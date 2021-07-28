public with sharing class JR_ServiceCtrl {
    // ログ出力機能
    private CommLogUtils mLogUtils{get; private set;}
    // CONFIG情報
    private BI_JR_ServiceConfigHelp.APPCONFIG appConfig;
    // 最大TIMEOUT時間
    private final integer COMMON_CALL_TIME_OUT_VALUE = 120000;
    // Service Key
    public static final String SERVICE_KEY = 'JR';
    // ステータス管理定数
    public static final string CONST_RESULT_FUNCTION_TYPE_LEAD_IMPORT = '予約取込';
    public static final string CONST_RESULT_STATUS_TYPE_LEAD_IMPORT_NG = '予約取込NG';
    public static final string CONST_RESULT_STATUS_TYPE_LEAD_WAIT_IMPORT = '予約取込待ち';
    public static final string CONST_RESULT_STATUS_TYPE_LEAD_IMPORT_OVER = '予約取込完了';
    public static final string CONST_RESULT_STATUS_TYPE_XML_IMPORT = 'XML取込完了';
    
    // クラスインスタンス化
    public JR_ServiceCtrl() {mLogUtils = new CommLogUtils('JR_ServiceCtrl',true);mLogUtils.write_method_start('--------API通信-------');} 
    public JR_ServiceCtrl(CommLogUtils pmLogUtils) {mLogUtils = pmLogUtils;}

	// 6.1. SelectBooking(予約照会 API)
	public SelectBookingReply callSelectBookingService(String shopCd) {
        mLogUtils.write_log('------SelectBookingRequest(予約照会API出力)------');
        //パラメータ初期化
        appConfig = BI_JR_ServiceConfigHelp.getAppConfig(shopCd);
        // サビースURL
        String serviceUrl = BI_JR_ServiceConfigHelp.getCommConfig().serviceUrl + '/rkdownlink';
        mLogUtils.write_log('endpoint:'+serviceUrl);
        //日付情報確認する
        DateTime nowDt = System.now();
        String systemDate = nowDt.format('yyyy-MM-dd');
        String systemTime = nowDt.format('HH:mm:ss');
		
		String reqXml = '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'+
		'<soap:Header>'+
		'<AuthenticationHeader UserName="$$__UserName__$$" PassWord="" />'+
		'</soap:Header>'+
		'<soap:Body>'+
		'<SelectBookingRequest>'+
		'<TransactionType>'+
		'<DataFrom>FromPMS</DataFrom>'+
		'<DataClassification>SelectBookingRequest</DataClassification>'+
		'<SystemDate>$$__SystemDate__$$</SystemDate>'+
		'<SystemTime>$$__SystemTime__$$</SystemTime>'+
		'</TransactionType>'+
		'<AccommodationInformation>'+
		'<HotelCode>$$__HotelCode__$$</HotelCode>'+
		'<HotelPassword>$$__HotelPassword__$$</HotelPassword>'+
		'</AccommodationInformation>'+
		'</SelectBookingRequest>'+
		'</soap:Body>'+
		'</soap:Envelope>';
		reqXml = reqXml.replace('$$__UserName__$$',appConfig.userName)
					.replace('$$__SystemDate__$$',systemDate)
					.replace('$$__SystemTime__$$',systemTime)
                    .replace('$$__HotelCode__$$',appConfig.hotelCode)//らく通の施設コードを設定゙
                    .replace('$$__HotelPassword__$$',appConfig.password);//施設毎のパスワード。
        mLogUtils.write_log('リクエスト:'+reqXml);
        // リクエストを発行する
        HTTPResponse res = null;
        try {
            res = sendRequest(reqXml, serviceUrl);
            mLogUtils.write_log('レスポンス:' + res);
        } catch (Exception e) {
            mLogUtils.write_error('エラー:' + e.getStackTraceString());
            res = getExceptionXml('callSelectBookingService Exception', e.getMessage()); 
        }
        String strXmlBody = res.getBody();
        return new SelectBookingReply(strXmlBody);
	}
	
	// 6.2. GetBooking(予約取得 API)
	public GetBookingReply callGetBookingService(String shopCd, String bookingID) {
        mLogUtils.write_log('------GetBookingRequest(予約照会API出力)------');
        //パラメータ初期化
        appConfig = BI_JR_ServiceConfigHelp.getAppConfig(shopCd);
        // サビースURL
        String serviceUrl = BI_JR_ServiceConfigHelp.getCommConfig().serviceUrl + '/rkdownlink';
        mLogUtils.write_log('endpoint:'+serviceUrl);
        //日付情報確認する
        DateTime nowDt = System.now();
        String systemDate = nowDt.format('yyyy-MM-dd');
        String systemTime = nowDt.format('HH:mm:ss');

		String reqXml = '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'+
						'<soap:Header>'+
						'<AuthenticationHeader UserName="$$__UserName__$$" PassWord="" />'+
						'</soap:Header>'+
						'<soap:Body>'+
						'<GetBookingRequest>'+
						'<TransactionType>'+
						'<DataFrom>FromPMS</DataFrom>'+
						'<DataClassification>GetBookingRequest</DataClassification>'+
						'<SystemDate>$$__SystemDate__$$</SystemDate>'+
						'<SystemTime>$$__SystemTime__$$</SystemTime>'+
						'</TransactionType>'+
						'<AccommodationInformation>'+
						'<HotelCode>$$__HotelCode__$$</HotelCode>'+
						'<HotelPassword>$$__HotelPassword__$$</HotelPassword>'+
						'</AccommodationInformation>'+
						'<UnconfirmedBookingInformation>'+
						'<GetBookingID>$$__GetBookingID__$$</GetBookingID>'+
						'</UnconfirmedBookingInformation>'+
						'</GetBookingRequest>'+
						'</soap:Body>'+
						'</soap:Envelope>';
		reqXml = reqXml.replace('$$__UserName__$$',appConfig.userName)
                    .replace('$$__SystemDate__$$',systemDate)
                    .replace('$$__SystemTime__$$',systemTime)
                    .replace('$$__HotelCode__$$',appConfig.hotelCode)//らく通の施設コードを設定゙
                    .replace('$$__HotelPassword__$$',appConfig.password)//施設毎のパスワード。
					.replace('$$__GetBookingID__$$',bookingID);
        mLogUtils.write_log('リクエスト:'+reqXml);
        // リクエストを発行する
        HTTPResponse res = null;
        try {
            res = sendRequest(reqXml, serviceUrl);
            mLogUtils.write_log('レスポンス:' + res);
        } catch (Exception e) {
            mLogUtils.write_error('エラー:' + e.getStackTraceString());
            res = getExceptionXml('callSelectBookingService Exception', e.getMessage()); 
        }
        String strXmlBody = res.getBody();
        return new GetBookingReply(strXmlBody);
	}
	
	// 6.3. ConfirmBooking(予約確認 API)
	public ConfirmBookingReply callConfirmBookingService(String shopCd, String bookingID) {
        mLogUtils.write_log('------ConfirmBookingRequest(予約確認API出力)------');
        //パラメータ初期化
        appConfig = BI_JR_ServiceConfigHelp.getAppConfig(shopCd);
        // サビースURL
        String serviceUrl = BI_JR_ServiceConfigHelp.getCommConfig().serviceUrl + '/rkdownlink';
        mLogUtils.write_log('endpoint:'+serviceUrl);
        //日付情報確認する
        DateTime nowDt = System.now();
        String systemDate = nowDt.format('yyyy-MM-dd');
        String systemTime = nowDt.format('HH:mm:ss');
        // リクエストXML設定する
		String reqXml = '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'+
						'<soap:Header>'+
						'<AuthenticationHeader UserName="$$__UserName__$$" PassWord="" />'+
						'</soap:Header>'+
						'<soap:Body>'+
						'<ConfirmBookingRequest>'+
						'<TransactionType>'+
						'<DataFrom>FromPMS</DataFrom>'+
						'<DataClassification>ConfirmBookingRequest</DataClassification>'+
						'<SystemDate>$$__SystemDate__$$</SystemDate>'+
						'<SystemTime>$$__SystemTime__$$</SystemTime>'+
						'</TransactionType>'+
						'<AccommodationInformation>'+
						'<HotelCode>$$__HotelCode__$$</HotelCode>'+
						'<HotelPassword>$$__HotelPassword__$$</HotelPassword>'+
						'</AccommodationInformation>'+
						'<UnconfirmedBookingInformation>'+
						'<GetBookingID>$$__GetBookingID__$$</GetBookingID>'+
						'</UnconfirmedBookingInformation>'+
						'</ConfirmBookingRequest>'+
						'</soap:Body>'+
						'</soap:Envelope>';
		reqXml = reqXml.replace('$$__UserName__$$',appConfig.userName)
                    .replace('$$__SystemDate__$$',systemDate)//システム日付
                    .replace('$$__SystemTime__$$',systemTime)//システム時刻
                    .replace('$$__HotelCode__$$',appConfig.hotelCode)//らく通の施設コードを設定゙
                    .replace('$$__HotelPassword__$$',appConfig.password)//施設毎のパスワード。
					.replace('$$__GetBookingID__$$',bookingID);
        mLogUtils.write_log('リクエスト:'+reqXml);
		//createReqXml(reqXml);
        // リクエストを発行する
        HTTPResponse res = null;
        try {
            res = sendRequest(reqXml, serviceUrl);
            mLogUtils.write_log('レスポンス:' + res);
        } catch (Exception e) {
            mLogUtils.write_error('エラー:' + e.getStackTraceString());
            res = getExceptionXml('callConfirmBookingService Exception', e.getMessage()); 
        }
        String strXmlBody = res.getBody();
        return new ConfirmBookingReply(strXmlBody);
	}
	
	public class RoomStockInfo{
	    public RoomStockInfo() {
	    	SettingDateList = new list<DayStockInfo>();
	    }
	    public String StockNo{get;set;}
		public String RoomTypeCode{get;set;}
		public list<DayStockInfo> SettingDateList{get;set;}
		/*
		public String StockDate{get;set;}	
		public Integer VacantRoomCount{get;set;}		
		public String CloseCategory{get;set;}	
		*/
		public String toSettingDateListXml() {
			String xml = '';
			for (DayStockInfo ds : SettingDateList) {
				xml += '<SettingDateList>';
				xml += '<Date>'+ds.StockDate+'</Date>';
				xml += '<VacantRoomCount>'+CommUtils.nullToBlank(ds.VacantRoomCount)+'</VacantRoomCount>';
				if (!CommUtils.isBlank(ds.CloseCategory)) xml += '<CloseCategory>'+CommUtils.nullToBlank(ds.CloseCategory)+'</CloseCategory>';
				xml += '</SettingDateList>';
			}
			return xml;
		}
	}
	public class DayStockInfo {
		public DayStockInfo() {
			CloseCategory = '';
		}
		public String StockDate{get;set;}	
		public Integer VacantRoomCount{get;set;}		
		public String CloseCategory{get;set;}	
	}

	// 6.4.在庫更新
	public InventorySettingReply calInventorySetting(String shopCd, RoomStockInfo stockReq) {
        mLogUtils.write_log('------calInventorySetting(InventorySetting(在庫更新API)_リクエスト)------');
		//パラメータ初期化
		appConfig = BI_JR_ServiceConfigHelp.getAppConfig(shopCd);
		// サビースURL
		String serviceUrl = BI_JR_ServiceConfigHelp.getCommConfig().serviceUrl + '/rkuplink';
        mLogUtils.write_log('endpoint:'+serviceUrl);
		//日付情報確認する
		DateTime nowDt = System.now();
		String systemDate = nowDt.format('yyyy-MM-dd');
		String systemTime = nowDt.format('HH:mm:ss');
		// 在庫調整のリクエストXML
		String reqXml = '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'+
		'<soap:Header>'+
		'<AuthenticationHeader UserName="$$__UserName__$$" PassWord="" />'+
		'</soap:Header>'+
		'<soap:Body>'+
		'<InventorySettingRequest>'+
		'<TransactionType>'+
		'<DataFrom>FromPMS</DataFrom>'+
		'<DataClassification>InventorySettingRequest</DataClassification>'+
		'<RequestID>$$__RequestID__$$</RequestID>'+
		'<SystemDate>$$__SystemDate__$$</SystemDate>'+
		'<SystemTime>$$__SystemTime__$$</SystemTime>'+
		'</TransactionType>'+
		'<AccommodationInformation>'+
		'<HotelCode>$$__HotelCode__$$</HotelCode>'+
		'<HotelPassword>$$__HotelPassword__$$</HotelPassword>'+
		'</AccommodationInformation>'+
		'<InventorySettingInformation>'+
		'    <InventorySettingCategory>0</InventorySettingCategory>'+
		'    <InventorySettingList>'+
		'        <BlockType><BlockRoomTypeCode>$$__BlockRoomTypeCode__$$</BlockRoomTypeCode></BlockType>'+
//		'        <SettingDateList>'+
//		'        <Date>$$__Date__$$</Date>'+
//		'        <VacantRoomCount>$$__VacantRoomCount__$$</VacantRoomCount>'+
//		//'		 <CloseCategory>$$__CloseCategory__$$</CloseCategory>'+
//		'        </SettingDateList>'+
		'    	$$__SettingDateList__$$'+
		'    </InventorySettingList>'+
		'</InventorySettingInformation>'+
		'</InventorySettingRequest>'+
		'</soap:Body>'+
		'</soap:Envelope>';
//System.debug(LoggingLevel.info, 'stockReq.CloseCategory='+stockReq.CloseCategory);
		reqXml = reqXml.replace('$$__UserName__$$',appConfig.userName)//Header設定情報
					.replace('$$__RequestID__$$',stockReq.StockNo)//リクエスト ID
					.replace('$$__SystemDate__$$',systemDate)//システム日付
					.replace('$$__SystemTime__$$',systemTime)//システム時刻
					.replace('$$__HotelCode__$$',appConfig.hotelCode)//らく通の施設コードを設定゙
					.replace('$$__HotelPassword__$$',appConfig.password)//施設毎のパスワード。
					.replace('$$__BlockRoomTypeCode__$$',stockReq.RoomTypeCode)
					.replace('$$__SettingDateList__$$', stockReq.toSettingDateListXml());
//					.replace('$$__VacantRoomCount__$$',CommUtils.nullToBlank(stockReq.VacantRoomCount))
//					.replace('$$__CloseCategory__$$',CommUtils.nullToBlank(stockReq.CloseCategory));
		mLogUtils.write_log('------RoomStockInfo(在庫情報)------');
		mLogUtils.write_log('リクエスト ID:'+ stockReq.StockNo);
		mLogUtils.write_log('部屋タイプコード:'+ stockReq.RoomTypeCode);
//		mLogUtils.write_log('更新日付:'+ stockReq.StockDate);
//		mLogUtils.write_log('在庫数:'+stockReq.VacantRoomCount);
//		mLogUtils.write_log('手仕舞区分:'+stockReq.CloseCategory);
		mLogUtils.write_log('リクエスト:'+reqXml);
        // リクエストを発行する
        HTTPResponse res = null;
        try {
            res = sendRequest(reqXml, serviceUrl);
            mLogUtils.write_log('レスポンス:' + res);
        } catch (Exception e) {
            mLogUtils.write_error('エラー:' + e.getStackTraceString());
            res = getExceptionXml('calInventorySetting Exception', e.getMessage()); 
        }
        String strXmlBody = res.getBody();
mLogUtils.write_log('レスポンス[BODY]='+strXmlBody); 
        return new InventorySettingReply(strXmlBody);
	}

    // 6.5.部屋マスタ取得API
    public JR_GetRoomTypeReply calGetRoomType(String shopCd) {
        mLogUtils.write_log('------SelectBookingRequest(部屋マスタ取得API)------');
        //パラメータ初期化
        appConfig = BI_JR_ServiceConfigHelp.getAppConfig(shopCd);
        // サビースURL
        String serviceUrl = BI_JR_ServiceConfigHelp.getCommConfig().serviceUrl + '/maintenance';
        mLogUtils.write_log('endpoint:'+serviceUrl);
        //日付情報確認する
        DateTime nowDt = System.now();
        String systemDate = nowDt.format('yyyy-MM-dd');
        String systemTime = nowDt.format('HH:mm:ss');
        
        String reqXml = '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'+
        '<soap:Header>'+
        '<AuthenticationHeader UserName="$$__UserName__$$" PassWord="" />'+
        '</soap:Header>'+
        '<soap:Body>'+
        '<GetRoomTypeRequest>'+
        '<TransactionType>'+
        '<DataFrom>FromPMS</DataFrom>'+
        '<DataClassification>GetRoomTypeRequest</DataClassification>'+
        '<SystemDate>$$__SystemDate__$$</SystemDate>'+
        '<SystemTime>$$__SystemTime__$$</SystemTime>'+
        '</TransactionType>'+
        '<AccommodationInformation>'+
        '<HotelCode>$$__HotelCode__$$</HotelCode>'+
        '<HotelPassword>$$__HotelPassword__$$</HotelPassword>'+
        '</AccommodationInformation>'+
        '</GetRoomTypeRequest>'+
        '</soap:Body>'+
        '</soap:Envelope>';
        reqXml = reqXml.replace('$$__UserName__$$',appConfig.userName)
                    .replace('$$__SystemDate__$$',systemDate)
                    .replace('$$__SystemTime__$$',systemTime)
                    .replace('$$__HotelCode__$$',appConfig.hotelCode)//らく通の施設コードを設定゙
                    .replace('$$__HotelPassword__$$',appConfig.password);//施設毎のパスワード。
        mLogUtils.write_log('リクエスト:'+reqXml);
        // リクエストを発行する
        HTTPResponse res = null;
        try {
            res = sendRequest(reqXml, serviceUrl);
            mLogUtils.write_log('レスポンス:' + res);
        } catch (Exception e) {
            mLogUtils.write_error('エラー:' + e.getStackTraceString());
            res = getExceptionXml('calGetRoomType Exception', e.getMessage()); 
        }
        // TEST SAMPLE *********************************
        String body = '<soap:Body><GetRoomTypeReply><TransactionType><DataFrom>FromRakutsu</DataFrom><DataClassification>GetRoomTypeReply</DataClassification><SystemDate>2018-03-26</SystemDate><SystemTime>14:00</SystemTime></TransactionType>'
                      +'<ResultInformation><ResultCode>0</ResultCode></ResultInformation>'
                      //+'<RoomType><RoomTypeCode>6</RoomTypeCode><RoomTypeName>A001</RoomTypeName></RoomType>'
                      +'<RoomType><RoomTypeCode>1200188490</RoomTypeCode><RoomTypeName>A002</RoomTypeName></RoomType>'
                      +'</GetRoomTypeReply></soap:Body>';
        //res.setBody(body);
        // TEST SAMPLE *********************************
        String strXmlBody = res.getBody();
        return new JR_GetRoomTypeReply(strXmlBody);
    }

    
	// *********************************
	// 共通セクション処理定義
	// *********************************
    // レスポンスエラー処理
    private HTTPResponse getExceptionXml(String errCd , String errMsg) {
        String xmlTemplate = '<?xml version="1.0" encoding="utf-8"?><soap:Body><Error><ResultCode>'+errCd+'</ResultCode><DetailedInformation><ErrorCode>'+errMsg+'</ErrorCode></DetailedInformation></Error></soap:Body>';
        HTTPResponse res = new HTTPResponse();
        res.setBody(xmlTemplate);
        return res;
    }
    // 予約の管理ID情報を設定する
    public static string setManagerDataId(String managerId) {
        // 2016/06/21 管理ID重複回避対応 BEGIN
        String retManagerId = CommUtils.nullToBlank(managerId).removeStart(SERVICE_KEY + '_');
        if (retManagerId.indexOf('_') >= 0) {
            // UUIDコード設定されている場合、[_]でSPLITして、２番目のコードは実際の管理コード
            String[] manangerIds = retManagerId.split('_');
            retManagerId = manangerIds[1];
        }
        return retManagerId;
    }
    // 予約の管理IDを返却する
    public static string getManagerDataId(String managerId) {
        // 2016/06/21 管理ID重複回避対応 BEGIN
        return SERVICE_KEY + '_' + Commutils.getGUID() + '_' + CommUtils.nullToBlank(managerId);
    }
    // レスポンスの共通処理を行う
    private static JR_ResultInfoItem commRepProcess(String strXmlBody, String key) {
        JR_ResultInfoItem rep = new JR_ResultInfoItem();
         // 予想外のエラーが発生する場合、エラー設定する
        if (strXmlBody.indexOfIgnoreCase(key) < 0 && strXmlBody.indexOfIgnoreCase('<Error>') < 0) {
            rep = new JR_ResultInfoItem();
            rep.setFail(strXmlBody);
            return rep;
        }
        if (strXmlBody.indexOfIgnoreCase('<Error>') >= 0)  {
            Dom.Document doc = new Dom.Document();
            doc.load(strXmlBody);
            Dom.XmlNode root = doc.getRootElement();
            return new JR_ResultInfoItem(root);
        }
        Dom.Document doc = new Dom.Document();
        doc.load(strXmlBody);
        Dom.XmlNode root = doc.getRootElement();
        String rootNodeName = root.getName();
        for (Dom.XMLNode node : root.getChildElements()) {
            // タグ名
            String nodeName = node.getName();
            if (nodeName == 'ResultInformation') {
                return new JR_ResultInfoItem(node);
            }
        }
        return rep;
    }
    // 6.1 Response
    public class SelectBookingReply {
        public SelectBookingReply(){}
        public SelectBookingReply(String strXmlBody) {
            strXmlBody = strXmlBody.substringBetween('<soap:Body>','</soap:Body>');
            strXmlBody = strXmlBody.replace('xsi:nil="true"','');
            commonResponse  = commRepProcess(strXmlBody,'SelectBookingReply');
            // 取得成功の場合
            if (commonResponse.isSuccess) {
                Dom.Document doc = new Dom.Document();
                doc.load(strXmlBody);
                Dom.XmlNode root = doc.getRootElement();
                String rootNodeName = root.getName();
                for (Dom.XMLNode node : root.getChildElements()) {
                    // タグ名
                    String nodeName = node.getName();
                    if (nodeName == 'UnconfirmedBookingInformation') {
                        GetRetNumber = CommUtils.nullToZero(CommXmlUtils.getChildElementByName(node, 'NumberOfUnconfirmedBooking'));
                        GetBookingID = CommUtils.nullToBlank(CommXmlUtils.getChildElementByName(node, 'GetBookingID'));
                    }
                } 
            }
        }
        // 共通戻る結果
        public JR_ResultInfoItem commonResponse{get; set;}
        // 未確認予約情報
        public Decimal GetRetNumber{get; private set;}// 未確認予約件数
        public String GetBookingID{get; private set;}// 予約取得 ID
        public Boolean isHaveData() {//予約データ存在チェック
            return (commonResponse.isSuccess && (CommUtils.nullToZero(GetRetNumber) > 0) && !CommUtils.isBlank(GetBookingID));
        }
    }
    // 6.2 Response
    public class GetBookingReply {
        public GetBookingReply(){}
        public GetBookingReply(String strXmlBody) {
            strXmlBody = strXmlBody.substringBetween('<soap:Body>','</soap:Body>');
            strXmlBody = strXmlBody.replace('xsi:nil="true"','');
            commonResponse  = commRepProcess(strXmlBody,'GetBookingReply');
            // 取得成功の場合
            if (commonResponse.isSuccess) {
                booingXml = new List<String>();
                // BookingのXML分割する
		        Integer lPos = strXmlBody.indexOf('<Booking');
		        Integer rPos = strXmlBody.lastIndexOf('</Booking>');
		        if (lPos > 0 && rPos > 0) {
		            String bodyXml = strXmlBody.substring(lPos,rPos);
		            String[] strBookinfLst = bodyXml.split('</Booking>');
		            for (String singBooking : strBookinfLst) {
		                if (CommUtils.isBlank(singBooking)) continue;
		                booingXml.add(singBooking+'</Booking>');
		            }
		        }
            }
        }
        // 共通戻る結果
        public JR_ResultInfoItem commonResponse{get; set;}
        // 未確認予約情報
        public List<String> booingXml{get;private set;}
    }
    // 6.3 Response
    public class ConfirmBookingReply {
        public ConfirmBookingReply(){}
        public ConfirmBookingReply(String strXmlBody) {
            strXmlBody = strXmlBody.substringBetween('<soap:Body>','</soap:Body>');
            strXmlBody = strXmlBody.replace('xsi:nil="true"','');
            commonResponse  = commRepProcess(strXmlBody,'ConfirmBookingReply');
        }
        // 共通戻る結果
        public JR_ResultInfoItem commonResponse{get; set;}
    }
    
    // 6.4. Reponse 在庫調整の返却情報
    public class InventorySettingReply {
        public InventorySettingReply(){}
        public InventorySettingReply(String strXmlBody) {
            strXmlBody = strXmlBody.substringBetween('<soap:Body>','</soap:Body>');
            strXmlBody = strXmlBody.replace('xsi:nil="true"','');
	        commonResponse  = commRepProcess(strXmlBody,'InventorySettingReply');
	        // 共通のエラーコードがない場合、一番目のエラーコードを設定する
	        if (!commonResponse.isSuccess && CommUtils.isBlank(commonResponse.errorDescription)) {
	            commonResponse.errorDescription = getFirstErrorCode(strXmlBody);
	        }
	        // 日別エラーコードを格納する
	        dataErrMap = new map<date,string>();
	        parseDateError(strXmlBody);
        }
        // 共通戻る結果
        public JR_ResultInfoItem commonResponse{get; set;}
        // 更新在庫情報リスト配下で最初に出現するエラーコードを取得する
        private string getFirstErrorCode(string xml) {
            if (xml.indexof('<InventorySettingList>') > 0) {
                xml = xml.substringBetween('<InventorySettingList>','</InventorySettingList>');
                if (xml.indexOf('<ErrorCode>') > 0) {
                    String errcode = xml.substringBetween('<ErrorCode>','</ErrorCode>');
                    if (!CommUtils.isBlank(errcode)) return errcode;
                }
            }
            return null;
        }
        // 日別エラー情報をPARSE処理
        private void parseDateError(String xml) {
            if (xml.indexof('<InventorySettingList>') > 0) {
                xml = xml.substringBetween('<InventorySettingList>','</InventorySettingList>');
                xml = '<root>'+xml+'</root>';
				Dom.Document doc = new Dom.Document();
				doc.load(xml);
				Dom.XmlNode root = doc.getRootElement();
				for(Dom.XMLNode node : root.getChildElements()) {
					string xmlTagName = node.getName();
					if (xmlTagName == 'SettingDateList') {
						String errcode = '';
						Date errdt = null;
						Dom.XmlNode errcodeNode = node.getChildElement('ErrorCode', null);
						if (errcodeNode != null) errcode = CommUtils.nullToBlank(errcodeNode.getText());
						Dom.XmlNode errdateNode = node.getChildElement('Date', null);
						if (errdateNode != null) errdt = Commutils.stringToDate(errdateNode.getText());	
						if (CommUtils.isBlank(errcode) || errdt == null) continue;
						dataErrMap.put(errdt,errcode);
					}
				}
            }
        }
        // 日別エラーコード格納
        public map<date,string> dataErrMap{get;private set;}
    }

    // 6.5 Response 部屋マスタ取得
    public class JR_GetRoomTypeReply {
        //public JR_GetRoomTypeReply(){}
        public JR_GetRoomTypeReply(String strXmlBody) {
            roomTypeList = new list<JR_RoomTypeItem>();
            strXmlBody = strXmlBody.substringBetween('<soap:Body>','</soap:Body>');
            strXmlBody = strXmlBody.replace('xsi:nil="true"','');
            commonResponse  = commRepProcess(strXmlBody,'GetRoomTypeReply');
            // 取得成功の場合
            if(commonResponse.isSuccess) {
                Dom.Document doc = new Dom.Document();
                doc.load(strXmlBody);
                Dom.XmlNode root = doc.getRootElement();
                String rootNodeName = root.getName();
                for (Dom.XMLNode node : root.getChildElements()) {
                    // タグ名
                    String nodeName = node.getName();
                    if (nodeName == 'RoomType') {
                        roomTypeList.add(new JR_RoomTypeItem(node));
                    }
                }
            }
        }
        // 共通戻る結果
        public JR_ResultInfoItem commonResponse{get;set;}
        public list<JR_RoomTypeItem> roomTypeList{get;set;}
    }
    public class JR_RoomTypeItem {
        public JR_RoomTypeItem(Dom.XMLNode node) {
            SalesOfficeCompanyCode = CommXmlUtils.getChildElementByName(node, 'SalesOfficeCompanyCode');
            SalesOfficeCompanyName = CommXmlUtils.getChildElementByName(node, 'SalesOfficeCompanyName');
            RoomTypeCode = CommXmlUtils.getChildElementByName(node, 'RoomTypeCode');
            RoomTypeName = CommXmlUtils.getChildElementByName(node, 'RoomTypeName');
        }
        public String SalesOfficeCompanyCode{get;set;}
        public String SalesOfficeCompanyName{get;set;}
        public String RoomTypeCode{get;set;}
        public String RoomTypeName{get;set;}
    }
    // 共通結果クラス
    public class JR_ResultInfoItem {
        public JR_ResultInfoItem(Dom.XMLNode commRes) {
	        Dom.XMLNode codeField = commRes.getChildElement('ResultCode', null);
	        Dom.XMLNode detailField = commRes.getChildElement('DetailedInformation', null);
	        if (codeField != null) failureReason = CommUtils.nullToBlank(codeField.getText());
	        if (detailField != null) {
	            Dom.XMLNode detailCodeField = detailField.getChildElement('ErrorCode', null);
	            if (detailCodeField != null) errorDescription= CommUtils.nullToBlank(detailCodeField.getText());
	        } 
        }
	    public JR_ResultInfoItem() {}
	    public void setIsSuccess() { failureReason = '0'; }
	    public String failureReason{get;set;}
	    public String errorDescription{get;set;}
	    public Boolean isSuccess{get{return failureReason == '0';}}
	    public override string toString() {
	        return (CommUtils.nullToblank('failureReason:' +failureReason + ' errorDescription:' + errorDescription));
	    }
	    public void setFail(String errMsg) {
	        failureReason = 'UNKNOWN';
	        errorDescription = CommUtils.nullToBlank(errMsg).stripHtmlTags();
	    }
    }
	//salesforce http call soap
	private HTTPResponse sendRequest(String reqXml, String endPoint) {
		// create the request and get the response
		Http h = new Http();
		HttpRequest req = new HttpRequest();
		req.setMethod('POST');
		req.setTimeout(COMMON_CALL_TIME_OUT_VALUE);
		req.setHeader('Content-Type', 'text/xml; charset=utf-8');
		req.setEndpoint(endPoint);
		req.setBody(reqXml);
		HttpResponse res = h.send(req);
		if (res.getStatusCode() != 200) {
		  throw new CommException('Request Error:'+res.getStatus());
		}
		return res;
	}
}