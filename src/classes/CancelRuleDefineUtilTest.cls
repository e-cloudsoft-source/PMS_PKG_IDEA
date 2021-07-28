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
private class CancelRuleDefineUtilTest {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        List<CancelRuleDefine__c> canCelLst = CancelRuleDefineUtil.getCancelRuleDefineByShopCode('01');
        system.assertEquals(canCelLst.size(), 0, canCelLst);
    }
    static testMethod void myUnitTest2() {
        createCancelRule('01');
        List<CancelRuleDefine__c> canCelLst = CancelRuleDefineUtil.getCancelRuleDefineByShopCode('02');
        system.assertEquals(canCelLst.size(), 1, canCelLst);
        system.assertEquals(canCelLst[0].CancelRate__c, 80);
        canCelLst = CancelRuleDefineUtil.getCancelRuleDefineByShopCode('01');
        system.assertEquals(canCelLst.size(), 1, canCelLst);
    	system.assertEquals(canCelLst[0].CancelRate__c, 100);
    }
    // キャンセル料金自動計算[キャンセル商品見設定の場合、キャンセル料金計算対象外]
    static testMethod void myUnitTest3() {
    	createCancelRule('');
    	// 支払情報
    	TestCommon.createBillSimpleHelpConfigDoc();
    	// キャンセル商品コード設定
    	TestCommon.createTesuryoConfigDoc();
		Date startDt = date.today();
		Contact cinf = TestCommon.createContact();
    	list<Lead__c> leadInfos = TestCommon.createLead(startDt,1,1,cinf.Id);
    	// 予約の日付を更新を行う
    	leadInfos[0].ReservedStatus__c = CommConst.LEAD_ST_CANCEL;
    	update leadInfos;
    }
    // キャンセル料金自動計算
    static testMethod void myUnitTest4() {
    	createCancelRule('');
    	// 支払情報
    	TestCommon.createBillSimpleHelpConfigDoc();
    	// キャンセル商品コード設定
    	TestCommon.createTesuryoConfigDoc();
    	// 指定の会計商品を作成する　
    	List<AccountMaster__c> accMst = TestCommon.createProductMst(1);
    	accMst[0].Field3__c = '800001';
    	update accMst;
    	
		Date startDt = date.today();
		Contact cinf = TestCommon.createContact();
    	list<Lead__c> leadInfos = TestCommon.createLead(startDt,1,1,cinf.Id);
    	// 予約の日付を更新を行う
    	leadInfos[0].ReservedStatus__c = CommConst.LEAD_ST_CANCEL;
    	update leadInfos;
    }
    // キャンセル料金自動計算[キャンセル商品存在、支払商品も存在]
    static testMethod void myUnitTest5() {
    	createCancelRule('');
    	// 支払情報
    	TestCommon.createBillSimpleHelpConfigDoc();
    	// キャンセル商品コード設定
    	TestCommon.createTesuryoConfigDoc();
    	// 指定の会計商品を作成する　
    	List<AccountMaster__c> accMst = TestCommon.createProductMst(2);
    	accMst[0].Field3__c = '800001';
    	accMst[0].Field3__c = 'M99002';
    	update accMst;
    	
		Date startDt = date.today();
		Contact cinf = TestCommon.createContact();
    	list<Lead__c> leadInfos = TestCommon.createLead(startDt,1,1,cinf.Id);
    	// 予約の日付を更新を行う
    	leadInfos[0].ReservedStatus__c = CommConst.LEAD_ST_CANCEL;
    	update leadInfos;
    }
    private static void createCancelRule(String shopCd) {
    	CancelRuleDefine__c cancelDef1 = new CancelRuleDefine__c(
    		Name = 'キャンセルルール０１'
    		,RuleBefDayNums__c = 0
    		,CancelRate__c = 80
    		,ShopCode__c = ''
    	);
    	CancelRuleDefine__c cancelDef2 = new CancelRuleDefine__c(
    		Name = 'キャンセルルール０２'
    		,RuleBefDayNums__c = 0
    		,CancelRate__c = 100
    		,ShopCode__c = shopCd
    	);
    	list<CancelRuleDefine__c> insLst = new list<CancelRuleDefine__c>();
    	insLst.add(cancelDef1);
    	insLst.add(cancelDef2);
    	insert insLst;
    }
}