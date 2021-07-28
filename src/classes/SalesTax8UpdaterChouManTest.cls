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
private class SalesTax8UpdaterChouManTest {
    // 2019/08/12 消費税は8%から10%に変更対応 WGCH BEGIN
    /*
    @isTest(SeeAllData=false)
	static void testCase1() {
		CommDefine__c comDef = TestCommon.createCommDefine();
		comDef.UnitPriceDefKb__c = 2;
		update comDef; 
		// ２０１４・０３・３０開始４連泊予約情報を設定する
		Date startDt = Date.newInstance(2014,3,30);
		Date changeDate = Date.newInstance(2014,4,1);
    	// 予約情報を作成する(4連泊予約情報を作成する)
    	List<Lead__c> leadInfos = TestCommon.createLead(startDt, 1, 4);
		// 見積もり明細情報を更新を行う（消費税マスタは５％のまま、更新する場合、2014/04/01以後の見積もり明細の消費税率は全部８％に変更されるの確認
		List<BookingEstimateItem__c> confirms = [select Id, TaxRate__c from BookingEstimateItem__c where TaxRate__c > 0];
		Integer oneDateDetails = confirms.size() / 4;
		Test.startTest();
		SalesTax8UpdaterChouMan m = new SalesTax8UpdaterChouMan();
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
		String jobName = DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, sch, m);
		
		SalesTax8UpdaterChouMan batch = new SalesTax8UpdaterChouMan(UserInfo.getUserId());
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		List<BookingEstimateItem__c> items = [select Id, TaxRate__c from BookingEstimateItem__c where DAY_ONLY(convertTimezone(refBooking__r.EntryTime__c)) >= :changeDate];
		// 全部明細件数を計算する
		System.assertEquals(items.size(), oneDateDetails * 2);
		for (BookingEstimateItem__c item : items) {
			system.assertEquals(item.TaxRate__c, 8, item);
		}
	}
	*/
	@isTest(SeeAllData=false)
	static void testCase2() {
		CommDefine__c comDef = TestCommon.createCommDefine();
		comDef.UnitPriceDefKb__c = 2;
		update comDef; 
		// ２０１４・０３・３０開始４連泊予約情報を設定する
		Date startDt = Date.newInstance(2019,9,29);
		Date changeDate = Date.newInstance(2019,10,1);
    	// 予約情報を作成する(4連泊予約情報を作成する)
    	List<Lead__c> leadInfos = TestCommon.createLead(startDt, 1, 4);
		// 見積もり明細情報を更新を行う（消費税マスタは５％のまま、更新する場合、2014/04/01以後の見積もり明細の消費税率は全部８％に変更されるの確認
		List<BookingEstimateItem__c> confirms = [select Id, TaxRate__c from BookingEstimateItem__c where TaxRate__c > 0];
		Integer oneDateDetails = confirms.size() / 4;
		Test.startTest();
		SalesTax8UpdaterChouMan m = new SalesTax8UpdaterChouMan();
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
		String jobName = DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, sch, m);
		
		SalesTax8UpdaterChouMan batch = new SalesTax8UpdaterChouMan(UserInfo.getUserId());
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		List<BookingEstimateItem__c> items = [select Id, TaxRate__c from BookingEstimateItem__c where DAY_ONLY(convertTimezone(refBooking__r.EntryTime__c)) >= :changeDate];
		// 全部明細件数を計算する
		System.assertEquals(items.size(), oneDateDetails * 2);
		for (BookingEstimateItem__c item : items) {
			system.assertEquals(item.TaxRate__c, 10, item);
		}
	}
	// 2019/08/12 消費税は8%から10%に変更対応 WGCH END
	// 2019/09/17 消費税は8%から10%に変更対応 WSQ BEGIN(総金額そのまま、単価を自動調整バッチ) BEGIN
	@isTest(SeeAllData=false)
	static void testCase3_1() {
		// 単価定義区分が1
		CommDefine__c comDef = TestCommon.createCommDefine();
		comDef.UnitPriceDefKb__c = 1;
		comdef.AutoCreateBookingEstFlg__c = false;
		update comDef; 
		// ２０１４・０３・３０開始４連泊予約情報を設定する
		Date startDt = Date.newInstance(2019,10,1);
		// プラン作成する
		// ご予約と見積もり作成
    	// 予約情報を作成する(4連泊予約情報を作成する)
    	List<Lead__c> leadInfos = TestCommon.createLead2IncRoomRate(startDt, 1, 3,null);
		List<BookingEstimateItem__c> confirms = [select Id, TaxRate__c,UnitPrice__c,Total__c from BookingEstimateItem__c where TaxRate__c > 0 order by name];	
system.debug(loggingLevel.info, 'confirms[BEG]='+confirms);
		map<id, BookingEstimateItem__c> existMap = new map<id, BookingEstimateItem__c>();
		for (BookingEstimateItem__c est : confirms) {
			existMap.put(est.id, est);
		}
		for(Lead__c ld : leadInfos){
			ld.Field298__c = 'チェックイン完';
		}
    	update leadInfos;
		// ================== 更新処理 ================== 
		Test.startTest();
		SalesTax8UpdaterChouMan2 m = new SalesTax8UpdaterChouMan2();
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
		String jobName = DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, sch, m);
	
		SalesTax8UpdaterChouMan2 batch = new SalesTax8UpdaterChouMan2(UserInfo.getUserId());
		ID batchprocessid = Database.executeBatch(batch);
		
		Test.stopTest();
		// ================== 更新処理 ================== 

		List<BookingEstimateItem__c> confirms2 = [select Id, TaxRate__c,UnitPrice__c,Total__c,ParentBookingItemRef__c,SpecialTax__c,UnitPriceDefKb__c from BookingEstimateItem__c 
			where TaxRate__c > 0 
			//and ParentBookingItemRef__c = null
			order by name];			
		system.debug(logginglevel.info, 'confirms2='+confirms2);
		for (BookingEstimateItem__c nw : confirms2) {
			BookingEstimateItem__c org = existMap.get(nw.id);
			system.assert(nw.TaxRate__c == 10, nw);
			system.assert(nw.Total__c == org.Total__c, nw);
		}
	}
	@isTest(SeeAllData=false)
	static void testCase3_2() {
		// 単価定義区分が２
		CommDefine__c comDef = TestCommon.createCommDefine();
		comDef.UnitPriceDefKb__c = 2;
		comdef.AutoCreateBookingEstFlg__c = false;
		update comDef; 
		// ２０１４・０３・３０開始４連泊予約情報を設定する
		Date startDt = Date.newInstance(2019,10,1);
		// プラン作成する
		// ご予約と見積もり作成
    	// 予約情報を作成する(4連泊予約情報を作成する)
    	List<Lead__c> leadInfos = TestCommon.createLead2IncRoomRate(startDt, 1, 3,null);
		List<BookingEstimateItem__c> confirms = [select Id, TaxRate__c,UnitPrice__c,Total__c from BookingEstimateItem__c where TaxRate__c > 0 order by name];	
system.debug(loggingLevel.info, 'confirms[BEG]='+confirms);
		map<id, BookingEstimateItem__c> existMap = new map<id, BookingEstimateItem__c>();
		for (BookingEstimateItem__c est : confirms) {
			existMap.put(est.id, est);
		}
		for(Lead__c ld : leadInfos){
			ld.Field298__c = 'チェックイン完';
		}
    	update leadInfos;
		// ================== 更新処理 ================== 
		Test.startTest();
		SalesTax8UpdaterChouMan2 m = new SalesTax8UpdaterChouMan2();
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
		String jobName = DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, sch, m);
	
		SalesTax8UpdaterChouMan2 batch = new SalesTax8UpdaterChouMan2(UserInfo.getUserId());
		ID batchprocessid = Database.executeBatch(batch);
		
		Test.stopTest();
		// ================== 更新処理 ================== 

		List<BookingEstimateItem__c> confirms2 = [select Id, TaxRate__c,UnitPrice__c,Total__c,ParentBookingItemRef__c,SpecialTax__c,UnitPriceDefKb__c from BookingEstimateItem__c 
			where TaxRate__c > 0 
			//and ParentBookingItemRef__c = null
			order by name];		
		system.debug(logginglevel.info, 'confirms2='+confirms2);
		for (BookingEstimateItem__c nw : confirms2) {
			BookingEstimateItem__c org = existMap.get(nw.id);
			system.assert(nw.TaxRate__c == 10, nw);
			system.assert(nw.Total__c == org.Total__c, nw);
		}
	}
	
	@isTest(SeeAllData=false)
	static void testCase3_3() {
		// 単価定義区分が3
		CommDefine__c comDef = TestCommon.createCommDefine();
		comDef.UnitPriceDefKb__c = 3;
		comdef.PDDetailsInputDefaultLines__c = 10;
		comdef.AutoCreateBookingEstFlg__c = false;
		update comDef; 
		// ２０１４・０３・３０開始４連泊予約情報を設定する
		Date startDt = Date.newInstance(2019,10,1);
		// プラン作成する
		// ご予約と見積もり作成
    	// 予約情報を作成する(4連泊予約情報を作成する)
    	List<Lead__c> leadInfos = TestCommon.createLead2IncRoomRate(startDt, 1, 3,null);
		List<BookingEstimateItem__c> confirms = [select Id, TaxRate__c,UnitPrice__c,Total__c from BookingEstimateItem__c 
			where TaxRate__c > 0 
			and ParentBookingItemRef__c = null
			order by name];	
system.debug(loggingLevel.info, 'confirms[BEG]='+confirms);
		map<id, BookingEstimateItem__c> existMap = new map<id, BookingEstimateItem__c>();
		for (BookingEstimateItem__c est : confirms) {
			existMap.put(est.id, est);
		}
		for(Lead__c ld : leadInfos){
			ld.Field298__c = 'チェックイン完';
		}
    	update leadInfos;
		// ================== 更新処理 ================== 
		Test.startTest();
		SalesTax8UpdaterChouMan2 m = new SalesTax8UpdaterChouMan2();
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
		String jobName = DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, sch, m);
	
		SalesTax8UpdaterChouMan2 batch = new SalesTax8UpdaterChouMan2(UserInfo.getUserId());
		ID batchprocessid = Database.executeBatch(batch);
		
		Test.stopTest();
		// ================== 更新処理 ================== 

		List<BookingEstimateItem__c> confirms2 = [select Id, TaxRate__c,UnitPrice__c,Total__c,ParentBookingItemRef__c,SpecialTax__c,UnitPriceDefKb__c from BookingEstimateItem__c 
			where TaxRate__c > 0 
			and ParentBookingItemRef__c = null
			order by name];	
		system.debug(logginglevel.info, 'confirms2='+confirms2);
		for (BookingEstimateItem__c nw : confirms2) {
			BookingEstimateItem__c org = existMap.get(nw.id);
			system.assert(nw.TaxRate__c == 10, nw);
			system.assert(nw.Total__c == org.Total__c, nw.Total__c+'='+org.Total__c);
		}
	}
	
	@isTest(SeeAllData=false)
	static void testCase3_4() {
		// 単価定義区分が4
		CommDefine__c comDef = TestCommon.createCommDefine();
		comDef.UnitPriceDefKb__c = 4;
		comdef.PDDetailsInputDefaultLines__c = 10;
		comdef.AutoCreateBookingEstFlg__c = false;
		update comDef; 
		// ２０１４・０３・３０開始４連泊予約情報を設定する
		Date startDt = Date.newInstance(2019,10,1);
		// プラン作成する
		// ご予約と見積もり作成
    	// 予約情報を作成する(4連泊予約情報を作成する)
    	List<Lead__c> leadInfos = TestCommon.createLead2IncRoomRate(startDt, 1, 3,null);
		List<BookingEstimateItem__c> confirms = [select Id, TaxRate__c,UnitPrice__c,Total__c from BookingEstimateItem__c 
			where TaxRate__c > 0 
			and ParentBookingItemRef__c = null
			order by name];	
system.debug(loggingLevel.info, 'confirms[BEG]='+confirms);
		map<id, BookingEstimateItem__c> existMap = new map<id, BookingEstimateItem__c>();
		for (BookingEstimateItem__c est : confirms) {
			existMap.put(est.id, est);
		}
		for(Lead__c ld : leadInfos){
			ld.Field298__c = 'チェックイン完';
		}
    	update leadInfos;
		// ================== 更新処理 ================== 
		Test.startTest();
		SalesTax8UpdaterChouMan2 m = new SalesTax8UpdaterChouMan2();
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
		String jobName = DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, sch, m);
	
		SalesTax8UpdaterChouMan2 batch = new SalesTax8UpdaterChouMan2(UserInfo.getUserId());
		ID batchprocessid = Database.executeBatch(batch);
		
		Test.stopTest();
		// ================== 更新処理 ================== 

		List<BookingEstimateItem__c> confirms2 = [select Id, TaxRate__c,UnitPrice__c,Total__c,ParentBookingItemRef__c,SpecialTax__c,UnitPriceDefKb__c from BookingEstimateItem__c 
			where TaxRate__c > 0 
			and ParentBookingItemRef__c = null
			order by name];	
		system.debug(logginglevel.info, 'confirms2='+confirms2);
		for (BookingEstimateItem__c nw : confirms2) {
			BookingEstimateItem__c org = existMap.get(nw.id);
			system.assert(nw.TaxRate__c == 10, nw);
			system.assert(nw.Total__c == org.Total__c, nw.Total__c+'='+org.Total__c);
		}
	}
	
	
	@isTest(SeeAllData=false)
	static void testCase4_1() {
		// 単価定義区分が4
		CommDefine__c comDef = TestCommon.createCommDefine();
		comDef.UnitPriceDefKb__c = 4;
		comdef.PDDetailsInputDefaultLines__c = 10;
		comdef.AutoCreateBookingEstFlg__c = false;
		update comDef; 
		// ２０１４・０３・３０開始４連泊予約情報を設定する
		Date startDt = Date.newInstance(2019,10,1);
		// プラン作成する
		// ご予約と見積もり作成
    	// 予約情報を作成する(4連泊予約情報を作成する)
    	List<Lead__c> leadInfos = TestCommon.createLead2IncRoomRate(startDt, 1, 3,createLocSingePlanIncRoom());
		List<BookingEstimateItem__c> confirms = [select Id, TaxRate__c,UnitPrice__c,Total__c from BookingEstimateItem__c 
			where TaxRate__c > 0 
			//and ParentBookingItemRef__c = null
			order by name];	
system.debug(loggingLevel.info, 'confirms[BEG]='+confirms);
		map<id, BookingEstimateItem__c> existMap = new map<id, BookingEstimateItem__c>();
		for (BookingEstimateItem__c est : confirms) {
			existMap.put(est.id, est);
		}
		for(Lead__c ld : leadInfos){
			ld.Field298__c = 'チェックイン完';
		}
    	update leadInfos;
		// ================== 更新処理 ================== 
		Test.startTest();
		SalesTax8UpdaterChouMan2 m = new SalesTax8UpdaterChouMan2();
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
		String jobName = DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, sch, m);
	
		SalesTax8UpdaterChouMan2 batch = new SalesTax8UpdaterChouMan2(UserInfo.getUserId());
		ID batchprocessid = Database.executeBatch(batch);
		
		Test.stopTest();
		// ================== 更新処理 ================== 

		List<BookingEstimateItem__c> confirms2 = [select Id, TaxRate__c,UnitPrice__c,Total__c,ParentBookingItemRef__c,SpecialTax__c,UnitPriceDefKb__c from BookingEstimateItem__c 
			where TaxRate__c > 0 
			//and ParentBookingItemRef__c = null
			order by name];	
		system.debug(logginglevel.info, 'confirms2='+confirms2);
		for (BookingEstimateItem__c nw : confirms2) {
			BookingEstimateItem__c org = existMap.get(nw.id);
			system.assert(nw.TaxRate__c == 10, nw);
			system.assert(nw.Total__c == org.Total__c, nw.Total__c+'='+org.Total__c);
		}
	}
	
	@isTest(SeeAllData=false)
	static void testCase5_1() {
		// プラン明細に室料が非存在場合
		// 単価定義区分が3
		CommDefine__c comDef = TestCommon.createCommDefine();
		comDef.UnitPriceDefKb__c = 3;
		comdef.PDDetailsInputDefaultLines__c = 10;
		comdef.AutoCreateBookingEstFlg__c = false;
		update comDef; 
		// ２０１４・０３・３０開始４連泊予約情報を設定する
		Date startDt = Date.newInstance(2019,10,1);
		// プラン作成する
		// ご予約と見積もり作成
    	// 予約情報を作成する(4連泊予約情報を作成する)
    	List<Lead__c> leadInfos = TestCommon.createLead2IncRoomRate(startDt, 1, 3,createLocPlanIncRoom());
		List<BookingEstimateItem__c> confirms = [select Id, TaxRate__c,UnitPrice__c,Total__c from BookingEstimateItem__c 
			where TaxRate__c > 0 
			//and ParentBookingItemRef__c = null
			order by name];	
system.debug(loggingLevel.info, 'confirms[BEG]='+confirms);
		map<id, BookingEstimateItem__c> existMap = new map<id, BookingEstimateItem__c>();
		for (BookingEstimateItem__c est : confirms) {
			existMap.put(est.id, est);
		}
		for(Lead__c ld : leadInfos){
			ld.Field298__c = 'チェックイン完';
		}
    	update leadInfos;
		// ================== 更新処理 ================== 
		Test.startTest();
		SalesTax8UpdaterChouMan2 m = new SalesTax8UpdaterChouMan2();
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
		String jobName = DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, sch, m);
	
		SalesTax8UpdaterChouMan2 batch = new SalesTax8UpdaterChouMan2(UserInfo.getUserId());
		ID batchprocessid = Database.executeBatch(batch);
		
		Test.stopTest();
		// ================== 更新処理 ================== 

		List<BookingEstimateItem__c> confirms2 = [select Id, TaxRate__c,UnitPrice__c,Total__c,ParentBookingItemRef__c,SpecialTax__c,UnitPriceDefKb__c from BookingEstimateItem__c 
			where TaxRate__c > 0 
			//and ParentBookingItemRef__c = null
			order by name];	
		system.debug(logginglevel.info, 'confirms2='+confirms2);
		List<BookingEstimateItem__c> books = [select id,refAccountMaster__c from BookingEstimateItem__c where ActionType__c ='プラン' and ParentBookingItemRef__c = null ];
		if (!books.isEmpty()) {
			books[0].TaxRate__c = 10;
			books[0].BatchProcessStatusDiv__c = '2';
			books[0].PlanDetailSyncInfo__c = books[0].refAccountMaster__c + ':' + 1000 + ':' + books[0].refAccountMaster__c + ':abc' + ';';
			update books[0]; 
		}
		SalesTax8UpdaterChouMan3 schedult = new SalesTax8UpdaterChouMan3(UserUtil.CurrentUserInfo.u.id);
        
		jobName = 'SalesTax8UpdaterChouMan3_' + DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		jobId = system.schedule(jobName, sch, schedult);

		SalesTax8UpdaterChouMan3 batch1 = new SalesTax8UpdaterChouMan3();
        DataBase.executeBatch(batch1,50);
		List<Tran1__c> tran1s = [select id,Field7__c from Tran1__c where ActionType__c ='プラン' and ParentTran1Ref__c = null ];
		if (!tran1s.isEmpty()) {
			tran1s[0].TaxRate__c = 10;
			tran1s[0].BatchProcessStatusDiv__c = '2';
			tran1s[0].PlanDetailSyncInfo__c = tran1s[0].Field7__c + ':' + 1000 + ':' + tran1s[0].Field7__c + ':abc' + ';';
			update tran1s[0]; 
		}
		batch1 = new SalesTax8UpdaterChouMan3();
		batch1.currentStatus = 'tran1';
        DataBase.executeBatch(batch1,50);
		SalesTax8UpdaterChouMan2 batch3 = new SalesTax8UpdaterChouMan2(UserInfo.getUserId());
		batch3.currentStatus = '3';
		batchprocessid = Database.executeBatch(batch3);
	}
	// 2019/09/17 消費税は8%から10%に変更対応 WSQ BEGIN(総金額そのまま、単価を自動調整バッチ) END
	
	
    public static Plan__c createLocPlanIncRoom() {
    	JMST__c taxMst =  TestCommon.createTaxMst_8();
    	Plan__c plan = new Plan__c();
    	plan.name = 'テストプランデータ' + CommUtils.getRandom(5);
    	plan.PlanNo__c = CommUtils.getRandom(10);
    	plan.Price__c = 35000;
    	plan.PackageCode__c = 'PK_'+CommUtils.getRandom(10);
    	plan.JmstRef__c = taxMst.Id;
    	plan.ServiceRate__c = 10;
    	plan.PlanStartDateandtime__c = Date.newInstance(2000,1,1);
    	plan.Planclosedateandtime__c = Date.newInstance(2999,1,1);
    	insert plan;
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(3);
        AccountMaster__c roomProductItem = TestCommon.createRoomProductMst();
        ApexPages.StandardController contrl = new ApexPages.StandardController(plan);
        PlanProductSetup ctrl = new PlanProductSetup(contrl);
        List<PlanProductSetup.PlanDetail> planDeLst = ctrl.planDetailList;
        planDeLst[0].productNm = productLst[0].Name;
        planDeLst[0].sobj.AccountMasterRef__c = productLst[0].Id;
        planDeLst[0].sobj.Price__c = 10000;
        planDeLst[0].sobj.ServiceRate__c = 10;
        planDeLst[0].sobj.taxRate__c = taxMst.taxRate__c;
        planDeLst[1].productNm = productLst[1].Name;
        planDeLst[1].sobj.AccountMasterRef__c = productLst[1].Id;
        planDeLst[1].sobj.Price__c = 20000;
        planDeLst[1].sobj.ServiceRate__c = 10;
        planDeLst[1].sobj.taxRate__c = taxMst.taxRate__c;
        planDeLst[2].productNm = productLst[2].Name;
        planDeLst[2].sobj.AccountMasterRef__c = productLst[2].Id;
        planDeLst[2].sobj.Price__c = 5000;
        planDeLst[2].sobj.ServiceRate__c = 10;
        planDeLst[2].sobj.taxRate__c = taxMst.taxRate__c;
        ctrl.savePlanDetail();
    	return plan;
    }
    // 1明細のプラン
    public static Plan__c createLocSingePlanIncRoom() {
    	JMST__c taxMst =  TestCommon.createTaxMst_8();
    	Plan__c plan = new Plan__c();
    	plan.name = 'テストプランデータ' + CommUtils.getRandom(5);
    	plan.PlanNo__c = CommUtils.getRandom(10);
    	plan.Price__c = 10000;
    	plan.PackageCode__c = 'PK_'+CommUtils.getRandom(10);
    	plan.JmstRef__c = taxMst.Id;
    	plan.ServiceRate__c = 10;
    	plan.PlanStartDateandtime__c = Date.newInstance(2000,1,1);
    	plan.Planclosedateandtime__c = Date.newInstance(2999,1,1);
    	insert plan;
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(3);
        AccountMaster__c roomProductItem = TestCommon.createRoomProductMst();
        ApexPages.StandardController contrl = new ApexPages.StandardController(plan);
        PlanProductSetup ctrl = new PlanProductSetup(contrl);
        List<PlanProductSetup.PlanDetail> planDeLst = ctrl.planDetailList;
        planDeLst[0].productNm = productLst[0].Name;
        planDeLst[0].sobj.AccountMasterRef__c = productLst[0].Id;
        planDeLst[0].sobj.Price__c = 10000;
        planDeLst[0].sobj.ServiceRate__c = 10;
        planDeLst[0].sobj.taxRate__c = taxMst.taxRate__c;
        ctrl.savePlanDetail();
    	return plan;
    }
}