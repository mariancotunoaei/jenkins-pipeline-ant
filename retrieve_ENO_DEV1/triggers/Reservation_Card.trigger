trigger Reservation_Card on Reservation_Card__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    B25.DimensionJunctionTriggerHook.execute();
}