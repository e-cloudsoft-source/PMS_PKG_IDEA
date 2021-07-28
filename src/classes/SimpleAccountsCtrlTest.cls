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
private class SimpleAccountsCtrlTest {

    @isTest(SeeAllData=false)
	static void selfTest() {
		// Init Xml Config
		getDocSetupConfig();
		// 店舗は空白に設定する
		UserUtil.CurrentUser.ShopCode__c = null;
		update UserUtil.CurrentUser;
    	// 2017/02/27 Order関連のXML定義情報を作成する
    	TestCommon.createOrderConfigXml();
    	TestCommon.createDeviceConfigXml();
		// 商品作成する
		List<AccountMaster__c> prodList = TestCommon.createProductMst(2);
		AccountMaster__c accMst = prodList[1];
		accMst.ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
		accMst.PaymentType__c = 'カード';  // XMLの定義と合わせるが必要です
		accMst.Field3__c = '1';
		update accMst;
		// 
		SimpleAccountsCtrl ctrl = new SimpleAccountsCtrl();
		ctrl.mediaType = ctrl.mediaTypeOptionLst[0].getValue();
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
		
		// 自動売上、会計、会計支払い、会計明細の作成
		// 支払い明細の作成の確認
		List<Tran1__c> tranLst = [select id from Tran1__c where Field7__c = :prodList[0].Id];
		System.assert(!tranLst.isEmpty(), tranLst);
		
		// ログインユーザーの店舗コードが未設定する場合、会計に店舗情報を設定を行わない
		List<AccountAcount__c> accLst = [select id,ShopSeq__c,ShopCode__c,ShopName__c  from AccountAcount__c where id = :ctrl.accountsId];
		System.assertEquals(accLst[0].ShopSeq__c, null, accLst);
		System.assertEquals(accLst[0].ShopCode__c, null, accLst);
		System.assertEquals(accLst[0].ShopName__c, null, accLst);
	}
	
	@isTest(SeeAllData=false)
	static void testSimpleAccShopSetup() {
		// Init Xml Config
		getDocSetupConfig();
		ShopInformation__c shop = TestCommon.createShopInfo();
		// 店舗は空白に設定する
 		User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	loginUser.ShopCode__c = shop.ShopCode__c;
    	update loginUser;
		// 商品作成する
		List<AccountMaster__c> prodList = TestCommon.createProductMst(1);
    	// 2017/02/27 Order関連のXML定義情報を作成する
    	TestCommon.createOrderConfigXml();
    	TestCommon.createDeviceConfigXml();
		SimpleAccountsCtrl ctrl = new SimpleAccountsCtrl();
		ctrl.mediaType = ctrl.mediaTypeOptionLst[0].getValue();
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
		
		// 自動売上、会計、会計支払い、会計明細の作成
		// 支払い明細の作成の確認
		List<Tran1__c> tranLst = [select id from Tran1__c where Field7__c = :prodList[0].Id];
		System.assert(!tranLst.isEmpty(), tranLst);
		
		
		// ログインユーザーの店舗コードが未設定する場合、会計に店舗情報を設定を行わない
		List<AccountAcount__c> accLst = [select id,ShopSeq__c,ShopCode__c,ShopName__c  from AccountAcount__c where id = :ctrl.accountsId];
		System.assertEquals(accLst[0].ShopSeq__c, shop.Seq__c, accLst);
		System.assertEquals(accLst[0].ShopCode__c, shop.ShopCode__c, accLst);
		System.assertEquals(accLst[0].ShopName__c, shop.Name, accLst);
    }
    @isTest(SeeAllData=true)
    static void remoteTest001 () {
     	SimpleAccountsCtrl.savePrintLodToDb('test');
			 List<AccountMaster__c> accs = TestCommon.createProductMst(10);
			 AutoAccountMasterCtrl.referenecInfo(accs[0].id);
    }
    private static void getDocSetupConfig() {
		// ドキュメントを作成する
		Document item = new Document();
		item.Name = 'SimplePaymentConfig';
		item.DeveloperName = item.Name;
		item.FolderId = UserInfo.getUserId();
		item.Body = Blob.valueOf('<root>'+
								'<SHOP>'+
								'<SHOPCODE></SHOPCODE>'+
								'<BUTTONTAB><BUTTON><LABEL>現金</LABEL><PRODCODE>1</PRODCODE></BUTTON><BUTTON><LABEL>Master</LABEL><PRODCODE>M90002</PRODCODE></BUTTON></BUTTONTAB>' + 
								'</SHOP>'+
								'</root>');
		insert item;
		
		String csv = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP><SHOPCODE></SHOPCODE><PAYMENT><CONVERT><PAYTYPE>現金</PAYTYPE><MEIDALAB>預り／現計</MEIDALAB></CONVERT><CONVERT><PAYTYPE>カード</PAYTYPE><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB></CONVERT><CONVERT><PAYTYPE>売掛金</PAYTYPE><MEIDALAB>掛計</MEIDALAB></CONVERT><CONVERT><PAYTYPE>クーポン</PAYTYPE><MEIDALAB>クーポン</MEIDALAB></CONVERT><CONVERT><PAYTYPE>値引</PAYTYPE><MEIDALAB>値引・割引券</MEIDALAB></CONVERT><CONVERT><PAYTYPE>予約金</PAYTYPE><MEIDALAB>予約金</MEIDALAB></CONVERT></PAYMENT><PAYMEIDA><CONVERT><MEIDALAB>預り／現計</MEIDALAB><PRODCODE>87001</PRODCODE></CONVERT><CONVERT><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB><PRODCODE>85201</PRODCODE></CONVERT><CONVERT><MEIDALAB>掛計</MEIDALAB><PRODCODE>85101</PRODCODE></CONVERT><CONVERT><MEIDALAB>クーポン</MEIDALAB><PRODCODE>85610</PRODCODE></CONVERT><CONVERT><MEIDALAB>値引・割引券</MEIDALAB><PRODCODE>87005</PRODCODE></CONVERT><CONVERT><MEIDALAB>予約金</MEIDALAB><PRODCODE>87001</PRODCODE></CONVERT></PAYMEIDA></SHOP></root>';
		
		Document doc = new Document();
		doc.Name = 'BillSimpleHelpConfig';
		doc.DeveloperName = doc.Name;
		doc.FolderId = UserInfo.getUserId();
		doc.Body = Blob.valueOf(csv);
		insert doc;
	}
}