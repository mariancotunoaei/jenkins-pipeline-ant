trigger Reservation_Performer on Reservation_Performer__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    B25.DimensionJunctionTriggerHook.execute();
}