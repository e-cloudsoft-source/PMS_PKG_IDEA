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
private class FreeeSyncCsvTemplateCtrlTest {
    @testsetup
    static void dataSetup(){
        getCsvSetupConfig2();
    }
    // 入金、出金関連の関連のテスト作成を行う
    static testMethod void Case1 () {
        getCsvSetupConfig1();
        //getCsvSetupConfig2();
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
        FreeeSyncCsvTemplateCtrl ctrl = new FreeeSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
        String csv = ctrl.generalCsvContent();
        String[] csvRs = csv.split('\n');
        System.assertEquals(csvRs.size(), 3, csvRs);
        System.assert(csvRs[1].indexOf('内金摘要テスト') > 0, csv);
        System.assert(csvRs[1].indexOf('50000') > 0, csv);
        System.assert(csvRs[2].indexOf('交通費摘要テスト') > 0, csv);
        System.assert(csvRs[2].indexOf('28300') > 0, csv);
        String csvRollup = ctrl.generalRollupCsvContent();
        Test.stopTest();
    }
    
    // 簡易会計から作成する会計のCSV抽出
    static testMethod void Case2 () {

        getCsvSetupConfig1();
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
        simCtrl.otran.Field7__c = prodList[0].Id;
        simCtrl.otran.ActionType__c = prodList[0].ActionType__c;
        simCtrl.otran.TaxRate__c = prodList[0].TaxRateCal__c;
        simCtrl.otran.ServiceRate__c = prodList[0].ServiceRate__c;
        simCtrl.otran.SpecialTax__c = 200;
        simCtrl.productNm = prodList[0].Name;
        simCtrl.saveTranToMemory();
        simCtrl.upsertData();
        Test.startTest();


        
        // 当日のCSV情報を出力する
        Date startDate = Date.today();
        // スケジュール実施開始日
        String strProcessDate = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('yyyyMMdd');
        List<RsvAccount__c> rsvAccLst = [select id,Name from RsvAccount__c where Name = :strProcessDate limit 1];
        FreeeSyncCsvTemplateCtrl ctrl = new FreeeSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
        String csv = ctrl.generalCsvContent();
        String[] csvRs = csv.split('\n');
        //System.assertEquals(csvRs.size(), 3, csvRs);
        System.assert(csvRs[1].indexOf('1110') > 0, csv);
        System.assert(csvRs[1].indexOf('11100001') > 0, csv);
        System.assert(csvRs[1].indexOf('5110') > 0, csv);
        System.assert(csvRs[1].indexOf('51100001') > 0, csv);
        System.assert(csvRs[1].indexOf('32000') > 0, csv);  
        System.assert(csvRs[1].indexOf('32000.00') < 0, csv);  
        String csvRollup = ctrl.generalRollupCsvContent();
        Test.stopTest();
        // 2019/12/30 FREEEAPI连携機能 WGCH BEGIN
        freeeSchedult(rsvAccLst[0].Id, '');
        freeebatch('', CommUtils.stringToDate(rsvAccLst[0].Name), CommUtils.stringToDate(rsvAccLst[0].Name));
        // 2019/12/30 FREEEAPI连携機能 WGCH END
    }
    /*
    // 連泊情報作成、連泊情報の自動チェックイン後、PCA連携情報の確認
    static testMethod void Case3 () {
        
        Test.startTest();
        // Init Xml Config
        getCsvSetupConfig1();
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
        accMst.PaymentType__c = 'カード';  // XMLの定義と合わせるが必要です
        update accMst;

        TestCommon.createBookEstItem(leadInfos[0], accMst); // カード
        Test.stopTest();
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
        FreeeSyncCsvTemplateCtrl ctrl1 = new FreeeSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
        String csv = ctrl1.generalCsvContent();
        String csvRollup = ctrl1.generalRollupCsvContent();
        /*
        leadInfos[1].Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfos[1];
        startDate = Date.today().addDays(1);
        // スケジュール実施開始日
        strProcessDate = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('yyyyMMdd');
        rsvAccLst = [select id,Name from RsvAccount__c where Name = :strProcessDate limit 1];
        ctrl1 = new FreeeSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
        csv = ctrl1.generalCsvContent();
        */
        /*
        leadInfos[2].Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfos[2];
        startDate = Date.today().addDays(2);
        // スケジュール実施開始日
        strProcessDate = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('yyyyMMdd');
        rsvAccLst = [select id,Name from RsvAccount__c where Name = :strProcessDate limit 1];
        ctrl1 = new FreeeSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
        csv = ctrl1.generalCsvContent();
       
    }*/
    // 新会計メニューの場合、PCA連携情報を行う
    static testMethod void Case4 () {
        CommDefine__c comDef = TestCommon.createCommDefine();
        comDef.BillInputSwitchCode__c = '2';
        comDef.AccountSoftSyncCsvType__c = '2';
        update comDef;
        // Init Xml Config
        getCsvSetupConfig1();
        //getCsvSetupConfig2();
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
        accMst.PaymentType__c = 'カード';  // XMLの定義と合わせるが必要です
        update accMst;
        
        TestCommon.createBookEstItem(leadInfos[0], accMst); // カード

        
        // 予約情報のステータス：チェックインに変更する
        leadInfos[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
 Test.startTest(); 
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
        FreeeSyncCsvTemplateCtrl ctrl1 = new FreeeSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
Test.stopTest();         
        String csv = ctrl1.generalCsvContent();

        String csvRollup = ctrl1.generalRollupCsvContent();
         /*
        leadInfos[1].Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfos[1];
        startDate = Date.today().addDays(1);
        // スケジュール実施開始日
        strProcessDate = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('yyyyMMdd');
        rsvAccLst = [select id,Name from RsvAccount__c where Name = :strProcessDate limit 1];
        ctrl1 = new FreeeSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
        csv = ctrl1.generalCsvContent();
        /*
        leadInfos[2].Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfos[2];
        startDate = Date.today().addDays(2);
        // スケジュール実施開始日
        strProcessDate = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('yyyyMMdd');
        rsvAccLst = [select id,Name from RsvAccount__c where Name = :strProcessDate limit 1];
        ctrl1 = new FreeeSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
        csv = ctrl1.generalCsvContent();
        */
        // 2019/12/30 FREEEAPI连携機能 WGCH BEGIN
        freeeSchedult(rsvAccLst[0].Id, '');
        freeebatch('', CommUtils.stringToDate(rsvAccLst[0].Name), CommUtils.stringToDate(rsvAccLst[0].Name));
        // 2019/12/30 FREEEAPI连携機能 WGCH END
    }
    /*
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
    */
     // 連泊情報作成、連泊情報の自動チェックイン後、PCA連携情報の確認
    static testMethod void Case6 () {
        
        Test.startTest();
        TestCommon.createRollParameter();
        // Init Xml Config
        getCsvSetupConfig3();
        // getCsvSetupConfig2();
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
        rsv = [select Salesday__c,Name from RsvAccount__c where id = :rsv.id];
        AccountAcount__c aa = TestCommon.createAccountAcount(rsv.Id, leadInfos[0].Id);
        List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfos[0].Id];
        AccountAcount__c accObj = accObjLst[0];
        accObj.CouponReturnFlg__c = true;
        TTend__c ttitem = TestCommon.createTTend(rsv.id,accObj.id);  
        ttitem.field1__c = accObj.id;
        ttitem.field2__c = CommConst.MEDIA_TYPE_CD_11; 
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
        ttitem.CouponTypeLst__c = '楽天クーポン';
        ttitem.PayProductRef__c = accMst.id; // 支払商品
        ttitem.UseDate__c = Date.today();
        update ttitem;

        ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
        BillSimpleInputCtrl ctrl = new BillSimpleInputCtrl(contrl);
        ctrl.initAction();

        ctrl.upsertData();
        ctrl.addTran1Item();//入力行目を増える
       /*
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
        */
        // 当日のCSV情報を出力する
        Date startDate = Date.today();
        // スケジュール実施開始日
        String strProcessDate = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('yyyyMMdd');
        List<RsvAccount__c> rsvAccLst = [select id,Name from RsvAccount__c where Name = :strProcessDate limit 1];
        FreeeSyncCsvTemplateCtrl ctrl1 = new FreeeSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
        String csv = ctrl1.generalCsvContent();
        String csvRollup = ctrl1.generalRollupCsvContent();
        // 2019/12/30 FREEEAPI连携機能 WGCH BEGIN
        freeeSchedult(rsvAccLst[0].Id, '');
        freeebatch('', CommUtils.stringToDate(rsv.Name), CommUtils.stringToDate(rsv.Name));
        // 2019/12/30 FREEEAPI连携機能 WGCH END
    }
    static testMethod void Case7 () {
        Test.startTest();
        // Init Xml Config
        getCsvSetupConfig4();
        // getCsvSetupConfig2();
        TestCommon.createTesuryoConfigDoc();
        CommDefine__c comDef = [select Id, BillInputSwitchCode__c from CommDefine__c limit 1];
        comDef.BillInputSwitchCode__c = '2';
        // comDef.AccountSoftSyncCsvType__c = '2';
        update comDef;
        //System.assertEquals([select Id from CommDefine__c].size(), 1);
        // 2015/12/01 Assert BEGIN
        //System.assertEquals([select Id from Document where Name = 'SyncFieldConvertConfig'].size(), 1);
        // 2015/12/01 Assert END
        List<KanjoKamoku__c> kanjoMst =  createKankeKamoku();
        List<AccountMaster__c> paymentProdList = createMediaProductMst(kanjoMst);
        Contact guest = TestCommon.createContact();
        // 予約情報を作成する
        List<Lead__c> leadInfos = TestCommon.createLead(Date.today(), 1, 1, guest.Id);
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(4);
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfos[0], productLst[0]);
        //TestCommon.createBookEstItem(leadInfos[1], productLst[0]);
        // TestCommon.createBookEstItem(leadInfos[2], productLst[0]);
        // 商品２は前受付金に変更を行う
        AccountMaster__c accMst = productLst[3];
        accMst.ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
        accMst.PaymentType__c = 'カード';  // XMLの定義と合わせるが必要です
        update accMst;
        //System.assertEquals([select Id from Document where Name = 'AccountingSyncBatchConfig'].size(), 1);
        // 2015/12/01 Assert END
        //連絡結果　予約取り込待ち
        TestCommon.createLeadImportAndWaitImpot();
        RsvAccount__c item = new RsvAccount__c();
        item.name = Date.today().format().replaceAll('/','').replaceAll('-','');
        //'20151113'
        insert item;
        ShopInformation__c shop = TestCommon.createShopInfo();
        String[] status = new String[]{'申請','処理済'};
        String[] kamokus = new String[]{'現金','買掛（月末振込）','買掛（都度振込）','事前振込','クレジットカード'};
        String[] purType = new String[]{'材料仕入','売店仕入','飲料仕入','室料経費','ブライダル仕入'};
        Account guests = TestCommon.createTravelCompany() ;
        guests.RoundType__c = '1';
        update guests;
        TestCommon.createchargeInfo(guests.id);
        // 口座情報の作成
        String shopAccLocalName = ShopAccountInfo__c.sObjectType.getDescribe().getName();
        List<RecordType> rts = [SELECT Id,Name FROM RecordType WHERE SobjectType  = :shopAccLocalName];
        String kouzaIds = TestCommon.createShopBankAccount(5,guests,rts,shop.id);
        
        List<Purchase__c> ps = new List<Purchase__c>();
        for(integer i = 0 ; i < 1 ; i++){
            Double status_idx = Math.random() * 1;
            Double kamoku_idx = Math.random() * 4;
            decimal incTax = Math.random() * 10000.9;
            Purchase__c p = new Purchase__c(
                                StatusLst__c = status[Integer.valueOf(status_idx)],
                                KamokuLst__c = '買掛（月末振込）',
                                DenpyoukeiIncTax__c = incTax * 1.08,
                                Denpyoukei__c  = incTax,
                                Purchasesource__c = guests.id,
                                JinyaRevenue__c = item.id,
                                PurchaseType__c = purType[Integer.valueOf(kamoku_idx)],
                                ShopInfoRef__c = shop.id
                            );
            ps.add(p);
        }
        insert ps;
        TestCommon.createBookEstItem(leadInfos[0], accMst); // カード
        
        // 予約情報のステータス：チェックインに変更する
        leadInfos[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfos[0];
Test.stopTest();    
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
        FreeeSyncCsvTemplateCtrl ctrl1 = new FreeeSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
        String csv = ctrl1.generalCsvContent();
        String csvRollup = ctrl1.generalRollupCsvContent();
        System.assert(!CommUtils.isBlank(csv));
    }
    static testMethod void Case8 () {
        Test.startTest();
        // Init Xml Config
        getCsvSetupConfig4();
        // getCsvSetupConfig2();
        TestCommon.createTesuryoConfigDoc();
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
        TestCommon.createBookEstItem(leadInfos[2], productLst[0]);
        // 商品２は前受付金に変更を行う
        AccountMaster__c accMst = productLst[1];
        accMst.ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
        accMst.PaymentType__c = 'カード';  // XMLの定義と合わせるが必要です
        update accMst;
        AccountMaster__c accMsts = productLst[2];
        accMsts.ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
        accMsts.PaymentType__c = 'カード';  // XMLの定義と合わせるが必要です
        accMst.Field5__c = 80000;
        update accMsts;
        AccountMaster__c accMstPay = productLst[3];
        accMstPay.ActionType__c = CommConst.PROD_ACTION_TYPE_PY;
        accMstPay.PaymentType__c = '現金';    // XMLの定義と合わせるが必要です
        accMst.Field5__c = 80000;
        update accMstPay;
        System.assertEquals([select Id from Document where Name = 'AccountingSyncBatchConfig'].size(), 1);
        // 2015/12/01 Assert END
        //連絡結果　予約取り込待ち
        TestCommon.createLeadImportAndWaitImpot();
        RsvAccount__c item = new RsvAccount__c();
        item.name = Date.today().format().replaceAll('/','').replaceAll('-','');
        //'20151113'
        insert item;
        ShopInformation__c shop = TestCommon.createShopInfo();
        String[] status = new String[]{'申請','処理済'};
        String[] kamokus = new String[]{'現金','買掛（月末振込）','買掛（都度振込）','事前振込','クレジットカード'};
        String[] purType = new String[]{'材料仕入','売店仕入','飲料仕入','室料経費','ブライダル仕入'};
        Account guests = TestCommon.createTravelCompany() ;
        guests.RoundType__c = '1';
        update guests;
        TestCommon.createchargeInfo(guests.id);
        // 口座情報の作成
        String shopAccLocalName = ShopAccountInfo__c.sObjectType.getDescribe().getName();
        List<RecordType> rts = [SELECT Id,Name FROM RecordType WHERE SobjectType  = :shopAccLocalName];
        String kouzaIds = TestCommon.createShopBankAccount(5,guests,rts,shop.id);
        
        List<Purchase__c> ps = new List<Purchase__c>();
        for(integer i = 0 ; i < 1 ; i++){
            Double status_idx = Math.random() * 1;
            Double kamoku_idx = Math.random() * 4;
            decimal incTax = Math.random() * 10000.9;
            Purchase__c p = new Purchase__c(
                                StatusLst__c = status[Integer.valueOf(status_idx)],
                                KamokuLst__c = '買掛（月末振込）',
                                DenpyoukeiIncTax__c = incTax * 1.08,
                                Denpyoukei__c  = incTax,
                                Purchasesource__c = guests.id,
                                JinyaRevenue__c = item.id,
                                PurchaseType__c = purType[Integer.valueOf(kamoku_idx)],
                                ShopInfoRef__c = shop.id
                            );
            ps.add(p);
        }
        insert ps;
        
        TestCommon.createBookEstItem(leadInfos[0], productLst[1]);
        TestCommon.createBookEstItem(leadInfos[0], accMsts);
        //TestCommon.createBookEstItem(leadInfos[1], accMsts);
        
        Test.stopTest();
        
        // 予約情報のステータス：チェックインに変更する
        leadInfos[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfos[0];        
        /* // 予約情報のステータス：チェックインに変更する
        leadInfos[1].Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfos[1];*/
        
        // 会計画面に動作確認を行う
        List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfos[0].Id];
        AccountAcount__c accObj = accObjLst[0];
        // 取引先作成
        Account acc = TestCommon.createNormalAccount();
        // カード支払商品を作成する
        List<AccountMaster__c> payAccs = TestCommon.createPayProductMst(new set<string>{Label.CONST_012_0439});
        AccountMaster__c payAcc = payAccs[0];
        // 該当商品の手数料と口座情報を作成する
        payAcc.CardAccountRef__c = acc.Id;
        update payAcc;
        ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
        BillSimpleInputCtrl ctrl = new BillSimpleInputCtrl(contrl);
        ctrl.initAction();
        ctrl.upsertData();
        ctrl.addTran1Item();//入力行目を増える
        // 商品３は会計明細に設定する
        List<BillSimpleInputCtrl.TranItem> rsTranItems = ctrl.oTranSobjLst;
        rsTranItems[2].productNm = productLst[2].Name;
        rsTranItems[2].sobj.Field7__c = productLst[2].Id;
        rsTranItems[2].tranId = '';
        rsTranItems[2].accRefId = '';
        rsTranItems[2].sobj.Field20__c = '3000';
        rsTranItems[2].sobj.Field21__c = '1';
        // 商品４は会計支払情報として、明細に設定する
        rsTranItems[3].productNm = productLst[3].Name;
        rsTranItems[3].sobj.Field7__c = productLst[3].Id;
        rsTranItems[3].tranId = '';
        rsTranItems[3].accRefId = '';
        rsTranItems[3].sobj.Field20__c = '5000';
        rsTranItems[3].sobj.Field21__c = '1';
        ctrl.upsertData();
        CommDefine__c def = TestCommon.createCommDefine();
        def.BillInputSwitchCode__c = '2';
        update def;
        
        // 当日のCSV情報を出力する
        Date startDate = Date.today();
        // スケジュール実施開始日
        String strProcessDate = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('yyyyMMdd');
        List<RsvAccount__c> rsvAccLst = [select id,Name from RsvAccount__c where Name = :strProcessDate limit 1];
        FreeeSyncCsvTemplateCtrl ctrl1 = new FreeeSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
        /*
        String csv = ctrl1.generalCsvContent();
        String csvRollup = ctrl1.generalRollupCsvContent();*/
    }
    static testMethod void Case9 () {
        Test.startTest();
        // Init Xml Config
        getCsvSetupConfig4();
        //getCsvSetupConfig2();
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
        TestCommon.createBookEstItem(leadInfos[2], productLst[0]);
        // 取引先作成
        Account acc = TestCommon.createNormalAccount();
        // 取引先関連の手数料定義作成
        list<ChargeInfo__c> chrLst1 = createTesuryo(acc);
        list<ChargeInfo__c> chrLst2 = createTesuryo(acc);
        createConfigDoc(chrLst2[0].Name);
        // 商品２は前受付金に変更を行う
        AccountMaster__c accMst = productLst[1];
        accMst.ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
        accMst.PaymentType__c = 'カード';  // XMLの定義と合わせるが必要です
        accMst.CardAccountRef__c = acc.id;
        update accMst;
        AccountMaster__c accMsts = productLst[2];
        accMsts.ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
        accMsts.PaymentType__c = 'カード';  // XMLの定義と合わせるが必要です
        accMst.CardAccountRef__c = acc.id;
        accMst.Field5__c = 80000;
        update accMsts;
        AccountMaster__c accMstPay = productLst[3];
        accMstPay.ActionType__c = CommConst.PROD_ACTION_TYPE_PY;
        accMstPay.PaymentType__c = '現金';    // XMLの定義と合わせるが必要です
        accMst.Field5__c = 80000;
        update accMstPay;
        System.assertEquals([select Id from Document where Name = 'AccountingSyncBatchConfig'].size(), 1);
        // 2015/12/01 Assert END
        //連絡結果　予約取り込待ち
        TestCommon.createLeadImportAndWaitImpot();
        RsvAccount__c item = new RsvAccount__c();
        item.name = Date.today().format().replaceAll('/','').replaceAll('-','');
        //'20151113'
        insert item;
        ShopInformation__c shop = TestCommon.createShopInfo();
        String[] status = new String[]{'申請','処理済'};
        String[] kamokus = new String[]{'現金','買掛（月末振込）','買掛（都度振込）','事前振込','クレジットカード'};
        String[] purType = new String[]{'材料仕入','売店仕入','飲料仕入','室料経費','ブライダル仕入'};
        Account guests = TestCommon.createTravelCompany() ;
        guests.RoundType__c = '1';
        update guests;
        TestCommon.createchargeInfo(guests.id);
        // 口座情報の作成
        String shopAccLocalName = ShopAccountInfo__c.sObjectType.getDescribe().getName();
        List<RecordType> rts = [SELECT Id,Name FROM RecordType WHERE SobjectType  = :shopAccLocalName];
        String kouzaIds = TestCommon.createShopBankAccount(5,guests,rts,shop.id);
        
        List<Purchase__c> ps = new List<Purchase__c>();
        for(integer i = 0 ; i < 1 ; i++){
            Double status_idx = Math.random() * 1;
            Double kamoku_idx = Math.random() * 4;
            decimal incTax = Math.random() * 10000.9;
            Purchase__c p = new Purchase__c(
                                StatusLst__c = status[Integer.valueOf(status_idx)],
                                KamokuLst__c = '買掛（月末振込）',
                                DenpyoukeiIncTax__c = incTax * 1.08,
                                Denpyoukei__c  = incTax,
                                Purchasesource__c = guests.id,
                                JinyaRevenue__c = item.id,
                                PurchaseType__c = purType[Integer.valueOf(kamoku_idx)],
                                ShopInfoRef__c = shop.id
                            );
            ps.add(p);
        }
        insert ps;
        
        TestCommon.createBookEstItem(leadInfos[0], productLst[1]);
        TestCommon.createBookEstItem(leadInfos[0], accMsts);
        //TestCommon.createBookEstItem(leadInfos[1], accMsts);
        
        Test.stopTest();
        
        // 予約情報のステータス：チェックインに変更する
        leadInfos[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfos[0];        
        /* // 予約情報のステータス：チェックインに変更する
        leadInfos[1].Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfos[1];*/
        
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
        rsTranItems[2].productNm = productLst[2].Name;
        rsTranItems[2].sobj.Field7__c = productLst[2].Id;
        rsTranItems[2].tranId = '';
        rsTranItems[2].accRefId = '';
        rsTranItems[2].sobj.Field20__c = '3000';
        rsTranItems[2].sobj.Field21__c = '1';
        // 商品４は会計支払情報として、明細に設定する
        rsTranItems[3].productNm = productLst[3].Name;
        rsTranItems[3].sobj.Field7__c = productLst[3].Id;
        rsTranItems[3].tranId = '';
        rsTranItems[3].accRefId = '';
        rsTranItems[3].sobj.Field20__c = '5000';
        rsTranItems[3].sobj.Field21__c = '1';
        ctrl.upsertData();
        CommDefine__c def = TestCommon.createCommDefine();
        def.BillInputSwitchCode__c = '2';
        update def;
        
        // 当日のCSV情報を出力する
        Date startDate = Date.today();
        // スケジュール実施開始日
        String strProcessDate = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('yyyyMMdd');
        List<RsvAccount__c> rsvAccLst = [select id,Name from RsvAccount__c where Name = :strProcessDate limit 1];
        FreeeSyncCsvTemplateCtrl ctrl1 = new FreeeSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
        /*
        String csv = ctrl1.generalCsvContent();
        String csvRollup = ctrl1.generalRollupCsvContent();*/
    }
    static testMethod void Case10 () {
        Test.startTest();
        // Init Xml Config
        getCsvSetupConfig4();
        // getCsvSetupConfig2();
        TestCommon.createTesuryoConfigDoc();
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
        // マージ元の取引先情報を作成する
        Account FrAccounts = TestCommon.createNormalAccount();
        // 下記の取引先の関連情報はマージ元(FrAccounts)にコピーする
        Account ToAccounts = FrAccounts.clone(false,true);
        insert ToAccounts;
        Id toAccountId = ToAccounts.Id;
        // 予約情報を作成する
        List<Lead__c> leadInfos = TestCommon.createLead(Date.today(), 1, 3, guest.Id);
        leadInfos[0].SalesOfficeInfoRef__c = toAccountId;
        update leadInfos[0];
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
        //accMst.CardAccountRef__c = toAccountId;
        update accMst;
        AccountMaster__c accMsts = productLst[2];
        accMsts.ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
        accMsts.PaymentType__c = 'カード';  // XMLの定義と合わせるが必要です
        //accMst.CardAccountRef__c = toAccountId;
        accMst.Field5__c = 80000;
        update accMsts;
        AccountMaster__c accMstPay = productLst[3];
        accMstPay.ActionType__c = CommConst.PROD_ACTION_TYPE_PY;
        accMstPay.PaymentType__c = '現金';    // XMLの定義と合わせるが必要です
        accMst.Field5__c = 80000;
        update accMstPay;
        System.assertEquals([select Id from Document where Name = 'AccountingSyncBatchConfig'].size(), 1);
        // 2015/12/01 Assert END
        //連絡結果　予約取り込待ち
        TestCommon.createLeadImportAndWaitImpot();
        RsvAccount__c item = new RsvAccount__c();
        item.name = Date.today().format().replaceAll('/','').replaceAll('-','');
        //'20151113'
        insert item;
        ShopInformation__c shop = TestCommon.createShopInfo();
        String[] status = new String[]{'申請','処理済'};
        String[] kamokus = new String[]{'現金','買掛（月末振込）','買掛（都度振込）','事前振込','クレジットカード'};
        String[] purType = new String[]{'材料仕入','売店仕入','飲料仕入','室料経費','ブライダル仕入'};
        Account guests = TestCommon.createTravelCompany() ;
        guests.RoundType__c = '1';
        update guests;
        TestCommon.createchargeInfo(guests.id);
        // 口座情報の作成
        String shopAccLocalName = ShopAccountInfo__c.sObjectType.getDescribe().getName();
        List<RecordType> rts = [SELECT Id,Name FROM RecordType WHERE SobjectType  = :shopAccLocalName];
        String kouzaIds = TestCommon.createShopBankAccount(5,guests,rts,shop.id);
        
        List<Purchase__c> ps = new List<Purchase__c>();
        for(integer i = 0 ; i < 1 ; i++){
            Double status_idx = Math.random() * 1;
            Double kamoku_idx = Math.random() * 4;
            decimal incTax = Math.random() * 10000.9;
            Purchase__c p = new Purchase__c(
                                StatusLst__c = status[Integer.valueOf(status_idx)],
                                KamokuLst__c = '買掛（月末振込）',
                                DenpyoukeiIncTax__c = incTax * 1.08,
                                Denpyoukei__c  = incTax,
                                Purchasesource__c = guests.id,
                                JinyaRevenue__c = item.id,
                                PurchaseType__c = purType[Integer.valueOf(kamoku_idx)],
                                ShopInfoRef__c = shop.id,
                                NoTaxFlg__c = true
                            );
            ps.add(p);
        }
        insert ps;
        
        TestCommon.createBookEstItem(leadInfos[0], productLst[1]);
        TestCommon.createBookEstItem(leadInfos[0], accMsts);
        //TestCommon.createBookEstItem(leadInfos[1], accMsts);
        
        Test.stopTest();
        
        // 予約情報のステータス：チェックインに変更する
        leadInfos[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfos[0];        
        /* // 予約情報のステータス：チェックインに変更する
        leadInfos[1].Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfos[1];*/
        // 会計画面に動作確認を行う
        RsvAccount__c rsv = TestCommon.createRsvAccount();
        rsv = [select Salesday__c,Name from RsvAccount__c where id = :rsv.id];
        AccountAcount__c aa = TestCommon.createAccountAcount(rsv.Id, leadInfos[0].Id);
        List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfos[0].Id];
        AccountAcount__c accObj = accObjLst[0];
        accObj.CouponReturnFlg__c = true;
        TTend__c ttitem = TestCommon.createTTend(rsv.id,accObj.id);  
        ttitem.field1__c = accObj.id;
        ttitem.field2__c = CommConst.MEDIA_TYPE_CD_02; 
        ttitem.field3__c = '33'; 
        ttitem.RowNo__c  = 44;  // メディア種別,メディア名称
        ttitem.Field16__c = '55';
        ttitem.Field17__c = '66';
        ttitem.Field19__c = '67';
        ttitem.Field20__c = '77';// 単価,枚数,支払金額 
        ttitem.Field21__c = '10';
        ttitem.PaymentType__c = '99';
        ttitem.PayProductName__c = '111';
        ttitem.CardTypeLst__c = 'American Express';
        ttitem.CouponTypeLst__c = '楽天クーポン';
        ttitem.PayProductRef__c = null; //accMst.id; // 支払商品
        ttitem.UseDate__c = Date.today();
        update ttitem;
        
        DateTime startDates = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
        LeadIndex__c leadIndexitem = new LeadIndex__c(
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
        insert leadIndexitem;
        
        List<Tran1__c> tranLst = [select id,PaymentType__c from Tran1__c where Field7__c = :productLst[2].Id];
        Tran1__c  tran1 = tranLst[0];
        tran1.PaymentType__c = 'カード';
        update tran1;
        PaymentInfo__c pay1 = new PaymentInfo__c(
                                                AccountAcountRef__c = accObj.id,
                                                TTendRef__c = ttitem.id,//null,
                                                Tran1Ref__c = tran1.id,
                                                LeadIndexRef__c = leadIndexitem.id,
                                                PaymentType__c = '返金',
                                                MediaTypeCode__c = CommConst.MEDIA_TYPE_CD_02,
                                                DepositAmount__c = 70000
                                                );
        PaymentInfo__c pay2 = new PaymentInfo__c(
                                                AccountAcountRef__c = accObj.id,
                                                TTendRef__c = ttitem.id,
                                                Tran1Ref__c = tran1.id,
                                                LeadIndexRef__c = leadIndexitem.id,
                                                PaymentType__c = '返金',
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
        FreeeSyncCsvTemplateCtrl ctrl1 = new FreeeSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
        String csv = ctrl1.generalCsvContent();
        String csvRollup = ctrl1.generalRollupCsvContent();
        // 2019/12/30 FREEEAPI连携機能 WGCH BEGIN
        freeeSchedult(rsvAccLst[0].Id, '');
        freeebatch('', CommUtils.stringToDate(rsv.Name), CommUtils.stringToDate(rsv.Name));
        // 2019/12/30 FREEEAPI连携機能 WGCH END
    }
    
    static testMethod void addCase1 () {
        Test.startTest();
        // Init Xml Config
        getCsvSetupConfig1();
        // getCsvSetupConfig2();
        TestCommon.createTesuryoConfigDoc();
        CommDefine__c comDef = [select Id, BillInputSwitchCode__c from CommDefine__c limit 1];
        comDef.BillInputSwitchCode__c = '2';
        comDef.AccountSoftSyncCsvType__c = '2';
        update comDef;
        System.assertEquals([select Id from CommDefine__c].size(), 1);
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'SyncFieldConvertConfig'].size(), 1);
        // 2015/12/01 Assert END
        List<KanjoKamoku__c> kanjoMst =  createKankeKamoku();
        List<AccountMaster__c> paymentProdList = createMediaProductMst(kanjoMst);
        Contact guest = TestCommon.createContact();
        // マージ元の取引先情報を作成する
        Account FrAccounts = TestCommon.createNormalAccount();
        // 下記の取引先の関連情報はマージ元(FrAccounts)にコピーする
        Account ToAccounts = FrAccounts.clone(false,true);
        insert ToAccounts;
        Id toAccountId = ToAccounts.Id;
        // 予約情報を作成する
        List<Lead__c> leadInfos = TestCommon.createLead(Date.today(), 1, 1, guest.Id);
        leadInfos[0].SalesOfficeInfoRef__c = toAccountId;
        update leadInfos[0];
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(4);
        // 見積明細を作成する
        //TestCommon.createBookEstItem(leadInfos[0], productLst[0]);
        //TestCommon.createBookEstItem(leadInfos[1], productLst[0]);
        //TestCommon.createBookEstItem(leadInfos[2], productLst[0]);
        // 商品２は前受付金に変更を行う
        AccountMaster__c accMst = productLst[1];
        accMst.ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
        accMst.PaymentType__c = 'カード';  // XMLの定義と合わせるが必要です
        //accMst.CardAccountRef__c = toAccountId;
        update accMst;
        AccountMaster__c accMsts = productLst[2];
        accMsts.ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
        accMsts.PaymentType__c = 'カード';  // XMLの定義と合わせるが必要です
        //accMst.CardAccountRef__c = toAccountId;
        accMst.Field5__c = 80000;
        update accMsts;
        AccountMaster__c accMstPay = productLst[3];
        accMstPay.ActionType__c = CommConst.PROD_ACTION_TYPE_PY;
        accMstPay.PaymentType__c = '現金';    // XMLの定義と合わせるが必要です
        accMst.Field5__c = 80000;
        update accMstPay;
        System.assertEquals([select Id from Document where Name = 'AccountingSyncBatchConfig'].size(), 1);
        BookingEstimateItem__c bookingItem = TestCommon.createBookEstItem(leadInfos[0], productLst[0]);
        // 予約情報のステータス：チェックインに変更する
        //bookingItem.UnitPrice__c = 20000;
        bookingItem.ActionType__c = CommConst.PROD_ACTION_TYPE_PL;
        bookingItem.PaymentType__c = '予約金';
        //bookingItem.refBooking__c = leadInfo.Id; 
        //bookingItem.refAccountMaster__c = accMst.Id;
        //bookingItem.Amount__c = 4;
        //bookingItem.UnitPriceDefKbCal__c = '1';
        //bookingItem.ParentBookingItemRef__c = null;
        update bookingItem;
        // 2015/12/01 Assert END
        //連絡結果　予約取り込待ち
        TestCommon.createLeadImportAndWaitImpot();
        RsvAccount__c item = new RsvAccount__c();
        item.name = Date.today().format().replaceAll('/','').replaceAll('-','');
        //'20151113'
        insert item;
        ShopInformation__c shop = TestCommon.createShopInfo();
        String[] status = new String[]{'申請','処理済'};
        String[] kamokus = new String[]{'現金','買掛（月末振込）','買掛（都度振込）','事前振込','クレジットカード'};
        String[] purType = new String[]{'材料仕入','売店仕入','飲料仕入','室料経費','ブライダル仕入'};
        Account guests = TestCommon.createTravelCompany() ;
        guests.RoundType__c = '1';
        update guests;
        TestCommon.createchargeInfo(guests.id);
        // 口座情報の作成
        String shopAccLocalName = ShopAccountInfo__c.sObjectType.getDescribe().getName();
        List<RecordType> rts = [SELECT Id,Name FROM RecordType WHERE SobjectType  = :shopAccLocalName];
        String kouzaIds = TestCommon.createShopBankAccount(5,guests,rts,shop.id);
        TestCommon.createBookEstItem(leadInfos[0], productLst[1]);
        TestCommon.createBookEstItem(leadInfos[0], accMsts);
        //TestCommon.createBookEstItem(leadInfos[1], accMsts);
        
        
        
        // 予約情報のステータス：チェックインに変更する
        leadInfos[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfos[0];        
        Test.stopTest();
        // 会計画面に動作確認を行う
        RsvAccount__c rsv = TestCommon.createRsvAccount();
        rsv = [select Salesday__c,Name from RsvAccount__c where id = :rsv.id];
        AccountAcount__c aa = TestCommon.createAccountAcount(rsv.Id, leadInfos[0].Id);
        List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfos[0].Id];
        AccountAcount__c accObj = accObjLst[0];
        accObj.CouponReturnFlg__c = true;
        TTend__c ttitem = TestCommon.createTTend(rsv.id,accObj.id);  
        ttitem.field1__c = accObj.id;
        ttitem.field2__c = CommConst.MEDIA_TYPE_CD_12; 
        ttitem.field3__c = '33'; 
        ttitem.RowNo__c  = 44;  // メディア種別,メディア名称
        ttitem.Field16__c = '55';
        ttitem.Field17__c = '66';
        ttitem.Field19__c = '67';
        ttitem.Field20__c = '77';// 単価,枚数,支払金額 
        ttitem.Field21__c = '80';
        ttitem.PaymentType__c = '99';
        ttitem.PayProductName__c = '111';
        ttitem.CardTypeLst__c = 'American Express';
        ttitem.CouponTypeLst__c = '楽天クーポン';
        ttitem.UseDate__c = Date.today();
        update ttitem;
        
        DateTime startDates = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
        LeadIndex__c leadIndexitem = new LeadIndex__c(
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
        insert leadIndexitem;
        
        List<Tran1__c> tranLst = [select id,PaymentType__c from Tran1__c where Field7__c = :productLst[2].Id];
        Tran1__c  tran1 = tranLst[0];
        tran1.PaymentType__c = '予約金';
        update tran1;
        PaymentInfo__c pay1 = new PaymentInfo__c(
                                                AccountAcountRef__c = accObj.id,
                                                TTendRef__c = ttitem.id, //null,
                                                Tran1Ref__c = tran1.id,
                                                LeadIndexRef__c = leadIndexitem.id,
                                                PaymentType__c = '予約金',
                                                MediaTypeCode__c = CommConst.MEDIA_TYPE_CD_12,
                                                DepositAmount__c = 70000
                                                );
        PaymentInfo__c pay2 = new PaymentInfo__c(
                                                AccountAcountRef__c = accObj.id,
                                                TTendRef__c = ttitem.id,
                                                Tran1Ref__c = tran1.id,
                                                LeadIndexRef__c = leadIndexitem.id,
                                                PaymentType__c = '予約金',
                                                MediaTypeCode__c = CommConst.MEDIA_TYPE_CD_12,
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
        FreeeSyncCsvTemplateCtrl ctrl1 = new FreeeSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
        String csv = ctrl1.generalCsvContent();
        String csvRollup = ctrl1.generalRollupCsvContent();
        // 2019/12/30 FREEEAPI连携機能 WGCH BEGIN
        freeeSchedult(rsvAccLst[0].Id, '');
        freeebatch('', CommUtils.stringToDate(rsv.Name), CommUtils.stringToDate(rsv.Name));
        // 2019/12/30 FREEEAPI连携機能 WGCH END
    }
    
    static testMethod void addCase2 () {
        Test.startTest();
        // Init Xml Config
        getCsvSetupConfig1();
        // getCsvSetupConfig2();
        TestCommon.createTesuryoConfigDoc();
        CommDefine__c comDef = [select Id, BillInputSwitchCode__c from CommDefine__c limit 1];
        comDef.BillInputSwitchCode__c = '2';
        update comDef;
        System.assertEquals([select Id from CommDefine__c].size(), 1);
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'SyncFieldConvertConfig'].size(), 1);
        // 2015/12/01 Assert END
        List<KanjoKamoku__c> kanjoMst =  createKankeKamoku();
        KanjoKamoku__c kanjoMsts = new KanjoKamoku__c (
            Kanjocode__c = '3241003'
            , KanjocodeCode__c = '3241'
            , Name='ﾎﾃﾙ前受金'
            , KanjoHojocode__c='0011'
            , KanjoHojoname__c = 'ﾘｽﾄｻﾞﾝ'
            , DebitTaxKbn__c = '00'
            , CreditTaxKbn__c='00'
            , BalanceKbn__c = '貸方'
        );
        //kanjoMst.KanjoHojoname__c = 'テスト';
        List<AccountMaster__c> paymentProdList = createMediaProductMst(kanjoMst);
        Contact guest = TestCommon.createContact();
        // マージ元の取引先情報を作成する
        Account FrAccounts = TestCommon.createNormalAccount();
        // 下記の取引先の関連情報はマージ元(FrAccounts)にコピーする
        Account ToAccounts = FrAccounts.clone(false,true);
        insert ToAccounts;
        Id toAccountId = ToAccounts.Id;
        // 予約情報を作成する
        List<Lead__c> leadInfos = TestCommon.createLead(Date.today(), 1, 3, guest.Id);
        leadInfos[0].SalesOfficeInfoRef__c = toAccountId;
        update leadInfos[0];
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
        //accMst.CardAccountRef__c = toAccountId;
        update accMst;
        AccountMaster__c accMsts = productLst[2];
        accMsts.ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
        accMsts.PaymentType__c = 'カード';  // XMLの定義と合わせるが必要です
        //accMst.CardAccountRef__c = toAccountId;
        accMst.Field5__c = 80000;
        update accMsts;
        AccountMaster__c accMstPay = productLst[3];
        accMstPay.ActionType__c = CommConst.PROD_ACTION_TYPE_PY;
        accMstPay.PaymentType__c = '現金';    // XMLの定義と合わせるが必要です
        accMst.Field5__c = 80000;
        update accMstPay;
        System.assertEquals([select Id from Document where Name = 'AccountingSyncBatchConfig'].size(), 1);
        // 2015/12/01 Assert END
        //連絡結果　予約取り込待ち
        TestCommon.createLeadImportAndWaitImpot();
        RsvAccount__c item = new RsvAccount__c();
        item.name = Date.today().format().replaceAll('/','').replaceAll('-','');
        //'20151113'
        insert item;
        ShopInformation__c shop = TestCommon.createShopInfo();
        String[] status = new String[]{'申請','処理済'};
        String[] kamokus = new String[]{'現金','買掛（月末振込）','買掛（都度振込）','事前振込','クレジットカード'};
        String[] purType = new String[]{'材料仕入','売店仕入','飲料仕入','室料経費','ブライダル仕入'};
        Account guests = TestCommon.createTravelCompany() ;
        guests.RoundType__c = '1';
        update guests;
        TestCommon.createchargeInfo(guests.id);
        // 口座情報の作成
        String shopAccLocalName = ShopAccountInfo__c.sObjectType.getDescribe().getName();
        List<RecordType> rts = [SELECT Id,Name FROM RecordType WHERE SobjectType  = :shopAccLocalName];
        String kouzaIds = TestCommon.createShopBankAccount(5,guests,rts,shop.id);
        
        List<Purchase__c> ps = new List<Purchase__c>();
        for(integer i = 0 ; i < 1 ; i++){
            Double status_idx = Math.random() * 1;
            Double kamoku_idx = Math.random() * 4;
            decimal incTax = Math.random() * 10000.9;
            Purchase__c p = new Purchase__c(
                                StatusLst__c = status[Integer.valueOf(status_idx)],
                                KamokuLst__c = '買掛（月末振込）',
                                DenpyoukeiIncTax__c = incTax * 1.08,
                                Denpyoukei__c  = incTax,
                                Purchasesource__c = guests.id,
                                JinyaRevenue__c = item.id,
                                PurchaseType__c = purType[Integer.valueOf(kamoku_idx)],
                                ShopInfoRef__c = shop.id,
                                NoTaxFlg__c = true
                            );
            ps.add(p);
        }
        insert ps;
        
        TestCommon.createBookEstItem(leadInfos[0], productLst[1]);
        TestCommon.createBookEstItem(leadInfos[0], accMsts);
        //TestCommon.createBookEstItem(leadInfos[1], accMsts);
        
        Test.stopTest();
        
        // 予約情報のステータス：チェックインに変更する
        leadInfos[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfos[0];        
        
        // 会計画面に動作確認を行う
        RsvAccount__c rsv = TestCommon.createRsvAccount();
        rsv = [select Salesday__c,Name from RsvAccount__c where id = :rsv.id];
        AccountAcount__c aa = TestCommon.createAccountAcount(rsv.Id, leadInfos[0].Id);
        List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfos[0].Id];
        AccountAcount__c accObj = accObjLst[0];
        accObj.CouponReturnFlg__c = true;
        TTend__c ttitem = TestCommon.createTTend(rsv.id,accObj.id);  
        ttitem.field1__c = accObj.id;
        ttitem.field2__c = CommConst.MEDIA_TYPE_CD_11; 
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
        ttitem.CouponTypeLst__c = '楽天クーポン';
        ttitem.PayProductRef__c = null; //accMst.id; // 支払商品
        ttitem.UseDate__c = Date.today();
        update ttitem;
        
        DateTime startDates = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
        LeadIndex__c leadIndexitem = new LeadIndex__c(
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
        insert leadIndexitem;
        
        List<Tran1__c> tranLst = [select id,PaymentType__c from Tran1__c where Field7__c = :productLst[2].Id];
        Tran1__c  tran1 = tranLst[0];
        tran1.PaymentType__c = 'カード';
        update tran1;
        PaymentInfo__c pay1 = new PaymentInfo__c(
                                                AccountAcountRef__c = accObj.id,
                                                TTendRef__c = ttitem.id,//null,
                                                Tran1Ref__c = tran1.id,
                                                LeadIndexRef__c = leadIndexitem.id,
                                                PaymentType__c = '返金',
                                                MediaTypeCode__c = CommConst.MEDIA_TYPE_CD_11,
                                                DepositAmount__c = 70000
                                                );
        PaymentInfo__c pay2 = new PaymentInfo__c(
                                                AccountAcountRef__c = accObj.id,
                                                TTendRef__c = ttitem.id,
                                                Tran1Ref__c = tran1.id,
                                                LeadIndexRef__c = leadIndexitem.id,
                                                PaymentType__c = '返金',
                                                MediaTypeCode__c = CommConst.MEDIA_TYPE_CD_11,
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
        FreeeSyncCsvTemplateCtrl ctrl1 = new FreeeSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
        String csv = ctrl1.generalCsvContent();
        String csvRollup = ctrl1.generalRollupCsvContent();
        // 2019/12/30 FREEEAPI连携機能 WGCH BEGIN
        freeeSchedult(rsvAccLst[0].Id, '');
        freeebatch('', CommUtils.stringToDate(rsv.Name), CommUtils.stringToDate(rsv.Name));
        // 2019/12/30 FREEEAPI连携機能 WGCH END
    }
    static testMethod void Case11 () {
        Test.startTest();
        // Init Xml Config
        getCsvSetupConfig4();
        // getCsvSetupConfig2();
        CommDefine__c comDef = [select Id, BillInputSwitchCode__c from CommDefine__c limit 1];
        comDef.BillInputSwitchCode__c = '2';
        // comDef.AccountSoftSyncCsvType__c = '2';
        update comDef;
        //System.assertEquals([select Id from CommDefine__c].size(), 1);
        // 2015/12/01 Assert BEGIN
        //System.assertEquals([select Id from Document where Name = 'SyncFieldConvertConfig'].size(), 1);
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
        // 取引先作成
        Account acc = TestCommon.createNormalAccount();
        // 取引先関連の手数料定義作成
        list<ChargeInfo__c> chrLst1 = createTesuryo(acc);
        list<ChargeInfo__c> chrLst2 = createTesuryo(acc);
        createConfigDoc(chrLst2[0].Name);

        /*// 下記の取引先の関連情報はマージ元(FrAccounts)にコピーする
        //Account ToAccounts = acc.clone(false,true);
        //insert ToAccounts;
        //Id toAccountId = ToAccounts.Id;
        // お客様
        Contact contacts = TestCommon.createContact();
        contacts.AccountId = chrLst2[0].Name.Id;
        update contacts;
        // 契約[Contract]
        Contract newCon = new Contract(
            AccountId = chrLst2[0].Name,
            StartDate = Date.today(),
            ContractTerm = 3
        );
        insert newCon;*/
        list<AccountMaster__c> accList = new list<AccountMaster__c>();
        // 商品２は前受付金に変更を行う
        AccountMaster__c accMst = productLst[1];
        accMst.ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
        accMst.PaymentType__c = 'カード';  // XMLの定義と合わせるが必要です
        accMst.CardAccountRef__c = acc.id;
        //update accMst;
        accList.add(accMst);
        AccountMaster__c accMsts = productLst[2];
        accMsts.ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
        accMsts.PaymentType__c = 'カード';  // XMLの定義と合わせるが必要です
        accMst.CardAccountRef__c = acc.id;
        accMst.Field5__c = 80000;
        //update accMsts;
        accList.add(accMsts);
        AccountMaster__c accMstPay = productLst[3];
        accMstPay.ActionType__c = CommConst.PROD_ACTION_TYPE_PY;
        accMstPay.PaymentType__c = '現金';    // XMLの定義と合わせるが必要です
        accMst.Field5__c = 80000;
        //update accMstPay;
        accList.add(accMstPay);
        update accList;
        System.assertEquals([select Id from Document where Name = 'AccountingSyncBatchConfig'].size(), 1);
        // 2015/12/01 Assert END
        //連絡結果　予約取り込待ち
        TestCommon.createLeadImportAndWaitImpot();
        RsvAccount__c item = new RsvAccount__c();
        item.name = Date.today().format().replaceAll('/','').replaceAll('-','');
        //'20151113'
        insert item;
        ShopInformation__c shop = TestCommon.createShopInfo();
        String[] status = new String[]{'申請','処理済'};
        String[] kamokus = new String[]{'現金','買掛（月末振込）','買掛（都度振込）','事前振込','クレジットカード'};
        String[] purType = new String[]{'材料仕入','売店仕入','飲料仕入','室料経費','ブライダル仕入'};
        Account guests = TestCommon.createTravelCompany() ;
        guests.RoundType__c = '1';
        update guests;
        TestCommon.createchargeInfo(guests.id);
        // 口座情報の作成
        String shopAccLocalName = ShopAccountInfo__c.sObjectType.getDescribe().getName();
        List<RecordType> rts = [SELECT Id,Name FROM RecordType WHERE SobjectType  = :shopAccLocalName];
        String kouzaIds = TestCommon.createShopBankAccount(5,guests,rts,shop.id);
        
        List<Purchase__c> ps = new List<Purchase__c>();
        for(integer i = 0 ; i < 1 ; i++){
            Double status_idx = Math.random() * 1;
            Double kamoku_idx = Math.random() * 4;
            decimal incTax = Math.random() * 10000.9;
            Purchase__c p = new Purchase__c(
                                StatusLst__c = status[Integer.valueOf(status_idx)],
                                KamokuLst__c = '買掛（月末振込）',
                                DenpyoukeiIncTax__c = incTax * 1.08,
                                Denpyoukei__c  = incTax,
                                Purchasesource__c = guests.id,
                                JinyaRevenue__c = item.id,
                                PurchaseType__c = purType[Integer.valueOf(kamoku_idx)],
                                ShopInfoRef__c = shop.id
                            );
            ps.add(p);
        }
        insert ps;
        //Test.stopTest();
        TestCommon.createBookEstItem(leadInfos[0], productLst[1]);
        TestCommon.createBookEstItem(leadInfos[0], accMsts);
        //TestCommon.createBookEstItem(leadInfos[1], accMsts);

        Test.stopTest();
        
        // 予約情報のステータス：チェックインに変更する
        leadInfos[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfos[0];        
        
        // 会計画面に動作確認を行う
        List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfos[0].Id];
        AccountAcount__c accObj = accObjLst[0];
        //System.debug(logginglevel.INFO, 'wgch---test--ac.Relreserve__r.Relcontact__r.AccountId:::' + accObjLst);                    
        //System.debug(logginglevel.INFO, 'wgch---accObj:::' + accObj);
        //System.debug(logginglevel.INFO, 'wgch---accObj.id:::' + accObj.id);
        
        ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
        BillSimpleInputCtrl ctrl = new BillSimpleInputCtrl(contrl);
        ctrl.initAction();
        ctrl.upsertData();
        ctrl.addTran1Item();//入力行目を増える
        // 商品３は会計明細に設定する
        List<BillSimpleInputCtrl.TranItem> rsTranItems = ctrl.oTranSobjLst;
        rsTranItems[2].productNm = productLst[2].Name;
        rsTranItems[2].sobj.Field7__c = productLst[2].Id;
        rsTranItems[2].tranId = '';
        rsTranItems[2].accRefId = '';
        rsTranItems[2].sobj.Field20__c = '3000';
        rsTranItems[2].sobj.Field21__c = '1';
        // 商品４は会計支払情報として、明細に設定する
        rsTranItems[3].productNm = productLst[3].Name;
        rsTranItems[3].sobj.Field7__c = productLst[3].Id;
        rsTranItems[3].tranId = '';
        rsTranItems[3].accRefId = '';
        rsTranItems[3].sobj.Field20__c = '5000';
        rsTranItems[3].sobj.Field21__c = '1';
        ctrl.upsertData();
        CommDefine__c def = TestCommon.createCommDefine();
        def.BillInputSwitchCode__c = '2';
        update def;
        
        // 当日のCSV情報を出力する
        Date startDate = Date.today();
        // スケジュール実施開始日
        String strProcessDate = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('yyyyMMdd');
        List<RsvAccount__c> rsvAccLst = [select id,Name from RsvAccount__c where Name = :strProcessDate limit 1];
        FreeeSyncCsvTemplateCtrl ctrl1 = new FreeeSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
        /*
        String csv = ctrl1.generalCsvContent();
        String csvRollup = ctrl1.generalRollupCsvContent();
        */
    }
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
    // 2019/12/30 FREEEAPI连携機能 WGCH BEGIN
    private static void freeeSchedult(id salesid, string spcd){
    	FreeeSeting__c createFreeeSeting = TestCommon.createFreeeSeting();
        FreeeSyncCsvGetBatch schedult = new FreeeSyncCsvGetBatch();
        DateTime nowTime = DateTime.now().addSeconds(10);
			// 起動ＣＲＯＮを設定する
			String timeStr = nowTime.format('yyyyMMddHHmmss');
			String yy = timeStr.substring(0,4);
			String mm = timeStr.substring(4,6);
			String dd = timeStr.substring(6,8);
			String hh = timeStr.substring(8,10);
			String ms = timeStr.substring(10,12);
			String ss = timeStr.substring(12,14);
			String sch = ss + ' ' +
			       ms + ' ' +
			       hh + ' ' +
			       dd + ' ' +
			       mm + ' ' +
			       ' ? ' + yy;
		String jobName = 'FreeeSyncCsvGetBatch_' + DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, sch, schedult);
		// バッチ起動する　
		/*
		Date begdt = Date.today();
		Date enddt = begdt.addDays(30);
		FreeeSyncCsvGetBatch batch = new FreeeSyncCsvGetBatch('',begdt,enddt);
		DataBase.executeBatch(batch,1);*/
    }
    private static void freeebatch(STRING gShopCode, DATE gFromDate, DATE gToDate){
    	FreeeSeting__c createFreeeSeting = TestCommon.createFreeeSeting();
        // Requstバッチ起動
        FreeeSyncCsvGetBatch batch = new FreeeSyncCsvGetBatch(gShopCode,gFromDate,gToDate);
        DataBase.executeBatch(batch,1);
        FreeeSyncCsvPostBatch postBatch = new FreeeSyncCsvPostBatch(new List<FreeeSyncCsvPostBatch.ProShopInfo>(), new Map<String, List<FreeeSyncCsvPostBatch.ProDocumentInfo>>());
        postBatch.pro = new FreeeSyncCsvPostBatch.ProDocumentInfo();
        postBatch.pro.startDate = CommUtils.dateToYYYYMMDD(Date.today());
        postBatch.checkSections('01');
        postBatch.deleteManualJournals('');
        postBatch.getManualJournals();
        postBatch.postManualJournals('');
        postBatch.getManualJournalsJson('');
        postBatch.checkAccountItems('');
        postBatch.getAccountItems();
        postBatch.checkItems('');
        postBatch.getItems('');
        postBatch.getItemsJson('', '', '');
        postBatch.getSectionsJson('', '', '', '');
        postBatch.postData('', '');
    }
    // 2019/12/30 FREEEAPI连携機能 WGCH END
    /**
    * メデイア関連の会計商品情報作成
    **/
    private static List<AccountMaster__c> createMediaProductMst(List<KanjoKamoku__c> kanjoMst) {
        List<AccountMaster__c> prodList = TestCommon.createProductMst(6);
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
         // 買掛（月末振込）:212
        KanjoKamoku__c newItem6 = new KanjoKamoku__c(
              Kanjocode__c = '324'
            , KanjocodeCode__c = '212'
            , Name='買掛'
            , DebitTaxKbn__c = '00'
            , CreditTaxKbn__c='B4'
            , BalanceKbn__c = '貸方'
        );
        // 買掛（月末振込）:212
        KanjoKamoku__c newItem7 = new KanjoKamoku__c(
              Kanjocode__c = '325'
            , KanjocodeCode__c = '212'
            , Name='買掛'
            , KanjoHojocode__c='0011'
            , KanjoHojoname__c = 'ﾘｽﾄｻﾞﾝ'
            , DebitTaxKbn__c = '00'
            , CreditTaxKbn__c='00'
            , BalanceKbn__c = '貸方'
        );
        // 現金：2
        KanjoKamoku__c newItem8 = new KanjoKamoku__c(
              Kanjocode__c = '326'
            , KanjocodeCode__c = '2'
            , KanjoHojocode__c='11100001'
            , KanjoHojoname__c = 'テスト'
            , Name='現金'
            , DebitTaxKbn__c = '00'
            , CreditTaxKbn__c='00'
            , BalanceKbn__c = '借方'
        );
        // 買掛（月末振込）:212
        KanjoKamoku__c newItem9 = new KanjoKamoku__c(
              Kanjocode__c = '327'
            , KanjocodeCode__c = '212'
            , KanjoHojocode__c='51100001'
            , KanjoHojoname__c = 'テストA'
            , Name='買掛'
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
        insLst.add(newItem6);
        insLst.add(newItem7);
        insLst.add(newItem8);
        insLst.add(newItem9);
        insert insLst;
        return insLst;
    }
    private static list<ChargeInfo__c> createTesuryo(Account acc) {
        System.debug(logginglevel.INFO, 'wgch---test--acc.id:::' + acc.id);
        // お客様
        Contact contacts = TestCommon.createContact();
        contacts.AccountId = acc.Id;
        update contacts;
        System.debug(logginglevel.INFO, 'wgch---test--contacts.id:::' + contacts.id);
        System.debug(logginglevel.INFO, 'wgch---test--contacts.AccountId:::' + contacts.AccountId);
        // 契約[Contract]
        Contract newCon = new Contract(
            AccountId = acc.Id,
            StartDate = Date.today(),
            ContractTerm = 3
        );
        insert newCon;
        List<ChargeInfo__c> insLst = new List<ChargeInfo__c>();
        ChargeInfo__c chrg = new ChargeInfo__c(
            SalesRate__c = 8,
            CategoryMain__c = AccountingSyncBatchHelp.TESURYO_DIV_AGT,
            AccountRef__c = acc.Id,
            PayChargeFlg__c = true
        );
        insLst.add(chrg);
        chrg = new ChargeInfo__c(
            SalesRate__c = 8,
            CategoryMain__c = AccountingSyncBatchHelp.TESURYO_DIV_AGT,
            AccountRef__c = acc.Id,
            PayChargeFlg__c = true
        );
        insLst.add(chrg);
        chrg = new ChargeInfo__c(
            SalesRate__c = 8,
            CategoryMain__c = AccountingSyncBatchHelp.TESURYO_DIV_CARD,
            AccountRef__c = acc.Id,
            PayChargeFlg__c = true
        );
        insLst.add(chrg);
        chrg = new ChargeInfo__c(
            SalesRate__c = 8,
            CategoryMain__c = AccountingSyncBatchHelp.TESURYO_DIV_CARD,
            AccountRef__c = acc.Id,
            PayChargeFlg__c = false
        );
        insLst.add(chrg);
        insert insLst;
        list<id> ids = new list<id>{insLst[0].id,insLst[1].Id};
        return [select id,name,SalesRate__c,AccountRef__c from ChargeInfo__c where id in :ids];
    }
    static testMethod void addCase () {
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
        FreeeSyncCsvTemplateCtrl ctrl1 = new FreeeSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
        /*
        String csv = ctrl1.generalCsvContent();
        String csvRollup = ctrl1.generalRollupCsvContent();
        */
        // 2019/12/30 FREEEAPI连携機能 WGCH BEGIN
        freeeSchedult(rsvAccLst[0].Id, '');
        freeebatch('', CommUtils.stringToDate(rsvAccLst[0].Name), CommUtils.stringToDate(rsvAccLst[0].Name));
        // 2019/12/30 FREEEAPI连携機能 WGCH END
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
         '<PRICEZERO_OUTPUT>FALSE</PRICEZERO_OUTPUT>'+
        '<ROLLUP_OUTPUT>TRUE</ROLLUP_OUTPUT>'+
        '<ROLLUP_PUR_OUTPUT>TRUE</ROLLUP_PUR_OUTPUT>'+
        '<TAX_KBN>1</TAX_KBN> '+
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
        '<NOTAXKBN>非課税</NOTAXKBN>'+ 
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
        '<PCA_PYA_TAX>'+                
        '<KANJOCODE>3351</KANJOCODE>'+
        '</PCA_PYA_TAX>'+
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
        
        TestCommon.createOrderConfigXml();
        TestCommon.createDeviceConfigXml();
        TestCommon.createConfigSimple();
    }
    private static void getCsvSetupConfig3() {
        CommDefine__c def = TestCommon.createCommDefine();
        def.SchedulePcaCsvHeaderIsShowFlg__c = true;
        update def;
        String xml = 
        '<?xml version="1.0" encoding="UTF-8"?>'+
        '<root>'+
        '<SHOP>'+
        '<SHOPCODE></SHOPCODE>'+
        '<PCA>'+
        '<PRICEZERO_OUTPUT>FALSE</PRICEZERO_OUTPUT>' +
        '<ROLLUP_OUTPUT>TRUE</ROLLUP_OUTPUT>' +
        '<ROLLUP_PUR_OUTPUT></ROLLUP_PUR_OUTPUT>' +
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
    private static void getCsvSetupConfig4() {
        CommDefine__c def = TestCommon.createCommDefine();
        def.SchedulePcaCsvHeaderIsShowFlg__c = true;
        update def;
        String xml = 
        '<?xml version="1.0" encoding="UTF-8"?>'+
        '<root>'+
        '<SHOP>'+
        '<SHOPCODE></SHOPCODE>'+
        '<PCA>'+
        '<UTIWAKE_OUTPUT>'+                 
        '<ISOUPUT>TRUE</ISOUPUT>'+              
        '<CARD_TESURYO>'+           
        '<PAYCHARGEFLG_REQUIRE>FALSE</PAYCHARGEFLG_REQUIRE>'+
        '<KANJOCODE>1841</KANJOCODE>'+      
        '<KANJOCODE_TAXKBN>非課税</KANJOCODE_TAXKBN>'+
        '<KANJOCODE_R>216</KANJOCODE_R>'+   
        '<KANJOCODE_R_TAXKBN>非課税</KANJOCODE_R_TAXKBN>'+
        '</CARD_TESURYO>'+
        '<AGT_TESURYO>'+
        '<PAYCHARGEFLG_REQUIRE>FALSE</PAYCHARGEFLG_REQUIRE>'+
        '<KANJOCODE>428</KANJOCODE>'+   
        '<KANJOCODE_TAXKBN>課税</KANJOCODE_TAXKBN>'+  
        '<KANJOCODE_R>216</KANJOCODE_R>'+
        '<KANJOCODE_R_TAXKBN>課税</KANJOCODE_R_TAXKBN>'+
        '<MEDIA_TYPE>2</MEDIA_TYPE>'+
        '</AGT_TESURYO>'+
        '</UTIWAKE_OUTPUT>'+
        '<PRICEZERO_OUTPUT>FALSE</PRICEZERO_OUTPUT>'+
        '<ROLLUP_OUTPUT>TRUE</ROLLUP_OUTPUT>'+
        '<ROLLUP_PUR_OUTPUT>TRUE</ROLLUP_PUR_OUTPUT>'+
        '<TAX_KBN>1</TAX_KBN> '+
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
        '<PURCHASE>'+
        '<P_TYPE NOTAXKBN_KEY="非課税,不課税">'+
        '<CONVERT><TYPENAME>材料仕入</TYPENAME><KANJOCODE>324</KANJOCODE><KANJOCODE_R>212</KANJOCODE_R><KANJOCODE_R_DESCRIPT>買掛金</KANJOCODE_R_DESCRIPT><KANJOCODE_TAXKBN>非課税</KANJOCODE_TAXKBN><KANJOCODE_TAXKBN_R>非課税</KANJOCODE_TAXKBN_R></CONVERT>'+ 
        '<CONVERT><TYPENAME>売店仕入</TYPENAME><KANJOCODE>325</KANJOCODE><KANJOCODE_R>212</KANJOCODE_R><KANJOCODE_R_DESCRIPT>買掛金</KANJOCODE_R_DESCRIPT><KANJOCODE_TAXKBN>非課税</KANJOCODE_TAXKBN><KANJOCODE_TAXKBN_R>非課税</KANJOCODE_TAXKBN_R></CONVERT>'+ 
        '<CONVERT><TYPENAME>飲料仕入</TYPENAME><KANJOCODE>326</KANJOCODE><KANJOCODE_R>212</KANJOCODE_R><KANJOCODE_R_DESCRIPT>買掛金</KANJOCODE_R_DESCRIPT><KANJOCODE_TAXKBN>非課税</KANJOCODE_TAXKBN><KANJOCODE_TAXKBN_R>非課税</KANJOCODE_TAXKBN_R></CONVERT>'+ 
        '<CONVERT><TYPENAME>室料経費</TYPENAME><KANJOCODE>327</KANJOCODE><KANJOCODE_R>2</KANJOCODE_R><KANJOCODE_R_DESCRIPT>現金</KANJOCODE_R_DESCRIPT><KANJOCODE_TAXKBN>非課税</KANJOCODE_TAXKBN><KANJOCODE_TAXKBN_R>非課税</KANJOCODE_TAXKBN_R></CONVERT>'+    
        '</P_TYPE>'+
        '<P_KAMOKU>'+
        '<CONVERT><TYPENAME>現金</TYPENAME><KANJOCODE>2</KANJOCODE></CONVERT>'+
        '<CONVERT><TYPENAME>買掛（月末振込）</TYPENAME><KANJOCODE>212</KANJOCODE></CONVERT>'+
        '</P_KAMOKU>'+
        '</PURCHASE>'+
        '</SHOP>'+
        '</root>';
        Document doc = new Document();
        doc.Name = 'SyncFieldConvertConfig';
        doc.DeveloperName = doc.Name;
        doc.FolderId = UserInfo.getUserId();
        doc.Body = Blob.valueOf(xml);
        insert doc;
    }
     private static void createConfigDoc(String tesuryoNo) {
        
        String configXml = '<?xml version="1.0" encoding="utf-8"?><root><!-- 概要：銀行振り込み情報作成の関連定義情報 --><SHOP><!-- デフォルト設定情報、削除しない、支店舗追加したい場合、このＮＯＤＥコピーして、後ろに追加してください --><SHOPCODE></SHOPCODE><ROUND_TYPE>1</ROUND_TYPE><!-- 手数料の端数処理区分 0:切り捨て / 1:四捨五入 / 2:切り上げ --><!-- 処理通知先メールアドレス,「,」で複数メールアドレス定義可能（５個まで） --><RESULT_MAIL>test11111@1111cccsss999.com</RESULT_MAIL><!-- 銀行へ通信電文関連定義情報 --><!-- 銀行振り込み手数料:必須 --><BANK_TRANS_RATE><SAME_BANK><!-- 同銀行 --><SAME_BRANCH><!-- 同支店 --><RANK_LEVEL><MIN_VAL>0</MIN_VAL><MAX_VAL>9999</MAX_VAL><RATE>0</RATE></RANK_LEVEL><RANK_LEVEL><MIN_VAL>10000</MIN_VAL><MAX_VAL>29999</MAX_VAL><RATE>0</RATE></RANK_LEVEL><RANK_LEVEL><MIN_VAL>30000</MIN_VAL><RATE>0</RATE></RANK_LEVEL></SAME_BRANCH><DIFF_BRANCH><!-- 別支店 --><RANK_LEVEL><MIN_VAL>0</MIN_VAL><MAX_VAL>9999</MAX_VAL><RATE>108</RATE></RANK_LEVEL><RANK_LEVEL><MIN_VAL>10000</MIN_VAL><MAX_VAL>29999</MAX_VAL><RATE>108</RATE></RANK_LEVEL><RANK_LEVEL><MIN_VAL>30000</MIN_VAL><RATE>324</RATE></RANK_LEVEL></DIFF_BRANCH></SAME_BANK><DIFF_BANK><!-- 別銀行 --><RANK_LEVEL><MIN_VAL>0</MIN_VAL><MAX_VAL>9999</MAX_VAL><RATE>324</RATE></RANK_LEVEL><RANK_LEVEL><MIN_VAL>10000</MIN_VAL><MAX_VAL>29999</MAX_VAL><RATE>432</RATE></RANK_LEVEL><RANK_LEVEL><MIN_VAL>30000</MIN_VAL><RATE>648</RATE></RANK_LEVEL></DIFF_BANK></BANK_TRANS_RATE><!-- 口座情報定義する --><BANK_KOZAINFO><PUR_SETTLEMENT><!-- 買掛決済バッチ --><KOUZA_SEQ>2</KOUZA_SEQ><!-- 店舗口座情報#SEQ値 --><DESCRIPT>仕入支払口座</DESCRIPT><TRANS_TYPE>21</TRANS_TYPE><!-- 業務種別:21:総合 11または71:給与 12または72:賞与 --></PUR_SETTLEMENT></BANK_KOZAINFO><BANK_TELEGRAM_HEADER><DATA_KBN>1</DATA_KBN><!-- レコード種別:1:ヘッダレコード --><MESSAGE_LAYOUT>$$_データ区分_$$$$_種別コード_$$$$_コード区分_$$$$_委託者コード_$$$$_委託者名_$$$$_取組日_$$$$_仕向金融機関番号_$$$$_仕向金融機関名_$$$$_仕向支店番号_$$$$_仕向支店名_$$$$_預金種目(依頼人)_$$$$_口座番号(依頼人)_$$$$_ダミー_$$</MESSAGE_LAYOUT></BANK_TELEGRAM_HEADER><BANK_TELEGRAM_DETAIL><DATA_KBN>2</DATA_KBN><!-- レコード種別:2:データレコード --><IS_EDI>FALSE</IS_EDI><!-- EDI情報を使う --><IS_PLUSFORMAT>TRUE</IS_PLUSFORMAT><!-- $$_支払金額_$$,$$_先方負担手数料_$$,$$_振込手数料_$$追加情報を出力するがどうか --><!-- $$_識別表示_$$はYの場合、$$_顧客コード1_$$,$$_顧客コード2_$$全部長さ０空白文字を差し替え、$$_EDI情報_$$を設定する、 $$_識別表示_$$はY以外の場合、$$_顧客コード1_$$,$$_顧客コード2_$$は別々１０桁まで設定する、$$_EDI情報_$$は長さ０の空白文字を差し替え --><MESSAGE_LAYOUT>$$_データ区分_$$$$_被仕向金融機関番号_$$$$_被仕向金融機関名_$$$$_被仕向支店番号_$$$$_被仕向支店名_$$$$_手形交換所番号_$$$$_預金種目_$$$$_口座番号_$$$$_受取人名_$$$$_振込金額_$$$$_新規コード_$$$$_顧客コード1_$$$$_顧客コード2_$$$$_EDI情報_$$$$_振込区分_$$$$_識別表示_$$$$_ダミー_$$$$_支払金額_$$$$_先方負担手数料_$$$$_振込手数料_$$</MESSAGE_LAYOUT></BANK_TELEGRAM_DETAIL><BANK_TELEGRAM_TRAILER><DATA_KBN>8</DATA_KBN><!-- レコード種別:8:トレーラレコード --><MESSAGE_LAYOUT>$$_データ区分_$$$$_合計件数_$$$$_合計金額_$$$$_ダミー_$$</MESSAGE_LAYOUT></BANK_TELEGRAM_TRAILER><BANK_TELEGRAM_END><DATA_KBN>9</DATA_KBN><!-- レコード種別:9:エンドレコード --><MESSAGE_LAYOUT>$$_データ区分_$$$$_ダミー_$$</MESSAGE_LAYOUT></BANK_TELEGRAM_END><!-- カード販売手数料計算関連 --><CARD_SALESRATE><I_TYPENAME>支払手数料</I_TYPENAME><O_KAMOKU>買掛（月末振込）</O_KAMOKU></CARD_SALESRATE><AGT_SALESRATE><I_TYPENAME>販売手数料</I_TYPENAME><!-- 種別 --><O_KAMOKU>買掛（月末振込）</O_KAMOKU><!-- 科目 --><HOLIDAY_INC_SAT>FALSE</HOLIDAY_INC_SAT><!-- 休日定義に、土曜日は休日として定義する/しない制御　TRUE:休日、FALSE：休日外(デフォルト値) --><CHARGERATE_LOGIC><FILTER TESURYONO="$$_TESURYONO_$$"><!-- 該当手数料番号に関連のご予約の抽出条件 --><DESCRIPT>I.JTB/HR(宿泊)</DESCRIPT><LOGIC>{0}</LOGIC><COONDITION>Relreserve__r.StayNightCal__c > 0</COONDITION></FILTER></CHARGERATE_LOGIC></AGT_SALESRATE></SHOP></root>';
        if (CommUtils.isBlank(tesuryoNo)) tesuryoNo = '';
        configXml.replace('$$_TESURYONO_$$',configXml);
        // ドキュメントを作成する
        Document item = new Document();
        item.Name = 'AccountingSyncBatchConfig';
        item.DeveloperName = item.Name;
        item.FolderId = UserInfo.getUserId();
        item.Body = Blob.valueOf(configXml);
        insert item;
    }
    static testMethod void addCase_001 () {
        Test.startTest();
        // Init Xml Config
        getCsvSetupConfig4();
        // getCsvSetupConfig2();
        TestCommon.createTesuryoConfigDoc();
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
        // マージ元の取引先情報を作成する
        Account FrAccounts = TestCommon.createNormalAccount();
        // 下記の取引先の関連情報はマージ元(FrAccounts)にコピーする
        Account ToAccounts = FrAccounts.clone(false,true);
        insert ToAccounts;
        Id toAccountId = ToAccounts.Id;
        // 予約情報を作成する
        List<Lead__c> leadInfos = TestCommon.createLead(Date.today(), 1, 3, guest.Id);
        leadInfos[0].SalesOfficeInfoRef__c = toAccountId;
        update leadInfos[0];
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
        //accMst.CardAccountRef__c = toAccountId;
        update accMst;
        AccountMaster__c accMsts = productLst[2];
        accMsts.ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
        accMsts.PaymentType__c = 'カード';  // XMLの定義と合わせるが必要です
        //accMst.CardAccountRef__c = toAccountId;
        accMst.Field5__c = 80000;
        update accMsts;
        AccountMaster__c accMstPay = productLst[3];
        accMstPay.ActionType__c = CommConst.PROD_ACTION_TYPE_PY;
        accMstPay.PaymentType__c = '現金';    // XMLの定義と合わせるが必要です
        accMst.Field5__c = 80000;
        update accMstPay;
        System.assertEquals([select Id from Document where Name = 'AccountingSyncBatchConfig'].size(), 1);
        // 2015/12/01 Assert END
        //連絡結果　予約取り込待ち
        TestCommon.createLeadImportAndWaitImpot();
        RsvAccount__c item = new RsvAccount__c();
        item.name = Date.today().format().replaceAll('/','').replaceAll('-','');
        //'20151113'
        insert item;
        ShopInformation__c shop = TestCommon.createShopInfo();
        String[] status = new String[]{'申請','処理済'};
        String[] kamokus = new String[]{'現金','買掛（月末振込）','買掛（都度振込）','事前振込','クレジットカード'};
        String[] purType = new String[]{'材料仕入','売店仕入','飲料仕入','室料経費','ブライダル仕入'};
        Account guests = TestCommon.createTravelCompany() ;
        guests.RoundType__c = '1';
        update guests;
        TestCommon.createchargeInfo(guests.id);
        // 口座情報の作成
        String shopAccLocalName = ShopAccountInfo__c.sObjectType.getDescribe().getName();
        List<RecordType> rts = [SELECT Id,Name FROM RecordType WHERE SobjectType  = :shopAccLocalName];
        String kouzaIds = TestCommon.createShopBankAccount(5,guests,rts,shop.id);
        
        List<Purchase__c> ps = new List<Purchase__c>();
        for(integer i = 0 ; i < 1 ; i++){
            Double status_idx = Math.random() * 1;
            Double kamoku_idx = Math.random() * 4;
            decimal incTax = Math.random() * 10000.9;
            Purchase__c p = new Purchase__c(
                                StatusLst__c = status[Integer.valueOf(status_idx)],
                                KamokuLst__c = '買掛（月末振込）',
                                DenpyoukeiIncTax__c = incTax * 1.08,
                                Denpyoukei__c  = incTax,
                                Purchasesource__c = guests.id,
                                JinyaRevenue__c = item.id,
                                PurchaseType__c = purType[Integer.valueOf(kamoku_idx)],
                                ShopInfoRef__c = shop.id,
                                NoTaxFlg__c = true
                            );
            ps.add(p);
        }
        insert ps;
        
        TestCommon.createBookEstItem(leadInfos[0], productLst[1]);
        TestCommon.createBookEstItem(leadInfos[0], accMsts);
        Test.stopTest();
        
        // 予約情報のステータス：チェックインに変更する
        leadInfos[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfos[0];        
        /* // 予約情報のステータス：チェックインに変更する
        leadInfos[1].Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfos[1];*/
        // 会計画面に動作確認を行う
        RsvAccount__c rsv = TestCommon.createRsvAccount();
        rsv = [select Salesday__c,Name from RsvAccount__c where id = :rsv.id];
        AccountAcount__c aa = TestCommon.createAccountAcount(rsv.Id, leadInfos[0].Id);
        List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfos[0].Id];
        AccountAcount__c accObj = accObjLst[0];
        accObj.CouponReturnFlg__c = true;
        TTend__c ttitem = TestCommon.createTTend(rsv.id,accObj.id);  
        ttitem.field1__c = accObj.id;
        ttitem.field2__c = CommConst.MEDIA_TYPE_CD_02; 
        ttitem.field3__c = '33'; 
        ttitem.RowNo__c  = 44;  // メディア種別,メディア名称
        ttitem.Field16__c = '55';
        ttitem.Field17__c = '66';
        ttitem.Field19__c = '67';
        ttitem.Field20__c = '77';// 単価,枚数,支払金額 
        ttitem.Field21__c = '10';
        ttitem.PaymentType__c = '99';
        ttitem.PayProductName__c = '111';
        ttitem.CardTypeLst__c = 'American Express';
        ttitem.CouponTypeLst__c = '楽天クーポン';
        ttitem.PayProductRef__c = null; //accMst.id; // 支払商品
        ttitem.UseDate__c = Date.today();
        update ttitem;
        
        DateTime startDates = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
        LeadIndex__c leadIndexitem = new LeadIndex__c(
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
        insert leadIndexitem;
        
        List<Tran1__c> tranLst = [select id,PaymentType__c from Tran1__c where Field7__c = :productLst[2].Id];
        Tran1__c  tran1 = tranLst[0];
        tran1.PaymentType__c = 'カード';
        update tran1;
        PaymentInfo__c pay1 = new PaymentInfo__c(
                                                AccountAcountRef__c = accObj.id,
                                                TTendRef__c = ttitem.id,//null,
                                                Tran1Ref__c = tran1.id,
                                                LeadIndexRef__c = leadIndexitem.id,
                                                PaymentType__c = '返金',
                                                MediaTypeCode__c = CommConst.MEDIA_TYPE_CD_02,
                                                DepositAmount__c = 70000
                                                );
        PaymentInfo__c pay2 = new PaymentInfo__c(
                                                AccountAcountRef__c = accObj.id,
                                                TTendRef__c = ttitem.id,
                                                Tran1Ref__c = tran1.id,
                                                LeadIndexRef__c = leadIndexitem.id,
                                                PaymentType__c = '返金',
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
        FreeeSyncCsvTemplateCtrl ctrl1 = new FreeeSyncCsvTemplateCtrl(rsvAccLst[0].Id, '');
        String csv = ctrl1.generalCsvContent();
        String csvRollup = ctrl1.generalRollupCsvContent();
        freeebatch(shop.ShopCode__c, startDate, startDate);
        
    }
}