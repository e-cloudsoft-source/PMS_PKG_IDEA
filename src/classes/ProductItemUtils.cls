/**
* 会計商品関連情報取得要
* 2014/12/25 商品コードのSETにより、商品情報MAPを戻る機能追加
**/
global with sharing class ProductItemUtils {

	/**
	* 会計商品コードにて、会計商品情報を取得する
	* 
	**/
	// 2017/10/09 会計商品並び順カスタマイズできるように改善対応 BEGIN
	private static final String PROD_SORT_KEY = CommConst.PROD_SORT_KEY;
	// 2017/10/09 会計商品並び順カスタマイズできるように改善対応 END
	// 2017/10/17 商品情報店舗別を検索を行う by zh BEGIN
    // 店舗別商品機能フラグ
    //private static Boolean shopAccountSetupFlg{get{return CommConst.APPOTION_BI_SHOPPRODUCT_FLG;}}
    // 現在ログインユーザー情報
    private static UserUtil.UserShopInfo userInf;
    private static Set<String> shopSt;
    private static final String ACCMST_SOBJNM = AccountMaster__c.SObjectType.getDescribe().SObjectType.getDescribe().getName();
    // 2017/10/17 商品情報店舗別を検索を行う by zh END
    // 2018/01/19 那須いちやホテル様から 会計商品の検索方式は前方一致モードに戻るほしい対応 WGCH BEGIN
    private static final Boolean productSearchTypeFlg = CommDefine__c.getOrgDefaults().ProductSearchTypeFlg__c == null ? false : CommDefine__c.getOrgDefaults().ProductSearchTypeFlg__c;
    // 2018/01/19 那須いちやホテル様から 会計商品の検索方式は前方一致モードに戻るほしい対応 WGCH END
    // 2018/07/27 宿泊税計算 WGCH BEGIN
    private static Map<String, List<PlanDetail__c>> pDetailMap = new Map<String, List<PlanDetail__c>>(); // KEY:会计商品ID/VAL:List<PLAN明细>
    // 2018/07/27 宿泊税計算 WGCH END
	public static ProductItem getSingProdcutItemByCode(String prodCd) {
		// 検索SQL取得
		String queryStr = CommSqlUtils.generateQueryString('AccountMaster__c');
		queryStr += ' Where BasePlanFlg__c = false And IsClosed__c != true And ActionType__c != \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_NO) + '\' And Field3__c = \'' + CommUtils.escStr(prodCd) + '\'';
		queryStr += ' limit 1 '; 
		// 商品情報を検索を行う
		List<AccountMaster__c> accMstLst = Database.query(queryStr);
		if (accMstLst.isEmpty()) {
			//該当商品が見つかりません。
			throw new CommException(Label.MSG_009_0042);
		}
		AccountMaster__c acc = accMstLst[0];
		ProductItem item = new ProductItem(acc);
		
		return item;
	}
	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
	// 商品コードにより、商品一覧を取得する_OPTION商品专用
	// OPTION有效页面调用函数
	public static Boolean isOpPgFlg{get{ if(isOpPgFlg == null) isOpPgFlg = false; return isOpPgFlg;}}
	public static List<ProductItem> getArrayProdcutItemByCodeOp(String prodCd, Boolean noPlan, Boolean noPay, Boolean gIsOpPgFlg) {
		isOpPgFlg = gIsOpPgFlg;
		return getArrayProdcutItemByCode(prodCd, noPlan, noPay);
	}
	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
	// 商品コードにより、商品一覧を取得する
	public static List<ProductItem> getArrayProdcutItemByCode(String prodCd) {
		return getArrayProdcutItemByCode(prodCd, false);
	}
	// 商品コードにより、商品一覧を取得する
	// prodCd:商品コード一部
	// noPlan:会計商品プラン対象制御フラグ(TRUE：会計商品（プラン）は検索対象外, FALSE:対象)
	public static List<ProductItem> getArrayProdcutItemByCode(String prodCd, Boolean noPlan) {
		return getArrayProdcutItemByCode(prodCd, noPlan, false);
	}
	// 商品コードにより、商品一覧を取得する
	// prodCd:商品コード一部
	// noPlan:会計商品プラン対象制御フラグ(TRUE：会計商品（プラン）は検索対象外, FALSE:対象)
	// noPay:会計商品プラン対象制御フラグ(TRUE：会計商品（支払）は検索対象外, FALSE:対象)
	public static List<ProductItem> getArrayProdcutItemByCode(String prodCd, Boolean noPlan, Boolean noPay) {
		// 2017/10/12 商品検索方式変更対応 BEGIN
        Set<String> payTypeSet = new Set<String>{CommConst.PROD_ACTION_TYPE_AR,Commconst.PROD_ACTION_TYPE_PY};
        // 検索機能対応、キーワードが一つ場合、LIKE方式で商品名と商品コードをヒントする、半角スペースで複数キーワードをいれるとき、SOSL方式で検索を行う 
		// 検索SQL取得
		//String queryStr = CommSqlUtils.generateQueryString('AccountMaster__c',new String[]{'(Select AccountMasterRef__c, Price__c, TaxRate__c From PlanProdcutRef__r  where TaxRate__c = 0 or TaxRate__c = null)'});
        String queryStr = null;
        prodCd = CommUtils.nullToBlank(prodCd);
        if (CommUtils.isBlank(prodCd)) return new List<ProductItem>();
        String[] keywords = CommUtils.splitSpace(prodCd);
        // 複数キーワード判断
        Boolean isSOSLModeFlg = keywords.size() > 1;
        if (isSOSLModeFlg) {
            queryStr = 'FIND :prodCd IN ALL FIELDS RETURNING ' + ACCMST_SOBJNM + '(' + CommSqlUtils.generateAllFieldsString('AccountMaster__c');
            // 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
            queryStr +=' ,PlanBathTaxAccMstRef__r.BathTaxAccMstRef__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Id, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Name, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Field3__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Field5__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.TaxRateCal__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.ServiceRate__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.SpecialTax__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.ActionType__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.PaymentType__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.DiscountRate__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Field7__c';
            // 2020/07/30 入湯税の自動入力機能について改善 WGCH END
        } else {
        	// 2018/07/27 宿泊税計算 WGCH BEGIN
        	// queryStr = CommSqlUtils.generateQueryString('AccountMaster__c',new String[]{'(Select AccountMasterRef__c, Price__c, TaxRate__c From PlanProdcutRef__r  where TaxRate__c = 0 or TaxRate__c = null)'});
        	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
        	// queryStr = CommSqlUtils.generateQueryString('AccountMaster__c',new String[]{'(Select AccountMasterRef__c, Price__c, TaxRate__c, AccountMasterRef__r.ActionType__c, ServiceRate__c From PlanProdcutRef__r  where TaxRate__c = 0 or TaxRate__c = null or AccountMasterRef__r.ActionType__c = \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_RP) + '\')'});
        	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
        	// queryStr = CommSqlUtils.generateQueryString('AccountMaster__c',new String[]{'(Select AccountMasterRef__c, Price__c, TaxRate__c, AccountMasterRef__r.ActionType__c, ServiceRate__c, AccountMasterRef__r.Name, Id From PlanProdcutRef__r)'});
        	// 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
        	// queryStr = CommSqlUtils.generateQueryString('AccountMaster__c',new String[]{'(Select AccountMasterRef__c, Price__c, TaxRate__c, AccountMasterRef__r.ActionType__c, ServiceRate__c, AccountMasterRef__r.Name, Id, Amount__c, OptionAccMstFLG__c From PlanProdcutRef__r)'});
        	queryStr = CommSqlUtils.generateQueryString('AccountMaster__c',new String[]{'(Select AccountMasterRef__c, Price__c, TaxRate__c, AccountMasterRef__r.ActionType__c, ServiceRate__c, AccountMasterRef__r.Name, Id, Amount__c, OptionAccMstFLG__c From PlanProdcutRef__r)',' PlanBathTaxAccMstRef__r.BathTaxAccMstRef__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Id, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Name, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Field3__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Field5__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.TaxRateCal__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.ServiceRate__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.SpecialTax__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.ActionType__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.PaymentType__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.DiscountRate__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Field7__c'});
        	// 2020/07/30 入湯税の自動入力機能について改善 WGCH END
        	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
        	// 2019/07/30 軽減税率機能対応 WGCH END
        	// 2018/07/27 宿泊税計算 WGCH END
        }
        // 2017/10/12 商品検索方式変更対応 END
        // 2017/10/17 商品情報店舗別を検索を行う by zh BEGIN
		queryStr += ' Where IsClosed__c != true And ActionType__c != \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_NO) + '\'';
		if (CommConst.PROD_SHOPSEARCH_DIV_IS) {
			 // ユーザINFO
            userInf = UserUtil.CurrentUserInfo;
            // 多店舗情報格納する
            shopSt = userInf.shopSt;
            // 該当ログインユーザーの情報を格納する
		    //String defSpcd = UserUtil.CurrentUserInfo.defaultShopCode;
		    String defSpcd = UserUtil.CurrentUser.ShopCode__c;
		    if (!CommUtils.isBlank(defSpcd)) {
	            // 該当ユーザーデフォルトの店舗コード
	            if (userInf.isShopCodePlex) {
	                queryStr += ' And (ShopInfoRef__r.ShopCode__c in :shopSt';
	            } else if (!CommUtils.isBlank(defSpcd)) {
	                queryStr += ' And (ShopInfoRef__r.ShopCode__c = :defSpcd';
	            }    
			    if (CommConst.PROD_SHOPSEARCH_DIV_ISALL) {
	                queryStr += ')';
			    } else if (CommConst.PROD_SHOPSEARCH_DIV_ISNOR) {
	                queryStr += ' OR ActionType__c IN :payTypeSet)';
			    } else if (CommConst.PROD_SHOPSEARCH_DIV_ISPAY) {
	                queryStr += ' OR ActionType__c NOT IN :payTypeSet)';
			    }
		    }
		}
		// 2017/10/17 商品情報店舗別を検索を行う by zh END
		// 2017/10/12 商品検索方式変更対応 BEGIN
		// 検索機能対応、キーワードが一つ場合、LIKE方式で商品名と商品コードをヒントする、半角スペースで複数キーワードをいれるとき、SOSL方式で検索を行う
		if (!isSOSLModeFlg) {
			// 2018/01/19 那須いちやホテル様から 会計商品の検索方式は前方一致モードに戻るほしい対応 WGCH BEGIN
			// prodCd = '%' + prodCd + '%';
			// 2019/03/11 SFの全角「＼」問題回避 WSQ BEGIN
			prodCd = CommUtils.escStr(prodCd);
			// 2019/03/11 SFの全角「＼」問題回避 WSQ END
		    if(!productSearchTypeFlg) prodCd = '%' + prodCd + '%';
		    else prodCd = prodCd + '%';
		    // 2018/01/19 那須いちやホテル様から 会計商品の検索方式は前方一致モードに戻るほしい対応 WGCH END
           	// 2020/12/15 会計商品にJANコードを登録し、それをバーコードリーダーで読み取り、会計処理が行えるようにしたい by zy BEGIN 
		    queryStr += ' And ( JanCode__c like :prodCd or Field3__c like :prodCd OR Name like :prodCd) ' ;
		    // 2020/12/15 会計商品にJANコードを登録し、それをバーコードリーダーで読み取り、会計処理が行えるようにしたい by zy END 
		}
		// 2017/10/12 商品検索方式変更対応 END
		if (noPlan) queryStr += ' And ActionType__c != \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_PL) + '\'';
		if (noPay) {
			queryStr += ' And ActionType__c != \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_PY) + '\'';
			queryStr += ' And ActionType__c != \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_AR) + '\'';
		}
		// 2017/10/09 会計商品並び順カスタマイズできるように改善対応 BEGIN
		//queryStr += ' order by Field4__c,OP__c, Field3__c ';
		queryStr += ' order by ' + PROD_SORT_KEY;
		// 2017/10/09 会計商品並び順カスタマイズできるように改善対応 END
		//queryStr += ' limit 1000 '; 
		// 2020/02/06 性能优化 WGCH BEGIN
		queryStr += ' limit 100 ';
		// 2020/02/06 性能优化 WGCH END
		// 商品情報を検索を行う
		// 2017/10/12 検索機能対応、キーワードが一つ場合、LIKE方式で商品名と商品コードをヒントする、半角スペースで複数キーワードをいれるとき、SOSL方式で検索を行う BEGIN
		List<AccountMaster__c> accMstLst = null;
		if (isSOSLModeFlg) {
		    queryStr += ')';
		    // 2018/07/27 宿泊税計算 WGCH BEGIN
		    // PLAN明细数据检索
		    // 2019/07/30 軽減税率機能対応 WGCH BEGIN
		    // queryStr += ' , ' + PlanDetail__c.SObjectType.getDescribe().SObjectType.getDescribe().getName() + ' ( AccountMasterRef__c, PlanProdcut__c, Price__c, TaxRate__c, AccountMasterRef__r.ActionType__c, ServiceRate__c where AccountMasterRef__r.ActionType__c = \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_RP) + '\') ';
		    // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
		    // queryStr += ' , ' + PlanDetail__c.SObjectType.getDescribe().SObjectType.getDescribe().getName() + ' ( AccountMasterRef__c, PlanProdcut__c, Price__c, TaxRate__c, AccountMasterRef__r.ActionType__c, ServiceRate__c, AccountMasterRef__r.Name, Id)';
		    // 2021/07/15 #13403 bug fixed by zy BEGIN
		    // queryStr += ' , ' + PlanDetail__c.SObjectType.getDescribe().SObjectType.getDescribe().getName() + ' ( AccountMasterRef__c, PlanProdcut__c, Price__c, TaxRate__c, AccountMasterRef__r.ActionType__c, ServiceRate__c, AccountMasterRef__r.Name, Id, Amount__c, OptionAccMstFLG__c,PlanRef__r.name,PlanProdcut__r.name,PlanProdcut__r.Field3__c)';
		    // 2021/07/15 #13403 bug fixed by zy END
		    // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
		    // 2019/07/30 軽減税率機能対応 WGCH END
		    // 2018/07/27 宿泊税計算 WGCH END
		    List<List<Sobject>> rsLst = Search.query(queryStr);
		    accMstLst = (List<AccountMaster__c>)rsLst[0];
		    // 2018/07/27 宿泊税計算 WGCH BEGIN
		    /*
		    if(rsLst.size() >= 2){
		    	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		    	pDetailMap = new Map<String, List<PlanDetail__c>>();
		    	// 2019/07/30 軽減税率機能対応 WGCH END
		    	for(AccountMaster__c acc : accMstLst){
		    		for(PlanDetail__c pd : (List<PlanDetail__c>)rsLst[1]){
		    			if(acc.Id != pd.PlanProdcut__c) continue; // 该明细与该商品不匹配跳过
		    			if(!pDetailMap.containsKey(acc.Id)) pDetailMap.put(acc.Id, new List<PlanDetail__c>());
		    			pDetailMap.get(acc.Id).add(pd);
		    		}
		    	}
		    }*/
		    // 2018/07/27 宿泊税計算 WGCH END
		} else {
			//List<AccountMaster__c> accMstLst = Database.query(queryStr);
			accMstLst = Database.query(queryStr);
		}
		// 2017/10/12 検索機能対応、キーワードが一つ場合、LIKE方式で商品名と商品コードをヒントする、半角スペースで複数キーワードをいれるとき、SOSL方式で検索を行う END
		if (accMstLst.isEmpty()) {
			return new List<ProductItem>();
		}
		List<ProductItem> items = new List<ProductItem>();
		// 2017/10/12 検索機能対応、キーワードが一つ場合、LIKE方式で商品名と商品コードをヒントする、半角スペースで複数キーワードをいれるとき、SOSL方式で検索を行う BEGIN
		// 2019/03/29 JINYABUG-1527 bug fix by zy BEGIN
		/*
		Map<Id, list<PlanDetail__c>> soslRelPlanDetailsMap = new Map<Id, list<PlanDetail__c>>();
		Map<String,ProductItemUtils.ProductItem> accMap = new Map<String,ProductItemUtils.ProductItem>();
		if (isSOSLModeFlg) {
            set<id> relAccMstIds = new set<Id>();
		    for (AccountMaster__c ac : accMstLst) { relAccMstIds.add(ac.id); }
		    // 非課税明細情報を取得する
            List<PlanDetail__c> planDetailLst = [Select AccountMasterRef__c,PlanProdcut__c, Price__c, TaxRate__c From PlanDetail__c  where (TaxRate__c = 0 or TaxRate__c = null) And PlanProdcut__c in : relAccMstIds];
            for (PlanDetail__c pd : planDetailLst) {
                Id accPlanId = pd.PlanProdcut__c;
                if (!soslRelPlanDetailsMap.containsKey(accPlanId)) soslRelPlanDetailsMap.put(accPlanId, new List<PlanDetail__c>());
                soslRelPlanDetailsMap.get(accPlanId).add(pd);
            }
		}*/
    	// 2021/07/15 #13403 bug fixed by zy END
    	// 既存会計商品
    	Set<String> accIdSet = new Set<String>();
    	for (AccountMaster__c ac : accMstLst) {
    		accIdSet.add(ac.id);
    	}
    	// プラン「室料あり、室料０」
		set<Id> hadRoomFlagSet = new Set<id>();
		// 2021/07/15 #13403 bug fixed by zy BEGIN
		pDetailMap = new Map<String, List<PlanDetail__c>>();
		// 2021/07/15 #13403 bug fixed by zy END
		// 複数キーワードの場合、プラン明細刷新フラグ
		for (PlanDetail__c detail : [Select AccountMasterRef__c, Price__c,ServiceRate__c,Amount__c,OptionAccMstFLG__c, TaxRate__c,PlanProdcut__c,AccountMasterRef__r.ActionType__c From PlanDetail__c  where  PlanProdcut__c = :accIdSet]){
        	AccountMaster__c acc = new AccountMaster__c(ActionType__c = detail.AccountMasterRef__r.ActionType__c);
        	if (RackRateUtils.isRoomRateProduct(acc)){
        		if (CommUtils.nullToZero(detail.Price__c) == 0){
        			if (!hadRoomFlagSet.contains(detail.PlanProdcut__c))
        				hadRoomFlagSet.add(detail.PlanProdcut__c);
        		}
        	}
        	// 2021/07/15 #13403 bug fixed by zy BEGIN
        	// 複数キーワードとプラン明細刷新
        	if (isSOSLModeFlg) {
        		if(!pDetailMap.containsKey(detail.PlanProdcut__c)) {
	        		pDetailMap.put(detail.PlanProdcut__c, new List<PlanDetail__c>());
	        	} 
			    pDetailMap.get(detail.PlanProdcut__c).add(detail);
        	}
		    // 2021/07/15 #13403 bug fixed by zy END
        }
        // 2019/03/29 JINYABUG-1527 bug fix by zy END
		// 2017/10/12 検索機能対応、キーワードが一つ場合、LIKE方式で商品名と商品コードをヒントする、半角スペースで複数キーワードをいれるとき、SOSL方式で検索を行う END
		for (AccountMaster__c ac : accMstLst) {
			// 2017/10/12 検索機能対応、キーワードが一つ場合、LIKE方式で商品名と商品コードをヒントする、半角スペースで複数キーワードをいれるとき、SOSL方式で検索を行う BEGIN
            String key = ac.id;
            // 2021/07/15 #13403 bug fixed by zy BEGIN
            /*
            if (isSOSLModeFlg) {
                accMap.put(key,new ProductItem(ac, soslRelPlanDetailsMap.get(key)));
            } else {
                accMap.put(key,new ProductItem(ac));
            }*/
            // 2021/07/15 #13403 bug fixed by zy END
			// 2017/10/12 検索機能対応、キーワードが一つ場合、LIKE方式で商品名と商品コードをヒントする、半角スペースで複数キーワードをいれるとき、SOSL方式で検索を行う END
			// 2019/03/29 JINYABUG-1527 bug fix by zy BEGIN
			//items.add(new ProductItem(ac));
			ProductItem item = new ProductItem(ac);
			// 2021/01/05 #9588 bug fixed by zy BEGIN 
			item.janCode = ac.JanCode__c;
			// 2021/01/05 #9588 bug fixed by zy END  
			// 室料フラグ設定
			item.hadRoomFlag = hadRoomFlagSet.contains(ac.id);
			items.add(item);
			// 2019/03/29 JINYABUG-1527 bug fix by zy END
		}
		return items;
	}
	// 2014/12/25 商品コードにより、商品情報MAPを取得する
	public static Map<String, ProductItem> getMapProductItemByCodes(Set<String> prodCdSet, Boolean noPlan) {
		// 検索SQL取得
		// 2018/07/27 宿泊税計算 WGCH BEGIN
		// String queryStr = CommSqlUtils.generateQueryString('AccountMaster__c',new String[]{'(Select AccountMasterRef__c, Price__c, TaxRate__c From PlanProdcutRef__r  where TaxRate__c = 0 or TaxRate__c = null)'});
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		// String queryStr = CommSqlUtils.generateQueryString('AccountMaster__c',new String[]{'(Select AccountMasterRef__c, Price__c, TaxRate__c, AccountMasterRef__r.ActionType__c From PlanProdcutRef__r  where TaxRate__c = 0 or TaxRate__c = null or AccountMasterRef__r.ActionType__c = \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_RP) + '\')'});
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
		// String queryStr = CommSqlUtils.generateQueryString('AccountMaster__c',new String[]{'(Select AccountMasterRef__c, Price__c, TaxRate__c, AccountMasterRef__r.ActionType__c,ServiceRate__c, AccountMasterRef__r.Name, Id From PlanProdcutRef__r)'});
		// 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
		// String queryStr = CommSqlUtils.generateQueryString('AccountMaster__c',new String[]{'(Select AccountMasterRef__c, Price__c, TaxRate__c, AccountMasterRef__r.ActionType__c,ServiceRate__c, AccountMasterRef__r.Name, Id, Amount__c, OptionAccMstFLG__c From PlanProdcutRef__r)'});
		String queryStr = CommSqlUtils.generateQueryString('AccountMaster__c',new String[]{'(Select AccountMasterRef__c, Price__c, TaxRate__c, AccountMasterRef__r.ActionType__c,ServiceRate__c, AccountMasterRef__r.Name, Id, Amount__c, OptionAccMstFLG__c From PlanProdcutRef__r)',' PlanBathTaxAccMstRef__r.BathTaxAccMstRef__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Id, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Name, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Field3__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Field5__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.TaxRateCal__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.ServiceRate__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.SpecialTax__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.ActionType__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.PaymentType__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.DiscountRate__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Field7__c'});
		// 2020/07/30 入湯税の自動入力機能について改善 WGCH END
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
		// 2019/07/30 軽減税率機能対応 WGCH END
		// 2018/07/27 宿泊税計算 WGCH END
		queryStr += ' Where IsClosed__c != true And ActionType__c != \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_NO) + '\' And Field3__c in :prodCdSet ' ;
		if (noPlan) queryStr += ' And ActionType__c != \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_PL) + '\'';
		// 2017/10/09 会計商品並び順カスタマイズできるように改善対応 BEGIN
        //queryStr += ' order by Field4__c,OP__c, Field3__c ';
        queryStr += ' order by ' + PROD_SORT_KEY;
        // 2017/10/09 会計商品並び順カスタマイズできるように改善対応 END
        // 2019/04/15 ベネフィットホテル様より改善要望 by zy BEGIN
    	// 既存会計商品
    	Set<String> accIdSet = new Set<String>();
    	// 2019/04/15 ベネフィットホテル様より改善要望 by zy END
		// 検索結果格納
		Map<String, ProductItem> itemMaps = new Map<String, ProductItem>();
		for (AccountMaster__c ac : Database.query(queryStr)) {
			// 2021/01/05 #9593 bug fixed by zy BEGIN 
			ProductItem item = new ProductItem(ac);
			item.janCode = ac.JanCode__c;
			//itemMaps.put(ac.Field3__c, new ProductItem(ac));
			itemMaps.put(ac.Field3__c, item);
			// 2021/01/05 #9593 bug fixed by zy END
			// 2019/04/15 ベネフィットホテル様より改善要望 by zy BEGIN
			accIdSet.add(ac.id);
			// 2019/04/15 ベネフィットホテル様より改善要望 by zy END
		}
		// 2019/04/15 ベネフィットホテル様より改善要望 by zy BEGIN
		for (PlanDetail__c detail : [Select AccountMasterRef__c, Price__c, TaxRate__c,PlanProdcut__c,PlanProdcut__r.Field3__c,AccountMasterRef__r.ActionType__c From PlanDetail__c  where  PlanProdcut__c = :accIdSet]){
        	AccountMaster__c acc = new AccountMaster__c(ActionType__c = detail.AccountMasterRef__r.ActionType__c);
        	if (RackRateUtils.isRoomRateProduct(acc)){
        		if (CommUtils.nullToZero(detail.Price__c) == 0){
        			if (itemMaps.containsKey(detail.PlanProdcut__r.Field3__c))
        				itemMaps.get(detail.PlanProdcut__r.Field3__c).hadRoomFlag = true;
        		}
        	}
        }
        // 2019/04/15 ベネフィットホテル様より改善要望 by zy END
		return itemMaps;
	}
	
	// プランIDにより、プラン明細情報を引き渡す
	public static List<PlanDetail> getPlanDetailList(String planId) {
		// プランIDより、プラン明細一覧を取得する
		List<PlanDetail> rsLst = new List<PlanDetail>();
        for (PlanDetail__c pd : [select AccountMasterRef__c,AccountMasterRef__r.name, Price__c,AccountMasterRef__r.ActionType__c from PlanDetail__c where PlanRef__c = :planId]) {
            PlanDetail item = new PlanDetail();
            item.prodName = CommUtils.nullToBlank(pd.AccountMasterRef__r.name);
            item.prodPrice = CommUtils.nullToZero(pd.Price__c).format();
            item.actionType = CommUtils.nullToBlank(pd.AccountMasterRef__r.ActionType__c);
            item.sobjId = pd.Id;
            item.prodId = pd.AccountMasterRef__c;
            rsLst.add(item);
        }
        return rsLst;
	}
	
	//private static final String roomPriceProdName = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomPriceProdName__c);
	public static List<PlanDetail> getPlanDetailList(String planId, Date rackrateDate) {
		// プランIDより、プラン明細一覧を取得する
		List<PlanDetail> rsLst = new List<PlanDetail>();
       	Boolean isHaveRoomDetailFlg = false;
        for (PlanDetail__c pd : [select AccountMasterRef__c,AccountMasterRef__r.name, Price__c,AccountMasterRef__r.ActionType__c from PlanDetail__c where PlanRef__c = :planId]) {
            PlanDetail item = new PlanDetail();
            item.prodName = CommUtils.nullToBlank(pd.AccountMasterRef__r.name);
            item.prodPrice = CommUtils.nullToZero(pd.Price__c).format();
            item.actionType = CommUtils.nullToBlank(pd.AccountMasterRef__r.ActionType__c);
            item.sobjId = pd.Id;
            item.prodId = pd.AccountMasterRef__c;
            rsLst.add(item);
        }
        return rsLst;
	}
	/* 2015/10/13 DELETE
	// プランIDにより、該当プランに設定されている室料明細項目を取得する
	public Map<Id, List<PlanDetail__c>> getRoomItemByPlanId(Set<Id> planIdSet) {
		// 室料自動設定用会計商品名を取得する
		Map<Id, List<PlanDetail__c>> roomItemMap = new Map<Id, List<PlanDetail__c>>();
		for (PlanDetail__c pd : [select Id, PlanRef__c, AccountMasterRef__c, Price__c from PlanDetail__c where PlanRef__c = :planIdSet
											And AccountMasterRef__r.Name = :CommConst.APPOPTION_ROOMPRICE_PRODNAME 
											And AccountMasterRef__r.ActionType__c =:CommConst.PROD_ACTION_TYPE_RP]) {
			Id planId = pd.PlanRef__c;
			if (!roomItemMap.containsKey(planId)) {
				roomItemMap.put(planId, new List<PlanDetail__c>());
			}
		 	roomItemMap.get(planId).add(pd);
		}
		return roomItemMap;
	}*/
	// 室料の会計商品を取得する
	public static List<AccountMaster__c> getRoomRateProduct(String roomRateNm) {
		return [select Id, Name,jmstRef__r.TaxRate__c,ServiceRate__c From AccountMaster__c Where Name = :roomRateNm And ActionType__c =:CommConst.PROD_ACTION_TYPE_RP limit 1];
	}
	// 2018/09/10 会計商品IDにより、プランBREAKDOWNの室料明細情報を返却する
	public static Map<Id, List<PlanDetail>> getRoomPriceByProdIds(set<id> prodIdSet) {
		// プランIDより、プラン明細一覧を取得する
		Map<Id, List<PlanDetail>> retMap = new Map<Id, List<PlanDetail>>();
		// 室料　かつ　室料>0
        for (PlanDetail__c pd : [select PlanProdcut__c,Id,AccountMasterRef__c,AccountMasterRef__r.name, Price__c,AccountMasterRef__r.ActionType__c from PlanDetail__c 
        							where PlanProdcut__c = :prodIdSet and AccountMasterRef__r.ActionType__c = :CommConst.PROD_ACTION_TYPE_RP And Price__c > 0]) {
            
            PlanDetail item = new PlanDetail();
            item.prodName = CommUtils.nullToBlank(pd.AccountMasterRef__r.name);
            item.prodPrice = CommUtils.nullToZero(pd.Price__c).format();
            item.actionType = CommUtils.nullToBlank(pd.AccountMasterRef__r.ActionType__c);
            item.sobjId = pd.Id;
            item.prodId = pd.AccountMasterRef__c;
            // 会計商品プラン単位で、含めている室料リストを取得する
            if (!retMap.containsKey(pd.PlanProdcut__c)) retMap.put(pd.PlanProdcut__c, new List<PlanDetail>());
            retMap.get(pd.PlanProdcut__c).add(item);
        }
        return retMap;
	}
	// 会計商品IDにより、室料会計商品リストを返却する
	public static set<Id> checkRoomProduct(set<id> prodIdSet) {
		map<Id,AccountMaster__c> rsMap = new map<Id,AccountMaster__c>([select id from AccountMaster__c where id in :prodIdSet and ActionType__c = :CommConst.PROD_ACTION_TYPE_RP]);
		return rsMap.keyset();
	}
	// プラン明細情報を維持する
	global class PlanDetail {
		public String prodName{get; set;}
		public String prodPrice{get; set;}
		public String sobjId{get;set;}
		public String actionType{get;set;}
		public String prodId{get;set;}
	}
	/**
	* 会計商品情報を格納用
	**/
	global class ProductItem {
		// 2017/10/12 検索機能対応、キーワードが一つ場合、LIKE方式で商品名と商品コードをヒントする、半角スペースで複数キーワードをいれるとき、SOSL方式で検索を行う BEGIN
	    public ProductItem(AccountMaster__c acc) {
	       init(acc, null);
	    } 
	    public ProductItem(AccountMaster__c acc, List<PlanDetail__c> noTaxPlanDt) {
            init(acc, noTaxPlanDt);
	    }
	    // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
	    public ProductItem(AccountMaster__c acc, List<PlanDetail__c> noTaxPlanDt, Boolean wkIsOptionPgFlg) {
	    	isOptionPgFlg = wkIsOptionPgFlg;
            init(acc, noTaxPlanDt);
	    }
	    // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
	    private void init(AccountMaster__c acc, List<PlanDetail__c> noTaxPlanDt) {
	    // 2017/10/12 検索機能対応、キーワードが一つ場合、LIKE方式で商品名と商品コードをヒントする、半角スペースで複数キーワードをいれるとき、SOSL方式で検索を行う END
			productId = acc.Id;
			prodcutName = acc.Name;
			prodcutCode = acc.Field3__c;
			hadRoomFlag = false;
			unitPrice = CommUtils.nullToZero(acc.Field5__c);
			tax = CommUtils.nullToZero(acc.TaxRateCal__c);
			serviceRate = CommUtils.nullToZero(acc.ServiceRate__c);
			specialTax = CommUtils.nullToZero(acc.SpecialTax__c);
			actionType = CommUtils.nullToBlank(acc.ActionType__c);
			paymentType = CommUtils.nullToBlank(acc.PaymentType__c);
			discountRate = CommUtils.nullToZero(acc.DiscountRate__c);

			childs = new List<ProductItem>();
			unitPriceExcTax = 0;
			// 2018/10/04 原価金額を返却する WSQ BEGIN
			basePrice = CommUtils.nullToZero(acc.Field7__c);
			// 2018/10/04 原価金額を返却する WSQ END
			// 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
			bTaxAccMstItem = null;
			try{
				if(acc.PlanBathTaxAccMstRef__c != null && acc.PlanBathTaxAccMstRef__r.BathTaxAccMstRef__c != null){
					bTaxAccMstItem = new ProductItem(acc.PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r);
				}
			} catch (Exception e) {}
			// 2020/07/30 入湯税の自動入力機能について改善 WGCH END
			// 2018/07/27 宿泊税計算 WGCH BEGIN
			/*
			if (acc.PlanProdcutRef__r != null && !acc.PlanProdcutRef__r.isEmpty()) {
				for (PlanDetail__c detail : acc.PlanProdcutRef__r) {
					
					AccountMaster__c newAcc = new AccountMaster__c(
						Field5__c = detail.Price__c
					);
					ProductItem child = new ProductItem(newAcc);
					child.tax = CommUtils.nullToZero(detail.TaxRate__c);
					childs.add(child);

					// 2015/10/16**********BEGIN
					// 2018/08/06 金額null修正 WGCH BEGIN
					// unitPriceExcTax +=	detail.Price__c;
					unitPriceExcTax += CommUtils.nullToZero(detail.Price__c);
					// 2018/08/06 金額null修正 WGCH END
					// 2015/10/16**********END
					*/
			planItemPriceLst = new List<Decimal>();
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			pdProductItem = new List<ProductItem>(); 
			// 2019/07/30 軽減税率機能対応 WGCH END
			// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
			diffUnitSum = 0;
			numMin = numMax = optionAccMstNum = 0;
			isUnitPriceZero = optionAccMstFlg = hasOptionMstFlg = false;
			if(isOptionPgFlg == null) isOptionPgFlg = isOpPgFlg;
			gKeyItemKeyLst = new List<String>();
			// optionModeKey对应室料金额Lst
			gPlanItemPriceLstMap = new Map<String, List<Decimal>>();
			// 数量对应optionMode
			gNumToKeyMap = new Map<Decimal, String>();
			// optionModeKey对应明细Lst
			gKeyItemMap = new Map<String, List<ProductItem>>();
			// option商品Lst
			List<ProductItem> optMstLst = new List<ProductItem>();
			// 普通商品Lst
			List<ProductItem> genMstLst = new List<ProductItem>();
			// 室料商品Lst
			List<ProductItem> romMstLst = new List<ProductItem>();
			// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
			List<PlanDetail__c> pDetailLst = acc.PlanProdcutRef__r;
			if((pDetailLst == null || pDetailLst.isEmpty()) && pDetailMap.containsKey(productId)) pDetailLst = pDetailMap.get(productId);
			if (pDetailLst != null && !pDetailLst.isEmpty()) {
				for (PlanDetail__c detail : pDetailLst) {
					// 2019/07/30 軽減税率機能対応 WGCH BEGIN
					AccountMaster__c pdAccMst = detail.AccountMasterRef__r == null ? new AccountMaster__c() : detail.AccountMasterRef__r;
					pdAccMst.Field5__c = detail.Price__c;
					pdAccMst.ActionType__c = CommUtils.nullToBlank(detail.AccountMasterRef__r.ActionType__c);
					pdAccMst.ServiceRate__c = CommUtils.nullToZero(detail.ServiceRate__c);
					ProductItem pdAccMstItem = new ProductItem(pdAccMst);
					pdAccMstItem.tax =  CommUtils.nullToZero(detail.TaxRate__c);
					// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
					pdAccMstItem.pdId = CommUtils.nullToBlank(detail.Id);
					pdAccMstItem.prodcutName = CommUtils.nullToBlank(detail.AccountMasterRef__r.Name);
					// option商品数量
					pdAccMstItem.optionAccMstNum = CommUtils.nullToIntZero(detail.Amount__c);
					// option商品FLG
					pdAccMstItem.optionAccMstFlg = detail.OptionAccMstFLG__c == null ? false : detail.OptionAccMstFLG__c;
					pdAccMstItem.isUnitPriceZero = pdAccMstItem.unitPrice == 0;
					// 2020/05/29 bug fixed 6428 WGCH BEGIN
					if(pdAccMstItem.isUnitPriceZero && !isUnitPriceZero) isUnitPriceZero = pdAccMstItem.isUnitPriceZero;
					// 2020/05/29 bug fixed 6428 WGCH END
					// 此笔数据是option商品时处理
					if(pdAccMstItem.optionAccMstFlg){
						// 初期最小值设定
						if(!hasOptionMstFlg) numMin = pdAccMstItem.optionAccMstNum;
						// 标识此笔Plan明细内包含了option商品
						hasOptionMstFlg = true;
						// 最小数量设定
						numMin = numMin < pdAccMstItem.optionAccMstNum ? numMin : pdAccMstItem.optionAccMstNum;
						// 最大数量设定
						numMax = numMax > pdAccMstItem.optionAccMstNum ? numMax : pdAccMstItem.optionAccMstNum;
						optMstLst.add(pdAccMstItem);
						// 2020/05/29 bug fixed 6428 WGCH BEGIN
						if(!isOptionSetlg || !isOptionPgFlg) unitPrice += CommUtils.nullToZero(pdAccMstItem.unitPrice);
						// 2020/05/29 bug fixed 6428 WGCH END
					}
					// 室料明细处理
					else if(pdAccMstItem.actionType == CommUtils.escStr(CommConst.PROD_ACTION_TYPE_RP)) romMstLst.add(pdAccMstItem);
					// 普通明细处理
					else genMstLst.add(pdAccMstItem);
					// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
					pdProductItem.add(pdAccMstItem);
					// 2019/07/30 軽減税率機能対応 WGCH END
					if(detail.AccountMasterRef__r.ActionType__c == CommUtils.escStr(CommConst.PROD_ACTION_TYPE_RP)){ // 室料明细处理
						planItemPriceLst.add(CommUtils.nullToZero(detail.Price__c));
					}
					if(detail.TaxRate__c == 0 || detail.TaxRate__c == null){
						AccountMaster__c newAcc = new AccountMaster__c(
							Field5__c = detail.Price__c
						);
						ProductItem child = new ProductItem(newAcc);
						child.tax = CommUtils.nullToZero(detail.TaxRate__c);
						childs.add(child);
	
						// 2018/08/06 金額null修正 WGCH BEGIN
						// unitPriceExcTax += detail.Price__c;
						unitPriceExcTax += CommUtils.nullToZero(detail.Price__c);
						// 2018/08/06 金額null修正 WGCH END
					}
					// 2018/07/27 宿泊税計算 WGCH END
				}
			}
			// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
			// 含有Option商品处理
			// 2020/05/29 bug fixed 6428 WGCH BEGIN
			if(isOptionSetlg && hasOptionMstFlg){
			// 2020/05/29 bug fixed 6428 WGCH END
				// 数量对应数据集处理
				for(Integer i = 0; i < (numMax+1); i++){
					// 当前数量对应的数据集合
					List<ProductItem> gItemLst = new List<ProductItem>();
					List<Decimal> gPlanItemPriceLst = new List<Decimal>();
					// 差值单价金额
					Decimal diffUnit = 0;
					// option商品处理
					for(ProductItem pd : optMstLst){
						ProductItem gPd = pd.clone(); // 防止地址共存
						// 满足条件ADD
						if(i < gPd.optionAccMstNum){
							diffUnit += gPd.unitPrice;
							gItemLst.add(gPd);
						}
					}
					// 室料商品处理
					for(ProductItem pd : romMstLst){
						ProductItem gPd = pd.clone(); // 防止地址共存
						// 差值金额累加
						gPd.unitPrice -= diffUnit;
						// 差值
						gPd.diffUnitSum = diffUnit;
						if(gPd.unitPrice < 0) gPd.unitPrice = 0;
						gItemLst.add(gPd);
						// 室料单价
						gPlanItemPriceLst.add(gPd.unitPrice);
						// 防止重复设定
						diffUnit = 0;
					}
					// 普通商品处理
					for(ProductItem pd : genMstLst){
						ProductItem gPd = pd.clone(); // 防止地址共存
						gItemLst.add(gPd);
					}
					// 数量
					Integer num = i + 1;
					String key = '';
					// 当前optionModeKey拼接
					for(ProductItem pd : gItemLst){
						key += pd.pdId + '_';
					}
					key = key.removeEnd('_');
					// 数量对应optionModeKey集计
					gNumToKeyMap.put(num, key);
					// optionModeKey集计
					if(!gKeyItemKeyLst.contains(key)) gKeyItemKeyLst.add(key);
					// optionModeKey对应数据集合Lst
					if(!gKeyItemMap.containsKey(key)) gKeyItemMap.put(key, gItemLst);
					// optionModeKey对应室料集合Lst
					if(!gPlanItemPriceLstMap.containsKey(key)) gPlanItemPriceLstMap.put(key, gPlanItemPriceLst);
				}
			}
			// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
			// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
			prodNum = '1';
			// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
		}
		public List<ProductItem> childs{get; private set;}
		public String productId{get;set;}
		public String prodcutName{get;set;}
		public String prodcutCode{get;set;}
		public Decimal unitPrice{get;set;}
		public Decimal tax{get;set;}
		public Decimal serviceRate{get;set;}
		public Decimal specialTax{get;set;}
		public String actionType{get;set;}
		public String paymentType{get;set;}	// 支払種別
		public Decimal discountRate{get;set;}	// 割引率
		// 2015/10/16**********BEGIN
		public Decimal unitPriceExcTax{get;set;}
		// 2015/10/16**********END
		public boolean hadRoomFlag{get;set;}
		// 2018/07/27 宿泊税計算 WGCH BEGIN
		public List<Decimal> planItemPriceLst{get;set;}
		// 2018/07/27 宿泊税計算 WGCH END
		// 2018/10/04 原価金額を返却する WSQ BEGIN
		public Decimal basePrice{get;set;}
		// 2018/10/04 原価金額を返却する WSQ END
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		public List<ProductItem> pdProductItem{get{if(pdProductItem == null) pdProductItem = new List<ProductItem>(); return pdProductItem;} private set;}
		// 2019/07/30 軽減税率機能対応 WGCH END
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
		public String pdId{get;set;}
		public Decimal diffUnitSum{get;set;}
		public Boolean isRoomTpFlg{get {return (actionType == CommUtils.escStr(CommConst.PROD_ACTION_TYPE_RP));} set;}
		public Boolean isOptionPgFlg{get; set;} // 有效Page设定
		public Integer numMin{get;set;} // 最小数量
		public Integer numMax{get;set;} // 最大数量
		public Integer optionAccMstNum{get;set;} // option商品对应的数量
		public Boolean isUnitPriceZero{get;set;}
		public Boolean optionAccMstFlg{get;set;} // option商品FLG
		public Boolean hasOptionMstFlg{get;set;} // Plan内还有option商品FLG
		public List<String> gKeyItemKeyLst{get;set;}
		public Map<String, List<Decimal>> gPlanItemPriceLstMap{get;set;} // optionModeKey对应室料金额Lst
		public Map<Decimal, String> gNumToKeyMap{get;set;} // num -> OptionKey
		public Map<String, List<ProductItem>> gKeyItemMap{get;set;} // OptionKey -> 数据集合
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
		// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
		public String prodNum{get;set;} // 最大数量
		// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
		// 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
		public ProductItem bTaxAccMstItem{get;set;}
		// 2020/07/30 入湯税の自動入力機能について改善 WGCH END
		// 2020/12/15 会計商品にJANコードを登録し、それをバーコードリーダーで読み取り、会計処理が行えるようにしたい by zy BEGIN 
		public String janCode; // JANコード
		// 2020/12/15 会計商品にJANコードを登録し、それをバーコードリーダーで読み取り、会計処理が行えるようにしたい by zy END 
	}
/**
*2015-11-18 
*テストクラスProductItemUtilsTestに移行する 
	@isTest static void myUnit() {
		List<AccountMaster__c> accLst = TestCommon.createProductMst(10);
		ProductItemUtils.ProductItem item = ProductItemUtils.getSingProdcutItemByCode(accLst[0].Field3__c);
		System.assertEquals(item.prodcutCode,accLst[0].Field3__c);
		Boolean isNotFound = false;
		Try {
			item = ProductItemUtils.getSingProdcutItemByCode('ABCD' + CommUtils.getRandom(9));
		} catch (Exception e) {
			isNotFound = true;
		}
		System.assertEquals(isNotFound, true);
		// 関連の呼び出しクラス呼び出す
		item = BillInput_Ctrl.getProductItemInfo(accLst[0].Field3__c);
		System.assertEquals(item.prodcutCode,accLst[0].Field3__c);
		item = BookingEstimateItemSetup.getProductItemInfo(accLst[0].Field3__c);
		System.assertEquals(item.prodcutCode,accLst[0].Field3__c);
		item = SimpleAccountsCtrl.getProductItemInfo(accLst[0].Field3__c);
		System.assertEquals(item.prodcutCode,accLst[0].Field3__c);
		List<ProductItemUtils.ProductItem> items = ProductItemUtils.getArrayProdcutItemByCode(accLst[0].Field3__c);
		System.assertEquals(items[0].prodcutCode,accLst[0].Field3__c);
		items = ProductItemUtils.getArrayProdcutItemByCode('ABCD' + CommUtils.getRandom(9));
		System.assertEquals(items.size(),0);
		items = BillInput_Ctrl.getArrayProductItemInfo(accLst[0].Field3__c);
		System.assertEquals(items[0].prodcutCode,accLst[0].Field3__c);
		items = BookingEstimateItemSetup.getArrayProductItemInfo(accLst[0].Field3__c);
		System.assertEquals(items[0].prodcutCode,accLst[0].Field3__c);
		items = SimpleAccountsCtrl.getArrayProductItemInfo(accLst[0].Field3__c);
		System.assertEquals(items[0].prodcutCode,accLst[0].Field3__c);
		
		String roomPriceProdName = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomPriceProdName__c);
		ProductItemUtils.getRoomRateProduct(roomPriceProdName);
		
		Plan__c plan = TestCommon.createPlan();
		List<ProductItemUtils.PlanDetail> rs1 = ProductItemUtils.getPlanDetailList(plan.Id);
		List<ProductItemUtils.PlanDetail> rs2 = ProductItemUtils.getPlanDetailList(plan.Id, Date.today());
		Set<Id> planIdSet = new Set<Id>();
		planIdSet.add(plan.id);
		ProductItemUtils planutil = new ProductItemUtils();
		//Map<Id, List<PlanDetail__c>> rs3 = planutil.getRoomItemByPlanId(planIdSet);
		
	}
*/
	// 2019/11/15 最近利用している商品一覧機能を提供する BY zyz BEGIN
	public static void viewInfo (Id accId){
		// 最近使った商品
		// List<AccountMaster__c> accountMaster = [select Id,Name from AccountMaster__c where Id =: accId FOR REFERENCE];
		// 最近参照した商品
		List<AccountMaster__c> accountMaster = [select Id,Name from AccountMaster__c where Id =: accId FOR VIEW];
	}
	// 2019/11/15 最近利用している商品一覧機能を提供する BY zyz END
	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
	public static String OPTION_MODE{get{ return (CommConst.OPTION_MODE);} set;}
	public static Boolean isReducedTaxFlg{get{ return (CommConst.REDUCED_TAXRATE_FLG);} set;}
	public static Boolean isOptionSetlg{get{ return (isReducedTaxFlg && OPTION_MODE == CommConst.OPTION_MODE_ON);} set;}
	public class LeadInfoSync{
		public LeadInfoSync(){
			romUnitPriceSum = optUnitPriceSum = 0;
			optMstLst = new List<ProductItem>();
			romMstLst = new List<ProductItem>();
			genMstLst = new List<ProductItem>();
			itemMap = new Map<String, ProductItem>();
			numToOpPdLstMap = new Map<Integer, List<ProductItem>>();
		}
		
		public Decimal romUnitPriceSum; // 当前对应的商品单价合计值
		public Decimal optUnitPriceSum; // 当前对应的OPTION商品单价合计值
		public List<ProductItem> optMstLst;
		public List<ProductItem> romMstLst;
		public List<ProductItem> genMstLst;
		public Map<String, ProductItem> itemMap;
		public Map<Integer, List<ProductItem>> numToOpPdLstMap;
	}
	public class PlanOrgPdInfo{
		public PlanOrgPdInfo(List<PlanDetail__c> orgPdList, LeadInfoSync ldInfo){
			this.orgPdList = orgPdList;
			this.ldInfo = ldInfo;
		}
		public List<PlanDetail__c> orgPdList;
		public LeadInfoSync ldInfo;
	}
	// 2020/05/29 bug fixed 6440 WGCH BEGIN
	public static void getNewPlanData(List<PlanDetail__c> orgPdList, Plan__c plan){
		// OPTION关闭情况要把OPTION金额补上
		for(PlanDetail__c sobj : orgPdList){
			if(sobj.OptionAccMstFLG__c){
				// 利用地址共存重置单价
				plan.Price__c = CommUtils.nullToZero(plan.Price__c) + CommUtils.nullToZero(sobj.Price__c);
			}
		}
	}
	// 2020/05/29 bug fixed 6440 WGCH END
	public static LeadInfoSync getOptionPlanDetailInfo(List<PlanDetail__c> pDetailLst){
		LeadInfoSync ldInfo = new LeadInfoSync();
		Integer numMax = 0;
		for (PlanDetail__c detail : pDetailLst) {
			AccountMaster__c pdAccMst = detail.AccountMasterRef__r == null ? new AccountMaster__c() : detail.AccountMasterRef__r;
			pdAccMst.Field5__c = detail.Price__c;
			pdAccMst.ActionType__c = CommUtils.nullToBlank(detail.AccountMasterRef__r.ActionType__c);
			pdAccMst.ServiceRate__c = CommUtils.nullToZero(detail.ServiceRate__c);
			ProductItem pdItem = new ProductItem(pdAccMst);
			pdItem.tax =  CommUtils.nullToZero(detail.TaxRate__c);
			pdItem.pdId = CommUtils.nullToBlank(detail.Id);
			pdItem.prodcutName = CommUtils.nullToBlank(detail.AccountMasterRef__r.Name);
			// option商品数量
			pdItem.optionAccMstNum = CommUtils.nullToIntZero(detail.Amount__c);
			// option商品FLG
			pdItem.optionAccMstFlg = detail.OptionAccMstFLG__c == null ? false : detail.OptionAccMstFLG__c;
			
			if(detail.OptionAccMstFLG__c){
				ldInfo.optUnitPriceSum += pdItem.unitPrice;
				// 最大数量设定
				numMax = numMax > CommUtils.nullToIntZero(detail.Amount__c) ? numMax : CommUtils.nullToIntZero(detail.Amount__c);
				ldInfo.optMstLst.add(pdItem);
			}
			// 室料明细处理
			else if(pdItem.isRoomTpFlg){
				ldInfo.romUnitPriceSum += pdItem.unitPrice;
				ldInfo.romMstLst.add(pdItem);
			// 普通商品
			} else ldInfo.genMstLst.add(pdItem);
			ldInfo.itemMap.put(pdItem.pdId, pdItem);
		}
		if(ldInfo.optMstLst.isEmpty()) return ldInfo;
		for(Integer i = 0; i < (numMax + 1); i++){
			List<ProductItem> gItemLst = new List<ProductItem>();
			// option商品处理
			for(ProductItem gPd : ldInfo.optMstLst){
				// 满足条件ADD
				if(i < gPd.optionAccMstNum){
					gItemLst.add(gPd);
				}
			}
			if(!gItemLst.isEmpty()) ldInfo.numToOpPdLstMap.put((i+1), gItemLst);
		}
		return ldInfo;
	}
	// 获取最终PLAN明細
	public static PlanOrgPdInfo getPlanOrgPdInfo(List<PlanDetail__c> orgPdList, LeadInfoSync ldInfo){
		List<PlanDetail__c> optOrgPdList = new List<PlanDetail__c>();
		List<PlanDetail__c> nwOrgPdList = new List<PlanDetail__c>();
		Decimal opUnitPriceSum = 0;
		for(PlanDetail__c sobj : orgPdList){
			// 集计所有明细
			optOrgPdList.add(sobj.clone(true, true));
			if(sobj.OptionAccMstFLG__c) continue;
			opUnitPriceSum += CommUtils.nullToZero(sobj.Price__c);
			// 集计非OPTION商品明细
			nwOrgPdList.add(sobj);
		}
		if(optOrgPdList.size() > nwOrgPdList.size()){
			ldInfo = getOptionPlanDetailInfo(optOrgPdList);
			orgPdList = nwOrgPdList;
		}
		return (new PlanOrgPdInfo(orgPdList, ldInfo));
	}
	// 获取最终見積明細
	public static List<BookingEstimateItem__c> getNwDetailLst(List<BookingEstimateItem__c> detailLst, LeadInfoSync ldInfo){
		Integer min = 0;
		List<BookingEstimateItem__c> nwDetailLst = new List<BookingEstimateItem__c>();
		for(BookingEstimateItem__c sobj : detailLst){
			Integer max = CommUtils.nullToIntZero(sobj.Amount__c) + min;
			List<BookingEstimateItem__c> bookEstLst = getBooingEstInf(ldInfo, sobj, min, max);
			// 集计最新的数据
			nwDetailLst.addAll(bookEstLst);
			min = max;
		}
		if(!nwDetailLst.isEmpty()){
			detailLst = nwDetailLst;
		}
		return detailLst;
	}
	public static List<BookingEstimateItem__c> getBooingEstInf(LeadInfoSync ldInfo, BookingEstimateItem__c sobj, Integer min, Integer max){
		return getBooingEstInf(ldInfo, sobj, min, max, null);
	}
	public static List<BookingEstimateItem__c> getBooingEstInf(LeadInfoSync ldInfo, BookingEstimateItem__c sobj, Integer min, Integer max, CommLogUtils mLogUtils){
		Boolean isSetLog = mLogUtils != null;
		Map<String, Integer> syncToNumMap = new Map<String, Integer>();
		List<BookingEstimateItem__c> bookEstLst = new List<BookingEstimateItem__c>();
		// 2020/05/29 bug fixed 6454 WGCH BEGIN
		sobj.OptionNo__c = CommUtils.nullToBlank(min);
		// 2020/05/29 bug fixed 6454 WGCH END
		for(Integer i = (min+1); i < (max+1); i++){
			List<ProductItem> opPdLst = ldInfo.numToOpPdLstMap.get(i);
			// 当前对应的OPTION商品SYNC
			String optSyncInf = '';
			// 当前对应的OPTION商品单价合计值
			Decimal opUnitPriceSum = 0;
			// 设定满足条件的OPTION商品FLG
			Boolean isSetOptionMstFlg = true;
			// 最新SYNC
			String planSyncInf = '';
			if(opPdLst != null){
				for(ProductItem item : opPdLst){
					opUnitPriceSum += item.unitPrice;
					// 集计当前SYNC
					optSyncInf += item.pdId + ':' + item.unitPrice + ':' + item.productId + ':' + item.prodcutName +';';
				}
			}
			if(sobj.PlanDetailSyncInfo__c != null && sobj.PlanDetailSyncInfo__c != CommConst.CONST_PLANITEM_NOEXPAND){
				// 解析原有的SYNC
				String[] prods = CommUtils.nullToBlank(sobj.PlanDetailSyncInfo__c).split(';');
				for(Integer m = 0 ; m < prods.size(); m++) {
					String message = prods[m];
					if (CommUtils.isBlank(message)) continue;
					// Plan明细ID
					String firstId = message.subStringBefore(':');
					String[] str = message.split(':');
					if(ldInfo.itemMap.containsKey(firstId)){
						ProductItem item = ldInfo.itemMap.get(firstId);
						// 当前有效的室料重置处理
						if(item.pdId == firstId && item.isRoomTpFlg){
							// 室料商品金额
							Decimal romUnitPrice = CommUtils.nullToZero(str[1]);
							// 去掉总OPTION商品后的室料商品金额
							Decimal wkRomUnitPrice = romUnitPrice - ldInfo.optUnitPriceSum;
							if(wkRomUnitPrice < 0){
								isSetOptionMstFlg = false;
							} else {
								// 集计当前SYNC
								planSyncInf += item.pdId + ':' + (romUnitPrice - opUnitPriceSum) + ':' + item.productId + ':' + item.prodcutName +';';
								continue;
							}
						}
					}
					// 集计当前SYNC
					planSyncInf += message + ';';
				}
			} else {
				// 去掉总OPTION商品后的室料商品金额
				Decimal wkRomUnitPrice = ldInfo.romUnitPriceSum - ldInfo.optUnitPriceSum;
				// 普通
				for(ProductItem item : ldInfo.genMstLst){
					// 集计当前SYNC
					planSyncInf += item.pdId + ':' + item.unitPrice + ':' + item.productId + ':' + item.prodcutName +';';
				}
				if(wkRomUnitPrice < 0){
					isSetOptionMstFlg = false;
					// 室料
					for(ProductItem item : ldInfo.romMstLst){
						// 集计当前SYNC
						planSyncInf += item.pdId + ':' + item.unitPrice + ':' + item.productId + ':' + item.prodcutName +';';
					}
				} else {
					// 室料-TODO: 目前只是支持一个室料的情况
					for(ProductItem item : ldInfo.romMstLst){
						// 集计当前SYNC
						planSyncInf += item.pdId + ':' + (ldInfo.romUnitPriceSum - opUnitPriceSum) + ':' + item.productId + ':' + item.prodcutName +';';
					}
				}
			}
			if(isSetOptionMstFlg) planSyncInf += optSyncInf;
			// 集计对应的数量
			if(!syncToNumMap.containsKey(planSyncInf)) syncToNumMap.put(planSyncInf, 0);
			Integer numEnd = syncToNumMap.get(planSyncInf) + 1;
			syncToNumMap.put(planSyncInf, numEnd);
		}
		for(String sync : syncToNumMap.keySet()){
			BookingEstimateItem__c wkSobj = sobj.clone();
			// 最终重置数量字段数据
			wkSobj.Amount__c = syncToNumMap.get(sync);
			// 最终重置SYNC字段数据
			wkSobj.PlanDetailSyncInfo__c = sync;
			bookEstLst.add(wkSobj);
		}
		if(bookEstLst.isEmpty()) bookEstLst.add(sobj);
		return bookEstLst;
	}
	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
}