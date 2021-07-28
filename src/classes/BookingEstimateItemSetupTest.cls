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
private class BookingEstimateItemSetupTest {

	// Leadと既存見積
	testMethod static void testCase1() {
        Test.startTest();
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
        CommDefine__c comDef = TestCommon.createCommDefine();
        comdef.ReducedTaxRateFlg__c = true;
        comdef.PDFPlanBrkIsShowFlg__c = true;
        update comdef;
        // 2019/07/30 軽減税率機能対応 WGCH END
        // 2018/10/24 見積明細自動計算機能対応 WGCH BEGIN
        Document doc = TestCommon.createBillSimpleHelpConfigDoc();
        commNoticeConfig();
        // 2018/10/24 見積明細自動計算機能対応 WGCH END
        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
        // 商品情報を作成する[5件商品を作成する]
        List<AccountMaster__c> productLst = TestCommon.createProductMst(5);
        // 見積明細を作成する[1件作成]
        //TestCommon.createBookEstItem(leadInfo, productLst[0]);
        Test.stopTest();
        // Lead設定する
        ApexPages.StandardController contrl = new ApexPages.StandardController(leadInfo);
        BookingEstimateItemSetup ctrl = new BookingEstimateItemSetup(contrl);
        List<BookingEstimateItemSetup.BookEstItem> queryLst = ctrl.oBookEstLst;
        Integer isValidataRecs = 0;
        for (BookingEstimateItemSetup.BookEstItem item : queryLst) {
        	if (item.isValidata) isValidataRecs++;
        }
        System.assertEquals(isValidataRecs, 1);

        BookingEstimateItemSetup.BookEstItem item2 = queryLst[1];
        item2.sobj.refAccountMaster__c = productLst[1].Id;
        item2.productNm = productLst[1].Name;
        item2.prodNums = '4';
        item2.sobj.UnitPrice__c = 5000;
        item2.sobj.UseDate__c = system.today();
        //item2.sobj.ActionType__c = '通常'
        ctrl.upsertData();
        queryLst = ctrl.oBookEstLst;
        isValidataRecs = 0;
        for (BookingEstimateItemSetup.BookEstItem item : queryLst) {
            if (item.isValidata) isValidataRecs++;
        }
        System.assertEquals(isValidataRecs, 2);
        
        // 商品自動取得機能
        ProductItemUtils.ProductItem item = BookingEstimateItemSetup.getProductItemInfo(productLst[0].Field3__c);
        System.assertEquals(item.prodcutName, productLst[0].Name);
        List<ProductItemUtils.ProductItem> items = BookingEstimateItemSetup.getArrayProductItemInfo(productLst[0].Field3__c);
		System.assert(items.size() > 0, items);
		
	}
	
	testMethod static void testCase2() {
        Test.startTest();
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
        CommDefine__c comDef = TestCommon.createCommDefine();
        comdef.ReducedTaxRateFlg__c = true;
        comdef.PDFPlanBrkIsShowFlg__c = true;
        update comdef;
        // 2019/07/30 軽減税率機能対応 WGCH END
        // 2018/10/24 見積明細自動計算機能対応 WGCH BEGIN
        Document doc = TestCommon.createBillSimpleHelpConfigDoc();
        commNoticeConfig();
        // 2018/10/24 見積明細自動計算機能対応 WGCH END
        Date startDt = Date.newInstance(2013,11,1);
        // 予約情報を作成する
        List<Lead__c> leadInfos = TestCommon.createLead(startDt, 1, 1);
        Lead__c leadInfo = leadInfos[0];
        // プラン情報を作成する
        AccountMaster__c planProd0 = TestCommon.createPlanProd();
        // 商品情報を作成する[5件商品を作成する]
        List<AccountMaster__c> productLst = TestCommon.createProductMst(5);
        // 見積明細を作成する[1件作成]
        //TestCommon.createBookEstItem(leadInfo, productLst[0]);
        Test.stopTest();
        // Lead設定する
        ApexPages.StandardController contrl = new ApexPages.StandardController(leadInfo);
        BookingEstimateItemSetup ctrl = new BookingEstimateItemSetup(contrl);
        List<BookingEstimateItemSetup.BookEstItem> queryLst = ctrl.oBookEstLst;
        Integer isValidataRecs = 0;
        for (BookingEstimateItemSetup.BookEstItem item : queryLst) {
        	if (item.isValidata) isValidataRecs++;
        }
        System.assertEquals(isValidataRecs, 1);
        // 明細情報を取得する
        BookingEstimateItemSetup.BookEstItem existItem = queryLst[0];
       	// 新規プラン商品を取得する
        List<BookingEstimateItemSetup.PlanDetail> planDetail1 = BookingEstimateItemSetup.getAccountMstLstByPlan('', '', planProd0.Id);
 		List<BookingEstimateItemSetup.PlanDetail> planDetail2 = BookingEstimateItemSetup.getAccountMstLstByPlan(existItem.itemId, existItem.leadId, '');
 		delete [select id from BookingEstimateItem__c where id = :existItem.itemId];
 		List<BookingEstimateItemSetup.PlanDetail> planDetail3 = BookingEstimateItemSetup.getAccountMstLstByPlan(existItem.itemId, existItem.leadId, planProd0.Id);
	   ctrl.getQuotationNameLst();
    }
	// 2017/07/14 発注書/注文請書 zyz BEGIN
	static testMethod void LeadToCase7_14_0() {
        Test.startTest();
        // 店舗情報を初期化する
        CommDefine__c comDef = TestCommon.createCommDefine();
        comDef.AccountServiceChargeIsShow__c = '1';
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
        comdef.ReducedTaxRateFlg__c = true;
        comdef.PDFPlanBrkIsShowFlg__c = true;
        // 2019/07/30 軽減税率機能対応 WGCH END
        update comDef;
        ShopInformation__c shopInfo = TestCommon.createShopInfo();
        shopInfo.payee1__c = '23';
        shopInfo.payee2__c = '23';
        shopInfo.payee3__c = '23';
        shopInfo.payeeAcount__c = '23';
        shopInfo.ShopCode__c = '02';
        update shopInfo;
        ReportLogo__c tempShopLogo = TestCommon.createRepLogo();
        tempShopLogo.ShopInfoRef__c = shopInfo.Id;
        update tempShopLogo;
        User currUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        currUser.ShopCode__c = shopInfo.ShopCode__c;
        update currUser;
        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
        leadInfo.LeadPdfShopCode__c = '01';
        leadInfo.Payduration__c = 'zhifuqixian';
        leadInfo.QuotationComment__c = '発注';
        leadInfo.ContractDate__c = Date.today();
        leadInfo.PeriodInfo__c = '2017/07/01';
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(4);
        AccountMaster__c accMst = productLst[1];
        accMst.ActionType__c = '前受付金';
        accMst.PaymentType__c = 'カード';
        update accMst;
        // 見積明細を作成する
        BookingEstimateItem__c bookingItemA = TestCommon.createBookEstItem(leadInfo, productLst[0]);
        bookingItemA.UnitPrice__c = 30000;
        update bookingItemA;
        BookingEstimateItem__c bookingItem = TestCommon.createBookEstItem(leadInfo, productLst[0]);
        // 予約情報のステータス：チェックインに変更する
        bookingItem.UnitPrice__c = 20000;
        bookingItem.ActionType__c = '通常';
        bookingItem.PaymentType__c = null;
        bookingItem.refAccountMaster__c = accMst.Id;
        bookingItem.Amount__c = 4;
        bookingItem.ServiceRate__c = 10;
        bookingItem.ParentBookingItemRef__c = bookingItemA.id;
        update bookingItem;

        Test.stopTest();
        // Report Logo作成
        TestCommon.createRepLogo();

        // 発注書 /注文請書 
        getCsvSetupConfig();
        ApexPages.StandardController contr3 = new ApexPages.StandardController(leadInfo);
        Apexpages.currentPage().getParameters().put('Id',leadInfo.Id);
        Apexpages.currentPage().getParameters().put('ptype','1');
        Apexpages.currentPage().getParameters().put('Contract','2017/07/01');
        Apexpages.currentPage().getParameters().put('PayDuration','zhifuqixian');
        Apexpages.currentPage().getParameters().put('Charge','null');
        Apexpages.currentPage().getParameters().put('Comment','QuotationComment');
        RepGeneralExtendCtrl lPdf = new RepGeneralExtendCtrl(contr3);
        lPdf.initPdf();
        lPdf.initRepWindow();
        lPdf.getLead();
        lPdf.getServiceAmount();
        lPdf.getLeadNames();
        
        RepGeneralExtendCtrl.TotalInfo pdfSumInfo = lPdf.sumInfo;
        pdfSumInfo.payedDiscount = 500;
        System.assert(pdfSumInfo.amoutQuotePriceIncTax != null);
        System.assert(pdfSumInfo.amoutTax != null);
        System.assert(pdfSumInfo.amoutUsedPriceIncTax != null);
	}
	static testMethod void LeadToCase7_14_1() {
        Test.startTest();
        // 予約情報を作成する
        CommDefine__c comDef = TestCommon.createCommDefine();
        comDef.AccountServiceChargeIsShow__c = '1';
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
        comdef.ReducedTaxRateFlg__c = true;
        comdef.PDFPlanBrkIsShowFlg__c = true;
        // 2019/07/30 軽減税率機能対応 WGCH END
        update comDef;
        ReportLogo__c item1 = new ReportLogo__c();
        item1.Name = CommRepUtils.REP_TYPE.LOGO_00_SYSDEF.name();
        item1.ReportLogo__c = 'TEST CONTEXT BODY';
        insert item1;
        User currUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        currUser.ShopCode__c = '';
        update currUser;
        list<Lead__c> leadInfolst = TestCommon.createLead(Date.today(),1,1);
        Lead__c leadInfo = leadInfolst[0];
        leadInfo.name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(); // 予約名
        leadInfo.ReservedStatus__c = '確認中'; 
        leadInfo.ReservedDate__c = System.now(); 
        leadInfo.ReservedContact__c = 'Ono'; 
        leadInfo.EntryTime__c = Date.today(); 
        leadInfo.Field4__c = '15:30'; 
        leadInfo.Departure__c = Date.today() +1; 
        leadInfo.Field3__c = '10:00'; 
        leadInfo.StayPersons__c = 1; 
        leadInfo.Field2__c = 'FAX'; 
        leadInfo.Payduration__c = 'zhifuqixian'; 
        leadInfo.QuotationComment__c = '発注'; 
        leadInfo.ContractDate__c = Date.today();
        leadInfo.PeriodInfo__c = '2017/07/01';
        update leadInfo;
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(4);
        AccountMaster__c accMst = productLst[1];
        accMst.ActionType__c = '前受付金';
        accMst.PaymentType__c = 'カード';
        update accMst;
        // 見積明細を作成する
        BookingEstimateItem__c bookingItemA = TestCommon.createBookEstItem(leadInfo, productLst[0]);
        bookingItemA.UnitPrice__c = 30000;
        update bookingItemA;
        BookingEstimateItem__c bookingItem = TestCommon.createBookEstItem(leadInfo, productLst[0]);
        // 予約情報のステータス：チェックインに変更する
        bookingItem.UnitPrice__c = 20000;
        bookingItem.ActionType__c = '通常';
        bookingItem.PaymentType__c = null;
        bookingItem.refAccountMaster__c = accMst.Id;
        bookingItem.Amount__c = 4;
        bookingItem.ServiceRate__c = 10;
        bookingItem.ParentBookingItemRef__c = bookingItemA.id;
        update bookingItem;

        Test.stopTest();
        // 発注書 /注文請書 
        getCsvSetupConfig();
        ApexPages.StandardController contr3 = new ApexPages.StandardController(leadInfo);
        Apexpages.currentPage().getParameters().put('Id',leadInfo.Id);
        Apexpages.currentPage().getParameters().put('ptype','1');
        Apexpages.currentPage().getParameters().put('spcd','');
        Apexpages.currentPage().getParameters().put('Contract','2017/07/01');
        Apexpages.currentPage().getParameters().put('PayDuration','zhifuqixian');
        Apexpages.currentPage().getParameters().put('Charge','null');
        Apexpages.currentPage().getParameters().put('Comment','QuotationComment');
        RepGeneralExtendCtrl lPdf = new RepGeneralExtendCtrl(contr3);
        lPdf.initPdf();
        lPdf.initRepWindow();
        lPdf.getLead();
        lPdf.getServiceAmount();
        lPdf.getLeadNames();

        RepGeneralExtendCtrl.TotalInfo pdfSumInfo = lPdf.sumInfo;
        pdfSumInfo.payedDiscount = 500;
        System.assert(pdfSumInfo.amoutQuotePriceIncTax != null);
        System.assert(pdfSumInfo.amoutTax != null);
        System.assert(pdfSumInfo.amoutUsedPriceIncTax != null);
	}
    static testMethod void LeadToCase7_14_2() {
        commNoticeConfig();
        TestCommon.createGroups(1);
        CommDefine__c comm = TestCommon.createCommDefine();
        comm.AutoAlarmFlg__c = true;
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
        comm.ReducedTaxRateFlg__c = true;
        comm.PDFPlanBrkIsShowFlg__c = true;
        update comm;
        Test.startTest();
        // 2019/07/30 軽減税率機能対応 WGCH END
        List<CollaborationGroup> groupList = [select name from CollaborationGroup];
        comm.ChatterGroupName__c = '11:' + groupList[0].name;
        update comm;
        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead(system.today());
        List<BookingEstimateItem__c> books = [select id,Amount__c from BookingEstimateItem__c];
        books[0].Amount__c = 9;
        update books[0];
        Test.stopTest();
    }

	static testMethod void Commnotice_1_1(){
        commNoticeConfig();
        TestCommon.createGroups(1);
        List<CollaborationGroup> groupList = [select name from CollaborationGroup];
        CommDefine__c comm = TestCommon.createCommDefine();
        comm.AutoAlarmFlg__c = true;
        comm.ChatterGroupName__c = '11:' + groupList[0].name;
        update comm;
        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead(system.today());
        List<BookingEstimateItem__c> books = [select id,Amount__c from BookingEstimateItem__c];
        books[0].Amount__c = 9;
        update books[0];
        // CommonNotifacationCtrl.NoticeDatas datas = new CommonNotifacationCtrl.NoticeDatas(new List<Sobject>(),new List<Sobject>(),'lead__c',CommConst.TriggerMethod.IsUpdate,'11');
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
	// 2017/07/14 発注書/注文請書 zyz END
    private static void commNoticeConfig(){
        String csv = '<?xml version="1.0" encoding="UTF-8"?><root><Lead__c> <!-- 监听变更字段设定 -->   <LISTENFIELD>name,Comment3__c</LISTENFIELD> <!-- 监听数据条件控制 当ご予約のfield01__cチェック -->   <LISTENFILTER>Field310__c != null</LISTENFILTER> <!--通知グループ指定--> <CHATTERGROUP>11</CHATTERGROUP> </Lead__c><BookingEstimateItem__c>  <!-- 监听变更字段设定 -->   <LISTENFIELD>Amount__c,UnitPrice__c,X2_1__c,UseDate__c</LISTENFIELD>    <!-- 监听数据条件控制 当ご予約のfield01__cチェック -->   <LISTENFILTER>refBooking__r.Relcontact__c != null</LISTENFILTER>    <!--    <WHERE>refBooking__r.Relcontact__c != null and Field4__r.Field1__c = \'0140\'</WHERE> --> <!--通知グループ指定--> <CHATTERGROUP>11</CHATTERGROUP><UPDFIELD value="2019/10/30 10:20">refBooking__r.VBCheckTime__c</UPDFIELD></BookingEstimateItem__c></root>';
        Document doc = new Document();
        doc.Name = 'CommObjectListenConfig';
        doc.DeveloperName = doc.Name;
        doc.FolderId = UserInfo.getUserId();
        doc.Body = Blob.valueOf(csv);
        insert doc;
    }
}