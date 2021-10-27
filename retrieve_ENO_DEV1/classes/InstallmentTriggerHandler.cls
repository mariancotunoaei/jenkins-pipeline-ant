/**
 * Created by ibuzau on 8/13/2021.
 */

public with sharing class InstallmentTriggerHandler {
    public static void afterInsert(List<cpm__Installment__c> installments) {
        updateOppotunities(installments);

    }

    private static void updateOppotunities(List<cpm__Installment__c> installments) {
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp;

        For(cpm__Installment__c currentInstallment : installments){
            opp = new Opportunity(Id = currentInstallment.npsp4hub__Opportunity__c,
                    Last_installment__c = currentInstallment.Id);
            oppList.add(opp);
        }

        update oppList;
    }

}