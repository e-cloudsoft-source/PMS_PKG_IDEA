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
private class TR1wayDataFixBatchTest {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        LeadIndex__c lead = new LeadIndex__c(
        							ParentLeadIndxRef__c = null,
        							APPNAME__c = null, 
        							EntryDate__c = Date.today(),
        							EventSource__c = 'Neppan',
        							Id__c = String.valueOf('20160525143219167085'));
        insert lead;
		createDocementActionUpdate(lead.id);  
        Test.startTest();
    	TR1wayDataFixBatch batch = new TR1wayDataFixBatch(UserInfo.getUserId());
    	batch.testLoadXmlMsg = '<AllotmentBookingReport><TransactionType><DataFrom>Neppan</DataFrom><DataClassification>CancellationReport</DataClassification><DataID>20160525143219167085</DataID><SystemDate>2014-03-13</SystemDate><SystemTime>11:10:05</SystemTime></TransactionType><SalesOfficeInformation><SalesOfficeCompanyCode>37</SalesOfficeCompanyCode><SalesOfficeCompanyName>booking</SalesOfficeCompanyName></SalesOfficeInformation><BasicInformation><TravelAgencyBookingNumber>106535992</TravelAgencyBookingNumber><TravelAgencyBookingDate>2013-05-16</TravelAgencyBookingDate></BasicInformation></AllotmentBookingReport>';
		ID batchprocessid = Database.executeBatch(batch,1);
        Test.stopTest();
        LeadIndex__c rs = [select id__c, orgId__c from leadIndex__c where id = :lead.id];
        system.assertEquals('37_106535992',rs.id__c,rs);
        system.assertEquals('20160525143219167085',rs.orgId__c,rs);
    }
    // NO TARGET
    static testMethod void myUnitTest_1() {
        // TO DO: implement unit test
        LeadIndex__c lead = new LeadIndex__c(
        							ParentLeadIndxRef__c = null,
        							APPNAME__c = 'TR', 
        							EntryDate__c = Date.today(),
        							EventSource__c = 'RAKUJIAN',
        							Id__c = String.valueOf('20160525143219167085'));
        insert lead;
        LeadIndex__c lead2 = new LeadIndex__c(
        							ParentLeadIndxRef__c = null,
        							APPNAME__c = 'TR', 
        							EntryDate__c = Date.today(),
        							EventSource__c = 'Neppan',
        							Id__c = String.valueOf('20160525143219167085'));
        insert lead2;
		createDocementActionUpdate(lead.id);  
		createDocementActionUpdate(lead2.id);  
        Test.startTest();
    	TR1wayDataFixBatch batch = new TR1wayDataFixBatch(UserInfo.getUserId());
    	batch.testLoadXmlMsg = '<AllotmentBookingReport><TransactionType><DataFrom>Neppan</DataFrom><DataClassification>CancellationReport</DataClassification><DataID>20160525143219167085</DataID><SystemDate>2014-03-13</SystemDate><SystemTime>11:10:05</SystemTime></TransactionType><SalesOfficeInformation><SalesOfficeCompanyCode>37</SalesOfficeCompanyCode><SalesOfficeCompanyName>booking</SalesOfficeCompanyName></SalesOfficeInformation><BasicInformation><TravelAgencyBookingNumber>106535992</TravelAgencyBookingNumber><TravelAgencyBookingDate>2013-05-16</TravelAgencyBookingDate></BasicInformation></AllotmentBookingReport>';
		ID batchprocessid = Database.executeBatch(batch,1);
        Test.stopTest();
        LeadIndex__c rs = [select id__c, orgId__c,EventSource__c from leadIndex__c where id = :lead.id];
        system.assertEquals(lead.id__c,rs.id__c,rs);
        system.assertEquals(lead.orgId__c,rs.orgId__c,rs);
        LeadIndex__c rs2 = [select id__c, orgId__c,EventSource__c from leadIndex__c where id = :lead2.id];
        system.assertEquals('37_106535992',rs2.id__c,rs2);
        system.assertEquals(lead2.Id__c,rs2.orgId__c,rs2);
    }
    static testMethod void myUnitTest1() {
        // TO DO: implement unit test
        LeadIndex__c lead = new LeadIndex__c(
        							ParentLeadIndxRef__c = null,
        							APPNAME__c = null, 
        							EntryDate__c = Date.today(),
        							EventSource__c = 'Neppan',
        							Id__c = String.valueOf('20160525143219167085'));
        insert lead;
		createDocementActionUpdate(lead.id);  
        Test.startTest();
    	TR1wayDataFixBatch batch = new TR1wayDataFixBatch(UserInfo.getUserId());
    	batch.testLoadXmlMsg = '<AllotmentBookingReport><TransactionType><DataFrom>Neppan</DataFrom><DataClassification>CancellationReport</DataClassification><DataID>20160525143219167085</DataID><SystemDate>2014-03-13</SystemDate><SystemTime>11:10:05</SystemTime></TransactionType><SalesOfficeInformation><SalesOfficeCompanyCode></SalesOfficeCompanyCode><SalesOfficeCompanyName>booking</SalesOfficeCompanyName></SalesOfficeInformation><BasicInformation><TravelAgencyBookingNumber>RSV291SH</TravelAgencyBookingNumber><TravelAgencyBookingDate>2013-05-16</TravelAgencyBookingDate></BasicInformation></AllotmentBookingReport>';
		ID batchprocessid = Database.executeBatch(batch,1);
        Test.stopTest();
        LeadIndex__c rs = [select id__c, orgId__c from leadIndex__c where id = :lead.id];
        system.assertEquals('_RSV291SH',rs.id__c,rs);
        system.assertEquals(lead.Id__c,rs.orgId__c,rs);
    }
    static testMethod void myUnitTest2() {
        // TO DO: implement unit test
         LeadIndex__c lead = new LeadIndex__c(
        							ParentLeadIndxRef__c = null,
        							APPNAME__c = 'TR',
        							EntryDate__c = Date.today(),
        							EventSource__c = 'FromNeppan',
        							Id__c = String.valueOf('20160525143219167085'));
        insert lead;
		createDocementActionUpdate(lead.id);  
        Test.startTest();
			// 次のスケジュールを起動する
			TR1wayDataFixBatch schedule = new TR1wayDataFixBatch();
	    	//schedule.testLoadXmlMsg = '<AllotmentBookingReport><TransactionType><DataFrom>Neppan</DataFrom><DataClassification>CancellationReport</DataClassification><DataID>20160525143219167085</DataID><SystemDate>2014-03-13</SystemDate><SystemTime>11:10:05</SystemTime></TransactionType><SalesOfficeInformation><SalesOfficeCompanyCode></SalesOfficeCompanyCode><SalesOfficeCompanyName>booking</SalesOfficeCompanyName></SalesOfficeInformation><BasicInformation><TravelAgencyBookingNumber>RSV291SH</TravelAgencyBookingNumber><TravelAgencyBookingDate>2013-05-16</TravelAgencyBookingDate></BasicInformation></AllotmentBookingReport>';
			Integer intervalLength = 10;
			DateTime nowTime = DateTime.now().addSeconds(intervalLength);
			// 起動ＣＲＯＮを設定する
			String timeStr = nowTime.format('yyyyMMddHHmmss');
			String yy = timeStr.substring(0,4);
			String mm = timeStr.substring(4,6);
			String dd = timeStr.substring(6,8);
			String hh = timeStr.substring(8,10);
			String ms = timeStr.substring(10,12);
			String ss = timeStr.substring(12,14);
			String sch = ss + ' ' +
         					ms + ' ' +
         					hh + ' ' +
     						dd + ' ' +
        					mm + ' ' +
         					' ? ' + yy;
			String jobName = 'TR1wayTo2wayDataFixBatch_' + DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
			String jobId = system.schedule(jobName, sch, schedule);
			
			TR1wayDataFixBatch batch = new TR1wayDataFixBatch(UserInfo.getUserId());
			batch.testLoadXmlMsg = '<AllotmentBookingReport><TransactionType><DataFrom>Neppan</DataFrom><DataClassification>CancellationReport</DataClassification><DataID>20160525143219167085</DataID><SystemDate>2014-03-13</SystemDate><SystemTime>11:10:05</SystemTime></TransactionType><SalesOfficeInformation><SalesOfficeCompanyCode></SalesOfficeCompanyCode><SalesOfficeCompanyName>booking</SalesOfficeCompanyName></SalesOfficeInformation><BasicInformation><TravelAgencyBookingNumber>RSV291SH</TravelAgencyBookingNumber><TravelAgencyBookingDate>2013-05-16</TravelAgencyBookingDate></BasicInformation></AllotmentBookingReport>';
			ID batchprocessid = Database.executeBatch(batch,1);
		Test.stopTest(); 
        LeadIndex__c rs = [select id__c, orgId__c from leadIndex__c where id = :lead.id];
        system.assertEquals('_RSV291SH',rs.id__c,rs);
        system.assertEquals(lead.Id__c,rs.orgId__c,rs);
    }
    static testMethod void myUnitTest3() {
        // TO DO: implement unit test
        LeadIndex__c lead = new LeadIndex__c(
        							ParentLeadIndxRef__c = null,
        							APPNAME__c = 'TL', 
        							EntryDate__c = Date.today(),
        							EventSource__c = 'FromAngency',
        							Id__c = String.valueOf('20160525143219167085'));
        insert lead;
		createDocementActionUpdate(lead.id);  
        Test.startTest();
    	TR1wayDataFixBatch batch = new TR1wayDataFixBatch(UserInfo.getUserId());
    	batch.testLoadXmlMsg = '<AllotmentBookingReport><TransactionType><DataFrom>Neppan</DataFrom><DataClassification>CancellationReport</DataClassification><DataID>20160525143219167085</DataID><SystemDate>2014-03-13</SystemDate><SystemTime>11:10:05</SystemTime></TransactionType><SalesOfficeInformation><SalesOfficeCompanyCode></SalesOfficeCompanyCode><SalesOfficeCompanyName>booking</SalesOfficeCompanyName></SalesOfficeInformation><BasicInformation><TravelAgencyBookingNumber>RSV291SH</TravelAgencyBookingNumber><TravelAgencyBookingDate>2013-05-16</TravelAgencyBookingDate></BasicInformation></AllotmentBookingReport>';
		ID batchprocessid = Database.executeBatch(batch,1);
        Test.stopTest();
        LeadIndex__c rs = [select id__c, orgId__c from leadIndex__c where id = :lead.id];
        system.assertEquals(lead.ID__c,rs.id__c,rs);
        system.assertEquals(lead.orgId__c,rs.orgId__c,rs);
    }
    private static void createDocementActionUpdate(String parentId){
		String infoTravelXML  = '<AllotmentBookingReport><TransactionType><DataFrom>Neppan</DataFrom><DataClassification>CancellationReport</DataClassification><DataID>20160525143219167085</DataID><SystemDate>2014-03-13</SystemDate><SystemTime>11:10:05</SystemTime></TransactionType><SalesOfficeInformation><SalesOfficeCompanyCode>37</SalesOfficeCompanyCode><SalesOfficeCompanyName>booking</SalesOfficeCompanyName></SalesOfficeInformation><BasicInformation><TravelAgencyBookingNumber>106535992</TravelAgencyBookingNumber><TravelAgencyBookingDate>2013-05-16</TravelAgencyBookingDate></BasicInformation></AllotmentBookingReport>';
		String dateKey = System.now().format('yyMMddHHMMssSSS');
		Attachment newAttach = new Attachment(
									ParentId = parentId,
									Name = 'TR_' + dateKey + '1_Test.xml', 
									ContentType = 'text/xml',
									Body = Blob.valueOf(infoTravelXML)
								);
		insert newAttach;
//		system.debug(loggingLevel.INfo, 'newAttach=' + newAttach);
    }
}