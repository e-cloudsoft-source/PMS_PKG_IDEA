/********************************************
*
*********************************************/
public with sharing class LeadItemSplitProcess extends CommBaseCtrl{
    // 詳細画面から引渡の会計ID
    private final Id recordId;
    // 該当会計データに関連付くの予約データのLeadIndexId
    private Id recordRefIndexId;
    // 最大抽出会計数制限値
    private static final Integer MaxQueryLimit = 150;
    //明細抽出数が制限を超えました(XXXXXX件まで)
    private static final String MaxQueryWarnMsg = Label.MSG_011_0103.replace('XXXXXX',String.valueOf(MaxQueryLimit)); 
    
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
    public Lead__c accSobj{get; private set;}
    // 2018/01/15 分割会計時を行う際、店舗切替できるように改善対応
    public String oShopCode{get; set;}
    // 2019/06/30 会計書の発行日付
    public String accDate{get; set;}
    // 該当ユーザーの関聯の施設コード
    public String oFacilityCode{get{return ShopInfoUtil.getShopFacilityCode(UserUtil.CurrentUser.ShopCode__c);}}
    // 見積書ハンコ表示・非表示
    public Boolean stampIsShowFlg{get{ return (CommDefine__c.getOrgDefaults().BookingReportStampIsShowFlg__c == null ? false : CommDefine__c.getOrgDefaults().BookingReportStampIsShowFlg__c);}set;}
    // 会計分割内容出力フラグ
    public Boolean accSplitOutputFlg{get{return CommDefine__c.getOrgDefaults().AccountSplitOutputFlg__c == null ? false : CommDefine__c.getOrgDefaults().AccountSplitOutputFlg__c;}set;}
    // 個人組織通貨情報格納
    public String oDefaultCurrency{get{return UserUtil.getDefaultCurrency();}}
    public String toDate{get{return DateTime.now().format(CommBaseCtrl.getDateFormat());}}
    public List<SelectOption> langList{get {
        List<SelectOption> langLst = new List<SelectOption>();
        langLst.add(new SelectOption('JPY', Label.MSG_011_0100));
        langLst.add(new SelectOption('USD', Label.MSG_011_0101));
        return langLst; 
    }}
    // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
    public Boolean respectFlg{get; private set;}
    // 敬称リスト
    public List<Selectoption> mrTypeLst{get{return CommConst.RESPECT_OPTIONS;}}
    public String mrStr{get; set;}
    // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
    /*************************
    * 初期化処理
    **************************/
    public LeadItemSplitProcess(ApexPages.StandardController controller){
        recordId = controller.getId();
        loadInit(recordId);
    }
    private void loadInit(Id recordId) {
        // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
        // 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH BEGIN
        // accSobj = [select id, name ,LeadIndexRef__c,LeadPdfShopCode__c,RoomGroupNo__c,LeadIndexSubId__c,AccountProviso__c,Language__c,Relcontact__r.Name,Relcontact__c,Relcontact__r.Account.Name,RespectLst__c from Lead__c where id = :recordId ];
        accSobj = [select id, name ,LeadIndexRef__c,LeadPdfShopCode__c,RoomGroupNo__c,LeadIndexSubId__c,AccountProviso__c,Language__c,Relcontact__r.Name,Relcontact__c,Relcontact__r.Account.Name,RespectLst__c,ShopCodeCal__c from Lead__c where id = :recordId ];
        // 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH END
        // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
        recordRefIndexId = accSobj.LeadIndexRef__c;
        oShopCode = CommUtils.isBlank(accSobj.LeadPdfShopCode__c) ? UserUtil.CurrentUser.ShopCode__c : accSobj.LeadPdfShopCode__c;
        // 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH BEGIN
        // 获取店铺默认设定Code
        // 2020/06/30 BUG-FIX-#6524 WGCH BEGIN
		if(CommUtils.isBlank(accSobj.LeadPdfShopCode__c)) oShopCode = ShopInfoUtil.getShopDefCd(oShopCode, accSobj.ShopCodeCal__c, UserUtil.CurrentUser.ShopCode__c);
        // 2020/06/30 BUG-FIX-#6524 WGCH END
        // 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH END
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
        if (!CommUtils.isBlank(accSobj.Relcontact__r.Account.Name))
        accountNamsLst.add(new Option(accSobj.Relcontact__r.Account.Name,accSobj.Relcontact__r.Account.Name));
        if (!CommUtils.isBlank(accSobj.Relcontact__r.Name))
        accountNamsLst.add(new Option(accSobj.Relcontact__r.Name,accSobj.Relcontact__r.Name));
        if (!CommUtils.isBlank(accSobj.Relcontact__r.Name))
        // 2013/10/28 会計編集の「会計書宛名、領収書宛名」の選択リスト内容を追加
        accountNamsLst.add(new Option(accSobj.Name,accSobj.Name));
        return JSON.serialize(accountNamsLst);
    }
    private void init() {
        // 一括表示フラグ
        c_showAll = false;
        // 2016/01/11 ポイント、値引以外の支払メデイアも明細に表示、グループNo登録可能対応
        isHaveTtendPayInfo = false;
        // グループ番号リスト
        groupNoOptLst = new List<Selectoption>();
        Schema.DescribeFieldResult fieldResult = BookingEstimateItem__c.SplitGroupNo__c.getDescribe();
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
        }
        paymentMediaJson = JSON.serialize(paymentMediaLst);
        
        // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
        respectFlg = CommConst.RESPECT_ISSHOW_FLG;
        if (respectFlg) {
        	mrStr = CommUtils.nullToBlank(accSobj.RespectLst__c);
        	if(CommUtils.isBlank(mrStr)) mrStr = ShopInfoUtil.RESPECT_DEFAULTVALUE;
        }
        // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
    }
    // ご予約を取得用SQL
    private final String leadSel = ' select id, name, Relcontact__c, Relcontact__r.Name,Relcontact__r.Account.Name,EntryTime__c,Departure__c,CancelBool__c,LeadIndexRef__c,LeadIndexSubId__c,Field372__c,checkoutdate__c,AccountProviso__c,Language__c From Lead__c ';
    private final String bookingSel = ' select id, name, ProductName__c, refBooking__c,refBooking__r.Name,refBooking__r.Relcontact__r.name,refBooking__r.EntryTime__c,refBooking__r.Departure__c,DPChange__c, ActionType__c, SplitGroupNo__c, refAccountMaster__r.Name,Field4__c,Field4__r.Name, GPChange__r.Name, unitPriceIncTaxCal__c,UnitPrice__c, Total__c,SpTotal__c, Amount__c,ParentBookingItemRef__c,UseDate__c,QuotationName__c,refBooking__r.Rroom__r.Name,InvoiceNoShowFlg__c,refBooking__r.QuotationName__c from BookingEstimateItem__c ';
    /*************************
    * ご予約を取得する
    **************************/
    public void refreshBillInfo() {
        // isFromBillSimpleInput = true;
        // 期間格納変数処理化
        c_termSt = new TimeManagement__c(WorkDay__c=null);
        c_termEt = new TimeManagement__c(WorkDay__c=null);
        queryBillInfo();
    }
    public void refreshInfo() {
        queryBillInfo();
    }
    /*************************
    * ご予約を取得する
    **************************/
    // private Boolean isFromBillSimpleInput = false;
    /*************************
    * ご予約を取得する
    **************************/
    private void queryBillInfo() {
        Date StDate = c_termSt.WorkDay__c;
        Date EtDate = c_termEt.WorkDay__c;
        // 情報を初期化する
        billInfLst = new List<BillInfo>();
        // 既存の割合番号を
        Set<String> groupNoSet = new Set<String>();
        // 会計IDリストを格納する
        Map<Id, Integer> accIdxMap = new Map<Id, Integer>();
        // 会計情報を取得する
        Integer idx = 0;
        // 会計Query分を用意する
        String leadQuery = leadSel + this.getAccWhere() + ' Order By Name limit :MaxQueryLimit ';
        bulkAccId = '';
        list<Lead__c> leadlst = DataBase.query(leadQuery);
        if(!leadlst.isEmpty()){
            for (Lead__c acc : leadlst) {
                // 画面に表示用リストを格納する
                BillInfo item = new BillInfo(acc);
                billInfLst.add(item);
                accIdxMap.put(acc.Id, idx);
                idx ++;
                bulkAccId += acc.Id + ',';
            }
        }
        bulkAccId = bulkAccId.substringBeforeLast(',');
        if (billInfLst.size() == MaxQueryLimit) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, MaxQueryWarnMsg));
        }
        
        // 該当会計に関連付くの会計明細（プラン明細が対象外）
        Set<Id> accIdSet = accIdxMap.keySet();
        String tranQuery = bookingSel  + ' where refBooking__c in :accIdSet ' + this.getTranWhere();
        String tranOtherCntQuery = ' select SplitGroupNo__c splitNo from BookingEstimateItem__c where refBooking__c in :accIdSet '; //group by SplitGroupNo__c ';
        // 前受付金
        /*
        String prodActionTypeAr = CommConst.PROD_ACTION_TYPE_AR;
        if (isFromBillSimpleInput) {
            tranQuery += ' And ActionType__c != :prodActionTypeAr ';
            tranOtherCntQuery +=' And ActionType__c != :prodActionTypeAr And ParentBookingItemRef__c = null  ';
        }
        */
        // プラン明細は非展開する場合、条件を追加する
        if (!CommConst.APPOTION_ACCOUNTSPLIT_BKISHOW) tranOtherCntQuery +=' And ParentBookingItemRef__c = null  ';
        tranOtherCntQuery += ' group by SplitGroupNo__c ';
        
        tranQuery += ' Order By Name ';
        
        // 取得する情報を
        Map<Id, Integer> planIdxMap = new Map<Id, Integer>();
        
        list<BookingEstimateItem__c> estimateItemlst =  DataBase.query(tranQuery);
        for (BookingEstimateItem__c tran : estimateItemlst) {
            if(!CommUtils.isBlank(CommUtils.nullToBlank(tran.UnitPrice__c))) tran.UnitPrice__c = CommUtils.nullToZero(tran.UnitPrice__c);
            if(CommUtils.isBlank(CommUtils.nullToBlank(tran.QuotationName__c))) {
            	if(!CommUtils.isBlank(tran.refBooking__r.QuotationName__c)) tran.QuotationName__c = tran.refBooking__r.QuotationName__c;
            	else tran.QuotationName__c = tran.refBooking__r.Relcontact__r.name;
            }
            if(CommUtils.isBlank(CommUtils.nullToBlank(tran.UseDate__c))) {
				tran.UseDate__c = tran.refBooking__r.EntryTime__c.date();
                // 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH BEGIN
                // if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI) {
                if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI && !CommConst.BOOKEST_USERDATE_FLG) {
                // 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH END
		    		tran.UseDate__c = tran.refBooking__r.Departure__c.date();
		    	}
            }
            // 会計に、関連の会計明細対象データは配列に格納する(注：プラン所属するプラン明細は対象外)
            BillInfo billItem = billInfLst[accIdxMap.get(tran.refBooking__c)];
            TranInfo convertTran = new TranInfo(tran);
            convertTran.entry = tran.refBooking__r.EntryTime__c.format(CommBaseCtrl.getDateFormat());
            // 支払情報を取得する
            if (tran.ActionType__c == CommConst.PROD_ACTION_TYPE_PY || tran.ActionType__c == CommConst.PROD_ACTION_TYPE_AR) {
                convertTran.ttendId = tran.Id;
                isHaveTtendPayInfo = true;
            }
            billItem.addTran(convertTran);

            // プラン商品場合
            if (tran.ActionType__c == CommConst.PROD_ACTION_TYPE_PL)
               planIdxMap.put(tran.Id, billItem.tranLst.size()-1);
        }

        // プランが存在する場合、プラン明細を取得、メモーに格納する
        if (!planIdxMap.isEmpty() && !isNotQuerySub() && CommConst.APPOTION_ACCOUNTSPLIT_BKISHOW) {
            Set<Id> pTranIdSet = planIdxMap.keySet();
            tranQuery = bookingSel  + ' where refBooking__c in :accIdSet And ParentBookingItemRef__c in :pTranIdSet ' + this.getTranSubWhere();
            
            for (BookingEstimateItem__c tran : DataBase.query(tranQuery)) {

                // 会計情報を取得する
                BillInfo bInfo = billInfLst[accIdxMap.get(tran.refBooking__c)];

                // プラン情報を取得する
                TranInfo tInfo = bInfo.tranLst[planIdxMap.get(tran.ParentBookingItemRef__c)];
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
        // 2019/09/15 Security Check BY zyz BEGIN
        List<String> chkFieldsLst = new List<String>{'sptotal__c'};
        Map<String,Schema.SObjectField> mm = Schema.SObjectType.BookingEstimateItem__c.fields.getMap();
        if (!CommSecurityUtils.isCanUpdateable(chkFieldsLst, mm)) {
        	return ;
        }
        // 2019/09/15 Security Check BY zyz END
        List<BookingEstimateItem__c> updLst = new List<BookingEstimateItem__c>();
        for (BillInfo info : billInfLst) {
            for (TranInfo tranItem : info.tranLst) {
	        	if (tranItem.tran.InvoiceNoShowFlg__c && CommConst.APPOTION_ACCOUNTNOSHOW_FLG) tranItem.tran.SpTotal__c = 0;
	        	else tranItem.tran.SpTotal__c = null;
                updLst.add(tranItem.tran);
                updLst.addAll(tranItem.childLst);
            }
        }
        update updLst;
        queryBillInfo();
    }
    // 2016/01/11 ポイント、値引以外の支払メデイアも明細に表示、グループNo登録可能対応
    public boolean isHaveTtendPayInfo{get; private set;}    
    /**
    * ご予約IDリストを取得する
    **/
    private String getAccWhere () {
        //　ご予約IDを取得する
        String wStr = '';

        // 一括会計
        if (c_showAll) {
            if (String.isEmpty(recordRefIndexId)) {
                wStr += ' Where CancelBool__c != ' + CommConst.LEAD_ST_CANCEL_FLG;
            } else {
                wStr += ' Where LeadIndexRef__c = :recordRefIndexId And CancelBool__c != ' + CommConst.LEAD_ST_CANCEL_FLG;
            }
        } else {
            if (String.isEmpty(recordRefIndexId)) {
                wStr += ' Where Id = :recordId ';
            } else {
                wStr += ' Where LeadIndexRef__c = :recordRefIndexId ' +
                        ' And LeadIndexSubId__c = \'' + String.escapeSingleQuotes(Commutils.nullToBlank(accSobj.LeadIndexSubId__c)) + '\''+ 
                        ' And RoomGroupNo__c = ' + String.escapeSingleQuotes(Commutils.nullToBlank(accSobj.RoomGroupNo__c));
            }
            wStr += ' And CancelBool__c != ' + CommConst.LEAD_ST_CANCEL_FLG;
        }
        if (c_termSt.WorkDay__c != null) {
            DateTime formater = DateTime.newInstance(c_termSt.WorkDay__c.year(),c_termSt.WorkDay__c.month(),c_termSt.WorkDay__c.day());
            wStr += ' And DAY_ONLY(convertTimezone(EntryTime__c)) >= : StDate ';
        }
        if (c_termEt.WorkDay__c != null) {
            DateTime formater = DateTime.newInstance(c_termEt.WorkDay__c.year(),c_termEt.WorkDay__c.month(),c_termEt.WorkDay__c.day());
            wStr += ' And DAY_ONLY(convertTimezone(EntryTime__c)) <= : EtDate ';
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
            wStr += ' And ProductName__c = :c_productNm ';
        }
        // c_dpId
        if (!CommUtils.isBlank(c_dpId)) {
            wStr += ' And Field4__c = :c_dpId ';
        }
        // c_gpId
        if (!CommUtils.isBlank(c_gpId)) {
            wStr += ' And GPChange__c = :c_gpId ';
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
        if (!isNotQuerySub()) wStr = ' And ParentBookingItemRef__c = null ';
        return wStr;
    }
    /**
    * 検索条件にて、会計明細の検索条件を作成する
    **/
    private String getTranSubWhere() {
        String wStr = '';
        // 商品名を入力する場合、一致商品名の明細情報を表示する
        if (!CommUtils.isBlank(c_productNm)) {
            wStr += ' And ProductName__c = :c_productNm ';
        }
        // c_dpId
        if (!CommUtils.isBlank(c_dpId)) {
            wStr += ' And Field4__c = :c_dpId ';
        }
        // c_gpId
        if (!CommUtils.isBlank(c_gpId)) {
            wStr += ' And GPChange__c = :c_gpId ';
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
        return wStr;
    }

    /************************
    * 会計と関連の会計明細格納
    *************************/
    public class BillInfo {

        public BillInfo(Lead__c pAcc) {
            acc = pAcc;
            tranLst = new List<TranInfo>();
        }
        public Lead__c acc{get; private set;}
        public List<TranInfo> tranLst{get; private set;}
        public void addTran(TranInfo tran) {
            tran.isFirst = (tranLst.size() == 0) ? true : false;
            tranLst.add(tran);
        }

    }
    public class TranInfo {
        public TranInfo(BookingEstimateItem__c p_tran) {
            tran = p_tran;
            childLst = new List<BookingEstimateItem__c>();
            
            // 数量情報が存在するば場合、小数部右側に表示する０は外す対応
            if (!Commutils.isBlank(Commutils.nullToBlank(tran.Amount__c))) tran.Amount__c = CommUtils.nullToZero(tran.Amount__c);
        }
        public String groupNo{get;set;}
        public String entry{get;set;}
        public Boolean isFirst{get; set;}
        public BookingEstimateItem__c tran{get; private set;}
        public List<BookingEstimateItem__c> childLst{get; private set;}
        // プランするがどうか
        public Boolean isPlan{get{return (tran.ActionType__c == CommConst.PROD_ACTION_TYPE_PL ? true : false);}}
        public void addChild(BookingEstimateItem__c tran) {
            // 数量情報が存在するば場合、小数部右側に表示する０は外す対応
            if (!Commutils.isBlank(Commutils.nullToBlank(tran.Amount__c))) tran.Amount__c = CommUtils.nullToZero(tran.Amount__c);
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
    // 共通定义 ： 会計分割明細のBreakDown明細表示・非表示フラグ
    public Boolean getAccountSplitBkIshow() {
        return CommConst.APPOTION_ACCOUNTSPLIT_BKISHOW;
    }

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
}