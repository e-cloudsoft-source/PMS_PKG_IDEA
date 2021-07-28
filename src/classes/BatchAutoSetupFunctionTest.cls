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
private class BatchAutoSetupFunctionTest {
    @IsTest(SeeAllData=true)
    static void myUnitTest() {
    	Id userId = UserInfo.getUserId();
		String q = '@'+UserInfo.getName();
		String qStr = 'さん、テストデータ';
    
		ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
		ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
		ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
		ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();

		messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

		mentionSegmentInput.id = UserId;
		messageBodyInput.messageSegments.add(mentionSegmentInput);

		textSegmentInput.text = qStr;
		messageBodyInput.messageSegments.add(textSegmentInput);

		feedItemInput.body = messageBodyInput;
		feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;

		feedItemInput.subjectId = UserId;
		ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(null,feedItemInput );
        
        ConnectApi.FeedElementPage testPage = new ConnectApi.FeedElementPage();
        List<ConnectApi.FeedElement> testItemList = new List<ConnectApi.FeedElement>();
        testItemList.add(feedElement);
        testPage.elements = testItemList;

        ConnectApi.CommentInput input = new ConnectApi.CommentInput();
        ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
        ConnectApi.TextSegmentInput textSegment;
        ConnectApi.MarkupBeginSegmentInput markupBeginSegment;
        ConnectApi.MarkupEndSegmentInput markupEndSegment;

        messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

        markupBeginSegment = new ConnectApi.MarkupBeginSegmentInput();
        markupBeginSegment.markupType = ConnectApi.MarkupType.Code;
        messageInput.messageSegments.add(markupBeginSegment);

        textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = qStr;
        messageInput.messageSegments.add(textSegment);

        markupEndSegment = new ConnectApi.MarkupEndSegmentInput();
        markupEndSegment.markupType = ConnectApi.MarkupType.Code;
        messageInput.messageSegments.add(markupEndSegment);

        input.body = messageInput;
        ConnectApi.ChatterFeeds.postCommentToFeedElement(null, feedElement.Id, input,null);
        
		String pageToken = null;
        ConnectApi.ChatterFeeds.setTestSearchFeedElements(null, q, pageToken, 100, testPage);
        Test.startTest();
    	BatchAutoSetupFunction batch = new BatchAutoSetupFunction();

    	batch.proocessLikeItem(feedElement, q);
    	BatchAutoSetupFunction m = new BatchAutoSetupFunction();
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
    	System.schedule('AAAA', sch, m);
    	
    	Date dt = Date.today().adddays(-1);
    	BatchAutoSetupFunction batch2 = new BatchAutoSetupFunction(pageToken, dt);
    	DataBase.executeBatch(batch2,1);
        Test.stopTest();
    }
}