trigger OrderCommTrigger on Order__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	// 2018/12/19 EXPO機能（AWS側合わせて）、キャンセル不可整制御追加対応 WSQ BEGIN
	if(Trigger.isUpdate && Trigger.isBefore){
		// 更新前のチェック実施
		OrderTriggerProcess orderTp = new OrderTriggerProcess();
		orderTp.updBeforeCheck(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
	}
	// 2018/12/19 EXPO機能（AWS側合わせて）、キャンセル不可整制御追加対応 WSQ END
	// after update
	if(Trigger.isUpdate && Trigger.isAfter){
		OrderTriggerProcess orderTp = new OrderTriggerProcess();
		orderTp.setStockInfo(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
		// 2018/12/10 EXPO注文ステータスを変更場合、関連情報はAWSへ通知を行う WSQ BEGIN
		orderTp.callInfoToAwsProcess(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
		// 2018/12/10 EXPO注文ステータスを変更場合、関連情報はAWSへ通知を行う WSQ END
	}
}