/**
 * Created by ibuzau on 5/11/2021.
 */

global class DeleteOlderJobs implements Schedulable {
    global void execute(SchedulableContext ctx) {
        Outbound_manager_settings__c days = [SELECT Lifetime_for_logged_data__c FROM Outbound_manager_settings__c];
        Date noDays= (System.today() -(Integer) days.Lifetime_for_logged_data__c);

        List<Outbound_Transfer__c> olderJobs = [
                select Id
                FROM Outbound_Transfer__c
                WHERE CreatedDate <= :noDays
                And (Failed_By_Business_Error__c = True OR Transfered__c = True)

        ]; 
        if (!olderJobs.isEmpty())
            delete olderJobs;
    }
}