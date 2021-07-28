trigger LeadCommTrigger on Lead__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	// 2018/08/27 予約データ検索キー設定の場合、トリガー処理ロジックは対象外になる BEGIN
//System.debug(loggingLevel.info, '--------TRIGGER BEGIN -------');
	// 2018/08/10 TL->JR変換の紐付ける処理の対応 BEGIN
	if (DataFixManagerUtils.tranTriggerIsStop()) return;
	// 2018/08/10 TL->JR変換の紐付ける処理の対応 END
	if (DataFixManagerUtils.getInstance().LeadUpdateFlg__c) return;
//System.debug(loggingLevel.info, '--------TRIGGER END -------');
	// 2018/08/27 予約データ検索キー設定の場合、トリガー処理ロジックは対象外になる END
    // before insert
    if(Trigger.isInsert && Trigger.isBefore){
        // 部屋から部屋タイプの自動設定()
        LeadTriggerProcess handel = new LeadTriggerProcess();
		// プラン設定チェック
        //handel.checkPlanInfo(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
        // 関連自動設定機能実施
        handel.autoSetupInfo(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
		//故障部屋チェック       
        //handel.autoCheckHadBadRoom(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
        // 宴会重複チェック
        handel.checkDuplicateTime(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
        // Indexテーブルデータ自動作成[2012/12/04]
        handel.autoSetupIndexInfo(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
        // 2019/05/31 008.行動からご予約の自動生成機能で、ご予約生成後に行動を変更（日時など）を変えた時にご予約は変更されないようです。by zy BEGIN
        handel.checkEventInfo(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
        // 2019/05/31 008.行動からご予約の自動生成機能で、ご予約生成後に行動を変更（日時など）を変えた時にご予約は変更されないようです。by zy END
    }
    // after insert
    else if(Trigger.isInsert && Trigger.isAfter){
        // 予約情報から関連処理を行う
        LeadTriggerProcess handel = new LeadTriggerProcess();
        //故障部屋チェック[2018/04/05場所移動]   
        handel.autoCheckHadBadRoom(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
		// 2017/05/04 自施設の予約や会計しか変更できないように権限管理機能 BEGIN
		handel.checkShopInfo(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
		// 2017/05/04 自施設の予約や会計しか変更できないように権限管理機能 END
        // プラン情報から見積明細自動作成
        handel.autoSetupBookingItemByPlan(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
        // 予約から会計側へ連携処理を行う
        handel.syncBookingInfoToAccounts(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
        // 在庫更新処理を行う
        // 2013/09/28 在庫統計方式変更に従って、下記ロジックを削除する
        //handel.syncGuestRoomStock(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
        // 予約データを作成するデータの到着日、出発日を変更する場合、自動該当変更時間はLeadIndexへ反映する
        handel.syncLeadInfoToLeadIndex(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
	// 2015/09/27 ADD 
        handel.stockChangeSyncToDb(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
        // 2019/04/15 改善要望：予約から活動の作成 by zy BEGIN
        // 活動のフラグ対応
        handel.createEventInfo(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
        // 2019/04/15 改善要望：予約から活動の作成 by zy END
        // 2019/07/15 項目変更により、自動アラート、通知機能の対応（予約と見積明細のみ連動検知機能を対応する） by zy BEGIN
        CommonNotifacationCtrl.updNoticationSobjectName(trigger.new, Trigger.old, 'Lead__c',CommConst.TriggerMethod.IsInsert,'Id');
        // 2019/07/15 項目変更により、自動アラート、通知機能の対応（予約と見積明細のみ連動検知機能を対応する） by zy END
    }
    // before update
    else if(Trigger.isUpdate && Trigger.isBefore){
        // 部屋から部屋タイプの自動設定()
        LeadTriggerProcess handel = new LeadTriggerProcess();
        // プラン設定チェック
        //handel.checkPlanInfo(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
        // 関連自動設定機能実施
        handel.autoSetupInfo(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
        
        // 2017/05/04 自施設の予約や会計しか変更できないように権限管理機能 BEGIN
        handel.checkShopInfo(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
        // 2017/05/04 自施設の予約や会計しか変更できないように権限管理機能 END  
        //故障部屋チェック[2018/04/05場所移動]      
        //handel.autoCheckHadBadRoom(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
        // 宴会重複チェック
        handel.checkDuplicateTime(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
        // チェックアウトする前、会計済みチェックする
        // 2014/03/24 (BIGUSERリリース後の使う不便するため、該当チェック(checkoutByAcountsInfo)を外す)
        // handel.checkoutByAcountsInfo(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
    }
    // after update
    else if(Trigger.isUpdate && Trigger.isAfter){
        // 予約情報から関連処理を行う
        LeadTriggerProcess handel = new LeadTriggerProcess();
        //故障部屋チェック[2018/04/05場所移動]       
        handel.autoCheckHadBadRoom(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
        // 2020/05/15 到着日を変更した際に紐づいている予約見積明細の利用日も自動変更する機能対応 WSQ BEGIN
        handel.leadInfoSyncEstItems(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
        // 2020/05/15 到着日を変更した際に紐づいている予約見積明細の利用日も自動変更する機能対応 WSQ END
        // プラン情報から見積明細自動作成
        handel.autoSetupBookingItemByPlan(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
        // 予約から会計側へ連携処理を行う
        handel.syncBookingInfoToAccounts(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
        // 予約情報から会計に連携を行う
        handel.syncBookingUpdInfoToAccount(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
        // 在庫更新処理を行う
        // 2013/09/28 在庫統計方式変更に従って、下記ロジックを削除する
        //handel.syncGuestRoomStock(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
        // SF標準画面から予約データを作成するデータの到着日、出発日を変更する場合、自動該当変更時間はLeadIndexへ反映する
        handel.syncLeadInfoToLeadIndex(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
        // 2013/10/11 予約キャンセルと同時に会計もキャンセル(取引種別:VOIDに変更、会計日時はキャンセル連動時間を設定する)
        handel.syncBookingCancelInfoToAccounts(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
    	// 2015/04/08 予約人數は会計に連動処理追加
    	//handel.syncBookingStayPeopleToAccounts(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
    	handel.syncBookingInfoToRelLeadsProc(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
	// 2015/09/27 ADD 
    	handel.stockChangeSyncToDb(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
    	// 2017/06/26 お客様がチェックアウトしたタイミングで音声通知機能 zyz BEGIN
    	handel.notifyMsgByCheckout(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
    	// 2017/06/26 お客様がチェックアウトしたタイミングで音声通知機能 zyz END
        // 2019/04/15 改善要望：予約から活動の作成 by zy BEGIN
        // 活動のフラグ対応
        handel.createEventInfo(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
        // 2019/04/15 改善要望：予約から活動の作成 by zy END
         // 2019/07/15 項目変更により、自動アラート、通知機能の対応（予約と見積明細のみ連動検知機能を対応する） by zy BEGIN
        CommonNotifacationCtrl.updNoticationSobjectName(trigger.new, Trigger.old, 'Lead__c',CommConst.TriggerMethod.IsUpdate,'Id');
        // 2019/07/15 項目変更により、自動アラート、通知機能の対応（予約と見積明細のみ連動検知機能を対応する） by zy END
    }
    // before delete
    else if(Trigger.isDelete && Trigger.isBefore){
    	(new LeadTriggerProcess()).stockChangeSyncToDb(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsDelete);
    }
    // after delete
//    else if(Trigger.isDelete && Trigger.isAfter){}
    // after undelete
    else if(Trigger.isUnDelete){
    	(new LeadTriggerProcess()).stockChangeSyncToDb(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
    }
}