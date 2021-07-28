/**
* 2way連携： ApexCalout機能共通クラス
* TL-リンカーン機能連携
* 2015/06/01 INIT
* 2016/07/29 ログ出力機能追加
**/
public with sharing class TA_ServiceCtrl {
    // ログ出力機能
    private CommLogUtils mLogUtils{get; private set;}
	//private final TA_ServiceConfigHelp help;
	private TA_ServiceConfigHelp.APPCONFIG appConfig;
	//private TA_ServiceConfigHelp.ERRCONFIG errConfig;
	private final integer COMMON_TA_CALL_TIME_OUT_VALUE = 120000;
	// Service Key
	public static final String SERVICE_KEY = 'TA';
	public TA_ServiceCtrl() {mLogUtils = new CommLogUtils('TA_ServiceCtrl',true);mLogUtils.write_method_start('--------API通信-------');} 
	public TA_ServiceCtrl(CommLogUtils pmLogUtils) {mLogUtils = pmLogUtils;}
	// 部屋情報取得
	//public TA_RoomTypeInfoItem callRoomTypeMasterSearchService(String shopCd, String dataType) {
	public TA_RoomTypeInfoItem callRoomTypeMasterSearchService(String shopCd) {
mLogUtils.write_log('------UpdateRoomRankRQ(部屋情報取得要求)------');
mLogUtils.write_log('------RoomInfo(部屋情報)------');
mLogUtils.write_log('取得する部屋のタイプ:1');	
		// 共通ログイン情報を設定する
		String reqStr = setCommReqInfo(shopCd, callRoomTypeMasterSearchServiceReq);
		// -------------- 予部屋情報取得機能個別設定情報 --------------
		reqStr = reqStr.replace('$$__DATA_TYPE__$$','1');
		HTTPResponse res = null;
		try {
			// リクエストを発行する
			res = sendRequest(reqStr, true);
//System.debug(logginglevel.info, res.getBody());
		} catch (Exception e) {
			res = getExceptionXml('callRoomTypeMasterSearchService Exception', e.getMessage()); 
		}
		String strXmlBody = res.getBody();
		// XML TO CLASS 
		TA_RoomTypeInfoItem resInfo = new TA_RoomTypeInfoItem(strXmlBody);
//System.debug(logginglevel.info, 'doc='+resInfo);
		return resInfo;
	}
	
	// 在庫取得
	public TA_RoomStockInfoGetItem callStockSearchService(String shopCd, list<TA_RoomStockInfoGetItem.RoomStockInfo> stockInfLst) {
mLogUtils.write_log('------GetRoomStockRQ(在庫取得要求)------');
		// 共通ログイン情報を設定する
		String reqStr = setCommReqInfo(shopCd, callStockSearchServiceReq);
		// -------------- 在庫取得機能個別設定情報 --------------
		String reqStrSub1 = '';
		for (TA_RoomStockInfoGetItem.RoomStockInfo roomStockInf : stockInfLst) {
			reqStrSub1 += callStockSearchServiceReq_Sub1
						.replace('$$__ROOMTYPECODE__$$',roomStockInf.roomTypeCode)
						.replace('$$__DATE__$$',roomStockInf.stockDate);
mLogUtils.write_log('------RoomStockInfo(在庫情報)------');
mLogUtils.write_log('部屋タイプコード:'+roomStockInf.roomTypeCode);
mLogUtils.write_log('取得日付:'+roomStockInf.stockDate);						
		}
		reqStr = reqStr.replace('$$__SUB1__$$',reqStrSub1);
		// リクエストを発行する
		HTTPResponse res = null;
		try {
			res = sendRequest(reqStr, true);
		} catch (Exception e) {
			res = getExceptionXml('callStockSearchService Exception', e.getMessage()); 
		}
//System.debug(logginglevel.info, res.getBody());
		String strXmlBody = res.getBody();
		TA_RoomStockInfoGetItem resInfo = new TA_RoomStockInfoGetItem(strXmlBody);	
//System.debug(logginglevel.info, 'resInfo='+resInfo);
		return resInfo;
	}
	
	// 在庫更新
	public TA_RoomStockInfoUpdItem callStockAdjustmentService(String shopCd, list<TA_RoomStockInfoUpdItem.RoomStockInfo> stockInfLst) {
mLogUtils.write_log('------UpdateRoomStockRQ(在庫更新要求)------');
		String reqStr = setCommReqInfo(shopCd, callStockAdjustmentServiceReq);
		String reqStrSub1 = '';
		for (TA_RoomStockInfoUpdItem.RoomStockInfo roomStockInf : stockInfLst) {
			String tmpSub1 = callStockAdjustmentServiceReq_Sub1
						.replace('$$__ROOMTYPECODE__$$',roomStockInf.roomTypeCode)
						.replace('$$__DATE__$$',roomStockInf.stockDate)
						.replace('$$__ROOMSTOCKNUM__$$',roomStockInf.roomStockNum);
			if (!CommUtils.isBlank(roomStockInf.salesClosed)) {
				tmpSub1 = tmpSub1.replace('$$__SALESCLOSED__$$','<SalesClosed>'+CommUtils.nullToBlank(roomStockInf.salesClosed)+'</SalesClosed>');
			} else {
				tmpSub1 = tmpSub1.replace('$$__SALESCLOSED__$$','');
			}
			if (!CommUtils.isBlank(roomStockInf.isForce)) {
				tmpSub1 = tmpSub1.replace('$$__ISFORCE__$$','<IsForce>'+CommUtils.nullToBlank(roomStockInf.isForce)+'</IsForce>');
			} else {
				tmpSub1 = tmpSub1.replace('$$__ISFORCE__$$','');
			}
mLogUtils.write_log('------RoomStockInfo(在庫情報)------');
mLogUtils.write_log('部屋タイプコード:'+ roomStockInf.roomTypeCode);
mLogUtils.write_log('更新日付:'+ roomStockInf.stockDate);
mLogUtils.write_log('在庫数:'+roomStockInf.roomStockNum);
mLogUtils.write_log('手仕舞い設定:'+CommUtils.nullToBlank(roomStockInf.salesClosed));
mLogUtils.write_log('強制更新設定:'+CommUtils.nullToBlank(roomStockInf.isForce));			
			reqStrSub1 += tmpSub1;
		}
		reqStr = reqStr.replace('$$__SUB1__$$',reqStrSub1);
		// リクエストを発行する
		HTTPResponse res = null;
		try {
			res = sendRequest(reqStr, true);
		} catch (Exception e) {
			res = getExceptionXml('callStockAdjustmentService Exception', e.getMessage()); 
		}
//System.debug(logginglevel.info, res.getBody());
		String strXmlBody = res.getBody();
		TA_RoomStockInfoUpdItem resInfo = new TA_RoomStockInfoUpdItem(strXmlBody);	
//System.debug(logginglevel.info, 'resInfo='+resInfo);
		return resInfo;
	}
	
	// 予約通知
	public TA_BookingInfoOutputInfoItem callBookingInfoOutputService(String shopCd) {
mLogUtils.write_log('------AllotmentBookingReports(予約情報通知 )------');
mLogUtils.write_log('連携フォーマット:xml');		
		String reqStr = setCommReqInfo(shopCd, callBookingInfoOutputServiceReq);
		// リクエストURLを設定する
		HTTPResponse res = null;
		try {
			res = sendRequest(reqStr, false);
		} catch (Exception e) {
			res = getExceptionXml('callBookingInfoOutputService Exception', e.getMessage()); 
		}
//System.debug(logginglevel.info, res.getBody());
		String strXmlBody = res.getBody();
		TA_BookingInfoOutputInfoItem resInfo = new TA_BookingInfoOutputInfoItem(strXmlBody);
		return resInfo;
	}
	
	// 予約通知完了機能
	public TA_OutputCompleteInfoItem callOutputCompleteService(String shopCd, String dataId) {
mLogUtils.write_log('------callOutputCompleteService(予約通知完了機能)------');
mLogUtils.write_log('処理ID:2');
mLogUtils.write_log('連携フォーマット:xml');
mLogUtils.write_log('データID:'+dataId);
		// 共通ログイン情報を設定する
		String reqStr = setCommReqInfo(shopCd, callOutputCompleteServiceReq);
		// -------------- 予約通知完了機能個別設定情報 --------------
		reqStr = reqStr.replace('$$__DATAID__$$',dataId);
		// リクエストを発行する
		HTTPResponse res = null;
		try {
			res = sendRequest(reqStr, false);
		} catch (Exception e) {
			res = getExceptionXml('callOutputCompleteService Exception', e.getMessage()); 
		}
//System.debug(logginglevel.info, res.getBody());
		String strXmlBody = res.getBody();
		TA_OutputCompleteInfoItem resInfo = new TA_OutputCompleteInfoItem(strXmlBody);
     	
		return resInfo;
	}
	/*
	// エージェント情報取得
	public TA_OTAInfoItem callAgtListService(String shopCd) {
		// 共通ログイン情報を設定する
		String reqStr = setCommReqInfo(shopCd, callAgtListServiceReq);
		// リクエストを発行する
		HTTPResponse res = null;
		try {
			res = sendRequest(reqStr, true);
		} catch (Exception e) {
			res = getExceptionXml('callOutputCompleteService Exception', e.getMessage()); 
		}
		String strXmlBody = res.getBody();
System.debug(logginglevel.info, res.getBody());

		// XML TO CLASS 
		TA_OTAInfoItem resInfo = new TA_OTAInfoItem(strXmlBody);	
System.debug(logginglevel.info, 'resInfo='+resInfo);
		return resInfo;
	}*/
	// プラン情報取得
	public TA_PlanInfoItem callNetPlanMasterSearchService(String shopCd) {
mLogUtils.write_log('------GetPlanListRQ(プラン情報取得要求)------');
// 共通ログイン情報を設定する
		String reqStr = setCommReqInfo(shopCd, callNetPlanMasterSearchServiceSeq);
		// リクエストを発行する
		HTTPResponse res = null;
		try {
			res = sendRequest(reqStr, true);
		} catch (Exception e) {
			res = getExceptionXml('callNetPlanMasterSearchService Exception', e.getMessage()); 
		}
		String strXmlBody = res.getBody();
//System.debug(logginglevel.info, 'strXmlBody=' +res.getBody());

		// XML TO CLASS 
		TA_PlanInfoItem resInfo = new TA_PlanInfoItem(strXmlBody);	
//System.debug(logginglevel.info, 'resInfo='+resInfo);
		return resInfo;
	}
	
	private String setCommReqInfo(String shopCd, String reqStr) {
		appConfig = TA_ServiceConfigHelp.getAppConfig(shopCd);
		reqStr = reqStr
					.replace('$$__USERID__$$',appConfig.userId)
					.replace('$$__PASSWD__$$',appConfig.password);
		if (CommUtils.isBLank(appConfig.systemId)) {
			return reqStr.replace('$$__PARENTID__$$','');
		} else {
			return reqStr.replace('$$__PARENTID__$$','<PartnerId>' + appConfig.systemId + '</PartnerId');
		}
	}
	
	private HTTPResponse sendRequest(String reqStr, Boolean isUp) {
		// リクエストURLを設定する
		String endpoint = TA_ServiceConfigHelp.getCommConfig().strServiceUrl;
		if (isUp) endpoint = TA_ServiceConfigHelp.getCommConfig().strServiceUpUrl;
if (isUp) System.debug(logginglevel.INFO, 'reqStr::' + 'PMS_XML='+reqStr);
else System.debug(logginglevel.INFO, 'reqStr::' + reqStr);
		HttpRequest req = new HttpRequest();
		req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
		if (isUp) req.setBody('PMS_XML='+reqStr);
		//if (!isUp) endpoint += '?' + reqStr;
		else req.setBody(reqStr);
		//req.setBody('PMS_XML='+reqStr);
		req.setEndpoint(endpoint);
		req.setMethod('POST');
		req.setTimeout(COMMON_TA_CALL_TIME_OUT_VALUE);
		
		Http http = new Http();
		HTTPResponse res = http.send(req);
		return res;
	}
	// 部屋情報取得REQ
	private static final String callRoomTypeMasterSearchServiceReq = '<?xml version="1.0" encoding="utf-8"?><GetRoomListRQ><LoginInfo><UserId>$$__USERID__$$</UserId><Password>$$__PASSWD__$$</Password>$$__PARENTID__$$</LoginInfo><RoomInfo><DataType>$$__DATA_TYPE__$$</DataType></RoomInfo></GetRoomListRQ>';	
	// 在庫取得
	private static final String callStockSearchServiceReq = '<?xml version="1.0" encoding="utf-8"?><GetRoomStockRQ><LoginInfo><UserId>$$__USERID__$$</UserId><Password>$$__PASSWD__$$</Password></LoginInfo><RoomStockList>$$__SUB1__$$</RoomStockList></GetRoomStockRQ>';
	private static final String callStockSearchServiceReq_Sub1 = '<RoomStockInfo><RoomTypeCode>$$__ROOMTYPECODE__$$</RoomTypeCode><Date>$$__DATE__$$</Date></RoomStockInfo>';
	// 在庫更新
	private static final String callStockAdjustmentServiceReq = '<?xml version="1.0" encoding="utf-8"?><UpdateRoomStockRQ><LoginInfo><UserId>$$__USERID__$$</UserId><Password>$$__PASSWD__$$</Password></LoginInfo><RoomStockList>$$__SUB1__$$</RoomStockList></UpdateRoomStockRQ>';
	private static final String callStockAdjustmentServiceReq_Sub1 = '<RoomStockInfo><RoomTypeCode>$$__ROOMTYPECODE__$$</RoomTypeCode><Date>$$__DATE__$$</Date><RoomStockNum>$$__ROOMSTOCKNUM__$$</RoomStockNum>$$__SALESCLOSED__$$$$__ISFORCE__$$</RoomStockInfo>';
	// 予約情報通知
	private static final String callBookingInfoOutputServiceReq = 'UserId=$$__USERID__$$&Password=$$__PASSWD__$$&TransactionId=1&ResponseFormat=xml';
	// 予約通知完了機能
	//private static final String callOutputCompleteServiceReq = '<?xml version="1.0" encoding="utf-8"?><BookingReportCompleteRQ><LoginInfo><UserId>$$__USERID__$$</UserId><Password>$$__PASSWD__$$</Password></LoginInfo><TransactionInformation><DataID>$$__DATAID__$$</DataID></TransactionInformation></BookingReportCompleteRQ>';
	private static final String callOutputCompleteServiceReq = 'UserId=$$__USERID__$$&Password=$$__PASSWD__$$&TransactionId=2&ResponseFormat=xml&DataId=$$__DATAID__$$';
	// エージェント情報取得
	private static final String callAgtListServiceReq = '<?xml version="1.0" encoding="utf-8"?><GetOtaListRQ><LoginInfo><UserId>$$__USERID__$$</UserId><Password>$$__PASSWD__$$</Password>$$__PARENTID__$$</LoginInfo></GetOtaListRQ>';
	// プラン情報取得
	private static final String callNetPlanMasterSearchServiceSeq = '<?xml version="1.0" encoding="utf-8"?><GetPlanListRQ><LoginInfo><UserId>$$__USERID__$$</UserId><Password>$$__PASSWD__$$</Password>$$__PARENTID__$$</LoginInfo></GetPlanListRQ>';
	
	private HTTPResponse getExceptionXml(String errCd , String errMsg) {
		String xmlTemplate = '<?xml version="1.0" encoding="utf-8"?><Error><Code>'+errCd+'</Code><ErrorMessage>'+errMsg+'</ErrorMessage></Error>';
		HTTPResponse res = new HTTPResponse();
		res.setBody(xmlTemplate);
		return res;
	}
	public static string setManagerDataId(String managerId) {
		// 2016/06/21 管理ID重複回避対応 BEGIN
		//return CommUtils.nullToBlank(managerId).removeStart(SERVICE_KEY + '_');
		String retManagerId = CommUtils.nullToBlank(managerId).removeStart(SERVICE_KEY + '_');
		if (retManagerId.indexOf('_') >= 0) {
			// UUIDコード設定されている場合、[_]でSPLITして、２番目のコードは実際の管理コード
			String[] manangerIds = retManagerId.split('_');
			retManagerId = manangerIds[1];
		}
		return retManagerId;
	}
	public static string getManagerDataId(String managerId) {
		// 2016/06/21 管理ID重複回避対応 BEGIN
		//return SERVICE_KEY + '_' + CommUtils.nullToBlank(managerId);
		return SERVICE_KEY + '_' + Commutils.getGUID() + '_' + CommUtils.nullToBlank(managerId);
	}
}