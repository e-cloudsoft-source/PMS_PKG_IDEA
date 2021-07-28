/**
* 在庫変更履歴共通トリガー処理
**/
trigger StockChangeHisotryCommTrigger on StockChangeHisotry__c (before insert, after insert) {
	// 2018/06/04 検索日付の検索キー自動設定対応 WSQ BEGIN
	if(Trigger.isInsert && Trigger.isBefore){
		(new StockChangeHisotryTriggerProcess()).autoSetupValue(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
	}
	// 2018/06/04 検索日付の検索キー自動設定対応 WSQ END
	if(Trigger.isInsert && Trigger.isAfter){
		// TL側からキャンセルして、在庫＋１を明細を作成する場合、関連の「論理連携済」情報が存在すると、該当「論理連携済」データは「未連携」に変更を行う
		(new StockChangeHisotryTriggerProcess()).tlMeragerLogicStockInfo(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
		// 在庫通知機能対応
		(new StockChangeHisotryTriggerProcess()).calStockInfoByChangeHis(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
	}
}