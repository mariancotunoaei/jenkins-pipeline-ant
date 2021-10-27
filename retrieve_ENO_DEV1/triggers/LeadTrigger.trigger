/******************************************************************************************************
* @Name         	LeadTrigger 
* @Author       	Sorina Grigorescu
* @Date         	26/05/2021
* @Description 		Lead Trigger that calls a handler class when a lead record is created
******************************************************************************************************/

/* MODIFICATION LOG
* Version         Developer          		Date               		Description
*-----------------------------------------------------------------------------------------------------
* 1.0             Sorina Grigorescu      	26/05/2021         		Initial Creation                             
******************************************************************************************************/

trigger LeadTrigger on Lead (before insert, after insert) {
	
    if(Trigger.isBefore) {
        if(Trigger.isInsert) {
            LeadTriggerHandler.beforeInsertTrigger(Trigger.New);
        }
    }
    
    if (Trigger.isAfter) {
        if(Trigger.isInsert) {
            LeadTriggerHandler.afterInsertTrigger(Trigger.new);
        }
    }
    
}