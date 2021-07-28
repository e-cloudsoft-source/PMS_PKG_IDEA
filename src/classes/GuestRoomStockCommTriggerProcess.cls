public with sharing class GuestRoomStockCommTriggerProcess {
	// 自動在庫変更履歴新規
    public void autoSyncStockChange (GuestRoomStock__c[] newList, GuestRoomStock__c[] oldList, CommConst.TriggerMethod action){
    	// 2019/09/15 Security Check BY zyz BEGIN
    	List<String> chkFieldsLst = new List<String>{'typeofroomref__c','stockchangedate__c','stockchangecnt__c','settingflg__c','salesstatus_del__c'};
    	Map<String,Schema.SObjectField> mm = Schema.SObjectType.StockChangeHisotry__c.fields.getMap();
    	if (!CommSecurityUtils.isCanCreateable(chkFieldsLst, mm)) {
    		return ;
    	}
    	// 2019/09/15 Security Check BY zyz END
    	List<StockChangeHisotry__c> stockChgHisLst = new List<StockChangeHisotry__c>();
    	for (integer i = 0 ; i < newList.size() ; i++) {
    		GuestRoomStock__c item = newList[i];
    		// 手動の場合
    		if (!item.SettingFlg__c) continue;
			StockChangeHisotry__c stock = new StockChangeHisotry__c();
			stock.SettingFlg__c = item.SettingFlg__c;
			stock.StockChangeDate__c = item.StockDate__c;
			stock.TypeOfRoomRef__c = item.RoomTypeRef__c; 
			stock.SalesStatus_del__c = item.SalesStatusLst__c;
			stock.StockChangeCnt__c = CommUtils.nullToZero(item.QtyOfStock__c);
			stockChgHisLst.add(stock);
			// 処理終わり
			item.SettingFlg__c = false;
    	}
    	if (!stockChgHisLst.isEmpty()) insert stockChgHisLst;
    }
}