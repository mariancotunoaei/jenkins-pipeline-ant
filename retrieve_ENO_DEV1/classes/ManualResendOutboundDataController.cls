public class ManualResendOutboundDataController  {

	@AuraEnabled
	public static string resendOutbound(string id){
		
		Outbound_Transfer__c outbound = [select id from Outbound_Transfer__c where Id=:id];
		outbound.Transfered__c=false;
		outbound.Failed_By_Business_Error__c = false;
		update outbound;
		return 'SUCCESS';
	}
}