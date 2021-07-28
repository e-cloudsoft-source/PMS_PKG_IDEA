trigger AccountsCommTrigger on AccountAcount__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	// 2020/03/31 会計ロック機能 by zy BEGIN
    if((Trigger.isInsert || Trigger.isUpdate || Trigger.isDelete) && Trigger.isBefore){
        if (CommLogicProcess.lockCheck(trigger.new, Trigger.old)) return;
    }
    // 2020/03/31 会計ロック機能 by zy END
    // before insert
    if(Trigger.isInsert && Trigger.isBefore){
    	AccountsTriggerProcess handel = new AccountsTriggerProcess();
    	// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH BEGIN
    	if(handel.compareSalesdayCalInfo(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert)) return;
    	// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH END
    	handel.autoSetupInfo(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
    	// 2013/08/05 ADD 部屋、部屋タイプ、支店情報設定
    	handel.copyRoomInfo(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
		// 2017/01/25 店舗ごとの会計権限機能対応 BEGIN
    	handel.setupSerialNo(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
    	// 2017/01/25 店舗ごとの会計権限機能対応 END
    }
    // after insert
    else if(Trigger.isInsert && Trigger.isAfter){
        AccountsTriggerProcess handel = new AccountsTriggerProcess();
        // 2017/01/25 店舗ごとの会計権限機能対応 BEGIN
        //handel.setupSerialNo(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
        // 2017/01/25 店舗ごとの会計権限機能対応 END
        // 2013/03/27 ADD
        handel.syncAccInfoToLead(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
        // 2016/05/13 ADD
        CommLogicProcess.writeChangeInfoToHistory(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
    }
    // before update
    else if(Trigger.isUpdate && Trigger.isBefore){
    	// 重複チェックを行う
    	(new CommLogicProcess()).hasCandidateDuplicates(trigger.new, 
    		AccountAcount__c.Name.getDescribe().getName(), 
    		AccountAcount__c.sObjectType.getDescribe().getName());
        AccountsTriggerProcess handel = new AccountsTriggerProcess();
        // 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH BEGIN
    	if(handel.compareSalesdayCalInfo(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate)) return;
    	// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH END
        handel.autoSetupInfo(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
    	// 2013/08/05 ADD 部屋、部屋タイプ、支店情報設定
    	handel.copyRoomInfo(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
	}
    else if(Trigger.isUpdate && Trigger.isAfter){
        // 2013/03/27 ADD
        AccountsTriggerProcess handel = new AccountsTriggerProcess();
        handel.syncAccInfoToLead(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
        // 2016/05/13 ADD
        CommLogicProcess.writeChangeInfoToHistory(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);

    }
    // 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH BEGIN
    // before delete
    else if(Trigger.isDelete && Trigger.isBefore){
    	AccountsTriggerProcess handel = new AccountsTriggerProcess();
    	if(handel.compareSalesdayCalInfo(trigger.new, Trigger.old, CommConst.TriggerMethod.IsDelete)) return;
    }
    // 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH END
    // before delete
//    else if(Trigger.isDelete && Trigger.isBefore){}
    // after delete
//    else if(Trigger.isDelete && Trigger.isAfter){}
    // after undelete
//    else if(Trigger.isUnDelete){}
}