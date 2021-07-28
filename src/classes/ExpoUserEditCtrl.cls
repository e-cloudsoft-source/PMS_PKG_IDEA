public with sharing class ExpoUserEditCtrl extends ExpoCommBaseCtrl{
	public String parentDsJson{get;set;} // 级联主DATA
	public String childDsJson{get;set;} // 级联子DATA
	public ExpoHelperUtil.ExpoFieldInfo expo{get;set;} // 所有数据集
	public String dataId{get{ return CommUtils.nullToBlank( ApexPages.currentPage().getParameters().get('Id') ); }}
	// *配置API必须小写* 固定标准必填字段
	private static final set<String> fieldReqSet = new set<String>{'name','email__c','shopcode__c'};
	// *配置API必须小写* 固定只读字段
	private static set<String> fieldRomSet = new set<String>{'username__c'};
	// *配置API必须小写* 固定不显示字段
	private static set<String> fieldNotSet = new set<String>{'id','expoorginforef__c','tokenid__c','password__c','changepasswordflg__c','administratorflg__c'};
	// XML为空时,默认显示 版块Key
	private static List<String> defOrderLst = new List<String>{'0'}; // 版块顺序
	// Key=>版块Key,Val=>配置格式{ SECTION(TITLE);SECTION(列数);API1:LAB1,API2:LAB2,API3:LAB3...; }
	private static final map<String,String> defMap = new map<String,String>{'0' => '情報;1;UserName__c,Name,Email__c,Phone__c,Fax__c,ShopCode__c,isactive__c;'};
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
		if(CommUtils.isBlank(dataId)) fieldRomSet.remove('username__c');
		expo = ExpoHelperUtil.getExpoXML('USERINFOFIELDS', ExpoUser__c.sObjectType, fieldReqSet, fieldRomSet, fieldNotSet);
		if(expo.custApiSet.isEmpty()){
			expo = ExpoHelperUtil.getExpoDef(defOrderLst, defMap, ExpoUser__c.sObjectType, fieldReqSet, fieldRomSet, fieldNotSet);
		}
		// 级联字段特殊处理
		/*parentDsJson = childDsJson = '[]';
		if(expo.custApiSet.contains('demomin__c') && expo.custApiSet.contains('democ__c') ){
			ExpoHelperUtil.KendoDataSourceAll kendo = ExpoHelperUtil.getDependentOptions('ExpoUser__c', 'DemoMin__c', 'DemoC__c');
			parentDsJson = JSON.serialize(kendo.parentKendoDs);
			childDsJson = JSON.serialize(kendo.childKendoDs);
			expo.custFieldInfoMap.get('demomin__c').fieldTyp = ExpoHelperUtil.API_TYPE.CPLST.name();
			expo.custFieldInfoMap.get('democ__c').fieldTyp = ExpoHelperUtil.API_TYPE.CPLST.name();
		}*/
		if(CommUtils.isBlank(dataId)){
			setShopCode(currentUser.ExpoOrgInfoRef__c);
			setIsactiveDefault();
			return;
		}
		expo.custApiSet.add('expoorginforef__c'); // 防止未查询
		String queryStr = ' Select ';
		// 合成有效api
		for(String api : expo.custApiSet) queryStr += api + ',' ;
		queryStr = queryStr.removeEnd(',');
		queryStr += ' From ExpoUser__c Where Id =: dataId ';
		List<ExpoUser__c> userLst = DataBase.query(queryStr);
		for(ExpoUser__c s : userLst){
			ExpoHelperUtil.setApiVal(s, expo);
		}
		setShopCode(userLst[0].ExpoOrgInfoRef__c);
	}
	
	private void setIsactiveDefault(){
		ExpoHelperUtil.FieldInfo field = expo.custFieldInfoMap.get('isactive__c');
		if(field != null) field.fieldVal = 'true';
	}
	
	private void setShopCode(String expoOrgInfoRef){
		// 店铺Code特殊处理
		if(expo.custFieldInfoMap.containsKey('shopcode__c')){
			ExpoHelperUtil.FieldInfo field = expo.custFieldInfoMap.get('shopcode__c');
			field.fieldLab = '店舗';
			field.fieldTyp = ExpoHelperUtil.API_TYPE.PLST.name();
			for(ShopInformation__c sp : [Select Id, Name, shopCode__c From ShopInformation__c where ExpoOrgInfoRef__c =: expoOrgInfoRef order by name]){
				field.fieldPLst.add(new SelectOption(CommUtils.nullToBlank(sp.shopCode__c), CommUtils.nullToBlank(sp.Name)));
			}
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
	// 判断User重复
	@remoteaction 
	public static Boolean checkUserName(String userName){
		return ([Select Id From ExpoUser__c where UserName__c =:userName].isEmpty());
	}
	// 保存处理
	@remoteaction
	public static String saveInfo(String dataId, String fieldJson, String expoOrgInfoRef){
		ExpoUser__c user = new ExpoUser__c();
		if(CommUtils.isBlank(expoOrgInfoRef)) user.ExpoOrgInfoRef__c = expoOrgInfoRef;
		return ExpoHelperUtil.saveInfo(dataId, fieldJson, new ExpoUser__c(ExpoOrgInfoRef__c = expoOrgInfoRef));
	}
	// 2018/10/06 システムロゴ情報を取得する WSQ BEGIN
	public String getLogoUrl() {
		return ExpoNoAuthHelp.getLogoUrl();
	}
	// 2018/10/06 システムロゴ情報を取得する WSQ END
}