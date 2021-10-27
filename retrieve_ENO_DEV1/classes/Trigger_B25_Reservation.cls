public class Trigger_B25_Reservation {
    public static void run() {
		if (!Trigger.isExecuting) {
			return;
		}
        Trigger_B25_Reservation.setUser();
        Trigger_B25_Reservation.setOverTimeStatus();
    }

    public static void setUser(){
        if(!(Trigger.isBefore && Trigger.isInsert)){
            return;
        }

        List<B25__Reservation__c> iterList = Trigger.new;
        for(B25__Reservation__c reservation : iterList){
            if(reservation.B25__User__c == null){
                reservation.B25__User__c = Userinfo.getUserId();
            }
        }
    }

    public static void setOverTimeStatus(){
        if(!(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate))){
            return;
        }

        Id statusId = [SELECT Id FROM B25__Reservation_Status__c WHERE Name='Overtime']?.Id;

        if(statusId != null){
            List<B25__Reservation__c> iterList = Trigger.new;
            for(B25__Reservation__c reservation : iterList){
                if(reservation.Overtime__c) {
                    reservation.B25__Status__c = statusId;
                }
            }
        }
    }
}