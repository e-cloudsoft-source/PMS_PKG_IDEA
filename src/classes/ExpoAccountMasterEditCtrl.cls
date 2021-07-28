public with sharing class ExpoAccountMasterEditCtrl extends ExpoCommBaseCtrl{
	private static final String APPOTION_NAMESPACE = CommConst.APPOTION_NAMESPACE;
	public String parentDsJson{get;set;} // 级联主DATA
	public String childDsJson{get;set;} // 级联子DATA
	public AccountMaster__c accMaster{get;set;} //会计商品
	public ExpoHelperUtil.ExpoFieldInfo expo{get;set;}	// 返回数据
	public String dataId{get;set;}
	// *配置API必须小写* 固定标准必填字段
	private static final set<String> fieldReqSet = new set<String>{'name','displaydate__c','category__c','categorysub__c','shopinforef__c','field5__c','expostockcount__c','shippingdays__c','paytype__c','deliverytype__c'};
	// *配置API必须小写* 固定只读字段
	private static final set<String> fieldRomSet = new set<String>{};
	// *配置API必须小写* 固定不显示字段
	// 2019/04/03 TEST[LOOKUP] WGCH BEGIN
	private static final set<String> fieldNotSet = new set<String>{'id','cookcount__c','expoorginforef__c', 'expoareamstcode__c'};
	// 2019/04/03 TEST[LOOKUP] WGCH END
	// XML为空时,默认显示 版块Key
	private static List<String> defOrderLst = new List<String>{'0','1','2','3','4','5'}; // 版块顺序
	private static map<String,String> defMap = new map<String,String>{'0' => '商品基本;2;Name,Field7__c,DisplayDate__c,jmstRef__c:消費税,Category__c,ServiceRate__c:サービス料,CategorySub__c,ShopInfoRef__c,Field5__c,ExpoStockCount__c:在庫,Charge__c,SalesStatus__c,ShippingDays__c,$_blank_$,PayType__c:決済方法,$_blank_$,DeliveryType__c;','1' => 'EXPO基本情報;1;SpDescription__c,Description__c,Content__c,Material__c,Origin__c,BestDateInfo__c,SpecialMemo__c, PurchaseMaxNum__c;','2' => '定期購入;2;RepeaterFlg__c,RepeatDiscountPrice__c,DiscountType__c,RepeatDiscountRate__c;','3' => '商品フラグ;1;LimitedFlg__c,ProductStatus__c:商品状態,OutsourceFlg__c,GoodFlg__c;','4' => '人材;1;StaffName__c,WorkRole__c,ExpoHrInfoRef__c,WorkContent__c;','5' => '地域;1;ExpoAreaMstLab__c;'};
	// DOUBLE类型的数据的格式
	public String getNumberFormat() {
		return CommUtils.getNumberFormat();
	}
	public ExpoAccountMasterEditCtrl(){
		accMaster = new AccountMaster__c();
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
		
		// 获取会计商品ID
		dataId = Apexpages.currentpage().getparameters().get('Id');
		// 页面显示的数据处理
		getExpoShopInfoXML();
		return null;
	}
	// 获取数据集
	public void getExpoShopInfoXML(){
		expo = ExpoHelperUtil.getExpoXML('ACCMASTERFIELDS', AccountMaster__c.sObjectType, fieldReqSet, fieldRomSet, fieldNotSet);
		if(expo.custApiSet.isEmpty()){
			expo = ExpoHelperUtil.getExpoDef(defOrderLst, defMap, AccountMaster__c.sObjectType, fieldReqSet, fieldRomSet, fieldNotSet);
		}
		// 级联字段特殊处理
		parentDsJson = childDsJson = '[]';
		if(expo.custApiSet.contains('category__c') && expo.custApiSet.contains('categorysub__c') ){
			ExpoHelperUtil.KendoDataSourceAll kendo = ExpoHelperUtil.getDependentOptions(APPOTION_NAMESPACE + 'AccountMaster__c', APPOTION_NAMESPACE + 'Category__c', APPOTION_NAMESPACE + 'CategorySub__c');
			parentDsJson = JSON.serialize(kendo.parentKendoDs);
			childDsJson = JSON.serialize(kendo.childKendoDs);
			expo.custFieldInfoMap.get('category__c').fieldTyp = ExpoHelperUtil.API_TYPE.CPLST.name();
			expo.custFieldInfoMap.get('categorysub__c').fieldTyp = ExpoHelperUtil.API_TYPE.CPLST.name();
		}
		if (!CommUtils.isBlank(dataId)){
			// 2019/04/03 TEST[LOOKUP] WGCH BEGIN
			String queryStr = ' Select ExpoAreaMstCode__c, ';
			// 2019/04/03 TEST[LOOKUP] WGCH END
			for(String api : expo.custApiSet) queryStr += api + ',' ;
			queryStr = queryStr.removeEnd(',');
			queryStr += ' From AccountMaster__c Where Id =: dataId ';
			accMaster = DataBase.query(queryStr);
			ExpoHelperUtil.setApiVal(accMaster, expo);
		}
	}
	// 参照字段のデータ取得する
	@remoteaction 
	public static List<ExpoHelperUtil.KendoDataSource> getRefDs(String ref,String ExpoInfoRef){
		String querySQL = 'select id,name ';
		if(ref == (APPOTION_NAMESPACE + 'jmst__c')) querySQL += ' ,TaxRate__c ';
		querySQL += ' from ' + ref;
		if((ref == (APPOTION_NAMESPACE +'shopinformation__c') || ref == (APPOTION_NAMESPACE + 'expouser__c')) && !CommUtils.isBlank(ExpoInfoRef)) querySQL += ' where ExpoOrgInfoRef__c =: ExpoInfoRef order by name';
		List<ExpoHelperUtil.KendoDataSource> selectOptionDsLst = new List<ExpoHelperUtil.KendoDataSource>{new ExpoHelperUtil.KendoDataSource('', '')};
		for (Sobject s : Database.query(querySQL)) {
			String textStr = CommUtils.nullToBlank(s.get('id'));
			String valueStr = CommUtils.nullToBlank(s.get('name'));
			if(ref == (APPOTION_NAMESPACE + 'jmst__c')) valueStr = Integer.valueOf(CommUtils.nullToZero(s.get('TaxRate__c')))+'%';
			selectOptionDsLst.add(new ExpoHelperUtil.KendoDataSource(valueStr, textStr));
		}
		return selectOptionDsLst;
	}
	// 保存
	@remoteaction 
	public static String saveInfo(String dataId, String fieldJson, String expoOrgInfoRef){
		AccountMaster__c accMasterItem = new AccountMaster__c();
		if(!CommUtils.isBlank(expoOrgInfoRef)) accMasterItem.ExpoOrgInfoRef__c = expoOrgInfoRef;
		return ExpoHelperUtil.saveInfo(dataId, fieldJson, accMasterItem);
	}
	
}