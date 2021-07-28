/**
* 取引先関連情報検索を行う
* 2019/03/19 性能改善対応
**/
public with sharing class ExpoLookupCtrl extends CommBaseCtrl{
	public enum SEARCH_MODE{NAME,ALL}
	// 检索 取引先名
	public String queryName{get; set;}
	// 页面 title
	public String sObjectTitle{get; set;}
	// 判断根据name字段还是多个字段检索
	public String searchMode{get; set;}
	// 改ページ機能対応
	public PaginationUtil pageCtrl{get; set;}
	// 数据集合
	public List<SObjectInfo> sObjectInfoLst{get; set;}
	// 字段集合
	public List<ExpoHelperUtil.FieldInfo> fieldInfoLst{get; set;}
	// 检索表名
	private String sObjectName;
	// 检索表名
	private String sObjectPrefix;
	// sessionId
	private String sessionId;
	// 遷移先からパラメータ情報を格納する
	private static Map<String,String> paramMap;
	// 初期化
	public void init() {
		searchMode = SEARCH_MODE.NAME.name();
		paramMap = Apexpages.currentPage().getParameters();
		queryName = CommUtils.nullToBlank(paramMap.get('lksrch'));
		sObjectPrefix = CommUtils.nullToBlank(paramMap.get('prefix')); // url传过来
		sessionId = CommUtils.nullToBlank(paramMap.get('sid'));
		// 取引先検索を行う
		queryInfo();  
	}
	// キャンセル処理
	public void cancelAct() {
		this.queryInfo();
	}
	// 初期化処理呼び出す
	public void queryInfo(){
		Schema.DescribeSobjectResult result = ExpoHelperUtil.findObjectFromRecordIdPrefix(sObjectPrefix);
		if(result == null) return;
		sObjectName = result.getName();
		Map<String, Schema.DescribeFieldResult> modeDefValMaps = CommSqlUtils.getAllFieldLst(result.getSobjectType(),false,true);
		List<String> apiLst = getLookUpXmlInfo(modeDefValMaps);
		if(CommUtils.isBlank(sObjectTitle)) sObjectTitle = result.getLabel();
		// 画面ページステータス設定を行う
		if(!preQueryInfo()) return;
		String custApiQueryStr = String.join(apiLst, ',');
		// sid反查处理
		ExpoUser__c currentUser = new ExpoUser__c();
		if (!CommUtils.isBlank(sessionId)) {
			List<ExpoSession__c> sessions = [SELECT Id, ExpoUserRef__c, ExpireDT__c, SessionId__c FROM ExpoSession__c WHERE SessionId__c = :sessionId];
			if (!sessions.isEmpty()) {
				ExpoSession__c session = sessions[0];
				if (session.ExpireDT__c >= DateTime.now()) {
					List<ExpoUser__c> users = [SELECT Id, Name, UserName__c, Email__c, Fax__c, Phone__c, ShopCode__c, ExpoOrgInfoRef__c, ExpoOrgInfoRef__r.Name FROM ExpoUser__c WHERE Id = :session.ExpoUserRef__c];
					if (users.size() == 1) {
						currentUser = users[0];
					}
				}
			}
		}
		// where
		String expoOrgInfoId = CommUtils.nullToBlank(currentUser.ExpoOrgInfoRef__c);
		String queryWhere = '';
		if(!CommUtils.isBlank(expoOrgInfoId)) queryWhere += ' Where ExpoOrgInfoRef__c =: expoOrgInfoId ';
		String queryStr = ' Select ' + custApiQueryStr + ' From ' + sObjectName + queryWhere + ' order by LastModifiedDate desc NULLS LAST limit 10';
		String findKey = CommSqlUtils.escapeSOSLTerm(queryName);
		String wkSearchMode = 'NAME';
		if(searchMode == SEARCH_MODE.ALL.name()) wkSearchMode = 'ALL';
		List<Sobject> oAccountLst = new List<Sobject>();
		if(!CommUtils.isBlank(findKey)){
			// limit200
			queryStr = 'FIND :findKey IN ' + wkSearchMode + ' FIELDS RETURNING ' + sObjectName + '( ' + custApiQueryStr + queryWhere + ' Order by LastModifiedDate desc NULLS LAST)';
			List<List<Sobject>> sObjectLstAll = Search.query(queryStr);
			if(!sObjectLstAll.isEmpty()) oAccountLst = sObjectLstAll[0];
		} else oAccountLst = Database.query(queryStr);
		// 画面に表示する情報を格納用変数
		pageCtrl = new PaginationUtil(oAccountLst,100);
		// 該当画面に表示する明細情報を取得、設定する
		queryAccountDetailInfo();
	}
	// 検索前の有効性チェック
	private boolean preQueryInfo() {
		String findKey = CommUtils.nullToBlank(queryName).replaceAll('[\\?&\\|!{}\\[\\]\\(\\)\\^~\\*:\\\"\\+-]','');
		// キーワード入力あり　かつ　該当キーワードから特殊な文字以外は２桁以下の場合
		if (!CommUtils.isBlank(CommUtils.nullToBlank(queryName)) && (findKey.length() < 2)) {
			//フリーワード検索文字は最低 2 文字指定してください。
			Apexpages.addMessage(new Apexpages.Message(ApexPages.severity.ERROR, Label.MSG_009_0037));
			return false;
		}
		return true;
	}
	public void firstPage() {
		pageCtrl.firstPage();
		queryAccountDetailInfo();
	}
	public void previousPage() {
		pageCtrl.previousPage();
		queryAccountDetailInfo();
	}
	public void nextPage() {
		pageCtrl.nextPage();
		queryAccountDetailInfo();
	}
	public void lastPage() {
		pageCtrl.lastPage();
		queryAccountDetailInfo();
	}
	// 指摘の取引先IDで詳細情報を再取得を行う
	private void queryAccountDetailInfo() {
		sObjectInfoLst = new List<SObjectInfo>();
		for(Sobject s : pageCtrl.records){
			SObjectInfo sObjectItem = new SObjectInfo(s);
			for(ExpoHelperUtil.FieldInfo field : fieldInfoLst){
				ExpoHelperUtil.FieldInfo cField = field.clone();
				cField.fieldVal = CommUtils.nullToBlank(ExpoHelperUtil.getValueByApi(s, cField.fieldApi));
				sObjectItem.fieldInfoLst.add(cField);
			}
			sObjectInfoLst.add(sObjectItem);
		}
	}
	private List<String> getLookUpXmlInfo(Map<String, Schema.DescribeFieldResult> modeDefValMaps){
		fieldInfoLst = new List<ExpoHelperUtil.FieldInfo>();
		String wkName = 'name';
		if(modeDefValMaps.containsKey(wkName)) fieldInfoLst.add(new ExpoHelperUtil.FieldInfo(wkName, new Map<String, String>{wkName => ''}, modeDefValMaps.get(wkName)));
		List<String> custApiLst = new List<String>{'id', wkName};
		// XML定义的获取处理
		Dom.XmlNode targetNode = CommXmlUtils.parseXmlDoc('ExpoServiceConfig', '');
		if (targetNode == null) return custApiLst;
		// 店舗情報はＸＭＬから取得する
		Dom.XmlNode lookUpNode = targetNode.getChildElement('LOOKUPLAYOUT', null);
		if(lookUpNode != null){ // 当前mode的定义信息
			for (Dom.Xmlnode pageNode : lookUpNode.getChildElements()) {
				if(pageNode.getName() != 'LAYOUT') continue;
				Dom.XmlNode sObjectNodes = pageNode.getChildElement('SOBJECT', null);
				if(sObjectNodes != null){ // 自定义表名
					String[] sObjectLst = CommUtils.nullToBlank(sObjectNodes.getText()).split(':');
					if(sObjectLst.isEmpty()) return custApiLst;
					String wkSOjectName = CommUtils.nullToBlank(sObjectLst[0]).toLowerCase();
					if(wkSOjectName != CommUtils.nullToBlank(sObjectName).toLowerCase()) return custApiLst;
					if(sObjectLst.size() > 1) sObjectTitle = CommUtils.nullToBlank(sObjectLst[1]);
				}
				Dom.XmlNode fieldsNodes = pageNode.getChildElement('FIELDS', null);
				if(fieldsNodes != null){ // 当前mode的定义信息
					for(String field : CommUtils.nullToBlank(fieldsNodes.getText()).split(',')){ // API转成小写
						String[] apiInfoSplit = field.split(':');
						if(apiInfoSplit.isEmpty()) continue;
						String api = CommUtils.nullToBlank(apiInfoSplit[0]).toLowerCase(); // 对应字段的API转成小写
						String lab = apiInfoSplit.size() > 1 ? CommUtils.nullToBlank(apiInfoSplit[1]) : ''; // 对应字段的名
						// 不符合条件的API过滤掉处理
						if(CommUtils.isBlank(api) || !modeDefValMaps.containsKey(api) || custApiLst.contains(api)) continue;
						custApiLst.add(api);
						Schema.DescribeFieldResult dr = modeDefValMaps.get(api);
						fieldInfoLst.add(new ExpoHelperUtil.FieldInfo(api, new Map<String, String>{api => lab}, dr));
					}
				}
			}
		}
		return custApiLst;
	}
	public class SObjectInfo{
		public SObjectInfo(Sobject s){
			sId = CommUtils.nullToBlank(s.get('id'));
			sNm = CommUtils.nullToBlank(s.get('name'));
			lab = 'Name';
			fieldInfoLst = new List<ExpoHelperUtil.FieldInfo>();
		}
		public String sId{get; set;}
		public String sNm{get; set;}
		public String lab{get; set;}
		public List<ExpoHelperUtil.FieldInfo> fieldInfoLst{get; set;}
	}
}