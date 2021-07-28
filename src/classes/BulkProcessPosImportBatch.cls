/*
* POSのCSVファイルを一括取込処理機能
* 2016/01/08 INIT
* 2016/01/29 取込済のファイルは削除から保留に変更、「ドキュメントの一意の名前」のキーが共通定義
*/
public with sharing class BulkProcessPosImportBatch implements Database.Batchable<Document>, Database.Stateful, Schedulable {

	private final String gShopCode;				// 店舗コード
	private Date gSaleDate;						// 売上計上日
	//private final String gRsvAccId;				// 指定の売上日
	private Boolean isFromSchedule;		// スケジュールからバッチ起動する
	// ファイル名一覧
	// 2016/01/29 取込済のファイルは削除から保留に変更、「ドキュメントの一意の名前」のキーが共通定義 BEGIN
	private final String CONST_POSKEY = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().PosFileKeyDef__c);
	private String CONST_TTOTAL = 'ttotal';
	private String CONST_TTEND  = 'ttend';
	private String CONST_TITEM  = 'titem';
	private list<string> fileNmLst = new list<string>{CONST_TTOTAL,CONST_TTEND,CONST_TITEM};
	// 2016/01/29 取込済のファイルは削除から保留に変更、「ドキュメントの一意の名前」のキーが共通定義 END
	// 今回処理対象の会計情報
	private map<string, AccountAcount__c> impAccountMap;
	// 処理済のファイル情報を格納する　
	//private list<id> fileIdsLst;
	// ログ情報格納用
	private String strErrMsg;

	// スケジュールで該当Methodを呼び出する
	public BulkProcessPosImportBatch(){
		isFromSchedule=true;
	}
	// 手動でスケジュール起動の場合
	public BulkProcessPosImportBatch (String pShopCd, Date pSaleDate) {
		gShopCode = pShopCd;
		//gSaleDate = pSaleDate;
		isFromSchedule = false;
	}
	// バッチ初期関数[スケジュールからバッチ起動]
	private BulkProcessPosImportBatch (String pShopCd, Date pSaleDate, Boolean pIsFromSchedule) {
		gShopCode = pShopCd;
		//gSaleDate = pSaleDate;
		isFromSchedule = pIsFromSchedule;
		impAccountMap = new map<string, AccountAcount__c>();
		//fileIdsLst = new list<id>();
		strErrMsg = '';
		// 2016/01/29 取込済のファイルは削除から保留に変更、「ドキュメントの一意の名前」のキーが共通定義 BEGIN
		if (!CommUtils.isBlank(CONST_POSKEY)) {
			String[] posKeyArr = CONST_POSKEY.split(',');
			if (posKeyArr.size() > 0) CONST_TTOTAL= posKeyArr[0];
			if (posKeyArr.size() > 1) CONST_TTEND = posKeyArr[1];
			if (posKeyArr.size() > 2) CONST_TITEM = posKeyArr[2];
			fileNmLst = new list<string>{CONST_TTOTAL,CONST_TTEND,CONST_TITEM};
		}
		// 2016/01/29 取込済のファイルは削除から保留に変更、「ドキュメントの一意の名前」のキーが共通定義 END
	}
	
	// ***********************************
	// スケジュール処理開始
	// ***********************************
	public void execute(SchedulableContext SC) {
		// 2016/08/25 SF初期化値を紛失機能回避
		if (isFromSchedule == null) isFromSchedule = true;
		if (isFromSchedule) {
			// システム日と処理日の差異日数
	      	//Integer days = CommDefine__c.getOrgDefaults().SchedulePcaDeviationDays__c == null ? 0 : CommDefine__c.getOrgDefaults().SchedulePcaDeviationDays__c.intValue();
			gSaleDate = Date.today();
		}

		// バッチスケジュールを起動する
		BulkProcessPosImportBatch batch = new BulkProcessPosImportBatch(gShopCode, gSaleDate, isFromSchedule);
		// バッチ処理設定
		DataBase.executeBatch(batch, 1);
	}
	// ***********************************
	// バッチ処理開始
	// ***********************************
	public Iterable<Document> start(Database.BatchableContext info){
		// スケジュールから起動する場合、全て店舗を処理する
		Folder posFolder = [select id from Folder where DeveloperName = 'PosFileImport'];
		List<Document> tmpFiles = [select name,DeveloperName,body from Document where DeveloperName in :fileNmLst and FolderId = :posFolder.Id];
		map<string, list<Document>> filesMap = new map<string, list<Document>>();
		for (Document file : tmpFiles) {
			string key = file.DeveloperName;
			if (!filesMap.containsKey(key)) filesMap.put(key, new list<Document>());
			filesMap.get(key).add(file);
		}
		List<Document> files = new List<Document>();
		for (String fileNm : fileNmLst) {
			if (filesMap.containsKey(fileNm)) {
				files.addAll(filesMap.get(fileNm));
			}
		}
		return files;
	}

	// ***********************************
	// バッチロジック処理開始
	// ***********************************
	public void execute(Database.BatchableContext BC, List<Document> scope){

		// エラーが発生すると、次の処理を行わない
		if (!CommUtils.isBlank(strErrMsg)) return;
		// ファイル名により、ファイル分析して、データ取込を行う
		Document posFile = scope[0];
		String fileName = posFile.DeveloperName;
		
try {
		PosSyncCsvTemplateCtrl posHandle = new PosSyncCsvTemplateCtrl();
		if (fileName == CONST_TTOTAL) {
			impAccountMap = posHandle.generalAccount(posFile.body.tostring());
			// 営業日情報を設定する　
			if (impAccountMap != null && !impAccountMap.isEmpty()) {
				// 関連の売上から営業日付を取得する
				Id salesId = impAccountMap.values()[0].frs__c;
				list<RsvAccount__c> rsvLst = [select Salesday__c from RsvAccount__c where id = :salesId limit 1];
				if (!rsvLst.isEmpty()) gSaleDate = rsvLst[0].Salesday__c;
			}
		} else if (fileName == CONST_TTEND) {
			// 会計支払情報を登録する
			posHandle.generalTtend(posFile.body.tostring(), impAccountMap);
		} else if (fileName == CONST_TITEM) {
			// 会計明細情報を登録する
			posHandle.generalTrand(posFile.body.tostring(), impAccountMap);
		}
// エラーが発生する場合、処理中止
} catch (Exception e) {
	// ゴミデータを削除する
	deleteDumyDataByErr(impAccountMap);
	// エラーメッセージを送信する
	//取込エラーが発生しました。
	if (CommUtils.isBlank(strErrMsg)) strErrMsg = Label.MSG_046_0018;
	String objName = AccountAcount__c.getSObjectType().getDescribe().getLabel();
	if (fileName == CONST_TTEND) objName = TTend__c.getSObjectType().getDescribe().getLabel();
	else if (fileName == CONST_TITEM) objName = Tran1__c.getSObjectType().getDescribe().getLabel();
	strErrMsg+= '\n'+objName + '：' + e.getMessage();
}
		// 処理済のファイルのID情報を格納する
		//fileIdsLst.add(posFile.Id);
	}
	// ***********************************
	// バッチ終了処理開始
	// ***********************************
	public void finish(Database.BatchableContext BC){
		// 処理結果はOKの場合、
		// 処理済のドキュメントを削除する
		// 2016/01/29 取込済のファイルは削除から保留に変更、「ドキュメントの一意の名前」のキーが共通定義 BEGIN
		/*
		if (CommUtils.isBlank(strErrMsg)) {
			String strSalesDt = (gSaleDate == null) ? '' : (DateTime.newInstance(gSaleDate.year(),gSaleDate.month(),gSaleDate.day()).format('yyyyMMdd'));
			String strNowTime = System.now().format('yyyyMMddHHmmssSSS');
			list<document> delDocs = [select id,name,DeveloperName from document where id in :fileIdsLst];
			for (document doc : delDocs) {
				doc.name = doc.name.mid(0,67) + '_' + ( CommUtils.isBlank(strSalesDt) ? '' : strSalesDt+'_') + '取込済';
				doc.DeveloperName = doc.DeveloperName + '_' + strNowTime;
				doc.Description = strNowTime + '_取込済';
			}
			update delDocs;
			delete delDocs;
		}*/
		// 2016/01/29 取込済のファイルは削除から保留に変更、「ドキュメントの一意の名前」のキーが共通定義 END
		// 処理結果を送信する
		sendPosImportMail(strErrMsg);
	}
	
	private void deleteDumyDataByErr(map<string, AccountAcount__c> accsMap) {
		// 削除対象なしの場合
		if (accsMap== null || accsMap.isEmpty()) return;
		// 削除対象あり場合、関連の会計、会計支払、会計明細を削除する
		set<id> accIdSet = new set<Id>();
		for (AccountAcount__c acc : accsMap.values()) {
			if (acc.id == null) break;
			accIdSet.add(acc.Id);
		}
		// 2017/04/13 Sobject Security Check BEGIN
		if (!CommSecurityUtils.isDeleteable(Ttend__c.getSObjectType()) ||
			!CommSecurityUtils.isDeleteable(Tran1__c.getSObjectType()) ||
			!CommSecurityUtils.isDeleteable(AccountAcount__c.getSObjectType())) {
			return;
		}
		// 2017/04/13 Sobject Security Check END
		// 既に登録の情報を削除する　
		if (!accIdSet.isEmpty()) {
			delete [select id from Ttend__c Where Field1__c in :accIdSet];
			delete [select id from Tran1__c Where Field1__c in :accIdSet];
			delete [select id from AccountAcount__c Where id in :accIdSet];
		}
	}
	/**
	* メール送信機能対応:
	**/
	private void sendPosImportMail(String errMsg) {
		// 連携結果履歴に記録する
		// メール情報を設定する
		//POS取込バッチが以下の通リ終了しましたのでお知らせいたします。
		String mailBodyStr = Label.INF_0003_03;
		if (gSaleDate != null) {
			//売上計上日:
			mailBodyStr += '\n'+ Label.CONST_046_0019 +' ' + (DateTime.newInstance(gSaleDate.year(),gSaleDate.month(),gSaleDate.day()).format('yyyyMMdd'));
		}
		if (!CommUtils.isBlank(gShopCode)) {
			// 関連店舗情報を取得する　
			List<ShopInformation__c> shops = [select id,name from ShopInformation__c where shopCode__c =:gShopCode limit 1 ];
			//店舗:
			if (!shops.isEmpty()) mailBodyStr += '\n'+ Label.CONST_046_0020 +' ' + shops[0].Name;
		}
		// エラー情報が存在する場合、エラーメッセージを出力する　
		if (!CommUtils.isBlank(errMsg))  {
			//処理結果：
			mailBodyStr += '\n\n'+ Label.CONST_046_0021  + errMsg;
		} else {
			
			if (impAccountMap.isEmpty()) {
				//処理結果：取込対象データがありません。
				mailBodyStr += '\n\n'+ Label.CONST_046_0022;
			} else {
				//処理結果：POSデータの取込みは正常に終了しました。
				mailBodyStr += '\n\n'+ Label.CONST_046_0023;
			}
		}
		mailBodyStr += '\n\n' + Label.INF_9001 + '\n';	//  JinyaConnect Enterprise system R&D team.

	    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	    //POS取込バッチ処理結果の通知
		mail.setSubject('['+UserInfo.getOrganizationName()+'] '+ Label.CONST_046_0024);
		mail.setPlainTextBody(mailBodyStr);
		// Chatterへポストする　
		sendMsgToChatter(mail, mailBodyStr);
	   	// テストクラスの場合、実施しない 
		// メール通知先のメールアドバイスを取得、設定する
		AccountingSyncBatchHelp config = new AccountingSyncBatchHelp('');
		// 送付先メールアドレス情報を取得する
		if (config == null || config.sendMailAddr.isEmpty()) return;
		String[] toAddresses = config.sendMailAddr;
		mail.setToAddresses(toAddresses);
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
	/**
	* ChatterGroup送信機能対応:
	**/
	private void sendMsgToChatter(Messaging.SingleEmailMessage mail, String pMsgBody) {
		// 
		List<String> chatterGroupNamesLst = CommConst.GetChatterGroupNameByCode(CommConst.PosI_ChatterGroupNameType);
		List<CollaborationGroup> chatterGroups = [select Id, Name from CollaborationGroup where name = :chatterGroupNamesLst and isarchived = false];
    	if (chatterGroups.isEmpty()) return;

    	String msgBody = mail.getSubject() + '\n\n';
  		msgBody += pMsgBody;
  		
    	List<FeedItem> feedItems = new List<FeedItem>();

    	for (CollaborationGroup cGroup : chatterGroups) {
			
			FeedItem post = new FeedItem();
			post.Type = 'TextPost';
	        post.Body = msgBody;
	        post.ParentId = cGroup.Id;
	        feedItems.add(post);
    	}
    	if (!feedItems.isEmpty()) insert feedItems;
	}
}