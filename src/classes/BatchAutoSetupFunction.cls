global with sharing class BatchAutoSetupFunction implements Database.Batchable<ConnectApi.FeedElement>, Database.Stateful, Schedulable{
    private String pageToken;//次の処理TOKEN
    private Date checkRangeDt;//処理対象期間
    private String q;//検索キー
	global BatchAutoSetupFunction(){
		pageToken = null;
		checkRangeDt = Date.today().addDays(-1);
	}
	public BatchAutoSetupFunction(String nextToken, Date pBegDt) {
		pageToken = nextToken;
		checkRangeDt = pBegDt;
	}
	// ***********************************
	// スケジュール処理開始
	// ***********************************
	public void execute(SchedulableContext SC) {
		// バッチ処理設定
		BatchAutoSetupFunction batch = new BatchAutoSetupFunction();
		DataBase.executeBatch(batch,1);
	}
	// ***********************************
	// バッチ処理開始
	// ***********************************
	public Iterable<ConnectApi.FeedElement> start(Database.BatchableContext BC){
		List<User> usr = [select Name from User where id = :userInfo.getUserId() And IsActive = true];
		q = '@'+usr[0].Name;
		ConnectApi.FeedElementPage pages = ConnectApi.ChatterFeeds.searchFeedElements(null, q, pageToken, 100);
		pageToken = pages.nextPageToken;
		return pages.elements;
	}
	// ***********************************
	// バッチロジック処理開始:SIZE=1前提
	// ***********************************
	public void execute(Database.BatchableContext BC, List<ConnectApi.FeedElement> scope){
		for (ConnectApi.FeedElement item : scope) {
			if (item.modifiedDate.date() < checkRangeDt) {
				// 処理中止
				pageToken = null;
				break;
			} else {
				// 内容処理を行う
				proocessLikeItem(item,q);
			}
		}
	}
	// ***********************************
	// バッチ終了処理開始
	// ***********************************
	public void finish(Database.BatchableContext BC){
		if (pageToken != null) {
			// バッチ処理設定
			BatchAutoSetupFunction batch = new BatchAutoSetupFunction(pageToken, checkRangeDt);
			DataBase.executeBatch(batch,1);
		}
	}
	// chatter数据处理
	@TestVisible
	private void proocessLikeItem(ConnectApi.FeedElement item, String q){
    	// feeditem数据
    	ConnectApi.FeedItem feedItem = (ConnectApi.FeedItem)item;
		// FeedItemのコメントのLIKE処理
    	if (feedItem.capabilities.comments.page.total > 0 || Test.isRunningTest()) {
    		List<ConnectApi.Comment> feedCommentItems = feedItem.capabilities.comments.page.items;
    		for(ConnectApi.Comment commentItem : feedCommentItems){
    			//すでにLIKE済み、再処理不要
    			if (commentItem.myLike != null) continue;
    			for(ConnectApi.MessageSegment message : commentItem.body.messageSegments) {
    				if (message instanceof ConnectApi.MentionSegment) {
    					// 取得的コメント内的@user与定义user一致，いいね!状态变更为いいね! を取り消す 
    					if(message.text == q) {
    						ConnectApi.ChatterLike chatterLike2 = ConnectApi.ChatterFeeds.likeComment(null, commentItem.id);
    						break;
    					}
    				}
    			}
    		}
    	} 
    	// FeedItemのLIKE処理
		List<ConnectApi.MessageSegment> messageSegments = feedItem.body.messageSegments;
		for (ConnectApi.MessageSegment message : messageSegments) {
			if (message instanceof ConnectApi.MentionSegment) {
				// 取得最初post数据@user与定义user一致，いいね!状态变更为いいね! を取り消す 
				if(message.text == q) {
					ConnectApi.ChatterLike chatterLike1 = ConnectApi.ChatterFeeds.likeFeedElement(null, item.id);
					break;
				}
			}
		}
	}
}