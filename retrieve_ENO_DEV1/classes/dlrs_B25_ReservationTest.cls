@IsTest
private class dlrs_B25_ReservationTest {
    @IsTest
    private static void testTrigger(){
        // Force the dlrs_B25_ReservationTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new B25__Reservation__c(B25__Start__c = DateTime.now(), B25__End__c = DateTime.now().addHours(1)));
    }
}