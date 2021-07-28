/**
* 連絡事項情報編集、保存処理機能
* 2014/10/27 INIT
* 2018/05/28 複数店舗連絡事項を同時に表示できる対応
* 2019/05/15 予定表指定日にて、連絡事項を表示する機能対応
*/
global with sharing class MessageItemCtrl {
 	public boolean isCanUpdateLead{get{return CommSecurityUtils.isCanUpdateable(MessageItem__c.sObjectType);}}
 	
	// 指定日付/年月により、既存情報を画面に表示する
	public String yyyymmdd{get;set;}
	public integer messageMaxRows{get;set;}
	//2016/12/15 ルームインジケータ、連絡事項店舗区分 by wx begin
	public String messageshopcode{get;set;}
	//2016/12/15 ルームインジケータ、連絡事項店舗区分 by wx end
	// 連絡事項情報を格納
	public MessageItem__c messageObj{get; set;}
	public MessageItem__c updMessageObj{get;set;}
	private Integer MESSAGE_ITEM_FIELD_LEN;
	// 2018/05/28 複数店舗連絡事項を同時に表示できる対応 WSQ BEGIN
	public Boolean isOldDataFlg{get;private set;}
	//public String noUpdMessageField{get;set;}
	//2016/12/15 ルームインジケータ、連絡事項店舗区分 by wx begin
	private final static boolean messageShopCodeDivFlg{get{return CommDefine__c.getOrgDefaults().MessageShopCodeDivFlg__c;}}	//2016/12/15 ルームインジケータ、連絡事項店舗区分 by wx end
	//2016/12/15 ルームインジケータ、連絡事項店舗区分 by wx end
	// 2018/05/28 複数店舗連絡事項を同時に表示できる対応 WSQ END
	public MessageItemCtrl() {}
	public String lastYearMsgJson{get; set;}
	public void getInit() {
		refreshMessage();
		MESSAGE_ITEM_FIELD_LEN = messageMaxRows * 4;
	}
	// 最新情報を取得する
	public void refreshMessage() {
		
		MessageItem__c newMessage = queryLastInfo(false);
		if (messageObj == null) {
			messageObj = newMessage.clone(false,false);
			updMessageObj = new MessageItem__c();
			return;
		}
		MessageItem__c locNewFlgObj = null;
		if(messageObj.Name == newMessage.Name){
			for (Integer i =1; i <= MESSAGE_ITEM_FIELD_LEN; i++) {
				String fieldName = 'Message' + i + '__c';
				String nwMsg = CommUtils.nullToBlank(newMessage.get(fieldName)) ;
				String curMsg = CommUtils.nullToBlank(messageObj.get(fieldName)) ;
				if (nwMsg != curMsg) {
					if (locNewFlgObj == null) locNewFlgObj = new MessageItem__c();
					locNewFlgObj.put(fieldName,nwMsg);
				}
			}
			if (locNewFlgObj != null) updMessageObj = locNewFlgObj;
		}else updMessageObj = new MessageItem__c();
		messageObj = newMessage.clone(false,false);
	}
	// 2019/05/15 予定表指定日にて、連絡事項を表示する機能対応 WGCH BEGIN
	public MessageItem__c queryLastInfo(String pQueryDt, String shopCode, Decimal msgMaxRows){
		yyyymmdd = pQueryDt;
		messageshopcode = shopCode;
		messageMaxRows = msgMaxRows.intValue();
		return queryLastInfo(false, true); 
	}
	private  MessageItem__c queryLastInfo (Boolean isLock) {
		return queryLastInfo(isLock, false);
	}
	// private  MessageItem__c queryLastInfo (Boolean isLock) {
	private MessageItem__c queryLastInfo(Boolean isLock, Boolean liModeFlg) {
	// 2019/05/15 予定表指定日にて、連絡事項を表示する機能対応 WGCH END
		MessageItem__c rs = null;
		Date currDate = Date.today();
		String formatStr = 'yyyyMM';
		if (yyyymmdd.length()==6) {
			currDate = CommUtils.stringToDate(yyyymmdd+'01');
		} else if (yyyymmdd.length()==8) {
			currDate = CommUtils.stringToDate(yyyymmdd);
			formatStr = 'yyyyMMdd';
		}
		// 去年の年月
		String currYmd = yyyymmdd;
		String oldYmd = currDate.addYears(-1).year() + yyyymmdd.mid(4,4);
		String querySql = CommSqlUtils.generateQueryString('MessageItem__c');
		String querySort = ' order by name desc ';
		if (isLock) querySort = '';
		//2016/12/15 ルームインジケータ、連絡事項店舗区分 by wx begin
		String queryShop = '';
		if(messageShopCodeDivFlg && !CommUtils.isBlank(messageshopcode)){
			currYmd += '_' + messageshopcode;
			oldYmd += '_' + messageshopcode;
			queryShop = ' And ShopCodeRef__r.ShopCode__c = :messageshopcode ';
		}
		//if (Commconst.OLDDATE_ISSHOW_MESSAGE) querySql += ' where name = :currYmd or name = :oldYmd ' + querySort + 'limit 2 ';
		//else querySql += ' where name = :currYmd ' + querySort + ' limit 1 ';
		if (Commconst.OLDDATE_ISSHOW_MESSAGE) querySql += ' where ( name = :currYmd or name = :oldYmd) ' + queryShop + querySort + 'limit 2 ';
		else querySql += ' where name = :currYmd ' + queryShop + querySort + ' limit 1 ';
		//2016/12/15 ルームインジケータ、連絡事項店舗区分 by wx end
		// 2018/05/28 複数店舗連絡事項を同時に表示できる対応 BEGIN
		isOldDataFlg = false;
		// 2018/05/28 複数店舗連絡事項を同時に表示できる対応 END
		List<MessageItem__c> msgLst = DataBase.query(querySql);
		if (msgLst.isEmpty()) {
			// 今年の連絡事項がなかった場合、去年の同じ年月の
			rs = new MessageItem__c(name=currYmd);
		} else {
			// 2018/05/28 複数店舗連絡事項を同時に表示できる対応 BEGIN
			// 現状のデータは過去履歴データから作成の場合、フラグはTRUEに設定する
			if (msgLst[0].Name == oldYmd) {
				isOldDataFlg = true;
			}
			// 2018/05/28 複数店舗連絡事項を同時に表示できる対応 END
			// 既存情報の場合
			rs = msgLst[0].clone(false,true);
			rs.Name = currYmd;
			rs.ownerId = UserInfo.getUserId();
		}
		// 2018/12/15 ルームインジケータ画面に連絡事項は１項目に変更対応 by cxw BEGIN
		if(isOldDataFlg || rs.MessageRich__c == null){
			String messageRich = '';
			JSONGenerator gen = JSON.createGenerator(false);
			gen.writeStartObject();
			for(Integer i = 1; i <= (messageMaxRows * 4); i++){
				String f = 'Message' + i + '__c';
				try{
					String msg = CommUtils.nullToBlank(rs.get(f));
					if(!CommUtils.isBlank(msg)){
						// 2019/05/15 予定表指定日にて、連絡事項を表示する機能対応 WGCH BEGIN
						// if(rs.MessageRich__c == null) messageRich += msg + '<br/>';
						if(rs.MessageRich__c == null){
							messageRich += liModeFlg ? ('<li>' + msg + '</li>') : (msg + '<br/>');
						}
						// 2019/05/15 予定表指定日にて、連絡事項を表示する機能対応 WGCH END
						if(isOldDataFlg) gen.writeObjectField(f, msg);
					}
				}catch(Exception e){}
			}
			gen.writeEndObject();
			if(rs.MessageRich__c == null) rs.MessageRich__c = messageRich;
			lastYearMsgJson = gen.getAsString();
		}
		// 2018/12/15 ルームインジケータ画面に連絡事項は１項目に変更対応 by cxw END
		return rs;
	}
	// 2018/05/28 複数店舗連絡事項を同時に表示できる対応 BEGIN
	@RemoteAction
	global static String updateMessage(string updStr,String name, String messageshopcode) {
	// 2018/05/28 複数店舗連絡事項を同時に表示できる対応 END
		try {
			// 2017/02/21 Field Security Check BEGIN
			List<String> chkFields = new List<String>{'ShopCodeRef__c','ownerId','Name'};
			Map<String,Schema.SObjectField> m = Schema.SObjectType.MessageItem__c.fields.getMap();
			if (!CommSecurityUtils.isCanUpsertable(chkFields, m)) {
				return '';
			}
			// 2017/02/21 Field Security Check End
			// 2018/05/28 複数店舗連絡事項を同時に表示できる対応 BEGIN
			MessageItem__c updItem = new MessageItem__c(Name = name);
			/*
			if(!CommUtils.isBlank(noUpdMessageField)){
				for(integer i = 1 ; i <= MESSAGE_ITEM_FIELD_LEN ; i++){
					String fieldName = 'Message' + i + '__c';
					if(!noUpdMessageField.contains(fieldName))
						updItem.put(fieldName,messageObj.get(fieldName));
				}
			}else updItem = messageObj;
			*/
			Map<String, Object> obj = (Map<String, Object>)JSON.deserializeUntyped(updStr);
			for (String key : obj.keySet()) {
				updItem.put(key, CommUtils.nullToBlank(obj.get(Key)));
			}
			// 2018/05/28 複数店舗連絡事項を同時に表示できる対応 END
			//2016/12/15 ルームインジケータ、連絡事項店舗区分 by wx begin
			if(messageShopCodeDivFlg && !CommUtils.isBlank(messageshopcode)){
				Id ShopCode = ShopInfoUtil.getShop(messageshopcode).id;
				updItem.ShopCodeRef__c = ShopCode;
			}
			//2016/12/15 ルームインジケータ、連絡事項店舗区分 by wx end			
			Database.upsert(updItem, MessageItem__c.Name);
			// 2018/05/28 複数店舗連絡事項を同時に表示できる対応 BEGIN
			//noUpdMessageField = '';
			//refreshMessage();
			// 2018/05/28 複数店舗連絡事項を同時に表示できる対応 END
		} catch (Exception e) {
			String errMsg = e.getMessage();
			// 2018/05/28 複数店舗連絡事項を同時に表示できる対応 BEGIN
			//if(!CommUtils.isFieldValidationMessage(errMsg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
			throw new CommException(CommUtils.getFieldValidationMessage(errMsg));
			// 2018/05/28 複数店舗連絡事項を同時に表示できる対応 END
		}
		// 2018/05/28 複数店舗連絡事項を同時に表示できる対応 BEGIN
		return '';
		// 2018/05/28 複数店舗連絡事項を同時に表示できる対応 END
	}
}