public with sharing class TL_LeadSyncNotifyBatchExtend  implements  Database.Batchable<Sobject>, Database.Stateful ,Database.AllowsCallouts{
	private CommLogUtils log;
	private final String Query;					// 検索SOQL
	//定数
	//private static String CONST_USAGECONUNT_SINGLE = '1';
	private static final string CONST_RESULT_FUNCTION_TYPE_LEAD_IMPORT = '予約取込';
	private static final string CONST_RESULT_FUNCTION_TYPE_LEAD_WAIT_IMPORT = '予約取込待ち';
	private static final string CONST_RESULT_FUNCTION_TYPE_XML_IMPORT = 'XML取込完了';
	//private static final string CONST_CONNECT_RESULT_TYPE_OUT_PUT_ERROR = 'SERVICE_OUT_PUT_OK_ERROR';
	//private static final integer CONST_CONNECT_RESULT_TYPE_ERROR_COUNT = 4;
	private static final integer CONST_BATCH_EXECUTE_COUNT = 1;
	private static final String SERVICE_KEY = TL_ServiceCtrl.SERVICE_KEY;
	//public final String parentId;
	//public static final String logManagerId = 'TL_LEAD_LOG_000000000';
	// 2016/12/14 バッチ重複起動されるチェック　Wgch BEGIN
	private boolean isDupFlg = false;
	// 2016/12/14 バッチ重複起動されるチェック　Wgch END
	public TL_LeadSyncNotifyBatchExtend(){  
		//定数
		Query = 'Select Id,Status__c,Name,ErrorCount__c,ProcessLog__c,ErrorContent__c,ManageID__c,ShopCode__c From CooperationResult__c where FunctionType__c = :CONST_RESULT_FUNCTION_TYPE_LEAD_IMPORT and Status__c = :CONST_RESULT_FUNCTION_TYPE_XML_IMPORT and ParentRef__c = null And ProcessingType__c = :SERVICE_KEY ';
		log = new CommLogUtils('TL_LeadSyncNotifyBatchExtend',true); 
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
		// TL側へ未通知の管理IDをTLへ送信を行う対象
		return Database.getQueryLocator(Query);
	} 
	// ***********************************
	// バッチロジック処理開始
	// ***********************************
	public void execute(Database.BatchableContext BC, List<CooperationResult__c> scope){
		// 2018/03/07 Security Check BEGIN
		List<String> chkFields = new List<String>{'ErrorCount__c','Status__c','ProcessLog__c','ErrorContent__c'};
		Map<String,Schema.SObjectField> m = Schema.SObjectType.CooperationResult__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(chkFields, m)) {
			return;
		}
		// 2018/03/07 Security Check END
		// Batch Size is 1
		if (scope.isEmpty()) return;

		log.write_method_start('execute');
		
		CooperationResult__c parentCoo = scope[0];

		String shopCode = CommUtils.nullToBlank(parentCoo.ShopCode__c);
		if (!TL_ServiceConfigHelp.isContractShop(shopCode)) return;
		// 2016/08/08 TLの通信API処理結果はNGでも次の処理を続ける処理できるように変更 BEGIN
		String preLogMsg = CommUtils.nullToBlank(parentCoo.ProcessLog__c);
		if (!CommUtils.isBLank(preLogMsg)) preLogMsg += '\n';
		// 2016/08/08 TLの通信API処理結果はNGでも次の処理を続ける処理できるように変更 END
		log.write_log('******予約出力_完了反映API 呼出開始******');
		TL_OutputCompleteService.outputCompleteResponse rep 
				= callOutputCompleteService(parentCoo.ManageID__c,shopCode);
		if(rep.commonResponse.isSuccess){
			log.write_log('******予約出力_完了反映API 呼出終了******');
			// 2016/08/08 TLの通信API処理結果はNGでも次の処理を続ける処理できるように変更 BEGIN
			//parentCoo.ProcessLog__c = removeOverLogString(log.getAllLog());
			parentCoo.ProcessLog__c = removeOverLogString(preLogMsg + log.getAllLog());  
			// 2016/08/08 TLの通信API処理結果はNGでも次の処理を続ける処理できるように変更 END
			// 通知完了すると、ステータスを変更する
			parentCoo.Status__c = CONST_RESULT_FUNCTION_TYPE_LEAD_WAIT_IMPORT;		// 予約取込待ち
			update parentCoo;

		} else {
			String orgErrMsg = parentCoo.ErrorContent__c;
			log.write_error(rep.commonResponse.failureReason+':'+rep.commonResponse.errorDescription);
			if (orgErrMsg != log.getLastError()) {
				parentCoo.ErrorCount__c = 1;
				parentCoo.ErrorContent__c = log.getLastError();
			} else {
				parentCoo.ErrorCount__c = CommUtils.nullToZero(parentCoo.ErrorCount__c) + 1;
			}
			// 2016/08/08 TLの通信API処理結果はNGでも次の処理を続ける処理できるように変更 BEGIN
			//parentCoo.ProcessLog__c = removeOverLogString(log.getAllLog());
			parentCoo.ProcessLog__c = removeOverLogString( preLogMsg + log.getAllLog());
			// 2016/08/08 TLの通信API処理結果はNGでも次の処理を続ける処理できるように変更 END
			setSendMailAddress(parentCoo);
			update parentCoo;
		} 
		
		// 該当管理IDの関連のステータスはXML→SFDCに取込準備を行う
		List<CooperationResult__c> childrens = [select id,Status__c from CooperationResult__c where ParentRef__c = :parentCoo.id And Status__c = :CONST_RESULT_FUNCTION_TYPE_XML_IMPORT];
		for (CooperationResult__c coop : childrens) {	
			coop.Status__c = CONST_RESULT_FUNCTION_TYPE_LEAD_WAIT_IMPORT;
		}
		update childrens;
			

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
		log.write_log('予約出力_完了反映処理済み');
		log.write_method_end();
		TL_ServiceConfigHelp.writeLogToDb(log.getAllLog(), logManagerId, false);
		} catch (exception e){}*/
		TL_LeadSyncProcessBatch batch = new TL_LeadSyncProcessBatch();
		ID batchprocessid = Database.executeBatch(batch,CONST_BATCH_EXECUTE_COUNT);
		/*
		try {
		log.clear();
		log.write_method_start('SFに取込バッチ定義');
		log.write_log('バッチ(TL_LeadSyncProcessBatch)定義済み、JOBID:'+batchprocessid);
		log.write_method_end();
		TL_ServiceConfigHelp.writeLogToDb(log.getAllLog(), logManagerId, false);
		} catch(exception e){}*/
	} 
	
	private TL_OutputCompleteService.outputCompleteResponse callOutputCompleteService(String outputId,String shopCd){
		// 2016/07/29 ログ出力機能追加 BEGIN
		TL_ServiceCtrl ctrl = new TL_ServiceCtrl(log);
		// 2016/07/29 ログ出力機能追加 END
		TL_OutputCompleteService.outputCompleteResponse rep = null;
		// DEBUG MODE以外の場合、TL側へ完了通知APIを呼出する
		if (!TL_ServiceConfigHelp.getCommConfig().bIsDebug) {
			rep = ctrl.callOutputCompleteService(shopCd, outputId);
		} else {
			rep = new TL_OutputCompleteService.outputCompleteResponse();
			rep.commonResponse = new TL_OutputCompleteService.commonResponse();
			rep.commonResponse.failureReason = '[DEBUG ERR CODE]';
			rep.commonResponse.errorDescription = '[DEBUG ERR MESSAGE]';
			rep.commonResponse.isSuccess = false;
		}
		return rep;
	}
	/**
	* メール通知先のアドレス宛を設定する
	**/
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
	/**
	* ログは最大格納値を超えると、最後から格納する
	**/
	private String removeOverLogString(String log) {
		return CommLogUtils.removeOverLogString(log);
	}
}