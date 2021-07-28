/**
* 日次処理：買掛バッチ処理
* 2015/11/11 INIT
* 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジックの追加
* 2017/02/28 手数料集計対象期間指定できるように改善対応
**/
public with sharing class BulkProcessPurchaseManagentBatch implements Database.Batchable<ShopInformation__c>, Database.Stateful, Schedulable {

	private final String gShopCode;				// 店舗コード
	private Date gSaleDate;						// 売上計上日
	//private final String gRsvAccId;				// 指定の売上日
	private Boolean isFromSchedule;		// スケジュールからバッチ起動する
	// 2017/02/28 手数料集計対象期間指定できるように改善対応 BEGIN
	private Boolean isBetweenProcess = false;	// 期間指定処理フラグ
	private Date gSaleEndDate;
	private CooperationResult__c termCoop;
	private List<String> gNextJobs;
	// 2017/02/28 手数料集計対象期間指定できるように改善対応 END
	// スケジュールで該当Methodを呼び出する
	public BulkProcessPurchaseManagentBatch(){
		isFromSchedule=true;
	}
	// 2017/02/28 手数料集計対象期間指定できるように改善対応 BEGIN
	// 手動でスケジュール起動の場合
	public BulkProcessPurchaseManagentBatch (String pShopCd, Date pSaleDate, Date pSaleEndDate, List<String> pNextJobs ) {
		gShopCode = pShopCd;
		gSaleDate = pSaleDate;
		isFromSchedule = false;
		gSaleEndDate = pSaleEndDate;
		if (pSaleEndDate != null) isBetweenProcess = true;
		gNextJobs = pNextJobs;
	}
	// 2017/02/28 手数料集計対象期間指定できるように改善対応 END
	// バッチ初期関数[スケジュールからバッチ起動]
	// 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジックの追加 BEGIN
	//private  BulkProcessPurchaseManagentBatch (Id pRsvAccId, String pShopCd, Date pSaleDate, Boolean pIsFromSchedule) {
	private  BulkProcessPurchaseManagentBatch (String pShopCd, Date pSaleDate, Boolean pIsFromSchedule,Date pSaleEndDate,List<String> pNextJobs, Boolean pIsBetweenProcess) {
		//gRsvAccId = pRsvAccId;
		gSaleEndDate = pSaleEndDate;
		if (pSaleEndDate != null) isBetweenProcess = true;
		gNextJobs = pNextJobs;
		// 2017/03/16 既存バッチスケジールを自動続けて実施できる対応 BUGFIX BEGIN
		isBetweenProcess = pIsBetweenProcess == null ? false : pIsBetweenProcess;
		// 2017/03/16 既存バッチスケジールを自動続けて実施できる対応 BUGFIX END
	// 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジックの追加 BEND
		gShopCode = pShopCd;
		gSaleDate = pSaleDate;
		isFromSchedule = pIsFromSchedule;
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
	      	gSaleDate = (Date.today().addDays(days));
		}
		// スケジュール実施開始日
		// 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジックの追加 BEGIN
		//String strProcessDate = DateTime.newInstance(gSaleDate.year(), gSaleDate.month(), gSaleDate.day()).format('yyyyMMdd');
		//List<RsvAccount__c> rsvAccLst = [select id,Name from RsvAccount__c where Name = :strProcessDate limit 1];
		// 休館日など売上ないの場合
		//if (rsvAccLst.isEmpty()) {
			// 処理終了
		//	return;
		//}
		// バッチスケジュールを起動する
		//BulkProcessPurchaseManagentBatch batch = new BulkProcessPurchaseManagentBatch(rsvAccLst[0].Id, gShopCode, gSaleDate, isFromSchedule);
		BulkProcessPurchaseManagentBatch batch = new BulkProcessPurchaseManagentBatch(gShopCode, gSaleDate, isFromSchedule, gSaleEndDate, gNextJobs, isBetweenProcess);
		// 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジックの追加 END
		// バッチ処理設定
		DataBase.executeBatch(batch, 1);
	}
	// ***********************************
	// バッチ処理開始
	// ***********************************
	public Iterable<ShopInformation__c> start(Database.BatchableContext info){ 
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
		} 
		// 手動でスケジュールを起動する
		else {
			shops.add(new ShopInformation__c(ShopCode__c = gShopCode));
			// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 BEGIN
			if (isBetweenProcess) {
				// 該当店舗コードをコピー
				ShopInformation__c wkShop = shops[0].clone(false,true);
				shops.clear();

				// 指定期間の売上名リストを取得する
				Date beginDate = gSaleDate;
				Date endDate = gSaleEndDate;
				//List<Date> rsLst = new List<Date>();
				while (beginDate <= endDate) {
					// 書式化する
					String currDtStr = DateTime.newInstance(beginDate.year(),beginDate.month(),beginDate.day()).format('yyyyMMdd');
					ShopInformation__c cloneShop = wkShop.clone(false,true);
					cloneShop.Name = currDtStr;
					shops.add(cloneShop);
					beginDate = beginDate.adddays(1);
				}
			}
			// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 END
		}
       return shops;
	}

	// ***********************************
	// バッチロジック処理開始
	// ***********************************
	public void execute(Database.BatchableContext BC, List<ShopInformation__c> scope){

		// 販売データが非存在場合、処理中止、メール送信を行う
		// 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジック
		//if (CommUtils.isBlank(gRsvAccId)) return;
		string errMsgDetail = '';
		string infoMsgDetail = '';
		//Integer okRsNums = 0;
		AccountingSyncBatchHelp conf = null;
		CommLogUtils log = new CommLogUtils('BulkProcessPurchaseManagentBatch', true);
		log.write_method_start('処理結果：');
		// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 BEGIN
		Date wkSalesDate = gSaleDate;
		// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 END
try {
		// 支店コードを取得する
		for (ShopInformation__c shop : scope) {
			String shopCode = CommUtils.nullToBlank(shop.ShopCode__c);
			// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 BEGIN
			if (isBetweenProcess) wkSalesDate = CommUtils.stringToDate(shop.Name);
			// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 END
			log.write_log('【店舗コード】：' + shopCode) ;
			conf = new AccountingSyncBatchHelp(shopCode);
			// 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジック
			//PurchaseManagentProcess proc = new PurchaseManagentProcess(gSaleDate,shopCode,conf);
			PurchaseManagentProcess proc = new PurchaseManagentProcess(wkSalesDate,shopCode,conf);
			// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 BEGIN
			// CLEAR DATA
			PurchaseManagentProcess.ResultInfo rs;
			rs = proc.clearExistDate();
			infoMsgDetail += '\n' +'削除：['+rs.rsNums+']件';
			//okRsNums += rs.rsNums;
			if (proc.log.isHaveError()) errMsgDetail += '\n' +proc.log.getAllError();
			rs = proc.generalNetAgtSalesRate();
			infoMsgDetail += '\n' +'販売手数料新規：['+rs.rsNums+']件';
			if (proc.log.isHaveError()) errMsgDetail += '\n' +proc.log.getAllError();
			//okRsNums += rs.rsNums;
			rs = proc.generalCardSalesRate();
			infoMsgDetail += '\n' +'カード手数料新規：['+rs.rsNums+']件';
			if (proc.log.isHaveError()) errMsgDetail += '\n' +proc.log.getAllError();
			//okRsNums += rs.rsNums;
		}
} catch (Exception e)	{
	// 2020/03/31 会計ロック機能 by zy BEGIN
	if (e.getMessage().contains(Label.MSG_006_0459)) log.write_error( CommUtils.getFieldValidationMessage(e.getMessage()));
	else
	// 2020/03/31 会計ロック機能 by zy END
	log.write_error(e.getmessage());
}
		// 次の店舗の処理を行う
		//if (okRsNums == 0 && Commutils.isBLank(errMsgDetail)) return;
// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 BEGIN
		//log.write_log('【仕入日】：'+gSaleDate.format());
		log.write_log('【仕入日】：'+wkSalesDate.format());
// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 END
		if (!Commutils.isBlank(infoMsgDetail)) log.write_log(infoMsgDetail);
		// 処理情報を記録する
		if (!Commutils.isBlank(errMsgDetail) ) {
			log.write_log('処理詳細:');
			log.write_log(errMsgDetail);
		}
// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 BEGIN
if (!isBetweenProcess) {
// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 END
		// 連携結果履歴に記録する
		// メール通知先のメールアドバイスを取得、設定する
		// 新規作成を行う
		CooperationResult__c newCoop = new CooperationResult__c(
			FunctionType__c = AccountingSyncBatchHelp.COOP_STATUS_PURCHASE_CHARGE,
			ErrorCount__c = log.isHaveError() ? 1 : 0,
			ErrorContent__c = CommLogUtils.removeOverLogString(log.getAllError(),255),
			MailSendComplete__c = false,
			ShopCode__c = !scope.isEmpty() ? scope[0].ShopCode__c : null,
			ProcessLog__c =  log.getAllLog()
		);
		// メールアドバイス設定する
		setSendMailAddress(newCoop,conf);
		insert newCoop;
// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 BEGIN
} else {
	if (termCoop == null) {
		termCoop = new CooperationResult__c();
		setSendMailAddress(termCoop,conf);
	}
	termCoop.FunctionType__c = AccountingSyncBatchHelp.COOP_STATUS_PURCHASE_CHARGE;
	if (termCoop.ErrorCount__c == 0) termCoop.ErrorCount__c = log.isHaveError() ? 1 : 0;
	if (CommUtils.isBlank(termCoop.ErrorContent__c)) termCoop.ErrorContent__c = CommLogUtils.removeOverLogString(log.getAllError(),255);
	termCoop.MailSendComplete__c = false;
	termCoop.ShopCode__c = !scope.isEmpty() ? scope[0].ShopCode__c : null;
	termCoop.ProcessLog__c = CommLogUtils.removeOverLogString((CommUtils.nullToBlank(termCoop.ProcessLog__c) + log.getAllLog() + '\n'), null);
}
// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 END
	}
	// ***********************************
	// バッチ終了処理開始
	// ***********************************
	public void finish(Database.BatchableContext BC){
// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 BEGIN
		if (isBetweenProcess) {	
			// 新規作成を行う
			if (termCoop != null) insert termCoop;
		}
		if (gNextJobs != null && !gNextJobs.isEmpty()) {
			// 次のジョブを起動する
			String firstJobName = gNextJobs[0];
			if (!isBetweenProcess) gSaleEndDate = null;
			BatchControlCenter.startNextBatch(firstJobName, gShopCode, gSaleDate, gSaleEndDate, gNextJobs ,null);
		}
// 2017/02/16 Freee仕訳集計対象期間指定できるように改善対応 END	
	}
	/**
	* メール通知先のアドレス宛を設定する
	**/
	private void setSendMailAddress(CooperationResult__c coop, AccountingSyncBatchHelp config) {
		if (config == null || config.sendMailAddr.isEmpty()) return;
		// メール送信
		coop.MailSendAddress1__c = config.sendMailAddr[0];
		if (config.sendMailAddr.size() > 1) coop.MailSendAddress2__c = config.sendMailAddr[1];
		if (config.sendMailAddr.size() > 2) coop.MailSendAddress3__c = config.sendMailAddr[2];
		if (config.sendMailAddr.size() > 3) coop.MailSendAddress4__c = config.sendMailAddr[3];
		if (config.sendMailAddr.size() > 4) coop.MailSendAddress5__c = config.sendMailAddr[4];
	}
}