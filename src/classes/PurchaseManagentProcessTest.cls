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
private class PurchaseManagentProcessTest {

    static testMethod void myUnitTest() {
    	createConfigDoc(null);
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'AccountingSyncBatchConfig'].size(), 1);
        // 2015/12/01 Assert END
    	ShopInformation__c shop = TestCommon.createShopInfo();
    	AccountingSyncBatchHelp config = new AccountingSyncBatchHelp(shop.ShopCode__c);
    	RsvAccount__c item = new RsvAccount__c();
    	item.name = '20151113';
    	Date proDate = Date.newInstance(2015,11,13);
    	insert item;
        // TO DO: implement unit test
        PurchaseManagentProcess purProcess = new PurchaseManagentProcess(proDate,shop.ShopCode__c,config);
        purProcess.clearExistDate();
        Date curDay =  Date.today();
    	//DateTime startDate = DateTime.newInstance(curDay.addDays(10), Time.newInstance(0, 0, 0, 0));
    	DateTime startDate = DateTime.newInstance(curDay, Time.newInstance(0, 0, 0, 0));
    	//LeadIndex__c leadIndex = createLeadIndex(3, startDate, startDate.addDays(1));
    	Room__c room = TestCommon.createRooms();
    	Account account = TestCommon.createTravelCompany ();
    	account.RoundType__c = '切り捨て';
    	update account;
    	/*
    	Contact contact = new Contact(
    		firstName = 'UNIT_TEST_顧客名' + CommUtils.getRandom(6),
    		LastName = 'LASTNAME'+CommUtils.getRandom(6),
    		Katakana__c = 'Katakana__c'+CommUtils.getRandom(10),
    		KanaName1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Name1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Phone = CommUtils.getRandom(10)
    		);
    	insert contact;
    	*/
        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
        leadInfo.SalesOfficeInfoRef__c= account.id;
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfo, productLst[0]);
        // 予約情報のステータス：チェックインに変更する
        leadInfo.Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfo;
        
    	createTesuryo(account);
    	/*
    	// 連泊データを自動作成
    	Lead__c item1 = new Lead__c(
    	   RecordTypeId = CommLogicProcess.getLeadBookingRecType(),
    	   name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
    	   Relcontact__c = contact.Id,                  // 顧客名
    	   ReservedStatus__c = '確認中',
    	   ReservedDate__c = System.now(),
    	   ReservedContact__c = 'Ono',
    	   EntryTime__c = startDate.addDays(-1),
    	   Field4__c = '15:30',
    	   Departure__c = startDate,
    	   Field3__c = '10:00',
    	   StayPersons__c = 4,
    	   SalesOfficeInfoRef__c = account.id,
    	   Field2__c = 'FAX',
    	   Field310__c = TestCommon.createPlan().Id,
    	   //LeadIndexRef__c = leadIndex.Id,
    	   Rroom__c = room.Id,
    	   refTypeOfRooms__c = room.TypeRoomRef__c);
    	insert item1;
    	item1.Field298__c = CommConst.LEAD_GUEST_ST_CI;
    	update item1;
    	AccountAcount__c acc = [select id,name from AccountAcount__c where Relreserve__c = :item1.id];
    	*/
    	//Relreserve__c
    	//item1
        purProcess.generalNetAgtSalesRate();
        purProcess.generalCardSalesRate();
        
    }
    // 
    static testMethod void tesuryoCase001() {
    	
    	// DOC INIT 
    	String gShopCode = '';
		
		TestCommon.createBillSimplePaymentConfigDoc();
		TestCommon.createBillSimpleHelpConfigDoc();
    	//getCsvSetupConfig1();
    	Date tday = Date.today();
    	// お客様作成
    	Contact cont = TestCommon.createContact();
    	// 取引先作成
    	Account acc = TestCommon.createNormalAccount();
    	// 取引先関連の口座作成
		// 口座情報の作成
		String shopAccLocalName = ShopAccountInfo__c.sObjectType.getDescribe().getName();
        List<RecordType> rts = [SELECT Id,Name FROM RecordType WHERE SobjectType  = :shopAccLocalName];
     	String kouzaIds = TestCommon.createShopBankAccount(1,acc,rts,null);
    	// 取引先関連の手数料定義作成
    	list<ChargeInfo__c> chrLst1 = createTesuryo(acc);
    	list<ChargeInfo__c> chrLst2 = createTesuryo(acc);
    	createConfigDoc(chrLst2[0].Name);
  		// 予約作成
		List<Lead__c> leads = TestCommon.createLead(tday,1,1,cont.Id);
		lead__c lead = leads[0];
		lead.SalesOfficeInfoRef__c= acc.id;
        // 予約情報のステータス：チェックインに変更する
        lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update lead;
    	cont.accountId = null;
    	update cont;
		Test.startTest();
    	// 会計情報を作成する
		//String todayStr = DateTime.newInstance(tday.year(),tday.month(),tday.day()).format('yyyyMMMdd');
		RsvAccount__c rsv = [select id,name from RsvAccount__c limit 1];
		// 会計支払商品を作成、関連の手数料情報を定義する
 		List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c,Relreserve__r.Relcontact__r.AccountId,Relreserve__r.Relcontact__c,Relreserve__r.SalesOfficeInfoRef__c from AccountAcount__c where Relreserve__c = :lead.Id];
        AccountAcount__c accObj = accObjLst[0];
        // カード支払商品を作成する
        List<AccountMaster__c> payAccs = TestCommon.createPayProductMst(new set<string>{Label.CONST_012_0439});
        AccountMaster__c payAcc = payAccs[0];
        // 該当商品の手数料と口座情報を作成する
        payAcc.CardAccountRef__c = acc.Id;
        update payAcc;
        ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
        BillSimpleInputCtrl ctrl = new BillSimpleInputCtrl(contrl);
        ctrl.initAction();
        List<BillSimpleInputCtrl.TranItem> rsTranItems = ctrl.oTranSobjLst;
        rsTranItems[1].productNm = payAcc.Name;
        rsTranItems[1].sobj.Field7__c = payAcc.Id;
        rsTranItems[1].sobj.ActionType__c = payAcc.ActionType__c;
        rsTranItems[1].sobj.PaymentType__c = payAcc.PaymentType__c;
        rsTranItems[1].tranId = '';
        rsTranItems[1].accRefId = '';
        rsTranItems[1].usedAmount = 30000;
        rsTranItems[1].sobj.Field20__c = '30000';
        rsTranItems[1].sobj.Field21__c = '1';
        
        ctrl.upsertData();
        
		AccountingSyncBatchHelp config = new AccountingSyncBatchHelp(gShopCode);
		PurchaseManagentProcess pur = new PurchaseManagentProcess(tday,gShopCode,config);
		pur.generalNetAgtSalesRate();
		pur.generalCardSalesRate();
		
		Test.stopTest();
    }

	static testMethod void tesuryoAgtCase001() {
    	
    	// DOC INIT 
    	String gShopCode = '';
		
		TestCommon.createBillSimplePaymentConfigDoc();
		TestCommon.createBillSimpleHelpConfigDoc();
    	//getCsvSetupConfig1();
    	Date tday = Date.today();
    	// お客様作成
    	Contact cont = TestCommon.createContact();
    	// 取引先作成
    	Account acc = TestCommon.createNormalAccount();
    	acc.ChargeCalKbnLst__c = '月単位';
    	String todayStr = System.now().format('yyyyMMdd');
    	acc.ChargeCalDateLst__c = todayStr.substring(6);
    	acc.RoundType__c = '切り捨て';
    	update acc;
    	// 取引先関連の口座作成
		// 口座情報の作成
		String shopAccLocalName = ShopAccountInfo__c.sObjectType.getDescribe().getName();
        List<RecordType> rts = [SELECT Id,Name FROM RecordType WHERE SobjectType  = :shopAccLocalName];
     	String kouzaIds = TestCommon.createShopBankAccount(1,acc,rts,null);
    	// 取引先関連の手数料定義作成
    	list<ChargeInfo__c> chrLst1 = createTesuryo(acc);
    	list<ChargeInfo__c> chrLst2 = createTesuryo(acc);
    	createConfigDoc(chrLst2[0].Name);
  		// 予約作成
		List<Lead__c> leads = TestCommon.createLead(tday,1,1,cont.Id);
		lead__c lead = leads[0];
		lead.SalesOfficeInfoRef__c= acc.id;
        // 予約情報のステータス：チェックインに変更する
        lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update lead;
    	cont.accountId = null;
    	update cont;
		Test.startTest();
    	// 会計情報を作成する
		//String todayStr = DateTime.newInstance(tday.year(),tday.month(),tday.day()).format('yyyyMMMdd');
		RsvAccount__c rsv = [select id,name from RsvAccount__c limit 1];
		// 会計支払商品を作成、関連の手数料情報を定義する
 		List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c,Relreserve__r.Relcontact__r.AccountId,Relreserve__r.Relcontact__c,Relreserve__r.SalesOfficeInfoRef__c from AccountAcount__c where Relreserve__c = :lead.Id];
        AccountAcount__c accObj = accObjLst[0];
        // キャンセル料会計商品
        List<AccountMaster__c> cancelList = TestCommon.createProductMst(1);
        AccountMaster__c cancelAcc = cancelList[0];
        cancelAcc.Field3__c = '800001';
        update cancelAcc;
        // カード支払商品を作成する
        List<AccountMaster__c> payAccs = TestCommon.createPayProductMst(new set<string>{Label.CONST_012_0439, Label.CONST_012_0441});
        AccountMaster__c payAcc = payAccs[0];
        AccountMaster__c prePay = payAccs[1];
        // 該当商品の手数料と口座情報を作成する
        payAcc.CardAccountRef__c = acc.Id;
        update payAcc;
        prePay.Field3__c = 'M90201';
        update prePay;
        ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
        BillSimpleInputCtrl ctrl = new BillSimpleInputCtrl(contrl);
        ctrl.initAction();
        List<BillSimpleInputCtrl.TranItem> rsTranItems = ctrl.oTranSobjLst;
        rsTranItems[1].productNm = payAcc.Name;
        rsTranItems[1].sobj.Field7__c = payAcc.Id;
        rsTranItems[1].sobj.ActionType__c = payAcc.ActionType__c;
        rsTranItems[1].sobj.PaymentType__c = payAcc.PaymentType__c;
        rsTranItems[1].tranId = '';
        rsTranItems[1].accRefId = '';
        rsTranItems[1].usedAmount = 15000;
        rsTranItems[1].sobj.Field20__c = '15000';
        rsTranItems[1].sobj.Field21__c = '1';

        rsTranItems[2].productNm = prePay.Name;
        rsTranItems[2].sobj.Field7__c = prePay.Id;
        rsTranItems[2].sobj.ActionType__c = prePay.ActionType__c;
        rsTranItems[2].sobj.PaymentType__c = prePay.PaymentType__c;
        rsTranItems[2].tranId = '';
        rsTranItems[2].accRefId = '';
        rsTranItems[2].usedAmount = 20000;
        rsTranItems[2].sobj.Field20__c = '20000';
        rsTranItems[2].sobj.Field21__c = '1';
        
        rsTranItems[3].productNm = cancelAcc.Name;
        rsTranItems[3].sobj.Field7__c = cancelAcc.Id;
        rsTranItems[3].sobj.ActionType__c = cancelAcc.ActionType__c;
        rsTranItems[3].sobj.PaymentType__c = cancelAcc.PaymentType__c;
        rsTranItems[3].tranId = '';
        rsTranItems[3].accRefId = '';
        rsTranItems[3].usedAmount = 10000;
        rsTranItems[3].sobj.Field20__c = '10000';
        rsTranItems[3].sobj.Field21__c = '1';
        ctrl.upsertData();
        
		AccountingSyncBatchHelp config = new AccountingSyncBatchHelp(gShopCode);
		PurchaseManagentProcess pur = new PurchaseManagentProcess(tday,gShopCode,config);
		pur.generalNetAgtSalesRate();
		pur.generalCardSalesRate();
		
		Test.stopTest();
    }
	// 集計単位は会計単位
	static testMethod void tesuryoAgtCase002() {
    	
    	// DOC INIT 
    	String gShopCode = '';
		
		TestCommon.createBillSimplePaymentConfigDoc();
		TestCommon.createBillSimpleHelpConfigDoc();
    	//getCsvSetupConfig1();
    	Date tday = Date.today();
    	// お客様作成
    	Contact cont = TestCommon.createContact();
    	// 取引先作成
    	Account acc = TestCommon.createNormalAccount();
    	//acc.ChargeCalKbnLst__c = '月単位';
    	//acc.ChargeCalDateLst__c = String.valueOf(Date.today().day());
    	update acc;
    	// 取引先関連の口座作成
		// 口座情報の作成
		String shopAccLocalName = ShopAccountInfo__c.sObjectType.getDescribe().getName();
        List<RecordType> rts = [SELECT Id,Name FROM RecordType WHERE SobjectType  = :shopAccLocalName];
     	String kouzaIds = TestCommon.createShopBankAccount(1,acc,rts,null);
    	// 取引先関連の手数料定義作成
    	list<ChargeInfo__c> chrLst1 = createTesuryo(acc);
    	list<ChargeInfo__c> chrLst2 = createTesuryo(acc);
    	createConfigDoc(chrLst2[0].Name);
  		// 予約作成
		List<Lead__c> leads = TestCommon.createLead(tday,1,1,cont.Id);
		lead__c lead = leads[0];
		lead.SalesOfficeInfoRef__c= acc.id;
        // 予約情報のステータス：チェックインに変更する
        lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update lead;
    	cont.accountId = null;
    	update cont;
		Test.startTest();
    	// 会計情報を作成する
		//String todayStr = DateTime.newInstance(tday.year(),tday.month(),tday.day()).format('yyyyMMMdd');
		RsvAccount__c rsv = [select id,name from RsvAccount__c limit 1];
		// 会計支払商品を作成、関連の手数料情報を定義する
 		List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c,Relreserve__r.Relcontact__r.AccountId,Relreserve__r.Relcontact__c,Relreserve__r.SalesOfficeInfoRef__c from AccountAcount__c where Relreserve__c = :lead.Id];
        AccountAcount__c accObj = accObjLst[0];
        // キャンセル料会計商品
        List<AccountMaster__c> cancelList = TestCommon.createProductMst(1);
        AccountMaster__c cancelAcc = cancelList[0];
        cancelAcc.Field3__c = '800001';
        update cancelAcc;
        // カード支払商品を作成する
        List<AccountMaster__c> payAccs = TestCommon.createPayProductMst(new set<string>{Label.CONST_012_0439, Label.CONST_012_0441});
        AccountMaster__c payAcc = payAccs[0];
        AccountMaster__c prePay = payAccs[1];
        // 該当商品の手数料と口座情報を作成する
        payAcc.CardAccountRef__c = acc.Id;
        update payAcc;
        prePay.Field3__c = 'M90201';
        update prePay;
        ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
        BillSimpleInputCtrl ctrl = new BillSimpleInputCtrl(contrl);
        ctrl.initAction();
        List<BillSimpleInputCtrl.TranItem> rsTranItems = ctrl.oTranSobjLst;
        rsTranItems[1].productNm = payAcc.Name;
        rsTranItems[1].sobj.Field7__c = payAcc.Id;
        rsTranItems[1].sobj.ActionType__c = payAcc.ActionType__c;
        rsTranItems[1].sobj.PaymentType__c = payAcc.PaymentType__c;
        rsTranItems[1].tranId = '';
        rsTranItems[1].accRefId = '';
        rsTranItems[1].usedAmount = 15000;
        rsTranItems[1].sobj.Field20__c = '15000';
        rsTranItems[1].sobj.Field21__c = '1';

        rsTranItems[2].productNm = prePay.Name;
        rsTranItems[2].sobj.Field7__c = prePay.Id;
        rsTranItems[2].sobj.ActionType__c = prePay.ActionType__c;
        rsTranItems[2].sobj.PaymentType__c = prePay.PaymentType__c;
        rsTranItems[2].tranId = '';
        rsTranItems[2].accRefId = '';
        rsTranItems[2].usedAmount = 20000;
        rsTranItems[2].sobj.Field20__c = '20000';
        rsTranItems[2].sobj.Field21__c = '1';
        
        rsTranItems[3].productNm = cancelAcc.Name;
        rsTranItems[3].sobj.Field7__c = cancelAcc.Id;
        rsTranItems[3].sobj.ActionType__c = cancelAcc.ActionType__c;
        rsTranItems[3].sobj.PaymentType__c = cancelAcc.PaymentType__c;
        rsTranItems[3].tranId = '';
        rsTranItems[3].accRefId = '';
        rsTranItems[3].usedAmount = 10000;
        rsTranItems[3].sobj.Field20__c = '10000';
        rsTranItems[3].sobj.Field21__c = '1';
        ctrl.upsertData();
        
		AccountingSyncBatchHelp config = new AccountingSyncBatchHelp(gShopCode);
		PurchaseManagentProcess pur = new PurchaseManagentProcess(tday,gShopCode,config);
		pur.generalNetAgtSalesRate();
		pur.generalCardSalesRate();
		pur.clearExistDate();
		Test.stopTest();
    }
    // 予約情報きキャンセル料金計算
	// 集計単位は月単位
	static testMethod void tesuryoAgtCase003() {
    	
    	// DOC INIT 
    	String gShopCode = '';
		TestCommon.createCancelRuleDefine(gShopCode);
		TestCommon.createBillSimplePaymentConfigDoc();
		TestCommon.createBillSimpleHelpConfigDoc();
    	//getCsvSetupConfig1();
    	Date tday = Date.today();
    	// お客様作成
    	Contact cont = TestCommon.createContact();
    	// 取引先作成
    	Account acc = TestCommon.createNormalAccount();
    	// 取引先関連の口座作成
		// 口座情報の作成
		String shopAccLocalName = ShopAccountInfo__c.sObjectType.getDescribe().getName();
        List<RecordType> rts = [SELECT Id,Name FROM RecordType WHERE SobjectType  = :shopAccLocalName];
     	String kouzaIds = TestCommon.createShopBankAccount(1,acc,rts,null);
    	// 取引先関連の手数料定義作成
    	list<ChargeInfo__c> chrLst1 = createTesuryo(acc);
    	list<ChargeInfo__c> chrLst2 = createTesuryo(acc);
    	createConfigDoc(chrLst2[0].Name);
  		// 予約作成
		List<Lead__c> leads = TestCommon.createLead(tday,1,1,cont.Id);
		lead__c lead = leads[0];
		lead.SalesOfficeInfoRef__c= acc.id;
        // 予約情報のステータス：チェックインに変更する
        //lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
        // キャンセル処理
        lead.ReservedStatus__c = CommConst.LEAD_ST_CANCEL;
        update lead;
    	cont.accountId = null;
    	update cont;
		Test.startTest();
    	// 会計情報を作成する
		AccountingSyncBatchHelp config = new AccountingSyncBatchHelp(gShopCode);
		PurchaseManagentProcess pur = new PurchaseManagentProcess(tday,gShopCode,config);
		pur.generalNetAgtSalesRate();
		pur.generalCardSalesRate();
		
		Test.stopTest();
    }
    // 予約情報きキャンセル料金計算
	// 集計単位は月単位
	static testMethod void tesuryoAgtCase003_1() {
    	
    	// DOC INIT 
    	String gShopCode = '';
		TestCommon.createCancelRuleDefine(gShopCode);
		TestCommon.createBillSimplePaymentConfigDoc();
		TestCommon.createBillSimpleHelpConfigDoc();
    	//getCsvSetupConfig1();
    	Date tday = Date.today();
    	// お客様作成
    	Contact cont = TestCommon.createContact();
    	// 取引先作成
    	Account acc = TestCommon.createNormalAccount();
    	// 取引先関連の口座作成
		// 口座情報の作成
		String shopAccLocalName = ShopAccountInfo__c.sObjectType.getDescribe().getName();
        List<RecordType> rts = [SELECT Id,Name FROM RecordType WHERE SobjectType  = :shopAccLocalName];
     	String kouzaIds = TestCommon.createShopBankAccount(1,acc,rts,null);
    	// 取引先関連の手数料定義作成
    	list<ChargeInfo__c> chrLst1 = createTesuryo(acc);
    	list<ChargeInfo__c> chrLst2 = createTesuryo(acc);
    	createConfigDoc(chrLst2[0].Name);
  		// 予約作成
		List<Lead__c> leads = TestCommon.createLead(tday,1,1,cont.Id);
		lead__c lead = leads[0];
		lead.SalesOfficeInfoRef__c= acc.id;
        // 予約情報のステータス：チェックインに変更する
        //lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
        // キャンセル処理
        lead.ReservedStatus__c = CommConst.LEAD_ST_CANCEL;
        update lead;
    	cont.accountId = null;
    	update cont;
		Test.startTest();
    	// 会計情報を作成する
		AccountingSyncBatchHelp config = new AccountingSyncBatchHelp(gShopCode);
		PurchaseManagentProcess pur = new PurchaseManagentProcess(tday.addDays(1),gShopCode,config);
		pur.generalNetAgtSalesRate();
		pur.generalCardSalesRate();
		
		Test.stopTest();
    }
    
    private static void createConfigDoc(String tesuryoNo) {
    	
    	String configXml = '<?xml version="1.0" encoding="utf-8"?><root><!-- 概要：銀行振り込み情報作成の関連定義情報 --><SHOP><!-- デフォルト設定情報、削除しない、支店舗追加したい場合、このＮＯＤＥコピーして、後ろに追加してください --><SHOPCODE></SHOPCODE><ROUND_TYPE>1</ROUND_TYPE><!-- 手数料の端数処理区分 0:切り捨て / 1:四捨五入 / 2:切り上げ --><!-- 処理通知先メールアドレス,「,」で複数メールアドレス定義可能（５個まで） --><RESULT_MAIL>test11111@1111cccsss999.com</RESULT_MAIL><!-- 銀行へ通信電文関連定義情報 --><!-- 銀行振り込み手数料:必須 --><BANK_TRANS_RATE><SAME_BANK><!-- 同銀行 --><SAME_BRANCH><!-- 同支店 --><RANK_LEVEL><MIN_VAL>0</MIN_VAL><MAX_VAL>9999</MAX_VAL><RATE>0</RATE></RANK_LEVEL><RANK_LEVEL><MIN_VAL>10000</MIN_VAL><MAX_VAL>29999</MAX_VAL><RATE>0</RATE></RANK_LEVEL><RANK_LEVEL><MIN_VAL>30000</MIN_VAL><RATE>0</RATE></RANK_LEVEL></SAME_BRANCH><DIFF_BRANCH><!-- 別支店 --><RANK_LEVEL><MIN_VAL>0</MIN_VAL><MAX_VAL>9999</MAX_VAL><RATE>108</RATE></RANK_LEVEL><RANK_LEVEL><MIN_VAL>10000</MIN_VAL><MAX_VAL>29999</MAX_VAL><RATE>108</RATE></RANK_LEVEL><RANK_LEVEL><MIN_VAL>30000</MIN_VAL><RATE>324</RATE></RANK_LEVEL></DIFF_BRANCH></SAME_BANK><DIFF_BANK><!-- 別銀行 --><RANK_LEVEL><MIN_VAL>0</MIN_VAL><MAX_VAL>9999</MAX_VAL><RATE>324</RATE></RANK_LEVEL><RANK_LEVEL><MIN_VAL>10000</MIN_VAL><MAX_VAL>29999</MAX_VAL><RATE>432</RATE></RANK_LEVEL><RANK_LEVEL><MIN_VAL>30000</MIN_VAL><RATE>648</RATE></RANK_LEVEL></DIFF_BANK></BANK_TRANS_RATE><!-- 口座情報定義する --><BANK_KOZAINFO><PUR_SETTLEMENT><!-- 買掛決済バッチ --><KOUZA_SEQ>2</KOUZA_SEQ><!-- 店舗口座情報#SEQ値 --><DESCRIPT>仕入支払口座</DESCRIPT><TRANS_TYPE>21</TRANS_TYPE><!-- 業務種別:21:総合 11または71:給与 12または72:賞与 --></PUR_SETTLEMENT></BANK_KOZAINFO><BANK_TELEGRAM_HEADER><DATA_KBN>1</DATA_KBN><!-- レコード種別:1:ヘッダレコード --><MESSAGE_LAYOUT>$$_データ区分_$$$$_種別コード_$$$$_コード区分_$$$$_委託者コード_$$$$_委託者名_$$$$_取組日_$$$$_仕向金融機関番号_$$$$_仕向金融機関名_$$$$_仕向支店番号_$$$$_仕向支店名_$$$$_預金種目(依頼人)_$$$$_口座番号(依頼人)_$$$$_ダミー_$$</MESSAGE_LAYOUT></BANK_TELEGRAM_HEADER><BANK_TELEGRAM_DETAIL><DATA_KBN>2</DATA_KBN><!-- レコード種別:2:データレコード --><IS_EDI>FALSE</IS_EDI><!-- EDI情報を使う --><IS_PLUSFORMAT>TRUE</IS_PLUSFORMAT><!-- $$_支払金額_$$,$$_先方負担手数料_$$,$$_振込手数料_$$追加情報を出力するがどうか --><!-- $$_識別表示_$$はYの場合、$$_顧客コード1_$$,$$_顧客コード2_$$全部長さ０空白文字を差し替え、$$_EDI情報_$$を設定する、 $$_識別表示_$$はY以外の場合、$$_顧客コード1_$$,$$_顧客コード2_$$は別々１０桁まで設定する、$$_EDI情報_$$は長さ０の空白文字を差し替え --><MESSAGE_LAYOUT>$$_データ区分_$$$$_被仕向金融機関番号_$$$$_被仕向金融機関名_$$$$_被仕向支店番号_$$$$_被仕向支店名_$$$$_手形交換所番号_$$$$_預金種目_$$$$_口座番号_$$$$_受取人名_$$$$_振込金額_$$$$_新規コード_$$$$_顧客コード1_$$$$_顧客コード2_$$$$_EDI情報_$$$$_振込区分_$$$$_識別表示_$$$$_ダミー_$$$$_支払金額_$$$$_先方負担手数料_$$$$_振込手数料_$$</MESSAGE_LAYOUT></BANK_TELEGRAM_DETAIL><BANK_TELEGRAM_TRAILER><DATA_KBN>8</DATA_KBN><!-- レコード種別:8:トレーラレコード --><MESSAGE_LAYOUT>$$_データ区分_$$$$_合計件数_$$$$_合計金額_$$$$_ダミー_$$</MESSAGE_LAYOUT></BANK_TELEGRAM_TRAILER><BANK_TELEGRAM_END><DATA_KBN>9</DATA_KBN><!-- レコード種別:9:エンドレコード --><MESSAGE_LAYOUT>$$_データ区分_$$$$_ダミー_$$</MESSAGE_LAYOUT></BANK_TELEGRAM_END><!-- カード販売手数料計算関連 --><CARD_SALESRATE><I_TYPENAME>支払手数料</I_TYPENAME><O_KAMOKU>買掛（月末振込）</O_KAMOKU></CARD_SALESRATE><AGT_SALESRATE><I_TYPENAME>販売手数料</I_TYPENAME><!-- 種別 --><O_KAMOKU>買掛（月末振込）</O_KAMOKU><!-- 科目 --><HOLIDAY_INC_SAT>FALSE</HOLIDAY_INC_SAT><!-- 休日定義に、土曜日は休日として定義する/しない制御　TRUE:休日、FALSE：休日外(デフォルト値) --><CHARGERATE_LOGIC><FILTER TESURYONO="$$_TESURYONO_$$"><!-- 該当手数料番号に関連のご予約の抽出条件 --><DESCRIPT>I.JTB/HR(宿泊)</DESCRIPT><LOGIC>{0}</LOGIC><COONDITION>Relreserve__r.StayNightCal__c > 0</COONDITION></FILTER></CHARGERATE_LOGIC><CANCEL_CODE>800001</CANCEL_CODE><SALES_TARGETOUT>「現地追加」</SALES_TARGETOUT><PRE_PAYMENT_INFO><PRE_PAYMENT RATE="2.5">M90201</PRE_PAYMENT></PRE_PAYMENT_INFO></AGT_SALESRATE></SHOP></root>';
    	if (CommUtils.isBlank(tesuryoNo)) tesuryoNo = '';
    	configXml.replace('$$_TESURYONO_$$',configXml);
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'AccountingSyncBatchConfig';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(configXml);
    	insert item;
    	
    	TestCommon.createDeviceConfigXml();
    }
    private static list<ChargeInfo__c> createTesuryo(Account acc) {
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
    		CategoryMain__c = AccountingSyncBatchHelp.TESURYO_DIV_CARD,
    		AccountRef__c = acc.Id,
    		PayChargeFlg__c = true
    	);
    	insLst.add(chrg);
    	insert insLst;
    	list<id> ids = new list<id>{insLst[0].id,insLst[1].Id};
    	return [select id,name,SalesRate__c,AccountRef__c from ChargeInfo__c where id in :ids];
    }

}