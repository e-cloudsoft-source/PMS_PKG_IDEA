/**
* バッチ連携：予約XML取り込みを行う
* 予約APIから未連携の予約情報をJRから取得、SF側に格納する
* JRラク通機能連携
* 2018/11/05 らく通ログ出力機能追加
*/
public with sharing class JR_LeadSyncXmlImportBatch implements Database.Batchable<ShopInformation__c>, Database.Stateful ,Database.AllowsCallouts{
    // ログ記録クラス
	private CommLogUtils log;
	// 2018/11/05 らく通ログ出力機能追加 WSQ BEGIN
	private static Integer logMaxFils = 1000;
	// 2018/11/05 らく通ログ出力機能追加 WSQ END
    //定数
    private static final string CONST_RESULT_FUNCTION_TYPE_LEAD_IMPORT = JR_ServiceCtrl.CONST_RESULT_FUNCTION_TYPE_LEAD_IMPORT;//'予約取込';
    private static final string CONST_RESULT_STATUS_TYPE_LEAD_WAIT_IMPORT = JR_ServiceCtrl.CONST_RESULT_STATUS_TYPE_LEAD_WAIT_IMPORT;//'予約取込待ち';
    private static final string CONST_RESULT_STATUS_TYPE_XML_IMPORT = JR_ServiceCtrl.CONST_RESULT_STATUS_TYPE_XML_IMPORT;//'XML取込完了';
    private static final String CONST_CONNECT_PROCESS_TYPE_JR = JR_ServiceCtrl.SERVICE_KEY;
    // 呼出エラー
	private static final String COMM_LEAD_OUT_PUT_ERROR_NAME = 'JR_SERVICE_CALL_BOOKINGINFOOUTPUTSERVICE_ERROR';
    // バッチ重複起動されるチェック
    private boolean isDupFlg = false;
    // インスタンス初期化
	public JR_LeadSyncXmlImportBatch(){
		log = new CommLogUtils('JR_LeadSyncXmlImport',true);
	} 
	// ***********************************
	// バッチ処理開始  
	// ***********************************
	public Iterable<ShopInformation__c>  start(Database.BatchableContext BC){
		// 2016/12/14 バッチ重複起動されるチェック
		isDupFlg = (BI_JR_ServiceConfigHelp.isLeadDupStartCheck(BC.getJobId()));
		if (isDupFlg) return new list<ShopInformation__c>();
		// 店舗別予約XMLを取り込みする
		List<ShopInformation__c> shops = [	
					SELECT 
	                Id
	                , Name
	                , ShopCode__c
	                From ShopInformation__c 
	                order by Seq__c limit 100];
	   // 店舗なし場合、空白データを作成する
	   if (shops.isEmpty()) shops.add(new ShopInformation__c());
       return shops;
	}
	// ***********************************
	// バッチロジック処理開始
	// ***********************************
	public void execute(Database.BatchableContext BC, List<ShopInformation__c> shops){
	    // 該当店舗は予約取り込み対象チェックする
		String shopCode = CommUtils.nullToBlank(shops[0].ShopCode__c);
		if (!BI_JR_ServiceConfigHelp.isContractShop(shopCode)) return;
		// *********************************************************************
		// 2017/02/21 Field Security Check BEGIN
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
		// *********************************************************************
		log.write_method_start('execute');
		log.write_log('店舗コード['+shopCode+']予約出力実施を行う');	
		// 2016/07/29 ログ出力機能追加 BEGIN
		JR_ServiceCtrl ctrl = new JR_ServiceCtrl(log);
		// 2016/07/29 ログ出力機能追加 END
		log.write_log('******6.1予約照会API 呼出開始******');
		JR_ServiceCtrl.SelectBookingReply rep = ctrl.callSelectBookingService(shopCode);
		log.write_log('******6.1予約照会API 呼出終了******');
		if (!rep.commonResponse.isSuccess) {
            setErrorCooper(COMM_LEAD_OUT_PUT_ERROR_NAME,rep.commonResponse);
            return;
		}
        // SelectBooking要求で予約が0件(予約取得ID未取得)回答された場合に、処理終了
        if (!rep.isHaveData()) return;
		// 管理IDを取得する
        String managerId = rep.GetBookingID;
        log.write_log('******6.2予約取得 API 呼出開始******');
		JR_ServiceCtrl.GetBookingReply rep2 = ctrl.callGetBookingService(shopCode,managerId);  
		log.write_log('******6.2予約取得 API 呼出終了******');
		//予約取得Error		
		if (!rep2.commonResponse.isSuccess) {
		    setErrorCooper(COMM_LEAD_OUT_PUT_ERROR_NAME,rep2.commonResponse);
		    return;
		}
		// 取得した予約情報を存在する場合
		if(rep2.booingXml == null) return;
		// 取得件数を情報に記録する
        log.write_log('['+rep2.booingXml.size()+']件予約XMLファイルを出力されました。' );
        // DB操作を行う
        Savepoint sp = Database.setSavepoint();
        // 正常な取り込みの場合、取り込み結果は登録する
        try {
        	//防止管理ID重复
        	managerId = JR_ServiceCtrl.getManagerDataId(managerId);
            //先生成一笔由管理Id确定的親連携結果
            List<CooperationResult__c> cooperationLst = new List<CooperationResult__c>();
            CooperationResult__c parentCoo = new CooperationResult__c(
                Status__c = CONST_RESULT_STATUS_TYPE_XML_IMPORT
                ,FunctionType__c = CONST_RESULT_FUNCTION_TYPE_LEAD_IMPORT
                ,ErrorCount__c = 0
                ,ManageID__c = managerId
                ,ShopCode__c = shopCode
                ,ProcessingType__c = CONST_CONNECT_PROCESS_TYPE_JR
                ,ProcessLog__c = removeOverLogString(log.getAllLog())
            );
            insert parentCoo;
            //一个管理ID下会有多笔数据、多笔数据作为子連携結果
            for(integer i = 0; i < rep2.booingXml.size(); i++) {
                CooperationResult__c coo = new CooperationResult__c(
                    // 該当明細データは通知APIへ確認通知終わり場合、ステータスを変更する
		            Status__c = CONST_RESULT_STATUS_TYPE_XML_IMPORT
	                ,FunctionType__c = CONST_RESULT_FUNCTION_TYPE_LEAD_IMPORT
	                ,ErrorCount__c = 0, ShopCode__c = shopCode
	                ,ParentRef__c = parentCoo.id
	                ,ProcessingType__c = CONST_CONNECT_PROCESS_TYPE_JR);
                cooperationLst.add(coo);
            }
            insert cooperationLst;
	        //每一笔子連携結果下添加一个xml文件
	        List<Attachment> atts = new List<Attachment>();
	        String dateKey = System.now().format('yyMMddHHMMssSSS');
	        for(integer i = 0; i < rep2.booingXml.size(); i++){
	            Attachment newAttach = new Attachment(
	                ParentId = cooperationLst[i].id,
	                Name = 'JRPDATA_' + dateKey + '_' + rep.GetBookingID +  '_' + CommUtils.paddingLeftZero((i+1),3) + '.xml', 
	                ContentType = 'text/xml',
	                Body = Blob.valueOf(rep2.booingXml[i])
	            );
	            atts.add(newAttach);
	        }  
	        insert atts;
        } catch (Exception e) {
	        // エラー処理ログを記録する
	        log.write_error('連携結果処理エラー:'+e.getStackTraceString());
	        Database.rollback(sp);
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
        // 2018/11/05 らく通ログ出力機能追加 WSQ BEGIN
        CommLogUtils.saveLogToDb(log.getAllLog(),CommLogUtils.LogType.JR,logMaxFils);
        // 2018/11/05 らく通ログ出力機能追加 WSQ END
		// 予約通知バッチを呼び出する
		JR_LeadSyncNotifyBatchExtend batch = new JR_LeadSyncNotifyBatchExtend();
		ID batchprocessid = Database.executeBatch(batch,1);
	}
	// メール通知のメールアドレス宛情報を取得する
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
	/*
	// 次のバッチ起動時間定義情報を取得する
	private void callNotifySchedule(){
        // 次のバッチの起動間隔時間を取得する（秒単位）
		Integer leadIntervalLength = BI_JR_ServiceConfigHelp.DEF_MIN_INTERVAL;
		try {
		    // XMLの設定値から取得する
    		leadIntervalLength =  BI_JR_ServiceConfigHelp.getCommConfig().mLeadImportInterval;
		} catch(exception e){}
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
		//定数
		String jobName = 'JR_LeadSyncNotifyBatch_' + DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, sch, schedult);
	}*/
	// 連携結果にエラー情報を記録する
	private void setErrorCooper(String errKey,JR_ServiceCtrl.JR_ResultInfoItem errInfo) {
        // 2018/03/07 Security Check BEGIN
        List<String> chkFieldsLst = new List<String>{'processlog__c','errorcount__c','errorcontent__c','errorcode__c'};
        Map<String,Schema.SObjectField> mm = Schema.SObjectType.CooperationResult__c.fields.getMap();
        if (!CommSecurityUtils.isCanUpdateable(chkFieldsLst, mm)) {
        	return ;
        }
        // 2018/03/07 Security Check END
        // ERROR
        CooperationResult__c errorCoo = new CooperationResult__c();
        // TODO ERROR
        List<CooperationResult__c> leadCallErrorCoo = [select Name,Id,ErrorCount__c,ErrorContent__c,ManageID__c from CooperationResult__c where ManageID__c =:errKey ];
        if(leadCallErrorCoo.isEmpty()){
            errorCoo = new CooperationResult__c(ManageID__c = errKey,
                                                FunctionType__c = CONST_RESULT_FUNCTION_TYPE_LEAD_IMPORT,
                                                ErrorCount__c = 0,
                                                ErrorContent__c = log.getLastError(),
                                                ProcessingType__c = CONST_CONNECT_PROCESS_TYPE_JR);
            insert errorCoo;
        }else{
            errorCoo = leadCallErrorCoo[0];
        }
        if(errorCoo.ErrorContent__c == log.getLastError())  errorCoo.ErrorCount__c ++;
        else errorCoo.ErrorCount__c = 0;
        errorCoo.ErrorContent__c = log.getLastError();
        setSendMailAddress(errorCoo);
        errorCoo.ErrorCode__c = errInfo.failureReason;
        log.write_error(' errorDescription::' + errInfo.errorDescription);   
        errorCoo.ProcessLog__c = removeOverLogString(log.getAllLog());
        update errorCoo;
	}
	/**
	* ログは最大格納値を超えると、最後から格納する
	**/
	private String removeOverLogString(String log) {
		return CommLogUtils.removeOverLogString(log);
	}
	
}