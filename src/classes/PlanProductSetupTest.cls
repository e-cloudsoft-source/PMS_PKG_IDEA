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
private class PlanProductSetupTest {

	// 自動チェックテスト
    static testMethod void myCheckinTest() {
    	Test.startTest();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(3);
    	// プラン作成
    	Plan__c plan = TestCommon.createPlan();
    	Test.stopTest();

    	ApexPages.StandardController contrl = new ApexPages.StandardController(plan);
 		PlanProductSetup ctrl = new PlanProductSetup(contrl);
		List<PlanProductSetup.PlanDetail> planDeLst = ctrl.planDetailList;

		planDeLst[0].productNm = productLst[0].Name;
		planDeLst[0].sobj.AccountMasterRef__c = productLst[0].Id;
		planDeLst[0].sobj.Price__c = 10000;
		planDeLst[1].productNm = productLst[1].Name;
		planDeLst[1].sobj.AccountMasterRef__c = productLst[1].Id;
		planDeLst[1].sobj.Price__c = 20000;
		planDeLst[2].productNm = productLst[2].Name;
		planDeLst[2].sobj.AccountMasterRef__c = productLst[2].Id;
		planDeLst[3].sobj.Price__c = 30000;

		ctrl.savePlanDetail();
		//ctrl.queryPlanDetailInfo();
		Pagereference page = ctrl.gotoBlack();
		System.assert(page != null);
    }
    // プラン新規作成する［入力チェック］
    static testmethod void newPlanTest() {
    	Plan__c plan = new Plan__c();
    	ApexPages.StandardController contrl = new ApexPages.StandardController(plan);
    	PlanProductSetup ctrl = new PlanProductSetup(contrl);
    	ctrl.savePlanDetail();
    	System.assert(Apexpages.hasMessages(ApexPages.Severity.ERROR));
    	System.assertEquals(Apexpages.getMessages().size(), 2);
    }
    static testmethod void newPlanTest2() {
    	Plan__c planMst = TestCommon.createPlan();
    	planMst.Seq__c = 12000;
    	update planMst;
    	Plan__c plan = new Plan__c();
    	ApexPages.StandardController contrl = new ApexPages.StandardController(plan);
    	PlanProductSetup ctrl = new PlanProductSetup(contrl);
    	ctrl.planInfo.PlanNo__c = planMst.PlanNo__c;
    	ctrl.planInfo.Seq__c = planMst.Seq__c;
    	ctrl.savePlanDetail();
    	System.assert(Apexpages.hasMessages(ApexPages.Severity.ERROR));
    	System.assertEquals(Apexpages.getMessages().size(), 3,Apexpages.getMessages());
    }
    // PLANNO重複チェック
    static testmethod void newPlanTest3() {
    	Plan__c planMst = TestCommon.createPlan();
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
    	Plan__c plan = new Plan__c();
    	ApexPages.StandardController contrl = new ApexPages.StandardController(plan);
    	PlanProductSetup ctrl = new PlanProductSetup(contrl);
    	ctrl.planInfo.Name = CommUtils.getRandom(10);
    	ctrl.planInfo.PlanNo__c = planMst.PlanNo__c;
    	List<PlanProductSetup.PlanDetail> planDeLst = ctrl.planDetailList;
        planDeLst[0].productNm = productLst[0].Name;
        planDeLst[0].sobj.AccountMasterRef__c = productLst[0].Id;
        planDeLst[0].sobj.Price__c = 10000;
    	ctrl.savePlanDetail();
    	System.assert(Apexpages.hasMessages(ApexPages.Severity.ERROR));
    	System.assertEquals(Apexpages.getMessages().size(), 1,Apexpages.getMessages());
    }
}