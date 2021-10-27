trigger Shift_Staff on Shift_Staff__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    B25.DimensionJunctionTriggerHook.execute();

    Trigger_Shift_Staff.run();
}