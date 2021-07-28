/******************************************
*
* プランの会計商品明細設定画面
* 商品登録順番変わらない様に変更を行う
* 2014/01/08 プランとプラン明細登録は１画面に統一する
* 2015/09/01 多店舗機能対応
* 2017/11/16 店舗別会計商品の対応
* 2019/02/28 ブッキングエンジンは多言語対応
* 2019/08/06 プラン明細入力明細行数をカスタマイズできるように改善対応
*******************************************/
public with sharing class PlanProductSetup extends CommBaseCtrl{
	// 2019/07/15 プラン内に入れたマイナス金額の商品に対応 WGCH BEGIN
	public Boolean planBrkFuSuFlg{get{return CommDefine__c.getOrgDefaults().PlanBreakdownMinusFlg__c == null ? false : CommDefine__c.getOrgDefaults().PlanBreakdownMinusFlg__c;}}
	// 2019/07/15 プラン内に入れたマイナス金額の商品に対応 WGCH END
	public boolean isCanUpdateLead{get{return CommSecurityUtils.isCanUpdateable(Plan__c.sObjectType);}}
	// 10行目の商品設定が可能
	// 2019/08/06 プラン明細入力明細行数をカスタマイズできるように改善対応 WSQ BEGIN
	//private static final Integer DEF_INPUT_ROWS = 10;
	private static final Integer DEF_INPUT_ROWS = CommUtils.nullToZero(CommDefine__c.getOrgDefaults().PDDetailsInputDefaultLines__c) > 0 
													? CommUtils.nullToZero(CommDefine__c.getOrgDefaults().PDDetailsInputDefaultLines__c).intValue()
													: 10;
	// 2019/08/06 プラン明細入力明細行数をカスタマイズできるように改善対応 WSQ END
	// 会計商品の商品コード作成する場合、前方数字：例：Pxxxxコードで自動採番を行う
    private static final String PLAN_PRD_PREX_NUM = 'P';
    // 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
    // プランの入湯税に自動入力フラグ
    public static Boolean isBTaxSetMode{get{ return CommConst.PLAN_BATHTAXAUTOSET_MODE != CommConst.PLAN_BATHTAXAUTOSET_1;} set;}
    // 2020/07/30 入湯税の自動入力機能について改善 WGCH END
	// 室料商品の名前
	private static final String roomPriceProdName = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomPriceProdName__c);
	// 室料登録用商品情報を維持する
	//private ApexPages.StandardController ctrl;
	private Id planId;				// プランID
	private Boolean isCloneFlg;		// CLONEのフラグ
	private String retUrl;			// 返却のURL
	private String orgPlanNo;		// Clone元のプランNO
	private Decimal roomPrice;		// 室料【引き渡す室料の情報を格納して、該当設定値が存在する場合、プラン明細に種別は室料、名前はカスタムに設定する商品名一致する場合、該当プラン明細の金額は引き渡す金額で設定を行う】
									// プランの総金額も自動かけます
	// 商品金額合計値維持する
	//public Decimal productAmount{get; private set;}
	// プラン金額（手入力情報維持する）
	public Decimal productInputAmout{get; set;}
	// POPUP　WINDOW　MODE　FLG( TRUEの場合、ポップモードで画面起動する)
	public Boolean isPopupWinFlg {get; set;}
	// 店舗情報存在標識フラグ
	public List<SelectOption> branchShopIdLst{get; private set;}
	// 店舗別プラン機能利用可否フラグ
	public Boolean isShopPlanSetupFlg {get{ return CommConst.APPOTION_BI_SHOPPLAN_FLG; }}
	// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
	public Boolean bookingApiFieldsShowFlg{get{return CommDefine__c.getOrgDefaults().BookingApiFieldsShowFlg__c == null ? false : CommDefine__c.getOrgDefaults().BookingApiFieldsShowFlg__c;}}
	// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
	public PlanProductSetup(ApexPages.StandardController controller) {
		// プランIDを取得、設定を行う
		planId = controller.getId();
		// Clone Check
		String strClone = ApexPages.currentPage().getParameters().get('clone');
		retUrl = ApexPages.currentPage().getParameters().get('retURL');
		isPopupWinFlg = !CommUtils.isBlank(ApexPages.currentPage().getParameters().get('popup'));	// Window.Openで起動される機能
		isCloneFlg = !CommUtils.isBlank(strClone);
		roomPrice = CommUtils.nullToZero(ApexPages.currentPage().getParameters().get('rp'));		// 室料
		// 新規・編集切り分け
		if (CommUtils.isBlank(planId)) {
			// 新規の場合、プランとプラン明細は一画面に統一作成する
			planInfo = new Plan__c();
			//　明細登録用配列を設定する
			queryPlanDetailInfo();
			// 元のプランNOを格納する
			orgPlanNo = '';
		} else {
			// 編集の場合
			// プラン情報を取得する
			if (queryPlanInfo(planId, false) != true) {
				planInfo = new Plan__c();
				return;
			}
			// プラン明細情報を取得する
			queryPlanDetailInfo();
			// 元のプランNOを格納する
			orgPlanNo = planInfo.PlanNo__c;
		}

		if (isCloneFlg) {
			// CLONEの場合、
			planInfo.Seq__c = null;
			planInfo.PlanNo__c = null;
			// 非公開、ベースプランはクリアする
			planInfo.IsClosed__c = false;
			planInfo.BasePlanFlg__c = false;
			// パッケージコードクリア
			planInfo.PackageCode__c = null;
			orgPlanNo = null;
		}
		// 2015/09/01 多店舗機能対応 BEGIN
		UserUtil.UserShopInfo userInf = UserUtil.CurrentUserInfo;
		// 2015/09/01 多店舗機能対応 END
		// 支店表示情報を取得する
		Map<String,ShopInformation__c> shopMap = ShopInfoUtil.getShopInfoMap();
		//branchShopIdLst = ShopInfoUtil.getBranchShopIdLst();
		branchShopIdLst = new List<SelectOption>();
		// 2015/09/01 多店舗機能対応 BEGIN
		// List<ShopInformation__c> locBranchShopInfLst = ShopInfoUtil.getBranchShopInfLst();
		List<ShopInformation__c> locBranchShopInfLst = ShopInfoUtil.getBranchShopInfLst(userInf.shops);
		// 2015/09/01 多店舗機能対応 END
		for (ShopInformation__c shop : locBranchShopInfLst) {
			branchShopIdLst.add(new SelectOption(shop.Id, shop.ShopCode__c + '_' + shop.Name));
		}
		if (planInfo.Id == null) {
			ShopInformation__c shop = shopMap.get(UserUtil.CurrentUser.ShopCode__c);
			if (shop != null) planInfo.ShopInfoRef__c = shop.Id;
		}
	}
	
	
	// プラン基本情報
	public Plan__c planInfo{get; private set;}
	// プラン金額
	public String strPlanPrice{get{
		return (planInfo.Price__c == null ? '' : CommUtils.deleteRightZero(CommUtils.nullToBlank(planInfo.Price__c.format()),CommUtils.getPointLen()));
	} set{
		strPlanPrice = value;
		planInfo.Price__c = CommUtils.nullToZero(strPlanPrice);
	}}
	//public AccountMaster__c planProductInfo{get; private set;}
	// プラン明細
	public List<PlanDetail> planDetailList{get; private set;}
	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
	public String OPTION_MODE{get{ return CommConst.OPTION_MODE;}}
	public static boolean isReducedTaxFlg{get{ return CommConst.REDUCED_TAXRATE_FLG;} private set;}
	// OPTIONプラン明細
	public List<PlanDetail> optPlanDetailList{get; private set;}
	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
	// --------------------
	// プラン基本情報を取得する
	// --------------------
	private Boolean queryPlanInfo(String planId, Boolean isLock) {
		List<Plan__c> planInfoLst = null;
		// 2018/01/23 BookingAPI プラン詳細情報追加 by zh BEGIN
		//String queryStr = 'select id, PlanStartDateandtime__c,Planclosedateandtime__c, Name, client__c,PackageCode__c,IsClosed__c,Seq__c, PlanNo__c, JmstRef__c, JmstRef__r.TaxRate__c ,ServiceRate__c, DpRef__c, GpRef__c, Price__c,Comment__c,BasePlanFlg__c,ShopInfoRef__c from Plan__c where id = :planId limit 1';
		// 2018/03/14 BookingAPI プラン詳細情報追加 BEGIN
		//String queryStr = 'select id, PlanStartDateandtime__c,Planclosedateandtime__c, Name, client__c,PackageCode__c,IsClosed__c,Seq__c, PlanNo__c, JmstRef__c, JmstRef__r.TaxRate__c ,ServiceRate__c, DpRef__c, GpRef__c, Price__c,Comment__c,BasePlanFlg__c,ShopInfoRef__c,PropRef__c from Plan__c where id = :planId limit 1';
		// 2019/02/28 ブッキングエンジンは多言語対応 By zh BEGIN
		//String queryStr = 'select id, MealMemo__c,PlanStartDateandtime__c,Planclosedateandtime__c, Name, client__c,PackageCode__c,IsClosed__c,Seq__c, PlanNo__c, JmstRef__c, JmstRef__r.TaxRate__c ,ServiceRate__c, DpRef__c, GpRef__c, Price__c,Comment__c,BasePlanFlg__c,ShopInfoRef__c,PropRef__c from Plan__c where id = :planId limit 1';
		// 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
		String queryStr = 'select id, MealMemo__c,PlanStartDateandtime__c,Planclosedateandtime__c, Name, client__c,PackageCode__c,IsClosed__c,Seq__c, PlanNo__c, JmstRef__c, JmstRef__r.TaxRate__c ,ServiceRate__c, DpRef__c, GpRef__c, Price__c,Comment__c,BasePlanFlg__c,ShopInfoRef__c,PropRef__c,EnMealMemo__c,EnName__c,BathTaxAccMstRef__c from Plan__c where id = :planId limit 1';
		// 2020/07/30 入湯税の自動入力機能について改善 WGCH END
		// 2019/02/28 ブッキングエンジンは多言語対応 By zh END
		// 2018/03/14 BookingAPI プラン詳細情報追加 BEGIN
		// 2018/01/23 BookingAPI プラン詳細情報追加 by zh END
		if (isLock) {
			// Data Lock
			//planInfoLst = [select id, Name, client__c,PackageCode__c,IsClosed__c,Seq__c, PlanNo__c, JmstRef__c, JmstRef__r.TaxRate__c ,ServiceRate__c, DpRef__c, GpRef__c, Price__c,Comment__c,BasePlanFlg__c,ShopInfoRef__c from Plan__c where id = :planId limit 1 for update];
			queryStr += ' for update';
		} else {
			// Data Query
			//planInfoLst = [select id, Name, client__c,PackageCode__c,IsClosed__c,Seq__c, PlanNo__c, JmstRef__c, JmstRef__r.TaxRate__c ,ServiceRate__c, DpRef__c, GpRef__c, Price__c,Comment__c,BasePlanFlg__c,ShopInfoRef__c from Plan__c where id = :planId limit 1 ];
		}
		planInfoLst = DataBase.query(queryStr);
		// データが非存在する場合
		if (planInfoLst.isEmpty()) {
			//指定してプラン情報を見つかりません。
			Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_009_0032));
			return false;
		}
		planInfo = planInfoLst[0];
		return true;
	}
	/**
	* プランから会計商品プラン情報を取得する
	**/
	private AccountMaster__c queryPlanProductInfo(Plan__c plan, String pOrgPlanNo) {
		// 会計商品（プラン）情報を取得する
		// プランと同じ商品コードのデータを取得する[単価、商品コード、リンクＤＰコード、#GP、]
		// 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
		List<AccountMaster__c> productLst = [select id, name, Field5__c, Field3__c, Field4__c, GPChange__c, ServiceRate__c, jmstRef__c,PlanAutoSyncChk__c,BasePlanFlg__c,PlanBathTaxAccMstRef__c From AccountMaster__c
		// 2020/07/30 入湯税の自動入力機能について改善 WGCH END
			where Field3__c = :getPlanProdCode(CommUtils.isBlank(orgPlanNo) ? plan.PlanNo__c : orgPlanNo) And ActionType__c = :CommConst.PROD_ACTION_TYPE_PL limit 1];
		if (productLst.isEmpty()) return null;
		return productLst[0];
	}
	/*
	* プランから、すでに設定された商品情報を取得する
	*/
	private void queryPlanDetailInfo () {
		// 金額と入力金額初期化する
		//productAmount = 0;
		productInputAmout = 0;

		// 会計商品（プラン）情報を取得する
		//queryPlanProductInfo();
		// プラン明細一覧情報を維持する
		planDetailList = new List<PlanDetail>();
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
		optPlanDetailList = new List<PlanDetail>();
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
		// 室料商品存在するがどうか判別用フラグ
		Boolean isHaveRoomPriceProdu = false;
		// プランが存在する場合
		if (!CommUtils.isBlank(planId)) {
			// 明細一覧を検索する
			for ( PlanDetail__c sobj : [select Name, PlanRef__c, AccountMasterRef__c, AccountMasterRef__r.Name ,TaxRate__c,
			                            AccountMasterRef__r.Field5__c, JmstRef__c, ServiceRate__c, Price__c, ProductNumber__c, PlanProdcut__c,
			                            AccountMasterRef__r.ActionType__c
			                            // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
			                            ,Amount__c ,OptionAccMstFLG__c
			                            // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
				from PlanDetail__c where PlanRef__c = :planId]) {
				// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
				if(sobj.OptionAccMstFLG__c && isReducedTaxFlg && OPTION_MODE == CommConst.OPTION_MODE_ON){
					optPlanDetailList.add(new PlanDetail((isCloneFlg ? sobj.clone(false, true) : sobj), optPlanDetailList.size()));
					continue;
				}
				// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
				// Readonly制御
				Boolean isReadonly = false;
				// 室料引き渡す場合
				if (roomPrice > 0 && isPopupWinFlg) {
					// 室料　＆＆　商品名は室料の商品名と一致する
					if (sobj.AccountMasterRef__r.ActionType__c == CommConst.PROD_ACTION_TYPE_RP &&
						sobj.AccountMasterRef__r.Name == roomPriceProdName) {
						// 室料設定を行う
						sobj.Price__c = roomPrice;
						isHaveRoomPriceProdu = true;
						isReadonly = true;
					}
				} 
				// 詳細情報を設定を行う
				planDetailList.add(new PlanDetail((isCloneFlg ? sobj.clone(false, true) : sobj), planDetailList.size()));
				planDetailList.get(planDetailList.size()-1).isReadonly = isReadonly;
				// 商品の単価(手入力)で金額を合計する
				productInputAmout += CommUtils.nullToZero(sobj.Price__c);
			}
			/*
			// 合計処理を行う
	        for (PlanDetail dl : planDetailList) {
	            productAmount += dl.amoutIncTax;
	        }*/
		}
		// 既存データ以外の自動追加
		if (planDetailList.size() < DEF_INPUT_ROWS) {
			Integer appendRsSize = DEF_INPUT_ROWS - planDetailList.size();
			// 2行目まで設定を行う
			for (Integer i = 0; i < appendRsSize; i++) {
				planDetailList.add(new PlanDetail(new PlanDetail__c(PlanRef__c = planId, Price__c = null),planDetailList.size()));
			}
		}
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
		// 既存データ以外の自動追加
		if (optPlanDetailList.size() < DEF_INPUT_ROWS && isReducedTaxFlg && OPTION_MODE == CommConst.OPTION_MODE_ON) {
			Integer appendRsSize = DEF_INPUT_ROWS - optPlanDetailList.size();
			// 2行目まで設定を行う
			for (Integer i = 0; i < appendRsSize; i++) {
				optPlanDetailList.add(new PlanDetail(new PlanDetail__c(PlanRef__c = planId, Price__c = null),optPlanDetailList.size()));
			}
		}
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
		if(optPlanDetailList != null && planDetailList != null){
			for(PlanDetail opt : optPlanDetailList){
				// 重置RowNo
				opt.rowNo += planDetailList.size();
			}
		}
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
		// 室料ありの場合、引き渡すの室料にて、プランの金額へ加算する
		// プランはベースプランのみ
		if (isHaveRoomPriceProdu) {
			planInfo.Price__c = CommUtils.nullToZero(planInfo.Price__c) + roomPrice;
		}
	}
	/**
	* 画面戻ります
	**/
	public Pagereference gotoBlack() {
		if (isPopupWinFlg) {
			return null;
		}
		Pagereference page = new Pagereference('/' + planId);
		if (!isCloneFlg && !CommUtils.isBlank(retUrl)) page = new Pagereference(retUrl);
		page.setRedirect(true);
		return page;
	}
    /**
    * 商品コード採番を行う
    * プラン商品登録場合、商品コードを取得する
    **//*
    private String generPlanProdNo() {
    	// 既存のプラン商品の最大番号を取得する
    	// 商品コードは最大4桁まで取得する、9999を超えると、0000に戻ります
    	Integer maxProdCode = Integer.valueOf(PLAN_PRD_PREX_NUM + String.valueOf(9999));
    	Integer startCode = 1;
    	Integer maxCdLen = 4;
    	// 商品種別はプランの最大商品コードを取得する（重複存在チェックを行う?）
    	List<AccountMaster__c> maxAccMst = [select nextitemcode__c from AccountMaster__c
    	   where ActionType__c = :CommConst.PROD_ACTION_TYPE_PL Order By nextitemcode__c desc limit 1];
        if (maxAccMst.isEmpty()) return PLAN_PRD_PREX_NUM + CommUtils.paddingLeftZero(startCode, maxCdLen);
        Decimal prodCd = maxAccMst[0].nextitemcode__c;
        if (prodCd == null || prodCd == 0) return PLAN_PRD_PREX_NUM + CommUtils.paddingLeftZero(startCode, maxCdLen);
        else {
        	// 最大値になる場合、0001に戻る
        	if (prodCd + 1 >= maxProdCode) return PLAN_PRD_PREX_NUM + CommUtils.paddingLeftZero(startCode, maxCdLen);
        	// 以外の場合、通常に番号を増える
        	return String.valueOf(prodCd + 1);
        }
    }*/
    
    /**
    * プラン登録の事前チェック
    * 1:プラン明細は１件以上の登録が必要
    **/
    private Boolean preSavePlanDetail() {
    	// 新規登録する場合、SEQ__C重複チェックを行う
    	// プラン名必須チェック Plan: 値を入力してください
    	if (CommUtils.isBlank(planInfo.Name)) {
    		//Plan値を入力してください。
    		Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_009_0033));
    	}
    	if (planInfo.Seq__c != null) {
    		Decimal seq = planInfo.Seq__c;
    		String queryChkSql = ' Select Id,Name From Plan__c where Seq__c = :seq ';
    		if (!CommUtils.isBlank(planId)) queryChkSql += ' And Id != :planId ';
    		List<Plan__c> existPlans = DataBase.query(queryChkSql);
    		if (!existPlans.isEmpty()) {
    			//Seq#値が重複しているため、登録できません。
 				Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_009_0034));
				//return false;
    		}
    	}
    	// プラン明細存在チェックを行う
    	Integer validateRsNum = 0;
		for (PlanDetail item : planDetailList) {
			// 有効対象場合
			if (item.isValidata) validateRsNum++;
		}
		if (validateRsNum == 0) {
			//明細設定情報は１件以上入力してください。
			Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_009_0035));
			//return false;
		}
		if (Apexpages.hasMessages(ApexPages.Severity.ERROR)) return false;
		return true;
    }
	/*
	* プラン情報を登録する
	*/
	public Pagereference savePlanDetail() {
		// 2018/03/07 Security Check BEGIN
		List<String> chkFields = new List<String>{'PlanRef__c','PlanProdcut__c','Name','Price__c'};
		Map<String,Schema.SObjectField> m = Schema.SObjectType.PlanDetail__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFields, m)) {
			return null;
		}
		List<String> chkFields1 = new List<String>{'ShopInfoRef__c','Seq__c','PlanNo__c','PackageCode__c','IsClosed__c','BasePlanFlg__c','PlanStartDateandtime__c','Planclosedateandtime__c'};
		Map<String,Schema.SObjectField> m1 = Schema.SObjectType.Plan__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFields1, m1)) {
			return null;
		}
		// 2018/03/07 Security Check END
		// 登録前の事前チェック
		if (!preSavePlanDetail()) {
			return null;
		}
		Savepoint sp = Database.setSavepoint();
		// プラン情報を取得する
		try {
			// Cloneからデータを作成する場合、プランは新規登録を行う
			if (isCloneFlg) planInfo.Id = null;
			// プラン情報を更新する
            // 2017/06/26 PlanNo重複問題対応 BEGIN
            planInfo.UIEventSource__c = true;
            // 2017/06/26 PlanNo重複問題対応 END
			upsert planInfo;
			// 新規作成したプラン情報IDを設定する
			planId = planInfo.Id;
			// 登録後の最新プラン情報を取得する
			queryPlanInfo(planId, true);

		} catch (Exception e) {
			DataBase.rollback(sp);
			if (!CommUtils.isFieldValidationMessage(e.getMessage())) {
				Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
			}
			return null;
		}
System.debug(LoggingLevel.INFO, 'orgPlanNo:::' + orgPlanNo);
		// 会計商品（プラン）最新情報を取得する
		AccountMaster__c planProductInfo = this.queryPlanProductInfo(planInfo, orgPlanNo);
		
		try {
		// 2018/03/07 Security Check BEGIN
		List<String> chkFieldsLst = new List<String>{'planautosyncchk__c','IsClosed__c','BasePlanFlg__c','jmstRef__c','ServiceRate__c',
												'GPChange__c','Field4__c','Field5__c','Field3__c','Name'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.AccountMaster__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(chkFieldsLst, mm)) {
			return null;
		}
		// 2018/03/07 Security Check END
		// 2019/09/15 Security Check BY zyz BEGIN
		if (!CommSecurityUtils.isDeleteable(PlanDetail__c.getSObjectType())) {
			return null;
		}
		// 2019/09/15 Security Check BY zyz END
        // 会計商品（プラン）は未存在する場合、自動新規プラン商品を作成する、
		if (planProductInfo == null) {
			// 商品コードを取得する(自動採番)
			//String newProdCode = generPlanProdNo();
			// 新規情報を設定を行う
			planProductInfo = new AccountMaster__c(
				Name = planInfo.Name,
				Field3__c = getPlanProdCode(planInfo.PlanNo__c),		// 商品コード：プランコード
				Field5__c = planInfo.Price__c,
				Field4__c  = planInfo.DpRef__c,
				GPChange__c = planInfo.GpRef__c,
				ServiceRate__c = planInfo.ServiceRate__c,
				jmstRef__c = planInfo.JmstRef__c,
				BasePlanFlg__c = planInfo.BasePlanFlg__c,
				// 2016/11/30 トリガー自動機能は廃止ため、下記連携項目を追加する BEGIN
				IsClosed__c = planInfo.IsClosed__c,
				// 2016/11/30 トリガー自動機能は廃止ため、下記連携項目を追加する END
				// 2017/11/16 店舗別会計商品の対応 BEGIN
				ShopInfoRef__c = planInfo.ShopInfoRef__c,
				// 2017/11/16 店舗別会計商品の対応 END
				// 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
				PlanBathTaxAccMstRef__c = planInfo.Id,
				// 2020/07/30 入湯税の自動入力機能について改善 WGCH END
				ActionType__c = CommConst.PROD_ACTION_TYPE_PL);
			insert planProductInfo;
		} else {
			// すでに存在する会計商品（プラン）情報を再取得、確認を行う
			planProductInfo.Name = planInfo.Name;
			planProductInfo.Field3__c = getPlanProdCode(planInfo.PlanNo__c);		// 商品コード：プランコード
			planProductInfo.Field5__c = planInfo.Price__c;
			planProductInfo.Field4__c  = planInfo.DpRef__c;
			planProductInfo.GPChange__c = planInfo.GpRef__c;
			planProductInfo.ServiceRate__c = planInfo.ServiceRate__c;
            planProductInfo.jmstRef__c = planInfo.JmstRef__c;
            planProductInfo.BasePlanFlg__c = planInfo.BasePlanFlg__c;
			// 2016/11/30 トリガー自動機能は廃止ため、下記連携項目を追加する BEGIN
			planProductInfo.IsClosed__c = planInfo.IsClosed__c;
			// 2016/11/30 トリガー自動機能は廃止ため、下記連携項目を追加する END
			// 2017/11/16 店舗別会計商品の対応 BEGIN
			planProductInfo.ShopInfoRef__c = planInfo.ShopInfoRef__c;
			// 2017/11/16 店舗別会計商品の対応 END
			// 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
			planProductInfo.PlanBathTaxAccMstRef__c = planInfo.Id;
			// 2020/07/30 入湯税の自動入力機能について改善 WGCH END
            planProductInfo.PlanAutoSyncChk__c = !(planProductInfo.PlanAutoSyncChk__c);
            update planProductInfo;
		}
		//Database.upsert (planProductInfo, AccountMaster__c.Field3__c);
		// プラン明細を再作成する
		//List<PlanDetail__c> insLst = new List<PlanDetail__c>();
		//List<PlanDetail__c> updLst = new List<PlanDetail__c>();
		List<PlanDetail__c> upsertLst = new List<PlanDetail__c>();
		List<PlanDetail__c> delLst = new List<PlanDetail__c>();
		for (PlanDetail item : planDetailList) {
			// 削除対象場合
			if (item.isDeleteItem) delLst.add(item.sobj);
			// 無効対象場合
			if (!item.isValidata) continue;
			// 更新対象場合
			if (item.isUpdateItem) {
				// 2016.06.30 80桁まで設定する
				//item.sobj.name = planInfo.Name + '-' + item.rowNo;
				item.sobj.name = CommUtils.nullToBlank(planInfo.Name + '-' + item.rowNo).left(80);
				item.sobj.PlanProdcut__c = planProductInfo.Id;
				item.sobj.PlanRef__c = planInfo.Id;
				//updLst.add(item.sobj);
				upsertLst.add(item.sobj);
			}
			// 新規対象場合
			if (item.isInsertItem) {
				item.sobj.PlanProdcut__c = planProductInfo.Id;
				// 2016.06.30 80桁まで設定する
				//item.sobj.Name = planInfo.Name + '-' + item.rowNo;
				item.sobj.Name = CommUtils.nullToBlank(planInfo.Name + '-' + item.rowNo).left(80);
				item.sobj.PlanRef__c = planInfo.Id;
				//insLst.add(item.sobj);
				upsertLst.add(item.sobj);
			}
		}
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
		if(OPTION_MODE == CommConst.OPTION_MODE_ON){
			for (PlanDetail item : optPlanDetailList) {
				// 削除対象場合
				if (item.isDeleteItem) delLst.add(item.sobj);
				// 無効対象場合
				if (!item.isValidata) continue;
				// 更新対象場合
				if (item.isUpdateItem) {
					// 2016.06.30 80桁まで設定する
					//item.sobj.name = planInfo.Name + '-' + item.rowNo;
					item.sobj.name = CommUtils.nullToBlank(planInfo.Name + '-' + item.rowNo).left(80);
					item.sobj.PlanProdcut__c = planProductInfo.Id;
					item.sobj.PlanRef__c = planInfo.Id;
					item.sobj.OptionAccMstFLG__c = true;
					//updLst.add(item.sobj);
					upsertLst.add(item.sobj);
				}
				// 新規対象場合
				if (item.isInsertItem) {
					item.sobj.PlanProdcut__c = planProductInfo.Id;
					// 2016.06.30 80桁まで設定する
					//item.sobj.Name = planInfo.Name + '-' + item.rowNo;
					item.sobj.Name = CommUtils.nullToBlank(planInfo.Name + '-' + item.rowNo).left(80);
					item.sobj.PlanRef__c = planInfo.Id;
					item.sobj.OptionAccMstFLG__c = true;
					//insLst.add(item.sobj);
					upsertLst.add(item.sobj);
				}
			}
		}
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END

		//if (!insLst.isEmpty()) insert insLst;
		//if (!updLst.isEmpty()) update updLst;
		if (!upsertLst.isEmpty()) database.upsert(upsertLst);
		if (!delLst.isEmpty()) delete delLst;
		} catch (Exception e) {
			DataBase.rollback(sp);
			if (!CommUtils.isFieldValidationMessage(e.getMessage())) {
				Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
			}
			return null;
		}
		// 最新情報を取得する
		queryPlanDetailInfo();
		
		// Clone Flg Setup
		//isCloneFlg = false;
		// 元のプランNOを格納する
		orgPlanNo = planInfo.PlanNo__c;
		// DB反映成功の場合、DB保存済みフラグを設定する
		jsIsSaveFinishFlg = String.valueOf(true);
		
		return gotoBlack();
	}
	// 保存処理成功完了フラグ
	public String jsIsSaveFinishFlg{get; private set;}
	public String jsIsPopupWinFlg{get{ return String.valueOf(isPopupWinFlg);}}
	// 会計商品プランの商品コードを取得する
	public static String getPlanProdCode(String planCd) {
		return PLAN_PRD_PREX_NUM + planCd;
	}
	@remoteAction
	public static List<ProductItemUtils.ProductItem> getArrayProductItemInfo(String prodCode) {
		// 2014/07/18 プラン明細設定画面にプランを選べない様に変更対応
		//return ProductItemUtils.getArrayProdcutItemByCode(prodCode);
		// 2015/07/07 プラン明細設定画面に支払情報を選べれない様に変更対応
		//return ProductItemUtils.getArrayProdcutItemByCode(prodCode, true);
		return ProductItemUtils.getArrayProdcutItemByCode(prodCode, true, true);
	}
	/**
	* プラン詳細情報　
	**/
	public class PlanDetail {
		public PlanDetail(PlanDetail__c item, Integer index) {
			sobj = item;
			rowNo = index;
			productNm = item.AccountMasterRef__r.Name;
			//oldProdcutId = sobj.AccountMasterRef__c;
			//oldPrice = sobj.Price__c;
			oldId = sobj.id;
/* 20121005修正を行う（商品単価多目意味機能対応） */
/*
			// 元商品単価（税込） * 現在のサービス料
			amoutIncTax = CommUtils.nullToZero(item.AccountMasterRef__r.Field5__c) +
			              CommUtils.nullToZero(item.AccountMasterRef__r.Field5__c) * (CommUtils.nullToZero(item.ServiceRate__c) / 100);
*/
			// 消費税小数点処理
			//sobj.TaxRate__c = CommUtils.nullToZero(CommUtils.deleteRightZero(String.valueOf(sobj.TaxRate__c), CommUtils.getTaxPointLen()));
			// 単価値
			productPrice = CommUtils.nullToZero(item.AccountMasterRef__r.Field5__c);
			
			CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo();
			priceInfo.process(productPrice, 1, CommUtils.nullToZero(item.TaxRate__c), CommUtils.nullToZero(item.ServiceRate__c));
			amoutIncTax = priceInfo.priceIncTax;
			
			diffPrice = amoutIncTax - CommUtils.nullToZero(item.Price__c);
			
			// 金額小数点機能対応
			strSummary = ( sobj.Price__c == null ? '' : CommUtils.deleteRightZero(CommUtils.nullToZero(sobj.Price__c).format(), CommUtils.getPointLen()));
			strTaxRate = ( sobj.TaxRate__c == null ? '' : CommUtils.deleteRightZero(
															CommUtils.nullToBlank(CommUtils.nullToZero(sobj.TaxRate__c)), CommUtils.getTaxPointLen()
															) + '%');
		}
		// 見積明細
		public PlanDetail__c sobj{get;private set;}
		// 行番号
		public Integer rowNo{get;set;}
		// 商品名
		public String productNm{get;set;}
		// 商品単価
		public Decimal productPrice{get;set;}
		// 元商品単価金額の合計値
		public Decimal amoutIncTax{get; set;}
		// 合計値と入力した金額の差額値
		public Decimal diffPrice{get;set;}
		// 1商品の金額合計
		public String strSummary{get;set{
			strSummary = value;
			sobj.Price__c = CommUtils.nullToZero(strSummary);
		}}
		// 消費税率
		public String strTaxRate{get;set{
			strTaxRate = value;
			sobj.TaxRate__c = CommUtils.nullToZero(strTaxRate.removeEnd('%'));
		}}
		// 変更前の設定値
		//private Decimal oldPrice;
		//private Id      oldProdcutId;
		private Id      oldId;
		// 明細データ変更あり、なし判断を行う
		/*
		private Boolean isChange() {
			return (oldProdcutId != sobj.AccountMasterRef__c ||
				oldPrice != sobj.Price__c );
		}*/
		// 室料項目がどうか判別フラグ/室料はベースプラン個別設定する場合、室料の行目に参照のみに設定する
		public Boolean isReadonly{get; set;}
		// 有効の入力データ
		public Boolean isValidata{get{return (!CommUtils.isBlank(productNm) && sobj.Price__c != null);}}
		// 新規対象[既存ID未設定する場合]
		public Boolean isInsertItem{get{return (oldId == null && isValidata);}}
		// 更新対象[有効データ　&&　oldI 存在　&& ProdcutId変更]
		public Boolean isUpdateItem{get{return (oldId != null && isValidata);}}
		// 削除対象[既存IDあり、無効データに変更する場合]
		public Boolean isDeleteItem{get{return (sobj.id != null && !isValidata);}}
	}

}