/**
 * Created by amacari on 7/5/2021.
 */

public with sharing class ConstantsUtilsPaymentsSplit {

    public static Split__c createPaymentSplit(Id paymentId, Decimal crmId, String lastName, String firstName, String generalLedgerCode, String departmentCode, String projectCode, String VAT1, String VAT2, String VAT3, String VAT4){
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

    public static Map<String, Decimal> createMembershipSplitMap(){
        Map<String, Decimal> membershipSplitMap = new Map<String, Decimal>();
        Map<String, Membership_Level_Benefit__mdt> mlbMap = Membership_Level_Benefit__mdt.getAll();
        for(String membershipLevelBenefit : mlbMap.keySet()){
            membershipSplitMap.put(mlbMap.get(membershipLevelBenefit).Membership_Name__c, mlbMap.get(membershipLevelBenefit).Benefit_Value__c);
        }
        return membershipSplitMap;
    }

    public static final List<String> RECORD_TYPE_ID_LIST = new List<String> {
            Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Donation').getRecordTypeId(),
            Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('In-Kind Gift').getRecordTypeId(),
            Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Grant').getRecordTypeId(),
            Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Philanthropy').getRecordTypeId(),
            Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Memberships').getRecordTypeId()
    };

    public static final Financial_Settings__c FINANCIAL_SETTINGS = [
            SELECT Annual_Non_VAT__c, Gift_Aid_Percent__c, VAT_Value__c
            FROM Financial_Settings__c
    ];

}