trigger CallInformationCommTrigger on Call_information__c (after insert, after update) {
	if(Trigger.isInsert && Trigger.isAfter){
		(new CallInformationTriggerProcess()).autoPostMessageToChatterGroup(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
	} else if(Trigger.isUpdate && Trigger.isAfter){
		(new CallInformationTriggerProcess()).autoPostMessageToChatterGroup(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
	}
}