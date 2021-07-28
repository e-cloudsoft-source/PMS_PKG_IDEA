/**
* This trigger populates account lookup in call information with matching number
*/ 
trigger SyncAccountWithCallInfo on Account (after insert) {
    CustomerCallInfoSyncHandler.afterInsertCustomer(Trigger.new);
}