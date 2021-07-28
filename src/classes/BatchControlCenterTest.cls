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
private class BatchControlCenterTest {

   static testMethod void myUnitTest() {
        // TO DO: implement unit test
        TestCommon.createCommDefine();
        createConfigDoc() ;
        createConfigDoc2();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'AccountingSyncBatchConfig'].size(), 1);
        // 2015/12/01 Assert END
        BatchControlCenter batch = new BatchControlCenter();

        batch.currentBatchName = 'BulkProcessPurchaseManagentBatch';
        batch.startBatch();
        batch.refreshBranShop();
        batch.stopBatch();
        batch.currentBatchName = 'BulkProcessPCABatch';
        batch.startBatch();
        batch.stopBatch();
    }
    // FROM/TOなし
	static testMethod void myUnitTest2() {
        // TO DO: implement unit test
        TestCommon.createCommDefine();
        createConfigDoc();
        createConfigDoc2();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'AccountingSyncBatchConfig'].size(), 1);
        // 2015/12/01 Assert END
        BatchControlCenter batch = new BatchControlCenter();
        Test.StartTest();
        batch.currentBatchName = 'ChargeBatch';
        batch.startBatch();
        batch.refreshBranShop();
        batch.currentBatchName = 'FREEEBatch';
        batch.startBatch();
        batch.currentBatchName = 'SalesBatch';
        batch.startBatch();
        batch.currentBatchName = 'PCABatch';
        batch.startBatch();
        batch.currentBatchName = 'FREEEBatch';
        batch.startBatch();
        batch.currentBatchName = 'KanBatch';
        batch.startBatch();
        Test.StopTest();  
	}
	// FROM/TOあり
	static testMethod void myUnitTest3() {
        // TO DO: implement unit test
        TestCommon.createCommDefine();
        createConfigDoc();
        createConfigDoc3();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'AccountingSyncBatchConfig'].size(), 1);
        // 2015/12/01 Assert END
        BatchControlCenter batch = new BatchControlCenter();
        Test.StartTest();
        batch.currentBatchName = 'PosBatch';
        batch.currentBatchTo.checkinDay__c = null;
        batch.startBatch();
        batch.currentBatchTo.checkinDay__c =Date.today();
        batch.startBatch();
        batch.refreshBranShop();
        //batch.stopBatch();
        batch.currentBatchName = 'SalesBatch';
        batch.startBatch();
        //batch.stopBatch();
        batch.currentBatchName = 'ChargeBatch';
        batch.startBatch();
        //batch.stopBatch();
        batch.currentBatchName = 'PCABatch';
        batch.startBatch();
        //batch.stopBatch();
        batch.currentBatchName = 'FREEEBatch';
		batch.currentBatch.checkinDay__c = Date.today().addDays(-32); 
		batch.currentBatchTo.checkinDay__c = Date.today();
        batch.startBatch();
        batch.currentBatch.checkinDay__c = Date.today().addDays(-30); 
        batch.startBatch();
        //batch.stopBatch();
        batch.currentBatchName = 'KanBatch';
        batch.startBatch();
        Test.StopTest();
    }
	// FROM/TOあり
	static testMethod void myUnitTest4() {
        // TO DO: implement unit test
        TestCommon.createCommDefine();
        createConfigDoc();
        createConfigDoc4();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'AccountingSyncBatchConfig'].size(), 1);
        // 2015/12/01 Assert END
        BatchControlCenter batch = new BatchControlCenter();
        Test.StartTest();
        batch.currentBatchName = 'ChargeBatch';
        //batch.startBatch();
        //batch.currentBatchName = 'FREEEBatch';
        //batch.startBatch();
		String firstJobName = 'FREEEBatch';
		String gShopCode = '02';
		Date gSaleDate = Date.today(); 
		Date gSaleEndDate = gSaleDate;
		List<String> gNextJobs = new List<String>();
		BatchControlCenter.startNextBatch(firstJobName, gShopCode, gSaleDate, gSaleEndDate, BatchControlCenter.getNextJobs(gNextJobs) ,null);
        Test.StopTest();
	}
    // FROM/TOあり
    static testMethod void myUnitTest5() {
        // TO DO: implement unit test
        TestCommon.createCommDefine();
        createConfigDoc();
        createConfigDoc5();
        System.assertEquals([select Id from Document where Name = 'AccountingSyncBatchConfig'].size(), 1);
        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfo, productLst[0]);
        // 予約情報のステータス：チェックインに変更する
        leadInfo.Field298__c = 'チェックイン完';
        update leadInfo;
        
        BatchControlCenter batch = new BatchControlCenter();
        Test.StartTest();
        batch.currentBatchName = 'FROMTOBATCH';
        batch.currentBatch.checkinDay__c = Date.today().addDays(-30); 
        batch.currentBatchTo.checkinDay__c = Date.today();
        batch.startBatch();
        Test.StopTest();
    }
    // FROM/TOあり
    static testMethod void myUnitTest6() {
        // TO DO: implement unit test
        TestCommon.createCommDefine();
        createConfigDoc();
        createConfigDoc6();
        System.assertEquals([select Id from Document where Name = 'BatchRequstConfigXml'].size(), 1);
        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfo, productLst[0]);
        // 予約情報のステータス：チェックインに変更する
        leadInfo.Field298__c = 'チェックイン完';
        update leadInfo;
        
        BatchControlCenter batch = new BatchControlCenter();
        Test.StartTest();
        batch.currentBatchName = 'BillPdfBatch';
        batch.refreshBranShop();
        Map<String,object> resultMap = new Map<String,object>{
        	'spcd' => '',
        	'queryDt' => system.today().format(),
        	'endDtStr' => system.today().format(),
        	'saleDt' => system.today().format()
        };
        BatchControlCenter.remoteQuery('queryLead',JSON.serialize(resultMap));
        //BatchControlCenter.remoteQuery('batchExcute');
        //BatchControlCenter.remoteQuery('queryExitLead');
        Test.StopTest();
    }
    static testMethod void myUnitTest6_1() {
        // TO DO: implement unit test
        TestCommon.createCommDefine();
        createConfigDoc();
        createConfigDoc6();
        System.assertEquals([select Id from Document where Name = 'BatchRequstConfigXml'].size(), 1);
        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfo, productLst[0]);
        // 予約情報のステータス：チェックインに変更する
        leadInfo.Field298__c = 'チェックイン完';
        update leadInfo;
        
        BatchControlCenter batch = new BatchControlCenter();
        Test.StartTest();
        batch.currentBatchName = 'BillPdfBatch';
        batch.refreshBranShop();
        Map<String,object> resultMap = new Map<String,object>{
        	'spcd' => '',
        	'queryDt' => system.today().format(),
        	'endDtStr' => system.today().format(),
        	'saleDt' => system.today().format()
			,'accountids' => new List<String>()
			,'leads' => new LIst<String>()
        };
        BatchControlCenter.remoteQuery('batchExcute',JSON.serialize(resultMap));
        //BatchControlCenter.remoteQuery('batchExcute');
        //BatchControlCenter.remoteQuery('queryExitLead');
        Test.StopTest();
    }
    static testMethod void myUnitTest6_2() {
        // TO DO: implement unit test
        TestCommon.createCommDefine();
        createConfigDoc();
        createConfigDoc6();
        System.assertEquals([select Id from Document where Name = 'BatchRequstConfigXml'].size(), 1);
        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfo, productLst[0]);
        // 予約情報のステータス：チェックインに変更する
        leadInfo.Field298__c = 'チェックイン完';
        update leadInfo;
        
        BatchControlCenter batch = new BatchControlCenter();
        Test.StartTest();
        batch.currentBatchName = 'BillPdfBatch';
        batch.refreshBranShop();
        Map<String,object> resultMap = new Map<String,object>{
        	'spcd' => '',
        	'queryDt' => system.today().format(),
        	'endDtStr' => system.today().format(),
        	'saleDt' => system.today().format()
			,'accountids' => new List<String>()
        };
        BatchControlCenter.remoteQuery('queryExitLead',JSON.serialize(resultMap));
        //BatchControlCenter.remoteQuery('batchExcute');
        //BatchControlCenter.remoteQuery('queryExitLead');
        Test.StopTest();
    }
	// 2019/01/15 支払いメディアの一括自動入力機能 WGCH BEGIN
	// 支払いメディアの一括自動入力 TRUE
	static testMethod void myUnitTest7_TRUE() {
		// TO DO: implement unit test
		TestCommon.createCommDefine();
		TestCommon.createBillSimpleHelpConfigDoc();
		TestCommon.createBillSimplePaymentConfigDoc();
		createConfigDoc();
		createConfigDoc7_TRUE();
		System.assertEquals([select Id from Document where Name = 'BatchRequstConfigXml'].size(), 1);
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
		// 予約情報を作成する
		Lead__c leadInfo = TestCommon.createLead(Date.today(), 1, 1)[0];
		leadInfo.Rroom__c = room.Id;
		leadInfo.refTypeOfRooms__c = typeRoom.Id;
		update leadInfo;
		// 会計支払商品作成を行う
		AccountMaster__c accMst = new AccountMaster__c(
			Name = Label.CONST_012_0438,
			Field3__c = 'M99000',
			ActionType__c = CommConst.PROD_ACTION_TYPE_PY,
			PaymentType__c = '現金'
		);
		insert accMst;
		// 商品情報を作成する
		List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
		// 見積明細を作成する
		TestCommon.createBookEstItem(leadInfo, productLst[0]);
		RsvAccount__c rsv = TestCommon.createRsvAccount();
        AccountAcount__c acc =TestCommon.createAccountAcount(rsv.Id,leadInfo.Id);
        Tran1__c tran1 = new Tran1__c(
        	Field20__c = '10000',
    		Field7__c = productLst[0].Id,
    		Field1__c = acc.Id,
    		RelAccount__c = rsv.Id
    	);
    	insert tran1;
		BatchControlCenter batch = new BatchControlCenter();
		Test.StartTest();
		batch.currentBatchName = 'BulkAccPaymentBatch';
		String firstJobName = batch.currentBatchName;
		String gShopCode = sp.ShopCode__c;
		Date gSaleDate = Date.today();
		BatchControlCenter.startNextBatch(firstJobName, gShopCode, gSaleDate, null, null, null);
		String whereDate = rsv.name;
		Integer year = Integer.valueOf(whereDate.subString(0,4));
		Integer month = Integer.valueOf(whereDate.subString(4,6));
		Integer day = Integer.valueOf(whereDate.subString(6,8));
		gSaleDate = Date.newInstance(year, month, day);
		BatchControlCenter.startNextBatch(firstJobName, gShopCode, gSaleDate, null, null, null);
		gShopCode = null;
		BatchControlCenter.startNextBatch(firstJobName, gShopCode, gSaleDate, null, null, null);
		gShopCode = '';
		BatchControlCenter.startNextBatch(firstJobName, gShopCode, gSaleDate, null, null, null);
		List<BatchControlCenter.AccountInfo> accLst = BatchControlCenter.accQuery(gShopCode, gSaleDate.format());
		Test.StopTest();
	}
	// 支払いメディアの一括自動入力 TRUE
	static testMethod void myUnitTest7_1_TRUE() {
		// TO DO: implement unit test
		TestCommon.createCommDefine();
		TestCommon.createBillSimpleHelpConfigDoc();
		TestCommon.createBillSimplePaymentConfigDoc();
		createConfigDoc();
		createConfigDoc7_TRUE();
		System.assertEquals([select Id from Document where Name = 'BatchRequstConfigXml'].size(), 1);
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
		// 予約情報を作成する
		Lead__c leadInfo = TestCommon.createLead(Date.today(), 3, 3)[0];
		leadInfo.Rroom__c = room.Id;
		leadInfo.refTypeOfRooms__c = typeRoom.Id;
		update leadInfo;
		// 会計支払商品作成を行う
		AccountMaster__c accMst = new AccountMaster__c(
			Name = Label.CONST_012_0438,
			Field3__c = 'M99000',
			ActionType__c = CommConst.PROD_ACTION_TYPE_PY,
			PaymentType__c = '現金'
		);
		insert accMst;
		// 商品情報を作成する
		List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
		// 見積明細を作成する
		TestCommon.createBookEstItem(leadInfo, productLst[0]);
		RsvAccount__c rsv = TestCommon.createRsvAccount();
        AccountAcount__c acc =TestCommon.createAccountAcount(rsv.Id,leadInfo.Id);
        Tran1__c tran1 = new Tran1__c(
        	Field20__c = '10000',
    		Field7__c = productLst[0].Id,
    		Field1__c = acc.Id,
    		RelAccount__c = rsv.Id
    	);
    	insert tran1;
		BatchControlCenter batch = new BatchControlCenter();
		Test.StartTest();
		batch.currentBatchName = 'BulkAccPaymentBatch';
		String firstJobName = batch.currentBatchName;
		String gShopCode = sp.ShopCode__c;
		Date gSaleDate = Date.today();
		BatchControlCenter.startNextBatch(firstJobName, gShopCode, gSaleDate, null, null, null);
		String whereDate = rsv.name;
		Integer year = Integer.valueOf(whereDate.subString(0,4));
		Integer month = Integer.valueOf(whereDate.subString(4,6));
		Integer day = Integer.valueOf(whereDate.subString(6,8));
		gSaleDate = Date.newInstance(year, month, day);
		List<BatchControlCenter.AccountInfo> accLst = BatchControlCenter.accQuery(gShopCode, gSaleDate.format());
		List<BatchControlCenter.AccountInfo> acc1Lst = BatchControlCenter.accQuery(gShopCode, gSaleDate.addDays(1).format());
		List<BatchControlCenter.AccountInfo> acc2Lst = BatchControlCenter.accQuery(gShopCode, gSaleDate.addDays(2).format());
		BatchControlCenter.startNextBatch(firstJobName, gShopCode, gSaleDate, null, null, null);
		gShopCode = null;
		BatchControlCenter.startNextBatch(firstJobName, gShopCode, gSaleDate, null, null, null);
		gShopCode = '';
		BatchControlCenter.startNextBatch(firstJobName, gShopCode, gSaleDate, null, null, null);
		Test.StopTest();
	}
	// 支払いメディアの一括自動入力 FALSE
	static testMethod void myUnitTest7_FALSE() {
		// TO DO: implement unit test
		TestCommon.createCommDefine();
		TestCommon.createBillSimpleHelpConfigDoc();
		TestCommon.createBillSimplePaymentConfigDoc();
		createConfigDoc();
		createConfigDoc7_FALSE();
		System.assertEquals([select Id from Document where Name = 'BatchRequstConfigXml'].size(), 1);
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
		// 予約情報を作成する
		Lead__c leadInfo = TestCommon.createLead(Date.today(), 1, 1)[0];
		leadInfo.Rroom__c = room.Id;
		leadInfo.refTypeOfRooms__c = typeRoom.Id;
		update leadInfo;
		// 会計支払商品を自動作成を行う
		// 会計支払商品作成を行う
		AccountMaster__c accMst = new AccountMaster__c(
			Name = Label.CONST_012_0438,
			Field3__c = 'M99000',
			ActionType__c = CommConst.PROD_ACTION_TYPE_PY,
			PaymentType__c = '現金'
		);
		insert accMst;
		// 商品情報を作成する
		List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
		// 見積明細を作成する
		TestCommon.createBookEstItem(leadInfo, productLst[0]);
		RsvAccount__c rsv = TestCommon.createRsvAccount();
		AccountAcount__c acc =TestCommon.createAccountAcount(rsv.Id,leadInfo.Id);
        Tran1__c tran1 = new Tran1__c(
    		Field20__c = '10000',
    		Field7__c = productLst[0].Id,
    		Field1__c = acc.Id,
    		RelAccount__c = rsv.Id
    	);
    	insert tran1;
		BatchControlCenter batch = new BatchControlCenter();
		Test.StartTest();
		batch.currentBatchName = 'BulkAccPaymentBatch';
		
		String firstJobName = batch.currentBatchName;
		String gShopCode = '02';
		Date gSaleDate = Date.today();
		BatchControlCenter.startNextBatch(firstJobName, gShopCode, gSaleDate, null, null, null);
		String whereDate = rsv.name;
		Integer year = Integer.valueOf(whereDate.subString(0,4));
		Integer month = Integer.valueOf(whereDate.subString(4,6));
		Integer day = Integer.valueOf(whereDate.subString(6,8));
		gSaleDate = Date.newInstance(year, month, day);
		BatchControlCenter.startNextBatch(firstJobName, gShopCode, gSaleDate, null, null, null);
		Test.StopTest();
	}
	static testMethod void myUnitTest8() {
		// TO DO: implement unit test
		TestCommon.createCommDefine();
		
		createConfigDoc();
		createConfigDoc8();
		System.assertEquals([select Id from Document where Name = 'BatchRequstConfigXml'].size(), 1);
		
		
		
		Test.StartTest();
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
		BulkBadRoomQtyStatBatch qtyBatch1 = new BulkBadRoomQtyStatBatch();
        BulkBadRoomQtyStatBatch qtyBatch2 = new BulkBadRoomQtyStatBatch();
        BulkBadRoomQtyStatBatch qtyBatch = new BulkBadRoomQtyStatBatch(startDt,endDt,gShopCode,true);
		//qtyBatch.startDt = startDt;
		//qtyBatch.endDt = endDt;
		//qtyBatch.spcd = gShopCode;
		DataBase.executeBatch(qtyBatch,20);
		BatchControlCenter batch = new BatchControlCenter();
		batch.currentBatchName = 'BadRoomSum';
		batch.currentShopCode = '02';
		String firstJobName = batch.currentBatchName;
		
		Date gSaleDate = Date.today();
		batch.startBatch();
	
		Test.StopTest();
	}
	// 2019/01/15 支払いメディアの一括自動入力機能 WGCH END
	// 2019/12/30 FREEEAPI连携機能 WGCH BEGIN
    // FREEEAPI连携
    // FROM/TOあり
    static testMethod void myUnitTest_FreeeApiPost() {
    	// Freee連携設定
        delete [select id from FreeeSeting__c];
		FreeeSeting__c newFreee = new FreeeSeting__c(
	    	DisplayName__c = '事業所名(屋号)TEST',
	    	DeveloperName__c = '認証プロバイダをURL 接尾辞TEST'
		);	
		insert newFreee;
        // TO DO: implement unit test
        TestCommon.createCommDefine();
        createConfigDoc();
        createConfigDoc_FreeeApiPost();
        System.assertEquals([select Id from Document where Name = 'AccountingSyncBatchConfig'].size(), 1);
        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfo, productLst[0]);
        // 予約情報のステータス：チェックインに変更する
        leadInfo.Field298__c = 'チェックイン完';
        update leadInfo;
        
        BatchControlCenter batch = new BatchControlCenter();
        Test.StartTest();
        batch.currentBatchName = 'FREEEPostBatch';
        batch.currentBatch.checkinDay__c = Date.today().addDays(-30); 
        batch.currentBatchTo.checkinDay__c = Date.today();
        batch.startBatch();
        Test.StopTest();
    }
    /*
    // TO DO: implement unit test
    static testMethod void myUnitTest_FreeeApiPost_1() {
    	// Freee連携設定
        delete [select id from FreeeSeting__c];
		FreeeSeting__c newFreee = new FreeeSeting__c(
	    	DisplayName__c = '事業所名(屋号)TEST',
	    	DeveloperName__c = '認証プロバイダをURL 接尾辞TEST'
		);	
		insert newFreee;
		TestCommon.createCommDefine();
		TestCommon.createBillSimpleHelpConfigDoc();
		TestCommon.createBillSimplePaymentConfigDoc();
		createConfigDoc();
		createConfigDoc_FreeeApiPost();
		System.assertEquals([select Id from Document where Name = 'BatchRequstConfigXml'].size(), 1);
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
		// 予約情報を作成する
		Lead__c leadInfo = TestCommon.createLead(Date.today(), 1, 1)[0];
		leadInfo.Rroom__c = room.Id;
		leadInfo.refTypeOfRooms__c = typeRoom.Id;
		update leadInfo;
		// 会計支払商品作成を行う
		AccountMaster__c accMst = new AccountMaster__c(
			Name = Label.CONST_012_0438,
			Field3__c = 'M99000',
			ActionType__c = CommConst.PROD_ACTION_TYPE_PY,
			PaymentType__c = '現金'
		);
		insert accMst;
		// 商品情報を作成する
		List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
		// 見積明細を作成する
		TestCommon.createBookEstItem(leadInfo, productLst[0]);
		RsvAccount__c rsv = TestCommon.createRsvAccount();
		Date gSaleDate = Date.today();
		rsv.name = DateTime.newInstance(gSaleDate.year(), gSaleDate.month(), gSaleDate.day()).format('yyyyMMdd');
		update rsv;
        AccountAcount__c acc =TestCommon.createAccountAcount(rsv.Id,leadInfo.Id);
        Tran1__c tran1 = new Tran1__c(
        	Field20__c = '10000',
    		Field7__c = productLst[0].Id,
    		Field1__c = acc.Id,
    		RelAccount__c = rsv.Id
    	);
    	insert tran1;
		BatchControlCenter batch = new BatchControlCenter();
		Test.StartTest();
		batch.currentBatchName = 'FREEEPostBatch';
		String firstJobName = batch.currentBatchName;
		String gShopCode = sp.ShopCode__c;
		
		Date gFromDate = gSaleDate.addDays(-5);
		Date gToDate = gSaleDate.addDays(5);
		BatchControlCenter.startNextBatch(firstJobName, gShopCode, gFromDate, gToDate, null, null);
		batch.startBatch();
		Test.StopTest();
	}
	*/
    // 2019/12/30 FREEEAPI连携機能 WGCH END
    private static void createConfigDoc() {
    	String configXml = '<?xml version="1.0" encoding="utf-8"?><root><!-- 概要：銀行振り込み情報作成の関連定義情報 -->    <SHOP>        <!-- デフォルト設定情報、削除しない、支店舗追加したい場合、このＮＯＤＥコピーして、後ろに追加してください -->        <SHOPCODE></SHOPCODE>        <!-- 処理通知先メールアドレス,「,」で複数メールアドレス定義可能（５個まで） -->        <RESULT_MAIL>sankyou.go@m.e-cloudsoft.com,zhouyu@e-cloudsoft.com</RESULT_MAIL>        <!-- 振込決済バッ出力対象の制御条件の定義 -->        <FILTER>KamokuLst__c in (\'買掛（月末振込）\',\'買掛（都度振込）\') </FILTER>        <!-- リクエストバッチ待ち時間の定義(秒数) 0の場合、待ちなし、１０秒後スケジュールを起動する -->        <REQBAT_WAIT_TIME>0</REQBAT_WAIT_TIME>        <!-- 仕入入力画面に表示するレポートボタン情報 -->        <BUTTONS>        	<BUTTON>        		<LABEL>レポート1</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        	<BUTTON>        		<LABEL>レポート2</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        	<BUTTON>        		<LABEL>レポート3</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        	<BUTTON>        		<LABEL>レポート4</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        </BUTTONS>        <!-- 銀行へ通信電文関連定義情報 -->        <!-- 銀行振り込み手数料:必須 -->        <BANK_TRANS_RATE>			<SAME_BANK>							<!-- 同銀行 -->				<SAME_BRANCH>					<!-- 同支店 -->					<RANK_LEVEL>						<MIN_VAL>0</MIN_VAL>						<MAX_VAL>9999</MAX_VAL>						<RATE>0</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>10000</MIN_VAL>						<MAX_VAL>29999</MAX_VAL>						<RATE>0</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>30000</MIN_VAL>						<RATE>0</RATE>					</RANK_LEVEL>				</SAME_BRANCH>				<DIFF_BRANCH>					<!-- 別支店 -->					<RANK_LEVEL>						<MIN_VAL>0</MIN_VAL>						<MAX_VAL>9999</MAX_VAL>						<RATE>108</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>10000</MIN_VAL>						<MAX_VAL>29999</MAX_VAL>						<RATE>108</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>30000</MIN_VAL>						<RATE>324</RATE>					</RANK_LEVEL>				</DIFF_BRANCH>			</SAME_BANK>			<DIFF_BANK>						<!-- 別銀行 -->				<RANK_LEVEL>					<MIN_VAL>0</MIN_VAL>					<MAX_VAL>9999</MAX_VAL>					<RATE>324</RATE>				</RANK_LEVEL>				<RANK_LEVEL>					<MIN_VAL>10000</MIN_VAL>					<MAX_VAL>29999</MAX_VAL>					<RATE>432</RATE>				</RANK_LEVEL>				<RANK_LEVEL>					<MIN_VAL>30000</MIN_VAL>					<RATE>648</RATE>				</RANK_LEVEL>			</DIFF_BANK>        </BANK_TRANS_RATE>        <!-- 口座情報定義する -->        <BANK_KOZAINFO>        	<!-- 買掛決済処理機能関連の口座情報定義　BEGIN -->        	<PUR_SETTLEMENT>								<!-- 買掛決済バッチ支払口座情報の定義 -->        		<KOUZA_SEQ>2</KOUZA_SEQ>					<!-- 店舗口座情報#SEQ値 -->        		<DESCRIPT>仕入支払口座</DESCRIPT>        		<TRANS_TYPE>21</TRANS_TYPE>					<!-- 業務種別:21:総合 11または71:給与 12または72:賞与 -->        	</PUR_SETTLEMENT>        	        	<PUR_RECIVEACCOUNT>								<!-- 振り込み先の口座情報の定義 -->        		<KOUZA_TYPE>買掛支払</KOUZA_TYPE>        		<DESCRIPT>        		取引先の振込用口座の種別情報、取引先側に複数口座情報を登録される場合、該当種別で、口座情報の「口座種別」と比較用        		一致すると、該当口座情報は買掛決済振り込み先の口座情報で利用する        		</DESCRIPT>        	</PUR_RECIVEACCOUNT>        	        	<!-- 買掛決済処理機能関連の口座情報定義　END -->        </BANK_KOZAINFO>        <BANK_TELEGRAM_HEADER>        	<DATA_KBN>1</DATA_KBN>		<!-- レコード種別:1:ヘッダレコード -->        	<MESSAGE_HEADER>        	データ区分,種別コード,コード区分,会社コード,会社名,振込指定日,仕向銀行番号,仕向銀行名,仕向支店番号,仕向支店名,預金種目,口座番号,ダミー        	</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_種別コード_$$			$$_コード区分_$$			$$_委託者コード_$$			$$_委託者名_$$			$$_取組日_$$			$$_仕向金融機関番号_$$			$$_仕向金融機関名_$$			$$_仕向支店番号_$$			$$_仕向支店名_$$			$$_預金種目(依頼人)_$$			$$_口座番号(依頼人)_$$			$$_ダミー_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_HEADER>		<BANK_TELEGRAM_DETAIL>			<DATA_KBN>2</DATA_KBN>		<!-- レコード種別:2:データレコード -->			<IS_EDI>FALSE</IS_EDI>			<!-- EDI情報を使う -->			<FURIKOMIKBN>7</FURIKOMIKBN>	<!-- 振込指定区分 -->			<MESSAGE_HEADER>			データ区分,被仕向銀行番号,被仕向銀行名,被仕向支店番号,被仕向支店名,手形交換所番号,預金種目,口座番号,受取人名,振込金額,新規コード,顧客コード1,顧客コード2,振込指定区分,識別表示,ダミー,支払金額,先方負担手数料,振込手数料			</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_被仕向金融機関番号_$$			$$_被仕向金融機関名_$$			$$_被仕向支店番号_$$			$$_被仕向支店名_$$			$$_手形交換所番号_$$			$$_預金種目_$$			$$_口座番号_$$			$$_受取人名_$$			$$_振込金額_$$			$$_新規コード_$$			$$_顧客コード1_$$			$$_顧客コード2_$$			$$_EDI情報_$$			$$_振込区分_$$			$$_識別表示_$$			$$_ダミー_$$			$$_支払金額_$$			$$_先方負担手数料_$$			$$_振込手数料_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_DETAIL>		<BANK_TELEGRAM_TRAILER>			<DATA_KBN>8</DATA_KBN>		<!-- レコード種別:8:トレーラレコード -->			<MESSAGE_HEADER>			データ区分,合計件数,合計金額,ダミー			</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_合計件数_$$			$$_合計金額_$$			$$_ダミー_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_TRAILER>		<BANK_TELEGRAM_END>			<DATA_KBN>9</DATA_KBN>		<!-- レコード種別:9:エンドレコード -->			<MESSAGE_HEADER>			データ区分,ダミー 			</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_ダミー_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_END>		<!-- エージェント販売手数料計算関連 -->		<AGT_SALESRATE>			<DATA_FILTER></DATA_FILTER>				<!-- 旅行会社の「旅行会社分類」制御が必要場合、タイプを追加する、複数存在すると、「,」定義する -->			<I_TYPENAME>販売手数料</I_TYPENAME>		<!-- 種別 -->			<O_KAMOKU>買掛（月末振込）</O_KAMOKU>		<!-- 科目 -->			<CHARGERATE_LOGIC>				<FILTER VALUE="HR(宿泊)" CATAGO="KNT">		 			<LOGIC>{0}</LOGIC>		          	<COONDITION>						ReservedType__c in (\'泊 ２食\',\'泊 朝半\',\'泊 夕半\',\'泊 素\',\'宿泊\')		          	</COONDITION>	          	</FILTER>			</CHARGERATE_LOGIC>		</AGT_SALESRATE>		<!-- カード販売手数料計算関連 -->		<CARD_SALESRATE>			<I_TYPENAME>カード手数料</I_TYPENAME>			<O_KAMOKU>買掛（月末振込）</O_KAMOKU>		</CARD_SALESRATE>    </SHOP>    <SHOP>        <!-- デフォルト設定情報、削除しない、支店舗追加したい場合、このＮＯＤＥコピーして、後ろに追加してください -->        <SHOPCODE>01</SHOPCODE>        <!-- 処理通知先メールアドレス,「,」で複数メールアドレス定義可能（５個まで） -->        <RESULT_MAIL>sankyou.go@m.e-cloudsoft.com,zhouyu@e-cloudsoft.com</RESULT_MAIL>        <!-- 振込決済バッ出力対象の制御条件の定義 -->        <FILTER>KamokuLst__c in (\'買掛（月末振込）\',\'買掛（都度振込）\') </FILTER>        <!-- 仕入入力画面に表示するレポートボタン情報 -->        <BUTTONS>        	<BUTTON>        		<LABEL>レポート1</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        	<BUTTON>        		<LABEL>レポート2</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        	<BUTTON>        		<LABEL>レポート3</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        	<BUTTON>        		<LABEL>レポート4</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        </BUTTONS>        <!-- 銀行へ通信電文関連定義情報 -->        <!-- 銀行振り込み手数料:必須 -->        <BANK_TRANS_RATE>			<SAME_BANK>							<!-- 同銀行 -->				<SAME_BRANCH>					<!-- 同支店 -->					<RANK_LEVEL>						<MIN_VAL>0</MIN_VAL>						<MAX_VAL>9999</MAX_VAL>						<RATE>0</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>10000</MIN_VAL>						<MAX_VAL>29999</MAX_VAL>						<RATE>0</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>30000</MIN_VAL>						<RATE>0</RATE>					</RANK_LEVEL>				</SAME_BRANCH>				<DIFF_BRANCH>					<!-- 別支店 -->					<RANK_LEVEL>						<MIN_VAL>0</MIN_VAL>						<MAX_VAL>9999</MAX_VAL>						<RATE>108</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>10000</MIN_VAL>						<MAX_VAL>29999</MAX_VAL>						<RATE>108</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>30000</MIN_VAL>						<RATE>324</RATE>					</RANK_LEVEL>				</DIFF_BRANCH>			</SAME_BANK>			<DIFF_BANK>						<!-- 別銀行 -->				<RANK_LEVEL>					<MIN_VAL>0</MIN_VAL>					<MAX_VAL>9999</MAX_VAL>					<RATE>324</RATE>				</RANK_LEVEL>				<RANK_LEVEL>					<MIN_VAL>10000</MIN_VAL>					<MAX_VAL>29999</MAX_VAL>					<RATE>432</RATE>				</RANK_LEVEL>				<RANK_LEVEL>					<MIN_VAL>30000</MIN_VAL>					<RATE>648</RATE>				</RANK_LEVEL>			</DIFF_BANK>        </BANK_TRANS_RATE>        <!-- 口座情報定義する -->        <BANK_KOZAINFO>        	<!-- 買掛決済処理機能関連の口座情報定義　BEGIN -->        	<PUR_SETTLEMENT>								<!-- 買掛決済バッチ支払口座情報の定義 -->        		<KOUZA_SEQ>2</KOUZA_SEQ>					<!-- 店舗口座情報#SEQ値 -->        		<DESCRIPT>仕入支払口座</DESCRIPT>        		<TRANS_TYPE>21</TRANS_TYPE>					<!-- 業務種別:21:総合 11または71:給与 12または72:賞与 -->        	</PUR_SETTLEMENT>        	        	<PUR_RECIVEACCOUNT>								<!-- 振り込み先の口座情報の定義 -->        		<KOUZA_TYPE>買掛支払</KOUZA_TYPE>        		<DESCRIPT>        		取引先の振込用口座の種別情報、取引先側に複数口座情報を登録される場合、該当種別で、口座情報の「口座種別」と比較用        		一致すると、該当口座情報は買掛決済振り込み先の口座情報で利用する        		</DESCRIPT>        	</PUR_RECIVEACCOUNT>        	        	<!-- 買掛決済処理機能関連の口座情報定義　END -->        </BANK_KOZAINFO>        <BANK_TELEGRAM_HEADER>        	<DATA_KBN>1</DATA_KBN>		<!-- レコード種別:1:ヘッダレコード -->        	<MESSAGE_HEADER>        	データ区分,種別コード,コード区分,会社コード,会社名,振込指定日,仕向銀行番号,仕向銀行名,仕向支店番号,仕向支店名,預金種目,口座番号,ダミー        	</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_種別コード_$$			$$_コード区分_$$			$$_委託者コード_$$			$$_委託者名_$$			$$_取組日_$$			$$_仕向金融機関番号_$$			$$_仕向金融機関名_$$			$$_仕向支店番号_$$			$$_仕向支店名_$$			$$_預金種目(依頼人)_$$			$$_口座番号(依頼人)_$$			$$_ダミー_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_HEADER>		<BANK_TELEGRAM_DETAIL>			<DATA_KBN>2</DATA_KBN>		<!-- レコード種別:2:データレコード -->			<IS_EDI>FALSE</IS_EDI>			<!-- EDI情報を使う -->			<FURIKOMIKBN>7</FURIKOMIKBN>	<!-- 振込指定区分 -->			<MESSAGE_HEADER>			データ区分,被仕向銀行番号,被仕向銀行名,被仕向支店番号,被仕向支店名,手形交換所番号,預金種目,口座番号,受取人名,振込金額,新規コード,顧客コード1,顧客コード2,振込指定区分,識別表示,ダミー,支払金額,先方負担手数料,振込手数料			</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_被仕向金融機関番号_$$			$$_被仕向金融機関名_$$			$$_被仕向支店番号_$$			$$_被仕向支店名_$$			$$_手形交換所番号_$$			$$_預金種目_$$			$$_口座番号_$$			$$_受取人名_$$			$$_振込金額_$$			$$_新規コード_$$			$$_顧客コード1_$$			$$_顧客コード2_$$			$$_EDI情報_$$			$$_振込区分_$$			$$_識別表示_$$			$$_ダミー_$$			$$_支払金額_$$			$$_先方負担手数料_$$			$$_振込手数料_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_DETAIL>		<BANK_TELEGRAM_TRAILER>			<DATA_KBN>8</DATA_KBN>		<!-- レコード種別:8:トレーラレコード -->			<MESSAGE_HEADER>			データ区分,合計件数,合計金額,ダミー			</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_合計件数_$$			$$_合計金額_$$			$$_ダミー_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_TRAILER>		<BANK_TELEGRAM_END>			<DATA_KBN>9</DATA_KBN>		<!-- レコード種別:9:エンドレコード -->			<MESSAGE_HEADER>			データ区分,ダミー 			</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_ダミー_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_END>		<!-- エージェント販売手数料計算関連 -->		<AGT_SALESRATE>			<DATA_FILTER></DATA_FILTER>				<!-- 旅行会社の「旅行会社分類」制御が必要場合、タイプを追加する、複数存在すると、「,」定義する -->			<I_TYPENAME>販売手数料</I_TYPENAME>		<!-- 種別 -->			<O_KAMOKU>買掛（月末振込）</O_KAMOKU>		<!-- 科目 -->			<CHARGERATE_LOGIC>				<FILTER VALUE="HR(宿泊)" CATAGO="KNT">		 			<LOGIC>{0}</LOGIC>		          	<COONDITION>						ReservedType__c in (\'泊 ２食\',\'泊 朝半\',\'泊 夕半\',\'泊 素\',\'宿泊\')		          	</COONDITION>	          	</FILTER>			</CHARGERATE_LOGIC>		</AGT_SALESRATE>		<!-- カード販売手数料計算関連 -->		<CARD_SALESRATE>			<I_TYPENAME>カード手数料</I_TYPENAME>			<O_KAMOKU>買掛（月末振込）</O_KAMOKU>		</CARD_SALESRATE>    </SHOP></root>';
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'AccountingSyncBatchConfig';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(configXml);
    	insert item;

        String configXml2 = '<root><SHOP><SHOPCODE></SHOPCODE><SUMMARY><PURCHASE><ASSING_FROM>Denpyoukei__c</ASSING_FROM><ASSING_TO>PurchaseStand__c</ASSING_TO><CONDITION>PurchaseType__c = \'売店仕入\'</CONDITION></PURCHASE><PURCHASE><ASSING_FROM>Denpyoukei__c</ASSING_FROM><ASSING_TO>PurchaseBeverage__c</ASSING_TO>'+
        					'<CONDITION>PurchaseType__c = \'飲料仕入\'</CONDITION></PURCHASE><PURCHASE><ASSING_FROM>Denpyoukei__c</ASSING_FROM><ASSING_TO>PurchaseRoom__c</ASSING_TO><CONDITION>PurchaseType__c = \'室料経費\'</CONDITION></PURCHASE><PURCHASE><ASSING_FROM>Denpyoukei__c</ASSING_FROM><ASSING_TO>PurchaseBridal__c</ASSING_TO>'+
        					'<CONDITION>PurchaseType__c = \'ブライダル仕入\'</CONDITION></PURCHASE><PURCHASE><ASSING_FROM>Denpyoukei__c</ASSING_FROM><ASSING_TO>PurchaseExpenses__c</ASSING_TO><CONDITION>PurchaseType__c = \'旅館外注費\'</CONDITION></PURCHASE></SUMMARY></SHOP>' + '</root>';
        Document item2 = new Document();
        item2.Name = 'RsvPurchaseSumConfig';
        item2.DeveloperName = item2.Name;
        item2.FolderId = UserInfo.getUserId();
        item2.Body = Blob.valueOf(configXml2);
        insert item2;
    }
    private static void createConfigDoc2() {
    	String configXml = '<?xml version="1.0" encoding="utf-8"?><root><SHOP><SHOPCODE></SHOPCODE><REQUEST_BATCH><BATCH FROMTO="FALSE" TIMETERM="LASTWEEK"><LABEL>1.手数料バッチ</LABEL><BATCHKEY>ChargeBatch</BATCHKEY></BATCH><BATCH FROMTO="FALSE" TIMETERM="今週"><LABEL>3.Freee連携バッチ</LABEL><BATCHKEY>FREEEBatch</BATCHKEY></BATCH><BATCH><LABEL>4.売上バッチ</LABEL><BATCHKEY>SalesBatch</BATCHKEY></BATCH><BATCH><LABEL>5.POS取込</LABEL><BATCHKEY>PosBatch</BATCHKEY></BATCH><BATCH><LABEL>7.Exceptionバッチ</LABEL><BATCHKEY>KanBatch1</BATCHKEY></BATCH><BATCH><LABEL>8.PCAバッチ</LABEL><BATCHKEY>PCABatch</BATCHKEY></BATCH><BATCH><LABEL>8.KanBatch1バッチ</LABEL><BATCHKEY>KanBatch</BATCHKEY></BATCH></REQUEST_BATCH></SHOP></root>';
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'BatchRequstConfigXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(configXml);
    	insert item;
    }
    // 手数料　AND　FREEE
    private static void createConfigDoc3() {
    	String configXml = '<?xml version="1.0" encoding="utf-8"?><root><SHOP><SHOPCODE></SHOPCODE><REQUEST_BATCH><BATCH FROMTO="TRUE"><LABEL>1.手数料バッチ</LABEL><BATCHKEY>ChargeBatch</BATCHKEY><BATCHKEY>FREEEBatch</BATCHKEY></BATCH><BATCH FROMTO="TRUE" TIMETERM="今週"><LABEL>3.Freee連携バッチ</LABEL><BATCHKEY>FREEEBatch</BATCHKEY></BATCH><BATCH><LABEL>4.売上バッチ</LABEL><BATCHKEY>SalesBatch</BATCHKEY></BATCH><BATCH><LABEL>5.POS取込</LABEL><BATCHKEY>PosBatch</BATCHKEY></BATCH><BATCH><LABEL>7.Exceptionバッチ</LABEL><BATCHKEY>KanBatch1</BATCHKEY></BATCH><BATCH><LABEL>8.PCAバッチ</LABEL><BATCHKEY>PCABatch</BATCHKEY></BATCH><BATCH><LABEL>8.KanBatch1バッチ</LABEL><BATCHKEY>KanBatch</BATCHKEY></BATCH></REQUEST_BATCH></SHOP></root>';
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'BatchRequstConfigXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(configXml);
    	insert item;
    }
    // 手数料　AND　FREEE
    private static void createConfigDoc4() {
    	String configXml = '<?xml version="1.0" encoding="utf-8"?><root><SHOP><SHOPCODE></SHOPCODE><REQUEST_BATCH><BATCH FROMTO="TRUE" TIMETERM="今日"><LABEL>1.手数料バッチ</LABEL><BATCHKEY>ChargeBatch</BATCHKEY></BATCH><BATCH FROMTO="TRUE" TIMETERM="TODAY"><LABEL>3.Freee連携バッチ</LABEL><BATCHKEY>FREEEBatch</BATCHKEY></BATCH></REQUEST_BATCH></SHOP></root>';
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'BatchRequstConfigXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(configXml);
    	insert item;
    }
    // 手数料、FREEE、KAN、PCA
    private static void createConfigDoc5() {
        String configXml = '<?xml version="1.0" encoding="utf-8"?><root><SHOP><SHOPCODE></SHOPCODE><REQUEST_BATCH><BATCH FROMTO="TRUE" TIMETERM="今日"><LABEL>FROMTOBATCH</LABEL><BATCHKEY>ChargeBatch</BATCHKEY><BATCHKEY>PCABatch</BATCHKEY><BATCHKEY>KanBatch</BATCHKEY><BATCHKEY>FREEEBatch</BATCHKEY></BATCH></REQUEST_BATCH></SHOP></root>';
        // ドキュメントを作成する
        Document item = new Document();
        item.Name = 'BatchRequstConfigXml';
        item.DeveloperName = item.Name;
        item.FolderId = UserInfo.getUserId();
        item.Body = Blob.valueOf(configXml);
        insert item;
    }
    // 一括請求書
    private static void createConfigDoc6() {
        String configXml = '<?xml version="1.0" encoding="utf-8"?><root><SHOP><SHOPCODE></SHOPCODE><REQUEST_BATCH><BATCH><LABEL>FROMTOBATCH</LABEL><BATCHKEY>BillPdfBatch</BATCHKEY></BATCH></REQUEST_BATCH></SHOP></root>';
        // ドキュメントを作成する
        Document item = new Document();
        item.Name = 'BatchRequstConfigXml';
        item.DeveloperName = item.Name;
        item.FolderId = UserInfo.getUserId();
        item.Body = Blob.valueOf(configXml);
        insert item;
    }
	// 2019/01/15 支払いメディアの一括自動入力機能 WGCH BEGIN
	// 支払いメディアの一括自動入力 TRUE
	private static void createConfigDoc7_TRUE() {
		String configXml = '<?xml version="1.0" encoding="utf-8"?><root><SHOP><SHOPCODE></SHOPCODE><ACCPAY_BATCH><AUTOCHECKINFLG>TRUE</AUTOCHECKINFLG><FIRSTNIGHTCHECKINFLG>TRUE</FIRSTNIGHTCHECKINFLG><FIRSTNIGHTPAYMENTCODE>M99002</FIRSTNIGHTPAYMENTCODE><NNIGHTPAYMENTCODE>M99000</NNIGHTPAYMENTCODE></ACCPAY_BATCH><REQUEST_BATCH><BATCH><LABEL>FROMTOBATCH</LABEL><BATCHKEY>BulkAccPaymentBatch</BATCHKEY></BATCH></REQUEST_BATCH></SHOP></root>';
		// ドキュメントを作成する
		Document item = new Document();
		item.Name = 'BatchRequstConfigXml';
		item.DeveloperName = item.Name;
		item.FolderId = UserInfo.getUserId();
		item.Body = Blob.valueOf(configXml);
		insert item;
	}
	// 支払いメディアの一括自動入力 FALSE
	private static void createConfigDoc7_FALSE() {
		String configXml = ' <?xml version="1.0" encoding="utf-8"?><root><SHOP><SHOPCODE></SHOPCODE><ACCPAY_BATCH><AUTOCHECKINFLG>FALSE</AUTOCHECKINFLG><FIRSTNIGHTCHECKINFLG>FALSE</FIRSTNIGHTCHECKINFLG><FIRSTNIGHTPAYMENTCODE></FIRSTNIGHTPAYMENTCODE><NNIGHTPAYMENTCODE></NNIGHTPAYMENTCODE></ACCPAY_BATCH><REQUEST_BATCH><BATCH><LABEL>FROMTOBATCH</LABEL><BATCHKEY>BulkAccPaymentBatch</BATCHKEY></BATCH></REQUEST_BATCH></SHOP></root>';
		// ドキュメントを作成する
		Document item = new Document();
		item.Name = 'BatchRequstConfigXml';
		item.DeveloperName = item.Name;
		item.FolderId = UserInfo.getUserId();
		item.Body = Blob.valueOf(configXml);
		insert item;
	}
	// 2019/01/15 支払いメディアの一括自動入力機能 WGCH END
	// 2019/12/30 FREEEAPI连携機能 WGCH BEGIN
	private static void createConfigDoc_FreeeApiPost() {
		String configXml = ' <?xml version="1.0" encoding="utf-8"?><root><SHOP><SHOPCODE></SHOPCODE><ACCPAY_BATCH><AUTOCHECKINFLG>FALSE</AUTOCHECKINFLG><FIRSTNIGHTCHECKINFLG>FALSE</FIRSTNIGHTCHECKINFLG><FIRSTNIGHTPAYMENTCODE></FIRSTNIGHTPAYMENTCODE><NNIGHTPAYMENTCODE></NNIGHTPAYMENTCODE></ACCPAY_BATCH><REQUEST_BATCH><BATCH><LABEL>FROMTOBATCH</LABEL><BATCHKEY>BadRoomSum</BATCHKEY><PROCESSBEG>0</PROCESSBEG><PROCESSEND>0</PROCESSEND><PROCESSWHERE></PROCESSWHERE></BATCH><BATCH><LABEL>FREEEAPI連携バッチ</LABEL><BATCHKEY>FREEEPostBatch</BATCHKEY></BATCH></REQUEST_BATCH></SHOP></root>';
		// ドキュメントを作成する
		Document item = new Document();
		item.Name = 'BatchRequstConfigXml';
		item.DeveloperName = item.Name;
		item.FolderId = UserInfo.getUserId();
		item.Body = Blob.valueOf(configXml);
		insert item;
	}
	// 2019/12/30 FREEEAPI连携機能 WGCH END
    private static void createConfigDoc8() {
		String configXml = ' <?xml version="1.0" encoding="utf-8"?><root><SHOP><SHOPCODE></SHOPCODE><ACCPAY_BATCH><AUTOCHECKINFLG>FALSE</AUTOCHECKINFLG><FIRSTNIGHTCHECKINFLG>FALSE</FIRSTNIGHTCHECKINFLG><FIRSTNIGHTPAYMENTCODE></FIRSTNIGHTPAYMENTCODE><NNIGHTPAYMENTCODE></NNIGHTPAYMENTCODE></ACCPAY_BATCH><REQUEST_BATCH><BATCH><LABEL>FROMTOBATCH</LABEL><BATCHKEY>BadRoomSum</BATCHKEY><PROCESSBEG>0</PROCESSBEG><PROCESSEND>0</PROCESSEND><PROCESSWHERE></PROCESSWHERE></BATCH></REQUEST_BATCH></SHOP></root>';
		// ドキュメントを作成する
		Document item = new Document();
		item.Name = 'BatchRequstConfigXml';
		item.DeveloperName = item.Name;
		item.FolderId = UserInfo.getUserId();
		item.Body = Blob.valueOf(configXml);
		insert item;
	}
}