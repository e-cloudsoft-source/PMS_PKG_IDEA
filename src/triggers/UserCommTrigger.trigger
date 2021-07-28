trigger UserCommTrigger on User (before insert, before update) {
	// before insert
    if(Trigger.isInsert && Trigger.isBefore){
    	(new UserTriggerProcess()).autoSetupUserTimeUnit(trigger.new,trigger.old,CommConst.TriggerMethod.IsInsert);
    	(new UserTriggerProcess()).autoSetupDefaultShopCode(trigger.new, null);
    } else if (Trigger.isUpdate && Trigger.isBefore){
    	(new UserTriggerProcess()).autoSetupUserTimeUnit(trigger.new,trigger.old,CommConst.TriggerMethod.IsUpdate);
    	(new UserTriggerProcess()).autoSetupDefaultShopCode(trigger.new, trigger.old);
    }
}