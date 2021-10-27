trigger dlrs_B25_ReservationTrigger on B25__Reservation__c(before delete, before insert, before update, after delete, after insert, after undelete, after update){
    dlrs.RollupService.triggerHandler(B25__Reservation__c.SObjectType);
}