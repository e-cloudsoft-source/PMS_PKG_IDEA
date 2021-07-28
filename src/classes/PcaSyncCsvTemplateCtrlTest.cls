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
private class PcaSyncCsvTemplateCtrlTest {
    @testsetup
    static void dataSetup(){
        getCsvSetupConfig2();
    }
    // 入金、出金関連の関連のテスト作成を行う
    static testMethod void Case1 () {
          getCsvSetupConfig1();
          // getCsvSetupConfig2();
          createKankeKamoku();
          createDepInfo();
          createPayInfo();
          
          // 入金、出金のCSV出力機能確認
          Test.startTest();
          // 当日のCSV情報を出力する
            Date startDate = Date.today();
            // スケジュール実施開始日
            String strProcessDate = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('yyyyMMdd');
            List<RsvAccount__c> rsvAccLst = [select id,Name from RsvAccount__c where Name = :strProcessDate limit 1];
            PcaSyncCsvTemplateCtrl ctrl = new PcaSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
            String csv = ctrl.generalCsvContent();
            String[] csvRs = csv.split('\n');
            System.assertEquals(csvRs.size(), 3, csvRs);
            System.assert(csvRs[1].indexOf('内金摘要テスト') > 0, csv);
            System.assert(csvRs[1].indexOf('50000') > 0, csv);
            System.assert(csvRs[2].indexOf('交通費摘要テスト') > 0, csv);
            System.assert(csvRs[2].indexOf('28300') > 0, csv);
            Test.stopTest();
    }
    
    // 簡易会計から作成する会計のCSV抽出
    static testMethod void Case2 () {
		
        getCsvSetupConfig1_1();
        //getCsvSetupConfig2();
        List<KanjoKamoku__c> kanjoMst =  createKankeKamoku();
            // 商品作成する
        List<AccountMaster__c> prodList = TestCommon.createProductMst(2);
        prodList[0]. KanjoKamokuRef__c = kanjoMst[4].ID;
        // 現金の支払商品
        prodList[1].Field3__c = 'T90001';
        prodList[1].ActionType__c = CommConst.PROD_ACTION_TYPE_PY;
        prodList[1].PaymentType__c = 'カード';
        prodList[1]. KanjoKamokuRef__c = kanjoMst[2].ID;
        update prodList;
        // 
        SimpleAccountsCtrl simCtrl = new SimpleAccountsCtrl();
        simCtrl.mediaType = simCtrl.mediaTypeOptionLst[0].getValue();//現金で支払
        simCtrl.otran.Field20__c = '16000';
        simCtrl.otran.Field21__c = '2';
        simCtrl.otran.Field2__c = CommConst.MEDIA_TYPE_CD_02;
        simCtrl.otran.Field7__c = prodList[0].Id;
        simCtrl.otran.ActionType__c = prodList[0].ActionType__c;
        simCtrl.otran.TaxRate__c = prodList[0].TaxRateCal__c;
        simCtrl.otran.ServiceRate__c = prodList[0].ServiceRate__c;
        simCtrl.otran.SpecialTax__c = 200;
        simCtrl.oTtend.Field2__c = CommConst.MEDIA_TYPE_CD_02;
        simCtrl.oTtend.CardTypeLst__c = 'American Express';
        simCtrl.productNm = prodList[0].Name;
        simCtrl.saveTranToMemory();
        simCtrl.upsertData();

          Test.startTest();
          // 当日のCSV情報を出力する
            Date startDate = Date.today();
            // スケジュール実施開始日
            String strProcessDate = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('yyyyMMdd');
            List<RsvAccount__c> rsvAccLst = [select id,Name from RsvAccount__c where Name = :strProcessDate limit 1];
            PcaSyncCsvTemplateCtrl ctrl = new PcaSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
            String csv = ctrl.generalCsvContent();
            String[] csvRs = csv.split('\n');
            //System.assertEquals(csvRs.size(), 3, csvRs);
            System.assert(csvRs[1].indexOf('1110') > 0, csv);
            System.assert(csvRs[1].indexOf('11100001') > 0, csv);
            System.assert(csvRs[1].indexOf('5110') > 0, csv);
            System.assert(csvRs[1].indexOf('51100001') > 0, csv);
            System.assert(csvRs[1].indexOf('32000') > 0, csv);  
	        System.assert(csvRs[1].indexOf('32000.00') < 0, csv);  
            Test.stopTest();
    }
    
     static testMethod void Case2_1 () {

        getCsvSetupConfig1_1();
        // getCsvSetupConfig2();
        List<KanjoKamoku__c> kanjoMst =  createKankeKamoku();
            // 商品作成する
        List<AccountMaster__c> prodList = TestCommon.createProductMst(2);
        prodList[0]. KanjoKamokuRef__c = kanjoMst[4].ID;
        // 現金の支払商品
        prodList[1].Field3__c = 'T90001';
        prodList[1].ActionType__c = CommConst.PROD_ACTION_TYPE_PY;
        prodList[1].PaymentType__c = 'カード';
        prodList[1]. KanjoKamokuRef__c = kanjoMst[2].ID;
        update prodList;
        // 
        SimpleAccountsCtrl simCtrl = new SimpleAccountsCtrl();
        simCtrl.mediaType = simCtrl.mediaTypeOptionLst[1].getValue();//現金で支払
        simCtrl.otran.Field20__c = '16000';
        simCtrl.otran.Field21__c = '2';
        simCtrl.otran.Field2__c = CommConst.MEDIA_TYPE_CD_02;
        simCtrl.otran.Field7__c = prodList[1].Id;
        simCtrl.otran.ActionType__c = prodList[1].ActionType__c;
        simCtrl.otran.TaxRate__c = prodList[1].TaxRateCal__c;
        simCtrl.otran.ServiceRate__c = prodList[1].ServiceRate__c;
        simCtrl.otran.SpecialTax__c = 200;
        simCtrl.oTtend.Field2__c = CommConst.MEDIA_TYPE_CD_02;
        simCtrl.oTtend.CardTypeLst__c = 'American Express';
        simCtrl.productNm = prodList[0].Name;
        simCtrl.saveTranToMemory();
        simCtrl.upsertData();

          Test.startTest();
          // 当日のCSV情報を出力する
            Date startDate = Date.today();
            // スケジュール実施開始日
            String strProcessDate = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('yyyyMMdd');
            List<RsvAccount__c> rsvAccLst = [select id,Name from RsvAccount__c where Name = :strProcessDate limit 1];
            PcaSyncCsvTemplateCtrl ctrl = new PcaSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
            String csv = ctrl.generalCsvContent();
            String[] csvRs = csv.split('\n');  
            Test.stopTest();
    }
    // 連泊情報作成、連泊情報の自動チェックイン後、PCA連携情報の確認
    static testMethod void Case3 () {
        
        // Init Xml Config
        getCsvSetupConfig1();
        // getCsvSetupConfig2();
        // 2015/12/01 Assert BEGIN
        // System.assertEquals([select Id from Document where Name = 'SyncFieldConvertConfig'].size(), 1);
        // 2015/12/01 Assert END
        List<KanjoKamoku__c> kanjoMst =  createKankeKamoku();
        List<AccountMaster__c> paymentProdList = createMediaProductMst(kanjoMst);

        Contact guest = TestCommon.createContact();
        // 予約情報を作成する
        List<Lead__c> leadInfos = TestCommon.createLead(Date.today(), 1, 3, guest.Id);
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(4);
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfos[0], productLst[0]);
        TestCommon.createBookEstItem(leadInfos[1], productLst[0]);
//        TestCommon.createBookEstItem(leadInfos[2], productLst[0]);
        // 商品２は前受付金に変更を行う
        AccountMaster__c accMst = productLst[3];
        accMst.ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
        accMst.PaymentType__c = 'カード';  // XMLの定義と合わせるが必要です
        update accMst;

        TestCommon.createBookEstItem(leadInfos[0], accMst); // カード
Test.startTest();
        // 予約情報のステータス：チェックインに変更する
        leadInfos[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfos[0];
		
        // 会計画面に動作確認を行う
        List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfos[0].Id];
        AccountAcount__c accObj = accObjLst[0];

        ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
        BillSimpleInputCtrl ctrl = new BillSimpleInputCtrl(contrl);
        ctrl.initAction();

        ctrl.upsertData();
        ctrl.addTran1Item();//入力行目を増える

        // 商品３は会計明細に設定する
        List<BillSimpleInputCtrl.TranItem> rsTranItems = ctrl.oTranSobjLst;

        rsTranItems[2].productNm = productLst[1].Name;
        rsTranItems[2].sobj.Field7__c = productLst[1].Id;
        rsTranItems[2].sobj.ActionType__c = productLst[1].ActionType__c;
        rsTranItems[2].sobj.PaymentType__c = productLst[1].PaymentType__c;
        rsTranItems[2].sobj.UseDate__c = system.today();
        rsTranItems[2].tranId = '';
        rsTranItems[2].accRefId = '';
        rsTranItems[2].sobj.Field20__c = '200000';
        rsTranItems[2].sobj.Field21__c = '1';
        // 商品４は会計支払情報として、明細に設定する
        rsTranItems[3].productNm = paymentProdList[3].Name;
        rsTranItems[3].sobj.Field7__c = paymentProdList[3].Id;
        rsTranItems[3].sobj.ActionType__c = productLst[3].ActionType__c;
        rsTranItems[3].sobj.PaymentType__c = productLst[3].PaymentType__c;
        rsTranItems[3].sobj.UseDate__c = system.today();
        rsTranItems[3].tranId = '';
        rsTranItems[3].accRefId = '';
        rsTranItems[3].sobj.Field20__c = '1000';
        rsTranItems[3].sobj.Field21__c = '1';
        // 商品５は会計支払情報として、明細に設定する
        rsTranItems[4].productNm = paymentProdList[4].Name;
        rsTranItems[4].sobj.Field7__c = paymentProdList[4].Id;
        rsTranItems[4].sobj.ActionType__c = paymentProdList[4].ActionType__c;
        rsTranItems[4].sobj.PaymentType__c = paymentProdList[4].PaymentType__c;
        rsTranItems[4].sobj.UseDate__c = system.today();
        rsTranItems[4].tranId = '';
        rsTranItems[4].accRefId = '';
        rsTranItems[4].sobj.Field20__c = '500';
        rsTranItems[4].sobj.Field21__c = '2';
        ctrl.upsertData();
Test.stopTest();        
      // 当日のCSV情報を出力する
        Date startDate = Date.today();
        // スケジュール実施開始日
        String strProcessDate = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('yyyyMMdd');
        List<RsvAccount__c> rsvAccLst = [select id,Name from RsvAccount__c where Name = :strProcessDate limit 1];
        PcaSyncCsvTemplateCtrl ctrl1 = new PcaSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
        String csv = ctrl1.generalCsvContent();
		/*
        leadInfos[1].Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfos[1];
        startDate = Date.today().addDays(1);
        // スケジュール実施開始日
        strProcessDate = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('yyyyMMdd');
        rsvAccLst = [select id,Name from RsvAccount__c where Name = :strProcessDate limit 1];
        ctrl1 = new PcaSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
        csv = ctrl1.generalCsvContent();
        */
        /*
        leadInfos[2].Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfos[2];
        startDate = Date.today().addDays(2);
        // スケジュール実施開始日
        strProcessDate = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('yyyyMMdd');
        rsvAccLst = [select id,Name from RsvAccount__c where Name = :strProcessDate limit 1];
        ctrl1 = new PcaSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
        csv = ctrl1.generalCsvContent();
        */

    }
    // 新会計メニューの場合、PCA連携情報を行う
    static testMethod void Case4 () {
		
		CommDefine__c comDef = TestCommon.createCommDefine();
		comDef.BillInputSwitchCode__c = '2';
		comDef.AccountSoftSyncCsvType__c = '2';
		update comDef;
        // Init Xml Config
        getCsvSetupConfig1();
        // getCsvSetupConfig2();
        // 2015/12/01 Assert BEGIN
        // System.assertEquals([select Id from Document where Name = 'SyncFieldConvertConfig'].size(), 1);
        // 2015/12/01 Assert END
        List<KanjoKamoku__c> kanjoMst =  createKankeKamoku();
        List<AccountMaster__c> paymentProdList = createMediaProductMst(kanjoMst);

        Contact guest = TestCommon.createContact();
        // 予約情報を作成する
        List<Lead__c> leadInfos = TestCommon.createLead(Date.today(), 1, 3, guest.Id);
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(4);
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfos[0], productLst[0]);
        TestCommon.createBookEstItem(leadInfos[1], productLst[0]);
        //TestCommon.createBookEstItem(leadInfos[2], productLst[0]);
        // 商品２は前受付金に変更を行う
        AccountMaster__c accMst = productLst[3];
        accMst.ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
        accMst.PaymentType__c = 'カード';  // XMLの定義と合わせるが必要です
        update accMst;
        Test.startTest();
        TestCommon.createBookEstItem(leadInfos[0], accMst); // カード
        
        // 予約情報のステータス：チェックインに変更する
        leadInfos[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfos[0];
        
        // 会計画面に動作確認を行う
        List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfos[0].Id];
        AccountAcount__c accObj = accObjLst[0];

        ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
        BillSimpleInputCtrl ctrl = new BillSimpleInputCtrl(contrl);
        ctrl.initAction();
		
        ctrl.upsertData();
        ctrl.addTran1Item();//入力行目を増える
        
        // 商品３は会計明細に設定する
        List<BillSimpleInputCtrl.TranItem> rsTranItems = ctrl.oTranSobjLst;

        rsTranItems[2].productNm = productLst[1].Name;
        rsTranItems[2].sobj.Field7__c = productLst[1].Id;
        rsTranItems[2].sobj.ActionType__c = productLst[1].ActionType__c;
        rsTranItems[2].sobj.PaymentType__c = productLst[1].PaymentType__c;
        rsTranItems[2].tranId = '';
        rsTranItems[2].accRefId = '';
        rsTranItems[2].sobj.Field20__c = '200000';
        rsTranItems[2].sobj.Field21__c = '1';
        // 商品４は会計支払情報として、明細に設定する
        rsTranItems[3].productNm = paymentProdList[3].Name;
        rsTranItems[3].sobj.Field7__c = paymentProdList[3].Id;
        rsTranItems[3].sobj.ActionType__c = productLst[3].ActionType__c;
        rsTranItems[3].sobj.PaymentType__c = productLst[3].PaymentType__c;
        rsTranItems[3].tranId = '';
        rsTranItems[3].accRefId = '';
        rsTranItems[3].sobj.Field20__c = '1000';
        rsTranItems[3].sobj.Field21__c = '1';
        // 商品５は会計支払情報として、明細に設定する
        rsTranItems[4].productNm = paymentProdList[4].Name;
        rsTranItems[4].sobj.Field7__c = paymentProdList[4].Id;
        rsTranItems[4].sobj.ActionType__c = paymentProdList[4].ActionType__c;
        rsTranItems[4].sobj.PaymentType__c = paymentProdList[4].PaymentType__c;
        rsTranItems[4].tranId = '';
        rsTranItems[4].accRefId = '';
        rsTranItems[4].sobj.Field20__c = '500';
        rsTranItems[4].sobj.Field21__c = '2';
        ctrl.upsertData();
Test.stopTest();
      // 当日のCSV情報を出力する
        Date startDate = Date.today();
        // スケジュール実施開始日
        String strProcessDate = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('yyyyMMdd');
        List<RsvAccount__c> rsvAccLst = [select id,Name from RsvAccount__c where Name = :strProcessDate limit 1];
        PcaSyncCsvTemplateCtrl ctrl1 = new PcaSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
        String csv = ctrl1.generalCsvContent();
         /*
        leadInfos[1].Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfos[1];
        startDate = Date.today().addDays(1);
        // スケジュール実施開始日
        strProcessDate = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('yyyyMMdd');
        rsvAccLst = [select id,Name from RsvAccount__c where Name = :strProcessDate limit 1];
        ctrl1 = new PcaSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
        csv = ctrl1.generalCsvContent();
		/*
        leadInfos[2].Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfos[2];
        startDate = Date.today().addDays(2);
        // スケジュール実施開始日
        strProcessDate = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('yyyyMMdd');
        rsvAccLst = [select id,Name from RsvAccount__c where Name = :strProcessDate limit 1];
        ctrl1 = new PcaSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
        csv = ctrl1.generalCsvContent();
        */
    }

    static testMethod void Case5() {
    	getCsvSetupConfig1();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'SyncFieldConvertConfig'].size(), 1);
        // 2015/12/01 Assert END
    	Document doc = [select id from Document limit 1];
    	System.currentPageReference().getParameters().put('rid',doc.Id);
    	System.currentPageReference().getHeaders().put('USER-AGENT','MSIE');
    	PcaSyncCsvDownloadCtrl down = new PcaSyncCsvDownloadCtrl();
    	PageReference pg = down.downCsvFile();
    	
    }
    /*
    static testMethod void Case6 () {
		Test.startTest();
		CommDefine__c comDef = TestCommon.createCommDefine();
		comDef.BillInputSwitchCode__c = '2';
		comDef.AccountSoftSyncCsvType__c = '2';
		update comDef;
        // Init Xml Config
        getCsvSetupConfig1_1();
        getCsvSetupConfig2();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'SyncFieldConvertConfig'].size(), 1);
        // 2015/12/01 Assert END
        List<KanjoKamoku__c> kanjoMst =  createKankeKamoku();
        List<AccountMaster__c> paymentProdList = createMediaProductMst(kanjoMst);

        Contact guest = TestCommon.createContact();
        // 予約情報を作成する
        List<Lead__c> leadInfos = TestCommon.createLead(Date.today(), 1, 3, guest.Id);
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(4);
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfos[0], productLst[0]);
        TestCommon.createBookEstItem(leadInfos[1], productLst[0]);
        //TestCommon.createBookEstItem(leadInfos[2], productLst[0]);
        // 商品２は前受付金に変更を行う
        AccountMaster__c accMst = productLst[3];
        accMst.ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
        accMst.PaymentType__c = '予約金';  // XMLの定義と合わせるが必要です
        update accMst;
        
        TestCommon.createBookEstItem(leadInfos[0], accMst); // カード
        
        Test.stopTest();
        
        // 予約情報のステータス：チェックインに変更する
        leadInfos[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfos[0];
        
        // 会計画面に動作確認を行う
        RsvAccount__c rsv = TestCommon.createRsvAccount();
    	rsv = [select Salesday__c from RsvAccount__c where id = :rsv.id];
    	AccountAcount__c aa = TestCommon.createAccountAcount(rsv.Id, leadInfos[0].Id);
        List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfos[0].Id];
        AccountAcount__c accObj = accObjLst[0];
		TTend__c ttitem = TestCommon.createTTend(rsv.id,accObj.id);  
	    ttitem.field2__c = '22'; 
	    ttitem.field3__c = '33'; 
	    ttitem.RowNo__c  = 44;  // メディア種別,メディア名称
	    ttitem.Field16__c = '55';
	    ttitem.Field17__c = '66';
	    ttitem.Field20__c = '77';// 単価,枚数,支払金額 
	    ttitem.SplitGroupNo__c = '88';
	    ttitem.PaymentType__c = '99';
	    ttitem.PayProductName__c = '111';
	    ttitem.UseDate__c = Date.today();
	    update ttitem;
		DateTime startDates = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
	    LeadIndex__c item = new LeadIndex__c(
    		ID__c = String.valueOf('101731864'),
    		Nights__c = 1,
     		EntryTime__c = '10:00',
    		EntryDate__c = startDates.date(),
    		DepartureTime__c = '15:30',
    		DepartureDate__c = startDates.addDays(1).date(),
			EventSource__c = 'FromTravelAgency',
			APPNAME__c = 'TL',
			Rooms__c = 1
    	);
    	insert item;
    	List<Tran1__c> tranLst = [select id,PaymentType__c from Tran1__c where Field7__c = :productLst[0].Id];
    	Tran1__c  tran1 = tranLst[0];
		PaymentInfo__c pay = new PaymentInfo__c(
												AccountAcountRef__c = accObj.id,
												TTendRef__c = ttitem.id,
												Tran1Ref__c = tran1.id,
												PaymentType__c = '予約金',
												LeadIndexRef__c = item.id
												);
		insert pay;	
		PaymentDetail__c payment = new PaymentDetail__c(
												AccountAcountRef__c = accObj.id,
												PaymentInfoRef__c = pay.id
												);
		insert payment;
        ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
        BillSimpleInputCtrl ctrl = new BillSimpleInputCtrl(contrl);
        ctrl.initAction();
		
        ctrl.upsertData();
        ctrl.addTran1Item();//入力行目を増える
        
        // 商品３は会計明細に設定する
        List<BillSimpleInputCtrl.TranItem> rsTranItems = ctrl.oTranSobjLst;

        rsTranItems[2].productNm = productLst[1].Name;
        rsTranItems[2].sobj.Field7__c = productLst[1].Id;
        rsTranItems[2].sobj.ActionType__c = productLst[1].ActionType__c;
        rsTranItems[2].sobj.PaymentType__c = '予約金';
        rsTranItems[2].tranId = '';
        rsTranItems[2].accRefId = '';
        rsTranItems[2].sobj.Field20__c = '200000';
        rsTranItems[2].sobj.Field21__c = '1';
        // 商品４は会計支払情報として、明細に設定する
        rsTranItems[3].productNm = paymentProdList[3].Name;
        rsTranItems[3].sobj.Field7__c = paymentProdList[3].Id;
        rsTranItems[3].sobj.ActionType__c = productLst[3].ActionType__c;
        rsTranItems[3].sobj.PaymentType__c = '予約金';
        rsTranItems[3].tranId = '';
        rsTranItems[3].accRefId = '';
        rsTranItems[3].sobj.Field20__c = '1000';
        rsTranItems[3].sobj.Field21__c = '1';
        // 商品５は会計支払情報として、明細に設定する
        rsTranItems[4].productNm = paymentProdList[4].Name;
        rsTranItems[4].sobj.Field7__c = paymentProdList[4].Id;
        rsTranItems[4].sobj.ActionType__c = paymentProdList[4].ActionType__c;
        rsTranItems[4].sobj.PaymentType__c = '予約金';
        rsTranItems[4].tranId = '';
        rsTranItems[4].accRefId = '';
        rsTranItems[4].sobj.Field20__c = '500';
        rsTranItems[4].sobj.Field21__c = '2';
        ctrl.upsertData();
         
      // 当日のCSV情報を出力する
        Date startDate = Date.today();
        // スケジュール実施開始日
        String strProcessDate = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('yyyyMMdd');
        List<RsvAccount__c> rsvAccLst = [select id,Name from RsvAccount__c where Name = :strProcessDate limit 1];
        PcaSyncCsvTemplateCtrl ctrl1 = new PcaSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
        String csv = ctrl1.generalCsvContent();
       
    }*/
    
    static testMethod void pageUtilCase () {
    	List<Account> accLst = new List<Account>();
    	for (Integer i = 0;  i<100;i++) {
    		accLst.add(new account());
    	}
    	PaginationUtil pt = new PaginationUtil(accLst, 10);
    	System.assertEquals(pt.records.size(),10);
    	System.assertEquals(pt.pageNum,'1');
    	System.assertEquals(pt.pageCount,'10');
    	pt.nextPage();
    	pt.lastPage();
    	pt.previousPage();
    	pt.firstPage();
    	pt.getTotalRs();
    	pt.getPageSize();
    	pt.getStartRsNo();
    	pt.getEndRsNo();
    	List<String> rs = pt.displayColums;
    	Boolean msgFlg = pt.mesgFlg;
    	
    } 
    /**
    * メデイア関連の会計商品情報作成
    **/
    private static List<AccountMaster__c> createMediaProductMst(List<KanjoKamoku__c> kanjoMst) {
        List<AccountMaster__c> prodList = TestCommon.createProductMst(7);
        prodList[0].Field3__c = 'T90001';
        prodList[0].ActionType__c = CommConst.PROD_ACTION_TYPE_PY;
        prodList[0].PaymentType__c = '現金';
        prodList[0].KanjoKamokuRef__c = kanjoMst[1].ID;
        prodList[0].Field5__c = 200000;

        prodList[1].Field3__c = 'T90002';
        prodList[1].ActionType__c = CommConst.PROD_ACTION_TYPE_PY;
        prodList[1].PaymentType__c = 'カード';
        prodList[1].KanjoKamokuRef__c = kanjoMst[1].ID;
        prodList[1].Field5__c = 200000;

        prodList[2].Field3__c = 'T90003';
        prodList[2].ActionType__c = CommConst.PROD_ACTION_TYPE_PY;
        prodList[2].PaymentType__c = '売掛金';
        prodList[2].KanjoKamokuRef__c = kanjoMst[1].ID;
        prodList[2].Field5__c = 200000;

        prodList[3].Field3__c = 'T90004';
        prodList[3].ActionType__c = CommConst.PROD_ACTION_TYPE_PY;
        prodList[3].PaymentType__c = 'クーポン';
        prodList[3].KanjoKamokuRef__c = kanjoMst[1].ID;
        prodList[3].Field5__c = 1000;

        prodList[4].Field3__c = 'T90005';
        prodList[4].ActionType__c = CommConst.PROD_ACTION_TYPE_PY;
        prodList[4].PaymentType__c = '値引';
        prodList[4].KanjoKamokuRef__c = kanjoMst[1].ID;
        prodList[4].Field5__c = 100;

        prodList[5].Field3__c = 'T90006';
        prodList[5].ActionType__c = CommConst.PROD_ACTION_TYPE_PY;
        prodList[5].PaymentType__c = '予約金';
        prodList[5].KanjoKamokuRef__c = kanjoMst[1].ID;
        prodList[5].Field5__c = 200000;
        
        prodList[6].ActionType__c = CommConst.PROD_ACTION_TYPE_PY;
        prodList[6].PaymentType__c = '返金';    // XMLの定義と合わせるが必要で
        prodList[6].Field5__c = 2000;

        update prodList;
        return prodList;
    }
    
    private static void createDepInfo () {
            Id contactId = TestCommon.createContact().Id;
            //Test.setCurrentPageReference(new PageReference('Page.CashManagentInput')); 
            System.currentPageReference().getParameters().put('pm', CashManagentInput.CONST_PAGE_MODE_IN);
            CashManagentInput ctrl = new CashManagentInput();
            ctrl.init();
            // 情報を入力する
            ctrl.editRowIdx = 0;
            ctrl.input.pageMode = CashManagentInput.CONST_PAGE_MODE_IN;
            List<CashManagentInput.ItemInfo> deposLists = ctrl.deposList;
            // 1件新規のみ
            deposit__c input = ctrl.inpData.dep;
            input.SalesDate__c = deposLists[0].dep.SalesDate__c;
            input.deposit__c = contactId;
            input.Kamoku__c  = '内金';
            input.deposititem__c = '内金摘要テスト';
            input.depositamount__c = 50000;
            ctrl.dataUpsert();

    }
    
    public static void createPayInfo () {
            Id contactId = TestCommon.createContact().Id;
            System.currentPageReference().getParameters().put('pm', CashManagentInput.CONST_PAGE_MODE_OU);
            CashManagentInput ctrl = new CashManagentInput();
            ctrl.init();
            // Page Mode Confirm
            System.assertEquals(ctrl.input.pageMode, CashManagentInput.CONST_PAGE_MODE_OU, ctrl.input.pageMode);
            // 情報を入力する
            ctrl.editRowIdx = 0;
            ctrl.input.pageMode = CashManagentInput.CONST_PAGE_MODE_OU;
            List<CashManagentInput.ItemInfo> paymentLists = ctrl.paymentList;
            System.assertEquals(paymentLists.size(), 1, paymentLists);
            // 1件新規のみ
            //CashManagentInput.ItemInfo firstItem = paymentLists[0];
            Paymentslip__c input = ctrl.inpData.pay;
            input.SalesDate__c = paymentLists[0].pay.SalesDate__c;
            input.Pkamoku__c  = '交通費';
            input.Pitem__c = '交通費摘要テスト';
            input.Pamount__c = 28300;
            ctrl.dataUpsert();
    }

    // 会計科目情報の作成
    private static List<KanjoKamoku__c> createKankeKamoku() {
        // 消費税:3350
        KanjoKamoku__c newItem1 = new KanjoKamoku__c(
              Kanjocode__c = '3350'
            , KanjocodeCode__c = '3350'
            , Name='仮受消費税'
            , DebitTaxKbn__c = '00'
            , CreditTaxKbn__c='B4'
            , BalanceKbn__c = '貸方'
        );
        // 前受付金:3241
        KanjoKamoku__c newItem2 = new KanjoKamoku__c(
              Kanjocode__c = '3241003'
            , KanjocodeCode__c = '3241'
            , Name='ﾎﾃﾙ前受金'
            , KanjoHojocode__c='0011'
            , KanjoHojoname__c = 'ﾘｽﾄｻﾞﾝ'
            , DebitTaxKbn__c = '00'
            , CreditTaxKbn__c='00'
            , BalanceKbn__c = '貸方'
        );
        // 現金：1110
        KanjoKamoku__c newItem3 = new KanjoKamoku__c(
              Kanjocode__c = '1110'
            , KanjocodeCode__c = '1110'
            , KanjoHojocode__c='11100001'
            , KanjoHojoname__c = 'テスト'
            , Name='現金'
            , DebitTaxKbn__c = '00'
            , CreditTaxKbn__c='00'
            , BalanceKbn__c = '借方'
        );
        // ﾎﾃﾙ未収入金：1841
        KanjoKamoku__c newItem4 = new KanjoKamoku__c(
              Kanjocode__c = '1841'
            , KanjocodeCode__c = '1841'
            , Name='ﾎﾃﾙ未収入金'
            , DebitTaxKbn__c = '00'
            , CreditTaxKbn__c='00'
            , BalanceKbn__c = '借方'
        );
        // 5110 ﾎﾃﾙﾋﾞｼﾞﾈｽ売上
        KanjoKamoku__c newItem5 = new KanjoKamoku__c(
              Kanjocode__c = '5110'
            , KanjocodeCode__c = '5110'
            , KanjoHojocode__c='51100001'
            , KanjoHojoname__c = 'テストA'
            , Name='ﾎﾃﾙﾋﾞｼﾞﾈｽ売上'
            , DebitTaxKbn__c = 'B4'
            , CreditTaxKbn__c='B4'
            , BalanceKbn__c = '貸方'
        );
        
        List<KanjoKamoku__c> insLst = new List<KanjoKamoku__c>();
        insLst.add(newItem1);
        insLst.add(newItem2);
        insLst.add(newItem3);
        insLst.add(newItem4);
        insLst.add(newItem5);
        insert insLst;
        return insLst;
    }
    static testMethod void addCase () {
        // Init Xml Config
        getCsvSetupConfig1();
        // getCsvSetupConfig2();
        CommDefine__c comDef = [select Id, BillInputSwitchCode__c from CommDefine__c limit 1];
		comDef.BillInputSwitchCode__c = '2';
		// comDef.AccountSoftSyncCsvType__c = '2';
		update comDef;
		System.assertEquals([select Id from CommDefine__c].size(), 1);
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'SyncFieldConvertConfig'].size(), 1);
        // 2015/12/01 Assert END
        List<KanjoKamoku__c> kanjoMst =  createKankeKamoku();
        List<AccountMaster__c> paymentProdList = createMediaProductMst(kanjoMst);

        Contact guest = TestCommon.createContact();
        // 予約情報を作成する
        List<Lead__c> leadInfos = TestCommon.createLead(Date.today(), 1, 3, guest.Id);
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(4);
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfos[0], productLst[0]);
        TestCommon.createBookEstItem(leadInfos[1], productLst[0]);
		// TestCommon.createBookEstItem(leadInfos[2], productLst[0]);
        // 商品２は前受付金に変更を行う
        AccountMaster__c accMst = productLst[3];
        accMst.ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
        accMst.PaymentType__c = 'カード';  // XMLの定義と合わせるが必要です
        update accMst;
Test.startTest();
        TestCommon.createBookEstItem(leadInfos[0], accMst); // カード
        // 予約情報のステータス：チェックインに変更する
        leadInfos[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;

        update leadInfos[0];
		
        // 会計画面に動作確認を行う
        List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfos[0].Id];
        AccountAcount__c accObj = accObjLst[0];

        ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
        BillSimpleInputCtrl ctrl = new BillSimpleInputCtrl(contrl);
        ctrl.initAction();
 
        ctrl.upsertData();
        ctrl.addTran1Item();//入力行目を増える
    
        // 商品３は会計明細に設定する
        List<BillSimpleInputCtrl.TranItem> rsTranItems = ctrl.oTranSobjLst;

        rsTranItems[2].productNm = productLst[1].Name;
        rsTranItems[2].sobj.Field7__c = productLst[1].Id;
        rsTranItems[2].sobj.ActionType__c = productLst[1].ActionType__c;
        rsTranItems[2].sobj.PaymentType__c = productLst[1].PaymentType__c;
        rsTranItems[2].tranId = '';
        rsTranItems[2].accRefId = '';
        rsTranItems[2].sobj.Field20__c = '200000';
        rsTranItems[2].sobj.Field21__c = '1';
        // 商品４は会計支払情報として、明細に設定する
        rsTranItems[3].productNm = paymentProdList[3].Name;
        rsTranItems[3].sobj.Field7__c = paymentProdList[3].Id;
        rsTranItems[3].sobj.ActionType__c = productLst[3].ActionType__c;
        rsTranItems[3].sobj.PaymentType__c = productLst[3].PaymentType__c;
        rsTranItems[3].tranId = '';
        rsTranItems[3].accRefId = '';
        rsTranItems[3].sobj.Field20__c = '1000';
        rsTranItems[3].sobj.Field21__c = '1';
        // 商品５は会計支払情報として、明細に設定する
        rsTranItems[4].productNm = paymentProdList[4].Name;
        rsTranItems[4].sobj.Field7__c = paymentProdList[4].Id;
        rsTranItems[4].sobj.ActionType__c = paymentProdList[4].ActionType__c;
        rsTranItems[4].sobj.PaymentType__c = paymentProdList[4].PaymentType__c;
        rsTranItems[4].tranId = '';
        rsTranItems[4].accRefId = '';
        rsTranItems[4].sobj.Field20__c = '500';
        rsTranItems[4].sobj.Field21__c = '2';
        ctrl.upsertData();
      // 当日のCSV情報を出力する
        Date startDate = Date.today();
        // スケジュール実施開始日
        String strProcessDate = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('yyyyMMdd');
        List<RsvAccount__c> rsvAccLst = [select id,Name from RsvAccount__c where Name = :strProcessDate limit 1];
  Test.stopTest();          
        PcaSyncCsvTemplateCtrl ctrl1 = new PcaSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
        String csv = ctrl1.generalCsvContent();
  
    }
    static testMethod void addCase1 () {
        Test.startTest();
        // Init Xml Config
        getCsvSetupConfig1();
        // getCsvSetupConfig2();
        CommDefine__c comDef = [select Id, BillInputSwitchCode__c from CommDefine__c limit 1];
		comDef.BillInputSwitchCode__c = '2';
		// comDef.AccountSoftSyncCsvType__c = '2';
		update comDef;
		System.assertEquals([select Id from CommDefine__c].size(), 1);
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'SyncFieldConvertConfig'].size(), 1);
        // 2015/12/01 Assert END
        List<KanjoKamoku__c> kanjoMst =  createKankeKamoku();
        List<AccountMaster__c> paymentProdList = createMediaProductMst(kanjoMst);

        Contact guest = TestCommon.createContact();
        // 予約情報を作成する
        List<Lead__c> leadInfos = TestCommon.createLead(Date.today(), 1, 3, guest.Id);
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(4);
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfos[0], productLst[0]);
        TestCommon.createBookEstItem(leadInfos[1], productLst[0]);
		// TestCommon.createBookEstItem(leadInfos[2], productLst[0]);
        // 商品２は前受付金に変更を行う
        AccountMaster__c accMst = productLst[3];
        accMst.ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
        accMst.PaymentType__c = 'カード';  // XMLの定義と合わせるが必要です
        update accMst;

        TestCommon.createBookEstItem(leadInfos[0], accMst); // カード
		Test.stopTest();
        // 予約情報のステータス：チェックインに変更する
        leadInfos[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfos[0];
		
        // 会計画面に動作確認を行う
        //List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfos[0].Id];
        //AccountAcount__c accObj = accObjLst[0];
		
		// 会計画面に動作確認を行う
        RsvAccount__c rsv = TestCommon.createRsvAccount();
    	rsv = [select Salesday__c from RsvAccount__c where id = :rsv.id];
    	AccountAcount__c aa = TestCommon.createAccountAcount(rsv.Id, leadInfos[0].Id);
        List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfos[0].Id];
        AccountAcount__c accObj = accObjLst[0];
		TTend__c ttitem = TestCommon.createTTend(rsv.id,accObj.id);  
	    ttitem.field2__c = '11'; 
	    ttitem.field3__c = '33'; 
	    ttitem.RowNo__c  = 44;  // メディア種別,メディア名称
	    ttitem.Field16__c = '55';
	    ttitem.Field17__c = '66';
	    ttitem.Field20__c = '77';// 単価,枚数,支払金額 
	    ttitem.SplitGroupNo__c = '88';
	    ttitem.PaymentType__c = '99';
	    ttitem.PayProductName__c = '111';
	    ttitem.UseDate__c = Date.today();
	    update ttitem;
		
		DateTime startDates = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
	    LeadIndex__c item = new LeadIndex__c(
    		ID__c = String.valueOf('101731864'),
    		Nights__c = 1,
     		EntryTime__c = '10:00',
    		EntryDate__c = startDates.date(),
    		DepartureTime__c = '15:30',
    		DepartureDate__c = startDates.addDays(1).date(),
			EventSource__c = 'FromTravelAgency',
			APPNAME__c = 'TL',
			Rooms__c = 1
    	);
    	insert item;
    	
    	List<Tran1__c> tranLst = [select id,PaymentType__c from Tran1__c where Field7__c = :productLst[0].Id];
    	Tran1__c  tran1 = tranLst[0];
		PaymentInfo__c pay = new PaymentInfo__c(
												AccountAcountRef__c = accObj.id,
												TTendRef__c = ttitem.id,
												Tran1Ref__c = tran1.id,
												LeadIndexRef__c = item.id,
												PaymentType__c = '予約金',
												MediaTypeCode__c = CommConst.MEDIA_TYPE_CD_11,
												DepositAmount__c = 50000
												);
		insert pay;
		
		PaymentDetail__c payment = new PaymentDetail__c(
												AccountAcountRef__c = accObj.id,
												PaymentInfoRef__c = pay.id
												);
		insert payment;
      	 // 当日のCSV情報を出力する
        Date startDate = Date.today();
        // スケジュール実施開始日
        String strProcessDate = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('yyyyMMdd');
        List<RsvAccount__c> rsvAccLst = [select id,Name from RsvAccount__c where Name = :strProcessDate limit 1];
        PcaSyncCsvTemplateCtrl ctrl1 = new PcaSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
        String csv = ctrl1.generalCsvContent();
    }
    static testMethod void addCase2 () {
        Test.startTest();
        // Init Xml Config
        getCsvSetupConfig1();
        // getCsvSetupConfig2();
        CommDefine__c comDef = [select Id, BillInputSwitchCode__c from CommDefine__c limit 1];
		comDef.BillInputSwitchCode__c = '2';
		// comDef.AccountSoftSyncCsvType__c = '2';
		update comDef;
		System.assertEquals([select Id from CommDefine__c].size(), 1);
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'SyncFieldConvertConfig'].size(), 1);
        // 2015/12/01 Assert END
        List<KanjoKamoku__c> kanjoMst =  createKankeKamoku();
        List<AccountMaster__c> paymentProdList = createMediaProductMst(kanjoMst);

        Contact guest = TestCommon.createContact();
        // 予約情報を作成する
        List<Lead__c> leadInfos = TestCommon.createLead(Date.today(), 1, 3, guest.Id);
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(4);
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfos[0], productLst[0]);
        TestCommon.createBookEstItem(leadInfos[1], productLst[0]);
		// TestCommon.createBookEstItem(leadInfos[2], productLst[0]);
        // 商品２は前受付金に変更を行う
        AccountMaster__c accMst = productLst[3];
        accMst.ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
        accMst.PaymentType__c = 'カード';  // XMLの定義と合わせるが必要です
        update accMst;

        TestCommon.createBookEstItem(leadInfos[0], accMst); // カード
		Test.stopTest();
        // 予約情報のステータス：チェックインに変更する
        leadInfos[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfos[0];
		
        // 会計画面に動作確認を行う
        //List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfos[0].Id];
        //AccountAcount__c accObj = accObjLst[0];
		
		// 会計画面に動作確認を行う
        RsvAccount__c rsv = TestCommon.createRsvAccount();
    	rsv = [select Salesday__c from RsvAccount__c where id = :rsv.id];
    	AccountAcount__c aa = TestCommon.createAccountAcount(rsv.Id, leadInfos[0].Id);
        List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfos[0].Id];
        AccountAcount__c accObj = accObjLst[0];
		TTend__c ttitem = TestCommon.createTTend(rsv.id,accObj.id);  
	    ttitem.field2__c = '12'; 
	    ttitem.field3__c = '33'; 
	    ttitem.RowNo__c  = 44;  // メディア種別,メディア名称
	    ttitem.Field16__c = '55';
	    ttitem.Field17__c = '66';
	    ttitem.Field19__c = '67';
	    ttitem.Field20__c = '77';// 単価,枚数,支払金額 
	    ttitem.SplitGroupNo__c = '88';	    
	    ttitem.PaymentType__c = '99';
	    ttitem.PayProductName__c = '111';
	    ttitem.CardTypeLst__c = 'American Express';
	    ttitem.UseDate__c = Date.today();
	    update ttitem;
		
		DateTime startDates = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
	    LeadIndex__c item = new LeadIndex__c(
    		ID__c = String.valueOf('101731864'),
    		Nights__c = 1,
     		EntryTime__c = '10:00',
    		EntryDate__c = startDates.date(),
    		DepartureTime__c = '15:30',
    		DepartureDate__c = startDates.addDays(1).date(),
			EventSource__c = 'FromTravelAgency',
			APPNAME__c = 'TL',
			Rooms__c = 1
    	);
    	insert item;
    	
    	List<Tran1__c> tranLst = [select id,PaymentType__c from Tran1__c where Field7__c = :productLst[0].Id];
    	Tran1__c  tran1 = tranLst[0];
    	tran1.PaymentType__c = 'カード';
		PaymentInfo__c pay = new PaymentInfo__c(
												AccountAcountRef__c = accObj.id,
												TTendRef__c = ttitem.id,
												Tran1Ref__c = tran1.id,
												LeadIndexRef__c = item.id,
												PaymentType__c = '予約金',
												MediaTypeCode__c = CommConst.MEDIA_TYPE_CD_12,
												DepositAmount__c = 70000
												);
		insert pay;
		
		PaymentDetail__c payment = new PaymentDetail__c(
												AccountAcountRef__c = accObj.id,
												PaymentInfoRef__c = pay.id
												);
		insert payment;
      	 // 当日のCSV情報を出力する
        Date startDate = Date.today();
        // スケジュール実施開始日
        String strProcessDate = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('yyyyMMdd');
        List<RsvAccount__c> rsvAccLst = [select id,Name from RsvAccount__c where Name = :strProcessDate limit 1];
        PcaSyncCsvTemplateCtrl ctrl1 = new PcaSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
        String csv = ctrl1.generalCsvContent();
    }
   
   static testMethod void addCase3 () {
        Test.startTest();
        // Init Xml Config
        getCsvSetupConfig1_1();
        // getCsvSetupConfig2();
        CommDefine__c comDef = [select Id, BillInputSwitchCode__c from CommDefine__c limit 1];
		comDef.BillInputSwitchCode__c = '2';
		// comDef.AccountSoftSyncCsvType__c = '2';
		update comDef;
		System.assertEquals([select Id from CommDefine__c].size(), 1);
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'SyncFieldConvertConfig'].size(), 1);
        // 2015/12/01 Assert END
        List<KanjoKamoku__c> kanjoMst =  createKankeKamoku();
        List<AccountMaster__c> paymentProdList = createMediaProductMst(kanjoMst);

        Contact guest = TestCommon.createContact();
        // 予約情報を作成する
        List<Lead__c> leadInfos = TestCommon.createLead(Date.today(), 1, 3, guest.Id);
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(4);
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfos[0], productLst[0]);
        TestCommon.createBookEstItem(leadInfos[1], productLst[0]);
		// TestCommon.createBookEstItem(leadInfos[2], productLst[0]);
        // 商品２は前受付金に変更を行う
        AccountMaster__c accMst = productLst[3];
        accMst.ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
        accMst.PaymentType__c = 'カード';  // XMLの定義と合わせるが必要です
        update accMst;

        TestCommon.createBookEstItem(leadInfos[0], accMst); // カード
		Test.stopTest();
        // 予約情報のステータス：チェックインに変更する
        leadInfos[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfos[0];
		
        // 会計画面に動作確認を行う
        //List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfos[0].Id];
        //AccountAcount__c accObj = accObjLst[0];
		
		// 会計画面に動作確認を行う
        RsvAccount__c rsv = TestCommon.createRsvAccount();
    	rsv = [select Salesday__c from RsvAccount__c where id = :rsv.id];
    	AccountAcount__c aa = TestCommon.createAccountAcount(rsv.Id, leadInfos[0].Id);
        List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfos[0].Id];
        AccountAcount__c accObj = accObjLst[0];
		TTend__c ttitem = TestCommon.createTTend(rsv.id,accObj.id);  
	    ttitem.field2__c = CommConst.MEDIA_TYPE_CD_02; 
	    ttitem.field3__c = '33'; 
	    ttitem.RowNo__c  = 44;  // メディア種別,メディア名称
	    ttitem.Field16__c = '55';
	    ttitem.Field17__c = '66';
	    ttitem.Field19__c = '67';
	    ttitem.Field20__c = '77';// 単価,枚数,支払金額 
	    ttitem.PaymentType__c = '99';
	    ttitem.PayProductName__c = '111';
	    ttitem.CardTypeLst__c = 'American Express';
	    ttitem.UseDate__c = Date.today();
	    update ttitem;
		
		DateTime startDates = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
	    LeadIndex__c item = new LeadIndex__c(
    		ID__c = String.valueOf('101731864'),
    		Nights__c = 1,
     		EntryTime__c = '10:00',
    		EntryDate__c = startDates.date(),
    		DepartureTime__c = '15:30',
    		DepartureDate__c = startDates.addDays(1).date(),
			EventSource__c = 'FromTravelAgency',
			APPNAME__c = 'TL',
			Rooms__c = 1
    	);
    	insert item;
    	
    	List<Tran1__c> tranLst = [select id,PaymentType__c from Tran1__c where Field7__c = :productLst[0].Id];
    	Tran1__c  tran1 = tranLst[0];
    	tran1.PaymentType__c = 'カード';
		PaymentInfo__c pay = new PaymentInfo__c(
												AccountAcountRef__c = accObj.id,
												TTendRef__c = ttitem.id,
												Tran1Ref__c = tran1.id,
												LeadIndexRef__c = item.id,
												PaymentType__c = '予約金',
												MediaTypeCode__c = CommConst.MEDIA_TYPE_CD_02,
												DepositAmount__c = 70000
												);
		insert pay;
		
		PaymentDetail__c payment = new PaymentDetail__c(
												AccountAcountRef__c = accObj.id,
												PaymentInfoRef__c = pay.id
												);
		insert payment;
      	 // 当日のCSV情報を出力する
        Date startDate = Date.today();
        // スケジュール実施開始日
        String strProcessDate = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('yyyyMMdd');
        List<RsvAccount__c> rsvAccLst = [select id,Name from RsvAccount__c where Name = :strProcessDate limit 1];
        PcaSyncCsvTemplateCtrl ctrl1 = new PcaSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
        String csv = ctrl1.generalCsvContent();
    }
    static testMethod void addCase4 () {
        Test.startTest();
        // Init Xml Config
        getCsvSetupConfig1();
        // getCsvSetupConfig2();
        CommDefine__c comDef = [select Id, BillInputSwitchCode__c from CommDefine__c limit 1];
		comDef.BillInputSwitchCode__c = '2';
		// comDef.AccountSoftSyncCsvType__c = '2';
		update comDef;
		System.assertEquals([select Id from CommDefine__c].size(), 1);
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'SyncFieldConvertConfig'].size(), 1);
        // 2015/12/01 Assert END
        List<KanjoKamoku__c> kanjoMst =  createKankeKamoku();
        List<AccountMaster__c> paymentProdList = createMediaProductMst(kanjoMst);

        Contact guest = TestCommon.createContact();
        // 予約情報を作成する
        List<Lead__c> leadInfos = TestCommon.createLead(Date.today(), 1, 3, guest.Id);
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(4);
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfos[0], productLst[0]);
        TestCommon.createBookEstItem(leadInfos[1], productLst[0]);
		// TestCommon.createBookEstItem(leadInfos[2], productLst[0]);
        // 商品２は前受付金に変更を行う
        AccountMaster__c accMst = productLst[3];
        accMst.ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
        accMst.PaymentType__c = 'カード';  // XMLの定義と合わせるが必要です
        update accMst;

        TestCommon.createBookEstItem(leadInfos[0], accMst); // カード
		Test.stopTest();
        // 予約情報のステータス：チェックインに変更する
        leadInfos[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfos[0];
		
        // 会計画面に動作確認を行う
        //List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfos[0].Id];
        //AccountAcount__c accObj = accObjLst[0];
		
		// 会計画面に動作確認を行う
        RsvAccount__c rsv = TestCommon.createRsvAccount();
    	rsv = [select Salesday__c from RsvAccount__c where id = :rsv.id];
    	AccountAcount__c aa = TestCommon.createAccountAcount(rsv.Id, leadInfos[0].Id);
        List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c,CouponReturnFlg__c from AccountAcount__c where Relreserve__c = :leadInfos[0].Id];
        AccountAcount__c accObj = accObjLst[0];
	accObj.CouponReturnFlg__c = true;
		TTend__c ttitem = TestCommon.createTTend(rsv.id,accObj.id);  
	    ttitem.Field1__c = accObj.id ;
	    ttitem.field2__c = '11'; 
	    ttitem.field3__c = '33'; 
	    ttitem.RowNo__c  = 44;  // メディア種別,メディア名称
	    ttitem.Field16__c = '55';
	    ttitem.Field17__c = '66';
	    ttitem.Field19__c = '67';
	    ttitem.Field20__c = '77';// 単価,枚数,支払金額 
	    ttitem.SplitGroupNo__c = '88';	    
	    ttitem.PaymentType__c = '99';
	    ttitem.PayProductName__c = '111';
	    ttitem.CardTypeLst__c = 'American Express';
	    ttitem.CouponTypeLst__c = '楽天クーポン';
	    ttitem.UseDate__c = Date.today();
	    update ttitem;
		
		DateTime startDates = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
	    LeadIndex__c item = new LeadIndex__c(
    		ID__c = String.valueOf('101731864'),
    		Nights__c = 1,
     		EntryTime__c = '10:00',
    		EntryDate__c = startDates.date(),
    		DepartureTime__c = '15:30',
    		DepartureDate__c = startDates.addDays(1).date(),
			EventSource__c = 'FromTravelAgency',
			APPNAME__c = 'TL',
			Rooms__c = 1
    	);
    	insert item;
    	
    	List<Tran1__c> tranLst = [select id,PaymentType__c from Tran1__c where Field7__c = :productLst[0].Id];
    	Tran1__c  tran1 = tranLst[0];
    	tran1.PaymentType__c = 'カード';
		PaymentInfo__c pay = new PaymentInfo__c(
												AccountAcountRef__c = accObj.id,
												TTendRef__c = ttitem.id,
												Tran1Ref__c = tran1.id,
												LeadIndexRef__c = item.id,
												PaymentType__c = '返金',
												MediaTypeCode__c = CommConst.MEDIA_TYPE_CD_11,
												DepositAmount__c = 70000
												);
		insert pay;
		
		PaymentDetail__c payment = new PaymentDetail__c(
												AccountAcountRef__c = accObj.id,
												PaymentInfoRef__c = pay.id
												);
		insert payment;
      	 // 当日のCSV情報を出力する
        Date startDate = Date.today();
        // スケジュール実施開始日
        String strProcessDate = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('yyyyMMdd');
        List<RsvAccount__c> rsvAccLst = [select id,Name from RsvAccount__c where Name = :strProcessDate limit 1];
        PcaSyncCsvTemplateCtrl ctrl1 = new PcaSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
        String csv = ctrl1.generalCsvContent();
    }

	static testMethod void addCase5 () {
        Test.startTest();
        // Init Xml Config
        getCsvSetupConfig1();
        // getCsvSetupConfig2();
        CommDefine__c comDef = [select Id, BillInputSwitchCode__c from CommDefine__c limit 1];
		comDef.BillInputSwitchCode__c = '2';
		// comDef.AccountSoftSyncCsvType__c = '2';
		update comDef;
		System.assertEquals([select Id from CommDefine__c].size(), 1);
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'SyncFieldConvertConfig'].size(), 1);
        // 2015/12/01 Assert END
        List<KanjoKamoku__c> kanjoMst =  createKankeKamoku();
        kanjoMst[0].BalanceKbn__c = '借方';
        kanjoMst[1].BalanceKbn__c = '借方';
        kanjoMst[4].BalanceKbn__c = '借方';
        update kanjoMst;
        List<AccountMaster__c> paymentProdList = createMediaProductMst(kanjoMst);

        Contact guest = TestCommon.createContact();
        // 予約情報を作成する
        List<Lead__c> leadInfos = TestCommon.createLead(Date.today(), 1, 1, guest.Id);
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(4);
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfos[0], productLst[2]);
        //TestCommon.createBookEstItem(leadInfos[1], productLst[2]);
		// TestCommon.createBookEstItem(leadInfos[2], productLst[0]);
        // 商品２は前受付金に変更を行う
        AccountMaster__c accMst = productLst[2];
        accMst.ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
        accMst.PaymentType__c = 'カード';  // XMLの定義と合わせるが必要です
        
        update accMst;

        TestCommon.createBookEstItem(leadInfos[0], accMst); // カード
		Test.stopTest();
        // 予約情報のステータス：チェックインに変更する
        leadInfos[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfos[0];
		
        // 会計画面に動作確認を行う
        //List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfos[0].Id];
        //AccountAcount__c accObj = accObjLst[0];
		
		// 会計画面に動作確認を行う
        RsvAccount__c rsv = TestCommon.createRsvAccount();
    	rsv = [select Salesday__c from RsvAccount__c where id = :rsv.id];
    	AccountAcount__c aa = TestCommon.createAccountAcount(rsv.Id, leadInfos[0].Id);
        List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfos[0].Id];
        AccountAcount__c accObj = accObjLst[0];
		TTend__c ttitem = TestCommon.createTTend(rsv.id,accObj.id);  
	    ttitem.field2__c = CommConst.MEDIA_TYPE_CD_03; 
	    ttitem.field3__c = '33'; 
	    ttitem.RowNo__c  = 44;  // メディア種別,メディア名称
	    ttitem.Field16__c = '55';
	    ttitem.Field17__c = '66';
	    ttitem.Field19__c = '67';
	    ttitem.Field20__c = '77';// 単価,枚数,支払金額 
	    ttitem.PaymentType__c = '99';
	    ttitem.PayProductName__c = '111';
	    ttitem.CardTypeLst__c = 'American Express';
	    ttitem.UseDate__c = Date.today();
	    update ttitem;
		
		DateTime startDates = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
	    LeadIndex__c item = new LeadIndex__c(
    		ID__c = String.valueOf('101731864'),
    		Nights__c = 1,
     		EntryTime__c = '10:00',
    		EntryDate__c = startDates.date(),
    		DepartureTime__c = '15:30',
    		DepartureDate__c = startDates.addDays(1).date(),
			EventSource__c = 'FromTravelAgency',
			APPNAME__c = 'TL',
			Rooms__c = 1
    	);
    	insert item;
    	List<Tran1__c> tranLst = [select id,PaymentType__c from Tran1__c where Field7__c = :productLst[2].Id];
    	Tran1__c  tran1 = tranLst[0];
    	tran1.PaymentType__c = 'カード';
		PaymentInfo__c pay = new PaymentInfo__c(
												AccountAcountRef__c = accObj.id,
												TTendRef__c = ttitem.id,
												Tran1Ref__c = tran1.id,
												LeadIndexRef__c = item.id,
												PaymentType__c = '予約金',
												MediaTypeCode__c = CommConst.MEDIA_TYPE_CD_03,
												DepositAmount__c = 70000
												);
		insert pay;
		
		PaymentDetail__c payment = new PaymentDetail__c(
												AccountAcountRef__c = accObj.id,
												PaymentInfoRef__c = pay.id
												);
		insert payment;
      	 // 当日のCSV情報を出力する
        Date startDate = Date.today();
        // スケジュール実施開始日
        String strProcessDate = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('yyyyMMdd');
        List<RsvAccount__c> rsvAccLst = [select id,Name from RsvAccount__c where Name = :strProcessDate limit 1];
        PcaSyncCsvTemplateCtrl ctrl1 = new PcaSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
        String csv = ctrl1.generalCsvContent();
    }
	static testMethod void addCase6 () {
        Test.startTest();
        // Init Xml Config
        getCsvSetupConfig1_1();
        // getCsvSetupConfig2();
        CommDefine__c comDef = [select Id, BillInputSwitchCode__c from CommDefine__c limit 1];
		comDef.BillInputSwitchCode__c = '2';
		// comDef.AccountSoftSyncCsvType__c = '2';
		update comDef;
		System.assertEquals([select Id from CommDefine__c].size(), 1);
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'SyncFieldConvertConfig'].size(), 1);
        // 2015/12/01 Assert END
        List<KanjoKamoku__c> kanjoMst =  createKankeKamoku();
        List<AccountMaster__c> paymentProdList = createMediaProductMst(kanjoMst);

        Contact guest = TestCommon.createContact();
        // 予約情報を作成する
        List<Lead__c> leadInfos = TestCommon.createLead(Date.today(), 1, 1, guest.Id);
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(4);
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfos[0], productLst[2]);
        //TestCommon.createBookEstItem(leadInfos[1], productLst[0]);
		// TestCommon.createBookEstItem(leadInfos[2], productLst[0]);
        // 商品２は前受付金に変更を行う
        AccountMaster__c accMst = productLst[2];
        accMst.ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
        accMst.PaymentType__c = 'カード';  // XMLの定義と合わせるが必要です
        update accMst;

        TestCommon.createBookEstItem(leadInfos[0], accMst); // カード
		Test.stopTest();
        // 予約情報のステータス：チェックインに変更する
        leadInfos[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfos[0];
		
        // 会計画面に動作確認を行う
        //List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfos[0].Id];
        //AccountAcount__c accObj = accObjLst[0];
		
		// 会計画面に動作確認を行う
        RsvAccount__c rsv = TestCommon.createRsvAccount();
    	rsv = [select Salesday__c from RsvAccount__c where id = :rsv.id];
    	AccountAcount__c aa = TestCommon.createAccountAcount(rsv.Id, leadInfos[0].Id);
        List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfos[0].Id];
        AccountAcount__c accObj = accObjLst[0];
		TTend__c ttitem = TestCommon.createTTend(rsv.id,accObj.id);  
	    ttitem.field2__c = CommConst.MEDIA_TYPE_CD_02; 
	    ttitem.field3__c = '33'; 
	    ttitem.RowNo__c  = 44;  // メディア種別,メディア名称
	    ttitem.Field16__c = '55';
	    ttitem.Field17__c = '66';
	    ttitem.Field19__c = '67';
	    ttitem.Field20__c = '77';// 単価,枚数,支払金額 
	    ttitem.Field21__c = '1';
	    ttitem.PaymentType__c = '99';
	    ttitem.PayProductName__c = '111';
	    ttitem.CardTypeLst__c = 'American Express';
	    ttitem.UseDate__c = Date.today();
	    update ttitem;
		
		DateTime startDates = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
	    LeadIndex__c item = new LeadIndex__c(
    		ID__c = String.valueOf('101731864'),
    		Nights__c = 1,
     		EntryTime__c = '10:00',
    		EntryDate__c = startDates.date(),
    		DepartureTime__c = '15:30',
    		DepartureDate__c = startDates.addDays(1).date(),
			EventSource__c = 'FromTravelAgency',
			APPNAME__c = 'TL',
			Rooms__c = 1
    	);
    	insert item;
    	
    	List<Tran1__c> tranLst = [select id,PaymentType__c from Tran1__c where Field7__c = :productLst[2].Id];
    	Tran1__c  tran1 = tranLst[0];
    	tran1.PaymentType__c = '予約金';
    	update tran1;
		PaymentInfo__c pay1 = new PaymentInfo__c(
												AccountAcountRef__c = accObj.id,
												TTendRef__c = null,
												Tran1Ref__c = tran1.id,
												LeadIndexRef__c = item.id,
												PaymentType__c = '予約金',
												MediaTypeCode__c = CommConst.MEDIA_TYPE_CD_02,
												DepositAmount__c = 70000
												);
		PaymentInfo__c pay2 = new PaymentInfo__c(
												AccountAcountRef__c = accObj.id,
												TTendRef__c = ttitem.id,
												Tran1Ref__c = tran1.id,
												LeadIndexRef__c = item.id,
												PaymentType__c = '予約金',
												MediaTypeCode__c = CommConst.MEDIA_TYPE_CD_02,
												DepositAmount__c = 70000
												);
		List<PaymentInfo__c> pay = new List<PaymentInfo__c>();
        pay.add(pay1);
        pay.add(pay2);
        insert pay;
		PaymentDetail__c payment1 = new PaymentDetail__c(
												AccountAcountRef__c = accObj.id,
												PaymentInfoRef__c = pay1.id
												);
		PaymentDetail__c payment2 = new PaymentDetail__c(
												AccountAcountRef__c = accObj.id,
												PaymentInfoRef__c = pay2.id
												);
		List<PaymentDetail__c> payment = new List<PaymentDetail__c>();
        payment.add(payment1);
        payment.add(payment2);
		insert payment;
      	 // 当日のCSV情報を出力する
        Date startDate = Date.today();
        // スケジュール実施開始日
        String strProcessDate = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('yyyyMMdd');
        List<RsvAccount__c> rsvAccLst = [select id,Name from RsvAccount__c where Name = :strProcessDate limit 1];
        PcaSyncCsvTemplateCtrl ctrl1 = new PcaSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
        String csv = ctrl1.generalCsvContent();
    }
    
    private static void getCsvSetupConfig1() {
    	CommDefine__c def = TestCommon.createCommDefine();
    	def.SchedulePcaCsvHeaderIsShowFlg__c = true;
    	update def;
        String xml = 
        '<?xml version="1.0" encoding="UTF-8"?>'+
        '<root>'+
        '<SHOP>'+
        '<SHOPCODE></SHOPCODE>'+
        '<PCA>'+
        '<TAX_KBN>1</TAX_KBN>' + 
        '<PCA_FIELD>'+
        '<VER>#2</VER>'+
        '<STARTNO>6001</STARTNO>'+
        '<CALCULATIONKBN>0</CALCULATIONKBN>'+
        '<JOURNALKBN>1</JOURNALKBN>'+
        '<MANAGEACCJOUKBN>0</MANAGEACCJOUKBN>'+
        '<DEBDEPARTCODE>180</DEBDEPARTCODE>'+
        '<DEBCONSUMPTAX>0</DEBCONSUMPTAX>'+
        '<CREDEPARTCODE>180</CREDEPARTCODE>'+
        '<CRECONSUMPTAX>0</CRECONSUMPTAX>'+
        '<INPUTPROGRAMKBN>HANYOU</INPUTPROGRAMKBN>'+
        '</PCA_FIELD>'+
        '<PCA_TAX>'+
        '<KANJOCODE>3350</KANJOCODE>'+
        '</PCA_TAX>'+
        '<PCA_ADVPAY_L>'+
        '<KANJOCODE>3241003</KANJOCODE>'+
        '</PCA_ADVPAY_L> '+
        '<PCA_ADVPAY_R>'+
        '<KANJOCODE>3241003</KANJOCODE>'+
        '</PCA_ADVPAY_R> '+
        '<SPECIALTAX_OUTPUT>TRUE</SPECIALTAX_OUTPUT>'+
        '<PCA_SPECIALTAX_R>'+
        '<KANJOCODE>1118</KANJOCODE>'+
        '</PCA_SPECIALTAX_R>'+
        '</PCA>'+
        '<CASH>'+
        '<CASH_INPUT>'+
        '<CONVERT>'+
        '<KEMOKU>内金</KEMOKU>'+
        '<I_KANJOCODE>1110</I_KANJOCODE>'+
        '<O_KANJOCODE>3241003</O_KANJOCODE>'+
        '</CONVERT>'+
        '</CASH_INPUT>'+
        '<CASH_OUTPUT>'+
        '<CONVERT>'+
        '<KEMOKU>交通費</KEMOKU>'+
        '<I_KANJOCODE>1841</I_KANJOCODE>'+
        '<O_KANJOCODE>1110</O_KANJOCODE>'+
        '</CONVERT>'+
        '</CASH_OUTPUT>'+
        '</CASH>'+
        '</SHOP>'+
        '</root>';
        Document doc = new Document();
        doc.Name = 'SyncFieldConvertConfig';
        doc.DeveloperName = doc.Name;
        doc.FolderId = UserInfo.getUserId();
        doc.Body = Blob.valueOf(xml);
        insert doc;
        
    }
     private static void getCsvSetupConfig1_1() {
    	CommDefine__c def = TestCommon.createCommDefine();
    	def.SchedulePcaCsvHeaderIsShowFlg__c = true;
    	update def;
        String xml = 
        '<?xml version="1.0" encoding="UTF-8"?>'+
        '<root>'+
        '<SHOP>'+
        '<SHOPCODE></SHOPCODE>'+
        '<PCA>'+
        '<TAX_KBN>2</TAX_KBN>' + 
        '<PCA_FIELD>'+
        '<VER>#2</VER>'+
        '<STARTNO>6001</STARTNO>'+
        '<CALCULATIONKBN>0</CALCULATIONKBN>'+
        '<JOURNALKBN>2</JOURNALKBN>'+
        '<MANAGEACCJOUKBN>0</MANAGEACCJOUKBN>'+
        '<DEBDEPARTCODE>180</DEBDEPARTCODE>'+
        '<DEBCONSUMPTAX>0</DEBCONSUMPTAX>'+
        '<CREDEPARTCODE>180</CREDEPARTCODE>'+
        '<CRECONSUMPTAX>0</CRECONSUMPTAX>'+
        '<INPUTPROGRAMKBN>HANYOU</INPUTPROGRAMKBN>'+
        '</PCA_FIELD>'+
        '<PCA_TAX>'+
        '<KANJOCODE>3350</KANJOCODE>'+
        '</PCA_TAX>'+
        '<PCA_ADVPAY_L>'+
        '<KANJOCODE>3241003</KANJOCODE>'+
        '</PCA_ADVPAY_L> '+
        '<PCA_ADVPAY_R>'+
        '<KANJOCODE>3241003</KANJOCODE>'+
        '</PCA_ADVPAY_R> '+
        '<PCA_REFUND_R>'+
        '<KANJOCODE>3241002</KANJOCODE>'+
        '</PCA_REFUND_R> '+
        '<SPECIALTAX_OUTPUT>TRUE</SPECIALTAX_OUTPUT>'+
        '<PCA_SPECIALTAX_R>'+
        '<KANJOCODE>1118</KANJOCODE>'+
        '</PCA_SPECIALTAX_R>'+
        '</PCA>'+
        '<CASH>'+
        '<CASH_INPUT>'+
        '<CONVERT>'+
        '<KEMOKU>予約金</KEMOKU>'+
        '<I_KANJOCODE>3261</I_KANJOCODE>'+
        '<O_KANJOCODE>3241002</O_KANJOCODE>'+
        '</CONVERT>'+
        '</CASH_INPUT>'+
        '<CASH_OUTPUT>'+
        '<CONVERT>'+
        '<KEMOKU>交通費</KEMOKU>'+
        '<I_KANJOCODE>1841</I_KANJOCODE>'+
        '<O_KANJOCODE>1110</O_KANJOCODE>'+
        '</CONVERT>'+
        '</CASH_OUTPUT>'+
        '</CASH>'+
        '<MEDIA>'+
        '<CARD>'+
        '<CONVERT>'+
        '<CARDNAME>VISA</CARDNAME>'+
        '<KANJOCODE>1841008</KANJOCODE>'+
        '</CONVERT>'+
        '</CARD>'+
        '<KINKEN>'+
        '<CONVERT>'+
        '<KINKENNAME>楽天ポイント</KINKENNAME>'+
        '<KANJOCODE>5210011</KANJOCODE>'+
        '</CONVERT>'+
        '</KINKEN>'+
        '</MEDIA>'+
        '</SHOP>'+
        '</root>';
        Document doc = new Document();
        doc.Name = 'SyncFieldConvertConfig';
        doc.DeveloperName = doc.Name;
        doc.FolderId = UserInfo.getUserId();
        doc.Body = Blob.valueOf(xml);
        insert doc;
        
    }
    private static void getCsvSetupConfig2() {
        String csv = '<?xml version="1.0" encoding="UTF-8"?>'
                                +'<root><SHOP><SHOPCODE></SHOPCODE><PAYMENT><CONVERT><PAYTYPE>現金</PAYTYPE><MEIDALAB>預り／現計</MEIDALAB></CONVERT><CONVERT><PAYTYPE>カード</PAYTYPE><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB></CONVERT><CONVERT><PAYTYPE>売掛金</PAYTYPE><MEIDALAB>掛計</MEIDALAB></CONVERT><CONVERT><PAYTYPE>クーポン</PAYTYPE><MEIDALAB>クーポン</MEIDALAB></CONVERT><CONVERT><PAYTYPE>値引</PAYTYPE><MEIDALAB>値引・割引券</MEIDALAB></CONVERT><CONVERT><PAYTYPE>予約金</PAYTYPE><MEIDALAB>予約金</MEIDALAB></CONVERT>'
                                +
                                '</PAYMENT><PAYMEIDA>'
                                    +'<CONVERT><MEIDALAB>預り／現計</MEIDALAB><PRODCODE>T90001</PRODCODE></CONVERT>'
                                    +'<CONVERT><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB><PRODCODE>T90002</PRODCODE></CONVERT>'
                                    +'<CONVERT><MEIDALAB>掛計</MEIDALAB><PRODCODE>T90003</PRODCODE></CONVERT>'
                                    +'<CONVERT><MEIDALAB>クーポン</MEIDALAB><PRODCODE>T90004</PRODCODE></CONVERT>'
                                    +'<CONVERT><MEIDALAB>値引・割引券</MEIDALAB><PRODCODE>T90005</PRODCODE></CONVERT>'
                                    +'<CONVERT><MEIDALAB>予約金</MEIDALAB><PRODCODE>T90006</PRODCODE></CONVERT>'
                                    +'</PAYMEIDA></SHOP></root>';
        
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
        TestCommon.createOrderConfigXml();
        TestCommon.createConfigSimple();
    }
}