/**
* プラン関連情報検索を行う
* 2016/10/27 性能改善対応
**/
public with sharing class PlanSearchCtrl extends CommBaseCtrl{
    // 画面に表示する情報を格納用変数
	public transient List<Plan__c> oPlanLst{get;private set;}
    // 条件により、全部抽出した会計商品ID配列　
    private transient list<Plan__c> wkPlanLst;
    // 商品DP選択リスト
    public List<Selectoption> dpOptionLst{get; private set;}
    public List<Selectoption> gpOptionLst{get; private set;}
//    public List<Selectoption> opOptionLst{get; private set;}
	/***************************
	* 定数定義を行う
	****************************/
    // 画面データ処理ステータス変数
    //private Enum PAGE_STATUS {INS,UPD,SEL,UPDSPEC}
    //public PAGE_STATUS pageStatus{get;private set;}
    //public Boolean isIns{get{return pageStatus == PAGE_STATUS.INS;}}
    //public Boolean isUpd{get{return pageStatus == PAGE_STATUS.UPD;}}
    //public Boolean isSel{get{return pageStatus == PAGE_STATUS.SEL;}}
    // 新規商品格納用クラス
    //public Plan__c newAccMst{get;set;} 
    public transient Map<String,DetailInfo> planMap{get;set;}
    // 改ページ機能対応
    public PaginationUtil pageCtrl{get; set;}
    // Sobject Name(NameSapece)
    private String sobjectName;
    public String ShopCode{get;set;}
    public UserUtil.UserShopInfo userInf;
    private Map<String,ShopInformation__c> shopInfoMap;
    public List<SelectOption> branchShopLst{get; private set;}
    public String branchShopNm{get; set;}
    // 親のJSを呼び出し関数名
    //public String p_operWinJsFunNm{get;private set;}
    // 検索条件：商品名
    public String c_planNm{get;set;}
    public String c_gpId{get;set;}
    public String c_dpId{get;set;}
//    public String c_opId{get;set;}
    //private Boolean isShowPlanProduFlg = true;		// 会計商品（プラン）が検索対象制御フラグ TRUE:会計商品プランは対象する
    //private Boolean isShowPayProduFLg = true;
    private boolean isPriceAndRoomFlg = false;
    // 初期化
    public PlanSearchCtrl() {
        // パラメータ分析する
        initParam();
        // 格納変数を初期化する
        oPlanLst = new List<Plan__c>();
        
		// 商品分類選択リストを設定を行う
		dpOptionLst = new List<Selectoption>();
		gpOptionLst = new List<Selectoption>();
//		opOptionLst = new List<Selectoption>();
		for (DP__c s: [select id, name, Field1__c from DP__c where IsClosed__c != true order by Name limit 500]) dpOptionLst.add(new SelectOption(s.id, s.Name));
		for (GP__c s: [select id, name, Field1__c from GP__c where IsClosed__c != true order by Name limit 500]) gpOptionLst.add(new SelectOption(s.id, s.Name));
//		for (OP__c s: [select id, name, Field1__c from OP__c order by Name limit 500]) opOptionLst.add(new SelectOption(s.id, s.Name));
    	
    	Schema.DescribeSObjectResult R = Plan__c.SObjectType.getDescribe();
    	sobjectName = R.getName();
    	
    }
     // 初期化処理呼び出す
    public void init() {
    	// ユーザINFO
    	userInf = UserUtil.CurrentUserInfo;
    	// 店舗情報作成
    	setInitBranShopLst();
    	// 会計商品検索を行う
        this.queryInfo();
    }
    // 店舗リストを設定する
    private void setInitBranShopLst() {
        branchShopLst = ShopInfoUtil.getBranchShopLst(userInf.shops);
        shopInfoMap   = ShopInfoUtil.getShopInfoMap(userInf.shops);
        if (!branchShopLst.isEmpty()) {
        	String locShopCode = UserUtil.CurrentUser.ShopCode__c;
        	for (SelectOption s : branchShopLst) {
        		if (s.getValue() == locShopCode) branchShopNm =  CommUtils.nullToBlank(locShopCode);
        	}
		}
    }
   
    // 引渡しパラメータ分析する
    private void initParam() {
        Cookie dpidCookie = ApexPages.currentPage().getCookies().get('_produ_dpid');
        if (dpidCookie != null) c_dpId = dpidCookie.getValue();
        Cookie gpidCookie = ApexPages.currentPage().getCookies().get('_produ_gpId');
        if (gpidCookie != null) c_gpId = gpidCookie.getValue();
        // 会計商品（プラン）非表示制御パラメータ
        //isShowPlanProduFlg = CommUtils.isBlank(ApexPages.currentPage().getParameters().get('np'));
        // 会計商品（支払）非表示制御フラグ
        //isShowPayProduFLg = CommUtils.isBlank(ApexPages.currentPage().getParameters().get('npy'));
        isPriceAndRoomFlg = !CommUtils.isBlank(ApexPages.currentPage().getParameters().get('par'));
    }
    
    private static final String SQL_QUERYFIELD ='Id, Name, PlanNo__c, Seq__c, JmstRef__r.TaxRate__c, ServiceRate__c, JmstRef__c, client__c, Price__c, ShopInfoRef__c, PackageCode__c, IsClosed__c, BasePlanFlg__c, DpRef__c, GpRef__c ';
	// 検索前の有効性チェック
	private boolean preQueryInfo() {
		String findKey = CommUtils.nullToBlank(c_planNm).replaceAll('[\\?&\\|!{}\\[\\]\\(\\)\\^~\\*:\\\"\\+-]','');
		// キーワード入力あり　かつ　該当キーワードから特殊な文字以外は２桁以下の場合
		if (!CommUtils.isBlank(CommUtils.nullToBlank(c_planNm)) && (findKey.length() < 2)) {
			//フリーワード検索文字は最低 2 文字指定してください。
			Apexpages.addMessage(new Apexpages.Message(ApexPages.severity.ERROR, Label.MSG_009_0037));
			return false;
		}
		return true;
    }
    
    // 会計商品検索を行う												
    public void queryInfo() {
    	
    	// 画面ページステータス設定を行う
    	//pageStatus = PAGE_STATUS.SEL;
    	
    	if (!preQueryInfo()) {
    		return;
    	}
    	
    	// 検索条件を取得する
        String whereStr = this.getWhereStr();
        String orderStr = this.getComOrderStr();
        String queryStr = '';
        if(branchShopNm != null) Id ShopCode = ShopInfoUtil.getShop(branchShopNm).id;
        c_planNm = CommUtils.nullToBlank(c_planNm);
        String findKey = CommSqlUtils.escapeSOSLTerm(c_planNm);
        // 画面検索条件を設定されている場合
        if (!CommUtils.isBlank(c_planNm)) {
            //findKey = findKey.replace('"','\\"');
            queryStr = 'FIND :findKey IN ALL FIELDS RETURNING '+sobjectName+'(Id '+ whereStr + orderStr +')';
        	List<List<Sobject>> rsLst = Search.query(queryStr);
        	wkPlanLst = (List<Plan__c>)rsLst[0];
        } else {
        	queryStr = ' Select Id From Plan__c ' + whereStr + orderStr;
        	wkPlanLst = Database.query(queryStr);
        }
        pageCtrl = new PaginationUtil(wkPlanLst , 100);
        // 該当画面に表示する明細情報を取得、設定する
        queryPlanDetailInfo();
		// 選択した検索条件はCookiesに維持する
		Cookie dpidCookie = new Cookie('_produ_dpid', c_dpId, null, -1, true);
		Cookie gpidCookie = new Cookie('_produ_gpId', c_gpId, null, -1, true);
		ApexPages.currentPage().setCookies(new Cookie[]{dpidCookie,gpidCookie});
    }
    public void firstPage() {
    	pageCtrl.firstPage();
    	queryPlanDetailInfo();
    }
    public void previousPage() {
    	pageCtrl.previousPage();
    	queryPlanDetailInfo();
    }
    public void nextPage() {
    	pageCtrl.nextPage();
    	queryPlanDetailInfo();
    }
    public void lastPage() {
    	pageCtrl.lastPage();
    	queryPlanDetailInfo();
    }
    
    // 指摘の商品IDで詳細情報を再取得を行う
    private void queryPlanDetailInfo() {
    	list<Plan__c> records = pageCtrl.records;
    	// 指定の会計商品IDにより、関連詳細情報を取得する
        Set<Id> accIdSet = new Set<Id>();
        if(branchShopNm != null) Id ShopCode = ShopInfoUtil.getShop(branchShopNm).id;
        planMap = new Map<String,DetailInfo>();
        for (Plan__c acc : records){
        	accIdSet.add(acc.id);
        	planMap.put(acc.id,new DetailInfo(0,false));
        }
		// 関連詳細情報を再取得する
		String whereStr = this.getWhereStr() + ' And id in :accIdSet AND IsClosed__c != true';
        String orderStr = this.getComOrderStr();
		String queryStr = ' Select ' + SQL_QUERYFIELD + ' From Plan__c ' + whereStr + orderStr;
		oPlanLst = Database.query(queryStr);
    	// 室料情報を取得する
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
        }
    }
    private String getWhereStr() {
        String whereStr = ' Where Name != null AND IsClosed__c != true';
        // DP設定場合
        if (!CommUtils.isBlank(branchShopNm)) {
        	//Id ShopCode = ShopInfoUtil.getShop(branchShopNm).id;
        	whereStr += ' AND ShopInfoRef__c = :ShopCode ';
        }
        if (!CommUtils.isBlank(c_dpId)) {
        	whereStr += ' AND DpRef__c = :c_dpId ';
        }
        // GP設定場合
        if (!CommUtils.isBlank(c_gpId)) {
            whereStr += ' And GpRef__c = :c_gpId ';
        }
        return whereStr;
    }
    // 100件まで表示する
    private String getComOrderStr () {
        return ' order by ShopInfoRef__c, DpRef__c, GpRef__c, PackageCode__c';
    }
    public class DetailInfo{
    	public decimal initPrice{get;set;}
    	public boolean hadRoomflag{get;set;}
    	public DetailInfo(decimal price ,boolean flag){
    		initPrice = price;
    		hadRoomflag = flag;
    	}
    }
}