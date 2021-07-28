public with sharing class ExpoShopInfoViewCtrl extends ExpoCommBaseCtrl {
	private static final String FRONT = 'FRONT'; // 附加字段 最前面
	private static final String BEHIND = 'BEHIND'; // 附加字段 最后面
	private static final String ORGLISTFIELDS = 'ORGLISTFIELDS'; // xml 节点
	private String template = '<a href=\'/apex/'+ CommConst.APPOTION_NAMESPACE +'ExpoShopInfoEdit?Id=#= id#&sid=$sid$\'>#= $field$#　<a>';
	public String colnumJson{get; set;}
	// 字段显示顺序
	private static List<String> defShowOrderLst = new List<String>{'name', 'post__c', 'address__c', 'phone__c', 'fax__c', 'email__c', 'website__c', 'payeeacount__c', 'payee1__c', 'payee2__c', 'payee3__c'};
	// 显示名字
	private static Map<String, String> defNeedFieldNameMap = new Map<String, String>{'website__c'=>'ウェブサイト'}; // key - 定义需要显示的字段, value - 显示的title, 为null则是字段的名字
	// 宽度
	private static Map<String, String> defFieldNameWidthMap = new Map<String, String>{'name'=>'160px', 'Phone__c'=>'130px', 'Login'=>'100px'}; // key - 字段, value - 显示的宽度
	// 模板
	private static Map<String, String> defTemplateMap = new Map<String, String>{};
	// 附加的字段 eg: Login => FRONT key: 首字母大写,与字段区分; value: 附加字段的位置, 可填入字段的名字, 该附加字段为填入的字段的后面
	private static Map<String, String> defFieldsMap = new Map<String,String>{}; 
	private static Map<String, Schema.DescribeFieldResult> getAllFieldLst{get{ return CommSqlUtils.getAllFieldLst(ShopInformation__c.sObjectType,false,true);}}
	
	public PageReference initAct(){
		PageReference pg = checkLogin();
		if (pg != null) return pg;
		
		template = template.replace('$sid$',sessionId);
		
		parseFieldsXml(CommUtils.nullToBlank(currentUser.ShopCode__c));
		addAccessory();
		colnumJson = getColnumJson();
		return null;
	}
	
	@remoteAction 
	public static List<Object> getModel(String spcd, String expoOrgInfoRef){
		Map<String, Schema.DescribeFieldResult> modelDeafaultValuesMaps = getAllFieldLst;
		parseFieldsXml(CommUtils.nullToBlank(spcd));
		Set<String> needFields = new Set<String>();
		String sql = getSql(needFields) + ' FROM ShopInformation__c WHERE ExpoOrgInfoRef__c = :expoOrgInfoRef';
		List<Map<String, Object>> ret = new List<Map<String, Object>>();
		for(ShopInformation__c eu : Database.query(sql)){
			Map<String, Object> tmp = new Map<String, Object>();
			for(String api : needFields){
				api = api.toLowerCase();
				String val = CommUtils.nullToBlank(getValueByApi(eu, api));
				if(!CommUtils.isBlank(val) && modelDeafaultValuesMaps.containsKey(api) && modelDeafaultValuesMaps.get(api).getType() == Schema.DisplayType.Date){
					Date dt = CommUtils.objectToDate((Object)val);
					val = (DateTime.newInstance(dt.year(),dt.month(),dt.day())).format(ExpoHelperUtil.DATE_FORMAT);
				}
				tmp.put(getObjApiKey(api, false), val);
			}	
			ret.add(tmp);
		}
		return ret;
	}
	
	// 获取SQL
	private static String getSql(Set<String> needFields){
		Map<String, Schema.DescribeFieldResult> allFieldMap = getAllFieldLst;
		List<String> tmpShowOrderLst = defShowOrderLst.clone();
		for(String str : tmpShowOrderLst){
			if(!allFieldMap.containsKey(str)) continue;
			Schema.DescribeFieldResult dr = allFieldMap.get(str);
			if(dr.getType() == DisplayType.Reference) needFields.add(getObjApiKey(str, true));
			else needFields.add(str);
		}
		needFields.add('id');
		String sql = 'SELECT ';
		sql += String.join(new List<String>(needFields), ',');
		return sql;
	}
	
	// 参照字段API转换
	private static String getObjApiKey(String api,Boolean isCtoRFlg){
		String c = '__c';
		String r = '__r.name';
		return (isCtoRFlg ? api.replaceAll(c, r) : api.replaceAll(r, c)).toLowerCase();
	}
	
	// 参照字段对应
	private static final String RELATION_KEY = '__r.';
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
	
	private String getColnumJson(){
		Map<String, Schema.DescribeFieldResult> allFieldMap = getAllFieldLst;
		List<Map<String, String>> jsonLst = new List<Map<String, String>>();
		List<String> tmpShowOrderLst = defShowOrderLst.clone();
		String isOk;
		for(String str : tmpShowOrderLst){
			String lab;
			String name;
			Map<String, String> tmp = new Map<String, String>();
			if(!allFieldMap.containsKey(str) && !defFieldsMap.containsKey(str)){
				continue;
			}else if(!allFieldMap.containsKey(str) && defFieldsMap.containsKey(str)){
				lab = defNeedFieldNameMap.get(str);
				if(lab == null) lab = str;
				name = str;
			}else{
				Schema.DescribeFieldResult dr = allFieldMap.get(str);
				lab = defNeedFieldNameMap.get(str);
				if(lab == null) lab = dr.getLabel();
				name = str;
				if(isOk == null){tmp.put('template', template.replace('$field$', name)); isOk = str;}
				tmp.put('typ', dr.getType().name());
			}
			tmp.put('field', name);
			tmp.put('title', lab);
			if(defFieldNameWidthMap.containsKey(str)) tmp.put('width', defFieldNameWidthMap.get(str));
			if(defTemplateMap.containsKey(str) && str != isOk) tmp.put('template', defTemplateMap.get(str));
			jsonLst.add(tmp);
		}
		return JSON.serialize(jsonLst);	
	}
	private static void parseFieldsXml(String pShopCode) {
		Dom.XMLNode targetNode = CommXmlUtils.parseXmlDoc('ExpoServiceConfig', pShopCode);
		if (targetNode == null) return;
		// 店舗情報はＸＭＬから取得する
		Dom.XmlNode orgInfoFields = targetNode.getChildElement(ORGLISTFIELDS, null);
		if(orgInfoFields != null){
			List<String> tmpShowOrderLst = new List<String>();
			// XMLに定義された表示項目リスト取得、処理を行う
			for (String item : CommUtils.nullToBlank(orgInfoFields.getText()).deleteWhitespace().split(',')) {
				String[] keySplits = item.split(':');
				if (keySplits.size() != 2) {
					//表示項目書式の設定が不正です[API名:項目ラベル]
					Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_041_0031));
					break;
				}
				String key = keySplits[0].toLowerCase().trim();
				String lab = keySplits[1];
				
				defNeedFieldNameMap.put(key, lab);
				if(key == 'id') continue;

				if(!tmpShowOrderLst.contains(key)) tmpShowOrderLst.add(key); // xml中的字段
			}
			if(!tmpShowOrderLst.isEmpty()) defShowOrderLst = tmpShowOrderLst; // 覆盖默认字段
		}
	}
	private static void addAccessory(){
		for(String key : defFieldsMap.KeySet()){
			// 填入附件字段
			String pos = defFieldsMap.get(key);
			Integer index = 0;
			if(pos == BEHIND) index = defShowOrderLst.size() - 1;
			else if(pos == FRONT) index = 0;
			else index = defShowOrderLst.indexOf(pos);
			
			if(index == -1) continue;
			
			defShowOrderLst.add(index, key);
		}
	}
}