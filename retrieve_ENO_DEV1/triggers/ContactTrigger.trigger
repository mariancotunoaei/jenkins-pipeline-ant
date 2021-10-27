/**********************************************************************************************************
* @Name         	ContactTrigger 
* @Author       	Paraschiv Alexandru
* @Date         	14/07/2021
* @Description 		Contact Trigger that calls a handler class when a contact record is created or updated
**********************************************************************************************************/

/* MODIFICATION LOG
* Version          	Developer                		Date               		Description
*---------------------------------------------------------------------------------------------------------
* 1.0              	Paraschiv Alexandru      		14/07/2021         		Initial Creation  
**********************************************************************************************************/

trigger ContactTrigger on Contact (before insert, before update, after insert, after update) {
    if(Trigger.isBefore) {
        if(Trigger.isInsert) {
            ContactHandler.handleBeforeInsertTrigger(Trigger.New);
        }
        if(Trigger.isUpdate) {
            ContactHandler.handleBeforeUpdateTrigger(Trigger.Old, Trigger.New);
        }
    }
    if (Trigger.isAfter) {
        if(Trigger.isInsert) {
            ContactHandler.handleAfterInsertTrigger(Trigger.New);
        }
        if(Trigger.isUpdate) {
            ContactHandler.handleAfterUpdateTrigger(Trigger.Old, Trigger.New);
        }
    }
}