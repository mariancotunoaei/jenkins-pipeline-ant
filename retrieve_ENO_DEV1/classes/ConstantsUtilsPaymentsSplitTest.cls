/**
 * Created by amacari on 7/8/2021.
 */

@IsTest
private class ConstantsUtilsPaymentsSplitTest {


    @TestSetup
    static void testSetup() {
        Financial_Settings__c financialSettings = new Financial_Settings__c(
                Annual_Non_VAT__c = 5,
                Gift_Aid_Percent__c = 0.25,
                VAT_Value__c = 1.2
        );
        insert financialSettings;

        Contact contact = new Contact();
        contact.FirstName = 'Test';
        contact.LastName = 'PaymentSplit';
        contact.CRM_ID_Backend__c = 12345;
        insert contact;

        Campaign campaignFY = new Campaign();
        campaignFY.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Financial Year').getRecordTypeId();
        campaignFY.Name = 'Financial Year 2021/22';
        campaignFY.IsActive = TRUE;
        insert campaignFY;

        Campaign campaignCampaignMembership = new Campaign();
        campaignCampaignMembership.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Campaign').getRecordTypeId();
        campaignCampaignMembership.Name = 'Memberships 2021/22';
        campaignCampaignMembership.IsActive = TRUE;
        campaignCampaignMembership.ParentId = campaignFY.Id;
        insert campaignCampaignMembership;

        Campaign campaignFundMembership = new Campaign();
        campaignFundMembership.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Fund').getRecordTypeId();
        campaignFundMembership.Name = 'ENO Friends Membership 2021/22';
        campaignFundMembership.IsActive = TRUE;
        campaignFundMembership.ParentId = campaignCampaignMembership.Id;
        campaignFundMembership.Opportunity_Record_Type_Name__c = 'Memberships';
        campaignFundMembership.General_Ledger_Code__c = '12006';
        campaignFundMembership.Department_Code__c = 'D337';
        campaignFundMembership.Project_Code__c = '1546';
        campaignFundMembership.VAT1__c = 'STD';
        campaignFundMembership.VAT2__c = 'GENERAL';
        campaignFundMembership.VAT3__c = 'UKVAT';
        campaignFundMembership.VAT4__c = 'SALE';
        campaignFundMembership.Direct_Debit_Gifts__c = '50506';
        campaignFundMembership.Non_Direct_Debit_Gifts__c = '60207';
        campaignFundMembership.Gift_Aid__c = '50114';
        insert campaignFundMembership;

        Opportunity opportunityMembership = new Opportunity();
        opportunityMembership.Name = 'Opp Membership Test PaymentSplit';
        opportunityMembership.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Memberships').getRecordTypeId();
        opportunityMembership.Amount = 100;
        opportunityMembership.npsp__Primary_Contact__c = contact.Id;
        opportunityMembership.StageName = 'Paid';
        opportunityMembership.CloseDate = System.today();
        opportunityMembership.CampaignId = campaignFundMembership.Id;
        opportunityMembership.npe01__Membership_Start_Date__c = System.today().addMonths(-3);
        opportunityMembership.npe01__Membership_End_Date__c = opportunityMembership.npe01__Membership_Start_Date__c.addYears(1);
        opportunityMembership.Membership_Scheme__c = 'ENO Friends';
        opportunityMembership.npe01__Member_Level__c = 'ENO Friends Bronze';
        insert opportunityMembership;
    }

    @IsTest
    public static void createPaymentSplitTest(){
        String membershipRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Memberships').getRecordTypeId();
        String nameOpp = 'ENO Friends Bronze ' + System.today().format();

        npe01__OppPayment__c oppPayment = [
                SELECT Id, npe01__Opportunity__r.npsp__Primary_Contact__r.CRM_ID_Backend__c, npe01__Opportunity__r.npsp__Primary_Contact__r.LastName,
                        npe01__Opportunity__r.npsp__Primary_Contact__r.FirstName, npe01__Opportunity__r.Campaign.General_Ledger_Code__c,
                        npe01__Opportunity__r.Campaign.Department_Code__c, npe01__Opportunity__r.Campaign.Project_Code__c, npe01__Opportunity__r.Campaign.VAT1__c,
                        npe01__Opportunity__r.Campaign.VAT2__c, npe01__Opportunity__r.Campaign.VAT3__c, npe01__Opportunity__r.Campaign.VAT4__c
                FROM npe01__OppPayment__c
                WHERE npe01__Paid__c = TRUE AND Splits_Created__c = FALSE
                AND npe01__Opportunity__r.RecordTypeId =: membershipRecordTypeId AND npe01__Opportunity__r.Name =: nameOpp
        ];

        Test.startTest();
        Split__c testSplit = new Split__c();
        testSplit.Payment__c = oppPayment.Id;
        testSplit.CRM_ID__c = oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.CRM_ID_Backend__c;
        testSplit.Surname__c = oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.LastName;
        testSplit.First_Name__c = oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.FirstName;
        testSplit.Account_No__c = oppPayment.npe01__Opportunity__r.Campaign.General_Ledger_Code__c;
        testSplit.Shortcut_Dimension_1_Code__c = oppPayment.npe01__Opportunity__r.Campaign.Department_Code__c;
        testSplit.Shortcut_Dimension_2_Code__c = oppPayment.npe01__Opportunity__r.Campaign.Project_Code__c;
        testSplit.VAT_Prod_Posting_Group73912_XP__c = oppPayment.npe01__Opportunity__r.Campaign.VAT1__c;
        testSplit.VAT_Bus_Posting_Group__c = oppPayment.npe01__Opportunity__r.Campaign.VAT2__c;
        testSplit.Gen_Prod_Posting_Group__c = oppPayment.npe01__Opportunity__r.Campaign.VAT3__c;
        testSplit.Gen_Posting_Type__c = oppPayment.npe01__Opportunity__r.Campaign.VAT4__c;

        Split__c split = ConstantsUtilsPaymentsSplit.createPaymentSplit(
                oppPayment.Id,
                oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.CRM_ID_Backend__c,
                oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.LastName,
                oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.FirstName,
                oppPayment.npe01__Opportunity__r.Campaign.General_Ledger_Code__c,
                oppPayment.npe01__Opportunity__r.Campaign.Department_Code__c,
                oppPayment.npe01__Opportunity__r.Campaign.Project_Code__c,
                oppPayment.npe01__Opportunity__r.Campaign.VAT1__c,
                oppPayment.npe01__Opportunity__r.Campaign.VAT2__c,
                oppPayment.npe01__Opportunity__r.Campaign.VAT3__c,
                oppPayment.npe01__Opportunity__r.Campaign.VAT4__c
        );
        System.assertEquals(testSplit.CRM_ID__c, split.CRM_ID__c);
        System.assertEquals(testSplit.Surname__c, split.Surname__c);
        System.assertEquals(testSplit.Account_No__c, split.Account_No__c);
        System.assertEquals(testSplit.Shortcut_Dimension_1_Code__c, split.Shortcut_Dimension_1_Code__c);
        Test.stopTest();
    }

    @IsTest
    public static void createMembershipSplitMapTest(){
        Map<String, Decimal> membershipSplitMapTest = new Map<String, Decimal>();
        Map<String, Membership_Level_Benefit__mdt> mlbMap = Membership_Level_Benefit__mdt.getAll();
        for(String membershipLevelBenefit : mlbMap.keySet()){
            membershipSplitMapTest.put(mlbMap.get(membershipLevelBenefit).Membership_Name__c, mlbMap.get(membershipLevelBenefit).Benefit_Value__c);
        }

        Test.startTest();
        Map<String, Decimal> membershipSplitMap = ConstantsUtilsPaymentsSplit.createMembershipSplitMap();
        System.assertEquals(membershipSplitMapTest, membershipSplitMap);
        Test.stopTest();
    }

}