public with sharing class Ctrl_PersonGroup {
    //Get more details when we receive just the id to show on screen.
    @AuraEnabled
    public static List<Id> getPerformers(String personGroupId){
        try {

            List<Person_Group_Performer__c> personGroupPerformers = [
                SELECT Id, Performer__c
                FROM Person_Group_Performer__c
                WHERE Person_Group__c = :personGroupId
            ];

            List<Id> personGroupPerformerIds = new List<Id>();
            for(Person_Group_Performer__c personGroupPerformer : personGroupPerformers){
                personGroupPerformerIds.add(personGroupPerformer.Performer__c);
            }

            return personGroupPerformerIds;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


}