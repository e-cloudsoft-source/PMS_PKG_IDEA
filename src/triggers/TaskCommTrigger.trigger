trigger TaskCommTrigger on Task (after delete, after insert, after update) {
    // after insert
    if(Trigger.isInsert && Trigger.isAfter){
    	TaskTriggerProcess handel = new TaskTriggerProcess();
    	handel.updRelationAcccounts(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
    } 
    // after update
    else if(Trigger.isUpdate && Trigger.isAfter){
    	TaskTriggerProcess handel = new TaskTriggerProcess();
    	handel.updRelationAcccounts(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
    }
    // after delete
    else if(Trigger.isDelete && Trigger.isAfter){
    	TaskTriggerProcess handel = new TaskTriggerProcess();
    	handel.updRelationAcccounts(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsDelete);
    }
}