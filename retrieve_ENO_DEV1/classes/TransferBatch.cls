public class TransferBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful
{
    //The outbound manager
    private OutboundManager OutboundManager;
    //A set of record ids we will handle in each batch execution
    private Set<Id> handledDataIds;
    //A set of string. We will add all failed request types in here
    private Set<String> failedRequestTypes;
    //All existing outbound meta data
    private List<outbound_manager_request_type__mdt> outboundMDT;
    //All business error codes per business type
    private Map<String, List<String>> businessErrorCodesPerRequestType;
    //All success codes per business type
    private Map<String, List<String>> succeededResponseCodesPerRequestType;
    //Retry limit per request type
    private Map<String, Integer> retryLimitPerRequestType;
    //Class name per request type
    private Map<String, String> requestClassNames;

    private final String QUERY;

    /**
     * Constructor to init the outbound manager
     *
     * @param manager
     */
    public TransferBatch(OutboundManager manager)
    {
        OutboundManager = manager;
        outboundMDT = [SELECT Id, request_class_name__c, request_type_name__c, max_retry_count__c, business_error_codes__c, succeeded_response_codes__c FROM outbound_manager_request_type__mdt];
        
		String subquery = (outboundMDT != null && !outboundMDT.isEmpty()) ? ' AND (' + OutboundManager.getOutboundTransferQueryMDTPart(outboundMDT, true) + ') ' : '';
		QUERY = 'SELECT Id FROM Outbound_Transfer__c WHERE transfered__c = false AND failed_by_business_error__c = false ' + subquery + ' ORDER BY inserted_time_in_ms__c ASC';
    }

    public Database.QueryLocator start(Database.BatchableContext info)
    {
        //A wrapper we use for sorting the transferdata objects (NOTE: Because we use FOR Update in the query, we cant sort the entries)
        List<TransferDataWrapper> wrappedTransferData = new List<TransferDataWrapper>();

        outbound_manager_settings__c settings = outbound_manager_settings__c.getOrgDefaults();
        Integer asyncThreshold = 20000;
        Integer recordLimit = 1000;
        if (settings.async_limit_threshold__c != null)
            asyncThreshold = Integer.valueOf(settings.async_limit_threshold__c);
        if (settings.record_number_limitation__c != null)
            recordLimit = Integer.valueOf(settings.record_number_limitation__c);
        
        try
        {
            OutboundManager.setStartedState(true);
            //Initiate all class parameter
            handledDataIds = new Set<Id>();
            failedRequestTypes = new Set<String>();
            businessErrorCodesPerRequestType = OutboundManager.getBusinessErrorCodes(outboundMDT);
            succeededResponseCodesPerRequestType = OutboundManager.getSucceededResponseCodes(outboundMDT);
            retryLimitPerRequestType = OutboundManager.getRetryLimits(outboundMDT);
            requestClassNames = OutboundManager.getRequestClassNames(outboundMDT);

            return Database.getQueryLocator(QUERY);
        }
        catch(Exception e)
        {
            System.debug('Error in start method: ' + e.getMessage() + ' ' + e.getStackTraceString());
        }

        return null;
    }

    /**
     *
     * @param info
     * @param scope
     */
    public void execute(Database.BatchableContext info, List<Outbound_Transfer__c> scope)
    {
		if(scope.isEmpty()) return;

        Set<Id> transferDataIds = new Set<Id>();

        for(Outbound_Transfer__c td : scope)
            transferDataIds.add(td.Id);

        List<Outbound_Transfer__c> transferData = Database.query(OutboundManager.getOutboundTransferDataQueryByMetadata(outboundMDT, true, 0, transferDataIds));

        List<TransferDataWrapper> wrappedTransferData = new List<TransferDataWrapper>();
        //Iterate over ach found outbound data
        for(Outbound_Transfer__c d : transferData)
        {
            //Create a wrapper instance for the current data
            wrappedTransferData.add(new TransferDataWrapper(d));
        }

        //Sort the wrappers
        wrappedTransferData.sort();

        try
        {
            Map<String, List<Sobject>> toHandle = new Map<String, List<SObject>>();
            toHandle.put('toInsert', new List<SObject>());
            toHandle.put('toUpdate', new List<SObject>());
            toHandle.put('toPublish', new List<SObject>());

            //Iterate over each data in the scope
            for(TransferDataWrapper wrapper : wrappedTransferData)
            {
                //Get the current data
                Outbound_Transfer__c currentTransferData = wrapper.transferData;

                //Get the outbound request class for the current data by using its request type
                OutboundRequestInterface outboundRequestClassInstance = getOutboundRequestClass(currentTransferData.request_type__c);

                //Check if we have to send the current data. If not, continue with the next entry
                if(!outboundRequestClassInstance.doSendTransferData(currentTransferData, failedRequestTypes))
                    continue;

                //Get the response by sending the request using the current data
                HttpResponse response = outboundRequestClassInstance.sendData(currentTransferData);

                //Flag to check if sending the request was successfull
                boolean succeeded = false;
                //Flag to check if the current data is finally failed
                boolean finallyFailed = false;

                if(response != null)
                {
                    //We got a response so check the result
                    ResponseCheckResult checkResult = outboundRequestClassInstance.checkResponse(currentTransferData, response);
                    switch on checkResult
                    {
                        when SUCCESS
                        {
                            //Response has been marked as successful
                            succeeded = true;
                        }
                        when BUSINESS_ERROR
                        {
                            //A business error occurred. This means, the current data is finally failed
                            finallyFailed = true;
                        }
                    }
                }

                if(succeeded)
                {
                    //In this case everything went fine. Execute the function for this case
                    outboundRequestClassInstance.handleFinallySucceeded(currentTransferData, toHandle);
                }
                else
                {
                    //Add the current request type to the failed set
					if(!finallyFailed) // FMARIN - business errors should not block subsequent data propagation
						failedRequestTypes.add(currentTransferData.request_type__c);

                    //Check if finally failed
                    if(!finallyFailed)
                    {
                        //Something failed
                        outboundRequestClassInstance.handleFailedAttempt(currentTransferData, toHandle);

                        //We will check, if the retry limit of the current data exceeded the allowed value
                        finallyFailed = outboundRequestClassInstance.isRetryLimitExceeded(Integer.valueOf(currentTransferData.retry_counter__c));
                    }

                    if(finallyFailed)
                    {
                        //If finally failed, executed the function for this case
                        outboundRequestClassInstance.handleFinallyFailed(currentTransferData, toHandle);
                    }
                }

                //Add the current data to the list to update
                //toUpdate.add(currentTransferData);
                toHandle.get('toUpdate').add(currentTransferData);
            }
			List<Database.SaveResult> saveResults;

			if(!toHandle.get('toUpdate').isEmpty()) {
				Map<String, List<SObject>> updateObjects = new Map<String, List<SObject>>();
				for (SObject crtObj: toHandle.get('toUpdate')) {
					if(crtObj == null) continue;
					String crtObjectname = crtObj.getSObjectType().getDescribe().getName();
					List<SObject> objectList = updateObjects.get(crtObjectname);
					if (objectList == null) {
						updateObjects.put(crtObjectname, new List<SObject>());
						objectList = updateObjects.get(crtObjectname);
					}
					objectList.add(crtObj);
				}

				

				for (List<SObject> crtObjects: updateObjects.values()) {
					saveResults.addAll(Database.update(crtObjects, false));
				}
			}
           
			if(!toHandle.get('toInsert').isEmpty()) {
				Map<String, List<SObject>> insertObjects = new Map<String, List<SObject>>();
				for (SObject crtinsObj: toHandle.get('toInsert')) {
					if(crtinsObj == null) continue;
					String crtObjectname = crtinsObj.getSObjectType().getDescribe().getName();
					List<SObject> objectList = insertObjects.get(crtObjectname);
					if (objectList == null) {
						insertObjects.put(crtObjectname, new List<SObject>());
						objectList = insertObjects.get(crtObjectname);
					}
					objectList.add(crtinsObj);
				}
			
				for (List<SObject> crtinsObjects: insertObjects.values()) {
					saveResults.addAll(Database.insert(crtinsObjects, false));
				}
			}

            if(!toHandle.get('toPublish').isEmpty())
                EventBus.publish(toHandle.get('toPublish'));
        }
        catch(Exception ex)
        {
            System.debug('Error in execute method: ' + ex.getMessage() + ' ' + ex.getStackTraceString());

            try
            {
               // SystemMessageService.log(ex, 'TransferBatch.execute()');
            }
            catch(Exception e)
            {
                System.debug('Failed to save system message: ' + e.getMessage());
            }
        }
    }

    public OutboundRequestInterface getOutboundRequestClass(String requestType)
    {
        //Name of the class we use for default
        String defaultRequestClassName = 'OutboundGenericRequest';

        //Get the class name by the request type from the map
        String requestClassName = requestClassNames.get(requestType);
        if(String.isBlank(requestClassName))
        {
            //No entry found in the map for the current type. Use the default class name
            System.debug('Using default request class >'+defaultRequestClassName+'<.');
            requestClassName = defaultRequestClassName;
        }

        OutboundRequestInterface outboundRequestClass = null;
        try
        {
            //Get a type by using the requestClassName
            Type t = Type.forName(requestClassName);
            if (t != null)
            {
                //Type could be created, create an instance of the class
                outboundRequestClass = (OutboundRequestInterface)t.newInstance();
            }
        }
        catch(Exception ex)
        {
            System.debug('Error instantiating request class >'+requestClassName+'<. '+ex.getStackTraceString());
        }

        if(outboundRequestClass == null)
        {
            //For some reason, we could not create a instance til here. Create one using the default type
            System.debug('Using default request class >' + defaultRequestClassName + '<.');
            outboundRequestClass = (OutboundRequestInterface)Type.forName(defaultRequestClassName).newInstance();
        }

        //Setting some parameters in the requestclass
        outboundRequestClass.setSuccessResultCodes(succeededResponseCodesPerRequestType.get(requestType));
        outboundRequestClass.setBusinessErrorResultCodes(businessErrorCodesPerRequestType.get(requestType));
        outboundRequestClass.setRetryLimit(retryLimitPerRequestType.get(requestType));

        return outboundRequestClass;
    }

    public void finish(Database.BatchableContext info)
    {
        try
        {
            //For the case the function returns false, delete all transfered
            if(!this.OutboundManager.getKeepData())
            {
                //Delete all transfered objects
                List<Outbound_Transfer__c> toDelete = [SELECT Id FROM Outbound_Transfer__c WHERE transfered__c = true AND Id IN:handledDataIds];
                delete toDelete;
            }
        }
        catch(Exception ex)
        {
            System.debug('Error in finish method: ' + ex.getMessage() + ' ' + ex.getStackTraceString());

            try
            {
               // SystemMessageService.log(ex, 'TransferBatch.finish()');
            }
            catch(Exception e)
            {
                System.debug('Failed to save system message: ' + e.getMessage());
            }
        }
        finally
        {
            OutboundManager.setStartedState(false);
            if(this.OutboundManager.isActive())
            {
                this.reInitBatchJob();
            }
        }
    }

  
    private void reInitBatchJob()
    {
        //If the batch has not already been started and is not in test context: restart it
        if(!this.OutboundManager.isStarted() && !Test.isRunningTest())
        {
            TransferBatch TransferBatch = new TransferBatch(this.OutboundManager);
            String cronID = System.scheduleBatch(TransferBatch, this.OutboundManager.getJobName(), this.OutboundManager.getCheckIntervalInMinutes(), 10);
        }
    }

   
}