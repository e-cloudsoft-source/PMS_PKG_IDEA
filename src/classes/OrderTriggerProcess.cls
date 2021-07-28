/**
* 注文共通トリガー
* 既存注文に対して、キャンセルされる場合、EXPO在庫とNOEXPO在庫連動を行う
**/
public with sharing class OrderTriggerProcess {
	// 変更のみ対応する
	//private static final String ORDER_STATUS_CANCEL = 'キャンセル';
	// 既存注文に対して、キャンセルされる場合、EXPO在庫とNOEXPO在庫連動を行う
    public void setStockInfo(List<Order__c> nw, List<Order__c> od, CommConst.TriggerMethod act) {
		// 在庫管理機能は無効の場合、連動処理中止
		if(!CommConst.STOCKSYNC_ISACTIVE_FLG) return;
		// 注文ID
		set<id> orderIds = new set<Id>();
		// 注文更新場合
		if (act == CommConst.TriggerMethod.IsUpdate) {
			for(Integer i = 0; i < nw.size(); i++){
				Order__c nwItem = nw[i];
				Order__c odItem = od[i];
				// 子注文の場合、処理SKIP
				if (!CommUtils.isBlank(nwItem.RefParOrder__c)) continue;
				// 注文のステータスはキャンセル以外からキャンセルに変更される場合
				if(	nwItem.OrderStatus__c == CommConst.ORDER_STATUS_CANCEL && 
					odItem.OrderStatus__c != CommConst.ORDER_STATUS_CANCEL) {
					// 関連の子注文情報の在庫を返品する
					orderIds.add(nwItem.Id);
				// 以外の場合、処理SKIP
				} else continue;
			}
		}
		// 対象注文が非存在場合、処理SKIP
		if (orderIds.isEmpty()) return;
		// 注文明細から在庫処理を行う
		list<OrderItem__c> targetLst = [select id, ExpoOrgInfoRefCal__c, AccountMasterRef__c, OrderDateCal__c, Qty__c from OrderItem__c where RefParOrder__c in :orderIds];
		for (OrderItem__c item : targetLst) {
			// 減算設定する
			item.Qty__c = CommUtils.nullToBlank(-CommUtils.nullToZero(item.Qty__c));
		}
//System.debug(loggingLevel.info, 'targetLst='+targetLst);
		// 注文明細の処理により、在庫連動処理を行う
		OrderItemTriggerProcess subHandle = new OrderItemTriggerProcess();
		subHandle.setStockInfo(targetLst, null, CommConst.TriggerMethod.IsInsert);
	}
	// 2018/12/10 EXPO注文ステータスを変更場合、関連情報はAWSへ通知を行う WSQ BEGIN
	// 会計商品新規・更新場合、該当商品情報をAWSへ送信を行う
	public void callInfoToAwsProcess(List<Order__c> newLst, List<Order__c> oldLst, CommConst.TriggerMethod act){
		if (act != CommConst.TriggerMethod.isUpdate) return;
		List<Id> targetIds = new list<Id>();
		Integer len = newLst.size();
		for (Integer i = 0; i < len; i++) {
			Order__c nw =  newLst[i];
			Order__c od =  oldLst[i];
			// APIから呼び出し場合、CALL処理を行わない
			if (nw.ExpoApiCancelFlg__c != od.ExpoApiCancelFlg__c) continue;
			// 注文ステータス変更場合【親とSUB両方とも】
			if (nw.OrderStatus__c != od.OrderStatus__c ) targetIds.add(nw.Id);
		}
		if (!targetIds.isEmpty()) WS_ExpoEngineService.syncSfOrderInfoToAws(targetIds);
	}
	
	// 更新処理の事前チェック
	public void updBeforeCheck(List<Order__c> newLst, List<Order__c> oldLst, CommConst.TriggerMethod act){
		Integer len = newLst.size();
		for (Integer i = 0; i < len; i++) {
			Order__c nw =  newLst[i];
			Order__c od =  oldLst[i];
			// API以外からキャンセル　かつ　注文ステータスはキャンセルされる場合、エラーで戻る
			if (nw.ExpoApiCancelFlg__c == od.ExpoApiCancelFlg__c ) {
				// 注文はキャンセル復活
				if (nw.OrderStatus__c == CommConst.ORDER_STATUS_CANCEL && od.OrderStatus__c != CommConst.ORDER_STATUS_CANCEL) {
					nw.addError('注文をキャンセルできません。');
				} else if (nw.OrderStatus__c != CommConst.ORDER_STATUS_CANCEL && od.OrderStatus__c == CommConst.ORDER_STATUS_CANCEL) {
					nw.addError('注文を復活できません。');
				}
			}
		}
	}
	// 2018/12/10 EXPO注文ステータスを変更場合、関連情報はAWSへ通知を行う WSQ END
}