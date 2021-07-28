// 2019/10/30 明細入力時に自動で反映 WGCH BEGIN
// trigger TtendCommTrigger on TTend__c (after delete, after insert, after undelete, after update) {
// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH BEGIN
trigger TtendCommTrigger on TTend__c (after delete, after insert, after undelete, after update, before insert, before update, before delete) {
// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH END
// 2019/10/30 明細入力時に自動で反映 WGCH END
    // 2017/07/13 POS単位現金合せ管理により、Triggerから自動現金へ連携処理を廃止する BEGIN
    // before insert
    // 2020/03/31 会計ロック機能 by zy BEGIN
    if((Trigger.isInsert || Trigger.isUpdate || Trigger.isDelete) && Trigger.isBefore) {
    	if (CommLogicProcess.lockCheck(trigger.new, Trigger.old)) return;
    }
    // 2020/03/31 会計ロック機能 by zy END
    //if(Trigger.isInsert && Trigger.isBefore){}
    // after insert
    if(Trigger.isInsert && Trigger.isAfter){
        TtendTriggerProcess handel = new TtendTriggerProcess();
        handel.syncAccInfoToLead(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
    }
    // before update
    //else if(Trigger.isUpdate && Trigger.isBefore){}
    else if(Trigger.isUpdate && Trigger.isAfter){
        TtendTriggerProcess handel = new TtendTriggerProcess();
        handel.syncAccInfoToLead(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
    }
    // before delete
    //else if(Trigger.isDelete && Trigger.isBefore){}
    // after delete
    else if(Trigger.isDelete && Trigger.isAfter){
        TtendTriggerProcess handel = new TtendTriggerProcess();
        handel.syncAccInfoToLead(trigger.new, Trigger.old, CommConst.TriggerMethod.IsDelete);
    }
    // after undelete
	//else if(Trigger.isUnDelete){}
	// 2017/07/13 POS単位現金合せ管理により、Triggerから自動現金へ連携処理を廃止する END
	// 2019/10/30 明細入力時に自動で反映 WGCH BEGIN
	// before insert
	else if(Trigger.isInsert && Trigger.isBefore){
		TtendTriggerProcess handel = new TtendTriggerProcess();
		// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH BEGIN
        handel.compareSalesdayCalInfo(trigger.new, Trigger.old, CommConst.TriggerMethod.isUpdate);
        // 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH END
		handel.syncAccountMstToTtendItem(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
	}
	// before update
	else if(Trigger.isUpdate && Trigger.isBefore){
		TtendTriggerProcess handel = new TtendTriggerProcess();
		// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH BEGIN
        handel.compareSalesdayCalInfo(trigger.new, Trigger.old, CommConst.TriggerMethod.isUpdate);
        // 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH END
		handel.syncAccountMstToTtendItem(trigger.new, Trigger.old, CommConst.TriggerMethod.isUpdate);
	}
	// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH BEGIN
	else if(Trigger.isDelete && Trigger.isBefore){
		TtendTriggerProcess handel = new TtendTriggerProcess();
        handel.compareSalesdayCalInfo(trigger.new, Trigger.old, CommConst.TriggerMethod.isDelete);
	}
	// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH END
	// 2019/10/30 明細入力時に自動で反映 WGCH END
}