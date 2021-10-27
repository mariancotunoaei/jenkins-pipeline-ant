public class OutboundManager
{
    private static OutboundManager instance;
    private static final String JOB_NAME = 'OutboundBatch';

    private Outbound_manager_settings__c settings;

    private OutboundManager(){}

    
    public static OutboundManager getInstance()
    {
        if(instance == null)
        {
            instance = new OutboundManager();
        }

        return instance;
    }

    public void addObjectsToBeTransferred(List<Outbound_Transfer_Insert_Event__e> platformEvents)
    {
        try
        {
            List<Outbound_Transfer__c> toInsert = new List<Outbound_Transfer__c>();

            for(Outbound_Transfer_Insert_Event__e platformEvent : platformEvents)
            {
                System.debug('### Create il transfer data for ' + platformEvent.sobject_developer_name__c + ' with id ' + platformEvent.record_id__c + ' inserted on ' + platformEvent.CreatedDate);
                System.debug('### Just activated field is: ' + platformEvent.activated_in_this_context__c);
                Outbound_Transfer__c transferData = new Outbound_Transfer__c();
                transferData.Name = platformEvent.record_id__c;
                transferData.sobject_developer_name__c = platformEvent.sobject_developer_name__c;
                transferData.activated_in_this_context__c = platformEvent.activated_in_this_context__c;
                transferData.error_code__c = platformEvent.error_code__c;
                transferData.error_message__c = platformEvent.error_message__c;
                transferData.request_method__c = platformEvent.request_method__c;
                transferData.request_body__c = platformEvent.request_body__c;
                transferData.request_endpoint__c = platformEvent.request_endpoint__c;
                transferData.request_type__c = platformEvent.request_type__c;
                transferData.inserted_time_in_ms__c = platformEvent.inserted_time_in_ms__c;
                transferData.additional_fields__c = platformEvent.additional_fields__c;
               // transferData.trace_id__c = platformEvent.trace_id__c;
                toInsert.add(transferData);
            }

			insert toInsert;
            //DatabaseHelper.dmlActionRecordByDatabaseClass(toInsert, true, 'OutboundManager.addObjectsToBeTransferred()', DMLActions.DML_INSERT);
        }
        catch(Exception e)
        {
            System.debug(e.getMessage());
        }
    }

    public boolean isActive()
    {
        settings = Outbound_manager_settings__c.getOrgDefaults();

        return settings.active__c;
    }

    public integer getCheckIntervalInMinutes()
    {
        settings = Outbound_manager_settings__c.getOrgDefaults();

        return (Integer) settings.Check_Interval_In_Minutes__c;
    }

    public integer getLifetimeOfData()
    {
        settings = Outbound_manager_settings__c.getOrgDefaults();

        return (Integer) settings.lifetime_for_logged_data__c;
    }

    public Boolean getKeepData()
    {
        settings = Outbound_manager_settings__c.getOrgDefaults();

        return settings.keep_data__c;
    }


    public integer getMinTransferDelayInMinutes()
    {
        settings = Outbound_manager_settings__c.getOrgDefaults();

        return (Integer) settings.min_transfer_delay_in_minutes__c;
    }

    
    public boolean isStarted()
    {
        settings = Outbound_manager_settings__c.getOrgDefaults();

        return settings.started__c;
    }

    public void setStartedState(boolean state)
    {
        settings = Outbound_manager_settings__c.getOrgDefaults();
        settings.started__c = state;
        update settings;
    }

    public boolean isBatchRunning()
    {
        
        List<CronTrigger> ct = [SELECT Id, TimesTriggered, NextFireTime, CronJobDetail.Name FROM CronTrigger WHERE CronJobDetail.Name =: JOB_NAME];

        return !ct.isEmpty();
    }

    public void start()
    {
        if(isActive() && !isStarted())
        {
            System.debug('Starting Batch Job');
            initBatchJob();
        }
    }

    public void stop()
    {
        if(isActive())
        {
            settings.active__c = false;
            update settings;
        }
    }

    public String getJobName()
    {
        return JOB_NAME;
    }

    public Integer getILUpdateRetryLimit()
    {
        settings = Outbound_manager_settings__c.getOrgDefaults();

        return (Integer) settings.update_retry_limit__c;
    }

    public Integer getGenericRequestRetryLimit()
    {
        settings = Outbound_manager_settings__c.getOrgDefaults();

        return (Integer) settings.generic_request_retry_limit__c;
    }

    public String getOutboundTransferDataQueryByMetadata(List<outbound_manager_request_type__mdt> outboundMDT, Boolean smallerFlag, Integer recordLimit)
    {
        
        return getOutboundTransferDataQueryByMetadata(outboundMDT, smallerFlag, recordLimit, null);
    }

    public String getOutboundTransferDataQueryByMetadata(List<outbound_manager_request_type__mdt> outboundMDT, Boolean smallerFlag, Integer recordLimit, Set<Id> transferDataIds)
    {
        
        String dynamicWhereClause = 'transfered__c = false AND failed_by_business_error__c = false';

        if(transferDataIds != null)
            dynamicWhereClause += ' AND Id IN :transferDataIds';

        
        if(outboundMDT != null && !outboundMDT.isEmpty())
        {
            dynamicWhereClause += ' AND (';
            dynamicWhereClause += getOutboundTransferQueryMDTPart(outboundMDT, smallerFlag);
            dynamicWhereClause += ')';
        }

        
        if (recordLimit>0)
            dynamicWhereClause += ' LIMIT ' + recordLimit;

        
        String toReturn = getQuerySObjWithAllFields('Outbound_Transfer__c', dynamicWhereClause, null, null, null);
        toReturn += ' FOR UPDATE';

        return toReturn;
    }

	 

    
    public String getOutboundTransferQueryMDTPart(List<outbound_manager_request_type__mdt> outboundMDT, Boolean smallerFlag)
    {
        String toReturn = '';

        String retryComparator = smallerFlag ? '<' : '>=';

        
        for(Integer i = 0; i < outboundMDT.size(); i++)
        {
           
            outbound_manager_request_type__mdt currentData = outboundMDT[i];

           
            toReturn += '(request_type__c = \'' + currentData.request_type_name__c + '\' AND retry_counter__c ' + retryComparator + ' ' + currentData.max_retry_count__c + ')';

            
            if(i != outboundMDT.size() - 1)
                toReturn += ' OR ';
        }

        return toReturn;
    }


    public Map<String, List<String>> getBusinessErrorCodes(List<outbound_manager_request_type__mdt> outboundMDT)
    {
        Map<String, List<String>> toReturn = new Map<String, List<String>>();

        for(outbound_manager_request_type__mdt mdt : outboundMDT)
        {
            if(String.isNotBlank(mdt.business_error_codes__c))
                toReturn.put(mdt.request_type_name__c, mdt.business_error_codes__c.split(','));
        }

        return toReturn;
    }

    
    public Map<String, List<String>> getSucceededResponseCodes(List<outbound_manager_request_type__mdt> outboundMDT)
    {
        Map<String, List<String>> toReturn = new Map<String, List<String>>();

        for(outbound_manager_request_type__mdt mdt : outboundMDT)
        {
            if(String.isNotBlank(mdt.succeeded_response_codes__c))
                toReturn.put(mdt.request_type_name__c, mdt.succeeded_response_codes__c.split(','));
        }

        return toReturn;
    }

    
    public Map<String, Integer> getRetryLimits(List<outbound_manager_request_type__mdt> outboundMDT)
    {
        Map<String, Integer> toReturn = new Map<String, Integer>();

        for(outbound_manager_request_type__mdt mdt : outboundMDT)
        {
            toReturn.put(mdt.request_type_name__c, Integer.valueOf(mdt.max_retry_count__c));
        }

        return toReturn;
    }

    
    public Map<String, String> getRequestClassNames(List<outbound_manager_request_type__mdt> outboundMDT)
    {
        Map<String, String> toReturn = new Map<String, String>();

        for(outbound_manager_request_type__mdt mdt : outboundMDT)
        {
            toReturn.put(mdt.request_type_name__c, mdt.request_class_name__c);
        }

        return toReturn;
    }

    
    private void initBatchJob()
    {
        try
        {
           // ILTransferBatch transferBatch = new ILTransferBatch(instance);
           // String cronID = System.scheduleBatch(transferBatch, JOB_NAME, getCheckIntervalInMinutes(), 10);
          //  system.debug(cronID);
        }
        catch(AssertException e)
        {
            
            System.debug(e.getMessage());
        }
    }

	public static String getQuerySObjWithAllFields (String sObj,
                                                    String whereClause,
                                                    List <Object> objectList,
                                                    List <String> additionalFields,
                                                    Set <String> fieldToIgnoreSet) {

        return getQuerySObjWithAllFields(sObj, whereClause, objectList, additionalFields, fieldToIgnoreSet, false);
    }

	public static String getQuerySObjWithAllFields (String sObj,
            String whereClause,
            List <Object> objectList,
            List <String> additionalFields,
            Set <String> fieldToIgnoreSet,
            Boolean lockForUpdate) {

        List <String> fields = getSObjFieldList(sObj);

        if (additionalFields != null) {
            //query += ',' + String.join(additionalFields, ',');
            fields.addAll(additionalFields);
        }

        // clean the field list by removing fields to ignore
        if (fieldToIgnoreSet != null && fieldToIgnoreSet.size() > 0) {
            fields = getFieldListCleaned (fields, fieldToIgnoreSet);
        }

        String query = ' SELECT ' + String.join(fields, ',');
        query += ' FROM ' + sObj;

        if (whereClause != null) {
            query += ' WHERE '+ whereClause;
        }
        if (objectList != null) {
            query += ' :objectList';
        }

        if (lockForUpdate == true) {
            query += ' FOR UPDATE';
        }
        return query;
    }
	 public static List <String> getSObjFieldList (String sObj) {

        Schema.SObjectType sobjType = Schema.getGlobalDescribe().get(sObj);
        return new List<String>(sobjType.getDescribe().fields.getMap().KeySet());
    }

	public static List <String> getFieldListCleaned (List <String> fieldList,
                                                     Set <String> fieldToIgnoreSet) {
        if (fieldToIgnoreSet == null ||
                fieldToIgnoreSet.size() == 0) {
            return fieldList;
        }

        Integer i = 0;
        while (i < fieldList.size())
        {
            String fieldApiName = fieldList.get(i);

            if (fieldToIgnoreSet.contains(fieldApiName)) {
                fieldList.remove(i);
            }
            else {
                i++;
            }
        }
        return fieldList;
    }
}