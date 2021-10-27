trigger B25_Reservation on B25__Reservation__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    Trigger_B25_Reservation.run();
}