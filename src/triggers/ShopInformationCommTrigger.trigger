/**
* 店舗情報トリガー共通処理
**/
trigger ShopInformationCommTrigger on ShopInformation__c (before insert, after insert) {
	// バッチ処理飛ばす
	if (DataFixManagerUtils.tranTriggerIsStop()) return;

	if(Trigger.isInsert && Trigger.isBefore){
		(new ShopInformationTriggerProcess()).autoSetupShopInfomation(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
	} 

}