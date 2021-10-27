public class OutboundPlatformEventHelper
{
	@TestVisible
	private static Boolean ignoreForTest = false;
	private static String selectWrapper = '';


	public static List<Outbound_Transfer_Insert_Event__e> getILPlatformEventsByRecordList(List<SObject> listToHandle, Map<Id, SObject> oldMap)
	{
		return getILPlatformEventsByRecordList(listToHandle, oldMap, null, new Map<String, Object> ());
	}


	public static List<Outbound_Transfer_Insert_Event__e> getILPlatformEventsByRecordList(List<SObject> listToHandle, Map<Id, SObject> oldMap, WrapperInterface.Operation operation)
	{


		return getILPlatformEventsByRecordList(listToHandle, oldMap, operation, new Map<String, Object> ());
	}


	public static List<Outbound_Transfer_Insert_Event__e> getILPlatformEventsByRecordList(List<SObject> listToHandle, Map<Id, SObject> oldMap, WrapperInterface.Operation operation, Map<String, Object> additionalFields)
	{
		//The list to return
		List<Outbound_Transfer_Insert_Event__e> toReturn = new List<Outbound_Transfer_Insert_Event__e> ();

		try
		{

			if (ignoreForTest)
			return toReturn;

			//Iterate over each object to handle
			for (SObject newObject : listToHandle)
			{
				SObject oldObject = oldMap == null ? null : oldMap.get(newObject.Id);
				//Check if we have to create a event for the current object
				if (doCreateILPlatformEvent(newObject, oldObject, operation))
				{
					System.debug('ZZZ13');
					Outbound_Transfer_Insert_Event__e toAdd;

					//If the function was called from Send xyz to IL button => oldMap == null
					if (oldObject == null && !Trigger.isExecuting) {
						toAdd = createILPlatformEvent(newObject, true, operation, additionalFields);
					} else {
						//Check if the current record just has been activated in an update context
						boolean justActivated = oldMap == null ? false : isLifecycleStatusEvent(newObject, oldMap.get(newObject.Id));
						toAdd = createILPlatformEvent(newObject, justActivated, operation, additionalFields);
					}


					if (toAdd == null)
					continue;

					//Create a platform event and add it to the list
					toReturn.add(toAdd);
				}
			}
		}
		catch(Exception ex)
		{
			System.debug('Error creating the platform events: ' + ex);
		}

		return toReturn;
	}


	public static Outbound_Transfer_Insert_Event__e getGenericOutboundPlatformEventsByHttpRequest(HttpRequest request, HttpResponse response, SObject relatedSObject)
	{
		return createGenericRequestPlatformEvent(request, response, relatedSObject);
	}


	public static Outbound_Transfer_Insert_Event__e getOutboundPlatformEventByHttpRequestForRequestType(HttpRequest request, HttpResponse response, String requestType, SObject relatedSObject)
	{
		return createRetryRequestPlatformEvent(request, response, requestType, relatedSObject);
	}

	/**
	 * Helper function to create a il platform event
	 * All informations are collected by the given parameter
	 *
	 *
	 * @return
	 */
	public static Outbound_Transfer_Insert_Event__e getOutboundPlatformEventByHttpRequestForRequestType(WrapperInterface wrapper, Id objectToWrap, WrapperInterface.Operation operation, Integer timeout, String requestType, SObject relatedSObject)
	{
		HttpRequest request = new HttpRequest();

		request.setEndpoint(wrapper.getEndpoint(operation));
	//	request.setMethod(wrapper.getILUpdateMethod(operation));

		if (timeout != null)
		{
			request.setTimeout(timeout);
		}

		request.setHeader('Content-Type', 'application/json');

		if (objectToWrap != null)
		{
			request.setBody(wrapper.getJSONString(objectToWrap));
		}
		else
		{
			request.setBody(wrapper.getJSONString());
		}

		return createRetryRequestPlatformEvent(request, null, null, requestType, relatedSObject);
	}

	public static Outbound_Transfer_Insert_Event__e getOutboundPlatformEventByHttpRequestForRequestType(HttpRequest request, String errorMessage, Integer errorCode, String requestType, SObject relatedSObject)
	{
		return createRetryRequestPlatformEvent(request, errorMessage, errorCode, requestType, relatedSObject);
	}


	private static boolean isLifecycleStatusEvent(SObject newObj, SObject oldObj)
	{
		//Switch statement on the new record
		switch on newObj
		{
			when Account a
			{
				//Its an account
				Account oldAccount = (Account) oldObj;

				//return oldAccount.lifecycle_status__c != a.lifecycle_status__c;
				return true;
			}
		}

		return false;
	}

	public static boolean hasSObjectField(String fieldName, SObject so) {
		return so.getSobjectType().getDescribe().fields.getMap().keySet().contains(fieldName.toLowerCase());
	}


	public static Outbound_Transfer_Insert_Event__e createILPlatformEvent(SObject o, boolean justActivated, WrapperInterface.Operation operation, Map<String, Object> additionalFields)
	{
		System.debug('Handeling a ' + String.valueOf(o.getSObjectType()));
			Outbound_Transfer_Insert_Event__e toReturn = new Outbound_Transfer_Insert_Event__e();
			//toReturn.request_type__c = Constants.OUTBOUND_IL_UPDATE_REQUEST_TYPE;
			toReturn.record_id__c = o.Id;
			toReturn.sobject_developer_name__c = String.valueOf(o.getSObjectType());
			toReturn.activated_in_this_context__c = justActivated;
			toReturn.inserted_time_in_ms__c = System.now().getTime();
			toReturn.additional_fields__c = !additionalFields.isEmpty() ? JSON.serialize(additionalFields) : '';

			/*if (hasSObjectField('trace_id__c', o) && String.isNotBlank((String) o.get('trace_id__c'))) {
			  toReturn.trace_id__c = (String) o.get('trace_id__c');
			  }*/
			WrapperInterface wrapper;


			String requestBody = null;

			switch on toReturn.sobject_developer_name__c
			{
				when 'Account'
				{
					wrapper = new WSDLExample(justActivated);
				}

			}

			if (requestBody == null)
				{
					// this is the default if it was was set before as a special case
					requestBody = wrapper.getJSONString(o.Id);
					System.debug('CGL Body: '+ wrapper.getJSONString(o.Id) );
				}
				toReturn.request_body__c = requestBody;
				//toReturn.request_method__c = wrapper.getILUpdateMethod(operation);
				toReturn.request_endpoint__c = wrapper.getEndpoint(operation);
				return toReturn;
			
	}


	private static Outbound_Transfer_Insert_Event__e createGenericRequestPlatformEvent(HttpRequest request, HttpResponse response, SObject relatedSObject)
	{
		return createRetryRequestPlatformEvent(request, response.getBody(), response.getStatusCode(), 'Generic Request', relatedSObject);
	}


	private static Outbound_Transfer_Insert_Event__e createRetryRequestPlatformEvent(HttpRequest request, HttpResponse response, String requestType, SObject relatedSObject)
	{
		return createRetryRequestPlatformEvent(request, response.getBody(), response.getStatusCode(), requestType, relatedSObject);
	}


	private static Outbound_Transfer_Insert_Event__e createRetryRequestPlatformEvent(HttpRequest request, String errorMessage, Integer errorCode, String requestType, SObject relatedSObject)
	{
		Outbound_Transfer_Insert_Event__e toReturn = new Outbound_Transfer_Insert_Event__e();
		toReturn.sobject_developer_name__c = String.valueOf(relatedSObject.getSObjectType());
		toReturn.record_id__c = relatedSObject.Id;
		toReturn.request_type__c = requestType;
		toReturn.request_endpoint__c = request.getEndpoint();
		toReturn.request_body__c = request.getBody();
		toReturn.request_method__c = request.getMethod();
		toReturn.inserted_time_in_ms__c = System.now().getTime();
		toReturn.error_message__c = errorMessage;
		toReturn.error_code__c = errorCode;
		return toReturn;
	}


	public static boolean doCreateILPlatformEvent(SObject newObject, SObject oldObject, WrapperInterface.Operation operation)
	{
		System.debug('ZZZ111');
		switch on newObject
		{
			when Account a
			{
				/*System.debug('ZZZ112');
				  Boolean isUpdate = false;
				 
				  System.debug('ZZZ113');
				  if ((operation == null && Trigger.isUpdate) || operation == WrapperInterface.Operation.UPDATE_OPERATION)
				  isUpdate = true;
				  Boolean isTrue = (a.RecordTypeId == outletEXactRTId || (a.RecordTypeId == legalEntityEXactRTId && isUpdate)) && a.onboarding_state_il__c == 'COMPLETED';
				  System.debug('ZZZ114: ' + isUpdate + isTrue);
				 
				  return((a.RecordTypeId == outletEXactRTId || (a.RecordTypeId == legalEntityEXactRTId && isUpdate)) && a.onboarding_state_il__c == 'COMPLETED');*/
				return true;
			}
		}
		return false;
	}

	public static List<Account> getListOfAccounts(Set<Id> accIds)
	{
		return[SELECT Id, RecordTypeId, Name FROM Account WHERE Id IN : accIds];
	}

	public static void setSelectWrapper(String wrapperName) {
		selectWrapper = wrapperName;
	}
}