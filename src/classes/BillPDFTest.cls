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
private class BillPDFTest {
	static testMethod void firstTest()
	{
		// TO DO: implement unit test
        Test.startTest();
        // 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH BEGIN
        ReportLogo__c rep = TestCommon.createRepLogo();
        ShopInformation__c shop = TestCommon.createShopInfo();
        rep.ShopInfoRef__c = shop.Id;
        update rep;
        User currUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        currUser.ShopCode__c = shop.ShopCode__c;
        update currUser;
        // 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH END
        // 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	ExchangeRate__c rate = TestCommon.createExchangeRate(CommBaseCtrl.getCurrency(),'JPY');
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
    	
    	Apexpages.currentPage().getParameters().put('bulkId',accObj.Id);
    	BillPDF pdf1 = new BillPDF(contrl);
    	System.assert(pdf1.getTran() != null);
    	System.debug('20161111111111::::::::::::');
	}
    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        Test.startTest();
        // 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH BEGIN
        ReportLogo__c rep = TestCommon.createRepLogo();
        ShopInformation__c shop = TestCommon.createShopInfo();
        rep.ShopInfoRef__c = shop.Id;
        update rep;
        User currUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        currUser.ShopCode__c = shop.ShopCode__c;
        update currUser;
        // 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH END
        // 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	ExchangeRate__c rate = TestCommon.createExchangeRate(CommBaseCtrl.getCurrency(),'JPY');
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
    	
    	//Apexpages.currentPage().getParameters().put('id',accObj.Id);
    	Apexpages.currentPage().getParameters().put('bulkId',accObj.Id);
    	Apexpages.currentPage().getParameters().put('cy','JPY');
    	BillPDF pdf = new BillPDF(contrl);
    	pdf.extInitAction();
    	pdf.getNumberFormat();
    	
    	
    	pdf.getAccoutInfo();
    	pdf.getAccountNo();
    	pdf.getCustomer();
    	pdf.getCharge();
    	pdf.getRequestAmount();
    	pdf.getTax();
    	pdf.getIssueDate();
    	pdf.getAdvancesReceived();
    	pdf.getTran();
    	pdf.getAmoutIncDiscont();
    	pdf.getServiceDate();
    	
    	// TO DO: implement unit test
    		TestCommon.createShopInfo();
    	
    	Apexpages.currentPage().getParameters().put('bulkId',accObj.Id);
    	BillPDF pdf1 = new BillPDF(contrl);
    	//pdf.getReportLogo();
    	//pdf.isFirstPage();
    	System.assert(pdf1.getTran() != null);
    }
    static testMethod void myUnitTest1() {   
        // TO DO: implement unit test
        Test.startTest();
        // 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH BEGIN
        ReportLogo__c rep = TestCommon.createRepLogo();
        ShopInformation__c shop = TestCommon.createShopInfo();
        rep.ShopInfoRef__c = shop.Id;
        update rep;
        // 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH END
        JMST__c taxMst = TestCommon.createTaxMst();
        CommDefine__c def = TestCommon.createCommDefine();
   		def.BillReportCommentAutoBreakFlg__c = false;
   		def.BillReportStampIsShowFlg__c = true;
   		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
   		def.ReducedTaxRateFlg__c = true;
   		def.PDFPlanBrkIsShowFlg__c = true;
   		// 2019/07/30 軽減税率機能対応 WGCH END
    	update def;
        ShopInformation__c shopInfo = TestCommon.createShopInfo();
    	shopInfo.payee1__c = '23';
    	shopInfo.payee2__c = '23';
    	shopInfo.payee3__c = '23';
    	shopInfo.payeeAcount__c = '23';
    	update shopInfo;
    	ReportLogo__c tempShopLogo = TestCommon.createRepLogo();
        tempShopLogo.ShopInfoRef__c = shopInfo.Id;
        update tempShopLogo;
    	User currUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	currUser.ShopCode__c = shopInfo.ShopCode__c;
    	update currUser;
        // 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	ExchangeRate__c rate = TestCommon.createExchangeRate(CommBaseCtrl.getCurrency(),'JPY');
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(4);
    	// 見積明細を作成する
    	BookingEstimateItem__c bookingItem = TestCommon.createBookEstItem(leadInfo, productLst[0]);
        // 商品２は前受付金に変更を行う
        AccountMaster__c accMst = productLst[1];
        accMst.ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
        accMst.PaymentType__c = 'カード';  // XMLの定義と合わせるが必要です
        update accMst;
        AccountMaster__c accMstPay = productLst[2];
        accMstPay.ActionType__c = CommConst.PROD_ACTION_TYPE_PY;
        accMstPay.PaymentType__c = '現金';    // XMLの定義と合わせるが必要です
        update accMstPay;
    	// 予約情報のステータス：チェックインに変更する
    	leadInfo.Field298__c = 'チェックイン完';
    	update leadInfo;
    	RsvAccount__c rsv = TestCommon.createRsvAccount();
    	AccountAcount__c aa = TestCommon.createAccountAcount(rsv.Id, leadInfo.Id);
    	// 会計画面に動作確認を行う
    	List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfo.Id];
    	AccountAcount__c accObj = accObjLst[0];
    	TTend__c ttitem = TestCommon.createTTend(rsv.Id, accObj.Id); 
    	ttitem.field2__c = '22'; 
    	ttitem.field3__c = '予約金';
    	//ttitem.Field28__c = 5000;  
    	//ttitem.Field29__c = 5000;    	
    	ttitem.RowNo__c  = 44;	// メディア種別,メディア名称
		ttitem.Field16__c = '55';
		ttitem.Field17__c = '66';
		ttitem.Field20__c = '77';// 単価,枚数,支払金額 
		//ttitem.SplitGroupNo__c = '88';
		//ttitem.PaymentType__c = '99';
		//ttitem.PayProductName__c = '111';
		//ttitem.UseDate__c = Date.today();
		update ttitem;
		Apexpages.currentPage().getParameters().put('id',leadInfo.Id);
		//System.debug(LoggingLevel.INFO, 'TTend__c::::::::::::' + [select field3__c, Field1__c from TTend__c
		//	where  ( Field3__c = :CommConst.MEDIA_TYPE_11 OR Field3__c = :CommConst.MEDIA_TYPE_21) 
		//	Group by Field3__c, Field1__c]);
    	Test.stopTest();   	
    	ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
    	BillInput_Ctrl ctrl = new BillInput_Ctrl(contrl);
    	ctrl.initAction();
    	ctrl.calPaymentInfo();
    	ctrl.upsertData();
    	//Apexpages.currentPage().getParameters().put('id',accObj.Id);
    	Apexpages.currentPage().getParameters().put('bulkId',accObj.Id);
    	Apexpages.currentPage().getParameters().put('cy','JPY');
    	BillPDF pdf = new BillPDF(contrl);
    	pdf.extInitAction();
    	pdf.getNumberFormat(); 
    	pdf.getReportLogo();	
    	pdf.getAccoutInfo();
    	pdf.getAccountNo();
    	pdf.getCustomer();
    	pdf.getCharge();
    	pdf.getRequestAmount();
    	pdf.getTax();
    	pdf.getIssueDate();
    	pdf.getAdvancesReceived();
    	pdf.getTran();
    	pdf.getAmoutIncDiscont();
    	pdf.getServiceDate();
    	pdf.getServiceAmount ();   	
    	// TO DO: implement unit test
    		TestCommon.createShopInfo();    	
    	Apexpages.currentPage().getParameters().put('bulkId',accObj.Id);
    	BillPDF pdf1 = new BillPDF(contrl);
    	//pdf.getReportLogo();
    	//pdf.isFirstPage();
    	System.assert(pdf1.getTran() != null);
    	CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo();
    	// 特別税
    	Decimal SpecialTax = productLst[0].SpecialTax__c;
		Decimal unitPrice = CommUtils.nullToZero(productLst[0].Field5__c);  // <-税金含め単価です
		Decimal qty = CommUtils.nullToZero(bookingItem.Amount__c);
        priceInfo.process(unitPrice , qty , taxMst.TaxRate__c, productLst[0].ServiceRate__c);    	
    	// 金額設定判定		
    }
    static testMethod void myUnitTest2() {
        // TO DO: implement unit test
        Test.startTest();
        // 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH BEGIN
        ReportLogo__c rep = TestCommon.createRepLogo();
        ShopInformation__c shop = TestCommon.createShopInfo();
        rep.ShopInfoRef__c = shop.Id;
        update rep;
        User currUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        currUser.ShopCode__c = shop.ShopCode__c;
        update currUser;
        // 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH END
        JMST__c taxMst = TestCommon.createTaxMst();
        CommDefine__c def = TestCommon.createCommDefine();
   		def.BillReportCommentAutoBreakFlg__c = false;
   		def.BillReportStampIsShowFlg__c = true;
   		def.BillInputSwitchCode__c='2';
   		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
   		def.ReducedTaxRateFlg__c = true;
   		def.PDFPlanBrkIsShowFlg__c = true;
		def.BillReportReceiptIsShowFlg__c = true;
   		// 2019/07/30 軽減税率機能対応 WGCH END
    	update def;
        // 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	ExchangeRate__c rate = TestCommon.createExchangeRate(CommBaseCtrl.getCurrency(),'JPY');
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
    	// 見積明細を作成する
    	BookingEstimateItem__c bookingItem = TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	// 予約情報のステータス：チェックインに変更する
    	leadInfo.Field298__c = 'チェックイン完';
    	update leadInfo;
        RsvAccount__c rsv = TestCommon.createRsvAccount();
    	AccountAcount__c aa = TestCommon.createAccountAcount(rsv.Id, leadInfo.Id);
    	// 会計画面に動作確認を行う
    	List<AccountAcount__c> accObjLst = [select id,frs__c,IsNewLayout__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfo.Id];
    	AccountAcount__c accObj = accObjLst[0];
    	TTend__c ttitem = TestCommon.createTTend(rsv.Id, accObj.Id); 
    	ttitem.field2__c = '22'; 
    	ttitem.field3__c = '予約金';
    	//ttitem.Field28__c = 5000;  
    	//ttitem.Field29__c = 5000;    	
    	ttitem.RowNo__c  = 44;	// メディア種別,メディア名称
		ttitem.Field16__c = '55';
		ttitem.Field17__c = '66';
		ttitem.Field20__c = '77';// 単価,枚数,支払金額 
		//ttitem.SplitGroupNo__c = '88';
		//ttitem.PaymentType__c = '99';
		//ttitem.PayProductName__c = '111';
		//ttitem.UseDate__c = Date.today();
		update ttitem;
    	Test.stopTest();
    	ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
    	
    	//Apexpages.currentPage().getParameters().put('id',accObj.Id);
    	Apexpages.currentPage().getParameters().put('bulkId',accObj.Id);
    	Apexpages.currentPage().getParameters().put('cy','JPY');
    	BillPDF pdf = new BillPDF(contrl);
    	pdf.extInitAction();
    	pdf.getNumberFormat();	
    	pdf.getAccoutInfo();
    	pdf.getAccountNo();
    	pdf.getCustomer();
    	pdf.getCharge();
    	pdf.getRequestAmount();
    	pdf.getTax();
    	pdf.getIssueDate();
    	pdf.getAdvancesReceived();
    	pdf.getTran();
    	pdf.getAmoutIncDiscont();
    	pdf.getServiceDate();   	
    	// TO DO: implement unit test
    		TestCommon.createShopInfo();
    	
    	Apexpages.currentPage().getParameters().put('bulkId',accObj.Id);
    	BillPDF pdf1 = new BillPDF(contrl);
    	//pdf.getReportLogo();
    	//pdf.isFirstPage();
    	System.assert(pdf1.getTran() != null);
    	CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo();
    	// 特別税
    	Decimal SpecialTax = productLst[0].SpecialTax__c;
		Decimal unitPrice = CommUtils.nullToZero(productLst[0].Field5__c);  // <-税金含め単価です
		Decimal qty = CommUtils.nullToZero(bookingItem.Amount__c);
        priceInfo.process(unitPrice , qty , taxMst.TaxRate__c, productLst[0].ServiceRate__c);    	
    	// 金額設定判定		
    } 
    
}