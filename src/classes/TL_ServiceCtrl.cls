/**
* 2way連携： ApexCalout機能共通クラス
* TL-リンカーン機能連携
* 2015/10/01 INIT
* 2016/07/29 ログ出力機能追加
**/
public with sharing class TL_ServiceCtrl {
    // ログ出力機能
    private CommLogUtils mLogUtils{get; private set;}
	//private final TL_ServiceConfigHelp help;
	private TL_ServiceConfigHelp.APPCONFIG appConfig;
	//private TL_ServiceConfigHelp.ERRCONFIG errConfig;
	private final integer COMMON_TL_CALL_TIME_OUT_VALUE = 120000;
	// Service Key
	public static final String SERVICE_KEY = 'TL';
	// 2016/07/29 ログ出力機能追加 BEGIN
	public TL_ServiceCtrl() {mLogUtils = new CommLogUtils('TL_ServiceCtrl',true);mLogUtils.write_method_start('--------API通信-------');} 
	public TL_ServiceCtrl(CommLogUtils pmLogUtils) {mLogUtils = pmLogUtils;}
	// 2016/07/29 ログ出力機能追加 END
	// 01.部屋タイプマスタ検索(ネット)API
	public TL_NetRoomTypeMasterSearchService.rmTypeMstSearchForNetResponse callNetRoomTypeMasterSearchService(String shopCd, TL_NetRoomTypeMasterSearchService.extractionCondition pExtractionCondition) {
mLogUtils.write_log('------rmTypeMstSearchForNetRequest(部屋タイプマスタ検索(ネット販売)_リクエス)------');
mLogUtils.write_log('抽出方法:'+pExtractionCondition.extractionProcedureCode);
mLogUtils.write_log('販売先コード:'+pExtractionCondition.agtCode);
mLogUtils.write_log('ネット販売先室タイプコード:'+pExtractionCondition.netAgtRmTypeCode);
		appConfig = TL_ServiceConfigHelp.getAppConfig(shopCd);
		
		TL_NetRoomTypeMasterSearchService.commonRequest commonRequest
		   = new TL_NetRoomTypeMasterSearchService.commonRequest();
		commonRequest.systemId = appConfig.systemId;
		commonRequest.pmsUserId = appConfig.userId;
		commonRequest.pmsPassword = appConfig.password;
		
		TL_NetRoomTypeMasterSearchService.extractionCondition extractionCondition = pExtractionCondition;
		
		TL_NetRoomTypeMasterSearchService.rmTypeMstSearchForNetRequest req
		   = new TL_NetRoomTypeMasterSearchService.rmTypeMstSearchForNetRequest();
		req.commonRequest = commonRequest;
		req.extractionCondition = extractionCondition;
		TL_NetRoomTypeMasterSearchService.NetRoomTypeMasterSearchPort port = 
		   new TL_NetRoomTypeMasterSearchService.NetRoomTypeMasterSearchPort(TL_ServiceConfigHelp.getCommConfig().strServiceUrl);
		// 2015/10/12 Timeout Limit Setup Begin
		port.timeout_x = COMMON_TL_CALL_TIME_OUT_VALUE;
		// 2015/10/12 Timeout Limit Setup END
		// 2016/05/09 実施異常CATCH BEGIN
		TL_NetRoomTypeMasterSearchService.rmTypeMstSearchForNetResponse  rep = null;
		try {
			rep = port.execute(req);
		} catch (Exception e) {
			TL_NetRoomTypeMasterSearchService.commonResponse commonResponse = new TL_NetRoomTypeMasterSearchService.commonResponse();
			commonResponse.isSuccess = false;
			commonResponse.failureReason = 'TL_NetRoomTypeMasterSearchService Exception';
			commonResponse.errorDescription = CommLogUtils.removeOverLogString(e.getMessage(),255);
			rep = new TL_NetRoomTypeMasterSearchService.rmTypeMstSearchForNetResponse();
			rep.commonResponse = commonResponse;
		}
		// 2016/05/09 実施異常CATCH END
		// 処理結果がエラーの場合
		if (!rep.commonResponse.isSuccess) return rep;
		// ----------------------------------------
		// TL側の室タイプ→SF側の部屋タイプコード変換設定を行う
		// ----------------------------------------
		// 室タイプ
		/* 2017/11/23 在庫連携、SFの1部屋タイプからTLの複数室タイプコード在庫連携、SFの1部屋タイプコードからTLの複数室タイプ名を対応できるように改善をできるように改善 BEGIN
		map<string, string> tlRmTypeCdToSfRmTypeCdMap = new map<string,string>();
		if (rep.rmTypeList != null) {
			for (TL_NetRoomTypeMasterSearchService.rmType rg : rep.rmTypeList) {
//System.debug(loggingLevel.INFO, rg.rmTypeCode + '=' + rg.rmTypeName + '=' + rg.tlDataOutPutRmTypeCode);
				if (!CommUtils.isBlank(rg.tlDataOutPutRmTypeCode)) {
					// 順番注意が必要
					tlRmTypeCdToSfRmTypeCdMap.put(rg.rmTypeCode, rg.tlDataOutPutRmTypeCode);
					rg.rmTypeCode = rg.tlDataOutPutRmTypeCode;
				}
			}
		}
		// ネット室タイプグルーフ
		if (rep.netRmTypeGroupList != null) {
			for (TL_NetRoomTypeMasterSearchService.netRmTypeGroup rg : rep.netRmTypeGroupList) {
				//tmTypeMap.put(rg.rmTypeCode, )
				//System.debug(loggingLevel.INFO, rg.rmTypeCode + '=' + rg.netRmTypeGroupName);
				if (tlRmTypeCdToSfRmTypeCdMap.containsKey(rg.rmTypeCode)) {
					rg.rmTypeCode = tlRmTypeCdToSfRmTypeCdMap.get(rg.rmTypeCode);
				}
			}
		}
		if (rep.netAgtRmTypeList != null) {
			// ネット販売先室タイプ
			for (TL_NetRoomTypeMasterSearchService.netAgtRmType rg : rep.netAgtRmTypeList) {
				//tmTypeMap.put(rg.rmTypeCode, )
				//System.debug(loggingLevel.INFO, rg.rmTypeCode + '=' + rg.netRmTypeGroupName);
				if (tlRmTypeCdToSfRmTypeCdMap.containsKey(rg.rmTypeCode)) {
					rg.rmTypeCode = tlRmTypeCdToSfRmTypeCdMap.get(rg.rmTypeCode);
				}
			}
		}
		2017/11/23 在庫連携、SFの1部屋タイプからTLの複数室タイプコード在庫連携、SFの1部屋タイプコードからTLの複数室タイプ名を対応できるように改善をできるように改善 END */
		// 結果：OK
		return rep;
	}
	// 02.在庫状況照会(ネット)API
	public TL_NetStockSearchService.stockSearchForNetResponse callNetStockSearchService(String shopCd, TL_NetStockSearchService.extractionCondition pExtractionCondition) {
mLogUtils.write_log('------stockSearchForNetRequest(在庫状況照会(ネット販売)_リクエスト )------');
mLogUtils.write_log('------extractionCondition(抽出条件)------');
mLogUtils.write_log('抽出方法:'+pExtractionCondition.extractionProcedure);
mLogUtils.write_log('更新日時:'+pExtractionCondition.updateDate);
mLogUtils.write_log('照会期間FROM:'+pExtractionCondition.searchDurationFrom);
mLogUtils.write_log('照会期間TO:'+pExtractionCondition.searchDurationTo);		
mLogUtils.write_log('ネット室タイプグループコード:'+pExtractionCondition.netRmTypeGroupCode);
mLogUtils.write_log('販売先コード:'+pExtractionCondition.agtCode);
mLogUtils.write_log('ネット販売先室タイプコード:'+pExtractionCondition.netAgtRmTypeCode);
mLogUtils.write_log('PMS用出力名:'+pExtractionCondition.PMSOutputRmTypeCode);					
//System.debug(loggingLevel.INFO, 'METHOD callNetStockSearchService START:');
		appConfig = TL_ServiceConfigHelp.getAppConfig(shopCd);
//System.debug(loggingLevel.INFO, 'appConfig:' + appConfig);	
		TL_NetStockSearchService.commonRequest commonRequest
		   = new TL_NetStockSearchService.commonRequest();
		commonRequest.systemId = appConfig.systemId;
		commonRequest.pmsUserId = appConfig.userId;
		commonRequest.pmsPassword = appConfig.password;
		
		TL_NetStockSearchService.extractionCondition extractionCondition = pExtractionCondition;
		
		TL_NetStockSearchService.stockSearchForNetRequest req
		   = new TL_NetStockSearchService.stockSearchForNetRequest();
		req.commonRequest = commonRequest;
		req.extractionCondition = extractionCondition;
		
		TL_NetStockSearchService.NetStockSearchPort port = 
		   new TL_NetStockSearchService.NetStockSearchPort(TL_ServiceConfigHelp.getCommConfig().strServiceUrl);
		// 2015/10/12 Timeout Limit Setup Begin
		port.timeout_x = COMMON_TL_CALL_TIME_OUT_VALUE;
		// 2015/10/12 Timeout Limit Setup END
		// 2016/05/09 実施異常CATCH BEGIN
		TL_NetStockSearchService.stockSearchForNetResponse  rep = null;
		try {
			rep = port.execute(req);
		} catch (Exception e) {
			TL_NetStockSearchService.commonResponse commonResponse = new TL_NetStockSearchService.commonResponse();
			commonResponse.isSuccess = false;
			commonResponse.failureReason = 'TL_NetStockSearchService Exception';
			commonResponse.errorDescription = CommLogUtils.removeOverLogString(e.getMessage(),255);
			rep = new TL_NetStockSearchService.stockSearchForNetResponse();
			rep.commonResponse = commonResponse;
		}
		// 2016/05/09 実施異常CATCH END
/*
		System.debug(loggingLevel.INFO, rep.commonResponse.isSuccess);
		if (rep.commonResponse.isSuccess) {
			rep.netRmTypeGroupAndDailyStockStatusList = rep.netRmTypeGroupAndDailyStockStatusList == null 
								? new TL_NetStockSearchService.netRmTypeGroupAndDailyStockStatus[0] 
								: rep.netRmTypeGroupAndDailyStockStatusList;
			System.debug(loggingLevel.INFO, rep.netRmTypeGroupAndDailyStockStatusList);
			for (TL_NetStockSearchService.netRmTypeGroupAndDailyStockStatus status : rep.netRmTypeGroupAndDailyStockStatusList) {
				System.debug(loggingLevel.INFO, 'status.salesCount='+status.salesCount);
				System.debug(loggingLevel.INFO, 'status.remainingCount='+status.remainingCount);
				System.debug(loggingLevel.INFO, 'status.salesStatus='+status.salesStatus);
			}
		}
*/
System.debug(loggingLevel.INFO, 'METHOD callNetStockSearchService END:');
		// 結果：OK
		return rep;
	}
	/*
	// 02.在庫状況照会(ネット)API
	public void callNetStockSearchService_Test(RoomTypeInventory.TL_netAgtRoomInfo info,String branchShopNm) {
		 
		TL_NetStockAdjustmentService.commonRequest commonRequest
		   = new TL_NetStockAdjustmentService.commonRequest();
		commonRequest.systemId = 'PFg69aA0';
		commonRequest.pmsUserId = 'P6820207';
		commonRequest.pmsPassword = 'mj2UOAL.t3';
		List<TL_NetStockAdjustmentService.adjustmentTarget> adjustmentTargets = new List<TL_NetStockAdjustmentService.adjustmentTarget>();
		for(Date d : info.dates){
			TL_NetStockAdjustmentService.adjustmentTarget adjustmentTarget=
			new TL_NetStockAdjustmentService.adjustmentTarget();
			adjustmentTarget.adjustmentProcedureCode = '1';
			adjustmentTarget.netRmTypeGroupCode = branchShopNm;
			adjustmentTarget.salesStatus = '3';
			
			Date conStartDate = d;
			//adjustmentTarget.remainingCount = String.valueOf(sumDayMaxRooms) ;
			adjustmentTargets.add(adjustmentTarget);
		}
		
		TL_NetStockAdjustmentService.stockAdjustmentForNetRequest req= 
			new TL_NetStockAdjustmentService.stockAdjustmentForNetRequest();
		req.commonRequest = commonRequest;
		//req.adjustmentTarget = adjustmentTarget;
		
		TL_NetStockAdjustmentService.NetStockAdjustmentPort port=
			new TL_NetStockAdjustmentService.NetStockAdjustmentPort();
		// 実行
		TL_NetStockAdjustmentService.stockAdjustmentForNetResponse rep = port.execute(req);
		System.debug(LoggingLevel.INFO, rep);
		// 結果：OK
	}*/
	
	// 03.在庫調整(ネット)API
	public TL_NetStockAdjustmentService.stockAdjustmentForNetResponse callNetStockAdjustmentService(String shopCd, TL_NetStockAdjustmentService.adjustmentTarget pAdjustmentTarget) {
mLogUtils.write_log('------stockAdjustmentForNetRequest(在庫調整(ネット販売)_リクエスト)------');
mLogUtils.write_log('------adjustmentTarget(調整対象)------');
mLogUtils.write_log('調整方法:'+pAdjustmentTarget.adjustmentProcedureCode);
mLogUtils.write_log('ネット室タイプグループコード:'+pAdjustmentTarget.netRmTypeGroupCode);
mLogUtils.write_log('販売先コード:'+pAdjustmentTarget.agtCode);	
mLogUtils.write_log('ネット販売先室タイプコード:'+pAdjustmentTarget.netAgtRmTypeCode);	
mLogUtils.write_log('調整日付:'+pAdjustmentTarget.adjustmentDate);	
mLogUtils.write_log('残室数:'+pAdjustmentTarget.remainingCount);
mLogUtils.write_log('販売状態:'+pAdjustmentTarget.salesStatus);		
mLogUtils.write_log('要求ID:'+pAdjustmentTarget.requestId);	
		appConfig = TL_ServiceConfigHelp.getAppConfig(shopCd);
		
		TL_NetStockAdjustmentService.commonRequest commonRequest
		   = new TL_NetStockAdjustmentService.commonRequest();
		commonRequest.systemId = appConfig.systemId;
		commonRequest.pmsUserId = appConfig.userId;
		commonRequest.pmsPassword = appConfig.password;
		// リクエスト条件		
		TL_NetStockAdjustmentService.adjustmentTarget adjustmentTarget = pAdjustmentTarget;
		// リクエスト条件はBINDする
		TL_NetStockAdjustmentService.stockAdjustmentForNetRequest req= 
			new TL_NetStockAdjustmentService.stockAdjustmentForNetRequest();
		req.commonRequest = commonRequest;
		req.adjustmentTarget = adjustmentTarget;
		
		TL_NetStockAdjustmentService.NetStockAdjustmentPort port=
			new TL_NetStockAdjustmentService.NetStockAdjustmentPort(TL_ServiceConfigHelp.getCommConfig().strServiceUrl);
		// 2015/10/12 Timeout Limit Setup Begin
		port.timeout_x = COMMON_TL_CALL_TIME_OUT_VALUE;
		// 2015/10/12 Timeout Limit Setup END
		// 実行
		// 2016/05/09 実施異常CATCH BEGIN
		TL_NetStockAdjustmentService.stockAdjustmentForNetResponse rep = null;
		try {
			rep = port.execute(req);
		} catch (Exception e) {
			TL_NetStockAdjustmentService.commonResponse commonResponse = new TL_NetStockAdjustmentService.commonResponse();
			commonResponse.isSuccess = false;
			commonResponse.failureReason = 'TL_NetStockAdjustmentService Exception';
			commonResponse.errorDescription = CommLogUtils.removeOverLogString(e.getMessage(),255);
			rep = new TL_NetStockAdjustmentService.stockAdjustmentForNetResponse();
			rep.commonResponse = commonResponse;
		}
		// 2016/05/09 実施異常CATCH END
//System.debug(LoggingLevel.INFO, rep);
		// 結果：OK
		return rep;
	}
	/*
	public void TL2NetPlanMasterInputService(){
		TL_NetPlanMasterSearchService.commonRequest commonRequest
		   = new TL_NetPlanMasterSearchService.commonRequest();
		commonRequest.systemId = 'PFg69aA0';
		commonRequest.pmsUserId = 'P6820207';
		commonRequest.pmsPassword = 'mj2UOAL.t3';
		
		TL_NetPlanMasterSearchService.extractionCondition extractionCondition
		   = new TL_NetPlanMasterSearchService.extractionCondition();
		extractionCondition.extractionProcedureCode = '0';
		
		TL_NetPlanMasterSearchService.planMstSearchForNetRequest req
		   = new TL_NetPlanMasterSearchService.planMstSearchForNetRequest();
		req.commonRequest = commonRequest;
		req.extractionCondition = extractionCondition;
		TL_NetPlanMasterSearchService.NetPlanMasterSearchPort port = 
		   new TL_NetPlanMasterSearchService.NetPlanMasterSearchPort();
		TL_NetPlanMasterSearchService.planMstSearchForNetResponse  rep = port.execute(req);
		List<String> planLst = new List<String>();
		Map<String,Plan__c> planMap = new Map<String,Plan__c>();
		for (TL_NetPlanMasterSearchService.planGroup planGroup : rep.planGroupList) {
			Plan__c p = new Plan__c(Name = planGroup.planGroupName,PackageCode__c = planGroup.planGroupCode);
			planLst.add(p.PackageCode__c);
			planMap.put(planGroup.planGroupCode,p);
		}
		for (TL_NetPlanMasterSearchService.plan plan : rep.planList) {
			Account  agt = [Select Id from Account where SalesOfficeCode__c = :plan.agtCode];
			Plan__c p = new Plan__c(Name = plan.planName,
									PackageCode__c = plan.planCode,
									client__c = agt.Id,
									Roomtype__c = plan.netAgtRmTypeCode);
			planLst.add(p.PackageCode__c);
			planMap.put(plan.planCode,p);
		}
		for(Plan__c p : [select PackageCode__c from Plan__c where PackageCode__c =:planLst]){
			planMap.remove(p.PackageCode__c);
		}
		List<Plan__c> updatePlanLst = new List<Plan__c>();
		for(String key : planMap.keySet()){
			updatePlanLst.add(planMap.get(key));
		}
		insert updatePlanLst;
	}*/
	// 04.プランマスタ検索(ネット)API
	public TL_NetPlanMasterSearchService.planMstSearchForNetResponse callNetPlanMasterSearchService(String shopCd, TL_NetPlanMasterSearchService.extractionCondition pExtractionCondition) {
mLogUtils.write_log('------planMstSearchForNetRequest(プランマスタ検索(ネット販売)_リクエスト)------');	
mLogUtils.write_log('------extractionCondition(抽出条件)------');	
mLogUtils.write_log('抽出方法:'+pExtractionCondition.extractionProcedureCode);	
mLogUtils.write_log('販売先コード :'+pExtractionCondition.agtCode);
mLogUtils.write_log('ネット販売先室タイプコード:'+pExtractionCondition.netAgtRmTypeCode);	
mLogUtils.write_log('プランコード :'+pExtractionCondition.planCode);	
mLogUtils.write_log('提供先コード :'+pExtractionCondition.offereeCode);	

		appConfig = TL_ServiceConfigHelp.getAppConfig(shopCd);
		
		TL_NetPlanMasterSearchService.commonRequest commonRequest
		   = new TL_NetPlanMasterSearchService.commonRequest();
		commonRequest.systemId = appConfig.systemId;
		commonRequest.pmsUserId = appConfig.userId;
		commonRequest.pmsPassword = appConfig.password;
		
		TL_NetPlanMasterSearchService.extractionCondition extractionCondition = pExtractionCondition;
		
		TL_NetPlanMasterSearchService.planMstSearchForNetRequest req
		   = new TL_NetPlanMasterSearchService.planMstSearchForNetRequest();
		req.commonRequest = commonRequest;
		req.extractionCondition = extractionCondition;
		TL_NetPlanMasterSearchService.NetPlanMasterSearchPort port = 
		   new TL_NetPlanMasterSearchService.NetPlanMasterSearchPort(TL_ServiceConfigHelp.getCommConfig().strServiceUrl);
		// 2015/10/12 Timeout Limit Setup Begin
		port.timeout_x = COMMON_TL_CALL_TIME_OUT_VALUE;
		// 2015/10/12 Timeout Limit Setup END
		// 2016/05/09 実施異常CATCH BEGIN
		TL_NetPlanMasterSearchService.planMstSearchForNetResponse  rep = null;
		try {
			rep = port.execute(req);
		} catch (Exception e) {
			TL_NetPlanMasterSearchService.commonResponse commonResponse = new TL_NetPlanMasterSearchService.commonResponse();
			commonResponse.isSuccess = false;
			commonResponse.failureReason = 'TL_NetPlanMasterSearchService Exception';
			commonResponse.errorDescription = CommLogUtils.removeOverLogString(e.getMessage(),255);
			rep = new TL_NetPlanMasterSearchService.planMstSearchForNetResponse();
			rep.commonResponse = commonResponse;
		}
		// 2016/05/09 実施異常CATCH END
		return rep;
	}

	/*
	// 05.プラン料金調整(ネット)API
	public void callNetPriceAdjustmentService() {

		TL_NetPriceAdjustmentService.commonRequest commonRequest = 
			new TL_NetPriceAdjustmentService.commonRequest();
		commonRequest.systemId = 'PFg69aA0';
		commonRequest.pmsUserId = 'P6820207';
		commonRequest.pmsPassword = 'mj2UOAL.t3';

		TL_NetPriceAdjustmentService.adjustmentTarget adjustmentTarget=
			new TL_NetPriceAdjustmentService.adjustmentTarget();
		adjustmentTarget.adjustmentProcedureCode = '1';
		adjustmentTarget.planGroupCode = '';
		adjustmentTarget.adjustmentDate='20150408';
		adjustmentTarget.salesStatus='3';
		
		TL_NetPriceAdjustmentService.priceAdjustmentForNetRequest req= 
			new TL_NetPriceAdjustmentService.priceAdjustmentForNetRequest();
		req.commonRequest = commonRequest;
		req.adjustmentTarget = adjustmentTarget;
		
		TL_NetPriceAdjustmentService.NetPriceAdjustmentPort port=
			new TL_NetPriceAdjustmentService.NetPriceAdjustmentPort(TL_ServiceConfigHelp.getCommConfig().strServiceUrl);
		// 実行
		TL_NetPriceAdjustmentService.priceAdjustmentForNetResponse rep = port.execute(req);
		System.debug(LoggingLevel.INFO, rep);
		// 結果：OK
	}*/
	
	// 06.予約出力API
	public TL_BookingInfoOutputService.bookingInfoResponse callBookingInfoOutputService(String shopCd) {
mLogUtils.write_log('------bookingInfoRequest(予約出力_リクエスト )------');
		appConfig = TL_ServiceConfigHelp.getAppConfig(shopCd);
		
		TL_BookingInfoOutputService.commonRequest commonRequest = 
			new TL_BookingInfoOutputService.commonRequest();
		commonRequest.systemId = appConfig.systemId;
		commonRequest.pmsUserId = appConfig.userId;
		commonRequest.pmsPassword = appConfig.password;

		TL_BookingInfoOutputService.outputTarget outputTarget = 
			new TL_BookingInfoOutputService.outputTarget();
		outputTarget.systemCode = '1';
		//outputTarget.agtTypeCode = '1';

mLogUtils.write_log('------outputTarget(出力対象)------');
mLogUtils.write_log('起動元システム区分:'+outputTarget.systemCode);
mLogUtils.write_log('再送用予約出力管理ID:'+outputTarget.bookingInfoOutputIdForResend);
mLogUtils.write_log('販売先種別コード:'+outputTarget.agtTypeCode);	
		TL_BookingInfoOutputService.bookingInfoRequest req =
			new TL_BookingInfoOutputService.bookingInfoRequest();
		req.commonRequest = commonRequest;
		req.outputTarget = outputTarget;
		/*
		TL_BookingInfoOutputService.execute execute = 
			new TL_BookingInfoOutputService.execute();
		execute.arg0 = req;
		*/
		TL_BookingInfoOutputService.BookingInfoOutputPort port = 
			new TL_BookingInfoOutputService.BookingInfoOutputPort(TL_ServiceConfigHelp.getCommConfig().strServiceUrl);
		// 2015/10/12 Timeout Limit Setup Begin
		port.timeout_x = COMMON_TL_CALL_TIME_OUT_VALUE;
		// 2015/10/12 Timeout Limit Setup END
		// 実行
		// 2016/05/09 実施異常CATCH BEGIN	
		TL_BookingInfoOutputService.bookingInfoResponse rep = null;
		try {
			rep = port.execute(req);
		} catch (Exception e) {
			TL_BookingInfoOutputService.commonResponse commonResponse = new TL_BookingInfoOutputService.commonResponse();
			commonResponse.isSuccess = false;
			commonResponse.failureReason = 'TL_BookingInfoOutputService Exception';
			commonResponse.errorDescription = CommLogUtils.removeOverLogString(e.getMessage(),255);
			rep = new TL_BookingInfoOutputService.bookingInfoResponse();
			rep.commonResponse = commonResponse;
		}
		// 2016/05/09 実施異常CATCH END
		/*
		System.debug(LoggingLevel.INFO, rep);
		for (TL_BookingInfoOutputService.bookingInfo xml : rep.bookingInfoList) {
			TL2WAY_ServiceCtrl.upsertLeadInfo(xml.infoTravelXML);
			System.debug(loggingLevel.INFO, 'XML::' + xml.infoTravelXML);
		}*/
		/********* TEST CODE *********/
		/*
		String docName = 'TL2WAY_TEMPLATE';
		List<Document> sr = [select body, name from Document where DeveloperName = :docName];
    	Blob xmlBody = sr[0].Body;
    	String strXmlBody = xmlBody.toString();
  		TL2WAY_ServiceCtrl.upsertLeadInfo(strXmlBody);
  		*/
		return rep;
	}
	
	// 07.予約出力完了反映API
	public TL_OutputCompleteService.outputCompleteResponse callOutputCompleteService(String shopCd,String outputId) {
mLogUtils.write_log('------outputCompleteRequest(予約出力_完了反映_リクエスト)------');		
		appConfig = TL_ServiceConfigHelp.getAppConfig(shopCd);
		
		TL_OutputCompleteService.commonRequest commonRequest = 
			new TL_OutputCompleteService.commonRequest();
		commonRequest.systemId = appConfig.systemId;
		commonRequest.pmsUserId = appConfig.userId;
		commonRequest.pmsPassword = appConfig.password;

		TL_OutputCompleteService.outputTarget outputTarget = 
			new TL_OutputCompleteService.outputTarget();
		outputTarget.systemCode = '1';
		outputTarget.outputId = outputId;
mLogUtils.write_log('------outputTarget(出力対象)------');
mLogUtils.write_log('起動元システム区分:'+outputTarget.systemCode);
mLogUtils.write_log('予約出力管理ID:'+outputTarget.outputId);	
		TL_OutputCompleteService.outputCompleteRequest req =
			new TL_OutputCompleteService.outputCompleteRequest();
		req.commonRequest = commonRequest;
		req.outputTarget = outputTarget;

		TL_OutputCompleteService.OutputCompletePort port = 
			new TL_OutputCompleteService.OutputCompletePort(TL_ServiceConfigHelp.getCommConfig().strServiceUrl);
		// 2015/10/12 Timeout Limit Setup Begin
		port.timeout_x = COMMON_TL_CALL_TIME_OUT_VALUE;
		// 2015/10/12 Timeout Limit Setup END
		// 実行
		// 2016/05/09 実施異常CATCH BEGIN	
		TL_OutputCompleteService.outputCompleteResponse rep = null;
		try {
			rep = port.execute(req);
		} catch (Exception e) {
			TL_OutputCompleteService.commonResponse commonResponse = new TL_OutputCompleteService.commonResponse();
			commonResponse.isSuccess = false;
			commonResponse.failureReason = 'TL_OutputCompleteService Exception';
			commonResponse.errorDescription = CommLogUtils.removeOverLogString(e.getMessage(),255);
			rep = new TL_OutputCompleteService.outputCompleteResponse();
			rep.commonResponse = commonResponse;
		}
		// 2016/05/09 実施異常CATCH END
//System.debug(LoggingLevel.INFO, rep);
		// 結果：OK
		return rep;
	}
	// 08.部屋タイプマスタ検索(旅行会社)API
	public TL_RealRoomTypeMasterSearchService.rmTypeMstSearchForRealResponse callRealRoomTypeMasterSearchService(String shopCd) {
//System.debug(loggingLevel.INFO, 'METHOD callRealRoomTypeMasterSearchService START:');
mLogUtils.write_log('------rmTypeMstSearchForRealRequest(部屋タイプマスタ検索(旅行会社)_リクエスト)------');
		appConfig = TL_ServiceConfigHelp.getAppConfig(shopCd);
		
		TL_RealRoomTypeMasterSearchService.commonRequest commonRequest
		   = new TL_RealRoomTypeMasterSearchService.commonRequest();
		commonRequest.systemId = appConfig.systemId;
		commonRequest.pmsUserId = appConfig.userId;
		commonRequest.pmsPassword = appConfig.password;
		
		TL_RealRoomTypeMasterSearchService.rmTypeMstSearchForRealRequest req = 
			new TL_RealRoomTypeMasterSearchService.rmTypeMstSearchForRealRequest();
		req.commonRequest = commonRequest;
		TL_RealRoomTypeMasterSearchService.RealRoomTypeMasterSearchPort port = 
			new TL_RealRoomTypeMasterSearchService.RealRoomTypeMasterSearchPort(TL_ServiceConfigHelp.getCommConfig().strServiceUrl);
		// 2015/10/12 Timeout Limit Setup Begin
		port.timeout_x = COMMON_TL_CALL_TIME_OUT_VALUE;
		// 2015/10/12 Timeout Limit Setup END
		// 実行
		// 2016/05/09 実施異常CATCH BEGIN	
		TL_RealRoomTypeMasterSearchService.rmTypeMstSearchForRealResponse rep = null;
		try {
			rep = port.execute(req);
		} catch (Exception e) {
			TL_RealRoomTypeMasterSearchService.commonResponse commonResponse = new TL_RealRoomTypeMasterSearchService.commonResponse();
			commonResponse.isSuccess = false;
			commonResponse.failureReason = 'TL_RealRoomTypeMasterSearchService Exception';
			commonResponse.errorDescription = CommLogUtils.removeOverLogString(e.getMessage(),255);
			rep = new TL_RealRoomTypeMasterSearchService.rmTypeMstSearchForRealResponse();
			rep.commonResponse = commonResponse;
		}	
		// 2016/05/09 実施異常CATCH END
		//System.debug(logginglevel.INFO, '========= EXECUTE REUSTL ========');
		// 結果を出力
		//System.debug(LoggingLevel.INFO, rep.commonResponse.isSuccess);
		//System.debug(LoggingLevel.INFO, rep.commonResponse.failureReason);
		//System.debug(LoggingLevel.INFO, rep.commonResponse.errorDescription);
		// 処理結果がエラーの場合
		if (!rep.commonResponse.isSuccess) return rep;
		// ----------------------------------------
		// TL側の室タイプ→SF側の部屋タイプコード変換設定を行う
		// ----------------------------------------
		// 室タイプ
		map<string, string> tlRmTypeCdToSfRmTypeCdMap = new map<string,string>();
		if (rep.rmTypeList != null) {
			// 室タイプを出力する
			for (TL_RealRoomTypeMasterSearchService.rmType rm: rep.rmTypeList) {
				//System.debug(logginglevel.INFO, rm.rmTypeCode + '=' + rm.rmTypeName + '=' + rm.tlDataOutPutRmTypeCode);
				if (!CommUtils.isBlank(rm.tlDataOutPutRmTypeCode)) {
					tlRmTypeCdToSfRmTypeCdMap.put(rm.rmTypeCode, rm.tlDataOutPutRmTypeCode);
					rm.rmTypeCode = rm.tlDataOutPutRmTypeCode;
				}
			}
		}
		if (rep.realAgtRmTypeList != null) {
			// リアル販売先室タイプ
			for (TL_RealRoomTypeMasterSearchService.realAgtRmType rm: rep.realAgtRmTypeList) {
				//System.debug(logginglevel.INFO, rm.agtCode + '=' + rm.realAgtRmTypeCode + '=' + rm.frame + '=' + rm.realAgtRmTypeName + '=' + rm.rmTypeCode+ '=' + rm.lincolnUseFlag);
				if (tlRmTypeCdToSfRmTypeCdMap.containsKey(rm.rmTypeCode)) {
					rm.rmTypeCode = tlRmTypeCdToSfRmTypeCdMap.get(rm.rmTypeCode);
				}
			}
		}
//System.debug(loggingLevel.INFO, 'METHOD callRealRoomTypeMasterSearchService END:');
		return rep;
		// 結果：OK
	}
	// 09.在庫状況照会(旅行会社) API  
	public TL_RealStockSearchService.stockSearchForRealResponse callRealStockSearchService(String shopCd,TL_RealStockSearchService.extractionCondition pExtractionCondition) {
mLogUtils.write_log('------stockSearchForRealRequest(在庫状況照会(旅行会社)_リクエスト)------');
mLogUtils.write_log('------extractionCondition(抽出条件)------');
mLogUtils.write_log('抽出方法:'+pExtractionCondition.extractionProcedureCode);
mLogUtils.write_log('更新日時:'+pExtractionCondition.updateDate);
mLogUtils.write_log('照会期間FROM:'+pExtractionCondition.searchDurationFrom);
mLogUtils.write_log('照会期間TO:'+pExtractionCondition.searchDurationTo);
mLogUtils.write_log('販売先コード:'+pExtractionCondition.agtCode);
mLogUtils.write_log('旅行会社室タイプコード :'+pExtractionCondition.realAgtRmTypeCode);
//System.debug(loggingLevel.INFO, 'METHOD callRealStockSearchService START:');
		appConfig = TL_ServiceConfigHelp.getAppConfig(shopCd);
		
		TL_RealStockSearchService.commonRequest commonRequest
		   = new TL_RealStockSearchService.commonRequest();
		commonRequest.systemId = appConfig.systemId;
		commonRequest.pmsUserId = appConfig.userId;
		commonRequest.pmsPassword = appConfig.password;
		
		TL_RealStockSearchService.stockSearchForRealRequest req = 
			new TL_RealStockSearchService.stockSearchForRealRequest();
		req.commonRequest = commonRequest;
		req.extractionCondition = pExtractionCondition;
		
		TL_RealStockSearchService.RealStockSearchPort port = 
			new TL_RealStockSearchService.RealStockSearchPort(TL_ServiceConfigHelp.getCommConfig().strServiceUrl);
		// 2015/10/12 Timeout Limit Setup Begin
		port.timeout_x = COMMON_TL_CALL_TIME_OUT_VALUE;
		// 2015/10/12 Timeout Limit Setup END
		// 実行
		// 2016/05/09 実施異常CATCH BEGIN	
		TL_RealStockSearchService.stockSearchForRealResponse rep = null;
		try {
			rep = port.execute(req);
		} catch (Exception e) {
			TL_RealStockSearchService.commonResponse commonResponse = new TL_RealStockSearchService.commonResponse();
			commonResponse.isSuccess = false;
			commonResponse.failureReason = 'TL_RealStockSearchService Exception';
			commonResponse.errorDescription = CommLogUtils.removeOverLogString(e.getMessage(),255);
			rep = new TL_RealStockSearchService.stockSearchForRealResponse();
			rep.commonResponse = commonResponse;
		}
		// 2016/05/09 実施異常CATCH END
/*
System.debug(logginglevel.INFO, '========= EXECUTE REUSTL ========');
		// 結果を出力
System.debug(LoggingLevel.INFO, rep.commonResponse.isSuccess);
System.debug(LoggingLevel.INFO, rep.commonResponse.failureReason);
System.debug(LoggingLevel.INFO, rep.commonResponse.errorDescription);
		// 室タイプを出力する
		if (rep.commonResponse.isSuccess && rep.realAgtRmTypeList != null) {
			for (TL_RealStockSearchService.realAgtRmType rm: rep.realAgtRmTypeList) {
				System.debug(logginglevel.INFO, rm.agtCode + '=' + rm.realAgtRmTypeCode + '=' + rm.realAgtRmTypeName);
			}
		}
System.debug(loggingLevel.INFO, 'METHOD callRealStockSearchService END:');
*/
		return rep;
		// 結果：OK
	}
	// 10.在庫調整(旅行会社) API
	public TL_RealStockAdjustmentService.stockAdjustmentForRealResponse callRealStockAdjustmentService(String shopCd, TL_RealStockAdjustmentService.adjustmentTarget pAdjustmentTarget) {
mLogUtils.write_log('------stockAdjustmentForRealRequest(在庫調整(旅行会社)_リクエスト)------');
mLogUtils.write_log('------adjustmentTarget(調整対象)------');
mLogUtils.write_log('販売先コード:'+pAdjustmentTarget.agtCode);
mLogUtils.write_log('旅行会社室タイプコード:'+pAdjustmentTarget.realAgtRmTypeCode);
mLogUtils.write_log('枠:'+pAdjustmentTarget.frame);
mLogUtils.write_log('調整日付:'+pAdjustmentTarget.adjustmentDate);
mLogUtils.write_log('残室数:'+pAdjustmentTarget.remainingCount);
mLogUtils.write_log('要求ID  :'+pAdjustmentTarget.requestId);
//System.debug(loggingLevel.INFO, 'METHOD callRealStockAdjustmentService START:');
		appConfig = TL_ServiceConfigHelp.getAppConfig(shopCd);
		
		TL_RealStockAdjustmentService.commonRequest commonRequest
		   = new TL_RealStockAdjustmentService.commonRequest();
		commonRequest.systemId = appConfig.systemId;
		commonRequest.pmsUserId = appConfig.userId;
		commonRequest.pmsPassword = appConfig.password;
		
		TL_RealStockAdjustmentService.stockAdjustmentForRealRequest req = 
			new TL_RealStockAdjustmentService.stockAdjustmentForRealRequest();
		req.commonRequest = commonRequest;
		req.adjustmentTarget = pAdjustmentTarget;
		
		TL_RealStockAdjustmentService.RealStockAdjustmentPort port = 
			new TL_RealStockAdjustmentService.RealStockAdjustmentPort(TL_ServiceConfigHelp.getCommConfig().strServiceUrl);
		// 2015/10/12 Timeout Limit Setup Begin
		port.timeout_x = COMMON_TL_CALL_TIME_OUT_VALUE;
		// 2015/10/12 Timeout Limit Setup END
		// 実行
		// 2016/05/09 実施異常CATCH BEGIN
		TL_RealStockAdjustmentService.stockAdjustmentForRealResponse rep = null;
		try {
			rep = port.execute(req);
		} catch (Exception e) {
			TL_RealStockAdjustmentService.commonResponse commonResponse = new TL_RealStockAdjustmentService.commonResponse();
			commonResponse.isSuccess = false;
			commonResponse.failureReason = 'TL_RealStockAdjustmentService Exception';
			commonResponse.errorDescription = CommLogUtils.removeOverLogString(e.getMessage(),255);
			rep = new TL_RealStockAdjustmentService.stockAdjustmentForRealResponse();
			rep.commonResponse = commonResponse;
		}
		// 2016/05/09 実施異常CATCH END
/*		
		System.debug(logginglevel.INFO, '========= EXECUTE REUSTL ========');
		// 結果を出力
		System.debug(LoggingLevel.INFO, rep.commonResponse.isSuccess);
		System.debug(LoggingLevel.INFO, rep.commonResponse.failureReason);
		System.debug(LoggingLevel.INFO, rep.commonResponse.errorDescription);
		
		// リアル販売先室タイプ
		System.debug(LoggingLevel.INFO, rep.adjustmentResult);
System.debug(loggingLevel.INFO, 'METHOD callRealStockAdjustmentService END:');
*/
		return rep;
		// 結果：OK
	}
}