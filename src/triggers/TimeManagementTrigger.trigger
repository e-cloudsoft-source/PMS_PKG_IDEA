/**************************
* 勤怠管理トリガー
**************************/
trigger TimeManagementTrigger on TimeManagement__c (before insert, before update, after insert, after update) {
	// before update
    if(Trigger.isInsert && Trigger.isBefore){
    	(new TimeManagementTriggerProcess()).autoSetupTimeManagement(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
    	(new TimeManagementTriggerProcess()).autoSetupOverTime(trigger.new);
    }
	// before update
    if(Trigger.isUpdate && Trigger.isBefore){
    	(new TimeManagementTriggerProcess()).autoSetupTimeManagement(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
    	(new TimeManagementTriggerProcess()).autoSetupOverTime(trigger.new);
    }
    // after insert
    else if(Trigger.isInsert && Trigger.isAfter){
    	// 勤怠情報IDはスッタフテーブルに反映
		(new TimeManagementTriggerProcess()).linkIdToStaffSchedule(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
    
    }
    // after update
    else if(Trigger.isUpdate && Trigger.isAfter){
    	// 勤怠情報IDはスッタフテーブルに反映
    	(new TimeManagementTriggerProcess()).linkIdToStaffSchedule(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
    
    }
}