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
private class CashRollupBookTest {
	static testMethod void initCheck() {
	    createConfigDoc1();
        CashRollupBook cashBook = new CashRollupBook();
        cashBook.init();
        cashBook.refreshBranShop();
		// 初期化
		Integer amount = 0;
        CashRollupBook.CashBookInfo cashInfo = cashBook.cashInfo;
        cashInfo.cash.ReserveFund__c = amount;
        // 保存する
        cashInfo.cash.TenThousandCashNums__c = amount/10000;
        cashBook.saveCashInfo();
        // 結果確認       
        System.assertEquals(cashInfo.cashActAmount, amount, cashInfo.cashActAmount);
        System.assertEquals(cashInfo.cashLogicAmount, amount, cashInfo.cashLogicAmount);
        System.assertEquals(cashInfo.diffAmount, 0, cashInfo.diffAmount);
	}
	
	// 指定日の現金情報集める確認
    static testMethod void myUnitTest() {
    	Date dt = Date.today();
        // 売上データを作成
		// 店舗は空白に設定する
 		User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	loginUser.ShopCode__c = null;
    	update loginUser;		
		CommDefine__c comdef = TestCommon.createCommDefine();		
		// 商品作成する
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo, productLst[0]);
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
    	createConfigDoc();
    	createConfigDoc1();
		Test.StartTest();
		
		RsvAccount__c rsv = CommLogicProcess.getRsvAccountInf(dt);
		ssumaccount.getrevenue(rsv.id);
		// 現金を取得する
		rsv = [select GenkinkeiKomi__c from RsvAccount__c where id = :rsv.Id];
		
        // 入金情報を作成
		Id contactId = TestCommon.createContact().Id;
		System.currentPageReference().getParameters().put('pm', CashManagentInput.CONST_PAGE_MODE_IN);
		CashManagentInput cashCtrl = new CashManagentInput();
		cashCtrl.init();
		// Page Mode Confirm
		System.assertEquals(cashCtrl.input.pageMode, CashManagentInput.CONST_PAGE_MODE_IN, cashCtrl.input.pageMode);
		// 情報を入力する
		cashCtrl.editRowIdx = 0;
		cashCtrl.input.pageMode = CashManagentInput.CONST_PAGE_MODE_IN;
		List<CashManagentInput.ItemInfo> deposLists = cashCtrl.deposList;
		System.assertEquals(deposLists.size(), 1, deposLists);
		// 1件新規のみ
		//CashManagentInput.ItemInfo firstItem = deposLists[0];
		deposit__c input = cashCtrl.inpData.dep;
		input.SalesDate__c = deposLists[0].dep.SalesDate__c;
		input.deposit__c = contactId;
		input.Kamoku__c  = 'テスト１科目';
		input.deposititem__c = '摘要テスト';
		input.depositamount__c = 50000;
		cashCtrl.dataUpsert();
		// 新規後、2件データになる、1件名は編集、2件名は表示Readonly、合計値は 50000
		System.assertEquals(cashCtrl.depAmount, 50000, cashCtrl.depAmount);
		deposLists = cashCtrl.deposList;
		System.assertEquals(deposLists.size(), 2, deposLists);
        // 出金情報を作成
		// 情報を入力する
		cashCtrl.editRowIdx = 0;
		cashCtrl.input.pageMode = CashManagentInput.CONST_PAGE_MODE_OU;
		List<CashManagentInput.ItemInfo> paymentLists = cashCtrl.paymentList;
		System.assertEquals(paymentLists.size(), 1, paymentLists);
		// 1件新規のみ
		//CashManagentInput.ItemInfo firstItem = paymentLists[0];
		Paymentslip__c inputPay = cashCtrl.inpData.pay;
		inputPay.SalesDate__c = paymentLists[0].pay.SalesDate__c;
		inputPay.Pkamoku__c  = 'テスト１科目';
		inputPay.Pitem__c = '摘要テスト';
		inputPay.Pamount__c = 60000;
		cashCtrl.dataUpsert();
		// 新規後、2件データになる、1件名は編集、2件名は表示Readonly、合計値は 50000
		System.assertEquals(cashCtrl.payAmount, 60000, cashCtrl.payAmount);
		paymentLists = cashCtrl.paymentList;
		System.assertEquals(paymentLists.size(), 2, paymentLists);                
        // 準備金
        CashRollupBook cashBook = new CashRollupBook();
        // 2017/07/12 localip，posリスト機能対応　by zy BEGIN
		cashBook.localIp = '192.168.10.XXX';
		// 2017/07/12 localip，posリスト機能対応　by zy END
        cashBook.init();
     	cashBook.refreshBranShop();
        CashRollupBook.CashBookInfo cashInfo = cashBook.cashInfo;
        cashInfo.cash.ReserveFund__c = 200000;
        // 有高（現物）
        cashInfo.cash.TenThousandCashNums__c = 10;
        cashInfo.cash.FiveThousandCashNums__c = 10;
        cashInfo.cash.TwoThousandCashNums__c = 10;
        cashInfo.cash.OneThousandCashNums__c = 10;
        cashInfo.cash.FiveHundredCashNums__c = 10;
        cashInfo.cash.OneHundredCashNums__c = 10;
        cashInfo.cash.FiftyCashNums__c = 10;
        cashInfo.cash.TenCashNums__c = 10;
        cashInfo.cash.FiveCashNums__c = 10;
        cashInfo.cash.OneCashNums__c = 10;
        
        cashBook.saveCashInfo();
        // 結果確認
        
        System.assertEquals(cashInfo.salesAmount, rsv.GenkinkeiKomi__c, cashInfo.salesAmount);	// 売上
        System.assertEquals(cashInfo.despAmount, 50000, cashInfo.despAmount);	// 入金
        System.assertEquals(cashInfo.payAmount, 60000, cashInfo.payAmount);	// 出金
        System.assertEquals(cashInfo.cash.ReserveFund__c, 200000, cashInfo.cash.ReserveFund__c);	// 準備金        
        System.assertEquals(cashInfo.diffAmount, cashInfo.cashActAmount - cashInfo.cashLogicAmount, cashInfo.diffAmount);
        //System.assertEquals(cashInfo.cashActAmount, (10 * (10000+5000+2000+1000+500+100+50+10+5+1)) , cashInfo.cashActAmount);
//System.debug(LoggingLevel.INFO, 'cashInfo.cashLogicAmount::' + cashInfo.cashLogicAmount);
//System.debug(LoggingLevel.INFO, 'rsv.GenkinkeiKomi__c::' + rsv.GenkinkeiKomi__c);
//System.debug(LoggingLevel.INFO, 'cashInfo.cash.ReserveFund__c::' + cashInfo.cash.ReserveFund__c);
        System.assertEquals(cashInfo.cashLogicAmount, cashInfo.cash.ReserveFund__c+rsv.GenkinkeiKomi__c+cashInfo.despAmount-cashInfo.payAmount , cashInfo.cashLogicAmount);
        
        Test.StopTest();
    }
    // 2016/07/20 現金合せの金額単位XML設定 by wgch begin
    static testMethod void myUnitTest1() {
    	ShopInformation__c shop =  TestCommon.createShopInfo();
    	RsvAccount__c rsv1 = TestCommon.createRsvAccount();
    	Date dt = Date.today();
        // 売上データを作成
		// 店舗は空白に設定する
 		User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	loginUser.ShopCode__c = null;
    	update loginUser;		
		CommDefine__c comdef = TestCommon.createCommDefine();		
		// 商品作成する
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo, productLst[0]);
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
    	createConfigDoc();
    	createConfigDoc1();
    	//createConfigDoc3();
		Test.StartTest();
		RsvAccount__c rsv = CommLogicProcess.getRsvAccountInf(dt);
		ssumaccount.getrevenue(rsv.id);
		// 現金を取得する
		rsv = [select GenkinkeiKomi__c from RsvAccount__c where id = :rsv.Id];
		
		CashVerification__c cash = new CashVerification__c(
		RsvAccountRef__r = rsv,	 	
		RsvAccountRef__c = rsv.Id,
        SearchKey__c = '住友銀行',
		//CashSales__c = 1,
		ReserveFund__c = 200000,
		ShopInfoRef__c = shop.Id ); 
		insert cash;
		
		CashVerification__c cash1 = new CashVerification__c(
		RsvAccountRef__r = rsv,	 	
		RsvAccountRef__c = rsv.Id,
        SearchKey__c = '住友銀行11',
		//CashSales__c = 1,
		ReserveFund__c = 500000,
		ShopInfoRef__c = shop.Id ); 
		insert cash1;
		
        // 入金情報を作成
		Id contactId = TestCommon.createContact().Id;
		System.currentPageReference().getParameters().put('pm', CashManagentInput.CONST_PAGE_MODE_IN);
		CashManagentInput cashCtrl = new CashManagentInput();
		cashCtrl.init();
		// Page Mode Confirm
		System.assertEquals(cashCtrl.input.pageMode, CashManagentInput.CONST_PAGE_MODE_IN, cashCtrl.input.pageMode);
		// 情報を入力する
		cashCtrl.editRowIdx = 0;
		cashCtrl.input.pageMode = CashManagentInput.CONST_PAGE_MODE_IN;
		List<CashManagentInput.ItemInfo> deposLists = cashCtrl.deposList;
		System.assertEquals(deposLists.size(), 1, deposLists);
		// 1件新規のみ
		//CashManagentInput.ItemInfo firstItem = deposLists[0];
		deposit__c input = cashCtrl.inpData.dep;
		input.SalesDate__c = deposLists[0].dep.SalesDate__c;
		input.deposit__c = contactId;
		input.Kamoku__c  = 'テスト１科目';
		input.deposititem__c = '摘要テスト';
		input.depositamount__c = 50000;
		cashCtrl.dataUpsert();
		// 新規後、2件データになる、1件名は編集、2件名は表示Readonly、合計値は 50000
		System.assertEquals(cashCtrl.depAmount, 50000, cashCtrl.depAmount);
		deposLists = cashCtrl.deposList;
		System.assertEquals(deposLists.size(), 2, deposLists);
        // 出金情報を作成
		// 情報を入力する
		cashCtrl.editRowIdx = 0;
		cashCtrl.input.pageMode = CashManagentInput.CONST_PAGE_MODE_OU;
		List<CashManagentInput.ItemInfo> paymentLists = cashCtrl.paymentList;
		System.assertEquals(paymentLists.size(), 1, paymentLists);
		// 1件新規のみ
		//CashManagentInput.ItemInfo firstItem = paymentLists[0];
		Paymentslip__c inputPay = cashCtrl.inpData.pay;
		inputPay.SalesDate__c = paymentLists[0].pay.SalesDate__c;
		inputPay.Pkamoku__c  = 'テスト１科目';
		inputPay.Pitem__c = '摘要テスト';
		inputPay.Pamount__c = 60000;
		cashCtrl.dataUpsert();
		// 新規後、2件データになる、1件名は編集、2件名は表示Readonly、合計値は 50000
		System.assertEquals(cashCtrl.payAmount, 60000, cashCtrl.payAmount);
		paymentLists = cashCtrl.paymentList;
		System.assertEquals(paymentLists.size(), 2, paymentLists);                
        // 準備金
        CashRollupBook cashBook = new CashRollupBook();
        cashBook.init();
     	cashBook.refreshBranShop();
        CashRollupBook.CashBookInfo cashInfo = cashBook.cashInfo;
        cashInfo.cash.ReserveFund__c = 200000;
        // 有高（現物）
        cashInfo.cash.TenThousandCashNums__c = 10;
        cashInfo.cash.FiveThousandCashNums__c = 10;
        cashInfo.cash.TwoThousandCashNums__c = 10;
        cashInfo.cash.OneThousandCashNums__c = 10;
        cashInfo.cash.FiveHundredCashNums__c = 10;
        cashInfo.cash.OneHundredCashNums__c = 10;
        cashInfo.cash.FiftyCashNums__c = 10;
        cashInfo.cash.TenCashNums__c = 10;
        cashInfo.cash.FiveCashNums__c = 10;
        cashInfo.cash.OneCashNums__c = 10;
        
        cashBook.saveCashInfo();
        
        cashInfo.cash.TenThousandCashNums__c = 100;
        cashInfo.cash.FiveThousandCashNums__c = 100;
        cashInfo.cash.TwoThousandCashNums__c = 100;
        cashInfo.cash.OneThousandCashNums__c = 100;
        cashInfo.cash.FiveHundredCashNums__c = 100;
        cashInfo.cash.OneHundredCashNums__c = 100;
        cashInfo.cash.FiftyCashNums__c = 100;
        cashInfo.cash.TenCashNums__c = 100;
        cashInfo.cash.FiveCashNums__c = 100;
        cashInfo.cash.OneCashNums__c = 100;
        
        cashBook.saveCashInfo();
        // 結果確認
        
        System.assertEquals(cashInfo.salesAmount, rsv.GenkinkeiKomi__c, cashInfo.salesAmount);	// 売上
        System.assertEquals(cashInfo.despAmount, 50000, cashInfo.despAmount);	// 入金
        System.assertEquals(cashInfo.payAmount, 60000, cashInfo.payAmount);	// 出金
        System.assertEquals(cashInfo.cash.ReserveFund__c, 200000, cashInfo.cash.ReserveFund__c);	// 準備金        
        System.assertEquals(cashInfo.diffAmount, cashInfo.cashActAmount - cashInfo.cashLogicAmount, cashInfo.diffAmount);
        //System.assertEquals(cashInfo.cashActAmount, (10 * (10000+5000+2000+1000+500+100+50+10+5+1)) , cashInfo.cashActAmount);
//System.debug(LoggingLevel.INFO, 'cashInfo.cashLogicAmount::' + cashInfo.cashLogicAmount);
//System.debug(LoggingLevel.INFO, 'rsv.GenkinkeiKomi__c::' + rsv.GenkinkeiKomi__c);
//System.debug(LoggingLevel.INFO, 'cashInfo.cash.ReserveFund__c::' + cashInfo.cash.ReserveFund__c);
        System.assertEquals(cashInfo.cashLogicAmount, cashInfo.cash.ReserveFund__c+rsv.GenkinkeiKomi__c+cashInfo.despAmount-cashInfo.payAmount , cashInfo.cashLogicAmount);
        
        Test.StopTest();
    }
    static testMethod void myUnitTest2() {
        createConfigDoc1();
    	ShopInformation__c shop =  TestCommon.createShopInfo();
    	RsvAccount__c rsv1 = TestCommon.createRsvAccount();
    	Date dt = Date.today();
        // 売上データを作成
		// 店舗は空白に設定する
 		User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	loginUser.ShopCode__c = null;
    	update loginUser;		
		CommDefine__c comdef = TestCommon.createCommDefine();		
		// 商品作成する
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo, productLst[0]);
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
    	createConfigDoc();
		Test.StartTest();
		RsvAccount__c rsv = CommLogicProcess.getRsvAccountInf(dt);
		ssumaccount.getrevenue(rsv.id);
		// 現金を取得する
		rsv = [select GenkinkeiKomi__c from RsvAccount__c where id = :rsv.Id];
		
		CashVerification__c cash = new CashVerification__c(
		RsvAccountRef__r = rsv,	 	
		RsvAccountRef__c = rsv.Id,
        SearchKey__c = '住友銀行',
		//CashSales__c = 1,
		ReserveFund__c = 200000,
		ShopInfoRef__c = shop.Id ); 
		insert cash;	
        // 入金情報を作成
		Id contactId = TestCommon.createContact().Id;
		System.currentPageReference().getParameters().put('pm', CashManagentInput.CONST_PAGE_MODE_IN);
		CashManagentInput cashCtrl = new CashManagentInput();
		cashCtrl.init();
		// Page Mode Confirm
		System.assertEquals(cashCtrl.input.pageMode, CashManagentInput.CONST_PAGE_MODE_IN, cashCtrl.input.pageMode);
		// 情報を入力する
		cashCtrl.editRowIdx = 0;
		cashCtrl.input.pageMode = CashManagentInput.CONST_PAGE_MODE_IN;
		List<CashManagentInput.ItemInfo> deposLists = cashCtrl.deposList;
		System.assertEquals(deposLists.size(), 1, deposLists);
		// 1件新規のみ
		//CashManagentInput.ItemInfo firstItem = deposLists[0];
		deposit__c input = cashCtrl.inpData.dep;
		input.SalesDate__c = deposLists[0].dep.SalesDate__c;
		input.deposit__c = contactId;
		input.Kamoku__c  = 'テスト１科目';
		input.deposititem__c = '摘要テスト';
		input.depositamount__c = 50000;
		cashCtrl.dataUpsert();
		// 新規後、2件データになる、1件名は編集、2件名は表示Readonly、合計値は 50000
		System.assertEquals(cashCtrl.depAmount, 50000, cashCtrl.depAmount);
		deposLists = cashCtrl.deposList;
		System.assertEquals(deposLists.size(), 2, deposLists);
        // 出金情報を作成
		// 情報を入力する
		cashCtrl.editRowIdx = 0;
		cashCtrl.input.pageMode = CashManagentInput.CONST_PAGE_MODE_OU;
		List<CashManagentInput.ItemInfo> paymentLists = cashCtrl.paymentList;
		System.assertEquals(paymentLists.size(), 1, paymentLists);
		// 1件新規のみ
		//CashManagentInput.ItemInfo firstItem = paymentLists[0];
		Paymentslip__c inputPay = cashCtrl.inpData.pay;
		inputPay.SalesDate__c = paymentLists[0].pay.SalesDate__c;
		inputPay.Pkamoku__c  = 'テスト１科目';
		inputPay.Pitem__c = '摘要テスト';
		inputPay.Pamount__c = 60000;
		cashCtrl.dataUpsert();
		// 新規後、2件データになる、1件名は編集、2件名は表示Readonly、合計値は 50000
		System.assertEquals(cashCtrl.payAmount, 60000, cashCtrl.payAmount);
		paymentLists = cashCtrl.paymentList;
		System.assertEquals(paymentLists.size(), 2, paymentLists);                
        // 準備金
        CashRollupBook cashBook = new CashRollupBook();
        cashBook.init();
     	cashBook.refreshBranShop();
        CashRollupBook.CashBookInfo cashInfo = cashBook.cashInfo;
        cashInfo.cash.ReserveFund__c = 200000;
        // 有高（現物）
        cashInfo.cash.TenThousandCashNums__c = 10;
        cashInfo.cash.FiveThousandCashNums__c = 10;
        cashInfo.cash.TwoThousandCashNums__c = 10;
        cashInfo.cash.OneThousandCashNums__c = 10;
        cashInfo.cash.FiveHundredCashNums__c = 10;
        cashInfo.cash.OneHundredCashNums__c = 10;
        cashInfo.cash.FiftyCashNums__c = 10;
        cashInfo.cash.TenCashNums__c = 10;
        cashInfo.cash.FiveCashNums__c = 10;
        cashInfo.cash.OneCashNums__c = 10;
        
        cashBook.saveCashInfo();
        
        cashInfo.cash.TenThousandCashNums__c = 100;
        cashInfo.cash.FiveThousandCashNums__c = 100;
        cashInfo.cash.TwoThousandCashNums__c = 100;
        cashInfo.cash.OneThousandCashNums__c = 100;
        cashInfo.cash.FiveHundredCashNums__c = 100;
        cashInfo.cash.OneHundredCashNums__c = 100;
        cashInfo.cash.FiftyCashNums__c = 100;
        cashInfo.cash.TenCashNums__c = 100;
        cashInfo.cash.FiveCashNums__c = 100;
        cashInfo.cash.OneCashNums__c = 100;
        
        cashBook.saveCashInfo();
        // 結果確認
        
        System.assertEquals(cashInfo.salesAmount, rsv.GenkinkeiKomi__c, cashInfo.salesAmount);	// 売上
        System.assertEquals(cashInfo.despAmount, 50000, cashInfo.despAmount);	// 入金
        System.assertEquals(cashInfo.payAmount, 60000, cashInfo.payAmount);	// 出金
        System.assertEquals(cashInfo.cash.ReserveFund__c, 200000, cashInfo.cash.ReserveFund__c);	// 準備金        
        System.assertEquals(cashInfo.diffAmount, cashInfo.cashActAmount - cashInfo.cashLogicAmount, cashInfo.diffAmount);
        //System.assertEquals(cashInfo.cashActAmount, (10 * (10000+5000+2000+1000+500+100+50+10+5+1)) , cashInfo.cashActAmount);
//System.debug(LoggingLevel.INFO, 'cashInfo.cashLogicAmount::' + cashInfo.cashLogicAmount);
//System.debug(LoggingLevel.INFO, 'rsv.GenkinkeiKomi__c::' + rsv.GenkinkeiKomi__c);
//System.debug(LoggingLevel.INFO, 'cashInfo.cash.ReserveFund__c::' + cashInfo.cash.ReserveFund__c);
        System.assertEquals(cashInfo.cashLogicAmount, cashInfo.cash.ReserveFund__c+rsv.GenkinkeiKomi__c+cashInfo.despAmount-cashInfo.payAmount , cashInfo.cashLogicAmount);
        // 2017/07/12 その他　pos項目テスト　by zy BEGIN
        cashBook.curPos = cashBook.otherPosValue;
        cashBook.refreshPosNo();
        // 2017/07/12 その他　pos項目テスト　by zy END
        Test.StopTest();
    }
    // 2016/07/20 現金合せの金額単位XML設定 by wgch end
    // 2016/04/18 現金合せ情報登録して、項目変更履歴確認を行う
	static testMethod void historytriggerTest() {
		createConfigDoc1();
		Test.startTest();
		delete [select id from CommDefine__c];
		CommDefine__c newDef = new CommDefine__c(
			ItemChangeHistoryAutoCreateFlg__c = true
		);	
		insert newDef;		
        CashRollupBook cashBook = new CashRollupBook();
        cashBook.init();
        cashBook.refreshBranShop();
		// 初期化
		Integer amount = 0;
        CashRollupBook.CashBookInfo cashInfo = cashBook.cashInfo;
        cashInfo.cash.ReserveFund__c = amount;
        // 保存する
        cashInfo.cash.TenThousandCashNums__c = amount/10000;
        cashBook.saveCashInfo();
        // 結果確認
		
		Test.stopTest();
		// 変更履歴情報存在チェック
		List<CashVerification__c>  cashList = [select id from CashVerification__c limit 1];
		Id parentId = cashList[0].Id;
		List<ItemChangeHistory__c> itemChangeLst  = [select id from ItemChangeHistory__c where ParentId__c = :parentId];
		System.assert(itemChangeLst.size() > 0, itemChangeLst);
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
    // 2016/07/11 現金合せの金額単位XML設定 by wgch begin
     private static void createConfigDoc1() {
        String configXml = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP> <!-- デフォルト設定情報、削除しない、支店舗追加したい場合、このＮＯＤＥコピーして、後ろに追加してください -->'+
							'<SHOPCODE></SHOPCODE>'+
							'<INIT_CONFIG><DEFALUT_VALUE ApiName="ReserveFund__c">500000</DEFALUT_VALUE></INIT_CONFIG>'+
							'<PRICE><label>万</label><crrency>¥</crrency><apiName>TenThousandCashNums__c</apiName><percount>10,000</percount></PRICE>'+
							'<PRICE><label>5千</label><crrency>¥</crrency><apiName>FiveThousandCashNums__c</apiName><percount>5,000</percount></PRICE>'+
							'<PRICE><label>2千</label><crrency>¥</crrency><apiName>TwoThousandCashNums__c</apiName><percount>2,000</percount></PRICE>'+
							'<PRICE><label>千</label><crrency>¥</crrency><apiName>OneThousandCashNums__c</apiName><percount>1,000</percount></PRICE>'+
							'<PRICE><label>500</label><crrency>¥</crrency><apiName>FiveHundredCashNums__c</apiName><percount>500</percount></PRICE>'+
							'<PRICE><label>100</label><crrency>¥</crrency><apiName>OneHundredCashNums__c</apiName><percount>100</percount></PRICE>'+
							'<PRICE><label>50</label><crrency>¥</crrency><apiName>FiftyCashNums__c</apiName><percount>50</percount></PRICE>'+
							'<PRICE><label>10</label><crrency>¥</crrency><apiName>TenCashNums__c</apiName><percount>10</percount></PRICE></SHOP>'+
							'<SHOP><!-- デフォルト設定情報、削除しない、支店舗追加したい場合、このＮＯＤＥコピーして、後ろに追加してください -->'+
							'<SHOPCODE>03</SHOPCODE>'+
							'<PRICE><label>dollar</label><crrency>¥</crrency><apiName>TenCashNums__c</apiName><percount>100</percount></PRICE>'+
							'<PRICE><label>Cent</label><crrency>¥</crrency><apiName>OneHundredCashNums1__c</apiName><percount>10</percount></PRICE></SHOP></root>';
        // ドキュメントを作成する
        Document item = new Document();
        item.Name = 'CashRollupBookSetting';
        item.DeveloperName = item.Name;
        item.FolderId = UserInfo.getUserId();
        item.Body = Blob.valueOf(configXml);
        insert item;
        
        TestCommon.createDeviceConfigXml();
        TestCommon.createOrderConfigXml();
    }
    private static void createConfigDoc2() {
        String configXml = '';
        // ドキュメントを作成する
        Document item = new Document();
        item.Name = '';
        item.DeveloperName = item.Name;
        item.FolderId = UserInfo.getUserId();
        item.Body = Blob.valueOf(configXml);
        insert item;
    }
}
// 2016/07/20 現金合せの金額単位XML設定 by wgch end