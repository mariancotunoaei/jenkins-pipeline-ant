/******************************************************************************************************
* @Name         	MarketingCloudActions 
* @Author       	Paraschiv Alexandru
* @Date         	26/07/2021
* @Description 		This class methods are actions performed in Marketing Cloud using APIs  
******************************************************************************************************/

/* MODIFICATION LOG
* Version         	Developer          			Date               		Description
*-----------------------------------------------------------------------------------------------------
* 1.0             	Paraschiv Alexandru      	26/07/2021         		Initial Creation                             
******************************************************************************************************/

public class MarketingCloudActions {
	
/*
*────────────────────────────────────────────────────────────────────────────────────────────────────────
* @Description 		This method unsubscribes a contact in Marketing Cloud
*────────────────────────────────────────────────────────────────────────────────────────────────────────
* @param    		recordIdList -	List of Ids for the records that needs to be unsubscribed (same as 
*									Subscriber Key in Marketing Cloud)
* @param    		objectName -	The sObject of the records that needs to be unsubscribed (works with 
*									Contact, Lead or Person Account)
* @return   		void
*────────────────────────────────────────────────────────────────────────────────────────────────────────
*/
    
    @future(callout=true)
    public static void Unsubscribe(List<String> recordIdList, String objectName) {
        String unsubResult;
        
        for(String recordId : recordIdList) {
            //Hidden method, part of the Marketing Cloud Connector Package
            //unsubResult = et4ae5.jsButtonMethods.performUnsub(recordId, objectName);
            System.debug('Unsubscribe Result: ' + unsubResult);
        }
    }
    
/*
*────────────────────────────────────────────────────────────────────────────────────────────────────────
* @Description 		This method resubscribes a contact in Marketing Cloud
*────────────────────────────────────────────────────────────────────────────────────────────────────────
* @param    		recordIdList -	List of Ids for the records that needs to be resubscribed (same as 
*									Subscriber Key in Marketing Cloud)
* @param    		objectName -	The sObject of the record that needs to be resubscribed (works with 
*									Contact, Lead or Person Account)
* @return   		void
*────────────────────────────────────────────────────────────────────────────────────────────────────────
*/
    
    @future(callout=true)
    public static void Resubscribe(List<String> recordIdList, String objectName) {
        String resubResult;
        
        for(String recordId : recordIdList) {
            //Hidden method, part of the Marketing Cloud Connector Package
            //resubResult = et4ae5.jsButtonMethods.performResub(recordId, objectName);
            System.debug('Resubscribe Result: ' + resubResult);
        }
    }
    
	/*
    @future(callout=true)
    public static void OneCall(Map<Id, Boolean> recordMap, String objectName) {
        String unsubResult;
        String resubResult;
        
        for(Id key : recordMap.keySet()) {
            //Hidden method, part of the Marketing Cloud Connector Package
            if(recordMap.get(key) == true) {
                unsubResult = et4ae5.jsButtonMethods.performUnsub(key, objectName);
                System.debug('Unsubscribe Result: ' + unsubResult);
            } else if(recordMap.get(key) == false) {
                resubResult = et4ae5.jsButtonMethods.performResub(key, objectName);
            	System.debug('Resubscribe Result: ' + resubResult);
            }
        }
        
    }
	*/
}