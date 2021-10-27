@IsTest
private class Test_B25_Reservation {
    @isTest private static void testOvertime() {
        B25__Reservation_Status__c status = new B25__Reservation_Status__c();
        status.Name = 'Overtime';
        Database.insert(status);

        B25__Reservation__c reservation = new B25__Reservation__c();
        reservation.Overtime__c = true;
        reservation.B25__Start__c = DateTime.now();
        reservation.B25__End__c = DateTime.now().addHours(1);
        Database.insert(reservation);

        System.assertEquals(status.Id, [SELECT B25__Status__c FROM B25__Reservation__c LIMIT 1].B25__Status__c);
    }

    @isTest private static void testDimensionJunctions() {
    
        B25__Reservation__c reservation = new B25__Reservation__c();
        reservation.B25__Start__c = DateTime.now();
        reservation.B25__End__c = DateTime.now().addHours(1);
        Database.insert(reservation);

        Card__c card = new Card__c();
        card.Name ='a';
        card.API_Name__c = 'a';
        Database.insert(card);

        Reservation_Card__c resCard = new Reservation_Card__c();
        resCard.Reservation__c = reservation.Id;
        resCard.Card__c = card.Id;
        Database.insert(resCard);

        Performer__c performer = new Performer__c();
        performer.Name ='a';
        Database.insert(performer);

        Reservation_Performer__c resPerformer = new Reservation_Performer__c();
        resPerformer.Reservation__c = reservation.Id;
        resPerformer.Performer__c = performer.Id;
        Database.insert(resPerformer);

        B25__Staff__c staff = new B25__Staff__c();
        staff.Name = 'a';
        Database.insert(staff);

        Reservation_Staff__c resStaff = new Reservation_Staff__c();
        resStaff.Reservation__c = reservation.Id;
        resStaff.Staff__c = staff.Id;
        Database.insert(resStaff);

        Shift_Staff__c shiftStaff = new Shift_Staff__c();
        shiftStaff.Reservation__c = reservation.Id;
        shiftStaff.Staff__c = staff.Id;
        Database.insert(shiftStaff);

        System.assertEquals(1, [SELECT Id FROM B25__Reservation__c].size());
    }

    @isTest private static void testCtrl_StaffResourceTitle() {
        // B25.Util_PluginManager.DynamicResourceTitleData a = (B25.Util_PluginManager.DynamicResourceTitleData)JSON.deserialize('{}', B25.Util_PluginManager.DynamicResourceTitleData.class);
        // Ctrl_StaffResourceTitle b = new Ctrl_StaffResourceTitle();
        // b.calculateResourceTitles(a);
    }
}