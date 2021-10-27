/**
* Created by ibuzau on 6/23/2021.
* @test : OpportunityTriggerHandlerTest
*/

public with sharing class OpportunityTriggerHandler {
    
    public static void beforeInsert(List<Opportunity> membershipList) {
        System.debug('opp before inset');
        calculateMembershipOrigin(membershipList);
        calculateNumberOfActiveMembershipLevels(membershipList);
    }
    
    public static void beforeUpdate(List<Opportunity> membershipList) {
        System.debug('opp before update');
        calculateNumberOfActiveMembershipLevels(membershipList);
    }
    
    public static void afterInsert() {
        
    }
    
    public static void afterUpdate() {
        
    }
    
    public static void calculateMembershipOrigin(List<Opportunity> membershipList) {
        
        List<String> contactsID = new List<String>();
        
        for (Opportunity opp : membershipList) {
            contactsID.add(opp.npsp__Primary_Contact__c);
        }
        
        Map<Id, Contact> contactMap = new Map<Id, Contact>( [SELECT Name, Id from Contact where id in :contactsID]);
        
        
        List<Opportunity> memberships = [
            SELECT Name, Id,CloseDate, npe01__Member_Level__c, npe01__Membership_End_Date__c,  npsp__Primary_Contact__r.Name,
            npsp__Primary_Contact__c,npe01__Membership_Start_Date__c, RecordTypeId
            from Opportunity
            where npsp__Primary_Contact__c in :contactsID
            ORDER BY npe01__Membership_End_Date__c
        ];
        
        
        Map<String, Decimal> membershipsLevel = new Map<String, Decimal>();
        List<Membership_Level_Benefit__mdt> levels = [SELECT Level__c, Membership_Name__c FROM Membership_Level_Benefit__mdt];
        for (Membership_Level_Benefit__mdt level : levels) {
            membershipsLevel.put(level.Membership_Name__c, level.Level__c);
        }
        
        
        for (Opportunity opp : membershipList) {
            String membershipRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Memberships').getRecordTypeId();
            
            if (opp.npe01__Member_Level__c == 'ENO Friends Trial' || opp.npe01__Member_Level__c == 'ENO Opera Circle Trial') // sau opp.StageName == 'Free Trial'
                opp.npe01__Membership_Origin__c = 'Free Trial'; else
                    if (opp.npsp4hub__Payment_Method__c == 'Gift Voucher')
                    opp.npe01__Membership_Origin__c = 'Gift';
            
            else {
                String name = contactMap.get(opp.npsp__Primary_Contact__c).Name;
                
                if (name != null) {
                    List <Opportunity> contactsMemberships = new List<Opportunity>();
                    for (Opportunity memb : memberships) {
                        if (memb.npsp__Primary_Contact__r.Name.equals(name) && memb.RecordTypeId == membershipRecordTypeId) {
                            contactsMemberships.add(memb);
                        }
                    }

					System.debug('contactsMemberships: '+JSON.serialize(contactsMemberships));
                    
                    if (!contactsMemberships.isEmpty()) {
                        Decimal lastMembershipLevel = membershipsLevel.get(contactsMemberships.get(contactsMemberships.size() - 1).npe01__Member_Level__c);
                        Decimal currentMembershipLevel = membershipsLevel.get(opp.npe01__Member_Level__c);
                        
                        if (contactsMemberships.get(contactsMemberships.size() - 1).npe01__Membership_End_Date__c.daysBetween(opp.npe01__Membership_Start_Date__c) > 30) {
                            opp.npe01__Membership_Origin__c = 'Rejoin';
                        }
                        else {
                            if (lastMembershipLevel == currentMembershipLevel)
                                opp.npe01__Membership_Origin__c = 'Renewal';
                            else
                                if (lastMembershipLevel > currentMembershipLevel)
                                opp.npe01__Membership_Origin__c = 'Downgrade';
                            else
                                opp.npe01__Membership_Origin__c = 'Upgrade';
                            
                        }
                    }
                    else {
                        opp.npe01__Membership_Origin__c = 'New';
                    }
                    
                }
            }
        }
    }
    
    public static void calculateNumberOfActiveMembershipLevels(List<Opportunity> membershipList) {
        
		System.debug('membershipList: '+membershipList);

        List<Id> contactIds = new List<Id>();
        Map<Id, Set<String>> memberLevelMap = new Map<Id, Set<String>>();
        List<Contact> contacts = new List<Contact>();
        
        for (Opportunity opportunity : membershipList) {
            contactIds.add(opportunity.npsp__Primary_Contact__c);
        }
        
		System.debug('contactIds: '+contactIds);

        List<Opportunity> opportunities = [
            SELECT npe01__Member_Level__c, npsp__Primary_Contact__c
            FROM Opportunity
            WHERE npsp__Primary_Contact__c IN : contactIds
            AND Membership_Status__c = 'Active'
        ];

		System.debug('opportunities: '+opportunities);
        
        for (Opportunity opportunity : opportunities) {
			System.debug('opportunity: '+opportunity);
            if (!memberLevelMap.containsKey(opportunity.npsp__Primary_Contact__c)) {
                memberLevelMap.put(opportunity.npsp__Primary_Contact__c, new Set<String>{opportunity.npe01__Member_Level__c});
            } else {
                memberLevelMap.get(opportunity.npsp__Primary_Contact__c).add(opportunity.npe01__Member_Level__c);
            }
        }
        
		System.debug('memberLevelMap: ' + memberLevelMap);

		Contact contact;
        for (Id key : memberLevelMap.keySet()) {
             contact= new Contact(
                Id = key,
                Number_of_Active_Membership_Levels__c = memberLevelMap.get(key).size()
            );
            contacts.add(contact);
        }

		System.debug(JSON.serialize(contacts));
        
        update contacts;
        
    }
    
}