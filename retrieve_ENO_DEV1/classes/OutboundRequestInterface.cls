public interface OutboundRequestInterface
{
    HttpResponse sendData(Outbound_Transfer__c transferData);

    ResponseCheckResult checkResponse(Outbound_Transfer__c outboundData, HttpResponse response);

    void setSuccessResultCodes(List<String> successResultCodes);

    void setBusinessErrorResultCodes(List<String> businessErrorResultCodes);

    void setRetryLimit(Integer retryLimit);

    boolean isRetryLimitExceeded(Integer toCompare);

    
    void handleFinallySucceeded(Outbound_Transfer__c outboundData, Map<String, List<SObject>> toHandle);

    
    void handleFinallyFailed(Outbound_Transfer__c outboundData, Map<String, List<SObject>> toHandle);

    void handleFailedAttempt(Outbound_Transfer__c outboundData, Map<String, List<SObject>> toHandle);

    Boolean doSendTransferData(Outbound_Transfer__c outboundData, Set<String> failedRequestTypes);
}