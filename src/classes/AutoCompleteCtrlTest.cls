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
private class AutoCompleteCtrlTest {

    @isTest
	static void testCase1() {
		SObject[] s = AutoCompleteCtrl.findSObjectsExt('LeadIndex__c', '22', 'ID__c', 'StatusLst__c != \'キャンセル\' And  ParentLeadIndxRef__c = null','StatusLst__c');
		System.assertNotEquals(s, new List<SObject>());
		SObject[] s2 = AutoCompleteCtrl.findSObjects('LeadIndex__c', '22', 'ID__c', 'StatusLst__c != \'キャンセル\' And  ParentLeadIndxRef__c = null');
		System.assertNotEquals(s2, new List<SObject>());
		SObject[] s3 = AutoCompleteCtrl.findSObjects(null,'22', 'ID__c', 'StatusLst__c != \'キャンセル\' And  ParentLeadIndxRef__c = null');
		System.assertEquals(s3,null);
		SObject[] s4 = AutoCompleteCtrl.findSObjects(null,'22', 'ID__c', null);
		
		AutoCompleteCtrl.findSObjectsExtSL('LeadIndex__c', '22', 'ID__c', 'StatusLst__c != \'キャンセル\' And  ParentLeadIndxRef__c = null','StatusLst__c');
		AutoCompleteCtrl.findSObjectsExtSL('LeadIndex__c', '22', 'ID__c', 'StatusLst__c != \'キャンセル\' And  ParentLeadIndxRef__c = null');
		AutoCompleteCtrl.findSObjectsExtSL('LeadIndex__c', '22', 'ID__c', null);
		AutoCompleteCtrl.findSObjectsExtSL('A-LeadIndex__c', '22', 'ID__c', 'StatusLst__c != \'キャンセル\' And  ParentLeadIndxRef__c = null');
	}
	// 2019/08/19 BY zyz BEGIN
    @isTest
	static void testCase2() {
		SObject[] s = AutoCompleteCtrl.findSObjectsExt('LeadIndex__c', '22', 'ID__c', 'StatusLst__c != \'キャンセル\' And  ParentLeadIndxRef__c = null','StatusLst__c');
		System.assertNotEquals(s, new List<SObject>());
		SObject[] s2 = AutoCompleteCtrl.findSObjects('LeadIndex__c', '22', 'ID__c', 'StatusLst__c != \'キャンセル\' And  ParentLeadIndxRef__c = null');
		System.assertNotEquals(s2, new List<SObject>());
		SObject[] s3 = AutoCompleteCtrl.findSObjects(null,'22', 'ID__c', 'StatusLst__c != \'キャンセル\' And  ParentLeadIndxRef__c = null');
		System.assertEquals(s3,null);
		SObject[] s4 = AutoCompleteCtrl.findSObjects(null,'22', 'ID__c', null);
		CommDefine__c com = TestCommon.createCommDefine();
		com.ContactSearchFields__c = 'mailingaddress,Phone,name';
		update com;
		AutoCompleteCtrl.findSObjectsExtSL('Contact', '22', 'ID__c', 'Name != null','');
		AutoCompleteCtrl.findSObjectsExt('Contact', '22', 'ID__c', 'Name != null','');
	}
	// 2019/08/19 BY zyz END
}