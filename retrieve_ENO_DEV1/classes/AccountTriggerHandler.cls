public class AccountTriggerHandler  {

	public static void handleAfterInsert(Map<Id, Account> newMap){
		 //createILPlatformEvents(newMap.values(), null);
	}

	private static void createILPlatformEvents(List<Account> newList, Map<Id, Account> oldMap) {
        List<Outbound_Transfer_Insert_Event__e> toPublish = OutboundPlatformEventHelper.getILPlatformEventsByRecordList(newList, oldMap);
		System.debug('toPublish' +JSON.serialize(toPublish));
        if (!toPublish.isEmpty()) {
            EventBus.publish(toPublish);
        }
    }
}