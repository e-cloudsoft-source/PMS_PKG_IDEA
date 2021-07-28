/**
* 会計商品関連情報検索を行う
* 2016/10/27 性能改善対応
* 2018/10/24 見積明細自動計算機能対応
**/
public with sharing class ProductSearch_Ctrl extends CommBaseCtrl{
	// 2016/10/27 性能改善対応 BEGIN
    // 画面に表示する情報を格納用変数
	public transient List<AccountMaster__c> oProductLst{get;private set;}
    // 条件により、全部抽出した会計商品ID配列　
    private transient list<AccountMaster__c> wkProductLst;
    // 2016/10/27 性能改善対応 END
    // 商品DP選択リスト
    public List<Selectoption> dpOptionLst{get; private set;}
    public List<Selectoption> gpOptionLst{get; private set;}
//    public List<Selectoption> opOptionLst{get; private set;}
	/***************************
	* 定数定義を行う
	****************************/
    // 画面データ処理ステータス変数
    private Enum PAGE_STATUS {INS,UPD,SEL,UPDSPEC}
    public PAGE_STATUS pageStatus{get;private set;}
    public Boolean isIns{get{return pageStatus == PAGE_STATUS.INS;}}
    public Boolean isUpd{get{return pageStatus == PAGE_STATUS.UPD;}}
    public Boolean isSel{get{return pageStatus == PAGE_STATUS.SEL;}}
    // 新規商品格納用クラス
    public AccountMaster__c newAccMst{get;set;} 
    public transient Map<String,DetailInfo> planMap{get;set;}
    // 改ページ機能対応
    public PaginationUtil pageCtrl{get; set;}
    // Sobject Name(NameSapece)
    private String sobjectName;
    // 2017/10/17 商品情報店舗別を検索を行う by zh BEGIN
    // 店舗別商品機能フラグ
    public Boolean shopAccountSetupFlg{get{return (CommConst.PROD_SHOPSEARCH_DIV_IS);}}
    // 現在ログインユーザー情報
    private final UserUtil.UserShopInfo userInf;
    private Set<String> shopSt;
    // 店舗リスト/店舗コード
    public List<SelectOption> branchShopLst{get; private set;}
    public String branchShopNm{get; set;}
    // 2017/10/17 商品情報店舗別を検索を行う by zh END
    // 2019/11/15 最近利用している商品一覧機能を提供する BY zyz BEGIN
    // 商品是否区分功能控制开关：直接写死的，暂时未追加
    public Boolean splitFlg{get;set;}
    // 2019/11/15 最近利用している商品一覧機能を提供する BY zyz END
    // 初期化
    public ProductSearch_Ctrl() {
        // パラメータ分析する
        initParam();
        // 格納変数を初期化する
        oProductLst = new List<AccountMaster__c>();
        
		// 商品分類選択リストを設定を行う
		dpOptionLst = new List<Selectoption>();
		gpOptionLst = new List<Selectoption>();
//		opOptionLst = new List<Selectoption>();
		for (DP__c s: [select id, name, Field1__c from DP__c where IsClosed__c != true order by Name limit 500]) dpOptionLst.add(new SelectOption(s.id, s.Name));
		for (GP__c s: [select id, name, Field1__c from GP__c where IsClosed__c != true order by Name limit 500]) gpOptionLst.add(new SelectOption(s.id, s.Name));
//		for (OP__c s: [select id, name, Field1__c from OP__c order by Name limit 500]) opOptionLst.add(new SelectOption(s.id, s.Name));
    
    	Schema.DescribeSObjectResult R = AccountMaster__c.SObjectType.getDescribe();
    	sobjectName = R.getName();
    	//planMap = new Map<String,DetailInfo>();
        // 2017/10/17 商品情報店舗別を検索を行う by zh BEGIN
        if (shopAccountSetupFlg) {
            // ユーザINFO
            userInf = UserUtil.CurrentUserInfo;
            // 多店舗情報格納する
            shopSt = userInf.shopSt;
            // 店舗情報作成
            setInitBranShopLst();
        }
        // 2017/10/17 商品情報店舗別を検索を行う by zh END
    }
    // 初期化処理呼び出す
    public void init() {
        // 2019/11/15 最近利用している商品一覧機能を提供する BY zyz BEGIN
        accMasterStr = 'Viewed';
        splitFlg = true;
        // 2019/11/15 最近利用している商品一覧機能を提供する BY zyz END
    	// 会計商品検索を行う
        this.queryInfo();
    }
    // 2017/10/17 商品情報店舗別を検索を行う by zh BEGIN
    // 店舗リストを設定する
    private void setInitBranShopLst() {
    	// 2017/10/17 商品情報店舗別を検索を行う by zh BEGIN
        branchShopLst = ShopInfoUtil.getBranchShopLst(userInf.shops);
        if (!branchShopLst.isEmpty()) {
            // 顧客に設定する支店で初期値に設定する[2013/06/30]
            String locShopCode = UserUtil.CurrentUser.ShopCode__c;
            for (SelectOption s : branchShopLst) {
                if (s.getValue() == locShopCode) branchShopNm = locShopCode;
            }
        }
        Cookie shopNmCookie = ApexPages.currentPage().getCookies().get('_produ_shopNm');
		if (shopNmCookie != null) branchShopNm = shopNmCookie.getValue();
    }
    // 2017/10/17 商品情報店舗別を検索を行う by zh END
	// 新規作成FORM起動する
	public void insertInit() {
    	// 画面ページステータス設定を行う
    	pageStatus = PAGE_STATUS.INS;
    	newAccMst = new AccountMaster__c();
	}
	// 新規データ作成を行う
	public void insertData() {
		try {
			insert newAccMst;
		} catch (Exception e) {
			//新規作成が失敗しました。
	        Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_009_0036, e.getmessage()));
		}
		// 最新情報を再設定をこなう
		String newAccId = newAccMst.Id;
		// 2021/01/12 #9612 bug fix BY zyz BEGIN
		String SQL_OPTION = ',PlanBathTaxAccMstRef__c,PlanBathTaxAccMstRef__r.BathTaxAccMstRef__c';
		String newInfSql = ' Select ' + SQL_QUERYFIELD + ' From AccountMaster__c where id = :newAccId ';
		// 2021/01/12 #9612 bug fix BY zyz END
		newAccMst = DataBase.query(newInfSql);//[select Id, Name, Field5__c, TaxRateCal__c, ServiceRate__c, SpecialTax__c, ActionType__c From AccountMaster__c where id = :newAccMst.Id][0];
        DetailInfo info = new DetailInfo(0,false);
        planMap = new Map<String,DetailInfo>();
		// 2021/01/12 #9612 bug fix BY zyz BEGIN
		newAccMst.PlanBathTaxAccMstRef__c = null;
		newAccMst.PlanBathTaxAccMstRef__r = new Plan__c(); 
		setPDetailMapInfo(new list<AccountMaster__c>{newAccMst});
		// 2021/01/12 #9612 bug fix BY zyz END
        planMap.put(newAccId,info);
		pageStatus = PAGE_STATUS.UPD;
	}
	// キャンセル処理
	public void cancelAct() {
		this.queryInfo();
	}
	/*
    // 引渡しパラメータ情報
    public String p_operWinEleId{get;private set;}
    public String p_operWinEleNm{get;private set;}
    public String p_operWinEleHidNm{get;private set;}
    public String p_operWinElePrice{get;set;}
    public String p_operWinEleNum{get;set;}
    public String p_operWinEleTax{get;set;}*/
    // 親のJSを呼び出し関数名
    public String p_operWinJsFunNm{get;private set;}
    // 検索条件：商品名
    public String c_productNm{get;set;}
    public String c_gpId{get;set;}
    public String c_dpId{get;set;}
//    public String c_opId{get;set;}
    private Boolean isShowPlanProduFlg = true;		// 会計商品（プラン）が検索対象制御フラグ TRUE:会計商品プランは対象する
    private Boolean isShowPayProduFLg = true;
    private boolean isPriceAndRoomFlg = false;
    // 引渡しパラメータ分析する
    private void initParam() {
    	/*
        PageReference pageRef = ApexPages.currentPage();
        // 設定するID
        p_operWinEleId = pageRef.getParameters().get('lkid');
        p_operWinEleNm = pageRef.getParameters().get('lknm');
        p_operWinEleHidNm = pageRef.getParameters().get('lkhidnm');
        p_operWinElePrice = pageRef.getParameters().get('lprice');
        p_operWinEleNum = pageRef.getParameters().get('lnumber');
        p_operWinEleTax = pageRef.getParameters().get('ltaxRate');
        // window.oper.xxx function name
        p_operWinJsFunNm = pageRef.getParameters().get('operJs');
        */
        Cookie dpidCookie = ApexPages.currentPage().getCookies().get('_produ_dpid');
        if (dpidCookie != null) c_dpId = dpidCookie.getValue();
        Cookie gpidCookie = ApexPages.currentPage().getCookies().get('_produ_gpId');
        if (gpidCookie != null) c_gpId = gpidCookie.getValue();
        // 会計商品（プラン）非表示制御パラメータ
        isShowPlanProduFlg = CommUtils.isBlank(ApexPages.currentPage().getParameters().get('np'));
        // 会計商品（支払）非表示制御フラグ
        isShowPayProduFLg = CommUtils.isBlank(ApexPages.currentPage().getParameters().get('npy'));
        isPriceAndRoomFlg = !CommUtils.isBlank(ApexPages.currentPage().getParameters().get('par'));
        // 2018/05/11 ラックレート設定の自動なしの場合故障修正 by ZY BEGIN
        isNeedSyncFlag = !CommUtils.isBlank(ApexPages.currentPage().getParameters().get('sync'));
        // 2018/05/11 ラックレート設定の自動なしの場合故障修正 by ZY END
        // 2018/08/29 会席設定追加追加 by zy BEGIN
  		isDinnerFlag = ApexPages.currentPage().getParameters().containsKey('dinner');
        // 2018/08/29 会席設定追加追加 by zy END
        // 2018/10/04 原価金額を返却する WSQ BEGIN
        isBasePriceFlg = ApexPages.currentPage().getParameters().containsKey('bp');
        // 2018/10/04 原価金額を返却する WSQ END
        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
        isOptionPgFlg = ApexPages.currentPage().getParameters().containsKey('op');
        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
    }
    
    /*
    private static final String SQL_HEADER = 'Select Id ,TaxRateCal__c ,Name, ServiceRate__c, SpecialTax__c, ActionType__c ' + 
    										 ',DPChange__c ,Field10__c ,Field11__c ,Field12__c ,Field13_del__c ,Field2__c ,Field3__c ,Field4__c ' +
    										 ',Field5__c ,Field6__c ,Field7__c ,Field8__c ,Field9__c ,GPChange__c ,Genkaritsu__c ,KD__c ,OES__c ,OP__c ,PLU__c ,Profit__c ,SCP_5__c ' +
    										 ',SalesnoneTax__c ,StsTaxfee__c ,X1__c ,X3_2__c ,X4_3__c ,detail13__c ,nextitemcode__c ,proftPer__c ' +
    										 ' From AccountMaster__c where BasePlanFlg__c = false And name != null And IsClosed__c != true And ActionType__c != \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_NO) + '\' ';
    */
    // 2018/10/04 原価情報を取得する機能追加 WSQ
    private static final String SQL_QUERYFIELD ='Id, Name, Field5__c, TaxRateCal__c, ServiceRate__c, SpecialTax__c, ActionType__c,Field4__c,GPChange__c,Field3__c,PaymentType__c, Field7__c ';
	// 検索前の有効性チェック
	private boolean preQueryInfo() {
		String findKey = CommUtils.nullToBlank(c_productNm).replaceAll('[\\?&\\|!{}\\[\\]\\(\\)\\^~\\*:\\\"\\+-]','');
		// キーワード入力あり　かつ　該当キーワードから特殊な文字以外は２桁以下の場合
		if (!CommUtils.isBlank(CommUtils.nullToBlank(c_productNm)) && (findKey.length() < 2)) {
			//フリーワード検索文字は最低 2 文字指定してください。
			Apexpages.addMessage(new Apexpages.Message(ApexPages.severity.ERROR, Label.MSG_009_0037));
			return false;
		}
		return true;
    }
    
    // 会計商品検索を行う												
    public void queryInfo() {
    	
    	// 画面ページステータス設定を行う
    	pageStatus = PAGE_STATUS.SEL;
    	
    	if (!preQueryInfo()) {
    		return;
    	}
    	
    	// 検索条件を取得する
        String whereStr = this.getWhereStr();
        String orderStr = this.getComOrderStr();
        String queryStr = '';
        
        c_productNm = CommUtils.nullToBlank(c_productNm);
        String findKey = CommSqlUtils.escapeSOSLTerm(c_productNm);
        // 2019/11/15 最近利用している商品一覧機能を提供する BY zyz BEGIN
        String searchStr = '';
        String limitStr = '';
        if(splitFlg && !Test.isRunningTest()){
        	searchStr = this.getSearchStr(false);
        	limitStr = this.getLimitStr();
        }
        // 2019/11/15 最近利用している商品一覧機能を提供する BY zyz END

        // 画面検索条件を設定されている場合
        if (!CommUtils.isBlank(c_productNm)) {
        /*
            whereStr += ' AND ( name Like \'%' + CommUtils.escStr(c_productNm) + '%\''; 
            whereStr += ' OR X1__c   Like \'%' + CommUtils.escStr(c_productNm) + '%\'';
            whereStr += ' OR X3_2__c Like \'%' + CommUtils.escStr(c_productNm) + '%\''; 
            whereStr += ' OR X4_3__c Like \'%' + CommUtils.escStr(c_productNm) + '%\' )';
            */
            //findKey = findKey.replace('"','\\"');
            // 2019/11/15 最近利用している商品一覧機能を提供する BY zyz BEGIN
            // queryStr = 'FIND :findKey IN ALL FIELDS RETURNING '+sobjectName+'(Id '+ whereStr + orderStr +')';
            // 2020/05/30 6423 bug fix BY zyz BEGIN
            // 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
            // queryStr = 'FIND :findKey IN ALL FIELDS RETURNING '+sobjectName+'(Id '+ whereStr + searchStr + orderStr +')';
            queryStr = 'FIND :findKey IN ALL FIELDS RETURNING '+sobjectName+'(Id, Field3__c, Name,Field5__c,TaxRateCal__c,ServiceRate__c,SpecialTax__c,ActionType__c,PaymentType__c,DiscountRate__c,Field7__c, PlanBathTaxAccMstRef__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Id, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Name, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Field3__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Field5__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.TaxRateCal__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.ServiceRate__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.SpecialTax__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.ActionType__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.PaymentType__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.DiscountRate__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Field7__c '+ whereStr + searchStr + orderStr +')';
            // 2020/07/30 入湯税の自動入力機能について改善 WGCH END
            // 2020/05/30 6423 bug fix BY zyz END
            // 2019/11/15 最近利用している商品一覧機能を提供する BY zyz END
	    // 2018/10/24 見積明細自動計算機能対応 WGCH BEGIN
	    // 2018/07/27 宿泊税計算 WGCH BEGIN
	    // PLAN明细数据检索
	    // 2019/07/30 軽減税率機能対応 WGCH BEGIN
	    // queryStr += ' , ' + PlanDetail__c.SObjectType.getDescribe().SObjectType.getDescribe().getName() + ' ( AccountMasterRef__c, PlanProdcut__c, Price__c, TaxRate__c, AccountMasterRef__r.ActionType__c where AccountMasterRef__r.ActionType__c = \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_RP) + '\') ';
	    // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
	    // queryStr += ' , ' + PlanDetail__c.SObjectType.getDescribe().SObjectType.getDescribe().getName() + ' ( AccountMasterRef__c, PlanProdcut__c, Price__c, TaxRate__c, AccountMasterRef__r.ActionType__c, ServiceRate__c, PlanRef__r.PlanNo__c, AccountMasterRef__r.Name, Id ) ';
	    // 2020/05/30 6462 bug fix WGCH BEGIN
	    queryStr += ' , ' + PlanDetail__c.SObjectType.getDescribe().SObjectType.getDescribe().getName() + ' ( AccountMasterRef__c, PlanProdcut__c, Price__c, TaxRate__c, AccountMasterRef__r.ActionType__c, AccountMasterRef__r.SpecialTax__c, ServiceRate__c, PlanRef__r.PlanNo__c, AccountMasterRef__r.Name, Id, Amount__c, OptionAccMstFLG__c ) ';
	    // 2020/05/30 6462 bug fix WGCH END
	    // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
	    // 2019/07/30 軽減税率機能対応 WGCH END
	    // 2018/07/27 宿泊税計算 WGCH END
	    // 2018/10/24 見積明細自動計算機能対応 WGCH END
	    List<List<Sobject>> rsLst = Search.query(queryStr);
	    wkProductLst = (List<AccountMaster__c>)rsLst[0];
	    // 2018/10/24 見積明細自動計算機能対応 WGCH BEGIN
	    // 2018/07/27 宿泊税計算 WGCH BEGIN
	    if(rsLst.size() >= 2){
	    	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
	    	pDetailMap = new Map<String, List<PlanDetail__c>>();
	    	// 2019/07/30 軽減税率機能対応 WGCH END
	    	for(AccountMaster__c acc : wkProductLst){
			for(PlanDetail__c pd : (List<PlanDetail__c>)rsLst[1]){
				if(acc.Id != pd.PlanProdcut__c) continue; // 该明细与该商品不匹配跳过
				if(!pDetailMap.containsKey(acc.Id)) pDetailMap.put(acc.Id, new List<PlanDetail__c>());
				pDetailMap.get(acc.Id).add(pd);
			}
		}
	    }
	    // 2018/07/27 宿泊税計算 WGCH END
	    // 2018/10/24 見積明細自動計算機能対応 WGCH END
        } else {
		// 2018/10/24 見積明細自動計算機能対応 WGCH BEGIN
		// 2018/07/27 宿泊税計算 WGCH BEGIN
		// queryStr = ' Select Id From AccountMaster__c ' + whereStr + orderStr;
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		// queryStr = ' Select Id,Field3__c,(Select Price__c, AccountMasterRef__r.ActionType__c From PlanProdcutRef__r  where TaxRate__c = 0 or TaxRate__c = null or AccountMasterRef__r.ActionType__c = \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_RP) + '\') From AccountMaster__c ' + whereStr + orderStr;
		// 2019/11/15 最近利用している商品一覧機能を提供する BY zyz BEGIN
		// queryStr = ' Select Id,Field3__c,(Select Price__c, AccountMasterRef__r.ActionType__c, TaxRate__c, ServiceRate__c, AccountMasterRef__c From PlanProdcutRef__r) From AccountMaster__c ' + whereStr + orderStr;
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
		// queryStr = ' Select Id,Field3__c,(Select Price__c, AccountMasterRef__r.ActionType__c, TaxRate__c, ServiceRate__c, AccountMasterRef__c, AccountMasterRef__r.Name, Id From PlanProdcutRef__r) From AccountMaster__c ' + whereStr + searchStr + orderStr + limitStr ;
		// 2020/05/30 6462 bug fix WGCH BEGIN
		// 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
		// queryStr = ' Select Id,Field3__c,(Select Price__c, AccountMasterRef__r.ActionType__c, AccountMasterRef__r.SpecialTax__c, TaxRate__c, ServiceRate__c, AccountMasterRef__c, AccountMasterRef__r.Name, Id, Amount__c, OptionAccMstFLG__c From PlanProdcutRef__r),Name,Field5__c,TaxRateCal__c,ServiceRate__c,SpecialTax__c,ActionType__c,PaymentType__c,DiscountRate__c,Field7__c From AccountMaster__c ' + whereStr + searchStr + orderStr + limitStr ;
		queryStr = ' Select Id,Field3__c,(Select Price__c, AccountMasterRef__r.ActionType__c, AccountMasterRef__r.SpecialTax__c, TaxRate__c, ServiceRate__c, AccountMasterRef__c, AccountMasterRef__r.Name, Id, Amount__c, OptionAccMstFLG__c From PlanProdcutRef__r),Name,Field5__c,TaxRateCal__c,ServiceRate__c,SpecialTax__c,ActionType__c,PaymentType__c,DiscountRate__c,Field7__c, PlanBathTaxAccMstRef__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Id, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Name, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Field3__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Field5__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.TaxRateCal__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.ServiceRate__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.SpecialTax__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.ActionType__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.PaymentType__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.DiscountRate__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Field7__c From AccountMaster__c ' + whereStr + searchStr + orderStr + limitStr ;
		// 2020/07/30 入湯税の自動入力機能について改善 WGCH END
		// 2020/05/30 6462 bug fix WGCH END
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
		// 2019/11/15 最近利用している商品一覧機能を提供する BY zyz END
		// 2019/07/30 軽減税率機能対応 WGCH END
		// 2018/07/27 宿泊税計算 WGCH END
		// 2018/10/24 見積明細自動計算機能対応 WGCH END
        	wkProductLst = Database.query(queryStr);
        }
        // 2018/10/24 見積明細自動計算機能対応 WGCH BEGIN
        // 2018/07/27 宿泊税計算 WGCH BEGIN
        // 2021/01/12 商品検索した際、limitエラー改善 BY zyz BEGIN
        // setPDetailMapInfo(wkProductLst);
        // 2021/01/12 商品検索した際、limitエラー改善 BY zyz END
        // 2018/07/27 宿泊税計算 WGCH END
        // 2018/10/24 見積明細自動計算機能対応 WGCH END
        /* 2016/10/27 性能改善対応 BEGIN
        Set<Id> accIdSet = new Set<Id>();
        for (AccountMaster__c acc : oProductLst){
        	accIdSet.add(acc.id);
        	planMap.put(acc.id,new DetailInfo(0,false));
        }
        if (isPriceAndRoomFlg){
	        for (PlanDetail__c detail : [Select AccountMasterRef__c, Price__c, TaxRate__c,PlanProdcut__c,AccountMasterRef__r.ActionType__c From PlanDetail__c  where  PlanProdcut__c = :accIdSet]){
	        	DetailInfo d = planMap.get(detail.PlanProdcut__c);
	        	if (detail.TaxRate__c == 0 || detail.TaxRate__c == null)
	        		d.initPrice += CommUtils.nullToZero(detail.Price__c);
	        	AccountMaster__c acc = new AccountMaster__c(ActionType__c = detail.AccountMasterRef__r.ActionType__c);
	        	if (RackRateUtils.isRoomRateProduct(acc)){
	        		if (CommUtils.nullToZero(detail.Price__c) == 0)
	        			d.hadRoomFlag = true;
	        	}
	        	planMap.put(detail.PlanProdcut__c,d);
	        }
        }*/
        pageCtrl = new PaginationUtil(wkProductLst , 100);
        // 2016/10/27 性能改善対応 BEGIN
        // 該当画面に表示する明細情報を取得、設定する
        queryProductDetailInfo();
        // 2016/10/27 性能改善対応 END
		// 20120915 選択した検索条件はCookiesに維持する
		Cookie dpidCookie = new Cookie('_produ_dpid', c_dpId, null, -1, true);
		Cookie gpidCookie = new Cookie('_produ_gpId', c_gpId, null, -1, true);
		// 2017/10/17 商品情報店舗別を検索を行う by zh BEGIN
		Cookie shopNmCookie = new Cookie('_produ_shopNm', branchShopNm, null, -1, true);
        //ApexPages.currentPage().setCookies(new Cookie[]{dpidCookie,gpidCookie});
		ApexPages.currentPage().setCookies(new Cookie[]{dpidCookie,gpidCookie,shopNmCookie});
		// 2017/10/17 商品情報店舗別を検索を行う by zh END
    }
    // 2016/10/27 性能改善対応 BEGIN
    public void firstPage() {
    	pageCtrl.firstPage();
    	queryProductDetailInfo();
    }
    public void previousPage() {
    	pageCtrl.previousPage();
    	queryProductDetailInfo();
    }
    public void nextPage() {
    	pageCtrl.nextPage();
    	queryProductDetailInfo();
    }
    public void lastPage() {
    	pageCtrl.lastPage();
    	queryProductDetailInfo();
    }
    
    // 指摘の商品IDで詳細情報を再取得を行う
    private void queryProductDetailInfo() {
    	list<AccountMaster__c> records = pageCtrl.records;
        // 2021/01/12 商品検索した際、limitエラー改善 BY zyz BEGIN
        setPDetailMapInfo(records);
        // 2021/01/12 商品検索した際、limitエラー改善 BY zyz END
    	// 指定の会計商品IDにより、関連詳細情報を取得する
        Set<Id> accIdSet = new Set<Id>();
        planMap = new Map<String,DetailInfo>();
        for (AccountMaster__c acc : records){
        	accIdSet.add(acc.id);
        	planMap.put(acc.id,new DetailInfo(0,false));
        }
		// 関連詳細情報を再取得する
        // 2019/11/15 最近利用している商品一覧機能を提供する BY BEGIN
		// String whereStr = this.getWhereStr() + ' And id in :accIdSet ';
		String whereStr = '';
		String searchStr = '';
		if(splitFlg && !Test.isRunningTest()){
			whereStr = this.getWhereStr();
        	searchStr = this.getSearchStr(true);
		} else whereStr = this.getWhereStr() + ' And id in :accIdSet ';
		// 2019/11/15 最近利用している商品一覧機能を提供する BY zyz END
		// 2018/08/29 会席設定追加追加 by zy BEGIN
		List<String> notInActLst = new List<String>{CommConst.PROD_ACTION_TYPE_NO,CommConst.PROD_ACTION_TYPE_AR,CommConst.PROD_ACTION_TYPE_PY};
		if (isDinnerFlag) {
			whereStr += ' and CookCount__c = 0 and ActionType__c != :notInActLst and field3__c != null';
		}
  		// 2018/08/29 会席設定追加追加 by zy END
        String orderStr = this.getComOrderStr();
        // 2019/11/15 最近利用している商品一覧機能を提供する BY zyz BEGIN
		// String queryStr = ' Select ' + SQL_QUERYFIELD + ' From AccountMaster__c ' + whereStr + orderStr;
		String queryStr = ' Select ' + SQL_QUERYFIELD + ' From AccountMaster__c ' + whereStr + searchStr + orderStr;
		// 2019/11/15 最近利用している商品一覧機能を提供する BY zyz END
		oProductLst = Database.query(queryStr);
		// 室料情報を取得する
        if (isPriceAndRoomFlg){
        	// 2018/05/11 ラックレート設定の自動なしの場合故障修正 by ZY BEGIN
        	String specialStr = '_price_';
        	Integer pointLen = CommUtils.getPointLen();
	        for (PlanDetail__c detail : [Select AccountMasterRef__c, Price__c, TaxRate__c,PlanProdcut__c,AccountMasterRef__r.ActionType__c,AccountMasterRef__r.Name From PlanDetail__c  where  PlanProdcut__c = :accIdSet]){
	        // 2018/05/11 ラックレート設定の自動なしの場合故障修正 by ZY END	
	        	DetailInfo d = planMap.get(detail.PlanProdcut__c);
	        	if (detail.TaxRate__c == 0 || detail.TaxRate__c == null)
	        		d.initPrice += CommUtils.nullToZero(detail.Price__c);
	        	AccountMaster__c acc = new AccountMaster__c(ActionType__c = detail.AccountMasterRef__r.ActionType__c);
	        	if (RackRateUtils.isRoomRateProduct(acc)){
	        		if (CommUtils.nullToZero(detail.Price__c) == 0)
	        			d.hadRoomFlag = true;
	        	}
	        	// 2018/05/11 ラックレート設定の自動なしの場合故障修正 by ZY BEGIN
	        	if (isNeedSyncFlag) {
	        		String priceTemp = CommUtils.deleteRightZero(CommUtils.nullToZero(detail.Price__c).format(), CommUtils.getPointLen());
	        		// 不存在关键字、且室料存在的情况下
	        		if (d.hadRoomFlag && d.syncInfo.indexOf(specialStr) < 0) priceTemp = specialStr;
	        		// 需要进行sync处理場合
                    // 2019/03/29 JINYABUG-1550 JINYABUG-1551 bug Fix by zy BEGIN
       			 	// d.syncInfo += detail.id + ':' + priceTemp + ':' + detail.AccountMasterRef__c + ':' + detail.AccountMasterRef__r.Name +';';
	        	    // 2019/03/29 JINYABUG-1550 JINYABUG-1551 bug Fix by zy END
                }
       			// 2018/05/11 ラックレート設定の自動なしの場合故障修正 by ZY END
	        	planMap.put(detail.PlanProdcut__c,d);
	        }
        }
    }
    // 2016/10/27 性能改善対応 END
    private String getWhereStr() {
    	// 非公開　|| 非表示の会計商品は対象外になる
        String whereStr = ' Where Name != null And IsClosed__c != true And ActionType__c != \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_NO) + '\''; 
        // DP設定場合
        if (!CommUtils.isBlank(c_dpId)) {
        	whereStr += ' AND Field4__c = :c_dpId ';
        }
        // GP設定場合
        if (!CommUtils.isBlank(c_gpId)) {
            whereStr += ' And GPChange__c = :c_gpId ';
        }
        // OP設定場合
//        if (!CommUtils.isBlank(c_opId)) {
//            whereStr += ' And OP__c = :c_opId ';
//        }	
		// プラン商品は非表示
		if (!isShowPlanProduFlg) {
			whereStr += ' And ActionType__c != \''+ String.escapeSingleQuotes(CommConst.PROD_ACTION_TYPE_PL) +'\'' ;
		}
		// 会計商品（支払）非表示
		if (!isShowPayProduFLg) {
			whereStr += ' And ActionType__c != \''+ String.escapeSingleQuotes(CommConst.PROD_ACTION_TYPE_PY) +'\'' ;
			whereStr += ' And ActionType__c != \''+ String.escapeSingleQuotes(CommConst.PROD_ACTION_TYPE_AR) +'\'' ;
		}
		// 2017/10/17 商品情報店舗別を検索を行う by zh BEGIN
        if (shopAccountSetupFlg && branchShopLst.size() > 0) {
            String subWhereStr = '';
	        if (!CommUtils.isBlank(branchShopNm)) {
	            subWhereStr+= ' And (ShopInfoRef__r.ShopCode__c = :branchShopNm';
	        }else if (userInf.isShopCodePlex) {
	            subWhereStr+= ' And (ShopInfoRef__r.ShopCode__c in :shopSt';
	        }
	        if (!CommUtils.isBlank(subWhereStr)) {
	            if (CommConst.PROD_SHOPSEARCH_DIV_ISALL) {
	                subWhereStr += ') ';
	            } else if (CommConst.PROD_SHOPSEARCH_DIV_ISNOR) {
	                subWhereStr += ' OR ActionType__c IN (\''+ String.escapeSingleQuotes(CommConst.PROD_ACTION_TYPE_AR) +'\',\''+ String.escapeSingleQuotes(CommConst.PROD_ACTION_TYPE_PY) +'\')) ';
	            } else if (CommConst.PROD_SHOPSEARCH_DIV_ISPAY) {
	                subWhereStr += ' OR ActionType__c NOT IN (\''+ String.escapeSingleQuotes(CommConst.PROD_ACTION_TYPE_AR) +'\',\''+ String.escapeSingleQuotes(CommConst.PROD_ACTION_TYPE_PY) +'\')) ';
	            } 
	        }
	        whereStr += subWhereStr;
        }
        // 2017/10/17 商品情報店舗別を検索を行う by zh END
        return whereStr;
    }
    // 100件まで表示する
    private String getComOrderStr () {
        // 2017/10/18 会計商品表示の並び順カスタマイズできるように改善対応 BEGIN
        //return ' order by Field4__c,OP__c, Field3__c ';
        // 2019/11/15 最近利用している商品一覧機能を提供する BY zyz BEGIN
        // return ' order by '+CommConst.PROD_SORT_KEY;
        String OrderByStr = ' order by '+CommConst.PROD_SORT_KEY;
        if (Test.isRunningTest()) return OrderByStr;
        if(accMasterStr == 'Viewed'){
        	OrderByStr = ' order by LastViewedDate desc ';
        } 
        return OrderByStr;
        // 2019/11/15 最近利用している商品一覧機能を提供する BY zyz END
        // 2017/10/18 会計商品表示の並び順カスタマイズできるように改善対応 END
    }
    public class DetailInfo{
    	public decimal initPrice{get;set;}
    	public boolean hadRoomflag{get;set;}
    	// 2018/05/11 ラックレート設定の自動なしの場合故障修正 by ZY BEGIN
    	public String syncInfo{get;set;}
    	// 2018/05/11 ラックレート設定の自動なしの場合故障修正 by ZY END
    	public DetailInfo(decimal price ,boolean flag){
    		initPrice = price;
    		hadRoomflag = flag;
    		// 2018/05/11 ラックレート設定の自動なしの場合故障修正 by ZY BEGIN
    		syncInfo = '';
    		// 2018/05/11 ラックレート設定の自動なしの場合故障修正 by ZY END
    	}
    }
    // 2018/05/11 ラックレート設定の自動なしの場合故障修正 by ZY BEGIN
    private Boolean isNeedSyncFlag;
    // 2018/05/11 ラックレート設定の自動なしの場合故障修正 by ZY END
    // 2018/08/29 会席設定追加追加 by zy BEGIN
    private Boolean isDinnerFlag;
    // 2018/08/29 会席設定追加追加 by zy END
	// 2018/10/04 原価金額を返却する WSQ BEGIN
    public Boolean isBasePriceFlg{get;private set;}
    // 2018/10/04 原価金額を返却する WSQ END
    // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
    public Map<String, Decimal> planHeaderSumMap{get;set;}
    public Map<String, String> gOptionMapInfo{get;set;}
    public Boolean isOptionPgFlg{get; set;}
    // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
    // 2018/10/24 見積明細自動計算機能対応 WGCH BEGIN
    // 2018/07/27 宿泊税計算 WGCH BEGIN
    private Map<String, List<PlanDetail__c>> pDetailMap = new Map<String, List<PlanDetail__c>>(); // KEY:会计商品ID/VAL:List<PLAN明细>
    public Map<String, String> pDetailMapInfo{get;set;}
    private void setPDetailMapInfo(List<AccountMaster__c> productLst){
        pDetailMapInfo = new Map<String, String>();
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
        Map<String, List<PlanBrkInfo>> planBrkInfoMap = new Map<String, List<PlanBrkInfo>>();
        // 2019/07/30 軽減税率機能対応 WGCH END
        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
        Boolean isHasOptionFlg = false;
        gOptionMapInfo = new Map<String, String>();
        planHeaderSumMap = new Map<String, Decimal>();
        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
        for (AccountMaster__c acc : productLst){
        	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
			Decimal planHeaderSum = 0;
			// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
        	List<Decimal> planItemPriceLst = new List<Decimal>();
        	List<PlanDetail__c> pDetailLst = acc.PlanProdcutRef__r;
			if((pDetailLst == null || pDetailLst.isEmpty()) && pDetailMap.containsKey(acc.Id)) pDetailLst = pDetailMap.get(acc.Id);
			if (pDetailLst != null && !pDetailLst.isEmpty()) {
				for (PlanDetail__c detail : pDetailLst) {
					// 2019/07/30 軽減税率機能対応 WGCH BEGIN
					PlanBrkInfo brk = new PlanBrkInfo();
					brk.productId = CommUtils.nullToBlank(detail.AccountMasterRef__c);
					brk.actionType = CommUtils.nullToBlank(detail.AccountMasterRef__r.ActionType__c);
					brk.unitPrice = CommUtils.nullToZero(detail.Price__c);
					brk.tax = CommUtils.nullToZero(detail.TaxRate__c);
					brk.serviceRate = CommUtils.nullToZero(detail.ServiceRate__c);
					// 2020/05/30 6462 bug fix WGCH BEGIN
					brk.specialTax = CommUtils.nullToZero(detail.AccountMasterRef__r.SpecialTax__c);
					// 2020/05/30 6462 bug fix WGCH END
					if(!planBrkInfoMap.containsKey(acc.Id)) planBrkInfoMap.put(acc.Id, new List<PlanBrkInfo>());
					planBrkInfoMap.get(acc.Id).add(brk);
					// 2019/07/30 軽減税率機能対応 WGCH END
					// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
					if(!isOptionPgFlg && detail.OptionAccMstFLG__c) planHeaderSum += brk.unitPrice;
					brk.pdId = CommUtils.nullToBlank(detail.Id);
					brk.prodcutName = CommUtils.nullToBlank(detail.AccountMasterRef__r.Name);
					if(!isHasOptionFlg) isHasOptionFlg = detail.OptionAccMstFLG__c == null ? false : detail.OptionAccMstFLG__c;
					// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
					if(detail.AccountMasterRef__r.ActionType__c == CommUtils.escStr(CommConst.PROD_ACTION_TYPE_RP)){ // 室料明细处理
						planItemPriceLst.add(CommUtils.nullToZero(detail.Price__c));
					}
				}
			}
			// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
			planHeaderSumMap.put(acc.Id, planHeaderSum);
			if(isHasOptionFlg){
				ProductItemUtils.ProductItem proItem = new ProductItemUtils.ProductItem(acc, pDetailLst, isOptionPgFlg);
				gOptionMapInfo.put(acc.Id, JSON.serialize(proItem));
			}
			// 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
			else if(acc.PlanBathTaxAccMstRef__c != null && acc.PlanBathTaxAccMstRef__r.BathTaxAccMstRef__c != null){
				ProductItemUtils.ProductItem proItem = new ProductItemUtils.ProductItem(acc);
				gOptionMapInfo.put(acc.Id, JSON.serialize(proItem));
			}
			// 2020/07/30 入湯税の自動入力機能について改善 WGCH END 
			else gOptionMapInfo.put(acc.Id, '');
			// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
			pDetailMapInfo.put(acc.Id, JSON.serialize(planItemPriceLst));
        }
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
        planBrkInfoMapJson = JSON.serialize(planBrkInfoMap);
        // 2019/07/30 軽減税率機能対応 WGCH END
    }
    // 2018/07/27 宿泊税計算 WGCH END
	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
	public String planBrkInfoMapJson{get;set;}
	public class PlanBrkInfo{
		public PlanBrkInfo(){
			productId = actionType = '';
			unitPrice = tax = serviceRate = 0;
			// 2020/05/30 6462 bug fix WGCH BEGIN
			specialTax = 0;
			// 2020/05/30 6462 bug fix WGCH END
			// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
			pdId = prodcutName = '';
			// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
		}
		public String productId{get;set;}
		public String actionType{get;set;}
		public Decimal unitPrice{get;set;}
		public Decimal tax{get;set;}
		public Decimal serviceRate{get;set;}
		// 2020/05/30 6462 bug fix WGCH BEGIN
		public Decimal specialTax{get;set;}
		// 2020/05/30 6462 bug fix WGCH END
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
		public String pdId{get;set;}
		public String prodcutName{get;set;}
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
	}
	// 2019/07/30 軽減税率機能対応 WGCH END
    // 2018/10/24 見積明細自動計算機能対応 WGCH END
    // 2019/11/15 最近利用している商品一覧機能を提供する BY zyz BEGIN
    public String accMasterStr{get;set;}
    // 切换li事件响应
    public void accountMasterItem() {
		queryInfo();
    }
    // 区分检索条件处理
    private String getSearchStr(Boolean selFlg) {
		String searchStr = '';
		// 最终阅览商品
		if(accMasterStr == 'Viewed'){
			searchStr += ' and LastViewedDate != null ';
			// if(!CommUtils.isBlank(c_productNm) && selFlg) searchStr += ' And id in :accIdSet ';
			if(selFlg) searchStr += ' And id in :accIdSet ';
		// 全部商品：8000
		} else if(accMasterStr == 'All'){
			if(selFlg) searchStr += ' And id in :accIdSet ';
		}
		return searchStr;
    }
    // 数据limit设定
    private String getLimitStr() {
		String limitStr = '';
		// 最终阅览商品
		if(accMasterStr == 'Viewed'){
			limitStr = ' limit 100 ';
		// 全部商品：8000
		} else if(accMasterStr == 'All'){
			limitStr = ' limit 8000 ';
		}
		return limitStr;
    }
    // 2019/11/15 最近利用している商品一覧機能を提供する BY zyz END
}