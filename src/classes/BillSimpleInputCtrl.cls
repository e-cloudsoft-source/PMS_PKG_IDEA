/*********************************************
* 会計編集機能対応(New Menu)
* STEP1:N泊1部屋対応する、該当会計に関連の予約情報の
*     1日付->1売上
*     1日付->1会計
*     会計商品に支払情報から会計支払情報に格納、表示する
* 2015/04/30 １予約N会計情報対応できる機能対応
* 2015/05/06 予約金明細情報を保存後、クリアして、別の支払メデイアで支払する場合、前受金をクリアされない問題不具合対応
* 2015/05/08 全画面並び順調整可能機能対応
* 2015/05/17 明細の利用日項目と売上と連動の対応
* 2015/06/17 予約人數は０の場合、会計可能に変更する
* 2015/06/18 明細のり用日項目と売上計上日と連動・連動しないモード対応
* 2015/07/13 利用日モード追加の対応：３→会計支払明細（前受金も含め）の利用日は売上日と一致して、紐付く、会計明細（普通商品）は到着日と紐付く
* 2015/07/16 お客様名の自動設定機能の追加
* 2015/08/14 多店舗請求書印刷機能対応
* 2015/12/24 入金確認自動チェック制御機能の追加
* 2016/02/19 ログ出力機能を追加する
* 2016/06/28 利用日設定機能追加
* 2016/09/19 売掛のご請求先存在チェックを追加する
* 2016/10/10 売掛のご請求先存在チェックを外す
* 2016/10/27 非表示機能とき、合計金額（税込）は０円でDBへ格納する、しない制御機能追加
* 2017/10/18 チェックアウト機能対応
* 2018/02/28 支払種別は「雑損」を作成したい
* 2018/03/12 連泊コメント同期機能対応
* 2018/04/27 会計書ハンコ表示・非表示機能対応
* 2018/07/27 宿泊税計算
* 2019/01/30 会計の売上計上日が自動入力機能対応
* 2019/01/30 入湯税の自動設定機能対応
* 2019/02/28 入湯税の自動設定機能連泊予約分别設定対応
* 2019/03/28 オーダーエントリー改善 レシート番号連続
* 2019/04/30 請求書の送付表新規作成
* 2019/05/15 入湯税自動入力機能の改善対応
* 2019/07/30 軽減税率機能対応
* 2020/01/30 予約作成段階では「利用日」が入力
* 2020/02/21 社内コメント項目を新規追加(共通定義により、切り替え制限可能) WSQ
*********************************************/
global with sharing class BillSimpleInputCtrl  extends CommBaseCtrl{

	/***************************
	* 定数定義を行う
	****************************/
	// 処理単位のログ記述する
	private CommLogUtils serverlog = new CommLogUtils('BillSimpleInputCtrl', true, true);
	public String clientLog{get;set;}
    // 画面データ処理ステータス変数
    private Enum PAGE_STATUS {INS,UPD,SEL,UPDSPEC}
	// 会計明細初期表示行数
	private static final Integer TRAN1_INPUT_DEF_ROWS = ( CommUtils.nullToIntZero(CommConst.APPOTION_DETAIL_DEF_INPUTLINES) == 0 
    													? 27 
    													: CommUtils.nullToIntZero(CommConst.APPOTION_DETAIL_DEF_INPUTLINES) );
    // メディア種別コード：12 DEL(共通CommConstに集中)
    private static final String MediaTypeDisCount = CommConst.MEDIA_TYPE_CD_12;
   	// 会計明細のkeyFix
   	private static final String TTEND_KEY_PREFIX = Ttend__c.sObjectType.getDescribe().getKeyPrefix();
   	// 支払アイコンデイフォルアイコン画像
   	private static final String PAYICON_DEFAULT = '/resource/' + CommConst.APPOTION_NAMESPACE + 'AppImages/payicon/pay.jpeg';
   	public String getPayiconDefault() {return PAYICON_DEFAULT;}
   	// 会計種別：プラン
	public String ACTTYPE_PLAN{get{return CommConst.PROD_ACTION_TYPE_PL;}}	// プラン
	public String ACTTYPE_PAY{get{return CommConst.PROD_ACTION_TYPE_PY;}}	// 支払
	public String ACTTYPE_AR {get{return CommConst.PROD_ACTION_TYPE_AR;}}	// 前受金
	// 支払種別
	public String ACTTYPE_PAY_DIS_RATE{get{return CommConst.PROD_PAY_TYPE_DIS_RATE;}}	// 割引
	public String ACTTYPE_PAY_DIS_PRICE{get{return CommConst.PROD_PAY_TYPE_DIS_PRICE;}}	// 値引
	public String ACTTYPE_PAY_ADD_RATE{get{return CommConst.PROD_PAY_TYPE_ADD_RATE;}}	// 割増
	//private final String PAYTYPE_CASH = '現金';
	//private final String PAYTYPE_CARD = 'カード';
	// 支払メディア種別
	public String MEDIA_TYPE_COPON		{get{return CommConst.MEDIA_TYPE_11;}}
	public String MEDIA_TYPE_DISCOUNT	{get{return CommConst.MEDIA_TYPE_12;}}
	// ０円自動非表示設定機能
	public Boolean commNoShowRequestFlg {get{return CommDefine__c.getOrgDefaults().NoShowRequestFlg__c;}}
	// 会計書ポップアップ情報を表示・非表示制御フラグ
	public Boolean accountPopupIsShowFlg{get{return CommDefine__c.getOrgDefaults().AccountPopupIsShow__c;}}
	// 2016/07/04 会計書の領収書欄を表示する・しない選択できる制御フラグ zyz
	public Boolean accountReceiptOptIsShow{get{return CommConst.APPOTION_RECEIPT_ISSHOW_FLG;}}
	// 会計書統合印刷表示フラグ
	public Boolean accountPrintTypeIsShowFlg{get{return CommDefine__c.getOrgDefaults().AccountPrintType__c;}}
	// ハンコ表示
	public Boolean billStampIsShowFlg{get{return CommConst.Bill_STAMPISSHOW_FLG;}}
	// 新会計利用日モード[1:利用日は格納だけ、売上と関係なし、２：利用日＝売上計上日で明細は売上に紐付く、３：会計支払は利用日は売上日と一致、会計明細は到着日と紐付く]
	public Boolean useDateSimpleMode{get{String mode = CommUtils.nullToblank(CommDefine__c.getOrgDefaults().AccountUseDateMode__c); return (mode == '1' || CommUtils.isBLank(mode));}}
	public Boolean useDateMiddleMode{get{return CommDefine__c.getOrgDefaults().AccountUseDateMode__c == '3';}}
	// 2015/12/24 入金確認自動チェック制御機能の追加
	public Boolean isAccountPaidFlg{get{return CommDefine__c.getOrgDefaults().AccountPaidFlg__c;}}
	// 2016/01/12 領収書日付デフォルト値設定制御変更
	private final static Boolean accountReceiptDateDefValSetFlg = CommDefine__c.getOrgDefaults().AccountReceiptDateDefValSetFlg__c;
	// 2019/11/30 会計の領収証日付値の自動設定制御モード機能対応 WGCH BEGIN
	private final static String accountReceiptDateDefValSetMode{get{return CommConst.ACCOUNT_RECEIPTDATE_MODE;}}
	// 2019/11/30 会計の領収証日付値の自動設定制御モード機能対応 WGCH END
	// 2016/10/27 非表示機能とき、合計金額（税込）は０円でDBへ格納する、しない制御機能追加
	//public static Boolean accountNoSetAmountWhenNoShowFlg{get{return CommDefine__c.getOrgDefaults().AccountNoSetAmountWhenNoShow__c;}}
	public static Boolean accountNoSetAmountWhenNoShowFlg{get{return CommConst.APPOTION_ACCOUNTNOSHOW_FLG;}}
	// 2020/01/30 非表示の一括解除、あるいは金額を0円にしない非表示設定の追加 WGCH BEGIN
	public final static String APPOTION_ACCOUNTNOSHOW_1 = CommConst.APPOTION_ACCOUNTNOSHOW_1;
	public static String accountNoSetAmountWhenNoShowMode{get{return CommConst.APPOTION_ACCOUNTNOSHOW_MODE;}}
	// 2020/01/30 非表示の一括解除、あるいは金額を0円にしない非表示設定の追加 WGCH END
	// 2019/04/30 請求書の送付表新規作成 BY zyz BEGIN
	public Boolean billLetterFlg{get{ return CommConst.Bill_LETTER_FLG;}}
	// 2019/04/30 請求書の送付表新規作成 BY zyz END
	/***************************
	* 画面表示用変数定義を行う
	****************************/
	// 画面に情報表示用変数う可能
	public PageInfo oPage{get; private set;}
    // 予約基本情報
    public Lead__c orgLeadSobj{get; private set;}
	// 会計基本情報[現在画面の会計情報]
	public AccountAcount__c oAcountSobj{get; private set;}
	// 会計明細【画面】
    // 2021/03/30 優化 by zy BEGIN
    public transient List<TranItem> oTranSobjLst;
    // 2021/03/30 優化 by zy END
    public LIst<TranItem> oStickyHeadList{get;private set;}
	// 画面利用する店舗コード情報[支払情報、会計商品選べるコンポネット表示の支店コード]
	public String oShopCode{get; private set;}
	// 個人組織通貨情報格納
	public String oDefaultCurrency{get{return UserUtil.getDefaultCurrency();}}
	// 該当ユーザーの関聯の施設コード
	public String oFacilityCode{get{return ShopInfoUtil.getShopFacilityCode(UserUtil.CurrentUser.ShopCode__c);}}
	/***************************
	* 変数定義を行う
	****************************/
    // 遷移先からパラメータ情報を格納する
    private Map<String,String> paramMap;
	private ApexPages.StandardController ctrl;

	// 該当会計関連の会計情報[1部屋N泊の関連会計]
	private Map<Id, AccountAcount__c> pRelAccountsMap;	// 当画面の会計と同じ部屋N泊の既存会計情報を格納する
	private List<Id> pRelAccountIdList;					// 当画面の会計と同じ部屋N泊の既存会計情報のIDを格納する
	private Map<Id, Lead__c> pRelLeadsMap;				// 指定の会計情報所属する予約情報
	private List<Id> pRelLeadIdList;					// 指定の会計情報所属する予約情報のIDリスト
	
    private Map<Id, List<TTend__c>> pExistTtendMap;		// 既存の会計支払情報は会計単位で格納変数
    private Map<Id, TTend__c> pExistTtendItemMap;		// 既存の会計支払情報を格納する

    //private Map<Id, Map<Id, TTend__c>> pArPaymentInfoMap;	// 前受け金で設定する金額
    private Map<Id, List<TTend__c>> pArPaymentInfoMap;		// 前受け金で設定する金額
    private Map<Id, List<TTend__c>> pBatchPaymentInfoMap;	// 自動チェックインで作成した会計支払情報
    // 下記変数は更新前に事前処理するため、情報を一時格納用変数
    private transient Map<Id, List<TranItem>> pTranSobjLstMap;		// 会計単位の会計明細情報
    private transient Map<Id, List<TTendItem>> pTTendSobjLstMap;	// 会計単位の会計支払情報
    private transient Map<Id, TranFooter> pTranFooterMap;			// 会計単位の会計明細合計情報格納用
    private transient Map<Id, TTendFooter> pTttendFooterMap;		// 会計単位の会計支払合計情報格納用
	private transient Map<Id, Map<Integer, Tran1__c>> pArTranInsertIdMap;		// 新規登録の前受金情報を格納する Map<会計ID、Map<RowIndex, 会計明細>> 
	private transient Set<Id> noDeleteIdSet;						// 削除対象外ID情報格納[会計支払＆会計明細]
	// 支払ボタンに定義する情報は格納する、該当支払いは支払いMediaと変換定義情報が可能
	// 前受金の場合、自動→会計処理種別は「前受金」、その以外の場合、「支払」情報を定義する
	// XMLの定義情報から取得する
	private Map<String, String> PAYMENT_MATCH_MAP = new Map<String, String>();
	public String payTypeConvertJson{get{return JSON.serialize(PAYMENT_MATCH_MAP);}}
	// 支払メデイア固定関連の会計商品[旧会計編集画面から作成した会計支払情報]
	// Map<支払メデイア名、会計商品コード>
	private Map<String, AccountMaster__c> MEDIA_PRODUCTCD_MAP = new Map<String, AccountMaster__c>();
	// 支払メニューのレイアウト設定情報格納
	public BillSimplePaymentCtrl.PageLayout payLayoutInfo{get; private set;}
	// 支払メニューのボタン設定情報格納
	private Map<String, String> payBtnInfoMap;
	// 登録済の売上期間情報を格納する[StartDate(yyyyymmdd):EndDate(yyyymmdd)]
	public String gSalesDateRangeStr{get; private set;}
	// 返金キー情報格納用
	public String refundItemString{get{return JSON.serialize(BillSimpleHelp.getRefundItemStr());}}
	// 2016/06/28 利用日設定機能追加
	public TimeManagement__c ReceiptDate{get; set;}
	// 2016/10/14 複数部屋会計処理を行う機能(Beta) BEGIN
	private boolean isMultiRoomFlg{get;private set;}
	// 2016/10/14 複数部屋会計処理を行う機能(Beta) END
	// 2018/04/27 会計書ハンコ表示・非表示機能対応 BEGIN by zh
	public Boolean accStampIsShowFlg{get{return CommConst.ACCOUNT_STAMPISSHOW_FLG;}}
	// 2018/04/27 会計書ハンコ表示・非表示機能対応 END by zh
	// 会計書のコメントの表示できる最大文字列
	public String commentMaxStrSize{get{
		// 会計情報がすでに存在する場合、該当会計に格納の店舗コードで、関連のコメントの制御情報を取得する
		String shopCd = UserUtil.CurrentUser.ShopCode__c;
		String fcCode = ShopInfoUtil.getShopFacilityCode(shopCd);
		Integer maxLen = CommRepUtils.getPdfMaxShowStringNum(fcCode);
		return (maxLen == 0 ? '255': String.valueOf(maxLen));
	}}
	//2016/12/27 会計人數自動設定機能封印 BEGIN by zh
	private static final Boolean AccounntStayPersonsAutoSetupFlg = CommDefine__c.getOrgDefaults().AccounntStayPersonsAutoSetupFlg__c == null ? false : CommDefine__c.getOrgDefaults().AccounntStayPersonsAutoSetupFlg__c;
	//2016/12/27 会計人數自動設定機能封印 END by zh
	// 2018/03/30 会計書の店舗切替を保存 WGCH BEGIN
	public String userId{get;private set;} // UserId
	public String accSpCd{get;private set;}
	public String billSpCd{get;private set;}
	public Boolean spCdCookieFlg{get{ return CommConst.ACC_SPCDSAVE_FLG;}}
	// 2018/03/30 会計書の店舗切替を保存 WGCH END
	// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH BEGIN
	public Boolean billRcptIsShowFlg{get{return CommConst.Bill_RCPTISSHOW_FLG;}}
	// 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH END
	// 2018/12/15 請求書の作成など自動繰返し機能 by zy BEGIN
	public boolean batchExcuteFlag = false;
	// 2018/12/15 請求書の作成など自動繰返し機能 by zy END
	// 2019/01/30 会計の売上計上日が自動入力機能対応 BEGIN
	public Boolean accReceiptDtAutoSetFlg{get{return (CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().AccountReceiptDtAutoSetupFlg__c) == '2' ? true : false);}}
	// 2019/01/30 会計の売上計上日が自動入力機能対応 END
	// 2019/01/30 入湯税の自動設定機能対応 WGCH BEGIN
	// 2019/02/28 入湯税の自動設定機能連泊予約分别設定対応 BEGIN
	// public TranItem accBathTaxItem;
	public List<TranItem> accBathTaxItemLst;
	public Boolean accRenpakuBathAutoSetFlg{get{return (CommDefine__c.getOrgDefaults().AccountRenpakuBathTaxAutoSetupFlg__c == null ? false : CommDefine__c.getOrgDefaults().AccountRenpakuBathTaxAutoSetupFlg__c);}}
	// 2019/02/28 入湯税の自動設定機能連泊予約分别設定対応 END
	// 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
	// public Boolean accBathTaxAutoSetFlg{get{return (CommDefine__c.getOrgDefaults().AccountBathTaxAutoSetupFlg__c == null ? false : CommDefine__c.getOrgDefaults().AccountBathTaxAutoSetupFlg__c);}}
	public static String bTaxSetMode{get{ return CommConst.PLAN_BATHTAXAUTOSET_MODE;} set;}
	public Boolean accBathTaxAutoSetFlg{get{return (CommDefine__c.getOrgDefaults().AccountBathTaxAutoSetupFlg__c == null ? false : CommDefine__c.getOrgDefaults().AccountBathTaxAutoSetupFlg__c) && bTaxSetMode == CommConst.PLAN_BATHTAXAUTOSET_1;}}
	// 2020/07/30 入湯税の自動入力機能について改善 WGCH END
	public String accBathTaxCode{get{return CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().AccountBathTaxCode__c);}}
	// 2019/01/30 入湯税の自動設定機能対応 WGCH END
	// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH BEGIN
	public Boolean bookEstUserDateFlg{get{return CommConst.BOOKEST_USERDATE_FLG;}}
	// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH END
	// 2019/10/30 会計書、請求書のマージ機能対応 WGCH BEGIN
	public Boolean isPdfMergeFlg{get{ return CommConst.ACCOUNT_PDFMERGE_FLG;} set;} // 会計書のマージ機能FLG
	// 2019/10/30 会計書、請求書のマージ機能対応 WGCH END
	// 2020/02/21 社内コメント項目を新規追加(共通定義により、切り替え制限可能) BEGIN
	// 会計画面の社内用コメント表示フラグ
	public Boolean isShowInCommentFlg{get{return CommDefine__c.getOrgDefaults().AccountIsShowInCommentFlg__c;}}
	private Map<String, String> accInCommentMap{get;set;}
	// 2020/02/21 社内コメント項目を新規追加(共通定義により、切り替え制限可能) END
	// 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH BEGIN
	// 2020/06/30 追加对应-#6540 WGCH BEGIN
	public static String shopDefCdSetMode{get{return CommConst.SHOP_DEFCODESET_MODE;}}
	// 2020/06/30 追加对应-#6523 WGCH END
	// 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH END
	// 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH BEGIN
	// 会计优化功能开关
	public Boolean limitFlg{get; private set;}
	// 会计优化最大限制行数
	public Decimal maxRows{get; private set;}
	// 会计优化最大限制提示Msg
	public String maxRowsMsg{get; private set;}
	// 会計飛ばし画面下拉列表Where条件
	public String accXmlWhereStr;
	// 画面初期URL第一次自动保存Flg
	public Boolean initUpsertFlg{get; private set;}
	// 会計飛ばし功能开关
	public Boolean accSkipTabShow{get; private set;}
	// レシートに自動印刷开关
	public Boolean autoPrintFlg{get; private set;}
	// 会計飛ばし功能レシートに自動印刷选中的会计明细IdJSON
	public String selectTranIdJson{get; set;}
	// 会計飛ばし功能レシートに自動印刷选中的支付明细IdJSON
	public String selectTTendIdJson{get; set;}
	// 会計飛ばし功能选中指定的会计对应的房间名
	public String selectSendRoomName{get; set;}
	// 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH END
	/**************************
	* 会計機能画面インスタンス化
	***************************/
	public BillSimpleInputCtrl(ApexPages.StandardController controller) {
		ctrl = controller;
	}

	
	/*************************
	* メディア名からメディアコードを取得処理
	*************************/
	private static String getMediaCodeByName(String nm) {
		/*
		if (nm == CommConst.MEDIA_TYPE_01) return CommConst.MEDIA_TYPE_CD_01;
		else if (nm == CommConst.MEDIA_TYPE_02) return CommConst.MEDIA_TYPE_CD_02;
		else if (nm == CommConst.MEDIA_TYPE_03) return CommConst.MEDIA_TYPE_CD_03;
		else if (nm == CommConst.MEDIA_TYPE_11) return CommConst.MEDIA_TYPE_CD_11;
		else if (nm == CommConst.MEDIA_TYPE_12) return CommConst.MEDIA_TYPE_CD_12;
		else if (nm == CommConst.MEDIA_TYPE_21) return CommConst.MEDIA_TYPE_CD_21;
		return '';
		*/
		return CommConst.getMediaCodeByMediaName(nm);
	}
	/*************************
	* 関聯の会計IDリストを所得する
	*************************/
	public String getRelAccountIds() {
		return JSON.serialize(pRelAccountsMap.keySet());
	}
	/************************
	* 兼務で複数店舗を指定する場合,請求書は指定店舗から印刷可能
	*************************/
	public String mulitiShops {get{
		String[] shops = ShopInfoUtil.getCanSelectShopLst(UserInfo.getUserId());
		if (shops.size() <= 1) return '';
		// 2017/07/12 複数店舗の場合、会計の店舗コードでデフォルト値を設定する BEGIN
		//UserUtil.UserShopInfo usrInf = UserUtil.getUserInfo(UserInfo.getUserId());
        // 2017/07/12 複数店舗の場合、会計の店舗コードでデフォルト値を設定する END
		String optionsHtml = '';
		for (String shop : shops) {
			String[] shopArr = shop.split(':');
			// 2017/07/12 複数店舗の場合、会計の店舗コードでデフォルト値を設定する BEGIN
			//optionsHtml += '<option value="'+shopArr[0]+'" ' + (usrInf.defaultShopCode == shopArr[0] ? ' selected ' : '') + '>' + shopArr[1] + '</option>';
			optionsHtml += '<option value="'+shopArr[0]+'" ' + (oShopCode == shopArr[0] ? ' selected ' : '') + '>' + shopArr[1] + '</option>';
			// 2017/07/12 複数店舗の場合、会計の店舗コードでデフォルト値を設定する END
		}
		return optionsHtml;
	}}
	/**
	* 初期化処理を行う
	**/
	private void initInfo(AccountAcount__c standObj) {
		// 2021/04/31 #10743 bug fixed by zy BEGIN
		isErrorFlg = false;
		// 2021/04/31 #10743 bug fixed by zy END
        // 格納用クラスの初期化を行う
        oPage = new PageInfo();
        // 戻るページ維持する
        // 2017/08/10 入金自動レシート印刷機能追加　by　zy BEGIN
        if (Apexpages.currentPage() != null) {
        	paramMap = Apexpages.currentPage().getParameters();
        } else {
        	paramMap = new Map<String,String>();
        }
         // 2017/08/10 入金自動レシート印刷機能追加　by　zy END
        // 2017/09/06 会計メッセージ項目自定義機能追加 by zy BEGIN
        // 自定义字段读取需要在数据取的前进行
		customAccountFields();
		// 2017/09/06 会計メッセージ項目自定義機能追加 by zy END
        // 明細追加の最初単位初期値
		//addTran1Unit = TRAN1_INPUT_DEF_ROWS;
		// 関連情報格納用変数初期化する
		pRelAccountsMap = new Map<Id, AccountAcount__c>();	// 1部屋N泊既に作成した会計情報を格納する
		pRelAccountIdList = new List<Id>();					// 1部屋N泊既に作成した会計IDを格納する
		pRelLeadsMap = new Map<Id, Lead__c>();				// 開いた会計の関連の予約情報リストを格納する
		pRelLeadIdList = new List<Id>();					// 開いた会計の関連の予約IDリストを格納する
		// 2020/02/21 社内コメント項目を新規追加(共通定義により、切り替え制限可能) BEGIN
		userId = UserInfo.getUserId();
		accSpCd = UserUtil.getAccSpCd(userId);
		billSpCd = UserUtil.getBillSpCd(userId);
		if (isShowInCommentFlg) accInCommentMap = new Map<String, String>();
		// 2020/02/21 社内コメント項目を新規追加(共通定義により、切り替え制限可能) BEGIN
		// 2016/06/28 利用日設定機能追加
		ReceiptDate = new TimeManagement__c();
		// 2016/10/14 複数部屋会計処理を行う機能(Beta) BEGIN
		parseBookingApp();
		// 2016/10/14 複数部屋会計処理を行う機能(Beta) END
        // データは新規の場合、当日の会計のみ入力可能
        //if (standObj.Id == null) {
        if (standObj.Id == null && !isMultiRoomFlg) {
            // 新規表示用情報を設定する
            oPage.dataStatus = PAGE_STATUS.INS;
            // 2018/03/12 連泊コメント同期機能対応 WGCH BEGIN
            if(isAccountSyncCommentFlg) getOneRoomAcc(standObj);
            // 2018/03/12 連泊コメント同期機能対応 WGCH END
            // 基本情報を格納用
			oAcountSobj = standObj.clone(true,true);
        }
        // データはすでに存在の場合、該当会計関連の同じ予約INDEXの会計情報を一括取得を行う
        else {
             // 画面編集フラグを設定する
            oPage.dataStatus = PAGE_STATUS.UPD;
            // 既存会計情報を取得する
            if (!refreshAccoutAcountInfo(standObj.Id)) return;
			// 会計書関連情報の自動初期化設定
			// 会計宛名
			if(CommUtils.isBlank(oAcountSobj.AccountName__c)){
				oAcountSobj.AccountName__c = oAcountSobj.ContactName__c;
			}
			// 請求書宛名
			if(CommUtils.isBlank(oAcountSobj.AccountReceiptName__c)){
				oAcountSobj.AccountReceiptName__c = oAcountSobj.BillingCal__c;
			}
			// 2016/06/28 利用日設定機能追加 BEGIN
			// 入金日
			if(oPage.isReceipt && oAcountSobj.ReceiptDt__c != null){
				ReceiptDate.workDay__c = oAcountSobj.ReceiptDt__c.date();
			}
			// 2016/06/28 利用日設定機能追加 END
        }
       	// 関聯の予約情報を取得する
    	getRelLeadInfo(oAcountSobj.Relreserve__c, oAcountSobj.Field57__c);
        // 店舗コード情報設定を行う
        oShopCode = CommUtils.isBlank(oAcountSobj.ShopCode__c) ? UserUtil.CurrentUser.ShopCode__c : oAcountSobj.ShopCode__c;
		// 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH BEGIN
		// 获取店铺默认设定Code
		// 2020/06/30 BUG-FIX-#6523 WGCH BEGIN
		oShopCode = ShopInfoUtil.getShopDefCd(oShopCode, oAcountSobj.ShopCode__c, UserUtil.CurrentUser.ShopCode__c, (oAcountSobj.Relreserve__c != null));
		// 2020/06/30 BUG-FIX-#6523 WGCH BEGIN
		// 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH END
		// 支払メディア情報のXML設定情報取得
		setPaymentToPayMeidaXml();
//System.debug(logginglevel.error, 'pRelAccountIdList:::'+pRelAccountIdList);        
//System.debug(logginglevel.error, 'pExistTtendMap:::'+pExistTtendMap); 
		// 2019/01/30 入湯税の自動設定機能対応 WGCH BEGIN
		setAccBathTaxItem();
		// 2019/01/30 入湯税の自動設定機能対応 WGCH END       
        // 関連情報を設定を行う
        refreshTTendInfo(pRelAccountIdList);					// 会計支払情報初期化
        refreshTran1Info(pRelAccountIdList, pExistTtendMap);	// 会計明細情報初期化
		// 2014/04/04 売上計上日初期化
		oAcountSobj.SalesDate__c = oAcountSobj.frs__c == null ? Date.today() : oAcountSobj.frs__r.Salesday__c;
		// 2014/04/29 領収書日付
		// 2016/01/12 領収書日付デフォルト値設定制御変更 BEGIN
		/*
		if (oAcountSobj.AccountReceiptDate__c == null ) {
			oAcountSobj.AccountReceiptDate__c = oAcountSobj.SalesDate__c;
		}*/
		// 2016/01/12 領収書日付デフォルト値設定制御変更 END
		// 2017/07/03 device fonig 機能追加　by　zy BEGIN
		initDeviceConfig();
		//2017/03/17 お釣りプリンター機能　by zy BEGIN
		//chargeJson();
		//2017/03/17 お釣りプリンター機能　by zy END
		//2017/02/16 打印响应 by zy BEGIN
		//if(printReadyState) { printIncludeIp = JSON.serialize(OrderServiceHelp.getIpSet());}
		//2017/02/16 打印响应 by zy END
		// 2017/07/03 device fonig 機能追加　by　zy END
		// 2019/11/30 会計の領収証日付値の自動設定制御モード機能対応 WGCH BEGIN
		if(oAcountSobj.Field53__c != null){
			// 到着日の日付で設定する
			if(accountReceiptDateDefValSetMode == CommConst.ACCOUNT_RECEIPTDATE_2){
				if(oAcountSobj.Relreserve__c != null && oAcountSobj.Relreserve__r.EntryTime__c != null){
					oAcountSobj.AccountReceiptDate__c = oAcountSobj.Relreserve__r.EntryTime__c.date();
				}
			}
			// 出発日の日付で設定する
			else if(accountReceiptDateDefValSetMode == CommConst.ACCOUNT_RECEIPTDATE_3){
				if(oAcountSobj.Relreserve__c != null && oAcountSobj.Relreserve__r.Departure__c != null){
					oAcountSobj.AccountReceiptDate__c = oAcountSobj.Relreserve__r.Departure__c.date();
				}
			}
		}
		// 2019/11/30 会計の領収証日付値の自動設定制御モード機能対応 WGCH END
		// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
		initHonor();
		// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
		transRowInt = TRAN1_INPUT_DEF_ROWS;
	}
	//2017/03/17 お釣りプリンター機能　by zy BEGIN
	public String chargeJson{get;set;}
	public Boolean changeSwitch{get;set;}
	// 零钱放出控制，true ：指定枚数放出，false：最小金额放出
	public boolean isSetting{get;set;}
	// 2017/08/15 入金完了後印刷自動処理機能追加　by zy BEGIN
	public boolean isAutoFlag{get;set;}
	// 2017/08/15 入金完了後印刷自動処理機能追加　by zy END
	// 2017/08/18 入金自動印刷機能のドルーオプンー機能フラグ追加　by　zy　BEGIN
	private boolean isOpenDoorFlag;
	// 2017/08/18 入金自動印刷機能のドルーオプンー機能フラグ追加　by　zy　END
	private Map<String,Object> changeIpMap ; 
	private void chargeJson(){
		isSetting = false;
		// 2017/08/15 入金完了後印刷自動処理機能追加　by zy BEGIN
		//默认打开
		isAutoFlag = true;
		// 2017/08/15 入金完了後印刷自動処理機能追加　by zy END
		changeIpMap = new Map<String,Object>();
		// 2017/07/03 device fonig 機能追加　by　zy BEGIN
		//changeSwitch = false;
		// 2017/07/03 device fonig 機能追加　by　zy END
		ChangeMachineHelp help = new ChangeMachineHelp(oShopCode);
		chargeJson = help.getIpMapJson(ChangeMachineHelp.PAGETYPE_ACCOUNT);
		isSetting = help.getIsMeisuuSettingFlag();
		// 2017/08/15 入金完了後印刷自動処理機能追加　by zy BEGIN
		isAutoFlag = help.getAutoSaveAndPrintFlag();
		// 2017/08/15 入金完了後印刷自動処理機能追加　by zy END
		// 2017/08/18 入金自動印刷機能のドルーオプンー機能フラグ追加　by　zy　BEGIN
		isOpenDoorFlag = help.getOpenDoorFlag();
		// 2017/08/18 入金自動印刷機能のドルーオプンー機能フラグ追加　by　zy　END
		// 2018/04/09 釣銭機入金方式更新 BY ZY BEGIN
		oldWayFlag = help.getOldWayFlag();
		beforeChkFlag = help.getCheckBeforeOutFlag();
		// 2018/04/09 釣銭機入金方式更新 BY ZY END
		if (!CommUtils.isBlank(chargeJson)) changeSwitch = true;
		changeIpMap = help.getIpMap();
		
	}
	//2017/03/17 お釣りプリンター機能　by zy END
	/**
	* １画面から引き渡し情報により、会計情報を取得する
	**/
	public boolean isFromBookingFlexApp{get;set;}
	public String returnUrl{get;set;}
	private void parseBookingApp() {
		// パラメータチェックする　
		isMultiRoomFlg = paramMap.containsKey('p01_parid');
		// 戻るURLを取得する
		isFromBookingFlexApp = false;
		String retUrl = paramMap.get('retURL');
		if(!CommUtils.isBlank(retUrl) && retUrl.contains('BookingFlexApp')){
			isFromBookingFlexApp = true;
			returnUrl = retUrl;
		}
		//2016/11/14 白fix END
		// 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH BEGIN
		initUpsertFlg = paramMap.containsKey('up');
		// 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH END
	}
	/**
	* 予約Section関聯情報自動設定機能
	* leadId： 予約ID
	* strStayPeople ：会計側の会計人數
	**/
	private void getRelLeadInfo(Id leadId, String strStayPeople) {
		if (leadId == null) {
			// 初期値設定する
			Integer stayPeople = CommConst.getBookingMansDef() + CommConst.getBookingFemailsDef() + CommConst.getBookingChildrenDef();
			// 会計側に人數が存在する場合、優先に会計人數を表示する
			if (!CommUtils.isBLank(strStayPeople)) {
				stayPeople = CommUtils.nullToIntZero(strStayPeople);
			}
			orgLeadSobj = new Lead__c(StayPersons__c = stayPeople);
		} else {
			// 2020/03/31 会計ロック by zy BEGIN
			List<Lead__c> leads = [select Id, Name, Field298__c, Relcontact__c, Rroom__c,refTypeOfRooms__c,StayPersons__c,entrytime__c from Lead__c where id = :leadId];
			// 2020/03/31 会計ロック by zy END
			if (!leads.isEmpty()) {
				orgLeadSobj = leads[0].clone(true,true);
				if (oAcountSobj.Id == null) {
				oAcountSobj.Relreserve__r = leads[0];
				oAcountSobj.relaccount__c = leads[0].Relcontact__c;
				}
			}
			// 会計情報がすでに存在する場合、会計人數で優先で設定する
			if (oAcountSobj.Id != null && Commutils.nullToZero(strStayPeople) > 0) {
				orgLeadSobj.StayPersons__c = Commutils.nullToZero(strStayPeople) ;
			}
		}
	}
	/**
	* 会計詳細画面へ戻る
	**/
	/*
	public Pagereference gotoAccountsDetailPg() {
		return new Pagereference('/' + ctrl.getRecord().id);
	}*/
	
	// 会計支払、会計明細情報を取得SQL定義
	// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH BEGIN
	// private static final String TTendSel = CommSqlUtils.generateQueryString('TTend__c', new String[]{'Field1__r.Relreserve__c','RelAccount__r.Name', 'Field1__r.SalesdayCal__c','PayProductRef__r.ActionType__c','PayProductRef__r.Field3__c'}); //'Select CardTypeLst__c ,CouponTypeLst__c, noneaccount__c, Taxfee__c, Taishou__c, RelAccount__c, POSNo__c, OutSideAccount__c, Field9__c, Field8__c, Field7__c, Field6__c, Field5__c, Field4__c, Field3__c, Field35__c, Field34__c, Field33__c, Field32__c, Field31__c, Field30__c, Field2__c, Field29__c, Field28__c, Field27__c, Field26__c, Field25__c, Field24__c, Field23__c, Field22__c, Field21__c, Field20__c, Field1__c, Field19__c, Field18__c, Field17__c, Field16__c, Field15__c, Field14__c, Field13__c, Field10__c, SystemModstamp, Name, LastModifiedDate, LastModifiedById, LastActivityDate, IsDeleted, Id, CreatedDate, CreatedById From TTend__c ';
	// 2019/11/30 会計の領収証日付値の自動設定制御モード機能対応 WGCH BEGIN
	// 2021/03/31 会計機能のAPI Version最新化 by zy BEGIN
	private static final String TTendSel = CommSqlUtils.generateQueryString('TTend__c', new String[]{'Field1__r.Relreserve__c','RelAccount__r.Name', 'Field1__r.SalesdayCal__c','PayProductRef__r.ActionType__c','PayProductRef__r.Field3__c','Field1__r.Relreserve__r.EntryTime__c','Field1__r.Relreserve__r.Departure__c','PayProductRef__r.name'}); //'Select CardTypeLst__c ,CouponTypeLst__c, noneaccount__c, Taxfee__c, Taishou__c, RelAccount__c, POSNo__c, OutSideAccount__c, Field9__c, Field8__c, Field7__c, Field6__c, Field5__c, Field4__c, Field3__c, Field35__c, Field34__c, Field33__c, Field32__c, Field31__c, Field30__c, Field2__c, Field29__c, Field28__c, Field27__c, Field26__c, Field25__c, Field24__c, Field23__c, Field22__c, Field21__c, Field20__c, Field1__c, Field19__c, Field18__c, Field17__c, Field16__c, Field15__c, Field14__c, Field13__c, Field10__c, SystemModstamp, Name, LastModifiedDate, LastModifiedById, LastActivityDate, IsDeleted, Id, CreatedDate, CreatedById From TTend__c ';
	// 2021/03/31 会計機能のAPI Version最新化 by zy END
	// 2019/11/30 会計の領収証日付値の自動設定制御モード機能対応 WGCH END
	// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH END
	// 2016/02/19 ログ出力機能を追加する BEGIN
	//private static final String TranSel = 'Select (Select Field20__c, TaxRate__c From ParentTran1Ref__r where (TaxRate__c = null OR TaxRate__c = 0) And ParentTran1Ref__r.ActionType__c = \''+CommConst.PROD_ACTION_TYPE_PL + '\') ,Field1__r.Relreserve__c,RelAccount__r.Name,UseDate__c,PaymentType__c,Field1__r.SalesdayCal__c, UnitPriceDefKbCal__c, NoShowRequestFlg__c,PlanDetailSyncInfo__c,TaxRate__c,ServiceRate__c,SpecialTax__c,InvoiceNoShowFlg__c,ActionType__c, Field7__r.Name,Field7__r.Field3__c, rtaxsts__c, profitt__c, profitnonetax__c, profit__c, noneaccount__c, inside__c, guestRoom__c, freetotal3__c, freetotal2__c, freetotal1__c, freeprice__c, freecost__c, VoidReceiptNo__c, TankawithoutTax__c, Tankanonetax__c, TableNo__c, Subprice__c, Seq__c, RowNo__c, RelAccount__c, POSNo__c, OPcode__c, GoukeinoneTax__c, Genkaritsu__c, Field9__c, Field8__c, Field7__c, Field6__c, Field5__c, Field52__c, Field51__c, Field50__c, Field4__c, Field49__c, Field48__c, Field47__c, Field46__c, Field45__c, Field44__c, Field43__c, Field42__c, Field41__c, Field40__c, Field3__c, Field39__c, Field38__c, Field37__c, Field36__c, Field35__c, Field34__c, Field33__c, Field32__c, Field31__c, Field30__c, Field2__c, Field29__c, Field28__c, Field27__c, Field26__c, Field25__c, Field24__c, Field23__c, Field22__c, Field21__c, Field20__c, Field1__c,    Field1__r.Name    ,Field19__c, Field18__c, Field17__c, Field16__c, Field15__c, Field14__c, Field13__c, Field12__c, Field11__c, Field10__c, DivisionNameI__c, Categorya__c, Category__c, CategoryItem__c, Accountoutside__c,  Name From Tran1__c ';
	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
	// private static final String TranSel = 'Select (Select Field20__c, TaxRate__c From ParentTran1Ref__r where (TaxRate__c = null OR TaxRate__c = 0) And ParentTran1Ref__r.ActionType__c = \''+CommConst.PROD_ACTION_TYPE_PL + '\') ,Field1__r.Relreserve__c,RelAccount__r.Name,UseDate__c,PaymentType__c,Field1__r.SalesdayCal__c, UnitPriceDefKbCal__c, NoShowRequestFlg__c,PlanDetailSyncInfo__c,TaxRate__c,ServiceRate__c,SpecialTax__c,InvoiceNoShowFlg__c,ActionType__c, Field7__r.Name,Field7__r.Field3__c, RowNo__c, RelAccount__c, POSNo__c, GoukeinoneTax__c, Field7__c, Field5__c, Field4__c, Field3__c, Field2__c, Field27__c, Field25__c, Field23__c, Field22__c, Field21__c, Field20__c, Field1__c, Field1__r.Name,  Name From Tran1__c ';
	// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH BEGIN
	// private static final String TranSel = 'Select (Select Field20__c, TaxRate__c From ParentTran1Ref__r where (TaxRate__c = null OR TaxRate__c = 0) And ParentTran1Ref__r.ActionType__c = \''+CommConst.PROD_ACTION_TYPE_PL + '\') ,Field1__r.Relreserve__c,RelAccount__r.Name,UseDate__c,PaymentType__c,Field1__r.SalesdayCal__c, UnitPriceDefKbCal__c, NoShowRequestFlg__c,PlanDetailSyncInfo__c,TaxRate__c,ServiceRate__c,SpecialTax__c,InvoiceNoShowFlg__c,ActionType__c, Field7__r.Name,Field7__r.Field3__c, RowNo__c, RelAccount__c, POSNo__c, GoukeinoneTax__c, Field7__c, Field5__c, Field4__c, Field3__c, Field2__c, Field27__c, Field25__c, Field23__c, Field22__c, Field21__c, Field20__c, Field1__c, Field1__r.Name,  Name, ParentTran1Ref__c, UnitPriceDefKb__c, TankanonetaxNew__c From Tran1__c ';
	// 2019/11/30 会計の領収証日付値の自動設定制御モード機能対応 WGCH BEGIN
	private static final String TranSel = 'Select (Select Field20__c, TaxRate__c From ParentTran1Ref__r where (TaxRate__c = null OR TaxRate__c = 0) And ParentTran1Ref__r.ActionType__c = \''+CommConst.PROD_ACTION_TYPE_PL + '\') ,Field1__r.Relreserve__c,RelAccount__r.Name,UseDate__c,PaymentType__c,Field1__r.SalesdayCal__c, UnitPriceDefKbCal__c, NoShowRequestFlg__c,PlanDetailSyncInfo__c,TaxRate__c,ServiceRate__c,SpecialTax__c,InvoiceNoShowFlg__c,ActionType__c, Field7__r.Name,Field7__r.Field3__c, RowNo__c, RelAccount__c, POSNo__c, GoukeinoneTax__c, Field7__c, Field5__c, Field4__c, Field3__c, Field2__c, Field27__c, Field25__c, Field23__c, Field22__c, Field21__c, Field20__c, Field1__c, Field1__r.Name,  Name, ParentTran1Ref__c, UnitPriceDefKb__c, TankanonetaxNew__c, Field1__r.Relreserve__r.EntryTime__c, Field1__r.Relreserve__r.Departure__c From Tran1__c ';
	// 2019/11/30 会計の領収証日付値の自動設定制御モード機能対応 WGCH END
	// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH END
	// 2019/07/30 軽減税率機能対応 WGCH END
	// 2016/02/19 ログ出力機能を追加する END
	// 2016/10/14 複数部屋会計処理を行う機能(Beta) BEGIN
	private Boolean refreshAccoutAcountInfoMulti () {
		// 引き渡し予約SUBのIDにより、関連の会計情報を取得する
		// 親の明細IDを取得、該当IDの１番目部屋は親部屋として、表示する
		String subIdxStr = paramMap.get('p01_psub');	//会計したい明細IDのリスト
		String subKeyStr = paramMap.get('p01_parid');	//親部屋の明細ID
		list<string> leadSubIdx = subIdxStr.split(',');
		List<LeadIndex__c> subIdexLst = [select id ,ParentLeadIndxRef__c from LeadIndex__c where id in:leadSubIdx];
		if (subIdexLst.isEmpty()) return false;
		Id leadSubIdxId = ID.valueOf(subKeyStr);
		Id leadIdx = subIdexLst[0].ParentLeadIndxRef__c;
//system.debug(logginglevel.info, 'subIdxStr:'+subIdxStr);
//system.debug(logginglevel.info, 'subKeyStr:'+subKeyStr);
		// 予約インデックスから関連の会計情報を取得する
		// 該当予約関連の予約情報を全部自動チェックイン処理を行う
		// *************************
		// 関連の会計情報も再取得する
		// *************************
		pRelAccountsMap.clear();
		pRelAccountIdList.clear();
		pRelLeadsMap.clear();
		pRelLeadIdList.clear();
        // 2017/10/18 チェックアウト機能対応 BEGIN
        map<String,List<Lead__c>> groupLeadsMap = new map<String, List<Lead__c>>();
        // 2017/10/18 チェックアウト機能対応 END
    	Lead__c keyLead = null;
    	// 既存有効な予約情報を取得する
    	List<Lead__c> leads = [select id,EntryTime__c,Departure__c,LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c from Lead__c 
    								where LeadIndexRef__c = :leadIdx
    								And LeadIndexSubId__c = :leadSubIdx
    								//And RoomGroupNo__c = :leadGroupNo
    								And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
    								Order By LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c,EntryTime__c
    								];
    	Date startDate = null;
    	Date endDate = null;
    	for (Lead__c lead : leads) {
    		pRelLeadsMap.put(lead.Id, lead);
    		pRelLeadIdList.add(lead.Id);
			
			if (startDate == null) startDate = lead.EntryTime__c.date();
			else if (startDate > lead.EntryTime__c.date()) startDate = lead.EntryTime__c.date();
			
			if (endDate == null) endDate = lead.Departure__c.date();
			else if (endDate < lead.Departure__c.date()) endDate = lead.Departure__c.date();
			
    		if (ID.valueOf(lead.LeadIndexSubId__c) == leadSubIdxId) {
    			if (keyLead == null) keyLead = lead;
    		}
    		// 2017/10/18 チェックアウト機能対応 BEGIN
    		String key = lead.LeadIndexRef__c + '_' + lead.LeadIndexSubId__c + '_' + lead.RoomGroupNo__c;
    		if (!groupLeadsMap.containsKey(key)) groupLeadsMap.put(key, new List<Lead__c>());
    		groupLeadsMap.get(key).add(lead);
    		// 2017/10/18 チェックアウト機能対応 END
    	}
    	if (keyLead == null) keyLead = leads[0];
//system.debug(logginglevel.info, 'keyLead:'+keyLead);
//system.debug(logginglevel.info, 'pRelLeadIdList:'+pRelLeadIdList);
//system.debug(logginglevel.info, 'pRelLeadsMap:'+pRelLeadsMap);
    	// 到着日と出発日を格納する
    	if (!leads.isEmpty()) {
    		//oPage.strEntryDate = leads[0].EntryTime__c.format(CommBaseCtrl.getDateFormat());
    		//oPage.strDepartureDate = leads[leads.size()-1].Departure__c.format(CommBaseCtrl.getDateFormat());
    		oPage.strEntryDate = startDate.format();
    		oPage.strDepartureDate = endDate.format();
    	}
        // 2017/10/18 チェックアウト機能対応 BEGIN
        String keyLeadKey = keyLead.LeadIndexRef__c + '_' + keyLead.LeadIndexSubId__c + '_' + keyLead.RoomGroupNo__c;
        if (groupLeadsMap.containsKey(keyLeadKey)) {
            List<Lead__c> ketLeads = groupLeadsMap.get(keyLeadKey);
            if (ketLeads[ketLeads.size()-1].Id == keyLead.Id) isShowCheckOutBtn = true;
        }
        // 2017/10/18 チェックアウト機能対応 END
	    // 該当予約により、親会計データを取得する
		// 最新情報を取得する
		// 2017/09/06 会計メッセージ項目自定義機能追加 by zy BEGIN
		List<AccountAcount__c> billList = new List<AccountAcount__c> ();
		if ( customBillSet != null && !customBillSet.isEmpty() ) billList = queryAccount(null,keyLead.Id);
		else {
		//List<AccountAcount__c> 
			billList = [
		  Select relaccount__c, frs__c, comment__c, TeaTimeFlag__c, Target__c, TableNo__c, Seq__c, Relreserve__c, 
		      PlanNo__c, POSNo__c, OutSideAccount__c, Field99__c, Field98__c, Field97__c, Field96__c, Field95__c, 
		      Field94__c, Field93__c, Field92__c, Field91__c, Field90__c, Field89__c, Field88__c, Field87__c, 
		      Field86__c, Field85__c, Field84__c, Field83__c, Field82__c, Field81__c, Field80__c, Field7__c, 
		      Field79__c, Field78__c, Field77__c, Field76__c, Field75__c, Field74__c, Field73__c, Field72__c, 
		      Field71__c, Field70__c, Field69__c, Field68__c, Field67__c, Field66__c, Field65__c, Field64__c, 
		      Field63__c, Field62__c, Field61__c, Field60__c, Field59__c, Field58__c, Field57__c, Field56__c, 
		      Field55__c, Field54__c, Field53__c, Field52__c, Field51__c, Field50__c, Field49__c, Field48__c, 
		      Field45__c, Field40__c, Field39__c, Field159__c, Field158__c, 
		      Field141__c, Field150__c,
		      Field126__c,
		      Field116__c, Field114__c, 
		      // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
		      RespectLst__c,
		      // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
		      // 2020/02/21 社内コメント項目を新規追加(共通定義により、切り替え制限可能) BEGIN
		      comment2__c,
		      // 2020/02/21 社内コメント項目を新規追加(共通定義により、切り替え制限可能) END
		      ContactName__c,BillingCal__c, AccountLanguage__c ,
		      DivisionName__c, Name, SumSrvPriceIncTax__c, SumSrvPriceExcTax__c,AmoutSpecialPrice__c,
		      LastModifiedDate, LastModifiedById, TaxRate__c,
		      // 予約関連項目
		      Relreserve__r.Field298__c,	// お客様ステータス
		      Relreserve__r.Name,Relreserve__r.refTypeOfRooms__c,Relreserve__r.LeadIndexRef__c,
		      Relreserve__r.StayPersons__c,Relreserve__r.Rroom__c, Discount__c,
		      Relreserve__r.LeadIndexSubId__c,Relreserve__r.RoomGroupNo__c,
		      PaymentFlg__c,relaccount__r.Account.Name, AccountedFlgCal__c,DetailSortBy__c,relaccount__r.Name, relaccount__r.AccountId, 
		      AccountName__c,AccountReceiptName__c,AccountProviso__c,AccountReceiptDate__c,
		      frs__r.Salesday__c,SalesDate__c,CouponReturnFlg__c
			  // 2015から新規項目
			  ,IsNewLayout__c, ShopCode__c
			  // 2015/05/20 追加
			  ,frs__r.Name
			  // 2015/12/24 追加
			  ,PaymentHandReqFlg__c
			  // 2016/06/28 利用日設定機能追加
			  ,ReceiptDt__c
			  // 2017/04/19 オーダーエントリ情報出力用
			  ,Field145__c
			  // 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH BEGIN
		      ,Relreserve__r.EntryTime__c
		      // 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH END
		      // 2019/11/30 会計の領収証日付値の自動設定制御モード機能対応 WGCH BEGIN
		      ,Relreserve__r.Departure__c
		      // 2019/11/30 会計の領収証日付値の自動設定制御モード機能対応 WGCH END
		  From AccountAcount__c where Relreserve__c = :keyLead.Id order by createddate desc limit 1];
		}
		// 2017/09/06 会計メッセージ項目自定義機能追加 by zy END
		// 指定の会計の実際データがない場合、処理中止
		if (billList.isEmpty()) return false;
		// 2018/03/12 連泊コメント同期機能対応 WGCH BEGIN
		if(isAccountSyncCommentFlg) getOneRoomAcc(billList[0]);
		// 2018/03/12 連泊コメント同期機能対応 WGCH END
		// 画面編集している会計情報を格納する
		oAcountSobj = billList[0];
//system.debug(logginglevel.info, 'oAcountSobj:'+oAcountSobj);

    	// *********************************
    	// 既にチェックイン済の会計情報を取得する
        // 売上計上日順に関連予約情報を全部取得を行う
        // *********************************
		List<AccountAcount__c> relAccounts = [
		  Select relaccount__c, frs__c, comment__c, TeaTimeFlag__c, Target__c, TableNo__c, Seq__c, Relreserve__c, 
		      PlanNo__c, POSNo__c, OutSideAccount__c, Field99__c, Field98__c, Field97__c, Field96__c, Field95__c, 
		      Field94__c, Field93__c, Field92__c, Field91__c, Field90__c, Field89__c, Field88__c, Field87__c, 
		      Field86__c, Field85__c, Field84__c, Field83__c, Field82__c, Field81__c, Field80__c, Field7__c, 
		      Field79__c, Field78__c, Field77__c, Field76__c, Field75__c, Field74__c, Field73__c, Field72__c, 
		      Field71__c, Field70__c, Field69__c, Field68__c, Field67__c, Field66__c, Field65__c, Field64__c, 
		      Field63__c, Field62__c, Field61__c, Field60__c, Field59__c, Field58__c, Field57__c, Field56__c, 
		      Field55__c, Field54__c, Field53__c, Field52__c, Field51__c, Field50__c, Field49__c, Field48__c, 
		      Field45__c, Field40__c, Field39__c, Field159__c, Field158__c, 
		      Field141__c,Field150__c,
		      Field126__c,
		      Field116__c, Field114__c, 
		      // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
		      RespectLst__c,
		      // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
		      // 2020/02/21 社内コメント項目を新規追加(共通定義により、切り替え制限可能) BEGIN
		      comment2__c,
		      // 2020/02/21 社内コメント項目を新規追加(共通定義により、切り替え制限可能) END
			  // 最終更新情報
		      ContactName__c,BillingCal__c, AccountLanguage__c ,
		      DivisionName__c, Name, SumSrvPriceIncTax__c, SumSrvPriceExcTax__c,AmoutSpecialPrice__c,
		      TaxRate__c,
		      // 予約関連項目
		      Relreserve__r.Field298__c,	// お客様ステータス
		      Relreserve__r.Name,Relreserve__r.refTypeOfRooms__c,Relreserve__r.LeadIndexRef__c,
		      Relreserve__r.StayPersons__c,Relreserve__r.Rroom__c, Discount__c,
		      Relreserve__r.LeadIndexSubId__c,Relreserve__r.RoomGroupNo__c,
		      PaymentFlg__c,relaccount__r.Account.Name, AccountedFlgCal__c,DetailSortBy__c,relaccount__r.Name, relaccount__r.AccountId, 
		      AccountName__c,AccountReceiptName__c,AccountProviso__c,AccountReceiptDate__c,
		      frs__r.Salesday__c,SalesDate__c,CouponReturnFlg__c
		      // 2015から新規項目
		      ,IsNewLayout__c
		      // 2015/05/20 追加
		      ,frs__r.Name
		      // 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH BEGIN
		      ,Relreserve__r.EntryTime__c
		      // 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH END
		      // 2019/11/30 会計の領収証日付値の自動設定制御モード機能対応 WGCH BEGIN
		      ,Relreserve__r.Departure__c
		      // 2019/11/30 会計の領収証日付値の自動設定制御モード機能対応 WGCH END
			From AccountAcount__c 
			where frs__c !=  null
				/*
				 And Relreserve__r.LeadIndexRef__c = :leadIdx 
				 And Relreserve__r.LeadIndexSubId__c = :leadSubIdx 
				 And Relreserve__r.RoomGroupNo__c = :leadGroupNo 
				 And Relreserve__r.CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG	// 有効な予約データ
				 */
					 And Relreserve__c in :pRelLeadsMap.keySet()
					 And Field39__c = :CommConst.ACC_TRADE_NORMAL // 正常な会計情報
				order By frs__r.Name ];
			for (AccountAcount__c acc : relAccounts) {
				pRelAccountsMap.put(acc.Id, acc);
				pRelAccountIdList.add(acc.Id);
				// 親部屋の親部屋の会計IDを取得する（１泊目）
			}
//system.debug(logginglevel.info, 'relAccounts:'+relAccounts.size());
//system.debug(logginglevel.info, 'pRelLeadsMap.keySet():'+pRelLeadsMap.keySet());
//system.debug(logginglevel.info, 'pRelAccountIdList:'+pRelAccountIdList);
			// 画面情報の会計共通化
			pRelAccountsMap.put(oAcountSobj.Id, oAcountSobj);
			if (pRelAccountIdList.isEmpty() && oAcountSobj.Field39__c == CommConst.ACC_TRADE_NORMAL ) pRelAccountIdList.add(oAcountSobj.Id);
//System.debug(loggingLevel.ERROR, 'pRelAccountsMap[in]:' + pRelAccountsMap);
//System.debug(loggingLevel.ERROR, 'pRelAccountIdList[in]:' + pRelAccountIdList);
			// 関連の売上期間情報を格納する
			List<String> sortSalesDateLst = new List<String>();
			for (AccountAcount__c acc : pRelAccountsMap.values()) {
				sortSalesDateLst.add(acc.frs__r.Name);
			}
			sortSalesDateLst.sort();
			gSalesDateRangeStr = sortSalesDateLst[0] + ':' + sortSalesDateLst[sortSalesDateLst.size()-1];
			
		return true;
	}
	// 2016/10/14 複数部屋会計処理を行う機能(Beta) END
	// 2017/10/18 チェックアウト機能対応 BEGIN
	public Boolean isShowCheckOutBtn{get; private set;}
	// 2017/10/18 チェックアウト機能対応 END
	/**
	* 最新会計情報を取得する
	* pBillId: 会計ID
	* 該当会計関連の予約の含めの会計情報を一括取得する
	**/
	
	private Boolean refreshAccoutAcountInfo(Id pBillId) {
		// 2016/10/14 複数部屋会計処理を行う機能(Beta) BEGIN
		if (isMultiRoomFlg) return refreshAccoutAcountInfoMulti();
		// 2016/10/14 複数部屋会計処理を行う機能(Beta) END
		if (pBillId == null) return false;
		// 画面から選べる会計情報を取得する
		// 最新情報を取得する
		// 2017/09/06 会計メッセージ項目自定義機能追加 by zy BEGIN
		List<AccountAcount__c> billList = new List<AccountAcount__c> ();
		if ( customBillSet != null && !customBillSet.isEmpty() ) billList = queryAccount(pBillId,null);
		else {
		//List<AccountAcount__c> 
		billList = [
		  Select relaccount__c, frs__c, comment__c, TeaTimeFlag__c, Target__c, TableNo__c, Seq__c, Relreserve__c, 
		      PlanNo__c, POSNo__c, OutSideAccount__c, Field99__c, Field98__c, Field97__c, Field96__c, Field95__c, 
		      Field94__c, Field93__c, Field92__c, Field91__c, Field90__c, Field89__c, Field88__c, Field87__c, 
		      Field86__c, Field85__c, Field84__c, Field83__c, Field82__c, Field81__c, Field80__c, Field7__c, 
		      Field79__c, Field78__c, Field77__c, Field76__c, Field75__c, Field74__c, Field73__c, Field72__c, 
		      Field71__c, Field70__c, Field69__c, Field68__c, Field67__c, Field66__c, Field65__c, Field64__c, 
		      Field63__c, Field62__c, Field61__c, Field60__c, Field59__c, Field58__c, Field57__c, Field56__c, 
		      Field55__c, Field54__c, Field53__c, Field52__c, Field51__c, Field50__c, Field49__c, Field48__c, 
		      Field45__c, Field40__c, Field39__c, Field159__c, Field158__c, 
		      Field141__c, Field150__c,
		      Field126__c,
		      Field116__c, Field114__c, 
		      // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
		      RespectLst__c,
		      // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
		      // 2020/02/21 社内コメント項目を新規追加(共通定義により、切り替え制限可能) BEGIN
		      comment2__c,
		      // 2020/02/21 社内コメント項目を新規追加(共通定義により、切り替え制限可能) END
		      ContactName__c,BillingCal__c, AccountLanguage__c ,
		      DivisionName__c, Name, SumSrvPriceIncTax__c, SumSrvPriceExcTax__c,AmoutSpecialPrice__c,
		      LastModifiedDate, LastModifiedById, TaxRate__c,
		      // 予約関連項目
		      Relreserve__r.Field298__c,	// お客様ステータス
		      Relreserve__r.Name,Relreserve__r.refTypeOfRooms__c,Relreserve__r.LeadIndexRef__c,
		      Relreserve__r.StayPersons__c,Relreserve__r.Rroom__c, Discount__c,
		      Relreserve__r.LeadIndexSubId__c,Relreserve__r.RoomGroupNo__c,
		      PaymentFlg__c,relaccount__r.Account.Name, AccountedFlgCal__c,DetailSortBy__c,relaccount__r.Name, relaccount__r.AccountId, 
		      AccountName__c,AccountReceiptName__c,AccountProviso__c,AccountReceiptDate__c,
		      frs__r.Salesday__c,SalesDate__c,CouponReturnFlg__c
			  // 2015から新規項目
			  ,IsNewLayout__c, ShopCode__c
			  // 2015/05/20 追加
			  ,frs__r.Name
			  // 2015/12/24 追加
			  ,PaymentHandReqFlg__c
			  // 2016/06/28 利用日設定機能追加
			  ,ReceiptDt__c
			  // 2017/04/19 オーダーエントリ情報出力用
			  ,Field145__c
			  // 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH BEGIN
		      ,Relreserve__r.EntryTime__c
		      // 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH END
		      // 2019/11/30 会計の領収証日付値の自動設定制御モード機能対応 WGCH BEGIN
		      ,Relreserve__r.Departure__c
		      // 2019/11/30 会計の領収証日付値の自動設定制御モード機能対応 WGCH END
		  From AccountAcount__c where id = :pBillId];
		}
		// 2017/09/06 会計メッセージ項目自定義機能追加 by zy END
		// 指定の会計の実際データがない場合、処理中止
		if (billList.isEmpty()) return false;
		// 2018/03/12 連泊コメント同期機能対応 WGCH BEGIN
		if(isAccountSyncCommentFlg) getOneRoomAcc(billList[0]);
		// 2018/03/12 連泊コメント同期機能対応 WGCH END
		// 画面編集している会計情報を格納する
		oAcountSobj = billList[0];
		// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
		if (RespectFlg){
			if (!CommUtils.isBlank(oAcountSobj.RespectLst__c)) mrStr = CommUtils.nullToBlank(oAcountSobj.RespectLst__c);
		}
		// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
		// *************************
		// 関連の会計情報も再取得する
		// *************************
		pRelAccountsMap.clear();
		pRelAccountIdList.clear();
		pRelLeadsMap.clear();
		pRelLeadIdList.clear();
		// 予約なしの簡易会計も対応するため、
		if (oAcountSobj.Relreserve__c == null) {
			pRelAccountsMap.put(oAcountSobj.Id, oAcountSobj);
			pRelAccountIdList.add(oAcountSobj.Id);
			gSalesDateRangeStr = oAcountSobj.frs__r.Name + ':' + oAcountSobj.frs__r.Name;
			return true;
		} else {
			// 該当予約関連の予約情報を全部自動チェックイン処理を行う
			//String[] autoCheckInRes = preAutoCheckin(oAcountSobj.Relreserve__c);
	 		// 予約INDEX
	    	Id leadIdx = oAcountSobj.Relreserve__r.LeadIndexRef__c;
	    	// 予約INDEX SUB
	    	Id leadSubIdx = oAcountSobj.Relreserve__r.LeadIndexSubId__c;
	    	// 予約グループNO
	    	Decimal leadGroupNo = oAcountSobj.Relreserve__r.RoomGroupNo__c;
	    	
	    	// 既存有効な予約情報を取得する
	    	List<Lead__c> leads = [select id,EntryTime__c,Departure__c from Lead__c 
	    								where LeadIndexRef__c = :leadIdx
	    								And LeadIndexSubId__c = :leadSubIdx
	    								And RoomGroupNo__c = :leadGroupNo
	    								And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
	    								Order By EntryTime__c
	    								];
	    	for (Lead__c lead : leads) {
	    		pRelLeadsMap.put(lead.Id, lead);
	    		pRelLeadIdList.add(lead.Id);
	    	}
	    	// 到着日と出発日を格納する
	    	if (!leads.isEmpty()) {
	    		oPage.strEntryDate = leads[0].EntryTime__c.format(CommBaseCtrl.getDateFormat());
	    		oPage.strDepartureDate = leads[leads.size()-1].Departure__c.format(CommBaseCtrl.getDateFormat());
	    	}
	    	// 2017/10/18 チェックアウト機能対応 BEGIN
	    	// 該当会計は該当部屋の最終日の会計の場合、チェックアウトボタンを表示する
	    	// 2018/12/20 有効な予約情報が存在するのみ、下記処理を行う
	    	if (leads.size() > 0)
	    	if (leads[leads.size()-1].Id == oAcountSobj.Relreserve__c) isShowCheckOutBtn = true;
	    	// 2017/10/18 チェックアウト機能対応 END
	    	// *********************************
	    	// 既にチェックイン済の会計情報を取得する
	        // 売上計上日順に関連予約情報を全部取得を行う
	        // *********************************
			List<AccountAcount__c> relAccounts = [
			  Select relaccount__c, frs__c, comment__c, TeaTimeFlag__c, Target__c, TableNo__c, Seq__c, Relreserve__c, 
			      PlanNo__c, POSNo__c, OutSideAccount__c, Field99__c, Field98__c, Field97__c, Field96__c, Field95__c, 
			      Field94__c, Field93__c, Field92__c, Field91__c, Field90__c, Field89__c, Field88__c, Field87__c, 
			      Field86__c, Field85__c, Field84__c, Field83__c, Field82__c, Field81__c, Field80__c, Field7__c, 
			      Field79__c, Field78__c, Field77__c, Field76__c, Field75__c, Field74__c, Field73__c, Field72__c, 
			      Field71__c, Field70__c, Field69__c, Field68__c, Field67__c, Field66__c, Field65__c, Field64__c, 
			      Field63__c, Field62__c, Field61__c, Field60__c, Field59__c, Field58__c, Field57__c, Field56__c, 
			      Field55__c, Field54__c, Field53__c, Field52__c, Field51__c, Field50__c, Field49__c, Field48__c, 
			      Field45__c, Field40__c, Field39__c, Field159__c, Field158__c, 
			      Field141__c,Field150__c,
			      Field126__c,
			      Field116__c, Field114__c, 
			      // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
			      RespectLst__c,
			      // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
			      // 2020/02/21 社内コメント項目を新規追加(共通定義により、切り替え制限可能) BEGIN
			      comment2__c,
			      // 2020/02/21 社内コメント項目を新規追加(共通定義により、切り替え制限可能) END
				  // 最終更新情報
			      ContactName__c,BillingCal__c, AccountLanguage__c ,
			      DivisionName__c, Name, SumSrvPriceIncTax__c, SumSrvPriceExcTax__c,AmoutSpecialPrice__c,
			      TaxRate__c,
			      // 予約関連項目
			      Relreserve__r.Field298__c,	// お客様ステータス
			      Relreserve__r.Name,Relreserve__r.refTypeOfRooms__c,Relreserve__r.LeadIndexRef__c,
			      Relreserve__r.StayPersons__c,Relreserve__r.Rroom__c, Discount__c,
			      Relreserve__r.LeadIndexSubId__c,Relreserve__r.RoomGroupNo__c,
			      PaymentFlg__c,relaccount__r.Account.Name, AccountedFlgCal__c,DetailSortBy__c,relaccount__r.Name, relaccount__r.AccountId, 
			      AccountName__c,AccountReceiptName__c,AccountProviso__c,AccountReceiptDate__c,
			      frs__r.Salesday__c,SalesDate__c,CouponReturnFlg__c
			      // 2015から新規項目
			      ,IsNewLayout__c
			      // 2015/05/20 追加
			      ,frs__r.Name
			      // 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH BEGIN
			      ,Relreserve__r.EntryTime__c
			      // 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH END
			      // 2019/11/30 会計の領収証日付値の自動設定制御モード機能対応 WGCH BEGIN
			      ,Relreserve__r.Departure__c
			      // 2019/11/30 会計の領収証日付値の自動設定制御モード機能対応 WGCH END
				From AccountAcount__c 
				where frs__c !=  null
					/*
					 And Relreserve__r.LeadIndexRef__c = :leadIdx 
					 And Relreserve__r.LeadIndexSubId__c = :leadSubIdx 
					 And Relreserve__r.RoomGroupNo__c = :leadGroupNo 
					 And Relreserve__r.CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG	// 有効な予約データ
					 */
					 And Relreserve__c in :pRelLeadsMap.keySet()
					 And Field39__c = :CommConst.ACC_TRADE_NORMAL // 正常な会計情報
				order By frs__r.Name ];
			for (AccountAcount__c acc : relAccounts) {
				pRelAccountsMap.put(acc.Id, acc);
				pRelAccountIdList.add(acc.Id);
			}
			// 画面情報の会計共通化
			pRelAccountsMap.put(oAcountSobj.Id, oAcountSobj);
			if (pRelAccountIdList.isEmpty() && oAcountSobj.Field39__c == CommConst.ACC_TRADE_NORMAL ) pRelAccountIdList.add(oAcountSobj.Id);
//System.debug(loggingLevel.ERROR, 'pRelAccountsMap[in]:' + pRelAccountsMap);
//System.debug(loggingLevel.ERROR, 'pRelAccountIdList[in]:' + pRelAccountIdList);
			// 関連の売上期間情報を格納する
			List<String> sortSalesDateLst = new List<String>();
			for (AccountAcount__c acc : pRelAccountsMap.values()) {
				sortSalesDateLst.add(acc.frs__r.Name);
			}
			sortSalesDateLst.sort();
			gSalesDateRangeStr = sortSalesDateLst[0] + ':' + sortSalesDateLst[sortSalesDateLst.size()-1];
			return true;
		}
	}
	/**
	* 「会計書宛名、領収書宛名」の選択リスト表示用クラス
	**/
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
		if (!CommUtils.isBlank(oAcountSobj.relaccount__r.Account.Name))
		accountNamsLst.add(new Option(oAcountSobj.relaccount__r.Account.Name,oAcountSobj.relaccount__r.Account.Name));
		if (!CommUtils.isBlank(oAcountSobj.relaccount__r.Name))
		accountNamsLst.add(new Option(oAcountSobj.relaccount__r.Name,oAcountSobj.relaccount__r.Name));
		if (!CommUtils.isBlank(oAcountSobj.Relreserve__r.Name))
		// 2013/10/28 会計編集の「会計書宛名、領収書宛名」の選択リスト内容を追加
		accountNamsLst.add(new Option(oAcountSobj.Relreserve__r.Name,oAcountSobj.Relreserve__r.Name));
		return JSON.serialize(accountNamsLst);
	}
	public String getAccountProvisos() {
		List<Option> accountProvisoLst = new List<Option>(); 
    	String provisoStr = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().AccountProviso__c);
    	String[] provisoArray = provisoStr.split(',');
    	for (String key : provisoArray) {
    		if (!CommUtils.isBlank(key)) accountProvisoLst.add(new Option(key, key));
    	}
    	return JSON.serialize(accountProvisoLst);
	}


	/** 明細の利用日により、会計情報の新規追加、明細の紐付く変更処理を行う */
	/** TODO:簡易会計の場合、対応が必要 */
	private void syncSalesDateInfo () {
		// 2015/06/18 EDIT BEGIN 利用日は情報のみ格納の場合（シンプルモード：）　該当利用日から売上情報とBIND処理を行わない
		if (useDateSimpleMode) return;
		// 2015/06/18 EDIT END
		// 現在の会計情報の予約情報はNULLの場合、下記処理を行わない
		if (oAcountSobj.Relreserve__c == null) return;
serverlog.write_method_start('syncSalesDateInfo');
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'relreserve__c','frs__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.AccountAcount__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
			return ;
		}
		// 2019/09/15 Security Check BY zyz END
		// 画面に設定の有効な会計明細情報・会計支払は
		// 会計明細の利用日により、関連の売上、会計に再紐付く設定を行う Map<Index(画面に入力の並び順, 画面に入力の明細情報)>
		Map<String, List<TranItem>> locAccTranMaps = new Map<String, List<TranItem>>();
		// 利用日リスト
		Set<String> salesDateSet = new Set<String>();
		// 関連の予約ID情報を格納する
		Set<Id> relLeadsIdSet = new Set<Id>();
		// 画面に登録した全部会計明細リスト[処理済の場合、配列から外す？]
		// 元の会計明細に関連の会計情報を取得する　pRelAccountsMap
		for (TranItem obj: oTranSobjLst) {
			// 無効な会計明細の場合、処理SKIP
			if (!obj.checkValidata()) continue;
			// 見積もり明細の場合、処理SKIP
			if (obj.isEstItemFlg) continue;
			
			// 有効な会計明細情報の場合、		
			// 利用日情報を取得する、該当利用日は画面に開くの場合の利用日と比較、変更される場合、
			// 現在の会計の予約情報はNULLの場合、処理を飛ばす
			// 新規登録の明細に対して、予約IDは自動現在の基本情報の会計の関連の予約情報IDで設定する
			if (CommUtils.isBlank(obj.tranId)) obj.orgLeadId = oAcountSobj.Relreserve__c;
			// 元の予約IDはNULLの場合、現在の基本情報の会計の関連の予約情報IDで設定する
			if (CommUtils.isBlank(obj.orgLeadId)) obj.orgLeadId = oAcountSobj.Relreserve__c;
			// 該当明細の利用日はNULLの場合、現在の基本情報の会計の売上計上日からデイフォル値を設定する
			// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH BEGIN
			if(obj.sobj.UseDate__c == null && CommConst.BOOKEST_USERDATE_FLG && oAcountSobj.Relreserve__c != null && oAcountSobj.Relreserve__r.EntryTime__c != null){
				obj.sobj.UseDate__c = oAcountSobj.Relreserve__r.EntryTime__c.date();
			}
			// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH END
			if (obj.sobj.UseDate__c == null) obj.sobj.UseDate__c = oAcountSobj.SalesDate__c;
			// 利用日の設定値により、売上存在チェック用配列に設定する
			String rsvName = DateTime.newInstance(obj.sobj.UseDate__c, Time.newInstance(0,0,0,0)).format('yyyyMMdd');
// モード３の場合、前受金と支払のみ対象
if (!useDateMiddleMode ||
				(useDateMiddleMode && (obj.isPayProduct() || obj.isARProduct()) ) ){
	// 参照している予約IDを配列の格納する
	if (!CommUtils.isBlank(obj.orgLeadId)) relLeadsIdSet.add(obj.orgLeadId);	// 参照している予約ID
	salesDateSet.add(rsvName);
}
	
			// 該当売上名と参照の予約IDにより、既存の関連会計情報存在チエックを行う、
			String key = rsvName + '_' + CommUtils.nullToBlank(obj.orgLeadId);
			// 会計明細の会計参照IDはNULLの場合、現在の基本情報の会計IDを設定する【このIDにより、コピー元の会計情報を取得するため】
			// 2021/05/31 #11277 bug fixed by zy BEGIN
			if (CommUtils.isBlank(obj.sobj.Field1__c)) obj.sobj.Field1__c = oAcountSobj.Id;
			// if (obj.sobj.Field1__c == null) obj.sobj.Field1__c = oAcountSobj.Id;
			// 2021/05/31 #11277 bug fixed by zy END
			// 同じ売上、同じ予約情報を紐付くの明細情報を格納する
			// モード３の場合、前受金と支払のみ自動作成対象になる
			if (useDateMiddleMode ) {
				if (!obj.isPayProduct() && !obj.isARProduct()) continue;
			}
			if (!locAccTranMaps.containsKey(key)) locAccTranMaps.put(key, new List<TranItem>());
			locAccTranMaps.get(key).add(obj);

		}
//System.debug(loggingLevel.INFO, 'locAccTranMaps:::' + locAccTranMaps);
		// --------------------------
		// 売上:::
		// --------------------------
		// 新規・更新売上情報リスト
		List<RsvAccount__c> upsertRsvLst = new List<RsvAccount__c>();
		for (String strSalsDt : salesDateSet) {
			upsertRsvLst.add(new RsvAccount__c(Name = strSalsDt));
		}
		if (!upsertRsvLst.isEmpty()) {
			upsert upsertRsvLst name;
//System.debug(loggingLevel.INFO, 'upsertRsvLst::::' + upsertRsvLst);
		}
serverlog.write_log('関連売上：'+upsertRsvLst);
		// 日付により、売上IDを格納する
		Map<String, Id> salesInfMap = new Map<String, Id>();
		for (RsvAccount__c rsv : upsertRsvLst) {
			salesInfMap.put(rsv.Name, rsv.Id);
		}
		// 簡易会計の場合「開いた会計の予約IDはNULLの場合、該当会計」
		// --------------------------
		// 会計:::「画面指定の利用日と関連の予約IDにより、既存の会計情報が存在チエックを行う」
		//        VOIDされないの会計情報は前提条件
		// --------------------------
		List<AccountAcount__c> locExistAccLst = [select id,frs__c,frs__r.Name,Relreserve__c From AccountAcount__c 
			where frs__r.Name in :salesDateSet And Relreserve__c in :relLeadsIdSet
			And Field39__c = :CommConst.ACC_TRADE_NORMAL];
		Map<String, AccountAcount__c> locExistAccMap = new Map<String, AccountAcount__c>();
		// 該当予約の関連の会計が存在するがどうか、チエックを行う
		for (AccountAcount__c acc : locExistAccLst) {
			String key = acc.frs__r.Name + '_' + acc.Relreserve__c;
			locExistAccMap.put(key, acc);
		}
serverlog.write_log('既存会計：'+locExistAccMap);
//System.debug(loggingLevel.INFO, 'locExistAccMap::::' + locExistAccMap);
		// 元の会計明細＿会計支払に所属の会計情報を取得する
		Map<String, AccountAcount__c> updAccUpsertMap = new Map<String, AccountAcount__c>();
		// 新規作成の会計情報を捜す
		for (String key : locAccTranMaps.keySet()) {
			// 利用日と同じ　かつ　同じ予約情報を参照する会計情報が非存在する場合
			if (!locExistAccMap.containsKey(key)) {
				// 該当会計は自動新規作成が必要になる
				List<TranItem> locTranLst = locAccTranMaps.get(key);
				// 該当会計明細に紐付くの会計情報を再取得して、コピーして、新会計情報を作成を行う
				AccountAcount__c locNewAcc = pRelAccountsMap.get(locTranLst[0].sobj.Field1__c).clone(false,true);
				// 新規作成の会計の売上と参照している予約情報を再設定を行う
				String[] keys = key.split('_');
				locNewAcc.frs__c = salesInfMap.get(keys[0]);	// 紐付く売上ID
				locNewAcc.Relreserve__c = keys[1];				// 紐付く予約ID
				// 2018/03/12 連泊コメント同期機能対応 WGCH BEGIN
				// comment__c新旧值进行最新的赋值
				if(isAccountSyncCommentFlg) setNewCommentInfo(locNewAcc);
				// 2018/03/12 連泊コメント同期機能対応 WGCH END
				updAccUpsertMap.put(key, locNewAcc);			// 新規配列に格納する
serverlog.write_log('新規作成予定会計：'+locNewAcc);
			} 
			// 該当会計情報が既に存在する場合、関連の明細は該当会計に紐付くする
			else {
				// 関連の明細に売上、会計IDを自動設定を行う
				List<TranItem> locTranLst = locAccTranMaps.get(key);
				AccountAcount__c locExistAcc = locExistAccMap.get(key);
				// 既存の会計IDと売上IDで、会計明細に更新を行う
				for (TranItem locTran : locTranLst) {
					// 2019/02/28 入湯税の自動設定機能連泊予約分别設定対応 BEGIN
					// locTran.sobj.Field1__c = locExistAcc.Id;
					// locTran.sobj.RelAccount__c = locExistAcc.frs__c;
					// 不是新自动追加的入汤税明细
					if (!locTran.bathTaxAutoSetupFlg){
						locTran.sobj.Field1__c = locExistAcc.Id;
						locTran.sobj.RelAccount__c = locExistAcc.frs__c;
					}
					// 2019/02/28 入湯税の自動設定機能連泊予約分别設定対応 END
					
				}
//System.debug(loggingLevel.INFO, 'locTranLst::::' + locTranLst);
				// 処理済の情報を対象から外す
				locAccTranMaps.remove(key);
			}
		}
//System.debug(loggingLevel.INFO, 'updAccUpsertMap::::' + updAccUpsertMap);
		// 会計新規作成対象あり場合
		if (!updAccUpsertMap.isEmpty()) {
			// 会計新規作成を行う
			List<AccountAcount__c> locUpsertAccLst = preUpdateAccountInf(updAccUpsertMap.values());
			upsert locUpsertAccLst;
			for (AccountAcount__c acc : locUpsertAccLst) {
				pRelAccountIdList.add(acc.id);
				// 2018/03/12 連泊コメント同期機能対応 WGCH BEGIN
				// comment__c新旧值进行最新的赋值
				if(isAccountSyncCommentFlg) setNewCommentInfo(acc);
				// 2018/03/12 連泊コメント同期機能対応 WGCH END
				pRelAccountsMap.put(acc.id, acc);
			}
			// 新規作成の会計のIDは会計明細に設定する
			for (String key : locAccTranMaps.keySet()) {
				if (!locExistAccMap.containsKey(key)) {
					// 関連の明細に売上、会計IDを自動設定を行う
					List<TranItem> locTranLst = locAccTranMaps.get(key);
					AccountAcount__c locExistAcc = updAccUpsertMap.get(key);
					for (TranItem locTran : locTranLst) {
						// 2019/02/28 入湯税の自動設定機能連泊予約分别設定対応 BEGIN
						// locTran.sobj.Field1__c = locExistAcc.Id;
						// locTran.sobj.RelAccount__c = locExistAcc.frs__c;
						// 不是新自动追加的入汤税明细
						if (!locTran.bathTaxAutoSetupFlg){
							locTran.sobj.Field1__c = locExistAcc.Id;
							locTran.sobj.RelAccount__c = locExistAcc.frs__c;
						}
						// 2019/02/28 入湯税の自動設定機能連泊予約分别設定対応 END
serverlog.write_log('明細['+locTran.index+']→会計リンク：'+locExistAcc.Id);
					}
				}
			}
		}
serverlog.write_method_end();
	}
	

	// ************************
	// 会計明細金額合計計算を行う
	// 画面入力した会計明細情報は会計支払と会計に反映を行う
	// ************************
	private Boolean amoutTran1Info() {
//serverlog.write_method_start('*****事前処理*****');
		// 会計単位の会計明細情報により、金額集計処理を行う
		pTTendSobjLstMap = new Map<Id, List<TTendItem>>();		// 会計支払
		pTranSobjLstMap = new Map<Id, List<TranItem>>();		// 会計明細
		pTttendFooterMap = new Map<Id, TTendFooter>();			// 会計単位の会計支払合計情報格納用	
		pTranFooterMap = new Map<Id, TranFooter>();				// 会計単位の会計明細合計情報格納用
		noDeleteIdSet  = new Set<Id>();
		pArTranInsertIdMap = new Map<Id, Map<Integer, Tran1__c>>();// 会計単位の事前会計明細情報を格納する
		// 画面に登録した全部会計明細リスト[処理済の場合、配列から外す？]
		for (TranItem obj: oTranSobjLst) {
			// 無効な会計明細の場合、処理SKIP
			if (!obj.checkValidata()) continue;
			// 見積もり明細の場合、処理SKIP
			if (obj.isEstItemFlg) continue;
//serverlog.write_log('明細処理対象['+obj.sobj.RowNo__c+'行]:' + obj);
			// 有効な会計明細情報の場合、
			// 会計支払で会計明細のデータで表示の場合
			if (obj.isPayProduct()) {
				// 会計明細の入力情報から会計支払情報に変換を行う
				TTend__c ttend = convertTranToTend(obj);
				// 
				Id accId = ttend.Field1__c;
				// 会計単位に支払明細情報を格納する
				if (!pTTendSobjLstMap.containsKey(accId)) pTTendSobjLstMap.put(accId, new List<TTendItem>());
				pTTendSobjLstMap.get(accId).add(new TTendItem(ttend, pTTendSobjLstMap.get(accId).size()));

				// 更新対象の支払情報を削除対象範囲外になる
				//if (ttend.Id != null ) pExistTtendItemMap.remove(ttend.Id);
				if (ttend.Id != null ) noDeleteIdSet.add(ttend.Id);
			} else {
				// 見積もり明細から表示の明細は処理SKIP
				//if (obj.isEstItemFlg) continue;

				// 新規会計明細の場合、会計IDを設定を行う
				if (!useDateSimpleMode){	// 利用日は売上日と連動あり
					// syncSalesDateInfo関数に会計明細は新規作成済ので、会計のIDをチェックする
					// 2021/05/31 #11277 bug fixed by zy BEGIN
					if (CommUtils.isBlank(obj.sobj.Field1__c)) obj.sobj.Field1__c = oAcountSobj.Id;
					// 2021/05/31 #11277 bug fixed by zy END
				} else {
					// 2019/02/28 入湯税の自動設定機能連泊予約分别設定対応 BEGIN
					// if (obj.sobj.Id == null) obj.sobj.Field1__c = oAcountSobj.Id;
					// 没有会计明细 并且 不是新自动追加的入汤税明细
					// 2021/05/31 #11277 bug fixed by zy BEGIN
					// if (obj.sobj.Id == null && !obj.bathTaxAutoSetupFlg) obj.sobj.Field1__c = oAcountSobj.Id;
					if (CommUtils.isBlank(obj.sobj.Id) && !obj.bathTaxAutoSetupFlg) obj.sobj.Field1__c = oAcountSobj.Id;
					// 2021/05/31 #11277 bug fixed by zy END
					// 2019/02/28 入湯税の自動設定機能連泊予約分别設定対応 END
				}
				// 該当画面に開いた会計に所属する会計明細の場合、該当会計の売上日を変更する場合、該当会計に所属する明細の売上も変更を行う
				if (obj.sobj.Field1__c == oAcountSobj.Id && obj.sobj.RelAccount__c != oAcountSobj.frs__c) {
					obj.sobj.RelAccount__c = oAcountSobj.frs__c;
				}

				// 関連項目を自動設定をを行う
				// 商品名称（または券名称）
				obj.sobj.Field5__c = CommUtils.isBlank(obj.productNm) ? obj.orgProductNm : obj.productNm;		
				// 会計ID
				Id accId = obj.sobj.Field1__c;
				// 同じ会計に会計明細情報を格納する
				if (!pTranSobjLstMap.containsKey(accId)) pTranSobjLstMap.put(accId, new List<TranItem>());
//				pTranSobjLstMap.get(accId).add(new TranItem(obj.sobj, pTranSobjLstMap.get(accId).size()));
				pTranSobjLstMap.get(accId).add(obj);
				// 前受金明細の場合、前受金から支払情報作成/更新対象を行う
				if (obj.isARProduct()) {
					// 前受金「返金」明細の場合
					if (BillSimpleHelp.isRefundItem(obj.sobj.PaymentType__c)) {
						// マイナス金額はDBに保存する
						if (CommUtils.nullToZero(obj.sobj.Field20__c) > 0 ) {
							obj.sobj.Field20__c = '-' + obj.sobj.Field20__c;
						}
					}
					// 該当前受付金明細は既に存在チェックを行う
					TTend__c ttend = convertArTranToTend(obj);
					// 会計単位に格納する[会計支払リスト]
					if (!pTTendSobjLstMap.containsKey(accId)) pTTendSobjLstMap.put(accId, new List<TTendItem>());
					pTTendSobjLstMap.get(accId).add(new TTendItem(ttend, pTTendSobjLstMap.get(accId).size()));
					
					// 前受金明細は新規登録の場合、支払情報に参照ID格納のMapping情報を設定する
					if (CommUtils.isBlank(ttend.ArTranId__c)) {
						// 上記前受金は格納のIndexを取得する
						Integer listIdx = pTTendSobjLstMap.get(accId).size();
						// 該当前受金経由で作成した支払情報、Mapに格納する、順番は該当会計支払に格納の順番と同じで対応する
						if (!pArTranInsertIdMap.containsKey(accId)) pArTranInsertIdMap.put(accId, new Map<Integer, Tran1__c>());
						pArTranInsertIdMap.get(accId).put(listIdx, obj.sobj);
					}
				}
			}
		} // End for (TranItem obj: oTranSobjLst) {
		// 消費税総金額格納する
		Decimal sumTaxAmount = 0;
		// 割引以外の支払金額合計値
		Decimal locAmoutSalesPrice = 0;
		// 全て支払情報格納用
		List<TTendItem> locAllTtendLst = new List<TTendItem>();
		// 毎日画面に入れた会計支払情報の金額を計算する
		// 明細に前受金が存在する場合、
		// 関連会計の金額を再自動計算を行う
		for (Id accId : pRelAccountIdList) {
			// 会計単位の関連処理を行う
			AccountAcount__c acountSobj = pRelAccountsMap.get(accId);
			// 会計のHeader消費税RESETする、会計商品の明細情報により、再設定を行う
			acountSobj.TaxRate__c = 0;
			// -------------------------------------
			// 画面に入力した会計明細と会計支払情報を取得する
			// -------------------------------------
			// 該当会計関連の会計明細リストを取得する
			List<TranItem> locTranSobjLst = pTranSobjLstMap.get(accId);			// 該当会計の会計明細
			if (locTranSobjLst == null) locTranSobjLst = new List<TranItem>();
			// 該当会計関連の会計支払リストを取得する
			List<TTendItem> locTtendSobjLst = pTTendSobjLstMap.get(accId);		// 該当会計の会計支払
			if (locTtendSobjLst == null) locTtendSobjLst = new List<TTendItem>();
			if (!locTtendSobjLst.isEmpty()) locAllTtendLst.addAll(locTtendSobjLst);
			// 明細合計値格納用変数
			TranFooter locTranfooter = new TranFooter();
			pTranFooterMap.put(accId, locTranfooter);
			TTendFooter locTTendFooter = new TTendFooter();
			pTttendFooterMap.put(accId, locTTendFooter);
			
			// *************************
			// 会計明細金額を再計算を行う
			// 入力の明細情報から金額最自動計算を行う
			// *************************
			for (TranItem obj: locTranSobjLst) {
				// 無効のデータをクリアを行う
				if (!obj.checkValidata()) {
					obj.clear();
					continue;
				}
				// 請求書非表示の場合、統計対象外になる
				// 2016/10/27 非表示機能とき、合計金額（税込）は０円でDBへ格納する、しない制御機能追加
				// 2020/01/30 非表示の一括解除、あるいは金額を0円にしない非表示設定の追加 WGCH BEGIN
				// if (obj.sobj.InvoiceNoShowFlg__c && accountNoSetAmountWhenNoShowFlg) continue;
				if ((accountNoSetAmountWhenNoShowMode == APPOTION_ACCOUNTNOSHOW_1) && obj.sobj.InvoiceNoShowFlg__c && accountNoSetAmountWhenNoShowFlg) continue;
				// 2020/01/30 非表示の一括解除、あるいは金額を0円にしない非表示設定の追加 WGCH END
				// --------------------------
				// 合計金額計算を行う
				// --------------------------
				// 2021/04/31 #10644 bug fixed by zy BEGIN
				// 只不进行重新计算其他的按照原来的方式进行数据合计
				/*
				CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero( obj.sobj.UnitPriceDefKbCal__c ));
				// 単価と数量はNULLの場合、
				Decimal unitPrice = CommUtils.nullToZero(obj.sobj.Field20__c);  // <-税金含め単価です
				Decimal qty = CommUtils.nullToZero(obj.sobj.Field21__c);
				// 関連金額再自動計算を行う
		        priceInfo.process(unitPrice , qty , obj.sobj.TaxRate__c, obj.sobj.ServiceRate__c);
		        // 合計金額(税抜)※※※※（１円未満切り上げ）※※※※
		        obj.amoutExcTax = priceInfo.priceExcTax;
		        // サービス料金（税込）
		        obj.servicePriceIncTax = priceInfo.priceService;
		        // 合計金額(税込)
		        obj.amoutIncTax = priceInfo.priceIncTax;
		        // 宿泊税値合計値に追加する
				obj.amoutIncTax += CommUtils.nullToZero(obj.sobj.SpecialTax__c);
				*/
				// 2021/04/31 #10644 bug fixed by zy END
				// 該当会計の消費税率項目はNULLの場合、消費税明細項目から消費税率設定ヲ行う
				if (CommUtils.nullToZero(acountSobj.TaxRate__c) == 0) {
					Decimal itemTaxRate = CommUtils.nullToZero(obj.sobj.TaxRate__c);
					if ( itemTaxRate > 0 ) acountSobj.TaxRate__c = itemTaxRate;
				}
				// 明細から合計情報格納する
				// 支払明細合計計算を行う
				locTranfooter.add(obj);
			}
			
			// 会計支払情報を設定をを行う
			//if (!syncPriceToTtend(acountSobj, locTranSobjLst, locTranfooter, locTtendSobjLst, locTTendFooter)) {
			//	return false;
			//}
			// 2021/04/31 #10644 bug fixed by zy BEGIN
			sumTaxAmount += syncPriceToTtend(acountSobj, locTranSobjLst, locTranfooter, locTtendSobjLst, locTTendFooter);
			// 2021/04/31 #10644 bug fixed by zy END
			locAmoutSalesPrice += locTTendFooter.amoutSalesPrice - CommUtils.nullToZero(locTTendFooter.amoutDiscountPrice);
			// 会計明細から会計へ売り上げ金額を設定を行う
			syncPriceToAccount(acountSobj, locTranfooter, locTTendFooter);
		}
		// 支払メデイア消費税値設定を行う
		if (!locAllTtendLst.isEmpty()) {
			setMediaTaxRate(sumTaxAmount, locAmoutSalesPrice, locAllTtendLst);
		}
//System.debug(LoggingLevel.ERROR, 'pTTendSobjLstMap:::' + pTTendSobjLstMap);
//serverlog.write_method_end();
		return true;
	}
	// ******************************
	// 前受金から自動作成した会計支払情報
	// ******************************
	//private TTend__c createArTtend (AccountAcount__c pAcc, TranItem pTranItem, Decimal pRecAmount, Decimal pPayAmount) {
	private TTend__c convertArTranToTend(TranItem pTranItem) {
		// 前受付金の明細情報の【支払種別】はNULLの場合、自動的に【現金】で認識する
		if (CommUtils.isBlank(pTranItem.sobj.PaymentType__c)) pTranItem.sobj.PaymentType__c = CommConst.PROD_PAY_TYPE_CASH;
		// 会計明細→会計支払情報に変更を行う
		String paymentCd = getMediaCodeByName(PAYMENT_MATCH_MAP.get(pTranItem.sobj.PaymentType__c));
		//指定範囲外の支払種別:
		if (CommUtils.isBlank(paymentCd)) throw new CommException(Label.CONST_006_0418 + paymentCd);
		
		AccountAcount__c pAcc = pRelAccountsMap.get(pTranItem.sobj.Field1__c);
		if (pAcc == null) pAcc = oAcountSobj;
		// 会計支払情報格納
		TTend__c newTtend = null;
		// 預かり金額
		Decimal amoutIncTax = (pTranItem.isReFundItem() ? -pTranItem.amoutIncTax: pTranItem.amoutIncTax);
		// 既存の前受金情報の場合
		if (!CommUtils.isBlank(pTranItem.tranId)) {
			// Map<会計明細ID、会計支払情報>
			//Map<Id, TTend__c> arPaymentInfo = pArPaymentInfoMap.get(pAcc.Id);
			List<TTend__c> arPaymentInfo = pArPaymentInfoMap.get(pAcc.Id);
			// 該当前受金に関連の会計支払情報が存在する場合、該当会計支払情報を取得する
			if (arPaymentInfo != null) for (ttend__c varTtend : arPaymentInfo) { if (varTtend.ArTranId__c == pTranItem.tranId) { newTtend = varTtend; break;} } 
			// 前受金関連の支払情報が存在場合、関連支払情報を更新する
			if (newTtend != null) {
				// 支払情報
				newTtend.Field2__c = paymentCd;
				newTtend.Field3__c = PAYMENT_MATCH_MAP.get(pTranItem.sobj.PaymentType__c);
				// 2019/10/08 メディア毎消費税額修正对应 WGCH BEGIN
				/*
				// 画面に入力金額は預かり金額に更新
				newTtend.Field19__c = CommUtils.nullToBlank(amoutIncTax);
				// 利用金額
				newTtend.Field20__c = CommUtils.nullToBlank(pTranItem.usedAmount);
				// お釣り金額
				newTtend.Field21__c = CommUtils.nullToBlank(pTranItem.changeAmout);
				*/
				// 画面に入力金額は預かり金額に更新
				newTtend.Field19__c = batchExcuteFlag ? newTtend.Field19__c : CommUtils.nullToBlank(amoutIncTax);
				// 利用金額
				newTtend.Field20__c = batchExcuteFlag ? newTtend.Field20__c : CommUtils.nullToBlank(pTranItem.usedAmount);
				// お釣り金額
				newTtend.Field21__c = batchExcuteFlag ? newTtend.Field21__c : CommUtils.nullToBlank(pTranItem.changeAmout);
				// 2019/10/08 メディア毎消費税額修正对应 WGCH END
				// 並び順項目
				newTtend.RowNo__c = pTranItem.sobj.RowNo__c;
				// 利用日も変更を行う
				newTtend.UseDate__c = pTranItem.sobj.UseDate__c;
				// 会計明細削除対象外になる
				//arPaymentInfo.remove(pTranItem.tranId);
				noDeleteIdSet.add(pTranItem.tranId);
			}
		}
		// 既存の会計情報がなかったの場合、新規会計支払「前受金紐付く会計支払」情報を新規作成する
		if (newTtend == null) {
			// 前受付金→新規会計支払情報作成
			newTtend = new TTend__c(
	            // *********** 初期値設定 **********
	            Field4__c = '1',
	            Field5__c = '1',
	            POSNo__c = CommUtils.getPosNoByComdefine(),
	            // *********** 計算額設定 **********
	            // 支払方法[現金の場合、]
	            Field2__c = paymentCd,
	            Field3__c = PAYMENT_MATCH_MAP.get(pTranItem.sobj.PaymentType__c),
				// 支払商品情報の自動設定
				PayProductRef__c = pTranItem.sobj.Field7__c,		// 前受金の会計商品に設定する
				PaymentType__c = pTranItem.sobj.PaymentType__c,
				PayProductName__c = pTranItem.productNm,
				UseDate__c = pTranItem.sobj.UseDate__c,
	            // *********** 合計金額 **********
				// 画面に入力金額は預かり金額に更新
				Field19__c = CommUtils.nullToBlank(amoutIncTax),
				// 利用金額
				Field20__c = CommUtils.nullToBlank(pTranItem.usedAmount),
				// お釣り金額
				Field21__c = CommUtils.nullToBlank(pTranItem.changeAmout),
				// 並び順項目
				RowNo__c = pTranItem.sobj.RowNo__c,
	            // *********** 参照関係設定 **********[新規登録する場合、現在の画面の会計に紐付く]
	            // 会計明細ID
	            ArTranId__c = pTranItem.sobj.Id
				);
			if (useDateSimpleMode) {
				newTtend.RelAccount__c = pAcc.frs__c;
				newTtend.Field1__c = pAcc.Id;
			}
		}
		// *********** 参照関係設定 **********
		if (!useDateSimpleMode){
			newTtend.RelAccount__c = pTranItem.sobj.RelAccount__c;
			newTtend.Field1__c = pTranItem.sobj.Field1__c;
		}
		// Cloneの参照情報をクリアする
		newTtend.PayProductRef__r = null;
		return newTtend;
	}
	
	// 会計明細の支払明細により、支払情報を自動作成を行う
	// 支払金額は自動預かり金額と支払金額を一致に自動設定を行う
	// 会計明細から会計支払へ設定を行う
	/**
	* 会計明細から会計支払情報の自動作成を行う
	* メデイア消費税計算を行う
	**/
	private Decimal syncPriceToTtend (AccountAcount__c pAcountSobj, List<TranItem> pTranSobjLst, TranFooter pTranFooter, List<TTendItem> pTtendSobjLst, TTendFooter pTTendFooter) {

		// 合計値格納クラスをクリアする
		pTTendFooter.clear();

		for (TTendItem item: pTtendSobjLst) {
			// メディア種別選択する場合:<-該当行目
			if (item.isCanEdit) {
                pTTendFooter.add(item);
			}
		}

//System.debug('oTttendFooter:::' + oTttendFooter);	
		// 2013/05/10 不具合対応：会計新規登録して、支払金額入力なし、会計確認ボタンクリックするして、「会計確認」ボタンクリックして、会計登録すると、消費税計算を行わなかった
		// 消費税の計算箇所を移動して、上記支払計算金額は全部自動計算終わる後、消費税計算を行う
		// 消費税計算を行う
// 2019/07/30 軽減税率機能対応 WGCH BEGIN
Decimal TaxSum = 0;
// 2021/04/31 #10644 bug fixed by zy BEGIN
if (isReducedTaxFlg) {
// 2021/04/31 #10644 bug fixed by zy END
	// 2019/10/08 メディア毎消費税額修正对应 WGCH BEGIN
	/*
	for (TranItem item: pTranSobjLst) {
		if(item.taxAmount != null) taxSum += CommUtils.nullToZero(item.taxAmount);
	}
	*/
	map<string,CommLogicProcess.HotelTaxDefineInfo> hotelTaxDefMap = CommLogicProcess.getHotelTaxDefInstance();
	// 2021/04/31 #10644 bug fixed by zy BEGIN
	Map<decimal,Decimal> eachTaxTotalMap = new Map<decimal,Decimal>{0=>0};
	// 2021/04/31 #10644 bug fixed by zy END
	reducedTaxInit();
	for (TranItem item: pTranSobjLst) {
		// 2019/10/24 非表示修正対応 WGCH BEGIN
		// 請求書非表示の場合、集計対象外になる
		// 2020/01/30 非表示の一括解除、あるいは金額を0円にしない非表示設定の追加 WGCH BEGIN
		// if (item.sobj.InvoiceNoShowFlg__c && accountNoSetAmountWhenNoShowFlg) continue;
		if ((accountNoSetAmountWhenNoShowMode == APPOTION_ACCOUNTNOSHOW_1) && item.sobj.InvoiceNoShowFlg__c && accountNoSetAmountWhenNoShowFlg) continue;
		// 2020/01/30 非表示の一括解除、あるいは金額を0円にしない非表示設定の追加 WGCH END
		// 商品は前受付金の場合
		if (item.sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_AR) {
			continue;
		}
		// 商品は支払商品の場合、処理対象外
		if (item.sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PY) {
			continue;
		}
		// 2019/10/24 非表示修正対応 WGCH END
		if(batchExcuteFlag && batchPlanBrkInfoMap != null && batchPlanBrkInfoMap.containsKey(item.sobj.Id)){
			List<PlanBrkInfo> pBrkInfoLst = batchPlanBrkInfoMap.get(item.sobj.Id);
			for(PlanBrkInfo brk : pBrkInfoLst){
				item.planBrkInfo = CommUtils.nullToBlank(item.planBrkInfo) +  // 原有累积的明细
											CommLogicProcess.getPlanBrkInfo(
												CommUtils.nullToBlank(brk.unitPrice), // 単価
												CommUtils.nullToBlank(brk.tax), // 消費税
												CommUtils.nullToBlank(brk.serviceRate), // サービス料
												CommUtils.nullToBlank(brk.nums), // 数量
												CommUtils.nullToBlank(brk.specialTax), // 特別税
												CommUtils.nullToBlank(brk.unitPriceKbn), // 会計商品単価定義区分
												CommUtils.nullToBlank(brk.productId), // 会計商品Id
												CommUtils.nullToBlank(brk.actionType) // 商品処理種別
											);
			}
		}
		String spcd = CommUtils.nullToBlank(oShopCode);
		// 2021/04/31 #10644 bug fixed by zy BEGIN
		if (item.itemDataArr != null && item.itemDataArr.size() > 0) {
			for (CommLogicProcess.ItemData detailData : item.itemDataArr) {
				CommLogicProcess.addDetailToMapFun(detailData, 0, comSum);
			}
			continue;
		}
		// 2021/04/31 #10644 bug fixed by zy END
		if(item.sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PL && !CommUtils.isBlank(item.planBrkInfo)){
			List<List<String>> brkInfoAllLst = CommLogicProcess.getPlanBrkInfoLst(CommUtils.nullToBlank(item.planBrkInfo));
			
			if(planBrkToHeaderCalFlg){
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
					// bug fixed by zy BEGIN
					CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(item.sobj.UnitPriceDefKb__c));
					CommLogicProcess.HotelTaxInfo hotelTaxItem = CommLogicProcess.getHotelTaxInfo(spcd, CommUtils.nullToBlank(actionType), CommUtils.nullToZero(unitPrice), CommUtils.nullToZero(nums), tax, serviceRate, priceInfo, hotelTaxDefMap);
					priceInfo = hotelTaxItem.priceInfo;
					TranItem tItem = new TranItem(new Tran1__c(), 9999);
					tItem.unitPrice = priceInfo.unitPriceTax;
					tItem.quantity = CommUtils.nullToZero(nums);
					// 消费税金额
					tItem.taxUnitPrice = priceInfo.priceTax;
					tItem.taxRate = tax / 100;
					addDetailToMapFun(tItem, 0);
				}
			} else {
				// 2021/04/31 #10644 bug fixed by zy BEGIN
				Decimal hasTaxUnitPrice = 0;
				Decimal noTaxUnitPrice = 0;
				for(List<String> brkInfoLst : brkInfoAllLst){
					if(brkInfoLst.size() < 3) continue;
					// brkInfoLst下标含义:[0]=>单价,[1]=>消费税,[2]=>サービ料,[3]=>数量,[4]=>特别税,[5]=>单价定义区分,[6]=>商品ID,[7]=>商品处理种别
					Decimal unitPrice = CommUtils.nullToZero(brkInfoLst[0]); // 单价
					Decimal tax = CommUtils.nullToZero(brkInfoLst[1]); // 消费税
					if(tax > 0) hasTaxUnitPrice += unitPrice;
					else if( tax == 0) noTaxUnitPrice += unitPrice * CommUtils.nullToIntZero(brkInfoLst[3]);
				}
				Decimal tax = CommUtils.nullToZero(item.sobj.TaxRate__c);
				Decimal amountInc = item.amoutIncTax - noTaxUnitPrice - CommUtils.nullToZero(item.sobj.SpecialTax__c);
				if (amountInc != null) {
					if (!eachTaxTotalMap.containsKey(tax)) {
						eachTaxTotalMap.put(tax,0);
					}
					Decimal curTotal = eachTaxTotalMap.get(tax);
					eachTaxTotalMap.put(tax,amountInc + curTotal);
				}
				eachTaxTotalMap.put(0,noTaxUnitPrice);
				eachTaxTotalMap.put(0,CommUtils.nullToZero(item.sobj.SpecialTax__c));
				// 2021/04/31 #10644 bug fixed by zy END
			}
		} else {
			// 2021/04/31 #10644 bug fixed by zy BEGIN
			/*
			CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(item.sobj.UnitPriceDefKb__c));
			CommLogicProcess.HotelTaxInfo hotelTaxItem = CommLogicProcess.getHotelTaxInfo(spcd, CommUtils.nullToBlank(item.sobj.ActionType__c), CommUtils.nullToZero(item.sobj.Field20__c), CommUtils.nullToZero(item.sobj.Field21__c), CommUtils.nullToZero(item.sobj.TaxRate__c), CommUtils.nullToZero(item.sobj.ServiceRate__c), priceInfo, hotelTaxDefMap);
			item.unitPrice = priceInfo.unitPriceTax;
			item.quantity = CommUtils.nullToZero(item.quantity);
			// 消费税金额
			item.taxUnitPrice = priceInfo.priceTax;
			addDetailToMapFun(item, 0);
			*/
			Decimal tax = CommUtils.nullToZero(item.sobj.TaxRate__c);
			Decimal amountInc = item.amoutIncTax;
			if (amountInc != null) {
				if (!eachTaxTotalMap.containsKey(tax)) {
					eachTaxTotalMap.put(tax,0);
				}
				Decimal curTotal = eachTaxTotalMap.get(tax);
				eachTaxTotalMap.put(tax,amountInc + curTotal);
			}
			// 2021/04/31 #10644 bug fixed by zy END
		}
	}
	// 2021/04/31 #10644 bug fixed by zy BEGIN
	for (Decimal tax : eachTaxTotalMap.keySet()){
		decimal total = eachTaxTotalMap.get(tax);
		tax = tax/100;
		Decimal taxUnitPrice = CommUtils.RoundProcess(total / (1 + tax) * tax, gPointLen);
		CommLogicProcess.ItemData item = new CommLogicProcess.ItemData();
		item.quantity = 1; // 明细-数量
		item.unitPrice = total; // 合计金额
		item.taxUnitPrice = taxUnitPrice; // 合计消費税
		item.specialTax = 0; // 合计特别税
		item.taxRate = tax; // 明细税
		CommLogicProcess.addDetailToMapFun(item, 0, comSum);
	}
	// 2021/04/31 #10644 bug fixed by zy END
	processSumInfo(pTTendFooter.amoutDiscountPrice);
	taxSum = taxUnitPriceAll - disRowData.disTaxAmountSum;
	taxSum = taxSum > 0 ? taxSum : 0;
	pTTendFooter.amoutSalesTax = CommUtils.nullToZero(taxSum);
	// 2019/10/08 メディア毎消費税額修正对应 WGCH END
} else {
		// Summary Tax 
		Decimal locAmoutIncTaxprice = pTranFooter.amoutPriceIncTaxByTax
                  	- CommUtils.nullToZero(pTTendFooter.amoutDiscountPrice);
        // 支払総金額 － 割引金額
//        Decimal locAmoutSalesPrice =  pTTendFooter.amoutSalesPrice 
//        			- CommUtils.nullToZero(pTTendFooter.amoutDiscountPrice);
//System.debug(loggingLevel.ERROR, 'locAmoutSalesPrice:::' + locAmoutSalesPrice);
		//Decimal taxRate = CommUtils.getTaxRate(Date.today());
		Decimal taxRate = CommUtils.nullToZero(pAcountSobj.TaxRate__c);
		// 2014/07/02 USD機能対応
		Integer pointLen = CommUtils.getPointLen();
		//Decimal taxSum = locAmoutIncTaxprice > 0 ? CommUtils.RoundProcess(locAmoutIncTaxprice / (1 + taxRate / 100) * (taxRate / 100), 0) : 0;
		taxSum = locAmoutIncTaxprice > 0 ? CommUtils.RoundProcess(locAmoutIncTaxprice / (1 + taxRate / 100) * (taxRate / 100), pointLen) : 0;
}		
// 2019/07/30 軽減税率機能対応 WGCH END
		return taxSum;
	}
	// 総消費税額から各メデイアに消費税を分割設定
	private void setMediaTaxRate(Decimal pTaxSumAmount, Decimal pAmoutSalesPrice, List<TTendItem> pTtendSobjLst) {
//System.debug(loggingLevel.ERROR, 'taxSum:::' + taxSum);
		Decimal remainTax = pTaxSumAmount;
		Integer maxIndex = 0;
		Decimal maxMoney = 0;
		// 2014/07/02 USD機能対応
		Integer pointLen = CommUtils.getPointLen();
// System.debug(loggingLevel.info, 'pTaxSumAmount:::' + pTaxSumAmount);
		for (TTendItem item: pTtendSobjLst) {
			if(item.isPaymented){
				if(item.sobj.Field2__c == CommConst.MEDIA_TYPE_CD_12){
					item.sobj.Field25__c = '0';
					continue;
				}
				
				// メデイア種別毎に、消費税金額計算を行う
				// 支払金額/総金額 * 消費税総金額　（小数切り捨て）
				Decimal paymentMoney = CommUtils.nullToZero(item.sobj.Field20__c);
				// 2014/07/02 USD機能対応
				//Decimal amoutTax = locAmoutSalesPrice > 0 ? CommUtils.RoundProcess((paymentMoney /locAmoutSalesPrice)*taxSum,0,RoundingMode.FLOOR) : 0;
				// 2016/02/15 マイナス数値計算の対応 BEGIN
				Decimal amoutTax = 0;
				if (!CommDefine__c.getOrgDefaults().AccountNoTaxCalFlg__c) {
					amoutTax = pAmoutSalesPrice > 0 ? CommUtils.RoundProcess((paymentMoney /pAmoutSalesPrice)*pTaxSumAmount,pointLen,RoundingMode.FLOOR) : 0;
				} else {
					amoutTax = pAmoutSalesPrice > 0 ? CommUtils.RoundProcess((math.abs(paymentMoney) /pAmoutSalesPrice)*pTaxSumAmount,pointLen,RoundingMode.FLOOR) : 0;
					if (paymentMoney < 0) amoutTax = -amoutTax;
				}
				// 2016/02/15 マイナス数値計算の対応 END
				if (paymentMoney > maxMoney) {
					maxIndex = item.index;
					maxMoney = paymentMoney;
				}
				remainTax = remainTax - amoutTax;
				// 消費税金額設定を行う
				item.sobj.Field25__c =  String.valueOf( amoutTax);
			} else {
				// 消費税金額設定を行う
				item.sobj.Field25__c =  '0';
			}
		}
//System.debug(loggingLevel.ERROR, 'remainTax:::' + remainTax);
//System.debug(loggingLevel.ERROR, 'pTtendSobjLst:::' + pTtendSobjLst);
		// Media消費税は残り値は最大消費金額に加算する
		if (remainTax != 0 && !pTtendSobjLst.isEmpty()) {
			pTtendSobjLst[maxIndex].sobj.Field25__c = String.valueOf(CommUtils.nullToZero(pTtendSobjLst[maxIndex].sobj.Field25__c) + remainTax);
		}
        //return true;
	}

	// **********************************
	// 会計明細/会計支払から会計へ売り上げ金額を設定を行う
	// pTranFooter :   会計明細合計値
	// pTttendFooter : 会計支払合計値
	// **********************************
	private void syncPriceToAccount (AccountAcount__c pAcountSobj, TranFooter pTranFooter, TTendFooter pTttendFooter) {
		// 売上計4（税込）金額:Field116__c  ->値引き存在と関係なし、実際の商品の売上を合計で設定する
		pAcountSobj.Field116__c = String.valueOf(pTranFooter.amoutPriceIncTax);
		// 売上計3（税抜）金額:Field114__c
//		pAcountSobj.Field114__c = String.valueOf(pTranFooter.amoutPriceExcTax + pTranFooter.amoutServicePrice);
//		pAcountSobj.Field114__c = String.valueOf(pTranFooter.amoutPriceExcTax);
        // サービス料金(税込)
        pAcountSobj.SumSrvPriceIncTax__c = pTranFooter.amoutServicePriceIncTax;
		// サービス料金(税抜)
		pAcountSobj.SumSrvPriceExcTax__c = pTranFooter.amoutServicePrice;
		// 宿泊税
		pAcountSobj.AmoutSpecialPrice__c = pTranFooter.amoutSpecialTax;
		// 割引金額（税込）
		pAcountSobj.Discount__c = pTttendFooter.amoutDiscountPrice;
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		// ToDo Wgch 确认目的
		if (isReducedTaxFlg) {
			pAcountSobj.sumTax__c = CommUtils.nullToZero(pTttendFooter.amoutSalesTax);
		} else {
		// 2019/07/30 軽減税率機能対応 WGCH END
		// 消費税計算、会計の消費税項目に設定を行う
        if ( pTranFooter.amoutPriceIncTaxByTax > 0 ) {
        	// 割引金額から減らいて、残りの合計金額は消費税を計算を行う
			Decimal locAmoutIncTaxprice = pTranFooter.amoutPriceIncTaxByTax
	                   					- CommUtils.nullToZero(pTttendFooter.amoutDiscountPrice);
	        // 計算用消費税率取得：会計日の消費税率を取得する
			//Decimal taxRate = CommUtils.getTaxRate(Date.today());
			Decimal taxRate = CommUtils.nullToZero(pAcountSobj.TaxRate__c);
            // 消費税計算を行う
            Integer pointLen = CommUtils.getPointLen();
            pAcountSobj.sumTax__c = (locAmoutIncTaxprice > 0 ? CommUtils.RoundProcess(locAmoutIncTaxprice / (1 + taxRate / 100) * (taxRate / 100), pointLen) : 0);
        } else {
            pAcountSobj.sumTax__c = 0;
        }
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
        }
        // 2019/07/30 軽減税率機能対応 WGCH END

        // 売上計3（税抜）金額:Field114__c
        pAcountSobj.Field114__c = String.valueOf(pTranFooter.amoutPriceIncTax - pAcountSobj.sumTax__c);
		// 請求額 = 売上計4（内税込み）金額　ー　割引額　ー　予約金 - クーポン
		pAcountSobj.Field126__c = String.valueOf(
									CommUtils.nullToZero(pTttendFooter.amoutSalesPrice)
									- CommUtils.nullToZero(pTttendFooter.amoutDiscountPrice)
									- CommUtils.nullToZero(pTttendFooter.amoutSubscriptionPrice) 
									- CommUtils.nullToZero(pTttendFooter.amoutCouponPayPrice) 
									- CommUtils.nullToZero(pTranFooter.amoutAdvancesReceived)
									);
	}

	/**
	* 最新会計支払情報を取得する
	* pAccIds: 会計IDS[1部屋N泊予約]
	* 前受金で自動作成された支払情報は明細に非表示する
	**/
	private Boolean refreshTTendInfo(List<Id> pAccIds) {
		
        if (pAccIds == null) pAccIds = new List<Id>();
        
        // 会計支払情報格納
		pExistTtendMap = new Map<Id, List<TTend__c>>();		// 会計単位の支払情報を格納するMAP<会計ID/支払情報配列>
		pExistTtendItemMap = new Map<Id, TTend__c>();		// 既存の支払情報格納MAP<会計支払ID/会計支払明細>
		//pArPaymentInfoMap = new Map<Id, Map<Id, TTend__c>>();	// Map<会計ID, Map<会計明細ID, 支払情報>>
		pArPaymentInfoMap = new Map<Id, List<TTend__c>>();	// Map<会計ID, Map<会計明細ID, 支払情報>>
		pBatchPaymentInfoMap = new Map<Id, List<TTend__c>>();	// バッチ OR 旧会計画面から作成された支払情報
		
		// 関連会計情報が存在する場合、関連会計の既存の支払情報を取得する
		if (!pAccIds.isEmpty()) {
			// 検索SQLの作成
			String queryStr  = TTendSel + ' Where Field1__c In :pAccIds ';
			queryStr += ' Order By RowNo__c, Name ';
//System.debug(loggingLevel.ERROR, 'queryStr:::' + queryStr);
			// 既存の会計支払情報を取得する
			// 会計支払情報から会計明細に変換を行う
			for (TTend__c sobj: DataBase.query(queryStr)) {
				// 会計ID
				String accId = sobj.Field1__c;
				
				// 作成した会計支払情報は前受け金経由で作成の場合
				// 会計支払の支払商品項目設定内容
				Id payProdId = sobj.PayProductRef__c;
				// 前受金で作成した会計支払情報の場合、会計明細の前受金と重複表示の回避するため、既存の支払情報から該当情報を外す
				if (payProdId != null && sobj.PayProductRef__r.ActionType__c == CommConst.PROD_ACTION_TYPE_AR ) {
					if (!pArPaymentInfoMap.containsKey(accId)) pArPaymentInfoMap.put(accId, new List<TTend__c>());
					//pArPaymentInfoMap.get(accId).put(sobj.ArTranId__c, sobj);
					pArPaymentInfoMap.get(accId).add(sobj);
					continue;
				}
				/* 一時封印(バッチで会計支払い作成しないので)
				// バッチで自動作成した支払情報は表示対象外
				if (sobj.EventSource__c == CommConst.TTEND_EVENTSOURCE_BATCH) {
					if (!pBatchPaymentInfoMap.containsKey(accId)) pBatchPaymentInfoMap.put(accId, new List<TTend__c>());
					pBatchPaymentInfoMap.get(accId).add(sobj);
					continue;
				}*/
				// 前受け金以外の支払情報は取得、格納する
				if (!pExistTtendMap.containsKey(accId)) pExistTtendMap.put(accId, new List<TTend__c>());
				pExistTtendMap.get(accId).add(sobj);
				// 会計明細IDー＞会計明細オブジェクト
				pExistTtendItemMap.put(sobj.id, sobj);
//System.debug(LoggingLevel.INFO, 'pExistTtendItemMap:::' + pExistTtendItemMap);
			}
		}
		return true;
	}

	/**
	* 最新会計明細情報を取得する
	* 対応日に会計明細情報がなかったの場合、見積明細情報を取得、明細に表示を行う
	* 支払情報から会計明細に変換、表示処理があります
	* pAccIds: 関連の会計ID's
	* pTtendMap:  会計単位の既存の支払情報
	**/
	private Boolean refreshTran1Info(List<Id> pAccIds, Map<Id, List<TTend__c>> pTtendMap) {
		
//System.debug(LoggingLevel.ERROR, 'refreshTran1Info::::'  + pAccIds);	
//System.debug(LoggingLevel.ERROR, 'refreshTran1Info::::'  + pTtendMap);	
		if (pAccIds == null) pAccIds = new List<Id>();

		// 会計明細列と会計明細集計変更初期化
        oTranSobjLst = new List<TranItem>();
        oStickyHeadList = new List<TranItem>();
        // 並び順ソースするため
		Map<String, TranItem> locSortMap = new Map<String, TranItem>();
		// 既存の明細情報の関連の売上、会計情報を格納する
		// Map<会計ID, 会計明細リスト>
		Map<Id, List<Tran1__c>> locExistTranMap = new Map<Id, List<Tran1__c>>();
		// 2018/07/27 宿泊税計算 WGCH BEGIN
		HotelTaxDefineInfo hotelInfo = new HotelTaxDefineInfo();
		// 2018/07/27 宿泊税計算 WGCH END
		// N泊１部屋の関連会計明細情報を一括取得する
		// 簡易会計から作成した会計データの場合、予約関連のIDがNULL
		if (!pAccIds.isEmpty()) {
			String queryStr = '';
			queryStr  = TranSel + ' Where Field1__c in :pAccIds ';
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			Map<String, List<PlanBrkInfo>> planBrkInfoMap = new Map<String, List<PlanBrkInfo>>();
			if(!isReducedTaxFlg) queryStr += ' And ParentTran1Ref__c = null  ';	// 会計明細はプラン明細以外
			// 2019/07/30 軽減税率機能対応 WGCH END
			queryStr += ' Order By RowNo__c,name ';	// 売上日、並び順、NO
			// 2018/07/27 宿泊税計算 WGCH BEGIN
			Set<String> pIdSet = new Set<String>();
			// 2018/07/27 宿泊税計算 WGCH END
			// 既存の会計明細情報を取得する
			for (Tran1__c sobj: DataBase.query(queryStr)) {
				// 2018/07/27 宿泊税計算 WGCH BEGIN
				if(!hotelInfo.hotelTaxDefInstance.isEmpty() && sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) pIdSet.add(sobj.Id);
				// 2018/07/27 宿泊税計算 WGCH END
				// 2019/07/30 軽減税率機能対応 WGCH BEGIN
				if(sobj.ParentTran1Ref__c != null){
					// PlanBrkDn 的信息Key[也就是主的Id]
					String key = sobj.ParentTran1Ref__c;
					if(!planBrkInfoMap.containsKey(key)) planBrkInfoMap.put(key, new List<PlanBrkInfo>());
					planBrkInfoMap.get(key).add(setPlanBrkInfo(sobj));
				} else {
					// 2013/01/28 ADD *重要* [既存のプラン明細連携情報は再表示する場合、必ずクリアする]
					// 2019/12/30 会計機能、会計画面でプランの内訳を編集出来るように WGCH BEGIN
					// sobj.PlanDetailSyncInfo__c = null;
					if(!isPlanEditFlg) sobj.PlanDetailSyncInfo__c = null;
					// 2019/12/30 会計機能、会計画面でプランの内訳を編集出来るように WGCH END
	/*				
					// 明細に前受け金情報を存在するがどうか、チェツクを行う
					TranItem item = new TranItem(sobj, -1);
					// 明細に存在している前受金情報をリストに格納する
					if (item.isARProduct()) {
						arProductLst.add(item.cloneAll());
					}
	*/				
					// 会計単位の会計明細リストを取得する
					Id accId = sobj.Field1__c;
					if (!locExistTranMap.containsKey(accId)) locExistTranMap.put(accId, new List<Tran1__c>());
					locExistTranMap.get(accid).add(sobj);
				}
					// 2019/07/30 軽減税率機能対応 WGCH END
			}
			// 2019/10/08 メディア毎消費税額修正对应 WGCH BEGIN
			batchPlanBrkInfoMap = planBrkInfoMap;
			// 2019/10/08 メディア毎消費税額修正对应 WGCH END
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			planBrkInfoMapJson = JSON.serialize(planBrkInfoMap);
			// 2019/07/30 軽減税率機能対応 WGCH END
			// 2018/07/27 宿泊税計算 WGCH BEGIN
			if(!pIdSet.isEmpty()){ // 处理Plan明细(商品处理种别=>室料商品)
				// 2018/12/15 宿泊税计算修正对应 WGCH BEGIN
				// String pdQueryStr = ' Select ParentTran1Ref__c, Field39__c From Tran1__c Where ParentTran1Ref__c in: pIdSet And ActionType__c = \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_RP) + '\'';
				String pdQueryStr = ' Select ParentTran1Ref__c, Field20__c From Tran1__c Where ParentTran1Ref__c in: pIdSet And ActionType__c = \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_RP) + '\'';
				// 2018/12/15 宿泊税计算修正对应 WGCH END
				for (Tran1__c sobj: DataBase.query(pdQueryStr)) {
					if(!hotelInfo.planItemPriceMap.containsKey(sobj.ParentTran1Ref__c)) hotelInfo.planItemPriceMap.put(sobj.ParentTran1Ref__c, new List<Decimal>());
					// 明细 -> 単価(税込)
					// 2018/12/15 宿泊税计算修正对应 WGCH BEGIN
					// hotelInfo.planItemPriceMap.get(sobj.ParentTran1Ref__c).add(CommUtils.nullToZero(sobj.Field39__c));
					hotelInfo.planItemPriceMap.get(sobj.ParentTran1Ref__c).add(CommUtils.nullToZero(sobj.Field20__c));
					// 2018/12/15 宿泊税计算修正对应 WGCH END
				}
			}
			// 2018/07/27 宿泊税計算 WGCH END
		}
		// 2018/07/27 宿泊税計算 WGCH BEGIN
		hotelInfoJson = JSON.serialize(hotelInfo);
		// 2018/07/27 宿泊税計算 WGCH END
//System.debug(loggingLevel.ERROR, 'locExistTranMap:::' + locExistTranMap);
		// 予約あり、会計なしのデータに対して、予約の見積もり明細を取得する
		// 未チェックインの会計情報が存在する場合、存在している見積もり明細から会計明細に表示する対応
		// 2015/05/23 見積明細は新会計画面に非表示する「一時封印」
		/*
		for (Id accId : pRelAccountIdList) {
			// 該当予約は既にチェックイン済する場合、該当予約の見積もり明細を表示対象外
			// 業務流れに対して、チェックイン前に、「新規会計」ボタンで、会計直接作成を行うので、該当様な状況の場合、見積もり明細も出ってくる
//System.debug(loggingLevel.INFO, 'pRelAccountsMap.get(accId).Relreserve__r.Field298__c:::' + pRelAccountsMap.get(accId).Relreserve__r.Field298__c);
			if (!CommUtils.isBlank(pRelAccountsMap.get(accId).Relreserve__r.Field298__c)) {
				// 既に会計情報存在の予約に対して、見積もり明細取得処理対象外に設定
				pRelLeadsMap.remove(pRelAccountsMap.get(accId).Relreserve__c);
			}
		}*/
//System.debug(loggingLevel.ERROR, 'pRelLeadsMap:::' + pRelLeadsMap);	
		// 予約データに未チェックインして、会計データがなかったの場合
		Map<Id, List<BookingEstimateItem__c>> locEstItemsMap = new Map<Id, List<BookingEstimateItem__c>>();
		// 予約の見積もり明細から紐付けして、明細に表示する
		// 2015/05/23 見積明細は新会計画面に非表示する「一時封印」
		/*
		if (!pRelLeadsMap.isEmpty()) {
			List<BookingEstimateItem__c> estItems = [
				select id, name, refBooking__c, ActionType__c,Amount__c,RowNo__c,refBooking__r.EntryTime__c,UnitPriceDefKb__c,
				refAccountMaster__c, refAccountMaster__r.Name,refAccountMaster__r.Field3__c, TaxRate__c, ServiceRate__c,SpecialTax__c,UnitPrice__c,
				GoukeinoneTax__c, SpTotal__c, ProductName__c, PlanDetailSyncInfo__c,PaymentType__c
				from BookingEstimateItem__c where refBooking__c = :pRelLeadsMap.keySet() and ParentBookingItemRef__c = null Order By RowNo__c,Name
				];
			// Map<予約ID/関連の見積明細>
			
			for (BookingEstimateItem__c est : estItems) {
				// 予約到着日は利用日に設定、
				//Tran1__c convertedTran = convertEstToTran(est);
				//oTranSobjLst.add(convertedTran,);
				Id leadId = est.refBooking__c;
				if (!locEstItemsMap.containsKey(leadId)) locEstItemsMap.put(leadId, new List<BookingEstimateItem__c>());
				locEstItemsMap.get(leadId).add(est);
			}
		}*/
		// <予約ID/会計ID>
		//Map<Id, Id> locLeadAccountIdMap = new Map<Id, Id>();
		// <予約ID/List<会計ID>[1予約複数関連会計ID情報格納] 
		Map<Id, List<Id>> locLeadAccountIdMap = new Map<Id, List<Id>>();
		for (Id accId : pRelAccountIdList) {
			AccountAcount__c acc = pRelAccountsMap.get(accId);
			if (!locLeadAccountIdMap.containsKey(acc.Relreserve__c)) {
				locLeadAccountIdMap.put(acc.Relreserve__c, new List<Id>());
			}
			//locLeadAccountIdMap.put(acc.Relreserve__c, acc.Id);
			locLeadAccountIdMap.get(acc.Relreserve__c).add(acc.Id);
		}
		// 予約から順番で、関連する情報設定を行う List<Id> pRelLeadIdList
		for (Id leadId : pRelLeadIdList) {
//System.debug(LoggingLevel.Error, '------ ['+leadId+']-------');
			// 予約に対して、会計情報が存在すると、会計明細情報に格納する
			if (locLeadAccountIdMap.containsKey(leadId)) {
//System.debug(LoggingLevel.Error, '------ [oTranSobjLst]【1】-------' + oTranSobjLst);
				// 該当予約に関連の会計情報存在チェックを行う
				//Id accId = locLeadAccountIdMap.get(leadId);
				// 1予約複数会計情報の関連明細を格納する
				for (Id accId : locLeadAccountIdMap.get(leadId)) {
					//System.debug(LoggingLevel.Error, '------ [ACCOUNT]-------' + accId);

					// 該当会計明細は並び順未調整の状態するがどうか、
					Boolean isInitShowFlg = false;
					if (locExistTranMap.containsKey(accId)) {
						// 該当会計に既存の【会計明細】情報を取得する
						if (locExistTranMap.containsKey(accId)) {
							for (Tran1__c sobj: locExistTranMap.get(accId)) {
								if (sobj.RowNo__c == 0 || sobj.RowNo__c == null) {
									isInitShowFlg = true;
									break;
								}
							}
						}
						// 該当会計に既存の【会計支払】情報を取得する
						if (!isInitShowFlg && pTtendMap.containsKey(accId)) {
							for (TTend__c sobj: pTtendMap.get(accId)) {
								if (sobj.RowNo__c == 0 || sobj.RowNo__c == null) {
									isInitShowFlg = true;
									break;
								}
							}
						}
					}
					// 該当会計に既存の【会計明細】情報を取得する
					if (locExistTranMap.containsKey(accId)) {
						// 該当会計の会計明細は全部取得、画面に表示する
						for (Tran1__c sobj: locExistTranMap.get(accId)) {
	//						TranItem item = new TranItem(sobj, oTranSobjLst.size());
							TranItem item = new TranItem(sobj, locSortMap.size());
	//						oTranSobjLst.add(item);
							locSortMap.put(getTranListSortKey(sobj, null, null,isInitShowFlg), item);
						}
	//System.debug(LoggingLevel.Error, '------ [oTranSobjLst]【2】-------' + oTranSobjLst);
					}

					// 該当会計に既存の【会計支払】情報を取得する
					if (pTtendMap.containsKey(accId)) {
	//System.debug(loggingLevel.ERROR, 'pTtendMap.containsKey(accId):::' + pTtendMap.get(accId));
						for (TTend__c sobj: pTtendMap.get(accId)) {
							// 格納している情報は前受付金から作成する場合、画面表示対象
							// チェックインから自動作成した会計支払情報は表示対象外
							// 予約のチェックイン処理後、自動的に一件会計支払情報作成を行う[支払金額：０]
							TTendItem tmpTtend = new TTendItem(sobj, -1);
							if (tmpTtend.isAutoGenByCheckin) continue; // チェックイン機能で自動作成の支払情報[預かり金額空白]は画面から非表示
							
							// 会計支払情報から会計明細に表示する[変換]
							Tran1__c convertedTran = convertTendToTran(sobj);
	//System.debug(loggingLevel.ERROR, 'convertedTran:::' + convertedTran);
							if (convertedTran != null) {
	//							TranItem item = new TranItem(convertedTran, oTranSobjLst.size());
								TranItem item = new TranItem(convertedTran, locSortMap.size());
								// 会計支払の関連変数設定を行う
								item.tranId = sobj.id;
								// 2021/02/28 CPU LIMITの最適化 WGCH BEGIN
								item.isNoUpdate = !CommUtils.isBlank(item.tranId);
								// 2021/02/28 CPU LIMITの最適化 WGCH END
								item.amoutExcTax = item.amoutIncTax;
	//							oTranSobjLst.add(item);
								locSortMap.put(getTranListSortKey(null, sobj, null,isInitShowFlg), item);
							}
						}
					}
				} // for (Id accId : locLeadAccountIdMap.get(leadId))
			} // if (locLeadAccountIdMap.containsKey(leadId)) {
			
			// 存在なければ、見積もり明細から会計明細として、画面に表示する
//			else {
//System.debug(LoggingLevel.Error, '------ [LEAD]-------');
				// 該当予約の関連見積もり明細情報を取得する
				if (locEstItemsMap.containsKey(leadId)) {
					List<BookingEstimateItem__c> ests = locEstItemsMap.get(leadId);
//System.debug(LoggingLevel.Error, '------ [EST]-------'+ests);
					for (BookingEstimateItem__c est : ests) {
						Tran1__c convertedTran = convertEstToTran(est);
						if (convertedTran != null) {
//							TranItem item = new TranItem(convertedTran, oTranSobjLst.size());
							TranItem item = new TranItem(convertedTran, locSortMap.size());
							item.amoutExcTax = CommUtils.nullToZero(est.GoukeinoneTax__c);		// 税抜き合計金額設定
							item.bookEstItemId = est.Id;
							item.isEstItemFlg = true;
//							oTranSobjLst.add(item);
							locSortMap.put(getTranListSortKey(null, null, est, true), item);
						}
					} // for (BookingEstimateItem__c est : ests) {
				} // if (locEstItemsMap.containsKey(leadId)) {
//			}
		}
		
		// 簡易会計の場合、対応する
		if(pRelLeadIdList.isEmpty()) {
			for (Id accId : pRelAccountIdList) {
				// 該当予約に関連の会計情報存在チェックを行う
				//Id accId = locLeadAccountIdMap.get(leadId);
//System.debug(LoggingLevel.Error, '------ [ACCOUNT]-------');
				// 該当会計に既存の会計明細情報を取得する
				if (locExistTranMap.containsKey(accId)) {
					
					// 該当会計の明細利用総金額合計する
					for (Tran1__c sobj: locExistTranMap.get(accId)) {
//						TranItem item = new TranItem(sobj, oTranSobjLst.size());
						TranItem item = new TranItem(sobj, locSortMap.size());
//						oTranSobjLst.add(item);
						locSortMap.put(getTranListSortKey(sobj, null, null, false), item);
					}
				}
				// 該当会計に既存の会計支払情報を取得する
				if (pTtendMap.containsKey(accId)) {
//System.debug(loggingLevel.ERROR, 'pTtendMap.containsKey(accId):::' + pTtendMap.get(accId));
					for (TTend__c sobj: pTtendMap.get(accId)) {
						// チェックインから自動作成した会計支払情報は表示対象外
						//TTendItem tmpTtend = new TTendItem(sobj, -1);
						//if (!tmpTtend.isPaymented) continue;
						
						// 会計支払情報から会計明細に表示する
						Tran1__c convertedTran = convertTendToTran(sobj);
						if (convertedTran != null) {
//							TranItem item = new TranItem(convertedTran, oTranSobjLst.size());
							TranItem item = new TranItem(convertedTran, locSortMap.size());
							// 会計支払の関連変数設定を行う
							item.tranId = sobj.id;
							// 2021/02/28 CPU LIMITの最適化 WGCH BEGIN
							item.isNoUpdate = !CommUtils.isBlank(item.tranId);
							// 2021/02/28 CPU LIMITの最適化 WGCH END
							item.amoutExcTax = item.amoutIncTax;
//							oTranSobjLst.add(item);
							locSortMap.put(getTranListSortKey(null, sobj, null, false), item);
						}
					}
				}
			}
		}
		system.debug(logginglevel.info,'locSortMap::' + locSortMap.keySet());
		// 並び順を行う
		oTranSobjLst.addAll(sortTranItems(locSortMap));
		// 2019/01/30 入湯税の自動設定機能対応 WGCH BEGIN
		// 2019/02/28 入湯税の自動設定機能連泊予約分别設定対応 BEGIN
		/*
		if(accBathTaxItem != null){
			// 重置一下序号
			accBathTaxItem.index = oTranSobjLst.size();
			accBathTaxItem.rowNo = oTranSobjLst.size();
			oTranSobjLst.add(accBathTaxItem.clone()); // 克隆防止地址共存
			accBathTaxItem = null; // 置空
		}
		*/
		// 存在的入汤税明细的时候进入处理
		if(accBathTaxItemLst != null && !accBathTaxItemLst.isEmpty()){
			for(TranItem item : accBathTaxItemLst){
				// 重置一下序号
				item.index = oTranSobjLst.size();
				item.rowNo = oTranSobjLst.size();
				oTranSobjLst.add(item.clone()); // 克隆防止地址共存
			}
			accBathTaxItemLst = new List<TranItem>(); // 置空
		}
		// 2019/02/28 入湯税の自動設定機能連泊予約分别設定対応 END
		// 2019/01/30 入湯税の自動設定機能対応 WGCH END
//System.debug(LoggingLevel.Error, '------ [oTranSobjLst]【END】[A]-------' + oTranSobjLst);	
//System.debug(loggingLevel.ERROR, 'locExistTranMap:::' + locExistTranMap);
		/*
		List<TranItem> itms = new LIst<TranItem>();
		for (TranItem item : oTranSobjLst) {
			if (!CommUtils.isBlank(item.productNm)) {
				itms.add(item);
			}
		}*/
		itemJson = JSON.serialize(oTranSobjLst);
		// 残り入力情報初期化する
		Integer appendRsSize = TRAN1_INPUT_DEF_ROWS - Math.Mod(oTranSobjLst.size(), TRAN1_INPUT_DEF_ROWS);
		// 入力できる行列を準備する
		for (Integer i = 0; i < appendRsSize; i++) {
			oTranSobjLst.add(new TranItem(new Tran1__c(),oTranSobjLst.size()));
		}
		// 2016/09/19 売掛のご請求先存在チェックを追加する BEGIN
		// 2016/10/10 売掛のご請求先存在チェックを外す BEGIN
		//relCheck();
		// 2016/10/10 売掛のご請求先存在チェックを外す BEGIN
		// 2016/09/19 売掛のご請求先存在チェックを追加する END
//System.debug(LoggingLevel.Error, '------ [oTranSobjLst]【END】[B]-------' + oTranSobjLst);	
		return true;
	}
	/** 指定のキーにより、明細表示順を戻る　
	*	itemsMap: Map<ソートキー, TranItem>:
	*/
	private List<TranItem> sortTranItems(Map<String, TranItem> locSortMap) {
		
		List<TranItem> sortRsLst = new List<TranItem>();
		List<String> locSortKeyLst = new List<String>(locSortMap.keySet());
		locSortKeyLst.sort();
		Integer locIndex = 0;
		// 並び順情報を再設定を行う
		for (String key : locSortKeyLst) {
			TranItem item = locSortMap.get(key);
			item.index = locIndex;
			// アイコンのURLを設定する
			setPaymentDetailIconUrl(item);
			// 簡易関係の場合、明細の利用日は自動的に売上日に設定する
			// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH BEGIN
			if(oAcountSobj.Relreserve__c == null && CommConst.BOOKEST_USERDATE_FLG && oAcountSobj.Relreserve__c != null && oAcountSobj.Relreserve__r.EntryTime__c != null){
				item.sobj.UseDate__c = oAcountSobj.Relreserve__r.EntryTime__c.date();
			}
			// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH END
			if (oAcountSobj.Relreserve__c == null) item.sobj.UseDate__c = oAcountSobj.SalesDate__c;
			sortRsLst.add(item);
			locIndex++;
		}
		return sortRsLst;
	}
	
	/** 並び順用キーを連結、作成する */
	private String getTranListSortKey(Tran1__c tran, TTend__c tend, BookingEstimateItem__c est, Boolean isInitFlg) {
		if (isInitFlg) {
			if (tran != null) 	return '1_9,999_' + tran.RelAccount__r.Name + '_' + CommUtils.paddingLeftZero(CommUtils.nullToZero(tran.RowNo__c == null ? 9999: tran.RowNo__c),4) + '_' + tran.Name;
			if (tend != null) 	return '1_9,999_' + tend.RelAccount__r.Name + '_' + CommUtils.paddingLeftZero(CommUtils.nullToZero(tend.RowNo__c  == null ? 9999: tend.RowNo__c),4) + '_' + tend.Name;
			if (est != null) 	return '2_9,999_' + est.refBooking__r.EntryTime__c.format('yyyyMMdd') + '_' + CommUtils.paddingLeftZero(CommUtils.nullToZero(est.RowNo__c  == null ? 9999: est.RowNo__c),4) + '_' + est.Name;			
		} else {
			if (tran != null) 	return '1_' + CommUtils.paddingLeftZero(CommUtils.nullToZero(tran.RowNo__c == null ? 9999: tran.RowNo__c),4) + '_' + tran.RelAccount__r.Name + '_' + tran.Name;
			if (tend != null) 	return '1_' + CommUtils.paddingLeftZero(CommUtils.nullToZero(tend.RowNo__c  == null ? 9999: tend.RowNo__c),4) + '_' + tend.RelAccount__r.Name + '_' + tend.Name;
			if (est != null) 	return '2_' + CommUtils.paddingLeftZero(CommUtils.nullToZero(est.RowNo__c  == null ? 9999: est.RowNo__c),4) + '_' + est.refBooking__r.EntryTime__c.format('yyyyMMdd') + '_' + est.Name;
		}
		return '';
	}
	/** 支払情報のアイコンを設定する */
	private void setPaymentDetailIconUrl(TranItem item) {
		// 前受金　と　支払情報以外の明細の場合、対象になる
		if (!item.isPayProduct() && !item.isARProduct()) return;
		// 商品コードにより、画像を表示する
		if (payBtnInfoMap.containsKey(item.productCd)) {
			item.paymentIconUrl = payBtnInfoMap.get(item.productCd);
		}
		if (CommUtils.isBlank(item.paymentIconUrl)) item.paymentIconUrl = PAYICON_DEFAULT;
	}
	/**
	* 会計明細（支払）→会計支払情報に転換処理
	**/
	private TTend__c convertTranToTend(TranItem pTranItem) {
		// 会計明細→会計支払情報に変更を行う
		String paymentCd = getMediaCodeByName(PAYMENT_MATCH_MAP.get(pTranItem.sobj.PaymentType__c));
		//指定範囲外の支払種別:
		if (CommUtils.isBlank(paymentCd)) throw new CommException(Label.CONST_006_0418 + paymentCd);
		
		// 会計支払情報格納
		TTend__c newTtend = null;
		// 既存の会計支払情報の場合[pTranItem.tranId.startsWith(TTEND_KEY_PREFIX)→条件追加の理由：見積明細から支払情報を登録される場合]
		if (!CommUtils.isBlank(pTranItem.tranId) && pTranItem.tranId.startsWith(TTEND_KEY_PREFIX)) {
			// 画面起動する場合、取得した会計支払情報MAPから既存の支払情報を取得して、関連項目更新を行う
			// ページから、商品切替を行う場合でも、新規の会計支払情報を作成を行う/数量、利用日、単価、数量、総金額、並び順、利用日更新を行う
			newTtend = pExistTtendItemMap.get(pTranItem.tranId);
//System.debug(logginglevel.ERROR, 'convertTranToTend::newTtend|' + newTtend);
			// 支払情報
			newTtend.Field2__c = paymentCd;
			newTtend.Field3__c = PAYMENT_MATCH_MAP.get(pTranItem.sobj.PaymentType__c);
			// 2019/10/08 メディア毎消費税額修正对应 WGCH BEGIN
			/*
			// 画面に入力金額は預かり金額に更新
			newTtend.Field19__c = CommUtils.nullToBlank(pTranItem.amoutIncTax);
			// 利用金額
			newTtend.Field20__c = CommUtils.nullToBlank(pTranItem.usedAmount);
			// お釣り金額
			newTtend.Field21__c = CommUtils.nullToBlank(pTranItem.changeAmout);
			*/
			// 画面に入力金額は預かり金額に更新
			newTtend.Field19__c = batchExcuteFlag ? newTtend.Field19__c : CommUtils.nullToBlank(pTranItem.amoutIncTax);
			// 利用金額
			newTtend.Field20__c = batchExcuteFlag ? newTtend.Field20__c : CommUtils.nullToBlank(pTranItem.usedAmount);
			// お釣り金額
			newTtend.Field21__c = batchExcuteFlag ? newTtend.Field21__c : CommUtils.nullToBlank(pTranItem.changeAmout);
			// 2019/10/08 メディア毎消費税額修正对应 WGCH END
			// 並び順項目
			newTtend.RowNo__c = pTranItem.sobj.RowNo__c;
			// 利用日情報更新項目
			newTtend.UseDate__c = pTranItem.sobj.UseDate__c;
			// 2021/05/30 #11228 bug fixed by zy BEGIN
			// 2021/05/31 #11692 bug fixed by zy BEGIN
			if (!CommUtils.isBlank(pTranItem.productNm) || !CommUtils.isBlank(pTranItem.orgProductNm)) {
				newTtend.PayProductName__c = CommUtils.isBlank(pTranItem.productNm) ? pTranItem.orgProductNm : pTranItem.productNm;	
			}
			// 2021/05/31 #11692 bug fixed by zy END
			// 2021/05/30 #11228 bug fixed by zy END	
		} else {
			String ttendPosNo = '';
			newTtend = 
				new TTend__c(
	                // *********** 初期値設定 **********
	                Field4__c = '1',
	                Field5__c = '1',
	                POSNo__c = DEF_INS_POS_NO,
	                // *********** 計算額設定 **********
	                // 支払方法
	                Field2__c = paymentCd,
	                Field3__c = PAYMENT_MATCH_MAP.get(pTranItem.sobj.PaymentType__c),
					// 支払商品情報の自動設定
					PayProductRef__c = pTranItem.sobj.Field7__c,
					PaymentType__c = pTranItem.sobj.PaymentType__c,
					PayProductName__c = pTranItem.productNm,
					UseDate__c = pTranItem.sobj.UseDate__c,
	                // *********** 合計金額 **********
					// 画面に入力金額は預かり金額に更新
					Field19__c = CommUtils.nullToBlank(pTranItem.amoutIncTax),
					// 利用金額
					Field20__c = CommUtils.nullToBlank(pTranItem.usedAmount),
					// お釣り金額
					Field21__c = CommUtils.nullToBlank(pTranItem.changeAmout),
	                // メディア毎消費税額設定を行う【あとで計算を行う】
	                Field25__c = String.valueOf(0),
	                // 並び順項目
	                RowNo__c = pTranItem.sobj.RowNo__c
	                // *********** 参照関係設定 **********[新規登録する場合、現在の画面の会計に紐付く]
	                // 売上情報
	                //RelAccount__c = pTranItem.sobj.RelAccount__c,
	                // 会計情報
	                //Field1__c = pTranItem.sobj.Field1__c
				);
				if (useDateSimpleMode){	// 利用日は売上日と連動なし
					newTtend.RelAccount__c = oAcountSobj.frs__c;
					newTtend.Field1__c = oAcountSobj.Id;
				}
 				// 支払いポース機能追加　by　zy BEGIN
 				if (!CommUtils.isBlank(pTranItem.sobj.POSNo__c)) {
 					if (CommUtils.isBlank(ttendPosNo)) ttendPosNo = chgDefNoToCurpos(pTranItem.sobj.POSNo__c);
 					newTtend.POSNo__c = ttendPosNo;
 				}
 				// 支払いポース機能追加　by　zy END
		}
		// 2015/03/03 BUGFIX 会計商品から「カード種別、金券種別、金券数量、単価」情報を設定する
		if (paymentCd == CommConst.MEDIA_TYPE_CD_02) {
			// カード種別に反映する
			newTtend.CardTypeLst__c = pTranItem.productNm;
		} else if ( paymentCd == CommConst.MEDIA_TYPE_CD_11 ||
					paymentCd == CommConst.MEDIA_TYPE_CD_12) {
			// 金券種別
		    newTtend.CouponTypeLst__c = pTranItem.productNm;
		    // 金券単価と数量
		    // 2020/01/14 単価金額はカンマを入れる場合、会計明細エラーが発生問題回避 WSQ BEGIN
		    newTtend.Field16__c = CommUtils.nullToBlank(CommUtils.nullToZero(pTranItem.sobj.Field20__c));
		    newTtend.Field17__c = CommUtils.nullToBlank(CommUtils.nullToZero(pTranItem.sobj.Field21__c));
		    // 2020/01/14 単価金額はカンマを入れる場合、会計明細エラーが発生問題回避 WSQ END
		}
		// 請求書非表示設定
		newTtend.InvoiceNoShowFlg__c = pTranItem.sobj.InvoiceNoShowFlg__c;
		// 請求書非表示に設定されている場合、画面に入力の単価と数量は関連項目に格納を行う
		// 2016/10/27 非表示機能とき、合計金額（税込）は０円でDBへ格納する、しない制御機能追加
		// 2020/01/30 非表示の一括解除、あるいは金額を0円にしない非表示設定の追加 WGCH BEGIN
		// if (newTtend.InvoiceNoShowFlg__c && accountNoSetAmountWhenNoShowFlg) {
		if ((accountNoSetAmountWhenNoShowMode == APPOTION_ACCOUNTNOSHOW_1) && newTtend.InvoiceNoShowFlg__c && accountNoSetAmountWhenNoShowFlg) {
		// 2020/01/30 非表示の一括解除、あるいは金額を0円にしない非表示設定の追加 WGCH END
			newTtend.TempSaveExtInfo__c = CommUtils.nullToBlank(pTranItem.sobj.Field20__c) + ':' + CommUtils.nullToBlank(pTranItem.sobj.Field21__c);
		} else {
			newTtend.TempSaveExtInfo__c = null;
		}
		if (!useDateSimpleMode){	// 利用日は売上日と連動あり
			// 参照関係の再設定する
			// 2021/05/31 #11277 bug fixed by zy BEGIN
			newTtend.RelAccount__c = Commutils.isBlank(pTranItem.sobj.RelAccount__c )? oAcountSobj.frs__c : pTranItem.sobj.RelAccount__c;
			newTtend.Field1__c = Commutils.isBlank(pTranItem.sobj.Field1__c) ? oAcountSobj.Id : pTranItem.sobj.Field1__c;
			// 2021/05/31 #11277 bug fixed by zy END
		}
		// Cloneの参照情報をクリアする
		newTtend.PayProductRef__r = null;
		return newTtend;
	}
	/**
	* 会計支払→会計明細（支払）に転換表示処理
	**/
	private Tran1__c convertTendToTran(TTend__c pTendItem) {
		// 会計支払情報から会計明細に転換処理を行う
		// 会計支払情報に格納している商品IDにより、関連の会計明細に自動変更を行う
		// 支払情報に関連している会計商品がなかれば、支払Mediaにより、固定の支払情報を変更する
		// 支払商品の参照IDがNULLの場合（過去の会計支払情報対応するため）、支払Mediaにより、固定の商品を転換を行う[TODO]
		// RowNo__c
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
			//if (pTendItem.UseDate__c == null) pTendItem.UseDate__c = pTendItem.RelAccount__r.Salesday__c;
		}
		// 単価と数量項目を設定されている場合、該当単価と数量はそのまま画面に表示が必要
		String unitPrice = pTendItem.Field19__c;
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
			,Field23__c = pTendItem.Field19__c	// 合計金額 ←　預かり金額
			,Field21__c = quality			// 数量１固定
			,Field5__c = pTendItem.PayProductName__c
			,TaxRate__c = null				// 消費税
			,ServiceRate__c = null			// サビース料
			,SpecialTax__c = 0			// 特別税
			,UseDate__c = pTendItem.UseDate__c	// 利用日
			,RelAccount__c = pTendItem.RelAccount__c
			,Field1__c = pTendItem.Field1__c
			,Field1__r = pTendItem.Field1__r
			,InvoiceNoShowFlg__c = pTendItem.InvoiceNoShowFlg__c	// 請求書非表示
			,RowNo__c = pTendItem.RowNo__c
		);
		// 請求書非表示の場合、画面に入力の単価と数量は自動表示を行う
		if(tran.InvoiceNoShowFlg__c && !CommUtils.isBlank(pTendItem.TempSaveExtInfo__c)) {
			String[] extInfs = pTendItem.TempSaveExtInfo__c.split(':');
			if (extInfs.size() == 2) {
				tran.Field20__c = extInfs[0];
				tran.Field21__c = extInfs[1];
			}
		}
		return tran;
	}

	/**
	* 見積明細→会計明細に転換表示処理
	**/
	private Tran1__c convertEstToTran(BookingEstimateItem__c pEstItem) {
		Date useDate = pEstItem.refBooking__r.EntryTime__c.date();
		// 
		Tran1__c tran = new Tran1__c(
			Field7__c = pEstItem.refAccountMaster__c // 商品コード
			,Field7__r = pEstItem.refAccountMaster__r.clone(false,true)
			,ActionType__c = pEstItem.ActionType__c	// 商品処理種別
			,PaymentType__c = pEstItem.PaymentType__c // 支払種別
			,Field20__c = CommUtils.nullToBlank(pEstItem.UnitPrice__c)	// 単価 ←　預かり金額
			,Field23__c = CommUtils.nullToBlank(pEstItem.SpTotal__c)	// 合計金額 ←　預かり金額
			,Field21__c = CommUtils.nullToBlank(pEstItem.Amount__c)			// 数量１固定
			,Field5__c = pEstItem.ProductName__c
			,TaxRate__c = pEstItem.TaxRate__c				// 消費税
			,ServiceRate__c = pEstItem.ServiceRate__c			// サビース料
			,SpecialTax__c = pEstItem.SpecialTax__c			// 特別税
			,UseDate__c = useDate		// 利用日	
			,RelAccount__c = null
			,Field1__c = null
			,UnitPriceDefKb__c = pEstItem.UnitPriceDefKb__c
		);
		return tran;
	}
	/**
	* 会計明細→見積明細に転換表示処理
	**/
	private BookingEstimateItem__c convertTranToEst(TranItem tran) {
		BookingEstimateItem__c est = new BookingEstimateItem__c(
			 Id = tran.bookEstItemId
			,PlanDetailSyncInfo__c = tran.sobj.PlanDetailSyncInfo__c
			,UnitPrice__c = CommUtils.nullToZero(tran.sobj.Field20__c)
			,SpTotal__c = CommUtils.nullToZero(tran.sobj.Field23__c)
			,Amount__c = CommUtils.nullToZero(tran.sobj.Field21__c)
			,SpecialTax__c = CommUtils.nullToZero(tran.sobj.SpecialTax__c)
			//,ProductName__c = CommUtils.nullToBlank(tran.sobj.Field5__c)
			,ProductName__c = CommUtils.isBlank(tran.productNm) ? tran.orgProductNm : tran.productNm
			,refAccountMaster__c = tran.sobj.Field7__c
		);
//System.debug(loggingLevel.INFO, 'est:::' + est);
		return est;
	}
	
	
	/**
	* 初期化処理関数
	* 取得した全部の会計情報の中に、新会計メニューリリース前の会計データが存在する場合、
	**/
	public Pagereference initAction() {
		// 初期表示用データを設定する
		this.initInfo((AccountAcount__c)ctrl.getRecord());
		// 既存の会計情報に旧会計情報が存在すると、旧会計画面起動する
		Boolean isHasOldAccDataFlg = false;
		for (Id accId : pRelAccountIdList) {
			AccountAcount__c acc = pRelAccountsMap.get(accId);
			if (!acc.IsNewLayout__c) {
				isHasOldAccDataFlg = true;
				break;
			}
		}
		// 過去の会計情報の場合
		if (oPage.dataStatus != PAGE_STATUS.INS && isHasOldAccDataFlg) {
			//paramMap
			PageReference pageRef = new PageReference('/apex/BillInput');
			pageRef.getParameters().putAll(paramMap);
            pageRef.setRedirect(true);
            return pageRef;
		}
		return null;
	}
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
	
    /**
    * キャセンル画面に遷移する
    **/ 
    public Pagereference gotoCancel() {
        String retUrl = paramMap.get('retURL');
        if (!CommUtils.isBlank(retUrl)) {
            PageReference pageRef = new PageReference(retUrl);
            pageRef.setRedirect(true);
            return pageRef;
        }
        return null;
    }
    
	/********************************
	* 明細の行追加機能
	********************************/
	public Pagereference addTran1Item() {
		
		Map<Integer, TranItem> locSortMap = new Map<Integer, TranItem>();
		for (TranItem item : oTranSobjLst) {
			// 画面表示順により、ソートを行う
			locSortMap.put(CommUtils.nullToIntZero(item.sobj.rowNo__c),item);
		}
		List<Integer> sortKeyLst = new List<Integer>();
		sortKeyLst.addAll(locSortMap.keySet());
		sortKeyLst.sort();
		
		oTranSobjLst.clear();
		// 2015/11/02 BugFix RowIndex再設定する BEGIN
		for (Integer key : sortKeyLst) {
			TranItem orgItem = locSortMap.get(key);
			orgItem.index = oTranSobjLst.size();
			oTranSobjLst.add(orgItem);
		}
		// 2015/11/02 BugFix RowIndex再設定する END

		for (Integer i = 0; i < TRAN1_INPUT_DEF_ROWS; i++) {
			TranItem newItem = new TranItem(new Tran1__c(RelAccount__c = oAcountSobj.frs__c), oTranSobjLst.size());
			oTranSobjLst.add(newItem);
		}
		// 無効なデータの消費税とサービス料０からNULLに設定する
		for (TranItem item : oTranSobjLst) {
			if (CommUtils.isBlank(item.productNm)) {
				if (item.sobj.TaxRate__c == 0) item.sobj.TaxRate__c = null;
				if (item.sobj.ServiceRate__c == 0) item.sobj.ServiceRate__c = null;
			}
		}
		return null;
	}
	
	/********************************
	 * 会計情報新規作成[直接会計新規作成機能]
	 ********************************/
	public Pagereference insertData() {
// 2016/02/19 ログ出力機能を追加する BEGIN
serverlog.clear();
parseClineLog(clientLog);
serverlog.write_method_start('新規');
// 2016/02/19 ログ出力機能を追加する END
		// 事前チェック
		if (!preSaveCheck()) return null;
		Savepoint sp = Database.setSavepoint();
		try {
			// 会計情報新規登録を行う
			insert preUpdateAccountInf(new List<AccountAcount__c>{oAcountSobj});
	    	// 画面編集フラグを設定する
	    	oPage.dataStatus = PAGE_STATUS.UPD;
	    	// 最新インサート情報を取得する
	    	refreshAccoutAcountInfo(oAcountSobj.id);
	        // 関連情報を設定を行う
	        refreshTTendInfo(pRelAccountIdList);					// 会計支払情報初期化
	        refreshTran1Info(pRelAccountIdList, pExistTtendMap);	// 会計明細情報初期化
	    	// 関聯予約の人數を変更されると、予約情報更新を行う
	    	updRelLead(oAcountSobj.Relreserve__c);
		} catch (Exception e) {
			DataBase.rollBack(sp);
			String msg = e.getMessage();
			// 2017/05/04 自施設の予約や会計しか変更できないように権限管理機能 BEGIN
			//ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CommUtils.getFieldValidationMessage(msg)));
			if(!CommUtils.isFieldValidationMessage(msg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, msg));
			// 2017/05/04 自施設の予約や会計しか変更できないように権限管理機能 END
		}
// 2016/02/19 ログ出力機能を追加する BEGIN
serverlog.write_method_end();
writeLogToDb(serverlog.getAllLog(), oAcountSobj.Id);
// 2016/02/19 ログ出力機能を追加する END
	    return null;
	}
	/**
	* 2016/02/25 ログ出力機能 BEGIN
	**/
	public String clinetLogSplitChar{get{return '__';}}
	private void parseClineLog(String clientLog) {
		serverlog.write_method_start('ページ操作履歴');
		String locClientLog = CommUtils.nullToBlank(clientLog);
		if (CommUtils.isBlank(clientLog)) return;
		serverlog.write_log('*****ページアクションの操作履歴*****');
//		serverlog.write_log('LEN SIZE=' +clientLog.split(clinetLogSplitChar).size());
		for (String logLine : clientLog.split(clinetLogSplitChar)) {
			String[] logItems = logLine.split(',');
			if (logItems.size() < 3) continue;
			String logInfo = '';
			// 操作タイプ
			if (logItems[0] == 'INS') logInfo = '明細追加:';
			else if(logItems[0] == 'DEL') logInfo = '明細削除:';
			else logInfo = logItems[0];
			// 行目
			if (!CommUtils.isBLank(logItems[1])) logInfo += logItems[1] + '行目:';
			// 時刻
			DateTime locTime = DateTime.newInstance(Long.valueOf(logItems[2]));
			String operTime = locTime.format('yyyy/MM/dd HH:mm:ss:SSS');
			if (logItems[0] == 'INS') {
				// 関連情報を連続表示する
				logInfo += '商品名['+logItems[3]+']';
				if (logItems.size() > 4 && !CommUtils.isBlank(logItems[4])) logInfo += ',商品処理種別['+logItems[4]+']';
				if (logItems.size() > 5 && !CommUtils.isBlank(logItems[5])) logInfo += ',支払種別['+logItems[5]+']';
				if (logItems.size() > 6 && !CommUtils.isBlank(logItems[6])) logInfo += ',商品コード['+logItems[6]+']';
			}
			serverlog.write_log(logInfo, operTime);
		}
		serverlog.write_method_end();
	}
	@future
	// 2017/07/11 ログの機能公開する　by　zy BEGIN
	public static void writeLogToDb(String logMsg, Id accId) {
	// 2017/07/11 ログの機能公開する　by　zy END
		//カスタム設定
		CommDefine__c commDef = CommDefine__c.getInstance();
            
        Integer maxDBRecords = 1000;
        
        if(commDef != null && commDef.maxrecords_DB__c != null){
            maxDBRecords = Integer.valueOf(commDef.maxrecords_DB__c);
        }
        boolean isInsertFlag = true;
        List<CooperationResult__c>  callInformationList = [Select Id,FunctionType__c from CooperationResult__c where FunctionType__c=:CommConst.COOP_FUNTYPE_OPPLOG and ProcessingType__c = NULL order by LastmodifiedDate asc LIMIT :maxDBRecords];
        if(callInformationList.size() >= maxDBRecords) isInsertFlag = false;        
        if(isInsertFlag){
			// 新規作成を行う
			CooperationResult__c newCoop = new CooperationResult__c(
				AccountAcountRef__c = accId,
				//Status__c = COOP_STATUS_STOCKNG,
				//ProcessingType__c = SERVICE_KEY,
				FunctionType__c = CommConst.COOP_FUNTYPE_OPPLOG,
				//ErrorCount__c = 1,
				//ErrorContent__c = removeOverErrString(log.getLastError()),
				MailSendComplete__c = false,
				//ManageID__c = null,
				//ShopCode__c = shopCode,
				ProcessLog__c =  CommLogUtils.removeOverLogString(logMsg)
			);
			insert newCoop;
        }else{
        	callInformationList[0].AccountAcountRef__c = accId;
        	callInformationList[0].FunctionType__c = CommConst.COOP_FUNTYPE_OPPLOG;
        	callInformationList[0].MailSendComplete__c = false;
        	callInformationList[0].ProcessLog__c = CommLogUtils.removeOverLogString(logMsg);
        	update callInformationList[0];
        }
	
	}
	// 2016/02/25 ログ出力機能 END
	
	private void updRelLead(Id leadId) {
//System.debug(loggingLevel.INFO, 'leadId:::' + leadId);
		// 2017/04/11 現在の会計情報はPOSから取り込みのデータ場合、該当会計人數は予約へ連携する、しない処理対応 BEGIN
		// 連携なし　かつ　現在の会計情報はPOSデータの場合、予約へ人數連携処理を行わない
		if (!CommConst.POSDATAISSYNCFLG && isPostData(oAcountSobj)) return;
		// 2017/04/11 現在の会計情報はPOSから取り込みのデータ場合、該当会計人數は予約へ連携する、しない処理対応 END
		if (leadId == null) return;
		List<Lead__c> updLst = [select id, StayPersons__c from lead__c where  id = :leadId];
		if (updLst.isEmpty()) return;
		if (updLst[0].StayPersons__c != orgLeadSobj.StayPersons__c) {
			updLst[0].StayPersons__c = orgLeadSobj.StayPersons__c;
			update updLst[0];
		}
	}
	// 2017/04/11 POS会計データの会計人數は関連予約、会計の人數を連携する、しない処理対応 BEGIN
	private boolean isPostData(AccountAcount__c acc) {
		return CommLogicProcess.isPosImportData(acc);
	}
	// 2017/04/11 POS会計データの会計人數は関連予約、会計の人數を連携する、しない処理対応 END
	// ******************************
	// プラン関連の商品明細を取得する
	//   (+)ボタンクリックする場合、該当プラン関連の明細情報を取得する
	// accId:会計ID/会計商品（プラン）ID
	// ******************************
	@RemoteAction
	public static List<PlanDetail> getAccountMstLstByPlan(String tranId, String accId, String planId, String estId) {
		// 会計IDが存在する場合、既に登録された登録情報から情報を展開する
		// 会計IDが非存在場合、
		List<PlanDetail> rsLst = new List<PlanDetail>();
		if (CommUtils.isBlank(accId)) {
			if (CommUtils.isBlank(estId)) {
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			// 2021/04/31 #10658 bug fixed by zy BEGIN
			for (PlanDetail__c pd : [select AccountMasterRef__r.name,AccountMasterRef__r.ActionType__c, Price__c,TaxRate__c,AccountMasterRef__c,ServiceRate__c from PlanDetail__c where PlanProdcut__c = :planId order by id]) {
			// 2021/04/31 #10658 bug fixed by zy END
			// 2019/07/30 軽減税率機能対応 WGCH END
	                PlanDetail item = new PlanDetail();
	                item.prodName = CommUtils.nullToBlank(pd.AccountMasterRef__r.name);
	                item.prodPrice = CommUtils.nullToZero(pd.Price__c).format();
	                item.sobjId = pd.Id;
	                item.actionType = pd.AccountMasterRef__r.ActionType__c;
	                item.prodTaxRate = CommUtils.nullToZero(pd.TaxRate__c);
	                // 2019/07/30 軽減税率機能対応 WGCH BEGIN
	                item.prodid = CommUtils.nullToBlank(pd.AccountMasterRef__c);
	                // sql => ServiceRate__c 我加的
	                item.prodServiceRate = CommUtils.nullToZero(pd.ServiceRate__c);
	                // 2019/07/30 軽減税率機能対応 WGCH END
	                rsLst.add(item);
		        }
			} else {
				// 見積もり明細からプラン明細を取得する
	            // 2019/07/30 軽減税率機能対応 WGCH BEGIN
	            // 2021/04/31 #10658 bug fixed by zy BEGIN
	            for (BookingEstimateItem__c tr : [select refAccountMaster__c,refAccountMaster__r.ActionType__c, ProductName__c, UnitPrice__c,TaxRate__c,ServiceRate__c from BookingEstimateItem__c where ParentBookingItemRef__c = :estId order by id]) {
	            // 2021/04/31 #10658 bug fixed by zy END
	            // 2019/07/30 軽減税率機能対応 WGCH END
	                PlanDetail item = new PlanDetail();
	                item.prodName = CommUtils.nullToBlank(tr.ProductName__c);
	                item.prodPrice = CommUtils.deleteRightZero(CommUtils.nullToZero(tr.UnitPrice__c).format(), CommUtils.getPointLen());
	                item.sobjId = tr.Id;
	                item.actionType = tr.refAccountMaster__r.ActionType__c;
	                item.prodTaxRate = CommUtils.nullToZero(tr.TaxRate__c);
	                // 2019/07/30 軽減税率機能対応 WGCH BEGIN
	                item.prodid = CommUtils.nullToBlank(tr.refAccountMaster__c);
	                item.prodServiceRate = CommUtils.nullToZero(tr.ServiceRate__c);
	                // 2019/07/30 軽減税率機能対応 WGCH END
	                rsLst.add(item);
	            }
			}
		} else {
            // 2019/07/30 軽減税率機能対応 WGCH BEGIN
            // 2021/04/31 #10658 bug fixed by zy BEGIN
            for (Tran1__c tr : [select Field5__c, Field20__c,TaxRate__c,ActionType__c,Field7__c,ServiceRate__c from Tran1__c where ParentTran1Ref__c = :tranId And Field1__c = :accId order by id]) {
            // 2021/04/31 #10658 bug fixed by zy END
            // 2019/07/30 軽減税率機能対応 WGCH END
                PlanDetail item = new PlanDetail();
                item.prodName = CommUtils.nullToBlank(tr.Field5__c);
                item.prodPrice = CommUtils.nullToZero(tr.Field20__c).format();
                item.sobjId = tr.Id;
                item.actionType = tr.ActionType__c;
                item.prodTaxRate = CommUtils.nullToZero(tr.TaxRate__c);
                // 2019/07/30 軽減税率機能対応 WGCH BEGIN
                item.prodid = CommUtils.nullToBlank(tr.Field7__c);
                item.prodServiceRate = CommUtils.nullToZero(tr.ServiceRate__c);
                // 2019/07/30 軽減税率機能対応 WGCH END
                rsLst.add(item);
            }
            // 2015/10/20 会計明細のプラン明細が未設定する場合、プラン設定情報から取得する BEGIN
            if (rsLst.isEmpty()) {
		        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
		        // 2021/04/31 #10658 bug fixed by zy BEGIN
		        for (PlanDetail__c pd : [select AccountMasterRef__r.name, AccountMasterRef__r.ActionType__c,Price__c,TaxRate__c,AccountMasterRef__c,ServiceRate__c from PlanDetail__c where PlanProdcut__c = :planId order by id]) {
		        // 2021/04/31 #10658 bug fixed by zy END
		        // 2019/07/30 軽減税率機能対応 WGCH END
	                PlanDetail item = new PlanDetail();
	                item.prodName = CommUtils.nullToBlank(pd.AccountMasterRef__r.name);
	                item.prodPrice = CommUtils.nullToZero(pd.Price__c).format();
	                item.sobjId = pd.Id;
	                item.actionType = pd.AccountMasterRef__r.ActionType__c;
	                item.prodTaxRate = CommUtils.nullToZero(pd.TaxRate__c);
	                // 2019/07/30 軽減税率機能対応 WGCH BEGIN
	                item.prodid = CommUtils.nullToBlank(pd.AccountMasterRef__c);
	                item.prodServiceRate = CommUtils.nullToZero(pd.ServiceRate__c);
	                // 2019/07/30 軽減税率機能対応 WGCH END
	                rsLst.add(item);
		        }
            }
            // 2015/10/20 会計明細のプラン明細が未設定する場合、プラン設定情報から取得する END
		}
		return rsLst;
	}
	// プラン明細情報を維持する
	public class PlanDetail {
		public String prodName{get; set;}
		public String prodPrice{get; set;}
		public String sobjId{get;set;}
		public String actionType{get;set;}
		// 2015/10/05プラン明細課税、非課税混雑対応するため、消費税情報を取得、格納する
		public Decimal prodTaxRate{get;set;}
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		public String prodid{get;set;}
		public Decimal prodServiceRate{get;set;}
		// 2019/07/30 軽減税率機能対応 WGCH END
	}
	
	/************************************
	* 会計商品情報を取得
	* 会計商品コード・商品名で商品明細情報を取得用
	*************************************/
	@remoteAction
	public static List<ProductItemUtils.ProductItem> getArrayProductItemInfo(String prodCode) {
		return ProductItemUtils.getArrayProdcutItemByCode(prodCode);
	}
	
	// 2019/12/30 会計機能、会計画面でプランの内訳を編集出来るように WGCH BEGIN
	public Boolean isPlanEditFlg{get{ return CommConst.ACC_PLAN_EDIT_FLG;} set;}
	@remoteAction
	global static List<ProductItemUtils.ProductItem> getArrayProductItemInfoNoPlan(String prodCode) {
		return ProductItemUtils.getArrayProdcutItemByCode(prodCode, true);
	}
	// 2019/12/30 会計機能、会計画面でプランの内訳を編集出来るように WGCH END
	/************************************
	* 集計対象になるため、デフォルト設定設定を行う
	* 会計情報を登録する前に、関連項目情報を自動設定
	* 更新対象会計 : pAcountSobj
	* 金額項目のみ更新：onlyCalMoneyFlg true金額のみ
	* バッチから自動作成する回避するため、１部屋のN泊の会計データは一括更新日時を設定する
	*************************************/
	private List<AccountAcount__c> preUpdateAccountInf(List<AccountAcount__c> pAcountSobjLst) {
		 // 2017/09/06 会計メッセージ項目自定義機能追加 by zy BEGIN
		// お客様フィルター更新
		preUpdateContact();
		// 2017/09/06 会計メッセージ項目自定義機能追加 by zy END
	// 2015/07/16 お客様情報の自動設定機能
	Map<Id, Id> relLeadIdsMap = new Map<Id, Id>();
	for (AccountAcount__c acc : pAcountSobjLst) {
		if (acc.relaccount__c == null || acc.Relreserve__c != null) {
			// 予約情報が存在、お客様名を未設定の場合、自動設定を行う
			relLeadIdsMap.put(acc.Id, acc.Relreserve__c);
		}
	}
	if (!relLeadIdsMap.isEmpty()) {
		Map<Id, Id> relContactIdMap = new Map<Id, Id>();
		List<Lead__c> leads = [select Id, Name, Relcontact__c from Lead__c where id = :relLeadIdsMap.values()];
		for (Lead__c lead: leads) {
			relContactIdMap.put(lead.Id, lead.Relcontact__c);
		}
		// お客様IDを自動設定を行う
		for (AccountAcount__c acc : pAcountSobjLst) {
			if (relLeadIdsMap.containsKey(acc.Id)) {
				acc.relaccount__c = relContactIdMap.get(acc.Relreserve__c);
			}
		}
	}
	// 2017/04/11 現在の会計情報はPOSから取り込みのデータ場合、該当会計人數は予約へ連携する、しない処理対応 BEGIN
	oAcountSobj.Field57__c = CommUtils.nullToBlank(orgLeadSobj.StayPersons__c);
	// 2017/04/11 現在の会計情報はPOSから取り込みのデータ場合、該当会計人數は予約へ連携する、しない処理対応 END
	// 2018/03/12 連泊コメント同期機能対応 WGCH BEGIN
	if(isAccountSyncCommentFlg){
		for (AccountAcount__c pAcountSobj : pAcountSobjLst) {
			// comment__c进行最新的赋值
			setNewCommentInfo(pAcountSobj);
		}
	}
	// 2018/03/12 連泊コメント同期機能対応 WGCH END
	for (AccountAcount__c pAcountSobj : pAcountSobjLst) {
		// 2014/02/25 並べ替え項目設定情報は非保存に変更する BEGIN
		pAcountSobj.DetailSortBy__c = null;
		// END
if (pAcountSobj.Id == oAcountSobj.Id) {
		// 売上計上日設定存在チェックを行う
		if (pAcountSobj.frs__c == null || pAcountSobj.frs__r.Salesday__c != pAcountSobj.SalesDate__c) {
			// 指定日の売上計上日関連の売上のIDを取得、設定を行う
			pAcountSobj.frs__c = CommLogicProcess.getRsvAccountInf(pAcountSobj.SalesDate__c).Id;
		}
		// 2016/06/28 利用日設定機能追加 BEGIN
		if (oPage.isReceipt) {
			if (ReceiptDate.workDay__c == null) {
				// 元存在の場合、クリアする
				if (pAcountSobj.ReceiptDt__c != null) {
					pAcountSobj.ReceiptDt__c = null;
					pAcountSobj.PaymentFlg__c = false;
				}
			}
			else {
				// 元の入金日が未設定 OR 日付が違うの場合
				if (oAcountSobj.ReceiptDt__c == null || oAcountSobj.ReceiptDt__c.date() != ReceiptDate.workDay__c) {
					Time dt = System.now().time();
					oAcountSobj.ReceiptDt__c = DateTime.newInstance(ReceiptDate.workDay__c, dt);
					pAcountSobj.PaymentFlg__c = true;
				}
			}
		}
		// 2016/06/28 利用日設定機能追加 END
}
// 2015/05/02 下記共通設定情報は更新する場合、設定行わない
// 例、一回VOID処理される会計データに対して、会計情報を再保存すると、正常に戻すの対応
if (oPage.dataStatus != PAGE_STATUS.UPD) {
		// 取引種別:00 売上(通常)
		pAcountSobj.Field39__c = CommConst.ACC_TRADE_NORMAL;
		// ＶＯＩＤレシートＮｏ．
		pAcountSobj.Field40__c = '';
}
		// 売上計3（内税抜き）金額
		//pAcountSobj.Field114__c ->会計明細から自動設定を行う
		// POSNo.
		// 2017/04/11 POSNOは未存在の場合、初期値設定を行う BEGIN
		//pAcountSobj.POSNo__c = CommUtils.getPosNoByComdefine();
		if (CommUtils.isBlank(pAcountSobj.POSNo__c)) pAcountSobj.POSNo__c = CommUtils.getPosNoByComdefine();
		// 2017/04/11 POSNOは未存在の場合、初期値設定を行う END
		// TODO：営業日付 ←　チェックイン日付で設定を行う　
		pAcountSobj.Field141__c = CommUtils.getBusinessDay();
		// 会計日時: TODO->原システム確認要
		pAcountSobj.Field53__c = DateTime.valueOf(String.valueOf(System.now())).format('yyyyMMddHHmmss');
		// 2016/01/12 領収書日付デフォルト値設定制御変更 BEGIN
		// 2019/11/30 会計の領収証日付値の自動設定制御モード機能対応 WGCH BEGIN
		/*
		if (oAcountSobj.AccountReceiptDate__c == null ) {
			if (accountReceiptDateDefValSetFlg) {
				oAcountSobj.AccountReceiptDate__c = Date.today();
			} else {
				oAcountSobj.AccountReceiptDate__c = oAcountSobj.SalesDate__c;
			}
		}
		*/
		if (oAcountSobj.AccountReceiptDate__c == null ) {
			// 到着日の日付で設定する
			if(accountReceiptDateDefValSetMode == CommConst.ACCOUNT_RECEIPTDATE_2){
				if(oAcountSobj.Relreserve__c != null && oAcountSobj.Relreserve__r.EntryTime__c != null){
					oAcountSobj.AccountReceiptDate__c = oAcountSobj.Relreserve__r.EntryTime__c.date();
				}
			}
			// 出発日の日付で設定する
			else if(accountReceiptDateDefValSetMode == CommConst.ACCOUNT_RECEIPTDATE_3){
				if(oAcountSobj.Relreserve__c != null && oAcountSobj.Relreserve__r.Departure__c != null){
					oAcountSobj.AccountReceiptDate__c = oAcountSobj.Relreserve__r.Departure__c.date();
				}
			} else if (accountReceiptDateDefValSetMode == CommConst.ACCOUNT_RECEIPTDATE_1) {
				oAcountSobj.AccountReceiptDate__c = oAcountSobj.SalesDate__c;
			} else {
				oAcountSobj.AccountReceiptDate__c = Date.today();
			}
		}
		// 2019/11/30 会計の領収証日付値の自動設定制御モード機能対応 WGCH END
		// 2016/01/12 領収書日付デフォルト値設定制御変更 END
		// 会計人数
		/* 2015/04/08 予約人數から同期設定するため、個別設定を行わない BEGIN
		pAcountSobj.Field57__c = String.valueOf(
									CommUtils.nullToZero(pAcountSobj.Field66__c) +
									CommUtils.nullToZero(pAcountSobj.Field67__c) +
									CommUtils.nullToZero(pAcountSobj.Field68__c));
		*/
		// 予約情報が設定なかった場合、
		//2016/12/27 会計人數自動設定機能封印 BEGIN by zh
		if (pAcountSobj.Relreserve__c == null || AccounntStayPersonsAutoSetupFlg == false) {
			// 2017/04/11 現在の会計情報はPOSから取り込みのデータ場合、該当会計人數は予約へ連携する、しない処理対応 BEGIN
			// 該当会計データはポストデータ　かつ　人數連携しない場合、人數設定を行わない
			boolean syncFlg = true;
			if (!CommConst.POSDATAISSYNCFLG) {
				if (isPostData(oAcountSobj) || isPostData(pAcountSobj)) {
					syncFlg = false;
				}
			}
			if (syncFlg) 
			pAcountSobj.Field57__c =CommUtils.nullToBlank(orgLeadSobj.StayPersons__c);
			// 2017/04/11 現在の会計情報はPOSから取り込みのデータ場合、該当会計人數は予約へ連携する、しない処理対応 END
		}
		//2016/12/27 会計人數自動設定機能封印 END by zh
		/* 2015/04/08 予約人數から同期設定するため、個別設定を行わない END */
		/*
		// 請求額 = 売上計4（内税込み）金額　ー　割引額　ー　予約金 - クーポン
		pAcountSobj.Field126__c = String.valueOf(
									CommUtils.nullToZero(oTttendFooter.amoutSalesPrice)
									- CommUtils.nullToZero(oTttendFooter.amoutDiscountPrice)
									- CommUtils.nullToZero(oTttendFooter.amoutSubscriptionPrice) 
									- CommUtils.nullToZero(oTttendFooter.amoutCouponPayPrice) 
									- CommUtils.nullToZero(oTranFooter.amoutAdvancesReceived)
									);
		*/
		// 2015/01/01新会計レイアウトで新規・更新された会計情報
		pAcountSobj.IsNewLayout__c = true;
		//return pAcountSobj;
		// 2015/05/14 クーポン利用の返金フラグは一緒に更新設定を行う
		pAcountSobj.CouponReturnFlg__c = oAcountSobj.CouponReturnFlg__c;
		// 2018/03/12 連泊コメント同期機能対応 WGCH BEGIN
		if(isAccountSyncCommentFlg && !accCommentMap.isEmpty()){
			pAcountSobj.comment__c =  accCommentMap.values()[0];
		}
		// 2020/02/21 社内コメント項目を新規追加(共通定義により、切り替え制限可能) BEGIN
		if(isShowInCommentFlg && !accInCommentMap.isEmpty()){
			pAcountSobj.comment2__c =  accInCommentMap.values()[0];
		}
		// 2020/02/21 社内コメント項目を新規追加(共通定義により、切り替え制限可能) END
		// 2018/03/12 連泊コメント同期機能対応 WGCH END
		} // End For
		return pAcountSobjLst;
	}
	// ********************
	// 支払情報保存前の事前処理
	// ********************
	private List<TTend__c> preUpdateTtendInfo (List<TTend__c> pTtendList) {
		// 集計対象条件
		// Field35__c = "00" && Field4__c = "1" && Field5__c ="1" && Field1__r.Field40__c ="" && Field29__c <> 0
		// 処理　種別１:Field4__c ->1
		// 処理　種別２:Field5__c ->1
		// 営業日付
		//String strBusinessDay = CommUtils.getBusinessDay();
		for (TTend__c sobj: pTtendList) {
			sobj.Field4__c = '1';
			sobj.Field5__c = '1';
			// 2017/04/11 POSNOは未存在の場合、初期値設定を行う BEGIN
			//sobj.POSNo__c = CommUtils.getPosNoByComdefine();
			if (CommUtils.isBlank(sobj.POSNo__c)) sobj.POSNo__c = CommUtils.getPosNoByComdefine();
			// 2017/04/11 POSNOは未存在の場合、初期値設定を行う END
			if (!CommUtils.isBlank(sobj.Field2__c)) sobj.Field3__c = CommConst.getPaymentTypeLabelByKey(sobj.Field2__c);
			// 2016/06/28 利用日設定機能追加 BEGIN
			if (oPage.isReceipt && oAcountSobj.Id == sobj.Field1__c) {
				sobj.ReceiptDt__c = oAcountSobj.ReceiptDt__c;
			}
			// 2016/06/28 利用日設定機能追加 END
		}
		return pTtendList;
	}
	// ********************
	// 会計明細情報保存前の事前処理
	// ********************
	private List<Tran1__c> preUpdateTran1Info (List<Tran1__c> pTranList) {
		// if ( Field44__c = "00" && (Field39__c <> 0 || CONTAINS( Field5__c , "●") ) && ( Field2__c ="M" || Field2__c ="P" || Field2__c ="R") && Field3__c = "1" && Field4__c ="1" && Field22__c <> "+000" && VoidReceiptNo__c ="0" && noneaccount__c = false , 1, 0)
		// 商品種別:Field2__c
		// 処理種別１:Field3__c
		// 処理種別２:Field4__c
		// 残数量:Field22__c
		// TODO: 営業日付
		// 会計商品から商品種別を取得を行う
		// 2014.12.28 トリガーに自動せっていするため
		/*
		Set<Id> prodcutIdSet = new Set<Id>();
		for (Tran1__c sobj: pTranList) {
			prodcutIdSet.add(sobj.Field7__c);
		}
		Map<Id, AccountMaster__c> productMap = new Map<Id, AccountMaster__c>([select SCP_5__c from AccountMaster__c where id in :prodcutIdSet]);
		*/
//		String strBusinessDay = CommUtils.getBusinessDay();
		for (Tran1__c sobj: pTranList) {
			/*
			// 商品種別 ->SCP(5) = '0'    M   ; SCP(5) != '0'   P
			if (productMap.containsKey(sobj.Field7__c)) {
				// TODO 現状のシステムを一回確認必要
				String scpCode = productMap.get(sobj.Field7__c).SCP_5__c;
                sobj.Field2__c = (scpCode == '0') ? 'M' : 'P';
			}*/
			// 処理種別１
			sobj.Field3__c = '1';
			// 処理種別２
			sobj.Field4__c = '1';
			// 残数量
			sobj.Field22__c = sobj.Field21__c;
			// 営業日付
//			sobj.Field45__c = strBusinessDay;
			// POSNo.
			// 2017/04/11 POSNOは未存在の場合、初期値設定を行う BEGIN
			//sobj.POSNo__c = CommUtils.getPosNoByComdefine();
			if (CommUtils.isBlank(sobj.POSNo__c)) CommUtils.getPosNoByComdefine();
			// 2017/04/11 POSNOは未存在の場合、初期値設定を行う END
			// 消費税　種別(消費税＝０の場合、非課税/)
			sobj.Field27__c = (sobj.TaxRate__c == 0 ? '2' : '1');
		}
		return pTranList;
	}
	
	/** 新規、更新処理する場合、関聯チエックを追加する */
	private boolean preSaveCheck() {
//System.debug(loggingLevel.INFO, 'oAcountSobj.Relreserve__r.StayPersons__c:::' + oAcountSobj.Relreserve__r.StayPersons__c);
		// 2015/06/17 BEGIN 予約人數は０の場合、会計可能に変更する
		/*
		if (CommUtils.nullToZero(orgLeadSobj.StayPersons__c) <= 0) {
			Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '予約人數はは1以上の値を入力してください。'));
			return false;
		}*/
		// 2015/06/17 END
		return true;
	}
	// 2016/09/19 2016/09/19 売掛のご請求先存在チェックを追加する
	// 2016/10/10 売掛のご請求先存在チェックを外す BEGIN
	/*
	private void relCheck() {
		for (TranItem obj: oTranSobjLst) {
			// 無効な会計明細の場合、処理SKIP
			if (!obj.isValidata) continue;
			// 見積もり明細の場合、処理SKIP
			if (obj.isEstItemFlg) continue;
			// 会計支払で会計明細のデータで表示の場合
			if (obj.isPayProduct()) {
				// 会計明細の入力情報から会計支払情報に変換を行う
				TTend__c ttend = convertTranToTend(obj);
				if(ttend.Field2__c == CommConst.MEDIA_TYPE_CD_03 && CommUtils.isBlank(oAcountSobj.relaccount__r.AccountId)){
					Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, '売掛のご請求先を設定してください.'));
					break;
				}
			}
		}
	}*/
	// 2016/10/10 売掛のご請求先存在チェックを外す END
	/**
	* 会計情報保存処理を行う
	**/
	public Pagereference upsertData() {
		
// 2016/02/19 ログ出力機能を追加する BEGIN	
serverlog.clear();
parseClineLog(clientLog);
serverlog.write_method_start('更新');
// 2016/02/19 ログ出力機能を追加する END
		// 事前チェック
		if (!preSaveCheck()) return null;
		// 関連の会計情報を一回更新を行う
		Savepoint sp = Database.setSavepoint();
		// 2018/06/13 error修复（JINYABUG-628）zy by BEGIN
		// 会計日時: TODO->原システム確認要
		String orgField53 = oAcountSobj.Field53__c;
		// 2018/06/13 error修复（JINYABUG-628）zy by END
		try {
			if (!CommUtils.isBlank(itemJson)) {
				oTranSobjLst = (List<TranItem>)JSON.deserialize(itemJson, List<TranItem>.class);
			}
			// 2021/04/31 #10743 bug fixed by zy BEGIN
			isErrorFlg = false;
			// 2021/04/31 #10743 bug fixed by zy END
			// 2019/09/15 Security Check BY zyz BEGIN
			if (!CommSecurityUtils.isDeleteable(TTend__c.getSObjectType())) {
				return null;
			}
			if (!CommSecurityUtils.isDeleteable(Tran1__c.getSObjectType())) {
				return null;
			}
			// 2019/09/15 Security Check BY zyz END
			// 利用日により、関連会計、売上情報を再自動処理を行う
			this.syncSalesDateInfo();
			// 最新入力情報にて、最新合計情報を再計算を行う
			if (!this.amoutTran1Info()) {
	            return null;
			}

			// 会計情報更新処理を行う
			upsert preUpdateAccountInf(pRelAccountsMap.values());
			// 2016/02/19 ログ出力機能を追加する BEGIN
			serverlog.write_log('*****サーバー側の処理履歴*****');
			// 2017/07/10 IPログ追加する　by　zy BEGIN
			serverlog.write_log('設備IP:::::' + localIp);
			// 2017/07/10 IPログ追加する　by　zy END
			serverlog.write_log('利用日モード：'+ CommDefine__c.getOrgDefaults().AccountUseDateMode__c);
			serverlog.write_log('*****新規/更新会計件数['+pRelAccountsMap.values().size()+']*****');
			for (AccountAcount__c acc : pRelAccountsMap.values()) {
				serverlog.write_log('会計：' + acc);
			}
			// 2016/02/19 ログ出力機能を追加する END
			// 会計支払情報・削除、更新処理
			List<TTend__c> updTtendList = new List<TTend__c>();
			List<TTend__c> delTtendList = new List<TTend__c>();
			
			// 会計明細情報・削除、更新処理
			List<Tran1__c> updTranList = new List<Tran1__c>();
			List<Tran1__c> delTranList = new List<Tran1__c>();
			
			// 見積もり明細更新配列
			List<BookingEstimateItem__c> updBookEstList = new List<BookingEstimateItem__c>();
			
			// 画面設定の明細情報から会計明細、会計支払情報処理を行う
			for (TranItem obj: oTranSobjLst) {
				// 2021/02/28 CPU LIMITの最適化 WGCH BEGIN
				if(limitFlg && obj.isNoUpdate) continue;
				// 2021/02/28 CPU LIMITの最適化 WGCH END
				// 商品登録と、有効なデータで登録する
				if (!obj.checkValidata()) {
					// 既存の会計明細情報に対して、無効に設定する場合、削除対象になる
	                if (obj.sobj.Id != null) {
	                	delTranList.add(obj.sobj);
	                }
	                /*
	                // 指定の情報は既に登録された会計支払情報の場合、会計支払情報明細も削除対象
	                else if (obj.sobj.Id == null && !CommUtils.IsBlank(obj.tranId)) {
//System.debug(LoggingLevel.INFO, ':::[A]:::' + obj);
	                	delTtendList.add(new TTend__c( Id = obj.tranId));
	                }*/
	                continue;
				} 
				// 2015/05/06 既存の会計明細から会計支払に設定されている場合、該当既存の会計明細は削除する BEGIN
				else if (obj.sobj.Id != null && CommUtils.IsBlank(obj.tranId) && obj.isPayProduct()) {
//System.debug(LoggingLevel.INFO, ':::[A]:::' + obj);
					delTranList.add(obj.sobj);
					continue;
				}
				// 会計明細に支払情報を登録されると、該当会計明細を削除する
				else if  (obj.sobj.Id != null && !CommUtils.IsBlank(obj.tranId) && obj.isPayProduct()) {
					delTranList.add(obj.sobj);
					continue;
				}
				// 2015/05/06 既存の会計明細から会計支払に設定されている場合、該当既存の会計明細は削除する END
				else if (obj.isEstItemFlg) {
					// 見積もり明細更新を行う
					updBookEstList.add(convertTranToEst(obj));
					continue;
				}
				// 2015/10/30 既存プラン　かつ　新明細のTranIdはNULLの場合、既存のプランの明細はクリアが必要
				// 2015/10/25 該当明細の商品はプラン　かつ　参照している商品は同じ　かつ　クリアされている場合、既存のプランの情報を削除する
				else if (obj.isPlanProduct() &&
					CommUtils.isBlank(obj.tranId) &&
					obj.sobj.Id != null) {
					// 既存のプランとプラン明細情報を削除して、新子見積もり明細を新規作成を行う
					Tran1__c planItemClone = obj.sobj.clone(false, true);
					delTranList.add(obj.sobj);
					updTranList.add(planItemClone);
					continue;
				}
//System.debug(LoggingLevel.INFO, 'ORDER SORT::ROW_NO' + obj);
			}
			// -----------------------------------
			// 各会計の会計支払と会計明細情報処理を行う
			// -----------------------------------
			for (Id accId : pRelAccountIdList) {
				
				// 会計単位の情報の処理を行う
				AccountAcount__c curAccount = pRelAccountsMap.get(accId);
				// 該当会計に登録した会計明細情報
				if (pTranSobjLstMap.containsKey(accId)) {
					// 該当会計に所属する明細情報を取得する
					List<TranItem> tranItems = pTranSobjLstMap.get(accId);
					for (TranItem tran : tranItems) {
						// 2021/02/28 CPU LIMITの最適化 WGCH BEGIN
						if(limitFlg && tran.isNoUpdate) continue;
						// 2021/02/28 CPU LIMITの最適化 WGCH END
//System.debug(LoggingLevel.INFO, 'TranItem[LOOP]:::' + tran);
						// 該当会計の売上参照IDの再設定を行う
						tran.sobj.RelAccount__c = curAccount.frs__c;
						// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz BEGIN
						if(tran.sobj.UseDate__c == null) tran.sobj.UseDate__c =  tran.tranUseDate;
						// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz END
						updTranList.add(tran.sobj);
					}
				}
				/*
				// 該当会計に登録した会計支払情報
				if (pTTendSobjLstMap.containsKey(accId)) {
					List<TTendItem> ttendItems = pTTendSobjLstMap.get(accId);
					for (TTendItem ttend : ttendItems) {
//System.debug(LoggingLevel.INFO, 'TTendItem[LOOP]:::' + ttend);
						// 該当会計に所属する会計支払情報の売上参照IDの再設定を行う
						ttend.sobj.RelAccount__c = curAccount.frs__c;
						updTtendList.add(ttend.sobj);
					}
				}*/
			}
			if (!updTranList.isEmpty()) upsert preUpdateTran1Info(updTranList);
			if (!delTranList.isEmpty()) delete delTranList;
//System.debug(LoggingLevel.INFO, 'delTtendList[1]:::' + delTtendList);
		// -----------------------------------
			// 各会計の会計支払と会計明細情報処理を行う
			// -----------------------------------
			for (Id accId : pRelAccountIdList) {
				
				// 会計単位の情報の処理を行う
				AccountAcount__c curAccount = pRelAccountsMap.get(accId);
				// 該当会計に登録した会計支払情報
				if (pTTendSobjLstMap.containsKey(accId)) {
					List<TTendItem> ttendItems = pTTendSobjLstMap.get(accId);
					Map<Integer, Tran1__c> locRelArTranMap = pArTranInsertIdMap.containsKey(accId) ? pArTranInsertIdMap.get(accId) : new Map<Integer, Tran1__c>();
					Integer idx = 1;
					for (TTendItem ttend : ttendItems) {
//System.debug(LoggingLevel.INFO, 'TTendItem[LOOP]:::' + ttend);
						// 該当会計に所属する会計支払情報の売上参照IDの再設定を行う
						ttend.sobj.RelAccount__c = curAccount.frs__c;
						// 該当会計支払情報は前受金で作成する場合、関連の参照IDを自動設定を行う
						if (locRelArTranMap.containsKey(idx)) ttend.sobj.ArTranId__c = locRelArTranMap.get(idx).Id;
						// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz BEGIN
						if(ttend.sobj.UseDate__c == null) ttend.sobj.UseDate__c =  ttend.ttendUseDate;
						// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz END

						updTtendList.add(ttend.sobj);
						idx++;
					}
				}
			}
			
			// 既存の支払情報を削除する
			//if (!pExistTtendItemMap.isEmpty()) delTtendList.addAll(pExistTtendItemMap.values());
			for (Ttend__c ttend : pExistTtendItemMap.values()) {
				if (noDeleteIdSet.contains(ttend.Id)) continue;
				delTtendList.add(ttend);
			}
//System.debug(LoggingLevel.INFO, 'delTtendList[2]:::' + delTtendList);
			/* 既存の前受け金で作成した会計支払情報*/
			if (!pArPaymentInfoMap.isEmpty()) {
				for (List<TTend__c> ttends : pArPaymentInfoMap.values()) {
					//for (Id tranId : ttends.keySet()) {
					for (TTend__c varTtend : ttends) {
						//if (tranId != null && noDeleteIdSet.contains(tranId)) continue;
						if (varTtend.ArTranId__c != null && noDeleteIdSet.contains(varTtend.ArTranId__c)) continue;
						//delTtendList.addAll(ttends.values());
						delTtendList.add(varTtend);
					}
				}
			}
//System.debug(LoggingLevel.INFO, 'delTtendList[3]:::' + delTtendList);
			/* バッチで自動作成した支払情報 */
			if (!pBatchPaymentInfoMap.isEmpty()) {
				for (List<TTend__c> ttends : pBatchPaymentInfoMap.values()) {
//System.debug(LoggingLevel.INFO, 'BATCH[A]:::' + ttends);
					delTtendList.addAll(ttends);
				}
			}	
//System.debug(LoggingLevel.INFO, 'delTtendList[4]:::' + delTtendList);		
//System.debug(LoggingLevel.INFO, 'delTtendList:::' + delTtendList);
//System.debug(LoggingLevel.INFO, 'updTtendList[1]:::' + updTtendList);
//System.debug(LoggingLevel.INFO, 'updTtendList[2]:::' + preUpdateTtendInfo(updTtendList));

			// 新規の会計支払情報登録を行う
			if (!updTtendList.isEmpty()) upsert preUpdateTtendInfo(updTtendList);
			//if (!delTtendList.isEmpty()) delete delTtendList;
			if (!delTtendList.isEmpty()) {
				Set<Id> delTtendIds = new Set<Id>();
				for (TTend__c tend : delTtendList) {
					delTtendIds.add(tend.Id);
				}
				delete [select id from TTend__c where id in :delTtendIds];
			}
			// 見積明細更新を行う
			if (!updBookEstList.isEmpty()) update updBookEstList;

// 2016/02/19 ログ出力機能を追加する BEGIN
serverlog.write_log('*****新規/更新会計支払件数['+updTtendList.size()+']*****');
for (TTend__c ttend : updTtendList) {
	serverlog.write_log('会計支払：['+ttend.RowNo__c+']行目:' + ttend);
}
serverlog.write_log('*****削除会計支払件数['+delTtendList.size()+']*****');
for (TTend__c ttend : delTtendList) {
	serverlog.write_log('会計支払：['+ttend.RowNo__c+']行目:' + ttend);
}
serverlog.write_log('*****新規/更新会計明細件数['+updTranList.size()+']*****');
for (Tran1__c tran : updTranList) {
	serverlog.write_log('会計明細：['+tran.RowNo__c+']行目:' + tran);
}
serverlog.write_log('*****削除会計明細件数['+delTranList.size()+']*****');
for (Tran1__c tran : delTranList) {
	serverlog.write_log('会計明細：['+tran.RowNo__c+']行目:' + tran);
}
// 2016/02/19 ログ出力機能を追加する END

			// 関聯予約の人數を変更されると、予約情報更新を行う
	    	updRelLead(oAcountSobj.Relreserve__c);
			// 会計詳細画面へ移動する
	        //Pagereference pg = new Pagereference('/' + oAcountSobj.id);
	        //pg.setRedirect(true);
			//return pg;
			// 最新インサート情報を取得する
	    	refreshAccoutAcountInfo(oAcountSobj.id);
	        // 関連情報を設定を行う
	        refreshTTendInfo(pRelAccountIdList);					// 会計支払情報初期化
	        refreshTran1Info(pRelAccountIdList, pExistTtendMap);	// 会計明細情報初期化
// 2016/02/19 ログ出力機能を追加する BEGIN
//			return null;
// 2016/02/19 ログ出力機能を追加する END
		} catch (Exception e) {
			DataBase.rollback(sp);
			String msg = e.getMessage();
			// 2017/05/04 自施設の予約や会計しか変更できないように権限管理機能 BEGIN
			//ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CommUtils.getFieldValidationMessage(msg)));
			if(!CommUtils.isFieldValidationMessage(msg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, msg));
			else {
				Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, msg));
			}
			// 2021/04/31 #10743 bug fixed by zy BEGIN
			isErrorFlg = true;
			// 2021/04/31 #10743 bug fixed by zy END
			// 2017/05/04 自施設の予約や会計しか変更できないように権限管理機能 END
// 2016/02/19 ログ出力機能を追加する BEGIN
//			return null;
// 2016/02/19 ログ出力機能を追加する END
			// 2018/06/13 error修复（JINYABUG-628）zy by BEGIN
			// 会計日時: TODO->原システム確認要
			oAcountSobj.Field53__c = orgField53;
			// 2018/06/13 error修复（JINYABUG-628）zy by END
		}
// 2016/02/19 ログ出力機能を追加する BEGIN
serverlog.write_method_end();
// 2018/12/15 請求書の作成など自動繰返し機能 by zy BEGIN
	// バッチ処理の場合：Future method cannot be called
	if (!batchExcuteFlag)
writeLogToDb(serverlog.getAllLog(), oAcountSobj.Id);
// 2018/12/15 請求書の作成など自動繰返し機能 by zy END
		return null;
// 2016/02/19 ログ出力機能を追加する END
	}

	/**********************
	* 事前会計処理
	* 指定予約の関連予約（同じ予約インデックス、同じ予約SUBINDEX,同じグループNOを一括チェックインする
	* その後、自動会計編集画面に遷移する
	***********************/
	webservice static String[] preAutoCheckin(String leadId) {
	//webservice static String preAutoCheckin(String leadId) {
		
		String[] result = new String[]{'',''};

		List<Lead__c> leads = [select LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c 
								from Lead__c where id = :leadId And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG ];
		if (leads.IsEmpty()) {
			//該当予約データが既に削除まはたキャンセルされたので、事前会計処理ができません。
			result[0]= Label.MSG_006_0438;
			return result;
		}
		
		// 該当予約関連の同じ部屋N泊検索用条件
		String leadIdx = leads[0].LeadIndexRef__c;
		String leadSubIdx = leads[0].LeadIndexSubId__c;
		Decimal leadGroupNo = leads[0].RoomGroupNo__c;
		// 関連の予約を取得する
		List<Lead__c> relLeads = [select Field298__c, CancelBool__c from Lead__c 
								 where LeadIndexRef__c = :leadIdx And LeadIndexSubId__c = :leadSubIdx And RoomGroupNo__c = :leadGroupNo
								 And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG];
		// 一括チェックイン
		Savepoint sp = Database.setSavepoint();
		try {
			List<Lead__c> updList = new List<Lead__c>();
			for (Lead__c lead : relLeads) {
				// 顧客データステータスはチェッキン完了またはチェックアウト場合、対象外？
				if (lead.Field298__c == CommConst.LEAD_GUEST_ST_CI ||
					lead.Field298__c == CommConst.LEAD_GUEST_ST_CO) continue;
				// チェックイン処理を行う
				lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
				updList.add(lead);
			}
			// 自動チェックイン更新を行う
			if (!updList.isEmpty()) update updList;
			// 指定の予約の関連会計のIDを取得する
			List<AccountAcount__c> newAccLst = [select id from AccountAcount__c where Relreserve__c = :leadId Order By LastModifiedDate desc limit 1];
			result[1] = newAccLst[0].Id;
			return result;
		} catch (Exception e) {
			Database.rollback(sp);
			result[0]= e.getMessage();	
			return result;
		}
	}
	

	/*************************
	* 会計商品の支払種別から支払メデイア対応表XML分析処理
	**************************/
	private void setPaymentToPayMeidaXml() {
		// 格納用変数クリアする
		BillSimpleHelp help = new BillSimpleHelp(oShopCode);
		PAYMENT_MATCH_MAP = help.getPaymentTypeToMediaLabMap();
		MEDIA_PRODUCTCD_MAP = help.getMediaLabToAccMstMap();
		// 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH BEGIN
		limitFlg = help.limitFlg;
		autoSaveMessage = help.autoSaveMessage;
		autoSaveLimit = help.autoSaveLimit;
		maxRows = help.maxRows;
		maxRowsMsg = Label.MSG_006_0461.replace('XXXXXX', CommUtils.nullToBlank(maxRows));
		accXmlWhereStr = help.accXmlWhereStr;
		accSkipTabShow = help.accSkipTabShow;
		autoPrintFlg = help.autoPrintFlg;
		// 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH END
		// 支払メニューのレイアウト設定情報を取得する
		BillSimplePaymentCtrl payInfo = new BillSimplePaymentCtrl();
		payLayoutInfo = payInfo.getLayoutTagInfo(oShopCode);
		payBtnInfoMap = payInfo.buttonsIconMap.clone();
	}

	/**
	* VOID
	**//* 2017/04/12 不要な処理Methodを削除 WSQ BEGIN
	public void voidProcess () {
		
        // 最新情報取得、設定を行う
        refreshAccoutAcountInfo(oAcountSobj.Id);
        
		// 既にVOIDの場合、再VOIDできませんチェックを行う
		if (oAcountSobj.Field39__c == CommConst.ACC_TRADE_VOID) {
			//既にVOID処理済みため、再VOID処理することができません。
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
		      Label.MSG_006_0318));

            return;
		}
		// VOID機能実施を行う
        // 取引種別:30 ＶＯＩＤ
        oAcountSobj.Field39__c = CommConst.ACC_TRADE_VOID;
        try {
        	update oAcountSobj;
        } catch (Exception e) {
        	Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage() ));
        }
	//VOID処理は正常に完了しました。
		Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.MSG_006_0319));
	}
	2017/04/12 不要な処理Methodを削除 WSQ END */
	/**
	* VOID機能取消を行う
	**//* 2017/04/12 不要な処理Methodを削除 WSQ BEGIN
	public void voidProcessCancel() {
        
        // 最新情報取得、設定を行う
        refreshAccoutAcountInfo(oAcountSobj.Id);
        
        if (oAcountSobj.Field39__c != CommConst.ACC_TRADE_VOID) {
//VOID処理をされてない為、VOID取り消し処理ができません。
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
              Label.MSG_006_0320));

            return;
        }
        // 取引種別:00 売上（通常）
        oAcountSobj.Field39__c = CommConst.ACC_TRADE_NORMAL;
        try {
        	update oAcountSobj;
        } catch (Exception e) {
        	Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage() ));
        }
//VOID取り消し処理は正常に完了しました。
		Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.MSG_006_0321));

	}
	2017/04/12 不要な処理Methodを削除 WSQ END */

	public class PageInfo {
		// 画面データステータス維持する
		public PAGE_STATUS dataStatus{get;private set;}
        public Boolean isIns{get{return dataStatus == PAGE_STATUS.INS;}}
        public Boolean isUpd{get{return dataStatus == PAGE_STATUS.UPD;}}
        public Boolean isSel{get{return dataStatus == PAGE_STATUS.SEL;}}
		// 画面関連表示情報格納
		public String strEntryDate{get; private set;}
		public String strDepartureDate{get; private set;}
		// 2016/06/28 入金日表示・非表示制御 BEGIN
		public Boolean isReceipt{get{return (CommDefine__c.getOrgDefaults().ReceiptDtIsShowFlg__c != '2');}}
		// 2016/06/28 入金日表示・非表示制御  END
	}
	// 会計支払
	public class TTendItem {
		public TTendItem(TTend__c o, Integer rsIndex) {
			sobj = o;
			index = rsIndex;
			// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz BEGIN
			if(o.UseDate__c == null && CommConst.BOOKEST_USERDATE_FLG && o.Field1__r.Relreserve__c != null && o.Field1__r.Relreserve__r.EntryTime__c != null){
				ttendUseDate = o.Field1__r.Relreserve__r.EntryTime__c.date();
			}
			if (ttendUseDate == null) ttendUseDate = o.Field1__r.SalesdayCal__c;
			// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz END
		}
		/*
		public void clear() {
			// メディア種別
			sobj.Field2__c = null;
			// カード種別
			sobj.CardTypeLst__c = null;
			// 金券種別
			sobj.CouponTypeLst__c = null;
			// 金券単価
			sobj.Field16__c = null;
			// 金券枚数
			sobj.Field17__c = null;
			// 預かり　金額
			sobj.Field19__c = null;
			// 値割引対象額
			sobj.Field15__c = null;
			// 支払　金額
			sobj.Field20__c = null;
			// 釣銭（差額）金額
			sobj.Field21__c = null;
			// メディア毎消費税額
			sobj.Field25__c = null;
		}*/
		public Integer index{get; private set;}
		public TTend__c sobj{get;set;}
		// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz BEGIN
		public Date ttendUseDate{get;set;}
		// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz END
		/*
		public Boolean isValidata{get{
			return true;
		}}*/
		public Boolean isCanEdit{get{
			return (!CommUtils.isBlank(sobj.Field2__c));
		}}
		// 顧客から支払金額を入力されたの場合
		public Boolean isPaymented{get{
			return (isCanEdit && ((CommUtils.nullToZero(sobj.Field19__c) !=0) ||
								  (CommUtils.nullToZero(sobj.Field15__c) !=0)));
		}}
		// チェックイン機能から自動作成の支払情報（預かり金額はNULL）
		public Boolean isAutoGenByCheckin{get{
			return (isCanEdit && CommUtils.isBlank(sobj.Field19__c));
		}}
		/*
		// 支払　金額 自動設定必要場合
		public Boolean isAutoSetupPayment{get{
			// 預かり金額 + 値割引対象額 -> 支払　金額
			return (isCanEdit && ((CommUtils.nullToZero(sobj.Field19__c) ==0) &&
								  (CommUtils.nullToZero(sobj.Field15__c) ==0)));
		}}*/
		public Boolean isExist{get{return (sobj.id != null);}}
		// 前受け金情報で作成された会計支払情報
		//public Boolean isARProduct {get{ return sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_AR;}}
	}
	// 会計支払合計情報を格納する
	public class TTendFooter {
		public TTendFooter() {
			this.clear();
		}
		// 割引値の合計
		public Decimal amoutDiscountPrice{get; private set;}
		// クーポン金額合計
		public Decimal amoutCouponPrice{get; private set;}
		public Decimal amoutCouponPayPrice{get; private set;}
		// 予約金金額合計
		public Decimal amoutSubscriptionPrice{get; private set;}
		// 予約金 & 前受金合計値情報格納
		//public Decimal amoutSumscriptionSummary{get;set;}
		// 預かり金額の合計
		public Decimal amoutPaymentPrice{get; private set;}
		// 支払金額の合計:預かり金額の中から、会計に使用された金額を処理する。
		public Decimal amoutSalesPrice{get; private set;}
		// 釣銭（差額）金額合計
		public Decimal amoutChangePrice{get; private set;}
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		// 全消費税[割引後の合計値]
		public Decimal amoutSalesTax{get; private set;}
		// 2019/07/30 軽減税率機能対応 WGCH END
        public void add(TTendItem item) {
        	if (!item.isCanEdit) return;
        	// 返金の場合、合計対象外になる
        	if (BillSimpleHelp.isRefundItem(item.sobj.PaymentType__c)) return;
        	// 割引値の合計
            if (item.sobj.Field2__c == MediaTypeDisCount) amoutDiscountPrice += CommUtils.nullToZero(item.sobj.Field19__c);
            // 予約金の合計
            else if (item.sobj.Field2__c == CommConst.MEDIA_TYPE_CD_21) amoutSubscriptionPrice += CommUtils.nullToZero(item.sobj.Field19__c);
            // クーポン金額合計
            else if (item.sobj.Field2__c == CommConst.MEDIA_TYPE_CD_11) {
            	amoutCouponPrice += CommUtils.nullToZero(item.sobj.Field19__c);
            	amoutCouponPayPrice += CommUtils.nullToZero(item.sobj.Field20__c);
            }
            // 預かり金額の合計
            amoutPaymentPrice += CommUtils.nullToZero(item.sobj.Field19__c);
            // 支払金額の合計
            amoutSalesPrice += CommUtils.nullToZero(item.sobj.Field20__c);
            // 釣銭（差額）金額合計
            amoutChangePrice += CommUtils.nullToZero(item.sobj.Field21__c);
        }
        public void clear() {
            amoutDiscountPrice = 0;
            amoutPaymentPrice = 0;
            amoutSalesPrice = 0;
            amoutChangePrice = 0;
            amoutCouponPrice = 0;
            amoutCouponPayPrice = 0;
            amoutSubscriptionPrice = 0;
            //amoutSumscriptionSummary = 0;
            // 2019/07/30 軽減税率機能対応 WGCH BEGIN
            amoutSalesTax = 0;
            // 2019/07/30 軽減税率機能対応 WGCH END
        }
	}
	// 会計明細
	public class TranItem {
		public TranItem(Tran1__c s, Integer rsIndex) {
			sobj = s;
			index = rsIndex;
			//rowNo = Integer.valueOf(s.RowNo__c) > 0 ? Integer.valueOf(s.RowNo__c) : rsIndex+1;
			// 2018/07/27 宿泊税計算 WGCH BEGIN
			rowNo = rsIndex;
			// 2018/07/27 宿泊税計算 WGCH END
			// 2014/09/09 RowNoの自動再設定
			//s.RowNo__c = rsIndex+1;
			// 利用日自動表示、設定を行う
			// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH BEGIN
			if(s.UseDate__c == null && CommConst.BOOKEST_USERDATE_FLG && s.Field1__r.Relreserve__c != null && s.Field1__r.Relreserve__r.EntryTime__c != null){
				s.UseDate__c = s.Field1__r.Relreserve__r.EntryTime__c.date();
				// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz BEGIN
				tranUseDate = s.Field1__r.Relreserve__r.EntryTime__c.date();
				// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz END
			}
			// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH END
			if (s.UseDate__c == null) s.UseDate__c = s.Field1__r.SalesdayCal__c;
			// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz BEGIN
			if (tranUseDate == null) tranUseDate = s.Field1__r.SalesdayCal__c;
			// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz END
			
            amoutIncTax = CommUtils.isBlank(s.Field23__c) ? 0 : Decimal.valueOf(s.Field23__c);
            amoutExcTax = s.GoukeinoneTax__c == null ? 0 : s.GoukeinoneTax__c;
            // 2021/03/30 優化 by zy BEGIN
		    isValidata = checkValidata();
			isPlanProduct = (sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PL);
			isPayProduct = (sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PY);
			isARProduct = (sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_AR);
			// 2021/03/30 優化 by zy END
			// 前受金の返金機能対応
			if (isReFundItem()) {
				sobj.Field20__c = String.valueOf(Math.abs(CommUtils.nullToZero(sobj.Field20__c)));
				amoutIncTax = Math.abs(amoutIncTax);
				amoutExcTax = Math.abs(amoutExcTax);
			}
			// 2021/03/30 優化 by zy BEGIN
			if (taxRate == null){
				taxRate = (CommUtils.nullToZero(sobj.TaxRate__c) / 100);
			} 
			if (unitPrice == null) {
				unitPrice = CommUtils.nullToZero(sobj.Field20__c);
			}
			if (quantity == null) {
				quantity = CommUtils.nullToZero(sobj.Field21__c) ;
			}
			if (specialTax == null) {
				specialTax = CommUtils.nullToZero(sobj.SpecialTax__c) ;
			}
			if (taxUnitPrice == null) {
				taxUnitPrice = (quantity > 0 ? (CommUtils.nullToZero(amoutIncTax) - CommUtils.nullToZero(amoutExcTax) - CommUtils.nullToZero(specialTax)) / quantity : 0);
			}
			if (bTaxAccMstId == null) {
				bTaxAccMstId = '';
			}
			if (bTaxToPlanRowIndex == null) {
				bTaxToPlanRowIndex = '';
			}
			if (bTaxAccMstItem == null) {
				bTaxAccMstItem = '';
			}
			// 2021/03/30 優化 by zy END
            productNm = CommUtils.isBlank(sobj.Field5__c) ? s.Field7__r.Name : sobj.Field5__c;
            orgProductNm = s.Field7__r.Name;
            productCd = s.Field7__r.Field3__c;
            isPlanProduct = false;
		    tranId = sobj.Id;
		    // 2021/02/28 CPU LIMITの最適化 WGCH BEGIN
		    isNoUpdate = !CommUtils.isBlank(tranId);
		    // 2021/02/28 CPU LIMITの最適化 WGCH END
		    accRefId = sobj.Field1__c;
		    // 2014/09/15 数量小数点機能対応
		    
		    // 数量情報が存在するば場合、小数部右側に表示する０は外す対応
		    if (!Commutils.isBlank(sobj.Field21__c)) sobj.Field21__c = CommUtils.deleteRightZero(sobj.Field21__c);
		    // 2014/09/19 金額は小数０を非表示対応（NO403）
		    // 単価
		    if (!CommUtils.isBlank(sobj.Field20__c)) sobj.Field20__c = CommUtils.deleteRightZero(sobj.Field20__c, CommUtils.getPointLen());
		    // 特別税
		    strSpecialTax = CommUtils.deleteRightZero( CommUtils.nullToZero(sobj.SpecialTax__c).format(), CommUtils.getPointLen());
			// 見積もり経由で会計明細情報作成の場合、該当フラグはTRUE
			isEstItemFlg = false;
			// 旧予約ID
			orgLeadId = s.Field1__r.Relreserve__c;
			
			//* 関連の参照情報をクリアする **/
			sobj.Field7__r = null;
			sobj.Field1__r = null;
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			// plan商品Flg
			isPlanMasterFlg = sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PL;
			// 2015/11/11 プラン明細課税、非課税混在合計金額計算対応 BEGIN
			// if (sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) {
			if (isPlanMasterFlg) {
			// 2019/07/30 軽減税率機能対応 WGCH END
				initPlanInfo = 0;
				// 既存の会計明細情報を取得する
				for (Tran1__c sobj: sobj.ParentTran1Ref__r) {
					initPlanInfo += CommUtils.nullToZero(sobj.Field20__c);
				}
			}
			// 2015/11/11 プラン明細課税、非課税混在合計金額計算対応 END
			// 2019/01/30 入湯税の自動設定機能対応 WGCH BEGIN
			bathTaxAutoSetupFlg = false;
			// 2019/01/30 入湯税の自動設定機能対応 WGCH END
			// 2019/10/08 メディア毎消費税額修正对应 WGCH BEGIN
			planBrkInfo = '';
			// 2019/10/08 メディア毎消費税額修正对应 WGCH END
		}
		public void clear() {
			// 消費税
			sobj.TaxRate__c = null;
			// サービス料
			sobj.ServiceRate__c = null;
			// 特別税
			sobj.SpecialTax__c = null;
		}
		public boolean checkValidata(){
			return (!CommUtils.isBlank(sobj.Field7__c) &&
                    !CommUtils.isBlank(sobj.Field20__c) &&
                    !CommUtils.isBlank(sobj.Field21__c));
		}
		public boolean isPlanProduct(){
			return (sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PL);
		}
		public boolean isPayProduct(){
			return (sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PY);
		}
		public boolean isARProduct(){
			return  (sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_AR);
		}
		// 2021/02/28 CPU LIMITの最適化 WGCH BEGIN
		public Boolean isNoUpdate{get; set;}
		// 2021/02/28 CPU LIMITの最適化 WGCH END
		// 2015/11/11 プラン明細課税、非課税混在合計金額計算対応 BEGIN
		public Decimal initPlanInfo{get; set;}
		// 2015/11/11 プラン明細課税、非課税混在合計金額計算対応 END
		public Integer index{get; private set;}
		//public Integer rowNo{get;set;}
		// 2018/07/27 宿泊税計算 WGCH BEGIN
		public Integer rowNo{get;set;}
		// 2018/07/27 宿泊税計算 WGCH END
		// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz BEGIN
		public Date tranUseDate{get;set;}
		// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz END
		/*
		public Decimal taxRate{get; set{
			taxRate = value;
			// 消費税　種別
			sobj.Field27__c = (taxRate == 0 ? '2' : '1');
		}}*/
		public String productNm{get;set;}
		public String productCd{get;set;}
		// 該当商品名は商品名変更ため、ダミ用変数
		public String orgProductNm{get;set;}
		// サービス料金(税込)
		public Decimal servicePriceIncTax{get;set;}
		// 特別税
		public String strSpecialTax{get; set{
			strSpecialTax = value;
			if(sobj != null) {
			sobj.SpecialTax__c = CommUtils.nullToZero(strSpecialTax);
			}
		}}
		// 会計明細単位の合計金額（税抜）[サビース料抜き]
		public Decimal amoutExcTax{get; set;}
		// 会計明細単位の合計金額（税込）[商品売価*数量  + サービス料　+ 特別税]
        public Decimal amoutIncTax{get; set{
        	amoutIncTax = value;
        	if (sobj != null && value !=null && String.valueOf(value) != sobj.Field23__c) sobj.Field23__c = String.valueOf(value);}}
		public Tran1__c sobj{get;set;}
		// データの有効性チェック:[商品コード]/[単価]/[数量] 全部存在する場合、該当入力情報が有効
		public Boolean isValidata{get;private set;}
		public Boolean isPlanProduct{get; set;}
		
		public String tranId{get; set;}
		public String accRefId{get ;set;}
		
		// ************ 新会計メニューに支払情報を格納用 **************
		// 該当会計明細に格納情報は支払商品判断用フラグ
		public Boolean isPayProduct{get;private set;}
		// 会計明細情報は前受金するがどうか
		public Boolean isARProduct {get;private set;}
		// $釣銭（差額）金額
		public Decimal changeAmout{get; set;}
		// 利用金額情報を置いてます
		public Decimal usedAmount{get;set;}
		// 見積明細情報で削除の会計明細
		public Boolean isEstItemFlg{get;set;}
		// 見積明細のID
		public String bookEstItemId{get; set;}	// 見積もり明細のID
		// 関連の予約ID
		public String orgLeadId{get; private set;}
		// 該当行目に画像アイコン情報存在チェック[初期自動設定を行わない]
		public String paymentIconUrl{get; set;}
		// 前受金の返金確認フラグ
		public Boolean isReFundItem() {
			return (isARProduct() && BillSimpleHelp.isRefundItem(sobj.PaymentType__c));
		}
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		// 消費税金額を格納する
		public Decimal taxAmount{get;set;}
		// plan商品Flg
		public Boolean isPlanMasterFlg{get;set;}
		// 2019/07/30 軽減税率機能対応 WGCH END
		// 2019/01/30 入湯税の自動設定機能対応 WGCH BEGIN
		public Boolean bathTaxAutoSetupFlg{get;set;}
		// 2019/01/30 入湯税の自動設定機能対応 WGCH END
		// 2019/10/08 メディア毎消費税額修正对应 WGCH BEGIN
		public String planBrkInfo{get; set;}
		public Decimal taxRate{get; set;}
		public Decimal unitPrice{get; set;}
		public Decimal quantity{get; set;}
		public Decimal taxUnitPrice{get; set;}
		public Decimal specialTax{get; set;}
		// 2019/10/08 メディア毎消費税額修正对应 WGCH END
		// 2020/07/30 入湯税の自動入力機能について改善 zyz BEGIN
		public String bTaxAccMstId{get ; set;}
		public String bTaxToPlanRowIndex{get ; set;}
		public String bTaxAccMstItem{get ;set;}
		// 2020/07/30 入湯税の自動入力機能について改善 zyz END
		// 2021/04/31 #10644 bug fixed by zy BEGIN
		List<CommLogicProcess.ItemData> itemDataArr;
		// 2021/04/31 #10644 bug fixed by zy END
	}
	/**
	* 支払合計値情報格納
	**/
	public class TranFooter {
		public TranFooter() {
            clear();
		}
		// 数量
		public Decimal unitNums{get; private set;}
		// 全会計明細合計金額（税抜き）->全サービス料/特別税含めない
		public Decimal amoutPriceExcTax{get; private set;}
		// 全会計明細合計金額（税含め）
		public Decimal amoutPriceIncTax{get; private set;}
		// 全消費税
		//public Decimal amoutSalesTax{get; private set;}
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		public Decimal amoutSalesTax{get; private set;}
		// 2019/07/30 軽減税率機能対応 WGCH END
		// サービス料(税抜)
		public Decimal amoutServicePrice{get; private set;}
		// サービス料(税込)
		public Decimal amoutServicePriceIncTax{get;private set;}
		// 特別税合計
		public Decimal amoutSpecialTax{get; private set;}
		// 前受付金
		public Decimal amoutAdvancesReceived{get; private set;}

		// 消費税設定存在の明細の税込金額
		public Decimal amoutPriceIncTaxByTax{get;set;}
		
		// 会計明細積み上げ計算
		public void add(TranItem item) {
			// 請求書非表示の場合、集計対象外になる
			// 2020/01/30 非表示の一括解除、あるいは金額を0円にしない非表示設定の追加 WGCH BEGIN
			// if (item.sobj.InvoiceNoShowFlg__c  && accountNoSetAmountWhenNoShowFlg) return;
			if ((accountNoSetAmountWhenNoShowMode == APPOTION_ACCOUNTNOSHOW_1) && item.sobj.InvoiceNoShowFlg__c  && accountNoSetAmountWhenNoShowFlg) return;
			// 2020/01/30 非表示の一括解除、あるいは金額を0円にしない非表示設定の追加 WGCH END
			// 商品は前受付金の場合
			if (item.sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_AR) {
				amoutAdvancesReceived+= item.amoutIncTax;
                return;
			}
			// 商品は支払商品の場合、処理対象外
			if (item.sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PY) {
				return;
			}
			unitNums += CommUtils.nullToZero(item.sobj.Field21__c);
			amoutPriceIncTax += CommUtils.nullToZero(item.sobj.Field23__c);
			amoutPriceExcTax += item.amoutExcTax == null ? 0 : item.amoutExcTax;
			amoutServicePriceIncTax += CommUtils.nullToZero(item.servicePriceIncTax);
			amoutServicePrice += CommUtils.CalExcTaxPrice(item.servicePriceIncTax, item.sobj.TaxRate__c, 0);
//            amoutServicePrice += CommUtils.nullToZero(item.servicePrice);
//            amoutServicePriceIncTax += CommUtils.CalIncTaxPrice(item.servicePrice, item.sobj.TaxRate__c, 0);

            amoutSpecialTax += CommUtils.nullToZero(item.sobj.SpecialTax__c);
			if (item.sobj.TaxRate__c > 0 ) {
				amoutPriceIncTaxByTax += CommUtils.nullToZero(item.sobj.Field23__c) - CommUtils.nullToZero(item.sobj.SpecialTax__c);
			}
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			// 各明細の消費税金額から合計する
			// 2019/10/08 メディア毎消費税額修正对应 WGCH BEGIN
			// amoutSalesTax += CommUtils.nullToZero(item.taxAmount);
			// 2019/10/08 メディア毎消費税額修正对应 WGCH END
			// 2019/07/30 軽減税率機能対応 WGCH END
		}
		public void clear() {
            unitNums = 0;
            amoutPriceExcTax = 0;
            amoutPriceIncTax = 0;
            amoutServicePrice = 0;
            amoutServicePriceIncTax = 0;
            amoutSpecialTax = 0;
            amoutAdvancesReceived = 0;
            amoutPriceIncTaxByTax = 0;
            // 2019/07/30 軽減税率機能対応 WGCH BEGIN
            amoutSalesTax = 0;
            // 2019/07/30 軽減税率機能対応 WGCH END
		}
	}
	//2017/02/16 打印响应 by zy BEGIN
	private OrderServiceHelp.PrintInfo curPrintInfo;
	public transient String prinUrl{get;set;}
	public String localIp{get;set;}
	public transient String statusUrl{get;set;}
	//2017/04/20 已配置打印机ip地址 bug fix by zy BEGIN
	public String printIncludeIp{get;set;}
	//2017/04/20 已配置打印机ip地址 bug fix by zy END
	public transient String printJson{get;set;}
	// 打印机是否配置
	public String strPrintReadyState{get{return CommUtils.nullToBlank(printReadyState);}}
	// m.popプリンター機能有効、無効フラグ:TRUE:有効
	private Boolean printReadyState{get{return (CommDefine__c.getOrgDefaults().AccountsPrintFlg__c == true);}}
	public void print(){
	// 2017/08/18 入金自動印刷機能のドルーオプンー機能フラグ追加　by　zy　BEGIN
	// 2019/07/31 68.モアレリゾートから、POSレジから出力されるレシートのお釣りの金額が0円になってしまう by zy BEGIN
		processPrintJson(true,false);
	}
	/*
	* レーシト印刷情報取得
	* openDoorFlag : 自動ドア開く
	* isFromChangeFlg : 釣銭機の機能対応
	*/
	private void processPrintJson(boolean openDoorFlag,boolean isFromChangeFlg){
	// 2019/07/31 68.モアレリゾートから、POSレジから出力されるレシートのお釣りの金額が0円になってしまう by zy END
	// 2017/08/18 入金自動印刷機能のドルーオプンー機能フラグ追加　by　zy　END
		if (curPrintInfo == null) {
			prinUrl = '';
			statusUrl = '';
			//２０１７・０６・１９　多店舗対応するbug fix　by zy BEGIN
			// shopcode切替
			//OrderServiceHelp.setInstance(UserUtil.CurrentUser.ShopCode__c);
			OrderServiceHelp.setInstance(oShopCode);
			//２０１７・０６・１９　多店舗対応するbug fix　by zy END
			//curPrintInfo = OrderServiceHelp.getPrintByIp(localIp,UserUtil.CurrentUser.ShopCode__c,OrderServiceHelp.LayoutType.ACCOUNT);
			curPrintInfo = OrderServiceHelp.getPrintByIp(localIp,oShopCode,OrderServiceHelp.LayoutType.ACCOUNT);
		}
		// trans 失效问题修复
		if (curPrintInfo != null) {
			prinUrl = curPrintInfo.prinUrl;
			statusUrl = curPrintInfo.statusUrl;
		}
		printJson = '';
		map<string, string> params = new map<string,string>();//ApexPages.currentPage().getParameters();
		// 会計書計算パラメータ１； 
		String bulkid = '';
		for (Id accId : pRelAccountIdList) { bulkid += accId + ',';}
		bulkid = bulkid.removeEnd(',');
		params.put('bulkid',bulkid);
		// パラメータ２
		params.put('shopcd',oShopCode);
		// パラメータ3[固定]
		params.put('fc','33');
		// 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH BEGIN
		// 要处理的会计明细Id信息
		// 2021/02/26 9705 bug fixed by zy BEGIN
		if(!CommUtils.isBlank(selectTranIdJson)){
		// 2021/02/26 9705 bug fixed by zy END
			params.put('trans',selectTranIdJson);
		}
		// 要处理的会计支付Id信息
		// 2021/02/26 9705 bug fixed by zy BEGIN
		if(!CommUtils.isBlank(selectTTendIdJson)){
		// 2021/02/26 9705 bug fixed by zy END
			params.put('ttends',selectTTendIdJson);
		}
		// 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH END
		// パラメータ４
		// 2018/01/19 会計レシート印刷機能言語選択する　by　zy BEGIN
		if (!CommUtils.isBlank(reciptJson)) {
			Map<String,String> objMap = (Map<String,String>)JSON.deserialize(reciptJson,Map<String,String>.class);
			params.putAll(objMap);
		}
		// 2018/01/19 会計レシート印刷機能言語選択する　by　zy END
		AccountAcount__c acc = new AccountAcount__c(Id = oAcountSobj.Id);
		ApexPages.currentPage().getParameters().putAll(params);
		ApexPages.StandardController con = new ApexPages.StandardController(acc);
		AccountPDF pdfcls = new AccountPDF(con);
		if (curPrintInfo != null){
			// 2019/07/31 68.モアレリゾートから、POSレジから出力されるレシートのお釣りの金額が0円になってしまう by zy BEGIN
			Decimal change = pdfcls.getRequestAmount();
			if (change > 0 || isFromChangeFlg) change = 0;
			else change = -change;
			// 2019/07/31 68.モアレリゾートから、POSレジから出力されるレシートのお釣りの金額が0円になってしまう by zy END
			// 2017/04/24 金額数字書式化処理不具合改修 BEGIN
			Map<String,Object> otherMap = new Map<String,Object>{
											'subTotal'=> OrderServiceHelp.currency(CommUtils.nullToZero(pdfCls.getCharge())),
											'total'=> OrderServiceHelp.currency(CommUtils.nullToZero(pdfCls.getCharge())),
											'tax' => OrderServiceHelp.currency(CommUtils.nullToZero(pdfCls.getTax())),
											 // 2020/08/15 クーポンを含んだ支払を行なった場合、レシートを出力すると合計金額が実際に支払った金額ではなく商品の合計金額になってしまいます。 by zy BEGIN
											'recevied' => OrderServiceHelp.currency(CommUtils.nullToZero(pdfCls.recivedAmount)),
											// 'recevied' => OrderServiceHelp.currency(CommUtils.nullToZero(pdfCls.getReceiptCustom())),
											// 2020/08/15 クーポンを含んだ支払を行なった場合、レシートを出力すると合計金額が実際に支払った金額ではなく商品の合計金額になってしまいます。 by zy END
											// 2019/07/31 68.モアレリゾートから、POSレジから出力されるレシートのお釣りの金額が0円になってしまう by zy BEGIN
											'change' => OrderServiceHelp.currency(CommUtils.nullToZero(change))};
											// 2019/07/31 68.モアレリゾートから、POSレジから出力されるレシートのお釣りの金額が0円になってしまう by zy END
			// 2017/04/24 金額数字書式化処理不具合改修 END
			List<Map<String,String>> childList = new List<Map<String,String>>();
			List<Map<String,String>> payList = new List<Map<String,String>>();
			// 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH BEGIN
			// 支払いのリストの部屋付け設定
			// 会計に移動の場合
			if(!CommUtils.isBlank(selectTranIdJson) || !CommUtils.isBlank(selectTTendIdJson)){
				// 会計に移動の場合
				String roomPayName = CommUtils.nullTOBlank(selectSendRoomName) + '部屋付';
				// 部屋付のHEAD
				payList.add(new Map<String,String>{
							'price'=> '',
							'name' => roomPayName});
			}
			// 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH END
			for ( AccountPDF.OnePage onePage : pdfcls.allPageList) {
				for ( AccountPDF.TranItem item: onePage.onePageList) {
					//2017/04/21 skip跳出逻辑改修 by zy BEGIN
					if (CommUtils.isBlank(item.produceNm) ) continue;
					//2017/04/21 skip跳出逻辑改修 by zy END
					if (!item.isPaymentInfo) {
						Map<String,String> detailMap = new Map<String,String>{
							// 2017/04/28 商品金額設定不正不具合改修 BEGIN
							//'price'=> OrderServiceHelp.currency(CommUtils.nullToZero(item.unitPrice)),
							'price'=> OrderServiceHelp.currency(CommUtils.nullToZero(item.amount)),
							// 2017/04/28 商品金額設定不正不具合改修 END
							'name' =>  OrderServiceHelp.encode(CommUtils.nullToblank(item.produceNm)),
							'qty'  => OrderServiceHelp.encode( CommUtils.nullToBlank(item.quantity))};
						childList.add(detailMap);
					} else {
						Map<String,String> detailMap = new Map<String,String>{
							'price'=> OrderServiceHelp.currency(CommUtils.nullToZero(item.amount)),
							'name' =>  OrderServiceHelp.encode(CommUtils.nullToblank(item.produceNm))};
						payList.add(detailMap);
					}
				}
			}
			otherMap.put('rows',childList);
			otherMap.put('pays',payList);
			// 2017/08/18 入金自動印刷機能のドルーオプンー機能フラグ追加　by　zy　BEGIN
			List<OrderServiceHelp.LayoutType> layTypeLst = new List<OrderServiceHelp.LayoutType>{OrderServiceHelp.LayoutType.ACCOUNT};
			
			if (openDoorFlag) layTypeLst.add(OrderServiceHelp.LayoutType.DOOROPEN);
			printJson = OrderServiceHelp.getPrintJsons(curPrintInfo,new List<Tran1__c>() , layTypeLst , new Map<Id,List<FoodDetail__c>>(), oAcountSobj,otherMap);
			// 2017/08/18 入金自動印刷機能のドルーオプンー機能フラグ追加　by　zy　END	
		}
	}
	//2017/02/16 打印响应 by zy END
	public String curPosNo{get;set;}
	public boolean autoDoorOpen;
	private DeviceConfigHelp.DeviceInfo deviceConfig;
	private void initDeviceConfig(){
		curPosNo = '';
		//店舗切り換える
		deviceConfig = DeviceConfigHelp.getDevice(oShopCode);
		chgDevConfig();
	}
	private boolean isPosFlag;
	public String DEF_DEV_POS_NO {get{return '$$$$';}}
	public String DEF_INS_POS_NO {get{return CommUtils.getPosNoByComdefine();}}
	private void chgDevConfig(){
		isPosFlag = false;
		boolean isChangeFlag = false;
		autoDoorOpen = false;
		// 2017/07/03 device fonig 機能追加　by　zy BEGIN
		changeSwitch = false;
		// 2017/07/03 device fonig 機能追加　by　zy END
		if (deviceConfig != null) {
			DeviceConfigHelp.FuncLst accFunc = deviceConfig.getFuncLstByCurPos(curPosNo,DeviceConfigHelp.DeviceType.ACCOUNT);
			isPosFlag = accFunc.orderPrintFlag;
			isChangeFlag = accFunc.changePrintFlag;
			//autoDoorOpen = accFunc.orderAutoDoorOpenFlag;
		}
		if (isChangeFlag) chargeJson();
		if (isPosFlag) {
			if(printReadyState) {
				// 多店铺对应
				// actionfunction调用的方法中，xml会重新加载，因此需要重新读取xml的信息，此时需要区分多店铺的问题
				// 所以需要重新根据店铺code加载xml
				OrderServiceHelp.setInstance(oShopCode);
				printIncludeIp = JSON.serialize(OrderServiceHelp.getIpSet());
			}
		} else {
			curPosNo = '';
		}
	}
	private String chgDefNoToCurpos(String pos){
		//如果curpos为空|| 等于$$$$
		if (CommUtils.isBlank(pos) || pos == DEF_DEV_POS_NO ) return getCurPosByInfo();
		return pos;
	}
	private String getCurPosByInfo(){
		String posNo = '';
		//２０１７・０６・１９　多店舗対応する　by zy BEGIN
		// shopcode切替
		//OrderServiceHelp.setInstance(UserUtil.CurrentUser.ShopCode__c);
		OrderServiceHelp.setInstance(oShopCode);
		// 2107/07/04 pos机关闭时，不进行posno取得 by zy BEGIN
		if (isPosFlag) {
		// 2107/07/04 pos机关闭时，不进行posno取得 by zy END
			// shopcode切替
			//curPrintInfo = OrderServiceHelp.getPrintByIp(localIp,UserUtil.CurrentUser.ShopCode__c,OrderServiceHelp.LayoutType.ACCOUNT);
			curPrintInfo = OrderServiceHelp.getPrintByIp(localIp,oShopCode,OrderServiceHelp.LayoutType.ACCOUNT);
			if (curPrintInfo != null) {
				posNo = curPrintInfo.printNo;
			}
		// 2107/07/04 pos机关闭时，不进行posno取得 by zy BEGIN
		}
		// 2107/07/04 pos机关闭时，不进行posno取得 by zy END
		// pos机关闭但是零钱机好用的情况，需要通过零钱机本机的ip查找pos机的
		if (CommUtils.isBlank(posNo) && changeSwitch) {
			if (changeIpMap != null && changeIpMap.containsKey(localIp)){
				Map<String,Object> changInfo = (Map<String,Object>)changeIpMap.get(localIp);
				String deviceUrl = (String)changInfo.get('deviceUrl');
				if (!CommUtils.isBlank(deviceUrl)) {
					OrderServiceHelp.PrintInfo print = OrderServiceHelp.getPrintInfoByDeviceIp(deviceUrl);
					if (print != null) {
						posNo = CommUtils.nullToBlank(print.printNo);
					}
				}
			}
		}
		return posNo;
	}
	public void initDevice(){
		curPosNo = chgDefNoToCurpos(curPosNo);
		chgDevConfig();
		// 2018/06/12 SCANER機能新規 by zy BEGIN
		refreshPrintBaseInfo();
		// 2018/06/12 SCANER機能新規 by zy END
	}
	// 2017/06/27 支払い店舗別POS機対応　by　zy　END
	// 2017/07/26 4）ログ情報はDBに記載する by zy BEGIN
	@remoteAction
	public static void savePrintLodToDb(String action){
		String curLog = system.now().format('yyyy-MM-dd HH:mm:ss SSS') + '*************会計印刷BEGIN********************\n';
		User u = UserUtil.CurrentUser;
		curLog += 'ユーザ：' + u.name + '（' + u.id +'）\n';
		curLog += action + '\n';
		curLog += system.now().format('yyyy-MM-dd HH:mm:ss SSS') + '*************会計印刷END  ********************\n';
		CommLogUtils.saveLogToDb(curLog,CommLogUtils.LogType.POS,new List<String>{'cmimg','newsmsg','qrurl'});
	}
	// 2017/07/26 4）ログ情報はDBに記載する by zy END
	 // 2017/08/10 入金自動レシート印刷機能追加　by　zy BEGIN
	public void refreshTran1Item(){
		// 更新会計明細
		upsertData();
		// 2017/08/18 入金自動印刷機能のドルーオプンー機能フラグ追加　by　zy　BEGIN
		// オーダーエンドリ設備取得
		// 2019/07/31 68.モアレリゾートから、POSレジから出力されるレシートのお釣りの金額が0円になってしまう by zy BEGIN
		processPrintJson(isOpenDoorFlag,true);
		// 2019/07/31 68.モアレリゾートから、POSレジから出力されるレシートのお釣りの金額が0円になってしまう by zy END
		// 2017/08/18 入金自動印刷機能のドルーオプンー機能フラグ追加　by　zy　END
	}
	 // 2017/08/10 入金自動レシート印刷機能追加　by　zy END
	// 2017/09/06 会計メッセージ項目自定義機能追加 by zy BEGIN
	public List<RowInfo> curRowInfos{get;set;}
	public class RowInfo{
		public List<PageCustomeFieldHelper.CusField> columns{get;set;}
		public Integer columnInt{get;set;}
		public RowInfo(){
			columns = new List<PageCustomeFieldHelper.CusField>();
		}
		public void add(PageCustomeFieldHelper.CusField field){
			columns.add(field);
		}
	}
	class Section{
		public List<String> fieldLst;
		public Integer columnInt;
		public Section(Dom.XMLNode filedDom){
			String fileds = filedDom.getText();
			fieldLst = new List<String>();
			if (!CommUtils.isBlank(fileds)) {
				fieldLst.addAll(CommUtils.nullToBlank(fileds).toLowerCase().deleteWhitespace().split(','));
			}
			columnInt = CommUtils.nullToIntZero(filedDom.getAttribute('COLNUM',null));
			if (columnInt == 0) columnInt = 2;
		}
	}
    public Contact newContact{get;set;}
    // カスタム設定お客様フィルター
    private Set<String> contactSet;
    // カスタム設定会計フィルター
    private Set<String> customBillSet;
    // 定数SQL文
    // 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH BEGIN
    // private String queryContact = 'relaccount__c, frs__c, comment__c, TeaTimeFlag__c, Target__c, TableNo__c, Seq__c, Relreserve__c, PlanNo__c, POSNo__c, OutSideAccount__c, Field99__c, Field98__c, Field97__c, Field96__c, Field95__c, Field94__c, Field93__c, Field92__c, Field91__c, Field90__c, Field89__c, Field88__c, Field87__c, Field86__c, Field85__c, Field84__c, Field83__c, Field82__c, Field81__c, Field80__c, Field7__c, Field79__c, Field78__c, Field77__c, Field76__c, Field75__c, Field74__c, Field73__c, Field72__c, Field71__c, Field70__c, Field69__c, Field68__c, Field67__c, Field66__c, Field65__c, Field64__c, Field63__c, Field62__c, Field61__c, Field60__c, Field59__c, Field58__c, Field57__c, Field56__c, Field55__c, Field54__c, Field53__c, Field52__c, Field51__c, Field50__c, Field49__c, Field48__c, Field45__c, Field40__c, Field39__c, Field159__c, Field158__c, Field141__c, Field150__c,Field126__c,Field116__c, Field114__c,ContactName__c,BillingCal__c, AccountLanguage__c ,DivisionName__c, Name, SumSrvPriceIncTax__c, SumSrvPriceExcTax__c,AmoutSpecialPrice__c,LastModifiedDate, LastModifiedById, TaxRate__c,Relreserve__r.Name,Relreserve__r.refTypeOfRooms__c,Relreserve__r.LeadIndexRef__c,Relreserve__r.StayPersons__c,Relreserve__r.Rroom__c, Discount__c,Relreserve__r.LeadIndexSubId__c,Relreserve__r.RoomGroupNo__c,PaymentFlg__c,relaccount__r.Account.Name, AccountedFlgCal__c,DetailSortBy__c,relaccount__r.Name, relaccount__r.AccountId, AccountName__c,AccountReceiptName__c,AccountProviso__c,AccountReceiptDate__c,frs__r.Salesday__c,SalesDate__c,CouponReturnFlg__c,IsNewLayout__c, ShopCode__c,frs__r.Name,PaymentHandReqFlg__c,ReceiptDt__c,Field145__c';
    // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
    // 2019/11/30 会計の領収証日付値の自動設定制御モード機能対応 WGCH BEGIN
    // 2021/03/31 #9902 bugFixed by zy BEGIN
    private String queryContact = 'RespectLst__c,relaccount__c, frs__c, comment__c, TeaTimeFlag__c, Target__c, TableNo__c, Seq__c, Relreserve__c, PlanNo__c, POSNo__c, OutSideAccount__c, Field99__c, Field98__c, Field97__c, Field96__c, Field95__c, Field94__c, Field93__c, Field92__c, Field91__c, Field90__c, Field89__c, Field88__c, Field87__c, Field86__c, Field85__c, Field84__c, Field83__c, Field82__c, Field81__c, Field80__c, Field7__c, Field79__c, Field78__c, Field77__c, Field76__c, Field75__c, Field74__c, Field73__c, Field72__c, Field71__c, Field70__c, Field69__c, Field68__c, Field67__c, Field66__c, Field65__c, Field64__c, Field63__c, Field62__c, Field61__c, Field60__c, Field59__c, Field58__c, Field57__c, Field56__c, Field55__c, Field54__c, Field53__c, Field52__c, Field51__c, Field50__c, Field49__c, Field48__c, Field45__c, Field40__c, Field39__c, Field159__c, Field158__c, Field141__c, Field150__c,Field126__c,Field116__c, Field114__c,ContactName__c,BillingCal__c, AccountLanguage__c ,DivisionName__c, Name, SumSrvPriceIncTax__c, SumSrvPriceExcTax__c,AmoutSpecialPrice__c,LastModifiedDate, LastModifiedById, TaxRate__c,Relreserve__r.Name,Relreserve__r.refTypeOfRooms__c,Relreserve__r.LeadIndexRef__c,Relreserve__r.StayPersons__c,Relreserve__r.Rroom__c, Discount__c,Relreserve__r.LeadIndexSubId__c,Relreserve__r.RoomGroupNo__c,PaymentFlg__c,relaccount__r.Account.Name, AccountedFlgCal__c,DetailSortBy__c,relaccount__r.Name, relaccount__r.AccountId, AccountName__c,AccountReceiptName__c,AccountProviso__c,AccountReceiptDate__c,frs__r.Salesday__c,SalesDate__c,CouponReturnFlg__c,IsNewLayout__c, ShopCode__c,frs__r.Name,PaymentHandReqFlg__c,ReceiptDt__c,Field145__c,Relreserve__r.EntryTime__c,Relreserve__r.Departure__c,Field95__c,Field94__c,Field86__c,Field79__c,Field71__c,Field63__c,Field55__c,Field45__c,Field141__c,Field150__c,Field114__c,comment2__c,SumSrvPriceIncTax__c,SumSrvPriceExcTax__c,Relreserve__r.Field298__c,Discount__c,AccountName__c,ShopCode__c';
    // 2021/03/31 #9902 bugFixed by zy END
    // 2019/11/30 会計の領収証日付値の自動設定制御モード機能対応 WGCH END
   	// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
   	// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH END
   	// お客様フィルター更新
   	private void preUpdateContact(){
        // 2019/09/15 Security Check BY zyz BEGIN
        if (!CommSecurityUtils.isCanUpdateable(Contact.sObjectType)) {
        	return ;
        }
        // 2019/09/15 Security Check BY zyz END
   		if (contactSet == null || contactSet.isEmpty()) return;
   		if (oAcountSobj.relaccount__c != null ) {
			Sobject contactSobj = oAcountSobj.getSObject('relaccount__r');
			Map<String,Object> checkMap = new Map<String,Object>();
			if (contactSobj != null) {
				// Deserialize it back into a key/value map
				Map<String,Object> objMap = (Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(contactSobj));
				// change tolower
				for (String fieldName : objMap.keySet()) {
					checkMap.put(fieldName.toLowerCase(),objMap.get(fieldName));
				}
			}
	   		for (String contactField : contactSet) {
	   			if (checkMap.containsKey(contactField)) {
	   				object orgValue = checkMap.get(contactField);
	   				if (orgValue != newContact.get(contactField)) {
	   					newContact.put(contactField,orgValue);
	   				}
	   			}
	   		}
	   		newContact.id = oAcountSobj.relaccount__c;
	   		update newContact;
   		}
   	}
   	// 查找
    private List<AccountAcount__c> queryAccount(String billId,String leadId){
    	// 元フィルター取得する
    	Set<String> queryContactSet = new Set<String>(queryContact.toLowerCase().deleteWhitespace().split(','));
    	//　カスタム設定フィルター追加捨
    	if (customBillSet != null) queryContactSet.addAll(customBillSet);
    	// SQL文取得する
    	String querySQL = getQuerySqlBySet(queryContactSet);
    	querySQL += ' From AccountAcount__c ';
    	if (!CommUtils.isBlank(billId)) querySQL += ' where id = \'' + billId + '\'';
    	else if (!CommUtils.isBlank(leadId)) querySQL += ' where Relreserve__c = \'' + leadId + '\'';
    	querySQL += ' order by createddate desc limit 1';
    	// 会計取得
    	List<AccountAcount__c> billLst = DataBase.query(querySQL);
  		// お客様のメッセージ作成
		if (billLst != null && !billLst.isEmpty() && contactSet != null && !contactSet.isEmpty()) {
			String contactId = billLst[0].relaccount__c;
			if (!CommUtils.isBlank(contactId)) {
				newContact = getContactById(contactSet,contactId);
			}
		}
    	return billLst;
    }
    @remoteAction
    public static Object getContactById(String reqJson){
    	RequestInfo req = (RequestInfo)JSON.deserialize(reqJson,RequestInfo.class);
    	String accId = req.accountId;
    	String fileds = req.contactFields;
    	Set<String> fieldSet = new Set<String>(fileds.split(','));
    	Set<String> querySet = new Set<String>();
    	Map<String, Schema.DescribeFieldResult> contactDeafaultValuesMaps = CommSqlUtils.getAllFieldLst(Contact.sObjectType,false,true);
    	// 添加参照字段显示信息
    	for (String fieldName : fieldSet) {
    		if (contactDeafaultValuesMaps.containsKey(fieldName)) {
    			Schema.DescribeFieldResult dr = contactDeafaultValuesMaps.get(fieldName);
    			if (dr.getType() == DisplayType.Reference) {
    				String fieldRefName = dr.getRelationshipName() + '.name';
    				querySet.add(fieldRefName);
    			}
    		}
    		querySet.add(fieldName);
    	}
    	Contact con = getContactById(querySet,accId);
    	Map<String,PageCustomeFieldHelper.CusField> objValueMap = new Map<String,PageCustomeFieldHelper.CusField>();
    	for (String filedName : fieldSet) {
    		Schema.DescribeFieldResult dr = contactDeafaultValuesMaps.get(filedName);
    		PageCustomeFieldHelper.CusField field = new PageCustomeFieldHelper.CusField(dr,false,'','','contact');
    		if (dr.getType() == DisplayType.Reference) {
    			field.id = con.get(filedName);
				Sobject refSobj = con.getSobject(dr.getRelationshipName());
				if (refSobj != null) field.value = con.getSobject(dr.getRelationshipName()).get('name');
    		} else field.value = con.get(filedName);
    		objValueMap.put(filedName,field);
    	}
    	return objValueMap;
    }
    class RequestInfo{
    	String accountId;
    	String contactFields;
    }
    private static Contact getContactById(Set<String> fieldSet,String contactId){
    	Contact curContact = new Contact();
    	String querySQL = getQuerySqlBySet(fieldSet);
		querySQL += ' from Contact where id=\'' + contactId + '\'';
		List<Contact> contacts = Database.query(querySQL);
		if (!contacts.isEmpty()) {
			curContact = contacts[0];
		}
		return curContact;
    }
	// 会計項目自定義
	private void customAccountFields(){
		// 変数初期化
		curRowInfos = new List<RowInfo>();
		newContact = new Contact();
		customBillSet = new Set<String>();
		contactSet = new Set<String>();
		String excuteFields = '';
		//'Field100__c, Field101__c, Field102__c, Field103__c, Field104__c, Field105__c, Field106__c, Field107__c, Field108__c, Field109__c, Field110__c, Field111__c, Field112__c, Field113__c, Field114__c, Field115__c, Field116__c, Field117__c, Field118__c, Field119__c, Field120__c, Field121__c, Field122__c, Field123__c, Field124__c, Field125__c, Field126__c, Field127__c, Field128__c, Field129__c, Field130__c, Field131__c, Field132__c, Field133__c, Field134__c, Field135__c, Field136__c, Field137__c, Field138__c, Field139__c, Field140__c, Field141__c, Field142__c, Field143__c, Field145__c, Field146__c, Field147__c, Field148__c, Field149__c, Field150__c, Field151__c, Field152__c, Field154__c, Field155__c, Field156__c, Field157__c, Field158__c, Field159__c, Field39__c, Field40__c, Field42__c, Field43__c, Field44__c, Field45__c, Field48__c, Field49__c, Field50__c, Field51__c, Field52__c, Field53__c, Field54__c, Field55__c, Field56__c, Field57__c, Field58__c, Field59__c, Field60__c, Field61__c, Field62__c, Field63__c, Field64__c, Field65__c, Field7__c, Field71__c, Field72__c, Field73__c, Field74__c, Field75__c, Field76__c, Field77__c, Field78__c, Field79__c, Field80__c, Field81__c, Field82__c, Field83__c, Field84__c, Field85__c, Field86__c, Field87__c, Field88__c, Field89__c, Field90__c, Field91__c, Field92__c, Field93__c, Field94__c, Field95__c, Field96__c, Field97__c, Field98__c, Field99__c, frs__c, Id, IsDeleted, IsNewLayout__c, IssueDate__c, LastActivityDate, LastModifiedById, LastModifiedDate, LastReferencedDate, LastViewedDate, Name, OtherShopEditCheckFlg__c, OutSideAccount__c, PaymentFlg__c, PaymentHandReqFlg__c, PlanNo__c, POSNo__c, ReceiptDt__c, relaccount__c, Relreserve__c, RoomDisplayNo__c, RoomName__c, RoomSeq__c, SalesDate__c, SalesdayCal__c, SearchDate__c, Seq__c, ShopCode__c, ShopName__c, ShopSeq__c, SumSrvPriceExcTax__c, SumSrvPriceIncTax__c, SumTax__c, SystemModstamp, TableNo__c, Target__c, TaxRate__c, TeaTimeFlag__c, TypeOfRoomCode__c, TypeOfRoomName__c, TypeOfRoomSeq__c, UnitPriceDefKb__c,';
		Set<String> disableFieldSet = new Set<String>{'id','relaccount__r.connectionsentid','relaccount__r.connectionreceivedid','relaccount__r.orgcreatedate__c'
				,'relaccount__r.orgupdatedate__c','relaccount__r.orgcreateuser__c','relaccount__r.orgupdateuser__c','relaccount__r.ownerid','relreserve__c'
				,'salesdate__c','relaccount__c','relaccount__r.accountid','accountname__c','accountreceiptname__c','accountlanguage__c','accountreceiptdate__c'
				,'comment__c','accountproviso__c','couponreturnflg__c','receiptdt__c','typeofroomname__c'};
		// 2020/02/21 社内コメント項目を新規追加(共通定義により、切り替え制限可能) BEGIN
		if (isShowInCommentFlg) disableFieldSet.add('comment2__c');
		// 2020/02/21 社内コメント項目を新規追加(共通定義により、切り替え制限可能) END
		disableFieldSet.addAll(excuteFields.deleteWhitespace().toLowerCase().split(','));
		try{
			// 処理ターゲットのNODEを取得する
			Dom.XmlNode targetNode = CommXmlUtils.encodeParseXmlDoc('BillSimpleInputField', oShopCode,new String[]{'<LOGOIMG>','</LOGOIMG>'});
			Set<String> requireSet = new Set<String>();
			Map<String,String> customLabelMap = new Map<String,String>();
			Map<String,String> styleClassMap = new Map<String,String>();
			Map<String,String> columnMap = new Map<String,String>();
			//字段名对应字段详细信息MAP 字段名为小写
		 	Map<String, Schema.DescribeFieldResult> modelDeafaultValuesMaps = CommSqlUtils.getAllFieldLst(AccountAcount__c.sObjectType,false,true);
		 	Map<String, Schema.DescribeFieldResult> contactDeafaultValuesMaps = CommSqlUtils.getAllFieldLst(Contact.sObjectType,false,true);
		 	Map<String, Schema.DescribeFieldResult> leadDeafaultValuesMaps = CommSqlUtils.getAllFieldLst(Lead__c.sObjectType,false,true);
			// XMLあり
			if ( targetNode != null ) {
				List<String> fieldLst = new List<String>();
				List<Section> sectionLst = new List<Section>();
				for (Dom.XMLNode domNode : targetNode.getChildElements()) {
					String nodeName = domNode.getName();
					if (nodeName == 'FIELDS') {
						for ( Dom.XMLNode filedDom : domNode.getChildElements() ) {
							String domName =  filedDom.getName();
							if (domName == 'SECTION') {
								Section section = new Section(filedDom);
								sectionLst.add(section);
							}
						}
					} else if (nodeName == 'REQUIREDFIELDS') {
						requireSet.addAll(CommUtils.nullToBlank(domNode.getText()).deleteWhitespace().toLowerCase().split(','));
					} else if (nodeName == 'COLNUMSIZE') {
						List<String> columnSizes = CommUtils.nullToBlank(domNode.getText()).deleteWhitespace().toLowerCase().split(',');
						for (String columnStr : columnSizes) {
							if (CommUtils.isBlank(columnStr)) continue;
							String[] fieldArr = columnStr.split(':');
							columnMap.put(fieldArr[0],fieldArr[1]);
						}
					} else if (nodeName == 'STYLECLASS') {
						List<String> styleClass = CommUtils.nullToBlank(domNode.getText()).deleteWhitespace().toLowerCase().split(',');
						for (String styleCss : styleClass) {
							if (CommUtils.isBlank(styleCss)) continue;
							String[] fieldArr = styleCss.split(':');
							styleClassMap.put(fieldArr[0],fieldArr[1]);
						}
					} else if (nodeName == 'LABEL') {
						String[] labelStr =  CommUtils.nullToBlank(domNode.getText()).deleteWhitespace().split(',');
						for (String curLabel : labelStr) {
							if (CommUtils.isBlank(curLabel)) continue;
							String[] fieldArr = curLabel.split(':');
							customLabelMap.put(fieldArr[0].toLowerCase(),fieldArr[1]);
						}
						
					}
				}
				// 行作成
				for (Section sec : sectionLst) {
					Integer columnInt = sec.columnInt;
					RowInfo row = null;
					integer idx = 0;
					for (integer i = 0  ; i < sec.fieldLst.size() ; i++) {
						String fieldName = sec.fieldLst[i].deleteWhitespace().trim();
						// 页面不可显示字段
						if (disableFieldSet.contains(fieldName)) continue;
						if (CommUtils.isBlank(fieldName)) continue;
						if (customBillSet.contains(fieldName)) continue;
						PageCustomeFieldHelper.CusField field = new PageCustomeFieldHelper.CusField();
						boolean isOtherFlag = false;
						Schema.DescribeFieldResult dr;
						String orgFieldName = fieldName;
						if (fieldName != '$_blank_$') {
							if (!modelDeafaultValuesMaps.containsKey(fieldName)) {
								if (fieldName.indexOf('relaccount__r') >= 0) {
									fieldName = fieldName.replace('relaccount__r.','');
									if (!contactDeafaultValuesMaps.containsKey(fieldName)) continue;
									dr = contactDeafaultValuesMaps.get(fieldName);
									// 不可更新项目
									if (!dr.isUpdateable()) continue;
									field = new PageCustomeFieldHelper.CusField(dr,requireSet.contains(orgFieldName),columnMap.get(orgFieldName),styleClassMap.get(orgFieldName),'contact');
									field.styleClass += ' contactClass';
									field.name = fieldName;
									contactSet.add(fieldName);
									isOtherFlag = true;
								} else if (fieldName.indexOf('relreserve__r') >= 0) {
									String leadFieldName = fieldName.replace('relreserve__r.','');
									if (!leadDeafaultValuesMaps.containsKey(leadFieldName)) continue;
									dr = leadDeafaultValuesMaps.get(leadFieldName);
									// 不可更新项目
									if (!dr.isUpdateable()) continue;
									field = new PageCustomeFieldHelper.CusField(dr,requireSet.contains(orgFieldName),columnMap.get(orgFieldName),styleClassMap.get(orgFieldName),'lead');
									field.styleClass += ' leadClass';
									field.name = leadFieldName;
									//isOtherFlag = true;
								} else continue;
							} else {
								dr = modelDeafaultValuesMaps.get(fieldName);
								// 不可更新项目
								if (!dr.isUpdateable()) continue;
								field = new PageCustomeFieldHelper.CusField(dr,requireSet.contains(fieldName),columnMap.get(fieldName),styleClassMap.get(fieldName),'account');
								field.name = fieldName;
							}
							if (customLabelMap.containsKey(orgFieldName)) field.fieldLabel = customLabelMap.get(orgFieldName);
							if (!isOtherFlag) customBillSet.add(fieldName);
							if (row == null) row = new RowInfo();
							row.add(field);
						} else {
							if (row == null) row = new RowInfo();
							row.add(new PageCustomeFieldHelper.CusField());
						}
						idx++;
						// 换行
						if( Math.mod(idx, columnInt) == 0 ){
							row.columnInt = columnInt;	
							curRowInfos.add(row);
							row = null;
						}
					}
					if (row != null ) {
						row.columnInt = columnInt;	
						curRowInfos.add(row);
					}
				}
			}
		}catch(exception e){
			system.debug(logginglevel.info,'error:::::' + e.getStackTraceString());
		}
	}
	/*
	* 根据set 返回sql文检索字段
	*/
	private static String getQuerySqlBySet(Set<String> fieldSet){
    	String querySQL = 'select ';
		for (String contactField : fieldSet) {
			querySQL += contactField + ',';
		}
		querySQL = querySQL.removeEnd(',');
		return querySQL;
    }
	// 2017/09/06 会計メッセージ項目自定義機能追加 by zy END
	// 2017/10/18 チェックアウト機能対応 BEGIN
	// 一括チェックアウト機能が有効の場合、関連N部屋は該当日に存在するがどう
	// 一回チェックアウト機能が有効の場合、関聯の予約情報を一括チェックアウト処理を行う
	// 該当部屋のみチェックアウト処理を行う
	@RemoteAction
	public static string[] checkoutAction(String leadId, String leadIdxId) {
	    String[] result = new List<String>{'',''};
	    // 指定の予約IDからチェックアウトステータス変更を行う
	    Savepoint sp = Database.setSavepoint();
        try {
            // 2018/03/07 Security Check BEGIN
            List<String> chkFieldsLst = new List<String>{'field298__c'};
            Map<String,Schema.SObjectField> mm = Schema.SObjectType.Lead__c.fields.getMap();
            if (!CommSecurityUtils.isCanUpdateable(chkFieldsLst, mm)) {
            	return result;
            }
            // 2018/03/07 Security Check END
            // 該当予約と同じ日付の予約情報を全部チェックアウトする
            // 該当会計に関連の予約情報を取得する、N部屋情報存在　かつ　該当部屋もチェックアウト日の場合、ビル一括印刷画面を起動して、一括チェックアウト指示画面を表示する
	        Date checkoutDate = null;
	        Date currLeadOutDt = null;
	        String currLeadKey = '';
	        Integer LEAD_ST_CANCEL_FLG = CommConst.LEAD_ST_CANCEL_FLG; // キャンセルまち
	        map<String, List<Lead__c>> leadsMap = new map<String, List<Lead__c>>();
	        // 関連予約情報は順番で部屋単位で取得する
	        String targetLeadQuery = 'Select Id,Name, LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c, EntryTime__c, Departure__c, Rroom__c, Rroom__r.Name,Relcontact__c,Relcontact__r.Name,checkoutdate__c From Lead__c '+
	                                 'Where CancelBool__c !=: LEAD_ST_CANCEL_FLG And LeadIndexRef__c = :leadIdxId And Field298__c != null ';
	        // 同じ部屋、到着日順で情報取得する
	        targetLeadQuery += ' Order By LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c, EntryTime__c';
	        List<Lead__c> targetLeads = DataBase.query(targetLeadQuery);
	        for(Lead__c lead : targetLeads) {
	            // ONEROOMの識別キー
	            String key = lead.LeadIndexRef__c + '_' + lead.LeadIndexSubId__c + '_' + lead.RoomGroupNo__c;
	            if(!leadsMap.containsKey(key)) {
	                leadsMap.put(key, new list<lead__c>());
	            }
	            leadsMap.get(key).add(lead);
	            // 該当会計に関連の予約の出発日情報を取得する
	            if (lead.Id == leadId) {
	                currLeadKey = key;
	                currLeadOutDt = lead.Departure__c.date();
	            }
	        }
	        if (CommUtils.isBlank(currLeadKey)) throw new CommException('該当会計に紐付け予約情報が無効な状態ため、チェックアウト失敗になる');
	        List<Lead__c> currRoomleads = leadsMap.get(currLeadKey);
	        checkoutDate = currRoomleads[currRoomleads.size()-1].Departure__c.date();
	        // 該当会計の予約の出発日はまだ最後出発日じゃない場合、チェックアウトできません
	        if (currLeadOutDt != checkoutDate) throw new CommException('最終出発日じゃないため、チェックアウト失敗になりました');
	        // チェックアウト対象データは２件以上場合、一括チェックアウトページへ遷移を行う、その意外の場合、直接チェックアウト、会計書出力を行う
	        for(String key : leadsMap.keySet()) {
	            // 該当部屋の最終出発日は画面指定の日付情報と違うと、該当部屋の予約情報は処理対象外になる
	            List<Lead__c> wkleads = leadsMap.get(key);
	            // 対象外の場合、処理を行わない
	            if(checkoutDate != wkleads[wkleads.size()-1].Departure__c.date()) {
	                // 処理対象外になる
	                leadsMap.remove(key);
	                continue;
	            }
	        }
	        Boolean coAndShowAccountWinFlg = CommDefine__c.getOrgDefaults().CoAndShowAccountWin__c;
	        // 該当会計関連の予約の出発日はまだ届きません、
            if(leadsMap.size() >= 2 || coAndShowAccountWinFlg) {
                // 複数件チェックアウト情報が存在する場合、引き渡す情報を用意して、
                result[0] = leadIdxId;
                result[1] = DateTime.newInstance(checkoutDate.year(),checkoutDate.month(),checkoutDate.day()).format(CommBaseCtrl.getDateFormat());
            }
            if(leadsMap.size() < 2) {
                // １部屋のみチェックアウトが必要ため、該当処理にチェックアウト処理対応
                Lead__c updLead = currRoomleads[currRoomleads.size()-1];
                updLead.Field298__c = CommConst.LEAD_GUEST_ST_CO; // チェックアウト完
                update updLead;
                // 2017/12/19 該当部屋の清掃データを作成する[画面に指定日にて、清掃管理データを作成する] WGCH BEGIN
                (new RoomStatusManager()).createNoCleanRooms(Date.today(), new List<Lead__c>{updLead});
                // 2017/12/19 該当部屋の清掃データを作成する[画面に指定日にて、清掃管理データを作成する] WGCH END
            }
        } catch (Exception e) {
            Database.rollback(sp);
            throw New CommException(CommUtils.getFieldValidationMessage(e.getMessage()));
        }
        return result;
	}
	// 2017/10/18 チェックアウト機能対応 END
	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
	// PlanBrkDn数据合计
	public String planBrkInfoMapJson{get{ if(planBrkInfoMapJson == null) planBrkInfoMapJson = '{}'; return planBrkInfoMapJson;} set;}
	private PlanBrkInfo setPlanBrkInfo(Tran1__c sobj){
		PlanBrkInfo item = new PlanBrkInfo();
		item.unitPrice = CommUtils.nullToZero(sobj.Field20__c);
		item.tax = CommUtils.nullToZero(sobj.TaxRate__c);
		item.serviceRate = CommUtils.nullToZero(sobj.ServiceRate__c);
		item.nums = CommUtils.nullToZero(sobj.Field21__c);
		item.specialTax = CommUtils.nullToZero(sobj.SpecialTax__c);
		item.unitPriceKbn = CommUtils.nullToBlank(sobj.UnitPriceDefKb__c);
		item.productId = CommUtils.nullToBlank(sobj.Field7__c);
		item.actionType = CommUtils.nullToBlank(sobj.ActionType__c);
		return item;
	}
	public class PlanBrkInfo{
		public PlanBrkInfo(){
			unitPrice = tax = serviceRate = nums = specialTax = 0;
			unitPriceKbn = productId = actionType = '';
		}
		public Decimal unitPrice{get;set;}
		public Decimal tax{get;set;}
		public Decimal serviceRate{get;set;}
		public Decimal nums{get;set;}
		public Decimal specialTax{get;set;}
		public String unitPriceKbn{get;set;}
		public String productId{get;set;}
		public String actionType{get;set;}
	}
	// 軽減税率Flg
	public static boolean isReducedTaxFlg{get{ return CommConst.REDUCED_TAXRATE_FLG;} private set;}
	// 小数部分桁数取得する
	private static final Integer gPointLen = CommUtils.getPointLen();
	// 2019/07/30 軽減税率機能対応 WGCH END
	// 2018/01/19 会計レシート印刷機能言語選択する　by　zy BEGIN
	public String reciptJson{get;set;}
	// 2018/01/19 会計レシート印刷機能言語選択する　by　zy END
	// 2018/03/12 連泊コメント同期機能対応 WGCH BEGIN
	private Map<String, String> accCommentMap{get;set;}
	public Boolean isAccountSyncCommentFlg = CommDefine__c.getOrgDefaults().AccountSyncCommentFlg__c;
	// 设置最新的comment__c数据
	private void setNewCommentInfo(AccountAcount__c acc){
		if(!accCommentMap.containsKey(acc.Id)) return;
		for(String key : accCommentMap.KeySet()){
			accCommentMap.put(key, CommUtils.nullToBlank(acc.comment__c));
			// 2020/02/21 社内コメント項目を新規追加(共通定義により、切り替え制限可能) BEGIN
			if (isShowInCommentFlg && accInCommentMap.containsKey(acc.Id)) {
				accInCommentMap.put(key,CommUtils.nullToBlank(acc.comment2__c));
			}
			// 2020/02/21 社内コメント項目を新規追加(共通定義により、切り替え制限可能) END
		}
	}
	// 处理第一天的会计与当前会计的信息
	private void getOneRoomAcc(AccountAcount__c billList_0){
		accCommentMap = new Map<String, String>();
	    // ONEROOMの識別キー
	    List<AccountAcount__c> accBulk = [Select Id,comment__c,comment2__c From AccountAcount__c Where Relreserve__r.LeadIndexRef__c =: billList_0.Relreserve__r.LeadIndexRef__c 
	    											 And Relreserve__r.LeadIndexSubId__c =: billList_0.Relreserve__r.LeadIndexSubId__c 
	    											 And Relreserve__r.RoomGroupNo__c =: billList_0.Relreserve__r.RoomGroupNo__c  Order By Relreserve__r.EntryTime__c limit 1];
	    if(!accBulk.isEmpty()){
	    	accCommentMap.put(billList_0.Id, CommUtils.nullToBlank(accBulk[0].comment__c));
	    	billList_0.comment__c = CommUtils.nullToBlank(accBulk[0].comment__c);
			// 2020/02/21 社内コメント項目を新規追加(共通定義により、切り替え制限可能) BEGIN
			if (isShowInCommentFlg) {
				accInCommentMap.put(billList_0.Id, CommUtils.nullToBlank(accBulk[0].comment2__c));
				billList_0.comment2__c = CommUtils.nullToBlank(accBulk[0].comment2__c);
			}
			// 2020/02/21 社内コメント項目を新規追加(共通定義により、切り替え制限可能) END
	    }
	}
	// 2018/03/12 連泊コメント同期機能対応 WGCH END
	// 2018/04/09 釣銭機入金方式更新 BY ZY BEGIN
    public boolean oldWayFlag{get;set;}
    public boolean beforeChkFlag{get;set;}
    // 2018/04/09 釣銭機入金方式更新 BY ZY END
    // 2018/05/08 請求書のコメント欄を毎回手打ちし自動 zyz BEGIN
	public String mulitiComments {get{
		return CommentHelperCompCtrl.getBillCommentJson();
	}}
    // 2018/05/08 請求書のコメント欄を毎回手打ちし自動 zyz END
    // 2018/06/12 SCANER機能新規 by zy BEGIN
	// 刷新打印机信息
	public void refreshPrintBaseInfo(){
		//OrderServiceHelp.setInstance(oShopCode);
		curPrintInfo = OrderServiceHelp.getPrintByIp(localIp,oShopCode,OrderServiceHelp.LayoutType.ACCOUNT);
		boolean scanerFlag = false;
		// 2020/12/15 会計商品にJANコードを登録し、それをバーコードリーダーで読み取り、会計処理が行えるようにしたい by zy BEGIN
		autoScanerConnectFlg = false;
		// 2020/12/15 会計商品にJANコードを登録し、それをバーコードリーダーで読み取り、会計処理が行えるようにしたい by zy END
		OrderServiceHelp.Device d = OrderServiceHelp.getDeviceMap().get(localIp);
		if (d != null) {
			scanerFlag = d.scanerFlag;
		}
		if (curPrintInfo != null && scanerFlag) {
			prinUrl = curPrintInfo.prinUrl;
			statusUrl = curPrintInfo.statusUrl;
			// 2020/12/15 会計商品にJANコードを登録し、それをバーコードリーダーで読み取り、会計処理が行えるようにしたい by zy BEGIN
			autoScanerConnectFlg = d.autoConnectFlg;
			// 2020/12/15 会計商品にJANコードを登録し、それをバーコードリーダーで読み取り、会計処理が行えるようにしたい by zy END
		}
	}
	// 2018/06/12 SCANER機能新規 by zy END
	// 2018/07/27 宿泊税計算 WGCH BEGIN
	public String hotelInfoJson{get; private set;}
	public class HotelTaxDefineInfo{
		public HotelTaxDefineInfo(){
			planItemPriceMap = new Map<String, List<Decimal>>();
		}
		public Map<String, CommLogicProcess.HotelTaxDefineInfo> hotelTaxDefInstance{get{ return CommLogicProcess.getHotelTaxDefInstance();}}
		public Map<String, List<Decimal>> planItemPriceMap{get; private set;}
	}
	// 2018/07/27 宿泊税計算 WGCH END
	// 2019/01/30 入湯税の自動設定機能対応 WGCH BEGIN
	public void setAccBathTaxItem(){
		// 2019/02/28 入湯税の自動設定機能連泊予約分别設定対応 BEGIN
		accBathTaxItemLst = new List<TranItem>();
		// if(!accBathTaxAutoSetFlg || CommUtils.isBlank(accBathTaxCode) || oAcountSobj == null || oAcountSobj.Relreserve__c == null) return;
		// 未开启自动设定入汤税功能 或者 入汤税商品code设成空 => 跳出
		if(!accBathTaxAutoSetFlg || CommUtils.isBlank(accBathTaxCode)) return;
		/*
		Set<String> leadIdSet = new Set<String>();
		for(AccountAcount__c pRelAcc : pRelAccountsMap.values()){
			leadIdSet.add(pRelAcc.Relreserve__c);
		}
		// 预约1房间n泊总人数计算
		// 默认值
		Integer stayPeople = CommConst.getBookingMansDef() + CommConst.getBookingFemailsDef() + CommConst.getBookingChildrenDef();
		if(orgLeadSobj != null){
			stayPeople = orgLeadSobj.StayPersons__c == null ? 0 : Integer.valueOf(orgLeadSobj.StayPersons__c);
		}
		stayPeople = stayPeople * leadIdSet.size();
		// 人数大于0时处理入湯税设定
		if(stayPeople <= 0) return;
		*/
		// 2019/05/15 入湯税自動入力機能の改善対応 WGCH BEGIN
		// Map<店铺code, 商品code>
		Map<String, String> accBathTaxCodeMap = new Map<String, String>();
		// todo:特殊定义不考虑 例如 =>' C0001: ' 这样的设定认为是他个人设定错误
		// 多店铺定义格式: 01:C0001;02:C0002; * 严格按照店铺code区分没有默认值
		String[] accBathTaxCodeSplit = accBathTaxCode.split(';');
		for(String wkAccBathTaxCode : accBathTaxCodeSplit){
			// 获取多店铺定义详细
			String[] wkAccBathTaxCodeSplit = wkAccBathTaxCode.split(':');
			// 有效定义时处理
			if(wkAccBathTaxCodeSplit.size() == 2){
				String shopCodeStr = CommUtils.nullToBlank(wkAccBathTaxCodeSplit[0]); // 店铺code
				String accBathTaxCodeStr = CommUtils.nullToBlank(wkAccBathTaxCodeSplit[1]); // 商品code
				// 设置Map<店铺code, 商品code> * 重复定义只有第一个设定有效
				if(!accBathTaxCodeMap.containsKey(shopCodeStr)) accBathTaxCodeMap.put(shopCodeStr, accBathTaxCodeStr);
			}
		}
		// 默认值设定
		String accBathTaxCodeFinal = accBathTaxCode;
		// 存在有效多店铺定义的时候处理
		if(accBathTaxCodeMap.size() > 0){
			// 多店铺处理时严格按照店铺code区分没有就跳出处理
			if(!accBathTaxCodeMap.containsKey(oShopCode)) return;
			// 当前店铺有效设定时,code置换处理
			accBathTaxCodeFinal = accBathTaxCodeMap.get(oShopCode);
		}
		// 查找指定code的入汤税商品
		// List<AccountMaster__c> accMastLst = [Select Id, Name, Field3__c, Field5__c, TaxRateCal__c, ServiceRate__c, SpecialTax__c, ActionType__c, PaymentType__c From AccountMaster__c Where Field3__c =: accBathTaxCode];
		List<AccountMaster__c> accMastLst = [Select Id, Name, Field3__c, Field5__c, TaxRateCal__c, ServiceRate__c, SpecialTax__c, ActionType__c, PaymentType__c From AccountMaster__c Where Field3__c =: accBathTaxCodeFinal];
		// 2019/05/15 入湯税自動入力機能の改善対応 WGCH END
		// 指定有效入湯税商品时处理
		if(accMastLst.isEmpty()) return;
		AccountMaster__c accMast = accMastLst[0];
		/*
		List<Tran1__c> tranLst = [select Id from Tran1__c where Field7__c =: accMast.Id And Field1__c in: pRelAccountIdList];
		// 1房间n泊 处理
		if(!tranLst.isEmpty()) return;
		TranItem item = new TranItem(new Tran1__c(), 99999); // 99999序号序号置换重置
		item.sobj.Field7__c = CommUtils.nullToBlank(accMast.Id); // 商品Id
		item.productNm = CommUtils.nullToBlank(accMast.Name); // 商品名字
		item.orgProductNm = CommUtils.nullToBlank(accMast.Name); // 商品名字
		item.productCd = CommUtils.nullToBlank(accMast.Field3__c); // 商品Code
		item.sobj.Field20__c = CommUtils.nullToZero(accMast.Field5__c).format(); // 商品単価
		item.sobj.ActionType__c = CommUtils.nullToBlank(accMast.ActionType__c); // 商品处理种别
		item.sobj.TaxRate__c = CommUtils.nullToZero(accMast.TaxRateCal__c); // 商品消费税
		item.sobj.ServiceRate__c = CommUtils.nullToZero(accMast.ServiceRate__c); // 商品サービス料
		item.sobj.Field21__c = CommUtils.nullToBlank(stayPeople); // 商品数量
		item.bathTaxAutoSetupFlg = true;
		item.accRefId = oAcountSobj.Id; // 会计Id
		item.sobj.UseDate__c = oAcountSobj.frs__c == null ? Date.today() : oAcountSobj.frs__r.Salesday__c; // 売上計上日 => ご利用日
		accBathTaxItem = item; // 赋值最新的入湯税明细
		*/
		Set<String> incBathTaxLeadIdSet = new Set<String>(); // 存在入汤税明细的会计IdSet
		Map<String, AcountInfo> noBathTaxAccInfoMap = new Map<String, AcountInfo>();
		// select 所有会计内还有入汤税商品的明细
		List<Tran1__c> tranLst = [select Id,Field1__r.Relreserve__c from Tran1__c where Field7__c =: accMast.Id And Field1__c in: pRelAccountIdList];
		for(Tran1__c tran : tranLst){
			incBathTaxLeadIdSet.add(tran.Field1__r.Relreserve__c); // 集计关联会计内的入汤税明细
		}
		Set<String> leadIdSet = new Set<String>();
		if(accRenpakuBathAutoSetFlg){ // 分开设定入汤税
			for(String accId : pRelAccountsMap.keySet()){ // 相关联的所有会计
				AccountAcount__c acountSobj = pRelAccountsMap.get(accId);
				// 当前会计参照预约 并且 参照的预约内，关联的会计明细内，没有入汤税商品 并且 参照的预约没有追加过明细
				if(acountSobj.Relreserve__c != null && !incBathTaxLeadIdSet.contains(acountSobj.Relreserve__c) && !leadIdSet.contains(acountSobj.Relreserve__c)){
					leadIdSet.add(acountSobj.Relreserve__c); // 防止一个预约的会计重复追加
					noBathTaxAccInfoMap.put(acountSobj.Id, new AcountInfo(acountSobj, 1)); // 该会计对应的入汤税会计明细信息
				}
			}
		// 合并设定 并且 当前的会计不为空 并且 当前会计有参照的预约 并且 所有关联的会计内没有入汤税会计明细
		} else if(oAcountSobj != null && oAcountSobj.Relreserve__c != null && incBathTaxLeadIdSet.isEmpty()){
			for(AccountAcount__c pRelAcc : pRelAccountsMap.values()){
				leadIdSet.add(pRelAcc.Relreserve__c); // 集计共有多少预约
			}
			noBathTaxAccInfoMap.put(oAcountSobj.Id, new AcountInfo(oAcountSobj, leadIdSet.size())); // 该会计对应的入汤税会计明细信息
		}
		for(AcountInfo accItem : noBathTaxAccInfoMap.values()){
			if(accItem.stayPeople <= 0) continue;
			TranItem item = new TranItem(new Tran1__c(), 99999); // 99999序号序号置换重置
			item.sobj.Field7__c = CommUtils.nullToBlank(accMast.Id); // 商品Id
			item.productNm = CommUtils.nullToBlank(accMast.Name); // 商品名字
			item.orgProductNm = CommUtils.nullToBlank(accMast.Name); // 商品名字
			item.productCd = CommUtils.nullToBlank(accMast.Field3__c); // 商品Code
			item.sobj.Field20__c = CommUtils.deleteRightZero(CommUtils.nullToBlank(CommUtils.nullToZero(accMast.Field5__c)), CommUtils.getPointLen()); // 商品単価
			item.sobj.ActionType__c = CommUtils.nullToBlank(accMast.ActionType__c); // 商品处理种别
			item.sobj.TaxRate__c = CommUtils.nullToZero(accMast.TaxRateCal__c); // 商品消费税
			item.sobj.ServiceRate__c = CommUtils.nullToZero(accMast.ServiceRate__c); // 商品サービス料
			item.sobj.Field21__c = CommUtils.nullToBlank(accItem.stayPeople); // 商品数量
			item.sobj.Field1__c = accItem.accId; // 会计Id
			item.sobj.RelAccount__c = accItem.accSobj.frs__c;
			item.bathTaxAutoSetupFlg = true; // 自动设定的标识
			item.accRefId = accItem.accId; // 会计Id
			item.sobj.UseDate__c = accItem.salesday; // 売上計上日 => ご利用日
			// 2021/06/31 #11196 bug fixed by zy BEGIN
			item.unitPrice =  CommUtils.nullToZero(item.sobj.Field20__c);
			item.quantity = CommUtils.nullToZero(item.sobj.Field21__c);
			// 2021/06/31 #11196 bug fixed by zy END
			accBathTaxItemLst.add(item); // Add最新的入湯税明细
		}
		// 2019/02/28 入湯税の自動設定機能連泊予約分别設定対応 END
	}
	// 2019/02/28 入湯税の自動設定機能連泊予約分别設定対応 BEGIN
	public class AcountInfo{
		public AccountAcount__c accSobj; // 当前会计sobj
		public String accId; // 当前会计ID
		public Date salesday; // ご利用日
		public Integer stayPeople; // 当前人数
		public AcountInfo(AccountAcount__c acountSobj, Integer leadSize){
			accSobj = acountSobj;
			accId = acountSobj.Id;
			salesday = acountSobj.frs__r.Salesday__c == null ? Date.today() : acountSobj.frs__r.Salesday__c; // 売上計上日 => ご利用日
			// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH BEGIN
			if(CommConst.BOOKEST_USERDATE_FLG && acountSobj.Relreserve__c != null && acountSobj.Relreserve__r.EntryTime__c != null){
				salesday = acountSobj.Relreserve__r.EntryTime__c.date();
			}
			// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH END
			stayPeople = CommConst.getBookingMansDef() + CommConst.getBookingFemailsDef() + CommConst.getBookingChildrenDef(); // 人数, 默认值设定
			if(acountSobj.Relreserve__r.StayPersons__c != null){
				stayPeople = Integer.valueOf(acountSobj.Relreserve__r.StayPersons__c); // 入汤税数量计算
			}
			stayPeople *= leadSize; // 合计总数
		}
	}
	// 2019/02/28 入湯税の自動設定機能連泊予約分别設定対応 END
	// 2019/01/30 入湯税の自動設定機能対応 WGCH END
	// 2019/04/30 増税仮対応 WGCH BEGIN
	// 增税商品json数据 
	public String taxIncMstItemJson{get	{ return CommLogicProcess.getTaxIncMstJson();} private set;}
	// 2019/04/30 増税仮対応 WGCH END
	// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
	public static boolean planBrkToHeaderCalFlg{get{ return CommConst.PLAN_BRKTOHEADER_CAL_FLG;} private set;}
	// 2019/10/02 PlanHeader算法切换对应 WGCH END
	// 2019/10/08 メディア毎消費税額修正对应 WGCH BEGIN
	// 2019/10/30 軽減税率割合モード機能対応 WGCH BEGIN
	public Map<String, List<PlanBrkInfo>> batchPlanBrkInfoMap{get; set;}
	public static Decimal taxUnitPriceAll{get; private set;}
	// 対象行Lst
	private List<CommLogicProcess.TaxRowData> taxRowDataLst;
	// 対象行Map <消費税レート,該当消費税関連の金額合計>
	private map<Decimal, CommLogicProcess.TaxRowData> taxRowDataMap;
	// 値引行
	public CommLogicProcess.DisRowData disRowData {get;set;}
	// 値引行Lst
	public List<CommLogicProcess.DisRowData> disRowDataLst {get;set;}
	// 合计行
	public CommLogicProcess.SumAmountRowData sumRowData {get;set;}
	
	private void reducedTaxInit(){
		taxUnitPriceAll = 0;
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
	private void addDetailToMapFun(TranItem tranItem, Decimal noTaxUnitPriceSum) {
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
		if(CommUtils.nullToZero(noTaxUnitPriceSum) != 0  || specialTax > 0){
			// Plan明细里 含有非课税 并且 Map key没有0的情况
			Decimal noTaxKey = 0;
			if(!taxRowDataMap.containsKey(noTaxKey)) taxRowDataMap.put(noTaxKey, new TaxRowData());
			taxRowDataMap.get(noTaxKey).amountExcTax += noTaxUnitPriceSum + specialTax;
			// 集计处理
			sumRowData.amountExcTax += noTaxUnitPriceSum + specialTax;
			sumRowData.amountIncTax += noTaxUnitPriceSum + specialTax;
			// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
			// sumRowData.priceAmountSum += noTaxUnitPriceSum + specialTax;
			// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
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
		item.specialTax = CommUtils.nullToZero(tranItem.sobj.SpecialTax__c); // 明细-特别税
		item.taxRate = tranItem.taxRate; // 明细-特别税
		CommLogicProcess.addDetailToMapFun(item, noTaxUnitPriceSum, comSum);
	}
	// 値引 比率计算 + 详细设值
	private void processSumInfo(Decimal amoutIncDiscont) {
		/*
		Decimal ratioSum = 1;
		disRowData.disUnitPriceSum = amoutIncDiscont; // 値引 合计值 获取
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
		//amoutAllMoneyEnd = sumRowData.amountExcTax + sumRowData.taxAmount;
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
		CommLogicProcess.processSumInfo(amoutIncDiscont, comSum);
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
		public Decimal amountExcTax{get;set;}	 	 // 税抜きの合計金額
		public Decimal amountIncTax{get;set;}	 	 // 税込きの合計金額
		public Decimal taxAmount{get;set;}		   // 該当行目の消費税合計
		public Boolean isNoTaxPrice{get;set;}		// 非課税金額
		public Boolean isDiscountTax{get;set;}	   // 割引
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
		public Decimal taxRate{get;set;} //値引き行目の税率情報を格納する
		// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
		public Decimal disTaxAmountSum{get;set;}		   // 該当行目の消費税合計
		public Decimal disUnitPriceSum{get;set;}
	}
	// 合计行
	public SumAmountRowData sumRowData {get;set;}
	public class SumAmountRowData {
		public SumAmountRowData(){
			taxAmount = amountExcTax = amountIncTax = priceAmountSum = 0;
		}
		public Decimal taxAmount{get;set;}		   // 該当行目の消費税合計
		public Decimal amountExcTax{get;set;} // 合计税拔
		public Decimal amountIncTax{get;set;} // 合计税込
		public Decimal priceAmountSum{get;set;}
	}
	*/
	// 2019/10/30 軽減税率割合モード機能対応 WGCH END
	// 2019/10/08 メディア毎消費税額修正对应 WGCH END
	// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
	public Boolean RespectFlg{get{return CommConst.RESPECT_ISSHOW_FLG;}}
	public String mrTypeLstJson {get; private set;}
	public String mrStr{get; private set;}
	private void initHonor(){
		List<String> mrTypeLst = new List<String>();
		Schema.DescribeFieldResult fieldResult = AccountAcount__c.RespectLst__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry f : ple) {
			if(f.isDefaultValue()) mrStr = f.getLabel();
			mrTypeLst.add(f.getLabel());
		}
		mrTypeLstJson = JSON.serialize(mrTypeLst);
	}
	// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
	// 2020/12/15 会計商品にJANコードを登録し、それをバーコードリーダーで読み取り、会計処理が行えるようにしたい by zy BEGIN
	public Boolean autoScanerConnectFlg{get;set;}
	// 2020/12/15 会計商品にJANコードを登録し、それをバーコードリーダーで読み取り、会計処理が行えるようにしたい by zy END
	// 2021/03/30 優化 by zy BEGIN
	transient public String itemJson{get;set;}
	public integer transRowInt{get;set;}
	public Integer autoSaveLimit{get;set;}
	public String autoSaveMessage{get;set;}
	// 2021/04/31 #10743 bug fixed by zy BEGIN
	public boolean isErrorFlg{get;set;}
	// 2021/04/31 #10743 bug fixed by zy END
	// 2021/03/30 優化 by zy END
}