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
private class TtendTriggerProcessTest {
    /*
	// 会計支払明細は新規作成の場合、
    static testMethod void create001() {
    	
        // 現金合せレイアウトに情報を作成する
        createCashInfo();
        // 当日の会計情報を作成する
        TestCommon.createBillSimpleHelpConfigDoc();
        TestCommon.createBillSimplePaymentConfigDoc();
        // 支払メデイア情報を自動作成
        List<String> names = new List<String>{Label.CONST_012_0438,Label.CONST_012_0439};
        set<string> paymediaSet = new set<string>();
        paymediaSet.addAll(names);
        list<AccountMaster__c> payProductMst = TestCommon.createPayProductMst(paymediaSet);
        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
        // 商品情報を作成する[5件商品を作成する]
        List<AccountMaster__c> productLst = TestCommon.createProductMst(5);
        
        Test.startTest();
        // Lead設定する
        ApexPages.StandardController contrl = new ApexPages.StandardController(leadInfo);
        BookingEstimateItemSetup ctrl = new BookingEstimateItemSetup(contrl);
        List<BookingEstimateItemSetup.BookEstItem> queryLst = ctrl.oBookEstLst;
        Integer isValidataRecs = 0;
        for (BookingEstimateItemSetup.BookEstItem item : queryLst) {
        	if (item.isValidata) isValidataRecs++;
        }
        // プランから見積明細を自動作成対応
        System.assertEquals(isValidataRecs, 1);

        BookingEstimateItemSetup.BookEstItem item2 = queryLst[1];
        item2.sobj.refAccountMaster__c = productLst[1].Id;
        item2.productNm = productLst[1].Name;
        item2.prodNums = '4';
        item2.sobj.UnitPrice__c = 5000;
        //item2.sobj.ActionType__c = '通常'
        BookingEstimateItemSetup.BookEstItem payitem = queryLst[2];
        AccountMaster__c cashpay = payProductMst[0];
        payitem.sobj.refAccountMaster__c = cashpay.Id;//現金
        payitem.productNm = cashpay.Name;
        payitem.prodNums = '1';
        payitem.sobj.UnitPrice__c = 10000;
        payitem.sobj.ActionType__c = cashpay.ActionType__c;
		payitem.sobj.PaymentType__c = cashpay.PaymentType__c;

        BookingEstimateItemSetup.BookEstItem payitem2 = queryLst[3];
        payitem2.sobj.refAccountMaster__c = cashpay.Id;//現金
        payitem2.productNm = cashpay.Name;
        payitem2.prodNums = '1';
        payitem2.sobj.UnitPrice__c = 5000;
        payitem2.sobj.ActionType__c = cashpay.ActionType__c;
		payitem2.sobj.PaymentType__c = cashpay.PaymentType__c;
		
        ctrl.upsertData();
        queryLst = ctrl.oBookEstLst;
        isValidataRecs = 0;
        for (BookingEstimateItemSetup.BookEstItem item : queryLst) {
            if (item.isValidata) isValidataRecs++;
        }
        System.assertEquals(isValidataRecs, 4);
        // 予約情報のステータス：チェックインに変更する
        leadInfo.Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfo;
        
		Test.stopTest();
		// 予約チェックイン、該当明細は自動新規作成の場合、該当日の打ち合わせに自動コピーを行う
 		//System.debug(loggingLevel.info, 'RESULT='+[select id,Field2__c,Field28__c,Field29__c,Field1__r.ShopCode__c,RelAccount__c from TTend__c limit 10]);
 		// 現金合せ画面に連携確認
 		List<CashVerification__c> existCash = [select CashSales__c from CashVerification__c];
 		System.assertEquals(existCash[0].CashSales__c, 15000);
 		// 明細金額変更を行う
 		List<TTend__c> existTtend = [select Field20__c from TTend__c order by name limit 1];
 		existTtend[0].Field20__c = '12000';
 		update existTtend;
 		existCash = [select CashSales__c from CashVerification__c];
 		System.assertEquals(existCash[0].CashSales__c, 17000);
 		//　明細情報を削除する
 		delete [select id from TTend__c limit 10];
 		// 現金合せ画面に連携確認
 		existCash = [select CashSales__c from CashVerification__c];
 		System.assertEquals(existCash[0].CashSales__c, 0);
 		
 		
 		
    }*/
    /*
    // 制御オブジェクトのパラメータは無効の場合、金額の連携処理を行わない
    static testMethod void carete002_byParam() {
    	
    	
    }
    static testMethod void delete001() {
        // TO DO: implement unit test
        
    }
    static testMethod void update001() {
        // TO DO: implement unit test
         // 現金合せレイアウトに情報を作成する
        createCashInfo();
        // 当日の会計情報を作成する
        TestCommon.createBillSimpleHelpConfigDoc();
        TestCommon.createBillSimplePaymentConfigDoc();
        
        List<String> names = new List<String>{Label.CONST_012_0438,Label.CONST_012_0439};
        set<string> paymediaSet = new set<string>();
        paymediaSet.addAll(names);
        list<AccountMaster__c> payProductMst = TestCommon.createPayProductMst(paymediaSet);
        // 新規登録を行う
        AccountAcount__c accObj = new AccountAcount__c();
        ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
        // 画面起動
        BillSimpleInputCtrl ctrl = new BillSimpleInputCtrl(contrl);
        ctrl.initAction();
        ctrl.oAcountSobj.relaccount__c = TestCommon.createContact().Id;
        List<BillSimpleInputCtrl.TranItem> rsTranItems = ctrl.oTranSobjLst;     
 		//ctrl.ttendSobj
 		// 現金支払を行う
 		AccountMaster__c cashpay= payProductMst[0];
        rsTranItems[1].productNm = cashpay.Name;
        rsTranItems[1].sobj.Field7__c = cashpay.Id;
        rsTranItems[1].tranId = '';
        rsTranItems[1].accRefId = '';
        rsTranItems[1].sobj.Field20__c = '150000';
        rsTranItems[1].sobj.Field21__c = '1';
        
        rsTranItems[1].sobj.ActionType__c = cashpay.ActionType__c;
        rsTranItems[1].sobj.PaymentType__c = cashpay.PaymentType__c;
        ctrl.insertData();
system.debug(logginglevel.info,'rsTranItems[1]:::' + rsTranItems[1]);
system.debug(logginglevel.info,'isValidata:::' + rsTranItems[1].isValidata);
        rsTranItems[1].sobj.Field20__c = '155555';
        
 		ctrl.upsertData();
 		
 		System.debug(loggingLevel.info, 'RESULT='+[select id,Field2__c,Field28__c,Field29__c,Field1__r.ShopCode__c,RelAccount__c from TTend__c limit 10]);
    }
    static testMethod void update002() {
        // TO DO: implement unit test
        
    }*/

    private static void createCashInfo() {
        TestCommon.createDeviceConfigXml();
        TestCommon.createOrderConfigXml();
        
    	CashRollupBook cashBook = new CashRollupBook();
        cashBook.init();
        cashBook.refreshBranShop();
		// 初期化
		Integer amount = 10000;
        CashRollupBook.CashBookInfo cashInfo = cashBook.cashInfo;
        cashInfo.cash.ReserveFund__c = amount;
        // 保存する
        cashInfo.cash.TenThousandCashNums__c = amount/10000;
        cashBook.saveCashInfo();
    }
}