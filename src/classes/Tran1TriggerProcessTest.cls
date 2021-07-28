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
private class Tran1TriggerProcessTest {

    // 2015/10/18 [プラン明細個別設定情報]により、プラン明細自動展開する・しない処理追加 END
    static testMethod void myUnitTest() {

    	Test.startTest();
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(3);
    	//List<AccountMaster__c> productLst_sub = TestCommon.createProductMst(3);
    	//productLst.ActionType__c = CommConst.PROD_ACTION_TYPE_PL;
    	//update productLst;
		// プラン情報を作成する
		Plan__c plan = TestCommon.createPlan();
		Test.stopTest();
		// プラン明細情報を設定する
    	ApexPages.StandardController contrl = new ApexPages.StandardController(plan);
 		PlanProductSetup ctrl = new PlanProductSetup(contrl);
		List<PlanProductSetup.PlanDetail> planDeLst = ctrl.planDetailList;

		planDeLst[0].productNm = productLst[0].Name;
		planDeLst[0].sobj.AccountMasterRef__c = productLst[0].Id;
		planDeLst[0].sobj.Price__c = 10001;
		planDeLst[1].productNm = productLst[1].Name;
		planDeLst[1].sobj.AccountMasterRef__c = productLst[1].Id;
		planDeLst[1].sobj.Price__c = 20002;
		planDeLst[2].productNm = productLst[2].Name;
		planDeLst[2].sobj.AccountMasterRef__c = productLst[2].Id;
		planDeLst[2].sobj.Price__c = 30003;
		ctrl.savePlanDetail();

		leadInfo.Field310__c = plan.id;

    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	// 予約情報のステータス：チェックインに変更する
    	leadInfo.Field298__c = 'チェックイン完';
    	update leadInfo;
    	System.assertEquals(5, [select id from BookingEstimateItem__c where refBooking__c = :leadInfo.Id].size(), [select UnitPrice__c,ParentBookingItemRef__c from BookingEstimateItem__c where refBooking__c = :leadInfo.Id]);
		// 会計データを自動作成する
		// 作成した会計IDを取得する
		AccountAcount__c accObject = [select id from AccountAcount__c where Relreserve__c = :leadInfo.Id];
		System.assertEquals(5, [select id from Tran1__c where Field1__c = :accObject.Id].size());

    	// 削除処理を行う
    	delete [select id from Tran1__c where ActionType__c = :CommConst.PROD_ACTION_TYPE_PL and Field1__c = :accObject.Id];

    }
    
    // 課税・非課税混雑ケースの対応テスト
    static testMethod void noTaxIncDetail() {
   	Test.startTest();
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(3);
        // 2015/12/01 Assert BEGIN
        System.assertEquals(productLst.size(), 3);
        // 2015/12/01 Assert END
    	//List<AccountMaster__c> productLst_sub = TestCommon.createProductMst(3);
    	//productLst.ActionType__c = CommConst.PROD_ACTION_TYPE_PL;
    	//update productLst;
		// プラン情報を作成する
		Plan__c plan = TestCommon.createPlan();
		Test.stopTest();
		// プラン明細情報を設定する
    	ApexPages.StandardController contrl = new ApexPages.StandardController(plan);
 		PlanProductSetup ctrl = new PlanProductSetup(contrl);
		List<PlanProductSetup.PlanDetail> planDeLst = ctrl.planDetailList;

		planDeLst[0].productNm = productLst[0].Name;
		planDeLst[0].sobj.AccountMasterRef__c = productLst[0].Id;
		planDeLst[0].sobj.Price__c = 20000;
		planDeLst[1].productNm = productLst[1].Name;
		planDeLst[1].sobj.AccountMasterRef__c = productLst[1].Id;
		planDeLst[1].sobj.TaxRate__c = 0;
		planDeLst[1].sobj.Price__c = 15000;
		planDeLst[2].productNm = productLst[2].Name;
		planDeLst[2].sobj.AccountMasterRef__c = productLst[2].Id;
		planDeLst[2].sobj.Price__c = 10000;
		ctrl.savePlanDetail();

		leadInfo.Field310__c = plan.id;

    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	// 予約情報のステータス：チェックインに変更する
    	leadInfo.Field298__c = 'チェックイン完';
    	update leadInfo;
    	
    }
}