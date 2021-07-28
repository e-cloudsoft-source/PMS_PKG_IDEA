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
private class ZipcodeSearchServiceTest {

    public static testmethod void testWebservice1(){
        Test.startTest();
            clearConfig();
            String response = ZipcodeSearchService.searchZIPCode('322');
            system.assertEquals(response, null);
        Test.stopTest();
    }
    
    public static testmethod void testWebservice2(){
        Test.setMock(HttpCalloutMock.class, new ZipcodeSearchService.HttpCalloutMockImpl());
        
        Test.startTest();
            clearConfig();
            String response = ZipcodeSearchService.searchZIPCode('322');
            system.assertNotEquals(response, null);
            system.assertEquals(response.length() > 0, true);
        Test.stopTest();
    }
    public static testmethod void testWebservice3(){
        Test.setMock(HttpCalloutMock.class, new ZipcodeSearchService.HttpCalloutMockImpl());
        Test.startTest();
            String response = ZipcodeSearchService.searchAddress('116001');
            system.assertNotEquals(response, null);
        Test.stopTest();
    }
    public static testmethod void testWebservice4(){
    	Test.setMock(HttpCalloutMock.class, new ZipcodeSearchService.HttpCalloutMockImpl());
    	clearConfig();
        Date resetDate = Date.today();
        insert (new ZipSearchInfo__c(EndPointType__c = CommUtils.nullToBlank(2),
                                     ResetDate__c = resetDate.addDays(3)));
        Test.startTest();
            String response = ZipcodeSearchService.searchZIPCode('335');
            system.assertNotEquals(response, null);
        Test.stopTest();
    }
    public static testmethod void testWebservice5(){
    	Test.setMock(HttpCalloutMock.class, new ZipcodeSearchService.HttpCalloutMockImpl());
        clearConfig();
        Date resetDate = Date.today();
        insert(new ZipSearchInfo__c(EndPointType__c = CommUtils.nullToBlank(3),
                                                ResetDate__c = resetDate.addDays(3)));
        Test.startTest();
            String response = ZipcodeSearchService.searchZIPCode('335');
            system.assertNotEquals(response, null);
        Test.stopTest();
    }
    private static void clearConfig() {
        delete [select id from ZipSearchInfo__c];
    }
}