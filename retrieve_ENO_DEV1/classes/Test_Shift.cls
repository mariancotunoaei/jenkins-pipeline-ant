@IsTest
private class Test_Shift {
    
    @isTest private static void createWorkPeriod(){

        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@eno.org';
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User user1 = new User(
            Alias = 'standt', 
            Email='standarduser@eno.org.dummy',
            EmailEncodingKey='UTF-8', 
            LastName='Testing', 
            LanguageLocaleKey='en_GB',
            LocaleSidKey='en_GB', 
            ProfileId = p.Id,
            TimeZoneSidKey='Europe/London',
            UserName=uniqueUserName,
            Department__c = 'Costume'
        );

        

        System.runAs(user1) {
            B25__Staff__c staff = new B25__Staff__c();
            staff.Department__c = 'Costume';
            staff.B25__User__c = user1.Id;
            Database.insert(staff);
            
            Work_Period__c workPeriod = new Work_Period__c();
            workPeriod.Start_Date__c = Date.today();
            Database.insert(workPeriod);
        }

        System.assertEquals('Costume', [SELECT Department__c FROM Work_Period__c LIMIT 1].Department__c);
    }

    @isTest private static void getWorkPeriodDetails() {
        Work_Period__c workPeriod = new Work_Period__c();
        workPeriod.Start_Date__c = Date.today();
        workPeriod.Department__c = 'Costume';
        Database.insert(workPeriod);

        System.assertEquals('Costume', Ctrl_Shifts.getShiftDetails(workPeriod.Id).Department__c);
    } 
    
    @isTest private static void getStaffMembersFromShifts() {
        Work_Period__c workPeriod = new Work_Period__c();
        workPeriod.Start_Date__c = Date.today();
        workPeriod.Department__c = 'Costume';
        Database.insert(workPeriod);

        List<B25__Staff__c> staffMembers = new List<B25__Staff__c>();
        B25__Staff__c staff1 = new B25__Staff__c();
        staff1.Name = 'costume guy';
        staff1.Department__c = 'Costume';
        staff1.B25__Is_Active__c = true;
        staffMembers.add(staff1);
        
        B25__Staff__c staff2 = new B25__Staff__c();
        staff2.Name = 'costume guy2';
        staff2.Department__c = 'Costume';
        staff2.B25__Is_Active__c = true;
        staffMembers.add(staff2);

        B25__Staff__c staff3 = new B25__Staff__c();
        staff3.Name = 'costume guy3';
        staff3.Department__c = 'Flys';
        staff3.B25__Is_Active__c = true;
        staffMembers.add(staff3);
        
        Database.insert(staffMembers);

        System.assertEquals(2, Ctrl_Shifts.getStaffMembers(workPeriod.Id).size());
    }

    @isTest private static void getMyShiftDetails() {

        System.assertEquals(0, Ctrl_Shifts.getMyShiftDetails(null).size());

        Work_Period__c workPeriod = new Work_Period__c();
        workPeriod.Start_Date__c = Date.today();
        workPeriod.Department__c = 'Costume';
        Database.insert(workPeriod);

        System.assertEquals(0, Ctrl_Shifts.getMyShiftDetails(workPeriod.Id).size());

    } 

    @isTest private static void publishShift() {
        Work_Period__c workPeriod = new Work_Period__c();
        workPeriod.Start_Date__c = Date.today();
        workPeriod.Department__c = 'Costume';
        Database.insert(workPeriod);

        B25__Staff__c staff1 = new B25__Staff__c();
        staff1.Name = 'costume guy';
        staff1.Department__c = 'Costume';
        staff1.B25__Is_Active__c = true;
        staff1.B25__User__c = Userinfo.getUserId();
        Database.insert(staff1);

        B25__Reservation_Type__c type = new B25__Reservation_Type__c();
        type.Name = 'Shift';
        Database.insert(type);


        B25__Reservation__c reservation = new B25__Reservation__c();
        reservation.Work_Period__c = workPeriod.Id;
        reservation.B25__Staff__c = staff1.Id;
        reservation.B25__Start__c = DateTime.now();
        reservation.B25__End__c = DateTime.now().addHours(1);
        reservation.B25__Reservation_Type__c = type.Id;
        Database.insert(reservation);

        Ctrl_Shifts.publishReservations(workPeriod.Id);

    } 

    @isTest private static void acknowlegeShift() {

        System.assertEquals(0, Ctrl_Shifts.getMyShiftDetails(null).size());

        Work_Period__c workPeriod = new Work_Period__c();
        workPeriod.Start_Date__c = Date.today();
        workPeriod.Department__c = 'Costume';
        Database.insert(workPeriod);

        B25__Staff__c staff1 = new B25__Staff__c();
        staff1.Name = 'costume guy';
        staff1.Department__c = 'Costume';
        staff1.B25__Is_Active__c = true;
        staff1.B25__User__c = Userinfo.getUserId();
        Database.insert(staff1);

        B25__Reservation__c reservation = new B25__Reservation__c();
        reservation.Work_Period__c = workPeriod.Id;
        reservation.B25__Staff__c = staff1.Id;
        reservation.B25__Start__c = DateTime.now();
        reservation.B25__End__c = DateTime.now().addHours(1);
        Database.insert(reservation);

        Ctrl_Shifts.publishReservations(workPeriod.Id);
        Ctrl_Shifts.acknowlegeShift(workPeriod.Id);

        System.assertEquals(true, [SELECT Acknowledged_by_Staff_Member__c FROM B25__Reservation__c LIMIT 1].Acknowledged_by_Staff_Member__c);

    } 

    @IsTest private static void getAllStaffMembers() {
        Work_Period__c workPeriod = new Work_Period__c();
        workPeriod.Start_Date__c = Date.today();
        workPeriod.Department__c = 'Costume';
        Database.insert(workPeriod);

        B25__Staff__c staff1 = new B25__Staff__c();
        staff1.Name = 'costume guy';
        staff1.Department__c = 'Costume';
        staff1.B25__Is_Active__c = true;
        staff1.B25__User__c = Userinfo.getUserId();
        Database.insert(staff1);

        System.assertEquals(1, Ctrl_Shifts.getStaffMembers(workPeriod.Id).size());

    }
    
    @isTest private static void testOverTime() {
        Work_Period__c workPeriod = new Work_Period__c();
        workPeriod.Start_Date__c = Date.today();
        workPeriod.Department__c = 'Costume';
        Database.insert(workPeriod);

        B25__Staff__c staff1 = new B25__Staff__c();
        staff1.Name = 'costume guy';
        staff1.Department__c = 'Costume';
        staff1.B25__Is_Active__c = true;
        staff1.B25__User__c = Userinfo.getUserId();
        Database.insert(staff1);

        B25__Reservation__c reservation = new B25__Reservation__c();
        reservation.Work_Period__c = workPeriod.Id;
        reservation.B25__Staff__c = staff1.Id;
        reservation.B25__Start__c = DateTime.now();
        reservation.B25__End__c = DateTime.now().addHours(1);
        Database.insert(reservation);

        Shift_Staff__c resStaff = new Shift_Staff__c();
        resStaff.Reservation__c = reservation.Id;
        resStaff.Staff__c = staff1.Id;
        Database.insert(resStaff);

        List<Shift_Staff__c> resStaffs = new List<Shift_Staff__c>();
        resStaffs.add(resStaff);

        System.assertEquals(1, Ctrl_Shifts.getMyOverTimeShifts(workPeriod.Id).size());

        Ctrl_Shifts.changeOvertimeStatus(resStaffs, 'No Response');

        System.assertEquals('No Response', [SELECT Status__c FROM Shift_Staff__c LIMIT 1].Status__c);

    }

    @isTest private static void holidays() {

        B25__Staff__c staff1 = new B25__Staff__c();
        staff1.Name = 'costume guy';
        staff1.Department__c = 'Costume';
        staff1.B25__Is_Active__c = true;
        staff1.Holiday_Allowance_In_Days__c = 25; 
        staff1.Start_Date_of_Current_Contract__c = Date.today().addMonths(-1);
        staff1.Start_of_Holiday__c = '1 August';
        staff1.B25__User__c = Userinfo.getUserId();
        Database.insert(staff1);

        B25__Reservation_Type__c type = new B25__Reservation_Type__c();
        type.Name = 'Shift';
        Database.insert(type);

        B25__Reservation_Status__c status = new B25__Reservation_Status__c();
        status.Name = 'Absence holiday or approved leave';
        Database.insert(status);


        Ctrl_Shifts.createLeaveRequest(Date.today(), 'Absence', 'Full Day', '');
        
        Ctrl_Shifts.createLeaveRequest(Date.today().addDays(3), 'Absence', 'Half Day', 'AM');
        Ctrl_Shifts.createLeaveRequest(Date.today().addDays(1), 'Absence', 'Half Day', 'PM');
        Ctrl_Shifts.createLeaveRequest(Date.today().addDays(2), 'Absence', 'Half Day', 'Evening');

        Ctrl_Reservations.getLeaveRequests();
        System.assertEquals(4, [SELECT ID FROM B25__Reservation__c].size());

        System.assertEquals('0 out of 25', Ctrl_Shifts.getHolidayAllowance());

        staff1.Start_of_Holiday__c = '1 September';
        Database.update(staff1);
        System.assertEquals('0 out of 25', Ctrl_Shifts.getHolidayAllowance());

        staff1.Start_of_Holiday__c = 'Start of Contract';
        Database.update(staff1);
        System.assertEquals('0 out of 25', Ctrl_Shifts.getHolidayAllowance());
    }

    @isTest private static void allReservationsToday(){
        Work_Period__c workPeriod = new Work_Period__c();
        workPeriod.Start_Date__c = Date.today();
        workPeriod.Department__c = 'Costume';
        Database.insert(workPeriod);

        B25__Staff__c staff1 = new B25__Staff__c();
        staff1.Name = 'costume guy';
        staff1.Department__c = 'Costume';
        staff1.B25__Is_Active__c = true;
        staff1.B25__User__c = Userinfo.getUserId();
        Database.insert(staff1);

        B25__Reservation__c reservation = new B25__Reservation__c();
        reservation.Work_Period__c = workPeriod.Id;
        reservation.B25__Staff__c = staff1.Id;
        reservation.B25__Start__c = DateTime.now();
        reservation.B25__End__c = DateTime.now().addHours(1);
        Database.insert(reservation);

        Ctrl_Shifts.publishReservations(workPeriod.Id);

        System.assertEquals(1, Ctrl_Reservations.getAllReservationsToday().size());

       
    }

    @isTest private static void testGetReservations() {
        Work_Period__c workPeriod = new Work_Period__c();
        workPeriod.Start_Date__c = Date.today();
        workPeriod.Department__c = 'Costume';
        workPeriod.Published__c = true;
        Database.insert(workPeriod);

        B25__Staff__c staff1 = new B25__Staff__c();
        staff1.Name = 'costume guy';
        staff1.Department__c = 'Costume';
        staff1.B25__Is_Active__c = true;
        staff1.B25__User__c = Userinfo.getUserId();
        Database.insert(staff1);

        B25__Reservation__c reservation = new B25__Reservation__c();
        reservation.Work_Period__c = workPeriod.Id;
        reservation.B25__Staff__c = staff1.Id;
        reservation.B25__Start__c = DateTime.now();
        reservation.B25__End__c = DateTime.now().addHours(1);
        Database.insert(reservation);

        Date d = Date.today();
        List<B25__Reservation__c> reservations = new List<B25__Reservation__c>();
        
        reservations = Ctrl_Reservations.getReservations(d.year()+'-'+d.month()+'-'+d.day(), 'day', 'me');
        system.assertEquals(1, reservations.size());

        reservations = Ctrl_Reservations.getReservations(d.year()+'-'+d.month()+'-'+d.day(), 'week', 'department');
        system.assertEquals(1, reservations.size());

        reservations = Ctrl_Reservations.getReservations(d.year()+'-'+d.month()+'-'+d.day(), 'month', 'department');
        system.assertEquals(1, reservations.size());

        reservations = Ctrl_Reservations.getMyShiftsToday();
        system.assertEquals(1, reservations.size());

    }

    @isTest private static void testExtendShift() {

        List<B25__Reservation__c> reservations = new List<B25__Reservation__c>();

        DateTime d = DateTime.now();
        B25__Reservation__c reservation = new B25__Reservation__c();
        reservation.B25__Start__c = d;
        reservation.B25__End__c = d.addHours(1);
        Database.insert(reservation);

        reservations.add(reservation);

        Ctrl_Reservations.extendShift(reservations, 60);

        System.AssertEquals(d, reservation.B25__End__c.addHours(-2));

        Ctrl_Reservations.completeShifts(reservations);
        system.assertEquals(reservation.Shift_Completed__c, true);
    }

    @isTest private static void testChangeReservationStatus() {
        List<B25__Reservation__c> reservations = new List<B25__Reservation__c>();

        DateTime d = DateTime.now();
        B25__Reservation__c reservation = new B25__Reservation__c();
        reservation.B25__Start__c = d;
        reservation.B25__End__c = d.addHours(1);
        Database.insert(reservation);

        reservations.add(reservation);

        List<B25__Reservation_Status__c> statuses = new List<B25__Reservation_Status__c>();
        statuses.add(new B25__Reservation_Status__c(Name = 'Absence unexplained'));
        statuses.add(new B25__Reservation_Status__c(Name = 'Absence illness'));
        statuses.add(new B25__Reservation_Status__c(Name = 'Shift'));
        Database.insert(statuses);

        Ctrl_Reservations.changeReservationStatus(reservations, 'Absent');
        System.assertEquals(reservation.Registered_Absent__c, 'Absent');

        Ctrl_Reservations.changeReservationStatus(reservations, 'Absent Sick');
        System.assertEquals(reservation.Registered_Absent__c, 'Absent Sick');

        Ctrl_Reservations.changeReservationStatus(reservations, 'Shift');
        System.assertEquals(reservation.Registered_Absent__c, 'Shift');

    }

    @isTest private static void testCreateSickLeave() {
        Work_Period__c workPeriod = new Work_Period__c();
        workPeriod.Start_Date__c = Date.today();
        workPeriod.Department__c = 'Costume';
        workPeriod.Published__c = true;
        Database.insert(workPeriod);

        B25__Staff__c staff1 = new B25__Staff__c();
        staff1.Name = 'costume guy';
        staff1.Department__c = 'Costume';
        staff1.B25__Is_Active__c = true;
        staff1.B25__User__c = Userinfo.getUserId();
        Database.insert(staff1);

        B25__Reservation__c reservation = new B25__Reservation__c();
        reservation.Work_Period__c = workPeriod.Id;
        reservation.B25__Staff__c = staff1.Id;
        reservation.B25__Start__c = DateTime.now();
        reservation.B25__End__c = DateTime.now().addHours(1);
        Database.insert(reservation);

        List<B25__Reservation_Status__c> statuses = new List<B25__Reservation_Status__c>();
        statuses.add(new B25__Reservation_Status__c(Name = 'Absence unexplained'));
        statuses.add(new B25__Reservation_Status__c(Name = 'Absence illness'));
        statuses.add(new B25__Reservation_Status__c(Name = 'Shift'));
        Database.insert(statuses);

        List<B25__Reservation__c> reservations = Ctrl_Reservations.createSickLeave();
        System.assertEquals([SELECt Registered_Absent__c FROM B25__Reservation__c WHERE id = :reservation.Id].Registered_Absent__c, 'Absent Sick');

    }

    @IsTest private static void testCreateSlices(){
        DateTime d = DateTime.now();
        B25__Reservation__c reservation = new B25__Reservation__c();
        reservation.B25__Start__c = d;
        reservation.B25__End__c = d.addHours(1);
        Database.insert(reservation);

        Ctrl_Reservations.createSlices(reservation.Id, '[{"sliceStart":"2021-03-25T08:00:00.000Z","sliceEnd":"2021-03-25T08:30:00.000Z"},{"sliceStart":"2021-03-25T08:30:00.000Z","sliceEnd":"2021-03-25T09:00:00.000Z"},{"sliceStart":"2021-03-25T09:00:00.000Z","sliceEnd":"2021-03-25T09:30:00.000Z"},{"sliceStart":"2021-03-25T09:30:00.000Z","sliceEnd":"2021-03-25T10:00:00.000Z"},{"sliceStart":"2021-03-25T10:00:00.000Z","sliceEnd":"2021-03-25T10:30:00.000Z"},{"sliceStart":"2021-03-25T10:30:00.000Z","sliceEnd":"2021-03-25T11:00:00.000Z"},{"sliceStart":"2021-03-25T11:00:00.000Z","sliceEnd":"2021-03-25T11:30:00.000Z"},{"sliceStart":"2021-03-25T11:30:00.000Z","sliceEnd":"2021-03-25T12:00:00.000Z"},{"sliceStart":"2021-03-25T12:00:00.000Z","sliceEnd":"2021-03-25T12:30:00.000Z"},{"sliceStart":"2021-03-25T12:30:00.000Z","sliceEnd":"2021-03-25T13:00:00.000Z"},{"sliceStart":"2021-03-25T13:00:00.000Z","sliceEnd":"2021-03-25T13:30:00.000Z"},{"sliceStart":"2021-03-25T13:30:00.000Z","sliceEnd":"2021-03-25T14:00:00.000Z"},{"sliceStart":"2021-03-25T14:00:00.000Z","sliceEnd":"2021-03-25T14:30:00.000Z"},{"sliceStart":"2021-03-25T14:30:00.000Z","sliceEnd":"2021-03-25T15:00:00.000Z"},{"sliceStart":"2021-03-25T15:00:00.000Z","sliceEnd":"2021-03-25T15:30:00.000Z"},{"sliceStart":"2021-03-25T15:30:00.000Z","sliceEnd":"2021-03-25T16:00:00.000Z"},{"sliceStart":"2021-03-25T16:00:00.000Z","sliceEnd":"2021-03-25T16:30:00.000Z"},{"sliceStart":"2021-03-25T16:30:00.000Z","sliceEnd":"2021-03-25T17:00:00.000Z"},{"sliceStart":"2021-03-25T17:00:00.000Z","sliceEnd":"2021-03-25T17:30:00.000Z"},{"sliceStart":"2021-03-25T17:30:00.000Z","sliceEnd":"2021-03-25T18:00:00.000Z"}]');
        System.AssertEquals(21, [SELECT ID FROM B25__Reservation__c].size());
    }

    @isTest private static void convertReservations() {
        Work_Period__c workPeriod = new Work_Period__c();
        workPeriod.Start_Date__c = Date.today();
        workPeriod.Department__c = 'Costume';
        Database.insert(workPeriod);

        B25__Staff__c staff1 = new B25__Staff__c();
        staff1.Name = 'costume guy';
        staff1.Department__c = 'Costume';
        staff1.B25__Is_Active__c = true;
        staff1.B25__User__c = Userinfo.getUserId();
        Database.insert(staff1);

        B25__Staff__c staff2 = new B25__Staff__c();
        staff2.Name = 'costume virtual';
        staff2.Department__c = 'Costume';
        staff2.B25__Is_Active__c = true;
        staff2.Virtual__c = true;
        Database.insert(staff2);

        B25__Reservation_Type__c type = new B25__Reservation_Type__c();
        type.Name = 'Shift';
        Database.insert(type);

        B25__Reservation_Status__c status = new B25__Reservation_Status__c();
        status.Name = 'Shift';
        Database.insert(status);

        B25__Reservation_Status__c status2 = new B25__Reservation_Status__c();
        status2.Name = 'Overtime';
        Database.insert(status2);

        Ctrl_Shifts.convertReservations(workPeriod.Id);
        System.assertEquals(0, [SELECT ID FROM B25__Reservation__c].size());

        B25__Reservation__c reservation = new B25__Reservation__c();
        reservation.B25__Start__c = DateTime.now();
        reservation.B25__End__c = DateTime.now().addHours(1);
        reservation.B25__Reservation_Type__c = type.Id;
        reservation.Required_Number_of_Employees__c = 2;
        reservation.Work_Period__c = workPeriod.Id;
        Database.insert(reservation);

        Shift_Staff__c resStaff = new Shift_Staff__c();
        resStaff.Reservation__c = reservation.Id;
        resStaff.Staff__c = staff1.Id;
        Database.insert(resStaff);
        resStaff.Status__c = 'Assigned';
        Database.update(resStaff);

        Ctrl_Shifts.convertReservations(workPeriod.Id);

        System.assertEquals(1, [SELECT ID FROM B25__Reservation__c].size());

    } 


}