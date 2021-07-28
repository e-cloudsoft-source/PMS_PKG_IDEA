/**
* 予定表PDF出力機能対応
* 2017/01/17 INIT
* 2017/05/12 投稿した予定表の変更箇所は色つけように改善対応
* 2017/05/12 店舗毎の予定表を異なるChatterグループ内に投稿できるように改善対応
* 2018/02/22 会計OP単位で料理表示できるように改善対応
* 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善
* 2018/10/15 料理集計に合計の表記がございますが機能対応
* 2019/04/15 料理自定义列所在位置功能对应
* 2019/04/30 料理項目列のタイトルを表示・非表示切り替えフラグ
* 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応
* 2019/05/15 料理集計「単泊」の料理数は「連泊の１泊目」に合計する機能対応
* 2019/05/15 予定表指定日にて、連絡事項を表示する機能対応
* 2019/06/14 「料理」列に「会計OP」を表示したい对应
* 2019/06/28 ユーザ側で非表示にした項目対応
* 2019/06/28 「サ抜税込」「サ抜税抜」の選択肢対応
* 2020/02/28 同伴者情報列位置自定义改善对应
**/
public with sharing class K_ScheduleReportPdf extends CommBaseCtrl{
	// 「ロジック処理用、非可変」部屋/部屋タイプオブジェクトから部屋情報を取得するようＳＱＬ
	private static final String queryRoomStr = ' Rroom__r.Seq__c, Rroom__r.RoomName__c, Rroom__r.Rnumber__c,Rroom__r.Name,refTypeOfRooms__c,refTypeOfRooms__r.Name,refTypeOfRooms__r.ShopInfoRef__c,refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c,refTypeOfRooms__r.ShopInfoRef__r.Name ';
	// 「ロジック処理用、非可変」見積もり明細情報を取得用ＳＱＬ
	// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
	// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
	// 2019/06/28 「サ抜税込」「サ抜税抜」の選択肢対応 WGCH BEGIN
	private static final String queryLdStr = ' Select ParentBookingItemRef__c, Field3__c, ActionType__c, ProductName__c, Amount__c, UnitPrice__c, NoneAccount__c, OP__c, OP__r.Name, refAccountMaster__c, refAccountMaster__r.Name,refAccountMaster__r.Field3__c,refAccountMaster__r.Field5__c,Tankanonetax__c,unitPriceIncTaxCal__c,X3_2__c,X4_3__c, UnitPriceDefKbCal__c, UnitPriceDefKb__c, TaxRate__c, ServiceRate__c, SpecialTax__c FROM BookingEstimateItemFgKu__r ';
	// 2019/06/28 「サ抜税込」「サ抜税抜」の選択肢対応 WGCH END
	// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
	// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
	// 「ロジック処理用、非可変」集計対象の会計明細情報を統計する
	// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
	// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
	// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
	// 2019/06/28 「サ抜税込」「サ抜税抜」の選択肢対応 WGCH BEGIN
	private static final String queryTranStr = ' Select Id, Name,ParentTran1Ref__c,Field7__r.OP__c,Field7__r.OP__r.Name,Field1__r.Relreserve__c,Field7__c,Field7__r.Name,Field7__r.Field3__c,Field7__r.Field5__c,Field5__c,Field40__c,Tankanonetax__c,Field39__c, UnitPriceDefKbCal__c, UnitPriceDefKb__c, TaxRate__c, ServiceRate__c, Field20__c, SpecialTax__c From Tran1__c ';
	// 2019/06/28 「サ抜税込」「サ抜税抜」の選択肢対応 WGCH END
	// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
	// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
	// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
	// 「ロジック処理用、非可変」予約情報取得用項目リスト
	// 2017/10/27 GROUP功能对应 WGCH BEGIN
	private static final String queryConstLeadStr = 'LeadIndexSubId__c,LeadIndexRef__r.Name , EntryTime__c,Field298__c, Rroom__c, Id, Name, Field353__c,Field291__c,Field4__c,Field278__c,DayNightCal__c,Check369__c,Morningtime__c,Morimongn__c,Field277__c,Field300__c,Field281__c,Field302__c,StayPersons__c,Mans__c,Femails__c,ChildFA__c,Childs__c,ReservedType__c,Field293__c,Field303__c,Field306__c,Field354__c,Field301__c,Comment3__c ';
	// 2017/10/27 GROUP功能对应 WGCH END
	/** 予約から自定義表示予定の項目リスト */
	private static Set<String> customAggregateFields = new Set<String>();				// XMLに合計項目のＡＰＩ格納する
	public static Boolean isShowFoodInfo{get;set;}										// 料理情報を表示・非表示設定する
	// 2019/04/30 料理項目列のタイトルを表示・非表示切り替えフラグ WSQ BEGIN
	public static Boolean isNoShowFoodHeader{get;set;}									// 料理項目列のタイトルを表示・非表示切り替えフラグ[2019.04.30追加]
	// 2019/04/30 料理項目列のタイトルを表示・非表示切り替えフラグ WSQ END
	/* ログインユーザーの支店コード */
	//private static String userShopCode;
	// 2015/09/01 多店舗機能対応 BEGIN
	//private static UserUtil.UserShopInfo userInf;
	// 2015/09/01 多店舗機能対応 END
	/* 部屋リスト情報を格納する */
	private transient List<Room__c> roomList;
	/** 朝食判断用会計ＯＰのID */
	private transient Set<Id> moringFoodOpIdSet = new Set<Id>();
	/** 予約情報を取得用ＳＱＬ */
	private static String queryLeadStr;
	// 処理がどうか判別用情報を格納用リスト
	private static List<String> filterOpList = new List<String>();
	// 朝食の商品コード
	private static final String CONST_OTHER_CD = 'A_';
	// 2017/05/12 PDFpost等机能对应 BEGIN By Wgch
	// 2017/04/27 料理数目变更之后变颜色对应 wgch BEGIN
	//private static final String CONST_MON_FOOD_CD = 'Z_' + CommUtils.getRandom(6);
	private static final String CONST_MON_FOOD_CD = 'Z_ZZZZZZ';
	// 2017/04/27 料理数目变更之后变颜色对应 wgch END
	// 2017/05/12 PDFpost等机能对应 END By Wgch
	// 2017/09/18 予定表に表示したく無い部屋のSEQ#をカンマで複数定義するに改善対応 WGCH BEGIN
	private static Set<Decimal> noRmSeqSet = new Set<Decimal>();		 // 不显示的Room SeqSet
	// 2017/09/18 予定表に表示したく無い部屋のSEQ#をカンマで複数定義するに改善対応 WGCH END
	// チェックイン後の予約データの料理集計は分けるがどうか判別する
	private static final Boolean cookInfoSplitShow = CommDefine__c.getOrgDefaults().ReportKScheduleCookInfoDiv__c == null ? false : CommDefine__c.getOrgDefaults().ReportKScheduleCookInfoDiv__c;
	// 料理集計種別コード取得する
	private static final String cookingSummyCode = CommDefine__c.getOrgDefaults().ReportKScheduleCookInfoCode__c == null ? '1' : CommDefine__c.getOrgDefaults().ReportKScheduleCookInfoCode__c;
	// 予定表料理項目商品並べ順表示方式
	private static final String cookFieldSortDiv = CommDefine__c.getOrgDefaults().ReportKScheduleCookFieldSortDiv__c == null ? '1' : CommDefine__c.getOrgDefaults().ReportKScheduleCookFieldSortDiv__c;
	// 2017/05/12 PDFpost等机能对应 BEGIN By Wgch
	//public transient List<String> leadApiLst{get;private set;}					// PDF出力の項目のAPI名
	// 2017/05/12 PDFpost等机能对应 END By Wgch
	//public transient List<String> leadLabLst{get;private set;}					// PDF出力の項目のラベル名
	// 2017/10/27 GROUP功能对应 WGCH BEGIN
	public transient static Map<String, String> leadApiLabelMap{get; private set;}
	// 2017/10/27 GROUP功能对应 WGCH END
	public transient List<List<ReportRow>> dataAll {get;private set;}				// PDF出力用PDF情報格納する
	public transient Map<String, Decimal> avgSumMap{get;private set;}				// 集計合計値を格納する
	// 2017/10/10 WGCH BEGIN
	//public transient List<List<ReportSumRow>> foodSumRowLstAll{get; private set;}	// 集計合計値List
	public transient List<foodSumInfo> foodSumRowLstAll{get;private set;}
	// 2017/10/10 WGCH END
	// 2017/10/27 GROUP功能对应 WGCH BEGIN
	public static map<String, String> customTypemap{get;set;}	// 画面項目文字列以外の項目のタイプを設定する
	// 2017/10/27 GROUP功能对应 WGCH END
	public transient Integer pageWidth{get;private set;}			// Xml: Page Width
	// 2017/05/12 PDFpost等机能对应 BEGIN By Wgch
	// 2017/04/27 料理数目变更之后变颜色对应 wgch BEGIN
	// 料理数量变更==>>显示的颜色
	private static String foodSumColor;
	// 背景色或是字体色的Flg
	private static Boolean bgColorFlg;
	public Map<String,String> apiColorMap{get;set;}
	public Map<String ,Map<String,String>> colorJsonMap{get;private set;}	
	// 2017/04/27 料理数目变更之后变颜色对应 wgch END
	// 2018/07/30 料理集計 WGCH BEGIN
	public static Boolean foodNightsFlg = false;
	// 2018/07/30 料理集計 WGCH END
	// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
	public static Boolean unitpriceColShow {get{ if(unitpriceColShow == null) unitpriceColShow = false; return unitpriceColShow;}}
	// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
	// 2019/04/15 料理自定义列所在位置功能对应 WGCH BEGIN
	public Decimal isShowFoodPosition{get;set;}
	// 2019/04/15 料理自定义列所在位置功能对应 WGCH END
	// 2019/06/14 「料理」列に「会計OP」を表示したい对应 WGCH BEGIN
	public static String opLabel{get { if(CommUtils.isBlank(opLabel)) opLabel = 'OP'; return opLabel;} private set;}
	public static Boolean opColIsShowFlg{get { if(opColIsShowFlg == null) opColIsShowFlg = false; return opColIsShowFlg;} private set;}
	// 2019/06/14 「料理」列に「会計OP」を表示したい对应 WGCH END
	// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
	// 单价列显示模式
	/*
	* 0:商品单价
	* 1:明细单价税込
	* 2:明细单价税拔
	*/
	private static String mode;
	public transient static Map<Date, List<String>> keyDateStrMap {get;private set;}
	// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
	// 2019/05/15 料理集計「単泊」の料理数は「連泊の１泊目」に合計する機能対応 WGCH BEGIN
	public Boolean oneNightSumFlg{get{ if(oneNightSumFlg == null) oneNightSumFlg = false; return oneNightSumFlg;} set;}
	// 2019/05/15 料理集計「単泊」の料理数は「連泊の１泊目」に合計する機能対応 WGCH END
	// 变更履历的Map
	public static Map<Id, LeadHistories.LeadHistoryItem> historyMap;
	private String shopCode;			// Page shopCode
	private String pQueryDt;			// Page pQueryDt
	private DateTime preBatchExcTime;	// 前回バッチの実施時間
	private static DateTime curBatchExcTime;// 今回バッチの実施時間
	// 2017/10/10 WGCH BEGIN
	public transient Boolean termDtFlg {get;private set;}
	public transient List<Date> keyDateLst {get;private set;}
	// 2017/10/27 GROUP功能对应 WGCH BEGIN
	// public transient Map<Date, List<List<ReportRow>>> dataAllMap {get;private set;}
	private static Set<String> grpTitlApiSet = new Set<String>();		// GROUPABLE XML设置的 ApiSet
	private static List<String> grpTitlApiLst = new List<String>();	 // GROUPABLE XML设置的 ApiSet
	private static Set<String> grpAggrApiSet = new Set<String>();		// GROUPABLE XML设置的 集计ApiSet
	public static Boolean groupAbleFlg {get;set;}						// GROUPABLE 功能FLG TRUE:有效;FALSE:无效;
	public static Boolean expandFlg {get;set;}
	// 2017/10/27 GROUP功能对应 WGCH END
	// 2018/10/15 料理集計に合計の表記がございますが機能対応 WGCH BEGIN
	public static Boolean foodSumIsShowProdFlg{get; set;}
	public static Boolean foodSumIsShowFlg{get; set;}
	// 2018/10/15 料理集計に合計の表記がございますが機能対応 WGCH END
	// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH BEGIN
	public static Boolean isShowGuestInfo{get;set;}
	public static String guestTitle{get;set;}
	private static Map<String, String> guestLabelMap = new Map<String, String>();		// GUESTYADOINFO XML设置的 guestLabelMap
	private static List<String> guestApiLst = new List<String>();						// GUESTYADOINFO XML设置的 ApiList
	// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH END
	// 2020/02/28 同伴者情報列位置自定义改善对应 WGCH BEGIN
	public static final String CONST_COL_FOOD{get { return 'A';}} //「料理列」标识符
	public static final String CONST_COL_GUEST{get { return 'B';}} //「同伴者情報列」标识符
	public Decimal isShowFoodPositionOld;
	public Decimal isShowGuestPositionOld;
	public Boolean isShowGuestPositionFlg{get;set;} //「同伴者情報列」自定义位置有效FLG
	public Decimal isShowGuestPosition{get{ return (isShowGuestPositionFlg ? isShowGuestPosition : (CommUtils.nullToZero(isShowFoodPosition)+1));}set;} // 同伴者情報表示場所格納
	// 2020/02/28 同伴者情報列位置自定义改善对应 WGCH END
	// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
	public static Boolean foodGroupAbleFlg{get; set;}					// FOODGROUPABLE初始化展开效果 功能FLG TRUE:料理Group有效; FALSE:料理Group无效;
	public static Map<String, String> opInfoMap{get; set;}
	private static final String BLANK = '$_BLANK_$';
	// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
	private Integer termDates;
	// 予定表を表示のとき、部屋順で表示できる改善対応
	private static String sortField;									 // GROUPABLE XML设置的 根据部屋字段排序
	// 2017/10/10 WGCH END
	//作为是否post的Flg(true:可以继续执行post处理)
	public static Boolean isBatchStartFlg;
	// 該当フラグはTRUE：前回の情報と比較処理を行う、FALSE:PDF
	//public static Boolean isBatchExecuteFlg;
	public static final String BATCH = 'バッチ';
	// 料理种别
	private static final String LEADFOODSUM = '予約料理集計';
	private static final String REPORTFOODSUM = '見積料理集計';
	private static final String ACCOUNTFOODSUM = '会計料理集計';
	//public K_ScheduleReportPdf(){}	
	public K_ScheduleReportPdf(){
		Pagereference pg = ApexPages.currentPage();
		shopCode = CommUtils.nullToBlank(pg.getParameters().get('sp'));
		pQueryDt = CommUtils.nullToBlank(pg.getParameters().get('dt'));
		// 2017/10/10 WGCH BEGIN
		// 2017/10/27 GROUP功能对应 WGCH BEGIN
		groupAbleFlg = pg.getParameters().containsKey('gpflg');
		expandFlg = pg.getParameters().containsKey('expand');
		// 2017/10/27 GROUP功能对应 WGCH END
		if (pg.getParameters().containsKey('pdf')) {
			String termDt = CommUtils.nullToBlank(pg.getParameters().get('term'));
			termDates = CommUtils.isBlank(termDt) ? 1 : Integer.valueOf(termDt);
			Date batchQueryDt = Date.today();
			if(termDates == 1 && batchQueryDt == CommUtils.stringToDate(pQueryDt)){
				List<ReservationListWork__c> reservationList = [Select Id,BatchLastTm__c,DateType__c,ShopInfoRef__r.ShopCode__c,FoodSumType__c,FeedItemId__c,EntryDate__c from ReservationListWork__c 
										where FoodSumType__c = null And EntryDate__c =: batchQueryDt And DateType__c =:K_ScheduleReportPdf.BATCH 
										And ShopInfoRef__r.ShopCode__c =: shopCode limit 1];
				if(!reservationList.isEmpty()){
					preBatchExcTime = reservationList[0].BatchLastTm__c;
				}
			}
			// 2019/06/28 ユーザ側で非表示にした項目対応 WGCH BEGIN
			isBatchRunFlg = false;
			// 2019/06/28 ユーザ側で非表示にした項目対応 WGCH END
		} else {
			Long longLtm = (Long)CommUtils.nullToZero(pg.getParameters().get('bltm'));
			curBatchExcTime = DateTime.newInstance(longLtm);
			if (pg.getParameters().containsKey('preBltm')) {
				Long longPrLtm = (Long)CommUtils.nullToZero(pg.getParameters().get('preBltm'));
				preBatchExcTime = DateTime.newInstance(longPrLtm);
			}
			// 2019/06/28 ユーザ側で非表示にした項目対応 WGCH BEGIN
			isBatchRunFlg = true;
			// 2019/06/28 ユーザ側で非表示にした項目対応 WGCH END
		}
		// 2017/10/10 WGCH END
		// 2019/08/15 予定表の部屋タイプ絞り込みは予定表内のフィルター機能が改善ほしい by zy BEGIN
		// 部屋タイプ指定
		String typeStr = pg.getParameters().get('type');
		if (!CommUtils.isBlank(typeStr)){
			typeSet = new Set<String>(typeStr.split(','));
			typeSet.remove('');
		}
		// 2019/08/15 予定表の部屋タイプ絞り込みは予定表内のフィルター機能が改善ほしい by zy END
		// 2019/08/15 予定表上にも、ルームインジケータのような検索欄が欲しい by zy BEGIN
		String filterTxtStr = pg.getParameters().get('filter');
		if (!CommUtils.isBlank(filterTxtStr)) filterStr = filterTxtStr;
		// 2019/08/15 予定表上にも、ルームインジケータのような検索欄が欲しい by zy END
		// 2021/05/31 #11007 bug fixed by zy BEGIN
		if (ApexPages.currentPage().getParameters().containsKey('layout')) {
			pLayoutId = CommUtils.nullToBlank(ApexPages.currentPage().getParameters().get('layout'));
		}
		if (ApexPages.currentPage().getParameters().containsKey('roomids')) {
			pRoomIds = CommUtils.nullToBlank(ApexPages.currentPage().getParameters().get('roomids'));
		}
		
		// 2021/05/31 #11007 bug fixed by zy END

	}
	public K_ScheduleReportPdf(String shopCd,String queryDt,boolean isBatchFlg, DateTime preStartTm, DateTime scheduleStartTm){
		// 指定の店舗コードで取得、関連の予約情報を出力する
		shopCode = shopCd;
		pQueryDt = queryDt;
		//isBatchExecuteFlg = isBatchFlg;
		curBatchExcTime = scheduleStartTm;
		preBatchExcTime = preStartTm;
		// 2017/10/27 GROUP功能对应 WGCH BEGIN
		groupAbleFlg = expandFlg = false;
		// 2017/10/27 GROUP功能对应 WGCH END
		// 2019/06/28 ユーザ側で非表示にした項目対応 WGCH BEGIN
		isBatchRunFlg = true;
		// 2019/06/28 ユーザ側で非表示にした項目対応 WGCH END
	}
	//public Pagereference getCurrPageInfo () {
	//	PageReference pdf = Page.K_ScheduleReportPdf;
	//	pdf.setRedirect(false);
	//	return pdf;
	//}
	// 2017/05/12 PDFpost等机能对应 END By Wgch
	public void init(){
		// -------------------------------------
		// カスタム項目設定情報処理
		// -------------------------------------
		try{
			// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
			opInfoMap = new Map<String, String>{BLANK => ''};
			// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
			// 2017/05/12 PDFpost等机能对应 BEGIN By Wgch
			// 指定の店舗コードで取得、関連の予約情報を出力する
			//String shopCode = CommUtils.nullToBlank(ApexPages.currentPage().getParameters().get('sp'));
			//String pQueryDt = CommUtils.nullToBlank(ApexPages.currentPage().getParameters().get('dt'));
			// 2017/05/12 PDFpost等机能对应 END By Wgch
			// カスタム表示用項目を初期化する
			List<String> fieldsSplits = parseFieldsXml(shopCode).split(',');
			Set<String> leadSqlFieldsSet = new Set<String>();
			// APIリスト関連情報を格納する
			// 2017/05/12 PDFpost等机能对应 BEGIN By Wgch
			//leadApiLst = new List<String>();
			leadApiLst = new List<LeadApi>();
			//Api字段对应的颜色
			apiColorMap = new Map<String,String>{'created'=>''};
			// 2017/05/12 PDFpost等机能对应 END By Wgch
			leadApiLabelMap = new map<String, String>();
			// 2019/06/28 ユーザ側で非表示にした項目対応 WGCH BEGIN
			Integer custidx = 0;
			Integer oldidx = Integer.valueOf(isShowFoodPosition);
			// COOKIE設定情報を取得する
			CookieInf cookieInf = getCookieInf(shopCode);
			// 2019/06/28 ユーザ側で非表示にした項目対応 WGCH END
			// 2020/02/28 同伴者情報列位置自定义改善对应 WGCH BEGIN
			Integer oldGuestIdx = Integer.valueOf(isShowGuestPosition);
			// 2020/02/28 同伴者情報列位置自定义改善对应 WGCH END
			// 合計値格納
			// XMLに定義された表示項目リスト取得、処理を行う
			for (String item : fieldsSplits) {
				String[] keySplits = item.split(':');
				if (keySplits.size() != 2) { continue;}
				String key = CommUtils.nullToBlank(keySplits[0]);
				String lab = CommUtils.nullToBlank(keySplits[1]);
				if(!leadApiLabelMap.containsKey(key)){
					// 2019/06/28 ユーザ側で非表示にした項目対応 WGCH BEGIN
					if(!pdfNoHiddenColnumFlg && !isBatchRunFlg){
						custidx++;
						Boolean runFlg = true;
						if(CookieInf.colnumHidMap.containsKey('detailList') && CookieInf.colnumHidMap.get('detailList')) isShowFoodInfo = false;
						if(CookieInf.colnumHidMap.containsKey('contactList') && CookieInf.colnumHidMap.get('contactList')) isShowGuestInfo = false;
						// 取cookie里的隐藏值
						if(CookieInf.colnumHidMap.containsKey(key)){
							runFlg = false;
							if(CookieInf.colnumHidMap.get(key)){
								if(oldidx >= custidx && isShowFoodPosition > 0) isShowFoodPosition--;
								// 2020/02/28 同伴者情報列位置自定义改善对应 WGCH BEGIN
								if(isShowGuestPositionFlg && oldGuestIdx >= custidx && isShowGuestPosition > 0) isShowGuestPosition--;
								// 2020/02/28 同伴者情報列位置自定义改善对应 WGCH END
								continue;
							}
						}
						// 初期非表示項目場合
						if(customHidFields.contains(key) && runFlg){
							if(oldidx >= custidx && isShowFoodPosition > 0) isShowFoodPosition--;
							// 2020/02/28 同伴者情報列位置自定义改善对应 WGCH BEGIN
							if(isShowGuestPositionFlg && oldGuestIdx >= custidx && isShowGuestPosition > 0) isShowGuestPosition--;
							// 2020/02/28 同伴者情報列位置自定义改善对应 WGCH END
							continue;
						}
					}
					// 2019/06/28 ユーザ側で非表示にした項目対応 WGCH END
					// 2017/05/12 PDFpost等机能对应 BEGIN By Wgch
					LeadApi lead = new LeadApi(key);
					apiColorMap.put(lead.leadApiStrAf,''); 
					//leadApiLst.add(key);
					leadApiLst.add(lead);
					// 2017/05/12 PDFpost等机能对应 END By Wgch
					leadApiLabelMap.put(key, lab);
					if(!avgSumMap.containsKey(key)) avgSumMap.put(key, -9999);
				}
				// 2017/10/27 GROUP功能对应 WGCH BEGIN
				// 去掉不符合条件的API
				if(!grpTitlApiSet.contains(key)){
					grpTitlApiSet.remove(key);
					grpAggrApiSet.remove(key);
				}
				// 2017/10/27 GROUP功能对应 WGCH END
			}
			// 部屋リストを取得する
			roomList = getRoomList(shopCode);
			// リンクする項目関連設定はSQLから検索必要の項目情報に格納する
			// 2017/05/12 PDFpost等机能对应 BEGIN By Wgch
			// leadSqlFieldsSet.addAll(leadApiLst);
			// Lead API 字段
			// 2017/06/06 XMLのAPI定義小文字、大文字区別されない対応 BEGIN
			for (String xmlApiKey : leadApiLabelMap.keySet()) {
				string lowApiKey = CommUtils.nullToBlank(xmlApiKey).toLowerCase();
				leadSqlFieldsSet.add(lowApiKey);
			}
			// 2017/06/06 XMLのAPI定義小文字、大文字区別されない対応 END
			// 2017/05/12 PDFpost等机能对应 END By Wgch
			// 既存固定定義している予約検索のＳＱＬを取得する
			queryLeadStr = queryConstLeadStr + ',' + queryRoomStr;
			// 固定定義されている項目リストを取得する
			String[] constLeadFields = queryLeadStr.deleteWhitespace().split(',');
			// 2017/10/10 予定表を表示のとき、部屋順で表示できる改善対応 WGCH BEGIN
			// 2018/02/02 予定表とタイムテーブルの並びを変えたい WGCH BEGIN
			// constLeadFields.add(sortField);
			leadSqlFieldsSet.add(CommUtils.nullToBlank(sortField).toLowerCase());
			// 2018/02/02 予定表とタイムテーブルの並びを変えたい WGCH END
			// 2017/10/10 予定表を表示のとき、部屋順で表示できる改善対応 WGCH END
			// カスタム項目をＳＱＬへ追加する
			for (String field : constLeadFields) {
				// 2017/06/06 XMLのAPI定義小文字、大文字区別されない対応 BEGIN
				//String key = field;
				String key = CommUtils.nullToBlank(field).toLowerCase();
				// 2017/06/06 XMLのAPI定義小文字、大文字区別されない対応 END
				// 該当項目が既に存在する場合、
				leadSqlFieldsSet.remove(key);
			}
			// カスタム項目は存在する場合、ＳＱＬに追加する
			for (String apiName : leadSqlFieldsSet) {
				queryLeadStr += ',' + apiName;
			}
			// -------------------------------------
			// 料理集計設定情報を取得する
			// -------------------------------------
			// 料理抽出条件を設定する場合、該当条件でデータ抽出を行う
			String whereStr = CommConst.getKScheduleReportWhere();
			// 朝食キー
			Set<String> moringFoodkeySet = new Set<String>();
			if (!String.isEmpty(whereStr)) {
				String[] whereLst = whereStr.split(',');
				filterOpList.clear();
				for (String key : whereLst) {
					String[] subKey = key.split(':');
					filterOpList.add(subKey[0]);
					// 朝食キーが存在
					if (subKey.size() > 1) moringFoodKeySet.add(subKey[0]);
				}
			}
			// 朝食のOP類別情報IDを格納する
			if (!moringFoodkeySet.isEmpty()) moringFoodOpIdSet = getMoringFoodOpIdSet(moringFoodkeySet);
			// 抽出条件を固定設定する
			// *****************************
			// 指定店舗
			// 当日
			// 取得範囲は１日分
			String area = shopCode;
			Boolean bRoomViewFlg = true;
			// データ抽出日
			//Date todayDt = Date.newInstance(2017,4,11);
			Date todayDt = Date.today();
			// バッチから起動の日付情報で設定する
			if (!CommUtils.isBlank(pQueryDt)) todayDt = CommUtils.stringToDate(pQueryDt);//Date.valueOf(pQueryDt);
			// 週間抽出最大日付
			// 2017/10/10 WGCH BEGIN
			// Integer plusDays = 1;
			Integer plusDays = termDates == null ? 1 : termDates;
			termDtFlg = plusDays > 1;
			// 2017/10/10 WGCH END
			Date weekedDt = todayDt.addDays(plusDays);
			// ******** 予約の検索条件 ********** //
			// 有効な予約データ
			String queryWhere = ' Where CancelBool__c != ' + CommConst.LEAD_ST_CANCEL_FLG;
			// 店舗コードにより、関連チェックを行う　
			if (!CommUtils.isBlank(shopCode)) queryWhere += ' And (refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c = :shopCode or Rroom__r.ShopInfoRef__r.ShopCode__c = :shopCode ) ';
			// 到着日は当日
			// 到着日は週間の範囲で予約データを取得する
			queryWhere += ' And DAY_ONLY(convertTimezone(EntryTime__c)) >= :todayDt ';
			queryWhere += ' And DAY_ONLY(convertTimezone(EntryTime__c)) < :weekedDt ';
			// 2017/09/18 予定表に表示したく無い部屋のSEQ#をカンマで複数定義するに改善対応 WGCH BEGIN
			if (!noRmSeqSet.isEmpty()) queryWhere += ' And Rroom__r.Seq__c Not in: noRmSeqSet ';
			// 2017/09/18 予定表に表示したく無い部屋のSEQ#をカンマで複数定義するに改善対応 WGCH END
			// 2019/08/15 予定表の部屋タイプ絞り込みは予定表内のフィルター機能が改善ほしい by zy BEGIN
			if (!typeSet.isEmpty()) queryWhere += ' and refTypeOfRooms__c in :typeSet';
			// 2019/08/15 予定表の部屋タイプ絞り込みは予定表内のフィルター機能が改善ほしい by zy END
			// 2021/05/31 予定表のレイアウトを複数パターンから切り替えられるようにしたいユーザ単位で保存できるように by zy BEGIN
			String roomIdStr = CommUtils.nullToBlank(pRoomIds);
			Set<String> roomIds = new Set<String>();
			if (!Commutils.isBlank(roomIdStr)) {
				for (String value : roomIdStr.split(',')) {
					if (!CommUtils.isblank(value)) {
						String[] roomArr = value.split('_');
						if (roomArr.size() > 1) {
							String roomId = roomArr[0];
							roomIds.add(roomId);
						}
					}
				}
			}
			if (!roomIds.isEmpty()) {
				queryWhere += ' and Rroom__c in :roomIds';
			}
			// 2021/05/31 予定表のレイアウトを複数パターンから切り替えられるようにしたいユーザ単位で保存できるように by zy END
			// アサイン部屋
			// 2013/11/04 部屋アサイン以外の有効な予約も料理集計対象になる
			
			// ******** 予約見積もり明細の検索条件 ********** //
			// 予約見積もり明細の商品種別は「プラン」以外(プラン明細のBreakDownの見積もり明細も対象外する)
			String queryLdWhere = ' Where ParentBookingItemRef__c = null And ActionType__c NOT IN ( \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_PL) + '\', \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_NO) + '\' ) ';
			// ******** 会計明細の検索条件 ********** //
			// 会計明細の商品種別「プラン」以外(会計データは集計対象が必要)
			String processType = '00';
			String queryTranWhere = ' Where Field1__r.Field39__c = :processType And ActionType__c NOT IN ( \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_PL) + '\', \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_NO) + '\' ) ';
			
			String OrKey = 'OR';
			// 料理のＦｉｌｔｅｒキーリスト
			if (!filterOpList.isEmpty()) {
				queryLdWhere += ' And ( ';
				queryTranWhere += ' And ( ';
				for (String key : filterOpList) {
					queryLdWhere += ' OP__r.Name like \'%' + CommUtils.escStr(key) + '%\' ' + OrKey;
					// 会計明細にOP項目がないため、直接商品のOP情報を使う
					queryTranWhere += ' Field7__r.OP__r.Name like \'%' + CommUtils.escStr(key) + '%\' ' + OrKey;
				}
				// 最後のＯＲを削除する
				queryLdWhere = queryLdWhere.substringBeforeLast(OrKey);
				queryLdWhere += ' ) ';
	
				queryTranWhere = queryTranWhere.substringBeforeLast(OrKey);
				queryTranWhere += ' ) ';
			}
			// 予約データを検索を行う、検索結果から、部屋リストにマージする
			String querySubStr = queryLdStr + queryLdWhere + ' Order By Name ';
			// 2017/10/10 WGCH BEGIN
			String queryStr = ' Select '+ queryLeadStr + ',(' + querySubStr + ') From Lead__c ' + queryWhere + ' Order By EntryTime__c ';
			// 2017/10/10 WGCH END
			// 存在の予約情報を取得する[到着日は指定日の有効な予約情報を取得する]
			// 2017/05/12 PDFpost等机能对应 BEGIN By Wgch
			// 查之前就得保存当前的时间,才查的全
			if (curBatchExcTime == null) curBatchExcTime = DateTime.now();
			// 2017/05/12 PDFpost等机能对应 END By Wgch
			List<Lead__c> reportLst = DataBase.query(queryStr);
			// 2017/05/12 PDFpost等机能对应 BEGIN By Wgch
			// 2019/08/15 予定表上にも、ルームインジケータのような検索欄が欲しい by zy BEGIN
			Set<String> contactFilter = new Set<String>();
			Set<String> leadFilter = new Set<String>();
			set<String> roomFilter = new Set<String>();
			if (!CommUtils.isBlank(filterStr) && !reportLst.isEmpty()) {
				List<Id> contactIds = new List<Id>();
				Set<Id> leadIds = new Set<Id>();
				Set<Id> roomIdSet = new Set<Id>();
				Map<String,List<Lead__c>> contactMap = new Map<String,List<Lead__c>>();
				for ( Lead__c lead : reportLst) {
					contactIds.add(lead.relcontact__c);
					leadIds.add(lead.id);
					if (lead.Rroom__c != null) roomIdSet.add(lead.Rroom__c);
				}
				String filterText = filterStr;
				String leadWhereStr = 'where id=:contactIds';
				String findQuery = 'FIND :filterText IN ALL FIELDS RETURNING Contact(Id ' + leadWhereStr + ')';
				List<List<Sobject>> leadRs = search.query(findQuery);
				List<Contact> contacts = leadRs[0];
				for (Contact con : contacts) {
					contactFilter.add(con.id);
				}
				leadWhereStr = ' where id=:leadIds';
				findQuery = 'FIND :filterText IN name FIELDS RETURNING ps__Lead__c(id' + leadWhereStr + ')';
				leadRs = search.query(findQuery);
				List<Lead__c> leads = leadRs[0];
				if (!leads.isEmpty()) {
					for(Lead__c l : leads) {
						leadFilter.add(l.id);
					}
				}
				if (!roomIdSet.isEmpty()) {
					leadWhereStr = ' where id=:roomIdSet';
					findQuery = 'FIND :filterText IN name FIELDS RETURNING ps__Room__c(id' + leadWhereStr + ')';
					leadRs = search.query(findQuery);
					List<Room__c> rooms = leadRs[0];
					if (!rooms.isEmpty()) {
						for(Room__c l : rooms) {
							roomFilter.add(l.id);
						}
					}
				}
				List<Lead__c> filterLst = new  List<Lead__c>();
				for (Lead__c lead : reportLst) {
					if (!contactFilter.contains(lead.relcontact__c) && !leadFilter.contains(lead.id) && !roomFilter.contains(lead.Rroom__c)) continue;
					filterLst.add(lead);
				}
				reportLst = filterLst;
			}
			// 2019/08/15 予定表上にも、ルームインジケータのような検索欄が欲しい by zy END
			// 2017/10/27 GROUP功能对应 WGCH BEGIN
			if(groupAbleFlg) getGrpTitlInfoMap(reportLst);
			// 2017/10/27 GROUP功能对应 WGCH END
			// 2017/04/27 料理数目变更之后变颜色对应 BEGIN By Wgch
			// 初期Loadの場合
			// かならず「xmlConfigProcess」以後呼出
			// 设置默认post flg
			isBatchStartFlg = (preBatchExcTime == null ? true : false);
			// batch第一次执行post处理会进去
			/*
			if(isBatchExecuteFlg){
				// 对应的店铺没有数据就不post处理 否则直接post处理
				if(reportLst.isEmpty()) return;
				else isBatchStartFlg = true;
			}*/
			// 初期化batch最终更新时间
			DateTime batchLastTm = null;
			// 为了查当天有效的数据 日期处理
			//Date theDayBefore = todayDt.addDays(-1);
			String oldSumaryJson = '';
			String oldSumary2Json = '';
			// 查找有效的上次post料理集計Json数据
			reservationFoodSum = [Select Id,FoodSumType__c,FoodSumData__c,FoodSumData2__c,FoodSumData3__c,ShopInfoRef__r.ShopCode__c,BatchLastTm__c,EntryDate__c from ReservationListWork__c 
						where EntryDate__c =:todayDt And FoodSumType__c != null And ShopInfoRef__r.ShopCode__c =: shopCode limit 3];
			// 有无历史数据Flg
			isFirstLoadFlg = reservationFoodSum.isEmpty();
			oldPerSumaryData = new Map<String, Map<String,Object>>();
			for(ReservationListWork__c res : reservationFoodSum){
				// 每行予約料理集計Json数据
				if(res.FoodSumType__c == LEADFOODSUM){
					String oldPerSumaryJson = jsonMerger(res.FoodSumData__c,res.FoodSumData2__c,res.FoodSumData3__c);
					// 每一行料理的oldData
					if(!CommUtils.isBlank(oldPerSumaryJson)){
						oldPerSumaryData = new Map<String, Map<String,Object>>();
						Map<String, Object> wkOldPerSumaryData = (Map<String, Object>)JSON.deserializeUntyped(oldPerSumaryJson);
						for (String key : wkOldPerSumaryData.keySet()) {
							oldPerSumaryData.put(key, (Map<String, Object>)wkOldPerSumaryData.get(key));
						}
					}
				}
				// 見積料理集計Json数据
				if(res.FoodSumType__c == REPORTFOODSUM)
				oldSumaryJson = jsonMerger(res.FoodSumData__c,res.FoodSumData2__c,res.FoodSumData3__c);
				// 会計料理集計Json数据
				if(res.FoodSumType__c == ACCOUNTFOODSUM)
				oldSumary2Json = jsonMerger(res.FoodSumData__c,res.FoodSumData2__c,res.FoodSumData3__c);
			}
			// 2017/04/27 料理数目变更之后变颜色对应 END By Wgch
			// 查找当天是否post过
			/*
			List<ReservationListWork__c> reservation = [Select Id,BatchLastTm__c,DateType__c,ShopInfoRef__r.ShopCode__c,FoodSumType__c from ReservationListWork__c 
														where FoodSumType__c = null And EntryDate__c =: todayDt And DateType__c =:BATCH And ShopInfoRef__r.ShopCode__c =: shopCode limit 1];
			// 如果有就把最后的时间得到查找这段时间里是否变更过
			if(!reservation.isEmpty()){
			*/
			// 2017/10/10 WGCH BEGIN
			/*
			// 変更履歴関連の比較処理
			if (preBatchExcTime != null) {
				//batchLastTm = reservation[0].BatchLastTm__c;
				batchLastTm = preBatchExcTime;
				historyMap = getTodayLeadHistory(reportLst,batchLastTm,curBatchExcTime);
				if(!historyMap.isEmpty()){
					colorJsonMap = new map<String ,Map<String,String>>();
					for (Lead__c lead : reportLst) {
						Map<String,String> cloneMap = apiColorMap.clone();
						//履歷一覽
						LeadHistories.LeadHistoryItem historyItem = new LeadHistories.LeadHistoryItem();
						if(historyMap.containsKey(lead.id)) historyItem = historyMap.get(lead.id);
						if(!Commutils.isBlank(historyItem.leadId)){
							Map<String,DateTime> fieldHisMap = new Map<String,DateTime>();
							// 该Map是过滤完成后, 这笔Lead里 所有API 显示颜色的数据源
							String namespace = CommConst.APPOTION_NAMESPACE;
							// 既存の履歴情報から変更回数を計算する
							List<LeadHistories.ObjectHistoryLine> leadHistoryLst = historyItem.histories;
							for (LeadHistories.ObjectHistoryLine item : leadHistoryLst) {
								String api = item.s.Field.toLowerCase();
								if(!CommUtils.isBlank(nameSpace) && api.startsWith(nameSpace)) api = api.substringAfter(nameSpace);
								if(!apiColorMap.containsKey(api)) continue;
								//if(api == 'created') cloneMap.put('created',xmlColorStyle());
								//else cloneMap.put(api,xmlColorStyle());
								cloneMap.put(api,xmlColorStyle());
							}
						}
						colorJsonMap.put(lead.Id,cloneMap);
					}
				}
			}
			*/
			// 2017/10/10 WGCH END
			// 2017/05/12 PDFpost等机能对应 END By Wgch
			// 予約明細情報を格納
			List<ReportRow> repLst = new List<ReportRow>();
			// 料理集計情報を格納[Key/合計情報]
			Map<String, ReportSumRow> prodSumMap = new Map<String, ReportSumRow>();
			// 料理集計情報を格納[Key/合計情報] (チェックイン後)
			Map<String, ReportSumRow> prodSumMap2 = new Map<String, ReportSumRow>();
			// 予約データを取得を行う
			// 部屋割り当て済みの予約情報を格納する<日付, MAP<部屋ID,予約リスト>>
			Map<Date, Map<Id, List<Lead__c>>> weekLeadRoomMap = new Map<Date, Map<Id, List<Lead__c>>>();
			// 部屋未割り当ての予約情報を格納する　<日付, LIST<予約情報>>
			Map<Date, List<Lead__c>> weekNoAssigneLeadMap = new Map<Date, List<Lead__c>>();
			// １週間情報格納初期化
			Integer termMaxDays = todayDt.daysBetween(weekedDt);
			for (Integer i=0; i < termMaxDays; i++) {
				weekLeadRoomMap.put(todayDt.addDays(i), new Map<Id, List<Lead__c>>());
				weekNoAssigneLeadMap.put(todayDt.addDays(i), new List<Lead__c>());
			}
			// プランの商品存在する場合、プラン関連の商品一覧を取得する
			Set<Id> noCheckInIdSet = new Set<Id>();
			// すでにチェックイン済みの予約情報を取得する
			Set<Id> checkInedIdSet = new Set<Id>();
	
			// 見割り合っての予約情報を格納する
			// 2017/10/10 WGCH BEGIN
			// 2017/10/27 GROUP功能对应 WGCH BEGIN
			// Map<Date, List<ReportRow>> repMap = new Map<Date, List<ReportRow>>();
			dataAllMap = new Map<Date, LeadInfo>();
			// 2017/10/27 GROUP功能对应 WGCH END
			Map<Date, List<Lead__c>> leadMap = new Map<Date, List<Lead__c>>();
			keyDateLst = new List<Date>();
			// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
			// Map<日期, List<商品code_单价>>
			keyDateStrMap = new Map<Date, List<String>>();
			// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
			// 2017/10/10 WGCH END	
			// 部屋別に予約情報に格納する
			for (Lead__c lead : reportLst) {
				// 到着日日付を取得する
				Date entryDt = lead.EntryTime__c.date();
				// 2017/10/10 WGCH BEGIN
				if(!leadMap.containsKey(entryDt)) {
					keyDateLst.add(entryDt);
					leadMap.put(entryDt, new List<Lead__c>());
					// 2017/10/27 GROUP功能对应 WGCH BEGIN
					// repMap.put(entryDt, new List<ReportRow>());
					dataAllMap.put(entryDt, new LeadInfo());
					// 2017/10/27 GROUP功能对应 WGCH END
				}
				leadMap.get(entryDt).add(lead);
				// 2017/10/10 WGCH END
				// 2016/11/24 BUG FIX BEGIN
				if (!weekNoAssigneLeadMap.containsKey(entryDt)) continue;
				// 部屋未割り当ての場合
				if (lead.Rroom__c == null) weekNoAssigneLeadMap.get(entryDt).add(lead);
				else {
					// 部屋割り当て済みの場合
					if (!weekLeadRoomMap.get(entryDt).containsKey(lead.Rroom__c)) {
						weekLeadRoomMap.get(entryDt).put(lead.Rroom__c, new List<Lead__c>());
					}
					// 部屋単位の予約情報を格納する
					weekLeadRoomMap.get(entryDt).get(lead.Rroom__c).add(lead);
				}
				// 2013/10/22 MODIFY BEGIN
				// 予約情報IDを格納する
				// すでにチェックイン済みの予約IDリストを取得して、会計明細情報を取得する
				if (!CommUtils.isBlank(lead.field298__c)) {
					// 既にチェックインの予約ID配列格納する
					checkInedIdSet.add(lead.Id);
				} else {
					// 未チェックイン予約ID配列格納する
					noCheckInIdSet.add(lead.Id);
				}
			}
			// 2017/10/10 WGCH BEGIN
			// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH BEGIN
			getContactData(leadMap.get(todayDt));
			// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH END
			// 変更履歴関連の比較処理
			if (preBatchExcTime != null) {
				//batchLastTm = reservation[0].BatchLastTm__c;
				batchLastTm = preBatchExcTime;
				historyMap = getTodayLeadHistory(leadMap.get(todayDt),batchLastTm,curBatchExcTime);
				if(!historyMap.isEmpty()){
					colorJsonMap = new map<String ,Map<String,String>>();
					for (Lead__c lead : leadMap.get(todayDt)) {
						Map<String,String> cloneMap = apiColorMap.clone();
						//履歷一覽
						LeadHistories.LeadHistoryItem historyItem = new LeadHistories.LeadHistoryItem();
						if(historyMap.containsKey(lead.id)) historyItem = historyMap.get(lead.id);
						if(!Commutils.isBlank(historyItem.leadId)){
							Map<String,DateTime> fieldHisMap = new Map<String,DateTime>();
							// 该Map是过滤完成后, 这笔Lead里 所有API 显示颜色的数据源
							String namespace = CommConst.APPOTION_NAMESPACE;
							// 既存の履歴情報から変更回数を計算する
							List<LeadHistories.ObjectHistoryLine> leadHistoryLst = historyItem.histories;
							for (LeadHistories.ObjectHistoryLine item : leadHistoryLst) {
								String api = item.s.Field.toLowerCase();
								if(!CommUtils.isBlank(nameSpace) && api.startsWith(nameSpace)) api = api.substringAfter(nameSpace);
								if(!apiColorMap.containsKey(api)) continue;
								//if(api == 'created') cloneMap.put('created',xmlColorStyle());
								//else cloneMap.put(api,xmlColorStyle());
								cloneMap.put(api,xmlColorStyle());
							}
						}
						colorJsonMap.put(lead.Id,cloneMap);
					}
				}
			}
			// 2017/10/10 WGCH END
			// 会計明細「プラン」以外の会計明細情報を取得する
			// ***************************************************
			// チェックイン済みの会計の関連会計IDにより、明細情報を取得する[料理のみ]
			queryTranWhere += ' And Field1__r.Relreserve__c in :checkInedIdSet ';
			// 会計明細【プラン以外」の情報を取得する、
			queryStr = queryTranStr + queryTranWhere + ' Order By Name ';
	
			List<Tran1__c> checkInTranLst = new List<Tran1__c>();
			if (!checkInedIdSet.isEmpty()) checkInTranLst = DataBase.query(queryStr);
			// 会計明細から取得する料理情報は見積もり明細方式に転換、設定を行う（統計便利するため）
			// ID(予約ID/ List<見積もり明細>)
			Map<Id, List<BookingEstimateItem__c>> tranCookingMap = new Map<Id, List<BookingEstimateItem__c>>();
			for (Tran1__c tran : checkInTranLst) {
				Id leadId = tran.Field1__r.Relreserve__c;
				if (!tranCookingMap.containsKey(leadId)) tranCookingMap.put(leadId, new List<BookingEstimateItem__c>());
				tranCookingMap.get(leadId).add(
						 new BookingEstimateItem__c(
							refBooking__c = leadId,
							refAccountMaster__c = tran.Field7__c,
							Field3__c = tran.Field7__r.Field3__c,
							ProductName__c = tran.Field5__c,
							OP__c = tran.Field7__r.OP__c,
							// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
							OP__r = tran.Field7__r.OP__r,
							// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
							// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
							X3_2__c = Commutils.nullToBlank(Commutils.nullToZero(tran.Tankanonetax__c)), // 税拔
							X4_3__c = Commutils.nullToBlank(Commutils.nullToZero(tran.Field39__c)), // 税込
							// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
							// 2019/06/28 「サ抜税込」「サ抜税抜」の選択肢対応 WGCH BEGIN
							UnitPriceDefKb__c = Commutils.nullToBlank(tran.UnitPriceDefKbCal__c),
							TaxRate__c = Commutils.nullToZero(tran.TaxRate__c),
							ServiceRate__c = Commutils.nullToZero(tran.ServiceRate__c),
							UnitPrice__c = Commutils.nullToZero(tran.Field20__c),
							SpecialTax__c = Commutils.nullToZero(tran.SpecialTax__c),
							// 2019/06/28 「サ抜税込」「サ抜税抜」の選択肢対応 WGCH END
							Amount__c = tran.Field40__c,
							refAccountMaster__r = tran.Field7__r
						)
				);
			}
			// ***************************************************
			// Lead__c ->　見積もり明細に含めた商品（プラン）
			Map<Id, List<Id>> leadPlanProdMap = new Map<Id, List<Id>>();
			Map<Id, List<BookingEstimateItem__c>> leadEstItemMap = new Map<Id, List<BookingEstimateItem__c>>();
			// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
			// 見積もり明細Id集合
			Set<String> pEstItemIdSet = new Set<String>();
			// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
	
			// 予約のプラン明細に料理存在の予約を取得する[未チェックイン予約プランとプランBreakDown情報を取得する]
			String planProdType = CommConst.PROD_ACTION_TYPE_PL;
			String planQueryStr = ' select id ,(' + queryLdStr + ' where ActionType__c = :planProdType OR ParentBookingItemRef__c != null) From Lead__c where id in :noCheckInIdSet';
			List<Lead__c> planLead = Database.query(planQueryStr);
			// BreakDown存在する見積もり明細（プラン）情報を格納する Map<見積もり明細PLAN、見積もり明細PLANのBreakDown情報>
			Map<Id, List<BookingEstimateItem__c>> existBreakDownEstItemMap = new Map<Id, List<BookingEstimateItem__c>>();
			// 会計明細「プラン」関連情報を取得する
			
			// 予約データからプラン含めの見積もり明細データを取得する
			Set<Id> planProdIdSet = new Set<Id>();
			// プランを含めの予約データ
			for (Lead__c l : planLead) {
				// 2013/10/25 該当プランは既にBreakDown明細が存在する場合、該当プランは検索対象外
				// 予約→商品（プラン）関連情報格納
				leadPlanProdMap.put(l.Id, new List<Id>());
				// 予約→見積もり明細リスト情報を格納する
				leadEstItemMap.put(l.Id, new List<BookingEstimateItem__c>());
				
				for (BookingEstimateItem__c estItem : l.BookingEstimateItemFgKu__r) {
					
					// 予約→商品（プラン）のBreakDown見積もり明細情報を格納する
					if (estItem.ParentBookingItemRef__c != null) {
						Id parentId = estItem.ParentBookingItemRef__c;
						if (!existBreakDownEstItemMap.containsKey(parentId)) {
							existBreakDownEstItemMap.put(parentId, new List<BookingEstimateItem__c>());
						}
						// 該当プランのBreakDown商品は料理が含めする場合、配列に追加する
						if (isCookingByWord(estItem.OP__r.Name)) existBreakDownEstItemMap.get(parentId).add(estItem);
						continue;
					}
					
					// プラン情報を格納して、関連のプラン明細の商品リストを取得するため
					// Ｍａｔｃｈ用予約ＩＤ→プラン（会計商品）配列
					leadPlanProdMap.get(l.Id).add(estItem.refAccountMaster__c);
					// 商品（プラン）ＩＤを追加する
					planProdIdSet.add(estItem.refAccountMaster__c);
					// Ｍａｔｃｈ用予約ＩＤ→見積もり明細(プラン OR 普通の見積もり明細)を格納する
					leadEstItemMap.get(l.Id).add(estItem);
					// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
					pEstItemIdSet.add(estItem.Id);
					// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
				}
			}
			// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
			// 2019/08/13 BUG修正 WGCH BEGIN
			/*
			// Map<预约Id_商品Id, List<見積もり明細>>
			Map<String, List<BookingEstimateItem__c>> leadpEstItemIdMap = new Map<String, List<BookingEstimateItem__c>>();
			if(unitpriceColShow){
				// 2019/06/28 「サ抜税込」「サ抜税抜」の選択肢対応 WGCH BEGIN
				for(BookingEstimateItem__c estItem : [Select Id, Tankanonetax__c, unitPriceIncTaxCal__c, ParentBookingItemRef__c, refAccountMaster__c, refBooking__c, UnitPriceDefKb__c, TaxRate__c, ServiceRate__c, UnitPrice__c, SpecialTax__c, Amount__c From BookingEstimateItem__c Where ParentBookingItemRef__c in: pEstItemIdSet]){
				// 2019/06/28 「サ抜税込」「サ抜税抜」の選択肢対応 WGCH END
					String key = getPlanItemKey(estItem.refBooking__c, estItem.refAccountMaster__c);
					if(!leadpEstItemIdMap.containsKey(key)) leadpEstItemIdMap.put(key, new List<BookingEstimateItem__c>());
					leadpEstItemIdMap.get(key).add(estItem);
				}
			}
			*/
			// 2019/08/13 BUG修正 WGCH END
			// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
			// プラン明細に格納している[上記プラン定義されている見積もり明細（プラン）のプラン明細定義情報を取得する[プラン明細は料理の前提条件あり]
			// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
			// 2019/08/13 BUG修正 WGCH BEGIN
			Map<Id, List<PlanDetail__c>> planBrkMap = new Map<Id, List<PlanDetail__c>>();
			// String planDlStr = ' Select PlanProdcut__c,AccountMasterRef__c, AccountMasterRef__r.OP__c, AccountMasterRef__r.OP__r.Name, AccountMasterRef__r.Field3__c, AccountMasterRef__r.Name from PlanDetail__c where PlanProdcut__c in :planProdIdSet ';
			String planDlStr = ' Select PlanProdcut__c,AccountMasterRef__c, AccountMasterRef__r.OP__c, AccountMasterRef__r.OP__r.Name, AccountMasterRef__r.Field3__c, AccountMasterRef__r.Name, AccountMasterRef__r.Field5__c, Price__c, TaxRate__c, ServiceRate__c from PlanDetail__c where PlanProdcut__c in :planProdIdSet ';
			// 2019/08/13 BUG修正 WGCH END
			// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
			// 料理のＦｉｌｔｅｒキーリスト
			if (!filterOpList.isEmpty()) {
				planDlStr += ' And ( ';
				for (String key : filterOpList) {
					planDlStr += ' AccountMasterRef__r.OP__r.Name like \'%' + CommUtils.escStr(key) + '%\' ' + OrKey;
				}
				// 最後のＯＲを削除する
				planDlStr = planDlStr.substringBeforeLast(OrKey);
				planDlStr += ' ) ';
			}
			List<PlanDetail__c> planDlList = DataBase.query(planDlStr);
	
			// プラン明細に含めている料理情報を格納<会計商品(プラン)ID/該当プランに含めするプラン明細（料理）配列
			Map<Id, List<AccountMaster__c>> cookingProdMap = new Map<Id, List<AccountMaster__c>>();
			for (PlanDetail__c detail : planDlList) {
				// プランに含めた明細商品に、料理対象データが存在する場合
				if (!cookingProdMap.containsKey(detail.PlanProdcut__c)) cookingProdMap.put(detail.PlanProdcut__c, new List<AccountMaster__c>());
				cookingProdMap.get(detail.PlanProdcut__c).add(detail.AccountMasterRef__r);
				// 2019/08/13 BUG修正 WGCH BEGIN
				if (!planBrkMap.containsKey(detail.PlanProdcut__c)) planBrkMap.put(detail.PlanProdcut__c, new List<PlanDetail__c>());
				planBrkMap.get(detail.PlanProdcut__c).add(detail);
				// 2019/08/13 BUG修正 WGCH END
			}
			// 朝食料理情報格納変数初期化
			ReportSumRow moringFood = new ReportSumRow();
			moringFood.sortKey = CONST_MON_FOOD_CD;
			moringFood.middayIcon = '';
			// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
			moringFood.op = '';
			// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
			//朝食
			moringFood.productName = Label.CONST_041_0038; 
			// チェックイン後の朝食数
			ReportSumRow moringFood2 = new ReportSumRow();
			moringFood2.sortKey = CONST_MON_FOOD_CD;
			moringFood2.middayIcon = '';
			// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
			moringFood2.op = '';
			// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
			//朝食
			moringFood2.productName = Label.CONST_041_0038; 
			// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
			// 見積明細Map<商品code_单价, 数据集合>
			Map<String, ReportSumRow> moringFoodMap = new Map<String, ReportSumRow>();
			// 会計明細Map<商品code_单价, 数据集合>
			Map<String, ReportSumRow> moringFood2Map = new Map<String, ReportSumRow>();
			// 获取商品code与单价合成的key
			String moringFoodKey = getMoringFoodKey(CONST_MON_FOOD_CD, '');
			moringFoodMap.put(moringFoodKey, moringFood.clone());
			moringFood2Map.put(moringFoodKey, moringFood2.clone());
			// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
			// 部屋順番で予約データを取得する、マージ処理を行う
			List<ReportRow> subLst = new List<ReportRow>();
			Integer idx = 0;
			// 2016/01/06 朝食 不具合改修
			// 2017/10/10 WGCH BEGIN
			// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
			/*
			Map<Date,ReportSumRow> moringFoodDetail1Map = new Map<Date,ReportSumRow>();
			Map<Date,ReportSumRow> moringFoodDetail2Map = new Map<Date,ReportSumRow>();
			*/
			// 見積明細Map<日期_商品code_单价, 数据集合>
			Map<String,ReportSumRow> moringFoodDetail1Map = new Map<String,ReportSumRow>();
			Map<String,ReportSumRow> moringFoodDetail2Map = new Map<String,ReportSumRow>();
			// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
			// 2017/10/10 WGCH END
			// 2016/01/06
			// 週間データ設定を行う
			// 2017/10/10 WGCH BEGIN
			map<Date, map<string, map<string,list<ReportSumRow>>>> sortFieldDtMap = new map<Date, map<string,map<string, list<ReportSumRow>>>>();
			map<Date, map<string, map<string,list<ReportSumRow>>>> sortFieldDtMap2 = new map<Date, map<string,map<string, list<ReportSumRow>>>>();
			// 2017/10/10 WGCH END
			for (Integer i=0; i < termMaxDays; i++) {
				Date keyDate = todayDt.addDays(i);
				// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
				// 获取固定日期格式
				String strKeyDate = getStrKeyDate(keyDate);
				// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
				// 2017/10/10 WGCH BEGIN
				map<string, map<string,list<ReportSumRow>>> sortFieldMap = new map<string,map<string, list<ReportSumRow>>>();
				map<string, map<string,list<ReportSumRow>>> sortFieldMap2 = new map<string,map<string, list<ReportSumRow>>>();
				ReportSumRow moringFoodDetail = new ReportSumRow();
				moringFoodDetail.sortKey = CONST_MON_FOOD_CD;
				moringFoodDetail.middayIcon = '';
				// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
				moringFoodDetail.op = '';
				// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
				//朝食
				moringFoodDetail.productName = Label.CONST_041_0038; 
				ReportSumRow moringFoodDetail2 = new ReportSumRow();
				moringFoodDetail2.sortKey = CONST_MON_FOOD_CD;
				moringFoodDetail2.middayIcon = '';
				// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
				moringFoodDetail2.op = '';
				// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
				//朝食
				moringFoodDetail2.productName = Label.CONST_041_0038; 
				// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
				// 根据日期key=>日期_商品code_单价
				String moringFoodDetailKey = getMoringFoodDetailKey(strKeyDate, moringFoodKey);
				// 集计当天内包含的单价key
				setKeyDateStrMap(keyDate, moringFoodDetailKey);
				moringFoodDetail1Map.put(moringFoodDetailKey, moringFoodDetail.clone());
				moringFoodDetail2Map.put(moringFoodDetailKey, moringFoodDetail2.clone());
				// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
				// 2017/10/10 WGCH END
				Map<Id, List<Lead__c>> leadRoomMap = weekLeadRoomMap.get(keyDate);
				for (Room__c room : roomList) {
					// Filter Append
					//if (!String.isEmpty(area) && (room.ShopInfoRef__r.ShopCode__c != area)) continue;
					if (bRoomViewFlg && !leadRoomMap.containsKey(room.Id)) continue;		// 予約割り当て部屋のみ表示の場合、該当部屋が予約データがないので、非表示する
					// 該当部屋の関連予約データが存在する場合
					if (leadRoomMap.containsKey(room.Id)) {
						// 予約データはVIEW LISTに格納を行う
						for (Lead__c lead : leadRoomMap.get(room.Id)) {
							// 基本情報を格納する
							ReportRow orgRep = new ReportRow(room, lead, idx);
							//orgRep.queryDate = keyDate;
							// 該当予約に関連付く料理の見積もり明細情報を格納する
							List<BookingEstimateItem__c> estItemList = new List<BookingEstimateItem__c>();
							// 未チェックインの場合、該当予約の料理明細情報を格納する
							if (noCheckInIdSet.contains(lead.Id)) {
								// プラン以外の料理の見積もり明細情報は配列に格納する
								estItemList.addAll(lead.BookingEstimateItemFgKu__r);
							} else if (checkInedIdSet.contains(lead.Id)) {
								// 既にチェックインの場合、会計明細の料理情報を格納する
								if (tranCookingMap.containsKey(lead.Id)) estItemList.addAll(tranCookingMap.get(lead.Id));
							}
	
							// 全部明細データはマージする
							// 該当予約に、プランに料理存在するチェックを行う
							if (leadPlanProdMap.containsKey(lead.Id)) {
								// 関連の料理が存在チェック
								Integer subIdx = 0;
								// プラン明細から料理の商品情報を取得する
								for (Id planId : leadPlanProdMap.get(lead.Id)) {
									// 見積もり明細（プラン）のID
									Id planEstItemId = leadEstItemMap.get(lead.Id)[subIdx].Id;
									// 料理を含めのプラン場合[見積もり明細BreakDown設定により]
									if (existBreakDownEstItemMap.containsKey(planEstItemId)) {
										estItemList.addAll(existBreakDownEstItemMap.get(planEstItemId));
										// 注意：INDEX加算必要
										subIdx++;
										continue;
									}
									// 料理を含めのプラン場合[プラン明細設定により]
									if (cookingProdMap.containsKey(planId)) {
										// 該当プランに含めの料理リストを取得する
										List<AccountMaster__c> accMstLst = cookingProdMap.get(planId);
										// 取得する商品情報から、見積り明細明細データを作成する
										for (AccountMaster__c accMst : accMstLst) {
											BookingEstimateItem__c newEstItem = new BookingEstimateItem__c(
												refBooking__c = lead.Id,
												refAccountMaster__c = accMst.Id,
												Field3__c = accMst.Field3__c,
												ProductName__c = accMst.Name,
												OP__c = accMst.OP__c,
												// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
												OP__r = accMst.OP__r,
												// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
												// 2019/08/13 BUG修正 WGCH BEGIN
												refAccountMaster__r = accMst,
												UnitPriceDefKb__c = Commutils.nullToBlank(leadEstItemMap.get(lead.Id)[subIdx].UnitPriceDefKbCal__c),
												// 2019/08/13 BUG修正 WGCH END
												Amount__c = leadEstItemMap.get(lead.Id)[subIdx].Amount__c
											);
											// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
											// 2019/08/13 BUG修正 WGCH BEGIN
											/*
											// estItemList.add(newEstItem);
											// Key=>预约Id_商品Id
											String key = getPlanItemKey(lead.Id, accMst.Id);
											if(leadpEstItemIdMap.containsKey(key)){
												List<BookingEstimateItem__c> pEstItemLst = leadpEstItemIdMap.get(key);
												for(BookingEstimateItem__c pEstItem : pEstItemLst){
													newEstItem.X3_2__c = Commutils.nullToBlank(Commutils.nullToZero(pEstItem.Tankanonetax__c)); // 税拔
													newEstItem.X4_3__c = Commutils.nullToBlank(Commutils.nullToZero(pEstItem.unitPriceIncTaxCal__c)); // 税込
													// 2019/06/28 「サ抜税込」「サ抜税抜」の選択肢対応 WGCH BEGIN
													newEstItem.UnitPriceDefKb__c = Commutils.nullToBlank(pEstItem.UnitPriceDefKbCal__c);
													newEstItem.TaxRate__c = Commutils.nullToZero(pEstItem.TaxRate__c);
													newEstItem.ServiceRate__c = Commutils.nullToZero(pEstItem.ServiceRate__c);
													newEstItem.UnitPrice__c = Commutils.nullToZero(pEstItem.UnitPrice__c);
													newEstItem.SpecialTax__c = Commutils.nullToZero(pEstItem.SpecialTax__c);
													newEstItem.Amount__c = Commutils.nullToZero(pEstItem.Amount__c);
													// 2019/06/28 「サ抜税込」「サ抜税抜」の選択肢対応 WGCH END
													estItemList.add(newEstItem);
												}
											} else estItemList.add(newEstItem);
											*/
											if(planBrkMap.containsKey(planId)){
												for(PlanDetail__c pd : planBrkMap.get(planId)){
													if(pd.AccountMasterRef__c != accMst.Id) continue;
													newEstItem.UnitPrice__c = Commutils.nullToZero(pd.Price__c);
													newEstItem.TaxRate__c = Commutils.nullToZero(pd.TaxRate__c);
													newEstItem.ServiceRate__c = Commutils.nullToZero(pd.ServiceRate__c);
												}
											}
											estItemList.add(newEstItem);
											// 2019/08/13 BUG修正 WGCH END
											// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
										}
									}
									subIdx++;
								}
							}
							// 明細ソートする
							// 2017/05/12 PDFpost等机能对应 BEGIN By Wgch
							// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH BEGIN
							orgRep.addAllDetailData(estItemList,lead);
							// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH END
							// 2017/05/12 PDFpost等机能对应 END By Wgch
							repLst.add(orgRep);
							// 2017/10/10 WGCH BEGIN
							// 2017/10/27 GROUP功能对应 WGCH BEGIN
							// repMap.get(keyDate).add(orgRep);
							setDataAllMap(lead, keyDate, orgRep);
							// 2017/10/17 GROUP功能对应 WGCH END
							// 2017/10/10 WGCH END
							// *******************************
							// 料理情報集計を行う
							// *******************************
							for(BookingEstimateItem__c item : estItemList) {
								// 処理種別は朝食する場合、個別に統計を行う
								ReportDetail tmpDetail = new ReportDetail(item);
								String prodName = tmpDetail.productName;
								String sortKey = getCookFieldSortField(tmpDetail);
								// 2018/07/30 料理集計 WGCH BEGIN
								// 2019/05/15 料理集計「単泊」の料理数は「連泊の１泊目」に合計する機能対応 WGCH BEGIN
								// String orgRepSummaryIcon = foodNightsFlg && orgRep.summaryIcon.contains(K_ScheduleReport.RENPAKU) ? K_ScheduleReport.getFoodNightsHtml(lead, item) : orgRep.summaryIcon;
								String orgRepSummaryIcon = orgRep.summaryIcon;
								if(foodNightsFlg && orgRep.summaryIcon.contains(K_ScheduleReport.RENPAKU)){
									orgRepSummaryIcon = K_ScheduleReport.getFoodNightsHtml(lead, item, false);
								} else if(cookingSummyCode == '1' && foodNightsFlg && oneNightSumFlg) {
									orgRepSummaryIcon = K_ScheduleReport.getFoodNightsHtml(lead, item, true);
								}
								// 2019/05/15 料理集計「単泊」の料理数は「連泊の１泊目」に合計する機能対応 WGCH END
								// 2018/07/30 料理集計 WGCH END
								// チェックキー
								// 2018/07/30 料理集計 WGCH BEGIN
								// String equalKey = prodName + '_' + orgRep.summaryIcon;
								String equalKey = prodName + '_' + orgRepSummaryIcon;
								// 2018/07/30 料理集計 WGCH END
								// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 BEIGN
								//String detailKey = keyDate + '_' + equalKey;
								equalKey = keyDate + '_' + equalKey;
								// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 END
								// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
								equalKey += getUnitPriceKey(tmpDetail.unitPrice); // 连接单价作为key条件
								// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
								// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
								if(item.OP__c != null) opInfoMap.put(item.OP__c, CommUtils.nullToBlank(item.OP__r.Name));
								// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
								// 朝食場合
								if (moringFoodOpIdSet.contains(item.OP__c)) {
									if (orgRep.isCheckIned) {
										// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
										if(!unitpriceColShow){
											// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
											moringFood2.op = CommUtils.nullToBlank(item.OP__c);
											moringFoodDetail2.op = CommUtils.nullToBlank(item.OP__c);
											// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
											moringFood2.productSummy += CommUtils.nullToZero(item.Amount__c);
											// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 BEIGN
											moringFoodDetail2.productSummy += CommUtils.nullToZero(item.Amount__c);
											// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 END
											// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
											moringFood2.unitPrice = CommUtils.nullToBlank(tmpDetail.unitPrice);
											moringFoodDetail2.unitPrice = CommUtils.nullToBlank(tmpDetail.unitPrice);
											// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
										} else {// 显示单价列处理
											// 删掉初期key
											moringFood2Map.remove(moringFoodKey);
											// 删掉初期key
											moringFoodDetail2Map.remove(moringFoodDetailKey);
											// 获取最新的key
											String wkMoringFoodKey = getMoringFoodKey(CONST_MON_FOOD_CD, tmpDetail.unitPrice);
											// 获取多天最新的key
											String wkMoringFoodDetailKey = getMoringFoodDetailKey(strKeyDate, wkMoringFoodKey);
											// 集计当天内包含的单价key
											setKeyDateStrMap(keyDate, wkMoringFoodDetailKey);
											// 料理数据集-防止地址共存
											ReportSumRow wkMoringFood2 = moringFood2.clone();
											// 料理数据集-防止地址共存
											ReportSumRow wkMoringFoodDetail2 = moringFoodDetail2.clone();
											// 数据置换
											if(moringFood2Map.containsKey(wkMoringFoodKey)) wkMoringFood2 = moringFood2Map.get(wkMoringFoodKey);
											if(moringFoodDetail2Map.containsKey(wkMoringFoodDetailKey)) wkMoringFoodDetail2 = moringFoodDetail2Map.get(wkMoringFoodDetailKey);
											wkMoringFood2.sortkey = wkMoringFoodKey;
											wkMoringFoodDetail2.sortkey = wkMoringFoodKey;
											// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
											wkMoringFood2.op = CommUtils.nullToBlank(item.OP__c);
											wkMoringFoodDetail2.op = CommUtils.nullToBlank(item.OP__c);
											// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
											wkMoringFood2.productSummy += CommUtils.nullToZero(item.Amount__c);
											// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 BEIGN
											wkMoringFoodDetail2.productSummy += CommUtils.nullToZero(item.Amount__c);
											// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 END
											// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
											wkMoringFood2.unitPrice = CommUtils.nullToBlank(tmpDetail.unitPrice);
											wkMoringFoodDetail2.unitPrice = CommUtils.nullToBlank(tmpDetail.unitPrice);
											// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
											// 追加新Key料理数据
											if(!moringFood2Map.containsKey(wkMoringFoodKey)) moringFood2Map.put(wkMoringFoodKey, wkMoringFood2);
											if(!moringFoodDetail2Map.containsKey(wkMoringFoodDetailKey)) moringFoodDetail2Map.put(wkMoringFoodDetailKey, wkMoringFoodDetail2);
										}
										// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
									} else {
										// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
										if(!unitpriceColShow){
											// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
											moringFood.op = CommUtils.nullToBlank(item.OP__c);
											moringFoodDetail.op = CommUtils.nullToBlank(item.OP__c);
											// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
											moringFood.productSummy += CommUtils.nullToZero(item.Amount__c);
											// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 BEIGN
											moringFoodDetail.productSummy += CommUtils.nullToZero(item.Amount__c);
											// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 END
											// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
											moringFood.unitPrice = CommUtils.nullToBlank(tmpDetail.unitPrice);
											moringFoodDetail.unitPrice = CommUtils.nullToBlank(tmpDetail.unitPrice);
											// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
										} else {
											// 删掉初期key
											moringFoodMap.remove(moringFoodKey);
											// 删掉初期key
											moringFoodDetail1Map.remove(moringFoodDetailKey);
											// 获取最新的key
											String wkMoringFoodKey = getMoringFoodKey(CONST_MON_FOOD_CD, tmpDetail.unitPrice);
											// 获取多天最新的key
											String wkMoringFoodDetailKey = getMoringFoodDetailKey(strKeyDate, wkMoringFoodKey);
											// 集计当天内包含的单价key
											setKeyDateStrMap(keyDate, wkMoringFoodDetailKey);
											// 料理数据集-防止地址共存
											ReportSumRow wkMoringFood = moringFood.clone();
											// 料理数据集-防止地址共存
											ReportSumRow wkMoringFoodDetail = moringFoodDetail.clone();
											// 数据置换
											if(moringFoodMap.containsKey(wkMoringFoodKey)) wkMoringFood = moringFoodMap.get(wkMoringFoodKey);
											if(moringFoodDetail1Map.containsKey(wkMoringFoodDetailKey)) wkMoringFoodDetail = moringFoodDetail1Map.get(wkMoringFoodDetailKey);
											wkMoringFood.sortkey = wkMoringFoodKey;
											wkMoringFoodDetail.sortkey = wkMoringFoodKey;
											// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
											wkMoringFood.op = CommUtils.nullToBlank(item.OP__c);
											wkMoringFoodDetail.op = CommUtils.nullToBlank(item.OP__c);
											// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
											wkMoringFood.productSummy += CommUtils.nullToZero(item.Amount__c);
											// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 BEIGN
											wkMoringFoodDetail.productSummy += CommUtils.nullToZero(item.Amount__c);
											// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 END
											// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
											wkMoringFood.unitPrice = CommUtils.nullToBlank(tmpDetail.unitPrice);
											wkMoringFoodDetail.unitPrice = CommUtils.nullToBlank(tmpDetail.unitPrice);
											// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
											// 追加新Key料理数据
											if(!moringFoodMap.containsKey(wkMoringFoodKey)) moringFoodMap.put(wkMoringFoodKey, wkMoringFood);
											if(!moringFoodDetail1Map.containsKey(wkMoringFoodDetailKey)) moringFoodDetail1Map.put(wkMoringFoodDetailKey, wkMoringFoodDetail);
										}
										// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
									}
									continue;
								}// 以外の場合、商品コード単位で、集計を行う
								else {
									if (orgRep.isCheckIned) {
										// 既存の商品する場合、
										if (!prodSumMap2.containsKey(equalKey)) {
											ReportSumRow newRepSum = new ReportSumRow();
											// 表示並べ替え利用するため、A_商品名でソートする
											newRepSum.sortKey = CONST_OTHER_CD + sortKey;
											newRepSum.productName = prodName;
											// 2018/07/30 料理集計 WGCH BEGIN
											// newRepSum.middayIcon = orgRep.summaryIcon;
											newRepSum.middayIcon = orgRepSummaryIcon;
											// 2018/07/30 料理集計 WGCH END
											// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
											newRepSum.op = CommUtils.nullToBlank(item.OP__c);
											// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
											// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
											newRepSum.unitPrice = CommUtils.nullToBlank(tmpDetail.unitPrice);
											// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
											prodSumMap2.put(equalKey, newRepSum);
											// key1 ==>> newRepSum.middayIcon
											reportSumRowSort(newRepSum,sortFieldMap2);
										}
										ReportSumRow repSum = prodSumMap2.get(equalKey);
										repSum.productSummy += CommUtils.nullToZero(item.Amount__c);
									} else {
										// 既存の商品する場合、
										if (!prodSumMap.containsKey(equalKey)) {
											ReportSumRow newRepSum = new ReportSumRow();
											// 表示並べ替え利用するため、A_商品名でソートする
											newRepSum.sortKey = CONST_OTHER_CD + sortKey;
											newRepSum.productName = prodName;
											// 2018/07/30 料理集計 WGCH BEGIN
											// newRepSum.middayIcon = orgRep.summaryIcon;
											newRepSum.middayIcon = orgRepSummaryIcon;
											// 2018/07/30 料理集計 WGCH END
											// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
											newRepSum.op = CommUtils.nullToBlank(item.OP__c);
											// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
											// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
											newRepSum.unitPrice = CommUtils.nullToBlank(tmpDetail.unitPrice);
											// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
											prodSumMap.put(equalKey, newRepSum);
											// key1 ==>> newRepSum.middayIcon
											reportSumRowSort(newRepSum,sortFieldMap);
										}
										ReportSumRow repSum = prodSumMap.get(equalKey);
										repSum.productSummy += CommUtils.nullToZero(item.Amount__c);
									}
								}
							}
						}
					} else {
						// 該当部屋に、予約データが非存在する場合
						ReportRow orgRep = new ReportRow(room, new Lead__c(), idx);
						//orgRep.queryDate = keyDate;
						repLst.add(orgRep);
						// 2017/10/10 WGCH BEGIN
						// 2017/10/27 GROUP功能对应 WGCH BEGIN
						// repMap.get(keyDate).add(orgRep);
						setDataAllMap(new Lead__c(), keyDate, orgRep);
						// 2017/10/27 GROUP功能对应 WGCH END
						// 2017/10/10 WGCH END
					}
					idx++;
				}
				// 該当日付に部屋未割り当ての予約リストを取得する
				List<Lead__c> noAssigneLeadLst = weekNoAssigneLeadMap.get(keyDate);
				// 未割り合っての予約データに対して、料理集計を行う
				if (!noAssigneLeadLst.isEmpty()) {
					for (Lead__c lead : noAssigneLeadLst) {
						// 基本情報を格納する
						ReportRow orgRep = new ReportRow(new Room__c(), lead, idx);
						//orgRep.queryDate = keyDate;
						// 支店Filter機能
						//if (!String.isEmpty(area) && (orgRep.branchShopCd != area)) continue;
						// 2015/09/01 多店舗機能対応 BEGIN
						//if (userInf.isShopCodePlex && !userInf.shopSt.contains(orgRep.branchShopCd)) continue;
						// 2015/09/01 多店舗機能対応 END
						// 該当予約に関連付く料理の見積もり明細情報を格納する
						List<BookingEstimateItem__c> estItemList = new List<BookingEstimateItem__c>();
						// 未チェックインの場合、該当予約の料理明細情報を格納する
						if (noCheckInIdSet.contains(lead.Id)) {
							// プラン以外の料理の見積もり明細情報は配列に格納する
							estItemList.addAll(lead.BookingEstimateItemFgKu__r);
						} else if (checkInedIdSet.contains(lead.Id)) {
							// 既にチェックインの場合、会計明細の料理情報を格納する
							if (tranCookingMap.containsKey(lead.Id)) estItemList.addAll(tranCookingMap.get(lead.Id));
						}
							
						// 全部明細データはマージする
						// 該当予約に、プランに料理存在するチェックを行う
						if (leadPlanProdMap.containsKey(lead.Id)) {
	
							// 関連の料理が存在チェック
							Integer subIdx = 0;
							// プラン明細から料理の商品情報を取得する
							for (Id planId : leadPlanProdMap.get(lead.Id)) {
								// 見積もり明細（プラン）のID
								Id planEstItemId = leadEstItemMap.get(lead.Id)[subIdx].Id;
								// 料理を含めのプラン場合[見積もり明細BreakDown設定により]
								if (existBreakDownEstItemMap.containsKey(planEstItemId)) {
									estItemList.addAll(existBreakDownEstItemMap.get(planEstItemId));
									// 注意：INDEX加算必要
									subIdx++;
									continue;
								}
								// 料理を含めのプラン場合[プラン明細設定により]
								if (cookingProdMap.containsKey(planId)) {
									// 該当プランに含めの料理リストを取得する
									List<AccountMaster__c> accMstLst = cookingProdMap.get(planId);
									// 取得する商品情報から、見積り明細明細データを作成する
									for (AccountMaster__c accMst : accMstLst) {
										BookingEstimateItem__c newEstItem = new BookingEstimateItem__c(
											refBooking__c = lead.Id,
											refAccountMaster__c = accMst.Id,
											Field3__c = accMst.Field3__c,
											ProductName__c = accMst.Name,
											OP__c = accMst.OP__c,
											// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
											OP__r = accMst.OP__r,
											// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
											// 2019/08/13 BUG修正 WGCH BEGIN
											refAccountMaster__r = accMst,
											UnitPriceDefKb__c = Commutils.nullToBlank(leadEstItemMap.get(lead.Id)[subIdx].UnitPriceDefKbCal__c),
											// 2019/08/13 BUG修正 WGCH END
											Amount__c = leadEstItemMap.get(lead.Id)[subIdx].Amount__c
										);
										// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
										// 2019/08/13 BUG修正 WGCH BEGIN
										/*
										// estItemList.add(newEstItem);
										String key = lead.Id + '_' + accMst.Id;
										if(leadpEstItemIdMap.containsKey(key)){
											List<BookingEstimateItem__c> pEstItemLst = leadpEstItemIdMap.get(key);
											for(BookingEstimateItem__c pEstItem : pEstItemLst){
												newEstItem.X3_2__c = Commutils.nullToBlank(Commutils.nullToZero(pEstItem.Tankanonetax__c)); // 税拔
												newEstItem.X4_3__c = Commutils.nullToBlank(Commutils.nullToZero(pEstItem.unitPriceIncTaxCal__c)); // 税込
												// 2019/06/28 「サ抜税込」「サ抜税抜」の選択肢対応 WGCH BEGIN
												newEstItem.UnitPriceDefKb__c = Commutils.nullToBlank(pEstItem.UnitPriceDefKbCal__c);
												newEstItem.TaxRate__c = Commutils.nullToZero(pEstItem.TaxRate__c);
												newEstItem.ServiceRate__c = Commutils.nullToZero(pEstItem.ServiceRate__c);
												newEstItem.UnitPrice__c = Commutils.nullToZero(pEstItem.UnitPrice__c);
												newEstItem.SpecialTax__c = Commutils.nullToZero(pEstItem.SpecialTax__c);
												newEstItem.Amount__c = Commutils.nullToZero(pEstItem.Amount__c);
												// 2019/06/28 「サ抜税込」「サ抜税抜」の選択肢対応 WGCH END
												estItemList.add(newEstItem);
											}
										} else estItemList.add(newEstItem);
										*/
										if(planBrkMap.containsKey(planId)){
											for(PlanDetail__c pd : planBrkMap.get(planId)){
												if(pd.AccountMasterRef__c != accMst.Id) continue;
												newEstItem.UnitPrice__c = Commutils.nullToZero(pd.Price__c);
												newEstItem.TaxRate__c = Commutils.nullToZero(pd.TaxRate__c);
												newEstItem.ServiceRate__c = Commutils.nullToZero(pd.ServiceRate__c);
											}
										}
										estItemList.add(newEstItem);
										// 2019/08/13 BUG修正 WGCH END
										// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
									}
								}
								subIdx++;
							}
						}
						// 2017/05/12 PDFpost等机能对应 BEGIN By Wgch
						// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH BEGIN
						orgRep.addAllDetailData(estItemList,lead);
						// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH END
						// 2017/05/12 PDFpost等机能对应 END By Wgch
						repLst.add(orgRep);
						// 2017/10/10 WGCH BEGIN
						// 2017/10/27 GROUP功能对应 WGCH BEGIN
						// repMap.get(keyDate).add(orgRep);
						setDataAllMap(lead, keyDate, orgRep);
						// 2017/10/27 GROUP功能对应 WGCH END
						// 2017/10/10 WGCH END
						// *******************************
						// 料理情報集計を行う
						// *******************************
						for(BookingEstimateItem__c item : estItemList) {
							// 2014/04/01 ADD
							ReportDetail tmpDetail = new ReportDetail(item);
							// 処理種別は朝食する場合、個別に統計を行う
							String prodName = tmpDetail.productName;
							String sortKey = getCookFieldSortField(tmpDetail);
							// 2018/07/30 料理集計 WGCH BEGIN
							// 2019/05/15 料理集計「単泊」の料理数は「連泊の１泊目」に合計する機能対応 WGCH BEGIN
							// String orgRepSummaryIcon = foodNightsFlg && orgRep.summaryIcon.contains(K_ScheduleReport.RENPAKU) ? K_ScheduleReport.getFoodNightsHtml(lead, item) : orgRep.summaryIcon;
							String orgRepSummaryIcon = orgRep.summaryIcon;
							if(foodNightsFlg && orgRep.summaryIcon.contains(K_ScheduleReport.RENPAKU)){
								orgRepSummaryIcon = K_ScheduleReport.getFoodNightsHtml(lead, item, false);
							} else if(cookingSummyCode == '1' && foodNightsFlg && oneNightSumFlg){
								orgRepSummaryIcon = K_ScheduleReport.getFoodNightsHtml(lead, item, true);
							}
							// 2019/05/15 料理集計「単泊」の料理数は「連泊の１泊目」に合計する機能対応 WGCH END
							// 2018/07/30 料理集計 WGCH END
							// チェックキー
							// 2018/07/30 料理集計 WGCH BEGIN
							// String equalKey = prodName + '_' + orgRep.summaryIcon;
							String equalKey = prodName + '_' + orgRepSummaryIcon;
							// 2018/07/30 料理集計 WGCH END
							// 2017/10/10 WGCH BEGIN
							//String detailKey = keyDate + '_' + equalKey;
							equalKey = keyDate + '_' + equalKey;
							// 2017/10/10 WGCH END
							// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
							equalKey += getUnitPriceKey(tmpDetail.unitPrice); // 连接单价作为key条件
							// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
							// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
							if(item.OP__c != null) opInfoMap.put(item.OP__c, CommUtils.nullToBlank(item.OP__r.Name));
							// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
							// 朝食場合
							if (moringFoodOpIdSet.contains(item.OP__c)) {
								if (orgRep.isCheckIned) {
									// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGI
									if(!unitpriceColShow){
										// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
										moringFood2.op = CommUtils.nullToBlank(item.OP__c);
										moringFoodDetail2.op = CommUtils.nullToBlank(item.OP__c);
										// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
										moringFood2.productSummy += CommUtils.nullToZero(item.Amount__c);
										// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 BEIGN
										moringFoodDetail2.productSummy += CommUtils.nullToZero(item.Amount__c);
										// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 END
										// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
										moringFood2.unitPrice = CommUtils.nullToBlank(tmpDetail.unitPrice);
										moringFoodDetail2.unitPrice = CommUtils.nullToBlank(tmpDetail.unitPrice);
										// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
									} else { // 显示单价列处理
										// 删掉初期key
										moringFood2Map.remove(moringFoodKey);
										// 删掉初期key
										moringFoodDetail2Map.remove(moringFoodDetailKey);
										// 获取最新的key
										String wkMoringFoodKey = getMoringFoodKey(CONST_MON_FOOD_CD, tmpDetail.unitPrice);
										// 获取多天最新的key
										String wkMoringFoodDetailKey = getMoringFoodDetailKey(strKeyDate, wkMoringFoodKey);
										// 集计当天内包含的单价key 
										setKeyDateStrMap(keyDate, wkMoringFoodDetailKey);
										// 料理数据集-防止地址共存 
										ReportSumRow wkMoringFood2 = moringFood2.clone();
										// 料理数据集-防止地址共存 
										ReportSumRow wkMoringFoodDetail2 = moringFoodDetail2.clone();
										// 数据置换
										if(moringFood2Map.containsKey(wkMoringFoodKey)) wkMoringFood2 = moringFood2Map.get(wkMoringFoodKey);
										if(moringFoodDetail2Map.containsKey(wkMoringFoodDetailKey)) wkMoringFoodDetail2 = moringFoodDetail2Map.get(wkMoringFoodDetailKey);
										wkMoringFood2.sortKey = wkMoringFoodKey;
										wkMoringFoodDetail2.sortKey = wkMoringFoodKey;
										// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
										wkMoringFood2.op = CommUtils.nullToBlank(item.OP__c);
										wkMoringFoodDetail2.op = CommUtils.nullToBlank(item.OP__c);
										// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
										wkMoringFood2.productSummy += CommUtils.nullToZero(item.Amount__c);
										// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 BEIGN
										wkMoringFoodDetail2.productSummy += CommUtils.nullToZero(item.Amount__c);
										// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 END
										// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
										wkMoringFood2.unitPrice = CommUtils.nullToBlank(tmpDetail.unitPrice);
										wkMoringFoodDetail2.unitPrice = CommUtils.nullToBlank(tmpDetail.unitPrice);
										// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
										// 追加新Key料理数据
										if(!moringFood2Map.containsKey(wkMoringFoodKey)) moringFood2Map.put(wkMoringFoodKey, wkMoringFood2);
										if(!moringFoodDetail2Map.containsKey(wkMoringFoodDetailKey)) moringFoodDetail2Map.put(wkMoringFoodDetailKey, wkMoringFoodDetail2);
									}
									// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
								} else {
									// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
									if(!unitpriceColShow){
										// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
										moringFood.op = CommUtils.nullToBlank(item.OP__c);
										moringFoodDetail.op = CommUtils.nullToBlank(item.OP__c);
										// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
										moringFood.productSummy += CommUtils.nullToZero(item.Amount__c);
										// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 BEIGN
										moringFoodDetail.productSummy += CommUtils.nullToZero(item.Amount__c);
										// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 BEIGN
										// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
										moringFood.unitPrice = CommUtils.nullToBlank(tmpDetail.unitPrice);
										moringFoodDetail.unitPrice = CommUtils.nullToBlank(tmpDetail.unitPrice);
										// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
									} else {
										// 删掉初期key
										moringFoodMap.remove(moringFoodKey);
										// 删掉初期key
										moringFoodDetail1Map.remove(moringFoodDetailKey);
										// 删掉初期key
										String wkMoringFoodKey = getMoringFoodKey(CONST_MON_FOOD_CD, tmpDetail.unitPrice);
										// 删掉初期key
										String wkMoringFoodDetailKey = getMoringFoodDetailKey(strKeyDate, wkMoringFoodKey);
										// 集计当天内包含的单价key
										setKeyDateStrMap(keyDate, wkMoringFoodDetailKey);
										// 料理数据集-防止地址共存
										ReportSumRow wkMoringFood = moringFood.clone();
										// 料理数据集-防止地址共存
										ReportSumRow wkMoringFoodDetail = moringFoodDetail.clone();
										// 数据置换
										if(moringFoodMap.containsKey(wkMoringFoodKey)) wkMoringFood = moringFoodMap.get(wkMoringFoodKey);
										if(moringFoodDetail1Map.containsKey(wkMoringFoodDetailKey)) wkMoringFoodDetail = moringFoodDetail1Map.get(wkMoringFoodDetailKey);
										wkMoringFood.sortkey = wkMoringFoodKey;
										wkMoringFoodDetail.sortkey = wkMoringFoodKey;
										// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
										wkMoringFood.op = CommUtils.nullToBlank(item.OP__c);
										wkMoringFoodDetail.op = CommUtils.nullToBlank(item.OP__c);
										// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
										wkMoringFood.productSummy += CommUtils.nullToZero(item.Amount__c);
										// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 BEIGN
										wkMoringFoodDetail.productSummy += CommUtils.nullToZero(item.Amount__c);
										// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 BEIGN
										// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
										wkMoringFood.unitPrice = CommUtils.nullToBlank(tmpDetail.unitPrice);
										wkMoringFoodDetail.unitPrice = CommUtils.nullToBlank(tmpDetail.unitPrice);
										// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
										// 追加新Key料理数据
										if(!moringFoodMap.containsKey(wkMoringFoodKey)) moringFoodMap.put(wkMoringFoodKey, wkMoringFood);
										if(!moringFoodDetail1Map.containsKey(wkMoringFoodDetailKey)) moringFoodDetail1Map.put(wkMoringFoodDetailKey, wkMoringFoodDetail);
									}
									// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
								}
								continue;
							}// 以外の場合、商品コード単位で、集計を行う
							else {
								if (orgRep.isCheckIned) {
									// 既存の商品する場合、
									if (!prodSumMap2.containsKey(equalKey)) {
										ReportSumRow newRepSum = new ReportSumRow();
										// 表示並べ替え利用するため、A_商品名でソートする
										newRepSum.sortKey = CONST_OTHER_CD + sortKey;
										newRepSum.productName = prodName;
										// 2018/07/30 料理集計 WGCH BEGIN
										// newRepSum.middayIcon = orgRep.summaryIcon;
										newRepSum.middayIcon = orgRepSummaryIcon;
										// 2018/07/30 料理集計 WGCH END
										// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
										newRepSum.op = CommUtils.nullToBlank(item.OP__c);
										// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
										// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
										newRepSum.unitPrice = CommUtils.nullToBlank(tmpDetail.unitPrice);
										// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
										prodSumMap2.put(equalKey, newRepSum);
										reportSumRowSort(newRepSum,sortFieldMap2);
									}
									ReportSumRow repSum = prodSumMap2.get(equalKey);
									repSum.productSummy += CommUtils.nullToZero(item.Amount__c);
								} else {
									// 既存の商品する場合、
									if (!prodSumMap.containsKey(equalKey)) {
										ReportSumRow newRepSum = new ReportSumRow();
										// 表示並べ替え利用するため、A_商品名でソートする
										newRepSum.sortKey = CONST_OTHER_CD + sortKey;
										newRepSum.productName = prodName;
										// 2018/07/30 料理集計 WGCH BEGIN
										// newRepSum.middayIcon = orgRep.summaryIcon;
										newRepSum.middayIcon = orgRepSummaryIcon;
										// 2018/07/30 料理集計 WGCH END
										// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
										newRepSum.op = CommUtils.nullToBlank(item.OP__c);
										// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
										// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
										newRepSum.unitPrice = CommUtils.nullToBlank(tmpDetail.unitPrice);
										// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
										prodSumMap.put(equalKey, newRepSum);
										reportSumRowSort(newRepSum,sortFieldMap);
									}
									ReportSumRow repSum = prodSumMap.get(equalKey);
									repSum.productSummy += CommUtils.nullToZero(item.Amount__c);
								}
							}
						}
						idx++;
					}
				}
				// 2017/10/10 WGCH BEGIN
				// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
				// 不显示用原来的处理
				if(!unitpriceColShow){
					/*
					moringFoodDetail1Map.put(keyDate, moringFoodDetail);
					moringFoodDetail2Map.put(keyDate, moringFoodDetail2);
					*/
					moringFoodDetail1Map.put(moringFoodDetailKey, moringFoodDetail);
					moringFoodDetail2Map.put(moringFoodDetailKey, moringFoodDetail2);
				}
				// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
				sortFieldDtMap.put(keyDate, sortFieldMap);
				sortFieldDtMap2.put(keyDate, sortFieldMap2);
				// 2017/10/10 WGCH END
			}
			// 朝食追加する
			if (!moringFoodOpIdSet.isEmpty()) {
				// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
				// 不显示用原来的处理
				if(!unitpriceColShow){
					prodSumMap2.put(CONST_MON_FOOD_CD, moringFood2);
					prodSumMap.put(CONST_MON_FOOD_CD, moringFood);
				} else {
					prodSumMap2.putAll(moringFood2Map);
					prodSumMap.putAll(moringFoodMap);
				}
				// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
				// 2017/10/10 WGCH BEGIN
				// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
				/*
				for(Date keyDate : keyDateLst){
					reportSumRowSort(moringFoodDetail1Map.get(keyDate),sortFieldDtMap.get(keyDate));
					reportSumRowSort(moringFoodDetail2Map.get(keyDate),sortFieldDtMap2.get(keyDate));
				}
				*/
				for(Date keyDate : keyDateLst){
					if(keyDateStrMap.containsKey(keyDate)){
						// 获取当天的单价key
						List<String> moringFoodDetailKeyLst = keyDateStrMap.get(keyDate);
						for(String moringFoodDetailKey : moringFoodDetailKeyLst){
							reportSumRowSort(moringFoodDetail1Map.get(moringFoodDetailKey),sortFieldDtMap.get(keyDate));
							reportSumRowSort(moringFoodDetail2Map.get(moringFoodDetailKey),sortFieldDtMap2.get(keyDate));
						}
					}
				}
				// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
				// 2017/10/10 WGCH END
			}
			// 全て編集可能項目リスト情報を取得する
			Map<String, Schema.DescribeFieldResult> modelDeafaultValuesMaps = CommSqlUtils.getAllFieldLst(Lead__c.sObjectType,false);
			// 1000*1000
			// 2017/10/10 WGCH BEGIN
			// 2017/10/27 GROUP功能对应 WGCH BEGIN
			// dataAllMap = new Map<Date, List<List<ReportRow>>>();
			for(Date keyDt : keyDateLst){
				// dataAll = new List<List<ReportRow>>();
				// List<ReportRow> repList = repMap.get(keyDt);
				LeadInfo ldInfo = dataAllMap.get(keyDt);
				ldInfo.titleKeyLst.sort();
				for (String titleKey :ldInfo.titleKeyLst) {
					List<ReportRow> wRepLst = ldInfo.titleItmMap.get(titleKey);
					for (Integer i = 0; i < wRepLst.size(); i++) {
						/*
						if (Math.mod(m, 1000) == 0) {
							List<ReportRow> oneSetPage = new List<ReportRow>();
							dataAll.add(oneSetPage);
						}
						dataAll[dataAll.size()-1].add(repList[i]);
						*/
						// 2017/05/12 PDFpost等机能对应 BEGIN By Wgch
						for (String fieldApi : leadApiLabelMap.keySet()) {
						// 2017/05/12 PDFpost等机能对应 END By Wgch
							// 表示ラベルを定義する
							//if(!customTypemap.containsKey(fieldApi)) customTypemap.put(fieldApi,'String');
							// 合计值字段 计算处理
							if (customAggregateFields.contains(fieldApi) && modelDeafaultValuesMaps.containsKey(fieldApi)) {
								Schema.DescribeFieldResult dr = modelDeafaultValuesMaps.get(fieldApi);
								DisplayType fieldType = dr.getType();
								if(fieldType == DisplayType.Integer ||
								fieldType == DisplayType.Double ||
								fieldType == DisplayType.Percent ||
								fieldType == DisplayType.Currency ){
									// 合計処理
									Decimal sumVal = CommUtils.nullToZero(avgSumMap.get(fieldApi)) + CommUtils.nullToZero(wRepLst[i].varlead.get(fieldApi));
									avgSumMap.put(fieldApi, sumVal);
								}
							}
						}
					}
				}
				//dataAllMap.put(keyDt, dataAll);
			}
			// 2017/10/27 GROUP功能对应 WGCH END
			// 2017/10/10 WGCH END
			// 2017/05/12 PDFpost等机能对应 BEGIN By Wgch
			// 料理集計情報を格納する
			Map<String,Object> oldSumaryData;
			// 第一个料理的oldData
			if(!CommUtils.isBlank(oldSumaryJson)) {
				// JSON -> OBJECT
				oldSumaryData = foodColorJsonToMap(oldSumaryJson);
				// 料理集計セクション変動チェック処理を行う
				chkChangeForFoodSum(prodSumMap,oldSumaryData);
			}
			// 第二个料理的oldData
			if(!CommUtils.isBlank(oldSumary2Json)) {
				// JSON -> OBJECT
				oldSumaryData = foodColorJsonToMap(oldSumary2Json);
				chkChangeForFoodSum(prodSumMap2,oldSumaryData);
			}
			// batch执行过，数据库已经纪录了该店铺batch执行的时间
			//if (preBatchExcTime != null) {
			perSumaryJsonLst = jsonCut(JSON.serialize(perSumaryMap));
			prodSumJsonLst = jsonCut(JSON.serialize(prodSumMap));
			prodSumJson2Lst = jsonCut(JSON.serialize(prodSumMap2));
				/*
				// 第一次进来的时候
				if(isFirstLoadFlg){
					// 店舗情報格納する
					Map<String, ShopInformation__c> shopInfoMap = ShopInfoUtil.getShopInfoMap();
					Id spId = shopInfoMap.containsKey(shopCode) ? shopInfoMap.get(shopCode).Id : null;
					ReservationListWork__c res1 = insertReservation(LEADFOODSUM,perSumaryJsonLst,spId,batchLastTm,todayDt);
					ReservationListWork__c res2 = insertReservation(REPORTFOODSUM,prodSumJsonLst,spId,batchLastTm,todayDt);
					ReservationListWork__c res3 = insertReservation(ACCOUNTFOODSUM,prodSumJson2Lst,spId,batchLastTm,todayDt);
					List<ReservationListWork__c> reservationLst = new List<ReservationListWork__c>{res1,res2,res3};
					insert reservationLst;
				} else if(isBatchStartFlg) {
					//对有变化的数据就行更新旧数据
					for(ReservationListWork__c res : reservationFoodSum){
						res.BatchLastTm__c = batchLastDt;
						if(res.FoodSumType__c == LEADFOODSUM){
							res.FoodSumData__c = perSumaryJsonLst[0];
							res.FoodSumData2__c = perSumaryJsonLst[1];
							res.FoodSumData3__c = perSumaryJsonLst[2];
						} else if(res.FoodSumType__c == REPORTFOODSUM){
							res.FoodSumData__c = prodSumJsonLst[0];
							res.FoodSumData2__c = prodSumJsonLst[1];
							res.FoodSumData3__c = prodSumJsonLst[2];
						} else if(res.FoodSumType__c == ACCOUNTFOODSUM){
							res.FoodSumData__c = prodSumJson2Lst[0];
							res.FoodSumData2__c = prodSumJson2Lst[1];
							res.FoodSumData3__c = prodSumJson2Lst[2];
						}
					}
					if(!reservationFoodSum.isEmpty()) update reservationFoodSum;
				}*/
			//}
			// 2017/05/12 PDFpost等机能对应 END By Wgch
			// 2017/10/10 WGCH BEGIN
			//foodSumRowLstAll = new List<List<ReportSumRow>>();
			// 料理集計並び順
			foodSumRowLstAll = new List<foodSumInfo>();
			foodSumInfo foodSumRow1 = new foodSumInfo();
			for(Date keyDate : keyDateLst){
				List<ReportSumRow> wFoodSumRow = reportSumRowSort(sortFieldDtMap.get(keyDate));
				// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
				Map<String, List<ReportSumRow>> wFoodSumRowMap = new Map<String, List<ReportSumRow>>();
				// 2018/07/05 初始化修正 WGCH BEGIN
				// 2018/10/15 料理集計に合計の表記がございますが機能対応 WGCH BEGIN
				// if(!foodSumRow1.opIdMap.containsKey(keyDate)) foodSumRow1.opIdMap.put(keyDate, new List<String>());
				if(!foodSumRow1.opIdMap.containsKey(keyDate)){
					foodSumRow1.opIdMap.put(keyDate, new List<String>());
					foodSumRow1.groupFooterDetailMap.put(keyDate, new List<ReportSumRow>());
					if(termDates > 1 && foodSumIsShowFlg && foodSumIsShowProdFlg) setGroupFooterDetailMap(keyDate, foodSumRow1, wFoodSumRow.clone());
				}
				// 2018/10/15 料理集計に合計の表記がございますが機能対応 WGCH END
				// 2018/07/05 初始化修正 WGCH END
				for(ReportSumRow rep : wFoodSumRow){
					String opKey = rep.op == '' ? BLANK : rep.op;
					if(!wFoodSumRowMap.containsKey(opKey)){
						// 2018/07/05 初始化修正 WGCH BEGIN
						// if(!foodSumRow1.opIdMap.containsKey(keyDate)) foodSumRow1.opIdMap.put(keyDate, new List<String>());
						// 2018/07/05 初始化修正 WGCH END
						foodSumRow1.opIdMap.get(keyDate).add(opKey);
						wFoodSumRowMap.put(opKey, new List<ReportSumRow>());
					}
					wFoodSumRowMap.get(opKey).add(rep);
				}
				// foodSumRow1.foodSumRowMapAll.put(keyDate, wFoodSumRow);
				foodSumRow1.foodSumRowMapAll.put(keyDate, wFoodSumRowMap);
				// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
				if(!wFoodSumRow.isEmpty() && !foodSumRow1.foodSumRowflg) foodSumRow1.foodSumRowflg = true;
			}
			// 2018/10/15 料理集計に合計の表記がございますが機能対応 WGCH BEGIN
			if(foodSumIsShowFlg && foodSumIsShowProdFlg) setFooterDetail(foodSumRow1, sortFieldDtMap);
			// 2018/10/15 料理集計に合計の表記がございますが機能対応 WGCH END
			foodSumRowLstAll.add(foodSumRow1);
			if (cookInfoSplitShow){
				foodSumInfo foodSumRow2 = new foodSumInfo();
				for(Date keyDate : keyDateLst){
					List<ReportSumRow> wFoodSumRow = reportSumRowSort(sortFieldDtMap2.get(keyDate));
					// 2019/02/28 Page->Map->Key修正对应 WGCH BEGIN
					if(!foodSumRow2.opIdMap.containsKey(keyDate)){
						foodSumRow2.opIdMap.put(keyDate, new List<String>());
						foodSumRow2.groupFooterDetailMap.put(keyDate, new List<ReportSumRow>());
						if(termDates > 1 && foodSumIsShowFlg && foodSumIsShowProdFlg) setGroupFooterDetailMap(keyDate, foodSumRow2, wFoodSumRow.clone());
					}
					// 2019/02/28 Page->Map->Key修正对应 WGCH END
					// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
					Map<String, List<ReportSumRow>> wFoodSumRowMap = new Map<String, List<ReportSumRow>>();
					for(ReportSumRow rep : wFoodSumRow){
						String opKey = rep.op == '' ? BLANK : rep.op;
						if(!wFoodSumRowMap.containsKey(opKey)){
							// 2018/10/15 料理集計に合計の表記がございますが機能対応 WGCH BEGIN
							// if(!foodSumRow2.opIdMap.containsKey(keyDate)) foodSumRow2.opIdMap.put(keyDate, new List<String>());
							// 2019/02/28 Page->Map->Key修正对应 WGCH BEGIN
							/*
							if(!foodSumRow2.opIdMap.containsKey(keyDate)){
								foodSumRow2.opIdMap.put(keyDate, new List<String>());
								foodSumRow2.groupFooterDetailMap.put(keyDate, new List<ReportSumRow>());
								if(termDates > 1 && foodSumIsShowFlg && foodSumIsShowProdFlg) setGroupFooterDetailMap(keyDate, foodSumRow2, wFoodSumRow.clone());
							}
							*/
							// 2019/02/28 Page->Map->Key修正对应 WGCH END
							// 2018/10/15 料理集計に合計の表記がございますが機能対応 WGCH END
							foodSumRow2.opIdMap.get(keyDate).add(opKey);
							wFoodSumRowMap.put(opKey, new List<ReportSumRow>());
						}
						wFoodSumRowMap.get(opKey).add(rep);
					}
					// foodSumRow2.foodSumRowMapAll.put(keyDate, wFoodSumRow);
					foodSumRow2.foodSumRowMapAll.put(keyDate, wFoodSumRowMap);
					// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
					if(!wFoodSumRow.isEmpty() && !foodSumRow2.foodSumRowflg) foodSumRow2.foodSumRowflg = true;
				}
				// 2018/10/15 料理集計に合計の表記がございますが機能対応 WGCH BEGIN
				if(foodSumIsShowFlg && foodSumIsShowProdFlg) setFooterDetail(foodSumRow2, sortFieldDtMap2);
				// 2018/10/15 料理集計に合計の表記がございますが機能対応 WGCH END
				foodSumRowLstAll.add(foodSumRow2);
			}
			//reportSumRowSort(sortFieldMap);
			// 料理集計並び順2
			// 2017/04/30 料理集計方式により、出力内容変更 BEGIN
			//reportSumRowSort(sortFieldMap2);
			//if (cookInfoSplitShow) reportSumRowSort(sortFieldMap2);
			// 2017/10/10 WGCH END
			// 2017/04/30 料理集計方式により、出力内容変更 END
			// 2020/02/28 同伴者情報列位置自定义改善对应 WGCH BEGIN
			// 2019/04/15 料理自定义列所在位置功能对应 WGCH BEGIN
			// isShowFoodPosition = isShowFoodPosition <= leadApiLst.size() ? isShowFoodPosition : leadApiLst.size();
			// 2019/04/15 料理自定义列所在位置功能对应 WGCH END
			Integer leadApiLstSize = leadApiLst.size();
			if(leadApiLstSize > 0){
				Boolean isAddFoodFlg = true;
				Boolean isAddGuestFlg = true;
				LeadApi lastLdApi = leadApiLst[leadApiLstSize-1];
				//「料理列」最后一列设定
				if(isShowGuestPositionFlg && isShowGuestInfo) isShowFoodPositionOld--;
				if(isShowFoodPositionOld > leadApiLstSize){
					//「料理列」显示、有效追加、当前有效追加列
					if(isShowFoodInfo && isAddFoodFlg){
						lastLdApi.afLst.add(CONST_COL_FOOD);
						isAddFoodFlg = false;
					}
					//「同伴者情報列」显示、有效追加、当前有效追加列
					if(!isShowGuestPositionFlg && isShowGuestInfo && isAddGuestFlg){
						lastLdApi.afLst.add(CONST_COL_GUEST);
						isAddGuestFlg = false;
					}
				}
				//「同伴者情報列」最后一列设定
				if(isShowGuestPositionFlg && isShowGuestPositionOld > leadApiLstSize){
					//「同伴者情報列」显示、有效追加、当前有效追加列
					if(isShowGuestInfo && isAddGuestFlg){
						lastLdApi.afLst.add(CONST_COL_GUEST);
						isAddGuestFlg = false;
					}
				}
				//「料理列」在「同伴者情報列」前Mode
				if(isShowFoodPosition <= isShowGuestPosition){
					//「料理列」隐藏Mode
					if(!isShowFoodInfo) isShowGuestPosition--;
				//「同伴者情報列」在「料理列前Mode
				} else if(isShowGuestPosition <= isShowFoodPosition) {
					//「同伴者情報列」隐藏Mode
					if(!isShowGuestInfo) isShowFoodPosition--;
				}
				Integer colIdx = 0;
				for(LeadApi ldApi : leadApiLst){
					Integer gColIdx = colIdx;
					//「料理列」显示、有效追加、当前有效追加列
					if(isShowFoodInfo && isAddFoodFlg && (gColIdx == isShowFoodPosition)){
						ldApi.bfLst.add(CONST_COL_FOOD);
						isAddFoodFlg = false;
						colIdx++;
					}
					//「同伴者情報列」显示、有效追加、当前有效追加列
					if(isShowGuestInfo && isAddGuestFlg && (gColIdx == isShowGuestPosition)){
						ldApi.bfLst.add(CONST_COL_GUEST);
						isAddGuestFlg = false;
						colIdx++;
					}
					// 连接1、2Case
					//「料理列」显示、有效追加、当前有效追加列
					if(isShowFoodInfo && isAddFoodFlg && (colIdx == isShowFoodPosition)){
						ldApi.bfLst.add(CONST_COL_FOOD);
						isAddFoodFlg = false;
						colIdx++;
					}
					//「同伴者情報列」显示、有效追加、当前有效追加列
					if(isShowGuestInfo && isAddGuestFlg && (colIdx == isShowGuestPosition)){
						ldApi.bfLst.add(CONST_COL_GUEST);
						isAddGuestFlg = false;
						colIdx++;
					}
					colIdx++;
					// 间隔1、3Case
					//「料理列」显示、有效追加、当前有效追加列
					if(isShowFoodInfo && isAddFoodFlg && (colIdx == isShowFoodPosition)){
						ldApi.afLst.add(CONST_COL_FOOD);
						isAddFoodFlg = false;
						colIdx++;
					}
					//「同伴者情報列」显示、有效追加、当前有效追加列
					if(isShowGuestInfo && isAddGuestFlg && (colIdx == isShowGuestPosition)){
						ldApi.afLst.add(CONST_COL_GUEST);
						isAddGuestFlg = false;
						colIdx++;
					}
				}
			}
			// 2020/02/28 同伴者情報列位置自定义改善对应 WGCH END
			// 2019/05/15 予定表指定日にて、連絡事項を表示する機能対応 WGCH BEGIN
			// 指定日期格式yyyyMMdd
			Date currDate = CommUtils.isBlank(pQueryDt) ? Date.today() : CommUtils.stringToDate(pQueryDt);
			DateTime currDt = DateTime.newInstance(currDate, Time.newInstance(0,0,0,0));
			// 获取連絡事項数据
			MessageItem__c message = (new MessageItemCtrl()).queryLastInfo(currDt.format('yyyyMMdd'), shopCode, messageMaxRows);
			messageItemInfoLst = new List<MessageItemInfo>();
			if(message != null){
				if(!CommUtils.isBlank(message.MessageRich__c) && messageIsRichTextFlg) messageItemInfoLst.add(new MessageItemInfo(message, message.MessageRich__c));
				else {
					if(!CommUtils.isBlank(message.Message1__c)) messageItemInfoLst.add(new MessageItemInfo(message, message.Message1__c));
					if(!CommUtils.isBlank(message.Message2__c)) messageItemInfoLst.add(new MessageItemInfo(message, message.Message2__c));
					if(!CommUtils.isBlank(message.Message3__c)) messageItemInfoLst.add(new MessageItemInfo(message, message.Message3__c));
					if(!CommUtils.isBlank(message.Message4__c)) messageItemInfoLst.add(new MessageItemInfo(message, message.Message4__c));
					if(!CommUtils.isBlank(message.Message5__c)) messageItemInfoLst.add(new MessageItemInfo(message, message.Message5__c));
					if(!CommUtils.isBlank(message.Message6__c)) messageItemInfoLst.add(new MessageItemInfo(message, message.Message6__c));
					if(!CommUtils.isBlank(message.Message7__c)) messageItemInfoLst.add(new MessageItemInfo(message, message.Message7__c));
					if(!CommUtils.isBlank(message.Message8__c)) messageItemInfoLst.add(new MessageItemInfo(message, message.Message8__c));
					if(!CommUtils.isBlank(message.Message9__c)) messageItemInfoLst.add(new MessageItemInfo(message, message.Message9__c));
					if(!CommUtils.isBlank(message.Message10__c)) messageItemInfoLst.add(new MessageItemInfo(message, message.Message10__c));
					if(!CommUtils.isBlank(message.Message11__c)) messageItemInfoLst.add(new MessageItemInfo(message, message.Message11__c));
					if(!CommUtils.isBlank(message.Message12__c)) messageItemInfoLst.add(new MessageItemInfo(message, message.Message12__c));
					if(!CommUtils.isBlank(message.Message13__c)) messageItemInfoLst.add(new MessageItemInfo(message, message.Message13__c));
					if(!CommUtils.isBlank(message.Message14__c)) messageItemInfoLst.add(new MessageItemInfo(message, message.Message14__c));
					if(!CommUtils.isBlank(message.Message15__c)) messageItemInfoLst.add(new MessageItemInfo(message, message.Message15__c));
					if(!CommUtils.isBlank(message.Message16__c)) messageItemInfoLst.add(new MessageItemInfo(message, message.Message16__c));
					if(!CommUtils.isBlank(message.Message17__c)) messageItemInfoLst.add(new MessageItemInfo(message, message.Message17__c));
					if(!CommUtils.isBlank(message.Message18__c)) messageItemInfoLst.add(new MessageItemInfo(message, message.Message18__c));
					if(!CommUtils.isBlank(message.Message19__c)) messageItemInfoLst.add(new MessageItemInfo(message, message.Message19__c));
					if(!CommUtils.isBlank(message.Message20__c)) messageItemInfoLst.add(new MessageItemInfo(message, message.Message20__c));
					if(!CommUtils.isBlank(message.Message21__c)) messageItemInfoLst.add(new MessageItemInfo(message, message.Message21__c));
					if(!CommUtils.isBlank(message.Message22__c)) messageItemInfoLst.add(new MessageItemInfo(message, message.Message22__c));
					if(!CommUtils.isBlank(message.Message23__c)) messageItemInfoLst.add(new MessageItemInfo(message, message.Message23__c));
					if(!CommUtils.isBlank(message.Message24__c)) messageItemInfoLst.add(new MessageItemInfo(message, message.Message24__c));
				}
			}
			// 2019/05/15 予定表指定日にて、連絡事項を表示する機能対応 WGCH END
		} catch(Exception e){
			System.debug(LoggingLevel.INFO, 'Error:' + e.getMessage());
			throw e;
		}
	}
	// 2019/05/15 予定表指定日にて、連絡事項を表示する機能対応 WGCH BEGIN
	public Boolean messageIsRichTextFlg{get{ return CommDefine__c.getOrgDefaults().ReportKScheduleMessageIsRichTextFlg__c == null ? false : CommDefine__c.getOrgDefaults().ReportKScheduleMessageIsRichTextFlg__c;} set;}
	public Decimal messageMaxRows = CommDefine__c.getOrgDefaults().MessageRows__c == null ? 0 : CommDefine__c.getOrgDefaults().MessageRows__c;
	public List<MessageItemInfo> messageItemInfoLst{get;set;}
	public class MessageItemInfo{
		public MessageItemInfo(MessageItem__c sobj, String messageText){
			this.sobj = sobj;
			this.messageText = '<li>' + messageText + '</li>';
		}
		public MessageItem__c sobj{get;set;}
		public String messageText{get;set;}
	}
	// 2019/05/15 予定表指定日にて、連絡事項を表示する機能対応 WGCH END
	// 2017/10/10 WGCH BEGIN
	public class foodSumInfo{
		public foodSumInfo(){
			// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
			opIdMap = new Map<Date, List<String>>();
			// foodSumRowMapAll = new Map<Date, List<ReportSumRow>>();
			foodSumRowMapAll = new Map<Date, Map<String ,List<ReportSumRow>>>();
			// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
			foodSumRowflg = false;
			// 2018/10/15 料理集計に合計の表記がございますが機能対応 WGCH BEGIN
			reportSumRowLst = new List<ReportSumRow>();
			groupFooterDetailMap = new Map<Date, List<ReportSumRow>>();
			// 2018/10/15 料理集計に合計の表記がございますが機能対応 WGCH END
		}
		// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
		public Map<Date, List<String>> opIdMap{get;set;}
		// public Map<Date, List<ReportSumRow>> foodSumRowMapAll{get;set;}
		public Map<Date, Map<String ,List<ReportSumRow>>> foodSumRowMapAll{get;set;}
		// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
		// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
		public Boolean foodSumRowflg{get;set;}
		// 2018/10/15 料理集計に合計の表記がございますが機能対応 WGCH BEGIN
		public List<ReportSumRow> reportSumRowLst{get;set;}
		public Map<Date, List<ReportSumRow>> groupFooterDetailMap{get;set;}
		// 2018/10/15 料理集計に合計の表記がございますが機能対応 WGCH END
	}
	// 2017/10/10 WGCH END
	// 抽出した比較用情報
	private List<String> perSumaryJsonLst;
	private List<String> prodSumJsonLst;
	private List<String> prodSumJson2Lst;
	private List<ReservationListWork__c> reservationFoodSum;
	public void saveSummaryToWorkDb(ShopInformation__c shop) {
		if (isFirstLoadFlg) {
			if (perSumaryJsonLst != null) {
				Date todayDt = curBatchExcTime.date();
				ReservationListWork__c res1 = insertReservation(LEADFOODSUM,perSumaryJsonLst,shop.Id,todayDt);
				ReservationListWork__c res2 = insertReservation(REPORTFOODSUM,prodSumJsonLst,shop.Id,todayDt);
				ReservationListWork__c res3 = insertReservation(ACCOUNTFOODSUM,prodSumJson2Lst,shop.Id,todayDt);
				List<ReservationListWork__c> reservationLst = new List<ReservationListWork__c>{res1,res2,res3};
				insert reservationLst;
			}
		} else if(isBatchStartFlg && reservationFoodSum != null) {
			for(ReservationListWork__c res : reservationFoodSum){
				res.BatchLastTm__c = curBatchExcTime;
				if(res.FoodSumType__c == LEADFOODSUM && perSumaryJsonLst != null){
					res.FoodSumData__c = perSumaryJsonLst[0];
					res.FoodSumData2__c = perSumaryJsonLst[1];
					res.FoodSumData3__c = perSumaryJsonLst[2];
				} else if(res.FoodSumType__c == REPORTFOODSUM && prodSumJsonLst != null){
					res.FoodSumData__c = prodSumJsonLst[0];
					res.FoodSumData2__c = prodSumJsonLst[1];
					res.FoodSumData3__c = prodSumJsonLst[2];
				} else if(res.FoodSumType__c == ACCOUNTFOODSUM && prodSumJson2Lst != null){
					res.FoodSumData__c = prodSumJson2Lst[0];
					res.FoodSumData2__c = prodSumJson2Lst[1];
					res.FoodSumData3__c = prodSumJson2Lst[2];
				}
			}
			if(!reservationFoodSum.isEmpty()) update reservationFoodSum;
		}
	}
	/**
	* 部屋情報一覧を取得する「一部屋一予約で取得を行う」
	**/
	private List<Room__c> getRoomList(string spcode) {
		// 2017/10/10 予定表に表示 自定义排序 改善対応 WGCH BEGIN
		String roomQueryHeader = ' Select Id, Name, TypeRoomRef__c, TypeRoomRef__r.Name, Seq__c, RoomName__c, Rnumber__c,ShopInfoRef__r.ShopCode__c,ShopInfoRef__r.Name, ' +
								 ' TypeRoomRef__r.ShopInfoRef__c,TypeRoomRef__r.ShopInfoRef__r.ShopCode__c,TypeRoomRef__r.ShopInfoRef__r.Name from Room__c ';
		String ROOM_UseOfType_Fiction = CommConst.ROOM_UseOfType_Fiction;
		String roomQueryWhere = ' Where UseOfRoom__c !=: ROOM_UseOfType_Fiction And ShopInfoRef__r.ShopCode__c = :spcode ';
		// 2017/10/10 予定表に表示したく無い部屋のSEQ#をカンマで複数定義するに改善対応 WGCH BEGIN
		if(!noRmSeqSet.isEmpty()) roomQueryWhere += ' And Seq__c Not in: noRmSeqSet ';
		// 2017/10/10 予定表に表示したく無い部屋のSEQ#をカンマで複数定義するに改善対応 WGCH END
		String roomQueryOrder = ' Order By ' + sortField.split('\\.')[1];
		String roomQueryLimit = ' limit 10000 ';
		String roomQueryStr = roomQueryHeader + roomQueryWhere + roomQueryOrder + roomQueryLimit;
		return Database.query(roomQueryStr);
		/*
		return [Select Id, Name, TypeRoomRef__c, TypeRoomRef__r.Name, Seq__c, RoomName__c, Rnumber__c,ShopInfoRef__r.ShopCode__c,ShopInfoRef__r.Name
								,TypeRoomRef__r.ShopInfoRef__c,TypeRoomRef__r.ShopInfoRef__r.ShopCode__c,TypeRoomRef__r.ShopInfoRef__r.Name from Room__c 
				Where UseOfRoom__c != :CommConst.ROOM_UseOfType_Fiction
						And ShopInfoRef__r.ShopCode__c = :spcode
						// 2017/09/18 予定表に表示したく無い部屋のSEQ#をカンマで複数定義するに改善対応 WGCH BEGIN
						And Seq__c Not in: noRmSeqSet
						// 2017/09/18 予定表に表示したく無い部屋のSEQ#をカンマで複数定義するに改善対応 WGCH END
				Order By Seq__c limit 10000];
		*/
	// 2017/10/10 予定表に表示 自定义排序 改善対応 WGCH END
	}
	
	/**
	* レポート明細情報を格納用
	**/
	public class ReportRow {
		public Lead__c varlead{get; private set;}
		public ReportRow(Room__c room, Lead__c ps, Integer rowIndex) {

			if (ps == null) ps = new Lead__c();
			
			if (ps.Rroom__c == null && room != null) {
				ps.Rroom__c = room.Id;
				ps.Rroom__r = room;
			}
			if (ps.refTypeOfRooms__c == null && room != null) {
				ps.refTypeOfRooms__c = room.TypeRoomRef__c;
				ps.refTypeOfRooms__r = room.TypeRoomRef__r;
			}
			// 予約情報を格納する
			varlead = ps;
			// 予約データ設定を行う
			leadId = CommUtils.nullToBlank(ps.Id);
			// 支店コード
			//branchShopCd = Commutils.isBlank(ps.refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c) 
			//							? ''
			//							: CommUtils.nullToBlank(ps.refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c);
			// 連泊、昼など集計方式設定する
			middayIcon = CommUtils.nullToBlank(ps.Field278__c);
			// 昼と夜の分割で表示対応
			summaryDayIcon = CommUtils.nullToBlank(ps.DayNightCal__c);

			// RowIndex
			this.rowIndex = rowIndex;
			// 明細情報
			detailList = new List<ReportDetail>();
			// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH BEGIN
			// 顧客明細情報
			contactList = new List<ContactDetail>();
			// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH END
			// チェックインステータス判別用(空白以外の場合、チェックインとして認識する)
			this.isCheckIned = !CommUtils.isBlank(ps.Field298__c) && cookInfoSplitShow;
		}
		public String leadId{get;set;}
		//public String branchShopCd{get;set;}
		public String summaryIcon{get{
			if (cookingSummyCode == '1') {
				return middayIcon;
			} else {
				return summaryDayIcon;
			}
		}}
		// 昼:Field278__c
		public String middayIcon{get;set;}
		// 昼：DayNightCal__c
		public String summaryDayIcon{get;set;}
		// 見積り明細情報を格納する
		public List<ReportDetail> detailList{get; private set;}
		// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH BEGIN
		public List<ContactDetail> contactList{get; private set;}
		// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH END
		// 2017/05/12 PDFpost等机能对应 BEGIN By Wgch
		// 2017/04/27 料理数目变更之后【每一行】变颜色对应
		//public void addAllDetailData(List<BookingEstimateItem__c> items) {
		// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH BEGIN
		public void addAllDetailData(List<BookingEstimateItem__c> items, Lead__c lead) {
			String leadIdKey = lead.Id;
		// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH END
		// 2017/05/12 PDFpost等机能对应 END By Wgch
			// 商品明細
			detailList = new List<ReportDetail>();
			// 会計商品の名から見積り明細の商品名にコピーする
			Map<String, ReportDetail> sortMap = new Map<String, ReportDetail>();
			for (BookingEstimateItem__c s : items) {
				ReportDetail subitem = new ReportDetail(s);
				// 商品存在場合[2014/03/27 料理項目明細、商品コードで並び順表示する]
				String key = getCookFieldSortField(subitem);
				// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
				// 显示时处理合成单价key
				if(unitpriceColShow) key += '_' + getUnitPrice(s);
				// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
				if (sortMap.containsKey(key)) {
					sortMap.get(key).amount = CommUtils.deleteRightZero(
												String.valueOf(	CommUtils.nullToZero(sortMap.get(key).amount) + 
																CommUtils.nullToZero(s.Amount__c))
																		);
				} else {
					sortMap.put(key, subitem);
				}
			}
			// 商品名でSORTする
			List<String> prodCodeLst = new List<String>(sortMap.keySet());
			prodCodeLst.sort();
			// 明細データはリストへ追加
			for (String prodNm : prodCodeLst) {
				detailList.add(sortMap.get(prodNm));
			}
			// 2017/05/12 PDFpost等机能对应 BEGIN By Wgch
			// 2017/04/27 料理数目变更之后【每一行】变颜色对应 BEGIN By Wgch
			// データ初期LOADのみ設定を行う
			if (isFirstLoadFlg || curBatchExcTime != null) {
				if (!perSumaryMap.containsKey(leadIdKey)) perSumaryMap.put(leadIdKey,sortMap);
				else perSumaryMap.get(leadIdKey).putAll(sortMap);
			}
			// 該当予約の料理明細変更チェック
			for(ReportDetail subitem : detailList){
				// 比較用キーを取得する
				String key = getCookFieldSortField(subitem);
				// 解析第一层==>> 根据==>>LeadId==>>作为Key
				if(oldPerSumaryData.containsKey(leadIdKey)){
					// 予約単位の料理情報
					Map<String,Object> oldDetailsSobj = oldPerSumaryData.get(leadIdKey);
					// 解析第二层 ==>>根据 ==>>料理項目明細名字==>>作为 Key
					if(oldDetailsSobj.containsKey(key)){
						// 获取到old室料的数量值进行对比
						Map<String, Object> oldSobj = (Map<String, Object>)oldDetailsSobj.get(key);
						Decimal oldAmount = CommUtils.nullToZero(oldSobj.get('amount'));
						Decimal newAmount = CommUtils.nullToZero(subitem.amount);
						// 色変更する
						if(newAmount == oldAmount) continue;
					}
				}
				// 初期LOAD以外の場合、変更色を設定する
				if (!isFirstLoadFlg){
					subitem.style = xmlColorStyle();
				}
			}
			// 2017/04/27 料理数目变更之后【每一行】变颜色对应 END By Wgch
			// 2017/05/12 PDFpost等机能对应 END By Wgch
			// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH BEGIN
			// 顧客明細情報
			contactList = new List<ContactDetail>();
			String key = getContactKey(lead.LeadIndexSubId__c, lead.Rroom__c);
			if(contactInfoMap.containsKey(key)){
				contactList = contactInfoMap.get(key);
			}
			// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH END
		}
		public Integer rowIndex{get;set;}
		// 見積もり明細データ
		public String productName{get;private set;}
		public String amount{get;private set;}
		//public Date queryDate;
		// 予約のお客様ステータスチェックイン・未チェックイン判別用
		public Boolean isCheckIned{get; private set;}
	}
	/**
	* 朝食キー文字を含めの会計ＯＰのＩＤ
	**/
	private Set<Id> getMoringFoodOpIdSet(Set<String> keySet) {
		String OrKey = 'OR';
		String queryStr = ' Select Id from OP__c where ';
		queryStr += ' ( ';
		for (String key : keySet) {
			queryStr += ' Name like \'%' + CommUtils.escStr(key) + '%\' ' + OrKey;
		}
		// 最後のＯＲを削除する
		queryStr = queryStr.substringBeforeLast(OrKey);
		queryStr += ' ) ';
		List<OP__c> opLst = Database.query(queryStr);
		Set<Id> opIdSet = new Set<Id>();
		for (OP__c op : opLst) opIdSet.add(op.Id);
		return opIdSet;
	}
	/**
	* 料理がどうか判別Method
	* TRUE:該当商品は料理場合
	**/
	private static Boolean isCookingByWord(String prodName) {
		if (String.isEmpty(prodName)) return false;
		for (String key : filterOpList) {
			if (prodName.contains(key)) return true;
		}
		return false;
	}
	// 料理項目明細表示の並べ順項目情報を取得する
	private static String getCookFieldSortField(ReportDetail subitem) {
		if (cookFieldSortDiv == '1') {
			// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
			// return subitem.productName;
			return subitem.productName + getUnitPriceKey(subitem.unitPrice);
			// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
		} else {
			// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
			// return subitem.productCode;
			return subitem.productCode + getUnitPriceKey(subitem.unitPrice);
			// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
		}
	}
	// 予約明細の会計商品明細情報格納
	public class ReportDetail {
		public ReportDetail(BookingEstimateItem__c s) {
			// 2017/05/12 PDFpost等机能对应 BEGIN By Wgch
			// 2017/04/27 料理数目变更之后【每一行】变颜色对应
			style = '';
			// 2017/05/12 PDFpost等机能对应 END By Wgch
			productName = CommUtils.nullToBlank(s.refAccountMaster__r.Name == null ? s.ProductName__c : s.refAccountMaster__r.Name);
			// 予定表の部屋ごとの料理の数量の小数点00サプレス対応
			amount = CommUtils.deleteRightZero(CommUtils.nullToBlank(s.Amount__c));
			productCode = CommUtils.nullToBlank(s.refAccountMaster__r.Field3__c == null ? s.Field3__c : s.refAccountMaster__r.Field3__c);
			// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
			// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
			// unitPrice = s.refAccountMaster__r.Field5__c == null ? '' : s.refAccountMaster__r.Field5__c.format();
			unitPrice = getUnitPrice(s);
			// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
			// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
			// 2019/06/14 「料理」列に「会計OP」を表示したい对应 WGCH BEGIN
			try{
				productOpName = CommUtils.nullToBlank(s.OP__r.Name);
			} catch(Exception e){
				productOpName = '';
			}
			// 2019/06/14 「料理」列に「会計OP」を表示したい对应 WGCH END
		}
		public String productCode {get; private set;}
		public String productName {get; private set;}
		public String amount {get; private set;}
		// 2017/05/12 PDFpost等机能对应 BEGIN By Wgch
		// 颜色设置
		public String style {get; private set;}
		// 2017/05/12 PDFpost等机能对应 END By Wgch
		// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
		public String unitPrice {get; private set;}
		// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
		// 2019/06/14 「料理」列に「会計OP」を表示したい对应 WGCH BEGIN
		public String productOpName {get; private set;}
		// 2019/06/14 「料理」列に「会計OP」を表示したい对应 WGCH END
	}
	// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH BEGIN
	private static Map<String, List<ContactDetail>> contactInfoMap;
	// 预约关联contactInfo数据集处理
	private static void getContactData(List<Lead__c> leadLst){
		Set<String> leadIndexIdSet = new Set<String>();
		Set<String> yadoIdSet = new Set<String>(); // 宿帳Id
		Set<String> contactIdSet = new Set<String>(); // 取引先Id
		Map<String, Set<String>> yadoIdMap = new Map<String, Set<String>>(); // Key[予約Id] => value[List<宿帳Id>]
		Map<String, Set<String>> contactIdMap = new Map<String, Set<String>>(); // Key[予約Id] => value[List<取引先Id>]
		contactInfoMap = new Map<String, List<ContactDetail>>(); // Key[予約Id] => value[List<取引先Info>]
		if(leadLst == null || leadLst.isEmpty()) return;
		for(Lead__c lead : leadLst){
			if(CommUtils.isBlank(lead.LeadIndexSubId__c)) continue;
			leadIndexIdSet.add(lead.LeadIndexSubId__c);
		}
		for(Yadochou__c yado : [Select Id, Field1__r.LeadIndexSubId__c, Field1__r.Rroom__c, Field15__c From Yadochou__c Where Field1__r.LeadIndexSubId__c in: leadIndexIdSet And Field15__c != null ]){ // 根据予約Id查到相对于的宿帳Info
			String key = getContactKey(yado.Field1__r.LeadIndexSubId__c, yado.Field1__r.Rroom__c); // Key
			yadoIdSet.add(yado.Id);
			contactIdSet.add(yado.Field15__c);
			if(!yadoIdMap.containsKey(key)) yadoIdMap.put(key, new Set<String>()); // Key[予約Id] => value[List<宿帳Id>]
			yadoIdMap.get(key).add(CommUtils.nullToBlank(yado.Id));
			if(!contactIdMap.containsKey(key)) contactIdMap.put(key, new Set<String>());
			else if(contactIdMap.get(key).contains(yado.Field15__c)) continue; // 过滤重复顾客
			contactIdMap.get(key).add(yado.Field15__c);
		}
		for(Guestbookcustomer__c guest : [Select Id, GuestbookNmae__c, customer__c From Guestbookcustomer__c Where GuestbookNmae__c in: yadoIdSet And customer__c != null ]){ // 根据宿帳Id查到相对于的宿帳明細Info
			String yadoId = guest.GuestbookNmae__c; // 宿帳Id
			if(CommUtils.isBlank(yadoId)) continue; // 无宿帳的跳到下一个
			contactIdSet.add(guest.customer__c);
			for(String key : yadoIdMap.keySet()){ // 合并取引先Id, key[予約Id]
				Set<String> wkYadoIdSet = yadoIdMap.get(key); // 取到当前予約下的所以宿帳Id
				if(!wkYadoIdSet.contains(yadoId) || contactIdMap.get(key).contains(guest.customer__c)) continue;
				contactIdMap.get(key).add(guest.customer__c); // 过滤重复顾客
			}
		}
		String queryContactSel = ' Select id, name ';
		for(String api : guestLabelMap.keySet()){
			if(api == 'id' || api == 'name') continue;
			queryContactSel += ',' + api;
		}
		String queryContactWhere = ' Where Id in: contactIdSet';
		String queryContactStr = queryContactSel + ' From Contact ' + queryContactWhere;
		List<Contact> contactLst = DataBase.query(queryContactStr);
		for(Contact sobj : contactLst){ // 根据宿帳Id查到相对于的宿帳明細Info
			for(String key : contactIdMap.keySet()){
				if(!contactIdMap.get(key).contains(sobj.Id)) continue; // 当前预约不包含取引先Id跳过
				if(!contactInfoMap.containsKey(key)) contactInfoMap.put(key, new List<ContactDetail>()); // Key[予約Id] => value[List<宿帳Id>]
				contactInfoMap.get(key).add(new ContactDetail(sobj));
			}
		}
	}
	private static String getContactKey(String leadIndexId, String roomId){
		return CommUtils.nullToBlank(leadIndexId) + '_' + CommUtils.nullToBlank(roomId);
	}
	// 予約明細の会計商品明細情報格納
	public class ContactDetail {
		public ContactDetail(Contact sobj) {
			contactId = CommUtils.nullToBlank(sobj.Id);
			contactName = CommUtils.nullToBlank(sobj.Name);
			contactApiInfo = '';
			for(String api : guestApiLst){ // 合并自定义字段值
				contactApiInfo += '　' + guestLabelMap.get(api).escapeHtml4() + ':' + CommUtils.nullToBlank(sobj.get(api)) + '<br/>';
			}
			contactApiInfo = contactApiInfo.removeEnd('<br/>');
		}
		public String contactId {get; private set;}
		public String contactName {get; private set;}
		public String contactApiInfo {get; private set;}
	}
	// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH END
	// 合計情報格納
	public class ReportSumRow {
		public ReportSumRow() {
			productSummy = 0;
			// 2017/05/12 PDFpost等机能对应 BEGIN By Wgch
			style = '';
			// 2017/05/12 PDFpost等机能对应 END By Wgch
			// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
			unitPrice = '';
			// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
		}
		public String middayIcon{get;set;}
		public String sortKey{get;set;}
		public String productName{get;set;}
		public Decimal productSummy{get;set;}
		// 2017/05/12 PDFpost等机能对应 BEGIN By Wgch
		public String style{get;set;}
		// 2017/05/12 PDFpost等机能对应 END By Wgch
		// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
		public String op{get;set;}
		// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
		// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
		public String unitPrice {get; private set;}
		// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
	}
	// 2017/05/12 PDFpost等机能对应 BEGIN By Wgch
	// 2017/04/27 料理数目变更之后变颜色对应 BEGIN By Wgch
	// jsonDate==>>Map
	private static Map<String,Map<String,ReportDetail>> perSumaryMap = new Map<String,Map<String,ReportDetail>>();
	// 上次寄存的sobj
	private static Map<String, Map<String,Object>> oldPerSumaryData;	// 予約単位明細情報
	// 画面初期表示情報Loadするがどうか判断用フラグ：TRUE：初期LOAD
	private static Boolean isFirstLoadFlg;
	// 料理集計変更されるがどうチェック
	public static void chkChangeForFoodSum(Map<String, ReportSumRow> newMap, Map<String, Object> oldMap){
		for(String keys : newMap.keySet()){
			// 既存情報の場合
			if(oldMap == null || !oldMap.containsKey(keys)){
				if(!isFirstLoadFlg) prodSumColorSet(newMap, newMap.get(keys), keys);
			} else {
				Map<String, Object> oldSobj = (Map<String, Object>)oldMap.get(keys);
				// 解析第二层 ==>>根据 ==>>料理項目明細名字==>>作为 Key
				ReportSumRow newRepItem = newMap.get(keys);
				Integer oldAmount = CommUtils.nullToIntZero(oldSobj.get('productSummy'));
				Integer newAmount = CommUtils.nullToIntZero(newRepItem.productSummy);
				// 获取到old室料的数量值进行对比 
				if(oldAmount != newAmount) prodSumColorSet(newMap, newRepItem, keys);
			} 
		}
	}
	// 料理集計情報JSON→OBJECT変換処理
	public static Map<String,Object> foodColorJsonToMap(String oldJson){
		Map<String, Map<String,Object>> oldDataMap = new Map<String, Map<String,Object>>();
		Map<String,Object> wkDefMap = (Map<String,Object>)JSON.deserializeUntyped(oldJson);
		return wkDefMap;
	}
	public static void prodSumColorSet(Map<String, ReportSumRow> newMap, ReportSumRow newRepItem, String keys){
		newRepItem.style = xmlColorStyle();
		newMap.put(keys,newRepItem);
	}
	// 设置对应的颜色
	public static String xmlColorStyle(){
		isBatchStartFlg = true;
		String bgColor = bgColorFlg ? foodSumColor :'';
		String fontColor = bgColorFlg ? '' :foodSumColor;
		return 'background-color:' + bgColor + ';color:'+ fontColor + ';';
	}
	// 2017/04/27 料理数目变更之后变颜色对应 END By Wgch 

	public List<LeadApi> leadApiLst{get;set;}
	// '__r' ==>> '__c'
	public class LeadApi {
		public LeadApi(String api){
			leadApiStrBf = api;
			if(api.contains('__r')) api = api.split('__r')[0] + '__c';
			leadApiStrAf = api.toLowerCase();
			// 2020/02/28 同伴者情報列位置自定义改善对应 WGCH BEGIN
			bfLst = new List<String>();
			afLst = new List<String>();
			// 2020/02/28 同伴者情報列位置自定义改善对应 WGCH END
		}
		public String leadApiStrBf{get;set;}
		public String leadApiStrAf{get;set;}
		// 2020/02/28 同伴者情報列位置自定义改善对应 WGCH BEGIN
		public List<String> bfLst{get;set;}
		public List<String> afLst{get;set;}
		// 2020/02/28 同伴者情報列位置自定义改善对应 WGCH END
	}
	// 130000 位单位长度分组 处理过长json的储存处理
	public static List<String> jsonCut(String jsonStr){
		Integer textAreaSizeMax = 130000;
		Integer jsonStrSize = jsonStr.length();
		if(jsonStrSize / textAreaSizeMax > 0){
			// 第一个long textArea String
			String jsonStr1 = jsonStr.subString(0,textAreaSizeMax);
			// 第一个 之后 剩余的 String
			String jsonStrMod = jsonStr.subString(textAreaSizeMax,jsonStrSize);
			if(jsonStrMod.length() / textAreaSizeMax > 0){
				// 第二个long textArea String
				String jsonStr2 = jsonStr.subString(textAreaSizeMax,2*textAreaSizeMax);
				// 第二个 之后 剩余的 String ==>> 也就是说最终省的都放在第三里,即使大约保存范围了,也不对应了
				String jsonStrMod2 = jsonStr.subString(2*textAreaSizeMax,jsonStrSize);
				return new List<String>{jsonStr1,jsonStr2,jsonStrMod2};
			} else return new List<String>{jsonStr1,jsonStrMod,''};	
		} else return new List<String>{jsonStr,'',''};
	}
	// JsonData 合成
	public static String jsonMerger(String jsonStr,String jsonStr2,String jsonStr3){
		if(!CommUtils.isBlank(jsonStr2)) jsonStr += jsonStr2;
		if(!CommUtils.isBlank(jsonStr3)) jsonStr += jsonStr3;
		return jsonStr;
	}
	// 插入料理数据 处理
	public static ReservationListWork__c insertReservation(String foodSumType,List<String> foodSumDataLst,String shopInfoRefId,Date todayDt){
		ReservationListWork__c res = new ReservationListWork__c(
			FoodSumType__c = foodSumType,
			FoodSumData__c = foodSumDataLst[0],
			FoodSumData2__c = foodSumDataLst[1],
			FoodSumData3__c = foodSumDataLst[2],
			ShopInfoRef__c = shopInfoRefId,
			//BatchLastTm__c = batchLastTm,
			EntryDate__c = todayDt
		);
		return res;
	}
	/**
	* 予約項目履歴変更機能追加
	**/
	private static Map<Id, LeadHistories.LeadHistoryItem > getTodayLeadHistory(List<Lead__c> leads,DateTime batchLastTm,DateTime isBatchLastTm) {
		// 2017/10/10 WGCH BEGIN
		if(leads == null || leads.isEmpty()) return new Map<Id, LeadHistories.LeadHistoryItem>();
		// 2017/10/10 WGCH END
		List<Id> leadIdLst = new List<Id>();
		for (Lead__c lead : leads) leadIdLst.add(lead.Id);
		LeadHistories his = new LeadHistories(leadIdLst,batchLastTm,isBatchLastTm);
		his.init();
		return his.resultMap;
	} 
	// 2017/05/12 PDFpost等机能对应 END By Wgch	
	private void reportSumRowSort(ReportSumRow newRepSum, map<string, map<string,list<ReportSumRow>>> sortFieldMap){
		// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
		// 防御处理
		if(newRepSum == null || sortFieldMap == null) return;
		// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
		String key1 = newRepSum.middayIcon;
		String key2 = newRepSum.sortKey;
		if (!sortFieldMap.containsKey(key1)) {
			map<string, list<ReportSumRow>> sortMap = new map<string, list<ReportSumRow>>();
			sortFieldMap.put(key1, sortMap);
		}
		map<string, list<ReportSumRow>> sortMap = sortFieldMap.get(key1);
		if (!sortMap.containsKey(key2)) {
			list<ReportSumRow> itemLst = new list<ReportSumRow>();
			sortMap.put(key2, itemLst);
		}
		sortMap.get(key2).add(newRepSum);
	}
	// 2017/10/10 WGCH BEGIN
	// private void reportSumRowSort(map<string, map<string,list<ReportSumRow>>> sortFieldMap){
	private List<ReportSumRow> reportSumRowSort(map<string, map<string,list<ReportSumRow>>> sortFieldMap){
	// 2017/10/10 WGCH END
		// 料理集計並び順
		List<ReportSumRow> foodSumRowLst = new List<ReportSumRow>();
		// 並び順処理を行う
		list<String> key1SortLst = new list<String>(sortFieldMap.keySet());
		key1SortLst.sort();
		// SORTKEY2並び順処理を行う
		for (Integer i = key1SortLst.size() -1; i >= 0; i--) {
			String key1 = key1SortLst[i];
			map<string,list<ReportSumRow>> sortMap = sortFieldMap.get(key1);
			// 並び順処理を行う　
			list<string> key2SortLst = new list<String>(sortMap.keySet());
			key2SortLst.sort();
			// 明細順位はリストに格納を行う
			for (String key2 : key2SortLst) {
				foodSumRowLst.addAll(sortMap.get(key2));
			}
		}
		// 2017/10/10 WGCH BEGIN
		//foodSumRowLstAll.add(foodSumRowLst);
		return foodSumRowLst;
		// 2017/10/10 WGCH END
	}
	// 2018/10/15 料理集計に合計の表記がございますが機能対応 WGCH BEGIN
	private void setFooterDetail(FoodSumInfo foodSumRow1, map<Date, map<string, map<string,list<ReportSumRow>>>> sortFieldDtMap){
		Map<String, ReportSumRow> summaryRepFooterMap = new Map<String, ReportSumRow>();
		for(Map<string, Map<string,List<ReportSumRow>>> map1 : sortFieldDtMap.values()){ // 集计相同商品数量处理
			for(Map<String, List<ReportSumRow>> map2 : map1.values()){
				for(List<ReportSumRow> itemLst : map2.values()){
					for(ReportSumRow item : itemLst){
						if(CommUtils.nullToIntZero(item.productSummy) == 0) continue;
						if(!summaryRepFooterMap.containsKey(item.sortKey)) summaryRepFooterMap.put(item.sortKey, item.clone());
						else{
							ReportSumRow oldItem = summaryRepFooterMap.get(item.sortKey);
							oldItem.productSummy += item.productSummy;
						}
					}
				}
			}
		}
		List<String> sortKeyLstAsc = new List<String>(summaryRepFooterMap.keySet());
		// 並び順処理を行う
		sortKeyLstAsc.sort();
		for(String sortKey : sortKeyLstAsc){
			foodSumRow1.reportSumRowLst.add(summaryRepFooterMap.get(sortKey));
		}
	}
	private void setGroupFooterDetailMap(Date keyDate, FoodSumInfo foodSumRow1, List<ReportSumRow> reportSumRowLst){
		Map<String, ReportSumRow> summaryRepFooterMap = new Map<String, ReportSumRow>();
		for(ReportSumRow item : reportSumRowLst){ // 集计相同商品数量处理
			if(CommUtils.nullToIntZero(item.productSummy) == 0) continue;
			if(!summaryRepFooterMap.containsKey(item.sortKey)) summaryRepFooterMap.put(item.sortKey, item.clone());
			else{
				ReportSumRow oldItem = summaryRepFooterMap.get(item.sortKey);
				oldItem.productSummy += item.productSummy;
			}
		}
		List<String> sortKeyLstAsc = new List<String>(summaryRepFooterMap.keySet());
		// 並び順処理を行う
		sortKeyLstAsc.sort();
		List<ReportSumRow> wkReportSumRowLst = new List<ReportSumRow>();
		for(String sortKey : sortKeyLstAsc){
			wkReportSumRowLst.add(summaryRepFooterMap.get(sortKey));
		}
		foodSumRow1.groupFooterDetailMap.put(keyDate, wkReportSumRowLst);
	}
	// 2018/10/15 料理集計に合計の表記がございますが機能対応 WGCH END
	// -------------------------------------------
	// 各店舗の表示する項目情報を取得、格納を行う
	// -------------------------------------------
	private String parseFieldsXml(String pShopCode) {
		// ログインユーザーの店舗コードが存在チェックを行う
		// StaticResourceから設定情報を取得する（ＸＭＬ）
		pageWidth = 1980;
		// 2017/05/12 PDFpost等机能对应 BEGIN By Wgch
		// 2017/04/27 料理数目变更之后变颜色对应 wgch BEGIN
		foodSumColor = '';//料理変更する倍、色値
		bgColorFlg = true;
		// 2017/05/12 PDFpost等机能对应 END By Wgch
		// 2019/06/28 初期化地址共存修复对应 WGCH BEGIN
		pdfNoHiddenColnumFlg = unitpriceColShow = opColIsShowFlg = oneNightSumFlg = false;
		// 2019/06/28 初期化地址共存修复对应 WGCH END
		try{
			List<Document> sr = [select body, name from Document where DeveloperName = 'ScheduleReportFieldsXml'];
			if (sr.isEmpty()) return '';
			Blob xmlBody = sr[0].Body;
			String strXmlBody = xmlBody.toString();
			
			Dom.XmlNode targetNode, firstNode = null;
			Dom.Document doc = new Dom.Document();
			doc.load(strXmlBody);
			Dom.XMLNode root = doc.getRootElement();
			for(Dom.XMLNode shop : root.getChildElements()) {
				// 各店舗情報はＸＭＬから取得する
				Dom.XmlNode shopcode = shop.getChildElement('SHOPCODE', null);
				// 店舗コードを取得する
				// 2014/01/23 WGCH BEGIN
				if(shopcode == null) break;
				// 2014/01/23 WGCH END
				String strShopCode = CommUtils.nullToBlank(shopcode.getText());
				if (firstNode == null) firstNode = shop;
				// ログインユーザの店舗コードと一致する場合
				if (strShopCode == pShopCode) {
					targetNode = shop;
					break;
				}
			}
			// 目標店舗情報を取得する、店舗コード未設定する場合、一番目の店舗情報で設定する
			targetNode = targetNode == null ? firstNode : targetNode;
			if (targetNode == null) return '';
			// 2021/05/31 予定表のレイアウトを複数パターンから切り替えられるようにしたいユーザ単位で保存できるように by zy BEGIN
			Dom.XmlNode layoutFields = targetNode.getChildElement('LAYOUT', null);
			if (layoutFields != null) {
				for (Dom.XmlNode dom : targetNode.getChildElements()){
					if (dom.getName() == 'LAYOUT'){
						Dom.XmlNode layoutDom = dom.getChildElement('LAYOUTCODE',null);
						String domLayoutCode = '';
						String layoutLabel = '';
						if (layoutDom != null) {
							domLayoutCode = CommUtils.nullToBlank(layoutDom.getText());
						}
						Dom.XmlNode layoutLabelDom = dom.getChildElement('LAYOUTLABEL',null);
						if (layoutLabelDom != null) {
							layoutLabel = CommUtils.nullToBlank(layoutLabelDom.getText());
						}
						if (!CommUtils.isBlank(domLayoutCode)){
							if (domLayoutCode == pLayoutId){
								targetNode = dom;
								break;
							}
						}
					}
				}
			}
			// 2021/05/31 予定表のレイアウトを複数パターンから切り替えられるようにしたいユーザ単位で保存できるように by zy END
			// 店舗情報はＸＭＬから取得する
			Dom.XmlNode shopFields = targetNode.getChildElement('FIELDS', null);
			Dom.XmlNode avgFields = targetNode.getChildElement('AGGREGATE', null);
			Dom.XmlNode exportPdfFields = targetNode.getChildElement('EXPORTPDF', null);
			Dom.XmlNode dataTypeFields = targetNode.getChildElement('COLNUMTYPE', null);
			
			// 合計項目設定内容を取得する
			// 集計情報格納用変数を初期化する
			avgSumMap = new map<String, Decimal>();
			if (avgFields != null) {
				String strAvgFields = CommUtils.nullToBlank(avgFields.getText()).deleteWhitespace();
				if (!CommUtils.isBlank(strAvgFields)) {
					customAggregateFields.addAll(strAvgFields.split(','));
				}
				// 合計値初期化設定を行う
				for (String api : customAggregateFields) {
					avgSumMap.put(api,0);
				}
			}
			// 2019/06/28 ユーザ側で非表示にした項目対応 WGCH BEGIN
			Dom.XmlNode hidFields = targetNode.getChildElement('HIDDENFIELD', null);
			if (hidFields != null) {
				String strHidFields = CommUtils.nullToBlank(hidFields.getText()).deleteWhitespace();
				if (!CommUtils.isBlank(strHidFields)) {
					customHidFields.addAll(strHidFields.split(','));
				}
			}
			// 2019/06/28 ユーザ側で非表示にした項目対応 WGCH END
			// 項目タイプ
			// boolean , date , number
			// 2017/10/27 GROUP功能对应 WGCH BEGIN
			customTypemap = new map<String, String>();
			if (dataTypeFields != null) {
				String strTypeFields = CommUtils.nullToBlank(dataTypeFields.getText()).deleteWhitespace();
				if (!CommUtils.isBlank(strTypeFields)) {
					for (String key : strTypeFields.split(',')) {
						String[] typeCof = key.split(':');
						if (typeCof.size() != 2) continue;
						customTypemap.put(typeCof[0],typeCof[1]);
					}
				}
			}
			// 2017/10/27 GROUP功能对应 WGCH END
			// 2017/05/12 PDFpost等机能对应 BEGIN By Wgch
			Dom.XmlNode historyFields = targetNode.getChildElement('HISTORY', null);
			if (historyFields != null) {
				Dom.XmlNode bgColorFields = historyFields.getChildElement('BGCOLOR', null);
				if(bgColorFields != null){
					bgColorFlg = Boolean.valueOf(CommUtils.nullToBlank(bgColorFields.getText()));
				}
				/*
				// 2017/04/27 料理数目变更之后变颜色对应 wgch 
				Dom.XmlNode foodSumColorNode = historyFields.getChildElement('FOODSUMMARYCOLOR', null);
				if(foodSumColorNode != null){
					Dom.XmlNode foodSumColorFields = foodSumColorNode.getChildElement('VALUE', null);
					if(foodSumColorFields != null){
						foodSumColor = CommUtils.nullToBlank(foodSumColorFields.getText());
					}
				}
				*/
			}
			// 2017/05/12 PDFpost等机能对应 END By Wgch
			// 2018/07/30 料理集計 WGCH BEGIN
			Dom.XmlNode nightsGroupAble = targetNode.getChildElement('NIGHTSGROUPABLE', null);
			if(nightsGroupAble != null){
				String nightsGroupAbleStr = CommUtils.nullToBlank(nightsGroupAble.getText());
				foodNightsFlg = Boolean.valueOf(nightsGroupAbleStr);
			}
			// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
			mode = '0';
			// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
			Dom.XmlNode foodSummaryFields = targetNode.getChildElement('FOODSUMMARY', null);
			if (foodsummaryFields != null) {
				// 泊数列背景颜色
				Dom.XmlNode consecutiveNights = foodsummaryFields.getChildElement('CONSECUTIVENIGHTS', null);
				if (consecutiveNights != null) {
					for(Dom.XMLNode bgColorNode : consecutiveNights.getChildElements()){
						if(bgColorNode.getName().equalsIgnoreCase('BACKGROUNDCOLOR')){
							String bgColor = CommUtils.nullToBlank(bgColorNode.getText());
							if (CommUtils.isBlank(bgColor)) continue;
							K_ScheduleReport.ColumnBgColor bgColorItem = new K_ScheduleReport.ColumnBgColor();
							String fromNight = CommUtils.nullToBlank(bgColorNode.getAttribute('FROMNIGHT', null));
							String toNight = CommUtils.nullToBlank(bgColorNode.getAttribute('TONIGHT', null));
							bgColorItem.bgColor = bgColor;
							bgColorItem.fromNight = fromNight;
							bgColorItem.toNight = toNight;
							K_ScheduleReport.columnBgColorLst.add(bgColorItem);
						}
					}
				}
				// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
				// 单价列显示
				Dom.XmlNode unitpriceColShowFields = foodsummaryFields.getChildElement('UNITPRICECOLSHOW', null);
				if (unitpriceColShowFields != null) {
					unitpriceColShow = Boolean.valueOf(CommUtils.nullToBlank(unitpriceColShowFields.getText()));
					// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
					mode = CommUtils.nullToBlank(unitpriceColShowFields.getAttribute('MODE', null));
					// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
				}
				// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
				// 2019/05/15 料理集計「単泊」の料理数は「連泊の１泊目」に合計する機能対応 WGCH BEGIN
				Dom.XmlNode oneNightSumFlgFields = foodsummaryFields.getChildElement('ONENIGHTSUMFLG', null);
				if (oneNightSumFlgFields != null) {
					oneNightSumFlg = Boolean.valueOf(CommUtils.nullToBlank(oneNightSumFlgFields.getText()));
				}
				// 2019/05/15 料理集計「単泊」の料理数は「連泊の１泊目」に合計する機能対応 WGCH END
			}
			// 2018/07/30 料理集計 WGCH END
			
			// 2017/09/18 予定表に表示したく無い部屋のSEQ#をカンマで複数定義するに改善対応 WGCH BEGIN
			Dom.XmlNode noShowRoomFields = targetNode.getChildElement('NOSHOWROOM', null);
			if(noShowRoomFields != null){
				for(String seqStr : CommUtils.nullToBlank(noShowRoomFields.getText()).split(',')){
					if(!CommUtils.isBlank(seqStr)) noRmSeqSet.add(CommUtils.nullToZero(seqStr));
				}
			}
			// 2017/09/18 予定表に表示したく無い部屋のSEQ#をカンマで複数定義するに改善対応 WGCH END
			// 2017/10/18 予定表を表示のとき、部屋順で表示できる改善対応 WGCH BEGIN
			sortField = 'Rroom__r.Seq__c';
			Dom.XmlNode sortApiFields = targetNode.getChildElement('SORTFIELD', null);
			if (sortApiFields != null) {
				String sortApiStr = CommUtils.nullToBlank(sortApiFields.getText());
				if(!CommUtils.isBlank(sortApiStr)){
					String[] sortApiArr = sortApiStr.toLowerCase().split('__r.');
					if(sortApiArr.Size() == 2 && sortApiArr[0] == 'rroom') sortField = sortApiStr;
				}
			}
			// 2017/10/27 GROUP功能对应 WGCH BEGIN
			// GROUPABLE功能FLG TRUE:有效;FALSE:无效;
			Dom.XmlNode groupAbleFields = targetNode.getChildElement('GROUPABLE', null);
			if (groupAbleFields != null) {
				Dom.XmlNode groupTitleFields = groupAbleFields.getChildElement('GROUPTITLE', null);
				if (groupTitleFields != null) {
					// 取到 GROUPTITLE Tab里的信息
					String groupTitleStr = CommUtils.nullToBlank(groupTitleFields.getText());
					for(String groupTitleApi : CommUtils.nullToBlank(groupTitleFields.getText()).split(',') ){
						// 取API
						String[] groupLst = groupTitleApi.split(':');
						if(!groupLst.isEmpty()){
							String api = CommUtils.nullToBlank(groupLst[0]);
							if(CommUtils.isBlank(api) || grpTitlApiSet.contains(api)) continue;
							// add 有效的Api
							if (!grpTitlApiSet.contains(api)) grpTitlApiLst.add(api);
							grpTitlApiSet.add(api);
							// add 有效的集计Api
							if(groupLst.size() == 2 && !CommUtils.isBlank(groupLst[1])) grpAggrApiSet.add(api);
						}
					}
				}
			}
			// 2017/10/27 GROUP功能对应 WGCH END
			// 2017/10/18 予定表を表示のとき、部屋順で表示できる改善対応 WGCH END
			// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH BEGIN
			String strShowGuest = shopFields == null ? '' : CommUtils.nullToBlank(shopFields.getAttribute('SHOWGUEST', null));
			isShowGuestInfo = CommUtils.isBlank(strShowGuest) ? false : Boolean.valueOf(strShowGuest);
			Dom.XmlNode guestFields = targetNode.getChildElement('GUESTYADOINFO', null);
			guestTitle = guestFields == null ? '' : CommUtils.nullToBlank(guestFields.getAttribute('TITLE', null));
			if(CommUtils.isBlank(guestTitle)) guestTitle = Label.MSG_041_0068;
			//SYSTEM.DEBUG(LOGGINGLEVEL.INFO,'guestFields:='+guestFields);
			if (guestFields != null && isShowGuestInfo) {
				for(String guestApi : CommUtils.nullToBlank(guestFields.getText()).split(',') ){
					//SYSTEM.DEBUG(LOGGINGLEVEL.INFO,'guestApi:='+guestApi);
					// 取API
					String[] guestLst = guestApi.split(':');
					if(guestLst.size() == 2){
						String api = CommUtils.nullToBlank(guestLst[0]).toLowerCase().replace('relcontact__r.','');
						if(CommUtils.isBlank(api) || guestLabelMap.containsKey(api)) continue;
						guestLabelMap.put(api, CommUtils.nullToBlank(guestLst[1]));
						// add 有效的Api
						guestApiLst.add(api);
					}
				}
				isShowGuestInfo = !guestApiLst.isEmpty();
			}
			// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH END
			// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
			foodGroupAbleFlg = false;
			Dom.XmlNode foodGroupAble = targetNode.getChildElement('FOODGROUPABLE', null);
			if(foodGroupAble != null){
				String foodGroupAbleStr = CommUtils.nullToBlank(foodGroupAble.getText());
				foodGroupAbleFlg = Boolean.valueOf(foodGroupAbleStr);
			}
			// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
			// 2020/02/28 同伴者情報列位置自定义改善对应 WGCH BEGIN
			isShowGuestPositionFlg = false;
			if (shopFields != null) {
				String strShowguestIdx = CommUtils.nullToBlank(shopFields.getAttribute('SHOWGUESTPOS', null));
				if (CommUtils.isBlank(strShowguestIdx)) {
					isShowGuestPosition = 9999;
				} else {
					isShowGuestPosition = CommUtils.nullToZero(strShowguestIdx);
					if(isShowGuestPosition <= 0) isShowGuestPosition = 9999;
					isShowGuestPositionFlg = true;
				}
			} else {
				isShowGuestPosition = 9999;
			}
			isShowGuestPositionOld = isShowGuestPosition;
			// 2020/02/28 同伴者情報列位置自定义改善对应 WGCH END
			// 2018/10/15 料理集計に合計の表記がございますが機能対応 WGCH BEGIN
			Dom.XmlNode foodSumIsShowProd = targetNode.getChildElement('FOODSUMISSHOWPROD', null);
			foodSumIsShowProdFlg = foodSumIsShowProd == null ? false : Boolean.valueOf(CommUtils.nullToBlank(foodSumIsShowProd.getText()));
			Dom.XmlNode foodSumIsNoShow = targetNode.getChildElement('FOODSUMISNOSHOW', null);
			foodSumIsShowFlg = !(foodSumIsNoShow == null ? false : Boolean.valueOf(CommUtils.nullToBlank(foodSumIsNoShow.getText())));
			// 2018/10/15 料理集計に合計の表記がございますが機能対応 WGCH END
			// 2019/06/14 「料理」列に「会計OP」を表示したい对应 WGCH BEGIN
			Dom.XmlNode optionsFields = targetNode.getChildElement('OPTIONS', null);
			if(optionsFields != null){
				Dom.XmlNode opColIsShow = optionsFields.getChildElement('SHOWFOODISSHOWOP', null);
				if(opColIsShow != null){
					opColIsShowFlg = Boolean.valueOf(CommUtils.nullToBlank(opColIsShow.getText()));
					opLabel = CommUtils.nullToBlank(opColIsShow.getAttribute('LABEL', null));
				}
				// 2019/06/28 ユーザ側で非表示にした項目対応 WGCH BEGIN
				Dom.XmlNode pdfNoHiddenColnum = optionsFields.getChildElement('PDFNOHIDDENCOLNUM', null);
				if(pdfNoHiddenColnum != null){
					String pdfNoHiddenColnumStr = CommUtils.nullToBlank(pdfNoHiddenColnum.getText());
					pdfNoHiddenColnumFlg = Boolean.valueOf(pdfNoHiddenColnumStr);
				}
				// 2019/06/28 ユーザ側で非表示にした項目対応 WGCH END
			}
			// 2019/06/14 「料理」列に「会計OP」を表示したい对应 WGCH END
			// [PDF--width]
			String apiStr = shopFields == null ? '' : CommUtils.nullToBlank(shopFields.getText()).deleteWhitespace();
			// 2014/03/18 料理項目横幅設定
			String strShowFood = shopFields == null ? '' : CommUtils.nullToBlank(shopFields.getAttribute('SHOWFOOD', null));
			// 2019/04/15 料理自定义列所在位置功能对应 WGCH BEGIN
			if (shopFields != null) {
				String strShowfoodIdx = CommUtils.nullToBlank(shopFields.getAttribute('SHOWFOODPOS', null));
				if (CommUtils.isBlank(strShowfoodIdx)) {
					isShowFoodPosition = 9999;
				} else {
					isShowFoodPosition = CommUtils.nullToZero(strShowfoodIdx);
					if (isShowFoodPosition <= 0) isShowFoodPosition = 9999;
				}
			} else {
				isShowFoodPosition = 9999;
			}
			// 2020/02/28 同伴者情報列位置自定义改善对应 WGCH BEGIN
			if(isShowGuestPosition == isShowFoodPosition) isShowGuestPosition++;
			isShowFoodPositionOld = isShowFoodPosition;
			// 2020/02/28 同伴者情報列位置自定义改善对应 WGCH END
			// 2019/04/15 料理自定义列所在位置功能对应 WGCH END
			// 2019/04/30 料理項目列のタイトルを表示・非表示切り替えフラグ WSQ BEGIN
			isNoShowFoodHeader = shopFields == null ? false : Boolean.valueOf(CommUtils.nullToBlank(shopFields.getAttribute('SHOWFOODSIMPLE', null)));
			// 2019/04/30 料理項目列のタイトルを表示・非表示切り替えフラグ WSQ END
			// 関連情報を設定する
			isShowFoodInfo = CommUtils.isBlank(strShowFood) ? false : Boolean.valueOf(strShowFood);
			foodSumColor = '#FFEC8B';
			if (exportPdfFields != null) {
				// 2017/09/18 予定表に表示したく無い部屋のSEQ#をカンマで複数定義するに改善対応 WGCH BEGIN
				Dom.XmlNode noShowRoomFlgFields = exportPdfFields.getChildElement('NOSHOWROOMFLG', null);
				if(noShowRoomFlgFields != null){
					// 默认值:TRUE 不设置TAB TAB里没有值 都认为是TRUE
					// 转成小写
					String noRmSeqFlgStr = CommUtils.nullToBlank(noShowRoomFlgFields.getText()).toLowerCase();
					Boolean noRmSeqFlg = noRmSeqFlgStr != 'false';
					if(!noRmSeqFlg) noRmSeqSet = new Set<Decimal>();
				}
				// 2017/09/18 予定表に表示したく無い部屋のSEQ#をカンマで複数定義するに改善対応 WGCH END
				Dom.XmlNode apiFields = exportPdfFields.getChildElement('FIELDS', null);
				Dom.XmlNode pageWidthFields = exportPdfFields.getChildElement('MAXWIDTH', null);
				if(pageWidthFields != null) {
					String pageWidthStr = CommUtils.nullToBlank(pageWidthFields.getText()).deleteWhitespace();
					if(!CommUtils.isBlank(pageWidthStr)){
						pageWidth = CommUtils.nullToIntZero(pageWidthStr.replaceAll('[^0-9]+', ''));
					}
				}
				Dom.XmlNode colorFields = exportPdfFields.getChildElement('COLOR', null);
				if(colorFields != null){
					String wkFoodSumColor = CommUtils.nullToBlank(colorFields.getText());
					if (!CommUtils.isBlank(wkFoodSumColor)) foodSumColor = wkFoodSumColor;
				}
				String apiItem = apiFields == null ? '' : CommUtils.nullToBlank(apiFields.getText()).deleteWhitespace();
				if(!CommUtils.isBlank(apiItem)){
					// 2014/03/18 料理項目横幅設定
					strShowFood = apiFields == null ? '' : CommUtils.nullToBlank(apiFields.getAttribute('SHOWFOOD', null));
					isShowFoodInfo = CommUtils.isBlank(strShowFood) ? false : Boolean.valueOf(strShowFood);
					return apiItem;
				} else return apiStr;
			} else return apiStr;
		} catch(Exception e){
			System.debug(LoggingLevel.INFO, 'Error:' + e.getMessage());
			return e.getMessage();
		}
	}
	// 2017/10/27 GROUP功能对应 WGCH BEGIN
	public transient static Map<Date, LeadInfo> dataAllMap{get; set;}
		public class LeadInfo{
		public LeadInfo(){
			titleKeyLst = new List<String>();
			titleValMap = new Map<String, String>();
			titleItmMap = new Map<String, List<ReportRow>>();
		}
		// TitleKey
		public List<String> titleKeyLst {get; set;}
		// TitleVal
		public Map<String, String> titleValMap {get; set;}
		// TitleItem
		public Map<String, List<ReportRow>> titleItmMap {get; set;}
	}	
	private static void setDataAllMap(Lead__c ld, Date keyDate, ReportRow orgRep){
		// 当天对应的InTheClass
		LeadInfo ldInfo = dataAllMap.get(keyDate);
		// 当天对应的TitleKey
		List<String> titleKeyLst = ldInfo.titleKeyLst;
		// 当天对应的TitleKey里的预约InTheClass
		Map<String, List<ReportRow>> titleItmMap = ldInfo.titleItmMap;
		// 获取TitleKey
		String titleKey = getTitleKey(ld, ldInfo);
		// 每个TitleKey对应里面的数据集
		if(!titleItmMap.containsKey(titleKey)){
			// 加入TitleKey[留排序等用处]
			titleKeyLst.add(titleKey);
			titleItmMap.put(titleKey, new List<ReportRow>());
		}
		titleItmMap.get(titleKey).add(orgRep);
	}
	private static String getTitleKey(Lead__c ld, LeadInfo ldInfo){
		// 2017/09/18 予定表を表示のとき、部屋順で表示できる改善対応 WGCH BEGIN
		String ldIndexNmKey = getLdIndexNmKey(ld);
		// Object 默认值【无预约的情况】
		String objVal = SORTAPI_NOLEAD; // 11位长【SEQ最多10位长** 不会冲突 ** 】
		if(!groupAbleFlg){
			if(!ldInfo.titleValMap.containsKey(objVal)) ldInfo.titleValMap.put(objVal, '');
		} else if(grpTitlInfoMap.containsKey(ldIndexNmKey)){
			// 获取 主预约的 排序字段值
			String sortValStr = CommUtils.nullToBlank(getValueByApi(grpTitlInfoMap.get(ldIndexNmKey).lead, sortField));
			// 获取 当前LeadInexName
			String ldIndexNm = CommUtils.nullToBlank(ld.LeadIndexRef__r.Name);
			// 合成 Object
			// 指定した部屋の並び順項目値がNULLの場合、デフォルト値を設定する
			objVal = ( CommUtils.isBlank(sortValStr) ? SORTAPI_DEF_NO : CommUtils.paddingLeftZero(sortValStr, 10) ) + '__' + ldIndexNm;
			// Title行数据信息
			ldInfo.titleValMap.put(objVal, grpTitlInfoMap.get(ldIndexNmKey).grpTitlInfo);
		}
		return objVal;
		// 2017/09/18 予定表を表示のとき、部屋順で表示できる改善対応 WGCH END
	}
	// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH END
	// KEY: ldIndexNm VALUE : title信息(IN THE CLASS)
	public static Map<String, GroupTitleInfo> grpTitlInfoMap {get;set;}
	public static final String LEAD_NAME_PREFIX = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomDelegatePrefix__c);
	private static void getGrpTitlInfoMap (List<Lead__c> ldLst) {
		// JSON情報格納用
		grpTitlInfoMap = new Map<String, GroupTitleInfo>();
		// 合计字段对应合计值Map
		Map<String,Integer> grpAggrMap = new Map<String,Integer>();
		// 親部屋情報格納用マップ
		map<Id, Lead__c> pkLeadMap = new map<Id, Lead__c>();
		// 親部屋情報を判断、取得処理ロジック BEGIN
		// 判断ロジック：ParentFlg__c(親SUBINDEXのフラグ)はTRUEの場合、一番名の予約は親予約情報
		// FLAGがない場合、予約名は共有定義の名前の前方が一致する場合、親予約として認識する
		// 上記でも情報がなかった場合、一番名の予約情報は親予約になる
		// STEP1:予約インデックスSUBのIDから親
		set<Id> subIndexIdSet = new set<Id>();
		set<Id> subIndexParentIdSet = new set<Id>();
		for (Lead__c ld : ldLst) {
			if (CommUtils.isBlank(ld.LeadIndexSubId__c)) continue;
			subIndexIdSet.add(ld.LeadIndexSubId__c);
		}
		if (!subIndexIdSet.isEmpty()) {
			List<LeadIndex__c> leadIndexSubLst = [select id from LeadIndex__c where id in :subIndexIdSet and ParentFlg__c = true];
			for (LeadIndex__c sub : leadIndexSubLst) {
				subIndexParentIdSet.add(sub.Id);
			}
		}
		// 該当予約インデックスに親情報が存在場合、存在の予約IDを格納する
		// map<予約インデックスID,親予約ID>
		map<date,map<Id,Id>> oneGpParntIdMap = new map<date,map<Id,Id>>();
		for (Lead__c ld : ldLst) {
			// 予約インデックス
			Id ldIndexId = ld.LeadIndexRef__c;
			// 親予約判断を行う
			Id subId = ID.valueOf(ld.LeadIndexSubId__c);
			// 到着日
			Date entryDt = ld.EntryTime__c.date();
			// 親SUBINDEXに所属の予約情報の場合
			if (subIndexParentIdSet.contains(subId)) {
				// 該当予約に親予約はまだ設定されてない場合
				if (!oneGpParntIdMap.containsKey(entryDt)) oneGpParntIdMap.put(entryDt, new map<Id,Id>());
				map<Id,Id> parentMap = oneGpParntIdMap.get(entryDt);
				if (!parentMap.containsKey(ldIndexId)) parentMap.put(ldIndexId, ld.Id);
			}
		}
		// 親部屋マークをチェックする
		if (!CommUtils.isBlank(LEAD_NAME_PREFIX)) {
			for (Lead__c ld : ldLst) {
				// 予約インデックス
				Id ldIndexId = ld.LeadIndexRef__c;
				String leadName = ld.name;
				Date entryDt = ld.EntryTime__c.date();
				// 該当日付の親SUBに存在の場合
				if (oneGpParntIdMap.containsKey(entryDt)) {
					map<Id,Id> parentMap = oneGpParntIdMap.get(entryDt);
					if (!parentMap.containsKey(ldIndexId) && leadName.startsWith(LEAD_NAME_PREFIX)) {
						parentMap.put(ldIndexId, ld.Id);
					}
				} 
				// 該当日付の親SUBが非存在の場合
				else {
					// 該当予約
					if (leadName.startsWith(LEAD_NAME_PREFIX)) {
						oneGpParntIdMap.put(entryDt, new map<Id,Id>());
						map<Id,Id> parentMap = oneGpParntIdMap.get(entryDt);
						parentMap.put(ldIndexId, ld.Id);
					}
				}
			}
		}
		// 親部屋に非存在の場合、一番目の予約情報は親予約情報です
		for (Lead__c ld : ldLst) {
			// 予約インデックス
			Id ldIndexId = ld.LeadIndexRef__c;
			//String leadName = ld.name;
			Date entryDt = ld.EntryTime__c.date();
			if (!oneGpParntIdMap.containsKey(entryDt)) {
				map<Id,Id> parentMap = new map<Id,Id>();
				parentMap.put(ldIndexId, ld.Id);
				oneGpParntIdMap.put(entryDt, parentMap);
			} else {
				map<Id,Id> parentMap = oneGpParntIdMap.get(entryDt);
				if (!parentMap.containsKey(ldIndexId)) parentMap.put(ldIndexId, ld.Id);
			}
		}
		// 親部屋情報を判断、取得処理ロジック END
		for (Lead__c ld : ldLst) {
			// 予約インデックスID
			Id ldIndexId = ld.LeadIndexRef__c;
			// 默认顺序的 第一个就是主预约
			if(!CommUtils.isBlank(ldIndexId)){
				// KEY => ldIndexNm -- ld.EntryTime__c
				Date entryDt = ld.EntryTime__c.date();
				//String keyDate = entryDt.format();
				// 該当グループとキー識別キー
				// 2017/09/18 予定表を表示のとき、部屋順で表示できる改善対応 WGCH BEGIN
				String ldIndexNmKey = getLdIndexNmKey(ld);
				// 2017/09/18 予定表を表示のとき、部屋順で表示できる改善対応 WGCH END
				// 該当曜日の親予約のキー格納変数取得
				map<Id,Id> parentMap = oneGpParntIdMap.get(entryDt);
				// 該当グループの合計とタイトル情報格納変数
				// 2017/09/18 カスタマイズ定義のLINKあり項目は自動リンクを付ける対応 WGCH BEGIN
				if (!grpTitlInfoMap.containsKey(ldIndexNmKey)) grpTitlInfoMap.put(ldIndexNmKey, new GroupTitleInfo(0, ld, ldIndexId));
				// 2017/09/18 カスタマイズ定義のLINKあり項目は自動リンクを付ける対応 WGCH END
				GroupTitleInfo grpItem = grpTitlInfoMap.get(ldIndexNmKey);
				// 親フラグを設定する
				Boolean isParentFlg = false;
				if(parentMap != null && parentMap.containsKey(ldIndexId) && parentMap.get(ldIndexId) == ld.Id) isParentFlg = true;
				// 件数集計
				grpItem.grpSize += 1;
				// 拡張ラベル情報を格納する
				for(String api : grpTitlApiLst){
					// XML里设置的API
					// 此API 没有Label 或 无效 跳出 
					if(!grpTitlApiSet.contains(api) || !leadApiLabelMap.containsKey(api)) continue;
					// 用预约IndexNm And API 合成Key
					// 指定項目を合計する
					if (customTypemap.containsKey(api) && grpAggrApiSet.contains(api) && customTypemap.get(api) == 'number'){
						grpItem.addTitleInfo(api, leadApiLabelMap.get(api), CommUtils.nullToIntZero(getValueByApi(ld,api)),true);
					} else {
						// 親予約の場合
						if(isParentFlg) {
							grpItem.addTitleInfo(api, leadApiLabelMap.get(api), CommUtils.nullToBlank(getValueByApi(ld,api)),false);
						}
					}
				}
			} // end if(!CommUtils.isBlank(ldIndexId))
		}
		// ラベル情報作成する
		for(String ldIndexNmKey : grpTitlInfoMap.keySet()){
			// 获取当前ldIndeNm对应的title数据源
			GroupTitleInfo grpItem = grpTitlInfoMap.get(ldIndexNmKey);
			grpItem.grpTitlInfo += '(' + grpItem.grpSize + Label.MSG_041_0057 + ')　　';
			// 对当前的title数据源 进行合成
			for(String api : grpTitlApiLst){
				grpItem.grpTitlInfo += grpItem.getTitleInfo(api);
			}
		}
	}
	// 用预约IndexNm And API 合成Key
	private static String getGrpTitlKey(String ldIndexNmKey,String api){
		return ldIndexNmKey + '__' + api;
	}
	// 用预约IndexNm And EntryTime__c 合成Key
	private static String getLdIndexNmKey(Lead__c ld){
		// KEY => ldIndexNm -- ld.EntryTime__c
		String keyDate = ld.EntryTime__c == null ? '' : ld.EntryTime__c.format(CONST_DATEFORMAT);
		return CommUtils.nullToBlank(ld.LeadIndexRef__r.Name) + '__' + keyDate;
	}
	// 主预约数据源
	public class TiltleVal{
			public TiltleVal(String api,String label,Object val){
				this.api = api;
				this.label = CommUtils.nullToBlank(label);
				this.value = CommUtils.nullToBlank(val);
			}
			// 字段
			private String api;
			// XML 定义的 Label
			private String label;
			// api 对应的数据
			private String value;
			// 合成Str
			public String getItemInfo(){
				// 2017/09/18 カスタマイズ定義のLINKあり項目は自動リンクを付ける対応 WSQ BEGIN
				if(CommUtils.isBlank(value)) return '';
				return (label + ':　' + value + '　').escapeHtml4();
				// 2017/09/18 カスタマイズ定義のLINKあり項目は自動リンクを付ける対応 WSQ END
			}
	}
	public class GroupTitleInfo{
		// 2017/09/18 カスタマイズ定義のLINKあり項目は自動リンクを付ける対応 WGCH BEGIN
		public GroupTitleInfo(Integer grpSize,Lead__c lead,String ldIndexId){
			// 2017/09/18 カスタマイズ定義のLINKあり項目は自動リンクを付ける対応 WGCH END
			this.grpSize = grpSize;
			// 2017/09/18 カスタマイズ定義のLINKあり項目は自動リンクを付ける対応 WGCH BEGIN
			this.lead = lead;
			// 2017/09/18 カスタマイズ定義のLINKあり項目は自動リンクを付ける対応 WGCH END
			this.ldIndexId = ldIndexId;
			ldIndexId = grpTitlInfo = '';
			titleMap = new map<String, TiltleVal>();
		}
		// 每个group id
		private String ldIndexId;
		// 每个group Item size
		private Integer grpSize;
		// 2017/09/18 カスタマイズ定義のLINKあり項目は自動リンクを付ける対応 WGCH BEGIN
		transient private Lead__c lead;
		// 2017/09/18 カスタマイズ定義のLINKあり項目は自動リンクを付ける対応 WGCH END
		// 每个group Title 行的信息 
		public String grpTitlInfo {get;set;}
		// 每个group Title 行的API集计信息 
		transient private map<String, TiltleVal> titleMap;
		public void addTitleInfo (String api, String label, Object val, Boolean isSumFlg) {
			if (!titleMap.containsKey(api)) {
				if (isSumFlg) {
					titleMap.put(api, new TiltleVal(api, label, 0));
				} else {
					titleMap.put(api, new TiltleVal(api, label, val));
				}
			}
			if (isSumFlg) {
				TiltleVal s = titleMap.get(api);
				s.value = CommUtils.nullToBlank(CommUtils.nullToZero(s.value) + CommUtils.nullToZero(val));
			}
		}
		public String getTitleInfo(String api) {
			if (!titleMap.containsKey(api)) return '';
			if (CommUtils.isBlank(titleMap.get(api).value)) return '';
			// 2017/09/18 カスタマイズ定義のLINKあり項目は自動リンクを付ける対応 WGCH BEGIN
			return titleMap.get(api).getItemInfo();
			// 2017/09/18 カスタマイズ定義のLINKあり項目は自動リンクを付ける対応 WGCH END
		}
	}
	/** 予約情報はＪＳＯＮに転換を行う
	* 注：予約から参照項目を表示したい場合、最大２階層まで対応できる
	**/
	private static final String RELATION_KEY = '__r.';
	// 参照字段对应
	private static Object getValueByApi(Sobject s ,String field) {
		// 2017/09/18 カスタマイズ定義のLINKあり項目は自動リンクを付ける対応 WGCH BEGIN
		if (s == null) return '';
		// 2017/09/18 カスタマイズ定義のLINKあり項目は自動リンクを付ける対応 WGCH END
		String apiField = field.trim();
		// 2017/06/06 XMLのAPI定義小文字、大文字区別されない対応 BEGIN
		if (apiField.containsIgnoreCase(RELATION_KEY)) {
			// aaa__r.xxxx
			Integer startPt = apiField.indexOfIgnoreCase(RELATION_KEY) + RELATION_KEY.length();
			String refFieldNm = apiField.substring(startPt);
			// 一階層のSOBJECT名
			// ssss__r
			String refSobjNm = apiField.substringBefore('.');
			// 二階層のSOBJECT[aaa__r.xxxx]
			if (refFieldNm.containsIgnoreCase(RELATION_KEY)) {
				// 一階層のSOBJECT取得する[ssss__r]
				Sobject refSobj = s.getSObject(refSobjNm);
				if (refSobj == null) {
					return null;
				}
				// 二階層の参照関係存在する場合、二階層以上は対応しません
				Integer twoStartPt = refFieldNm.indexOfIgnoreCase(RELATION_KEY) + RELATION_KEY.length();
				String twoRefFieldNm = refFieldNm.substring(twoStartPt);
				// Sobject Name [aaa__r]
				String twoRefSobjNm = refFieldNm.substringBefore('.');
				// Two Level Field
				Sobject twoRefSobj = refSobj.getSObject(twoRefSobjNm);
				// JSONに情報を書込する
				if (twoRefSobj == null) return null;
				else {
					Object val = twoRefSobj.get(twoRefFieldNm);
					return val;
				}
			} else {
				Sobject refSobj = s.getSObject(refSobjNm);
				if (refSobj == null) return null;
				else {
					Object val = refSobj.get(refFieldNm);
					return val;
				}
			}
		} else {
			Object val = s.get(apiField);
			return val;
		}
	}
	// 2017/09/18 跨月份日期排序BUG修改对应
	private static final String CONST_DATEFORMAT = 'yyyy/MM/dd';
	// 予定表を表示のとき、部屋順で表示できる改善対応
	public static String SORTAPI_NOLEAD{get{return '99999999999';}}
	public static String SORTAPI_DEF_NO{get{return '99999999998';}}
	// 2017/10/27 GROUP功能对应 WGCH END
	// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
	// 单价显示模式转换处理
	public static String getUnitPrice(BookingEstimateItem__c s){
		try {
			// 2019/06/28 「サ抜税込」「サ抜税抜」の選択肢対応 WGCH BEGIN
			/*
			if(s.Id == null) {
				if(mode == '1') return CommUtils.isBlank(s.X3_2__c) ? '' : Commutils.nullToZero(s.X3_2__c).format();
				else if(mode == '2') return CommUtils.isBlank(s.X4_3__c) ? '' : Commutils.nullToZero(s.X4_3__c).format();
			} else{
				if(mode == '1') return s.Tankanonetax__c == null ? '' : s.Tankanonetax__c.format();
				else if(mode == '2') return s.unitPriceIncTaxCal__c == null ? '' : s.unitPriceIncTaxCal__c.format();
			}
			*/
			CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(s.UnitPriceDefKb__c));
			Decimal unitPrice = CommUtils.nullToZero(s.UnitPrice__c);
			Decimal qty = CommUtils.nullToZero(s.Amount__c);
			Decimal taxRate = CommUtils.nullToZero(s.TaxRate__c);
			Decimal serviceRate = CommUtils.nullToZero(s.ServiceRate__c);
			priceInfo.process(unitPrice, qty , taxRate, serviceRate);
			/*
			1: 見積明細・会計明細の単価[税抜き]				unitPriceExcTax
			2: 見積明細・会計明細の単価[税込]				unitPriceTax
			3: 見積明細・会計明細の単価[税抜、サビース料込]		unitPriceIncServiceExcTax
			4: 見積明細・会計明細の単価[税込、サービス料抜き]	unitPriceIncTax
			
			priceExcTax			 // 合計税抜、サービス料抜き
			priceIncTax			 // 合計税込、サービス料込
			priceServiceExcTax	 // 合計サービス料(税抜)
			priceService		 // 合計サービス料(税込)
	    	
			unitPriceIncServiceExcTax // 単価税抜、サービス料込
			unitPriceTax			  // 単価税込、サービス料込
			unitPriceExcService		  // 単価サービス料(税抜)
			unitPriceIncService		  // 単価サービス料(税込)
			*/
			// 単価: サービス料込(消費税)
			// 2019/07/30 MODE1、4BUG修正 WGCH BEGIN
			// Decimal priceServiceTax = priceInfo.unitPriceIncService - priceInfo.unitPriceExcService;
			// if(mode == '1') return (priceInfo.unitPriceIncServiceExcTax - priceServiceTax).format();
			if(mode == '1') return (priceInfo.unitPriceExcTax).format();
			// 2019/07/30 MODE1、4BUG修正 WGCH END
			else if(mode == '2') return (priceInfo.unitPriceTax).format();
			else if(mode == '3') return (priceInfo.unitPriceIncServiceExcTax).format();
			// 2019/07/30 MODE1、4BUG修正 WGCH BEGIN
			// else if(mode == '4') return (priceInfo.unitPriceTax - priceServiceTax).format();
			else if(mode == '4') return (priceInfo.unitPriceIncTax).format();
			// 2019/07/30 MODE1、4BUG修正 WGCH END
			// 2019/06/28 「サ抜税込」「サ抜税抜」の選択肢対応 WGCH END
		} catch (Exception e) {}
		// 默认商品单价
		return s.refAccountMaster__r.Field5__c == null ? '' : s.refAccountMaster__r.Field5__c.format();
	}
	// 预约Id_商品Id
	public static String getPlanItemKey(String leadId, String accMasterId){
		return CommUtils.nullToBlank(leadId) + '_' + CommUtils.nullToBlank(accMasterId);
	}
	// 商品code_商品Id
	public static String getMoringFoodKey(String foodCd, String unitPrice){
		return CommUtils.nullToBlank(foodCd) + getUnitPriceKey(unitPrice);
	}
	// 日期_商品code_单价
	public static String getMoringFoodDetailKey(String strKeyDate, String moringFoodKey){
		return CommUtils.nullToBlank(strKeyDate) + '_' + CommUtils.nullToBlank(moringFoodKey);
	}
	// _单价key
	public static String getUnitPriceKey(String unitPrice){
		return unitpriceColShow ? ('_' + getUnitPricePaddingLeft(unitPrice)) : '';
	}
	// 单价补位处理为了排序
	public static String getUnitPricePaddingLeft(String unitPrice){
		return CommUtils.paddingLeftZero(CommUtils.nullToBlank(unitPrice).replace(',',''), 10);
	}
	// 设置日期对应的料理key
	public static void setKeyDateStrMap(Date keyDate, String moringFoodDetailKey){
		if(!keyDateStrMap.containsKey(keyDate)) keyDateStrMap.put(keyDate, new List<String>());
		List<String> moringFoodDetailKeyLst = keyDateStrMap.get(keyDate);
		if(!moringFoodDetailKeyLst.contains(moringFoodDetailKey)) moringFoodDetailKeyLst.add(moringFoodDetailKey);
	}
	// 日期=>KEY
	private static String getStrKeyDate(Date keyDate){
		return dateTime.newinstance(keyDate.year(),keyDate.month(),keyDate.day()).format(CONST_DATEFORMAT);
	}
	// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
	// 2019/06/28 ユーザ側で非表示にした項目対応 WGCH BEGIN
	public static Boolean isBatchRunFlg;
	public static Boolean pdfNoHiddenColnumFlg{get{ if(pdfNoHiddenColnumFlg == null) pdfNoHiddenColnumFlg = false; return pdfNoHiddenColnumFlg;} private set;}
	public static String userId{get{ return UserInfo.getUserId();} private set;} // UserId
	private static Set<String> customHidFields = new Set<String>(); // 画面に非表示（選択可能）項目リストを定義する
	// Cookie情報処理追加
	private static CookieInf getCookieInf (String pShopCode) {
		CookieInf inf = new CookieInf();
		if(pdfNoHiddenColnumFlg || isBatchRunFlg) return inf;
		// DBから設定情報を取得する
		map<string,string> userConfigMap = UserConfigCompCtrl.getKrepConfig(userId, pShopCode);
		String configResizeKey = UserConfigCompCtrl.KREP_SUBTYPE.RESIZE.name();
		String configResizeVal = '';
		if (userConfigMap.containsKey(configResizeKey)) {
			configResizeVal = userConfigMap.get(configResizeKey);
		} else {
			// Remote Action Call Return
			if (ApexPages.currentPage() == null) return inf;
	 		Cookie theCookie = ApexPages.currentPage().getCookies().get(pShopCode + '_K_ScheduleReport_ColResize');
			if (theCookie != null) {
				configResizeVal = CommUtils.nullToBlank(theCookie.getValue());
			}
		}
		List<String> colResizeLst = configResizeVal.split(',');
		for (String colSizeDef : colResizeLst) {
			List<String> defInf = colSizeDef.split(':');
			if (defInf.size() < 2) continue;
			// Relation参照項目定義内容変換する: __r_ -> __R.
			String api = defInf[0].replace('__r_',RELATION_KEY);
			inf.colnumSizeMap.put(api,defInf[1]);
		}
		// 2017/09/23 列表示・非表示自動記憶機能対応 WGCH BEGIN
		String configColHidKey = UserConfigCompCtrl.KREP_SUBTYPE.HIDCOL.name();
		String configColHidVal = '';
		if (userConfigMap.containsKey(configColHidKey)) {
			configColHidVal = userConfigMap.get(configColHidKey); 
		} else {
			Cookie theCookie = ApexPages.currentPage().getCookies().get(userId + pShopCode + '_K_ScheduleReport_ColumnHidFlg');
			if (theCookie != null) {
				configColHidVal = CommUtils.nullToBlank(theCookie.getValue());
			}  
		}
		List<String> colHidLst = configColHidVal.split(',');
		for (String colHidDef : colHidLst) {
			List<String> defInf = colHidDef.split(':');
			if (defInf.size() < 2) continue;
			// Relation参照項目定義内容変換する: __r_ -> __R.
			String api = defInf[0].replace('__r_',RELATION_KEY);
			inf.colnumHidMap.put(api,Boolean.valueOf(defInf[1]));
		}
		// 2017/09/23 列表示・非表示自動記憶機能対応 WGCH END
		return inf;
	}
	public class CookieInf {
		public map<string,string> colnumSizeMap{get; set;}
		// 2017/09/23 列表示・非表示自動記憶機能対応 WGCH BEGIN
		public map<string,Boolean> colnumHidMap{get; set;}
		// 2017/09/23 列表示・非表示自動記憶機能対応 WGCH END
		public CookieInf(){
			colnumSizeMap = new map<string,string>();
			// 2017/09/23 列表示・非表示自動記憶機能対応 WGCH BEGIN
			colnumHidMap = new map<string,boolean>();
			// 2017/09/23 列表示・非表示自動記憶機能対応 WGCH END
		}
	}
	// 2019/06/28 ユーザ側で非表示にした項目対応 WGCH END
	// 2019/08/15 予定表の部屋タイプ絞り込みは予定表内のフィルター機能が改善ほしい by zy BEGIN
	private set<String> typeSet = new Set<String>();
	// 2019/08/15 予定表の部屋タイプ絞り込みは予定表内のフィルター機能が改善ほしい by zy END
	// 2019/08/15 予定表上にも、ルームインジケータのような検索欄が欲しい by zy BEGIN
	private String filterStr = '';
	// 2019/08/15 予定表上にも、ルームインジケータのような検索欄が欲しい by zy END
	// 2021/05/31 予定表のレイアウトを複数パターンから切り替えられるようにしたいユーザ単位で保存できるように by zy BEGIN
	private String pLayoutId;
	private String pRoomIds;
	// 2021/05/31 予定表のレイアウトを複数パターンから切り替えられるようにしたいユーザ単位で保存できるように by zy END
}