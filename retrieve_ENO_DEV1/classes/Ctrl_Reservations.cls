public inherited sharing class Ctrl_Reservations {
    
    @AuraEnabled(cacheable=true)
    public static List<B25__Reservation__c> getReservations(String selectedDate, String period, String owner){
        try {

            
            Date dateSelected = Date.valueOf(selectedDate);
            Date dateStart = Date.today();
            Date dateEnd = dateStart.addDays(1);

            if(period == 'day'){
                dateStart = dateSelected;
                dateEnd = dateStart.addDays(1);
            } else if(period == 'week'){
                dateStart = dateSelected.toStartofWeek();
                dateEnd = dateStart.addDays(7);
            } else if(period == 'month'){
                dateStart = dateSelected.toStartOfMonth();
                dateEnd = dateStart.addMonths(1).addDays(-1);
            }


            if(owner == 'department'){
                String department = [SELECT Id, Department__c FROM B25__Staff__c WHERE B25__User__c = :Userinfo.getUserId() LIMIT 1].Department__c;
                return [
                    SELECT B25__Start__c, B25__End__c, Staff_Name__c, Acknowledged_by_Staff_Member__c,
                    Overtime__c, Registered_Absent__c, Shift_Completed__c, B25__Start_Date__c
                    FROM B25__Reservation__c
                    WHERE B25__Start_Date__c >= :dateStart
                    AND B25__Start_Date__c <= :dateEnd
                    AND B25__Staff__c != null 
                    AND B25__Staff__r.Virtual__c = false
                    AND Shift_Published__c = true
                    AND B25__Staff__r.Department__c = :department
                    AND Leave_Request_Status__c = null
                    AND B25__Status__r.Name != 'TOIL'
                    ORDER BY B25__Start__c
                ];
                
            } else {
                return [
                    SELECT B25__Start__c, B25__End__c, Staff_Name__c, Acknowledged_by_Staff_Member__c,
                    Overtime__c, Registered_Absent__c, Shift_Completed__c, B25__Start_Date__c
                    FROM B25__Reservation__c
                    WHERE B25__Start_Date__c >= :dateStart
                    AND B25__Start_Date__c <= :dateEnd
                    AND B25__Staff__c != null 
                    AND B25__Staff__r.Virtual__c = false
                    AND Shift_Published__c = true
                    AND B25__Staff__r.B25__User__c = :Userinfo.getUserId()
                    AND Leave_Request_Status__c = null
                    AND B25__Status__r.Name != 'TOIL'
                    ORDER BY B25__Start__c 
                ];
                
            }

            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true)
    public static List<B25__Reservation__c> getAllReservationsToday(){
        try {

            String department = [SELECT Id, Department__c FROM B25__Staff__c WHERE B25__User__c = :Userinfo.getUserId()].Department__c;

            return [
                SELECT B25__Start__c, B25__End__c, Staff_Name__c,
                    Registered_Absent__c, Acknowledged_by_Staff_Member__c
                FROM B25__Reservation__c
                WHERE B25__Start_Date__c = :Date.today()
                AND B25__Staff__c != null 
                AND B25__Staff__r.Virtual__c = false
                AND Shift_Published__c = true
                AND B25__Staff__r.Department__c = :department
                AND Leave_Request_Status__c = null
                ORDER BY B25__Start__c, B25__Staff__r.Name
            ];
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true)
    public static List<DataTableWrapper> getLeaveRequests(){
        try {

            Boolean enabledPermission = System.FeatureManagement.checkPermission('ENO_See_All_Leave_Requests');
            List<B25__Reservation__c> reservations = new List<B25__Reservation__c>();
            if(enabledPermission){
                String departmentName = [SELECT Department__c FROM B25__Staff__c WHERE B25__User__c = :UserInfo.getUserId() LIMIT 1].Department__c;
                reservations = [
                    SELECT Id, Name, B25__Start__c, B25__End__c, Leave_Request_Status__c, Staff_Name__c
                    FROM B25__Reservation__c
                    WHERE B25__Start_Date__c >= :Date.today()
                    AND Leave_Request_Status__c != null
                    AND B25__Status__r.Name = 'Absence holiday or approved leave'
                    AND B25__Staff__r.Department__c = :departmentName
                    ORDER BY B25__Start_Date__c
                ];
            } else {
                reservations = [
                    SELECT Id, Name, B25__Start__c, B25__End__c, Leave_Request_Status__c, Staff_Name__c
                    FROM B25__Reservation__c
                    WHERE B25__Start_Date__c >= :Date.today()
                    AND Leave_Request_Status__c != null
                    AND B25__Status__r.Name = 'Absence holiday or approved leave'
                    AND B25__Staff__r.B25__User__c = :Userinfo.getUserId()
                    ORDER BY B25__Start_Date__c
                ];
            }

            List<DataTableWrapper> response = new List<DataTableWrapper>();
            for(B25__Reservation__c res : reservations){
                DataTableWrapper obj = new DataTableWrapper();
                obj.recordId = res.Id;
                obj.leaveRequestStatus = res.Leave_Request_Status__c;
                obj.name = res.Name;
                obj.nameUrl = '/'+res.Id;
                obj.staffName = res.Staff_Name__c;
                obj.startDateTime = res.B25__Start__c;
                obj.endDateTime = res.B25__End__c;
                response.add(obj);
            }            

            return response;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private class DataTableWrapper {
        @AuraEnabled
        public Id recordId {get;set;}
        @AuraEnabled
        public String leaveRequestStatus {get;set;}
        @AuraEnabled
        public String name {get;set;}
        @AuraEnabled
        public String nameUrl {get;set;}
        @AuraEnabled
        public String staffName {get;set;}
        @AuraEnabled
        public Datetime startDateTime {get;set;}
        @AuraEnabled
        public Datetime endDateTime {get;set;}
    }
    
    @AuraEnabled
    public static void extendShift(List<B25__Reservation__c> reservationList, Integer minutes){
        try {

            for(B25__Reservation__c reservation :reservationList){
                reservation.B25__End__c = reservation.B25__End__c.addMinutes(minutes);
            }
            Database.update(reservationList);
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void completeShifts(List<B25__Reservation__c> reservationList){
        try {
            for(B25__Reservation__c reservation : reservationList){
                if(reservation.B25__Start__c < DateTime.now()){
                    reservation.Shift_Completed__c = true;
                }
            }
            Database.update(reservationList);

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void changeReservationStatus(List<B25__Reservation__c> reservationList, String action){
        try {
            Id statusid = null;
            if(action == 'Absent'){
                statusId = [SELECT ID FROM B25__Reservation_Status__c WHERE name = 'Absence unexplained' LIMIT 1].Id;
            } else if (action == 'Absent Sick'){
                statusId = [SELECT ID FROM B25__Reservation_Status__c WHERE name = 'Absence illness' LIMIT 1].Id;
            } else {
                statusId = [SELECT ID FROM B25__Reservation_Status__c WHERE name = 'Shift' LIMIT 1].Id;
            }

            for(B25__Reservation__c reservation : reservationList){
                reservation.B25__Status__c = statusid;
                reservation.Registered_Absent__c = action;
            }
            Database.update(reservationList);
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<B25__Reservation__c> getMyShiftsToday() {
        List<B25__Reservation__c> reservations = [
            SELECT Id , Duration_in_Hours__c
            FROM B25__Reservation__c 
            WHERE B25__Staff__r.B25__User__c = :Userinfo.getUserId()
            AND Shift_Published__c = true
            AND B25__Start_Date__c = :Date.today()
        ];
        return reservations;
    }

    @AuraEnabled
    public static List<B25__Reservation__c> createSickLeave(){
        try {
            List<B25__Reservation__c> reservations = Ctrl_reservations.getMyShiftsToday();

            Id statusId = [SELECT ID FROM B25__Reservation_Status__c WHERE name = 'Absence illness' LIMIT 1].Id;

            for(B25__Reservation__c reservation : reservations){
                reservation.B25__Status__c = statusId;
                reservation.Sick_Hours__c = reservation.Duration_in_Hours__c;
                reservation.Registered_Absent__c = 'Absent Sick';
            }
            Database.update(reservations);
            
            B25__Staff__c staff = [
                SELECT Id, Name, B25__User__r.ManagerId
                FROM B25__Staff__c
                WHERE B25__User__c = :UserInfo.getUserId()
                LIMIT 1
            ];

            if(staff.B25__User__r.ManagerId != null) {
                Set<String> managerIds = new Set<String>();
                managerIds.add(staff.B25__User__r.ManagerId);
                Util_Notifications.notifyUsersViaPush(managerIds, staff.Id, staff.Name + ' has reported in Sick today', 'Please contact the staff member');
            }

            return reservations;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void createSlices(String recordId, String slices){
        try {
            String soql = Ctrl_Reservations.getCreatableFieldsSOQL('B25__Reservation__c','id=\''+recordId+'\'');
            B25__Reservation__c reservation = (B25__Reservation__c)Database.query(soql);

            List<Object> m = (List<Object>)JSON.deserializeUntyped(slices);
            List<B25__Reservation__c> reservations = new List<B25__Reservation__c>();

            for(Object o : m){
                Map<String, Object> item = (Map<String, Object>)o;

                B25__Reservation__c newRes = reservation.clone(false, false, false, false);

                String startStr = (String)item.get('sliceStart');
                String endStr = (String)item.get('sliceEnd');

                newRes.B25__StartLocal__c = null;
                newRes.B25__EndLocal__c = null;
                newRes.Selected_Person_Groups__c = null;
                newRes.B25__Start__c = DateTime.valueOfGMT(startStr.substringBefore('.').replace('T', ' '));
                newRes.B25__End__c = DateTime.valueOfGMT(endStr.substringBefore('.').replace('T', ' '));
                newRes.Parent_Reservation__c = reservation.Id;
                reservations.add(newRes);
            }

            Database.insert(reservations);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    // Returns a dynamic SOQL statement for the whole object, includes only creatable fields since we will be inserting a cloned result of this query
    public static string getCreatableFieldsSOQL(String objectName, String whereClause){
         
        String selects = '';
         
        if (whereClause == null || whereClause == ''){ return null; }
         
        // Get a map of field name and field token
        Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();
        List<String> selectFields = new List<String>();
         
        if (fMap != null){
            for (Schema.SObjectField ft : fMap.values()){ // loop through all field tokens (ft)
                Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
                if (fd.isCreateable()){ // field is creatable
                    selectFields.add(fd.getName());
                }
            }
        }
         
        if (!selectFields.isEmpty()){
            selects = String.join(selectFields, ',');        
        }
         
        return 'SELECT ' + selects + ' FROM ' + objectName + ' WHERE ' + whereClause;
         
    }

}