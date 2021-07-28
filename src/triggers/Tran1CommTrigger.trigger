trigger Tran1CommTrigger on Tran1__c (after delete, after insert, after undelete,
after update, before delete, before insert, before update) {
    // 2020/03/31 会計ロック機能 by zy BEGIN
    if((Trigger.isInsert || Trigger.isUpdate || Trigger.isDelete) && Trigger.isBefore) {
    	if (CommLogicProcess.lockCheck(trigger.new, Trigger.old)) return;
    }
    // 2020/03/31 会計ロック機能 by zy END
    // 2019/10/05 見積もり明細の金額変更ロジック by zy BEGIN
    if (DataFixManagerUtils.tranTriggerIsStop()) return;
    // 2019/10/05 見積もり明細の金額変更ロジック by zy END
    // before insert
    if(Trigger.isInsert && Trigger.isBefore){
    	Tran1TriggerProcess handel = new Tran1TriggerProcess();
    	handel.syncAccountMstToTran1Item(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
    	// 予約情報から会計明細へ反映を行う
    	handel.copyLeadInfoToTranItem(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
    }
    // after insert
    else if(Trigger.isInsert && Trigger.isAfter){
        Tran1TriggerProcess handel = new Tran1TriggerProcess();
        handel.expandPlanItem(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
        // 2015/09/27 ADD
        handel.syncNumsPlanToDetail(trigger.new, Trigger.old);
        // 2018/10/05 EXPO在庫機能対応 WSQ BEGIN
        handel.setStockInfo(trigger.new, Trigger.old,CommConst.TriggerMethod.IsInsert);
        // 2018/10/05 EXPO在庫機能対応 WSQ END
    }
    // before update
    else if(Trigger.isUpdate && Trigger.isBefore){
    	Tran1TriggerProcess handel = new Tran1TriggerProcess();
    	// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH BEGIN
    	handel.compareSalesdayCalInfo(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
    	// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH END
    	// 修正前のプランの関連見積もり明細データを作成を行う
    	handel.syncAccountMstToTran1Item(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
    }
    else if(Trigger.isUpdate && Trigger.isAfter){
    	Tran1TriggerProcess handel = new Tran1TriggerProcess();
    	// 不要なプラン関連明細データ
    	handel.expandPlanItem(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
    	// プランの数量は該当関連の見積もり明細に連動コピーを行う
    	handel.syncNumsPlanToDetail(trigger.new, Trigger.old);
        // 2018/10/05 EXPO在庫機能対応 WSQ BEGIN
        handel.setStockInfo(trigger.new, Trigger.old,CommConst.TriggerMethod.IsUpdate);
        // 2018/10/05 EXPO在庫機能対応 WSQ END
    }
    // before delete
    else if(Trigger.isDelete && Trigger.isBefore){
        Tran1TriggerProcess handel = new Tran1TriggerProcess();
        // 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH BEGIN
        handel.compareSalesdayCalInfo(trigger.new, Trigger.old, CommConst.TriggerMethod.IsDelete);
        // 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH END
        handel.expandPlanItem(trigger.new, Trigger.old, CommConst.TriggerMethod.IsDelete);
        // 2018/10/05 EXPO在庫機能対応 WSQ BEGIN
        handel.setStockInfo(trigger.new, Trigger.old,CommConst.TriggerMethod.IsDelete);
        // 2018/10/05 EXPO在庫機能対応 WSQ END
    }
    // after delete
    //else if(Trigger.isDelete && Trigger.isAfter){}
    // after undelete
//    else if(Trigger.isUnDelete){}
}