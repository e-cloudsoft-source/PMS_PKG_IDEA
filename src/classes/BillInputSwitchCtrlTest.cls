@isTest
private class BillInputSwitchCtrlTest {
	static testMetHod void case01() {
		Date dt = Date.today();
		RsvAccount__c rsv = TestCommon.createRsvAccount();
		// 2015/12/01 Assert BEGIN
		System.assertEquals([select Id from RsvAccount__c].size(), 1);
		// 2015/12/01 Assert END
		List<Lead__c> leadLst = TestCommon.createLead(dt, 5, 5);
		AccountAcount__c aaitem = TestCommon.createAccountAcount(rsv.Id, leadLst[0].Id);

		Test.startTest();

		ApexPages.StandardController contrl = new ApexPages.StandardController(aaitem);
		BillInputSwitchCtrl bs = new BillInputSwitchCtrl(contrl);
		Pagereference pg = bs.redirect();
		Test.setCurrentPage(pg);

		Test.stopTest();
	}
	
}