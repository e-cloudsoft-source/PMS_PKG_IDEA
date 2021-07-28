/**
* Bookingサイトエンジン機能
* 2019/02/28 ブッキングエンジンは多言語対応
* 2019/11/11 室販売方法の対応（4. プラン情報取得ー＞PlanPriceListー＞RoomPriceタグ追加）
**/
@RestResource(urlMapping='/pmsservice/V1/*')
global with sharing class WS_BookingEngineService {
    // 2017/12/06 性能改善 BEGIN
    // ログ出力の最大件数
    private static Integer logMaxFils;
    // 2017/12/06 性能改善 END
   	@HttpPost	
	global static void doPost() {
		// 指定のXMLからParseして、予約情報を取り込みを行う
		RestRequest req = RestContext.request;
		// サービス名を取得する
		String serviceName = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        Blob bodyString = req.requestBody;
        String reqXml = CommUtils.nullToBlank(bodyString.toString());
        // 2017/12/06 性能改善 BEGIN
        WS_ServiceConfigHelp.COMMCONFIG wsConfig = WS_ServiceConfigHelp.getCommConfigOnly();
        logMaxFils = wsConfig.logMaxFiles;
        // 2017/12/06 性能改善 END
        // 3. 部屋情報取得
        if (serviceName == SERVICE_NAME.getroomtypelist.name()) {
        	RestContext.response.responseBody = Blob.valueOf(getroomtypelistService(reqXml));
        } 
        // 4. プラン情報取得
        else if (serviceName == SERVICE_NAME.getplanlist.name()) {
        	RestContext.response.responseBody = Blob.valueOf(getPlanListService(reqXml));
        } 
        // 5. 在庫情報取得
        else if (serviceName == SERVICE_NAME.getroomtypeinventorylist.name()) {
        	RestContext.response.responseBody = Blob.valueOf(getroomtypeinventorylistService(reqXml));
        }
        // 6. 予約登録
        else if (serviceName == SERVICE_NAME.createBooking.name()) {
        	RestContext.response.responseBody = Blob.valueOf(createBookingService(reqXml));
        }
        // 7. 予約情報取得
        else if (serviceName == SERVICE_NAME.getbookinglist.name()) {
        	RestContext.response.responseBody = Blob.valueOf(getbookinglistSerivce(reqXml));
        }
        // 8. 見積結果取得
        else if (serviceName == SERVICE_NAME.getEstimateInfo.name()) {
        	RestContext.response.responseBody = Blob.valueOf(getEstimateInfoService(reqXml));
        }
        else {
        	WS_ResultInfo rs = new WS_ResultInfo('E998','処理対象外...');
        	RestContext.response.responseBody = Blob.valueOf(rs.toXml());
        }
       
	}
	// 2020/09/12 DEBUG機能改善対応 By WSQ BEGIN
	private static String getTraceLog(Exception e) {
		return (e.getMessage() + '¥n' + e.getStackTraceString());
	}
	// 2020/09/12 DEBUG機能改善対応 By WSQ END
	private static final String MSG_E001 = '抽出条件設定不正';
	private static final String MSG_E002 = '照会期間不正';
	//**************************************************
	// 3. 部屋情報取得
	//**************************************************
	class RoomTypeListParam {
		public RoomTypeListParam(Dom.XmlNode root) {
			// 店舗コード情報を取得する
			Dom.XmlNode CommonRequestField = root.getChildElement('CommonRequest', null);
			ShopCode = getChildElementByName(CommonRequestField, 'ShopCode');
			// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
			Lang = getChildElementByName(CommonRequestField, 'Lang');
			// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
			// 抽出条件
			Dom.XmlNode extrField = root.getChildElement('RoomTypeInfo', null);
			if (extrField != null) {
				DataType = getChildElementByName(extrField, 'DataType');
				// 2018/05/02 集計対象外フラグ追加対応 BEGIN
				SumTargetOnly = getChildElementByName(extrField, 'SumTargetOnly');
				// 2018/05/02 集計対象外フラグ追加対応 END
			}
		}
		// 店舗コード
		String ShopCode{get;set;}
		// 取得する部屋のタイプ
		// 0：指定店舗の部屋タイプをすべて取得
		// 1：指定店舗の部屋タイプコードありのみ
		String DataType{get;set;}
		// 2018/05/02 集計対象外フラグ追加対応 BEGIN
		String SumTargetOnly{get;set;}
		public Boolean isTargetOnly() {
			return (SumTargetOnly == '1');
		}
		// 2018/05/02 集計対象外フラグ追加対応 END
		public String validata() {
			String errMsg = '';
			// 
			if (CommUtils.isBlank(DataType) || (DataType != '0' && DataType != '1')) {
				errMsg = MSG_E001 + ':'+this;
			}
			return errMsg;
 		}
 		// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
 		String Lang{get;set;}
 		// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
	}
	@TestVisible private static string getroomtypelistService(String reqXml) {
		//System.debug(loggingLevel.INFO,'---------:::::::::BEGIN:::::::::---------'+reqXml);
		CommLogUtils log = initLog();
		log.write_method_start('getroomtypelistService');
		log.write_log('reqXml：'+reqXml);
		WS_ResultInfo rs = new WS_ResultInfo();
		String repxml = '';
		String roomTypeInfoXml = '';
		try {
			// 取得のリクエストXMLを会席する
			Dom.Document doc = new Dom.Document();
			doc.load(reqXml);
			Dom.XMLNode rootNode = doc.getRootElement();
			// リクエスト情報解析する
			RoomTypeListParam reqInfo = new RoomTypeListParam(rootNode);
			// 有効チェック
			String validataMsg = reqInfo.validata();
			if (!CommUtils.isBlank(validataMsg)) {
				rs = new WS_ResultInfo('E0001',validataMsg);
			}
			String shopCode = CommUtils.nullToBlank(reqInfo.ShopCode);
			String dataType = reqInfo.DataType;
			// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
			String lang = reqInfo.Lang;
			// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
			repXml = '<GetRoomTypeListRS><CommonResponse>$$_CommonResponse_$$</CommonResponse><RoomTypeList>$$_RoomTypeList_$$</RoomTypeList></GetRoomTypeListRS>';
			if (rs.IsSuccess) {
				// SFの部屋タイプリストを取得
				// 2018/04/27 部屋情報取得APIに、部屋タイプの説明と画像URLを追加 zyz BEGIN
				// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
				//String queryStr = 'select id, name, RoomTypeCode__c,RoomTypeName__c,ShopInfoRef__r.ShopCode__c,Description__c,Seq__c,SumNotApplicableFlg__c,(Select Name, PropValue__c From RoomTypePropRef__r) from TypeOfRooms__c Where ShopInfoRef__r.ShopCode__c = :shopCode ';
				String queryStr = 'select id, name, RoomTypeCode__c,RoomTypeName__c,ShopInfoRef__r.ShopCode__c,Description__c,Seq__c,SumNotApplicableFlg__c,EnRoomTypeName__c,EnDescription__c,(Select Name, PropValue__c,EnPropValue__c, EnName__c From RoomTypePropRef__r) from TypeOfRooms__c Where ShopInfoRef__r.ShopCode__c = :shopCode ';
				// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
				// 2018/04/27 部屋情報取得APIに、部屋タイプの説明と画像URLを追加 zyz END
				// 2018/05/02 集計対象外フラグ追加対応 BEGIN
				if (reqInfo.isTargetOnly()) queryStr +=' And SumNotApplicableFlg__c != true ';
				// 2018/05/02 集計対象外フラグ追加対応 END
				if (dataType == '1') queryStr +=' And RoomTypeCode__c != null ';
				// 2018/02/12 部屋属性機能追加 BEGIN
                List<TypeOfRooms__c> roomTypelist = DataBase.query(queryStr);
                // 2018/04/27 部屋情報取得APIに、部屋タイプの説明と画像URLを追加 zyz BEGIN
                Organization currOrg = [Select IsSandbox,Id from Organization where id = :userInfo.getOrganizationId()];
                String photoUrl = 'https://login.salesforce.com';
                if (currOrg.IsSandbox) photoUrl = 'https://test.salesforce.com';
                photoUrl +='/servlet/servlet.ImageServer?key=$_KEYWORD_$&id=$_FILEID_$&oid='+currOrg.id;
                photoUrl = photoUrl.escapeXml();
                
                set<String> roomTypeSeqs = new set<String>();
                for (TypeOfRooms__c RT : roomTypelist) if (!CommUtils.isBlank(CommUtils.nullToBlank(RT.Seq__c))) roomTypeSeqs.add(CommUtils.nullToBlank(RT.Seq__c));
                map<string, list<document>> roomTypeSeqToIdMap = new map<string, list<document>>();
                if (!roomTypeSeqs.isEmpty()) {
                    list<document> docRTs = [select id,name,Keywords from document where Folder.DeveloperName = 'BookingApiPhotoRoomType' and name in :roomTypeSeqs and IsPublic = true order by createddate];
                    for(document pdoc : docRTs) {
                        string roomTypeSeq = commutils.nulltoBlank(pdoc.name);
                        if (!roomTypeSeqToIdMap.containsKey(roomTypeSeq)) roomTypeSeqToIdMap.put(roomTypeSeq, new list<document>());
                        roomTypeSeqToIdMap.get(roomTypeSeq).add(pdoc);
                    }
                }
                // 2018/04/27 部屋情報取得APIに、部屋タイプの説明と画像URLを追加 zyz END
                // 該当部屋タイプの部屋情報一覧を取得する
                set<Id> roomTypeIds = new set<Id>();
                map<Id,List<Room__c>> roomsOfRoomTypeMap = new map<Id, List<Room__c>>();
                for (TypeOfRooms__c roomType : roomTypelist) {
                    roomTypeIds.add(roomType.Id);
                }
                // 2018/04/27 部屋情報取得APIに、部屋の説明と画像URLを追加 zyz BEGIN
                set<String> roomSeqs = new set<String>();
                map<string, list<document>> roomSeqToIdMap = new map<string, list<document>>();
                // 2018/04/27 部屋情報取得APIに、部屋の説明と画像URLを追加 zyz END
                if (!roomTypeIds.isEmpty()) {
	                // 部屋属性情報を取得する
	                // 2018/04/27 部屋情報取得APIに、部屋の説明と画像URLを追加 zyz BEGIN
	                // 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
	                //List<Room__c> rooms = [Select Seq__c, Name, TypeRoomRef__c, Field4__c, (Select Name,PropValue__c From RoomPropRef__r) From Room__c Where TypeRoomRef__c in :roomTypeIds Order by Seq__c];
	                List<Room__c> rooms = [Select Seq__c, Name, TypeRoomRef__c, Field4__c,EnName__c,EnField4__c, (Select Name,PropValue__c,EnPropValue__c,EnName__c From RoomPropRef__r) From Room__c Where TypeRoomRef__c in :roomTypeIds Order by Seq__c];
					// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
	                // 2018/04/27 部屋情報取得APIに、部屋の説明と画像URLを追加 zyz END
	                for (Room__c room : rooms) {
	                    // 2018/04/27 部屋情報取得APIに、部屋の説明と画像URLを追加 zyz BEGIN
	                    if (!CommUtils.isBlank(CommUtils.nullToBlank(room.Seq__c))) roomSeqs.add(CommUtils.nullToBlank(room.Seq__c));
	                    // 2018/04/27 部屋情報取得APIに、部屋の説明と画像URLを追加 zyz END
	                    Id rtypeId = room.TypeRoomRef__c;
	                    if (!roomsOfRoomTypeMap.containsKey(rtypeId)) roomsOfRoomTypeMap.put(rtypeId, new List<Room__c>());
	                    roomsOfRoomTypeMap.get(rtypeId).add(room);
	                }
	                // 2018/04/27 部屋情報取得APIに、部屋の説明と画像URLを追加 zyz BEGIN
	                if (!roomSeqs.isEmpty()) {
	                    list<document> docRSs = [select id,name,keywords from document where Folder.DeveloperName = 'BookingApiPhotoRoom' and name in :roomSeqs and IsPublic = true order by createddate];
	                    for(document pdoc : docRSs) {
	                        string roomSeq = commutils.nulltoBlank(pdoc.name);
	                        if (!roomSeqToIdMap.containsKey(roomSeq)) roomSeqToIdMap.put(roomSeq, new list<document>());
	                        roomSeqToIdMap.get(roomSeq).add(pdoc);
	                    }
	                }
	                // 2018/04/27 部屋情報取得APIに、部屋の説明と画像URLを追加 zyz END
                }
                for (TypeOfRooms__c roomType : roomTypelist) {
				// 既存情報でXMLを作成する
				//for (TypeOfRooms__c roomType : DataBase.query(queryStr)) {
					//roomTypeInfoXml += getroomtypelistServiceRepItem(roomType);
					List<Room__c> wkRooms = roomsOfRoomTypeMap.get(roomType.Id);
					// 2018/04/27 部屋情報取得APIに、部屋タイプの説明と画像URLを追加 zyz BEGIN
					// 2018/04/27 部屋情報取得APIに、部屋の説明と画像URLを追加 zyz BEGIN
					//roomTypeInfoXml += getroomtypelistServiceRepItem(roomType, wkRooms);
					// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
					//roomTypeInfoXml += getroomtypelistServiceRepItem(roomType, wkRooms, photoUrl, roomTypeSeqToIdMap, roomSeqToIdMap);
					roomTypeInfoXml += getroomtypelistServiceRepItem(roomType, wkRooms, photoUrl, roomTypeSeqToIdMap, roomSeqToIdMap, lang);
					// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
					// 2018/04/27 部屋情報取得APIに、部屋の説明と画像URLを追加 zyz END
					// 2018/04/27 部屋情報取得APIに、部屋タイプの説明と画像URLを追加 zyz END
				}
				// 2018/02/12 部屋属性機能追加 END
			}
		} catch (Exception e) {
			// 予想以外の異常が発生する場合
			// 2020/09/12 DEBUG機能改善対応 By WSQ BEGIN
			//rs = new WS_ResultInfo('E999',e.getMessage());
			rs = new WS_ResultInfo('E999',getTraceLog(e));
			// 2020/09/12 DEBUG機能改善対応 By WSQ END
			log.write_error(e.getStackTraceString());
		}
		repxml = repxml.replace('$$_RoomTypeList_$$',roomTypeInfoXml);
		repxml = repxml.replace('$$_CommonResponse_$$',rs.toXml());
		// 2017/12/06 性能改善 BEGIN
		//log.write_log('repxml：'+repxml);
		// 2017/12/06 性能改善 END		
		log.write_method_end();
		// 2017/12/06 性能改善 BEGIN
		CommLogUtils.saveLogToDb(log.getAllLog(),CommLogUtils.LogType.WSAPI,logMaxFils);
		// 2017/12/06 性能改善 END
		return repxml;
	}
	// 2018/04/27 部屋情報取得APIに、部屋タイプの説明と画像URLを追加 zyz BEGIN
	// 2018/04/27 部屋情報取得APIに、部屋の説明と画像URLを追加 zyz BEGIN
	//private static string getroomtypelistServiceRepItem(TypeOfRooms__c roomType, List<Room__c> rooms) {
	// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
	//private static string getroomtypelistServiceRepItem(TypeOfRooms__c roomType, List<Room__c> rooms, String photoUrlXmlTemp, map<string, list<document>> roomTypeSeqToIdMap, map<string, list<document>> roomSeqToIdMap) {
	private static string getroomtypelistServiceRepItem(TypeOfRooms__c roomType, List<Room__c> rooms, String photoUrlXmlTemp, map<string, list<document>> roomTypeSeqToIdMap, map<string, list<document>> roomSeqToIdMap, String lang) {
		Boolean isEngLangFlg = isEngLang(lang);
	// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
	// 2018/04/27 部屋情報取得APIに、部屋の説明と画像URLを追加 zyz END
	// 2018/04/27 部屋情報取得APIに、部屋タイプの説明と画像URLを追加 zyz END
		// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
		//String roomTypeName = CommUtils.nullToBlank(roomType.RoomTypeName__c).escapeXml();
		String roomTypeName = CommUtils.nullToBlank(isEngLangFlg ? roomType.EnRoomTypeName__c : roomType.RoomTypeName__c).escapeXml();
		// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
		String roomTypeCode = CommUtils.nullToBlank(roomType.RoomTypeCode__c).escapeXml();
		String shopCode = CommUtils.nullToBlank(roomType.ShopInfoRef__r.ShopCode__c).escapeXml();
		// 2018/04/27 部屋情報取得APIに、部屋タイプの説明と画像URLを追加 zyz BEGIN
		// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
		//String roomTypeMemo = CommUtils.nullToBlank(roomType.Description__c).escapeXml();
		String roomTypeMemo = CommUtils.nullToBlank(isEngLangFlg ? roomType.EnDescription__c : roomType.Description__c).escapeXml();
		// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
		String repItem = '<RoomTypeInfo><RoomTypeName>' + roomTypeName + '</RoomTypeName><RoomTypeCode>'+roomTypeCode+'</RoomTypeCode><ShopCode>'+shopCode+'</ShopCode>$$_RTEXPLAIN_$$$$_ROOMTYPEIMG_$$$$_SumTargetOnly_$$$$_RTPropInfo_$$$$_ROOMINFO_$$</RoomTypeInfo>';
		// 部屋タイプの説明情報
		repItem = repItem.replace('$$_RTEXPLAIN_$$', joinTagXml('Memo',roomTypeMemo));
		// 部屋タイプの画像URL情報設定する
		String roomTypeXml = '';
		if (roomTypeSeqToIdMap.containsKey(CommUtils.nullToBlank(roomType.Seq__c))) {
		    for (document doc : roomTypeSeqToIdMap.get(CommUtils.nullToBlank(roomType.Seq__c))) {
		        roomTypeXml += joinTagXml('ImgURL',photoUrlXmlTemp.replace('$_FILEID_$',doc.Id)
		        		.replace('$_KEYWORD_$',CommUtils.nullToBlank(doc.keywords).escapeXml()));
			}
		}
		repItem = repItem.replace('$$_ROOMTYPEIMG_$$', roomTypeXml);
		// 2018/04/27 部屋情報取得APIに、部屋タイプの説明と画像URLを追加 zyz END
		// 2018/05/02 集計対象外フラグ追加対応 BEGIN
		repItem = repItem.replace('$$_SumTargetOnly_$$',joinTagXml('SumTargetOnly',(roomType.SumNotApplicableFlg__c != true ? '0' : '1')));
		// 2018/05/11 部屋タイプ属性情報返却できるように改善 BEGIN
        String rtProps = '';
        for (RoomTypeProp__c prop : roomType.RoomTypePropRef__r) {
            // 2018/05/11 属性値項目内容が存在するとき、属性値項目値内容を優先利用する、その以外場合、属性名を利用する
            // 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
            //rtProps += joinTagXml('PropInfo', (CommUtils.isBlank(prop.PropValue__c) ? prop.name : prop.PropValue__c).escapeXml());
            rtProps += joinTagXml('PropInfo', (CommUtils.isBlank(prop.PropValue__c) ? CommUtils.nullToBlank(isEngLangFlg ? prop.EnName__c : prop.name ): CommUtils.nullToBlank(isEngLangFlg ? prop.EnPropValue__c : prop.PropValue__c)).escapeXml());
            // 2019/02/28 ブッキングエンジンは多言語対応 By zh END
        }
        repItem = repItem.replace('$$_RTPropInfo_$$',rtProps);
		// 2018/05/11 部屋タイプ属性情報返却できるように改善 END
		
		// 2018/05/02 集計対象外フラグ追加対応 END
		if (rooms != null) {
		    // 2018/04/27 部屋情報取得APIに、部屋の説明と画像URLを追加 zyz BEGIN
		    String roomTemplate = '<RoomInfo><RoomName>$$_RoomName_$$</RoomName>$$_RoomSeqNo_$$$$_PropInfo_$$$$_RSEXPLAIN_$$$$_ROOMIMG_$$</RoomInfo>';
		    // 2018/04/27 部屋情報取得APIに、部屋の説明と画像URLを追加 zyz END
		    String roomStr = '';
		    for (Room__c r : rooms) {
		        List<String> props = new List<String>();
		        for (RoomProp__c prop : r.RoomPropRef__r) {
		            //props.add(prop.name.escapeXml());
					// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
		            //props.add((CommUtils.isBlank(prop.PropValue__c) ? prop.name : prop.PropValue__c).escapeXml());
		            String val = (CommUtils.isBlank(prop.PropValue__c) ? CommUtils.nullToBlank(isEngLangFlg ? prop.EnName__c : prop.name) : CommUtils.nullToBlank(isEngLangFlg ? prop.EnPropValue__c : prop.PropValue__c)).escapeXml();
		            if(!CommUtils.isBlank(val))props.add(val);
					// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
		        }
		        // 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
		        //roomStr += roomTemplate.replace('$$_RoomName_$$',CommUtils.nullToBlank(r.Name).escapeXml());
		        roomStr += roomTemplate.replace('$$_RoomName_$$',CommUtils.nullToBlank(isEngLangFlg ? r.EnName__c : r.Name).escapeXml());
		        // 2019/02/28 ブッキングエンジンは多言語対応 By zh END
		        String strSeq = CommUtils.nullToBlank(r.Seq__c);
		        if (!CommUtils.isBlank(strSeq)) {
		            roomStr = roomStr.replace('$$_RoomSeqNo_$$','<RoomSeqNo>'+strSeq+'</RoomSeqNo>');
		            // 2018/04/27 部屋情報取得APIに、部屋の説明と画像URLを追加 zyz BEGIN
		            String roomXml = '';
		            if (roomSeqToIdMap.containsKey(strSeq)) {
		                for (document rmdoc : roomSeqToIdMap.get(strSeq)) {
		                    roomXml += joinTagXml('ImgURL',photoUrlXmlTemp.replace('$_FILEID_$',rmdoc.Id)
		                		.replace('$_KEYWORD_$',CommUtils.nullToBlank(rmdoc.keywords).escapeXml()));
		                }
		            }
		            roomStr = roomStr.replace('$$_ROOMIMG_$$', roomXml);
		            // 2018/04/27 部屋情報取得APIに、部屋の説明と画像URLを追加 zyz END
		        } else {
		            roomStr = roomStr.replace('$$_RoomSeqNo_$$', '');
		            // 2018/04/27 部屋情報取得APIに、部屋の説明と画像URLを追加 zyz BEGIN
		            roomStr = roomStr.replace('$$_ROOMIMG_$$', '');
		            // 2018/04/27 部屋情報取得APIに、部屋の説明と画像URLを追加 zyz END
		        }
		        // 2018/04/27 部屋情報取得APIに、部屋の説明と画像URLを追加 zyz BEGIN
		        // 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
		        //String roomMemo = CommUtils.nullToBlank(r.Field4__c).escapeXml();
		        String roomMemo = CommUtils.nullToBlank(isEngLangFlg ? r.EnField4__c : r.Field4__c).escapeXml();
		        // 2019/02/28 ブッキングエンジンは多言語対応 By zh END
		        roomStr = roomStr.replace('$$_RSEXPLAIN_$$',joinTagXml('Memo',roomMemo));
		        // 2018/04/27 部屋情報取得APIに、部屋の説明と画像URLを追加 zyz END
		        if (!props.isEmpty()) {
		            roomStr = roomStr.replace('$$_PropInfo_$$','<PropInfo>'+String.join(props,',')+'</PropInfo>');
		        } else {
		            roomStr = roomStr.replace('$$_PropInfo_$$','');
		        }
		    }
		    repItem = repItem.replace('$$_ROOMINFO_$$',roomStr);
		} else {
		    repItem = repItem.replace('$$_ROOMINFO_$$','');
		}
		return repItem;
	}
	
	//**************************************************
	// 4. プラン情報取得
	//**************************************************
	class PlanListParam {
		public PlanListParam(Dom.XmlNode root) {
			// 店舗コード情報を取得する
			Dom.XmlNode CommonRequestField = root.getChildElement('CommonRequest', null);
			ShopCode = getChildElementByName(CommonRequestField, 'ShopCode');
			// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
			Lang = getChildElementByName(CommonRequestField, 'Lang');
			// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
			// 抽出条件
			Dom.XmlNode extrField = root.getChildElement('ExtractionCondition', null);
			if (extrField != null) {
				ExtractionProcedure = getChildElementByName(extrField, 'ExtractionProcedure');
				RoomTypeCode = getChildElementByName(extrField, 'RoomTypeCode');
				String strSearchDurationFrom = getChildElementByName(extrField, 'SearchDurationFrom');
				if (!CommUtils.isBlank(strSearchDurationFrom)) SearchDurationFrom = CommUtils.stringToDate(strSearchDurationFrom);
				String strSearchDurationTo = getChildElementByName(extrField, 'SearchDurationTo');
				if (!CommUtils.isBlank(strSearchDurationTo)) SearchDurationTo = CommUtils.stringToDate(strSearchDurationTo);
				PlanCode = getChildElementByName(extrField, 'PlanCode');
				AgtPlanNoInclude = getChildElementByName(extrField, 'AgtPlanNoInclude');
				BasePlanDiv = getChildElementByName(extrField, 'BasePlanDiv');
			}
		}
		// 店舗コード
		String ShopCode{get;set;}
		/*
		検索方法を指定する
		「1」：全件検索
		「2」：照会期間で検索（*1）
		「3」：照会期間 AND プランコード（*1）
		*1)の場合、料金見積金額を返信されます、照会期間は31日以内指定して下さい
		*/
		String ExtractionProcedure{get;set;}
		// 部屋タイプコード
		String RoomTypeCode{get;set;}
		// 照会期間FROM
		Date SearchDurationFrom{get;set;}
		// 照会期間TO
		Date SearchDurationTo{get;set;}
		// プランコード
		String PlanCode{get;set;}
		// AGT区分
		String AgtPlanNoInclude{get;set;}
		// ベースプラン区分
		String BasePlanDiv{get;set;}
		//
		///String errMsg{get;set;}
		public String validata() {
			String errMsg = '';
			// 
			if (CommUtils.isBlank(ExtractionProcedure) || 
				(ExtractionProcedure != '1' && ExtractionProcedure != '2' && ExtractionProcedure != '3')) {
				errMsg = MSG_E001 + ':'+this;
			}
			if (ExtractionProcedure == '2' || ExtractionProcedure == '3' ) { 
				if (SearchDurationFrom == null || SearchDurationTo == null || CommUtils.isBlank(RoomTypeCode)) {
					errMsg = MSG_E001 + ':'+this;
				} else if (SearchDurationFrom.daysBetween(SearchDurationTo) >= 31) {
					errMsg = MSG_E002 + ':'+this;
				}
			}
			if (ExtractionProcedure == '3' && CommUtils.isBlank(PlanCode)) return MSG_E001 + ':'+this;
			return errMsg;
 		}
 		// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
 		String Lang{get;set;}
 		// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
	}
	@TestVisible private static string getPlanListService(String reqXml) {
	    CommLogUtils log = initLog();
		log.write_method_start('getPlanListService');
		log.write_log('reqXml：'+reqXml);
		// プラン料金情報を取得する
		String repxml = '<GetPlanListRS><CommonResponse>$$_CommonResponse_$$</CommonResponse><PlanList>$$_PlanList_$$</PlanList></GetPlanListRS>';
		// プラン情報
		// 2017/07/19 プラン有効期限機能追加 by zh BEGIN
		//String PlanInfoTempXml = '<PlanInfo><PlanName>$$_PlanName_$$</PlanName><PlanCode>$$_PlanCode_$$</PlanCode><PlanNo>$$_PlanNo_$$</PlanNo><ShopCode>$$_ShopCode_$$</ShopCode>$$_PlanRangePriceListXml_$$</PlanInfo>';
		// 2018/01/19 プラン詳細情報追加 by zh BEGIN
		//String PlanInfoTempXml = '<PlanInfo><PlanName>$$_PlanName_$$</PlanName><PlanCode>$$_PlanCode_$$</PlanCode><PlanNo>$$_PlanNo_$$</PlanNo><ShopCode>$$_ShopCode_$$</ShopCode><PlanOpenDateTime>$$_PlanOpenDateTime_$$</PlanOpenDateTime><PlanCloseDateTime>$$_PlanCloseDateTime_$$</PlanCloseDateTime>$$_PlanRangePriceListXml_$$</PlanInfo>';
		String PlanInfoTempXml = '<PlanInfo><PlanName>$$_PlanName_$$</PlanName><PlanCode>$$_PlanCode_$$</PlanCode><PlanNo>$$_PlanNo_$$</PlanNo><ShopCode>$$_ShopCode_$$</ShopCode><PlanOpenDateTime>$$_PlanOpenDateTime_$$</PlanOpenDateTime><PlanCloseDateTime>$$_PlanCloseDateTime_$$</PlanCloseDateTime>$$_PlanExtPropXml_$$$$_PlanRangePriceListXml_$$</PlanInfo>';
		// 2018/01/19 プラン詳細情報追加 by zh END
		// 2017/07/19 プラン有効期限機能追加 by zh END
		// プラン料金帯リスト
		String PlanRangePriceListTempXml = '<PlanRangePriceList><PlanRangePriceName>$$_PlanRangePriceName_$$</PlanRangePriceName>$$_PlanPriceListXml_$$</PlanRangePriceList>';
		// 人数分プラン料金リスト
		// 2019/11/11 室販売方法の対応 WSQ BEGIN
		//String PlanPriceListTempXml = '<PlanPriceList><PriceCount>$$_PriceCount_$$</PriceCount><PlanPrice>$$_PlanPrice_$$</PlanPrice></PlanPriceList>';
		String PlanPriceListTempXml = '<PlanPriceList><RoomPrice>$$_RoomPrice_$$</RoomPrice><PriceCount>$$_PriceCount_$$</PriceCount><PlanPrice>$$_PlanPrice_$$</PlanPrice></PlanPriceList>';
		// 2019/11/11 室販売方法の対応 WSQ END
		// プラン情報の全部情報を格納する
		String planInfoXml = '';
		// 返却値
		WS_ResultInfo rs = new WS_ResultInfo();
		try {
			Dom.Document doc = new Dom.Document();
			doc.load(reqXml);
			Dom.XMLNode rootNode = doc.getRootElement();
			// リクエスト情報解析する
			PlanListParam reqInfo = new PlanListParam(rootNode);
			// 有効チェック
			String validataMsg = reqInfo.validata();
			if (!CommUtils.isBlank(validataMsg)) {
				rs = new WS_ResultInfo('E0001',validataMsg);
			}
			// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
			String lang = reqInfo.Lang;
			Boolean isEngLangFlg = isEngLang(lang);
			// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
			if (rs.IsSuccess) {
				// SFの部屋タイプリストを取得
				// ラクレートマスタ情報を取得する
				// 部屋タイプ　＋　店舗コード　＋　日付により、
				// ラクレート明細情報を取得する
				Map<String,list<RackRateTable__c>> rackRateMstMap = new Map<String,list<RackRateTable__c>>();
				
				for (RackRateTable__c racklst:[select id,name,Tier__c,Price__c,Persons__c,RoomTypeRel__r.RoomTypeCode__c from RackRateTable__c 
												where RoomTypeRel__r.RoomTypeCode__c = :reqInfo.RoomTypeCode AND RoomTypeRel__r.ShopInfoRef__r.ShopCode__c = :reqInfo.shopCode
												Order by Tier__c, Persons__c asc]){
					if(!rackRateMstMap.containsKey(racklst.Tier__c)) rackRateMstMap.put(racklst.Tier__c,new List<RackRateTable__c>());
					rackRateMstMap.get(racklst.Tier__c).add(racklst);
				}
				List<String> tierLst = new List<String>();
				tierLst.addAll(rackRateMstMap.keySet());
				tierLst.sort();
				// 店舗コード　
				String shopCode = CommUtils.nullToBlank(reqInfo.shopCode);
				// 照会期間FROM
				Date SearchDurationFrom = reqInfo.SearchDurationFrom;
				// 照会期間TO
				Date SearchDurationTo = reqInfo.SearchDurationTo;
				// プラン定義情報を取得する
				String prodTypeRp = CommConst.PROD_ACTION_TYPE_RP;
				// 2018/03/28 客户自定义API追加 WGCH BEGIN
				String defPropRefApiStr = ',PropRef__r.LeadPreEndTime__c, PropRef__r.LeadPreBegTime__c, PropRef__r.LeadCanEndDate__c, PropRef__r.LeadCanBegDate__c, PropRef__r.CheckOutTime__c, PropRef__r.CheckInEndTime__c, PropRef__r.LeadPreEndDays__c, PropRef__r.LeadUpdDays__c, PropRef__r.PlanCategory__c '+
					                      ',PropRef__r.CheckInBegTime__c, PropRef__r.Note__c, PropRef__r.MinNight__c, PropRef__r.PlanType__c, PropRef__r.MaxNight__c, PropRef__r.LeadCancelTime__c, PropRef__r.MaxChildren__c, PropRef__r.MinChildren__c, PropRef__r.CancelRule__c, PropRef__r.LeadUpdTime__c '+
					                      ',PropRef__r.LeadCancelDays__c, PropRef__r.MaxRooms__c, PropRef__r.MinRooms__c, PropRef__r.LeadPreBegDays__c, PropRef__r.Meal__c,PropRef__c ';
				Set<String> newPropApiSet = new Set<String>();
				Set<String> defPropRefApiSet = new Set<String>();
				for(String defApi : defPropRefApiStr.split(',')){
					if(!CommUtils.isBlank(defApi)) defPropRefApiSet.add(CommUtils.nullToBlank(defApi).toLowerCase());
				}
				// 2018/05/10 プラン属性へカスタム項目を追加することで名も返却改善 WGCH BEGIN
				Map<String, Schema.DescribeFieldResult> modelDeafaultValuesMaps = CommSqlUtils.getAllFieldLst(PlanProp__c.sObjectType,false,true);
				// 2018/05/10 プラン属性へカスタム項目を追加することで名も返却改善 WGCH END
				//获取所有API字段方法
				Map<String, String> propRefMaps = CommSqlUtils.getCustomeFieldLst(PlanProp__c.sObjectType,false);
				for(String api : propRefMaps.keySet()){
					String propRefKey = ('PropRef__r.' + api).toLowerCase();
					if(!defPropRefApiSet.contains(propRefKey)){
						defPropRefApiStr += ',' + propRefKey;
						// 2018/05/10 プラン属性へカスタム項目を追加することで名も返却改善 WGCH BEGIN
						Schema.DescribeFieldResult dr = modelDeafaultValuesMaps.get(CommUtils.nullToBlank(api).toLowerCase());
						if(dr.getType() == Schema.DisplayType.REFERENCE){
							String propRefNameKey = propRefKey.replace('__c','__r.Name');
							defPropRefApiStr += ',' + propRefNameKey;
						}
						// 2018/05/10 プラン属性へカスタム項目を追加することで名も返却改善 WGCH END
						newPropApiSet.add(api);
					}
				}
				// 2018/05/10 プラン属性へカスタム項目を追加することで名も返却改善 WGCH BEGIN
				/*
				Map<String, Schema.DescribeFieldResult> modelDeafaultValuesMaps = null;
				if(!newPropApiSet.isEmpty()) modelDeafaultValuesMaps = CommSqlUtils.getAllFieldLst(PlanProp__c.sObjectType,false,true);
				*/
				// 2018/05/10 プラン属性へカスタム項目を追加することで名も返却改善 WGCH END
				// 2018/03/28 客户自定义API追加 WGCH END
				// 2018/01/19 プラン詳細情報追加 by zh BEGIN 
				//String queryStr = 'select id, name, PlanNo__c,Price__c ,BasePlanFlg__c,PackageCode__c,ShopInfoRef__r.ShopCode__c,PlanStartDateandtime__c,Planclosedateandtime__c,(Select AccountMasterRef__c, Price__c From PlanRef__r Where AccountMasterRef__r.ActionType__c = :prodTypeRp ) from Plan__c '+
				String queryStr = 'select id, name, PlanNo__c,Price__c ,BasePlanFlg__c,PackageCode__c,ShopInfoRef__r.ShopCode__c,PlanStartDateandtime__c,Planclosedateandtime__c,(Select AccountMasterRef__c, Price__c From PlanRef__r Where AccountMasterRef__r.ActionType__c = :prodTypeRp ) '+
								  ',Seq__c '+
								  // 2018/03/28 客户自定义API追加 WGCH BEGIN
								  /*
                                  ',PropRef__r.LeadPreEndTime__c, PropRef__r.LeadPreBegTime__c, PropRef__r.LeadCanEndDate__c, PropRef__r.LeadCanBegDate__c, PropRef__r.CheckOutTime__c, PropRef__r.CheckInEndTime__c, PropRef__r.LeadPreEndDays__c, PropRef__r.LeadUpdDays__c, PropRef__r.PlanCategory__c '+
                                  ',PropRef__r.CheckInBegTime__c, PropRef__r.Note__c, PropRef__r.MinNight__c, PropRef__r.PlanType__c, PropRef__r.MaxNight__c, PropRef__r.LeadCancelTime__c, PropRef__r.MaxChildren__c, PropRef__r.MinChildren__c, PropRef__r.CancelRule__c, PropRef__r.LeadUpdTime__c '+
                                  ',PropRef__r.LeadCancelDays__c, PropRef__r.MaxRooms__c, PropRef__r.MinRooms__c, PropRef__r.LeadPreBegDays__c, PropRef__r.Meal__c,PropRef__c '+
                                  */
                                  defPropRefApiStr +
                                   // 2018/03/28 客户自定义API追加 WGCH END
                                  // 2018/03/14 プラン詳細情報追加 BEGIN
                                  ',MealMemo__c '+
                                  // 2018/03/14 プラン詳細情報追加 END
								  // 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
								  ',EnName__c, EnMealMemo__c '+
								  // 2019/02/28 ブッキングエンジンは多言語対応 By zh END
								  'from Plan__c ' +
								  'where IsClosed__c != true And ShopInfoRef__r.ShopCode__c = :shopCode ';
				// 2018/01/19 プラン詳細情報追加 by zh END
				//if (!CommUtils.isBlank(reqInfo.ShopCode)) queryStr += ' And ShopInfoRef__r.ShopCode__c = \'' + String.escapeSingleQuotes(reqInfo.shopCode) + '\'';
				// 期間検索条件を入れる
				if (SearchDurationFrom != null) queryStr += ' And DAY_ONLY(convertTimezone(Planclosedateandtime__c)) >= :SearchDurationFrom';
				if (SearchDurationTo != null) queryStr += ' And DAY_ONLY(convertTimezone(PlanStartDateandtime__c)) <= :SearchDurationTo ';
				// 2017/12/06 性能改善対応 BEGIN
				set<String> planCodeSets = new set<String>();
				List<String> planCodeLst = CommUtils.nullToBlank(reqInfo.PlanCode).split(',');
				for (String cd : planCodeLst) {
				    if (CommUtils.isBlank(cd)) continue;
				    planCodeSets.add(cd);
				} 
				//if (!CommUtils.isBlank(reqInfo.PlanCode)) queryStr += ' And PackageCode__c = \'' + String.escapeSingleQuotes(reqInfo.PlanCode) + '\'';
				if (!planCodeSets.isEmpty()) queryStr += ' And PackageCode__c = :planCodeSets';
				// 2017/12/06 性能改善対応 END
				if (reqInfo.AgtPlanNoInclude == '1') queryStr += ' And client__c = null ';
				if (reqInfo.BasePlanDiv == '1') queryStr += ' And BasePlanFlg__c = true ';
//System.debug(loggingLevel.info, 'queryStr='+queryStr);
                // 2018/01/19 プラン詳細情報追加 by zh BEGIN 
                queryStr += ' Order By Seq__c';
                // 2018/01/19 プラン詳細情報追加 by zh END 
                // 2018/03/28 画像情報はレスポンスに追加対応 BEGIN
                Organization currOrg = [Select IsSandbox,Id from Organization where id = :userInfo.getOrganizationId()];
                String photoUrl = 'https://login.salesforce.com';
                if (currOrg.IsSandbox) photoUrl = 'https://test.salesforce.com';
                photoUrl +='/servlet/servlet.ImageServer?key=$_KEYWORD_$&id=$_FILEID_$&oid='+currOrg.id;
                photoUrl = photoUrl.escapeXml();
                
                List<Plan__c> plans = DataBase.query(queryStr);
                set<String> planNos = new set<String>();
                for (Plan__c plan : plans) if (!CommUtils.isBlank(plan.PlanNo__c)) planNos.add(plan.PlanNo__c);
                map<string, list<document>> planNoToIdMap = new map<string, list<document>>();
                if (!planNos.isEmpty()) {
                    list<document> docs = [select id,name,keywords from document where Folder.DeveloperName = 'BookingApiPhoto' and name in :planNos and IsPublic = true order by createddate];
                    for(document pdoc : docs) {
                        string planno = commutils.nulltoBlank(pdoc.name);
                        if (!planNoToIdMap.containsKey(planno)) planNoToIdMap.put(planno, new list<document>());
                        planNoToIdMap.get(planno).add(pdoc);
                    }
                }
				//String planInfoXml = '';
				//for (Plan__c plan : DataBase.query(queryStr)) {
				for (Plan__c plan : plans) {
				// 2018/03/28 画像情報はレスポンスに追加対応 END
					// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
					//String planName = CommUtils.nullToBlank(plan.Name).escapeXml();
					String planName = CommUtils.nullToBlank(isEngLangFlg ? plan.EnName__c : plan.Name).escapeXml();
					// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
					String planCd = CommUtils.nullToBlank(plan.PackageCode__c).escapeXml();
					String planNo = CommUtils.nullToBlank(plan.PlanNo__c).escapeXml();
					String shopCd = CommUtils.nullToBlank(plan.ShopInfoRef__r.ShopCode__c).escapeXml();
					// 2017/07/19 プラン有効期限機能追加 by zh BEGIN
					String planOpenDateTime = '';
					if (plan.PlanStartDateandtime__c != null) planOpenDateTime = plan.PlanStartDateandtime__c.format('yyyyMMddHHmm').escapeXml();
					String planCloseDateTime = '';
					if (plan.Planclosedateandtime__c != null) planCloseDateTime = plan.Planclosedateandtime__c.format('yyyyMMddHHmm').escapeXml();
					// 2017/07/19 プラン有効期限機能追加 by zh END
					// 2018/01/19 プラン詳細情報追加 by zh BEGIN 
					// 表示順
					String planPropXml = joinTagXml('SortNo',CommUtils.nullToBlank(plan.Seq__c));
                    // 2018/03/14 プラン詳細情報追加 BEGIN
                    // 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
                    //planPropXml += joinTagXml('MealMemo',CommUtils.nullToBlank(plan.MealMemo__c));
                    planPropXml += joinTagXml('MealMemo',CommUtils.nullToBlank(isEngLangFlg ? plan.EnMealMemo__c : plan.MealMemo__c));
					// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
                    // 2018/03/14 プラン詳細情報追加 END
                    // 2018/03/28 画像情報はレスポンスに追加対応 BEGIN
                    if (planNoToIdMap.containsKey(plan.PlanNo__c)) {
                        for (document vardoc : planNoToIdMap.get(plan.PlanNo__c)) {
                            planPropXml += joinTagXml('ImgURL',photoUrl.replace('$_FILEID_$',vardoc.Id)
                        		.replace('$_KEYWORD_$',CommUtils.nullToBlank(vardoc.keywords).escapeXml()));
                        }
                    }
                    // 2018/03/28 画像情報はレスポンスに追加対応 END
					if (!CommUtils.isBlank(plan.PropRef__c)) {
					    // プラン属性情報
					    PlanProp__c prop = plan.PropRef__r; 
                        // 予約可能期間
                        if (prop.LeadCanBegDate__c != null) planPropXml+= joinTagXml('LeadCanBegDate',dateToString(prop.LeadCanBegDate__c)); //予約可能開始日
                        if (prop.LeadCanEndDate__c != null) planPropXml+= joinTagXml('LeadCanEndDate',dateToString(prop.LeadCanEndDate__c)); //予約可能開始日
                        // 予約受付開始日時
                        //String leadPreBegStr = '';
						planPropXml+= joinTagXml('LeadPreBegDays',CommUtils.nullToBlank(prop.LeadPreBegDays__c)); //何日前から予約受付
						planPropXml+= joinTagXml('LeadPreBegTime',prop.LeadPreBegTime__c); //何日前の時刻から予約受付
                        // 予約受付終了日時
                        planPropXml+= joinTagXml('LeadPreEndDays',CommUtils.nullToBlank(prop.LeadPreEndDays__c)); //何日前まで予約受付
                        planPropXml+= joinTagXml('LeadPreEndTime',prop.LeadPreEndTime__c); //何日前の時刻まで予約受付
                        // 予約変更期限
                        planPropXml+= joinTagXml('LeadUpdDays',CommUtils.nullToBlank(prop.LeadUpdDays__c)); //何日前まで予約変更受付
                        planPropXml+= joinTagXml('LeadUpdTime',prop.LeadUpdTime__c); //何日前の時刻まで予約変更受付
                        // 予約キャンセル期限
                        planPropXml+= joinTagXml('LeadCancelDays',CommUtils.nullToBlank(prop.LeadCancelDays__c)); //何日前まで予約キャンセル受付
                        planPropXml+= joinTagXml('LeadCancelTime',CommUtils.nullToBlank(prop.LeadCancelTime__c)); //何日前の時刻まで予約キャンセル受付                    
                        // 泊数制限
                        planPropXml+= joinTagXml('MinNight',CommUtils.nullToBlank(prop.MinNight__c)); //最小泊数
                        planPropXml+= joinTagXml('MaxNight',CommUtils.nullToBlank(prop.MaxNight__c)); //最大泊数
                        // 部屋数制限
                        planPropXml+= joinTagXml('MinRooms',CommUtils.nullToBlank(prop.MinRooms__c)); //最小部屋数
                        planPropXml+= joinTagXml('MaxRooms',CommUtils.nullToBlank(prop.MaxRooms__c)); //最大部屋数  
                        // 子ども人数制限
                        planPropXml+= joinTagXml('MinChildren',CommUtils.nullToBlank(prop.MinChildren__c)); //最小子ども人数
                        planPropXml+= joinTagXml('MaxChildren',CommUtils.nullToBlank(prop.MaxChildren__c)); //最大子ども人数  
                        // チェックイン可能期間
                        planPropXml+= joinTagXml('CheckInBegTime',CommUtils.nullToBlank(prop.CheckInBegTime__c)); //チェックイン開始時刻
                        planPropXml+= joinTagXml('CheckInEndTime',CommUtils.nullToBlank(prop.CheckInEndTime__c)); //チェックイン終了時刻 
                        // チェックアウト時刻
						planPropXml+= joinTagXml('CheckOutTime',CommUtils.nullToBlank(prop.CheckOutTime__c)); //チェックアウト時刻
						//お食事
						// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
						//planPropXml+= joinTagXml('Meal',prop.Meal__c); //お食事
						planPropXml+= joinTagXml('Meal',(isEngLangFlg ? prop.EnMeal__c : prop.Meal__c)); //お食事
						// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
						// プランカテゴリー
						// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
						//planPropXml+= joinTagXml('PlanCategory',prop.PlanCategory__c); //プランカテゴリー
						planPropXml+= joinTagXml('PlanCategory',(isEngLangFlg ? prop.EnPlanCategory__c : prop.PlanCategory__c)); //プランカテゴリー
                        // 2019/02/28 ブッキングエンジンは多言語対応 By zh END
                        // プラン種別
                        // 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
                        //planPropXml+= joinTagXml('PlanType',prop.PlanType__c); //プラン種別
                        planPropXml+= joinTagXml('PlanType',(isEngLangFlg ? prop.EnPlanType__c : prop.PlanType__c)); //プラン種別
						// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
                        // 備考
                        // 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
                        //planPropXml+= joinTagXml('Memo',prop.Note__c); //プラン種別
                        planPropXml+= joinTagXml('Memo',(isEngLangFlg ? prop.EnNote__c : prop.Note__c)); //プラン種別
                        // 2019/02/28 ブッキングエンジンは多言語対応 By zh END
                        // 予約キャンセル規定
                        // 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
                        //planPropXml+= joinTagXml('CancelRule',prop.CancelRule__c); //予約キャンセル規
                        planPropXml+= joinTagXml('CancelRule',(isEngLangFlg ? prop.EnCancelRule__c : prop.CancelRule__c)); //予約キャンセル規
						// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
                        // 2018/03/28 客户自定义API追加 WGCH BEGIN
                        // 自定义追加的Api处理
                        for(String newApi : newPropApiSet){
                            Object o = prop.get(newApi);
                            if (o == null) continue;
                        	// 字段描述
                        	Schema.DescribeFieldResult dr = modelDeafaultValuesMaps.get(newApi.toLowerCase());
                        	Schema.DisplayType fieldType = dr.getType();
                        	if(fieldType == Schema.DisplayType.Time){
                        	    // Time
                        	    planPropXml+= joinTagXml(newApi,(DateTime.newInstance(Date.today(),(Time)o)).format('HH:mm'));
                        	} else if(fieldType == Schema.DisplayType.Date) {
	                        	// Date
	                        	planPropXml+= joinTagXml(newApi,dateToString((Date)o));
	                        } else if(fieldType == Schema.DisplayType.DateTime) {
	                        	// DateTime
	                        	planPropXml+= joinTagXml(newApi,((DateTime)o).format('yyyyMMddHHmm'));
	                        } else {
	                            // Other
                        		planPropXml+= joinTagXml(newApi,CommUtils.nullToBlank(o));
                        		// 2018/05/10 プラン属性へカスタム項目を追加することで名も返却改善 WGCH BEGIN
                        		if(fieldType == Schema.DisplayType.REFERENCE){
                        			String propRef = newApi.replace('__c','__r');
                        			sObject s = prop.getSObject(propRef);
                        			if(s != null){
                        				planPropXml+= joinTagXml((newApi + '_' + 'Name'),CommUtils.nullToBlank(s.get('Name')));
                        			}
                        		}
                        		// 2018/05/10 プラン属性へカスタム項目を追加することで名も返却改善 WGCH END
	                        }
                        }
                        // 2018/03/28 客户自定义API追加 WGCH END
					}
					// 2018/01/19 プラン詳細情報追加 by zh END 
					// プラン料金金額
					Decimal planPrice = CommUtils.nullToZero(plan.Price__c);
					//List<PlanDetail__c> roomPriceLst = plan.PlanRef__r;
					// 室数明細が存在する、しないフラグ
					Boolean isHaveRoomDetailFlg = false;
					Boolean autoSetupTierPriceFlg = false;
					Decimal sumRoomPrice = 0;
					for (PlanDetail__c detail : plan.PlanRef__r) {
						isHaveRoomDetailFlg = true;
						// 室料合計する
						sumRoomPrice += Commutils.nullToZero(detail.Price__c);
					}
//System.debug(loggingLevel.info, 'sumRoomPrice='+sumRoomPrice);
//System.debug(loggingLevel.info, 'planPrice[1]='+planPrice);
					// 室料金額は0円の場合、TIERで金額自動設定を行う
					autoSetupTierPriceFlg = (isHaveRoomDetailFlg && (sumRoomPrice == 0));
//System.debug(loggingLevel.info, 'planPrice[2]='+planPrice);
					// プラン料金帯リスト
					String planRangePriceListXml = '';
					// 料金情報
					if (reqInfo.ExtractionProcedure == '2' || reqInfo.ExtractionProcedure == '3') {
						for (String tier : tierLst) {
							List<RackRateTable__c> ractRateLst = rackRateMstMap.get(tier);
							String planPriceListXml = '';
							for (RackRateTable__c rackRate : ractRateLst) {
//System.debug(loggingLevel.info, 'rackRate[2]='+rackRate);
								// 人数
								Decimal priceCount = CommUtils.nullToZero(rackRate.Persons__c);
								// 室料あり場合、TIER金額で加算する[プラン金額]
								// 2020/09/12 ソース柔軟性改善対応　[rackRate.Price__c]がNULLの計算不具合対応 WSQ BEGIN
								if (rackRate.Price__c == null) rackRate.Price__c = 0;
								// 2020/09/12 ソース柔軟性改善対応　[rackRate.Price__c]がNULLの計算不具合対応 WSQ END
								Decimal xmlPlanPrice = autoSetupTierPriceFlg ? (CommUtils.nullToZero(rackRate.Price__c + planPrice)) : planPrice ;
								// 2019/11/11 室販売方法の対応 WSQ BEGIN
								Decimal roomPrice = autoSetupTierPriceFlg ? (CommUtils.nullToZero(rackRate.Price__c) * priceCount + planPrice) : planPrice ;
								// 2019/11/11 室販売方法の対応 WSQ END
//System.debug(loggingLevel.info, 'xmlPlanPrice[2]='+xmlPlanPrice);
								planPriceListXml += planPriceListTempXml
													// 2019/11/11 室販売方法の対応 WSQ BEGIN
													.replace('$$_RoomPrice_$$',CommUtils.deleteRightZero(CommUtils.nullToBlank(roomPrice)))
													// 2019/11/11 室販売方法の対応 WSQ END
													.replace('$$_PriceCount_$$',String.valueOf(priceCount))
													.replace('$$_PlanPrice_$$',CommUtils.deleteRightZero(CommUtils.nullToBlank(xmlPlanPrice)));
							}
							planRangePriceListXml += PlanRangePriceListTempXml
													.replace('$$_PlanRangePriceName_$$',tier)
													.replace('$$_PlanPriceListXml_$$',planPriceListXml);
						}
					}
					planInfoXml += PlanInfoTempXml
									.replace('$$_PlanName_$$',planName)
									.replace('$$_PlanCode_$$',planCd)
									.replace('$$_PlanNo_$$',planNo)
									.replace('$$_ShopCode_$$',shopCd)
									// 2017/07/19 プラン有効期限機能追加 by zh BEGIN
									.replace('$$_PlanOpenDateTime_$$',planOpenDateTime)
									.replace('$$_PlanCloseDateTime_$$',planCloseDateTime)
									// 2017/07/19 プラン有効期限機能追加 by zh END
									// 2018/01/19 プラン詳細情報追加 by zh BEGIN 
									.replace('$$_PlanExtPropXml_$$',planPropXml)
									// 2018/01/19 プラン詳細情報追加 by zh END
									.replace('$$_PlanRangePriceListXml_$$',planRangePriceListXml);
				}
				// プラン情報リスト
				//if (!CommUtils.isBlank(planInfoXml)) planListXml = '<PlanList>' + planInfoXml +'</PlanList>';
			}
		} catch (Exception e) {
			// 予想以外の異常が発生する場合
			// 2020/09/12 DEBUG機能改善対応 By WSQ BEGIN
			//rs = new WS_ResultInfo('E999',e.getMessage());
			rs = new WS_ResultInfo('E999',getTraceLog(e));
			// 2020/09/12 DEBUG機能改善対応 By WSQ END
			log.write_error(e.getStackTraceString());
			System.debug(loggingLevel.error, e.getStackTraceString());
		}
		repxml = repxml.replace('$$_PlanList_$$',planInfoXml);
		repxml = repxml.replace('$$_CommonResponse_$$',rs.toXml());
		// 2017/12/06 性能改善 BEGIN
		//log.write_log('repxml：'+repxml);
		// 2017/12/06 性能改善 END
		log.write_method_end();
		// 2017/12/06 性能改善 BEGIN
		CommLogUtils.saveLogToDb(log.getAllLog(),CommLogUtils.LogType.WSAPI,logMaxFils);
		// 2017/12/06 性能改善 END
		return repxml;
	}
	
	// **********************************
	// 5. 在庫情報取得
	// **********************************
	class RoomTypeInventoryListParam {
		public RoomTypeInventoryListParam(Dom.XmlNode root) {
			// 店舗コード情報を取得する
			Dom.XmlNode CommonRequestField = root.getChildElement('CommonRequest', null);
			ShopCode = getChildElementByName(CommonRequestField, 'ShopCode');
			// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
			Lang = getChildElementByName(CommonRequestField, 'Lang');
			// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
			// 抽出条件
			Dom.XmlNode extrField = root.getChildElement('ExtractionCondition', null);
			if (extrField != null) {
				ExtractionProcedure = getChildElementByName(extrField, 'ExtractionProcedure');
				RoomTypeCode = getChildElementByName(extrField, 'RoomTypeCode');
				String strSearchDurationFrom = getChildElementByName(extrField, 'SearchDurationFrom');
				if (!CommUtils.isBlank(strSearchDurationFrom)) SearchDurationFrom = CommUtils.stringToDate(strSearchDurationFrom);
				String strSearchDurationTo = getChildElementByName(extrField, 'SearchDurationTo');
				if (!CommUtils.isBlank(strSearchDurationTo)) SearchDurationTo = CommUtils.stringToDate(strSearchDurationTo);
                // 2017/10/27 未割り当て部屋情報を取得できるよう追加 BEGIN
                // 在庫あり部屋はレスポンスする・しないフラグ
                OutRoomStockInfo = '2';
                String wkOutRoomStockInfo = getChildElementByName(extrField, 'OutRoomStockInfo');
                if (!CommUtils.isBlank(wkOutRoomStockInfo)) OutRoomStockInfo = wkOutRoomStockInfo;
                // 2017/10/27 未割り当て部屋情報を取得できるよう追加 END
			}
		}
		// 店舗コード
		String ShopCode{get;set;}
		/*
		検索方法を指定する
		「2」：照会期間で検索
		「3」：照会期間 AND 部屋タイプコード
		*/
		String ExtractionProcedure{get;set;}
		// 部屋タイプコード
		String RoomTypeCode{get;set;}
		// 照会期間FROM
		Date SearchDurationFrom{get;set;}
		// 照会期間TO
		Date SearchDurationTo{get;set;}
		// 2017/10/27 未割り当て部屋情報を取得できるよう追加 BEGIN
		// 在庫あり部屋はレスポンスする・しないフラグ
		// 「1」:返却、「2」:返却しない（デフォルト値）
		String OutRoomStockInfo{get;set;}
		Boolean isGetNoUseRoomInfo{get{return OutRoomStockInfo == '1';}}
		// 2017/10/27 未割り当て部屋情報を取得できるよう追加 END
		//
		public String validata() {
			String errMsg = '';
			// 
			if (CommUtils.isBlank(ExtractionProcedure) || 
				(ExtractionProcedure != '2' && ExtractionProcedure != '3')) {
				errMsg = MSG_E001 + ':'+this;
			}
			if (ExtractionProcedure == '2' || ExtractionProcedure == '3' ) { 
				if (SearchDurationFrom == null || SearchDurationTo == null) {
					errMsg = MSG_E001 + ':'+this;
				} else if (SearchDurationFrom.daysBetween(SearchDurationTo) >= 31) {
					errMsg = MSG_E002 + ':'+this;
				}
			}
			// 2017/10/27 未割り当て部屋情報を取得できるよう追加 BEGIN
			if (!CommUtils.isBlank(OutRoomStockInfo) &&
                (OutRoomStockInfo != '1' && OutRoomStockInfo != '2')) {
                errMsg = MSG_E001 + ':'+this;
            }
            // 2017/10/27 未割り当て部屋情報を取得できるよう追加 END
			if (ExtractionProcedure == '3' && CommUtils.isBlank(RoomTypeCode)) return MSG_E001 + ':'+this;
			return errMsg;
 		}
 		// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
 		String Lang{get;set;}
 		// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
	}
	@TestVisible private static string getroomtypeinventorylistService(String reqXml) {
	    CommLogUtils log = initLog();
		log.write_method_start('getroomtypeinventorylistService');
		log.write_log('reqXml：'+reqXml);
		// 在庫処理
		String repxml = '<GetRoomTypeInventoryListRS><CommonResponse>$$_CommonResponse_$$</CommonResponse><RoomStockList>$$_RoomStockList_$$</RoomStockList></GetRoomTypeInventoryListRS>';
		String roomStockInfoTempXml = '<RoomStockInfo><RoomTypeCode>$$_RoomTypeCode_$$</RoomTypeCode><RoomTypeName>$$_RoomTypeName_$$</RoomTypeName><SaleDate>$$_SaleDate_$$</SaleDate><SaleCount>$$_SaleCount_$$</SaleCount><RemainingCount>$$_RemainingCount_$$</RemainingCount><SalesStatus>$$_SalesStatus_$$</SalesStatus><ShopCode>$$_ShopCode_$$</ShopCode><RoomNames>$$_RoomNames_$$</RoomNames></RoomStockInfo>';
		String roomStockInfoXml = '';

		WS_ResultInfo rs = new WS_ResultInfo();
		try {
			Dom.Document doc = new Dom.Document();
			doc.load(reqXml);
			Dom.XMLNode rootNode = doc.getRootElement();
	
			// リクエスト情報解析する
			RoomTypeInventoryListParam reqInfo = new RoomTypeInventoryListParam(rootNode);
//System.debug(loggingLevel.INFO,'---------reqInfo---------'+reqInfo);
			// 有効チェック
			String validataMsg = reqInfo.validata();
			if (!CommUtils.isBlank(validataMsg)) {
				rs = new WS_ResultInfo('E0001',validataMsg);
			}
			// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
			String lang = reqInfo.Lang;
			Boolean isEngLangFlg = isEngLang(lang);
			// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
			if (rs.IsSuccess) {
				// 指定期間の部屋タイプ情報から在庫情報を取得する
				StockChangeHelpUtils helper = new StockChangeHelpUtils();
                // 2017/10/27 未割り当て部屋情報を取得できるよう追加 BEGIN
                Boolean isGetNoUseRoomInfo = reqInfo.isGetNoUseRoomInfo; 
                if (isGetNoUseRoomInfo) {
                    helper = new StockChangeHelpUtils(true);
                }
				// 2017/10/27 未割り当て部屋情報を取得できるよう追加 END
				List<Date> dateRangeLst = helper.getDateRange(reqInfo.SearchDurationFrom, reqInfo.SearchDurationTo);
				map<Date,String> dateToStringMap = new map<Date, String>();
				for (Date dt : dateRangeLst) {
					String strDt = DateTime.newInstance(dt.year(),dt.month(),dt.day()).format('yyyyMMdd');
					dateToStringMap.put(dt,strDt);	
				}
				set<Date> dateRangeSet = new set<Date>();
				dateRangeSet.addAll(dateRangeLst);
				// 既存部屋タイプ関連情報を取得する
				String shopCode = CommUtils.nullToBlank(reqInfo.ShopCode);
				String roomTypeCd = reqInfo.RoomTypeCode;
				// 2017/10/27 未割り当て部屋情報を取得できるよう追加 BEGIN
				Map<Id,set<Room__c>> roomTypeToRoomsMap = new Map<Id, Set<Room__c>>();
				//String queryStr = 'select id, MaxRooms__c,RoomTypeCode__c,RoomTypeName__c from TypeOfRooms__c where SumNotApplicableFlg__c != true And ShopInfoRef__r.ShopCode__c = :shopCode ';
				// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
				//String queryStr = 'select id, MaxRooms__c,RoomTypeCode__c,RoomTypeName__c ';
				String queryStr = 'select id, MaxRooms__c,RoomTypeCode__c,RoomTypeName__c,EnRoomTypeName__c ';
				//if (isGetNoUseRoomInfo) queryStr+= ',(Select Id,Name From TypeRoomRef__r) ';
				if (isGetNoUseRoomInfo) queryStr+= ',(Select Id,Name,EnName__c From TypeRoomRef__r) ';
				// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
				queryStr += 'from TypeOfRooms__c where SumNotApplicableFlg__c != true And ShopInfoRef__r.ShopCode__c = :shopCode ';
				if (!CommUtils.isBlank(roomTypeCd)) queryStr += ' And RoomTypeCode__c = :roomTypeCd ';
                // 2017/10/27 未割り当て部屋情報を取得できるよう追加 END
				List<TypeOfRooms__c> targetRoomTypeLst = DataBase.query(queryStr);
				set<Id> roomTypeIdsSet = new Set<Id>();
				for (TypeOfRooms__c roomType : targetRoomTypeLst) {
					roomTypeIdsSet.add(roomType.Id);
					// 2017/10/27 未割り当て部屋情報を取得できるよう追加 BEGIN
					if (isGetNoUseRoomInfo) {
					    if (!roomTypeToRoomsMap.containsKey(roomType.Id)) roomTypeToRoomsMap.put(roomType.Id,new set<Room__c>());
					    roomTypeToRoomsMap.get(roomType.Id).addAll(roomType.TypeRoomRef__r);
					}
					// 2017/10/27 未割り当て部屋情報を取得できるよう追加 END
				}
				map<String, Decimal> usedRoomMap = helper.getStockUsedInfo(roomTypeIdsSet, dateRangeSet);
				// 2017/10/27 未割り当て部屋情報を取得できるよう追加 BEGIN
				map<String, Decimal> usedRoomInfMap = helper.getRoomStockUsedInfo();
				// 2017/10/27 未割り当て部屋情報を取得できるよう追加 END
				// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
				map<String, GuestRoomStock__c> guestRoomInfMap = helper.getGuestRoomInfo(roomTypeIdsSet, dateRangeSet);
				// 2018/12/15 在庫調整と販売状態管理 by zy END
				// 各部屋タイプの各日の在庫情報を返却する
				for (TypeOfRooms__c roomType : targetRoomTypeLst) {
					Decimal maxRooms = CommUtils.nullToZero(roomType.MaxRooms__c);
					String roomTypeCode = CommUtils.nullToBlank(roomType.RoomTypeCode__c).escapeXml();
					// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
					//String roomTypeName = CommUtils.nullToBlank(roomType.RoomTypeName__c).escapeXml();
					String roomTypeName = CommUtils.nullToBlank(isEngLangFlg ? roomType.EnRoomTypeName__c : roomType.RoomTypeName__c).escapeXml();
					// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
					// 2017/10/27 未割り当て部屋情報を取得できるよう追加 BEGIN
					set<Room__c> relRoomSet = roomTypeToRoomsMap.get(roomType.Id);
					// 2017/10/27 未割り当て部屋情報を取得できるよう追加 END
					for (Date dt : dateRangeLst) {
						String key = helper.getRoomStockKey(roomType.Id, dt);
						// 販売室数
						Decimal salesRooms = 0;
						if (usedRoomMap.containsKey(key)) {
							salesRooms = usedRoomMap.get(key);
						}
						// 残室数
						// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
						//Decimal remaindRooms = (maxRooms >= salesRooms ? (maxRooms - salesRooms) : 0);
						GuestRoomStock__c guest = guestRoomInfMap.get(key);
						Decimal typeMaxRoom = guest != null ? guest.MaxRoomsCal__c : maxRooms;
						Decimal remaindRooms = (typeMaxRoom >= salesRooms ? (typeMaxRoom - salesRooms) : 0);
						String salesStatus = '';
						// 指定販売状態設定
						if (guest != null) salesStatus = CommUtils.nullToBlank(guest.SalesStatusLst__c);
						// 2018/12/15 在庫調整と販売状態管理 by zy END
						// 販売日
						String strDt = dateToStringMap.get(dt);
						// 2017/10/27 未割り当て部屋情報を取得できるよう追加 BEGIN
						String roomNames = '';
						if (isGetNoUseRoomInfo && relRoomSet != null) {
					        // 該当日の該当部屋は既に利用される、されないチェックする
					        for (Room__c room : relRoomSet) {
					            String roomkey = helper.getRoomStockKey(room.id, dt);
					            // 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
					            //if (!usedRoomInfMap.containsKey(roomkey)) roomNames += room.Name + ',';  
					            if (!usedRoomInfMap.containsKey(roomkey)) roomNames += CommUtils.nullToBlank(isEngLangFlg ? room.EnName__c : room.Name) + ',';  
					            // 2019/02/28 ブッキングエンジンは多言語対応 By zh END
					        }
						}
						roomNames = roomNames.removeEnd(',');
						// 2017/10/27 未割り当て部屋情報を取得できるよう追加 END
						roomStockInfoXml += roomStockInfoTempXml
												.replace('$$_RoomTypeCode_$$',roomTypeCode)
												.replace('$$_RoomTypeName_$$',roomTypeName)
												.replace('$$_SaleDate_$$',strDt)
												.replace('$$_SaleCount_$$',String.valueOf(salesRooms))
												.replace('$$_RemainingCount_$$',String.valueOf(remaindRooms))
												// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
												.replace('$$_SalesStatus_$$',salesStatus)
												// 2018/12/15 在庫調整と販売状態管理 by zy END
												// 2017/10/27 未割り当て部屋情報を取得できるよう追加 BEGIN
												.replace('$$_RoomNames_$$',roomNames)
												// 2017/10/27 未割り当て部屋情報を取得できるよう追加 END
												.replace('$$_ShopCode_$$',shopCode);
					}
				}
//System.debug(loggingLevel.info, 'roomStockInfoXml='+roomStockInfoXml);
				/*
				if (!CommUtils.isBlank(roomStockInfoXml)) {
					roomStockInfoXml = '<RoomStockList>' + roomStockInfoXml + '</RoomStockList>';
				}*/
			}
		} catch (Exception e) {
			// 予想以外の異常が発生する場合
			// 2020/09/12 DEBUG機能改善対応 By WSQ BEGIN
			//rs = new WS_ResultInfo('E999',e.getMessage());
			rs = new WS_ResultInfo('E999',getTraceLog(e));
			// 2020/09/12 DEBUG機能改善対応 By WSQ END
			log.write_error(e.getStackTraceString());
			System.debug(loggingLevel.error, e.getStackTraceString());
		}
		repxml = repxml.replace('$$_RoomStockList_$$',roomStockInfoXml);
		repxml = repxml.replace('$$_CommonResponse_$$',rs.toXml());
		// 2017/12/06 性能改善 BEGIN
		//log.write_log('repxml：'+repxml);
		// 2017/12/06 性能改善 END	
		log.write_method_end();
		// 2017/12/06 性能改善 BEGIN
		CommLogUtils.saveLogToDb(log.getAllLog(),CommLogUtils.LogType.WSAPI,logMaxFils);
		// 2017/12/06 性能改善 END
		return repxml;
	}
	

	// ******************************************
	// 8. 見積結果取得
	// ******************************************
	class EstimateInfoParam {
		public EstimateInfoParam(Dom.XMLNode root) {
			estLst = new list<EstimateInfoParamSub>();
			Dom.XmlNode CommonRequestField = root.getChildElement('CommonRequest', null);
			ShopCode = getChildElementByName(CommonRequestField, 'ShopCode');
			Dom.XmlNode estimateInfoListField = root.getChildElement('EstimateInfoList', null);
			if (estimateInfoListField != null) {
				for (Dom.XmlNode estimateInfoField : estimateInfoListField.getChildElements()) {
					EstimateInfoParamSub sub = new EstimateInfoParamSub(estimateInfoField);
					if (sub.isFullData()) estLst.add(sub);
				}
			}
		}
		// 店舗コード
		String ShopCode{get;set;}
		// 抽出条件
		list<EstimateInfoParamSub> estLst{get;set;}
		public String validata() {
			String errMsg = '';
			if (estLst.isEmpty()) {
				errMsg = MSG_E001 + ':'+this;
			}
			return errMsg;
		}
	}
	class EstimateInfoParamSub {
		// 予約情報
		public EstimateInfoParamSub (Dom.XMLNode estNode) {
			String strRoomDate = getChildElementByName(estNode, 'RoomDate');
			if (!CommUtils.isBlank(strRoomDate)) RoomDate = CommUtils.StringToDate(strRoomDate);
			ProductCode = getChildElementByName(estNode, 'ProductCode');
			Quantity = CommUtils.nullToZero(getChildElementByName(estNode, 'Quantity'));
			RowNo = getChildElementByName(estNode, 'RowNo');
		}
		Date RoomDate{get;set;}
		String ProductCode{get;set;}
		Decimal Quantity{get;set;}
		String RowNo {get;set;}
		public boolean isFullData() {
			return (RoomDate != null && !CommUtils.isBlank(ProductCode) && Quantity > 0 && !CommUtils.isBlank(RowNo));
		}
	}
	
	@TestVisible private static string getEstimateInfoService(String reqXml) {
	    CommLogUtils log = initLog();
		log.write_method_start('getEstimateInfoService');
		log.write_log('reqXml：'+reqXml);
		String repXml = '<GetEstimateInfoRS><CommonResponse>$$_CommonResponse_$$</CommonResponse>$$_EstimateInfoBase_$$$$_EstimateInfoList_$$</GetEstimateInfoRS>';
		String EstimateInfoBaseTempXml = '<EstimateInfoBase><EstimateTotalNoTax>$$_EstimateTotalNoTax_$$</EstimateTotalNoTax><EstimateTotalIncTax>$$_EstimateTotalIncTax_$$</EstimateTotalIncTax><EstimateTax>$$_EstimateTax_$$</EstimateTax></EstimateInfoBase>';
		String EstimateInfoTempXml = '<EstimateInfo><TotalNoTax>$$_TotalNoTax_$$</TotalNoTax><TotalIncTax>$$_TotalIncTax_$$</TotalIncTax><TaxRate>$$_TaxRate_$$</TaxRate><ServiceRate>$$_ServiceRate_$$</ServiceRate><RowNo>$$_RowNo_$$</RowNo></EstimateInfo>';
		
		String EstimateInfoBaseXml = '';
		String EstimateInfoListXml = '';
		WS_ResultInfo rs = new WS_ResultInfo();
		try {
			Dom.Document doc = new Dom.Document();
			doc.load(reqXml);
			Dom.XMLNode rootNode = doc.getRootElement();
			// リクエスト情報解析する
			EstimateInfoParam reqInfo = new EstimateInfoParam(rootNode);
//System.debug(loggingLevel.INFO,'---------reqInfo---------'+reqInfo);
			// 有効チェック
			String validataMsg = reqInfo.validata();
			if (!CommUtils.isBlank(validataMsg)) {
				rs = new WS_ResultInfo('E0001',validataMsg);
			}
			if (rs.IsSuccess) {
				// 商品コードにより、商品定義情報から金額計算を行う 
				Decimal EstimateTotalIncTax = 0;
				//Decimal EstimateTotal = 0;
				//Decimal EstimateTax = 0;
				Set<String> prodCodeSet = new set<String>();
				for (EstimateInfoParamSub sub : reqInfo.estLst) {
					prodCodeSet.add(sub.ProductCode);
				}
				map<string,AccountMaster__c> prodMstMap = new map<string, AccountMaster__c>();
				// 消費税マスタから消費税取得する
				JMST__c taxRateMst = CommLogicProcess.getTaxRateInfo();
				Decimal taxRateVal = CommUtils.nullToZero(taxRateMst.TaxRate__c);
				list<AccountMaster__c> existProdLst = [select id, name, Field5__c, TaxRateCal__c, ServiceRate__c,Field3__c from AccountMaster__c where Field3__c =:prodCodeSet And IsClosed__c != true];
				for (AccountMaster__c acc : existProdLst) {
					prodMstMap.put(acc.field3__c, acc);
				}
				// 金額計算用共通クラス初期化
				CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo();
				Integer pointLen = CommUtils.getPointLen();
				Decimal noTaxSumPrice = 0;
				//引き渡し商品情報により、金額計算を行う
				for (EstimateInfoParamSub sub : reqInfo.estLst) {
					String prodCode = sub.ProductCode;
					if (!prodMstMap.containsKey(prodCode)) continue;
					AccountMaster__c acc = prodMstMap.get(prodCode);
					Decimal price = CommUtils.nullToZero(acc.Field5__c);
					Decimal qty = sub.Quantity;
					Decimal taxRate = CommUtils.nullToZero(acc.TaxRateCal__c);
					Decimal serviceRate = CommUtils.nullToZero(acc.ServiceRate__c);
					priceInfo.process(price, qty, taxRate, serviceRate);
					Decimal TotalNoTax = priceInfo.priceExcTax;
					Decimal TotalIncTax = priceInfo.priceIncTax;
					// 金額合計（税込み)
					EstimateTotalIncTax += TotalIncTax;
					// 非課税の商品の金額を計算する
					if (taxRate == 0) noTaxSumPrice += TotalIncTax;
					// XML作成する
					EstimateInfoListXml += EstimateInfoTempXml
											.replace('$$_TotalNoTax_$$',CommUtils.deleteRightZero(CommUtils.nullToBlank(TotalNoTax)))
											.replace('$$_TotalIncTax_$$',CommUtils.deleteRightZero(CommUtils.nullToBlank(TotalIncTax)))
											.replace('$$_TaxRate_$$',CommUtils.deleteRightZero(CommUtils.nullToBlank(taxRate)))
											.replace('$$_ServiceRate_$$',CommUtils.deleteRightZero(CommUtils.nullToBlank(serviceRate)))
											.replace('$$_RowNo_$$',sub.RowNo);
				}
				if (!CommUtils.isBlank(EstimateInfoListXml)) {
					EstimateInfoListXml = '<EstimateInfoList>' + EstimateInfoListXml + '</EstimateInfoList>';
					// 合計金額から消費税と税抜金額を計算する
					Decimal calTaxRateVal = CommUtils.RoundProcess((EstimateTotalIncTax - noTaxSumPrice) / (1 + taxRateVal / 100) * (taxRateVal / 100), pointLen);
					// 税抜き金額
					Decimal EstimateTotalNoTax = EstimateTotalIncTax - calTaxRateVal;
					EstimateInfoBaseXml += EstimateInfoBaseTempXml
											.replace('$$_EstimateTotalNoTax_$$',CommUtils.deleteRightZero(CommUtils.nullToBlank(EstimateTotalNoTax)))
											.replace('$$_EstimateTotalIncTax_$$',CommUtils.deleteRightZero(CommUtils.nullToBlank(EstimateTotalIncTax)))
											.replace('$$_EstimateTax_$$',CommUtils.deleteRightZero(CommUtils.nullToBlank(calTaxRateVal)));
				}
			}
		} catch (Exception e) {
			// 2020/09/12 DEBUG機能改善対応 By WSQ BEGIN
			// 	rs = new WS_ResultInfo('E999',e.getMessage());
			rs = new WS_ResultInfo('E999',getTraceLog(e));
			// 2020/09/12 DEBUG機能改善対応 By WSQ END
			log.write_error(e.getStackTraceString());
			System.debug(loggingLevel.error, e.getStackTraceString());
		}
		repXml = repXml
					.replace('$$_EstimateInfoBase_$$',EstimateInfoBaseXml)
					.replace('$$_EstimateInfoList_$$',EstimateInfoListXml)
					.replace('$$_CommonResponse_$$',rs.toXml());
		// 2017/12/06 性能改善 BEGIN
		//log.write_log('repxml：'+repxml);
		// 2017/12/06 性能改善 END
		log.write_method_end();
		// 2017/12/06 性能改善 BEGIN
		CommLogUtils.saveLogToDb(log.getAllLog(),CommLogUtils.LogType.WSAPI,logMaxFils);
		// 2017/12/06 性能改善 END
		return repXml;	
	}
	
	// ******************************************
	// 6. 予約登録
	// ******************************************
	@TestVisible private static string createBookingService(String reqXml) {
	    CommLogUtils log = initLog();
		log.write_method_start('createBookingService');
		log.write_log('reqXml：'+reqXml);
		String repxml = '<CreateBookingRS><CommonResponse>$$_CommonResponse_$$<PmsDataId>$$_PmsDataId_$$</PmsDataId><UserID>$$_UserID_$$</UserID></CommonResponse></CreateBookingRS>';
		WS_ResultInfo rs = new WS_ResultInfo();
		try {
			String shopCode = '';

			WS_ParseXmlToBookingInfoCtrl parseXmlCtrl = new WS_ParseXmlToBookingInfoCtrl();	
			WS_LeadInfoSync leadInfoToSfCtrl = new WS_LeadInfoSync();			
			WS_LeadInfoSync.BI_WS_SyncInfo bookingInfo = parseXmlCtrl.parse(reqXml);
            if (CommUtils.isBlank(bookingInfo.DataID)) {
            	bookingInfo.DataID = getSeqDataId();
            }
            // 店舗コード
            WS_LeadInfoSync.BI_WS_RisaplBasic risaplBasic = bookingInfo.risaplsinformation.risaplsCommonInformation.risaplBasic;
            if (!CommUtils.isBlank(risaplBasic.AccommodationId)) {
            	shopCode = CommUtils.nullToBlank(risaplBasic.AccommodationId);
            }
			WS_LeadInfoSync.BI_WS_SyncResult result = leadInfoToSfCtrl.upsertWSLeadInfo(bookingInfo,shopCode);
			if(result.result != WS_LeadInfoSync.BI_WS_Result.OK){
				rs = new WS_ResultInfo('E999',result.message);
				log.write_log(leadInfoToSfCtrl.mLogUtils.getAlllog());
			} else {
				Id leadIndxId = result.sfdcId;	
				List<LeadIndex__c> indexs = [select id, name, contactRef__r.ID__c,ID__c from LeadIndex__c where id = :leadIndxId limit 1];	
				LeadIndex__c leadIdx = indexs[0];
				// 成功
				repxml = repxml.replace('$$_PmsDataId_$$',leadIdx.ID__c)
								.replace('$$_UserID_$$',CommUtils.nullToBlank(leadIdx.contactRef__r.ID__c));
				log.write_log(leadInfoToSfCtrl.mLogUtils.getAlllog());
			}
		} catch (Exception e) {
			// 2020/09/12 DEBUG機能改善対応 By WSQ BEGIN
			//rs = new WS_ResultInfo('E999',e.getMessage());
			rs = new WS_ResultInfo('E999',getTraceLog(e));
			// 2020/09/12 DEBUG機能改善対応 By WSQ END
			log.write_error(e.getStackTraceString());
			System.debug(loggingLevel.error, e.getStackTraceString());
		}
		repxml = repxml.replace('$$_PmsDataId_$$','')
						.replace('$$_UserID_$$','')
						.replace('$$_CommonResponse_$$',rs.toXml());
		// 2017/12/06 性能改善 BEGIN
		//log.write_log('repxml：'+repxml);
		// 2017/12/06 性能改善 BEGIN		
		log.write_method_end();
		// 2017/12/06 性能改善 BEGIN
		CommLogUtils.saveLogToDb(log.getAllLog(),CommLogUtils.LogType.WSAPI,logMaxFils);
		// 2017/12/06 性能改善 END
		return repxml;
	}  
	// 管理番号を作成する
	private static String getSeqDataId() {
        Savepoint sp = Database.setSavepoint();
        try {
		   LeadIndex__c newLeadIndex = new LeadIndex__c();
		   insert newLeadIndex;
		   return [select name from leadindex__c where id = :newLeadIndex.id][0].name;
        } finally {
           Database.rollback(sp);
        }
 	}
 	
	
	// ******************************************
	// 7. 予約情報取得
	// ******************************************
	class BookinglistParam {
		public BookinglistParam(Dom.XmlNode root) {
			// 店舗コード情報を取得する
			Dom.XmlNode CommonRequestField = root.getChildElement('CommonRequest', null);
			ShopCode = getChildElementByName(CommonRequestField, 'ShopCode');
			// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
			Lang = getChildElementByName(CommonRequestField, 'Lang');
			// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
			// 抽出条件
			Dom.XmlNode extrField = root.getChildElement('ExtractionCondition', null);
			if (extrField != null) {
				UserID = getChildElementByName(extrField, 'UserID');
				TravelAgencyBookingNumber = getChildElementByName(extrField, 'TravelAgencyBookingNumber');
				PmsDataId = getChildElementByName(extrField, 'PmsDataId');
				String strSearchDurationFrom = getChildElementByName(extrField, 'SearchDurationFrom');
				if (!CommUtils.isBlank(strSearchDurationFrom)) SearchDurationFrom = CommUtils.stringToDate(strSearchDurationFrom);
				String strSearchDurationTo = getChildElementByName(extrField, 'SearchDurationTo');
				if (!CommUtils.isBlank(strSearchDurationTo)) SearchDurationTo = CommUtils.stringToDate(strSearchDurationTo);
				if (SearchDurationTo == null) SearchDurationTo = Date.newInstance(3999,12,31);
			}
		}
		// 店舗コード
		String ShopCode{get;set;}
		/*
		検索方法を指定する
		予約者・会員番号
		*/
		String UserID{get;set;}
		// 旅行会社予約(管理)番号
		String TravelAgencyBookingNumber{get;set;}
		// PMS側の内部予約管理ID
		String PmsDataId{get;set;}
		// 照会期間FROM
		Date SearchDurationFrom{get;set;}
		// 照会期間TO
		Date SearchDurationTo{get;set;}
		//
		public String validata() {
			String errMsg = '';
			// 
			if (CommUtils.isBlank(UserID) || SearchDurationFrom == null || SearchDurationTo == null){
				errMsg = MSG_E001 + ':'+this;
			}
			return errMsg;
 		}
 		// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
 		String Lang{get;set;}
 		// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
	}
	// ネットから
	@TestVisible private static String getbookinglistSerivce(String reqXml) {
	    CommLogUtils log = initLog();
		log.write_method_start('getbookinglistSerivce');
		log.write_log('reqXml：'+reqXml);
		String repXml = '<GetBookingListRS><CommonResponse>$$_CommonResponse_$$</CommonResponse><BookingList>$$_BookingList_$$</BookingList></GetBookingListRS>';
		String bookingInfoXml = '';
		WS_ResultInfo rs = new WS_ResultInfo();
		try {
			Dom.Document doc = new Dom.Document();
			doc.load(reqXml);
			Dom.XMLNode rootNode = doc.getRootElement();
			// リクエスト情報解析する
			BookinglistParam reqInfo = new BookinglistParam(rootNode);
//System.debug(loggingLevel.info, 'reqInfo='+reqInfo);
			// 有効チェック
			String validataMsg = reqInfo.validata();
			if (!CommUtils.isBlank(validataMsg)) {
				rs = new WS_ResultInfo('E0001',validataMsg);
			}
			// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
			String lang = reqInfo.Lang;
			// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
			if (rs.IsSuccess) {
				// 該当ユーザーIDと開始日により、関連の予約情報を取得する
				// USERIDにより、予約インデックス情報を取得する
				// 到着日開始
				//---------------------------------------
				// 既存予約インデックス情報を取得する
				//---------------------------------------
				String userId = reqInfo.UserID;
				Date startDate = reqInfo.SearchDurationFrom;
				Date endDate = reqInfo.SearchDurationTo;
				String cancelFlg = CommConst.LEAD_ST_CANCEL;
				String travelNo = reqInfo.TravelAgencyBookingNumber;
				String dataId = reqInfo.PmsDataId;
				String strQuery = 	'select id,createdDate,TravelLeadNo__c,EntryTime__c,DepartureTime__c,EntryDate__c,DepartureDate__c,Nights__c, '+
									'TravelAgencyBookingInsDateTime__c,Comment__c,ID__c,'+
									'contactRef__r.Name,contactRef__r.KanaName1__c,contactRef__r.Katakana__c,contactRef__r.Name1__c '+
									'from LeadIndex__c where StatusLst__c != :cancelFlg And ParentLeadIndxRef__c = null And contactRef__r.Id__c = :userId And ( EntryDate__c <= :endDate And EntryDate__c >= :startDate) ';
				//if (endDate != null) strQuery += ' And (DepartureDate__c <= :endDate And )';
				if (!CommUtils.isBlank(travelNo)) strQuery += ' And TravelLeadNo__c = :travelNo';
				if (!CommUtils.isBlank(dataId)) strQuery += ' And ID__c = :dataId';
//System.debug(loggingLevel.info, 'strQuery='+strQuery);
				// 既存予約インデックス情報を取得する
				List<LeadIndex__c> leadIndexs = DataBase.query(strQuery);
				
				// 既存情報が存在する場合
				if (!leadIndexs.isEmpty()) {
					//予約インデックスID
					//set<id> idxSet = new set<id>();
					map<id, LeadIndex__c> existIndexMap = new map<id, leadIndex__c>();
					for (LeadIndex__c leadIndex : leadIndexs) {
						//idxSet.add(leadIndex.Id);
						existIndexMap.put(leadIndex.id, leadIndex);
					}
					// 関連のIDにより、有効な予約情報を取得する
					// ネットから予約情報のみ返却する
					List<Lead__c> existLeads = [select id,LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c
                								,EntryTime__c,Departure__c 
                								,Nights__c,Field348__c
                								,UnitPriceDefKb__c
                								// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
                								//,refTypeOfRooms__r.RoomTypeCode__c, refTypeOfRooms__r.RoomTypeName__c
                								,refTypeOfRooms__r.RoomTypeCode__c, refTypeOfRooms__r.RoomTypeName__c, refTypeOfRooms__r.EnRoomTypeName__c
                								// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
                								,StayPersons__c,Mans__c,Femails__c,ChildFA__c,Childs__c,ChildC__c,ChildD__c
                								,Field310__r.Name,Field310__r.PackageCode__c,Field315__c
                								// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
                								//,(Select ActionType__c,UseDate__c,Field3__c,ProductName__c,UnitPrice__c,Amount__c,GoukeinoneTax__c,Total__c,TaxRate__c,ServiceRate__c From BookingEstimateItemFgKu__r order by UseDate__c, rowno__c, name) 
                								,(Select ActionType__c,UseDate__c,Field3__c,ProductName__c,UnitPrice__c,Amount__c,GoukeinoneTax__c,Total__c,TaxRate__c,ServiceRate__c,EnProductName__c From BookingEstimateItemFgKu__r order by UseDate__c, rowno__c, name) 
												// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
				                                from Lead__c 
				                                where LeadIndexRef__c = :existIndexMap.keySet()
				                                And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
				                                And BookingDataID__c != null
				                                Order By LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c ];
				    //map<string, list<lead__c>> existLeadsMap = new map<string, list<lead__c>>();
				    map<id, list<list<lead__c>>> existLeadsMap = new map<id, list<list<lead__c>>>();
				    set<string> filterSet = new set<string>();
				    for (Lead__c lead : existLeads) {
				    	Id leadIndexId = CommUtils.nullToBlank(lead.LeadIndexRef__c);
				    	// 関連の予約インデックス情報はネットから予約の情報の場合、
				    	String key = leadIndexId
			                   +'_'+ CommUtils.nullToBlank(lead.LeadIndexSubId__c)
			                   +'_'+ CommUtils.nullToBlank(lead.RoomGroupNo__c);
						if (!existLeadsMap.containsKey(leadIndexId)) existLeadsMap.put(leadIndexId, new list<list<Lead__c>>());
						list<list<lead__c>> oneTravelList = existLeadsMap.get(leadIndexId);
						if (!filterSet.contains(key)) {
							oneTravelList.add(new list<lead__c>());
							filterSet.add(key);
						}
						list<lead__c> oneRoomLst = oneTravelList[oneTravelList.size()-1];
						oneRoomLst.add(lead);
				    }
					// 関連の予約情報から集計する
					
					// 複数予約情報を一括返却する
					for (Id idxId : existLeadsMap.keySet()) {
						LeadIndex__c leadIndex = existIndexMap.get(idxId);
						//if (!existLeadsMap.containsKey(leadIndex)) continue;
						list<list<lead__c>> oneTravelList = existLeadsMap.get(idxId);
						// １予約番号の関連の予約情報を出力する
						// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
						//bookingInfoXml += generalBookingInfo(leadIndex,oneTravelList);
						bookingInfoXml += generalBookingInfo(leadIndex,oneTravelList,lang);
						// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
					}
				}
			}
			
		} catch(Exception e) {
			// 2020/09/12 DEBUG機能改善対応 By WSQ BEGIN
			//rs = new WS_ResultInfo('E999',e.getMessage());
			rs = new WS_ResultInfo('E999',getTraceLog(e));
			// 2020/09/12 DEBUG機能改善対応 By WSQ END
			log.write_error(e.getStackTraceString());
			System.debug(loggingLevel.error, e.getStackTraceString());
		}
		repXml = repXml.replace('$$_BookingList_$$',bookingInfoXml)
						.replace('$$_CommonResponse_$$',rs.toXml());
		// 2017/12/06 性能改善 BEGIN
		//log.write_log('repxml：'+repxml);	
		// 2017/12/06 性能改善 END	
		log.write_method_end();
		// 2017/12/06 性能改善 BEGIN
		CommLogUtils.saveLogToDb(log.getAllLog(),CommLogUtils.LogType.WSAPI,logMaxFils);
		// 2017/12/06 性能改善 END
		return repXml;
	}
	// １予約インデックス関連の全てN部屋N泊の予約情報
	// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
	//private static string generalBookingInfo(LeadIndex__c leadIndex, list<list<lead__c>> oneTravelList) {
	private static string generalBookingInfo(LeadIndex__c leadIndex, list<list<lead__c>> oneTravelList, String lang) {
	Boolean isEngLangFlg = isEngLang(lang);
	// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
		String transactionTypeXml = generalTransactionTypeInfo(leadIndex);
		String basicInfoXml = generalBasicInfo(leadIndex, oneTravelList);
		String basicRatInfoXml = generalBasicRateInfo(leadIndex, oneTravelList);
		// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
		//String roomAndGuestInfoXml = generalRoomAndGuestInfo(leadIndex, oneTravelList);
		String roomAndGuestInfoXml = generalRoomAndGuestInfo(leadIndex, oneTravelList, isEngLangFlg);
		// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
		return '<BookingInfo>'+transactionTypeXml+basicInfoXml+basicRatInfoXml+roomAndGuestInfoXml+'</BookingInfo>'; 
	}
	private static string generalTransactionTypeInfo (LeadIndex__c leadIndex) {
		return '<TransactionType>'+CommUtils.nullToBlank(leadIndex.ID__c)+'</TransactionType>';
	}
	private static string generalBasicInfo(LeadIndex__c leadIndex, list<list<lead__c>> oneTravelList) {
		// 該当部屋の一番目予約情報
		Lead__c firstLead = oneTravelList[0][0];
		// 旅行会社予約(管理)番号
		String TravelAgencyBookingNumber = xmlNullToBlank(leadIndex.TravelLeadNo__c);
//System.debug(loggingLevel.info, 'TravelAgencyBookingNumber='+TravelAgencyBookingNumber);
//System.debug(loggingLevel.info, 'leadIndex='+leadIndex);
		// 旅行会社予約受付日
		DateTime TravelAgencyBookingInsDt = leadIndex.TravelAgencyBookingInsDateTime__c;
		if (TravelAgencyBookingInsDt == null) TravelAgencyBookingInsDt = leadIndex.createdDate;
		String TravelAgencyBookingDate = xmlNullToBlank(TravelAgencyBookingInsDt.format('yyyy-MM-dd'));
		String TravelAgencyBookingTime = xmlNullToBlank(TravelAgencyBookingInsDt.format('HH:mm:ss'));
		// 代表者情報
		String singleName = CommUtils.nullToBlank(leadIndex.contactRef__r.KanaName1__c);
		if (CommUtils.isBlank(singleName)) singleName = leadIndex.contactRef__r.Name;
		String GuestOrGroupNameSingleByte = xmlNullToBlank(singleName);
		String GuestOrGroupNameDoubleByte = xmlNullToBlank(leadIndex.contactRef__r.Katakana__c);
		String GuestOrGroupNameKanjiName = xmlNullToBlank(leadIndex.contactRef__r.Name);
		// 日付と時刻
		Time ciTime = CommUtils.stringToTime(leadIndex.EntryTime__c);
		Time coTime = CommUtils.stringToTime(leadIndex.DepartureTime__c);
		DateTime entryDt = DateTime.newInstance(leadIndex.EntryDate__c, ciTime);
		DateTime departDt = DateTime.newInstance(leadIndex.DepartureDate__c, coTime);
		String CheckInDate = xmlNullToBlank(entryDt.format('yyyy-MM-dd'));
		String CheckInTime = xmlNullToBlank(entryDt.format('HH:mm:ss'));
		String CheckOutDate = xmlNullToBlank(departDt.format('yyyy-MM-dd'));
		String CheckOutTime = xmlNullToBlank(departDt.format('HH:mm:ss'));
		// 宿泊日数
		Integer Nights = CommUtils.nullToIntZero(leadIndex.Nights__c);
		// 入込方法
		String Transportaion = xmlNullToBlank((firstLead.Field348__c));
		String TotalRoomCount = xmlNullToBlank(String.valueOf(oneTravelList.size()));
		Integer TotalPaxMaleCount = 0;
		Integer TotalPaxFemaleCount = 0;
		Integer TotalChildA70Count = 0;
		Integer TotalChildB50Count = 0;
		Integer TotalChildC30Count = 0;
		Integer TotalChildDNoneCount = 0;
		for (list<lead__c> oneRoomLst : oneTravelList) {
			Lead__c lead = oneRoomLst[0];
			TotalPaxMaleCount += CommUtils.nullToIntZero(lead.Mans__c);
			TotalPaxFemaleCount += CommUtils.nullToIntZero(lead.Femails__c);
			TotalChildA70Count += CommUtils.nullToIntZero(lead.ChildFA__c);
			TotalChildB50Count += CommUtils.nullToIntZero(lead.Childs__c);
			TotalChildC30Count += CommUtils.nullToIntZero(lead.ChildC__c);
			TotalChildDNoneCount += CommUtils.nullToIntZero(lead.ChildD__c);
		}
		Integer GrandTotalPaxCount = TotalPaxMaleCount
									+TotalPaxFemaleCount
									+TotalChildA70Count
									+TotalChildB50Count
									+TotalChildC30Count
									+TotalChildDNoneCount;
		String PackagePlanName = xmlNullToBlank(firstLead.Field310__r.Name);
		String PackagePlanCode = xmlNullToBlank(firstLead.Field310__r.PackageCode__c);
		String OtherServiceInformation = xmlNullToBlank(leadIndex.Comment__c);

		String tempXml1 = '<BasicInformation><TravelAgencyBookingNumber>$$_TravelAgencyBookingNumber_$$</TravelAgencyBookingNumber><TravelAgencyBookingDate>$$_TravelAgencyBookingDate_$$</TravelAgencyBookingDate><TravelAgencyBookingTime>$$_TravelAgencyBookingTime_$$</TravelAgencyBookingTime><GuestOrGroupNameSingleByte>$$_GuestOrGroupNameSingleByte_$$</GuestOrGroupNameSingleByte><GuestOrGroupNameDoubleByte>$$_GuestOrGroupNameDoubleByte_$$</GuestOrGroupNameDoubleByte><GuestOrGroupNameKanjiName>$$_GuestOrGroupNameKanjiName_$$</GuestOrGroupNameKanjiName><CheckInDate>$$_CheckInDate_$$</CheckInDate><CheckInTime>$$_CheckInTime_$$</CheckInTime><CheckOutDate>$$_CheckOutDate_$$</CheckOutDate><CheckOutTime>$$_CheckOutTime_$$</CheckOutTime>';
		String tempXml2 = '<Nights>$$_Nights_$$</Nights><Transportaion>$$_Transportaion_$$</Transportaion><TotalRoomCount>$$_TotalRoomCount_$$</TotalRoomCount><GrandTotalPaxCount>$$_GrandTotalPaxCount_$$</GrandTotalPaxCount><TotalPaxMaleCount>$$_TotalPaxMaleCount_$$</TotalPaxMaleCount><TotalPaxFemaleCount>$$_TotalPaxFemaleCount_$$</TotalPaxFemaleCount><TotalChildA70Count>$$_TotalChildA70Count_$$</TotalChildA70Count><TotalChildB50Count>$$_TotalChildB50Count_$$</TotalChildB50Count><TotalChildC30Count>$$_TotalChildC30Count_$$</TotalChildC30Count><TotalChildDNoneCount>$$_TotalChildDNoneCount_$$ </TotalChildDNoneCount>';
		String tempXMl3 = '<PackagePlanName>$$_PackagePlanName_$$</PackagePlanName><PackagePlanCode>$$_PackagePlanCode_$$</PackagePlanCode><OtherServiceInformation>$$_OtherServiceInformation_$$</OtherServiceInformation></BasicInformation>';
		
		String returnXml = tempXml1
							.replace('$$_TravelAgencyBookingNumber_$$',TravelAgencyBookingNumber)
							.replace('$$_TravelAgencyBookingDate_$$',TravelAgencyBookingDate)
							.replace('$$_TravelAgencyBookingTime_$$',TravelAgencyBookingTime)
							.replace('$$_GuestOrGroupNameSingleByte_$$',GuestOrGroupNameSingleByte)
							.replace('$$_GuestOrGroupNameDoubleByte_$$',GuestOrGroupNameDoubleByte)
							.replace('$$_GuestOrGroupNameKanjiName_$$',GuestOrGroupNameKanjiName)
							.replace('$$_CheckInDate_$$',CheckInDate)
							.replace('$$_CheckInTime_$$',CheckInTime)
							.replace('$$_CheckOutDate_$$',CheckOutDate)
							.replace('$$_CheckOutTime_$$',CheckOutTime);
							
				returnXml+= tempXml2
							.replace('$$_Nights_$$',String.valueOf(Nights))
							.replace('$$_Transportaion_$$',Transportaion)
							.replace('$$_TotalRoomCount_$$',TotalRoomCount)
							.replace('$$_GrandTotalPaxCount_$$',String.valueOf(GrandTotalPaxCount))
							.replace('$$_TotalPaxMaleCount_$$',String.valueOf(TotalPaxMaleCount))
							.replace('$$_TotalPaxFemaleCount_$$',String.valueOf(TotalPaxFemaleCount))
							.replace('$$_TotalChildA70Count_$$',String.valueOf(TotalChildA70Count))
							.replace('$$_TotalChildB50Count_$$',String.valueOf(TotalChildB50Count))
							.replace('$$_TotalChildC30Count_$$',String.valueOf(TotalChildC30Count))
							.replace('$$_TotalChildDNoneCount_$$',String.valueOf(TotalChildDNoneCount));
				
				returnXml+= tempXml3
							.replace('$$_PackagePlanName_$$',PackagePlanName)
							.replace('$$_PackagePlanCode_$$',PackagePlanCode)
							.replace('$$_OtherServiceInformation_$$',OtherServiceInformation);
		return returnXml;
	}
	private static string generalBasicRateInfo(LeadIndex__c leadIndex, list<list<lead__c>> oneTravelList) {
		String tempXml = '<BasicRateInformation><RoomRateOrPersonalRate>PersonalRate</RoomRateOrPersonalRate><TaxServiceFee>$$_TaxServiceFee_$$</TaxServiceFee><Payment>$$_Payment_$$</Payment></BasicRateInformation>';
		// 該当部屋の一番目予約情報
		Lead__c firstLead = oneTravelList[0][0];
		// 税サ区分出力情報
		// 単価定義区分
		Decimal taxRateKbn = CommUtils.nullToZero(firstLead.UnitPriceDefKb__c);
		if (taxRateKbn == 0) taxRateKbn = CommConst.APPOPTION_UTP_DEF_KB;
		String TaxServiceFee = '';
		if(taxRateKbn == CommConst.APPOPTION_UTP_DEF_KB_OP4){
			TaxServiceFee = 'IncludingServiceWithOutTax';
		}else if(taxRateKbn == CommConst.APPOPTION_UTP_DEF_KB_OP3){
			TaxServiceFee = 'WithoutSerivceAndTax';
		}else if(taxRateKbn == CommConst.APPOPTION_UTP_DEF_KB_OP2){
			TaxServiceFee = 'IncludingServiceAndTax';
		}else if(taxRateKbn == CommConst.APPOPTION_UTP_DEF_KB_OP1){
			TaxServiceFee = 'WithoutServiceAndIncludingTax';
		}
		// 支払い方法
		String Payment = xmlNullToBlank(firstLead.Field315__c);
		// 合計宿泊料金(総額)/TODO
		String returnXml = tempXml
							.replace('$$_TaxServiceFee_$$',TaxServiceFee)
							.replace('$$_Payment_$$',Payment);
		return returnXml;
	}
	//　N部屋のN泊予約情報を作成する
	// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
	//private static string generalRoomAndGuestInfo(LeadIndex__c leadIndex, list<list<lead__c>> oneTravelList) {
	private static string generalRoomAndGuestInfo(LeadIndex__c leadIndex, list<list<lead__c>> oneTravelList, Boolean isEngLangFlg) {
	// 2019/02/28 ブッキングエンジンは多言語対応 By zh END	
		String roomAndGuestInformationXml = '';
		// N部屋のXML情報を作成する
		for (List<Lead__c> oneRoomLeads : oneTravelList) {
//System.debug(loggingLevel.info, 'oneRoomLeads='+oneRoomLeads.size());
//System.debug(loggingLevel.info, 'oneRoomLeads[ID]='+oneRoomLeads[0].ID);
			// 1部屋N泊のXML情報を作成する
			//roomAndGuestInformationXml += '<RoomAndGuestList>'+generalRoomInfo(leadIndex, oneRoomLeads)+'</RoomAndGuestList>';
			roomAndGuestInformationXml += '<RoomAndGuestList>'+generalRoomInfo(leadIndex, oneRoomLeads, isEngLangFlg)+'</RoomAndGuestList>';

		}
		return '<RoomAndGuestInformation>'+roomAndGuestInformationXml+'</RoomAndGuestInformation>';
	}
	// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
	//private static string generalRoomInfo(LeadIndex__c leadIndex, list<lead__c> oneRoomLeads) {
	private static string generalRoomInfo(LeadIndex__c leadIndex, list<lead__c> oneRoomLeads, Boolean isEngLangFlg) {
	// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
		String tempXml = '<RoomInformation><RoomTypeCode>$$_RoomTypeCode_$$</RoomTypeCode><RoomTypeName>$$_RoomTypeName_$$</RoomTypeName><PerRoomPaxCount>$$_PerRoomPaxCount_$$</PerRoomPaxCount><RoomPaxMaleCount>$$_RoomPaxMaleCount_$$</RoomPaxMaleCount><RoomPaxFemaleCount>$$_RoomPaxFemaleCount_$$</RoomPaxFemaleCount><RoomChildA70Count>$$_RoomChildA70Count_$$</RoomChildA70Count><RoomChildB50Count>$$_RoomChildB50Count_$$</RoomChildB50Count><RoomChildC30Count>$$_RoomChildC30Count_$$</RoomChildC30Count><RoomChildDNoneCount>$$_RoomChildDNoneCount_$$</RoomChildDNoneCount></RoomInformation>';
		String returnXml = '';
		// N部屋の連泊予約情報
		// 該当部屋の基本情報を作成する
		Lead__c lead = oneRoomLeads[0];
		String roomTypeCode = xmlNullToBlank(lead.refTypeOfRooms__r.RoomTypeCode__c);
		// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
		//String roomTypeName = xmlNullToBlank(lead.refTypeOfRooms__r.RoomTypeName__c);
		String roomTypeName = xmlNullToBlank(isEngLangFlg ? lead.refTypeOfRooms__r.EnRoomTypeName__c : lead.refTypeOfRooms__r.RoomTypeName__c);
		// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
		String perRoomPaxCount = xmlNullToBlank(lead.StayPersons__c);
		String roomPaxMaleCount = xmlNullToBlank(lead.Mans__c);
		String roomPaxFemaleCount = xmlNullToBlank(lead.Femails__c);
		String roomChildA70Count = xmlNullToBlank(lead.ChildFA__c);
		String roomChildB50Count = xmlNullToBlank(lead.Childs__c);
		String roomChildC30Count = xmlNullToBlank(lead.ChildC__c);
		String roomChildDNoneCount = xmlNullToBlank(lead.ChildD__c);
		// 該当部屋の「部屋情報」
		returnXml += tempXml
                  .replace('$$_RoomTypeCode_$$',roomTypeCode)
                  .replace('$$_RoomTypeName_$$',roomTypeName)
                  .replace('$$_PerRoomPaxCount_$$',perRoomPaxCount)
                  .replace('$$_RoomPaxMaleCount_$$',roomPaxMaleCount)
                  .replace('$$_RoomPaxFemaleCount_$$',roomPaxFemaleCount)
                  .replace('$$_RoomChildA70Count_$$',roomChildA70Count)
                  .replace('$$_RoomChildB50Count_$$',roomChildB50Count)
                  .replace('$$_RoomChildC30Count_$$',roomChildC30Count)
                  .replace('$$_RoomChildDNoneCount_$$',roomChildDNoneCount);
		// 部屋料金情報
		// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
		//returnXml += generalRoomRateInfo(oneRoomLeads);
		returnXml += generalRoomRateInfo(oneRoomLeads, isEngLangFlg);
		// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
		return returnXml;
	}
	// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
	//private static string generalRoomRateInfo(list<lead__c> oneRoomLeads) {
	private static string generalRoomRateInfo(list<lead__c> oneRoomLeads, Boolean isEngLangFlg) {
	// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
		String tempXml = '<RoomRateInformation><RoomDate>$$_RoomDate_$$</RoomDate><ProductCode>$$_ProductCode_$$</ProductCode><ProductName>$$_ProductName_$$</ProductName><UnitPrice>$$_UnitPrice_$$</UnitPrice><Quantity>$$_Quantity_$$</Quantity><TotalNoTax>$$_TotalNoTax_$$</TotalNoTax><TotalIncTax>$$_TotalIncTax_$$</TotalIncTax><TaxRate>$$_TaxRate_$$</TaxRate><ServiceRate>$$ServiceRate_$$</ServiceRate></RoomRateInformation>';
		String returnXml = '';
		// 該当部屋の一番目予約情報
		for (Lead__c lead : oneRoomLeads) {
			String oneLeadXml = '';
			// 予約関連の見積明細情報
			for (BookingEstimateItem__c est : lead.BookingEstimateItemFgKu__r) {
				// 支払Media情報は個別処理[前受付金/支払]
				if (est.ActionType__c == CommConst.PROD_ACTION_TYPE_PY || est.ActionType__c == CommConst.PROD_ACTION_TYPE_AR) {
					continue;
				}
				// 利用日
				Date useDate = est.UseDate__c == null ? lead.EntryTime__c.date() : est.UseDate__c;
				DateTime formatDt = DateTime.newInstance(useDate.year(),useDate.month(),useDate.day());
				String roomDate = xmlNullToBlank(formatDt.format('yyyy-MM-dd'));
				String productCode = xmlNullToBlank(est.Field3__c);
				// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
				//String productName = xmlNullToBlank(est.ProductName__c);
				String productName = xmlNullToBlank(isEngLangFlg ? est.EnProductName__c : est.ProductName__c);
				// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
				String unitPrice = CommUtils.deleteRightZero(CommUtils.nullToBlank(est.UnitPrice__c));
				String quantity = CommUtils.deleteRightZero(CommUtils.nullToBlank(est.Amount__c));
				String totalNoTax = CommUtils.deleteRightZero(CommUtils.nullToBlank(est.GoukeinoneTax__c));
				String totalIncTax = CommUtils.deleteRightZero(CommUtils.nullToBlank(est.Total__c));
				String taxRate = CommUtils.deleteRightZero(CommUtils.nullToBlank(est.TaxRate__c));
				String serviceRate = CommUtils.deleteRightZero(CommUtils.nullToBlank(est.ServiceRate__c));

				oneLeadXml += tempXml
								.replace('$$_RoomDate_$$',roomDate)
								.replace('$$_ProductCode_$$',productCode)
								.replace('$$_ProductName_$$',productName)
								.replace('$$_UnitPrice_$$',unitPrice)
								.replace('$$_Quantity_$$',quantity)
								.replace('$$_TotalNoTax_$$',totalNoTax)
								.replace('$$_TotalIncTax_$$',totalIncTax)
								.replace('$$_TaxRate_$$',taxRate)
								.replace('$$ServiceRate_$$',serviceRate);
				
			}
			returnXml += oneLeadXml;
		}
		return returnXml;
	}
	
	private static CommLogUtils initLog() {
	   CommLogUtils log = new CommLogUtils('WS_BookingEngineService,',true);
	   return log;
	}
	// **************************************
	// 共通処理Method
	// **************************************
	// XMLタグ情報を取得する
	private static string getChildElementByName(Dom.XMLNode parentNode,String elementName){
		if (parentNode == null) return '';
		Dom.XMLNode childrenNode = parentNode.getChildElement(elementName, null);
		return getChildElementValue(childrenNode);
	}
	private static String getChildElementValue(Dom.XMLNode childNode) {
		if (childNode == null) return '';
		return CommUtils.nullToBlank(childNode.getText());
	}
	private static String xmlNullToBlank(Object s) {
		return CommUtils.nullToBlank(s).escapeXml();
	}
    // XMLタグ作成する
    private static String joinTagXml(String tagKey, String val) {
        return joinTagXml(tagKey, val, false);
    }
    private static String joinTagXml(String tagKey, String val, Boolean masttag) {
        return (CommUtils.isBlank(val) ? (masttag ? ('<'+tagKey+'></'+tagKey+'>') : '') : '<'+tagKey+'>'+val+'</'+tagKey+'>');
    }
    // 日付→YYYYMMDD(文字列)
    private static String dateToString(Date dt) {
        return (Datetime.newInstance(dt.year(),dt.month(),dt.day()).format('yyyyMMdd'));
    }
	enum SERVICE_NAME{getroomtypelist,getplanlist,getroomtypeinventorylist,createBooking,getEstimateInfo,getbookinglist}
	
    // 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
    private static Boolean isEngLang(string lang){
    	return (CommUtils.nullToBlank(lang) == '2');
    }
    // 2019/02/28 ブッキングエンジンは多言語対応 By zh END
}