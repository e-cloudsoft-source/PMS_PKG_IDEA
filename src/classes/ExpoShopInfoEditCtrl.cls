public with sharing class ExpoShopInfoEditCtrl extends ExpoCommBaseCtrl{
	public String parentDsJson{get;set;} // 级联主DATA
	public String childDsJson{get;set;} // 级联子DATA
	public ExpoHelperUtil.ExpoFieldInfo expo{get;set;} // 所有数据集
	public String dataId{get{ return CommUtils.nullToBlank( ApexPages.currentPage().getParameters().get('Id') ); }}
	// *配置API必须小写* 固定标准必填字段
	private static final set<String> fieldReqSet = new set<String>{'name', 'address__c'};
	// *配置API必须小写* 固定只读字段
	private static final set<String> fieldRomSet = new set<String>{'expoorginforef__c'};
	// *配置API必须小写* 固定不显示字段
	private static final set<String> fieldNotSet = new set<String>{'id','shopcode__c'};
	// XML为空时,默认显示 版块Key
	private static List<String> defOrderLst = new List<String>{'0'}; // 版块顺序
	// Key=>版块Key,Val=>配置格式{ SECTION(TITLE);SECTION(列数);API1:LAB1,API2:LAB2,API3:LAB3...; }
	private static final map<String,String> defMap = new map<String,String>{'0' => '情報;1;Name,Post__c,Address__c,Phone__c,Fax__c,Email__c,WebSite__c,PayeeAcount__c,Payee1__c,Payee2__c,Payee3__c;'};
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
		// 2018/09/27 店舗情報ロゴイメージアップロード機能追加　by　zy BEGIN
		newLog = new Attachment();
		// 2018/09/27 店舗情報ロゴイメージアップロード機能追加　by　zy END
		return null;
	}
	// 获取数据集
	public void getExpoShopInfoXML(){
		expo = ExpoHelperUtil.getExpoXML('SHOPINFOFIELDS', ShopInformation__c.sObjectType, fieldReqSet, fieldRomSet, fieldNotSet);
		if(expo.custApiSet.isEmpty()){
			expo = ExpoHelperUtil.getExpoDef(defOrderLst, defMap, ShopInformation__c.sObjectType, fieldReqSet, fieldRomSet, fieldNotSet);
		}
		/*
		// 级联字段特殊处理
		parentDsJson = childDsJson = '[]';
		if(expo.custApiSet.contains('demomin__c') && expo.custApiSet.contains('democ__c') ){
			ExpoHelperUtil.KendoDataSourceAll kendo = ExpoHelperUtil.getDependentOptions('ShopInformation__c', 'DemoMin__c', 'DemoC__c');
			parentDsJson = JSON.serialize(kendo.parentKendoDs);
			childDsJson = JSON.serialize(kendo.childKendoDs);
			expo.custFieldInfoMap.get('demomin__c').fieldTyp = ExpoHelperUtil.API_TYPE.CPLST.name();
			expo.custFieldInfoMap.get('democ__c').fieldTyp = ExpoHelperUtil.API_TYPE.CPLST.name();
		}
		*/
		if(CommUtils.isBlank(dataId)){
			try{
				expo.custFieldInfoMap.get('expoorginforef__c').fieldVal = currentUser.ExpoOrgInfoRef__r.Name;
			}catch(Exception e){}
			return;
		}
		String queryStr = ' Select ';
		// 合成有效api
		for(String api : expo.custApiSet) queryStr += api + ',' ;
		queryStr = queryStr.removeEnd(',');
		queryStr += ' From ShopInformation__c Where Id =: dataId ';
		for(ShopInformation__c s : DataBase.query(queryStr)){
			// expoorginforef__r.name =>共通里已经处理过__r.name *PS：__r.xx   其它字段得 expo.custApiSet.add(xx);
			ExpoHelperUtil.setApiVal(s, expo, new Map<String, String>{'expoorginforef__c' => 'expoorginforef__r.name'});
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
	public static String saveInfo(String dataId, String fieldJson, String expoOrgInfoRef){
		ShopInformation__c shpoItem = new ShopInformation__c();
		if(!CommUtils.isBlank(expoOrgInfoRef)) shpoItem.ExpoOrgInfoRef__c = expoOrgInfoRef;
		return ExpoHelperUtil.saveInfo(dataId, fieldJson, shpoItem);
	}
	// 2018/09/27 店舗情報ロゴイメージアップロード機能追加　by　zy BEGIN
	public Attachment newLog{get;set;}
	// ロゴ保存
	public PageReference saveLogo(){
		// 2019/09/19 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'contenttype','parentid','name'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.Attachment.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
			return null;
		}
		// 2019/09/19 Security Check BY zyz END
		// 店舗情報取得
		ShopInformation__c shop = getShopInfoById(dataId);
		if (shop != null) {
			// ロゴイメージ名
			newLog.name = ExpoCommonConst.getShopCodeLogoName(shop.shopCode__c);
			// 
			List<Attachment> rsAtt = [select Name,Body,ParentId from attachment where parentId = :dataId and name = :newLog.name];
			// 既存ロゴ
			if (!rsAtt.isEmpty()) newLog.id = rsAtt[0].id;
			// 新規ロゴ
			else {
				newLog.parentid = dataId;
				newLog.ContentType = 'application/jpg';
			}
			upsert newLog;
			// 該当店舗レポートロゴ
			//ReportLogo__c logo = ExpoNoAuthHelp.getReportTitleInfo(shop.ShopCode__c);
			//logo.ReportLogo__c = '<img alt="ユーザが追加した画像" src=\"/servlet/servlet.FileDownload?file=' + newLog.id +'" target="_blank" rel="nofollow"></img>';
			//if (CommUtils.isBlank(logo.id)) {
				//logo.ShopInfoRef__c = dataId;
			//}
			// 情報更新です
			//upsert logo;
			PageReference pg = Page.ExpoShopInfoEdit;
			pg.getParameters().put('sid',sessionId);
			pg.getParameters().put('Id',dataId);
			return pg;
		}
		return null;
	}
	// 店舗情報取得
	private ShopInformation__c getShopInfoById(String shopId){
		// 初期化
		ShopInformation__c shop = null;
		// 店舗リスト
		List<ShopInformation__c> shops = [select id,shopcode__c from ShopInformation__c where id = :dataId];
		if (!shops.isEmpty()) shop = shops[0];
		return shop;
	}
	// 該当店舗ロゴ取得
	public ReportLogo__c getSpcdLog() {
		ShopInformation__c shop = getShopInfoById(dataId);
		String spcd = null;
		if (shop != null) spcd = shop.ShopCode__c;
        return ExpoNoAuthHelp.getReportTitleInfo(spcd);
    }
    // 2018/09/27 店舗情報ロゴイメージアップロード機能追加　by　zy END
}