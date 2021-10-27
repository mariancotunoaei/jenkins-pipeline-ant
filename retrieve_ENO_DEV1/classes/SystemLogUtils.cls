/**
 * Created by sgrigorescu on 5/11/2021.
 */

global with sharing class SystemLogUtils {

    /**
     * method that inserts System_Log__c object based on parameters
     *
     * @param recordId the id of the record on which the event occurred
     * @param source the method in which the event occurred
     * @param level type of the event
     * @param notification short event description (e.g. exception message)
     * @param details event details (e.g. stack trace)
     * @param category the context where the error occurred
     */
    public static void createSystemLog(String recordId, String source, String level, String notification, String details, String category) {
        System_Log__c log = new System_Log__c(
                RecordId__c = recordId,
                Source__c = source,
                Level__c = level,
                Notification__c = notification,
                Details__c = details,
                System_Modstamp__c = System.now(),
                Category__c = category
        );
        insert log;
    }
}