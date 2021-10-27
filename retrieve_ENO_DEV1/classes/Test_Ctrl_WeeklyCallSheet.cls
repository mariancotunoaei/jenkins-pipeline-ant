@isTest
private class Test_Ctrl_WeeklyCallSheet {
    @isTest 
    private static void testWeeklyCallSheetWithoutReservation() {
        Date today = Date.today();

        Ctrl_WeeklyCallSheet.getWeeklyCallSheetData(today);
    }

    @isTest 
    private static void testWeeklyCallSheetWithReservation() {
        Date today = Date.today();

        Production__c prod = new Production__c();
        Database.insert(prod);

        Run__c run = new Run__c();
        run.Production__c = prod.Id;
        Database.insert(run);

        B25__Reservation__c rsv = Test_DataHelper.createBooker();
        rsv.Run__c = run.Id;
        Database.update(rsv);

        List<B25__Reservation_type__c> types = new List<B25__Reservation_type__c>();
        B25__Reservation_type__c type = new B25__Reservation_type__c();
        type.Name = 'Chorus - Production';
        types.add(type);

        B25__Reservation_type__c type2 = new B25__Reservation_type__c();
        type2.Name = 'Orchestral';
        types.add(type2);

        B25__Reservation_type__c type3 = new B25__Reservation_type__c();
        type3.Name = 'Performance (Evening)';
        types.add(type3);

        B25__Reservation_type__c type4 = new B25__Reservation_type__c();
        type4.Name = 'Fitting';
        types.add(type4);

        Database.insert(types);
        
        List<B25__Reservation__c> rsvList = new List<B25__Reservation__c>();
        B25__Reservation__c rsv3 = rsv.clone(false, false, false, false);
        rsv3.Id = null;
        rsv3.B25__Reservation_Type__c = type.Id;
        rsvList.add(rsv3);

        B25__Reservation__c rsv4 = rsv.clone(false, false, false, false);
        rsv4.Id = null;
        rsv4.B25__Reservation_Type__c = type2.Id;
        rsvList.add(rsv4);

        B25__Reservation__c rsv5 = rsv.clone(false, false, false, false);
        rsv5.Id = null;
        rsv5.B25__Reservation_Type__c = type3.Id;
        rsvList.add(rsv5);

        B25__Reservation__c rsv6 = rsv.clone(false, false, false, false);
        rsv6.Id = null;
        rsv6.B25__Reservation_Type__c = type4.Id;
        rsvList.add(rsv6);

        Database.insert(rsvList);

        B25__Staff__c staff = new B25__Staff__c();
        Database.insert(staff);

        Reservation_Staff__c resStaff = new Reservation_Staff__c();
        resStaff.Reservation__c = rsv.Id;
        resStaff.Staff__c = staff.Id;
        Database.insert(resStaff);

        B25__Reservation__c rsv2 = new B25__Reservation__c();
		rsv2.B25__Start__c = Datetime.now();
		rsv2.B25__End__c = Datetime.now().addHours(1);
		rsv2.B25__Calculation_Method__c = B25.Util_Enums.PriceCalculation.PER_TIME_UNIT.name();
		rsv2.Cost_Centre_Code__c ='a';
		rsv2.Purchase_Order_Number__c = 'a';
        rsv2.Parent_Reservation__c = rsv.Id;
		Database.insert(rsv2);

        Reservation_Staff__c resStaff2 = new Reservation_Staff__c();
        resStaff2.Reservation__c = rsv2.Id;
        resStaff2.Staff__c = staff.Id;
        Database.insert(resStaff2);

        List<Ctrl_WeeklyCallSheet.CallSheet> callsheets = Ctrl_WeeklyCallSheet.getWeeklyCallSheetData(today);
        System.assertEquals(1, callsheets.size());


    }
}