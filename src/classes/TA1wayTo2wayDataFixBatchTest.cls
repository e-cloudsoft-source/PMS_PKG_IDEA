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
private class TA1wayTo2wayDataFixBatchTest {
    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        LeadIndex__c lead = new LeadIndex__c(
        							ParentLeadIndxRef__c = null,
        							APPNAME__c = null, 
        							EntryDate__c = Date.today(),
        							EventSource__c = 'FromTravelAgency',
        							Id__c = String.valueOf('20160525143219167085'));
        insert lead;
		createDocementActionUpdate(lead.id);  
        Test.startTest();
    	Test.setMock(WebServiceMock.class, new TestCommonMockImpl());
    	TA1wayTo2wayDataFixBatch batch = new TA1wayTo2wayDataFixBatch(UserInfo.getUserId());
    	batch.testLoadXmlMsg = '<?xml version="1.0" encoding="shift_jis"?><AllotmentBookingReport><TransactionType><DataFrom>FromTravelAgency</DataFrom><DataClassification>NewBookReport</DataClassification><DataID>20160525143219167085</DataID><BookingDataID>00001496877-B-20160113004826</BookingDataID><SystemDate>2016-05-25</SystemDate><SystemTime>14:32:19</SystemTime></TransactionType></AllotmentBookingReport>';
//    	system.debug(loggingLevel.INfo, 'batch=' + batch);  
		ID batchprocessid = Database.executeBatch(batch,1);
//		system.debug(loggingLevel.INfo, 'batchprocessid=' + batchprocessid);
        Test.stopTest();
    }
    static testMethod void myUnitTest1() {
        // TO DO: implement unit test
        LeadIndex__c lead = new LeadIndex__c(
        							ParentLeadIndxRef__c = null,
        							APPNAME__c = null, 
        							EntryDate__c = Date.today(),
        							EventSource__c = 'FromTravelAgency',
        							Id__c = String.valueOf('12345678900'));
        insert lead;
		createDocementActionUpdate(lead.id);  
        Test.startTest();
    	Test.setMock(WebServiceMock.class, new TestCommonMockImpl());
    	TA1wayTo2wayDataFixBatch batch = new TA1wayTo2wayDataFixBatch(UserInfo.getUserId());
    	batch.testLoadXmlMsg = '<?xml version="1.0" encoding="shift_jis"?><AllotmentBookingReport><TransactionType><DataFrom>FromTravelAgency</DataFrom><DataClassification>NewBookReport</DataClassification><DataID>20160525143219167085</DataID><BookingDataID>00001496877-B-20160113004826</BookingDataID><SystemDate>2016-05-25</SystemDate><SystemTime>14:32:19</SystemTime></TransactionType></AllotmentBookingReport>';
//    	system.debug(loggingLevel.INfo, 'batch=' + batch);  
		ID batchprocessid = Database.executeBatch(batch,1);
//		system.debug(loggingLevel.INfo, 'batchprocessid=' + batchprocessid);
        Test.stopTest();
    }
    static testMethod void myUnitTest2() {
        // TO DO: implement unit test
         LeadIndex__c lead = new LeadIndex__c(
        							ParentLeadIndxRef__c = null,
        							APPNAME__c = TA_ServiceCtrl.SERVICE_KEY,
        							EntryDate__c = Date.today(),
        							EventSource__c = 'FromTravelAgency',
        							Id__c = String.valueOf('20160525143219167085'));
        insert lead;
		createDocementActionUpdate(lead.id);  
        Test.startTest();
    	Test.setMock(WebServiceMock.class, new TestCommonMockImpl());
    	TA1wayTo2wayDataFixBatch batch = new TA1wayTo2wayDataFixBatch(UserInfo.getUserId());
    	batch.testLoadXmlMsg = '<?xml version="1.0" encoding="shift_jis"?><AllotmentBookingReport><TransactionType><DataFrom>FromTravelAgency</DataFrom><DataClassification>NewBookReport</DataClassification><DataID>20160525143219167085</DataID><BookingDataID>-</BookingDataID><SystemDate>2016-05-25</SystemDate><SystemTime>14:32:19</SystemTime></TransactionType></AllotmentBookingReport>';
//    	system.debug(loggingLevel.INfo, 'batch=' + batch);  
		ID batchprocessid = Database.executeBatch(batch,1);
//		system.debug(loggingLevel.INfo, 'batchprocessid=' + batchprocessid);
        Test.stopTest();
    }
    private static void createDocementActionUpdate(String parentId){
		String infoTravelXML  = '<?xml version="1.0" encoding="shift_jis"?><AllotmentBookingReport><TransactionType><DataFrom>FromTravelAgency</DataFrom><DataClassification>NewBookReport</DataClassification><DataID>20160525143219167085</DataID><BookingDataID>00001496877-B-20160113004826</BookingDataID><SystemDate>2016-05-25</SystemDate><SystemTime>14:32:19</SystemTime></TransactionType></AllotmentBookingReport>';
		String dateKey = System.now().format('yyMMddHHMMssSSS');
		Attachment newAttach = new Attachment(
									ParentId = parentId,
									Name = 'TA_' + dateKey + '1_Test.xml', 
									ContentType = 'text/xml',
									Body = Blob.valueOf(infoTravelXML)
								);
		insert newAttach;
//		system.debug(loggingLevel.INfo, 'newAttach=' + newAttach);
    }
    
}