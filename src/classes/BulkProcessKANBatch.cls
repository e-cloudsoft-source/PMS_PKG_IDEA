/**
* 勘定奉行連携機能（バッチスケジュール
* 2016/09/16 INIT
* 2018/04/20 仕訳集計対象期間指定できるように改善対応
**/
public with sharing class BulkProcessKANBatch  implements Database.Batchable<ShopInformation__c>, Database.Stateful, Schedulable {

	public final String rsvAccId;						// 売上のSFのID
	public String saleDate;								// 売上計上日
	//private String gBatchMode;							// バッチモード（PCA/FREEE）
	private final String gShopCode;						// 店舗コード
	private Boolean isFromSchedule;				// スケジュールからバッチ起動する
	// 2018/04/20 仕訳集計対象期間指定できるように改善対応 BEGIN
	private Boolean isBetweenProcess = false;   // 期間指定処理フラグ
	private String saleEndDate;                 // 期間指定の場合、終了日情報を格納する
	private String gshopName;                   // 期間指定の場合、指定の店舗名情報を格納
	private List<String> rsvAccIds;     // 期間指定の売上IDの配列
	private List<String> rsvAccNms;     // 期間指定の売上名の配列
	private List<String> gNextJobs;
	private String sumMessage = '';     // 処理メッセージ情報を格納用
	// 2018/04/20 仕訳集計対象期間指定できるように改善対応 END
	private static final String PCA_BATCH_RESULT_METHOD_NONE = '0';
	private static final String PCA_BATCH_RESULT_METHOD_SENDMAIL = '1';
	private static final String PCA_BATCH_RESULT_METHOD_RELFILE = '2';
	private static final String PCA_BATCH_RESULT_METHOD_SENDANDSAVE = '3';
	private static final String APPOTION_PCARESULT_SENDTYPE = CommDefine__c.getInstance().SchedulePcaResultSendType__c == null 
																	? PCA_BATCH_RESULT_METHOD_SENDMAIL
																	: CommDefine__c.getInstance().SchedulePcaResultSendType__c;	
	
	private String batchProcessJobNo;					// バッチ処理のSEQNO
	private String batchFilePrefixKey;					// 前方キー
	// 共通定義；会計連携用CSV出力種別「PCA/FREEE」
	//private static final String pcaSyncCtrlCode = CommDefine__c.getOrgDefaults().AccountSoftSyncCsvType__c;
	//public static final String CSV_OUTPUT_MODE_PCA = '1';			// PCA連携CSV出力モード
	//public static final String CSV_OUTPUT_MODE_FREEE = '2';		// Freee連携CSV出力モード
	//private static final Boolean isCsvOutModeFreee = (pcaSyncCtrlCode == CSV_OUTPUT_MODE_FREEE);	// Freee連携出力するがどうか
	// スケジュールで該当Methodを呼び出する
	public BulkProcessKANBatch(){
		isFromSchedule = true;
		//gBatchMode = pcaSyncCtrlCode;
	}
	// 手動でスケジュール起動の場合
	// pShopCd
	// pSaleDate
	// batchMode: 1(PCA連携CSV出力モード) OR 2(Freee連携CSV出力モード)
	// 2018/04/20 仕訳集計対象期間指定できるように改善対応 BEGIN
	//public BulkProcessKANBatch (String pShopCd, Date pSaleDate) {
	public BulkProcessKANBatch (String pShopCd, Date pSaleDate, Date pSaleEndDate, List<String> pNextJobs) {
        // 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 BEGIN
        if (pSaleEndDate != null) {
            isBetweenProcess = true;
        } else {
            isBetweenProcess = false;
            // 同じ日付を設定する
            pSaleEndDate = pSaleDate;
        }
        saleEndDate = DateTime.newInstance(pSaleEndDate.year(), pSaleEndDate.month(), pSaleEndDate.day()).format('yyyyMMdd');
        gNextJobs = pNextJobs;
        // 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 END
	// 2018/04/20 仕訳集計対象期間指定できるように改善対応 END
		isFromSchedule = false;
		gShopCode = pShopCd;
		saleDate = DateTime.newInstance(pSaleDate.year(), pSaleDate.month(), pSaleDate.day()).format('yyyyMMdd');
		//gBatchMode = pBatchMode;
	}
	// rsvAccId:指定の売上日情報[バッチ起動するのパラメータ情報を指定する]
	// 2018/04/20 仕訳集計対象期間指定できるように改善対応 BEGIN
	//private BulkProcessKANBatch (String pRsvId, String pRsvNm, String pShopCode,Boolean pIsFromSchedule) {
	private BulkProcessKANBatch (List<String> pRsvId, List<String> pRsvNm, String pShopCode,Boolean pIsFromSchedule, String pSaleDate ,String pSaleEndDate, List<String> pNextJobs, Boolean pIsBetweenProcess) { 
        rsvAccIds = pRsvId;
        rsvAccNms = pRsvNm;
        gNextJobs = pNextJobs;
        // 既存バッチスケジールを自動続けて実施できる対応
        isBetweenProcess = pIsBetweenProcess == null ? false : pIsBetweenProcess;
        saleDate = pSaleDate;
        saleEndDate = pSaleEndDate;
		//rsvAccId = pRsvId;
		//saleDate = pRsvNm;
        // 2018/04/20 仕訳集計対象期間指定できるように改善対応 END
		gShopCode = pShopCode;
		//batchProcessJobNo = 'PCA_' + System.now().format('yyyyMMddHHmmss');
		// 2015.12.04 ファイルName設定ルール変更、作成日から処理日に設定する BEGIN
		//batchProcessJobNo = System.now().format('yyyyMMddHHmmss');
		batchProcessJobNo = saleDate + System.now().format('HHmmss');
		// 2015.12.04 ファイルName設定ルール変更、作成日から処理日に設定する END
		isFromSchedule = pIsFromSchedule;
		// 2015.12.24 バッチ・モード
		//gBatchMode = pBatchMode;
	}
	// ***********************************
	// スケジュール処理開始
	// ***********************************
	public void execute(SchedulableContext SC) {
		// 2016/08/25 SF初期化値を紛失機能回避
		if (isFromSchedule == null) isFromSchedule = true;
		if (isFromSchedule) {
	     	 // システム日と処理日の差異日数
	      	Integer days = CommDefine__c.getOrgDefaults().SchedulePcaDeviationDays__c == null ? 0 : CommDefine__c.getOrgDefaults().SchedulePcaDeviationDays__c.intValue();
	      	Date startDate = (Date.today().addDays(days));
			// スケジュール実施開始日
			saleDate = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('yyyyMMdd');
			// 2015.12.24 バッチ・モード
			//gBatchMode = CommDefine__c.getOrgDefaults().AccountSoftSyncCsvType__c;
			//if (CommUtils.isBlank(gBatchMode)) gBatchMode = CSV_OUTPUT_MODE_PCA;
		}
		// 2018/04/20 仕訳集計対象期間指定できるように改善対応 BEGIN
		/*
		List<RsvAccount__c> rsvAccLst = [select id,Name from RsvAccount__c where Name = :saleDate limit 1];
		// 休館日など売上ないの場合
		if (rsvAccLst.isEmpty()) {
			// 処理終了
			return;
		}*/
		// 2018/04/20 仕訳集計対象期間指定できるように改善対応 END
		// バッチクラスを呼び出す
        // 2018/04/20 仕訳集計対象期間指定できるように改善対応 BEGIN
        if (!initBatchInfo()) return;
		//BulkProcessKANBatch batch = new BulkProcessKANBatch(rsvAccLst[0].Id, rsvAccLst[0].Name, gShopCode,isFromSchedule);
		BulkProcessKANBatch batch = new BulkProcessKANBatch(rsvAccIds, rsvAccNms, gShopCode,isFromSchedule, saleDate, saleEndDate, gNextJobs,isBetweenProcess);
		// 2018/04/20 仕訳集計対象期間指定できるように改善対応 END
		// バッチ処理設定
		DataBase.executeBatch(batch, 1);
	}
    // 2018/04/20 仕訳集計対象期間指定できるように改善対応 BEGIN
    // バッチ実施用パラメータを初期化する
    private boolean initBatchInfo() {
        // 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 BEGIN
        rsvAccIds = new List<String>();
        rsvAccNms = new List<String>();
        Set<String> salesDatesSet = new Set<String>();
        // 2017/03/16 既存バッチスケジールを自動続けて実施できる対応 BUGFIX BEGIN
        //if (isBetweenProcess) {
        if (isBetweenProcess != null && isBetweenProcess) {
        // 2017/03/16 既存バッチスケジールを自動続けて実施できる対応 BUGFIX END
            // 指定期間の売上名リストを取得する
            Date beginDate = CommUtils.stringToDate(saleDate);
            Date endDate = CommUtils.stringToDate(saleEndDate);
            //List<Date> rsLst = new List<Date>();
            while (beginDate <= endDate) {
                // 書式化する
                String currDtStr = DateTime.newInstance(beginDate.year(),beginDate.month(),beginDate.day()).format('yyyyMMdd');
                salesDatesSet.add(currDtStr);
                beginDate = beginDate.adddays(1);
            }
        } else {
            salesDatesSet.add(saleDate);
        }
        List<RsvAccount__c> rsvAccLst = [select id,Name from RsvAccount__c where Name = :salesDatesSet ];
        // 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 END
        // 休館日など売上ないの場合
        if (rsvAccLst.isEmpty()) {
            // 処理終了
            return false;
        }
        // 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 BEGIN
        // バッチクラスを呼び出す
        for (RsvAccount__c rsv : rsvAccLst) {
            rsvAccIds.add(rsv.Id);
            rsvAccNms.add(rsv.Name);
        }
        return true;
    }
    // 2018/04/20 仕訳集計対象期間指定できるように改善対応 END
	// ***********************************
	// バッチ処理開始
	// ***********************************
	public Iterable<ShopInformation__c> start(Database.BatchableContext info){ 
        // 2018/04/20 仕訳集計対象期間指定できるように改善対応 BEGIN
        if (rsvAccIds.isEmpty()) return new List<ShopInformation__c>();
        // 2018/04/20 仕訳集計対象期間指定できるように改善対応 END
		// スケジュールから起動する場合、全て店舗を処理する
		List<ShopInformation__c> shops = new List<ShopInformation__c>();
		if (isFromSchedule) {
			shops = [	
					SELECT 
	                Id
	                , Name
	                , ShopCode__c
	                From ShopInformation__c order by Seq__c limit 100];
	   		// Dumy Shop Info Create
			if (shops.isEmpty()) shops.add(new ShopInformation__c());
            // 2018/04/20 仕訳集計対象期間指定できるように改善対応 BEGIN
            for (ShopInformation__c shop : shops) {
                shop.Payee1__c = rsvAccIds[0];
                shop.Payee2__c = rsvAccNms[0];
            }
            // 2018/04/20 仕訳集計対象期間指定できるように改善対応 END
		} 
		// 手動でスケジュールを起動する
		else {
			if (CommUtils.isBlank(gShopCode)) {
				shops.add(new ShopInformation__c());
			} else {
				// 指定店舗コードにより、店舗情報を取得する
				// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 BEGIN
				//shops.add([select id, name, shopcode__c from ShopInformation__c where shopcode__c =:gShopCode limit 1]);
				shops = [select id, name, shopcode__c from ShopInformation__c where shopcode__c =:gShopCode limit 1];
				if (shops.isEmpty()) shops.add(new ShopInformation__c());
				// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 END
			}
            // 2018/04/20 仕訳集計対象期間指定できるように改善対応 BEGIN
            if (isBetweenProcess) {
                // 該当店舗コードをコピー
                ShopInformation__c wkShop = shops[0].clone(false,true);
                gshopName = CommUtils.nullToBlank(wkShop.Name);
                shops.clear();
                for (Integer i= 0; i< rsvAccIds.size(); i++) {
                    String rsvId = rsvAccIds[i];
                    String rsvNm = rsvAccNms[i];
                    ShopInformation__c cloneShop = wkShop.clone(false,true);
                    cloneShop.Payee1__c = rsvId;
                    cloneShop.Payee2__c = rsvNm;
                    shops.add(cloneShop);
                }
            } else {
	    	// 2018/04/20 仕訳集計対象期間指定できるように改善対応 BEGIN
                gshopName = CommUtils.nullToBlank(shops[0].Name);
		// 2018/04/20 仕訳集計対象期間指定できるように改善対応 END
                for (ShopInformation__c shop : shops) {
                    shop.Payee1__c = rsvAccIds[0];
                    shop.Payee2__c = rsvAccNms[0];
                }
            }
            // 2018/04/20 仕訳集計対象期間指定できるように改善対応 END
		}
		return shops;
	}

	// ***********************************
	// バッチロジック処理開始
	// ***********************************
	public void execute(Database.BatchableContext BC, List<ShopInformation__c> scope){
        // 2018/04/20 仕訳集計対象期間指定できるように改善対応 BEGIN
		// 販売データが非存在場合、処理中止、メール送信を行う
		//if (CommUtils.isBlank(rsvAccId)) return;
		// 2018/04/20 仕訳集計対象期間指定できるように改善対応 END
		// バッチモード区分
		//Boolean isFreeeMode = (gBatchMode == CSV_OUTPUT_MODE_FREEE);
		// 2016/01/18 Chatterグループへ送信、借方金額は貸方金額と合わない場合、WARNING情報を出力する BEGIN
		String warningMsg = '';
		// 2016/01/18 Chatterグループへ送信、借方金額は貸方金額と合わない場合、WARNING情報を出力する END
		// 支店コードを取得する
		for (ShopInformation__c shop : scope) {
			String csvBody = '';
			// 2018/04/20 仕訳集計対象期間指定できるように改善対応 BEGIN
			String wkRsvAccId = shop.Payee1__c;
			if (!isFromSchedule) {
				batchProcessJobNo = shop.Payee2__c + System.now().format('HHmmss');
			}
			//KanSyncCsvTemplateCtrl ctrl = new KanSyncCsvTemplateCtrl(rsvAccId,CommUtils.nullToBlank(shop.ShopCode__c));
			KanSyncCsvTemplateCtrl ctrl = new KanSyncCsvTemplateCtrl(wkRsvAccId,CommUtils.nullToBlank(shop.ShopCode__c));
			// 2018/04/20 仕訳集計対象期間指定できるように改善対応 BEGIN
			csvBody = ctrl.generalCsvContent();
			// 明細情報がなかった場合、送信を行わない
			// 2018/04/23 処理内容がなかったの場合でも、メール通知を行う変更対応 BEGIN
			//if (ctrl.isEmptyCsvBody) continue;
			// 2018/04/23 処理内容がなかったの場合でも、メール通知を行う変更対応 END
			// 出力ログ情報を設定する
			// 2018/06/12 仕訳Rollup機能追加対応 BEGIN
			//warningMsg = ctrl.msgStr;
			// 2018/04/20 仕訳集計対象期間指定できるように改善対応 BEGIN
			//if (!CommUtils.isBlank(warningMsg)) sumMessage += '\n' + shop.Payee2__c + '\n' + warningMsg;
			// 2018/06/12 仕訳Rollup機能追加対応 END
			// 2018/04/20 仕訳集計対象期間指定できるように改善対応 END
			// 2018/06/12 仕訳Rollup機能追加対応 BEGIN
			String rollUpCsvBody = '';
			if (!ctrl.isEmptyCsvBody) {
				// 仕訳の明細ROLLUP処理する
				rollUpCsvBody = ctrl.generalRollupCsvContent();
				// 出力ログ情報を設定する
				warningMsg = ctrl.msgStr;
				if (!CommUtils.isBlank(warningMsg)) sumMessage += '\n' + shop.Payee2__c + '\n' + warningMsg;
			}
			// 2018/06/12 仕訳Rollup機能追加対応 END
			// 前方キー
			batchFilePrefixKey = 'KAN_';
			// 添附ファイル名				
			String fileName = batchFilePrefixKey + batchProcessJobNo
							+ ( CommUtils.isBlank(shop.ShopCode__c) ? '' : '_' + ( shop.ShopCode__c + '(' +shop.Name  + ')') ) 
							+ '.csv';		
                            
			Attachment att = new Attachment(name =fileName);
	       	att.body = Blob.valueOf(csvBody);
	       	// 2018/06/12 仕訳Rollup機能追加対応 BEGIN
	       	// Rollup Csv File
	       	Attachment freeRollupAtt = null;
	       	if (!CommUtils.isBlank(rollUpCsvBody)) {
				String rollupfileName = 'KANRU_' + batchProcessJobNo
							+ ( CommUtils.isBlank(shop.ShopCode__c) ? '' : '_' + ( shop.ShopCode__c + '(' +shop.Name  + ')') ) 
							+ '.csv';	
	       		freeRollupAtt = new Attachment(name = rollupfileName);
	       		freeRollupAtt.body = Blob.valueOf(rollUpCsvBody);
	       	}
	       	// 2018/06/12 仕訳Rollup機能追加対応 END
			// メールで送信を行う
			if(PCA_BATCH_RESULT_METHOD_SENDMAIL == APPOTION_PCARESULT_SENDTYPE){
				//if (isFreeeMode) sendFreeeMail(shop);
				//else sendEmptyMail(att, shop, warningMsg);
				// 2018/04/20 仕訳集計対象期間指定できるように改善対応 BEGIN
				//sendEmptyMail(att, shop, warningMsg);
				// 2018/04/20 仕訳集計対象期間指定できるように改善対応 END
			}
			// ドキュメント格納する
			else if(PCA_BATCH_RESULT_METHOD_RELFILE == APPOTION_PCARESULT_SENDTYPE){
				createFileToSyncFloder(att, shop, freeRollupAtt);
			}
			// メール送信とドキュメント格納両方共処理を行う
			else if(PCA_BATCH_RESULT_METHOD_SENDANDSAVE == APPOTION_PCARESULT_SENDTYPE){
				//if (isFreeeMode) sendFreeeMail(shop);
				//else sendEmptyMail(att, shop, warningMsg);
				// 2018/04/20 仕訳集計対象期間指定できるように改善対応 BEGIN
				//sendEmptyMail(att, shop, warningMsg);
				// 2018/04/20 仕訳集計対象期間指定できるように改善対応 END
				createFileToSyncFloder(att, shop, freeRollupAtt);
			}
		}
		
	}
	// ***********************************
	// バッチ終了処理開始
	// ***********************************
	public void finish(Database.BatchableContext BC){
        // 2018/04/20 仕訳集計対象期間指定できるように改善対応 BEGIN
        if (PCA_BATCH_RESULT_METHOD_SENDMAIL == APPOTION_PCARESULT_SENDTYPE || 
            PCA_BATCH_RESULT_METHOD_SENDANDSAVE == APPOTION_PCARESULT_SENDTYPE) {
            list<string> rangeDtLst = new list<string>{saleDate};
            if (isBetweenProcess) rangeDtLst.add(saleEndDate);
            // 処理結果を一括送信を行う
            sendEmptyMail(new ShopInformation__c(name = gshopName), rangeDtLst,sumMessage);
        }
        // 次のジョブを実施する
        if (gNextJobs != null && !gNextJobs.isEmpty()) {
            // 次のジョブを起動する
            String firstJobName = gNextJobs[0];
            Date beginDate = CommUtils.stringToDate(saleDate);
            Date endDate = (isBetweenProcess ? CommUtils.stringToDate(saleEndDate) : null);
            BatchControlCenter.startNextBatch(firstJobName, gShopCode, beginDate, endDate, gNextJobs ,null);
        }   
        // 2018/04/20 仕訳集計対象期間指定できるように改善対応 END
	}
	
	/**
	* メール送信機能対応
	**/
	// 2018/04/20 仕訳集計対象期間指定できるように改善対応 BEGIN
	//private void sendEmptyMail(Attachment att, ShopInformation__c shop, String warningMsg) {
	private void sendEmptyMail(ShopInformation__c shop, List<String> dateRanges, String pMsgBody) {
	// 2018/04/20 仕訳集計対象期間指定できるように改善対応 END
		// メール情報を設定する
		//PCA連携のCSV出力が以下の通リ終了しましたのでお知らせいたします。
		String mailBodyStr = Label.INF_0003_00;
		//売上計上日:
		// 2018/04/20 仕訳集計対象期間指定できるように改善対応 BEGIN
		//mailBodyStr += '\n'+ Label.MSG_046_0001 +' ' + saleDate;
		mailBodyStr += '\n'+ Label.MSG_046_0001 +' ' + (dateRanges.size() > 1 ? (dateRanges[0] + '-' + dateRanges[dateRanges.size()-1]) : dateRanges[0] ) ;
		// 2018/04/20 仕訳集計対象期間指定できるように改善対応 END
		if (!CommUtils.isBlank(shop.Name)) {
			//店舗:
			mailBodyStr += '\n'+ Label.MSG_046_0002 +' ' + shop.Name;
		}
		// 2018/04/20 仕訳集計対象期間指定できるように改善対応 BEGIN
		/*
		if (!Commutils.isBlank(warningMsg)) {
			mailBodyStr += '\n\n' + warningMsg;
		}
		*/
		mailBodyStr += '\n'+pMsgBody;
		//連携データはCSV形式で添付致します
		//mailBodyStr += '\n\n' + Label.INF_9001 + '\n';	//  JinyaConnect Enterprise system R&D team.
		String mailBodyStr1 = '\n\n' + Label.INF_9001 + '\n';    //  JinyaConnect Enterprise system R&D team.
		// 2018/04/20 仕訳集計対象期間指定できるように改善対応 END
	    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	    //PCA連携のバッチ処理結果の通知
		mail.setSubject('['+UserInfo.getOrganizationName()+'] '+ Label.MSG_046_0004_00);
		// 2018/04/20 仕訳集計対象期間指定できるように改善対応 BEGIN
		//mail.setPlainTextBody(mailBodyStr);
		mail.setPlainTextBody(mailBodyStr + mailBodyStr1);
		// 2018/04/20 仕訳集計対象期間指定できるように改善対応 END
		// Fileも送付
	    //Messaging.EmailFileAttachment attFile= new Messaging.EmailFileAttachment();
	    //attFile.setBody(att.body);
	    //attFile.setFileName(att.name);
	    //mail.setFileAttachments(new Messaging.EmailFileAttachment[]{attFile});
//System.debug(loggingLevel.INFO, 'mail::' +mail);
		// Chatterへ送信する
		sendMsgToChatter(mail,mailBodyStr);
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
	/**
	* 通知情報はChatterグループへポストする
	**/
	private void sendMsgToChatter(Messaging.SingleEmailMessage mail, String pMsgBody) {
		// 
		List<String> chatterGroupNamesLst = CommConst.GetChatterGroupNameByCode(CommConst.Pcas_ChatterGroupNameType);
		List<CollaborationGroup> chatterGroups = [select Id, Name from CollaborationGroup where name = :chatterGroupNamesLst and isarchived = false];
    	if (chatterGroups.isEmpty()) return;

    	String msgBody = mail.getSubject() + '\n\n';
  		msgBody += pMsgBody;
  		msgBody += '\n\n' + Label.INF_9001 + '\n';
  		
    	List<FeedItem> feedItems = new List<FeedItem>();
    	//String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
    	for (CollaborationGroup cGroup : chatterGroups) {
			
			FeedItem post = new FeedItem();
			post.Type = 'TextPost';
	        post.Body = msgBody;
	        post.ParentId = cGroup.Id;
	        feedItems.add(post);
    	}
    	if (!feedItems.isEmpty()) insert feedItems;
	}
	/**
	* フォルダに連携結果を保存する
	**/
	private void createFileToSyncFloder(Attachment att, ShopInformation__c shop, Attachment rollUpAtt) {
		// 2017/02/24 Field Security Check BEGIN by wx
		List<String> insChkFields = new List<String>{'Description','FolderId','ContentType',
													'type','body','DeveloperName'};
		Map<String,Schema.SObjectField> insm = Schema.SObjectType.Document.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(insChkFields, insm)) {
			return;
		}
		// 2017/02/24 Field Security Check End by wx
		// ファイル格納のフォルダを取得する
		List<Folder> fs = [select id from Folder where DeveloperName = 'SyncFiles'];
        // CSVファイルをアップロードする
        Document newDoc = new Document(
        	DeveloperName = batchFilePrefixKey+ batchProcessJobNo + (CommUtils.isBlank(shop.ShopCode__c) ? '' : '_' + shop.ShopCode__c),
        	// 2015.12.04 ファイルName設定ルール変更、作成日から処理日に設定する BEGIN
        	//Description = '連携結果_'+batchFilePrefixKey +batchProcessJobNo,
        	//連携結果_
        	Description = Label.MSG_046_0017 +batchFilePrefixKey +System.now().format('yyyyMMddHHmmss'),
        	// 2015.12.04 ファイルName設定ルール変更、作成日から処理日に設定する END
        	FolderId = fs[0].Id,
        	Name = att.name,
        	ContentType = 'text/csv',
        	type = 'csv',
        	body = att.body
        );
        // 2018/06/12 仕訳Rollup機能追加対応 BEGIN
        //insert newDoc;
        list<Document> newDocs = new list<Document>();
        newDocs.add(newDoc);
        if (rollUpAtt != null) {
        	String rollupBatchFilePrefixKey = 'KANRU_';
        	// CSVファイルをアップロードする
        	Document rollUpNewDoc = new Document(
	        	DeveloperName = rollupBatchFilePrefixKey + batchProcessJobNo + (CommUtils.isBlank(shop.ShopCode__c) ? '' : '_' + shop.ShopCode__c),
	        	// 2015.12.04 ファイルName設定ルール変更、作成日から処理日に設定する BEGIN
	        	//連携結果_
	        	Description = Label.MSG_046_0017 + rollupBatchFilePrefixKey +System.now().format('yyyyMMddHHmmss'),
	        	// 2015.12.04 ファイルName設定ルール変更、作成日から処理日に設定する END
	        	FolderId = fs[0].Id,
	        	Name = rollUpAtt.name,
	        	ContentType = 'text/csv',
	        	type = 'csv',
	        	body = rollUpAtt.body
	        );
	        newDocs.add(rollUpNewDoc);
        }
        if (!newDocs.isEmpty()) insert newDocs;
        // 2018/06/12 仕訳Rollup機能追加対応 END
	}
}