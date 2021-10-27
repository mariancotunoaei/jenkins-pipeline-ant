/******************************************************************************************************
* @Name         	LeadTriggerHandlerTest 
* @Author       	Sorina Grigorescu
* @Date         	31/05/2021
* @Description 		Test class for LeadTriggerHandler
******************************************************************************************************/

/* MODIFICATION LOG
* Version         	Developer          		Date               		Description
*-----------------------------------------------------------------------------------------------------
* 1.0             	Sorina Grigorescu      	31/05/2021         		Initial Creation
* 2.0				Paraschiv Alexandru		15/07/2021				Test Method Update
******************************************************************************************************/

@IsTest
private class LeadTriggerHandlerTest {
    
    @isTest
    public static void insertNonExistingContact() {
        Test.startTest();
        
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        
        Lead lead = new Lead();
        lead.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Newsletter_Subscription').getRecordTypeId();
        lead.FirstName = 'Test';
        lead.LastName = 'Lead';
        lead.Email = 'testLead@test.com';
        lead.Company = 'Test Company';
        lead.Marketing_Newsletter_Sign_Up__c = true;
        lead.Form_Completion_Date__c = Datetime.now();
        lead.Form_Name__c = 'Test Form';
        insert lead;
        
        Contact cont = [SELECT Id, FirstName, LastName, Email, Signup_MKT_Newsletter__c FROM Contact WHERE Email = 'testLead@test.com' LIMIT 1];
        System.assert(cont.FirstName == 'Test');
        System.assert(cont.LastName == 'Lead');
        
        Lead insertedLead = [SELECT Id, Status FROM Lead WHERE Id = :lead.Id LIMIT 1];
        System.assert(insertedLead.Status == convertStatus.MasterLabel);
        
        Test.stopTest();
    }
    
    @isTest
    public static void insertExistingContact() {
        Test.startTest();
        
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        
        Contact cont = new Contact();
        cont.FirstName = 'Test';
        cont.LastName = 'Lead';
        cont.Email = 'testLead@test.com';
        insert cont;
        
        Lead lead = new Lead();
        lead.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Newsletter_Subscription').getRecordTypeId();
        lead.FirstName = 'Test';
        lead.LastName = 'Lead';
        lead.Email = 'testLead@test.com';
        lead.Company = 'Test Company';
        lead.Marketing_Newsletter_Sign_Up__c = true;
        lead.Form_Completion_Date__c = Datetime.now();
        lead.Form_Name__c = 'Test Form';
        insert lead;
        
        Contact updatedcont = [SELECT Id, FirstName, LastName, Email, Signup_MKT_Newsletter__c, Form_Name__c FROM Contact WHERE Email = 'testLead@test.com' LIMIT 1];
        System.assert(updatedcont.Signup_MKT_Newsletter__c == true);
        System.assert(updatedcont.Form_Name__c == 'Test Form');
        
        Lead insertedLead = [SELECT Id, Status FROM Lead WHERE Id = :lead.Id LIMIT 1];
        System.assert(insertedLead.Status == convertStatus.MasterLabel);
        
        Test.stopTest();
    }
    
    @isTest
    public static void testBulk() {
        Test.startTest();
        
        List<Lead> leadList = new List<Lead>();
        String NewsletterRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Newsletter_Subscription').getRecordTypeId();
        
        for(Integer i=0; i<=200; i++) {
            Lead lead = new Lead();
            lead.RecordTypeId = NewsletterRecordType;
            lead.FirstName = 'Test' + i;
            lead.LastName = 'Lead' + i;
            lead.Email = 'testLead@test' + i + '.com';
            lead.Company = 'Test Company' + i;
            lead.Marketing_Newsletter_Sign_Up__c = true;
            lead.Form_Completion_Date__c = Datetime.now();
            lead.Form_Name__c = 'Test Form' + i;
        	leadList.add(lead);
        }
        
        insert leadList;
        
        Test.stopTest();
    }
    
}