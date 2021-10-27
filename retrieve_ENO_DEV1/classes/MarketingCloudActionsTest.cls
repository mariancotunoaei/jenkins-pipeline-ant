/******************************************************************************************************
* @Name         	MarketingCloudActionsTest 
* @Author       	Paraschiv Alexandru
* @Date         	27/07/2021
* @Description 		Test Class for MarketingCloudActionsTest
******************************************************************************************************/

/* MODIFICATION LOG
* Version         	Developer          			Date               		Description
*-----------------------------------------------------------------------------------------------------
* 1.0             	Paraschiv Alexandru      	27/07/2021         		Initial Creation                             
******************************************************************************************************/

@isTest
public class MarketingCloudActionsTest {
	
    @isTest
    public static void unsubscribeTest() {
        List<String> recordIdList = new List<String>();
        
        Test.startTest();
        
        Contact cont = new Contact();
        cont.FirstName = 'Test';
        cont.LastName = 'Contact';
        insert cont;
        
        recordIdList.add(cont.Id);
        
        MarketingCloudActions.Unsubscribe(recordIdList, 'Contact');
        Test.stopTest();
    }
    
    @isTest
    public static void resubscribeTest() {
        List<String> recordIdList = new List<String>();
        
        Test.startTest();
        
        Contact cont = new Contact();
        cont.FirstName = 'Test';
        cont.LastName = 'Contact';
        insert cont;
        
        recordIdList.add(cont.Id);
        
        MarketingCloudActions.Resubscribe(recordIdList, 'Contact');
        Test.stopTest();
    }
    
}