public with sharing class DinnerSetupCtrl {
	// 参照会計商品Id
	private String prodId;
	// 該当会計商品情報
    public AccountMaster__c accMaster{get;set;}
    // 画面用料理情報リスト
    public List<CookDetail> cookInfos{get;set;}
    // 原材料JSON
    public String materialsJson{get;set;}
    // アレルギーJSON
    public String allergyJson{get;set;}
    // 該当献立情報
    public String processJson{get;set;}
    // 料理タイプ
    public String detailJson{get;set;}
    // 店舗リスト
    public List<SelectOption> shopOpts{get;set;}
    // ユーザ情報
    private UserUtil.UserShopInfo userInf;
     // ユーザー店舗コード
    public String currentShopCode{get;set;}
    public DinnerSetupCtrl(ApexPages.StandardController controller) {
		prodId = controller.getId();
	}
	// 初期化
    public void initKaiseki(){
    	String queryStr = getQuerySQL();
    	userInf = UserUtil.CurrentUserInfo;
		queryStr += ' From AccountMaster__c where id =:prodId';
		List<AccountMaster__c> accs = DataBase.query(queryStr);
		cookInfos = new List<CookDetail>();
		// 会席タイプ
		Map<String,CookDetail> cookMap = new Map<String,CookDetail>();
        // アレルギーリスト
        allergyJson = '';
        Schema.DescribeFieldResult fieldResult = AccountMaster__c.Allergy__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<String> sendLst = new List<String>();
        for (Schema.PicklistEntry f : ple) {
        	sendLst.add(f.getValue());
        }
        allergyJson = JSON.serialize(sendLst);
        // 原材料リスト
        materialsJson = '';
        fieldResult = AccountMaster__c.Materials__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        sendLst = new List<String>();
        for (Schema.PicklistEntry f : ple) {
        	sendLst.add(f.getValue());
        }
        materialsJson = JSON.serialize(sendLst);
		if (!accs.isEmpty()) {
			accMaster = accs[0];
		}
		// 献立明細情報
		processJson = '';
		// 該当会計商品情報作成
		if (accMaster != null) {
			List<FoodDetail__c> foods = [select id,AccountMasterRef__c,AccountMasterSubRef__c,AccountMasterSubRef__r.name,DetailType__c,BreakName__c from FoodDetail__c where AccountMasterRef__c = :accMaster.id order by OrderNo__c];
			if (!foods.isEmpty()) {
				// 料理ブレイクあり
				for (FoodDetail__c food : foods) {
					String foodType = food.BreakName__c;
					if (!cookMap.containsKey(foodType)) cookMap.put(foodType,new CookDetail(foodType));
					cookMap.get(foodType).addDetail(food);
				}
			}
			processJson = getSchedultInfo(accMaster.id);
			accMaster.DisplayDate__c = System.today();
		}
		// 初期化店舗リスト
		setInitBranShopLst();
		List<String> cookLst = new List<String>();
		boolean noDataFlag = cookMap.isEmpty();
		fieldResult = FoodDetail__c.DetailType__c.getDescribe();
    	ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry f : ple) {
        	String cook = f.getValue();
        	if (noDataFlag) cookMap.put(cook,new CookDetail(cook));
        	cookLst.add(cook);
        }
		detailJson = JSON.serialize(cookLst);
		cookInfos = cookMap.values();
    }
    // 初期化店舗リスト
    private void setInitBranShopLst() {
  		// 店舗リスト情報を取得する
    	// 2015/09/01 多店舗機能対応 BEGIN
        shopOpts = ShopInfoUtil.getBranchShopLst();
        // 2015/09/01 多店舗機能対応 END
        currentShopCode = CommUtils.nullToBlank(UserUtil.CurrentUser.ShopCode__c);
    }
    // 献立情報作成方法
    private static String getSchedultInfo(String accId){
    	Date start = null;
		Date endDt = null;
		String result = '';
		Set<String> opts = new Set<String>();
		List<AccountMaster__c> details = [select id,MealInfo__c from AccountMaster__c where id = :accId];
		if (!details.isEmpty()) {
			result = details[0].MealInfo__c;
		}
		return result;
    }
    // 画面に表示項目のAPIを定義する、!!!必ず小文字に設定する!!!
	private static Set<String> defAccMasterApiSet = new Set<String>{'id','field3__c','name','field5__c','field7__c','field4__c','field4__r.name','gpchange__c','gpchange__r.name','DPChange__c','DPChange__r.name','op__c','op__r.name','materials__c','allergy__c','displaydate__c','Protein__c','Lipid__c','Carbohydrate__c','Calorie__c','CookCount__c','ShopInfoRef__r.ShopCode__c'};
	private static Map<String, Schema.DescribeFieldResult> getAllFieldLst{get{ return CommSqlUtils.getAllFieldLst(AccountMaster__c.sObjectType,false,true);}} // 获取AccountMaster__c所有字段信息
	private static String getQuerySQL(){
    	String queryStr = ' Select '; // queryStr
		for(String api : defAccMasterApiSet.clone()){ // 防止地址共存
			queryStr += api + ',';
		}
		queryStr = queryStr.removeEnd(',');
		return queryStr;
	}
    @remoteaction 
    public static Object remoteCenter(String proType,String reqInfo){
    	// 全部商品リスト取得する
    	if (proType == 'getProds') return getProds(reqInfo);
    	// 会計商品項目更新
    	else if (proType == 'updCookDetail') return updCookDetail(reqInfo);
    	else if (proType == 'updateOpts') return updateOpts(reqInfo);
    	return null;
    }
    // 全部商品リスト取得する
    private static Object getProds(String reqInfo){
    	Request req = (Request)JSON.deserialize(reqInfo,Request.class);
    	// 店舗コード情報設定を行う
        String oShopCode = UserUtil.CurrentUser.ShopCode__c;
    	// SHOP ROOT ELEMENT INFO
		Dom.XmlNode targetNode = CommXmlUtils.parseXmlDoc('BillSimpleProductConfig', oShopCode);
		// TABのNODEの情報を取得する
		Dom.XmlNode[] tabGroups =  targetNode.getChildElements();
		List<ProdInfo> prodLst = new List<ProdInfo>();
		Set<String> prodSet = new Set<String>();
		if (tabGroups != null) {
			for (Dom.XmlNode tabRoot : tabGroups) {
				/*
				// tableの共通STYLE確認
				if(tabRoot.getName().equalsIgnoreCase('TABLEWIDTH')){
					tableWidth = CommUtils.nullToBlank(tabRoot.getText()).deleteWhitespace();
					continue;
				}
				if(tabRoot.getName().equalsIgnoreCase('TABLEHEIGHT')){
					tableHeight = CommUtils.nullToBlank(tabRoot.getText()).deleteWhitespace();
					continue;
				}*/
				// TABGROUP以外の情報は処理対象外
				if (!tabRoot.getName().equalsIgnoreCase('TABGROUP')) continue;
				// Tab Group Info
				Dom.XmlNode tabelNode = tabRoot.getChildElement('TABLABEL',null);
				String labelName = '';
				if (tabelNode != null && !CommUtils.isBlank(tabelNode.getText()))
					labelName = CommUtils.nullToBlank(tabelNode.getText());
				// 該当ボタンに定義されているタブ情報
				Dom.XmlNode[] tabChildrens =  tabRoot.getChildElements();
				for (Dom.XmlNode child : tabChildrens) {
					// タグ名を取得する
					String tagName = child.getName();
					// 商品
					if (tagName.equalsIgnoreCase('PRODUCT')) {
						Dom.XmlNode prodCodeField  = child.getChildElement('CODE', null);
						if (prodCodeField == null) continue;
						String prodCode = CommUtils.nullToBlank(prodCodeField.getText()).deleteWhitespace();
						if (CommUtils.isBlank(prodCode)) continue;
						Dom.XmlNode prodNameField  = child.getChildElement('NAME', null);
						String prodName = '';
						if (prodNameField != null) prodName = CommUtils.nullToBlank(prodNameField.getText()).deleteWhitespace();
						ProdInfo prod = new ProdInfo(prodCode, prodName,labelName); 
						prodLst.add(prod);
						// 商品情報を追加する
						prodSet.add(prodCode);
					}
					/*
					// ボタンレイアウト定義情報
					else if (tagName.equalsIgnoreCase('LAYOUT')) {
						//Dom.XmlNode labelMaxLenField  = child.getChildElement('BTNWORDLEN', null);
						Dom.XmlNode btnStyleField  = child.getChildElement('BTNSTYLE', null);
						//if (labelMaxLenField != null) tabItem.layoutMaxLen = CommUtils.nullToBlank(labelMaxLenField.getText()).deleteWhitespace();
						if (btnStyleField != null) tabItem.layoutBtnStyle = CommUtils.nullToBlank(btnStyleField.getText()).deleteWhitespace();
					}
					*/
				}
			}
		}
    	String queryStr = getQuerySQL();
		queryStr += ' From AccountMaster__c where field3__c in :prodSet and CookCount__c = 0' ;
		List<AccountMaster__c> accs = DataBase.query(queryStr );
		Map<String,AccountMaster__c> accountMasterMap = new Map<String,AccountMaster__c>();
		for (AccountMaster__c acc : accs){
			accountMasterMap.put(acc.field3__c,acc);
		}
		Map<String,TabInfo> tabMap = new Map<String,TabInfo>();
		for (ProdInfo prod : prodLst) {
			if (accountMasterMap.containsKey(prod.ProdCode)) {
				AccountMaster__c acc = accountMasterMap.get(prod.ProdCode);
				prod.addAccountMaster(acc);
			}
			if (!tabMap.containsKey(prod.Catogray)) tabMap.put(prod.Catogray,new TabInfo(prod.Catogray));
			tabMap.get(prod.Catogray).addProdInfo(prod);
		}
    	return tabMap.values();
    }
    // 会計商品項目更新
    private static object updCookDetail(String reqInfo){
    	Request req = (Request)JSON.deserialize(reqInfo,Request.class);
    	Savepoint sp = Database.setSavepoint();
	  	try{
	  		AccountMaster__c acc = new AccountMaster__c();
	    	acc.id = req.prodid;
	    	// 材料とアレルギー変更あり
    		acc.Materials__c = req.materials;
    		acc.Allergy__c = req.allergys;
	    	// 栄養成分変更あり
	    	acc.Protein__c = req.pro;
	    	acc.Lipid__c = req.lip;
	    	acc.Carbohydrate__c = req.car;
	    	acc.Calorie__c = req.cal;
	    	update acc;
	    	if (req.cooks != null && !req.cooks.isEmpty()) {
	    		List<FoodDetail__c> foods = new List<FoodDetail__c>();
	    		for (integer i = 0 ; i < req.cooks.size(); i++) {
	    			Cook cook = req.cooks[i];
	    			FoodDetail__c food = new FoodDetail__c(AccountMasterRef__c = acc.id);
	    			if(!CommUtils.isBlank(cook.foodid)) food.id = cook.foodid;
	    			food.BreakName__c = cook.cooktype;
	    			if(!CommUtils.isBlank(cook.id))food.AccountMasterSubRef__c = cook.id;
	    			foods.add(food);
	    			food.OrderNo__c = i;
	    		}
	    		if (!foods.isEmpty()) upsert foods;
	    	}
	    	if (req.deleteids != null && !req.deleteids.isEmpty()) {
	    		List<FoodDetail__c> details = [select id from FoodDetail__c where id = :req.deleteids];
	    		if (!details.isEmpty()) delete details;
	    	}
	  	} catch(exception e) {
	  		Database.rollback(sp);
	  		system.debug(logginglevel.info,'error:::::' + e.getStackTraceString());
	  		throw new CommException(e.getMessage());
	  	}
    	return null;
    }
    // 頻度ありの場合
    private static Object updateOpts(String reqInfo){
    	Request req = (Request)JSON.deserialize(reqInfo,Request.class);
		Set<String> weekOptsSet = new Set<String>(req.opts);
		Date startDt = CommUtils.StringtoDate(req.start);
		Date endDt = CommUtils.StringtoDate(req.endDt);
		DateTime startDTime = DateTime.newInstance(startDt.year(), startDt.month(), startDt.day());
		DateTime endDTime = DateTime.newInstance(endDt.year(), endDt.month(), endDt.day());
		Savepoint sp = Database.setSavepoint();
	  	try{
			// 該当会計商品献立明細
			List<MealDetail__c> details = [select id,MealDateKey__c,AccountMasterRef__c,ShopCode__c from MealDetail__c where AccountMasterRef__c = :req.prodid];
			Map<String,MealDetail__c> mealMap = new Map<String,MealDetail__c>();
			for (MealDetail__c m : details) {
				String searchKey = m.AccountMasterRef__c + '_' + m.MealDateKey__c + '_' + m.ShopCode__c;
				mealMap.put(searchKey,m);
			}
			List<MealDetail__c> meals = new List<MealDetail__c>();
			while (startDTime <= endDTime) {
				String weekKey = startDTime.format('EEEE');
				if (weekOptsSet.contains(weekKey)) {
					Date configDate = startDTime.date();
					// 献立明細該当日付ありの場合
					String searchKey = req.prodid + '_' + configDate.format() + '_' + req.shops;
					// 処理なし
					if (mealMap.containsKey(searchKey)) {
						startDTime = startDTime.addDays(1);
						mealMap.remove(searchKey);
						continue;
					}
					MealDetail__c item = new MealDetail__c(
						MealDateKey__c = configDate.format(),
						AccountMasterRef__c = req.prodid,
						ShopCode__c = req.shops
					);
					meals.add(item);
				}
				startDTime = startDTime.addDays(1);
			}
			AccountMaster__c acc = new AccountMaster__c(id = req.prodid);
			acc.MealInfo__c = JSON.serialize(new SchduleInfo(req.start,req.endDt,req.opts,req.shops));
			if (!meals.isEmpty()) insert meals;
			// 無効の献立削除
			if (!mealMap.isEmpty()) delete mealMap.values();
			update acc;
		} catch(exception e) {
	  		Database.rollback(sp);
	  		throw new CommException(e.getMessage());
	  	}
		return getSchedultInfo(req.prodid);
    }
    // 画面用料理明細情報
    class CookDetail{
    	public String cookType{get;set;}
    	public List<FoodDetail__c> foods{get;set;}
    	public CookDetail(String cook){
    		cookType = cook;
    		foods = new List<FoodDetail__c>();
    	}
    	public void addDetail(FoodDetail__c food){
    		foods.add(food);
    	}
    }
    // 通信用情報
    class Request{
    	String prodid;
    	String materials;
    	String allergys;
    	List<Cook> cooks;
    	String start;
    	String endDt;
    	List<String> opts;
    	decimal pro;
    	decimal lip;
    	decimal car;
    	decimal cal;
    	String shops;
    	List<String> deleteids;
    }
    // 料理
    class Cook{
    	String id;
    	String name;
    	String cooktype;
    	String foodid;
    }
    // 会計Tab情報
    class TabInfo{
    	List<ProdInfo> prods;
    	String Catogray;
    	String orgCatogray;
    	String ProdContent;
    	public TabInfo(String cat){
    		orgCatogray = CommUtils.nullToBlank(cat);
    		ProdContent = '';
    		prods = new List<ProdInfo>();
    	}
    	public void addProdInfo(ProdInfo info){
    		prods.add(info);
    		Catogray = orgCatogray + '[' + CommUtils.nullToBlank(prods.size())  + ']';
    	}
    }
    // 会計商品情報
    class ProdInfo{
    	// 会計名
    	String ProdName;
    	// カテゴリー
    	String Catogray;
    	// 会計ID
    	String Prodid;
    	// 会計コード
    	String ProdCode;
    	// アレルギー
    	String Allergy;
    	// 原材料
    	String Materials;
    	boolean disabledFlag;
    	public ProdInfo(String code,String name,String label){
    		ProdName = name;
    		ProdCode = code;
    		Catogray = label;
    		disabledFlag = true;
    	}
    	public void addAccountMaster(AccountMaster__c acc){
    		Prodid = acc.id;
    		disabledFlag = false;
    		if (CommUtils.isBlank(ProdName)) ProdName = acc.Name;
    		Materials = CommUtils.nullToBlank(acc.Materials__c);
    		Allergy = CommUtils.nullToBlank(acc.Allergy__c);
    	}
    }
    // 献立明細の情報
    class SchduleInfo{
    	String start;
    	String endDt;
    	String shops;
    	List<String> weekOpts;
    	public SchduleInfo(String beg,String over,List<String> opts,String shopCode){
    		start = beg;
    		endDt = over;
    		weekOpts = opts;
    		shops = shopCode;
    	}
    }
}