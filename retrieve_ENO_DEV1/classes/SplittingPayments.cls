/**
 * Created by amacari on 6/24/2021.
 */

public with sharing class SplittingPayments {


    public static void SplitPayments() {

        Map<String, Decimal> membershipSplitMap = ConstantsUtilsPaymentsSplit.createMembershipSplitMap();

        List<npe01__OppPayment__c> oppPayments = [
                SELECT npe01__Payment_Amount__c, Splits_Created__c, npe01__Check_Reference_Number__c,
                        npe01__Opportunity__r.npe01__Member_Level__c, npe01__Opportunity__r.npsp__Primary_Contact__r.FirstName, npe01__Opportunity__r.RecordTypeId,
                        npe01__Opportunity__r.npsp__Primary_Contact__r.LastName, npe01__Opportunity__r.npsp__Primary_Contact__r.CRM_ID_Backend__c,
                        npe01__Opportunity__r.npsp__Primary_Contact__r.gaid__Has_Valid_GAD_Now__c, npe01__Opportunity__r.Campaign.General_Ledger_Code__c,
                        npe01__Opportunity__r.Campaign.Department_Code__c, npe01__Opportunity__r.Campaign.Project_Code__c, npe01__Opportunity__r.Campaign.VAT1__c,
                        npe01__Opportunity__r.Campaign.VAT2__c, npe01__Opportunity__r.Campaign.VAT3__c, npe01__Opportunity__r.Campaign.VAT4__c,
                        npe01__Opportunity__r.Campaign.Direct_Debit_Gifts__c, npe01__Opportunity__r.Campaign.Non_Direct_Debit_Gifts__c,
                        npe01__Opportunity__r.Campaign.Gift_Aid__c, npe01__Opportunity__r.npe03__Recurring_Donation__c, npe01__Opportunity__r.npe01__Number_of_Payments__c
                FROM npe01__OppPayment__c
                WHERE npe01__Paid__c = TRUE AND Splits_Created__c = FALSE AND npe01__Opportunity__r.RecordTypeId IN : ConstantsUtilsPaymentsSplit.RECORD_TYPE_ID_LIST
        ];

        system.debug('size: ' + oppPayments.size());
        List<Split__c> splits = new List<Split__c>();
        for(npe01__OppPayment__c oppPayment : oppPayments){
            Decimal donationValue;
            if(oppPayment.npe01__Opportunity__r.RecordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Memberships').getRecordTypeId()) {
                Decimal annualBenefit = membershipSplitMap.get(oppPayment.npe01__Opportunity__r.npe01__Member_Level__c);
                System.debug('oppPaymentId ' + oppPayment.Id);
                System.debug('annual benefit ' + annualBenefit);
                System.debug('oppPayment.npe01__Opportunity__r.npe03__Recurring_Donation__c ' + oppPayment.npe01__Opportunity__r.npe03__Recurring_Donation__c);
                System.debug('oppPayment.npe01__Opportunity__r.npe01__Number_of_Payments__c ' + oppPayment.npe01__Opportunity__r.npe01__Number_of_Payments__c);
                System.debug('ConstantsUtilsPaymentsSplit.FINANCIAL_SETTINGS.Annual_Non_VAT__c ' + ConstantsUtilsPaymentsSplit.FINANCIAL_SETTINGS.Annual_Non_VAT__c);
                System.debug('ConstantsUtilsPaymentsSplit.FINANCIAL_SETTINGS.VAT_Value__c ' + ConstantsUtilsPaymentsSplit.FINANCIAL_SETTINGS.VAT_Value__c);
                System.debug('\n\n');

                Decimal annualVatable = (oppPayment.npe01__Opportunity__r.npe03__Recurring_Donation__c != null && oppPayment.npe01__Opportunity__r.npe01__Number_of_Payments__c == 12) ? ((annualBenefit - ConstantsUtilsPaymentsSplit.FINANCIAL_SETTINGS.Annual_Non_VAT__c) / ConstantsUtilsPaymentsSplit.FINANCIAL_SETTINGS.VAT_Value__c) / 12 : (annualBenefit - ConstantsUtilsPaymentsSplit.FINANCIAL_SETTINGS.Annual_Non_VAT__c) / ConstantsUtilsPaymentsSplit.FINANCIAL_SETTINGS.VAT_Value__c;
                donationValue = (oppPayment.npe01__Opportunity__r.npe03__Recurring_Donation__c != null && oppPayment.npe01__Opportunity__r.npe01__Number_of_Payments__c == 12) ? oppPayment.npe01__Payment_Amount__c - annualBenefit / 12 : oppPayment.npe01__Payment_Amount__c - annualBenefit;
                Decimal annualVAT = (oppPayment.npe01__Opportunity__r.npe03__Recurring_Donation__c != null && oppPayment.npe01__Opportunity__r.npe01__Number_of_Payments__c == 12) ? (annualBenefit - ConstantsUtilsPaymentsSplit.FINANCIAL_SETTINGS.Annual_Non_VAT__c - annualVatable) / 12 : annualBenefit - ConstantsUtilsPaymentsSplit.FINANCIAL_SETTINGS.Annual_Non_VAT__c - annualVatable;
                Decimal annualVatableAnnualVAT = annualVatable + annualVAT;

                // amount
                Split__c splitAmount = ConstantsUtilsPaymentsSplit.createPaymentSplit(
                        oppPayment.Id,
                        oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.CRM_ID_Backend__c,
                        oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.LastName,
                        oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.FirstName,
                        oppPayment.npe01__Opportunity__r.Campaign.General_Ledger_Code__c,
                        oppPayment.npe01__Opportunity__r.Campaign.Department_Code__c,
                        oppPayment.npe01__Opportunity__r.Campaign.Project_Code__c,
                        null, null, null, null
                );
                splitAmount.Amount__c = oppPayment.npe01__Payment_Amount__c;
                splitAmount.Account_No__c = oppPayment.npe01__Opportunity__r.npe03__Recurring_Donation__c != null ? oppPayment.npe01__Opportunity__r.Campaign.Direct_Debit_Gifts__c : oppPayment.npe01__Opportunity__r.Campaign.Non_Direct_Debit_Gifts__c;
                splits.add(splitAmount);

                // annualVatableAnnualVAT
                Split__c splitAnnualVatableAnnualVAT = ConstantsUtilsPaymentsSplit.createPaymentSplit(
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
                splitAnnualVatableAnnualVAT.Amount__c = -annualVatableAnnualVAT;
                splits.add(splitAnnualVatableAnnualVAT);

                // donationValue
                Split__c splitDonationValue = ConstantsUtilsPaymentsSplit.createPaymentSplit(
                        oppPayment.Id,
                        oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.CRM_ID_Backend__c,
                        oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.LastName,
                        oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.FirstName,
                        oppPayment.npe01__Opportunity__r.Campaign.General_Ledger_Code__c,
                        oppPayment.npe01__Opportunity__r.Campaign.Department_Code__c,
                        oppPayment.npe01__Opportunity__r.Campaign.Project_Code__c,
                        null, null, null, null
                );
                splitDonationValue.Amount__c = -donationValue;
                splits.add(splitDonationValue);

                // constfixa annualNonVatable
                Split__c splitAnnualNonVatable = ConstantsUtilsPaymentsSplit.createPaymentSplit(
                        oppPayment.Id,
                        oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.CRM_ID_Backend__c,
                        oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.LastName,
                        oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.FirstName,
                        oppPayment.npe01__Opportunity__r.Campaign.General_Ledger_Code__c,
                        oppPayment.npe01__Opportunity__r.Campaign.Department_Code__c,
                        oppPayment.npe01__Opportunity__r.Campaign.Project_Code__c,
                        'ZERO',
                        oppPayment.npe01__Opportunity__r.Campaign.VAT2__c,
                        oppPayment.npe01__Opportunity__r.Campaign.VAT3__c,
                        oppPayment.npe01__Opportunity__r.Campaign.VAT4__c
                );
                splitAnnualNonVatable.Amount__c = (oppPayment.npe01__Opportunity__r.npe03__Recurring_Donation__c != null && oppPayment.npe01__Opportunity__r.npe01__Number_of_Payments__c == 12) ? -ConstantsUtilsPaymentsSplit.FINANCIAL_SETTINGS.Annual_Non_VAT__c / 12 : -ConstantsUtilsPaymentsSplit.FINANCIAL_SETTINGS.Annual_Non_VAT__c;
                splits.add(splitAnnualNonVatable);

                oppPayment.Annual_VAT__c = annualVAT;

            } else {
                donationValue = oppPayment.npe01__Payment_Amount__c;
                Split__c splitDonationValue = ConstantsUtilsPaymentsSplit.createPaymentSplit(oppPayment.Id,
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
                Split__c splitDonationValueneg = ConstantsUtilsPaymentsSplit.createPaymentSplit(oppPayment.Id,
                        oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.CRM_ID_Backend__c,
                        oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.LastName,
                        oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.FirstName,
                        oppPayment.npe01__Opportunity__r.Campaign.General_Ledger_Code__c,
                        oppPayment.npe01__Opportunity__r.Campaign.Department_Code__c,
                        oppPayment.npe01__Opportunity__r.Campaign.Project_Code__c,
                        null, null, null, null);
                splitDonationValueneg.Amount__c = -donationValue;
                splits.add(splitDonationValueneg);
            }
            // GAD
            if (oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.gaid__Has_Valid_GAD_Now__c == TRUE &&
                    oppPayment.npe01__Opportunity__r.RecordTypeId != Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('In-Kind Gift').getRecordTypeId() &&
                    oppPayment.npe01__Opportunity__r.RecordTypeId != Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Grant').getRecordTypeId()) {
                Decimal annualGAD = donationValue * ConstantsUtilsPaymentsSplit.FINANCIAL_SETTINGS.Gift_Aid_Percent__c;
                Split__c splitAnnualGADin = ConstantsUtilsPaymentsSplit.createPaymentSplit(
                        oppPayment.Id,
                        oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.CRM_ID_Backend__c,
                        oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.LastName,
                        oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.FirstName,
                        oppPayment.npe01__Opportunity__r.Campaign.Gift_Aid__c,
                        null, null, null, null, null, null);
                splitAnnualGADin.Amount__c = annualGAD;
                splits.add(splitAnnualGADin);

                Split__c splitAnnualGADout = ConstantsUtilsPaymentsSplit.createPaymentSplit(
                        oppPayment.Id,
                        oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.CRM_ID_Backend__c,
                        oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.LastName,
                        oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.FirstName,
                        '12005',
                        oppPayment.npe01__Opportunity__r.Campaign.Department_Code__c,
                        null, null, null, null, null);
                splitAnnualGADout.Amount__c = -annualGAD;
                splits.add(splitAnnualGADout);

                oppPayment.GAD_Split__c = TRUE;
            }

            oppPayment.Splits_Created__c = TRUE;
        }

        insert splits;
        update oppPayments;
    }

}