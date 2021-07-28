/*
* 2019/09/30 棚卸機能(原価、棚卸評価額項目追加と連絡)改善
*/
public with sharing class ProductStockInventoryCtrl extends CommBaseCtrl{
	public List<SelectOption> masterOpts{get;set;}
	public String masterOptVal{get;set;}
	public List<StockInfo> stocks{get;set;}
	public String curDt{get;set;}
	// 写真表示フラグ
	public boolean showFlag{get;set;}
	private static String REMOTE_METHOD_READ = 'queryStockData';
	private static String REMOTE_METHOD_UPD = 'updateStockData';
	// 写真保存モード
	private static String REMOTE_METHOD_MODESAVE = 'saveMode';
	private static string noImageUrl = '/resource/' + CommConst.APPOTION_NAMESPACE + 'OrderLib/css/images/noImage.jpg';
	public ProductStockInventoryCtrl(){}
    public void initStock(){
    	doAction();
    }
    private void doAction(){
    	showFlag = true;
    	curDt = system.today().format();
    	// 棚リスト作成
    	refresMaseterOption();
    	// データ更新
    	queryData();
    }
    public void changeMaster(){
    	// データ更新
    	queryData();
    	saveCookieSetting(masterOptVal,UserConfigCompCtrl.KREP_SUBTYPE.TANAO.name(),'');
    }
    @remoteaction
    public static Object remoteCenter(String dataType , String dataReq){
    	// 該当画面データ取得
    	if (dataType == REMOTE_METHOD_READ) return queryStockData(dataReq);
    	// データ保存
    	else if (dataType == REMOTE_METHOD_UPD) return updateStockData(dataReq);
    	// データ保存
    	else if (dataType == REMOTE_METHOD_MODESAVE) return saveMode(dataReq);
    	// 2018/12/30 棚卸し機能（在庫照合、在庫数改修） by cxw BEGIN
    	// 会計情報取得
    	else if (dataType == 'remoteProductDesc') return remoteProductDesc(dataReq);
    	// 2018/12/30 棚卸し機能（在庫照合、在庫数改修） by cxw END
    	return null;
    }
    // 該当画面データ取得
    private static object queryStockData(String dataReq){
    	StockInfo stock = (StockInfo) JSON.deserialize(dataReq,StockInfo.class);
    	List<StockInfo> stocks = queryInven(new Set<String>{stock.groupName});
    	return stocks;
    }
    // データ保存
    private static object updateStockData(String dataReq){
    	List<StockInfo> stocks = (List<StockInfo>)JSON.deserialize(dataReq,List<StockInfo>.class);
    	Date todayDt = system.today();
    	List<InventoryInfo__c> invenLst = new List<InventoryInfo__c>();
    	Set<String> groupSet = new Set<String>();
        // 2019/04/15 宿屋EXPOの棚卸について by zy BEGIN
        Set<String> prodIds = new Set<String>();
        // 2019/04/15 宿屋EXPOの棚卸について by zy END
    	for (StockInfo info : stocks) {
    		InventoryInfo__c inven = new InventoryInfo__c();
    		if (!CommUtils.isBlank(info.stockId)) inven.id = info.stockId;
    		inven.stockDate__c = todayDt;
    		inven.RealQtyOfStock__c = info.stockQty;
    		inven.AccountMasterRef__c = info.accountId;
    		// 既存フラグ設定
    		inven.ShelfChkFlag__c = info.checkFlag;
    		invenLst.add(inven);
    		groupSet.add(info.groupName);
		// 2019/04/15 宿屋EXPOの棚卸について by zy BEGIN
            	prodIds.add(info.accountId);
		// 2019/04/15 宿屋EXPOの棚卸について by zy END
    	}
    	if (!invenLst.isEmpty()) upsert invenLst;
        // 2019/04/15 宿屋EXPOの棚卸について by zy BEGIN
        // 棚卸し機能を使用する・使用しないフラグ
        // 棚卸データ直し保存
        if (CommConst.PROD_INVENTORY_FLG) {
            updProductStock(prodIds,todayDt);
        }
	// 2019/04/15 宿屋EXPOの棚卸について by zy END
    	return queryInven(groupSet);
    }
    private static object saveMode(String dataReq){
    	saveCookieSetting(dataReq,UserConfigCompCtrl.KREP_SUBTYPE.TANAOMODE.name(),'');
    	return null;
    }
    private void refresMaseterOption(){
    	masterOpts = new List<SelectOption>();
    	set<String> shelfSet = new Set<String>();
    	// 棚マスタ情報
    	List<String> shelfInfos = getShelfLst();
    	for (String mst : shelfInfos) {
    		if (CommUtils.isBlank(mst)) continue;
    		if (!shelfSet.contains(mst)) {
    			shelfSet.add(mst);
    			masterOpts.add(new SelectOption(mst,mst));
    		}
    	}
    	masterOptVal = getCookieSetting(UserConfigCompCtrl.KREP_SUBTYPE.TANAO.name());
    	if (CommUtils.isBLank(masterOptVal)) masterOptVal = shelfInfos[0];
    }
    // データ更新
    private void queryData(){
    	stocks = queryInven(new Set<String>{masterOptVal});
    	String cookieValue = CommUtils.nullToBlank(getCookieSetting(UserConfigCompCtrl.KREP_SUBTYPE.TANAOMODE.name()));
    	showFlag = CommUtils.isBlank(cookieValue) || cookieValue == 'true';
    }
    private static List<String> getShelfLst(){
    	Schema.DescribeFieldResult fieldResult = AccountMaster__c.Shelves__c.getDescribe();
    	List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    	List<String> values = new List<String>();
        for(Schema.PicklistEntry f : ple) {
        	String cook = f.getValue();
        	values.add(cook);
        }
    	return values;
    }
    // 2018/12/30 棚卸し機能（在庫照合、在庫数改修） by cxw BEGIN 
    private static List<accountMaster__c> queryShelfLst(Set<String> masterSet, Boolean isAccId){
    	// 2018/11/8 棚卸画面、「適正在庫」列は追加の対応 by cxw BEGIN
    	// 2019/09/30 棚卸機能(原価、棚卸評価額項目追加と連絡)改善 BY zyz BEGIN
    	// String querySQL = 'select id,Shelves__c,Field5__c,name,BigImage__c,ReasonableStock__c from accountMaster__c where ' + (isAccId ? 'field3__c' : 'Shelves__c') + ' in :masterSet';
    	String querySQL = 'select id,Shelves__c,Field5__c,name,BigImage__c,ReasonableStock__c,Field7__c from accountMaster__c where ' + (isAccId ? 'field3__c' : 'Shelves__c') + ' in :masterSet';
    	// 2019/09/30 棚卸機能(原価、棚卸評価額項目追加と連絡)改善 BY zyz END
    	// 2018/12/30 棚卸し機能（在庫照合、在庫数改修） by cxw END
    	// 2018/11/8 棚卸画面、「適正在庫」列は追加の対応 by cxw END
    	querySQL += ' order by '+CommConst.PROD_SORT_KEY;
    	integer orgValue = 0;
    	if (masterSet != null) orgValue = masterSet.size();
    	Set<String> exitSet = new Set<String>();
    	// 棚マスタ情報
    	List<accountMaster__c> shelfInfos = Database.query(querySQL);
    	return shelfInfos;
    }
    private static List<StockInfo> queryInven(Set<String> masterIds) {
   	 // 2018/12/30 棚卸し機能（在庫照合、在庫数改修） by cxw BEGIN
    	return queryInven(masterIds, false);
    }
    private static List<StockInfo> queryInven(Set<String> masterIds, Boolean isAccId) {
    // 2018/12/30 棚卸し機能（在庫照合、在庫数改修） by cxw END	
    	List<StockInfo> stockLst = new List<StockInfo>();
    	// 棚マスタ情報
    	// 2018/12/30 棚卸し機能（在庫照合、在庫数改修） by cxw BEGIN
    	List<AccountMaster__c> shelfInfos = queryShelfLst(masterIds, isAccId);    	
    	// 2018/12/30 棚卸し機能（在庫照合、在庫数改修） by cxw END
    	// 棚マスタ集合
    	Set<String> masterSet = new Set<String>();
    	for (AccountMaster__c mast : shelfInfos) {
    		masterSet.add(mast.id);
    	}
    	Set<String> detailSet = new Set<String>();
    	// 商品在庫情報
    	Map<String,ProductStock__c> stockMap = new Map<String,ProductStock__c>();
    	for (ProductStock__c stock : [select id,ProductRef__c,ProductSfId__c,LogicQtyOfStock__c,InitQtyOfStock__c,ProductOutStock__c,PurchaseSummary__c from ProductStock__c where ProductRef__c in :masterSet]) {
    		stockMap.put(stock.ProductRef__c,stock);
    	}
    	Map<String,InventoryInfo__c> invenMap = new Map<String,InventoryInfo__c>();
    	for (InventoryInfo__c inven : [select id ,StockDate__c,AccountMasterRef__c,ShelfChkFlag__c,RealQtyOfStock__c from InventoryInfo__c where AccountMasterRef__c in :masterSet]) {
    		String searchKey = inven.AccountMasterRef__c;
    		invenMap.put(searchKey,inven);
    	}
    	// 2019/09/30 棚卸機能(原価、棚卸評価額項目追加と連絡)改善 BY zyz BEGIN
    	Map<String,PurchaseDetail__c> purchaseMap = new Map<String,PurchaseDetail__c>();
    	list<PurchaseDetail__c> PurchaseDetailLst = [select Id,AccountMasterRef__c,CostPrice__c,InStockDate__c from PurchaseDetail__c where AccountMasterRef__c in :masterSet order by InStockDate__c desc,LastModifiedDate desc];
    	set<String> searchSet = new set<String>();
    	for (PurchaseDetail__c purchase : PurchaseDetailLst){
    		String searchKey = purchase.AccountMasterRef__c;
    		if (searchSet.contains(searchKey)) continue;
    		searchSet.add(searchKey);
    		purchaseMap.put(searchKey,purchase);
    	}
    	// 2019/09/30 棚卸機能(原価、棚卸評価額項目追加と連絡)改善 BY zyz END
    	// 2018/12/30 棚卸し機能（在庫照合、在庫数改修） by cxw BEGIN
    	Map<String,ProdDiff> diffMap = diffProductStockCheck(invenMap.values());
    	// 2018/12/30 棚卸し機能（在庫照合、在庫数改修） by cxw END
    	for (AccountMaster__c shelf : shelfInfos) {
			ProductStock__c stock = stockMap.get(shelf.id);
    		String searchKey = shelf.id; 
    		//+ '_' + groupName;
    		InventoryInfo__c inven = invenMap.get(searchKey);
    		// 2019/09/30 棚卸機能(原価、棚卸評価額項目追加と連絡)改善 BY zyz BEGIN
    		PurchaseDetail__c purchase = purchaseMap.get(searchKey);
    		// StockInfo stockInfo = new StockInfo(shelf,stock,inven);
    		StockInfo stockInfo = new StockInfo(shelf,stock,inven,purchase);
    		// 2019/09/30 棚卸機能(原価、棚卸評価額項目追加と連絡)改善 BY zyz END
    		// 2018/12/30 棚卸し機能（在庫照合、在庫数改修） by cxw BEGIN
    		if (diffMap.containsKey(shelf.id)) stockInfo.title = '該当棚卸日以後、入出庫データが存在する';
    		// 2018/12/30 棚卸し機能（在庫照合、在庫数改修） by cxw END
    		stockLst.add(stockInfo);
    	}
    	return stockLst;
    }
    //　在庫情報
    public class StockInfo{
    	public String groupName{get;set;}
    	public String accountId{get;set;}
    	public String accountNm{get;set;}
    	public String mstId{get;set;}
    	public String stockId{get;set;}
    	// 2018/12/30 JINYABUG-1297 bug fix by cxw BEGIN
    	public Decimal orgQty{get;set;}
    	public Decimal stockQty{get;set;}
    	// 2018/12/30 JINYABUG-1297 bug fix by cxw END
    	public String stockDt{get;set;}
    	public decimal amount{get;set;}
    	public decimal price{get;set;}
    	// 保存フラグ
    	public boolean checkFlag{get;set;}
    	//　imageurl
    	public String image{get;set;}
    	// 2018/11/8 棚卸画面、「適正在庫」列は追加の対応 by cxw BEGIN
    	public Integer reasonableStockQty{get; set;}
    	// 写真なしのフラグ
    	public boolean defaultFlag{get;set;}
    	// 2018/11/8 棚卸画面、「適正在庫」列は追加の対応 by cxw END
    	// 2018/12/30 棚卸し機能（在庫照合、在庫数改修） by cxw BEGIN
    	public String title{get;set;}
    	// 2018/12/30 棚卸し機能（在庫照合、在庫数改修） by cxw END
    	// 2019/09/30 棚卸機能(原価、棚卸評価額項目追加と連絡)改善 BY zyz BEGIN
    	public Decimal stockCost{get;set;}	// 原価
    	public Decimal valuation{get;set;}	// 評価額
    	// public StockInfo(Accountmaster__c acc,ProductStock__c stock,InventoryInfo__c inven){
    	public StockInfo(Accountmaster__c acc,ProductStock__c stock,InventoryInfo__c inven,PurchaseDetail__c purchase){
    	// 2019/09/30 棚卸機能(原価、棚卸評価額項目追加と連絡)改善 BY zyz END
    		orgQty = 0;
    		stockQty = 0;
    		amount = 0;
    		mstId = acc.Shelves__c;
    		stockDt = '';
    		groupName = acc.Shelves__c;
    		accountId = acc.id;
    		accountNm = acc.name;
    		// 2018/11/8 棚卸画面、「適正在庫」列は追加の対応 by cxw BEGIN
    		reasonableStockQty = CommUtils.nullToIntZero(acc.ReasonableStock__c);
    		defaultFlag = false;
    		// 2018/11/8 棚卸画面、「適正在庫」列は追加の対応 by cxw END
    		checkFlag = false;
    		// 2018/10/06 会計商品写真追加 by zy BEGIN
    		if(acc != null && !CommUtils.isBlank(acc.BigImage__c)){
				image = acc.BigImage__c.unescapeHtml4().subStringAfter('src="');
				image = image.substringBefore('"');
			}
			// 2018/11/8 棚卸画面、「適正在庫」列は追加の対応 by cxw BEGIN
			if (CommUtils.isBlank(image)) {
				image = noImageUrl;
				defaultFlag = true;
			}// 2018/11/8 棚卸画面、「適正在庫」列は追加の対応 by cxw END
			// 2018/10/06 会計商品写真追加 by zy END
    		price = CommUtils.nullToZero(acc.Field5__c);
    		if (stock != null) {
    			// 2018/12/30 JINYABUG-1297 bug fix by cxw BEGIN
    			// orgQty = CommUtils.nullToIntZero(stock.LogicQtyOfStock__c);
    			orgQty = CommUtils.nullToZero(stock.LogicQtyOfStock__c);
    			// 2018/12/30 JINYABUG-1297 bug fix by cxw END
    			amount = CommUtils.nullToZero(orgQty * CommUtils.nullToZero(acc.Field5__c));
    			stockQty = orgQty;
    		}
    		if (inven != null) {
    			// 保存フラグ
    			checkFlag = inven.ShelfChkFlag__c;
    			// 該当棚卸しデータ既存フラグ
    			// 2018/12/30 JINYABUG-1297 bug fix by cxw BEGIN
    			if (checkFlag) stockQty = CommUtils.nullToZero(inven.RealQtyOfStock__c);
    			// 2018/12/30 JINYABUG-1297 bug fix by cxw END
    			if (inven.StockDate__c != null) stockDt = inven.StockDate__c.format();
    			stockId = inven.id;
    		}
    		// 2019/09/30 棚卸機能(原価、棚卸評価額項目追加と連絡)改善 BY zyz BEGIN
    		stockCost = CommUtils.nullToZero(acc.Field7__c);
    		if(purchase != null){
    			stockCost = CommUtils.nullToZero(purchase.CostPrice__c);
    		}
    		valuation = CommUtils.nullToZero(stockQty * stockCost);
    		// 2019/09/30 棚卸機能(原価、棚卸評価額項目追加と連絡)改善 BY zyz END
    	}
    }
     // Cookie情報処理追加
    private String getCookieSetting(String functionType){
    	// DBから設定情報を取得する
		map<String,String> userBookMap = UserConfigCompCtrl.getCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.TANAO,UserUtil.CurrentUser.id,'');
		String setInnfo = CommUtils.nullToBlank(userBookMap.get(functionType));
		return CommUtils.nullToBlank(setInnfo);
    }
    // 保存Cookie情報
    private static void saveCookieSetting(String setInfo,String subType,string spcd){
    	UserConfigCompCtrl.saveCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.TANAO,
				subType,CommUtils.nullToBlank(setInfo),UserUtil.CurrentUser.id,spcd);
    }
    // 2018/12/30 棚卸し機能（在庫照合、在庫数改修） by cxw BEGIN
    @remoteAction 
    public static Object remoteProductDesc(String requests){
    	List<String> ids = (List<String>)JSON.deserialize(requests, List<String>.class);
    	return queryInven(new Set<String>(ids), true);
    }
    // 差異明細変更
    public static Map<String,ProdDiff> diffProductStockCheck(List<InventoryInfo__c> invens){
    	// 開始日
    	Date startDt;
    	// 差異集合
    	Map<String,ProdDiff> diffMap = new Map<String,ProdDiff>();
    	// 棚卸データ
    	Map<String,InventoryInfo__c> invenMap = new Map<String,InventoryInfo__c>();
    	Set<String> prodSet = new Set<String>();
    	for (InventoryInfo__c inven : invens) {
    		if (inven.ShelfChkFlag__c) {
    			// 開始日
    			if (startDt == null || startDt < inven.StockDate__c) startDt = inven.StockDate__c;
    			String searchKey = inven.AccountMasterRef__c;
    			prodSet.add(searchKey);
    			invenMap.put(searchKey,inven);
    		}
    	}
    	if (startDt != null) {
    		Date todayDt = system.today();
    		String todayStr = CommUtils.dateToYYYYMMDD(todayDt);
    		String startStr = CommUtils.dateToYYYYMMDD(startDt);
	    	// 仕入明細
	    	Map<String,decimal> inputProdMap = new Map<String,decimal>();
	   		for (PurchaseDetail__c input : [select id,ProductNumber__c,AccountMasterRef__c,InStockDate__c from PurchaseDetail__c where AccountMasterRef__c = :prodSet and InStockDate__c > :startStr and IsNotTarget__c = false]) {
	   			// 棚卸日と今日区間
	   			if (invenMap.containsKey(input.AccountMasterRef__c)) {
	   				InventoryInfo__c inven = invenMap.get(input.AccountMasterRef__c);
	   				if (inven.StockDate__c == null) continue;
	   				String stockDt = CommUtils.dateToYYYYMMDD(inven.StockDate__c);
	   				if (stockDt > input.InStockDate__c) continue;
	   			}
	   			if (!inputProdMap.containsKey(input.AccountMasterRef__c)) inputProdMap.put(input.AccountMasterRef__c,0);
	   			inputProdMap.put(input.AccountMasterRef__c,inputProdMap.get(input.AccountMasterRef__c) + input.ProductNumber__c);
	   		}
	   		// 商品出庫情報
	   		Map<String,decimal> outProdMap = new Map<String,decimal>();
	   		for (ProductOutStock__c output : [select id,ProductNumber__c,AccountMasterRef__c,OutStockDate__c from ProductOutStock__c where AccountMasterRef__c = :prodSet and OutStockDate__c > :startStr and IsNotTarget__c = false]) {
	   			// 棚卸日と今日区間
	   			if (invenMap.containsKey(output.AccountMasterRef__c)) {
	   				InventoryInfo__c inven = invenMap.get(output.AccountMasterRef__c);
	   				if (output.OutStockDate__c == null) continue;
	   				String stockDt = CommUtils.dateToYYYYMMDD(inven.StockDate__c);
	   				if (stockDt > output.OutStockDate__c) continue;
	   			}
	   			if (!outProdMap.containsKey(output.AccountMasterRef__c)) outProdMap.put(output.AccountMasterRef__c,0);
	   			outProdMap.put(output.AccountMasterRef__c,outProdMap.get(output.AccountMasterRef__c) + output.ProductNumber__c);
	   		}
	   		for (String prodId : invenMap.keySet()) {
	   			ProdDiff diff = new ProdDiff(prodId,inputProdMap.get(prodId),outProdMap.get(prodId));
	   			// 差異値存在の場合
	   			if (diff.diffNumber != 0) diffMap.put(prodId,diff);
	   		}
    	}
    	return diffMap;
    }
    // 差異情報
    public class ProdDiff{
    	// 商品ID
    	String prodId;
    	// 差異値
    	Decimal diffNumber;
    	// 初期化
    	public ProdDiff(String prodId,Decimal inputNum,Decimal outNum){
    		this.prodId = prodId;
    		diffNumber = CommUtils.nullToZero(CommUtils.nullToZero(inputNum) - CommUtils.nullToZero(outNum));
    	}
    }
    // 2018/12/30 棚卸し機能（在庫照合、在庫数改修） by cxw END
    // 2019/04/15 宿屋EXPOの棚卸について by zy BEGIN
    private static void updProductStock(Set<String> processIds,Date gProDate){
        // 該当処理日の会計商品在庫情報取得
        Map<String,ProductStock__c> prodMap = new Map<String,ProductStock__c>();
        // 既存棚卸し在庫対応
        Map<Id,decimal> stockMap = new Map<Id,decimal>();
        Savepoint sp = Database.setSavepoint();
        // 有効な会計集合
        Set<String> processIdSet = new Set<String>();
        try{
            Set<String> inventoryIds = new Set<String>();
            // 棚卸し在庫処理
            List<InventoryInfo__c> ints = [select id,AccountMasterRef__c,StockDate__c,ShelfChkFlag__c,RealQtyOfStock__c from InventoryInfo__c 
                                                    where AccountMasterRef__c in :processIds and StockDate__c <= :gProDate and ShelfChkFlag__c = true];
            // 棚卸し在庫LOOP
            for (InventoryInfo__c inventory : ints) {
                // 該当商品在庫取得
                Decimal cnt = CommUtils.nullToZero(inventory.RealQtyOfStock__c); 
                // 商品在庫数設定
                stockMap.put(inventory.AccountMasterRef__c,cnt);
                // 在庫処理後再処理フラグ設定
                inventory.ShelfChkFlag__c = false;
                // 締日設定
                inventory.BatchDate__c = gProDate;
                // 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy BEGIN
                // 処理会計商品
                processIdSet.add(inventory.AccountMasterRef__c);
                // 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy END
            }
            // 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy BEGIN
            //Map<String,ProductStockInventoryCtrl.ProdDiff> diffMap = ProductStockInventoryCtrl.diffProductStockCheck(ints);
            // 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy END
            List<ProductStock__c>  prodStocks = [select id ,InitQtyOfStock__c,ProductRef__c,ProductRef__r.name from ProductStock__c where ProductRef__c in : processIds];
            // 処理会計商品データあり
            for (ProductStock__c stock : prodStocks) {
                // 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy BEGIN
                //stock.InitQtyOfStock__c = CommUtils.nullToIntZero(stockMap.get(stock.ProductRef__c));
                Decimal stockInt = CommUtils.nullToZero(stockMap.get(stock.ProductRef__c));
                stock.InitQtyOfStock__c = stockInt;
                // 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy END
                processIdSet.remove(stock.ProductRef__c);
            }
            // 新規商品在庫
            if (!processIdSet.isEmpty()) {
                List<ProductStock__c> insertStocks = new List<ProductStock__c>();
                for (String prodId : processIdSet) {
                    Decimal stockInt = CommUtils.nullToZero(stockMap.get(prodId));
                    insertStocks.add(new ProductStock__c(
                        ProductRef__c = prodId,
                        ProductSfId__c = prodId,
                        InitQtyOfStock__c = stockInt
                    ));
                }
                if (!insertStocks.isEmpty()) insert insertStocks;
            }
            // 在庫更新
            if (!prodStocks.isEmpty()) update prodStocks;
            // 棚卸し在庫処理
            if (!ints.isEmpty()) update ints;
            // 入庫情報と出庫情報の集計対象フラグを更新する
            String queryYmd = (DateTime.newInstance(gProDate.year(),gProDate.month(),gProDate.day())).format('yyyyMMdd');
            List<PurchaseDetail__c> inputDetails = [select id,AccountMasterRef__c,IsNotTarget__c,InStockDate__c from PurchaseDetail__c where InStockDate__c <= :queryYmd and IsNotTarget__c != true and AccountMasterRef__c in :processIds];
            for (PurchaseDetail__c s : inputDetails) {
                // 入庫日
                s.IsNotTarget__c = true;
            }
            if (!inputDetails.isEmpty()) update inputDetails;
            List<ProductOutStock__c> outDetails = [select id,AccountMasterRef__c,IsNotTarget__c,OutStockDate__c from ProductOutStock__c where OutStockDate__c <= :queryYmd and IsNotTarget__c != true and AccountMasterRef__c in :processIds];
            for (ProductOutStock__c s : outDetails) {
                s.IsNotTarget__c = true;
            }
            if (!outDetails.isEmpty()) update outDetails;
        }catch(Exception e) {
            DataBase.rollback(sp);
        }
    }
    // 2019/04/15 宿屋EXPOの棚卸について by zy END
}