/**************************
* 会計商品共通トリガー管理
**************************/
trigger AccountMasterCommTrigger on AccountMaster__c (before insert, before update, before delete, after insert, after update, after undelete) {
    // before insert
    if(Trigger.isInsert && Trigger.isBefore){
    	(new AccountMasterTriggerProcess()).autoSetupAccountMaster(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
    }
    // before update
    else if(Trigger.isUpdate && Trigger.isBefore){
    	(new AccountMasterTriggerProcess()).autoSetupAccountMaster(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
	}
	// 2018/09/19: 固定の会計商品は削除できないように制限追加 BEGIN
	// before delete
    else if(Trigger.isDelete && Trigger.isBefore){
    	(new AccountMasterTriggerProcess()).deletePreCheck(trigger.new, Trigger.old, CommConst.TriggerMethod.IsDelete);
    	// 2019/06/06 EXPO会計商品削除場合、関連情報はAWSへ通知を行う WSQ BEGIN
    	(new AccountMasterTriggerProcess()).callDelInfoToAwsProcess(trigger.new, Trigger.old, CommConst.TriggerMethod.IsDelete);
    	// 2019/06/06 EXPO会計商品削除場合、関連情報はAWSへ通知を行う WSQ END
	}
	// 2018/09/19: 固定の会計商品は削除できないように制限追加 END
	// 2018/12/10 EXPO会計商品変更場合、関連情報はAWSへ通知を行う WSQ BEGIN
	else if(Trigger.isInsert && Trigger.isAfter){
		(new AccountMasterTriggerProcess()).callInfoToAwsProcess(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
	}
	else if(Trigger.isUpdate && Trigger.isAfter){
		(new AccountMasterTriggerProcess()).callInfoToAwsProcess(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
	}
	// 2018/12/10 EXPO会計商品変更場合、関連情報はAWSへ通知を行う WSQ END
	// 2019/08/21 EXPO会計商品変更場合、関連情報はAWSへ通知を行う WSQ BEGIN
	else if(Trigger.isUnDelete){
		(new AccountMasterTriggerProcess()).callInfoToAwsProcess(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
	}
	// 2019/08/21 EXPO会計商品変更場合、関連情報はAWSへ通知を行う WSQ END
}