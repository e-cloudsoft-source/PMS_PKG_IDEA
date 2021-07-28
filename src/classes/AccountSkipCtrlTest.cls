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
private class AccountSkipCtrlTest {

	static testMethod void case01() {
		Test.startTest();
		ReportLogo__c rep = TestCommon.createRepLogo();
		ShopInformation__c shop = TestCommon.createShopInfo();
		rep.ShopInfoRef__c = shop.Id;
		update rep;
		User currUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
		currUser.ShopCode__c = shop.ShopCode__c;
		update currUser;
		// Init Xml Config
		getCsvSetupConfig();
		// 2015/12/01 Assert BEGIN
		System.assertEquals([select Id from Document where Name = 'BillSimplePaymentConfig'].size(), 1);
		// 2015/12/01 Assert END
		Contact guest = TestCommon.createContact();
		// 予約情報を作成する
		List<Lead__c> leadInfos = TestCommon.createLead(Date.today(), 1, 3, guest.Id);
		// 商品情報を作成する
		List<AccountMaster__c> productLst = TestCommon.createProductMst(4);
		// 見積明細を作成する
		TestCommon.createBookEstItem(leadInfos[0], productLst[0]);
		TestCommon.createBookEstItem(leadInfos[1], productLst[0]);
		TestCommon.createBookEstItem(leadInfos[2], productLst[0]);
		// 商品２は前受付金に変更を行う
		AccountMaster__c accMst = productLst[1];
		accMst.ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
		accMst.PaymentType__c = 'カード';  // XMLの定義と合わせるが必要です
		update accMst;
		AccountMaster__c accMstPay = productLst[3];
		accMstPay.ActionType__c = CommConst.PROD_ACTION_TYPE_PY;
		accMstPay.PaymentType__c = '現金';	// XMLの定義と合わせるが必要です
		update accMstPay;
		
		TestCommon.createBookEstItem(leadInfos[1], productLst[1]);
		// 予約情報のステータス：チェックインに変更する
		leadInfos[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
		leadInfos[1].Field298__c = CommConst.LEAD_GUEST_ST_CI;
		update leadInfos;
		Test.stopTest();
		
		// 会計画面に動作確認を行う
		List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfos[0].Id Or Relreserve__c = :leadInfos[1].Id];
		AccountAcount__c accObj = accObjLst[1];
		

		ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
		BillSimpleInputCtrl ctrl = new BillSimpleInputCtrl(contrl);
		ctrl.initAction();
		ctrl.upsertData();
		AccountSkipCtrl accSkipCtrl = new AccountSkipCtrl(contrl);
		accSkipCtrl.newAccountId = accObjLst[0].Id;
		List<String> tran1IdLst = new List<String>();
		for(Tran1__c t : [Select Id From Tran1__c]){
			tran1IdLst.add(t.Id);
		}
		List<String> ttendIdLst = new List<String>();
		for(TTend__c t : [Select Id From TTend__c]){
			ttendIdLst.add(t.Id);
		}
		accSkipCtrl.selectTranIdJson = Json.serialize(tran1IdLst);
		accSkipCtrl.selectTTendIdJson = Json.serialize(ttendIdLst);
		accSkipCtrl.updateTranDetail();
	}
	private static void getCsvSetupConfig() {
		String csv = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP><SHOPCODE></SHOPCODE><PAYMENT><CONVERT><PAYTYPE>現金</PAYTYPE><MEIDALAB>預り／現計</MEIDALAB></CONVERT><CONVERT><PAYTYPE>カード</PAYTYPE><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB></CONVERT><CONVERT><PAYTYPE>売掛金</PAYTYPE><MEIDALAB>掛計</MEIDALAB></CONVERT><CONVERT><PAYTYPE>クーポン</PAYTYPE><MEIDALAB>クーポン</MEIDALAB></CONVERT><CONVERT><PAYTYPE>値引</PAYTYPE><MEIDALAB>値引・割引券</MEIDALAB></CONVERT><CONVERT><PAYTYPE>予約金</PAYTYPE><MEIDALAB>予約金</MEIDALAB></CONVERT></PAYMENT><PAYMEIDA><CONVERT><MEIDALAB>預り／現計</MEIDALAB><PRODCODE>87001</PRODCODE></CONVERT><CONVERT><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB><PRODCODE>85201</PRODCODE></CONVERT><CONVERT><MEIDALAB>掛計</MEIDALAB><PRODCODE>85101</PRODCODE></CONVERT><CONVERT><MEIDALAB>クーポン</MEIDALAB><PRODCODE>85610</PRODCODE></CONVERT><CONVERT><MEIDALAB>値引・割引券</MEIDALAB><PRODCODE>87005</PRODCODE></CONVERT><CONVERT><MEIDALAB>予約金</MEIDALAB><PRODCODE>87001</PRODCODE></CONVERT></PAYMEIDA></SHOP></root>';
		Document doc = new Document();
		doc.Name = 'BillSimpleHelpConfig';
		doc.DeveloperName = doc.Name;
		doc.FolderId = UserInfo.getUserId();
		doc.Body = Blob.valueOf(csv);
		insert doc;
		
	
		csv = '<root><SHOP><SHOPCODE></SHOPCODE><LAYOUT><MAXCOLS>3</MAXCOLS><BTNSTYLE>width:125px;height:30px;</BTNSTYLE><TABLEWIDTH>450</TABLEWIDTH><TABLEHEIGHT>260</TABLEHEIGHT></LAYOUT><BUTTONTAB><TABLABEL>メディア</TABLABEL><BUTTON ISBLANK="FALSE"><LABEL>現金</LABEL><PRODCODE>87001</PRODCODE><ICONURL>/resource/AppImages/payicon/Cash.png</ICONURL></BUTTON><BUTTON ISBLANK="FALSE"><LABEL>VISA</LABEL><PRODCODE>85201</PRODCODE><ICONURL>/resource/simplepayimg/card/visa.jpg</ICONURL></BUTTON><BUTTON ISBLANK="FALSE"><LABEL>MASTER</LABEL><PRODCODE>85301</PRODCODE><ICONURL>/resource/simplepayimg/card/mc.jpg</ICONURL></BUTTON></BUTTONTAB><BUTTONTAB><TABLABEL>カード</TABLABEL><BUTTON ISBLANK="FALSE"><LABEL>VISA</LABEL><PRODCODE>85201</PRODCODE><ICONURL>/resource/simplepayimg/card/visa.jpg</ICONURL></BUTTON><BUTTON ISBLANK="FALSE"><LABEL>MASTER</LABEL><PRODCODE>85301</PRODCODE><ICONURL>/resource/simplepayimg/card/mc.jpg</ICONURL></BUTTON><BUTTON ISBLANK="FALSE"><LABEL>JCB</LABEL><PRODCODE>85401</PRODCODE><ICONURL>/resource/simplepayimg/card/jcb.jpg</ICONURL></BUTTON></BUTTONTAB><BUTTONTAB><TABLABEL>クーポン</TABLABEL><BUTTON ISBLANK="FALSE"><LABEL>楽天ポイント</LABEL><PRODCODE>85601</PRODCODE><ICONURL>/resource/simplepayimg/coupon/rt.jpg</ICONURL></BUTTON><BUTTON ISBLANK="FALSE"><LABEL>一休ポイント</LABEL><PRODCODE>85602</PRODCODE><ICONURL>/resource/simplepayimg/coupon/1x.jpg</ICONURL></BUTTON><BUTTON ISBLANK="FALSE"><LABEL>じゃらんポイント</LABEL><PRODCODE>85603</PRODCODE><ICONURL>/resource/simplepayimg/coupon/jal.jpg</ICONURL></BUTTON></BUTTONTAB></SHOP>'
					+ '</root>';
		
		doc = new Document();
		doc.Name = 'BillSimplePaymentConfig';
		doc.DeveloperName = doc.Name;
		doc.FolderId = UserInfo.getUserId();
		doc.Body = Blob.valueOf(csv);
		insert doc;
		
		TestCommon.createDeviceConfigXml();
	}
	private static void getCsvSetupConfigField() {
		String csv = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP><SHOPCODE></SHOPCODE><FIELDS><SECTION COLNUM="2">Field66__c,Field70__c,$_blank_$,relaccount__r.Phone</SECTION></FIELDS><REQUIREDFIELDS>Field137__c,AccountLanguage__c,relaccount__r.phone,TaxRate__c</REQUIREDFIELDS><LABEL>Field66__c:男性</LABEL><STYLECLASS>Field137__c:k-textbox</STYLECLASS><EXUTEFIELD>relaccount__r.gender__c</EXUTEFIELD><COLNUMSIZE>Relcontact__c:180px,Name:180px,Field137__c:150px</COLNUMSIZE></SHOP><SHOP><SHOPCODE>02</SHOPCODE><FIELDS><SECTION COLNUM="2"></SECTION></FIELDS></SHOP></root>';
		Document doc = new Document();
		doc.Name = 'BillSimpleInputField';
		doc.DeveloperName = doc.Name;
		doc.FolderId = UserInfo.getUserId();
		doc.Body = Blob.valueOf(csv);
		insert doc;
	}
}