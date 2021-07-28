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
private class BookingEstimateItemSetupsTest {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        // TO DO: implement unit test
        // 三泊数据
        List<Lead__c> leads = TestCommon.createLead(System.today(), 1, 3); 
        Lead__c leadInfo = leads[0];
        String subIds = '';
        for (Lead__c lead : leads) {
        	subIds += lead.id + ',';
        }
        List<AccountMaster__c> prods = TestCommon.createProductMst(2);
        TestCommon.createBookEstItem(leadInfo,prods[0]);
        ApexPages.StandardController contrl = new ApexPages.StandardController(leadInfo);
        Apexpages.currentPage().getParameters().put('Id',leadInfo.Id);
        Apexpages.currentPage().getParameters().put('more',subIds);
        Apexpages.currentPage().getParameters().put('mitumo','');
        Apexpages.currentPage().getParameters().put('auto','');
        getCsvSetupConfig();
        
        BookingEstimateItemSetup ctrl = new BookingEstimateItemSetup(contrl);
        List<BookingEstimateItemSetup.BookEstItem> queryLst = ctrl.oBookEstLst;
        BookingEstimateItemSetup.BookEstItem item2 = queryLst[3];
        item2.sobj.refAccountMaster__c = prods[1].Id;
        item2.productNm = prods[1].Name;
        item2.prodNums = '4';
        item2.sobj.UnitPrice__c = 5000;
        ctrl.addBookingItem();
        queryLst = ctrl.oBookEstLst;
        BookingEstimateItemSetup.BookEstItem lastItem = queryLst[queryLst.size()-1];
        lastItem.sobj.refAccountMaster__c = prods[0].Id;
        lastItem.productNm = prods[0].Name;
        lastItem.prodNums = '4';
        lastItem.sobj.UnitPrice__c = 5000;
       	lastItem.sobj.UseDate__c = CommUtils.stringtoDate('2015/01/01');
        ctrl.upsertData();
        Test.startTest();
        ctrl.refreshWindow();
        ctrl.kariKakuTei();
        // 見積場合
        ApexPages.StandardController contrl2 = new ApexPages.StandardController(leadInfo);
        Apexpages.currentPage().getParameters().put('Id',leadInfo.Id);
        Apexpages.currentPage().getParameters().put('quota',ctrl.quotaOrTemplateId);
        BookingEstimateItemSetup ctrl2 = new BookingEstimateItemSetup(contrl2);
        queryLst = ctrl2.oBookEstLst;
        lastItem = queryLst[queryLst.size()-1];
        lastItem.sobj.refAccountMaster__c = prods[0].Id;
        lastItem.productNm = prods[0].Name;
        lastItem.prodNums = '5';
        lastItem.sobj.UnitPrice__c = 2000;
       	lastItem.sobj.UseDate__c = CommUtils.stringtoDate('2222/01/01');
       	ctrl2.upsertData();
       	Test.stopTest();
       	// 見積場合
       	Quota__c quota = new Quota__c(id = ctrl.quotaOrTemplateId);
        ApexPages.StandardController contrl3 = new ApexPages.StandardController(quota);
       	//QuotaPDF pdf = new QuotaPDF(contrl3);
    }
    static testMethod void myUnitTest001() {
    	// 2018/10/24 見積明細自動計算機能対応 WGCH BEGIN
        Document doc = TestCommon.createBillSimpleHelpConfigDoc();
        // 2018/10/24 見積明細自動計算機能対応 WGCH END
    	 // 三泊数据
        List<Lead__c> leads = TestCommon.createLead(System.today(), 1, 3); 
        Lead__c leadInfo = leads[0];
        List<AccountMaster__c> prods = TestCommon.createProductMst(2);
        ApexPages.StandardController contrl = new ApexPages.StandardController(leadInfo);
        BookingEstimateItemSetup ctrl = new BookingEstimateItemSetup(contrl);
    	 // 見積場合
        ApexPages.StandardController contrl2 = new ApexPages.StandardController(leadInfo);
        Apexpages.currentPage().getParameters().put('Id',leadInfo.Id);
        Apexpages.currentPage().getParameters().put('quota',ctrl.quotaOrTemplateId);
        BookingEstimateItemSetup ctrl2 = new BookingEstimateItemSetup(contrl2);
        List<BookingEstimateItemSetup.BookEstItem> queryLst = ctrl2.oBookEstLst;
        BookingEstimateItemSetup.BookEstItem lastItem = queryLst[queryLst.size()-1];
        lastItem.sobj.refAccountMaster__c = prods[0].Id;
        lastItem.productNm = prods[0].Name;
        lastItem.prodNums = '5';
        lastItem.sobj.UnitPrice__c = 2000;
       	lastItem.sobj.UseDate__c = CommUtils.stringtoDate('2222/01/01');
       	ctrl2.upsertData();
       	ctrl2.kariKakuTei();
    	Test.startTest();
        List<Quota__c> results = [select id,LeadRef__c from Quota__c where id=:ctrl2.quotaOrTemplateId ];
        // 多見積の画面
        Map<String,Object> req = new Map<String,Object>();
        req.put('quotaid',results[0].id);
        req.put('field','quotaDesc');
        req.put('value','123');
        List<Object> obj = new List<Object>{req};
        String request = JSON.serialize(obj);
        BookingEstimateItemSetups.saveQuota(request);
        request = JSON.serialize(req);
        BookingEstimateItemSetups.saveResize('{1,:3:2}');
        /*
        // moreList
        */
        req.put('mark',true);
        request = JSON.serialize(req);
        BookingEstimateItemSetups.saveBookMark(request);
        ApexPages.StandardController contrl3 = new ApexPages.StandardController(new Lead__c(id=results[0].LeadRef__c));
        BookingEstimateItemSetups ctrls = new BookingEstimateItemSetups(contrl3);
        ctrls.refreshDetail();
        BookingEstimateItemSetups.deleteQuota(request);
		Test.stopTest();
    }
    static testMethod void myUnitTest002(){
        CommDefine__c def = TestCommon.createCommDefine();
        def.ReducedTaxRateFlg__c = true;
        update def;
        TestCommon.createShopInfo();
    	getCsvSetupConfig();
    	 // 三泊数据
        List<Lead__c> leads = TestCommon.createLead(System.today(), 1, 3); 
        Lead__c leadInfo = leads[0];
        String subIds = '';
        for (Lead__c lead : leads) {
        	subIds += lead.id + ',';
        }
        Quota__c quo = new Quota__c();
        quo.LeadRef__c = leadInfo.id;
        insert quo;
        List<AccountMaster__c> productLst = TestCommon.createProductMst(5);
        AccountMaster__c prod = Testcommon.createPlanProd();
        TestCommon.createBookEstItem(leadInfo,prod);
    	// 見積場合
        ApexPages.StandardController contrl2 = new ApexPages.StandardController(leadInfo);
        Apexpages.currentPage().getParameters().put('Id',leadInfo.Id);
        Apexpages.currentPage().getParameters().put('quota',quo.id);
        BookingEstimateItemSetup ctrl2 = new BookingEstimateItemSetup(contrl2);
        List<BookingEstimateItemSetup.BookEstItem> queryLst = ctrl2.oBookEstLst;
        BookingEstimateItemSetup.BookEstItem lastItem = queryLst[queryLst.size()-1];
        lastItem.sobj.refAccountMaster__c = prod.Id;
        lastItem.productNm = prod.Name;
        lastItem.prodNums = '5';
        lastItem.sobj.UnitPrice__c = 2000;
       	lastItem.sobj.UseDate__c = CommUtils.stringtoDate('2222/01/01');
        // lastItem.sobj.PlanBrkInfo__c = '13000.00,8.0000,10,1,100,,' + prod.id + ',室料;';
       	ctrl2.updateCurQuota();
    }
    static testMethod void errUnitTest() {
    	Test.startTest();
    	// 2018/10/24 見積明細自動計算機能対応 WGCH BEGIN
        Document doc = TestCommon.createBillSimpleHelpConfigDoc();
        // 2018/10/24 見積明細自動計算機能対応 WGCH END
    	ApexPages.StandardController contrl = new ApexPages.StandardController(new Lead__c());
    	BookingEstimateItemSetups ctrls = new BookingEstimateItemSetups(contrl);
    	// 三泊数据
        Lead__c leadInfo = TestCommon.createLead(); 
    	 // 見積場合
        ApexPages.StandardController contrl2 = new ApexPages.StandardController(leadInfo);
        Apexpages.currentPage().getParameters().put('Id',leadInfo.Id);
        Apexpages.currentPage().getParameters().put('newTemp','');
        BookingEstimateItemSetup ctrl2 = new BookingEstimateItemSetup(contrl2);
        ctrl2.nextStep();
        Test.stopTest();
    }
    static testMethod void myUnitTest003() {
        // TO DO: implement unit test
        // 店舗情報を初期化する
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	comDef.FacilityCode__c = '3';
    	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
    	comDef.ReducedTaxRateFlg__c = true;
    	comDef.PDFPlanBrkIsShowFlg__c = true;
    	// 2019/07/30 軽減税率機能対応 WGCH END
    	update comDef;
        // TO DO: implement unit test
        // 三泊数据
        List<Lead__c> leads = TestCommon.createLead(System.today(), 1, 3); 
        Lead__c leadInfo = leads[0];
        String subIds = '';
        for (Lead__c lead : leads) {
        	subIds += lead.id + ',';
        }
        List<AccountMaster__c> prods = TestCommon.createProductMst(2);
        TestCommon.createBookEstItem(leadInfo,prods[0]);
        ApexPages.StandardController contrl = new ApexPages.StandardController(leadInfo);
        Apexpages.currentPage().getParameters().put('Id',leadInfo.Id);
        Apexpages.currentPage().getParameters().put('more',subIds);
        Apexpages.currentPage().getParameters().put('mitumo','');
        Apexpages.currentPage().getParameters().put('auto','');
        getCsvSetupConfig();
        Test.startTest();
        BookingEstimateItemSetup ctrl = new BookingEstimateItemSetup(contrl);
        List<BookingEstimateItemSetup.BookEstItem> queryLst = ctrl.oBookEstLst;
        BookingEstimateItemSetup.BookEstItem item2 = queryLst[3];
        item2.sobj.refAccountMaster__c = prods[1].Id;
        item2.productNm = prods[1].Name;
        item2.prodNums = '4';
        item2.sobj.UnitPrice__c = 5000;
        ctrl.addBookingItem();
        queryLst = ctrl.oBookEstLst;
        BookingEstimateItemSetup.BookEstItem lastItem = queryLst[queryLst.size()-1];
        lastItem.sobj.refAccountMaster__c = prods[0].Id;
        lastItem.productNm = prods[0].Name;
        lastItem.prodNums = '4';
        lastItem.sobj.UnitPrice__c = 5000;
       	lastItem.sobj.UseDate__c = CommUtils.stringtoDate('2015/01/01');
        ctrl.kariKakuTei();
        comDef.PDFPlanBrkIsShowFlg__c = false;
    	// 2019/07/30 軽減税率機能対応 WGCH END
        update comDef;
        lastItem.prodNums = '3';
        ctrl.kariKakuTei();
       	// 見積場合
       	Quota__c quota = new Quota__c(id = ctrl.quotaOrTemplateId);
        ApexPages.StandardController contrl3 = new ApexPages.StandardController(quota);
       	QuotaPDF pdf = new QuotaPDF(contrl3);
        boolean showFlg = pdf.stampIsShowFlg;
        pdf.getCustomer();
        pdf.getQuota();
        pdf.getNumberFormat();
        pdf.getRealLeadIds(leads[0]);
    }
    /*
    private void createQuota(ApexPages.StandardController contrl){
    	Apexpages.currentPage().getParameters().put('Id',leadInfo.Id);
		Apexpages.currentPage().getParameters().put('ptype','1');
		Apexpages.currentPage().getParameters().put('Contract','2017/07/01');
		Apexpages.currentPage().getParameters().put('PayDuration','zhifuqixian');
		Apexpages.currentPage().getParameters().put('Charge','null');
		Apexpages.currentPage().getParameters().put('Comment','leadInfo.QuotationComment__c');
    	BookingEstimateItemSetup ctrl = new BookingEstimateItemSetup();
    }*/
     private static void getCsvSetupConfig() {
        String csv = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP><SHOPCODE></SHOPCODE><PAYMENT><CONVERT><PAYTYPE>現金</PAYTYPE><MEIDALAB>預り／現計</MEIDALAB></CONVERT><CONVERT><PAYTYPE>カード</PAYTYPE><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB></CONVERT><CONVERT><PAYTYPE>売掛金</PAYTYPE><MEIDALAB>掛計</MEIDALAB></CONVERT><CONVERT><PAYTYPE>クーポン</PAYTYPE><MEIDALAB>クーポン</MEIDALAB></CONVERT><CONVERT><PAYTYPE>値引</PAYTYPE><MEIDALAB>値引・割引券</MEIDALAB></CONVERT><CONVERT><PAYTYPE>予約金</PAYTYPE><MEIDALAB>予約金</MEIDALAB></CONVERT></PAYMENT><PAYMEIDA><CONVERT><MEIDALAB>預り／現計</MEIDALAB><PRODCODE>87001</PRODCODE></CONVERT><CONVERT><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB><PRODCODE>85201</PRODCODE></CONVERT><CONVERT><MEIDALAB>掛計</MEIDALAB><PRODCODE>85101</PRODCODE></CONVERT><CONVERT><MEIDALAB>クーポン</MEIDALAB><PRODCODE>85610</PRODCODE></CONVERT><CONVERT><MEIDALAB>値引・割引券</MEIDALAB><PRODCODE>87005</PRODCODE></CONVERT><CONVERT><MEIDALAB>予約金</MEIDALAB><PRODCODE>87001</PRODCODE></CONVERT></PAYMEIDA></SHOP></root>';
        
        Document doc = new Document();
        doc.Name = 'BillSimpleHelpConfig';
        doc.DeveloperName = doc.Name;
        doc.FolderId = UserInfo.getUserId();
        doc.Body = Blob.valueOf(csv);
        insert doc;
    }
}