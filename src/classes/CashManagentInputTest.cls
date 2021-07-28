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
private class CashManagentInputTest {
	// 入金情報を新規追加する[支店なし]
    static testMethod void TestDesp_01() {
    	// ユーザーの店舗コードがNULLに設定する
		User currUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	currUser.ShopCode__c = null;
    	update currUser;
    	system.runAs(currUser) {
    		Id contactId = TestCommon.createContact().Id;
		 	//Test.setCurrentPageReference(new PageReference('Page.CashManagentInput')); 
			System.currentPageReference().getParameters().put('pm', CashManagentInput.CONST_PAGE_MODE_IN);
			CashManagentInput ctrl = new CashManagentInput();
			ctrl.init();
			// Page Mode Confirm
			System.assertEquals(ctrl.input.pageMode, CashManagentInput.CONST_PAGE_MODE_IN, ctrl.input.pageMode);
			// 情報を入力する
			ctrl.editRowIdx = 0;
			ctrl.input.pageMode = CashManagentInput.CONST_PAGE_MODE_IN;
			List<CashManagentInput.ItemInfo> deposLists = ctrl.deposList;
			System.assertEquals(deposLists.size(), 1, deposLists);
			// 1件新規のみ
			//CashManagentInput.ItemInfo firstItem = deposLists[0];
			deposit__c input = ctrl.inpData.dep;
			input.SalesDate__c = deposLists[0].dep.SalesDate__c;
			input.deposit__c = contactId;
			input.Kamoku__c  = 'テスト１科目';
			input.deposititem__c = '摘要テスト';
			input.depositamount__c = 50000;
			ctrl.dataUpsert();
			// 新規後、2件データになる、1件名は編集、2件名は表示Readonly、合計値は 50000
			System.assertEquals(ctrl.depAmount, 50000, ctrl.depAmount);
			deposLists = ctrl.deposList;
			System.assertEquals(deposLists.size(), 2, deposLists);
			
			deposit__c input2 = ctrl.inpData.dep;
			input2.SalesDate__c = deposLists[0].dep.SalesDate__c;
			input2.deposit__c = contactId;
			input2.Kamoku__c  = 'テスト2科目';
			input2.deposititem__c = '摘要テスト2';
			input2.depositamount__c = 60000;
			ctrl.dataUpsert();
			System.assertEquals(ctrl.depAmount, 110000, ctrl.depAmount);
			deposLists = ctrl.deposList;
			System.assertEquals(deposLists.size(), 3, deposLists);
			// 初期登録データは別の営業日に変更する
			ctrl.editRowIdx = 2;
			ctrl.input.pageMode = CashManagentInput.CONST_PAGE_MODE_IN;
			ctrl.historyEdit(); // 編集
			deposLists = ctrl.deposList;
			System.assertEquals(deposLists.size(), 3, deposLists);
			CashManagentInput.ItemInfo item = deposLists[2];
			System.assert(!item.isReadOnly);
			// 売上日を変更する
			ctrl.editRowIdx = 2;
			ctrl.input.pageMode = CashManagentInput.CONST_PAGE_MODE_IN;
			
			deposit__c input3 = ctrl.inpData.dep;
			input3.SalesDate__c = item.dep.SalesDate__c.addDays(1);
			input3.deposit__c = contactId;
			input3.Kamoku__c  = 'テスト１科目';
			input3.deposititem__c = '摘要テスト1';
			input3.depositamount__c = 70000;
			ctrl.dataUpsert();
			// 別の売上に変更する
			// 新規後、2件データになる、1件名は編集、2件名は表示Readonly、合計値は 50000
			System.assertEquals(ctrl.depAmount, deposLists[1].dep.depositamount__c, ctrl.depAmount);
			deposLists = ctrl.deposList;
			System.assertEquals(deposLists.size(), 2, deposLists);
			
			ctrl.editRowIdx = 1;
			ctrl.input.pageMode = CashManagentInput.CONST_PAGE_MODE_IN;
			ctrl.historyEdit(); // 編集
			ctrl.dataRollBack();
			
			// 过滤条件Json作成
			Map<String,List<String>> filterDsMap = new Map<String,List<String>>();
			filterDsMap.put('depCreateUser', new List<String>{ctrl.depFilter.createUserLst[0].get('createUser')});
			filterDsMap.put('depKamoku', new List<String>{ctrl.depFilter.kamokuLst[0].get('kamoku')});
			filterDsMap.put('depSalesDate', new List<String>{ctrl.depFilter.salesDateLst[0].get('salesDate')});
			filterDsMap.put('depositId', new List<String>{ctrl.depFilter.depositLst[0].get('depositId')});
			ctrl.depFilter.filterDataJson = JSON.serialize(filterDsMap);
			
			// 削除処理
			ctrl.deleteRowIdxs = '1';
			ctrl.input.pageMode = CashManagentInput.CONST_PAGE_MODE_IN;
			ctrl.deleteData();
			deposLists = ctrl.deposList;
			System.assertEquals(deposLists.size(), 1, deposLists);
			
			// 売上日変更
			ctrl.input.pageMode = CashManagentInput.CONST_PAGE_MODE_IN;
			ctrl.input.depToDateInput.Checkinday__c = Date.today().addDays(1);
			ctrl.changeSalesDate();
			deposLists = ctrl.deposList;
			System.assertEquals(deposLists.size(), 2, deposLists);
    	}
    }
    
	// 入金情報を新規追加する[支店なし]
    static testMethod void TestPay_01() {
    	// ユーザーの店舗コードがNULLに設定する
 		User currUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	currUser.ShopCode__c = null;
    	update currUser;
    	system.runAs(currUser) {
    		Id contactId = TestCommon.createContact().Id;
		 	//Test.setCurrentPageReference(new PageReference('Page.CashManagentInput')); 
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
			input.Pkamoku__c  = 'テスト１科目';
			input.Pitem__c = '摘要テスト';
			input.Pamount__c = 50000;
			ctrl.dataUpsert();
			// 新規後、2件データになる、1件名は編集、2件名は表示Readonly、合計値は 50000
			System.assertEquals(ctrl.payAmount, 50000, ctrl.payAmount);
			paymentLists = ctrl.paymentList;
			System.assertEquals(paymentLists.size(), 2, paymentLists);
			
			Paymentslip__c input2 = ctrl.inpData.pay;
			input2.SalesDate__c = paymentLists[0].pay.SalesDate__c;
			input2.Pkamoku__c  = 'テスト１科目';
			input2.Pitem__c = '摘要テスト';
			input2.Pamount__c = 60000;
			ctrl.dataUpsert();
			System.assertEquals(ctrl.payAmount, 110000, ctrl.payAmount);
			paymentLists = ctrl.paymentList;
			System.assertEquals(paymentLists.size(), 3, paymentLists);
			// 初期登録データは別の営業日に変更する
			ctrl.editRowIdx = 2;
			ctrl.input.pageMode = CashManagentInput.CONST_PAGE_MODE_OU;
			ctrl.historyEdit(); // 編集
			paymentLists = ctrl.paymentList;
			System.assertEquals(paymentLists.size(), 3, paymentLists);
			CashManagentInput.ItemInfo item = paymentLists[2];
			System.assert(!item.isReadOnly);
			// 売上日を変更する
			ctrl.editRowIdx = 2;
			ctrl.input.pageMode = CashManagentInput.CONST_PAGE_MODE_OU;
			
			Paymentslip__c input3 = ctrl.inpData.pay;
			input3.SalesDate__c = item.pay.SalesDate__c.addDays(1);
			input3.Pkamoku__c  = 'テスト１科目';
			input3.Pitem__c = '摘要テスト';
			input3.Pamount__c = 50000;
			ctrl.dataUpsert();
			// 別の売上に変更する
			// 新規後、2件データになる、1件名は編集、2件名は表示Readonly、合計値は 50000
			System.assertEquals(ctrl.payAmount, paymentLists[1].pay.Pamount__c, ctrl.depAmount);
			paymentLists = ctrl.paymentList;
			System.assertEquals(paymentLists.size(), 2, paymentLists);
			
			ctrl.editRowIdx = 1;
			ctrl.input.pageMode = CashManagentInput.CONST_PAGE_MODE_OU;
			ctrl.historyEdit(); // 編集
			ctrl.dataRollBack();
			
			CashManagentInput.getAccount(contactId);
			// 过滤条件Json作成
			Map<String,List<String>> filterDsMap = new Map<String,List<String>>();
			filterDsMap.put('payCreateUser', new List<String>{ctrl.payFilter.createUserLst[0].get('createUser')});
			filterDsMap.put('payKamoku', new List<String>{ctrl.payFilter.kamokuLst[0].get('kamoku')});
			filterDsMap.put('paySalesDate', new List<String>{ctrl.payFilter.salesDateLst[0].get('salesDate')});
			ctrl.payFilter.filterDataJson = JSON.serialize(filterDsMap);
			
			// 削除処理
			ctrl.deleteRowIdxs = '1';
			ctrl.input.pageMode = CashManagentInput.CONST_PAGE_MODE_OU;
			ctrl.deleteData();
			paymentLists = ctrl.paymentList;
			System.assertEquals(paymentLists.size(), 1, paymentLists);

			ctrl.input.pageMode = CashManagentInput.CONST_PAGE_MODE_OU;
			ctrl.input.payToDateInput.Checkinday__c = Date.today().addDays(1);
			ctrl.changeSalesDate();
			paymentLists = ctrl.paymentList;
			System.assertEquals(paymentLists.size(), 2, paymentLists);
    	}
    }
	static testMethod void TestPay_02() {
		createConfigDoc();
		TestCommon.createTaxMst();
		CashManagentInput ctrl = new CashManagentInput();
		ctrl.init();
	}
	private static void createConfigDoc() {
        String configXml = '<?xml version="1.0" encoding="UTF-8"?><root>	<SHOP>		<SHOPCODE></SHOPCODE>		<!-- 入金 -->			<DEPOSIT>			<!--税リスト表示：デフォルト：false -->			<TAXSELECTFLG>true</TAXSELECTFLG>			<COLNUMSIZE>削除:3%,伝票#:6%,扱者:6%,入金日時:6%,店舗:15%,科目:12%,計上日:6%,入金先:12%,取引先:12%,摘要:16%,金額:3%,アクション:3%			</COLNUMSIZE>		</DEPOSIT>			<!-- 出金 -->		<PAYMENTSLIP>			<!--税リスト表示：デフォルト：false -->			<TAXSELECTFLG>true</TAXSELECTFLG>			<COLNUMSIZE>削除:3%,伝票#:6%,扱者:6%,出金日時:6%,店舗:15%,科目:12%,計上日:6%,出金先:12%,取引先:12%,摘要:16%,金額:3%,アクション:3%			</COLNUMSIZE>		</PAYMENTSLIP>	</SHOP></root>';
        // ドキュメントを作成する
        Document item = new Document();
        item.Name = 'CashManagentConfig';
        item.DeveloperName = item.Name;
        item.FolderId = UserInfo.getUserId();
        item.Body = Blob.valueOf(configXml);
        insert item;
    }
}