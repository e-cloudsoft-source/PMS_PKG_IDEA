/**
* おもてなし連携機能対応
* 2017/01/01 INIT 
*/
@RestResource(urlMapping='/pmsservice/V1/jtbplus/getuserinfo')
global with sharing class WS_SyncJTBContactInfo {
	// timeout limit
	private static final integer COMMON_TA_CALL_TIME_OUT_VALUE = 120000;
	
    @HttpGet
    global static void doGet() {
    	// 連携IDはSF側に格納する
		RestRequest req = RestContext.request;
system.debug(LoggingLevel.INfo, ' RestContext.request.params :: '+  RestContext.request.params);        
        String collaborationId=req.params.get('collaborationId'); 
        if (!Test.isRunningTest()) {
        	try {
        		processRequest( collaborationId);
        	} catch (Exception e) {
        		RestResponse rep = RestContext.response;
        		rep.statusCode = 417;
        		rep.responseBody = Blob.valueOf(e.getMessage());
        	}
        }
    }
    /*
    @HttpPost
    global static void doPost() {
    	// 連携IDはSF側に格納する
    	// 連携IDはSF側に格納する
		RestRequest req = RestContext.request;
system.debug(LoggingLevel.INfo, ' RestContext.request.params :: '+  RestContext.request.params);        
		String strXmlBody = req.requestBody != null ? CommUtils.nullToBlank(req.requestBody.toString()) : '';
		Map<String,Object> rsMap = (Map<String,Object>)JSON.deserializeUntyped(strXmlBody);
		
		if (!CommUtils.isBLank(bodyStr) && bodyStr.indexOf('collaborationId=') >= 0) {
			List<String> paramterLst = bodyStr.split('collaborationId=');
			if (paramterLst.size() > 1) {
				String response = processRequest( paramterLst[1]);
			}
		}
    }   */ 
    /**
    *　取得した連携指示IDでおもてなしからお客様情報を取得する
    **/
    @TestVisible
    private static String processRequest(String collaborationId) {
system.debug(LoggingLevel.INfo, ' collaborationId :: '+  collaborationId);   
    	try {
	    	// おもてなしへ認証情報をXMLから取得する
	    	// 2017/02/03 SF既存のお客様とマッピングルールのXML情報を取得する zyz
	    	XmlDefInfo authInfo = loadSyncLoginInfo();
	    	// client_id/client_secretをBase64化して、ユーザとパスワードも設定、OAUTH認証する
	    	String currentToken = getToken(authInfo);
	    	// 認証後のTOKENと連携IDで属性情報を取得する
	    	Map<String,Object> dataJsonMap = getMemberGet(authInfo, currentToken, collaborationId);
	    	// RESPONSEの情報はSF側のお客様へ更新を行う
	    	//String currentToken = 
			// 2017/02/03 SF既存のお客様とマッピングルール zyz BEGIN
	    	if (!dataJsonMap.isEmpty()) syncContact(dataJsonMap, collaborationId, authInfo);
			// 2017/02/03 SF既存のお客様とマッピングルール zyz END
    		// 処理結果はRESPONE設定を行う
    	} catch (CommException e) {
    		throw e;
    	} catch (Exception ex) {
system.debug(logginglevel.info, ex.getStackTraceString());
			throw new CommException('属性連携処理エラーが発生しました(' + ex.getMessage() + ')');
    	}
    	return '';
    }
	// TOKEN情報取得URL
    static String tokenUrl = '/oauth/token';
    // 連携属性情報を取得
    //static String serverAttPostUrl = '/collaboration-service/attributes/';
    /*
    * ユーザ認証によるアクセストークン取得
    */
    // 2017/02/03 SF既存のお客様とマッピングルールのXML情報を取得する zyz
    private static String getToken(XmlDefInfo authInfo){
try {
    	Map<String,String> paramap = new Map<String,String>{'username' => authInfo.user_id,'password' => authInfo.password,'grant_type' =>'password'};
    	HttpRequest req = new HttpRequest();
    	String postMessage = 'Basic ' + EncodingUtil.base64Encode(Blob.valueof(authInfo.clined_id + ':' + authInfo.client_secret));
    	req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
		req.setHeader('Authorization', postMessage);
		req.setMethod('POST');
		String endPoint = authInfo.domainUrl + tokenUrl;
		HTTPResponse rep = sendRequest(req,endPoint, paraMap) ;
		String strXmlBody = CommUtils.nullToBlank(rep.getBody());
		if (!Commutils.isBlank(strXmlBody)) {
			// 取得
			Map<String,Object> rsMap = (Map<String,Object>)JSON.deserializeUntyped(strXmlBody);
			return CommUtils.nullToBlank(rsMap.get('access_token'));
		}
} catch (CommException e) {
	throw new CommException('「おもてなしへOauth認証」エラーが発生しました(' + e.getMessage() + ')');
}
		return '';
    }
    /*
    * おもてなしへ認証情報をXMLから取得する
    */
	// 2017/02/03 SF既存のお客様とマッピングルールのXML情報を取得する zyz BEGIN
    private static XmlDefInfo loadSyncLoginInfo() {
    	XmlDefInfo info = new XmlDefInfo();
    // 2017/02/03 SF既存のお客様とマッピングルールのXML情報を取得する zyz END
    	// テギのXML情報を取得する
    	Dom.XmlNode rootElement =  CommXmlUtils.parseXmlDoc('JTBSyncInfoConfig', '');
    	Dom.XmlNode authRoot =  rootElement.getChildElement('AUTHINFO', null);
    	if (authRoot != null) {
    		Dom.XmlNode domainUrlField = authRoot.getChildElement('domainUrl',null);
    		Dom.XmlNode clined_idField = authRoot.getChildElement('clined_id',null);
    		Dom.XmlNode client_secretField = authRoot.getChildElement('client_secret',null);
    		Dom.XmlNode user_idField = authRoot.getChildElement('user_id',null);
    		Dom.XmlNode passwordField = authRoot.getChildElement('password',null);
    		if (domainUrlField != null) info.domainUrl = CommUtils.nullToBlank(domainUrlField.getText());
    		if (clined_idField != null) info.clined_id = CommUtils.nullToBlank(clined_idField.getText());
    		if (client_secretField != null) info.client_secret = CommUtils.nullToBlank(client_secretField.getText());
    		if (user_idField != null) info.user_id = CommUtils.nullToBlank(user_idField.getText());
    		if (passwordField != null) info.password = CommUtils.nullToBlank(passwordField.getText());
    	}
		// 2017/02/03 SF既存のお客様とマッピングルールのXML情報を取得する zyz BEGIN
		
		info.jsonKeyLst = new List<string>();
		info.sfKeyLst = new List<string>();
		Dom.XmlNode conMapping =  rootElement.getChildElement('CONTACT_MAPPING', null);
		//String sqlWhere = '';
		if (conMapping != null) {
			//String childAttributeName = conMapping.getName();
			for (Dom.XMLNode childNode : conMapping.getChildElements()){
				String childNodeNm = childNode.getName();
				//if (childNodeNm.equalsIgnoreCase('LOGIC')){
				//	info.whereLogicDef = childNode.getText();
				if (childNodeNm.equalsIgnoreCase('MAPPING')) {
					Dom.XmlNode jsonkeyField = childNode.getChildElement('JSONKEY',null);
					Dom.XmlNode sfkeyField = childNode.getChildElement('SFKEY',null);
					if (jsonkeyField == null || sfkeyField == null) continue;
					String jsonkey = CommUtils.nullToBlank(jsonkeyField.getText());
					String sfkey = CommUtils.nullToBlank(sfkeyField.getText());
					if (CommUtils.isBlank(jsonkey) || CommUtils.isBlank(sfkey)) continue;
					//info.whereDefLst.add(new map<string,string>{sfkey=>jsonkey});
					info.jsonKeyLst.add(jsonkey);
					info.sfKeyLst.add(sfkey);
				}
			}
			// SQL情報を作成する
		}
		// 2017/02/03 SF既存のお客様とマッピングルールのXML情報を取得する zyz END
//system.debug(LoggingLevel.INfo, ' info :: '+  info);   
    	return info;
    }
    // 2017/02/03 SF既存のお客様とマッピングルール  collaborationId zyz
    class XmlDefInfo {
    	public String domainUrl{get;set;}
    	public String clined_id{get;set;}
    	public String client_secret{get;set;}
    	public String user_id{get;set;}
    	public String password{get;set;}
    	// 2017/02/03 SF既存のお客様とマッピングルール  collaborationId zyz BEGIN
    	public list<string> jsonKeyLst{get;set;}
    	public list<string> sfKeyLst{get;set;}
    	public String whereLogicDef{get;set;}
    	// 2017/02/03 SF既存のお客様とマッピングルール  collaborationId zyz END
    }
    /*
    * リフレッシュトークン
    *//*
    private void refreshToken(){
    	Map<String,String> paramap = new Map<String,String>{'refresh_token' => '1','grant_type' => 'refresh_token'};
    	HttpRequest req = new HttpRequest();
    	String postMessage = EncodingUtil.base64Encode(Blob.valueof('1111:333333'));
		req.setHeader('Authorization', postMessage);
		HTTPResponse rep = sendRequest(req,tokenUrl, paraMap) ;
		String strXmlBody = rep.getBody();
system.debug(logginglevel.info,'rep:::' +rep);
system.debug(logginglevel.info,'strXmlBody:::' +strXmlBody);
    }
    */
    /*
    * 提携サービス属性取得
    */
    //static String collaborationId = 'QdD67zPLyTDc6Vo1';
    // 2017/02/03 SF既存のお客様とマッピングルール  collaborationId zyz
    private static Map<String,Object> getMemberGet(XmlDefInfo authInfo, String token, String collaborationId){
try {
    	HttpRequest req = new HttpRequest();
    	String postMessage = 'Bearer ' + token;
		req.setHeader('Authorization', postMessage);
		req.setHeader('Content-Type', 'application/json');
		
		req.setMethod('GET');
		tokenUrl = authInfo.domainUrl + '/collaboration-service/attributes/' + collaborationId;
		//response
		HTTPResponse rep = sendRequest(req,tokenUrl, new Map<String,String>()) ;
		String strXmlBody = rep.getBody();
		if (!CommUtils.isBlank(strXmlBody)) {
			Map<String,Object> rsMap = (Map<String,Object>)JSON.deserializeUntyped(strXmlBody);
			if (rsMap != null) {
				Map<String,Object> dataMap = (Map<String,Object>)rsMap.get('data');
				if(dataMap != null) return dataMap;
			}
		}
} catch (CommException e) {
	throw new CommException('「提携サービス属性取得」エラーが発生しました(' + e.getMessage() + ')');
}
		return new Map<String,Object>();
		
    }
    private static HTTPResponse sendRequest(HttpRequest req,String urlStr, Map<String,String> paraMap) {
		// リクエストURLを設定する
		String endpoint = urlStr ;
		//client_id : client_secret
		if (!paraMap.isEmpty()) req.setBody(getJsonByMap(paraMap));
		req.setEndpoint(endpoint);
		req.setTimeout(COMMON_TA_CALL_TIME_OUT_VALUE);
system.debug(logginglevel.info, 'endpoint='+endpoint);
system.debug(logginglevel.info, 'paraMap='+paraMap);
		Http http = new Http();
		HTTPResponse res = http.send(req);
system.debug(logginglevel.info, 'HTTPResponse='+res);
		// エラーチェック
		if (res.getStatusCode() != 200) {
			throw new CommException(res.getStatusCode() + '=' + res.getStatus());
		}
system.debug(logginglevel.info, 'body='+res.getBody());
		return res;
	}
	private static String getJsonByMap(Map<String,String> paramMap){
		String result = '';
		for (String key : paramMap.keySet()){
			result += key + '=' + paramMap.get(key) + '&';
		}
		result = result.removeEnd('&');
		return result;
	}
	private static String convertSexDiv(String sex) {
		sex = CommUtils.nullToBlank(sex);
		if (sex == '1') return '男性';
		else if (sex == '2') return '女性';
		else if (sex == '9') return '適用不能';
		else return '不明';
	}
	/**
	* おもてなしお客様情報を更新、関連のお客様に参照IDを設定する
	**/
	// 2017/02/03 SF既存のお客様とマッピングルール  collaborationId zyz
 	private static void syncContact(Map<String,Object> jsonMap, String collaborationId, XmlDefInfo authInfo){
 		// 国籍
 		Object nationObj = (Object)jsonMap.get('nationalities');
 		String curNations = '';
 		if (nationObj != null) {
 			List<Object> nations = (List<Object>)nationObj;
	 		for (Object nation : nations) {
	 			String strNation = CommUtils.nullToBlank(nation);
	 			if (!CommUtils.isBlank(strNation)) curNations += strNation + ',';
	 		}
	 		curNations.removeEnd(',');
 		}
 		// メールアドレス
 		String mailAddress = (String)jsonMap.get('mailAddress');
 		// 2017/02/03 SF既存のお客様とマッピングルール  collaborationId zyz BEGIN
 		/*
 		if (CommUtils.isBlank(mailAddress)) {
 			throw new CommException('メールアドレス情報を見つかりませんため、情報更新失敗になる');
 		}*/
 		// 2017/02/03 SF既存のお客様とマッピングルール  collaborationId zyz END
 		// 生年月日
 		Date birthDate = CommUtils.stringToDate((String)jsonMap.get('birthday')) ;
 		// 氏名情報
 		String lastName = CommUtils.nullToBlank(jsonMap.get('lastName'));
 		String middName = CommUtils.nullToBlank(jsonMap.get('middleName'));
 		String firstName = CommUtils.nullToBlank(jsonMap.get('firstName'));
 		// お客様名
 		String contactName = CommUtils.nullToBlank(lastName + ' ' + (CommUtils.isBlank(middName) ? '' : (middName + ' ')) + firstName);
 		Savepoint sp = Database.setSavepoint();
 		try {
	 		// 更新情報を設定する
	 		SyncContactInfo__c syncInfo = new SyncContactInfo__c(
	 			Name = contactName,
	 			Address__c = CommUtils.nullToBlank(jsonMap.get('address')),
	 			Birthday__c = birthDate,
	 			LastName__c = lastName,
	 			MiddleName__c = middName,
	 			FirstName__c = firstName,
	 			Gender__c = convertSexDiv(CommUtils.nullToBlank(jsonMap.get('gender'))),
	 			MailAddress__c = mailAddress,
	 			Nationalities__c = curNations,
				// 2017/02/03 SF既存のお客様とマッピングルール zyz BEGIN
	 			SyncKey__c = collaborationId
				// 2017/02/03 SF既存のお客様とマッピングルール zyz END
	 		);
	 		// 既存情報を更新を行う
	 		// 2017/02/03 SF既存のお客様とマッピングルール zyz BEGIN
	 		DataBase.upsert(syncInfo,SyncContactInfo__c.SyncKey__c);
	 		// mailAddress
	 		String queryStr = 'select JTbSyncInfoRef__c from Contact Where ';
	 		// Where条件を作成
	 		List<String> whereStrLst = new list<string>();
	 		//for (map<string,string> keyMap : authInfo.whereDefLst) {
	 		for(integer i = 0 ; i < authInfo.jsonKeyLst.size(); i++){
	 			String sfKey = authInfo.sfKeyLst[i];
	 			String jsonKey = authInfo.jsonKeyLst[i];
	 			String jsonKeyVal = CommUtils.nullToBlank(jsonMap.get(jsonKey));
	 			if (CommUtils.isBlank(jsonKeyVal)) {
	 				//throw new CommException(jsonKey + ' 情報を見つかりませんため、情報更新失敗になる.');
	 				continue;
	 			}
	 			//String subWhere = sfKey = '\'' + CommUtils.escStr(jsonKeyVal) + '\'';
				String subWhere = sfKey +'='+'\'' + CommUtils.escStr(jsonKeyVal) + '\'';
	 			whereStrLst.add(subWhere);
	 		}
	 		if (whereStrLst.isEmpty()) {
	 			System.debug(loggingLevel.warn, '指定のキーの設定値は全部空白するため、SF側のお客様へリンク処理ができませんでした。');
	 			return;
	 		} 
			//String sqlWhere = authInfo.whereLogicDef;
			String sqlWhere = '(';
			String joinKey = ' OR ';
			for(integer i = 0 ; i < whereStrLst.size(); i++){
				//System.debug(loggingLevel.INFO, 'sqlWhere1:::' + sqlWhere);
				//sqlWhere = sqlWhere.replace('{' + i + '}',whereStrLst[i]); 
				//System.debug(loggingLevel.INFO, 'sqlWhere2:::' + sqlWhere);
				sqlWhere += whereStrLst[i] + joinKey;
			}
			sqlWhere = sqlWhere.removeEndIgnoreCase(joinKey);
			sqlWhere += ')';
			queryStr += sqlWhere + ' order by LastModifiedDate desc limit 1 ';
System.debug(loggingLevel.info, 'SQL='+queryStr);
	    	//List<Contact> contactLsts = [Select JTbSyncInfoRef__c From Contact Where Email =:mailAddress];
	    	List<Contact> contactLst = DataBase.query(queryStr);
			// 2017/02/03 SF既存のお客様とマッピングルール zyz END
	    	List<Contact> updContactLst = new list<Contact>();
			for (Contact c : contactLst){
				if (c.JTbSyncInfoRef__c == null || c.JTbSyncInfoRef__c != syncInfo.Id) {
					c.JTbSyncInfoRef__c = syncInfo.Id;
					updContactLst.add(c);
				}
	    	}
	    	if (!updContactLst.isEmpty()) update updContactLst;
 		} catch (Exception e) {
 			DataBase.rollBack(sp);
			throw e; 			
 		}
    }
}