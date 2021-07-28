global with sharing class SyncStatusManagerUploadCtrl {
	// ****************************************************
	// 店舗情報リスト[共通変数]
	// ****************************************************
	public List<SelectOption> branchShopLst{get; private set;}
    private void initBranShopLst() {
		// 店舗リスト
        branchShopLst = ShopInfoUtil.getBranchShopLst();
        // 処理対象
	}
	
	//public UserUtil.UserShopInfo userInf;
	// XML UPLOAD INIT
	public void init(){
		// 店舗リスト情報
		initBranShopLst();
		//userInf = UserUtil.CurrentUserInfo;
		//filehand = new FileUploadBase();
		// batch status init
		SyncStatusManagerCtrl.BatchChkAndRestore statusCtrl = new SyncStatusManagerCtrl.BatchChkAndRestore();
		// バッチ状態により、XMLアップロード有効・無効を切替制御
		//xmlUpd = new XmlUpload();
		//list<BatchStatusInfo> batchStatusLst
		//for (SyncStatusManagerCtrl.BatchStatusInfo batch : statusCtrl.batchStatusLst) {
		//	if ((batch.jobTypeStr == SyncStatusManagerCtrl.JOBTYPE.TLIMP.name() || batch.jobTypeStr == SyncStatusManagerCtrl.JOBTYPE.TAIMP.name()) && batch.statusOn) {
		//		xmlUpd.addProcessType(new SelectOption(batch.jobTypeStr, batch.label));
		//	}
		//}
		// ******************************************************
		// 指定期間の未連携、連携エラーの連携結果のXMLは再度取込実施処理
		// ******************************************************
		begDtInput = new BookingTimeTable__c(Checkinday__c = Date.today().addDays(-31));
		endDtInput = new BookingTimeTable__c(Checkinday__c = Date.today());
		retryTargetLst = new list<SelectOption>();
		// 店舗コード初期値を設定する
		retryShopCd = UserUtil.CurrentUser.ShopCode__c;
		for (SyncStatusManagerCtrl.BatchStatusInfo batch : statusCtrl.batchStatusLst) {
			if (batch.statusOn) {
				if ( batch.jobTypeStr == SyncStatusManagerCtrl.JOBTYPE.TLIMP.name() || 
				     batch.jobTypeStr == SyncStatusManagerCtrl.JOBTYPE.JRIMP.name() || 
					 batch.jobTypeStr == SyncStatusManagerCtrl.JOBTYPE.TAIMP.name()) {
					 //batch.jobTypeStr == SyncStatusManagerCtrl.JOBTYPE.TLSTOCK.name() || 
					 //batch.jobTypeStr == SyncStatusManagerCtrl.JOBTYPE.TASTOCK.name())
					retryTargetLst.add(new SelectOption(batch.jobTypeStr, batch.label));
				}
			}
		}
		
	}
	// ******************************************************
	// XMLアップロード処理関連
	// ******************************************************
	/*
	public class XmlUpload {
		public Boolean isCanUpload{get{
			return !processingTypeLst.isEmpty();
		}}
		//private UserUtil.UserShopInfo userInf;
		public XmlUpload() {
			xmlUpdShopCode = UserUtil.CurrentUser.ShopCode__c;
			processingTypeLst = new List<SelectOption>();
		}
		// 予約取り込み種別
		public String processingType{get;set;}
		public List<SelectOption> processingTypeLst{get; private set;}
		public String xmlUpdShopCode{get; set;}
		public void addProcessType(SelectOption opt) {
			processingTypeLst.add(opt);
		}
	}
	//public public List<SelectOption> branchShopLst{get; private set;}
	public XmlUpload xmlUpd{get; private set;}
	public FileUploadBase filehand{get; private set;}
	public UploadResult updRs{get; private set;}
	public void uploadLeadXml(){
		updRs = new UploadResult();
		try{
			Blob body = filehand.getFileBody();	
			if(xmlUpd.processingType == SyncStatusManagerCtrl.JOBTYPE.TLIMP.name()){
				TL_LeadInfoSync leadInfoToSfCtrl = new TL_LeadInfoSync();
				TL_ParseXmlToBookingInfoCtrl parseXmlCtrl = new TL_ParseXmlToBookingInfoCtrl();
				TL_LeadInfoSync.BI_TL_SyncInfo bookingInfo = parseXmlCtrl.parse(Body.toString(),xmlUpd.xmlUpdShopCode);							
				// ログ：取込詳細情報を取得する	
				TL_LeadInfoSync.BI_TL_SyncResult result = leadInfoToSfCtrl.upsertTL2LeadInfo(bookingInfo,xmlUpd.xmlUpdShopCode);
				if(result.result == TL_LeadInfoSync.BI_TL_Result.OK){ 		
					updRs.message = '予約取込正常に完了しました。';
					updRs.sfdcId = result.sfdcId;
					updRs.isSucess = true;
				} else{
					updRs.message += '予約取込エラーが発生しました。(' + result.message + ')';
				}	
			} else if(xmlUpd.processingType == SyncStatusManagerCtrl.JOBTYPE.TAIMP.name()){
				TA_LeadInfoSync leadInfoToSfCtrl = new TA_LeadInfoSync();
				TA_ParseXmlToBookingInfoCtrl parseXmlCtrl = new TA_ParseXmlToBookingInfoCtrl();	
				TA_LeadInfoSync.BI_TA_SyncInfo bookingInfo = parseXmlCtrl.parse(Body.toString(),xmlUpd.xmlUpdShopCode);										
				// ログ：取込詳細情報を取得する	
				TA_LeadInfoSync.BI_TA_SyncResult result = leadInfoToSfCtrl.upsertTALeadInfo(bookingInfo,xmlUpd.xmlUpdShopCode);
				updRs.message = '予約取込処理終了、';
				if(result.result == TA_LeadInfoSync.BI_TA_Result.OK){ 		
					updRs.message = '予約取込正常に完了しました。';
					updRs.sfdcId = result.sfdcId;
					updRs.isSucess = true;
				} else{
					updRs.message += '予約取込エラーが発生しました。(' + result.message + ')';
				}
			}
		}catch(Exception e){
			updRs.message = e.getMessage();
		} finally {
			filehand.clear();
		}
	}
	public Class UploadResult {
		public UploadResult() {
			isSucess = false;
			message = '';
		}
		public boolean isShowResult{get{return !CommUtils.isBlank(message);}}
		public id sfdcId{get;private set;}
		public boolean isSucess{get;private set;}
		public String message{get;private set;}
	}
	*/
	// ******************************************************
	// 指定期間の未連携、連携エラーの連携結果のXMLは再度取込実施処理
	// ******************************************************
	public BookingTimeTable__c begDtInput{get; private set;}
	public BookingTimeTable__c endDtInput{get; private set;}
	// 店舗情報リスト
	public List<SelectOption> retryTargetLst{get; private set;}
	public String retryShopCd{get; set;}
	public String retryProType{get;set;}
	// 復旧関連定数
	
	// 一覧対象情報格納クラス
	global Class SyncResultInfo {
		public Id sfid{get;private set;}			//該当データの連携結果のID
		public String errMsg{get;private set;}		//エラーメッセージ情報（最大２５５文字列制御）
		public String fileName{get;private set;}	//ファイル名
		public String lastSyncDt{get;private set;}	//最終連携時間
		public String createdDt{get;private set;}	//作成時間
		public String status{get;private set;}
		public SyncResultInfo(){}
		public SyncResultInfo(CooperationResult__c c) {
			sfid = c.id;
			errMsg = CommUtils.nullToBlank(c.ErrorContent__c);
			List<Attachment> impXmls = c.Attachments;
			fileName = impXmls[0].Name;
			lastSyncDt = c.lastModifiedDate.format();
			createdDt = c.CreatedDate.format();
			status = CommUtils.nullToBlank(c.Status__c);
		}
	}
    // [連携NGのXMLファイルをリストに表示する、表示対象は再連携/連携対象外に変更可能]
    @ReadOnly @remoteAction
	global static List<SyncResultInfo> getLeadRetryViewInfo(String spcd, String strBegDt, String strEndDt, String processType) {
		// 指定期間から連携エラー情報を取得する
		String coopFunType = CommConst.COOP_FUNTYPE_LEADIMP;
		String coopSynResult = CommConst.COOP_FUNTYPE_LEADIMP_NG;
		Date begDt = CommUtils.stringToDate(strBegDt);
		Date endDt = CommUtils.stringToDate(strEndDt);
		// 処理種別:TL/TA
		String processingTypeKey = CommConst.SYNC_PROCESS_TYPE_TL;
		if (processType == SyncStatusManagerCtrl.JOBTYPE.TAIMP.name()) processingTypeKey = CommConst.SYNC_PROCESS_TYPE_TA;
		if (processType == SyncStatusManagerCtrl.JOBTYPE.JRIMP.name()) processingTypeKey = CommConst.SYNC_PROCESS_TYPE_JR;
		
		String strQuery = 'Select Id,lastModifiedDate,CreatedDate,ErrorContent__c,ProcessingType__c,Status__c,ParentRef__c,';
		strQuery += ' (Select Name From Attachments order by CreatedDate desc limit 1) ';
		strQuery += ' from CooperationResult__c ';
		strQuery += ' where FunctionType__c=:coopFunType And ParentRef__c != Null ';
		// ステータス:予約取込NG
		strQuery += ' And Status__c =:coopSynResult ';
		strQuery += ' And DAY_ONLY(convertTimezone(LastModifiedDate)) >= :begDt And DAY_ONLY(convertTimezone(LastModifiedDate)) <= :endDt';
		// 処理種別:TL/TA
		strQuery += ' And ProcessingType__c = :processingTypeKey';
		// 店舗コード
		if (!CommUtils.isBlank(spcd)) strQuery += ' And ShopCode__c = :spcd ';
		// 作成順で起動する
		strQuery += ' Order By CreatedDate asc ';
System.debug(loggingLevel.info, 'strQuery='+strQuery);
		// 取り込みエラー対象一覧を表示する
		List<SyncResultInfo> jsonDataSrc = new List<SyncResultInfo>();
		for (CooperationResult__c cooper : Database.query(strQuery)) {
			List<Attachment> impXmls = cooper.Attachments;
			if (impXmls.isEmpty()) continue;
			jsonDataSrc.add(new SyncResultInfo(cooper));
		}
		return jsonDataSrc;
	}
	// 復旧処理を行う
	// Param:	updCooperIds:処理対象のIDS
	@remoteAction
	global static void syncRestoreStatus(String[] updCooperIds) {
		// IDにより、情報ステータスを更新する
		List<String> cooperIds = updCooperIds;
		List<CooperationResult__c> updLst = new List<CooperationResult__c>();
		for (CooperationResult__c coop : [select id, Status__c from CooperationResult__c where id in :cooperIds ]) {
			// 予約取込待ち
			coop.Status__c = CommConst.COOP_FUNTYPE_LEADIMP_WAIT;
			updLst.add(coop);
		}
		if (!updLst.isEmpty()) update updLst;
	}
	// 指定の予約IDSにより、最新の復旧状況を取得する
	@remoteAction
	global static RestoreResultInfo refreshRestoreStatus(String[] updCooperIds) {
		// IDにより、情報ステータスを更新する
		List<String> cooperIds = updCooperIds;
		// 何件完了、何件待ち、何件NG
		RestoreResultInfo rs = new RestoreResultInfo();
		rs.orgLst = cooperIds;
		// 最新処理ステータスを取得する
		for (CooperationResult__c coop : [select id, Status__c from CooperationResult__c where id in :cooperIds ]) {
			String status = coop.Status__c;
			// WAIT
			if (status == CommConst.COOP_FUNTYPE_LEADIMP_WAIT) {
				rs.waitLst.add(coop.Id);
			} 
			// OK
			else if (status == CommConst.COOP_FUNTYPE_LEADIMP_OK) {
				rs.okLst.add(coop.Id);
			}
			// NG
			else if (status == CommConst.COOP_FUNTYPE_LEADIMP_NG) {
				rs.ngLst.add(coop.Id);
			}
		}
		rs.generalMsg();
		return rs;
	}
	
	global class RestoreResultInfo {
		public RestoreResultInfo() {
			okLst = new list<Id>();
			waitLst = new list<Id>();
			ngLst = new list<Id>();
			orgLst = new list<Id>();
		}
		public list<Id> okLst{get;set;}
		public list<Id> waitLst{get;set;}
		public list<Id> ngLst{get;set;}
		public list<Id> orgLst{get;set;}
		public String statusMsg{get;set;}
		public void generalMsg() {
			statusMsg = '';
			statusMsg += '成功:'+okLst.size()+'件 ';
			statusMsg += '失敗:'+ngLst.size()+'件 ';
			statusMsg += '処理待ち:'+waitLst.size()+'件 ';
		}
	}
}