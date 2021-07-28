/*
* 2019/08/15 入金消込機能の改善
*/
public with sharing class BillEraseListCtrl extends CommBaseCtrl{
    public list<StockInfo> stocks {get;set;}        			// 数据
    public TimeManagement__c c_termSt{get; set;}    			// 检索的开始时间
    public TimeManagement__c c_termEt{get; set;}    			// 检索的结束时间
    public Boolean c_termCk{get;set;}               			// 消込済明細も表示
    public String userName{get;set;}                			// 消込者
    // 2019/06/15 消込機能改善対応 BY zyz BEGIN
    public List<SelectOption> branchShopLst{get; private set;} 	// 店铺list
    public String branchShopNm{get; set;}						// 默认店铺
    public Boolean layoutFlg{get{return true;}}					// 控制开关(暂时不公开，显示新功能；true：新layout功能；false：原layout功能)
    // 2019/07/15 入金消込機能ソートを保持の改善 BY zyz BEGIN
    public String userId{get;set;}								// 消込者Id
    public String configFieldVal{get;set;}						// 记忆的列
    public String configDirVal{get;set;}						// 记忆的值
    // 2019/07/15 入金消込機能ソートを保持の改善 BY zyz END
    // 检索数据
    private set<String> mediaSet{get; set;}
    // 2019/06/15 消込機能改善対応 BY zyz END
    // 2019/11/30 Filter機能改善対応 BY zyz BEGIN
    public String filterVal{get;set;}
    // 2019/11/30 Filter機能改善対応 BY zyz END
    public BillEraseListCtrl(){
    	// 2019/06/15 消込機能改善対応 BY zyz BEGIN
    	userInf = UserUtil.CurrentUserInfo;
    	userName = userInf.u.Name;
    	setInitBranShopLst(userInf.defaultShopCode);
    	userId = userInf.u.Id;
    	// 获取共通定义的支付种别
    	String mediaTypeStr = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().BillEraseMediaTypeCode__c);
    	mediaSet = new set<String>();
    	for(String s : mediaTypeStr.split(',')){
    		if (mediaSet.contains(s) || CommUtils.isBlank(s)) continue;
    		mediaSet.add(s);
    	}
    	// 2019/06/15 消込機能改善対応 BY zyz END
        // 2019/11/30 Filter機能改善対応 BY zyz BEGIN
        filterVal = getFilterVal();
        // 2019/11/30 Filter機能改善対応 BY zyz END
        c_termCk = false;
        Date preMonthDate = Date.today().addMonths(-1);
		Integer preYear = preMonthDate.year();
		Integer preMonth = preMonthDate.month();
		// 初期値設定、前月の１日から前月の月末
        c_termSt = new TimeManagement__c(WorkDay__c= Date.newInstance(preYear,preMonth,1));
        c_termEt = new TimeManagement__c(WorkDay__c= Date.newInstance(preYear,preMonth,Date.daysInMonth(preYear,preMonth)));
    }
    // 获取数据
    // 2019/06/15 消込機能改善対応 BY zyz BEGIN
    private void getTtend(Date startDt,Date endDt,Boolean clearFlg,String spcd){
    // 2019/06/15 消込機能改善対応 BY zyz END
        stocks = new list<StockInfo>();
        list<String> days = new list<String>();
        for(Integer i=0;startDt <= endDt;i++){
            String dtStr = DateTime.newInstance(startDt.year(), startDt.month(), startDt.day()).format('yyyyMMdd');
            days.add(dtStr);
            startDt = startDt.addDays(1);
        }
        c_termCk = clearFlg;
        String ACC_TRADE_VOID = CommConst.ACC_TRADE_VOID;
        // 2019/06/15 消込機能改善対応 BY zyz BEGIN
        // 支付方式过滤集合		ｸﾚ計・掛計等:MEDIA_TYPE_CD_02;掛計:MEDIA_TYPE_CD_03;クーポン:MEDIA_TYPE_CD_11
        if (mediaSet.isEmpty()) mediaSet = new set<String>{CommConst.MEDIA_TYPE_CD_02,CommConst.MEDIA_TYPE_CD_03,CommConst.MEDIA_TYPE_CD_11};
        if(!layoutFlg) {
        	mediaSet = new set<String>{CommConst.MEDIA_TYPE_CD_03};
        	spcd = '';
        }
        // 2019/06/15 消込機能改善対応 BY zyz END
        // 2019/07/15 入金消込機能ソートを保持の改善 BY zyz BEGIN
        getUserConfig(spcd);
        // 2019/07/15 入金消込機能ソートを保持の改善 BY zyz END
        String queryStr = ' select Id,Field1__c,Field1__r.Name,Field1__r.Relreserve__r.Name,Field34__c, '
                         + ' Field1__r.ContactName__c,Field1__r.BillingCal__c,Field1__r.SalesDate__c, '
                         + ' Field20__c,ClearFlg__c,ClearName__c,ClearDateTime__c,Field29__c, '
						 + ' Field1__r.relaccount__c,RelAccount__c,RelAccount__r.Name,ClearLog__c, ' 
                         // 2019/06/15 消込機能改善対応 BY zyz BEGIN
                         + ' ReceiptDt__c,PayProductRef__r.Name,ShopCodeCal__c,Field1__r.Relreserve__c,Field2__c, '
                         // 2019/06/15 消込機能改善対応 BY zyz END
                         // 2019/08/15 入金消込機能の改善 BY zyz BEGIN
                         + 'Comment__c,ClearPayment__c,'
                         // 2019/08/15 入金消込機能の改善 BY zyz END
                         // 2019/11/30 Filter機能改善対応 BY zyz BEGIN
                         + 'Field28__c,'
                         // 2019/11/30 Filter機能改善対応 BY zyz END
                         + ' Field1__r.Relreserve__r.CancelBool__c,Field1__r.Field39__c, '
                         + ' PayProductName__c,ArTranId__c,PayProductRef__c,PaymentType__c,Field3__c  '
                         // 2019/06/15 消込機能改善対応 BY zyz BEGIN
                         + ' from TTend__c where Field2__c =: mediaSet '
                         // 2019/06/15 消込機能改善対応 BY zyz END
                         + ' and Field1__r.Field39__c != : ACC_TRADE_VOID '
                         + ' and RelAccount__r.Name in: days ';
        if(!clearFlg) queryStr +=' and ClearFlg__c =: clearFlg ';
        // 2019/06/15 消込機能改善対応 BY zyz BEGIN
        if(!CommUtils.isBlank(spcd)) queryStr +=' and ShopCodeCal__c =: spcd ';
        // 2019/06/15 消込機能改善対応 BY zyz END
        // 2019/11/15 入金消込のvisualforceページ改善 BY zyz BEGIN
        queryStr += ' order by Field1__r.BillingCal__c,Field1__r.ContactName__c,Field1__r.SalesDate__c limit 2000';
        // 2019/11/15 入金消込のvisualforceページ改善 BY zyz END
        list<TTend__c> ttendLst = DataBase.query(queryStr);
        for(TTend__c t : ttendLst){
            StockInfo stockInfo = new StockInfo(t);
            stocks.add(stockInfo);
        }
        // 2019/06/15 消込機能改善対応 BY zyz BEGIN
        ttendItemJson = JSON.serialize(stocks);
        // 2019/06/15 消込機能改善対応 BY zyz END
        // 2019/11/15 入金消込のvisualforceページ改善 BY zyz BEGIN
        if(ttendLst.size() == 2000) {
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, '入金消込抽出数が制限を超えました(2000件まで)'));
        }
        // 2019/11/15 入金消込のvisualforceページ改善 BY zyz END
    }
    // 2019/06/15 消込機能改善対応 BY zyz BEGIN
    // 店铺list做成
    private static UserUtil.UserShopInfo userInf;
    private void setInitBranShopLst(String pShopCode) {
    	branchShopLst = new List<SelectOption>();
        branchShopLst = ShopInfoUtil.getBranchShopLst(userInf.shops);
        if (!branchShopLst.isEmpty()) {
        	String locShopCode = pShopCode;
        	for (SelectOption s : branchShopLst) {
        		if (s.getValue() == locShopCode) branchShopNm = locShopCode;
        	}
        }
    }
    // 读取显示json数据
    // 2019/09/27 性能改善 WSQ BEGIN
    //public String ttendItemJson{get;set;}
    public transient String ttendItemJson{get; private set;}
    // 2019/09/27 性能改善 WSQ END
    // 2019/06/15 消込機能改善対応 BY zyz END
    // 检索按钮响应
    public void getTTend() {
        Date beigndt = c_termSt.WorkDay__c;
        Date enddt = c_termEt.WorkDay__c;
        Boolean checkBn = c_termCk;
        // 2019/06/15 消込機能改善対応 BY zyz BEGIN
        String shopcd = CommUtils.nullToBlank(branchShopNm);
        getTtend(beigndt,enddt,checkBn,shopcd);
        // 2019/06/15 消込機能改善対応 BY zyz END
    }
    // 2019/07/15 入金消込機能ソートを保持の改善 BY zyz BEGIN
    private void getUserConfig(String ShopCode){
		map<string,string> userConfigMap = UserConfigCompCtrl.getKrepConfig(userId, ShopCode);
		String configSwapValueKey = UserConfigCompCtrl.KREP_SUBTYPE.BILLERASE.name();
		String configSwapFlgVal = '';
		configFieldVal = '';
		configDirVal = '';
		if (userConfigMap.containsKey(configSwapValueKey)) configSwapFlgVal = userConfigMap.get(configSwapValueKey);
		String[] autoSplit = configSwapFlgVal.split(':');
		configFieldVal = CommUtils.nullToBlank(autoSplit[0]);
		if (autoSplit.size() >= 2) configDirVal = CommUtils.nullToBlank(autoSplit[1]);
    }
    // 2019/07/15 入金消込機能ソートを保持の改善 BY zyz END
    // 数据的JSON字符串
    public String saveValStr{get;set;}
    // 保存按钮响应
    public void saveTTend(){
        if (!CommUtils.isBlank(saveValStr)) {
            RequestInfo info = (RequestInfo)JSON.deserialize(saveValStr,RequestInfo.class);
            Set<Id> typeSet = new Set<Id>(info.ttends);
			// 数据的时间范围
            Date begDt = Date.Parse(info.bDt);
            Date endDt = Date.Parse(info.eDt);
            // 2019/06/15 消込機能改善対応 BY zyz BEGIN
            String shopcd = CommUtils.nullToBlank(info.tspcd);
            // 2019/06/15 消込機能改善対応 BY zyz END
			// 数据存储的MAP
            Map<String,String> ttendMap = info.diffTTendMap;
            Map<String,String> clearFlgMap = info.diffFlgMap;
            // 2019/06/15 消込機能改善対応 BY zyz BEGIN
            Map<String,String> ReceiptDtMap = info.diffRepMap;
            // 2019/06/15 消込機能改善対応 BY zyz END
            // 2019/08/15 入金消込機能の改善 BY zyz BEGIN
            Map<String,String> paymentMap = info.diffPayMap;
            Map<String,String> commentMap = info.diffComMap;
            // 2019/08/15 入金消込機能の改善 BY zyz END
            Boolean checkBn = true;
            if(info.bcheck =='false') checkBn = false;
			// 根据ID获取的会计支付数据
			// 2019/05/15 未变更的数据不进行更新 BY zyz BEGIN
			// 2019/08/15 入金消込機能の改善 BY zyz BEGIN
			// 2019/11/30 Filter機能改善対応 BY zyz BEGIN
            List<TTend__c> upTTendLst = [Select Id,ClearFlg__c,ClearName__c,ClearDateTime__c,ClearLog__c,ReceiptDt__c,Comment__c,ClearPayment__c,Field29__c,Field28__c From TTend__c where Id in : typeSet];
            // 2019/11/30 Filter機能改善対応 BY zyz END
            // 2019/08/15 入金消込機能の改善 BY zyz END
            // 2019/05/15 未变更的数据不进行更新 BY zyz END
            for(TTend__c up : upTTendLst){
                if (ttendMap.containsKey(up.Id)) {
					// 2019/08/15 入金消込機能の改善 BY zyz BEGIN
					Decimal paymentDec = CommUtils.nullToZero(paymentMap.get(up.Id));
					Boolean paymentFlg = false;
					if(paymentDec != 0) paymentFlg = true;
					String commentStr = CommUtils.nullToBlank(commentMap.get(up.Id));
					// 2019/08/15 入金消込機能の改善 BY zyz END
					// 数据的checkbox状态
					Boolean diffclearFlg = (clearFlgMap.get(up.Id) == 'true' ? true : false );
					// 2019/05/15 未变更的数据不进行更新 BY zyz BEGIN
					// 2019/06/15 消込機能改善対応 BY zyz BEGIN
					String receiptDtStr = CommUtils.nullToBlank(ReceiptDtMap.get(up.Id));
					String oldReceiptDtStr = '';
					String UName = userName;
					if(up.ReceiptDt__c != null )oldReceiptDtStr = up.ReceiptDt__c.format('yyyy/MM/dd');
					// 2019/08/15 入金消込機能の改善 BY zyz BEGIN
					// if(up.ClearFlg__c == diffclearFlg && receiptDtStr == oldReceiptDtStr) continue;
					if(up.ClearFlg__c == diffclearFlg && receiptDtStr == oldReceiptDtStr && !paymentFlg && up.Comment__c == commentStr) continue;
					// 2019/08/15 入金消込機能の改善 BY zyz END
					// 2019/06/15 消込機能改善対応 BY zyz END
					// 2019/05/15 未变更的数据不进行更新 BY zyz END
					// 数据状态变更时间
					String ttendDTStr = ttendMap.get(up.Id);
					DateTime ttendDT = DateTime.Parse(ttendDTStr);
					// 数据变更log
					String clearlogStr = '';
					// diffclearFlg是true（売掛支付未消込变更为消込）；false（売掛支付消込变更为未消込）
					// 2019/08/15 入金消込機能の改善 BY zyz BEGIN
					if(up.ClearFlg__c != diffclearFlg || receiptDtStr != oldReceiptDtStr) {
					// 2019/08/15 入金消込機能の改善 BY zyz END
						if(diffclearFlg) {
							clearlogStr = '未消込 => 消込 ( ' +userName + ' '+ ttendDTStr + ' )' ;
						}else{
							clearlogStr = '消込 => 未消込 ( ' +userName + ' '+ ttendDTStr + ' )' ;
							UName ='';
							ttendDT = null;
						}
					// 2019/08/15 入金消込機能の改善 BY zyz BEGIN
					} else if(paymentDec != 0 && !diffclearFlg){
						UName ='';
						ttendDT = null;
					} else if(up.Comment__c != commentStr){
						UName = up.ClearName__c;
						ttendDT = up.ClearDateTime__c;
					}
					paymentDec += CommUtils.nullToZero(up.ClearPayment__c);
					if(paymentDec < 0) paymentDec = 0;
					// 2019/11/30 Filter機能改善対応 BY zyz BEGIN
					if(CommUtils.nullToZero(up.Field28__c) < paymentDec) paymentDec = CommUtils.nullToZero(up.Field28__c);
					// 2019/11/30 Filter機能改善対応 BY zyz END
					// 2019/08/15 入金消込機能の改善 BY zyz END
					// 2019/06/15 消込機能改善対応 BY zyz BEGIN
					// 入金日设定
					if(layoutFlg) {
						if(!CommUtils.isBlank(receiptDtStr)){
							Time dt = System.now().time();
							Date dt1 = Date.parse(receiptDtStr);
							DateTime receiptDt = DateTime.newInstance(dt1, dt);
							if(receiptDtStr != oldReceiptDtStr) up.ReceiptDt__c = receiptDt;
						} else if(CommUtils.isBlank(receiptDtStr)) up.ReceiptDt__c = null;
					}
					// 2019/06/15 消込機能改善対応 BY zyz END
                    up.ClearFlg__c = diffclearFlg;
					up.ClearLog__c = clearlogStr;
					// 2019/06/15 消込機能改善対応 BY zyz BEGIN
                    up.ClearName__c = UName;
                    // 2019/06/15 消込機能改善対応 BY zyz END
					up.ClearDateTime__c = ttendDT;
					// 2019/08/15 入金消込機能の改善 BY zyz BEGIN
					up.ClearPayment__c = paymentDec;
					up.Comment__c = commentStr;
					// 2019/08/15 入金消込機能の改善 BY zyz END
                }
            }
            if (!upTTendLst.isEmpty()) upsert upTTendLst;
			// 页面更新
			// 2019/06/15 消込機能改善対応 BY zyz BEGIN
            getTtend(begDt,endDt,checkBn,shopcd);
            // 2019/06/15 消込機能改善対応 BY zyz END
        }
    }
    // josn字符串
    class RequestInfo{
		List<Id> ttends;					// 支付Id
		String bdt;							// 检索开始日期
		String edt;							// 检索结束日期
		String bcheck;						// 检索check状态
		Map<String,String> diffFlgMap;		// 消込状态Map
		Map<String,String> diffTTendMap;	// 消込时间Map
		// 2019/06/15 消込機能改善対応 BY zyz BEGIN
		String tspcd;						// 店铺code
		Map<String,String> diffRepMap;		// 入金日Map
		// 2019/06/15 消込機能改善対応 BY zyz END
		// 2019/08/15 入金消込機能の改善 BY zyz BEGIN
		Map<String,String> diffPayMap;		// 输入金额
		Map<String,String> diffComMap;		// コメント
		// 2019/08/15 入金消込機能の改善 BY zyz END
    }
    // 2019/11/30 Filter機能改善対応 BY zyz BEGIN
    private String getFilterVal(){
    	Boolean filterFlg = CommDefine__c.getOrgDefaults().BillEraseFilterFlg__c == null ? false : CommDefine__c.getOrgDefaults().BillEraseFilterFlg__c;
    	// 定义  => true：显示checbox过滤；false：显示filter过滤
    	if(filterFlg) return '{ multi : true,search: true}';
    	else return 'true';
    }
    // 2019/11/30 Filter機能改善対応 BY zyz END
    // 页面数据
    public class StockInfo{
        public Id ttendId{get;set;}                 // 支付明细Id
        public String ttLead{get;set;}              // ご予約
        public String ttLeadId{get;set;}            // ご予約Id
        public String ttContact{get;set;}           // お客様
        public String ttContactId{get;set;}         // お客様Id
        public String ttReceiptName{get;set;}       // 請求宛名
        public String ttAccount{get;set;}           // 会計
        public String ttAccountId{get;set;}         // 会計Id
        public String ttSalesDate{get;set;}         // 売上計上日
        public Decimal ttPayment{get;set;}          // 支払金額
        public Boolean ttClearFlg{get;set;}         // 消込フラグ
        public String ttClearName{get;set;}         // 消込者
        public String ttClearDateTime{get;set;}     // 消込日
        // 2019/06/15 消込機能改善対応 BY zyz BEGIN
    	public String ttReceiptDt{get;set;}			// 入金日
    	public String ttProductName{get;set;}		// 支払商品
    	public Boolean ttchangeFlg{get;set;} 		// 消込记录处理
    	// 2019/06/15 消込機能改善対応 BY zyz END
    	// 2019/08/15 入金消込機能の改善 BY zyz BEGIN
    	public String ttComment{get;set;} 			// コメント欄
    	public Decimal ttClearPayment{get;set;} 	// 消込金額初期値
    	public Decimal ttsettlePayment{get;set;}	// 済み
    	public Decimal ttOldPayment{get;set;} 		// 残金
    	// 2019/08/15 入金消込機能の改善 BY zyz END
        public StockInfo(TTend__c tt){
            ttSalesDate = '';
            ttClearDateTime = '';
            ttendId = tt.Id;
            // 2019/06/15 消込機能改善対応 BY zyz BEGIN
            ttchangeFlg = false;
            ttProductName = CommUtils.nullToBlank(tt.PayProductRef__r.Name);
            ttLead = CommUtils.nullToBlank(tt.Field1__r.Relreserve__r.Name);
            ttLeadId = CommUtils.nullToBlank(tt.Field1__r.Relreserve__c);
            ttContact = CommUtils.nullToBlank(tt.Field1__r.ContactName__c);
            ttContactId = CommUtils.nullToBlank(tt.Field1__r.relaccount__c);
            ttReceiptName = CommUtils.nullToBlank(tt.Field1__r.BillingCal__c);
            ttAccount = CommUtils.nullToBlank(tt.Field1__r.Name);
            ttAccountId = CommUtils.nullToBlank(tt.Field1__c);
            if (tt.Field1__r.SalesDate__c != null) ttSalesDate = tt.Field1__r.SalesDate__c.format();
            // 2019/11/30 Filter機能改善対応 BY zyz BEGIN
            ttPayment = CommUtils.nullToZero(tt.Field28__c);
            // 2019/11/30 Filter機能改善対応 BY zyz END
            ttClearFlg = tt.ClearFlg__c;
            ttClearName = CommUtils.nullToBlank(tt.ClearName__c);
            if (tt.ClearDateTime__c != null) ttClearDateTime = tt.ClearDateTime__c.format('yyyy/MM/dd HH:mm');
            // 入金日
            ttReceiptDt = '';
            if (tt.ReceiptDt__c != null) ttReceiptDt = tt.ReceiptDt__c.format('yyyy/MM/dd');
            // 2019/06/15 消込機能改善対応 BY zyz END
            // 2019/08/15 入金消込機能の改善 BY zyz BEGIN
            ttComment = CommUtils.nullToBlank(tt.Comment__c);
            ttClearPayment = 0;
            ttsettlePayment = CommUtils.nullToZero(tt.ClearPayment__c);
            ttOldPayment = ttPayment - ttsettlePayment;
            // 2019/08/15 入金消込機能の改善 BY zyz END
        }
    }
}