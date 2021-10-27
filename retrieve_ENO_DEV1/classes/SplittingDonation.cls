/**
 * Created by ibuzau on 6/28/2021.
 */

public with sharing class SplittingDonation {

    public static Split__c createPaymentSplit(Id paymentId, Decimal crmId, String lastName, String firstName, String generalLedgerCode, String departmentCode, String projectCode, String VAT1, String VAT2, String VAT3, String VAT4) {
        Split__c split = new Split__c();
        split.Payment__c = paymentId;
        split.CRM_ID__c = crmId;
        split.Surname__c = lastName;
        split.First_Name__c = firstName;
        split.Account_No__c = generalLedgerCode;
        split.Shortcut_Dimension_1_Code__c = departmentCode;
        split.Shortcut_Dimension_2_Code__c = projectCode;
        split.VAT_Prod_Posting_Group73912_XP__c = VAT1;
        split.VAT_Bus_Posting_Group__c = VAT2;
        split.Gen_Prod_Posting_Group__c = VAT3;
        split.Gen_Posting_Type__c = VAT4;
        return split;
    }

    public static void execute(SchedulableContext ctx) {

        Financial_Settings__c financialSettings = [
                SELECT Annual_Non_VAT__c, Gift_Aid_Percent__c, VAT_Value__c
                FROM Financial_Settings__c
        ];
        List<String> recordTypesIdList = new List<String>();
        recordTypesIdList.add(Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Donation').getRecordTypeId());
        recordTypesIdList.add(Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('In-Kind Gift').getRecordTypeId());
        recordTypesIdList.add(Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Grant').getRecordTypeId());
        recordTypesIdList.add(Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Philathropy').getRecordTypeId());
        System.debug(recordTypesIdList);

        List<npe01__OppPayment__c> oppPayments = [
                SELECT npe01__Payment_Amount__c, Splits_Created__c, npe01__Check_Reference_Number__c, npe01__Payment_Method__c,
                        npe01__Opportunity__r.npe01__Member_Level__c,npe01__Opportunity__r.npsp__Primary_Contact__r.FirstName,
                        npe01__Opportunity__r.npsp__Primary_Contact__r.LastName, npe01__Opportunity__r.npsp__Primary_Contact__r.CRM_ID_Backend__c,
                        npe01__Opportunity__r.npsp__Primary_Contact__r.gaid__Active_Gift_Aid_Declarations__c, npe01__Opportunity__r.Campaign.General_Ledger_Code__c,
                        npe01__Opportunity__r.Campaign.Department_Code__c, npe01__Opportunity__r.Campaign.Project_Code__c, npe01__Opportunity__r.Campaign.VAT1__c,
                        npe01__Opportunity__r.Campaign.VAT2__c, npe01__Opportunity__r.Campaign.VAT3__c, npe01__Opportunity__r.Campaign.VAT4__c,
                        npe01__Opportunity__r.Campaign.Direct_Debit_Gifts__c, npe01__Opportunity__r.Campaign.Non_Direct_Debit_Gifts__c, npe01__Opportunity__r.Campaign.Gift_Aid__c
                FROM npe01__OppPayment__c
                WHERE npe01__Paid__c = TRUE AND Splits_Created__c = FALSE AND npe01__Opportunity__r.RecordTypeId in :recordTypesIdList

        ];
        System.debug(oppPayments.size());

        List<Split__c> splits = new List<Split__c>();
        for (npe01__OppPayment__c oppPayment : oppPayments) {
            Decimal donationValue = oppPayment.npe01__Payment_Amount__c;

            // donationValue
            Split__c splitDonationValue = createPaymentSplit(oppPayment.Id,
                    oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.CRM_ID_Backend__c,
                    oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.LastName,
                    oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.FirstName,
                    oppPayment.npe01__Opportunity__r.Campaign.Non_Direct_Debit_Gifts__c,
                    oppPayment.npe01__Opportunity__r.Campaign.Department_Code__c,
                    oppPayment.npe01__Opportunity__r.Campaign.Project_Code__c,
                    null, null, null, null);
            splitDonationValue.Amount__c = donationValue;
            splits.add(splitDonationValue);

            // donationValue
            Split__c splitDonationValueneg = createPaymentSplit(oppPayment.Id,
                    oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.CRM_ID_Backend__c,
                    oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.LastName,
                    oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.FirstName,
                    oppPayment.npe01__Opportunity__r.Campaign.General_Ledger_Code__c,
                    oppPayment.npe01__Opportunity__r.Campaign.Department_Code__c,
                    oppPayment.npe01__Opportunity__r.Campaign.Project_Code__c,
                    null, null, null, null);
            splitDonationValueneg.Amount__c = -donationValue;
            splits.add(splitDonationValueneg);
            // gift aid
            if (oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.gaid__Active_Gift_Aid_Declarations__c > 0) {
                Decimal annualGAD = donationValue * financialSettings.Gift_Aid_Percent__c;
                Split__c splitAnnualGADin = createPaymentSplit(oppPayment.Id,
                        oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.CRM_ID_Backend__c,
                        oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.LastName,
                        oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.FirstName,
                        oppPayment.npe01__Opportunity__r.Campaign.Gift_Aid__c,
                        null, null, null, null, null, null);
                splitAnnualGADin.Amount__c = annualGAD;
                splits.add(splitAnnualGADin);

                Split__c splitAnnualGADout = createPaymentSplit(oppPayment.Id,
                        oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.CRM_ID_Backend__c,
                        oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.LastName,
                        oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.FirstName,
                        '12005', oppPayment.npe01__Opportunity__r.Campaign.Department_Code__c,
                        null, null, null, null, null);
                splitAnnualGADout.Amount__c = -annualGAD;
                splits.add(splitAnnualGADout);

            }

            oppPayment.Splits_Created__c = TRUE;
        }
        insert splits;
        update oppPayments;
    }
}