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
private class WS_LiquidKeyServiceTest {

    static testMethod void doGetTest() {
    	RestResponse res = new RestResponse();
    	RestRequest req = new RestRequest(); 
    	req.requestURI = '/services/apexrest/liquid/V1/getbookinginfo';  
    	req.httpMethod = 'GET';  
    	RestContext.response = res;
        RestContext.request = req;
        Test.startTest();
    	try {
    	WS_LiquidKeyService.doGet();
    	} catch (Exception e) {}
    }
    
    //旅行会社予約番号作为searchkey
    static testMethod void getbookinginfoTest() {
    	// 予約情報を作成する
    	String key0 = 'E001781590';
    	String key1 = 'A001781590';
    	Lead__c leadInfo = TestCommon.createLead();
        Id leadIdxId = [select LeadIndexRef__c from Lead__c where id = :leadInfo.id].LeadIndexRef__c;
    	List<LeadIndex__c> leadIdxs = [select name,TravelLeadNo__c,contactRef__c from LeadIndex__c where id = :leadIdxId];
    	LeadIndex__c leadIdx = leadIdxs[0];
    	leadIdx.TravelLeadNo__c = key1;
    	update leadIdx;
    	String key2 = leadIdx.Name.right(10);
    	Id contactId = leadIdx.contactRef__c;
    	List<Contact> cs = [select phone from contact where id = :contactId];
    	String key3 = cs[0].phone;
    	Test.startTest();
    	WS_LiquidKeyService.getbookinginfo(key0);
    	WS_LiquidKeyService.getbookinginfo(key1);
    	WS_LiquidKeyService.getbookinginfo(key2);
    	WS_LiquidKeyService.getbookinginfo(key3);
    	Test.stopTest();
    }
    
    
    
    
    
}