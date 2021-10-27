/**
 * Created by ibuzau on 5/17/2021.
 */

@IsTest
private class Test_DeleteOlderJobs {

    @IsTest
    public static void testSendJobOutbound() {
        Outbound_manager_settings__c setting = new Outbound_manager_settings__c();
        setting.Lifetime_for_logged_data__c = 30;
        insert setting;

        Outbound_Transfer__c outboundTransfer = new Outbound_Transfer__c(
                Request_Body__c = '{"attributes":{"type":"Account","url":"/services/data/v51.0/sobjects/Account/0012500001RQjjUAAT"},"Id":"0012500001RQjjUAAT","Name":"Test9"}',
                Request_Endpoint__c = null,
                Transfered__c = true,
                Failed_By_Business_Error__c = false
        );

        insert outboundTransfer;

        Test.setCreatedDate(outboundTransfer.Id, Date.today().addMonths(-1));

        Test.startTest();
        DeleteOlderJobs deleteOlderJobs = new DeleteOlderJobs();
        deleteOlderJobs.execute(null);
        Test.stopTest();
        
        List<Outbound_Transfer__c> jobs =  [
                    SELECT Id
                    FROM Outbound_Transfer__c
                    WHERE Id = :outboundTransfer.Id
            ];
        Outbound_Transfer__c jobExpected= new Outbound_Transfer__c();

        System.assertEquals(0 , jobs.size());


    }
}