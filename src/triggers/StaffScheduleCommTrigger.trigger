trigger StaffScheduleCommTrigger on StaffSchedule__c (before insert, before update, before delete) {
    // before insert
    if(Trigger.isInsert && Trigger.isBefore){
    	StaffScheduleTriggerProcess handel = new StaffScheduleTriggerProcess();
    	handel.autoSetupStaffSchedule(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
    }
    // before update
    else if(Trigger.isUpdate && Trigger.isBefore){
        StaffScheduleTriggerProcess handel = new StaffScheduleTriggerProcess();
        handel.autoSetupStaffSchedule(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
	}
	// /before delete
	else if(Trigger.isDelete && Trigger.isBefore){
		StaffScheduleTriggerProcess handel = new StaffScheduleTriggerProcess();
		handel.autoSetupStaffSchedule(trigger.new, Trigger.old, CommConst.TriggerMethod.isDelete);
	}
}