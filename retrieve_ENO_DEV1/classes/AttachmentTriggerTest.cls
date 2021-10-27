/**
 * Created by ibuzau on 8/13/2021.
 */

@IsTest
private class AttachmentTriggerTest {
    @TestSetup
    static void testBehavior() {
        Contact c = new Contact();
        c.FirstName = 'Test';
        c.LastName = 'Test';
        c.Email = 'test@test.nl';
        c.Number_of_Active_Membership_Levels__c = 0;
        c.CRM_ID_Backend__c = 12345;
        insert c;

        Contact contact = [SELECT Id FROM Contact where Email = 'test@test.nl'];
        String contactId = contact.Id;
        Campaign campaign = new Campaign();
        campaign.Name = 'Campanie de test';
        campaign.IsActive = true;
        campaign.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Fund').getRecordTypeId();
        campaign.Opportunity_Record_Type_Name__c = 'Memberships';
        insert campaign;

        Document_Generation_Request__c doc = new Document_Generation_Request__c();
        doc.Name = 'testTrigger';
        doc.Template_Name__c = 'DD Auto Renew Thank You Letter Mapping';
        insert doc;

        Opportunity opp = new Opportunity();
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Memberships').getRecordTypeId();
        opp.Name = 'test';
        opp.npsp__Primary_Contact__c = contactId;
        opp.Amount = 100;
        opp.StageName = 'Paid';
        opp.npe01__Membership_End_Date__c = Date.today();
        opp.CloseDate = Date.today();
        opp.npe01__Membership_Start_Date__c = Date.today().addDays(-2);
        opp.Membership_Scheme__c = 'ENO Opera Circle';
        opp.npe01__Member_Level__c = 'ENO Opera Circle Supporter';
        opp.Document_Generation_Request__c = doc.Id;
        insert opp;
        Attachment attach=new Attachment();
        attach.Name='Unit Test Attachment';
        Blob bodyBlob = Blob.valueOf('Unit Test Attachment Body');
        attach.body = bodyBlob;
        attach.parentId = opp.id;
        insert attach;

    }

    @IsTest
    public static void test() {

        Document_Generation_Request__c documentGenerationRequests = [
                SELECT Id, Name
                FROM Document_Generation_Request__c
                WHERE Name = 'testTrigger'
                LIMIT 1
        ];
        System.debug(documentGenerationRequests);
        List<Attachment> attachments = [
                SELECT Id, Name, ParentId
                FROM Attachment
                WHERE ParentId =: documentGenerationRequests.Id

        ];
        System.debug(JSON.serialize(attachments));

        Test.startTest();
        System.assertEquals(1, attachments.size());
        Test.stopTest();


    }
}