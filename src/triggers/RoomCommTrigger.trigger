trigger RoomCommTrigger on Room__c (after update) {
    // after update
    if(Trigger.isUpdate && Trigger.isAfter){
    	(new RoomCommTriggerProcess()).syncRoomInfoToLeads(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
    }
}