trigger Work_Period on Work_Period__c  (before insert, after insert, before update, after update, before delete, after delete) {
    Trigger_Work_Period.run();
}