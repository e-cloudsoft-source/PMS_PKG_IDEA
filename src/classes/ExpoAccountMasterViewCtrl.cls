public with sharing class ExpoAccountMasterViewCtrl extends ExpoCommBaseCtrl{
	private static final String RELATION_KEY = '__r.';
	private static map<String, String> customLabelMap = new map<String, String>{'paytype__c'=>'決済方法', 'displaydate__c'=>'販売開始日', 'category__c'=>'ｶﾃｺﾞﾘ', 'categorysub__c'=>'ｶﾃｺﾞﾘｻﾌﾞ', 'servicerate__c'=>'ｻﾋﾞｰｽ料'}; // カスタム表示する項目のラベル名を定義する<JSONKEY, LABEL>
	// 画面に表示項目のAPIを定義する、!!!必ず小文字に設定する!!!
	private static Set<String> defAccMasterApiSet = new Set<String>{'id','name','displaydate__c','category__c','categorysub__c','field5__c','taxratecal__c', 'field7__c', 'servicerate__c', 'paytype__c', 'deliverytype__c' , 'shopinforef__c'};
	private static Map<String,String> defApiMap = new Map<String,String>{'field3__c' => '130px','field5__c' => '80px;','field7__c' => '80px;','field4__c' => '150px;','gpchange__c' => '150px;','taxratecal__c' => '100px;', 'servicerate__c'=>'110px;'};
	private static Map<String, Schema.DescribeFieldResult> getAllFieldLst{get{ return CommSqlUtils.getAllFieldLst(AccountMaster__c.sObjectType,false,true);}} // 获取AccountMaster__c所有字段信息
	public static String colnumJson{get; private set;} // 列
	// 初始化页面读取
	public PageReference initAct(){
		// *****************************
		// 共通処理呼び出す
		// *****************************
		PageReference pg = checkLogin();
		if (pg != null) return pg;
		// *****************************
		// 実際の業務ロジック処理展開
		// *****************************
		parseFieldsXml(CommUtils.nullToBlank(currentUser.ShopCode__c));
		getColnumJson(); // 获取colnumjson
		return null;
	}
	@remoteAction
	public static List<Map<String,Object>> getModel(String shopCode, String expoOrgInfoRef) {
		Map<String, Schema.DescribeFieldResult> modelDeafaultValuesMaps = getAllFieldLst;
		parseFieldsXml(CommUtils.nullToBlank(shopCode));
		List<String> notInActLst = new List<String>{CommConst.PROD_ACTION_TYPE_NO,CommConst.PROD_ACTION_TYPE_AR,CommConst.PROD_ACTION_TYPE_PY};
		String queryStr = getSql();
		queryStr += ' From AccountMaster__c Where ActionType__c != :notInActLst And IsClosed__c = false And ExpoOrgInfoRef__c =: expoOrgInfoRef ' ;
		queryStr += ' order by ' + CommConst.PROD_SORT_KEY;
		List<Map<String,Object>> resultLst = new List<Map<String,Object>>();
		List<AccountMaster__c> accs = DataBase.query(queryStr );
		for (AccountMaster__c acc : accs){
			Map<String,Object> objMap = new Map<String,Object>();
			for(String api : defAccMasterApiSet){
				String val = CommUtils.nullToBlank(getValueByApi(acc, api));
				if(!CommUtils.isBlank(val) && modelDeafaultValuesMaps.containsKey(api) && modelDeafaultValuesMaps.get(api).getType() == Schema.DisplayType.Date){
					Date dt = CommUtils.objectToDate((Object)val);
					val = (DateTime.newInstance(dt.year(),dt.month(),dt.day())).format(ExpoHelperUtil.DATE_FORMAT);
				}
				//if(api == 'taxratecal__c') val = val; //+ '%';
				objMap.put(getObjApiKey(api, false), val);
			}
			resultLst.add(objMap);
		}
		return resultLst;
		
	}
	private static String getSql(){
		Map<String, Schema.DescribeFieldResult> modelDeafaultValuesMaps = getAllFieldLst;// 获取AccountMaster__c所有字段信息
		String queryStr = ' Select '; // queryStr
		for(String api : defAccMasterApiSet.clone()){ // 防止地址共存
			if(!modelDeafaultValuesMaps.containsKey(api)) continue; // 去掉无效字段
			Schema.DescribeFieldResult dr = modelDeafaultValuesMaps.get(api); // 获取当前字段所以信息
			if(dr.getType() == Schema.DisplayType.REFERENCE){
				defAccMasterApiSet.remove(api); // 去掉参照字段
				api = getObjApiKey(api, true);
				defAccMasterApiSet.add(api); // 追加参照字段的Nmae
			}
			queryStr += api + ',';
		}
		queryStr = queryStr.removeEnd(',');
		return queryStr;
	}
	// 参照字段API转换
	private static String getObjApiKey(String api,Boolean isCtoRFlg){
		String c = '__c';
		String r = '__r.name';
		return isCtoRFlg ? api.replaceAll(c, r) : api.replaceAll(r, c);
	}
	// 获取所有列Info
	private void getColnumJson(){
		Map<String, Schema.DescribeFieldResult> modelDeafaultValuesMaps = getAllFieldLst; // 获取AccountMaster__c所有字段信息
		
		JSONGenerator gen = JSON.createGenerator(false);
		gen.writeStartArray();
		Boolean oneFlg = true;
		// 2019/08/15 商品の詳細情報を削除、削除した商品復元 BY zyz BEGIN
		gen.writeStartObject();
		gen.writeStringField('template', '<input type="checkbox" class="clearCheck" accDefId="#= id#" onclick="clearCheckBoxFun(this)" id="clearId" Name="checkNm" />');
		gen.writeStringField('title', '削除');
		gen.writeStringField('width', '45px');
		gen.writeEndObject();
		// 2019/08/15 商品の詳細情報を削除、削除した商品復元 BY zyz END
		for(String api : defAccMasterApiSet){
			if(!modelDeafaultValuesMaps.containsKey(api) || api == 'id') continue; // 去掉无效字段
			Schema.DescribeFieldResult dr = modelDeafaultValuesMaps.get(api); // 获取当前字段所以信息
			String lab = dr.getLabel();
			if(customLabelMap.containsKey(api)) lab = customLabelMap.get(api);
			gen.writeStartObject();
			gen.writeStringField('field', api);
			gen.writeStringField('title', lab);
			if (defApiMap.containsKey(api)) gen.writeStringField('width', defApiMap.get(api));
			// 　
			if(oneFlg) gen.writeStringField('template', '<a style="display: inline-block; width: 100%; height: 100%;" href=\'/apex/'+CommConst.APPOTION_NAMESPACE+'ExpoAccountMasterEdit?Id=#= id#&sid='+sessionId+'\'>#= ' + api + '#　<a>');
			gen.writeStringField('typ', dr.getType().name());
			gen.writeEndObject();
			oneFlg = false;
		}
		gen.writeEndArray();
		colnumJson = gen.getAsString(); // 设置获取所有列Info
	}
	// 参照字段对应
	private static Object getValueByApi(Sobject s ,String field) {
		// 2017/09/18 カスタマイズ定義のLINKあり項目は自動リンクを付ける対応 WGCH BEGIN
		if (s == null) return '';
		// 2017/09/18 カスタマイズ定義のLINKあり項目は自動リンクを付ける対応 WGCH END
		String apiField = field.trim();
		// Jsonにアサインするキー: ssss__r.aaa__r.xxxx -> ssss__r_aaa__r_xxxx
		// 2017/06/06 XMLのAPI定義小文字、大文字区別されない対応 BEGIN
		if (apiField.containsIgnoreCase(RELATION_KEY)) {
			// aaa__r.xxxx
			Integer startPt = apiField.indexOfIgnoreCase(RELATION_KEY) + RELATION_KEY.length();
			String refFieldNm = apiField.substring(startPt);
			// 一階層のSOBJECT名
			// ssss__r
			String refSobjNm = apiField.substringBefore('.');
			// 二階層のSOBJECT[aaa__r.xxxx]
			if (refFieldNm.containsIgnoreCase(RELATION_KEY)) {
				// 一階層のSOBJECT取得する[ssss__r]
				Sobject refSobj = s.getSObject(refSobjNm);
				if (refSobj == null) {
					return null;
				}
				// 二階層の参照関係存在する場合、二階層以上は対応しません
				Integer twoStartPt = refFieldNm.indexOfIgnoreCase(RELATION_KEY) + RELATION_KEY.length();
				String twoRefFieldNm = refFieldNm.substring(twoStartPt);
				// Sobject Name [aaa__r]
				String twoRefSobjNm = refFieldNm.substringBefore('.');
				// Two Level Field
				Sobject twoRefSobj = refSobj.getSObject(twoRefSobjNm);
				// JSONに情報を書込する
				if (twoRefSobj == null) return null;
				else {
					Object val = twoRefSobj.get(twoRefFieldNm);
					return val;
				}
			} else {
				Sobject refSobj = s.getSObject(refSobjNm);
				if (refSobj == null) return null;
				else {
					Object val = refSobj.get(refFieldNm);
					return val;
				}
			}
		} else {
			Object val = s.get(apiField);
			return val;
		}
	}
	private static void parseFieldsXml(String pShopCode) {
		Dom.XMLNode targetNode = CommXmlUtils.parseXmlDoc('ExpoServiceConfig', pShopCode);
		if (targetNode == null) return;
		// 店舗情報はＸＭＬから取得する
		Dom.XmlNode shopFields = targetNode.getChildElement('ACCLISTFIRLDS', null);
		if(shopFields != null){
			// XMLに定義された表示項目リスト取得、処理を行う
			for (String item : CommUtils.nullToBlank(shopFields.getText()).deleteWhitespace().split(',')) {
				String[] keySplits = item.split(':');
				if (keySplits.size() != 2) {
					//表示項目書式の設定が不正です[API名:項目ラベル]
					Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_041_0031));
					break;
				}
				String key = keySplits[0].toLowerCase();
				String lab = keySplits[1];
				// API名を格納する
				defAccMasterApiSet.add(key);
				// 表示ラベルを定義する
				customLabelMap.put(key, lab);
			}
		}
	}
	// 2019/08/15 商品の詳細情報を削除、削除した商品復元 BY zyz BEGIN
	@remoteAction
	public static String clearAccData(list<String> idLst,String expoUserName) {
		return ExpoNoAuthHelp.clearMaster(idLst,expoUserName);
	}
	// 2019/08/15 商品の詳細情報を削除、削除した商品復元 BY zyz END
}