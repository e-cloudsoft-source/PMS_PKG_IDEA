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
private class ContactBookingListTest {

	static testMethod void testCase1() {
		Lead__c lead1 = TestCommon.createLead();
		Contact refContact = [select id from Contact where id =:lead1.Relcontact__c];
		ApexPages.StandardController scontrol = new ApexPages.StandardController(refContact);
		// 一括キャンセル処理を行う
		ContactBookingList ctrl = new ContactBookingList(scontrol);
		ctrl.c_fromSearchDate = '1A';
		ctrl.c_toSearchDate = '2C';
		ctrl.batchCheckoutProc();
		ctrl.batchCancelProc();
		System.assert(ctrl.getLeadInfoLst() != null);
	}
	static testMethod void testCase2() {
		Lead__c lead1 = TestCommon.createLead();
		Contact refContact = [select id from Contact where id =:lead1.Relcontact__c];
		ApexPages.StandardController scontrol = new ApexPages.StandardController(refContact);
		// 一括キャンセル処理を行う
		ContactBookingList ctrl = new ContactBookingList(scontrol);
		List<ContactBookingList.BookingItem> rs = ctrl.getLeadInfoLst();
		rs[0].isSelected = true;
		ctrl.batchCheckoutProc();
		rs = ctrl.getLeadInfoLst();
		rs[0].isSelected = true;
		ctrl.batchCancelProc();
		System.assert(ctrl.getLeadInfoLst() != null);
	}
}