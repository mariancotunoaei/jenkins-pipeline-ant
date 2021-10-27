/******************************************************************************************************
* @Name         	LeadTriggerHandler 
* @Author       	Sorina Grigorescu
* @Date         	31/05/2021
* @Description 		This class represents the Handler class for LeadTrigger
******************************************************************************************************/

/* MODIFICATION LOG
* Version         	Developer          		Date               		Description
*-----------------------------------------------------------------------------------------------------
* 1.0             	Sorina Grigorescu      	31/05/2021         		Initial Creation
* 2.0				Paraschiv Alexandru		15/07/2021				Solution Update
******************************************************************************************************/

public with sharing class LeadTriggerHandler {
    
    public static String NewsletterRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Newsletter_Subscription').getRecordTypeId();
    
    public static void beforeInsertTrigger(List<Lead> newLeadsList) {
        System.debug('Lead Before Insert');
        
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        
        // Change the Status of lead who have Newsletter Subscription as Record Type to the picklist value that represents the Converted state
        // Part of the convertToContact solution
        for(Lead lead : newLeadsList) {
            if(lead.RecordTypeId == NewsletterRecordType) {
            	lead.Status = convertStatus.MasterLabel;
            }
        }
        
    }
    
    public static void afterInsertTrigger(List<Lead> newLeadsList) {
        System.debug('Lead After Insert');
        
        List<Lead> leadsList = new List<Lead>();
        
        for(Lead lead : newLeadsList) {
            if(lead.RecordTypeId == NewsletterRecordType) {
            	leadsList.add(lead);
            }
        }
		
        convertToContact(leadsList);
    }
    
/*
*────────────────────────────────────────────────────────────────────────────────────────────────────────
* @Description 		This method is converting all the leads inserted with the Newsletter Subscription 
*					Record Type to contacts. If the contact is non-existent, a new contact record is 
*					inserted, if the contact exists, that contact record is updated
*────────────────────────────────────────────────────────────────────────────────────────────────────────
* @param    		newLeadsList -	A list of leads that contains all the leads from the Trigger.new  
*									list that have the Newsletter Subscription Record Type
* @return   		void
*────────────────────────────────────────────────────────────────────────────────────────────────────────
*/
    public static void convertToContact(List<Lead> newLeadsList) {
        // Map for Lead Id with Contact
        Map<Id, Contact> existingContactsMap = new Map<Id, Contact>();
        List<String> emailsList = new List<String>();
        List<String> firstNameList = new List<String>();
        List<String> lastNameList = new List<String>();
        List<Contact> upsertContactList = new List<Contact>();
        
        for(Lead lead: newLeadsList) {
            emailsList.add(lead.Email);
            firstNameList.add(lead.FirstName);
            lastNameList.add(lead.LastName);
        }
        
        List<Contact> existingContactsList = [SELECT Id, Name, FirstName, LastName, Email, Signup_MKT_Newsletter__c, General_GDPR_Consent__c, 
                                              Marketing_Newsletter_Sign_Up_Date__c, Form_Name__c 
                                              FROM Contact 
                                              WHERE Email IN :emailsList AND FirstName IN :firstNameList AND LastName IN :lastNameList];
        
        for(Lead lead: newLeadsList) {
            for(Contact cont : existingContactsList) {
                if(lead.FirstName == cont.FirstName && lead.LastName == cont.LastName && lead.Email == cont.Email) {
                    existingContactsMap.put(lead.Id, cont);
                }
            }
        }
        
        for(Lead lead: newLeadsList) {
            // Contact existent
            if(existingContactsMap.get(lead.Id) != null) {
                Contact cont = existingContactsMap.get(lead.Id);
                cont.Signup_MKT_Newsletter__c = lead.Marketing_Newsletter_Sign_Up__c;
                //cont.General_GDPR_Consent__c = true;
                cont.Marketing_Newsletter_Sign_Up_Date__c = lead.Form_Completion_Date__c;
                if(cont.Form_Name__c != null) {
                	cont.Form_Name__c = cont.Form_Name__c + '\n' + lead.Form_Name__c;
                } else {
                    cont.Form_Name__c = lead.Form_Name__c;
                }
                if(cont.HasOptedOutOfEmail == true) {
                    cont.HasOptedOutOfEmail = false;
                }
                
                upsertContactList.add(cont);
            } 
            // Contact non-existent
            else {
                Contact newCont = new Contact();
                newCont.FirstName = lead.FirstName;
                newCont.LastName = lead.LastName;
                newCont.Email = lead.Email;
                newCont.Signup_MKT_Newsletter__c = lead.Marketing_Newsletter_Sign_Up__c;
                //newCont.General_GDPR_Consent__c = true;
                newCont.Marketing_Newsletter_Sign_Up_Date__c = lead.Form_Completion_Date__c;
                newCont.Form_Name__c = lead.Form_Name__c;
                newCont.LeadSource = 'Newsletter SignUp';
                
                upsertContactList.add(newCont);
            }
        }
        
        try {
            upsert upsertContactList;
        } catch(DmlException e) {
            System.debug('Lead Trigger Handler Error: ' + e);
            SystemLogUtils.createSystemLog(e.getDmlId(0) , 'Lead After Insert', 'ERROR', e.getMessage(), e.getStackTraceString(), 'APEX');
            e.setMessage('Failed DML Operation: Couldn\'t insert/update the contact' );
        }
    }
   
}