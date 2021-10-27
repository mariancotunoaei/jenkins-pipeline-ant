public class OutboundPlatformEventTriggerHandler
{
    public static void handleAfterInsert(List<Outbound_Transfer_Insert_Event__e> newList)
    {
        handleILPlatformEventCreation(newList);
    }

    private static void handleILPlatformEventCreation(List<Outbound_Transfer_Insert_Event__e> newList)
    {
        OutboundManager manager = OutboundManager.getInstance();
        manager.addObjectsToBeTransferred(newList);
    }
}