trigger BookingEstimateItemCommTrigger on BookingEstimateItem__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	if (DataFixManagerUtils.tranTriggerIsStop()) return;
    // before insert
    if(Trigger.isInsert && Trigger.isBefore){
        BookingEstimateItemTriggerProcess handel = new BookingEstimateItemTriggerProcess();
        handel.syncAccountMstToBookingItem(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
        handel.autoSetupFieldValue(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
    }
    // after insert
    else if(Trigger.isInsert && Trigger.isAfter){
    	BookingEstimateItemTriggerProcess handel = new BookingEstimateItemTriggerProcess();
    	handel.syncInfoToLead(trigger.new);
    	handel.expandPlanItem(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
    	// 2015/09/27 ADD
    	handel.syncNumsPlanToDetail(trigger.new, Trigger.old);
    	// 2018/07/27 宿泊税計算 ANDD
    	handel.planDetailToPlanHeader(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
        // 2019/07/15 項目変更により、自動アラート、通知機能の対応（予約と見積明細のみ連動検知機能を対応する） by zy BEGIN
        CommonNotifacationCtrl.updNoticationSobjectName(trigger.new, Trigger.old, 'BookingEstimateItem__c',CommConst.TriggerMethod.IsInsert,'refBooking__c');
        // 2019/07/15 項目変更により、自動アラート、通知機能の対応（予約と見積明細のみ連動検知機能を対応する） by zy END
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
        handel.updataPlanBrkToHeader(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
        // 2019/07/30 軽減税率機能対応 WGCH END
    }
    // before update
    else if(Trigger.isUpdate && Trigger.isBefore){
    	// 項目内容自動設定する
    	BookingEstimateItemTriggerProcess handel = new BookingEstimateItemTriggerProcess();
    	// 商品コードを変更する場合、情報再設定をこなう
    	handel.syncAccountMstToBookingItem(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
    	// 金額合計再計算を行う
    	handel.autoSetupFieldValue(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
    }
    // after update
    else if(Trigger.isUpdate && Trigger.isAfter){
    	BookingEstimateItemTriggerProcess handel = new BookingEstimateItemTriggerProcess();
    	handel.syncInfoToLead(trigger.new);
    	handel.expandPlanItem(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
    	// プランの数量は該当関連の見積もり明細に連動コピーを行う
    	handel.syncNumsPlanToDetail(trigger.new, Trigger.old);
    	// 2018/07/27 宿泊税計算 ANDD
    	handel.planDetailToPlanHeader(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
        // 2019/07/15 項目変更により、自動アラート、通知機能の対応（予約と見積明細のみ連動検知機能を対応する） by zy BEGIN
        CommonNotifacationCtrl.updNoticationSobjectName(trigger.new, Trigger.old, 'BookingEstimateItem__c',CommConst.TriggerMethod.isUpdate,'refBooking__c');
        // 2019/07/15 項目変更により、自動アラート、通知機能の対応（予約と見積明細のみ連動検知機能を対応する） by zy END
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
        handel.updataPlanBrkToHeader(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
        // 2019/07/30 軽減税率機能対応 WGCH END
    }
    // before delete
    else if(Trigger.isDelete && Trigger.isBefore){
    	BookingEstimateItemTriggerProcess handel = new BookingEstimateItemTriggerProcess();
    	handel.expandPlanItem(trigger.new, Trigger.old, CommConst.TriggerMethod.IsDelete);
    }
    // after delete
    // 2019/07/15 項目変更により、自動アラート、通知機能の対応（予約と見積明細のみ連動検知機能を対応する） by zy BEGIN
    else if(Trigger.isDelete && Trigger.isAfter){
        CommonNotifacationCtrl.updNoticationSobjectName(trigger.new, Trigger.old, 'BookingEstimateItem__c',CommConst.TriggerMethod.isDelete,'refBooking__c');
    }
    // 2019/07/15 項目変更により、自動アラート、通知機能の対応（予約と見積明細のみ連動検知機能を対応する） by zy END
    // after undelete
//    else if(Trigger.isUnDelete){}
}