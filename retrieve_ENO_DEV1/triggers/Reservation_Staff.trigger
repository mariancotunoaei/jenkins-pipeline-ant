trigger Reservation_Staff on Reservation_Staff__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    B25.DimensionJunctionTriggerHook.execute();

    Trigger_Reservation_Staff.run();
}