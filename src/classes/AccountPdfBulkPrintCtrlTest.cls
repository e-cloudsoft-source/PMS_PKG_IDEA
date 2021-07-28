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
private class AccountPdfBulkPrintCtrlTest {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        Test.startTest();
    	// 店舗情報を初期化する
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	comDef.FacilityCode__c = '3';
    	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
    	comDef.ReducedTaxRateFlg__c = true;
    	comDef.PDFPlanBrkIsShowFlg__c = true;
    	// 2019/07/30 軽減税率機能対応 WGCH END
    	update comDef;
		User currUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	currUser.ShopCode__c = '';
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
    	ApexPages.currentPage().getParameters().put('accDate',leadInfo.Departure__c.Date().format());
		ApexPages.currentPage().getParameters().put('shopcd','');
        AccountPdfBulkPrintCtrl acc = new AccountPdfBulkPrintCtrl();
        acc.init();
        //acc.redirectPlugin();
        acc.gotoDate();
        // 会計画面に動作確認を行う
    	List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c =: leadInfo.Id];
    	String accIdStr = accObjLst[0].Id;
        AccountPdfBulkPrintCtrl.getAccPrintItemInfo(accIdStr,'true',leadInfo.Departure__c.Date().format());
        AccountPdfBulkPrintCtrl.checkoutAction(leadInfo.Id);
    }
     /**
    * 予約連泊情報から会計情報を作成する、前受付金情報を見積明細に設定を行う
    **/
    static testMethod void Case2_2() {
        Test.startTest();
        // Init Xml Config
        getCsvSetupConfig();
        User currUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        currUser.ShopCode__c = '';
        update currUser;
        TestCommon.createRepLogo();
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
        // 2019/04/15 BY zyz BEGIN
        RsvAccount__c rsv = TestCommon.createRsvAccount();
        // 2019/04/15 BY zyz END
        // 会計画面に動作確認を行う
        List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfos[0].Id];
        AccountAcount__c accObj = accObjLst[0];
        // 2019/04/15 BY zyz BEGIN
    	TTend__c ttitem = TestCommon.createTTend(rsv.Id, accObj.Id); 
    	ttitem.field2__c = '22'; 
    	ttitem.field3__c = '予約金';
    	ttitem.RowNo__c  = 44;	// メディア種別,メディア名称
		ttitem.Field16__c = '55';
		ttitem.Field17__c = '66';
		ttitem.Field20__c = '77';// 単価,枚数,支払金額 
		update ttitem;
		// 2019/04/15 BY zyz END
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
        // 2019/04/15 BY zyz BEGIN
        def.AccountShowRoomColFlg__c = true;
        // 2019/04/15 BY zyz END
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
    	def.ReducedTaxRateFlg__c = true;
    	def.PDFPlanBrkIsShowFlg__c = true;
    	// 2019/07/30 軽減税率機能対応 WGCH END
        update def;
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
        // Apexpages.currentPage().getParameters().put('fc','33');
        Apexpages.currentPage().getParameters().put('fc','34');
        // 2019/07/30 軽減税率機能対応 WGCH END
        Apexpages.currentPage().getParameters().put('bp','1');
        // 2019/04/15 BY zyz BEGIN
        Apexpages.currentPage().getParameters().put('g','1');
        // 2019/04/15 BY zyz END
        Apexpages.currentPage().getParameters().put('bulkid',accObj.Id);
        ApexPages.StandardController contr2 = new ApexPages.StandardController(accObj);
        AccountPDFExtCtrl pdf = new AccountPDFExtCtrl(contr2);
        pdf.extInitAction();
        // 2019/04/15 BY zyz BEGIN
        pdf.getSimpleAccReceiptDate();
        // 2019/04/15 BY zyz END
        //pdf.getRequestAmount();
        List<AccountPDFExtCtrl.OneRoomInfo> bulkPrintInfoLst = pdf.bulkPrintInfoLst;
    }
    /*
    static testMethod void Case2_3() {
        Test.startTest();
        // Init Xml Config
        getCsvSetupConfig();
        User currUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        currUser.ShopCode__c = '';
        update currUser;
        TestCommon.createRepLogo();
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
        // 2019/04/15 BY zyz BEGIN
        RsvAccount__c rsv = TestCommon.createRsvAccount();
        // 2019/04/15 BY zyz END
        // 会計画面に動作確認を行う
        List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfos[0].Id];
        AccountAcount__c accObj = accObjLst[0];
        // 2019/04/15 BY zyz BEGIN
    	TTend__c ttitem = TestCommon.createTTend(rsv.Id, accObj.Id); 
    	ttitem.field2__c = '22'; 
    	ttitem.field3__c = '予約金';
    	ttitem.RowNo__c  = 44;	// メディア種別,メディア名称
		ttitem.Field16__c = '55';
		ttitem.Field17__c = '66';
		ttitem.Field20__c = '77';// 単価,枚数,支払金額 
		update ttitem;
		// 2019/04/15 BY zyz END
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
        def.AccountSetTotalPosition__c = '3';
        // 2019/04/15 BY zyz BEGIN
        def.AccountShowRoomColFlg__c = true;
        // 2019/04/15 BY zyz END
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
    	def.ReducedTaxRateFlg__c = true;
    	def.PDFPlanBrkIsShowFlg__c = true;
    	// 2019/07/30 軽減税率機能対応 WGCH END
        update def;
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
        // Apexpages.currentPage().getParameters().put('fc','33');
        Apexpages.currentPage().getParameters().put('fc','34');
        // 2019/07/30 軽減税率機能対応 WGCH END
        Apexpages.currentPage().getParameters().put('bp','1');
        // 2019/04/15 BY zyz BEGIN
        Apexpages.currentPage().getParameters().put('g','1');
        // 2019/04/15 BY zyz END
        Apexpages.currentPage().getParameters().put('bulkid',accObj.Id);
        ApexPages.StandardController contr2 = new ApexPages.StandardController(accObj);
        AccountPDFExtCtrl pdf = new AccountPDFExtCtrl(contr2);
        pdf.extInitAction();
        // 2019/04/15 BY zyz BEGIN
        pdf.getSimpleAccReceiptDate();
        // 2019/04/15 BY zyz END
        //pdf.getRequestAmount();
        List<AccountPDFExtCtrl.OneRoomInfo> bulkPrintInfoLst = pdf.bulkPrintInfoLst;
    }
    static testMethod void Case2_4() {
        Test.startTest();
        // Init Xml Config
        getCsvSetupConfig();
        User currUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        currUser.ShopCode__c = '';
        update currUser;
        TestCommon.createRepLogo();
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
        // 2019/04/15 BY zyz BEGIN
        RsvAccount__c rsv = TestCommon.createRsvAccount();
        // 2019/04/15 BY zyz END
        // 会計画面に動作確認を行う
        List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfos[0].Id];
        AccountAcount__c accObj = accObjLst[0];
        // 2019/04/15 BY zyz BEGIN
    	TTend__c ttitem = TestCommon.createTTend(rsv.Id, accObj.Id); 
    	ttitem.field2__c = '22'; 
    	ttitem.field3__c = '予約金';
    	ttitem.RowNo__c  = 44;	// メディア種別,メディア名称
		ttitem.Field16__c = '55';
		ttitem.Field17__c = '66';
		ttitem.Field20__c = '77';// 単価,枚数,支払金額 
		update ttitem;
		// 2019/04/15 BY zyz END
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
        def.AccountSetTotalPosition__c = '2';
        // 2019/04/15 BY zyz BEGIN
        def.AccountShowRoomColFlg__c = true;
        // 2019/04/15 BY zyz END
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
    	def.ReducedTaxRateFlg__c = true;
    	def.PDFPlanBrkIsShowFlg__c = true;
    	// 2019/07/30 軽減税率機能対応 WGCH END
        update def;
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
        // Apexpages.currentPage().getParameters().put('fc','33');
        Apexpages.currentPage().getParameters().put('fc','34');
        // 2019/07/30 軽減税率機能対応 WGCH END
        Apexpages.currentPage().getParameters().put('bp','1');
        // 2019/04/15 BY zyz BEGIN
        Apexpages.currentPage().getParameters().put('g','1');
        // 2019/04/15 BY zyz END
        Apexpages.currentPage().getParameters().put('bulkid',accObj.Id);
        ApexPages.StandardController contr2 = new ApexPages.StandardController(accObj);
        AccountPDFExtCtrl pdf = new AccountPDFExtCtrl(contr2);
        pdf.extInitAction();
        // 2019/04/15 BY zyz BEGIN
        pdf.getSimpleAccReceiptDate();
        // 2019/04/15 BY zyz END
        //pdf.getRequestAmount();
        List<AccountPDFExtCtrl.OneRoomInfo> bulkPrintInfoLst = pdf.bulkPrintInfoLst;
    }
    */
    // 2019/11/13 BY zyz BEGIN
    static testMethod void Case2_5() {
        Test.startTest();
        // Init Xml Config
        getCsvSetupConfig();
        User currUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        currUser.ShopCode__c = '';
        update currUser;
        TestCommon.createRepLogo();
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
        // 2019/04/15 BY zyz BEGIN
        RsvAccount__c rsv = TestCommon.createRsvAccount();
        // 2019/04/15 BY zyz END
        // 会計画面に動作確認を行う
        List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfos[0].Id];
        AccountAcount__c accObj = accObjLst[0];
        // 2019/04/15 BY zyz BEGIN
    	TTend__c ttitem = TestCommon.createTTend(rsv.Id, accObj.Id); 
    	ttitem.field2__c = '22'; 
    	ttitem.field3__c = '予約金';
    	ttitem.RowNo__c  = 44;	// メディア種別,メディア名称
		ttitem.Field16__c = '55';
		ttitem.Field17__c = '66';
		ttitem.Field20__c = '77';// 単価,枚数,支払金額 
		update ttitem;
		// 2019/04/15 BY zyz END
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
        // 2019/04/15 BY zyz BEGIN
        def.AccountShowRoomColFlg__c = true;
        // 2019/04/15 BY zyz END
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
    	def.ReducedTaxRateFlg__c = true;
    	def.PDFPlanBrkIsShowFlg__c = true;
    	// 2019/07/30 軽減税率機能対応 WGCH END
    	def.AccountSetTotalPosition__c = '2';
        update def;
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
        // Apexpages.currentPage().getParameters().put('fc','33');
        Apexpages.currentPage().getParameters().put('fc','34');
        // 2019/07/30 軽減税率機能対応 WGCH END
        Apexpages.currentPage().getParameters().put('bp','1');
        // 2019/04/15 BY zyz BEGIN
        Apexpages.currentPage().getParameters().put('g','1');
        // 2019/04/15 BY zyz END
        Apexpages.currentPage().getParameters().put('bulkid',accObj.Id);
        ApexPages.StandardController contr2 = new ApexPages.StandardController(accObj);
        AccountPDFExtCtrl pdf = new AccountPDFExtCtrl(contr2);
        pdf.extInitAction();
        // 2019/04/15 BY zyz BEGIN
        pdf.getSimpleAccReceiptDate();
        // 2019/04/15 BY zyz END
        pdf.getReportLogo();
        pdf.getTaxRate();
        pdf.getDate();
        pdf.getAdvancesReceived();
        pdf.getTran();
        pdf.getServiceDate();
        //pdf.getRequestAmount();
        List<AccountPDFExtCtrl.OneRoomInfo> bulkPrintInfoLst = pdf.bulkPrintInfoLst;
    }
    // 2019/11/13 BY zyz END
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
}