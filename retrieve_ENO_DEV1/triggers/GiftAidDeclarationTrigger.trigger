trigger GiftAidDeclarationTrigger on gaid__Gift_Aid_Declaration__c (before insert, before update, after insert, after update) {

    if(Trigger.isBefore) {
        if(Trigger.isInsert) {
            GiftAidDeclarationTriggerHandler.handleBeforeInsertTrigger(Trigger.New);
        }
        if(Trigger.isUpdate) {
            GiftAidDeclarationTriggerHandler.handleBeforeUpdateTrigger(Trigger.Old, Trigger.New);
        }
    }

    if (Trigger.isAfter) {
        if(Trigger.isInsert) {
            GiftAidDeclarationTriggerHandler.handleAfterInsertTrigger(Trigger.New);
        }
        if(Trigger.isUpdate) {
            GiftAidDeclarationTriggerHandler.handleAfterUpdateTrigger(Trigger.Old, Trigger.New);
        }
    }

}