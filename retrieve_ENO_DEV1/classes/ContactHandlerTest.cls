/******************************************************************************************************
* @Name         	ContactHandlerTest 
* @Author       	Paraschiv Alexandru
* @Date         	14/07/2021
* @Description 		Test Class for ContactHandler
******************************************************************************************************/

/* MODIFICATION LOG
* Version         	Developer          			Date               		Description
*-----------------------------------------------------------------------------------------------------
* 1.0             	Paraschiv Alexandru      	14/07/2021         		Initial Creation                             
******************************************************************************************************/

@isTest
public class ContactHandlerTest {
    
    @isTest
    public static void contactNoTransaction() {
        Test.startTest();
        
        Contact cont = new Contact();
        cont.FirstName = 'Test';
        cont.LastName = 'Contact';
        insert cont;
        
        Contact newCont = [SELECT No_Transactions__c, Member__c, Customer__c, Donor__c FROM Contact WHERE FirstName = 'Test' LIMIT 1];
        System.assert(newCont.No_Transactions__c == true);
        System.assert(newCont.Member__c == false);
        System.assert(newCont.Donor__c == false);
        System.assert(newCont.Customer__c == false);
        
        Test.stopTest();
    }
    
    @isTest
    public static void contactMembership() {
        Test.startTest();
        
        Contact cont = new Contact();
        cont.FirstName = 'Test';
        cont.LastName = 'Contact';
        insert cont;
        
        Opportunity oppMembership = new Opportunity();
        oppMembership.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Membership').getRecordTypeId();
        oppMembership.Name = 'Test Opportunity Membership';
        oppMembership.npsp__Primary_Contact__c = cont.Id;
        oppMembership.Amount = 1000.00;
        oppMembership.StageName = 'Paid';
        oppMembership.CloseDate = Date.today();
        oppMembership.npe01__Membership_End_Date__c = Date.today();
        oppMembership.npe01__Membership_Start_Date__c = Date.today();
        oppMembership.Membership_Scheme__c = 'ENO Friends';
        oppMembership.npe01__Member_Level__c = 'ENO Friends Bronze';
        insert oppMembership;
        
        cont.npo02__MembershipJoinDate__c = Date.today();
        update cont;
        
        Contact newCont = [SELECT No_Transactions__c, Member__c, Customer__c, Donor__c FROM Contact WHERE FirstName = 'Test' LIMIT 1];
        System.assert(newCont.No_Transactions__c == false);
        System.assert(newCont.Member__c == true);
        System.assert(newCont.Donor__c == false);
        System.assert(newCont.Customer__c == false);
        
        Test.stopTest();
    }
    
    @isTest
    public static void updateContactDonor() {
        Test.startTest();
        
        Contact cont = new Contact();
        cont.FirstName = 'Test';
        cont.LastName = 'Contact';
        insert cont;
        
        Opportunity oppDonor = new Opportunity();
        oppDonor.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Donation').getRecordTypeId();
        oppDonor.Name = 'Test Opportunity Donor';
        oppDonor.npsp__Primary_Contact__c = cont.Id;
        oppDonor.Amount = 1000;
        oppDonor.StageName = 'Paid';
        oppDonor.npe01__Membership_End_Date__c = Date.today();
        oppDonor.CloseDate = Date.today();
        oppDonor.npe01__Membership_Start_Date__c = Date.today().addDays(-2);
        insert oppDonor;
        
        cont.npo02__FirstCloseDate__c = Date.today();
        update cont;
        
        Contact newCont = [SELECT No_Transactions__c, Member__c, Customer__c, Donor__c FROM Contact WHERE FirstName = 'Test' LIMIT 1];
        System.assert(newCont.No_Transactions__c == false);
        System.assert(newCont.Member__c == false);
        System.assert(newCont.Donor__c == true);
        System.assert(newCont.Customer__c == false);
        
        cont.npo02__FirstCloseDate__c = null;
        update cont;
        
        Contact newCont2 = [SELECT No_Transactions__c, Member__c, Customer__c, Donor__c FROM Contact WHERE FirstName = 'Test' LIMIT 1];
        System.assert(newCont2.No_Transactions__c == true);
        System.assert(newCont2.Member__c == false);
        System.assert(newCont2.Donor__c == false);
        System.assert(newCont2.Customer__c == false);
        
        Test.stopTest();
    }
    
    @isTest
    public static void updateContactTicket() {
        Test.startTest();
        
        Contact cont = new Contact();
        cont.FirstName = 'Test';
        cont.LastName = 'Contact';
        insert cont;
        
        Ticket__c ticket = new Ticket__c();
        ticket.Name = 'Test Ticket';
        ticket.Contact__c = cont.Id;
        insert ticket;
        
        cont.Email = 'test@email.com';
        update cont;
        
        Contact newCont = [SELECT No_Transactions__c, Member__c, Customer__c, Donor__c FROM Contact WHERE FirstName = 'Test' LIMIT 1];
        System.assert(newCont.No_Transactions__c == false);
        System.assert(newCont.Member__c == false);
        System.assert(newCont.Donor__c == false);
        System.assert(newCont.Customer__c == true);
        
        Test.stopTest();
    }
    
    @isTest
    public static void updateContactAll() {
        Test.startTest();
        
        Contact cont = new Contact();
        cont.FirstName = 'TestUpdateAll';
        cont.LastName = 'ContactAll';
        insert cont;
        
        Opportunity oppMembership = new Opportunity();
        oppMembership.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Membership').getRecordTypeId();
        oppMembership.Name = 'Test Opportunity Membership2';
        oppMembership.npsp__Primary_Contact__c = cont.Id;
        oppMembership.Amount = 1000;
        oppMembership.StageName = 'Paid';
        oppMembership.npe01__Membership_End_Date__c = Date.today();
        oppMembership.CloseDate = Date.today();
        oppMembership.npe01__Membership_Start_Date__c = Date.today().addDays(-2);
        insert oppMembership;
        
        Opportunity oppDonor = new Opportunity();
        oppDonor.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Donation').getRecordTypeId();
        oppDonor.Name = 'Test Opportunity Donor2';
        oppDonor.npsp__Primary_Contact__c = cont.Id;
        oppDonor.Amount = 1000;
        oppDonor.StageName = 'Paid';
        oppDonor.npe01__Membership_End_Date__c = Date.today();
        oppDonor.CloseDate = Date.today();
        oppDonor.npe01__Membership_Start_Date__c = Date.today().addDays(-2);
        insert oppDonor;
        
        Ticket__c ticket = new Ticket__c();
        ticket.Name = 'Test Ticket2';
        ticket.Contact__c = cont.Id;
        insert ticket;
        
        cont.Email = 'test@email.com';
        cont.npo02__FirstCloseDate__c = Date.today();
        cont.npo02__MembershipJoinDate__c = Date.today();
        update cont;
        
        Contact newCont = [SELECT No_Transactions__c, Member__c, Customer__c, Donor__c FROM Contact WHERE FirstName = 'TestUpdateAll' LIMIT 1];
        System.assert(newCont.No_Transactions__c == false);
        System.assert(newCont.Member__c == true);
        System.assert(newCont.Donor__c == true);
        System.assert(newCont.Customer__c == true);
        
        Test.stopTest();
    }
    
    @isTest
    public static void testBulk() {
        List<Contact> contList = new List<Contact>();        
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('HH_Account').getRecordTypeId();
        
        insert acc;
        
        Test.startTest();
        for(Integer i=0; i<=200; i++) {
            Contact cont = new Contact();
            cont.FirstName = 'TestBulk' + i;
            cont.LastName = 'ContactBulk' + i;
            cont.AccountId = acc.Id;
            
            contList.add(cont);
        }
        
        insert contList;
        Test.stopTest();
    }
    
}