/**
 * Created by ibuzau on 6/29/2021.
 */

@IsTest
private class OpportunityTriggerHandlerTest {


    @TestSetup
    static void testBehavior() {
        List<Opportunity> oppIdsToInsert = new List<Opportunity>();
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


        Opportunity opp = new Opportunity();
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Memberships').getRecordTypeId();
        opp.Name = 'test';
        opp.npsp__Primary_Contact__c = contactId;
        opp.Amount = 100;
        opp.StageName = 'Paid';
        opp.npe01__Membership_End_Date__c = Date.today();
        opp.CloseDate = Date.today();
        opp.npe01__Membership_Start_Date__c = Date.today().addDays(-2);
        opp.CampaignId = campaign.Id;
        opp.Membership_Scheme__c = 'ENO Opera Circle';
        opp.npe01__Member_Level__c = 'ENO Opera Circle Supporter';
        oppIdsToInsert.add(opp);


        Opportunity membershipGift = new Opportunity();
        membershipGift.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Memberships').getRecordTypeId();
        membershipGift.Name = 'test2';
        membershipGift.npsp__Primary_Contact__c = contactId;
        membershipGift.Amount = 200;
        membershipGift.StageName = 'Paid';
        membershipGift.npe01__Membership_End_Date__c = Date.today();
        membershipGift.CloseDate = Date.today();
        membershipGift.npe01__Membership_Start_Date__c = Date.today().addDays(-2);
        membershipGift.CampaignId = campaign.Id;
        membershipGift.Membership_Scheme__c = 'ENO Opera Circle';
        membershipGift.npe01__Member_Level__c = 'ENO Opera Circle Supporter';
        oppIdsToInsert.add(membershipGift);

        //for testing the bulk
        for( Integer i =0; i<200; i++){
            Opportunity membershipbulk = new Opportunity();
            membershipbulk.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Memberships').getRecordTypeId();
            membershipbulk.Name = 'test2';
            membershipbulk.npsp__Primary_Contact__c = contactId;
            membershipbulk.Amount = 23460;
            membershipbulk.StageName = 'Paid';
            membershipbulk.npe01__Membership_End_Date__c = Date.today();
            membershipbulk.CloseDate = Date.today();
            membershipbulk.npe01__Membership_Start_Date__c = Date.today().addDays(-2);
            membershipbulk.CampaignId = campaign.Id;
            membershipbulk.Membership_Scheme__c = 'ENO Opera Circle';
            membershipbulk.npe01__Member_Level__c = 'ENO Opera Circle Supporter';
            oppIdsToInsert.add(membershipbulk);
        }

        insert oppIdsToInsert;

    }


    @IsTest
    public static void testFreeTrial() {


        List<Opportunity> membershipFreeTrial = [SELECT Name,npsp__Primary_Contact__c,npe01__Membership_Origin__c,npe01__Member_Level__c FROM Opportunity WHERE Amount = 100 LIMIT 1];

        Test.startTest();

        membershipFreeTrial[0].npe01__Member_Level__c = 'ENO Opera Circle Trial';
       OpportunityTriggerHandler.calculateMembershipOrigin(membershipFreeTrial);
        System.assertEquals('Free Trial', membershipFreeTrial[0].npe01__Membership_Origin__c);

        Test.stopTest();

    }

    @IsTest
    public static void testGift() {
        // TEST FOR GIFT

       List< Opportunity> membershipGift = [
                SELECT Name,npe01__Membership_Origin__c,
                        npsp__Primary_Contact__c, npe01__Member_Level__c,npsp4hub__Payment_Method__c
                FROM Opportunity
                WHERE Amount = 200
                LIMIT 1
        ];
        membershipGift[0].npsp4hub__Payment_Method__c = 'Gift Voucher';

        Test.startTest();
        OpportunityTriggerHandler.calculateMembershipOrigin(membershipGift);
        System.assertEquals('Gift', membershipGift[0].npe01__Membership_Origin__c);
        Test.stopTest();
    }

    @IsTest
    public static void testRenewal() {

        List<Opportunity> membershipRenewal = [
                SELECT Name,npe01__Membership_Origin__c, npe01__Membership_Start_Date__c,npe01__Membership_End_Date__c,npe01__Member_Level__c,npsp4hub__Payment_Method__c,npsp__Primary_Contact__c
                FROM Opportunity
                WHERE Amount = 200
        ];

        //TEST FOR RENEWAL
        Test.startTest();
        OpportunityTriggerHandler.calculateMembershipOrigin(membershipRenewal);
        System.assertEquals('Renewal', membershipRenewal[0].npe01__Membership_Origin__c);
        Test.stopTest();
    }

    @IsTest
    public static void testUpgrade() {


        List<Opportunity> membershipUpgrade = [
                SELECT Name,npe01__Membership_Origin__c, npe01__Membership_Start_Date__c,npe01__Membership_End_Date__c,npe01__Member_Level__c,npsp4hub__Payment_Method__c,npsp__Primary_Contact__c
                FROM Opportunity
                WHERE Amount = 200
        ];
        //TEST FOR UPGRADE
        Test.startTest(); 

        membershipUpgrade[0].npe01__Member_Level__c = 'ENO Opera Circle Principal Supporter';
        OpportunityTriggerHandler.calculateMembershipOrigin(membershipUpgrade);
        System.assertEquals('Upgrade', membershipUpgrade[0].npe01__Membership_Origin__c);
        Test.stopTest();
    }

    @IsTest
    public static void testDowngrade() {
        List<Opportunity>  membershipDowngrade = [
                SELECT Name,npe01__Membership_Origin__c, npe01__Membership_Start_Date__c,npe01__Membership_End_Date__c,npe01__Member_Level__c,npsp4hub__Payment_Method__c,npsp__Primary_Contact__c
                FROM Opportunity
                WHERE Amount = 200
        ];
        //TEST FOR DOWNGRADE
        Test.startTest();
        membershipDowngrade[0].npe01__Member_Level__c = 'ENO Friends Platinum';
        OpportunityTriggerHandler.calculateMembershipOrigin(membershipDowngrade);
        System.assertEquals('Downgrade', membershipDowngrade[0].npe01__Membership_Origin__c);
        Test.stopTest();

    }

    @IsTest
    public static void testRejoin() {
        List<Opportunity> membershipRejoin = [
                SELECT Name,npe01__Membership_Origin__c, npe01__Membership_Start_Date__c,npe01__Membership_End_Date__c,npe01__Member_Level__c,npsp4hub__Payment_Method__c,npsp__Primary_Contact__c
                FROM Opportunity
                WHERE Amount = 200
        ];
        Test.startTest();

        membershipRejoin[0].npe01__Membership_End_Date__c = Date.today().addDays(35);
        membershipRejoin[0].CloseDate = Date.today().addDays(35);
        membershipRejoin[0].npe01__Membership_Start_Date__c = Date.today().addDays(31);
         OpportunityTriggerHandler.calculateMembershipOrigin(membershipRejoin);
        System.assertEquals('Rejoin', membershipRejoin[0].npe01__Membership_Origin__c);
        Test.stopTest();

    }

}