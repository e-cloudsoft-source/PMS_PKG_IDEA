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
private class TA_LeadSyncXmlImportBatchTest {
	static testMethod void myUnitTest1() {
    	TestCommon.createCommDefine();
    	createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Ta2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        CooperationResult__c coo = TestCommon.createCooperationParentXMLImpot();
        coo.ErrorContent__c = 'SERVICE_OUT_PUT_ERROR';
        coo.ErrorCount__c = 5;
        update coo;

        Test.startTest();
    	Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true));
    	TA_LeadSyncXmlImportBatch batch = new TA_LeadSyncXmlImportBatch();    
		ID batchprocessid = Database.executeBatch(batch,1);
        Test.stopTest(); 

    }

    static testMethod void myUnitTest2() {
        // TO DO: implement unit test
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Ta2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        CooperationResult__c coo = TestCommon.createCooperationParentXMLImpot();
        coo.ErrorContent__c = 'SERVICE_OUT_PUT_ERROR';
        update coo;

        Test.startTest();
    	Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true));
    	TA_LeadSyncXmlImportBatch batch = new TA_LeadSyncXmlImportBatch();    
		ID batchprocessid = Database.executeBatch(batch,1);
        Test.stopTest(); 
    }
    
    static testMethod void myUnitTest3() {
        // TO DO: implement unit test
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Ta2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        TestCommon.createCooperationParentLeadImport();

        Test.startTest();
    	Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl());
    	TA_LeadSyncXmlImportBatch batch = new TA_LeadSyncXmlImportBatch();    
		ID batchprocessid = Database.executeBatch(batch,1);
        Test.stopTest(); 
    }
    private static void createConfigDoc() {
    	TestCommon.createTa2WayConfigDoc();
    }
}