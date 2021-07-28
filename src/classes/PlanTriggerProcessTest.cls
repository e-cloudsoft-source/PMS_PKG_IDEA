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
private class PlanTriggerProcessTest {

    @isTest
	static void selfUnit() {
    	Test.startTest();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(3);
    	// プラン作成
    	Plan__c plan = TestCommon.createPlan();
    	Plan__c plan2 = TestCommon.createPlan();
		// プラン明細作成を行う
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
		
    	ApexPages.StandardController contrl2 = new ApexPages.StandardController(plan2);
 		PlanProductSetup ctrl2 = new PlanProductSetup(contrl2);
		List<PlanProductSetup.PlanDetail> planDeLst2 = ctrl2.planDetailList;

		planDeLst2[0].productNm = productLst[0].Name;
		planDeLst2[0].sobj.AccountMasterRef__c = productLst[0].Id;
		planDeLst2[0].sobj.Price__c = 10000;
		planDeLst2[1].productNm = productLst[1].Name;
		planDeLst2[1].sobj.AccountMasterRef__c = productLst[1].Id;
		planDeLst2[1].sobj.Price__c = 20000;
		planDeLst2[2].productNm = productLst[2].Name;
		planDeLst2[2].sobj.AccountMasterRef__c = productLst[2].Id;
		planDeLst2[3].sobj.Price__c = 30000;

		ctrl2.savePlanDetail();
		Test.stopTest();

		Integer stepNum = 0;
		
		// 予約に登録されている場合
		Lead__c lead = TestCommon.createLead();
		lead.Field310__c = plan.Id;
		update lead;
		stepNum = 10;
		try {
			delete plan;
		} catch (Exception e) {
			stepNum = 11;
		}
		System.assertEquals(stepNum, 11);
		/*
		// 見積り明細へ設定、更新を行う
		BookingEstimateItem__c bItem = [select id from BookingEstimateItem__c where refBooking__c = :lead.Id and ParentBookingItemRef__c = null];
		List<PlanDetail__c> pldLst = [select id ,PlanRef__c, PlanProdcut__c from PlanDetail__c where PlanRef__c = :plan2.Id]; 
		Id accMsProdId = pldLst[0].PlanProdcut__c;
		bItem.refAccountMaster__c = accMsProdId;
		update bItem;
		
		stepNum = 20;
		try {
			delete plan2;
		} catch (Exception e) {
			stepNum = 21;
		}
		System.assertEquals(stepNum, 21);	*/
	}
	@isTest
	static void selfUnit2() {
    	Test.startTest();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(3);
    	// プラン作成
    	Plan__c plan = TestCommon.createPlan();
    	Plan__c plan2 = TestCommon.createPlan();
		// プラン明細作成を行う
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
		// Plan1作成
		ctrl.savePlanDetail();
		
    	ApexPages.StandardController contrl2 = new ApexPages.StandardController(plan2);
 		PlanProductSetup ctrl2 = new PlanProductSetup(contrl2);
		List<PlanProductSetup.PlanDetail> planDeLst2 = ctrl2.planDetailList;

		planDeLst2[0].productNm = productLst[0].Name;
		planDeLst2[0].sobj.AccountMasterRef__c = productLst[0].Id;
		planDeLst2[0].sobj.Price__c = 10000;
		planDeLst2[1].productNm = productLst[1].Name;
		planDeLst2[1].sobj.AccountMasterRef__c = productLst[1].Id;
		planDeLst2[1].sobj.Price__c = 20000;
		planDeLst2[2].productNm = productLst[2].Name;
		planDeLst2[2].sobj.AccountMasterRef__c = productLst[2].Id;
		planDeLst2[3].sobj.Price__c = 30000;
		// Plan2作成
		ctrl2.savePlanDetail();
		
		Test.stopTest();
    			
		// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst2 = TestCommon.createProductMst(1);
    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo, productLst2[0]);
    	// 予約情報のステータス：チェックインに変更する
    	leadInfo.Field298__c = 'チェックイン完';
    	update leadInfo;
 	
		Integer stepNum = 0;
		stepNum = 0;
		try {
			delete plan;
		} catch (Exception e) {
			stepNum = 1;
		}
		System.assertEquals(stepNum, 0);	
		/*
    	// 会計画面に動作確認を行う
		List<PlanDetail__c> pldLst = [select id ,PlanRef__c, PlanProdcut__c from PlanDetail__c where PlanRef__c = :plan2.Id]; 
		Id accMsProdId = pldLst[0].PlanProdcut__c;
    	List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfo.Id];
    	AccountAcount__c accObj = accObjLst[0];
 	
    	ApexPages.StandardController contrlAcc = new ApexPages.StandardController(accObj);
    	BillInput_Ctrl ctrlAcc = new BillInput_Ctrl(contrlAcc);
    	ctrlAcc.initAction();
		// 会計明細に、プラン会計商品を設定する
		ctrlAcc.oTranSobjLst[0].sobj.Field7__c = accMsProdId;
		ctrlAcc.upsertData();
		
		stepNum = 20;
		try {
			delete plan2;
		} catch (Exception e) {
			stepNum = 21;
		}
		System.assertEquals(stepNum, 21);
*/
	}
	@isTest
	static void selfUnit2_1() {
    	Test.startTest();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(3);
    	// プラン作成
    	Plan__c plan = TestCommon.createPlan();
    	Plan__c plan2 = TestCommon.createPlan();
		// プラン明細作成を行う
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
		// Plan1作成
		ctrl.savePlanDetail();
		
    	ApexPages.StandardController contrl2 = new ApexPages.StandardController(plan2);
 		PlanProductSetup ctrl2 = new PlanProductSetup(contrl2);
		List<PlanProductSetup.PlanDetail> planDeLst2 = ctrl2.planDetailList;

		planDeLst2[0].productNm = productLst[0].Name;
		planDeLst2[0].sobj.AccountMasterRef__c = productLst[0].Id;
		planDeLst2[0].sobj.Price__c = 10000;
		planDeLst2[1].productNm = productLst[1].Name;
		planDeLst2[1].sobj.AccountMasterRef__c = productLst[1].Id;
		planDeLst2[1].sobj.Price__c = 20000;
		planDeLst2[2].productNm = productLst[2].Name;
		planDeLst2[2].sobj.AccountMasterRef__c = productLst[2].Id;
		planDeLst2[3].sobj.Price__c = 30000;
		// Plan2作成
		ctrl2.savePlanDetail();
		
		Test.stopTest();
    					
    	// 会計画面に動作確認を行う
		List<PlanDetail__c> pldLst = [select id ,PlanRef__c, PlanProdcut__c from PlanDetail__c where PlanRef__c = :plan2.Id]; 
		Id accMsProdId = pldLst[0].PlanProdcut__c;
    	//List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfo.Id];
    	RsvAccount__c rsv = TestCommon.createRsvAccount();
    	String rsvQuery = CommSqlUtils.generateQueryString('RsvAccount__c');
    	rsv = Database.query(rsvQuery);
    	AccountAcount__c accObj = new AccountAcount__c(frs__r = rsv);
 	
    	ApexPages.StandardController contrlAcc = new ApexPages.StandardController(accObj);
    	BillInput_Ctrl ctrlAcc = new BillInput_Ctrl(contrlAcc);
    	ctrlAcc.initAction();
    	ctrlAcc.insertData();
		// 会計明細に、プラン会計商品を設定する
		ctrlAcc.oTranSobjLst[0].sobj.Field7__c = accMsProdId;
		ctrlAcc.oTranSobjLst[0].productNm = 'テスト商品名';
		ctrlAcc.oTranSobjLst[0].sobj.Field20__c = '2000';
		ctrlAcc.oTranSobjLst[0].sobj.Field21__c = '2000';
		ctrlAcc.oTranSobjLst[0].tranId = '';
		ctrlAcc.oTranSobjLst[0].accRefId = '';
		ctrlAcc.upsertData();
		
		Integer stepNum = 20;
		try {
			delete plan2;
		} catch (Exception e) {
			stepNum = 21;
		}
		System.assertEquals(stepNum, 21);

	}
	
	// プラン名変更にしたがって、関連商品名も自動変更を行う
	/*
	@isTest
	static void selfUnit3() {
    	Test.startTest();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(3);
    	// プラン作成
    	Plan__c plan = TestCommon.createPlan();
    	Plan__c plan2 = TestCommon.createPlan();
		// プラン明細作成を行う
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
		// Plan1作成
		ctrl.savePlanDetail();
		
    	ApexPages.StandardController contrl2 = new ApexPages.StandardController(plan2);
 		PlanProductSetup ctrl2 = new PlanProductSetup(contrl2);
		List<PlanProductSetup.PlanDetail> planDeLst2 = ctrl2.planDetailList;

		planDeLst2[0].productNm = productLst[0].Name;
		planDeLst2[0].sobj.AccountMasterRef__c = productLst[0].Id;
		planDeLst2[0].sobj.Price__c = 10000;
		planDeLst2[1].productNm = productLst[1].Name;
		planDeLst2[1].sobj.AccountMasterRef__c = productLst[1].Id;
		planDeLst2[1].sobj.Price__c = 20000;
		planDeLst2[2].productNm = productLst[2].Name;
		planDeLst2[2].sobj.AccountMasterRef__c = productLst[2].Id;
		planDeLst2[3].sobj.Price__c = 30000;
		// Plan2作成
		ctrl2.savePlanDetail();
		
		Test.stopTest();
		
		// プラン１関連の商品を確認する
		plan.Name = CommUtils.getRandom(10);
		update plan;
		// 関連の商品名を確認する
		List<PlanDetail__c> pldLst = [select id ,PlanRef__c, PlanProdcut__c from PlanDetail__c where PlanRef__c = :plan.Id]; 
		AccountMaster__c accMst = [select name from AccountMaster__c where id = :pldLst[0].PlanProdcut__c];
		System.assertEquals(accMst.Name, plan.Name);
		
	}*/
}