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
@isTest(SeeAllData=false)
private class BulkProcessBatchTest {


	// 自動チェックテスト
	@isTest(SeeAllData=false)
    static void myCheckinTest() {
    	Test.startTest();
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 2015/12/01 Assert BEGIN
        System.assertEquals(productLst.size(), 1);
        // 2015/12/01 Assert END
    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	Test.stopTest();

    	// 指定日でバッチ処理を行う
    	BulkProcessBatch batch = new BulkProcessBatch();
    	batch.checkInDate = leadInfo.EntryTime__c.format('yyyy/MM/dd');
    	batch.autoCheckInProcess();
//        System.assert(batch.isShowCheckinMsg);
    }
    // 指定日会計を行う
    @isTest(SeeAllData=false)
    static void myCalDayAmountTest() {
    	Test.startTest();
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 2015/12/01 Assert BEGIN
        System.assertEquals(productLst.size(), 1);
        // 2015/12/01 Assert END
    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	Test.stopTest();

    	// 指定日でバッチ処理を行う
    	BulkProcessBatch batch = new BulkProcessBatch();
    	batch.checkInDate = leadInfo.EntryTime__c.format('yyyy/MM/dd');
    	batch.autoCheckInProcess();

    	batch.checkInDate = leadInfo.EntryTime__c.addDays(-1).format('yyyy/MM/dd');
    	batch.autoCheckInProcess();
//        System.assert(batch.isShowCheckinMsg);
    	batch.amoutDate = batch.checkInDate;
    	batch.autoCalDayAmount();
    	//System.assert(batch.isShowCalDayAmoutMsg);
		//
		batch.UpdateforSalesforcast();
    }
    
    @isTest(SeeAllData=false)
    static void confirmAmountInfo() {
    	Test.startTest();
    	// 予約情報を作成する
    	//Contact guest = TestCommon.createContact();
		TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
		
		// 新規登録
		LeadIndex__c sobj = new LeadIndex__c();
    	ApexPages.StandardController contrl = new ApexPages.StandardController(sobj);
    	BookingApp app = new BookingApp(contrl);
    	
		app.leadBaseInf.s.EntryDate__c = Date.today();
		app.leadBaseInf.s.EntryTime__c = '16:00';
		app.leadBaseInf.s.Nights__c = 2;
		app.leadBaseInf.s.DepartureDate__c = app.leadBaseInf.s.EntryDate__c.addDays(app.leadBaseInf.s.Nights__c.intValue());
		app.leadBaseInf.s.DepartureTime__c = '10:30';
        // 顧客情報を更新を行う
        //app.refreshContcatInfo();

 		app.leadBaseInf.contactName = 'UNAME' + Crypto.getRandomLong();
 		app.leadBaseInf.l.Field2__c = '本社';
 		app.leadBaseInf.l.Segment__c = 'CARD';
        app.leadBaseInf.accoutName = 'ACC-NEW' + CommUtils.getRandom(10);
		//app.leadBaseInf.s.contactRef__c = guest.Id;
		app.leadBaseInf.s.LeadName__c = 'テストケースの予約名';
		app.leadBaseInf.s.Comment__c = 'Comment_'+ CommUtils.getRandom(10);
		
		BookingApp.LeadItem subItem = app.oLeadLst[0];
		subItem.s.EntryDate__c = app.leadBaseInf.s.EntryDate__c;
		subItem.nights = String.valueOf(app.leadBaseInf.s.Nights__c);
		subItem.s.DepartureDate__c = app.leadBaseInf.s.DepartureDate__c;
		subItem.s.RoomTypeRef__c = typeOfRoom.Id;
		subItem.persons = String.valueOf(4);
		subItem.rooms = String.valueOf(1);
		// １件予約データを作成する
 		app.createLeadInfo();
 		
//System.debug(logginglevel.ERROR, '[:2ERROR2:]' +[select id, Nights__c,Rooms__c from LeadIndex__c where ParentLeadIndxRef__c != null]);
 		// 部屋アサインする
 		Room__c roomId = TestCommon.createRooms();
 		List<Lead__c> leadInfo = [select id,EntryTime__c,Rroom__c from lead__c order by EntryTime__c];
 		Integer idx = 0;
 		for (Lead__c lead : leadInfo) {
 			lead.Rroom__c = roomId.Id;
 			lead.refTypeOfRooms__c = roomId.TypeRoomRef__c;
 			if (idx == 0) lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
 			idx++;
 		}
 		update leadInfo;
 		System.assertEquals(leadInfo.size(), 2);
 		
    	JMST__c taxMst = TestCommon.createTaxMst();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
    	// 見積明細を作成する
    	BookingEstimateItem__c bookingItem = TestCommon.createBookEstItem(leadInfo[0], productLst[0]);
    	BookingEstimateItem__c bookingItem2 = TestCommon.createBookEstItem(leadInfo[1], productLst[0]);
    	// 指定日でバッチ処理を行う
    	BulkProcessBatch batch = new BulkProcessBatch();
    	batch.checkInDate = leadInfo[1].EntryTime__c.format('yyyy/MM/dd');
    	batch.autoCheckInProcess();
    	Test.stopTest();
    	
    	// 処理日の会計情報を計算する
    	// 会計情報確認
    	// ps__Field147__c:$売上計III（税抜）金額
    	// ps__Field151__c:$売上計IV（税込）金額
    	// ps__SumSrvPriceIncTax__c:サービス料（税込）
    	// ps__SumSrvPriceExcTax__c:サービス料（税抜）
    	// ps__Discount__c:割引金額
    	// ps__SumTax__c:消費税
    	// ps__AmoutSpecialPrice__c:宿泊税
    	// Field126__c 請求金額
    	List<AccountAcount__c> accLst = [select id, Field147__c, Field151__c,SumSrvPriceIncTax__c,SumSrvPriceExcTax__c,Discount__c,SumTax__c,AmoutSpecialPrice__c,Field126__c 
    															from AccountAcount__c Where Relreserve__c = :leadInfo[1].Id];
    	// 自分チェックインとバッチチェックイン２件あり
    	System.assertEquals(accLst.size(), 1);
    	AccountAcount__c acc = accLst[0];
    	
    	CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo();
    	// 特別税
    	Decimal SpecialTax = productLst[0].SpecialTax__c;
		Decimal unitPrice = CommUtils.nullToZero(productLst[0].Field5__c);  // <-税金含め単価です
		Decimal qty = CommUtils.nullToZero(bookingItem.Amount__c);
        priceInfo.process(unitPrice , qty , taxMst.TaxRate__c, productLst[0].ServiceRate__c);    	
    	// 金額設定判定
    	System.assertEquals(acc.Field151__c, priceInfo.priceIncTax + SpecialTax);
    	System.assertEquals(acc.Field147__c, priceInfo.priceExcTax);
    	System.assertEquals(acc.SumTax__c, (priceInfo.priceIncTax-priceInfo.priceExcTax));
    	
    	System.assertEquals(acc.SumSrvPriceIncTax__c, priceInfo.priceService);
    	System.assertEquals(acc.SumSrvPriceExcTax__c, priceInfo.priceServiceExcTax);
    	System.assertEquals(acc.Discount__c, 0);
    	System.assertEquals(acc.AmoutSpecialPrice__c, SpecialTax);
    	
    	System.assertEquals(Decimal.valueOf(acc.Field126__c), acc.Field151__c);
    }
    
    @isTest(SeeAllData=false)
   static void batchCheckInCheckTest1() {
		// チェックインする前に、予約データ関連のチェックインできるがどうかチェックを行う
		// １：2泊１部屋の予約データを作成する、該当部屋は1泊目の予約データは自動チェックインすると、自動チェックイン対象外になる
		Date startDt = Date.newInstance(2013, 10, 31);
		
		List<Lead__c> lead1Room2Night = TestCommon.createLead(startDt, 1, 2);
    	Set<Id> leadIdSet = new Set<Id>();
		for (Lead__c lead : lead1Room2Night) {leadIdSet.add(lead.Id);}
		
		Test.startTest();
		// 該当１泊目の予約データでバッチ実施
		BulkProcessBatch bat = new BulkProcessBatch();
		bat.checkInDate = startDt.format();
    	bat.autoCheckInProcess();
    	String msg1 = bat.message;
    	String msg2 = bat.errMessage;
//    	System.assert(String.isEmpty(msg1), msg1);
    	System.assert(String.isEmpty(msg2), msg2);
    	// データは未自動チェックイン
    	for (Lead__c lead : [select Id, Field298__c,LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c from lead__c where id in:leadIdSet]) {
    		System.assert(String.isEmpty(lead.Field298__c), lead);
    	}
    	// ２泊目バッチ実行する
		bat.checkInDate = startDt.addDays(1).format();
    	bat.autoCheckInProcess();
    	msg1 = bat.message;
    	msg2 = bat.errMessage;
//    	System.assert(String.isEmpty(msg1), msg1);
    	System.assert(!String.isEmpty(msg2), msg2);
    	System.assert(msg2.contains(lead1Room2Night[0].Id), msg2);
    	// データは未自動チェックイン
    	for (Lead__c lead : [select Id, Field298__c,LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c from lead__c where id in :leadIdSet]) {
    		System.assert(String.isEmpty(lead.Field298__c), lead);
    	}
    	
    	// 1泊目の予約データはチェックインする場合、2泊目は自動バッチでチェックイン可能
    	List<Lead__c> updateLeads = [select id,Field298__c from Lead__c where DAY_ONLY(convertTimezone(EntryTime__c)) = :startDt];
    	System.assertEquals(updateLeads.size(), 1);
    	for (Lead__c lead :updateLeads) {
    		lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
    	}
    	update updateLeads;
    	
    	// ２泊目バッチ実行する
		bat.checkInDate = startDt.addDays(1).format();
    	bat.autoCheckInProcess();
    	msg1 = bat.message;
    	msg2 = bat.errMessage;
//    	System.assert(String.isEmpty(msg1), msg1);
    	System.assert(String.isEmpty(msg2), msg2);
//    	System.assert(msg2.contains(lead1Room2Night[0].Id), msg2);
    	// データは未自動チェックイン
    	for (Lead__c lead : [select Id, Field298__c,LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c from lead__c where id in :leadIdSet]) {
    		System.assert(!String.isEmpty(lead.Field298__c), lead);
    	}
    	Test.stopTest();
   }
    @isTest(SeeAllData=false)
   static void batchCheckInCheckTest2() {
		// チェックインする前に、予約データ関連のチェックインできるがどうかチェックを行う
		// １：1泊N部屋の予約データを作成する、BatchNroomsCheckInFlg__c=TRUEの場合: 自動チェックイン対象になる[]
		TestCommon.createCommDefine();
		CommDefine__c comDef = [select BatchNroomsCheckInFlg__c from CommDefine__c];
		comDef.BatchNroomsCheckInFlg__c = true;
		update comDef;
		Date startDt = Date.newInstance(2013, 10, 31);
		
		List<Lead__c> lead2Room1Night = TestCommon.createLead(startDt, 2, 1);
    	Set<Id> leadIdSet = new Set<Id>();
		for (Lead__c lead : lead2Room1Night) {leadIdSet.add(lead.Id);}
System.debug(LoggingLevel.INFO,'lead2Room1Night::' + lead2Room1Night);
System.debug(LoggingLevel.INFO, 'INDEX:' + [select id,Nights__c,Rooms__c,ParentLeadIndxRef__c  from LeadIndex__c  ]);
		Test.startTest();
		// 該当１泊目の予約データでバッチ実施[エラーなし]
		BulkProcessBatch bat = new BulkProcessBatch();
		bat.checkInDate = startDt.format();
    	bat.autoCheckInProcess();
    	String msg1 = bat.message;
    	String msg2 = bat.errMessage;
//    	System.assert(String.isEmpty(msg1), msg1);
    	System.assert(String.isEmpty(msg2), msg2);
    	// データは未自動チェックイン
    	for (Lead__c lead : [select Id, Field298__c,LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c from lead__c where id in:leadIdSet]) {
    		System.assert(String.isEmpty(lead.Field298__c), lead);
    	}
    	
    	// 1部屋の予約データはチェックインする場合、2部屋は自動バッチでチェックイン可能[BatchNroomsCheckInFlg__c=TRUEの場合]
    	List<Lead__c> updateLeads = [select id,Field298__c from Lead__c where DAY_ONLY(convertTimezone(EntryTime__c)) = :startDt limit 1];
    	System.assertEquals(updateLeads.size(), 1);
    	for (Lead__c lead :updateLeads) {
    		lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
    	}
    	update updateLeads;
System.debug(LoggingLevel.INFO,'----------------1-----------------');
    	// 関連部屋も自動チェックされる
		bat.checkInDate = startDt.format();
    	bat.autoCheckInProcess();
System.debug(LoggingLevel.INFO,'----------------2-----------------');
    	msg1 = bat.message;
    	msg2 = bat.errMessage;
//    	System.assert(String.isEmpty(msg1), msg1);
    	System.assert(String.isEmpty(msg2), msg2);
System.debug(LoggingLevel.INFO,'msg1::' + msg1);
System.debug(LoggingLevel.INFO,'msg2::' + msg2);
    	// データは未自動チェックイン
    	for (Lead__c lead : [select Id, Field298__c,LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c from lead__c where id in :leadIdSet]) {
    		System.assert(!String.isEmpty(lead.Field298__c), lead);
    	}
    	Test.stopTest();
   }
    @isTest(SeeAllData=false)
   static void batchCheckInCheckTest3() {
		// チェックインする前に、予約データ関連のチェックインできるがどうかチェックを行う
		// １：1泊N部屋の予約データを作成する、BatchNroomsCheckInFlg__c=FALSEの場合: 自動チェックイン対象外になる[]
		TestCommon.createCommDefine();
		CommDefine__c comDef = [select BatchNroomsCheckInFlg__c from CommDefine__c];
		comDef.BatchNroomsCheckInFlg__c = false;
		update comDef;
		Date startDt = Date.newInstance(2013, 10, 31);
		
		List<Lead__c> lead1Room2Night = TestCommon.createLead(startDt, 2, 1);
    	Set<Id> leadIdSet = new Set<Id>();
		for (Lead__c lead : lead1Room2Night) {leadIdSet.add(lead.Id);}
		
		Test.startTest();
		// 該当１泊目の予約データでバッチ実施[エラーなし]
		BulkProcessBatch bat = new BulkProcessBatch();
		bat.checkInDate = startDt.format();
    	bat.autoCheckInProcess();
    	String msg1 = bat.message;
    	String msg2 = bat.errMessage;
//    	System.assert(String.isEmpty(msg1), msg1);
    	System.assert(String.isEmpty(msg2), msg2);
    	// データは未自動チェックイン
    	for (Lead__c lead : [select Id, Field298__c,LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c from lead__c where id in:leadIdSet]) {
    		System.assert(String.isEmpty(lead.Field298__c), lead);
    	}
    	
    	// 1部屋の予約データはチェックインする場合、2部屋は自動バッチでチェックイン可能[BatchNroomsCheckInFlg__c=TRUEの場合]
    	List<Lead__c> updateLeads = [select id,Field298__c from Lead__c where DAY_ONLY(convertTimezone(EntryTime__c)) = :startDt limit 1];
    	System.assertEquals(updateLeads.size(), 1);
    	for (Lead__c lead :updateLeads) {
    		lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
    	}
    	update updateLeads;
    	
    	// ２泊目バッチ実行する
		bat.checkInDate = startDt.format();
    	bat.autoCheckInProcess();
    	msg1 = bat.message;
    	msg2 = bat.errMessage;
//    	System.assert(String.isEmpty(msg1), msg1);
    	System.assert(String.isEmpty(msg2), msg2);
    	// データは未自動チェックイン
    	List<Lead__c> noCheckinLst = [select Id, Field298__c,LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c from lead__c where id in :leadIdSet And Field298__c = null];
    	System.assertEquals(noCheckinLst.size(), 1,noCheckinLst);
    	Test.stopTest();
   }
    @isTest(SeeAllData=false)
   static void batchCheckInCheckTest4() {
		// チェックインする前に、予約データ関連のチェックインできるがどうかチェックを行う
		// １：2泊１部屋の予約データを作成する、該当部屋は1泊目の予約データは自動チェックインすると、自動チェックイン対象外になる
		Date startDt = Date.newInstance(2013, 10, 31);
		
		TestCommon.createCommDefine();
		CommDefine__c comDef = [select BatchNroomsCheckInFlg__c from CommDefine__c];
		comDef.BatchNroomsCheckInFlg__c = true;
		update comDef;
		
		List<Lead__c> lead2Room2Night = TestCommon.createLead(startDt, 2, 2);
    	Set<Id> leadIdSet = new Set<Id>();
		for (Lead__c lead : lead2Room2Night) {leadIdSet.add(lead.Id);}
		
		Test.startTest();
		// 該当１泊目の予約データでバッチ実施
		BulkProcessBatch bat = new BulkProcessBatch();
		bat.checkInDate = startDt.format();
    	bat.autoCheckInProcess();
    	String msg1 = bat.message;
    	String msg2 = bat.errMessage;
//    	System.assert(String.isEmpty(msg1), msg1);
    	System.assert(String.isEmpty(msg2), msg2);
    	// データは未自動チェックイン
    	for (Lead__c lead : [select Id, Field298__c,LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c from lead__c where id in:leadIdSet]) {
    		System.assert(String.isEmpty(lead.Field298__c), lead);
    	}
    	
    	// ２泊目バッチ実行する
		bat.checkInDate = startDt.addDays(1).format();
    	bat.autoCheckInProcess();
    	msg1 = bat.message;
    	msg2 = bat.errMessage;
//    	System.assert(String.isEmpty(msg1), msg1);
    	System.assert(!String.isEmpty(msg2), msg2);
    	System.assert(msg2.contains(lead2Room2Night[0].Id), msg2);
    	// データは未自動チェックイン
    	for (Lead__c lead : [select Id, Field298__c,LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c from lead__c where id in :leadIdSet]) {
    		System.assert(String.isEmpty(lead.Field298__c), lead);
    	}
    	/*
    	// 1泊目の予約データはチェックインする場合、2泊目は自動バッチでチェックイン可能
    	List<Lead__c> updateLeads = [select id,Field298__c from Lead__c where DAY_ONLY(convertTimezone(EntryTime__c)) = :startDt limit 1];
    	System.assertEquals(updateLeads.size(), 1);
    	for (Lead__c lead :updateLeads) {
    		lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
    	}
    	update updateLeads;
    	
		// 該当１泊目の予約データでバッチ実施[N部屋の自動チェックされる]
		bat.checkInDate = startDt.format();
    	bat.autoCheckInProcess();
    	msg1 = bat.message;
    	msg2 = bat.errMessage;
//    	System.assert(String.isEmpty(msg1), msg1);
    	System.assert(String.isEmpty(msg2), msg2);
    	// データは未自動チェックイン
    	for (Lead__c lead : [select Id, Field298__c,LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c from lead__c where id in:leadIdSet And DAY_ONLY(convertTimezone(EntryTime__c)) = :startDt ]) {
    		System.assert(!String.isEmpty(lead.Field298__c), lead);
    	}

    	// ２泊目バッチ実行する[全部自動チェックインされる]
		bat.checkInDate = startDt.addDays(1).format();
    	bat.autoCheckInProcess();
    	msg1 = bat.message;
    	msg2 = bat.errMessage;
//    	System.assert(String.isEmpty(msg1), msg1);
    	System.assert(String.isEmpty(msg2), msg2);
//    	System.assert(msg2.contains(lead1Room2Night[0].Id), msg2);
    	// データは未自動チェックイン
    	for (Lead__c lead : [select Id, Field298__c,LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c from lead__c where id in :leadIdSet]) {
    		System.assert(!String.isEmpty(lead.Field298__c), lead);
    	}*/
    	Test.stopTest();
   }
    @isTest(SeeAllData=false)
   static void batchCheckInCheckTest5() {
		// チェックインする前に、予約データ関連のチェックインできるがどうかチェックを行う
		// １：2泊１部屋の予約データを作成する、該当部屋は1泊目の予約データは自動チェックインすると、自動チェックイン対象外になる
		Date startDt = Date.newInstance(2013, 10, 31);
		
		TestCommon.createCommDefine();
		CommDefine__c comDef = [select BatchNroomsCheckInFlg__c from CommDefine__c];
		comDef.BatchNroomsCheckInFlg__c = true;
		update comDef;
		
		List<Lead__c> lead2Room2Night = TestCommon.createLead(startDt, 2, 2);
    	Set<Id> leadIdSet = new Set<Id>();
		for (Lead__c lead : lead2Room2Night) {leadIdSet.add(lead.Id);}
		
		// 該当１泊目の予約データでバッチ実施
		BulkProcessBatch bat = new BulkProcessBatch();
    	
    	// 1泊目の予約データはチェックインする場合、2泊目は自動バッチでチェックイン可能
    	List<Lead__c> updateLeads = [select id,Field298__c from Lead__c where DAY_ONLY(convertTimezone(EntryTime__c)) = :startDt limit 1];
    	System.assertEquals(updateLeads.size(), 1);
    	for (Lead__c lead :updateLeads) {
    		lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
    	}
    	update updateLeads;
    	
    	Test.startTest();
		// 該当１泊目の予約データでバッチ実施[N部屋の自動チェックされる]
		bat.checkInDate = startDt.format();
    	bat.autoCheckInProcess();
    	String msg1 = bat.message;
    	String msg2 = bat.errMessage;
//    	System.assert(String.isEmpty(msg1), msg1);
    	System.assert(String.isEmpty(msg2), msg2);
    	// データは未自動チェックイン
    	for (Lead__c lead : [select Id, Field298__c,LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c from lead__c where id in:leadIdSet And DAY_ONLY(convertTimezone(EntryTime__c)) = :startDt ]) {
    		System.assert(!String.isEmpty(lead.Field298__c), lead);
    	}

    	// ２泊目バッチ実行する[全部自動チェックインされる]
		bat.checkInDate = startDt.addDays(1).format();
    	bat.autoCheckInProcess();
    	msg1 = bat.message;
    	msg2 = bat.errMessage;
//    	System.assert(String.isEmpty(msg1), msg1);
    	System.assert(String.isEmpty(msg2), msg2);
//    	System.assert(msg2.contains(lead1Room2Night[0].Id), msg2);
    	// データは未自動チェックイン
    	for (Lead__c lead : [select Id, Field298__c,LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c from lead__c where id in :leadIdSet]) {
    		System.assert(!String.isEmpty(lead.Field298__c), lead);
    	}
    	Test.stopTest();
   }
}