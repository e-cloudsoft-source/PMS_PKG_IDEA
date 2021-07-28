/*
* 自设定pageField对象
* 专门用于显示自定义予約window
* 2019/06/15 新規予約を部屋ごとに時間と到着日をデフォルト設定
*/
public with sharing class PageCustomeFieldHelper {
	private static final String TEMPLATE_BLANK = 'blank';
	private static final String SOBJECT_TYPE = 'textarea';
	private static final integer MAX_TEXTAREA_LEN = 1000;
	//section定义信息
	public class SectionInfo{
		public Integer columnsInt{get;set;}
		public List<String> fieldLst;
		public String title{get;set;}
		// 2017/01/25 新規画面の項目自定義機能　by　zy　BEGIN
		public List<CusField> cusFields{get;set;}
		// 2017/01/25 新規画面の項目自定義機能　by　zy　END
		public boolean isHeadShowFlag{get{ return !CommUtils.isblank(title);}}
		public SectionInfo(){
		    columnsInt = 2;
		    fieldLst = new List<String>(); 
		    // 2017/01/25 新規画面の項目自定義機能　by　zy　BEGIN
		    cusFields = new List<CusField>();
		    // 2017/01/25 新規画面の項目自定義機能　by　zy　END
		}
		public void add(Set<String> fLst){
		    fieldLst.addAll(fLst);
		}
		public void add(List<String> fLst){
		    fieldLst.addAll(fLst);
		}
		// 2017/01/25 新規画面の項目自定義機能　by　zy　BEGIN
		public void add(CusField cus) {
			cusFields.add(cus);	
		}
		// 2017/01/25 新規画面の項目自定義機能　by　zy　END
	}
    //字段信息
    public class CusField{
    	// 項目api名
    	public String fieldName{get;set;}
    	//　必須項目フラグ
    	public boolean isRequired{get;set;}
    	//　項目ラベル
    	public String fieldLabel{get;set;}
    	//　項目タイプ
    	public String fieldType{get;set;}
    	//　参照関係フラグ
    	public boolean isRefFlag{get;set;}
    	//　項目local名
    	public String localName{get;set;}
    	//　項目名
    	public String name{get;set;}
    	//　項目スタイル
    	public String fieldStyle{get;set;}
    	//　項目クラス
    	public String styleClass{get;set;}
    	public String refName;
    	// JSONデータ対応
    	//　フィールド情報
    	public Schema.DisplayType typeName{get;set;}
    	// 表示値
    	public Object value;
    	// 非表示ID
    	public Object id;
    	public String searchKey;
    	public Schema.DescribeFieldResult cusDr;
    	public Schema.DescribeFieldResult refDr;
    	public CusField(){
    		fieldStyle = '';
    		styleClass = '';
    		searchKey = '';
    		isRequired = false;
    		isRefFlag = false;
    	}
    	public CusField(Schema.DescribeFieldResult dr){
    		fieldStyle = '';
    		styleClass = '';
    		searchKey = '';
    		isRequired = false;
    		isRefFlag = false;
    		name = dr.getName();
    		typeName = dr.getType();
    		fieldName = dr.getName();
    		fieldLabel = dr.getLabel();
    		localName = dr.getLocalName();
    		fieldType = '';
    		if (DisplayType.textarea == dr.getType() && dr.getLength() > MAX_TEXTAREA_LEN) {
    			fieldType = SOBJECT_TYPE;
    		}
    		cusDr = dr;
    	}
    	// 新会計画面対応
    	public CusField(Schema.DescribeFieldResult dr,boolean reqiredFlag,String style,String curClass,String curType){
    		fieldType = curType;
    		if (DisplayType.textarea == dr.getType() && dr.getLength() > MAX_TEXTAREA_LEN) {
    			fieldType = SOBJECT_TYPE;
    		}
    		name = dr.getName();
    		isRequired = reqiredFlag;
    		fieldName = dr.getName();
    		fieldLabel = dr.getLabel();
    		localName = dr.getLocalName();
    		fieldStyle = CommUtils.isBlank(style) ? '90%' : CommUtils.nullToBlank(style) ;
    		styleClass = CommUtils.nullToBlank(curClass);
    		typeName = dr.getType();
    	}
    }
    enum PROCEE_TYPE{BEFORE,AFTER,SPLIT}
    public class NodeItem {
		public NodeItem(String key ) {
			value = '';
			leadXmlTag = key;
			forwardFlag = false;
			saveKeyFlag = false;
			endSaveKeyFlag = false;
			oneRowProcessFlag = false;
			exculdeStr = '';
			operation = '';
			emailType = '';
			emailTagFormatJoinKey = '　';
		}
		// アレルギーのクスタム設定
		public NodeItem(Dom.XMLNode xmlNode) {
			value = '';
			forwardFlag = false;
			saveKeyFlag = false;
			endSaveKeyFlag = false;
			oneRowProcessFlag = false;
			emailType = '' ;
			fixedVal = '';
			emailTagFormatJoinKey = '　';
			leadXmlTag = '';
			Dom.XMLNode emailField = xmlNode.getChildElement('FIELD', null);
			if ( emailField != null ) {
				leadXmlTag = CommUtils.nullToBlank(emailField.getText());
			}
			Dom.XMLNode emailTagField = xmlNode.getChildElement('KEY', null);
			if (emailTagField != null){ 
				emailTag = CommUtils.nullToBlank(emailTagField.getText());
				String forwardStr = emailTagField.getAttribute('forward',null);
				if (!CommUtils.isBlank(forwardStr)) forwardFlag = isTrue(forwardStr);
				oneRowProcessFlag = isTrue(emailTagField.getAttribute('oneRowProcess',null));
			}
			Dom.XMLNode emailTagBegField = xmlNode.getChildElement('BEG', null);
			if (emailTagBegField != null) {
				emailTagBegKey = CommUtils.nullToBlank(emailTagBegField.getText());
				saveKeyFlag = isTrue(emailTagBegField.getAttribute('saveKey',null));
			}
			Dom.XMLNode emailTagEndField = xmlNode.getChildElement('END', null);
			if (emailTagEndField != null) {
				emailTagEndKey = CommUtils.nullToBlank(emailTagEndField.getText());
				endSaveKeyFlag = isTrue(emailTagEndField.getAttribute('saveKey',null));
			}
			Dom.XMLNode emailTagFormatField = xmlNode.getChildElement('FORMAT', null);
			if (emailTagFormatField != null) emailTagFormat = CommUtils.nullToBlank(emailTagFormatField.getText());

			Dom.XMLNode emailTagFormatJoinKeyField = xmlNode.getChildElement('FORMAT_JOINKEY', null);
			if (emailTagFormatJoinKeyField != null) emailTagFormatJoinKey = CommUtils.nullToBlank(emailTagFormatJoinKeyField.getText());
			
			Dom.XMLNode convertValField = xmlNode.getChildElement('CONVERT_VAL', null);
			if (convertValField != null) convertVal = CommUtils.nullToBlank(convertValField.getText());
		}
		public string leadXmlTag{get;set;}		// メールから取得の情報は該当タグ名にXMLを取得する
		public string emailTag{get;set;}		// 該当キーを見つかると、これから以後の文字列は取得対象
		public string emailTagBegKey{get;set;}	
		public string emailTagEndKey{get;set;}	// 該当XML関連情報は該当キーを見つかると、取得完了
		//public Integer subStrLen{get;set;}		// 指定開始から指定の文字数を取得する
		public string emailTagFormat{get;set;}	// 該当タグをParseする正規表現
		public string convertVal{get;set;}
		public string emailTagFormatJoinKey{get;set;}
		public string fixedVal{get;set;}
		public string value{get;set;}
		public string exculdeStr{get;set;}
		public string operation{get;set;}
		public boolean saveKeyFlag{get;set;}
		public boolean endSaveKeyFlag;
		// true：向前截取，false:向后截取
		public boolean forwardFlag{get;set;}
		public boolean oneRowProcessFlag{get;set;}
		public List<NodeItem> childItems{get;set;}
		private String emailType;
		private boolean isTrue(Object s){
			String result = CommUtils.nullToblank(s);
			if(CommUtils.isBlank(result)) return false;
			if(result.equalsIgnoreCase('true')) return true;
			return false;
		}
		public List<String> getFilterValue(String textContent){
			List<String> filterValues = new List<String>();
//system.debug(logginglevel.info,'textContent:::' + textContent);
//system.debug('emailTag:::' + emailTag);
			List<String> chkContent = splitContent(textContent,emailTag);
//system.debug(logginglevel.info,'chkContent:::' + chkContent);
			//String value = '';
			if(!chkContent.isEmpty()){
				for (String processContent : chkContent) {
//system.debug(logginglevel.info,'processContent:::' + processContent);
					List<String> begContentLst = afterContent(processContent,emailTagBegKey);
					for (String begContent : begContentLst) {
//system.debug(logginglevel.info,'begContent:::' + begContent);
						List<String> afterContentLst = beforeContent(begContent,emailTagEndKey);
						String orgText = '';
						for (String content : afterContentLst) {
							String curText = CommUtils.nullToBlank(formatValue(content));
							// 重复内容不进行处理
							if ( orgText != curText ) {
								//if (!CommUtils.isBlank(emailTagFormatJoinKey) && !CommUtils.isBlank(value))  value += emailTagFormatJoinKey;
								//value += curText;
//system.debug(logginglevel.info,'curText=[' + curText+']');
								filterValues.add(curText.trim());
								orgText = curText;
							}
						}
					}
				}
			}
			return filterValues;
		}
		private String formatValue(String wkStr){
			String value = '';
			// Format
			Boolean isFinded = false;
			if (!CommUtils.isBlank(emailTagFormat)) {
				String[] formatter = emailTagFormat.split(';');
				//boolean andFlag = operation == 'AND' ? true : false;
				for (String formatterStr : formatter) {
					Pattern wkPattern = Pattern.Compile(formatterStr);
					Matcher mathch = wkPattern.matcher(wkStr);
					if (mathch.find()) {
						// 転換値が存在する場合、転換値から戻る
						if (!CommUtils.isBlank(convertVal)) {
							value = convertVal;
							if(!CommUtils.isBlank(exculdeStr) && exculdeStr.contains(value)) value = '';
							//and 下 进行多次判断
							//if(andFlag && !checkLastFlag) { 
								//continue;
							//}
							return value;
						}
						wkStr = '';
						Integer size = mathch.groupCount();
						for (integer i =1; i <= size; i++) {
							wkStr += mathch.group(i);
							if (size > 1 && i < size && !CommUtils.isBlank(emailTagFormatJoinKey)) wkStr += emailTagFormatJoinKey;
						}	
						isFinded = true;
						break;
					}
				} // End For
			} else {
				isFinded = true;
			}
			if (isFinded && !CommUtils.isBlank(wkStr)) {
				value = wkStr;
				/*
				if(saveKeyFlag)
					if(forwardFlag) value = value + emailTag;
					else value = emailTag + value;
				*/
				if (!CommUtils.isBlank(exculdeStr) && exculdeStr.contains(value)) value = '';
				return CommUtils.nullToBlank(value);
			} 
			return value;
		}
		private List<String> splitContent(String textContent,String key){
			List<String> results = new List<String>();
			List<String> split = textContent.split('\n');
//system.debug('split:::' + split);
//system.debug('split1:::' + key);
			if (CommUtils.isBlank(key)) return split;
			for (String content : split) {
			    if (CommUtils.isBlank(content)) continue;
			    String endCode = content.right(1);
			    String htmlCode = endCode.escapeHtml4();
			    if (htmlCode == '&nbsp;') content = content.substring(0, (content.length()-1));
				for (String filterKey : key.split(',')) {
					if (content.indexOf(filterKey) >= 0 && !CommUtils.isBlank(filterKey)) results.add(content + '\n');
				}
			}
			return results;//chkContent(textContent,key,true,PROCEE_TYPE.SPLIT);
		}
		private List<String> afterContent(String textContent,String key){
//system.debug(logginglevel.info,'saveKeyFlag:::' + saveKeyFlag);
			return chkContent(textContent,key,PROCEE_TYPE.AFTER);
		}
		private List<String> beforeContent(String textContent,String key){
			return chkContent(textContent,key,PROCEE_TYPE.BEFORE);
		} 
		private List<String> chkContent(String textContent,String key,PROCEE_TYPE forwardType){
			List<String> contentLst = new List<String>();
			if (CommUtils.isBlank(key)) return new List<String>{textContent};
//system.debug(logginglevel.info,'isSaveKey:::' + isSaveKey);
			List<String> processLst = getFilterContent(textContent,key,forwardType);
//system.debug('processLst::::' + processLst);	
			if (!processLst.isEmpty()) contentLst.addAll(processLst);
			for (String searchKey : key.deletewhitespace().split(',')) {
				if (key == searchKey) continue;
				processLst = getFilterContent(textContent,searchKey,forwardType);
//system.debug('processLst::::' + processLst);
				if (!processLst.isEmpty()) contentLst.addAll(processLst);
			}
//system.debug(contentLst);
			return contentLst;
		}
		private List<String> getFilterContent(String nextContent,String key,PROCEE_TYPE forwardType) {
			List<String> splitContent = new List<String>();
			String curContent = nextContent;
			if (!CommUtils.isBlank(key)) {
				if (!key.equals('\\n')) {
                    if (nextContent.indexOf(key) < 0) return splitContent; 
                }
				if (forwardType == PROCEE_TYPE.BEFORE) {
					curContent = nextContent.subStringBefore(key);
					if (endSaveKeyFlag) curContent += key;
				} else {
					curContent = nextContent.subStringAfter(key);
					if (saveKeyFlag) curContent = key + curContent;
				}
			}
			splitContent.add(curContent); 
			return splitContent;
		}
	}
  // 2016/06/20 end
  	// 2019/06/15 新規予約を部屋ごとに時間と到着日をデフォルト設定 BY zyz BEGIN
  	public static String getNewWindowLeadFieldDefValue(String docName,String spcd,Map<String,String> defPopupWinMap){
	  	String result = '';
		try{
			Dom.XmlNode targetNode = CommXmlUtils.parseXmlDoc(docName,spcd);
	   		Dom.XmlNode rtNode = targetNode.getChildElement('DEFROOMTYPE',null);
	   		Map<String, Schema.DescribeFieldResult> modelDeafaultValuesMap = CommSqlUtils.getAllFieldLst(Lead__c.sObjectType,true,true);
	   		if (rtNode != null) {
	   			// 检索房型的seq集合
	   			set<Decimal> seqSet = new set<Decimal>();
	   			// key：seq，value：对应值
				map<Decimal,list<RequestField>> defItemMap = new map<Decimal,list<RequestField>>();
				// 循环DEFVALUES层
				for(Dom.XmlNode seqNode : rtNode.getChildElements()){
					// 取得设定的seq
					String seqStr = CommUtils.nullToblank(seqNode.getAttribute('SEQ',null));
					if(!CommUtils.isBlank(seqStr)){
						for(String s : seqStr.split(',')){
							// 处理seq的值
							if (seqSet.contains(CommUtils.nullToZero(s))) continue;
							seqSet.add(CommUtils.nullToZero(s));
							// 一个房型下定义的所有数据存储
							list<RequestField> defItemLst = new list<RequestField>();
							// 循环DEFINE层
							for(Dom.XmlNode apiNode : seqNode.getChildElements()){
								// 获取字段的API
								Dom.XmlNode apiNameNode = apiNode.getChildElement('APINAME', null);
								if(apiNameNode == null) continue;
								String apiName = CommUtils.nullToblank(apiNameNode.getText());
								Schema.DescribeFieldResult dr = modelDeafaultValuesMap.get(apiName.toLowerCase());
								// 字段无效且map内不存在
								if (dr == null && !defPopupWinMap.containsKey(apiName)) continue;
								String fieldName = '';
								// 特殊字段api取得
								if (defPopupWinMap.containsKey(apiName)) fieldName = defPopupWinMap.get(apiName);
								else if (dr != null) {
									// 参照字段去除
									if (dr.getType() == Schema.DisplayType.REFERENCE) continue;
									// 不使用getName原因是，对应的API字段可能带着"ps__"
									//fieldName = dr.getName();
									fieldName = dr.getLocalName();
								}
								// 获取字段对应的默认值
								Dom.XmlNode apiValNode = apiNode.getChildElement('DEFVALUE', null);
								String apiVal = '';
								if(apiValNode != null) apiVal = CommUtils.nullToblank(apiValNode.getText());
								// 数据
								RequestField field = new RequestField(fieldName,apiVal);
								defItemLst.add(field);
							}
							defItemMap.put(CommUtils.nullToZero(s),defItemLst);
						}
					}
				}
				if(!seqSet.isEmpty() && !defItemMap.isEmpty()){
					// 根据seq检索数据值
					list<TypeOfRooms__c> TypeOfRooms = [select Id,Name,seq__c from TypeOfRooms__c where seq__c in: seqSet];
					map<String,list<RequestField>> leadTimeMaps = new map<String,list<RequestField>>();
					for(TypeOfRooms__c rt : TypeOfRooms){
						// key:房型id，value：对应集合
						leadTimeMaps.put(rt.Id,defItemMap.get(rt.seq__c));
					}
					result = JSON.serialize(leadTimeMaps);
				}
			}
	    } catch(Exception e){}
	    return result;
	}
  	public class RequestField{
	    public String nm;		// 字段API
	    public String val;		// 字段值
	    public RequestField(String aName,String aValue){
	    	nm = CommUtils.nullToBlank(aName);
	    	val = CommUtils.nullToBlank(aValue);
	    }
	}
	// 2019/06/15 新規予約を部屋ごとに時間と到着日をデフォルト設定 BY zyz END	
}