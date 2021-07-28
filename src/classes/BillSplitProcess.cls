/********************************************
* 会計分割処理指示機能
* 分割NO一括印刷できる機能
* 2014/09/06 GP/DPの検索条件は非公開を追加する
* 2015/12/18 会計分割画面に、新会計に支払メディアも分割対象とする機能
* 2016/01/11 ポイント、値引以外の支払メデイアも明細に表示、グループNo登録可能対応
* 2018/04/27 会計書ハンコ表示・非表示機能対応
* 2019/04/30 請求書の送付表新規作成
* 2019/12/30 一括会計にチェックを入れたら、会計期間に全泊分の期間が自動入力されるようにして
*********************************************/
public with sharing class BillSplitProcess extends CommBaseCtrl{
    // 詳細画面から引渡の会計ID
    private final Id recordId;
    // 該当会計データに関連付くの予約データのLeadIndexId
    private Id recordRefIndexId;
	// 最大抽出会計数制限値
	private static final Integer MaxQueryLimit = 150;
	//会計抽出数が制限を超えました(XXXXXX件まで)
	private static final String MaxQueryWarnMsg = Label.MSG_006_0439.replace('XXXXXX',String.valueOf(MaxQueryLimit)); 
	
    private final Map<String,String> paramMap;

    // 分割指示チェック情報を格納する
    public List<BillInfo> billInfLst{get; private set;}
    public List<Selectoption> groupNoOptLst{get; private set;}

    // 検索条件情報格納用変数
    public List<Selectoption> dpOptionLst{get; private set;}
    public List<Selectoption> gpOptionLst{get; private set;}
    public List<Selectoption> typeOptionLst{get; private set;}
    public String paymentMediaJson{get;private set;}
    public List<PaymentMedia> paymentMediaLst{get;private set;}
	public TimeManagement__c c_termSt{get; set;}
	public TimeManagement__c c_termEt{get; set;}
    public String c_productNm{get;set;}
    public String c_gpId{get;set;}
    public String c_dpId{get;set;}
    public String c_splitNo{get;set;}
    public String[] c_actType{get;set;}
    public Boolean c_showAll{get;set;}
    // 既に設定済みGroupNoリストを格納する[印刷番号リスト格納]
    public List<Selectoption> c_groupNo{get; private set;}
    public String bulkAccId{get; set;}
    public AccountAcount__c accSobj{get; private set;}
    // 2018/01/15 分割会計時を行う際、店舗切替できるように改善対応 zyz BEGIN
    public String oShopCode{get; set;}
    // 2018/01/15 分割会計時を行う際、店舗切替できるように改善対応 zyz END
    // 施設コードにより、PDF関連入力条件設定判断フラグ(領収書あり)
    private String FACILITY_CODE = CommConst.APPOPTION_FACILITY_CODE;
    public Boolean isHaveReceipt{get{
    	// 領収書ありの会計書種類
    	return (FACILITY_CODE == '2' || FACILITY_CODE == '3' || FACILITY_CODE == '4' || FACILITY_CODE == '8' || FACILITY_CODE == '9'
    			 || FACILITY_CODE == '13' || FACILITY_CODE == '14');
    }}
    // 2019/04/30 明細分割時に領収書不要を改善対応 WGCH BEGIN
    public Boolean accountReceiptOptIsShow{get{return CommConst.APPOTION_RECEIPT_ISSHOW_FLG;}}
    // 該当ユーザーの関聯の施設コード
	public String oFacilityCode{get{return ShopInfoUtil.getShopFacilityCode(UserUtil.CurrentUser.ShopCode__c);}}
    public Boolean accReceiptIsShow{get{
    	// 領収書ありの会計書種類
    	return (accountReceiptOptIsShow && (oFacilityCode == '33' || oFacilityCode == '34'));
    }}
    // 2019/04/30 明細分割時に領収書不要を改善対応 WGCH END
    // 2018/03/30 会計書の店舗切替を保存 WGCH BEGIN
    public String userId{get{ return UserInfo.getUserId();}} // UserId
    public String billShopCode{get; set;}
    public Boolean spCdCookieFlg{get{ return CommConst.ACC_SPCDSAVE_FLG;}}
    // 2018/03/30 会計書の店舗切替を保存 WGCH END
    // 2018/04/27 会計書ハンコ表示・非表示機能対応 BEGIN by zh
    public Boolean accStampIsShowFlg{get{return CommConst.ACCOUNT_STAMPISSHOW_FLG;}set;}
    // 2018/04/27 会計書ハンコ表示・非表示機能対応 END by zh
    // 2018/04/03 会計分割 WGCH BEGIN
    public Boolean accSplitOutputFlg{get{return CommDefine__c.getOrgDefaults().AccountSplitOutputFlg__c == null ? false : CommDefine__c.getOrgDefaults().AccountSplitOutputFlg__c;}set;}
    public String fcInfoJson{get{
    	Set<String> defFcSet = new Set<String>{'33','34','35','36'};
    	List<String> spcdLst = new List<String>();
    	Map<String, Boolean> fcInfoMap = new Map<String, Boolean>();
    	String fc = CommUtils.nullToBlank( CommDefine__c.getOrgDefaults().FacilityCode__c );
    	for(System.SelectOption sp : mulitiShops){ // 初始化
    		spcdLst.add(sp.getValue());
    		fcInfoMap.put(sp.getValue(), defFcSet.contains(fc));
    	}
    	Map<String,ShopInformation__c> shopInfoMap = ShopInfoUtil.getShopInfoMap(spcdLst);
    	for(String spcd : shopInfoMap.keySet()){ // 根据店铺Info替换值
    		ShopInformation__c sp = shopInfoMap.get(spcd);
    		if(!CommUtils.isBlank(sp.FacilityCode__c)) fcInfoMap.put(spcd, defFcSet.contains(sp.FacilityCode__c)); // 替换值
    	}
    	if(fcInfoMap.isEmpty()) fcInfoMap.put('', defFcSet.contains(fc)); // 无店铺情况
    	return JSON.serialize(fcInfoMap);
    }}
    // 2018/04/03 会計分割 WGCH END
    // 2018/05/01 請求書分割 WGCH BEGIN
    // 請求書ハンコ表示
    public Boolean billStampIsShowFlg{get{return CommConst.Bill_STAMPISSHOW_FLG;}set;}
    // 個人組織通貨情報格納
    public String oDefaultCurrency{get{return UserUtil.getDefaultCurrency();}}
    public String toDate{get{return DateTime.now().format(CommBaseCtrl.getDateFormat());}}
    // 請求書のコメント欄を毎回手打ちし自動
    public String mulitiComments {get{ return CommentHelperCompCtrl.getBillCommentJson();}}
    // 2018/05/01 請求書分割 WGCH END
    // 2019/04/30 請求書の送付表新規作成 BY zyz BEGIN
    public Boolean billLetterFlg{get{ return CommConst.Bill_LETTER_FLG;}}
    // 2019/04/30 請求書の送付表新規作成 BY zyz END
    // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
    public Boolean respectFlg{get; private set;}
    // 敬称リスト
    public List<Selectoption> mrTypeLst{get{return CommConst.RESPECT_OPTIONS;}}
    public String mrStr{get; set;}
    // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
    // 2019/12/30 一括会計にチェックを入れたら、会計期間に全泊分の期間が自動入力されるようにして BY zyz BEGIN
    public String fromDefDate{get;set;}	// 一括会计-默认开始会计期间
    public String toDefDate{get;set;}		// 一括会计-默认结束会计期间
    // 2019/12/30 一括会計にチェックを入れたら、会計期間に全泊分の期間が自動入力されるようにして BY zyz END
    /*************************
    * 初期化処理
    **************************/
    public BillSplitProcess(ApexPages.StandardController controller){
        recordId = controller.getId();
        loadInit(recordId);
    }
    public BillSplitProcess() {
    	recordId = ApexPages.currentPage().getParameters().get('accid');
    	loadInit(recordId);
    }
    private void loadInit(Id recordId) {
        accSobj = [select id, name, Relreserve__c, Relreserve__r.LeadIndexRef__c,ContactName__c,BillingCal__c,relaccount__c,
        AccountName__c,AccountReceiptName__c,AccountProviso__c,relaccount__r.Account.Name,
        relaccount__r.Name, relaccount__r.AccountId,Relreserve__r.Name
        ,Relreserve__r.LeadIndexSubId__c,Relreserve__r.RoomGroupNo__c
        // 2018/01/15 分割会計時を行う際、店舗切替できるように改善対応 zyz BEGIN
        ,ShopCode__c
        // 2018/01/15 分割会計時を行う際、店舗切替できるように改善対応 zyz END
        // 2018/06/08 会計レシート印刷機能言語選択する WGCH BEGIN
        ,AccountLanguage__c
        // 2018/06/08 会計レシート印刷機能言語選択する WGCH END
        // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
        ,RespectLst__c
        // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
        from AccountAcount__c where id = :recordId ];
        recordRefIndexId = accSobj.Relreserve__r.LeadIndexRef__c;
        // 2018/01/15 分割会計時を行う際、店舗切替できるように改善対応 zyz BEGIN
        oShopCode = CommUtils.isBlank(accSobj.ShopCode__c) ? UserUtil.CurrentUser.ShopCode__c : accSobj.ShopCode__c;
        // 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH BEGIN
        // 获取店铺默认设定Code
        oShopCode = ShopInfoUtil.getShopDefCd(oShopCode, accSobj.ShopCode__c, UserUtil.CurrentUser.ShopCode__c, (accSobj.Relreserve__c != null));
        // 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH END
        // 2018/01/15 分割会計時を行う際、店舗切替できるように改善対応 zyz END
        // 2018/03/30 会計書の店舗切替を保存 WGCH BEGIN
        billShopCode = oShopCode;
        // 2018/03/30 会計書の店舗切替を保存 WGCH END
        // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
        respectFlg = CommLogicProcess.isShowRespectLst(oFacilityCode);
        if (!CommUtils.isBlank(accSobj.RespectLst__c)) mrStr = CommUtils.nullToBlank(accSobj.RespectLst__c);
        else mrStr = ShopInfoUtil.RESPECT_DEFAULTVALUE;
        // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
        init();
    }
    public class Option {
		public Option (String value, String label) {
			this.value = value;
			this.label = label;
		}
		public String value{get;set;}
		public String label{get;set;}
	}
	public String getAccountNames() {
		List<Option> accountNamsLst = new List<Option>();
		if (!CommUtils.isBlank(accSobj.relaccount__r.Account.Name))
		accountNamsLst.add(new Option(accSobj.relaccount__r.Account.Name,accSobj.relaccount__r.Account.Name));
		if (!CommUtils.isBlank(accSobj.relaccount__r.Name))
		accountNamsLst.add(new Option(accSobj.relaccount__r.Name,accSobj.relaccount__r.Name));
		if (!CommUtils.isBlank(accSobj.Relreserve__r.Name))
		// 2013/10/28 会計編集の「会計書宛名、領収書宛名」の選択リスト内容を追加
		accountNamsLst.add(new Option(accSobj.Relreserve__r.Name,accSobj.Relreserve__r.Name));
		return JSON.serialize(accountNamsLst);
	}
	public String getAccountProvisos() {
		List<Option> accountProvisoLst = new List<Option>(); 
    	String provisoStr = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().AccountProviso__c);
    	String[] provisoArray = provisoStr.split(',');
    	for (String key : provisoArray) {
    		// 2018/10/11 但しデイフォル値設定機能対応 zyz BEGIN
    		Integer defMarkIdx = key.indexOf(':1');
    		if (defMarkIdx > 0)  key = key.substring(0,defMarkIdx);
    		// 2018/10/11 但しデイフォル値設定機能対応 zyz END
    		if (!CommUtils.isBlank(key)) accountProvisoLst.add(new Option(key, key));
    	}
    	return JSON.serialize(accountProvisoLst);
	}
    private void init() {
		// 一括表示フラグ
        c_showAll = false;
        // 2016/01/11 ポイント、値引以外の支払メデイアも明細に表示、グループNo登録可能対応
        isHaveTtendPayInfo = false;
		// グループ番号リスト
        groupNoOptLst = new List<Selectoption>();
        Schema.DescribeFieldResult fieldResult = Tran1__c.SplitGroupNo__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple) {
            groupNoOptLst.add(new SelectOption(f.getValue(),f.getLabel()));
        }
		// 商品処理種別
        typeOptionLst = new List<Selectoption>();
        fieldResult = AccountMaster__c.ActionType__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple) {
            typeOptionLst.add(new SelectOption(f.getValue(),f.getLabel()));
        }
		// 期間格納変数処理化
        c_termSt = new TimeManagement__c(WorkDay__c=Date.today().addDays(-1));
        c_termEt = new TimeManagement__c(WorkDay__c=Date.today());

		// DP/GP選択設定
        dpOptionLst = new List<Selectoption>();
        gpOptionLst = new List<Selectoption>();
        for (DP__c s: [select id, name, Field1__c from DP__c where IsClosed__c != true order by Name limit 500]) dpOptionLst.add(new SelectOption(s.id, s.Name));
        for (GP__c s: [select id, name, Field1__c from GP__c where IsClosed__c != true order by Name limit 500]) gpOptionLst.add(new SelectOption(s.id, s.Name));
        
        paymentMediaLst = new List<PaymentMedia>();
        BillSimplePaymentCtrl billSimplePayment = new BillSimplePaymentCtrl();
        billSimplePayment.getInitXmlDefineInfo();
       	paymentMediaLst.add(new PaymentMedia('','','',''));
       	for(BillSimplePaymentCtrl.Product product: billSimplePayment.exitProdLst){
       		if(product.productItem != null){
				PaymentMedia media = new PaymentMedia(product.productItem.prodcutName,product.productItem.prodcutCode,product.iconUrl,product.productItem.productId);
       			paymentMediaLst.add(media);
			}
       		//paymentOptionLst.add(new SelectOption(f.getValue(),f.getLabel()));
       	}
       	paymentMediaJson = JSON.serialize(paymentMediaLst);
    }
    // 会計情報を取得用SQL
    // 2019/12/30 一括会計にチェックを入れたら、会計期間に全泊分の期間が自動入力されるようにして BY zyz BEGIN
    // private final String leadSel = 'select id, name, Field147__c, Field151__c, relaccount__c, Relreserve__c,ContactName__c,Relreserve__r.EntryTime__c From AccountAcount__c ';
    private final String leadSel = 'select id, name, Field147__c, Field151__c, relaccount__c, Relreserve__c,ContactName__c,Relreserve__r.EntryTime__c,frs__r.name,Relreserve__r.RoomGroupNo__c,Relreserve__r.LeadIndexSubId__c From AccountAcount__c ';
    // 2019/12/30 一括会計にチェックを入れたら、会計期間に全泊分の期間が自動入力されるようにして BY zyz END
    private final String tranSel = 'select id, name, PrintedFlg__c, Field5__c, Field1__c, ActionType__c, SplitGroupNo__c, Field7__r.Name,Field25__r.Name, Field26__r.Name, Field39__c,Field20__c, Field41__c,Field23__c, Field21__c,ParentTran1Ref__c,AccountName__c,AccountReceiptName__c,AccountProviso__c,PayProductRef__c,UseDate__c from Tran1__c ';
    /*************************
    * 会計情報を取得する
    **************************/
    public void refreshBillInfo() {
        // 2019/12/30 一括会計にチェックを入れたら、会計期間に全泊分の期間が自動入力されるようにして BY zyz BEGIN
        fromDefDate = '';
        toDefDate = '';
        // 2019/12/30 一括会計にチェックを入れたら、会計期間に全泊分の期間が自動入力されるようにして BY zyz END
		queryBillInfo();
    }
    /*************************
    * 会計情報を取得する[新会計メニューから]
    **************************/
    private Boolean isFromBillSimpleInput = false;
    public void refreshSimpleBillInfo() {
		// 該当会計と関聯の会計情報を全部自動的に表示する（同じ部屋で）
		isFromBillSimpleInput = true;
		// 期間格納変数処理化
        c_termSt = new TimeManagement__c(WorkDay__c=null);
        c_termEt = new TimeManagement__c(WorkDay__c=null);
		queryBillInfo();
    }
    /*************************
    * 会計情報を取得する
    **************************/
    private void queryBillInfo() {
    	// 2018/03/30 会計書の店舗切替を保存 WGCH BEGIN
    	if(spCdCookieFlg) getUserCookData();
    	// 2018/03/30 会計書の店舗切替を保存 WGCH END
    	// 情報を初期化する
    	billInfLst = new List<BillInfo>();
    	// 既存の割合番号を
    	Set<String> groupNoSet = new Set<String>();
    	// 会計IDリストを格納する
    	Map<Id, Integer> accIdxMap = new Map<Id, Integer>();
    	// 会計情報を取得する
    	Integer idx = 0;
        // 会計Query分を用意する
    	String leadQuery = leadSel + this.getAccWhere() + ' Order By frs__r.Name, Name limit :MaxQueryLimit ';
System.debug('leadQuery:::' + leadQuery);
		bulkAccId = '';
		// 2019/12/30 一括会計にチェックを入れたら、会計期間に全泊分の期間が自動入力されるようにして BY zyz BEGIN
		date fromDate = null;
		date toDate = null;
		// 2019/12/30 一括会計にチェックを入れたら、会計期間に全泊分の期間が自動入力されるようにして BY zyz END
		for (AccountAcount__c acc : DataBase.query(leadQuery)) {
			// 2019/12/30 一括会計にチェックを入れたら、会計期間に全泊分の期間が自動入力されるようにして BY zyz BEGIN
			// 获取当前数据的売上记上日
			date defDate = CommUtils.stringToDate(acc.frs__r.name);
			// 设定初期值
			if(fromDate == null || toDate == null){
				fromDate = defDate;
				toDate = defDate;
			}else{
				// 取得会计期间最小日期
				if(fromDate > defDate){
					fromDate = defDate;
				}
				// 取得会计期间最大日期
				if(toDate < defDate){
					toDate = defDate;
				}
			}
			// 一括会計：false，过滤多房间的数据，只显示连泊数据(过滤掉LeadIndexSubId__c不相等的数据或者RoomGroupNo__c不相等的数据)
			if(!c_showAll && ((acc.Relreserve__r.LeadIndexSubId__c != accSobj.Relreserve__r.LeadIndexSubId__c) || (acc.Relreserve__r.RoomGroupNo__c != accSobj.Relreserve__r.RoomGroupNo__c))) continue;
			// 2019/12/30 一括会計にチェックを入れたら、会計期間に全泊分の期間が自動入力されるようにして BY zyz END
            // 画面に表示用リストを格納する
            BillInfo item = new BillInfo(acc);
            billInfLst.add(item);
            accIdxMap.put(acc.Id, idx);
            idx ++;
            bulkAccId += acc.Id + ',';
    	}
    	// 2019/12/30 一括会計にチェックを入れたら、会計期間に全泊分の期間が自動入力されるようにして BY zyz BEGIN
    	if(fromDate != null) fromDefDate = fromDate.format();
    	if(toDate != null) toDefDate = toDate.format();
    	// 2019/12/30 一括会計にチェックを入れたら、会計期間に全泊分の期間が自動入力されるようにして BY zyz END
    	bulkAccId = bulkAccId.substringBeforeLast(',');
    	if (billInfLst.size() == MaxQueryLimit) {
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, MaxQueryWarnMsg));
    	}
    	
        // 該当会計に関連付くの会計明細（プラン明細が対象外）
        Set<Id> accIdSet = accIdxMap.keySet();
        String tranQuery = tranSel  + ' where Field1__c in :accIdSet ' + this.getTranWhere();
        String tranOtherCntQuery = ' select SplitGroupNo__c splitNo from Tran1__c where Field1__c in :accIdSet '; //group by SplitGroupNo__c ';
        // 2015/12/18 会計支払明細は配列に追加表示 BEGIN
        String prodActionTypeAr = CommConst.PROD_ACTION_TYPE_AR;
        if (isFromBillSimpleInput) {
        	tranQuery += ' And ActionType__c != :prodActionTypeAr ';
        	tranOtherCntQuery +=' And ActionType__c != :prodActionTypeAr And ParentTran1Ref__c = null  ';
        }
	// 2015/12/18 会計支払明細は配列に追加表示 END
        // プラン明細は非展開する場合、条件を追加する
        if (!CommConst.APPOTION_ACCOUNTSPLIT_BKISHOW) tranOtherCntQuery +=' And ParentTran1Ref__c = null  ';
        tranOtherCntQuery += ' group by SplitGroupNo__c ';
        
        tranQuery += ' Order By Name ';
System.debug('tranQuery:' + tranQuery);
        // 取得する情報を
        Map<Id, Integer> planIdxMap = new Map<Id, Integer>();

        for (Tran1__c tran : DataBase.query(tranQuery)) {
        	//wx upd start
			if(!CommUtils.isBlank(tran.Field20__c)) tran.Field20__c = CommUtils.nullToBlank(CommUtils.nullToZero(tran.Field20__c));
			//wx upd end
			//AccountAcountのdefault值
			if(CommUtils.isBlank(tran.AccountName__c)){
				tran.AccountName__c = CommUtils.isBlank(accSobj.AccountName__c) ?
														accSobj.ContactName__c : accSobj.AccountName__c;
			}
			// 領収書宛名
			if(CommUtils.isBlank(tran.AccountReceiptName__c)){
				tran.AccountReceiptName__c = CommUtils.isBlank(accSobj.AccountReceiptName__c) ?
																	accSobj.BillingCal__c : accSobj.AccountReceiptName__c;
			}
			// 会計書但し
			if(CommUtils.isBlank(tran.AccountProviso__c)){
					tran.AccountProviso__c = accSobj.AccountProviso__c;
			}
        	// 会計に、関連の会計明細対象データは配列に格納する(注：プラン所属するプラン明細は対象外)
        	BillInfo billItem = billInfLst[accIdxMap.get(tran.Field1__c)];
        	billItem.addTran(new TranInfo(tran));

        	// プラン商品場合
        	if (tran.ActionType__c == CommConst.PROD_ACTION_TYPE_PL)
        	   planIdxMap.put(tran.Id, billItem.tranLst.size()-1);
        }
        // 2015/12/18 会計支払明細は配列に追加表示 BEGIN
        if (isFromBillSimpleInput) {
	        map<id, list<TranInfo>> payTrandMap = getTtends(accIdSet);
	        for (Id accId : payTrandMap.keyset()) {
	        	// 会計に、関連の会計明細対象データは配列に格納する(注：プラン所属するプラン明細は対象外)
	        	BillInfo billItem = billInfLst[accIdxMap.get(accId)];
	        	for (TranInfo tran : payTrandMap.get(accId)) {
	        		billItem.addTran(tran);
	        	}
	        }
        }
	// 2015/12/18 会計支払明細は配列に追加表示 END

        // プランが存在する場合、プラン明細を取得、メモーに格納する
        if (!planIdxMap.isEmpty() && !isNotQuerySub() && CommConst.APPOTION_ACCOUNTSPLIT_BKISHOW) {
        	Set<Id> pTranIdSet = planIdxMap.keySet();
            tranQuery = tranSel  + ' where Field1__c in :accIdSet And ParentTran1Ref__c in :pTranIdSet ' + this.getTranSubWhere();

	        for (Tran1__c tran : DataBase.query(tranQuery)) {

	            // 会計情報を取得する
	            BillInfo bInfo = billInfLst[accIdxMap.get(tran.Field1__c)];

	            // 該当会計情報のプラン情報を取得する
	            TranInfo tInfo = bInfo.tranLst[planIdxMap.get(tran.ParentTran1Ref__c)];
	            tInfo.addChild(tran);
	        }
        }
        
        // 印刷できるの分割NOを設定を行う
        c_groupNo = new List<Selectoption>();
		// 既に登録済み「印刷分割No」統計する
		Set<String> splitNoSet = new Set<String>();
       	for (AggregateResult rs : DataBase.query(tranOtherCntQuery)) {
       		String splitNo = CommUtils.nullToBlank((String)rs.get('splitNo'));
       		splitNoSet.add(splitNo);
       	}
        for (Selectoption opt : groupNoOptLst) {
        	if (splitNoSet.contains(opt.getValue())) {
        		c_groupNo.add(opt);
        		splitNoSet.remove(opt.getValue());
        	}
        }
	    if (!splitNoSet.isEmpty()) {
        	Selectoption sop = new Selectoption('','Other');
        	c_groupNo.add(sop);
        }
    }

    /**
    * 分割NOを登録機能
    **/
    public void saveNo() {

        List<Tran1__c> updLst = new List<Tran1__c>();
	// 2015/12/18 会計支払明細は配列に追加表示 BEGIN
        List<TTend__c> updTtendLst = new list<TTend__c>();
        for (BillInfo info : billInfLst) {
            //tran.SplitGroupNo__c = splitChkMap.get(tran.Id);
            for (TranInfo tranItem : info.tranLst) {
            	if (!CommUtils.isBlank(tranItem.ttendId)) {
            		updTtendLst.add(new TTend__c(Id = tranItem.ttendId, SplitGroupNo__c = tranItem.tran.SplitGroupNo__c, PrintedFlg__c = tranItem.tran.PrintedFlg__c));
            	} else {
	            	updLst.add(tranItem.tran);
	            	updLst.addAll(tranItem.childLst);
            	}
            }
        }
        // 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH BEGIN
        // update updLst;
        // if (!updTtendLst.isEmpty()) update updTtendLst;
        try{
        	update updLst;
        	if (!updTtendLst.isEmpty()) update updTtendLst;
        } catch (Exception e) {
        	String msg = e.getMessage();
			// 2017/05/04 自施設の予約や会計しか変更できないように権限管理機能 BEGIN
			if(!CommUtils.isFieldValidationMessage(msg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, msg));
			// 2017/05/04 自施設の予約や会計しか変更できないように権限管理機能 END
        }
        // 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH END
	// 2015/12/18 会計支払明細は配列に追加表示 END

//System.debug('billInfLst:::::' + billInfLst);
        //refreshBillInfo();
        queryBillInfo();
    }
	// 2016/01/11 ポイント、値引以外の支払メデイアも明細に表示、グループNo登録可能対応
	public boolean isHaveTtendPayInfo{get; private set;}	
	// 2015/12/18 会計支払明細は配列に追加表示 BEGIN
	/**
	* 支払支払情報を取得する
	* 会計分割について、ポイント、クーポン、商品券(現金、カード、売掛の支払メデイア、前受け、返金、予約金以外)
	**/
	private map<Id,List<TranInfo>> getTtends (Set<Id> accIdSet ) {
		// 対象明細のメディア種別:クーポン/値引・割引券
		Set<String> mediaTypes = new Set<String>();
		mediaTypes.add(CommConst.MEDIA_TYPE_CD_11);
		mediaTypes.add(CommConst.MEDIA_TYPE_CD_12);
		
		map<id, list<TranInfo>> tranMaps = new map<id, list<TranInfo>>();
		// ポイント、クーポン、
		for (TTend__c ttend : [select id, Field1__c, field2__c, field3__c,RowNo__c	// メディア種別,メディア名称
								,Field16__c,Field17__c,Field20__c	// 単価,枚数,支払金額
								,SplitGroupNo__c
								,PaymentType__c
								,PayProductName__c
								,PayProductRef__c	// 支払商品
								,PayProductRef__r.ActionType__c,PayProductRef__r.Field3__c
								,RelAccount__r.Name	// 主従関係(売上)
								,Field1__r.Relreserve__c, Field1__r.SalesdayCal__c
								,UseDate__c
								,PrintedFlg__c
								// 2019/10/30 会計画面に入力した金額と、明細分割した際の金額が違う修正 WGCH BEGIN
								,Field19__c
								// 2019/10/30 会計画面に入力した金額と、明細分割した際の金額が違う修正 WGCH END
								from TTend__c 
								where Field1__c in :accIdSet 
								// 2016/01/11 ポイント、値引以外の支払メデイアも明細に表示、グループNo登録可能対応 BEGIN
								//and field2__c in :mediaTypes
								// 2016/01/11 ポイント、値引以外の支払メデイアも明細に表示、グループNo登録可能対応 END
								order by Field1__c, RowNo__c]) {
			Id accId = ttend.Field1__c;
			// 取得の会計明細は分割明細に表示する
			TranInfo convertTran = new TranInfo(convertTtendToTran(ttend));
			convertTran.ttendId = ttend.Id;
			if (!tranMaps.containskey(accId)) {
				tranMaps.put(accId, new list<TranInfo>());
			}
			tranMaps.get(accId).add(convertTran);
		}
		// 2016/01/11 ポイント、値引以外の支払メデイアも明細に表示、グループNo登録可能対応
		isHaveTtendPayInfo = !tranMaps.isEmpty();
		// 取得の支払情報は会計単位に、リスト格納する
		return tranMaps;
	}
	// ポイントと値引のみ情報を出力する
	private Tran1__c convertTtendToTran(TTend__c pTendItem) {
		// 会計支払情報から会計明細に転換処理を行う
		// 会計支払情報に格納している商品IDにより、関連の会計明細に自動変更を行う
		// 支払情報に関連している会計商品がなかれば、支払Mediaにより、固定の支払情報を変更する
		// 支払商品の参照IDがNULLの場合（過去の会計支払情報対応するため）、支払Mediaにより、固定の商品を転換を行う[TODO]
		// RowNo__c
		/*
		if (CommUtils.isBlank(pTendItem.PayProductRef__c)) {
			// 支払Mediaにより、固定の会計商品コードとMATCHする
			String mediaNm = pTendItem.Field3__c;
			AccountMaster__c accMst = MEDIA_PRODUCTCD_MAP.get(mediaNm);
			if (accMst == null) accMst= new AccountMaster__c(Name = mediaNm);
//System.debug(LoggingLevel.INFO, '[MEDIA_PRODUCTCD_MAP]:::' + MEDIA_PRODUCTCD_MAP);
//System.debug(LoggingLevel.INFO, '[mediaNm]:::' + mediaNm);
			pTendItem.PayProductRef__c = accMst.Id;
			pTendItem.PayProductRef__r = accMst.clone(false,true);
			pTendItem.PayProductName__c = accMst.Name;
			pTendItem.PaymentType__c = accMst.PaymentType__c;
		}*/
		// 単価と数量項目を設定されている場合、該当単価と数量はそのまま画面に表示が必要
		// 2019/10/30 会計画面に入力した金額と、明細分割した際の金額が違う修正 WGCH BEGIN
		// String unitPrice = pTendItem.Field20__c;
		String unitPrice = pTendItem.Field19__c;
		// 2019/10/30 会計画面に入力した金額と、明細分割した際の金額が違う修正 WGCH END
		String quality = '1';
		if ( pTendItem.Field2__c == CommConst.MEDIA_TYPE_CD_11 ||
			 pTendItem.Field2__c == CommConst.MEDIA_TYPE_CD_12) {
			if (!CommUtils.isBlank(pTendItem.Field16__c) &&
				!CommUtils.isBlank(pTendItem.Field17__c)) {
				unitPrice = pTendItem.Field16__c;
				quality = pTendItem.Field17__c;
			}
		}
		Tran1__c tran = new Tran1__c(
			Field7__c = pTendItem.PayProductRef__c // 商品コード
			,Field7__r = pTendItem.PayProductRef__r.clone(false,true)
			,ActionType__c = CommConst.PROD_ACTION_TYPE_PY	// 商品処理種別
			,PaymentType__c = pTendItem.PaymentType__c // ;支払種別
			,Field20__c = unitPrice	// 単価 ←　預かり金額
			// 2019/10/30 会計画面に入力した金額と、明細分割した際の金額が違う修正 WGCH BEGIN
			// ,Field23__c = pTendItem.Field20__c	// 合計金額 ←　預かり金額
			,Field23__c = pTendItem.Field19__c	// 合計金額 ←　預かり金額
			// 2019/10/30 会計画面に入力した金額と、明細分割した際の金額が違う修正 WGCH END
			,Field21__c = quality			// 数量１固定
			,Field5__c = pTendItem.PayProductName__c
			,RelAccount__c = pTendItem.RelAccount__c
			,Field1__c = pTendItem.Field1__c
			,Field1__r = pTendItem.Field1__r
			,RowNo__c = pTendItem.RowNo__c
			,SplitGroupNo__c = pTendItem.SplitGroupNo__c
			,PayProductRef__c = pTendItem.PayProductRef__c
			// 2016/01/11 ポイント、値引以外の支払メデイアも明細に表示、グループNo登録可能対応 BEGIN
			,UseDate__c = pTendItem.UseDate__c
			// 2016/01/11 ポイント、値引以外の支払メデイアも明細に表示、グループNo登録可能対応 END
			,PrintedFlg__c = pTendItem.PrintedFlg__c
		);
		return tran;
	}
	// 2015/12/18 会計支払明細は配列に追加表示 END
    /**
    * 画面設定条件にて、会計情報のIDリストを取得する
    **/
    private String getAccWhere () {
    	//　会計詳細画面から遷移して、引渡の会計IDを取得する
    	//Set<Id> accIdSet = new Set<Id>();
    	//accIdSet.add(recordId);
    	String wStr = '';

    	// 一括会計
    	if (c_showAll) {
    		if (String.isEmpty(recordRefIndexId)) {
    			wStr += ' Where Relreserve__c = null ';
    		} else {
	        	wStr += ' Where Relreserve__r.LeadIndexRef__c = :recordRefIndexId ';
    		}
    	} else {
    		// 2015/04/10 新会計編集画面から起動する場合、該当会計の関聯の会計情報を全部表示する
    		if (isFromBillSimpleInput) {
    			// 関聯予約情報がなかった場合、自分の明細のみ取得する
    			if (String.isEmpty(recordRefIndexId)) {
    				wStr += ' Where Id = :recordId ';
    			} else {
    				// 2019/12/30 一括会計にチェックを入れたら、会計期間に全泊分の期間が自動入力されるようにして BY zyz BEGIN
    				// 未一括数据时，检索所有会计数据
    				wStr += ' Where Relreserve__r.LeadIndexRef__c = :recordRefIndexId ' ;
    				// wStr += ' Where Relreserve__r.LeadIndexRef__c = :recordRefIndexId ' +
    						// ' And Relreserve__r.LeadIndexSubId__c = \'' + String.escapeSingleQuotes(Commutils.nullToBlank(accSobj.Relreserve__r.LeadIndexSubId__c)) + '\''+ 
    						// ' And Relreserve__r.RoomGroupNo__c = ' + String.escapeSingleQuotes(Commutils.nullToBlank(accSobj.Relreserve__r.RoomGroupNo__c));
    				// 2019/12/30 一括会計にチェックを入れたら、会計期間に全泊分の期間が自動入力されるようにして BY zyz END
    			}
    		} else {
    			wStr += ' Where Id = :recordId ';
    		}
    	}
    	// 2015/11/25 VOIDされる会計明細対象外になる BEGIN
    	wStr += ' And Field39__c != \'' + CommConst.ACC_TRADE_VOID + '\' ';
    	// 2015/11/25 VOIDされる会計明細対象外になる END
    	if (c_termSt.WorkDay__c != null) {
    		DateTime formater = DateTime.newInstance(c_termSt.WorkDay__c.year(),c_termSt.WorkDay__c.month(),c_termSt.WorkDay__c.day());
    		wStr += ' And frs__r.Name >= \'' + formater.format('yyyyMMdd') + '\' ';
    	}
        if (c_termEt.WorkDay__c != null) {
        	DateTime formater = DateTime.newInstance(c_termEt.WorkDay__c.year(),c_termEt.WorkDay__c.month(),c_termEt.WorkDay__c.day());
            wStr += ' And frs__r.Name <= \'' + formater.format('yyyyMMdd') + '\' ';
        }
        return wStr;
    }
    /**
    * プラン明細Queryするかどうか
    * 商品関連の検索条件を指定する場合、プラン単位の検索を行わない
    **/
    private Boolean isNotQuerySub() {

    	Boolean flg1 = false;
    	Boolean flg2 = false;

        // 商品名を入力する場合、一致商品名の明細情報を表示する
        if (!CommUtils.isBlank(c_productNm) ||
            !CommUtils.isBlank(c_dpId) ||
            !CommUtils.isBlank(c_gpId) ||
            !CommUtils.isBlank(c_splitNo)) {
            flg1 = true;
        }
        // 商品種別
        if (c_actType != null && c_actType.size() > 0) {
            for (String str : c_actType) {
                if (!CommUtils.isBlank(str)) {
                    flg2 = true;
                    break;
                }
            }
        }
        return (flg1 || flg2);
    }

    /**
    * 検索条件にて、会計明細の検索条件を作成する
    **/
    private String getTranWhere() {
    	String wStr = '';
        // 商品名を入力する場合、一致商品名の明細情報を表示する
        if (!CommUtils.isBlank(c_productNm)) {
        	wStr += ' And Field5__c = :c_productNm ';
        }
        // c_dpId
        if (!CommUtils.isBlank(c_dpId)) {
        	wStr += ' And Field25__c = :c_dpId ';
        }
        // c_gpId
        if (!CommUtils.isBlank(c_gpId)) {
            wStr += ' And Field26__c = :c_gpId ';
        }
        // c_splitNo
        if (!CommUtils.isBlank(c_splitNo)) {
        	wStr += ' And SplitGroupNo__c = :c_splitNo ';
        }
        // 商品種別
        if (c_actType != null && c_actType.size() > 0) {
        	Boolean isShowAll = false;
        	for (String str : c_actType) {
        		if (CommUtils.isBlank(str)) {
        			isShowAll = true;
        			break;
        		}
        	}
        	if (!isShowAll) wStr += ' And ActionType__c in :c_actType';
        }
        // 商品関連の検索条件を未設定する場合、プラン明細は検索対象外
        if (!isNotQuerySub()) wStr = ' And ParentTran1Ref__c = null ';
System.debug('getTranWhere:::' + wStr);
        return wStr;
    }
    /**
    * 検索条件にて、会計明細の検索条件を作成する
    **/
    private String getTranSubWhere() {
        String wStr = '';
        // 商品名を入力する場合、一致商品名の明細情報を表示する
        if (!CommUtils.isBlank(c_productNm)) {
            wStr += ' And Field5__c = :c_productNm ';
        }
        // c_dpId
        if (!CommUtils.isBlank(c_dpId)) {
            wStr += ' And Field25__c = :c_dpId ';
        }
        // c_gpId
        if (!CommUtils.isBlank(c_gpId)) {
            wStr += ' And Field26__c = :c_gpId ';
        }
        // c_splitNo
        if (!CommUtils.isBlank(c_splitNo)) {
        	wStr += ' And SplitGroupNo__c = :c_splitNo ';
        }
        // 商品種別
        if (c_actType != null && c_actType.size() > 0) {
            Boolean isShowAll = false;
            for (String str : c_actType) {
                if (CommUtils.isBlank(str)) {
                    isShowAll = true;
                    break;
                }
            }
            if (!isShowAll) wStr += ' And ActionType__c in :c_actType';
        }
System.debug('getTranSubWhere:::' + wStr);
        return wStr;
    }

    /************************
    * 会計と関連の会計明細格納
    *************************/
    public class BillInfo {

    	public BillInfo(AccountAcount__c pAcc) {
    		acc = pAcc;
    		tranLst = new List<TranInfo>();
    	}
    	public AccountAcount__c acc{get; private set;}
    	public List<TranInfo> tranLst{get; private set;}
        public void addTran(TranInfo tran) {
        	tran.isFirst = (tranLst.size() == 0) ? true : false;
        	tranLst.add(tran);
        }

    }
    public class TranInfo {
    	public TranInfo(Tran1__c p_tran) {
    		tran = p_tran;
    		childLst = new List<Tran1__c>();
		    
		    // 2014/09/15 数量小数点機能対応
		    // 数量情報が存在するば場合、小数部右側に表示する０は外す対応
		    if (!Commutils.isBlank(tran.Field21__c)) tran.Field21__c = CommUtils.deleteRightZero(tran.Field21__c);
    	}
    	public String groupNo{get;set;}
        public Boolean isFirst{get; set;}
    	public Tran1__c tran{get; private set;}
    	public List<Tran1__c> childLst{get; private set;}
    	// プランするがどうか
    	public Boolean isPlan{get{return (tran.ActionType__c == CommConst.PROD_ACTION_TYPE_PL ? true : false);}}
    	public void addChild(Tran1__c tran) {
    		//if(CommConst.APPOTION_ACCOUNTSPLIT_BKISHOW)
 			// 2014/09/15 数量小数点機能対応
		    // 数量情報が存在するば場合、小数部右側に表示する０は外す対応
		    if (!Commutils.isBlank(tran.Field21__c)) tran.Field21__c = CommUtils.deleteRightZero(tran.Field21__c);
    		childLst.add(tran);
    	}
    	public Id ttendId{get;set;}
    }
	public class PaymentMedia{
		String MediaName;
		String MediaId;
		String MediaCode;
		String PhotoUrl;
		PaymentMedia(String name,String code,String Icon,String id){
			MediaName = name;
			MediaCode = code;
			PhotoUrl = Icon;
			MediaId = id;
		}
	}
	public Boolean getAccountSplitBkIshow() {
		return CommConst.APPOTION_ACCOUNTSPLIT_BKISHOW;
	}
/**
*2015-11-18 
*テストクラスBillSplitProcessTestに移行する
    @isTest(SeeAllData=true)
    static void selfUnit() {
    	Test.startTest();
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	// 予約情報のステータス：チェックインに変更する
    	leadInfo.Field298__c = 'チェックイン完';
    	update leadInfo;

    	Test.stopTest();

    	// 会計画面に動作確認を行う
    	List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfo.Id];
    	AccountAcount__c accObj = accObjLst[0];

    	ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
    	BillInput_Ctrl ctrl = new BillInput_Ctrl(contrl);
    	ctrl.initAction();
    	ctrl.calPaymentInfo();
    	ctrl.upsertData();
    	
    	BillSplitProcess split = new BillSplitProcess(contrl);
    	split.c_showAll = true;
    	split.refreshBillInfo();
    	
    	split.c_splitNo = '01';
    	split.c_actType = new String[]{'朝食'};
    	split.c_dpId = '01';
    	split.c_gpId = '02';
    	split.c_productNm = 'テスト商品';
    	split.c_termEt.WorkDay__c = Date.today();
    	split.c_termSt.WorkDay__c = Date.today();
    	split.refreshBillInfo();
    	split.saveNo();
    	System.assertNotEquals(split.accSobj, null);
    }
    **/
    // 2018/01/15 分割会計時を行う際、店舗切替できるように改善対応 zyz BEGIN
	public List<SelectOption> mulitiShops {get{
		String[] shops = ShopInfoUtil.getCanSelectShopLst(UserInfo.getUserId());
		List<SelectOption> shopList = new List<SelectOption>();
		if (shops.size() <= 1) return shopList;
		for (String shop : shops) {
			String[] shopArr = shop.split(':');
			shopList.add(new SelectOption(shopArr[0], shopArr[1].left(10)));
		}
		return shopList;
	}}
    // 2018/01/15 分割会計時を行う際、店舗切替できるように改善対応 zyz END
    // 2018/03/30 会計書の店舗切替を保存 WGCH BEGIN
    private void getUserCookData(){
		// DBから設定情報を取得する
		map<string,string> userConfigMap = UserConfigCompCtrl.getKrepConfig(userId, '');
		String demoAccKey = UserConfigCompCtrl.KREP_SUBTYPE.ACCSPCD.name();
		if (userConfigMap.containsKey(demoAccKey)) {
			String spCd = CommUtils.nullToBlank(userConfigMap.get(demoAccKey));
			if(!CommUtils.isBlank(spCd)) oShopCode = spCd;
		}
		String demoBillKey = UserConfigCompCtrl.KREP_SUBTYPE.BILLSPCD.name();
		if (userConfigMap.containsKey(demoBillKey)) {
			String spCd = CommUtils.nullToBlank(userConfigMap.get(demoBillKey));
			if(!CommUtils.isBlank(spCd)) billShopCode = spCd;
		}
    }
    // 2018/03/30 会計書の店舗切替を保存 WGCH END
	// 2019/1/15 請求書に掲載する振込先口座情報を、同一店舗内で切り替えする BY cxw BEGIN
	public String jsonFixedMsg{
		get{
			String[] shops = ShopInfoUtil.getCanSelectShopLst(UserInfo.getUserId());
			Set<String> spcdSet = new Set<String>{oShopCode};
			for(String shop : shops) spcdSet.add(shop.split(':')[0].trim());
			object target = UserUtil.getFixedMsg(new List<String>(spcdSet));
			return JSON.serialize(target);
		} set;}
	// 2019/1/15 請求書に掲載する振込先口座情報を、同一店舗内で切り替えする BY cxw END
}