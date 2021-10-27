/**
 * Created by amacari on 6/22/2021.
 */

trigger OpportunityTrigger on Opportunity (before insert, before update) {

    if (Trigger.isBefore) {
        List<Opportunity> membershipList = new List<Opportunity>();
        for (Opportunity opportunity : Trigger.new) {
            if (opportunity.RecordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Membership').getRecordTypeId()) {
                opportunity.Name = opportunity.npe01__Member_Level__c + ' ' + opportunity.CloseDate.format();
                membershipList.add(opportunity);
            }
        }

        if (Trigger.isInsert) {
            OpportunityTriggerHandler.beforeInsert(membershipList);
        }
        if (Trigger.isUpdate) {
            OpportunityTriggerHandler.beforeUpdate(membershipList);
        }
    } else if (Trigger.isAfter) {
        if (Trigger.isInsert) {

            OpportunityTriggerHandler.afterInsert();
        }
        if (Trigger.isUpdate) {

            OpportunityTriggerHandler.afterUpdate();
        }
    }

}