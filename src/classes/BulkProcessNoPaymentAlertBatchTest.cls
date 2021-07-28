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
private class BulkProcessNoPaymentAlertBatchTest {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        List<CollaborationGroup> chtGrp = TestCommon.createGroups(1);
        
        CommDefine__c comDef = TestCommon.createCommDefine();
        comDef.SchedulePayCheckDays__c = -2;
        comDef.ScheduleResultMailAddress__c = '111@aaa.com';
        comDef.ChatterGroupName__c = '11:'+chtGrp[0].Name;
        update comDef;

		Date startDt = Date.today().addDays(-2);
        // 予約情報を作成する
        list<Lead__c> leadInfos = TestCommon.createLead(startDt, 1, 1);
        Lead__c leadInfo = leadInfos[0];
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        List<AccountMaster__c> payMst = TestCommon.createPayProductMst(new set<String>{Label.CONST_012_0440});
        payMst[0].PayLimitDays__c = 1;
        update payMst;
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfo, productLst[0]);
        // 予約情報のステータス：チェックインに変更する
        leadInfo.Field298__c = 'チェックイン完';
        update leadInfo;
        
         // 会計画面に動作確認を行う
        List<AccountAcount__c> accObjLst = [select id,frs__c from AccountAcount__c where Relreserve__c = :leadInfo.Id];
        AccountAcount__c accObj = accObjLst[0];
        // 支払明細
        TTend__c ttend = TestCommon.createTTend(accObj.frs__c,accObj.Id,payMst[0].Id);
        
        Test.startTest();
        BulkProcessNoPaymentAlertBatch bppb = new BulkProcessNoPaymentAlertBatch();
        DateTime nowTime = DateTime.now().addSeconds(100);
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
        String jobId = system.schedule(jobName, sch, bppb);

        Test.stopTest();
    }
    // 2019/11/15 「該当のご予約に紐づいているお客様の取引先が変更」も反映 BY zyz BEGIN
    static testMethod void myUnitTest1() {
        // 
        CommDefine__c comDef = TestCommon.createCommDefine();
        comDef.LeadRefAccountAutoSetupFlg__c = true;
        update comDef;
        // 取引先做成
        Account FrAccounts1 = TestCommon.createNormalAccount();
        Account FrAccounts2 = TestCommon.createNormalAccount();
		// お客様
		Contact contacts = TestCommon.createContact();
		contacts.AccountId = FrAccounts1.Id;
		update contacts;
		// 予約情報を作成する
		List<Lead__c> leadInfos = TestCommon.createLead(Date.today(), 1, 3, contacts.Id);
		// 变更お客様的取引先
		contacts.AccountId = FrAccounts2.Id;
		update contacts;
		// 执行Schedule
		// 次のスケジュールを起動する
		BulkProcessLeadAccounRefFixBatch schedule = new BulkProcessLeadAccounRefFixBatch();
		// 每间隔一个小时执行
		DateTime nowTime = DateTime.now().addMinutes(60);
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
		String jobName = 'BulkProcessLeadAccounRefFixBatch_' + DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, sch, schedule);
        // 执行batch
		//BulkProcessLeadAccounRefFixBatch batch = new BulkProcessLeadAccounRefFixBatch();
		DataBase.executeBatch(schedule,2000);
    }
    // 2019/11/15 「該当のご予約に紐づいているお客様の取引先が変更」も反映 BY zyz END
}