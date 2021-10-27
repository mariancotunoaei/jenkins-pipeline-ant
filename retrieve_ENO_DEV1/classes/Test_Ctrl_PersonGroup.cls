@isTest
private class Test_Ctrl_PersonGroup {
    
    @isTest 
    private static void testPerformGroup() {
        Person_Group__c personGroup = new Person_Group__c();
        personGroup.Name = 'a';
        Database.insert(personGroup);

        Performer__c performer = new Performer__c();
        performer.Name = 'a';
        Database.insert(performer);

        Person_Group_Performer__c personGroupPerformer = new Person_Group_Performer__c();
        personGroupPerformer.Performer__c = performer.Id;
        personGroupPerformer.Person_Group__c = personGroup.Id;
        Database.insert(personGroupPerformer);

        System.assertEquals(1, Ctrl_PersonGroup.getPerformers(personGroup.Id).size());

    }
}