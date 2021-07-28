public with sharing class ExpoOrgInfoEditCtrl extends ExpoCommBaseCtrl{
	public String parentDsJson{get;set;} // 级联主DATA
	public String childDsJson{get;set;} // 级联子DATA
	public ExpoHelperUtil.ExpoFieldInfo expo{get;set;} // 所有数据集
	public String dataId{get{ return CommUtils.nullToBlank( currentUser.ExpoOrgInfoRef__c ); }}
	// *配置API必须小写* 固定标准必填字段
	private static final set<String> fieldReqSet = new set<String>{'name','unitpricedefkb__c'};
	// *配置API必须小写* 固定只读字段
	private static final set<String> fieldRomSet = new set<String>();
	// *配置API必须小写* 固定不显示字段
	private static final set<String> fieldNotSet = new set<String>{'id', 'contactref__c'};
	// XML为空时,默认显示 版块Key
	private static List<String> defOrderLst = new List<String>{'0'}; // 版块顺序
	// Key=>版块Key,Val=>配置格式{ SECTION(TITLE);SECTION(列数);API1:LAB1,API2:LAB2,API3:LAB3...; }
	private static final map<String,String> defMap = new map<String,String>{'0' => '情報;1;Name,Phone__c,Fax__c,PostNo__c,State__c,City__c,Street__c,Phone__c,WebSiteUrl__c,UnitPriceDefKb__c,UnitPriceDefKb__c;'};
	public PageReference initAct() {
		// *****************************
		// 共通処理呼び出す
		// *****************************
		PageReference pg = checkLogin();
		if (pg != null) return pg;
		// *****************************
		// 実際の業務ロジック処理展開
		// *****************************
		// 页面显示的数据处理
		getExpoShopInfoXML();
		return null;
	}
	// 获取数据集
	public void getExpoShopInfoXML(){
		expo = ExpoHelperUtil.getExpoXML('ORGINFOFIELDS', ExpoOrgInfo__c.sObjectType, fieldReqSet, fieldRomSet, fieldNotSet);
		if(expo.custApiSet.isEmpty()){
			expo = ExpoHelperUtil.getExpoDef(defOrderLst, defMap, ExpoOrgInfo__c.sObjectType, fieldReqSet, fieldRomSet, fieldNotSet);
		}
		// 级联字段特殊处理
		/*parentDsJson = childDsJson = '[]';
		if(expo.custApiSet.contains('demomin__c') && expo.custApiSet.contains('democ__c') ){
			ExpoHelperUtil.KendoDataSourceAll kendo = ExpoHelperUtil.getDependentOptions('ExpoOrgInfo__c', 'DemoMin__c', 'DemoC__c');
			parentDsJson = JSON.serialize(kendo.parentKendoDs);
			childDsJson = JSON.serialize(kendo.childKendoDs);
			expo.custFieldInfoMap.get('demomin__c').fieldTyp = ExpoHelperUtil.API_TYPE.CPLST.name();
			expo.custFieldInfoMap.get('democ__c').fieldTyp = ExpoHelperUtil.API_TYPE.CPLST.name();
		}*/
		if(CommUtils.isBlank(dataId)) return;
		String queryStr = ' Select ';
		// 合成有效api
		for(String api : expo.custApiSet) queryStr += api + ',' ;
		queryStr = queryStr.removeEnd(',');
		queryStr += ' From ExpoOrgInfo__c Where Id =: dataId ';
		for(ExpoOrgInfo__c s : DataBase.query(queryStr)){
			ExpoHelperUtil.setApiVal(s, expo);
		}
	}
	// 参照字段のデータ取得する
	@remoteaction 
	public static List<ExpoHelperUtil.KendoDataSource> getRefDs(String ref){
		String querySQL = 'Select Id, Name From ' + ref;
		List<ExpoHelperUtil.KendoDataSource> kendoDs = new List<ExpoHelperUtil.KendoDataSource>{new ExpoHelperUtil.KendoDataSource('', '')};
		for (Sobject s : DataBase.query(querySQL)) {
			kendoDs.add(new ExpoHelperUtil.KendoDataSource(CommUtils.nullToBlank(s.get('Name')), CommUtils.nullToBlank(s.get('Id'))));
		}
		return kendoDs;
	}
	// 保存处理
	@remoteaction
	public static String saveInfo(String dataId, String fieldJson){
		return ExpoHelperUtil.saveInfo(dataId, fieldJson, new ExpoOrgInfo__c());
	}
	
}