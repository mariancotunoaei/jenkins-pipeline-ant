/**
 * Created by ibuzau on 5/5/2021.
 */

@IsTest
private class Test_SendJobOutbound {
    @TestSetup
    static void setup() {
    }

    @IsTest
    public static void testSendJobOutbound(){
        List<Outbound_Transfer__c> outboundTransfers = new List<Outbound_Transfer__c>();
        for (Integer i = 0; i < 3; i++) {
            Outbound_Transfer__c outboundTransfer = new Outbound_Transfer__c(
                    Request_Body__c = '{"attributes":{"type":"Account","url":"/services/data/v51.0/sobjects/Account/0012500001RQjjUAAT"},"Id":"0012500001RQjjUAAT","Name":"Test9"}',
                    Request_Endpoint__c = null,
                    Transfered__c = false,
                    Failed_By_Business_Error__c = false
            );
            outboundTransfers.add(outboundTransfer);
        }
        insert outboundTransfers;

        Map<Id, Outbound_Transfer__c> outboundTransferMap = new Map<Id, Outbound_Transfer__c>(outboundTransfers);
        List<Id> outboundTransferIds = new List<Id>(outboundTransferMap.keySet());

        Test.startTest();
        SendJobOutbound sjo1 = new SendJobOutbound();
        sjo1.execute(null);
        Test.stopTest();
        List<Outbound_Transfer__c> jobs = [SELECT Id, Transfered__c, Failed_By_Business_Error__c, Error_Message__c, Error_Code__c FROM Outbound_Transfer__c WHERE Id IN : outboundTransferIds];
        for (Outbound_Transfer__c job : jobs){
            System.assertEquals(500, job.Error_Code__c);
            System.assertEquals('Generic Error', job.Error_Message__c);
            System.assertEquals(true, job.Failed_By_Business_Error__c);
        }
    }
}