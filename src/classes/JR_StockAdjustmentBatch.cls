/**
* バッチ:在庫調整対象情報
* INIT:初期化する
**/
public with sharing class JR_StockAdjustmentBatch implements Schedulable {
	// スケジュールで該当Methodを呼び出する
	public JR_StockAdjustmentBatch(){}
	// ***********************************
	// スケジュール処理開始
	// ***********************************
	public void execute(SchedulableContext SC) {
		// 管理データを作成する
		BI_JR_ServiceConfigHelp.insUpdStockLockData();
		// 該当バッチは処理中止するがどうかチェック
		if (BI_JR_ServiceConfigHelp.isStockBatchStopCheck()) {
			System.abortJob(SC.getTriggerId());
			return;
		}
		// 処理対象確認する
		list<TypeOfRooms__c> roomtypes = [Select id,ShopInfoRef__r.ShopCode__c,RoomTypeCode__c from TypeOfRooms__c where SumNotApplicableFlg__c != TRUE and RoomTypeCode__c != null order by ShopInfoRef__c];
		//for (TypeOfRooms__c roomtype : roomtypes) targetIds.add(roomtype.Id);
		list<Id> targetIds = filterRoomTypes(roomtypes);
		// バッチ実施開始の情報をInsertする
		JR_StockAdjustmentBatchExtend batch = new JR_StockAdjustmentBatchExtend(targetIds);
		Id batchJobId = DataBase.executeBatch(batch,BI_JR_ServiceConfigHelp.SYNC_RANGE_DAYS);
		// スケジュールABORTする　
		System.abortJob(SC.getTriggerId());
	}
	// 連携対象外店舗の部屋タイプの場合、連携対象から外す対応
	private list<Id> filterRoomTypes(list<TypeOfRooms__c> roomtypes) {
        // 処理開始
        list<Id> targetIds = new list<Id>();
        // 店舗別部屋タイプリスト情報を格納する
        map<string,list<TypeOfRooms__c>> roomTypeOfShopMap = new map<string, list<TypeOfRooms__c>>();
        for (TypeOfRooms__c rmtype : roomtypes) {
            // 該当部屋タイプのプラングループ関連の残室数を取得する[店舗コード情報]
            String shopCode = CommUtils.nullToBlank(rmtype.ShopInfoRef__r.ShopCode__c);
            // 部屋タイプコード
            String roomTypeCd = CommUtils.nullToBlank(rmtype.RoomTypeCode__c);
            // ***********************************************
            // 該当店舗情報の接続定義はXMLに未定義する場合、処理対象外
            // ***********************************************
            if (!BI_JR_ServiceConfigHelp.isContractShop(shopCode)) {
                // 連携対象外店舗設定されている
                system.debug(logginglevel.info,'店舗コード['+shopCode+']はXMLに定義されていないため、部屋タイプ['+roomTypeCd+']連携不要対象になる.');
                continue;
            }
            // 該当店舗の連携対象です
            if (!roomTypeOfShopMap.containsKey(shopCode)) roomTypeOfShopMap.put(shopCode, new list<TypeOfRooms__c>());
            roomTypeOfShopMap.get(shopCode).add(rmtype);
        }
        if (roomTypeOfShopMap.isEmpty()) return targetIds;
        for (list<TypeOfRooms__c> typerooms : roomTypeOfShopMap.values()) {
        	for (TypeOfRooms__c roomtype : typerooms) targetIds.add(roomtype.Id);
        }
        return targetIds;
    }
}