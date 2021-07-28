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
private class CooperationResultTriggerProcessTest {

	
	static testMethod void myTest1() {
		List<CollaborationGroup> groups = TestCommon.createGroups(2);
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	comDef.ChatterGroupName__c = groups[0].name+','+groups[1].name;
    	update comDef;
        Test.startTest();    	
		CooperationResult__c coop = TestCommon.createLeadImportAndImpotNG();
		coop.MailSendComplete__c = true;
		update coop;		
		list<FeedItem> feeditems = [select Type, title, Body, ParentId, LinkUrl from FeedItem];
		system.assertEquals(feeditems.size(),2);
        Test.stopTest();
    }
	static testMethod void myTest2() {
		List<CollaborationGroup> groups = TestCommon.createGroups(2);
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	comDef.ChatterGroupName__c = groups[0].name+','+groups[1].name;
    	update comDef;
        Test.startTest();    	
		CooperationResult__c coop1 = TestCommon.createLeadImportAndImpotNG();
		CooperationResult__c coop2 = TestCommon.createLeadImportAndImpotNG();
		CooperationResult__c coop3 = TestCommon.createLeadImportAndImpotNG();
		list<CooperationResult__c> resultList = new list<CooperationResult__c>();
		resultList.add(coop1);
		resultList.add(coop2);
		resultList.add(coop3);
		for(CooperationResult__c coop : resultList){
			coop.MailSendComplete__c = true;
			coop.FunctionType__c = '在庫調整';
		}
		update resultList;		
		
		list<FeedItem> feeditems = [select Type, title, Body, ParentId, LinkUrl from FeedItem];
		system.assertEquals(feeditems.size(),6);
        Test.stopTest();
    }
}