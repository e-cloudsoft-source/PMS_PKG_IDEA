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
private class BillSplitProcessTest {
	@testsetup
    static void dataSetup(){
    	List<CommDefine__c> commDefs = [select QQNRoomAssignFlag__c from CommDefine__c];
		if (!commDefs.isEmpty()) {
			commDefs[0].QQNRoomAssignFlag__c = false;
			update commDefs[0];
		}
		ShopInformation__c shop = TestCommon.createShopInfo();
  		shop.ShopCode__c = UserUtil.CurrentUserInfo.defaultShopCode;
  		update shop;
  		list<AccountMaster__c> accs = TestCommon.createPayProductMst(new List<String>{Label.CONST_012_0438,Label.CONST_012_0439,Label.CONST_012_0440,Label.CONST_012_0441,Label.CONST_012_0442,Label.CONST_012_0443});
		TestCommon.createBillSimpleHelpConfigDoc();
  		TestCommon.createBillSimplePaymentConfigDoc();
        // 予約情報を作成する
		Lead__c leadInfo = TestCommon.createLead();
		ExchangeRate__c rate = TestCommon.createExchangeRate();
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
		// 格納用変数クリアする
		TTend__c ttitem = TestCommon.createTTend(rsv.Id, accObj.Id);
		//ttitem.Field1__c =; 
		ttitem.Field2__c = '22'; 
		ttitem.Field3__c = '33'; 
		ttitem.RowNo__c  = 44;  // メディア種別,メディア名称
		ttitem.Field16__c = '55';
		ttitem.Field17__c = '66';
		ttitem.Field20__c = '77';// 単価,枚数,支払金額 
		ttitem.Field21__c = '1'; //数量
		ttitem.Field23__c = '123'; 
		ttitem.SplitGroupNo__c = '88';
		ttitem.PaymentType__c = '99';
		ttitem.PayProductName__c = '111';
		ttitem.PayProductRef__c = accs[0].id;  // 支払商品
		//ttitem.PayProductRef__r.ActionType__c =;
		//ttitem.PayProductRef__r ='UNIT' + CommUtils.getRandom(9);
		//ttitem.RelAccount__r.Name =;  // 主従関係(売上)
		//ttitem.Field1__r.Relreserve__c =; 
		//ttitem.Field1__r.SalesdayCal__c =;
		ttitem.UseDate__c = Date.today();
		update ttitem;
		// AccountMaster__c accMst = MEDIA_PRODUCTCD_MAP.get(mediaNm);
		// 商品情報を作成する
        // List<AccountMaster__c> productLst = TestCommon.createProductMst(3);
        insert new Tran1__c(
			Field7__c = ttitem.PayProductRef__c // 商品コード
			,ActionType__c = CommConst.PROD_ACTION_TYPE_PY	// 商品処理種別
			,PaymentType__c = ttitem.PaymentType__c // ;支払種別
			,Field20__c = '800'	// 単価 ←　預かり金額
			,Field23__c = ttitem.Field20__c	// 合計金額 ←　預かり金額
			,Field21__c = '1'			// 数量１固定
			,Field5__c = ttitem.PayProductName__c
			,RelAccount__c = ttitem.RelAccount__c
			,Field1__c = ttitem.Field1__c
			,RowNo__c = ttitem.RowNo__c
			,SplitGroupNo__c = ttitem.SplitGroupNo__c
			,PayProductRef__c = ttitem.PayProductRef__c
			// 2016/01/11 ポイント、値引以外の支払メデイアも明細に表示、グループNo登録可能対応 BEGIN
			,UseDate__c = ttitem.UseDate__c
			// 2016/01/11 ポイント、値引以外の支払メデイアも明細に表示、グループNo登録可能対応 END
			,PrintedFlg__c = ttitem.PrintedFlg__c
		);
		
  		
  		insert new WorkTimeDefine__c(shopCode__c = '02',Name = '0001');
  		// zyz
        DateTime beforeDt = System.now().addDays(1);
		Date beforeDay = beforeDt.date();
        TimeManagement__c beforeItem = new TimeManagement__c(
		    Status__c = System.Label.MSG_1019,
			WorkDay__c = beforeDay,
			WorkerRef__c = UserInfo.getUserId(),
			WorkerName__c = UserInfo.getName(),
			WorkBeginTime__c = System.now().addDays(1),
			OutingTime__c = System.now().addDays(1),
			OutingTime2__c = System.now().addDays(1), 
			OutingTime3__c = System.now().addDays(1) 
		);
		insert beforeItem;
    }
    @isTest(SeeAllData=false)
    static void selfUnit() {
		Test.startTest();
		/*
		// 予約情報を作成する
		Lead__c leadInfo = TestCommon.createLead();
		// 商品情報を作成する
		List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
		// 見積明細を作成する
		TestCommon.createBookEstItem(leadInfo, productLst[0]);
		// 予約情報のステータス：チェックインに変更する
		leadInfo.Field298__c = 'チェックイン完';
		update leadInfo;
		*/
		
		
		// 会計画面に動作確認を行う
		List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c limit 1];
		AccountAcount__c accObj = accObjLst[0];
		
		ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
		BillInput_Ctrl ctrl = new BillInput_Ctrl(contrl);
		ctrl.initAction();
		//zyz
		ctrl.getAccountNames();
		//zyz
		ctrl.calPaymentInfo();
		ctrl.upsertData();
		BillSplitProcess split = new BillSplitProcess(contrl);
		Test.stopTest();
		split.c_showAll = false;
		split.refreshBillInfo();
		    
		split.c_splitNo = '03';
		split.c_actType = new String[]{'朝食'};
		split.c_dpId = '01';
		split.c_gpId = '02';
		split.c_productNm = 'テスト商品';
		split.c_termEt.WorkDay__c = Date.today();
		split.c_termSt.WorkDay__c = Date.today();
		split.refreshBillInfo();
		split.saveNo();
		System.assertNotEquals(split.accSobj, null);
		
	}
 /*   @isTest(SeeAllData=false)
	static void selfUnit1() {
	Test.startTest();
		// 予約情報を作成する
		Lead__c leadInfo = TestCommon.createLead();
		// 商品情報を作成する
		List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
		// 見積明細を作成する
		TestCommon.createBookEstItem(leadInfo, productLst[0]);
		// 予約情報のステータス：チェックインに変更する
		leadInfo.Field298__c = 'チェックイン完';
		update leadInfo;
		RsvAccount__c rsv = TestCommon.createRsvAccount();
		TTend__c ttitem = TestCommon.createTTend(rsv.id,''); 
		//ttitem.Field1__c =; 
		ttitem.field2__c = '22'; 
		ttitem.field3__c = '33'; 
		ttitem.RowNo__c  = 44;  // メディア種別,メディア名称
		ttitem.Field16__c = '55';
		ttitem.Field17__c = '66';
		ttitem.Field20__c = '77';// 単価,枚数,支払金額 
		ttitem.SplitGroupNo__c = '88';
		ttitem.PaymentType__c = '99';
		ttitem.PayProductName__c = '111';
		//ttitem.PayProductRef__c =;  // 支払商品
		//ttitem.PayProductRef__r.ActionType__c =;
		//ttitem.PayProductRef__r.Field3__c =;
		//ttitem.RelAccount__r.Name =;  // 主従関係(売上)
		//ttitem.Field1__r.Relreserve__c =; 
		//ttitem.Field1__r.SalesdayCal__c =;
		ttitem.UseDate__c = Date.today();
		update ttitem;  
		Test.stopTest();
		
		// 会計画面に動作確認を行う
		List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfo.Id];
		AccountAcount__c accObj = accObjLst[0];
		
		ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
		BillInput_Ctrl ctrl = new BillInput_Ctrl(contrl);
		ctrl.initAction();
		ctrl.calPaymentInfo();
		ctrl.upsertData();
		      
		BillSplitProcess split = new BillSplitProcess(contrl);
		split.c_showAll = true;
		split.refreshBillInfo();
		      
		split.c_splitNo = '01';
		split.c_actType = new String[]{'朝食'};
		split.c_dpId = '01';
		split.c_gpId = '02';
		split.c_productNm = 'テスト商品';
		split.c_termEt.WorkDay__c = Date.today();
		split.c_termSt.WorkDay__c = Date.today();
		split.refreshBillInfo();
		split.saveNo();
		BillSplitProcess.Option op = new BillSplitProcess.Option('','');
		split.getAccountNames();
		split.getAccountProvisos();
		split.refreshSimpleBillInfo();
		System.assertNotEquals(split.accSobj, null);
    }*/
    @isTest(SeeAllData=false)
	static void selfUnit1() {
	
		/*
		// 予約情報を作成する
		Lead__c leadInfo = TestCommon.createLead();
		ExchangeRate__c rate = TestCommon.createExchangeRate();
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
		//ttitem.Field1__c =; 
		ttitem.Field2__c = '22'; 
		ttitem.Field3__c = '33'; 
		ttitem.RowNo__c  = 44;  // メディア種別,メディア名称
		ttitem.Field16__c = '55';
		ttitem.Field17__c = '66';
		ttitem.Field20__c = '77';// 単価,枚数,支払金額 
		ttitem.Field21__c = '1'; //数量
		ttitem.Field23__c = '123'; 
		ttitem.SplitGroupNo__c = '88';
		ttitem.PaymentType__c = '99';
		ttitem.PayProductName__c = '111';
		//ttitem.PayProductRef__c =;  // 支払商品
		//ttitem.PayProductRef__r.ActionType__c =;
		//ttitem.PayProductRef__r ='UNIT' + CommUtils.getRandom(9);
		//ttitem.RelAccount__r.Name =;  // 主従関係(売上)
		//ttitem.Field1__r.Relreserve__c =; 
		//ttitem.Field1__r.SalesdayCal__c =;
		ttitem.UseDate__c = Date.today();
		update ttitem;*/
		// 会計画面に動作確認を行う
		List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c];
		AccountAcount__c accObj = accObjLst[0];
		Test.startTest();
		
		ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
		BillInput_Ctrl ctrl = new BillInput_Ctrl(contrl);
		ctrl.initAction();
		ctrl.calPaymentInfo();
		ctrl.upsertData();
		BillSplitProcess split = new BillSplitProcess(contrl);
		split.c_showAll = true;
		split.refreshBillInfo();
		//split.refreshSimpleBillInfo();
		  
		split.c_splitNo = '03';
		split.c_actType = new String[]{'朝食'};
		split.c_dpId = '01';
		split.c_gpId = '02';
		split.c_productNm = 'テスト商品';
		split.c_termEt.WorkDay__c = Date.today();
		split.c_termSt.WorkDay__c = Date.today();
		split.refreshBillInfo();
		Test.stopTest();
		split.saveNo();
		BillSplitProcess.Option op = new BillSplitProcess.Option('','');
		split.getAccountNames();
		split.getAccountProvisos();
		//split.refreshSimpleBillInfo();
		System.assertNotEquals(split.accSobj, null);
	}
    @isTest(SeeAllData=false)
    static void test() {
	Test.startTest();
		/*
		// 予約情報を作成する
		Lead__c leadInfo = TestCommon.createLead();
		ExchangeRate__c rate = TestCommon.createExchangeRate();
		// 商品情報を作成する
		List<AccountMaster__c> productLst = TestCommon.createProductMst(4);
		// 見積明細を作成する
		BookingEstimateItem__c bookingItem = TestCommon.createBookEstItem(leadInfo, productLst[0]);
		//TestCommon.createBookEstItem(leadInfo, productLst[1]);
		AccountMaster__c accMst = productLst[1];
		accMst.ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
		accMst.PaymentType__c = 'カード';  // XMLの定義と合わせるが必要です
		accMst.Field3__c = '1';
		update accMst;
		AccountMaster__c accMstPay = productLst[2];
		accMstPay.ActionType__c = CommConst.PROD_ACTION_TYPE_PY;
		accMstPay.PaymentType__c = '売掛金';    // XMLの定義と合わせるが必要です
		update accMstPay; 
		// 予約情報のステータス：チェックインに変更する
		leadInfo.Field298__c = 'チェックイン完';
		update leadInfo;
		RsvAccount__c rsv = TestCommon.createRsvAccount();
		AccountAcount__c aa = TestCommon.createAccountAcount(rsv.Id, leadInfo.Id);
		// 会計画面に動作確認を行う
		List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c,SalesdayCal__c from AccountAcount__c where Relreserve__c = :leadInfo.Id];
		AccountAcount__c accObj = accObjLst[0];
		TTend__c ttitem = TestCommon.createTTend(rsv.Id, accObj.Id);
		ttitem.Field2__c = '22'; 
		ttitem.Field3__c = '予約金'; 
		ttitem.RowNo__c  = 44;  // メディア種別,メディア名称
		ttitem.Field16__c = '55';
		ttitem.Field17__c = '66';
		ttitem.Field20__c = '77';// 単価,枚数,支払金額 
		ttitem.Field21__c = '1'; //数量
		ttitem.Field23__c = '123'; 
		ttitem.SplitGroupNo__c = '88';
		ttitem.PaymentType__c = '99';
		ttitem.PayProductName__c = '111';
		ttitem.PayProductRef__c = accMst.id;  // 支払商品
		ttitem.PayProductName__c = accMst.Name;
		ttitem.Field5__c = '9';
		ttitem.PaymentType__c = accMst.PaymentType__c;
		ttitem.RelAccount__c =rsv.Id;  // 主従関係(売上)
		ttitem.UseDate__c = Date.today();
		update ttitem;
		
		
		ApexPages.currentPage().getParameters().put('accid',accObj.id);
		*/
		// 会計画面に動作確認を行う
		List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c];
		AccountAcount__c accObj = accObjLst[0];
		// zyz
		ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
		BillSplitProcess split = new BillSplitProcess(contrl);
		// zyz
		split.c_showAll = false;
		split.refreshBillInfo();
		split.refreshSimpleBillInfo();
		Test.stopTest();
		split.c_splitNo = '03';
		split.c_actType = new String[]{'朝食'};
		split.c_dpId = '01';
		split.c_gpId = '02';
		split.c_productNm = 'テスト商品';
		split.c_termEt.WorkDay__c = Date.today().addDays(-1);
		split.c_termSt.WorkDay__c = Date.today();
		split.refreshBillInfo();
		split.refreshSimpleBillInfo();
		split.saveNo();
		BillSplitProcess.Option op = new BillSplitProcess.Option('','');
		split.getAccountNames();
		split.getAccountProvisos();
		
		// zyz
		System.assertNotEquals(split.accSobj, null);
    }
    // 2019/07/30 予約見積は明細分割機能 BY zyz BEGIN
    @isTest(SeeAllData=false)
    static void leadtest() {
        CommDefine__c def = TestCommon.createCommDefine();
		def.BookingReportStampIsShowFlg__c = true;
		def.AccountSplitOutputFlg__c = true;
		update def;
		Test.startTest();
		// 予約情報を作成する
		Lead__c leadInfo = TestCommon.createLead();
		// 為替レート
		ExchangeRate__c rate = TestCommon.createExchangeRate();
		// 商品情報を作成する
		List<AccountMaster__c> productLst = TestCommon.createProductMst(4);
		// 見積明細を作成する
		BookingEstimateItem__c bookingItem = TestCommon.createBookEstItem(leadInfo, productLst[0]);
		AccountMaster__c accMst = productLst[1];
		accMst.ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
		accMst.PaymentType__c = 'カード';  // XMLの定義と合わせるが必要です
		accMst.Field3__c = '1000001';
		update accMst;
		AccountMaster__c accMstPay = productLst[2];
		accMstPay.ActionType__c = CommConst.PROD_ACTION_TYPE_PY;
		accMstPay.PaymentType__c = '売掛金';    // XMLの定義と合わせるが必要です
		update accMstPay; 
		
		ApexPages.currentPage().getParameters().put('id',leadInfo.Id);
        DateTime beforeDt = System.now().addDays(1);
		Date beforeDay = beforeDt.date();
        TimeManagement__c beforeItem = new TimeManagement__c(
		    Status__c = System.Label.MSG_1019,
			WorkDay__c = beforeDay,
			WorkerRef__c = UserInfo.getUserId(),
			WorkerName__c = UserInfo.getName(),
			WorkBeginTime__c = System.now().addDays(1),
			OutingTime__c = System.now().addDays(1),
			OutingTime2__c = System.now().addDays(1), 
			OutingTime3__c = System.now().addDays(1) 
		);
		insert beforeItem;
		ApexPages.StandardController contrl = new ApexPages.StandardController(leadInfo);
		LeadItemSplitProcess split = new LeadItemSplitProcess(contrl);
		split.c_showAll = false;
		split.refreshBillInfo();
		
		split.c_splitNo = '03';
		split.c_actType = new String[]{'朝食'};
		split.c_dpId = '01';
		split.c_gpId = '02';
		split.c_productNm = 'テスト商品';
		split.c_termEt.WorkDay__c = Date.today().addDays(-1);
		split.c_termSt.WorkDay__c = Date.today();
		split.refreshBillInfo();
		Test.stopTest();
		split.saveNo();
		LeadItemSplitProcess.Option op = new LeadItemSplitProcess.Option('','');
		split.getAccountNames();
		System.assertNotEquals(split.accSobj, null);
    }
    // 2019/07/30 予約見積は明細分割機能 BY zyz END
}