@isTest
private class Test_Ctrl_CardReport {
    @isTest 
    private static void testCardReport() {
        PageReference pageRef = Page.cardReport;
        Test.setCurrentPage(pageRef);
        
        B25__Reservation__c rsv = Test_DataHelper.createBooker();

        Ctrl_CardReport controller = new Ctrl_CardReport();
        System.assertEquals(Date.today(), controller.tableRows[0].rowDate);
    }

    @isTest 
    private static void testSearchGhostPlanning() {
        Ghost_Planning__c ghostPlanning = new Ghost_Planning__c();
        Database.insert(ghostPlanning);
        
        Ghost_Planning_Version__c ghostPlanningVersion = new Ghost_Planning_Version__c();
        ghostPlanningVersion.Name = 'name';
        ghostPlanningVersion.Ghost_planning__c = ghostPlanning.Id;
        Database.insert(ghostPlanningVersion);

        System.assertEquals(1, Ctrl_CardReport.searchGhostPlanningVersion('name', null).size());
    }
}