/**
* ご予約情報により、請求書作成機能対応
* 2019/02/28 請求書宛名の『様』の表示改善対応
* 2019/04/30 請求書の送付表新規作成
* 2019/04/30 増税仮対応
* 2019/06/15 請求書の振込先欄を5つにして機能対応
* 2019/06/30 ご予約内の請求書ボタンのUIに作成
* 2019/06/30 請求書送付状の宛名複数選択表示機能
* 2019/07/30 軽減税率機能対応
* 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応
* 2020/01/30 宛名が一定文字数を超えた場合に自動改行する
**/
public with sharing class LeadBillPDFCtrl {

	// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH BEGIN
	// 売り掛け分の金額を領収書金額からマイナスした対応について、共通定義にマイナスする／しないのパラメータ
	private Boolean isManasAccountMoneyFlg = ( CommDefine__c.getOrgDefaults().AccountMoneyManasFlg__c == null ? false : CommDefine__c.getOrgDefaults().AccountMoneyManasFlg__c);
	// 領収書利用金額設定
	// 領収書利用金額：お客様消費総金額 - 割引 - ポイント及びクーポン　- 売掛金の金額　+　特別税合計
	public Decimal getReceipt() {
		if (!isManasAccountMoneyFlg) {
			// 2019/04/30 増税仮対応 - 請求金額に特別税合計金額を含めないbug対応  BY zyz BEGIN
			Decimal wkReceipt = (CommUtils.nullToZero(amoutAllMoney) - CommUtils.nullToZero(amountAllDiscount) - CommUtils.nullToZero(amoutAllCoupon) + CommUtils.nullToZero(amoutIncSpecialPrice));
			// 2019/04/30 増税仮対応 - 請求金額に特別税合計金額を含めないbug対応  BY zyz BEGIN
			if(wkReceipt <= 0) return 0;
			return wkReceipt;
		} else {
			// 2019/04/30 増税仮対応 - 請求金額に特別税合計金額を含めないbug対応  BY zyz BEGIN
			Decimal wkReceipt = (CommUtils.nullToZero(amoutAllMoney) - CommUtils.nullToZero(amountAllDiscount) - CommUtils.nullToZero(amoutAllCoupon) - CommUtils.nullToZero(amoutAllMultiply) + CommUtils.nullToZero(amoutIncSpecialPrice));
			// 2019/04/30 増税仮対応 - 請求金額に特別税合計金額を含めないbug対応  BY zyz END
			if(wkReceipt <= 0) return 0;
			return wkReceipt;
	 	}
	}
	// 領収書金額から計算の内税金額を出力する
	public Decimal getReceiptTax() {
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
    	/**
    	** 領収証-金額:getReceipt()
    	** ご利用金額(税込):getCharge()
    	** 内税:getTax()
    	**/
    	if(isReducedTaxFlg){
    		// 2019/10/18 領収証内税修正 WGCH BEGIN
    		// return sumRowData.taxAmount
    		// クーポン
    		Decimal paymented = CommUtils.nullToZero(amoutAllCoupon);
    		// 掛計
    		if (isManasAccountMoneyFlg) paymented += CommUtils.nullToZero(amoutAllMultiply);
    		// 2020/03/30 BUGFIX WGCH BEGIN
    		// Decimal ratio = (sumRowData.amountExcTax + sumRowData.taxAmount) == 0 ? 0 : (paymented / (sumRowData.amountExcTax + sumRowData.taxAmount));
			// return CommUtils.RoundProcess(((1 - ratio) * sumRowData.taxAmount), gPointLen);
			paymented += CommUtils.nullToZero(amountAllDiscount);
			Decimal recpiptAmount = sumRowData.priceAmountSum - paymented;
			if(recpiptAmount <= 0) return 0;
			Decimal ratio = (sumRowData.amountExcTax + sumRowData.taxAmount) == 0 ? 0 : (paymented / (sumRowData.priceAmountSum));
			Decimal taxAmount = 0;
			for(CommLogicProcess.TaxRowData taxRow : taxRowDataLst){
				taxAmount += taxRow.taxAmount;
			}
			return CommUtils.RoundProcess(((1 - ratio) * taxAmount), gPointLen);
			// 2020/03/30 BUGFIX WGCH END
    		// 2019/10/18 領収証内税修正 WGCH END
    	} else {
			// 2019/04/30 増税仮対応 BY zyz BEGIN
			// Decimal recpiptAmount = getReceipt();
			Decimal recpiptAmount = 0;
	        if (!isManasAccountMoneyFlg) {
	            recpiptAmount = (CommUtils.nullToZero(amoutIncTaxprice) - CommUtils.nullToZero(amountAllDiscount) - CommUtils.nullToZero(amoutAllCoupon));
	        } else {
	            recpiptAmount = (CommUtils.nullToZero(amoutIncTaxprice) - CommUtils.nullToZero(amountAllDiscount) - CommUtils.nullToZero(amoutAllCoupon) - CommUtils.nullToZero(amoutAllMultiply));
	        }
	        if (recpiptAmount <= 0) return 0;
			// 2019/04/30 増税仮対応 BY zyz END
			// 2019/10/11 サービス料を含む商品を予約見積明細の請求書の消費税が正しい金額になっておりませんの不具合対応 BY zyz BEGIN
			// Decimal taxRate = CommUtils.nullToZero(account[0].TaxRate__c);
			Decimal taxRate = 0;
			// 2019/10/11 サービス料を含む商品を予約見積明細の請求書の消費税が正しい金額になっておりませんの不具合対応 BY zyz END
			// 会計に該当消費税が未設定する場合、会計に所属する会計明細から消費税率を取得する
			if(CommUtils.nullToZero(taxRate) == 0) {
				// 消費税率＞０　AND　BreakDown明細以外の会計明細を消費税率を取得する
				List<BookingEstimateItem__c> taxItems = [ select TaxRate__c from BookingEstimateItem__c
														where refBooking__c = :leadIds and Accountoutside__c = 1
														And ParentBookingItemRef__c = null
														// And InvoiceNoShowFlg__c = false
														And TaxRate__c > 0 limit 1];
				if (!taxItems.isEmpty()) taxRate = CommUtils.nullToZero(taxItems[0].TaxRate__c);
				// 2019/10/11 サービス料を含む商品を予約見積明細の請求書の消費税が正しい金額になっておりませんの不具合対応 BY zyz BEGIN
				else taxRate = CommUtils.nullToZero(account[0].TaxRate__c);
				// 2019/10/11 サービス料を含む商品を予約見積明細の請求書の消費税が正しい金額になっておりませんの不具合対応 BY zyz END
			}
			// 2014/07/18 為替レート変更機能対応（USD→JPY）[通貨変更表示する場合、日本の消費率で内消費税を計算する]
		 	if (exchangeRateFlg) {
				taxRate = CommUtils.nullToZero(singelAccount.ExchangeTaxRate__c) == 0
		 					? CommUtils.nullToZero(CommDefine__c.getOrgDefaults().ExchangeTaxRate__c)
							: CommUtils.nullToZero(singelAccount.ExchangeTaxRate__c);
			}
			// 2019/04/30 増税仮対応 BY zyz BEGIN
			// return CommUtils.RoundProcess(recpiptAmount / (1 + taxRate / 100) * (taxRate / 100), gPointLen);
			return CommUtils.RoundProcess(recpiptAmount / (1 + taxRate / 100) * (taxRate / 100) + taxIncMstTaxprice, gPointLen);
			// 2019/04/30 増税仮対応 BY zyz END
    	}
    	// 2019/07/30 軽減税率機能対応 WGCH END
	}
	public ReportLogo__c repInfo{get; private set;}
	public void setRepInfo (String pspcd) {
		ReportTitleCompCtrl rep = new ReportTitleCompCtrl();
		rep.billRTshopCd = pspcd;
		repInfo = rep.reportInfo;
	}
	public String getCurrencySybmol(){ return CommBaseCtrl.getCurrencySybmol();}
	// 領収書分割線LOOP制御変数
	public List<Integer> spliteLineLoop{get{return new List<Integer>{1,2,3,4,5,6,7,8,9,10};}}
	// 会計書文字サイズ大フラグ
	public Boolean isOldManModeFlg{get{ return (CommDefine__c.getOrgDefaults().AccountOldManModeFlg__c == null ? false : CommDefine__c.getOrgDefaults().AccountOldManModeFlg__c);}}
	public String proTaxEnglishLabel{get; private set;}	// 領収書内消費税英語表示文言;
	// 領収書出力する/しない制御追加と領収金額に内税金額を表示追加する
	public transient Boolean noreceipt{get{ return !CommConst.Bill_RCPTISSHOW_FLG;}}
	public transient Boolean accountHotelTaxIsShowFlg{get;private set;}
	private Map<String, List<Decimal>> pItemPriceMap = new Map<String, List<Decimal>>();
	// get 請求書の宛名先名
	public transient String accountName{get;private set;}
	// get 但し書き
	public transient String accountProviso{get;private set;}
	// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH END
	// 合計金額など集計用会計情報リスト
	private List<AccountAcount__c> account;
	private AccountAcount__c singelAccount;
	// 会計明細情報を格納する
	private List<TranItem> tran;
	// 課税対象商品の売上金額合計を格納する
	private Decimal amoutIncTaxprice = 0;
    // 2019/04/30 増税仮対応 BY zyz BEGIN
    private Decimal taxIncMstTaxprice = 0;
    // 2019/04/30 増税仮対応 BY zyz EDN
	// 特別税合計
	private Decimal amoutIncSpecialPrice = 0;
	//　返金金額
	private Decimal amountRefundPrice = 0;
	// 前受付金の金額合計を格納する
	private Decimal amoutARprice = 0;
	// 税込前金額合計を格納する
	private Decimal amoutAllMoney = 0;
	// 為替レート変換前の請求金額
	private Decimal allOrgRemaindPrice = 0;
	private Decimal allPlusPayAmount = 0;
	// 2017/05/31 請求書PDFについての(控)を出力制御対応 zyz BEGIN
	public transient List<Integer> printLoop{get;private set;}
	// 請求書PDFについての(控)を出力制御
	private Boolean isShowCopyInfFlg = ( CommDefine__c.getOrgDefaults().BillIsShowCopy__c == null ? true : CommDefine__c.getOrgDefaults().BillIsShowCopy__c);
	// 2017/05/31 請求書PDFについての(控)を出力制御対応 zyz END
    // 2018/12/15 請求書レイアウト改善 BY zyz BEGIN 
    public String subjectStr{get;set;} 		// title
    public String customizeHtml{get;set;} 	// 部分信息layout自定义
    public String payeeStr{get;set;} 		// お振込先 自定义
    public String titleStr{get;set;} 		// 様 自定义
    // 2018/12/15 請求書レイアウト改善 BY zyz END
	// 一ページに最大格納できる明細レコード数
	public final Integer PAGE_FIRSTPG_BREAK_RSNUM = 28;
	public final Integer PAGE_NEXTPG_BREAK_RSNUM = 42;
	// 1:初日の日付のレートで請求書に計算する　（Default値）
	private final Integer APPOPTION_EXCHANGE_RATE_ONE_DAY = 1;
	// 2:売上日別で為替レートマスタからレートを取得、請求額計算を行う
	private final Integer APPOPTION_EXCHANGE_RATE_EVERY_DAY = 2;
	//為替レート取得区分[]
	private final Integer EXCHANGE_RATE_QUERY = CommDefine__c.getInstance().ExchangeRateQueryDiv__c == null ? APPOPTION_EXCHANGE_RATE_ONE_DAY :Integer.valueOf(CommDefine__c.getInstance().ExchangeRateQueryDiv__c);
	// 小数部分桁数取得する
	private static final Integer gPointLen = CommUtils.getPointLen();
	// 支払メディア金額合計値を格納する
	// 現金
	private Decimal amoutAllCash = 0;			// 支払金額
	// 掛計
	private Decimal amoutAllMultiply = 0;		// 支払金額
	// クレジット
	private Decimal amoutAllCredit = 0;			// 支払金額
	// クーポン
	private Decimal amoutAllCoupon = 0;			// 支払金額
	// 割引
	private Decimal amountAllDiscount = 0;		// 支払金額
	// 予約金
	private Decimal amoutAllSubscription = 0;	// 支払金額
	// 前頁から引渡パラメータ情報を維持する変数
	private final Map<String,String> parMap;
	// 2012/10/17 ADD サービス料の項目と宿泊税の項目を表示切替フラグ
	// 2014/07/30 為替レートにより、外貨から日本円変換、計算する BEGIN
	// 通貨為替レート変更フラグ
	private boolean exchangeRateFlg = false;			// 外貨から日本円変換処理実施フラグ（TRUEの場合、外貨から日本円に変更する
	private Map<Date, Decimal> exchangeRateMap = null; 	// 為替レート期間範囲のレート情報を格納する
	private Integer pointlen{get; private set;}			// 小数桁数情報格納
	public String currencyMark{get; private set;}		// 通貨MARK($, ¥ etc)
	public String currencyUnit{get; private set;}   	// 通貨単位 (USD,JPY etc)
	public Boolean isForeignCurrency{get; private set;} // 外貨するがどうかチェックする
	public String taxEnglishLabel{get; private set;}	// 内消費税英語表示文言
	// 2019/04/30 請求書の送付表新規作成 BY zyz BEGIN
	public Boolean letterFlg{get;set;}
	// 2019/04/30 請求書の送付表新規作成 BY zyz END
	// 2014/07/30 為替レートにより、外貨から日本円変換、計算する End
	// 2019/06/30 請求書送付状の宛名複数選択表示機能 BY zyz BEGIN
	public String autoHtml{get;set;}					// 請求書送付状名输出显示
	public String autoStyle{get;set;}					// 請求書送付状显示的css设定
	// 2019/06/30 請求書送付状の宛名複数選択表示機能 BY zyz END
	// 2019/07/15 請求書の請求先名称の上部に請求先の住所を印字 BY zyz BEGIN
	public String autoAddHtml{get;set;}					// 請求書請求先の住所输出显示
	public String autoAddStyle{get;set;}				// 請求書請求先の住所显示的css设定
	private Integer longInt{get;set;}
	public Boolean autoAllFlg{get;set;}
	// 2019/07/15 請求書の請求先名称の上部に請求先の住所を印字 BY zyz END
	// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
    private Boolean isAccountProdNmReturnFlg{get{ return CommConst.ACCOUNT_PRODNM_FLG;}}
	private transient map<String,List<String>> proNameMap = new map<String, List<String>>();
	// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
    // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
    public static String mrStr{get;set;}
    public Boolean RespectFlg{get;set;}
    // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
	// 2015/01/26 ハンコ表示・非表示機能対応
	public Boolean stampIsShowFlg{get; private set;}
	// 2015/08/13 指定の店舗コードで請求書を表示機能対応
	public String shopCd {get; private set;}
	// 該当ページに引き渡す会計ID
	private Set<Id> accIdSet;
	// 2016/01/12 自動改行制御機能追加 BEGIN
	public Boolean isCommentAutoBreakFlg{get{return CommDefine__c.getOrgDefaults().BillReportCommentAutoBreakFlg__c;}}
	// 2016/01/12 自動改行制御機能追加 END
	// PDFページ毎の明細情報を格納用
	public List<OnePage> allPageList{get; private set;}
	public class OnePage {
		// startRsIndex：データ開始行目
		public OnePage () {
			onePageList = new List<TranItem>();
			currPages = 1;
		}
		// ページ内に追加するITEM
		public void addItem(TranItem item) {
			onePageList.add(item);
		}
		// 現在表示してページ数
		public Integer currPages{get;set;}
		public Boolean isFirstPage{get{
		  return currPages == 1;
		}}
		// １ページ表示用データを格納
		public List<TranItem> onePageList{get; private set;}
	}
	/**
	* 初期化処理を行う
	**/
	public LeadBillPDFCtrl(ApexPages.StandardController controller){
		// Data转换
		getEstInfoByLead(controller.getId());
		// 2018/12/30 防御修正 WGCH BEGIN
		// if(lead == null){
		if(lead == null || account.isEmpty()){
		// 2018/12/30 防御修正 WGCH END
			// は削除されました。
			Apexpages.addMessage(new Apexpages.Message(ApexPages.severity.ERROR, Label.MSG_011_0098));
			return;
		}
		// 2018/02/28 支払種別は「雑損」を作成したい WGCH BEGIN
		amoutCustomPayLst = new List<AmoutCustomPay>();
		// 2018/02/28 支払種別は「雑損」を作成したい WGCH END
		// 2017/05/31 請求書PDFについての(控)を出力制御対応 zyz BEGIN
		if (isShowCopyInfFlg) {
			printLoop = new List<Integer>{1,2};
		} else {
			printLoop = new List<Integer>{1};
		}
		// 2017/05/31 請求書PDFについての(控)を出力制御対応 zyz END
		// パラメータ情報を取得する
		parMap = ApexPages.currentPage().getParameters();
		// 2014/07/18 為替レート指定の場合（施設コードが 23/24 && パラメータから通貨を指定する場合、金額は変更を行う BEGIN
		// USER INFO
		String currencyInf = UserInfo.getDefaultCurrency();					// ログインユーザーの組織通貨を取得する
		String orgCurrency = currencyInf;									// ログインユーザーの組織通貨
		if (CommUtils.isBlank(currencyInf)) currencyInf = 'JPY';		// 組織通貨設定がNULLの場合、通貨JPY(日本円)に設定する
		// 請求書起動WindowからURLのパラメータが存在すると、外貨から日本円変換、表示処理FLGをTrueにする
		exchangeRateFlg = parMap.containsKey('cy'); // パラメータに存在設定する場合、以下の通貨から日本円に変更を行う（施設23/24のみパラメータ設定を行う)
		// TRUEの場合、元の通貨から日本円に変更を行う
		if (exchangeRateFlg) {
			currencyInf = 'JPY';	// JPY以外からJPY通貨変更の場合、表示の通貨はJPYに設定する
		}
		pointlen = CommUtils.getPointLen(currencyInf);	// 指定の通貨により、小数点桁数を取得する
		// 画面通貨のMARK設定する
		currencyMark = CommUtils.getCurrencyMark(currencyInf);
		currencyUnit = CommUtils.getCurrencyUnit(currencyInf);
		// 2018/06/08 レシート印刷機能言語選択する WGCH BEGIN
		// isForeignCurrency = CommUtils.isForeignCurrency(orgCurrency);		// ログインユーザーのログイン通貨により、レイアウト表示切替対応追加(Ver1.1.1)
		// 2019/06/30 ご予約内の請求書ボタンのUIに作成 BY zyz BEGIN
		// isForeignCurrency = CommUtils.isForeignCurrency(CommUtils.isBlank(lead.Language__c) ? orgCurrency : lead.Language__c);		// ログインユーザーのログイン通貨により、レイアウト表示切替対応追加(Ver1.1.1)
		if (parMap.containsKey('language')) isForeignCurrency = (parMap.get('language') != 'en' ? false : true);
		else isForeignCurrency = CommUtils.isForeignCurrency(CommUtils.isBlank(lead.Language__c) ? orgCurrency : lead.Language__c);
		// 2019/06/30 ご予約内の請求書ボタンのUIに作成 BY zyz END
		// 2018/06/08 レシート印刷機能言語選択する WGCH END
		// 2014/07/18 END
		// 2019/04/30 請求書の送付表新規作成 BY zyz BEGIN
		letterFlg = false;
		if (parMap.containsKey('letter')) letterFlg = true;
		// 2019/04/30 請求書の送付表新規作成 BY zyz END
		// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
		RespectFlg = CommConst.RESPECT_ISSHOW_FLG;
		mrStr = '';
		if(RespectFlg) {
			mrStr = CommUtils.nullToBlank(parMap.get('mr'));
			if(CommUtils.isBlank(mrStr)) mrStr = CommUtils.nullToBlank(lead.RespectLst__c);
		}
		// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
		// 2015/01/26 BEGING
		String stampFlg = parMap.get('stampFlg');
		if (CommUtils.isBlank(stampFlg)) stampIsShowFlg = CommConst.Bill_STAMPISSHOW_FLG;
		else stampIsShowFlg = Boolean.valueOf(stampFlg);
		// 2012/08/25 WSQ ADD
		// 2015/09/01 多店舗機能対応 BEGIN
		shopCd = parMap.get('shopcd');
		String[] shops = ShopInfoUtil.getCanSelectShopLst(UserInfo.getUserId());
		if (CommUtils.isBlank(shopCd) && shops.Size() > 0 && lead != null) shopCd = lead.LeadPdfShopCode__c;
		// 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH BEGIN
		// if (CommUtils.isBlank(shopCd)) shopCd = UserUtil.CurrentUser.ShopCode__c;
		if (CommUtils.isBlank(shopCd)){
			shopCd = UserUtil.CurrentUser.ShopCode__c;
			// 获取店铺默认设定Code
			shopCd = ShopInfoUtil.getShopDefCd(shopCd, lead.ShopCodeCal__c, UserUtil.CurrentUser.ShopCode__c);
		}
		// 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH END
		// 2015/09/01 多店舗機能対応 END
    	// 2019/1/15 請求書に掲載する振込先口座情報を、同一店舗内で切り替えする BY cxw BEGIN
    	// 2019/06/15 請求書の振込先欄を5つにして機能対応 BY zyz BEGIN
    	// lstFixelMsg = CommRepUtils.handleNewLines(CommUtils.nullToBlank(ApexPages.currentPage().getParameters().get('fixedMsg')), 4, 35);
    	lstFixelMsg = CommRepUtils.handleNewLines(CommUtils.nullToBlank(ApexPages.currentPage().getParameters().get('fixedMsg')), 8, 35);
    	// 2019/06/15 請求書の振込先欄を5つにして機能対応 BY zyz END
    	// 2019/1/15 請求書に掲載する振込先口座情報を、同一店舗内で切り替えする BY cxw END
		// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH BEGIN
		setRepInfo(shopCd);
		// 2019/06/30 ご予約内の請求書ボタンのUIに作成 BY zyz BEGIN
		// accountName = lead.BillSaveFlg__c ? CommUtils.nullToBlank(lead.AccountReceiptName__c) : CommUtils.nullToBlank(lead.BillingCal__c);
		if (parMap.containsKey('recpName')) accountName = CommUtils.nullToBlank(parMap.get('recpName'));
		else if (CommUtils.isBlank(accountName)) accountName = lead.BillSaveFlg__c ? CommUtils.nullToBlank(lead.AccountReceiptName__c) : CommUtils.nullToBlank(lead.BillingCal__c);
		// 2020/01/30 宛名が一定文字数を超えた場合に自動改行する BY zyz BEGIN
		Boolean titleNameFlg = !CommConst.APPOTION_TITLE_NAME_FLG;
		if(titleNameFlg) {
			accountName = CommRepUtils.getPdfMaxShowStringNew(accountName ,2,20);
		}
		// 2020/01/30 宛名が一定文字数を超えた場合に自動改行する BY zyz END
		// accountProviso = CommUtils.nullToBlank(lead.AccountProviso__c);
		if (parMap.containsKey('accountProviso')) accountProviso = CommUtils.nullToBlank(parMap.get('accountProviso'));
		else if(CommUtils.isBlank(accountProviso)) accountProviso = CommUtils.nullToBlank(lead.AccountProviso__c);
		// 2019/06/30 ご予約内の請求書ボタンのUIに作成 BY zyz END
		// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH END
		accIdSet = new Set<Id>();
		// 2013/11/14 支店機能追加
		setPayeeInfo();
		// 2016/09/09 会計書、請求書明細表示順機能対応 BEGIN
		// 予約インストール_予約インデックスSUB_グループNO
		Set<String> mulitRoomKeySet = new Set<String>();
		// 2016/09/09 会計書、請求書明細表示順機能対応 END
		Set<Date> rateGetDaySet = new Set<Date>();
		// 利用日リスト情報を格納する (2014/07/18)
		Map<Id, Date> salesDataMap = new Map<Id, Date>();
		// 外貨から日本円に変換、請求書を作成するの場合		
		if (exchangeRateFlg) {
			Date useDate = null;
			// 全て利用日情報を取得する
			for (AccountAcount__c acc: account) {
				// 2014/07/18 利用日情報を格納する（売上日）
				salesDataMap.put(acc.Relreserve__c, salesdayCal);
			}
			exchangeRateMap = new Map<Date, Decimal>();
			// TODO 2014/08/02 ユーザーの組織通貨により、検索の前方キーワードを決める対応可能
			// USDJPY前方一致の為替レートを取得する
			// 2016/12/06 為替レートカスタマイズできる機能対応 BEGIN
			String exchangePrefixKey =  orgCurrency+currencyInf+'_%';
			// 2016/12/06 為替レートカスタマイズできる機能対応 END
			// パラメータは起動の会計の為替レートにより、日本円表示する
			if(EXCHANGE_RATE_QUERY == APPOPTION_EXCHANGE_RATE_ONE_DAY)
			{
				List<ExchangeRate__c> rs = [select Rate__c,RateDate__c from ExchangeRate__c Where Name LIKE :exchangePrefixKey And RateDate__c = :salesdayCal limit 1];
				if (!rs.isEmpty()) {
					for(Id key: salesDataMap.keySet()) {
						exchangeRateMap.put(salesDataMap.get(key), rs[0].Rate__c);
					}
				} else {
					throw new CommException('請求書作成エラーが発生しました、'+salesdayCal.format()+'の為替レート値が未設定。['+orgCurrency+']->['+currencyInf+']');
				}
			}
			else
			{ 
				for (ExchangeRate__c rs : [select Rate__c,RateDate__c from ExchangeRate__c Where Name LIKE :exchangePrefixKey And RateDate__c in :salesDataMap.values()]) {
					exchangeRateMap.put(rs.RateDate__c, rs.Rate__c);
				}
			}
		}
		// 2015/07/20 会計明細に支払明細表示を追加する
		// 指定の会計情報は新会計・旧会計するがどうか判断を行う
		for (AccountAcount__c acc: account) {
			// 2016/09/09 会計書、請求書明細表示順機能対応 BEGIN
			if (acc.Relreserve__c != null) {
				String filterKey =	CommUtils.nullToBlank(acc.Relreserve__r.LeadIndexRef__c) + '_' +
									CommUtils.nullToBlank(acc.Relreserve__r.LeadIndexSubId__c) + '_' +
									CommUtils.nullToBlank(acc.Relreserve__r.RoomGroupNo__c);
				mulitRoomKeySet.add(filterKey);
			}
			// 2016/09/09 会計書、請求書明細表示順機能対応 END
		}
		// 並び順情報を格納する
		Map<String, TranItem> locSortKeyMap = new Map<String, TranItem>();
		// $支払金額合計値格納する
		Map<String, Decimal> ttendInfoMap = new Map<String, Decimal>();
		// 会計支払情報金額を集計を行う
		for (TTend__c ttend : ttendLst) {
			// Media名
			String ttendMedia = CommUtils.nullToBlank(ttend.field3__c);
			// 預かり金額
			Decimal paymentMoney = CommUtils.nullToZero(ttend.Field28__c);
			// 全ての支払金額を合計する
			allOrgRemaindPrice += paymentMoney;
			// 通貨変換する場合
			if (exchangeRateFlg) {
				String key = ttend.Field1__r != null ? (ttend.Field1__r.Relreserve__r != null ? ttend.Field1__r.Relreserve__r.Id : null)
													   : null;
				paymentMoney = exchangeUsdToJpy(salesDataMap.get(key), paymentMoney);
				ttend.Field19__c = CommUtils.nullToBlank(paymentMoney);
			}
			// 支払金額
			if (!ttendInfoMap.containsKey(ttendMedia)) ttendInfoMap.put(ttendMedia, paymentMoney);
			else ttendInfoMap.put(ttendMedia, ttendInfoMap.get(ttendMedia) + paymentMoney);
			// 支払情報も会計明細に表示の対応
			locSortKeyMap.put(getSortKey(null, ttend, mulitRoomKeySet.size()), convertTtendToTranItem(ttend));
		}
		// 各Mediaに支払金額を合計する
		// 2018/02/28 支払種別は「雑損」を作成したい WGCH BEGIN
		for(String mediaType : ttendInfoMap.keySet()){
			if( mediaType == CommConst.MEDIA_TYPE_01 || 
				mediaType == CommConst.MEDIA_TYPE_02 || 
				mediaType == CommConst.MEDIA_TYPE_03 || 
				mediaType == CommConst.MEDIA_TYPE_11 || 
				mediaType == CommConst.MEDIA_TYPE_12 || 
				mediaType == CommConst.MEDIA_TYPE_21   ) continue;
			amoutCustomPayLst.add(new amoutCustomPay(CommUtils.nullToZero(ttendInfoMap.get(mediaType))));
		}
		// 2018/02/28 支払種別は「雑損」を作成したい WGCH END
		// 現計(税込)
		amoutAllCash = CommUtils.nullToZero(ttendInfoMap.get(CommConst.MEDIA_TYPE_01));
		// 掛計(税込)
		amoutAllMultiply = CommUtils.nullToZero(ttendInfoMap.get(CommConst.MEDIA_TYPE_03));
		// クレジット計
		amoutAllCredit = CommUtils.nullToZero(ttendInfoMap.get(CommConst.MEDIA_TYPE_02));
		// クーポン計
		amoutAllCoupon = CommUtils.nullToZero(ttendInfoMap.get(CommConst.MEDIA_TYPE_11));
		// 割引計
		amountAllDiscount = CommUtils.nullToZero(ttendInfoMap.get(CommConst.MEDIA_TYPE_12));
		// 予約金[預かり金額]で画面に表示を行う
		amoutAllSubscription = CommUtils.nullToZero(ttendInfoMap.get(CommConst.MEDIA_TYPE_21));
		// 2016/03/31 サビース料金は明細として、請求書に表示の対応 BEGIN
		gServiceOuputFlg = ShopInfoUtil.isShowServiceCharge(shopCd);
		// 2016/03/31 サビース料金は明細として、請求書に表示の対応 END
		// 2016/04/08 サビース料金は明細として、請求書に表示の対応[サービス料表示モード２] BEGIN
		String serviceOutputDiv = ShopInfoUtil.getShowServiceChargeMode(shopCd);
		gIsServieModeOuter = serviceOutputDiv == ShopInfoUtil.SERVICE_CHARGE_MODE_OUTER;
		// 2016/04/08 サビース料金は明細として、請求書に表示の対応[サービス料表示モード２] END
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		gIsServieModeInner = serviceOutputDiv == ShopInfoUtil.SERVICE_CHARGE_MODE_INNER;
		// 2019/07/30 軽減税率機能対応 WGCH END
		// 2017/07/20 サビース料税別区分 zyz BEGIN
		gserviceNoTaxFlg = ShopInfoUtil.isServiceChargeIsNoTax(shopCd);
		exchageServiceAmount = 0;//外貨のサービス料金額格納
		// 2017/07/20 サビース料税別区分 zyz END
		tran = new List<TranItem>();
		for(Tran1__c sobj : tranRsLst) {
			// 前受付金の商品する場合
			if (sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_AR) {
				Decimal locPayAmount = CommUtils.nullToZero(sobj.Field23__c);
				allOrgRemaindPrice += locPayAmount;
				
				if (exchangeRateFlg) locPayAmount = exchangeUsdToJpy(sobj.RelAccount__r.Salesday__c, locPayAmount);
				
				// 返金の場合、返金の金額は利用金額と加算して、店舗から出るの資産値
				if (BillSimpleHelp.isRefundItem(sobj.PaymentType__c)) {
					amountRefundPrice += Math.abs(locPayAmount);
				} else {
					amoutARprice += locPayAmount;
				}
				// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
				// TranItem item = new TranItem(sobj, tran.size()+1, pointlen);
				TranItem item = new TranItem(sobj, tran.size()+1, pointlen, false);
				// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
				item.unitPrice = locPayAmount;
				// 明細情報はMAPに格納する
				locSortKeyMap.put(getSortKey(sobj, null,mulitRoomKeySet.size()), item);
				continue;
			}
			Decimal qty = CommUtils.nullToZero(sobj.Field21__c);
			// 通貨JPYへ変換する場合、小数点処理は０桁で計算する
			CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(sobj.UnitPriceDefKb__c), CommUtils.getPointLen());
			// 2015/10/27 課税、非課税混在明細対応するため BEGIN
			// 2015/11/25 数量は０の場合、単価計算方式は「単価から税込単価に計算して、画面に表示する」BEGIN
			Decimal unitPrice = 0;
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			Decimal unitPriceEnd = 0;
			Decimal taxUnitPrice = 0;
			Decimal unitPriceExcServiceEnd = 0;
			Decimal unitPriceIncServiceEnd = 0;
			// 2019/07/30 軽減税率機能対応 WGCH END
			// 非課税明細が含める場合
			Decimal noTaxUnitPriceSum = noTaxUnitPriceSumMap.get(sobj.AccountProviso__c);
			// 2016/03/31 サビース料金は明細として、請求書に表示の対応 BEGIN
			Decimal noServiceUnitPrice = 0;
			// 2016/03/31 サビース料金は明細として、請求書に表示の対応 END
			// 元の単価から、税抜金額を外して、税込み金額を計算する
			Decimal incTaxUnitPrice = CommUtils.nullToZero(sobj.Field20__c) - noTaxUnitPriceSum;
			priceInfo.process(incTaxUnitPrice, qty, sobj.TaxRate__c, sobj.ServiceRate__c);
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			if (isReducedTaxFlg) {
				if(planHeaderMap != null && planHeaderMap.containsKey(sobj.Field11__c)) {
					// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
					// priceInfo = planHeaderMap.get(sobj.Field11__c);
					if(planBrkToHeaderCalFlg) priceInfo = planHeaderMap.get(sobj.Field11__c);
					// 2019/10/02 PlanHeader算法切换对应 WGCH END
				}
				// 税抜き金額[税抜、サビース料込]	
				unitPriceEnd = priceInfo.unitPriceTax;
				// 消费税金额
				taxUnitPrice = priceInfo.priceTax;
				if(gServiceOuputFlg){
					// サービス料表示モード1
					if(gIsServieModeInner){
						// 防止重复集计
						// 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH BEGIN
						// if(sobj.ActionType__c != CommConst.PROD_ACTION_TYPE_PL){
						// 2019/09/27 ServiceAmountBUG修正 WGCH BEGIN
						// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
						if(sobj.ActionType__c != CommConst.PROD_ACTION_TYPE_PL || (pBrkTranItemMap != null && !pBrkTranItemMap.containsKey(sobj.Field11__c)) || !planBrkToHeaderCalFlg){
						// 2019/10/02 PlanHeader算法切换对应 WGCH END
						// 2019/09/27 ServiceAmountBUG修正 WGCH END
						// 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH END
							serviceAmountEnd += priceInfo.priceService;
							serviceTaxAmountEnd += priceInfo.priceService - priceInfo.priceServiceExcTax;
						}
						unitPriceExcServiceEnd += priceInfo.unitPriceExcService;
						unitPriceIncServiceEnd += priceInfo.unitPriceIncService;
					}
					// サービス料表示モード２
					// 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH BEGIN
					// if(gIsServieModeOuter && sobj.ActionType__c != CommConst.PROD_ACTION_TYPE_PL){
					// 2019/09/27 ServiceAmountBUG修正 WGCH BEGIN
					// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
					if(gIsServieModeOuter && (sobj.ActionType__c != CommConst.PROD_ACTION_TYPE_PL || (pBrkTranItemMap != null && !pBrkTranItemMap.containsKey(sobj.Field11__c)) || !planBrkToHeaderCalFlg)){
					// 2019/10/02 PlanHeader算法切换对应 WGCH END
					// 2019/09/27 ServiceAmountBUG修正 WGCH END
					// 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH END
						// 該当明細はサービス料の場合
						if (CommConst.PROD_ACTION_TYPE_SR == sobj.ActionType__c) {
							if (gserviceNoTaxFlg) serviceAmountEnd += priceInfo.priceExcTax;
							else serviceAmountEnd += priceInfo.priceIncTax;
						} else {
							if (gserviceNoTaxFlg) serviceAmountEnd += priceInfo.priceServiceExcTax;
							else serviceAmountEnd += priceInfo.priceService;
						}
					}
				}
			}
			// 2019/07/30 軽減税率機能対応 WGCH END
			unitPrice = priceInfo.unitPriceTax;
			// 2016/03/31 サビース料金は明細として、請求書に表示の対応 BEGIN
			noServiceUnitPrice = priceInfo.unitPriceIncTax;
			// 2016/03/31 サビース料金は明細として、請求書に表示の対応 END
			// サビース料金は明細として、請求書に表示の対応[サービス料表示モード２] BEGIN
			if (gIsServieModeOuter) {
				// 該当明細はサービス料の場合
				if (CommConst.PROD_ACTION_TYPE_SR == sobj.ActionType__c) {
					// 2017/07/20 サビース料税別区分 zyz BEGIN
					if (gserviceNoTaxFlg) serviceAmount += priceInfo.priceExcTax;
					else 
					// 2017/07/20 サビース料税別区分 zyz END
					serviceAmount += priceInfo.priceIncTax;
				} else {
					// 2017/07/20 サビース料税別区分 zyz BEGIN
					if (gserviceNoTaxFlg) serviceAmount += priceInfo.priceServiceExcTax;
					else 
					// 2017/07/20 サビース料税別区分 zyz END
					serviceAmount += priceInfo.priceService;
				}
			}
			// サビース料金は明細として、請求書に表示の対応[サービス料表示モード２] END
			Decimal priceIncTax = priceInfo.priceIncTax;	// 非課税明細金額を抜いて、計算した税込金額
			Decimal onlyIncTaxunitPrice = unitPrice;		// 税込の明細合計値を格納する
			Decimal onlyIncTaxPrice = priceIncTax;
			// 非課税明細金額からサービス料を計算する
			if (noTaxUnitPriceSum > 0) {
				priceInfo.process(noTaxUnitPriceSum, qty , 0, sobj.ServiceRate__c);
				unitPrice += priceInfo.unitPriceTax;
				priceIncTax += priceInfo.priceIncTax;
				// 2016/03/31 サビース料金は明細として、請求書に表示の対応 BEGIN
				// TODO: 加算必要じゃないですか？ 非課税含める場合、該当非課税のサービス料も別計算が必要
				noServiceUnitPrice += priceInfo.unitPriceIncTax;
				// 2016/03/31 サビース料金は明細として、請求書に表示の対応 END
				// サビース料金は明細として、請求書に表示の対応[サービス料表示モード２] BEGIN
				if (gIsServieModeOuter) {
					// 2017/07/20 サビース料税別区分 zyz BEGIN
					if (gserviceNoTaxFlg) serviceAmount += priceInfo.priceServiceExcTax;
					else 
					// 2017/07/20 サビース料税別区分 zyz END
					serviceAmount += priceInfo.priceService;
				}
				// サビース料金は明細として、請求書に表示の対応[サービス料表示モード２] END
			}
			// 2015/11/25 数量は０の場合、単価計算方式は「単価から税込単価に計算して、画面に表示する」END
			// 2015/08/02 明細利用金額から総金額から減算する
			allOrgRemaindPrice = allOrgRemaindPrice - priceIncTax;
			// 単価（税込み、サビース料込）金額は外貨へ変換を行う
			if (exchangeRateFlg) {
				// 外貨から日本円金額を計算する
				unitPrice = exchangeUsdToJpy(sobj.RelAccount__r.Salesday__c, CommUtils.nullToZero(unitPrice));
				// 該当金額により、各項目金額を再計算を行う[日本円の桁数により、単価区分２で関連金額を計算する]
				priceInfo = new CommUtils.ProductInfo(CommConst.APPOPTION_UTP_DEF_KB_OP2, pointlen);
				// 税込のみ情報を格納する
				onlyIncTaxunitPrice = exchangeUsdToJpy(sobj.RelAccount__r.Salesday__c, CommUtils.nullToZero(onlyIncTaxunitPrice));
				priceInfo.process(onlyIncTaxunitPrice , qty, sobj.TaxRate__c, sobj.ServiceRate__c);
				onlyIncTaxPrice = priceInfo.priceIncTax;
				// 2016/03/31 サビース料金は明細として、請求書に表示の対応 BEGIN
				noServiceUnitPrice = exchangeUsdToJpy(sobj.RelAccount__r.Salesday__c, CommUtils.nullToZero(noServiceUnitPrice));
				// 2016/03/31 サビース料金は明細として、請求書に表示の対応 END
				// サビース料金は明細として、請求書に表示の対応[サービス料表示モード２] BEGIN
				if (gIsServieModeOuter) {
					// 2017/07/20 サビース料税別区分 zyz BEGIN
					exchageServiceAmount += exchangeUsdToJpy(sobj.RelAccount__r.Salesday__c, CommUtils.nullToZero(serviceAmount));
					// 2017/07/20 サビース料税別区分 zyz END
				}
				// サビース料金は明細として、請求書に表示の対応[サービス料表示モード２] END
			}
			// 税率は0以上の場合、該当合計金額は課税対象です[商品本体の単価＊数量（税込）= 税込金額]
			// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
			// TranItem item = new TranItem(sobj, tran.size()+1, pointlen);
			TranItem item = new TranItem(sobj, tran.size()+1, pointlen, false);
			// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
			if(sobj.TaxRate__c > 0) amoutIncTaxprice += onlyIncTaxPrice;
			// 商品単価（税込、サービス込）
			item.unitPrice = unitPrice;
			// 通貨変換機能
			// 総計金額を計算する
			// 2014/09/05 数量小数点機能対応
			amoutAllMoney += item.amout;
			// 特別税計算合計
			Decimal varAmoutIncSpecialPrice = CommUtils.nullToZero(sobj.SpecialTax__c);
			// 2015/08/02 明細利用金額から総金額から減算する
			allOrgRemaindPrice = allOrgRemaindPrice - varAmoutIncSpecialPrice;
			if (exchangeRateFlg && varAmoutIncSpecialPrice > 0) {
				String key = sobj.Field1__r != null ? (sobj.Field1__r.Relreserve__r != null ? sobj.Field1__r.Relreserve__r.Id : null)
													   : null;
				varAmoutIncSpecialPrice = exchangeUsdToJpy(salesDataMap.get(key), varAmoutIncSpecialPrice);
				// 為替変更後の金額は再設定を行う
				item.specialTax = varAmoutIncSpecialPrice;
			}
			amoutIncSpecialPrice += varAmoutIncSpecialPrice;
			// 2016/03/31 サビース料金は明細として、請求書に表示の対応 BEGIN
			if (gServiceOuputFlg && sobj.ServiceRate__c > 0) {
				if (serviceOutputDiv == ShopInfoUtil.SERVICE_CHARGE_MODE_INNER) {
					// サビース料なしの単価を取得する
					item.unitPrice = noServiceUnitPrice;
				}
			}
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			if (isReducedTaxFlg) {
				// 最终单价赋值
				item.unitPrice = unitPriceEnd;
				// 最终消费税赋值
				item.taxUnitPrice = taxUnitPrice;
				// noTaxUnitPriceSum => 当前plan 明细里的非课税合计金额 【如果当前不是plan 或 plan明细里没有 非课税商品  它就=0】
				// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
				// if(sobj.ActionType__c != CommConst.PROD_ACTION_TYPE_PL) addDetailToMapFun(item, noTaxUnitPriceSum);
				if(sobj.ActionType__c != CommConst.PROD_ACTION_TYPE_PL || !planBrkToHeaderCalFlg){
            		addDetailToMapFun(item, 0);
            		priceInfo.process(noTaxUnitPriceSum, qty, 0, sobj.ServiceRate__c);
            		item.unitPrice += priceInfo.unitPriceTax;
            		// サービス料表示モード1
            		if(gIsServieModeInner){
            			serviceAmountEnd += priceInfo.priceService;
            			serviceTaxAmountEnd += priceInfo.priceService - priceInfo.priceServiceExcTax;
            			item.unitPrice -= priceInfo.unitPriceIncService;
            			item.taxUnitPrice -= priceInfo.unitPriceIncService - priceInfo.unitPriceExcService;
            		}
            		// サービス料表示モード２
            		if(gIsServieModeOuter){
            			// 該当明細はサービス料の場合
            			if (CommConst.PROD_ACTION_TYPE_SR == sobj.ActionType__c) {
            				if (gserviceNoTaxFlg) serviceAmountEnd += priceInfo.priceExcTax;
            				else serviceAmountEnd += priceInfo.priceIncTax;
            			} else {
            				if (gserviceNoTaxFlg) serviceAmountEnd += priceInfo.priceServiceExcTax;
            				else serviceAmountEnd += priceInfo.priceService;
            			}
            		}
            		// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
            		// addDetailToMapFun(new TranItem(new Tran1__c(), item.rowNo, pointlen), (priceInfo.unitPriceTax * qty));
            		addDetailToMapFun(new TranItem(new Tran1__c(), item.rowNo, pointlen, false), (priceInfo.unitPriceTax * qty));
            		// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
            	}
				// 2019/10/02 PlanHeader算法切换对应 WGCH END
				// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
				// else addDetailToMapFun(new TranItem(new Tran1__c(), item.rowNo, pointlen), CommUtils.nullToZero(sobj.SpecialTax__c));
				else addDetailToMapFun(new TranItem(new Tran1__c(), item.rowNo, pointlen, false), CommUtils.nullToZero(sobj.SpecialTax__c));
				// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
				// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
				if(planBrkToHeaderCalFlg && pBrkTranItemMap != null && pBrkTranItemMap.containsKey(item.tranId)) {
				// 2019/10/02 PlanHeader算法切换对应 WGCH END
					for(TranItem brkItem : pBrkTranItemMap.get(item.tranId)){
            			// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
						accountsName(CommUtils.nullToBLank(brkItem.produceNm),brkItem);
						// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
						addDetailToMapFun(brkItem, -(brkItem.specialTax));
						if(gServiceOuputFlg && pBrkProMap.containsKey(brkItem.tranId)){
							CommUtils.ProductInfo bPriceInfo = pBrkProMap.get(brkItem.tranId);
							// サービス料表示モード1
							if(gIsServieModeInner){
								serviceAmountEnd += bPriceInfo.priceService;
								serviceTaxAmountEnd += bPriceInfo.priceService - bPriceInfo.priceServiceExcTax;
								brkItem.unitPrice -= bPriceInfo.unitPriceIncService;
								brkItem.taxUnitPrice -= bPriceInfo.unitPriceIncService - bPriceInfo.unitPriceExcService;
							}
							// サービス料表示モード２
							if(gIsServieModeOuter){
								// 該当明細はサービス料の場合
								if (CommConst.PROD_ACTION_TYPE_SR == sobj.ActionType__c) {
									if (gserviceNoTaxFlg) serviceAmountEnd += bPriceInfo.priceExcTax;
									else serviceAmountEnd += bPriceInfo.priceIncTax;
								} else {
									if (gserviceNoTaxFlg) serviceAmountEnd += bPriceInfo.priceServiceExcTax;
									else serviceAmountEnd += bPriceInfo.priceService;
								}
							}
						}
					}
				}
				// 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH BEGIN
				// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
				else if(planBrkToHeaderCalFlg && sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) addDetailToMapFun(item, noTaxUnitPriceSum);
				// 2019/10/02 PlanHeader算法切换对应 WGCH END
				// サービス料表示モード1
				if(gIsServieModeInner){
					item.unitPrice -= unitPriceIncServiceEnd;
					item.taxUnitPrice -= unitPriceIncServiceEnd - unitPriceExcServiceEnd;
				}
				// 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH END
			}
			// 2019/07/30 軽減税率機能対応 WGCH END
			// 2016/03/31 サビース料金は明細として、請求書に表示の対応 END
			// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
			accountsName(CommUtils.nullToBLank(item.produceNm),item);
			// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
			// 明細情報はMAPに格納する
			locSortKeyMap.put(getSortKey(sobj, null,mulitRoomKeySet.size()), item);
		}
		// 新会計
		// 並び順を処理して、出力明細を表示する
		List<String> locSortKeyLst = new List<String>(locSortKeyMap.keySet());
		locSortKeyLst.sort();
		// 並び順情報を再設定を行う[会計支払と会計明細は全部明細に順番を表示を行う]
		for (String key : locSortKeyLst) {
			TranItem item = locSortKeyMap.get(key);
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			/*
			// No列を再設定を行う
			item.rowNo = tran.size()+1;
			*/
			// No列を再設定を行う
			// 2019/09/15 RowNoBUG修正 WGCH BEGIN
			// item.rowNo = rowNoEnd;
			item.rowNo = isReducedTaxFlg ? rowNoEnd : tran.size()+1;
			// 2019/09/15 RowNoBUG修正 WGCH END
			// 2019/07/30 軽減税率機能対応 WGCH END
			tran.add(item);
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			if(isPlanBrkShowFlg && pBrkTranItemMap != null && pBrkTranItemMap.containsKey(item.tranId)){
				for(TranItem pItem : pBrkTranItemMap.get(item.tranId)){
					pItem.rowNo = rowNoEnd;
					pItem.pBrkDNFlg = true;
					tran.add(pItem);
				}
			}
			rowNoEnd ++;
			// 2019/07/30 軽減税率機能対応 WGCH END
			// 該当明細に関連の宿泊税存在するがどうかチェックを行う[33/34のみ、明細に宿泊税を表示する]
			if (item.specialTax > 0) {
				// 宿泊税明細情報を設定する
				TranItem specItem = new TranItem(new Tran1__c(
									   // 2018/06/08 レシート印刷機能言語選択する WGCH BEGIN
									   Field5__c = (isForeignCurrency == true ? 'Accommodation Tax' : '宿泊税'),
									   // 2018/06/08 レシート印刷機能言語選択する WGCH END
									   Field20__c = String.valueOf(item.specialTax),
									   Field21__c = '1',
									   // 2019/07/30 軽減税率機能対応 WGCH BEGIN
									   RowNo__c = isReducedTaxFlg ? rowNoEnd : (tran.size() + 1)),
									   // 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
									   // isReducedTaxFlg ? rowNoEnd : (tran.size()+1), gPointLen);
									   isReducedTaxFlg ? rowNoEnd : (tran.size()+1), gPointLen, false);
									   // 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
									   rowNoEnd ++;
									   // 2019/07/30 軽減税率機能対応 WGCH END
				// 利用日個別設定
				specItem.usedDate = item.usedDate;
				tran.add(specItem);
			}
		}
		
		// 為替レート変更が存在する場合、差異値を再計算する
		// 変換前の請求金額は 100 / 為替レート：100.50 / 変換後の為替金額：10050 各支払明細の金額から支払場合、10499などの場合、該当１円は各支払金額名に平均割り振りする
		if (exchangeRateFlg && allOrgRemaindPrice == 0) {
			// 為替レートから計算の金額は０以外の場合、差分処理を行う
			// 請求金額の場合、
			Decimal locRemainRequest = getRequestAmount();
			// 2015/11/25 差分計算する場合、売掛金は先に外す BEGIN
			Decimal multiplyAmount = CommUtils.nullToZero(amoutAllMultiply);
			locRemainRequest -= multiplyAmount;// 売掛金から支払金額から外す、まだ差分金額が存在する場合
			// 2015/11/25 差分計算する場合、売掛金は先に外す END
			// 差分処理を行う[2015/11/25 売掛金明細に設定する場合、差分値は全部売掛金明細に設定する、その場合、請求金額から該当差分値は外すは要らない、全部売掛金に掛けるので]
			allPlusPayAmount = (multiplyAmount>0) ? 0 : locRemainRequest;
			// 総支払金額の格納する
			Decimal locPayAmoutPrice = 0;
			if (locRemainRequest != 0) {
				List<TranItem> payTranItems = new List<TranItem>();
				for(TranItem item : tran) {
					if (!item.isPayTranItem) continue;
					if (item.amout == 0) continue;
					// 2015/11/25 売掛金存在の場合、差分金額は売掛金に調整する
					if (multiplyAmount > 0 && item.payMediaCode != CommConst.MEDIA_TYPE_CD_03) continue;
					payTranItems.add(item);
					locPayAmoutPrice += item.amout;	// 総支払金額を合計する
				}
				Integer maxIndex = 0;
				Decimal maxMoney = 0;
				Integer rsCntIdx = 0;
				for (TranItem item : payTranItems) {
					Decimal locSplitAmout = CommUtils.RoundProcess((item.amout /locPayAmoutPrice)*locRemainRequest,0,RoundingMode.FLOOR);
					if (item.amout > maxMoney) {
						maxIndex = rsCntIdx;
						maxMoney = item.amout;
					}
					locRemainRequest = locRemainRequest - locSplitAmout;
					item.unitPrice = item.unitPrice + locSplitAmout;
					rsCntIdx++;
				}
				// 最大支払明細に、加算を行う
				if (locRemainRequest != 0) {
					payTranItems[maxIndex].unitPrice = payTranItems[maxIndex].unitPrice + locRemainRequest;
				}
			}
		}
		// 2016/03/31 サビース料金は明細として、請求書に表示の対応 BEGIN
		if (gServiceOuputFlg && serviceOutputDiv == ShopInfoUtil.SERVICE_CHARGE_MODE_INNER) setServiceDetailInfo();
		// 2016/03/31 サビース料金は明細として、請求書に表示の対応 END
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		// 2019/10/30 軽減税率割合モード機能対応 WGCH BEGIN
		// if(isReducedTaxFlg) amoutAllMoney = sumRowData.amountIncTax - amoutIncSpecialPrice;
		if(isReducedTaxFlg) amoutAllMoney = comSum.sumRowData.amountIncTax - amoutIncSpecialPrice;
		// 2019/10/30 軽減税率割合モード機能対応 WGCH END
		// 2019/07/30 軽減税率機能対応 WGCH END
		// 2019/07/15 請求書の請求先名称の上部に請求先の住所を印字 BY zyz BEGIN
		initDocSetting(controller);
		// 2019/07/15 請求書の請求先名称の上部に請求先の住所を印字 BY zyz END
		// 改ページ情報を設定する
		// 改ページ処理機能初期化
		allPageList = new List<OnePage>();
		Integer breakNum = PAGE_FIRSTPG_BREAK_RSNUM;
		// 2019/07/15 請求書の請求先名称の上部に請求先の住所を印字 BY zyz BEGIN
		String comment = comment.comment__c;
		List<String> commentLst = comment.split(' ');
		// 2019/07/15 請求書の請求先名称の上部に請求先の住所を印字 BY zyz END
		// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH BEGIN
		if(!noreceipt){
			breakNum -= 8;
			Integer row = 0;
			// 2019/1/15 請求書に掲載する振込先口座情報を、同一店舗内で切り替えする BY cxw BEGIN
			/*if(CommUtils.isBlank(payee1)) row += 1;
			if(CommUtils.isBlank(payee2)) row += 1;
			if(CommUtils.isBlank(payee3)) row += 1;
			if(row > 0 && row < 3) breakNum += 1;
			else if(row == 3) breakNum += 2;*/
			if(isFiexlMsg) {
				// 2019/06/15 請求書の振込先欄を5つにして機能対応 BY zyz BEGIN
				// row = 4 - lstFixelMsg.size();
				row = 8 - lstFixelMsg.size();
				// 2019/06/15 請求書の振込先欄を5つにして機能対応 BY zyz END
			}else {
				if(CommUtils.isBlank(payee1)) row += 1;
				if(CommUtils.isBlank(payee2)) row += 1;
				if(CommUtils.isBlank(payee3)) row += 1;
			}
			// 2019/06/15 請求書の振込先欄を5つにして機能対応 BY zyz BEGIN
			// if(row > 0 && row < 3) breakNum += 1;
			// else if(row >= 3) breakNum += 2;
			// 2019/07/15 請求書の請求先名称の上部に請求先の住所を印字 BY zyz BEGIN
			/*
			if (isFiexlMsg){
				if(row >= 7)  breakNum += 2;
				else if(row < 7 && row >= 5 ) breakNum += 1;
				else if(row < 5 && row >= 3 ) breakNum += 0;
				else if(row < 3 && row >= 2 ) breakNum -= 1;
				else if(row < 2 && row >= 0 ) breakNum -= 2;
			} else {
				if(row > 0 && row < 3) breakNum += 1;
				else if(row >= 3) breakNum += 2;
			}
			*/
			if (isFiexlMsg){
			    if(row >= 7)  {
			        breakNum += 2;
			        if(longInt > 2) breakNum -= 1;
			    }else if(row < 7 && row >= 5 ) {
			        breakNum += 1;
			        if(longInt > 2 && row == 5) breakNum -= 2;
			        if(longInt > 2 && row == 6) breakNum -= 1;
			    }else if(row < 5 && row >= 3 ) {
			        // breakNum += 0;
			        if(longInt > 2 && row == 4) breakNum -= 1;
			        else if(longInt > 2 && row == 3) breakNum -= 2;
			        else if(longInt > 1 && row == 3) breakNum -= 1;
			    }else if(row < 3 && row >= 2 ) {
			        breakNum -= 1;
			        if(longInt > 2) breakNum -= 2;
			        else if(longInt > 1) breakNum -= 1;
			    }else if(row < 2 && row >= 0 ) {
			        breakNum -= 2;
			        if(longInt > 2 && row == 1) breakNum -= 2;
			        else if(longInt > 2 && row == 0) breakNum -= 3;
			        else if(longInt > 1) breakNum -= 1;
			    }
			} else {
			    if(row > 0 && row < 3) {
			        breakNum += 1;
			        if(longInt > 2) breakNum -= 1;
			    }else if(row >= 3) {
			        breakNum += 2;
			        if(longInt > 2) breakNum -= 1;
			    }else if(longInt > 2 && row == 0) breakNum -= 1;
			}
			// 2019/07/15 請求書の請求先名称の上部に請求先の住所を印字 BY zyz END
			// 2019/06/15 請求書の振込先欄を5つにして機能対応 BY zyz END
			// 2019/1/15 請求書に掲載する振込先口座情報を、同一店舗内で切り替えする BY cxw END
			if(isCommentAutoBreakFlg){
				// 2019/07/15 請求書の請求先名称の上部に請求先の住所を印字 BY zyz BEGIN
				// String comment = comment.comment__c;
				// List<String> commentLst = comment.split(' ');
				// 2019/07/15 請求書の請求先名称の上部に請求先の住所を印字 BY zyz END
				// 2019/1/15 請求書に掲載する振込先口座情報を、同一店舗内で切り替えする BY cxw BEGIN
				// if(commentLst.size() == 4 && row >= 3) breakNum -= 2;
				// 2019/06/15 請求書の振込先欄を5つにして機能対応 BY zyz BEGIN
				// if(commentLst.size() == 4 && row >= 3) breakNum -= 2;
				if (isFiexlMsg){
					if(commentLst.size() == 4 && row >= 7) breakNum -= 2;
					// 2019/07/15 請求書の請求先名称の上部に請求先の住所を印字 BY zyz BEGIN
					// 自定义3行时，comment定义四行，口座情报少于4，行数再次减一
					if(commentLst.size() == 4 && row >= 5 && longInt > 1) breakNum -= 1;
					if(commentLst.size() == 4 && row == 6 && longInt > 2) breakNum -= 1;
					else if(commentLst.size() == 3 && row >= 7 && longInt > 2) breakNum -= 1;
					// 2019/07/15 請求書の請求先名称の上部に請求先の住所を印字 BY zyz END
				} else {
					if(commentLst.size() == 4 && row >= 3) breakNum -= 2;
					if(commentLst.size() == 4 && row >= 3 && longInt > 2) breakNum -= 1;
				}
				// 2019/06/15 請求書の振込先欄を5つにして機能対応 BY zyz END
				// 2019/1/15 請求書に掲載する振込先口座情報を、同一店舗内で切り替えする BY cxw END
			}
		// 2019/06/15 請求書の振込先欄を5つにして機能対応 BY zyz BEGIN
		} else if(isFiexlMsg){
			// 不显示领収书时行数计算
			Integer row = 8 - lstFixelMsg.size();
			// 2019/07/15 請求書の請求先名称の上部に請求先の住所を印字 BY zyz BEGIN
			/*
			if(row >= 4)  breakNum -= 0;
			else if(row < 4 && row >= 2 ) breakNum -= 1;
			else if(row < 2 && row > 0 ) breakNum -= 2;
			else if(row == 0 ) breakNum -= 3;
			*/
			if(row >= 4) {
			    //breakNum -= 0;
			    if (longInt > 2 && row == 5) breakNum -= 1;
			    else if (longInt > 2 && row == 4) breakNum -= 2;
			    else if (longInt > 1 && row == 4) breakNum -= 1;
			    // 請求書控页再次计算
			    if(!isShowCopyInfFlg && longInt > 2 && row == 4) breakNum -= 1;
			} else if (row < 4 && row >= 2 ) {
			    breakNum -= 1;
			    if (longInt > 2 && row == 3) breakNum -= 2;
			    else if (longInt > 2 && row == 2) breakNum -= 3;
			    else if (longInt > 1) breakNum -= 1;
			} else if (row < 2 && row > 0 ) {
			    breakNum -= 2;
			    if (longInt > 2) breakNum -= 2;
			    else if (longInt > 1) breakNum -= 1;
			} else if (row == 0 ) {
			    breakNum -= 3;
			    if (longInt > 2) breakNum -= 2;
			    else if (longInt > 1) breakNum -= 1;
			}
			// コメント
			if(isCommentAutoBreakFlg){
				if(commentLst.size() == 4 && row >= 6 && longInt > 2) breakNum -= 2;
				else if(commentLst.size() == 4 && row >= 4 && longInt > 2) breakNum -= 1;
				else if(commentLst.size() == 4 && row >= 5 && longInt > 1) breakNum -= 1;
				else if(commentLst.size() == 3 && row >= 6 && longInt > 2) breakNum -= 1;
			}
		} else{
			// 不显示领収书时行数计算
			Integer row = 8 - lstFixelMsg.size();
			// 2019/10/30 多一页空白页bug对应修改 BY zyz BEGIN
			if(!CommUtils.isBlank(payee1) && !CommUtils.isBlank(payee2) && !CommUtils.isBlank(payee3) && !CommUtils.isBlank(payeeAcount)) breakNum -= 1;
			// 2019/10/30 多一页空白页bug对应修改 BY zyz END
			// コメント
			if(isCommentAutoBreakFlg){
				if(commentLst.size() == 4 && row >= 7 && longInt > 2) breakNum -= 2;
			}
		}
		// 2019/07/15 請求書の請求先名称の上部に請求先の住所を印字 BY zyz END
		// 2019/06/15 請求書の振込先欄を5つにして機能対応 BY zyz END
		// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH END
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		if (isReducedTaxFlg && taxRowDataMap != null) processSumInfo();
		// 根据合计板块的行数 与 总行数合并
		if(isReducedTaxFlg){
			// 2019/10/30 消費税対象、値引行非表示の機能機能対応 WGCH BEGIN
			/*
			breakNum += 1; // 原有消费税行
			// head 内容行间距缩小节省行数 by zy END
			if(taxRowDataMap != null){
				// head 内容行间距缩小节省行数 by zy BEGIN
				integer lineSize = taxRowDataMap.keySet().Size();
				if (lineSize == 4) breakNum -= 3;
				else if (lineSize > 1 && lineSize < 4) breakNum -= 2;
				else breakNum -= 1;
				// head 内容行间距缩小节省行数 by zy END
				// 合计行
				breakNum -= 1;
			}
			// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
			if(disRowDataLst != null) breakNum -= disRowDataLst.Size() + 1;
			// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
			if((disRowData.disUnitPriceSum + disRowData.disTaxAmountSum ) != 0) breakNum -= 1;
			*/
			// 获取轻减税率后最终多出来的行数
			Integer rowBreakNumEnd = CommLogicProcess.getRowBreakNumEnd(comSum, CommLogicProcess.CLASS_MODE.BILL.Name());
			breakNum -= rowBreakNumEnd;
			// 2019/10/30 消費税対象、値引行非表示の機能機能対応 WGCH END
		}
		// 2019/07/30 軽減税率機能対応 WGCH END
		// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
		Integer lineNum = 0;	// 记录最后一页计算空白格
		Integer linesNum = 0;	// 计算增加行数值
		// 2019/10/22 BUGFIX WSQ BEGIN
		// if (!taxRowDataMap.isEmpty() && isAccountProdNmReturnFlg && tran.size() != 0) breakNum +=3;		// 軽减税率和行追加功能生效后，追加三行
		if (taxRowDataMap != null && !taxRowDataMap.isEmpty() && isAccountProdNmReturnFlg && tran.size() != 0) breakNum +=3;		// 軽减税率和行追加功能生效后，追加三行
		// 2019/10/22 BUGFIX WSQ END
		// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
		for (Integer index =0; index < tran.size(); index++) {
			// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
			lineNum += CommUtils.nullToZero(tran[index].proNum);
			linesNum += CommUtils.nullToZero(tran[index].proNum);
			// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
			// 改ページ計算
			// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH BEGIN
			// Integer breakLine = index - (allPageList.isEmpty() ? 0 : 1) * PAGE_FIRSTPG_BREAK_RSNUM - (allPageList.size() > 1 ? allPageList.size() -1 : 0 ) * PAGE_NEXTPG_BREAK_RSNUM;
			// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
			// Integer breakLine = index - (allPageList.isEmpty() ? 0 : 1) * breakNum - (allPageList.size() > 1 ? allPageList.size() -1 : 0 ) * PAGE_NEXTPG_BREAK_RSNUM;
			Integer breakLine = index - (allPageList.isEmpty() ? 0 : 1) * (breakNum -linesNum) - (allPageList.size() > 1 ? allPageList.size() -1 : 0 ) * PAGE_NEXTPG_BREAK_RSNUM;
			// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH END
			// 改ページする場合
			// if (breakLine == 0) {
			if(breakLine >= 0){
				lineNum = CommUtils.nullToZero(tran[index].proNum);
				if(index != 0 && CommUtils.nullToZero(tran[index].proNum) != 0)linesNum += CommUtils.nullToZero(tran[index].proNum)-breakLine;
				// 补全每页的空白行
				/**/
				if(allPageList.size() > 0){
					OnePage onePgblank = allPageList[allPageList.size() - 1];
					for (integer i=0; i < (lineNum -breakLine); i++) {
						onePgblank.addItem(new TranItem(new Tran1__c(), null, pointlen, true));
					}
				}
				// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
				OnePage onePg = new OnePage();
				onePg.addItem(tran[index]);
				allPageList.add(onePg);
				// ページ数を設定する
				onePg.currPages = allPageList.size();
			} else {
				OnePage onePg = allPageList[allPageList.size() - 1];
				onePg.addItem(tran[index]);
			}
		}
		// 全部データは一ページ場合、空白行を追加する
		Integer dumyLen = 0;
		OnePage dumyPage = null;
		if (allPageList.isEmpty()) {
			dumyLen = breakNum;
			dumyPage = new OnePage();
			allPageList.add(dumyPage);
		}
		if (allPageList.size() == 1) {
			// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
			// dumyLen = breakNum - allPageList[0].onePageList.size();
			dumyLen = breakNum - allPageList[0].onePageList.size() - lineNum;
			// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
			dumyPage = allPageList[0];
		}
		for (integer i=0; i < dumyLen; i++) {
			// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
			// dumyPage.onePageList.add(new TranItem(new Tran1__c(), null, pointlen));
			dumyPage.onePageList.add(new TranItem(new Tran1__c(), null, pointlen, false));
			// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
		}
		
		// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH BEGIN
		proTaxEnglishLabel = ShopInfoUtil.getTaxEnglishLabel(shopCd);
		// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH END
		// 外貨の場合、内税英語文言表示対応
		if (isForeignCurrency) {
			// 2014/07/30 内消費税表示文言取得
			// 2015/09/01 多店舗機能対応 BEGIN
			// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH BEGIN
			// taxEnglishLabel = ShopInfoUtil.getTaxEnglishLabel(shopCd);
			taxEnglishLabel = proTaxEnglishLabel;
			// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH END
			// 2015/09/01 多店舗機能対応 END
		}
	}
	// 会計支払情報は会計明細にて変換処理を行う
	private TranItem convertTtendToTranItem(Ttend__c ttend) {
		// 会計支払→会計明細に転換を行う
		// ***********************************
		// 該当転換はAccountPDFのconvertTtendToTranItemと一致が必要
		// 簡易会計など、関連の支払商品がなかった場合
		String payProdName = ttend.PayProductName__c;
		if (Commutils.isBlank(payProdName)) {
			if (!CommUtils.isBlank(ttend.CardTypeLst__c)) {
				payProdName = ttend.CardTypeLst__c;
			} else if (!CommUtils.isBlank(ttend.CouponTypeLst__c)) {
				payProdName = ttend.CouponTypeLst__c;
			} else {
				payProdName = ttend.Field3__c;
			}
		}
		Tran1__c tran = new Tran1__c();
		tran.Field7__c = ttend.PayProductRef__c;	// 商品コード
		tran.ActionType__c = CommConst.PROD_ACTION_TYPE_PY;	// 商品処理種別
		tran.PaymentType__c = ttend.PaymentType__c; // ;支払種別
		tran.Field5__c = payProdName;				//会計商品名
		tran.Field20__c = ttend.Field19__c;			// 単価 ←　預かり金額
		tran.Field23__c = ttend.Field19__c;			// 合計金額 ←　預かり金額
		tran.Field21__c = '1';						// 数量１固定
		tran.TaxRate__c = null;						// 消費税
		tran.ServiceRate__c = null;					// サビース料
		tran.SpecialTax__c = 0;						// 特別税
		tran.UseDate__c = ttend.UseDate__c;			// 利用日
		tran.RelAccount__c = ttend.RelAccount__c;	// 売上
		tran.Field1__c = ttend.Field1__c;			// 会計
		tran.RelAccount__r = ttend.RelAccount__r;	// 売上関連情報もコピー[Readonly注意が必要]
		// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
		// TranItem item = new TranItem(tran, -1, gPointLen);
		TranItem item = new TranItem(tran, -1, gPointLen, false);
		// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
		// ***********************************
		// 預かり金額列に表示するため、フラグを設定する
		item.isShowCircle = true;
		// 支払メデイアコード情報を格納
		item.payMediaCode = ttend.Field2__c;
		return item;
	}
	// 表示の並び順KEYを作成する
	private String getSortKey(Tran1__c tran, TTend__c tend, Integer rooms) {
		// 予約なし（簡易会計）一括表示する場合、売上日_ROWNO_NAME
		if (singelAccount.Relreserve__c == null) {
			// 1(固定)_売上日_会計ID_４桁並び順NO(新会計画面から設定)_自動番号
			if (tran != null) 	return '1_' + tran.RelAccount__r.Name + '_' + tran.Field1__c + '_' + CommUtils.paddingLeftZero(CommUtils.nullToZero(tran.RowNo__c),4) + '_' + tran.Name;
			if (tend != null) 	return '1_' + tend.RelAccount__r.Name + '_' + tend.Field1__c + '_' + CommUtils.paddingLeftZero(CommUtils.nullToZero(tend.RowNo__c),4) + '_' +  tend.Name;
		} else {
			// 1(固定)_４桁並び順NO(新会計画面から設定)_売上日_自動番号
			// 2019/04/30 チェックインをかけなくても請求書が１枚に印刷されるようにご希望です by zy BEGIN
			// if (tran != null) 	return '1_' + getSameRoomGroupKey(tran,null,(rooms>1)) + CommUtils.paddingLeftZero(CommUtils.nullToZero(tran.RowNo__c),4) + '_' + tran.RelAccount__r.Name + '_' + tran.Name;
			// 並べ順 1 _ (GROUP)_ ROWNO _ 予約ID _ 見積もり名
			if (tran != null) 	return '1_' + getSameRoomGroupKey(tran,null,(rooms>1)) + CommUtils.paddingLeftZero(CommUtils.nullToZero(tran.RowNo__c),4) + '_' + tran.field1__r.Relreserve__r.EntryTime__c + '_' + tran.Field49__c;
			// if (tend != null) 	return '1_' + getSameRoomGroupKey(null,tend,(rooms>1)) + CommUtils.paddingLeftZero(CommUtils.nullToZero(tend.RowNo__c),4) + '_' + tend.RelAccount__r.Name + '_' + tend.Name;
			// 並べ順 1 _ (GROUP)_ ROWNO _ 予約ID _ 見積もり名
			if (tend != null) 	return '1_' + getSameRoomGroupKey(null,tend,(rooms>1)) + CommUtils.paddingLeftZero(CommUtils.nullToZero(tend.RowNo__c),4) + '_' + tend.field1__r.Relreserve__r.EntryTime__c + '_'  + tend.TempSaveExtInfo__c;
			// 2019/04/30 チェックインをかけなくても請求書が１枚に印刷されるようにご希望です by zy END
		}
		return '';
	}
	private string getSameRoomGroupKey (Tran1__c tran, TTend__c tend, Boolean isMuliteRoomFlg) {
		String userDateSortStr = '';
		//if (!isMuliteRoomFlg) return userDateSortStr;
		Boolean isAccountReportSort = CommConst.APPOTION_ACCOUNT_SORT_VAL == CommConst.APPOTION_ACCOUNT_SORT_USEDATE;
		if (tran != null) {
			if (isAccountReportSort) {
				Date useDate = (tran.UseDate__c == null ? tran.RelAccount__r.Salesday__c : tran.UseDate__c);
				userDateSortStr = DateTime.newInstance(useDate.Year(),useDate.month(),useDate.day()).format('yyyyMMdd') + '_';
				userDateSortStr+= CommUtils.nullToBlank(tran.Field1__r.Relreserve__r.LeadIndexRef__c) + '_' + CommUtils.nullToBlank(tran.Field1__r.Relreserve__r.LeadIndexSubId__c) + '_' + CommUtils.nullToBlank(tran.Field1__r.Relreserve__r.RoomGroupNo__c) + '_';
			}
		} else if (tend != null) {
			if (isAccountReportSort) {
				Date useDate = (tend.UseDate__c == null ? tend.RelAccount__r.Salesday__c : tend.UseDate__c);
				userDateSortStr = DateTime.newInstance(useDate.Year(),useDate.month(),useDate.day()).format('yyyyMMdd') + '_';
				userDateSortStr+= CommUtils.nullToBlank(tend.Field1__r.Relreserve__r.LeadIndexRef__c) + '_' + CommUtils.nullToBlank(tend.Field1__r.Relreserve__r.LeadIndexSubId__c) + '_' + CommUtils.nullToBlank(tend.Field1__r.Relreserve__r.RoomGroupNo__c) + '_';
			}
		}
		return userDateSortStr ;
	}
	/*
	* 2014/07/18 為替レート変更Method
	**/
	private Decimal exchangeUsdToJpy(Date rateDate, Decimal orgCurrency) {
		if (!exchangeRateMap.containsKey(rateDate)) {
			throw new CommException('請求書作成エラーが発生しました、'+rateDate.format()+'の為替レート値が未設定。');
		}
		// 為替レート金額変更を行う
		Decimal rate = exchangeRateMap.get(rateDate);
		// 変更後の金額
		Decimal exchangeMoney = CommUtils.RoundProcess(orgCurrency * rate , pointlen);
		return exchangeMoney;
	}
	public String getNumberFormat() {
		return pointlen > 0 ? ('##,##0.' + '0'.repeat(pointlen) ) : '##,###';
	}
	/**
	* 発行日更新を行う
	**/
	public void extInitAction() {
		// 2017/01/16 請求書/会計書PDFファイルを自動保存対応 BEGIN
		if (ApexPages.currentPage().getParameters().containsKey(PdfAutoSaveUtil.isCallFromAutoPdfKey)) return;
		// 2017/01/16 請求書/会計書PDFファイルを自動保存対応 END
		// 発行日更新処理を行う[2013/01/15 ADD BEGIN]
		List<Id> ldIdLst = new List<Id>();
		for (AccountAcount__c acc: account) {
			ldIdLst.add(acc.Relreserve__c);
			acc.IssueDate__c = Date.today();
		}
		CommLogicProcess.writeLogInfo(ldIdLst);
		// [2013/01/15 ADD END]
	}
	/**
	* レポートロゴ取得する
	**/
	public ReportLogo__c getReportLogo() {
		return CommRepUtils.getReplogoInfoByTypeId(CommRepUtils.REP_TYPE.LOGO_00_SYSDEF);
	}

	public AccountAcount__c getAccoutInfo() {
		return account[0];
	}

	//get Account#
	public string getAccountNo(){
		return lead == null ? '' : CommUtils.nullToBlank(lead.No__c);
	}

	//get 'お客様'
	public string getCustomer(){
		String cuName = parMap.containsKey('cuName') ? parMap.get('cuName') : 
									CommUtils.isBlank(singelAccount.AccountName__c) ?  CommUtils.nullToBlank(contactName)  :  singelAccount.AccountName__c;
		return (CommUtils.isBlank(cuName) ? '　' : cuName);
	}

	//get '$売上計IV（税込）金額'
	public Decimal getCharge(){
		return amoutAllMoney;
	}
	// 請求金額設定
	public Decimal getRequestAmount() {
		// 新会計モードの場合
		// 割引金額を取得する
		// 利用総金額
		Decimal remaindPayMoney = CommUtils.nullToZero(amoutAllMoney) + CommUtils.nullToZero(amoutIncSpecialPrice);
		
		// 支払
		Decimal requestAmountVal = 0;
		// 割引金額が存在する場合、優先で利用する
		if (amountAllDiscount > 0) {
			// 未支払金額は割引金額により、大きく場合、全額割引金額を使う
			if (remaindPayMoney >= amountAllDiscount) {
				remaindPayMoney = remaindPayMoney - amountAllDiscount;
			} 
			// 割引金額は全額支払できるの場合
			else {
				remaindPayMoney = 0;
			}
		}
		// クーポン支払金額が存在する場合
		if (amoutAllCoupon > 0) {
			// 起動の会計画面の[クーポン利用の返金]はONの場合
			boolean coponManasFlg = singelAccount.CouponReturnFlg__c;
			if (remaindPayMoney >= amoutAllCoupon) {
				remaindPayMoney = remaindPayMoney - amoutAllCoupon;
			} else {
				remaindPayMoney = coponManasFlg ? (remaindPayMoney - amoutAllCoupon) : 0;
			}
		}
		// 2018/02/28 支払種別は「雑損」を作成したい WGCH BEGIN
		for(AmoutCustomPay itemAmout : amoutCustomPayLst){
			remaindPayMoney -= itemAmout.amoutAllCustomPay;
		}
		// 2018/02/28 支払種別は「雑損」を作成したい WGCH END
		return (	
			remaindPayMoney -
			CommUtils.nullToZero(amoutAllCash) - 
			CommUtils.nullToZero(amoutAllCredit) - 
			getAdvancesReceived() + 
			CommUtils.nullToZero(amountRefundPrice)	// 返金計算する
			- allPlusPayAmount	// 差分金額を調整（為替　＆＆　変換前の請求金額は０の場合
		);
	}
	// 2018/02/28 支払種別は「雑損」を作成したい WGCH BEGIN
	public List<AmoutCustomPay> amoutCustomPayLst;
	public class AmoutCustomPay{
		public AmoutCustomPay(Decimal varItemAmount){
			amoutAllCustom = varItemAmount;
			amoutAllCustomPay = varItemAmount;
		}
		public Decimal amoutAllCustom;
		public Decimal amoutAllCustomPay;
	}
	// 2018/02/28 支払種別は「雑損」を作成したい WGCH END
	//get Tax
	public Decimal getTax(){
		// 会計日付にて、消費税計算を行う[会計日付から税率を取得する][連泊場合：初日の税率で]
		// 消費税機能変更対応
		// 2019/10/11 サービス料を含む商品を予約見積明細の請求書の消費税が正しい金額になっておりませんの不具合対応 BY zyz BEGIN
		// Decimal taxRate = CommUtils.nullToZero(account[0].TaxRate__c);
		Decimal taxRate = 0;
		// 2019/10/11 サービス料を含む商品を予約見積明細の請求書の消費税が正しい金額になっておりませんの不具合対応 BY zyz END
		// 会計に該当消費税が未設定する場合、会計に所属する会計明細から消費税率を取得する
		if (taxRate == 0) {
			List<BookingEstimateItem__c> taxItems = [ select TaxRate__c from BookingEstimateItem__c
													where refBooking__c = :leadIds and Accountoutside__c = 1
													And ParentBookingItemRef__c = null
													// And InvoiceNoShowFlg__c = false
													And TaxRate__c > 0 limit 1];
			if (!taxItems.isEmpty()) taxRate = taxItems[0].TaxRate__c;
			// 2019/10/11 サービス料を含む商品を予約見積明細の請求書の消費税が正しい金額になっておりませんの不具合対応 BY zyz BEGIN
			else taxRate = CommUtils.nullToZero(account[0].TaxRate__c);
			// 2019/10/11 サービス料を含む商品を予約見積明細の請求書の消費税が正しい金額になっておりませんの不具合対応 BY zyz END
		}
		// 2014/07/18 為替レート変更機能対応（USD→JPY）[通貨変更表示する場合、日本の消費率で内消費税を計算する]
		if (exchangeRateFlg) { 
			taxRate = CommUtils.nullToZero(singelAccount.ExchangeTaxRate__c) == 0 
						? CommUtils.nullToZero(CommDefine__c.getOrgDefaults().ExchangeTaxRate__c)
						: CommUtils.nullToZero(singelAccount.ExchangeTaxRate__c);
		}
		// 消費税計算を行う：課税商品金額(税込) + サービス料(税込)　- 割引金額
		if ( amoutIncTaxprice > 0 ) {
			Decimal locAmoutIncTaxprice = amoutIncTaxprice
			                   - CommUtils.nullToZero(amountAllDiscount);
			// TODO 消費税マスタの関連設定を再設定を行う
			// 2014/07/02 USD機能対応
			Integer pointLen = CommUtils.getPointLen();
			// 2019/04/30 増税仮対応 BY zyz BEGIN
			// return (locAmoutIncTaxprice > 0 ? CommUtils.RoundProcess(locAmoutIncTaxprice / (1 + taxRate / 100) * (taxRate / 100), pointLen) : 0);
			return (locAmoutIncTaxprice > 0 ? CommUtils.RoundProcess(locAmoutIncTaxprice / (1 + taxRate / 100) * (taxRate / 100) + taxIncMstTaxprice, pointLen) : 0);
			// 2019/04/30 増税仮対応 BY zyz END
		} else {
			// 2019/04/30 増税仮対応 BY zyz BEGIN
			// return 0;
			return 0 + taxIncMstTaxprice;
			// 2019/04/30 増税仮対応 BY zyz END
		}
	}

	//get '$会計日付'
	public Date getIssueDate(){
		Date parDate = null;
		try {
			// 請求日
			String pDate = parMap.get('pdt');
			if (!CommUtils.isBlank(pDate)) {
				// 2016/11/25 TIMEZON fix BEGIN by zh
				parDate = CommUtils.stringToDate(pDate);
				// 2016/11/25 TIMEZON fix END by zh
			}
		} catch (Exception e) {}
		// 2019/10/30 見積の発行日付のデフォルト値を制御フラグ BY zyz BEGIN
		if (parDate != null) {
			return parDate;
		}
		if(lead != null){
			if(lead.LeadReceiptDate__c != null) return lead.LeadReceiptDate__c;
		}
		if ( account[0].IssueDate__c != null) {
		// 2019/10/30 見積の発行日付のデフォルト値を制御フラグ BY zyz END
			return account[0].IssueDate__c;
		}
		else if ( account[0].Field148__c != null ) {
			return account[0].Field148__c;
		} else {
			return Date.today();
		}
	}
	// 前受付金
	public Decimal getAdvancesReceived() {
		return CommUtils.nullToZero(amoutARprice) + CommUtils.nullToZero(amoutAllSubscription);
	}
	//get '会計明細'
	public List<TranItem> getTran(){
		return tran;
	}
	// 割引合計
	public Decimal getAmoutIncDiscont() {
		return amountAllDiscount;
	}
	// ご利用日
	public String getServiceDate() {
		return getAccoutInfo().Relreserve__r.EntryTime__c != null ? getAccoutInfo().Relreserve__r.EntryTime__c.format('yyyy年MM月dd日') : '    　  　　　';
	}
	// 2013/11/14 ADD 店舗コードにより、請求書関連振り込み情報を設定
	private void setPayeeInfo() {
		User loginUser = UserUtil.CurrentUser;
		// 店舗コードが存在する場合
		// 2015/09/01 多店舗機能対応 BEGIN
		if (!CommUtils.isBlank(shopCd)) {
		// 2015/09/01 多店舗機能対応 END
			List<ShopInformation__c> shops = [select PayeeAcount__c, Payee1__c, Payee2__c, Payee3__c from ShopInformation__c where ShopCode__c = :shopCd];
			if (shops.isEmpty()) {
				payee1 = CommDefine__c.getInstance().FacilityPayee1__c;
				payee2 = CommDefine__c.getInstance().FacilityPayee2__c;
				payee3 = CommDefine__c.getInstance().FacilityPayee3__c;
				payeeAcount = CommDefine__c.getInstance().FacilityPayeeAcount__c;
			} else {
				payee1 = shops[0].Payee1__c;
				payee2 = shops[0].Payee2__c;
				payee3 = shops[0].Payee3__c;
				payeeAcount = shops[0].PayeeAcount__c;
			}
		} else {
			payee1 = CommDefine__c.getInstance().FacilityPayee1__c;
			payee2 = CommDefine__c.getInstance().FacilityPayee2__c;
			payee3 = CommDefine__c.getInstance().FacilityPayee3__c;
			payeeAcount = CommDefine__c.getInstance().FacilityPayeeAcount__c;
		}
	}
	// 2012/10/11 ADD 振込先情報を入れる
	// 2015/12/03 換行 Fix BEGIN
	// 2016/01/12 自動改行制御機能追加 BEGIN
	public AccountAcount__c comment{get{
		// 改行の文字はREPELACEする
		String orgCommentStr = CommUtils.nullToBlank(parMap.get('comment'));
		if(CommUtils.isBlank(orgCommentStr) && lead != null) orgCommentStr = CommUtils.nullToBlank(lead.QuotationComment__c);
		AccountAcount__c acc = new AccountAcount__c(comment__c = orgCommentStr);
		if (isCommentAutoBreakFlg) {
			acc.comment__c = CommRepUtils.getPdfMaxShowStringNew(orgCommentStr,4,18);
		}
		return acc;
	}}
	// 2016/01/12 自動改行制御機能追加 END
	// 2015/12/03 換行 Fix END
	public String payee1{get; private set;}
	public String payee2{get; private set;}
	public String payee3{get; private set;}
	public String payeeAcount{get; private set;}
	// 2019/1/15 請求書に掲載する振込先口座情報を、同一店舗内で切り替えする BY cxw BEGIN
	public List<String> lstFixelMsg{get; private set;}
	public Boolean isFiexlMsg{get{return !CommUtils.isBlank(parMap.get('fixedMsg'));} private set;}
	// 2019/1/15 請求書に掲載する振込先口座情報を、同一店舗内で切り替えする BY cxw END
	/**
	* 2016/03/31 サビース料金は明細として、請求書に表示の対応
	**/
	private void setServiceDetailInfo() {
		// サビース料情報
		Decimal noServiceAmount = 0;
		// サビース料抜き合計金額
		for (TranItem item : tran) {
			if (item.isPayTranItem) continue;
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			if (item.pBrkDNFlg) continue;
			// 2019/07/30 軽減税率機能対応 WGCH END
			noServiceAmount += item.amout;
		}
		Decimal fullAmoutAllMoney = CommUtils.nullToZero(amoutAllMoney) + CommUtils.nullToZero(amoutIncSpecialPrice);
		Decimal serviceRate = fullAmoutAllMoney - noServiceAmount;
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		if(isReducedTaxFlg) serviceRate = serviceAmountEnd;
		// 2019/07/30 軽減税率機能対応 WGCH END

		if (serviceRate > 0) {
			// 明細にサビース料情報を追加表示する
			TranItem serviceItem = new TranItem(new Tran1__c(
							   Field5__c = (isForeignCurrency == true ? 'Service Charge' : 'サービス料'),
							   Field20__c = String.valueOf(serviceRate),
							   Field21__c = '1',
							   // 2019/07/30 軽減税率機能対応 WGCH BEGIN
							   RowNo__c = isReducedTaxFlg ? CommUtils.nullToZero(rowNoEnd) : (tran.size() + 1)),
							   // 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
							   // isReducedTaxFlg ? rowNoEnd : (tran.size()+1), pointlen);
							   isReducedTaxFlg ? rowNoEnd : (tran.size()+1), pointlen, false);
							   // 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
							   rowNoEnd ++;
							   // 2019/07/30 軽減税率機能対応 WGCH END
			for (Integer i = tran.size() - 1; i >= 0; i--) {
				TranItem preItem = tran[i];
				if (preItem.usedDate != null) {
					serviceItem.usedDate = preItem.usedDate;
					break;
				}
			}
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			if(isReducedTaxFlg){
				serviceItem.taxUnitPrice = serviceTaxAmountEnd;
				serviceItem.isServieFlg = true;
			}
			// 2019/07/30 軽減税率機能対応 WGCH END
			tran.add(serviceItem);
		}
	}
	// サビース料金は明細として、請求書に表示の対応[サービス料表示モード２] BEGIN
	public Boolean gServiceOuputFlg{get; private set;}
	public Boolean gIsServieModeOuter{get; private set;}
	// 2017/07/20 サビース料税別区分 zyz BEGIN
	public Boolean gserviceNoTaxFlg{get; private set;}
	private Decimal exchageServiceAmount = 0;
	// 2017/07/20 サビース料税別区分 zyz END
	private Decimal serviceAmount = 0;
	public Decimal getServiceAmount(){
		if (gIsServieModeOuter) {
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			if(isReducedTaxFlg) return serviceAmountEnd;
			// 2019/07/30 軽減税率機能対応 WGCH END
			// 2017/07/20 サビース料税別区分 zyz BEGIN
			if (exchangeRateFlg) {
				return exchageServiceAmount;
			} else
			// 2017/07/20 サビース料税別区分 zyz END
			return serviceAmount;
		} else return null;
	}
	// サビース料金は明細として、請求書に表示の対応[サービス料表示モード２] END
	public class TranItem {
		// 明細番号
		public Integer rowNo{get; private set;}
		// 商品名
		public String produceNm{get; private set;}
		// 価格
		public Decimal unitPrice{get{return (isReFundFlg == true ? Math.abs(unitPrice) : unitPrice);} private set;}
		// 数量
		public Decimal quantity{get; private set;}
		// 利用日
		public String usedDate{get; private set;}
		// 合計金額[NULLに設定するのは、空白行の場合、金額非設定にする]
		public Decimal amout{get{return CommUtils.RoundProcess(CommUtils.nullToZero(unitPrice) * CommUtils.nullToZero(quantity), pointlen);}}
		// 小数点桁数数
		private Integer pointlen;
		// ▲表示・非表示対応
		public boolean isShowCircle{get; private set;}
		// 特別税
		public Decimal specialTax{get; private set;}
		// 明細情報は返金するがどうか、標識フラグ
		public Boolean isReFundFlg{get; private set;}
		// 支払情報するがどうか
		public Boolean isPayTranItem{get; private set;}
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		public Tran1__c sobj{get; private set;}
		public String tranId{get{ return CommUtils.nullToBlank(sobj.Field11__c);} private set;}
		public Boolean isPaymentInfo{get{ return isPayTranItem;} private set;}
		public Boolean isServieFlg{get; private set;}        // サービス料行Flg
		public Decimal taxUnitPrice{get; private set;}        // 消費税金額
		public Decimal taxRate{get; private set;}             // 消費税率
		public Decimal serviceRate{get; private set;}
		public Boolean planFlg{get; private set;}
		public Boolean pBrkDNFlg{get; private set;}
		// 2019/07/30 軽減税率機能対応 WGCH END
		// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
		public TranItem(Tran1__c sobj, Integer index, Integer pPointLen ,Boolean isBlankFlg) {
			blankFlg = isBlankFlg;
			// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
			rowNo = index;
			pointlen = pPointLen;
			if (index == null) return;
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
			// Integer maxLen = 55;
			// if(isReducedTaxFlg) maxLen -= 4;
			// produceNm = CommRepUtils.getPdfMaxShowString(sobj.Field5__c, maxLen);
			produceNm = sobj.Field5__c;
			proNum = 0;
			// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
			// 2019/07/30 軽減税率機能対応 WGCH END
			unitPrice = CommUtils.nullToZero(sobj.Field20__c);
			quantity = CommUtils.nullToZero(sobj.Field21__c);
			// 利用日表示対応 2015/07/30 BEGIN
			Date lUseDate = (sobj.UseDate__c == null ? sobj.RelAccount__r.Salesday__c : sobj.UseDate__c) ;
			if (lUseDate != null) {
				DateTime dt = (DateTime.newInstance(lUseDate, Time.newInstance(0,0,0,0)));
				usedDate = dt.format(CommBaseCtrl.getDateFormat());
			}
			// 返金情報チェック
			isReFundFlg = sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_AR && BillSimpleHelp.isRefundItem(sobj.PaymentType__c);
			
			// 利用日表示対応 2015/07/30 END
			// 返金じゃないの前受金の場合
			if (sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_AR && !isReFundFlg) isShowCircle = true;
			else isShowCircle = false;
			// 宿泊税情報格納する
			specialTax = CommUtils.nullToZero(sobj.SpecialTax__c);
			// 支払情報判断フラグ
			isPayTranItem = (	sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_AR ||
								sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PY);
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			this.sobj = sobj;
			// 消费税率
			taxRate = CommUtils.nullToZero(sobj.TaxRate__c) / 100;
			serviceRate = CommUtils.nullToZero(sobj.ServiceRate__c) / 100;
			// 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH BEGIN
			// planFlg = isPlanBrkShowFlg && (sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PL);
			planFlg = isPlanBrkShowFlg && (sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) && pBrkTranItemMap != null && pBrkTranItemMap.containsKey(tranId);
			// 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH END
			isServieFlg = pBrkDNFlg = false;
			taxUnitPrice = 0;
			// 2019/07/30 軽減税率機能対応 WGCH END
    	}
		public Boolean isShowInfo{get{return (rowNo != null);}}
		// 2015/11/25 支払メデイアコード情報を格納
		public String payMediaCode{get;set;}
		// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
		// 商品占用行数
		public Integer proNum{get; private set;}
		// 改行後の文字列情報を格納する
		public List<String> produceNms{get; private set;}
        public Boolean blankFlg{get; private set;}
		// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
	}
	// 2017/11/02 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
	private void accountsName(String accName,TranItem item) {
		integer splitCodeNum = 32;
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		if(isReducedTaxFlg) splitCodeNum -= 2;
		// 2019/07/30 軽減税率機能対応 WGCH END
		if ( accName.length() > splitCodeNum) {
			// 商品名截取多行显示
			if (isAccountProdNmReturnFlg) {
				if (!proNameMap.containsKey(accName)) {
					// PAGE_FIRSTPG_BREAK_RSNUM = 28	/ PAGE_NEXTPG_BREAK_RSNUM = 42
					List<String> retArr = CommRepUtils.getPdfMaxShowStringNews(accName,PAGE_FIRSTPG_BREAK_RSNUM,splitCodeNum,true);
					proNameMap.put(accName,retArr);
				}
				item.produceNms = proNameMap.get(accName);
				item.proNum = (item.produceNms.isEmpty() ? 0 : (item.produceNms.size() -1));
			} else {
				// 商品名截取一行显示
				//item.produceNm = accName.left(splitCodeNum);
				item.produceNm = CommRepUtils.getPdfMaxShowStringNew(accName,1,splitCodeNum);
			}
		}
	}
	// 2017/11/02 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
	private List<Tran1__c> tranRsLst; //利用明細情報を格納する
	private List<TTend__c> ttendLst;  //支払明細情報を格納する
	private Date salesdayCal; // $営業日付
	private String contactName; // お客様名
	private Map<String, Decimal> noTaxUnitPriceSumMap;
	private Set<id> leadIds;
	private Lead__c lead;
	private void getEstInfoByLead(String leadId) {
		ttendLst = new List<TTend__c>();
		tranRsLst = new List<Tran1__c>();
		account = new List<AccountAcount__c>();
		noTaxUnitPriceSumMap = new Map<String, Decimal>();
		List<Lead__c> leadLst = [select id, No__c, QuotationComment__c, QuotationName__c, LeadPdfShopCode__c, LeadReceiptDate__c, EntryTime__c, ExchangeTaxRate__c, Relcontact__r.LastName, Relcontact__r.FirstName,
					// 2018/06/08 レシート印刷機能言語選択する WGCH BEGIN
					Language__c,
					// 2018/06/08 レシート印刷機能言語選択する WGCH END
					// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH BEGIN
					BillSaveFlg__c,
					AccountReceiptName__c,
					BillingCal__c,
					AccountProviso__c,
					// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH END
					// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
					RespectLst__c,
					// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
					// 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH BEGIN
					ShopCodeCal__c,
					// 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH END
					LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c
					from Lead__c where id = : leadId];
		if(leadLst.isEmpty()) return;
		lead = leadLst[0];
		LeadPDF helpPdf = new LeadPDF();
		// 支払情報ラベル変換情報を取得する
		BillSimpleHelp billHelp = new BillSimpleHelp('');
		Map<String, String> payTypeToMediaLabMap = billHelp.getPaymentTypeToMediaLabMap();
		// 2019/04/30 チェックインをかけなくても請求書が１枚に印刷されるようにご希望です by zy BEGIN
		if (CommConst.BILL_ALLLEADPDF_FLG) leadIds = getRealLeadIds(lead);
		else leadIds = helpPdf.getRealLeadIds(lead);
		// 2019/04/30 チェックインをかけなくても請求書が１枚に印刷されるようにご希望です by zy END
		
		/* singelAccount作成 */
		singelAccount = new AccountAcount__c(
					Relreserve__c = lead.id,
					ExchangeTaxRate__c = lead.ExchangeTaxRate__c,
					// SalesdayCal__c = // $営業日付
					AccountName__c = lead.QuotationName__c,
					IsNewLayout__c = true,
					// ContactName__c = // お客様名
					CouponReturnFlg__c = false);
		RsvAccount__c rsvs = new RsvAccount__c(Name = lead.EntryTime__c.format('yyyyMMdd'));
		// 数式項目を再計算を行う
		rsvs.recalculateFormulas();
		salesdayCal = rsvs.Salesday__c;
		contactName = CommUtils.nullToBlank(lead.Relcontact__r.LastName) + ' ' + CommUtils.nullToBlank(lead.Relcontact__r.FirstName);
		
		for(Lead__c ld : [select id, QuotationName__c, EntryTime__c, ExchangeTaxRate__c,
							LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c
							from Lead__c where id in: leadIds]) {
			account.add( new AccountAcount__c(
									Relreserve__c = ld.id,
									// SalesdayCal__c = // $営業日付
									IsNewLayout__c = true,
									// IssueDate__c
									// Field148__c => Field53__c
									TaxRate__c = ld.ExchangeTaxRate__c,
									CouponReturnFlg__c = false,
									Relreserve__r = ld.clone()));
		}
		// 2018/06/08 レシート印刷機能言語選択する WGCH BEGIN
		Boolean wkIsForeignCurrency = CommUtils.isForeignCurrency(CommUtils.isBlank(lead.Language__c) ? UserInfo.getDefaultCurrency() : lead.Language__c);
		// 2018/06/08 レシート印刷機能言語選択する WGCH END
        // 2019/04/30 増税仮対応 BY zyz BEGIN
		CommLogicProcess.TaxIncMstInfo info = CommLogicProcess.getTaxIncMstInfo();
		// 增税商品的Id
		id taxIncMstId = !CommUtils.isBlank(info.taxIncMstId) ? info.taxIncMstId : null;
        // 2019/04/30 増税仮対応 BY zyz END
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		/*
		for(BookingEstimateItem__c s: [select id, name, X2_1__c, Tankanonetax__c, Amount__c,TaxRate__c, UnitPriceDefKbCal__c,
						SCP_5__c, UnitPriceDefKb__c,
						refBooking__c, refBooking__r.Id, refBooking__r.Rroom__c, refBooking__r.LeadIndexRef__c, refBooking__r.LeadIndexSubId__c, refBooking__r.RoomGroupNo__c, refBooking__r.UnitPriceDefKb__c,
						refAccountMaster__c, refAccountMaster__r.Field5__c, refAccountMaster__r.ServiceRate__c, refAccountMaster__r.SpecialTax__c, refAccountMaster__r.TaxRateCal__c,
						// 2018/06/08 レシート印刷機能言語選択する WGCH BEGIN
						refAccountMaster__r.ProductEnName__c,
						// 2018/06/08 レシート印刷機能言語選択する WGCH END
						ActionType__c,PaymentType__c,
						refBooking__r.EntryTime__c,UseDate__c,refBooking__r.Departure__c,
						Total__c, ServiceRate__c, SpecialTax__c,GoukeinoneTax__c,UnitPrice__c, ProductName__c,SpTotal__c,rowNo__c
						,(select UnitPrice__c from ParentBookingItemRef__r where (TaxRate__c = null OR TaxRate__c = 0) And ParentBookingItemRef__r.ActionType__c = :CommConst.PROD_ACTION_TYPE_PL)
						from BookingEstimateItem__c
						where refBooking__c = :leadIds
						and Accountoutside__c = 1
						And InvoiceNoShowFlg__c = false
						order by UseDate__c, rowNo__c, Name]) {
		*/
		List<BookingEstimateItem__c> bookLst = [select id, name, X2_1__c, Tankanonetax__c, Amount__c,TaxRate__c, UnitPriceDefKbCal__c,
						SCP_5__c, UnitPriceDefKb__c,
						refBooking__c, refBooking__r.Id, refBooking__r.Rroom__c, refBooking__r.LeadIndexRef__c, refBooking__r.LeadIndexSubId__c, refBooking__r.RoomGroupNo__c, refBooking__r.UnitPriceDefKb__c,
						refAccountMaster__c, refAccountMaster__r.Field5__c, refAccountMaster__r.ServiceRate__c, refAccountMaster__r.SpecialTax__c, refAccountMaster__r.TaxRateCal__c,
						// 2018/06/08 レシート印刷機能言語選択する WGCH BEGIN
						refAccountMaster__r.ProductEnName__c,
						// 2018/06/08 レシート印刷機能言語選択する WGCH END
						// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
						OptionPlanKey__c,
						// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
						ActionType__c,PaymentType__c,
						refBooking__r.EntryTime__c,UseDate__c,refBooking__r.Departure__c,
						Total__c, ServiceRate__c, SpecialTax__c,GoukeinoneTax__c,UnitPrice__c, ProductName__c,SpTotal__c,rowNo__c
						,ParentBookingItemRef__r.TaxRate__c,ParentBookingItemRef__r.ActionType__c, ParentBookingItemRef__r.InvoiceNoShowFlg__c, ParentBookingItemRef__r.UnitPrice__c
						,ParentBookingItemRef__c, AccountOutside__c
						from BookingEstimateItem__c
						where refBooking__c = :leadIds
						And InvoiceNoShowFlg__c = false
						order by UseDate__c, rowNo__c, Name];
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
		CommLogicProcess.OptionPlanInfo optionItem = null;
		if(isReducedTaxFlg && CommConst.OPTION_MODE == CommConst.OPTION_MODE_ON){
			optionItem = CommLogicProcess.getOptionPlanInfo(bookLst);
		}
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
		List<BookingEstimateItem__c> newBookLst = new List<BookingEstimateItem__c>();
		// 初始化
		reducedTaxInit();
		pBrkTranItemMap = new Map<String, List<TranItem>>();
		pBrkProMap = new Map<String, CommUtils.ProductInfo>();
		planHeaderMap = new Map<String, CommUtils.ProductInfo>();
		// 2015/09/01 多店舗機能対応 BEGIN
		shopCd = ApexPages.currentPage().getParameters().get('shopcd');
		String[] shops = ShopInfoUtil.getCanSelectShopLst(UserInfo.getUserId());
		if (CommUtils.isBlank(shopCd) && shops.Size() > 0 && lead != null) shopCd = lead.LeadPdfShopCode__c;
		// 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH BEGIN
		// if (CommUtils.isBlank(shopCd)) shopCd = UserUtil.CurrentUser.ShopCode__c;
		if (CommUtils.isBlank(shopCd)){
			shopCd = UserUtil.CurrentUser.ShopCode__c;
			// 获取店铺默认设定Code
			shopCd = ShopInfoUtil.getShopDefCd(shopCd, lead.ShopCodeCal__c, UserUtil.CurrentUser.ShopCode__c);
		}
		// 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH END
		// 2015/09/01 多店舗機能対応 END
		// USER INFO
		String currencyInf = UserInfo.getDefaultCurrency();					// ログインユーザーの組織通貨を取得する
		String orgCurrency = currencyInf;									// ログインユーザーの組織通貨
		if (CommUtils.isBlank(currencyInf)) currencyInf = 'JPY';		// 組織通貨設定がNULLの場合、通貨JPY(日本円)に設定する
		// 請求書起動WindowからURLのパラメータが存在すると、外貨から日本円変換、表示処理FLGをTrueにする
		exchangeRateFlg = ApexPages.currentPage().getParameters().containsKey('cy'); // パラメータに存在設定する場合、以下の通貨から日本円に変更を行う（施設23/24のみパラメータ設定を行う)
		// TRUEの場合、元の通貨から日本円に変更を行う
		if (exchangeRateFlg) {
			currencyInf = 'JPY';	// JPY以外からJPY通貨変更の場合、表示の通貨はJPYに設定する
		}
		pointlen = CommUtils.getPointLen(currencyInf);	// 指定の通貨により、小数点桁数を取得する
		map<string,CommLogicProcess.HotelTaxDefineInfo> hotelTaxMap = CommLogicProcess.getHotelTaxDefInstance();
		for(BookingEstimateItem__c s : bookLst){
			// 合成明细Key
			String key = s.ParentBookingItemRef__c;
			// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
			if(optionItem != null && !optionItem.planEstIdSet.isEmpty() && CommUtils.isBlank(key) && !optionItem.planEstIdSet.contains(s.Id)) continue;
			// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
			if(isReducedTaxFlg && !CommUtils.isBlank(key) && (s.ParentBookingItemRef__r.InvoiceNoShowFlg__c != true)){
				
				// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
				if(optionItem != null){
					if(!optionItem.planEstIdSet.isEmpty() && !optionItem.planEstIdSet.contains(key)) continue;
					if(optionItem.planHeaderKeyMap.containsKey(key)){
						String planHeaderNumKey = optionItem.planHeaderKeyMap.get(key);
						s.Amount__c = CommUtils.nullToZero(optionItem.planHeaderNumMap.get(planHeaderNumKey));
					}
				}
				// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
				// 2018/06/08 レシート印刷機能言語選択する WGCH BEGIN
				if(wkIsForeignCurrency && !CommUtils.isBlank(s.refAccountMaster__r.ProductEnName__c)) s.ProductName__c = s.refAccountMaster__r.ProductEnName__c;
				// 2018/06/08 レシート印刷機能言語選択する WGCH END
				// 商品種別取得する
				String actType = CommUtils.nullToBlank(s.ActionType__c);
				// 売上
				RsvAccount__c rsv = new RsvAccount__c(Name = lead.EntryTime__c.format('yyyyMMdd'));
				// 数式項目を再計算を行う
				rsv.recalculateFormulas();
				// 2019/04/30 増税仮対応 BY zyz BEGIN
				if(taxIncMstId == s.refAccountMaster__c  && taxIncMstId != null)  taxIncMstTaxprice += CommUtils.nullToZero(s.Total__c);
				// 2019/04/30 増税仮対応 BY zyz END
				// 会計
				AccountAcount__c accItem = new AccountAcount__c(Relreserve__r = s.refBooking__r);
				Decimal unitPrice = (s.UnitPrice__c == null ? s.refAccountMaster__r.Field5__c : s.UnitPrice__c);
				Decimal serviceRate = (s.ServiceRate__c == null ? s.refAccountMaster__r.ServiceRate__c : s.ServiceRate__c);
				Decimal specialTax = (s.SpecialTax__c == null ? s.refAccountMaster__r.SpecialTax__c : s.SpecialTax__c);
				Decimal taxRate = (s.TaxRate__c == null ? s.refAccountMaster__r.TaxRateCal__c : s.TaxRate__c);
				// 2016/12/27 見積明細利用日機能対応 BEGIN zyz
				Date useDate = s.refBooking__r.EntryTime__c.date();
				// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH BEGIN
				// if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI) {
				if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI && !CommConst.BOOKEST_USERDATE_FLG) {
				// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH END
					useDate = s.refBooking__r.Departure__c.date();
				}
				Tran1__c tran = new Tran1__c();
				tran.AccountProviso__c = s.Id;
				// $合計金額(税込)
				tran.Field23__c = String.valueOf(s.Total__c); // Field41__c $合計金額（税込） = 数式 (通貨)
				// 数式項目を再計算を行う
				tran.recalculateFormulas();
				// 2013/08/22 編集後の商品名称で会計明細に設定を行う
				tran.Field5__c = s.ProductName__c;
				// 会計
				tran.Field1__c  = s.refBooking__c;
				// 商品処理種別
				tran.ActionType__c = s.ActionType__c;
				// 消費税
				tran.TaxRate__c = taxRate;
				// サービス料
				tran.ServiceRate__c = serviceRate;
				// 特別税
				tran.SpecialTax__c = specialTax;
				// 単価(税込)
				tran.Field20__c = String.valueOf(unitPrice);
				// 数量
				tran.Field21__c = String.ValueOf(s.Amount__c);
				// 2014/08/15 単価定義区分コピー
				tran.UnitPriceDefKb__c = !CommUtils.isBlank(s.UnitPriceDefKb__c) ?  s.UnitPriceDefKb__c : 
																					( !CommUtils.isBlank(s.refBooking__r.UnitPriceDefKb__c) ? s.refBooking__r.UnitPriceDefKb__c : '2' );
				// POSNo.
				tran.POSNo__c = CommUtils.getPosNoByComdefine();
				// RowNo__cコピー追加
				tran.RowNo__c = s.RowNo__c;
				// 2015/02/09 支払種別コピー追加
				tran.PaymentType__c = s.PaymentType__c;
				// 見積明細利用日
				tran.UseDate__c = (s.UseDate__c == null ? useDate : s.UseDate__c);
				tran.RelAccount__r = rsv.clone(); // 予約会計 = 主従関係(売上) Salesday__c[数式] => Name
				tran.Field1__r = accItem.clone(); // レシートＮｏ． = 参照関係(会計)
				// 2019/04/30 チェックインをかけなくても請求書が１枚に印刷されるようにご希望です by zy BEGIN
				tran.Field49__c = s.name;
				// 2019/04/30 チェックインをかけなくても請求書が１枚に印刷されるようにご希望です by zy END
				tran.Field11__c = s.Id;
				CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(tran.UnitPriceDefKb__c));
				// 元の単価から、税抜金額を外して、税込み金額を計算する
				CommLogicProcess.HotelTaxInfo hotelTaxItem = CommLogicProcess.getHotelTaxInfo(CommUtils.nullToBlank(shopCd), CommUtils.nullToBlank(tran.ActionType__c), CommUtils.nullToZero(tran.Field20__c), CommUtils.nullToZero(tran.Field21__c), tran.TaxRate__c, tran.ServiceRate__c, priceInfo, hotelTaxMap);
				priceInfo = hotelTaxItem.priceInfo;
				if(!planHeaderMap.containsKey(key)) planHeaderMap.put(key, new CommUtils.ProductInfo(CommUtils.nullToIntZero(s.UnitPriceDefKbCal__c)));
				CommUtils.ProductInfo headerPriceInfo = planHeaderMap.get(key);
				// 合计header数据处理
				headerPriceInfo.getAddPriceInfo(priceInfo);
				// BRK-INFO
				// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
				// TranItem item = new TranItem(tran, 0, pointlen);
				TranItem item = new TranItem(tran, 0, pointlen, false);
				// 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
				// 最终单价重置
				item.unitPrice = priceInfo.unitPriceTax;
				// 最终消费税重置
				item.taxUnitPrice = priceInfo.priceTax;
				// 明细对应的priceInfo
				pBrkProMap.put(item.tranId, priceInfo);
				if(!pBrkTranItemMap.containsKey(key)) pBrkTranItemMap.put(key, new List<TranItem>());
				pBrkTranItemMap.get(key).add(item);
			}
			// 获取子明细数据集计非课税商品
			if(s.ParentBookingItemRef__r.ActionType__c == CommConst.PROD_ACTION_TYPE_PL && (s.TaxRate__c == null || s.TaxRate__c == 0)){
				if(!noTaxUnitPriceSumMap.containsKey(key)) noTaxUnitPriceSumMap.put(key, 0);
				Decimal noTaxUnitPriceSum = CommUtils.nullToZero(s.UnitPrice__c) + noTaxUnitPriceSumMap.get(key);
				noTaxUnitPriceSumMap.put(key, noTaxUnitPriceSum);
			}
			if(s.Accountoutside__c == 1 && CommUtils.isBlank(key)) newBookLst.add(s);
		}
		for(BookingEstimateItem__c s : newBookLst){
		// 2019/07/30 軽減税率機能対応 WGCH END
			// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
			if(optionItem != null && optionItem.planHeaderKeyMap.containsKey(s.Id)){
				String planHeaderNumKey = optionItem.planHeaderKeyMap.get(s.Id);
				s.Amount__c = CommUtils.nullToZero(optionItem.planHeaderNumMap.get(planHeaderNumKey));
				s.SpecialTax__c = CommUtils.nullToZero(optionItem.planHeaderTaxMap.get(planHeaderNumKey));
			}
			// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
			// 2018/06/08 レシート印刷機能言語選択する WGCH BEGIN
			if(wkIsForeignCurrency && !CommUtils.isBlank(s.refAccountMaster__r.ProductEnName__c)) s.ProductName__c = s.refAccountMaster__r.ProductEnName__c;
			// 2018/06/08 レシート印刷機能言語選択する WGCH END
			// 商品種別取得する
			String actType = CommUtils.nullToBlank(s.ActionType__c);
			// 売上
			RsvAccount__c rsv = new RsvAccount__c(Name = lead.EntryTime__c.format('yyyyMMdd'));
			// 数式項目を再計算を行う
			rsv.recalculateFormulas();
			// 2019/04/30 増税仮対応 BY zyz BEGIN
			if(taxIncMstId == s.refAccountMaster__c  && taxIncMstId != null)  taxIncMstTaxprice += CommUtils.nullToZero(s.Total__c);
			// 2019/04/30 増税仮対応 BY zyz END
			// 会計
			AccountAcount__c accItem = new AccountAcount__c(Relreserve__r = s.refBooking__r);
			// 商品種別は支払場合、支払情報を設定する
			if (actType == CommConst.PROD_ACTION_TYPE_PY) {
				// 支払メデイアに変換
				String mediaName = payTypeToMediaLabMap.get(s.PaymentType__c);
				if (CommUtils.isBlank(mediaName)) mediaName = CommConst.MEDIA_TYPE_01;
				String paymentCd = CommConst.getMediaCodeByMediaName(mediaName);
				Date useDate = s.refBooking__r.EntryTime__c.date();
				TTend__c tend = new TTend__c();
				// 画面に入力金額は預かり金額に更新
				tend.Field19__c = CommUtils.nullToBlank(s.Total__c); // Field28__c $預かり　金額 = 数式 (通貨)
				// 利用金額
				tend.Field20__c = CommUtils.nullToBlank(s.Total__c); // Field29__c $支払　金額 = 数式 (通貨)
				// お釣り金額
				tend.Field21__c = CommUtils.nullToBlank(0); // Field30__c $釣銭（差額）金額 = 数式 (通貨)
				// 数式項目を再計算を行う
				tend.recalculateFormulas();
				// 支払方法
				tend.Field2__c = paymentCd;
				tend.Field3__c = mediaName;
				// RowNo__cコピー追加
				tend.RowNo__c = s.RowNo__c;
				// 支払商品情報の自動設定
				//tend.PayProductName__c = s.ProductName__c;
				// 支払種別コピー追加
				tend.PaymentType__c = s.PaymentType__c;
				// 会計商品名 
				tend.PayProductName__c = s.ProductName__c;
				// 見積明細利用
				tend.UseDate__c = (s.UseDate__c == null ? useDate : s.UseDate__c);
				// 支払商品情報の自動設定
				tend.PayProductRef__c = s.refAccountMaster__c;
				tend.RelAccount__r = rsv.clone(); // 予約会計 = 主従関係(売上) Salesday__c[数式] => Name
				tend.Field1__r = accItem.clone(); // レシートＮｏ． = 参照関係(会計)
				tend.Field1__c = s.refBooking__c;
				// 2019/04/30 チェックインをかけなくても請求書が１枚に印刷されるようにご希望です by zy BEGIN
				tend.TempSaveExtInfo__c = s.name;
				// 2019/04/30 チェックインをかけなくても請求書が１枚に印刷されるようにご希望です by zy END
				if (paymentCd == CommConst.MEDIA_TYPE_CD_02) {
					// カード種別に反映する
					tend.CardTypeLst__c = tend.PayProductName__c ;
				} else if ( paymentCd == CommConst.MEDIA_TYPE_CD_11 ||
							paymentCd == CommConst.MEDIA_TYPE_CD_12) {
					// 金券種別
					tend.CouponTypeLst__c = tend.PayProductName__c;
					// 金券単価と数量
					tend.Field16__c = CommUtils.nullToBlank(s.UnitPrice__c);
					tend.Field17__c = CommUtils.nullToBlank(s.Amount__c);
				}
				ttendLst.add(tend);
			} 
			// 商品種別は利用明細の場合、会計明細に格納する
			else {
				Decimal unitPrice = (s.UnitPrice__c == null ? s.refAccountMaster__r.Field5__c : s.UnitPrice__c);
				Decimal serviceRate = (s.ServiceRate__c == null ? s.refAccountMaster__r.ServiceRate__c : s.ServiceRate__c);
				Decimal specialTax = (s.SpecialTax__c == null ? s.refAccountMaster__r.SpecialTax__c : s.SpecialTax__c);
				Decimal taxRate = (s.TaxRate__c == null ? s.refAccountMaster__r.TaxRateCal__c : s.TaxRate__c);
				// 2016/12/27 見積明細利用日機能対応 BEGIN zyz
				Date useDate = s.refBooking__r.EntryTime__c.date();
				// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH BEGIN
				// if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI) {
				if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI && !CommConst.BOOKEST_USERDATE_FLG) {
				// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH END
					useDate = s.refBooking__r.Departure__c.date();
				}
				Tran1__c tran = new Tran1__c();
				tran.AccountProviso__c = s.Id;
				// $合計金額(税込)
				tran.Field23__c = String.valueOf(s.Total__c); // Field41__c $合計金額（税込） = 数式 (通貨)
				// 数式項目を再計算を行う
				tran.recalculateFormulas();
				// 2013/08/22 編集後の商品名称で会計明細に設定を行う
				tran.Field5__c = s.ProductName__c;
				// 会計
				tran.Field1__c  = s.refBooking__c;
				// 商品処理種別
				tran.ActionType__c = s.ActionType__c;
				// 消費税
				tran.TaxRate__c = taxRate;
				// サービス料
				tran.ServiceRate__c = serviceRate;
				// 特別税
				tran.SpecialTax__c = specialTax;
				// 単価(税込)
				tran.Field20__c = String.valueOf(unitPrice);
				// 数量
				tran.Field21__c = String.ValueOf(s.Amount__c);
				// 2014/08/15 単価定義区分コピー
				tran.UnitPriceDefKb__c = !CommUtils.isBlank(s.UnitPriceDefKb__c) ?  s.UnitPriceDefKb__c : 
																					( !CommUtils.isBlank(s.refBooking__r.UnitPriceDefKb__c) ? s.refBooking__r.UnitPriceDefKb__c : '2' );
				// POSNo.
				tran.POSNo__c = CommUtils.getPosNoByComdefine();
				// RowNo__cコピー追加
				tran.RowNo__c = s.RowNo__c;
				// 2015/02/09 支払種別コピー追加
				tran.PaymentType__c = s.PaymentType__c;
				// 見積明細利用日
				tran.UseDate__c = (s.UseDate__c == null ? useDate : s.UseDate__c);
				tran.RelAccount__r = rsv.clone(); // 予約会計 = 主従関係(売上) Salesday__c[数式] => Name
				tran.Field1__r = accItem.clone(); // レシートＮｏ． = 参照関係(会計)
				// 2019/04/30 チェックインをかけなくても請求書が１枚に印刷されるようにご希望です by zy BEGIN
				tran.Field49__c = s.name;
				// 2019/04/30 チェックインをかけなくても請求書が１枚に印刷されるようにご希望です by zy END
				Decimal noTaxUnitPriceSum = 0;
				// 2019/07/30 軽減税率機能対応 WGCH BEGIN
				tran.Field11__c = s.Id;
				// 2019/07/30 軽減税率機能対応 WGCH END
				// 2019/07/30 軽減税率機能対応 WGCH BEGIN
				// for(BookingEstimateItem__c b : s.ParentBookingItemRef__r){
					// noTaxUnitPriceSum += b.UnitPrice__c;
				// }
				// noTaxUnitPriceSumMap.put(s.Id, noTaxUnitPriceSum);
				if(!noTaxUnitPriceSumMap.containsKey(s.id)) noTaxUnitPriceSumMap.put(s.id, 0);
				// 2019/07/30 軽減税率機能対応 WGCH END
				tranRsLst.add(tran);
			}
		}
	}
	// 2019/02/28 請求書宛名の『様』の表示改善対応 WSQ BEGIN
	public transient Boolean isFixPosition{get; private set;}
	public transient integer ftsize {get;private set;}
	public String[] getCustomerArr () {
		String customer = getCustomer();
		String[] customerArr = new List<String>();
		if (!CommUtils.isBlank(customer)) {
        	// お客様名は自動改行処理を行う
        	// 文字の長さにより、1行の最大文字数を変更する
        	Decimal maxlen = CommRepUtils.zankaSizeByStr(customer,22);
        	Integer oneLineSize = 16;//16pt
        	if (maxlen >= 21) {
        		ftsize = 12;
        		oneLineSize = 21;//1行 21文字まで自動改行
        	}
        	else if (maxlen >= 18) {
        		ftsize = 14;
        		oneLineSize = 18;//1行１８文字まで自動改行
        	}
        	// お客様の請求書宛名を自動改行処理を行う
        	customerArr = CommRepUtils.getPdfMaxShowStringNews(customer, 99, oneLineSize, false);
        	if (customerArr.size() >0) customerArr[customerArr.size() -1] = 
        								// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
        								// customerArr[customerArr.size() -1] + '　' + (CommUtils.isBlank(titleStr) ? '様' : titleStr);	
        								customerArr[customerArr.size() -1] + '　' + ( CommUtils.isBlank(mrStr)? (CommUtils.isBlank(titleStr) ? '様': titleStr) : mrStr);
        								// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
        }
        return customerArr;
	}
	// 2019/02/28 請求書宛名の『様』の表示改善対応 WSQ END
	// 2019/04/30 請求書の送付表新規作成 BY zyz BEGIN
	public String shipTitle{get;set;}	// 名头
	public String shipBody{get;set;}	// 详细内容
	public Boolean shipBodyFlg{get;set;}// 详细内容控制
	public String shipRegards{get;set;}	// 敬具
	public String shipRecord{get;set;}	// 記
	public String shipDepart{get;set;}	// 部分定义
	public String shipAbove{get;set;}	// 以上
	private void getShipping(Dom.XmlNode shipNode){
		shipTitle = '書 類 送 付 の ご 案 内';
		shipBody = '';
		shipBodyFlg = false;
		shipRegards = '敬具';
		shipRecord = '記';
		shipDepart = '■請求書 1部';
		shipAbove = '以上';
		if (shipNode != null ){
			for(Dom.XmlNode strNode : shipNode.getChildElements() ){
				String tagNm = strNode.getName();
				if(tagNm == 'SUBJECTLABEL'){
					shipTitle = (CommUtils.nullToblank(strNode.getText()) == '' ? '' : CommUtils.nullToblank(strNode.getText()));
				}else if(tagNm == 'CUSTOM_SHIPPING'){
					shipBodyFlg = true;
					shipBody = CommUtils.nullToblank(strNode.getText());
				}else if(tagNm == 'REGARDSLABEL'){
					shipRegards = (CommUtils.nullToblank(strNode.getText()) == '' ? '' : CommUtils.nullToblank(strNode.getText()));
				}else if(tagNm == 'RECORDLABEL'){
					shipRecord = (CommUtils.nullToblank(strNode.getText()) == '' ? '' : CommUtils.nullToblank(strNode.getText()));
				}else if(tagNm == 'DEPARTLABEL'){
					shipDepart = (CommUtils.nullToblank(strNode.getText()) == '' ? '' : CommUtils.nullToblank(strNode.getText()));
				}else if(tagNm == 'ABOVELABEL'){
					shipAbove = (CommUtils.nullToblank(strNode.getText()) == '' ? '' : CommUtils.nullToblank(strNode.getText()));
				}
			}
		}
	}
	// 2019/04/30 請求書の送付表新規作成 BY zyz END
	// 2019/04/30 チェックインをかけなくても請求書が１枚に印刷されるようにご希望です by zy BEGIN
	public set<id> getRealLeadIds(Lead__c pLead) {
		set<Id> leadIds = new set<Id>();
		Id leadIndexId = pLead.LeadIndexRef__c;     	
		// 関連予約情報を検査する　
		for (Lead__c lead : [select id from Lead__c where LeadIndexRef__c = :leadIndexId And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
								Order By LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c, EntryTime__c]) {
			leadIds.add(lead.Id);
		}
		return leadIds;
	}
	// 2019/04/30 チェックインをかけなくても請求書が１枚に印刷されるようにご希望です by zy END
	// 2019/06/30 請求書送付状の宛名複数選択表示機能 BY zyz BEGIN
	private String getLayoutName(Id pLeadId, String autoStr,Boolean splitFlg,Integer SplitNum){
		// API存放的Map
		map<String,String> apiMap = new map<String,String>();
		// 字段检索
		String queryApiStr = ' Id,';
		// api存放set
		set<String> apiDupSet = new set<String>();
		String layoutStr = '';
		try{
			// 拆分 _$$ 
			String[] lst = autoStr.split('_\\$\\$');
			for(String s : lst){
				// 拆分 $$_
				String[] lit = s.split('\\$\\$_');
				if (lit.size() >= 2) {
					apiMap.put(lit[1],lit[1]);
					if (apiDupSet.contains(lit[1])) continue;
					apiDupSet.add(lit[1]);
					queryApiStr += lit[1]+',';
				}
			}
			queryApiStr = queryApiStr.removeEnd(',');
			String queryWhere = 'Where Id =: pLeadId ';
			String queryStr = ' Select '+ queryApiStr + ' From Lead__c ' + queryWhere;
			List<Lead__c> leadlist = Database.query(queryStr);
			if (leadlist.isEmpty()) return '';
			for(Lead__c leadStr: leadlist){
				layoutStr = autoStr;
				for(String api : apiDupSet){
					// 获取定义字段对应值
			    	String valueStr = CommUtils.nullToBlank(CommUtils.getFielValue(leadStr,api));
			    	// 替换显示的值
			    	layoutStr = layoutStr.Replace('$$_' +api+'_$$' ,valueStr);
				}
			}
		} catch(Exception e){}
		if(splitFlg && !CommUtils.isBlank(layoutStr)) layoutStr = getlongSplit(layoutStr,SplitNum);
		return layoutStr;
	}
	// 控制开关打开，长度过长换行
	private String getlongSplit(String longStr,Integer Num){
		list<String> longLst = new list<String>();
		String layStr = '';
		if(Num == 0) Num = 20;
		for(String str : longStr.split('<br/>')){
			if(str.length() > Num){
				String val = CommRepUtils.getPdfMaxShowStringNew(str, 3, Num, '<br/>');
				longLst.add(val);
			} else {
				longLst.add(str);
			}
		}
		for(String l : longLst){
			layStr += l+'<br/>';
		}
		return layStr.removeEnd('<br/>');
	}
	// 2019/06/30 請求書送付状の宛名複数選択表示機能 BY zyz END
	// 2019/07/15 請求書の請求先名称の上部に請求先の住所を印字 BY zyz BEGIN
	private void initDocSetting(ApexPages.StandardController controller){
    	// 2018/12/15 請求書レイアウト改善 BY zyz BEGIN 
    	subjectStr = '';
    	customizeHtml = '';
    	payeeStr = '';
    	titleStr = '';
    	// 2019/02/28 請求書宛名の『様』の表示改善対応 WSQ BEGIN
		ftsize = 16;//文字サイズは16pt
    	isFixPosition = false;
    	// 2019/02/28 請求書宛名の『様』の表示改善対応 WSQ END
    	// 2019/06/30 請求書送付状の宛名複数選択表示機能 BY zyz BEGIN
    	autoHtml = '';
    	autoStyle = 'font-size:14pt;';
    	Boolean autoFlg = false;
    	// 2019/06/30 請求書送付状の宛名複数選択表示機能 BY zyz END
    	// 2019/07/15 請求書の請求先名称の上部に請求先の住所を印字 BY zyz BEGIN
    	autoAddHtml = '';
    	autoAddStyle = '';
    	Boolean autoAddFlg = false;
    	longInt = 0;
    	autoAllFlg = false;
    	// 2019/07/15 請求書の請求先名称の上部に請求先の住所を印字 BY zyz END
    	try {
	        String docName = 'BillPdfConfig';
	        Dom.XmlNode shopRoot = CommXmlUtils.parseXmlDoc(docName, shopCd);
	        Dom.XmlNode billPrintDom = shopRoot.getChildElement('BILLPDFLAYOUT', null);
		        if (billPrintDom != null) {
		            Dom.XmlNode billPrint = billPrintDom.getChildElement('SUBJECTLABEL', null);
		            if(billPrint != null) subjectStr = CommUtils.nullToBlank(billPrint.getText());
		            Dom.XmlNode resPrint = billPrintDom.getChildElement('TITLELABEL', null);
		            if(resPrint != null) titleStr = CommUtils.nullToBlank(resPrint.getText());
		        	// 2019/02/28 請求書宛名の『様』の表示改善対応 WSQ BEGIN
		        	if(resPrint != null) {
	        			String strIsFixPos = CommUtils.nullToBlank(resPrint.getAttribute('FIXPOSITION',null));
	       				if (!CommUtils.isBlank(strIsFixPos)) isFixPosition = Boolean.valueOf(strIsFixPos);
		        	}
		        	// 2019/02/28 請求書宛名の『様』の表示改善対応 WSQ END
		        	Dom.XmlNode rowsNode = billPrintDom.getChildElement('ROWSLABEL', null);
		        	if(rowsNode != null) customizeHtml = ReportXmlParserHelper.convertXmlTagToHtml(rowsNode);
		        	Dom.XmlNode payeePrint = billPrintDom.getChildElement('PAYLABEL', null);
		        	if(payeePrint != null) payeeStr = CommUtils.nullToBlank(payeePrint.getText());
		        }
		    // 2019/04/30 請求書の送付表新規作成 BY zyz BEGIN
	        Dom.XmlNode billShipDom = shopRoot.getChildElement('LETTERLAYOUT', null);
	        getShipping(billShipDom);
	        // 2019/04/30 請求書の送付表新規作成 BY zyz END
	        // 2019/06/30 請求書送付状の宛名複数選択表示機能 BY zyz BEGIN
	        Dom.XmlNode billNameDom = shopRoot.getChildElement('BILLLAYOUTNAME', null);
	        String customizeHtml = '';
	        Integer autoSplitNum = 20;
	        if(billNameDom != null){
	        	Dom.XmlNode LeadNameDom = billNameDom.getChildElement('LEAD_PDF', null);
	        	if(LeadNameDom != null){
	        		customizeHtml = CommUtils.nullToBlank(LeadNameDom.getText());
	        		autoStyle = (CommUtils.nullToblank(LeadNameDom.getAttribute('STYLE',null)) == '' ? 'font-size:14pt;' : CommUtils.nullToblank(LeadNameDom.getAttribute('STYLE',null)));
	        		autoFlg = boolean.valueOf(CommUtils.nullToblank(LeadNameDom.getAttribute('AOTUSPLIT',null)));
	        		autoSplitNum = CommUtils.nullToIntZero(LeadNameDom.getAttribute('MAXLENGTH',null));
	        	}
	        	autoHtml = getLayoutName(controller.getId(),customizeHtml,autoFlg,autoSplitNum);
	        }
	        // 2019/06/30 請求書送付状の宛名複数選択表示機能 BY zyz END
	        // 2019/07/15 請求書の請求先名称の上部に請求先の住所を印字 BY zyz BEGIN
	        Dom.XmlNode billTitleDom = shopRoot.getChildElement('BILLTITLENAME', null);
	        String titleHtml = '';
	        Integer addautoSplitNum = 20;
	        if(billTitleDom != null){
	        	autoAllFlg = boolean.valueOf(CommUtils.nullToblank(billTitleDom.getAttribute('ALLREPLACE',null)));
	        	Dom.XmlNode addTitleDom = billTitleDom.getChildElement('LEAD_PDF', null);
	        	if(addTitleDom != null){
	        		titleHtml = CommUtils.nullToBlank(addTitleDom.getText());
	        		autoAddStyle = (CommUtils.nullToblank(addTitleDom.getAttribute('STYLE',null)) == '' ? 'font-size:14pt;' : CommUtils.nullToblank(addTitleDom.getAttribute('STYLE',null)));
	        		autoAddFlg = boolean.valueOf(CommUtils.nullToblank(addTitleDom.getAttribute('AOTUSPLIT',null)));
	        		addautoSplitNum = CommUtils.nullToIntZero(addTitleDom.getAttribute('MAXLENGTH',null));
	        	}
	        	autoAddHtml = getLayoutName(controller.getId(),titleHtml,autoAddFlg,addautoSplitNum);
				// 字体カスタム設定の場合、サイズ更新指定行数
				longInt = autoAddHtml.split('<br/>').size();
	        }
	        if(CommUtils.isBlank(autoAddHtml)) autoAllFlg = false;
	        // 2019/07/15 請求書の請求先名称の上部に請求先の住所を印字 BY zyz END
        } catch (Exception e) {}
    	// 2018/12/15 請求書レイアウト改善 BY zyz END 
	}
	// 2019/07/15 請求書の請求先名称の上部に請求先の住所を印字 BY zyz END
	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
	// 各税率の金額合計（税抜）と消費税合計情報を格納する
	// 合計のセクションに、割引ある場合、割引関連の消費税を計算する、画面に表示する
	// 該当金額と一覧の金額とわせて、最後の合計行に金額を表示する（税抜き合計＋消費税合計）、最後利用金額合計
	private Boolean gIsServieModeInner; // サービス料表示モード1
	private Decimal taxUnitPriceAll; // 消费税合计值
	private Decimal amoutAllMoneyEnd = 0;
	private Decimal serviceAmountEnd = 0;
	private Decimal serviceTaxAmountEnd = 0;
	private Integer rowNoEnd = 1;
	// 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH BEGIN
	private static Map<String, List<TranItem>> pBrkTranItemMap;
	// 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH END
	private Map<String, CommUtils.ProductInfo> pBrkProMap;
	private Map<String, CommUtils.ProductInfo> planHeaderMap;
	public String getTaxNumberFormat() { return CommBaseCtrl.getTaxNumberFormat();}
	public static boolean isReducedTaxFlg{get{ return CommConst.REDUCED_TAXRATE_FLG;} private set;}
	public static boolean isPlanBrkShowFlg{get{ return CommConst.REDUCED_PDF_PLAN_BRK_SHOW_FLG;} private set;}
	// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
	public static boolean planBrkToHeaderCalFlg{get{ return CommConst.PLAN_BRKTOHEADER_CAL_FLG;} private set;}
	// 2019/10/02 PlanHeader算法切换对应 WGCH END
	// 2019/10/30 軽減税率割合モード機能対応 WGCH BEGIN
	// 対象行Lst
	public List<CommLogicProcess.TaxRowData> taxRowDataLst {get;set;}
	// 対象行Map <消費税レート,該当消費税関連の金額合計>
	private map<Decimal, CommLogicProcess.TaxRowData> taxRowDataMap;
	// 値引行
	public CommLogicProcess.DisRowData disRowData {get;set;}
	// 値引行Lst
	public List<CommLogicProcess.DisRowData> disRowDataLst {get;set;}
	// 合计行
	public CommLogicProcess.SumAmountRowData sumRowData {get;set;}
	
	private void reducedTaxInit(){
		serviceAmountEnd = serviceTaxAmountEnd = taxUnitPriceAll = 0;
		rowNoEnd = 1;
		// 值引行 金额合计 计算 初始化
		disRowData = new CommLogicProcess.DisRowData();
		// 合计值 金额合计 计算 初始化
		sumRowData = new CommLogicProcess.SumAmountRowData();
		// 消费税板块
		taxRowDataMap = new map<Decimal, CommLogicProcess.TaxRowData>();
		// 2019/10/30 軽減税率割合モード機能対応 WGCH BEGIN
		comSum = new CommLogicProcess.SumRowInfo();
		// 2019/10/30 軽減税率割合モード機能対応 WGCH END
	}
	public CommLogicProcess.SumRowInfo comSum{get;set;}
	private void addDetailToMapFun(TranItem tranItem,Decimal noTaxUnitPriceSum) {
		if (tranItem.isPaymentInfo) return;
		/*
		// 每笔会计商品 合計税込
		Decimal priceAmount = CommUtils.RoundProcess(CommUtils.nullToZero(tranItem.unitPrice) * CommUtils.nullToZero(tranItem.quantity), gPointLen);
		// 每笔会计商品 合計消費税
		Decimal taxAmount = CommUtils.RoundProcess(CommUtils.nullToZero(tranItem.taxUnitPrice) * CommUtils.nullToZero(tranItem.quantity), gPointLen);
		taxUnitPriceAll = CommUtils.nullToZero(taxUnitPriceAll) + taxAmount;
		// 每笔会计商品 的 特别税
		Decimal specialTax = tranItem.specialTax;
		if((priceAmount + specialTax + taxAmount) == 0 && CommUtils.nullToZero(noTaxUnitPriceSum) == 0) return;
		// 合计行 会计商品 税拔金额的合计值:
		sumRowData.amountExcTax += priceAmount - taxAmount; // 特别税单独行显示: 所以加到合计税拔里
		// 合计行 会计商品 税込金额的合计值:
		sumRowData.amountIncTax += priceAmount;
		// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
		if(CommUtils.nullToZero(tranItem.taxRate) != 0) sumRowData.priceAmountSum += priceAmount;
		// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
		// 合计行 会计商品 消费税金额的合计值:=> 
		sumRowData.taxAmount += taxAmount;
		Decimal taxRate = CommUtils.nullToZero(tranItem.taxRate);
		taxRate = taxRate == 0 ? 0 : taxRate.setScale(4);
		if (taxRowDataMap == null) taxRowDataMap = new map<Decimal, TaxRowData>();
		if (!taxRowDataMap.containsKey(taxRate)) taxRowDataMap.put(taxRate, new TaxRowData());
		// Plan明细里  含有非课税 
		if(CommUtils.nullToZero(noTaxUnitPriceSum) != 0 || specialTax > 0){
			// Plan明细里 含有非课税 并且 Map key没有0的情况
			Decimal noTaxKey = 0;
			if(!taxRowDataMap.containsKey(noTaxKey)) taxRowDataMap.put(noTaxKey, new TaxRowData());
			taxRowDataMap.get(noTaxKey).amountExcTax += noTaxUnitPriceSum + specialTax;
			// 集计处理
			sumRowData.amountExcTax += noTaxUnitPriceSum + specialTax;
			sumRowData.amountIncTax += noTaxUnitPriceSum + specialTax;
			// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
			// sumRowData.priceAmountSum += noTaxUnitPriceSum + specialTax;
			// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
		}
		TaxRowData taxRow = taxRowDataMap.get(taxRate);
		// 消费税
		taxRow.taxRate = taxRate;
		taxRow.amountExcTax += priceAmount - taxAmount;
		taxRow.amountIncTax += priceAmount;
		// 当前税率   的 消费税合计值
		taxRow.taxAmount += taxAmount;
		*/
		CommLogicProcess.ItemData item = new CommLogicProcess.ItemData();
		item.quantity = tranItem.quantity; // 明细-数量
		item.unitPrice = tranItem.unitPrice; // 明细-单价
		item.taxUnitPrice = tranItem.taxUnitPrice; // 明细-消費税
		item.specialTax = tranItem.specialTax; // 明细-特别税
		item.taxRate = tranItem.taxRate; // 明细-特别税
		CommLogicProcess.addDetailToMapFun(item, noTaxUnitPriceSum, comSum);
	}
	// 値引 比率计算 + 详细设值
	private void processSumInfo() {
		/*
		Decimal ratioSum = 1;
		disRowData.disUnitPriceSum = getAmoutIncDiscont(); // 値引 合计值 获取
		// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
		disRowDataLst = new List<DisAmountRowData>();
		// 值引处理
		// 值引金额 > 课税商品合计金额 Flg
		Boolean disMaxFlg = disRowData.disUnitPriceSum >= sumRowData.priceAmountSum;
		// 当值引金额 > 课税商品合计金额 时, 金额置换, 防止负值
		if(disMaxFlg) disRowData.disUnitPriceSum = sumRowData.priceAmountSum;
		// 最终有效的值引金额
		Decimal disEnd = disRowData.disUnitPriceSum;
		Decimal disSumEnd = disRowData.disUnitPriceSum;
		// 初始化
		disRowData.disUnitPriceSum = 0;
		// 占最大比例的key
		Decimal larger = 0;
		// Key: 最大比例, Val: 消费税
		Map<Decimal, Decimal> disTaxMaxMap = new Map<Decimal, Decimal>();
		// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
		// 並び順で最小税からMAX税を設定する
		taxRowDataLst = new List<TaxRowData>();
		List<Decimal> taxRateLst = new List<Decimal>(taxRowDataMap.keySet());
		taxRateLst.sort();
		for (Decimal taxRate : taxRateLst) {
			TaxRowData taxRow = taxRowDataMap.get(taxRate);
			** 值引【税込】= 值引【税拔】 + 值引【总消费税金额】
			** keyDiscountRatio =>: 構成比率 = 每笔  合計税抜  / W：GrandTota
			-------------传入的值引为--值引【税拔】------------------------------------
			** (値引【税抜】 * 構成比率 * 当前消费税).小数点处理【跟着共同定义走】 = 当前值引的消费税金额
			** 把每笔值引消费税金额 累加 = 值引【总消费税金额】
			-------------传入的值引为--值引【税込】------------------------------------
			** (値引【税込】 / (1 + 構成比率1 * 当前消费税1 + 構成比率2 * 当前消费税2 + ....)).小数点处理【跟着共同定义走】 = 值引【税抜】
			** 值引【税込】 - 值引【税抜】 = 值引【总消费税金额】
			**
			// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
			if(taxRate != 0){
				// 税抜 比率
				// Decimal keyDiscountRatio = sumRowData.amountIncTax == 0 ? 0 : taxRow.amountIncTax / sumRowData.amountIncTax;
				Decimal keyDiscountRatio = sumRowData.priceAmountSum == 0 ? 0 : taxRow.amountIncTax / sumRowData.priceAmountSum;
				larger = math.max(keyDiscountRatio, larger);
				// 集计占比例最大的税种别
				disTaxMaxMap.put(larger, taxRate);
				// 值引行Info
				DisAmountRowData disItem = new DisAmountRowData();
				disItem.taxRate = taxRate;
				// 值引拔
				disItem.disUnitPriceSum = CommUtils.RoundProcess((disMaxFlg ? taxRow.amountExcTax : ((disEnd * keyDiscountRatio) / (1+taxRate))), gPointLen);
				// 值引税
				disItem.disTaxAmountSum = CommUtils.RoundProcess((disMaxFlg ? taxRow.taxAmount : ((disEnd * keyDiscountRatio) - disItem.disUnitPriceSum)), gPointLen);
				// 値引 合计值 税拔
				disRowData.disUnitPriceSum += disItem.disUnitPriceSum;
				// 値引き合計行目の金額を計算する（該当金額は税率混在の金額を合計する
				disRowData.disTaxAmountSum += disItem.disTaxAmountSum;
				// 最终差值
				disSumEnd -= (disItem.disUnitPriceSum + disItem.disTaxAmountSum);
				// 值引行集计
				disRowDataLst.add(disItem);
				// 值引行集计
				disRowDataMap.put(taxRate, disItem);
				// 当前構成比率 * 当前消费税
				ratioSum += keyDiscountRatio * taxRate;
			}
			// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
			taxRowDataLst.add(taxRow);//消費税リスト情報を格納する
		}
		// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
		// 値引き明細行目合計値は値引き合計金額と一致しない場合、差分金額は値引行目の税抜列の最大行目に金額を差分設定する
		if(!disMaxFlg && disTaxMaxMap.containsKey(larger) && disSumEnd != 0){
			Decimal taxRate = disTaxMaxMap.get(larger);
			DisAmountRowData disItem = disRowDataMap.get(taxRate);
			// 差值找平
			disItem.disUnitPriceSum += disSumEnd;
			// 总差值找平
			disRowData.disUnitPriceSum += disSumEnd;
		}
		*
		// 値引き合計行目の金額を計算する（該当金額は税率混在の金額を合計する
		// 值引【总消费税金额】= 值引【税込】 - 值引【税抜(discountAllInfo.discountAmountAll/ratioSum)】
		disRowData.disTaxAmountSum = CommUtils.RoundProcess(disRowData.disUnitPriceSum - (disRowData.disUnitPriceSum / ratioSum), gPointLen);
		// 値引 合计值 税拔
		disRowData.disUnitPriceSum -= disRowData.disTaxAmountSum;
		*
		// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
		// 割引後の消費税 = 合計消費税 - 合計 値引金額に対する消費税額
		sumRowData.taxAmount -= disRowData.disTaxAmountSum;
		sumRowData.amountExcTax -= disRowData.disUnitPriceSum;
		// 最终税込
		amoutAllMoneyEnd = sumRowData.amountExcTax + sumRowData.taxAmount;
		// 负值处理(値引き消費税がマイナスの場合)
		if(sumRowData.taxAmount < 0){
			// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
			Decimal taxRate = disTaxMaxMap.get(larger);
			DisAmountRowData disItem = disRowDataMap.get(taxRate);
			// 差值找平
			disItem.disUnitPriceSum -= sumRowData.taxAmount;
			disItem.disTaxAmountSum += sumRowData.taxAmount;
			// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
			disRowData.disUnitPriceSum -= sumRowData.taxAmount;
			disRowData.disTaxAmountSum += sumRowData.taxAmount;
			sumRowData.amountExcTax += sumRowData.taxAmount;
			sumRowData.taxAmount -= sumRowData.taxAmount;
		}
		*/
		CommLogicProcess.processSumInfo(getAmoutIncDiscont(), comSum);
		taxUnitPriceAll = comSum.taxUnitPriceAll;
		// 対象行Lst
		taxRowDataLst = comSum.taxRowDataLst;
		// 值引行
		disRowData = comSum.disRowData;
		// 值引行Lst
		disRowDataLst = comSum.disRowDataLst;
		// 合计行
		sumRowData = comSum.sumRowData;
	}
	/*
	public List<TaxRowData> taxRowDataLst{get; set;}
	// map<消費税レート,該当消費税関連の金額合計>
	private map<Decimal, TaxRowData> taxRowDataMap;
	public class TaxRowData {
		public TaxRowData() {
			taxRate = amountExcTax = amountIncTax = taxAmount = 0;
			isNoTaxPrice = isDiscountTax = true;
		}
		public Decimal taxRate{get{return (CommUtils.nullToZero(taxRate));}set;}	// 消費税率
		public Decimal amountExcTax{get;set;}	// 税抜きの合計金額
		public Decimal amountIncTax{get;set;}	// 税込きの合計金額
		public Decimal taxAmount{get;set;}		// 該当行目の消費税合計
		public Boolean isNoTaxPrice{get;set;}	// 非課税金額
		public Boolean isDiscountTax{get;set;}	// 割引
	}
	// 値引行
	public DisAmountRowData disRowData {get;set;}
	public class DisAmountRowData {
		public DisAmountRowData(){
			// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
			taxRate = 0;
			// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
			disTaxAmountSum = disUnitPriceSum = 0;
		}
		// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
		public Decimal taxRate{get;set;}//値引き行目の税率情報を格納する
		// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
		public Decimal disTaxAmountSum{get;set;}	// 該当行目の消費税合計
		public Decimal disUnitPriceSum{get;set;}
	}
	// 合计行
	public SumAmountRowData sumRowData {get;set;}
	public class SumAmountRowData {
		public SumAmountRowData(){
			taxAmount = amountExcTax = amountIncTax = priceAmountSum = 0;
		}
		public Decimal taxAmount{get;set;}	// 該当行目の消費税合計
		public Decimal amountExcTax{get;set;} // 合计税拔
		public Decimal amountIncTax{get;set;} // 合计税込
		public Decimal priceAmountSum{get;set;}
	}
	*/
	// 2019/10/30 軽減税率割合モード機能対応 WGCH END
	// 2019/07/30 軽減税率機能対応 WGCH END
}