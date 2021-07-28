/**
* This trigger populates contact lookup on call information based on matching number
*/
trigger SyncContactWithCallInfo on Contact(after insert) {
    CustomerCallInfoSyncHandler.afterInsertCustomer(Trigger.new);
}