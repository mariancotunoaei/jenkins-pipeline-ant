/******************************************************************************************************
* @Name         	ContactHandler 
* @Author       	Paraschiv Alexandru
* @Date         	14/07/2021
* @Description 		This class represents the Handler class for ContactTrigger
******************************************************************************************************/

/* MODIFICATION LOG
* Version         	Developer          			Date               		Description
*-----------------------------------------------------------------------------------------------------
* 1.0             	Paraschiv Alexandru      	14/07/2021         		Initial Creation               
* 2.0				Paraschiv Alexandru			26/07/2021				Added Unsubscribe/Resubscribe method
******************************************************************************************************/

public class ContactHandler {
    public static Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    
    public static void handleBeforeInsertTrigger(List<Contact> newContactList) {
        System.debug('Contact Before Insert');
         
        //Calculate audience
        audienceInsert(newContactList);
        upperCaseFirstLetter(newContactList);
    }


    public static void handleBeforeUpdateTrigger(List<Contact> oldContactList, List<Contact> newContactList) {
        System.debug('Contact Before Update');
        
        //Calculate audience
        audienceUpdate(oldContactList, newContactList);
        upperCaseFirstLetter(newContactList);
    }

    public static void handleAfterInsertTrigger(List<Contact> newContactList) {
		
    }
    
    public static void handleAfterUpdateTrigger(List<Contact> oldContactList, List<Contact> newContactList) {
		
        // This part is commented because it only works in Enviorements where Marketing Cloud Connector 
        // is installed and connected (QA2 & Production)
        
        System.debug('Contact After Update');
        
        // Query Metadata for MC MC Integration User Ids for Prod and QA
        Marketing_Cloud_Connected_User__mdt MCUsersId = [SELECT Prod_User_Id__c, QA_User_Id__c FROM Marketing_Cloud_Connected_User__mdt WHERE QualifiedApiName = 'Number1' LIMIT 1];
        System.debug('MCUsersId: ' + MCUsersId);
        if(isSandbox == true) {
            // Call UnsubscribeResubscribe() only if the user is not the MC Integration User
            if(UserInfo.getUserId() != MCUsersId.QA_User_Id__c) {
                UnsubscribeResubscribe(oldContactList, newContactList);
            }
        } else {
            // Call UnsubscribeResubscribe() only if the user is not the MC Integration User
            if(UserInfo.getUserId() != MCUsersId.Prod_User_Id__c) {
            	UnsubscribeResubscribe(oldContactList, newContactList);
            }
        }
		
    }
    
/*
*────────────────────────────────────────────────────────────────────────────────────────────────────────
* @Description 		This method updates the audience fields (checkboxes) when a contact is inserted
*────────────────────────────────────────────────────────────────────────────────────────────────────────
* @param    		newContactList -	A list of contacts that is passed to this method base on the 
*										Trigger.new list
* @return   		void
*────────────────────────────────────────────────────────────────────────────────────────────────────────
*/
    public static void audienceInsert(List<Contact> newContactList) {
        for(Contact cont: newContactList) {
            if(cont.npo02__MembershipJoinDate__c == null && cont.npo02__FirstCloseDate__c == null && cont.Has_Ticket__c == false) {
                cont.No_Transactions__c = true;
            } else {
                cont.No_Transactions__c = false;
            }
            
            if(cont.Has_Ticket__c == true) {
                cont.Customer__c = true;
            } else if(cont.Has_Ticket__c == false) {
                cont.Customer__c = false;
            }
            
            if(cont.npo02__MembershipJoinDate__c != null) {
                cont.Member__c = true;
            } else if(cont.npo02__MembershipJoinDate__c == null) {
                cont.Member__c = false;
            }
            
            if(cont.npo02__FirstCloseDate__c != null) {
                cont.Donor__c = true;
            } else if(cont.npo02__FirstCloseDate__c == null) {
                cont.Donor__c = false;
            }
            
            //Calculate Preferences
            preferences(cont);
        }
    }
    
/*
*────────────────────────────────────────────────────────────────────────────────────────────────────────
* @Description 		This method updates the audience fields (checkboxes) when a contact is updated
*────────────────────────────────────────────────────────────────────────────────────────────────────────
* @param    		oldContactList -	A list of contacts that is passed to this method base on the 
*										Trigger.old list
* @param    		newContactList -	A list of contacts that is passed to this method base on the 
*										Trigger.new list
* @return   		void
*────────────────────────────────────────────────────────────────────────────────────────────────────────
*/
    public static void audienceUpdate(List<Contact> oldContactList, List<Contact> newContactList) {
        Map<Id, Contact> oldContactMap = new Map<Id, Contact>(oldContactList);
        
        for(Contact cont : newContactList) {
            if(cont.npo02__MembershipJoinDate__c == null && cont.npo02__FirstCloseDate__c == null && cont.Has_Ticket__c == false) {
                cont.No_Transactions__c = true;
            } else {
                cont.No_Transactions__c = false;
            }
            
            if((cont.No_Transactions__c == true) && (cont.No_Transactions__c != oldContactMap.get(cont.Id).No_Transactions__c)) {
                cont.Opera__c = true;
                cont.Dance__c = true;
                cont.Musical__c = true;
                cont.Comedy_cabaret__c = true;
                cont.Hospitality__c = true;
                cont.Membership__c = true;
                cont.Making_a_donation__c = true;
            } else if((cont.No_Transactions__c == false) && (cont.No_Transactions__c != oldContactMap.get(cont.Id).No_Transactions__c)) {
                cont.Opera__c = false;
                cont.Dance__c = false;
                cont.Musical__c = false;
                cont.Comedy_cabaret__c = false;
                cont.Hospitality__c = false;
                cont.Membership__c = false;
                cont.Making_a_donation__c = false;
            }
            
            if(cont.Has_Ticket__c != oldContactMap.get(cont.Id).Has_Ticket__c){
                if(cont.Has_Ticket__c == true) {
                    cont.Customer__c = true;
                    cont.Opera__c = true;
                    cont.Dance__c = true;
                    cont.Musical__c = true;
                    cont.Comedy_cabaret__c = true;
                    cont.Hospitality__c = true;
                    cont.Membership__c = true;
                    cont.Making_a_donation__c = true;
                }
            }
            
            if(cont.npo02__MembershipJoinDate__c != oldContactMap.get(cont.Id).npo02__MembershipJoinDate__c) {
                if(cont.npo02__MembershipJoinDate__c != null) {
                    cont.Member__c = true;
                } else if(cont.npo02__MembershipJoinDate__c == null) {
                    cont.Member__c = false;
                }
                
                if(cont.Member__c == true || cont.Donor__c == true) {
                    cont.Monthly_Newsletter__c = true;
                    cont.Member_Events__c = true;
                } else {
                    cont.Monthly_Newsletter__c = false;
                    cont.Member_Events__c = false;
                }
            }
            
            if(cont.npo02__FirstCloseDate__c != oldContactMap.get(cont.Id).npo02__FirstCloseDate__c) {
                if(cont.npo02__FirstCloseDate__c != null) {
                    cont.Donor__c = true;
                } else if(cont.npo02__FirstCloseDate__c == null) {
                    cont.Donor__c = false;
                }
                
                if(cont.Member__c == true || cont.Donor__c == true) {
                    cont.Monthly_Newsletter__c = true;
                    cont.Member_Events__c = true;
                } else {
                    cont.Monthly_Newsletter__c = false;
                    cont.Member_Events__c = false;
                }
            }
        }
        
    }
    
/*
*────────────────────────────────────────────────────────────────────────────────────────────────────────
* @Description 		This method updates the preference fields (checkboxes) when a contact is 
*					inserted or updated
*────────────────────────────────────────────────────────────────────────────────────────────────────────
* @param    		cont -	A contact record
* @return   		void
*────────────────────────────────────────────────────────────────────────────────────────────────────────
*/
    public static void preferences(Contact cont) {
        
        if(cont.No_Transactions__c == true) {
            cont.Opera__c = true;
            cont.Dance__c = true;
            cont.Musical__c = true;
            cont.Comedy_cabaret__c = true;
            cont.Hospitality__c = true;
            cont.Membership__c = true;
            cont.Making_a_donation__c = true;
        } else {
            cont.Opera__c = false;
            cont.Dance__c = false;
            cont.Musical__c = false;
            cont.Comedy_cabaret__c = false;
            cont.Hospitality__c = false;
            cont.Membership__c = false;
            cont.Making_a_donation__c = false;
        }
        
        if(cont.Member__c == true || cont.Donor__c == true) {
            cont.Monthly_Newsletter__c = true;
            cont.Member_Events__c = true;
        } else {
            cont.Monthly_Newsletter__c = false;
            cont.Member_Events__c = false;
        }
        
        if(cont.Customer__c == true) {
            cont.Opera__c = true;
            cont.Dance__c = true;
            cont.Musical__c = true;
            cont.Comedy_cabaret__c = true;
            cont.Hospitality__c = true;
            cont.Membership__c = true;
            cont.Making_a_donation__c = true;
        }
    }
    
/*
*────────────────────────────────────────────────────────────────────────────────────────────────────────
* @Description 		This Unsubscribes/Resubscribes a contact in Marketing Cloud
*────────────────────────────────────────────────────────────────────────────────────────────────────────
* @param    		oldContactList -	A list of contacts that is passed to this method base on the 
*										Trigger.old list
* @param    		newContactList -	A list of contacts that is passed to this method base on the 
*										Trigger.new list
* @return   		void
*────────────────────────────────────────────────────────────────────────────────────────────────────────
*/
    
        // This part is commented because it only works in Enviorements where Marketing Cloud Connector 
        // is installed and connected (QA2 & Production)
        
    public static void UnsubscribeResubscribe(List<Contact> oldContactList, List<Contact> newContactList) {
        Map<Id, Contact> oldContactMap = new Map<Id, Contact>(oldContactList);
        List<Id> unsubscribeList = new List<Id>();
        List<Id> resubscribeList = new List<Id>();
        
        for(Contact cont: newContactList) {
            if((cont.HasOptedOutOfEmail == true) && (cont.HasOptedOutOfEmail != oldContactMap.get(cont.Id).HasOptedOutOfEmail)) {
                unsubscribeList.add(cont.Id);
            }
            
            if((cont.HasOptedOutOfEmail == false) && (cont.HasOptedOutOfEmail != oldContactMap.get(cont.Id).HasOptedOutOfEmail)) {
                resubscribeList.add(cont.Id);
            }
        }
        
        if(unsubscribeList.size() > 0) {
        	MarketingCloudActions.Unsubscribe(unsubscribeList, 'Contact');
    	}
        if(resubscribeList.size() > 0) {
        	MarketingCloudActions.Resubscribe(resubscribeList, 'Contact');
        }
        
    }
/*
*────────────────────────────────────────────────────────────────────────────────────────────────────────
* @Description 		This uppercase the first letter of some fields
*────────────────────────────────────────────────────────────────────────────────────────────────────────
* @param    		newContactList -	A list of contacts that is passed to this method base on the
*										Trigger.new list
* @return   		void
*────────────────────────────────────────────────────────────────────────────────────────────────────────
*/
    private static void upperCaseFirstLetter(List<Contact> contacts) {

        for( Contact contact : contacts){
            contact.FirstName = stringFirstLetterFormat( contact.FirstName );
            contact.LastName = stringFirstLetterFormat( contact.LastName );
            contact.MiddleName = stringFirstLetterFormat( contact.MiddleName);
            contact.Salutation = stringFirstLetterFormat( contact.Salutation );
            contact.Primary_Salutation__c = stringFirstLetterFormat( contact.Primary_Salutation__c );

        }
    }

    private static String stringFirstLetterFormat (String name) {
        String result = '';

        if (name != null && name != '') {
            for (String iter : name.split('[ ]+')) {
                if (iter != null && iter != '') {
                    if (iter.length() > 1) {
                        result += iter.substring(0,1).toUpperCase() + iter.substring(1,iter.length()) + ' ';
                    }
                    else {
                        result += iter.substring(0,1).toUpperCase() + ' ';
                    }
                }
            }
            result = result.substring(0, result.length() - 1);
        }
        return result;
    }

}