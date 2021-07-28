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
private class BillInput_Ctrl_Test {

    static testMethod void LeadToAccountCase() {
		// 店舗情報を初期化する
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	comDef.FacilityCode__c = '3';
    	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
    	comDef.ReducedTaxRateFlg__c = true;
    	comDef.PDFPlanBrkIsShowFlg__c = true;
		comDef.AccountServiceChargeIsShow__c = '2';
    	// 2019/07/30 軽減税率機能対応 WGCH END
    	update comDef;
    	Test.startTest();
    	// 2018/12/15 請求書レイアウト改善 BY zyz BEGIN 
    	getBillPdfConfig();
    	// 2018/12/15 請求書レイアウト改善 BY zyz END 
    	ShopInformation__c shop = TestCommon.createShopInfo();
    	ReportLogo__c rep = TestCommon.createRepLogo();
    	rep.ShopInfoRef__c = shop.Id;
    	update rep;
        User currUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        currUser.ShopCode__c = shop.ShopCode__c;
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
    	System.assert(!Apexpages.hasMessages(Apexpages.Severity.ERROR));
    	ctrl.voidProcess();
    	ctrl.voidProcessCancel();

    	Apexpages.currentPage().getParameters().put('retUrl','TestPage');
    	Apexpages.currentPage().getParameters().put('bulkId',accObj.Id);
    	ctrl.gotoCancel();
    	Pagereference pg = ctrl.gotoAccountsDetailPg();
    	System.assertNotEquals(pg, null);

        // Report Logo作成
        TestCommon.createRepLogo();
		
		Apexpages.currentPage().getParameters().put('g','1');
    	// PDF起動する
    	ApexPages.StandardController contr2 = new ApexPages.StandardController(accObj);
    	// 見積書
		getCsvSetupConfig();
		AccountPDF pdf = new AccountPDF(contr2);
    	pdf.getTran();
    	pdf.getCustomer();
    	pdf.getAccountNo();
    	pdf.getCharge();
    	pdf.getDate();
    	pdf.getTax();
    	pdf.getReportLogo();
		pdf.extInitAction();
		pdf.getServiceDate();
		pdf.getAdvancesReceived();
		pdf.getAmoutIncDiscont();
		pdf.getAccountName();
		// String wd = pdf.referenceWidth;
		Apexpages.currentPage().getParameters().put('pType','r');
    	AccountPDF pdf2 = new AccountPDF(contr2);
		
		Apexpages.currentPage().getParameters().put('pType','rf');
		AccountPDF pdf3 = new AccountPDF(contr2);
		
    	BillPDF bPdf = new BillPDF(contr2);
        bPdf.getTran();
        bPdf.getCustomer();
        bPdf.getAccountNo();
        bPdf.getCharge();
        bPdf.getIssueDate();
        bPdf.getTax();
        bPdf.getReportLogo();
//        bPdf.getAccoutInfo();
		bPdf.extInitAction();
		bPdf.getAdvancesReceived();
		bPdf.getAmoutIncDiscont();
		bPdf.getServiceDate();
		bPdf.getAccoutInfo();
        
		// 2019/04/15 BY zyz BEGIN
        CommDefine__c def = TestCommon.createCommDefine();
   		def.BookingReportStampIsShowFlg__c = true;
   		def.AccountServiceChargeIsShow__c = '2';
   		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
        def.ReducedTaxRateFlg__c = true;
        def.PDFPlanBrkIsShowFlg__c = true;
        // 2019/07/30 軽減税率機能対応 WGCH END
    	update def;
    	// 2019/04/15 BY zyz END
        ApexPages.StandardController contr3 = new ApexPages.StandardController(leadInfo);
        LeadPDF lPdf = new LeadPDF(contr3);
        System.assertNotEquals(lPdf.sumInfo, null);
        System.assert(lPdf.allPageList.size() > 0);
        //lPdf.getReportLogo();
        lPdf.getLead();
        LeadPDF.TotalInfo pdfSumInfo = lPdf.sumInfo;
        System.assert(pdfSumInfo.amoutQuotePriceIncTax != null);
        System.assert(pdfSumInfo.amoutTax != null);
        System.assert(pdfSumInfo.amoutUsedPriceIncTax != null);
    }

    static testMethod void productSearchCase() {
		CommDefine__c def = TestCommon.createCommDefine();
		def.ShopAccountSearchDiv__c = '1';
		update def;
		TestCommon.createShopInfo() ;
		ApexPages.currentPage().getParameters().put('par','123');
		ApexPages.currentPage().getParameters().put('sync','123');
		ApexPages.currentPage().getParameters().put('dinner','123');
		
    	// List<AccountMaster__c> prodList = TestCommon.createProductMst(5);
		AccountMaster__c acc = TestCommon.createPlanProd();
    	ProductSearch_Ctrl ctrl = new ProductSearch_Ctrl();
    	ctrl.init();
    	ctrl.c_productNm = acc.Name;
    	ctrl.c_dpId = '1111';
    	ctrl.c_gpId = '2222';
    	//ctrl.c_opId = '3333';
    	ctrl.queryInfo();
    	String p_op = ctrl.p_operWinJsFunNm;
		ctrl.accountMasterItem();
    	ctrl.insertInit();
    	ctrl.newAccMst.name = 'テスト商品';
    	ctrl.newAccMst.Field5__c = 2000;
    	ctrl.newAccMst.jmstRef__c = TestCommon.createTaxMst().Id;
    	ctrl.insertData();
    	ctrl.cancelAct();

		ctrl.firstPage();
		ctrl.previousPage();
		ctrl.nextPage();
		ctrl.lastPage();
		boolean checkFlg = ctrl.isIns == ctrl.isUpd && ctrl.isIns == ctrl.isSel;
    	System.assert(!Apexpages.hasMessages(Apexpages.Severity.ERROR));
    }
	
	// 会計情報明細データ更新機能の確認
	static testMethod void tranCase_1_1() {

    	// 予約情報を作成する[プラン付け]
    	Lead__c leadInfo = TestCommon.createLead();
    	// 商品情報を作成する
		// Normal商品
		List<AccountMaster__c> productLst = TestCommon.createProductMst(2);
		//List<AccountMaster__c> productLst2 = TestCommon.createFullProductMst(5);
		// プラン商品作成
		AccountMaster__c planProd0 = TestCommon.createPlanProd();
		AccountMaster__c planProd1 = TestCommon.createPlanProd();
		//AccountMaster__c planProd2 = TestCommon.createPlanProd();
		//　上記プランの関連プラン商品を取得する

		// 見積明細を作成する
    	TestCommon.createBookEstItems(leadInfo, productLst);
    	
    	Test.startTest();
    	// 予約情報のステータス：チェックインに変更する
    	leadInfo.Field298__c = 'チェックイン完';
    	update leadInfo;
	
    	// 会計画面に動作確認を行う
    	List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfo.Id];
    	AccountAcount__c accObj = accObjLst[0];
    	ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);

		// 画面起動
    	BillInput_Ctrl ctrl = new BillInput_Ctrl(contrl);
    	ctrl.initAction();
    	
    	List<BillInput_Ctrl.TranItem> rsTranItems = ctrl.oTranSobjLst;
    	Integer trueDataNums = 0;
    	for (BillInput_Ctrl.TranItem item : rsTranItems) {
    		System.debug('item:::' +item);
    		if (item.sobj.Id != null) trueDataNums++;
    	}
    	// Plan(1) + 5件個別商品
		System.assertEquals(trueDataNums, productLst.size() + 1);

		String accountId = ctrl.oAcountSobj.Id;
		// 会計商品内容を更新して、ＤＢへ反映する
		// プラン明細データの単価を更新して、プラン数量も更新する
		// 該当プランの明細から単価再定義
		//List<Tran1__c> plan0DetailTranLst = [select id from Tran1__c where ParentTran1Ref__c = :rsTranItems[0].sobj.Id Order By ]; 
		//List<BillInput_Ctrl.PlanDetail> planDetailLst = BillInput_Ctrl.getAccountMstLstByPlan(rsTranItems[0].sobj.Id, rsTranItems[0].sobj.Field1__c, '');
		List<BillInput_Ctrl.PlanDetail> planDetailLst0 = BillInput_Ctrl.getAccountMstLstByPlan(rsTranItems[0].sobj.Id, '', planProd0.Id);
		// ０行目会計明細の商品ＩＤ
		String item0OrgProdId =  rsTranItems[0].sobj.Field7__c;
		String item0OrgId = rsTranItems[0].sobj.Id;
		// 該当プラン関連の会計明細
		List<Tran1__c> orgTran0Detail = [select Field5__c, Field20__c from Tran1__c where ParentTran1Ref__c = :item0OrgId ];
		System.assert(!orgTran0Detail.isEmpty());

		// 単価再定義
		Decimal planSummary = 0;
		String planDetailString = '';
		rsTranItems[0].productNm = planProd0.Name;
		rsTranItems[0].sobj.Field7__c = planProd0.Id;
		rsTranItems[0].tranId = '';
		rsTranItems[0].accRefId = '';
		
		// 商品３に、別の普通商品に設定する,単価、数量など設定を行う
		planSummary = 0;
		planDetailString = '';
		for (BillInput_Ctrl.PlanDetail pl : planDetailLst0) {
			pl.prodPrice = String.valueOf(Decimal.valueOf(pl.prodPrice.replaceAll(',', ''))  + 100);
			planSummary += Decimal.valueOf(pl.prodPrice);
			planDetailString += pl.sobjId + ':' + pl.prodPrice + ';';
		}
		rsTranItems[0].sobj.Field20__c = String.valueOf(planSummary);
		rsTranItems[0].sobj.Field21__c = String.valueOf(Decimal.valueOf(rsTranItems[2].sobj.Field21__c) + 1);
		rsTranItems[0].sobj.PlanDetailSyncInfo__c = planDetailString;

		// 商品１に、数量、単価更新を行う
		rsTranItems[1].productNm = 'テスト商品１名前再定義';
		rsTranItems[1].sobj.Field20__c = String.valueOf(Decimal.valueOf(rsTranItems[1].sobj.Field20__c) + 100);
		rsTranItems[1].sobj.Field21__c = String.valueOf(Decimal.valueOf(rsTranItems[1].sobj.Field21__c) + 1);
		// 商品２に、プラン商品１に更新を行う、プラン明細に単価など変更なし、数量と単価を更新する
		rsTranItems[2].productNm = planProd1.Name;
		rsTranItems[2].sobj.Field7__c = planProd1.Id;
		rsTranItems[2].tranId = '';
		rsTranItems[2].accRefId = '';
		List<BillInput_Ctrl.PlanDetail> planDetailLst2 = BillInput_Ctrl.getAccountMstLstByPlan(rsTranItems[2].sobj.Id, '', planProd1.Id);
		// 商品３に、別の普通商品に設定する,単価、数量など設定を行う
		planSummary = 0;
		planDetailString = '';
		for (BillInput_Ctrl.PlanDetail pl : planDetailLst2) {
			pl.prodPrice = String.valueOf(Decimal.valueOf(pl.prodPrice.replaceAll(',', ''))  + 100);
			planSummary += Decimal.valueOf(pl.prodPrice);
			planDetailString += pl.sobjId + ':' + pl.prodPrice + ';';
		}
		rsTranItems[2].sobj.Field20__c = String.valueOf(planSummary);
		rsTranItems[2].sobj.Field21__c = String.valueOf(Decimal.valueOf(rsTranItems[2].sobj.Field21__c) + 1);
		rsTranItems[2].sobj.PlanDetailSyncInfo__c = planDetailString;
	
		// 支払い計算、更新を行う	
    	ctrl.calPaymentInfo();
    	ctrl.upsertData();
		// 更新処理内容の確認
		// 商品０のいり買え前の関連プラン明細を削除する
		Set<Id> orgTran0IdSet = new Set<Id>();
		for (Tran1__c org : orgTran0Detail) { orgTran0IdSet.add(org.Id); }
		List<Tran1__c> orgTran0Chk = [select Field5__c, Field20__c from Tran1__c where ParentTran1Ref__c = :item0OrgId And Id in :orgTran0IdSet ];
		System.assert(orgTran0Chk.isEmpty(), orgTran0Chk);
    	// 新規のプラン情報は正確に更新、新規作成を行う、数量は正確に反映する
    	List<BillInput_Ctrl.PlanDetail> planDetailLst0_N = BillInput_Ctrl.getAccountMstLstByPlan(item0OrgId, accountId,  '');
    	/*
    	System.assertEquals(planDetailLst0_N.size(), planDetailLst0.size());
    	for (Integer i=0;i<planDetailLst0_N.size();i++) {
    		System.assertEquals(planDetailLst0_N[i].prodPrice.replaceAll(',',''),planDetailLst0[i].prodPrice);
    	}*/
		Test.stopTest();	
	}
	
	// 会計登録場合、自動設定機能の確認
	static testMethod void testInitInfoChk() {
    	// 予約情報を作成する[プラン付け]
    	Lead__c leadInfo = TestCommon.createLead();
    	// 商品情報を作成する
		// Normal商品
		List<AccountMaster__c> productLst = TestCommon.createProductMst(5);
		List<AccountMaster__c> productLst2 = TestCommon.createFullProductMst(5);
		// プラン商品作成
		AccountMaster__c planProd0 = TestCommon.createPlanProd();
		AccountMaster__c planProd1 = TestCommon.createPlanProd();
		AccountMaster__c planProd2 = TestCommon.createPlanProd();
		//　上記プランの関連プラン商品を取得する
		// 見積明細を作成する
    	TestCommon.createBookEstItems(leadInfo, productLst);
		Test.startTest();
    	// 予約情報のステータス：チェックインに変更する
    	leadInfo.Field298__c = 'チェックイン完';
    	leadInfo.StayPersons__c = 0;
    	update leadInfo;

    	// 会計画面に動作確認を行う
    	List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfo.Id];
    	AccountAcount__c accObj = accObjLst[0];
    	ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
    	BillInput_Ctrl ctrl = new BillInput_Ctrl(contrl);
    	ctrl.initAction();
    	ctrl.calPaymentInfo();
    	ctrl.oAcountSobj.PaymentFlg__c = true;
    	ctrl.upsertData();
		System.assert([select PaymentFlg__c from lead__c where id = :leadInfo.Id].PaymentFlg__c);
		Test.stopTest();
	}
	@isTest(SeeAllData=false)
	static void testAccShopSetup() {
		ShopInformation__c shop = TestCommon.createShopInfo();
		// 店舗は空白に設定する
		User currUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	currUser.ShopCode__c = shop.ShopCode__c;
    	update currUser;
		// 直接画面から会計を登録する場合、予約データが未選択する場合、ログインユーザーの店舗コードを設定して、会計を登録する場合
		// 店舗情報は該当会計に設定する
		RsvAccount__c rsv = TestCommon.createRsvAccount();
    	AccountAcount__c accObj = new AccountAcount__c();
    	ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
		// 画面起動
    	BillInput_Ctrl ctrl = new BillInput_Ctrl(contrl);
    	ctrl.initAction();
		ctrl.oAcountSobj.frs__c = rsv.Id;
		ctrl.insertData();

		// ログインユーザーの店舗コードが未設定する場合、会計に店舗情報を設定を行わない
		List<AccountAcount__c> accLst = [select id,ShopSeq__c,ShopCode__c,ShopName__c  from AccountAcount__c where id = :ctrl.oAcountSobj.Id];
		System.assertEquals(accLst[0].ShopSeq__c, shop.Seq__c, accLst);
		System.assertEquals(accLst[0].ShopCode__c, shop.ShopCode__c, accLst);
		System.assertEquals(accLst[0].ShopName__c, shop.Name, accLst);
	}
	// 売上計上日可変機能対応[新規作成から]
	@isTest(SeeAllData=false)
	static void testSalesAutoSetup1() {
		// 当日
		Date todayDt = Date.Today();
		DateTime todayDtime = DateTime.newInstance(todayDt.year(), todayDt.month(), todayDt.day());
		// 新規の場合、初期日は当日に設定を行う
    	AccountAcount__c accObj = new AccountAcount__c();
    	ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
		// 画面起動
    	BillInput_Ctrl ctrl = new BillInput_Ctrl(contrl);
    	ctrl.initAction();
    	System.assertEquals(ctrl.oAcountSobj.salesDate__c,todayDt);
		// 別の日付を指定して、新規登録を行う
		ctrl.oAcountSobj.Salesdate__c = todayDt.addDays(3);
		ctrl.insertData();
		// 売上データを自動作成確認
		String condStrName = todayDtime.adddays(3).format('yyyyMMdd');
		List<RsvAccount__c> rsvLst = [select id from RsvAccount__c where name = :condStrName];
		System.assertEquals(rsvLst.size(), 1);
		System.assertEquals(ctrl.oAcountSobj.frs__c, rsvLst[0].Id);
		// 会計明細設定を行う
		// プラン商品作成
		AccountMaster__c planProd0 = TestCommon.createPlanProd();
		//AccountMaster__c planProd1 = TestCommon.createPlanProd();
    	List<BillInput_Ctrl.TranItem> rsTranItems = ctrl.oTranSobjLst;
    	rsTranItems[0].productNm = planProd0.Name;
    	rsTranItems[0].sobj.Field7__c = planProd0.Id;
    	rsTranItems[0].sobj.Field21__c = '2';
    	rsTranItems[0].sobj.Field20__c = '10000';
    	ctrl.upsertData();
    	
	}
	@isTest(SeeAllData=false)
	static void testSalesAutoSetup2() {
		// SHOP INFO
    	ShopInformation__c tempShop = TestCommon.createShopInfo();
 		User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	loginUser.ShopCode__c = tempShop.shopcode__c;
    	update loginUser;
		// 当日
		Date todayDt = Date.Today();
		DateTime todayDtime = DateTime.newInstance(todayDt.year(), todayDt.month(), todayDt.day());
		// 既存から、編集する場合
    	// 予約情報を作成する[プラン付け]
    	Lead__c leadInfo = TestCommon.createLead();
    	// 商品情報を作成する
		// Normal商品
		List<AccountMaster__c> productLst = TestCommon.createProductMst(2);
		// 見積明細を作成する
    	TestCommon.createBookEstItems(leadInfo, productLst);
    	
    	Test.startTest();
    	// 予約情報のステータス：チェックインに変更する
    	leadInfo.Field298__c = 'チェックイン完';
    	update leadInfo;

    	// 会計画面に動作確認を行う
    	List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfo.Id];
    	AccountAcount__c accObj = accObjLst[0];
    	ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
		// 画面起動
    	BillInput_Ctrl ctrl = new BillInput_Ctrl(contrl);
    	ctrl.initAction();
    	String maxSize = ctrl.commentMaxStrSize;
    	String accName = ctrl.getAccountNames();
    	String accPro = ctrl.getAccountProvisos();
    	System.assertEquals(ctrl.oAcountSobj.salesDate__c,todayDt);
    	
	}
	// 2019/04/15 BY zyz BEGIN
    static testMethod void LeadToAccountCase1() {
    	Test.startTest();

    	ShopInformation__c shop = TestCommon.createShopInfo();
    	ReportLogo__c rep = TestCommon.createRepLogo();
    	rep.ShopInfoRef__c = shop.Id;
    	update rep;
        User currUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        currUser.ShopCode__c = shop.ShopCode__c;
        update currUser;
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
    	// 見積明細を作成する
        BookingEstimateItem__c bookingItemA = TestCommon.createBookEstItem(leadInfo, productLst[0]);
        bookingItemA.UnitPrice__c = 30000;
        update bookingItemA;
    	BookingEstimateItem__c bookingEst2 = TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	bookingEst2.UnitPrice__c = 10000;
    	bookingEst2.ActionType__c = '支払';
        bookingEst2.PaymentType__c = null;
        bookingEst2.refAccountMaster__c = productLst[0].Id;
        bookingEst2.Amount__c = 4;
        bookingEst2.ServiceRate__c = 10;
        bookingEst2.ParentBookingItemRef__c = bookingItemA.id;
    	update bookingEst2;
    	
        BookingEstimateItem__c bookingItem = TestCommon.createBookEstItem(leadInfo, productLst[0]);
        // 予約情報のステータス：チェックインに変更する
        bookingItem.UnitPrice__c = 20000;
        bookingItem.ActionType__c = '通常';
        bookingItem.PaymentType__c = null;
        bookingItem.refAccountMaster__c = productLst[0].Id;
        bookingItem.Amount__c = 4;
        bookingItem.ServiceRate__c = 10;
        bookingItem.ParentBookingItemRef__c = bookingItemA.id;
        update bookingItem;
    	// 予約情報のステータス：チェックインに変更する
    	leadInfo.Field298__c = 'チェックイン完';
    	update leadInfo;

    	Test.stopTest();
        // Report Logo作成
        TestCommon.createRepLogo();

        // 見積書
		getCsvSetupConfig();
		
        CommDefine__c def = TestCommon.createCommDefine();
   		def.BookingReportStampIsShowFlg__c = true;
   		def.AccountServiceChargeIsShow__c = '1';
   		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
        def.ReducedTaxRateFlg__c = true;
        def.PDFPlanBrkIsShowFlg__c = true;
        // 2019/07/30 軽減税率機能対応 WGCH END
    	update def;
		
        ApexPages.StandardController contr3 = new ApexPages.StandardController(leadInfo);
        LeadPDF lPdf = new LeadPDF(contr3);
        
        System.assertNotEquals(lPdf.sumInfo, null);
        System.assert(lPdf.allPageList.size() > 0);
        //lPdf.getReportLogo();
        lPdf.getLead();
        lPdf.getCustomer();
        lPdf.getServiceAmount();
        lPdf.getNumberFormat();
        LeadPDF.TotalInfo pdfSumInfo = lPdf.sumInfo;
        System.assert(pdfSumInfo.amoutQuotePriceIncTax != null);
        System.assert(pdfSumInfo.amoutTax != null);
        System.assert(pdfSumInfo.amoutUsedPriceIncTax != null);
    }
	// 2019/04/15 BY zyz END
	
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
        String csv = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP><SHOPCODE></SHOPCODE><BILLLAYOUTNAME><BILL_PDF STYLE="font-size:12pt;" AOTUSPLIT="true">予約名：$$_Relreserve__r.Name_$$&lt;br/&gt;お客様名：$$_relaccount__r.Name_$$ 様</BILL_PDF></BILLLAYOUTNAME><BILLPDFLAYOUT><TITLELABEL>御  請  求  書</TITLELABEL><ROWSLABEL><ROW><COL STYLE="font-size:9pt;">毎度格別の御引立に預かり厚く御礼申し上げます。</COL></ROW><ROW><COL STYLE="font-size:9pt;">下記の通り御請求申し上げます。</COL></ROW></ROWSLABEL><PAYLABEL>お振込先お振込先</PAYLABEL></BILLPDFLAYOUT><LETTERLAYOUT><SUBJECTLABEL>書 類 送 付 の ご 案 内</SUBJECTLABEL><CUSTOM_SHIPPING>拝啓&lt;br/&gt;時下ますますご清栄のこととお喜び申し上げます。</CUSTOM_SHIPPING><REGARDSLABEL>敬具</REGARDSLABEL><RECORDLABEL>記</RECORDLABEL><DEPARTLABEL>■請求書 1部</DEPARTLABEL><ABOVELABEL>以上</ABOVELABEL></LETTERLAYOUT></SHOP></root>';
        Document doc = new Document();
        doc.Name = 'BillPdfConfig';
        doc.DeveloperName = doc.Name;
        doc.FolderId = UserInfo.getUserId();
        doc.Body = Blob.valueOf(csv);
        insert doc;
    }
    // 2018/12/15 請求書レイアウト改善 BY zyz END 
    // 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 zk BEGIN
    static testMethod void productSearchCase2() {
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	comDef.ShopAccountSearchDiv__c = '1';
    	
    	comDef.AccountAcountCutoffDay__c = '2:15;3';
    	
    	update comDef;
    	// 予約情報を作成する[プラン付け]
    	Lead__c leadInfo = TestCommon.createLead();
    	// 商品情報を作成する
		// Normal商品
		List<AccountMaster__c> productLst = TestCommon.createProductMst(2);
		//List<AccountMaster__c> productLst2 = TestCommon.createFullProductMst(5);
		// プラン商品作成
		AccountMaster__c planProd0 = TestCommon.createPlanProd();
		AccountMaster__c planProd1 = TestCommon.createPlanProd();
		//AccountMaster__c planProd2 = TestCommon.createPlanProd();
		// 見積明細を作成する
    	TestCommon.createBookEstItems(leadInfo, productLst);
    	
    	Test.startTest();
    	// 予約情報のステータス：チェックインに変更する
    	leadInfo.Field298__c = 'チェックイン完';
    	update leadInfo;
	
    	// 会計画面に動作確認を行う
    	List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfo.Id];
    	AccountAcount__c accObj = accObjLst[0];
    	ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);

		// 画面起動
    	BillInput_Ctrl ctrl = new BillInput_Ctrl(contrl);
    	ctrl.initAction();
    	
    	List<BillInput_Ctrl.TranItem> rsTranItems = ctrl.oTranSobjLst;
    	Integer trueDataNums = 0;
    	for (BillInput_Ctrl.TranItem item : rsTranItems) {
    		if (item.sobj.Id != null) trueDataNums++;
    	}
    	// Plan(1) + 5件個別商品
		System.assertEquals(trueDataNums, productLst.size() + 1);

		String accountId = ctrl.oAcountSobj.Id;
		// 会計商品内容を更新して、ＤＢへ反映する
		// プラン明細データの単価を更新して、プラン数量も更新する
		// 該当プランの明細から単価再定義
		List<BillInput_Ctrl.PlanDetail> planDetailLst0 = BillInput_Ctrl.getAccountMstLstByPlan(rsTranItems[0].sobj.Id, '', planProd0.Id);
		// ０行目会計明細の商品ＩＤ
		String item0OrgProdId =  rsTranItems[0].sobj.Field7__c;
		String item0OrgId = rsTranItems[0].sobj.Id;
		// 該当プラン関連の会計明細
		List<Tran1__c> orgTran0Detail = [select Field5__c, Field20__c from Tran1__c where ParentTran1Ref__c = :item0OrgId ];
		System.assert(!orgTran0Detail.isEmpty());

		// 単価再定義
		Decimal planSummary = 0;
		String planDetailString = '';
		rsTranItems[0].productNm = planProd0.Name;
		rsTranItems[0].sobj.Field7__c = planProd0.Id;
		rsTranItems[0].tranId = '';
		rsTranItems[0].accRefId = '';
		
		// 商品３に、別の普通商品に設定する,単価、数量など設定を行う
		planSummary = 0;
		planDetailString = '';
		for (BillInput_Ctrl.PlanDetail pl : planDetailLst0) {
			pl.prodPrice = String.valueOf(Decimal.valueOf(pl.prodPrice.replaceAll(',', ''))  + 100);
			planSummary += Decimal.valueOf(pl.prodPrice);
			planDetailString += pl.sobjId + ':' + pl.prodPrice + ';';
		}
		rsTranItems[0].sobj.Field20__c = String.valueOf(planSummary);
		rsTranItems[0].sobj.Field21__c = String.valueOf(Decimal.valueOf(rsTranItems[2].sobj.Field21__c) + 1);
		rsTranItems[0].sobj.PlanDetailSyncInfo__c = planDetailString;

		// 商品１に、数量、単価更新を行う
		rsTranItems[1].productNm = 'テスト商品１名前再定義';
		rsTranItems[1].sobj.Field20__c = String.valueOf(Decimal.valueOf(rsTranItems[1].sobj.Field20__c) + 100);
		rsTranItems[1].sobj.Field21__c = String.valueOf(Decimal.valueOf(rsTranItems[1].sobj.Field21__c) + 1);
		// 商品２に、プラン商品１に更新を行う、プラン明細に単価など変更なし、数量と単価を更新する
		rsTranItems[2].productNm = planProd1.Name;
		rsTranItems[2].sobj.Field7__c = planProd1.Id;
		rsTranItems[2].tranId = '';
		rsTranItems[2].accRefId = '';
		List<BillInput_Ctrl.PlanDetail> planDetailLst2 = BillInput_Ctrl.getAccountMstLstByPlan(rsTranItems[2].sobj.Id, '', planProd1.Id);
		// 商品３に、別の普通商品に設定する,単価、数量など設定を行う
		planSummary = 0;
		planDetailString = '';
		for (BillInput_Ctrl.PlanDetail pl : planDetailLst2) {
			pl.prodPrice = String.valueOf(Decimal.valueOf(pl.prodPrice.replaceAll(',', ''))  + 100);
			planSummary += Decimal.valueOf(pl.prodPrice);
			planDetailString += pl.sobjId + ':' + pl.prodPrice + ';';
		}
		rsTranItems[2].sobj.Field20__c = String.valueOf(planSummary);
		rsTranItems[2].sobj.Field21__c = String.valueOf(Decimal.valueOf(rsTranItems[2].sobj.Field21__c) + 1);
		rsTranItems[2].sobj.PlanDetailSyncInfo__c = planDetailString;
	
		// 支払い計算、更新を行う	
    	ctrl.calPaymentInfo();
    	ctrl.upsertData();
		// 更新処理内容の確認
		// 商品０のいり買え前の関連プラン明細を削除する
		Set<Id> orgTran0IdSet = new Set<Id>();
		for (Tran1__c org : orgTran0Detail) { orgTran0IdSet.add(org.Id); }
		List<Tran1__c> orgTran0Chk = [select Field5__c, Field20__c from Tran1__c where ParentTran1Ref__c = :item0OrgId And Id in :orgTran0IdSet ];
		System.assert(orgTran0Chk.isEmpty(), orgTran0Chk);
    	// 新規のプラン情報は正確に更新、新規作成を行う、数量は正確に反映する
    	List<BillInput_Ctrl.PlanDetail> planDetailLst0_N = BillInput_Ctrl.getAccountMstLstByPlan(item0OrgId, accountId,  '');
		Test.stopTest();
    }
	static testMethod void productSearchCase3() {
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	comDef.ShopAccountSearchDiv__c = '1';
    	
    	comDef.AccountAcountCutoffDay__c = '2:15;3';
    	
    	update comDef;
    	// 予約情報を作成する[プラン付け]
    	Lead__c leadInfo = TestCommon.createLead();
    	// 商品情報を作成する
		// Normal商品
		List<AccountMaster__c> productLst = TestCommon.createProductMst(2);
		//List<AccountMaster__c> productLst2 = TestCommon.createFullProductMst(5);
		// プラン商品作成
		AccountMaster__c planProd0 = TestCommon.createPlanProd();
		AccountMaster__c planProd1 = TestCommon.createPlanProd();
		//AccountMaster__c planProd2 = TestCommon.createPlanProd();
		//　上記プランの関連プラン商品を取得する

		// 見積明細を作成する
    	TestCommon.createBookEstItems(leadInfo, productLst);
    	
    	Test.startTest();
    	// 予約情報のステータス：チェックインに変更する
    	leadInfo.Field298__c = 'チェックイン完';
    	update leadInfo;
    }
    // 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 zk END
}