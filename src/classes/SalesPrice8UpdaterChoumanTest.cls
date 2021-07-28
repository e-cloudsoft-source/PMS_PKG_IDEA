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
private class SalesPrice8UpdaterChoumanTest {

    // 2019/08/12 消費税は8%から10%に変更対応 WGCH BEGIN
    /*
    @isTest(SeeAllData=false)
	static void testCase1() {
		// ２０１４・０３・３０開始４連泊予約情報を設定する
		//Date startDt = Date.newInstance(2014,3,30);
		//Date changeDate = Date.newInstance(2014,4,1);
    	// 予約情報を作成する(4連泊予約情報を作成する)
    	// カスタム設定情報を区分２に設定をおこなう
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	// 単価処理区分は２の場合
    	comDef.UnitPriceDefKb__c = CommConst.APPOPTION_UTP_DEF_KB_OP2;
    	update comDef;
    	// 会計商品作成を行う
    	List<AccountMaster__c> prods = TestCommon.createProductMst(4);
    	// 単価再定義
    	prods[0].Field5__c = 1050;
    	prods[1].Field5__c = 10500;
    	prods[2].Field5__c = 105000;
    	prods[2].jmstRef__c = null;
    	prods[3].Field5__c = 0;
    	update prods;
    	Map<Id, Decimal> equalPriceMap = new Map<Id, Decimal>();
    	equalPriceMap.put(prods[0].Id, 1080);
    	equalPriceMap.put(prods[1].Id, 10800);
    	equalPriceMap.put(prods[2].Id, 105000);
    	equalPriceMap.put(prods[3].Id, 0);
    	
 		Test.startTest();
		SalesPrice8UpdaterChouman m = new SalesPrice8UpdaterChouman();
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
		// 単価再定義処理を行う
		SalesPrice8UpdaterChouman batch = new SalesPrice8UpdaterChouman(UserInfo.getUserId());
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		// 商品金額確認を行う
		List<AccountMaster__c> newProds = [select Id, Field5__c from AccountMaster__c where id in :equalPriceMap.keySet() limit 100];
		System.assertEquals(newProds.size(), 4, newProds);
		for (AccountMaster__c acc : newProds) {
			System.assertEquals(acc.Field5__c, equalPriceMap.get(acc.Id));
		}	
	}
	@isTest(SeeAllData=false)
	static void testCase2() {
		// ２０１４・０３・３０開始４連泊予約情報を設定する
		//Date startDt = Date.newInstance(2014,3,30);
		//Date changeDate = Date.newInstance(2014,4,1);
    	// 予約情報を作成する(4連泊予約情報を作成する)
    	// カスタム設定情報を区分２に設定をおこなう
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	// 単価処理区分は２の場合
    	comDef.UnitPriceDefKb__c = CommConst.APPOPTION_UTP_DEF_KB_OP3;
    	update comDef;
    	// 会計商品作成を行う
    	List<AccountMaster__c> prods = TestCommon.createProductMst(4);
    	// 単価再定義
    	prods[0].Field5__c = 1050;
    	prods[1].Field5__c = 10500;
    	prods[2].Field5__c = 105000;
    	prods[3].Field5__c = 0;
    	update prods;
    	Map<Id, Decimal> equalPriceMap = new Map<Id, Decimal>();
    	equalPriceMap.put(prods[0].Id, 1050);
    	equalPriceMap.put(prods[1].Id, 10500);
    	equalPriceMap.put(prods[2].Id, 105000);
    	equalPriceMap.put(prods[3].Id, 0);
    	
 		Test.startTest();
		SalesPrice8UpdaterChouman m = new SalesPrice8UpdaterChouman();
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
		// 単価再定義処理を行う
		SalesPrice8UpdaterChouman batch = new SalesPrice8UpdaterChouman(UserInfo.getUserId());
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		// 商品金額確認を行う
		List<AccountMaster__c> newProds = [select Id, Field5__c from AccountMaster__c where id in :equalPriceMap.keySet() limit 100];
		System.assertEquals(newProds.size(), 4, newProds);
		for (AccountMaster__c acc : newProds) {
			System.assertEquals(acc.Field5__c, equalPriceMap.get(acc.Id));
		}	
	}
	*/
	@isTest(SeeAllData=false)
	static void testCase3() {
		// ２０１４・０３・３０開始４連泊予約情報を設定する
		//Date startDt = Date.newInstance(2014,3,30);
		//Date changeDate = Date.newInstance(2014,4,1);
    	// 予約情報を作成する(4連泊予約情報を作成する)
    	// カスタム設定情報を区分２に設定をおこなう
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	// 単価処理区分は２の場合
    	comDef.UnitPriceDefKb__c = CommConst.APPOPTION_UTP_DEF_KB_OP2;
    	update comDef;
    	// 会計商品作成を行う
    	List<AccountMaster__c> prods = TestCommon.createProductMst_8(4);
    	// 単価再定義
    	prods[0].Field5__c = 1080;
    	prods[1].Field5__c = 10800;
    	prods[2].Field5__c = 108000;
    	prods[3].Field5__c = 0;
    	update prods;
    	Map<Id, Decimal> equalPriceMap = new Map<Id, Decimal>();
    	equalPriceMap.put(prods[0].Id, 1100);
    	equalPriceMap.put(prods[1].Id, 11000);
    	equalPriceMap.put(prods[2].Id, 110000);
    	equalPriceMap.put(prods[3].Id, 0);
    	
 		Test.startTest();
		SalesPrice8UpdaterChouman m = new SalesPrice8UpdaterChouman();
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
		// 単価再定義処理を行う
		SalesPrice8UpdaterChouman batch = new SalesPrice8UpdaterChouman(UserInfo.getUserId());
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		// 商品金額確認を行う
		List<AccountMaster__c> newProds = [select Id, Field5__c from AccountMaster__c where id in :equalPriceMap.keySet() limit 100];
		System.assertEquals(newProds.size(), 4, newProds);
		for (AccountMaster__c acc : newProds) {
			System.assertEquals(acc.Field5__c, equalPriceMap.get(acc.Id));
		}	
	}
	@isTest(SeeAllData=false)
	static void testCase3_1() {
		// ２０１４・０３・３０開始４連泊予約情報を設定する
		//Date startDt = Date.newInstance(2014,3,30);
		//Date changeDate = Date.newInstance(2014,4,1);
    	// 予約情報を作成する(4連泊予約情報を作成する)
    	// カスタム設定情報を区分２に設定をおこなう
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	// 単価処理区分は２の場合
    	comDef.UnitPriceDefKb__c = CommConst.APPOPTION_UTP_DEF_KB_OP1;
    	update comDef;
    	// 会計商品作成を行う
    	List<AccountMaster__c> prods = TestCommon.createProductMst_8(4);
    	// 単価再定義
    	prods[0].Field5__c = 1188;
    	prods[1].Field5__c = 11880;
    	prods[2].Field5__c = 118800;
    	prods[3].Field5__c = 0;
    	update prods;
    	Map<Id, Decimal> equalPriceMap = new Map<Id, Decimal>();
    	equalPriceMap.put(prods[0].Id, 1210);
    	equalPriceMap.put(prods[1].Id, 12100);
    	equalPriceMap.put(prods[2].Id, 121000);
    	equalPriceMap.put(prods[3].Id, 0);
    	
 		Test.startTest();
		SalesPrice8UpdaterChouman m = new SalesPrice8UpdaterChouman();
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
		// 単価再定義処理を行う
		SalesPrice8UpdaterChouman batch = new SalesPrice8UpdaterChouman(UserInfo.getUserId());
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		// 商品金額確認を行う
		List<AccountMaster__c> newProds = [select Id, Field5__c from AccountMaster__c where id in :equalPriceMap.keySet() limit 100];
		System.assertEquals(newProds.size(), 4, newProds);
		for (AccountMaster__c acc : newProds) {
			System.assertEquals(acc.Field5__c, equalPriceMap.get(acc.Id));
		}	
	}
	@isTest(SeeAllData=false)
	static void testCase4() {
		// ２０１４・０３・３０開始４連泊予約情報を設定する
		//Date startDt = Date.newInstance(2014,3,30);
		//Date changeDate = Date.newInstance(2014,4,1);
    	// 予約情報を作成する(4連泊予約情報を作成する)
    	// カスタム設定情報を区分２に設定をおこなう
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	// 単価処理区分は3の場合
    	comDef.UnitPriceDefKb__c = CommConst.APPOPTION_UTP_DEF_KB_OP3;
    	update comDef;
    	// 会計商品作成を行う
    	List<AccountMaster__c> prods = TestCommon.createProductMst_8(4);
    	// 単価再定義
    	prods[0].Field5__c = 1080;
    	prods[1].Field5__c = 10800;
    	prods[2].Field5__c = 108000;
    	prods[3].Field5__c = 0;
    	update prods;
    	Map<Id, Decimal> equalPriceMap = new Map<Id, Decimal>();
    	equalPriceMap.put(prods[0].Id, 1080);
    	equalPriceMap.put(prods[1].Id, 10800);
    	equalPriceMap.put(prods[2].Id, 108000);
    	equalPriceMap.put(prods[3].Id, 0);
    	
 		Test.startTest();
		SalesPrice8UpdaterChouman m = new SalesPrice8UpdaterChouman();
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
		// 単価再定義処理を行う
		SalesPrice8UpdaterChouman batch = new SalesPrice8UpdaterChouman(UserInfo.getUserId());
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		// 商品金額確認を行う
		List<AccountMaster__c> newProds = [select Id, Field5__c from AccountMaster__c where id in :equalPriceMap.keySet() limit 100];
		System.assertEquals(newProds.size(), 4, newProds);
		for (AccountMaster__c acc : newProds) {
			System.assertEquals(acc.Field5__c, equalPriceMap.get(acc.Id));
		}
	}
	@isTest(SeeAllData=false)
	static void testCase4_1() {
		// ２０１４・０３・３０開始４連泊予約情報を設定する
		//Date startDt = Date.newInstance(2014,3,30);
		//Date changeDate = Date.newInstance(2014,4,1);
    	// 予約情報を作成する(4連泊予約情報を作成する)
    	// カスタム設定情報を区分２に設定をおこなう
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	// 単価処理区分は3の場合
    	comDef.UnitPriceDefKb__c = CommConst.APPOPTION_UTP_DEF_KB_OP3;
    	update comDef;
    	// 会計商品作成を行う
    	List<AccountMaster__c> prods = TestCommon.createProductMst_8(4);
    	// 単価再定義
    	prods[0].Field5__c = 1080;
    	prods[1].Field5__c = 10800;
    	prods[2].Field5__c = 108000;
    	prods[3].Field5__c = 0;
    	update prods;
    	Map<Id, Decimal> equalPriceMap = new Map<Id, Decimal>();
    	equalPriceMap.put(prods[0].Id, 1080);
    	equalPriceMap.put(prods[1].Id, 10800);
    	equalPriceMap.put(prods[2].Id, 108000);
    	equalPriceMap.put(prods[3].Id, 0);
    	
 		Test.startTest();
		SalesPrice8UpdaterChouman m = new SalesPrice8UpdaterChouman();
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
		// 単価再定義処理を行う
		SalesPrice8UpdaterChouman batch = new SalesPrice8UpdaterChouman(UserInfo.getUserId());
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		// 商品金額確認を行う
		List<AccountMaster__c> newProds = [select Id, Field5__c from AccountMaster__c where id in :equalPriceMap.keySet() limit 100];
		System.assertEquals(newProds.size(), 4, newProds);
		for (AccountMaster__c acc : newProds) {
			System.assertEquals(acc.Field5__c, equalPriceMap.get(acc.Id));
		}
	}
	// 2019/08/12 消費税は8%から10%に変更対応 WGCH END
}