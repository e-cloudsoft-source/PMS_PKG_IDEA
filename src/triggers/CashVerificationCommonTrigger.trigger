// 2020/03/31 会計ロック機能 by zy BEGIN
trigger CashVerificationCommonTrigger on CashVerification__c (after insert, after update,before delete, before insert, before update) {
    if((Trigger.isInsert || Trigger.isUpdate || Trigger.isDelete) && Trigger.isBefore){
        if (CommLogicProcess.lockCheck(trigger.new, Trigger.old)) return;
    }
    // 2020/03/31 会計ロック機能 by zy END
    // before insert
    if(Trigger.isInsert && Trigger.isAfter){
    	(new CashVerificationTriggerProcess()).writeChangeInfoToHistory(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
    } 
    // before update
    else if(Trigger.isUpdate && Trigger.isAfter){
    	(new CashVerificationTriggerProcess()).writeChangeInfoToHistory(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
	}
}