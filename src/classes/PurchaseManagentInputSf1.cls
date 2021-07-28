public with sharing class PurchaseManagentInputSf1 {
   
    private ApexPages.StandardController singCtrl;
    public PurchaseManagentInputSf1(ApexPages.StandardController controller) {
        singCtrl = controller;
    }
    
    public List<PurchaseManagentInput.ItemInfo> fileLst{get; private set;}
    public void InitView() {
        // 入力項目初期化する
        UserUtil.UserShopInfo userInf = UserUtil.CurrentUserInfo;
        // 店舗項目リスト初期化する
        shopOpts = ShopInfoUtil.getBranchShopLst(userInf.shops);
        // 関連の仕入情報を取得する
        reInitCtrlInfo(singCtrl.getId(), false);
        // 既に存在の添付ファイルを取得する
        PurchaseManagentInput helpCtrl = new PurchaseManagentInput(true);
        PurchaseManagentInput.ItemInfo item = new PurchaseManagentInput.ItemInfo();
        item.pur = (Purchase__c)singCtrl.getRecord();
        List<Attachment> files = item.pur.Attachments;
        if (!files.isEmpty()) {
            item.fileId = files[0].Id;
            item.fileNm = files[0].Name;
            item.fileLastModifyDt = files[0].LastModifiedDate;
        }
        fileLst = new List<PurchaseManagentInput.ItemInfo>();
        fileLst.add(item);
        helpCtrl.linkRelContentDoc(fileLst);
        System.debug(loggingLevel.info,'fileLst=='+fileLst);
    }
    // 店舗リスト
    public transient List<SelectOption> shopOpts  {get; private set;}
    // 数字入力モード設定
    /*
    public string imeMode{get{
        if (CommUtils.nullToZero(getPointLen()) > 0) {
            return '-?¥?(([1-9](\\d*|\\d{0,2}(,\\d{3})*))|0)(\\.\\d{'+getPointLen()+'})?$';
        } else {
            return '-?¥?(([1-9](\\d*|\\d{0,2}(,\\d{3})*))|0)?$';
        }
    }}*/
    // 端数処理区分[取込先変更により、変更を行う]
    public transient integer roundMode{get;private set;}  
    // 消費税率  
    public transient Decimal commTaxRate{get;private set;}
    public transient string xmlShopNotaxTypeMapJson{get; private set;}
    public transient string xmlShopNotaxTypeRightMapJson{get; private set;}
    public transient string xmlDefaultSetShopCode{get; private set;}
    public transient String profileNm{get; private set;}
    //
    //public transient String typeTokamokuJson{get;private set;}
    //小数点桁数
    public String getPointLen() { return CommBaseCtrl.getPointLen(); }
    public String getCurrencySybmol() { return CommBaseCtrl.getCurrencySybmol(); }
    public String getNs() { return CommBaseCtrl.getNs(); }
    //仕入日
    public transient String strSalesDate{get;set;}
    // 金額（税抜）
    public transient Decimal payAmountExcTax{get;set;}
    // 金額（税込)
    public transient Decimal payAmountIncTax{get;set;}
    public String getNumberFormat(){ return CommUtils.getNumberFormat();}
    // 店舗情報
    private transient String shopId;
    //
    public String shopIdToCdMapJson{get;set;}
    public String viewPrefix{get{
        return Purchase__c.sobjecttype.getDescribe().getKeyPrefix();
    }}
    // 画面情報表示用
    public transient Purchase__c pur{get;private set;}
    public void InitEdit() {
        // 入力項目初期化する
        UserUtil.UserShopInfo userInf = UserUtil.CurrentUserInfo;
        // ユーザー所属する店舗情報コードを取得する
        String currentShopCode = userInf.defaultShopCode;
        // データ保存情報変数初期化
        //inpData = new ItemInfo();
        // 店舗項目リスト初期化する
        shopOpts = ShopInfoUtil.getBranchShopLst(userInf.shops);
        // 店舗情報MAPを取得する
        Map<String,ShopInformation__c> shopInfoMap = ShopInfoUtil.getShopInfoMap(userInf.shops);
        
        Map<String,String> shopIdToCdMap = new Map<String,String>(); 
        for (SelectOption opt : shopOpts) {
            ShopInformation__c wkSp = shopInfoMap.get(opt.getValue());
            if(wkSp == null) continue;
            shopIdToCdMap.put(wkSp.Id,opt.getValue());
            opt.setValue(wkSp.Id);
            if (currentShopCode == wkSp.ShopCode__c) shopId = wkSp.Id;
        }
        shopIdToCdMapJson = JSON.serialize(shopIdToCdMap);
        // 入力項目初期化する
        //input = new InputForm();
        // 消費税情報
        JMST__c jmst = CommLogicProcess.getTaxRateInfo();
        commTaxRate = jmst.taxRate__c;
        // 2016/01/19 LOCALのプロファイル名を取得する BEGIN
        profileNm = CommLogicProcess.getLoginUserProfile().name;
        // 共通定義情報の読み込み処理する
        AccountingSyncBatchHelp  help = new AccountingSyncBatchHelp(currentShopCode);
        // 種別と科目関連の税対象がどうか
        //typeTokamokuJson = help.typeTokamokuJson;
        roundMode = CommBaseCtrl.getRoundType();
        // 関連のレポートIDを取得する
        // 2016/04/21 課税対象外自動設定機能対応
        PurchaseManagentInput helpCtrl = new PurchaseManagentInput(true);
        helpCtrl.initPhashTypeKamokuInfo();
        xmlShopNotaxTypeMapJson = helpCtrl.xmlShopNotaxTypeMapJson;
        xmlShopNotaxTypeRightMapJson = helpCtrl.xmlShopNotaxTypeRightMapJson;
        xmlDefaultSetShopCode = helpCtrl.xmlDefaultSetShopCode;
        // COPYから場合
        Map<String,String> paramMap = Apexpages.currentPage().getParameters();
        if (paramMap.containsKey('cid')) {
            reInitCtrlInfo(paramMap.get('cid'),true);
        } else if (CommUtils.isBlank(singCtrl.getId())) {
            reInitCtrlInfo(null, true);
        } else {
            reInitCtrlInfo(singCtrl.getId(), false);
        }
	    // 2019/10/15 現在料理の仕入れはsalesforceアプリの仕入（標準）上から入力しているのですが、この画面には「消費税」項目が表示されていないため、追加していただきたいです by zy BEGIN
        initTaxList();
	    // 2019/10/15 現在料理の仕入れはsalesforceアプリの仕入（標準）上から入力しているのですが、この画面には「消費税」項目が表示されていないため、追加していただきたいです by zy END
    }
    
    @remoteAction
    public static List<String> getAccount(String accountId){
        String[] rsArr = new String[]{'',''};
        List<Account> accounts = [Select name,Id ,RoundType__c from Account where id = :accountId limit 3];
        if (accounts.isEmpty()) {
            rsArr[1] = Label.MSG_040_0094;
            return rsArr;
        }
        Account acc = accounts[0];
        // 共通定義の端数処理区分
        RoundingMode roundMode = CommUtils.pointRoundMode();
        // 取込先単位の端数処理区分
        if (!CommUtils.isBlank(acc.RoundType__c)) roundMode = Commutils.pointRoundMode(acc.RoundType__c);
        rsArr[0] = CommUtils.nullToBlank(CommUtils.getRoundTypeKbnByRoundMode(roundMode));
        return rsArr;
    }
    // IDにより、関連情報を再取得する
    private void reInitCtrlInfo(Id purId, Boolean isClone) {
        // 2019/10/15 現在料理の仕入れはsalesforceアプリの仕入（標準）上から入力しているのですが、この画面には「消費税」項目が表示されていないため、追加していただきたいです by zy BEGIN
        String queryHeader = 'select id, Name, StatusLst__c, KamokuLst__c,ShopInfoRef__c,ShopInfoRef__r.ShopCode__c, PsalesproductRef__c,PsalesproductRef__r.name,Purchasesource__r.RoundType__c ,DenpyoukeiIncTax__c,Denpyoukei__c,Purchasesource__c,JinyaRevenue__c,JinyaRevenue__r.Salesday__c,Field1__c,PurchaseType__c,Memo__c,NoTaxFlg__c,TaxRateCal__c,TaxRate__c ';
        // 2019/10/15 現在料理の仕入れはsalesforceアプリの仕入（標準）上から入力しているのですが、この画面には「消費税」項目が表示されていないため、追加していただきたいです by zy END
        Id currUserId = UserInfo.getUserId();
        // 新規の場合
        if (CommUtils.isBlank(purId)) {
            queryHeader += ' from Purchase__c where JinyaRevenue__c != null And CreatedById =:currUserId Order By CreatedDate desc limit 1 ';
        } else {
            queryHeader += ' ,(Select Id, Name,LastModifiedDate From Attachments order by LastModifiedDate desc limit 1) from Purchase__c where JinyaRevenue__c != null And Id = :purId limit 1 ';
        }
        List<Purchase__c> purs = DataBase.query(queryHeader);
        if (!purs.isEmpty()) {
            pur = (isClone ? purs[0].clone(false,true) : purs[0]);
            singCtrl = new ApexPages.StandardController(pur);
            // 関連の表示情報を転換、画面へ出力する
            Date saleDate = pur.JinyaRevenue__r.Salesday__c;
            strSalesDate = DateTime.newInstance(saleDate.year(),saleDate.month(),saleDate.day()).format('yyyy-MM-dd');
            payAmountExcTax = CommUtils.nullToZero(pur.Denpyoukei__c);
            payAmountIncTax = CommUtils.nullToZero(pur.DenpyoukeiIncTax__c);
            shopId = pur.ShopInfoRef__c;
            
            String numberFormat = CommUtils.getNumberFormat();
            List<String> args = new String[]{'0','number',numberFormat};
            String strPayAmountExcTax = String.format(payAmountExcTax.format(), args);
            String strPayAmountIncTax = String.format(payAmountIncTax.format(), args);
            payAmountExcTax = CommUtils.nullToZero(strPayAmountExcTax);
            payAmountIncTax = CommUtils.nullToZero(strPayAmountIncTax); 
            // 仕入先情報が存在する場合、該当仕入先の端数処理区分を初期化する
            if (!CommUtils.isBLank(pur.Purchasesource__r.RoundType__c)) {
                String roundType = Commutils.nullToBlank(pur.Purchasesource__r.RoundType__c);
                roundMode = Commutils.getRoundTypeKbnByRoundMode(Commutils.pointRoundMode(roundType));
            }
        } else {
            // 該当ユーザーは最近作成のデータの情報を取得する
            pur = new Purchase__c();
            pur.ShopInfoRef__c = shopId;
            Date saleDate = Date.today();
            strSalesDate = DateTime.newInstance(saleDate.year(),saleDate.month(),saleDate.day()).format('yyyy-MM-dd');
        }
	    // 2019/10/15 現在料理の仕入れはsalesforceアプリの仕入（標準）上から入力しているのですが、この画面には「消費税」項目が表示されていないため、追加していただきたいです by zy BEGIN
        taxRate = CommUtils.nullToBlank(CommUtils.numberFormat(pur.Taxrate__c));
	    // 2019/10/15 現在料理の仕入れはsalesforceアプリの仕入（標準）上から入力しているのですが、この画面には「消費税」項目が表示されていないため、追加していただきたいです by zy END
    }
    // rsvRetrieve
    @RemoteAction
    public static Map<String, Object> rsvRetrieve(String type, 
        List<String> fields, 
        Map<String, Object> paramMap) {
            
        // RemoteAction Result Simulate Create
        Map<String, Object> result = new Map<String, Object>();
        List<RsvAccount__c> rsvLst = new List<RsvAccount__c>();
        try {
	        String strSalesDt = CommUtils.nullToBlank(paramMap.get('Name'));
	        Date queryDt = CommUtils.stringToDate(strSalesDt);
	        if (queryDt == null) queryDt = Date.today();
	        //queryDt = null;
	        // 売上情報を取得する
	        RsvAccount__c rsv = CommLogicProcess.getRsvAccountInf(queryDt);
	        rsvLst.add(rsv);
        } catch (Exception e) {
            result.put('error',e.getMessage());
            result.put('size',0);
        }
        if (!rsvLst.isEmpty()) {
            result.put('success',true);
            result.put('size',rsvLst.size());
            
        }
        result.put('type',type);
        result.put('records', rsvLst);
        /*
        system.debug(loggingLevel.info, 'result='+result);
        system.debug(loggingLevel.info, 'type='+type);
        system.debug(loggingLevel.info, 'fields='+fields);
        system.debug(loggingLevel.info, 'criteria='+paramMap);
        for (String key : result.keyset()) {
            System.debug(loggingLevel.info, 'KEY=['+key+']='+result.get(key));
        }*/
        return result;
    }
    // 2019/10/15 現在料理の仕入れはsalesforceアプリの仕入（標準）上から入力しているのですが、この画面には「消費税」項目が表示されていないため、追加していただきたいです by zy BEGIN
    public List<System.SelectOption> taxOpts{get;set;}
    public String taxRate{get;set;}
	private void initTaxList(){
		taxOpts = new List<System.SelectOption>();
		List<JMST__c> jmts = [select id,TaxRate__c,Name from JMST__c where TaxRate__c > 0 order by TaxRate__c desc];
		Set<String> commTaxSet = new Set<String>();
		if (!jmts.isEmpty()) {
			for (JMST__c jmt : jmts) {
				String rateStr = CommUtils.nullToBlank(CommUtils.numberFormat(jmt.TaxRate__c));
				if (!commTaxSet.contains(rateStr)) {
					taxOpts.add(new SelectOption(rateStr,rateStr));
					commTaxSet.add(rateStr);
				}
			}
			commTaxRate = jmts[0].TaxRate__c;
		} else {
			JMST__c jmst = CommLogicProcess.getTaxRateInfo();
			commTaxRate = jmst.taxRate__c;
		}
	}
	// 2019/10/15 現在料理の仕入れはsalesforceアプリの仕入（標準）上から入力しているのですが、この画面には「消費税」項目が表示されていないため、追加していただきたいです by zy END
}