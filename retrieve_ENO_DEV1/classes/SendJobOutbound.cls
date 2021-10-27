/**
 * Created by ibuzau on 4/29/2021.
 */

global class SendJobOutbound implements Schedulable {


	private Map<String, Integer> retryLimitPerRequestType;
	private List<outbound_manager_request_type__mdt> outboundMDT;

    global void execute(SchedulableContext ctx) {
        List<Outbound_Transfer__c> jobs = [
                SELECT Id, Request_Body__c, Request_Endpoint__c
                FROM Outbound_Transfer__c
                WHERE Transfered__c = FALSE AND Failed_By_Business_Error__c = FALSE
        ];

		outboundMDT = [SELECT Id, request_class_name__c, request_type_name__c, max_retry_count__c, business_error_codes__c, succeeded_response_codes__c FROM outbound_manager_request_type__mdt];
		retryLimitPerRequestType = getRetryLimits(outboundMDT);

        WrapperInterface wrapperInterface = new WSDLExample();
        WSDLExample.wsdlResponse resp = new WSDLExample.wsdlResponse();

        for (Outbound_Transfer__c job : jobs) {
            if (job.Request_Body__c != null) {
                JSONParser body = JSON.createParser(job.Request_Body__c);
                while (body.nextToken() != null) {
                    if ((body.getCurrentToken() == JSONToken.FIELD_NAME) && (body.getText() == 'type')) {
                        body.nextToken();
                        System.debug(body.getText()); // returneaza account
                    }
                    if ((body.getCurrentToken() == JSONToken.FIELD_NAME) && (body.getText() == 'Id')) {
                        body.nextToken();
                        System.debug(body.getText());
                    }
                    if ((body.getCurrentToken() == JSONToken.FIELD_NAME) && (body.getText() == 'Name')) {
                        body.nextToken();
                        System.debug(body.getText());
                    }

                    resp = wrapperInterface.send();
                    if ((resp.code.startsWith('3') || resp.code.startsWith('4') || resp.code.startsWith('5')) && resp.errorMessage != null){
                        job.Failed_By_Business_Error__c = true;
                        job.Error_Code__c = Decimal.valueOf(resp.code);
                        job.Error_Message__c = resp.errorMessage;
                    } else {
                        job.Transfered__c = true;
                    }
                }
            }
        }
        update jobs;
        
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

}