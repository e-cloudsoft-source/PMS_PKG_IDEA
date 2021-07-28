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
private class RoomsStatusTriggerProcessTest {

    static testMethod void case001_Ins() {
    	Date s = Date.today();
    	// 部屋タイプ作成
    	TypeOfRooms__c roomType = TestCommon.createTypeOfRoom();
        // 過去の日付の故障部屋のデータを作成する時、在庫情報を連動対処外
        RoomsStatus__c r1 = createOrgStatus(roomType.id,s.addDays(-2),s.addDays(-1));
        Integer rsCnt = [select count() from StockChangeHisotry__c limit 100];
        System.assertEquals(rsCnt,0);
        // 当日分指定の場合、連携を行う
        RoomsStatus__c r2 = createOrgStatus(roomType.id,s.addDays(0),s.addDays(0));
        rsCnt = [select count() from StockChangeHisotry__c limit 100]; 
        System.assertEquals(rsCnt,1);
        // 今日以後の故障部屋データを作成すると、在庫情報連携を行う
        RoomsStatus__c r3 = createOrgStatus(roomType.id,s.addDays(1),s.addDays(2));
        rsCnt = [select count() from StockChangeHisotry__c limit 100]; 
        System.assertEquals(rsCnt,3);
        // 削除処理を行う
        delete [select id from RoomsStatus__c limit 100];
        rsCnt = [select count() from StockChangeHisotry__c limit 100]; 
        System.assertEquals(rsCnt,6);
        // 作成の日付は昨日から３日間
        RoomsStatus__c r4 = createOrgStatus(roomType.id,s.addDays(-1),s.addDays(1));
        rsCnt = [select count() from StockChangeHisotry__c limit 100];
        System.assertEquals(rsCnt,8);
    }
    // 同じ日付けに既存の故障部屋情報が存在する場合、新規登録される故障部屋情報は在庫連携情報を発行しない
    static testMethod void case002_Ins() {
    	// 日付
    	Date s = Date.today();
		// 部屋タイプ作成
    	TypeOfRooms__c roomType = TestCommon.createTypeOfRoom();
    	// 部屋作成
    	Room__c room = TestCommon.createRooms(roomType.Id);
    	// 故障管理データ作成
    	RoomsStatus__c badStatus1 = TestCommon.createBadRoom(room.Id, s.addDays(-1), s.addDays(1));
    	// 新規故障部屋は翌日から翌々日データ作成　
    	Integer rsCnt = [select count() from StockChangeHisotry__c limit 100];
        System.assertEquals(rsCnt,2);
        RoomsStatus__c badStatus2 = TestCommon.createBadRoom(room.Id, s.addDays(1), s.addDays(2));
        rsCnt = [select count() from StockChangeHisotry__c limit 100];
        System.assertEquals(rsCnt,3);
        // 該当bad2削除すると、翌々日の在庫情報のみ追加、翌日の故障部屋まだ存在するため、在庫連携を行わない
        delete badStatus2;
        rsCnt = [select count() from StockChangeHisotry__c limit 100];
        System.assertEquals(rsCnt,4);
        // 全部削除すると、６件になる
        delete badStatus1;
        rsCnt = [select count() from StockChangeHisotry__c limit 100];
        System.assertEquals(rsCnt,6);
    }
 	// 新規の場合、既存の予約情報が存在すろと、登録できない
 	static testMethod void case003_Ins() {
    	// 日付
    	Date s = Date.today();
		// 部屋タイプ作成
    	TypeOfRooms__c roomType = TestCommon.createTypeOfRoom();
    	// 部屋作成
    	Room__c room = TestCommon.createRooms(roomType.Id);
    	// 予約情報を作成する[当日]
    	Lead__c lead =  TestCommon.createLead();
    	lead.Rroom__c = room.id;
    	update lead;
    	// 故障管理データ作成
    	Boolean errFlg = false;
    	try {
    	RoomsStatus__c badStatus1 = TestCommon.createBadRoom(room.Id, s.addDays(-1), s.addDays(1));
    	} catch (Exception e) {
    		errFlg = true;
    	}
    	System.assert(errFlg);
 	}
 	// 故障部屋情報から期間変更により、ご予約情報と競合チェックを行う
 	static testMethod void case004_Upd() {
    	// 日付
    	Date s = Date.today();
		// 部屋タイプ作成
    	TypeOfRooms__c roomType = TestCommon.createTypeOfRoom();
    	// 部屋作成
    	Room__c room = TestCommon.createRooms(roomType.Id);
    	// 予約情報を作成する[当日]
    	Lead__c lead =  TestCommon.createLead();
    	lead.Rroom__c = room.id;
    	update lead;
    	// 故障管理データ作成
    	Boolean errFlg = false;
    	RoomsStatus__c badStatus1 = null;
    	try {
    	badStatus1 = TestCommon.createBadRoom(room.Id, s.addDays(1), s.addDays(1));
    	} catch (Exception e) {
    		errFlg = true;
    	}
    	System.assert(!errFlg);
    	// 期間変更を行う
        // 故障部屋期間は期間に変更を行う[リクエスト発行しない]
        badStatus1.StatusBeginDate__c = s.addDays(0);
        badStatus1.StatusEndDate__c = s.addDays(1);
        try {
        update badStatus1;
    	} catch (Exception e) {
    		errFlg = true;
    	}
    	// ERROR
 		system.assert(errFlg);
 		// 
 		errFlg = false;
        // 故障部屋期間は期間に変更を行う[リクエスト発行しない]
        badStatus1.StatusBeginDate__c = s.addDays(-1);
        badStatus1.StatusEndDate__c = s.addDays(0);
        try {
        update badStatus1;
    	} catch (Exception e) {
    		errFlg = true;
    	}
    	// ERROR
 		system.assert(errFlg);
 		errFlg = false;
        // 故障部屋期間は期間に変更を行う[リクエスト発行しない]
        badStatus1.StatusBeginDate__c = s.addDays(-1);
        badStatus1.StatusEndDate__c = s.addDays(2);
        try {
        update badStatus1;
    	} catch (Exception e) {
    		errFlg = true;
    	}
    	// ERROR
 		system.assert(errFlg);
 	}
 	
 	static testMethod void case001_Upd() {
    	// 日付
    	Date s = Date.today();
		// 部屋タイプ作成
    	TypeOfRooms__c roomType = TestCommon.createTypeOfRoom();
    	// 部屋作成
    	Room__c room = TestCommon.createRooms(roomType.Id);
    	// 故障管理データ作成
    	RoomsStatus__c badStatus1 = TestCommon.createBadRoom(room.Id, s.addDays(-1), s.addDays(1));
    	// 新規故障部屋は前日から翌日データ作成　
    	Integer rsCnt = [select count() from StockChangeHisotry__c where StockChangeCnt__c = -1 limit 100];
        System.assertEquals(rsCnt,2);
        // 期間変換を行う「TODAYー＞３日後」
        badStatus1.StatusBeginDate__c = s;
        badStatus1.StatusEndDate__c = s.addDays(3);
        update badStatus1;
        // 1件在庫連携情報を作成する
        rsCnt = [select count() from StockChangeHisotry__c limit 100];
        System.assertEquals(rsCnt,4);
        // 故障部屋期間は期間に変更を行う[リクエスト発行しない]
        badStatus1.StatusBeginDate__c = s.addDays(1);
        badStatus1.StatusEndDate__c = s.addDays(2);
        update badStatus1;
        rsCnt = [select count() from StockChangeHisotry__c where StockChangeCnt__c = -1 limit 100];
        System.assertEquals(rsCnt,4);
        rsCnt = [select count() from StockChangeHisotry__c where StockChangeCnt__c = 1 limit 100];
        System.assertEquals(rsCnt,2);
        // 期間は拡大になる
        badStatus1.StatusBeginDate__c = s.addDays(0);
        badStatus1.StatusEndDate__c = s.addDays(3);
        update badStatus1;
        rsCnt = [select count() from StockChangeHisotry__c where StockChangeCnt__c = -1 limit 100];
        System.assertEquals(rsCnt,6);
        rsCnt = [select count() from StockChangeHisotry__c where StockChangeCnt__c = 1 limit 100];
        System.assertEquals(rsCnt,2);
        // 期間は過去の日付に変更を行う
        badStatus1.StatusBeginDate__c = s.addDays(-1);
        badStatus1.StatusEndDate__c = s.addDays(2);
        update badStatus1;
        rsCnt = [select count() from StockChangeHisotry__c where StockChangeCnt__c = -1 limit 100];
        System.assertEquals(rsCnt,6);
        rsCnt = [select count() from StockChangeHisotry__c where StockChangeCnt__c = 1 limit 100];
        System.assertEquals(rsCnt,3);
        // 期間は未来の日付に変更を行う
        badStatus1.StatusBeginDate__c = s.addDays(1);
        badStatus1.StatusEndDate__c = s.addDays(4);
        update badStatus1; 
        rsCnt = [select count() from StockChangeHisotry__c where StockChangeCnt__c = -1 limit 100];
        System.assertEquals(rsCnt,8);
        rsCnt = [select count() from StockChangeHisotry__c where StockChangeCnt__c = 1 limit 100];
        System.assertEquals(rsCnt,4);
 	}
	// 変更、ステータス、処理結果変更のチェック
 	static testMethod void case002_Upd() {
    	// 日付
    	Date s = Date.today();
		// 部屋タイプ作成
    	TypeOfRooms__c roomType = TestCommon.createTypeOfRoom();
    	// 部屋作成
    	Room__c room = TestCommon.createRooms(roomType.Id);
    	// 故障管理データ作成
    	RoomsStatus__c badStatus1 = TestCommon.createBadRoom(room.Id, s.addDays(-1), s.addDays(1));
    	// 新規故障部屋は前日から翌日データ作成　
    	Integer rsCnt = [select count() from StockChangeHisotry__c where StockChangeCnt__c = -1 limit 100];
        System.assertEquals(rsCnt,2);
        // ステータスを変更する　
        badStatus1.Status__c = '清掃';
        update badStatus1;
        // 在庫情報は戻る
    	rsCnt = [select count() from StockChangeHisotry__c where StockChangeCnt__c = 1 limit 100];
        System.assertEquals(rsCnt,2);
        // 清掃から故障部屋に変更
        badStatus1.Status__c = CommConst.ROOM_ST_TYPE_BED;
        update badStatus1;
    	rsCnt = [select count() from StockChangeHisotry__c where StockChangeCnt__c = -1 limit 100];
        System.assertEquals(rsCnt,4);
        // 処理結果は済みへ変更
        badStatus1.Result__c = '修理中';
        update badStatus1;
    	rsCnt = [select count() from StockChangeHisotry__c where StockChangeCnt__c = -1 limit 100];
        System.assertEquals(rsCnt,4);
    	rsCnt = [select count() from StockChangeHisotry__c where StockChangeCnt__c = 1 limit 100];
        System.assertEquals(rsCnt,2); 
        // 処理結果は済みへ変更
        badStatus1.Result__c = CommConst.ROOM_ST_TYPE_BED_FIN;
        update badStatus1;
        // 在庫情報は戻る
    	rsCnt = [select count() from StockChangeHisotry__c where StockChangeCnt__c = 1 limit 100];
        System.assertEquals(rsCnt,4); 
        // 処理結果は済みから再開
        badStatus1.Result__c = null;
        update badStatus1;
    	rsCnt = [select count() from StockChangeHisotry__c where StockChangeCnt__c = -1 limit 100];
        System.assertEquals(rsCnt,6);
        // 情報変更なし、NAMEのみ変更の場合、変換なし
        badStatus1.Name = 'UPD';
        update badStatus1;
    	rsCnt = [select count() from StockChangeHisotry__c where StockChangeCnt__c = -1 limit 100];
        System.assertEquals(rsCnt,6);  
    	rsCnt = [select count() from StockChangeHisotry__c where StockChangeCnt__c = 1 limit 100];
        System.assertEquals(rsCnt,4); 
 	}
 	static testMethod void case001_Undelete() {
    	// 日付
    	Date s = Date.today();
		// 部屋タイプ作成
    	TypeOfRooms__c roomType = TestCommon.createTypeOfRoom();
    	// 部屋作成
    	Room__c room = TestCommon.createRooms(roomType.Id);
    	// 故障管理データ作成
    	RoomsStatus__c badStatus1 = TestCommon.createBadRoom(room.Id, s.addDays(-1), s.addDays(1));
    	// 新規故障部屋は前日から翌日データ作成　
    	Integer rsCnt = [select count() from StockChangeHisotry__c where StockChangeCnt__c = -1 limit 100];
        System.assertEquals(rsCnt,2);
        // 削除
        delete badStatus1;
		rsCnt = [select count() from StockChangeHisotry__c where StockChangeCnt__c = -1 limit 100];
        System.assertEquals(rsCnt,2);
		rsCnt = [select count() from StockChangeHisotry__c where StockChangeCnt__c = 1 limit 100];
        System.assertEquals(rsCnt,2);
        // UNDELETE
        database.undelete(badStatus1);
		rsCnt = [select count() from StockChangeHisotry__c where StockChangeCnt__c = -1 limit 100];
        System.assertEquals(rsCnt,4);
 	}

	// 変更、ステータス、処理結果変更のチェック
 	static testMethod void case003_Upd() {
     	// 日付
    	Date s = Date.today();
		// 部屋タイプ作成
    	TypeOfRooms__c roomType = TestCommon.createTypeOfRoom();
    	// 部屋作成
    	Room__c room = TestCommon.createRooms(roomType.Id);
    	
		RoomsStatus__c status = new RoomsStatus__c(
			RoomRef__c = room.Id,
			Status__c = '故障',
			StatusBeginDate__c = s,
			StatusEndDate__c = s.addDays(1),
			IsStockSyncTarget__c = false
		);
		insert status;
		// 連携対象外、在庫連携情報を作成しない　
    	Integer rsCnt = [select count() from StockChangeHisotry__c where StockChangeCnt__c = -1 limit 100];
        System.assertEquals(rsCnt,0);
        // 変更する
        status.StatusBeginDate__c = s.addDays(1);
		status.StatusBeginDate__c = s.addDays(2);
		try{
			update status;
		}catch(exception e){}
		rsCnt = [select count() from StockChangeHisotry__c where StockChangeCnt__c = -1 limit 100];
        System.assertEquals(rsCnt,0);
		// 削除
		delete status;
		rsCnt = [select count() from StockChangeHisotry__c where StockChangeCnt__c = -1 limit 100];
        System.assertEquals(rsCnt,0);
 	}
    //
    static RoomsStatus__c createOrgStatus(Id roomTypeId, Date startDt, Date endDate) {

    	// 部屋作成
    	Room__c room = TestCommon.createRooms(roomTypeId);
    	// 故障管理データ作成
    	RoomsStatus__c badStatus = TestCommon.createBadRoom(room.Id, startDt, endDate);
    	
    	return badStatus;
    }
}