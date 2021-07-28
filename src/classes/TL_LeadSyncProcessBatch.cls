/**
* バッチ連携：予約XML取り込みを行う
* TL-リンカーン機能連携
* 2016/10/16 ネット取り込みエラーの場合、リトライ処理をする・しない制御処理追加
*/
public with sharing class TL_LeadSyncProcessBatch implements Database.Batchable<sObject>, Database.Stateful,Database.AllowsCallouts{
	private final String Query;					// 検索SOQL
	private CommLogUtils log;
	private static final string CONST_RESULT_FUNCTION_TYPE_LEAD_IMPORT = '予約取込';
	private static final string CONST_RESULT_STATUS_TYPE_LEAD_IMPORT_NG = '予約取込NG';
	private static final string CONST_RESULT_STATUS_TYPE_LEAD_WAIT_IMPORT = '予約取込待ち';
	private static final string CONST_RESULT_STATUS_TYPE_LEAD_IMPORT_OVER = '予約取込完了';
	private static final string CONST_RESULT_STATUS_TYPE_XML_IMPORT = 'XML取込完了';
	
	//private static final string CONST_CONNECT_RESULT_TYPE_OUT_PUT_ERROR = 'SERVICE_OUT_PUT_OK_ERROR';
	//private static final integer CONST_BATCH_EXECUTE_COUNT = 1;
	//private static final String logManagerId = TL_LeadSyncNotifyBatch.logManagerId;
	private static final String SERVICE_KEY = TL_ServiceCtrl.SERVICE_KEY;
	// 2016/12/14 バッチ重複起動されるチェック　Wgch BEGIN
	private boolean isDupFlg = false;
	// 2016/12/14 バッチ重複起動されるチェック　Wgch END
	public TL_LeadSyncProcessBatch(){
		log = new CommLogUtils('TL_LeadSyncProcessBatch',true); 
		// 予約取込待ち　OR　予約取込NGの情報を取得して、再取込を行う
		Query = 'Select Id,Status__c,ErrorContent__c,ManageID__c,FunctionType__c,ErrorCount__c,ParentRef__c,ShopCode__c,ProcessLog__c From CooperationResult__c where FunctionType__c = :CONST_RESULT_FUNCTION_TYPE_LEAD_IMPORT and (status__c  =:CONST_RESULT_STATUS_TYPE_LEAD_WAIT_IMPORT or status__c  =:CONST_RESULT_STATUS_TYPE_LEAD_IMPORT_NG) and ParentRef__c != null And ProcessingType__c = :SERVICE_KEY order by Name';
	}
	// ***********************************
	// バッチ処理開始
	// ***********************************
	public Database.QueryLocator start(Database.BatchableContext BC){
		// 2016/12/14 バッチ重複起動されるチェック　Wgch BEGIN
		isDupFlg = (TL_ServiceConfigHelp.isLeadDupStartCheck(BC.getJobId()));
		if (isDupFlg) return Database.getQueryLocator('select id from CooperationResult__c limit 0');
		// 2016/12/14 バッチ重複起動されるチェック　Wgch END
		/*
		log.write_method_start('バッチ処理開始');
		log.write_log('バッチ処理正常に起動された');
		log.write_method_end();
		TL_ServiceConfigHelp.writeLogToDb(log.getAllLog(), logManagerId, false);
		*/
		// TLの予約完了APIへ送信のSFのデータを取得する
		return Database.getQueryLocator(Query); 
	}
	// ***********************************
	// バッチロジック処理開始
	// ***********************************
	public void execute(Database.BatchableContext BC, List<CooperationResult__c> scope){
		log.write_method_start('execute');
		// 2018/03/07 Security Check BEGIN
		List<String> ChkFields = new List<String>{'Status__c','ProcessLog__c','ErrorContent__c'}; 
		Map<String,Schema.SObjectField> m = Schema.SObjectType.CooperationResult__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(ChkFields, m)) {
			return;
		}
		// 2018/03/07 Security Check END
		//xml → sf
		for (CooperationResult__c coo : scope) {
			List<Attachment> rsAtt = [select Name,Body,ParentId from attachment where parentId = :coo.Id];
			if (rsAtt.isEmpty()) continue;
			String shopCode = CommUtils.nullToBlank(coo.ShopCode__c);
			// 2016/10/16 ネット取り込みエラーの場合、リトライ処理をする・しない制御処理追加 BEGIN
			if (!TL_ServiceConfigHelp.isContractShop(shopCode)) continue;
			Boolean retrySyncFlg = TL_ServiceConfigHelp.getAppConfig(shopCode).retrySync;
			// 連携ステータスはNG　かつ　リトライしない場合、処理対象外になる
			if (!retrySyncFlg && coo.Status__c == CONST_RESULT_STATUS_TYPE_LEAD_IMPORT_NG) continue;
			// 2016/10/16 ネット取り込みエラーの場合、リトライ処理をする・しない制御処理追加 END
			log.clear();
			log.write_log('XMLファイル'+rsAtt[0].Name+'を取込開始');
			// XML TO SALESFORCE
			TL_LeadInfoSync leadInfoToSfCtrl = new TL_LeadInfoSync();
			TL_ParseXmlToBookingInfoCtrl parseXmlCtrl = new TL_ParseXmlToBookingInfoCtrl();	
			try{
				log.write_log('XMLファイルパーサー開始');
				// XML PARSE
				log.write_log('XMLファイル'+rsAtt[0].Body+'を取込');	
				TL_LeadInfoSync.BI_TL_SyncInfo bookingInfo = parseXmlCtrl.parse(rsAtt[0].Body.toString(),shopCode);				
				// ログ：取込詳細情報を取得する	
				log.write_log(parseXmlCtrl.mLogUtils.getAllLog());
				log.write_log('XMLからSFへ登録する');
				TL_LeadInfoSync.BI_TL_SyncResult result = leadInfoToSfCtrl.upsertTL2LeadInfo(bookingInfo,shopCode);
				
				log.write_log(leadInfoToSfCtrl.mLogUtils.getAllLog());
				log.write_log('XMLファイル'+rsAtt[0].Name+'を取込終了');
				if(result.result == TL_LeadInfoSync.BI_TL_Result.OK){
					// 2016/08/25 EDIT ファイル更新とアップロードしない変更 BEGIN
					/*
					if(!CommUtils.isBlank(result.sfdcId)){
						log.write_log('XMLファイル'+rsAtt[0].Name+'を予約インデックスにアップロード開始');
						// 取込みXMLファイルを作成を行う
						//Attachment newAttachment = rsAtt[0].clone();
						//newAttachment.ParentId = result.sfdcId;
						//insert newAttachment;
						try {
						Attachment newAttachment = new Attachment(name = rsAtt[0].name, body = rsAtt[0].body, parentid = result.sfdcId);
						Database.SaveResult newResult = DataBase.insert(newAttachment,false);
						log.write_log('XMLをアップロード結果：'+newResult);
						// DEBUG MODEの場合、該当XMLファイルを削除なし
						if (!TL_ServiceConfigHelp.getCommConfig().bIsDebug) {
						//delete rsAtt[0];
						Database.DeleteResult delResult = DataBase.delete(rsAtt[0],false);
						log.write_log('元のXMLを削除結果：'+delResult);
						}
						} catch (exception e) {}
						log.write_log('XMLファイル'+rsAtt[0].Name+'を予約インデックスにアップロード終了');
					}*/
					coo.Status__c = CONST_RESULT_STATUS_TYPE_LEAD_IMPORT_OVER;
					coo.ProcessLog__c = removeOverLogString(log.getAllLog());
					coo.ErrorContent__c = '';
					update coo;
				}else{
					error(coo,result.message);
				}
			}catch(Exception e){
				log.write_log(parseXmlCtrl.mLogUtils.getAllLog());
				log.write_log(leadInfoToSfCtrl.mLogUtils.getAllLog());
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
		// 2016/12/14 バッチ重複起動されるチェック　Wgch BEGIN
		if (isDupFlg != null && isDupFlg) return;
		// 2016/12/14 バッチ重複起動されるチェック　Wgch END
		// 2016/12/14 該当バッチは処理中止するがどうかチェック　Wgch BEGIN
		if (TL_ServiceConfigHelp.isLeadBatchStopCheck()) return;
		// 2016/12/14 該当バッチは処理中止するがどうかチェック　Wgch END
		/*
		try {
		log.clear();
		log.write_method_start('バッチ処理終了');
		log.write_log('SF側へXMLデータを取込済み');
		log.write_method_end();
		TL_ServiceConfigHelp.writeLogToDb(log.getAllLog(), logManagerId, false);
		} catch (exception e) {}
		*/
		// バッチ 未処理完　(status__c  ='予約取込待ち' or status__c  = '予約取込NG'　）
		//　処理完了　xml　イッポト
		//定数
		List<CooperationResult__c> coos = [Select Id From CooperationResult__c where FunctionType__c = :CONST_RESULT_FUNCTION_TYPE_LEAD_IMPORT and status__c  =:CONST_RESULT_STATUS_TYPE_XML_IMPORT and ParentRef__c = null And ProcessingType__c = :SERVICE_KEY limit 1];
		if(coos.isEmpty()){
			TL_LeadSyncXmlImportBatch batch = new TL_LeadSyncXmlImportBatch();
			ID batchprocessid = Database.executeBatch(batch,1);
			/*
			try {
			log.clear();
			log.write_method_start('XML取得バッチ定義');
			log.write_log('バッチ(TL_LeadSyncXmlImportBatch)定義済み、JOBID:'+batchprocessid);
			log.write_method_end();
			TL_ServiceConfigHelp.writeLogToDb(log.getAllLog(), logManagerId, false);
			} catch(exception e){}*/
		}else{
			callTransSchedule();
		}
	}
	private void error(CooperationResult__c coo,String errorMessage){
		// 2018/03/07 Security Check BEGIN
	    List<String> chkFields = new List<String>{'ErrorCount__c','Status__c','ProcessLog__c','ErrorContent__c'};
	    Map<String,Schema.SObjectField> m = Schema.SObjectType.CooperationResult__c.fields.getMap();
	    if (!CommSecurityUtils.isCanUpdateable(chkFields, m)) {
			return;
	    }
	    // 2018/03/07 Security Check END
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
		Boolean retrySyncFlg = TL_ServiceConfigHelp.getAppConfig(shopCode).retrySync;
		if (!retrySyncFlg) coo.ErrorCount__c = 5;// WFからメール送信できる回数を設定する
		// 2016/10/16 ネット取り込みエラーの場合、リトライ処理をする・しない制御処理追加 END
		setSendMailAddress(coo);
		coo.ProcessLog__c = removeOverLogString(log.getAllLog());
		update coo;
		log.write_method_end();
	}
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
		Integer leadIntervalLength = TL_ServiceConfigHelp.DEF_MIN_INTERVAL;
		try {
		//log.clear();
		//log.write_method_start('次のスケジュール定義');
		leadIntervalLength =  TL_ServiceConfigHelp.getCommConfig().mLeadImportInterval;
		//log.write_log(String.valueOf(leadIntervalLength) + '秒後、次のスケジュール(TL_LeadSyncNotifyBatch)を起動する');
		} catch(Exception e){}
		TL_LeadSyncNotifyBatch schedult = new TL_LeadSyncNotifyBatch();
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
		String jobName = 'TL_LeadSyncNotifyBatch_' + DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, sch, schedult);
		/*
		try {
		log.write_log('次のスケジュール(TL_LeadSyncNotifyBatch)ID:'+jobId);
		log.write_method_end();
		TL_ServiceConfigHelp.writeLogToDb(log.getAllLog(), logManagerId, false);
		} catch (exception e){}
		*/
	}
	/**
	* ログは最大格納値を超えると、最後から格納する
	**/
	private String removeOverLogString(String log) {
		return CommLogUtils.removeOverLogString(log);
	}
}