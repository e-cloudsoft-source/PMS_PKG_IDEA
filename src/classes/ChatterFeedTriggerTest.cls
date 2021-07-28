/**
 * Chatter⇒RECAIUS投稿用トリガテストクラス
 * 
 * 本番組織リリース時に必要なテストクラス
 * 
 * Copyright (c) 2018 TOSHIBA CORPORATION,  All Rights Reserved.
 */ 
@isTest(SeeAllData = true)
private class ChatterFeedTriggerTest {   
    

     static testMethod void ChatterPostTriggerMethod(){
        // 2018/03/26 Package Merge Edit Begin
        CommDefine__c comdef = TestCommon.createCommDefine();
        comdef.RecaiusFlg__c = true;
        update comdef;
        // 2018/03/26 Package Merge Edit End
        // test user create
        String user1_Id = RecaiusTestData.createUser1();        
        String user2_Id = RecaiusTestData.createUser2();        
        String user3_Id = RecaiusTestData.createUser3();
        CollaborationGroup g =new CollaborationGroup(Name='合成音声投稿グループ(test)',CollaborationType='public');
        CollaborationGroup g2 =new CollaborationGroup(Name='音声通知グループ２(test)',CollaborationType='public');
        insert g;
        insert g2;
        //投稿するtest
        String groupId = g.Id;
        //投稿しないtest
        String groupId2 = g2.Id;
        //RecaiusUserInfo__c data create
        List<RecaiusUserInfo__c> Ruser = new List<RecaiusUserInfo__c>();
        Ruser = RecaiusTestData.createRecaiusUserInfo(g.Name,groupId);
        String msg = 'testMsg';
		//feed作成
		//成功	
		FeedItem feed = new FeedItem();
		feed.Type = 'TextPost';         
         //開発環境
        feed.CreatedById = user1_Id;
    	feed.ParentId = groupId;
		feed.Body = msg;        
        //グループ違い
        FeedItem feed2 = new FeedItem();
        feed2.ParentId = groupId2;
        feed2.Body = 'test2';
         //開発環境
        feed2.CreatedById = user1_Id;                      
        //成功分岐名字
        FeedItem feed5 = new FeedItem();
		feed5.Type = 'TextPost';
         //開発環境
        feed5.CreatedById = user2_Id;          
    	feed5.ParentId = groupId;
		feed5.Body = msg+'5';        
        //成功分岐名前
        FeedItem feed6 = new FeedItem();
		feed6.Type = 'TextPost';         
         //開発環境
        feed6.CreatedById = user3_Id;                 
    	feed6.ParentId = groupId;
		feed6.Body = msg+'6';        
    	test.startTest();
    	
		HttpCallout.isRecaiusTestFlg = true;
        insert feed;        
        insert feed2;        
        insert feed5;
        insert feed6;
    
    	test.stopTest();
        HttpCallout.isRecaiusTestFlg = false;        
    }
    
    //RECAIUS callout test
    //login -> 投稿 -> logout 成功
    @isTest static void testCallout(){
        // 2018/03/26 Package Merge Edit Begin
        CommDefine__c comdef = TestCommon.createCommDefine();
        comdef.RecaiusFlg__c = true;
        update comdef;
        // 2018/03/26 Package Merge Edit End
        String feedText = 'test';
        Datetime speechtime =datetime.now();
        String account = 'testaccount';
        String contact = 'testcont';
        String pass = 'pass';
        String rgroup = 'rgroup';
        Decimal rid = 123;
        Test.setMock(HttpCalloutMock.class, new MockLogindexCallout());
        test.startTest();
        HttpCallout.recaiusPost(contact,account,pass,feedText,rid,speechtime);
        system.debug('--test--logindexsuccess');
        
        test.stopTest();
        
    }

    //login失敗
    @isTest static void testCalloutstatuscodeLoginfalse(){
        // 2018/03/26 Package Merge Edit Begin
        CommDefine__c comdef = TestCommon.createCommDefine();
        comdef.RecaiusFlg__c = true;
        update comdef;
        // 2018/03/26 Package Merge Edit End
        String feedText = 'testfalse';
        Datetime speechtime =datetime.now();
        String account = 'testaccount';
        String contact = 'testcont';
        String pass = 'pass';
        String rgroup = 'rgroup';
        Decimal rid = 123;
        
        Test.setMock(HttpCalloutMock.class, new MockLogindexCallout());
        test.startTest();
        MockLogindexCallout.LogindexStatusCode = true;
        HttpCallout.recaiusPost(contact,account,pass,feedText,rid,speechtime);
        test.stopTest();
        MockLogindexCallout.LogindexStatusCode = false;
    }

    //login成功 -> 投稿失敗
    @isTest static void testCalloutstatuscodespeechfalse(){
        // 2018/03/26 Package Merge Edit Begin
        CommDefine__c comdef = TestCommon.createCommDefine();
        comdef.RecaiusFlg__c = true;
        update comdef;
        // 2018/03/26 Package Merge Edit End
        String feedText = 'testspeechfalse';
        Datetime speechtime =datetime.now();
        String account = 'testaccount';
        String contact = 'testcont';
        String pass = 'pass';
        String rgroup = 'rgroup';
        Decimal rid = 123;
        
        Test.setMock(HttpCalloutMock.class, new MockLogindexCallout());
        test.startTest();
        MockLogindexCallout.LogindexSpeechStatusCode = true;
        HttpCallout.recaiusPost(contact,account,pass,feedText,rid,speechtime);
        test.stopTest();
        MockLogindexCallout.LogindexSpeechStatusCode = false;
    }

    //login成功 -> 投稿成功 -> logour失敗
    @isTest static void testCalloutstatuscodeLogoutfalse(){
        // 2018/03/26 Package Merge Edit Begin
        CommDefine__c comdef = TestCommon.createCommDefine();
        comdef.RecaiusFlg__c = true;
        update comdef;
        // 2018/03/26 Package Merge Edit End
        String feedText = 'testlogoutfalse';
        Datetime speechtime =datetime.now();
        String account = 'testaccount';
        String contact = 'testcont';
        String pass = 'pass';
        String rgroup = 'rgroup';
        Decimal rid = 123;
        
        Test.setMock(HttpCalloutMock.class, new MockLogindexCallout());
        MockLogindexCallout.LogindexLogoutStatusCode = true;
        test.startTest();
        HttpCallout.recaiusPost(contact,account,pass,feedText,rid,speechtime);
        test.stopTest();
        MockLogindexCallout.LogindexLogoutStatusCode = false;
    }

    @isTest static void testCalloutstatuscodeSpeechfalse2(){
        // 2018/03/26 Package Merge Edit Begin
        CommDefine__c comdef = TestCommon.createCommDefine();
        comdef.RecaiusFlg__c = true;
        update comdef;
        // 2018/03/26 Package Merge Edit End
        String feedText = 'testfalse';
        Datetime speechtime =datetime.now();
        String account = 'testaccount';
        String contact = 'testcont';
        String pass = 'pass';
        String rgroup = 'rgroup';
        Decimal rid = 123;
        
        Test.setMock(HttpCalloutMock.class, new MockLogindexCallout());
        MockLogindexCallout.LogindexexceptionStatusCode = true;
        MockLogindexCallout.LogindexLogoutStatusCode = true;
        test.startTest();
        HttpCallout.recaiusPost(contact,account,pass,feedText,rid,speechtime);
        test.stopTest();
        MockLogindexCallout.LogindexexceptionStatusCode = false;
        MockLogindexCallout.LogindexLogoutStatusCode = false;
    }

    @isTest static void testCalloutstatuscodeLoginException(){
        // 2018/03/26 Package Merge Edit Begin
        CommDefine__c comdef = TestCommon.createCommDefine();
        comdef.RecaiusFlg__c = true;
        update comdef;
        // 2018/03/26 Package Merge Edit End
        String feedText = 'testfalse';
        Datetime speechtime =datetime.now();
        String account = 'testaccount';
        String contact = 'testcont';
        String pass = 'pass';
        String rgroup = 'rgroup';
        Decimal rid = 123;
        
        Test.setMock(HttpCalloutMock.class, new MockLogindexCallout());
        MockLogindexCallout.LogindexexceptionStatusCode = true;
        MockLogindexCallout.LogindexSpeechStatusCode = true;
        test.startTest();
        HttpCallout.recaiusPost(contact,account,pass,feedText,rid,speechtime);
        test.stopTest();
        MockLogindexCallout.LogindexexceptionStatusCode = false;
        MockLogindexCallout.LogindexSpeechStatusCode = false;
    }

    //mention test
    @isTest static void chattermention(){
        // 2018/03/26 Package Merge Edit Begin
        CommDefine__c comdef = TestCommon.createCommDefine();
        comdef.RecaiusFlg__c = true;
        update comdef;
        // 2018/03/26 Package Merge Edit End
        HttpCallout.isRecaiusTestFlg = true;
        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
        ConnectApi.FeedItemInput feedItemInput2 = new ConnectApi.FeedItemInput();
        ConnectApi.FeedItemInput feedItemInput3 = new ConnectApi.FeedItemInput();
		ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
		ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
		ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();

        CollaborationGroup g =new CollaborationGroup(Name='合成音声投稿グループ(test)',CollaborationType='public');
        CollaborationGroup g2 =new CollaborationGroup(Name='音声通知グループ２(test)',CollaborationType='public');
        CollaborationGroup g3 =new CollaborationGroup(Name='音声通知グループ3(test)',CollaborationType='public');
        insert g;
        insert g2;
        insert g3;
        //投稿するtest
        String groupId = g.Id;
        String groupId3 = g3.Id;
        //投稿しないtest
        String groupId2 = g2.Id;

        //RecaiusUserInfo__c data create
        List<RecaiusUserInfo__c> Ruser = new List<RecaiusUserInfo__c>();
        Ruser = RecaiusTestData.createRecaiusUserInfo(g.Name,groupId);
        List<RecaiusUserInfo__c> Ruser3 = new List<RecaiusUserInfo__c>();
        Ruser3 = RecaiusTestData.createRecaiusUserInfo(g3.Name,groupId3);

		messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
		//メンション先ID
		mentionSegmentInput.id = groupId;
		messageBodyInput.messageSegments.add(mentionSegmentInput);

		textSegmentInput.text = 'mention test';
		messageBodyInput.messageSegments.add(textSegmentInput);

		feedItemInput.body = messageBodyInput;
		feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
        
        //フィード投稿先
		feedItemInput.subjectId = groupId2;        
        feedItemInput2.body = messageBodyInput;
		feedItemInput2.feedElementType = ConnectApi.FeedElementType.FeedItem;        
		feedItemInput2.subjectId = groupId;

        feedItemInput3.body = messageBodyInput;
		feedItemInput3.feedElementType = ConnectApi.FeedElementType.FeedItem;        
		feedItemInput3.subjectId = groupId3;
		
        test.startTest();
		ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
        ConnectApi.FeedElement feedElement2 = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput2);
        ConnectApi.FeedElement feedElement3 = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput3);
        //ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(null, feedItemInput);
        test.stopTest();
        HttpCallout.isRecaiusTestFlg = false;
    }
    
    @isTest static void chattermention_false(){
        // 2018/03/26 Package Merge Edit Begin
        CommDefine__c comdef = TestCommon.createCommDefine();
        comdef.RecaiusFlg__c = true;
        update comdef;
        // 2018/03/26 Package Merge Edit End
        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
		ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
		ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
		ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();

        //group create
        CollaborationGroup g =new CollaborationGroup(Name='合成音声投稿グループ(test)',CollaborationType='public');
        CollaborationGroup g2 =new CollaborationGroup(Name='音声通知グループ２(test)',CollaborationType='public');
        insert g;
        insert g2;
        //投稿するtest
        String groupId = g.Id;
        //投稿しないtest
        String groupId2 = g2.Id;
        List<RecaiusUserInfo__c> Ruser = new List<RecaiusUserInfo__c>();
        Ruser = RecaiusTestData.createRecaiusUserInfo(g.Name,groupId);

		messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
		//メンション先ID
		mentionSegmentInput.id = groupId2;        
		messageBodyInput.messageSegments.add(mentionSegmentInput);

		textSegmentInput.text = 'Not callout ';
		messageBodyInput.messageSegments.add(textSegmentInput);

		feedItemInput.body = messageBodyInput;
		feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
        
        //フィード投稿先
		feedItemInput.subjectId = groupId2;        
		System.debug('----Chatter mention False----');
        test.startTest();
		ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
        
        test.stopTest();
    }
    @isTest static void chatterCommentMention(){
        // 2018/03/26 Package Merge Edit Begin
        CommDefine__c comdef = TestCommon.createCommDefine();
        comdef.RecaiusFlg__c = true;
        update comdef;
        // 2018/03/26 Package Merge Edit End
        HttpCallout.isRecaiusTestFlg = true;

         // test user create
        String user1_Id = RecaiusTestData.createUser1();        
        String user2_Id = RecaiusTestData.createUser2();        
        String user3_Id = RecaiusTestData.createUser3();
        //group create
        CollaborationGroup g =new CollaborationGroup(Name='合成音声投稿グループ(test)',CollaborationType='public');
        CollaborationGroup g2 =new CollaborationGroup(Name='音声通知グループ２(test)',CollaborationType='public');
        insert g;
        insert g2;
        //投稿するtest
        String groupId = g.Id;
        //投稿しないtest
        String groupId2 = g2.Id;
        //RecaiusUserInfo__c data create
        List<RecaiusUserInfo__c> Ruser = new List<RecaiusUserInfo__c>();
        Ruser = RecaiusTestData.createRecaiusUserInfo(g.Name,groupId);        
  		String msg = 'test';
		//feed作成
		//成功	
		FeedItem feed = new FeedItem();
		feed.Type = 'TextPost';         
        feed.CreatedById = user1_Id;                 
    	feed.ParentId = groupId2;
		feed.Body = msg;
        
        insert feed;
        
        //開発環境
        List<FeedItem> fi = [SELECT Id FROM FeedItem WHERE CreatedById =:user1_Id limit 1];        
        
        ConnectApi.CommentInput commentInput = new ConnectApi.CommentInput();
        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        
        ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
        textSegmentInput.text = 'test comment mention';
        messageBodyInput.messageSegments.add(textSegmentInput);
        
        ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();        
        mentionSegmentInput.id = groupId;        
        messageBodyInput.messageSegments.add(mentionSegmentInput);
        
        CommentInput.Body = messageBodyInput;
        
        ConnectApi.CommentInput commentInput2 = new ConnectApi.CommentInput();
        ConnectApi.MessageBodyInput messageBodyInput2 = new ConnectApi.MessageBodyInput();
        messageBodyInput2.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        
        ConnectApi.TextSegmentInput textSegmentInput2 = new ConnectApi.TextSegmentInput();
        textSegmentInput2.text = 'test comment';
        messageBodyInput2.messageSegments.add(textSegmentInput);
        
        ConnectApi.MentionSegmentInput mentionSegmentInput2 = new ConnectApi.MentionSegmentInput();        
        mentionSegmentInput2.id = groupId2;
        messageBodyInput2.messageSegments.add(mentionSegmentInput2);
        
        CommentInput2.Body = messageBodyInput2;
        
        test.startTest();
        ConnectApi.Comment comment = ConnectApi.ChatterFeeds.postCommentToFeedElement(null, fi[0].id, CommentInput, null);
        ConnectApi.Comment comment2 = ConnectApi.ChatterFeeds.postCommentToFeedElement(null, fi[0].id, CommentInput2, null);
        test.stopTest();
        HttpCallout.isRecaiusTestFlg = false;
    }
    
}