/**************************
* 勤務休憩管理トリガー
**************************/
trigger RestTimeManagementTrigger on RestTimeManagement__c (before update) {
	// before update
    if(Trigger.isUpdate && Trigger.isBefore){
    	(new RestTimeManagementTriggerProcess()).autoSetupRestTimeManagement(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
    }
}