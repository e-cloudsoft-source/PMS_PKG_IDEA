/**
* ベースプラン情報取得
* 
**/
global with sharing class BasePlanSetupViewCtrl extends CommBaseCtrl{
	
    // 会計種別：プラン
    global String ACTTYPE_PLAN{get{return CommConst.PROD_ACTION_TYPE_PL;}}
    /* TODO:两种支付方法可以去除 */
    global String ACTTYPE_PAY{get{return CommConst.PROD_ACTION_TYPE_PY;}}   // 支払
    global String ACTTYPE_AR {get{return CommConst.PROD_ACTION_TYPE_AR;}}   // 前受金
    // 単価定義区分を設定する
    global Integer UnitPriceKbn {get{return CommConst.APPOPTION_UTP_DEF_KB;}}
    // 获取返回的CallBack
    global String callBackFun{get;private set;}
    // 2020/05/28 6406 bug fixed BY zyz BEGIN
    // 获取当前使用的房型
    global String roomTypeId{get;private set;}
    // 获取当前设定的时间
    global String queryDate{get;private set;}
    // 获取当前店铺code
    global String spcd{get;private set;}
    // tier 存储map
    global String raceRateMapJson{get;private set;} 
    // 2020/05/28 6406 bug fixed BY zyz END   
    // 軽減税率機能
    global Boolean isReducedTaxFlg{get{ return CommConst.REDUCED_TAXRATE_FLG;} set;}
    global static boolean planBrkToHeaderCalFlg{get{ return CommConst.PLAN_BRKTOHEADER_CAL_FLG;} private set;}
    global String hotelTaxDefineInfoJson {get{ return JSON.serialize(CommLogicProcess.getHotelTaxDefInstance());}}
    // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
    public String OPTION_MODE{get{ return CommConst.OPTION_MODE;}}
    // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
    // 検索条件：商品名
    global String c_planNm{get;set;}
    global String c_gpId{get;set;}
    global String c_dpId{get;set;}
    global List<SelectOption> branchShopLst{get; private set;}
    global String branchShopNm{get; set;}
    private String planNmStr;
    // 商品DP選択リスト
    global List<Selectoption> dpOptionLst{get; private set;}
    global List<Selectoption> gpOptionLst{get; private set;}
    // 御見積金額
    global Decimal totalAmount{get;set;}
    // 店舗別ベースプラン
    public Boolean shopAccountSetupFlg{get{ return (CommConst.APPOTION_BI_SHOPPLAN_FLG && CommDefine__c.getOrgDefaults().ShopBasePlanFlg__c);}set;}
	global List<ProductItemUtils.ProductItem> orgPlanLst{get;set;}
	global map<String,String> orgJsonMap{get;set;}
	private String pWhereStr =' Where Name != null AND IsClosed__c != true And BasePlanFlg__c = true ';
	// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
	private boolean isPriveFlg = false;
	// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
    global BasePlanSetupViewCtrl(){
    	// 获取返回的CallBack
    	callBackFun = ApexPages.currentPage().getParameters().get('callback');
    	roomTypeId = CommUtils.nullToBlank(ApexPages.currentPage().getParameters().get('roomType'));
    	queryDate = CommUtils.nullToBlank(ApexPages.currentPage().getParameters().get('queryDate'));
		planVipStr = CommUtils.nullToBlank(ApexPages.currentPage().getParameters().get('guestType'));
		spcd = '';
		list<TypeOfRooms__c> roomTypeLst = [select Id,ShopInfoRef__r.ShopCode__c from TypeOfRooms__c where Id =:roomTypeId];
		if (!roomTypeLst.isEmpty()) spcd = CommUtils.nullToBlank(roomTypeLst[0].ShopInfoRef__r.ShopCode__c);
		getVipList();
		// 商品分類選択リストを設定を行う
		dpOptionLst = new List<Selectoption>();
		gpOptionLst = new List<Selectoption>();
		
		for (DP__c s: [select id, name, Field1__c from DP__c where IsClosed__c != true order by Name limit 500]) dpOptionLst.add(new SelectOption(s.id, s.Name));
		for (GP__c s: [select id, name, Field1__c from GP__c where IsClosed__c != true order by Name limit 500]) gpOptionLst.add(new SelectOption(s.id, s.Name));
	}
	// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
	public BasePlanSetupViewCtrl(String typeId,String queryDt,String spcd,String guestType){
		roomTypeId = typeId;
    	queryDate = queryDt;
    	// 2021/06/31 #11783 bug fixed by zy BEGIN
		this.spcd = spcd;
		// 2021/06/31 #11783 bug fixed by zy END
		planVipStr = guestType;
		isPriveFlg = true;
	}
	// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
	// 画面初期化
	public void init(){
		totalAmount = 0;
		// 获取tier
		orgPlanLst = new List<ProductItemUtils.ProductItem>();
		orgJsonMap = new map<String,String>();
		// 店舗別の対応
		if (shopAccountSetupFlg && !CommUtils.isBlank(spcd)) {
			pWhereStr += ' and ShopInfoRef__r.shopCode__c = :spcd';
		}
		// プランのTier処理
		queryInfo();
	}
	// 会員種別変更
	public void switchTypeAction(){
		init();
	}
    global void querySqlInfo(String whereStr){
		// 当前设定的日期
		Date startDate = CommUtils.stringToDate(queryDate);
		// 默认的key
		String defKey = '_' + startDate;
		// プラン商品Id
		set<Id> accIdSet = new set<Id>();
		// プランこーののプランId
		Map<String,Plan__c> planCodeMap = new Map<String,Plan__c>();
		// Tier初期値設定する
		String defaultTier = getDefTiers(spcd);
		// 部屋タイプID/ Map<日付, 金額>
		Map<String, Decimal> raceRateMstMap = getRackRatePriceMap();
		// 根据设定日检索,ラックレート明細
		// roomtype 数据map
		map<String,String> setupRoomTypeTierMap = getRackRateDetailMap(startDate);
		// 返回的数据map
		Map<String, Decimal> raceRatePriceAllMap = new Map<String, Decimal>();
		// baseplan 数据map
		map<String,String> setupBasePlanTierMap = new map<String,String>();
		// 止まるのベースプラン
		Set<String> stopPlan = new Set<String>();
		// 販売のベースプラン
		Set<String> salesPlan = new Set<String>();
		// 一括のベースプラン設定
		BasePlanDetail__c bulkBasePlan = null;
		// ベースプランの場合
		if(isBasePlanLayputFlg){
			// baseplan的贩卖状态
			map<String,String> basePlanSalesMap = new map<String,String>();
			// 根据设定日检索,ラックレート明細（プラン）
    		String queryBasePlan = 'Select SearchKey__c,Tier__c,BasePlanRef__c,GuestType__c,PriceSetupDate__c,SalesStatus__c From BasePlanDetail__c Where PriceSetupDate__c =:startDate and GuestType__c =: planVipStr';
			list<BasePlanDetail__c> BasePlanDetailLst = DataBase.query(queryBasePlan);
    		// 处理设定的数据
    		for(BasePlanDetail__c detail : BasePlanDetailLst){
				// 一括のベースプラン設定取得
				if (CommUtils.isBlank(detail.BasePlanRef__c) ) bulkBasePlan = detail;
				// 販売プラン
				else if(detail.SalesStatus__c == '1') salesPlan.add(detail.BasePlanRef__c);
				// 止まるプラン
				else if(detail.SalesStatus__c == '2') stopPlan.add(detail.BasePlanRef__c);
				// プランのラックレート設定
    			String mapkey = CommUtils.nullToBlank(detail.BasePlanRef__c) + '_' + startDate;
    			setupBasePlanTierMap.put(mapkey,detail.Tier__c);
			}
		}
    	// 检索baseplan商品
    	String queryStr = ' select Id, Name,PlanNo__c From Plan__c ' + whereStr + ' order by ShopInfoRef__c, DpRef__c, GpRef__c, PackageCode__c limit 100 ';
    	list<Plan__c> oBasePlanLst = DataBase.query(queryStr);
		// 循环plan商品ID，设定金额
    	for(Plan__c plan : oBasePlanLst){
			// 默认tier
			String tier = defaultTier;
			String planKey = plan.Id + '_' + startDate;
			String rackRateKey = roomTypeId + '_' + startDate;
    		// 处理检索plan商品对应的code
    		String key = PlanProductSetup.getPlanProdCode(plan.PlanNo__c);
			planCodeMap.put(key,plan);
			// ラックレート処理
			// 取得单独设定的tier
			if (setupBasePlanTierMap.containsKey(planKey)) tier = setupBasePlanTierMap.get(planKey);
			// 取得一括设定的tier
			else if (setupBasePlanTierMap.containsKey(defKey)) tier = setupBasePlanTierMap.get(defKey);
			else if (setupRoomTypeTierMap.containsKey(rackRateKey)) tier = setupRoomTypeTierMap.get(rackRateKey);
			else if (setupRoomTypeTierMap.containsKey(defKey)) tier = setupRoomTypeTierMap.get(defKey);
			// Tier + "_" + 人数 + "_" + 部屋タイプID
			for(String searchKey : raceRateMstMap.keySet()){
				// 2021/04/18 ラックレート設定ベースプラン金額 BY zyz BEGIN
				List<String> searchKeyLst = CommUtils.nullToBlank(searchKey).split('_');
				// 不生效的情况下
				if(searchKeyLst.size() < 3) continue;
				// 设定房型价格取得
				else if (searchKeyLst.size() == 3){
					String raceRateKey = tier + '_' + roomTypeId + '_' + searchKeyLst[2];
					if (raceRateMstMap.containsKey(raceRateKey)) {
						Decimal price = raceRateMstMap.get(raceRateKey);
						String raceRateAllKey = plan.Id +'_' + searchKeyLst[2];
						if (!raceRatePriceAllMap.containsKey(raceRateAllKey)) raceRatePriceAllMap.put(raceRateAllKey, price);
					}
				}
				// 设定plan价格取得
				else if (searchKeyLst.size() == 4 && searchKeyLst[3] == plan.Id && CommConst.RACKRATE_BASEPLAN){
					String raceRateKey = tier + '_' + roomTypeId + '_' + searchKeyLst[2] + '_' + searchKeyLst[3];
					if (raceRateMstMap.containsKey(raceRateKey)) {
						Decimal price = raceRateMstMap.get(raceRateKey);
						String raceRateAllKey = plan.Id +'_' + searchKeyLst[2];
						raceRatePriceAllMap.put(raceRateAllKey, price);
					}
				}				
				/*
				String raceRateKey = tier + '_' + roomTypeId + '_' + searchKeyLst[2];
				if (raceRateMstMap.containsKey(raceRateKey)) {
					Decimal price = raceRateMstMap.get(raceRateKey);
					String raceRateAllKey = plan.Id +'_' + searchKeyLst[2];
					raceRatePriceAllMap.put(raceRateAllKey, price);
    			}
    			*/
    			// 2021/04/18 ラックレート設定ベースプラン金額 BY zyz END
			}
		}
		// ラックレート情報JSON作成
		raceRateMapJson = JSON.serialize(raceRatePriceAllMap);
		//　会計商品対応プラン集合
    	Map<String,String> basePlanPriceMap = new Map<String,String>();
		// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
		Map<String,String> planAccMap = new Map<String,String>();
		// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
    	// 检索plan对应额会计商品
    	list<AccountMaster__c> AccountMasterLst = [select Id, Name, Field5__c, TaxRateCal__c, ServiceRate__c, SpecialTax__c, ActionType__c,Field4__c,GPChange__c,Field3__c,PaymentType__c, Field7__c,DiscountRate__c,(Select Price__c, AccountMasterRef__r.ActionType__c, TaxRate__c, ServiceRate__c, AccountMasterRef__c, AccountMasterRef__r.Name, Id, Amount__c, OptionAccMstFLG__c From PlanProdcutRef__r) 
    												 // 2020/07/30 入湯税の自動入力機能について改善 zyz BEGIN
    												 ,PlanBathTaxAccMstRef__r.BathTaxAccMstRef__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Id
    												 ,PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Name, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Field3__c
    												 ,PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Field5__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.TaxRateCal__c
    												 ,PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.ServiceRate__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.SpecialTax__c
    												 ,PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.ActionType__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.PaymentType__c
    												 ,PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.DiscountRate__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Field7__c
    												 // 2020/07/30 入湯税の自動入力機能について改善 zyz END
    												 From AccountMaster__c where Field3__c in :planCodeMap.keySet() order by Field4__c,OP__c, Field3__c];
    	for(AccountMaster__c acc : AccountMasterLst){
    		accIdSet.add(acc.Id);
			// 数据的planId作成
    		String planId ='';
    		if (planCodeMap.containsKey(acc.Field3__c)) planId = planCodeMap.get(acc.Field3__c).id;
    		basePlanPriceMap.put(acc.Id,planId);
			// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
			planAccMap.put(planId,acc.id);
			// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
    	}
		// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
		if (isPriveFlg) {
			system.debug(logginglevel.info, 'raceRatePriceAllMap:::' + raceRatePriceAllMap);
			Map<String,decimal> rackAllMap = new Map<String,Decimal>();
			for (String key : raceRatePriceAllMap.keySet()){
				String[] keyLst =  key.split('_');
				// planid->accid
				keyLst[0] = planAccMap.get(keyLst[0]);
				rackAllMap.put(string.join(keyLst,'_'),raceRatePriceAllMap.get(key));
			}
			String rackRateKey = roomTypeId + '_' + startDate;
			// 默认tier
			String tier = defaultTier;
			if (setupRoomTypeTierMap.containsKey(rackRateKey)) tier = setupRoomTypeTierMap.get(rackRateKey);
			else if (setupRoomTypeTierMap.containsKey(defKey)) tier = setupRoomTypeTierMap.get(defKey);
			// Tier + "_" + 人数 + "_" + 部屋タイプID
			for(String searchKey : raceRateMstMap.keySet()){
				List<String> searchKeyLst = CommUtils.nullToBlank(searchKey).split('_');
				if(searchKeyLst.size() < 3) continue;
				String raceRateKey = tier + '_' + roomTypeId + '_' + searchKeyLst[2];
				if (raceRateMstMap.containsKey(raceRateKey)) {
					Decimal price = raceRateMstMap.get(raceRateKey);
					// 人数->価格
					rackAllMap.put(searchKeyLst[2], price);
				}
			}
			raceRateMapJson = JSON.serialize(rackAllMap);
			return;
		}
		// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
    	// 数据的planId
    	basePlanPriceJson = JSON.serialize(basePlanPriceMap);
    	// plan数据的明细处理
    	map<String,list<PlanDetail__c>> pDetailLstMap = new map<String,list<PlanDetail__c>>();
    	// 2020/06/03 6456 bug fix BY zyz BEGIN
        for (PlanDetail__c detail : [Select AccountMasterRef__c, Price__c, TaxRate__c,PlanProdcut__c,AccountMasterRef__r.ActionType__c,OptionAccMstFLG__c,Amount__c From PlanDetail__c  where  PlanProdcut__c = :accIdSet]){
        // 2020/06/03 6456 bug fix BY zyz END
            if (!pDetailLstMap.containsKey(detail.PlanProdcut__c)) pDetailLstMap.put(detail.PlanProdcut__c, new List<PlanDetail__c>());
            pDetailLstMap.get(detail.PlanProdcut__c).add(detail);
        }
        // 处理页面显示数据和隐藏域数据
    	for(AccountMaster__c acc : AccountMasterLst){
    		List<PlanDetail__c> pDetailLst =  new List<PlanDetail__c>();
    		if (pDetailLstMap.containsKey(acc.Id)) pDetailLst = pDetailLstMap.get(acc.Id);
    		ProductItemUtils.ProductItem proItem = new ProductItemUtils.ProductItem(acc, pDetailLst, true);
			Plan__c plan = planCodeMap.get(acc.Field3__c);
			if (planCodeMap.containsKey(acc.Field3__c)) proItem.prodcutName = plan.name;
			// 一括プラン設定あり
			if (bulkBasePlan != null) {
				// 一括販売の場合、販売の集合有効
				if (bulkBasePlan.SalesStatus__c == '1' && stopPlan.contains(plan.id)) continue;
				// 一括止まるの場合、販売の集合含むないのプラン
				else if (bulkBasePlan.SalesStatus__c == '2' && !salesPlan.contains(plan.id)) continue;
			// 一括プラン設定なし
			} else if (stopPlan.contains(plan.id)) continue;
    		orgPlanLst.add(proItem);
    		orgJsonMap.put(acc.Id,JSON.serialize(proItem));
    	}
    }
    global void queryInfo(){
    	orgPlanLst = new List<ProductItemUtils.ProductItem>();
    	orgJsonMap = new map<String,String>();
        String whereStr = pWhereStr;
        if (!CommUtils.isBlank(c_planNm)) {
        	planNmStr = '%' + c_planNm + '%';
        	whereStr += ' AND Name like: planNmStr ';
        }
        // DP設定場合
        if (!CommUtils.isBlank(c_dpId)) {
        	whereStr += ' AND DpRef__c = :c_dpId ';
        }
        // GP設定場合
        if (!CommUtils.isBlank(c_gpId)) {
            whereStr += ' And GpRef__c = :c_gpId ';
        }
    	querySqlInfo(whereStr);
	}
	// 2020/01/30 新規予約入力画面で見積明細にプランを室料0円のまま入力して、保存前に合計金額を表示して欲しい WGCH BEGIN
	// 默认tier的获取
	global static String getDefTiers(String shopCd) {
		Map<String,ShopInformation__c> shopInfoMap = ShopInfoUtil.getShopInfoMap(UserUtil.CurrentUserInfo.shops);
		if (shopInfoMap.containsKey(shopCd)) {
			return 	CommUtils.isBLank((shopInfoMap.get(shopCd)).TierDefault__c) 
					? CommUtils.nullToBlank( CommDefine__c.getOrgDefaults().RackRateTableTierDefault__c )
					: CommUtils.nullToBlank( (shopInfoMap.get(shopCd)).TierDefault__c );
		} else {
			return CommUtils.nullToBlank( CommDefine__c.getOrgDefaults().RackRateTableTierDefault__c );
		}
	}
	// 会员种别可以自定义处理
	public list<SelectOption> vipTypeLst{get;private set;}
	public String planVipStr{get;set;}
    public void getVipList(){
		vipTypeLst = new List<SelectOption>();
		// 予約ポップラックレート設定[プラン]無効,会员种别list不显示
		if(isBasePlanLayputFlg){
			Schema.DescribeFieldResult fieldResult = BasePlanDetail__c.GuestType__c.getDescribe();
			List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
			for( Schema.PicklistEntry f : ple) {
				if(f.isDefaultValue() || CommUtils.isBlank(planVipStr)) planVipStr = f.getLabel();
				vipTypeLst.add(new SelectOption(f.getLabel(),f.getLabel()));
			}
		}
    }
    
    public String basePlanPriceJson{get;set;}
    private boolean isBasePlanLayputFlg{get{ return CommDefine__c.getOrgDefaults().RoomTypeBasePlanTierFlag__c == null ? false : CommDefine__c.getOrgDefaults().RoomTypeBasePlanTierFlag__c;}set;}
	// 店舗のラックレート取得
	private Map<String,decimal> getRackRatePriceMap(){
		// 部屋タイプID/ Map<日付, 金額>
		Map<String, Decimal> raceRateMstMap = new Map<String, Decimal>();
		// 取得ラックレート对应的金额
		String queryRaceRateHeader = ' SELECT SearchKey__c, RoomTypeRel__r.ShopInfoRef__c, RoomTypeRel__c, Persons__c, Price__c, Tier__c From RackRateTable__c ';
		// 部屋タイプ毎、日単位の料金情報を初期化する
		for (RackRateTable__c raceRate : DataBase.query(queryRaceRateHeader)) {
			raceRateMstMap.put(raceRate.SearchKey__c, CommUtils.nullToZero(raceRate.Price__c));
		}
		return raceRateMstMap;
	}
	// 根据设定日检索,ラックレート明細
	private Map<String,String> getRackRateDetailMap(Date startDate){
		// roomtype 数据map
		map<String,String> setupRoomTypeTierMap = new map<String,String>();
		String queryRackRateTable = 'Select SearchKey__c,Tier__c,PriceSetupDate__c,RoomTypeRef__c From RackRateTableDetail__c Where PriceSetupDate__c =:startDate ';
		// 2021/06/31 #11783 bug fixed by zy BEGIN
		// 店舗条件
		if (!CommUtils.isBlank(spcd)) {
			queryRackRateTable += ' And ShopInfoRef__r.ShopCode__c = :spcd';
		}
        // 2021/06/31 #11783 bug fixed by zy END
		// 2015/09/01 多店舗機能対応 END
		list<RackRateTableDetail__c> RackRateTableDetailLst = DataBase.query(queryRackRateTable);
		// 处理设定的数据
		for(RackRateTableDetail__c detail : RackRateTableDetailLst){
			String key = CommUtils.nullToBlank(detail.RoomTypeRef__c) + '_' + startDate;
			setupRoomTypeTierMap.put(key, detail.Tier__c);
    	}
		return setupRoomTypeTierMap;
    }
	global static Map<String, Decimal> queryRaceRateInfo (String shopCd, String queryDt) {
		throw new CommException('該当METHODは既に利用廃止');
		return null;
	}
	global Map<String, Decimal> queryRaceRateInfos (String shopCd, String queryDt) {
		throw new CommException('該当METHODは既に利用廃止');
		return null;
	}
	global static Map<String, Decimal> queryRaceRateInfo (String shopCd, Date startDate, Integer daysInMonth) {
		throw new CommException('該当METHODは既に利用廃止');
		return null;
	}
}