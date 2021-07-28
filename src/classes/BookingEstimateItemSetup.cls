/************************
* 見積明細設定機能
* 2014/08/05 過去の合計計算不具合修正と部屋宿泊税自動設定機能外す
* 2014/09/17 金額小数がない場合、画面に小数非表示対応
* 2015/01/26 ハンコ表示・非表示機能対応
* 2015/10/25 クリアする場合、元の見積明細情報はプランすると、プラン明細情報をクリアを行う
* 2017/03/23 見積書を２パターン用意する場合などの為に、見積明細１.2...などいくつか作成できる機能
* 2018/10/24 見積明細自動計算機能対応
* 2018/12/15 請求書-領収書新規レイアウトを追加
* 2019/07/30 軽減税率機能対応
* 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応
* 2019/10/30 見積の発行日付のデフォルト値を制御フラグ
* 2020/01/30 予約作成段階では「利用日」が入力
* 2020/08/30 複数のプランとそれぞれのプランの人数を選択し機能対応
*************************/
global with sharing class BookingEstimateItemSetup extends CommBaseCtrl{
	// 2018/10/24 見積明細自動計算機能対応 WGCH BEGIN
	// 2016/10/27 非表示機能とき、合計金額（税込）は０円でDBへ格納する、しない制御機能追加
	public static Boolean accountNoSetAmountWhenNoShowFlg{get{return CommConst.APPOTION_ACCOUNTNOSHOW_FLG;}}
	public Boolean prodAmountAutoCompFlg{get{return true;}}	// 見積明細page自动计算Flg
	// 会計種別：プラン
	public String ACTTYPE_PAY{get{return CommConst.PROD_ACTION_TYPE_PY;}}	// 支払
	public String ACTTYPE_AR {get{return CommConst.PROD_ACTION_TYPE_AR;}}	// 前受金
	public String MEDIA_TYPE_COPON		{get{return CommConst.MEDIA_TYPE_11;}}
	public String MEDIA_TYPE_DISCOUNT	{get{return CommConst.MEDIA_TYPE_12;}}
	// 支払ボタンに定義する情報は格納する、該当支払いは支払いMediaと変換定義情報が可能
	// 前受金の場合、自動→会計処理種別は「前受金」、その以外の場合、「支払」情報を定義する
	// XMLの定義情報から取得する
	private Map<String, String> PAYMENT_MATCH_MAP = new Map<String, String>();
	public String payTypeConvertJson{get{return JSON.serialize(PAYMENT_MATCH_MAP);}}
	// 返金キー情報格納用
	public String refundItemString{get{return JSON.serialize(BillSimpleHelp.getRefundItemStr());}}
	// 画面利用する店舗コード情報[支払情報、会計商品選べるコンポネット表示の支店コード]
	public String oShopCode{get; private set;}
	/*************************
	* 会計商品の支払種別から支払メデイア対応表XML分析処理
	**************************/
	private void setPaymentToPayMeidaXml() {
		// 格納用変数クリアする
		BillSimpleHelp help = new BillSimpleHelp(oShopCode);
		PAYMENT_MATCH_MAP = help.getPaymentTypeToMediaLabMap();
	}
	// 2018/07/27 宿泊税計算 WGCH BEGIN
	public String hotelInfoJson{get{ if(CommUtils.isBlank(hotelInfoJson)) hotelInfoJson = JSON.serialize(new HotelTaxDefineInfo()); return hotelInfoJson;} set;}
	public class HotelTaxDefineInfo{
		public HotelTaxDefineInfo(){
			planItemPriceMap = new Map<String, List<Decimal>>();
		}
		public Map<String, CommLogicProcess.HotelTaxDefineInfo> hotelTaxDefInstance{get{ return CommLogicProcess.getHotelTaxDefInstance();}}
		public Map<String, List<Decimal>> planItemPriceMap{get; private set;}
	}
	public void setHotelInfoJson(Set<String> pIdSet,HotelTaxDefineInfo hotelInfo){
		if(!pIdSet.isEmpty()){ // 处理Plan明细(商品处理种别=>室料商品)
			String pdQueryStr = ' Select ParentBookingItemRef__c, UnitPrice__c From BookingEstimateItem__c Where ParentBookingItemRef__c in: pIdSet And ActionType__c = \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_RP) + '\'';
			for (BookingEstimateItem__c sobj: DataBase.query(pdQueryStr)) {
				if(!hotelInfo.planItemPriceMap.containsKey(sobj.ParentBookingItemRef__c)) hotelInfo.planItemPriceMap.put(sobj.ParentBookingItemRef__c, new List<Decimal>());
				// 明细 -> 単価(税込)
				hotelInfo.planItemPriceMap.get(sobj.ParentBookingItemRef__c).add(CommUtils.nullToZero(sobj.UnitPrice__c));
			}
		}
		hotelInfoJson = JSON.serialize(hotelInfo);
	}
	// 2018/07/27 宿泊税計算 WGCH END
	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
	public String OPTION_MODE{get{ return CommConst.OPTION_MODE;}}
	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
	// 2018/10/24 見積明細自動計算機能対応 WGCH END
     // ご予約へ編集権限あり、なし
	public boolean isCanUpdateLead{get{return CommSecurityUtils.isCanUpdateLead();}}
    //private static final Integer LIST_INPUT_MAX_ROWS = 27;
    private static final Integer LIST_INPUT_DEF_ROWS = ( CommUtils.nullToIntZero(CommConst.APPOTION_DETAIL_DEF_INPUTLINES) == 0 
    													? 27 
    													: CommUtils.nullToIntZero(CommConst.APPOTION_DETAIL_DEF_INPUTLINES) );
    // 遷移先からパラメータ情報を格納する
    private Map<String,String> paramMap;
    // 予約ID
    public String leadId{get; private set;}
    public Lead__c leasSobj{get; private set;}
	// 2016/12/27 見積明細利用日機能対応 BEGIN zyz
    public String defUseDate{get; private set;}
    // 2016/12/27 見積明細利用日機能対応 END zyz
	// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
	public Boolean RespectFlg{get{return CommConst.RESPECT_ISSHOW_FLG;}}
	public String mrStr{get; private set;}
	public List<Selectoption> mrTypeLst{get; private set;}
	// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
    // 見積書の宛名
   	// 会計種別：プラン
	public String ACTTYPE_PLAN{get{return CommConst.PROD_ACTION_TYPE_PL;}}
	// 2015/01/26 ハンコ表示・非表示機能対応
	public Boolean stampIsShowFlg{get{
		// 予約の設定値を取得する
		Boolean defaultFlg = CommDefine__c.getOrgDefaults().BookingReportStampIsShowFlg__c;
		if (leasSobj != null) {
			if (CommUtils.isBlank(leasSobj.StampIsShowDiv__c)) return defaultFlg;
			else return (CommUtils.nullToBlank(leasSobj.StampIsShowDiv__c) != '0' );
		} else return defaultFlg;
	} set{
		// 画面からBoolean設定値により、区分設定値を反映する
		if (value) leasSobj.StampIsShowDiv__c = '1';
		else leasSobj.StampIsShowDiv__c = '0';
	}}
	// 2017/12/13 見積明細非表示機能対応 WGCH BEGIN
	// ０円自動非表示設定機能
	public Boolean commNoShowRequestFlg{get{return CommDefine__c.getOrgDefaults().NoShowRequestFlg__c;}}
	// 2017/12/13 見積明細非表示機能対応 WGCH END
	// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH BEGIN
	public Boolean billRcptIsShowFlg{get{return CommConst.Bill_RCPTISSHOW_FLG;}}
	public List<SelectOption> accProvisoLst{get; private set;}
	// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH END
    // 予約Controll
    //private ApexPages.StandardController ctrl;
	public BookingEstimateItemSetup(ApexPages.StandardController controller) {
		//ctrl = controller;
		leadId = controller.getId();
		// 初期化処理を行う
		if (!initInfo()) return;
		// 見積明細詳細一覧を取得する
		refreshBookEstItemInfo(leadId);
	}

	private Boolean initInfo() {
		// 全画面から引渡「予約ID」を取得する
		//paramMap = Apexpages.currentPage().getParameters();
		if (CommUtils.isBlank(leadId)) {
			//パラメータ設定不正、管理者に連絡ください。
			Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_011_0069));
			return false;
		}
		// リード存在チェックを行う
		// 2015/09/28 ADD BEGIN
		// 2017/11/28 多見積対応　by zy BEGIN
		// 2018/06/05 見積書の英語版対応 WGCH BEGIN
		// 2018/10/24 見積明細自動計算機能対応 WGCH BEGIN
		// List<Lead__c> leadLst = [select id, Name,EntryTime__c, Departure__c,LeadPdfShopCode__c, StampIsShowDiv__c, LeadReceiptDate__c, Field310__c,Relcontact__r.name,Relcontact__r.Account.Name,QuotationName__c,QuotationComment__c,LeadIndexSubId__c,LeadIndexRef__c,RoomGroupNo__c,Language__c from Lead__c where Id = :leadId];
		// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH BEGIN
		// List<Lead__c> leadLst = [select id, Name,EntryTime__c, Departure__c,LeadPdfShopCode__c, StampIsShowDiv__c, LeadReceiptDate__c, Field310__c,Relcontact__r.name,Relcontact__r.Account.Name,QuotationName__c,QuotationComment__c,LeadIndexSubId__c,LeadIndexRef__c,RoomGroupNo__c,Language__c,Rroom__r.ShopInfoRef__r.ShopCode__c from Lead__c where Id = :leadId];
		// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
		// List<Lead__c> leadLst = [select id, Name,EntryTime__c, Departure__c,LeadPdfShopCode__c, StampIsShowDiv__c, LeadReceiptDate__c, Field310__c,Relcontact__r.name,Relcontact__r.Account.Name,QuotationName__c,QuotationComment__c,LeadIndexSubId__c,LeadIndexRef__c,RoomGroupNo__c,Language__c,Rroom__r.ShopInfoRef__r.ShopCode__c,BillSaveFlg__c,AccountReceiptName__c,BillingCal__c,AccountProviso__c from Lead__c where Id = :leadId];
		// 2019/10/30 見積の発行日付のデフォルト値を制御フラグ BY zyz BEGIN
		// 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH BEGIN
		// List<Lead__c> leadLst = [select id, Name,EntryTime__c, Departure__c,LeadPdfShopCode__c, StampIsShowDiv__c, LeadReceiptDate__c, Field310__c,Relcontact__r.name,Relcontact__r.Account.Name,QuotationName__c,QuotationComment__c,LeadIndexSubId__c,LeadIndexRef__c,RoomGroupNo__c,Language__c,Rroom__r.ShopInfoRef__r.ShopCode__c,BillSaveFlg__c,AccountReceiptName__c,BillingCal__c,AccountProviso__c,RespectLst__c,LeadReceiptDateFlg__c from Lead__c where Id = :leadId];
		// 2020/08/30 複数のプランとそれぞれのプランの人数を選択し機能対応 zyz BEGIN
		List<Lead__c> leadLst = [select id, Name,EntryTime__c, Departure__c,LeadPdfShopCode__c, StampIsShowDiv__c, LeadReceiptDate__c, Field310__c,Relcontact__r.name,Relcontact__r.Account.Name,QuotationName__c,QuotationComment__c,LeadIndexSubId__c,LeadIndexRef__c,RoomGroupNo__c,Language__c,Rroom__r.ShopInfoRef__r.ShopCode__c,BillSaveFlg__c,AccountReceiptName__c,BillingCal__c,AccountProviso__c,RespectLst__c,LeadReceiptDateFlg__c,ShopCodeCal__c,refTypeOfRooms__c,StayPersons__c,refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c from Lead__c where Id = :leadId];
		// 2020/08/30 複数のプランとそれぞれのプランの人数を選択し機能対応 zyz END
		// 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH END
		// 2019/10/30 見積の発行日付のデフォルト値を制御フラグ BY zyz END
		// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
		// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH END
		// 2018/10/24 見積明細自動計算機能対応 WGCH END
		// 2018/06/05 見積書の英語版対応 WGCH END
		// 2017/11/28 多見積対応　by zy END
		// 2015/09/28 ADD END
		// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
		mrTypeLst = new List<Selectoption>();
		Schema.DescribeFieldResult fieldResult = Lead__c.RespectLst__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
	   	for( Schema.PicklistEntry f : ple) {
	   		if(f.isDefaultValue()) mrStr = f.getLabel();
        	mrTypeLst.add(new SelectOption(f.getValue(),f.getLabel()));
	   	}
	   	// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
		if (leadLst.isEmpty()) {
			//予約データはすでに削除された。
			Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_011_0070));
			return false;
		}
		leasSobj = leadLst[0];
		// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH BEGIN
		if(billRcptIsShowFlg){
			// 領収書宛名
			if(!leasSobj.BillSaveFlg__c) leasSobj.AccountReceiptName__c = leasSobj.BillingCal__c;
			// 会計書但し
			accProvisoLst = new List<SelectOption>{new SelectOption('', '')};
			for(String item : CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().AccountProviso__c).split(',')){
				if(item.contains(':1')){ // 默认值获取处理
					String defAccProviso = item.split(':1')[0];
					accProvisoLst.add(new SelectOption(defAccProviso, defAccProviso));
					if(!leasSobj.BillSaveFlg__c) leasSobj.AccountProviso__c = defAccProviso; // 初期设置默认值
				} else accProvisoLst.add(new SelectOption(CommUtils.nullToBlank(item), CommUtils.nullToBlank(item)));
			}
		}
		// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH END
		// 2018/10/24 見積明細自動計算機能対応 WGCH BEGIN
		// 店舗コード情報設定を行う
		oShopCode = CommUtils.isBlank(leasSobj.Rroom__r.ShopInfoRef__r.ShopCode__c) ? UserUtil.CurrentUser.ShopCode__c : leasSobj.Rroom__r.ShopInfoRef__r.ShopCode__c;
		// 2020/08/30 複数のプランとそれぞれのプランの人数を選択し機能対応 zyz BEGIN
		basePlanDate = leasSobj.EntryTime__c.format(CommBaseCtrl.getDateFormat());
		// 根据房型的设定店铺code取得XML设定
		String cdStr = CommUtils.isBlank(leasSobj.refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c) ? oShopCode : leasSobj.refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c;
		baseplanSwitch(cdStr);
		// 2020/08/30 複数のプランとそれぞれのプランの人数を選択し機能対応 zyz END
		// 支払メディア情報のXML設定情報取得
		setPaymentToPayMeidaXml();
		// 2018/10/24 見積明細自動計算機能対応 WGCH END
		// 2018/06/05 見積書の英語版対応 WGCH BEGIN
		String currencyInf = UserInfo.getDefaultCurrency();         // ログインユーザーの組織通貨を取得する
		if(CommUtils.isBlank(leasSobj.Language__c)) leasSobj.Language__c = currencyInf == 'JPY' ? currencyInf : 'USD';
		// 2018/06/05 見積書の英語版対応 WGCH END
		// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
		if(CommUtils.isBlank(leasSobj.RespectLst__c)) leasSobj.RespectLst__c = mrStr;
		// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
		// 2017/11/28 多見積対応　by zy BEGIN
		/*
		// 2016/12/27 見積明細利用日機能対応 BEGIN zyz
		defUseDate = leasSobj.EntryTime__c.format(CommBaseCtrl.getDateFormat());
		if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI) {
			defUseDate = leasSobj.Departure__c.format(CommBaseCtrl.getDateFormat());
		}
		// 2016/12/27 見積明細利用日機能対応 END zyz
		// 見積書宛名
		if (CommUtils.isBlank(leasSobj.QuotationName__c)) {
			leasSobj.QuotationName__c = leasSobj.Relcontact__r.name;
		}
		// 発行日付
		if (leasSobj.LeadReceiptDate__c == null) {
			leasSobj.LeadReceiptDate__c = Date.today();
		}*/
		//見積書情報設定
		initLeadPdf();
		// 2017/11/28 多見積対応　by zy END
		// 2015/09/28 ADD BEGIN
		// 複数の店舗情報を設定されている場合、画面に見積書を出力の店舗コード
		shopList = new List<SelectOption>();
		UserUtil.UserShopInfo userInf = UserUtil.CurrentUserInfo;
		if (CommUtils.isBlank(leasSobj.LeadPdfShopCode__c)) {
			leasSobj.LeadPdfShopCode__c = userInf.defaultShopCode;
			// 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH BEGIN
			// 获取店铺默认设定Code
			leasSobj.LeadPdfShopCode__c = ShopInfoUtil.getShopDefCd(leasSobj.LeadPdfShopCode__c, leasSobj.ShopCodeCal__c, userInf.defaultShopCode);
			// 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH END
		}
		if (userInf.shops.size() > 1) {
			// 店舗情報を取得する
			Map<String,ShopInformation__c> shopMap = ShopInfoUtil.getShopInfoMap();
			for (String shopCode : userInf.shops) {
				if (shopMap.containsKey(shopCode)) {
					ShopInformation__c shop = shopMap.get(shopCode);
					shopList.add(new SelectOption(shop.ShopCode__c, shop.name));
				}
			}
		}
		// 2015/09/28 ADD END
		// 2017/11/28 多見積対応　by zy BEGIN
		quoName = '';
		chkInfo = new ChkInfo();
		moreLst = new List<String>();	
		// 收藏列表
		bookMarkLst = new List<Selectoption>();
		paramMap = Apexpages.currentPage().getParameters();
		String subId = paramMap.get('more');
		if (!CommUtils.isBlank(subId)) moreLst = subId.split(',');
		// 指定見積
		quotaOrTemplateId = CommUtils.nullToBlank(paramMap.get('quota'));
		// 根据
		refreshQuotaInfo(quotaOrTemplateId);
		// 多見積予約対応
		chkInfo.autoMoreFlag = !moreLst.isEmpty();
		// 見積状態設定
		chkInfo.mitumoriFlag = paramMap.containsKey('mitumo');
		// 新規フラグ
		chkInfo.newMitumoriFlag = paramMap.containsKey('newTemp');
		// 2017/11/28 多見積対応　by zy END
		return true;
	}
	private void initLeadPdf(){
		// 2016/12/27 見積明細利用日機能対応 BEGIN zyz
		defUseDate = leasSobj.EntryTime__c.format(CommBaseCtrl.getDateFormat());
		// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH BEGIN
		// if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI) {
		if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI && !CommConst.BOOKEST_USERDATE_FLG) {
		// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH END
			defUseDate = leasSobj.Departure__c.format(CommBaseCtrl.getDateFormat());
		}
		// 2016/12/27 見積明細利用日機能対応 END zyz
		// 見積書宛名
		if (CommUtils.isBlank(leasSobj.QuotationName__c)) {
			leasSobj.QuotationName__c = leasSobj.Relcontact__r.name;
		}
		// 2019/10/30 見積の発行日付のデフォルト値を制御フラグ BY zyz BEGIN
		// 発行日付
		/*if (leasSobj.LeadReceiptDate__c == null) {
			leasSobj.LeadReceiptDate__c = Date.today();
		}*/
		leadReceiptDateFlg = CommConst.LEAD_RECEIPTDATE_FLG;
		if(leadReceiptDateFlg){
		LeadNewDate =  Date.today().format();
		if (leasSobj.LeadReceiptDate__c == null) {
				leasSobj.LeadReceiptDate__c = Date.today();
				LeadReceiptDate = Date.today().format();
			}else{
				LeadReceiptDate = leasSobj.LeadReceiptDate__c.format();
				if(leasSobj.LeadReceiptDateFlg__c) leasSobj.LeadReceiptDate__c = Date.today();
			}
		} else if (leasSobj.LeadReceiptDate__c == null) {
			leasSobj.LeadReceiptDate__c = Date.today();
		}
		// 2019/10/30 見積の発行日付のデフォルト値を制御フラグ BY zyz END
	}
	// 2019/10/30 見積の発行日付のデフォルト値を制御フラグ BY zyz BEGIN
	public Boolean leadReceiptDateFlg{get;set;} 		// 功能开关
	public String LeadReceiptDate{get;private set;}		// 功能打开后的原字段值
	public String LeadNewDate{get;private set;}			// 功能打开后的当前日格式化
	// 2019/10/30 見積の発行日付のデフォルト値を制御フラグ BY zyz END
	public List<SelectOption> shopList{get; private set;}
	// 2018/06/05 見積書の英語版対応 WGCH BEGIN
	public List<SelectOption> langList{get {
		List<SelectOption> langLst = new List<SelectOption>();
		langLst.add(new SelectOption('JPY', Label.MSG_011_0100));
		langLst.add(new SelectOption('USD', Label.MSG_011_0101));
		return langLst; 
	}}
	// 2018/06/05 見積書の英語版対応 WGCH END
	// ****************************
	// 設定されている見積明細
	// leadId:リードID
	public Pagereference upsertData() {
		// 2017/02/21 Field Security Check BEGIN
	    List<String> chkFields = new List<String>{'LeadPdfShopCode__c','LeadReceiptDate__c','QuotationName__c'};
	    Map<String,Schema.SObjectField> m = Schema.SObjectType.Lead__c.fields.getMap();
	    if (!CommSecurityUtils.isCanUpdateable(chkFields, m)) {
			return null;
	    }
	    // 2017/02/21 Field Security Check End
		// 2019/09/15 Security Check BY zyz BEGIN
		if (!CommSecurityUtils.isDeleteable(BookingEstimateItem__c.getSObjectType())) {
			return null;
		}
		// 2019/09/15 Security Check BY zyz END
		// 登録されている明細データを処理を行う
		List<BookingEstimateItem__c> updList = new List<BookingEstimateItem__c>();
		List<BookingEstimateItem__c> delList = new List<BookingEstimateItem__c>();
		// 2014/08/05 EDIT DELETE
		//CommUtils.ProductInfo proc = new CommUtils.ProductInfo();
		// 2017/11/28 多見積対応　by zy BEGIN
		// 日期控制
		Map<date,id> dateLeadMap = new Map<date,id>();
		// 多予約
		List<Id> leadIdLst = new List<Id>();
		// 見積画面明細替え
		Map<String,BookingEstimateItem__c> estItemMap = new Map<String,BookingEstimateItem__c>();
		Date maxDate = leasSobj.entryTime__c.date();
		Date minDate = leasSobj.entryTime__c.date();
		String minLeadId = leadId;
		String maxLeadId = leadId;
		if (chkInfo.mitumoriFlag){
			//同じ予約
			List<Lead__c> leads = [select id, Name,Rroom__c,UnitPriceDefKbCal__c,Relcontact__c,
					StayPersons__c,EntryTime__c,Departure__c,Field4__c,Field3__c,Comment3__c
				from Lead__c 
				where LeadIndexRef__c = :leasSobj.LeadIndexRef__c 
				And LeadIndexSubId__c = :leasSobj.LeadIndexSubId__c
				And RoomGroupNo__c = :leasSobj.RoomGroupNo__c
				And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 
				Order By EntryTime__c ] ;
			for (lead__c lead : leads) {
				dateLeadMap.put(lead.EntryTime__c.date(),lead.id);
				if (maxDate < lead.EntryTime__c.date()) {
					maxDate = lead.EntryTime__c.date();
					maxLeadId = lead.id;
				}		
				if (minDate > lead.EntryTime__c.date()) {
					minDate = lead.EntryTime__c.date();
					minLeadId = lead.id;
				}
				leadIdLst.add(lead.id);
			}
			//&& !CommUtils.isBlank(quotaOrTemplateId)
			if (!leadIdLst.isEmpty()) {
				for ( BookingEstimateItem__c item : [select id, name, refBooking__c, ActionType__c,Amount__c,RowNo__c,
							refAccountMaster__c, refAccountMaster__r.Name, TaxRate__c, ServiceRate__c,SpecialTax__c,UnitPrice__c,
							// 2016/12/08 見積明細利用日機能対応 BEGIN zyz
							UseDate__c,refBooking__r.EntryTime__c,refBooking__r.Departure__c,
							// 2016/12/08 見積明細利用日機能対応 END zyz
							GoukeinoneTax__c, SpTotal__c, ProductName__c, PlanDetailSyncInfo__c
							// 2017/12/13 見積明細非表示機能対応 WGCH BEGIN
							,InvoiceNoShowFlg__c, NoShowRequestFlg__c
							// 2017/12/13 見積明細非表示機能対応 WGCH END
							from BookingEstimateItem__c where refBooking__c = :leadIdLst and ParentBookingItemRef__c = null Order By RowNo__c,Name]) {
					estItemMap.put(item.id,item);
				}
			}
			// 点确定时自动生成数据
			// 自动作成的数据点确定除外
			// && !CommUtils.isBlank(quotaOrTemplateId)
			//if (!chkInfo.autoMoreFlag) quotaOrTemplateId = insertQuta();
		}
		// 2017/11/28 多見積対応　by zy END
		// 登録されているデータに対して、
		for (BookEstItem obj: oBookEstLst) {
			// 2019/02/15 単価定義区分を設定bug改修 BY zyz BEGIN
            // 単価定義区分を設定する
            if(CommUtils.isBlank(obj.sobj.UnitPriceDefKb__c)) obj.sobj.UnitPriceDefKb__c = String.valueOf(CommConst.APPOPTION_UTP_DEF_KB);
            // 2019/02/15 単価定義区分を設定bug改修 BY zyz END
			// 2017/11/28 多見積対応　by zy BEGIN
			if (obj.sobj.Id != null) estItemMap.remove(obj.sobj.id);
			// 2017/11/28 多見積対応　by zy END
			// 商品登録と、有効なデータで登録する
			if (!obj.isValidata) {
                if (obj.sobj.Id != null) delList.add(obj.sobj);
                obj.clear();
                continue;
			}
			// 予約親予約IDを設定する
			// 2017/11/28 多見積対応　by zy BEGIN
			//if (obj.sobj.refBooking__c == null) obj.sobj.refBooking__c = leadId;
			if (obj.sobj.refBooking__c == null) {
				if (dateLeadMap.containsKey(obj.sobj.useDate__c)) obj.sobj.refBooking__c = dateLeadMap.get(obj.sobj.useDate__c);
				else if (minDate > obj.sobj.UseDate__c) {
					obj.sobj.refBooking__c = minLeadId;
				}else if (maxDate < obj.sobj.UseDate__c) {
					obj.sobj.refBooking__c = maxLeadId;
				}
				else obj.sobj.refBooking__c = leadId;
			}
			// 2017/11/28 多見積対応　by zy END
			// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz BEGIN
			if(obj.sobj.UseDate__c == null){
				// 设定到着日为利用日
				obj.sobj.UseDate__c = obj.sobj.refBooking__r.EntryTime__c.date();
				if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI && !CommConst.BOOKEST_USERDATE_FLG) {
					// 设定出发日为利用日
					obj.sobj.UseDate__c = obj.sobj.refBooking__r.Departure__c.date();
				}
			}
			// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz END
			//obj.sobj.Field1__c = oAcountSobj.Id;
			//if(obj.sobj.RelAccount__c == null) obj.sobj.RelAccount__c = oAcountSobj.frs__c;
			// 関連項目を自動設定をを行う
			// 商品名称（または券名称）
			//if (CommUtils.isBlank(obj.sobj.Field5__c))  obj.sobj.Field5__c = obj.productNm;
			obj.sobj.ProductName__c = CommUtils.isBlank(obj.productNm) ? obj.orgProductNm : obj.productNm;
			// 2012/10/17 宿泊税の計算機能を追加する
			// 設定されている商品は室料場合、宿泊税計算を行う
			// 2014/08/05 宿泊税自動設定機能外す BEGIN
			/*
			if (obj.sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_RP) {
				// 部屋料金取得
				proc.process(obj.sobj.UnitPrice__c, 1, obj.sobj.TaxRate__c, obj.sobj.ServiceRate__c);
				// 部屋料金：本体単価（税抜） + 単価サービス料（税抜）
				// 2013/07/24 EDIT: unitPriceIncServiceExcTax = 本体単価（税抜） + 単価サービス料（税抜）
				//Decimal roomPrice = proc.unitPriceExcTax + proc.unitPriceExcService;
				Decimal roomPrice = proc.unitPriceIncServiceExcTax;
				// 特別税計算を行う[入力不可、会計画面に調査する]
				// 2014/07/10 宿泊税自動計算機能は外す
				//obj.sobj.SpecialTax__c = proc.specialTaxCal(roomPrice) * CommUtils.nullToZero(obj.sobj.Amount__c);
			}*/
			// 該当明細の商品はプラン　かつ　参照している商品は同じ　かつ　クリアされている場合、既存のプランの情報を削除する
			if (obj.isPlanProduct &&
				CommUtils.isBlank(obj.itemId) &&
				obj.sobj.Id != null) {
				// 既存のプランとプラン明細情報を削除して、新子見積もり明細を新規作成を行う
				BookingEstimateItem__c planItemClone = 	obj.sobj.clone(false, true);
				delList.add(obj.sobj);
				updList.add(planItemClone);
				continue;
			}
			// 2018/06/25 複数見積で見積修正したデータが残りたい by zy BEGIN
			// 見積明細自動保存
			// 2018/11/30 複数見積「新規、コピー」bug fixed by zy BEGIN
			// if (!isAutoSaveFlag) updateQuota();
			if (!isAutoSaveFlag && !chkInfo.betuFlag) updateQuota();	
			// 2018/11/30 複数見積「新規、コピー」bug fixed by zy END	
			// 2018/06/25 複数見積で見積修正したデータが残りたい by zy END
			// 2014/08/05 宿泊税自動設定機能外す END
			updList.add(obj.sobj);
		}
		Savepoint sp = Database.setSavepoint();
		try {
			// 2017/11/28 多見積対応　by zy BEGIN
			// 見積場合
			if (!estItemMap.isEmpty()) {
				delList.addAll(estItemMap.values());
			}
			// 2017/11/28 多見積対応　by zy END
		//upsert preUpdateInfo(updList);
		if (!delList.isEmpty()) delete delList;
		if (!updList.isEmpty()) upsert preUpdateInfo(updList);
			// 2017/11/28 多見積対応　by zy BEGIN
			// 多見積の場合
			if (chkInfo.mitumoriFlag && !CommUtils.isBlank(quotaInf.id)) updateQuota(leadIdLst);
			// 2017/11/28 多見積対応　by zy END
		// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH BEGIN
		if(billRcptIsShowFlg){
			leasSobj.BillSaveFlg__c = true;
		}
		// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH END
		// 見積書の宛名更新
		update leasSobj;
		} catch(Exception e) {
			DataBase.rollback(sp);
			// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 BEGIN
			String errMsg = e.getMessage();
			if(!CommUtils.isFieldValidationMessage(errMsg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
			// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 END
			return null;
		}
		// 更新後の最新情報を取得する
		refreshBookEstItemInfo(leadId);
		return null;
	}
	// 更新前の関連設定を行う
	private List<BookingEstimateItem__c> preUpdateInfo(List<BookingEstimateItem__c> updLst) {
        for(BookingEstimateItem__c item: updLst) {
        	// 合計金額は全部NULLに設定して、トリガーに最自動計算を行う
        	// 2017/12/29 EDIT START
        	// 非表示＆＆会計の非表示の合計金額設定不要＝TRUEの場合、該当項目金額は自動０になる
        	// その以外の場合、NULLのまま設定する
        	//item.SpTotal__c = null;
        	if (item.InvoiceNoShowFlg__c && CommConst.APPOTION_ACCOUNTNOSHOW_FLG) item.SpTotal__c = 0;
        	else item.SpTotal__c = null;
        	// 2017/12/29 EDIT END
        }
        return updLst;
	}
	
	/**
	* 会計商品情報を取得
	**/
	@remoteAction
	global static ProductItemUtils.ProductItem getProductItemInfo(String prodCode) {
		return ProductItemUtils.getSingProdcutItemByCode(prodCode);
	}
	@remoteAction
	global static List<ProductItemUtils.ProductItem> getArrayProductItemInfo(String prodCode) {
		// 2020/08/30 エステなど商品を追加したプラン機能 WGCH BEGIN
		// return ProductItemUtils.getArrayProdcutItemByCode(prodCode);
		return ProductItemUtils.getArrayProdcutItemByCodeOp(prodCode, false, false, true);
		// 2020/08/30 エステなど商品を追加したプラン機能 WGCH END
	}
	@remoteAction
	global static List<ProductItemUtils.ProductItem> getArrayProductItemInfoNoPlan(String prodCode) {
		return ProductItemUtils.getArrayProdcutItemByCode(prodCode, true);
	}
	
	// ****************************
	// すでに設定済み明細一覧情報を取得する
	// leadId:リードID
	public List<BookEstItem> oBookEstLst{get;private set;}
	// 2017/11/28 多見積対応　by zy BEGIN
	// リアル見積明細の表示
	private void refreshBookEstItemInfo(Id leadId) {
		// 指定見積の場合
		if (!CommUtils.isBlank(quotaInf.id)) refreshQuotaItems();
		// 新規見積の場合
		else if (chkInfo.newMitumoriFlag) newMitumoriItems();
		// 多泊予約の場合
		else if (chkInfo.autoMoreFlag) refreshBookEstItemInfos(moreLst);
		// その他の場合
		else refreshBookEstItemInfoById(leadId);
	}
	private void refreshBookEstItemInfoById(Id leadId){
	// 2017/11/28 多見積対応　by zy END
		//List<BookingEstimateItem__c> bookEstLst = [select from ]
		oBookEstLst = new List<BookEstItem>();
		//String queryStr = CommSqlUtils.generateQueryString('BookingEstimateItem__c');
		//String whereStr = ' Where refBooking__c =  \'' + String.escapeSingleQuotes(leadId) + '\'';
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		List<BookingEstimateItem__c> existBookEstLst = new List<BookingEstimateItem__c>();
		if(!isReducedTaxFlg){
			existBookEstLst = [select id, name, refBooking__c, ActionType__c,Amount__c,RowNo__c,
				refAccountMaster__c, refAccountMaster__r.Name, TaxRate__c, ServiceRate__c,SpecialTax__c,UnitPrice__c,
				// 2016/12/08 見積明細利用日機能対応 BEGIN zyz
				UseDate__c,refBooking__r.EntryTime__c,refBooking__r.Departure__c,
				// 2016/12/08 見積明細利用日機能対応 END zyz
				GoukeinoneTax__c, SpTotal__c, ProductName__c, PlanDetailSyncInfo__c
				// 2017/12/13 見積明細非表示機能対応 WGCH BEGIN
				,InvoiceNoShowFlg__c, NoShowRequestFlg__c
				// 2017/12/13 見積明細非表示機能対応 WGCH END
				// 2018/10/24 見積明細自動計算機能対応 WGCH BEGIN
				,UnitPriceDefKb__c
				,UnitPriceDefKbCal__c
				,PaymentType__c
				,(Select UnitPrice__c, TaxRate__c From ParentBookingItemRef__r where (TaxRate__c = null OR TaxRate__c = 0) And ParentBookingItemRef__r.ActionType__c =: CommConst.PROD_ACTION_TYPE_PL)
				// 2018/10/24 見積明細自動計算機能対応 WGCH END
				,PlanBrkInfo__c
				// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
				,OptionNo__c
				// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
				from BookingEstimateItem__c where refBooking__c = :leadId and ParentBookingItemRef__c = null Order By RowNo__c,Name];
		} else {
			// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
			// String queryStr = ' select id, name, refBooking__c, ActionType__c, Amount__c, RowNo__c, refAccountMaster__c, refAccountMaster__r.Name, TaxRate__c, ServiceRate__c, SpecialTax__c, UnitPrice__c, GoukeinoneTax__c, SpTotal__c, ProductName__c, PlanDetailSyncInfo__c, UseDate__c, refBooking__r.EntryTime__c, refBooking__r.Departure__c, InvoiceNoShowFlg__c, NoShowRequestFlg__c, refAccountMaster__r.PaymentType__c, ParentBookingItemRef__c, TankanonetaxNew__c, UnitPriceDefKbCal__c, PaymentType__c, PlanBrkInfo__c from BookingEstimateItem__c where refBooking__c = :leadId  ';
			String queryStr = ' select id, name, refBooking__c, ActionType__c, Amount__c, RowNo__c, refAccountMaster__c, refAccountMaster__r.Name, TaxRate__c, ServiceRate__c, SpecialTax__c, UnitPrice__c, GoukeinoneTax__c, SpTotal__c, ProductName__c, PlanDetailSyncInfo__c, UseDate__c, refBooking__r.EntryTime__c, refBooking__r.Departure__c, InvoiceNoShowFlg__c, NoShowRequestFlg__c, refAccountMaster__r.PaymentType__c, ParentBookingItemRef__c, TankanonetaxNew__c, UnitPriceDefKbCal__c, PaymentType__c, PlanBrkInfo__c, OptionNo__c from BookingEstimateItem__c where refBooking__c = :leadId  ';
			// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
			queryStr += ' Order By RowNo__c, Name ';
			existBookEstLst = DataBase.query(queryStr);
			setPlanAmountMap(existBookEstLst);
		}
		// 2019/07/30 軽減税率機能対応 WGCH END
		// 2018/10/24 見積明細自動計算機能対応 WGCH BEGIN
		// 2018/07/27 宿泊税計算 WGCH BEGIN
		HotelTaxDefineInfo hotelInfo = new HotelTaxDefineInfo();
		Set<String> pIdSet = new Set<String>();
		// 2018/07/27 宿泊税計算 WGCH END
		// 2018/10/24 見積明細自動計算機能対応 WGCH END
		for (BookingEstimateItem__c sobj: existBookEstLst) {
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			if(sobj.ParentBookingItemRef__c != null) continue;
			// 2019/07/30 軽減税率機能対応 WGCH END
			// 2018/10/24 見積明細自動計算機能対応 WGCH BEGIN
			// 2018/07/27 宿泊税計算 WGCH BEGIN
			if(!hotelInfo.hotelTaxDefInstance.isEmpty() && sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) pIdSet.add(sobj.Id);
			// 2018/07/27 宿泊税計算 WGCH END
			// 2018/10/24 見積明細自動計算機能対応 WGCH END
			BookEstItem item = new BookEstItem(sobj, oBookEstLst.size());
			oBookEstLst.add(item);
		}
		// 2018/10/24 見積明細自動計算機能対応 WGCH BEGIN
		setHotelInfoJson(pIdSet, hotelInfo);
		// 2018/10/24 見積明細自動計算機能対応 WGCH END
		// 2017/01/16 统一行追加功能改修 by wsq BEGIN
        //if (oBookEstLst.size() < LIST_INPUT_DEF_ROWS) {
        //  Integer appendRsSize = LIST_INPUT_DEF_ROWS - oBookEstLst.size();
            Integer appendRsSize = LIST_INPUT_DEF_ROWS - Math.Mod(oBookEstLst.size(), LIST_INPUT_DEF_ROWS);
            // 2017/01/16 统一行追加功能改修 by wsq END
            // 2行目まで設定を行う
            for (Integer i = 0; i < appendRsSize; i++) {
                oBookEstLst.add(new BookEstItem(new BookingEstimateItem__c(refBooking__c = leadId),oBookEstLst.size()));
            }
        // 2017/01/16 统一行追加功能改修 by wsq BEGIN
        //}
        // 2017/01/16 统一行追加功能改修 by wsq END
	}
	// 見積もり明細行目追加
	public Pagereference addBookingItem() {
		//2017/01/16 行追加共通化　by　zy BEGIN
		Map<Integer, BookEstItem> locSortMap = new Map<Integer, BookEstItem>();
		for (BookEstItem item : oBookEstLst) {
			// 画面表示順により、ソートを行う
			locSortMap.put(CommUtils.nullToIntZero(item.sobj.rowNo__c),item);
		}
		List<Integer> sortKeyLst = new List<Integer>();
		sortKeyLst.addAll(locSortMap.keySet());
		sortKeyLst.sort();
		
		oBookEstLst.clear();
		// RowIndex再設定する BEGIN
		for (Integer key : sortKeyLst) {
			BookEstItem orgItem = locSortMap.get(key);
			orgItem.index = oBookEstLst.size();
			oBookEstLst.add(orgItem);
		}
    	// 2020/08/30 複数のプランとそれぞれのプランの人数を選択し機能対応 zyz BEGIN
    	Integer addInputRows = LIST_INPUT_DEF_ROWS;
    	if(addRowsMan != null && addRowsMan != 0) {
    		if(addInputRows >= addRowsMan) addRowsMan = LIST_INPUT_DEF_ROWS;
    		addInputRows = Math.Ceil(addRowsMan/LIST_INPUT_DEF_ROWS).intValue() * LIST_INPUT_DEF_ROWS;
    	}
    	addRowsMan = null;
    	// for (Integer i = 0; i < LIST_INPUT_DEF_ROWS; i++) {
    	for (Integer i = 0; i < addInputRows; i++) {
    	// 2020/08/30 複数のプランとそれぞれのプランの人数を選択し機能対応 zyz END
    		// 見積の場合
    		if (chkInfo.mitumoriFlag) oBookEstLst.add(new BookEstItem(new BookingEstimateItem__c(),oBookEstLst.size()));
	    	else oBookEstLst.add(new BookEstItem(new BookingEstimateItem__c(refBooking__c = leadId),oBookEstLst.size()));
    	}
    	//2017/01/16 行追加共通化　by　zy END
		return null;
	}
	// プラン関連の商品明細を取得する
	// accId:会計ID/会計商品（プラン）ID
	@RemoteAction
	global static List<PlanDetail> getAccountMstLstByPlan(String estItemId, String leadId, String planId) {
		// 会計IDが存在する場合、既に登録された登録情報から情報を展開する
		// 会計IDが非存在場合、
		List<PlanDetail> rsLst = new List<PlanDetail>();
		if (CommUtils.isBlank(leadId)) {
	        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
	        // for (PlanDetail__c pd : [select AccountMasterRef__c, AccountMasterRef__r.name, AccountMasterRef__r.ActionType__c,Price__c,TaxRate__c from PlanDetail__c where PlanProdcut__c = :planId]) {
	        // 2020/08/30 エステなど商品を追加したプラン機能 WGCH BEGIN
	        // for (PlanDetail__c pd : [select AccountMasterRef__c, AccountMasterRef__r.name, AccountMasterRef__r.ActionType__c,Price__c,TaxRate__c,ServiceRate__c from PlanDetail__c where PlanProdcut__c = :planId]) {
	        for (PlanDetail__c pd : [select AccountMasterRef__c, AccountMasterRef__r.name, AccountMasterRef__r.ActionType__c,Price__c,TaxRate__c,ServiceRate__c,OptionAccMstFLG__c from PlanDetail__c where PlanProdcut__c = :planId]) {
	        // 2020/08/30 エステなど商品を追加したプラン機能 WGCH END
	        // 2019/07/30 軽減税率機能対応 WGCH END
                PlanDetail item = new PlanDetail();
                item.prodName = CommUtils.nullToBlank(pd.AccountMasterRef__r.name);
                //item.prodPrice = CommUtils.nullToZero(pd.Price__c).format();
                item.prodPrice = CommUtils.deleteRightZero(CommUtils.nullToZero(pd.Price__c).format(), CommUtils.getPointLen());
                item.sobjId = pd.Id;
                item.prodId = pd.AccountMasterRef__c;
                item.planId = pd.Id;
                item.actionType = pd.AccountMasterRef__r.ActionType__c;
                // 2019/07/30 軽減税率機能対応 WGCH BEGIN
                item.prodTaxRate = CommUtils.nullToZero(pd.TaxRate__c);
                item.prodServiceRate = CommUtils.nullToZero(pd.ServiceRate__c);
                // 2019/07/30 軽減税率機能対応 WGCH END
                // 2020/08/30 エステなど商品を追加したプラン機能 WGCH BEGIN
            	item.optionAccMstFlg = pd.OptionAccMstFLG__c == null ? false : pd.OptionAccMstFLG__c;
            	// 2020/08/30 エステなど商品を追加したプラン機能 WGCH END
                rsLst.add(item);
	        }
		} else {
            // 2019/07/30 軽減税率機能対応 WGCH BEGIN
            // for (BookingEstimateItem__c tr : [select refAccountMaster__c,refAccountMaster__r.ActionType__c, ProductName__c, UnitPrice__c,TaxRate__c from BookingEstimateItem__c where ParentBookingItemRef__c = :estItemId And refBooking__c = :leadId ]) {
            for (BookingEstimateItem__c tr : [select refAccountMaster__c,refAccountMaster__r.ActionType__c, ProductName__c, UnitPrice__c,TaxRate__c,ServiceRate__c from BookingEstimateItem__c where ParentBookingItemRef__c = :estItemId And refBooking__c = :leadId ]) {
            // 2019/07/30 軽減税率機能対応 WGCH END
                PlanDetail item = new PlanDetail();
                item.prodName = CommUtils.nullToBlank(tr.ProductName__c);
                //item.prodPrice = CommUtils.nullToZero(tr.UnitPrice__c).format();
                item.prodPrice = CommUtils.deleteRightZero(CommUtils.nullToZero(tr.UnitPrice__c).format(), CommUtils.getPointLen());
                item.sobjId = tr.Id;
                item.prodId = tr.refAccountMaster__c;
                item.actionType = tr.refAccountMaster__r.ActionType__c;
                // 2019/07/30 軽減税率機能対応 WGCH BEGIN
                item.prodTaxRate = CommUtils.nullToZero(tr.TaxRate__c);
                item.prodServiceRate = CommUtils.nullToZero(tr.ServiceRate__c);
                // 2019/07/30 軽減税率機能対応 WGCH END
                rsLst.add(item);
            }
            // 既存のデータを対応するため、プランのタイトル飲み、存在する場合、明細情報を表示したい場合、該当商品のプラン明細により、明細情報リストを取得する
            if (rsLst.isEmpty()) {
		        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
		        for (PlanDetail__c pd : [select AccountMasterRef__c, AccountMasterRef__r.name,AccountMasterRef__r.ActionType__c, Price__c, TaxRate__c, ServiceRate__c from PlanDetail__c where PlanProdcut__c = :planId]) {
		        // 2019/07/30 軽減税率機能対応 WGCH END
	                PlanDetail item = new PlanDetail();
	                item.prodName = CommUtils.nullToBlank(pd.AccountMasterRef__r.name);
	                //item.prodPrice = CommUtils.nullToZero(pd.Price__c).format();
	                item.prodPrice = CommUtils.deleteRightZero(CommUtils.nullToZero(pd.Price__c).format(), CommUtils.getPointLen());
	                item.sobjId = pd.Id;
	                item.planId = pd.Id;
	                item.prodId = pd.AccountMasterRef__c;
	                item.actionType = pd.AccountMasterRef__r.ActionType__c;
	                // 2019/07/30 軽減税率機能対応 WGCH BEGIN
	                item.prodTaxRate = CommUtils.nullToZero(pd.TaxRate__c);
	                item.prodServiceRate = CommUtils.nullToZero(pd.ServiceRate__c);
	                // 2019/07/30 軽減税率機能対応 WGCH END
	                rsLst.add(item);
		        }
            }
		}
		return rsLst;
	}
	// プラン明細情報を維持する
	global class PlanDetail {
		public String prodName{get; set;}
		public String prodPrice{get; set;}
		public String sobjId{get;set;}
		public String prodId{get;set;}
		public String planId{get;set;} // プラン明細ID
		public String actionType{get;set;}
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		public Decimal prodTaxRate;
		public Decimal prodServiceRate;
		// 2019/07/30 軽減税率機能対応 WGCH END
		// 2020/08/30 エステなど商品を追加したプラン機能 WGCH BEGIN
        public Boolean optionAccMstFlg{get;set;}
        // 2020/08/30 エステなど商品を追加したプラン機能 WGCH END
	}

	// 見積明細情報格納
	public class BookEstItem {
		// 初期化する
		public BookEstItem(BookingEstimateItem__c s, Integer rsIndex) {

			sobj = s;
			index = rsIndex;
			rowNo = String.valueOf(rsIndex);
			s.rowNo__c = rsIndex;
			// 商品名
			productNm = CommUtils.isBlank(sobj.ProductName__c) ? s.refAccountMaster__r.Name : sobj.ProductName__c;
            orgProductNm = s.refAccountMaster__r.Name;
			// 数量
			//prodNums = s.Amount__c;
			prodNums = CommUtils.deleteRightZero(CommUtils.nullToBLank(s.Amount__c));
			// 単価
			unitPrice = CommUtils.deleteRightZero(CommUtils.nullToBLank(s.UnitPrice__c), CommUtils.getPointLen());
			// 特別税
            specialTax = s.SpecialTax__c;
            // 2018/10/24 見積明細自動計算機能対応 WGCH BEGIN
            if (s.InvoiceNoShowFlg__c && accountNoSetAmountWhenNoShowFlg) s.SpTotal__c = 0;
            // 2018/10/24 見積明細自動計算機能対応 WGCH END
            // 合計金額（税込）
            amoutIncTax = s.SpTotal__c;
            // 合計金額（税抜）
            amoutExcTax = s.GoukeinoneTax__c;
			//if (s.id == null) clear();
			// 2019/02/15 単価定義区分を設定bug改修 BY zyz BEGIN
            // 単価定義区分を設定する
            if(s.id == null) s.UnitPriceDefKb__c = String.valueOf(CommConst.APPOPTION_UTP_DEF_KB);
            // 2019/02/15 単価定義区分を設定bug改修 BY zyz END
			isPlanProduct = false;
			itemId = s.Id;
			leadId = s.refBooking__c;
			// 2016/12/08 見積明細利用日機能対応 BEGIN zyz
			if(s.UseDate__c == null && s.refBooking__r != null){
				sobj.UseDate__c = s.refBooking__r.EntryTime__c.date();
				// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH BEGIN
		    	// if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI) {
		    	if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI && !CommConst.BOOKEST_USERDATE_FLG) {
		    	// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH END
		    		sobj.UseDate__c = s.refBooking__r.Departure__c.date();
		    	}
			}
			// 2016/12/08 見積明細利用日機能対応 END zyz
			// 2018/10/24 見積明細自動計算機能対応 WGCH BEGIN
			// plan商品Flg
			isPlanMasterFlg = sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PL;
			if (isPlanMasterFlg && s.ParentBookingItemRef__r != null) {
				initPlanInfo = 0;
				// 既存の会計明細情報を取得する
				for (BookingEstimateItem__c sobj: s.ParentBookingItemRef__r) {
					initPlanInfo += CommUtils.nullToZero(sobj.UnitPrice__c);
				}
			}
			// 2018/10/24 見積明細自動計算機能対応 WGCH END
		}
		public void clear() {
			productNm = null;
			servicePriceIncTax = null;
			specialTax = null;
			prodNums = null;
			amoutExcTax = null;
			amoutIncTax = null;
		}
		// 見積明細格納する
		public BookingEstimateItem__c sobj{get; private set;}
		// 明細Index
		public Integer index{get; private set;}
		// 
		public String itemId{get; set;}
		public String leadId{get; set;}
		// 商品名
		public String productNm{get;set;}
		// 会計商品マスタの商品名
		public String orgProductNm{get;set;}
		// サービス料金(税込)
		public Decimal servicePriceIncTax{get;set;}
		// 特別料金
		public Decimal specialTax{get;set;}
		public String rowNo{get;set;}
		// 単価
		public String unitPrice{get;set{
			unitPrice = value;
			sobj.UnitPrice__c = CommUtils.nullToZero(unitPrice);
		}}
		// 数量
		public String prodNums{get;set{
			prodNums = value;
			sobj.Amount__c = CommUtils.nullToZero(prodNums);
			}}
		// 会計明細単位の合計金額（税抜）
		public Decimal amoutExcTax{get; set;}
		// 会計明細単位の合計金額（税込）[商品売価*数量  + サービス料　+ 特別税]
        public Decimal amoutIncTax{get; set{
        	amoutIncTax = value;
        	if (value !=null && value != sobj.SpTotal__c) sobj.SpTotal__c = value;}}
		public Boolean isValidata{get{
			// 商品コード != null && 単価 != null && 数量 != null
            return (!CommUtils.isBlank(sobj.refAccountMaster__c) &&
                    sobj.UnitPrice__c != null &&
                    sobj.Amount__c != null);
		}}
		public Boolean isPlanProduct{get{return (sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PL ? true : false);} set;}
		// 2017/11/28 多見積対応by　zy　BEGIN
		public String quotaItemId{get;set;}
		// 2017/11/28 多見積対応by　zy　END
		// 2018/10/24 見積明細自動計算機能対応 WGCH BEGIN
		// plan商品Flg
		public Boolean isPlanMasterFlg{get;set;}
		public Decimal initPlanInfo{get; set;}
		// 2018/10/24 見積明細自動計算機能対応 WGCH END
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
		public String gOptionInfoJson{get {if(gOptionInfoJson == null) gOptionInfoJson = ''; return gOptionInfoJson ;} set;}
		public Boolean isSetOptionFlg{get {if(isSetOptionFlg == null) isSetOptionFlg = false; return isSetOptionFlg ;} set;}
		public Boolean showDetailFlg{get {if(showDetailFlg == null) showDetailFlg = false; return showDetailFlg ;} set;}
		public String key{get {if(key == null) key = ''; return key ;} set;}
		public String nwOrderNums{get {if(nwOrderNums == null) nwOrderNums = '0'; return nwOrderNums ;} set;}
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
		// 2020/07/30 入湯税の自動入力機能について改善 zyz BEGIN
		public String bTaxAccMstId{get {if(bTaxAccMstId == null) bTaxAccMstId = ''; return bTaxAccMstId;} set;}
		public String bTaxToPlanRowIndex{get {if(bTaxToPlanRowIndex == null) bTaxToPlanRowIndex = ''; return bTaxToPlanRowIndex;} set;}
		public String bTaxAccMstItem{get {if(bTaxAccMstItem == null) bTaxAccMstItem = ''; return bTaxAccMstItem ;} set;}
		// 2020/07/30 入湯税の自動入力機能について改善 zyz END
		// 2020/08/30 複数のプランとそれぞれのプランの人数を選択し機能対応 zyz BEGIN
		public String oldOrderNums{get {if(oldOrderNums == null) oldOrderNums = '1'; return oldOrderNums ;} set;}
		// 2020/08/30 複数のプランとそれぞれのプランの人数を選択し機能対応 zyz END
	}

	// 見積書宛名
	public String getQuotationNameLst() {
		if (leasSobj == null) leasSobj = new Lead__c();
		JSONGenerator gen = JSON.createGenerator(false);
		gen.writeStartArray();
		if (!CommUtils.isBlank(leasSobj.Relcontact__r.name)) {
			gen.writeStartObject();
			gen.writeStringField('value', leasSobj.Relcontact__r.name);
			gen.writeStringField('label', leasSobj.Relcontact__r.name);
			gen.writeEndObject();
		}
		if (!CommUtils.isBlank(leasSobj.Relcontact__r.Account.Name)) {
			gen.writeStartObject();
			gen.writeStringField('value', leasSobj.Relcontact__r.Account.Name);
			gen.writeStringField('label', leasSobj.Relcontact__r.Account.name);
			gen.writeEndObject();
		}
		// 2019/12/30 宛名の候補にも「ご予約名」を表示する BY zyz BEGIN
		if (!CommUtils.isBlank(leasSobj.Name)) {
			gen.writeStartObject();
			gen.writeStringField('value', leasSobj.Name);
			gen.writeStringField('label', leasSobj.name);
			gen.writeEndObject();
		}
		// 2019/12/30 宛名の候補にも「ご予約名」を表示する BY zyz END
		gen.writeEndArray();
		return gen.getAsString();
	}
	// 2017/11/21参照見積関連追加　by　zy BEGIN
	// 画面にコントローラー
	public ChkInfo chkInfo{get;set;}
	// 多予約リスト
	private List<String> moreLst;
	public String quotaJson{get;set;}
	// 見積情報
	public Quota__c quotaInf{get;set;}
	public String quoName{get;set;}
	public Decimal totalAmount{get;set;}
	public String quotaOrTemplateId{get;set;}
	public Boolean isCopyUserDate{get;set;}
	public List<Selectoption> quotaNm{get;set;}
	public static String QUOTA_STATUS_KARI = '仮保存';
	private static final String BOOKING_SOBJ_KEY = BookingEstimateItem__c.sObjectType.getDescribe().getKeyPrefix();
	public static String QUOTA_STATUS_FORMAL = '本保存';
	// ブックマークリスト
	public List<Selectoption> bookMarkLst{get; private set;}
	// 新規の見積の場合
	private void newMitumoriItems(){
		// 收藏列表
		map<String,String> userBookMap = UserConfigCompCtrl.getCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.ESTIMATE,UserUtil.CurrentUser.id,'');
		String quotaLstStr = CommUtils.nullToBlank(userBookMap.get(UserConfigCompCtrl.KREP_SUBTYPE.BOOKMARK.name()));
		List<String> bookIdLst = quotaLstStr.split(',');
		// 查询見積数据
        for (Quota__c s: [select id, QuotaDescription__c, QuotaName__c from Quota__c where id =:bookIdLst order by Name limit 50]) {
            String opStr =  CommUtils.nullToBlank(s.QuotaName__c) + ' : ' + CommUtils.nullToBlank(s.QuotaDescription__c);
            // 該当ご予約関連の見積明細の場合
            // 2018/10/25 常に新規保存になってしまい、見積もりがいくつも作成されてしまいます。 by cxw BEGIN
            if (CommUtils.isBlank(quotaOrTemplateId))
            // 2018/10/25 常に新規保存になってしまい、見積もりがいくつも作成されてしまいます。 by cxw END
            	bookMarkLst.add(new SelectOption(s.id, opStr));
        }
        // 2018/10/25 常に新規保存になってしまい、見積もりがいくつも作成されてしまいます。 by cxw BEGIN
        // 新规页面设定为false
        //isCopyUserDate = false;
        isCopyUserDate = !CommUtils.isBlank(quotaOrTemplateId);
        //if (!CommUtils.isBlank(quotaOrTemplateId)) refreshQuota();
        // 2018/10/25 常に新規保存になってしまい、見積もりがいくつも作成されてしまいます。 by cxw END
	}
	// 新規、コピーの場合ボタン「次へ」機能
	public void nextStep(){
		// 有选择見積
		if (!CommUtils.isBlank(quotaInf.id)) {
			quotaOrTemplateId = quotaInf.id;
			// 保持内容
			Quota__c lastQuota = quotaInf.clone(false,false);
			refreshQuotaItems();
			// 見積内容回复
			quotaInf = lastQuota;
		} else {
			// 2018/10/25 常に新規保存になってしまい、見積もりがいくつも作成されてしまいます。 by cxw BEGIN
			if (!CommUtils.isBlank(quotaOrTemplateId)) {
				// ID前三位
				String prefix = CommUtils.nullToBlank(quotaOrTemplateId).subString(0,3);
				if (prefix == leadPrefix) {
					// 見積明細詳細一覧を取得する
					refreshBookEstItemInfos(moreLst);
					for (BookEstItem item : oBookEstLst) {
						// 利用日不copy
						if (!isCopyUserDate && item.sobj.UseDate__c != null) item.sobj.UseDate__c = leasSobj.EntryTime__c.date();
					}
					chkInfo.autoMoreFlag = false;
				}
			} else {
			// 2018/10/25 常に新規保存になってしまい、見積もりがいくつも作成されてしまいます。 by cxw END
				oBookEstLst = new List<BookEstItem>();
				Integer appendRsSize = LIST_INPUT_DEF_ROWS - Math.Mod(oBookEstLst.size(), LIST_INPUT_DEF_ROWS);
	            // 2行目まで設定を行う
	            for (Integer i = 0; i < appendRsSize; i++) {
	                oBookEstLst.add(new BookEstItem(new BookingEstimateItem__c(refBooking__c = leadId),oBookEstLst.size()));
	            }
	        // 2018/10/25 常に新規保存になってしまい、見積もりがいくつも作成されてしまいます。 by cxw BEGIN
			}
			// 2018/10/25 常に新規保存になってしまい、見積もりがいくつも作成されてしまいます。 by cxw END
		}
		// 新規页面收起
		chkInfo.newMitumoriFlag = false;
		//　ボタン表示
		chkInfo.betuFlag = true;
	}
	// 仮確定の機能
	public void kariKakuTei(){
		// 重新作成一个見積
		quotaOrTemplateId = insertQuta();
		upsertQuotaItems();
		// 刷新見積情報
		refreshQuotaInfo(quotaOrTemplateId);
		refreshQuotaItems();
	}
	// iframe用画面リアル機能
	public void refreshWindow(){
		if (!CommUtils.isBlank(leadId)) {
			// 2018/06/05 見積書の英語版対応 WGCH BEGIN
			// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH BEGIN
			// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
			// List<Lead__c> leadLst = [select id, Name,EntryTime__c, Departure__c,LeadPdfShopCode__c, StampIsShowDiv__c, LeadReceiptDate__c, Field310__c,Relcontact__r.name,Relcontact__r.Account.Name,QuotationName__c,QuotationComment__c,LeadIndexSubId__c,LeadIndexRef__c,RoomGroupNo__c,Language__c,AccountReceiptName__c,BillingCal__c,AccountProviso__c from Lead__c where Id = :leadId];
			// 2019/10/30 見積の発行日付のデフォルト値を制御フラグ BY zyz BEGIN
			// 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH BEGIN
			// List<Lead__c> leadLst = [select id, Name,EntryTime__c, Departure__c,LeadPdfShopCode__c, StampIsShowDiv__c, LeadReceiptDate__c, Field310__c,Relcontact__r.name,Relcontact__r.Account.Name,QuotationName__c,QuotationComment__c,LeadIndexSubId__c,LeadIndexRef__c,RoomGroupNo__c,Language__c,AccountReceiptName__c,BillingCal__c,AccountProviso__c,RespectLst__c,LeadReceiptDateFlg__c from Lead__c where Id = :leadId];
			// 2020/08/30 複数のプランとそれぞれのプランの人数を選択し機能対応 zyz BEGIN
			List<Lead__c> leadLst = [select id, Name,EntryTime__c, Departure__c,LeadPdfShopCode__c, StampIsShowDiv__c, LeadReceiptDate__c, Field310__c,Relcontact__r.name,Relcontact__r.Account.Name,QuotationName__c,QuotationComment__c,LeadIndexSubId__c,LeadIndexRef__c,RoomGroupNo__c,Language__c,AccountReceiptName__c,BillingCal__c,AccountProviso__c,RespectLst__c,LeadReceiptDateFlg__c,ShopCodeCal__c,refTypeOfRooms__c,StayPersons__c from Lead__c where Id = :leadId];
			// 2020/08/30 複数のプランとそれぞれのプランの人数を選択し機能対応 zyz END
			// 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH END
			// 2019/10/30 見積の発行日付のデフォルト値を制御フラグ BY zyz END
			// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
			// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH END
			// 2018/06/05 見積書の英語版対応 WGCH END
			if (!leadLst.isEmpty()) leasSobj = leadLst[0];
			// 見積書の情報は設定　
			initLeadPdf();
			// 見積明細詳細一覧を取得する
			refreshBookEstItemInfo(leadId);
		}
	}
	// 2018/06/25 複数見積で見積修正したデータが残りたい by zy BEGIN
	public void updateQuota(){
		// 2018/10/25 常に新規保存になってしまい、見積もりがいくつも作成されてしまいます。 by cxw BEGIN
		if (!CommUtils.isBlank(quotaOrTemplateId)) {
			// ID前三位
			String prefix = CommUtils.nullToBlank(quotaOrTemplateId).subString(0,3);
			if ( prefix != leadPrefix) {
				upsertQuotaItems();
			}
		}
		// 2018/10/25 常に新規保存になってしまい、見積もりがいくつも作成されてしまいます。 by cxw END
	}
	// 2018/06/25 複数見積で見積修正したデータが残りたい by zy END
	// 更新見積
	private void upsertQuotaItems(){
		// 2018/03/07 Security Check BEGIN
		List<String> chkFieldsLst = new List<String>{'usedate__c','unitprice__c','taxrate__c','specialtax__c',
													'servicerate__c','rowno__c','productname__c', //'quotaref__c'
													'refaccountmaster__c','plandetailsyncinfo__c','noshowrequestflg__c',
													'invoicenoshowflg__c','amount__c','actiontype__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.QuotaItem__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
			return ;
		}
		// 2018/03/07 Security Check END
		Map<String,QuotaItem__c> quotaItemMap = new Map<String,QuotaItem__c>();
		// 元見積明細
		for (QuotaItem__c quota : [select id, name, refBooking__c, ActionType__c,Amount__c,RowNo__c,X2_1__c,
			refAccountMaster__c, refAccountMaster__r.Name, TaxRate__c, ServiceRate__c,SpecialTax__c,UnitPrice__c,UseDate__c,refBooking__r.EntryTime__c,refBooking__r.Departure__c,GoukeinoneTax__c, SpTotal__c, ProductName__c, PlanDetailSyncInfo__c, QuotaRef__r.Id
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			,PlanBrkInfo__c
			// 2019/07/30 軽減税率機能対応 WGCH END
			// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
			,OptionNo__c
			// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
			from QuotaItem__c where ParentBookingItemRef__c = null and QuotaRef__c =:quotaOrTemplateId Order By RowNo__c,Name]) {
			quotaItemMap.put(quota.id,quota);
		}
		// 2017/12/11 見積明細金額合計機能追加　by　zy BEGIN
		totalAmount = 0;
		Decimal totalInc = 0;
		// 2017/12/11 見積明細金額合計機能追加　by　zy END
		// 2019/04/30 JINYABUG-1634 bug fix by zy BEGIN
		// 未展開見積もりプラン情報
		Map<String,String> bookingEstMap = new Map<String,String>();
		// 2019/04/30 JINYABUG-1634 bug fix by zy END
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
		Map<String,String> bookingEstBrkMap = new Map<String,String>();
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
		// 既存の見積明細エラー対応　by zy BEGIN
		List<Id> prodId = new List<Id>();
		for (BookEstItem item : oBookEstLst) {
			if (!item.isValidata)  continue;
			// 2019/04/30 JINYABUG-1634 bug fix by zy BEGIN
			//if (item.sobj.id == null) continue;
			// 2019/04/30 JINYABUG-1634 bug fix by zy END
			if (item.sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PL){
				prodId.add(item.sobj.refAccountMaster__c);
				// 2019/04/30 JINYABUG-1634 bug fix by zy BEGIN
				// 未展開のプラン
				if (item.sobj.id != null && CommUtils.isBlank(item.sobj.PlanDetailSyncInfo__c)) 
					bookingEstMap.put(item.sobj.id,'');
				// 2019/04/30 JINYABUG-1634 bug fix by zy END
				// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
				// 未展開のプラン
				if (item.sobj.id != null && CommUtils.isBlank(item.sobj.PlanDetailSyncInfo__c))
					bookingEstBrkMap.put(item.sobj.id, item.sobj.PlanBrkInfo__c);
				// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
			}
		}
		Map<String,List<PlanDetail__c>> prodDetailMap = new Map<String,List<PlanDetail__c>>();
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		for (PlanDetail__c pd : [select AccountMasterRef__c, AccountMasterRef__r.name,AccountMasterRef__r.ActionType__c,PlanProdcut__c, Price__c, TaxRate__c, ServiceRate__c from PlanDetail__c where PlanProdcut__c = :prodId]) {
		// 2019/07/30 軽減税率機能対応 WGCH END
	    	if (!prodDetailMap.containsKey(pd.PlanProdcut__c)) prodDetailMap.put(pd.PlanProdcut__c,new List<PlanDetail__c>());
	        prodDetailMap.get(pd.PlanProdcut__c).add(pd);
		}
		// 2019/04/30 JINYABUG-1634 bug fix by zy BEGIN
		// 未展開の見積もり明細あり
		if (!bookingEstMap.isEMpty()) {
			// 既存見積もり展開情報作成
			List<BookingEstimateItem__c> existBookEstLst = [select id, name, refBooking__c, ActionType__c,Amount__c,RowNo__c,
				refAccountMaster__c, refAccountMaster__r.Name, TaxRate__c, ServiceRate__c,SpecialTax__c,UnitPrice__c,
				// 2016/12/08 見積明細利用日機能対応 BEGIN zyz
				UseDate__c,refBooking__r.EntryTime__c,refBooking__r.Departure__c,
				// 2016/12/08 見積明細利用日機能対応 END zyz
				GoukeinoneTax__c, SpTotal__c, ProductName__c, PlanDetailSyncInfo__c
				// 2017/12/13 見積明細非表示機能対応 WGCH BEGIN
				,InvoiceNoShowFlg__c, NoShowRequestFlg__c
				// 2017/12/13 見積明細非表示機能対応 WGCH END
				// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
				,PlanBrkInfo__c
				// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
				// 2018/10/24 見積明細自動計算機能対応 WGCH BEGIN
				,UnitPriceDefKb__c
				,UnitPriceDefKbCal__c
				,PaymentType__c
				,ParentBookingItemRef__c
				from BookingEstimateItem__c where ParentBookingItemRef__c = :bookingEstMap.keySet() Order By refBooking__c,UseDate__c,RowNo__c,Name];
			for (BookingEstimateItem__c item : existBookEstLst) {
				// 父見積もりのプラン情報
				if (bookingEstMap.containsKey(item.ParentBookingItemRef__c)){
					// 既存情報追加
					String syncInfo = bookingEstMap.get(item.ParentBookingItemRef__c);
					syncInfo += item.id + ':' + CommUtils.numberFormat(CommUtils.nullToZero(item.UnitPrice__c)) + ':' + item.refAccountMaster__c + ':' + item.refAccountMaster__r.name + ';';
					bookingEstMap.put(item.ParentBookingItemRef__c,syncInfo);
					// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
					bookingEstBrkMap.put(item.ParentBookingItemRef__c, item.PlanBrkInfo__c);
					// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
				}
			}		
		}
		// 2019/04/30 JINYABUG-1634 bug fix by zy END
		// 既存の見積明細エラー対応　by zy END
		List<QuotaItem__c> updItemLst = new List<QuotaItem__c>();
		for (BookEstItem item : oBookEstLst) {
			if (!item.isValidata) {
                item.clear();
                continue;
			}
			QuotaItem__c quota = quotaItemMap.get(item.quotaItemId);
			if ( quota == null ) {
				quota = new QuotaItem__c();
				quota.QuotaRef__c = quotaOrTemplateId;
			} else quotaItemMap.remove(item.quotaItemId);
			BookingEstimateItem__c obj = item.sobj;
			quota.UnitPrice__c = CommUtils.nullToZero(obj.UnitPrice__c);
			quota.ProductName__c = CommUtils.isBlank(item.productNm) ? item.orgProductNm : item.productNm;
			quota.Amount__c = obj.Amount__c;
			quota.SpecialTax__c = obj.SpecialTax__c;
			quota.TaxRate__c = obj.TaxRate__c;
			quota.ServiceRate__c = obj.ServiceRate__c;
			quota.refAccountMaster__c = obj.refAccountMaster__c;
			// 2017/12/13 見積明細非表示機能対応 WGCH BEGIN
			quota.InvoiceNoShowFlg__c = obj.InvoiceNoShowFlg__c;
			quota.NoShowRequestFlg__c = obj.NoShowRequestFlg__c;
			// 2017/12/13 見積明細非表示機能対応 WGCH END
			// 2018/10/24 見積明細自動計算機能対応 WGCH BEGIN
			quota.PaymentType__c = obj.PaymentType__c;
			// 2018/10/24 見積明細自動計算機能対応 WGCH END
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			quota.ShopCode__c = leasSobj.LeadPdfShopCode__c;
			// 2019/07/30 軽減税率機能対応 WGCH END
			// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
			quota.OptionNo__c = obj.OptionNo__c;
			// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
			if(obj.ActionType__c == CommConst.PROD_ACTION_TYPE_PL){
				// 2019/04/30 JINYABUG-1634 bug fix by zy BEGIN
				// 既存予約見積もり明細未展開のプラン情報設定
				if (obj.id != null && bookingEstMap.containsKey(obj.id)) obj.PlanDetailSyncInfo__c = bookingEstMap.get(obj.id);
				// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
				// 既存予約見積もり明細未展開のプラン情報設定
				if (obj.id != null && bookingEstBrkMap.containsKey(obj.id)) obj.PlanBrkInfo__c = bookingEstBrkMap.get(obj.id);
				// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
				// 2019/04/30 JINYABUG-1634 bug fix by zy END
				// 見積明細转换
				if (obj.id != null && !CommUtils.isBlank(obj.PlanDetailSyncInfo__c)) {
					if (prodDetailMap.containsKey(quota.refAccountMaster__c)) {
						List<PlanDetail__c> detailLst = prodDetailMap.get(quota.refAccountMaster__c);
						String[] prods = obj.PlanDetailSyncInfo__c.split(';');
						String syncPlan = '';
						for (integer i = 0 ; i < prods.size() ; i++) {
							String message = prods[i];
							if (CommUtils.isBlank(message)) continue;
							String firstId = message.subStringBefore(':');
							// 見積明細ID判断
							if (!firstId.startsWith(BOOKING_SOBJ_KEY)) {
								syncPlan += message + ';';
								continue;
							}
							String lastMsg = message.subStringAfter(':');
							syncPlan += detailLst[i].id + ':' + lastMsg + ';';
						}
						quota.PlanDetailSyncInfo__c = syncPlan;
						// 2019/07/30 軽減税率機能対応 WGCH BEGIN
						quota.PlanBrkInfo__c = obj.PlanBrkInfo__c;
						quota.TankanonetaxNew__c = obj.TankanonetaxNew__c;
						// 2019/07/30 軽減税率機能対応 WGCH END
					}
				// 2019/04/30 JINYABUG-1634 bug fix by zy BEGIN
				// 未展開のプラン対応
				} else if (CommUtils.isBlank(obj.PlanDetailSyncInfo__c) && prodDetailMap.containsKey(obj.refAccountMaster__c)){
					List<PlanDetail__c> details = prodDetailMap.get(obj.refAccountMaster__c);
					String synfInfo = '';
					// 2019/07/30 軽減税率機能対応 WGCH BEGIN
					String planBrkInfo = '';
					// 2019/07/30 軽減税率機能対応 WGCH END
					for (PlanDetail__c detail : details) {
						synfInfo += detail.id + ':' + CommUtils.numberFormat(CommUtils.nullToZero(detail.Price__c)) + ':' + detail.AccountMasterRef__c + ':' + detail.AccountMasterRef__r.name + ';';
						// 2019/07/30 軽減税率機能対応 WGCH BEGIN
						planBrkInfo += CommLogicProcess.getPlanBrkInfo(
											CommUtils.nullToBlank(detail.Price__c), // 単価
											CommUtils.nullToBlank(detail.TaxRate__c), // 消費税
											CommUtils.nullToBlank(detail.ServiceRate__c), // サービス料
											CommUtils.nullToBlank(obj.Amount__c), // 数量
											CommUtils.nullToBlank(obj.SpecialTax__c), // 特別税
											CommUtils.nullToBlank(obj.UnitPriceDefKbCal__c), // 会計商品単価定義区分
											CommUtils.nullToBlank(detail.AccountMasterRef__c), // 会計商品Id
											CommUtils.nullToBlank(detail.AccountMasterRef__r.ActionType__c) // 商品処理種別
										); 
						// 2019/07/30 軽減税率機能対応 WGCH END
					}
					quota.PlanDetailSyncInfo__c = synfInfo;
					// 2019/07/30 軽減税率機能対応 WGCH BEGIN
					quota.PlanBrkInfo__c = planBrkInfo;
					// 2019/07/30 軽減税率機能対応 WGCH END
				// 2019/04/30 JINYABUG-1634 bug fix by zy END
				// 未生成予約見積明細	
				} else {
					quota.PlanDetailSyncInfo__c = obj.PlanDetailSyncInfo__c;
					// 2019/07/30 軽減税率機能対応 WGCH BEGIN
					quota.PlanBrkInfo__c = obj.PlanBrkInfo__c;
					quota.TankanonetaxNew__c = obj.TankanonetaxNew__c;
					// 2019/07/30 軽減税率機能対応 WGCH END
				}
			}
			//quota.SpTotal__c = obj.SpTotal__c;
			quota.ActionType__c = obj.ActionType__c;
			quota.UseDate__c = obj.UseDate__c;
			quota.rowNo__c = obj.rowNo__c;
			quota.X2_1__c = obj.X2_1__c;
			updItemLst.add(quota);
		}
		if (!quotaItemMap.isEmpty()) delete quotaItemMap.values(); 
		if (!updItemLst.isEmpty()) {
			//合計金額内容の自動設定
			// 2017/12/11 見積明細金額合計機能追加　by　zy BEGIN
			totalAmount = autoSetupFieldValue(updItemLst);
			// 2017/12/11 見積明細金額合計機能追加　by　zy END
			upsert updItemLst;
		}
		// 2017/12/11 見積明細金額合計機能追加　by　zy BEGIN
		// 更新見積INFO
		update new Quota__c(id = quotaOrTemplateId,TotalInc__c = totalAmount);
		// 2017/12/11 見積明細金額合計機能追加　by　zy END
	}
	// #合計金額など項目内容の自動設定
	// 2017/12/11 見積明細金額合計機能追加　by　zy BEGIN
	// private void autoSetupFieldValue(QuotaItem__c[] newLst){
	private Decimal autoSetupFieldValue(QuotaItem__c[] newLst){
		Decimal totalInc = 0;
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		Decimal totalIncEnd = 0;
		// トリガーは更新前の場合
		map<string,CommLogicProcess.HotelTaxDefineInfo> hotelTaxDefMap = CommLogicProcess.getHotelTaxDefInstance();
		// 2019/07/30 軽減税率機能対応 WGCH END
	// 2017/12/11 見積明細金額合計機能追加　by　zy END
		// #合計金額　＝　単価（税込）　＊　数量　＋　(単価（税込）　＊　数量) * サビース料金(%)　＋ 特別税　
        // 2016/04/13 JPY以外の場合、２桁小数の単価（税抜き）計算を行う BEGIN
        Integer locPointLen = CommUtils.getPointLen();
        // 2016/04/13 JPY以外の場合、２桁小数の単価（税抜き）計算を行う END
//2017/04/24 見積もり明細効率改修　by zy BEGIN
        map<String,Decimal> totalMap = new map<String,Decimal>();
        map<String,Decimal> totalExcMap = new map<String,Decimal>();
//2017/04/24 見積もり明細効率改修　by zy END      
		for (QuotaItem__c nw: newLst) {
			//2017/04/24 見積もり明細効率改修　by zy BEGIN
      	  	// 2019/05/31 見積もり明細効率改修BUG FIX WGCH BEGIN
      	  	// String searchKey = CommUtils.nullToZero(nw.UnitPrice__c) + '_' + CommUtils.nullToZero(nw.Amount__c) + '_' + nw.TaxRate__c  + '_' + nw.ServiceRate__c;
      	  	String searchKey = CommUtils.nullToZero(nw.UnitPrice__c) + '_' + CommUtils.nullToZero(nw.Amount__c) + '_' + nw.TaxRate__c  + '_' + nw.ServiceRate__c + '_' + nw.SpecialTax__c ;
      	  	// 2019/05/31 見積もり明細効率改修BUG FIX WGCH END
      	  	//2017/04/24 見積もり明細効率改修　by zy END
			// 2013/01/13 WSQ
			if (nw.ProductName__c != nw.X2_1__c) nw.X2_1__c = nw.ProductName__c;
			// 2017/12/13 見積明細非表示機能対応 WGCH BEGIN
			if (nw.InvoiceNoShowFlg__c && CommConst.APPOTION_ACCOUNTNOSHOW_FLG) nw.SpTotal__c = 0;
			else nw.SpTotal__c = null;
			// 2017/12/13 見積明細非表示機能対応 WGCH END
			// #合計金額非存在する場合
			if (nw.SpTotal__c == null) {
//2017/04/24 見積もり明細効率改修　by zy BEGIN
				if (!totalMap.containsKey(searchKey)){
//2017/04/24 見積もり明細効率改修　by zy END
					// 2014/08/06   単価定義区分に従って、過去見積もり明細金額変更あり不具合修正 BEGIN
					CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(nw.UnitPriceDefKbCal__c));
					// 2014/08/06   単価定義区分に従って、過去見積もり明細金額変更あり不具合修正 END
	/* 20121005修正を行う（商品単価多目意味機能対応） */
	            	priceInfo.process(CommUtils.nullToZero(nw.UnitPrice__c), CommUtils.nullToZero(nw.Amount__c), nw.TaxRate__c, nw.ServiceRate__c);
	/*				// 売価
					Decimal totalPrice = CommUtils.nullToZero(nw.UnitPrice__c) * CommUtils.nullToZero(nw.Amount__c);
					// サービス料
					Decimal servicePrices = CommUtils.RoundProcess(totalPrice * (CommUtils.nullToZero(nw.ServiceRate__c) / 100),0);
					// #合計金額設定
					nw.SpTotal__c = totalPrice + servicePrices + CommUtils.nullToZero(nw.SpecialTax__c);*/
					nw.SpTotal__c = priceInfo.priceIncTax + CommUtils.nullToZero(nw.SpecialTax__c);
//2017/04/24 見積もり明細効率改修　by zy BEGIN					
					totalMap.put(searchKey,nw.SpTotal__c);
				} else {
					nw.SpTotal__c = totalMap.get(searchKey);
				}
//2017/04/24 見積もり明細効率改修　by zy END
			}
			
			// 2016/04/13 JPY以外の場合、２桁小数の単価（税抜き）計算を行う BEGIN
            // 単価（税抜き）金額は再計算して、設定を行う
            if (locPointLen > 0) {
//2017/04/24 見積もり明細効率改修　by zy BEGIN
            	if (!totalExcMap.containsKey(searchKey)){
//2017/04/24 見積もり明細効率改修　by zy END
            		CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(nw.UnitPriceDefKbCal__c));
	            	priceInfo.process(CommUtils.nullToZero(nw.UnitPrice__c), CommUtils.nullToZero(nw.Amount__c), nw.TaxRate__c, nw.ServiceRate__c);
	           	 	nw.TankawithoutTaxSys__c = priceInfo.unitPriceIncServiceExcTax;
//2017/04/24 見積もり明細効率改修　by zy BEGIN	           	 	
	           	 	totalExcMap.put(searchKey,nw.TankawithoutTaxSys__c);
            	} else {
            		nw.TankawithoutTaxSys__c = totalExcMap.get(searchKey);
            	}
//2017/04/24 見積もり明細効率改修　by zy END
            }
            // 2016/04/13 JPY以外の場合、２桁小数の単価（税抜き）計算を行う END
            // 2017/12/11 見積明細金額合計機能追加　by　zy BEGIN
            if (nw.ActionType__c == CommConst.PROD_ACTION_TYPE_PY || nw.ActionType__c == CommConst.PROD_ACTION_TYPE_AR) totalInc -= nw.SpTotal__c;
			else totalInc += nw.SpTotal__c;
			// 2017/12/11 見積明細金額合計機能追加　by　zy END
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			if(isReducedTaxFlg){
				if (nw.InvoiceNoShowFlg__c && CommConst.APPOTION_ACCOUNTNOSHOW_FLG) continue;
				if (nw.ActionType__c == CommConst.PROD_ACTION_TYPE_PY || nw.ActionType__c == CommConst.PROD_ACTION_TYPE_AR) totalIncEnd -= nw.SpTotal__c;
				else if(!CommUtils.isBlank(nw.PlanBrkInfo__c)){
    				List<List<String>> brkInfoAllLst = CommLogicProcess.getPlanBrkInfoLst(CommUtils.nullToBlank(nw.PlanBrkInfo__c));
    				for(List<String> brkInfoLst : brkInfoAllLst){
    					if(brkInfoLst.size() < 8) continue;
    					// brkInfoLst下标含义:[0]=>单价,[1]=>消费税,[2]=>サービ料,[3]=>数量,[4]=>特别税,[5]=>单价定义区分,[6]=>商品ID,[7]=>商品处理种别
    					Decimal unitPrice = CommUtils.nullToZero(brkInfoLst[0]); // 单价
    					Decimal tax = CommUtils.nullToZero(brkInfoLst[1]); // 消费税
    					Decimal serviceRate = CommUtils.nullToZero(brkInfoLst[2]); // サービ料
    					Decimal nums = CommUtils.nullToZero(brkInfoLst[3]); // 数量
    					Decimal specialTax = CommUtils.nullToZero(brkInfoLst[4]); // 特别税
    					String unitPriceKbn = CommUtils.nullToBlank(brkInfoLst[5]); // 单价定义区分
    					String productId = CommUtils.nullToBlank(brkInfoLst[6]); // 商品ID
    					String actionType = CommUtils.nullToBlank(brkInfoLst[7]); // 商品处理种别
    					String spcd = CommUtils.nullToBlank(nw.ShopCode__c);
    					CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(nw.UnitPriceDefKb__c));
    					CommLogicProcess.HotelTaxInfo hotelTaxItem = CommLogicProcess.getHotelTaxInfo(spcd, CommUtils.nullToBlank(actionType), CommUtils.nullToZero(unitPrice), CommUtils.nullToZero(nums), tax, serviceRate, priceInfo, hotelTaxDefMap);
    					priceInfo = hotelTaxItem.priceInfo;
						totalIncEnd += priceInfo.priceIncTax;
						if(hotelTaxItem.autoSetFlg) totalIncEnd += hotelTaxItem.newNumSepcTaxSum;
    				}
    			} else {
    				String spcd = CommUtils.nullToBlank(nw.ShopCode__c);
    				CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(nw.UnitPriceDefKb__c));
    				CommLogicProcess.HotelTaxInfo hotelTaxItem = CommLogicProcess.getHotelTaxInfo(spcd, CommUtils.nullToBlank(nw.ActionType__c), CommUtils.nullToZero(nw.UnitPrice__c), CommUtils.nullToZero(nw.Amount__c), nw.TaxRate__c, nw.ServiceRate__c, priceInfo, hotelTaxDefMap);
    				priceInfo = hotelTaxItem.priceInfo;
    				totalIncEnd += priceInfo.priceIncTax;
    				if(hotelTaxItem.autoSetFlg) totalIncEnd += hotelTaxItem.newNumSepcTaxSum;
				}
			}
			// 2019/07/30 軽減税率機能対応 WGCH END
		}
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		if(isReducedTaxFlg) return totalIncEnd;
		// 2019/07/30 軽減税率機能対応 WGCH END
		// 2017/12/11 見積明細金額合計機能追加　by　zy BEGIN
		return totalInc;
		// 2017/12/11 見積明細金額合計機能追加　by　zy END
	}
	// 新規見積機能
	private Id insertQuta(){
		// 2018/03/07 Security Check BEGIN
		List<String> chkFieldsLst = new List<String>{'quotaname__c','quotationname__c','stampisshowdiv__c','leadreceiptdate__c',
													'quotationcomment__c','leadref__c','quotastatus__c','LeadPdfShopCode__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.Quota__c.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(chkFieldsLst, mm)) {
			return null;
		}
		// 2018/03/07 Security Check END
		String quotaStatus = QUOTA_STATUS_KARI;
		Quota__c quota = quotaInf.clone(false,false);
		quota.QuotaStatus__c = quotaStatus;
		quota.LeadRef__c = leasSobj.id;
		// 見積書宛名メッセージ設定
		quota.QuotationComment__c = leasSobj.QuotationComment__c;
		quota.LeadReceiptDate__c = leasSobj.LeadReceiptDate__c;
		quota.StampIsShowDiv__c = leasSobj.StampIsShowDiv__c;
		quota.QuotationName__c = leasSobj.QuotationName__c;
		// 2018/06/05 見積書の英語版対応 WGCH BEGIN
		quota.Language__c = leasSobj.Language__c;
		// 2018/06/05 見積書の英語版対応 WGCH END
		// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
		quota.RespectLst__c = leasSobj.RespectLst__c;
		// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
		// 2018/06/25 複数見積で見積修正したデータが残りたい by zy BEGIN
		quota.LeadPdfShopCode__c = leasSobj.LeadPdfShopCode__c;
		// 2018/06/25 複数見積で見積修正したデータが残りたい by zy END
			//Integer defDateLength = 7;
		if (CommUtils.isBlank(quota.QuotaName__c)) quota.QuotaName__c = leasSobj.Name + '（コピー）';
		//if (quota.ExpirationDate__c == null) quota.ExpirationDate__c = leasSobj.entryTime__c.addDays(defDateLength).date();
		//if (CommUtils.isBlank(quota.QuotaDescription__c)) quota.QuotaDescription__c = Label.MSG_011_0077;
		// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH BEGIN
		if(billRcptIsShowFlg){
			quota.BillSaveFlg__c = true;
			quota.AccountReceiptName__c = leasSobj.AccountReceiptName__c;
			quota.AccountProviso__c = leasSobj.AccountProviso__c;
		}
		// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH END
		insert quota; 
		return quota.id;
	}
	// 見積リアル
	public void refreshQuota(){
		// 根据id 刷新見積
		refreshQuotaInfo(quotaInf.id);
	}
	// リアル見積情報
	private void refreshQuotaInfo(String quotaId){
		quotaInf = new Quota__c(QuotaName__c = leasSobj.Name);
		if (!CommUtils.isBlank(quotaId)) {
			// 2017/12/11 見積明細金額合計機能追加　by　zy BEGIN
			List<Quota__c> quotaLst = [select id, name, LeadRef__c,TotalInc__c,QuotaStatus__c, MainQuotaFlg__c, ExpirationDate__c, QuotaDescription__c, QuotaName__c,LastModifiedBy.Name,LastModifiedById,
			// 2017/12/11 見積明細金額合計機能追加　by　zy END						
			// 2018/06/05 見積書の英語版対応 WGCH BEGIN
			Language__c,
			// 2018/06/05 見積書の英語版対応 WGCH END
			// 2018/06/25 複数見積で見積修正したデータが残りたい by zy BEGIN
			LeadPdfShopCode__c,
			// 2018/06/25 複数見積で見積修正したデータが残りたい by zy END
			// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH BEGIN
			BillSaveFlg__c,
			AccountReceiptName__c,
			BillingCal__c,
			AccountProviso__c,
			// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH END
			// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
			RespectLst__c,
			// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
									LastModifiedDate,QuotationComment__c,LeadReceiptDate__c,StampIsShowDiv__c,QuotationName__c from Quota__c where id = :quotaId];
			if (!quotaLst.isEmpty()) {
				quotaInf = quotaLst[0];
				// 見積書宛名メッセージ設定
				leasSobj.QuotationComment__c = quotaInf.QuotationComment__c;
				leasSobj.LeadReceiptDate__c = quotaInf.LeadReceiptDate__c;
				leasSobj.StampIsShowDiv__c = quotaInf.StampIsShowDiv__c;
				leasSobj.QuotationName__c = quotaInf.QuotationName__c;
				// 2018/06/05 見積書の英語版対応 WGCH BEGIN
				leasSobj.Language__c = quotaInf.Language__c;
				// 2018/06/05 見積書の英語版対応 WGCH END
				// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
				leasSobj.RespectLst__c = quotaInf.RespectLst__c;
				// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
				if (!CommUtils.isBlank(quotaInf.LeadPdfShopCode__c)) leasSobj.LeadPdfShopCode__c = quotaInf.LeadPdfShopCode__c;
				// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH BEGIN
				if(billRcptIsShowFlg){
					leasSobj.BillSaveFlg__c = true;
					leasSobj.AccountReceiptName__c = quotaInf.AccountReceiptName__c;
					leasSobj.AccountProviso__c = quotaInf.AccountProviso__c;
				}
				// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH END
			}
		}
		// 利用日不copy
		isCopyUserDate = true;
		// 2017/12/11 見積明細金額合計機能追加　by　zy BEGIN
		totalAmount = CommUtils.nullToZero(quotaInf.TotalInc__c);
		// 2017/12/11 見積明細金額合計機能追加　by　zy END
		quotaJson = JSON.serialize(new QuotaJson(quotaInf));
	}
	//切换見積列表、查询見積明細
	private void refreshQuotaItems() {
		oBookEstLst = new List<BookEstItem>();
		// 2017/12/11 見積明細金額合計機能追加　by　zy BEGIN
		Decimal totalInc = 0;
		// 2017/12/11 見積明細金額合計機能追加　by　zy END
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		List<QuotaItem__c> quotaParItemLst = new List<QuotaItem__c>();
		//根据画面选择的見積名、用传过来的Id查找見積
		if(!isReducedTaxFlg){
			quotaParItemLst = [select id, name, refBooking__c, ActionType__c,Amount__c,RowNo__c,refAccountMaster__c, refAccountMaster__r.Name, TaxRate__c, ServiceRate__c,SpecialTax__c,UnitPrice__c,
				// 2016/12/08 見積明細利用日機能対応 BEGIN zyz
				UseDate__c,refBooking__r.EntryTime__c,refBooking__r.Departure__c,
				// 2016/12/08 見積明細利用日機能対応 END zyz
				// 2017/12/13 見積明細非表示機能対応 WGCH BEGIN
				InvoiceNoShowFlg__c, NoShowRequestFlg__c,
				// 2017/12/13 見積明細非表示機能対応 WGCH END
				// 2018/10/24 見積明細自動計算機能対応 WGCH BEGIN
				UnitPriceDefKbCal__c,
				PaymentType__c,
				// 2018/10/24 見積明細自動計算機能対応 WGCH END
				GoukeinoneTax__c, SpTotal__c, ProductName__c, PlanDetailSyncInfo__c, QuotaRef__r.Id,X2_1__c
				// 2019/07/30 軽減税率機能対応 WGCH BEGIN
				,PlanBrkInfo__c
				,TankanonetaxNew__c
				// 2019/07/30 軽減税率機能対応 WGCH END
				// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
				,OptionNo__c
				// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
				from QuotaItem__c where ParentBookingItemRef__c = null and QuotaRef__c =: quotaOrTemplateId Order By RowNo__c,Name];
		} else {
			String queryStr = ' select id, name, refBooking__c, ActionType__c, Amount__c, RowNo__c, refAccountMaster__c, refAccountMaster__r.Name, TaxRate__c, ServiceRate__c, SpecialTax__c, UnitPrice__c, UseDate__c, refBooking__r.EntryTime__c, refBooking__r.Departure__c, InvoiceNoShowFlg__c, NoShowRequestFlg__c, GoukeinoneTax__c, SpTotal__c, ProductName__c, PlanDetailSyncInfo__c, QuotaRef__r.Id, refAccountMaster__r.PaymentType__c, ParentBookingItemRef__c, UnitPriceDefKbCal__c,PaymentType__c,X2_1__c,PlanBrkInfo__c ' 
								// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
								+ ',OptionNo__c'
								// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
								// 2019/07/30 軽減税率機能対応 WGCH BEGIN
								+ ',TankanonetaxNew__c '
								+ ' from QuotaItem__c where ParentBookingItemRef__c = null and QuotaRef__c =: quotaOrTemplateId ';
								// 2019/07/30 軽減税率機能対応 WGCH END
			queryStr += ' Order By RowNo__c, Name ';
			quotaParItemLst = DataBase.query(queryStr);
			setPlanAmountMap(quotaParItemLst);
		}
		// 2019/07/30 軽減税率機能対応 WGCH END
		// 2018/10/24 見積明細自動計算機能対応 WGCH BEGIN
		HotelTaxDefineInfo hotelInfo = new HotelTaxDefineInfo();
		Map<String, Decimal> pdTaxMap = new Map<String, Decimal>();
		Map<String, String> prodTpyeMap = new Map<String, String>();
		for (QuotaItem__c obj : quotaParItemLst) {
			if(obj.ActionType__c == CommConst.PROD_ACTION_TYPE_PL && !CommUtils.isBlank(obj.PlanDetailSyncInfo__c)){ // 該当プランに所属する設定情報が存在する場合
				// １明細の商品IDと数量格納する
    			String planSynInfo = obj.PlanDetailSyncInfo__c.substringBeforeLast(';');
    			String[] prodInfoLst = planSynInfo.split(';');
    			for (Integer i = 0; i < prodInfoLst.size(); i++) {
    				String[] prodItem = prodInfoLst[i].split(':');
    				if (prodItem.size() > 2) {
    					pdTaxMap.put(prodItem[0], null);
    					prodTpyeMap.put(prodItem[2], null);
    				}
    			}
			}
		}
		for(PlanDetail__c pd : [select Id, TaxRate__c from PlanDetail__c where Id in : pdTaxMap.keySet()]) {
			pdTaxMap.put(pd.Id, pd.TaxRate__c);
		}
		for(AccountMaster__c accMst : [select Id, ActionType__c from AccountMaster__c where Id in : prodTpyeMap.keySet()]) {
			prodTpyeMap.put(accMst.Id, accMst.ActionType__c);
		}
		// 2018/10/24 見積明細自動計算機能対応 WGCH END
		// 2019/04/30 多見積明細设定BUG修正 WGCH BEGIN
		Set<String> pIdSet = new Set<String>();
		// 2019/04/30 多見積明細设定BUG修正 WGCH END
		//从見積把明细拷贝到予约見積明细、字段赋值
		for (QuotaItem__c obj: quotaParItemLst) {
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			if(isReducedTaxFlg && obj.ParentBookingItemRef__c != null) continue;
			// 2019/07/30 軽減税率機能対応 WGCH END
			BookingEstimateItem__c item = new BookingEstimateItem__c();
			//if (!itemLst.isEmpty() && curIdx < itemLst.size()) item = new BookingEstimateItem__c(id=itemLst[curIdx]);
			item.UnitPrice__c = CommUtils.nullToZero(obj.UnitPrice__c);
			//item.refBooking__c = obj.refBooking__c;
			item.ProductName__c = CommUtils.isBlank(obj.ProductName__c) ? obj.refAccountMaster__r.Name : obj.ProductName__c;
			item.refAccountMaster__c = obj.refAccountMaster__c;
			item.Amount__c = obj.Amount__c;
			item.SpecialTax__c = obj.SpecialTax__c;
			if (isCopyUserDate && obj.UseDate__c != null) item.UseDate__c = obj.UseDate__c;
			else item.UseDate__c = leasSobj.EntryTime__c.date();
			item.TaxRate__c = obj.TaxRate__c;
			item.ServiceRate__c = obj.ServiceRate__c;
			item.ActionType__c = obj.ActionType__c;
			if(item.ActionType__c == CommConst.PROD_ACTION_TYPE_PL){
				item.PlanDetailSyncInfo__c = obj.PlanDetailSyncInfo__c;
				// 2019/07/30 軽減税率機能対応 WGCH BEGIN
				item.PlanBrkInfo__c = obj.PlanBrkInfo__c;
				item.TankanonetaxNew__c = obj.TankanonetaxNew__c;
				// 2019/07/30 軽減税率機能対応 WGCH END
				// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
				item.OptionNo__c = obj.OptionNo__c;
				// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
			}
			// 2017/12/13 見積明細非表示機能対応 WGCH BEGIN
			item.NoShowRequestFlg__c = obj.NoShowRequestFlg__c;
			item.InvoiceNoShowFlg__c = obj.InvoiceNoShowFlg__c;
			// 2017/12/13 見積明細非表示機能対応 WGCH END
			// 2018/10/24 見積明細自動計算機能対応 WGCH BEGIN
			// UnitPriceDefKbCal__c
			item.UnitPriceDefKb__c = obj.UnitPriceDefKbCal__c;
			item.recalculateFormulas();
			item.PaymentType__c = obj.PaymentType__c;
			// 2018/10/24 見積明細自動計算機能対応 WGCH END
			item.X2_1__c = obj.X2_1__c;
			BookEstItem estItem = new BookEstItem(item, oBookEstLst.size());
			estItem.amoutExcTax = obj.GoukeinoneTax__c;
			estItem.amoutIncTax = obj.SpTotal__c;
			estItem.quotaItemId = obj.id;
			// 2018/10/24 見積明細自動計算機能対応 WGCH BEGIN
			if(obj.ActionType__c == CommConst.PROD_ACTION_TYPE_PL && !CommUtils.isBlank(obj.PlanDetailSyncInfo__c)){ // 該当プランに所属する設定情報が存在する場合
				// １明細の商品IDと数量格納する
				String planSynInfo = obj.PlanDetailSyncInfo__c.substringBeforeLast(';');
				String[] prodInfoLst = planSynInfo.split(';');
				for (Integer i = 0; i < prodInfoLst.size(); i++) {
					String[] prodItem = prodInfoLst[i].split(':');
					if (prodItem.size() > 2) {
						String planDetailId = prodItem[0]; // plan明细ID
						Decimal planItemPrice =  CommUtils.nullToZero(prodItem[1]); // plan明细单价金额
						String productId = prodItem[2];
						// 非课税处理
						if( pdTaxMap.containsKey(planDetailId) && (pdTaxMap.get(planDetailId) == null || pdTaxMap.get(planDetailId) == 0)) estItem.initPlanInfo += planItemPrice; // plan明细单价金额
						// 室料商品处理
						if(prodTpyeMap.containsKey(productId) && prodTpyeMap.get(productId) == CommUtils.escStr(CommConst.PROD_ACTION_TYPE_RP)){
							if(!hotelInfo.planItemPriceMap.containsKey(obj.Id)) hotelInfo.planItemPriceMap.put(obj.Id, new List<Decimal>());
							// 明细 -> 単価(税込)
							hotelInfo.planItemPriceMap.get(obj.Id).add(planItemPrice);
						}
					}
				}
			}
			// 2018/10/24 見積明細自動計算機能対応 WGCH END
			// 2019/04/30 多見積明細设定BUG修正 WGCH BEGIN
			if(!hotelInfo.hotelTaxDefInstance.isEmpty() && obj.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) pIdSet.add(obj.Id);
			// 2019/04/30 多見積明細设定BUG修正 WGCH END
			// 2017/12/11 見積明細金額合計機能追加　by　zy BEGIN
			if(obj.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) estItem.isPlanProduct = true;
			if (item.ActionType__c == CommConst.PROD_ACTION_TYPE_PY || item.ActionType__c == CommConst.PROD_ACTION_TYPE_AR) totalInc -= item.SpTotal__c;
			else totalInc += item.SpTotal__c;
			// 2017/12/11 見積明細金額合計機能追加　by　zy END
			//把从見積拷贝的明细放到list中
			oBookEstLst.add(estItem);
		}
		// 2018/10/24 見積明細自動計算機能対応 WGCH BEGIN
		hotelInfoJson = JSON.serialize(hotelInfo);
		// 2018/10/24 見積明細自動計算機能対応 WGCH END
		// 2019/04/30 多見積明細设定BUG修正 WGCH BEGIN
		setHotelInfoJson(pIdSet, hotelInfo);
		// 2019/04/30 多見積明細设定BUG修正 WGCH END
		totalAmount = CommUtils.nullToZero(totalInc);
		Integer appendRsSize = LIST_INPUT_DEF_ROWS - Math.Mod(oBookEstLst.size(), LIST_INPUT_DEF_ROWS);
        // 2017/01/16 统一行追加功能改修 by wsq END
        // 2行目まで設定を行う
        for (Integer i = 0; i < appendRsSize; i++) {
            oBookEstLst.add(new BookEstItem(new BookingEstimateItem__c(refBooking__c = leadId),oBookEstLst.size()));
        }
        // 页面控制设定
        // 置空多見積
        chkInfo.autoMoreFlag = false;
        //　ボタン表示
		chkInfo.betuFlag = false;
	}
	// 最新情報対応　全て予約
	private void refreshBookEstItemInfos(List<String> subIds){
		//　見積明細作成
		createItemByLeadLst(subIds);
        Integer appendRsSize = LIST_INPUT_DEF_ROWS - Math.Mod(oBookEstLst.size(), LIST_INPUT_DEF_ROWS);
        // 2行目まで設定を行う
        for (Integer i = 0; i < appendRsSize; i++) {
            oBookEstLst.add(new BookEstItem(new BookingEstimateItem__c(),oBookEstLst.size()));
        }
	}
	// 全て予約の見積明細作成する
	private void createItemByLeadLst(List<String> leadIds) {
		oBookEstLst = new List<BookEstItem>();
		List<String> maxQueryLimit = new List<String>();
		List<String> minQueryLimit = new List<String>();
		Date maxDate = leasSobj.Departure__c.date();
		Date minDate = leasSobj.entryTime__c.date();
		String minLeadId = leadId;
		String maxLeadId = leadId;
		Decimal totalInc = 0;
		//同じ予約
		List<Lead__c> leads = [select id, Name,Rroom__c,UnitPriceDefKbCal__c,Relcontact__c,
				StayPersons__c,EntryTime__c,Departure__c,Field4__c,Field3__c,Comment3__c
			from Lead__c 
			where LeadIndexRef__c = :leasSobj.LeadIndexRef__c 
			And LeadIndexSubId__c = :leasSobj.LeadIndexSubId__c
			And RoomGroupNo__c = :leasSobj.RoomGroupNo__c
			And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 
			Order By EntryTime__c ] ;
		for (lead__c lead : leads) {
			if (maxDate < lead.Departure__c.date()) {
				maxDate = lead.Departure__c.date();
				maxLeadId = lead.id;
			}		
			if (minDate > lead.EntryTime__c.date()) {
				minDate = lead.EntryTime__c.date();
				minLeadId = lead.id;
			}
		}
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		List<BookingEstimateItem__c> existBookEstLst = new List<BookingEstimateItem__c>();
		if(!isReducedTaxFlg){
			existBookEstLst = [select id, name, refBooking__c, ActionType__c,Amount__c,RowNo__c,
				refAccountMaster__c, refAccountMaster__r.Name, TaxRate__c, ServiceRate__c,SpecialTax__c,UnitPrice__c,
				// 2016/12/08 見積明細利用日機能対応 BEGIN zyz
				UseDate__c,refBooking__r.EntryTime__c,refBooking__r.Departure__c,
				// 2016/12/08 見積明細利用日機能対応 END zyz
				GoukeinoneTax__c, SpTotal__c, ProductName__c, PlanDetailSyncInfo__c
				// 2017/12/13 見積明細非表示機能対応 WGCH BEGIN
				,InvoiceNoShowFlg__c, NoShowRequestFlg__c
				// 2017/12/13 見積明細非表示機能対応 WGCH END
				// 2018/10/24 見積明細自動計算機能対応 WGCH BEGIN
				,UnitPriceDefKb__c
				,UnitPriceDefKbCal__c
				,PaymentType__c
				,(Select UnitPrice__c, TaxRate__c From ParentBookingItemRef__r where (TaxRate__c = null OR TaxRate__c = 0) And ParentBookingItemRef__r.ActionType__c =: CommConst.PROD_ACTION_TYPE_PL)
				// 2018/10/24 見積明細自動計算機能対応 WGCH END
				,PlanBrkInfo__c
				// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
				,OptionNo__c
				// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
				// 2017/12/29 显示顺调整 by zy BEGIN
				from BookingEstimateItem__c where refBooking__c = :leadIds and ParentBookingItemRef__c = null Order By refBooking__c,UseDate__c,RowNo__c,Name];	
				// 2017/12/29 显示顺调整 by zy END
		} else {
			// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
			// String queryStr = ' select id, name, refBooking__c, ActionType__c, Amount__c, RowNo__c, refAccountMaster__c, refAccountMaster__r.Name, TaxRate__c, ServiceRate__c, SpecialTax__c, UnitPrice__c, UseDate__c, refBooking__r.EntryTime__c, refBooking__r.Departure__c, GoukeinoneTax__c, SpTotal__c, ProductName__c, PlanDetailSyncInfo__c, InvoiceNoShowFlg__c, NoShowRequestFlg__c, refAccountMaster__r.PaymentType__c, ParentBookingItemRef__c,TankanonetaxNew__c, UnitPriceDefKbCal__c, PaymentType__c, PlanBrkInfo__c from BookingEstimateItem__c where refBooking__c = :leadIds ';
			String queryStr = ' select id, name, refBooking__c, ActionType__c, Amount__c, RowNo__c, refAccountMaster__c, refAccountMaster__r.Name, TaxRate__c, ServiceRate__c, SpecialTax__c, UnitPrice__c, UseDate__c, refBooking__r.EntryTime__c, refBooking__r.Departure__c, GoukeinoneTax__c, SpTotal__c, ProductName__c, PlanDetailSyncInfo__c, InvoiceNoShowFlg__c, NoShowRequestFlg__c, refAccountMaster__r.PaymentType__c, ParentBookingItemRef__c,TankanonetaxNew__c, UnitPriceDefKbCal__c, PaymentType__c, PlanBrkInfo__c, OptionNo__c from BookingEstimateItem__c where refBooking__c = :leadIds ';
			// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
			if(!isReducedTaxFlg) queryStr += ' and ParentBookingItemRef__c = null ';
			queryStr += ' Order By refBooking__c, UseDate__c, RowNo__c, Name ';
			existBookEstLst = DataBase.query(queryStr);
			setPlanAmountMap(existBookEstLst);
		}
		// 2019/07/30 軽減税率機能対応 WGCH END
		// 2018/10/24 見積明細自動計算機能対応 WGCH BEGIN
		// 2018/07/27 宿泊税計算 WGCH BEGIN
		HotelTaxDefineInfo hotelInfo = new HotelTaxDefineInfo();
		Set<String> pIdSet = new Set<String>();
		// 2018/07/27 宿泊税計算 WGCH END
		// 2018/10/24 見積明細自動計算機能対応 WGCH END
		for (BookingEstimateItem__c sobj: existBookEstLst) {
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			if(sobj.ParentBookingItemRef__c != null) continue;
			// 2019/07/30 軽減税率機能対応 WGCH END
			// 2018/10/24 見積明細自動計算機能対応 WGCH BEGIN
			// 2018/07/27 宿泊税計算 WGCH BEGIN
			if(!hotelInfo.hotelTaxDefInstance.isEmpty() && sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) pIdSet.add(sobj.Id);
			// 2018/07/27 宿泊税計算 WGCH END
			// 2018/10/24 見積明細自動計算機能対応 WGCH END
			BookEstItem item = new BookEstItem(sobj, oBookEstLst.size());
			if ( sobj.UseDate__c != null ) {
				if (minDate > sobj.UseDate__c) {
					minQueryLimit.add(item.productNm + item.rowNo);
				}else if (maxDate < sobj.UseDate__c) {
					maxQueryLimit.add(item.productNm + item.rowNo);
				}
			}
			if (sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PY || sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_AR) totalInc -= sobj.SpTotal__c;
			else totalInc += sobj.SpTotal__c;
			oBookEstLst.add(item);
		}
		// 2018/10/24 見積明細自動計算機能対応 WGCH BEGIN
		setHotelInfoJson(pIdSet, hotelInfo);
		// 2018/10/24 見積明細自動計算機能対応 WGCH END
		totalAmount = CommUtils.nullToZero(totalInc);
		//String warMsg = '';
		if (!maxQueryLimit.isEmpty()) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.MSG_011_0082));
    	if (!minQueryLimit.isEmpty()) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.MSG_011_0083));
    	//if (!CommUtils.isBlank(warMsg)) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, warMsg));
	}
	//見積作成する
	private void updateQuota(List<Id> leadIdLst){
		// 更新quota明细
		//upsertQuotaItems();
		// 更新予約下全て見積状態
		refreshAllQuotaStatus();
	}
	// 更新見積状態、該当の見積は予約済み
	private void refreshAllQuotaStatus() {
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'quotastatus__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.Quota__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
			return ;
		}
		// 2019/09/15 Security Check BY zyz END
		//更新見積状態
		List<Quota__c> chgLst = new List<Quota__c>();
		// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
		// for (Quota__c quota : [select id, name, LeadRef__c,QuotaStatus__c, MainQuotaFlg__c, ExpirationDate__c, QuotaDescription__c, QuotaName__c,CreatedBy.Name,CreatedById,CreatedDate from Quota__c where LeadRef__c = :leasSobj.id]) {
		for (Quota__c quota : [select id, name, LeadRef__c,QuotaStatus__c, MainQuotaFlg__c, ExpirationDate__c, QuotaDescription__c, QuotaName__c,CreatedBy.Name,CreatedById,CreatedDate,RespectLst__c from Quota__c where LeadRef__c = :leasSobj.id]) {
		// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
			if (quota.QuotaStatus__c == QUOTA_STATUS_FORMAL && quota.id != quotaOrTemplateId) {
				quota.QuotaStatus__c = QUOTA_STATUS_KARI;
				//chgLst.add(quota);
			} else if (quota.id == quotaOrTemplateId) {
				quota.QuotaStatus__c = QUOTA_STATUS_FORMAL;
				// 見積書宛名メッセージ設定
				/*
				quota.QuotationComment__c = leasSobj.QuotationComment__c;
				quota.LeadReceiptDate__c = leasSobj.LeadReceiptDate__c;
				quota.StampIsShowDiv__c = leasSobj.StampIsShowDiv__c;
				quota.QuotationName__c = leasSobj.QuotationName__c;
				*/
				chgLst.add(quota);
				quotaInf = quota;
			}
		}
		if (!chgLst.isEmpty()) update chgLst;
		//quotaOrTemplateId = null;
	}
	public class ChkInfo{
		// 新見積フラグ
		public boolean newMitumoriFlag{get;set;}
		// 見積モードフラグ
		public boolean mitumoriFlag{get;set;}
		// 別保存フラグ true:保存、false:別保存
		public boolean betuFlag{get;set;}
		// 自動作成フラグ
		public boolean autoMoreFlag{get;set;}
		public ChkInfo(){
			newMitumoriFlag = false;
			mitumoriFlag = false;
			betuFlag = false;
			autoMoreFlag = false;
		}
	}
	// 页面之间，用于前台js刷新行信息
	public class QuotaJson {
		String id;
		String name;
		String status;
		String quotaName;
		String quoDesc;
		String quoDate;
		String createBy;
		String createDate;
		String createById;
		// 2017/12/11 見積明細金額合計機能追加　by　zy BEGIN
		Decimal quoTotal;
		// 2017/12/11 見積明細金額合計機能追加　by　zy END
		public QuotaJson(Quota__c q) {
			id = q.id;
			name = CommUtils.nullToBlank(q.name);
			quotaName = CommUtils.nullToBlank(q.QuotaName__c);
			status = CommUtils.nullToBlank(q.QuotaStatus__c);
			quoDesc = CommUtils.nullToBlank(q.QuotaDescription__c);
			if (q.ExpirationDate__c != null ) quoDate = q.ExpirationDate__c.format();
			else quoDate = '';
			createBy = CommUtils.nullToBlank(q.LastModifiedBy.Name);
			createById = CommUtils.nullToBlank(q.LastModifiedById);
			if (q.LastModifiedDate != null) createDate = q.LastModifiedDate.format(CommBaseCtrl.getDateTimeFormat());
			// 2017/12/11 見積明細金額合計機能追加　by　zy BEGIN
			quoTotal = CommUtils.nullToZero(q.TotalInc__c);
			// 2017/12/11 見積明細金額合計機能追加　by　zy END
		}
	}
	// 2017/11/21参照見積関連追加　by　zy END
	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
	private void setPlanAmountMap(List<BookingEstimateItem__c> existBookEstLst) {
		planBrkInfoMap = new Map<String, List<PlanBrkInfo>>();
		for (BookingEstimateItem__c sobj : existBookEstLst) {
			if(sobj.ParentBookingItemRef__c != null){
				// PlanBrkDn 的信息Key[也就是主的Id]
				String key = sobj.ParentBookingItemRef__c;
				if(!planBrkInfoMap.containsKey(key)) planBrkInfoMap.put(key, new List<PlanBrkInfo>());
				planBrkInfoMap.get(key).add(setPlanBrkInfo(sobj));
			}
		}
		planBrkInfoMapJson = JSON.serialize(planBrkInfoMap);
	}
	private void setPlanAmountMap(List<QuotaItem__c> quotaItemLst) {
		planBrkInfoMap = new Map<String, List<PlanBrkInfo>>();
		for (QuotaItem__c sobj : quotaItemLst) {
			if(!CommUtils.isBlank(sobj.PlanBrkInfo__c)){
				// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
				Integer idx = 0;
				String[] prods = sobj.PlanDetailSyncInfo__c.split(';');
				// plan明细ID
				List<String> planBrkIdLst = new List<String>();
				for (integer i = 0 ; i < prods.size() ; i++) {
					String message = prods[i];
					if (CommUtils.isBlank(message)) continue;
					planBrkIdLst.add(message.subStringBefore(':'));
				}
				// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
				// PlanBrkDn 的信息Key[也就是主的Id]
				String key = sobj.Id;
				if(!planBrkInfoMap.containsKey(key)) planBrkInfoMap.put(key, new List<PlanBrkInfo>());
				List<List<String>> brkInfoAllLst = CommLogicProcess.getPlanBrkInfoLst(CommUtils.nullToBlank(sobj.PlanBrkInfo__c));
				for(List<String> brkInfoLst : brkInfoAllLst){
					if(brkInfoLst.size() < 8) continue;
					PlanBrkInfo item = new PlanBrkInfo();
					item.unitPrice = CommUtils.nullToZero(brkInfoLst[0]);
					item.tax = CommUtils.nullToZero(brkInfoLst[1]);
					item.serviceRate = CommUtils.nullToZero(brkInfoLst[2]);
					item.nums = CommUtils.nullToZero(brkInfoLst[3]);
					item.specialTax = CommUtils.nullToZero(brkInfoLst[4]);
					item.unitPriceKbn = CommUtils.nullToBlank(brkInfoLst[5]);
					item.productId = CommUtils.nullToBlank(brkInfoLst[6]);
					item.actionType = CommUtils.nullToBlank(brkInfoLst[7]);
					// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
					item.pdId = idx < planBrkIdLst.size() ? CommUtils.nullToBlank(planBrkIdLst[idx]) : '';
					item.prodcutName = CommUtils.isBlank(sobj.ProductName__c) ? sobj.refAccountMaster__r.Name : sobj.ProductName__c;
					idx++;
					// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
					planBrkInfoMap.get(key).add(item);
				}
			}
		}
		planBrkInfoMapJson = JSON.serialize(planBrkInfoMap);
	}
    // PlanBrkDn数据合计
    public Map<String, List<PlanBrkInfo>> planBrkInfoMap{get; set;}
    public String planBrkInfoMapJson{get{ if(planBrkInfoMapJson == null) planBrkInfoMapJson = '{}'; return planBrkInfoMapJson;} set;}
    private PlanBrkInfo setPlanBrkInfo(BookingEstimateItem__c sobj){
    	PlanBrkInfo item = new PlanBrkInfo();
    	item.unitPrice = CommUtils.nullToZero(sobj.UnitPrice__c);
    	item.tax = CommUtils.nullToZero(sobj.TaxRate__c);
    	item.serviceRate = CommUtils.nullToZero(sobj.ServiceRate__c);
    	item.nums = CommUtils.nullToZero(sobj.Amount__c);
    	item.specialTax = CommUtils.nullToZero(sobj.SpecialTax__c);
    	item.unitPriceKbn = CommUtils.nullToBlank(sobj.UnitPriceDefKbCal__c);
    	item.productId = CommUtils.nullToBlank(sobj.refAccountMaster__c);
    	item.actionType = CommUtils.nullToBlank(sobj.ActionType__c);
    	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
    	item.pdId = CommUtils.nullToBlank(sobj.Id);
    	item.prodcutName = CommUtils.nullToBlank(sobj.ProductName__c);
    	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
    	return item;
	}
    public class PlanBrkInfo{
    	public PlanBrkInfo(){
    		unitPrice = tax = serviceRate = nums = specialTax = 0;
    		unitPriceKbn = productId = actionType = '';
    		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
    		pdId = prodcutName = '';
    		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
    	}
    	public Decimal unitPrice{get;set;}
    	public Decimal tax{get;set;}
    	public Decimal serviceRate{get;set;}
    	public Decimal nums{get;set;}
    	public Decimal specialTax{get;set;}
    	public String unitPriceKbn{get;set;}
    	public String productId{get;set;}
    	public String actionType{get;set;}
    	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
    	public String pdId{get;set;}
    	public String prodcutName{get;set;}
    	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
    }
    // 軽減税率Flg
    public Boolean isReducedTaxFlg{get{ return CommConst.REDUCED_TAXRATE_FLG;} set;}
    // 小数部分桁数取得する
    private static final Integer gPointLen = CommUtils.getPointLen();
    // 2019/07/30 軽減税率機能対応 WGCH END
	// 2018/06/25 複数見積で見積修正したデータが残りたい by zy BEGIN
    public boolean isAutoSaveFlag{get {return CommDefine__c.getOrgDefaults().EstIsCanEditFlg__c == null ? false : CommDefine__c.getOrgDefaults().EstIsCanEditFlg__c;}set;}
	// 2018/06/25 複数見積で見積修正したデータが残りたい by zy END
	// 2018/10/25 常に新規保存になってしまい、見積もりがいくつも作成されてしまいます。 by cxw BEGIN
	public void updateCurQuota(){
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'stampisshowdiv__c','quotationname__c','quotationcomment__c','quotastatus__c','leadreceiptdate__c','leadpdfshopcode__c',
													'language__c','billsaveflg__c','accountreceiptname__c','accountproviso__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.Quota__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
			return ;
		}
		// 2019/09/15 Security Check BY zyz END
		// 見積書宛名メッセージ設定
		quotaInf.QuotationComment__c = leasSobj.QuotationComment__c;
		quotaInf.LeadReceiptDate__c = leasSobj.LeadReceiptDate__c;
		quotaInf.StampIsShowDiv__c = leasSobj.StampIsShowDiv__c;
		quotaInf.QuotationName__c = leasSobj.QuotationName__c;
		quotaInf.Language__c = leasSobj.Language__c;
		quotaInf.LeadPdfShopCode__c = leasSobj.LeadPdfShopCode__c;
		quotaInf.QuotaStatus__c = QUOTA_STATUS_KARI;
		// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
		quotaInf.RespectLst__c = leasSobj.RespectLst__c;
		// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
		// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH BEGIN
		if(billRcptIsShowFlg){
			quotaInf.BillSaveFlg__c = true;
			quotaInf.AccountReceiptName__c = leasSobj.AccountReceiptName__c;
			quotaInf.AccountProviso__c = leasSobj.AccountProviso__c;
		}
		// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH END
		if (!CommUtils.isBlank(quotaInf.id)) update quotaInf; 
		
		// 画面見積明細更新
		upsertQuotaItems();
		// 刷新見積情報
		refreshQuotaInfo(quotaOrTemplateId);
		// 画面内容更新
		refreshQuotaItems();
	}
	private static String leadPrefix = Lead__c.sObjectType.getDescribe().getKeyPrefix();
	// 2018/10/25 常に新規保存になってしまい、見積もりがいくつも作成されてしまいます。 by cxw END
	// 2019/04/30 増税仮対応 WGCH BEGIN
	// 增税商品json数据 
	public String taxIncMstItemJson{get	{ return CommLogicProcess.getTaxIncMstJson();} private set;}
	// 2019/04/30 増税仮対応 WGCH END
	// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
	public static boolean planBrkToHeaderCalFlg{get{ return CommConst.PLAN_BRKTOHEADER_CAL_FLG;} private set;}
	// 2019/10/02 PlanHeader算法切换对应 WGCH END
	// 2020/08/30 複数のプランとそれぞれのプランの人数を選択し機能対応 zyz BEGIN
	// 功能开关
	public Boolean isBasePlanFlag{get;set;}
	// 行追加处理使用
	public Integer addRowsMan{get;set;}
	// baseplan使用的日期
	public String basePlanDate{get; private set;}
	private void baseplanSwitch(String spcd){
		isBasePlanFlag = false;
        Boolean oldVersionFlag = false;
        Integer showVersion = CommConst.APPOTION_NEWBOOKING_VER;
        oldVersionFlag = (showVersion != 2);
        // 拡張予約項目を定義する
        String xmlName = (oldVersionFlag ? 'RoomTypeInventoryLeadInputExtendFieldsXml' : 'RoomTypeInventoryLeadInputExtendFieldsXml_V2');
        try{
       		Dom.XMLNode targetNode = CommXmlUtils.parseXmlDoc(xmlName,spcd);
        	if (targetNode != null) {
	            //プラン明細フラグ
	            Dom.XmlNode mitumoriNode =  targetNode.getChildElement('MITUMORIFLAG', null);
	            if(mitumoriNode != null) {
	                String mitumoriContent = mitumoriNode.getText();
	                Boolean isPlanDetailFlag = boolean.valueOf(mitumoriContent);
	                if (isPlanDetailFlag) {
	                    isBasePlanFlag = boolean.valueOf(CommUtils.nullToBlank(mitumoriNode.getAttribute('BASEPLANFLAG',null)));
	                }
	            }
        	}
	    }catch(Exception e){}
	}
	// 2020/08/30 複数のプランとそれぞれのプランの人数を選択し機能対応 zyz END
}