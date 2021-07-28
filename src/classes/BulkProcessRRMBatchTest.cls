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
private class BulkProcessRRMBatchTest {

    @isTest(SeeAllData=false)
	static void testCase1() {
		CommDefine__c comDef = TestCommon.createCommDefine();
		comDef.AccountSaleDateSetupDiv__c = '1';
		comDef.ScheduleResultMailAddress__c = 'aaa@bbb.ccc.com';
		update comDef; 
		Date startDt = Date.today();
    	// 予約情報を作成する[プラン付け]
    	Lead__c leadInfo = TestCommon.createLead(startDt);
    	// 商品情報を作成する
		// Normal商品
		List<AccountMaster__c> productLst = TestCommon.createProductMst(2);
		// 見積明細を作成する
    	TestCommon.createBookEstItems(leadInfo, productLst);
    	// 予約情報のステータス：チェックインに変更する
    	leadInfo.Field298__c = 'チェックイン完';
    	update leadInfo;
    	// 会計画面に動作確認を行う
    	List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfo.Id];
    	AccountAcount__c accObj = accObjLst[0];

    	ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
    	BillInput_Ctrl ctrl = new BillInput_Ctrl(contrl);
    	ctrl.initAction();
    	ctrl.calPaymentInfo();
    	ctrl.upsertData();
    	
    	List<AccountAcount__c> accLst = [select OutSideAccount__c, relaccount__c,SalesdayCal__c,Field147__c from AccountAcount__c where Relreserve__c = :leadInfo.Id];
    	System.assertEquals(accLst.size(), 1, accLst);
    	System.assertEquals(accLst[0].relaccount__c, leadInfo.Relcontact__c, accLst);
    	System.assertEquals(accLst[0].OutSideAccount__c, 1, accLst);

		Test.startTest();

		BulkProcessRRMBatch m = new BulkProcessRRMBatch();
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
		
		BulkProcessRRMBatch batch = new BulkProcessRRMBatch();
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		Contact cRs = [select Usage_Count__c,Usage_Charge__c,LastUsageDate__c From Contact where id = :leadInfo.Relcontact__c];
		System.assertEquals(cRs.Usage_Count__c, 1, cRs);
		System.assertEquals(cRs.Usage_Charge__c, accLst[0].Field147__c, cRs);
		System.assertEquals(cRs.LastUsageDate__c, leadInfo.EntryTime__c.date(), cRs);
	}
	//BulkProcessRRMBatch
	// 団体の場合、集計区分２、１来店１回利用回数計算するテスト
	@isTest(SeeAllData=false)
	static void testCase2() {
		Test.startTest();
		TestCommon.createBillSimpleHelpConfigDoc();
		CommDefine__c comDef = TestCommon.createCommDefine();
		comDef.AccountSaleDateSetupDiv__c = '1';
		comDef.ContactUsageCountDiv__c = '2';		// お客様利用回数集計区分:2：実際の来店回数で集計（N部屋N泊連泊でも、１回で集計する）
		comDef.ScheduleResultMailAddress__c = 'aaa@bbb.ccc.com';
		update comDef; 
		Integer nights = 3;
		Date startDt = Date.today().addDays(-1*nights);
    	// 予約情報を作成する[プラン付け]
    	List<Lead__c> leads = TestCommon.createLead(startDt, 2, nights);
    	leads[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
    	update leads[0];
    	// 集計計算を行う
		BulkProcessRRMBatch batch = new BulkProcessRRMBatch();
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		Contact cRs = [select Usage_Count__c,Usage_Charge__c,LastUsageDate__c From Contact where id = :leads[0].Relcontact__c];
		System.assertEquals(cRs.Usage_Count__c, 1, cRs);
		//System.assertEquals(cRs.Usage_Charge__c, accLst[0].Field147__c, cRs);
		//System.assertEquals(cRs.LastUsageDate__c, leadInfo.EntryTime__c.date(), cRs);
	}
	// 団体の場合、集計区分２、１来店１回利用回数計算するテスト
	@isTest(SeeAllData=false)
	static void testCase2_0() {
		TestCommon.createBillSimpleHelpConfigDoc();
		CommDefine__c comDef = TestCommon.createCommDefine();
		comDef.AccountSaleDateSetupDiv__c = '1';
		comDef.ContactUsageCountDiv__c = '2';		// お客様利用回数集計区分:2：実際の来店回数で集計（N部屋N泊連泊でも、１回で集計する）
		comDef.ScheduleResultMailAddress__c = 'aaa@bbb.ccc.com';
		comDef.RenpakuBatchCheckinIsCanFlg__c = false;
		update comDef; 
		Integer nights = 3;
		Date startDt = Date.today().addDays(-1*nights);
    	// 予約情報を作成する[プラン付け]
    	
    	List<Lead__c> leads = TestCommon.createLead(startDt, 2, nights);
    	Test.startTest();
    	List<Lead__c> leads2 = TestCommon.createLead(startDt, 2, nights, leads[0].Relcontact__c);
    	
    	List<Lead__c> updLeads = new List<Lead__c>();
    	leads[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
    	leads2[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
    	updLeads.add(leads[0]);
    	updLeads.add(leads2[0]);
    	update updLeads;
    	// 集計計算を行う
		BulkProcessRRMBatch batch = new BulkProcessRRMBatch();
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		Contact cRs = [select Usage_Count__c,Usage_Charge__c,LastUsageDate__c From Contact where id = :leads[0].Relcontact__c];
		System.assertEquals(cRs.Usage_Count__c, 2, cRs);
		
	}
	
	// 団体の場合、集計区分２、１来店１回利用回数計算するテスト[予約データはキャンセルされる場合]
	@isTest(SeeAllData=false)
	static void testCase2_1() {
		Test.startTest();
		CommDefine__c comDef = TestCommon.createCommDefine();
		comDef.AccountSaleDateSetupDiv__c = '1';
		comDef.ContactUsageCountDiv__c = '2';		// お客様利用回数集計区分:2：実際の来店回数で集計（N部屋N泊連泊でも、１回で集計する）
		comDef.ScheduleResultMailAddress__c = 'aaa@bbb.ccc.com';
		update comDef; 
		Integer nights = 3;
		Date startDt = Date.today().addDays(-1*nights);
    	// 予約情報を作成する[プラン付け]
    	List<Lead__c> leads = TestCommon.createLead(startDt, 2,nights);
    	for (Lead__c p : leads ) {
    		p.ReservedStatus__c = 'キャンセル';
    	}
    	update leads;
    	// 集計計算を行う
		BulkProcessRRMBatch batch = new BulkProcessRRMBatch();
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		Contact cRs = [select Usage_Count__c,Usage_Charge__c,LastUsageDate__c From Contact where id = :leads[0].Relcontact__c];
		System.assertEquals(CommUtils.nullToZero(cRs.Usage_Count__c), 0, cRs);
		//System.assertEquals(cRs.Usage_Charge__c, accLst[0].Field147__c, cRs);
		//System.assertEquals(cRs.LastUsageDate__c, leadInfo.EntryTime__c.date(), cRs);
	}
	// 団体の場合、集計区分２、１来店１回利用回数計算するテスト[予約データはキャンセルされる場合あり]
	@isTest(SeeAllData=false)
	static void testCase2_2() {
		CommDefine__c comDef = TestCommon.createCommDefine();
		comDef.AccountSaleDateSetupDiv__c = '1';
		comDef.ContactUsageCountDiv__c = '2';		// お客様利用回数集計区分:2：実際の来店回数で集計（N部屋N泊連泊でも、１回で集計する）
		comDef.ScheduleResultMailAddress__c = 'aaa@bbb.ccc.com';
		update comDef; 
		Integer nights = 3;
		Date startDt = Date.today().addDays(-1*nights);
    	// 予約情報を作成する[プラン付け]
    	List<Lead__c> leads = TestCommon.createLead(startDt, 2,nights);
    	Test.startTest();
    	for (Lead__c p : leads ) {
    		p.ReservedStatus__c = 'キャンセル';
    	}
    	update leads;
    	List<Lead__c> leads2 = TestCommon.createLead(startDt, 2,nights, leads[0].Relcontact__c);
    	leads2[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
    	update leads2[0];
    	// 集計計算を行う
		BulkProcessRRMBatch batch = new BulkProcessRRMBatch();
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		Contact cRs = [select Usage_Count__c,Usage_Charge__c,LastUsageDate__c From Contact where id = :leads[0].Relcontact__c];
		System.assertEquals(CommUtils.nullToZero(cRs.Usage_Count__c), 1, cRs);
	}
	// 団体の場合、集計区分２、１来店１回利用回数計算するテスト[予約データはキャンセルされる場合あり]
	@isTest(SeeAllData=false)
	static void testCase2_3() {
		CommDefine__c comDef = TestCommon.createCommDefine();
		comDef.AccountSaleDateSetupDiv__c = '1';
		comDef.ContactUsageCountDiv__c = '2';		// お客様利用回数集計区分:2：実際の来店回数で集計（N部屋N泊連泊でも、１回で集計する）
		comDef.ScheduleResultMailAddress__c = 'aaa@bbb.ccc.com';
		update comDef; 
		Integer nights = 3;
		Date startDt = Date.today().addDays(-1*nights);
    	// 予約情報を作成する[プラン付け]
    	List<Lead__c> leads = TestCommon.createLead(startDt, 2,nights);
    	Test.startTest();
    	List<Lead__c> leads2 = TestCommon.createLead(startDt, 2,nights, leads[0].Relcontact__c);
    	leads[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
    	//update leads[0];
    	leads2[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
    	//update leads2[0];
    	List<Lead__c> updLeads = new List<Lead__c>();
    	updLeads.add(leads[0]);
    	updLeads.add(leads2[0]);
    	update updLeads;
    	// 集計計算を行う
		BulkProcessRRMBatch batch = new BulkProcessRRMBatch();
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		Contact cRs = [select Usage_Count__c,Usage_Charge__c,LastUsageDate__c From Contact where id = :leads[0].Relcontact__c];
		System.assertEquals(CommUtils.nullToZero(cRs.Usage_Count__c), 2, cRs);
	}
	// 団体の場合、集計区分1、予約データ数が利用回数計算するテスト
	@isTest(SeeAllData=false)
	static void testCase3() {
		Test.startTest();
		CommDefine__c comDef = TestCommon.createCommDefine();
		comDef.AccountSaleDateSetupDiv__c = '1';
		comDef.ContactUsageCountDiv__c = '1';		// お客様利用回数集計区分:2：実際の来店回数で集計（N部屋N泊連泊でも、１回で集計する）
		comDef.ScheduleResultMailAddress__c = 'aaa@bbb.ccc.com';
		update comDef; 
		Integer nights = 3;
		Date startDt = Date.today().addDays(-1*nights);
    	// 予約情報を作成する[プラン付け]
    	List<Lead__c> leads = TestCommon.createLead(startDt, 2, nights);
    	for (Lead__c lead : leads) {
    		lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
    	}
    	update leads;
    	// 集計計算を行う
		BulkProcessRRMBatch batch = new BulkProcessRRMBatch();
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		Contact cRs = [select Usage_Count__c,Usage_Charge__c,LastUsageDate__c From Contact where id = :leads[0].Relcontact__c];
		System.assertEquals(cRs.Usage_Count__c, 6, cRs);
	}
	@isTest(SeeAllData=false)
	static void testCase3_1() {
		CommDefine__c comDef = TestCommon.createCommDefine();
		comDef.AccountSaleDateSetupDiv__c = '1';
		comDef.ContactUsageCountDiv__c = '1';		// お客様利用回数集計区分:2：実際の来店回数で集計（N部屋N泊連泊でも、１回で集計する）
		comDef.ScheduleResultMailAddress__c = 'aaa@bbb.ccc.com';
		update comDef; 
		Integer nights = 3;
		Date startDt = Date.today().addDays(-1*nights);
    	// 予約情報を作成する[プラン付け]
    	List<Lead__c> leads = TestCommon.createLead(startDt, 2, nights);
    	Test.startTest();
    	List<Lead__c> leads2 = TestCommon.createLead(startDt, 2,nights, leads[0].Relcontact__c);
    	
    	for (Lead__c lead : leads) {
    		lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
    	}
    	update leads;
    	for (Lead__c lead : leads2) {
    		lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
    	}
    	update leads2;
    	// 集計計算を行う
		BulkProcessRRMBatch batch = new BulkProcessRRMBatch();
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		Contact cRs = [select Usage_Count__c,Usage_Charge__c,LastUsageDate__c From Contact where id = :leads[0].Relcontact__c];
		System.assertEquals(cRs.Usage_Count__c, 12, cRs);
	}
}