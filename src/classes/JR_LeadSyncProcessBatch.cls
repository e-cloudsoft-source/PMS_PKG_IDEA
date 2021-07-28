/**
* バッチ連携：予約XML取り込みを行う
* JRラク通機能連携
* 2016/10/16 ネット取り込みエラーの場合、リトライ処理をする・しない制御処理追加
*/
public with sharing class JR_LeadSyncProcessBatch implements Database.Batchable<sObject>, Database.Stateful,Database.AllowsCallouts{
	private final String Query;                // 検索SOQL
	private CommLogUtils log;                  // ログ情報
	private static final string CONST_RESULT_FUNCTION_TYPE_LEAD_IMPORT = JR_ServiceCtrl.CONST_RESULT_FUNCTION_TYPE_LEAD_IMPORT;//'予約取込'
	private static final string CONST_RESULT_STATUS_TYPE_LEAD_IMPORT_NG = JR_ServiceCtrl.CONST_RESULT_STATUS_TYPE_LEAD_IMPORT_NG;//'予約取込NG';
	private static final string CONST_RESULT_STATUS_TYPE_LEAD_WAIT_IMPORT = JR_ServiceCtrl.CONST_RESULT_STATUS_TYPE_LEAD_WAIT_IMPORT;//'予約取込待ち';
	private static final string CONST_RESULT_STATUS_TYPE_LEAD_IMPORT_OVER = JR_ServiceCtrl.CONST_RESULT_STATUS_TYPE_LEAD_IMPORT_OVER;//'予約取込完了';
	private static final string CONST_RESULT_STATUS_TYPE_XML_IMPORT = JR_ServiceCtrl.CONST_RESULT_STATUS_TYPE_XML_IMPORT;//'XML取込完了';
	// Service Key
	private static final String SERVICE_KEY = JR_ServiceCtrl.SERVICE_KEY;
	// バッチ重複起動されるチェック
	private boolean isDupFlg = false;
	// インスタンス初期化
	public JR_LeadSyncProcessBatch(){
		log = new CommLogUtils('JR_LeadSyncProcessBatch',true); 
		// 予約取込待ち　OR　予約取込NGの情報を取得して、再取込を行う
		Query = 'Select Id,Status__c,ErrorContent__c,ManageID__c,FunctionType__c,ErrorCount__c,ParentRef__c,ShopCode__c,ProcessLog__c From CooperationResult__c where FunctionType__c = :CONST_RESULT_FUNCTION_TYPE_LEAD_IMPORT and (status__c  =:CONST_RESULT_STATUS_TYPE_LEAD_WAIT_IMPORT or status__c  =:CONST_RESULT_STATUS_TYPE_LEAD_IMPORT_NG) and ParentRef__c != null And ProcessingType__c = :SERVICE_KEY order by Name';
	}
	// ***********************************
	// バッチ処理開始
	// ***********************************
	public Database.QueryLocator start(Database.BatchableContext BC){
		// バッチ重複起動されるチェック
		isDupFlg = (BI_JR_ServiceConfigHelp.isLeadDupStartCheck(BC.getJobId()));
		// バッチは既に重複起動される場合、処理終了
		if (isDupFlg) return Database.getQueryLocator('select id from CooperationResult__c limit 0');
		// JRの予約完了APIへ送信のSFのデータを取得する
		return Database.getQueryLocator(Query); 
	}
	// ***********************************
	// バッチロジック処理開始
	// ***********************************
	public void execute(Database.BatchableContext BC, List<CooperationResult__c> scope){
		log.write_method_start('execute');
		// 2017/04/13 Field Security Check BEGIN by wx
		List<String> ChkFields = new List<String>{'Status__c','ProcessLog__c','ErrorContent__c'}; 
		Map<String,Schema.SObjectField> m = Schema.SObjectType.CooperationResult__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(ChkFields, m)) {
			return;
		}
		//xmlファイルからSFへ取り込みする
		for (CooperationResult__c coo : scope) {
		    // 該当管理データに含めている予約明細情報リストを取得する「最大100件」
			List<Attachment> rsAtt = [select Name,Body,ParentId from attachment where parentId = :coo.Id];
			if (rsAtt.isEmpty()) continue;
			// 該当ファイルに対応の店舗コードを取得する
			String shopCode = CommUtils.nullToBlank(coo.ShopCode__c);
			// 該当店舗はXMLに連携情報を定義される・されないチェックする
			if (!BI_JR_ServiceConfigHelp.isContractShop(shopCode)) continue;
			// ネット取り込みエラーの場合、リトライ処理をする・しない制御処理
			Boolean retrySyncFlg = BI_JR_ServiceConfigHelp.getAppConfig(shopCode).retrySync;
			// 連携ステータスはNG　かつ　リトライしない場合、処理対象外になる
			if (!retrySyncFlg && coo.Status__c == CONST_RESULT_STATUS_TYPE_LEAD_IMPORT_NG) continue;
			// 該当XMLの処理ログ情報初期化する
			log.clear();
			log.write_log('XMLファイル'+rsAtt[0].Name+'を取込開始');
			// XML TO SALESFORCE
			JR_ParseXmlToBookingInfoCtrl parseXmlCtrl = new JR_ParseXmlToBookingInfoCtrl();	
			try{
				log.write_log('XMLファイルパーサー開始');
				// XML PARSE
				log.write_log('XMLファイル'+rsAtt[0].Body+'を取込');	
				BI_JR_LeadInfoSync.BI_JR_SyncInfo bookingInfo = parseXmlCtrl.parse(rsAtt[0].Body.toString(),shopCode);				
				// ログ：取込詳細情報を取得する1	
				log.write_log(parseXmlCtrl.mLogUtils.getAllLog());
				log.write_log('XMLからSFへ登録する');
				BI_JR_LeadInfoSync.BI_JR_SyncResult result = BI_JR_LeadInfoSync.commUpsertLeadInfo(bookingInfo,shopCode);
				// ログ：取込詳細情報を取得する2
				log.write_log(BI_JR_LeadInfoSync.mLogUtils.getAllLog());
				log.write_log('XMLファイル'+rsAtt[0].Name+'を取込終了');
				// 処理結果はOKの場合、該当XMLの管理データのステータスは「予約取込完了」へ変更する
				if(result.result == BI_JR_LeadInfoSync.BI_JR_Result.OK){
					coo.Status__c = CONST_RESULT_STATUS_TYPE_LEAD_IMPORT_OVER;
					coo.ProcessLog__c = removeOverLogString(log.getAllLog());
					coo.ErrorContent__c = '';
					update coo;
				}else{
					error(coo,result.message);
				}
			}catch(Exception e){
				log.write_log(parseXmlCtrl.mLogUtils.getAllLog());
				//log.write_log(leadInfoToSfCtrl.mLogUtils.getAllLog());
                log.write_error(e.getStackTraceString());
                error(coo,String.valueOf(e));
			}
		}
		log.write_method_end();
	}
	// ***********************************
	// バッチ終了処理開始
	// ***********************************
	public void finish(Database.BatchableContext BC){
		// 2016/12/14 バッチ重複起動されるチェック
		if (isDupFlg != null && isDupFlg) return;
		// 2016/12/14 該当バッチは処理中止するがどうかチェック
		if (BI_JR_ServiceConfigHelp.isLeadBatchStopCheck()) return;
		// 次の予約取り込み処理を待ちする
		callTransSchedule();
	}
	// エラー処理
	private void error(CooperationResult__c coo,String errorMessage){
		// 2017/02/24 Field Security Check BEGIN
	    List<String> chkFields = new List<String>{'ErrorCount__c','Status__c','ProcessLog__c','ErrorContent__c'};
	    Map<String,Schema.SObjectField> m = Schema.SObjectType.CooperationResult__c.fields.getMap();
	    if (!CommSecurityUtils.isCanUpdateable(chkFields, m)) {
			return;
	    }
	    // 2017/02/24 Field Security Check End
		log.write_method_start('error');
		//定数
		coo.Status__c = CONST_RESULT_STATUS_TYPE_LEAD_IMPORT_NG;
		log.write_error('lead load  error ===' + errorMessage);
		errorMessage = CommLogUtils.removeOverLogString(errorMessage,255);
		if(coo.ErrorContent__c == errorMessage){
			coo.ErrorCount__c += 1;
		}else{
			coo.ErrorContent__c = errorMessage; 
			coo.ErrorCount__c = 1;
		}
		// 2016/10/16 ネット取り込みエラーの場合、リトライ処理をする・しない制御処理追加 BEGIN
		String shopCode = CommUtils.nullToBlank(coo.ShopCode__c);
		Boolean retrySyncFlg = BI_JR_ServiceConfigHelp.getAppConfig(shopCode).retrySync;
		if (!retrySyncFlg) coo.ErrorCount__c = 5;// WFからメール送信できる回数を設定する
		// 2016/10/16 ネット取り込みエラーの場合、リトライ処理をする・しない制御処理追加 END
		setSendMailAddress(coo);
		coo.ProcessLog__c = removeOverLogString(log.getAllLog());
		update coo;
		log.write_method_end();
	}
	// 通知アドレス宛情報を設定する
	private void setSendMailAddress(CooperationResult__c coop) {
		// メール送信
		String mailAdds = CommDefine__c.getOrgDefaults().ScheduleResultMailAddress__c;
		if (CommUtils.isBlank(mailAdds)) mailAdds=UserInfo.getUserEmail();
		String[] toAddresses = mailAdds.split(',');
		coop.MailSendAddress1__c = toAddresses[0];
		if (toAddresses.size() > 1) coop.MailSendAddress2__c = toAddresses[1];
		if (toAddresses.size() > 2) coop.MailSendAddress3__c = toAddresses[2];
		if (toAddresses.size() > 3) coop.MailSendAddress4__c = toAddresses[3];
		if (toAddresses.size() > 4) coop.MailSendAddress5__c = toAddresses[4];
	}
	private void callTransSchedule(){
		Integer leadIntervalLength = BI_JR_ServiceConfigHelp.DEF_MIN_INTERVAL;
		try {
		//log.clear();
		//log.write_method_start('次のスケジュール定義');
		leadIntervalLength =  BI_JR_ServiceConfigHelp.getCommConfig().mLeadImportInterval;
		//log.write_log(String.valueOf(leadIntervalLength) + '秒後、次のスケジュール(JR_LeadSyncNotifyBatch)を起動する');
		} catch(Exception e){}
		JR_LeadSyncNotifyBatch schedult = new JR_LeadSyncNotifyBatch();
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
		String jobName = 'JR_LeadSyncNotifyBatch_' + DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, sch, schedult);
	}
	/**
	* ログは最大格納値を超えると、最後から格納する
	**/
	private String removeOverLogString(String log) {
		return CommLogUtils.removeOverLogString(log);
	}
}