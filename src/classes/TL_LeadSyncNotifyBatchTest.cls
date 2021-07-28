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
private class TL_LeadSyncNotifyBatchTest {

    static testMethod void myTest1() {
    	createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Tl2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        Test.startTest();
    	Test.setMock(WebServiceMock.class, new TestCommonMockImpl());
    	TL_LeadSyncNotifyBatchExtend batch = new TL_LeadSyncNotifyBatchExtend();    
		ID batchprocessid = Database.executeBatch(batch,1);
        Test.stopTest();
    }
    
    
    
    static testMethod void myTest2() {
    	createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Tl2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        Test.startTest();
    	CooperationResult__c cooperationResultInfo = TestCommon.createCooperationParentXMLImpot();
    	Test.setMock(WebServiceMock.class, new TestCommonMockImpl(true));
    	TL_LeadSyncNotifyBatchExtend batch = new TL_LeadSyncNotifyBatchExtend();    
		ID batchprocessid = Database.executeBatch(batch,1);
    	Test.stopTest();  
    }
    private static void createConfigDoc() {
    	String configXml = '<?xml version="1.0" encoding="UTF-8"?><root><COMMON><STOCKINTERVAL>120</STOCKINTERVAL><STOCKDELETEVAL>-3</STOCKDELETEVAL><LEADINTERVAL>10</LEADINTERVAL><LEADDELETEVAL>-30</LEADDELETEVAL><SERVICE_URL>https://test472.tl-lincoln.net/pmsservice/V1</SERVICE_URL></COMMON><SHOP><SHOPCODE></SHOPCODE><APPCONFIG><SYSTEMID>PFg69aA0</SYSTEMID><USERID>P6820207</USERID><PASSWORD>mj2UOAL.t3</PASSWORD></APPCONFIG>	<ACCOUNTCONFIG><SHITULYOUACCOUNT>100999</SHITULYOUACCOUNT><NYUUTOUACCOUNT>5041</NYUUTOUACCOUNT><OPTIONACCOUNT>C0000</OPTIONACCOUNT><SERVICEACCOUNT>S0000</SERVICEACCOUNT></ACCOUNTCONFIG></SHOP></root>';
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'Tl2wayServiceConfigXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(configXml);
    	insert item;
    }
}