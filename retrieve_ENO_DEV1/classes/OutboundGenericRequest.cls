public virtual without sharing class OutboundGenericRequest implements OutboundRequestInterface
{
    public HttpResponse response;

    private List<String> successResultCodes;
    private List<String> businessErrorResultCodes;
    private Integer retryLimit;

    public void setSuccessResultCodes(List<String> successResultCodes)
    {
        this.successResultCodes = successResultCodes;
    }

    public void setBusinessErrorResultCodes(List<String> businessErrorResultCodes)
    {
        this.businessErrorResultCodes = businessErrorResultCodes;
    }

    public void setRetryLimit(Integer retryLimit)
    {
        this.retryLimit = retryLimit;
    }

    public boolean isRetryLimitExceeded(Integer toCompare)
    {
        return toCompare >= this.retryLimit;
    }

    public virtual HttpRequest buildRequest(Outbound_Transfer__c outboundData)
    {
        HttpRequest toReturn = new HttpRequest();
        toReturn.setBody(outboundData.request_body__c);
        toReturn.setEndpoint(outboundData.request_endpoint__c);
        toReturn.setMethod(outboundData.request_method__c);
        toReturn.setTimeout(50000);
        toReturn.setHeader('Content-Type', 'application/json');
        toReturn.setHeader('Accept', 'application/json');

        if(String.isNotBlank(outboundData.trace_id__c))
            toReturn.setHeader('Trace-ID', outboundData.trace_id__c);

		
        return toReturn;
    }

    public virtual HttpResponse sendData(Outbound_Transfer__c outboundData)
    {
        Boolean toReturn = true;
        HttpResponse response = new HttpResponse();

        try
        {
            Http http = new Http();
            HttpRequest request = buildRequest(outboundData);

            System.debug('ILTransferBatch endpoint: '+request.getendpoint());
            System.debug('ILTransferBatch request: '+request);
            System.debug('ILTransferBatch request body: '+request.getBody());

            outboundData.sent_timestamp__c = String.valueOf(System.now());
            response = http.send(request);
            this.response = response;
            outboundData.transfered_timestamp__c = String.valueOf(System.now());
            outboundData.transfered_timestamp_in_ms__c = decimal.valueOf(System.now().getTime());

            System.debug('ILTransferBatch response: '+response);
            System.debug('ILTransferBatch response body: '+response.getBody());

            return response;
        }
        catch(CalloutException ce)
        {
            System.debug('Callout-Error occurred while sending the outbound message: ' + ce.getMessage());
        }
        catch(Exception e)
        {
            System.debug('Error occurred while sending the outbound message: ' + e.getMessage());
        }

        return null;
    }


    
    public virtual ResponseCheckResult checkResponse(Outbound_Transfer__c outboundData, HttpResponse response)
    {
        //Get the status code
        Integer statusCode = response.getStatusCode();
        //Check if the response code is a business error
        if(containsResponseCode(businessErrorResultCodes, String.valueOf(statusCode)))
        {
            //Set the flag and throw an exception
            outboundData.failed_by_business_error__c = true;
            outboundData.error_code__c = response.getStatusCode();
            outboundData.error_message__c = response.getBody();
            
            return ResponseCheckResult.BUSINESS_ERROR;
        }
        else if(!containsResponseCode(successResultCodes, String.valueOf(statusCode)))
        {
          
            outboundData.error_code__c = response.getStatusCode();
            outboundData.error_message__c = response.getBody();
            return ResponseCheckResult.ERROR;
        }

        return ResponseCheckResult.SUCCESS;
    }

    
    private Boolean containsResponseCode(List<String> codesToCheck, String responseCode)
    {
        //Found no codes -> return false
        if(codesToCheck == null || codesToCheck.isEmpty())
            return false;

        //Iterate over the list and check if the response code starts with the current entry
        for(String codeToCheck : codesToCheck)
        {
            if(responseCode.startsWith(codeToCheck))
                return true;
        }

        return false;
    }

    public virtual void handleFinallySucceeded(Outbound_Transfer__c outboundData, Map<String, List<SObject>> toHandle)
    {
        outboundData.transfered__c = true;
        outboundData.error_code__c = null;
        outboundData.error_message__c = '';

        //Add handling metainformation to deal with business worfklow steps (e.g. SMESF-1500)
        if (!String.isEmpty(outboundData.additional_fields__c)) {
            //parse the values from the metadata information
            Map<String, String> nameValueMap = castMapToStringString(handleAdditionalJSONField(outboundData));

        }
    }

    public virtual void handleFinallyFailed(Outbound_Transfer__c outboundData, Map<String, List<SObject>> toHandle)
    {
        
       // toHandle.get('toInsert').add(getSystemMessage(outboundData));

       
        if (!String.isEmpty(outboundData.additional_fields__c)) {
            
            Map<String, String> nameValueMap = castMapToStringString(handleAdditionalJSONField(outboundData));

        }
    }

    public virtual void handleFailedAttempt(Outbound_Transfer__c outboundData, Map<String, List<SObject>> toHandle)
    {
        outboundData.retry_counter__c++;
    }

   /* private mms_system_message__c getSystemMessage(Outbound_Transfer__c outboundData)
    {
        System.debug('Creating message for data with id: ' + outboundData.Id);
        String message = 'Outbound data with id: ' + outboundData.Id + ' to the endpoint: ' + outboundData.request_endpoint__c + '.';

        Id recordId = null;

        try
        {
            recordId = outboundData.Name;
        }
        catch(Exception e)
        {
            //recordId stays empty
        }


        mms_system_message__c toReturn = SystemMessageService.getSystemMessage(SystemMessageLevel.ERROR.name(), outboundData.request_endpoint__c, SystemMessageCategory.INTERFAZE.name(),
                message, message, System.now(), recordId);
        toReturn.source_system__c = 'SFDC';
        toReturn.error_type__c = outboundData.failed_by_business_error__c ? 'business_error' : 'technical_error';
        toReturn.error_code__c = String.valueOf(outboundData.error_code__c);
        toReturn.related_transfer_data_record__c = outboundData.Id;
        toReturn.correlation_id__c = String.isNotBlank(outboundData.trace_id__c) ? outboundData.trace_id__c : '';

        toReturn.mms_link_to_legal_entity__c = TRUE;


        return toReturn;
    }*/

    protected Map<String, Object> handleAdditionalJSONField(Outbound_Transfer__c outboundData)
    {
        Map<String, Object> toReturn = new Map<String, Object>();

        String additionalFieldsJSON = outboundData.additional_fields__c;

        if(String.isNotBlank(additionalFieldsJSON))
            toReturn = (Map<String, Object>)JSON.deserializeUntyped(additionalFieldsJSON);

        return toReturn;
    }

    private Map<String, String> castMapToStringString(Map<String,Object> inputMap) {
        Map<String, String> returnMap = new Map<String, String>();
        for (String key : inputMap.keySet()) {
            returnMap.put(key, (String)inputMap.get(key));
        }
        return returnMap;
    }

   
    private Map<String, String> getNameValues (String input) {
        Map<String, String> nameValueMap = new Map<String, String>();
        List <String> metaInformation = input.split(',');
        for (String s : metaInformation) {
            List <String> nameValue = s.split('=');
            nameValueMap.put(nameValue.get(0), nameValue.get(1));
        }
        return nameValueMap;
    }

    

    public virtual Boolean doSendTransferData(Outbound_Transfer__c outboundData, Set<String> failedRequestTypes)
    {
        return !failedRequestTypes.contains(outboundData.request_type__c);
    }
}