@isTest
private class Test_Ctrl_CateringInvoice {
    @isTest 
    private static void testCateringInvoice() {
		PageReference pageRef = Page.cateringInvoice;
        Test.setCurrentPage(pageRef);
        

        B25__Reservation__c rsv = Test_DataHelper.createBooker();
        // Add parameters to page URL
        ApexPages.currentPage().getParameters().put('ids', rsv.Id);
        
        // Instantiate a new controller with all parameters in the page
        Ctrl_CateringInvoice controller = new Ctrl_CateringInvoice();
        System.assertEquals(1, controller.reservations.size());

        ApexPages.currentPage().getParameters().put('id', rsv.Id);
        
        // Instantiate a new controller with all parameters in the page
        Ctrl_CateringInvoice controller2 = new Ctrl_CateringInvoice();
        System.assertEquals(1, controller2.reservations.size());
    }

    @isTest 
    private static void testCatering() {
        B25__Reservation__c rsv = Test_DataHelper.createBooker();
        // Add parameters to page URL

        List<B25__Service_Reservation__c> services = Ctrl_Catering.getServices(rsv.Id, false);
        System.assertEquals(1, services.size());

        Ctrl_Catering.changeServiceReservationStatus(services, 'Ordered');

        System.assertEquals('Ordered', services[0].Status__c);
    }
    
    @isTest 
    private static void testCateringCancelled() {
        B25__Reservation__c rsv = Test_DataHelper.createBooker();
        // Add parameters to page URL

        List<B25__Service_Reservation__c> services = Ctrl_Catering.getServices(rsv.Id, false);
        System.assertEquals(1, services.size());

        Ctrl_Catering.changeServiceReservationStatus(services, 'Cancelled');
        List<B25__Service_Reservation__c> services2 = Ctrl_Catering.getServices(rsv.Id, true);

        System.assertEquals(1, services2.size());
    }

    @isTest 
    private static void testCateringList() {
        B25__Reservation__c rsv = Test_DataHelper.createBooker();
        // Add parameters to page URL

        Ctrl_Catering catering = new Ctrl_Catering();
        catering.reservationId = rsv.Id;
        catering.serviceType = 'st1';
        List<B25__Service_Reservation__c> services = catering.getServicesList();
        System.assertEquals(1, services.size());
    }

    @isTest private static void updateServiceRes() {
        B25__Reservation__c rsv = Test_DataHelper.createBooker();

        List<B25__Service_Reservation__c> services = [SELECT ID FROM B25__Service_Reservation__c WHERE B25__Reservation__c = :rsv.Id];
        Ctrl_Catering.updateServiceReservations(services);
    }

    @isTest static void testDateTimeComponent(){        
        Ctrl_DateTimeComponent etdfc = new Ctrl_DateTimeComponent();
        String s4 = etdfc.getFormattedDatetime();
        etdfc.dt = Datetime.newInstance(2013, 09, 24, 2, 30, 0);
        String s5 = etdfc.getFormattedDatetime();
        etdfc.definedFormat = 'dd/MM/yyyy';
        String s6 = etdfc.getFormattedDatetime();

        System.assertEquals('24/09/2013', s6);
    }

    @isTest static void testCurrencyComponent(){        
        Ctrl_CurrencyComponent ccfc = new Ctrl_CurrencyComponent();
        ccfc.nr = 1.20;
        String s2 = ccfc.getFormattedString();
        System.assertEquals('1.20', s2);

        ccfc.nrString = '1.40';
        String s3 = ccfc.getFormattedString();
        System.assertEquals('1.40', s3);
    }
}