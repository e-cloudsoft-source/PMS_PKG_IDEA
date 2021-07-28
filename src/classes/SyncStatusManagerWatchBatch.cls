public with sharing class SyncStatusManagerWatchBatch implements Schedulable{
	
	//定数
	// 定期バッチの開始日
	private DateTime beginDt;
	// Chain Batch Flg
	private boolean isChainSchFlg;
	public SyncStatusManagerWatchBatch(){
		isChainSchFlg = false;
		beginDt = system.now();
	}
	// バッチChainから該当スケジュールを再起動の場合、該当バッチ初期起動の日付情報を格納する
	public SyncStatusManagerWatchBatch(DateTime pBeginDate) {
		beginDt = pBeginDate;
		isChainSchFlg = true;
	}
	// ***********************************
	// スケジュール処理開始
	// ***********************************
	public void execute(SchedulableContext SC) {	
		// 監視バッチの定義情報を格納する
		SyncStatusManagerCtrl.BatchStatusInfo watchBatch = null;
		// 定時実施のスケジュールに対して、新たChainのバッチを起動する場合、最新の日付を設定して、バッチを起動する
		if (!isChainSchFlg) beginDt = System.now();
		try {
			//loadNodeXml();
			// 2018/03/07 Security Check BEGIN
			List<String> insChkFields = new List<String>{'MessageHelpUrl__c','messagedttime__c','messagetype__c','MessageLevel__c','MessageCode__c','Message__c','Name'}; 
			Map<String,Schema.SObjectField> insm = Schema.SObjectType.MessageInformation__c.fields.getMap();
			if (!CommSecurityUtils.isCanCreateable(insChkFields, insm)) {
				return;
			}
			// 2018/03/07 Security Check END
			List<MessageInformation__c> errLst = new List<MessageInformation__c>();
			DateTime dt =DateTime.now();
			// ステータスチェックを行う
			SyncStatusManagerCtrl sync = new SyncStatusManagerCtrl();
			// 各バッチの状態をチェックする
			sync.init();
			SyncStatusManagerCtrl.BatchChkAndRestore batChkAndRestore = sync.batChkAndRestore;
			
			// 存在対象のバッチ状態をチェックする
			for (SyncStatusManagerCtrl.BatchStatusInfo batch : batChkAndRestore.batchStatusLst) {
				if (batch.jobTypeStr == SyncStatusManagerCtrl.JOBTYPE.WATCH.name()) {
					watchBatch = batch;
					continue;
				}
				// 各バッチチェックを行う
				// 機能有効、バッチ起動されない
				String msg = '';
				if (batch.statusOn && !batch.isRunning) {
					msg = batch.label + '状態異常(停止している)';
				} 
				// 機能無効、バッチ起動される場合
				else if (!batch.statusOn && batch.isRunning) {
					msg = batch.label + '状態異常(誤って起動されました)';
				}
				//if (!CommUtils.isBlank(msg)) errLst.add(msg);
				if (!CommUtils.isBlank(msg)) {
					MessageInformation__c newMessage = new MessageInformation__c();
					newMessage.Name = batch.label;
					newMessage.Message__c = msg;
					newMessage.MessageCode__c = '001';
					newMessage.MessageLevel__c = 'Error'; 	 
					newMessage.MessageType__c = getMessageType(batch); 	// カテゴリ
					newMessage.MessageDtTime__c = dt;
					newMessage.MessageHelpUrl__c = getRestoreUrl();
					errLst.add(newMessage);
				}
			}
			if (!errLst.isEmpty()) {
				insert errLst;
				String errMsg = '';
				for (MessageInformation__c msg : errLst) {
					errMsg += msg.Message__c + '\n';
				}
				setMessageToChatter(errMsg, watchBatch.isSendMail);
			}
			// エラーウインドウに送信を行う
			// メール送信しますか
		} catch (Exception e) {}
		//1時間後、次の監視スケジュールを起動する 3600
		Integer interVal = 0;
		if (watchBatch != null) {
			interVal = watchBatch.interval;
			// 日単位バッチスケジールをチェックする
		}
		if (interVal == 0) return;
		// 次の分単位のスケジール定義を行う
		DateTime nextTime = DateTime.now().addMinutes(interVal);
		if (isChainSchFlg) {
			// 次回の開始時間は２４時間を跨がる場合、処理中止
			DateTime equalDt = beginDt.addHours(24);
			if (nextTime > equalDt) return;
		}
		// 起動ＣＲＯＮを設定する
		String timeStr = nextTime.format('yyyyMMddHHmmss');
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
		//定数[]
		SyncStatusManagerWatchBatch schjob = new SyncStatusManagerWatchBatch(beginDt);
		String jobName = 'SyncStatusManagerWatchBatch_' + DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, sch, schjob);
	}
	private String getMessageType(SyncStatusManagerCtrl.BatchStatusInfo batch) {
		if (batch.jobTypeStr == SyncStatusManagerCtrl.JOBTYPE.TLIMP.name()  ||
			batch.jobTypeStr == SyncStatusManagerCtrl.JOBTYPE.TAIMP.name()  ||
			batch.jobTypeStr == SyncStatusManagerCtrl.JOBTYPE.JRIMP.name()  ) {
			return '予約取込';
		} 
		else if (batch.jobTypeStr == SyncStatusManagerCtrl.JOBTYPE.TLSTOCK.name()  ||
				 batch.jobTypeStr == SyncStatusManagerCtrl.JOBTYPE.TASTOCK.name()  ||
				 batch.jobTypeStr == SyncStatusManagerCtrl.JOBTYPE.JRSTOCK.name()  ) {
			return '在庫調整';
		}
		return '';
	}
	// Chatter Group Post
	private void setMessageToChatter(String msg, Boolean isSendMailFlg) {
			List<String> chatterGroupNamesLst = CommConst.GetChatterGroupNameByCode(CommConst.Coop_ChatterGroupNameType);
			List<CollaborationGroup> chatterGroups = [select Id, Name from CollaborationGroup where name = :chatterGroupNamesLst and isarchived = false];
        	if (chatterGroups.isEmpty()) return;
        	List<FeedItem> feedItems = new List<FeedItem>();
        	
        	String functionTypeStock = CommConst.COOP_FUNTYPE_STOCK;
    		String title = '復旧処理URL' +'\n';
    		String bodyMessage = '2wayバッチ状態異常になりました.\n\n' + msg + '\n\n';
    		String linkUrl = getRestoreUrl();
    		for (CollaborationGroup gp : chatterGroups) {
    			feedItems.add(sendMessageToChatter(gp.Id, title, bodyMessage, linkUrl));
    		}
        	if (!feedItems.isEmpty()) insert feedItems;
        	
        	if (isSendMailFlg) sendErroMail(bodyMessage, linkUrl);
	}
	private FeedItem sendMessageToChatter(Id chatterGroupId, String tilte, String bodyMessage, String linkUrl) {
		FeedItem post = new FeedItem();
		post.Type = 'LinkPost';
		post.title = tilte;
        post.Body = bodyMessage;
        post.ParentId = chatterGroupId;
        post.LinkUrl = linkUrl;
        return post;
	}
	private String getRestoreUrl() {
		String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
		//String nmspUrl = CommUtils.isBlank(CommConst.APPOTION_NAMESPACE) ? '' : ('/'+CommConst.APPOTION_NAMESPACE);
		//return baseUrl+'/apex'+nmspUrl+'/SyncStatusManager';
		PageReference page = new PageReference('/apex/SyncStatusManager');
		return (baseUrl + page.getUrl());
	}
	// 2017/03/30 異常が発生する場合、スケジール定義者へ送信する
	private void sendErroMail(String errMsg, String url) {
		// メール情報を設定する
		if (CommUtils.isBlank(errMsg)) return;
		String mailBodyStr = errMsg;
		mailBodyStr += '復旧処理URL:' + url;
		//連携データはCSV形式で添付致します
		String mailBodyStr1 = '\n\n' + Label.INF_9001 + '\n';	//  JinyaConnect Enterprise system R&D team.
	    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	    //PCA連携のバッチ処理結果の通知
		mail.setSubject('['+UserInfo.getOrganizationName()+'] 2wayバッチ状態異常の通知');
		mail.setPlainTextBody(mailBodyStr+mailBodyStr1);
		// メール送信
		String mailAdds = CommDefine__c.getOrgDefaults().ScheduleResultMailAddress__c;
		// メールアドレス未設定する場合、メール送信しない
		if (CommUtils.isBlank(mailAdds)) return;
		String[] toAddresses = mailAdds.split(',');
		mail.setToAddresses(toAddresses);
	   	// テストクラスの場合、実施しない
	   	// 送信できるがどうか、チェックを行う
	   	Boolean canSendMail = true;
	   	try {
	   		Messaging.reserveSingleEmailCapacity(toAddresses.size());
	   	} catch (Exception e){
	   		canSendMail = false;
	   	}
		if(!Test.isRunningTest() && canSendMail)
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	}
}