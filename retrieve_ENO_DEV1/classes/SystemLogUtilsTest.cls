/**
 * Created by sgrigorescu on 5/17/2021.
 */

@IsTest
public with sharing class SystemLogUtilsTest {
    @IsTest
    public static void createSystemLogTest() {
        Test.startTest();
        SystemLogUtils.createSystemLog(null, 'SystemLogUtilsTest.createSystemLogTest', 'ERROR', 'test', 'test details', 'APEX');
        System_Log__c systemLog = [SELECT RecordId__c FROM System_Log__c LIMIT 1];
        System.assertEquals(systemLog.RecordId__c, null, 'RecordId field has incorrect value');
        Test.stopTest();
    }
}