/**
* バッチリクエスト機能
* 2015/11/10 初期作成
* 2015/12/24 起動できるバッチは定義できる対応
* 2016/09/15 勘定奉行バッチ機能追加
* 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応
* 2018/04/20 仕訳集計対象期間指定できるように改善対応(PCA/勘定)
* 2018/08/22 一般ユーザーでも作業できるように改善対応
* 2018/09/25 棚卸しバッチ起動できるように改善対応
* 2019/01/15 支払いメディアの一括自動入力機能
* 2019/02/28 シフトで入っている時間の範囲しか勤怠打刻を認めない機能はある
* 2019/05/09 未入金チェックバッチ機能追加
* 2019/06/28 支払いメディアの対象の予約の一覧表示機能
* 2019/07/31 請求書一括作成の改善対応（リクエストバッチ＞請求書自動作成 ＞）、この画面に、「お客様ステータス」の欄を追加していただき、すでにチェックイン完の予約がわかるように希望します
**/
public with sharing class BatchControlCenter {
	public String currentBatchName{get;set;}
	public String currentShopCode{get;set;}
	// 店舗情報選択リスト情報を格納する
	public List<SelectOption> shopOpts  {get; private set;}

	public List<SelectOption> batchOpts  {get; private set;}
	public boolean isStartFlag{get;set;}
	private Map<String,String> batchMap;
	public BookingTimeTable__c currentBatch{get;set;}
	// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 BEGIN
	public BookingTimeTable__c currentBatchTo{get;set;}
	// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 END
	public boolean isCanStargFlag{get;set;}
	public boolean isCanStopFlag{get;set;}
	private integer leadIntervalLength = 100;
	public integer delayLength{get;set;}
	// 2016/01/19 LOCALのプロファイル名を取得する BEGIN
	public String profileNm{get; private set;}
	// 2016/01/19 LOCALのプロファイル名を取得する END
	// 2016/02/21 Freee仕訳集計対象期間指定できるように改善対応 begin by wx
	//FREEEBatch 機能キー
	public static String BATCH_KEY_FREEE{get{return 'FREEEBatch';}}
	// 2016/02/21 Freee仕訳集計対象期間指定できるように改善対応 end by wx
	// 2019/12/30 FREEEAPI连携機能 WGCH BEGIN
	// Freee連携POST
	public static String BATCH_KEY_FREEEPOST{get{return 'FREEEPostBatch';}}
	// 2019/12/30 FREEEAPI连携機能 WGCH END
	// POS取込機能キー
	public static String BATCH_KEY_POS_IMP{get{return 'PosBatch';}}
	// 2016/09/15 勘定奉行バッチ機能追加
	// 勘定奉行機能キー
	public static String BATCH_KEY_KAN_SYN{get{return 'KanBatch';}}
	// 2018/09/25 棚卸しバッチ起動できるように改善対応
	// 棚卸バッチ機能キー
	public static String BATCH_KEY_STOCK_SYN{get{return 'StockBatch';}}
	// 2018/12/15 請求書の作成など自動繰返し機能 by zy BEGIN
	public static String BATCH_KEY_STOCK_BLN{get{return 'BillPdfBatch';}}
	// 2018/12/15 請求書の作成など自動繰返し機能 by zy END
	// 2018/12/30 部屋自動割当機能AI対応 by zy BEGIN
	public static String BATCH_KEY_ROOM_ASSIGN{get{return 'QQNAutoAssignBatch';}}
	// 2018/12/30 部屋自動割当機能AI対応 by zy END
	// 2019/01/15 支払いメディアの一括自動入力機能 WGCH BEGIN
	public static String BATCH_KEY_PAYMENT{get{return 'BulkAccPaymentBatch';}}
	// 2019/01/15 支払いメディアの一括自動入力機能 WGCH END
	// 2019/02/28 シフトで入っている時間の範囲しか勤怠打刻を認めない機能はある BY zyz BEGIN
	public static String BATCH_WORKTIME{get{return 'WorkTimeBatch';}}
	// 2019/02/28 シフトで入っている時間の範囲しか勤怠打刻を認めない機能はある BY zyz END
	// 2019/05/09 未入金チェックバッチ機能追加 WSQ BEGIN
	public static String BATCH_KEY_NOPAY{get{return 'NoPayCheckBatch';}}
	// 2019/05/09 未入金チェックバッチ機能追加 WSQ END
	// 2019/09/15 モアレリゾート様他複数施設（落合楼村上様など）より、稼働率レポートで故障部屋設定を加味してほしいという要望をいただいております。（夜間バッチで故障数集計） by zy BEGIN
	public static String BATCH_KEY_ROOM_STATUS{get{return 'BadRoomSumBatch';}}
	// 2019/09/15 モアレリゾート様他複数施設（落合楼村上様など）より、稼働率レポートで故障部屋設定を加味してほしいという要望をいただいております。（夜間バッチで故障数集計） by zy END
	// 定義できるバッチ対象リスト[KEY:XMLに定義のキー、VALUE:説明用文言、ロジック処理関係なし]
	private static final map<string,string> batchRequestItems = new map<string,string>{
		'ChargeBatch'=>'手数料バッチ',
		'PCABatch'=>'PCAバッチ',
		BATCH_KEY_FREEE=>'FREEE連携バッチ',
		BATCH_KEY_KAN_SYN=>'勘定奉行バッチ',
		'SalesBatch'=>'売上バッチ',
		BATCH_KEY_POS_IMP=>'POS取込バッチ'
		// 2018/09/25 棚卸しバッチ起動できるように改善対応 BEGIN
		,BATCH_KEY_STOCK_SYN=>'棚卸連携バッチ'
		// 2018/09/25 棚卸しバッチ起動できるように改善対応 END
		// 2018/12/15 請求書の作成など自動繰返し機能 by zy BEGIN
		,BATCH_KEY_STOCK_BLN=>'請求書自動作成'
		// 2018/12/15 請求書の作成など自動繰返し機能 by zy END
		// 2018/12/30 部屋自動割当機能AI対応 by zy BEGIN
		,BATCH_KEY_ROOM_ASSIGN => '部屋自動割当教育バッチ'
		// 2018/12/30 部屋自動割当機能AI対応 by zy BEGIN
		// 2019/01/15 支払いメディアの一括自動入力機能 WGCH BEGIN
		, BATCH_KEY_PAYMENT=>'支払いメディア一括登録'
		// 2019/01/15 支払いメディアの一括自動入力機能 WGCH END
		// 2019/02/28 シフトで入っている時間の範囲しか勤怠打刻を認めない機能はある BY zyz BEGIN
		,BATCH_WORKTIME=>'勤怠時間チェック'
		// 2019/02/28 シフトで入っている時間の範囲しか勤怠打刻を認めない機能はある BY zyz END
		// 2019/05/09 未入金チェックバッチ機能追加 WSQ BEGIN
		,BATCH_KEY_NOPAY=>'入金チェックバッチ'
		// 2019/05/09 未入金チェックバッチ機能追加 WSQ END
		// 2019/09/15 モアレリゾート様他複数施設（落合楼村上様など）より、稼働率レポートで故障部屋設定を加味してほしいという要望をいただいております。（夜間バッチで故障数集計） by zy BEGIN
		,BATCH_KEY_ROOM_STATUS => '故障部屋集計'
		// 2019/09/15 モアレリゾート様他複数施設（落合楼村上様など）より、稼働率レポートで故障部屋設定を加味してほしいという要望をいただいております。（夜間バッチで故障数集計） by zy END
		// 2019/12/30 FREEEAPI连携機能 WGCH BEGIN
		,BATCH_KEY_FREEEPOST => 'FREEEAPI連携バッチ'
		// 2019/12/30 FREEEAPI连携機能 WGCH END
	};
	
	// FROMTO期間指定機能対応済みバッチ対象
	// 2018/04/20 仕訳集計対象期間指定できるように改善対応(PCA/勘定) BEGIN
	// 2019/02/28 シフトで入っている時間の範囲しか勤怠打刻を認めない機能はある BY zyz BEGIN
	// 2019/05/09 未入金チェックバッチ機能追加 BATCH_KEY_NOPAY 未入金チェックの場合、期間指定可能
	// 2019/12/30 FREEEAPI连携機能 WGCH BEGIN
	private static final set<string> fromtoBatchItems = new set<string>{'ChargeBatch',BATCH_KEY_FREEE,'PCABatch',BATCH_KEY_KAN_SYN,BATCH_KEY_ROOM_ASSIGN,BATCH_WORKTIME,BATCH_KEY_NOPAY,BATCH_KEY_FREEEPOST,BATCH_KEY_ROOM_STATUS};
	// 2019/12/30 FREEEAPI连携機能 WGCH END
	// 2019/02/28 シフトで入っている時間の範囲しか勤怠打刻を認めない機能はある BY zyz END
	// 2018/04/20 仕訳集計対象期間指定できるように改善対応(PCA/勘定) END
	public BatchControlCenter(){
		currentBatchName = '';
		batchOpts = new List<SelectOption>();
		batchMap = new Map<String,String>();
		isStartFlag = false;
		//getBatchOpts();
		// ユーザー所属する店舗情報コードを取得する
		currentShopCode = UserUtil.CurrentUser.ShopCode__c;
		// 入力項目初期化する
		UserUtil.UserShopInfo userInf = UserUtil.CurrentUserInfo;
		shopOpts = ShopInfoUtil.getBranchShopLst(userInf.shops);
		// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 BEGIN
		//currentBatch = new BookingTimeTable__c(Checkinday__c = Date.today());
		// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 END
		initTimePrep();
		// 2015/12/17 リクエストバッチ起動対象リスト設定 BEGIN
		parseConfigXml(currentShopCode);
		// 2015/12/17 リクエストバッチ起動対象リスト設定 END
		if (batchOpts.size() > 0) {
			currentBatchName = batchOpts[0].getValue();
		}
		// 2016/01/19 LOCALのプロファイル名を取得する BEGIN
		profileNm = CommLogicProcess.getLoginUserProfile().name;
		// 2016/01/19 LOCALのプロファイル名を取得する END
		// 2018/08/22 一般ユーザーでも作業できるように改善対応 BEGIN
		// プロファイル名は常にシステム管理者に設定する
		if (commConfig.noauth) profileNm = Label.MSG_1016;
		// 2018/08/22 一般ユーザーでも作業できるように改善対応 END
		// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 BEGIN
		initQueryTerm(currentBatchName);
		// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 END
		// 2018/12/15 請求書の作成など自動繰返し機能 by zy BEGIN
		oAcountSobj = new AccountAcount__c(IssueDate__c = system.today(),SalesDate__c = system.today());
		// 2018/12/15 請求書の作成など自動繰返し機能 by zy END
	}
	/*
	public void getBatchOpts(){
		batchOpts.add(new SelectOption('BulkProcessPurchaseManagentBatch', '1:手数料バッチ'));
		String pcaBatchName = '3:Freee連携バッチ';
		if (PcaSyncCsvTemplateCtrl.isCsvOupModePca) pcaBatchName = '3:PCA連携バッチ';
		batchOpts.add(new SelectOption('BulkProcessPCABatch', pcaBatchName));
		batchOpts.add(new SelectOption('BulkProcessSchedule_2', '4:売上バッチ'));
	}*/
	public void refreshBranShop(){
		//String jobId = startBatch();
		//batchMap.put(currentBatchName,jobId);
		String jobId = batchMap.get(currentBatchName);
		String timeString = DateTime.newInstance(currentBatch.Checkinday__c, Time.newInstance(0, 0, 0, 0)).format('yyyyMMdd');
		String searchKey = currentBatchName + '_' + timeString + '%';
//System.debug(logginglevel.info,'searchKey:::' + searchKey);
		List<CronJobDetail> cronJobDetailLst = [select Id, JobType, Name from CronJobDetail where name like :searchKey];
		Set<Id> cronJobIdSet = new Set<Id>();
		for(CronJobDetail detail : cronJobDetailLst){
			cronJobIdSet.add(detail.id);
		}
//System.debug(logginglevel.info,'cronJobIdSet:::' + cronJobIdSet);
		List<CronTrigger> cronTriggerLst = [select CreatedById, CreatedDate, CronExpression, CronJobDetailId,
												EndTime, Id, LastModifiedById, NextFireTime, OwnerId, PreviousFireTime,
												StartTime, State, TimesTriggered, TimeZoneSidKey from CronTrigger
												where CronJobDetailId=:cronJobIdSet and State != 'DELETED'];
//System.debug(logginglevel.info,'cronTriggerLst:::' + cronTriggerLst);
		if(!cronTriggerLst.isEmpty()){
			isCanStargFlag = false;
			isCanStopFlag = false;
		}else{
			isCanStargFlag = true;
			isCanStopFlag = false;
		}
		initTimePrep();
		
		// 2015/12/17 リクエストバッチ起動対象リスト設定 BEGIN
		parseConfigXml(currentShopCode);
		// 2015/12/17 リクエストバッチ起動対象リスト設定 END
		// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 BEGIN
		initQueryTerm(currentBatchName);
		// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 END
		// 2018/12/15 請求書の作成など自動繰返し機能 by zy BEGIN
		oAcountSobj = new AccountAcount__c(IssueDate__c = system.today(),SalesDate__c = system.today());
		// 2018/12/15 請求書の作成など自動繰返し機能 by zy END
	}
	private void initTimePrep(){
		AccountingSyncBatchHelp help = new AccountingSyncBatchHelp(currentShopCode);
		leadIntervalLength = help.reqBatchWaitTimes;
		if(leadIntervalLength == 0 ){
			delayLength = 0;
			leadIntervalLength += 10;
		}else{
			delayLength = leadIntervalLength;
			leadIntervalLength += 30;
		}
	}
	public void stopBatch(){
		String jobId = batchMap.get(currentBatchName);
		if(!CommUtils.isBlank(jobId)){
			System.abortJob(jobId);
			isCanStargFlag = true;
			isCanStopFlag = false;
		}
	}
	public void startBatch(){
		// 起動日はチエックする
		if (currentBatch.checkinDay__c == null) {
			//処理日を指定してください。
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_046_0009));
			return;
		}
		// 終了日設定チェック[NULLの場合、開始日と同じ日付を設定する]
		if (currentBatchTo.checkinDay__c == null) currentBatchTo.checkinDay__c = currentBatch.checkinDay__c;
		// 指定期間は３１日以上を超える場合、エラーメッセージを表示する
		// 2019/02/15 部屋自動割り当て by zy BEGIN
		if (currentBatch.checkinDay__c.daysBetween(currentBatchTo.checkinDay__c) >= 31 && !monthExcudeSet.contains(currentBatchName)) {
		// 2019/02/15 部屋自動割り当て by zy END
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_046_0019));
			return;
		}
		
		String jobName =  DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		DateTime nowTime = DateTime.now().addSeconds(leadIntervalLength);
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
		// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 BEGIN
		BatchInfo batchInf = batchInfMap.get(currentBatchName);
		if (batchInf == null || batchInf.jobs.isEmpty()) return;
		String firstJobName = batchInf.jobs[0];
		Date wkEndDate = currentBatchTo.checkinDay__c;
		if (!getIsShowFromTo()) wkEndDate = null;
		Id currJobId = startNextBatch(firstJobName, currentShopCode,currentBatch.checkinDay__c,wkEndDate,batchInf.jobs,sch);
		batchMap.put(currentBatchName,currJobId);
		/*
		// 手数料バッチ
		if(currentBatchName == 'ChargeBatch'){
			BulkProcessPurchaseManagentBatch schedult = new BulkProcessPurchaseManagentBatch(currentShopCode,currentBatch.checkinDay__c);
			jobName = 'BulkProcessPurchaseManagentBatch_' + jobName;
			String jobId = system.schedule(jobName, sch, schedult);
			batchMap.put(currentBatchName,jobId);
		} 
		// PCA連携出力バッチ
		else if(currentBatchName == 'PCABatch'){
			BulkProcessPCABatch schedult = new BulkProcessPCABatch(currentShopCode,currentBatch.checkinDay__c,BulkProcessPCABatch.CSV_OUTPUT_MODE_PCA);
			jobName = 'BulkProcessPCABatch_' + jobName;
			String jobId = system.schedule(jobName, sch, schedult);
			batchMap.put(currentBatchName,jobId);
		} 
		// Freee連携種出力バッチ
		else if (currentBatchName == 'FREEEBatch') {
			BulkProcessPCABatch schedult = new BulkProcessPCABatch(currentShopCode,currentBatch.checkinDay__c,BulkProcessPCABatch.CSV_OUTPUT_MODE_FREEE);
			jobName = 'BulkProcessFreeeBatch_' + jobName;
			String jobId = system.schedule(jobName, sch, schedult);
			batchMap.put(currentBatchName,jobId);
		}
		// 2016/09/15 勘定奉行バッチ機能追加 BEGIN
		// 勘定奉行出力バッチ
		else if (currentBatchName == BATCH_KEY_KAN_SYN) {
			BulkProcessKANBatch schedult = new BulkProcessKANBatch(currentShopCode,currentBatch.checkinDay__c);
			jobName = 'BulkProcessKanBatch_' + jobName;
			String jobId = system.schedule(jobName, sch, schedult);
			batchMap.put(currentBatchName,jobId);
		}
		// 2016/09/15 勘定奉行バッチ機能追加 END
		// 売上バッチ
		else if(currentBatchName == 'SalesBatch'){
			BulkProcessSchedule_2 schedult = new BulkProcessSchedule_2(currentBatch.checkinDay__c);
			jobName = 'BulkProcessSchedule_2_' + jobName;
			String jobId = system.schedule(jobName, sch, schedult);
			batchMap.put(currentBatchName,jobId);
		}
		//POS取込
		else if(currentBatchName == BATCH_KEY_POS_IMP){
			BulkProcessPosImportBatch schedult = new BulkProcessPosImportBatch(currentShopCode,currentBatch.checkinDay__c);
			jobName = 'BulkProcessPosImportBatch_' + jobName;
			String jobId = system.schedule(jobName, sch, schedult);
			batchMap.put(currentBatchName,jobId);
		}*/
		// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 END
		isCanStargFlag = false;
		isCanStopFlag = true;
	}
	public static list<string> getNextJobs(list<string> jobs) {
		List<String> jobNames = new list<string>();
		for (Integer i = 1; i<jobs.size(); i++) {
			jobNames.add(jobs[i]);
		}
		return jobNames;
	}
	// 次のJOBスケジュールを定義、起動する
	public static Id startNextBatch(String nextBatchName, String pShopCd, Date pSaleDate, Date pSaleEndDate, List<String> pNextJobs, String sch) {
		String jobId = null;
		String jobName =  DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		if (Commutils.isBlank(sch)) {
			DateTime nowTime = DateTime.now().addSeconds(10);
			// 起動ＣＲＯＮを設定する
			String timeStr = nowTime.format('yyyyMMddHHmmss');
			String yy = timeStr.substring(0,4);
			String mm = timeStr.substring(4,6);
			String dd = timeStr.substring(6,8);
			String hh = timeStr.substring(8,10);
			String ms = timeStr.substring(10,12);
			String ss = timeStr.substring(12,14);
			sch = ss + ' ' +
			       ms + ' ' +
			       hh + ' ' +
			       dd + ' ' +
			       mm + ' ' +
			       ' ? ' + yy;
		}
		Boolean isBetweenFlg = (pSaleEndDate == null ? false : true);
		// 手数料バッチ
		if(nextBatchName == 'ChargeBatch'){
			BulkProcessPurchaseManagentBatch schedult;
			if (isBetweenFlg) {
				schedult = new BulkProcessPurchaseManagentBatch(pShopCd,pSaleDate,pSaleEndDate,getNextJobs(pNextJobs));
			} else {
				schedult = new BulkProcessPurchaseManagentBatch(pShopCd,pSaleDate,null,getNextJobs(pNextJobs));
			}
			jobName = 'BulkProcessPurchaseManagentBatch_' + jobName;
			jobId = system.schedule(jobName, sch, schedult);
		} 
		// PCA連携出力バッチ
		else if(nextBatchName == 'PCABatch'){
		    // 2018/04/20 仕訳集計対象期間指定できるように改善対応(PCA/勘定) BEGIN
		    //BulkProcessPCABatch schedult = new BulkProcessPCABatch(pShopCd,pSaleDate,null,null,BulkProcessPCABatch.CSV_OUTPUT_MODE_PCA);
		    BulkProcessPCABatch schedult;
		    if (isBetweenFlg) { 
		    	schedult = new BulkProcessPCABatch(pShopCd,pSaleDate,pSaleEndDate,getNextJobs(pNextJobs),BulkProcessPCABatch.CSV_OUTPUT_MODE_PCA);
	            } else {
	                schedult = new BulkProcessPCABatch(pShopCd,pSaleDate,null,getNextJobs(pNextJobs),BulkProcessPCABatch.CSV_OUTPUT_MODE_PCA);
	            }
		    // 2018/04/20 仕訳集計対象期間指定できるように改善対応(PCA/勘定) END
			jobName = 'BulkProcessPCABatch_' + jobName;
			jobId = system.schedule(jobName, sch, schedult);
		} 
		// Freee連携種出力バッチ
		else if (nextBatchName == 'FREEEBatch') {
			BulkProcessPCABatch schedult;
			if (isBetweenFlg) { 
				schedult = new BulkProcessPCABatch(pShopCd,pSaleDate,pSaleEndDate,getNextJobs(pNextJobs),BulkProcessPCABatch.CSV_OUTPUT_MODE_FREEE);
			} else {
				schedult = new BulkProcessPCABatch(pShopCd,pSaleDate,null,getNextJobs(pNextJobs),BulkProcessPCABatch.CSV_OUTPUT_MODE_FREEE);
			}
			jobName = 'BulkProcessFreeeBatch_' + jobName;
			jobId = system.schedule(jobName, sch, schedult);
		}
		// 2019/12/30 FREEEAPI连携機能 WGCH BEGIN
		// Freee連携POST
		else if (nextBatchName == BATCH_KEY_FREEEPOST) {
			FreeeSyncCsvGetBatch schedult;
			if (isBetweenFlg) { 
				schedult = new FreeeSyncCsvGetBatch(pShopCd,pSaleDate,pSaleEndDate);
			} else {
				schedult = new FreeeSyncCsvGetBatch(pShopCd,pSaleDate,pSaleDate);
			}
			jobName = 'FreeeSyncCsvGetBatch_' + jobName;
			jobId = system.schedule(jobName, sch, schedult);
		}
		// 2019/12/30 FREEEAPI连携機能 WGCH END
		// 2016/09/15 勘定奉行バッチ機能追加 BEGIN
		// 勘定奉行出力バッチ
		else if (nextBatchName == BATCH_KEY_KAN_SYN) {
		    // 2018/04/20 仕訳集計対象期間指定できるように改善対応(PCA/勘定) BEGIN
		    //BulkProcessKANBatch schedult = new BulkProcessKANBatch(pShopCd,pSaleDate);
		    BulkProcessKANBatch schedult;
	            if (isBetweenFlg) { 
	                schedult = new BulkProcessKANBatch(pShopCd,pSaleDate,pSaleEndDate,getNextJobs(pNextJobs));
	            } else {
	                schedult = new BulkProcessKANBatch(pShopCd,pSaleDate,null,getNextJobs(pNextJobs));
	            }
			// 2018/04/20 仕訳集計対象期間指定できるように改善対応(PCA/勘定) END
			jobName = 'BulkProcessKanBatch_' + jobName;
			jobId = system.schedule(jobName, sch, schedult);
		}
		// 2016/09/15 勘定奉行バッチ機能追加 END
		// 売上バッチ
		else if(nextBatchName == 'SalesBatch'){
			BulkProcessSchedule_2 schedult = new BulkProcessSchedule_2(pSaleDate);
			jobName = 'BulkProcessSchedule_2_' + jobName;
			jobId = system.schedule(jobName, sch, schedult);
		}
		//POS取込
		else if(nextBatchName == BATCH_KEY_POS_IMP){
			BulkProcessPosImportBatch schedult = new BulkProcessPosImportBatch(pShopCd,pSaleDate);
			jobName = 'BulkProcessPosImportBatch_' + jobName;
			jobId = system.schedule(jobName, sch, schedult);
		}
		// 2018/09/25 棚卸しバッチ起動できるように改善対応 BEGIN
		// 棚卸し在庫連携処理
		else if(nextBatchName == BATCH_KEY_STOCK_SYN){
			BulkStocktakingSyncBatch schedult = new BulkStocktakingSyncBatch(pShopCd,pSaleDate);
			jobName = 'BulkStocktakingSyncBatch_' + jobName;
			jobId = system.schedule(jobName, sch, schedult);
		}
		// 2018/09/25 棚卸しバッチ起動できるように改善対応 END
		// 2018/12/30 部屋自動割当機能AI対応 by zy BEGIN
		else if(nextBatchName == BATCH_KEY_ROOM_ASSIGN){
			QQNRoomTrainBatch batch = new QQNRoomTrainBatch(pShopCd,pSaleDate,pSaleEndDate);
			jobName = 'QQNRoomTrainBatch_' + jobName;
			jobId = system.schedule(jobName, sch, batch);
		}
		// 2018/12/30 部屋自動割当機能AI対応 by zy BEGIN
		// 2019/01/15 支払いメディアの一括自動入力機能 WGCH BEGIN
		else if (nextBatchName == BATCH_KEY_PAYMENT) {
			// 2019/06/28 支払いメディアの対象の予約の一覧表示機能 WGCH BEGIN
			if(searchMode == '1'){
				Set<String> accIdSet = new Set<String>();
				for(String accId : CommUtils.nullToBlank(accIdStr).split(',')){
					if(!CommUtils.isBlank(accId)) accIdSet.add( CommUtils.nullToBlank(accId));
				}
				pSaleDate = CommUtils.StringtoDate(accSlDtStr);
				BulkLeadCheckInBatch batch = new BulkLeadCheckInBatch(pShopCdStr, pSaleDate, accIdSet);
				// バッチ処理設定
				DataBase.executeBatch(batch, PRO_LEAD_NOMAX);
			} else {
				BulkLeadCheckInBatch batch = new BulkLeadCheckInBatch(pShopCd, pSaleDate);
				// バッチ処理設定
				DataBase.executeBatch(batch, PRO_LEAD_NOMAX);
			}
			// 2019/06/28 支払いメディアの対象の予約の一覧表示機能 WGCH END
		}
		// 2019/01/15 支払いメディアの一括自動入力機能 WGCH END
		// 2019/02/28 シフトで入っている時間の範囲しか勤怠打刻を認めない機能はある BY zyz BEGIN
		else if (nextBatchName == BATCH_WORKTIME) {
			WorkTimeBatch schedult;
			if (isBetweenFlg) { 
				schedult = new WorkTimeBatch(pShopCd,pSaleDate,pSaleEndDate);
			} else {
				schedult = new WorkTimeBatch(pShopCd,pSaleDate,null);
			}
			jobName = 'WorkTimeBatch_' + jobName;
			jobId = system.schedule(jobName, sch, schedult);
		}
		// 2019/02/28 シフトで入っている時間の範囲しか勤怠打刻を認めない機能はある BY zyz END
		// 2019/05/09 未入金チェックバッチ機能追加 WSQ BEGIN
		else if (nextBatchName == BATCH_KEY_NOPAY) {
			BulkProcessNoPaymentAlertBatch schedult;
			if (isBetweenFlg) { 
				schedult = new BulkProcessNoPaymentAlertBatch(pShopCd,pSaleDate,pSaleEndDate);
			} else {
				schedult = new BulkProcessNoPaymentAlertBatch(pShopCd,pSaleDate,null);
			}
			jobName = 'BulkProcessNoPaymentAlertBatch_' + jobName;
			jobId = system.schedule(jobName, sch, schedult);
		}
		// 2019/05/09 未入金チェックバッチ機能追加 WSQ END
		// 2019/09/15 モアレリゾート様他複数施設（落合楼村上様など）より、稼働率レポートで故障部屋設定を加味してほしいという要望をいただいております。（夜間バッチで故障数集計） by zy BEGIN
		else if (nextBatchName == BATCH_KEY_ROOM_STATUS) {
			BulkBadRoomQtyStatBatch schedult;
			if (isBetweenFlg) { 
				schedult = new BulkBadRoomQtyStatBatch(pShopCd,pSaleDate,pSaleEndDate);
			} else {
				schedult = new BulkBadRoomQtyStatBatch(pShopCd,pSaleDate,pSaleDate);
			}
			jobName = 'BulkBadRoomQtyStatBatch_' + jobName;
			jobId = system.schedule(jobName, sch, schedult);
		}
		// 2019/09/15 モアレリゾート様他複数施設（落合楼村上様など）より、稼働率レポートで故障部屋設定を加味してほしいという要望をいただいております。（夜間バッチで故障数集計） by zy END
		return jobId;
	}
	// XML情報分析と格納
	private void parseConfigXml(String shopCode) {
		// 初期化
		batchOpts = new List<SelectOption>();
		// 2017/02/28 FROMTO フラグをTRUEを設定すると、FROMTO機能有効になる	BEGIN
		batchInfMap = new map<String,BatchInfo>();
		// 2017/02/28 FROMTO フラグをTRUEを設定すると、FROMTO機能有効になる	END
		// XML READ
		String xmlConfigName = 'BatchRequstConfigXml';
		Dom.XmlNode shopRoot = CommXmlUtils.parseXmlDoc(xmlConfigName, shopCode);	
		// 2018/08/22 一般ユーザーでも作業できるように改善対応 BEGIN
		commConfig = new CommConfig();
		Dom.XmlNode noauthField =  shopRoot.getChildElement('NOAUTH', null);
		if (noauthField != null) {
			commConfig.noauth = Boolean.valueOf(Commutils.nullToblank(noauthField.getText()));
		}
		// 2018/08/22 一般ユーザーでも作業できるように改善対応 END
		// SET XML TO batchOpts
		Dom.XmlNode nodeRequestBatch =  shopRoot.getChildElement('REQUEST_BATCH', null);
	  	if (nodeRequestBatch != null) {
			for (Dom.XmlNode nodeBatch : nodeRequestBatch.getChildElements()) {
				// OPTION情報を設定する[FROM/TO期間]
				BatchInfo batchInf = new BatchInfo();
				String fromtoStr = CommUtils.nullToBlank(nodeBatch.getAttribute('FROMTO',null));
				if (!CommUtils.isBlank(fromtoStr)) batchInf.isFromTo = Boolean.valueOf(fromtoStr);
				// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 by zh BEGIN
				batchInf.timetermStr = CommUtils.nullToBlank(nodeBatch.getAttribute('TIMETERM',null));		
				// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 by zh END	
				String batchKey = '';
				String labelVal = '';
				for (Dom.XmlNode childNode : nodeBatch.getChildElements()) {
					String nodeName = childNode.getName();
					if (nodeName == 'LABEL') {
						labelVal = Commutils.nullToblank(childNode.getText());
						if (CommUtils.isBlank(labelVal)) continue;
					} else if (nodeName == 'BATCHKEY') {
						String wkBatchKey = Commutils.nullToblank(childNode.getText());
						if (CommUtils.isBlank(wkBatchKey)) continue;
						// 定義のバッチキーは処理対象外の場合、エラーメッセージを表示する
						if (!batchRequestItems.containsKey(wkBatchKey)) {
							//定義XML[XXXXXX]にタグ[BATCHKEY]の設定値が不正です.
					  		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_046_0010.replace('XXXXXX',xmlConfigName)));
					  		continue;
						}
						// FROM/TO有効　かつ　ジョブはFROMTO未対応の場合、エラーする
						if (batchInf.isFromTo && !fromtoBatchItems.contains(wkBatchKey)) {
							// TODO
							ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_046_0010.replace('XXXXXX',xmlConfigName)));
							continue;
						}
						if (CommUtils.isBlank(batchKey)) batchKey += wkBatchKey;
						else batchKey += ',' + wkBatchKey;
						// ジョブリストを追加する
						batchInf.jobs.add(wkBatchKey);
					}
				}
				if (!CommUtils.isBlank(labelVal) && !CommUtils.isBlank(batchKey)) {
					batchOpts.add(new SelectOption(batchKey,labelVal));
					batchInfMap.put(batchKey, batchInf);
				}
			}
	  	}
	  	// 2019/06/28 支払いメディアの対象の予約の一覧表示機能 WGCH BEGIN
	  	accViewIsNoShowFlg = false;
	  	Dom.XmlNode accpayBatch = shopRoot.getChildElement('ACCPAY_BATCH', null);
	  	if(accpayBatch != null){
	  		Dom.XmlNode accViewIsNoShow = accpayBatch.getChildElement('ACCVIEWISNOSHOW', null);
	  		if(accViewIsNoShow != null) accViewIsNoShowFlg = Boolean.valueOf(CommUtils.nullToBlank(accViewIsNoShow.getText()));
	  	}
	  	// 2019/06/28 支払いメディアの対象の予約の一覧表示機能 WGCH END
	}
	// 2017/02/28 FROMTO フラグをTRUEを設定すると、FROMTO機能有効になる	BEGIN
	public boolean getIsTimeTerm() {
		return batchInfMap.containsKey(currentBatchName) && batchInfMap.get(currentBatchName).isTimeTerm;
	}
	public boolean getIsShowFromTo() {
		return batchInfMap.containsKey(currentBatchName) && batchInfMap.get(currentBatchName).isFromTo;
	}
	// 2018/08/22 一般ユーザーでも作業できるように改善対応 BEGIN
	private CommConfig commConfig;
	public class CommConfig {
		public CommConfig() {
			noauth = false;
		}
		public boolean noauth{get;set;}
	}
	// 2018/08/22 一般ユーザーでも作業できるように改善対応 END
	private map<string,BatchInfo> batchInfMap{get;private set;}
	public class BatchInfo {
		public BatchInfo() {
			isFromTo = false;
			isTimeTerm = true;
			jobs = new list<string>();
			// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 by zh BEGIN
			timetermStr = '';
			// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 by zh END
		} 
		public boolean isFromTo{get;set;}
		public List<String> jobs{get;set;}// 該当バッチ名リストを格納する
		// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 by zh BEGIN
		public String timetermStr{get;set;}
		public Boolean isTimeTerm{get;set;}
		// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 by zh END
	}
	// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 by zh BEGIN
	public void initQueryTerm (String currentBatchName){
		Integer thisYear = Date.today().year();
		Integer thisMonth = Date.today().month();
		Integer daysOfMonth = Date.daysInMonth(thisYear, thisMonth);
		BatchInfo batch = batchInfMap.get(currentBatchName);
		String batchTerm = (batch != null) ? batch.timetermStr : null;
		if(getIsShowFromTo()){
			if(batchTerm == 'THISWEEK' || batchTerm == '今週'){
				currentBatch = new BookingTimeTable__c(Checkinday__c = Date.today().toStartofWeek());
				currentBatchTo = new BookingTimeTable__c(Checkinday__c = Date.today().toStartofWeek().addDays(6));
			}else if(batchTerm == 'LASTWEEK' || batchTerm == '先週'){
				currentBatch = new BookingTimeTable__c(Checkinday__c = Date.today().toStartofWeek().addDays(-7));
				currentBatchTo = new BookingTimeTable__c(Checkinday__c = Date.today().toStartofWeek().addDays(-1));			
			}else if(batchTerm == 'THISMONTH' || batchTerm == '今月'){
				currentBatch = new BookingTimeTable__c(Checkinday__c = Date.today().toStartOfMonth());
				currentBatchTo = new BookingTimeTable__c(Checkinday__c = Date.today().toStartOfMonth().addDays(daysOfMonth-1));
			}else if(batchTerm == 'LASTMONTH' || batchTerm == '先月'){
				currentBatch = new BookingTimeTable__c(Checkinday__c = Date.today().toStartOfMonth().addMonths(-1));
				currentBatchTo = new BookingTimeTable__c(Checkinday__c = Date.today().toStartOfMonth().addDays(-1));
			}else{
				if (currentBatch == null) currentBatch = new BookingTimeTable__c(Checkinday__c = Date.today());
				if (currentBatchTo == null) {
					currentBatchTo = new BookingTimeTable__c(Checkinday__c = Date.today());
					if (currentBatchTo.Checkinday__c < currentBatch.Checkinday__c) currentBatchTo.Checkinday__c = currentBatch.Checkinday__c;
				}
				if (batch != null) batch.isTimeTerm = false;
			}
		}else{
			if (currentBatch == null) currentBatch = new BookingTimeTable__c(Checkinday__c = Date.today());
			if (currentBatchTo == null) {
				currentBatchTo = new BookingTimeTable__c(Checkinday__c = Date.today());
				if (currentBatchTo.Checkinday__c < currentBatch.Checkinday__c) currentBatchTo.Checkinday__c = currentBatch.Checkinday__c;
			}
			if (batch != null) batch.isTimeTerm = false;
		}
		// 2018/09/25 棚卸しバッチ起動できるように改善対応 BEGIN
		// 締日リスト
		processDateOpts = new List<SelectOption>();
		noSettingFlag = false;
		// 棚卸しバッチの場合
		if(currentBatchName == BATCH_KEY_STOCK_SYN) {
			// 該当処理日
			Date todayDt = system.today();
			// 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy BEGIN
			/*
			// 棚処理対応設定取得
			Map<String,BulkStocktakingSyncBatch.ProcessInfo> shopProcess = BulkStocktakingSyncBatch.loadXmlReading(todayDt);
			// 棚設定情報
			BulkStocktakingSyncBatch.ProcessInfo processInfo = BulkStocktakingSyncBatch.getProcessInfoBySpcd(currentShopCode,shopProcess);
			// 棚設定情報あり
			if (processInfo != null) {
				// 今日は締日
				if (processInfo.processFlag) 
					processDateOpts.add(new SelectOption(todayDt.format(),todayDt.format()));
				// 後締日	
				if (processInfo.nextDate != null) processDateOpts.add(new SelectOption(processInfo.nextDate.format(),processInfo.nextDate.format()));
			}
			// 締め日設定なし、開始不能
			noSettingFlag = processDateOpts.size() == 0;
			*/
			// 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy END
		}
		// 2018/09/25 棚卸しバッチ起動できるように改善対応 END
		// 2018/12/15 請求書の作成など自動繰返し機能 by zy BEGIN
		billPDFFlag = false;
		commentOpts = new List<SelectOption>();
		if (currentBatchName == BATCH_KEY_STOCK_BLN) {
			billPDFFlag = true;
			// FROM/TOのデフォルト値設定する（前月の月末はTO、その前の６日はFROM）
			Date todayDt = Date.today();
			Date currFirstDate = Date.newInstance(todayDt.year(),todayDt.month(),1);
			leadFrom = new BookingTimeTable__c(Checkinday__c = currFirstDate.addDays(-7));
			leadTo = new BookingTimeTable__c(Checkinday__c = currFirstDate.addDays(-1));
			CommentHelperCompCtrl commHelp = new CommentHelperCompCtrl();
			// 2018/12/18 エラー修正JINYABUG-1271 by zy BEGIN
			commHelp.isBillComment = true;
			// 2018/12/18 エラー修正JINYABUG-1271 by zy END
			commentOpts = commHelp.commOptionlst;
			billComment = '';
			if (commentOpts.size() == 1) billComment = commentOpts[0].getValue();
		}
		// 2018/12/15 請求書の作成など自動繰返し機能 by zy END
		// 2019/01/15 支払いメディアの一括自動入力機能 WGCH BEGIN
		bulkAccPaymentFlag = false;
		if (currentBatchName == BATCH_KEY_PAYMENT) {
			bulkAccPaymentFlag = true;
		}
		// 2019/01/15 支払いメディアの一括自動入力機能 WGCH END
	}
	// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 by zh END
	// 2017/02/28 FROMTO フラグをTRUEを設定すると、FROMTO機能有効になる	END
	// 2018/09/25 棚卸しバッチ起動できるように改善対応 BEGIN
	public List<SelectOption> processDateOpts{get;set;}
	public boolean noSettingFlag{get;set;}
	// 2018/09/25 棚卸しバッチ起動できるように改善対応 END
	// 2018/12/15 請求書の作成など自動繰返し機能 by zy BEGIN
	// 会計基本情報[現在画面の会計情報]
	public AccountAcount__c oAcountSobj{get; private set;}
	// コメント項目
	public List<SelectOption> commentOpts{get;set;}
	// 到着日
	public BookingTimeTable__c leadFrom{get;set;}
	// 出発日
	public BookingTimeTable__c leadTo{get;set;}
	public String billComment{get;set;}
	private static String voidStatus = CommConst.ACC_TRADE_NORMAL;
	// 請求書一括作成機能フラグ
	public boolean billPDFFlag{get;set;}
	// 2019/01/15 支払いメディアの一括自動入力機能 WGCH BEGIN
	public boolean bulkAccPaymentFlag{get;set;}
	public static final Integer PRO_LEAD_NOMAX = 10;
	public static final Integer PRO_ACC_NOMAX = 10;
	// 2019/06/28 支払いメディアの対象の予約の一覧表示機能 WGCH BEGIN
	public static String searchMode{get{ if(searchMode == null) searchMode = ''; return searchMode;} set;} // 是否是viewmode 1
	public static String pShopCdStr{get{ if(pShopCdStr == null) pShopCdStr = ''; return pShopCdStr;} set;} // 当前检索选中数据的shopcode
	public static String accSlDtStr{get{ if(accSlDtStr == null) accSlDtStr = ''; return accSlDtStr;} set;} // 当前检索选中数据的売上日
	public static String accIdStr{get{ if(accIdStr == null) accIdStr = ''; return accIdStr;} set;} // 选中会计Id字符串「,」分割
	public Boolean accViewIsNoShowFlg{get; set;} // 隐藏view板块，前提是支払いメディアmode下，true:和原来功能一致
	@remoteaction
	public static List<AccountInfo> accQuery(String pShopCd, String pSaleDate){
		List<AccountInfo> accInfoLst = new List<AccountInfo>();
		String whereDate = '';
		Date saleDt = CommUtils.StringtoDate(pSaleDate);
		if(saleDt != null) {
			// 該当日の売上存在がどうかチェックを行う
			DateTime wkDt = DateTime.newInstance(saleDt.year(), saleDt.month(), saleDt.day());
			whereDate = wkDt.format('yyyyMMdd');
		}
		Id rsvAccId = null;
		// 2020/03/31 会計ロック機能 by zy BEGIN
		List<RsvAccount__c> existRsvAccLst = [select id,islockflg__c from RsvAccount__c where name =: whereDate limit 1 for update];
		// 2020/03/31 会計ロック機能 by zy END
		// 同じ日付の会計情報を一括取得して、取得する会計情報は処理を行う
		if (existRsvAccLst.isEmpty()) return accInfoLst;
		// 2020/03/31 会計ロック機能 by zy BEGIN
		if (existRsvAccLst[0].islockflg__c) throw new CommException(Label.MSG_006_0459);
		// 2020/03/31 会計ロック機能 by zy END
		rsvAccId = existRsvAccLst[0].Id;
		List<AccountAcount__c> accAcountLst = [ Select Relreserve__c, Relreserve__r.Name, Relreserve__r.LeadIndexRef__c, Relreserve__r.LeadIndexSubId__c, Relreserve__r.RoomGroupNo__c,
												relaccount__c, relaccount__r.Name,
												Id, Name,
												SalesDate__c
										// 会計日時設定される場合、該当会計は自動バッチ処理対象外
										from AccountAcount__c where frs__c =: rsvAccId And Relreserve__r.RefTypeOfRooms__r.ShopInfoRef__r.ShopCode__c =: pShopCd And Field39__c !=: CommConst.ACC_TRADE_VOID];
		Set<String> leadIndexIdSet = new Set<String>(); // 预约IndexId集合
		Set<String> leadIndexSubIdSet = new Set<String>(); // 预约IndexSubId集合
		Set<Decimal> roomGroupNoSet = new Set<Decimal>(); // 预约RoomGroupNo集合
		Map<String, List<Lead__c>> oneRoomLeadMap = new Map<String, List<Lead__c>>();
		Map<String, String> leadNightMap = new Map<String, String>();
		for(AccountAcount__c sobj : accAcountLst){
			leadIndexIdSet.add(sobj.Relreserve__r.LeadIndexRef__c); // 预约IndexId集合
			leadIndexSubIdSet.add(sobj.Relreserve__r.LeadIndexSubId__c); // 预约IndexSubId集合
			roomGroupNoSet.add(sobj.Relreserve__r.RoomGroupNo__c); // 预约RoomGroupNo集合
		}
		// 获取同一房间的相关预约
		List<Lead__c> oneRoomLeadLst = [ Select Id, StayNightCal__c, LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c From Lead__c 
														Where LeadIndexRef__c =: leadIndexIdSet
														And LeadIndexSubId__c =: leadIndexSubIdSet
														And RoomGroupNo__c =: roomGroupNoSet
														And CancelBool__c !=: CommConst.LEAD_ST_CANCEL_FLG 
														Order By EntryTime__c ];
		for(Lead__c leadItem : oneRoomLeadLst){
			// ONEROOMの識別キー
			String key = leadItem.LeadIndexRef__c + '_' + leadItem.LeadIndexSubId__c + '_' + leadItem.RoomGroupNo__c;
			if(!oneRoomLeadMap.containsKey(key)) oneRoomLeadMap.put(key, new List<lead__c>());
			oneRoomLeadMap.get(key).add(leadItem);
		}
		BulkLeadCheckInBatch batch = new BulkLeadCheckInBatch(pShopCd, saleDt); 
		for(String key : oneRoomLeadMap.keySet()){
			List<Lead__c> wkOneRoomLeadLst = oneRoomLeadMap.get(key);
			for(Integer i = 0; i < wkOneRoomLeadLst.size(); i++){ // 泊数Info处理
				Lead__c oneRoomLead = wkOneRoomLeadLst[i];
				// 当前是第几泊
				Integer leadNight = i+1;
				if(oneRoomLead.StayNightCal__c == 0) leadNight = 0;
				String leadNightStr = CommUtils.nullToBlank(leadNight);
				Integer leadNights = wkOneRoomLeadLst.size();
				if(leadNights > 1) leadNightStr = leadNights + '-' + leadNightStr;
				leadNightMap.put(oneRoomLead.Id, leadNightStr);
				BulkLeadCheckInBatch.LeadNightInfo leadNightItem = new BulkLeadCheckInBatch.LeadNightInfo(oneRoomLead, leadNight, (wkOneRoomLeadLst.size() > 1), wkOneRoomLeadLst.size() == leadNight );
				// 2019/05/15 最終泊の設定対応 WGCH END
				batch.bItem.leadNightInfoMap.put(oneRoomLead.Id, leadNightItem);
			}
		}
		Set<Id> accAcountIdSet = new Set<Id>();
		for(AccountAcount__c accItem : accAcountLst){
			accAcountIdSet.add(accItem.Id);
		}
		// 会計支払情報を取得する
		Map<Id, List<TTend__c>> ttendMap = new Map<Id, List<TTend__c>>();
		// 会計支払データを取得[同じ売上、有効な会計に、会計支払情報を取得する]
		for(TTend__c item: [select Field19__c, Field20__c, Field21__c,Field1__c,OutSideAccount__c,Field2__c,Field1__r.Relreserve__r.Field315__c,PayProductRef__r.ActionType__c,Field23__c,Field28__c from TTend__c where RelAccount__c =: rsvAccId And Field1__c in: accAcountIdSet]) {
			if(!ttendMap.containsKey(item.Field1__c)) ttendMap.put(item.Field1__c, new List<TTend__c>());
			ttendMap.get(item.Field1__c).add(item);
		}
		// 会計明細情報を取得する
		Map<Id, List<Tran1__c>> tranMap = new Map<Id, List<Tran1__c>>();
		// 詳細仕様： 請求書非表示(InvoiceNoShowFlg__c) AND 前受付　AND　有効な会計ID　の場合、統計対象外になる
		//		単価(Field20__c)
		//		数量(Field40__c/Field21__c)
		//		消費税(TaxRate__c)
		//		サービス料(ServiceRate__c) xx%方式
		//		特別税(SpecialTax__c)
		//	Where	商品処理種別　!= 前受け金 AND 請求書非表示(InvoiceNoShowFlg__c) AND 売上ID一致　AND　会計IDは有効な会計ID
		//	下記処理詳細：　処理対象の会計明細を取得して、
		//	取得する会計明細の会計支払データ件数は1件以上が存在する場合、処理対象外→既に処理済みの会計情報
		//	会計情報単位で、会計明細Groupする
		//	2013/11/12 親会計明細情報は計算対象外に変更対応
		Decimal taxRate = 0;
		for (Tran1__c item : [select UnitPriceDefKbCal__c, Id, Field1__c, ActionType__c, InvoiceNoShowFlg__c, Field20__c, Field21__c, Field40__c, TaxRate__c, ServiceRate__c, SpecialTax__c from Tran1__c
			where RelAccount__c =: rsvAccId And InvoiceNoShowFlg__c != true And ActionType__c !=: CommConst.PROD_ACTION_TYPE_AR
			And ParentTran1Ref__c = null
			And Field1__c in: accAcountIdSet
			Order By Field1__c]) {
			// 会計情報から消費税率は０の場合、明細から消費税率を取得する、設定を行う
			if (taxRate == 0) taxRate = CommUtils.nullToZero(item.TaxRate__c);
			// 会計単位で、金額計算を行う
			// 会計情報は既に設定されている場合
			if (tranMap.containsKey(item.Field1__c)) tranMap.get(item.Field1__c).add(item);
			else {
				List<Tran1__c> tranLst = new List<Tran1__c>();
				tranLst.add(item);
				tranMap.put(item.Field1__c, tranLst);
			}
		}
		// 金額計算を行う:計算方法は会計編集画面：必ず同じルールで計算ください、修正する場合、必ず両方連動ください:
		// TODO:税抜の計算方法は：　商品　＊　数量総税込から　税抜を計算する、元システムに（数式）、先に商品の税込金額を計算後、この金額と数量で税抜く金額を計算する
		// 消費税計算を行うため、消費税値は０以上の商品金額を税込み金額を合計して、合計値にて、消費税を計算を行う
		// 計算用消費税率取得：会計日の消費税率を取得する「日付は：画面指定日　又は　スケジュールの実施日」
		List<Tran1__c> insTranLst = new List<Tran1__c>();
		List<TTend__c> insTTendLst = new List<TTend__c>();
		List<AccountAcount__c> updAccAcount = new List<AccountAcount__c>();
		// 2019/05/15 最終泊の設定対応 WGCH BEGIN
		Map<String, List<TTend__c>> insAccReceivableTTendMap = new Map<String, List<TTend__c>>();
		Map<String, List<Tran1__c>> insAccReceivableTranMap = new Map<String, List<Tran1__c>>();
		Map<String, List<TTend__c>> accReceivableTTendMap = new Map<String, List<TTend__c>>();
		Map<String, List<Tran1__c>> accReceivableTranMap = new Map<String, List<Tran1__c>>();
		// 获取多泊指定的支付信息
		BulkLeadCheckInBatch.PaymentInfo nNightPaymentItem = batch.bItem.configXmlItem.nNightPaymentItem;
		// 获取关联的所有预约Id*除最终泊
		Set<String> leadAllLst = new Set<String>();
		for(String leadId : batch.bItem.leadNightInfoMap.keySet()){
			BulkLeadCheckInBatch.LeadNightInfo leadNightItem = batch.bItem.leadNightInfoMap.get(leadId);
			// 最终泊的不查询
			if(!leadNightItem.leadLastNightFlg) leadAllLst.add(leadId);
		}
		// 获取所有预约指定多泊支付商品对应的支付信息
		if(batch.bItem.configXmlItem.lastNightPaymentFlg && !leadAllLst.isEmpty()){
			for(TTend__c item : [select Field28__c, PayProductRef__c, Field1__r.Relreserve__r.LeadIndexRef__c, Field1__r.Relreserve__r.LeadIndexSubId__c, Field1__r.Relreserve__r.RoomGroupNo__c from TTend__c where Field1__r.Relreserve__c in: leadAllLst]) {
				// ONEROOMの識別キー
				String key = item.Field1__r.Relreserve__r.LeadIndexRef__c + '_' + item.Field1__r.Relreserve__r.LeadIndexSubId__c + '_' + item.Field1__r.Relreserve__r.RoomGroupNo__c;
				if(!accReceivableTTendMap.containsKey(key)) accReceivableTTendMap.put(key, new List<TTend__c>());
				accReceivableTTendMap.get(key).add(item);
			}
			// 获取所有预约指定多泊支付商品对应的明细信息
			for (Tran1__c item : [select Field23__c, Field7__c, Field1__r.Relreserve__r.LeadIndexRef__c, Field1__r.Relreserve__r.LeadIndexSubId__c, Field1__r.Relreserve__r.RoomGroupNo__c from Tran1__c where Field1__r.Relreserve__c in: leadAllLst And InvoiceNoShowFlg__c != true And ActionType__c !=: CommConst.PROD_ACTION_TYPE_AR And ParentTran1Ref__c = null]) {
				// ONEROOMの識別キー
				String key = item.Field1__r.Relreserve__r.LeadIndexRef__c + '_' + item.Field1__r.Relreserve__r.LeadIndexSubId__c + '_' + item.Field1__r.Relreserve__r.RoomGroupNo__c;
				if(!accReceivableTranMap.containsKey(key)) accReceivableTranMap.put(key, new List<Tran1__c>());
				accReceivableTranMap.get(key).add(item);
			}
		}
		// 2019/05/15 最終泊の設定対応 WGCH END
		// 会計単位で、会計明細情報を統計する
		for (AccountAcount__c oAcountSobj : accAcountLst) {
			// 会計情報へ設定を行う
			Id acountId = oAcountSobj.Id;
			// 1日１会計情報の会計総額金額計算
			// 売上計4（税込）金額
			Decimal totalAmoutIncTax = 0;
			// 売上計3（税抜）金額
			Decimal totalAmoutExcTax = 0;
			// サービス料金(税込)
			Decimal totalAmoutSrvIncTax = 0;
			// サービス料金(税抜)
			Decimal totalAmoutSrvExcTax = 0;
			// 宿泊税
			Decimal totalAmoutSPTax = 0;
			// 消費税ありの商品税込金額
			Decimal amoutPriceIncTaxByTax = 0;
			// 金額計算共通
			// １会計:1会計支払：N会計明細
			List<Tran1__c> tranLst = tranMap.get(acountId);
			if(tranLst == null) tranLst = new List<Tran1__c>();
			for (Tran1__c tranItem : tranLst) {
				// 金額計算を行う
				// 2014/08/06 単価定義区分に従って、過去見積もり明細金額変更あり不具合修正 BEGIN
				CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(tranItem.UnitPriceDefKbCal__c));
				// 2014/08/06 単価定義区分に従って、過去見積もり明細金額変更あり不具合修正 END
				// 単価と数量はNULLの場合、
				Decimal unitPrice = CommUtils.nullToZero(tranItem.Field20__c);	// <-税金含め単価です
				Decimal qty = CommUtils.nullToZero(tranItem.Field21__c);
				// 金額計算を行う
				priceInfo.process(unitPrice, qty, tranItem.TaxRate__c, tranItem.ServiceRate__c);
				// 合計金額(税抜)※※※※（１円未満切り上げ）※※※※[サビース料込(20130923)]
				Decimal amoutExcTax = priceInfo.priceExcTax;
				// サービス料金（税込）
				Decimal servicePriceIncTax = priceInfo.priceService;
				// 2012/10/30 宿泊税の処理追加を行う
				// 合計金額(税込)[合計金額（税込:サービス込）＋特別税]
				totalAmoutIncTax += priceInfo.priceIncTax + CommUtils.nullToZero(tranItem.SpecialTax__c);
				// ----------- 会計へ設定用情報 ----------
				// サービス料金(税込)
				totalAmoutSrvIncTax += servicePriceIncTax;
				// サービス料金(税抜)
				totalAmoutSrvExcTax += priceInfo.priceServiceExcTax;
				// 宿泊税[TODO]自動計算する場合、宿泊税の設定が必要
				totalAmoutSPTax += CommUtils.nullToZero(tranItem.SpecialTax__c);
				// 商品販売金額（税抜き）
				totalAmoutExcTax += amoutExcTax;
				// 商品税値は＞０の場合、金額合計を行う
				if (tranItem.TaxRate__c > 0 ) amoutPriceIncTaxByTax += priceInfo.priceIncTax;
			} // End For
			// 会計支払へ該当統計金額を計算を行う
			List<TTend__c> ttendSobjLst = ttendMap.get(acountId);
			// 複数会計支払い情報を存在する場合、処理対象外
			if(ttendSobjLst != null){
				for(TTend__c ttend : ttendSobjLst){
					totalAmoutIncTax -= CommUtils.nullToZero(ttend.Field28__c);
					amoutPriceIncTaxByTax -= CommUtils.nullToZero(ttend.Field28__c);
				}
			}
			// 2019/05/15 最終泊の設定対応 WGCH BEGIN
			if(! batch.bItem.leadNightInfoMap.containsKey(oAcountSobj.Relreserve__c)) continue;
			// 获取当前会计对应的预约信息
			BulkLeadCheckInBatch.LeadNightInfo leadNightItem = batch.bItem.leadNightInfoMap.get(oAcountSobj.Relreserve__c);
			// ONEROOMの識別キー
			String key = oAcountSobj.Relreserve__r.LeadIndexRef__c + '_' + oAcountSobj.Relreserve__r.LeadIndexSubId__c + '_' + oAcountSobj.Relreserve__r.RoomGroupNo__c;
			// 当前预约如果是最终泊时处理
			if(leadNightItem.leadLastNightFlg){
				if(accReceivableTTendMap.containsKey(key)){
					for(TTend__c item : accReceivableTTendMap.get(key)) {
						// 除最终以外的相关支付商品金额处理
						if(item.PayProductRef__c != nNightPaymentItem.paymentId) totalAmoutIncTax -= CommUtils.nullToZero(item.Field28__c);
						else{
							// *********** 合計金額 **********
							// 預かり　金額[バッチ処理の自動計算する場合、預かり金額は０で設定する]
							item.Field19__c = String.valueOf(0);
							// 支払　金額
							item.Field20__c = String.valueOf(0);
							// メディア毎消費税額設定を行う
							item.Field25__c = String.valueOf(0);
							// 請求書非表示
							item.InvoiceNoShowFlg__c = true;
							if(!insAccReceivableTTendMap.containsKey(key)) insAccReceivableTTendMap.put(key, new List<TTend__c>());
							insAccReceivableTTendMap.get(key).add(item);
						}
					}
				}
				if(accReceivableTranMap.containsKey(key)){
					for(Tran1__c item : accReceivableTranMap.get(key)) {
						if(item.Field7__c != nNightPaymentItem.paymentId) totalAmoutIncTax += CommUtils.nullToZero(item.Field23__c);
						// 除最终以外的相关支付商品金额处理
						else {
							// 数量设成0
							item.Field21__c = String.valueOf(0);
							// 請求書非表示
							item.InvoiceNoShowFlg__c = true;
							if(!insAccReceivableTranMap.containsKey(key)) insAccReceivableTranMap.put(key, new List<Tran1__c>());
							insAccReceivableTranMap.get(key).add(item);
						}
					}
				}
			}
			// 2019/05/15 最終泊の設定対応 WGCH END
			if(totalAmoutIncTax <= 0) continue;
			// メディア毎消費税額計算を行う
			// 2014/07/02 USD機能対応
			Integer pointLen = CommUtils.getPointLen();
			Decimal mediaTaxPrice = (amoutPriceIncTaxByTax > 0 ? CommUtils.RoundProcess(amoutPriceIncTaxByTax / (1 + taxRate / 100) * (taxRate / 100), pointLen) : 0);
			// 2019/05/15 最終泊の設定対応 WGCH BEGIN
			// 支付方式获取处理
			// 2019/05/15 最終泊の設定対応 WGCH END
			BulkLeadCheckInBatch.PaymentInfo paymentItem = leadNightItem.leadNightsFlg ? batch.bItem.configXmlItem.nNightPaymentItem : batch.bItem.configXmlItem.firstNightPaymentItem;
			// 2019/05/15 最終泊の設定対応 WGCH BEGIN
			// 当前会计对应的预约时最终泊数据时&&最终泊设定支付信息功能打开处理
			if(leadNightItem.leadNightsFlg && leadNightItem.leadLastNightFlg && batch.bItem.configXmlItem.lastNightPaymentFlg){
				// 最终泊支付商品信息
				paymentItem = batch.bItem.configXmlItem.lastNightPaymentItem;
			}
			if(paymentItem.isInvalidFlg) continue;
			accInfoLst.add(new AccountInfo(oAcountSobj, leadNightMap, pShopCd, paymentItem, totalAmoutIncTax));
		}
		return accInfoLst;
	}
	public class AccountInfo{
		public AccountInfo(AccountAcount__c sobj, Map<String, String> leadNightMap, String pShopCd, BulkLeadCheckInBatch.PaymentInfo paymentItem, Decimal totalAmoutIncTax){
			accLdId = CommUtils.nullToBlank(sobj.Relreserve__c);
			accLdNm = CommUtils.nullToBlank(sobj.Relreserve__r.Name);
			accCtId = CommUtils.nullToBlank(sobj.relaccount__c);
			accCtNm = CommUtils.nullToBlank(sobj.relaccount__r.Name);
			accId = CommUtils.nullToBlank(sobj.Id);
			accNm = CommUtils.nullToBlank(sobj.Name);
			accSlDt = sobj.SalesDate__c != null ? sobj.SalesDate__c.format() : '';
			leadNight = '';
			if(leadNightMap.containsKey(accLdId)) leadNight = leadNightMap.get(accLdId);
			checkflag = false;
			this.pShopCd = pShopCd;
			this.totalAmoutIncTax = CommUtils.nullToZero(totalAmoutIncTax).format();
			paymentId = paymentItem.paymentId;
			paymentNm = paymentItem.paymentNm;
		}
		public String accLdId; // 予約Id
		public String accLdNm; // 予約名
		public String accCtId; // お客様Id
		public String accCtNm; // お客様名
		public String accId; // 会計Id
		public String accNm; // 会計名
		public String accSlDt; // 売上日
		public Boolean checkflag;
		public String leadNight; // 泊目
		public String pShopCd; // 店铺
		public String totalAmoutIncTax; // 支付金额
		public String paymentId; // 支付商品Id
		public String paymentNm; // 支付商品名
	}
	// 2019/06/28 支払いメディアの対象の予約の一覧表示機能 WGCH END
	// 2019/01/15 支払いメディアの一括自動入力機能 WGCH END
	// 2019/07/31 請求書一括作成の改善対応（リクエストバッチ＞請求書自動作成 ＞）、この画面に、「お客様ステータス」の欄を追加していただき、すでにチェックイン完の予約がわかるように希望します by zy BEGIN
	private static String querySQL = 'select id,name,relaccount__c,SalesDate__c,relaccount__r.name,Relreserve__r.name,Relreserve__r.Field2__c,Relreserve__r.ReservedType__c,Relreserve__r.EntryTime__c,Relreserve__r.refTypeOfRooms__r.name,Relreserve__r.Rroom__c,Relreserve__r.Field298__c from AccountAcount__c';
	// 2019/07/31 請求書一括作成の改善対応（リクエストバッチ＞請求書自動作成 ＞）、この画面に、「お客様ステータス」の欄を追加していただき、すでにチェックイン完の予約がわかるように希望します by zy END
	@remoteaction
	public static object remoteQuery(String actionType,String request){
		// リクエスト
		RequestInfo req = (RequestInfo) JSON.deserialize(request,RequestInfo.class);
		// 予約取得
		if (actionType == 'queryLead') return queryLead(req);
		// バッチ処理
		else if (actionType == 'batchExcute') return batchExcute(req);
		// 指定処理日予約チェック
		else if (actionType == 'queryExitLead') return queryExitLead(req);
		return null;
	}
	// 予約取得
	private static object queryLead(RequestInfo req){
		// リクエスト
		//RequestInfo req = (RequestInfo) JSON.deserialize(request,RequestInfo.class);
		String spcd = req.spcd;
		String sqlWhere = ' where Relreserve__r.refTypeOfRooms__r.ShopInfoRef__r.shopcode__c = :spcd ';
		String queryDtStr = req.queryDt;
		Date queryDt = CommUtils.StringtoDate(queryDtStr);
		Boolean isFixedFlg = DataFixManagerUtils.getInstance().LeadFixed__c;
		// 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
		Boolean isFixedFlg1 = DataFixManagerUtils.getInstance().LeadFixed1__c;
		Integer queryDtInt = CommUtils.nullToIntZero(CommUtils.dateToYYYYMMDD(queryDt));
		// 2020/08/30 部屋状態管理インデックス機能対応 WGCH END
		if (!CommUtils.isBlank(queryDtStr)) {
			queryDtStr = CommUtils.dateToYYYYMMDD(queryDt);
			// INDEX有効化有効の場合、該当検索キーで検索する
			// 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
			// if (isFixedFlg) sqlWhere += ' and Relreserve__r.EntryDateKey__c >= :queryDtStr';
			if(isFixedFlg1) sqlWhere += ' and Relreserve__r.EntryDateIntKey__c >= :queryDtInt';
			else if(isFixedFlg) sqlWhere += ' and Relreserve__r.EntryDateKey__c >= :queryDtStr';
			// 2020/08/30 部屋状態管理インデックス機能対応 WGCH END
			else sqlWhere += 'and DAY_ONLY(convertTimezone(Relreserve__r.EntryTime__c)) >= :queryDt';
		}
		String querEndStr = req.endDtStr;
		Date endDt = CommUtils.StringtoDate(querEndStr);
		// 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
		Integer querEndInt = CommUtils.nullToIntZero(CommUtils.dateToYYYYMMDD(endDt));
		// 2020/08/30 部屋状態管理インデックス機能対応 WGCH END
		if (!CommUtils.isBlank(querEndStr)) {
			querEndStr = CommUtils.dateToYYYYMMDD(endDt);
			// INDEX有効化有効の場合、該当検索キーで検索する
			// 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
			// if (isFixedFlg) sqlWhere += ' and Relreserve__r.EntryDateKey__c <= :querEndStr';
			if(isFixedFlg1) sqlWhere += ' and Relreserve__r.EntryDateIntKey__c <= :querEndInt';
			else if(isFixedFlg) sqlWhere += ' and Relreserve__r.EntryDateKey__c <= :querEndStr';
			// 2020/08/30 部屋状態管理インデックス機能対応 WGCH END
			else sqlWhere += ' and DAY_ONLY(convertTimezone(Relreserve__r.EntryTime__c)) <= :endDt';
			
		}
		// 正常な会計情報
		sqlWhere += ' And Field39__c = :voidStatus';
		sqlWhere += ' order by Relreserve__r.EntryTime__c,Relreserve__r.LeadIndexRef__c,Relreserve__r.LeadIndexSubId__c,Relreserve__r.RoomGroupNo__c';
		Date saleDt = CommUtils.StringtoDate(req.saleDt);
		// 指定条件により、既存会計情報を取得する
		List<AccountAcount__c> accounts = Database.query(querySQL + sqlWhere);
		// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy BEGIN
		// 指定の売上計上日関連の会計データが存在チェックを行う
		List<LeadInfo> infos = (List<LeadInfo>) commCheckExist(accounts, req);
		infos.addAll(getNochekInLead(spcd,queryDtStr,querEndStr,req));
		return infos;
		// return commCheckExist(accounts, req);
		// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy END
	}
	// バッチ処理
	private static object batchExcute(RequestInfo req){
		//RequestInfo req = (RequestInfo) JSON.deserialize(request,RequestInfo.class);
		List<String> leads = req.leads;
		String spcd = CommUtils.nullToBlank(req.spcd);
		// 請求書条件指定
		AccountAcount__c oAcountSobj = new AccountAcount__c(
			IssueDate__c = CommUtils.stringtodate(req.queryDt),
			comment__c = commUtils.nullToBlank(req.comment),
			IsNewLayout__c = req.checkflag,
			SalesDate__c = CommUtils.stringtodate(req.saleDt)
		);
		// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy BEGIN
		if (Commconst.Bill_LETTER_FLG) oAcountSobj.PaymentFlg__c = req.letter;
		// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy END
		
		List<Id> leadIds = new List<Id>();
		for (String leadId : leads) {
			leadIds.add(leadId);
		}
		// バッチ開始
		// 12ヶ月分の予約がまとめて作成出来る WSQ BEGIN
		//BillCopyBatch batch = new BillCopyBatch(leadIds,oAcountSobj);
		req.loopsize = CommUtils.nullToZero(req.loopsize);
		BillCopyBatch batch = new BillCopyBatch(leadIds,oAcountSobj,req.loopsize,null);
		// 12ヶ月分の予約がまとめて作成出来る WSQ END
		Database.executeBatch(batch,1);
		return leadIds;
	}
	// 指定処理日予約チェック
	private static object queryExitLead(RequestInfo req){
		//RequestInfo req = (RequestInfo) JSON.deserialize(request,RequestInfo.class);
		// 2020/03/31 会計ロック機能 by zy BEGIN
		if (checkRsvLock(req)) return Label.MSG_006_0459;
		// 2020/03/31 会計ロック機能 by zy END
		// 画面全部会計
		List<String> accountids = req.accountids;
		// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy BEGIN
		if (accountids.isEmpty()) return null;
		// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy END
		String sqlWhere = ' where id in : accountids';
		// 会計SQL
		List<AccountAcount__c> accs = DataBase.query(querySQL + sqlWhere);
		// 既存関連会計データが存在チェック
		// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy BEGIN
		List<LeadInfo> leadInfos = (List<LeadInfo>) commCheckExist(accs, req);
		List<String> leadIds = req.leads;
		if (!leadIds.isEmpty()) {
			String sqlLeadWhere = ' where id in : leadIds';
			// 予約SQL
			List<Lead__c> leads = DataBase.query(queryLeadSQL + sqlLeadWhere);
			leadInfos.addAll(commCheckExistLead(leads,req));
		}
		return leadInfos;
		// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy END
	}
	// 指定会計で、同じお客様、同じ部屋、会計データ存在がどうかチェックを行う
	private static object commCheckExist(List<AccountAcount__c> accs, RequestInfo req) {
		// 店舗コード
		String spcd = req.spcd;
		// 処理日
		Date queryDt = CommUtils.StringtoDate(req.saleDt);
		// 既存お客様ID
		Set<String> contactSet = new Set<String>();
		// 既存部屋ID
		Set<string> roomIdSet = new Set<String>();
		// データ初期化
		for (AccountAcount__c acc : accs) {
			if (!CommUtils.isBlank(acc.relaccount__c)) contactSet.add(acc.relaccount__c);
			if (!CommUtils.isBlank(acc.Relreserve__r.Rroom__c)) roomIdSet.add(CommUtils.nullToblank(acc.Relreserve__r.Rroom__c));
		}
		// 指定作成日、同じお客様、同じ部屋タイプに会計データが存在場合、該当予約情報を格納する
		List<LeadInfo> infos = new List<LeadInfo>();
		// 12ヶ月分の予約がまとめて作成出来る WSQ BEGIN
		// 複数作成月の売上計上日を計算する
		set<String> salesDateSet = new set<String>();
		// 始める日を先に格納する
		salesDateSet.add(CommUtils.dateToYYYYMMDD(queryDt));
		for (Integer i=1 ; i<req.loopsize; i++) {	
			// 月末の場合
			if (queryDt.day() == Date.daysInMonth(queryDt.year(),queryDt.month())) {
				// 次の計上日も月末に設定する
				Date wkDate = queryDt.addMonths(1);
				queryDt = Date.newInstance(wkDate.year(), wkDate.month(), Date.daysInMonth(wkDate.year(), wkDate.month()));
			} else {
				// 次の月の売上計上日を設定する
				queryDt = queryDt.addMonths(1);
			}
			// 翌日日付を設定する
			salesDateSet.add(CommUtils.dateToYYYYMMDD(queryDt));
		}
		// 12ヶ月分の予約がまとめて作成出来る WSQ END
		// 指定条件会計データ取得
		//Map<String,String> accountMap = getAccountMap(spcd,salesDateSet,contactSet,roomIdSet);
		// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy BEGIN
		// set<String> extAccKeySet = getExiAccountInfo(spcd,salesDateSet,contactSet,roomIdSet);
		// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy END
		// 既存会計チェック判定
		for (AccountAcount__c acc : accs) {
			// 会計情報が既に存在するがどうかチェック用キーワードを取得する
			String key = CommUtils.nullToBlank(getAccountKey(acc.Relreserve__r.Rroom__c ,acc.relaccount__c));
			// 各予約
			// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy BEGIN
			// infos.add(new LeadInfo(acc,extAccKeySet.contains(key)));
			infos.add(new LeadInfo(acc,false));
			// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy END
		}
		return infos;
	}
	// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy BEGIN
	/*
	// 指定条件会計取得
	private static set<String> getExiAccountInfo(String spcd ,set<String> salesDateSet,Set<String> contactSet,Set<string> roomIdSet){
		// 会計SQL文作成
		String accountSQL = 'select id , Relreserve__r.Rroom__c , relaccount__c from AccountAcount__c where frs__r.Name in :salesDateSet and Relreserve__r.refTypeOfRooms__r.ShopInfoRef__r.shopcode__c = :spcd And Field39__c = :voidStatus';
		if (!contactSet.isEmpty()) accountSQL += ' and relaccount__c in :contactSet';
		if (!roomIdSet.isEmpty()) accountSQL += ' and Relreserve__r.Rroom__c in :roomIdSet';
		//List<AccountAcount__c> hadAccs = [select id , Relreserve__r.refTypeOfRooms__c, relaccount__c from AccountAcount__c where SalesDate__c = :saleDt and Relreserve__r.refTypeOfRooms__r.ShopInfoRef__r.shopcode__c = :spcd And Field39__c = :voidStatus];
		List<AccountAcount__c> hadAccs = Database.query(accountSQL);
		//Map<String,String> accountMap = new Map<String,String>();
		set<String> extAccKeySet = new set<String>();
		for (AccountAcount__c acc : hadAccs) {
			// チェック用キーワードを作成する
			String key = getAccountKey(acc.Relreserve__r.Rroom__c ,acc.relaccount__c);
			// 該当キーワードに、存在の会計情報のIDを格納する（始める会計IDのみ)
			if (!CommUtils.isBlank(key) && !extAccKeySet.contains(key)) extAccKeySet.add(key);
		}
		return extAccKeySet;
	}*/
	// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy END
	private static String getAccountKey(String roomId,String contactId){
		// 部屋　まはた　お客様は空白の場合、対象外データにする
		if (CommUtils.isBlank(roomId) || CommUtils.isBlank(contactId)) return '';
		return CommUtils.nullToBlank(roomId) + '_' + CommUtils.nullToBlank(contactId);
	}
	class RequestInfo {
		String spcd;
		String queryDt;
		List<String> leads; 
		boolean checkflag;
		String comment;
		List<String> accountids;
		String endDtStr;
		String saleDt;
		// 12ヶ月分の予約がまとめて作成出来る WSQ BEGIN
		Integer loopsize;
		// 12ヶ月分の予約がまとめて作成出来る WSQ END
		// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy BEGIN
		boolean letter;
		// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy END
	}
	class LeadInfo{
		// 部屋タイプ名
		public String roomName;
		// 予約名
		public String leadName;
		// 予約チャンネル
		public String chanel;
		// 予約タイプ
		public String leadType;
		// お客様名
		public String contactName;
		// 予約ID
		public String leadid;
		// 状態
		public String checkType;
		// 会計ID
		public String accountid;
		// 会計名
		public String accountName;
		// お客様ID
		public String contactid;
		// 売上計上日
		public String salesDate;
		// 選択状態
		public boolean checkflag;
		// 2019/07/31 請求書一括作成の改善対応（リクエストバッチ＞請求書自動作成 ＞）、この画面に、「お客様ステータス」の欄を追加していただき、すでにチェックイン完の予約がわかるように希望します by zy BEGIN
		// お客様ステータス
		public String contactStatus;
		// 2019/07/31 請求書一括作成の改善対応（リクエストバッチ＞請求書自動作成 ＞）、この画面に、「お客様ステータス」の欄を追加していただき、すでにチェックイン完の予約がわかるように希望します by zy END
		public LeadInfo(AccountAcount__c acc , boolean hadAccount){
			leadid = acc.Relreserve__c;
			accountid = acc.id;
			accountName = acc.name;
			// 2019/07/31 請求書一括作成の改善対応（リクエストバッチ＞請求書自動作成 ＞）、この画面に、「お客様ステータス」の欄を追加していただき、すでにチェックイン完の予約がわかるように希望します by zy BEGIN
			contactid = CommUtils.nullToBlank(acc.relaccount__c);
			// 2019/07/31 請求書一括作成の改善対応（リクエストバッチ＞請求書自動作成 ＞）、この画面に、「お客様ステータス」の欄を追加していただき、すでにチェックイン完の予約がわかるように希望します by zy END
			roomName = CommUtils.nullToBlank(acc.Relreserve__r.refTypeOfRooms__r.name);
			leadName = CommUtils.nullToBlank(acc.Relreserve__r.name);
			chanel = CommUtils.nullToBlank(acc.Relreserve__r.Field2__c);
			contactName = CommUtils.nullToBlank(acc.relaccount__r.name);
			leadType = CommUtils.nullToBlank(acc.Relreserve__r.ReservedType__c);
			salesDate = acc.SalesDate__c != null ? acc.SalesDate__c.format() : '';
			checkType = '';
			if (hadAccount) checkType = '1';
			checkflag = false;
			// 2019/07/31 請求書一括作成の改善対応（リクエストバッチ＞請求書自動作成 ＞）、この画面に、「お客様ステータス」の欄を追加していただき、すでにチェックイン完の予約がわかるように希望します by zy BEGIN
			contactStatus = CommUtils.nullToBlank(acc.Relreserve__r.field298__c);
			// 2019/07/31 請求書一括作成の改善対応（リクエストバッチ＞請求書自動作成 ＞）、この画面に、「お客様ステータス」の欄を追加していただき、すでにチェックイン完の予約がわかるように希望します by zy END
		}
		// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy BEGIN
		public LeadInfo(Lead__c lead , boolean hadAccount){
			leadid = lead.id;
			accountid = '';
			accountName = '';
			// 2019/07/31 請求書一括作成の改善対応（リクエストバッチ＞請求書自動作成 ＞）、この画面に、「お客様ステータス」の欄を追加していただき、すでにチェックイン完の予約がわかるように希望します by zy BEGIN
			contactid = CommUtils.nullToBlank(lead.relcontact__c);
			// 2019/07/31 請求書一括作成の改善対応（リクエストバッチ＞請求書自動作成 ＞）、この画面に、「お客様ステータス」の欄を追加していただき、すでにチェックイン完の予約がわかるように希望します by zy END
			roomName = CommUtils.nullToBlank(lead.refTypeOfRooms__r.name);
			leadName = CommUtils.nullToBlank(lead.name);
			chanel = CommUtils.nullToBlank(lead.Field2__c);
			contactName = CommUtils.nullToBlank(lead.relcontact__r.name);
			leadType = CommUtils.nullToBlank(lead.ReservedType__c);
			// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH BEGIN
			// if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI) {
			if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI && !CommConst.BOOKEST_USERDATE_FLG) {
			// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH END
				salesDate = lead.Departure__c != null ? lead.Departure__c.date().format() : '';
			} else {
				salesDate = lead.EntryTime__c != null ? lead.EntryTime__c.date().format() : '';
			}
			checkType = '';
			if (hadAccount) checkType = '1';
			checkflag = false;
			// 2019/07/31 請求書一括作成の改善対応（リクエストバッチ＞請求書自動作成 ＞）、この画面に、「お客様ステータス」の欄を追加していただき、すでにチェックイン完の予約がわかるように希望します by zy BEGIN
			contactStatus = CommUtils.nullToBlank(lead.field298__c);
			// 2019/07/31 請求書一括作成の改善対応（リクエストバッチ＞請求書自動作成 ＞）、この画面に、「お客様ステータス」の欄を追加していただき、すでにチェックイン完の予約がわかるように希望します by zy END
		}
		// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy END
	}
	// 2018/12/15 請求書の作成など自動繰返し機能 by zy END
	// 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy BEGIN
	public boolean productStockFlag{get{return currentBatchName == BATCH_KEY_STOCK_SYN;}set;}
	// 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy END
	// 2019/02/15 部屋自動割り当て by zy BEGIN
	private Set<String> monthExcudeSet = new Set<String>{BATCH_KEY_ROOM_ASSIGN};
	// 2019/02/15 部屋自動割り当て by zy END
	// 店舗選択なしのバッチ集合
	private Set<String> noShowBranchBatch = new Set<String>{BATCH_KEY_ROOM_ASSIGN};
	// 店舗表示フラグ
	public boolean isShopNoShow{get{ return noShowBranchBatch.contains(currentBatchName);}}
	// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy BEGIN
	// 2019/07/31 請求書一括作成の改善対応（リクエストバッチ＞請求書自動作成 ＞）、この画面に、「お客様ステータス」の欄を追加していただき、すでにチェックイン完の予約がわかるように希望します by zy BEGIN
	private static String queryLeadSQL = 'select id,name,Field2__c,Rroom__c,ReservedType__c,EntryTime__c,Departure__c,refTypeOfRooms__r.name,relcontact__r.name,relcontact__c,LeadReceiptDate__c,Field298__c from Lead__c';
	// 2019/07/31 請求書一括作成の改善対応（リクエストバッチ＞請求書自動作成 ＞）、この画面に、「お客様ステータス」の欄を追加していただき、すでにチェックイン完の予約がわかるように希望します by zy END
	private static List<LeadInfo> getNochekInLead(String spcd,String queryDtStr,String endDtStr,RequestInfo req){
		String sqlWhere = ' where refTypeOfRooms__r.ShopInfoRef__r.shopcode__c = :spcd ';
		Date queryDt = CommUtils.StringtoDate(queryDtStr);
		Boolean isFixedFlg = DataFixManagerUtils.getInstance().LeadFixed__c;
		// 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
		Boolean isFixedFlg1 = DataFixManagerUtils.getInstance().LeadFixed1__c;
		Integer queryDtInt = CommUtils.nullToIntZero(CommUtils.dateToYYYYMMDD(queryDt));
		// 2020/08/30 部屋状態管理インデックス機能対応 WGCH END
		if (!CommUtils.isBlank(queryDtStr)) {
			queryDtStr = CommUtils.dateToYYYYMMDD(queryDt);
			// INDEX有効化有効の場合、該当検索キーで検索する
			// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH BEGIN
			// if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI) {
			if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI && !CommConst.BOOKEST_USERDATE_FLG) {
			// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH END
				// 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
				// if (isFixedFlg) sqlWhere += ' and DepartureDateKey__c >= :queryDtStr';
				if(isFixedFlg1) sqlWhere += ' and DepartureDateIntKey__c >= :queryDtInt';
				else if(isFixedFlg) sqlWhere += ' and DepartureDateKey__c >= :queryDtStr';
				// 2020/08/30 部屋状態管理インデックス機能対応 WGCH END
				else sqlWhere += 'and DAY_ONLY(convertTimezone(Departure__c)) >= :queryDt';
			} else {
				// 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
				// if (isFixedFlg) sqlWhere += ' and EntryDateKey__c >= :queryDtStr';
				if(isFixedFlg1) sqlWhere += ' and EntryDateIntKey__c >= :queryDtInt';
				else if(isFixedFlg) sqlWhere += ' and EntryDateKey__c >= :queryDtStr';
				// 2020/08/30 部屋状態管理インデックス機能対応 WGCH END
				else sqlWhere += 'and DAY_ONLY(convertTimezone(EntryTime__c)) >= :queryDt';
			}
		}
		String querEndStr = endDtStr;
		Date endDt = CommUtils.StringtoDate(querEndStr);
		// 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
		Integer querEndInt = CommUtils.nullToIntZero(CommUtils.dateToYYYYMMDD(endDt));
		// 2020/08/30 部屋状態管理インデックス機能対応 WGCH END
		if (!CommUtils.isBlank(querEndStr)) {
			querEndStr = CommUtils.dateToYYYYMMDD(endDt);
			// INDEX有効化有効の場合、該当検索キーで検索する
			// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH BEGIN
			// if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI) {
			if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI && !CommConst.BOOKEST_USERDATE_FLG) {
			// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH END
				// INDEX有効化有効の場合、該当検索キーで検索する
				// 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
				// if (isFixedFlg) sqlWhere += ' and DepartureDateKey__c <= :querEndStr';
				if(isFixedFlg1) sqlWhere += ' and DepartureDateIntKey__c <= :querEndInt';
				else if(isFixedFlg) sqlWhere += ' and DepartureDateKey__c <= :querEndStr';
				// 2020/08/30 部屋状態管理インデックス機能対応 WGCH END
				else sqlWhere += ' and DAY_ONLY(convertTimezone(Departure__c)) <= :endDt';
			} else {
				// INDEX有効化有効の場合、該当検索キーで検索する
				// 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
				// if (isFixedFlg) sqlWhere += ' and EntryDateKey__c <= :querEndStr';
				if(isFixedFlg1) sqlWhere += ' and EntryDateIntKey__c <= :querEndInt';
				else if(isFixedFlg) sqlWhere += ' and EntryDateKey__c <= :querEndStr';
				// 2020/08/30 部屋状態管理インデックス機能対応 WGCH END
				else sqlWhere += ' and DAY_ONLY(convertTimezone(EntryTime__c)) <= :endDt';
			}
			
		}
		// 未チャックイン状態
		String nocheckIn = '';
		Integer cancelStatus = CommConst.LEAD_ST_CANCEL_FLG;
		// 正常な会計情報
		sqlWhere += ' And CancelBool__c != :cancelStatus And Field298__c = :nocheckIn';
		sqlWhere += ' order by EntryTime__c,LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c';
		// 指定条件により、既存会計情報を取得する
		List<Lead__c> leads = Database.query(queryLeadSQL + sqlWhere);
		// 指定作成日、同じお客様、同じ部屋タイプに会計データが存在場合、該当予約情報を格納する
		return commCheckExistLead(leads,req);
	}
	// 指定会計で、同じお客様、同じ部屋、会計データ存在がどうかチェックを行う
	private static List<LeadInfo> commCheckExistLead(List<Lead__c> leads, RequestInfo req) {
		// 店舗コード
		String spcd = req.spcd;
		// 処理日
		Date queryDt = CommUtils.StringtoDate(req.saleDt);
		// 既存お客様ID
		Set<String> contactSet = new Set<String>();
		// 既存部屋ID
		Set<string> roomIdSet = new Set<String>();
		// データ初期化
		for (Lead__c lead : leads) {
			if (!CommUtils.isBlank(lead.relcontact__c)) contactSet.add(lead.relcontact__c);
			if (!CommUtils.isBlank(lead.Rroom__c)) roomIdSet.add(CommUtils.nullToblank(lead.Rroom__c));
		}
		// 指定作成日、同じお客様、同じ部屋タイプに会計データが存在場合、該当予約情報を格納する
		List<LeadInfo> infos = new List<LeadInfo>();
		// 12ヶ月分の予約がまとめて作成出来る WSQ BEGIN
		// 複数作成月の売上計上日を計算する
		set<Date> salesDateSet = new set<Date>();
		// 始める日を先に格納する
		salesDateSet.add(queryDt);
		for (Integer i=1 ; i<req.loopsize; i++) {	
			// 月末の場合
			if (queryDt.day() == Date.daysInMonth(queryDt.year(),queryDt.month())) {
				// 次の計上日も月末に設定する
				Date wkDate = queryDt.addMonths(1);
				queryDt = Date.newInstance(wkDate.year(), wkDate.month(), Date.daysInMonth(wkDate.year(), wkDate.month()));
			} else {
				// 次の月の売上計上日を設定する
				queryDt = queryDt.addMonths(1);
			}
			// 翌日日付を設定する
			salesDateSet.add(queryDt);
		}
		// 12ヶ月分の予約がまとめて作成出来る WSQ END
		// 指定条件会計データ取得
		// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy BEGIN
		// set<String> extAccKeySet = getExiLeadInfo(spcd,salesDateSet,contactSet,roomIdSet);
		// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy END
		// 既存会計チェック判定
		for (Lead__c lead : leads) {
			// 会計情報が既に存在するがどうかチェック用キーワードを取得する
			String key = CommUtils.nullToBlank(getAccountKey(lead.Rroom__c ,lead.relcontact__c));
			// 各予約
			// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy BEGIN
			// infos.add(new LeadInfo(lead,extAccKeySet.contains(key)));
			infos.add(new LeadInfo(lead,false));
			// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy END
		}
		return infos;
	}
	// 指定条件会計取得
	// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy BEGIN
	/*
	private static set<String> getExiLeadInfo(String spcd ,set<Date> salesDateSet,Set<String> contactSet,Set<string> roomIdSet){
		// 会計SQL文作成
		String accountSQL = 'select id , Rroom__c , relcontact__c from Lead__c where  refTypeOfRooms__r.ShopInfoRef__r.shopcode__c = :spcd ';
		Boolean isFixedFlg = DataFixManagerUtils.getInstance().LeadFixed__c;
		Set<String> dateSet = new Set<String>();
		if (isFixedFlg) {
			for (Date salesDt : salesDateSet) {
				dateSet.add(CommUtils.dateToYYYYMMDD(salesDt));
			}
		}
		// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH BEGIN
		// if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI) {
		if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI && !CommConst.BOOKEST_USERDATE_FLG) {
		// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH END
			// INDEX有効化有効の場合、該当検索キーで検索する
			if (isFixedFlg) accountSql += ' and DepartureDateKey__c in :dateSet';
			else accountSql += ' and DAY_ONLY(convertTimezone(Departure__c)) in :salesDateSet';
		} else {
			// INDEX有効化有効の場合、該当検索キーで検索する
			if (isFixedFlg) accountSql += ' and EntryDateKey__c in :dateSet';
			else accountSql += ' and DAY_ONLY(convertTimezone(EntryTime__c)) in :salesDateSet';
		}
		if (!contactSet.isEmpty()) accountSQL += ' and relcontact__c in :contactSet';
		if (!roomIdSet.isEmpty()) accountSQL += ' and Rroom__c in :roomIdSet';
		Integer cancelblank = CommConst.LEAD_ST_CANCEL_FLG;
		accountSQL += ' And CancelBool__c != :cancelblank';
		List<Lead__c> hadLeads = Database.query(accountSQL);
		set<String> extAccKeySet = new set<String>();
		for (Lead__c lead : hadLeads) {
			// チェック用キーワードを作成する
			String key = getAccountKey(lead.Rroom__c ,lead.relcontact__c);
			// 該当キーワードに、存在の会計情報のIDを格納する（始める会計IDのみ)
			if (!CommUtils.isBlank(key) && !extAccKeySet.contains(key)) extAccKeySet.add(key);
		}
		return extAccKeySet;
	}
	*/
	// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy BEGIN
	// 予約表示ラベル
	public String SHOW_LEAD_LABEL{get{return BillCopyBatch.MAIL_LEAD_HEAD;}set;}
	// 請求書の送付状出力・出力しない切替選択機能フラグ
	public Boolean BILL_LETTER_FLG{get{return Commconst.Bill_LETTER_FLG;}set;}
	// 2020/03/31 会計ロック機能 by zy BEGIN
	private static boolean checkRsvLock(RequestInfo req){
		boolean islock =false;
		// 処理日
		Date queryDt = CommUtils.StringtoDate(req.saleDt);
		// 複数作成月の売上計上日を計算する
		Set<String> salesDtFm = new Set<String>();
		// 始める日を先に格納する
		salesDtFm.add(CommUtils.dateToYYYYMMDD(queryDt));
		for (Integer i=1 ; i<req.loopsize; i++) {	
			// 月末の場合
			if (queryDt.day() == Date.daysInMonth(queryDt.year(),queryDt.month())) {
				// 次の計上日も月末に設定する
				Date wkDate = queryDt.addMonths(1);
				queryDt = Date.newInstance(wkDate.year(), wkDate.month(), Date.daysInMonth(wkDate.year(), wkDate.month()));
			} else {
				// 次の月の売上計上日を設定する
				queryDt = queryDt.addMonths(1);
			}
			// 翌日日付を設定する
			salesDtFm.add(CommUtils.dateToYYYYMMDD(queryDt));
		}
		if (!salesDtFm.isEmpty()) {
			List<RsvAccount__c> rsvs = [select id from RsvAccount__c where isLockFlg__c = true and name in :salesDtFm];
			islock = !rsvs.isEmpty();
		}
		return islock;
	}
	// 2020/03/31 会計ロック機能 by zy END
}