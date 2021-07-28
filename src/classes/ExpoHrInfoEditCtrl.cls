public with sharing class ExpoHrInfoEditCtrl extends ExpoCommBaseCtrl{
    private static final String APPOTION_NAMESPACE = CommConst.APPOTION_NAMESPACE;
	public String parentDsJson{get;set;} // 级联主DATA
	public String childDsJson{get;set;} // 级联子DATA1
	public String childDsJsons{get;set;} // 级联子DATA2
	public ExpoHrInfo__c accMaster{get;set;} //会计商品
	public ExpoHelperUtil.ExpoFieldInfo expo{get;set;}	// 返回数据
	public String dataId{get;set;}
	// *配置API必须小写* 固定标准必填字段
	private static final set<String> fieldReqSet = new set<String>{'name'};
	// *配置API必须小写* 固定只读字段
	private static final set<String> fieldRomSet = new set<String>{};
	// *配置API必须小写* 固定不显示字段
	private static final set<String> fieldNotSet = new set<String>{'id','expoorginforef__c'};
	// XML为空时,默认显示 版块Key
	private static List<String> defOrderLst = new List<String>{'0','1','2'}; // 版块顺序
	//private static map<String,String> defMap = new map<String,String>{'0' => '人材情報の詳細;2;Name,ExpoDayWorkBegTimeLst__c,ExpoDispatchScopeLst__c	,ExpoDayWorkEndTimeLst__c ,ExpoWeekWorkDaysLst__c ,ExpoOvertimeWorkHourLst__c ,WorkPayType__c ,$_blank_$ ,ExpoMinPayLst__c ,$_blank_$ ,ExpoMaxPayLst__c;','1' => 'スキル・経験;1;ExpoOaSkillLst__c::line,ExpoEngSkillLst__c::line,ExpoOthLangSkillLst__c::line, ExpoAccSkillLst__c::line,ExpoLicSkillLst__c::line,ExpoHrOtherLst__c::line;'};
	private static map<String,String> defMap = new map<String,String>{'0' => '人材情報の詳細;1;ExpoDispatchScopeLst__c,ExpoWeekWorkDaysLst__c,WorkPayType__c	,ExpoMinPayLst__c ,ExpoMaxPayLst__c ,ExpoOvertimeWorkHourLst__c ,ExpoDayWorkBegTimeLst__c ,ExpoDayWorkEndTimeLst__c ;','1' => 'スキル・経験;1;ExpoOaSkillLst__c,ExpoEngSkillLst__c,ExpoOthLangSkillLst__c, ExpoAccSkillLst__c,ExpoLicSkillLst__c,ExpoHrOtherLst__c;'};
	// DOUBLE类型的数据的格式
	public String getNumberFormat() {
		return CommUtils.getNumberFormat();
	}
	public ExpoHrInfoEditCtrl(){
		accMaster = new ExpoHrInfo__c();
	}
	public PageReference initAct() {
		// *****************************
		// 共通処理呼び出す
		// *****************************
		PageReference pg = checkLogin();
		if (pg != null) return pg;
		// *****************************
		// 実際の業務ロジック処理展開
		// *****************************
		
		// 获取ID
		dataId = Apexpages.currentpage().getparameters().get('Id');	
		// 页面显示的数据处理
		getExpoShopInfoXML();
		return null;
	}
	// 获取数据集
	public void getExpoShopInfoXML(){
		expo = ExpoHelperUtil.getExpoXML('HRINFOFIELDS', ExpoHrInfo__c.sObjectType, fieldReqSet, fieldRomSet, fieldNotSet);
		if(expo.custApiSet.isEmpty()){
			expo = ExpoHelperUtil.getExpoDef(defOrderLst, defMap, ExpoHrInfo__c.sObjectType, fieldReqSet, fieldRomSet, fieldNotSet);
		}
		// 级联字段特殊处理
		parentDsJson = childDsJson = '[]';
		if(expo.custApiSet.contains('workpaytype__c') && expo.custApiSet.contains('expominpaylst__c')){
			ExpoHelperUtil.KendoDataSourceAll kendo = ExpoHelperUtil.getDependentOptions(APPOTION_NAMESPACE + 'ExpoHrInfo__c', APPOTION_NAMESPACE + 'WorkPayType__c', APPOTION_NAMESPACE + 'ExpoMinPayLst__c');
			parentDsJson = JSON.serialize(kendo.parentKendoDs);
			childDsJson = JSON.serialize(kendo.childKendoDs);
			expo.custFieldInfoMap.get('workpaytype__c').fieldTyp = ExpoHelperUtil.API_TYPE.CPLST.name();
			expo.custFieldInfoMap.get('expominpaylst__c').fieldTyp = ExpoHelperUtil.API_TYPE.CPLST.name();
		}
		childDsJsons = '[]';
		if(expo.custApiSet.contains('workpaytype__c') && expo.custApiSet.contains('expomaxpaylst__c') ){
			ExpoHelperUtil.KendoDataSourceAll kendo = ExpoHelperUtil.getDependentOptions(APPOTION_NAMESPACE + 'ExpoHrInfo__c', APPOTION_NAMESPACE + 'WorkPayType__c', APPOTION_NAMESPACE + 'ExpoMaxPayLst__c');
			childDsJsons = JSON.serialize(kendo.childKendoDs);
			expo.custFieldInfoMap.get('expomaxpaylst__c').fieldTyp = ExpoHelperUtil.API_TYPE.CPLST.name();
		}
		if (!CommUtils.isBlank(dataId)){
			String queryStr = ' Select ';
			for(String api : expo.custApiSet) queryStr += api + ',' ;
			queryStr = queryStr.removeEnd(',');
			queryStr += ' From ExpoHrInfo__c Where Id =: dataId ';
			List<ExpoHrInfo__c> accMasterLst = DataBase.query(queryStr);
			if (!accMasterLst.isEmpty()) {
				accMaster = accMasterLst[0];
			}
			ExpoHelperUtil.setApiVal(accMaster, expo);
		}
	}
	// 参照字段のデータ取得する
	@remoteaction 
	public static List<ExpoHelperUtil.KendoDataSource> getRefDs(String ref,String ExpoInfoRef){
		String querySQL = 'select id,name ';
		querySQL += ' from ' + ref;
		if(!CommUtils.isBlank(ExpoInfoRef)) querySQL += ' where ExpoOrgInfoRef__c =: ExpoInfoRef order by name';
		List<ExpoHelperUtil.KendoDataSource> selectOptionDsLst = new List<ExpoHelperUtil.KendoDataSource>{new ExpoHelperUtil.KendoDataSource('', '')};
		for (Sobject s : Database.query(querySQL)) {
			String textStr = CommUtils.nullToBlank(s.get('id'));
			String valueStr = CommUtils.nullToBlank(s.get('name'));
			selectOptionDsLst.add(new ExpoHelperUtil.KendoDataSource(valueStr, textStr));
		}
		return selectOptionDsLst;
	}
	// 保存
	@remoteaction 
	public static String saveInfo(String dataId, String fieldJson, String expoOrgInfoRef){
		ExpoHrInfo__c accMasterItem = new ExpoHrInfo__c();
		if(!CommUtils.isBlank(expoOrgInfoRef)) accMasterItem.ExpoOrgInfoRef__c = expoOrgInfoRef;
		return ExpoHelperUtil.saveInfo(dataId, fieldJson, accMasterItem);
	}
}