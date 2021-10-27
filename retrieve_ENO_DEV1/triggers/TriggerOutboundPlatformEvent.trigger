trigger TriggerOutboundPlatformEvent on Outbound_Transfer_Insert_Event__e(after insert)
{
    OutboundPlatformEventTriggerHandler.handleAfterInsert(Trigger.new);
}