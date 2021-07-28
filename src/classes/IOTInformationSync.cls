/**
* IOT機能
* 2016/09/30 音通知機能と文言ジョイン機能の追加
* 2016/12/23 IOT状態管理機能の追加
* 2017/04/24 RECAIUS機能統合対応
**/
global with sharing class IOTInformationSync {
	public static final String IotKey = 'IOT';
	private static final Boolean IotMessageJoinFlg = CommDefine__c.getOrgDefaults().IotMessageJoinFlg__c == null ? false : CommDefine__c.getOrgDefaults().IotMessageJoinFlg__c;
	private static final Boolean IotMessageToChatterFlg = CommDefine__c.getOrgDefaults().IotMessageToChatterFlg__c == null ? true : CommDefine__c.getOrgDefaults().IotMessageToChatterFlg__c;
    // 2016/12/23 IOT状態管理機能の追加 BEGIN
    private static final Boolean IotStatusManagerFlg = CommDefine__c.getOrgDefaults().IotNormalStatusAlertFlg__c == null ? true : CommDefine__c.getOrgDefaults().IotNormalStatusAlertFlg__c;
    private static final String MessagetStatusInfo = 'Info';
    // 2016/12/23 IOT状態管理機能の追加 END
    webservice static IOTInformationSyncResult createCallInformation(IOTInformation callInfo) {
        try{
        	// 必須チェック
        	if(IotMessageJoinFlg) {
        		if (CommUtils.isBlank(CommUtils.nullToBlank(callInfo.sno)) || CommUtils.isBlank(CommUtils.nullToBlank(callInfo.NAM)) || CommUtils.isBlank(CommUtils.nullToBlank(callInfo.dt1))|| CommUtils.isBlank(CommUtils.nullToBlank(callInfo.dt4))) 
        			return new IOTInformationSyncResult('必須連携項目(SNO/NAM/DT1/DT4)がありません。');
        	} else {
        		if (CommUtils.isBlank(CommUtils.nullToBlank(callInfo.sno)) || CommUtils.isBlank(CommUtils.nullToBlank(callInfo.NAM)) || CommUtils.isBlank(CommUtils.nullToBlank(callInfo.dt1))) 
        			return new IOTInformationSyncResult('必須連携項目(SNO/NAM/DT1)がありません。');
        	}
        	// 2016/12/23 IOT状態管理機能の追加 BEGIN
        	String iotMessageLevel = getIotMessageLevel(callInfo);
        	Boolean locSendMessageFlg = (iotMessageLevel == MessagetStatusInfo && IotStatusManagerFlg) || (iotMessageLevel != MessagetStatusInfo);
        	// 2016/12/23 IOT状態管理機能の追加 END
			// エラー通知先のチャターグループ名を取得する
			List<String> chatterGroupNamesLst = CommConst.GetChatterGroupNameByCode(CommConst.IOT_ChatterGroupNameType);
			if (chatterGroupNamesLst.isEmpty() && IotMessageToChatterFlg) return new IOTInformationSyncResult('共通定義(チャターグループ名)にIOT通知用グループを未定義ため、通知失敗になる');
			// 2017/05/11 Iotのワーニングメッセージの文言を変更できるように改善対応 BEGIN
			iotIconDefMap = CommNoAuthLimitUtil.getIotIconInfoMap(getIotIconTypeList());
			// 2017/05/11 Iotのワーニングメッセージの文言を変更できるように改善対応 END
		 	// 2016/12/23 IOT状態管理機能の追加 BEGIN
		 	//if (!chatterGroupNamesLst.isEmpty() && IotMessageToChatterFlg) {
		 	if (!chatterGroupNamesLst.isEmpty() && IotMessageToChatterFlg && locSendMessageFlg) {
	 		// 2016/12/23 IOT状態管理機能の追加 END
			 	// エラー通知先のチャターグループ名を取得する
				List<CollaborationGroup> chatterGroups = [select Id, Name from CollaborationGroup where name = :chatterGroupNamesLst and isarchived = false];
	        	if (chatterGroups.isEmpty()) return new IOTInformationSyncResult('IOT通知用グループ['+chatterGroupNamesLst+']が見つかりません、通知失敗になる');
	        	List<FeedItem> feedItems = new List<FeedItem>();
	        	// IOT情報はChatterに通知処理
	    		String title = callInfo.nam;
	    		//様、ご到着されましたので、ご案内ください
	    		// 2017/04/24 RECAIUS機能統合対応 BEGIN
	    		String bodyMessage = '';
	    		//if (!CommConst.ChatterGroupSimpleMsgFlg) {
	    		//	bodyMessage = getMessage(callInfo,false,true);
	    		//} else {
	    		//	bodyMessage = getMessage(callInfo,true,true);
	    		//}
	    		bodyMessage = getMessage(callInfo,CommConst.ChatterGroupSimpleMsgFlg,true);
	    		// 2017/04/24 RECAIUS機能統合対応 END
	    		for (CollaborationGroup gp : chatterGroups) {
	    			feedItems.add(sendMessageToChatter(gp.Id, title, bodyMessage));
	    		}
				// Chatterへポストする
	        	if (!feedItems.isEmpty()) insert feedItems;
		 	}
       		// 2016/11/10 IOT情報はメッセージオブジェクトに転送処理を行う
        	syncIotInfoToMessage(callInfo);
			// 2016/09/30 音通知機能と文言ジョイン機能の追加　BEGIN
			Boolean IotSpeechAlertFlg = CommDefine__c.getOrgDefaults().IotSpeechAlertFlg__c == null ? true : CommDefine__c.getOrgDefaults().IotSpeechAlertFlg__c;
        	//if (IotSpeechAlertFlg) {
        	if (IotSpeechAlertFlg && locSendMessageFlg) {
        	// 2016/09/30 音通知機能と文言ジョイン機能の追加　END
	        	// 音送信を行う
	        	String iotMessage = getMessage(callInfo,true,true);
	        	//iotMessage = iotMessage.length() > 255 ? iotMessage.substring(0,255) : iotMessage;
	        	Call_information__c newCall = new Call_information__c(
	        		NAM__c = iotMessage,
	        		CallType__c = IotKey,
	        		DNO__c = callInfo.dno,
	        		MessageUUID__c = CommUtils.getGUID()
	        	);
	            if(CommUtils.nullToBlank(callInfo.cdt).length() == 8 && CommUtils.nullToBlank(callInfo.ctm).length() == 6) {
	            	try {
	                	newCall.Call_Time__c = DateTime.newInstance(
	                                            Integer.valueOf(callInfo.cdt.substring(0, 4)),      // Year
	                                            Integer.valueof(callInfo.cdt.substring(4, 6)),      // Month
	                                            Integer.valueOf(callInfo.cdt.substring(6, 8)),      // Day 
	                                            Integer.valueOf(callInfo.ctm.substring(0, 2)),      // Hour
	                                            Integer.valueOf(callInfo.ctm.substring(2, 4)),      // Minutes
	                                            Integer.valueOf(callInfo.ctm.substring(4, 6)));     // Seconds
	            	} catch (Exception e){}
				}
	        	integer maxDbCount = 10;
	        	list<Call_information__c> callLst = [select id from Call_information__c where CallType__c = :IotKey order by Call_Time__c asc, LastmodifiedDate asc limit :maxDbCount];
	        	if (callLst.size() < 10 ) {
	        		insert newCall;
	        	} else {
	        		newCall.id = callLst[0].Id;
	        		update newCall;
	        	}
        	}
        	// 2016/09/30 音通知機能と文言ジョイン機能の追加　END
			return new IOTInformationSyncResult();
        }
        catch(Exception ex){
            /**
            * If there is an exception then return errorMessage with isSuccess as false
            */
            return new IOTInformationSyncResult(ex.getMessage());
        }
    }
    // 2017/05/11 Iotのワーニングメッセージの文言を変更できるように改善対応 BEGIN
    private static String getCustomMsg(IOTInformation callInfo) {
    	String callInfoType = callInfo.NAM;
    	String customMsg = '';
    	String comDefMsg = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().IotMessageCustomDef__c);
    	if (CommUtils.isBLank(comDefMsg)) return customMsg;
    	List<String> comDefMsgLst = comDefMsg.split(';');
    	for (String customMsgItem : comDefMsgLst) {
    		Integer keyPos = customMsgItem.indexOf(':');
//System.debug(loggingLevel.info, 'keyPos='+keyPos);
    		if (keyPos < 1 ) continue;
    		String key = CommUtils.nullToBlank(customMsgItem.substring(0,keyPos));
    		String msg = CommUtils.nullToBlank(customMsgItem.substring(keyPos+1));
//System.debug(loggingLevel.info, 'key='+key);
//System.debug(loggingLevel.info, 'msg='+msg);
    		if (CommUtils.isBlank(msg)) continue;
    		if (callInfoType == key) {
    			customMsg = msg.replace('@location',callInfo.dt1)
    							.replace('@value',callInfo.sno)
    							.replace('{dt0}',callInfo.dt0);// 公開なし
    			return customMsg;
    		}
    	}
    	
    	return customMsg;
    }
    // 2017/07/20 Iotのワーニングメッセージの文言にICONは含めるがどうか対応 BEGIN
    private static string getMessage(IOTInformation callInfo, Boolean isSimpleFlg, Boolean isHavePreFix) {
        return getMessage(callInfo, isSimpleFlg, isHavePreFix, false);
    }
    // 2017/07/20 Iotのワーニングメッセージの文言にICONは含めるがどうか対応 END
    // 2017/05/11 Iotのワーニングメッセージの文言を変更できるように改善対応 END
    // 2017/07/20 Iotのワーニングメッセージの文言にICONは含めるがどうか対応 BEGIN
    //private static string getMessage(IOTInformation callInfo, Boolean isSimpleFlg, Boolean isHavePreFix) {
    private static string getMessage(IOTInformation callInfo, Boolean isSimpleFlg, Boolean isHavePreFix, Boolean isHtmlIconFlg) {
    // 2017/07/20 Iotのワーニングメッセージの文言にICONは含めるがどうか対応 END
    	// 2017/05/11 Iotのワーニングメッセージの文言を変更できるように改善対応 BEGIN
    	String customMsg = getCustomMsg(callInfo);
    	if (!CommUtils.isBlank(customMsg)) {
    		if (customMsg.length() > 255) customMsg = customMsg.substring(0,255);
    		String errLevel = getIotMessageLevel(callInfo);
    		for (String key : iotIconDefMap.keySet()) {
    			if (key.endsWithIgnoreCase(errLevel)) {
    			    // 2017/07/20 Iotのワーニングメッセージの文言にICONは含めるがどうか対応 BEGIN
    				//if (!isSimpleFlg) customMsg = '<img src="sfdc://'+iotIconDefMap.get(key)+'" />'+customMsg;
    				String[] idArr = (iotIconDefMap.get(key)).split(':');
    				String iconUrl = '<img src="sfdc://'+idArr[0]+'" />';
    				if (isHtmlIconFlg) iconUrl = '<img src="/sfc/servlet.shepherd/version/download/'+idArr[1]+'" />';
    				if (!isSimpleFlg) customMsg = iconUrl+customMsg;
    				break;
    			}
    		}
    		return customMsg;
    	}
    	// 2017/05/11 Iotのワーニングメッセージの文言を変更できるように改善対応 END
    	String strPreFix = isSimpleFlg ? 'Warning Message: ' : '<b>⚠</b> Warning Message: ';
    	// 2016/12/23 IOT状態管理機能の追加 BEGIN
    	String iotMessageLevel = getIotMessageLevel(callInfo);
    	if (iotMessageLevel == MessagetStatusInfo) {
    		strPreFix = isSimpleFlg ? 'Information Message: ' : '<b>⚠</b> Information Message: ';
    	}
    	// 2016/12/23 IOT状態管理機能の追加 END
    	if (!isHavePreFix) strPreFix  = '';
		String strType = ' 水量 ';
    	String strunit = 'リットル';
    	if (callInfo.NAM == 'WaterTemperature') {
    		strType = ' 水温 '; 
    		strunit = '度';
    	}
    	if (callInfo.NAM == 'Persons') {
    		strType = ' 人数 '; 
    		strunit = '人';
    	}
		// 2016/09/30 音通知機能と文言ジョイン機能の追加　BEGIN
    	if (IotMessageJoinFlg) {
			strType = '';
    		strunit = '';
			String[] msgTmplate = CommUtils.nullToBlank(callInfo.dt4).split(',');
    		if (msgTmplate.size() > 0) {
    			String wkStrType = CommUtils.nullToBlank(msgTmplate[0]).removeStart('"').removeEnd('"');
    			strType = ' ' + wkStrType + ' ';
    		}
    		if (msgTmplate.size() > 1) {
    			String wkStrunit = CommUtils.nullToBlank(msgTmplate[1]).removeStart('"').removeEnd('"');
    			strunit = wkStrunit;
    		}
    	}
    	// 2016/09/30 音通知機能と文言ジョイン機能の追加　END
    	String iotMessage = strPreFix + CommUtils.nullToBlank(callInfo.dt1) + strType + callInfo.sno + strunit;
    	return (iotMessage.length() > 255 ? iotMessage.substring(0,255) : iotMessage);
    }
	private static FeedItem sendMessageToChatter(Id chatterGroupId, String tilte, String bodyMessage) {
		FeedItem post = new FeedItem();
		post.Type = 'TextPost';
		//post.title = tilte;
	    post.Body = bodyMessage;
	    post.ParentId = chatterGroupId;
	    post.IsRichText = true;
	    return post;
	}
    /**
    * This wrapper is used to send information to the web service in Salesforce
    */
    global class IOTInformation{
        webservice String sno{get;set;}
        webservice string nam{get;set;}
        webservice String lno{get;set;}
        webservice String ctm{get;set;}
        webservice String cdt{get;set;}
        webservice boolean rsnp{get;set;}
        webservice String  rsnCode{get;set;}
        webservice boolean dcd1{get;set;}
        webservice String dt0{get;set;}
        webservice String dt1{get;set;}
        webservice String dt4{get;set;}
        webservice String dno{get;set;}
    }
    
    /**
    * This wrapper is used to send result from web service
    */
    global class IOTInformationSyncResult{
        //webservice Id sfdcId{get;set;}
        webservice boolean isSuccess{get;set;}
        webservice string errorMessage{get;set;}
        
        /**
        * Create success instance
        */
        IOTInformationSyncResult(){
            //this.sfdcId = sfdcId;
            isSuccess = true;
        }
        
        /**
        * Create error instance
        */
        IOTInformationSyncResult(String errorMessage){
            this.errorMessage = errorMessage;
            isSuccess = false;
        }
    }
    // 2016/11/10 IOT情報はメッセージオブジェクトに転送処理を行う
    private static void syncIotInfoToMessage(IOTInformation callInfo) {
    	// 音送信を行う
    	// 2017/07/20 Iotのワーニングメッセージの文言にICONは含めるがどうか対応 BEGIN
    	//String iotMessage = getMessage(callInfo,false,false);
    	String iotMessage = getMessage(callInfo,false,false,true);
    	// 2017/07/20 Iotのワーニングメッセージの文言にICONは含めるがどうか対応 END
    	String uuid = CommUtils.getGUID();
    	MessageInformation__c newCall = new MessageInformation__c(
    		Name = IotKey + '_' + System.now().format('yyyyMMddHHmmssSSS'),
    		Message__c = iotMessage,
    		MessageType__c = IotKey,
    		MessageUUID__c = uuid,
    		// 2016/12/23 IOT状態管理機能の追加 BEGIN
    		MessageLevel__c = getIotMessageLevel(callInfo),
    		// 2016/12/23 IOT状態管理機能の追加 END
    		MessageSub1__c = callInfo.dt1//Location
    	);
        if(CommUtils.nullToBlank(callInfo.cdt).length() == 8 && CommUtils.nullToBlank(callInfo.ctm).length() == 6) {
        	try {
            	newCall.MessageDtTime__c = DateTime.newInstance(
                                        Integer.valueOf(callInfo.cdt.substring(0, 4)),      // Year
                                        Integer.valueof(callInfo.cdt.substring(4, 6)),      // Month
                                        Integer.valueOf(callInfo.cdt.substring(6, 8)),      // Day 
                                        Integer.valueOf(callInfo.ctm.substring(0, 2)),      // Hour
                                        Integer.valueOf(callInfo.ctm.substring(2, 4)),      // Minutes
                                        Integer.valueOf(callInfo.ctm.substring(4, 6)));     // Seconds
        	} catch (Exception e){}
		}
    	integer maxDBRecords = 10;
        maxDBRecords = CommUtils.nullToIntZero(CommDefine__c.getOrgDefaults().maxrecords_DB__c);
    	list<MessageInformation__c> callLst = [select id from MessageInformation__c where MessageType__c = :IotKey order by LastmodifiedDate asc limit :maxDBRecords];
    	if (callLst.size() < 10 ) {
    		insert newCall;
    	} else {
    		newCall.id = callLst[0].Id;
    		update newCall;
    	}
    }
    
    // 2016/12/23 IOT状態管理機能の追加 BEGIN
    private static string getIotMessageLevel(IOTInformation callInfo) {

		String errorLevel = CommUtils.nullToBlank(callInfo.dt0);
    	if (errorLevel == 'Normal') {
    		return MessagetStatusInfo;
    	} else if (errorLevel.contains('Warning')) {
    		return 'Warn';
    	} else return 'Error';
    }
    // 2016/12/23 IOT状態管理機能の追加 END
    // 2017/05/11 Iotのワーニングメッセージの文言を変更できるように改善対応 BEGIN
    private static map<string,String> iotIconDefMap;
    public static final String IOT_ICON_ERROR = 'IOTMESSAGE_ICON_ERROR';
    public static final String IOT_ICON_WARN = 'IOTMESSAGE_ICON_WARN';
    public static final String IOT_ICON_NORMAL = 'IOTMESSAGE_ICON_INFO';
    public static list<string> getIotIconTypeList() {
    	return new List<String>{IOT_ICON_ERROR,IOT_ICON_WARN,IOT_ICON_NORMAL};
    }
    // 2017/05/11 Iotのワーニングメッセージの文言を変更できるように改善対応 END
}