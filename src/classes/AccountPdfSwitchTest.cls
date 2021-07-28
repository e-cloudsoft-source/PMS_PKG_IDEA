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
private class AccountPdfSwitchTest {

	static testMethod void accountPdfSwitch() {
    	Test.startTest();
    	// 店舗情報を初期化する
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	comDef.FacilityCode__c = '3';
    	update comDef;
		User currUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	currUser.ShopCode__c = null;
    	update currUser;
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	// 予約情報のステータス：チェックインに変更する
    	leadInfo.Field298__c = 'チェックイン完';
    	update leadInfo;

    	Test.stopTest();

    	// 会計画面に動作確認を行う
    	List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfo.Id];
    	AccountAcount__c accObj = accObjLst[0];
    	ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
    	BillInput_Ctrl ctrl = new BillInput_Ctrl(contrl);
    	ctrl.initAction();
    	ctrl.calPaymentInfo();
    	ctrl.upsertData();

    	ApexPages.StandardController contrl1 = new ApexPages.StandardController(accObj);
    	AccountPdfSwitch ctrl1 = new AccountPdfSwitch(contrl1);
    	ctrl1.AccAcountsSelectorInit();
		PageReference refPage = ctrl1.redirect();
		String strUrl = refPage.getUrl();
		system.assert(strUrl.contains('AccountPDF_3'), strUrl);
    	//ctrl1.termStartDt = DateTime.newInstance(Date.today()-10, Time.newInstance(0, 0, 0, 0)).format('yyyy/MM/dd');
    	//ctrl1.termEndDt = DateTime.newInstance(Date.today()+10, Time.newInstance(0, 0, 0, 0)).format('yyyy/MM/dd');
    	ctrl1.c_termSt.WorkDay__c = Date.today().addDays(-10);
    	ctrl1.c_termEt.WorkDay__c = Date.today().addDays(10);
    	ctrl1.queryAccAcountList();
    	System.assert(ctrl1.accAcountLst.size() > 0);
    	Pagereference pg = ctrl1.redirectPlugin();
		System.assertNotEquals(pg, null);
		pg = ctrl1.redirectBillPlugin();
		System.assertNotEquals(pg, null);
	}
	// 店舗あり、なしの場合、会計書レイアウト切替制御確認
	static testMethod void accountPdfSwitch2() {
    	Test.startTest();
    	// 店舗情報を初期化する
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	comDef.FacilityCode__c = '3';
    	update comDef;
    	ShopInformation__c shopInfo = TestCommon.createShopInfo();
    	shopInfo.FacilityCode__c = '23';
    	update shopInfo;
		User currUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	currUser.ShopCode__c = shopInfo.ShopCode__c;
    	update currUser;
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	// 予約情報のステータス：チェックインに変更する
    	leadInfo.Field298__c = 'チェックイン完';
    	update leadInfo;

    	Test.stopTest();

    	// 会計画面に動作確認を行う
    	List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfo.Id];
    	AccountAcount__c accObj = accObjLst[0];
    	ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
    	BillInput_Ctrl ctrl = new BillInput_Ctrl(contrl);
    	ctrl.initAction();
    	ctrl.calPaymentInfo();
    	ctrl.upsertData();

    	ApexPages.StandardController contrl1 = new ApexPages.StandardController(accObj);
    	AccountPdfSwitch ctrl1 = new AccountPdfSwitch(contrl1);
    	ctrl1.AccAcountsSelectorInit();
    	PageReference refPage = ctrl1.redirect();
		String strUrl = refPage.getUrl();
		system.assert(strUrl.contains('AccountPDF_23'), strUrl);
	}
}