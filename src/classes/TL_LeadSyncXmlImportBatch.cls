public with sharing class TL_LeadSyncXmlImportBatch implements Database.Batchable<ShopInformation__c>, Database.Stateful ,Database.AllowsCallouts{

	private CommLogUtils log;
	private static final string CONST_RESULT_FUNCTION_TYPE_LEAD_IMPORT = '予約取込';
	private static final string CONST_RESULT_STATUS_TYPE_XML_IMPORT = 'XML取込完了';
	private static final string CONST_RESULT_STATUS_TYPE_LEAD_WAIT_IMPORT = '予約取込待ち';
	private static final string CONST_CONNECT_PROCESS_TYPE_TL = 'TL';
	private static final integer CONST_CONNECT_RESULT_TYPE_ERROR_COUNT = 3;
	private static final integer CONST_BATCH_EXECUTE_COUNT = 1;
	private static final String COMM_LEAD_OUT_PUT_ERROR_NAME = 'TL_SERVICE_CALL_BOOKINGINFOOUTPUTSERVICE_ERROR';
	//private static final String logManagerId = TL_LeadSyncNotifyBatch.logManagerId;
	// 2016/12/14 バッチ重複起動されるチェック　Wgch BEGIN
	private boolean isDupFlg = false;
	// 2016/12/14 バッチ重複起動されるチェック　Wgch END
	public TL_LeadSyncXmlImportBatch(){
		log = new CommLogUtils('TL_LeadSyncXmlImport',true);
	} 
	
	// ***********************************
	// バッチ処理開始  
	// ***********************************
	public Iterable<ShopInformation__c>  start(Database.BatchableContext BC){
		// 2016/12/14 バッチ重複起動されるチェック　Wgch BEGIN
		isDupFlg = (TL_ServiceConfigHelp.isLeadDupStartCheck(BC.getJobId()));
		if (isDupFlg) return new list<ShopInformation__c>();
		// 2016/12/14 バッチ重複起動されるチェック　Wgch END
		/*
		log.write_method_start('バッチ処理開始');
		log.write_log('バッチ処理正常に起動された');
		log.write_method_end();
		TL_ServiceConfigHelp.writeLogToDb(log.getAllLog(), logManagerId, false);
		*/
		List<ShopInformation__c> shops = [	
					SELECT 
	                Id
	                , Name
	                , ShopCode__c
	                From ShopInformation__c order by Seq__c limit 100];
	   // Dumy Shop Info Create
	   if (shops.isEmpty()) shops.add(new ShopInformation__c());
       return shops;
	}
	// ***********************************
	// バッチロジック処理開始
	// ***********************************
	public void execute(Database.BatchableContext BC, List<ShopInformation__c> shops){
		String shopCode = CommUtils.nullToBlank(shops[0].ShopCode__c);
		if (!TL_ServiceConfigHelp.isContractShop(shopCode)) return;
		// 2018/03/07 Security Check BEGIN
	    List<String> chkFields = new List<String>{'ProcessLog__c','ErrorCount__c','ErrorContent__c','ErrorCode__c'};
	    Map<String,Schema.SObjectField> m = Schema.SObjectType.CooperationResult__c.fields.getMap();
	    if (!CommSecurityUtils.isCanUpdateable(chkFields, m)) {
			return;
	    }
		List<String> insChkFields = new List<String>{'Name','ContentType','Body','ParentId'};
		Map<String,Schema.SObjectField> insm = Schema.SObjectType.Attachment.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(insChkFields, insm)) {
			return;
		}
		// 2018/03/07 Security Check END
		log.write_method_start('execute');
		log.write_log('店舗コード['+shopCode+']予約出力実施を行う');	
		// 2016/07/29 ログ出力機能追加 BEGIN
		TL_ServiceCtrl ctrl = new TL_ServiceCtrl(log);
		// 2016/07/29 ログ出力機能追加 END
		log.write_log('******予約出力API 呼出開始******');
		TL_BookingInfoOutputService.bookingInfoResponse rep = ctrl.callBookingInfoOutputService(shopCode);  
		
		if (!rep.commonResponse.isSuccess) {
			// ERROR
			log.write_error(rep.commonResponse.failureReason+':'+rep.commonResponse.errorDescription);
			CooperationResult__c errorCoo = new CooperationResult__c();
			// TODO ERROR
			List<CooperationResult__c> leadCallErrorCoo = [select Name,Id,ErrorCount__c,ErrorContent__c,ManageID__c from CooperationResult__c where ManageID__c =:COMM_LEAD_OUT_PUT_ERROR_NAME ];
			if(leadCallErrorCoo.isEmpty()){
				errorCoo = new CooperationResult__c(ManageID__c =COMM_LEAD_OUT_PUT_ERROR_NAME,
													FunctionType__c = CONST_RESULT_FUNCTION_TYPE_LEAD_IMPORT,
  													ErrorCount__c = 0,
  													ErrorContent__c = log.getLastError(),
  													ProcessingType__c = CONST_CONNECT_PROCESS_TYPE_TL);
  				insert errorCoo;
			}else{
				errorCoo = leadCallErrorCoo[0];
			}
			if(errorCoo.ErrorContent__c == log.getLastError())	errorCoo.ErrorCount__c ++;
			else errorCoo.ErrorCount__c = 0;
			errorCoo.ErrorContent__c = log.getLastError();
			setSendMailAddress(errorCoo);
			errorCoo.ErrorCode__c =  rep.commonResponse.failureReason;
			log.write_error(' errorDescription::' + rep.commonResponse.errorDescription);	
			errorCoo.ProcessLog__c = removeOverLogString(log.getAllLog());
			
			update errorCoo;
			return ;
		}
		log.write_log('******予約出力API 呼出終了******');
		
		// 管理IDを取得する
		String parentRef = rep.configurationSettings.outputId;

		if(rep.bookingInfoList != null ){
			
			log.write_log('['+rep.bookingInfoList.size()+']件予約XMLファイルを出力されました。' );
			// DB操作を行う
	  		Savepoint sp = Database.setSavepoint();
	  		try {
	  			List<CooperationResult__c> cooperationLst = new List<CooperationResult__c>();
	  			CooperationResult__c parentCoo = new CooperationResult__c(Status__c = CONST_RESULT_STATUS_TYPE_XML_IMPORT
	  																		,FunctionType__c = CONST_RESULT_FUNCTION_TYPE_LEAD_IMPORT
	  																		,ErrorCount__c = 0
	  																		,ManageID__c = parentRef
	  																		,ShopCode__c = shopCode
	  																		,ProcessingType__c = CONST_CONNECT_PROCESS_TYPE_TL
	  																		,ProcessLog__c = removeOverLogString(log.getAllLog())
	  																		);
				insert parentCoo;
				
				for(integer i = 0; i < rep.bookingInfoList.size(); i++){
					CooperationResult__c coo = new CooperationResult__c(Status__c = CONST_RESULT_STATUS_TYPE_LEAD_WAIT_IMPORT
																		,FunctionType__c = CONST_RESULT_FUNCTION_TYPE_LEAD_IMPORT
																		,ErrorCount__c = 0, ShopCode__c = shopCode
																		,ParentRef__c = parentCoo.id
																		,ProcessingType__c = CONST_CONNECT_PROCESS_TYPE_TL);
					cooperationLst.add(coo);
				}
				insert cooperationLst;
				//parentCoo.ProcessLog__c = removeOverLogString(log.getAllLog());
				//update parentCoo; 
				List<Attachment> atts = new List<Attachment>();
				String dateKey = System.now().format('yyMMddHHMMssSSS');
				for(integer i = 0; i < rep.bookingInfoList.size(); i++){
					TL_BookingInfoOutputService.bookingInfo bookingInfo = rep.bookingInfoList[i];
					Attachment newAttach = new Attachment(
						ParentId = cooperationLst[i].id,
						Name = 'TLPDATA_' + dateKey + CommUtils.paddingLeftZero((i+1),3) + '_' + parentRef + '.xml', 
						ContentType = 'text/xml',
						Body = Blob.valueOf(bookingInfo.infoTravelXML)
					);
					atts.add(newAttach);
				}  
				insert atts;
			} catch (Exception e) {
				// エラー処理ログを記録する
				log.write_error('連携結果処理エラー:'+e.getStackTraceString());
	  			Database.rollback(sp);
	  			throw e;
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
		log.write_log('予約出力APIから予約XMLを取得済み');
		log.write_method_end();
		TL_ServiceConfigHelp.writeLogToDb(log.getAllLog(), logManagerId, false);
		} catch (exception e){}
		*/
		// 未連携データが存在
		callNotifySchedule();
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
	private void callNotifySchedule(){
		
		Integer leadIntervalLength = TL_ServiceConfigHelp.DEF_MIN_INTERVAL;
		try {
		//log.clear();
		//log.write_method_start('次のスケジュール定義');
		leadIntervalLength =  TL_ServiceConfigHelp.getCommConfig().mLeadImportInterval;
		//log.write_log(String.valueOf(leadIntervalLength) + '秒後、次のスケジュール(TL_LeadSyncNotifyBatch)を起動する');
		} catch(exception e){}
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
		//定数
		String jobName = 'TL_LeadSyncNotifyBatch_' + DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, sch, schedult);
		/*
		try {
		log.write_log('次のスケジュール(TL_LeadSyncNotifyBatch)ID:'+jobId);
		log.write_method_end();
		TL_ServiceConfigHelp.writeLogToDb(log.getAllLog(), logManagerId, false);
		} catch(exception e){}*/
	}
	/**
	* ログは最大格納値を超えると、最後から格納する
	**/
	private String removeOverLogString(String log) {
		return CommLogUtils.removeOverLogString(log);
	}
}