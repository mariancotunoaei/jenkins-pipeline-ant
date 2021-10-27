/**
 * Created by amacari on 7/5/2021.
 */

public with sharing class GiftAidDeclarationTriggerHandler {

    public static void handleBeforeInsertTrigger(List<gaid__Gift_Aid_Declaration__c> newGiftAidList) {

    }

    public static void handleBeforeUpdateTrigger(List<gaid__Gift_Aid_Declaration__c> oldGiftAidList, List<gaid__Gift_Aid_Declaration__c> newGiftAidList) {

    }

    public static void handleAfterInsertTrigger(List<gaid__Gift_Aid_Declaration__c> newGiftAidList) {
        System.debug('Gift Aid Declaration After Insert');
        recalculateSplitPayments(newGiftAidList);
    }

    public static void handleAfterUpdateTrigger(List<gaid__Gift_Aid_Declaration__c> oldGiftAidList, List<gaid__Gift_Aid_Declaration__c> newGiftAidList) {
        System.debug('Gift Aid Declaration After Update');
        recalculateSplitPayments(newGiftAidList);
    }

    public static void recalculateSplitPayments(List<gaid__Gift_Aid_Declaration__c> newGiftAidList){

        Map<String, Decimal> membershipSplitMap = ConstantsUtilsPaymentsSplit.createMembershipSplitMap();
        Date limitDate = System.today().addYears(-4);
        System.debug('limitDate:' + limitDate);

        List<Id> contactIds = new List<Id>();
        for(gaid__Gift_Aid_Declaration__c giftAidDeclaration : newGiftAidList){
            if (giftAidDeclaration.gaid__Valid_Now__c == true) {
                contactIds.add(giftAidDeclaration.gaid__Contact__c);
            }
        }

        System.debug(contactIds);


        List<npe01__OppPayment__c> oppPayments = [
                SELECT npe01__Payment_Amount__c, npe01__Check_Reference_Number__c, npe01__Opportunity__r.RecordTypeId,
                        npe01__Opportunity__r.npe01__Member_Level__c, npe01__Opportunity__r.npsp__Primary_Contact__r.FirstName,
                        npe01__Opportunity__r.npsp__Primary_Contact__r.LastName, npe01__Opportunity__r.npsp__Primary_Contact__r.CRM_ID_Backend__c,
                        npe01__Opportunity__r.Campaign.Department_Code__c, npe01__Opportunity__r.Campaign.Gift_Aid__c,
                        npe01__Opportunity__r.npe03__Recurring_Donation__c, npe01__Opportunity__r.npe01__Number_of_Payments__c
                FROM npe01__OppPayment__c
                WHERE npe01__Paid__c = TRUE AND Splits_Created__c = TRUE AND GAD_Split__c = FALSE
                AND npe01__Opportunity__r.RecordTypeId IN : ConstantsUtilsPaymentsSplit.RECORD_TYPE_ID_LIST
                AND npe01__Opportunity__r.npsp__Primary_Contact__c IN : contactIds
                AND npe01__Payment_Date__c >= : limitDate
        ];

        System.debug(oppPayments);

        List<Split__c> splits = new List<Split__c>();
        for(npe01__OppPayment__c oppPayment : oppPayments){
            if(oppPayment.npe01__Opportunity__r.RecordTypeId != Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('In-Kind Gift').getRecordTypeId() &&
                    oppPayment.npe01__Opportunity__r.RecordTypeId != Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Grant').getRecordTypeId()) {
                Decimal donationValue;
                if(oppPayment.npe01__Opportunity__r.RecordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Memberships').getRecordTypeId()) {
                    Decimal annualBenefit = membershipSplitMap.get(oppPayment.npe01__Opportunity__r.npe01__Member_Level__c);
                    donationValue = (oppPayment.npe01__Opportunity__r.npe03__Recurring_Donation__c != null && oppPayment.npe01__Opportunity__r.npe01__Number_of_Payments__c == 12) ? oppPayment.npe01__Payment_Amount__c - annualBenefit / 12 : oppPayment.npe01__Payment_Amount__c - annualBenefit;
                } else {
                    donationValue = oppPayment.npe01__Payment_Amount__c;
                }
                Decimal annualGAD = donationValue * ConstantsUtilsPaymentsSplit.FINANCIAL_SETTINGS.Gift_Aid_Percent__c;
                Split__c splitAnnualGADin = ConstantsUtilsPaymentsSplit.createPaymentSplit(
                        oppPayment.Id,
                        oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.CRM_ID_Backend__c,
                        oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.LastName,
                        oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.FirstName,
                        oppPayment.npe01__Opportunity__r.Campaign.Gift_Aid__c,
                        null, null, null, null, null, null
                );
                splitAnnualGADin.Amount__c = annualGAD;
                splits.add(splitAnnualGADin);

                Split__c splitAnnualGADout = ConstantsUtilsPaymentsSplit.createPaymentSplit(
                        oppPayment.Id,
                        oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.CRM_ID_Backend__c,
                        oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.LastName,
                        oppPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.FirstName,
                        '12005',
                        oppPayment.npe01__Opportunity__r.Campaign.Department_Code__c,
                        null, null, null, null, null
                );
                splitAnnualGADout.Amount__c = -annualGAD;
                splits.add(splitAnnualGADout);

                oppPayment.GAD_Split__c = true;
            }
        }

        insert splits;
        update oppPayments;

    }

}