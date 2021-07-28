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
private class LeadBillPDFCtrlTest {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        getCsvSetupConfig();
        // 2018/12/15 請求書レイアウト改善 BY zyz BEGIN 
        getBillPdfConfig();
        // 2018/12/15 請求書レイアウト改善 BY zyz END 
    	Test.startTest();
    	// 店舗情報を初期化する
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	// 施設コード    
    	comDef.BillReportCommentAutoBreakFlg__c = true;
		comDef.BookingReportStampIsShowFlg__c = false;
    	//comDef.UnitPriceDefKb__c = 1; 	//会計商品単価定義区分
    	update comDef;
    	ShopInformation__c shopInfo = TestCommon.createShopInfo();
    	shopInfo.payee1__c = '23';
    	shopInfo.payee2__c = '23';
    	shopInfo.payee3__c = '23';
    	shopInfo.payeeAcount__c = '23';
		shopInfo.ServiceChargeIsShow__c = '2';
		shopInfo.AccountServiceChargeNoTaxFlg__c = true;
    	update shopInfo;
    	ReportLogo__c tempShopLogo = TestCommon.createRepLogo();
        tempShopLogo.ShopInfoRef__c = shopInfo.Id;
        update tempShopLogo;
    	User currUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	currUser.ShopCode__c = shopInfo.ShopCode__c;
    	update currUser;
    	ExchangeRate__c rate = TestCommon.createExchangeRate();
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	rate.Name = UserInfo.getDefaultCurrency() + 'JPY_' + CommUtils.getRandom(3);
    	rate.RateDate__c = leadInfo.EntryTime__c.Date();
    	update rate;
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(4);
    	productLst[0].ActionType__c = CommConst.PROD_ACTION_TYPE_PY;
    	productLst[0].SpecialTax__c = 2000;
    	productLst[0].PaymentType__c = '予約金';
    	productLst[1].ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
    	productLst[1].SpecialTax__c = 2000;
    	productLst[1].PaymentType__c = '予約金';
		update productLst;
    	// 見積明細を作成する
    	BookingEstimateItem__c bookingItem = TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	// 予約情報のステータス：チェックインに変更する
    	bookingItem.UnitPrice__c = 20000;
    	bookingItem.SpecialTax__c = 7900;
    	bookingItem.ActionType__c = CommConst.PROD_ACTION_TYPE_PY;
    	bookingItem.PaymentType__c = '予約金';
    	bookingItem.refAccountMaster__c = productLst[0].Id;
    	bookingItem.Amount__c = 4;
    	bookingItem.ParentBookingItemRef__c = null;
    	update bookingItem;
    	BookingEstimateItem__c bookingItem1 = TestCommon.createBookEstItem(leadInfo, productLst[1]);
    	// 予約情報のステータス：チェックインに変更する
    	bookingItem1.UnitPrice__c = 1000;
    	bookingItem1.SpecialTax__c = 1000;
    	bookingItem1.ActionType__c = '前受付金';
    	bookingItem1.PaymentType__c = '予約金';
    	bookingItem1.refAccountMaster__c = productLst[1].Id;
    	bookingItem1.Amount__c = 4;
    	bookingItem1.ParentBookingItemRef__c = null;
    	update bookingItem;
    	Test.stopTest();
        ApexPages.StandardController contr3 = new ApexPages.StandardController(leadInfo);
        Apexpages.currentPage().getParameters().put('cy','cy');
        LeadBillPDFCtrl lbPdf = new LeadBillPDFCtrl(contr3);
        
        lbPdf.getNumberFormat();
        lbPdf.extInitAction();
        lbPdf.getReportLogo();
        lbPdf.getAccoutInfo();
        lbPdf.getAccountNo();
        lbPdf.getCustomer();
        lbPdf.getCharge();
        lbPdf.getRequestAmount();
        lbPdf.getTax();
        lbPdf.getIssueDate();
        lbPdf.getAdvancesReceived();
        lbPdf.getTran();
        lbPdf.getAmoutIncDiscont();
        lbPdf.getServiceDate();
        AccountAcount__c comment = lbPdf.comment;
        lbPdf.getServiceAmount();
    }
    static testMethod void myUnitTest01() {
        // TO DO: implement unit test
        getCsvSetupConfig();
        // 2018/12/15 請求書レイアウト改善 BY zyz BEGIN 
        getBillPdfConfig();
        // 2018/12/15 請求書レイアウト改善 BY zyz END 
    	Test.startTest();
    	// 店舗情報を初期化する
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	// 施設コード    
    	comDef.BillReportCommentAutoBreakFlg__c = true;
		comDef.BookingReportStampIsShowFlg__c = false;
    	//comDef.UnitPriceDefKb__c = 1; 	//会計商品単価定義区分
    	update comDef;
    	ShopInformation__c shopInfo = TestCommon.createShopInfo();
    	shopInfo.payee1__c = '23';
    	shopInfo.payee2__c = '23';
    	shopInfo.payee3__c = '23';
    	shopInfo.payeeAcount__c = '23';
		shopInfo.ServiceChargeIsShow__c = '2';
		shopInfo.AccountServiceChargeNoTaxFlg__c = true;
    	update shopInfo;
    	ReportLogo__c tempShopLogo = TestCommon.createRepLogo();
        tempShopLogo.ShopInfoRef__c = shopInfo.Id;
        update tempShopLogo;
    	User currUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	currUser.ShopCode__c = shopInfo.ShopCode__c;
    	update currUser;
    	ExchangeRate__c rate = TestCommon.createExchangeRate();
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	rate.Name = UserInfo.getDefaultCurrency() + 'JPY_' + CommUtils.getRandom(3);
    	rate.RateDate__c = leadInfo.EntryTime__c.Date();
    	update rate;
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(4);
    	productLst[0].ActionType__c = CommConst.PROD_ACTION_TYPE_PY;
    	productLst[0].PaymentType__c = '予約金';
    	productLst[1].ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
    	productLst[1].PaymentType__c = '予約金';
		update productLst;
    	// 見積明細を作成する
    	BookingEstimateItem__c bookingItem = TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	// 予約情報のステータス：チェックインに変更する
    	bookingItem.UnitPrice__c = 0;
    	bookingItem.ActionType__c = CommConst.PROD_ACTION_TYPE_PY;
    	bookingItem.PaymentType__c = '予約金';
    	bookingItem.refAccountMaster__c = productLst[0].Id;
    	bookingItem.Amount__c = 4;
    	bookingItem.ParentBookingItemRef__c = null;
    	update bookingItem;
    	BookingEstimateItem__c bookingItem1 = TestCommon.createBookEstItem(leadInfo, productLst[1]);
    	// 予約情報のステータス：チェックインに変更する
    	bookingItem1.UnitPrice__c = 0;
    	bookingItem1.ActionType__c = '前受付金';
    	bookingItem1.PaymentType__c = '予約金';
    	bookingItem1.refAccountMaster__c = productLst[1].Id;
    	bookingItem1.Amount__c = 4;
    	bookingItem1.ParentBookingItemRef__c = null;
    	update bookingItem;
    	Test.stopTest();
        ApexPages.StandardController contr3 = new ApexPages.StandardController(leadInfo);
        Apexpages.currentPage().getParameters().put('cy','cy');
        LeadBillPDFCtrl lbPdf = new LeadBillPDFCtrl(contr3);
        
        lbPdf.getNumberFormat();
        lbPdf.extInitAction();
        lbPdf.getReportLogo();
        lbPdf.getAccoutInfo();
        lbPdf.getAccountNo();
        lbPdf.getCustomer();
        lbPdf.getCharge();
        lbPdf.getRequestAmount();
        lbPdf.getTax();
        lbPdf.getIssueDate();
        lbPdf.getAdvancesReceived();
        lbPdf.getTran();
        lbPdf.getAmoutIncDiscont();
        lbPdf.getServiceDate();
        AccountAcount__c comment = lbPdf.comment;
        lbPdf.getServiceAmount();
    }
    static testMethod void myUnitTest02() {
        // TO DO: implement unit test
        getCsvSetupConfig();
        // 2018/12/15 請求書レイアウト改善 BY zyz BEGIN 
        getBillPdfConfig();
        // 2018/12/15 請求書レイアウト改善 BY zyz END 
    	Test.startTest();
    	// 店舗情報を初期化する
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	// 施設コード    
    	comDef.BillReportCommentAutoBreakFlg__c = true;
		comDef.BookingReportStampIsShowFlg__c = false;
    	//comDef.UnitPriceDefKb__c = 1; 	//会計商品単価定義区分
    	update comDef;
    	ShopInformation__c shopInfo = TestCommon.createShopInfo();
    	shopInfo.payee1__c = '23';
    	shopInfo.payee2__c = '23';
    	shopInfo.payee3__c = '23';
    	shopInfo.payeeAcount__c = '23';
		shopInfo.ServiceChargeIsShow__c = '2';
		shopInfo.AccountServiceChargeNoTaxFlg__c = true;
    	update shopInfo;
    	ReportLogo__c tempShopLogo = TestCommon.createRepLogo();
        tempShopLogo.ShopInfoRef__c = shopInfo.Id;
        update tempShopLogo;
    	User currUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	currUser.ShopCode__c = shopInfo.ShopCode__c;
    	update currUser;
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(4);
    	productLst[0].ActionType__c = CommConst.PROD_ACTION_TYPE_PY;
    	productLst[0].PaymentType__c = '予約金';
    	productLst[1].ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
    	productLst[1].PaymentType__c = '予約金';
		update productLst;
    	// 見積明細を作成する
    	BookingEstimateItem__c bookingItem = TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	// 予約情報のステータス：チェックインに変更する
    	bookingItem.UnitPrice__c = 20000;
    	bookingItem.ActionType__c = CommConst.PROD_ACTION_TYPE_PY;
    	bookingItem.PaymentType__c = '予約金';
    	bookingItem.refAccountMaster__c = productLst[0].Id;
    	bookingItem.Amount__c = 4;
    	bookingItem.ParentBookingItemRef__c = null;
    	update bookingItem;
    	BookingEstimateItem__c bookingItem1 = TestCommon.createBookEstItem(leadInfo, productLst[1]);
    	// 予約情報のステータス：チェックインに変更する
    	bookingItem1.UnitPrice__c = 20000;
    	bookingItem1.ActionType__c = '前受付金';
    	bookingItem1.PaymentType__c = '予約金';
    	bookingItem1.refAccountMaster__c = productLst[1].Id;
    	bookingItem1.Amount__c = 4;
    	bookingItem1.ParentBookingItemRef__c = null;
    	update bookingItem;
    	Test.stopTest();
        ApexPages.StandardController contr3 = new ApexPages.StandardController(leadInfo);
        LeadBillPDFCtrl lbPdf = new LeadBillPDFCtrl(contr3);
        lbPdf.getNumberFormat();
        lbPdf.extInitAction();
        lbPdf.getReportLogo();
        lbPdf.getAccoutInfo();
        lbPdf.getAccountNo();
        lbPdf.getCustomer();
        lbPdf.getCharge();
        lbPdf.getRequestAmount();
        lbPdf.getTax();
        lbPdf.getIssueDate();
        lbPdf.getAdvancesReceived();
        lbPdf.getTran();
        lbPdf.getAmoutIncDiscont();
        lbPdf.getServiceDate();
        AccountAcount__c comment = lbPdf.comment;
        lbPdf.getServiceAmount();
    }
    private static void getCsvSetupConfig() {
        String csv = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP><SHOPCODE></SHOPCODE><PAYMENT><CONVERT><PAYTYPE>現金</PAYTYPE><MEIDALAB>預り／現計</MEIDALAB></CONVERT><CONVERT><PAYTYPE>カード</PAYTYPE><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB></CONVERT><CONVERT><PAYTYPE>売掛金</PAYTYPE><MEIDALAB>掛計</MEIDALAB></CONVERT><CONVERT><PAYTYPE>クーポン</PAYTYPE><MEIDALAB>クーポン</MEIDALAB></CONVERT><CONVERT><PAYTYPE>値引</PAYTYPE><MEIDALAB>値引・割引券</MEIDALAB></CONVERT><CONVERT><PAYTYPE>予約金</PAYTYPE><MEIDALAB>予約金</MEIDALAB></CONVERT></PAYMENT><PAYMEIDA><CONVERT><MEIDALAB>預り／現計</MEIDALAB><PRODCODE>87001</PRODCODE></CONVERT><CONVERT><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB><PRODCODE>85201</PRODCODE></CONVERT><CONVERT><MEIDALAB>掛計</MEIDALAB><PRODCODE>85101</PRODCODE></CONVERT><CONVERT><MEIDALAB>クーポン</MEIDALAB><PRODCODE>85610</PRODCODE></CONVERT><CONVERT><MEIDALAB>値引・割引券</MEIDALAB><PRODCODE>87005</PRODCODE></CONVERT><CONVERT><MEIDALAB>予約金</MEIDALAB><PRODCODE>87001</PRODCODE></CONVERT></PAYMEIDA></SHOP></root>';
        
        Document doc = new Document();
        doc.Name = 'BillSimpleHelpConfig';
        doc.DeveloperName = doc.Name;
        doc.FolderId = UserInfo.getUserId();
        doc.Body = Blob.valueOf(csv);
        insert doc;
    }
    // 2018/12/15 請求書レイアウト改善 BY zyz BEGIN 
    private static void getBillPdfConfig() {
        String csv = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP><SHOPCODE></SHOPCODE><BILLLAYOUTNAME><LEAD_PDF STYLE="font-size:12pt;" AOTUSPLIT="true">御支払 : $$_Field315__c_$$&lt;br/&gt;$$_Relcontact__r.Name_$$ 様&lt;br/&gt;予約名 : $$_Name_$$</LEAD_PDF></BILLLAYOUTNAME><BILLPDFLAYOUT><TITLELABEL>御  請  求  書</TITLELABEL><ROWSLABEL><ROW><COL STYLE="font-size:9pt;">毎度格別の御引立に預かり厚く御礼申し上げます。</COL></ROW><ROW><COL STYLE="font-size:9pt;">下記の通り御請求申し上げます。</COL></ROW></ROWSLABEL><PAYLABEL>お振込先お振込先</PAYLABEL></BILLPDFLAYOUT><LETTERLAYOUT><SUBJECTLABEL>書 類 送 付 の ご 案 内</SUBJECTLABEL><CUSTOM_SHIPPING>拝啓&lt;br/&gt;時下ますますご清栄のこととお喜び申し上げます。</CUSTOM_SHIPPING><REGARDSLABEL>敬具</REGARDSLABEL><RECORDLABEL>記</RECORDLABEL><DEPARTLABEL>■請求書 1部</DEPARTLABEL><ABOVELABEL>以上</ABOVELABEL></LETTERLAYOUT></SHOP></root>';
        Document doc = new Document();
        doc.Name = 'BillPdfConfig';
        doc.DeveloperName = doc.Name;
        doc.FolderId = UserInfo.getUserId();
        doc.Body = Blob.valueOf(csv);
        insert doc;
    }
    // 2018/12/15 請求書レイアウト改善 BY zyz END 
}