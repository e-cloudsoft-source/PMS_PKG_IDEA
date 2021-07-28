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
private class SalesTax8UpdaterPlanDetailChouManTest {

    // 2019/08/12 消費税は8%から10%に変更対応 WGCH BEGIN
    /*
    @isTest(SeeAllData=false)
	static void testCase1() {

		// ２０１４・０３・３０開始４連泊予約情報を設定する
		Date startDt = Date.newInstance(2014,3,30);
		Date changeDate = Date.newInstance(2014,4,1);
    	// 予約情報を作成する(4連泊予約情報を作成する)
    	Plan__c plan = TestCommon.createPlan();
		// 見積もり明細情報を更新を行う（消費税マスタは５％のまま、更新する場合、2014/04/01以後の見積もり明細の消費税率は全部８％に変更されるの確認
		List<PlanDetail__c> confirms = [select Id, TaxRate__c from PlanDetail__c where PlanRef__c = :plan.Id];
		for (PlanDetail__c planDetail : confirms) {
			planDetail.TaxRate__c = 5;
		}
		confirms[0].TaxRate__c = 4;
		update confirms;
		
		Test.startTest();
		SalesTax8UpdaterPlanDetailChouMan m = new SalesTax8UpdaterPlanDetailChouMan();
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
		String jobName = DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, sch, m);
		
		SalesTax8UpdaterPlanDetailChouMan batch = new SalesTax8UpdaterPlanDetailChouMan(UserInfo.getUserId());
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		List<PlanDetail__c> items = [select Id, TaxRate__c from PlanDetail__c where PlanRef__c = :plan.Id And TaxRate__c = 8];
		// 全部明細件数を計算する
		System.assertEquals(items.size(), confirms.size()-1);
		// for (PlanDetail__c item : items) {
		//	system.assertEquals(item.TaxRate__c, 8, item);
		//}
	}
	*/
	@isTest(SeeAllData=false)
	static void testCase1() {

		// ２０１４・０３・３０開始４連泊予約情報を設定する
		Date startDt = Date.newInstance(2014,3,30);
		Date changeDate = Date.newInstance(2014,4,1);
    	// 予約情報を作成する(4連泊予約情報を作成する)
    	Plan__c plan = TestCommon.createPlan();
		// 見積もり明細情報を更新を行う（消費税マスタは５％のまま、更新する場合、2014/04/01以後の見積もり明細の消費税率は全部８％に変更されるの確認
		List<PlanDetail__c> confirms = [select Id, TaxRate__c from PlanDetail__c where PlanRef__c = :plan.Id];
		for (PlanDetail__c planDetail : confirms) {
			planDetail.TaxRate__c = 8;
		}
		confirms[0].TaxRate__c = 4;
		update confirms;
		
		Test.startTest();
		SalesTax8UpdaterPlanDetailChouMan m = new SalesTax8UpdaterPlanDetailChouMan();
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
		String jobName = DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, sch, m);
		
		SalesTax8UpdaterPlanDetailChouMan batch = new SalesTax8UpdaterPlanDetailChouMan(UserInfo.getUserId());
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		List<PlanDetail__c> items = [select Id, TaxRate__c from PlanDetail__c where PlanRef__c = :plan.Id And TaxRate__c = 10];
		// 全部明細件数を計算する
		System.assertEquals(items.size(), confirms.size()-1);
	}
	@isTest(SeeAllData=false)
	static void testCase2() {

		// ２０１４・０３・３０開始４連泊予約情報を設定する
		Date startDt = Date.newInstance(2014,3,30);
		Date changeDate = Date.newInstance(2014,4,1);
    	// 予約情報を作成する(4連泊予約情報を作成する)
    	Plan__c plan = TestCommon.createPlan();
		// 見積もり明細情報を更新を行う（消費税マスタは５％のまま、更新する場合、2014/04/01以後の見積もり明細の消費税率は全部８％に変更されるの確認
		List<PlanDetail__c> confirms = [select Id, TaxRate__c from PlanDetail__c where PlanRef__c = :plan.Id];
		for (PlanDetail__c planDetail : confirms) {
			planDetail.TaxRate__c = 8;
		}
		update confirms;
		
		Test.startTest();
		SalesTax8UpdaterPlanDetailChouMan m = new SalesTax8UpdaterPlanDetailChouMan();
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
		String jobName = DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, sch, m);
		
		SalesTax8UpdaterPlanDetailChouMan batch = new SalesTax8UpdaterPlanDetailChouMan(UserInfo.getUserId());
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		List<PlanDetail__c> items = [select Id, TaxRate__c from PlanDetail__c where PlanRef__c = :plan.Id And TaxRate__c = 10];
		// 全部明細件数を計算する
		System.assertEquals(items.size(), confirms.size());
	}
	// 2019/08/12 消費税は8%から10%に変更対応 WGCH END
	@isTest(SeeAllData=false)
	static void testCase3() {

		// ２０１４・０３・３０開始４連泊予約情報を設定する
		Date startDt = Date.newInstance(2014,3,30);
		Date changeDate = Date.newInstance(2014,4,1);
    	// 予約情報を作成する(4連泊予約情報を作成する)
    	Plan__c plan = TestCommon.createPlan();
		// 見積もり明細情報を更新を行う（消費税マスタは５％のまま、更新する場合、2014/04/01以後の見積もり明細の消費税率は全部８％に変更されるの確認
		List<PlanDetail__c> confirms = [select Id, Price__c, TaxRate__c from PlanDetail__c where PlanRef__c = :plan.Id];
		for (PlanDetail__c planDetail : confirms) {
			planDetail.Price__c = 10000;
			planDetail.TaxRate__c = 8;
		}
		confirms[0].TaxRate__c = 4;
		update confirms;
		
		Test.startTest();
		SalesTax8UpdaterPlanDetailChouMan2 m = new SalesTax8UpdaterPlanDetailChouMan2();
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
		String jobName = DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, sch, m);
		
		SalesTax8UpdaterPlanDetailChouMan2 batch = new SalesTax8UpdaterPlanDetailChouMan2(UserInfo.getUserId());
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		List<PlanDetail__c> items = [select Id, TaxRate__c from PlanDetail__c where PlanRef__c = :plan.Id And TaxRate__c = 10];
		// 全部明細件数を計算する
		System.assertEquals(items.size(), confirms.size()-1);
	}
	@isTest(SeeAllData=false)
	static void testCase4() {

		// ２０１４・０３・３０開始４連泊予約情報を設定する
		Date startDt = Date.newInstance(2014,3,30);
		Date changeDate = Date.newInstance(2014,4,1);
    	// 予約情報を作成する(4連泊予約情報を作成する)
    	Plan__c plan = TestCommon.createPlan();
		// 見積もり明細情報を更新を行う（消費税マスタは５％のまま、更新する場合、2014/04/01以後の見積もり明細の消費税率は全部８％に変更されるの確認
		List<PlanDetail__c> confirms = [select Id, TaxRate__c, Price__c from PlanDetail__c where PlanRef__c = :plan.Id];
		for (PlanDetail__c planDetail : confirms) {
			planDetail.Price__c = 10000;
			planDetail.TaxRate__c = 8;
		}
		update confirms;
		
		Test.startTest();
		SalesTax8UpdaterPlanDetailChouMan2 m = new SalesTax8UpdaterPlanDetailChouMan2();
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
		String jobName = DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, sch, m);
		
		SalesTax8UpdaterPlanDetailChouMan2 batch = new SalesTax8UpdaterPlanDetailChouMan2(UserInfo.getUserId());
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		List<PlanDetail__c> items = [select Id, TaxRate__c from PlanDetail__c where PlanRef__c = :plan.Id And TaxRate__c = 10];
		// 全部明細件数を計算する
		System.assertEquals(items.size(), confirms.size());
	}
	// 2019/08/12 消費税は8%から10%に変更対応 WGCH END
}