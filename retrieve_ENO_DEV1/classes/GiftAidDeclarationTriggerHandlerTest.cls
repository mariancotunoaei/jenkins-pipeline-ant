/**
 * Created by amacari on 7/8/2021.
 */

@IsTest
private class GiftAidDeclarationTriggerHandlerTest {

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
        contact.LastName = 'GADTrigger';
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

        Campaign campaignCampaignDonation = new Campaign();
        campaignCampaignDonation.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Campaign').getRecordTypeId();
        campaignCampaignDonation.Name = 'MicroDonations 2021/22';
        campaignCampaignDonation.IsActive = TRUE;
        campaignCampaignDonation.ParentId = campaignFY.Id;
        insert campaignCampaignDonation;

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

        Campaign campaignFundDonation = new Campaign();
        campaignFundDonation.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Fund').getRecordTypeId();
        campaignFundDonation.Name = 'SMS Donation 2021/22';
        campaignFundDonation.IsActive = TRUE;
        campaignFundDonation.ParentId = campaignCampaignDonation.Id;
        campaignFundDonation.Opportunity_Record_Type_Name__c = 'Donation';
        campaignFundDonation.General_Ledger_Code__c = '12002';
        campaignFundDonation.Department_Code__c = 'D338';
        campaignFundDonation.Project_Code__c = '1568';
        campaignFundDonation.VAT1__c = null;
        campaignFundDonation.VAT2__c = null;
        campaignFundDonation.VAT3__c = null;
        campaignFundDonation.VAT4__c = null;
        campaignFundDonation.Direct_Debit_Gifts__c = null;
        campaignFundDonation.Non_Direct_Debit_Gifts__c = '60207';
        campaignFundDonation.Gift_Aid__c = '50114';
        insert campaignFundDonation;

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

        Opportunity opportunityDonation = new Opportunity();
        opportunityDonation.Name = 'Opp Donation Test PaymentSplit';
        opportunityDonation.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Donation').getRecordTypeId();
        opportunityDonation.Amount = 100;
        opportunityDonation.npsp__Primary_Contact__c = contact.Id;
        opportunityDonation.StageName = 'Paid';
        opportunityDonation.CloseDate = System.today().addYears(-2);
        opportunityDonation.CampaignId = campaignFundDonation.Id;
        insert opportunityDonation;
    }

    @IsTest
    public static void recalculateSplitPaymentsTest(){
        Contact contact = [
                SELECT Id, FirstName, LastName, CRM_ID_Backend__c
                FROM Contact
                WHERE Name = 'Test GADTrigger'
        ];

        Opportunity oppDonation = [
                SELECT Id
                FROM Opportunity
                WHERE Name = 'Opp Donation Test PaymentSplit'
                AND npsp__Primary_Contact__c =: contact.Id
        ];

        npe01__OppPayment__c paymentDonation = [
                SELECT Id, npe01__Payment_Amount__c
                FROM npe01__OppPayment__c
                WHERE npe01__Opportunity__c =: oppDonation.Id
        ];

        paymentDonation.Splits_Created__c = true;
        update paymentDonation;

        List<gaid__Gift_Aid_Declaration__c> gadList = new List<gaid__Gift_Aid_Declaration__c>();

        Test.startTest();
        for(Integer i = 0; i <= 200; i++) {
            gaid__Gift_Aid_Declaration__c gad = new gaid__Gift_Aid_Declaration__c();
            gad.gaid__Start_Date__c = Date.today();
            gad.gaid__End_Date__c = Date.today().addMonths(i + 1);
            gad.gaid__Contact__c = contact.Id;

            gadList.add(gad);
        }
        insert gadList;

        GiftAidDeclarationTriggerHandler.recalculateSplitPayments(gadList);
        Test.stopTest();
    }

}