trigger GuestRoomStockCommTrigger on GuestRoomStock__c (before insert, before update) {
    if(Trigger.isInsert && Trigger.isBefore){
        (new GuestRoomStockCommTriggerProcess()).autoSyncStockChange(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
    }
    if(Trigger.isUpdate && Trigger.isBefore){
        (new GuestRoomStockCommTriggerProcess()).autoSyncStockChange(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
    }
}