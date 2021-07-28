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
private class LeadIndexCommTriggerProcessTest {

	@isTest
    static void testCase1() {
    	Test.startTest();
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	Test.stopTest();
    	Lead__c newLead = [select LeadIndexSubId__c from lead__c where id =:leadInfo.Id ];
    	List<LeadIndex__c> subIdxs = [select id,StatusLst__c from LeadIndex__c where Id = :newLead.LeadIndexSubId__c];
    	for (LeadIndex__c sub : subIdxs) {
    		sub.StatusLst__c = CommConst.LEAD_ST_CANCEL;
    	}
    	update subIdxs;
    	List<Lead__c> existLead = [select id from Lead__c where id = :leadInfo.Id And ReservedStatus__c = :CommConst.LEAD_ST_CANCEL];
    	// キャンセル処理を行う
    	System.assert(!existLead.isEmpty());
	}
}