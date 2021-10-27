public with sharing class Ctrl_Shifts {

    //Used by staffCalendar to filter the staff members on department
    @AuraEnabled
    public static List<Id> getStaffMembers(String workPeriodRecordId) {
        try {
            List<Id> ids = new List<Id>();

            Work_Period__c workPeriod = [
                SELECT ID, Department__c 
                FROM Work_Period__c 
                WHERE Id = :workPeriodRecordId 
            ];

            List<B25__Staff__c> staffMembers = [
                SELECT Id 
                FROM B25__Staff__c 
                WHERE Department__c = :workPeriod.Department__c 
                AND B25__Is_Active__c = true
            ];
            for(B25__Staff__c staff : staffMembers){
                ids.add(staff.Id);
            }
            return ids;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    //Used in workPeriod planning to make sure that porposal shifts are converted into actual shifts
    @AuraEnabled(cacheable=false)
    public static List<B25__Reservation__c> convertReservations(Id workPeriodId){
        try {
            system.debug(workPeriodId);
            List<B25__Reservation__c> proposalReservations = Ctrl_Shifts.getProposalReservations(workPeriodId);
            if(proposalReservations.size() == 0){
                return new List<B25__Reservation__c>();
            }
            
            Id virtualsStaffId = [
                SELECT Id 
                FROM B25__Staff__c
                WHERE Virtual__c = true
                AND Department__c = :proposalReservations[0].Work_Period__r.Department__c
                LIMIT 1
            ].Id;

            Id shiftReservationTypeId = [
                SELECT Id 
                FROM B25__Reservation_Type__c
                WHERE Name = 'Shift'
                LIMIT 1
            ].Id;
            
            Id shiftStatusId = [
                SELECT Id 
                FROM B25__Reservation_Status__c
                WHERE Name = 'Shift'
                LIMIT 1
            ].Id;

            Id overtimeStatusId = [
                SELECT Id 
                FROM B25__Reservation_Status__c
                WHERE Name = 'Overtime'
                LIMIT 1
            ].Id;

            List<B25__Reservation__c> reservations = new List<B25__Reservation__c>();
            Map<Id, List<B25__Reservation__c>> overtimeReservations = new Map<Id, List<B25__Reservation__c>>();
            for(B25__Reservation__c reservation : proposalReservations){

                Integer reqNrEmployees = reservation.Required_Number_of_Employees__c != null ? Integer.valueOf(reservation.Required_Number_of_Employees__c) : 0;
                String department = reservation.Work_Period__r.Department__c;

                // Overtime shifts need to be "offered" to users. We create reservations and keep the relation 
                // to multiple staff members
                if(reservation.Overtime__c){
                    overtimeReservations.put(reservation.Id, new List<B25__Reservation__c>());

                    B25__Reservation__c newRes = new B25__Reservation__c();
                    newRes.B25__Staff__c = virtualsStaffId;
                    newRes.B25__Reservation_Type__c = shiftReservationTypeId;
                    newRes.B25__Status__c = overtimeStatusId;
                    newRes.Run__c = reservation.Run__c;
                    newRes.Umbrella_Arrangement__c = reservation.Umbrella_Arrangement__c;
                    newRes.B25__Account__c = reservation.B25__Account__c;
                    newRes.Work_Period__c = workPeriodId;
                    newRes.B25__Start__c = reservation.B25__Start__c;
                    newRes.B25__End__c = reservation.B25__End__c;
                    newRes.B25__Notes__c = reservation.B25__Notes__c;
                    newRes.B25__Resource__c = reservation.B25__Resource__c;
                    newRes.NCO__c = reservation.NCO__c;
                    newRes.Overtime__c = reservation.Overtime__c;
                    overtimeReservations.get(reservation.Id).add(newRes);
                }

                // For normal shifts, when there is a staff member assigned to the shift we will
                // convert it to a shift with a staff member assigned (e.g. create single reservations from
                // the dimension junction).
                if(!reservation.Overtime__c){
                    for(Shift_Staff__c reservationStaff : reservation.Shift_Staffs__r){
                        B25__Reservation__c newRes = new B25__Reservation__c();
                        newRes.B25__Staff__c = reservationStaff.Staff__c;
                        newRes.B25__Reservation_Type__c = shiftReservationTypeId;
                        newRes.B25__Status__c = shiftStatusId;
                        newRes.Run__c = reservation.Run__c;
                        newRes.Umbrella_Arrangement__c = reservation.Umbrella_Arrangement__c;
                        newRes.B25__Account__c = reservation.B25__Account__c;
                        newRes.B25__Start__c = reservation.B25__Start__c;
                        newRes.B25__End__c = reservation.B25__End__c;
                        newRes.B25__Notes__c = reservation.B25__Notes__c;
                        newRes.B25__Resource__c = reservation.B25__Resource__c;
                        newRes.NCO__c = reservation.NCO__c;
                        newRes.Work_Period__c = workPeriodId;
                        reservations.add(newRes);
                        reqNrEmployees--;
                    }

                    // If there is no staff member assigned, we need to create shifts in the virtual staff record
                    for(Integer i=0;i<reqNrEmployees;i++){
                        B25__Reservation__c newRes = new B25__Reservation__c();
                        newRes.B25__Staff__c = virtualsStaffId;
                        newRes.B25__Reservation_Type__c = shiftReservationTypeId;
                        newRes.B25__Status__c = shiftStatusId;
                        newRes.Run__c = reservation.Run__c;
                        newRes.Umbrella_Arrangement__c = reservation.Umbrella_Arrangement__c;
                        newRes.B25__Account__c = reservation.B25__Account__c;
                        newRes.Work_Period__c = workPeriodId;
                        newRes.B25__Start__c = reservation.B25__Start__c;
                        newRes.B25__End__c = reservation.B25__End__c;
                        newRes.B25__Notes__c = reservation.B25__Notes__c;
                        newRes.B25__Resource__c = reservation.B25__Resource__c;
                        newRes.NCO__c = reservation.NCO__c;
                        reservations.add(newRes);
                    }
                }
            }

            List<B25__Reservation__c> flattenReservations = new List<B25__Reservation__c>();
            for(List<B25__Reservation__c> reservationList : overtimeReservations.values()){
                for(B25__Reservation__c resItem : reservationList){
                    flattenReservations.add(resItem);
                }
            }
            Database.insert(flattenReservations);          

            //Relate the staff members to overtime when needed.
            List<Shift_Staff__c> staffToInsert = new List<Shift_Staff__c>();
            for(B25__Reservation__c reservation : proposalReservations){
                if(overtimeReservations.containsKey(reservation.Id)){
                    for(Shift_Staff__c reservationStaff : reservation.Shift_Staffs__r){
                        Shift_Staff__c newResStaff = new Shift_Staff__c();
                        newResStaff.Reservation__c = overtimeReservations.get(reservation.Id)[0].Id;
                        newResStaff.Staff__c = reservationStaff.Staff__c;
                        newResStaff.Status__c = 'No Response';
                        staffToInsert.add(newResStaff);                   
                    }
                }
            }
           

            //Delete all proposal shiftIds that are no longer needed
            Database.delete(proposalReservations);
            //Insert all the new shifts
            Database.insert(reservations);
            Database.insert(staffToInsert);
            
            Ctrl_Shifts.updateScheduleCompleteForWorkPeriod(workPeriodId);  

            return reservations;
        } catch (Exception e) {
           throw new AuraHandledException(e.getMessage());
        }
    }

    private static List<B25__Reservation__c> getProposalReservations(Id workPeriodId){
        return [
            SELECT Id, Required_Number_of_Employees__c, Overtime__c,
            Run__c, B25__Account__c, B25__Start__c, B25__End__c,
            NCO__c, B25__Resource__c, B25__Notes__c,
            Umbrella_Arrangement__c,
            Work_Period__r.Department__c, 
            (
                SELECT Id, Staff__c
                FROM Shift_Staffs__r
            )
            FROM B25__Reservation__c 
            WHERE Work_Period__c = :workPeriodId
        ];
    }

    private static Work_Period__c updateScheduleCompleteForWorkPeriod(Id workPeriodId){
        Work_Period__c workPeriod = new Work_Period__c();
        workPeriod.Id = workPeriodId;
        workPeriod.Schedule_Complete__c = true;
        Database.update(workPeriod);

        return workPeriod;
    }

    //Publish all shifts
    @AuraEnabled(cacheable=false)
    public static void publishReservations(String workPeriodId){
        try {
            Work_Period__c workPeriod = new Work_Period__c();
            workPeriod.Id = workPeriodId;
            workPeriod.Published__c = true;
            Database.update(workPeriod);

            Set<String> recipientsIds = new Set<String>();

            List<B25__Reservation__c> reservations = [
                SELECT Id, B25__Staff__r.B25__User__c, B25__End__c,
                (SELECT Id, Staff__r.B25__User__c FROM Shift_Staffs__r)
                FROM B25__Reservation__c
                WHERE Work_Period__c = :workPeriodId
                AND B25__Reservation_Type__r.Name = 'Shift'
            ];
            
            for(B25__Reservation__c res : reservations) {
                res.Original_End_Local_DateTime__c = res.B25__End__c;
                for(Shift_Staff__c staffMember : res.Shift_Staffs__r) {
                    recipientsIds.add(staffMember.Staff__r.B25__User__c);    
                }
                recipientsIds.add(res.B25__Staff__r.B25__User__c);
            }
            Database.update(reservations);

            recipientsIds.remove(null);

            Util_Notifications.notifyUsersViaPush(recipientsIds, workPeriodId, 'New Shifts have been published!', 'New shifts have been published. Make sure you acknowledge the shifts.');

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    //Get shift details of the current user so they can acknowledge the shift
    @AuraEnabled(cacheable=true)
    public static List<B25__Reservation__c> getMyShiftDetails(String workPeriodId){
        try {
            if(workPeriodId == null){
                return new List<B25__Reservation__c>();
            }
            return [
                SELECT Id, B25__Start__c, B25__End__c, Acknowledged_by_Staff_Member__c
                FROM B25__Reservation__c 
                WHERE Work_Period__c = :workPeriodId
                AND Shift_Published__c = true
                AND B25__Staff__r.B25__User__c = :userInfo.getUserId()
                ORDER BY B25__Start__c, B25__End__c
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    //Get overtime details of the current user so they can acknowledge the shift
    @AuraEnabled(cacheable=true)
    public static List<Shift_Staff__c> getMyOverTimeShifts(String workPeriodId){
        try {
            if(workPeriodId == null){
                return new List<Shift_Staff__c>();
            }
            return [
                SELECT Id, Start__c, End__c, Status__c
                FROM Shift_Staff__c 
                WHERE Reservation__r.Work_Period__c = :workPeriodId
                AND Staff__r.B25__User__c = :UserInfo.getUserId()
                ORDER BY Start__c, End__c
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    //let a user acknowledge the shift
    @AuraEnabled(cacheable=false)
    public static void acknowlegeShift(String workPeriodId){
        try {

            List<B25__Reservation__c> reservations = Ctrl_Shifts.getMyShiftDetails(workPeriodId);
            system.debug(reservations);
            for(B25__Reservation__c reservation : reservations){
                reservation.Acknowledged_by_Staff_Member__c = true;
                reservation.Acknowledged_by_Staff_Member_On_Date__c = DateTime.now();
            }
            Database.update(reservations);

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static void changeOvertimeStatus(List<Shift_Staff__c> reservationStaff, String action){
        try {

            for(Shift_Staff__c resStaff : reservationStaff){
                resStaff.Status__c = action;
            }
            Database.update(reservationStaff);

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    //Get more details when we receive just the id to show on screen.
    @AuraEnabled
    public static Work_Period__c getShiftDetails(String workPeriodRecordId){
        try {
            return [
                SELECT ID, Department__c, Start_Date__c, End_Date__c,Published__c, Schedule_Complete__c
                FROM Work_Period__c 
                WHERE Id = :workPeriodRecordId
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getHolidayAllowance(){
        try {
            
            B25__Staff__c staff = [
                SELECT Id, Holiday_Allowance_In_Days__c, Start_Date_of_Current_Contract__c, Start_of_Holiday__c 
                FROM B25__Staff__c 
                WHERE B25__User__c = :Userinfo.getUserId()
                LIMIT 1
            ];

            //Find out the range in which we have to get the date
            Date now = Date.today();
            Date betweenStart = Date.today();
            Date betweenEnd = Date.today();
            Integer year = now.year()-1;

            if(staff.Start_of_Holiday__c == '1 August'){
                
                if(now.month() >= 8){
                    year = now.year();
                }
                betweenStart = Date.newInstance(year, 8, 1);
                betweenEnd = betweenStart.addYears(1);
            }

            if(staff.Start_of_Holiday__c == '1 September'){
                if(now.month() >= 9){
                    year = now.year();
                }
                betweenStart = Date.newInstance(year, 9, 1);
                betweenEnd = betweenStart.addYears(1);
            }

            if(staff.Start_of_Holiday__c == 'Start of Contract'){
                if(now.month() >= staff.Start_Date_of_Current_Contract__c.month()){
                    year = now.year();
                }
                betweenStart = Date.newInstance(year, staff.Start_Date_of_Current_Contract__c.month(), staff.Start_Date_of_Current_Contract__c.day());
                betweenEnd = betweenStart.addYears(1);
            }

            List<B25__Reservation__c> reservations = [
                SELECT Leave_Request_Days__c
                FROM B25__Reservation__c
                WHERE B25__Staff__c = :staff.Id
                AND Leave_Request_Status__c = 'Approved'
                AND B25__Start_Date__c >= :betweenStart
                AND B25__Start_Date__c < :betweenEnd
            ];

            Decimal usedHours = 0;
            for(B25__Reservation__c reservation : reservations){
                usedHours += reservation.Leave_Request_Days__c;
            }
            
            return String.valueOf(usedHours) + ' out of ' + staff.Holiday_allowance_In_Days__c;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static B25__Reservation__c createLeaveRequest(Date dateValue, String typeValue, String lengthValue, String whenValue){
        try {  
            Decimal leaveDays = 0.5;
            Integer startHr = 8;
            Integer endHr = 13;
            if(lengthValue == 'Full Day'){
                endHr = 23;
                leaveDays = 1;
            }

            if(lengthValue == 'Half Day' && whenValue == 'PM'){
                startHr = 13;
                endHr = 18;
            }

            if(lengthValue == 'Half Day' && whenValue == 'Evening'){
                startHr = 18;
                endHr = 23;
            }

            Time startTime = Time.newInstance(startHr,00,00,0);
            DateTime startDateTime = DateTime.newInstance(dateValue, startTime);
            Time endTime = Time.newInstance(endHr,00,00,0);
            DateTime endDateTime = DateTime.newInstance(dateValue, endTime);

            B25__Staff__c staff = [
                SELECT Id, Name, B25__User__r.ManagerId
                FROM B25__Staff__c
                WHERE B25__User__c = :UserInfo.getUserId()
                LIMIT 1
            ];

            Id statusId = [
                SELECT ID 
                FROM B25__Reservation_Status__c 
                WHERE name = 'Absence holiday or approved leave'
            ].Id;

            Id shiftReservationTypeId = [
                SELECT Id 
                FROM B25__Reservation_Type__c
                WHERE Name = 'Shift'
                LIMIT 1
            ].Id;

            B25__Reservation__c reservation = new B25__Reservation__c();
            reservation.B25__Staff__c = staff.Id;
            reservation.B25__User__c = UserInfo.getUserId();
            reservation.B25__Start__c = startDateTime;
            reservation.B25__End__c = endDateTime;
            reservation.B25__Status__c = statusId;
            reservation.B25__Notes__c = typeValue;
            reservation.Staff_Manager__c = staff.B25__User__r.ManagerId;
            reservation.Leave_Request_Status__c = 'Requested';
            reservation.B25__Reservation_Type__c = shiftReservationTypeId;
            reservation.Leave_Request_Days__c = leaveDays;
            Database.insert(reservation);   
            
            if(staff.B25__User__r.ManagerId != null) {
                Set<String> managerIds = new Set<String>();
                managerIds.add(staff.B25__User__r.ManagerId);
                Util_Notifications.notifyUsersViaPush(managerIds, reservation.Id, staff.Name + ' has requested time off on ' + String.valueOf(dateValue), 'Please make sure you approve or reject the request');
            }

            return reservation;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}