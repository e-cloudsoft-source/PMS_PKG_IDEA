/**
* 会計書
* 会計書機能対応
* 2013/10/30 会計書の「会計人数」数値は「会計」オブジェクトの【会計人数】として設定する
* 2014/07/24 Coupon処理追加
* 2014/07/30 内消費税表示文言表示
* 2014/08/05 過去の合計計算不具合修正
* 2014/10/20 会計書のレイアウトは店舗別で制御機能を追加
* 2014/12/28 売り掛け分の金額を領収書金額からマイナス計算制御フラグ
* 2015/04/02 ご請求金額のフォントサイズ変更に従って、表示明細行数変更を行う
* 2015/04/08 会計人數表示対応、会計人数は最終日の会計の人数を見て、合計を行う(旧会計の場合、最初日で合計、新会計の場合、最終日で合計)
* 2015/04/10 分割処理する場合、支払メデイア設定により、金額集計を行う
* 2015/04/30 新会計機能に従って、会計支払情報から前受金で作成する場合、合計値対象外になる
* 2015/05/19 会計書33/34前受金と支払情報同時表示対応(新会計レイアウト)
* 2015/05/20 会計書の請求金額訂正する（支払金額は請求金額から外す）[新会計モードの場合]
* 2015/06/18 利用日表示内容を変更を行う
* 2015/06/25 返金機能新規追加
* 2015/07/08 会計書33/34の場合、明細分割機能対応（支払メデイア金額は預かり金額として、表示を行う)
* 2015/10/27 課税、非課税混在対応、明細情報の単価が合計金額から数量にが計算する
* 2015/12/18 会計支払情報は分割情報として、表示できる
* 2016/01/11 ポイント、値引以外の支払メデイアも明細に表示、グループNo登録可能対応
* 2016/03/21 会計書にサビース料金額を出力機能の対応[33/34(共通パラメータにより、会計書にサビース料出力、出力しない制御)]
* 2016/04/08 サビース料金は明細として、請求書に表示の対応[サービス料表示モード２]（右下にサービス料表示)
* 2016/07/12 領収書出力する/しない制御追加と領収金額に内税金額を表示追加する
* 2016/07/18 領収書35/36(領収書なし）レイアウトを追加する
* 2016/08/10 会計書(33/34)英語版に切替機能対応
* 2016/09/09 会計書、請求書明細表示順機能対応
* 2017/01/16 請求書/会計書PDFファイルを自動保存対応
* 2017/04/24 ビル一括印刷機能対応
* 2017/11/02 会計書で印刷した際に、商品名が折り返し出力できるように改善対応
* 2018/02/28 支払種別は「雑損」を作成したい
* 2018/04/27 会計書ハンコ表示・非表示機能対応
* 2018/04/03 会計分割纏める印刷
* 2018/10/07 会計書の明細にそれぞれの部屋名が表記できる改善
* 2018/10/06 領収書の宛名を空白保存しても宛名が表記されてしまう
* 2019/03/20 会計書出力枚数とタイトルをカスタマイズできるように改善対応
* 2019/04/30 増税仮対応
* 2019/05/31 ルームインジケータの印刷ボタンから会計書出力の場合、泊数と到着、出発日は明細別出力できるように改善対応
* 2019/07/30 軽減税率機能対応
* 2019/08/15 会計書1枚目に合計が出る対応
* 2019/09/15 部屋名が表示、会計書崩れる対応
* 2019/10/12 8と10％が混在する為、値引きも両方表記の対応（安分処理方法対応前提、非課税金額は安分処理対象外）
* 2020/01/30 宛名が一定文字数を超えた場合に自動改行する
* 2020/10/26 「明細分割」のタブから印刷を行おうとすると表示が元の商品名のままになってしまうの不具合改修
**/
public with sharing class AccountPDFExtCtrl extends CommBaseCtrl{
	// 2018/10/07 会計書の明細にそれぞれの部屋名が表記できる改善 WGCH BEGIN
	private static Boolean isShowRoomColFlg = (CommDefine__c.getOrgDefaults().AccountShowRoomColFlg__c == null ? false : CommDefine__c.getOrgDefaults().AccountShowRoomColFlg__c);
	public Integer ROOM_INFO_MAX_SIZE{get{return CommConst.ROOM_INFO_MAX_SIZE;}}
	// 2018/10/07 会計書の明細にそれぞれの部屋名が表記できる改善 WGCH END
    // 2018/07/27 宿泊税計算 WGCH BEGIN
    public transient Decimal hotelTax = 0;
    public static Map<String, List<Decimal>> pItemPriceMap = new Map<String, List<Decimal>>();
    // 2018/07/27 宿泊税計算 WGCH END
    // 施設コードにて、レポート改ページ定義を格納する
    private static final Map<String, Integer> pageMap;
    private static final Map<String, Integer> pageMaxMap;
    // 前受金は無条件に明細に表示する設定セット
    //private static final Set<String> prePaymentFlgSet;
    // 開始ページに詳細データ明細件数
    private static final Integer maxLineNums = 30;
    //private static final Integer maxLine2Nums = 22;
    private static final Integer maxLine3Nums = 19; // B5
    //private static final Integer maxLine4Nums = 29; // A4
    //private static final Integer maxLine9Nums = 30; // A4[請求金額表示戻るため]
    //private static final Integer maxLine10Nums = 29;
    //private static final Integer maxLine11Nums = 39;
    //private static final Integer maxLine15Nums = 16;
    // 2017/11/10 35/36Page页面对应 WGCH BEGIN
    private static final Integer maxLine35Nums = 29;
    private static final Integer maxLine36Nums = 40;
    // 2017/11/10 35/36Page页面对应 WGCH END
    // 商品名表示言語
    private static final String lang_jp='jp';
    private static final String lang_en='en';
    public transient Boolean isShowEnName{get; private set;}
    // 統合印刷タイプ
    private static final String ROOM_ONLY = 'r';
    private static final String ROOM_FOOD = 'rf';
    // 分割NO設定値の格納
    private static final Set<String> splitNoSet;
    // 二部出力、二部目は、(控)の文字を追加する
    //public List<Integer> printLoop{get{return new List<Integer>{1,2};}}
    // 2019/03/20 会計書出力枚数とタイトルをカスタマイズできるように改善対応 WSQ BEGIN
    //public transient List<Integer> printLoop{get;private set;}
    public transient List<String> printLoop{get;private set;}
    // 2019/03/20 会計書出力枚数とタイトルをカスタマイズできるように改善対応 WSQ END
    // 領収書分割線LOOP制御変数
    public List<Integer> spliteLineLoop{get{return new List<Integer>{1,2,3,4,5,6,7,8,9,10};}}
    // 但し書き設定値の格納
    //public String accountProviso{get; set;}
    // 会計書文字サイズ大フラグ
    public Boolean isOldManModeFlg{get{ return (CommDefine__c.getOrgDefaults().AccountOldManModeFlg__c == null ? false : CommDefine__c.getOrgDefaults().AccountOldManModeFlg__c);}}
    // 会計書PDFについての(控)を出力制御
    private Boolean isShowCopyInfFlg = ( CommDefine__c.getOrgDefaults().AccountIsShowCopy__c == null ? true : CommDefine__c.getOrgDefaults().AccountIsShowCopy__c);
    // 2016/07/05 領収書出力する/しない制御追加と領収金額に内税金額を表示追加する BEGIN
    public Boolean noreceipt {get;private set;}
    // 2016/07/05 領収書出力する/しない制御追加と領収金額に内税金額を表示追加する END
    // 明細にMedia情報表示・非表示制御
    private Boolean isShowMediaInfFlg= ( CommDefine__c.getOrgDefaults().AccountMediaIsShow__c == null ? false : CommDefine__c.getOrgDefaults().AccountMediaIsShow__c);
    // 売り掛け分の金額を領収書金額からマイナスした対応について、共通定義にマイナスする／しないのパラメータ
    private Boolean isManasAccountMoneyFlg = ( CommDefine__c.getOrgDefaults().AccountMoneyManasFlg__c == null ? false : CommDefine__c.getOrgDefaults().AccountMoneyManasFlg__c);
    // 小数部分桁数取得する
    private static final Integer gPointLen = CommUtils.getPointLen();
    // 2015/05/06 会計のレイアウトNO
    private static final String gLayoutNo = CommDefine__c.getOrgDefaults().BillInputSwitchCode__c;
    // 2016/08/10 会計書(33/34)英語版に切替機能対応
    public transient Boolean isJpLangeFlg{get; private set;}
    // 2017/11/02 会計書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
    // 2019/09/30 会計書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
    // private static Boolean isAccountProdNmReturnFlg{get{ return (CommDefine__c.getOrgDefaults().AccountProdNmReturnFlg__c == null ? false : CommDefine__c.getOrgDefaults().AccountProdNmReturnFlg__c);}}
    private static Boolean isAccountProdNmReturnFlg{get{ return CommConst.ACCOUNT_PRODNM_FLG;}}
    // 2019/09/30 会計書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
    private transient map<String,List<String>> proNameMap = new map<String, List<String>>();
    // 2017/11/02 会計書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
    // 2018/04/27 会計書ハンコ表示・非表示機能対応 BEGIN by zh
    // 2015/01/26 ハンコ表示・非表示機能対応
    public Boolean accStampIsShowFlg{get; private set;}
    // 2018/04/27 会計書ハンコ表示・非表示機能対応 END by zh
    // 2019/05/31 ルームインジケータの印刷ボタンから会計書出力の場合、泊数と到着、出発日は明細別出力できるように改善対応 WGCH BEGIN
    private static String nightsMode = (CommDefine__c.getOrgDefaults().RoomIndicatorAccountPrintCode__c == null ? '0' : CommDefine__c.getOrgDefaults().RoomIndicatorAccountPrintCode__c);
    // 2019/05/31 ルームインジケータの印刷ボタンから会計書出力の場合、泊数と到着、出発日は明細別出力できるように改善対応 WGCH END
    // 2019/05/31 増税仮BUG FIX WGCH BEGIN
    public static CommLogicProcess.TaxIncMstInfo info{get{ if(info == null) info = CommLogicProcess.getTaxIncMstInfo(); return info;}}
    // 2019/05/31 増税仮BUG FIX WGCH END
    // 2019/08/15 会計書1枚目に合計が出る対応 BY zyz BEGIN
    public String allAmountShowType{get;set;}
    // 2019/08/15 会計書1枚目に合計が出る対応 BY zyz END
    // 2019/10/30 点線の位置対応 BY zyz BEGIN
    // 2019/11/15 PDF性能优化对应 WGCH BEGIN
    // public Boolean isSplitLineShowFlg{get{return CommConst.ACCOUNT_SPLITLINE_FLG;}}
    public Boolean isSplitLineShowFlg{get;set;}
    // 2019/11/15 PDF性能优化对应 WGCH END
    // 2019/10/30 点線の位置対応 BY zyz END
    // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
    public static String mrStr{get;set;}
    public Boolean RespectFlg{get;set;}
    // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
    // 2020/01/30 宛名が一定文字数を超えた場合に自動改行する BY zyz BEGIN
    private static Boolean isAccountTitleNameFlg{get{ return !CommConst.APPOTION_TITLE_NAME_FLG;}}
    // 2020/01/30 宛名が一定文字数を超えた場合に自動改行する BY zyz END
    // 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH BEGIN
    public List<String> selectTranIdLst{get; set;}
    public List<String> selectTTendIdLst{get; set;}
    // 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH END
    static {
        pageMap = new Map<String,Integer>{
            // 2017/11/10 35/36Page页面对应 WGCH BEGIN
            '36'=>maxLine36Nums,                // 新会計専用「36:領収書なし」
            '35'=>maxLine35Nums,                // 新会計専用「35:領収書なし」
            // 2017/11/10 35/36Page页面对应 WGCH END
            '34'=>maxLineNums,                  // 新会計専用
            '33' =>maxLine3Nums                 // 新会計専用
            /*
            '24'=>maxLineNums,                  // 英語版
            '23' =>maxLine3Nums,                // 英語版
            '15'=>maxLine15Nums,                // 施設コード：１５のとき、プレ印刷用紙文字列のみ、A4サイズ、領収書あり
            '14'=>maxLineNums,
            '13' =>maxLine3Nums,
            '12' =>maxline11Nums,
            '11'=>maxLine11Nums,                //施設コード：１１のとき、プレ印刷用紙文字列のみ、A4サイズ、領収書なし、文字色一律変更可能
            '10'=>maxLine10Nums,                //施設コード：１０のとき、プレ印刷用紙文字列のみ、B5サイズ、領収書なし、文字色一律変更可能
            '9'=>maxLine9Nums,                  //施設コード：９のとき、プレ印刷用紙文字列のみ、A4サイズ、領収書あり、文字色一律変更可能
            '8'=>maxLine3Nums,                  //施設コード：８のとき、プレ印刷用紙文字列のみ、B5サイズ、領収書あり、文字色一律変更可能
            '7'=>maxLine11Nums,                 //施設コード：７のとき、デザイン性のある明細、A4サイズ、領収書なし
            '6'=>maxLine10Nums,                 //施設コード：６のとき、デザイン性のある明細、B5サイズ、領収書なし
            '4'=>maxLine4Nums,                  //施設コード：４のとき、デザイン性のある明細、A4サイズ、領収書あり
            '3'=>maxLine3Nums,
            // hotel-continental　会社会計書PDF専用ページ
            '2'=>maxLine2Nums,
            // JINYA会社DefaultPDF専用ページ
            '1'=>maxLineNums*/
            };
        pageMaxMap = new Map<String,Integer>{
            // 2017/11/10 35/36Page页面对应 WGCH BEGIN
            '36'=>maxLine36Nums,                // 新会計専用「36:領収書なし」
            '35'=>maxLine35Nums,                // 新会計専用「35:領収書なし」
            // 2017/11/10 35/36Page页面对应 WGCH END
            '34'=>maxLineNums,                  // 新会計専用
            '33'=>maxLine3Nums                  // 新会計専用
            /*
            '24'=>maxLineNums,
            '23'=>maxLine3Nums,
            '15'=>maxLine15Nums,                //施設コード：１５のとき、プレ印刷用紙文字列のみ、A4サイズ、領収書あり
            '14'=>maxLineNums,
            '13'=>maxLine3Nums,
            '12'=>maxline11Nums,
            '11'=>maxLine11Nums,                //施設コード：１１のとき、プレ印刷用紙文字列のみ、A4サイズ、領収書なし、文字色一律変更可能
            '10'=>maxLine10Nums,                //施設コード：１０のとき、プレ印刷用紙文字列のみ、B5サイズ、領収書なし、文字色一律変更可能
            '9'=>maxLine9Nums,                  //施設コード：９のとき、プレ印刷用紙文字列のみ、A4サイズ、領収書あり、文字色一律変更可能
            '8'=>maxLine3Nums,                  //施設コード：８のとき、プレ印刷用紙文字列のみ、B5サイズ、領収書あり、文字色一律変更可能
            '7'=>maxLine11Nums,                 //施設コード：７のとき、デザイン性のある明細、A4サイズ、領収書なし
            '6'=>maxLine10Nums,                 //施設コード：６のとき、デザイン性のある明細、B5サイズ、領収書なし
            '4'=>maxLine4Nums,
            '3'=>maxLine3Nums,
            // hotel-continental　会社会計書PDF専用ページ
            '2'=>maxLine2Nums,
            // JINYA会社DefaultPDF専用ページ
            '1'=>maxLineNums*/
            };
        //prePaymentFlgSet = new Set<String>{'3','4'};
        
        Schema.DescribeFieldResult fieldResult = Tran1__c.SplitGroupNo__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        splitNoSet = new Set<String>();
        for( Schema.PicklistEntry f : ple) {
            splitNoSet.add(f.getValue());
        }
    }
    // 合計金額など集計用会計情報リスト
    private transient List<AccountAcount__c> account;
    private transient AccountAcount__c singelAccount;
    // 会計明細情報を格納する
    private transient List<TranItem> tran;
    // 課税対象商品の売上金額合計を格納する
    private transient Decimal amoutIncTaxprice = 0;
    // 2019/04/30 増税仮対応 BY zyz BEGIN
    private transient Decimal taxIncMstTaxprice = 0;
    // 2019/04/30 増税仮対応 BY zyz EDN
    // サビース料金（税込）
    //private Decimal amoutIncServicePrice = 0;
    // 特別税合計
    private transient Decimal amoutIncSpecialPrice = 0;
    // 割引合計
    //private Decimal amoutIncDiscont = 0;
    // 前受付金の金額合計を格納する
    private Decimal amoutARprice = 0;
    //　返金金額
    private Decimal amountRefundPrice = 0;
    // 税込前金額合計を格納する
    private Decimal amoutAllMoney = 0;
    // 現金
    public transient Decimal amoutAllCash {get;set;}            // 支払金額
    private transient Decimal amoutAllCashPay;              // 預かり金額
    // 掛計
    public transient Decimal amoutAllMultiply {get;set;}        // 支払金額
    private transient Decimal amoutAllMultiplyPay;          // 預かり金額
    // クレジット
    public transient Decimal amoutAllCredit {get;set;}          // 支払金額
    private transient Decimal amoutAllCreditPay;            // 預かり金額
    // クーポン
    public transient Decimal amoutAllCoupon {get;set;}          // 支払金額
    public transient Decimal amoutAllCouponPay{get;set;}        // 預かり金額
    // 割引
    private transient Decimal amountAllDiscount{get; set;}      // 支払金額
    private transient Decimal amountAllDiscountPay;         // 預かり金額
    // 予約金
    public transient Decimal amoutAllSubscription{get;set;}     // 支払金額
    private transient Decimal amoutAllSubscriptionPay;          // 預かり金額
    // 支払商品ID単位で支払メデイア金額合計を格納する（明細分割のみ利用する：2015/07/08) BEGIN
    private transient Map<Id, Tran1__c> payProdAmoutMap;
    private transient List<Id> payProdAmoutIdList;
    // 支払商品ID単位で支払メデイア金額合計を格納する（明細分割のみ利用する：2015/07/08) END
    // 2017/05/11 明細印刷済み識別機能追加 BEGIN
    private transient list<Id> outputTtendIdLst;
    // 2017/05/11 明細印刷済み識別機能追加 END
    //コメント
    public transient String comment {get;private set;}
    // 文字色
    public String pageFontColor{get{ return CommConst.APPOPTION_ACCOUNTPDF_FONT_COLOR;}}
    // 一ページに最大格納できる明細レコード数
    private static String FACILITY_CODE = pageMap.containsKey(CommConst.APPOPTION_FACILITY_CODE) ? CommConst.APPOPTION_FACILITY_CODE : '33';//CommDefine__c.getOrgDefaults().FacilityCode__c == null ? '1' : CommDefine__c.getOrgDefaults().FacilityCode__c;
    // FirstPage [Default 29行]
    //private Integer PAGE_FIRSTPG_BREAK_RSNUM = pageMap.get(FACILITY_CODE); //== null ? maxLineNums : pageMap.get(FACILITY_CODE);
    private Integer PAGE_FIRSTPG_BREAK_RSNUM;
    // SecondPage以後 [Default 29行]
    //private final Integer PAGE_NEXTPG_BREAK_RSNUM = pageMaxMap.get(FACILITY_CODE); //== null ? maxLine2Nums : pageMaxMap.get(FACILITY_CODE);
    private static Integer PAGE_NEXTPG_BREAK_RSNUM{get { return pageMaxMap.get(FACILITY_CODE); }}
    // 予約金は明細に表示する判定区分
    //private final Boolean advancesReceivedChk = CommDefine__c.getOrgDefaults().AdvancesReceivedChk__c == null ? false : CommDefine__c.getOrgDefaults().AdvancesReceivedChk__c;
    // 前頁から引渡パラメータ情報を維持する変数
    private transient final Map<String,String> parMap;
    // 分割標識フラグ
    private Boolean isGroupShowFlg = false;
    // 該当ページに引き渡す会計ID
    private Set<Id> accIdSet;
    // PDFページ毎の明細情報を格納用
    public transient List<OnePage> allPageList{get; private set;}
    // 通貨定義情報格納
    //public String CurrencyInf{get; private set;}
    // 内消費税英語表示文言
    public transient String taxEnglishLabel{get; private set;}
    
    public class OnePage {
        // startRsIndex：データ開始行目
        public OnePage () {
            onePageList = new List<TranItem>();
            currPages = 1;
            // 2019/11/15 PDF性能优化对应 WGCH BEGIN
            isShowTotalFlg = 'display:none;';
            isShowreceiptFlg = 'display:none;';
            // 2019/11/15 PDF性能优化对应 WGCH END
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
        // 2019/08/15 会計書1枚目に合計が出る対応 BY zyz BEGIN
        public Boolean isAmountShow{get;set;}
        // 2019/08/15 会計書1枚目に合計が出る対応 BY zyz END
        // 2019/11/15 PDF性能优化对应 WGCH BEGIN
        public String isShowTotalFlg{get;set;}		// 总金额显示控制
        public String isShowreceiptFlg{get;set;}	// 領収書显示控制
        // 2019/11/15 PDF性能优化对应 WGCH END
    }
    private String shopCode;
    // 2017/04/24 ビル一括印刷機能対応 BEGIN
    public ReportLogo__c repInfo{get; private set;}
    public void setRepInfo (String pspcd) {
        ReportTitleCompCtrl rep = new ReportTitleCompCtrl();
        rep.billRTshopCd = pspcd;
        repInfo = rep.reportInfo;
    }
    // 2017/04/24 ビル一括印刷機能対応 END
    /**
    * 初期化処理を行う
    **/
    public AccountPDFExtCtrl(ApexPages.StandardController controller){
        // 2014/02/05 会計書PDFについての(控)を出力制御対応
        // 2019/03/20 会計書出力枚数とタイトルをカスタマイズできるように改善対応 WSQ BEGIN
        //if (isShowCopyInfFlg) {
        //    printLoop = new List<Integer>{1,2,3};
        //} else {
        //    printLoop = new List<Integer>{1};
        //}
        isJpLangeFlg = CommBaseCtrl.getLocalIsJapanese();
        printLoop = parseAccPrintDef();
        // 2019/03/20 会計書出力枚数とタイトルをカスタマイズできるように改善対応 WSQ END
        // USER INFO
        //CurrencyInf = UserInfo.getDefaultCurrency();// UserUtil.CurrentUser.
        //if (CommUtils.isBlank(CurrencyInf) || CurrencyInf == 'JPY') CurrencyInf = 'YEN';
        // パラメータ情報を取得する
        parMap = ApexPages.currentPage().getParameters();
        // 必ず先に施設コードを引き渡しするがどうか、チェックする
        String strFaclityCode = parMap.get('fc');
        if (!CommUtils.isBlank(strFaclityCode) && pageMap.containsKey(strFaclityCode)) FACILITY_CODE = strFaclityCode;
        // 2012/10/22 URLから引渡パラメータ情報（明細行数設定がある場合、設定の行数で優先に設定する）
        String strPageSize = parMap.get('pgsize');
        if (!CommUtils.isBlank(strPageSize)) {
            PAGE_FIRSTPG_BREAK_RSNUM = Integer.valueOf(strPageSize);
        } else {
            PAGE_FIRSTPG_BREAK_RSNUM = pageMap.get(FACILITY_CODE);
        }
        // 2012/08/25 WSQ ADD[一括会計の場合、複数の会計IDを該当パラメータに格納する]
        String bulkid = parMap.get('bulkid');

        // 2015/10/28 多店舗機能対応 BEGIN
        shopCode = parMap.get('shopcd');
        if (CommUtils.isBlank(shopCode)) shopCode = UserUtil.CurrentUser.ShopCode__c;
        // 2015/10/28 多店舗機能対応 END
        // 2017/04/24 ビル一括印刷機能対応 BEGIN
        setRepInfo(shopCode);
        // 2017/04/24 ビル一括印刷機能対応 END
        // 2016/08/10 会計書(33/34)英語版に切替機能対応 BEGIN
        // 2019/03/20 会計書出力枚数とタイトルをカスタマイズできるように改善対応 WSQ BEGIN
        //sJpLangeFlg = CommBaseCtrl.getLocalIsJapanese();
        // 2019/03/20 会計書出力枚数とタイトルをカスタマイズできるように改善対応 WSQ END
        // 2016/08/10 会計書(33/34)英語版に切替機能対応 END
        // 英語ラベル情報
        taxEnglishLabel = ShopInfoUtil.getTaxEnglishLabel(shopCode);
        // 検索対象会計ID情報を格納する　
        //Set<Id> accIdSet = new Set<Id>();
        accIdSet = new Set<Id>();
        // ビル一括印刷のとき、引き渡す会計のID順で会計書出力を行う
        List<Id> accIdSortLst = new List<Id>();
        //accIdSet.add(controller.getId());
        if (!CommUtils.isBlank(bulkId)) {
            String[] accIdLst = bulkId.split(',');
            for (String s : accIdLst) {
                accIdSet.add(s);
                accIdSortLst.add(s);
            }
        }
        // 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH BEGIN
    	selectTranIdLst = null;
    	selectTTendIdLst = null;
    	if(parMap.containsKey('trans') || parMap.containsKey('ttends')){
    		selectTranIdLst = CommUtils.nullToBlank(parMap.get('trans')).split(',');
    		selectTTendIdLst = CommUtils.nullToBlank(parMap.get('ttends')).split(',');
    	}
    	// 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH END
        // 2016/07/05 領収書出力する/しない制御追加と領収金額に内税金額を表示追加する BEGIN
        noreceipt = parMap.containsKey('noreceipt');
        // 2016/07/05 領収書出力する/しない制御追加と領収金額に内税金額を表示追加する END
        // 2018/04/27 会計書ハンコ表示・非表示機能対応 BEGIN by zh
        String accStampFlg = parMap.get('stampFlg');
        if (CommUtils.isBlank(accStampFlg)) accStampIsShowFlg = CommConst.ACCOUNT_STAMPISSHOW_FLG;
        else accStampIsShowFlg = Boolean.valueOf(accStampFlg);
        // 2018/04/27 会計書ハンコ表示・非表示機能対応 BEGIN by zh
        // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
        RespectFlg = CommConst.RESPECT_ISSHOW_FLG;
        mrStr = '';
        if(RespectFlg) mrStr = CommUtils.nullToBlank(parMap.get('mr'));
        // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
        // 一括会計から設定する場合、該当会計のIDを取得、追加設定する(2013/10/28)
        /*
        if (!CommUtils.isBlank(controller.getId())) {
            singelAccount = [select Relreserve__r.Rroom__r.Name,Relreserve__c, CouponReturnFlg__c,SalesdayCal__c,AccountReceiptDate__c,AccountLanguage__c,AccountName__c,comment__c,ContactName__c,AccountReceiptName__c,BillingCal__c,AccountProviso__c,relaccount__r.Account.Name,frs__r.Salesday__c,DetailSortBy__c,Field53__c from AccountAcount__c where id = :controller.getId()];
            // コメント情報設定を行う
            comment = CommRepUtils.getPdfMaxShowStringNew(singelAccount.comment__c, FACILITY_CODE);
                        //      CommUtils.nullToBlank(singelAccount.comment__c).length() > 40 
                        //      ? CommUtils.nullToBlank(singelAccount.comment__c).subString(0,40)
                        //      : CommUtils.nullToBlank(singelAccount.comment__c);
        }
        */
        if (accIdSet.isEmpty()) {
            accIdSet.add(controller.getId());
            accIdSortLst.add(controller.getId());
        }

        // 一括印刷する・しないフラグ
        Boolean isBulkPrint = isBulkPrint();
        // 関連データを一括取得を行う
        queryAllData(accIdSet, accIdSortLst, controller.getId());
        // 印刷出力対象データ情報を格納する
        bulkPrintInfoLst = new List<OneRoomInfo>();
        // 2018/04/03 会計分割 WGCH BEGIN
        for(accGroupInfo grp : accGroupInfoLst){
        	grpItem = grp;
        // 2018/04/03 会計分割 WGCH END
	        // 取得した会計データからLOOPして、
	        for (String key : oneRoomKeyList) {
	            //該当部屋関連の会計情報を取得する
	            List<AccountAcount__c> repAccs = oneRoomAccMap.get(key);
	            // 一括印刷の場合、SINGLE情報を上書き設定する
	            if (isBulkPrint) singelAccount = oneRoomSingMap.get(key);
	            // コメント情報設定を行う
	            comment = CommRepUtils.getPdfMaxShowStringNew(singelAccount.comment__c, FACILITY_CODE);
	            // このページの内容を処理を行う
	            processPrintInfo(repAccs);
	            // Header情報を設定する
	            LeadIndex__c wkHeader = oneRoomHeaderMap.get(key);
	            // 部屋名を個別設定を行う
	            String roomName = CommUtils.nullToBlank(singelAccount.Relreserve__r.Rroom__r.Name);
	            // 計算した金額は出力のクラスへ設定する
	            bulkPrintInfoLst.add(
	                new OneRoomInfo(
	                    // 該当ページ全て明細情報を格納する
	                    allPageList,
	                    // コメント
	                    comment,
	                    // 部屋名
	                    roomName,
	                    /**
	                    * 利用金額ー預かり金額の結果を格納する
	                    * 該当計算ロジックは新会計画面JSの関数「setupCalSumAmountPrice」を一致するが必要
	                    **/
	                    requestAmount3,
	                    // サビース料
	                    getServiceAmount(),
	                    //get Account#
	                    getAccountNo(),
	                    // get 請求書の宛名先名
	                    getAccountName(),
	                    // get 'お客様'
	                    getCustomer(),
	                    // get 但し書き
	                    getAccountProviso(),
	                    // get '$売上計IV（税込）金額'
	                    getCharge(),
	                    // 領収書利用金額設定
	                    // 領収書利用金額：お客様消費総金額 - 割引 - ポイント及びクーポン　- 売掛金の金額
	                    getReceipt(),
	                    // 領収書金額から計算の内税金額を出力する
	                    getReceiptTax(),
	                    // 消費税
	                    getTax(),
	                     // 領収書日付[yyyy年MM月dd日]
	                    getAccReceiptDate(),
	                    // 部屋単位の泊数と到着日、出発日表示対応
	                    wkHeader,
	                    // 会計人数表示
	                    accountingNums,
	                    // 2018/04/03 会計分割 WGCH BEGIN
	                    // 会計明細情報を格納する
	                    tran,
	                    // 明細印刷済み識別機能追加
	                    outputTtendIdLst
	                    // 2018/04/03 会計分割 WGCH END
	                    // 2018/07/27 宿泊税計算 WGCH BEGIN
	                    ,hotelTax
	                    // 2018/07/27 宿泊税計算 WGCH END
	                    // 2019/07/30 軽減税率機能対応 WGCH BEGIN
	                    ,disRowData
	                    ,sumRowData
	                    ,taxRowDataLst
	                    // 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
	                    ,disRowDataLst
	                    // 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
	                    // 2019/07/30 軽減税率機能対応 WGCH END
	                    ));
	                   
				/**
				* 課税対象商品の売上金額合計を格納する
				* 特別税合計
				* 前受付金の金額合計を格納する
				* 返金金額
				* 税込前金額合計を格納する
				**/
			    amoutIncTaxprice = amoutIncSpecialPrice = amoutARprice = amountRefundPrice = amoutAllMoney = serviceAmount = 0;
			    // 2019/04/30 増税仮対応 BY zyz BEGIN
			    taxIncMstTaxprice = 0;
			    // 2019/04/30 増税仮対応 BY zyz END
			    // 2018/07/27 宿泊税計算 WGCH BEGIN
			    hotelTax = 0;
			    // 2018/07/27 宿泊税計算 WGCH END
			    // 2019/07/30 軽減税率機能対応 WGCH BEGIN
			    if (isReducedTaxFlg) {
			    	// 初始化
			    	reducedTaxInit();
			    }
			    // 2019/07/30 軽減税率機能対応 WGCH END
	        }
        // 2018/04/03 会計分割 WGCH BEGIN
        }
        // 2018/04/03 会計分割 WGCH END
    }
    private void processPrintInfo(List<AccountAcount__c> pAcounts) {
        // 2013/12/17 初期化追加[会計支払情報]
        // 2018/02/28 支払種別は「雑損」を作成したい WGCH BEGIN
        amoutCustomPayLst = new List<AmoutCustomPay>();
        // 2018/02/28 支払種別は「雑損」を作成したい WGCH END
        amoutAllCash = amoutAllMultiply = amoutAllCredit = amoutAllCoupon = amountAllDiscount = amoutAllSubscription = 0;                   // 支払金額
        amoutAllCashPay = amoutAllMultiplyPay = amoutAllCreditPay = amoutAllCouponPay = amountAllDiscountPay = amoutAllSubscriptionPay = 0; // 預り金額
        // 分割NO
        String groupNo = parMap.get('gno'); 
        // 2012/10/25 WSQ ADD 商品名：英語を表示フラグ
        // 会計書言語は引き渡されない場合、会計書経由した情報で設定する
        isShowEnName = parMap.containsKey('language') ? (parMap.get('language') != lang_en ? false : true) : (singelAccount.AccountLanguage__c != lang_en ? false : true);
        // 処理対象明細
        List<Tran1__c> tranRsLst = new List<Tran1__c>();
        List<Ttend__c> tendRsLst = new List<Ttend__c>();

        // コメント情報設定を行う
        comment = CommRepUtils.getPdfMaxShowStringNew(singelAccount.comment__c, FACILITY_CODE);
        // 2013/10/29 会計人数初期化
        accountingNums = 0;
        //Set<Date> rateGetDaySet = new Set<Date>();
        // クーポン利用のフラグ
        Map<Id, Boolean> CouponFlgMap = new Map<Id, Boolean>();
        //query '会計' current page
        /*
        account = [
            select id, name, POSNo__c, relaccount__r.name, Field141__c, Discount__c,
                AmoutSpecialPrice__c,SumSrvPriceExcTax__c,SumSrvPriceIncTax__c,TaxRate__c,
                Field145__c, Field147__c, Field148__c, Field151__c, Relreserve__c, Relreserve__r.RecordTypeId,
                Relreserve__r.LeadIndexRef__c,Relreserve__r.LeadIndexSubId__c,Relreserve__r.RoomGroupNo__c,
                relaccount__r.Account.Name,         // 会計書の請求書欄の請求先名は取得の機能追加　
                Field152__c,                        // 会計人数合計
                IssueDate__c,                       // 会計の発行日
                Relreserve__r.EntryTime__c          // 会計の予約の到着日で、発行日として表示する
                ,CouponReturnFlg__c                 // クーポン利用の返金
            from AccountAcount__c
            //where id = :controller.getId()
            where id in :accIdSet
            Order By frs__r.Name, Name      // 売上日/会計日で並べ順
            ];
        */
        account = pAcounts;
        
        Set<String> containsKeySet = new Set<String>(); // 会計人数合計FILTER
        // 2017/07/27 WGCH 部屋単位の泊数と到着日、出発日表示対応 BEGIN
        //Set<Id> leadIdSet = new Set<Id>();
        // 2017/07/27 WGCH 部屋単位の泊数と到着日、出発日表示対応 END
        // 2015/04/09 最初日の会計人数を統計から最終日の会計人数を合計に変更を行う BEGIN
        Map<String, Decimal> peopleNumsMap = new Map<String, Decimal>();    // 会計人数情報を格納する
        // 2015/04/09 最初日の会計人数を統計から最終日の会計人数を合計に変更を行う END
        // 2019/09/15 部屋名が表示、会計書崩れる対応 BY zyz BEGIN
        set<String> roomNameSet = new set<String>();
        // 2019/09/15 部屋名が表示、会計書崩れる対応 BY zyz END
        // 総税込金額を合計する
        for (AccountAcount__c acc: account) {
        	// 2019/09/15 部屋名が表示、会計書崩れる対応 BY zyz BEGIN
        	if(!roomNameSet.contains(acc.Relreserve__r.Rroom__r.Id)) roomNameSet.add(acc.Relreserve__r.Rroom__r.Id);
            // 2019/09/15 部屋名が表示、会計書崩れる対応 BY zyz END
            // 総計金額を計算する
            //amoutAllMoney += CommUtils.nullToZero(acc.Field151__c);
            // 割引額を合計する
            //amoutIncDiscont += CommUtils.nullToZero(acc.Discount__c);
            // 特別税金が存在する場合、明細へ追加する
            //if (acc.AmoutSpecialPrice__c != null && acc.AmoutSpecialPrice__c > 0) {
            //amoutIncSpecialPrice += CommUtils.nullToZero(acc.AmoutSpecialPrice__c);
            //}
            // 2017/07/27 WGCH 部屋単位の泊数と到着日、出発日表示対応 BEGIN
            //if (acc.Relreserve__c != null)  leadIdSet.add(acc.Relreserve__c);
            // 2017/07/27 WGCH 部屋単位の泊数と到着日、出発日表示対応 END
            // 2014/03/21 会計人数
            String key = acc.Relreserve__r.LeadIndexRef__c + '_' + acc.Relreserve__r.LeadIndexSubId__c + '_' + acc.Relreserve__r.RoomGroupNo__c;
            if (!containsKeySet.contains(key)) {
                accountingNums += acc.Field152__c;
                containsKeySet.add(key);
            }
            // 2015/04/09 最初日の会計人数を統計から最終日の会計人数を合計に変更を行う BEGIN
            peopleNumsMap.put(key, acc.Field152__c);
            // 2015/04/09 最初日の会計人数を統計から最終日の会計人数を合計に変更を行う END
            // Coupon返金を追加する
            CouponFlgMap.put(acc.Id, acc.CouponReturnFlg__c);
            
            // 2018/04/03 会計分割 WGCH BEGIN
            /*
            // 会計明細情報はリストへ格納する
            if (oneRoomTranMap.containsKey(acc.Id)) tranRsLst.addAll(oneRoomTranMap.get(acc.Id));
            // 会計支払情報はリストへ格納する
            if (oneRoomTtendMap.containsKey(acc.Id)) tendRsLst.addAll(oneRoomTtendMap.get(acc.Id));
            */
            String pageKey = getPageKey(acc.Id, grpItem.splitGroupNo);
            // 会計明細情報はリストへ格納する
            if (oneRoomTranMap.containsKey(pageKey)) tranRsLst.addAll(oneRoomTranMap.get(pageKey));
            // 会計支払情報はリストへ格納する
            if (oneRoomTtendMap.containsKey(pageKey)) tendRsLst.addAll(oneRoomTtendMap.get(pageKey));
            // 2018/04/03 会計分割 WGCH END
        }
        // 2015/04/13 新会計の場合、最初日の会計人数を統計から最終日の会計人数を合計に変更を行う BEGIN
        //String layoutNo = CommDefine__c.getOrgDefaults().BillInputSwitchCode__c;
        if (gLayoutNo == BillInputSwitchCtrl.BILL_LAYOUT_CODE_2) {
            accountingNums = 0;
            for (Decimal d : peopleNumsMap.values()) {
                accountingNums += d;
            }
        }
        // 2015/04/13 最初日の会計人数を統計から最終日の会計人数を合計に変更を行う END
        // 2015/05/14 新会計画面から並び順で明細表示を行う対応するため、情報はMAPに格納を行う
        Map<String, TranItem> locSortKeyMap = new Map<String, TranItem>();
        // 2013/10/17 金券情報を格納する
        List<TranItem> goldNoteTran = new List<TranItem>();
        // 2013/05/06 ADD 支払情報を合計を行う
        if (!isGroupShowFlg) {
            // $支払金額合計値格納する
            Map<String, Decimal> ttendInfoMap = new Map<String, Decimal>();
            // $預かり金額合計値格納する
            Map<String, Decimal> ttendPayInfoMap = new Map<String, Decimal>();
            String medialabel = TTend__c.field3__c.getDescribe().getName();
            // 支払金額を集計する「預かり金額・支払金額」
            /*
            for (TTend__c ttend : [select CardTypeLst__c,CouponTypeLst__c,Field29__c, Field28__c, field2__c, field3__c, Field1__c,RowNo__c,PayProductRef__c,PaymentType__c,PayProductName__c,Field19__c,UseDate__c,RelAccount__c,Field1__r.Relreserve__r.Rroom__c,RelAccount__r.Salesday__c,RelAccount__r.Name,Name,Field30__c  
                                    ,Field1__r.Relreserve__r.LeadIndexRef__c,Field1__r.Relreserve__r.LeadIndexSubId__c,Field1__r.Relreserve__r.RoomGroupNo__c
                                    From TTend__c where Field1__c in :accIdSet And InvoiceNoShowFlg__c != true And PayProductRef__r.ActionType__c != :CommConst.PROD_ACTION_TYPE_AR ]) {
                */
            for (TTend__c ttend : tendRsLst) {
                // Media名
                String ttendMedia = CommUtils.nullToBlank(ttend.field3__c);
                // 支払　金額
                // Copon返金を設置する場合、MediaはCoponの場合、預かり金額金額で、支払金額に設置する
                Decimal paymentMoney = CommUtils.nullToZero(ttend.Field29__c);
                if (CouponFlgMap.containsKey(ttend.Field1__c) && CouponFlgMap.get(ttend.Field1__c) && ttendMedia == CommConst.MEDIA_TYPE_11) {
                    paymentMoney = CommUtils.nullToZero(ttend.Field28__c);
                }
                // 支払金額
                if (!ttendInfoMap.containsKey(ttendMedia)) ttendInfoMap.put(ttendMedia, paymentMoney);
                else ttendInfoMap.put(ttendMedia, ttendInfoMap.get(ttendMedia) + paymentMoney);
                // 預かり　金額
                //ttendPayInfoMap.put(String.valueOf(sobj.get(medialabel)), CommUtils.nullToZero(String.valueOf(sobj.get('amoutPayIncTax'))));
                if (!ttendPayInfoMap.containsKey(ttendMedia)) ttendPayInfoMap.put(ttendMedia, CommUtils.nullToZero(ttend.Field28__c));
                else ttendPayInfoMap.put(ttendMedia, ttendPayInfoMap.get(ttendMedia) + CommUtils.nullToZero(ttend.Field28__c));
                // 施設コード３３・３４の場合、支払情報も設定する
                if (isNewModeType()) {
                    // 支払情報も会計明細に表示の対応
                    locSortKeyMap.put(getSortKey(null, ttend,containsKeySet.size()), convertTtendToTranItem(ttend));
                }
            }
            // 2018/02/28 支払種別は「雑損」を作成したい WGCH BEGIN
            for(String mediaType : ttendInfoMap.keySet()){
            	if( mediaType == CommConst.MEDIA_TYPE_01 || 
	            	mediaType == CommConst.MEDIA_TYPE_02 || 
	            	mediaType == CommConst.MEDIA_TYPE_03 || 
	            	mediaType == CommConst.MEDIA_TYPE_11 || 
	            	mediaType == CommConst.MEDIA_TYPE_12 || 
	            	mediaType == CommConst.MEDIA_TYPE_21   ) continue;
            	amoutCustomPayLst.add(new amoutCustomPay(CommUtils.nullToZero(ttendInfoMap.get(mediaType)), CommUtils.nullToZero(ttendPayInfoMap.get(mediaType))));
            }
            // 2018/02/28 支払種別は「雑損」を作成したい WGCH END
            // 現計(税込)
            amoutAllCash = CommUtils.nullToZero(ttendInfoMap.get(CommConst.MEDIA_TYPE_01));
            amoutAllCashPay = CommUtils.nullToZero(ttendPayInfoMap.get(CommConst.MEDIA_TYPE_01));
            // 掛計(税込)
            amoutAllMultiply = CommUtils.nullToZero(ttendInfoMap.get(CommConst.MEDIA_TYPE_03));
            amoutAllMultiplyPay = CommUtils.nullToZero(ttendPayInfoMap.get(CommConst.MEDIA_TYPE_03));
            // クレジット計
            amoutAllCredit = CommUtils.nullToZero(ttendInfoMap.get(CommConst.MEDIA_TYPE_02));
            amoutAllCreditPay = CommUtils.nullToZero(ttendPayInfoMap.get(CommConst.MEDIA_TYPE_02));
            // クーポン計
            amoutAllCoupon = CommUtils.nullToZero(ttendInfoMap.get(CommConst.MEDIA_TYPE_11));
            amoutAllCouponPay = CommUtils.nullToZero(ttendPayInfoMap.get(CommConst.MEDIA_TYPE_11));
            // 割引計
            amountAllDiscount = CommUtils.nullToZero(ttendInfoMap.get(CommConst.MEDIA_TYPE_12));
            amountAllDiscountPay = CommUtils.nullToZero(ttendPayInfoMap.get(CommConst.MEDIA_TYPE_12));
            // 予約金[預かり金額]で画面に表示を行う
            amoutAllSubscription = CommUtils.nullToZero(ttendInfoMap.get(CommConst.MEDIA_TYPE_21));
            amoutAllSubscriptionPay = CommUtils.nullToZero(ttendPayInfoMap.get(CommConst.MEDIA_TYPE_21));
            // 
            // 2014/03/26 Media明細に表示・非表示制御機能追加
            // 33/34の場合、支払メデイアは個別表示は行わない
            /*
            if (isShowMediaInfFlg && !isNewModeType()) {
                // 2013/10/17 会計書に単泊、金券情報は会計書に表示する BEGIN
                for (TTend__c ttend : [select CardTypeLst__c, CouponTypeLst__c, Field16__c, Field17__c,RelAccount__r.Salesday__c,
                                                Field19__c,Field20__c
                                        from TTend__c 
                                        where Field1__c in :accIdSet 
                                        And InvoiceNoShowFlg__c != true 
                                        And (
                                        CardTypeLst__c != null OR 
                                        (CouponTypeLst__c != null And Field17__c != null And Field16__c != null) )
                                        Order By RelAccount__r.Name, Name]) {
                    // カード種別
                    if (!CommUtils.isBlank(ttend.CardTypeLst__c)) {
                        TranItem ti = new TranItem(
                                        new Tran1__c(
                                           RelAccount__r = ttend.RelAccount__r,
                                           Field5__c = '　' + ttend.CardTypeLst__c,
                                           Field20__c = ttend.Field20__c,
                                           Field21__c = '1',
                                           RowNo__c = goldNoteTran.size() + 1),
                                           goldNoteTran.size()+1);
                        ti.isShowCircle = false;
                        ti.isShowPrice = false;
                        goldNoteTran.add(ti);
                    } 
                    // 金券種別
                    else {
                        TranItem ti = new TranItem(
                                        new Tran1__c(
                                           RelAccount__r = ttend.RelAccount__r,
                                           Field5__c = '　' + ttend.CouponTypeLst__c,
                                           Field20__c = ttend.Field16__c,
                                           Field21__c = ttend.Field17__c,
                                           RowNo__c = goldNoteTran.size() + 1),
                                           goldNoteTran.size()+1);
                        ti.isShowCircle = false;
                        ti.isShowPrice = false;
                        goldNoteTran.add(ti);
                    }
                } // End Select Query
            
            } // End if (isShowMediaInfFlg)*/
            // 関連金額項目設定を行う
        } // End if (!isGroupShowFlg) 
        /*
        List<Tran1__c> tranRsLst = new List<Tran1__c>();
        // 2013/01/27 ADD/EDIT
        String tranQuery = 'select (Select Field20__c From ParentTran1Ref__r where (TaxRate__c = null OR TaxRate__c = 0) And ParentTran1Ref__r.ActionType__c = \''+CommConst.PROD_ACTION_TYPE_PL + '\'),id, name, RowNo__c, PaymentType__c, Field5__c, Tankanonetax__c, Field20__c, Field21__c,ServiceRate__c ,Field7__r.ProductEnName__c,Field41__c,TaxRate__c, ActionType__c, Field23__c, RelAccount__r.Salesday__c, SpecialTax__c,SplitGroupNo__c,UnitPriceDefKbCal__c,Field1__r.Relreserve__r.Rroom__r.Name,PayProductRef__c,PayProductRef__r.PaymentType__c,PayProductRef__r.Name,UseDate__c,RelAccount__r.Name  '+
                            ',Field1__r.Relreserve__r.LeadIndexRef__c,Field1__r.Relreserve__r.LeadIndexSubId__c,Field1__r.Relreserve__r.RoomGroupNo__c '+
                            'from Tran1__c ';
        tranQuery += ' where Field1__c in :accIdSet  ';
        if (printType == ROOM_ONLY) {
            tranQuery += ' And ActionType__c = \'' + CommConst.PROD_ACTION_TYPE_RP + '\'';
        } else if (printType == ROOM_FOOD) {
            tranQuery += ' And ( ActionType__c = \'' + CommConst.PROD_ACTION_TYPE_RP + '\'';
            tranQuery += '      OR ActionType__c = \'' + CommConst.PROD_ACTION_TYPE_MO + '\')';
        } else if (isGroupShowFlg) {
            // 分割出力
            if (splitNoSet.contains(groupNo)) {
                tranQuery += ' And SplitGroupNo__c = :groupNo ';
            } else {
                tranQuery += ' And SplitGroupNo__c = null ';
            }
             if(!CommConst.APPOTION_ACCOUNTSPLIT_BKISHOW){
                tranQuery += ' And ParentTran1Ref__c = null ';
            }
            // 2015/12/23 ADD 会計明細に前受付金、返金は明細に非表示制御 BGEIN
            if (noShowTranArPay) {
                tranQuery += ' And ActionType__c != \'' + CommConst.PROD_ACTION_TYPE_AR + '\' ';
            }
            // 2015/12/23 ADD 会計明細に前受付金、返金は明細に非表示制御 END
        } else {
            // ALLの場合、集計対象のデータだけ、レポートへ出力する
            //tranQuery += ' And Accountoutside__c =1 And InvoiceNoShowFlg__c != true ';
            tranQuery += ' And ParentTran1Ref__c = null And InvoiceNoShowFlg__c != true ';
        }
        // Order By Add
        if (!isGroupShowFlg) {
            if (singelAccount != null && !CommUtils.IsBlank(singelAccount.DetailSortBy__c)) {
                // 並び順から設定荒れている場合、プランは一番上に表示して、その後、詳細の明細を表示する
                // プラン個別抽出を行う
                String queryStr2 = tranQuery;
                queryStr2 += ' And ActionType__c = \'' + String.escapeSingleQuotes(CommConst.PROD_ACTION_TYPE_PL) + '\'';
                queryStr2 += ' Order By RelAccount__r.Name, Name ';  
                tranRsLst = DataBase.query(queryStr2);
                
                tranQuery += ' And ActionType__c != \'' + String.escapeSingleQuotes(CommConst.PROD_ACTION_TYPE_PL) + '\'';
                tranQuery += ' Order By ' + singelAccount.DetailSortBy__c;
            } else {
                tranQuery += ' Order By RelAccount__r.Name, RowNo__c, Name ';
            }
        } else {
            tranQuery += ' Order By SplitGroupNo__c, RelAccount__r.Name, Name ';
        }*/
//System.debug('tranQuery:::' + tranQuery);
        //query '会計明細' current page
        /*
        List<Tran1__c> tranRsLst = [
                select id, name, RowNo__c, Field5__c, Tankanonetax__c, Field20__c, Field21__c,ServiceRate__c ,Field7__r.ProductEnName__c,
                    Field41__c,TaxRate__c, ActionType__c, Field23__c, RelAccount__r.Salesday__c, SpecialTax__c
                from Tran1__c
                //where Field1__c = :account.id
                where Field1__c in :accIdSet
                And Accountoutside__c =1 And InvoiceNoShowFlg__c != true
                Order By RelAccount__r.Name, Name];*/
        
        // 明細単位の合計情報
        //Decimal amoutAllMoneyDetail = 0;
        //Decimal amoutIncDiscontDetail = 0;
        //Decimal amoutIncSpecialPriceDetail = 0;   // 特別税
        // 分割の場合、集計用情報を再クリアする
        if (isGroupShowFlg) {
            // 2018/02/28 支払種別は「雑損」を作成したい WGCH BEGIN
            amoutCustomPayLst = new List<AmoutCustomPay>();
            // 2018/02/28 支払種別は「雑損」を作成したい WGCH END
            amoutAllCash = amoutAllMultiply = amoutAllCredit = amoutAllCoupon = amountAllDiscount = amoutAllSubscription = 0;                   // 支払金額
            amoutAllCashPay = amoutAllMultiplyPay = amoutAllCreditPay = amoutAllCouponPay = amountAllDiscountPay = amoutAllSubscriptionPay = 0; // 預り金額
        }
        //query '会計明細' current page
        tran = new List<TranItem>();
        // 
        //tranRsLst.addAll((List<Tran1__c>)DataBase.query(tranQuery));
        // 2015/04/10 分割の場合、明細の支払メデイア種別で集計する
        Map<String, String> paymentTypeToMediaLabMap = new Map<String, String>();
        // 2016/01/11 ポイント、値引以外の支払メデイアも明細に表示、グループNo登録可能対応
        Boolean isHaveTtendPayInfo = false;
        if (isGroupShowFlg) {
            // 2017/05/11 明細印刷済み識別機能追加 BEGIN
            outputTtendIdLst = new List<Id>();
            // 2017/05/11 明細印刷済み識別機能追加 END
            // 2015/10/28 多店舗機能対応 BEGIN
            // paymentTypeToMediaLabMap = (new BillSimpleHelp(UserUtil.CurrentUser.ShopCode__c)).getPaymentTypeToMediaLabMap();
            paymentTypeToMediaLabMap = (new BillSimpleHelp(shopCode)).getPaymentTypeToMediaLabMap();
            // 2015/10/28 多店舗機能対応 END
            payProdAmoutMap = new map<Id, Tran1__c>();
            payProdAmoutIdList = new list<Id>();
            // 2015/12/18 会計支払情報は分割情報として、表示できる BEGIN
            // 支払明細のグループNoと一致する場合、支払情報は取得する
            // Group No指定がある場合
            //if (!CommUtils.isBlank(groupNo)) {
                // 対象明細のメディア種別:クーポン/値引・割引券
                Set<String> mediaTypes = new Set<String>();
                mediaTypes.add(CommConst.MEDIA_TYPE_CD_11);
                mediaTypes.add(CommConst.MEDIA_TYPE_CD_12);
                /*
                // 会計支払情報明細を取得、設定する
                for (TTend__c ttend : [select PayProductRef__c
                                            ,PayProductRef__r.PaymentType__c
                                            ,PayProductRef__r.Name
                                            ,PayProductRef__r.ProductEnName__c
                                            ,Field20__c
                                         From TTend__c where Field1__c in :accIdSet 
                                            And SplitGroupNo__c =:groupNo
                                            // 2016/01/11 ポイント、値引以外の支払メデイアも明細に表示、グループNo登録可能対応 BEGIN
                                            //and field2__c in :mediaTypes
                                            // 2016/01/11 ポイント、値引以外の支払メデイアも明細に表示、グループNo登録可能対応 END
                                         Order By SplitGroupNo__c, RelAccount__r.Name, Name ]) {*/
                 for (TTend__c ttend : tendRsLst) {
                    // Ttend -> Tran
                    Tran1__c tranItem = new Tran1__c(
                         PayProductRef__c = ttend.PayProductRef__c
                        ,PayProductRef__r = ttend.PayProductRef__r
                        // 2020/10/26 「明細分割」のタブから印刷を行おうとすると表示が元の商品名のままになってしまうの不具合改修 WSQ BEGIN
                        ,Field5__c = ttend.PayProductName__c
                        // 2020/10/26 「明細分割」のタブから印刷を行おうとすると表示が元の商品名のままになってしまうの不具合改修 WSQ END
                    );
                    // 2019/10/30 会計画面に入力した金額と、明細分割した際の金額が違う修正 WGCH BEGIN
                    // decimal varItemAmount = CommUtils.nullToZero(ttend.Field20__c);
                    decimal varItemAmount = CommUtils.nullToZero(ttend.Field19__c);
                    // 2019/10/30 会計画面に入力した金額と、明細分割した際の金額が違う修正 WGCH END
                    groupTranPayInfo(tranItem, varItemAmount, paymentTypeToMediaLabMap);
                    // 2016/01/11 ポイント、値引以外の支払メデイアも明細に表示、グループNo登録可能対応 BEGIN
                    isHaveTtendPayInfo = true;
                    // 2016/01/11 ポイント、値引以外の支払メデイアも明細に表示、グループNo登録可能対応 END
                    // 2017/05/11 明細印刷済み識別機能追加 BEGIN
                    outputTtendIdLst.add(ttend.Id);
                    // 2017/05/11 明細印刷済み識別機能追加 END
                }
            //}
            // 2015/12/18 会計支払情報は分割情報として、表示できる END
        }
        // 2016/03/31 サビース料金は明細として、請求書に表示の対応 BEGIN
        gServiceOuputFlg = ShopInfoUtil.isShowServiceCharge(shopCode);
        // 2017/07/20 サビース料税別区分 zyz BEGIN
        gserviceNoTaxFlg = ShopInfoUtil.isServiceChargeIsNoTax(shopCode);
        // 2017/07/20 サビース料税別区分 zyz END
        // 2016/03/31 サビース料金は明細として、請求書に表示の対応 END
        // 2016/04/08 サビース料金は明細として、請求書に表示の対応[サービス料表示モード２] BEGIN
        String serviceOutputDiv = ShopInfoUtil.getShowServiceChargeMode(shopCode);
        gIsServieModeOuter = serviceOutputDiv == ShopInfoUtil.SERVICE_CHARGE_MODE_OUTER;
        // 2016/04/08 サビース料金は明細として、請求書に表示の対応[サービス料表示モード２] END
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
        gIsServieModeInner = serviceOutputDiv == ShopInfoUtil.SERVICE_CHARGE_MODE_INNER;
        // 2019/07/30 軽減税率機能対応 WGCH END
        // 2019/04/30 増税仮対応 BY zyz BEGIN
        // 2019/05/31 増税仮BUG FIX WGCH BEGIN
		// CommLogicProcess.TaxIncMstInfo info = CommLogicProcess.getTaxIncMstInfo();
		// 2019/05/31 増税仮BUG FIX WGCH END
		// 增税商品的Id
		id taxIncMstId = !CommUtils.isBlank(info.taxIncMstId) ? info.taxIncMstId : null;
        // 2019/04/30 増税仮対応 BY zyz END
        //for(Tran1__c sobj : DataBase.query(tranQuery)) {
        for (Tran1__c sobj : tranRsLst) {
            // 前受付金の商品する場合
            if (sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_AR) {
                // 返金の場合、返金の金額は利用金額と加算して、店舗から出るの資産値
                if (BillSimpleHelp.isRefundItem(sobj.PaymentType__c)) {
                    amountRefundPrice += Math.abs(CommUtils.nullToZero(sobj.Field23__c));
                } else {
                    // 支払済の前受金情報
                    amoutARprice += CommUtils.nullToZero(sobj.Field23__c);
                }
                // 施設コードは１３，１４の場合、前受金は明細に非表示する
                if(FACILITY_CODE != '13' && FACILITY_CODE != '14' && FACILITY_CODE != '15'){
                    // 2013/09/23 前受付金の場合、明細に表示対応
                    TranItem item = new TranItem(sobj, tran.size()+1);
                    // 2014/07/28 施設コード２３，２４、３３，３４対応[前受け金明細は右側の預かり金額を表示する]
                    if(FACILITY_CODE == '23' || FACILITY_CODE == '24' || isNewModeType()){
                        item.isPaymentInfo = true;
                        item.isShowPrice = false;
                    }
                    // 2018/06/08 会計レシート印刷機能言語選択する WGCH BEGIN
                    // 英語の場合、英語名を再設定を行う
                    // if (isShowEnName) item.produceNm = sobj.Field7__r.ProductEnName__c;
                    if (isShowEnName && !CommUtils.isBlank(sobj.Field7__r.ProductEnName__c)) item.produceNm = sobj.Field7__r.ProductEnName__c;
                    // 2018/06/08 会計レシート印刷機能言語選択する WGCH END
                    // 新会計　会計書３，４，３３，３４の場合、画面に表示の順番でそのまま表示する
                    if (isNewModeTypeExt()) {
                        // 明細情報はMAPに格納する
                        locSortKeyMap.put(getSortKey(sobj, null,containsKeySet.size()), item);
                    } else {
                        tran.add(item);
                    }
                }
                continue;
            }
/* 20121005修正を行う（商品単価多目意味機能対応） */
            // 2015/10/27 課税、非課税混在明細対応するため BEGIN
            //Decimal unitPrice = CommUtils.nullToZero(sobj.Field20__c);  // 商品単価
            Decimal qty = CommUtils.nullToZero(sobj.Field21__c);
            // 2014/08/05 BugFix Begin
            //CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo();
            CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(sobj.UnitPriceDefKbCal__c));
            // 2014/08/05 BugFix End
            /* 2015/10/27 課税、非課税混在明細対応するため BEGIN
            priceInfo.process(unitPrice, qty , sobj.TaxRate__c, sobj.ServiceRate__c);
            */
            // 税率は0以上の場合、該当合計金額は課税対象です[商品本体の単価＊数量（税込）= 税込金額]
//            if(sobj.TaxRate__c > 0) amoutIncTaxprice += CommUtils.nullToZero(sobj.Field20__c) * CommUtils.nullToZero(sobj.Field21__c);
            // 2015/10/27 課税、非課税混在明細対応するため BEGIN
            // 2015/11/25 数量は０の場合、単価計算方式は「単価から税込単価に計算して、画面に表示する」BEGIN
            //Decimal priceIncTax = CommUtils.nullToZero(sobj.Field23__c) - CommUtils.nullToZero(sobj.SpecialTax__c);  
            Decimal unitPrice = 0;
            // 2019/07/30 軽減税率機能対応 WGCH BEGIN
            Decimal unitPriceEnd = 0;
            Decimal taxUnitPrice = 0;
            Decimal unitPriceExcServiceEnd = 0;
            Decimal unitPriceIncServiceEnd = 0;
            // 2019/07/30 軽減税率機能対応 WGCH END
            // 非課税明細が含める場合
            Decimal noTaxUnitPriceSum = 0;
            for (Tran1__c subItem : sobj.ParentTran1Ref__r) {
                noTaxUnitPriceSum += CommUtils.nullToZero(subItem.Field20__c);
            }
            // 2016/03/31 サビース料金は明細として、請求書に表示の対応 BEGIN
            Decimal noServiceUnitPrice = 0;
            // 2016/03/31 サビース料金は明細として、請求書に表示の対応 END
            // 元の単価から、税抜金額を外して、税込み金額を計算する
            Decimal incTaxUnitPrice = CommUtils.nullToZero(sobj.Field20__c) - noTaxUnitPriceSum;
            priceInfo.process(incTaxUnitPrice, qty , sobj.TaxRate__c, sobj.ServiceRate__c);
            // 2019/07/30 軽減税率機能対応 WGCH BEGIN
            if (isReducedTaxFlg) {
            	 if(planHeaderMap != null && planHeaderMap.containsKey(sobj.Id)) {
            	 	// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
            	 	// priceInfo = planHeaderMap.get(sobj.Id);
            	 	if(planBrkToHeaderCalFlg) priceInfo = planHeaderMap.get(sobj.Id);
            	 	// 2019/10/02 PlanHeader算法切换对应 WGCH END
            	 }
            	// 税抜き金額[税込、サビース料込]	
            	unitPriceEnd = priceInfo.unitPriceTax;
            	// 消费税金额
            	taxUnitPrice = priceInfo.priceTax;
            	if(gServiceOuputFlg){
            		// サービス料表示モード1
            		if(gIsServieModeInner){
            			// 防止重复集计
            			// 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH BEGIN
            			// if(sobj.ActionType__c != CommConst.PROD_ACTION_TYPE_PL){
            			// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
            			if(sobj.ActionType__c != CommConst.PROD_ACTION_TYPE_PL || (pBrkTranItemMap != null && !pBrkTranItemMap.containsKey(sobj.Id)) || !planBrkToHeaderCalFlg){
            			// 2019/10/02 PlanHeader算法切换对应 WGCH END
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
            		if(gIsServieModeOuter && (sobj.ActionType__c != CommConst.PROD_ACTION_TYPE_PL || (pBrkTranItemMap != null && !pBrkTranItemMap.containsKey(sobj.Id)) || !planBrkToHeaderCalFlg)){
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
            // 2016/03/31 サビース料金は明細として、請求書に表示の対応 BEGIN
            noServiceUnitPrice = priceInfo.unitPriceIncTax;
            // 2016/03/31 サビース料金は明細として、請求書に表示の対応 END
            Decimal onlyIncTaxPrice = priceInfo.priceIncTax;    // 非課税明細金額を抜いて、計算した税込金額
            if (noTaxUnitPriceSum > 0) {
                priceInfo.process(noTaxUnitPriceSum, qty , 0, sobj.ServiceRate__c);
                unitPrice += priceInfo.unitPriceTax;
                // 2016/03/31 サビース料金は明細として、請求書に表示の対応 BEGIN
                noServiceUnitPrice += priceInfo.unitPriceIncTax;
                // 2016/03/31 サビース料金は明細として、請求書に表示の対応 END
                if (gIsServieModeOuter) {
                    // 2017/07/20 サビース料税別区分 zyz BEGIN
                    if (gserviceNoTaxFlg) serviceAmount += priceInfo.priceServiceExcTax;
                    else 
                    // 2017/07/20 サビース料税別区分 zyz END
                    serviceAmount += priceInfo.priceService;
                }
            }
            // 2015/11/25 数量は０の場合、単価計算方式は「単価から税込単価に計算して、画面に表示する」END
            TranItem item = new TranItem(sobj, tran.size()+1);
            //if(sobj.TaxRate__c > 0) amoutIncTaxprice += priceInfo.priceIncTaxNoService;
            //if(sobj.TaxRate__c > 0) amoutIncTaxprice += priceInfo.priceIncTax;
            if(sobj.TaxRate__c > 0) amoutIncTaxprice += onlyIncTaxPrice;
            // 2019/04/30 増税仮対応 BY zyz BEGIN
            if(taxIncMstId == sobj.Field7__c && taxIncMstId != null)  taxIncMstTaxprice += unitPrice;
            // 2019/04/30 増税仮対応 BY zyz END
            // 商品単価（税込、サービス込）
            //item.unitPrice = priceInfo.unitPriceTax;
            item.unitPrice = unitPrice;
            // 2016/03/21 会計書にサビース料金額を出力機能の対応 BEGIN
            if (gServiceOuputFlg && sobj.ServiceRate__c > 0) {
                if (serviceOutputDiv == ShopInfoUtil.SERVICE_CHARGE_MODE_INNER) {
                    // サビース料なしの単価を取得する
                    item.unitPrice = noServiceUnitPrice;
                }
            }
            // 2018/07/27 宿泊税計算 WGCH BEGIN
            // 2019/07/30 軽減税率機能対応 WGCH BEGIN
            if(!isReducedTaxFlg){
            	map<string,CommLogicProcess.HotelTaxDefineInfo> hotelTaxDefMap = CommLogicProcess.getHotelTaxDefInstance();
            	if(!hotelTaxDefMap.isEmpty() && sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_RP) hotelTax += CommLogicProcess.getHotelTax(priceInfo.unitPriceIncServiceExcTax,hotelTaxDefMap.get(CommUtils.nullToBlank(shopCode)), false) * qty;
            	else if(!hotelTaxDefMap.isEmpty() && sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PL && pItemPriceMap.containsKey(sobj.Id)){
            		for(Decimal itemUnitPrice : pItemPriceMap.get(sobj.Id)){
            			priceInfo.process(itemUnitPrice, qty , sobj.TaxRate__c, sobj.ServiceRate__c);
            			hotelTax += CommLogicProcess.getHotelTax(priceInfo.unitPriceIncServiceExcTax,hotelTaxDefMap.get(CommUtils.nullToBlank(shopCode)), false) * qty;
            		}
            	}
            }
            // 2019/07/30 軽減税率機能対応 WGCH END
            // 2018/07/27 宿泊税計算 WGCH END
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
            		addDetailToMapFun(new TranItem(new Tran1__c(), item.rowNo), (priceInfo.unitPriceTax * qty));
            	}
            	// 2019/10/02 PlanHeader算法切换对应 WGCH END
            	else addDetailToMapFun(new TranItem(new Tran1__c(), item.rowNo), CommUtils.nullToZero(sobj.SpecialTax__c));
            	// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
            	if(planBrkToHeaderCalFlg && pBrkTranItemMap != null && pBrkTranItemMap.containsKey(sobj.Id)) {
            	// 2019/10/02 PlanHeader算法切换对应 WGCH END
            		for(TranItem brkItem : pBrkTranItemMap.get(sobj.Id)){
            			// 2019/09/15 部屋名が表示、会計書崩れる対応 BY zyz BEGIN
            			accountsName(CommUtils.nullToBLank(brkItem.produceNm),brkItem,roomNameSet);
            			// 2019/09/15 部屋名が表示、会計書崩れる対応 BY zyz END
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
            	// 2019/10/15 軽減税率機能-宿泊税単価に宿泊税含む对应 BEGIN
            	map<string,CommLogicProcess.HotelTaxDefineInfo> hotelTaxDefMap = CommLogicProcess.getHotelTaxDefInstance();
            	CommUtils.ProductInfo rpPriceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(sobj.UnitPriceDefKbCal__c));
            	if(!hotelTaxDefMap.isEmpty() && sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_RP){
            		rpPriceInfo.process(CommUtils.nullToZero(sobj.Field20__c), qty , sobj.TaxRate__c, sobj.ServiceRate__c);
            		hotelTax += CommLogicProcess.getHotelTax(rpPriceInfo.unitPriceIncServiceExcTax,hotelTaxDefMap.get(CommUtils.nullToBlank(shopCode)), false) * qty;
            	} else if(!hotelTaxDefMap.isEmpty() && sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PL && pItemPriceMap.containsKey(sobj.Id)){
            		for(Decimal itemUnitPrice : pItemPriceMap.get(sobj.Id)){
            			rpPriceInfo.process(itemUnitPrice, qty , sobj.TaxRate__c, sobj.ServiceRate__c);
            			hotelTax += CommLogicProcess.getHotelTax(rpPriceInfo.unitPriceIncServiceExcTax,hotelTaxDefMap.get(CommUtils.nullToBlank(shopCode)), false) * qty;
            		}
            	}
            	// 2019/10/15 軽減税率機能-宿泊税単価に宿泊税含む对应 END
            }
            // 2019/07/30 軽減税率機能対応 WGCH END
            // 2016/03/21 会計書にサビース料金額を出力機能の対応 END
            // 2015/10/27 課税、非課税混在明細対応するため END
            // 2018/06/08 会計レシート印刷機能言語選択する WGCH BEGIN
            // 英語の場合、英語名を再設定を行う
            // if (isShowEnName) item.produceNm = sobj.Field7__r.ProductEnName__c;
            if (isShowEnName && !CommUtils.isBlank(sobj.Field7__r.ProductEnName__c)) item.produceNm = sobj.Field7__r.ProductEnName__c;
            // 2018/06/08 会計レシート印刷機能言語選択する WGCH END
            // 2017/11/02 会計書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
            // 2019/09/15 部屋名が表示、会計書崩れる対応 BY zyz BEGIN
            accountsName(CommUtils.nullToBLank(item.produceNm),item,roomNameSet);
            // 2019/09/15 部屋名が表示、会計書崩れる対応 BY zyz END
            // 2017/11/02 会計書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
            // 新会計　かつ　会計書３、４、３３、３４の場合、画面に表示の順番でそのまま表示する
            if (isNewModeTypeExt()) {
                // 明細情報はMAPに格納する
                locSortKeyMap.put(getSortKey(sobj, null,containsKeySet.size()), item);
            } else {
                tran.add(item);
            }
            // 2013/01/27 ADD/EDIT
            // 該当明細行の利用金額（税込み＋特別税）
            //Decimal varItemAmount = CommUtils.nullToZero(priceInfo.priceIncTax) + CommUtils.nullToZero(sobj.SpecialTax__c);
            Decimal varItemAmount = CommUtils.nullToZero(sobj.Field23__c);
            // 総金額合計計算
            //amoutAllMoneyDetail += priceInfo.priceIncTax;
            // 特別税計算合計
            //amoutIncSpecialPriceDetail += CommUtils.nullToZero(sobj.SpecialTax__c);
            // 総金額合計計算
            amoutAllMoney += varItemAmount;
            // 特別税計算合計
            amoutIncSpecialPrice += CommUtils.nullToZero(sobj.SpecialTax__c);
            
            // 2015/04/10 分割の場合、明細の支払メデイア種別で集計する BEGIN
            if (isGroupShowFlg) {
                // 2015/12/18 会計支払情報は分割情報として、表示できる BEGIN
                // 2016/01/11 ポイント、値引以外の支払メデイアも明細に表示、グループNo登録可能対応 BEGIN
                // 支払明細情報はグループに登録される場合、会計明細の支払メデイア情報をクリアする
                if (!isHaveTtendPayInfo)
                groupTranPayInfo(sobj, varItemAmount, paymentTypeToMediaLabMap);
                // 2016/01/11 ポイント、値引以外の支払メデイアも明細に表示、グループNo登録可能対応 END
                /*
                // 明細に支払メデイアを設定されている場合、メデイア集計金額を計算する
                if (sobj.PayProductRef__c != null) {
                    
                    // 該当支払商品の支払種別により、会計メデイア金額合計
                    String mediaName = paymentTypeToMediaLabMap.get(sobj.PayProductRef__r.PaymentType__c);
                    // 現金[金額＋特別税]
                    if (mediaName == CommConst.MEDIA_TYPE_01) {
                        amoutAllCash += varItemAmount;
                        amoutAllCashPay += varItemAmount;
                    }
                    // クレジット計(税込)[金額＋特別税]
                    else if (mediaName == CommConst.MEDIA_TYPE_02) {
                        amoutAllCredit += varItemAmount;
                        amoutAllCreditPay += varItemAmount;
                    }
                    // 掛計(税込)[金額＋特別税]
                    else if (mediaName == CommConst.MEDIA_TYPE_03) {
                        amoutAllMultiply += varItemAmount;
                        amoutAllMultiplyPay += varItemAmount;
                    }
                    // クーポン計(税込)[金額＋特別税]
                    else if (mediaName == CommConst.MEDIA_TYPE_11) {
                        amoutAllCoupon += varItemAmount;
                        amoutAllCouponPay += varItemAmount;
                    }
                    // 割引金額[金額＋特別税]
                    else if (mediaName == CommConst.MEDIA_TYPE_12) {
                        amountAllDiscount += varItemAmount;
                        amountAllDiscountPay += varItemAmount;
                    }
                    // 予約金
                    else if (mediaName == CommConst.MEDIA_TYPE_21) {
                        amoutAllSubscription += varItemAmount;
                        amoutAllSubscriptionPay += varItemAmount;
                    }
                    
                    // 施設コードは３３と３４の場合、支払メデイアの会計商品単位で、支払明細は会計書に表示を行う
                    if (isNewModeType()) {
                        if (!payProdAmoutMap.containsKey(sobj.PayProductRef__c)) {
                            payProdAmoutMap.put(sobj.PayProductRef__c,
                                     new Tran1__c(
                                           Field5__c = (isShowEnName == true ? sobj.PayProductRef__r.ProductEnName__c : sobj.PayProductRef__r.Name),
                                           Field20__c = String.valueOf(0),
                                           Field21__c = '1') );
                            payProdAmoutIdList.add(sobj.PayProductRef__c);
                        }
                        // 金額合計を加算を行う
                        Decimal orgPayAmout = CommUtils.nullToZero(payProdAmoutMap.get(sobj.PayProductRef__c).Field20__c);
                        payProdAmoutMap.get(sobj.PayProductRef__c).Field20__c = CommUtils.nullToBLank( orgPayAmout + varItemAmount);
                    }
                }*/
        // 2015/12/18 会計支払情報は分割情報として、表示できる END
            }
        // 2015/04/10 分割の場合、明細の支払メデイア種別で集計する END
        }
        // 新会計かつ会計書３、４、３３、３４の場合、画面に表示の順番でそのまま表示する
        if (isNewModeTypeExt()) {
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
                if (item.specialTax > 0 && isNewModeType()) {
                    // 宿泊税は３３．３４のみ、詳細に表示する
                    // 宿泊税明細情報を設定する
                    TranItem specItem = new TranItem(new Tran1__c(
                               Field5__c = (isShowEnName == true ? 'Accommodation Tax' : '宿泊税'),
                               Field20__c = String.valueOf(item.specialTax),
                               Field21__c = '1',
                               // 2019/07/30 軽減税率機能対応 WGCH BEGIN
                               RowNo__c = isReducedTaxFlg ? rowNoEnd : (tran.size() + 1)),
                               isReducedTaxFlg ? rowNoEnd : (tran.size()+1));
                               rowNoEnd ++;
                               // 2019/07/30 軽減税率機能対応 WGCH END
                    // 利用日個別設定
                    specItem.usedDate = item.usedDate;
                    // 2018/10/07 会計書の明細にそれぞれの部屋名が表記できる改善 WGCH BEGIN
                    specItem.roomName = item.roomName;
                    // 2018/10/07 会計書の明細にそれぞれの部屋名が表記できる改善 WGCH END
                    tran.add(specItem);
                }
            }
        }

        // 2013/10/17 金券情報を追加対応
        if (!goldNoteTran.isEmpty()) {
            for (TranItem item : goldNoteTran) {
            	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
                item.rowNo = isReducedTaxFlg ? rowNoEnd : (tran.size() + 1);
                rowNoEnd ++;
                // 2019/07/30 軽減税率機能対応 WGCH END
                tran.add(item);
            }
        }
        // 宿泊税情報設定
        if (!isNewModeType()) {
            if (amoutIncSpecialPrice > 0) {
                tran.add(new TranItem(new Tran1__c(
                                           Field5__c = (isShowEnName == true ? 'Accommodation Tax' : '宿泊税'),
                                           Field20__c = String.valueOf(amoutIncSpecialPrice),
                                           Field21__c = '1',
                                           // 2019/07/30 軽減税率機能対応 WGCH BEGIN
                                           RowNo__c = isReducedTaxFlg ? rowNoEnd : (tran.size() + 1)),
                                           isReducedTaxFlg ? rowNoEnd : (tran.size()+1)));
                                           rowNoEnd ++;
                                           // 2019/07/30 軽減税率機能対応 WGCH END
            }
        }
        /* 
        // 支払金額情報を表示する[TODO:１３と１４、金券などの情報はまだ表示しますか]
        if( FACILITY_CODE == '13' || FACILITY_CODE == '14' ||
            FACILITY_CODE == '15' ||
            FACILITY_CODE == '23' || FACILITY_CODE == '24'){
            setMediaPayInfo();
        }
        */
        // 33/34 && 分割の場合
        if (isGroupShowFlg && isNewModeType()) {
            setMediaPayInfo2();
        }
        // 2016/03/31 会計書にサビース料金額を出力機能の対応 BEGIN
        if (FACILITY_CODE == '33' || FACILITY_CODE == '34' || FACILITY_CODE == '35' || FACILITY_CODE == '36') {
            if (gServiceOuputFlg && serviceOutputDiv == ShopInfoUtil.SERVICE_CHARGE_MODE_INNER) setServiceDetailInfo();
        }
        // 2016/03/31 会計書にサビース料金額を出力機能の対応 END
        //if ((advancesReceivedChk || prePaymentFlgSet.contains(FACILITY_CODE)) && amoutARprice > 0 ) {
        /*
        if (amoutARprice > 0 ) {
            tran.add(new TranItem(new Tran1__c(
                                       Field5__c = (isShowEnName == true ? 'PrePayment' : '前受金'),
                                       Field20__c = String.valueOf(amoutARprice),
                                       Field21__c  = '1',
                                       RowNo__c = tran.size() + 1),
                                       tran.size()+1));
        }*/
        // 改ページ情報を設定する
        // 改ページ処理機能初期化
        // 2016/07/12 領収書出力する/しない制御追加と領収金額に内税金額を表示追加する BEGIN
        Integer nextPgBreakRsNum = PAGE_NEXTPG_BREAK_RSNUM;
        Integer breakNum = PAGE_FIRSTPG_BREAK_RSNUM;
        if ((FACILITY_CODE == '33' || FACILITY_CODE == '34') && noreceipt) {
            breakNum += 10;
            nextPgBreakRsNum += 10;
        }
        // 2016/07/12 領収書出力する/しない制御追加と領収金額に内税金額を表示追加する END
        allPageList = new List<OnePage>();
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
        if (isReducedTaxFlg && taxRowDataMap != null) processSumInfo();
        // 2019/08/15 会計書1枚目に合計が出る対応 BY zyz BEGIN
        Integer reducedTaxInt = 0;
        // 2019/08/15 会計書1枚目に合計が出る対応 BY zyz END
        // 根据合计板块的行数 与 总行数合并
        if(isReducedTaxFlg){
        	// 2019/10/30 消費税対象、値引行非表示の機能機能対応 WGCH BEGIN
        	/*
        	breakNum += 1; // 原有消费税行
        	if(taxRowDataMap != null){
				breakNum -= taxRowDataMap.keySet().Size(); // 消费税对象行
				nextPgBreakRsNum -= taxRowDataMap.keySet().Size(); // 消费税对象行
				// 合计行
				breakNum -= 1;
        		nextPgBreakRsNum -= 1;
				// 2019/08/15 会計書1枚目に合計が出る対応 BY zyz BEGIN
        		reducedTaxInt = taxRowDataMap.keySet().Size();
        		// 2019/08/15 会計書1枚目に合計が出る対応 BY zyz END
        	}
        	// 2019/10/30 消費税対象、値引行非表示の機能機能対応 WGCH BEGIN
        	// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
        	if(disRowDataLst != null) breakNum -= disRowDataLst.Size() + 1;
        	// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
        	if((disRowData.disUnitPriceSum + disRowData.disTaxAmountSum ) != 0) {
        		breakNum -= 1;
        		nextPgBreakRsNum -= 1;
        	}
        	*/
        	if(taxRowDataMap != null){
        		// 2019/08/15 会計書1枚目に合計が出る対応 BY zyz BEGIN
        		reducedTaxInt = taxRowDataMap.keySet().Size();
        		// 2019/08/15 会計書1枚目に合計が出る対応 BY zyz END
        	}
        	// 2019/10/30 会計書1枚目に合計が出る対応_bug対応 BY zyz BEGIN
        	if(disRowDataLst != null) reducedTaxInt += disRowDataLst.Size();
        	// 2019/10/30 会計書1枚目に合計が出る対応_bug対応 BY zyz END
        	// 获取轻减税率后最终多出来的行数
        	Integer rowBreakNumEnd = CommLogicProcess.getRowBreakNumEnd(comSum);
        	breakNum -= rowBreakNumEnd;
        	nextPgBreakRsNum -= rowBreakNumEnd;
        	// 2019/10/30 消費税対象、値引行非表示の機能機能対応 WGCH END
        	// 2019/10/28 对应PDF显示每页下方空白小进行调整 BY zyz BEGIN
        	breakNum -=1;
        	nextPgBreakRsNum -=1;
        	// 2019/10/28 对应PDF显示每页下方空白小进行调整 BY zyz END
        }
        // 2019/07/30 軽減税率機能対応 WGCH END
        //Integer breakNum = PAGE_FIRSTPG_BREAK_RSNUM;
        // 2017/11/02 会計書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
        Integer lineNum = 0;	// 记录最后一页计算空白格
        Integer linesNum = 0;	// 计算增加行数值
        // 2017/11/02 会計書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
        // 2019/08/15 会計書1枚目に合計が出る対応 BY zyz BEGIN
        // 原行数记忆
        Integer breakNumMoth = breakNum;
        Integer nextPgBreakRsNumMoth = nextPgBreakRsNum;
        allAmountShowType = CommConst.APPOPTION_ACCOUNTPDF_POSITION;
        // 2019/08/15 会計書1枚目に合計が出る対応 BY zyz END
        // 2019/11/15 PDF性能优化对应 WGCH BEGIN
        isSplitLineShowFlg = CommConst.ACCOUNT_SPLITLINE_FLG;
        // 2019/11/15 PDF性能优化对应 WGCH END
        for (Integer index = 0; index < tran.size(); index++) {
            // 2019/08/15 会計書1枚目に合計が出る対応 BY zyz BEGIN
            if( allAmountShowType != '1' && (allPageList.size() == 0 || allPageList.size() == 1) && (FACILITY_CODE == '33' || FACILITY_CODE == '34' || FACILITY_CODE == '35' || FACILITY_CODE == '36')){
            	if(allAmountShowType == '2' && (FACILITY_CODE == '33' || FACILITY_CODE == '35')) breakNum = 37;
            	if(allAmountShowType == '2' && (FACILITY_CODE == '34' || FACILITY_CODE == '36')) breakNum = 47;
            	nextPgBreakRsNum = nextPgBreakRsNumMoth;
            } else if( allAmountShowType != '1' && (FACILITY_CODE == '33' || FACILITY_CODE == '35')) {
            	nextPgBreakRsNum = 37;
            } else if( allAmountShowType != '1' && (FACILITY_CODE == '34' || FACILITY_CODE == '36')) {
            	nextPgBreakRsNum = 47;
            }
            // 2019/08/15 会計書1枚目に合計が出る対応 BY zyz END
            // 2017/11/02 会計書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
            lineNum += CommUtils.nullToZero(tran[index].proNum);
            linesNum += CommUtils.nullToZero(tran[index].proNum);
            Integer breakLine = index - (allPageList.isEmpty() ? 0 : 1) * (breakNum -linesNum) - (allPageList.size() > 1 ? allPageList.size() -1 : 0 ) * nextPgBreakRsNum;// + lineNum;
            // 改ページする場合
            if(breakLine >= 0){
                lineNum = CommUtils.nullToZero(tran[index].proNum);
                if(index != 0 && CommUtils.nullToZero(tran[index].proNum) != 0) linesNum += CommUtils.nullToZero(tran[index].proNum)-breakLine;
                // 补全每页的空白行
                if(allPageList.size() > 0){
                	OnePage onePgblank = allPageList[allPageList.size() - 1];
	                for (integer i=0; i < (lineNum -breakLine); i++) {
	                    onePgblank.addItem(new TranItem(new Tran1__c(), null));
	                }
                }
            	// 2017/11/02 会計書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
                OnePage onePg = new OnePage();
                // 2019/11/15 PDF性能优化对应 WGCH BEGIN
                // 表示每页都显示总金额和领收证
                if(allAmountShowType == '1') {
                	onePg.isShowTotalFlg = '';
                	onePg.isShowreceiptFlg = '';
                }
                // 2019/11/15 PDF性能优化对应 WGCH END
                onePg.addItem(tran[index]);
                allPageList.add(onePg);
                // ページ数を設定する
                onePg.currPages = allPageList.size();
            } else {
                OnePage onePg = allPageList[allPageList.size() - 1];
                onePg.addItem(tran[index]);
            }
        }
        // 2019/11/15 PDF性能优化对应 WGCH BEGIN
        if(allPageList.size() > 1 && allAmountShowType != '1'){
        	if(FACILITY_CODE == '33' || FACILITY_CODE == '35') nextPgBreakRsNum = 37;
        	else if(FACILITY_CODE == '34' || FACILITY_CODE == '36') nextPgBreakRsNum = 47;
        }
		// 2019/11/15 PDF性能优化对应 WGCH END
        Integer dumyLen = 0;
        OnePage dumyPage = null;
        // 明細データが非存在する場合
        if (allPageList.isEmpty()) {
            // だみデータ作成件数
            dumyLen = breakNum;
            dumyPage = new OnePage();
            allPageList.add(dumyPage);
        }
        // 全部データは一ページ場合、空白行を追加する
        /*
        if (allPageList.size() == 1) {
            dumyLen = breakNum - allPageList[0].onePageList.size();
            dumyPage = allPageList[0];
        }*/
        if (allPageList.size() > 1) {
            breakNum = nextPgBreakRsNum;
        }
        Integer lastIndex = allPageList.size() - 1;
        // 2017/11/02 会計書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
        dumyLen = breakNum - allPageList[lastIndex].onePageList.size() - lineNum;
        dumyPage = allPageList[lastIndex];
        // 2017/11/02 会計書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
        // 2019/08/15 会計書1枚目に合計が出る対応 BY zyz BEGIN
        if(allAmountShowType == '2'){
        	dumyLen -= reducedTaxInt;
        	// 2019/11/15 PDF性能优化对应 WGCH BEGIN
        	isSplitLineShowFlg = false;
        	// 2019/11/15 PDF性能优化对应 WGCH END
        	// 領収書不显示处理
        	if(noreceipt && dumyLen >= 9 && dumyLen < 19){
	        	// 2019/11/15 PDF性能优化对应 WGCH BEGIN
	        	// 只有第一页显示总金额和領収書
	        	allPageList[lastIndex].isShowTotalFlg = '';
	        	// 2019/11/15 PDF性能优化对应 WGCH END
        		dumyPage.isAmountShow = true;
        		dumyLen -= 9;
        for (integer i=0; i < dumyLen; i++) {
          dumyPage.onePageList.add(new TranItem(new Tran1__c(), null));
		        }
		    // 領収書显示处理
        	} else if(dumyLen < 19){
        		if(FACILITY_CODE == '33' || FACILITY_CODE == '34'){
	        		Boolean demyFlg = true;
		        	if(dumyLen >= 9 && tran.size() != 0){
		        		// 2019/11/15 PDF性能优化对应 WGCH BEGIN
		        		// 只有第一页显示总金额和領収書
		        		dumyPage.isShowTotalFlg = '';
		        		// 2019/11/15 PDF性能优化对应 WGCH END
		        		dumyPage.isAmountShow = true;
		        		demyFlg = false;
		        		dumyLen -= 9;
		        	}
			        for (integer i=0; i < dumyLen; i++) {
			          dumyPage.onePageList.add(new TranItem(new Tran1__c(), null));
			        }
			        if(tran.size() != 0){
		            	dumyPage = new OnePage();
		            	// 2019/11/15 PDF性能优化对应 WGCH BEGIN
		            	if(demyFlg) {
		            		dumyPage.isAmountShow = true;
		            		dumyPage.isShowTotalFlg = '';
		            	}
		            	dumyPage.isShowreceiptFlg = '';
		            	// 2019/11/15 PDF性能优化对应 WGCH END
		            	allPageList.add(dumyPage);
		            	dumyPage.currPages = allPageList.size();
			        }
        		} else if(FACILITY_CODE == '35' || FACILITY_CODE == '36'){
        			if(dumyLen < 9){
				        for (integer i=0; i < dumyLen; i++) {
				          dumyPage.onePageList.add(new TranItem(new Tran1__c(), null));
				        }
				        if(tran.size() != 0){
			            	dumyPage = new OnePage();
			            	// 2019/11/15 PDF性能优化对应 WGCH BEGIN
			            	dumyPage.isShowTotalFlg = '';
			            	// 2019/11/15 PDF性能优化对应 WGCH END
			            	dumyPage.isAmountShow = true;
			            	allPageList.add(dumyPage);
			            	dumyPage.currPages = allPageList.size();
				        }
        			}else {
        				// 2019/11/15 PDF性能优化对应 WGCH BEGIN
        				dumyPage.isShowTotalFlg = '';
        				// 2019/11/15 PDF性能优化对应 WGCH END
        				dumyPage.isAmountShow = true;
        			}
        		}
        	} else {
        		// 2019/11/15 PDF性能优化对应 WGCH BEGIN
        		// 只有第一页显示总金额和領収書
        		allPageList[lastIndex].isShowTotalFlg = '';
        		allPageList[lastIndex].isShowreceiptFlg = '';
        		// 2019/11/15 PDF性能优化对应 WGCH END
        		dumyPage.isAmountShow = true;
        	}
        } else if(allAmountShowType == '3') {
        	// 2019/11/15 PDF性能优化对应 WGCH BEGIN
        	// 只有第一页显示总金额和領収書
        	allPageList[0].isShowTotalFlg = '';
        	allPageList[0].isShowreceiptFlg = '';
        	// 2019/11/15 PDF性能优化对应 WGCH END
        	dumyLen -= reducedTaxInt;
	        for (integer i=0; i < dumyLen; i++) {
	          dumyPage.onePageList.add(new TranItem(new Tran1__c(), null));
	        }
        } else if(allAmountShowType == '1') {
        	// 2019/11/15 PDF性能优化对应 WGCH BEGIN
        	// 空数据，显示总金额和領収書
        	allPageList[0].isShowTotalFlg = '';
        	allPageList[0].isShowreceiptFlg = '';
        	// 2019/11/15 PDF性能优化对应 WGCH END
	        for (integer i=0; i < dumyLen; i++) {
	          dumyPage.onePageList.add(new TranItem(new Tran1__c(), null));
	        }
        }
        // 2019/08/15 会計書1枚目に合計が出る対応 BY zyz END
        // Header Pdf 情報を設定する[宿泊場合、設定を行う]
        //if (account[0].Relreserve__c != null && account[0].Relreserve__r.RecordTypeId == CommLogicProcess.getLeadBookingRecType())
        // 2015/05/05 現在に選べる会計書の関連予約のHeader情報を設定する
        //if (account[0].Relreserve__c != null)
        //  this.setHeaderInfo(account[0].Relreserve__c);
        // 2017/07/27 WGCH 部屋単位の泊数と到着日、出発日表示対応 BEGIN
        //if (singelAccount.Relreserve__c != null)
        //    this.setHeaderInfo(singelAccount.Relreserve__c, leadIdSet);
        // 2017/07/27 WGCH 部屋単位の泊数と到着日、出発日表示対応 END
        // 施設コード２３，２４の場合、内税英語文言表示対応
        // 2016/03/21 施設コード２３，２４、３３，３４の場合、内税英語文言表示対応 BEGIN
        //if (FACILITY_CODE == '23' || FACILITY_CODE == '24' ) {
        /*
        if (FACILITY_CODE == '23' || FACILITY_CODE == '24' || FACILITY_CODE == '33' || FACILITY_CODE == '34' || FACILITY_CODE == '35' || FACILITY_CODE == '36') {
        // 2016/03/21 施設コード２３，２４、３３，３４の場合、内税英語文言表示対応 END
            // 2014/07/30 内消費税表示文言取得
        // 2015/10/28 多店舗機能対応 BEGIN
            // String shopCode = UserUtil.CurrentUser.ShopCode__c;
        // 2015/10/28 多店舗機能対応 END
            taxEnglishLabel = ShopInfoUtil.getTaxEnglishLabel(shopCode);
        }*/
    }
    // 2015/12/18 会計支払情報は分割情報として、表示できる BEGIN
    // 会計支払の支払金額は合計する
    private void groupTranPayInfo(Tran1__c sobj, Decimal varItemAmount, Map<String, String> paymentTypeToMediaLabMap) {
                // 明細に支払メデイアを設定されている場合、メデイア集計金額を計算する
                if (sobj.PayProductRef__c != null) {

                    // 該当支払商品の支払種別により、会計メデイア金額合計
                    String mediaName = paymentTypeToMediaLabMap.get(sobj.PayProductRef__r.PaymentType__c);
                    // 現金[金額＋特別税]
                    if (mediaName == CommConst.MEDIA_TYPE_01) {
                        amoutAllCash += varItemAmount;
                        amoutAllCashPay += varItemAmount;
                    }
                    // クレジット計(税込)[金額＋特別税]
                    else if (mediaName == CommConst.MEDIA_TYPE_02) {
                        amoutAllCredit += varItemAmount;
                        amoutAllCreditPay += varItemAmount;
                    }
                    // 掛計(税込)[金額＋特別税]
                    else if (mediaName == CommConst.MEDIA_TYPE_03) {
                        amoutAllMultiply += varItemAmount;
                        amoutAllMultiplyPay += varItemAmount;
                    }
                    // クーポン計(税込)[金額＋特別税]
                    else if (mediaName == CommConst.MEDIA_TYPE_11) {
                        amoutAllCoupon += varItemAmount;
                        amoutAllCouponPay += varItemAmount;
                    }
                    // 割引金額[金額＋特別税]
                    else if (mediaName == CommConst.MEDIA_TYPE_12) {
                        amountAllDiscount += varItemAmount;
                        amountAllDiscountPay += varItemAmount;
                    }
                    // 予約金
                    else if (mediaName == CommConst.MEDIA_TYPE_21) {
                        amoutAllSubscription += varItemAmount;
                        amoutAllSubscriptionPay += varItemAmount;
                    }
                    // 2018/02/28 支払種別は「雑損」を作成したい WGCH BEGIN
                    else if(!CommUtils.isBlank(BillSimpleHelp.getMediaCodeByName(mediaName))){
                    	amoutCustomPayLst.add(new amoutCustomPay(varItemAmount));
                    }
                    // 2018/02/28 支払種別は「雑損」を作成したい WGCH END

                    // 施設コードは３３と３４の場合、支払メデイアの会計商品単位で、支払明細は会計書に表示を行う
                    if (isNewModeType()) {
                        if (!payProdAmoutMap.containsKey(sobj.PayProductRef__c)) {
                        	// 2020/10/26 「明細分割」のタブから印刷を行おうとすると表示が元の商品名のままになってしまうの不具合改修 WSQ BEGIN
       						String payProdName = sobj.Field5__c;
        					if (Commutils.isBlank(payProdName)) payProdName = sobj.PayProductRef__r.Name;
                        	// 2020/10/26 「明細分割」のタブから印刷を行おうとすると表示が元の商品名のままになってしまうの不具合改修 WSQ END
                            payProdAmoutMap.put(sobj.PayProductRef__c,
                                     new Tran1__c(
                                           // 2018/06/08 会計レシート印刷機能言語選択する WGCH BEGIN
                                           // 2020/10/26 「明細分割」のタブから印刷を行おうとすると表示が元の商品名のままになってしまうの不具合改修 WSQ BEGIN
                                           //Field5__c = (isShowEnName == true && !CommUtils.isBlank(sobj.PayProductRef__r.ProductEnName__c) ? sobj.PayProductRef__r.ProductEnName__c : sobj.PayProductRef__r.Name),
                                           Field5__c = (isShowEnName == true && !CommUtils.isBlank(sobj.PayProductRef__r.ProductEnName__c) ? sobj.PayProductRef__r.ProductEnName__c : payProdName),
                                           // 2020/10/26 「明細分割」のタブから印刷を行おうとすると表示が元の商品名のままになってしまうの不具合改修 WSQ END
                                           // 2018/06/08 会計レシート印刷機能言語選択する WGCH END
                                           Field20__c = String.valueOf(0),
                                           Field21__c = '1') );
                            payProdAmoutIdList.add(sobj.PayProductRef__c);
                        }
                        // 金額合計を加算を行う
                        Decimal orgPayAmout = CommUtils.nullToZero(payProdAmoutMap.get(sobj.PayProductRef__c).Field20__c);
                        payProdAmoutMap.get(sobj.PayProductRef__c).Field20__c = CommUtils.nullToBLank( orgPayAmout + varItemAmount);
                    }
                }
    }
    // 2015/12/18 会計支払情報は分割情報として、表示できる END
    // 2018/02/28 支払種別は「雑損」を作成したい WGCH BEGIN
    public List<AmoutCustomPay> amoutCustomPayLst;
    public class AmoutCustomPay{
    	public AmoutCustomPay(Decimal varItemAmount){
    		amoutAllCustom = varItemAmount;
    		amoutAllCustomPay = varItemAmount;
    	}
    	public AmoutCustomPay(Decimal amoutCustom, Decimal amoutCustomPay){
    		amoutAllCustom = amoutCustom;
    		amoutAllCustomPay = amoutCustomPay;
    	}
    	public Decimal amoutAllCustom;
    	public Decimal amoutAllCustomPay;
    }
    // 2018/02/28 支払種別は「雑損」を作成したい WGCH END
    // 新会計モードに切り替え判断ロジック
    private Boolean isNewModeType() {
        return (gLayoutNo == BillInputSwitchCtrl.BILL_LAYOUT_CODE_2  &&
                (FACILITY_CODE == '33' || FACILITY_CODE == '34' || FACILITY_CODE == '35' || FACILITY_CODE == '36'));
    }
    // 新規会計モード　かつ　新会計画面の明細並び順
    private Boolean isNewModeTypeExt() {
        return (gLayoutNo == BillInputSwitchCtrl.BILL_LAYOUT_CODE_2  &&
                (FACILITY_CODE == '3' || FACILITY_CODE == '4' || FACILITY_CODE == '33' || FACILITY_CODE == '34' || FACILITY_CODE == '35' || FACILITY_CODE == '36'));
    }
    // 表示の並び順KEYを作成する
    private String getSortKey(Tran1__c tran, TTend__c tend, Integer rooms) {
        // 予約なし（簡易会計）一括表示する場合、売上日_ROWNO_NAME
        if (singelAccount.Relreserve__c == null) {
            // 1(固定)_売上日_会計ID_４桁並び順NO(新会計画面から設定)_自動番号
            if (tran != null)   return '1_' + tran.RelAccount__r.Name + '_' + tran.Field1__c + '_' + CommUtils.paddingLeftZero(CommUtils.nullToZero(tran.RowNo__c),4) + '_' + tran.Name;
            if (tend != null)   return '1_' + tend.RelAccount__r.Name + '_' + tend.Field1__c + '_' + CommUtils.paddingLeftZero(CommUtils.nullToZero(tend.RowNo__c),4) + '_' +  tend.Name;
        } else {
            // 1(固定)_４桁並び順NO(新会計画面から設定)_売上日_自動番号
            //if (tran != null)     return '1_' + CommUtils.paddingLeftZero(CommUtils.nullToZero(tran.RowNo__c),4) + '_' + tran.RelAccount__r.Name + '_' + tran.Name;
            //if (tend != null)     return '1_' + CommUtils.paddingLeftZero(CommUtils.nullToZero(tend.RowNo__c),4) + '_' + tend.RelAccount__r.Name + '_' + tend.Name;
            // 1(固定)_４桁並び順NO(新会計画面から設定)_売上日_自動番号
            if (tran != null)   return '1_' + getSameRoomGroupKey(tran,null,(rooms>1)) + CommUtils.paddingLeftZero(CommUtils.nullToZero(tran.RowNo__c),4) + '_' + tran.RelAccount__r.Name + '_' + tran.Name;
            if (tend != null)   return '1_' + getSameRoomGroupKey(null,tend,(rooms>1)) + CommUtils.paddingLeftZero(CommUtils.nullToZero(tend.RowNo__c),4) + '_' + tend.RelAccount__r.Name + '_' + tend.Name;
        }
        return '';
    }
    private string getSameRoomGroupKey (Tran1__c tran, TTend__c tend, Boolean isMuliteRoomFlg) {
        String userDateStr = '';
        //if (!isMuliteRoomFlg) return userDateStr;
        Boolean isAccountReportSort = CommConst.APPOTION_ACCOUNT_SORT_VAL == CommConst.APPOTION_ACCOUNT_SORT_USEDATE;
        if (tran != null) {
            if (isAccountReportSort){ 
                Date useDate = (tran.UseDate__c == null ? tran.RelAccount__r.Salesday__c : tran.UseDate__c) ;
                userDateStr = DateTime.newInstance(useDate.Year(),useDate.month(),useDate.day()).format('yyyyMMdd') + '_';
                userDateStr += CommUtils.nullToBlank(tran.Field1__r.Relreserve__r.LeadIndexRef__c) + '_' + CommUtils.nullToBlank(tran.Field1__r.Relreserve__r.LeadIndexSubId__c) + '_' + CommUtils.nullToBlank(tran.Field1__r.Relreserve__r.RoomGroupNo__c) + '_';
            }
        } else if (tend != null) {
            if (isAccountReportSort) {
                Date useDate = (tend.UseDate__c == null ? tend.RelAccount__r.Salesday__c : tend.UseDate__c) ;
                userDateStr = DateTime.newInstance(useDate.Year(),useDate.month(),useDate.day()).format('yyyyMMdd') + '_';
                userDateStr += CommUtils.nullToBlank(tend.Field1__r.Relreserve__r.LeadIndexRef__c) + '_' + CommUtils.nullToBlank(tend.Field1__r.Relreserve__r.LeadIndexSubId__c) + '_' + CommUtils.nullToBlank(tend.Field1__r.Relreserve__r.RoomGroupNo__c) + '_';
            }   
        }
        return userDateStr;
    }
    // 会計支払情報は会計明細にて変換処理を行う
    private TranItem convertTtendToTranItem(Ttend__c ttend) {
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
        // 2018/06/08 会計レシート印刷機能言語選択する WGCH BEGIN
        if (isShowEnName == true && !CommUtils.isBlank(ttend.PayProductRef__r.ProductEnName__c)) payProdName = CommUtils.nullToBlank(ttend.PayProductRef__r.ProductEnName__c);
        // 2018/06/08 会計レシート印刷機能言語選択する WGCH END
        Tran1__c tran = new Tran1__c();
        tran.Field7__c = ttend.PayProductRef__c;    // 商品コード
        tran.ActionType__c = CommConst.PROD_ACTION_TYPE_PY; // 商品処理種別
        tran.PaymentType__c = ttend.PaymentType__c; // ;支払種別
        tran.Field5__c = payProdName;               //会計商品名
        tran.Field20__c = ttend.Field19__c;         // 単価 ←　預かり金額
        tran.Field23__c = ttend.Field19__c;         // 合計金額 ←　預かり金額
        tran.Field21__c = '1';                      // 数量１固定
        tran.TaxRate__c = null;                     // 消費税
        tran.ServiceRate__c = null;                 // サビース料
        tran.SpecialTax__c = 0;                     // 特別税
        tran.UseDate__c = ttend.UseDate__c;         // 利用日
        tran.RelAccount__c = ttend.RelAccount__c;   // 売上
        tran.Field1__c = ttend.Field1__c;           // 会計
        tran.RelAccount__r = ttend.RelAccount__r;   // 売上関連情報もコピー[Readonly注意が必要]
        TranItem item = new TranItem(tran, -1);
        // 預かり金額列に表示するため、フラグを設定する
        item.isPaymentInfo = true;
        item.isShowPrice = true;
        return item;
    }
    /**
    * 利用金額ー預かり金額の結果を格納する
    * 該当計算ロジックは新会計画面JSの関数「setupCalSumAmountPrice」を一致するが必要
    **/
    public Decimal requestAmount3{get{
        // 割引金額を取得する
        // 利用総金額
        Decimal remaindPayMoney = amoutAllMoney;
            
        // 支払
        Decimal requestAmountVal = 0;
        // 割引金額が存在する場合、優先で利用する
        if (amountAllDiscountPay > 0) {
            // 未支払金額は割引金額により、大きく場合、全額割引金額を使う
            if (remaindPayMoney >= amountAllDiscountPay) {
                remaindPayMoney = remaindPayMoney - amountAllDiscountPay;
            } 
            // 割引金額は全額支払できるの場合
            else {
                remaindPayMoney = 0;
            }
        }
// System.debug(loggingLevel.info,'remaindPayMoney='+remaindPayMoney);
// System.debug(loggingLevel.info,'amoutAllCouponPay='+amoutAllCouponPay);
// System.debug(loggingLevel.info,'coponManasFlg='+singelAccount.CouponReturnFlg__c);
        // クーポン支払金額が存在する場合
        if (amoutAllCoupon > 0) {
            // 起動の会計画面の[クーポン利用の返金]はONの場合
            boolean coponManasFlg = singelAccount.CouponReturnFlg__c;
            if (remaindPayMoney >= amoutAllCouponPay) {
                remaindPayMoney = remaindPayMoney - amoutAllCouponPay;
            } else {
                remaindPayMoney = coponManasFlg ? (remaindPayMoney - amoutAllCouponPay) : 0;
            }
        }
        // その以外の支払情報 = 現金 - 掛計 - クレジット - 予約金 - 前受金 + 返金
        remaindPayMoney = remaindPayMoney - amoutAllCashPay - amoutAllMultiplyPay - amoutAllCreditPay - amoutAllSubscriptionPay - CommUtils.nullToZero(amoutARprice) + CommUtils.nullToZero(amountRefundPrice);
        // 2018/02/28 支払種別は「雑損」を作成したい WGCH BEGIN
        for(AmoutCustomPay itemAmout : amoutCustomPayLst){
        	remaindPayMoney -= itemAmout.amoutAllCustomPay;
        }
        // 2018/02/28 支払種別は「雑損」を作成したい WGCH END
        return remaindPayMoney;
    }}
    /**
    * media支払情報を設定する
    * 施設コードは１３と１４する場合、起動起動する
    **/
    public Decimal requestAmount2{get; private set;}
    /* 2017/09/25 処理対象外 BEGIN
    private void setMediaPayInfo() {
            // 明細に前受金が存在　かつ　会計書は２３，２４の場合
            if (CommUtils.nullToZero(amoutARprice) > 0 &&  (FACILITY_CODE == '23' || FACILITY_CODE == '24')) {
                requestAmount2 = getRequestAmount();    
            } else {
                Decimal paymented = amoutAllCash + amoutAllMultiply + amoutAllCredit + amoutAllCouponPay + getAdvancesReceived() + amountAllDiscount;
                requestAmount2 = CommUtils.nullToZero(amoutAllMoney) - paymented;
            }
            String prefixMark = (FACILITY_CODE == '23' || FACILITY_CODE == '24') ? '' : '　';
            // 23と24に、利用日表示するため、下記売上情報を設定する
            RsvAccount__c rsvInf = (FACILITY_CODE == '23' || FACILITY_CODE == '24') ? singelAccount.frs__r : null;
            
            String constCash =  (FACILITY_CODE == '23' || FACILITY_CODE == '24') ? '現金払い' : '現計';
            String constCredit =  (FACILITY_CODE == '23' || FACILITY_CODE == '24') ? '売掛金' : '掛計';
            String constCard =  (FACILITY_CODE == '23' || FACILITY_CODE == '24') ? 'カード払い' : 'クレジット';
            // 支払Media非表示制御フラグ
            Boolean noshowMediaFlg = (FACILITY_CODE == '23' || FACILITY_CODE == '24') && (CommUtils.nullToZero(amoutARprice) > 0);
            
            // 現計/Cash
            if (amoutAllCash != 0 && noshowMediaFlg != true) {
                TranItem mediaInfo = new TranItem(
                                        new Tran1__c(
                                           RelAccount__r = rsvInf,
                                           //Field5__c = prefixMark + (isShowEnName == true ? 'Cash' : '現計'),
                                           Field5__c = prefixMark + (isShowEnName == true ? 'Cash' : constCash),
                                           Field20__c = CommUtils.nullToBlank(amoutAllCash),            // 単価
                                           Field21__c = '1',                                                                    // 数量
                                           RowNo__c = tran.size() + 1),
                                           tran.size() + 1);   
                mediaInfo.isPaymentInfo = true;
                mediaInfo.isShowPrice = false;
                tran.add(mediaInfo);
            }
            // 掛計/Credit
            if (amoutAllMultiply != 0 && noshowMediaFlg != true) {
                TranItem mediaInfo = new TranItem(
                                        new Tran1__c(
                                           RelAccount__r = rsvInf,
                                           //Field5__c = prefixMark + (isShowEnName == true ? 'Credit' : '掛計'),
                                           Field5__c = prefixMark + (isShowEnName == true ? 'Credit' : constCredit),
                                           Field20__c = CommUtils.nullToBlank(amoutAllMultiply),        // 単価
                                           Field21__c = '1',                                                                    // 数量
                                           RowNo__c = tran.size() + 1),
                                           tran.size() + 1);  
                mediaInfo.isPaymentInfo = true;
                mediaInfo.isShowPrice = false;
                tran.add(mediaInfo);
            }
            // クレジット/Card
            if (amoutAllCredit != 0 && noshowMediaFlg != true) {
                TranItem mediaInfo = new TranItem(
                                        new Tran1__c(
                                           RelAccount__r = rsvInf,
                                           //Field5__c = prefixMark + (isShowEnName == true ? 'Card' : 'クレジット'),
                                           Field5__c = prefixMark + (isShowEnName == true ? 'Card' : constCard),
                                           Field20__c = CommUtils.nullToBlank(amoutAllCredit),      // 単価
                                           Field21__c = '1',                                                                // 数量
                                           RowNo__c = tran.size() + 1),
                                           tran.size() + 1);  
                mediaInfo.isPaymentInfo = true;
                mediaInfo.isShowPrice = false;
                tran.add(mediaInfo);
            }
            // クーポン/Coupon
            if (amoutAllCouponPay != 0 && noshowMediaFlg != true) {
                TranItem mediaInfo = new TranItem(
                                        new Tran1__c(
                                           RelAccount__r = rsvInf,
                                           Field5__c = prefixMark + (isShowEnName == true ? 'Coupon' : 'クーポン'),
                                           Field20__c = CommUtils.nullToBlank(amoutAllCouponPay),   // 単価
                                           Field21__c = '1',                                                                        // 数量
                                           RowNo__c = tran.size() + 1),
                                           tran.size() + 1);
                mediaInfo.isPaymentInfo = true;
                mediaInfo.isShowPrice = false;
                tran.add(mediaInfo);
            }
            // 前受金/PrePayment
            if (getAdvancesReceived() != 0 && noshowMediaFlg != true) {
                TranItem mediaInfo = new TranItem(
                                        new Tran1__c(
                                           RelAccount__r = rsvInf,
                                           Field5__c = prefixMark + (isShowEnName == true ? 'PrePayment' : '前受金'),
                                           Field20__c = CommUtils.nullToBlank(getAdvancesReceived()),   // 単価
                                           Field21__c = '1',                                                                            // 数量
                                           RowNo__c = tran.size() + 1),
                                           tran.size() + 1);
                mediaInfo.isPaymentInfo = true;
                mediaInfo.isShowPrice = false;
                tran.add(mediaInfo);
            }
            // 値引割引額/Discount
            if (amountAllDiscountPay != 0 && noshowMediaFlg != true) {
                TranItem mediaInfo = new TranItem(
                                        new Tran1__c(
                                           RelAccount__r = rsvInf,
                                           Field5__c = prefixMark + (isShowEnName == true ? 'Discount' : '値引割引額'),
                                           Field20__c = CommUtils.nullToBlank(amountAllDiscountPay),        // 単価
                                           Field21__c = '1',                                                                    // 数量
                                           RowNo__c = tran.size() + 1),
                                           tran.size() + 1);
                mediaInfo.isPaymentInfo = true;
                mediaInfo.isShowPrice = false;
                tran.add(mediaInfo);
            }
    }*/
    /**
    * 明細分割の支払情報合計表示する
    **/
    private void setMediaPayInfo2() {
        RsvAccount__c rsvInf = singelAccount.frs__r;
        for (Id payId : payProdAmoutIdList) {
            Tran1__c payTran = payProdAmoutMap.get(payId);
            payTran.RelAccount__r = rsvInf;
            payTran.RowNo__c = tran.size() + 1;
            
            TranItem mediaInfo = new TranItem(payTran,tran.size() + 1);
            mediaInfo.isPaymentInfo = true;
            mediaInfo.isShowPrice = false;
            tran.add(mediaInfo);
        }
    }
    /**
    * 2016/03/31 会計書にサビース料金額を出力機能の対応
    **/
    private void setServiceDetailInfo() {
        // サビース料情報
        Decimal noServiceAmount = 0;
        // サビース料抜き合計金額
        for (TranItem item : tran) {
            if (item.isPaymentInfo) continue;
            // 2019/07/30 軽減税率機能対応 WGCH BEGIN
            if (item.pBrkDNFlg) continue;
            // 2019/07/30 軽減税率機能対応 WGCH END
            noServiceAmount += item.amount;
        }
        Decimal serviceRate = amoutAllMoney - noServiceAmount;
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
        if(isReducedTaxFlg) serviceRate = serviceAmountEnd;
        // 2019/07/30 軽減税率機能対応 WGCH END

        if (serviceRate > 0) {
            // 明細にサビース料情報を追加表示する
            TranItem serviceItem = new TranItem(new Tran1__c(
                       Field5__c = (isShowEnName == true ? 'Service Charge' : 'サービス料'),
                       Field20__c = String.valueOf(serviceRate),
                       Field21__c = '1',
                       // 2019/07/30 軽減税率機能対応 WGCH BEGIN
                       RowNo__c = isReducedTaxFlg ? rowNoEnd : (tran.size() + 1)),
                       isReducedTaxFlg ? rowNoEnd : (tran.size()+1));
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
    // 2017/07/20 サビース料税別区分 zyz END
    private Decimal serviceAmount = 0;
    public Decimal getServiceAmount(){
        if (gIsServieModeOuter) {
            // 2019/07/30 軽減税率機能対応 WGCH BEGIN
            if(isReducedTaxFlg) return serviceAmountEnd;
            // 2019/07/30 軽減税率機能対応 WGCH END
            return serviceAmount;
        } else return null;
    }
    // サビース料金は明細として、請求書に表示の対応[サービス料表示モード２] END
    /**
    * 発行日更新を行う
    **/
    // 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH BEGIN
    // public void extInitAction() {
    public PageReference extInitAction() {
    // 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH END
       
        // 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH BEGIN
        CommErrorPage pg = isLockAcc(ApexPages.currentPage().getParameters());
        if(pg.isBlankPageFlg) return pg.page;
        // 2017/01/16 請求書/会計書PDFファイルを自動保存対応 BEGIN
        // if (ApexPages.currentPage().getParameters().containsKey(PdfAutoSaveUtil.isCallFromAutoPdfKey)) return;
        if (ApexPages.currentPage().getParameters().containsKey(PdfAutoSaveUtil.isCallFromAutoPdfKey)) return null;
        // 2017/01/16 請求書/会計書PDFファイルを自動保存対応 END
        // 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH END
        // 発行日更新処理を行う[2013/01/15 ADD BEGIN]
        List<Id> accIdLst = new List<Id>();
        for (AccountAcount__c acc: account) {
            accIdLst.add(acc.Id);
            //acc.IssueDate__c = Date.today();
        }
        // 2013/10/21 会計書宛名、請求書宛名追加する
        if (!isGroupShowFlg) {
            if (isBulkPrint()) {
                // BULKIDから更新IDを取得する
                accIdLst.addAll(accIdSet);
                CommLogicProcess.writeLogInfo(accIdLst, null, null, null);
            }
            else CommLogicProcess.writeLogInfo(accIdLst, getAccountProviso(), getAccountName(), getCustomer());
        } else {
            // 会計明細分割の場合、ログは会計明細に書き込むする
            List<Id> tranIdLst = new List<Id>();
            // 2018/04/03 会計分割 WGCH BEGIN
            /*
            for (TranItem r : tran) {
                if (r.tranId != null) tranIdLst.add(r.tranId);
            }
            // 出力した会計明細ID
            if (outputTtendIdLst != null) tranIdLst.addAll(outputTtendIdLst);
            */
            for(OneRoomInfo oneInfo : bulkPrintInfoLst){
	            for (TranItem r : oneInfo.tran) {
	            	if (r.tranId != null) tranIdLst.add(r.tranId);
	            }
	            // 出力した会計明細ID
	            if (oneInfo.outputTtendIdLst != null) tranIdLst.addAll(oneInfo.outputTtendIdLst);
            }
            // 2018/04/03 会計分割 WGCH END
            CommLogicProcess.writeLogInfo(tranIdLst, getAccountProviso(), getAccountName(), getCustomer());
        }
        // [2013/01/15 ADD END]
        // 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH BEGIN
        return null;
        // 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH END
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
//System.debug(loggingLevel.info, 'account='+account);
        return account[0].name;
    }
    // get 請求書の宛名先名
    public String getAccountName() {
        /*
        String recpName = parMap.get('recpName');
        return CommUtils.isBlank(recpName) ? account[0].relaccount__r.Account.Name : recpName;
        */
        // パラメータは未設定する場合、直接会計データから設定情報を取得、設定を行う
        // 2018/04/03 会計分割 WGCH BEGIN
        // String recpName = parMap.containsKey('recpName') ? parMap.get('recpName') :
        // 2018/05/24 BugFix 未会計の場合、ビル一括印刷すると、お客様名が非表示の不具合改修
        String recpName = !CommUtils.isBlank(grpItem.recpNameStr) ? grpItem.recpNameStr : 
        // 2018/04/03 会計分割 WGCH END
                CommUtils.isBlank(singelAccount.AccountReceiptName__c) ?  CommUtils.nullToBlank(singelAccount.BillingCal__c)  :  singelAccount.AccountReceiptName__c;
        // 2020/01/30 宛名が一定文字数を超えた場合に自動改行する BY zyz BEGIN
        if(isAccountTitleNameFlg){
	        if(!CommUtils.isBlank(recpName)){
	        	Integer maxLen = 20;
	        	if (FACILITY_CODE == '34' ||FACILITY_CODE == '36') maxLen = 27;
	        	recpName = CommRepUtils.getPdfMaxShowStringNew(recpName ,2,maxLen);
	        }
        }
        // 2020/01/30 宛名が一定文字数を超えた場合に自動改行する BY zyz END
        return recpName;
        //return CommUtils.isBlank(recpName) ? CommUtils.nullToBlank(account[0].relaccount__r.Account.Name) : recpName;
    }
    //get 'お客様'
    public string getCustomer(){
        /*
        if(account.relaccount__c!=null){
            return account.relaccount__r.name;
        }else{
            return '　　　　　　　　　　';
        }*/
        /*
        String cuName = parMap.get('cuName');
        return (CommUtils.isBlank(cuName) ? '　' : cuName);*/
        // 2018/04/03 会計分割 WGCH BEGIN
        // String cuName = parMap.containsKey('cuName') ? parMap.get('cuName') : 
        // 2018/05/24 BugFix 未会計の場合、ビル一括印刷すると、お客様名が非表示の不具合改修
        String cuName = !CommUtils.isBlank(grpItem.cuNameStr) ? grpItem.cuNameStr : 
        // 2018/04/03 会計分割 WGCH END
                                    CommUtils.isBlank(singelAccount.AccountName__c) ?  CommUtils.nullToBlank(singelAccount.ContactName__c)  :  singelAccount.AccountName__c;
        // 2020/01/30 宛名が一定文字数を超えた場合に自動改行する BY zyz BEGIN
        // return (CommUtils.isBlank(cuName) ? '　' : cuName);
        if(isAccountTitleNameFlg){
	        if(!CommUtils.isBlank(cuName)){
	        	Integer maxLen = 23;
	        	if((FACILITY_CODE == '33' || FACILITY_CODE == '35') && isOldManModeFlg) maxLen = 17;
	        	else if (FACILITY_CODE == '34' ||FACILITY_CODE == '36') maxLen = 30;
	        	cuName = CommRepUtils.getPdfMaxShowStringNew(cuName ,2,maxLen);
	        }else cuName = '　';
        }
        return cuName;
        // 2020/01/30 宛名が一定文字数を超えた場合に自動改行する BY zyz END
    }
    // get 但し書き
    public String getAccountProviso() {
        // 2018/04/03 会計分割 WGCH BEGIN
        // String accountProviso = parMap.containsKey('accountProviso') ? CommUtils.nullToBlank(parMap.get('accountProviso')) : CommUtils.nullToBlank(singelAccount.AccountProviso__c); 
        // 2018/05/24 BugFix 未会計の場合、ビル一括印刷すると、お客様名が非表示の不具合改修
        String accountProviso = !CommUtils.isBlank(grpItem.accountProvisoStr) ? CommUtils.nullToBlank(grpItem.accountProvisoStr) : CommUtils.nullToBlank(singelAccount.AccountProviso__c); 
        // 2018/04/03 会計分割 WGCH END
        // 日本語文字最大２０文字、英字混在する場合、表示文字列は長く表示できるように改善
        //if (accountProviso.length() > 20) accountProviso = accountProviso.substring(0,20);
        Integer maxLen = 20;
        if (FACILITY_CODE == '4' || FACILITY_CODE == '9' || FACILITY_CODE == '14' || FACILITY_CODE == '24' || FACILITY_CODE == '34') maxLen = 24;
    	accountProviso = CommRepUtils.getPdfMaxShowStringNew(accountProviso,1,maxLen);
        return accountProviso;
    }

    //get '$売上計IV（税込）金額'
    public Decimal getCharge(){
        return amoutAllMoney;
        /*
        if ( account.Field151__c != null ) {
            //return putComma(string.valueof(account.Field151__c));
            return account.Field151__c;
        } else {
            return 0;
        }*/
    }
    // 請求金額設定：お客様消費総金額 - 割引 - ポイント及びクーポン　- 前受金
    public Decimal getRequestAmount() {
        if (isNewModeTypeExt()) {
            return requestAmount3;
        } else {
        //Decimal couponVal = singelAccount.CouponReturnFlg__c ? CommUtils.nullToZero(amoutAllCouponPay) : CommUtils.nullToZero(amoutAllCoupon);
        return (CommUtils.nullToZero(amoutAllMoney) - CommUtils.nullToZero(amountAllDiscount) - CommUtils.nullToZero(amoutAllCoupon) - getAdvancesReceived());
        //return (CommUtils.nullToZero(amoutAllMoney) - CommUtils.nullToZero(amoutIncDiscont) - couponVal - getAdvancesReceived());
        }
    }
    // 領収書利用金額設定
    // 領収書利用金額：お客様消費総金額 - 割引 - ポイント及びクーポン　- 売掛金の金額
    public Decimal getReceipt() {
        //Decimal couponVal = singelAccount.CouponReturnFlg__c ? CommUtils.nullToZero(amoutAllCouponPay) : CommUtils.nullToZero(amoutAllCoupon);
        // 2014.10.27 会計書の領収金額から売掛金額分はマイナス対応追加、（例）　現金20,000円　+　売り掛け10,000円　＝領収金額は　20,000円として表示のこと
        //return (CommUtils.nullToZero(amoutAllMoney) - CommUtils.nullToZero(amoutIncDiscont) - CommUtils.nullToZero(amoutAllCoupon));
        //return (CommUtils.nullToZero(amoutAllMoney) - CommUtils.nullToZero(amoutIncDiscont) - CommUtils.nullToZero(couponVal));
        //return (CommUtils.nullToZero(amoutAllMoney) - CommUtils.nullToZero(amoutIncDiscont) - CommUtils.nullToZero(amoutAllCoupon) - CommUtils.nullToZero(amoutAllMultiply));
        // 2014.12.28 売り掛け分の金額を領収書金額からマイナスした対応について、共通定義にマイナスする／しないのパラメータ
        if (!isManasAccountMoneyFlg) {
            return (CommUtils.nullToZero(amoutAllMoney) - CommUtils.nullToZero(amountAllDiscount) - CommUtils.nullToZero(amoutAllCoupon));
        } else {
            return (CommUtils.nullToZero(amoutAllMoney) - CommUtils.nullToZero(amountAllDiscount) - CommUtils.nullToZero(amoutAllCoupon) - CommUtils.nullToZero(amoutAllMultiply));
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
    	} else {
    		Decimal recpiptAmount = 0;
    		if (!isManasAccountMoneyFlg) {
    			recpiptAmount = (CommUtils.nullToZero(amoutIncTaxprice) - CommUtils.nullToZero(amountAllDiscount) - CommUtils.nullToZero(amoutAllCoupon));
    		} else {
    			recpiptAmount = (CommUtils.nullToZero(amoutIncTaxprice) - CommUtils.nullToZero(amountAllDiscount) - CommUtils.nullToZero(amoutAllCoupon) - CommUtils.nullToZero(amoutAllMultiply));
    		}
        	if (recpiptAmount <= 0) return 0;
        	Decimal taxRate = getTaxRate();
        	// 2019/04/30 増税仮対応 BY zyz BEGIN
        	// return CommUtils.RoundProcess(recpiptAmount / (1 + taxRate / 100) * (taxRate / 100), gPointLen);
        	return CommUtils.RoundProcess(recpiptAmount / (1 + taxRate / 100) * (taxRate / 100) + taxIncMstTaxprice, gPointLen);
        	// 2019/04/30 増税仮対応 BY zyz END
    	}
    	// 2019/07/30 軽減税率機能対応 WGCH END
    }
    //get Tax
    public Decimal getTaxRate(){
        // 会計日付にて、消費税計算を行う[会計日付から税率を取得する][連泊場合：初日の税率で]
        // TODO:最後の会計日の消費税率で計算を行う
        Decimal taxRate = CommUtils.nullToZero(account[0].TaxRate__c);
        // 会計に該当消費税が未設定する場合、会計に所属する会計明細から消費税率を取得する
        if (taxRate == 0) {
            // 消費税率＞０　AND　BreakDown明細以外の会計明細を消費税率を取得する
            if (isBulkPrint()) {
                // 全て会計に税情報が存在場合
                for (AccountAcount__c acc : account) {
//System.debug(loggingLevel.info, 'oneRoomTranMap.containsKey('+acc.Id+')='+oneRoomTranMap.containsKey(acc.Id));
                    // 2018/04/03 会計分割 WGCH BEGIN
                    /*
                    if (!oneRoomTranMap.containsKey(acc.Id)) continue;
                    List<Tran1__c> taxtranLs = oneRoomTranMap.get(acc.Id);
                    */
                    String pageKey = getPageKey(acc.Id, grpItem.splitGroupNo);
                    if (!oneRoomTranMap.containsKey(pageKey)) continue;
                    List<Tran1__c> taxtranLs = oneRoomTranMap.get(pageKey);
                    // 2018/04/03 会計分割 WGCH END
	                for (Tran1__c tran : taxtranLs) {
	                    if (tran.TaxRate__c > 0) {
	                        taxRate = tran.TaxRate__c;
	                        break;
	                    }
	                }
                }
            } else {
                List<Tran1__c> taxtranLst = [   select Id, TaxRate__c from Tran1__c 
                                            where ParentTran1Ref__c = null And Field1__c in : accidSet And TaxRate__c > 0 
                                            limit 1];
                if (!taxtranLst.isEmpty()) taxRate = taxtranLst[0].TaxRate__c;
            }
//System.debug(loggingLevel.info, 'taxRate[3]='+taxRate);
//System.debug(loggingLevel.info, 'taxRate[4]='+taxRate);
        }
        return taxRate;
    }
    public Decimal getTax(){
    	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
    	if(isReducedTaxFlg) return CommUtils.nullToZero(taxUnitPriceAll) + CommUtils.nullToZero(taxIncMstTaxprice);
    	// 2019/07/30 軽減税率機能対応 WGCH END
        Decimal taxRate = getTaxRate();
        //Map<Date, Decimal> rateMstmap = CommUtils.getTaxRateMap()
        // 消費税計算を行う：課税商品金額(税込) + サービス料(税込)　- 割引金額
        if ( amoutIncTaxprice > 0 ) {
            Decimal locAmoutIncTaxprice = amoutIncTaxprice
                               //+ CommUtils.nullToZero(amoutIncServicePrice)
                               - CommUtils.nullToZero(amountAllDiscount);
            // TODO 消費税マスタの関連設定を再設定を行う
            // 2014/07/02 USD機能対応
            //Integer pointLen = CommUtils.getPointLen();
            //return (locAmoutIncTaxprice > 0 ? CommUtils.RoundProcess(locAmoutIncTaxprice / (1 + taxRate / 100) * (taxRate / 100), 0) : 0);
            // 2019/04/30 増税仮対応 BY zyz BEGIN
            //return (locAmoutIncTaxprice > 0 ? CommUtils.RoundProcess(locAmoutIncTaxprice / (1 + taxRate / 100) * (taxRate / 100), gPointLen) : 0);
            return (locAmoutIncTaxprice > 0 ? CommUtils.RoundProcess(locAmoutIncTaxprice / (1 + taxRate / 100) * (taxRate / 100) + taxIncMstTaxprice, gPointLen) : 0);
            // 2019/04/30 増税仮対応 BY zyz END
        } else {
        	// 2019/04/30 増税仮対応 BY zyz BEGIN
        	// return 0;
            return 0 + taxIncMstTaxprice;
            // 2019/04/30 増税仮対応 BY zyz END
        }
    }



    //get '$会計日付'
    public string getDate(){
        if ( account[0].Field148__c != null ) {
            string s = string.valueof(account[0].Field148__c)+' ';
            string year = s.substring(0,4);
            string month = s.substring(5,7);
            string day = s.substring(8,10);
            return  year+'年'+month+'月'+day+'日';
        } else {
            return  '    年'+'  月'+'  日';
        }
    }
    // 領収書日付[yyyy年MM月dd日]
    public String getAccReceiptDate() {
        // 領収書日付
        Date recDate = null;
        // 2015/05/05 領収証日付はパラメータを引き渡しの場合、該当パラメータの日付を優先を行う
        String parAccRepDt = parMap.get('accRepDt');
        if (!CommUtils.isBlank(parAccRepDt)) {
            try {
                recDate = CommUtils.stringToDate(parAccRepDt);
            } catch (Exception e) {}
        }
        // 2016/01/12 領収書日付デフォルト値設定制御変更 BEGIN
        Boolean accountReceiptDateDefValSetFlg = CommDefine__c.getOrgDefaults().AccountReceiptDateDefValSetFlg__c;
        // 2016/01/12 領収書日付デフォルト値設定制御変更 END
        // 2019/11/30 会計の領収証日付値の自動設定制御モード機能対応 WGCH BEGIN
        String accountReceiptDateDefValSetMode = CommConst.ACCOUNT_RECEIPTDATE_MODE;
        // 2019/11/30 会計の領収証日付値の自動設定制御モード機能対応 WGCH END
        //　領収書日付設定する場合、該当日付で表示、未設定する場合、$営業日付で設定、表示する
        if (recDate == null) {
            // 2019/06/30 領収書日付字段值不为空，设定日期值存在问题bug对应 BY zyz BEGIN
        	/*
            // 2016/01/12 領収書日付デフォルト値設定制御変更 BEGIN
            if (accountReceiptDateDefValSetFlg && !CommUtils.isBLank(singelAccount.Field53__c)) {
                singelAccount.AccountReceiptDate__c = CommUtils.stringToDate(singelAccount.Field53__c.substring(0,8));
            } 
            // 領収書日付のパラメータは空文字列　かつ　パラメータは「売上日」でデイフォル値の場合
            else if (!accountReceiptDateDefValSetFlg && parAccRepDt == '') {
                singelAccount.AccountReceiptDate__c = singelAccount.SalesdayCal__c;
            }
            // 2016/01/12 領収書日付デフォルト値設定制御変更 END
            recDate = singelAccount.AccountReceiptDate__c != null ? singelAccount.AccountReceiptDate__c : singelAccount.SalesdayCal__c;
            */
            // 2019/11/30 会計の領収証日付値の自動設定制御モード機能対応 WGCH BEGIN
            // 到着日の日付で設定する
			if(accountReceiptDateDefValSetMode == CommConst.ACCOUNT_RECEIPTDATE_2){
				if(singelAccount.Relreserve__c != null && singelAccount.Relreserve__r.EntryTime__c != null){
					singelAccount.AccountReceiptDate__c = singelAccount.Relreserve__r.EntryTime__c.date();
				}
			}
			// 出発日の日付で設定する
			else if(accountReceiptDateDefValSetMode == CommConst.ACCOUNT_RECEIPTDATE_3){
				if(singelAccount.Relreserve__c != null && singelAccount.Relreserve__r.Departure__c != null){
					singelAccount.AccountReceiptDate__c = singelAccount.Relreserve__r.Departure__c.date();
				}
			}
            // 2019/11/30 会計の領収証日付値の自動設定制御モード機能対応 WGCH END
            if(singelAccount.AccountReceiptDate__c != null){
            	recDate = singelAccount.AccountReceiptDate__c;
            } else {
	            // 2019/11/30 会計の領収証日付値の自動設定制御モード機能対応 WGCH BEGIN
	            /*
	            // 領収書日付のパラメータは空文字列　かつ　パラメータは「会計日時」でデイフォル値の場合
	            }if (accountReceiptDateDefValSetFlg && !CommUtils.isBLank(singelAccount.Field53__c)) {
	            	singelAccount.AccountReceiptDate__c = CommUtils.stringToDate(singelAccount.Field53__c.substring(0,8));
	            } 
	            // 領収書日付のパラメータは空文字列　かつ　パラメータは「売上日」でデイフォル値の場合
	            else if (!accountReceiptDateDefValSetFlg && parAccRepDt == '') {
	            	singelAccount.AccountReceiptDate__c = singelAccount.SalesdayCal__c;
	            }
	            */
	            if (accountReceiptDateDefValSetMode == CommConst.ACCOUNT_RECEIPTDATE_1) {
	            	if(parAccRepDt == '') singelAccount.AccountReceiptDate__c = singelAccount.SalesdayCal__c;
	            } else if(!CommUtils.isBLank(singelAccount.Field53__c)){
	            	singelAccount.AccountReceiptDate__c = CommUtils.stringToDate(singelAccount.Field53__c.substring(0,8));
	            }
	            // 2019/11/30 会計の領収証日付値の自動設定制御モード機能対応 WGCH END
	            recDate = singelAccount.AccountReceiptDate__c != null ? singelAccount.AccountReceiptDate__c : singelAccount.SalesdayCal__c;
            }
            // 2019/06/30 領収書日付字段值不为空，设定日期值存在问题bug对应 BY zyz END
        }
        // 日本語以外　かつ　施設コードは３３　OR　３４の場合、日付書式を自動変換を行う
        if(!isJpLangeFlg && (FACILITY_CODE == '33' || FACILITY_CODE == '34')){
            if ( recDate != null ) {
                DateTime formatDt = DateTime.newInstance(recDate.Year(),recDate.month(),recDate.day());
                return  formatDt.format(CommBaseCtrl.getDateFormat());
            } else {
                return  ' ';
            }
        }else{
            if ( recDate != null ) {
                DateTime formatDt = DateTime.newInstance(recDate.Year(),recDate.month(),recDate.day());
                return  formatDt.format('yyyy年MM月dd日');
            } else {
                return  '    年'+'  月'+'  日';
            }
        }
    }
    // 領収書日付[yyyy/MM/dd]
    public String getSimpleAccReceiptDate() {
        //　領収書日付設定する場合、該当日付で表示、未設定する場合、$営業日付で設定、表示する
        Date recDate = singelAccount.AccountReceiptDate__c != null ? singelAccount.AccountReceiptDate__c : singelAccount.SalesdayCal__c;
        if ( recDate != null ) {
            DateTime formatDt = DateTime.newInstance(recDate.Year(),recDate.month(),recDate.day());
            return  formatDt.format(CommBaseCtrl.getDateFormat());
        } else {
            return  ' ';
        }
    }
    // 前受付金[前受金＋予約金]
    public Decimal getAdvancesReceived() {
        //return CommUtils.nullToZero(amoutARprice) + CommUtils.nullToZero(amoutAllSubscription);
        decimal arAmountPrice = CommUtils.nullToZero(amoutARprice) + CommUtils.nullToZero(amoutAllSubscription);
    decimal locAmountRefundPrice = CommUtils.nullToZero(amountRefundPrice);
    if (locAmountRefundPrice != 0) {
            return (arAmountPrice > 0 ? (arAmountPrice - locAmountRefundPrice) : 0);
    } else {
        return arAmountPrice;   
    }
    }
    //get '会計明細'
    public List<TranItem> getTran(){
        return tran;
    }
    // 割引合計
    public Decimal getAmoutIncDiscont() {
        //return amoutIncDiscont;
        return amountAllDiscountPay;
    }
    // ご利用日
    public String getServiceDate() {
        return getAccoutInfo().Relreserve__r.EntryTime__c != null ? getAccoutInfo().Relreserve__r.EntryTime__c.format('yyyy年MM月dd日') : '    　  　　　';
    }
    public class TranItem {
        // 明細番号
        public Integer rowNo{get; private set;}
        // 商品名
        public String produceNm{get; private set;}
        // 2017/11/02 会計書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
        // 商品占用行数
        public Integer proNum{get; private set;}
        // 2017/11/02 会計書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
        // 価格
        public Decimal unitPrice{get{return (isReFundFlg == true ? Math.abs(unitPrice) : unitPrice);} private set;}
        // 数量
        public Decimal quantity{get; private set;}
        // 合計金額
        public Decimal amount{get{return CommUtils.RoundProcess(CommUtils.nullToZero(unitPrice) * CommUtils.nullToZero(quantity), gPointLen);}}
        // 特別税
        public Decimal specialTax{get; private set;}
        // 利用日
        public String usedDate{get; private set;}
        // 部屋名(明細に)
        public String roomName{get; private set;}
        // メディア種別設定情報：該当フラグはＴＲＵＥの場合、お支払金額欄に表示する
        public boolean isPaymentInfo{get; private set;}
        // 画面に「▲」に表示するがどうか判別用フラグ
        public boolean isShowCircle {get; private set;}
        // 単価、数量、金額を表示するがどうか判別用フラグ
        public boolean isShowPrice {get; private set;}
        // 明細情報は返金するがどうか、標識フラグ
        private Boolean isReFundFlg;
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
        public Boolean isServieFlg{get; private set;}        // サービス料行Flg
        public Decimal taxUnitPrice{get; private set;} // 消費税金額
        public Decimal taxRate{get; private set;} // 消費税率
        public Decimal serviceRate{get; private set;}
        public Boolean planFlg{get; private set;} // PlanFlg 轻减税率专用
        public Boolean pBrkDNFlg{get; private set;}
        // 2019/11/15 PDF性能优化对应 WGCH BEGIN
        public String pBrkDNStyle{get; private set;}
        public String planStyle{get; private set;}
        // 2019/11/15 PDF性能优化对应 WGCH END
        // 2019/07/30 軽減税率機能対応 WGCH END

        public TranItem(Tran1__c sobj, Integer index) {
            rowNo = index;
            // 2017/11/02 会計書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
            proNum = 0;
            // 2017/11/02 会計書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
            if (index == null) return;
            produceNm = sobj.Field5__c;
            if (FACILITY_CODE == '3') {
                produceNm = CommRepUtils.getPdfMaxShowString(produceNm, 50);
            }
            unitPrice = CommUtils.nullToZero(sobj.Field20__c);
            quantity = CommUtils.nullToZero(sobj.Field21__c);
            isShowCircle = false;
            isShowPrice = true;
            isPaymentInfo = false;
            //System.debug('RelAccount__c:' + sobj.RelAccount__r.Salesday__c);
            // 2015/06/18 利用日内容を設定されると、利用日日付を表示する、設定されないと、売上計上日で表示する
            Date lUseDate = (sobj.UseDate__c == null ? sobj.RelAccount__r.Salesday__c : sobj.UseDate__c) ;
            //if (sobj.RelAccount__r.Salesday__c != null) {
            if (lUseDate != null) {
                DateTime dt = (DateTime.newInstance(lUseDate, Time.newInstance(0,0,0,0)));
                usedDate = dt.format(CommBaseCtrl.getDateFormat());
                //simpleUsedDate = dt.format('MM/dd');
            }
            if (sobj.Field1__r.Relreserve__c != null && 
                sobj.Field1__r.Relreserve__r.Rroom__c != null) {
                // 2018/10/07 会計書の明細にそれぞれの部屋名が表記できる改善 WGCH BEGIN
                roomId = CommUtils.nullToBlank(sobj.Field1__r.Relreserve__r.Rroom__c);
                // 2018/10/07 会計書の明細にそれぞれの部屋名が表記できる改善 WGCH END
                roomName = sobj.Field1__r.Relreserve__r.Rroom__r.Name;
            }
            // 宿泊税情報格納する
            specialTax = CommUtils.nullToZero(sobj.SpecialTax__c);
            tranId = sobj.Id;
            
            // 返金情報チェック
            isReFundFlg = sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_AR && BillSimpleHelp.isRefundItem(sobj.PaymentType__c);
            // 2019/07/30 軽減税率機能対応 WGCH BEGIN
            // 消费税率
            taxRate = CommUtils.nullToZero(sobj.TaxRate__c) / 100;
            serviceRate = CommUtils.nullToZero(sobj.ServiceRate__c) / 100;
            // 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH BEGIN
            // planFlg = isPlanBrkShowFlg && (sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PL);
            planFlg = isPlanBrkShowFlg && (sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) && pBrkTranItemMap != null && pBrkTranItemMap.containsKey(tranId);
            // 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH END
            isServieFlg = pBrkDNFlg = false;
            taxUnitPrice = 0;
            // 2019/11/15 PDF性能优化对应 WGCH BEGIN
            pBrkDNStyle = pBrkDNFlg ? 'display: none;' : 'display: true;';
            planStyle = pBrkDNFlg ? 'display: none;' : 'display: true;';
        // public String planStyle{get { return (true ? 'display: none;' : 'display: true;');} private set;}
        // 2019/11/15 PDF性能优化对应 WGCH END
            // 2019/07/30 軽減税率機能対応 WGCH END
        }
        public Boolean isShowInfo{get{return (rowNo != null);}}
        public Id tranId{get; private set;}
        // 2017/11/02 会計書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
        // 改行後の文字列情報を格納する
        public List<String> produceNms{get; private set;}
        // 2017/11/02 会計書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
        // 2018/10/07 会計書の明細にそれぞれの部屋名が表記できる改善 WGCH BEGIN
        public String roomId{get; private set;}
        // 2018/10/07 会計書の明細にそれぞれの部屋名が表記できる改善 WGCH END
    }

    // 2017/07/27 WGCH 部屋単位の泊数と到着日、出発日表示対応 BEGIN
    /*
    // ヘーダ情報を設定する
    public void setHeaderInfo(String leadId, Set<Id> leadIdSet){
        // 2013/01/11 EDIT  Rroom__r.Rnumber__c -> Rroom__r.Name
        headInfo = [select id, Name, Rroom__r.Rnumber__c, Rroom__r.Name, 
            LeadIndexRef__r.DepartureDate__c, LeadIndexRef__r.EntryDate__c,
            LeadIndexRef__r.Nights__c, StayPersons__c From Lead__c where Id = :leadId];
        // 2017/09/06 直接印刷するとき、泊数情報を再設定しないように改善対応 BEGIN
        //fixHeaderInfo(headInfo, leadIdSet);
        if (!parMap.containsKey('prm')) fixHeaderInfo(headInfo, leadIdSet);
        // 2017/09/06 直接印刷するとき、泊数情報を再設定しないように改善対応 END
    }*/
    private leadIndex__c fixHeaderInfo (List<AccountAcount__c> accItems) {
        //if(headInfo == null) return;
        leadIndex__c locHeader = new leadIndex__c();
        // 查所有有会计 对应的预约数据
        //List<Lead__c> headInfoLst = [select id, Departure__c, EntryTime__c From Lead__c where Id in: leadIdSet];
        Date entryTime = null;
        Date departure = null;
        for(AccountAcount__c acc : accItems){
            Lead__c lead = acc.Relreserve__r;
            // 2019/10/30 会計書、請求書のマージ機能対応 WGCH BEGIN
            if(lead == null) continue;
            /*
            Date wkEntryTime = lead.EntryTime__c.date();
            Date wkDeparture = lead.Departure__c.date();
            */
            Date wkEntryTime = lead.EntryTime__c == null ? null : lead.EntryTime__c.date();
            Date wkDeparture = lead.Departure__c == null ? null : lead.Departure__c.date();
            // 2019/10/30 会計書、請求書のマージ機能対応 WGCH END
            // 最大値と最小値を設定する
            if (entryTime == null) entryTime = wkEntryTime;
            else if (entryTime > wkEntryTime) entryTime = wkEntryTime;
            if (departure == null) departure = wkDeparture;
            else if (departure < wkDeparture) departure = wkDeparture;
        }
        // 置换赋值
        locHeader.EntryDate__c = entryTime;
        locHeader.DepartureDate__c = departure;
        // 2019/10/30 会計書、請求書のマージ機能対応 WGCH BEGIN
        // locHeader.Nights__c = entryTime.daysBetween(departure);
        if(entryTime != null && departure != null) locHeader.Nights__c = entryTime.daysBetween(departure);
        // 2019/10/30 会計書、請求書のマージ機能対応 WGCH END
        return locHeader; 
    }
    // 2017/07/27 WGCH 部屋単位の泊数と到着日、出発日表示対応 END
    public Lead__c headInfo{get; private set;}
    // 会計人数表示
    public Decimal accountingNums{get; private set;}


    // map<leadindex_leadindexsub_groupno, list<会計>>  
    private transient list<string> oneRoomKeyList;
    private transient map<String, List<AccountAcount__c>> oneRoomAccMap;
    // 各部屋の初日会計情報を格納する
    private transient map<String, AccountAcount__c> oneRoomSingMap;
    // 2018/04/03 会計分割 WGCH BEGIN
    // map<会計ID,list<会計明細>>
    private transient map<String, List<TTend__c>> oneRoomTtendMap;
    // map<会計ID,list<会計支払>>
    private transient map<String, List<Tran1__c>> oneRoomTranMap;
    // 2018/04/03 会計分割 WGCH END
    // map<会計ID,Lead__c> 
    private transient map<String, LeadIndex__c> oneRoomHeaderMap;
    
    private boolean isBulkPrint() {
        return parMap.containsKey('bp');
    }
    // 2018/04/03 会計分割 WGCH BEGIN
    // 分割DataInfo
    private List<accGroupInfo> accGroupInfoLst;
    private accGroupInfo grpItem;
    private class accGroupInfo{
    	public accGroupInfo(String wkSplitGroupNo, String wkCuNameStr, String wkRecpNameStr, String wkAccountProvisoStr){
    		splitGroupNo = CommUtils.nullToBlank(wkSplitGroupNo);
    		// 2018/10/06 領収書の宛名を空白保存しても宛名が表記されてしまう WGCH BEGIN
    		cuNameStr = wkCuNameStr == null ? CommUtils.nullToBlank(wkCuNameStr) : 
    													CommUtils.isBlank(wkCuNameStr) ? '　' : CommUtils.nullToBlank(wkCuNameStr);
    		recpNameStr = wkRecpNameStr == null ? CommUtils.nullToBlank(wkRecpNameStr) : 
    													CommUtils.isBlank(wkRecpNameStr) ? '　' : CommUtils.nullToBlank(wkRecpNameStr);
    		accountProvisoStr = wkAccountProvisoStr == null ? CommUtils.nullToBlank(wkAccountProvisoStr) : 
    													CommUtils.isBlank(wkAccountProvisoStr) ? '　' : CommUtils.nullToBlank(wkAccountProvisoStr);
    		// 2018/10/06 領収書の宛名を空白保存しても宛名が表記されてしまう WGCH END
    	}
    	private String splitGroupNo; // 分割NO
    	private String cuNameStr; // 会計書宛名
    	private String recpNameStr; // 領収証宛名
    	private String accountProvisoStr; // 領収証但し
    }
    private String getPageKey(String accId, String groupNo){
    	return CommUtils.nullToBlank( accId ) + '_' + CommUtils.nullToBlank( groupNo );
    }
    // 2018/04/03 会計分割 WGCH END
    private void querySingData(map<String, Id> relAccMap) {
        // SINGLE会計情報を格納する
        oneRoomSingMap = new map<String, AccountAcount__c>();
        // 検索対象ID
        set<id> accIdsSet = new set<Id>();
        accIdsSet.addAll(relAccMap.values());
        // 頭情報を取得する
        map<Id, AccountAcount__c> singAccsMap = new map<Id, AccountAcount__c>(
            [select Relreserve__r.Rroom__r.Name,Relreserve__c, CouponReturnFlg__c,SalesdayCal__c,AccountReceiptDate__c,AccountLanguage__c,AccountName__c,comment__c,ContactName__c,AccountReceiptName__c,BillingCal__c,AccountProviso__c,relaccount__r.Account.Name,frs__r.Salesday__c,DetailSortBy__c,Field53__c 
                // 2019/11/30 会計の領収証日付値の自動設定制御モード機能対応 WGCH BEGIN
                ,Relreserve__r.EntryTime__c
                ,Relreserve__r.Departure__c
                // 2019/11/30 会計の領収証日付値の自動設定制御モード機能対応 WGCH END
                from AccountAcount__c where id = :accIdsSet]);
        if (isBulkPrint()) {
            for (String key : relAccMap.keySet()) {
                id accId = relAccMap.get(key);
                AccountAcount__c singleAcc = singAccsMap.get(accId);
                if (singleAcc == null) singleAcc = new AccountAcount__c();
                oneRoomSingMap.put(key, singleAcc);
            }
        } else {
            singelAccount = singAccsMap.values()[0];
        }
    }
    // １部屋情報を取得、処理を行う
    // 全て会計のID，ControllerのID
    private void queryAllData (set<id> accIdSet, list<id> accIdSortLst, Id ctrlRsId) {
        // 会計情報格納
        oneRoomAccMap = new map<String, List<AccountAcount__c>>();
        // 並び順キーを格納する
        oneRoomKeyList = new list<String>();
        // 会計単位の支払情報格納
        // 2018/04/03 会計分割 WGCH BEGIN
        oneRoomTtendMap = new map<String, List<TTend__c>>();
        // 会計単位の明細情報格納
        oneRoomTranMap = new map<String, List<Tran1__c>>();
        // 2018/04/03 会計分割 WGCH END
        // Header情報を格納する
        oneRoomHeaderMap = new map<String, LeadIndex__c>();

        // 部屋のFIRSTの会計のIDとキー情報格納用変数う
        map<Id, String> firstAccIdKeyMap = new map<Id, String>();
        set<Id> leadIndexSet = new set<Id>();
        map<String,Id> singAccIdMap = new map<String, Id>();
        // 2013/01/29 ADD GROUP設定によて、詳細印刷、表示を行う
        isGroupShowFlg = parMap.get('g') == '1' ? true : false; // 会計分割表示するがどうか判断フラグ　
        // 印刷種別の取得
        String printType = parMap.get('pType');
        // GROUP設定によて、詳細印刷、表示を行う
        String groupNo = parMap.get('gno'); // 分割NO
        // 会計明細に前受付金、返金は明細に非表示制御
        Boolean noShowTranArPay = parMap.containsKey('noar');   // 分割処理の場合、会計明細の前受付金、返金は明細に表示対象外
        // 2018/04/03 会計分割 WGCH BEGIN
        List<String> groupNoLst = new List<String>();
        accGroupInfoLst = new List<accGroupInfo>();
        Boolean splitNoFlg = false;
        if(parMap.containsKey('gnoSize')){
        	for(Integer i = 0; i < CommUtils.nullToIntZero(parMap.get('gnoSize')); i++){
        		String gno = CommUtils.nullToBlank(parMap.get('g'+i));
        		if(!splitNoFlg && splitNoSet.contains(CommUtils.nullToBlank(gno))) splitNoFlg = true;
        		groupNoLst.add(gno);
        		accGroupInfoLst.add(new accGroupInfo(gno, parMap.get('cNm'+i), parMap.get('rNm'+i), parMap.get('aPro'+i)));
        	}
        } else{
        	if(splitNoSet.contains(CommUtils.nullToBlank(groupNo))) splitNoFlg = true;
        	groupNoLst.add(groupNo);
        	accGroupInfoLst.add(new accGroupInfo(groupNo, parMap.get('cuName'), parMap.get('recpName'), parMap.get('accountProviso')));
        }
        // 2018/04/03 会計分割 WGCH END
            
        // 一括印刷する・しないフラグ
        Boolean isBulkPrint = isBulkPrint();
        // 出力対象会計情報を全部取得する
        List<AccountAcount__c> account = [
            select id, name, POSNo__c, relaccount__r.name, Field141__c, Discount__c,
                AmoutSpecialPrice__c,SumSrvPriceExcTax__c,SumSrvPriceIncTax__c,TaxRate__c,
                Field145__c, Field147__c, Field148__c, Field151__c, Relreserve__c, Relreserve__r.RecordTypeId,
                Relreserve__r.LeadIndexRef__c,Relreserve__r.LeadIndexSubId__c,Relreserve__r.RoomGroupNo__c,
                Relreserve__r.Rroom__r.Name,        // 部屋名
                relaccount__r.Account.Name,         // 会計書の請求書欄の請求先名は取得の機能追加　
                Field152__c,                        // 会計人数合計
                //IssueDate__c,                     // 会計の発行日
                Relreserve__r.EntryTime__c,         // 会計の予約の到着日で、発行日として表示する
                Relreserve__r.Departure__c,         // 会計の予約の出発日
                CouponReturnFlg__c                  // クーポン利用の返金
            from AccountAcount__c
            //where id = :controller.getId()
            where id in :accIdSet
            Order By frs__r.Name, Name      // 売上日/会計日で並べ順
            ];
        // 取得した会計情報をMAPへ格納する
        for (AccountAcount__c acc: account) {
            // 該当会計に紐付け予約情報
            // 同じ部屋のキーを作成する
            String key = CommUtils.nullToBlank(acc.Relreserve__r.LeadIndexRef__c) + '_' + CommUtils.nullToBlank(acc.Relreserve__r.LeadIndexSubId__c) + '_' + CommUtils.nullToBlank(acc.Relreserve__r.RoomGroupNo__c);
            // 一括印刷以外の場合、キーは同じで設定する
            if (!isBulkPrint) key = '';
            // 会計情報をMAPへ格納する
            if (!oneRoomAccMap.containsKey(key)) {
                //oneRoomKeyList.add(key);
                firstAccIdKeyMap.put(acc.Id, key);
                oneRoomAccMap.put(key, new list<AccountAcount__c>());
                if (acc.Relreserve__c != null) {
                    //oneRoomHeaderMap.put(acc.Id, )
                    leadIndexSet.add(acc.Relreserve__r.LeadIndexRef__c);
                }
            }
            oneRoomAccMap.get(key).add(acc);
        }
        // 並び順設定を行う
        for (Id accId : accIdSortLst) {
            if (firstAccIdKeyMap.containsKey(accId)) {
                oneRoomKeyList.add(firstAccIdKeyMap.get(accId));
            }
        }
        // SINGLE会計情報を取得する
        map<string, id> singParMap = new map<string, id>();
        if (isBulkPrint()) {
            for (String key : oneRoomAccMap.keyset()) {
                List<AccountAcount__c> accLst = oneRoomAccMap.get(key);
                singParMap.put(key, accLst[0].Id);
            }
        } else {
           singParMap.put('',ctrlRsId); 
        }
        querySingData(singParMap);

        // 会計支払情報を取得する
        List<TTend__c> ttends = null;
        if (!isGroupShowFlg) {
            ttends = [select CardTypeLst__c,CouponTypeLst__c,Field29__c, Field28__c, field2__c, field3__c, Field1__c,RowNo__c,PayProductRef__c,PaymentType__c,PayProductName__c,Field19__c,UseDate__c,RelAccount__c,Field1__r.Relreserve__r.Rroom__c,RelAccount__r.Salesday__c,RelAccount__r.Name,Name,Field30__c  
                        ,Field1__r.Relreserve__r.LeadIndexRef__c,Field1__r.Relreserve__r.LeadIndexSubId__c,Field1__r.Relreserve__r.RoomGroupNo__c
                        // 2018/06/08 会計レシート印刷機能言語選択する WGCH BEGIN
                        ,PayProductRef__r.ProductEnName__c
                        // 2018/06/08 会計レシート印刷機能言語選択する WGCH END
                        // 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH BEGIN
                        ,Id
                        // 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH END
                        From TTend__c where Field1__c in :accIdSet And InvoiceNoShowFlg__c != true And PayProductRef__r.ActionType__c != :CommConst.PROD_ACTION_TYPE_AR ];
        } else {

            ttends = [select PayProductRef__c,PayProductRef__r.PaymentType__c,PayProductRef__r.Name,PayProductRef__r.ProductEnName__c,Field20__c,Field1__c
                            // 2019/10/30 会計画面に入力した金額と、明細分割した際の金額が違う修正 WGCH BEGIN
                            ,Field19__c
                            // 2019/10/30 会計画面に入力した金額と、明細分割した際の金額が違う修正 WGCH END
                            // 2020/10/26 「明細分割」のタブから印刷を行おうとすると表示が元の商品名のままになってしまうの不具合改修 WSQ BEGIN
                            ,PayProductName__c
                            // 2020/10/26 「明細分割」のタブから印刷を行おうとすると表示が元の商品名のままになってしまうの不具合改修 WSQ END
                            // 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH BEGIN
                            ,Id
                            // 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH END
                            // 2018/04/03 会計分割 WGCH BEGIN
                            // From TTend__c where Field1__c in :accIdSet And SplitGroupNo__c =:groupNo
                            ,SplitGroupNo__c  From TTend__c where Field1__c in :accIdSet And SplitGroupNo__c in:groupNoLst
                            // 2018/04/03 会計分割 WGCH END
                            Order By SplitGroupNo__c, RelAccount__r.Name, Name ];
        }
        for (TTend__c ttend : ttends) {
            // 2018/04/03 会計分割 WGCH BEGIN
/*
            Id accid = ttend.Field1__c;// 会計ID
            if (!oneRoomTtendMap.containsKey(accid)) oneRoomTtendMap.put(accid, new list<TTend__c>());
            oneRoomTtendMap.get(accid).add(ttend);
*/
            // 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH BEGIN
        	if(selectTTendIdLst != null && !selectTTendIdLst.contains(CommUtils.nullToBlank(ttend.Id).substring(0,15))) continue;
        	// 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH END
            String pageKey = getPageKey(ttend.Field1__c, isGroupShowFlg ? ttend.SplitGroupNo__c : '');
            if (!oneRoomTtendMap.containsKey(pageKey)) oneRoomTtendMap.put(pageKey, new list<TTend__c>());
            oneRoomTtendMap.get(pageKey).add(ttend);
            // 2018/04/03 会計分割 WGCH END
        }

        // 会計明細情報を取得する
        List<Tran1__c> tranRsLst = new List<Tran1__c>();
        // 会計明細情報を取得する
        String tranQuery = 'select (Select Field20__c From ParentTran1Ref__r where (TaxRate__c = null OR TaxRate__c = 0) And ParentTran1Ref__r.ActionType__c = \''+CommConst.PROD_ACTION_TYPE_PL + '\'),id, name, RowNo__c, PaymentType__c, Field5__c, Tankanonetax__c, Field20__c, Field21__c,ServiceRate__c ,Field7__r.ProductEnName__c,Field41__c,TaxRate__c, ActionType__c, Field23__c, RelAccount__r.Salesday__c, SpecialTax__c,SplitGroupNo__c,UnitPriceDefKbCal__c,Field1__r.Relreserve__r.Rroom__r.Name,PayProductRef__c,PayProductRef__r.PaymentType__c,PayProductRef__r.Name,UseDate__c,RelAccount__r.Name  '+
                            ',Field1__r.Relreserve__r.LeadIndexRef__c,Field1__r.Relreserve__r.LeadIndexSubId__c,Field1__r.Relreserve__r.RoomGroupNo__c '+
                            ',Field1__r.Relreserve__r.EntryTime__c,Field1__r.Relreserve__r.Departure__c '+
                            // 2019/07/30 軽減税率機能対応 WGCH BEGIN
                            ',ParentTran1Ref__c '+
                            // 2019/07/30 軽減税率機能対応 WGCH END
                            // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
                            ',OptionPlanKey__c '+
                            // 2020/02/28 エステなど商品を追加したプラン機能 WGCH END
                            'from Tran1__c ';
        tranQuery += ' where Field1__c in :accIdSet  ';
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
		CommLogicProcess.OptionPlanInfo optionItem = null;
		// 2020/02/28 エステなど商品を追加したプラン機能 WGCH END
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		if(isReducedTaxFlg){
			// 初始化
			reducedTaxInit();
			pBrkTranItemMap = new Map<String, List<TranItem>>();
			pBrkProMap = new Map<String, CommUtils.ProductInfo>();
			planHeaderMap = new Map<String, CommUtils.ProductInfo>();
			// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
			// String wkTranQuery = tranQuery + ' And ParentTran1Ref__c != null And InvoiceNoShowFlg__c != true And ParentTran1Ref__r.InvoiceNoShowFlg__c != true ';
			String gtranQuery = 'select id, name, RowNo__c, PaymentType__c, Field5__c, Tankanonetax__c, Field20__c, Field21__c,ServiceRate__c ,Field7__r.ProductEnName__c,Field41__c,TaxRate__c, ActionType__c, Field23__c, RelAccount__r.Salesday__c, SpecialTax__c,SplitGroupNo__c,UnitPriceDefKbCal__c,Field1__r.Relreserve__r.Rroom__r.Name,PayProductRef__c,PayProductRef__r.PaymentType__c,PayProductRef__r.Name,UseDate__c,RelAccount__r.Name  '+
								',Field1__r.Relreserve__r.LeadIndexRef__c,Field1__r.Relreserve__r.LeadIndexSubId__c,Field1__r.Relreserve__r.RoomGroupNo__c '+
								',Field1__r.Relreserve__r.EntryTime__c,Field1__r.Relreserve__r.Departure__c,ParentTran1Ref__c '+
								',OptionPlanKey__c, ParentTran1Ref__r.OptionPlanKey__c, ParentTran1Ref__r.Field21__c, ParentTran1Ref__r.SpecialTax__c '+
								'from Tran1__c where Field1__c in :accIdSet';
			if(CommConst.OPTION_MODE != CommConst.OPTION_MODE_ON) gtranQuery = tranQuery;
			String wkTranQuery = gtranQuery + ' And ParentTran1Ref__c != null And InvoiceNoShowFlg__c != true And ParentTran1Ref__r.InvoiceNoShowFlg__c != true ';
			// 2020/02/28 エステなど商品を追加したプラン機能 WGCH END
			map<string,CommLogicProcess.HotelTaxDefineInfo> hotelTaxMap = CommLogicProcess.getHotelTaxDefInstance();
			// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
			// 查plan明细的数据进行详细计算
			// for(Tran1__c sobj : DataBase.query(wkTranQuery)){
			List<Tran1__c> tran1Lst = DataBase.query(wkTranQuery);
			if(CommConst.OPTION_MODE == CommConst.OPTION_MODE_ON){
				// 2020/05/29 bug fixed 6437 WGCH BEGIN
				optionItem = CommLogicProcess.getOptionPlanInfo(tran1Lst, isGroupShowFlg);
				// 2020/05/29 bug fixed 6437 WGCH END
			}
			for(Tran1__c sobj : tran1Lst){
			// 2020/02/28 エステなど商品を追加したプラン機能 WGCH END
				// 数量
				Decimal qty = CommUtils.nullToZero(sobj.Field21__c);
				// 合成明细Key
				String key = sobj.ParentTran1Ref__c;
				// 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH BEGIN
				if(selectTranIdLst != null && !selectTranIdLst.contains(key.substring(0,15))) continue;
				// 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH END
				// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
				if(optionItem != null){
					if(!optionItem.planHeaderKeyMap.isEmpty() && !CommUtils.isBlank(sobj.OptionPlanKey__c) && !optionItem.planHeaderKeyMap.containskey(key)) continue;
					if(optionItem.planHeaderKeyMap.containsKey(key)){
						String planHeaderNumKey = optionItem.planHeaderKeyMap.get(key);
						sobj.Field23__c = qty != 0 ? CommUtils.nullToBlank((CommUtils.nullToZero(sobj.Field23__c) / qty * optionItem.planHeaderNumMap.get(planHeaderNumKey))) 
	        											: sobj.Field23__c;
						sobj.Field21__c = CommUtils.nullToBlank(optionItem.planHeaderNumMap.get(planHeaderNumKey));
						qty = CommUtils.nullToZero(sobj.Field21__c);
					}
				}
				// 2020/02/28 エステなど商品を追加したプラン機能 WGCH END
				CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(sobj.UnitPriceDefKbCal__c));
				// 元の単価から、税抜金額を外して、税込み金額を計算する
				CommLogicProcess.HotelTaxInfo hotelTaxItem = CommLogicProcess.getHotelTaxInfo(CommUtils.nullToBlank(shopCode), CommUtils.nullToBlank(sobj.ActionType__c), CommUtils.nullToZero(sobj.Field20__c), CommUtils.nullToZero(sobj.Field21__c), sobj.TaxRate__c, sobj.ServiceRate__c, priceInfo, hotelTaxMap);
				priceInfo = hotelTaxItem.priceInfo;
				if(!planHeaderMap.containsKey(key)) planHeaderMap.put(key, new CommUtils.ProductInfo(CommUtils.nullToIntZero(sobj.UnitPriceDefKbCal__c)));
				CommUtils.ProductInfo headerPriceInfo = planHeaderMap.get(key);
				// 合计header数据处理
				headerPriceInfo.getAddPriceInfo(priceInfo);
				// BRK-INFO
				TranItem item = new TranItem(sobj, 0);
				// 最终单价重置
				item.unitPrice = priceInfo.unitPriceTax;
				// 最终消费税重置
				item.taxUnitPrice = priceInfo.priceTax;
				// 明细对应的priceInfo
				pBrkProMap.put(item.tranId, priceInfo);
				if(!pBrkTranItemMap.containsKey(key)) pBrkTranItemMap.put(key, new List<TranItem>());
				pBrkTranItemMap.get(key).add(item);
			}
		}
		// 2019/07/30 軽減税率機能対応 WGCH END
        // 2018/07/27 宿泊税計算 WGCH BEGIN
        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
        String wkTranQuery = ' Select Id, Field20__c, ParentTran1Ref__c, OptionPlanKey__c, Field21__c, Field23__c From Tran1__c Where Field1__c in :accIdSet And ParentTran1Ref__c != null And InvoiceNoShowFlg__c != true And ActionType__c = \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_RP) + '\'';
        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
        // 查plan明细的数据进行详细计算
        for(Tran1__c sobj : DataBase.query(wkTranQuery)){
        	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
        	String key = sobj.ParentTran1Ref__c;
        	// 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH BEGIN
        	if(selectTranIdLst != null && !selectTranIdLst.contains(key.substring(0,15))) continue;
        	// 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH END
        	if(optionItem != null){
				if(!optionItem.planHeaderKeyMap.isEmpty() && !CommUtils.isBlank(sobj.OptionPlanKey__c) && !optionItem.planHeaderKeyMap.containskey(key)) continue;
				if(optionItem.planHeaderKeyMap.containsKey(key)){
					String planHeaderNumKey = optionItem.planHeaderKeyMap.get(key);
					sobj.Field23__c = CommUtils.nullToZero(sobj.Field21__c) != 0 ? CommUtils.nullToBlank((CommUtils.nullToZero(sobj.Field23__c) / CommUtils.nullToZero(sobj.Field21__c) * optionItem.planHeaderNumMap.get(planHeaderNumKey)))
	        																	: sobj.Field23__c;
					sobj.Field21__c = CommUtils.nullToBlank(optionItem.planHeaderNumMap.get(planHeaderNumKey));
				}
        	}
        	// 2020/02/28 エステなど商品を追加したプラン機能 WGCH END
            if(!pItemPriceMap.containsKey(sobj.ParentTran1Ref__c)) pItemPriceMap.put(sobj.ParentTran1Ref__c, new List<Decimal>());
            pItemPriceMap.get(sobj.ParentTran1Ref__c).add(CommUtils.nullToZero(sobj.Field20__c));
        }
        // 2018/07/27 宿泊税計算 WGCH END
        if (printType == ROOM_ONLY) {
            tranQuery += ' And ActionType__c = \'' + CommConst.PROD_ACTION_TYPE_RP + '\'';
        } else if (printType == ROOM_FOOD) {
            tranQuery += ' And ( ActionType__c = \'' + CommConst.PROD_ACTION_TYPE_RP + '\'';
            tranQuery += '      OR ActionType__c = \'' + CommConst.PROD_ACTION_TYPE_MO + '\')';
        } else if (isGroupShowFlg) {
            // 分割出力
            // 2018/04/03 会計分割 WGCH BEGIN
            if (splitNoFlg) {
                tranQuery += ' And SplitGroupNo__c in :groupNoLst ';
            // 2018/04/03 会計分割 WGCH END
            } else {
                tranQuery += ' And SplitGroupNo__c = null ';
            }
             if(!CommConst.APPOTION_ACCOUNTSPLIT_BKISHOW){
                tranQuery += ' And ParentTran1Ref__c = null ';
            }
            // 2015/12/23 ADD 会計明細に前受付金、返金は明細に非表示制御 BGEIN
            if (noShowTranArPay) {
                tranQuery += ' And ActionType__c != \'' + CommConst.PROD_ACTION_TYPE_AR + '\' ';
            }
            // 2015/12/23 ADD 会計明細に前受付金、返金は明細に非表示制御 END
        } else {
            // ALLの場合、集計対象のデータだけ、レポートへ出力する
            //tranQuery += ' And Accountoutside__c =1 And InvoiceNoShowFlg__c != true ';
            tranQuery += ' And ParentTran1Ref__c = null And InvoiceNoShowFlg__c != true ';
        }
        // Order By Add
        if (!isGroupShowFlg) {
            if (singelAccount != null && !CommUtils.IsBlank(singelAccount.DetailSortBy__c)) {
                // 並び順から設定荒れている場合、プランは一番上に表示して、その後、詳細の明細を表示する
                // プラン個別抽出を行う
                String queryStr2 = tranQuery;
                queryStr2 += ' And ActionType__c = \'' + String.escapeSingleQuotes(CommConst.PROD_ACTION_TYPE_PL) + '\'';
                queryStr2 += ' Order By RelAccount__r.Name, Name ';  
                tranRsLst = DataBase.query(queryStr2);
                
                tranQuery += ' And ActionType__c != \'' + String.escapeSingleQuotes(CommConst.PROD_ACTION_TYPE_PL) + '\'';
                tranQuery += ' Order By ' + singelAccount.DetailSortBy__c;
            } else {
                tranQuery += ' Order By RelAccount__r.Name, RowNo__c, Name ';
            }
        } else {
            tranQuery += ' Order By SplitGroupNo__c, RelAccount__r.Name, Name ';
        }
System.debug('tranQuery:::' + tranQuery);
        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
        // tranRsLst.addAll((List<Tran1__c>)DataBase.query(tranQuery));
        if(optionItem != null && !optionItem.planHeaderKeyMap.isEmpty()){
        	List<Tran1__c> tran1AllLst = (List<Tran1__c>)DataBase.query(tranQuery);
	        List<Tran1__c> nwTran1AllLst = new List<Tran1__c>();
	        for(Tran1__c s : tran1AllLst){
	        	// 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH BEGIN
	        	if(selectTranIdLst != null && !selectTranIdLst.contains(CommUtils.nullToBlank(s.Id).substring(0,15))) continue;
	        	// 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH END
	        	if(!optionItem.planHeaderKeyMap.isEmpty() && 
	        		s.ActionType__c == CommConst.PROD_ACTION_TYPE_PL && 
	        		!CommUtils.isBlank(s.OptionPlanKey__c) && 
	        		!optionItem.planHeaderKeyMap.containskey(s.Id)) continue;
	        	if(optionItem.planHeaderKeyMap.containsKey(s.Id)){
	        		String planHeaderNumKey = optionItem.planHeaderKeyMap.get(s.Id);
	        		s.Field23__c = CommUtils.nullToZero(s.Field21__c) != 0 ? CommUtils.nullToBlank( (CommUtils.nullToZero(s.Field23__c) / CommUtils.nullToZero(s.Field21__c) * optionItem.planHeaderNumMap.get(planHeaderNumKey)))
	        																	: s.Field23__c;
	        		s.Field21__c = CommUtils.nullToBlank(optionItem.planHeaderNumMap.get(planHeaderNumKey));
	        		s.SpecialTax__c = CommUtils.nullToZero(optionItem.planHeaderTaxMap.get(planHeaderNumKey));
	        	}
	        	nwTran1AllLst.add(s);
	        }
	        tranRsLst.addAll(nwTran1AllLst);
        } else tranRsLst.addAll((List<Tran1__c>)DataBase.query(tranQuery));
        // 2020/02/28 エステなど商品を追加したプラン機能 WGCH END
        for (Tran1__c tran : tranRsLst) {
        	// 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH BEGIN
        	if(selectTranIdLst != null && !selectTranIdLst.contains(CommUtils.nullToBlank(tran.Id).substring(0,15))) continue;
        	// 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH END
            // 2018/04/03 会計分割 WGCH BEGIN
/*
            Id accid = tran.Field1__c;// 会計ID
            if (!oneRoomTranMap.containsKey(accid)) oneRoomTranMap.put(accid, new list<Tran1__c>());
            oneRoomTranMap.get(accid).add(tran);
*/
            String pageKey = getPageKey(tran.Field1__c, isGroupShowFlg ? tran.SplitGroupNo__c : '');
            if (!oneRoomTranMap.containsKey(pageKey)) oneRoomTranMap.put(pageKey, new list<Tran1__c>());
            oneRoomTranMap.get(pageKey).add(tran);
            // 2018/04/03 会計分割 WGCH END
        }
        // 予約情報から各会計のHEADER情報を取得、設定を行う
        // Header情報を取得する
        if (!leadIndexSet.isEmpty()) {
            if (!parMap.containsKey('prm')) {
                for (String key : oneRoomAccMap.keySet()) {
                    List<AccountAcount__c> accItems = oneRoomAccMap.get(key);
                    LeadIndex__c locHeader = fixHeaderInfo(accItems);
                    oneRoomHeaderMap.put(key, locHeader);
                }
            } else {
            	Map<Id, LeadIndex__c> leadIndexMap = new Map<Id, LeadIndex__c>([select Id, DepartureDate__c,EntryDate__c,Nights__c From LeadIndex__c where Id = :leadIndexSet]);
            	// 2019/05/31 ルームインジケータの印刷ボタンから会計書出力の場合、泊数と到着、出発日は明細別出力できるように改善対応 WGCH BEGIN
                Map<String, LeadIndex__c> nwLeadIndexMap = new Map<String, LeadIndex__c>();
                if(nightsMode == '1'){
                	// Map<one房间Key, 对应的预约List<Lead__c>>
                	Map<String, List<Lead__c>> oneRoomLeadMap = new Map<String, List<Lead__c>>();
                	// 同一个房间集计处理
                	for(Lead__c lead : [select Id, Field298__c, EntryTime__c, Departure__c, LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c From Lead__c where LeadIndexRef__c in: leadIndexMap.keySet() order by EntryTime__c]){
                		// 顧客データステータスはチェッキン完了またはチェックアウト場合
                		if(lead.Field298__c != CommConst.LEAD_GUEST_ST_CI && lead.Field298__c != CommConst.LEAD_GUEST_ST_CO) continue;
                		// 一个房间Key
                		String key = lead.LeadIndexRef__c + '_' + lead.LeadIndexSubId__c + '_' + lead.RoomGroupNo__c;
                		if(!oneRoomLeadMap.containsKey(key)) oneRoomLeadMap.put(key, new List<Lead__c>());
                		oneRoomLeadMap.get(key).add(lead);
                	}
                	for(String key : oneRoomLeadMap.keySet()){
                		// 当前房间对应的预约集合
                		List<Lead__c> leadLst = oneRoomLeadMap.get(key);
                		LeadIndex__c locHeader = new LeadIndex__c();
                		Date entryTime = null; // 到着日
                		Date departure = null; // 出発日
                		for(Lead__c lead : leadLst){
                			Date wkEntryTime = lead.EntryTime__c.date(); // 到着日
                			Date wkDeparture = lead.Departure__c.date(); // 出発日
                			// 最大値と最小値を設定する
                			if (entryTime == null) entryTime = wkEntryTime;
                			else if (entryTime > wkEntryTime) entryTime = wkEntryTime;
                			if (departure == null) departure = wkDeparture;
                			else if (departure < wkDeparture) departure = wkDeparture;
                		}
                		// 置换赋值
                		locHeader.EntryDate__c = entryTime; // 到着日
                		locHeader.DepartureDate__c = departure; // 出発日
                		locHeader.Nights__c = entryTime.daysBetween(departure); // 泊数
                		for(Lead__c lead : leadLst){
                			// 每个预约对应-最新的LeadIndex信息
                			nwLeadIndexMap.put(lead.Id, locHeader.clone());
                		}
                	}
                }
                // 2019/05/31 ルームインジケータの印刷ボタンから会計書出力の場合、泊数と到着、出発日は明細別出力できるように改善対応 WGCH END
                for (String key : oneRoomAccMap.keySet()) {
                    List<AccountAcount__c> accItems = oneRoomAccMap.get(key);
                    Id leadIndex = accItems[0].Relreserve__r.LeadIndexRef__c;
                    if (leadIndexMap.containsKey(leadIndex)) {
                    	oneRoomHeaderMap.put(key, leadIndexMap.get(leadIndex).clone());
                    	// 2019/05/31 ルームインジケータの印刷ボタンから会計書出力の場合、泊数と到着、出発日は明細別出力できるように改善対応 WGCH BEGIN
                    	if(nightsMode == '1'){
                    		// 当前预约Id
                    		String leadId = accItems[0].Relreserve__c;
                    		// 存在最新的Index数据置换处理
                    		if(nwLeadIndexMap.containsKey(leadId)) oneRoomHeaderMap.put(key, nwLeadIndexMap.get(leadId).clone());
                    	}
                    	// 2019/05/31 ルームインジケータの印刷ボタンから会計書出力の場合、泊数と到着、出発日は明細別出力できるように改善対応 WGCH END
                    } else {
                        oneRoomHeaderMap.put(key, new LeadIndex__c());
                    }
                }
            }
        }
        
    }
    // 集计所有会计书的List
    public List<OneRoomInfo> bulkPrintInfoLst{get;set;}
    // 每个会计书对应的Class
    public class OneRoomInfo{
        public OneRoomInfo( 
            // 一部屋の全て明細情報
            List<OnePage> allPageList,
            // コメント
            String comment,
            // 部屋名
            String roomName,
            /**
            * 利用金額ー預かり金額の結果を格納する
            * 該当計算ロジックは新会計画面JSの関数「setupCalSumAmountPrice」を一致するが必要
            **/
            Decimal requestAmount3,
            // サビース料
            Decimal serviceAmount,
            //get Account#
            String accountNo,
            // get 請求書の宛名先名
            String accountName,
            // get 'お客様'
            String customer,
            // get 但し書き
            String accountProviso,
            // get '$売上計IV（税込）金額'
            Decimal charge,
            // 領収書利用金額設定
            // 領収書利用金額：お客様消費総金額 - 割引 - ポイント及びクーポン　- 売掛金の金額
            Decimal receipt,
            // 領収書金額から計算の内税金額を出力する
            Decimal receiptTax,
            // 消費税
            Decimal tax,
             // 領収書日付[yyyy年MM月dd日]
            String accReceiptDate,
            // 部屋単位の泊数と到着日、出発日表示対応
            LeadIndex__c headInfo,
            // 会計人数表示
            Decimal accountingNums,
            // 2018/04/03 会計分割 WGCH BEGIN
            List<TranItem> tran,
            // 明細印刷済み識別機能追加
            list<Id> outputTtendIdLst
            // 2018/04/03 会計分割 WGCH END
            // 2018/07/27 宿泊税計算 WGCH BEGIN
            ,Decimal hotelTax
            // 2018/07/27 宿泊税計算 WGCH END
            // 2019/07/30 軽減税率機能対応 WGCH BEGIN
            // 2019/10/30 軽減税率割合モード機能対応 WGCH BEGIN
            ,CommLogicProcess.DisRowData disRowData
            ,CommLogicProcess.SumAmountRowData sumRowData
            ,List<CommLogicProcess.TaxRowData> taxRowDataLst
            // 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
            ,List<CommLogicProcess.DisRowData> disRowDataLst
            // 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
            // 2019/10/30 軽減税率割合モード機能対応 WGCH END
            // 2019/07/30 軽減税率機能対応 WGCH END
            ){
            // 明細一覧を取得する
            this.allPageList = allPageList;
            // コメント
            this.comment = comment;
            /**
            * 利用金額ー預かり金額の結果を格納する
            * 該当計算ロジックは新会計画面JSの関数「setupCalSumAmountPrice」を一致するが必要
            **/
            this.requestAmount3 = requestAmount3;
            // サビース料
            this.serviceAmount = serviceAmount;
            //get Account#
            this.accountNo = accountNo;
            // get 請求書の宛名先名
            this.accountName = accountName;
            // get 'お客様'
            this.customer = customer;
            // get 但し書き
            this.accountProviso = accountProviso;
            // get '$売上計IV（税込）金額'
            this.charge = charge;
            // 領収書利用金額設定
            // 領収書利用金額：お客様消費総金額 - 割引 - ポイント及びクーポン　- 売掛金の金額
            this.receipt = receipt;
            // 領収書金額から計算の内税金額を出力する
            this.receiptTax = receiptTax;
            // 消費税
            this.tax = tax;
             // 領収書日付[yyyy年MM月dd日]
            this.accReceiptDate = accReceiptDate;
            // 部屋単位の泊数と到着日、出発日表示対応
            this.headInfo = (headInfo == null ? new LeadIndex__c() : headInfo);
            this.headRoomNm = roomName;
            // 会計人数表示
            this.accountingNums = accountingNums;
            // 2018/04/03 会計分割 WGCH BEGIN
            // 会計明細情報を格納する
            this.tran = tran;
            // 明細印刷済み識別機能追加
            this.outputTtendIdLst = outputTtendIdLst;
            // 2018/04/03 会計分割 WGCH END
            // 2018/07/27 宿泊税計算 WGCH BEGIN
            this.hotelTax = hotelTax;
            // 2018/07/27 宿泊税計算 WGCH END
            /* 2019/09/15 部屋名が表示、会計書崩れる対応 by zyz BEGIN */
            // 2018/10/07 会計書の明細にそれぞれの部屋名が表記できる改善 WGCH BEGIN
            roomNmShowFlg = false;
            if(isShowRoomColFlg){
            	Set<String> roomIdSet = new Set<String>();
            	for(OnePage onePageItem : allPageList){
            		for(TranItem item : onePageItem.onePageList){
            			// 页面显示根据RoomIdSet.size 来控制显示/不显示列
            			if(!CommUtils.isBlank(item.roomId)){
            				roomIdSet.add(item.roomId);
            				if(roomIdSet.size() > 1){
            					roomNmShowFlg = true;
            					break; // 条件成立跳出内部循环
            				}
            			}
            		}
            		if(roomNmShowFlg) break; // 条件成立跳出外部循环
            	}
            }
            /*
            roomNmShowFlg = false;
            if(isShowRoomColFlg){
            	Set<String> roomIdSet = new Set<String>();
            	for(OnePage onePageItem : allPageList){
            		for(TranItem item : onePageItem.onePageList){
            			// 页面显示根据RoomIdSet.size 来控制显示/不显示列
            			if(!CommUtils.isBlank(item.roomId)){
            				roomIdSet.add(item.roomId);
            				if(roomIdSet.size() > 1){
            					roomNmShowFlg = true;
            					break; // 条件成立跳出内部循环
            				}
            			}
            		}
            		if(roomNmShowFlg) break; // 条件成立跳出外部循环
            	}
            	// 部屋名を表示が必要場合 かつ　該当会計書に複数部屋を混在する場合
            	if (roomNmShowFlg) {
            		// １行最大文字数
            		integer splitCodeNum = getProductMaxLen() - CommConst.ROOM_INFO_MAX_SIZE + (
            			(CommConst.ROOM_INFO_MAX_SIZE > 9 ? (isB5size() ? 3 : 5) : 
            			(CommConst.ROOM_INFO_MAX_SIZE > 6 ? (isB5size() ? 3 : 4) : 
            			(CommConst.ROOM_INFO_MAX_SIZE > 5 ? 3 : 2))));
            		map<String,List<String>> wkProNameMap = new map<string ,list<string>>();
            		// 各明細の商品名の指定サイズから外す
	            	for(OnePage onePageItem : allPageList){
	            		for(TranItem item : onePageItem.onePageList){
	            			if (CommUtils.isBlank(item.produceNm)) continue;
	            			// 処理前の商品
	            			String pdNm = item.produceNm;
					        // 2018/10/07 会計書の明細にそれぞれの部屋名が表記できる改善 WSQ END
					        if ( pdNm.length() > splitCodeNum && splitCodeNum != 0) {
					        	// 商品名截取多行显示
					        	if (isAccountProdNmReturnFlg) {
					        	 	if (!wkProNameMap.containsKey(pdNm)) {
					        	 		List<String> retArr = CommRepUtils.getPdfMaxShowStringNews(pdNm,PAGE_NEXTPG_BREAK_RSNUM,splitCodeNum,true);
					        	 		wkProNameMap.put(pdNm,retArr);
					        	 	}
					        	 	item.produceNms = wkProNameMap.get(pdNm);
					        	 	item.proNum = (item.produceNms.isEmpty() ? 0 : (item.produceNms.size() -1));
					        	} else {
					        		// 商品名截取一行显示
					        	 	//system.debug(loggingLevel.info, pdNm+'=['+pdNm.length()+']');
					        	 	//item.produceNm = pdNm.left(splitCodeNum);
					        	 	if (!wkProNameMap.containsKey(pdNm)) {
					        	 		List<String> retArr = CommRepUtils.getPdfMaxShowStringNews(pdNm,1,splitCodeNum,true);
					        	 		wkProNameMap.put(pdNm,retArr);
					        	 	}
					        	 	item.produceNms = wkProNameMap.get(pdNm);
					        	 	item.proNum = (item.produceNms.isEmpty() ? 0 : (item.produceNms.size() -1));
					        	 	//system.debug(loggingLevel.info, item.produceNm+'[AFTER]=['+item.produceNm.length()+']');
					        	}
					        }
	            		}
	            	}
            	}
            }
            */
            // 2018/10/07 会計書の明細にそれぞれの部屋名が表記できる改善 WGCH END
            /* 2019/09/15 部屋名が表示、会計書崩れる対応 by zyz END */
            // 2019/07/30 軽減税率機能対応 WGCH BEGIN
            this.taxRowDataLst = taxRowDataLst;
            this.disRowData = disRowData;
            this.sumRowData = sumRowData;
        	// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
            this.disRowDataLst = disRowDataLst;
            // 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
            // 2019/07/30 軽減税率機能対応 WGCH END
        }
        // 二部出力、二部目は、(控)の文字を追加する
        //public transient List<Integer> printLoop {get; private set;}
        // PDFページ毎の明細情報を格納用
        public transient List<OnePage> allPageList {get; private set;}
        // 領収書出力する/しない制御追加と領収金額に内税金額を表示追加する
        //public transient Boolean noreceipt {get; private set;}
        // 会計書(33/34)英語版に切替機能対応
        //public transient Boolean isJpLangeFlg {get; private set;}
        // コメント
        public transient String comment {get; private set;}
        // 内消費税英語表示文言
        //public transient String taxEnglishLabel {get; private set;}
        // spcd
        //public transient String shopCode {get; private set;}
        // ビル一括印刷機能対応
        //public transient ReportLogo__c repInfo {get; private set;}
        /**
        * 利用金額ー預かり金額の結果を格納する
        * 該当計算ロジックは新会計画面JSの関数「setupCalSumAmountPrice」を一致するが必要
        **/
        public transient Decimal requestAmount3 {get; private set;}
        // サビース料
        public transient Decimal serviceAmount {get; private set;}
        //get Account#
        public transient String accountNo {get; private set;}
        // get 請求書の宛名先名
        public transient String accountName {get; private set;}
        // get 'お客様'
        public transient String customer {get; private set;}
        // get 但し書き
        public transient String accountProviso {get; private set;}
        // get '$売上計IV（税込）金額'
        public transient Decimal charge {get; private set;}
        // 領収書利用金額設定
        // 領収書利用金額：お客様消費総金額 - 割引 - ポイント及びクーポン　- 売掛金の金額
        public transient Decimal receipt {get; private set;}
        // 領収書金額から計算の内税金額を出力する
        public transient Decimal receiptTax {get; private set;}
        // 消費税
        public transient Decimal tax {get; private set;}
         // 領収書日付[yyyy年MM月dd日]
        public transient String accReceiptDate {get; private set;}
        // 部屋単位の泊数と到着日、出発日表示対応
        public transient LeadIndex__c headInfo {get; private set;}
        public transient String headRoomNm{get; private set;}
        // 会計人数表示
        public transient Decimal accountingNums {get; private set;}
        // 2018/04/03 会計分割 WGCH BEGIN
        // 会計明細情報を格納する
        private transient List<TranItem> tran;
        // 明細印刷済み識別機能追加
        private transient list<Id> outputTtendIdLst;
        // 2018/04/03 会計分割 WGCH END
        // 2018/07/27 宿泊税計算 WGCH BEGIN
        public transient Decimal hotelTax{get; private set;}
        public transient Boolean isHotelTaxFlg{get{ return hotelTax > 0;} private set;}
        // 2018/07/27 宿泊税計算 WGCH END
        // 2018/10/07 会計書の明細にそれぞれの部屋名が表記できる改善 WGCH BEGIN
        public transient Boolean roomNmShowFlg{get; private set;}
        // 2018/10/07 会計書の明細にそれぞれの部屋名が表記できる改善 WGCH END
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
        public transient String referenceWidth {get{
	    	if(roomNmShowFlg && isReducedTaxFlg) return '33%';
	    	else if(!roomNmShowFlg && isReducedTaxFlg) return '38%';
	    	else if(roomNmShowFlg && !isReducedTaxFlg) return '39%';
	    	else return '44%';
	    } set;}
        // 2019/10/30 軽減税率割合モード機能対応 WGCH BEGIN
        public CommLogicProcess.DisRowData disRowData {get;set;}
        public CommLogicProcess.SumAmountRowData sumRowData {get;set;}
        public List<CommLogicProcess.TaxRowData> taxRowDataLst {get;set;}
        // 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
        public List<CommLogicProcess.DisRowData> disRowDataLst {get;set;}
        // 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
        // 2019/10/30 軽減税率割合モード機能対応 WGCH END
        // 2019/11/15 PDF性能优化对应 WGCH BEGIN
        public String colgroupStyle {get{ return (!isReducedTaxFlg || 
        								( taxRowDataLst.isEmpty() &&
        								  disRowDataLst.isEmpty() &&
        								  ((sumRowData.amountExcTax + sumRowData.taxAmount) == 0)
        								) ? 'display: true;' : 'display: none;');} set;}
        public String sumRowDataStyle {get{ return (isReducedTaxFlg && sumRowData.isSumRowShowFlg &&
        								(!taxRowDataLst.isEmpty()) ? 'display: true;' : 'display: none;');} set;}
        // 2019/11/15 PDF性能优化对应 WGCH END
        // 2019/07/30 軽減税率機能対応 WGCH END
    }
    // 2017/09/04 WGCH ルームインジケータ画面から会計書一括印刷機能対応 END
    // 2017/11/02 会計書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
    // 2019/09/15 部屋名が表示、会計書崩れる対応 BY zyz BEGIN
    private void accountsName(String accName,TranItem item,set<String> roomset) {
    // 2019/09/15 部屋名が表示、会計書崩れる対応 BY zyz END
        // 2018/10/07 会計書の明細にそれぞれの部屋名が表記できる改善 WSQ BEGIN
        /*
 		integer splitCodeNum = 0;
 		if (FACILITY_CODE == '33') splitCodeNum = 24;
 		else if (FACILITY_CODE == '34'){ splitCodeNum = 28;}
        */
        // 2019/09/15 部屋名が表示、会計書崩れる対応 BY zyz BEGIN
        /*
        integer splitCodeNum = getProductMaxLen();
        // 2018/10/07 会計書の明細にそれぞれの部屋名が表記できる改善 WSQ END
        if ( accName.length() > splitCodeNum && splitCodeNum != 0) {
        	// 商品名截取多行显示
        	if (isAccountProdNmReturnFlg) {
        	 	if (!proNameMap.containsKey(accName)) {
        	 		List<String> retArr = CommRepUtils.getPdfMaxShowStringNews(accName,PAGE_NEXTPG_BREAK_RSNUM,splitCodeNum,true);
        	 		proNameMap.put(accName,retArr);
        	 	}
        	 	item.produceNms = proNameMap.get(accName);
        	 	item.proNum = (item.produceNms.isEmpty() ? 0 : (item.produceNms.size() -1));
        	} else {
        		// 商品名截取一行显示
        	 	item.produceNm = accName.left(splitCodeNum);
        	}
        }*/
		integer splitCodeNum = getProductMaxLen();
		if(roomset.size() > 1 && isShowRoomColFlg){
			Boolean roomNmShowFlg = false;
			if(roomset.size() > 1) roomNmShowFlg = true;
			// 部屋名を表示が必要場合 かつ　該当会計書に複数部屋を混在する場合
			if (roomNmShowFlg) {
				// １行最大文字数
				integer splitCodeNumOne = getProductMaxLen() - CommConst.ROOM_INFO_MAX_SIZE + (
				(CommConst.ROOM_INFO_MAX_SIZE > 9 ? (isB5size() ? 3 : 5) : 
				(CommConst.ROOM_INFO_MAX_SIZE > 6 ? (isB5size() ? 3 : 4) : 
				(CommConst.ROOM_INFO_MAX_SIZE > 5 ? 3 : 2))));
				map<String,List<String>> wkProNameMap = new map<string ,list<string>>();
				// 各明細の商品名の指定サイズから外す
				// 処理前の商品
				String pdNm = accName;
				if ( pdNm.length() > splitCodeNumOne && splitCodeNumOne != 0) {
					// 商品名截取多行显示
					if (isAccountProdNmReturnFlg) {
						if (!wkProNameMap.containsKey(pdNm)) {
							List<String> retArr = CommRepUtils.getPdfMaxShowStringNews(pdNm,PAGE_NEXTPG_BREAK_RSNUM,splitCodeNumOne,true);
							wkProNameMap.put(pdNm,retArr);
						}
						item.produceNms = wkProNameMap.get(pdNm);
						item.proNum = (item.produceNms.isEmpty() ? 0 : (item.produceNms.size() -1));
					} else {
						// 商品名截取一行显示
						if (!wkProNameMap.containsKey(pdNm)) {
							List<String> retArr = CommRepUtils.getPdfMaxShowStringNews(pdNm,1,splitCodeNumOne,true);
							wkProNameMap.put(pdNm,retArr);
						}
						item.produceNms = wkProNameMap.get(pdNm);
						item.proNum = (item.produceNms.isEmpty() ? 0 : (item.produceNms.size() -1));
					}
				}
			}
        } else {
	        if ( accName.length() > splitCodeNum && splitCodeNum != 0) {
	        	// 商品名截取多行显示
	        	if (isAccountProdNmReturnFlg) {
	        	 	if (!proNameMap.containsKey(accName)) {
	        	 		List<String> retArr = CommRepUtils.getPdfMaxShowStringNews(accName,PAGE_NEXTPG_BREAK_RSNUM,splitCodeNum,true);
	        	 		proNameMap.put(accName,retArr);
	        	 	}
	        	 	item.produceNms = proNameMap.get(accName);
	        	 	item.proNum = (item.produceNms.isEmpty() ? 0 : (item.produceNms.size() -1));
	        	} else {
	        		// 商品名截取一行显示
	        	 	item.produceNm = accName.left(splitCodeNum);
	        	}
	        }
        }
        // 2019/09/15 部屋名が表示、会計書崩れる対応 BY zyz END
    }
    // 2017/11/02 会計書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
    // 2018/10/07 会計書の明細にそれぞれの部屋名が表記できる改善 WSQ BEGIN
    // 商品名の最大サイズを取得する
    private static Integer getProductMaxLen() {
    	integer splitCodeNum = 0;
 		if (FACILITY_CODE == '33' || FACILITY_CODE == '35') splitCodeNum = 24;
 		else if (FACILITY_CODE == '34' || FACILITY_CODE == '36'){ splitCodeNum = 28;}
 		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
 		if(isReducedTaxFlg) splitCodeNum -= 3;
 		// 2019/07/30 軽減税率機能対応 WGCH END
 		return splitCodeNum;
    }
    private static Boolean isB5size() {
    	return (FACILITY_CODE == '33' || FACILITY_CODE == '35');
    }
    // 2018/10/07 会計書の明細にそれぞれの部屋名が表記できる改善 WSQ END
    // 2019/03/20 会計書出力枚数とタイトルをカスタマイズできるように改善対応 WSQ BEGIN
    // 共通定義「会計書の印刷枚数とタイトル定義」により、印刷情報を格納用変数
    public list<String> parseAccPrintDef() {
    	// 共通定義値を取得する
    	String str = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().AccountPrintNumsAndTitleDef__c);
    	List<String> titleList = null;
    	// 枚数情報を定義される場合
    	if (!CommUtils.isBlank(str)) {
    		List<String> strArr = str.split(',');
    		String strNum = CommUtils.nullToBlank(strArr[0]);
    		// 数値の場合
    		if (CommUtils.isNumber(strNum)) {
    			Integer decNum = CommUtils.nullToIntZero(strNum);
    			// 1ページ以上印刷場合
    			if (decNum > 0) {
    				// 各枚のタイトル定義情報を格納配列の初期化
    				titleList = new String[decNum];
                    if (strArr.size() > 1) {
        				// 各ページの定義情報を取得する
        				String bodyDef = strArr[1];
        				for (string titleDef : bodyDef.split(';')) {
        					List<String> titleDefArr = CommUtils.nullToBlank(titleDef).split(':');
        					// 定義不正の場合、次の処理を行う
        					if (titleDefArr.size() < 2) continue;
        					String strTitlePos = CommUtils.nullToBlank(titleDefArr[0]);
        					String strTitleLab = CommUtils.nullToBlank(titleDefArr[1]);
        					// NUMBER:TITLE書式じゃない場合、処理SKIP
        					if (!CommUtils.isNumber(strTitlePos) || CommUtils.isBlank(strTitleLab)) continue;
        					// 共通定義の場合、枚数１，２，３定義する場合、配列に入れる場合、マイナス１を計算する
                            Integer decTitlePos = CommUtils.nullToIntZero(strTitlePos)-1;
        					// タイトルの位置は０以前または最大枚以後の場合、処理SKIP
        					if (decTitlePos < 0 || decTitlePos >= decNum) continue;
        					titleList.set(decTitlePos, strTitleLab);
        				}
                    }// if (strArr.size() > 1) 
                    // 定義の枚数により、タイトル未設定の場合、デフォルト値を指定する
                    for (Integer i = 0; i < decNum; i++) {
                        if (CommUtils.isBlank(titleList.get(i))) {
                            if (i == 0) titleList.set(i, (isJpLangeFlg ? 'ご利用明細書': 'Description'));
                            else if (i > 0) titleList.set(i, (isJpLangeFlg ? 'ご利用明細書(控)': 'Description(Customer\'s receipt)'));
                        }
                    }
    			}
    		}
    	}
    	// カスタマイズが非存在場合、デフォルト値を設定する
		if (titleList == null) {
	        if (isShowCopyInfFlg) {
	        	// ２ページ印刷場合
	            titleList = new List<String>{ (isJpLangeFlg ? 'ご利用明細書': 'Description'),(isJpLangeFlg ? 'ご利用明細書(控)': 'Description(Customer\'s receipt)')};
	        } else {
	            titleList = new List<String>{ (isJpLangeFlg ? 'ご利用明細書': 'Description') };
	        }
		}
		return titleList;
    }
    // 2019/03/20 会計書出力枚数とタイトルをカスタマイズできるように改善対応 WSQ END
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
	public static boolean isReducedTaxFlg{get{ return (CommConst.REDUCED_TAXRATE_FLG && (FACILITY_CODE == '34' || FACILITY_CODE == '33'));} private set;}
	public static boolean isPlanBrkShowFlg{get{ return CommConst.REDUCED_PDF_PLAN_BRK_SHOW_FLG;} private set;}
	// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
	public static boolean planBrkToHeaderCalFlg{get{ return CommConst.PLAN_BRKTOHEADER_CAL_FLG;} private set;}
	// 2019/10/02 PlanHeader算法切换对应 WGCH END
	// 2019/10/30 軽減税率割合モード機能対応 WGCH BEGIN
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
	private void addDetailToMapFun(TranItem tranItem, Decimal noTaxUnitPriceSum) {
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
		if(CommUtils.nullToZero(noTaxUnitPriceSum) != 0  || specialTax > 0){
			// Plan明细里 含有非课税 并且 Map key没有0的情况
			Decimal noTaxKey = 0;
			if(!taxRowDataMap.containsKey(noTaxKey)) taxRowDataMap.put(noTaxKey, new TaxRowData());
			taxRowDataMap.get(noTaxKey).amountExcTax += noTaxUnitPriceSum + specialTax;
			// 集计处理
			sumRowData.amountExcTax += noTaxUnitPriceSum + specialTax;
			sumRowData.amountIncTax += noTaxUnitPriceSum + specialTax;
			// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
			//sumRowData.priceAmountSum += noTaxUnitPriceSum + specialTax;
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
	private List<TaxRowData> taxRowDataLst;
	// map<消費税レート,該当消費税関連の金額合計>
	private map<Decimal, TaxRowData> taxRowDataMap;
	public class TaxRowData {
		public TaxRowData() {
			taxRate = amountExcTax = amountIncTax = taxAmount = 0;
			//isNoTaxPrice = isDiscountTax = false;
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
			// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WSQ BEGIN
			taxRate = 0;
			// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WSQ END
			disTaxAmountSum = disUnitPriceSum = 0;
		}
		// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WSQ BEGIN
		public Decimal taxRate{get;set;}//値引き行目の税率情報を格納する
		// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WSQ END
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
	// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH BEGIN
	public static CommErrorPage isLockAcc(Map<String, String> parMap){
		CommErrorPage page = new CommErrorPage();
		// 获取管理员信息
		CommLogicProcess.AccountAdminInfo accAdminItem = CommLogicProcess.getAccountAdminInfo();
		// 获取锁定日期设定
		CommLogicProcess.ComDay comDayItem = new CommLogicProcess.ComDay();
		if(comDayItem.setComDay()){
			Set<String> accIdSet = new Set<String>();
			if(parMap.containsKey('id')){
				String accId = parMap.get('id');
				accIdSet.add(accId);
			}
			String bulkid = parMap.get('bulkid');
			if(!CommUtils.isBlank(bulkId)){
				String[] accIdLst = bulkId.split(',');
				for (String s : accIdLst) {
					accIdSet.add(s);
				}
			}
			List<AccountAcount__c> account = [ select id, SalesdayCal__c, ShopCode__c from AccountAcount__c where id in :accIdSet];
			for(AccountAcount__c acc : account){
				// 设定Error成功跳到下次循环
				if(CommLogicProcess.isAccLockFlg(acc, accAdminItem, comDayItem, true)){
					// 无効の場合PAGE
					PageReference customPage = new PageReference('/apex/CommErrorPage');
					page.isBlankPageFlg = true;
					page.page = customPage;
				}
			}
		}
		return page;
	}
	public class CommErrorPage{
		public CommErrorPage(){
			isBlankPageFlg = false;
		}
		public Boolean isBlankPageFlg{get; set;}
		public PageReference page{get; set;}
	}
	// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH END
}