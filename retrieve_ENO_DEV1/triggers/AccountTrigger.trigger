trigger AccountTrigger on Account (before insert, before update, after insert, after update)  { 
	
	if(Trigger.isInsert&&Trigger.isAfter){
		AccountTriggerHandler.handleAfterInsert(trigger.newMap);
	}
}