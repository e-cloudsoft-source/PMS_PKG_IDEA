/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class StockChangeHisotryTriggerProcessTest {

	// TLからキャンセルデータを作成する、そして、論理連携情報が存在する場合、該当論理連携データは「未連携」に変更される
    static testMethod void Case001() {
        // TO DO: implement unit test
        CommDefine__c def = TestCommon.createCommDefine();
        def.StockDataCreateFlg__c = true;
        update def;
        // 部屋タイプ
        TypeOfRooms__c roomType1 = TestCommon.createTypeOfRoom();
        TypeOfRooms__c roomType2 = TestCommon.createTypeOfRoom();
        // 論理連携結果を作成する
        Date targetDt = Date.today();
        // 当日の論理連携済
        StockChangeHisotry__c stock1 = createStockHisotry(
        					TL_StockAdjustmentBatch.STOCK_STATUS_LOGIC_SYNCOK,
        					-1,
        					CommConst.BI_PROCESS_TYPE.SFDC.Name()+'1',
        					targetDt,
        					roomType1.Id, true);
       	// 前日の論理連携済
        StockChangeHisotry__c stock2 = createStockHisotry(
        					TL_StockAdjustmentBatch.STOCK_STATUS_LOGIC_SYNCOK,
        					-1,
        					CommConst.BI_PROCESS_TYPE.SFDC.Name()+'2',
        					targetDt.addDays(-1),
        					roomType1.Id, true);
        // 部屋タイプは違う
        StockChangeHisotry__c stock3 = createStockHisotry(
        					TL_StockAdjustmentBatch.STOCK_STATUS_LOGIC_SYNCOK,
        					-1,
        					CommConst.BI_PROCESS_TYPE.SFDC.Name()+'3',
        					targetDt,
        					roomType2.Id, true);
        // 日付は違う
        StockChangeHisotry__c stock4 = createStockHisotry(
        					TL_StockAdjustmentBatch.STOCK_STATUS_LOGIC_SYNCOK,
        					-1,
        					CommConst.BI_PROCESS_TYPE.SFDC.Name()+'4',
        					targetDt.addDays(1),
        					roomType1.Id, true);

        List<StockChangeHisotry__c> canInsLst = new List<StockChangeHisotry__c>();					     					      					
        StockChangeHisotry__c tlCancelStock1= createStockHisotry(
        					TL_StockAdjustmentBatch.STOCK_STATUS_NOSYNC,
        					1,
        					CommConst.BI_PROCESS_TYPE.TL.Name(),
        					targetDt,
        					roomType1.Id,
        					false);   
	
        StockChangeHisotry__c tlCancelStock2 = createStockHisotry(
        					TL_StockAdjustmentBatch.STOCK_STATUS_NOSYNC,
        					1,
        					CommConst.BI_PROCESS_TYPE.TL.Name(),
        					targetDt,
        					roomType1.Id,
        					false);   
        					
        StockChangeHisotry__c tlCancelStock3 = createStockHisotry(
        					TL_StockAdjustmentBatch.STOCK_STATUS_NOSYNC,
        					1,
        					CommConst.BI_PROCESS_TYPE.TL.Name(),
        					targetDt.addDays(1),
        					roomType2.Id,
        					false);    
     	canInsLst.add(tlCancelStock1);				
        canInsLst.add(tlCancelStock2);
        canInsLst.add(tlCancelStock3);
        insert canInsLst;
        list<StockChangeHisotry__c> rsLst = [select id,CreateSource__c,StockChangeDate__c,StatusLst__c from StockChangeHisotry__c 
        	where StatusLst__c = :TL_StockAdjustmentBatch.STOCK_STATUS_NOSYNC
        	And CreateSource__c != :CommConst.BI_PROCESS_TYPE.TL.Name()
        	];
   		System.assertEquals(rsLst.size(),1, rsLst);
    }
    
    private static StockChangeHisotry__c createStockHisotry(String status, Decimal stockNum, String eventSource, Date targetDt, Id roomTypeId, Boolean isInsert) {
    	StockChangeHisotry__c newItem = new StockChangeHisotry__c(
    		StatusLst__c = status,
    		StockChangeCnt__c = stockNum,
    		CreateSource__c = eventSource,
    		StockChangeDate__c = targetDt,
    		TypeOfRoomRef__c = roomTypeId
    	);
    	if (isInsert) {
    	insert newItem;
    	}
    	return newItem;
    }
    
    /**
    * StockChangeHisotryDataFixBatch テストMethod呼び出し
    */
     static testMethod void StockBatchUnit001() {
		// TO DO: implement unit test
		// 店舗情報作成
		ShopInformation__c sp = TestCommon.createShopInfo();
		// 部屋タイプ情報作成
		TypeOfRooms__c typeRoom = TestCommon.createTypeOfRoom();
		typeRoom.ShopInfoRef__c = sp.Id;
		update typeRoom;
		// 部屋情報作成
		Room__c room = TestCommon.createRooms();
		room.ShopInfoRef__c = sp.Id;
		room.TypeRoomRef__c = typeRoom.Id;
		update room;
		Date startDt = system.today();
		Date endDt = startDt;
		String gShopCode = sp.shopcode__c;
		RoomsStatus__c roomStatus = new RoomsStatus__c( Name = 'test001', RoomRef__c = room.id, 
                                                                                StatusBeginDate__c = startDt,
                                                                                StatusEndDate__c = endDt,
																				Status__c = CommConst.ROOM_ST_TYPE_BED);
		insert roomStatus;
		
        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
		(new DataFixManagerUtils()).init();
        // その後、バッチ実施する
        Test.startTest();
        StockChangeHisotryDataFixBatch m = new StockChangeHisotryDataFixBatch();
		String sch = getScheduleTime();
		System.schedule('AAAA', sch, m);
		StockChangeHisotry__c stock = new StockChangeHisotry__c(StockChangeDate__c = system.today());
		insert stock;
		stock.StockChangeDateKey__c = null;
		stock.LeadRef__c = leadInfo.id;
		update stock;
		delete leadInfo;
		system.debug(logginglevel.info,'1::::' + [Select Id,StockChangeDateKey__c,StockChangeDate__c from StockChangeHisotry__c]);
		StockChangeHisotryDataFixBatch batch = new StockChangeHisotryDataFixBatch(UserInfo.getuserid());
		DataBase.executeBatch(batch, 1);
        Test.stopTest();
        System.assert(DataFixManagerUtils.getInstance().StockChangeHisotryFixed__c,DataFixManagerUtils.getInstance());
    }
    
     static testMethod void LeadFixBatchUnit001() {
        // TO DO: implement unit test
        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
        (new DataFixManagerUtils()).init();
        // その後、バッチ実施する
        Test.startTest();
        DataFixBatchForLead m = new DataFixBatchForLead();
		String sch = getScheduleTime();
    	System.schedule('AAAA', sch, m);
		leadInfo.EntryTime__c = system.now().addDays(-30);
		leadInfo.Departure__c = system.now().addDays(-29);
		leadinfo.EntryDateKey__c = null;
        leadinfo.EntryDateIntKey__c = null;
		DataFixManagerUtils.stopTranTriggger();
		update leadInfo;
		DataFixManagerUtils.begTranTriggger();
		System.assert((new List<Lead__c>([select id from lead__c where EntryDateKey__c = null and CancelBool__c != 1 and DAY_ONLY(convertTimezone(EntryTime__c)) >= LAST_N_DAYS:36])).size() == 1,true);
		DataFixManagerUtils dtUtils = new DataFixManagerUtils();
		dtUtils.updLeadKeyFixed(false);
		DataFixBatchForLead batch = new DataFixBatchForLead(UserInfo.getuserid());
		DataBase.executeBatch(batch);
        Test.stopTest();
        System.assert(DataFixManagerUtils.getInstance().LeadFixed__c,DataFixManagerUtils.getInstance());
    }
    // 部屋ステータス設定処理機能対応
     static testMethod void DataFixBatchForRoomsStatusUnit001() {
        // TO DO: implement unit test
        
        DataFixManagerUtils.stopTranTriggger();
    	// 日付
    	Date s = Date.today();
		// 部屋タイプ作成
    	TypeOfRooms__c roomType = TestCommon.createTypeOfRoom();
    	// 部屋作成
    	Room__c room = TestCommon.createRooms(roomType.Id);
    	// 故障管理データ作成
    	RoomsStatus__c badStatus1 = TestCommon.createBadRoom(room.Id, s.addDays(-1), s.addDays(1));
    	
        (new DataFixManagerUtils()).init();
        // その後、バッチ実施する
        Test.startTest();
        DataFixBatchForRoomsStatus m = new DataFixBatchForRoomsStatus();
		String sch = getScheduleTime();
    	System.schedule('AAAA', sch, m);

		DataFixBatchForRoomsStatus batch = new DataFixBatchForRoomsStatus(UserInfo.getuserid());
		DataBase.executeBatch(batch);
        Test.stopTest();
        DataFixManagerUtils.begTranTriggger();
        System.assert(DataFixManagerUtils.getInstance().RoomsStatusFixed__c,DataFixManagerUtils.getInstance());

    }
    
	private static String getScheduleTime() {
    	DateTime nowTime = DateTime.now().addSeconds(10);
		// 起動ＣＲＯＮを設定する
		String timeStr = nowTime.format('yyyyMMddHHmmss');
		String yy = timeStr.substring(0,4);
		String mm = timeStr.substring(4,6);
		String dd = timeStr.substring(6,8);
		String hh = timeStr.substring(8,10);
		String ms = timeStr.substring(10,12);
		String ss = timeStr.substring(12,14);
		String sch = ss + ' ' +
		       ms + ' ' +
		       hh + ' ' +
		       dd + ' ' +
		       mm + ' ' +
		       ' ? ' + yy;
		return sch;
    }
}