/**************************
*  連携共通トリガー管理
**************************/
trigger CooperationResultCommTrigger on CooperationResult__c (after update) {
	if(Trigger.isUpdate && Trigger.isAfter){
		(new CooperationResultTriggerProcess()).autoPostMessageToChatterGroup(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
	}
	
}