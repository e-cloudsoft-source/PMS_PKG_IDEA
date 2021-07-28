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
private class CashPdfBulkPrintCtrlTest {

    static testMethod void myUnitTest() {
    	Contact guest = TestCommon.createContact();
    	Contact guest1 = TestCommon.createContact();
    	Lead__c lead = TestCommon.createLead();
		Yadochou__c yadochou = new Yadochou__c(
			Name = 'TestCode',
			Field1__c = lead.Id,
			Field15__c = guest.Id
		);
		insert yadochou;
		Guestbookcustomer__c sub1 = new Guestbookcustomer__c(
			customer__c = guest1.Id,
			GuestbookNmae__c = yadochou.Id
		);
		Guestbookcustomer__c sub2 = new Guestbookcustomer__c(
			customer__c = guest1.Id,
			GuestbookNmae__c = yadochou.Id
		);
		List<Guestbookcustomer__c> subs = new List<Guestbookcustomer__c>{sub1, sub2};
		insert subs;
		CashPdfBulkPrintCtrl ctrl1 = new CashPdfBulkPrintCtrl();
		ctrl1.gotoDate();
    }
}