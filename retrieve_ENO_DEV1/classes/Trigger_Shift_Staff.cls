public class Trigger_Shift_Staff {
    public static void run() {
		if (!Trigger.isExecuting) {
			return;
		}

        Trigger_Shift_Staff.setUserField();

        Trigger_Shift_Staff.acceptedOvertime();
        Trigger_Shift_Staff.convertOvertime();
    }

    public static void setUserField() {
        if(!(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate))){
            return;
        }

        List<Id> staffids = new List<Id>();
        List<Shift_Staff__c> iterList = Trigger.new;
        for(Shift_Staff__c resStaff : iterList){
            staffids.add(resStaff.Staff__c);
        } 

        List<B25__Staff__c> staffMembers = [
            SELECT Id, B25__User__c
            FROM B25__Staff__c
            WHERE Id IN :staffids
            AND B25__User__c != null
        ];
        
        Map<Id, Id> staffMap = new Map<Id, Id>();
        for(B25__Staff__c staff : staffMembers){
            if(staff.B25__User__c != null) {
                staffMap.put(staff.Id, staff.B25__User__c);
            }
        }

        for(Shift_Staff__c resStaff : iterList){
            if(staffMap.containsKey(resStaff.Staff__c)){
                resStaff.User__c = staffMap.get(resStaff.Staff__c);
            }
        }
    }

    public static void acceptedOvertime(){
        if(!(Trigger.isAfter && Trigger.isUpdate)){
            return;
        }
 
        List<Id> resStaffids = new List<Id>();
        List<Shift_Staff__c> iterList = Trigger.new;
        for(Shift_Staff__c resStaff : iterList){
            resStaffids.add(resStaff.Id);
        }

        Set<String> recipientsIds = new Set<String>();
        Id targetId = null;
        List<Shift_Staff__c> reservationStaff = [
            SELECT Id, Staff__r.B25__User__c, Reservation__c, Status__c
            FROM Shift_Staff__c
            WHERE Id IN :resStaffids
            AND Is_Shift__c = true
        ];
        for(Shift_Staff__c resStaff : reservationStaff){
            if(resStaff.Staff__r.B25__User__c != null && resStaff.Status__c == 'Accepted'){
                recipientsIds.add(resStaff.Staff__r.B25__User__c);
                targetId = resStaff.Reservation__c;
            }
        }

        if(recipientsIds.size() > 0 && targetId != null){
            Util_Notifications.notifyUsersViaPush(recipientsIds, targetId, 'The overtime has been assigned to you', 'Overtime shift has been assigned to you.');
        }
    }

    public static void convertOvertime() {
        if(!(Trigger.isAfter && Trigger.isUpdate)){
            return;
        }

        List<Shift_Staff__c> resStaffToConvert = new List<Shift_Staff__c>();
        List<Id> resStaffNoResponse = new List<Id>();
        List<Shift_Staff__c> iterList = Trigger.new;
        for(Shift_Staff__c resStaff : iterList){
            if(resStaff.Status__c == 'Assigned'){
                resStaffToConvert.add(resStaff);
            } else if (resStaff.Status__c == 'No Response'){
                resStaffNoResponse.add(resStaff.Id);
            }
        }

        List<B25__Reservation__c> reservations = new List<B25__Reservation__c>();

        List<Id> reservationIds = new List<Id>();
        for(Shift_Staff__c staffMemberAssigned : resStaffToConvert){
            reservationIds.add(staffMemberAssigned.Reservation__c);
        }

        List<B25__Reservation__c> reservationList = [
            SELECT Id, B25__Start__c, B25__End__c, B25__User__c,
                Overtime__c, Run__c, B25__Account__c, B25__Contact__c, B25__Title__c,
                B25__Reservation_Type__c, B25__Resource__c, B25__Status__c, 
                B25__Notes__c, Performance_Fee__c, Allow_Double_Booking__c, Include_in_Amendments_sheet__c, 
                Secret__c, Work_Period__c, Umbrella_Arrangement__c, NCO__c
            FROM B25__Reservation__c
            WHERE id IN :reservationIds
        ];

        for(B25__Reservation__c reservation :reservationList){
            for(Shift_Staff__c shiftStaff : resStaffToConvert){
                B25__Reservation__c newRes = new B25__Reservation__c();
                newRes.B25__Staff__c = shiftStaff.Staff__c;
                newRes.B25__End__c = reservation.B25__End__c;
                newRes.B25__Start__c = reservation.B25__Start__c;
                newRes.B25__User__c = reservation.B25__User__c;
                newRes.Overtime__c = reservation.Overtime__c;
                newRes.Run__c = reservation.Run__c;
                newRes.B25__Account__c = reservation.B25__Account__c;
                newRes.B25__Contact__c = reservation.B25__Contact__c;
                newRes.B25__Title__c = reservation.B25__Title__c;
                newRes.B25__Reservation_Type__c = reservation.B25__Reservation_Type__c;
                newRes.B25__Resource__c = reservation.B25__Resource__c;
                newRes.B25__Status__c = reservation.B25__Status__c;
                newRes.B25__Notes__c = reservation.B25__Notes__c;
                newRes.Performance_Fee__c = reservation.Performance_Fee__c;
                newRes.Allow_Double_Booking__c = reservation.Allow_Double_Booking__c;
                newRes.Include_in_Amendments_sheet__c = reservation.Include_in_Amendments_sheet__c;
                newRes.Secret__c = reservation.Secret__c;
                newRes.Work_Period__c = reservation.Work_Period__c;
                newRes.Umbrella_Arrangement__c = reservation.Umbrella_Arrangement__c;
                newRes.NCO__c = reservation.NCO__c;
                newRes.Send_Assignment_Email__c = true;
                reservations.add(newRes);
            }
        }

        Database.insert(reservations);
        if(resStaffNoResponse.size() == 0){
            Database.delete(reservationList);
        }
    }
}