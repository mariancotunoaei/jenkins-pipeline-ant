public class Trigger_Reservation_Staff {
    public static void run() {
		if (!Trigger.isExecuting) {
			return;
		}

        Trigger_Reservation_Staff.setUserField();
    }

    public static void setUserField() {
        if(!(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate))){
            return;
        }

        List<Id> staffids = new List<Id>();
        List<Reservation_Staff__c> iterList = Trigger.new;
        for(Reservation_Staff__c resStaff : iterList){
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

        for(Reservation_Staff__c resStaff : iterList){
            if(staffMap.containsKey(resStaff.Staff__c)){
                resStaff.User__c = staffMap.get(resStaff.Staff__c);
            }
        }
    }
}