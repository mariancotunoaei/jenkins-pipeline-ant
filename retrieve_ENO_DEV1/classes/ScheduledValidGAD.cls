/**
 * Created by amacari on 7/8/2021.
 */

global with sharing class ScheduledValidGAD implements Schedulable {

    global void execute(SchedulableContext SC) {

        List<Contact> contacts = [
                SELECT Id
                FROM Contact
        ];

        List<AggregateResult> GADsValidNow = [
                SELECT Count(Id) NoGADValid, gaid__Contact__c
                FROM gaid__Gift_Aid_Declaration__c
                WHERE gaid__Valid_Now__c = TRUE
                GROUP BY gaid__Contact__c
        ];

        Map<Id, Integer> myMap = new Map<Id, Integer>();
        for(AggregateResult gad : GADsValidNow){
            myMap.put((ID)gad.get('gaid__Contact__c'), (Integer)gad.get('NoGADValid'));
        }

        for(Contact contact : contacts){
            if(myMap.containsKey(contact.Id)){
                contact.gaid__Has_Valid_GAD_Now__c = TRUE;
            } else {
                contact.gaid__Has_Valid_GAD_Now__c = FALSE;
            }
        }

        update contacts;

    }

}