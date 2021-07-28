public with sharing class SyncStatusManagerCtrl extends CommBaseCtrl {

    // ***************** バッチ復旧と監視 ******************//
	public enum JOBTYPE{TLIMP,TLSTOCK,TAIMP,TASTOCK,WATCH,JRIMP,JRSTOCK}
	//enum RESULT{OK,NG)
	public BatchChkAndRestore batChkAndRestore{get; private set;}
    // バッチ停止処理
    // return:  [0]:異常情報
    //          [1]:uuid
    //          [2]:ログ情報
    @RemoteAction
    public static string[] stopBatchProcess(String jobTypeStr, String pUUID, String batchDefJson) {
    	String[] rsMsg = new List<String>{'',pUUID,'',''};
        try {
            BatchStatusInfo defInf = getJsonBatchDef(batchDefJson);
            // バッチ停止処理を行う
            if (jobTypeStr == JOBTYPE.TLIMP.name()) {
                TL_ServiceConfigHelp.stopLeadBatch();
            } else if (jobTypeStr == JOBTYPE.TLSTOCK.name()) {
                TL_ServiceConfigHelp.stopStockBatch();
            } else if (jobTypeStr == JOBTYPE.TAIMP.name()) {
                TA_ServiceConfigHelp.stopLeadBatch();
            } else if (jobTypeStr == JOBTYPE.TASTOCK.name()) {
                TA_ServiceConfigHelp.stopStockBatch();
            } else if (jobTypeStr == JOBTYPE.JRIMP.name()) {
                BI_JR_ServiceConfigHelp.stopLeadBatch();
            } else if (jobTypeStr == JOBTYPE.JRSTOCK.name()) {
                BI_JR_ServiceConfigHelp.stopStockBatch();
            } else if (jobTypeStr == JOBTYPE.WATCH.name()) {
                SyncWatchBatch watch = new SyncWatchBatch(defInf);
                watch.stopWatchBatch();
            }
            rsMsg[2] = getBatchLog(defInf, 'バッチスケジール停止処理開始...');
            rsMsg[3] = '処理中...';
        } catch (Exception e) {
            rsMsg[0] = e.getMessage();
        }
        return rsMsg;
    }
    // バッチ再起動処理を行う
    // return:  [0]:異常情報
    //          [1]:uuid
    //          [2]:ログ情報
    @RemoteAction
    public static string[] restBatchProcess(String jobTypeStr, String pUUID, String batchDefJson) {
        // バッチ復旧処理を行う
    	String[] rsMsg = new List<String>{'',pUUID,'','',''};
        try {
            BatchStatusInfo defInf = getJsonBatchDef(batchDefJson);
            List < Id > jobIds = null;
            Id jobId = null;
            // バッチ停止処理を行う
            if (jobTypeStr == JOBTYPE.TLIMP.name()) {
                jobId = TL_ServiceConfigHelp.startLeadBatch();
            } else if (jobTypeStr == JOBTYPE.TLSTOCK.name()) {
                jobId = TL_ServiceConfigHelp.startStockBatch();
            } else if (jobTypeStr == JOBTYPE.TAIMP.name()) {
                jobId = TA_ServiceConfigHelp.startLeadBatch();
            } else if (jobTypeStr == JOBTYPE.TASTOCK.name()) {
                jobId = TA_ServiceConfigHelp.startStockBatch();
            } else if (jobTypeStr == JOBTYPE.JRIMP.name()) {
                jobId = BI_JR_ServiceConfigHelp.startLeadBatch();
            } else if (jobTypeStr == JOBTYPE.JRSTOCK.name()) {
                jobId = BI_JR_ServiceConfigHelp.startStockBatch();
            } else if (jobTypeStr == JOBTYPE.WATCH.name()) {
                SyncWatchBatch watch = new SyncWatchBatch(defInf);
                jobIds = watch.startWatchBatch();
            }
			if (jobIds == null) jobIds = new List<Id>{jobId};
            if (!jobIds.isEmpty()) {
                List < CronTrigger > crons = [select Id, State from CronTrigger where Id =: jobIds];
                if (crons.isEmpty()) {
                    rsMsg[0] = getBatchLog(defInf, 'バッチスケジール起動失敗');
                    defInf.isRunning = false;
                }
                for (CronTrigger cron: crons) {
                    if (cron.State == 'ERROR') {
                        rsMsg[0] = getBatchLog(defInf, 'バッチスケジール起動失敗');
                        defInf.isRunning = false;
                        break;
                    } else {
                        defInf.isRunning = true;
                        rsMsg[2] = getBatchLog(defInf, 'バッチスケジール起動成功');
                    }
                }
                rsMsg[3] = defInf.getStatusMsg();
            }
        } catch (Exception e) {
            rsMsg[0] = e.getMessage();
        }
        // 最新バッチ状況を確認する

        return rsMsg;
    }
    //
    // return:  [0]:バッチ実施状態：1:実施中,0:停止中,-1:異常,2:状態返却
    //          [1]:uuid
    //          [2]:ログ/異常メッセージ
    @remoteAction
    public static String[] refreshBatchStatus(String jobTypeStr, String pUUID, String batchDefJson, Boolean onlyWatchStatus) {

    	String[] rsMsg = new List<String>{'',pUUID,'',''};
        // JSONからCLASS作成
        BatchStatusInfo batch = getJsonBatchDef(batchDefJson);
        //BatchStatusInfo batch = new BatchStatusInfo(jobTypeStr);
        batch.restBatchStatus();
        //defInf.isRunning = batch.isRunning;
        if (onlyWatchStatus) {
            rsMsg[0] = '2';
            rsMsg[2] = '';
            rsMsg[3] = batch.getStatusMsg();
        } else {
            if (batch.isRunning) {
                rsMsg[0] = '1';
                rsMsg[2] = getBatchLog(batch, 'バッチスケジール停止処理中...');
                rsMsg[3] = '処理中...';
            } else {
                rsMsg[0] = '0';
                rsMsg[2] = getBatchLog(batch, 'バッチスケジール停止処理済');
                rsMsg[3] = batch.getStatusMsg();
                // 停止対象バッチの
                if (jobTypeStr == JOBTYPE.TLIMP.name()) {
                    TL_ServiceConfigHelp.clearLeadBatchStopFlg();
                } else if (jobTypeStr == JOBTYPE.TLSTOCK.name()) {
                    TL_ServiceConfigHelp.clearStockBatchStopFlg();
                } else if (jobTypeStr == JOBTYPE.TAIMP.name()) {
                    TA_ServiceConfigHelp.clearLeadBatchStopFlg();
                } else if (jobTypeStr == JOBTYPE.TASTOCK.name()) {
                    TA_ServiceConfigHelp.clearStockBatchStopFlg();
                } else if (jobTypeStr == JOBTYPE.JRIMP.name()) {
                    BI_JR_ServiceConfigHelp.clearLeadBatchStopFlg();
                } else if (jobTypeStr == JOBTYPE.JRSTOCK.name()) {
                    BI_JR_ServiceConfigHelp.clearStockBatchStopFlg();
                }
            }
        }
        return rsMsg;
    }
    private static BatchStatusInfo getJsonBatchDef(String batchDefJson) {
        return (BatchStatusInfo) JSON.deserializeStrict(batchDefJson, BatchStatusInfo.class);
    }
    private static String getBatchLog(BatchStatusInfo defInf, String str) {
        return System.now().format('yyyyMMddHHmmsss') + ' ' + defInf.label + ':' + str;
    }
    // バッチスケジールの監視と復旧       
    public class BatchStatusInfo {
 		public String label{get;private set;}
 		public Boolean statusOn{get;private set;}
 		public Boolean isRunning{get;private set;}
 		public String jsonStr{get; private set;}
 		public String jobTypeStr{get;private set;}
 		// 監視バッチの監視インタバル値（時間単位)
 		public Integer interval{get;private set;}
 		public String jobName{get;private set;}
 		// バッチの定義とバッチの現状状況により、情報戻る
 		//
 		public boolean isSendMail{get;private set;}
        public String getStatusMsg() {
            String msg = '';
            if ((statusOn && !isRunning) || (!statusOn && isRunning)) {
                msg = '異常';
                if (statusOn && !isRunning) msg += '(停止中)';
                else if (!statusOn && isRunning) msg += '(実行中)';
            } else {
                msg = '正常';
                if (isRunning) msg += '(実行中)';
                else msg += '(停止中)';
            }
            return msg;
        }
        // 該当バッチの最新状況を取得する
        public void restBatchStatus() {
            if (jobTypeStr == JOBTYPE.TLIMP.name()) {
                isRunning = TL_ServiceConfigHelp.isLeadRuning(null);
            } else if (jobTypeStr == JOBTYPE.TLSTOCK.name()) {
                isRunning = TL_ServiceConfigHelp.isStockRuning(null);
            } else if (jobTypeStr == JOBTYPE.TAIMP.name()) {
                isRunning = TA_ServiceConfigHelp.isLeadRuning(null);
            } else if (jobTypeStr == JOBTYPE.TASTOCK.name()) {
                isRunning = TA_ServiceConfigHelp.isStockRuning(null);
            } else if (jobTypeStr == JOBTYPE.JRIMP.name()) {
                isRunning = BI_JR_ServiceConfigHelp.isLeadRuning(null);
            } else if (jobTypeStr == JOBTYPE.JRSTOCK.name()) {
                isRunning = BI_JR_ServiceConfigHelp.isStockRuning(null);
            } else if (jobTypeStr == JOBTYPE.WATCH.name()) {
                SyncWatchBatch watch = new SyncWatchBatch(this);
                isRunning = watch.isWatchRuning();
            }
        }
        // バッチの初期定義情報を取得
        public BatchStatusInfo(Dom.XmlNode pNode, JOBTYPE pJobType) {
            statusOn = false;
            isRunning = false;
            isSendMail = false;
            interval = 0;
            //jobType = pJobType;
            jobTypeStr = pJobType.name();
            Dom.XmlNode batchNameField = pNode.getChildElement('BATCHLABEL', null);
            if (batchNameField != null) {
                label = CommUtils.nullToBlank(batchNameField.getText());
            }
            Dom.XmlNode statusField = pNode.getChildElement('BATCHOPEN', null);
            if (statusField != null) {
                statusOn = Boolean.valueOf(CommUtils.nullToBlank(statusField.getText()));
            }
            Dom.XmlNode interValField = pNode.getChildElement('INTERVAL', null);
            if (interValField != null) {
                try {
                    interval = CommUtils.nullToIntZero(interValField.getText());
                } catch (Exception e) {}
                // 1日以上定義する場合
                if (interval >= 24 * 60) interval = 0;
                // 5分以下を定義する場合
                else if (interval < 5) interval = 5;
            }
            Dom.XmlNode jobNameField = pNode.getChildElement('APEXJOBNAME', null);
            if (jobNameField != null) {
                jobName = CommUtils.nullToBlank(jobNameField.getText());
            }
            Dom.XmlNode sendMailField = pNode.getChildElement('SENDMAIL', null);
            if (sendMailField != null) {
                isSendMail = Boolean.valueOf(CommUtils.nullToBlank(sendMailField.getText()));
            }
        }
    }
    // 監視と復旧処理主クラス
    public class BatchChkAndRestore {
        // 処理プロセス名
	 	public list<BatchStatusInfo> batchStatusLst{get; private set;}
        // 在庫
        public BatchChkAndRestore() {
            // XMLにバッチ機能の有効化定義取得、初期化する
            initBatchDefine();
            // バッチの最新状態をチェックする
            setBatchStatus();
        }
        // 各バッチの現状のステータスを取得する
        private void setBatchStatus() {
            // 指定のバッチのステータスを取得する
            //  JOBTYPE{TLIMP,TLSTOCK,TAIMP,TASTOCK,WATCH}
            // 存在チェックを行う
            for (BatchStatusInfo batch: batchStatusLst) {
                batch.restBatchStatus();
                batch.jsonStr = JSON.serialize(batch);
            }
        }
        // バッチ定義情報を取得する
        private void initBatchDefine() {
            // 定義したバッチ情報を格納リスト
            batchStatusLst = new list < BatchStatusInfo > ();
            // Document定義ファイル名
            String xmlDocName = 'SyncStatusManagerConfigXml';
            try {
                // ROOTNODE定義
                Dom.XmlNode rootNode = CommXmlUtils.parseXmlDoc(xmlDocName, '');
                // TL取り込み
                Dom.XmlNode jobConfigField = rootNode.getChildElement('TLIMPJOBCONFIG', null);
                if (jobConfigField != null) {
                    BatchStatusInfo batch = new BatchStatusInfo(jobConfigField, JOBTYPE.TLIMP);
                    if (CommUtils.isBlank(batch.jobName)) batch.jobName = 'TL予約取込';
                    if (!CommUtils.isBlank(batch.label)) batchStatusLst.add(batch);

                }
                // TL在庫調整
                jobConfigField = rootNode.getChildElement('TLSTOCKJOBCONFIG', null);
                if (jobConfigField != null) {
                    BatchStatusInfo batch = new BatchStatusInfo(jobConfigField, JOBTYPE.TLSTOCK);
                    if (CommUtils.isBlank(batch.jobName)) batch.jobName = 'TL在庫調整';
                    if (!CommUtils.isBlank(batch.label)) batchStatusLst.add(batch);
                }
                // TA取り込み
                jobConfigField = rootNode.getChildElement('TAIMPJOBCONFIG', null);
                if (jobConfigField != null) {
                    BatchStatusInfo batch = new BatchStatusInfo(jobConfigField, JOBTYPE.TAIMP);
                    if (CommUtils.isBlank(batch.jobName)) batch.jobName = 'TA予約取込';
                    if (!CommUtils.isBlank(batch.label)) batchStatusLst.add(batch);
                }
                // TA在庫調整
                jobConfigField = rootNode.getChildElement('TASTOCKJOBCONFIG', null);
                if (jobConfigField != null) {
                    BatchStatusInfo batch = new BatchStatusInfo(jobConfigField, JOBTYPE.TASTOCK);
                    if (CommUtils.isBlank(batch.jobName)) batch.jobName = 'TA在庫調整';
                    if (!CommUtils.isBlank(batch.label)) batchStatusLst.add(batch);
                }
                // JR取り込み
                jobConfigField = rootNode.getChildElement('JRIMPJOBCONFIG', null);
                if (jobConfigField != null) {
                    BatchStatusInfo batch = new BatchStatusInfo(jobConfigField, JOBTYPE.JRIMP);
                    if (CommUtils.isBlank(batch.jobName)) batch.jobName = 'JR予約取込';
                    if (!CommUtils.isBlank(batch.label)) batchStatusLst.add(batch);
                }
                // JR在庫調整
                jobConfigField = rootNode.getChildElement('JRSTOCKJOBCONFIG', null);
                if (jobConfigField != null) {
                    BatchStatusInfo batch = new BatchStatusInfo(jobConfigField, JOBTYPE.JRSTOCK);
                    if (CommUtils.isBlank(batch.jobName)) batch.jobName = 'JR在庫調整';
                    if (!CommUtils.isBlank(batch.label)) batchStatusLst.add(batch);
                }
                // 監視バッチの暗黙の自動RETRY回数定義
                jobConfigField = rootNode.getChildElement('WATCHBATCHCONFIG', null);
                if (jobConfigField != null) {
                    BatchStatusInfo batch = new BatchStatusInfo(jobConfigField, JOBTYPE.WATCH);
                    if (CommUtils.isBlank(batch.jobName)) batch.jobName = '2way監視バッチ';
                    if (!CommUtils.isBlank(batch.label)) batchStatusLst.add(batch);
                }
            } catch (Exception e) {
                throw e;
            }
        }
        // 監視バッチ関連の監視、チェック、起動、停止

    }
    // 監視バッチ関連の処理機能
    public class SyncWatchBatch {
        private BatchStatusInfo batch;
        public SyncWatchBatch(BatchStatusInfo pBatch) {
            batch = pBatch;
        }
        // 監視スケジールは停止処理
        public boolean isWatchRuning() {
            // 定義中のスケジール
            List < CronTrigger > cronTriggerLst = getScheduleList();
            if (cronTriggerLst.size() > 0) return true;
            return false;
        }
        // 監視スケジールは定義開始
        public list < id > startWatchBatch() {

            // 毎日定期実施のスケジールを定義する
            DateTime nwoDt = DateTime.now().addMinutes(1);
            String timeStr = nwoDt.format('yyyyMMddHHmmss');
            String hh = timeStr.substring(8, 10);
            String ms = timeStr.substring(10, 12);
            SyncStatusManagerWatchBatch bppbs = new SyncStatusManagerWatchBatch();
            String jobName = batch.jobName + timeStr + '|' + String.valueof(Crypto.getRandomLong());
            // 毎日の定時からスケジールを起動する
            String schs = '0 ' + ms + ' ' + hh + ' ? * 1,2,3,4,5,6,7';
            Id jobId2 = system.schedule(jobName, schs, bppbs);
			return new List<Id>{jobId2};
        }
        // バッチ名固定が必要
        public void stopWatchBatch() {
            // 定義中のスケジール
            List < CronTrigger > crons = getScheduleList();
            for (CronTrigger cron: crons) {
                try {
                    System.abortJob(cron.Id);
                } catch (Exception e) {}
            }
            // 使っているApexから中止処理を行う
            set<string> targetClassNmSet = new set<String>{'SyncStatusManagerWatchBatch'};
            List<AsyncApexJob> apexJobs = [Select Id From AsyncApexJob Where ApexClass.Name = :targetClassNmSet  and ( Status = 'Queued' or Status = 'Processing' or Status = 'Preparing' or Status = 'Holding')];  
            for (AsyncApexJob apexJob: apexJobs) {
                try {
                    System.abortJob(apexJob.Id);
                } catch (Exception e) {}
            }
        }
        // 監視バッチスケジール存在チェック
        private list < CronTrigger > getScheduleList() {
            String jobName = batch.jobName + '%';
            String childJobNm = 'SyncStatusManagerWatchBatch%';
            List < CronTrigger > cronTriggerLst = [SELECT Id, CronJobDetailId, State FROM CronTrigger
                WHERE State !=: 'DELETED'
                And(CronJobDetail.Name like: childJobNm or CronJobDetail.Name like: jobName)
            ];
            return cronTriggerLst;
        }

    }
    public void init() {
        // batch status init
        batChkAndRestore = new BatchChkAndRestore();
        // 2018/05/22 連携監視/復旧機能(2wayバッチ状態チェック、バッチ復旧、釣銭機復旧) by zy BEGIN
        initChangePrint();
        // 2018/05/22 連携監視/復旧機能(2wayバッチ状態チェック、バッチ復旧、釣銭機復旧) by zy END
    }
     // 2018/05/22 連携監視/復旧機能(2wayバッチ状態チェック、バッチ復旧、釣銭機復旧) by zy BEGIN
	// 店舗リスト
	public List<SelectOption> branchShopLst{get; private set;}
	// 印刷メーセッジリスト
	public list<PrintStatusInfo> PrintStatusLst{get; private set;}
	// 
	public String ipMapJson{get;set;}
	// 印刷メーセッジ
	public class PrintStatusInfo {
		public String printConflgName{get;set;}		// 釣銭機バッチ名
		public String printConflgIp{get;set;}		// 釣銭機IP
		public String printConflgStatus{get;set;}	// 釣銭機状態
		public String printConflgCon{get;set;}		// 釣銭機url
		public PrintStatusInfo(String nameStr,String ipStr,String con){
			printConflgName = nameStr;
			printConflgIp = ipStr;
			printConflgCon = con;
		}
	}
	// 2018/04/19 zyz END
    public String branchShopNm{get;set;}
    // 店铺刷新
    public void refreshBranchShopInfo(){
    	refreshPrintInfo();
    }
    /// 多店舗初期化
    private void setInitBranShopLst() {
    	UserUtil.UserShopInfo userInf = UserUtil.CurrentUserInfo;
    	//branchShopNm = CommUtils.nullToBlank(UserUtil.CurrentUser.ShopCode__c);
		// 2015/09/01 多店舗機能対応 BEGIN
        branchShopLst = ShopInfoUtil.getBranchShopLst(userInf.shops);
        List<SelectOption> selectOpts = new List<SelectOption>();
        branchShopNm = '';
        if (!branchShopLst.isEmpty()) {
        	// 顧客に設定する支店で初期値に設定する[2013/06/30]
        	String locShopCode = UserUtil.CurrentUser.ShopCode__c;
        	for (SelectOption s : branchShopLst) {
        		String spcd = s.getValue();
        		ChangeMachineHelp help = new ChangeMachineHelp(spcd,true);
        		map<String,Object> changeIpMap = help.getDeviceMap();
        		if (!changeIpMap.isEmpty()) {
        			if (CommUtils.isBlank(branchShopNm)) branchShopNm = spcd;
        			selectOpts.add(s);
        		}
        	}
        }
        branchShopLst = selectOpts;
    }
    // 印刷設備初期化
    private void initChangePrint(){
    	// 多店舗処理
    	setInitBranShopLst();
    	// リアル印刷リスト
    	refreshPrintInfo();
	}
	// リアル印刷リスト
	private void refreshPrintInfo(){
		// 定義したバッチ情報を格納リスト
		PrintStatusLst = new list<PrintStatusInfo>();
		// Document定義ファイル名
   		String xmlDocName = 'ChangeMachineConfig';
   		Map<String,Object> ipChangeMap = new Map<String,Object>();
	    try{
			ChangeMachineHelp help = new ChangeMachineHelp(branchShopNm,true);
		    set<String> printSet = new set<String>();
			set<String> printUrlSet = new set<String>();
		    map<String,Object> changeIpMap = help.getDeviceMap();
			for(String key : changeIpMap.keySet()){
				Object obj = changeIpMap.get(key);
				String printNM = (String)( (Map<String, Object>)obj ).get( 'name' );
				String printUrl = (String)( (Map<String, Object>)obj ).get( 'url' );
				if (printSet.contains(printNM) || printUrlSet.contains(printUrl)) continue;
				String printCon = (String)( (Map<String, Object>)obj ).get( 'connect' );
				printSet.add(printNM);
				printUrlSet.add(printUrl);
				PrintStatusInfo print = new PrintStatusInfo(printNM, printUrl,printCon);
				PrintStatusLst.add(print);	
				ipChangeMap.put(printUrl,obj);
			}
		    ipMapJson = JSON.serialize(ipChangeMap);
	    } catch(Exception e){
	    	system.debug(logginglevel.info,e.getStackTraceString());
	    	//throw e;
	    } 
	}
	@remoteAction
	public static void savePrintLodToDb(String action){
		// 2017/09/11 印刷リスト機能　by　zy　BEGIN
		String curLog = system.now().format('yyyy-MM-dd HH:mm:ss SSS') + '*************復旧画面BEGIN******************\n';
		// 2017/09/11 印刷リスト機能　by　zy　END
		User u = UserUtil.CurrentUser;
		curLog += 'ユーザ：' + u.name + '（' + u.id +'）\n';
		curLog += action + '\n';
		// 2017/09/11 印刷リスト機能　by　zy　BEGIN
		curLog += system.now().format('yyyy-MM-dd HH:mm:ss SSS') + '*************復旧画面END  ******************\n';
		// 2017/09/11 印刷リスト機能　by　zy　END
		CommLogUtils.saveLogToDb(curLog,CommLogUtils.LogType.POS);
	}
	// 2018/05/22 連携監視/復旧機能(2wayバッチ状態チェック、バッチ復旧、釣銭機復旧) by zy END
}