trigger ExpoUserCommTrigger on ExpoUser__c (before insert, before update) {
	// before insert
	if(Trigger.isInsert && Trigger.isBefore){
		ExpoUserTriggerProcess expoUser = new ExpoUserTriggerProcess();
		expoUser.checkExpoUserInfo(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
	}
	// before update
	if(Trigger.isUpdate && Trigger.isBefore){
		ExpoUserTriggerProcess expoUser = new ExpoUserTriggerProcess();
		expoUser.checkExpoUserInfo(Trigger.new, Trigger.old, CommConst.TriggerMethod.isUpdate);
	}
}