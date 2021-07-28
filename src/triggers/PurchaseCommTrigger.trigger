// 2020/03/31 会計ロック機能 by zy BEGIN
trigger PurchaseCommTrigger on Purchase__c (before insert, before update, before delete) {
    if((Trigger.isInsert || Trigger.isUpdate || Trigger.isDelete) && Trigger.isBefore){
        if (CommLogicProcess.lockCheck(trigger.new, Trigger.old)) return;
    }
    // 2020/03/31 会計ロック機能 by zy END
	// before insert
    if(Trigger.isInsert && Trigger.isBefore){
    	(new PurchaseCommTriggerProcess()).autoSetupAmountCompute(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
    }
    // before update
    else if(Trigger.isUpdate && Trigger.isBefore){
    	(new PurchaseCommTriggerProcess()).autoSetupAmountCompute(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
	}
}