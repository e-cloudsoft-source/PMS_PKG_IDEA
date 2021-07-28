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
private class BillSimpleInputCtrlTest {

    // 新規会計画面起動、直接情報を入れて、新規情報作成を行う
    static testMethod void Case1 () {
        // Init Xml Config
        getCsvSetupConfig();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'BillSimplePaymentConfig'].size(), 1);
        // 2015/12/01 Assert END
        // 新規登録を行う
        AccountAcount__c accObj = new AccountAcount__c();
        ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
        // 画面起動
        BillSimpleInputCtrl ctrl = new BillSimpleInputCtrl(contrl);
        ctrl.initAction();
        ctrl.oAcountSobj.relaccount__c = TestCommon.createContact().Id;
        ctrl.insertData();
        // 追加
        DataFixBatchForAccountTaxRate batch = new DataFixBatchForAccountTaxRate();
		DataBase.executeBatch(batch, 1);
		batch = new DataFixBatchForAccountTaxRate(Date.newInstance(2019,10,1));
		DataBase.executeBatch(batch, 1);
		DataFixBatchForAccountTaxRate schedule= new DataFixBatchForAccountTaxRate();
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
		String jobName = 'DataFixBatchForAccountTaxRate_' + DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, sch, schedule);
		
        // 明細情報を登録して、保存する処理
        // プラン商品作成
        AccountMaster__c planProd0 = TestCommon.createProductMst(1)[0];
        AccountMaster__c planProd1 = TestCommon.createProductMst(1)[0];
        
        List<BillSimpleInputCtrl.TranItem> rsTranItems = ctrl.oTranSobjLst;     
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

        // 商品１に、数量、単価更新を行う
        rsTranItems[0].productNm = 'テスト商品１名前再定義';
        rsTranItems[0].sobj.Field20__c = '50000';
        rsTranItems[0].sobj.Field21__c = '3';
        // 商品２に、プラン商品１に更新を行う、プラン明細に単価など変更なし、数量と単価を更新する
        rsTranItems[1].productNm = planProd1.Name;
        rsTranItems[1].sobj.Field7__c = planProd1.Id;
        rsTranItems[1].tranId = '';
        rsTranItems[1].accRefId = '';
        rsTranItems[1].sobj.Field20__c = '3000';
        rsTranItems[1].sobj.Field21__c = '1';
        List<BillSimpleInputCtrl.PlanDetail> planDetailLst2 = BillSimpleInputCtrl.getAccountMstLstByPlan(rsTranItems[1].sobj.Id, '', planProd1.Id, '');
        // 商品３に、別の普通商品に設定する,単価、数量など設定を行う
        planSummary = 0;
        planDetailString = '';
        for (BillSimpleInputCtrl.PlanDetail pl : planDetailLst2) {
            pl.prodPrice = String.valueOf(Decimal.valueOf(pl.prodPrice.replaceAll(',', ''))  + 100);
            planSummary += Decimal.valueOf(pl.prodPrice);
            planDetailString += pl.sobjId + ':' + pl.prodPrice + ';';
        }
        rsTranItems[1].sobj.Field20__c = String.valueOf(planSummary);
        rsTranItems[1].sobj.Field21__c = String.valueOf(Decimal.valueOf(rsTranItems[1].sobj.Field21__c) + 1);
        rsTranItems[1].sobj.PlanDetailSyncInfo__c = planDetailString;
        ctrl.upsertData();
    }
    /**
    * 予約情報からチェックインして、会計データ情報確認
    **/
    static testMethod void Case2_1 () {
        Test.startTest();
        // Init Xml Config
        getCsvSetupConfig();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'BillSimplePaymentConfig'].size(), 1);
        // 2015/12/01 Assert END
        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfo, productLst[0]);
        // 予約情報のステータス：チェックインに変更する
        leadInfo.Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfo;

        Test.stopTest();
 
        // 会計画面に動作確認を行う
        List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfo.Id];
        AccountAcount__c accObj = accObjLst[0];

        ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
        BillSimpleInputCtrl ctrl = new BillSimpleInputCtrl(contrl);
        ctrl.initAction();
        ctrl.upsertData();
    }
    /**
    * 予約連泊情報から会計情報を作成する、前受付金情報を見積明細に設定を行う
    **/
    static testMethod void Case2_2() {
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
        accMstPay.PaymentType__c = '現金';    // XMLの定義と合わせるが必要です
        update accMstPay;
        
        TestCommon.createBookEstItem(leadInfos[0], productLst[1]);
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
        Apexpages.currentPage().getParameters().put('fc','33');
        ApexPages.StandardController contr2 = new ApexPages.StandardController(accObj);
    	AccountPDF pdf = new AccountPDF(contr2);
    	pdf.getRequestAmount();
    	Apexpages.currentPage().getParameters().put('fc','23');
    	pdf = new AccountPDF(contr2);
    }
    /**
    * 旧会計編集機能から会計情報作成して、その後、新会計メニューを起動して、情報保存処理を行う
    **/
    static testMethod void Case2_3() {
        Test.startTest();
        // Init Xml Config
        getCsvSetupConfig();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'BillSimplePaymentConfig'].size(), 1);
        // 2015/12/01 Assert END
        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 見積明細を作成する
        BookingEstimateItem__c est = TestCommon.createBookEstItem(leadInfo, productLst[0]);
        
        // 予約情報のステータス：チェックインに変更する
        leadInfo.Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfo;

        // 会計画面に動作確認を行う
        List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfo.Id];
        AccountAcount__c accObj = accObjLst[0];

        ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
        BillInput_Ctrl ctrl = new BillInput_Ctrl(contrl);
        ctrl.initAction();
        Test.stopTest();
        
        ApexPages.StandardController simpleCtrl = new ApexPages.StandardController(accObj);
        BillSimpleInputCtrl sCtrl = new BillSimpleInputCtrl(simpleCtrl);
        sCtrl.initAction();
        sCtrl.getAccountNames();
        sCtrl.getAccountProvisos();
        sCtrl.upsertData();
        sCtrl.gotoCancel();
        BillSimpleInputCtrl.getAccountMstLstByPlan('','','',est.Id);
        List<BillSimpleInputCtrl.TranItem> rsTranItems = sCtrl.oTranSobjLst;
        BillSimpleInputCtrl.getAccountMstLstByPlan(rsTranItems[0].tranId, ctrl.oAcountSobj.Id,'','');
        sCtrl.upsertData();
        
    }
    static testMethod void AddCase1 () {
        // Init Xml Config
        getCsvSetupConfig();
        ShopInformation__c shop = TestCommon.createShopInfo();
        shop.ShopCode__c = '04';
        upsert shop;
        User curUsr = [select shopcode__c from user where id = :userInfo.getUserid()];
        curUsr.shopcode__c = shop.ShopCode__c;
        update curUsr;
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'BillSimplePaymentConfig'].size(), 1);
        // 2015/12/01 Assert END
		AccountAcount__c accObj = new AccountAcount__c();
        ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
        // 画面起動
        BillSimpleInputCtrl ctrl = new BillSimpleInputCtrl(contrl);
        ctrl.initAction();
        ctrl.oAcountSobj.relaccount__c = TestCommon.createContact().Id;
        ctrl.insertData();
		ctrl.getRelAccountIds();
        ctrl.getPayiconDefault();
        /*
        String s1 = ctrl.ACTTYPE_PAY + '#' + ctrl.ACTTYPE_AR + '#' + ctrl.ACTTYPE_PAY_DIS_RATE + '#' + ctrl.ACTTYPE_PAY_DIS_PRICE 
					+ '#' + ctrl.MEDIA_TYPE_COPON + '#' + ctrl.MEDIA_TYPE_DISCOUNT + '#' + ctrl.commNoShowRequestFlg 
					+ '#' + ctrl.accountPopupIsShowFlg + '#' + ctrl.accountPrintTypeIsShowFlg + '#' + ctrl.billStampIsShowFlg 
					+ '#' + ctrl.useDateMiddleMode + '#' + ctrl.oDefaultCurrency + '#' + ctrl.payTypeConvertJson 
					+ '#' + ctrl.refundItemString + '#' + ctrl.commentMaxStrSize + '#' + ctrl.mulitiShops;*/
        // 明細情報を登録して、保存する処理
        // プラン商品作成
        AccountMaster__c planProd0 = TestCommon.createProductMst(1)[0];
        AccountMaster__c planProd1 = TestCommon.createProductMst(1)[0];
        List<BillSimpleInputCtrl.TranItem> rsTranItems = ctrl.oTranSobjLst;
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
        // 商品１に、数量、単価更新を行う
        rsTranItems[0].productNm = 'テスト商品１名前再定義';
        rsTranItems[0].sobj.Field20__c = '50000';
        rsTranItems[0].sobj.Field21__c = '3';
        // 商品２に、プラン商品１に更新を行う、プラン明細に単価など変更なし、数量と単価を更新する
        rsTranItems[1].productNm = planProd1.Name;
        rsTranItems[1].sobj.Field7__c = planProd1.Id;
        rsTranItems[1].tranId = '';
        rsTranItems[1].accRefId = '';
        rsTranItems[1].sobj.Field20__c = '3000';
        rsTranItems[1].sobj.Field21__c = '1';
        List<BillSimpleInputCtrl.PlanDetail> planDetailLst2 = BillSimpleInputCtrl.getAccountMstLstByPlan(rsTranItems[1].sobj.Id, '', planProd1.Id, '');
        // 商品３に、別の普通商品に設定する,単価、数量など設定を行う
        planSummary = 0;
        planDetailString = '';
        for (BillSimpleInputCtrl.PlanDetail pl : planDetailLst2) {
            pl.prodPrice = String.valueOf(Decimal.valueOf(pl.prodPrice.replaceAll(',', ''))  + 100);
            planSummary += Decimal.valueOf(pl.prodPrice);
            planDetailString += pl.sobjId + ':' + pl.prodPrice + ';';
        }
        rsTranItems[1].sobj.Field20__c = String.valueOf(planSummary);
        rsTranItems[1].sobj.Field21__c = String.valueOf(Decimal.valueOf(rsTranItems[1].sobj.Field21__c) + 1);
        rsTranItems[1].sobj.PlanDetailSyncInfo__c = planDetailString;
        ctrl.upsertData();
    }
    static testMethod void AddCase2 () {
    	CommDefine__c comm = TestCommon.createCommDefine();
    	comm.AccountUseDateMode__c = '2';
    	upsert comm;
        Test.startTest();
        // Init Xml Config
        getCsvSetupConfig();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'BillSimplePaymentConfig'].size(), 1);
        // 2015/12/01 Assert END
        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfo, productLst[0]);
        // 予約情報のステータス：チェックインに変更する
        leadInfo.Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfo;
        Test.stopTest();
        // 会計画面に動作確認を行う
        List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfo.Id];
        AccountAcount__c accObj = accObjLst[0];
        ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
        BillSimpleInputCtrl ctrl = new BillSimpleInputCtrl(contrl);
        ctrl.initAction();
        ctrl.upsertData();
        //ctrl.voidProcessCancel();
        String[] preAutoCheckin = BillSimpleInputCtrl.preAutoCheckin(leadInfo.Id);
    }
    @isTest(SeeAllData=true)
    static void remoteTest001 () {
     	BillSimpleInputCtrl.savePrintLodToDb('test');
     	CommDefine__c comm = TestCommon.createCommDefine();
    	comm.AccountUseDateMode__c = '2';
    	upsert comm;
        Test.startTest();
        // Init Xml Config
        getCsvSetupConfig();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'BillSimplePaymentConfig'].size(), 1);
        // 2015/12/01 Assert END
        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfo, productLst[0]);
        // 予約情報のステータス：チェックインに変更する
        leadInfo.Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfo;
        Test.stopTest();
        // 会計画面に動作確認を行う
        List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfo.Id];
        AccountAcount__c accObj = accObjLst[0];
        ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
        BillSimpleInputCtrl ctrl = new BillSimpleInputCtrl(contrl);
        ctrl.initAction();
        ctrl.refreshTran1Item();
       	ctrl.initDevice();
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
    // 2019/11/13 BY zyz BEGIN
    static testMethod void AddCase2_1 () {
    	CommDefine__c comm = TestCommon.createCommDefine();
    	comm.AccountUseDateMode__c = '2';
    	comm.ReducedTaxRateFlg__c = true;
    	comm.PDFPlanBrkIsShowFlg__c = true;
    	upsert comm;
        Test.startTest();
        // Init Xml Config
        getCsvSetupConfig();
        getCsvSetupConfigField();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'BillSimplePaymentConfig'].size(), 1);
        // 2015/12/01 Assert END
        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(4);
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfo, productLst[0]);
        // 商品２は前受付金に変更を行う
        AccountMaster__c accMst = productLst[1];
        accMst.ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
        accMst.PaymentType__c = 'カード';  // XMLの定義と合わせるが必要です
        update accMst;
        AccountMaster__c accMstPay = productLst[3];
        accMstPay.ActionType__c = CommConst.PROD_ACTION_TYPE_PY;
        accMstPay.PaymentType__c = '現金';    // XMLの定義と合わせるが必要です
        update accMstPay;
        // 予約情報のステータス：チェックインに変更する
        leadInfo.Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfo;
        Test.stopTest();
        // 会計画面に動作確認を行う
        List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfo.Id];
        AccountAcount__c accObj = accObjLst[0];
        
        ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
        BillSimpleInputCtrl ctrl = new BillSimpleInputCtrl(contrl);
        ctrl.initAction();
        ctrl.upsertData();
        //ctrl.voidProcessCancel();
        String[] preAutoCheckin = BillSimpleInputCtrl.preAutoCheckin(leadInfo.Id);
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
    // 2019/11/13 BY zyz END
    /**
    * 予約連泊情報から会計情報を作成する、前受付金情報を見積明細に設定を行う
    **/
    static testMethod void Case3_1() {
        ReportLogo__c rep = TestCommon.createRepLogo();
        ShopInformation__c shop = TestCommon.createShopInfo();
        rep.ShopInfoRef__c = shop.Id;
        update rep;
        User currUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        currUser.ShopCode__c = shop.ShopCode__c;
        update currUser;
        // Init Xml Config
        getCsvSetupConfig();
        CommDefine__c def = TestCommon.createCommDefine();
        def.StockSyncIsActiveFlg__c = true;
        update def;
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'BillSimplePaymentConfig'].size(), 1);
        // 2015/12/01 Assert END
        Contact guest = TestCommon.createContact();
        // 予約情報を作成する
        List<Lead__c> leadInfos = TestCommon.createLead(Date.today(), 1, 3, guest.Id);
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(4);
        ProcessedProduct__c pd = new ProcessedProduct__c();
        pd.ProductRef__c = productLst[0].id;
        pd.ItemProdcutRef__c = productLst[1].id;
        pd.Usage__c = 50;
        insert pd;
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
        accMstPay.PaymentType__c = '現金';    // XMLの定義と合わせるが必要です
        update accMstPay;
        Test.startTest();
        TestCommon.createBookEstItem(leadInfos[0], productLst[1]);
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
        Test.stopTest();
    }
    static testMethod void AddCase3 () {
    	CommDefine__c comm = TestCommon.createCommDefine();
    	comm.AccountUseDateMode__c = '2';
    	upsert comm;
        Test.startTest();
        // Init Xml Config
        getCsvSetupConfig();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'BillSimplePaymentConfig'].size(), 1);
        // 2015/12/01 Assert END
        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(4);
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfo, productLst[0]);
        // 予約情報のステータス：チェックインに変更する
        leadInfo.Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfo;
        Test.stopTest();
        // 会計画面に動作確認を行う
        List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfo.Id];
        AccountAcount__c accObj = accObjLst[0];
        ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
        BillSimpleInputCtrl ctrl = new BillSimpleInputCtrl(contrl);
        comm.RsvLockType__c = '1';
    	upsert comm;
        ctrl.initAction();
        ctrl.upsertData();
        //ctrl.voidProcessCancel();
        String[] preAutoCheckin = BillSimpleInputCtrl.preAutoCheckin(leadInfo.Id);
        comm.RsvLockType__c = '2';
        upsert comm;
        ctrl.upsertData();
        List<rsvaccount__c> rsvs = [select isLockFlg__c,id from rsvaccount__c];
        for (rsvaccount__c acc : rsvs) acc.isLockFlg__c = true;
        update rsvs;
        // 商品３は会計明細に設定する
        List<BillSimpleInputCtrl.TranItem> rsTranItems = ctrl.oTranSobjLst;
        rsTranItems[2].productNm = productLst[1].Name;
        rsTranItems[2].sobj.Field7__c = productLst[1].Id;
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
        try{
            ctrl.upsertData();
        } catch(exception e) {
            system.assert(e.getMessage().contains(Label.MSG_006_0459));
        }
        
    }
}