// 2020/03/31 会計ロック機能 by zy BEGIN
trigger PaymentslipCommTrigger on Paymentslip__c (before insert, before update,after delete,after insert, after update) {	
	if((Trigger.isInsert || Trigger.isUpdate || Trigger.isDelete) && Trigger.isAfter){
		if (CommLogicProcess.lockCheck(trigger.new, Trigger.old,Trigger.isAfter)) return;
	}
	// 2020/03/31 会計ロック機能 by zy END
	if(Trigger.isInsert && Trigger.isBefore){
		CashManagentInput handle = new CashManagentInput();
		handle.paySalesInfoAutoSetup(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
	}	
    // before update
    else if(Trigger.isUpdate && Trigger.isBefore){
    	CashManagentInput handle = new CashManagentInput();
    	handle.paySalesInfoAutoSetup(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
    	
    }
}