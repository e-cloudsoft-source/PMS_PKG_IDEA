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
@isTest(seeAllData = false) 
private class BulkProcessScheduleTest {
	// 指定の時間範囲チェックを行う
    static testMethod void ScheduleHHCheck_1() {
        // カスタム設定情報により、支店情報コードがNULLの場合、カスタム設定から取得する
        TestCommon.createCommDefine();
        CommDefine__c def = [select ExchangeRateStartHours__c from CommDefine__c];
        def.ExchangeRateStartHours__c = -1;
        update def;
        Boolean errFlg = false;
        Test.startTest();
    	BulkProcessSchedule m = new BulkProcessSchedule();
    	String sch = getScheduleTime();
    	System.schedule('AAAA', sch, m);
        Test.stopTest();
        System.assertEquals(errFlg, false);
    }
	// 指定の時間範囲チェックを行う
    static testMethod void ScheduleHHCheck_2() {
    	Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl());
        // カスタム設定情報により、支店情報コードがNULLの場合、カスタム設定から取得する
        TestCommon.createCommDefine();
        CommDefine__c def = [select ExchangeRateStartHours__c from CommDefine__c];
        def.ExchangeRateStartHours__c = 0;
        update def;
        Boolean errFlg = false;
        Test.startTest();
    	BulkProcessSchedule m = new BulkProcessSchedule();
    	String sch = getScheduleTime();
    	System.schedule('AAAA', sch, m);
        Test.stopTest();
        System.assertEquals(errFlg, false);
    }
    
    
    // 為替レート取得スケジュール内容チェックする
    // 
    static testMethod void FinanceXchangeServiceCheck_1() {
    	Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl());

        FinanceXchangeService m = new FinanceXchangeService();
    	String sch = getScheduleTime();
        // 2015/12/01 Assert BEGIN
        System.assertEquals(sch != null, true);
        // 2015/12/01 Assert END

    	System.schedule('AAAA', sch, m);

    }
    // 為替レート取得
    static testMethod void FinanceXchangeServiceCheck_2() {
    	Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl());
		
        TestCommon.createCommDefine();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from CommDefine__c].size(), 1);
        // 2015/12/01 Assert END
        CommDefine__c def = [select ExchangeRateStartHours__c,ScheduleResultMailAddress__c from CommDefine__c];
        def.ExchangeRateStartHours__c = 0;
        def.ScheduleResultMailAddress__c = 'ABCCC@XXXsss.com.abc';
        update def;
    	Test.startTest();
        FinanceXchangeService.setExchangeRate('USD', 'JPY', Date.today());
        Test.stopTest();
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

   static testMethod void BulkProcessSchedule_1_case1(){
   	
   		Test.startTest();
   		BulkProcessSchedule_1 m = new BulkProcessSchedule_1();
		DateTime nowTime = DateTime.now().addSeconds(100);
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
		Test.stopTest();
		System.assert(jobId != null);
   }
   
   static testMethod void BulkProcessSchedule_2_case1(){
		createConfigDoc();
   		Test.startTest();
   		BulkProcessSchedule_2 m = new BulkProcessSchedule_2();
		DateTime nowTime = DateTime.now().addSeconds(100);
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
		Test.stopTest();
		System.assert(jobId != null);
	}
	static testMethod void bulkProcessScheduleTestCase() {
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'AccountingSyncBatchConfig'].size(), 1);
        // 2015/12/01 Assert END

        RsvAccount__c rsv = createRsvAccount();
        CommDefine__c comDef = TestCommon.createCommDefine();
        comDef.ScheduleResultMailAddress__c = '111@aaa.com';
        comDef.SchedulePcaResultSendType__c = '2';
        comDef.SchedulePcaDeviationDays__c = 0;
        update comDef;

        Test.startTest();

        BulkProcessSchedule_2 bppb = new BulkProcessSchedule_2(date.today());
        DateTime nowTime = DateTime.now().addSeconds(100);
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
        String jobId = system.schedule(jobName, sch, bppb);
        Test.stopTest();
    }

    private static void createConfigDoc() {
        String configXml = '<?xml version="1.0" encoding="utf-8"?><root><SHOP><SHOPCODE></SHOPCODE><RESULT_MAIL>xxxx.test@testabc.com</RESULT_MAIL></SHOP></root>';
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
    private static RsvAccount__c createRsvAccount() {
        RsvAccount__c rsv = createSimpleRsvAccount();
        createAccount();
        return rsv;
    }
    private static RsvAccount__c createSimpleRsvAccount() {
        RsvAccount__c item = new RsvAccount__c();
        item.name = DateTime.now().format('yyyyMMdd');
        upsert item name;
        return item;
    }
    private static void createAccount() {
        // 商品作成する
        List<AccountMaster__c> prodList = TestCommon.createProductMst(1);
        SimpleAccountsCtrl ctrl = new SimpleAccountsCtrl();
        ctrl.mediaType = ctrl.mediaTypeOptionLst[1].getValue();
        ctrl.otran.Field20__c = '16000';
        ctrl.otran.Field21__c = '2';
        ctrl.otran.Field7__c = prodList[0].Id;
        ctrl.otran.ActionType__c = prodList[0].ActionType__c;
        ctrl.otran.TaxRate__c = prodList[0].TaxRateCal__c;
        ctrl.otran.ServiceRate__c = prodList[0].ServiceRate__c;
        ctrl.otran.SpecialTax__c = 200;
        ctrl.productNm = prodList[0].Name;
        ctrl.saveTranToMemory();
        ctrl.upsertData();
    }
}