trigger InstallmentTrigger on cpm__Installment__c (after insert) {

    if (Trigger.isInsert) {
        if (Trigger.isAfter) {
            InstallmentTriggerHandler.afterInsert(Trigger.new); 
        }
    }
}