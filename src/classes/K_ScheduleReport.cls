/**
* 予定表
* 2013/10/22 会計明細統計情報を追加する
* 2013/11/05 部屋未割り当てるの予約の料理も集計対象になる
* 2013/11/20 料理情報を表示列設定制御機能追加
* 2013/11/23 ブライダル別に料理集計できることもパラメータにて切り替えられる対応
* 2014/03/31 料理項目表示順切り替え対応(Ver4.28)
* 2014/05/06 予定表週間集計表示機能
* 2014/07/10 予約アサインのみ部屋・すべて部屋表示切替
* 2014/08/15 予約履歴機能を追加
* 2014/09/24 予定表の部屋ごとの料理の数量の小数点00サプレス対応
* 2015/01/12 予定表料金集計の列のカスタマイズできる機能対応
* 2015/09/01 多店舗機能対応
* 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応
* 2016/01/28 インターバルタイマ定義は定義XMLに指定可能の対応
* 2017/03/13 予定表の変更履歴が色でわかるように、色も一色ではなくN色自動対応
* 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応
* 2018/02/22 会計OP単位で料理表示できるように改善対応
* 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善
* 2018/10/15 料理集計に合計の表記がございますが機能対応
* 2019/04/30 料理項目列のタイトルを表示・非表示切り替えフラグ
* 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応
* 2019/05/15 料理集計「単泊」の料理数は「連泊の１泊目」に合計する機能対応
* 2019/05/15 予定表指定日にて、連絡事項を表示する機能対応
* 2019/06/14 「料理」列に「会計OP」を表示したい对应
* 2019/06/14 フィルターを各アカウント毎に保持できる様にして欲しい対応
* 2019/06/14 予定表の表示期間対応
* 2019/06/28 「サ抜税込」「サ抜税抜」の選択肢対応
* 2020/02/28 同伴者情報列位置自定义改善对应
* 2021/05/31 予定表のレイアウトを複数パターンから切り替えられるようにしたいユーザ単位で保存できるように
* 2021/05/31 部屋タイプでの絞り込みと追加で部屋でも絞り込めるようにし、 ユーザ単位で保存できるように
**/
public with sharing class K_ScheduleReport {
	// ご予約へ編集権限あり、なし
	public boolean isCanUpdateLead{get{return CommSecurityUtils.isCanUpdateLead();}}
	// タイムテーブル情報を定義する
	public BookingTimeTable__c timeTable{get;set;}
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
	private static final String queryConstLeadStr = 'LeadIndexRef__c,LeadIndexRef__r.Name,LeadIndexSubId__c,EntryTime__c,Field298__c, Rroom__c, Id, Name, Field353__c,Field291__c,Field4__c,Field278__c,DayNightCal__c,Check369__c,Morningtime__c,Morimongn__c,Field277__c,Field300__c,Field281__c,Field302__c,StayPersons__c,Mans__c,Femails__c,ChildFA__c,Childs__c,ReservedType__c,Field293__c,Field303__c,Field306__c,Field354__c,Field301__c,Comment3__c  ';
	
	// 画像数式処理用Pattern
	private static final Pattern pTool = Pattern.compile('.*src=["](/resource.*?)["].*');
	// 処理がどうか判別用情報を格納用リスト
	private static List<String> filterOpList = new List<String>();//{'会席','お膳','単品','仕出し','朝食'};
	// 2013/10/30 透か度取得
	public Boolean WatermarkRate{get{return CommDefine__c.getOrgDefaults().WatermarkRate__c == null ? false : CommDefine__c.getOrgDefaults().WatermarkRate__c;}}
	// 朝食の商品コード
	private static final String CONST_OTHER_CD = 'A_';
	// 2017/04/27 料理数目变更之后变颜色对应 WGCH BEGIN
	//private static final String CONST_MON_FOOD_CD = 'Z_' + CommUtils.getRandom(6);
	private static final String CONST_MON_FOOD_CD = 'Z_ZZZZZZ';
	// 2017/04/27 料理数目变更之后变颜色对应 WGCH END
	// 2017/09/18 跨月份日期排序BUG修改对应 WGCH BEGIN
	private static final String CONST_DATEFORMAT = 'yyyy/MM/dd';
	// 2017/09/18 跨月份日期排序BUG修改对应 WGCH END
	// チェックイン後の予約データの料理集計は分けるがどうか判別する
	private static Boolean cookInfoSplitShow = CommDefine__c.getOrgDefaults().ReportKScheduleCookInfoDiv__c == null ? false : CommDefine__c.getOrgDefaults().ReportKScheduleCookInfoDiv__c;
	// 予定表料理項目商品並べ順表示方式
	private static final String cookFieldSortDiv = CommDefine__c.getOrgDefaults().ReportKScheduleCookFieldSortDiv__c == null ? '1' : CommDefine__c.getOrgDefaults().ReportKScheduleCookFieldSortDiv__c;
	public boolean getCookInfoSplitShow() {
		return cookInfoSplitShow;
	}
	public static String editColumStr{get;set;}
	public static String jsonColumType{get;set;}
	public integer splitLen{get;set;}
	public String timeZoneMiliseconds{get;set;}
	public String reportMode{get;set;}
	public static Map<Id, LeadHistories.LeadHistoryItem> historyMap;
	// 2015/01/12 予定表料金Window定義情報格納変数
	public transient static FoodSummarySetupInfo foodSummaryInfo{get; private set;}
	// 料理集計種別コード取得する
	private static String cookingSummyCode = CommDefine__c.getOrgDefaults().ReportKScheduleCookInfoCode__c == null ? '1' : CommDefine__c.getOrgDefaults().ReportKScheduleCookInfoCode__c;

	/* ログインユーザーの支店コード */
	private static String userShopCode;
	// 2015/09/01 多店舗機能対応 BEGIN
	private static UserUtil.UserShopInfo userInf;
	// 2015/09/01 多店舗機能対応 END
	/* 部屋リスト情報を格納する */
	private static List<Room__c> roomList;
	/** 朝食判断用会計ＯＰのID */
	private static Set<Id> moringFoodOpIdSet = new Set<Id>();
	
	/** 予約から自定義表示予定の項目リスト */
	private static list<String> customApiFields = new list<String>();					// XMLにカスタム項目配列を格納する<API FIELD>
	private static map<String, String> customLabelMap = new map<String, String>();		// カスタム表示する項目のラベル名を定義する<JSONKEY, LABEL>
	private static map<String, String> customLinkMap = new map<String, String>();		// カスタム項目に、リンク追加の項目を定義される情報を格納する<API FIELD, SF ID>
	private static map<String, Schema.DescribeFieldResult> modelDeafaultValuesMap;
	private static Set<String> customAggregateFields = new Set<String>();				// XMLに合計項目のＡＰＩ格納する
	private static Set<String> customHidFields = new Set<String>();						// 画面に非表示（選択可能）項目リストを定義する
	private static map<String, String> customWidthMap = new map<String, String>();  	// 画面項目のサイズを指定する
	private static map<String, String> customStyleMap = new map<String, String>();		// 画面項目のSTYLE定義情報
	private static map<String, String> customTypemap = new map<String, String>();		// 画面項目文字列以外の項目のタイプを設定する
	private static Set<String> customEditSet = new Set<String>();		// 画面項目のEDIT情報
	private static Set<String> jsonDataFields = new Set<String>();						// 画面へ表示用データを作成するＪＳＯＮの項目リスト(画面表示用の項目は全部該当リストに格納するが必要)
																						// 該当変数はＱＵＥＲＹ検索結果からＪＳＯＮに変換する場合が使う
	private static Boolean isShowFoodInfo;												// 料理情報を表示・非表示設定する
	private static Decimal isShowFoodPosition;											// 料理項目表示場所格納
	private static String  isShowFoodStyle;												// 料理項目表示STYLE情報格納
	private static String  isShowFoodWidth;												// 料理項目表示の横幅設定情報格納
	private static Boolean isNoShowFoodHeader;											// 料理項目列のタイトルを表示・非表示切り替えフラグ[2019.04.30追加]
	private static Boolean optionsAssignRoomOnlyShowFlg;								// OPTIONS：割り当て部屋のみ表示フラグ
	// 2017/03/13 予定表の変更履歴が色でわかるように、色も一色ではなくN色自動対応 BEGIN
	private static Map<String ,Map<String,HistoryColor>> colorJsonMap = new map<String ,Map<String,HistoryColor>>();
	private static Map<String,HistorySetupInfo> colorMap;
	private static Boolean bgColorFlg;
	// 2017/04/27 料理数目变更之后变颜色对应 WGCH BEGIN
	// 每行料理数量变更==>>是否显示颜色Flg
	private static Boolean detailIsShowFlg;
	public static Boolean isFoodSumColor;
	// 料理数量变更==>>显示的颜色
	private static String foodSumColor;
	// 2017/04/27 料理数目变更之后变颜色对应 WGCH END
	// 2017/03/13 予定表の変更履歴が色でわかるように、色も一色ではなくN色自動対応 END
	/** 予約情報を取得用ＳＱＬ */
	private static String queryLeadStr;
	//public static Boolean isShowCommand{get;set;} 
	// 2014/05/08 指定日からXX日間変数可能
	public String termDates{get; set;}
	// 2014/06/26 部屋表示ステータス切り替え制御
	public static String intervalTime{get; private set;}								// XMLからインターバルタイマ定義情報を取得、格納する
	//public Boolean getIsAssignRoomOnlyShow(){return optionsAssignRoomOnlyShowFlg;}	// 割り当て部屋のみ表示制御フラグ
	public List<Selectoption> roomViewLst{get{
		List<Selectoption> rs = new List<Selectoption>();
		//アサイン部屋表示
		rs.add(new Selectoption('true',Label.CONST_041_0035));
		//全部屋表示
		rs.add(new Selectoption('false',Label.CONST_041_0036));
		return rs;
	}} 
	public String roomViewFlg{get{
		return (CommUtils.isBlank(roomViewFlg) ? String.valueOF(optionsAssignRoomOnlyShowFlg) : roomViewFlg); 
	} set;}//true/false
	// 2019/06/14 予定表の表示期間対応 WGCH BEGIN
	// 对应SF内部处理BUG
	public String oldTermDates{get{
		if(oldTermDates == null) return '';
		return oldTermDates;
	} set;}
	public static List<Selectoption> termDatesLst{get{
		if(termDatesLst == null) return getTermDatesSoption(7);
		return termDatesLst;
	}}
	public static List<Selectoption> getTermDatesSoption(Integer termDatesSize){
		List<Selectoption> rs = new List<Selectoption>();
		if(termDatesSize == null) return rs;
		for(Integer i = 0; i < termDatesSize; i++ ){
			String termDateStr = CommUtils.nullToBlank(i + 1);
			// から定義情報设定
			rs.add(new Selectoption(termDateStr, termDateStr));
		}
		return rs;
	}
	// 2019/06/14 予定表の表示期間対応 WGCH END
	// 2017/09/18 予定表に表示したく無い部屋のSEQ#をカンマで複数定義するに改善対応 WGCH BEGIN
	private static Set<Decimal> noRmSeqSet = new Set<Decimal>();		 // 不显示的Room SeqSet
	// 2017/09/18 予定表に表示したく無い部屋のSEQ#をカンマで複数定義するに改善対応 WGCH END
	// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH BEGIN
	private static Set<String>  grpTitlApiSet = new Set<String>();		// GROUPABLE XML设置的 ApiSet
	private static List<String> grpTitlApiLst = new List<String>();	  // GROUPABLE XML设置的 ApiList
	private static Set<String>  grpAggrApiSet = new Set<String>();		// GROUPABLE XML设置的 集计ApiSet
	// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH BEGIN
	public static Boolean isShowGuestInfo{get;set;}
	private static String guestTitle;
	private static Map<String, String> guestLabelMap = new Map<String, String>();		// GUESTYADOINFO XML设置的 guestLabelMap
	private static List<String> guestApiLst = new List<String>();						// GUESTYADOINFO XML设置的 ApiList
	// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH END
	// 2020/02/28 同伴者情報列位置自定义改善对应 WGCH BEGIN
	private static Boolean isShowGuestPositionFlg;
	private static Decimal isShowGuestPosition;											// 同伴者情報表示場所格納
	// 2020/02/28 同伴者情報列位置自定义改善对应 WGCH END
	// 2017/09/18 予定表を表示のとき、部屋順で表示できる改善対応 WGCH BEGIN
	private static String sortField;									 // GROUPABLE XML设置的 根据部屋字段排序
	// 2017/09/18 予定表を表示のとき、部屋順で表示できる改善対応 WGCH END
	public static Boolean groupAbleFlg{get; set;}						// GROUPABLE 功能FLG TRUE:有效;FALSE:无效;
	public static Boolean xmlGroupAbleFlg{get;private set;}			  	// XMLタグ「GROUPABLE」定義されているがどうか情報格納
	public static Boolean collapseGroupFlg{get; set;}					// GROUPABLE初始化展开效果 功能FLG TRUE:收起; FALSE:展开;
	// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
	public static Boolean foodGroupAbleFlg{get; set;}					// FOODGROUPABLE初始化展开效果 功能FLG TRUE:料理Group有效; FALSE:料理Group无效;
	public static Map<String, String> opInfoMap = new Map<String, String>();
	// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
	// 2018/10/15 料理集計に合計の表記がございますが機能対応 WGCH BEGIN
	public static Boolean foodSumIsShowProdFlg{get; set;}
	public static Boolean foodSumIsShowFlg{get; set;}
	// 2018/10/15 料理集計に合計の表記がございますが機能対応 WGCH END
	// 2017/09/27 同一个电脑,不同USER_COOKIE对应 WGCH BEGIN
	public static String userId{get{ return UserInfo.getUserId();} private set;} // UserId
	// 2017/09/27 同一个电脑,不同USER_COOKIE对应 WGCH END
	// 2018/02/05 手書き zyz BEGIN
	// user的KEY
	public static String userStr{get;private set;}
	public static String canvasMode{get;private set;}
	public static Boolean xmlExportFlg{get;private set;}
	public static integer maxHeight{get;set;}
	// 手写功能关闭
	private final static String CANVAS_OFF = '0';
	// 一次直接出力
	private final static String CANVAS_ONE = '1';
	// 多次手写重复替换
	private final static String CANVAS_REA = '2';
	// 2018/02/05 手書き zyz END
	// 2017/09/18 一回のみ切替すると、常に維持する対応 WGCH BEGIN
	public List<Selectoption> groupAbleLst{get{
		List<Selectoption> rs = new List<Selectoption>();
		//アサイン部屋表示
		rs.add(new Selectoption('true',Label.CONST_041_0039_01));
		//全部屋表示
		rs.add(new Selectoption('false',Label.CONST_041_0039_02));
		return rs;
	}}
	// 2017/09/18 一回のみ切替すると、常に維持する対応 WGCH END
	// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH END
	// 2018/02/02 予定表とタイムテーブルの並びを変えたい WGCH BEGIN
	private static Set<String> xmlSqlFieldsSet = new Set<String>();
	// 2018/02/02 予定表とタイムテーブルの並びを変えたい WGCH END
	// 2019/02/28 「前日」「今日」「翌日」ボタンをつけることは改善対応 WGCH BEGIN
	public static Boolean dayButtonShow{get;private set;}
	// 2019/02/28 「前日」「今日」「翌日」ボタンをつけることは改善対応 WGCH END
	// 2019/06/14 「料理」列に「会計OP」を表示したい对应 WGCH BEGIN
	public static String opLabel{get { if(CommUtils.isBlank(opLabel)) opLabel = 'OP'; return opLabel;} private set;}
	public static Boolean opColIsShowFlg{get { if(opColIsShowFlg == null) opColIsShowFlg = false; return opColIsShowFlg;} private set;}
	// 2019/06/14 「料理」列に「会計OP」を表示したい对应 WGCH END
	// 2019/09/15 指定日自动记忆機能対応 WGCH BEGIN
	public Boolean isChkInDayFlg{get{ return CommConst.USERCONFIG_CHECKINDAY_FLG;} set;}
	// 2019/09/15 指定日自动记忆機能対応 WGCH END
	public Pagereference gotoSwitchShop () {
		// 2019/06/14 予定表の表示期間対応 WGCH BEGIN
		// 对应SF内部处理BUG
		termDates = oldTermDates;
		// 2019/06/14 予定表の表示期間対応 WGCH END
		// 2017/09/18 一回のみ切替すると、常に維持する対応 WGCH BEGIN
		String url = '/apex/K_ScheduleReport?sp='+CommUtils.nullToBlank(branchShopNm) + '&qt='+timeTable.Checkinday__c.format() + '&term='+termDates + '&rvflg='+roomViewFlg;
		if (groupAbleFlg != null) url+= ('&gpflg=' + groupAbleFlg);
		Pagereference pg = new PageReference(url);
		// 2017/09/18 一回のみ切替すると、常に維持する対応 WGCH END
		pg.setRedirect(true);
		return pg;
	}
	// 2021/05/31 予定表のレイアウトを複数パターンから切り替えられるようにしたいユーザ単位で保存できるように by zy BEGIN
	public Pagereference changeLayout () {
		// 2019/06/14 予定表の表示期間対応 WGCH BEGIN
		// 对应SF内部处理BUG
		termDates = oldTermDates;
		// 2019/06/14 予定表の表示期間対応 WGCH END
		// 2017/09/18 一回のみ切替すると、常に維持する対応 WGCH BEGIN
		String url = '/apex/K_ScheduleReport?sp='+CommUtils.nullToBlank(branchShopNm) + '&qt='+timeTable.Checkinday__c.format() + '&term='+termDates + '&rvflg='+roomViewFlg;
		if (groupAbleFlg != null) url+= ('&gpflg=' + groupAbleFlg);
		// 2021/05/31 予定表のレイアウトを複数パターンから切り替えられるようにしたいユーザ単位で保存できるように by zy BEGIN
		url += '&layout=' + currLayoutId;
		// 2021/05/31 予定表のレイアウトを複数パターンから切り替えられるようにしたいユーザ単位で保存できるように by zy END
		Pagereference pg = new PageReference(url);
		// 2017/09/18 一回のみ切替すると、常に維持する対応 WGCH END
		pg.setRedirect(true);
		return pg;
	}
	// 2021/05/31 予定表のレイアウトを複数パターンから切り替えられるようにしたいユーザ単位で保存できるように by zy END
	static {
		// 2017/09/18 予定表に表示したく無い部屋のSEQ#をカンマで複数定義するに改善対応 WGCH BEGIN
		/*
		// 部屋リストを取得する
		roomList = getRoomList();
		*/
		// 2017/09/18 予定表に表示したく無い部屋のSEQ#をカンマで複数定義するに改善対応 WGCH END
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
		// 2015/09/01 多店舗機能対応 BEGIN
		userInf = UserUtil.CurrentUserInfo;
		userShopCode = userInf.defaultShopCode;
		// 2015/09/01 多店舗機能対応 END
		/*
		// -------------------------------------
		// カスタム項目設定情報処理
		// -------------------------------------
		// カスタム表示用項目を取得する
		Set<String> leadSqlFieldsSet = new Set<String>();
		// カスタム表示用項目を初期化する
		List<String> fieldsSplits = parseFieldsXml().split(',');
		// ＬＩＮＫ参照項目関連追加する
		for (String key : customLinkMap.keySet()) {
			// ＸＭＬに設定したＬＩＮＫ項目リストは追加する
			jsonDataFields.add(key);
			jsonDataFields.add(customLinkMap.get(key));
		}

		// XMLに定義された表示項目リスト取得、処理を行う
		for (String item : fieldsSplits) {
			String[] keySplits = item.split(':');
			if (keySplits.size() != 2) {
				Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
				  '表示項目書式の設定が不正です[API名:項目ラベル]'));
				break;
			}
			String key = keySplits[0];
			String disKey = converDisFields(key);
			String lab =  keySplits[1];
			// ＸＭＬに設定した項目リストは追加する
			jsonDataFields.add(key);
			// API名を格納する
			customApiFields.add(key);
			// 表示ラベルを定義する
			customLabelMap.put(disKey,  lab);
		}
		
		// リンクする項目関連設定はSQLから検索必要の項目情報に格納する
		leadSqlFieldsSet.addAll(jsonDataFields);

		// 既存固定定義している予約検索のＳＱＬを取得する
		queryLeadStr = queryConstLeadStr + ',' + queryRoomStr;
		// 固定定義されている項目リストを取得する
		String[] constLeadFields = queryLeadStr.deleteWhitespace().split(',');
		// カスタム項目をＳＱＬへ追加する
		for (String field : constLeadFields) {
			String key = field;
			// 該当項目が既に存在する場合、
			leadSqlFieldsSet.remove(key);
		}
		// カスタム項目は存在する場合、ＳＱＬに追加する
		for (String apiName : leadSqlFieldsSet) {
			queryLeadStr += ',' + apiName;
		}
		// 表示するデータ項目情報を作成する
		// GRIDのCOLNUM定義属性作成する
		genShowFieldsColnumJson();
		genAvgColInfoPoint();
		genModelJson();
		*/
	}
	private static String converDisFields(String s) {
		return s.replace('.','_');
	}
	
	private static String getSearchShopCode(String pShopCode) {
		return (pShopCode == null ? userShopCode : pShopCode );
	}
	// param:isInitCall(画面初期化処理するがどうか識別フラグ)
	private static void xmlConfigProcess(String pShopCode, Boolean isInitCall) {
		// -------------------------------------
		// カスタム項目設定情報処理
		// -------------------------------------
		// カスタム表示用項目を取得する
		Set<String> leadSqlFieldsSet = new Set<String>();
		// カスタム表示用項目を初期化する
		// 2017/04/27 初期化以外の場合、GRID定義情報JSONは重複処理しない改善 BEGIN
		List<String> fieldsSplits = parseFieldsXml(pShopCode, isInitCall).split(',');
		// 2017/04/27 初期化以外の場合、GRID定義情報JSONは重複処理しない改善 END
		// 2017/09/18 予定表に表示したく無い部屋のSEQ#をカンマで複数定義するに改善対応 WGCH BEGIN
		// 2018/02/02 予定表とタイムテーブルの並びを変えたい WGCH BEGIN
		// 部屋リストを取得する
		// if (!isInitCall) roomList = getRoomList();
		// 2018/02/02 予定表とタイムテーブルの並びを変えたい WGCH END
		// 2017/09/18 予定表に表示したく無い部屋のSEQ#をカンマで複数定義するに改善対応 WGCH END
		// ＬＩＮＫ参照項目関連追加する
		for (String key : customLinkMap.keySet()) {
			// ＸＭＬに設定したＬＩＮＫ項目リストは追加する
			jsonDataFields.add(key);
			jsonDataFields.add(customLinkMap.get(key));
		}

		// XMLに定義された表示項目リスト取得、処理を行う
		for (String item : fieldsSplits) {
			String[] keySplits = item.split(':');
			if (keySplits.size() != 2) {
				//表示項目書式の設定が不正です[API名:項目ラベル]
				Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
				  Label.MSG_041_0031));
				break;
			}
			String key = keySplits[0];
			String disKey = converDisFields(key);
			String lab =  keySplits[1];
			// ＸＭＬに設定した項目リストは追加する
			jsonDataFields.add(key);
			// API名を格納する
			customApiFields.add(key);
			// 表示ラベルを定義する
			customLabelMap.put(disKey,  lab);
			// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH BEGIN
			// 去掉不符合条件的API
			if(!grpTitlApiSet.contains(key)){
				grpTitlApiSet.remove(key);
				grpAggrApiSet.remove(key);
			}
			// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH END
		}
		// リンクする項目関連設定はSQLから検索必要の項目情報に格納する
		// 2017/06/06 XMLのAPI定義小文字、大文字区別されない対応 BEGIN
		// leadSqlFieldsSet.addAll(jsonDataFields);
		for (String xmlApiKey : jsonDataFields) {
			string lowApiKey = CommUtils.nullToBlank(xmlApiKey).toLowerCase();
			leadSqlFieldsSet.add(lowApiKey);
		}
		// 2017/06/06 XMLのAPI定義小文字、大文字区別されない対応 END
		// 既存固定定義している予約検索のＳＱＬを取得する
		queryLeadStr = queryConstLeadStr + ',' + queryRoomStr;
		// 固定定義されている項目リストを取得する
		String[] constLeadFields = queryLeadStr.deleteWhitespace().split(',');
		// 2017/09/18 予定表を表示のとき、部屋順で表示できる改善対応 WGCH BEGIN
		// 2018/02/02 予定表とタイムテーブルの並びを変えたい WGCH BEGIN
		// constLeadFields.add(sortField);
		leadSqlFieldsSet.add(CommUtils.nullToBlank(sortField).toLowerCase());
		// 2018/02/02 予定表とタイムテーブルの並びを変えたい WGCH END
		// 2017/09/18 予定表を表示のとき、部屋順で表示できる改善対応 WGCH END
		// カスタム項目をＳＱＬへ追加する
		for (String field : constLeadFields) {
			// 2017/06/06 XMLのAPI定義小文字、大文字区別されない対応 BEGIN
			//String key = field;
			String key = CommUtils.nullToBlank(field).toLowerCase();
			// 2017/06/06 XMLのAPI定義小文字、大文字区別されない対応 END
			// 該当項目が既に存在する場合、
			leadSqlFieldsSet.remove(key);
		}
		// 2018/02/02 予定表とタイムテーブルの並びを変えたい WGCH BEGIN
		xmlSqlFieldsSet.addAll(leadSqlFieldsSet);
		// 部屋リストを取得する
		if (!isInitCall) roomList = getRoomList();
		// 2018/02/02 予定表とタイムテーブルの並びを変えたい WGCH END
		// カスタム項目は存在する場合、ＳＱＬに追加する
		for (String apiName : leadSqlFieldsSet) {
			queryLeadStr += ',' + apiName;
		}
		// 表示するデータ項目情報を作成する
		// 2017/04/27 初期化以外の場合、GRID定義情報JSONは重複処理しない改善 BEGIN
		if (!isInitCall) return;
		// 2017/04/27 初期化以外の場合、GRID定義情報JSONは重複処理しない改善 END
		// GRIDのCOLNUM定義属性作成する
		genShowFieldsColnumJson(pShopCode);
		genAvgColInfoPoint();
		genModelJson();
		// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH BEGIN
		genGroupInfo();
		// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH END
		// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
		genFoodGroupInfo();
		// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
	}
	// -------------------------------------------
	// 各店舗の表示する項目情報を取得、格納を行う
	// -------------------------------------------
	private static String parseFieldsXml(String pShopCode, Boolean isInitCall) {
		// ログインユーザーの店舗コードが存在チェックを行う
		// String userShopCode = CommUtils.nullToBlank(UserUtil.CurrentUser.ShopCode__c);
		// StaticResourceから設定情報を取得する（ＸＭＬ）
		// List<StaticResource> sr = [Select body, name from StaticResource where Name = 'ScheduleReportFieldsXml']; 
		// 2014/06/26 部屋表示ステータス切り替え制御 BEGIN
		intervalTime = '60';
		// 2014/06/26 部屋表示ステータス切り替え制御 END
		editColumStr = '';
		jsonColumType = '';
		// 2017/04/27 共通定義に切替対応 BEGIN
		// 2017/04/27  料理数目变更之后变颜色对应 WGCH BEGIN
		foodSumColor = '';//料理変更する倍、色値
		isFoodSumColor = false;//料理変更機能有効
		detailIsShowFlg = true;//料理列の料理変更されると、色変更を行う
		// 2017/04/27  料理数目变更之后变颜色对应 WGCH END
		// 2019/06/28 初期化地址共存修复对应 WGCH BEGIN
		opColIsShowFlg = false;
		// 2019/06/28 初期化地址共存修复对应 WGCH END
		// 2021/05/31 #11230 bug fixed by zy BEGIN
		isMultiRoomFlg = true;
		// 2021/05/31 #11230 bug fixed by zy END
		/*
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
			Dom.XmlNode shopcode =  shop.getChildElement('SHOPCODE', null);
			// 店舗コードを取得する
			String strShopCode = CommUtils.nullToBlank(shopcode.getText());
			if (firstNode == null) firstNode = shop;
			// ログインユーザの店舗コードと一致する場合
			//if (strShopCode == userShopCode) {
			if (strShopCode == pShopCode) {
				targetNode = shop;
				break;
			}
		}
		// 目標店舗情報を取得する、店舗コード未設定する場合、一番目の店舗情報で設定する
		targetNode = targetNode == null ? firstNode : targetNode;
		*/
		Dom.XMLNode targetNode = CommXmlUtils.parseXmlDoc('ScheduleReportFieldsXml',pShopCode);
		// 2021/05/31 予定表のレイアウトを複数パターンから切り替えられるようにしたいユーザ単位で保存できるように by zy BEGIN
		layoutOpts = new List<Map<String,String>>();
		// 2021/05/31 予定表のレイアウトを複数パターンから切り替えられるようにしたいユーザ単位で保存できるように by zy END
		// 2017/04/27 共通定義に切替対応 END
		if (targetNode == null) return '';
		// 2021/05/31 予定表のレイアウトを複数パターンから切り替えられるようにしたいユーザ単位で保存できるように by zy BEGIN
		Dom.XmlNode layoutFields = targetNode.getChildElement('LAYOUT', null);
		if (layoutFields != null) {
			for (Dom.XmlNode dom : targetNode.getChildElements()){
				if (dom.getName() == 'LAYOUT'){
					String layoutLabel = '';
					Dom.XmlNode layoutLabelDom = dom.getChildElement('LAYOUTLABEL',null);
					if (layoutLabelDom != null) {
						layoutLabel = CommUtils.nullToBlank(layoutLabelDom.getText());
					}
					if (!CommUtils.isBlank(layoutLabel)){
						if (layoutLabel == pLayoutId){
							targetNode = dom;
						}
						layoutOpts.add(new Map<String,String>{'name' => layoutLabel , 'code' => layoutLabel});
					}
				}
			}
		}
		// 2021/05/31 予定表のレイアウトを複数パターンから切り替えられるようにしたいユーザ単位で保存できるように by zy END
		// isShowCommand = false;
		// 店舗情報はＸＭＬから取得する
		Dom.XmlNode shopFields =  targetNode.getChildElement('FIELDS', null);
		Dom.XmlNode linkFields = targetNode.getChildElement('LINKFIELD', null);
		Dom.XmlNode avgFields = targetNode.getChildElement('AGGREGATE', null);
		Dom.XmlNode hidFields = targetNode.getChildElement('HIDDENFIELD', null);
		Dom.XmlNode widthFields = targetNode.getChildElement('COLNUMSIZE', null);
		Dom.XmlNode styleFields = targetNode.getChildElement('COLNUMSTYLE', null);
		Dom.XmlNode dataTypeFields = targetNode.getChildElement('COLNUMTYPE', null);
		Dom.XmlNode editDataFields = targetNode.getChildElement('COLNUMEDIT', null);
		Dom.XmlNode optionsFields = targetNode.getChildElement('OPTIONS', null);
		// 2018/02/05 手書き zyz BEGIN
		Dom.XmlNode canvasFlgFields = targetNode.getChildElement('HANDWRITE', null);
		xmlExportFlg = false;
		userStr = '';
		canvasMode = CANVAS_OFF;
		maxHeight = 8000;
		if(canvasFlgFields != null){
			boolean shareFlag = true;
			canvasMode = CANVAS_ONE;
			// Dom.XmlNode exportFields = canvasFlgFields.getChildElement('EXPORT', null);
			Dom.XmlNode reappearFields = canvasFlgFields.getChildElement('REAPPEAR', null);
			Dom.XmlNode customFields = canvasFlgFields.getChildElement('CUSTOMKEY', null);
			Dom.XmlNode shareFlagNode = canvasFlgFields.getChildElement('SHAREFLG', null);
			Dom.XmlNode maxHeightNode = canvasFlgFields.getChildElement('MAXHEIGHT', null);
			// 导出方式：png/PDF
			// if(exportFields != null) xmlExportFlg = ((CommUtils.nullToBlank(exportFields.getText()).toLowerCase() =='pdf') ? true :false);
			// 手书方式
			if(reappearFields != null) {
				Boolean xmlReappearFlg = Boolean.valueOf(CommUtils.nullToBlank(reappearFields.getText()));
				if (xmlReappearFlg) canvasMode = CANVAS_REA;
			}
			// 共享设定
			if ( shareFlagNode != null ) {
				 String shareFlagStr = shareFlagNode.getText();
				 if (!CommUtils.isBlank(shareFlagStr)) shareFlag = boolean.valueof(shareFlagStr);
			}
			// 添加的user定义内容key
			if(customFields != null) {
				String xmlCustomFlg = CommUtils.nullToBlank(customFields.getText());
				if(!CommUtils.isBlank(xmlCustomFlg)){
					try{
						for(String Str : xmlCustomFlg.split(',')){
							userStr +=  '_' + String.valueOf(userInf.u.get(Str));
						}
					}catch (Exception e) {}
				}
			}
			if (!shareFlag && CommUtils.isBlank(userStr)) userStr +=  '_' + String.valueOf(userInf.u.get('Id'));
			if (maxHeightNode != null) {
				maxHeight = CommUtils.nullToIntZero(maxHeightNode.getText());
			}
		}
		// 2018/02/05 手書き zyz END
		// 2017/03/13 予定表の変更履歴が色でわかるように、色も一色ではなくN色自動対応 BEGIN
		bgColorFlg =  true;
		Dom.XmlNode historyFields =  targetNode.getChildElement('HISTORY', null);
		colorMap = new Map<String,HistorySetupInfo>();
		if (historyFields != null) {
			Dom.XmlNode bgColorFields =  historyFields.getChildElement('BGCOLOR', null);
			if(bgColorFields != null){
				bgColorFlg = Boolean.valueOf(CommUtils.nullToBlank(bgColorFields.getText()));
			}
			
			// COLOR単位
			for(Dom.XMLNode colorNode : historyFields.getChildElements()){
				// 各APIの色定義情報を取得する
				if(colorNode.getName().equalsIgnoreCase('COLOR')){
					// COLORタグ単位の定義情報を格納する
					HistorySetupInfo history = new HistorySetupInfo();
					for(Dom.XMLNode valueNode : colorNode.getChildElements()){
						// 2017/04/27 为了追加根据时间来对API变背景色的处理==>>为了把Map转写成In The class WGCH BEGIN
						if(valueNode.getName().equalsIgnoreCase('VALUE')){
							String val = CommUtils.nullToBlank(valueNode.getText());
							if (CommUtils.isBlank(val)) continue;
							ColorType colorItem = new ColorType();
							String tmFromNo = CommUtils.nullToBlank(valueNode.getAttribute('TMFROM', null));
							String tmToNo = CommUtils.nullToBlank(valueNode.getAttribute('TMTO', null));
							String fromNo = CommUtils.nullToBlank(valueNode.getAttribute('FROM', null));
							String toNo = CommUtils.nullToBlank(valueNode.getAttribute('TO', null));
							colorItem.val = val;
							colorItem.tmFromNo = tmFromNo;
							colorItem.tmToNo = tmToNo;
							colorItem.fromNo = fromNo;
							colorItem.toNo = toNo;
							history.colorLst.add(colorItem);
						}
						// 2017/04/27 为了追加根据时间来对API变背景色的处理==>>为了把Map转写成In The class WGCH END
					}
					// 該当色の関連のAPI項目
					Dom.XmlNode apiFields = colorNode.getChildElement('FIELDS', null);
					if(apiFields != null){
						String apistr = CommUtils.nullToBlank(apiFields.getText());
						// 項目API名は未定義する場合、処理SKIPする
						if (CommUtils.isBlank(apistr)) continue;
						for(String api : apiStr.split(',')){
							api = CommUtils.nullToBlank(api).toLowerCase();
							// API単位のCOLOR定義する格納
							if (!colorMap.containsKey(api)) colorMap.put(api, history);
							else colorMap.get(api).colorLst.addAll(history.colorLst);
						}
					}
				}	
			}
			// 2017/04/27 料理数目变更之后变颜色对应 WGCH BEGIN
			Dom.XmlNode foodSumColorNode =  historyFields.getChildElement('FOODSUMMARYCOLOR', null);
			if(foodSumColorNode != null){
				detailIsShowFlg = Boolean.valueOf(CommUtils.nullToBlank(foodSumColorNode.getAttribute('DETAILISSHOW', null)));
				Dom.XmlNode foodSumColorFields = foodSumColorNode.getChildElement('VALUE', null);
				if(foodSumColorFields != null){
					foodSumColor = CommUtils.nullToBlank(foodSumColorFields.getText());
					isFoodSumColor =  true;
				}
			}
			// 2017/04/27 料理数目变更之后变颜色对应 WGCH END
		}
		// 2017/03/13 予定表の変更履歴が色でわかるように、色も一色ではなくN色自動対応 END
		// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH BEGIN
		// 項目タイプ
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
		// 2017/09/18 予定表に表示したく無い部屋のSEQ#をカンマで複数定義するに改善対応 WGCH BEGIN
		Dom.XmlNode noShowRoomFields =  targetNode.getChildElement('NOSHOWROOM', null);
		if(noShowRoomFields != null){
			for(String seqStr : CommUtils.nullToBlank(noShowRoomFields.getText()).split(',')){
				if(!CommUtils.isBlank(seqStr)) noRmSeqSet.add(CommUtils.nullToZero(seqStr));
			}
		}
		// 2017/09/18 予定表に表示したく無い部屋のSEQ#をカンマで複数定義するに改善対応 WGCH END
		// 2017/09/18 予定表を表示のとき、部屋順で表示できる改善対応 WGCH BEGIN
		sortField = 'Rroom__r.Seq__c';
		Dom.XmlNode sortApiFields =  targetNode.getChildElement('SORTFIELD', null);
		if (sortApiFields != null) {
			String sortApiStr = CommUtils.nullToBlank(sortApiFields.getText());
			if(!CommUtils.isBlank(sortApiStr)){
				String[] sortApiArr = sortApiStr.toLowerCase().split('__r.');
				if(sortApiArr.Size() == 2 && sortApiArr[0] == 'rroom') sortField = sortApiStr;
			}
		}
		// 2017/09/18 予定表を表示のとき、部屋順で表示できる改善対応 WGCH END
		// GROUPABLE功能FLG	TRUE:有效;FALSE:无效;
		xmlGroupAbleFlg = false;
		collapseGroupFlg = true;
		Dom.XmlNode groupAbleFields =  targetNode.getChildElement('GROUPABLE', null);
		if (groupAbleFields != null) {
			xmlGroupAbleFlg = true;
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
			Dom.XmlNode autoExpandFields =  groupAbleFields.getChildElement('AUTOEXPAND', null);
			if (autoExpandFields != null) {
				String autoExpandStr = CommUtils.nullToBlank(autoExpandFields.getText());
				collapseGroupFlg = !Boolean.valueOf(autoExpandStr);
			}
		}
		// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH END
		// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH BEGIN
		String strShowGuest = shopFields == null ? '' : CommUtils.nullToBlank(shopFields.getAttribute('SHOWGUEST', null));
		isShowGuestInfo = CommUtils.isBlank(strShowGuest) ? false  : Boolean.valueOf(strShowGuest);
		Dom.XmlNode guestFields = targetNode.getChildElement('GUESTYADOINFO', null);
		guestTitle = guestFields == null ? '' : CommUtils.nullToBlank(guestFields.getAttribute('TITLE', null));
		if (guestFields != null && isShowGuestInfo) {
			for(String guestApi : CommUtils.nullToBlank(guestFields.getText()).split(',') ){
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
		// 2020/02/28 同伴者情報列位置自定义改善对应 WGCH END
		// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH END
		// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
		foodGroupAbleFlg = false;
		Dom.XmlNode foodGroupAble = targetNode.getChildElement('FOODGROUPABLE', null);
		if(foodGroupAble != null){
			String foodGroupAbleStr = CommUtils.nullToBlank(foodGroupAble.getText());
			foodGroupAbleFlg = Boolean.valueOf(foodGroupAbleStr);
		}
		// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
		String strShowFood = shopFields == null ? '' : CommUtils.nullToBlank(shopFields.getAttribute('SHOWFOOD', null));
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
		// 2020/02/28 同伴者情報列位置自定义改善对应 WGCH END
		// OPTIONS DEFINE PARSE
		// OPTIONS ITEM INIT
		optionsAssignRoomOnlyShowFlg = false;
		// 2019/02/28 「前日」「今日」「翌日」ボタンをつけることは改善対応 WGCH BEGIN
		dayButtonShow = false;
		// 2019/02/28 「前日」「今日」「翌日」ボタンをつけることは改善対応 WGCH END
		if (optionsFields != null) {
			// 割り当て部屋のみ表示フラグ
			Dom.XmlNode assignRoomFields = optionsFields.getChildElement('ASSIGNONLYROOM', null);
			if (assignRoomFields != null) {
				String flg = CommUtils.nullToBlank(assignRoomFields.getText()).deleteWhitespace();
				if (!CommUtils.isBLank(flg) && Boolean.valueOf(flg)) optionsAssignRoomOnlyShowFlg = true;
			}
			// 2016/01/28 インターバルタイマ定義は定義XMLに指定可能の対応 BEGIN
			Dom.XmlNode pollerTimerFields = optionsFields.getChildElement('POLLERTIMER', null);
			if (pollerTimerFields != null) {
				String locIntervalTime = CommUtils.nullToBlank(pollerTimerFields.getText());
				if(!CommUtils.isBlank(locIntervalTime)) {
					if (CommUtils.nullToZero(locIntervalTime) <= 30) intervalTime = '30';
					else intervalTime = locIntervalTime;
				}
			}
			// 2016/01/28 インターバルタイマ定義は定義XMLに指定可能の対応 END
			// 2019/02/28 「前日」「今日」「翌日」ボタンをつけることは改善対応 WGCH BEGIN
			Dom.XmlNode dayButtonShowFields = optionsFields.getChildElement('DAYBUTTONSHOW', null);
			if (dayButtonShowFields != null) {
				dayButtonShow = Boolean.valueOf(CommUtils.nullToBlank(dayButtonShowFields.getText()));
			}
			// 2019/02/28 「前日」「今日」「翌日」ボタンをつけることは改善対応 WGCH END
			// 2019/06/14 予定表の表示期間対応 WGCH BEGIN
			// から定義情報
			Dom.XmlNode termDatesSize = optionsFields.getChildElement('TERMDATESIZE', null);
			if (termDatesSize != null) {
				String termDatesSizeStr = CommUtils.nullToBlank(termDatesSize.getText());
				if (!CommUtils.isBlank(termDatesSizeStr) && Pattern.matches('[0-9]*', termDatesSizeStr)){
					if(CommUtils.nullToIntZero(termDatesSizeStr) > 0 ) termDatesLst = getTermDatesSoption(CommUtils.nullToIntZero(termDatesSizeStr));
				}
			}
			// 2019/06/14 予定表の表示期間対応 WGCH END
			// 2019/06/14 「料理」列に「会計OP」を表示したい对应 WGCH BEGIN
			Dom.XmlNode opColIsShow = optionsFields.getChildElement('SHOWFOODISSHOWOP', null);
			if(opColIsShow != null){
				opColIsShowFlg = Boolean.valueOf(CommUtils.nullToBlank(opColIsShow.getText()));
				opLabel = CommUtils.nullToBlank(opColIsShow.getAttribute('LABEL', null));
			}
			// 2019/06/14 「料理」列に「会計OP」を表示したい对应 WGCH END
			// 2021/05/31 #11230 bug fixed by zy BEGIN
			Dom.XmlNode isMultiRoomField = optionsFields.getChildElement('MULTIROOMFLG', null);
			if(isMultiRoomField != null){
				isMultiRoomFlg = Boolean.valueOf(CommUtils.nullToBlank(isMultiRoomField.getText()));
			}
			// 2021/05/31 #11230 bug fixed by zy END
		}
		isShowFoodStyle = shopFields == null ? '' : CommUtils.nullToBlank(shopFields.getAttribute('SHOWFOODSTYLE', null));
		// 2014/03/18 料理項目横幅設定
		isShowFoodWidth = shopFields == null ? '' : CommUtils.nullToBlank(shopFields.getAttribute('SHOWFOODWIDTH', null));
		// 2019/04/30 料理項目列のタイトルを表示・非表示切り替えフラグ WSQ BEGIN
		isNoShowFoodHeader = shopFields == null ? false : Boolean.valueOf(CommUtils.nullToBlank(shopFields.getAttribute('SHOWFOODSIMPLE', null)));
		// 2019/04/30 料理項目列のタイトルを表示・非表示切り替えフラグ WSQ END
		// リンク項目を取得する
		if (linkFields != null) {
			String strLinkFields = linkFields.getText();
			String[] strLinkFieldsSplit = strLinkFields.split(',');
			for (String linkInfo : strLinkFieldsSplit) {
				String[] linkInfoSplit = linkInfo.split(':');
				if (linkInfoSplit.size() != 2) {
					// 表示項目書式の設定が不正です[API名:項目ラベル]
					Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
				  	Label.MSG_041_0031));
				  	break;
				} else {
					// KEY: LINKされる項目ＡＰＩ名、linkId繊維先のSalesforceID
					String key = linkInfoSplit[0].trim();
					String linkId = linkInfoSplit[1].trim();
					customLinkMap.put(key, linkId);
				}
			}
		}
		// 2018/07/30 料理集計 WGCH BEGIN
		Dom.XmlNode nightsGroupAble = targetNode.getChildElement('NIGHTSGROUPABLE', null);
		if(nightsGroupAble != null){
			String nightsGroupAbleStr = CommUtils.nullToBlank(nightsGroupAble.getText());
			foodNightsFlg = Boolean.valueOf(nightsGroupAbleStr);
		}
		// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
		// 料理集計情報Window定義情報(css)
		foodSummaryInfo = new FoodSummarySetupInfo();
		// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
		// 泊数列背景颜色
		Dom.XmlNode foodSummaryFields = targetNode.getChildElement('FOODSUMMARY', null);
		if(foodsummaryFields != null){
			Dom.XmlNode consecutiveNights = foodsummaryFields.getChildElement('CONSECUTIVENIGHTS', null);
			if (consecutiveNights != null) {
				for(Dom.XMLNode bgColorNode : consecutiveNights.getChildElements()){
					if(bgColorNode.getName().equalsIgnoreCase('BACKGROUNDCOLOR')){							 
						String bgColor = CommUtils.nullToBlank(bgColorNode.getText());
						if (CommUtils.isBlank(bgColor)) continue;
						ColumnBgColor bgColorItem = new ColumnBgColor();
						String fromNight = CommUtils.nullToBlank(bgColorNode.getAttribute('FROMNIGHT', null));
						String toNight = CommUtils.nullToBlank(bgColorNode.getAttribute('TONIGHT', null));
						bgColorItem.bgColor = bgColor;
						bgColorItem.fromNight = fromNight;
						bgColorItem.toNight = toNight;
						columnBgColorLst.add(bgColorItem);
					}
				}
			}
			// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
			// 单价列显示
			Dom.XmlNode unitpriceColShowFields = foodsummaryFields.getChildElement('UNITPRICECOLSHOW', null);
			if (unitpriceColShowFields != null) {
				foodSummaryInfo.unitpriceColShow = Boolean.valueOf(CommUtils.nullToBlank(unitpriceColShowFields.getText()));
				foodSummaryInfo.mode = CommUtils.nullToBlank(unitpriceColShowFields.getAttribute('MODE', null));
			}
			// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
			// 2019/05/15 料理集計「単泊」の料理数は「連泊の１泊目」に合計する機能対応 WGCH BEGIN
			Dom.XmlNode oneNightSumFlgFields = foodsummaryFields.getChildElement('ONENIGHTSUMFLG', null);
			if (oneNightSumFlgFields != null) {
				foodSummaryInfo.oneNightSumFlg = Boolean.valueOf(CommUtils.nullToBlank(oneNightSumFlgFields.getText()));
			}
			// 2019/05/15 料理集計「単泊」の料理数は「連泊の１泊目」に合計する機能対応 WGCH END
			// 2019/06/14 フィルターを各アカウント毎に保持できる様にして欲しい対応 WGCH BEGIN
			Dom.XmlNode summaryFilterConfig = foodsummaryFields.getChildElement('SUMMARYFILTERCONFIG', null);
			if (summaryFilterConfig != null) {
				foodSummaryInfo.summaryFilterConfigFlg = Boolean.valueOf(CommUtils.nullToBlank(summaryFilterConfig.getText()));
			}
			// 2019/06/14 フィルターを各アカウント毎に保持できる様にして欲しい対応 WGCH END
		}
		// 2018/07/30 料理集計 WGCH END
		// 2018/10/15 料理集計に合計の表記がございますが機能対応 WGCH BEGIN
		Dom.XmlNode foodSumIsShowProd = targetNode.getChildElement('FOODSUMISSHOWPROD', null);
		foodSumIsShowProdFlg = foodSumIsShowProd == null ? false : Boolean.valueOf(CommUtils.nullToBlank(foodSumIsShowProd.getText()));
		Dom.XmlNode foodSumIsNoShow = targetNode.getChildElement('FOODSUMISNOSHOW', null);
		foodSumIsShowFlg = !(foodSumIsNoShow == null ? false : Boolean.valueOf(CommUtils.nullToBlank(foodSumIsNoShow.getText())));
		// 2018/10/15 料理集計に合計の表記がございますが機能対応 WGCH END
// 2017/04/27 初期化以外の場合、GRID定義情報JSONは重複処理しない改善 BEGIN
if (isInitCall) {
// 2017/04/27 初期化以外の場合、GRID定義情報JSONは重複処理しない改善 END
		// 合計項目設定内容を取得する
		if (avgFields != null) {
			String strAvgFields = CommUtils.nullToBlank(avgFields.getText()).deleteWhitespace();
			if (!CommUtils.isBlank(strAvgFields)) {
				customAggregateFields.addAll(strAvgFields.split(','));
			}
		}
		if (hidFields != null) {
			String strHidFields = CommUtils.nullToBlank(hidFields.getText()).deleteWhitespace();
			if (!CommUtils.isBlank(strHidFields)) {
				customHidFields.addAll(strHidFields.split(','));
			}
		}
		if (widthFields != null) {
			String strWidthFields = CommUtils.nullToBlank(widthFields.getText()).deleteWhitespace();
			if (!CommUtils.isBlank(strWidthFields)) {
				// customHidFields.addAll(strHidFields.split(','));
				for (String key : strWidthFields.split(',')) {
					String[] widthCof = key.split(':');
					if (widthCof.size() != 2) continue;
					customWidthMap.put(widthCof[0],widthCof[1]);
				}
			}
		}
		if (styleFields != null) {
			String strStyleFields = CommUtils.nullToBlank(styleFields.getText()).deleteWhitespace();
			if (!CommUtils.isBlank(strStyleFields)) {
				// customHidFields.addAll(strHidFields.split(','));
				for (String key : strStyleFields.split(',')) {
					String[] widthCof = key.split(':', 2);
					if (widthCof.size() != 2) continue;
					customStyleMap.put(widthCof[0],widthCof[1]);
				}
			}
			
		}
		// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH BEGIN
		/*
		// 項目タイプ
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
		*/
		// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH END
		if(editDataFields !=null){
			String strEditDataFields = CommUtils.nullToBlank(editDataFields.getText()).deleteWhitespace();
			if (!CommUtils.isBlank(strEditDataFields)) {
				customEditSet.addAll(strEditDataFields.split(','));
				editColumStr = strEditDataFields;
				//isShowCommand = true;
			}
		}
		// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
		// 料理集計情報Window定義情報(css)
		// foodSummaryInfo = new FoodSummarySetupInfo();
		// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
		// 2018/07/30 料理集計 WGCH BEGIN
		// Dom.XmlNode foodSummaryFields = targetNode.getChildElement('FOODSUMMARY', null);
		// 2018/07/30 料理集計 WGCH END
		if (foodsummaryFields != null) {
			Dom.XmlNode colnumWidthFields = foodsummaryFields.getChildElement('COLNUMSIZE', null);
			if (colnumWidthFields != null) {
				Dom.XmlNode middayIconWidthFields = colnumWidthFields.getChildElement('MIDDAYICON', null);
				Dom.XmlNode productNameWidthFields = colnumWidthFields.getChildElement('PRODCUTNMAEM', null);
				Dom.XmlNode productSummyWidthFields = colnumWidthFields.getChildElement('PRODUCTSUMMY', null);
				// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
				Dom.XmlNode unitpriceWidthFields = colnumWidthFields.getChildElement('UNITPRICE', null);
				// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
				if (middayIconWidthFields != null) {
					String val = CommUtils.nullToBlank(middayIconWidthFields.getText()).deleteWhitespace();
					if (!CommUtils.isBlank(val)) foodSummaryInfo.strMiddayIconWidth = val;
				}
				if (productNameWidthFields != null) {
					String val = CommUtils.nullToBlank(productNameWidthFields.getText()).deleteWhitespace();
					if (!CommUtils.isBlank(val)) foodSummaryInfo.strProductNameWidth = val;
				}
				if (productSummyWidthFields != null) {
					String val = CommUtils.nullToBlank(productSummyWidthFields.getText()).deleteWhitespace();
					if (!CommUtils.isBlank(val)) foodSummaryInfo.strProductSummyWidth = val;
				}
				// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
				if (unitpriceWidthFields != null) {
					String val = CommUtils.nullToBlank(unitpriceWidthFields.getText()).deleteWhitespace();
					if (!CommUtils.isBlank(val)) foodSummaryInfo.strUnitpriceWidth = val;
				}
				// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
			}
			// 列のCSS定義情報
			Dom.XmlNode colnumStyleFields = foodsummaryFields.getChildElement('COLNUMSTYLE', null);
			if (colnumStyleFields != null) {
				Dom.XmlNode middayIconStyleFields = colnumStyleFields.getChildElement('MIDDAYICON', null);
				Dom.XmlNode productNameStyleFields = colnumStyleFields.getChildElement('PRODCUTNMAEM', null);
				Dom.XmlNode productSummyStyleFields = colnumStyleFields.getChildElement('PRODUCTSUMMY', null);
				// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
				Dom.XmlNode unitpriceStyleFields = colnumStyleFields.getChildElement('UNITPRICE', null);
				// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
				if (middayIconStyleFields != null) {
					String val = CommUtils.nullToBlank(middayIconStyleFields.getText()).deleteWhitespace();
					if (!CommUtils.isBlank(val)) foodSummaryInfo.strMiddayIconStyle = val;
				}
				if (productNameStyleFields != null) {
					String val = CommUtils.nullToBlank(productNameStyleFields.getText()).deleteWhitespace();
					if (!CommUtils.isBlank(val)) foodSummaryInfo.strProductNameStyle = val;
				}
				if (productSummyStyleFields != null) {
					String val = CommUtils.nullToBlank(productSummyStyleFields.getText()).deleteWhitespace();
					if (!CommUtils.isBlank(val)) foodSummaryInfo.strProductSummyStyle = val;
				}
				// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
				if (unitpriceStyleFields != null) {
					String val = CommUtils.nullToBlank(unitpriceStyleFields.getText()).deleteWhitespace();
					if (!CommUtils.isBlank(val)) foodSummaryInfo.strUnitpriceStyle = val;
				}
				// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
			}
			// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
			// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
			/*
			// 单价列显示
			Dom.XmlNode unitpriceColShowFields = foodsummaryFields.getChildElement('UNITPRICECOLSHOW', null);
			if (unitpriceColShowFields != null) {
				foodSummaryInfo.unitpriceColShow = Boolean.valueOf(CommUtils.nullToBlank(unitpriceColShowFields.getText()));
			}
			*/
			// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
			// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
		}
		// 2019/06/14 予定表の表示期間対応 WGCH BEGIN
		// から定義情報
		Dom.XmlNode termDatesSize = targetNode.getChildElement('TERMDATESIZE', null);
		if (termDatesSize != null) {
			String termDatesSizeStr = CommUtils.nullToBlank(termDatesSize.getText());
			if (!CommUtils.isBlank(termDatesSizeStr) && Pattern.matches('[0-9]*', termDatesSizeStr)){
				if(CommUtils.nullToIntZero(termDatesSizeStr) > 0 ) termDatesLst = getTermDatesSoption(CommUtils.nullToIntZero(termDatesSizeStr));
			}
		}
		// 2019/06/14 予定表の表示期間対応 WGCH END
// 2017/04/27 初期化以外の場合、GRID定義情報JSONは重複処理しない改善 BEGIN
}
// 2017/04/27 初期化以外の場合、GRID定義情報JSONは重複処理しない改善 END
		// 関連情報を設定する
		isShowFoodInfo = CommUtils.isBlank(strShowFood) ? false  : Boolean.valueOf(strShowFood);
		return shopFields == null ? '' : CommUtils.nullToBlank(shopFields.getText()).deleteWhitespace();
	}
	// 2017/03/13 予定表の変更履歴が色でわかるように、色も一色ではなくN色自動対応 BEGIN
	private static List<HistorySetupInfo> historyColorItem;
	public class HistorySetupInfo{
		// XMLの色定義情報
		public List<ColorType> colorLst;
		public HistorySetupInfo(){
			colorLst = new List<ColorType>();
		}
	}
	public class HistoryColor{
		public String fontColor;
		public String bgColor;
		public HistoryColor(){
			fontColor = '';
			bgColor = '';
		}
	}
	// 2017/04/27 为了追加根据时间来对API变背景色的处理==>>为了把Map转写成In The class WGCH BEGIN
	public class ColorType{
		public String val;
		public String fromNo;
		public String toNo;
		public String tmFromNo;
		public String tmToNo;
		public ColorType(){
			val = '';
			fromNo = '';
			toNo = '';
			tmFromNo = '';
			tmToNo = '';
		}
		public boolean isOnlyColorVal() {
			return (CommUtils.isBlank(fromNo) && CommUtils.isBlank(toNo) && CommUtils.isBlank(tmFromNo) && CommUtils.isBlank(tmToNo) && !CommUtils.isBlank(val));
		}
	}
	public class HistoryData{
		public Integer changeNo;
		public Datetime theDate;
		public HistoryData(){
			changeNo = 0;
			theDate = null;
		}
	}
	// 2017/04/27 为了追加根据时间来对API变背景色的处理==>>为了把Map转写成In The class WGCH END
	// 2017/03/13 予定表の変更履歴が色でわかるように、色も一色ではなくN色自動対応 End
	// 2018/07/30 料理集計 WGCH BEGIN
	public static List<ColumnBgColor> columnBgColorLst = new List<ColumnBgColor>();
	public class ColumnBgColor{
		public String bgColor;
		public String fromNight;
		public String toNight;
		public ColumnBgColor(){
			bgColor = fromNight = toNight = '';
		}
		public boolean isOnlyBgColorVal() {
			return (CommUtils.isBlank(bgColor) && CommUtils.isBlank(fromNight) && CommUtils.isBlank(toNight));
		}
	}
	// 2018/07/30 料理集計 WGCH END
	// 150112 L
	public class FoodSummarySetupInfo{
		// 列の横幅サイズ(px)
		public String strMiddayIconWidth{get; set;}
		public String strProductNameWidth{get; set;}
		public String strProductSummyWidth{get; set;}
		// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
		public String strUnitpriceWidth{get; set;}
		public String strWindowMaxWidth{get{
			Integer maxWidth = (CommUtils.nullToIntZero(strMiddayIconWidth) + 
					CommUtils.nullToIntZero(strProductNameWidth) + 
					CommUtils.nullToIntZero(strProductSummyWidth) + 
					40
					);
			if(unitpriceColShow) maxWidth += CommUtils.nullToIntZero(strUnitpriceWidth);
			return String.valueOf(maxWidth);
		}}
		// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
		// 列のCSS
		public String strMiddayIconStyle{get; set;}
		public String strProductNameStyle{get; set;}
		public String strProductSummyStyle{get; set;}
		// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
		public String strUnitpriceStyle{get; set;}
		public Boolean unitpriceColShow{get; set;}
		// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
		// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
		/*
		* 0:商品单价
		* 1:明细单价税込
		* 2:明细单价税拔
		*/
		public String mode{get; set;}
		// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
		// 2019/05/15 料理集計「単泊」の料理数は「連泊の１泊目」に合計する機能対応 WGCH BEGIN
		public Boolean oneNightSumFlg{get; set;}
		// 2019/05/15 料理集計「単泊」の料理数は「連泊の１泊目」に合計する機能対応 WGCH END
		// 2019/06/14 フィルターを各アカウント毎に保持できる様にして欲しい対応 WGCH BEGIN
		public Boolean summaryFilterConfigFlg{get; set;}
		// 2019/06/14 フィルターを各アカウント毎に保持できる様にして欲しい対応 WGCH END
		public FoodSummarySetupInfo() {
			strMiddayIconWidth = '60';
			strProductNameWidth = '240';
			strProductSummyWidth = '60';
			// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
			strUnitpriceWidth = '60';
			// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
			strMiddayIconStyle = 'font-size: 14px';
			strProductNameStyle = 'font-size: 14px';
			strProductSummyStyle = 'text-align: right; font-size: 14px';
			// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
			strUnitpriceStyle = 'text-align: right; font-size: 14px';
			unitpriceColShow = false;
			// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
			// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
			mode = '0';
			// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
			// 2019/05/15 料理集計「単泊」の料理数は「連泊の１泊目」に合計する機能対応 WGCH BEGIN
			oneNightSumFlg = false;
			// 2019/05/15 料理集計「単泊」の料理数は「連泊の１泊目」に合計する機能対応 WGCH END
			// 2019/06/14 フィルターを各アカウント毎に保持できる様にして欲しい対応 WGCH BEGIN
			summaryFilterConfigFlg = false;
			// 2019/06/14 フィルターを各アカウント毎に保持できる様にして欲しい対応 WGCH END
		}
	}
	// -------------------------------------------
	// GRID 表示の項目定義情報
	// -------------------------------------------
	// 予約情報を表示する項目定義情報を設定する
	public static String colnumJson{get; private set;}
	// 画面に表示する予定のカスタム項目の項目情報を作成する
	private static void genShowFieldsColnumJson(String pShopCode) {
		// 項目タイプにより、？あと回して、まず、文字列で項目表示設定を行う
		JSONGenerator gen = JSON.createGenerator(false);
		gen.writeStartArray();
		Set<String> picklistNameSet = new Set<String>();
		// 2017/04/26 列幅サイズ自動記憶機能対応 BEGIN
		//　COOKIE設定情報を取得する
 		CookieInf cookieInf = getCookieInf(pShopCode);
		// Cookie情報からAPI幅を設定される場合、該当設定値で画面に表示する
		for (String apiName : cookieInf.colnumSizeMap.keySet()) {
			customWidthMap.put(apiName,cookieInf.colnumSizeMap.get(apiName) + 'px');
		}
		// 2017/04/26 列幅サイズ自動記憶機能対応 END
		//for (Integer i = 0; i < customDispFields.size(); i++) {
		Integer idx = 0;
		Boolean isShowedFoodInf = false;
		// 2020/02/28 同伴者情報列位置自定义改善对应 WGCH BEGIN
		Boolean isShowedGuestInf = false;
		// 2020/02/28 同伴者情報列位置自定义改善对应 WGCH END
		modelDeafaultValuesMap = new Map<String,Schema.DescribeFieldResult>();
		for (String api : customApiFields) {
			// 隠列の項目の場合、列計算対象外
			if (!customHidFields.contains(api)) {
				idx ++;
			}
			// 料理情報列の設定値の場合、料理情報を追加設定
			if (idx == isShowFoodPosition) {
				// 2017/09/23 列表示・非表示自動記憶機能対応 WGCH BEGIN
				// 料理情報を作成する
				if (isShowFoodInfo) genCookingInfoPoint(gen, cookieInf);
				// 2017/09/23 列表示・非表示自動記憶機能対応 WGCH END
				// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH BEGIN
				// 2020/02/28 同伴者情報列位置自定义改善对应 WGCH BEGIN
				// if (isShowGuestInfo) genContactInfoPoint(gen, cookieInf);
				if (!isShowGuestPositionFlg && isShowGuestInfo){
					genContactInfoPoint(gen, cookieInf);
					isShowedGuestInf = true;
				}
				else if(isShowGuestPositionFlg && isShowFoodInfo) idx ++;
				// 2020/02/28 同伴者情報列位置自定义改善对应 WGCH END
				// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH END
				isShowedFoodInf = true;
				//idx ++;
			}
			// 2020/02/28 同伴者情報列位置自定义改善对应 WGCH BEGIN
			// 同伴者情報列の設定値の場合、料理情報を追加設定
			if (isShowGuestPositionFlg && (idx == isShowGuestPosition)) {
				if (isShowGuestInfo) {
					genContactInfoPoint(gen, cookieInf);
					isShowedGuestInf = true;
					idx ++;
				}
				// 料理情報列の設定値の場合、料理情報を追加設定
				if (idx == isShowFoodPosition) {
					// 料理情報を作成する
					if (isShowFoodInfo) genCookingInfoPoint(gen, cookieInf);
					isShowedFoodInf = true;
				}
			}
			// 2020/02/28 同伴者情報列位置自定义改善对应 WGCH END
			// JSONのColnumKey
			String jsonkey = converDisFields(api);
			// 表示する項目のＡＰＩ名を取得する
			String fieldLab = customLabelMap.get(jsonkey);
			gen.writeStartObject();
			gen.writeStringField('field', jsonkey);
			gen.writeStringField('title', fieldLab);
			gen.writeBooleanField('encoded',false);
			// リンク項目存在する場合
			if (customLinkMap.containsKey(api)) {
				String linkId = converDisFields( customLinkMap.get(api) );
				String linkTxt = converDisFields( api );
				String linkStyle = '';
				if (customStyleMap.containsKey(api)) {
					linkStyle = customStyleMap.get(api);//.replace(':','$_$');
				}
				gen.writeStringField('template', '#= generLinkHtml('+linkId+','+linkTxt+',"'+linkStyle+'") #');
			}
			// 2017/03/13 予定表の変更履歴が色でわかるように、色も一色ではなくN色自動対応 BEGIN
			String wkColorApi = api.toLowerCase();
			if (colorMap.containsKey(wkColorApi)) {
				String leadId = 'Id' ;
				String apiTxt = converDisFields( api );
				gen.writeStringField('template', '#= generColorHtml('+apiTxt+','+leadId+',"'+wkColorApi+'") #');
			}
			// 2017/03/13 予定表の変更履歴が色でわかるように、色も一色ではなくN色自動対応 End
			// 集計項目存在する場合
			if (customAggregateFields.contains(api)) {
				//gen.writeStringField('title', fieldLab);
				gen.writeStringField('footerTemplate', '<div style="width:100%; text-align: right"> #= sum # </div>');
			}
			// 2017/09/23 列表示・非表示自動記憶機能対応 WGCH BEGIN
			Boolean runFlg = true;
			// 取cookie里的隐藏值
			if (CookieInf.colnumHidMap.containsKey(api)){
				runFlg = false;
				gen.writeBooleanField('hidden', CookieInf.colnumHidMap.get(api));
			}
			// 初期非表示項目場合
			if (customHidFields.contains(api) && runFlg) {
			// 2017/09/23 列表示・非表示自動記憶機能対応 WGCH END
				gen.writeBooleanField('hidden',true);
			}
			// 項目サイズが指定したい場合
			if (customWidthMap.containsKey(api)) {
				gen.writeStringField('width',  customWidthMap.get(api));
			}
			if (customStyleMap.containsKey(api)) {
				gen.writeFieldName('attributes');
				gen.writeStartObject();
				gen.writeStringField('class',  'table-cell');
				gen.writeStringField('style', customStyleMap.get(api));
				gen.writeEndObject();
			}
			// データタイプは日付の場合
			if (customTypemap.containsKey(api)) {
				if (customTypemap.get(api) == 'date') {
					gen.writeStringField('type', 'date');
					// gen.writeStringField('format', '{0:yyyy/MM/dd}');
				gen.writeStringField('format',  '{0:'+CommBaseCtrl.getDateFormat()+'}');
					gen.writeBooleanField('filterable',  false);
				} else if (customTypemap.get(api) == 'boolean') {
					// boolean項目タイプ定義する場合、チェックマークアイコン表示
					gen.writeStringField('type', 'boolean');
					gen.writeStringField('template','#= generCheckImgHtml('+jsonkey+') #');
					gen.writeBooleanField('filterable',  false);
				}else if(customTypemap.get(api) == 'list'){
					picklistNameSet.add(api);
					gen.writeStringField('type', 'string');
					// 2021/01/11 予定表の選択リストにもフィルター機能を追加する BY zyz BEGIN
					// filter功能打开
					// gen.writeBooleanField('filterable',  false);
					// 2021/01/11 予定表の選択リストにもフィルター機能を追加する BY zyz END
				}
			}else{
				customTypemap.put(api,'string');
			}
			gen.writeEndObject();
		}
		// 2017/09/23 列表示・非表示自動記憶機能対応 WGCH BEGIN
		// 料理情報を作成する
		if (isShowFoodInfo && !isShowedFoodInf) genCookingInfoPoint(gen, cookieInf);
		// 2017/09/23 列表示・非表示自動記憶機能対応 WGCH END
		// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH BEGIN
		// 2020/02/28 同伴者情報列位置自定义改善对应 WGCH BEGIN
		// if (isShowGuestInfo && !isShowedFoodInf) genContactInfoPoint(gen, cookieInf);
		if (isShowGuestInfo && !isShowedGuestInf) genContactInfoPoint(gen, cookieInf);
		// 2020/02/28 同伴者情報列位置自定义改善对应 WGCH END
		// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH END
		// 編集ボタン追加する
		// genEdidButton(gen);
		if(!picklistNameSet.isEmpty()){
			modelDeafaultValuesMap = CommUtils.getFieldMetaData(Lead__c.getSObjectType().getDescribe(),picklistNameSet);
		}
		// gen.writeEndObject();
		gen.writeEndArray();
		colnumJson = gen.getAsString();
		jsonColumType = JSON.serialize(customTypemap);
	}
	/* 2014/05/08 Delete
	private static void genEdidButton(JSONGenerator gen){
		gen.writeStartObject();
		gen.writeStringField('field','editButton');
		gen.writeStringField('title', '&nbsp;');
		gen.writeStringField('width', '100');
		gen.writeBooleanField('sortable', false);
		gen.writeBooleanField('filterable', false);
		gen.writeStringField('template',  '#= generSubTemp(uid) #');
		gen.writeEndObject();
	}*/
	// JSのCOLNUM定義情報を追加する[料理は個別設定ので、作成したＪＳＯＮに個別追加する]
	// 2017/09/23 列表示・非表示自動記憶機能対応 WGCH BEGIN
	private static void genCookingInfoPoint(JSONGenerator gen, CookieInf cookieColHid) {
	// 2017/09/23 列表示・非表示自動記憶機能対応 WGCH END
		// 2017/04/26 列幅サイズ自動記憶機能対応 BEGIN
		// COOKIEに記載の料理幅情報を取得、画面へ反映する
		// 料理項目もともとVFに"px"持っているため、再設定する場合、px連結しない
		if (customWidthMap.containsKey('detailList')) isShowFoodWidth = customWidthMap.get('detailList');
		// 2017/04/26 列幅サイズ自動記憶機能対応 END
		gen.writeStartObject();
		gen.writeStringField('field','detailList');
		//料理
		gen.writeStringField('title', Label.CONST_041_0037);
		gen.writeStringField('width', Commutils.isBlank(isShowFoodWidth) ? '10%' : isShowFoodWidth);
		gen.writeBooleanField('sortable', false);
		gen.writeBooleanField('filterable', false);
		gen.writeFieldName('attributes');
			gen.writeStartObject();
			gen.writeStringField('style', 'vertical-align: top;');
			gen.writeEndObject();
		// 2019/04/30 料理項目列のタイトルを表示・非表示切り替えフラグ WSQ BEGIN
		//gen.writeStringField('template', '#= generSubHtml(detailList, "'+isShowFoodStyle+'") #');
		// 2019/08/15 SOURCE丢失修正 WGCH BEGIN
		// gen.writeStringField('template', '#= generSubHtml(detailList, "'+isShowFoodStyle+'") #');
		gen.writeStringField('template', '#= generSubHtml(detailList, "'+isShowFoodStyle+'", '+isNoShowFoodHeader+') #');
		// 2019/08/15 SOURCE丢失修正 WGCH END
		// 2019/04/30 料理項目列のタイトルを表示・非表示切り替えフラグ WSQ END
		// 2017/09/23 列表示・非表示自動記憶機能対応 WGCH BEGIN
		// 取cookie里的隐藏值
		if (cookieColHid.colnumHidMap.containsKey('detailList')){
			gen.writeBooleanField('hidden', cookieColHid.colnumHidMap.get('detailList'));
		}
		// 2017/09/23 列表示・非表示自動記憶機能対応 WGCH END
		gen.writeEndObject();
		// Modelの料理は個別設定[編集不可制御するため]
		customTypemap.put('detailList','object');
	}
	// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH BEGIN
	private static void genContactInfoPoint(JSONGenerator gen, CookieInf cookieColHid) {
		// 2017/04/26 列幅サイズ自動記憶機能対応 BEGIN
		// 顧客項目もともとVFに"px"持っているため、再設定する場合、px連結しない
		if (customWidthMap.containsKey('contactList')) isShowFoodWidth = customWidthMap.get('contactList');
		// 2017/04/26 列幅サイズ自動記憶機能対応 END
		gen.writeStartObject();
		gen.writeStringField('field','contactList');
		// 顧客情報
		String titleStr = CommUtils.isBlank(guestTitle) ? Label.MSG_041_0068 : guestTitle;
		gen.writeStringField('title', titleStr);
		gen.writeStringField('width', Commutils.isBlank(isShowFoodWidth) ? '270px' : isShowFoodWidth);
		gen.writeBooleanField('sortable', false);
		gen.writeBooleanField('filterable', false);
		gen.writeFieldName('attributes');
			gen.writeStartObject();
			gen.writeStringField('style', 'vertical-align: top;');
			gen.writeEndObject();
		gen.writeStringField('template', '#= generGuestHtml(contactList, "'+isShowFoodStyle+'") #');
		// 2017/09/23 列表示・非表示自動記憶機能対応 WGCH BEGIN
		// 取cookie里的隐藏值
		if (cookieColHid.colnumHidMap.containsKey('contactList')){
			gen.writeBooleanField('hidden', cookieColHid.colnumHidMap.get('contactList'));
		}
		// 2017/09/23 列表示・非表示自動記憶機能対応 WGCH END
		gen.writeEndObject();
		// [編集不可制御するため]
		customTypemap.put('contactList','object');
	}
	// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH END
	// JSの合計定義情報のＪＳＯＮ作成する
	public static String avgColnumJson{get; private set;}
	private static void genAvgColInfoPoint() {
		if (customAggregateFields.isEmpty()) {
			avgColnumJson = '[]';
			return;
		}
		JSONGenerator gen = JSON.createGenerator(false);
		gen.writeStartArray();
		// 関連設定を行う
		// field: "stayPersons",
		// aggregate: "sum"
		for (String apiFields : customAggregateFields) {
			String jsonKey = converDisFields(apiFields);
			gen.writeStartObject();
			gen.writeStringField('field',jsonKey);
			gen.writeStringField('aggregate', 'sum');
			gen.writeEndObject();
		}
		gen.writeEndArray();
		avgColnumJson = gen.getAsString();
	}
	// JSのモジュール定義情報のＪＳＯＮ作成する 
	// Data Schema Define Info
	public static String modelJson{get;private set;}
	private static void genModelJson () {
		if (customTypemap.isEmpty()) {
			modelJson = '{}';
			return;
		}
		//	{
		//		fields: {
		//					field1 {type: "number"}
		//				}
		//	}
		JSONGenerator gen = JSON.createGenerator(false);
		gen.writeStartObject();
		gen.writeStringField('id', 'Rroom__r_Name');
		gen.writeFieldName('fields');
		gen.writeStartObject();
			for (String apiName : customTypemap.keySet()) {
				String jsonKey = converDisFields  (apiName );
				gen.writeFieldName(jsonKey);
				gen.writeStartObject();
					// 2021/01/11 予定表の選択リストにもフィルター機能を追加する BY zyz BEGIN
					// kendo的TYPE属性没有list，需要把list替换成string，其他位置的设定不变
					// gen.writeStringField('type', customTypemap.get(apiName));
					String typeStr = customTypemap.get(apiName);
					if(typeStr == 'list') typeStr = 'string';
					gen.writeStringField('type', customTypemap.get(apiName));
					// 2021/01/11 予定表の選択リストにもフィルター機能を追加する BY zyz END
					if(customEditSet.contains(apiName)) gen.writeBooleanField('editable', true);
					else gen.writeBooleanField('editable', false);
					if(customTypemap.get(apiName) == 'list' && modelDeafaultValuesMap.containsKey(apiName)){
					genSelectList(gen,apiName);
				}
				gen.writeEndObject();
			}
		gen.writeEndObject();
		modelJson = gen.getAsString(); 
	}
	// Data Schema Define Info
	private static void genSelectList(JSONGenerator gen,String apiName){
		gen.writeFieldName('defaultValue');
		List<Schema.PicklistEntry> ple = modelDeafaultValuesMap.get(apiName).getPicklistValues(); 
		gen.writeStartArray();
		for( Schema.PicklistEntry f : ple){ 
			gen.writeStartObject();
			gen.writeStringField('key' ,f.getValue());
			gen.writeStringField('value' ,f.getLabel());
			gen.writeEndObject();
//System.debug(LoggingLevel.INFO, 'f;;;;;;;' + f);
		}
		gen.writeEndArray();
	}
	/**
	* 初期化
	**/
	public K_ScheduleReport() {
		
		String pShopCode = getSearchShopCode(ApexPages.currentPage().getParameters().get('sp'));
		String pQueryDt = ApexPages.currentPage().getParameters().get('qt');
		termDates = CommUtils.nullToBlank(ApexPages.currentPage().getParameters().get('term'));
		splitLen = CommConst.APPOPTION_REPORT_LINE_SIZE; 
		long timeoff = UserInfo.getTimeZone().getOffset(datetime.newInstance(Date.today(), time.newInstance(0, 0, 0, 0)));
		timeZoneMiliseconds = String.valueOf(timeoff);
		reportMode = CommConst.APPOPTION_REPORT_FOOD_MODE;
		// 部屋表示情報切り替え
		roomViewFlg = ApexPages.currentPage().getParameters().get('rvflg');
		// 2017/09/18 一回のみ切替すると、常に維持する対応 WGCH BEGIN
		if (ApexPages.currentPage().getParameters().containsKey('gpflg')) {
			groupAbleFlg = Boolean.valueOf(ApexPages.currentPage().getParameters().get('gpflg'));
		}
		// 2021/05/31 予定表のレイアウトを複数パターンから切り替えられるようにしたいユーザ単位で保存できるように by zy BEGIN
		boolean hadLayoutFlg = ApexPages.currentPage().getParameters().containsKey('layout');
		if (hadLayoutFlg) {
			pLayoutId = currLayoutId = CommUtils.nullToBlank(ApexPages.currentPage().getParameters().get('layout'));
		}
		initCookiteInfo(pShopCode,hadLayoutFlg);
		// 2021/05/31 予定表のレイアウトを複数パターンから切り替えられるようにしたいユーザ単位で保存できるように by zy END
		// 2017/09/18 一回のみ切替すると、常に維持する対応 WGCH END
		if (CommUtils.isBlank(termDates)) termDates = '1';
		// XML CONFIG
		// 2017/04/27 初期化以外の場合、GRID定義情報JSONは重複処理しない改善 BEGIN
		xmlConfigProcess(pShopCode, true);
		// 2017/04/27 初期化以外の場合、GRID定義情報JSONは重複処理しない改善 END
		// 2021/05/31 予定表のレイアウトを複数パターンから切り替えられるようにしたいユーザ単位で保存できるように by zy BEGIN
		layoutOptJson = JSON.serialize(layoutOpts);
		if (layoutOpts.isEmpty()) {
			currLayoutId = '';
		}
		// 2021/05/31 予定表のレイアウトを複数パターンから切り替えられるようにしたいユーザ単位で保存できるように by zy END
		// 2019/06/14 予定表の表示期間対応 WGCH BEGIN
		// 对应SF内部处理BUG
		Integer termDatesLstSize = termDatesLst.size();
		// 重置有效值
		if(CommUtils.nullToIntZero(termDates) > termDatesLstSize) termDates = CommUtils.nullToBlank(termDatesLstSize);
		// 2019/06/14 予定表の表示期間対応 WGCH END
		// 支店情報リスト初期値
		setInitBranShopLst(pShopCode);
		// 2019/09/15 指定日自动记忆機能対応 WGCH BEGIN
		// 初期値設定
		// timeTable = new BookingTimeTable__c(Checkinday__c = ( CommUtils.isBlank(pQueryDt) ? Date.today() : Date.Parse(pQueryDt) ) );
		Date stDate = CommUtils.isBlank(pQueryDt) ? Date.today() : Date.Parse(pQueryDt);
		if(isChkInDayFlg && CommUtils.isBlank(pQueryDt)){
			Map<string,string> userConfigMap = UserConfigCompCtrl.getKrepConfig(userId, '');
			// 指定日KEY
			String checkInDayKey = UserConfigCompCtrl.KREP_SUBTYPE.CHECKINDAY.name();
			if(userConfigMap.containsKey(checkInDayKey)){
				String queryDt = userConfigMap.get(checkInDayKey); // 记忆指定日
				stDate = (String.isEmpty(queryDt)) ? stDate : CommUtils.stringToDate(queryDt);
			}
		}
		// 初期値設定
		timeTable = new BookingTimeTable__c(Checkinday__c = stDate );
		// 2019/09/15 指定日自动记忆機能対応 WGCH END
		// 2019/05/15 予定表指定日にて、連絡事項を表示する機能対応 WGCH BEGIN
		// 2019/10/15 予定表指定日エラー修正　by　zy　BEGIN　
		// messageDt = pQueryDt;
		messageDt = stDate.format();
		// 2019/10/15 予定表指定日エラー修正　by　zy　END
		messageSpCd = pShopCode;
		setMessageItem();
		// 2019/05/15 予定表指定日にて、連絡事項を表示する機能対応 WGCH END
		// 2019/08/15 予定表の部屋タイプ絞り込みは予定表内のフィルター機能が改善ほしい by zy BEGIN
		setInitRoomTypeLst();
		// 2019/08/15 予定表の部屋タイプ絞り込みは予定表内のフィルター機能が改善ほしい by zy END
	}
	// 2017/10/14 多店舗　かつ　店舗コードがALL選択されるがどうかフラグ BEGIN
	public Boolean getIsAllShopFlg() {
		return (CommUtils.isBlank(branchShopNm) && branchShopLst != null && branchShopLst.size() > 0);
	}
	// 2017/10/14 多店舗　かつ　店舗コードがALL選択されるがどうかフラグ END
	// 支店選択リスト
	public List<SelectOption> branchShopLst{get; private set;}
	public String branchShopNm{get; set;}
	private void setInitBranShopLst(String pShopCode) {
		branchShopLst = new List<SelectOption>();
		/*
		for (AggregateResult r : [  SELECT BranchShopName__c shopName FROM Room__c Where BranchShopName__c != null GROUP BY BranchShopName__c ORDER BY BranchShopName__c limit 1000]) {
			branchShopLst.add(new SelectOption(String.valueof(r.get('shopName')),String.valueof(r.get('shopName'))));
		}*/
		// 2015/09/01 多店舗機能対応 BEGIN
		/*for (ShopInformation__c shop : [select id, name,ShopCode__c from ShopInformation__c order by Seq__c limit  5000]) {
			branchShopLst.add(new SelectOption(shop.ShopCode__c, shop.name));
		}*/
		branchShopLst = ShopInfoUtil.getBranchShopLst(userInf.shops);
		// 2015/09/01 多店舗機能対応 END
		if (!branchShopLst.isEmpty()) {
			// 顧客に設定する支店で初期値に設定する[2013/06/30]
			String locShopCode = pShopCode;
			for (SelectOption s : branchShopLst) {
				if (s.getValue() == locShopCode) branchShopNm = locShopCode;
			}
		}
	}
	@remoteAction
	public static String updateLeadMsg(string jsondata,String jsonEditColumn,String jsonColumnType ) {
		//Object obj  = JSON.deserialize(JSONString, Object.class);
		Map<String,Object> columnType = (Map<String, Object>)JSON.deserializeUntyped(jsonColumnType);
		List<Object> recordList = (List<Object>)JSON.deserializeUntyped(jsondata);
		//System.debug(LoggingLevel.INFO, 'step2:::' + recordList);
		List<Lead__c> leadLst = new List<Lead__c>();
		try{
			for(Object obj : recordList){
				Map<String,Object> recordMap = (Map<String,Object>)obj;
				string leadId = String.valueOf(recordMap.get('Id'));
				Lead__c lead = new Lead__c(id = leadId);//[select Comment3__c from Lead__c where id= :leadId];
				String error = '';
				for(String apiName : jsonEditColumn.split(',')){
					if(recordMap.containsKey(apiName)){
						Object objVal;
						if(columnType.get(apiName)=='boolean'){
							objVal =  Boolean.valueOf(recordMap.get(apiName));
						}else if(columnType.get(apiName)=='date'){
							objVal = CommUtils.stringGmtToLocalDate(String.valueOf(recordMap.get(apiName)));
						}else{
							objVal = recordMap.get(apiName);
						}
						lead.put(apiName,objVal);
					}
				}
				leadLst.add(lead);
			}
			// Decimal a = Decimal.valueOf('sgx1');
			// UPDATE　ダーテの予約Id
			update leadLst;
		} catch(System.SObjectException e){
			// error += 'error:' + apiName + '--------->:' +e.getMessage();
			// continue;
			return e.getMessage();
		}
		// 2017/01/25 店舗ごとの会計権限機能対応 BEGIN
		catch (Exception ex) {
			String errMsg = ex.getMessage();
			if(CommUtils.isFieldValidationMessage(errMsg)) {
				throw new CommException(CommUtils.getFieldValidationMessage(errMsg));
			}
			throw ex;
		}
		// 2017/01/25 店舗ごとの会計権限機能対応 END
		return '';
	}
	
	/**
	* 当日の予約と料理情報レポート
	* 有効な予約データ全部取得する
	* 含めの予約データ
	* 2014/06/25 予定表画面に、ボタンを追加して、該当ボタンクリックすると、予約ありのみ表示と全表示機能連動する
	* isShowAllRoomsFlg:TRUEの場合、全て部屋を表示する
	**/
	
	// public static DataSource getReportViewInfo(String area, String queryDt) {
	// public static String getReportViewInfo(String area, String queryDt, String strTermDays) {
	// 2017/09/18 カスタマイズ定義のLINKあり項目は自動リンクを付ける対応 WGCH BEGIN
	// 2019/08/15 予定表の部屋タイプ絞り込みは予定表内のフィルター機能が改善ほしい by zy BEGIN
	public static String getReportViewInfo(String area, String queryDt, String strTermDays, String roomViewFlg, String[] foodSumJson, String isGroupAbleFlg) {
		return getReportViewInfo(area,queryDt,strTermDays,roomViewFlg,foodSumJson,isGroupAbleFlg,'');
	}
	@remoteAction
	public static String getReportViewInfo(String area, String queryDt, String strTermDays, String roomViewFlg, String[] foodSumJson, String isGroupAbleFlg,String otherInfo) {
	// 2019/08/15 予定表の部屋タイプ絞り込みは予定表内のフィルター機能が改善ほしい by zy END
	// 2017/09/18 カスタマイズ定義のLINKあり項目は自動リンクを付ける対応 WGCH END
		// 処理結果格納用
		// DataSource ds = new DataSource();
		// 2019/08/15 予定表の部屋タイプ絞り込みは予定表内のフィルター機能が改善ほしい by zy BEGIN
		// 2021/05/31 予定表のレイアウトを複数パターンから切り替えられるようにしたいユーザ単位で保存できるように by zy BEGIN
		String multiRoomIds = '';
		// 2021/05/31 予定表のレイアウトを複数パターンから切り替えられるようにしたいユーザ単位で保存できるように by zy END
		if (!CommUtils.isBlank(otherInfo)) {
			RequestInfo req = (RequestInfo)JSON.deserialize(otherInfo, RequestInfo.class);
			multiRoomTypeIds = CommUtils.nullToBlank(req.types);
			filterText = CommUtils.nullToBlank(req.filter);
			// 2021/05/31 予定表のレイアウトを複数パターンから切り替えられるようにしたいユーザ単位で保存できるように by zy BEGIN
			multiRoomIds = CommUtils.nullToBlank(req.roomIds);
			pLayoutId = Commutils.nullToBlank(req.layout);
			// 2021/05/31 #11229 bug fixed by zy BEGIN
			String spcd = CommUtils.nullToBlank(req.spcd);
			saveCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.DEPARTCODES.name(),spcd,JSON.serialize(new Map<String,object> {COOKIE_TYPE => multiRoomTypeIds,COOKIE_ROOM => multiRoomIds,COOKIE_LAYOUT => pLayoutId}));
			// 2021/05/31 #11229 bug fixed by zy END
			// 2021/05/31 予定表のレイアウトを複数パターンから切り替えられるようにしたいユーザ単位で保存できるように by zy END
		}
		// 2019/08/15 予定表の部屋タイプ絞り込みは予定表内のフィルター機能が改善ほしい by zy END
		// 2017/04/27 初期化以外の場合、GRID定義情報JSONは重複処理しない改善 BEGIN
		xmlConfigProcess(area, false);
		// 2017/04/27 初期化以外の場合、GRID定義情報JSONは重複処理しない改善 END
		// 2017/04/27 料理数目变更之后变颜色对应 BEGIN By Wgch
		// 初期Loadの場合
		// かならず「xmlConfigProcess」以後呼出
		if (isFoodSumColor) {
			isFirstLoadFlg = CommUtils.isBlank(foodSumJson[0]);
			if (detailIsShowFlg) {
				String oldPerSumaryJson = foodSumJson[0];
				// 每一行料理的oldData
				if(!CommUtils.isBlank(oldPerSumaryJson)){
					oldPerSumaryData = new Map<String, Map<String,Object>>();
					Map<String, Object> wkOldPerSumaryData = (Map<String, Object>)JSON.deserializeUntyped(oldPerSumaryJson);
					for (String key : wkOldPerSumaryData.keySet()) {
						oldPerSumaryData.put(key, (Map<String, Object>)wkOldPerSumaryData.get(key));
					}
				} else {
					oldPerSumaryData = new Map<String, Map<String,Object>>();
				}
			}
		}
		// 2017/04/27 料理数目变更之后变颜色对应 END By Wgch
		// 2017/09/18 一回のみ切替すると、常に維持する対応 WGCH BEGIN
		groupAbleFlg = Boolean.valueOf(isGroupAbleFlg);
		// 2017/09/18 一回のみ切替すると、常に維持する対応 WGCH END
		Boolean bRoomViewFlg = Boolean.valueOf(roomViewFlg);
		// データ抽出日
		Date todayDt = (String.isEmpty(queryDt)) ? Date.today() : Date.parse(queryDt);
		// 週間抽出最大日付
		Integer plusDays = String.isEmpty(strTermDays) ? 1 : Integer.valueOf(strTermDays);
		Date weekedDt  = todayDt.addDays(plusDays);
		// プランの明細から表示を行う[プランの明細取得を行う]
		Set<Id> roomIdSet = new Set<Id>();
		// 2021/05/31 部屋タイプでの絞り込みと追加で部屋でも絞り込めるようにし、 ユーザ単位で保存できるように by zy BEGIN
		Set<String> roomIds = new Set<String>();
		String roomIdStr = CommUtils.nullToBlank(multiRoomIds);
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
		// 2021/05/31 部屋タイプでの絞り込みと追加で部屋でも絞り込めるようにし、 ユーザ単位で保存できるように by zy END
		for (Room__c room : roomList) {
			if (!String.isEmpty(area)) {
				if (room.ShopInfoRef__r.ShopCode__c != area) continue;
			// 2015/09/01 多店舗機能対応 BEGIN
			} else {
				if (userInf.isShopCodePlex && !userInf.shopSt.contains(room.ShopInfoRef__r.ShopCode__c)) continue;
			}
			// 2015/09/01 多店舗機能対応 END
			// 2021/05/31 部屋タイプでの絞り込みと追加で部屋でも絞り込めるようにし、 ユーザ単位で保存できるように by zy BEGIN
			if (!roomIds.isEmpty() && !roomIds.contains(room.Id)) {
				continue;
			}
			// 2021/05/31 部屋タイプでの絞り込みと追加で部屋でも絞り込めるようにし、 ユーザ単位で保存できるように by zy END
			roomIdSet.add(room.Id);
		}
		// ******** 予約の検索条件 ********** //
		// 有効な予約データ
		String queryWhere = ' Where CancelBool__c != ' + CommConst.LEAD_ST_CANCEL_FLG;
		// 到着日は当日
		// queryWhere += ' And DAY_ONLY(convertTimezone(EntryTime__c)) = :todayDt ';
		// 到着日は週間の範囲で予約データを取得する
		queryWhere += ' And DAY_ONLY(convertTimezone(EntryTime__c)) >= :todayDt ';
		queryWhere += ' And DAY_ONLY(convertTimezone(EntryTime__c)) <  :weekedDt ';
		// 2017/09/18 予定表に表示したく無い部屋のSEQ#をカンマで複数定義するに改善対応 WGCH BEGIN
		if(!noRmSeqSet.isEmpty()) queryWhere += ' And Rroom__r.Seq__c Not in: noRmSeqSet ';
		// 2017/09/18 予定表に表示したく無い部屋のSEQ#をカンマで複数定義するに改善対応 WGCH END
		// 2019/08/15 予定表の部屋タイプ絞り込みは予定表内のフィルター機能が改善ほしい by zy BEGIN
		Set<String> roomTypes = new Set<String>(CommUtils.nullToBlank(multiRoomTypeIds).split(','));
		roomTypes.remove('');
		if (!roomTypes.isEmpty()) queryWhere += ' And refTypeOfRooms__c in: roomTypes';
		else 
		// 予約情報の部屋タイプは店舗単位条件追加 BEGIN
		if (!String.isEmpty(area)) queryWhere += ' And refTypeOfRooms__c in (select id from TypeOfRooms__c where ShopInfoRef__r.ShopCode__c = :area) ';
		// 予約情報の部屋タイプは店舗単位条件追加 END 

		// 2019/08/15 予定表の部屋タイプ絞り込みは予定表内のフィルター機能が改善ほしい by zy END
		// アサイン部屋
		// 2013/11/04 部屋アサイン以外の有効な予約も料理集計対象になる
		// queryWhere += ' And Rroom__c in :roomIdSet ';
		// 2021/05/31 部屋タイプでの絞り込みと追加で部屋でも絞り込めるようにし、 ユーザ単位で保存できるように by zy BEGIN
		if (!roomIds.isEmpty()) {
			queryWhere += ' And Rroom__c in :roomIds ';
		}
		// 2021/05/31 部屋タイプでの絞り込みと追加で部屋でも絞り込めるようにし、 ユーザ単位で保存できるように by zy END
		// ******** 予約見積もり明細の検索条件 ********** //
		// 予約見積もり明細の商品種別は「プラン」以外(プラン明細のBreakDownの見積もり明細も対象外する)
		String queryLdWhere = ' Where ParentBookingItemRef__c = null And ActionType__c NOT IN ( \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_PL) + '\', \'' +  CommUtils.escStr(CommConst.PROD_ACTION_TYPE_NO) + '\' ) ';
		// ******** 会計明細の検索条件 ********** //
		// 会計明細の商品種別「プラン」以外(会計データは集計対象が必要)
		String processType = '00';
		String queryTranWhere = ' Where Field1__r.Field39__c = :processType And ActionType__c NOT IN ( \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_PL) + '\', \'' +  CommUtils.escStr(CommConst.PROD_ACTION_TYPE_NO) + '\' ) ';
		
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
		// String queryStr = ' Select '+ queryRoomStr + ',(' + querySubStr + '),' + queryLeadStr + ' From Lead__c ' + queryWhere;
		// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH BEGIN
		// String queryStr = ' Select '+ queryLeadStr + ',(' + querySubStr + ') From Lead__c ' + queryWhere;
		// 排序取到第一个就是主预约
		String queryStr = ' Select '+ queryLeadStr + ',(' + querySubStr + ') From Lead__c ' + queryWhere + ' Order By LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c,EntryTime__c';
		// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH END
		// 存在の予約情報を取得する[到着日は指定日の有効な予約情報を取得する]
		List<Lead__c> reportLst = DataBase.query(queryStr);
		// 2019/08/15 予定表の部屋タイプ絞り込みは予定表内のフィルター機能が改善ほしい by zy BEGIN
		Set<String> contactFilter = new Set<String>();
		Set<String> leadFilter = new Set<String>();
		set<String> roomFilter = new Set<String>();
		if (!CommUtils.isBlank(filterText) && !reportLst.isEmpty()) {
			List<Id> contactIds = new List<Id>();
			Set<Id> leadIds = new Set<Id>();
			Map<String,List<Lead__c>> contactMap = new Map<String,List<Lead__c>>();
			for ( Lead__c lead : reportLst) {
				contactIds.add(lead.relcontact__c);
				leadIds.add(lead.id);
			}
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
		// 2019/08/15 予定表の部屋タイプ絞り込みは予定表内のフィルター機能が改善ほしい by zy END
		// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH BEGIN
		if(groupAbleFlg) getGrpTitlInfoMap(reportLst);
		// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH END
		historyMap = getTodayLeadHistory(reportLst);
		// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH BEGIN
		if(isShowGuestInfo) getContactData(reportLst);
		// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH END
		// 予約明細情報を格納
		List<ReportRow> repLst = new List<ReportRow>();
		// 料理集計情報を格納[Key/合計情報]
		Map<String, ReportSumRow> prodSumMap = new Map<String, ReportSumRow>();
		// 料理集計情報を格納[Key/合計情報] (チェックイン後)
		Map<String, ReportSumRow> prodSumMap2 = new Map<String, ReportSumRow>();
		// 予約データを取得を行う
		// Map<Id, List<Lead__c>> leadRoomMap = new Map<Id, List<Lead__c>>();
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
		// List<Lead__c> noAssigneLeadLst = new List<Lead__c>();
 		
		// 部屋別に予約情報に格納する
		for (Lead__c lead : reportLst) {
			/* 2014/05/07 DELETE
			// 部屋み割り合っていの場合
			if (lead.Rroom__c == null) noAssigneLeadLst.add(lead);
			else {
				if (!leadRoomMap.containsKey(lead.Rroom__c)) {
					leadRoomMap.put(lead.Rroom__c, new List<Lead__c>());
				}
				// 部屋単位の予約情報を格納する
				leadRoomMap.get(lead.Rroom__c).add(lead);
			}*/
			// 到着日日付を取得する
			Date entryDt = lead.EntryTime__c.date();
			// 2016/11/28 BUG IFX BEGIN
			if (!weekNoAssigneLeadMap.containsKey(entryDt)) continue;
			// 2016/11/28 BUG IFX END
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
			// leadIdSet.add(lead.Id);
			// すでにチェックイン済みの予約IDリストを取得して、会計明細情報を取得する
			if (!CommUtils.isBlank(lead.field298__c)) {
				// 既にチェックインの予約ID配列格納する
				checkInedIdSet.add(lead.Id);
			} else {
				// 未チェックイン予約ID配列格納する
				noCheckInIdSet.add(lead.Id);
			}
		}
		// 会計明細「プラン」以外の会計明細情報を取得する
		// ***************************************************
		// チェックイン済みの会計の関連会計IDにより、明細情報を取得する[料理のみ]
		queryTranWhere += ' And Field1__r.Relreserve__c in :checkInedIdSet ';
		// 会計明細【プラン以外」の情報を取得する、
		queryStr = queryTranStr + queryTranWhere + ' Order By Name ';
// System.debug(LoggingLevel.INFO, 'queryStr:::' + queryStr);

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
		// List<Lead__c> planLead = [select id, (select ParentBookingItemRef__c, OP__r.Name, refBooking__c, refAccountMaster__c,refAccountMaster__r.Name, Amount__c from BookingEstimateItemFgKu__r where ActionType__c = :CommConst.PROD_ACTION_TYPE_PL OR ParentBookingItemRef__c != null) From Lead__c where id in :noCheckInIdSet];
		List<Lead__c> planLead = Database.query(planQueryStr);
		/*		
		for (Lead__c l : planLead) {
			for (BookingEstimateItem__c estItem : l.BookingEstimateItemFgKu__r) {
				// 予約→商品（プラン）のBreakDown見積もり明細情報を格納する
				if (estItem.ParentBookingItemRef__c != null) {
					Id parentId = estItem.ParentBookingItemRef__c;
					if (!existBreakDownEstItemMap.containsKey(parentId)) {
						existBreakDownEstItemMap.put(parentId, new List<BookingEstimateItem__c>());
					}
					// 該当プランのBreakDown商品は料理が含めする場合、配列に追加する
					if (isCookingByWord(estItem.OP__r.Name))
						existBreakDownEstItemMap.get(parentId).add(estItem);
				}
			}
		}
		*/
		// BreakDown存在する見積もり明細（プラン）情報を格納する Map<見積もり明細PLAN、見積もり明細PLANのBreakDown情報>
		Map<Id, List<BookingEstimateItem__c>> existBreakDownEstItemMap = new Map<Id, List<BookingEstimateItem__c>>();
		// 会計明細「プラン」関連情報を取得する
		// ***************************************************
		/*
		Map<Id, List<Id>> tranPlanProdMap = new Map<Id, List<Id>>();
		Map<Id, List<Tran1__c>> tranItemMap = new Map<Id, List<Tran1__c>>();
		// 予約データ関連の会計明細に、プラン明細に料理情報を取得する
		queryTranWhere = ' Where ActionType__c = \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_PL) + '\'';
		queryTranWhere += ' And Field1__r.Field145__c in  :checkInedIdSet ';
		queryStr = queryTranStr + queryTranWhere + ' Order By Name ';
		List<Tran1__c> checkInPlanTranLst = DataBase.query(queryStr);
		*/
		// ***************************************************
		
		// 予約データからプラン含めの見積もり明細データを取得する
		Set<Id> planProdIdSet = new Set<Id>();
		// プランを含めの予約データ
		for (Lead__c l : planLead) {
			// 2013/10/25 該当プランは既にBreakDown明細が存在する場合、該当プランは検索対象外
			// 予約→商品（プラン）関連情報格納
			leadPlanProdMap.put(l.Id, new List<Id>());
			// 予約→見積もり明細リスト情報を格納する
			leadEstItemMap.put(l.Id, new List<BookingEstimateItem__c>());
			
			// if (l.BookingEstimateItemFgKu__r.size() > 0) {
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
		// Map<预约Id_商品Id, List<見積もり明細>>
		Map<String, List<BookingEstimateItem__c>> leadpEstItemIdMap = new Map<String, List<BookingEstimateItem__c>>();
		// 2019/08/13 BUG修正 WGCH BEGIN
		/*
		if(foodSummaryInfo.unitpriceColShow){
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
		// String planDlStr = ' Select PlanProdcut__c,AccountMasterRef__c, AccountMasterRef__r.OP__c, AccountMasterRef__r.OP__r.Name, AccountMasterRef__r.Field3__c, AccountMasterRef__r.Name,AccountMasterRef__r.Field5__c from PlanDetail__c where PlanProdcut__c in :planProdIdSet ';
		String planDlStr = ' Select PlanProdcut__c,AccountMasterRef__c, AccountMasterRef__r.OP__c, AccountMasterRef__r.OP__r.Name, AccountMasterRef__r.Field3__c, AccountMasterRef__r.Name,AccountMasterRef__r.Field5__c, Price__c, TaxRate__c, ServiceRate__c from PlanDetail__c where PlanProdcut__c in :planProdIdSet ';
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
		// 朝食
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
		// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 BEIGN
		Map<String,ReportSumRow> reportDetailLst = new Map<String,ReportSumRow>();
		Map<String,ReportSumRow> reportCheckinMap = new Map<String,ReportSumRow>();
		// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 END
		// 2016/01/06 朝食 不具合改修
	 	Map<String,ReportSumRow> moringFoodDetail1Map = new Map<String,ReportSumRow>();
	 	Map<String,ReportSumRow> moringFoodDetail2Map = new Map<String,ReportSumRow>();
		// 2016/01/06
		// 週間データ設定を行う
		for (Integer i=0; i < termMaxDays; i++) {
			Date keyDate = todayDt.addDays(i);
			// 2017/09/18 跨月份日期排序BUG修改对应 WGCH BEGIN
			String strKeyDate = dateTime.newinstance(keyDate.year(),keyDate.month(),keyDate.day()).format(CONST_DATEFORMAT);//keyDate.format();
			// 2017/09/18 跨月份日期排序BUG修改对应 WGCH END
			// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 BEIGN
			ReportSumRow moringFoodDetail = new ReportSumRow();
			moringFoodDetail.sortKey = CONST_MON_FOOD_CD;
			moringFoodDetail.middayIcon = '';
			// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
			moringFoodDetail.op = '';
			// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
			//朝食
			moringFoodDetail.productName = Label.CONST_041_0038; 
			// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH BEGIN
			moringFoodDetail.keyDate = strKeyDate;
			// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH END
			ReportSumRow moringFoodDetail2 = new ReportSumRow();
			moringFoodDetail2.sortKey = CONST_MON_FOOD_CD;
			moringFoodDetail2.middayIcon = '';
			// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
			moringFoodDetail2.op = '';
			// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
			//朝食
			moringFoodDetail2.productName = Label.CONST_041_0038; 
			// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH BEGIN
			moringFoodDetail2.keyDate = strKeyDate;
			// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH END
			// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
			// 根据日期key=>日期_商品code_单价
			String moringFoodDetailKey = getMoringFoodDetailKey(strKeyDate, moringFoodKey);
			moringFoodDetail1Map.put(moringFoodDetailKey, moringFoodDetail.clone());
			moringFoodDetail2Map.put(moringFoodDetailKey, moringFoodDetail2.clone());
			// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
			// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 END
			Map<Id, List<Lead__c>> leadRoomMap = weekLeadRoomMap.get(keyDate);
			/****房间LIST[BEGIN]****/
			for (Room__c room : roomList) {
				// Filter Append
				if (!String.isEmpty(area) && (room.ShopInfoRef__r.ShopCode__c != area)) continue;
				// 2015/09/01 多店舗機能対応 BEGIN
				if (userInf.isShopCodePlex && !userInf.shopSt.contains(room.ShopInfoRef__r.ShopCode__c)) continue;
				// 2015/09/01 多店舗機能対応 END
				//if (optionsAssignRoomOnlyShowFlg && !leadRoomMap.containsKey(room.Id)) continue;		// 予約割り当て部屋のみ表示の場合、該当部屋が予約データがないので、非表示する
				if (bRoomViewFlg && !leadRoomMap.containsKey(room.Id)) continue;		// 予約割り当て部屋のみ表示の場合、該当部屋が予約データがないので、非表示する
				// 2021/05/31 #11040 bug fixed by zy BEGIN
				if (!roomIds.isEmpty() && !roomIds.contains(room.Id)) continue;
				// 2021/05/31 #11040 bug fixed by zy END
				// 該当部屋の関連予約データが存在する場合
				if (leadRoomMap.containsKey(room.Id)) {
					/****予約データはVIEW LISTに格納を行う[BEGIN]****/
					// 予約データはVIEW LISTに格納を行う
					for (Lead__c lead : leadRoomMap.get(room.Id)) {
						// 2019/08/15 予定表の部屋タイプ絞り込みは予定表内のフィルター機能が改善ほしい by zy BEGIN
						if (!CommUtils.isBlank(filterText) && !contactFilter.contains(lead.relcontact__c) && !leadFilter.contains(lead.id) && !roomFilter.contains(room.id)) continue;
						// 2019/08/15 予定表の部屋タイプ絞り込みは予定表内のフィルター機能が改善ほしい by zy END
						// 基本情報を格納する
						ReportRow orgRep = new ReportRow(room, lead, idx);
						
						// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH BEGIN
						//orgRep.queryDate =  keyDate;
						orgRep.queryDate =  strKeyDate;
						// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH END
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
						// List<BookingEstimateItem__c> estItemList = new List<BookingEstimateItem__c>(lead.BookingEstimateItemFgKu__r);
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
											for(BookingEstimateItem__c pEstItem : leadpEstItemIdMap.get(key)){
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
						// 2017/04/27 料理数目变更之后变颜色对应 WGCH BEGIN
						orgRep.addAllDetailData(estItemList,lead.Id);
						// 2017/04/27 料理数目变更之后变颜色对应 WGCH END
						repLst.add(orgRep);

						// *******************************
						// 料理情報集計を行う
						// *******************************
						for(BookingEstimateItem__c item : estItemList) {
							// 処理種別は朝食する場合、個別に統計を行う
							ReportDetail tmpDetail = new ReportDetail(item);
							// String prodCd = item.Field3__c;
							// String equalKey = prodCd + '_' + orgRep.middayIcon;
							String prodName = tmpDetail.productName; //item.refAccountMaster__r.Name == null ? item.ProductName__c : item.refAccountMaster__r.Name;
							String sortKey = getCookFieldSortField(tmpDetail);
							// 2018/07/30 料理集計 WGCH BEGIN
							// 2019/05/15 料理集計「単泊」の料理数は「連泊の１泊目」に合計する機能対応 WGCH BEGIN
							// String orgRepSummaryIcon = foodNightsFlg && orgRep.summaryIcon.contains(RENPAKU) ? getFoodNightsHtml(lead, item) : orgRep.summaryIcon;
							String orgRepSummaryIcon = orgRep.summaryIcon;
							if(foodNightsFlg && orgRep.summaryIcon.contains(RENPAKU)) {
								orgRepSummaryIcon = getFoodNightsHtml(lead, item, false);
							} else if(cookingSummyCode == '1' && foodNightsFlg && foodSummaryInfo.oneNightSumFlg){
								orgRepSummaryIcon = getFoodNightsHtml(lead, item, true);
							}
							// 2019/05/15 料理集計「単泊」の料理数は「連泊の１泊目」に合計する機能対応 WGCH END
							// 2018/07/30 料理集計 WGCH END
							// チェックキー
							// String equalKey = prodName + '_' + orgRep.middayIcon;
							// 2018/07/30 料理集計 WGCH BEGIN
							// String equalKey = prodName + '_' + orgRep.summaryIcon;
							String equalKey = prodName + '_' + orgRepSummaryIcon;
							// 2018/07/30 料理集計 WGCH END
							// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
							equalKey += getUnitPriceKey(tmpDetail.unitPrice); // 连接单价作为key条件
							// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
							// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 BEIGN
							String detailKey = keyDate + '_' + equalKey;
							// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 END
							// 朝食場合
							// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
							if(item.OP__c != null) opInfoMap.put(item.OP__c, CommUtils.nullToBlank(item.OP__r.Name));
							// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
							if (moringFoodOpIdSet.contains(item.OP__c)) {
								//prodCd = CONST_MON_FOOD_CD;
								if (orgRep.isCheckIned) {
									// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
									if(!foodSummaryInfo.unitpriceColShow){
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
									if(!foodSummaryInfo.unitpriceColShow){
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
							} // 以外の場合、商品コード単位で、集計を行う
							else {
								if (orgRep.isCheckIned) {
									// 既存の商品する場合、
									if (!prodSumMap2.containsKey(equalKey)) {
										ReportSumRow newRepSum = new ReportSumRow();
										// 表示並べ替え利用するため、A_商品名でソートする
										// newRepSum.sortKey = CONST_OTHER_CD + prodName;
										newRepSum.sortKey = CONST_OTHER_CD + sortKey;
										newRepSum.productName = prodName;
										// newRepSum.middayIcon = orgRep.middayIcon;
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
									}
									// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 BEIGN
									if(!reportCheckinMap.containsKey(detailKey)){
										ReportSumRow newRepSum = new ReportSumRow();
										// 表示並べ替え利用するため、A_商品名でソートする
										// newRepSum.sortKey = CONST_OTHER_CD + prodName;
										newRepSum.sortKey = CONST_OTHER_CD + sortKey;
										newRepSum.productName = prodName;
										// newRepSum.middayIcon = orgRep.middayIcon;
										// 2018/07/30 料理集計 WGCH BEGIN
										// newRepSum.middayIcon = orgRep.summaryIcon;
										newRepSum.middayIcon = orgRepSummaryIcon;
										// 2018/07/30 料理集計 WGCH END
										// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
										newRepSum.op = CommUtils.nullToBlank(item.OP__c);
										// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
										// 2017/09/18 跨月份日期排序BUG修改对应 WGCH BEGIN
										newRepSum.keyDate = strKeyDate;
										// 2017/09/18 跨月份日期排序BUG修改对应 WGCH END
										// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
										newRepSum.unitPrice = CommUtils.nullToBlank(tmpDetail.unitPrice);
										// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
										reportCheckinMap.put(detailKey,newRepSum);
									}
									// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 END
									ReportSumRow repSum = prodSumMap2.get(equalKey);
									repSum.productSummy += CommUtils.nullToZero(item.Amount__c);
									// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 BEIGN
									ReportSumRow repDetailSum = reportCheckinMap.get(detailKey);
									repDetailSum.productSummy += CommUtils.nullToZero(item.Amount__c);
									// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 END
								} else {
									// 既存の商品する場合、
									if (!prodSumMap.containsKey(equalKey)) {
										ReportSumRow newRepSum = new ReportSumRow();
										// 表示並べ替え利用するため、A_商品名でソートする
										// newRepSum.sortKey = CONST_OTHER_CD + prodName;
										newRepSum.sortKey = CONST_OTHER_CD + sortKey;
										newRepSum.productName = prodName;
										// newRepSum.middayIcon = orgRep.middayIcon;
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
									}
									// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 BEIGN
									if(!reportDetailLst.containsKey(detailKey)){
										ReportSumRow newRepSum = new ReportSumRow();
										// 表示並べ替え利用するため、A_商品名でソートする
										// newRepSum.sortKey = CONST_OTHER_CD + prodName;
										newRepSum.sortKey = CONST_OTHER_CD + sortKey;
										newRepSum.productName = prodName;
										// newRepSum.middayIcon = orgRep.middayIcon;
										// 2018/07/30 料理集計 WGCH BEGIN
										// newRepSum.middayIcon = orgRep.summaryIcon;
										newRepSum.middayIcon = orgRepSummaryIcon;
										// 2018/07/30 料理集計 WGCH END
										// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
										newRepSum.op = CommUtils.nullToBlank(item.OP__c);
										// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
										// 2017/09/18 跨月份日期排序BUG修改对应 WGCH BEGIN
										newRepSum.keyDate = strKeyDate;
										// 2017/09/18 跨月份日期排序BUG修改对应 WGCH END
										// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
										newRepSum.unitPrice = CommUtils.nullToBlank(tmpDetail.unitPrice);
										// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
										reportDetailLst.put(detailKey,newRepSum);
									}
									// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 END
									ReportSumRow repSum = prodSumMap.get(equalKey);
									repSum.productSummy += CommUtils.nullToZero(item.Amount__c);
									// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 BEIGN
									ReportSumRow repDetailSum = reportDetailLst.get(detailKey);
									repDetailSum.productSummy += CommUtils.nullToZero(item.Amount__c);
									// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 END
								}
							}
						}
					} /****予約データはVIEW LISTに格納を行う[END]****/
				} else {
					// 2019/08/15 予定表の部屋タイプ絞り込みは予定表内のフィルター機能が改善ほしい by zy BEGIN
					if (!CommUtils.isBlank(filterText) && !roomFilter.contains(room.id)) continue;
					// 2019/08/15 予定表の部屋タイプ絞り込みは予定表内のフィルター機能が改善ほしい by zy END
					// 該当部屋に、予約データが非存在する場合
					ReportRow orgRep = new ReportRow(room, new Lead__c(), idx);
					// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH BEGIN
					orgRep.queryDate =  strKeyDate;
					// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH END
					repLst.add(orgRep);
				}
				idx++;
			} /****房间LIST[END]****/

			// 該当日付に部屋未割り当ての予約リストを取得する
			List<Lead__c> noAssigneLeadLst = weekNoAssigneLeadMap.get(keyDate);
			// 未割り合っての予約データに対して、料理集計を行う
			if (!noAssigneLeadLst.isEmpty()) {
				/****未割り合っての予約データに対して、料理集計を行うLIST[BEGIN]****/
				for (Lead__c lead : noAssigneLeadLst) {
					// 2019/08/15 予定表の部屋タイプ絞り込みは予定表内のフィルター機能が改善ほしい by zy BEGIN
					if (!CommUtils.isBlank(filterText) && !contactFilter.contains(lead.relcontact__c) && !leadFilter.contains(lead.id)) continue;
					// 2019/08/15 予定表の部屋タイプ絞り込みは予定表内のフィルター機能が改善ほしい by zy END
					// 基本情報を格納する
					ReportRow orgRep = new ReportRow(new Room__c(), lead, idx);
					// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH BEGIN
					orgRep.queryDate = strKeyDate;
					// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH END
					// 支店Filter機能
					if (!String.isEmpty(area) && (orgRep.branchShopCd != area)) continue;
					// 2015/09/01 多店舗機能対応 BEGIN
					if (userInf.isShopCodePlex && !userInf.shopSt.contains(orgRep.branchShopCd)) continue;
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
						/****プラン明細から料理の商品情報を取得する[BEGIN]****/
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
									// estItemList.add(newEstItem);
									/*
									String key = lead.Id + '_' + accMst.Id;
									if(leadpEstItemIdMap.containsKey(key)){
										List<BookingEstimateItem__c> pEstItemLst = leadpEstItemIdMap.get(key);
										for(BookingEstimateItem__c pEstItem : leadpEstItemIdMap.get(key)){
											newEstItem.X3_2__c = Commutils.nullToBlank(Commutils.nullToZero(pEstItem.Tankanonetax__c));
											newEstItem.X4_3__c = Commutils.nullToBlank(Commutils.nullToZero(pEstItem.unitPriceIncTaxCal__c));
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
						} /****プラン明細から料理の商品情報を取得する[END]****/
					}
					// 2017/04/27 料理数目变更之后变颜色对应 WGCH BEGIN
					orgRep.addAllDetailData(estItemList,lead.Id);
					// 2017/04/27 料理数目变更之后变颜色对应 WGCH END
					repLst.add(orgRep);
					// *******************************
					// 料理情報集計を行う
					// *******************************
					for(BookingEstimateItem__c item : estItemList) {
						// 2014/04/01 ADD
						ReportDetail tmpDetail = new ReportDetail(item);
						// 処理種別は朝食する場合、個別に統計を行う
						String prodName = tmpDetail.productName;//item.refAccountMaster__r.Name == null ? item.ProductName__c : item.refAccountMaster__r.Name;
						String sortKey = getCookFieldSortField(tmpDetail);
						// 2018/07/30 料理集計 WGCH BEGIN
						// 2019/05/15 料理集計「単泊」の料理数は「連泊の１泊目」に合計する機能対応 WGCH BEGIN
						// String orgRepSummaryIcon = foodNightsFlg && orgRep.summaryIcon.contains(RENPAKU) ? getFoodNightsHtml(lead, item) : orgRep.summaryIcon;
						String orgRepSummaryIcon = orgRep.summaryIcon;
						if(foodNightsFlg && orgRep.summaryIcon.contains(RENPAKU)){
							orgRepSummaryIcon = getFoodNightsHtml(lead, item, false);
						} else if(cookingSummyCode == '1' && foodNightsFlg && foodSummaryInfo.oneNightSumFlg) {
							orgRepSummaryIcon = getFoodNightsHtml(lead, item, true);
						}
						// 2019/05/15 料理集計「単泊」の料理数は「連泊の１泊目」に合計する機能対応 WGCH END
						// 2018/07/30 料理集計 WGCH END
						// チェックキー
						//String equalKey = prodName + '_' + orgRep.middayIcon;
						// 2018/07/30 料理集計 WGCH BEGIN
						// String equalKey = prodName + '_' + orgRep.summaryIcon;
						String equalKey = prodName + '_' + orgRepSummaryIcon;
						// 2018/07/30 料理集計 WGCH END
						// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
						equalKey += getUnitPriceKey(tmpDetail.unitPrice);
						// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
						// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 BEIGN
						String detailKey = keyDate + '_' + equalKey;
						// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 END
						// 朝食場合
						// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
						if(item.OP__c != null) opInfoMap.put(item.OP__c, CommUtils.nullToBlank(item.OP__r.Name));
						// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
						if (moringFoodOpIdSet.contains(item.OP__c)) {
							//　prodCd = CONST_MON_FOOD_CD;
							if (orgRep.isCheckIned) {
								// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGI
								if(!foodSummaryInfo.unitpriceColShow){
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
									// 料理数据集-防止地址共存
									ReportSumRow wkMoringFood2 = moringFood2.clone();
									// 料理数据集-防止地址共存
									ReportSumRow wkMoringFoodDetail2 = moringFoodDetail2.clone();
									// 数据置换
									if(moringFood2Map.containsKey(wkMoringFoodKey)) wkMoringFood2 = moringFood2Map.get(wkMoringFoodKey);
									if(moringFoodDetail2Map.containsKey(wkMoringFoodDetailKey)) wkMoringFoodDetail2 = moringFoodDetail2Map.get(wkMoringFoodDetailKey);
									wkMoringFood2.sortKey =  wkMoringFoodKey;
									wkMoringFoodDetail2.sortKey =  wkMoringFoodKey;
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
								if(!foodSummaryInfo.unitpriceColShow){
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
									// 获取最新的key
									String wkMoringFoodKey = getMoringFoodKey(CONST_MON_FOOD_CD, tmpDetail.unitPrice);
									// 获取多天最新的key
									String wkMoringFoodDetailKey = getMoringFoodDetailKey(strKeyDate, wkMoringFoodKey);
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
									//newRepSum.sortKey = CONST_OTHER_CD + prodName;
									newRepSum.sortKey = CONST_OTHER_CD + sortKey;
									newRepSum.productName = prodName;
									//newRepSum.middayIcon = orgRep.middayIcon;
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
								}
								// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 BEIGN
								if(!reportCheckinMap.containsKey(detailKey)){
									ReportSumRow newChkinRepSum = new ReportSumRow();
									// 表示並べ替え利用するため、A_商品名でソートする
									newChkinRepSum.sortKey = CONST_OTHER_CD + sortKey;
									newChkinRepSum.productName = prodName;
									// 2018/07/30 料理集計 WGCH BEGIN
									newChkinRepSum.middayIcon = orgRepSummaryIcon;
									// 2018/07/30 料理集計 WGCH END
									// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
									newChkinRepSum.op = CommUtils.nullToBlank(item.OP__c);
									// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
									// 2017/09/18 跨月份日期排序BUG修改对应 WGCH BEGIN
									newChkinRepSum.keyDate = strKeyDate;
									// 2017/09/18 跨月份日期排序BUG修改对应 WGCH END
									// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
									newChkinRepSum.unitPrice = CommUtils.nullToBlank(tmpDetail.unitPrice);
									// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
									reportCheckinMap.put(detailKey,newChkinRepSum);
								}
								// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 BEIGN
								ReportSumRow repSum = prodSumMap2.get(equalKey);
								repSum.productSummy += CommUtils.nullToZero(item.Amount__c);
								// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 BEIGN
								ReportSumRow repDetailSum = reportCheckinMap.get(detailKey);
								repDetailSum.productSummy += CommUtils.nullToZero(item.Amount__c);
								// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 END
							} else {
								// 既存の商品する場合、
								if (!prodSumMap.containsKey(equalKey)) {
									ReportSumRow newRepSum = new ReportSumRow();
									// 表示並べ替え利用するため、A_商品名でソートする
									//newRepSum.sortKey = CONST_OTHER_CD + prodName;
									newRepSum.sortKey = CONST_OTHER_CD + sortKey;
									newRepSum.productName = prodName;
									//newRepSum.middayIcon = orgRep.middayIcon;
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
								}
								// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 BEIGN
								if(!reportDetailLst.containsKey(detailKey)){
									ReportSumRow newRepSum = new ReportSumRow();
									// 表示並べ替え利用するため、A_商品名でソートする
									//newRepSum.sortKey = CONST_OTHER_CD + prodName;
									newRepSum.sortKey = CONST_OTHER_CD + sortKey;
									newRepSum.productName = prodName;
									// 2017/09/18 跨月份日期排序BUG修改对应 WGCH BEGIN
									newRepSum.keyDate = strKeyDate;
									// 2017/09/18 跨月份日期排序BUG修改对应 WGCH END
									//newRepSum.middayIcon = orgRep.middayIcon;
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
									reportDetailLst.put(detailKey,newRepSum);
								}
								// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 END
								ReportSumRow repSum = prodSumMap.get(equalKey);
								repSum.productSummy += CommUtils.nullToZero(item.Amount__c);
								// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 BEIGN
								ReportSumRow repDetailSum = reportDetailLst.get(detailKey);
								repDetailSum.productSummy += CommUtils.nullToZero(item.Amount__c);
								// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 END
							}
						}
					}
					idx++;
				} /****未割り合っての予約データに対して、料理集計を行うLIST[END]****/
			}
			// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 BEIGN
			// 2017/09/18 跨月份日期排序BUG修改对应 WGCH BEGIN
			// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
			// 不显示用原来的处理
			if(!foodSummaryInfo.unitpriceColShow){
				moringFoodDetail1Map.put( strKeyDate,moringFoodDetail);
				moringFoodDetail2Map.put( strKeyDate,moringFoodDetail2);
			}
			// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
			// 2017/09/18 跨月份日期排序BUG修改对应 WGCH END
			// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 END
		} // End for (Integer i=0; i < termMaxDays; i++) {
		// 朝食追加する
		if (!moringFoodOpIdSet.isEmpty()) {
			// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
			// 不显示用原来的处理
			if(!foodSummaryInfo.unitpriceColShow){
				prodSumMap2.put(CONST_MON_FOOD_CD, moringFood2);
				prodSumMap.put(CONST_MON_FOOD_CD, moringFood);
			} else {
				prodSumMap2.putAll(moringFood2Map);
				prodSumMap.putAll(moringFoodMap);
			}
			// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
			reportDetailLst.putAll(moringFoodDetail1Map);
			reportCheckinMap.putAll(moringFoodDetail2Map);
		}
		// 予約明細一覧設定
		//ds.detailRep = repLst;
		// 料理集計情報
		//ds.summaryRep = prodSumMap.values();
		//ds.summaryRep2 = prodSumMap2.values();
		// 処理情報を画面に戻る
		//return ds;
		// 予定表情報のＪＳＯＮを作成する
		JSONGenerator gen = JSON.createGenerator(false);
		gen.writeStartObject();
		// 予約情報を設定する
		gen.writeFieldName('detailRep');
		gen.writeStartArray();
		for (ReportRow rep : repLst) {
			generatorSobject(gen, rep);
		}
		gen.writeEndArray();
		// 2017/03/13 予定表の変更履歴が色でわかるように、色も一色ではなくN色自動対応 BEGIN
		gen.writeFieldName('colorJsonMap');
		gen.writeObject(K_ScheduleReport.colorJsonMap);
		// 2017/03/13 予定表の変更履歴が色でわかるように、色も一色ではなくN色自動対応 END
		// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH BEGIN
		if(groupAbleFlg){
			gen.writeFieldName('grpTitlInfoMap');
			gen.writeObject(grpTitlInfoMap);
		}
		// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH END
		// 2017/04/27 料理数目变更之后变颜色对应 BEGIN By Wgch
		// 料理集計チェック機能有効
		if (isFoodSumColor) {
			String oldSumaryJson = foodSumJson[1];
			String oldSumary2Json = foodSumJson[2];
			String oldSumaryDetJson = foodSumJson[3];
			String oldSumaryDet2Json = foodSumJson[4];
			// 2017/04/27 料理数目变更之后变颜色对应 END By Wgch
			// ご予約行単位チェック用情報を格納する
			gen.writeFieldName('perSumaryMap');
			gen.writeObject(K_ScheduleReport.perSumaryMap);
			// 料理集計情報を格納する
			Map<String, Map<String,Object>> oldSumaryData;
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
			// 複数日期間関連判断
			if(termMaxDays > 1) {
				// 第一个料理明细的oldData
				if(!CommUtils.isBlank(oldSumaryDetJson)) {
					// JSON -> OBJECT
					oldSumaryData = foodColorJsonToMap(oldSumaryDetJson);
					chkChangeForFoodSum(reportDetailLst,oldSumaryData);
				}
				// 第二个料理明细的oldData
				if(!CommUtils.isBlank(oldSumaryDet2Json)) {
					// JSON -> OBJECT
					oldSumaryData = foodColorJsonToMap(oldSumaryDet2Json);
					chkChangeForFoodSum(reportCheckinMap,oldSumaryData);
				}
			}
			// 比較用キーを設定する
			if (isFirstLoadFlg) {
				initOldDataKey(prodSumMap);
				initOldDataKey(prodSumMap2);
				initOldDataKey(reportDetailLst);
				initOldDataKey(reportCheckinMap);
			}
		}
		// 2017/04/27 料理数目变更之后变颜色对应 END By Wgch
		// 料理集計情報は設定する
		gen.writeFieldName('summaryRep');
		gen.writeObject( prodSumMap.values());
		// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 BEIGN
		if(termMaxDays > 1){
			gen.writeFieldName('summaryDsDetail');
			gen.writeObject(reportDetailLst.values());
		}
		// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 END
		gen.writeFieldName('summaryRep2');
		gen.writeObject( prodSumMap2.values());
		// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 BEIGN
		if(termMaxDays > 1){
			gen.writeFieldName('summaryDs2Detail');
			gen.writeObject(reportCheckinMap.values());
		}
		// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 END
		// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
		gen.writeFieldName('opInfo');
		gen.writeObject(opInfoMap);
		// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
		// 2019/06/14 フィルターを各アカウント毎に保持できる様にして欲しい対応 WGCH BEGIN
		if(foodSummaryInfo.summaryFilterConfigFlg){
			map<string,string> userConfigMap = UserConfigCompCtrl.getKrepConfig(userId, area);
			// 主明细板块KEY
			String configGridKey = UserConfigCompCtrl.KREP_SUBTYPE.GRID.name();
			// 料理WINDOW第一个板块KEY
			String configSummaryKey = UserConfigCompCtrl.KREP_SUBTYPE.SUMMARY.name();
			// 料理WINDOW第一个明细多天板块KEY
			String configSummaryDetlKey = UserConfigCompCtrl.KREP_SUBTYPE.SUMMARYDETL.name();
			// 料理WINDOW第二个明细板块KEY
			String configSummary2Key = UserConfigCompCtrl.KREP_SUBTYPE.SUMMARY2.name();
			// 料理WINDOW第二个明细多天板块KEY
			String configSummary2DetlKey = UserConfigCompCtrl.KREP_SUBTYPE.SUMMARY2DETL.name();
			if (userConfigMap.containsKey(configGridKey)) {
				gen.writeFieldName('gridVal');
				gen.writeObject(CommUtils.nullToBlank(userConfigMap.get(configGridKey)));
			}
			if (userConfigMap.containsKey(configSummaryKey)) {
				gen.writeFieldName('summaryVal');
				gen.writeObject(CommUtils.nullToBlank(userConfigMap.get(configSummaryKey)));
			}
			if (userConfigMap.containsKey(configSummaryDetlKey)) {
				gen.writeFieldName('summaryDetlVal');
				gen.writeObject(CommUtils.nullToBlank(userConfigMap.get(configSummaryDetlKey)));
			}
			if (userConfigMap.containsKey(configSummary2Key)) {
				gen.writeFieldName('summary2Val');
				gen.writeObject(CommUtils.nullToBlank(userConfigMap.get(configSummary2Key)));
			}
			if (userConfigMap.containsKey(configSummary2DetlKey)) {
				gen.writeFieldName('summary2DetlVal');
				gen.writeObject(CommUtils.nullToBlank(userConfigMap.get(configSummary2DetlKey)));
			}
		}
		// 2019/06/14 フィルターを各アカウント毎に保持できる様にして欲しい対応 WGCH END
		// JSON結果を戻る
		return gen.getAsString();
	}

	/** 予約情報はＪＳＯＮに転換を行う
	* 注：予約から参照項目を表示したい場合、最大２階層まで対応できる
	**/
	private static final String RELATION_KEY = '__r.';
	public static void generatorSobject(JSONGenerator gen , ReportRow rep) {
		Sobject s = rep.varlead;
		gen.writeStartObject();
		// queryLeadStr
		// String[] queryedFields = queryLeadStr.split(',');
		// カスタム設定表示項目により、
		// for(Integer index = 0;index < queryedFields.size() ;index++) {
		for (String field : jsonDataFields) {
			String apiField = field.trim();
			// Jsonにアサインするキー: ssss__r.aaa__r.xxxx -> ssss__r_aaa__r_xxxx
			String jsonKey = converDisFields  (apiField );
			// 参照関係が存在する場合
			// ssss__r.aaa__r.xxxx
			// 2017/06/06 XMLのAPI定義小文字、大文字区別されない対応 BEGIN
			// if (apiField.contains(RELATION_KEY)) {
			if (apiField.containsIgnoreCase(RELATION_KEY)) {
				// aaa__r.xxxx
				// String refFieldNm = apiField.substringAfter(RELATION_KEY);
				Integer startPt = apiField.indexOfIgnoreCase(RELATION_KEY) + RELATION_KEY.length();
				String refFieldNm = apiField.substring(startPt);
			// 2017/06/06 XMLのAPI定義小文字、大文字区別されない対応 END
				// 一階層のSOBJECT名
				// ssss__r
				String refSobjNm = apiField.substringBefore('.');
				// 二階層のSOBJECT[aaa__r.xxxx]
				// 2017/06/06 XMLのAPI定義小文字、大文字区別されない対応 BEGIN
				// if (refFieldNm.contains(RELATION_KEY)) {
				if (refFieldNm.containsIgnoreCase(RELATION_KEY)) {
				// 2017/06/06 XMLのAPI定義小文字、大文字区別されない対応 END
					// 一階層のSOBJECT取得する[ssss__r]
					Sobject refSobj = s.getSObject(refSobjNm);
					if (refSobj == null) {
						gen.writeNullField(jsonKey);
						continue;
					}
					
					// 二階層の参照関係存在する場合、二階層以上は対応しません
					// xxxx
					// 2017/06/06 XMLのAPI定義小文字、大文字区別されない対応 BEGIN
					// String twoRefFieldNm = refFieldNm.substringAfter(RELATION_KEY);
					Integer twoStartPt = refFieldNm.indexOfIgnoreCase(RELATION_KEY) + RELATION_KEY.length();
					String twoRefFieldNm = refFieldNm.substring(twoStartPt);
					// 2017/06/06 XMLのAPI定義小文字、大文字区別されない対応 END
					// Sobject Name [aaa__r]
					String twoRefSobjNm = refFieldNm.substringBefore('.');
					// Two Level Field
					Sobject twoRefSobj = refSobj.getSObject(twoRefSobjNm);
					// JSONに情報を書込する
					if (twoRefSobj == null) gen.writeNullField(jsonKey);
					else {
						Object val = twoRefSobj.get(twoRefFieldNm);
						if (val == null) gen.writeNullField(jsonKey);
						else gen.writeObjectField(jsonKey, val);
					}
				} else {
					Sobject refSobj = s.getSObject(refSobjNm);
					if (refSobj == null) gen.writeNullField(jsonKey);
					else {
						Object val = refSobj.get(refFieldNm);
						if (val == null) gen.writeNullField(jsonKey);
						else gen.writeObjectField(jsonKey, val);
					}
				}
			} else {
				Object val = s.get(apiField);
				if (val == null) gen.writeNullField(jsonKey);
				else gen.writeObjectField(jsonKey, val);
			}
		}
		//履歷一覽
		LeadHistories.LeadHistoryItem historyItem = new LeadHistories.LeadHistoryItem();
		if(historyMap.containsKey(s.id)) historyItem = historyMap.get(s.id);
		// 2017/03/13 予定表の変更履歴が色でわかるように、色も一色ではなくN色自動対応 BEGIN
		if(!Commutils.isBlank(historyItem.leadId)){
			// 为了判断 API 变更次数用的
			// 2017/04/27 为了追加根据时间来对API变背景色的处理==>>为了把Map转写成In The class WGCH BEGIN
			Map<String,HistoryData> fieldHisMap = new Map<String,HistoryData>();
			// 2017/04/27 为了追加根据时间来对API变背景色的处理==>>为了把Map转写成In The class WGCH END
			// 该Map是过滤完成后,  这笔Lead里 所有API 显示颜色的数据源
			Map<String,HistoryColor> rowDataColorJson = new Map<String,HistoryColor>();
			String namespace = CommConst.APPOTION_NAMESPACE;
			// 既存の履歴情報から変更回数を計算する
			List<LeadHistories.ObjectHistoryLine> leadHistoryLst = historyItem.histories;
			// API単位の変更回数を集計する
			for (LeadHistories.ObjectHistoryLine item : leadHistoryLst) {
				String api = item.s.Field.toLowerCase();
				if(!CommUtils.isBlank(nameSpace) && api.startsWith(nameSpace)) api = api.substringAfter(nameSpace);
				// 2017/04/27 为了追加根据时间来对API变背景色的处理==>>为了把Map转写成In The class WGCH BEGIN
				if (!fieldHisMap.containsKey(api)) {
					HistoryData hisItem = new HistoryData();
					hisItem.changeNo = 1;
					hisItem.theDate = item.s.CreatedDate;
					fieldHisMap.put(api, hisItem);
				} else{
					HistoryData hisItem = fieldHisMap.get(api);
					hisItem.changeNo += 1;
					// 該当項目最終変更時間の格納する
					if (hisItem.theDate < item.s.CreatedDate) hisItem.theDate = item.s.CreatedDate;
				}
				// 2017/04/27 为了追加根据时间来对API变背景色的处理==>>为了把Map转写成In The class WGCH END
			}
			// 各APIの色設定を行う
			for (String api : colorMap.keySet()) {
				String colorVal = '';
				String changeKey = api;
				if(changeKey.contains('__r')) changeKey = changeKey.split('__r')[0] + '__c';
				// 該当API変換履歴あり かつ　該当API変更履歴情報定義あり
				if (fieldHisMap.containsKey(changeKey) && colorMap.containsKey(api)) {
					// 該当ご予約データの項目の変換回数
					Integer changeNo = fieldHisMap.get(changeKey).changeNo;
					// 該当ご予約データの項目の最終変更時間
					Datetime theDate = fieldHisMap.get(changeKey).theDate;
					// colorMap：API単位の色取得定義
					HistorySetupInfo colorSetup = colorMap.get(api);
					// タグCOLOR単位のルールにより、API色情報を判定する
					// 判定ルール単位で判定する
					for(ColorType colorDataSet : colorSetup.colorLst){
						// 変換時間ロジックチェックを行う
						if((!CommUtils.isblank(colorDataSet.tmFromNo) || !CommUtils.isblank(colorDataSet.tmToNo)) && theDate != null){
							DateTime now = DateTime.now();
							Datetime tmFromDt = CommUtils.isblank(colorDataSet.tmFromNo) ? theDate.addYears(-999) : theDate.addMinutes(CommUtils.nullToIntZero(colorDataSet.tmFromNo));
							Datetime tmToDt = CommUtils.isblank(colorDataSet.tmToNo) ? theDate.addYears(999) : theDate.addMinutes(CommUtils.nullToIntZero(colorDataSet.tmToNo));
							if( now >= tmFromDt && now <= tmToDt){
								colorVal = colorDataSet.val;
								break;
							}
					 	}
					 	// 変換回数ロジックチェックを行う
					 	if (!CommUtils.isBlank(colorDataSet.fromNo) || !CommUtils.isBlank(colorDataSet.toNo)) {
							Integer fromNo = CommUtils.isBlank(colorDataSet.fromNo) ? -99999 : CommUtils.nullToIntZero(colorDataSet.fromNo);
							Integer toNo = CommUtils.isBlank(colorDataSet.toNo) ? 99999 : CommUtils.nullToIntZero(colorDataSet.toNo);
							if( fromNo <= changeNo && changeNo <= toNo){
								colorVal = colorDataSet.val;
								break;
						 	}
					 	}
					 	// 変更すると、色設定の場合
					 	if (colorDataSet.isOnlyColorVal()) {
					 		colorVal = colorDataSet.val;
					 		break;
					 	} 
					}
					// 2017/04/27 为了追加根据时间来对API变背景色的处理==>>为了把Map转写成In The class WGCH END
				}
				if (!CommUtils.isBlank(colorVal)) {
					// 把该API的 颜色放到这个 HistoryColor Class 里
					HistoryColor color = new HistoryColor();
					color.fontColor = bgColorFlg ? '' : colorVal;
					color.bgColor = bgColorFlg ? colorVal : '';
					rowDataColorJson.put(api,color);
				}
			}
			// 最终把 Lead 变更字段, 对应显示的颜色  放到该Map,然后之后会 放到 @remoteAction 的 JSON里
			colorJsonMap.put('history_'+historyItem.leadId,rowDataColorJson);
		}
		// 2017/03/13 予定表の変更履歴が色でわかるように、色も一色ではなくN色自動対応 End
		gen.writeFieldName('history');
		gen.writeObject(historyItem);
		// group by queryDate
		gen.writeFieldName(Label.MSG_041_0017);
		gen.writeObject(rep.queryDate);
		// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH BEGIN
		if(groupAbleFlg){
			gen.writeFieldName(Label.MSG_041_0054);
			// 2017/09/18 予定表を表示のとき、部屋順で表示できる改善対応 WGCH BEGIN
			String ldIndexNmKey = getLdIndexNmKey(rep.varlead);
			// Object 默认值【无预约的情况】
			String objVal = SORTAPI_NOLEAD; // 11位长【SEQ最多10位长** 不会冲突 ** 】
			if(grpTitlInfoMap.containsKey(ldIndexNmKey)){
				// 获取 主预约的 排序字段值
				String sortValStr = CommUtils.nullToBlank(getValueByApi(grpTitlInfoMap.get(ldIndexNmKey).lead, sortField));
				// 获取 当前LeadInexName
				String ldIndexNm = CommUtils.nullToBlank(rep.varlead.LeadIndexRef__r.Name);
				// 合成 Object
				// 指定した部屋の並び順項目値がNULLの場合、デフォルト値を設定する
				objVal = ( CommUtils.isBlank(sortValStr) ? SORTAPI_DEF_NO : CommUtils.paddingLeftZero(sortValStr, 10) ) + '__' + ldIndexNm;
			} 
			gen.writeObject(objVal);
			// 2017/09/18 予定表を表示のとき、部屋順で表示できる改善対応 WGCH END
		}
		// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH END
		//order field
		gen.writeFieldName('rowindex');
		gen.writeObject(rep.rowIndex);

		gen.writeFieldName('detailList');
		gen.writeObject(rep.detailList);
		// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH BEGIN
		if(isShowGuestInfo){
			gen.writeFieldName('contactList');
			List<ContactDetail> contactList = new List<ContactDetail>();
			String key = getContactKey(CommUtils.nullToBlank(s.get('LeadIndexSubId__c')), CommUtils.nullToBlank(getValueByApi(s, 'Rroom__c')));
			if(contactInfoMap.containsKey(key)){
				contactList = contactInfoMap.get(key);
			}
			gen.writeObject(contactList);
		}
		// 2018/06/05 同伴のお客様のお客様重要事項を合わせて予定表に表示できるように改善 WGCH END
		// 2018/02/05 手書き zyz BEGIN
		gen.writeFieldName('imgKeys');
		String imgKeys = '';
		if(!CommUtils.isBlank(CommUtils.nullToBlank(s.get('Id')))) imgKeys = CommUtils.nullToBlank(s.get('Rroom__c')) + '_' + CommUtils.nullToBlank(s.get('Id')) + userStr;
		else {
			String Datekey = CommUtils.nullToBlank(rep.queryDate).Replace('/','_');
			imgKeys = CommUtils.nullToBlank(s.get('Rroom__c')) + '_' + Datekey + userStr;
		}
		gen.writeObject(imgKeys);
		// 2018/02/05 手書き zyz END
		gen.writeEndObject();
	}
	// 2017/09/18 予定表を表示のとき、部屋順で表示できる改善対応 WGCH BEGIN
	public static String SORTAPI_NOLEAD{get{return '99999999999';}}
	public static String SORTAPI_DEF_NO{get{return '99999999998';}}
	// 2017/09/18 予定表を表示のとき、部屋順で表示できる改善対応 WGCH END
	/**
	* 画面へ戻る情報格納
	**//*
	public class DataSource {
		// 会計商品
		List<ReportRow> detailRep{get;set;}
		// 料理商品集計値
		List<ReportSumRow> summaryRep{get;set;}
		// 朝食集計値格納
		ReportSumRow moringFoodRep{get;set;}
		// 既にチェックインの料理商品集計値
		List<ReportSumRow> summaryRep2{get;set;}
		// 既にチェックインの朝食集計値格納
		ReportSumRow moringFoodRep2{get;set;}
	}*/
	
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
	
	/**
	* 部屋情報一覧を取得する「一部屋一予約で取得を行う」
	**/
	private static List<Room__c> getRoomList() {
		// 2017/09/27 予定表に表示 自定义排序 改善対応 WGCH BEGIN
		// 2018/02/02 予定表とタイムテーブルの並びを変えたい WGCH BEGIN
		/*
		String roomQueryHeader = ' Select Id, Name, TypeRoomRef__c, TypeRoomRef__r.Name, Seq__c, RoomName__c, Rnumber__c,ShopInfoRef__r.ShopCode__c,ShopInfoRef__r.Name, ' +
								 ' TypeRoomRef__r.ShopInfoRef__c,TypeRoomRef__r.ShopInfoRef__r.ShopCode__c,TypeRoomRef__r.ShopInfoRef__r.Name from Room__c ';
		*/
		String constRoomQuery = ' Id, Name, TypeRoomRef__c, TypeRoomRef__r.Name, Seq__c, RoomName__c, Rnumber__c,ShopInfoRef__r.ShopCode__c,ShopInfoRef__r.Name, ' +
								 ' TypeRoomRef__r.ShopInfoRef__c,TypeRoomRef__r.ShopInfoRef__r.ShopCode__c,TypeRoomRef__r.ShopInfoRef__r.Name ';
		// 固定定義されている項目リストを取得する && 定義小文字、大文字区別されない対応 
		String[] constLeadFields = constRoomQuery.deleteWhitespace().toLowerCase().split(',');
		// カスタム表示用項目を取得する
		Set<String> roomSqlFieldsSet = new Set<String>();
		roomSqlFieldsSet.addAll(constLeadFields);
		// 自定义排序的字段追加
		xmlSqlFieldsSet.add(sortField.split('\\.')[1].toLowerCase());
		for(String api : xmlSqlFieldsSet){
			String[] apiArr = api.toLowerCase().split('__r.');
			if(apiArr.Size() == 2 && apiArr[0] == 'rroom' && !roomSqlFieldsSet.contains(apiArr[1])){
				constRoomQuery += ' , ' + apiArr[1];
			}
		}
		String roomQueryHeader = ' Select ' + constRoomQuery + ' from Room__c ';
		// 2018/02/02 予定表とタイムテーブルの並びを変えたい WGCH END
		String ROOM_UseOfType_Fiction = CommConst.ROOM_UseOfType_Fiction;
		String roomQueryWhere  = ' Where UseOfRoom__c !=: ROOM_UseOfType_Fiction ';
		// 2017/09/18 予定表に表示したく無い部屋のSEQ#をカンマで複数定義するに改善対応 WGCH BEGIN
		if(!noRmSeqSet.isEmpty()) roomQueryWhere += ' And Seq__c Not in: noRmSeqSet ';
		// 2017/09/18 予定表に表示したく無い部屋のSEQ#をカンマで複数定義するに改善対応 WGCH END
		// 2019/08/15 予定表の部屋タイプ絞り込みは予定表内のフィルター機能が改善ほしい by zy BEGIN
		Set<String> roomTypes = new Set<String>(CommUtils.nullToBlank(multiRoomTypeIds).split(','));
		roomTypes.remove('');
		if (!roomTypes.isEmpty()) roomQueryWhere += ' And TypeRoomRef__c in: roomTypes';
		// 2021/05/31 部屋タイプでの絞り込みと追加で部屋でも絞り込めるようにし、 ユーザ単位で保存できるように by zy BEGIN
		// saveCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.DEPARTCODES.name(),defShopCode,CommUtils.nullToBlank(multiRoomTypeIds));
		// 2021/05/31 部屋タイプでの絞り込みと追加で部屋でも絞り込めるようにし、 ユーザ単位で保存できるように by zy END
		// 2019/08/15 予定表の部屋タイプ絞り込みは予定表内のフィルター機能が改善ほしい by zy END
		String roomQueryOrder  = ' Order By ' + sortField.split('\\.')[1];
		String roomQueryLimit  = ' limit 10000 ';
		String roomQueryStr = roomQueryHeader + roomQueryWhere + roomQueryOrder + roomQueryLimit;
		/*
		return [Select Id, Name, TypeRoomRef__c, TypeRoomRef__r.Name, Seq__c, RoomName__c, Rnumber__c,ShopInfoRef__r.ShopCode__c,ShopInfoRef__r.Name
								,TypeRoomRef__r.ShopInfoRef__c,TypeRoomRef__r.ShopInfoRef__r.ShopCode__c,TypeRoomRef__r.ShopInfoRef__r.Name from Room__c 
				// 2017/09/18 予定表に表示したく無い部屋のSEQ#をカンマで複数定義するに改善対応 WGCH BEGIN
				Where UseOfRoom__c != :CommConst.ROOM_UseOfType_Fiction And Seq__c Not in: noRmSeqSet 
				// 2017/09/18 予定表に表示したく無い部屋のSEQ#をカンマで複数定義するに改善対応 WGCH END
				Order By Seq__c limit 10000];
		*/				
		return Database.query(roomQueryStr);
		// 2017/09/27 予定表に表示 自定义排序 改善対応 WGCH END
	}
	/**
	* 朝食キー文字を含めの会計ＯＰのＩＤ
	**/
	private static Set<Id> getMoringFoodOpIdSet(Set<String> keySet) {
		String OrKey = 'OR';
		String queryStr = ' Select Id from OP__c where  ';
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
	* 予約項目履歴変更機能追加
	**/
	private static Map<Id, LeadHistories.LeadHistoryItem > getTodayLeadHistory(List<Lead__c> leads) {
		List<Id> leadIdLst = new List<Id>();
		for (Lead__c lead : leads) leadIdLst.add(lead.Id);
		LeadHistories his = new LeadHistories(leadIdLst);
		his.init();
		return his.resultMap;
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
				
				// 支店情報を設定する
				// ps.refTypeOfRooms__r.ShopInfoRef__r = room.ShopInfoRef__r;
				// ps.refTypeOfRooms__r.ShopInfoRef__c = room.ShopInfoRef__c;
			}

			// 予約情報を格納する
			varlead = ps;
				
			// 予約データ設定を行う
			leadId = CommUtils.nullToBlank(ps.Id);
			// 支店コード
			branchShopCd = Commutils.isBlank(ps.refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c) 
										? ''
										: CommUtils.nullToBlank(ps.refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c);
			
			// 連泊、昼など集計方式設定する
			middayIcon = CommUtils.nullToBlank(ps.Field278__c);
			/*
			if (!String.isEmpty(middayIcon)) {
				Matcher m = pTool.matcher(middayIcon);
				if(m.Matches()) middayIcon = m.group(1);
				else middayIcon = '';
			}*/
			// 昼と夜の分割で表示対応
			summaryDayIcon = CommUtils.nullToBlank(ps.DayNightCal__c);
			/*
			if (!String.isEmpty(summaryDayIcon)) {
				Matcher m = pTool.matcher(summaryDayIcon);
				if(m.Matches()) summaryDayIcon = m.group(1);
				else summaryDayIcon = '';
			}*/

			// RowIndex
			this.rowIndex = rowIndex; 
			// 明細情報
			detailList = new List<ReportDetail>();
			// チェックインステータス判別用(空白以外の場合、チェックインとして認識する)
			this.isCheckIned = !CommUtils.isBlank(ps.Field298__c) && cookInfoSplitShow;
		}
		public String leadId{get;set;}
		/*
		// Seq#
		public String roomSeqNo {get;set;}
		// R#
		public String roomRno {get;set;}
		// RoomArea
		public String branchShop{get;set;}
		*/
		public String branchShopCd{get;set;}
		/*
		// 確
		public String kakuniIcon {get;set;}
		// お部屋
		public String roomName {get;set;}
		// お部屋タイプ
		public String roomTypeName{get;set;}
		// 当日
		public String todayIcon{get;set;}
		// 到着時刻
		public String entryTime{get;set;}
		*/
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
		/*
		// Check: Check369__c
		public String checkIcon{get;set;}
		// 朝食時間
		public String breakfastTime{get;set;}
		// 朝食数
		// public Decimal breakfastNum{get;set;}
		public String breakfastNum{get;set;}
		// 指定:Field277__c
		public String finishFlg{get;set;}
		// 布団戸締
		public String closeUpIcon{get;set;}
		// 補足$ Field281__c
		public String complement{get;set;}
		// 補足 Field302__c
		public String complementArea{get;set;}
		// 予約人数 StayPersons__c
		public String stayPersons{get;set;}
		// 男性 Mans__c
		public String manCnt{get;set;}
		// 女性 Femails__c
		public String womanCnt{get;set;}
		// 小人A ChildFA__c
		public String childrenA{get;set;}
		// 小人B Childs__c
		public String childrenB{get;set;}
		// 予約名 Name
		public String leadNo{get;set;}
		// 予約タイプ ReservedType__c
		public String leadType{get;set;}
		// 夕食時間 Field293__c
		public String mealtime{get;set;}
		// 処 Field303__c
		public String placeIcon{get;set;}
		// [料]要注意 Field306__c
		public String noticeIcon{get;set;}
		// 料理補足 Field354__c
		public String cookingPlusInfo{get;set;}
		// 食事開始 Field301__c
		public String mealBeginIcon{get;set;}
		// 特記事項 Comment3__c
		public String memo{get;set;}

		// 到着日
		//public String entryDate{get;set;}
		// 会計OP
		//public String productOpName{get;set;}
		*/
		// 見積り明細情報を格納する
		List<ReportDetail> detailList{get; private set;}
		// 2017/04/27 料理数目变更之后【每一行】变颜色对应 BEGIN By Wgch
		public void addAllDetailData(List<BookingEstimateItem__c> items,String leadIdKey) {
		// 2017/04/27 料理数目变更之后【每一行】变颜色对应 END By Wgch
			// 商品明細
			detailList = new List<ReportDetail>();
			// 会計商品の名から見積り明細の商品名にコピーする
			Map<String, ReportDetail> sortMap = new Map<String, ReportDetail>();
			for (BookingEstimateItem__c s : items) {
				ReportDetail subitem = new ReportDetail(s);
				// 商品存在場合[2014/03/27 料理項目明細、商品コードで並び順表示する]
				String key = getCookFieldSortField(subitem);//subitem.productName;
				// if (sortMap.containsKey(subitem.productName)) {
				if (sortMap.containsKey(key)) {
					sortMap.get(key).amount = CommUtils.deleteRightZero(
												String.valueOf(	CommUtils.nullToZero(sortMap.get(key).amount) + 
														 		CommUtils.nullToZero(s.Amount__c)));
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
			// 2017/04/27 料理数目变更之后【每一行】变颜色对应 BEGIN By Wgch
			if (isFoodSumColor && detailIsShowFlg ) {
				// データ初期LOADのみ設定を行う
				if (isFirstLoadFlg) {
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
					if (!isFirstLoadFlg) subitem.style = xmlColorStyle();
				}
			}
			// 2017/04/27 料理数目变更之后【每一行】变颜色对应 END By Wgch
		}
		public Integer rowIndex{get;set;}

		// 見積もり明細データ
		public String productName{get;private set;}
		public String amount{get;private set;}
		// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH BEGIN
		// public Date queryDate;
		public String queryDate{get;private set;}
		// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH END
		// 予約のお客様ステータスチェックイン・未チェックイン判別用
		public Boolean isCheckIned{get; private set;}
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
			// 2017/04/27 料理数目变更之后【每一行】变颜色对应 BEGIN By Wgch
			style = '';
			// 2017/04/27 料理数目变更之后【每一行】变颜色对应 END By Wgch
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
		// 2017/04/27 料理数目变更之后【每一行】变颜色对应 BEGIN By Wgch
		// 颜色设置
		public String style {get; private set;}
		// 2017/04/27 料理数目变更之后【每一行】变颜色对应 END By Wgch
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
			// 2017/04/27 料理数目变更之后变颜色对应 BEGIN By Wgch
			style = '';
			// 2017/04/27 料理数目变更之后变颜色对应 END By Wgch
			// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
			unitPrice = '';
			// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
		}
		// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
		public String op{get;set;}
		// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
		// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 BEIGN
		public String keyDate{get;set;}
		// 2015/11/04 料理集計は日単位（７日間）グループ表示機能対応 END
		public String middayIcon{get;set;}
		public String sortKey{get;set;}
		// public String productCode{get;set;}
		public String productName{get;set;}
		public Decimal productSummy{get;set;}
		// 2017/04/27 料理数目变更之后变颜色对应 BEGIN By Wgch
		public String style{get;set;}
		public String qKey{get;set;}
		// 2017/04/27 料理数目变更之后变颜色对应 END By Wgch
		// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH BEGIN
		public String unitPrice {get; private set;}
		// 2019/02/28 予定表の料理と料理集計に単価も表記させてほしい对应 WGCH END
	}
	// 2017/04/27 料理数目变更之后变颜色对应 BEGIN By Wgch
	// jsonDate==>>Map
	private static Map<String,Map<String,ReportDetail>> perSumaryMap = new Map<String,Map<String,ReportDetail>>();
	// 上次寄存的sobj
	private static Map<String, Map<String,Object>> oldPerSumaryData;	// 予約単位明細情報
	// 画面初期表示情報Loadするがどうか判断用フラグ：TRUE：初期LOAD
	private static Boolean isFirstLoadFlg;
	// 初期取得データのキーを設定する
	public static void initOldDataKey(Map<String, ReportSumRow> newMap) {
		for(String keys : newMap.keySet()){
			ReportSumRow item = newMap.get(keys);
			item.qKey = keys;
		}
	}
	// 料理集計変更されるがどうチェック
	public static void chkChangeForFoodSum(Map<String, ReportSumRow> newMap, Map<String, Map<String, Object>> oldMap){
		for(String keys : newMap.keySet()){
			// 既存情報の場合
			if(oldMap == null || !oldMap.containsKey(keys)){
				if(!isFirstLoadFlg) prodSumColorSet(newMap, newMap.get(keys), keys);
			} else {
				Map<String, Object> oldSobj = oldMap.get(keys);
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
	public static Map<String, Map<String,Object>> foodColorJsonToMap(String oldJson){
		Map<String, Map<String,Object>> oldDataMap = new Map<String, Map<String,Object>>();
		List<Object> wkLst = (List<Object>)JSON.deserializeUntyped(oldJson);
		for ( Object wkDef : wkLst ){
			Map<String, Object> wkDefMap = (Map<String, Object>)wkDef;
			String qKey = CommUtils.nullToBlank(wkDefMap.get('qKey'));
			oldDataMap.put(qKey,wkDefMap);
		}
		return oldDataMap;
	}
	public static void prodSumColorSet(Map<String, ReportSumRow> newMap, ReportSumRow newRepItem, String keys){
		newRepItem.style = xmlColorStyle();
		newMap.put(keys,newRepItem);
	}
	// 设置对应的颜色
	public static String xmlColorStyle(){
		String bgColor = bgColorFlg ? foodSumColor :'';
		String fontColor = bgColorFlg ? '' :foodSumColor;
		return 'background-color:' + bgColor + ';color:'+ fontColor + ';';
	}
	// 2017/04/27 料理数目变更之后变颜色对应 END By Wgch
	// 2018/07/30 料理集計 WGCH BEGIN
	public static Boolean foodNightsFlg = false;
	public static final String RENPAKU = Label.MSG_041_0069;
	// 2019/05/15 料理集計「単泊」の料理数は「連泊の１泊目」に合計する機能対応 WGCH BEGIN
	public static String getFoodNightsHtml(Lead__c lead, BookingEstimateItem__c item, Boolean oneNightFlg){
	// 2019/05/15 料理集計「単泊」の料理数は「連泊の１泊目」に合計する機能対応 WGCH END
		// 获取当前泊数
		Decimal nights = 0;
		String[] ldNames = CommUtils.nullToBlank(lead.Name).split(Label.CONST_008_0110);
		// 2020/06/30 BUG-FIX-#PC6917 WGCH BEGIN
		// 根据预约名获取当前第几泊无效标识FLG, TRUE: 获得无效的泊数; FLASE: 获取有效的泊数;
		Boolean isInvalid = false;
		// 2020/06/30 BUG-FIX-#PC6917 WGCH END
		if(ldNames.Size() == 2 && ldNames[0].contains('-')){
			// 2020/06/30 BUG-FIX-#PC6917 WGCH BEGIN
			// nights = CommUtils.nullToZero(ldNames[0].split('-')[1]);
			// 获取当前泊数; 正确例: 正常连泊预约名前缀 ->「2-1」; 异常例: 修改连泊预约名前缀 ->「（2-1）2-1」
			String gNights = CommUtils.nullToBlank(ldNames[0].split('-')[1]);
			// 判断当前获取泊数是否为有效数值; 正确例: 正常连泊预约名后的当前泊目 ->「1」; 异常例: 修改连泊预约名后的当前泊目 ->「 1）2 」
			if(Pattern.matches('[0-9]*', gNights)) nights = CommUtils.nullToZero(gNights);
			// 获得无效的泊数
			else isInvalid = true;
			// 2020/06/30 BUG-FIX-#PC6917 WGCH END
		}
		// 2019/05/15 料理集計「単泊」の料理数は「連泊の１泊目」に合計する機能対応 WGCH BEGIN
		if(oneNightFlg) nights = 1;
		// 2019/05/15 料理集計「単泊」の料理数は「連泊の１泊目」に合計する機能対応 WGCH END
		// 2020/06/30 BUG-FIX-#PC6917 WGCH BEGIN
		// String foodNightsHtml = '<div alt="' + nights + Label.MSG_041_0070 + '" style="width: 100%; height: 100%; background-color: $_BGCOLOR_$">' + nights + Label.MSG_041_0070 + '</div>';
		// 获取有效的泊数的显示效果-> 「1泊」; 获得无效的泊数的显示效果-> 「 泊」;
		String nightsLab = (isInvalid ? '　' : CommUtils.nullToBlank(nights)) + Label.MSG_041_0070;
		// 当前LaoutHTML作成处理
		String foodNightsHtml = '<div alt="' + nightsLab + '" style="width: 100%; height: 100%; background-color: $_BGCOLOR_$">' + nightsLab + '</div>';
		// 2020/06/30 BUG-FIX-#PC6917 WGCH END
		for(ColumnBgColor bgColorItem : columnBgColorLst){
			Integer fromNight = CommUtils.isBlank(bgColorItem.fromNight) ? -99999 : CommUtils.nullToIntZero(bgColorItem.fromNight);
			Integer toNight = CommUtils.isBlank(bgColorItem.toNight) ? 99999 : CommUtils.nullToIntZero(bgColorItem.toNight);
			// 2020/06/30 BUG-FIX-#PC6917 WGCH BEGIN
			// if( fromNight <= nights && nights <= toNight){
			// 当前有效泊目背景色設定「泊数単位料理集計場合、泊数により、背景色定義用タグ、定義省略可能、省略の場合、背景は白色で設定するCONSECUTIVENIGHTS->BACKGROUNDCOLOR」
			if(!isInvalid && fromNight <= nights && nights <= toNight){
			// 2020/06/30 BUG-FIX-#PC6917 WGCH END
				return foodNightsHtml.Replace('$_BGCOLOR_$', bgColorItem.bgColor);
		 	}
		}
		return foodNightsHtml;
	}
	// 2018/07/30 料理集計 WGCH END
	// 2017/04/26 列幅サイズ自動記憶機能対応 BEGIN
	// Cookie情報処理追加
	private static CookieInf getCookieInf (String pShopCode) {
		// DBから設定情報を取得する
		map<string,string> userConfigMap = UserConfigCompCtrl.getKrepConfig(userId, pShopCode);
		
		CookieInf inf = new CookieInf();
		
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
		// グループ機能有効の前提条件、COOKIEまたはURLから引き渡す情報でフラグを再度設定を行う
		groupAbleFlg = xmlGroupAbleFlg;
		if (xmlGroupAbleFlg) {
			String gpFlgStr = ApexPages.currentPage().getParameters().get('gpflg');
			if(!CommUtils.isBlank(gpFlgStr)) groupAbleFlg = Boolean.valueOf(gpFlgStr);
			else {
				// Cookieから前回切替パラメータを取得する
				String configGpAbFlgKey = UserConfigCompCtrl.KREP_SUBTYPE.GROUPTYPE.name();
				String configGpAbFlgVal = null;
				if (userConfigMap.containsKey(configGpAbFlgKey)) {
					configGpAbFlgVal = userConfigMap.get(configGpAbFlgKey);
				} else {
					Cookie theCookie = ApexPages.currentPage().getCookies().get(userId + pShopCode + '_K_ScheduleReport_GpAbFlg');
					if (theCookie != null) {
						configGpAbFlgVal = CommUtils.nullToBlank(theCookie.getValue());
					}  
				}
				if (configGpAbFlgVal != null) groupAbleFlg = Boolean.valueOf(configGpAbFlgVal);
			}
		}
		// 2017/09/18 一回のみ切替すると、常に維持する対応 WGCH END
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
	// 2017/04/26 列幅サイズ自動記憶機能対応 END
	// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH BEGIN
	// JSのGROUP定義情報のＪＳＯＮ作成する
	public static String foodGroupColnumJson{get; private set;}
	public static String detFoodGroupColnumJson{get; private set;}
	private static void genFoodGroupInfo() {
		foodGroupColnumJson = '[]';
		detFoodGroupColnumJson = '';
		if(!foodGroupAbleFlg) return;
		JSONGenerator gen = JSON.createGenerator(false);
		// 関連設定を行う
		gen.writeStartObject();
		gen.writeStringField('field', 'op');
		gen.writeStringField('aggregates', '$_$');
		gen.writeEndObject();
		foodGroupColnumJson = gen.getAsString();
		JSONGenerator genAgg = JSON.createGenerator(false);
		genAgg.writeStartArray();
		// 関連設定を行う
		genAgg.writeStartObject();
		genAgg.writeStringField('field','productSummy');
		genAgg.writeStringField('aggregate', 'sum');
		genAgg.writeEndObject();
		genAgg.writeEndArray();
		foodGroupColnumJson = detFoodGroupColnumJson = foodGroupColnumJson.replace('"$_$"', genAgg.getAsString());
	}
	// 2018/02/22 会計OP単位で料理表示できるように改善対応 WGCH END
	// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH BEGIN
	// JSのGROUP定義情報のＪＳＯＮ作成する
	public static String groupColnumJson{get; private set;}
	private static void genGroupInfo() {
		JSONGenerator gen = JSON.createGenerator(false);
		gen.writeStartArray();
		// 関連設定を行う
		gen.writeStartObject();
		gen.writeStringField('field',Label.MSG_041_0017);
		gen.writeEndObject();
		if(groupAbleFlg){
			gen.writeStartObject();
			gen.writeStringField('field', Label.MSG_041_0054);
			/**
			* dir: asc  // 默认升序
			* dir: desc // 降序
			* gen.writeStringField('dir', 'desc');
			*/
			gen.writeEndObject();
		}
		gen.writeEndArray();
		groupColnumJson = gen.getAsString();
	}
	// KEY: ldIndexNm VALUE : title信息(IN THE CLASS)
	private static Map<String, GroupTitleInfo> grpTitlInfoMap;
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
				// String keyDate = entryDt.format();
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
					//  KEY 转成  customLabelMap 的格式
					String disKey = converDisFields(api);
					// 此API 没有Label 或 无效 跳出 
					if(!grpTitlApiSet.contains(api) || !customLabelMap.containsKey(disKey)) continue;
					// 用预约IndexNm And API 合成Key
					// 指定項目を合計する
					if (customTypemap.containsKey(api) && customTypemap.get(api) == 'number' && grpAggrApiSet.contains(api)){
						grpItem.addTitleInfo(api, customLabelMap.get(disKey), CommUtils.nullToIntZero(getValueByApi(ld,api)),true);
					} else {
						// 親予約の場合
						if(isParentFlg) {
							// 2020/01/30 BUGFIX WGCH BEGIN 
							grpItem.lead = ld;
							// 2020/01/30 BUGFIX WGCH END
							grpItem.addTitleInfo(api, customLabelMap.get(disKey), CommUtils.nullToBlank(getValueByApi(ld,api)),false);
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
	// 2017/09/18 予定表を表示のとき、部屋順で表示できる改善対応 WGCH BEGIN
	// 用预约IndexNm And EntryTime__c 合成Key
	private static String getLdIndexNmKey(Lead__c ld){
		// KEY => ldIndexNm -- ld.EntryTime__c
		String keyDate = ld.EntryTime__c == null ? '' : ld.EntryTime__c.format(CONST_DATEFORMAT);
		return CommUtils.nullToBlank(ld.LeadIndexRef__r.Name) + '__' + keyDate;
	}
	// 2017/09/18 予定表を表示のとき、部屋順で表示できる改善対応 WGCH END
	// 每个API数据显示的模板
	// 2017/09/18 カスタマイズ定義のLINKあり項目は自動リンクを付ける対応 WSQ BEGIN
	/*
	private static String getComInfoStr(String label, String value){
		if(CommUtils.isBlank(value)) return '';
		return label + ':　' + value + '　';
	}*/
	// 2017/09/18 カスタマイズ定義のLINKあり項目は自動リンクを付ける対応 WSQ END
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
		public String getItemInfo(Id linkId){
		// 2017/09/18 カスタマイズ定義のLINKあり項目は自動リンクを付ける対応 WSQ BEGIN
		if(CommUtils.isBlank(value)) return '';
		if (!CommUtils.isBlank(linkId)) {
			return (label.escapeHtml4() + ':　<a href="/' + linkId + '" target="_blank">' + value.escapeHtml4() + '</a>　');
		} else {
			return (label + ':　' + value + '　').escapeHtml4();
		}
		//return getComInfoStr(label, value);
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
		private String grpTitlInfo;
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
			Id linkId = null;
			if(customLinkMap.containsKey(api)) {
				String linkIdApi = customLinkMap.get(api);
				linkId = CommUtils.nullToBlank(getValueByApi(lead,linkIdApi));
			}
			return titleMap.get(api).getItemInfo(linkId);
			// 2017/09/18 カスタマイズ定義のLINKあり項目は自動リンクを付ける対応 WGCH END
		}
	}
	// 参照字段对应
	private static Object getValueByApi(Sobject s ,String field) {
		// 2017/09/18 カスタマイズ定義のLINKあり項目は自動リンクを付ける対応 WGCH BEGIN
		if (s == null) return '';
		// 2017/09/18 カスタマイズ定義のLINKあり項目は自動リンクを付ける対応 WGCH END
		String apiField = field.trim();
		// Jsonにアサインするキー: ssss__r.aaa__r.xxxx -> ssss__r_aaa__r_xxxx
		String jsonKey = converDisFields  (apiField );
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
	// 2017/09/13 予定表画面、複数予約時(予約インデックスが同じ)にはまとまって表示できるように改善対応 WGCH END
	// 2018/02/05 手書き zyz BEGIN
	// 取得数据值
	@remoteAction
	public static Map<String,HandWrite__c> getImg(list<String> imgKeyArr){
		map<String,HandWrite__c> keyMap = new map<String,HandWrite__c>();
		// 2018/02/05 手書き zyz BEGIN
		Date sysDate = Date.today().addDays(-30);
		delete [select Id,Name,SetupDate__c from HandWrite__c where SetupDate__c < :sysDate limit 1000 ];
		// 2018/02/05 手書き zyz END
		list<HandWrite__c> HandwriteLst = [select Id,Name,HandWriteImg__c,Trajectory__c,ImgSize__c from HandWrite__c where Name =: imgKeyArr ];
		for(HandWrite__c hw : HandwriteLst){
			if(CommUtils.isBlank(hw.Trajectory__c)) continue;
			keyMap.put(hw.Name,hw);
		}
		return keyMap;
	}
	private static String HANDWRITE_TYPE = '予定表' ;
	//存储数据值
	@remoteAction
	// 手書Key	手書図	手書きの軌跡
	public static void saveImg(String imgKeys,String img,String trajectoryArr,String sizeStr){
		list<HandWrite__c> handWriteLst = [select Id,Name,HandWriteImg__c,Trajectory__c,ImgSize__c,SetupDate__c,DataType__c from HandWrite__c where Name =: imgKeys ];
		HandWrite__c handWriteStr = new HandWrite__c();
		if (!handWriteLst.isEmpty()) handWriteStr = handWriteLst[0];
		handWriteStr.Name = imgKeys;
		handWriteStr.HandWriteImg__c = img;
		handWriteStr.Trajectory__c = trajectoryArr;
		handWriteStr.ImgSize__c = sizeStr;
		handWriteStr.SetupDate__c = system.today();
		handWriteStr.DataType__c = HANDWRITE_TYPE;
		upsert handWriteStr;
	}
	// 2018/02/05 手書き zyz END
	// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH BEGIN
	// 单价显示模式转换处理
	public static String getUnitPrice(BookingEstimateItem__c s){
		try{
			// 2019/06/28 「サ抜税込」「サ抜税抜」の選択肢対応 WGCH BEGIN
			/*
			if(s.Id == null) {
				if(foodSummaryInfo.mode == '1') return CommUtils.isBlank(s.X3_2__c) ? '' : Commutils.nullToZero(s.X3_2__c).format();
				else if(foodSummaryInfo.mode == '2') return CommUtils.isBlank(s.X4_3__c) ? '' : Commutils.nullToZero(s.X4_3__c).format();
			} else{
				if(foodSummaryInfo.mode == '1') return s.Tankanonetax__c == null ? '' : s.Tankanonetax__c.format();
				else if(foodSummaryInfo.mode == '2') return s.unitPriceIncTaxCal__c == null ? '' : s.unitPriceIncTaxCal__c.format();
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
			// if(foodSummaryInfo.mode == '1') return (priceInfo.unitPriceIncServiceExcTax - priceServiceTax).format();
			if(foodSummaryInfo.mode == '1') return (priceInfo.unitPriceExcTax).format();
			// 2019/07/30 MODE1、4BUG修正 WGCH BEGIN
			else if(foodSummaryInfo.mode == '2') return (priceInfo.unitPriceTax).format();
			else if(foodSummaryInfo.mode == '3') return (priceInfo.unitPriceIncServiceExcTax).format();
			// 2019/07/30 MODE1、4BUG修正 WGCH BEGIN
			// else if(foodSummaryInfo.mode == '4') return (priceInfo.unitPriceTax - priceServiceTax).format();
			else if(foodSummaryInfo.mode == '4') return (priceInfo.unitPriceIncTax).format();
			// 2019/07/30 MODE1、4BUG修正 WGCH END
			// 2019/06/28 「サ抜税込」「サ抜税抜」の選択肢対応 WGCH END
		}catch (Exception e) {}
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
		return foodSummaryInfo.unitpriceColShow ? ('_' + getUnitPricePaddingLeft(unitPrice)) : '';
	}
	// 单价补位处理为了排序
	public static String getUnitPricePaddingLeft(String unitPrice){
		return CommUtils.paddingLeftZero(CommUtils.nullToBlank(unitPrice).replace(',',''), 10);
	}
	// 2019/05/15 料理集計の料理単価の表示ですが、税込金額と税別金額のどちらかを選択できるよう改善対応 WGCH END
	// 2019/05/15 予定表指定日にて、連絡事項を表示する機能対応 WGCH BEGIN
	private static final Boolean MessageShopCodeDivFlg = CommDefine__c.getOrgDefaults().MessageShopCodeDivFlg__c;
	public boolean isShowMessageCompFlg{get{return !(MessageShopCodeDivFlg && CommUtils.isBlank(branchShopNm) && branchShopLst.size() > 0);}}
	// 最新連絡事項情報取得
	public MessageItem__c messageObj{get; set;}
	public String messageDt{get; set;} // 最新連絡事項-指定日
	public String messageSpCd{get; set;} // 最新連絡事項-当前店铺code
	public List<String> msgCompSpLst{get; set;} // 最新連絡事項-当前店铺codeLst
	public void setMessageItem() {
		// 去年の年月
		Date currDate = (String.isEmpty(messageDt)) ? Date.today() : Date.parse(messageDt);
		DateTime currDt = DateTime.newInstance(currDate, Time.newInstance(0,0,0,0));
		String currYm = currDt.format('yyyyMMdd');
		messageObj = new MessageItem__c(name=currYm);
		msgCompSpLst = getMsgCompSpCdLst();
	}
	private List<String> getMsgCompSpCdLst() {
		List<String> rsList = new List<String>();
		messageSpCd = (String.isEmpty(messageSpCd)) ? '' : messageSpCd;
		// 店舗別ごと連絡事項機能不要の場合
		if (!MessageShopCodeDivFlg) rsList.add('');
		else rsList.add(messageSpCd);
		return rsList;
	}
	// 2019/05/15 予定表指定日にて、連絡事項を表示する機能対応 WGCH END
	// 2019/08/15 予定表の部屋タイプ絞り込みは予定表内のフィルター機能が改善ほしい by zy BEGIN
	// 部屋タイプ情報
	public List<SelectOption> roomTypeLst{get; private set;}
	public String roomTypeNm{get; set;}
	public static String multiRoomTypeIds{get; set;}
	// フィルター
	public static String filterText{get;set;}
	public static String defShopCode;
  	private void setInitRoomTypeLst() {
    	roomTypeLst = new List<SelectOption>();
    	// 2021/05/31 #JP10240 開発対応　by zy BEGIN
		// roomTypeNm = multiRoomTypeIds = getCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.DEPARTCODES.name(),'');
		// 2021/05/31 #JP10240 開発対応　by zy END
		List<String> typeLst = new List<String>();
		set<String> typeSet = new Set<String>(CommUtils.nullToBlank(multiRoomTypeIds).split(','));
    	List<TypeOfRooms__c> roomTypeLstRs = (new CommLogicProcess()).getTypeOfRooms(branchShopNm);
		// 2021/05/31 部屋タイプでの絞り込みと追加で部屋でも絞り込めるようにし、 ユーザ単位で保存できるように by zy BEGIN
    	Set<String> roomTypeSet = new Set<String>();
		// 2021/05/31 部屋タイプでの絞り込みと追加で部屋でも絞り込めるようにし、 ユーザ単位で保存できるように by zy END
		for (TypeOfRooms__c r : roomTypeLstRs) {
    		roomTypeLst.add(new SelectOption(r.Id, r.Name));
			if (typeSet.contains(r.Id)) typeLst.add(r.id);
			// 2021/05/31 #JP10240 開発対応　by zy BEGIN
			roomTypeSet.add(r.id);
			// 2021/05/31 #JP10240 開発対応　by zy END
		}
		if (!typeLst.isEmpty()) roomTypeNm = multiRoomTypeIds = String.join(typeLst,',');
		else roomTypeNm = multiRoomTypeIds = '';
		// 2021/05/31 #JP10240 開発対応　by zy BEGIN
		setInitRoomLst(roomTypeSet);
		// 2021/05/31 #JP10240 開発対応　by zy END
  	}
  	public static void saveCookieInfo(String subType,String spcd ,String settingInfo){
		// Cookieからレイアウトモードを取得する
		// 2021/05/31 #11229 bug fixed by zy BEGIN
		UserConfigCompCtrl.saveCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.K_REPORT,
					subType,settingInfo,UserUtil.CurrentUser.id,spcd);
		// 2021/05/31 #11229 bug fixed by zy END
	}
	public static String getCookieInfo(String subType,String spcd){
		map<String,String> userBookMap = UserConfigCompCtrl.getCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.K_REPORT,
											UserUtil.CurrentUser.id,spcd);
		String cookieInfo = CommUtils.nullToBlank(userBookMap.get(subType));
	   	return cookieInfo;
	}
	class RequestInfo{
		String types;
		String filter;
		// 2021/05/31 部屋タイプでの絞り込みと追加で部屋でも絞り込めるようにし、 ユーザ単位で保存できるように by zy BEGIN
		String roomIds;
		String layout;
		// 2021/05/31 #11229 bug fixed by zy BEGIN
		String spcd;
		// 2021/05/31 #11229 bug fixed by zy END
		// 2021/05/31 部屋タイプでの絞り込みと追加で部屋でも絞り込めるようにし、 ユーザ単位で保存できるように by zy END
	}
	// 2019/08/15 予定表の部屋タイプ絞り込みは予定表内のフィルター機能が改善ほしい by zy END
	// 2021/05/31 #JP10240 開発対応　by zy BEGIN
    public List<SelectOption> roomOpts{get;set;}
    public static String selRoomIds{get;set;}
    //　画面選択リスト項目初期化
    private void setInitRoomLst(Set<String> roomSet){
		// 画面選択リスト項目
		roomOpts = new List<SelectOption>();
		if (!roomSet.isEmpty()) {
			String roomQuery = 'select id,TypeRoomRef__c,name from Room__c where TypeRoomRef__c in :roomSet ';
			String roomQueryOrder  = ' Order By ' + sortField.split('\\.')[1];
			String roomLimit = ' limit 1000';
			// 該当店舗で部屋あり
			for (Room__c r : Database.query(roomQuery + roomQueryOrder + roomLimit)) {
				roomOpts.add(new Selectoption(r.id + '_' + r.TypeRoomRef__c,r.Name));
			}
		}
    }
    private static List<Map<String,String>> layoutOpts;
    public String layoutOptJson{get;set;}
    private static String pLayoutId;
    public String currLayoutId{get;set;}
    // 2021/05/31 #11230 bug fixed by zy BEGIN
	public static Boolean isMultiRoomFlg{get { if(isMultiRoomFlg == null) isMultiRoomFlg = true; return isMultiRoomFlg;} private set;}
	// 2021/05/31 #11230 bug fixed by zy END
    private static final String COOKIE_TYPE = 'typeIds';
	private static final String COOKIE_ROOM = 'roomIds';
	private static final String COOKIE_LAYOUT = 'layout';
	private void initCookiteInfo(String spcd,boolean hadLayoutFlg) {
		String cookStr = getCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.DEPARTCODES.name(),spcd);
		String cookieLayoutId = '';
		Map<String,String> cookieMap = new Map<String,String>();
		if (cookStr.contains(COOKIE_TYPE)) {
			cookieMap = (Map<String,String>)JSON.deserialize(cookStr, Map<String,String>.class);
			roomTypeNm = multiRoomTypeIds = cookieMap.get(COOKIE_TYPE);
			// 部屋選択Ids
			selRoomIds = Commutils.nullToBlank(cookieMap.get(COOKIE_ROOM));
			cookieLayoutId = cookieMap.get(COOKIE_LAYOUT);
		} else {
			roomTypeNm = multiRoomTypeIds = cookStr;
			// 部屋選択Ids
			selRoomIds = '';
			cookieLayoutId = '';
		}
		if (!hadLayoutFlg) {
			pLayoutId = currLayoutId = cookieLayoutId;
		}
	}
	// 2021/05/31 #JP10240 開発対応　by zy END
}