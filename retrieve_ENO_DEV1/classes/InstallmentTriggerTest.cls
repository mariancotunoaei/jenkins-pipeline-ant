/**
 * Created by ibuzau on 8/13/2021.
 */

@IsTest
private class InstallmentTriggerTest {
    @TestSetup
    static void testBehavior() {
        Contact c = new Contact();
        c.FirstName = 'Test';
        c.LastName = 'Test';
        c.Email = 'test@test.nl';
        c.Number_of_Active_Membership_Levels__c = 0;
        c.CRM_ID_Backend__c = 12345;
        insert c;

        Opportunity opp = new Opportunity();
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Memberships').getRecordTypeId();
        opp.Name = 'testopp';
        opp.npsp__Primary_Contact__c = c.Id;
        opp.Amount = 100;
        opp.StageName = 'Paid';
        opp.npe01__Membership_End_Date__c = Date.today();
        opp.CloseDate = Date.today();
        opp.npe01__Membership_Start_Date__c = Date.today().addDays(-2);
        opp.Membership_Scheme__c = 'ENO Opera Circle';
        opp.npe01__Member_Level__c = 'ENO Opera Circle Supporter';
        insert opp;

        cpm__Installment__c installment = new cpm__Installment__c(

                cpm__Contact__c = c.Id,
                cpm__Amount__c = 999,
                cpm__Payment_Intent_Id__c = 'int222',
                npsp4hub__Opportunity__c=opp.Id
        );
        insert installment;
    }
    @IsTest
    public static void test() {

        Opportunity opp = [SELECT Id, Last_installment__c, Name from Opportunity WHERE Amount = 100 ];
        System.debug(opp);
        cpm__Installment__c inst = [SELECT Id  FROM cpm__Installment__c LIMIT 1];

        Test.startTest();
        System.assertEquals(inst.id, opp.Last_installment__c);
        Test.stopTest();
    }
}