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
private class WS_SyncJTBContactInfoTest {

    static testMethod void myUnitTest() {
    	createJtbConfigDoc();
        RestRequest req = new RestRequest(); 
    	RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/pmsservice/V1/jtbplus/getuserinfo';  
        req.addParameter('collaborationId', 'QdD67zPLyTDc6Vo1');
    	req.httpMethod = 'GET';  
        RestContext.request = req;
    	RestContext.response = res;
    	
    	Test.startTest();
    	try {
    	WS_SyncJTBContactInfo.doGet();
    	} catch (Exception e) {}
    }
    // メールをヒントできる場合
	static testMethod void testJtbInfo_ExtLogic1() {
    	createJtbConfigDoc();
    	// 電話番号をヒントできる場合
    	Contact guest = TestCommon.createContact();
    	guest.email= 'xxxx@xxx.xxx';
    	guest.phone= '09012345678MM';
    	update guest;
    	Test.startTest();
    	// 指定IDから呼出する
    	String testSyncId = '1234567890';
    	Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl());
    	WS_SyncJTBContactInfo.processRequest(testSyncId);
    	Test.stopTest();
    	List<SyncContactInfo__c> syncInfoLst = [select id from SyncContactInfo__c where SyncKey__c = :testSyncId];
    	System.assertEquals(syncInfoLst.size(),1,syncInfoLst);
    	List<Contact> newGuest = [select JTbSyncInfoRef__c from contact where id = :guest.Id];
    	System.assertEquals(syncInfoLst[0].id, newGuest[0].JTbSyncInfoRef__c, newGuest);
	}
	// 電話番号をヒントできる場合
	static testMethod void testJtbInfo_ExtLogic2() {
    	createJtbConfigDoc();
    	// メールをヒントできる場合
    	Contact guest = TestCommon.createContact();
    	guest.email= 'xxxx@xxx.xxx.com';
    	guest.phone= '09012345678';
    	update guest;
    	Test.startTest();
    	// 指定IDから呼出する
    	String testSyncId = '1234567890';
    	Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl());
    	WS_SyncJTBContactInfo.processRequest(testSyncId);
    	Test.stopTest();
    	List<SyncContactInfo__c> syncInfoLst = [select id from SyncContactInfo__c where SyncKey__c = :testSyncId];
    	System.assertEquals(syncInfoLst.size(),1,syncInfoLst);
    	List<Contact> newGuest = [select JTbSyncInfoRef__c from contact where id = :guest.Id];
    	System.assertEquals(syncInfoLst[0].id, newGuest[0].JTbSyncInfoRef__c, newGuest);
	}
	// 両方ともヒントできない場合
	static testMethod void testJtbInfo_ExtLogic3() {
    	createJtbConfigDoc();
    	// メールをヒントできる場合
    	Contact guest = TestCommon.createContact();
    	guest.email= 'xxxx@xxx.xxx.com';
    	guest.phone= '09012345678MM';
    	update guest;
    	Test.startTest();
    	// 指定IDから呼出する
    	String testSyncId = 'z1234567890';
    	Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl());
    	WS_SyncJTBContactInfo.processRequest(testSyncId);
    	Test.stopTest();
    	List<SyncContactInfo__c> syncInfoLst = [select id from SyncContactInfo__c where SyncKey__c = :testSyncId];
    	System.assertEquals(syncInfoLst.size(),1,syncInfoLst);
    	List<Contact> newGuest = [select JTbSyncInfoRef__c from contact where id = :guest.Id];
    	System.assertEquals(null, newGuest[0].JTbSyncInfoRef__c, newGuest);
	}
    private static Document createJtbConfigDoc() {
    	String configXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><root><SHOP><SHOPCODE></SHOPCODE><AUTHINFO><domainUrl>https://staging.e-cloudsoft.com/id-translator</domainUrl><clined_id>19lzdvkb7g8t3ars</clined_id><client_secret>W98EDXkPBF3GtRcDrqDK2fLAwrOgw7aY</client_secret><user_id>staging_jinya_connect</user_id><password>YSiqFJ3YvfXOskl7ITBvoGsfOUEOzmk7</password></AUTHINFO><CONTACT_MAPPING><MAPPING><JSONKEY>mailAddress</JSONKEY><SFKEY>Email</SFKEY></MAPPING><MAPPING><JSONKEY>phone</JSONKEY><SFKEY>Phone</SFKEY></MAPPING></CONTACT_MAPPING></SHOP></root>';
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'JTBSyncInfoConfig';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(configXml);
    	insert item;
    	return item;
    }
}