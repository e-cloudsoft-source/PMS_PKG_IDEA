public without sharing class ExpoHelperUtil {
	private static final String APPOTION_NAMESPACE = CommConst.APPOTION_NAMESPACE;
	public static final String DATE_FORMAT = 'yyyy-MM-dd';
	public static final String DATETIME_FORMAT = 'yyyy-MM-dd';
	// 2018/11/08 EXPOからAWSのAPIを呼び出し機能対応 WSQ BEGIN
	public static String EXPO_ENDPOINTURL {get{
		return CommUtils.nullToBlank(ExpoDefine__c.getOrgDefaults().ServiceEndpoint__c);
	}}
	public static String EXPO_SITEDOMAIN{get{
		return CommUtils.nullToBlank(ExpoDefine__c.getOrgDefaults().ExpoDomain__c);
	}}
	public static String EXPO_IMGENDPOINTURL{get{
		return CommUtils.nullToBlank(ExpoDefine__c.getOrgDefaults().ExpoImgEndPoint__c);
	}}
	// 2018/11/08 EXPOからAWSのAPIを呼び出し機能対応 WSQ END
	// 获取有效ExpoUser
	public static List<ExpoUser__c> getThisUserNameInfo(String userName){
		return [Select Id, UserName__c, IsActive__c, ChangePasswordFlg__c, PwdResetSendMalFlg__c From ExpoUser__c Where UserName__c =: userName And IsActive__c = true];
	}
	/*
	// 各ページ遷移の際に自動設定のパラメータ
	public static void SetSidToPage(PageReference page, String sid) {
		Map<String,String> paramMap = new map<String,String>();
		paramMap.put('sid',sid);
		page.getParameters().putAll(paramMap);
	}*/
	// 获取SessinonId
	public static String generateNewSessionId() {
		DateTime dt = DateTime.now();	   //  donot use such session id
		return EncodingUtil.convertToHex(Crypto.generateDigest('md5', Blob.valueOf(dt.formatLong())));
	}
	// ユーザ情報存在チェックを行う
	public static ExpoUser__c getUserBySession(String sessionId){
		// 該当セッションIdあり
		List<ExpoSession__c> sessions = [SELECT ID,ExpireDT__c,ExpoUserRef__c,SessionId__c FROM ExpoSession__c WHERE SessionId__c = :sessionId];
		if (!sessions.isEmpty()) {
			String userId = null;
			for (ExpoSession__c session : sessions) {
				if (session.ExpireDT__c >= DateTime.now()) {
					userId = session.ExpoUserRef__c;
				}
			}
			if (!CommUtils.isBlank(userId)) {
				List<ExpoUser__c> users = [SELECT Id, Name, UserName__c, Email__c, Fax__c, Phone__c, ShopCode__c, ExpoOrgInfoRef__c, ExpoOrgInfoRef__r.Name FROM ExpoUser__c WHERE id = :userId And IsActive__c = true];
				if (!users.isEmpty()) {
					ExpoUser__c aUser = users[0];
					return aUser;
				}
			}
		}
		return null;
	}
	//　該当ユーザID対応セッション取得
	private static ExpoSession__c getSessionByUserId(String userId){
		ExpoSession__c session = null;
		if (!CommUtils.isBlank(userId)) {
			List<ExpoUser__c> users = [Select Id, UserName__c, Name, password__c FROM ExpoUser__c WHERE id = :userId And IsActive__c = true];
			if (!users.isEmpty()) {
				ExpoUser__c aUser = users[0];
				List<ExpoSession__c> sessions = [SELECT ID,ExpireDT__c,ExpoUserRef__c,SessionId__c FROM ExpoSession__c WHERE ExpoUserRef__c = :aUser.id order by LastModifiedDate desc];
				if (!sessions.isEmpty()) {
					session = sessions[0];
					if (session.ExpireDT__c >= DateTime.now()) {
						return session;
					}
				}
			}
		}
		return session;
	}
	// 设置sessionInfo
	// 該当ユーザはすでにログインした　かつ　ログイン期間は有効期間以内の場合、ログイン有効期間を延長する
	public static String writeSessionId(Id userId, String inSessionID) {
		// ユーザID　かつ　新たSESSIONのIDが存在
		if (!CommUtils.isBlank(userId) && !CommUtils.isBlank(inSessionID)) {
			// 2019/09/15 Security Check BY zyz BEGIN
			List<String> chkFieldsLst = new List<String>{'sessionid__c','expiredt__c'};
			Map<String,Schema.SObjectField> mm = Schema.SObjectType.ExpoSession__c.fields.getMap();
			if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
				return '';
			}
			// 2019/09/15 Security Check BY zyz END
			ExpoSession__c session = getSessionByUserId(userId);
			if (session == null) {
				session = new ExpoSession__c(ExpoUserRef__c = userId);
			} else {
				inSessionID = session.sessionId__c;
			}
			session.sessionId__c = inSessionID;
			session.ExpireDT__c = DateTime.now().addSeconds(ExpoCommonConst.AuthReleaseTime);
			upsert session;
		}
		return inSessionID;
	}
	// 該当ユーザのSESSIONを削除する
	public static void removeSessionId(Id userId) {
		// 2019/09/15 Security Check BY zyz BEGIN
		if (!CommSecurityUtils.isDeleteable(ExpoSession__c.getSObjectType())) {
			return;
		}
		// 2019/09/15 Security Check BY zyz END
		if (CommUtils.isBlank(userId)) return;
		ExpoSession__c[] expoSessions = [SELECT ID FROM ExpoSession__c WHERE ExpoUserRef__c = :userId];
		if(!expoSessions.isEmpty())
			delete [SELECT ID FROM ExpoSession__c WHERE ExpoUserRef__c = :userId];
	}
	
	// *************************************************************
	// 保存新规数据处理
	public static String saveInfo(String dataId, String fieldJson, Sobject s){
		if(CommUtils.isBlank(fieldJson)) return dataId;
		Map<String,List<String>> fieldMap = (Map<String,List<String>>)JSON.deserializeStrict(fieldJson, Map<String,List<String>>.class);
		if(fieldMap.isEmpty()) return dataId;
		if(!CommUtils.isBlank(dataId)) s.put('Id', dataId);
		for(String api : fieldMap.keySet()){
			List<String> fieldLst = fieldMap.get(api);
			if(fieldLst.size() != 3) continue;
			String val = fieldLst[0];
			String typeMode = fieldLst[2];
			// 参照 赋值
			//public enum API_TYPE{REF, STR, BLN, DT, DTTM, PLST, MPLST, TEXTAREA, CPLST, INTE, DBL, CURR, PCT}
			if(typeMode == API_TYPE.REF.name()){
				s.put(api, CommUtils.nullToBlank(val));
			}
			// 整数
			else if(typeMode == API_TYPE.INTE.name()){
				s.put(api, CommUtils.nullToZero(val));
			}
			// 双精度小数
			else if(typeMode == API_TYPE.DBL.name()){
				s.put(api, CommUtils.nullToZero(val));
			}
			// 通貨
			else if(typeMode == API_TYPE.CURR.name()){
				s.put(api, CommUtils.nullToZero(val));
			}
			// 百分比
			else if(typeMode == API_TYPE.PCT.name()){
				s.put(api, CommUtils.nullToZero(val));
			}
			// 日付  赋值 格式必须*yyyy-MM-dd*
			else if(typeMode == API_TYPE.DT.name()){
				Date dt = CommUtils.isBlank(val) ? null : Date.valueOf(CommUtils.nullToBlank(val));
				s.put(api, dt);
			}
			// 日付/時刻  赋值
			else if(typeMode == API_TYPE.DTTM.name()){
				Datetime dtTm = CommUtils.isBlank(val) ? null : Datetime.valueOf(CommUtils.nullToBlank(val));
				s.put(api, dtTm);
			}
			// チェックボックス  赋值
			else if(typeMode == API_TYPE.BLN.name()){
				s.put(api, val == 'on' ? true : Boolean.valueOf(CommUtils.nullToBlank(val)));
			}
			// 複数選択  赋值
			else if(typeMode == API_TYPE.MPLST.name()){
				s.put(api,val);
			} 
			// その他  赋值
			else s.put(api, CommUtils.nullToBlank(val));
		}
		upsert s;
		return CommUtils.nullToBlank(s.get('Id'));
	}
	// 获取XML定义
	/* 
	* fieldReqSet => *配置API必须小写* 固定标准必填字段
	* fieldRomSet => *配置API必须小写* 固定只读字段
	* fieldNotSet => *配置API必须小写* 固定不显示字段
	*/
	public static ExpoFieldInfo getExpoXML(String modeName, Schema.SObjectType sObjectType, Set<String> fieldReqSet, Set<String> fieldRomSet, Set<String> fieldNotSet){
		ExpoFieldInfo expoXml = new ExpoFieldInfo(false);
		if(fieldReqSet != null) expoXml.fieldReqSet.addAll(fieldReqSet);
		if(fieldRomSet != null) expoXml.fieldRomSet.addAll(fieldRomSet);
		if(fieldNotSet != null) expoXml.fieldNotSet.addAll(fieldNotSet);
		// XML定义的获取处理
		Dom.XmlNode targetNode = CommXmlUtils.parseXmlDoc('ExpoServiceConfig', '');
		if (targetNode == null) return expoXml;
		Map<String, Schema.DescribeFieldResult> modeDefValMaps = CommSqlUtils.getAllFieldLst(sObjectType,false,true);
		// 店舗情報はＸＭＬから取得する
		Dom.XmlNode modeNode = targetNode.getChildElement(modeName, null);
		if(modeNode != null){ // 当前mode的定义信息
			Dom.XmlNode requiredNodes = modeNode.getChildElement('REQUIREDFIELDS', null);
			Dom.XmlNode widthsNodes = modeNode.getChildElement('WIDTHFIELDS', null);
			Dom.XmlNode textAreaImgNodes = modeNode.getChildElement('TEXTAREAIMG', null);
			Dom.XmlNode fieldsNodes = modeNode.getChildElement('FIELDS', null);
			Dom.XmlNode heightNodes = modeNode.getChildElement('HEIGHT', null);
			if(requiredNodes != null){ // 自定义必填项处理
				for(String req : expoXml.getCustInfo(requiredNodes)){ // API转成小写
					if(CommUtils.isBlank(req)) continue; 
					expoXml.fieldReqSet.add(CommUtils.nullToBlank(req));
				}
			}
			if(widthsNodes != null){ // 自定义行高处理
				// html 长度单位换算 100px相当于75pt长度 [PX = PT * 0.75]/ 100px相当于6.25em长度 [PX = EM * 16]
				Pattern p = Pattern.compile('[^0-9^.]'); // 正则表达式含义[取0-9 的数字]
				for(String widths : expoXml.getCustInfo(widthsNodes)){
					String[] widthsSplit = CommUtils.nullToBlank(widths).split(':');
					if(widthsSplit.size() != 2) continue;
					String api = CommUtils.nullToBlank(widthsSplit[0]);
					String width = CommUtils.nullToBlank(widthsSplit[1]);
					Decimal apiWidth;
					Matcher m = p.matcher(width);
					// 判断以px结尾
					if(width.endsWith('px')){
						apiWidth = CommUtils.nullToZero(m.replaceAll('').trim()).divide(1, 2, System.RoundingMode.UP);
					}
					else if(width.endsWith('pt')){
						apiWidth = (CommUtils.nullToZero(m.replaceAll('').trim()) * 0.75).divide(1, 2, System.RoundingMode.UP);
					}
					else if(width.endsWith('em')){
						apiWidth = (CommUtils.nullToZero(m.replaceAll('').trim()) * 16).divide(1, 2, System.RoundingMode.UP);
					} else {
						apiWidth = (CommUtils.nullToZero(m.replaceAll('').trim())).divide(1, 2, System.RoundingMode.UP);
					}
					expoXml.custFieldWidthMap.put(api, CommUtils.nullToZero(apiWidth));
				}
			}
			if(textAreaImgNodes != null){ // 自定义TextareaImg字段处理
				for(String textAreaImg : expoXml.getCustInfo(textAreaImgNodes)){
					if(CommUtils.isBlank(textAreaImg)) continue; 
					expoXml.custTextAreaImgSet.add(CommUtils.nullToBlank(textAreaImg));
				}
			}
			// 2019/04/03 TEST[LOOKUP] WGCH BEGIN
			Dom.XmlNode lookUpNodes = modeNode.getChildElement('LOOKUPFIELDS', null);
			if(lookUpNodes != null){ // 自定义行高处理
				String[] lookUpFields = CommUtils.nullToBlank(lookUpNodes.getText()).toLowerCase().split(',');
				for(String lookUpField : lookUpFields){
					if(CommUtils.isBlank(lookUpField)) continue;
					expoXml.fieldLkpSet.add(CommUtils.nullToBlank(lookUpField));
				}
			}
			// 2019/04/03 TEST[LOOKUP] WGCH END
			if(fieldsNodes != null){ // 自定义版块API处理
				for (Dom.Xmlnode sectionNode : fieldsNodes.getChildElements()) {
					if(sectionNode.getName() != 'SECTION') continue;
					SectionInfo section = new SectionInfo(sectionNode, modeDefValMaps, expoXml);
					if(!section.sctnColLst.isEmpty()) expoXml.custSectionInfoLst.add(section);
				}
				// 补齐最大列数处理
				addCol(expoXml);
			}
			if(heightNodes != null){ // 自定义行高处理
				String height = CommUtils.nullToBlank(heightNodes.getText());
				if(!CommUtils.isBlank(height)) expoXml.custHeight = height;
			}
		}
		return expoXml;
	}
	// 获取DEF定义
	/* 
	* fieldReqSet => *配置API必须小写* 固定标准必填字段
	* fieldRomSet => *配置API必须小写* 固定只读字段
	* fieldNotSet => *配置API必须小写* 固定不显示字段
	* orderLst => 版块Key
	* defMap   => KEY:版块Key / Val:配置格式{ SECTION(TITLE);SECTION(列数);API1:LAB1,API2,API3...; } *PS: 可以自定义字段LAB, 不定义取字段默认LAB*
	* sObjectType => 表
	* Demo => List<String> orderLst = new List<String>{'0'};
			  Map<String, String> defMap = new Map<String, String>{'0' => '情報;1;Name:店舗名,Post__c;};
	*/
	public static ExpoFieldInfo getExpoDef(List<String> orderLst, Map<String, String> defMap, Schema.SObjectType sObjectType, Set<String> fieldReqSet, Set<String> fieldRomSet, Set<String> fieldNotSet){
		ExpoFieldInfo expoDef = new ExpoFieldInfo(true);
		if(fieldReqSet != null) expoDef.fieldReqSet.addAll(fieldReqSet);
		if(fieldRomSet != null) expoDef.fieldRomSet.addAll(fieldRomSet);
		if(fieldNotSet != null) expoDef.fieldNotSet.addAll(fieldNotSet);
		Map<String, Schema.DescribeFieldResult> modeDefValMaps = CommSqlUtils.getAllFieldLst(sObjectType,false,true);
		for(String key : orderLst){
			if(!defMap.containsKey(key)) continue;
			expoDef.custSectionInfoLst.add(new SectionInfo(defMap.get(key), modeDefValMaps, expoDef));
		}
		// 补齐最大列数处理
		addCol(expoDef);
		return expoDef;
	}
	// 补齐最大列数处理
	private static void addCol(ExpoFieldInfo expo){
		for(SectionInfo section : expo.custSectionInfoLst){
			for(List<String> rowApiLst : section.sctnColLst){
				for(Integer i = rowApiLst.size(); i < expo.custColMax; i++){
					setInputWidthMax(expo, BLANK, rowApiLst.size()); // 入力列最大宽度处理
					rowApiLst.add(BLANK);
					if(!expo.custFieldInfoMap.containsKey(BLANK)) expo.custFieldInfoMap.put(BLANK, new FieldInfo());
				}
			}
		}
	}
	// 入力列最大宽度处理
	private static void setInputWidthMax(ExpoFieldInfo expo, String api, Integer colNo){
		Decimal fieldWid = expo.DEFWID_INPUT; // 默认入力框宽度
		if(expo.custFieldWidthMap.containsKey(api)) fieldWid = expo.custFieldWidthMap.get(api); // 设置自定义入力框宽度
		fieldWid += expo.DEFWID_LAB; // 合计TD宽度
		if(!expo.custTdWidthMaxMap.containsKey(colNo)) expo.custTdWidthMaxMap.put(colNo, 0); // 设置TD宽度最大值处理
		Decimal tdWidthMax = expo.custTdWidthMaxMap.get(colNo) > fieldWid ? expo.custTdWidthMaxMap.get(colNo) : fieldWid;
		expo.custTdWidthMaxMap.put(colNo, tdWidthMax);
	}		
	// 设置Val
	public static void setApiVal(Sobject s, ExpoFieldInfo expo){
		setApiVal(s, expo, new Map<String, String>());
	}
	public static void setApiVal(Sobject s, ExpoFieldInfo expo, Map<String, String> repApiMap){
		for(FieldInfo field : expo.custFieldInfoMap.values()){
			if(CommUtils.isBlank(field.fieldApi)) continue;
			field.fieldVal = CommUtils.nullToBlank(s.get(field.fieldApi));
			if(field.fieldTyp == API_TYPE.REF.name()){ // 参照初始化处理
				// 会計商品的消費税
				// 2019/04/03 TEST[LOOKUP] WGCH BEGIN
				if(field.fieldApi == 'jmstref__c' && field.fieldRef == (APPOTION_NAMESPACE + 'jmst__c')) {
					String taxRateVal = Integer.valueOf(CommUtils.nullToZero(getValueByApi(s, getfieldRefNameApi(field.fieldApi))))+'%';
					field.fieldPLst.add(new SelectOption(field.fieldVal,taxRateVal));
					field.fieldPLstMap.put(field.fieldVal,taxRateVal);
				} else {
					String fieldNm = CommUtils.nullToBlank(getValueByApi(s, getfieldRefNameApi(field.fieldApi)));
					field.fieldPLst.add(new SelectOption(field.fieldVal, fieldNm));
					field.fieldPLstMap.put(field.fieldVal, fieldNm);
				}
				// 2019/04/03 TEST[LOOKUP] WGCH END
			} else field.fieldVal = repApiMap.containsKey(field.fieldApi) ? CommUtils.nullToBlank(getValueByApi(s, repApiMap.get(field.fieldApi))) : CommUtils.nullToBlank(s.get(field.fieldApi));
		}
	}
	// 页面信息
	public class ExpoFieldInfo{
		public ExpoFieldInfo(Boolean wkIsDefFlg){
			isDefFlg = wkIsDefFlg;
			custHeight = '35px';
			custColMax = 1;
			custSectionInfoLst = new List<SectionInfo>();
			custFieldInfoMap = new Map<String, FieldInfo>();
			custFieldWidthMap = new Map<String, Decimal>();
			custTdWidthMaxMap = new Map<Integer, Decimal>();
		}
		
		public List<String> getCustInfo(Dom.XmlNode nodes){
			return CommUtils.nullToBlank(nodes.getText()).toLowerCase().split(',');
		}
		public Boolean isDefFlg{get; set;}
		public Decimal custTrWidthMax{get{
			if(custTrWidthMax == null) custTrWidthMax = 0;
			for(Decimal tdWidthMax : custTdWidthMaxMap.values()) custTrWidthMax += tdWidthMax;
			return custTrWidthMax;
		} set;}  // 行宽最大值
		public String custLabWidth{get{ return (DEFWID_LAB + 'px');} set;} // 默认Lab宽度
		public String custHeight{get;set;} // 自定义行的高度
		public Integer custColMax{get;set;} // 自定义最大列数
		public List<SectionInfo> custSectionInfoLst{get;set;} // 自定义版块LST
		public Map<String, FieldInfo> custFieldInfoMap{get;set;} // 所有API数据MAP Key => API / Val => API信息
		public Map<Integer, Decimal> custTdWidthMaxMap{get;set;}  // 所有Td最大宽度集计Map Key => 列No / Val => TD最大宽度
		/*
		* 全局变量区域
		*/
		public Set<String> custApiSet = new Set<String>(); // 自定义API SET *PS: Select 的所有API*
		public Set<String> custTextAreaImgSet = new Set<String>(); // 自定义TEXTAREAIMG字段
		public Map<String, Decimal> custFieldWidthMap;  // 所有API自定义宽度MAP Key => API / Val => API入力宽度
		/*
		* 固定值区域
		*/
		public final Decimal DEFWID_LAB = 150; // 默认Lab宽度
		public final Decimal DEFWID_INPUT = 300; // 默认入力框宽度 
		public Set<String> fieldReqSet = new Set<String>(); // *配置API必须小写* 固定标准必填字段
		public Set<String> fieldRomSet = new Set<String>(); // *配置API必须小写* 固定只读字段
		public Set<String> fieldNotSet = new Set<String>(); // *配置API必须小写* 固定不显示字段
		// 2019/04/03 TEST[LOOKUP] WGCH BEGIN
		public Set<String> fieldLkpSet = new Set<String>(); // *配置API必须小写* 固定标准放大镜字段
		// 2019/04/03 TEST[LOOKUP] WGCH END
		public String DATEFORMAT{get { return DATE_FORMAT;} set;} // 固定格式
		public String DATETIMEFORMAT{get { return DATETIME_FORMAT;}set;} // 固定格式 
		
	}
	// Section数据信息
	public class SectionInfo{
		public SectionInfo(Dom.xmlNode sectionNode, Map<String, Schema.DescribeFieldResult> modeDefValMaps, ExpoFieldInfo expoXml){  // 自定义处理
			sctnTitle = CommUtils.nullToBlank(sectionNode.getAttribute('TITLE',null));
			sctnCol = CommUtils.nullToIntZero(sectionNode.getAttribute('COLNUM',null));
			init(sectionNode.getText(), modeDefValMaps, expoXml);
		}
		public SectionInfo(String sectionInfo, Map<String, Schema.DescribeFieldResult> modeDefValMaps, ExpoFieldInfo expoDef){ // 默认值处理
			List<String> sectionSplit = sectionInfo.split(';');
			if(sectionSplit.size() != 3) return;
			sctnTitle = CommUtils.nullToBlank(sectionSplit[0]);
			sctnCol = CommUtils.nullToIntZero(sectionSplit[1]);
			init(sectionSplit[2], modeDefValMaps, expoDef);
		}
		private void init(String section, Map<String, Schema.DescribeFieldResult> modeDefValMaps, ExpoFieldInfo expo){
			sctnTitle = CommUtils.isBlank(sctnTitle) ? '情報' : sctnTitle;
			sctnCol = sctnCol == 0 ? 1 : sctnCol;
			expo.custColMax = sctnCol > expo.custColMax ? sctnCol : expo.custColMax; // 最大列数处理
			sctnColLst = new List<List<String>>();
			List<String> rowApiLst = new List<String>(); // 每行APILST
			for(String apiInfo : CommUtils.nullToBlank(section).split(',')){
				String[] apiInfoSplit = apiInfo.split(':');
				if(apiInfoSplit.isEmpty()) continue;
				String api = CommUtils.nullToBlank(apiInfoSplit[0]).toLowerCase(); // 对应字段的API转成小写
				String lab = apiInfoSplit.size() > 1 ? CommUtils.nullToBlank(apiInfoSplit[1]) : ''; // 对应字段的名
				
				// XML设定格式： XX:XXXX,XX和XXXX(为API)不可为空 字段的类型不为空(过滤数式)
				if(expo.fieldNotSet.contains(api)) continue; // 不要字段过滤
				else if(api == BLANK){ // 占位符处理
					setInputWidthMax(expo, BLANK, rowApiLst.size()); // 入力列最大宽度处理
					rowApiLst.add(api); // 集计当前行APILST
					if (Math.mod(rowApiLst.size(),sctnCol) == 0) { // 每行API满
						sctnColLst.add(rowApiLst);
						rowApiLst = new List<String>();
					}
					if(!expo.custFieldInfoMap.containsKey(BLANK)) expo.custFieldInfoMap.put(api, new FieldInfo());
					continue;
				}
				// 不符合条件的API过滤掉处理
				else if(CommUtils.isBlank(api) || !modeDefValMaps.containsKey(api) || expo.custApiSet.contains(api)) continue;
				Schema.DescribeFieldResult dr = modeDefValMaps.get(api);
				// 数式 和 自动采番 过滤掉处理
				if( !CommUtils.isBlank(dr.getCalculatedFormula()) || dr.isAutoNumber()) continue;
				setInputWidthMax(expo, api, rowApiLst.size()); // 入力列最大宽度处理
				rowApiLst.add(api); // 集计当前行APILST
				if(Math.mod(rowApiLst.size(),sctnCol) == 0) {
					sctnColLst.add(rowApiLst);
					rowApiLst = new List<String>();
				}
				expo.custApiSet.add(api); // 集计所有API
				FieldInfo field = new FieldInfo(api, new Map<String, String>{api => lab}, dr); // 获取当前API所有信息
				if(field.fieldTyp == API_TYPE.REF.name()) expo.custApiSet.add(getfieldRefNameApi(api)); // 参照对应 add 对应的Name
				if(expo.fieldReqSet.contains(api)) field.fieldReq = true; // 必填项处理
				if(expo.fieldRomSet.contains(api)){ // 只读字段处理
					field.fieldRom = true;
					field.fieldTyp = API_TYPE.STR.name();
				}
				if(expo.custFieldWidthMap.containsKey(field.fieldApi)) field.fieldWid = expo.custFieldWidthMap.get(field.fieldApi); // 入力列宽度处理
				if(expo.custTextAreaImgSet.contains(field.fieldApi)) field.fieldImg = true; // 图片特殊处理
				// 2019/04/03 TEST[LOOKUP] WGCH BEGIN
				if(field.fieldTyp == API_TYPE.REF.name() && expo.fieldLkpSet.contains(field.fieldApi)){
					Map<String, Schema.DescribeSobjectResult> resultsMap = getSobjInfo(field.fieldRef);
					if(resultsMap.containsKey(field.fieldRef)){
						Schema.DescribeSobjectResult result = resultsMap.get(field.fieldRef);
						field.fieldPrefix = result.keyPrefix;
					}
				}
				// 2019/04/03 TEST[LOOKUP] WGCH END
				expo.custFieldInfoMap.put(api, field); // put当前API所有信息
			}
			// 最后一行处理
			if(!rowApiLst.isEmpty()){
				for(Integer i = rowApiLst.size(); i < sctnCol; i++){
					setInputWidthMax(expo, BLANK, rowApiLst.size()); // 入力列最大宽度处理
					rowApiLst.add(BLANK);
				}
				sctnColLst.add(rowApiLst); // 补位处理
				if(!expo.custFieldInfoMap.containsKey(BLANK)) expo.custFieldInfoMap.put(BLANK, new FieldInfo());
			}
		}
		public String sctnTitle{get;set;} // SECTION Title
		public Integer sctnCol{get;set;} // SECTION 列数
		public List<List<String>> sctnColLst{get;set;} // SECTION 每行对应的API集合
	}
	/*
	* API都为小写
	* field: API字段[复数时分隔符',']
	* labMap: KEY=>API / VAL=>API自定义LAB
	* modeDefValMaps: 表数据MAP
	* notApiSet: 过滤的API数据集
	*/
	public static List<FieldInfo> getFieldInfo(String field, Map<String, Schema.DescribeFieldResult> modeDefValMaps, Sobject s){
		return getFieldInfo(field, new Map<String, String>(), modeDefValMaps, s, new Set<String>());
	}
	public static List<FieldInfo> getFieldInfo(String field, Map<String, Schema.DescribeFieldResult> modeDefValMaps, Sobject s, Set<String> notApiSet){
		return getFieldInfo(field, new Map<String, String>(), modeDefValMaps, s, notApiSet);
	}
	public static List<FieldInfo> getFieldInfo(String field, Map<String, String> labMap, Map<String, Schema.DescribeFieldResult> modeDefValMaps){
		return getFieldInfo(field, new Map<String, String>(), modeDefValMaps, null, new Set<String>());
	}
	public static List<FieldInfo> getFieldInfo(String field, Map<String, String> labMap, Map<String, Schema.DescribeFieldResult> modeDefValMaps, Sobject s, Set<String> notApiSet){
		List<FieldInfo> fieldInfoLst = new List<FieldInfo>(); // 初期化
		if(CommUtils.isBlank(field)) return fieldInfoLst; // 无效跳出
		for(String api : field.split(',')){
			api = CommUtils.nullToBlank(api).toLowerCase(); // API转成小写
			if(!modeDefValMaps.containsKey(api) || notApiSet.contains(api)) continue; // 无效跳出
			String val = s == null ? '' : CommUtils.nullToBlank(s.get(api)); // 该字段Val
			fieldInfoLst.add(new FieldInfo(api, val, labMap, modeDefValMaps.get(api)));
		}
		return fieldInfoLst;
	}
	public static final String BLANK = '$_blank_$';
	public enum API_TYPE{REF, STR, BLN, DT, DTTM, PLST, MPLST, TEXTAREA, CPLST, INTE, DBL, CURR, PCT, EMAIL}
	public class FieldInfo{
		public FieldInfo(){
			fieldApi = fieldVal = fieldLab = '';
			fieldReq = fieldRom = fieldImg = false;
			fieldPLst = new List<SelectOption>();
			fieldPLstMap = new Map<String, String>();
		}
		public FieldInfo(String api, Map<String, String> labMap, Schema.DescribeFieldResult dr){
			init(api, null, labMap, dr);
		}
		public FieldInfo(String api, String val, Map<String, String> labMap, Schema.DescribeFieldResult dr){
			init(api, val, labMap, dr);
		}
		private void init(String api, String val, Map<String, String> labMap, Schema.DescribeFieldResult dr){
			fieldApi = api;
			fieldVal = val == null ? '' : val;
			fieldLen = dr.getPrecision() == 0 ? dr.getLength() : dr.getPrecision();
			fieldLab = labMap.containsKey(api) && !CommUtils.isBlank(labMap.get(api)) ? labMap.get(api) : dr.getLabel();
			fieldRef = dr.getReferenceTo().isEmpty() ? '' : dr.getReferenceTo()[0].getDescribe().getName().toLowerCase();
			fieldReq = (!dr.isNillable() && dr.isCreateable() && !dr.isDefaultedOnCreate());// API必填项判断
			fieldRom = fieldImg = false;
			fieldPLst = new List<SelectOption>();
			fieldWid = 300;
			fieldPLstMap = new Map<String, String>();
			if(dr.getType() == DisplayType.Reference){
				fieldTyp = API_TYPE.REF.name();
			} else if(dr.getType() == DisplayType.Email){
				fieldTyp = API_TYPE.EMAIL.name();
			} else if(dr.getType() == DisplayType.Boolean){
				fieldTyp = API_TYPE.BLN.name();
			} else if(dr.getType() == DisplayType.Date){
				fieldTyp = API_TYPE.DT.name();
			} else if(dr.getType() == DisplayType.DateTime){
				fieldTyp = API_TYPE.DTTM.name();
			} else if(dr.getType() == DisplayType.Percent){
				fieldTyp = API_TYPE.PCT.name();
			} else if(dr.getType() == DisplayType.Double){
				fieldTyp = API_TYPE.DBL.name();
			} else if(dr.getType() == DisplayType.Currency){
				fieldTyp = API_TYPE.CURR.name();
			} else if(dr.getType() == DisplayType.Integer){
				fieldTyp = API_TYPE.INTE.name();
			} else if(dr.getType() == DisplayType.Picklist){
				fieldTyp = API_TYPE.PLST.name();
				for(Schema.PicklistEntry rep : dr.getPicklistValues()) {
					fieldPLst.add(new SelectOption(rep.getValue(), rep.getLabel()));
					fieldPLstMap.put(rep.getValue(), rep.getLabel());
				}
			} else if(dr.getType() == DisplayType.MultiPicklist){
				fieldTyp = API_TYPE.MPLST.name();
				for(Schema.PicklistEntry rep : dr.getPicklistValues()) {
					fieldPLst.add(new SelectOption(rep.getValue(), rep.getLabel()));
					fieldPLstMap.put(rep.getValue(), rep.getLabel());
				}
			} else if(dr.getType() == DisplayType.TEXTAREA){
				fieldTyp = API_TYPE.TEXTAREA.name();
			} else{
				fieldTyp = API_TYPE.STR.name();
			}
		}
		public String fieldApi{get; set;} // API字段
		public String fieldVal{get; set;} // API数据
		public Integer fieldLen{get; set;} // API长度
		public String fieldLab{get; set;} // API名称
		public String fieldRef{get; set;} // API参照表名
		public String fieldTyp{get; set;} // API类型
		public Boolean fieldReq{get; set;} // API必填项
		public Boolean fieldRom{get; set;} // API只读
		public Decimal fieldWid{get; set;} // API入力框宽度
		public Boolean fieldImg{get; set;} // API TEXTAREAIMG FLG
		// 2019/04/03 TEST[LOOKUP] WGCH BEGIN
		public String fieldPrefix{get; set;} // Prefix
		public String fieldRefNm{get{
			if(fieldPLstMap.containsKey(fieldVal))
				return CommUtils.nullToBlank(fieldPLstMap.get(fieldVal));
			else 
				return fieldVal;
		} set;}  // API参照NAME名
		// 2019/04/03 TEST[LOOKUP] WGCH BEGIN
		public String fieldWidPx{get {
			return (fieldWid + 'px');
		} set;} // API入力框宽度PX
		public List<SelectOption> fieldPLst{get; set;} // API列表数据集
		public Map<String, String> fieldPLstMap{get; set;} // API列表数据集
		
	}
	private static final String RELATION_KEY = '__r.';
	private static String getfieldRefNameApi(String field){
		// 会計商品的消費税
		if(field == 'jmstref__c') {
			return field.replace('__c','__r.taxrate__c');
		}else return field.replace('__c','__r.name');
		//return field.replace('__c','__r.name');
	}
	// 获取级联字段信息处理
	public static KendoDataSourceAll getDependentOptions(String pObjName, String pControllingFieldName, String pDependentFieldName){
		KendoDataSourceAll kendo = new KendoDataSourceAll();
		//get the string to sobject global map
		Map<String,Schema.SObjectType> objGlobalMap = Schema.getGlobalDescribe();
		if (!objGlobalMap.containsKey(pObjName))
			return kendo;
		//get the type being dealt with
		Schema.SObjectType pType = objGlobalMap.get(pObjName);
		Map<String, Schema.SObjectField> objFieldMap = pType.getDescribe().fields.getMap();
		//verify field names
		if (!objFieldMap.containsKey(pControllingFieldName) || !objFieldMap.containsKey(pDependentFieldName))
			return kendo;
		//get the control values
		List<Schema.PicklistEntry> ctrl_ple = objFieldMap.get(pControllingFieldName).getDescribe().getPicklistValues();
		//get the dependent values
		List<Schema.PicklistEntry> dep_ple = objFieldMap.get(pDependentFieldName).getDescribe().getPicklistValues();
		//iterate through the values and get the ones valid for the controlling field name
		Bitset objBitSet = new Bitset();
		//set up the results
		for(Integer pControllingIndex=0; pControllingIndex < ctrl_ple.size(); pControllingIndex++){
			//get the pointer to the entry
			Schema.PicklistEntry ctrl_entry = ctrl_ple[pControllingIndex];
			//get the label
			String pControllingLabel = ctrl_entry.getLabel();
			//get the value
			String pControllingValue = ctrl_entry.getValue();
			kendo.parentKendoDs.add(new KendoDataSource(pControllingLabel, pControllingValue));
			//create the entry with the value
			// objResults.put(pControllingValue,new List<KendoDataSource>());
		}
		//check the dependent values
		for(Integer pDependentIndex=0; pDependentIndex < dep_ple.size(); pDependentIndex++){
			//get the pointer to the dependent index
			Schema.PicklistEntry dep_entry = dep_ple[pDependentIndex];
			//get the valid for
			String pEntryStructure = JSON.serialize(dep_entry);
			TPicklistEntry objDepPLE = (TPicklistEntry)JSON.deserialize(pEntryStructure, TPicklistEntry.class);
			//if valid for is empty, skip
			if (objDepPLE.validFor==null || objDepPLE.validFor==''){
				continue;
			}
			//iterate through the controlling values
			for(Integer pControllingIndex=0; pControllingIndex < ctrl_ple.size(); pControllingIndex++){
				if (objBitSet.testBit(objDepPLE.validFor,pControllingIndex)){
					//get the label
					String pControllingLabel = ctrl_ple[pControllingIndex].getLabel();
					//get the value
					String pControllingValue = ctrl_ple[pControllingIndex].getValue();
					kendo.childKendoDs.add(new KendoDataSource(pControllingLabel, pControllingValue, objDepPLE.label, objDepPLE.value));
				}
			}
		} 
		return kendo;
	}
	public class TPicklistEntry{
		public string active {get;set;}
		public string defaultValue {get;set;}
		public string label {get;set;}
		public string value {get;set;}
		public string validFor {get;set;}
		public TPicklistEntry(){}
	}
	private class Bitset{
		public Map<String,Integer> AlphaNumCharCodes {get;set;}
		public Map<String, Integer> Base64CharCodes { get; set; }
		public Bitset(){
			LoadCharCodes();
		}
		//Method loads the char codes
		private void LoadCharCodes(){
			AlphaNumCharCodes = new Map<String,Integer>{
				'!'=>33,'”'=>34,'#'=>35,'$'=>36,'%'=>37,'&'=>38,'\''=>39,'('=>40,')'=>41,'*'=>42,'+'=>43,','=>44,'-'=>45,
				'.'=>46,'/'=>47,'0'=>48,'1'=>49,'2'=>50,'3'=>51,'4'=>52,'5'=>53,'6'=>54,'7'=>55,
				'8'=>56,'9'=>57,':'=>58,';'=>59,'<'=>60,'='=>61,'>'=>62,'?'=>63,'@'=>64,
				'A'=>65,'B'=>66,'C'=>67,'D'=>68,'E'=>69,'F'=>70,'G'=>71,'H'=>72,'I'=>73,'J'=>74,
				'K'=>75,'L'=>76,'M'=>77,'N'=>78,'O'=>79,'P'=>80,'Q'=>81,'R'=>82,'S'=>83,'T'=>84,
				'U'=>85,'V'=> 86,'W'=>87,'X'=>88,'Y'=>89,'Z'=>90
			};
			Base64CharCodes = new Map<String, Integer>();
			//lower case
			Set<String> pUpperCase = AlphaNumCharCodes.keySet();
			for(String pKey : pUpperCase){
				//the difference between upper case and lower case is 32
				AlphaNumCharCodes.put(pKey.toLowerCase(),AlphaNumCharCodes.get(pKey)+32);
				//Base 64 alpha starts from 0 (The ascii charcodes started from 65)
				Base64CharCodes.put(pKey,AlphaNumCharCodes.get(pKey) - 65);
				Base64CharCodes.put(pKey.toLowerCase(),AlphaNumCharCodes.get(pKey) - (65) + 26);
			}
			//numerics
			for (Integer i=0; i<=9; i++){
				AlphaNumCharCodes.put(string.valueOf(i),i+48);
				//base 64 numeric starts from 52
				Base64CharCodes.put(string.valueOf(i), i + 52);
			}
		}
		public Boolean testBit(String pValidFor,Integer n){
			//the list of bytes
			List<Integer> pBytes = new List<Integer>();
			//multiply by 6 since base 64 uses 6 bits
			Integer bytesBeingUsed = (pValidFor.length() * 6)/8;
			//will be used to hold the full decimal value
			Integer pFullValue = 0;
			//must be more than 1 byte
			if (bytesBeingUsed <= 1)
				return false;
			//calculate the target bit for comparison
			Integer bit = 7 - (Math.mod(n,8));
			//calculate the octet that has in the target bit
			Integer targetOctet = (bytesBeingUsed - 1) - (n >> bytesBeingUsed);
			//the number of bits to shift by until we find the bit to compare for true or false
			Integer shiftBits = (targetOctet * 8) + bit;
			//get the base64bytes
			for(Integer i=0;i<pValidFor.length();i++){
				//get current character value
				pBytes.Add((Base64CharCodes.get((pValidFor.Substring(i, i+1)))));
			}
			//calculate the full decimal value
			for (Integer i = 0; i < pBytes.size(); i++)
			{
				Integer pShiftAmount = (pBytes.size()-(i+1))*6;//used to shift by a factor 6 bits to get the value
				pFullValue = pFullValue + (pBytes[i] << (pShiftAmount));
			}
			//& is to set the same set of bits for testing
			//shift to the bit which will dictate true or false
			Integer tBitVal = ((Integer)(Math.Pow(2, shiftBits)) & pFullValue) >> shiftBits;
			return  tBitVal == 1;
		}
	}
	// kedo数据集All
	public class KendoDataSourceAll{
		public KendoDataSourceAll(){
			parentKendoDs = new List<KendoDataSource>();
			childKendoDs = new List<KendoDataSource>();
		}
		public List<KendoDataSource> parentKendoDs;
		public List<KendoDataSource> childKendoDs;
	}
	// kedo数据集
	public class KendoDataSource{
		public KendoDataSource(String parentName, String parentId){
			this.parentName = CommUtils.nullToBlank(parentName);
			this.parentId = CommUtils.nullToBlank(parentId);
			childName = childId = '';
		}
		public KendoDataSource(String parentName, String parentId, String childName, String childId){
			this.parentName = CommUtils.nullToBlank(parentName);
			this.parentId = CommUtils.nullToBlank(parentId);
			this.childName = CommUtils.nullToBlank(childName);
			this.childId = CommUtils.nullToBlank(childId);
		}
		public String parentName;
		public String parentId;
		public String childName;
		public String childId;
	}
	// 2019/04/03 TEST[LOOKUP] WGCH BEGIN
	public static Map<String, Schema.DescribeSobjectResult> getSobjInfo(String objNames){
		Map<String, Schema.DescribeSobjectResult> resultsMap = new Map<String, Schema.DescribeSobjectResult>();
		// sObject types to describe 
		String[] types = CommUtils.nullToBlank(objNames).split(',');
		// Make the describe call Schema.
		DescribeSobjectResult[] results = Schema.describeSObjects(types); 
		// For each returned result, get some info 
		for(Schema.DescribeSobjectResult res : results){
			resultsMap.put(CommUtils.nullToBlank(res.getName()).toLowerCase(), res);
		}
		return resultsMap;
	}
	public static Schema.DescribeSObjectResult findObjectFromRecordIdPrefix(String recordIdOrPrefix){
		Schema.DescribeSObjectResult result;
		try{
			//Get prefix from record ID
			//This assumes that you have passed at least 3 characters
			String myIdPrefix = String.valueOf(recordIdOrPrefix).substring(0,3);
			//Get schema information
			Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
			//Loop through all the sObject types returned by Schema
			for(Schema.SObjectType stype : gd.values()){
				Schema.DescribeSObjectResult r = stype.getDescribe();
				if(r == null) continue;
				String prefix = CommUtils.nullToBlank(r.getKeyPrefix());
				//Check if the prefix matches with requested prefix
				if(prefix!= null && prefix.equals(myIdPrefix)){
					result = r;
					break;
				}
			}
		}catch(Exception e){
			//System.debug(e);
		}
		return result;
	}
	// 2019/04/03 TEST[LOOKUP] WGCH END
	// 参照字段对应
	public static Object getValueByApi(Sobject s ,String field) {
		if (s == null) return '';
		String apiField = field.trim();
		// Jsonにアサインするキー: ssss__r.aaa__r.xxxx -> ssss__r_aaa__r_xxxx
		// XMLのAPI定義小文字、大文字区別されない対応
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
	// 2019/03/29 EXPO定義した組織情報を取得する WSQ BEGIN
	public static OrganizationInfo getOrganizationInfo() {
		OrganizationInfo ret = null;
	    try {
	        // XMLに定義する全て情報を格納する
	        Dom.XmlNode topNode = CommXmlUtils.getTagBetweenXml('ExpoServiceConfig',new List<String>{'<ORGANIZATION>','</ORGANIZATION>'}, null);
	        if (topNode != null) {
	        	ret = new OrganizationInfo(topNode);
	        }
	    } catch (Exception e) {}
	    return (ret == null ?  new OrganizationInfo() : ret);
	}
	// 組織情報定義
	public class OrganizationInfo {
		public String webSite{get;set;}
		public String email{get;set;}
		public Boolean isOpenBuyHistoryFlg{get;set;}
		public OrganizationInfo () {
			webSite = email = '';
			isOpenBuyHistoryFlg = true;
		}
		public OrganizationInfo(Dom.XmlNode node){
			webSite = CommXmlUtils.getChildElementByName(node, 'WEBSITE');
			email = CommXmlUtils.getChildElementByName(node, 'EMAIL');
			String strIsOpenBuyHistoryFlg = CommXmlUtils.getChildElementByName(node, 'ISOPENBUYHISTORY');
			isOpenBuyHistoryFlg = (CommUtils.isBlank(strIsOpenBuyHistoryFlg)) ? false : Boolean.valueOf(strIsOpenBuyHistoryFlg);
		}
	}
	// 2019/03/29 EXPO定義した組織情報を取得する WSQ END
	// 2019/04/15 EXPOの10.1.稼働率分析情報を取得（稼働率・ADR・RevPer・客単価） WSQ BEGIN
	public static AnalyticsFilter getAnalyticsFilter() {
		AnalyticsFilter ret = null;
	    try {
	        // XMLに定義する全て情報を格納する
	        Dom.XmlNode topNode = CommXmlUtils.getTagBetweenXml('ExpoServiceConfig',new List<String>{'<ANALYTICS>','</ANALYTICS>'}, null);
	        if (topNode != null) {
	        	ret = new AnalyticsFilter(topNode);
	        }
	    } catch (Exception e) {}
	    return (ret == null ?  new AnalyticsFilter() : ret);
	}
	// 組織情報定義
	public class AnalyticsFilter {
		public String leadFilter{get;set;}
		public String accFilter{get;set;}
		public AnalyticsFilter () {
			leadFilter = accFilter = '';
		}
		public AnalyticsFilter(Dom.XmlNode node){
			leadFilter = CommXmlUtils.getChildElementByName(node, 'LEAD_FILTER');
			accFilter = CommXmlUtils.getChildElementByName(node, 'ACCOUNT_FILTER');		
		}
	}
	// 2019/04/15 EXPOの10.1.稼働率分析情報を取得（稼働率・ADR・RevPer・客単価） WSQ END
	// 2021/05/31 EXPOログイン機能改修（EXPOユーザ情報アクセス問題回避　WSQ BEGIN
	public static ExpoUser__c getUserInfo(String username, String password){
		List<ExpoUser__c> users = [Select Id, UserName__c, Name, password__c FROM ExpoUser__c WHERE UserName__c =: username And IsActive__c = true And ActivationFlg__c = true];
		if (!users.isEmpty()) {
			ExpoUser__c aUser = users[0];
			if (aUser.password__c != null && aUser.password__c.equals(password)) {
				return aUser;
			}
		}
		return null;
	}
	// 2021/05/31 EXPOログイン機能改修（EXPOユーザ情報アクセス問題回避　WSQ END
}