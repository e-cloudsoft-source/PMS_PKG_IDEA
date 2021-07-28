/*
 * @Date: July 15, 2013
 * @Description: webservice called from javascript 
        to invoke japan address search REST api to get zipcodes
 */
global class ZipcodeSearchService {
    
    //~Usage: webservice function to get list of zipcodes. 
    webservice static String searchZIPCode(String zipcode){
    	// 2018/03/06 zip.cgis.biz利用不可で再対応する WGCH BEGIN
    	/*
    	Http http = new Http();
        Httprequest searchRequest = new Httprequest();
        //searchRequest.setEndpoint('http://geoapi.heartrails.com/api/json?method=searchByPostal&postal=' + zipcode);
        zipcode = CommStringUtils.zenkakuEisujiToHankakuEisuji(zipcode);
        string wkZipCode = zipcode.replaceAll('[^0-9]+', '');
        searchRequest.setEndpoint('http://zip.cgis.biz/xml/zip.php?zn=' + wkZipCode);
        searchRequest.setMethod('GET');
        searchRequest.setTimeout(60000);
        try{
            Httpresponse searchResponse = http.send(searchRequest);
            String unescapedStr = searchResponse.getBody().unescapeUnicode();
            
			Dom.Document doc = new Dom.Document();
			doc.load(unescapedStr);
			Dom.XmlNode root = doc.getRootElement();
			map<string, string> infoMap = new map<String, String>();
			list<XmlAddressInfo> addressLst = new list<XmlAddressInfo>();
			for (Dom.XmlNode child : root.getChildElements()) {
				//system.debug(loggingLevel.info, child);
				String nodeName = child.getName();
				//system.debug(loggingLevel.info, nodeName);
				if (nodeName == 'result') {
					String result_code = child.getAttribute('result_code',null);
					String error_code = child.getAttribute('error_code',null);
					String error_note = child.getAttribute('error_note',null);
					if (!CommUtils.isBlank(result_code)) infoMap.put('result_code', result_code);
					if (!CommUtils.isBlank(error_code)) infoMap.put('error_code', error_code);
					if (!CommUtils.isBlank(error_note)) infoMap.put('error_note', error_note);
				} else if (nodeName == 'ADDRESS_value') {
					addressLst.add(new XmlAddressInfo(child, wkZipCode));
				}
			}
			if (infoMap.get('result_code') == '0' && (infoMap.get('error_code') == '4' || infoMap.get('error_code') == '5')) {
				throw new CommException(infoMap.get('error_note'));
			}
     		JSONGenerator gen = JSON.createGenerator(true);
    		gen.writeStartObject();
    		gen.writeFieldName('response');
    		gen.writeStartObject();
    		gen.writeObjectField('location', addressLst);
    		gen.writeEndObject();
			return gen.getAsString();
			// 情報が存在する場合、JSONリストは画面に表示する
        }catch(Exception ex){
        	system.debug('--Exception:::' + ex.getMessage());
            searchRequest.setEndpoint('http://geoapi.heartrails.com/api/json?method=searchByPostal&postal=' + zipcode);
			try{
	            Httpresponse searchResponse = http.send(searchRequest);
	            String unescapedStr = searchResponse.getBody().unescapeUnicode();
	            //system.debug('--response: ' + searchResponse.getBody());
	            return unescapedStr;
			} catch (Exception dupEx) {
				system.debug('--dupEx Exception:::' + dupEx.getMessage());
			}
        }
        */
    	/* Sql 取到开始的Mode */
        zipcode = CommStringUtils.zenkakuEisujiToHankakuEisuji(zipcode);
        zipcode = zipcode.replaceAll('[^0-9]+', '');   
    	//startMode = '';
    	Integer intSiteNo = 1;
    	ZipSearchInfo__c zipconfig = ZipSearchInfo__c.getOrgDefaults();
    	String mode = CommUtils.isBlank(zipconfig.EndPointType__c) ? CONST_MODE_1 : CommUtils.nullToBlank(zipconfig.EndPointType__c);
System.debug(loggingLevel.info, 'mode='+mode);
    	if(mode == CONST_MODE_1) return searchZIPCodeOne(zipcode, intSiteNo);
    	else if(mode == CONST_MODE_2) return searchZIPCodeTwo(zipcode, intSiteNo);
    	else return searchZIPCodeThree(zipcode, intSiteNo);
    	// 2018/03/06 zip.cgis.biz利用不可で再対応する WGCH END
    }
    private class XmlAddressInfo {
    	// 2018/03/06 zip.cgis.biz利用不可で再対応する WGCH BEGIN
    	public XmlAddressInfo(){}
    	// 2018/03/06 zip.cgis.biz利用不可で再対応する WGCH END
    	public XmlAddressInfo(Dom.XmlNode addressRoot, String wkZipCode) {
    		for (Dom.XmlNode child : addressRoot.getChildElements()) {
    			String locState = child.getAttribute('state',null);
    			String locCity = child.getAttribute('city',null);
    			String locAddress = child.getAttribute('address',null);
    			if (!CommUtils.isBlank(locState)) this.prefecture = locState;
    			if (!CommUtils.isBlank(locCity)) this.city = locCity;
    			if (!CommUtils.isBlank(locAddress)) this.town = locAddress;
    			postal = wkZipCode;
    		}
    	}
    	public string prefecture{get;private set;}
    	public string city{get;private set;}
    	public string town{get;private set;}
    	public string postal{get;private set;}
    }
    
    //~Usage: webservice function to get list of zipcodes. 
    webservice static String searchAddress(String zipcode){
        Http http = new Http();
        Httprequest searchRequest = new Httprequest();
        searchRequest.setEndpoint('http://geoapi.heartrails.com/api/json?method=suggest&matching=like&keyword=' + Encodingutil.urlEncode(zipcode, 'UTF-8'));
        searchRequest.setMethod('GET');
        searchRequest.setTimeout(60000);
        try{
            Httpresponse searchResponse = http.send(searchRequest);
            String unescapedStr = searchResponse.getBody().unescapeUnicode();
            system.debug('--response: ' + searchResponse.getBody());
            return unescapedStr;
        }catch(Exception ex){
            system.debug('--Exception: ' + ex.getMessage());
        }
        return null;
    }
    
    /*
     * @Description global class to implement http mock callout
     */
    global class HttpCalloutMockImpl implements HttpCalloutMock{
         
         //~Usage: function to implement http response
         global HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            String endPointUrl = req.getEndpoint();
System.debug(loggingLevel.info, 'URL='+endPointUrl);
            String str = '';
            if (endPointUrl.contains('zip.cgis.biz')) {
                str = '<ZIP_result><result name="ZipSearchXML"/><result version="1.01"/><result request_zip_num="1000001"/><result request_zip_version="none"/><result result_code="1"/><result result_zip_num="1000001"/><result result_zip_version="0"/><result result_values_count="1"/>' + 
                '<ADDRESS_value><value state="東京都"/><value city="千代田区"/><value address="千代田"/></ADDRESS_value></ZIP_result>';
            } else if (endPointUrl.contains('postcode.teraren.com')) {
                str = '[{"jis":"11223","old":"335  ","new":"3350001","prefecture_kana":"サイタマケン","city_kana":"ワラビシ","suburb_kana":"キタマチ","prefecture":"埼玉県","city":"蕨市","suburb":"北町","is_separated_suburb":0,"is_koaza":0,"is_chome":1,"is_include_area":0,"status":0,"reason":0,"url":"https://postcode.teraren.com/postcodes/3350001.json"}]';
            } else if (endPointUrl.contains('www.post.japanpost.jp')) {
                str = '<table class="sp-b10"><tbody><tr></tr><tr><td class="data"><small>335-0002</small></td><td class="data"><small>埼玉県</small></td><td class="data"><small>蕨市</small></td><td><div class="data"><p><small><a href="zipcode.php?pref=11&city=1112230&id=40695&merge=">塚越</a></small></p><p class="comment"><small>ツカゴシ</small></p></div></td></tr></tbody></table>';
            } else if (endPointUrl.contains('geoapi.heartrails.com')) {
                str = '[{"city":"石狩郡当別町",,"town":"ビトエ（中島）","prefecture":"北海道","postal":"0613772"}]';
            }
            res.setBody(str);
            res.setStatusCode(200);
            return res;
        }
    }
    // 2018/03/06 zip.cgis.biz利用不可で再対応する WGCH BEGIN
    private static final String CONST_MODE_1 = '1';
    private static final String CONST_MODE_2 = '2';
    private static final String CONST_MODE_3 = '3';
    //private static String startMode;
    private static final Integer CONST_MAXSITE = 3;
    // 1.http://zip.cgis.biz/xml/zip.php
    private static String searchZIPCodeOne(String zipcode, Integer runNo){
    	Http http = new Http();
        Httprequest searchRequest = new Httprequest();
        searchRequest.setEndpoint('http://zip.cgis.biz/xml/zip.php?zn=' + zipcode);
        searchRequest.setMethod('GET');
        searchRequest.setTimeout(60000);
        try{
            Httpresponse searchResponse = http.send(searchRequest);
            if(searchResponse.getStatusCode() != 200 && runNo < CONST_MAXSITE){
            	// ３サイトは全部
				runNo++;
				return searchZIPCodeTwo(zipcode, runNo);
            }
            String unescapedStr = searchResponse.getBody().unescapeUnicode();
			Dom.Document doc = new Dom.Document();
			doc.load(unescapedStr);
			Dom.XmlNode root = doc.getRootElement();
			map<string, string> infoMap = new map<String, String>();
			list<XmlAddressInfo> addressLst = new list<XmlAddressInfo>();
			for (Dom.XmlNode child : root.getChildElements()) {
				String nodeName = child.getName();
				if (nodeName == 'result') {
					String result_code = child.getAttribute('result_code',null);
					String error_code = child.getAttribute('error_code',null);
					String error_note = child.getAttribute('error_note',null);
					if (!CommUtils.isBlank(result_code)) infoMap.put('result_code', result_code);
					if (!CommUtils.isBlank(error_code)) infoMap.put('error_code', error_code);
					if (!CommUtils.isBlank(error_note)) infoMap.put('error_note', error_note);
				} else if (nodeName == 'ADDRESS_value') {
					addressLst.add(new XmlAddressInfo(child, zipcode));
				}
			}
			/*
			1 郵便番号パラメータ(zn)未設定
			2 郵便番号形式指定パラメータ(ver)の形式誤り
			3 郵便番号パラメータ(zn)形式誤り
			4 システムメンテナンス中
			5 システム側エラー
			*/
			if (infoMap.get('result_code') == '0' && (infoMap.get('error_code') == '4' || infoMap.get('error_code') == '5')) {
			    // ３サイトは全部
				if(runNo < CONST_MAXSITE){
					runNo++;
					//startMode = CONST_MODE_2;
					return searchZIPCodeTwo(zipcode, runNo);
				}
			}
			return getJsonInfo(new Map<String,List<XmlAddressInfo>>(), addressLst, CONST_MODE_1);
			// 情報が存在する場合、JSONリストは画面に表示する
        }catch(Exception ex){
            if(runNo < CONST_MAXSITE){
                runNo++;
                return searchZIPCodeTwo(zipcode, runNo);
            }
        }
        return null;
    }
    // 2.https://postcode.teraren.com/postcodes.json?s=
    private static String searchZIPCodeTwo(String zipcode, Integer runNo){
    	Http http = new Http();
        Httprequest searchRequest = new Httprequest();
        string queryCode = zipcode;
        if (queryCode.length() < 7) queryCode += '*';
        searchRequest.setEndpoint('https://postcode.teraren.com/postcodes.json?s='+queryCode);
        searchRequest.setMethod('GET');
        searchRequest.setTimeout(60000);
        try{
            Httpresponse searchResponse = http.send(searchRequest);
            if(searchResponse.getStatusCode() != 200 && runNo < CONST_MAXSITE){
            	// ３サイトは全部
				runNo++;
				return searchZIPCodeThree(zipcode, runNo);
            }
            String unescapedStr = searchResponse.getBody().unescapeUnicode();
            List<Object> jsonlst = (List<Object>)Json.deserializeUntyped(unescapedStr);
            map<String,List<XmlAddressInfo>> sortMap = new map<String, List<XmlAddressInfo>>();
            for (Object item : jsonlst) {
                Map<String,Object> mp = (Map<string,Object>)item;
                String postno = CommUtils.nullToBlank(mp.get('new'));
                if (CommUtils.isBlank(postno) || !postno.startsWith(zipcode)) continue;
                XmlAddressInfo inf = new XmlAddressInfo(); 
                inf.postal = postno;
                inf.prefecture = CommUtils.nullToBlank(mp.get('prefecture'));
                inf.city = CommUtils.nullToBlank(mp.get('city'));
                inf.town = CommUtils.nullToBlank(mp.get('suburb'));
                if (!sortMap.containsKey(postno)) sortMap.put(postno, new List<XmlAddressInfo>());
                sortMap.get(postno).add(inf);
            }
            // 情報が存在する場合、JSONリストは画面に表示する
            return getJsonInfo(sortMap, new list<XmlAddressInfo>(), CONST_MODE_2);
        }catch(Exception ex){
        	/* Sql insert String Start = '3' */
        	if(runNo < CONST_MAXSITE){
        		runNo++;
        		return searchZIPCodeThree(zipcode, runNo);
        	}
        	system.debug('--Exception:::' + ex.getMessage());
        }
        return null;
    }
    /*2019/10/25 下記機能利用不可になるため、関連処理外す 
    // 3.http://www.post.japanpost.jp/cgi-zip/zipcode.php
    private static String searchZIPCodeThree(String zipcode, Integer runNo){
        try{
            list<XmlAddressInfo> addressLst = new list<XmlAddressInfo>();
            String htmlBodyStr = getHtmlBody('zip=' + zipcode, zipcode, runNo);
            List<String> partLst = htmlBodyStr.split('<divclass="part">');
            if(partLst.size() == 1) getHtmlBodyInfo(htmlBodyStr, addressLst);
            else{
            	for(String part : partLst){
	            	String urlWhere =  part.substringBetween('<ahref="zipcode.php?','">'); // 获取Url条件
	            	if(urlWhere == null) continue;
	            	if(addressLst.Size() < 100) getHtmlBodyInfo(getHtmlBody(urlWhere, zipcode, runNo), addressLst); // 小于100条数据的情况下，继续调用下一个Link
            	}
            }
            map<String,List<XmlAddressInfo>> sortMap = new map<String, List<XmlAddressInfo>>();
            for (XmlAddressInfo item : addressLst) {
                if (!sortMap.containsKey(item.postal)) sortMap.put(item.postal, new List<XmlAddressInfo>());
                sortMap.get(item.postal).add(item); 
            }
            // 情報が存在する場合、JSONリストは画面に表示する
			return getJsonInfo(sortMap, new List<XmlAddressInfo>(), CONST_MODE_3);
        }catch(Exception ex){

        	if(runNo < CONST_MAXSITE){
        		runNo++;
        		return searchZIPCodeOne(zipcode, runNo);
        	}
        }
        return null;
    }*/
    public static String searchZIPCodeThree(String zipcode, Integer runNo){
   		Http http = new Http();
        Httprequest searchRequest = new Httprequest();
        searchRequest.setEndpoint('http://zipcloud.ibsnet.co.jp/api/search?zipcode=' + zipcode);
        //searchRequest.setEndpoint('https://api.zipaddress.net/?zipcode=' + zipcode);
        searchRequest.setMethod('GET');
        searchRequest.setTimeout(60000);
        try{
            Httpresponse searchResponse = http.send(searchRequest);
            if(searchResponse.getStatusCode() != 200 && runNo < CONST_MAXSITE){
            	// 1番目サイトを呼び出し
				runNo++;
				return searchZIPCodeOne(zipcode, runNo);
            }
            String unescapedStr = searchResponse.getBody().unescapeUnicode();
            map<String,Object> jsonMap = (map<String,Object>)Json.deserializeUntyped(unescapedStr);
			map<String,List<XmlAddressInfo>> sortMap = new map<String, List<XmlAddressInfo>>();
            for (String key : jsonMap.keyset()) {
				// 検査結果を確認する
                if (key == 'results') {
                	List<Object> addresslst = (List<Object>)jsonMap.get(key);
                	for (Object item : addresslst) {
                		Map<String, Object> mp = (Map<String, Object>)item;
		                String postno = CommUtils.nullToBlank(mp.get('zipcode'));
		                if (CommUtils.isBlank(postno) || !postno.startsWith(zipcode)) continue;
		                XmlAddressInfo inf = new XmlAddressInfo(); 
		                inf.postal = postno;
		                inf.prefecture = CommUtils.nullToBlank(mp.get('address1'));
		                inf.city = CommUtils.nullToBlank(mp.get('address2'));
		                inf.town = CommUtils.nullToBlank(mp.get('address3'));
		                if (!sortMap.containsKey(postno)) sortMap.put(postno, new List<XmlAddressInfo>());
		                sortMap.get(postno).add(inf);
                	}
                }
            }
			return getJsonInfo(sortMap, new list<XmlAddressInfo>(), CONST_MODE_3);
			// 情報が存在する場合、JSONリストは画面に表示する
        }catch(Exception ex){
        	// 1番目サイトを呼び出し
            if(runNo < CONST_MAXSITE){
                runNo++;
                return searchZIPCodeOne(zipcode, runNo);
            }
        }
        return null;
    }
    // 转换Json
    private static String getJsonInfo(Map<String,List<XmlAddressInfo>> sortMap, List<XmlAddressInfo> addressLst, String modeType){
        // 2018/03/07 Security Check BEGIN
        List<String> chkFieldsLst = new List<String>{'resetdate__c','endpointtype__c'};
        Map<String,Schema.SObjectField> mm = Schema.SObjectType.ZipSearchInfo__c.fields.getMap();
        if (!CommSecurityUtils.isCanCreateable(chkFieldsLst, mm)) {
        	return null;
        }
        // 2018/03/07 Security Check END
        // 2018/03/07 Security Check BEGIN
        List<String> chkFieldLst = new List<String>{'resetdate__c','endpointtype__c'};
        Map<String,Schema.SObjectField> m = Schema.SObjectType.ZipSearchInfo__c.fields.getMap();
        if (!CommSecurityUtils.isCanUpdateable(chkFieldLst, m)) {
        	return null;
        }
        // 2018/03/07 Security Check END
        // 共通定義なし && モードが１の場合
        // 共通定義あり && 引き渡すモードと共通定義が一致する場合
        ZipSearchInfo__c zipconfig = ZipSearchInfo__c.getOrgDefaults();
        // 未定義の場合
        if (CommUtils.isBlank(zipconfig.Id)) {
            // 個別処理不要
            if ( modeType != CONST_MODE_1) {
                // モード１エラー発生する場合、情報記録する
                zipconfig.EndPointType__c = modeType;
                zipconfig.ResetDate__c = Date.today().addDays(3);
                insert zipconfig;
            }
        } 
        // 既に定義する場合、
        else {
             // 自動復旧処理を行う・しない判断
             // モード１に戻る処理
             if (!zipconfig.NoAutoResetFlg__c && zipconfig.ResetDate__c <= Date.today()) {
                 zipconfig.EndPointType__c = CONST_MODE_1;
                 zipconfig.ResetDate__c = null;
                 update zipconfig;
             }
             // 現在の日付により、復旧処理を行うがどうか
             else {
             	// モード変更あり場合
             	if(modeType != zipconfig.EndPointType__c)  {
             		// 新モードがモード１以外の場合、かつ　復旧日付を未設定　または　復旧日付は今日以前の場合　復旧日付を再度設定する
             		if (modeType != CONST_MODE_1 && 
             			(zipconfig.ResetDate__c == null || zipconfig.ResetDate__c <= Date.today()) ) zipconfig.ResetDate__c = Date.today().addDays(3);
             		zipconfig.EndPointType__c = modeType;
             		update zipconfig;
             	}
             }
        }
        // 
    	if (!sortMap.isEmpty()) {
	    	List<String> sortList = new List<String>(sortMap.keyset());
	        sortList.sort();
	        for (String key : sortList) {
	            addressLst.addAll(sortMap.get(key));
	        }
    	}
    	JSONGenerator gen = JSON.createGenerator(true);
		gen.writeStartObject();
		gen.writeFieldName('response');
		gen.writeStartObject();
		gen.writeObjectField('location', addressLst);
		gen.writeEndObject();
		return gen.getAsString();
    }
    /*2019/10/25 下記機能利用不可になるため、関連処理外す 
    // 调用Url
    private static String getHtmlBody(String urlWhere, String zipcode, Integer runNo){
    	Http http = new Http();
    	HttpRequest reqs = new HttpRequest();   
    	reqs.setEndpoint('http://www.post.japanpost.jp/cgi-zip/zipcode.php?' + urlWhere);
    	reqs.setMethod('GET');
    	reqs.setTimeout(60000);
    	//reqs.setCompressed(true);
    	HttpResponse res = http.send(reqs);
    	if(res.getStatusCode() != 200 && runNo < CONST_MAXSITE){
        	// ３サイトは全部
			//runNo++;
			// 2019/10/25 郵便検索機能無効の場合、次の検索機能を利用する
			throw new CommException('www.post.japanpost.jp/cgi-zip/zipcode.php error['+res.getStatusCode()+']');
			//return searchZIPCodeOne(zipcode, runNo);
        }
    	return CommUtils.nullToBlank(res.getBody()).deleteWhitespace();
    }
    // 获取信息
    private static void getHtmlBodyInfo(String htmlBodyStr, list<XmlAddressInfo> wkInfoLst){
    	List<String> tbodyLst = htmlBodyStr.split('<tbody>'); 
    	if(tbodyLst.Size() <= 1) return;
    	for(Integer m = 1 ; m < tbodyLst.Size() ; m++){ // 第0位无用的信息
    		List<String> trLst = tbodyLst[m].split('</tr><tr><tdclass="data">');
			if(trLst.Size() <= 1) continue;
    		for(Integer n = 1 ; n < trLst.Size() ; n++){ // 第0位无用的信息
    			if(wkInfoLst.Size() == 100) return;
    			List<String> smallLst = trLst[n].split('</small>');
    			if(smallLst.size() < 4 ) continue;
    			XmlAddressInfo item = new XmlAddressInfo();
    			item.postal = CommUtils.nullToBlank(smallLst[0].stripHtmlTags().replaceAll('-','')); // 郵便番号
    			item.prefecture = CommUtils.nullToBlank(smallLst[1].stripHtmlTags()); // 都道府県
    			item.city = CommUtils.nullToBlank(smallLst[2].stripHtmlTags()); // 市区町村
    			item.town = CommUtils.nullToBlank(smallLst[3].stripHtmlTags().replaceAll('以下に掲載がない場合','')); // 町域
    			wkInfoLst.add(item);
    		}
    	}
    }
    // 2018/03/06 zip.cgis.biz利用不可で再対応する WGCH END
    */
    // 2021/03/31 予約ポップやルームインジケータから予約作成する際に郵便番号検索が使えるようにして欲しい by zy BEGIN
    @remoteaction
    global static object requestCenter(String dataType,String request){
        if (dataType == 'searchZIPCode') {
            return searchZIPCode(request);
        } else if (dataType == 'searchAddress') {
            return searchAddress(request);
        }
        return null;
    }
    // 2021/03/31 予約ポップやルームインジケータから予約作成する際に郵便番号検索が使えるようにして欲しい by zy END
}