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
private class BatchGetWebSiteInfoTest {
	@isTest(SeeAllData=true)
    static void myUnitTest() {
        // TO DO: implement unit test
        createConfigDoc();
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl());
    	BatchGetWebSiteInfo m = new BatchGetWebSiteInfo();
    	BatchGetWebSiteInfo.ParseInfo inf = BatchGetWebSiteInfo.getParseInfo();
		String sch = getScheduleTime();
    	System.schedule('AAAA', sch, m);
        Test.stopTest();
    }
	@isTest(SeeAllData=true)
    static void myUnitTest2() {
        // TO DO: implement unit test
        createConfigDoc();
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true,true));
    	BatchGetWebSiteInfo m = new BatchGetWebSiteInfo();
    	BatchGetWebSiteInfo.MaxRetryNum = 0;
    	BatchGetWebSiteInfo.ParseInfo inf = BatchGetWebSiteInfo.getParseInfo();
		String sch = getScheduleTime();
    	System.schedule('AAAA', sch, m);
        Test.stopTest();
    }
    private static void createConfigDoc() {
        String configXml = '<?xml version="1.0" encoding="UTF-8"?>'
							+'<root>'
							+'<Campaign>'				
							+'<AutoGetInfo>'
							+'<WebSiteUrl>http://www.jinya-inn.com/databox/data.php/topics_ja/code#filter=.topics_01_ja</WebSiteUrl>'
							+'<MessageBlock>'
							+'<HTML_BEG>class="portfolio-item col-lg-4 col-md-6 col-sm-6 col-xs-12 topics_01_ja</HTML_BEG>'
							+'<HTML_END>/li</HTML_END>'
							+'<FILTER>'
							+'<HTML_BEG>&lt;h4 class="text-left"&gt;</HTML_BEG>'
							+'<HTML_END>&lt;/h4&gt;</HTML_END>'
							+'<HTML_STRIP>TRUE</HTML_STRIP>'
							+'</FILTER>'
							+'<FILTER>'
							+'<HTML_BEG>&lt;p class="text-left mt10"&gt;</HTML_BEG>'
							+'<HTML_END>&lt;/p&gt;</HTML_END>'
							+'<HTML_STRIP>TRUE</HTML_STRIP>'
							+'</FILTER>'
							+'<CONTENT_TYPE>text/plain</CONTENT_TYPE>'
							+'<FILE_NAME>WorkFileImgForCampaign_'+CommUtils.getRandom(4)+'</FILE_NAME>'
							+'</MessageBlock>'
							+'<ImageBlock>'
							+'<HTML_BEG>class="portfolio-item col-lg-4 col-md-6 col-sm-6 col-xs-12 topics_01_ja</HTML_BEG>'
							+'<HTML_END>/li</HTML_END>'
							+'<FILTER>'
							+'<HTML_BEG>img src="</HTML_BEG>'
							+'<HTML_END>"</HTML_END>'
							+'</FILTER>'
							+'<CONTENT_TYPE>image/jpeg</CONTENT_TYPE>'
							+'<FILE_NAME>WorkFileImgForCampaign_'+CommUtils.getRandom(4)+'</FILE_NAME>'
							+'</ImageBlock>'
							+'</AutoGetInfo>'
							+'</Campaign>'+
							'</root>';
        // ドキュメントを作成する
        Document item = new Document();
        item.Name = 'BatchGetWebSiteInfoConfig';
        item.DeveloperName = item.Name;
        item.FolderId = UserInfo.getUserId();
        item.Body = Blob.valueOf(configXml);
        insert item;
	}
	
	private static String getScheduleTime() {
    	DateTime nowTime = DateTime.now().addSeconds(10);
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
		return sch;
    }
	
}