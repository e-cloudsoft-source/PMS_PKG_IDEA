/**
* 月単位の部屋アサインリスト情報
* 要件１：今日から一か月間部屋予約情報を照会できる
*              同じ部屋、重複利用する場合、表示情報は？
* 要件２：同じお客様連泊する場合、同じＢＬＯＣＫを表示する
* 2014/08/28 店舗と部屋タイプ制御条件を追加する
* 2014/09/01 BugFix 親部屋集める/分割するフラグが１の場合、設定不正不具合修正
* 2014/09/10 １日間モードを追加する
* 2014/11/12 TDのHTML作成機能改善
* 2014/12/05 タイムテーブルに予約ステータスの色表示
* 2014/12/25 六輝機能外貨の場合非表示対応
* 2015/09/01 多店舗機能対応
* 2015/10/29 故障部屋など項目有効性エラーが発生する場合、エラーメッセージ表示改善対応
* 2016/10/13 別画面からINCLUDE場合の対応
* 2016/11/22 故障部屋一括登録機能対応
* 2018/11/08 未割り当てウインドウの予約も該当部屋タイプのみ情報を表示する
* 2019/05/30 タイムテーブルの期間設定（31日表示、7日表示など）が保持されないに関して
* 2019/07/30 軽減税率機能対応
* 2020/07/30 入湯税の自動入力機能について改善
**/
global with sharing class RoomScheduleReport extends CommBaseCtrl {
	// ご予約へ編集権限あり、なし
	public boolean isCanUpdateLead{get{return CommSecurityUtils.isCanUpdateLead();}}
	// 2016/11/25 英語版するがどうか
	public Boolean isEnglishMode{get{return !CommBaseCtrl.getLocalIsJapanese();}}
	// 支店情報を表示、格納する
    //public BranchShopUtil shopInfo{get; private set;}
    /* 部屋リスト情報を格納する */
    // 1000件以上部屋対応するため、部屋格納構造変更する
    //public List<Room__c> roomList{get; private set;}
    public List<List<Id>> roomList{get; private set;}
    public String roomListJson{get;private set;}
    //{get; private set;}
    public Map<Id,RoomInf> roomInfos{get; private set;}
    // 画面上に表示される予約一覧のヘッダー部
    //public List<dispHeader> dispHeaders;
    public List<DispHeader> monthHeader	{get; private set;}
    public List<DispHeader> dayHeader	{get; private set;}
    public List<DispHeader> hourHeader	{get; private set;}
    // 
    public List<DispHeader> allColUnitInfo {get; private set;}
    // 六輝表示がどうか判断用
    public boolean isShowQreqki{get{return CommConst.IsOrgRokuyoIsNoShow();}}
   
    // 時間設定アリアに情報を維持する[画面使用]
    public transient  Map<Id, OneRoomAssingInfo> roomBookingMap{get;private set;}
    // ３０日日付情報を格納する[表示する期間範囲の日付を格納する]
    //private transient List<Date> oneMonthDateList;
	// 部屋/予約名表示標識 2の場合、予約名を表示する 
	private static final Integer ROOM_INFO_NAME_TYPE = CommDefine__c.getOrgDefaults().RoomIndicatorInfoNameType__c == null ? 0 : CommDefine__c.getOrgDefaults().RoomIndicatorInfoNameType__c.intValue();
    // 取得するデータ範囲
    private static final Integer CONST_QUERY_DAYS_MODE1 = 31;
    private static final Integer CONST_QUERY_DAYS_MODE2 = 7;
    private static final Integer CONST_QUERY_DAYS_MODE3 = 90;
    private static final Integer CONST_QUERY_DAYS_MODE4 = 1;
    // 画面表示モード設定
    private static final String CONST_VIEWMODE_1 = '31DAYS';
    private static final String CONST_VIEWMODE_2 = 'ONEWEEK';
    private static final String CONST_VIEWMODE_3 = '90DAYS';
    private static final String CONST_VIEWMODE_4 = 'ONEDAY-30';
    private static final String CONST_VIEWMODE_5 = 'ONEDAY-10';
    private static final String CONST_VIEWMODE_6 = 'ONEDAY-05';
    // 2018/05/01 タイムテーブル、15 分刻みの追加 by zy BEGIN
    private static final String CONST_VIEWMODE_7 = 'ONEDAY-15';
    // 2018/05/01 タイムテーブル、15 分刻みの追加 by zy END
	// 画面表示モード設定[時モード]
    //private static final String CONST_VIEWMODE_M_5 	= '5minute';
    //private static final String CONST_VIEWMODE_M_10 = '10minute';
    //private static final String CONST_VIEWMODE_M_30 = '30minute';
    // 表示モード制御情報
    public TimeModel gModeInfo{get; private set;}
    
    // 照会指定日情報を格納する
	public BookingTimeTable__c timeTable{get;set;}
    // エラーメッセージ
    public static String showInfoError{get;set;}
    public String showInfoWarn {get;set;}
	// -------------------------------------------
   	// 予約新規登録機能対応開始
   	// 各店舗の表示する項目情報を取得、格納を行う
    // -------------------------------------------
    // お客様名
	public String contactName{get;set;}
	// 予約新規登録用関数う
    public Lead__c newLead{get;set;}
    public Contact newContact{get;set;}
    // 一括予約登録に割り当て部屋リスト
    public String roomIds{get;set;}
    // Hidden項目・到着日
	public String startDays{get;set;}
    // 泊数
	public Integer staysNums{get;set;}
    // 2013/10/12 DB更新処理標識フラグ
	public Boolean bookingCreateOK{get;set;}
	// 会計支払方法
	public List<Selectoption> paymentTypeLst{get; private set;}
	// E/B機能存在するかどうか標識用
    public Boolean isHaveEbInfo{get; private set;}
	public Boolean isHaveSeminar{get; private set;}
    // 2016/10/13 別画面からINCLUDE場合の対応 BEGIN
    public Boolean isIncludeMode{get;private set;}
    // 2016/10/13 別画面からINCLUDE場合の対応 END
	// 2016/12/14 zyz CTI予約 BEGIN
	public String ctiContactInf {get; set;}
	// 2016/12/14 zyz CTI予約 END
	//public Date nowUseDt;
	// -------------------------------------------
   	// 予約新規画面に固定設定の項目
    // -------------------------------------------
    private static final String LeadConstFields  = 'Name,Relcontact__c,refTypeOfRooms__c,EntryTime__c,Field4__c,Departure__c,Field3__c,StayPersons__c,SeminarOrderFlg__c,ExtraBedChk__c,Rroom__c,Field310__c,Field315__c,Field2__c,Segment__c,Comment3__c';
	
	// 2013/12/10 日帰到着時刻初期値
	private static final String defaultDayUseCheckInTime = CommConst.DEF_DAYUSE_CHECKIN_TIME;
	//2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 by zy BEGIN
	//private static final String defaultCheckinTime = CommConst.DEF_CHECKIN_TIME;
	//private static final String defaultCheckoutTime = CommConst.DEF_CHECKOT_TIME;
	private static String defaultCheckinTime = CommConst.DEF_CHECKIN_TIME;
	private static String defaultCheckoutTime = CommConst.DEF_CHECKOT_TIME;
	public Integer defStaysNums{get; private set;}
	//2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 by zy END
	public String getDefaultCheckinTime() { return defaultCheckinTime;}
	public String getDefaultCheckoutTime() { return defaultCheckoutTime;}
	// 期間表示情報
	//private integer cycSize;
	//public Map<String,TimeModel> timeModelMap{get;set;}
	//minute mode `s button list
	//public List<String> buttonLst{get;private set;}
	// 画面制御モード変数
	public String viewMode	{get;set;}	// 画面制御モード:31日間、90日間、一週間、１日間
	//public String minuteMode{get;set;} 	// 画面制御モード：分単位制御変数（５分、１０分、３０分）
	// 祝日情報を格納する
	public Map<Date, String> holidayMap{get; private set;}
	// 予約情報ステータスの色制御情報を格納
	public Map<String, AppSetupConfigXmlUtil.Config> leadStatusColorMap{get; private set;}
	public List<SelectOption> leadStatusInfoLst{get; private set;} 
	// 店舗関連の色設定情報格納
	public ShopInfoUtil.Color statusColor{get; private set;}	// 部屋ステータスの色情報を格納
    private UserUtil.UserShopInfo userInf;
    // 2016/08/09 BEGIN
    private static final string localTimeFormat = CommBaseCtrl.getDateTimeFormat();
    // 2016/08/09 END
    // 予約情報ステータスの色制御情報を格納
	public String statusCode{get; set;}
	public String constStatusCodeRoom{get{ return 'room';}}
	public String constStatusCodeLead{get{ return 'lead';}}
	public String MoreRoomMessage{get;set;}
	//親部屋
	public String mainRoomId{get;set;}
	// 2016/12/07 タイムテーブル新規後一画面へ遷移 BEGIN by zh
    public String indexId{get;private set;}
    // タイムテーブル新規後一画面へ自動遷移制御
    public boolean RoomTypeGotoBookingFlexApp{get{return CommDefine__c.getOrgDefaults().RoomScheduleGoBookingFlexAppFlg__c;}}
    // タイムテーブル新規後一画面へ遷移する・しない切替選択機能制御
    public boolean RoomTypeGotoBookingFlexAppConfirm{get{return CommDefine__c.getOrgDefaults().RoomScheduleGoBookingFlexAppConfirmFlg__c;}}
    // 2016/12/07 タイムテーブル新規後一画面へ遷移 END by zh
    // 2016/12/29 连接plan页面替换标准页面  begin by wx  
    public String planName{get;set;}
    // 2016/12/29 连接plan页面替换标准页面  end by wx 
    // 2019/02/28 滞在・外出状態の管理 WGCH BEGIN
    public static Boolean outButtonShowFlg{get{return RoomIndicatorInfo.outButtonShowFlg;}}
    // 2019/09/15 指定日自动记忆機能対応 WGCH BEGIN
	public Boolean isChkInDayFlg{get{ return CommConst.USERCONFIG_CHECKINDAY_FLG;} set;}
	public String userId{get{ return UserInfo.getUserId();} private set;} // UserId
	// 2019/09/15 指定日自动记忆機能対応 WGCH END
    // 2019/02/28 滞在・外出状態の管理 WGCH END
	// -------------------------------------------
	// クラスインスタンス化
	// -------------------------------------------
    public RoomScheduleReport () {
        userInf = UserUtil.CurrentUserInfo;
		// 2019/07/31 20190527.04.タイムテーブル、ルームインジケータ、マルチタスク機能編集モードと読み込み専用モード対応必要 by zy BEGIN
		notReadOnlyFlg = userInf.hadTimeTable;
		// 2019/07/31 20190527.04.タイムテーブル、ルームインジケータ、マルチタスク機能編集モードと読み込み専用モード対応必要 by zy END
    	// 開始指定日初期値設定を行う
        // 2013/12/12 パラメータ追加,指定日の情報を表示する
        String startDt = ApexPages.currentPage().getParameters().get('dt');
        if (!CommUtils.isBlank(startDt)) {
        	// 2016/10/21 翻訳機能対応、日付変換対応 BEGIN
        	//timeTable = new BookingTimeTable__c(Checkinday__c=Date.parse(startDt));
        	timeTable = new BookingTimeTable__c(Checkinday__c=CommUtils.stringToDate(startDt));
        	// 2016/10/21 翻訳機能対応、日付変換対応 END
        } else {
			// 2019/09/15 指定日自动记忆機能対応 WGCH BEGIN
			Date stDate = Date.today();
			if(isChkInDayFlg){
				Map<string,string> userConfigMap = UserConfigCompCtrl.getKrepConfig(userId, '');
				// 指定日KEY
				String checkInDayKey = UserConfigCompCtrl.KREP_SUBTYPE.CHECKINDAY.name();
				if(userConfigMap.containsKey(checkInDayKey)){
					String queryDt = userConfigMap.get(checkInDayKey); // 记忆指定日
					stDate = (String.isEmpty(queryDt)) ? stDate : CommUtils.stringToDate(queryDt);
				}
			}
    		// timeTable = new BookingTimeTable__c(Checkinday__c=Date.today());
			timeTable = new BookingTimeTable__c(Checkinday__c = stDate);
			// 2019/09/15 指定日自动记忆機能対応 WGCH END
        }
	    // 2016/10/13 別画面からINCLUDE場合の対応 BEGIN
	    isIncludeMode = ApexPages.currentPage().getParameters().containsKey('frame');//別のページに含めているがどうか
	    // 2016/10/13 別画面からINCLUDE場合の対応 END
        // Cookieからレイアウトモードを取得する
	    // 2019/05/30 タイムテーブルの期間設定（31日表示、7日表示など）が保持されないに関してby zy BEGIN
        /*
        CookieInf cookInf = getCookieInf();
        // 画面モード初期値を設定する
        // 2018/05/02 タイムテーブルの初期表示の単位値は定義できるように改善 by zy BEGIN
        // cookie不存在的情况下用共同定义
        //viewMode = CommUtils.isBlank(cookInf.viewMode) ? CONST_VIEWMODE_1 : cookInf.viewMode;
        viewMode = CommUtils.isBlank(cookInf.viewMode) ? getDefMode() : cookInf.viewMode;
	    */
	    // 2019/05/30 タイムテーブルの期間設定（31日表示、7日表示など）が保持されないに関してby zy END
        // 2018/05/02 タイムテーブルの初期表示の単位値は定義できるように改善 by zy END
        // １日間モードの場合、時間単位モード(10分単位はDefault設定)
        //minuteMode = CONST_VIEWMODE_M_10;
        // 2019/01/15 タイムテーブルを開いた際、デフォルトで表示される部屋タイプを指定できるようにする by zy BEGIN
        initCookieInfo();
        // 2019/01/15 タイムテーブルを開いた際、デフォルトで表示される部屋タイプを指定できるようにする by zy END
        // 支店一覧を初期化
        setInitBranShopLst();
        // 指定の支店の部屋タイプ設定
        setInitRoomTypeLst();
        // 2019/05/30 タイムテーブルの期間設定（31日表示、7日表示など）が保持されないに関してby zy BEGIN
        CookieInf cookInf = getCookieInf();
        viewMode = CommUtils.isBlank(cookInf.viewMode) ? getDefMode() : cookInf.viewMode;
        // 2019/05/30 タイムテーブルの期間設定（31日表示、7日表示など）が保持されないに関してby zy END
        // 休日設定情報を初期化する
        initHolidayInfo();
        // -------------------------------------------
        // 部屋リスト情報を取得する
        roomList = getGuestRooms();
		// -------------------------------------------
		
	   	// -------------------------------------------
	   	// 予約新規登録用変数初期化
	    // -------------------------------------------
		//newLead = new Lead__c();
		newLead = initLeadInfo();
		//newContact = new Contact();
		/*
		// 予約のレコードタイプ
    	newLead.RecordTypeId = CommLogicProcess.getLeadBookingRecType();
    	// チェックイン時刻、チェックアウト時刻
    	newLead.Field4__c = CommConst.DEF_CHECKIN_TIME;
    	newLead.Field3__c = CommConst.DEF_CHECKOT_TIME;
    	*/
		// 支払方法リスト初期化する
		paymentTypeLst = new List<Selectoption>();
		Schema.DescribeFieldResult fieldResult = Lead__c.Field315__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
	   	for( Schema.PicklistEntry f : ple) {
           paymentTypeLst.add(new SelectOption(f.getValue(),f.getLabel()));
	   	}
		// アプリのE/B機能起動がどうかフラグを設定する
		isHaveEbInfo = CommConst.APPOPTION_ISUSR_EB;
		isHaveSeminar = CommConst.APPOTION_ISSHOW_SEMINAR;
		// 2014/12/05 色表示情報初期化 BEGIN
		initColorInfo();
		// 2014/12/05 色表示情報初期化 End
		statusCode = CommUtils.isBlank(cookInf.statusMode) ? constStatusCodeRoom : cookInf.statusMode;
		// 2017/01/25 新規画面の項目自定義機能 by zy BEGIN
		loadInsertWindow();
		// 2017/01/25 新規画面の項目自定義機能 by zy END
		
    }
    private Lead__c initLeadInfo() {
		// 2020/06/15 予約ポップのデフォルト字段エラー修正 by zy BEGIN
		Lead__c newLead = (Lead__c)Lead__c.sObjectType.newSObject(CommLogicProcess.getLeadBookingRecType(), true);
		// Lead__c newLead = new Lead__c();
    	// 予約のレコードタイプ
		// newLead.RecordTypeId = CommLogicProcess.getLeadBookingRecType();
		// 2020/06/15 予約ポップのデフォルト字段エラー修正 by zy END
    	// チェックイン時刻、チェックアウト時刻
    	newLead.Field4__c = CommConst.DEF_CHECKIN_TIME;
    	newLead.Field3__c = CommConst.DEF_CHECKOT_TIME;
		newContact = new Contact();
		// 2016/12/14 zyz CTI予約 BEGIN
		String ctiContactId = Apexpages.currentpage().getparameters().get('contactid');
		String ctiContactNm = Apexpages.currentpage().getparameters().get('contactnm');
		ctiContactInf = CommUtils.isBlank(ctiContactId) ? '' : (ctiContactNm + '#' + ctiContactId);
        // 2016/12/14 zyz CTI予約 END*/
    	// 2016/11/16 見積明細設定機能対応 BEGIN by zh
    	initBookEstItem();
    	// 2016/11/16 見積明細設定機能対応 END by zh
    	return newLead;
    }
    /**
    * 色表示関連情報の初期化
    * 2014/12/05 色表示情報
    **/
    private void initColorInfo () {
		// 2014/12/05 予約のステータス設置情報を格納する BEGIN
		leadStatusColorMap = AppSetupConfigXmlUtil.getLeadStatusColors(branchShopNm);
		// 予約ステータスリストの定義情報を取得する
		Schema.DescribeFieldResult fieldResult = Lead__c.ReservedStatus__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		leadStatusInfoLst = new List<SelectOption>();
		for (Schema.PicklistEntry f : ple ) {
			//leadStatusInfoLst.add(new SelectOption(f.getValue(), f.getLabel()));
			if (leadStatusColorMap.containsKey(f.getValue()) && !CommUtils.isBlank(leadStatusColorMap.get(f.getValue()).val)) {
				leadStatusInfoLst.add(new SelectOption(f.getValue(), f.getLabel()));
			}
		}
		// 故障部屋など設定色の取得
		statusColor = ShopInfoUtil.getStatusColor(branchShopNm);
    }
    public void changeStatusMode() {
 		// 選択値はCOOKIEへ反映する
 		//CookieInf inf = new CookieInf();
 		//inf.statusMode = statusCode;
        setCookieInf();
    	// 2016/01/28 予約ステータス/部屋ステータス表示の切替できる対応 BEGIN
        initColorInfo();
        // 2016/01/28 予約ステータス/部屋ステータス表示の切替できる対応 END
    }
    // ページモードリスト
    public List<SelectOption> getViewModeList() {
        List<SelectOption> options = new List<SelectOption>();
        //90日
        options.add(new SelectOption (CONST_VIEWMODE_3,Label.CONST_005_0080+'　'));
        //31日
        options.add(new SelectOption (CONST_VIEWMODE_1,Label.CONST_005_0081+'　'));
        //07日
        options.add(new SelectOption (CONST_VIEWMODE_2,Label.CONST_005_0082+'　'));
        //30分
        options.add(new SelectOption (CONST_VIEWMODE_4,Label.CONST_005_0083+'　'));
        // 2018/05/01 タイムテーブル、15 分刻みの追加 by zy BEGIN
        //15分
        options.add(new SelectOption (CONST_VIEWMODE_7,+'15分　'));
        // 2018/05/01 タイムテーブル、15 分刻みの追加 by zy END
        //10分
        options.add(new SelectOption (CONST_VIEWMODE_5,Label.CONST_005_0084+'　'));
        //05分
        options.add(new SelectOption (CONST_VIEWMODE_6,Label.CONST_005_0085+'　')); 
        return options;
    }
    /*
    // ページモード：時間モード
    public List<String> getMinuteModeList() {
    	List<String> minuteLst = new List<String>();
    	if (viewMode != CONST_VIEWMODE_4) return minuteLst;
    	minuteLst.add(CONST_VIEWMODE_M_5);
    	minuteLst.add(CONST_VIEWMODE_M_10);
    	minuteLst.add(CONST_VIEWMODE_M_30);
    	return minuteLst;
    }*/
	/**
	* XML定義から祝日情報を取得する
	**/
	private void initHolidayInfo () {
		// 祝日情報初期化
		holidayMap = new Map<Date, String>();
		// 祝日定義情報を取得する
    	List<Document> sr = [select body, name from Document where DeveloperName = 'HolidayDefineXml'];
    	if (sr.isEmpty()) return;
    	Blob xmlBody = sr[0].Body;
    	String strXmlBody = xmlBody.toString();
		// String -> XML OBJECT
		Dom.Document doc = new Dom.Document();
		doc.load(strXmlBody);
		Dom.XMLNode root = doc.getRootElement();
		for(Dom.XMLNode yearNode : root.getChildElements()) {
			for(Dom.XMLNode dayNode : yearNode.getChildElements()) {
				String holiday = dayNode.getText();
				if (!CommUtils.isBlank(holiday)) {
					// 2016/01/20 Golbal対応するため、日付変換は共通関数に変換する BEGIN
					//Date holidayDt = Date.parse(holiday);
					Date holidayDt = CommUtils.stringToDate(holiday);
					// 2016/01/20 Golbal対応するため、日付変換は共通関数に変換する END
					holidayMap.put(holidayDt, CommUtils.nullToBlank(dayNode.getAttribute('label', null)));
				}
			}
		}
	}
	
	// 部屋タイプリスト情報
	public List<SelectOption> roomTypeLst{get; private set;}
	public String roomTypeNm{get; set;}
    private void setInitRoomTypeLst() {
    	roomTypeLst = new List<SelectOption>();
	// 2015/09/01 多店舗機能対応 BEGIN
		// List<TypeOfRooms__c> roomTypeLstRs = (new CommLogicProcess()).getTypeOfRooms(branchShopNm);
        List<TypeOfRooms__c> roomTypeLstRs = new List<TypeOfRooms__c>();
        if (CommUtils.isBlank(branchShopNm) && userInf.isShopCodePlex) {
            roomTypeLstRs = (new CommLogicProcess()).getTypeOfRooms(userInf.shops);
        }else {
            roomTypeLstRs = (new CommLogicProcess()).getTypeOfRooms(branchShopNm);
        }
	// 2015/09/01 多店舗機能対応 END
		for (TypeOfRooms__c r : roomTypeLstRs) {
    		roomTypeLst.add(new SelectOption(r.Id, r.Name));
		}
// 2016/11/04 部屋タイプは複数選択できる機能対応 BEGIN		
		// 2019/01/15 タイムテーブルを開いた際、デフォルトで表示される部屋タイプを指定できるようにする by zy BEGIN
		//roomTypeNm = multiRoomTypeIds = '';
        roomTypeNm = multiRoomTypeIds = CommUtils.nullToBlank(cookieInfo.roomTypeIds);
        // 2019/01/15 タイムテーブルを開いた際、デフォルトで表示される部屋タイプを指定できるようにする by zy END
// 2016/11/04 部屋タイプは複数選択できる機能対応 END		
		//2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 by zy BEGIN
		ShopInfoUtil.ShopLeadInfo shopInfo = ShopInfoUtil.getShopDefInfo(branchShopNm);
		defaultCheckinTime = shopInfo.defCheckInTimeStr;
		defaultCheckoutTime = shopInfo.defCheckOtTimeStr;
		defStaysNums = shopInfo.defStayNums;
		//2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 by zy END
    }
    
  	// 支店選択リスト
	private Map<String,ShopInformation__c> shopInfoMap;
    public List<SelectOption> branchShopLst{get; private set;}
    public String branchShopNm{get; set;}
  	private void setInitBranShopLst() {
  		// 店舗リスト情報を取得する
    	// 2015/09/01 多店舗機能対応 BEGIN
        branchShopLst = ShopInfoUtil.getBranchShopLst(userInf.shops);
        shopInfoMap   = ShopInfoUtil.getShopInfoMap(userInf.shops);
        // 2015/09/01 多店舗機能対応 END
        // 店舗コードの初期値設定を行う
        // URLから店舗コードを設定されているの場合、該当設定値は初期値として、設定する
        if (ApexPages.currentPage().getParameters().containsKey('spcd')) {
        	branchShopNm = ApexPages.currentPage().getParameters().get('spcd');
        } else {
        // URLから店舗コードが未設定する場合、該当ユーザーに設定されている店舗コードで初期値設定
	        if (!branchShopLst.isEmpty()) {
	        	// 顧客に設定する支店で初期値に設定する[2013/06/30]
	        	String locShopCode = UserUtil.CurrentUser.ShopCode__c;
	        	// 2019/01/15 タイムテーブルを開いた際、デフォルトで表示される部屋タイプを指定できるようにする by zy BEGIN
	        	Set<String> spcdSet = new Set<String>();
	        	// 2019/01/15 タイムテーブルを開いた際、デフォルトで表示される部屋タイプを指定できるようにする by zy END
	        	for (SelectOption s : branchShopLst) {
	        		// 2019/01/15 タイムテーブルを開いた際、デフォルトで表示される部屋タイプを指定できるようにする by zy BEGIN
	        		spcdSet.add(s.getValue());
	        		// 2019/01/15 タイムテーブルを開いた際、デフォルトで表示される部屋タイプを指定できるようにする by zy END
	        		if (s.getValue() == locShopCode) branchShopNm = locShopCode;
	        	}
	        	// 2019/01/15 タイムテーブルを開いた際、デフォルトで表示される部屋タイプを指定できるようにする by zy BEGIN
				if (cookieInfo.spcd != null && spcdSet.contains(cookieInfo.spcd) || cookieInfo.spcd == '') branchShopNm = cookieInfo.spcd;
				// bug fix JINYABUG-1342
				if (cookieInfo.spcd != branchShopNm) cookieInfo.roomTypeIds = '';
				// 2019/01/15 タイムテーブルを開いた際、デフォルトで表示される部屋タイプを指定できるようにする by zy END
	        }
        }
    }

    // 2017/03/10 页面自动刷新功能  begin by wx 
    public string getRollTimerVal() {
    	if (!CommUtils.isBlank(branchShopNm) && shopInfoMap.containsKey(branchShopNm)) {
    		return CommUtils.nullToBlank(CommUtils.nullToIntZero(shopInfoMap.get(branchShopNm).RoomScheduleTimerMinute__c));
    	}
    	return CommUtils.nullToBlank(CommUtils.nullToIntZero(CommDefine__c.getOrgDefaults().RoomScheduleTimerMinute__c));
    }
    // 2017/03/10 页面自动刷新功能  end by wx 
    //
    // 表示モード制御情報
    // processDate	: 画面の指定日
    // viewMode		: 画面制御モード	
    //						３０日間
   	//						９０日間
   	//						一週間
   	//						１日間
    // timeMode		: 画面時間制御モード
    //						１日間ー＞５分単位
    //						１日間ー＞１０分単位
    //						１日間ー＞３０分単位
    private TimeModel initTimeModelMap(Date processDate, String viewMode) {
    	// 画面制御情報を初期化する
    	gModeInfo = new TimeModel(processDate, viewMode);
        return gModeInfo;
    }
    
    // -------------------------
    // 情報取得処理を行う
    // -------------------------
    public void doAction(){
		// 処理開始日取得
		Date startDt = timeTable.Checkinday__c;
		// 画面制御変数を設定する
		initTimeModelMap(startDt, viewMode);
		// Table Header Info
        setDispHeaders();
        // 情報を検索を行う
        queryData();
        // 選択値はCOOKIEへ反映する
		// 2017/02/14	画面モードと予約ステータス/部屋ステータス表示の切替显示対応 BEGIN zyz
        //setCookieInf(new CookieInf(viewMode));
        setCookieInf();
		// 2017/02/14	画面モードと予約ステータス/部屋ステータス表示の切替显示対応 END zyz
    }
    
    // 初期処理
    public void init() {
        doAction();
    }
     public Boolean isShowTierHeader {get{
    	// 支店あり、全店舗を選べる場合、TIERのHeader情報を非表示する
    	return !(CommUtils.isBlank(branchShopNm) && branchShopLst.size() > 0);
    }}

    // 2015/12/11 FIX BEGIN
    //通常
	private String CONST_NORMAL_HOTEL = Label.CONST_005_0086;								// 默认状态
    private String CONST_NORMAL_COLOR = 'black';							// 默认颜色
    private String CONST_NORMAL_OTCOLOR = 'red';							// 非默认颜色
    private String getNoramlStatus() {return CONST_NORMAL_HOTEL;}
    public transient Map<String, String> restInfoMap{get; private set;}		// status map
    public transient Map<String, String> colorInfoMap{get; private set;}	// color map
    // また、人数とプランも一つの予約データのみに取り込み、他の予約データは、人数ゼロ、プランなし、と設定する
	public String strRoomDelegatePrefix {get{ return CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomDelegatePrefix__c);}}
    private void queryRestHotelInfo(Date dt) {
    	// 支店は未指定 && 支店リストはが存在する場合
    	if (!isShowTierHeader) return;

    	// 获取共同定义设定
    	Map<String, String> statusColorMap = new Map<String, String>();
        String roomTSS = CommConst.APPOTION_DEF_ROOMTYPE_SALESTATUS();
        Set<String> roomTSSSet = new Set<String>();
        // 解析共通定义设置
        if (!String.isEmpty(roomTSS)) {
        	String[] roomLst = roomTSS.split(',');
        	for (String key : roomLst) {
        		String[] subKey = key.split(':');
        		// 默认状态
        		if (subKey.size() > 1) CONST_NORMAL_HOTEL = subKey[0];
				else roomTSSSet.add(subKey[0].split(';')[0]);
				String[] colorKey = key.split(';');
				// 存在颜色设置
				if (colorKey.size() > 1) statusColorMap.put(subKey[0].split(';')[0], colorKey[1]);
        	}
        }
        // 添加默认Status颜色
       	if (!statusColorMap.containsKey(CONST_NORMAL_HOTEL)) statusColorMap.put(CONST_NORMAL_HOTEL, CONST_NORMAL_COLOR);

    	Date firstDay = dt;
    	Date endDay;
    	// 画面结束日期
    	if(viewMode == CONST_VIEWMODE_1) endDay = dt.addDays(31);
    	if(viewMode == CONST_VIEWMODE_2) endDay = dt.addDays(7);
    	if(viewMode == CONST_VIEWMODE_3) endDay = dt.addDays(90);
    	// 2018/05/01 タイムテーブル、15 分刻みの追加 by zy BEGIN
    	if(viewMode == CONST_VIEWMODE_4 || viewMode == CONST_VIEWMODE_5 || viewMode == CONST_VIEWMODE_6 || viewMode == CONST_VIEWMODE_7) endDay = firstDay.addDays(1);
    	// 2018/05/01 タイムテーブル、15 分刻みの追加 by zy END
    	// 画面期間範囲の 休館/全館貸切 情報を取得する
		List<RoomsStatus__c> roomsStatus = [select id, Status__c, StatusBeginDate__c, StatusEndDate__c from RoomsStatus__c
												where (Status__c in : roomTSSSet)
												And StatusBeginDate__c <= :endDay And StatusEndDate__c >= :firstDay
												And (
												   RoomRef__r.ShopInfoRef__r.ShopCode__c = :branchShopNm
												OR RoomRef__r.TypeRoomRef__r.ShopInfoRef__r.ShopCode__c = :branchShopNm
												)];
		restInfoMap = new Map<String, String>();
		colorInfoMap = new Map<String, String>();

		Date whStartDate = firstDay;
		// 初始化画面期间Map
		while (whStartDate <= endDay) {
			restInfoMap.put(whStartDate.format(), getNoramlStatus());
			colorInfoMap.put(whStartDate.format(), statusColorMap.get(CONST_NORMAL_HOTEL));

			whStartDate = whStartDate.adddays(1);
			if (whStartDate > endDay) break;
		}
		// 设置画面期间Map
		for (RoomsStatus__c status : roomsStatus) {
			Date loopStart = status.StatusBeginDate__c;
			Date loopEnd   = status.StatusEndDate__c;
			while (loopStart <= loopEnd) {
				restInfoMap.put(loopStart.format(), status.Status__c);
				if (statusColorMap.containsKey(status.Status__c)) colorInfoMap.put(loopStart.format(), statusColorMap.get(status.Status__c));
				else if(status.Status__c != CONST_NORMAL_HOTEL) {
					colorInfoMap.put(loopStart.format(), CONST_NORMAL_OTCOLOR);
				}
				loopStart = loopStart.adddays(1);
				if (loopStart > loopEnd) break;
			}
		}
    }
    // 2015/12/11 FIX END
    /**
    * 既存予約情報を取得して、画面表示用情報を作成する
    **/
    private void queryData() {

		// 取得するデータの正確性チェックを行う
		showInfoError = '';
		showInfoWarn = '';
		//部屋color
 		// １部屋予約情報を格納する<ルームID, 該当部屋にアサインの予約情報>
        roomBookingMap = new Map<Id, OneRoomAssingInfo>();
     
        // 既存の有効予約情報を取得する
        List<Lead__c> leads = getLeads();
        // 部屋単位、予約情報は配列に格納する
/*
System.debug(LoggingLevel.ERROR, 'leads:::' + leads);
System.debug(LoggingLevel.ERROR, 'startTime:::' + gModeInfo.beginTime.format());
System.debug(LoggingLevel.ERROR, 'endTime:::' + gModeInfo.lastTime.format());
*/
        // 開始日
        Date conStartDate = gModeInfo.beginDate.addDays(-1);
        // 終了日
        Date conEndDate = gModeInfo.lastDate.addDays(1);
        
		Map<String,Map<String,List<LongTdInfo>>> roomLongInfMap = new Map<String,Map<String,List<LongTdInfo>>>();
		showInfoWarn = setupLeadsToTdInfo(roomLongInfMap,leads,conStartDate,conEndDate,gModeInfo,leadStatusColorMap,statusColor,branchShopNm);
        integer cycInt = CommUtils.nullToZero(roomInt);
        integer roomIdx = 0;
        // 部屋単位に、アサイン情報を格納する
        for (List<Id> rooms : roomList) {
        	for (Id roomId : rooms) {
	        	// 該当部屋に予約情報が未存在する場合
	        	Map<String,List<LongTdInfo>> oneRoomLeads = roomLongInfMap.get(roomId); 
	        	if (oneRoomLeads == null) oneRoomLeads = new Map<String,List<LongTdInfo>>();
				// 部屋単位に格納した予約情報はInnerクラスに初期化する
		// 2016/03/21 UI効率改善 BEGIN
                if(cycInt > 0 )roomBookingMap.put(roomId, new OneRoomAssingInfo(oneRoomLeads, gModeInfo, allColUnitInfo.size(),statusCode));
                else roomBookingMap.put(roomId, new OneRoomAssingInfo());
                cycInt--;
                roomIdx++;
		// 2016/03/21 UI効率改善 END
        	} // End for (Room__c r : rooms)
        } // End for (List<Room__c> rooms : roomList)
        hadNeedLoadFlag = roomIdx > CommUtils.nullToZero(roomInt);
        // エラー情報チェックを行う
        for (OneRoomAssingInfo inf : roomBookingMap.values()) {
        	String errMsg = inf.checkTimeRange();
        	if (!CommUtils.isBlank(errMsg)) {
        		showInfoError += errMsg;
        	}
        }
		// 2015/12/11 FIX BEGIN
        queryRestHotelInfo(timeTable.Checkinday__c);
		// 2015/12/11 FIX END
    }
    
    // 支店選択リスト変更の場合、関連の支店所属する部屋を取得、情報を表示する
    public void refreshBranchShopInfo() {
    	// 2019/01/15 タイムテーブルを開いた際、デフォルトで表示される部屋タイプを指定できるようにする by zy BEGIN
    	cookieInfo.changeSpcd(branchShopNm);
    	// 2019/01/15 タイムテーブルを開いた際、デフォルトで表示される部屋タイプを指定できるようにする by zy END
    	// 部屋タイプリスト連動
    	setInitRoomTypeLst();
        // 表示用部屋リストを取得する
        roomList = getGuestRooms();
        // 色表示の制御設定
        initColorInfo();
        // 最新情報を取得する
        queryData();
        bookingCreateOK = false;
        // 2017/01/25 新規画面の項目自定義機能 by zy BEGIN
        loadInsertWindow();
        // 2017/01/25 新規画面の項目自定義機能 by zy END
        //  2016/12/29 连接plan页面替换标准页面  begin by wx
        planName = '';
        //  2016/12/29 连接plan页面替换标准页面  end by wx
        // 2016/11/21 店铺切换初始化 BEGIN by zh
        contactName = '';
        newContact = new Contact();
        newLead = initLeadInfo();
        // 2016/11/21 店铺切换初始化 END by zh
    }
    // 部屋タイプ変更に従って、指定している部屋タイプ情報を再検索する
    public void refreshTypeOfRoomInfo() {
        // 表示用部屋リストを取得する
        roomList = getGuestRooms();
        // 最新情報を取得する
        queryData();
        bookingCreateOK = false;
    }
    
    // *******************************
    // 予約新規作成機能
    // *******************************
    public PageReference bookingCreate() {
    	// 事前チェックを行う
		if (!preBookingCreate()) {
			doAction();
			return null;
		}
		// 2018/03/07 Security Check BEGIN
		List<String> insChkFields = new List<String>{'EventSource__c','Segment__c','Rooms__c','Nights__c','EntryTime__c',
													'EntryDate__c','DepartureTime__c','DepartureDate__c','Channel__c',
													'Comment__c','Payment__c','LeadName__c','contactRef__c'};
		Map<String,Schema.SObjectField> insm = Schema.SObjectType.LeadIndex__c.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(insChkFields, insm)) {
			return null;
		}
		// 2018/03/07 Security Check END
    	// Hidden項目から到着日を取得する
		// 2016/01/20 Golbal対応するため、日付変換は共通関数に変換する BEGIN
		//Date defaultDate = Date.parse(startDays);
		Date defaultDate = CommUtils.stringToDate(startDays);
		// 2016/01/20 Golbal対応するため、日付変換は共通関数に変換する END
  		/* 2013/01/21 到着時間と出発時間、設定によて、自動取得、設定を行う */
        Datetime defCheInDt = Datetime.newInstance(defaultDate, converHHMMtoTime(newLead.Field4__c));
        Datetime defCheOutDt = Datetime.newInstance(defaultDate.addDays(1), converHHMMtoTime(newLead.Field3__c));
    	
    	// 2013/10/07お客様情報を自動登録機能追加する
  		upsertContact();
		// ----------------------
  		// 予約の内容を作成する
  		// ----------------------
  		// 予約情報変数格納
  		List<Lead__c> insList = new List<Lead__c>();
        Map<String,List<String>> roomIdandRoomType = new Map<String,List<String>>();
  	    // 選べる部屋リスト[RoomId_RoomTypeId]
		String[] roomMsg = roomIds.split(',');
		Integer leadCount = 0;
		String roomArr = '';
       	for(string key : roomMsg) {	
        	if(CommUtils.isBlank(key)) continue;
        	
            String[] msg = key.deleteWhitespace().split('_');
			if (msg.size() < 2) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '部屋の部屋タイプを設定されないため、ご予約を登録できません。'));
				return null;
			}
            if(!roomIdandRoomType.containsKey(msg[1])) {
                roomIdandRoomType.put(msg[1], new  List<String>());
            }
            roomIdandRoomType.get(msg[1]).add(msg[0]);
            roomArr += msg[0] + ',';
            leadCount ++ ;
        }

  		// DB操作を行う
	  	Savepoint sp = Database.setSavepoint();
  		try{
  			Map<String,LeadIndex__c> typeByIndexMap = new Map<String,LeadIndex__c>();
  			
  			// 予約インデックス情報を作成する 2012/08/23 ADD BEGIN
	    	LeadIndex__c newLeadIndex = new LeadIndex__c();
	    	newLeadIndex.EntryDate__c = defCheInDt.date();
	    	newLeadIndex.EntryTime__c = defCheInDt.format('HH:mm');
	        newLeadIndex.DepartureDate__c = defCheInDt.addDays(staysNums).date();
	        newLeadIndex.DepartureTime__c = defCheOutDt.format('HH:mm');
	    	// 顧客ID + RandomID
	    	// 2012/12/20 -> Null Setup
	    	newLeadIndex.contactRef__c = newLead.Relcontact__c;
			newLeadIndex.EventSource__c = 'FromUI';
			newLeadIndex.Nights__c = staysNums;
			newLeadIndex.Rooms__c = roomMsg.size();
			newLeadIndex.LeadName__c = newLead.name;
			//newLeadIndex.RoomTypeRef__c = key;	// 部屋タイプ
			// 予約チャネル
			newLeadIndex.Channel__c = newLead.Field2__c;
			// セグメント
			newLeadIndex.Segment__c = newLead.Segment__c;
			// 支払方法
			newLeadIndex.Payment__c = newLead.Field315__c;
			// 特記事項
			newLeadIndex.Comment__c = newLead.Comment3__c;
  			
  			insert newLeadIndex;
  			// 2016/12/07 タイムテーブル新規後一画面へ遷移 BEGIN by zh
  			// 按ctrl多选房间 一画面へ遷移 fix by zh BEGIN
	        indexId = newLeadIndex.Id;
	        // 按ctrl多选房间 一画面へ遷移 fix by zh END
	        // 2016/12/07 タイムテーブル新規後一画面へ遷移 END by zh
  			if(!CommUtils.isBlank(MoreRoomMessage)){
  				insertLeadByMoreTimeRoom(insList,newLeadIndex);
  			}else{
  			// RoomTypeのIDリスト
  			List<String> roomTypeIdlst = new List<String>();
  			roomTypeIdlst.addAll(roomIdandRoomType.keySet());
  			// LeadIndex Sub作成
  			if(!roomTypeIdlst.isEmpty()){
  				
  				List<LeadIndex__c> newLeadIndexs = new List<LeadIndex__c>();
  				
	  			//for(String key : roomIdandRoomType.keySet())
				for (Integer idx =0; idx < roomTypeIdlst.size() ; idx++)		
	  			{
	  				String key = roomTypeIdlst[idx];
	  				// 予約インデックス情報を作成する 2012/08/23 ADD BEGIN
			    	LeadIndex__c nwSub = new LeadIndex__c();
		            nwSub.ParentLeadIndxRef__c = newLeadIndex.Id;
		            // エキストラベッド(E/B)
		            nwSub.ExtraBedChk__c = newLead.ExtraBedChk__c;
		            //2017/04/25 親部屋subindex設定する　by zy BEGIN
			        //nwSub.PlanRef__c = newLead.Field310__c;
			        //2017/04/25 親部屋subindex設定する　by zy END
		            nwSub.Nights__c = newLeadIndex.Nights__c;
		            nwSub.Rooms__c = roomIdandRoomType.get(key).size();
		            nwSub.RoomTypeRef__c = key;
		            nwSub.DepartureDate__c = newLeadIndex.DepartureDate__c;
		            nwSub.EntryDate__c = newLeadIndex.EntryDate__c;
		            nwSub.contactRef__c = newLeadIndex.contactRef__c;
		            // 出発時刻と到着時刻設定追加
		            nwSub.EntryTime__c = newLeadIndex.EntryTime__c;
		            nwSub.DepartureTime__c = newLeadIndex.DepartureTime__c;
		            nwSub.LeadName__c = newLeadIndex.LeadName__c;
					// 支払方法
					nwSub.Payment__c = newLeadIndex.Payment__c;
					// 特記事項
					nwSub.Comment__c = newLeadIndex.Comment__c;
					// 予約分割で設定する場合、人数は平均にアサインする
		            if (idx == 0 || CommConst.APPOTION_LEADSPLIT_DIV_CODE == CommConst.APPOTION_LEADSPLIT_DIV_CODE_SPLIT) {
		            	nwSub.StayPersons__c = newLead.StayPersons__c;
		            	//2017/04/25 親部屋subindex設定する　by zy BEGIN
			            nwSub.PlanRef__c = newLead.Field310__c;
			            //2017/04/25 親部屋subindex設定する　by zy END
		            } else {
		            	nwSub.StayPersons__c = 0;
		            }
					// 2019/11/15 一括予約画面の部屋直接選択 by zy BEGIN
					if (Commconst.BOOKING_FLEX_SEL_ROOM_FLG) {
						// 2020/03/31 ご予約3点以上の場合、エラー発生の修正 by zy BEGIN
						integer roomIdx = Commutils.nulltointZero(nwSub.Rooms__c);
						for (integer i = 0 ; i < roomIdx; i++) {
						// 2020/03/31 ご予約3点以上の場合、エラー発生の修正 by zy END
							String idxKey = key + '_' + i;
							nwSub.Rooms__c = 1;
							LeadIndex__c ldx = nwSub.clone(false,false);
							newLeadIndexs.add(ldx);
							typeByIndexMap.put(idxKey,ldx);
						}
					} else {
						newLeadIndexs.add(nwSub);
						typeByIndexMap.put(key,nwSub);
					}
					// 2019/11/15 一括予約画面の部屋直接選択 by zy END
	  			}	
				insert newLeadIndexs;
  			}
  			// 2016/12/07 タイムテーブル新規後一画面へ遷移 BEGIN by zh
		    //indexId = newLeadIndex.Id;
		    // 2016/12/07 タイムテーブル新規後一画面へ遷移 END by zh
  			// 予約名設定する
  			String leadName = newLead.name;
  			// また、人数とプランも一つの予約データのみに取り込み、他の予約データは、人数ゼロ、プランなし、と設定する
  	    	String strRoomDelegatePrefix = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomDelegatePrefix__c);
			// 自動設定内容
			// 受付日
			newLead.ReservedDate__c = System.now();
			// 受付者
			newLead.ReservedContact__c = UserInfo.getName();
			
			// 日帰り場合
			if (staysNums == 0) {
	  			newLead.EntryTime__c = defCheInDt.addDays(0);
		  		newLead.Departure__c = Datetime.newInstance(defCheInDt.date(), converHHMMtoTime(newLead.Field3__c));
				//for(String roomType : roomIdandRoomType.keySet())
				for (Integer idx = 0; idx < roomTypeIdlst.size() ; idx++)
				{
					String roomType = roomTypeIdlst[idx];
					
					List<String> roomIdLst = roomIdandRoomType.get(roomType);
        			// 予約情報関連設定
					newLead.LeadIndexRef__c = newLeadIndex.Id;
					// 2019/11/15 一括予約画面の部屋直接選択 by zy BEGIN
					if (Commconst.BOOKING_FLEX_SEL_ROOM_FLG) newLead.LeadIndexSubId__c = typeByIndexMap.get(roomType + '_0').Id;
					else newLead.LeadIndexSubId__c = typeByIndexMap.get(roomType).Id;	
					// 2019/11/15 一括予約画面の部屋直接選択 by zy END
					
					newLead.refTypeOfRooms__c = roomType;
		  			for(Integer j = 0; j < roomIdLst.size(); j ++ ){
		  				Lead__c cloneLead =  newLead.clone(false, true);
		  			   	// 2013/07/20 UPDATE
		  			   	cloneLead.RoomGroupNo__c = j;
		  			   	cloneLead.Rroom__c = roomIdLst[j];
						// 2019/11/15 一括予約画面の部屋直接選択 by zy BEGIN
						if (Commconst.BOOKING_FLEX_SEL_ROOM_FLG) {
							String key = roomType + '_' + j;
							cloneLead.LeadIndexSubId__c = typeByIndexMap.get(key).Id;
						}
						// 2019/11/15 一括予約画面の部屋直接選択 by zy END
		  			   	if(idx ==0 && j == 0) cloneLead.name = (leadCount > 1 ? strRoomDelegatePrefix : '') + cloneLead.name;
						else setLeadValue(cloneLead);
		  				insList.add(cloneLead);
		  			}
				}
			} else {
				//for(String roomType : roomIdandRoomType.keySet())
				for (Integer idx =0; idx < roomTypeIdlst.size() ; idx++)
				{
					String roomType = roomTypeIdlst[idx];
					
					List<String> roomIdLst = roomIdandRoomType.get(roomType);
					LeadIndex__c leadIndex = typeByIndexMap.get(roomType);		// SubIndex
					// 2019/11/15 一括予約画面の部屋直接選択 by zy BEGIN
					if (Commconst.BOOKING_FLEX_SEL_ROOM_FLG) leadIndex = typeByIndexMap.get(roomType + '_0');	
					// 2019/11/15 一括予約画面の部屋直接選択 by zy END
        			// 予約情報関連設定
					newLead.LeadIndexRef__c = newLeadIndex.Id;
					newLead.LeadIndexSubId__c = leadIndex.Id;
					newLead.refTypeOfRooms__c = roomType;
					// 1泊以上場合
			  		for(Integer i = 0; i < staysNums; i ++){
                    	//泊目
                        //if (staysNums > 1) newLead.name = String.valueOf(staysNums) + '-' + (i+1) + '泊目 ' + leadName;
                        if (staysNums > 1) newLead.name = String.valueOf(staysNums) + '-' + (i+1) + Label.CONST_005_0087 + ' ' + leadName;
			  			newLead.EntryTime__c = defCheInDt.addDays(i);
			  			newLead.Departure__c = defCheOutDt.addDays(i);
			  			// 到着時刻
			  			newLead.Field4__c = leadIndex.EntryTime__c;//newLead.EntryTime__c.format('HH:mm');
			  			// 出発時刻
			  			newLead.Field3__c = leadIndex.DepartureTime__c;//newLead.Departure__c.format('HH:mm');
			  			for(Integer j = 0; j < roomIdLst.size(); j ++ ){
			  			   	Lead__c cloneLead =  newLead.clone(false, true);
				  			// 2013/07/20 UPDATE
				  			cloneLead.RoomGroupNo__c = j;
				  			cloneLead.Rroom__c = roomIdLst[j];
							// 2019/11/15 一括予約画面の部屋直接選択 by zy BEGIN
							if (Commconst.BOOKING_FLEX_SEL_ROOM_FLG) {
								String key = roomType + '_' + j;
								cloneLead.LeadIndexSubId__c = typeByIndexMap.get(key).Id;
							}
							// 2019/11/15 一括予約画面の部屋直接選択 by zy END
				  			// 2014/09/01 BugFix
				  			//if(idx ==0 && i == 0 && j == 0) cloneLead.name = (leadCount > 1  ? strRoomDelegatePrefix : '') +  cloneLead.name;
				  			if(idx ==0 && j == 0) cloneLead.name = (leadCount > 1  ? strRoomDelegatePrefix : '') +  cloneLead.name;
				  			else setLeadValue(cloneLead);
				  			insList.add(cloneLead);
			  			}
			  		}
				}
			}
  			}
  			// 2012/12/22 WSQ ADD
  			// SUBINDEX自動作成
//  			CommLogicProcess logic = new CommLogicProcess();
//  			logic.autoCreateIndexSub(insList);
  			// データの更新
//  			update updList;
  			// データの挿入
  			insert insList;
  			// 料金表情報にて、予約情報見積もり明細自動設定を行う
  			autoCreateBookingEstItems(insList, newLeadIndex.EntryDate__c,newLeadIndex.DepartureDate__c);
	  		//}
  		}catch (Exception e){
  			// 2015/10/29 故障部屋など項目有効性エラーが発生する場合、エラーメッセージ表示改善対応 BEGIN
  			//ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
system.debug(logginglevel.info,'message::::' + e.getStackTraceString());
			String errMsg = e.getMessage();
			if(!CommUtils.isFieldValidationMessage(errMsg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CommUtils.getFieldValidationMessage(errMsg)));
  			// 2015/10/29 故障部屋など項目有効性エラーが発生する場合、エラーメッセージ表示改善対応 END
            Database.rollback(sp);
            bookingCreateOK = false;
            return null;
  		}
  		roomIds = roomArr;
  		// 2013/06/24 ADD BEGIN
  		// Data Create OK
  		bookingCreateOK = true;
  		// 設定情報をクリアする【注意：クリアしないと、常にContact　IDを更新されない】
  		newContact = new Contact();
  		//newLead = new Lead__c();
  		newLead = initLeadInfo();
  		// 情報再構築
  		doAction();
    	return null;
    }
    private void insertLeadByMoreTimeRoom(List<Lead__c> mainLeadLst,LeadIndex__c newLeadIndex){
    	// 2018/03/07 Security Check BEGIN
		List<String> insChkFields = new List<String>{'Rooms__c','RoomTypeRef__c','Nights__c','EntryTime__c','EntryDate__c',
													'DepartureTime__c','DepartureDate__c','contactRef__c','StayPersons__c','PlanRef__c',
													'Payment__c','ParentLeadIndxRef__c','EventSource__c','LeadName__c','ExtraBedChk__c',
													'Comment__c'};
		Map<String,Schema.SObjectField> insm = Schema.SObjectType.LeadIndex__c.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(insChkFields, insm)) {
			return;
		}
		// 2018/03/07 Security Check END
    	Map<String,List<String>> moreRoomKeyMap = getRoomMessage();
    	Map<String,List<String>> typeLeadMap = new Map<String,List<String>>();
  		Integer leadCount = 0;
//system.debug(logginglevel.info,'moreRoomKeyMap:::' + moreRoomKeyMap);
        Set<String> roomIdSet = new Set<String>();
  		// RoomTypeのIDリスト
  		List<Map<String,List<LeadIndex__c>>> groupSubIdxMapLst = new List<Map<String,List<LeadIndex__c>>>();
  		//2016/11/15 親部屋の設定のエラー修正　BEGIN
		Id mainRoom = Id.valueOf(mainRoomId);
		//2016/11/15 親部屋の設定のエラー修正　END
		// 2018/01/26 予約人數が０の場合、登録の明細は見積明細へ反映できない by zy BEGIN
		List<Lead__c> insList = new List<Lead__c>();
		// 2018/01/26 予約人數が０の場合、登録の明細は見積明細へ反映できない by zy END
  		// LeadIndex Sub作成
  		if(!moreRoomKeyMap.isEmpty()){
  			List<LeadIndex__c> newLeadIndexs = new List<LeadIndex__c>();
  			integer idx = 0;
  			for (String key : moreRoomKeyMap.keySet()) {
  				List<String> meLst = moreRoomKeyMap.get(key);
  				Integer stayRooms = meLst.size();
  				// 予約インデックス情報を作成する 2012/08/23 ADD BEGIN
  				LeadIndex__c nwSub = new LeadIndex__c();
  				nwSub.ParentLeadIndxRef__c = newLeadIndex.Id;
	            // エキストラベッド(E/B)
	            nwSub.ExtraBedChk__c = newLead.ExtraBedChk__c;
	            nwSub.PlanRef__c = newLead.Field310__c;
	            nwSub.contactRef__c = newLeadIndex.contactRef__c;
	            nwSub.LeadName__c = newLeadIndex.LeadName__c;
				// 支払方法
				nwSub.Payment__c = newLeadIndex.Payment__c;
				// 特記事項
				nwSub.Comment__c = newLeadIndex.Comment__c;
				//2017/04/25 親部屋subindex設定する　by zy BEGIN
				// 予約分割で設定する場合、人数は平均にアサインする
	            if (CommConst.APPOTION_LEADSPLIT_DIV_CODE == CommConst.APPOTION_LEADSPLIT_DIV_CODE_SPLIT) {
	            	nwSub.StayPersons__c = newLead.StayPersons__c;
	            } else {
	            	nwSub.StayPersons__c = 0;
	            }
	             //2017/04/25 親部屋subindex設定する　by zy END
	            Map<String,List<LeadIndex__c>> roomIdToIndexMap = new Map<String,List<LeadIndex__c>>();
	            for (integer i = 0 ; i < meLst.size() ; i++) {
					String message =  meLst[i];           	
  					String typeId = message.substringBefore('_');
  					String afMessage = message.substringAfter('_');
  					String roomId = afMessage.substringAfterLast('_');
  					List<String> timeLst = afMessage.substringBeforeLast('_').split('_');
//System.debug(logginglevel.info,'timeLst:::' + timeLst[0]);
  					Date entryDate = CommUtils.stringToDate(timeLst[0]);
  					Date depertDate = CommUtils.stringToDate(timeLst[2]);
  					//Datetime entryDt = DateTime.newInstance(Long.valueOf(timeLst[0]));
  					//DateTime.parse();DateTime.parse(timeLst[1]); 
			        //Datetime depDt = DateTime.newInstance(Long.valueOf(timeLst[1]));
  					LeadIndex__c cloneSub = nwSub.clone(false,false);
  					//2016/12/31 部屋数エラー by zy BEGIN
  					cloneSub.Rooms__c = 1;
  					//2016/12/31 部屋数エラー by zy END
					cloneSub.RoomTypeRef__c = typeId;
					cloneSub.Nights__c = entryDate.daysBetween(depertDate);
		            cloneSub.EntryDate__c = entryDate;
		            cloneSub.DepartureDate__c = depertDate;
		            // 出発時刻と到着時刻設定追加
		            cloneSub.EntryTime__c = timeLst[1];
		            cloneSub.DepartureTime__c = timeLst[3];
		            //2017/04/25 親部屋subindex設定する　by zy BEGIN
		           	if (mainRoom != roomId) {
		           		//2017/04/25 親部屋subindex設定する　by zy BEGIN
		           		if (CommConst.APPOTION_LEADSPLIT_DIV_CODE != CommConst.APPOTION_LEADSPLIT_DIV_CODE_SPLIT)
		           		//2017/04/25 親部屋subindex設定する　by zy END
		           		cloneSub.PlanRef__c = null;
		           	} else {
			            cloneSub.StayPersons__c = newLead.StayPersons__c;
			            // 2018/01/26 予約人數が０の場合、登録の明細は見積明細へ反映できない by zy BEGIN
			            cloneSub.ParentFlg__c = true;
			            // 2018/01/26 予約人數が０の場合、登録の明細は見積明細へ反映できない by zy END
		           	}
		           	//2017/04/25 親部屋subindex設定する　by zy END
					if(!roomIdToIndexMap.containsKey(roomId)) roomIdToIndexMap.put(roomId,new List<LeadIndex__c>());
	  				roomIdToIndexMap.get(roomId).add(cloneSub);
					newLeadIndexs.add(cloneSub);
					roomIdSet.add(roomId);
  				}
  				groupSubIdxMapLst.add(roomIdToIndexMap);
  				idx++;
  			}
			insert newLeadIndexs;
  			// 予約名設定する
  			String leadName = newLead.name;
			// 自動設定内容
			// 受付日
			newLead.ReservedDate__c = System.now();
			// 受付者
			newLead.ReservedContact__c = UserInfo.getName();	
			//2017/04/25 親部屋subindex設定する　by zy BEGIN
			//2016/11/15 親部屋の設定のエラー修正　BEGIN
			//Id mainRoom = Id.valueOf(mainRoomId);
			//2016/11/15 親部屋の設定のエラー修正　END
			//2017/04/25 親部屋subindex設定する　by zy END
			for (Map<String,List<LeadIndex__c>> subMap : groupSubIdxMapLst) {
				Integer roomIdx = 0;
				for (String roomId : subMap.keySet()) {
					List<LeadIndex__c> subLst = subMap.get(roomId);
					// 2018/01/26 予約人數が０の場合、登録の明細は見積明細へ反映できない by zy BEGIN
					boolean mainKey = mainRoom == Id.valueOf(roomId);
					// 2018/01/26 予約人數が０の場合、登録の明細は見積明細へ反映できない by zy END
					for (integer i = 0 ; i < subLst.size() ; i++ ) {
						LeadIndex__c sub = subLst[i];
						// 予約情報関連設定
						newLead.LeadIndexRef__c = newLeadIndex.Id;
						newLead.LeadIndexSubId__c = sub.Id;
						newLead.refTypeOfRooms__c = sub.RoomTypeRef__c;
						// 到着時刻
			  			newLead.Field4__c = sub.EntryTime__c;//newLead.EntryTime__c.format('HH:mm');
			  			// 出発時刻
			  			newLead.Field3__c = sub.DepartureTime__c;//newLead.Departure__c.format('HH:mm');
			  			//system.debug(logginglevel.info,'sub.Nights__c:::' + sub.Nights__c);
			  			//system.debug(logginglevel.info,'sub:::' + sub);
			  			//予約時間不正　修正　BEGIN
			  			Datetime orgEntryTime = DateTime.newInstance(sub.EntryDate__c,CommUtils.objectToTime(newLead.Field4__c));
					  	Datetime orgDepartTime = DateTime.newInstance(sub.EntryDate__c,CommUtils.objectToTime(newLead.Field3__c));
						if(sub.Nights__c == 0){
							newLead.EntryTime__c = orgEntryTime;
					  		newLead.Departure__c = orgDepartTime;
				  			Lead__c cloneLead =  newLead.clone(false, true);
			  			   	// 2013/07/20 UPDATE
			  			   	cloneLead.RoomGroupNo__c = idx;
			  			   	cloneLead.Rroom__c = roomId;
			  			   	//if(roomIdx ==0 && i == 0) cloneLead.name = (leadCount > 1 ? strRoomDelegatePrefix : '') + cloneLead.name;
			  			   	//2016/11/15 親部屋の設定のエラー修正　BEGIN
			  			    if(mainRoom == Id.valueOf(roomId)) {
			  			    	cloneLead.name = strRoomDelegatePrefix + cloneLead.name;
			  			    }
			  			    //2016/11/15 親部屋の設定のエラー修正　END
							else if (mainRoom != Id.valueOf(roomId)  ) setLeadValue(cloneLead);
							// 2018/01/26 予約人數が０の場合、登録の明細は見積明細へ反映できない by zy BEGIN
							if(mainKey) mainLeadLst.add(cloneLead);
			  				else insList.add(cloneLead);
			  				// 2018/01/26 予約人數が０の場合、登録の明細は見積明細へ反映できない by zy END
						} else {
							// 1泊以上場合
				  			for(Integer j = 0; j < sub.Nights__c; j ++){
				  				Lead__c cloneLead =  newLead.clone(false, true);
				  				//if (sub.Nights__c > 1) cloneLead.name = String.valueOf(sub.Nights__c) + '-' + (j+1) + Label.CONST_005_0087 + ' ' + leadName;
					  			if( sub.Nights__c > 1) cloneLead.name = String.valueOf(sub.Nights__c) + '-' + (j+1) + Label.CONST_005_0087 + ' ' + leadName;
					  			//2016/11/15 親部屋の設定のエラー修正　BEGIN
					  			if( mainRoom == Id.valueOf(roomId) ) {
					  				cloneLead.name = strRoomDelegatePrefix + cloneLead.name;
					  			}
					  			//2016/11/15 親部屋の設定のエラー修正　END
					  			cloneLead.EntryTime__c = orgEntryTime.addDays(j);
					  			cloneLead.Departure__c = orgDepartTime.addDays(j+1);
				  				//予約時間不正　修正　END
					  			// 2013/07/20 UPDATE
					  			cloneLead.RoomGroupNo__c = roomIdx;
					  			cloneLead.Rroom__c = roomId;
					  			// 2014/09/01 BugFix
					  			//if(idx ==0 && i == 0 && j == 0) cloneLead.name = (leadCount > 1  ? strRoomDelegatePrefix : '') +  cloneLead.name;
					  			if(mainRoom != Id.valueOf(roomId) ) setLeadValue(cloneLead);
					  			else if(roomIdx == 0 && i == 0) cloneLead.name = (leadCount > 1  ? strRoomDelegatePrefix : '') +  cloneLead.name;
					  			// 2018/01/26 予約人數が０の場合、登録の明細は見積明細へ反映できない by zy BEGIN
					  			// insList.add(cloneLead);
								if(mainKey) mainLeadLst.add(cloneLead);
				  				else insList.add(cloneLead);
				  				// 2018/01/26 予約人數が０の場合、登録の明細は見積明細へ反映できない by zy END
							}
						}
					}
					roomIdx++;
				}
			}
			// 2018/01/26 予約人數が０の場合、登録の明細は見積明細へ反映できない by zy BEGIN
			mainLeadLst.addAll(insList);
  			// 2018/01/26 予約人數が０の場合、登録の明細は見積明細へ反映できない by zy END
			//roomIds = '';
//system.debug(logginglevel.info,'insList:::' + insList);
			//for (String roomId : roomIdSet)  roomIds += roomId + ',';
  		}
    }
    // 親部屋集める処理機能関連処理 
	private void setLeadValue( Lead__c cloneLead){
		// 予約データの分割に登録する
		if (CommConst.APPOTION_LEADSPLIT_DIV_CODE == CommConst.APPOTION_LEADSPLIT_DIV_CODE_SPLIT) return;
		// 親部屋に集めるの場合、下記処理を行う
 		cloneLead.Comment3__c = null;
 		 // 代表部屋以外のデータ
 	    cloneLead.StayPersons__c = 0;
	    // 大人人員(男性)
	    cloneLead.Mans__c = 0;
		// 大人人員(女性)
		cloneLead.Femails__c = 0;
		// 子供A人数
	    cloneLead.ChildFA__c = 0;
		 // 子供B人数
		cloneLead.Childs__c = 0;
		 // 子供C人数
		cloneLead.ChildC__c = 0;
		// プラン情報 <- NULL
		cloneLead.Field310__c = null;
	}
	
    // データ登録の事前チェック
  	private Boolean preBookingCreate() {
  		// 処理に必須な項目が未入力の場合、処理を中止する
  		// お客様/予約名/予約チャネル
		//2017/02/23 新規画面の対応　by　zh　BEGIN
		Contact curContact =  CommLogicProcess.getOrInsertTempContact();
		if (CommUtils.isBlank(newLead.Relcontact__c) && CommUtils.isBlank(contactName)) {
			 newContact.id = curContact.id;
		}
		
		if (CommUtils.isBlank(newLead.Name)){
			newLead.Name = curContact.name;
		}
		//2017/02/23 新規画面の対応　by　zh　END
		/*
		if((CommUtils.isBlank(newLead.Relcontact__c) && CommUtils.isBlank(contactName) ) ||
  			CommUtils.isBlank(newLead.Name) ||
  			CommUtils.isBlank(newLead.Field2__c) ||
  			newLead.StayPersons__c == null) {
  		*/
  		if(  newLead.StayPersons__c == null) {
  			//必須項目を入力してください。
  			Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_005_0075));
  			return false;
  		}
  		// 日帰りの場合、到着日と出発日の時刻チェックを行う
  		if (!CommUtils.isBlank(MoreRoomMessage)){
  			Map<String,List<String>> moreRoomKeyMap = getRoomMessage();
  			for (String key : moreRoomKeyMap.keySet()) {
  				List<String> meLst = moreRoomKeyMap.get(key);
	            Map<String,List<LeadIndex__c>> roomIdToIndexMap = new Map<String,List<LeadIndex__c>>();
	            for (integer i = 0 ; i < meLst.size() ; i++) {
					String message =  meLst[i];           	
  					String afMessage = message.substringAfter('_');
  					String roomId = afMessage.substringAfterLast('_');
  					List<String> timeLst = afMessage.substringBeforeLast('_').split('_');
  					Date entryDate = CommUtils.stringToDate(timeLst[0]);
  					Date depertDate = CommUtils.stringToDate(timeLst[2]);
  					Integer daysNums = entryDate.daysBetween(depertDate);
  					if( daysNums == 0 ){
//System.debug(logginglevel.info,'newLead.Field4__c11:::' + timeLst[1]);
//System.debug(logginglevel.info,'newLead.Field3__c11:::' + timeLst[3]);
  						// 2013/09/16 TIME:[H:M]書式対応ため、下記処理を追加する
		  				Time startTime = CommUtils.stringToTime(timeLst[1]);
		  				Time endTime = CommUtils.stringToTime(timeLst[3]);
//System.debug(logginglevel.info,'startTime:::' + startTime);
//System.debug(logginglevel.info,'endTime:::' + endTime);
		  				if (startTime >= endTime) {
			  				//出発時刻には到着時刻以降の時刻を指定して下さい
			  				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_005_0076));
			  				return false;
			  			}
  					}
  				}
  			}
  		}else {
  		if (staysNums == 0) {
  			// 2013/09/16 TIME:[H:M]書式対応ため、下記処理を追加する
  			Time startTime = CommUtils.stringToTime(newLead.Field4__c);
  			Time endTime = CommUtils.stringToTime(newLead.Field3__c);
  			//if (newLead.Field4__c >= newLead.Field3__c) {
  			if (startTime >= endTime) {
  				//出発時刻には到着時刻以降の時刻を指定して下さい
  				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_005_0076));
  				return false;
	  			}
  			}
  		}
  		// Defautl値設定
  		if (staysNums == null) staysNums = 0;
  		/*
  		// 2013/10/28 部屋割り当て可能チェックを行う
  		if (!CommUtils.isBlank(newLead.Rroom__c)) {
  			Date startDt = Date.parse(startDays);
  			// 日帰りする場合、条件統一ため、０から１に変更する
  			Date endDt = startDt.addDays(staysNums == 0 ? 1 : staysNums);
			List<Lead__c> existLeads = [ select Id from Lead__c
	        	where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
	                And DAY_ONLY(convertTimezone(EntryTime__c)) >= :startDt
	                And DAY_ONLY(convertTimezone(EntryTime__c)) < :endDt
	                And Rroom__c = :newLead.Rroom__c ];
	         if (!existLeads.isEmpty()) {
  				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_0010));
  				return false;
	         }
  		}*/
  		
  		if (!CommUtils.isBlank(newLead.Relcontact__c)) newContact.Id = newLead.Relcontact__c;
  		return true;
  	}
  	private Map<String,List<String>> getRoomMessage(){
  		Map<String,List<String>> moreRoomKeyMap  = new Map<String,List<String>>();
  		String[] typeMsLst = MoreRoomMessage.split(',');
		for (String me : typeMsLst) {
			String key = me.substringBeforeLast('_');
			if(!moreRoomKeyMap.containsKey(key)) moreRoomKeyMap.put(key, new  List<String>());
            moreRoomKeyMap.get(key).add(me);
		}
		return moreRoomKeyMap;
  	}
    // お客様情報新規登録・更新を行う
    private void upsertContact() {
    	// 顧客情報の新規作成
    	if (newContact.Id == null) {
    		String[] names = CommUtils.splitName(contactName);
    		newContact.LastName = names[0];
    		newContact.FirstName = names[1];
    	// 2017/01/25 新規画面の項目自定義機能　by　zy　BEGIN	
    	// 2017/02/15 お客様关联的自定义字段更新 Fix by zh BEGIN
    	} else {
			List<String> splitContactFields = contactFields.split(',');
			Map<String, Schema.DescribeFieldResult> contactDeafaultValuesMaps = CommSqlUtils.getAllFieldLst(Contact.sObjectType,false,true);
	    	for (String fieldConName : splitContactFields) {
				String fieldKey = fieldConName.toLowerCase();
	    		if (contactDeafaultValuesMaps.containsKey(fieldKey)){
					Schema.DescribeFieldResult result = contactDeafaultValuesMaps.get(fieldKey);
					if( newContact.get(fieldConName) == null){
						if(result.getType() == DisplayType.String || result.getType() == DisplayType.textarea
		    			|| result.getType() == DisplayType.Phone|| result.getType() == DisplayType.Email)
		    				newContact.put(fieldConName,'');
		    			else newContact.put(fieldConName,null);
					}		    		
	    		}
//system.debug(logginglevel.info,'newContact:::' + newContact);
	    	}
    	}
    	// 2017/02/15 お客様关联的自定义字段更新 Fix by zh END
	// 2017/01/25 新規画面の項目自定義機能　by　zy　END
    	// 2016/10/19 お客様重複管理機能対応 BEGIN
    	//upsert newContact;
    	newContact = (new CommLogicProcess()).upsertDuplicateErrorProcess(newContact);
    	// 2016/10/19 お客様重複管理機能対応 END
    	newLead.Relcontact__c = newContact.Id;
    }
    
    // 画面データ表示用Header定義情報を設定する
    private void setDispHeaders(){
    	// 画面制御変数設定する
    	TimeModel tm = gModeInfo;
    	// 月の単位のHeader情報表示用リスト
    	monthHeader = new List<DispHeader>();
    	dayHeader = new List<DispHeader>();
    	hourHeader = new List<DispHeader>();
    	allColUnitInfo = new List<DispHeader>(); // １列単位のHeader情報を格納する
    	
    	// 重複情報をFILTER用MAP
    	Map<String, DispHeader> hourColspanMap = new Map<String, DispHeader>();
    	Map<Date, DispHeader> dayColspanMap = new Map<Date, DispHeader>();
    	Map<Integer, DispHeader> monthColspanMap = new Map<Integer, DispHeader>();
    	// ９０日間のViewModeの場合
    	Boolean is90ViewMode = (viewMode == CONST_VIEWMODE_3);
    	String tdClassName = tm.className;
    	// 開始時刻から各列の時間情報を設定する
    	for (Integer h = 0; h < tm.maxShowColNums; h++) {
    		// 列の時間を計算する
    		DateTime curDateTime = tm.beginTime.addMinutes(tm.colHourLen * h);
    		// 列単位に情報を設定する
    		DispHeader minUnitColInfo = new DispHeader(curDateTime, '', h);
    		minUnitColInfo.styleClassName = tdClassName;	// TDのClass
    		allColUnitInfo.add(minUnitColInfo);
    		
    		// 時間単位のHeader情報を設定する
    		String hourKey = curDateTime.format('yyyyMMddHH');
    		if (!hourColspanMap.containsKey(hourKey)) {
	    		//String minuteLabel = (is90ViewMode ? '24' : String.valueOf(curDateTime.hour()) ) + '時';	// 90日間の場合、表示のラベルは0時から24時に表示変更
	    		String minuteLabel = (is90ViewMode ? '24' : String.valueOf(curDateTime.hour()) );	// 90日間の場合、表示のラベルは0時から24時に表示変更
	    		DispHeader minuteColHeader = new DispHeader(curDateTime, minuteLabel, h);
	    		minuteColHeader.styleClassName = tdClassName;	// TDのClass
	    		
	    		hourHeader.add(minuteColHeader);

	    		hourColspanMap.put(hourKey, minuteColHeader);
    		} else {
    			hourColspanMap.get(hourKey).colspan ++;
    		}
    		// 日付単位のHeader情報を設定する
    		Date curDate = curDateTime.date();
    		if (!dayColspanMap.containsKey( curDate )) {
    			String dayLabel = curDate.day() + '(' + CommUtils.getYobi(curDate) + ')';
    			DispHeader colDayHeader = new DispHeader(curDateTime, dayLabel, h);
    			// 休日の場合、休日フラグを設定する
    			if (holidayMap.containsKey(curDate)) {
    				colDayHeader.isHoliday = true;
    				colDayHeader.holidayStr= holidayMap.get(curDate);
    			}
    			dayHeader.add(colDayHeader);
    			
    			dayColspanMap.put(curDate, colDayHeader);
    		} else {
    			dayColspanMap.get(curDate).colspan ++;
    		}
    		// 月単位のHeader情報を設定する
    		Integer curMonth = curDate.month();
    		if (!monthColspanMap.containsKey( curMonth )) {
            	//月
                String monthLabel = curMonth + Label.CONST_005_0088;
    			DispHeader colMonthHeader = new DispHeader(curDateTime, monthLabel, h);
    			monthHeader.add(colMonthHeader);
    			monthColspanMap.put(curMonth, colMonthHeader);
    		} else {
    			monthColspanMap.get(curMonth).colspan ++;
    		}
    	}
    }
    
    //public List<dispHeader> getDispHeaders() { return dispHeaders;}
    public String getPageTitleInfo() {
    	//return oneMonthDateList[0].format() + '〜' + oneMonthDateList[oneMonthDateList.size()-1].format();
    	//return gModeInfo.beginTime.format('yyyy/MM/dd') + '〜' + gModeInfo.lastTime.format('yyyy/MM/dd');
    	return gModeInfo.beginTime.format(CommBaseCtrl.getDateFormat()) + '〜' + gModeInfo.lastTime.format(CommBaseCtrl.getDateFormat());
    }
    // 2016/03/21 UI効率改善 BEGIN
    public String lastRoomId{get;set;}
    public Boolean hadNeedLoadFlag{get;set;}
    public integer roomInt{get{return Integer.valueOf(CommDefine__c.getOrgDefaults().TimeTableProcessLimit__c == null ? 200 : CommDefine__c.getOrgDefaults().TimeTableProcessLimit__c);}}
    // 2016/03/21 UI効率改善 END
    // 画面に表示する予約データを取得する
    private List<Lead__c> getLeads () {
        // ---------------------------
        // 期間の予約データ件数を統計する
        // ---------------------------
        // 予約ステータス（無効フラグ）
        Integer leadCancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
        //String roomTypeNormalFlg = CommConst.ROOMTYPE_NORMAL;
        // 開始日
        Date conStartDate = gModeInfo.beginDate.addDays(-1);
        // 終了日
        Date conEndDate = gModeInfo.lastDate.addDays(1);
        // 支店コード
        String shopCode = branchShopNm;
		// 2016/03/21 UI効率改善 BEGIN
        Set<Id> roomIdSet = new Set<Id>();
        integer sizeInt = CommUtils.nullToZero(roomInt);
        for(List<Id> rooms : roomList){
            for (Id roomId : rooms) {
                roomIdSet.add(roomId);
                if ( sizeInt == 0) break;
                sizeInt --;
            }
        }
	// 2016/03/21 UI効率改善 END
        // Query SQL
        String leadQuery =  'Select Id, Name, Rroom__c,LeadIndexRef__c,Relcontact__r.name,LeadIndexSubId__c,RoomGroupNo__c,LeadIndexRef__r.Nights__c, EntryTime__c, Field4__c, Field3__c,Departure__c,ReservedStatus__c,Field298__c ' +
                            ' ,Field276__c' + 
							' From Lead__c ' +
                            ' Where CancelBool__c != :leadCancelFlg ' +
                            ' And LeadIndexRef__c != null ' +
        //                  ' And DAY_ONLY(convertTimezone(EntryTime__c)) >= :conStartDate ' +
                            ' And Rroom__c = :roomIdSet ';
        /*
        leadQuery   +=  timeModelMap.get(nowMinuteMode).modeTypeInt == 0
        						? ' And DAY_ONLY(convertTimezone(EntryTime__c)) < :conEndDate '
        						: ' And DAY_ONLY(convertTimezone(EntryTime__c)) <= :conEndDate ';
        						*/
       	// 90日間の場合、到着日は90間日の日付の予約データを取得する
       	if (viewMode == CONST_VIEWMODE_3) {
       						leadQuery +=
       						' And DAY_ONLY(convertTimezone(EntryTime__c)) >= :conStartDate ' +
       						' And DAY_ONLY(convertTimezone(EntryTime__c)) < :conEndDate ';
       	} else {
       						leadQuery +=
                         	' And DAY_ONLY(convertTimezone(EntryTime__c)) <= :conEndDate ' +
                         	' And DAY_ONLY(convertTimezone(Departure__c)) >= :conStartDate ';
       	}  
	// 2015/09/01 多店舗機能対応 BEGIN             	
        if (!CommUtils.isBlank(shopCode)) {
            leadQuery+= ' And Rroom__r.ShopInfoRef__r.ShopCode__c = :shopCode' ;
        }else if (userInf.isShopCodePlex) {
            Set<String> shopSt = userInf.shopSt;
            leadQuery+= ' And Rroom__r.ShopInfoRef__r.ShopCode__c in :shopSt';
        }
	// 2015/09/01 多店舗機能対応 END
        //leadQuery +=   ' Group By refTypeOfRooms__c, DAY_ONLY(convertTimezone(EntryTime__c)) ' +
        leadQuery += ' Order by EntryTime__c,LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c';
/*   
System.debug(LoggingLevel.ERROR, 'conStartDate:::' + conStartDate);
System.debug(LoggingLevel.ERROR, 'conEndDate:::' + conEndDate);
System.debug(LoggingLevel.ERROR, 'shopCode:::' + shopCode);
System.debug(LoggingLevel.ERROR, 'leadCancelFlg:::' + leadCancelFlg);
System.debug(LoggingLevel.ERROR, 'leadQuery:::' + leadQuery);
*/		
        return DataBase.query(leadQuery);
        
    }
    
    // プランなしの予約データに対して、料金表にて、見積もり明細データを作成する
  	private void autoCreateBookingEstItems(List<Lead__c> leads, Date stDate, Date edDat) {
  		// 2019/09/15 Security Check BY zyz BEGIN
  		List<String> chkFieldsLst = new List<String>{'refbooking__c','productname__c'};
  		Map<String,Schema.SObjectField> mm = Schema.SObjectType.BookingEstimateItem__c.fields.getMap();
  		if (!CommSecurityUtils.isCanCreateable(chkFieldsLst, mm)) {
  			return ;
  		}
  		// 2019/09/15 Security Check BY zyz END
  		// 料金情報設定用商品が非存在する場合、処理中止
  		//if (roomPriceInfo == null) return;
  		// 2016/11/16 見積明細設定機能対応 BEGIN by zh
  		refreshBookingOrder();
  		// 2016/11/16 見積明細設定機能対応 END by zh
  		// 予約の料金表情報を設定する
  		List<Lead__c> targets = new List<Lead__c>();
  		Set<Id> targetIdSet = new Set<Id>();
  		// 2018/01/26 予約人數が０の場合、登録の明細は見積明細へ反映できない by zy BEGIN
  		if (!leads.isEmpty()) {
	  		String mainKey = CommUtils.nullToBlank(leads[0].LeadIndexRef__c) 
						+ '_' +	CommUtils.nullToBlank(leads[0].LeadIndexSubId__c) 
						+ '_' +	CommUtils.nullToZero(leads[0].RoomGroupNo__c);
			// 2018/01/26 予約人數が０の場合、登録の明細は見積明細へ反映できない by zy END
	  		for (Lead__c lead : leads) {
	  			// 2018/01/26 予約人數が０の場合、登録の明細は見積明細へ反映できない by zy BEGIN
	  			// 集めるの場合対応
	        	if (CommConst.APPOTION_LEADSPLIT_DIV_CODE == CommConst.APPOTION_LEADSPLIT_DIV_CODE_UNION) {
	        		String curKey = CommUtils.nullToBlank(lead.LeadIndexRef__c) 
						+ '_' +	CommUtils.nullToBlank(lead.LeadIndexSubId__c) 
						+ '_' +	CommUtils.nullToZero(lead.RoomGroupNo__c);
	        		if (mainKey != curKey ) continue;
	        	}
	        	// 2018/01/26 予約人數が０の場合、登録の明細は見積明細へ反映できない by zy END
	  			//if (CommConst.APPOTION_LEADSPLIT_DIV_CODE == CommConst.APPOTION_LEADSPLIT_DIV_CODE_SPLIT) return;
	  			// 予約人数は０の場合、見積もり明細作成対象外
	  			// プラン未設定 && 予約人数は０以上場合、室料の見積もり明細を自動作成する
	 			//  2016/12/29 连接plan页面替换标准页面  begin by wx
	  			//if (lead.Field310__c == null && CommUtils.nullToZero(lead.StayPersons__c) > 0) {
	            if (CommUtils.isBlank(lead.Field310__c)) { // && CommUtils.nullToZero(lead.StayPersons__c) > 0
	            //  2016/12/29 连接plan页面替换标准页面  end by wx
	  				targets.add(lead);
	  				targetIdSet.add(lead.Id);
	  			}
	  		}
	  	// 2018/01/26 予約人數が０の場合、登録の明細は見積明細へ反映できない by zy BEGIN
  		}
  		// 2018/01/26 予約人數が０の場合、登録の明細は見積明細へ反映できない by zy END
  		// 自動料金設定する予約データがない場合、処理終了
  		if (targets.isEmpty()) return;	
  		
  		// 2016/11/16 見積明細設定機能対応 BEGIN by zh
        List<BookingEstimateItem__c> updLst = new List<BookingEstimateItem__c> ();
        // 2020/07/30 入湯税の自動入力機能について改善 zyz BEGIN
        // 处理预约信息数据集合分类
        CommLogicProcess.ProLeadInfo proLead = CommLogicProcess.getProLeadInfo(targets);
        // 2020/07/30 入湯税の自動入力機能について改善 zyz END
        if (!oBookEstLst.isEmpty()){
            for (BookEstItem obj : oBookEstLst) {
                // 商品登録と、有効なデータで登録する
                if (!obj.isValidata) {
                    obj.clear();
                    continue;
                }
                // 予約親予約IDを設定する
                // 商品名称（または券名称）
                obj.sobj.ProductName__c = CommUtils.isBlank(obj.productNm) ? obj.orgProductNm : obj.productNm;
                // 2020/07/30 入湯税の自動入力機能について改善 zyz BEGIN
                if(!CommUtils.isBlank(obj.bTaxToPlanRowIndex)) proLead.proBookEst.proAccMstIdSet.add(obj.sobj.refAccountMaster__c);
                // 2020/07/30 入湯税の自動入力機能について改善 zyz END
                updLst.add(obj.sobj);
                // 2014/08/05 宿泊税自動設定機能外す END
            }
        }
  		// 2016/11/16 見積明細設定機能対応 END by zh
		// 2014/01/27 料金自動設定用商品情報を取得する
	  	AccountMaster__c roomPriceInfo = null;
	  	String roomPriceProdName = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomPriceProdName__c);
	  	if (!CommUtils.isBlank(roomPriceProdName)) {
			//List<AccountMaster__c> accMsts = [select Id, Name  From AccountMaster__c Where Name = :roomPriceProdName limit 1];
			List<AccountMaster__c> accMsts = ProductItemUtils.getRoomRateProduct(roomPriceProdName);
			if (!accMsts.isEmpty()) roomPriceInfo = accMsts[0];
	  	}
		// 料金情報設定用商品が非存在する場合、処理中止
		// 2016/11/16 見積明細設定機能対応 BEGIN by zh
  		//if (roomPriceInfo == null) return;
  		// 2016/11/16 見積明細設定機能対応 END by zh	
  		RackRateUtils util = new RackRateUtils();
  		Map<Id,Decimal> leadRoomRateMap = util.getRoomRateByLead(targetIdSet);
  		/*
  		// これから、料金表設定情報にて、見積もり明細情報を作成する
  		// 店舗単位の期間範囲のTier情報を取得する
		String queryRRDetailHeader = ' Select Tier__c, ShopInfoRef__c, ShopInfoRef__r.ShopCode__c,PriceSetupDate__c From RackRateTableDetail__c ';
		String queryRRDetailString = queryRRDetailHeader + ' Where PriceSetupDate__c >=:stDate And PriceSetupDate__c <= :edDat ';
		// 店舗条件
		if (!CommUtils.isBlank(shopInfo.branchShopNm))  queryRRDetailString += ' And ShopInfoRef__r.ShopCode__c = :branchShopNm ';
		// 該当期間のTIER設定配列を格納する
		// 期間単位のTier情報を取得する
		Map<Date, String> setupTierMap = new Map<Date, String>();
		Set<String> tierSet = new Set<String>();
		// 支店コード_日付/TIER
		for (RackRateTableDetail__c detail : DataBase.query(queryRRDetailString)) {
			//String key = CommUtils.nullToBlank(branchShopNm) + '_' + detail.PriceSetupDate__c;
			setupTierMap.put(detail.PriceSetupDate__c, detail.Tier__c);
			tierSet.add(detail.Tier__c);
		}
		// 料金表からDefaultの料金情報を取得する
		Id roomTypeId = newLead.refTypeOfRooms__c;
		
		// 料金表からTier関連金額を取得する
  		String defTier = getDefTier(shopInfo.branchShopNm);
		tierSet.add(defTier);
		// 人数
		String persons = CommUtils.nullToBlank(newLead.StayPersons__c);
		// 同じ部屋タイプ、同じTIER、人数で、料金情報を取得する
		List<RackRateTable__c> raceRateMst = [select id, Name,Tier__c, Price__c from RackRateTable__c where RoomTypeRel__c = :roomTypeId And Tier__c in :tierSet And Persons__c = :persons ]; 
  		// 同じ部屋タイプ、同じ人数で、各TIER情報を取得する
  		Map<String, Decimal> tierMstMap = new Map<String, Decimal>();
  		for (RackRateTable__c raceRate : raceRateMst) {
  			tierMstMap.put(raceRate.Tier__c,  raceRate.Price__c);
  		}
  		
  		List<BookingEstimateItem__c> insertEstItems = new List<BookingEstimateItem__c>();
  		for (Lead__c lead : targets) {
  			// 到着日
  			Date keyDate = lead.EntryTime__c.date();
  			String tierKey = setupTierMap.containsKey(keyDate) ? setupTierMap.get(keyDate) : defTier;
  			Decimal priceVal = (tierMstMap.containsKey(tierKey) ? tierMstMap.get(tierKey) : 0);
  			// 日付から料金情報を取得する
  			BookingEstimateItem__c item = new BookingEstimateItem__c(
  				refBooking__c = lead.Id,
  				refAccountMaster__c = roomPriceInfo.Id,
  				Amount__c = newLead.StayPersons__c,
  				UnitPrice__c = priceVal
  			);
  			insertEstItems.add(item);
  		}
  		*/
  		// 2016/11/16 見積明細設定機能対応 BEGIN by zh
  		if (updLst.isEmpty()) {
        	// 料金情報設定用商品が非存在する場合、処理中止
        	if (roomPriceInfo == null) return;
	  	// 2016/11/16 見積明細設定機能対応 END by zh
  		List<BookingEstimateItem__c> insertEstItems = new List<BookingEstimateItem__c>();
  		for (Lead__c lead : targets) {
  			
  			// 日付から料金情報を取得する
  			BookingEstimateItem__c item = new BookingEstimateItem__c(
  				refBooking__c = lead.Id,
  				refAccountMaster__c = roomPriceInfo.Id,
  				Amount__c = newLead.StayPersons__c,
  				UnitPrice__c = CommUtils.nullToZero(leadRoomRateMap.get(lead.Id))
  			);
  			insertEstItems.add(item);
  		}
  		
  		if (!insertEstItems.isEmpty()) insert insertEstItems;
  		// 2016/11/16 見積明細設定機能対応 BEGIN by zh
  		}else {
            List<BookingEstimateItem__c> insLst = new List<BookingEstimateItem__c>();
            for (Integer i = 0  ; i < targets.size() ; i++ ){
            	Lead__c lead = targets[i];
                for (BookingEstimateItem__c item : updLst){
                    BookingEstimateItem__c cloneItem = item.clone(false, true);
                    if (cloneItem.ActionType__c == ACTTYPE_AR || cloneItem.ActionType__c == ACTTYPE_PAY) {
                    	if ( i != 0 ) continue;
                    }
                    cloneItem.refBooking__c = lead.Id;
                    // 2020/07/30 入湯税の自動入力機能について改善 zyz BEGIN
                    if(CommLogicProcess.proBathTaxAccMst(proLead, lead, cloneItem, staysNums)) continue;
                    // 2020/07/30 入湯税の自動入力機能について改善 zyz END
                    insLst.add(cloneItem);
                }
            }
            if (!insLst.isEmpty()) insert insLst;
       }
       // 2016/11/16 見積明細設定機能対応 END by zh
  	}
  	/*
	private String getDefTier(String shopCd) {
  		
		if (shopInfoMap.containsKey(shopCd)) {
			return 	CommUtils.isBLank((shopInfoMap.get(shopCd)).TierDefault__c) 
					? CommUtils.nullToBlank( CommDefine__c.getOrgDefaults().RackRateTableTierDefault__c )
					: CommUtils.nullToBlank( (shopInfoMap.get(shopCd)).TierDefault__c );
		} else {
			return CommUtils.nullToBlank( CommDefine__c.getOrgDefaults().RackRateTableTierDefault__c );
		}
	}*/
    /**
  	* HH:MM 文字列からTIMEに変換処理
  	**/
  	private Time converHHMMtoTime(String timeStr) {
  		//if (String.isEmpty(timeStr) || timeStr.length() != 5) return Time.newInstance(0,0,0,0);
        //Integer HH = Integer.valueOf(timeStr.subString(0,2));
        //Integer MM = Integer.valueOf(timeStr.subString(3,5));
        //return Time.newInstance(HH, MM, 0, 0);
        return CommUtils.stringToTime(timeStr);
  	}

    /**
	* 予約情報拡張設定項目作成する
	**/
	public Component.Apex.pageBlockSection getInputExtendFields () {
		// 拡張情報を取得する
		Component.Apex.pageBlockSection psection = parseFieldsXml(branchShopNm);
		return psection;
	}
	@remoteAction
	global static DTO.ContactInfo refreshContcatInfo(String contactId, String contactName) {
		return RoomTypeInventory.refreshContcatInfo(contactId, contactName);
	}
	// 2017/01/25 新規画面の項目自定義機能 by zy BEGIN
	/**
	* 顧客情報最新取得を行う
	**/
	@remoteAction
	global static Contact refreshCustomContcatInfo(String contactId, String contactFields) {
		return  queryContact(contactFields, contactId);
	}
	// 2017/01/25 新規画面の項目自定義機能 by zy END
	// プラン明細情報を取得する
	@remoteAction
	global static List<ProductItemUtils.PlanDetail> getPlanDetailListById(String planId) {
		return ProductItemUtils.getPlanDetailList(planId);
	}
	// 商品コードにより、会計商品情報を取得する
	@remoteAction
	global static List<ProductItemUtils.ProductItem> getArrayProductItemInfo(String prodCode) {
		return ProductItemUtils.getArrayProdcutItemByCode(prodCode, true);
	}
    // 2016/03/21 UI効率改善 BEGIN
    @remoteAction 
    global static LeadInfo preAddLeadMessage(String roomIds,String branchShopNm,String processDateStr,String viewMode,String colSize,String guuid,String statusCode){
        //List<TdInfo>
        // 既存の有効予約情報を取得する
        Integer leadCancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
        List<String> roomLst = new List<String>();
        if (!CommUtils.isBlank(roomIds)){
        	roomLst = roomIds.split(',');
        }
        List<TdInfo> htmlLst = new List<TdInfo>();
        htmlLst = getRowAssingInfo(roomLst,branchShopNm,processDateStr, viewMode,colSize, statusCode);
        LeadInfo leadInf = new LeadInfo();
        leadInf.tdInf = htmlLst;
        leadInf.guuid = guuid;
        
        // roomBookingMap.values();JSON.serialize(htmlLst);
        return leadInf;//htmlLst;
    }
    @remoteAction
	global static Map<String,RoomInf> getRoomMessageJson(String branchShopNm,String roomTypeNm){
		// 2018/07/27 宿泊税計算 WGCH BEGIN
		// String querRoomHeader = ' Select Id, Name, TypeRoomRef__r.Name From Room__c ';
		String querRoomHeader = ' Select Id, Name, TypeRoomRef__r.Name, ShopInfoRef__r.ShopCode__c From Room__c ';
		// 2018/07/27 宿泊税計算 WGCH END 
        String userOfRoomType = String.escapeSingleQuotes(CommConst.ROOM_UseOfType_Guest);
        //if(viewMode == CONST_VIEWMODE_4) userOfRoomType = CommConst.ROOM_UseOfType_PTY;
        String queryWhere = ' where UseOfRoom__c = \'' + userOfRoomType + '\'';
        UserUtil.UserShopInfo userInf = UserUtil.CurrentUserInfo;
        // 2015/09/01 多店舗機能対応 BEGIN
		if (!CommUtils.isBlank(branchShopNm)) {
            queryWhere+= ' And ShopInfoRef__r.ShopCode__c = \'' + String.escapeSingleQuotes(branchShopNm) + '\'';
        }else if (userInf.isShopCodePlex) {
            Set<String> shopSt = userInf.shopSt;
            queryWhere+= ' And ShopInfoRef__r.ShopCode__c in :shopSt';
        }
	// 2015/09/01 多店舗機能対応 END
// 2016/11/04 部屋タイプは複数選択できる機能対応 BEGIN		
//        if (!CommUtils.isBlank(roomTypeNm)) queryWhere+= ' And TypeRoomRef__c = \'' + String.escapeSingleQuotes(roomTypeNm) + '\'';
		if (!CommUtils.isBlank(roomTypeNm)) {
        	list<string> locRoomTypeIds = CommUtils.nullToBlank(roomTypeNm).split(',');  
        	queryWhere+= ' And TypeRoomRef__c in :locRoomTypeIds ';        	
        }
// 2016/11/04 部屋タイプは複数選択できる機能対応 END	        
        String queryOrder = ' Order By Seq__c asc  ';
        String queryStr = QuerRoomHeader + queryWhere + queryOrder;
        Integer idx = 0;
        Map<String,RoomInf> roomInfoMap = new Map<String,RoomInf>();
        for (Room__c room : Database.query(queryStr)) {
        	roomInfoMap.put(room.id,new RoomInf(room,idx));
        }
        //roomInfos.addAll(roomInfoMap.values());
        return roomInfoMap;
        //JSON.serialize(roomInfoMap);
	}
	@remoteAction
	global static LeadInfo changeRoomByAjax(String changeRoomId,String orgRoomId,String changeRoomMessage,String branchShopNm,String processDateStr,String viewMode,String colSize,String statusCode){
		List<TdInfo> tdInfos = new List<TdInfo>();
		LeadInfo leadInf = new LeadInfo();
		if(!CommUtils.isBlank(changeRoomMessage)){
			List<String> messageLst = changeRoomMessage.split(',');
			Map<String,List<String>> changeRoomMap = new Map<String,List<String>>();
			for (String message : messageLst) {
				//leadId_toRoomId
				List<String> changeRoomMessagesLst = message.split('_');
				changeRoomMap.put(changeRoomMessagesLst.get(0),changeRoomMessagesLst);
			}
			List<String> error = new List<String>();
			String chgMode = '';
			if (!changeRoomMap.isEmpty())error = chgLeadByChangeRoomAndEntryTime(changeRoomMap,chgMode,viewMode);
			Set<String> roomLst = new Set<String>{orgRoomId,changeRoomId};
			if (!CommUtils.isBlank(error[1])){
				for (String roomId : error[1].split(',')) {
					if(!CommUtils.isBlank(roomId))
						roomLst.add(roomId);
				}
				
			}
//system.debug(logginglevel.info,'roomLst:::' + roomLst);
			List<String> roomIdLst = new List<String>();
			roomIdLst.addAll(roomLst);
			tdInfos = getRowAssingInfo(roomIdLst,branchShopNm, processDateStr, viewMode, colSize, statusCode);
        	leadInf.tdInf = tdInfos;
        	leadInf.errorMsg = CommUtils.nullToBlank(error[0]);
		}
		return leadInf;
	}
	@remoteAction
	global static LeadInfo refreshRoomByIds(String roomIds,String branchShopNm,String processDateStr,String viewMode,String colSize,String statusCode){
		LeadInfo leadInf = new LeadInfo();
		if (!CommUtils.isBlank(roomIds)){
			List<String> roomLst = roomIds.split(',');
			List<TdInfo> tdInfos = new List<TdInfo>();
			tdInfos = getRowAssingInfo(roomLst,branchShopNm, processDateStr, viewMode, colSize, statusCode);
			leadInf.tdInf = tdInfos;
		}
		leadInf.errorMsg = '';
		return leadInf;
	}
	@remoteAction
	global static List<BadRoomInf> getBadRoomMessage(String processDateStr,String viewMode){
		TimeModel gModeInfo = new TimeModel(Date.parse(processDateStr), viewMode);
		List<BadRoomInf> badRoomInfs = new List<BadRoomInf>();
		List<RoomsStatus__c> roomStatus = new RoomStatusManager().queryBadRoomList( gModeInfo.beginDate,gModeInfo.lastDate);
        for(RoomsStatus__c rs : roomStatus) {
			BadRoomInf badRoomInfo = new BadRoomInf(rs) ;
			badRoomInfs.add(badRoomInfo);
        }
        return badRoomInfs;
	}
	//自动更改房间和到着日
	private static List<String> chgLeadByChangeRoomAndEntryTime(Map<String,List<String>> changeRoomMap,String chgMode,String viewMode){
//system.debug(logginglevel.info,'changeRoomMap:::' + changeRoomMap);
		List<String> errMsg = new String[2];
		// 遷移元の予約関連情報取得
		List<Lead__c> updList = [select Rroom__c, refTypeOfRooms__c, LeadIndexRef__c,EntryTime__c,Departure__c,Field4__c,Field3__c, LeadIndexSubId__c, RoomGroupNo__c,Field298__c from lead__c where id = :changeRoomMap.keySet()];
		// 入力情報により、関連の予約情報を一括変更を行う
		// 泊数、最後の出発日変更対応を行う
		// 同じグループNO、同じSUBINDEXの予約データは連動更新を行う
		Set<Id> LeadIndexRefSet = new Set<Id>();
		Set<Id> LeadIndexSubIdSet = new Set<Id>();
		Set<Decimal> RoomGroupNoSet = new Set<Decimal>();
		//Set<Id> roomSet = new Set<Id>();
		Set<String> roomSet = new Set<String>();
		Map<String,List<Lead__c>> sameIndexMap = new Map<String,List<Lead__c>>();
		for (Lead__c l : updList) {
			LeadIndexRefSet.add(l.LeadIndexRef__c);
			LeadIndexSubIdSet.add(l.LeadIndexSubId__c);
			RoomGroupNoSet.add(CommUtils.nullToZero(l.RoomGroupNo__c));
		}
		List<Lead__c> leads = [select id, Name,Rroom__c,UnitPriceDefKbCal__c,LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c,
				StayPersons__c,EntryTime__c,Departure__c,Field4__c,Field3__c
			from Lead__c 
			where LeadIndexRef__c = :LeadIndexRefSet
			And LeadIndexSubId__c = :LeadIndexSubIdSet
			And RoomGroupNo__c = :RoomGroupNoSet
			And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 
			Order By EntryTime__c ] ;
		for (Lead__c upd : leads) {
			// 同じ予約ＩＮＤＥＸ、予約ＩＮＤＥＸＳＵＢ、グループＮＯの場合、同じ予約連泊情報を認識する
			String dtKey =	CommUtils.nullToBlank(upd.LeadIndexRef__c) 
					+ '_' +	CommUtils.nullToBlank(upd.LeadIndexSubId__c) 
					+ '_' +	CommUtils.nullToZero(upd.RoomGroupNo__c);
			if(!sameIndexMap.containsKey(dtKey)) sameIndexMap.put(dtKey,new List<Lead__c>());
			sameIndexMap.get(dtKey).add(upd);
			roomSet.add(upd.Rroom__c);
		}
		  
		
		// DB操作を行う
		Savepoint sp = Database.setSavepoint();
		String roomIds = '';
		Date curToday = System.today();
		try{
			// 2019/09/15 Security Check BY zyz BEGIN
			List<String> chkFieldsLst = new List<String>{'field4__c','field3__c','reftypeofrooms__c','rroom__c','entrytime__c','departure__c'};
			Map<String,Schema.SObjectField> mm = Schema.SObjectType.Lead__c.fields.getMap();
			if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
				return errMsg;
			}
			// 2019/09/15 Security Check BY zyz END
			if (!ApexPages.hasMessages(ApexPages.Severity.ERROR)) {
				//long oneDayLong = 60*60*24*1000;
				List<Lead__c> changeLeadLst = new List<Lead__c>();
				//2017/03/27 故障部屋一括解除機能対応　by　zy BEGIN
				Set<Id> cleanRoomSet = new Set<Id>();
				//2017/03/27 故障部屋一括解除機能対応　by　zy END
	            // Drop元の予約の予約部屋にアサインする
				for (Lead__c updLead : updList) {
					List<String> changeMessage = changeRoomMap.get(updLead.id);
					String moveToRoomId = changeMessage.get(1);
					// 同じ予約ＩＮＤＥＸ、予約ＩＮＤＥＸＳＵＢ、グループＮＯの場合、同じ予約連泊情報を認識する
					String dtKey =	CommUtils.nullToBlank(updLead.LeadIndexRef__c) 
							+ '_' +	CommUtils.nullToBlank(updLead.LeadIndexSubId__c) 
							+ '_' +	CommUtils.nullToZero(updLead.RoomGroupNo__c);
					Integer chgDateInt = 0;
					Datetime orgEntryTime = updLead.EntryTime__c ;
					if (changeMessage.size() == 3) {
						String entryTime = changeMessage.get(2);
						Datetime chgEntryTime  = Datetime.newInstance(Long.valueOf(entryTime));
						long betweenTime = DateTime.newInstance(updLead.Departure__c.date(),CommUtils.objectToTime(updLead.Field3__c)).getTime() - DateTime.newInstance(updLead.EntryTime__c.date(),CommUtils.objectToTime(updLead.Field4__c)).getTime();
						chgDateInt = updLead.EntryTime__c.date().daysBetween(chgEntryTime.date());
						if (viewMode == CONST_VIEWMODE_3) {
							updLead.EntryTime__c = updLead.EntryTime__c.addDays(chgDateInt);
							updLead.Departure__c = updLead.Departure__c.addDays(chgDateInt);
						} else  {
							updLead.EntryTime__c = chgEntryTime;
							long departTime = updLead.EntryTime__c.getTime() + betweenTime;
							updLead.Departure__c = Datetime.newInstance(departTime);
						}
						
						if (viewMode != CONST_VIEWMODE_3) {
							updLead.Field4__c = updLead.EntryTime__c.format('HH:mm');
							updLead.Field3__c = updLead.Departure__c.format('HH:mm');
						}
					}
					if (sameIndexMap.containsKey(dtKey)){
						for (Lead__c lead : sameIndexMap.get(dtKey)){
							if (lead.id != updLead.Id && lead.EntryTime__c > orgEntryTime) {
								if (changeMessage.size() == 3) {
								long betweenTime = DateTime.newInstance(lead.Departure__c.date(),CommUtils.objectToTime(lead.Field3__c)).getTime() - DateTime.newInstance(lead.EntryTime__c.date(),CommUtils.objectToTime(lead.Field4__c)).getTime();
								lead.EntryTime__c = DateTime.newInstance(lead.EntryTime__c.addDays(chgDateInt).date(),updLead.EntryTime__c.time());
								//lead.EntryTime__c = lead.EntryTime__c.addDays(chgDateInt);
								long departTime = lead.EntryTime__c.getTime() + betweenTime;
								lead.Departure__c = Datetime.newInstance(departTime);
								lead.Field4__c = updLead.Field4__c;
								lead.Field3__c = updLead.Field3__c;
								}
								lead.Rroom__c = moveToRoomId;
								roomSet.add(lead.Rroom__c);
								// 部屋タイプをNULLに設定すると、該当部屋の部屋タイプはトリガーで自動設定
								lead.refTypeOfRooms__c = null;
								//2017/03/27 故障部屋一括解除機能対応　by　zy BEGIN
								if (!CommUtils.isBlank(lead.Field298__c) && lead.Field298__c != CommConst.LEAD_GUEST_ST_CO && lead.EntryTime__c.date() == curToday) {
									// この部屋は清掃データ自動作成を行う
									//(new RoomStatusManager()).createNoCleanRooms(system.today(), new Set<Id>{lead.Rroom__c});
									cleanRoomSet.add(lead.Rroom__c);
								}
								//2017/03/27 故障部屋一括解除機能対応　by　zy BEGIN
								//lead.StockAdjustTargetFlg__c = !lead.StockAdjustTargetFlg__c;
								changeLeadLst.add(lead);
							}
						}
					}
					//2017/03/27 故障部屋一括解除機能対応　by　zy BEGIN
					if (!CommUtils.isBlank(updLead.Field298__c) && updLead.Field298__c != CommConst.LEAD_GUEST_ST_CO && updLead.EntryTime__c.date() == curToday) {
						// この部屋は清掃データ自動作成を行う
						cleanRoomSet.add(updLead.Rroom__c);
					}
					//2017/03/27 故障部屋一括解除機能対応　by　zy END
					updLead.Rroom__c = moveToRoomId;
					// 部屋タイプをNULLに設定すると、該当部屋の部屋タイプはトリガーで自動設定
					updLead.refTypeOfRooms__c = null;
					//updLead.StockAdjustTargetFlg__c = !updLead.StockAdjustTargetFlg__c;
					changeLeadLst.add(updLead);
					
//system.debug(logginglevel.info,'updLead:::' + updLead);
				}
				for (String roomId : roomSet) roomIds += (roomId + ',');
				//2017/03/27 故障部屋一括解除機能対応　by　zy BEGIN
				(new RoomStatusManager()).createNoCleanRooms(curToday, cleanRoomSet);
				//2017/03/27 故障部屋一括解除機能対応　by　zy END
				if (!changeLeadLst.isEmpty()) update changeLeadLst;
				// 2016/02/17 ルームインジケータは部屋SWAPする場合、2wayの在庫調整を発行しない機能対応を行う END
			}
		}catch (Exception e){
			// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 BEGIN
			errMsg[0] = CommUtils.getFieldValidationMessage(e.getmessage());
			//if(!CommUtils.isFieldValidationMessage(errMsg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
			//changeRoomErrorMessage = errMsg;
			// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 END
			Database.rollback(sp);
		}
		errMsg[1] = roomIds;
		return errMsg;
	}
	private static List<Lead__c> getRelateRoomId(List<Lead__c> leads,Date startDt,Date endDt,String branchShopNm){
		Set<Id> LeadIndexRefSet = new Set<Id>();
		Set<Id> LeadIndexSubIdSet = new Set<Id>();
		Set<Decimal> RoomGroupNoSet = new Set<Decimal>();
		Set<Id> roomSet = new Set<Id>();
		Set<Id> leadIdSet = new Set<Id>();
		Map<String,List<Lead__c>> leadMap = new Map<String,List<Lead__c>>();
		for (Lead__c l : leads) {
			LeadIndexRefSet.add(l.LeadIndexRef__c);
			LeadIndexSubIdSet.add(l.LeadIndexSubId__c);
			RoomGroupNoSet.add(CommUtils.nullToZero(l.RoomGroupNo__c));
			roomSet.add(l.Rroom__c);
			leadIdSet.add(l.id);
		}
		Set<Id> otherRelateSet = new Set<Id>();
		String querySql = 'select id from Lead__c  where LeadIndexRef__c = :LeadIndexRefSet And LeadIndexSubId__c = :LeadIndexSubIdSet '
						+ 'And RoomGroupNo__c = :RoomGroupNoSet and Rroom__c !=:roomSet and Id != :leadIdSet And CancelBool__c != ' + CommConst.LEAD_ST_CANCEL_FLG 
						+ 'And DAY_ONLY(convertTimezone(Departure__c)) >= :startDt And DAY_ONLY(convertTimezone(EntryTime__c)) <= :endDt ';
		if (!CommUtils.isBlank(branchShopNm)) {
			querySql += 'And Rroom__r.ShopInfoRef__r.ShopCode__c = :branchShopNm';
		}
		querySql += ' Order By EntryTime__c';
		for (Lead__c l : DataBase.query(querySql) ){
				otherRelateSet.add(l.id);
		}
		List<Lead__c> rowLst = leads;
		if (!otherRelateSet.isEmpty()){
			leadIdSet.addAll(otherRelateSet);
			rowLst =  [select id, Name,Relcontact__r.name, Rroom__c,UnitPriceDefKbCal__c,LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c, StayPersons__c,EntryTime__c,Departure__c,Field4__c,Field3__c,Field298__c,ReservedStatus__c
							,Field276__c
											from Lead__c 
											where  Id = :leadIdSet
											Order by EntryTime__c,LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c ];
		
		}
		return rowLst;
	}
	//获取预约数据
	private static List<TdInfo> getRowAssingInfo(List<String> roomLst,String branchShopNm,String processDateStr,String viewMode,String colSize,String statusCode){
		List<TdInfo> tdInfos = new List<TdInfo>();
		Integer leadCancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
        TimeModel gModeInfo = new TimeModel(Date.parse(processDateStr), viewMode);
        ShopInfoUtil.Color statusColor = ShopInfoUtil.getStatusColor(branchShopNm);
        Date startDt = gModeInfo.beginDate.addDays(-1);
        Date endDt = gModeInfo.lastDate.addDays(1);
//system.debug(logginglevel.info,'gModeInfo:::' + gModeInfo);
        Map<String, AppSetupConfigXmlUtil.Config> leadStatusColorMap = AppSetupConfigXmlUtil.getLeadStatusColors(branchShopNm);
        //String roomTypeNormalFlg = CommConst.ROOMTYPE_NORMAL;
        // Query SQL
        String leadQuery =  'Select Id, Name, Rroom__c,LeadIndexRef__c,Relcontact__r.name,LeadIndexSubId__c,RoomGroupNo__c,LeadIndexRef__r.DepartureDate__c, EntryTime__c,LeadIndexRef__r.Nights__c,Field298__c, Field4__c, Field3__c,Departure__c,ReservedStatus__c ' +
                            ' , Field276__c ' +
							' From Lead__c ' +
                            ' Where CancelBool__c != :leadCancelFlg ' +
                            ' And LeadIndexRef__c != null ' +
        //                  ' And DAY_ONLY(convertTimezone(EntryTime__c)) >= :conStartDate ' +
                            ' And Rroom__c = :roomLst ';
        // 90日間の場合、到着日は90間日の日付の予約データを取得する
        if (gModeInfo.viewMode == CONST_VIEWMODE_3) {
                            leadQuery +=
                            ' And DAY_ONLY(convertTimezone(EntryTime__c)) >= :startDt ' +
                            ' And DAY_ONLY(convertTimezone(EntryTime__c)) < :endDt ';
        } else {
                            leadQuery +=
                            ' And DAY_ONLY(convertTimezone(EntryTime__c)) <= :endDt ' +
                            ' And DAY_ONLY(convertTimezone(Departure__c)) >= :startDt ';
        }
    // 2015/09/01 多店舗機能対応 BEGIN
        if (!CommUtils.isBlank(branchShopNm)) {
            leadQuery+= ' And Rroom__r.ShopInfoRef__r.ShopCode__c = :branchShopNm' ;
        }
    // 2015/09/01 多店舗機能対応 END
        //leadQuery +=   ' Group By refTypeOfRooms__c, DAY_ONLY(convertTimezone(EntryTime__c)) ' +
        leadQuery += ' Order by EntryTime__c,LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c , EntryTime__c';
//system.debug(logginglevel.info,'leadQuery:::' + leadQuery);
        List<Lead__c> leads = DataBase.query(leadQuery);
        // 部屋単位、予約情報は配列に格納する
        // 1部屋に含めの予約データが1配列に格納する
        String showInfoWarn = '';
        //check前一天的连泊信息
        Map<String,Map<String,List<LongTdInfo>>> roomLongInfMap = new Map<String,Map<String,List<LongTdInfo>>>();
		showInfoWarn = setupLeadsToTdInfo(roomLongInfMap,leads,startDt,endDt,gModeInfo,leadStatusColorMap,statusColor,branchShopNm);
        // 部屋単位に、アサイン情報を格納する
        for(String roomId : roomLst){
            // 該当部屋に予約情報が未存在する場合
            Map<String,List<LongTdInfo>> oneRoomLeads = roomLongInfMap.get(roomId);
            if (oneRoomLeads == null) oneRoomLeads = new Map<String,List<LongTdInfo>>();
//system.debug(logginglevel.info,'oneRoomLeads:::' + oneRoomLeads);
            // 部屋単位に格納した予約情報はInnerクラスに初期化する
            OneRoomAssingInfo inf = new OneRoomAssingInfo(oneRoomLeads, gModeInfo, CommUtils.nullToIntZero(colSize),statusCode); //,leadIdToKeyMap
            String errMsg = inf.checkTimeRange();
            if (!CommUtils.isBlank(errMsg)) {
                showInfoError += errMsg;
            }
            TdInfo tdinfo = new TdInfo();
            tdinfo.tdHtml = inf.tdHtml;
            tdinfo.roomId = roomId;
            tdinfo.width = inf.widthStr;
            tdinfo.assignTd = inf.assingedColIdxs;
            tdInfos.add(tdinfo);
        } 
        return tdInfos;
	}
	private static String setupLeadsToTdInfo(Map<String,Map<String,List<LongTdInfo>>> roomLongInfMap,List<Lead__c> leads,Date startDt,Date endDt, TimeModel gModeInfo,Map<String, AppSetupConfigXmlUtil.Config> leadStatusColorMap,ShopInfoUtil.Color statusColor,String branchShopNm){
        // 部屋単位、予約情報は配列に格納する
        // 1部屋に含めの予約データが1配列に格納する
        //check最后一天的连泊信息
       	Set<String> LastDtKeySet = new Set<String>();
        //check前一天的连泊信息
       	Set<String> beforeDtKeySet = new Set<String>();
	 	Map<string,datetime> sameLeadDtMap = new Map<string,datetime>();
	 	Map<String,List<LongTdInfo>> beforeDepartTimeMap = new Map<String,List<LongTdInfo>>();
	 	Map<String,Map<String,List<Id>>> roomLeadIdMap = new Map<String,Map<String,List<Id>>>();
	 	String showInfoWarn = '';
	 	//将其他关联房间数据查出，但不加入刷新列
        List<Lead__c> checkLead = getRelateRoomId(leads,startDt,endDt,branchShopNm);
        // 予約情報はクラスに格納する
        for (Lead__c lead : checkLead) {
        	boolean canDropFlag = false;
            // 同じ予約ＩＮＤＥＸ、予約ＩＮＤＥＸＳＵＢ、グループＮＯの場合、同じ予約連泊情報を認識する
			String dtKey =	CommUtils.nullToBlank(lead.LeadIndexRef__c) 
					+ '_' +	CommUtils.nullToBlank(lead.LeadIndexSubId__c) 
					+ '_' +	CommUtils.nullToZero(lead.RoomGroupNo__c);
            // 該当部屋に予約情報が未格納する場合、情報を新規作成する
            // 既存データの到着時刻と出発時刻設定処理を行う
            Date entryDt = lead.EntryTime__c.date();
            Date departDt = lead.Departure__c.date();
            //前一天数据
			if (startDt == entryDt || startDt == departDt){
				beforeDtKeySet.add(dtKey);
			}
			if (endDt  == entryDt || endDt == departDt){
				LastDtKeySet.add(dtKey);
			}
			if (gModeInfo.viewMode == CONST_VIEWMODE_3) {
				//>= ==> > 如果过滤出发日当天的数据则会丢失当天做的数据
				if (gModeInfo.beginDate > entryDt || gModeInfo.lastDate < entryDt) 
	        		continue;
			} else {
				if (startDt >= departDt || endDt <= entryDt) 
	        		continue;
			}
        	
            // 到着時刻が空白の場合 Default時刻を自動設定を行う
            String warnInfMsg = null;

            // 到着時刻または出発時刻が空白の場合、設置値が補足する
            if (CommUtils.isBlank(lead.Field4__c) || CommUtils.isBlank(lead.Field3__c)) {

                // 時刻情報を未設定の予約情報は、画面に表示を行う
                //showInfoWarn +=  '&nbsp;&nbsp;【<a href="/' + lead.Id + '/e" target="_blank" >'+(ROOM_INFO_NAME_TYPE == 2 ? lead.name : lead.Relcontact__r.name)+'</a>】';
                warnInfMsg = '&nbsp;&nbsp;【<a href="/' + lead.Id + '/e" target="_blank" >'+(ROOM_INFO_NAME_TYPE == 2 ? lead.name : lead.Relcontact__r.name)+'</a>】';
                // 日帰りの場合
                if (entryDt.daysBetween(departDt) == 0) {
                    if (CommUtils.isBlank(lead.Field4__c)) lead.Field4__c = defaultDayUseCheckInTime;
                    if (CommUtils.isBlank(lead.Field3__c)) {
                        lead.Field3__c = DateTime.newInstance(
                                    Date.today(),
                                    CommUtils.stringToTime(lead.Field4__c).addHours(CommConst.DEF_DAYUSE_STAY_HOURS)).format('HH:mm');
                    }
                } else {
                    if (CommUtils.isBlank(lead.Field4__c)) lead.Field4__c = defaultCheckinTime;
                    if (CommUtils.isBlank(lead.Field3__c)) lead.Field3__c = defaultCheckoutTime;
                }
            }
            // 予約の到着時刻と出発時刻は再調査、設定を行う、注意：元のDBに格納している情報と違うになる
            // 2018/03/22 予約の到着時刻24:00以上の場合対応　by　zy　BEGIN
            //lead.EntryTime__c = DateTime.newInstance(entryDt, CommUtils.stringToTime(lead.Field4__c));
            //lead.Departure__c = DateTime.newInstance(departDt,CommUtils.stringToTime(lead.Field3__c));
            lead.EntryTime__c = CommUtils.convertDatetime(entryDt,lead.Field4__c);
            lead.Departure__c = CommUtils.convertDatetime(departDt,lead.Field3__c);
           	// 2018/03/22 予約の到着時刻24:00以上の場合対応　by　zy　END
           	boolean checkflag = false;
           	// 補足後の表示時間は範囲外の場合、該当予約データが表示対象外になる、該当予約の到着時刻　または　出発時刻は範囲外の場合、処理対象外に設定する
           	if (lead.EntryTime__c >= gModeInfo.lastTime || lead.Departure__c <= gModeInfo.beginTime){
        		if (sameLeadDtMap.containsKey(dtKey)) {
        			datetime beforeEntryTime = sameLeadDtMap.get(dtKey);
        			if (beforeEntryTime.date().daysBetween(lead.EntryTime__c.date()) <= 1)
        				checkflag = true;
        		}
        		if (!checkflag) continue;
        	}
           	if (!sameLeadDtMap.containskey(dtKey) ) {
        		if (!beforeDtKeySet.contains(dtKey))
        			canDropFlag = true;
        	}
        	sameLeadDtMap.put(dtKey,lead.Departure__c);
        	/*
        	if (lead.EntryTime__c >= gModeInfo.lastTime || lead.Departure__c <= gModeInfo.beginTime) {
        		continue;
        	} else {
        		
        	}
        	*/
        	if (warnInfMsg != null) showInfoWarn += warnInfMsg;
        	Datetime orgEntryTime = lead.EntryTime__c;
    		// 開始時刻と終了時間は再自動設定を行う
    		if (!checkflag){
    			lead.EntryTime__c = lead.EntryTime__c > gModeInfo.beginTime ? lead.EntryTime__c : gModeInfo.beginTime;
    			lead.Departure__c = lead.Departure__c > gModeInfo.lastTime  ? gModeInfo.lastTime: lead.Departure__c;
    		}
            // 部屋IDにより、情報は配列に格納する
            LongTdInfo info = new LongTdInfo(gModeInfo,lead,canDropFlag && orgEntryTime == lead.EntryTime__c,orgEntryTime);
    		// 連泊の予約データは一つ配列に格納する
            //if (!assingedIndexMap.containsKey(key)) assingedIndexMap.put(key, );
            // 該当部屋に予約情報を追加する
            if (!beforeDepartTimeMap.containsKey(dtKey))
            	beforeDepartTimeMap.put(dtKey,new List<LongTdInfo>());
            integer beforeIdx = beforeDepartTimeMap.get(dtKey).size() - 1;
        	if (beforeIdx >= 0 ){
        		beforeDepartTimeMap.get(dtKey)[beforeIdx].departureDt = lead.EntryTime__c;
        		integer endIdx = info.beginIdx;
				if (gModeInfo.maxShowColNums < endIdx){ 
                	endIdx = gModeInfo.maxShowColNums;
                }  else if (beforeDepartTimeMap.get(dtKey)[beforeIdx].beginIdx == endIdx) {
                	info.beginIdx +=1;
                }
                beforeDepartTimeMap.get(dtKey)[beforeIdx].endIdx = endIdx;
        		
        	}
        	beforeDepartTimeMap.get(dtKey).add(info);
            if(!roomLeadIdMap.containsKey(lead.Rroom__c)) roomLeadIdMap.put(lead.Rroom__c,new Map<String,List<Id>>());
            if(!roomLeadIdMap.get(lead.Rroom__c).containsKey(dtKey)) roomLeadIdMap.get(lead.Rroom__c).put(dtKey,new List<Id>());
            roomLeadIdMap.get(lead.Rroom__c).get(dtKey).add(info.leadId);
        }
        Map<String,LongTdInfo> longInfoMap = new Map<String,LongTdInfo>();
        Date systemDate = System.now().date();
        for (String dtKey : beforeDepartTimeMap.keySet()) {
        	Integer longInfoSize = beforeDepartTimeMap.get(dtKey).size();
        	List<LongTdInfo> procLst = beforeDepartTimeMap.get(dtKey);
        	for (integer i = 0 ; i < procLst.size(); i++) {
        		LongTdInfo info = procLst[i];
        		if (!longInfoMap.containsKey(info.leadId)) {
        			String roomColor = statusColor.RS_RoomAssigned;
        			// 2019/02/28 滞在・外出状態の管理 WGCH BEGIN
        			if( info.status == CommConst.LEAD_GUEST_ST_OUT && outButtonShowFlg ) {		// 外出ボタンで切り替え表示するため、ステータスはチェックアウトすると、出発状態を表示する
        				// 外出予定
        				roomColor = statusColor.RS_RoomOut;
        			}
        			else if( info.status == CommConst.LEAD_GUEST_ST_CI ||
	                info.status == CommConst.LEAD_GUEST_ST_OUT ||
	                info.status == CommConst.LEAD_GUEST_ST_BATH){
	                // 2019/02/28 滞在・外出状態の管理 WGCH END
	                	roomColor = statusColor.RS_RoomStay; 
	                	if(systemDate == info.departureDt.date()){
	                		if (!LastDtKeySet.contains(dtKey) && (procLst.size()-1) == i){
	                			roomColor = statusColor.RS_RoomChkOutDay;
	                		}
	                	}
	                	// 2018/05/09 ルームインジケータの最終日意外泊目のステータスも自動で赤に変え　by ZY BEGIN
						// カスタム設定、デフォルトはfalse
						boolean isChgCheckOutFlag = CommDefine__c.getOrgDefaults().RoomIndicatorPastLeadToCoColorFlg__c == null ? false : CommDefine__c.getOrgDefaults().RoomIndicatorPastLeadToCoColorFlg__c;
						if (isChgCheckOutFlag && systemDate > info.entryDt.date()) roomColor = statusColor.RS_RoomChkOut;
						// 2018/05/09 ルームインジケータの最終日意外泊目のステータスも自動で赤に変え　by ZY END
	                } else if (info.status == CommConst.LEAD_GUEST_ST_CO) {
	                	// 出発
						roomColor = statusColor.RS_RoomChkOut;
					}
					info.roomColor = roomColor;
					// 予約のStyle設定情報を設定する
		    		if (CommUtils.isBlank(info.statusStyle)) {
		    			info.statusStyle = leadStatusColorMap.containsKey(info.leadStatus) && !CommUtils.isBlank(leadStatusColorMap.get(info.leadStatus).val) ? leadStatusColorMap.get(info.leadStatus).val : '';
		    		}
        			longInfoMap.put(info.leadId,info);
        		}
        	}
        }
        for (String roomId : roomLeadIdMap.keySet()) {
        	if(!roomLongInfMap.containsKey(roomId)) roomLongInfMap.put(roomId,new Map<String,List<LongTdInfo>>());
        	for (String dtkey : roomLeadIdMap.get(roomId).keySet()){
        		if(!roomLongInfMap.get(roomId).containsKey(dtkey)) roomLongInfMap.get(roomId).put(dtkey,new List<LongTdInfo>());
        		for (String leadId : roomLeadIdMap.get(roomId).get(dtkey)) {
        			if(longInfoMap.containsKey(leadId))
        				roomLongInfMap.get(roomId).get(dtkey).add(longInfoMap.get(leadId));
        		}
        	}
        	
        }
        return showInfoWarn;
	}
    global Class LeadInfo{
        List<TdInfo> tdInf;
        String guuid;
        String errorMsg;
    }
    Class TdInfo{
        String roomId;
        String tdHtml;
        String assignTd;
        String width;
    }
    // 2016/03/21 UI効率改善 END
	/**
	* 指定の店舗コードにより、XML指定の項目設定情報を取得する
	**/
   	private Component.Apex.pageBlockSection parseFieldsXml(String pShopCode) {
   		
   		Component.Apex.pageBlockSection psection = new Component.Apex.pageBlockSection();
		psection.columns = 1;

   		// 拡張予約項目を定義する
    	List<Document> sr = [select body, name from Document where DeveloperName = 'RoomTypeInventoryLeadInputExtendFieldsXml'];
    	if (sr.isEmpty()) return psection;
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
			if (strShopCode == pShopCode) {
				targetNode = shop;
				break;
			}
		}
		// 目標店舗情報を取得する、店舗コード未設定する場合、一番目の店舗情報で設定する
		targetNode = targetNode == null ? firstNode : targetNode;
		if (targetNode == null) return psection;
		// 2016/11/16 見積明細設定機能対応 BEGIN by zh
		//プラン明細フラグ
        Dom.XmlNode mitumoriNode =  targetNode.getChildElement('MITUMORIFLAG', null);
        if(mitumoriNode != null) {
            String mitumoriContent = mitumoriNode.getText();
            isPlanDetailFlag = boolean.valueOf(mitumoriContent);
        }
        // 2016/11/16 見積明細設定機能対応 END by zh 
		// 画面に既存の予約項目重複処理
		List<String> constFieldsList = LeadConstFields.deleteWhitespace().split(',');
		Set<String> dupliateSet = new Set<String>(constFieldsList);
        // 列数定義タグ存在チェック[2016/07/06]
        Dom.XmlNode colnumsNode = targetNode.getChildElement('COLNUMS', null);
        if (colnumsNode != null) {
            psection.columns = CommUtils.nullToIntZero(colnumsNode.getText().deleteWhitespace());
        }
		// 店舗情報はＸＭＬから取得する
		Dom.XmlNode shopFields =  targetNode.getChildElement('FIELDS', null);
		String strFields = (shopFields == null ? '' : CommUtils.nullToBlank(shopFields.getText()).deleteWhitespace());
		List<String> fieldsSplits = strFields.split(',');
		// 重複する項目は無くす
		List<String> extendFieldsLst = new List<String>();
		// 予約に固定使用する項目APIから無くす
		for (String extendField : fieldsSplits) {
			if (!dupliateSet.contains(extendField) ) extendFieldsLst.add(extendField);
		}
		// 2014/11/27 指定オブジェクトの項目情報は
		map<String, Schema.DescribeFieldResult> modelDeafaultValuesMap = CommUtils.getFieldMetaData(Lead__c.getSObjectType().getDescribe(),new set<String>(extendFieldsLst));
		
		for (String fieldKey : extendFieldsLst) {
			if (CommUtils.isBlank(fieldKey)) continue;
			Schema.DescribeFieldResult descField = modelDeafaultValuesMap.get(fieldKey);
			if (descField == null) continue;
			// Rich Text Area
			if (descField.getType() == Schema.DisplayType.TEXTAREA && descField.isHtmlFormatted()) {
				Component.Apex.InputTextArea inputField = new Component.Apex.InputTextArea();
				inputField.expressions.value = '{!newLead.'+fieldKey+'}';
				inputField.styleClass='ckeditorClass';
				// 2016/11/16 見積明細設定機能対応 BEGIN by zh
				if(isRequired(descField)){
					inputField.styleClass += ' repuiredClass';
				}
				// 2016/11/16 見積明細設定機能対応 END by zh
				inputField.id = fieldKey;
				psection.childComponents.add(inputField);
			} else {
				Component.Apex.InputField inputField = new Component.Apex.InputField();
				// 2016/11/16 見積明細設定機能対応 BEGIN by zh
				if(isRequired(descField)){
					inputField.styleClass = 'repuiredClass';
				}
				// 2016/11/16 見積明細設定機能対応 END by zh
				inputField.expressions.value = '{!newLead.'+fieldKey+'}';
				psection.childComponents.add(inputField);
			}

		}	
		return psection;
   	}
   	// 2016/11/16 見積明細設定機能対応 BEGIN by zh
   	private boolean isRequired(Schema.DescribeFieldResult dr) {
    	return !dr.isNillable() && dr.isCreateable() && !dr.isDefaultedOnCreate();
   	}
	// 2016/11/16 見積明細設定機能対応 END by zh
    //private static final String QuerRoomHeader = CommSqlUtils.generateQueryString('Room__c');
    // 表示する部屋情報一覧を取得する[客室のみ？または全部表示する？]
    //private List<Room__c> getGuestRooms() {
    public String multiRoomTypeIds{get; set;}
    private List<List<Id>> getGuestRooms() {
        // 2018/07/27 宿泊税計算 WGCH BEGIN
	// String querRoomHeader = ' Select Id, Name, TypeRoomRef__r.Name From Room__c ';
	String querRoomHeader = ' Select Id, Name, TypeRoomRef__r.Name, ShopInfoRef__r.ShopCode__c From Room__c ';
	// 2018/07/27 宿泊税計算 WGCH END

        String userOfRoomType = String.escapeSingleQuotes(CommConst.ROOM_UseOfType_Guest);
        //if(viewMode == CONST_VIEWMODE_4) userOfRoomType = CommConst.ROOM_UseOfType_PTY;
        String queryWhere = ' where UseOfRoom__c = \'' + userOfRoomType + '\'';
        // 2015/09/01 多店舗機能対応 BEGIN
	if (!CommUtils.isBlank(branchShopNm)) {
            queryWhere+= ' And ShopInfoRef__r.ShopCode__c = \'' + String.escapeSingleQuotes(branchShopNm) + '\'';
        }else if (userInf.isShopCodePlex) {
            Set<String> shopSt = userInf.shopSt;
            queryWhere+= ' And ShopInfoRef__r.ShopCode__c in :shopSt';
        }
	// 2015/09/01 多店舗機能対応 END
		// 2016/10/13 部屋タイプは複数選択できる機能対応 BEGIN
        //if (!CommUtils.isBlank(roomTypeNm)) queryWhere+= ' And TypeRoomRef__c = \'' + String.escapeSingleQuotes(roomTypeNm) + '\'';
        // 2019/01/15 タイムテーブルを開いた際、デフォルトで表示される部屋タイプを指定できるようにする by zy BEGIN
        // チェック変更と保存
        cookieInfo.changeRoomType(multiRoomTypeIds,branchShopNm);
		// 既存部屋タイプ
		Set<String> roomTypeSet = new Set<String>();
		String newMultiRoomIds = '';
		for (SelectOption opt : roomTypeLst) roomTypeSet.add(opt.getValue());
        // 2019/01/15 タイムテーブルを開いた際、デフォルトで表示される部屋タイプを指定できるようにする by zy END
        if (!CommUtils.isBlank(multiRoomTypeIds)) {
        	//2017/04/07 不能过滤typeid为空的数据bug修复 by zy BEGIN
        	list<string> locRoomTypeIds = new List<String>();
        	//list<string> locRoomTypeIds = CommUtils.nullToBlank(multiRoomTypeIds).split(',');  
        	for (String typeId : CommUtils.nullToBlank(multiRoomTypeIds).split(',')) {
        		// 2019/01/15 タイムテーブルを開いた際、デフォルトで表示される部屋タイプを指定できるようにする by zy BEGIN
        		// 既存部屋タイプ不在
        		if (!roomTypeSet.contains(typeId) || CommUtils.isBlank(typeId)) continue;
        		newMultiRoomIds += typeId + ',';
        		// 2019/01/15 タイムテーブルを開いた際、デフォルトで表示される部屋タイプを指定できるようにする by zy END
        		if (!CommUtils.isBlank(typeId)) locRoomTypeIds.add(typeId);
        	}
        	//2017/04/07 不能过滤typeid为空的数据bug修复 by zy END
        	// 2019/01/15 タイムテーブルを開いた際、デフォルトで表示される部屋タイプを指定できるようにする by zy BEGIN
        	if (!CommUtils.isBlank(newMultiRoomIds)) newMultiRoomIds = newMultiRoomIds.removeEnd(',');
        	if (roomTypeNm != newMultiRoomIds) roomTypeNm = multiRoomTypeIds = newMultiRoomIds;
        	// 2019/01/15 タイムテーブルを開いた際、デフォルトで表示される部屋タイプを指定できるようにする by zy END
//System.debug(Logginglevel.info, 'multiRoomTypeIds:::locRoomTypeIds:'+multiRoomTypeIds);   	
        	//2017/04/07 不能过滤typeid为空的数据bug修复 by zy BEGIN
        	if (!locRoomTypeIds.isEmpty())  queryWhere+= ' And TypeRoomRef__c in :locRoomTypeIds ';
        	//2017/04/07 不能过滤typeid为空的数据bug修复 by zy END        	
        } else if (!CommUtils.isBlank(roomTypeNm)) {
//System.debug(Logginglevel.info, 'roomTypeNm:::String.escapeSingleQuotes(roomTypeNm):'+ String.escapeSingleQuotes(roomTypeNm));
        	queryWhere+= ' And TypeRoomRef__c = \'' + String.escapeSingleQuotes(roomTypeNm) + '\'';
        }
		// 2016/10/13 部屋タイプは複数選択できる機能対応 END
        String queryOrder = ' Order By Seq__c asc  ';
        String queryStr = QuerRoomHeader + queryWhere + queryOrder;
        //return Database.query(queryStr);
        List<List<Id>> results = new List<List<Id>>();
        //roomInfos = new List<RoomInf>();
        roomInfos = new Map<Id,RoomInf>();
        List<Id> subList = new List<Id>();	// 初期値設定
        integer sizeInt = CommUtils.nullToZero(roomInt);
        Integer idx = 0;
        for (Room__c room : Database.query(queryStr)) {
        	if (Math.mod(subList.size(), roomInt) == 0) {
        		subList = new List<Id>();
        		results.add(subList);
        	}
        	if(sizeInt == 0 ){ 
                lastRoomId = room.Id;
            }
            sizeInt--;
        	results[results.size()-1].add(room.id);
        	//if (sizeInt >= 0)
        	roomInfos.put(room.id,new RoomInf(room,idx));
        	idx ++;
        		//roomInfos.add(new RoomInf(room));
        }
        roomListJson = JSON.serialize(results);
        
        //roomInfos.addAll(roomInfoMap.values());
        return results;
    }
  
    // TDのHTMLのテンプレート文字列
    private static final String CONST_TD_HTML_TEMPLATE = '<td class="$$_SOLDLINECLASS_$$" cycIndex="$$_COLINDEX_$$" " $$_STYLE_$$>$$_LEADTEMPLATE_$$</td>';
    private static final String CONST_TD_HTML_BLANK_TEMPLATE = '<td class="tdcolcls $$_SOLDLINECLASS_$$" cycIndex="$$_COLINDEX_$$" $$_STYLE_$$  ></td>';
    private static final String CONST_LEAD_HTML_TEMPLATE = 
    	//'<div class="$$_LEADCLASS_$$"><a target="_blank" onclick="window.open(\'/$$_LEADID_$$\')" href="javascript:void(0)" id="$$_LEADID_$$" onblur="LookupHoverDetail.getHover(\'$$_LEADID_$$\').hide();" onfocus="LookupHoverDetail.getHover(\'$$_LEADID_$$\', \'/$$_LEADID_$$/m?retURL=%2F$$_LEADID_$$&isAjaxRequest=1\').show();" onmouseout="LookupHoverDetail.getHover(\'$$_LEADID_$$\').hide();" onmouseover="LookupHoverDetail.getHover(\'$$_LEADID_$$\', \'/$$_LEADID_$$/m?retURL=%2F$$_LEADID_$$&isAjaxRequest=1\').show();"><span class="fnlabel">$$_SIMPLENAME_$$</span></a>$$_MULITI_LEAD_ICON_$$</div>';
    	'<div class="$$_LEADCLASS_$$" end="$$_end_$$" isblocked="_BLOCK_" dt="_ENTRYDATE_" name="lead_$$_LEADINDEX_$$" $$_STYLE_$$ leadid="$$_LEADID_$$" rcol="$$_ROOMCOLOR_$$" lcol="$$_LEADCOLOR_$$" ><a target="_blank" href="/$$_LEADID_$$" id="$$_LEADID_$$" onblur="LookupHoverDetail.getHover(\'$$_LEADID_$$\').hide();" onfocus="LookupHoverDetail.getHover(\'$$_LEADID_$$\', \'/$$_LEADID_$$/m?retURL=%2F$$_LEADID_$$&isAjaxRequest=1\').show();" onmouseout="LookupHoverDetail.getHover(\'$$_LEADID_$$\').hide();" onmouseover="LookupHoverDetail.getHover(\'$$_LEADID_$$\', \'/$$_LEADID_$$/m?retURL=%2F$$_LEADID_$$&isAjaxRequest=1\').show();"><span class="fnlabel">$$_SIMPLENAME_$$</span></a>_LOCKIMG_</div>';
    //private static final String CONST_MULITI_LEAD_ICON_TEMPLATE = 
    //	'<div class="triangle-topright" onclick="javascipt:openRoomindicatorWin(this)" title="予約件数:$$_LEAD_COUNT_$$件" style="display: true;" >$$_LEAD_COUNT_$$</div>';
    private static final String CONST_LEAD_BLANK_TEMPLATE = '<div class="bDiv"></div>';
	private static final String CONST_LOCK_IMG = '<img class="jlock"/>';
    private static String blankLead = '$BLANK$';
    private static String assignLead = '$ASSIGNLEAD$';
    private static String blankLeadReg = '\\$BLANK\\$';
    private static String assignLeadReg = '\\$ASSIGNLEAD\\$';
    private static String ONE_PAKU = 'oneDayClass';
    private static String MORE_PAKU = 'moreDayClass';
    // １部屋アサインしているの予約情報を格納する
    public class OneRoomAssingInfo {
    	
		/*
		// 割当済
		private final String strAssignedStatusColor = 'isAssignedStatus';
		// 滞中
	    private final String strIsStayStatusColor = 'isStayStatus';
	    // 出発予定
	    private final String strCheckOutDayStatusColor = 'isChkOutDayStatus';
	    // 出発
	    private final String strCheckOutStatusColor = 'isChkOutStatus';
		*/
        // 予約開始時間と終了時間
        //private Map<Integer,Map<Id,LongTdInfo>> assingedLeadsMap;
        
        // 日付/時刻単位の連泊情報格納する
        private LongRowInfo rowInfo = new LongRowInfo();
        private String statusCode;
        //public Integer rowTrIndex{get; private set;}
        //private List<Date> oneMonthDateList;
        //private String viewMode;
        //private TimeModel tm;
        // 到着時刻と出発時刻設定不正のチェック
        public String checkTimeRange() {
        	//String errMsg = '';
        	/*
        	for (List<LongTdInfo> tdLeads : assingedLeadsBlockMap.values()) {
        		for (LongTdInfo longTd : tdLeads) {
        			if (longTd.getColspan() < 0) {
        				errMsg +=  '&nbsp;&nbsp;【<a href="/' + longTd.leadId + '/e" target="_blank" >'+longTd.simpleName+'</a>】<br/>';
        			}
        		}
        	}*/
        	return rowInfo.errMsg;
        	//return errMsg;
        }
        public String widthStr{get;set;}
	// 2016/03/21 UI効率改善 BEGIN
    public OneRoomAssingInfo(){
    	widthStr = '25';
    }
	// 2016/03/21 UI効率改善 END
        /**
        * １部屋に既に予約された予約情報リストを格納する
        *  pRowIndex:行番
        * roomLeads: 該当部屋に有効な予約配列
        **/
        //public OneRoomAssingInfo(List<Lead__c> roomLeads, List<Date> dtLst, List<colTimeInfo> pColTimes, String pageViewMode,integer modeunit,TimeModel timemodel) {
        // 2016/03/21 UI効率改善 BEGIN
        //,Map<Id,String> leadIdToKeyMap
	public OneRoomAssingInfo(Map<String,List<LongTdInfo>> beforeDepartTimeMap, TimeModel pModeInfo, Integer unitInfSize,String pStatusCode) {
			widthStr = '25';
            this.unitInfSize = unitInfSize;
	    // 2016/03/21 UI効率改善 END
			this.pModeInfo = pModeInfo;
			this.statusCode = pStatusCode;
			rowInfo.addAll(beforeDepartTimeMap);
			
			if (rowInfo.maxRowSize > 1) widthStr = String.valueOf(rowInfo.maxRowSize*25 - 1);
			assingedColIdxs = rowInfo.getCantAssignIdx();
			//System.debug(LoggingLevel.ERROR, 'assingedIndexMap :::' + assingedIndexMap);
			// 日付単位に、合流後の予約情報はＭＡＰに格納する
        }
        
		public String tdHtml{get{
			String ldTdHtml = '';
// 2016/03/21 UI効率改善 BEGIN
            if(unitInfSize == 0) return ldTdHtml;
// 2016/03/21 UI効率改善 END
// 2016/03/21 UI効率改善 BEGIN
            for (Integer i = 0; i < unitInfSize ; i++) {
                //DispHeader colHeader = pAllColUnitInfo[i];
// 2016/03/21 UI効率改善 END
                //String colKey = String.valueOf(i);
                String boldLineStyleCls = pModeInfo.isTdSoldLine(i) ? 'tdSLine' : 'tdDLine';
                String styleStr = '';
                if (i == 0) styleStr = 'style="height:' + widthStr + 'px"';
                String leadHtml = rowInfo.divHtml(i,statusCode,pModeInfo.colMinWidth);
                //system.debug(logginglevel.info,'leadHtml:::' + leadHtml);
                if (CommUtils.isBlank(leadHtml)){
                	// TD情報を作成する
        			ldTdHtml += CONST_TD_HTML_BLANK_TEMPLATE
        					.replace('$$_SOLDLINECLASS_$$'	, boldLineStyleCls)
        					.replace('$$_COLINDEX_$$'		, i + '')
        					.replace('$$_STYLE_$$'		, styleStr);
                } else {
                	// TD情報を作成する
            		ldTdHtml += CONST_TD_HTML_TEMPLATE
            					//.replace('$$_TDWIDTH_$$'		, String.valueOf(pModeInfo.colMinWidth * intColSpan))
            					.replace('$$_SOLDLINECLASS_$$'	, boldLineStyleCls)
            					.replace('$$_COLSPAN_$$'		, '')//'colspan="' + String.valueOf(intColSpan) + '"'
            					.replace('$$_COLINDEX_$$'		, i + '')
            					.replace('$$_LEADTEMPLATE_$$'	, leadHtml)
            					.replace('$$_STYLE_$$'		, styleStr);
                }
            }
			return ldTdHtml;

		}}
        public String assingedColIdxs{get; private set;}
	// 2016/03/21 UI効率改善 BEGIN
        private integer unitInfSize;
	// 2016/03/21 UI効率改善 END
        private TimeModel pModeInfo;
    }
    
    /**
    * 画面制御情報を格納クラス
    */
    public class TimeModel{

    	public DateTime beginTime;					// 画面に表示する時間帯範囲の開始日付・時間
    	public DateTime lastTime;					// 最終表示日時
    	public Date		beginDate;					// 最初表示日付
    	public Date		lastDate;					// 最終表示日付
    	public Integer	colHourLen{get; private set;}		// １TDに表示する分の数
    	public Integer	colGroupLen;				// １日/１時間に含めの列数
    	public Integer	maxShowColNums;				// 画面に表示する最大列数格納
    	public String	className;					// 画面の詳細データのTDの　ClassName
    	public String 	viewMode;					// 画面制御状態
    	//public String	timeMode;					// 1日間の場合、時制御モード
    	//public Integer 	htmlWidth{get; private set;}//画面の最大 width
    	public Decimal  colMinWidth{get; private set;}
    	public Decimal 	tableWidth{get;set;}
    	
   		private Map<Integer,Boolean> soldLineMap;	// 列の実線状況格納する
   		// コンスタント初期化
   		public TimeModel (Date processDate, String pViewMode) {
			
			viewMode = pViewMode;
			//timeMode = pTimeMode;
			
   			// 画面制御モードと時間モードにより、各関連の制御情報を取得する
   			Integer startHoure = 0;		// 画面表示の開始時刻
   			//Integer maxShowColNums = 0;	// 画面に最大表示されるTD数
   			//Integer colHourLen = 0;		// １TDに表示する分の数
   			Integer colGroupLen = 0;	// 分割用の実線の含めの分の数
   			
   			//String className= '';
   			// 30日間モード
   			// 30日間 * 6時間(1列) * 1日(4列)(1実線)
   			if (viewMode == CONST_VIEWMODE_1) {
   				startHoure = 0;
   				colHourLen = 6 * 60;			// ６時間は１TD
   				colGroupLen = 4;				// 1日間4列含め
   				maxShowColNums = CONST_QUERY_DAYS_MODE1 * colGroupLen;	// 30日間 * 4列（6時間は１列、1日間は4列を表示する）
   				//HTML width
   				colMinWidth = 25; 
   				//htmlWidth = (maxShowColNums*colMinWidth + 400);
   				className = 'detailTd31DAYS';	// Css Class Name
   			} 
   			// 一週間モード
   			// ７日間 * １時間(1列) * 1日(24列)(1実線)
   			else if (viewMode == CONST_VIEWMODE_2) {
   				startHoure = 0;
   				colHourLen = 1 * 60;			// 1時間は１TD
   				colGroupLen = 24;				// 1日間24列含め
   				maxShowColNums = CONST_QUERY_DAYS_MODE2 * colGroupLen;	// 7日間 * 24列（1時間は１列、1日間は24列を表示する）
   				//HTML width 
   				colMinWidth = 25; 
   				//htmlWidth = (maxShowColNums*colMinWidth + 400);
   				className = 'detailTdONEWEEK';	// Css Class Name
   			}
   			// 90日間モード
   			// 90日間 * 1日(1列) * 土曜日(7列)(1実線)
   			else if (viewMode == CONST_VIEWMODE_3) {
   				startHoure = 0;
   				colHourLen = 24 * 60;			// 24時間は１TD
   				colGroupLen = 1;				// 1日間1列含め
   				maxShowColNums = CONST_QUERY_DAYS_MODE3;	// 90日間 * 1列（24時間は１列）
   				//HTML width 
   				colMinWidth = 40; 
   				//htmlWidth = (maxShowColNums*colMinWidth + 400);
   				className = 'detailTd90DAYS';	// Css Class Name
   			}
   			// 1日間モード
   			// 朝５時から翌日の５時まで１日間 * 10分(1列) * 6列(1実線)
   			//else if (viewMode == CONST_VIEWMODE_4 && timeMode == CONST_VIEWMODE_M_10) {
   			else if (viewMode == CONST_VIEWMODE_5) {
   				startHoure = 5;
   				colHourLen = 10;				// 10分は１TD
   				colGroupLen = 6;				// 1時間6列含め
   				maxShowColNums = CONST_QUERY_DAYS_MODE4 * 24 * colGroupLen;	// 1日間 * 6列 * 24（10分は１列）
   				//HTML width 
   				colMinWidth = 8; 
   				//htmlWidth = (maxShowColNums*colMinWidth + 400);
   				className = 'detailTdONEDAY10M';	// Css Class Name
   			}
   			// 朝５時から翌日の５時まで１日間 * 30分(1列) * 2列(1実線)
   			//else if (viewMode == CONST_VIEWMODE_4 && timeMode == CONST_VIEWMODE_M_30) {
   			else if (viewMode == CONST_VIEWMODE_4) {
   				startHoure = 5;
   				colHourLen = 30;				// 30分は１TD
   				colGroupLen = 2;				// 1時間2列含め
   				maxShowColNums = CONST_QUERY_DAYS_MODE4 * 24 * colGroupLen;	// 1日間 * 2列 * 24（10分は１列）
   				//HTML width 
   				colMinWidth = 25; 
   				//htmlWidth = (maxShowColNums*colMinWidth + 400);
   				className = 'detailTdONEDAY30M';	// Css Class Name
   			}
   			// 朝8時から夜8時まで12時間 * 5分(1列) * 12列(1実線)
   			//else if (viewMode == CONST_VIEWMODE_4 && timeMode == CONST_VIEWMODE_M_5) {
   			else if (viewMode == CONST_VIEWMODE_6) {
   				startHoure = 5;
   				colHourLen = 5;					// 30分は１TD
   				colGroupLen = 12;				// 1時間12列含め
   				maxShowColNums = CONST_QUERY_DAYS_MODE4 * 24 * colGroupLen;	// 1日間 * 2列 * 24（10分は１列）
   				//HTML width 
   				colMinWidth = 8; 
   				//htmlWidth = (maxShowColNums*colMinWidth + 400);
   				className = 'detailTdONEDAY05M';	// Css Class Name
   			}
   			// 2018/05/01 タイムテーブル、15 分刻みの追加 by zy BEGIN
   			else if (viewMode == CONST_VIEWMODE_7) {
   				startHoure = 5;
   				colHourLen = 15;					// 15分は１TD
   				colGroupLen = 4;				// 1時間12列含め
   				maxShowColNums = CONST_QUERY_DAYS_MODE4 * 24 * colGroupLen;	// 1日間 * 2列 * 24（10分は１列）
   				//HTML width 
   				colMinWidth = 18; 
   				//htmlWidth = (maxShowColNums*colMinWidth + 400);
   				className = 'detailTdONEDAY05M';	// Css Class Name
   			}
   			// 2018/05/01 タイムテーブル、15 分刻みの追加 by zy END
   			tableWidth = colMinWidth * maxShowColNums;
   			//htmlWidth = (maxShowColNums*colMinWidth + 400);
   			// 開始時刻
   			Time startTime = Time.newInstance(startHoure, 0, 0 ,0);
   			// 開始の日付・時間変数を設定する
   			beginTime	= DateTime.newInstance(processDate, startTime);
   			lastTime	= beginTime.addMinutes(colHourLen * maxShowColNums);
   			// 開始日、終了日
   			beginDate 	= beginTime.date();
   			lastDate	= lastTime.date();
   			// 実線の初期化設定
   			soldLineMap = new Map<Integer, Boolean>();
   			for (Integer i = 0; i < maxShowColNums; i++ ) {
   				Boolean boldLineFlg = false;
   				// 一週間の場合、土曜日の列右側に実線を設定する
   				if (viewMode == CONST_VIEWMODE_3) {
   					boldLineFlg = ( beginTime.addDays(i).format('E') == '土' );
   				} 
   				// 一週間以外の場合、
   				else {
   					boldLineFlg = (Math.mod(i, colGroupLen) == 0);
   				}
   				soldLineMap.put(i, boldLineFlg);
   			}
   			
   		}
   		public Boolean isTdSoldLine(Integer idx) {
   			return soldLineMap.get(idx);
   		}
    }
    public class LongRowInfo{
    	private Map<Integer,List<String>> templateMap;
    	private Map<Integer,List<LongTdInfo>> infoMap;
    	public Integer maxRowSize;
    	private Map<Integer,Set<Integer>> assignPosSetMap;
    	private map<String,Integer> positionKeyMap;
    	private map<integer,integer> curPositionMap;
    	public String errMsg;
    	public LongRowInfo(){
    		errMsg = '';
    		maxRowSize = 1;
    		templateMap = new Map<Integer,List<String>>();
    		infoMap = new Map<Integer,List<LongTdInfo>>();
    		assignPosSetMap = new Map<Integer,Set<Integer>>();
    		positionKeyMap = new Map<String,Integer>();
    		curPositionMap = new Map<Integer,integer>();
    	}
    	public String getCantAssignIdx(){
    		String result = '';
    		for (Integer key : assignPosSetMap.keySet()) result += key + ',';
    		return result.removeEnd(',');
    	}
    	public void addAll(Map<String,List<LongTdInfo>> infoMap){
    		//system.debug(logginglevel.info,'infoMap:::' + infoMap);
    		for (String key : infoMap.keySet()) {
    			for (LongTdInfo info : infoMap.get(key)) add(key,info);
    		}
    	}
    	private void add(String dtKey,LongTdInfo info){
    		integer currentPosition = 0;
    		Integer beginIdx = info.getColKey();
    		Integer colspanInt = info.getColspan();
    		if (info.entryDt > info.departureDt){
    			errMsg +=  '&nbsp;&nbsp;【<a href="/' + info.leadId + '/e" target="_blank" >'+info.simpleName+'</a>】<br/>';
    			return;
    		} else if(colspanInt == 0 ) colspanInt = 1;
    		boolean getPositionFlag = false;
    		if (positionKeyMap.containsKey(dtKey)) { 
    			currentPosition = positionKeyMap.get(dtKey);
    			getPositionFlag = true;
    		}else if (curPositionMap.containsKey(beginIdx)) currentPosition = curPositionMap.get(beginIdx);
    		
    		if (!templateMap.containsKey(beginIdx)){
    			templateMap.put(beginIdx,new String[10]);
    		}
    		
    		List<String> templateLst = templateMap.get(beginIdx);
    		
    		info.initLongSet();
//system.debug(logginglevel.info,'name:::' + info.simpleName);
//system.debug(logginglevel.info,'assignPosSetMap.keySet():::' + assignPosSetMap.keySet());
//system.debug(logginglevel.info,'info.longSet:::' + info.longSet);
    		
    		//长度不够则临时补充
    		if (maxRowSize >= templateLst.size()){
    			List<String> temp = new String[maxRowSize + 10];
    			for (integer i = 0 ; i < templateLst.size(); i++) {
    				temp[i] = templateLst[i];
    			}
    			templateLst = temp;
    		}
//system.debug(logginglevel.info,'currentPosition:::' + currentPosition);
    		Set<Integer> assignSet = new Set<Integer>();
    		if (assignPosSetMap.containsKey(beginIdx)) assignSet = assignPosSetMap.get(beginIdx);
    		
    		//如果第一次进来发现与别人重叠则需要避让
    		if (currentPosition == 0 && assignSet.isEmpty()) {
    			// 先记录下原有size
    			integer orgSize = info.longSet.size();
    			//curSet
    			info.longSet.retainAll(assignPosSetMap.keySet());
    			//integer orgSize = info.longSet.size();
    			if (info.longSet.size() > 0 && orgSize != info.longSet.size()){
	    			templateLst[currentPosition] = blankLead;
	    			currentPosition++;
    			}
//system.debug(logginglevel.info,'needNextFlag:::' + info.longSet.size());
    		}
    		
    		
//system.debug(logginglevel.info,'assignSet:::' + assignSet);
    		if (getPositionFlag && !assignSet.contains(currentPosition))
    			templateLst[currentPosition] = info.leadId;
    		else {
    			boolean hadNofalg = false;
	    		for (integer i = currentPosition ; i < templateLst.size() ; i++) {
	    			//如果模板中未存放数据
	    			if (CommUtils.isBlank(templateLst[i]) ){
	    				//未占位
						if(!assignSet.contains(currentPosition)){
							hadNofalg = true;
	    					break;
	    				//被占位，并且没有被指定
						} else if (!getPositionFlag){
							templateLst[i] = blankLead;
						}
					}
					currentPosition ++;
	    		}
	    		//基本不可能出现
	    		if (!hadNofalg) {
//system.debug(logginglevel.info,'currentPosition111:::' + currentPosition);
					//integer endIdx = beginIdx + colspanInt;
					//if (assignPosSetMap.containsKey(endIdx)) assignSet = assignPosSetMap.get(endIdx);
					//if (assignSet.contains(currentPosition)) {
						//currentPosition ++;
					//}
				}
				templateLst[currentPosition] = info.leadId;
//system.debug(logginglevel.info,'templateLst:::' + templateLst);
    		}
//system.debug(logginglevel.info,'leadId:::' + info.leadId);
			//system.debug(logginglevel.info,'assignSet:::' + assignSet);
    		
    		if (!positionKeyMap.containsKey(dtKey)) positionKeyMap.put(dtKey,currentPosition);
    		templateMap.put(beginIdx,templateLst);
    		if (!infoMap.containsKey(beginIdx)) infoMap.put(beginIdx,new List<LongTdInfo>());
    		infoMap.get(beginIdx).add(info);
    		if ((currentPosition + 1) > maxRowSize) maxRowSize = (currentPosition + 1 );
    		putPosition(beginIdx,colspanInt,currentPosition);
    		if (!getPositionFlag) curPositionMap.put(beginIdx,currentPosition+1);
    	}
    	private void putPosition(Integer beginIdx,Integer colspanInt,Integer position){
    		for (integer i = 0; i < colspanInt ; i++){
    			integer curIdx = beginIdx + i ;
    			if (!assignPosSetMap.containsKey(curIdx))
    				assignPosSetMap.put(curIdx,new Set<Integer>());
    			assignPosSetMap.get(curIdx).add(position);
    		}
    	}
    	public String divHtml(Integer i,String statusCode,Decimal colMinWidth){
    		if (!templateMap.containsKey(i)) return '';
    		String leadHtml = '';
    		boolean hadLeadflag = false;
    		String blankHtml = '';
    		
    		for (String template : templateMap.get(i)) {
    			if (CommUtils.isBlank(template) || template == blankLead) {
    				blankHtml += blankLead;
    			} else {
    				leadHtml += blankHtml;
    				blankHtml = '';
    				leadHtml += template;
    			}
    		}
    		//Integer heightValue = Integer.valueOf(height);
    		
    		String styleHeight = '';
    		// TD作成のテンプレートの文字列
            String leadStatusCls = 'isAssignedStatus ';
    		//';height:' + heightValue + 'px;';
    		for(LongTdInfo info : infoMap.get(i)){
    			//system.debug(logginglevel.info,'info:::' + info);
    			integer intColspan = info.getColspan();
    			if (intColspan == 0) intColspan = 1;
                // 該当情報の幅列数を取得する
				styleHeight += 'height:23px;width:' + ( colMinWidth * intColspan - 5 ) + 'px';
				if ( statusCode == 'room')
					styleHeight += ';background:' + info.roomColor;
				else 
					styleHeight += ';background:' + info.statusStyle;
				if (leadHtml.contains(info.leadId))
					leadHtml = leadHtml.replaceFirst(info.leadId,CONST_LEAD_HTML_TEMPLATE.replace('$$_LEADCLASS_$$'		, leadStatusCls + info.cssClass)	// Default
															            				   .replace('$$_STYLE_$$'			, 'style="' + styleHeight + '"')
															            				   .replace('$$_LEADID_$$'			, CommUtils.nullToBlank(info.leadId))
															            				   .replace('$$_LEADINDEX_$$'		, CommUtils.nullToBlank(info.leadIndexId))
															            				   .replace('$$_SIMPLENAME_$$'		, CommUtils.nullToBlank(info.simpleName))
															            				   .replace('$$_start_$$'			, i+'')
															            				   .replace('$$_end_$$'				, (i+intColspan - 1)+'')
															            				   .replace('$$_ROOMCOLOR_$$'		, CommUtils.nullToBlank(info.roomColor))
															            				   .replace('$$_LEADCOLOR_$$'		, CommUtils.nullToBlank(info.statusStyle)))
															            				   .replace('_BLOCK_'			, CommUtils.nullToBlank(info.lockFlag)) 
																						   .replace('_LOCKIMG_' 				,info.lockFlag ? CONST_LOCK_IMG : '')
															            				   .replace('_ENTRYDATE_'			, CommUtils.nullToBlank(info.orgDt.date().format()));
            	else leadHtml += CONST_LEAD_HTML_TEMPLATE.replace('$$_LEADCLASS_$$'			, leadStatusCls + info.cssClass)	// Default
						            					 .replace('$$_STYLE_$$'				, 'style="' + styleHeight + '"')
						            					 .replace('$$_LEADID_$$'			, CommUtils.nullToBlank(info.leadId))
						            					 .replace('$$_LEADINDEX_$$'			, CommUtils.nullToBlank(info.leadIndexId))
						            					 .replace('$$_SIMPLENAME_$$'		, CommUtils.nullToBlank(info.simpleName))
						            					 .replace('$$_start_$$'				, i+'')
						            					 .replace('$$_end_$$'				, (i+intColspan - 1)+'')
						            					 .replace('$$_ROOMCOLOR_$$'			, CommUtils.nullToBlank(info.roomColor))
											             .replace('$$_LEADCOLOR_$$'			, CommUtils.nullToBlank(info.statusStyle))
											             .replace('_BLOCK_'				, CommUtils.nullToBlank(info.lockFlag))
														 .replace('_LOCKIMG_' 				, '')
											             .replace('_ENTRYDATE_'			, '');
    			
    		}
    		leadHtml = leadHtml.replaceAll(blankLeadReg,CONST_LEAD_BLANK_TEMPLATE);
    		return leadHtml;
    	}
    }
    /**
    * 1連泊の予約情報ＢＬＯＣＫ
    **/
    public class LongTdInfo{

        private DateTime entryDt;				// 同じ連泊の予約情報の表示時間帯の開始の日時
        private DateTime departureDt;			// 同じ連泊の予約情報の表示時間帯の終了の日時
        private TimeModel tm;					// 画面表示モードの情報
        public String simpleName{get; private set;}	// 画面に表示する予約のTitle情報/故障部屋のタイトル
        public Id leadId		{get; set;}	// リンクする予約ID/故障部屋のID(2014/12/08ADD)
        public Id leadIndexId	{get; set;}
        public String statusStyle{get;set;}	// 表示情報のCSSのSTYLE情報格納、該当項目情報を設定する場合
        public String leadStatus{get; private set;}	// 予約ステータス
        public String roomColor{get;set;}
        public Integer endIdx;
        public integer beginIdx;
        public String cssClass;
        public string status;
        public Id roomId;
        public set<Integer> longSet{get;private set;}
        public boolean lockFlag;
        public Datetime orgDt;
        public void initLongSet() {
        	longSet = new Set<integer>();
        	for (integer i = beginIdx ; i <= endIdx ; i++ ){
				longSet.add(i);
			}
        }
        // インスタンス化
        public LongTdInfo(TimeModel pModeInfo,Lead__c pLead,boolean dropFlag,Datetime curDatetime){
            tm = pModeInfo;
            statusStyle = '';
            orgDt = curDatetime;
            status = pLead.Field298__c;
            // 開始日設定
    		if (pLead.Id != null || !CommUtils.isBlank(pLead.name)) {
    		// 予約名情報を設定刷る　
        		simpleName = ROOM_INFO_NAME_TYPE == 2 ? pLead.name : pLead.Relcontact__r.name;
        		// 特殊字符对应
        		// 2019/10/15 エラー修正 by zy BEGIN
        		// simpleName = simpleName.replaceAll('\\$','\\\\\\$');
				simpleName = Commutils.nullToBlank(simpleName).replaceAll('\\$','\\\\\\$');
				// 2019/10/15 エラー修正 by zy END
        		leadId = pLead.Id;
    		}
    		roomId = pLead.Rroom__c;
        	entryDt = pLead.EntryTime__c;
        	departureDt = pLead.Departure__c;
    		// 初日の予約のステータスを見え、ステータスを設定する
    		leadStatus = pLead.ReservedStatus__c;
    		leadIndexId = pLead.LeadIndexRef__c;
    		//若出发日小于系统时间则无法进行拖拽
    		if(pLead.Departure__c.date() < system.now().date() || pLead.Field298__c == CommConst.LEAD_GUEST_ST_CO ){
    			cssClass = '';
    		} else if (dropFlag) {
    			cssClass = ONE_PAKU;
    		} else {
    			cssClass = MORE_PAKU;
    		}
    		beginIdx = getColKey();
    		endIdx = beginIdx + getColspan();
    		lockFlag = pLead.Field276__c;
        }
        
        // 該当予約データの到着時刻は時間軸に割り当て箇所のキーを取得する
        // 到着日の時間軸のINDEXを戻る
        public Integer getColKey() {
        	if (beginIdx == null) { 
        		return beginIdx = getIndex(entryDt, false);
        	}
        	else return beginIdx;
        }
        // Blockの長さ
        public Integer getColspan() {
        	Integer startColIdx	= beginIdx == null ? getIndex(entryDt, false) : beginIdx;
        	// 2014.10.22 ９０日間の場合、出発時刻は前に寄せる対応
        	Integer endColIdx 	= endIdx == null ? getIndex(departureDt, ((tm.viewMode == CONST_VIEWMODE_3) ? false : true) ) : endIdx;
        	//startColIdx	= getIndex(entryDt);
        	//endColIdx 	= getIndex(departureDt);
//System.debug(LoggingLevel.ERROR, 'endColIdx::' + endColIdx);
//System.debug(LoggingLevel.ERROR, 'result::' + (endColIdx - startColIdx ));
        	return (endColIdx - startColIdx);
        }
		// 指定の日時により、該当時刻軸に対応の列数を表示する
        private Integer getIndex (DateTime pDt, Boolean isCeil) {
        	Integer diffDays = tm.beginTime.date().daysBetween(pDt.date());
        	Integer diffMinutes = ( diffDays * 24 * 60 + pDt.hour() * 60 + pDt.minute() ) - ( tm.beginTime.hour() * 60 + tm.beginTime.minute() );
        	//System.debug(LoggingLevel.ERROR, 'pDt ::' + pDt);
        	//System.debug(LoggingLevel.ERROR, 'pDt.hour() ::' + pDt.hour());
        	//System.debug(LoggingLevel.ERROR, 'tm.beginTime ::' + tm.beginTime);
        	//System.debug(LoggingLevel.ERROR, '( diffDays * 24 * 60 + pDt.hour() * 60 + pDt.minute() ) ::' + ( diffDays * 24 * 60 + pDt.hour() * 60 + pDt.minute() ) );
        	//System.debug(LoggingLevel.ERROR, '( tm.beginTime.hour() * 60 + tm.beginTime.minute() )::' + ( tm.beginTime.hour() * 60 + tm.beginTime.minute() ));
        	Integer colIndex = diffMinutes / tm.colHourLen;
        	if (isCeil && Math.mod(diffMinutes, tm.colHourLen) > 0) colIndex++;
        	return colIndex;
        }
	}

    // ３Level：月ー＞日ー＞分情報を表示する
    // 31日間：月ー＞日ー＞時
    // 一週間	：月ー＞日ー＞時
    // 90日間：月ー＞日ー＞24時
    // １日間：月ー＞日ー＞時
    // インナークラス・ヘッダー
    public class DispHeader{
        public String label{get;set;}
        public Integer colIdx{get; private set;}				// 表示する列の数字
        public Integer colspan{get;set;}						// 該当HeaderのTDのColspan数
        public String styleClassName{get;set;}					// 該当TD列のCSSのクラス名
        public String colKey{get; private set;}					// 時間軸単位の列数
        // 2016/08/09 BEGIN
        //public String localDateTime{get{return dt.format();}}	// 日時はLocalに変換する
        //public String localDateTime{get{return dt.format(localTimeFormat);}}	
        public Long localDateTime{get{return dt.getTime();}}	
        // 2016/08/09 END
        public String localDate{get{return dt.date().format();}}// 日付も文字列を戻る
        public String locaYobi{get{return dt.format('E');}}		// 月、火、水、木、金、土、日
        public Boolean isHoliday{get;set;}						// 休日
        public String holidayStr{get;set;}						// 休日詳細
        public Boolean isFutureDay{get;private set;}
		// Localに
        private DateTime dt{get; private set;}
        public DispHeader(DateTime pDt, String pLabel, Integer pColIdx) {
        	dt = pDt;
        	label = pLabel;
        	colspan = 1;
        	colIdx = pColIdx;
        	colKey = String.valueOf(pColIdx);
        	isHoliday = false;
        	isFutureDay = Date.today() <= pDt.date();
        }
    }
    
    // Cookie情報処理追加
    private CookieInf getCookieInf () {
    	CookieInf inf = new CookieInf();
        // 2019/05/30 タイムテーブルの期間設定（31日表示、7日表示など）が保持されないに関してby zy BEGIN
        String viewMode = getCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.VIEWMODE.name(),branchShopNm);
        if (CommUtils.isBlank(viewMode)){
	    // 2019/05/30 タイムテーブルの期間設定（31日表示、7日表示など）が保持されないに関してby zy END
            Cookie theCookie;
            theCookie = ApexPages.currentPage().getCookies().get('_RoomScheduleReport_cookie_viewmode');
            if (theCookie != null) inf.viewMode = theCookie.getValue();
        // 2019/05/30 タイムテーブルの期間設定（31日表示、7日表示など）が保持されないに関してby zy BEGIN
    	} else inf.viewMode = viewMode;
        String leadStatus = getCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.LEADSTATUS.name(),branchShopNm);
        if (CommUtils.isBlank(leadStatus)) {
        // 2019/05/30 タイムテーブルの期間設定（31日表示、7日表示など）が保持されないに関してby zy END
            Cookie statucModeCookie;
            statucModeCookie = ApexPages.currentPage().getCookies().get('_RoomScheduleReport_cookie_statusMode');
            if (statucModeCookie != null) inf.statusMode = statucModeCookie.getValue();
        // 2019/05/30 タイムテーブルの期間設定（31日表示、7日表示など）が保持されないに関してby zy BEGIN    
	    } else  inf.statusMode = leadStatus;
        // 2019/05/30 タイムテーブルの期間設定（31日表示、7日表示など）が保持されないに関してby zy END
        return inf;
    }
	// 2017/02/14	画面モードと予約ステータス/部屋ステータス表示の切替显示対応 BEGIN zyz
    private void setCookieInf () {
    	// 2019/05/30 タイムテーブルの期間設定（31日表示、7日表示など）が保持されないに関してby zy BEGIN
        /*
		CookieInf inf = new CookieInf();
		inf.viewMode = viewMode;
		inf.statusMode = statusCode;
		// 2017/02/14	画面モードと予約ステータス/部屋ステータス表示の切替显示対応 END zyz
		// 画面最後利用する画面モードはCookiesに維持する
		Cookie viewModeCookie = new Cookie('_RoomScheduleReport_cookie_viewmode', inf.viewMode, null, -1, true);
		Cookie statucModeCookie = new Cookie('_RoomScheduleReport_cookie_statusMode', inf.statusMode, null, -1, true);
		ApexPages.currentPage().setCookies(new Cookie[]{viewModeCookie,statucModeCookie});
        */
        saveCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.VIEWMODE.name(),branchShopNm,viewMode);
        saveCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.LEADSTATUS.name(),branchShopNm,statusCode);
        // 2019/05/30 タイムテーブルの期間設定（31日表示、7日表示など）が保持されないに関してby zy END
    }
    public class CookieInf {
    	public String viewMode{get; set;}
    	public String statusMode{get; set;}
    	public CookieInf(){}
    	public CookieInf(String pViewMode) {
    		viewMode = pViewMode;
    	}
    }
    global class BadRequest{
    	public List<BadRoomInf> infos;
    	//2017/03/27 故障部屋一括解除機能対応　by　zy BEGIN
    	public List<String> rmvs;
    	//2017/03/27 故障部屋一括解除機能対応　by　zy END
    	public String message;
    	// 涉及房间
    	List<String> roomArr;
    }
    global class BadRoomInf{
    	public DateTime beginDate;
    	public DateTime endDate;
    	public String beginDateStr;
    	public String endDateStr;
    	public Id Id{get;private set;}
    	public String Name{get;private set;}
    	public Id roomId;
    	public boolean isOneDay;
    	public BadRoomInf(RoomsStatus__c rs){
    		Id = rs.Id;
    		Name = rs.Name;
    		roomId = rs.RoomRef__c;
    		// 2018/02/07 故障時刻登録　by zy BEGIN
    		String beginTime = '00:00';
    		String endTime = '24:00';
    		beginDate = DateTime.newInstance( rs.StatusBeginDate__c,CommUtils.stringtotime(beginTime));
	    	Datetime orgEndDate = DateTime.newInstance( rs.StatusEndDate__c,CommUtils.stringtotime(beginTime));
    		endDate = processTime(orgEndDate,endTime);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
    		if ( rs.StatusBeginDate__c == rs.StatusEndDate__c ) isOneDay = true;
    		if ( rs.BeginTime__c != null) { 
	    		try{
	    			beginDate = DateTime.newInstance( rs.StatusBeginDate__c,CommUtils.stringtotime(rs.BeginTime__c));
	    		} catch(exception e){
	    			system.debug(logginglevel.info,e);
	    		}
    		}
    		if ( rs.OverTime__c != null) {
    			try{
	    			endTime = rs.OverTime__c;        
	    			endDate = processTime(orgEndDate,endTime);
	    		} catch(exception e){
	    			system.debug(logginglevel.info,e);
	    		}
    		}
    		// 2018/02/07 故障時刻登録　by zy END
    		//beginDateStr = beginDate.format('yyyy/MM/dd');
    		beginDateStr = beginDate.format(CommBaseCtrl.getDateFormat());
    		//endDateStr = endDate.format('yyyy/MM/dd');
    		endDateStr = endDate.format(CommBaseCtrl.getDateFormat());
    	}
    	// 2018/02/07 故障時刻登録　by zy BEGIN
    	private Datetime processTime(Datetime orgEndDate,String endTime){
    		String[] timeArr = endTime.split(':');
			DateTime endDate = orgEndDate.addHours(CommUtils.nullToIntZero(timeArr[0])); 
			if (CommUtils.nullToIntZero(timeArr[1]) != 0 ) {
				endDate = endDate.addMinutes(CommUtils.nullToIntZero(timeArr[1]));                          
			}   
    		return endDate;
    	}
    	// 2018/02/07 故障時刻登録　by zy END
    }
    global class RoomInf{
    	public String roomId{get;set;}
    	public String roomNm{get;set;}
    	public String roomTp{get;set;}
    	// 2018/07/27 宿泊税計算 WGCH BEGIN
    	public String roomSpCd{get;set;}
    	// 2018/07/27 宿泊税計算 WGCH END
    	public String typeId{get;set;}
    	public Integer index;
    	public RoomInf(Room__c r){
    		roomId = r.id;
    		roomNm = r.name;
    		//2017/03/06 部屋タイプのNULL bug fix by zy BEGIN
    		roomTp = CommUtils.nullToblank(r.TypeRoomRef__r.Name);
    		typeId = CommUtils.nullToblank(r.TypeRoomRef__c);
    		//2017/03/06 部屋タイプのNULL bug fix by zy END
    		// 2018/07/27 宿泊税計算 WGCH BEGIN
    		roomSpCd = CommUtils.nullToblank(r.ShopInfoRef__r.ShopCode__c);
    		// 2018/07/27 宿泊税計算 WGCH END
    	}
    	public RoomInf(Room__c r,integer idx){
    		roomId = r.id;
    		roomNm = r.name;
    		//2017/03/06 部屋タイプのNULL bug fix by zy BEGIN
    		roomTp = CommUtils.nullToblank(r.TypeRoomRef__r.Name);
    		typeId = CommUtils.nullToblank(r.TypeRoomRef__c);
    		//2017/03/06 部屋タイプのNULL bug fix by zy END
    		// 2018/07/27 宿泊税計算 WGCH BEGIN
    		roomSpCd = CommUtils.nullToblank(r.ShopInfoRef__r.ShopCode__c);
    		// 2018/07/27 宿泊税計算 WGCH END
    		index = idx;
    	}
    }
    // 2016/11/16 見積明細設定機能対応 BEGIN by zh
    // 返金キー情報格納用
    public String refundItemString{get{return JSON.serialize(BillSimpleHelp.getRefundItemStr());}}
    // XMLの定義情報から取得する
    private Map<String, String> PAYMENT_MATCH_MAP = new Map<String, String>();
    public String payTypeConvertJson{get{return JSON.serialize(PAYMENT_MATCH_MAP);}}
    private static final Integer LIST_INPUT_DEF_ROWS = ( CommUtils.nullToIntZero(CommConst.APPOTION_DETAIL_DEF_INPUTLINES) == 0 
                                                        ? 27 
                                                        : CommUtils.nullToIntZero(CommConst.APPOTION_DETAIL_DEF_INPUTLINES) );	
    //見積もり明細表示・非表示
    public Boolean isPlanDetailFlag{get;set;}
    // すでに設定済み明細一覧情報を取得する
    // leadId:リードID
    public List<BookEstItem> oBookEstLst{get; private set;}
    //見積もり明細行目
    public String curRows{get;set;}
    // 2019/07/30 軽減税率機能対応 WGCH BEGIN
    public Boolean isReducedTaxFlg{get{ return CommConst.REDUCED_TAXRATE_FLG;} set;}
    // 支払種別
    public static String ACTTYPE_PAY_DIS_PRICE{get{return CommConst.PROD_PAY_TYPE_DIS_PRICE;}}	// 値引
    // 2019/07/30 軽減税率機能対応 WGCH END
    // 見積もり明細行目追加
    public void addBookingItem() {
    	if(CommUtils.isBlank(curRows)){
    		//明細行目超过默认行数、按照默认行数的明细循环出来放到list中
    		if (oBookEstLst.size() > LIST_INPUT_DEF_ROWS) {
    			List<BookEstItem> orgBookingLst = new List<BookEstItem>();
	            for (Integer i = 0; i < LIST_INPUT_DEF_ROWS; i++) {
	            	orgBookingLst.add(oBookEstLst[i]);
	            }
	            oBookEstLst = orgBookingLst;
	            curRows = String.valueOf(LIST_INPUT_DEF_ROWS);
	        }
    	}
    	refreshBookingOrder();
	// 2016/11/16 見積明細設定機能対応 BEGIN by zh
		// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
		Integer addInputRows = LIST_INPUT_DEF_ROWS;
		// 2020/06/01 6438 bug fix BY zyz BEGIN
		if(addRowsMan != null && addRowsMan != 0) {
			if(addInputRows >= addRowsMan) addRowsMan = LIST_INPUT_DEF_ROWS;
			addInputRows = Math.Ceil(addRowsMan/LIST_INPUT_DEF_ROWS).intValue() * LIST_INPUT_DEF_ROWS;
		}
		addRowsMan = null;
		// for (Integer i = 0; i < LIST_INPUT_DEF_ROWS; i++) {
		for (Integer i = 0; i < addInputRows; i++) {
		// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
	    	BookEstItem estItem = new BookEstItem(new BookingEstimateItem__c(),oBookEstLst.size());
	    	estItem.addRowStr = 'rowStr';
	        oBookEstLst.add(estItem);
	        curRows = String.valueOf(CommUtils.nullToIntZero(curRows)+1);
    	}
	//2016/11/16 見積明細設定機能対応 END by zh
    }
    // 顺序保持 fix BEGIN
	private void refreshBookingOrder(){
		//拖拽改变明细顺序、用每行的No.作为key得到每行的明细放到map中、重新排序、再放到原来的list中
		Map<Integer, BookEstItem> locSortMap = new Map<Integer, BookEstItem>();
		for (BookEstItem item : oBookEstLst) {
			//system.debug(logginglevel.info,'item.sobj.rowNo__c:::' + item.sobj.rowNo__c);
			// 画面表示順により、ソートを行う
			locSortMap.put(CommUtils.nullToIntZero(item.sobj.rowNo__c),item);
		}
		List<Integer> sortKeyLst = new List<Integer>();
		sortKeyLst.addAll(locSortMap.keySet());
		sortKeyLst.sort();
		//system.debug(logginglevel.info,'sortKeyLst:::' + sortKeyLst);
		oBookEstLst.clear();
		//RowIndex再設定する BEGIN
		for (Integer key : sortKeyLst) {
			BookEstItem orgItem = locSortMap.get(key);
			//默认行数保证
			if (LIST_INPUT_DEF_ROWS > oBookEstLst.size()) orgItem.addRowStr = '';
			else orgItem.addRowStr = 'rowStr';
			orgItem.index = oBookEstLst.size();
			oBookEstLst.add(orgItem);
		}
		//RowIndex再設定する END
	// 顺序保持 fix END
    }
    // 見積書の宛名
    // 会計種別：プラン
    public String ACTTYPE_PLAN{get{return CommConst.PROD_ACTION_TYPE_PL;}}
    public String ACTTYPE_PAY{get{return CommConst.PROD_ACTION_TYPE_PY;}}   // 支払
    public String ACTTYPE_AR {get{return CommConst.PROD_ACTION_TYPE_AR;}}   // 前受金
    // 支払メディア種別
    public String MEDIA_TYPE_COPON      {get{return CommConst.MEDIA_TYPE_11;}}
    public String MEDIA_TYPE_DISCOUNT   {get{return CommConst.MEDIA_TYPE_12;}}
    // 見積明細情報格納
    public class BookEstItem {
        // 初期化する
        public BookEstItem(BookingEstimateItem__c s, Integer rsIndex) {
			addRowStr = '';
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
            //2017/03/13 特別税fix by zy BEGIN
            //String specialTasStr = CommUtils.deleteRightZero( CommUtils.nullToZero(s.SpecialTax__c).format(), CommUtils.getPointLen());
            //2017/03/13 特別税fix by zy END
            // 特別税
            //specialTax = CommUtils.isBlank(specialTasStr) ? null : CommUtils.nullToZero(specialTasStr);
            // 合計金額（税込）
            amoutIncTax = s.SpTotal__c;
            // == null ? 0 : CommUtils.nullToZero(s.SpTotal__c);
            // 合計金額（税抜）
            amoutExcTax = s.GoukeinoneTax__c == null ? null : s.GoukeinoneTax__c;
            //if (s.id == null) clear();
            isPlanProduct = false;
            itemId = s.Id;
            leadId = s.refBooking__c;
            // 2015/11/11 プラン明細課税、非課税混在合計金額計算対応 BEGIN
            if (sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) {  
                initPlanInfo = 0;
                // 既存の会計明細情報を取得する
                //for (Tran1__c sobj: sobj.ParentTran1Ref__r) {
                    //initPlanInfo += CommUtils.nullToZero(sobj.Field20__c);
                //}
            }
            // 2015/11/11 プラン明細課税、非課税混在合計金額計算対応 END
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
        //2017/03/13 特別税fix by zy BEGIN
        // 特別料金
        //public Decimal specialTax;
        public Decimal specialTax{get{
        		if (sobj.SpecialTax__c == null) return null;
        		String specialTasStr = CommUtils.deleteRightZero( CommUtils.nullToZero(sobj.SpecialTax__c).format(), CommUtils.getPointLen());
        		return CommUtils.nullToZero(specialTasStr);}set;}
       	//2017/03/13 特別税fix by zy END
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
        // 2015/11/11 プラン明細課税、非課税混在合計金額計算対応 BEGIN
        public Decimal initPlanInfo{get; set;}
        // 2015/11/11 プラン明細課税、非課税混在合計金額計算対応 END
        public Boolean isPlanProduct{get{return (sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PL ? true : false);} set;}
        public String addRowStr{get; set;}
		// 2020/07/30 入湯税の自動入力機能について改善 zyz BEGIN
		public String bTaxAccMstId{get {if(bTaxAccMstId == null) bTaxAccMstId = ''; return bTaxAccMstId;} set;}
		public String bTaxToPlanRowIndex{get {if(bTaxToPlanRowIndex == null) bTaxToPlanRowIndex = ''; return bTaxToPlanRowIndex;} set;}
		public String bTaxAccMstItem{get {if(bTaxAccMstItem == null) bTaxAccMstItem = ''; return bTaxAccMstItem ;} set;}
		// 2020/07/30 入湯税の自動入力機能について改善 zyz END
    }
    
    // 商品コードにより、会計商品情報を取得する
    @remoteAction
    global static List<ProductItemUtils.ProductItem> getArrayProductDetailItemInfo(String prodCode) {
        // 2017/10/17 商品情報店舗別を検索を行う by zh BEGIN
        /*
        // 検索SQL取得
		String queryStr = CommSqlUtils.generateQueryString('AccountMaster__c',new String[]{'(Select AccountMasterRef__c, Price__c, TaxRate__c ,AccountMasterRef__r.ActionType__c From PlanProdcutRef__r where TaxRate__c = 0 or TaxRate__c = null)'});
		//queryStr += ' Where BasePlanFlg__c = false And IsClosed__c != true And ActionType__c != \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_NO) + '\' And Field3__c like \'' + CommUtils.escStr(prodCd) + '%\'';
		queryStr += ' Where IsClosed__c != true And ActionType__c != \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_NO) + '\' And ( Field3__c like \'' + CommUtils.escStr(prodCode) + '%\' OR Name like \'' + CommUtils.escStr(prodCode) + '%\') ' ;
		
		queryStr += ' order by Field4__c,OP__c, Field3__c ';
		//queryStr += ' limit 1000 '; 
		// 商品情報を検索を行う
		List<AccountMaster__c> accMstLst = Database.query(queryStr);
		if (accMstLst.isEmpty()) {
			return new List<ProductItemUtils.ProductItem>();
		}
		Set<Id> accIdSet = new Set<Id>();
		for (AccountMaster__c ac : accMstLst) {
			accIdSet.add(ac.id);
		} 
		set<Id> hadRoomFlagSet = new Set<id>();
		for (PlanDetail__c detail : [Select AccountMasterRef__c, Price__c, TaxRate__c,PlanProdcut__c,AccountMasterRef__r.ActionType__c From PlanDetail__c  where  PlanProdcut__c = :accIdSet]){
        	AccountMaster__c acc = new AccountMaster__c(ActionType__c = detail.AccountMasterRef__r.ActionType__c);
        	if (RackRateUtils.isRoomRateProduct(acc)){
        		if (CommUtils.nullToZero(detail.Price__c) == 0){
        			if (!hadRoomFlagSet.contains(detail.PlanProdcut__c))
        				hadRoomFlagSet.add(detail.PlanProdcut__c);
        		}
        	}
        }
		List<ProductItemUtils.ProductItem> items = new List<ProductItemUtils.ProductItem>();
		for (AccountMaster__c ac : accMstLst) {
			ProductItemUtils.ProductItem p = new ProductItemUtils.ProductItem(ac);
			if (hadRoomFlagSet.contains(ac.id)) p.hadRoomFlag = true;
			items.add(p);
		}
        
//system.debug(logginglevel.info,'items:::' + items);
        return items;
        */
        return ProductItemUtils.getArrayProdcutItemByCode(prodCode, false, false);
        // 2017/10/17 商品情報店舗別を検索を行う by zh END
    }
    
    // プラン関連の商品明細を取得する
    // accId:会計ID/会計商品（プラン）ID
    /**
    * planId : プランID
    * tierPrice　: tier 
    * rateFLagStr : true 室料設定、false 自動计算
    **/
    
    @remoteAction
    global static List<PlanDetail> getAccountMstLstByPlan(String planId) {
        // 会計IDが存在する場合、既に登録された登録情報から情報を展開する
        // 会計IDが非存在場合、
        List<PlanDetail> rsLst = new List<PlanDetail>();
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
        // List<PlanDetail__c> detailLst = [select AccountMasterRef__c, AccountMasterRef__r.name, AccountMasterRef__r.ActionType__c,Price__c,TaxRate__c from PlanDetail__c where PlanProdcut__c = :planId];
        List<PlanDetail__c> detailLst = [select AccountMasterRef__c, AccountMasterRef__r.name, AccountMasterRef__r.ActionType__c,Price__c,TaxRate__c,ServiceRate__c from PlanDetail__c where PlanProdcut__c = :planId];
        // 2019/07/30 軽減税率機能対応 WGCH END
        //Decimal tierPriceDec = CommUtils.nullToZero(tierPrice);
        for (PlanDetail__c pd : detailLst) {
            PlanDetail item = new PlanDetail();
            //AccountMaster__c acc = new AccountMaster__c(ActionType__c = pd.AccountMasterRef__r.ActionType__c);
            Decimal roomPrice = pd.Price__c;
            /*if (tierPriceDec > 0 ){
	            if (RackRateUtils.isRoomRateProduct(acc)){
	                if (!CommUtils.isBlank(tierPrice) && roomPrice == 0) 
	                    roomPrice = tierPriceDec;
	            }
            }*/
//system.debug(logginglevel.info,'roomPrice：：：'  + roomPrice); 
            item.prodPrice = CommUtils.deleteRightZero(CommUtils.nullToZero(roomPrice).format(), CommUtils.getPointLen());
            item.prodName = CommUtils.nullToBlank(pd.AccountMasterRef__r.name);
            //item.prodPrice = CommUtils.nullToZero(pd.Price__c).format();
            item.sobjId = pd.Id;
            item.prodId = pd.AccountMasterRef__c;
            item.planId = pd.Id;
            item.actionType = pd.AccountMasterRef__r.ActionType__c;
            item.prodTaxRate = CommUtils.nullToZero(pd.TaxRate__c);
            // 2019/07/30 軽減税率機能対応 WGCH BEGIN
            item.prodServiceRate = CommUtils.nullToZero(pd.ServiceRate__c);
            // 2019/07/30 軽減税率機能対応 WGCH END
            rsLst.add(item);
        }
        return rsLst;
    }
    
    @remoteAction
    global static List<ProductItemUtils.ProductItem> getArrayProductItemInfoNoPlan(String prodCode) {
        return ProductItemUtils.getArrayProdcutItemByCode(prodCode, true);
    }
    
    // プラン明細情報を維持する
    global class PlanDetail {
        public String prodName{get; set;}
        public String prodPrice{get; set;}
        public String sobjId{get;set;}
        public String prodId{get;set;}
        public String planId{get;set;} // プラン明細ID
        public String actionType{get;set;}
        public Decimal prodTaxRate;
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
        public Decimal prodServiceRate;
        // 2019/07/30 軽減税率機能対応 WGCH END
    }
    
    public void initBookEstItem(){
        oBookEstLst = new List<BookEstItem>();
        if (oBookEstLst.size() < LIST_INPUT_DEF_ROWS) {
            Integer appendRsSize = LIST_INPUT_DEF_ROWS - oBookEstLst.size();
            // 2行目まで設定を行う
            for (Integer i = 0; i < appendRsSize; i++) {
                oBookEstLst.add(new BookEstItem(new BookingEstimateItem__c(),oBookEstLst.size()));
            }
        }
        curRows = String.valueOf(LIST_INPUT_DEF_ROWS);
    }
    
    // 2016/11/16 見積明細設定機能対応 END by zh
    // 2016/11/22 故障部屋一括登録機能対応 BEGIN
    @remoteAction 
    global static List<BadRoomInf> InsertBadRoom(String statusName,String roomIds,String badDates,String expectRoom){
    	return new List<BadRoomInf>();
    }
    @remoteAction 
    global static BadRequest InsertBadRoomExt(String statusName,String roomIds,String badDates,String expectRoom){
    	//2017/03/27 故障部屋一括解除機能対応　by　zy BEGIN
    	//故障房间列表
    	List<String> roomLst = new List<String>();
    	//故障房间日期
    	List<String> dateLst = new List<String>();
    	//2017/03/27 故障部屋一括解除機能対応　by　zy END
    	BadRequest req = new BadRequest(); 
    	//2017/03/06 不考虑的逻辑 by zy BEGIN
    	//expectRoom => expectType
    	// 更改取得信息方式
    	List<RemoteInfo> remoteInfos = (List<RemoteInfo>)JSON.deserializeStrict(expectRoom,List<RemoteInfo>.class);
    	List<String> expectLst = CommUtils.nullToBlank(remoteInfos[0].expectInfo).split(';');
    	//2017/03/06 不考虑的逻辑 by zy END
    	// DB操作を行う
	  	Savepoint sp = Database.setSavepoint();
	  	List<BadRoomInf> badRoomInf = new List<BadRoomInf>();
	  	List<RoomsStatus__c> badRoomLst = new List<RoomsStatus__c>();
	  	List<RoomsStatus__c> updRoomLst = new List<RoomsStatus__c>();
	  	Date processDt = system.today();
	  	//List<String> rmvLst = new List<String>();
	  	Set<Id> roomSet = new Set<Id>();
    	try{
	    	Map<String,Set<String>> expectRoomDateMap = new Map<String,Set<String>>();
	    	//2017/03/27 故障部屋一括解除機能対応　by　zy BEGIN
	    	Map<String,Set<String>> longDateMap = new Map<String,Set<String>>();
	    	//日期解除房间区分，多解除bug修改 by zy BEGIN
	    	//Set<String> excDts = new Set<String>();
	    	Map<String,Set<String>> roomExcDts = new Map<String,Set<String>>();
	    	//日期解除房间区分，多解除bug修改 by zy END
	    	Set<Date> excDates = new Set<Date>();
	    	Set<Id> expRoomIdSet = new Set<Id>();
	    	//被替换,老版本
	    	if (badDates != '2'){
	    		roomLst = roomIds.split(',');
	    		dateLst = badDates.split(',');
	  		//2017/03/27 故障部屋一括解除機能対応　by　zy END
	    		for (String expectStr : expectLst) {
		    		String[] expectRoomMessage = expectStr.split(':');
		    		String roomId = expectRoomMessage[0];
		    		if(!expectRoomDateMap.containsKey(roomId)) expectRoomDateMap.put(roomId,new Set<String>());
		    		if(expectRoomMessage.size() > 1 && !CommUtils.isBlank(expectRoomMessage[1])){
			    		for (String dateStr : expectRoomMessage[1].split('_')){
			    			expectRoomDateMap.get(roomId).add(dateStr);
			    		}
		    		}
		    	}
			    for (String roomId  : roomLst) {
		    		List<String> betweenDateLst = new List<String>();
		    		Date prevDate = null;
		    		//清掃管理データ自動作成_
		    		RoomsStatus__c roomsStatus = new RoomsStatus__c( Name = statusName, RoomRef__c = roomId , Status__c = CommConst.ROOM_ST_TYPE_BED);
		    		for (String bdDate : dateLst) {
		    			if(expectRoomDateMap.containsKey(roomId)){
		    				if(expectRoomDateMap.get(roomId).contains(bdDate)){
		    					continue;
		    				}
		    			}
		    			Date curDate = CommUtils.StringToDate(bdDate);
	    				processDt = curDate;
		    			if(roomsStatus.StatusBeginDate__c == null ) roomsStatus.StatusBeginDate__c = curDate;
		    			//first time
		    			if(prevDate == null) {
		    				prevDate = curDate;
		    				roomsStatus.StatusBeginDate__c = curDate;
		    				continue;
		    			}
						Integer daysBetweenInt = prevDate.daysBetween(curDate);
						//靠近日期自增
						if(daysBetweenInt == 1 ) {
							roomsStatus.StatusEndDate__c = curDate;
						//不靠近的日期直接做成
						} else if (daysBetweenInt > 1){
							roomsStatus.StatusEndDate__c = prevDate;
							badRoomLst.add(roomsStatus);
							roomsStatus = new RoomsStatus__c( Name = statusName, RoomRef__c = roomId , Status__c = CommConst.ROOM_ST_TYPE_BED);
							roomsStatus.StatusBeginDate__c = curDate;
						}
						prevDate = curDate;
		    		}
		    		if( prevDate != null){
		    			if(roomsStatus.StatusBeginDate__c != null) roomsStatus.StatusEndDate__c = prevDate;
		    			else {
		    				roomsStatus.StatusBeginDate__c = prevDate;
		    				roomsStatus.StatusEndDate__c = prevDate;
		    			}
		    			badRoomLst.add(roomsStatus);
		    		}
		    		roomSet.add(roomId);
		    	}
	    	} else{
	    		//system.debug(logginglevel.info,'roomIds:::' + roomIds);
	    		//2type 下 roomIds => roomclean json
	    		List<RoomClean> rc = (List<RoomClean>)JSON.deserializeStrict(roomIds,List<RoomClean>.class);
	    		Set<String> dateSet = new Set<String>();
	    		//List<String> badIds = new List<String>();
	    		for (RoomClean clean : rc) {
	    			roomSet.add(clean.rid);
	    			if(clean.otp == 'exp') {
	    				if (clean.dates.isEmpty() && !CommUtils.isBlank(clean.bid)){
	    					//badIds.add(clean.bid);
	    					updRoomLst.add(new RoomsStatus__c(id = clean.bid , Result__c = CommConst.ROOM_ST_TYPE_BED_FIN));
	    				} else {
	    				//从数据库中查出当日数据
	    				expRoomIdSet.add(clean.rid);
	    					for (String c_date : clean.dates) {
		    					//日期解除房间区分，多解除bug修改 by zy BEGIN
		    					if (!roomExcDts.containsKey(clean.rid)) {
		    						roomExcDts.put(clean.rid,new Set<String>());
		    					}
		    					//excDts.add(c_date);
		    					roomExcDts.get(clean.rid).add(c_date);
		    					//日期解除房间区分，多解除bug修改 by zy END
		    					excDates.add(CommUtils.stringToDate(c_date));
		    					if (!CommUtils.isBlank(clean.bid)) {
		    						if (!longDateMap.containsKey(clean.bid)) longDateMap.put(clean.bid,new Set<String>());
		    					longDateMap.get(clean.bid).add(c_date);
		    					}
	    					}
	    					// 2017/03/03 故障一括解除　by　zy BEGIN
	    					//updRoomLst.add(new RoomsStatus__c(id = clean.bid , Result__c = CommConst.ROOM_ST_TYPE_BED_FIN));
	    					// 2017/03/03 故障一括解除　by　zy END
		    					
	    				}
	    				//rmvLst.add(clean.bid);
	    			//故障部屋タイプ
	    			} else if(clean.otp == 'bad') {
	    				// 2018/02/07 故障時刻登録　by zy BEGIN
	    				/*
	    				for (String dateStr : clean.dates) {
	    					Date curDt = CommUtils.StringToDate(dateStr);
	    					badRoomLst.add(new RoomsStatus__c( Name = statusName, RoomRef__c = clean.rid ,StatusBeginDate__c = curDt, StatusEndDate__c = curDt, Status__c = CommConst.ROOM_ST_TYPE_BED));
	    					*//*
	    					if (!expectRoomDateMap.containsKey(clean.rid)){
		    					expectRoomDateMap.put(clean.rid,new set<String>());
		    				}
		    				expectRoomDateMap.get(clean.rid).add(dateStr);
		    				*/
		    			/*
	    				}*/
			// 2019/04/30 JINYABUG-1631 bug fix by zy BEGIN
                        RoomsStatus__c roomStatus = new RoomsStatus__c( Name = statusName, RoomRef__c = clean.rid, 
                                                                                BeginTime__c = CommUtils.isBlank(clean.start) ? RoomStatusManager.DEF_START_TIME :clean.start,
                                                                                OverTime__c = CommUtils.isBlank(clean.endtime) ? RoomStatusManager.DEF_END_TIME :clean.endtime,
                                                                                Status__c = CommConst.ROOM_ST_TYPE_BED);
                        Date befDt = null;
                        for (String dateStr : clean.dates) {
                            Date curDt = CommUtils.StringToDate(dateStr);
                            if (befDt != null && (befDt.daysBetween(curDt) > 1)) {
                                badRoomLst.add(roomStatus);
                                roomStatus = roomStatus.clone(false,false);
                                roomStatus.StatusBeginDate__c = curDt;
                                roomStatus.StatusEndDate__c = curDt;
                            } 
                            if (roomStatus.StatusBeginDate__c == null || roomStatus.StatusBeginDate__c > curDt)
                                roomStatus.StatusBeginDate__c = curDt;
                            if (roomStatus.StatusEndDate__c == null || roomStatus.StatusEndDate__c < curDt)
                                roomStatus.StatusEndDate__c = curDt;
                            befDt = curDt;
                        }
                        /*
	    				Date startDt = CommUtils.StringToDate(clean.dates[0]);
	    				Date endDt = CommUtils.StringToDate(clean.dates[clean.dates.size()-1]);
	    				RoomsStatus__c roomStatus = new RoomsStatus__c( Name = statusName, RoomRef__c = clean.rid ,StatusBeginDate__c = startDt, 
	    											BeginTime__c = clean.start ,OverTime__c = clean.endtime,StatusEndDate__c = endDt);
	    				List<RoomsStatus__c> rs = createRoomStatus(roomStatus);
	    				if (!rs.isEmpty()) badRoomLst.addAll(rs);
                        */
                        badRoomLst.add(roomStatus);
			// 2019/04/30 JINYABUG-1631 bug fix by zy END
	    				// 2018/02/07 故障時刻登録　by zy END
	    			}
	    		}
	    	}
	    	//多日故障处理
	    	if (!expRoomIdSet.isEmpty()) {
	    		for ( RoomsStatus__c rs : [select id,StatusEndDate__c,StatusBeginDate__c,name,RoomRef__c,Status__c,IsStockSyncTarget__c,Result__c,Describe__c,TypeOfRoomTypeId__c 
	    										// 2018/02/07 故障時刻登録　by zy BEGIN
	    										,BeginTime__c,OverTime__c
	    										// 2018/02/07 故障時刻登録　by zy END
	    												from RoomsStatus__c 
	    												where RoomRef__c = :expRoomIdSet and StatusBeginDate__c <= :excDates and StatusEndDate__c >= :excDates and Result__c != :CommConst.ROOM_ST_TYPE_BED_FIN and Status__c = :CommConst.ROOM_ST_TYPE_BED]) {
	    			RoomsStatus__c r = null;
	    			Integer daysBetween = rs.StatusBeginDate__c.daysBetween(rs.StatusEndDate__c);
	    			//Set<String> excDts = longDateMap.get(rs.id);
	    			// 2018/02/07 故障時刻登録　by zy BEGIN
	    			// 解除被指定故障的场合下不会解除其他的故障
	    			if (!longDateMap.isEmpty() && !longDateMap.containsKey(rs.id)) continue;
	    			// 2018/02/07 故障時刻登録　by zy END
	    			if( daysBetween == 0 && roomExcDts.containsKey(rs.RoomRef__c)){
	    				//判定日
	    				Date curDt = rs.StatusBeginDate__c;
	    				// 单日故障
	    				if (roomExcDts.get(rs.RoomRef__c).contains(curDt.format())){
		    				//将检索到的元数据都清扫完了
			    			rs.Result__c = CommConst.ROOM_ST_TYPE_BED_FIN;
			    			updRoomLst.add(rs);
	    				}
	    				continue;
	    			}
	    			// 2018/02/07 故障時刻登録　by zy BEGIN
    				for (RoomsStatus__c roomStatus : createRoomStatus(rs)) {
						// <= 是为了取出临界值,如果没有「=」 就会出现缺少临界值的问题
	    				//判定日
	    				Date curDt = roomStatus.StatusBeginDate__c;
	    				//故障解除日
	    				//日期解除房间区分，多解除bug修改 by zy BEGIN
	    				if(roomExcDts.containsKey(roomStatus.RoomRef__c) && roomExcDts.get(roomStatus.RoomRef__c).contains(curDt.format())){
	    				//日期解除房间区分，多解除bug修改 by zy END
	    					continue;
	    				}
	    				//是否断开
	    				// 多日数据并且此日期没有数据的情况下
	    				badRoomLst.add(roomStatus);
	    			}
	    			/*
	    			// <= 是为了取出临界值,如果没有「=」 就会出现缺少临界值的问题
	    			for (integer i = 0 ; i <= daysBetween ; i++) {
	    				//判定日
	    				Date curDt = rs.StatusBeginDate__c.addDays(i);
	    				//故障解除日
	    				//日期解除房间区分，多解除bug修改 by zy BEGIN
	    				if(roomExcDts.containsKey(rs.RoomRef__c) && roomExcDts.get(rs.RoomRef__c).contains(curDt.format())){
	    				//日期解除房间区分，多解除bug修改 by zy END
	    					if (r != null) badRoomLst.add(r);
	    					r = null;
	    					continue;
	    				}
	    				//是否断开
	    				// 多日数据并且此日期没有数据的情况下
	    				if (r == null) {
	    					r = rs.clone(false,false);
	    					r.StatusBeginDate__c = curDt;
	    				}
	    				r.StatusEndDate__c = curDt;
	    			}
	    			//存在未放入list中的数据
	    			if (r != null) {
	    				badRoomLst.add(r);
	    			}*/
	    			// 2018/02/07 故障時刻登録　by zy END
    				//将检索到的元数据都清扫完了
	    			rs.Result__c = CommConst.ROOM_ST_TYPE_BED_FIN;
	    			updRoomLst.add(rs);
	    		}
	    	}
	    	// 性能优化 トリガー処理
	    	/*
	    	if (!updRoomLst.isEmpty()) update updRoomLst;
	    	if(!badRoomLst.isEmpty()) insert badRoomLst;
	    	*/
	    	// 2019/09/15 Security Check BY zyz BEGIN
	    	List<String> chkFieldsLst = new List<String>{'overtime__c','begintime__c','statusenddate__c','statusbegindate__c','result__c'};
	    	Map<String,Schema.SObjectField> mm = Schema.SObjectType.RoomsStatus__c.fields.getMap();
	    	if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
	    		return req;
	    	}
	    	// 2019/09/15 Security Check BY zyz END
	    	List<RoomsStatus__c> rStatusLst = new List<RoomsStatus__c>();
	    	if (!updRoomLst.isEmpty()) rStatusLst.addAll(updRoomLst);
	    	if (!badRoomLst.isEmpty()) rStatusLst.addAll(badRoomLst);
	    	if (!rStatusLst.isEmpty()) upsert rStatusLst;
    	} catch (Exception e){
    		Database.rollback(sp);
    		if (e.getMessage().contains(Label.MSG_012_0466)){
    			req.message = Label.MSG_012_0466 + ' \n';
    		} else if (e.getMessage().contains(Label.MSG_9104)){
                req.message = Label.MSG_9104;
            } else {
    			req.message = e.getMessage();
    		}
    		badRoomLst = new List<RoomsStatus__c>();
    	}
    	List<String> repRoomLst = new List<String>();
    	if (remoteInfos != null) {
	    	String viewMode = CommUtils.nullToBlank(remoteInfos[0].viewMode);
	    	String queryDateStr = CommUtils.nullToBlank(remoteInfos[0].queryDate);
	    	Date processDate = CommUtils.stringToDate(queryDateStr);
	    	//刷新整个roomid里的数据
	    	TimeModel curModeInfo = new TimeModel(processDate, viewMode);
	    	for (Id roomId : roomSet ) repRoomLst.add(roomId);
	    	List<RoomsStatus__c> refreshRoomLst = new RoomStatusManager().queryBadRoomList(curModeInfo.beginDate,curModeInfo.lastDate,roomSet);
	    	if (!refreshRoomLst.isEmpty()) {
		    	for (RoomsStatus__c r : refreshRoomLst ){
		    		BadRoomInf badRoomInfo = new BadRoomInf(r) ;
					badRoomInf.add(badRoomInfo);
		    	}
	    	}
    	}
    	req.infos = badRoomInf;
    	//req.rmvs = rmvLst;
    	req.roomArr = repRoomLst;
    	return req;
    	
    	
    }
    // 2016/11/22 故障部屋一括登録機能対応 END
	// 2017/01/25 新規画面の項目自定義機能　by　zy　BEGIN
	//原画面默认字段名及对应关系
	private static final  Map<String,String> windowDefFieldMap = new Map<String,String>{'relcontact__c' => 'relcontact', 'reftypeofrooms__c' => 'refTypeOfRooms', 'name' => 'leadName', 'entrytime__c' => 'entryDate', 'relcontact__r.katakana__c' => 'katakana', 'field4__c' => 'entryTime', 'relcontact__r.kananame1__c' => 'kanaName', 'departure__c' => 'departureDate', 'relcontact__r.phone' => 'custPhone', 'field3__c' => 'departureTime', 'staypersons__c' => 'stayPerson', 'staysnums' => 'staysNums', 'rroom__c' => 'brooms', 'field310__c' => 'plan','field315__c' => 'paymentType', 'bookingrooms' => 'broomNum', 'comment3__c' => 'comment3', 'field2__c' => 'channel','segment__c'=> 'segment','seminarorderflg__c'=> 'seminarorder','extrabedchk__c'=> 'extrabedchk'};
	//被排除字段集合
    public List<CustomField> hadRenderFields{get;set;}
    public List<SectionInfo> newLPg{get;set;}
    // 部屋名[transient]
    private static final String blankString = '$_blank_$';
   	public Decimal widthPx{get; set;}
   	public String heightPx{get; set;}
    public String leadFields{get;set;}
    public String mapleadPingField{get;set;}
    public String contactFields{get;set;}
    //原画面默认字段名及对应关系
    public Boolean isLineHeightFlg{get;set;}
    public String leadFieldsAllStr{get;set;}
    public String contactMapFields{get;set;}
    public Map<String,String> styleMap{get;set;}
	//新规窗口XML读取
    private void loadInsertWindow() {
//system.debug(logginglevel.info,'RoomTypeInventoryLeadInputExtendFieldsXml:::');
		
		styleMap = new Map<String,String>();
		
	    //页面所有字段列表
	    List<String> fieldsSplits = new List<String>();
	    //无效字段集合
		set<String> dumyFieldSet = new set<String>();
		//不可为空字段集合
	    set<string> requiredSet = new set<string>{'relcontact__c','name','staypersons__c','field4__c','field2__c','field3__c'};
	    newLPg = new List<SectionInfo>();
	    // 拡張予約項目を定義する
	    String odVerFiledStr = '';
	    Set<String> nowFieldSet = new Set<String>(fieldsSplits);
	    List<String> oneSectionPageStringLst = new List<String>();
	    boolean oldVersionFlag = false;
        Integer showVersion = CommConst.APPOTION_NEWBOOKING_VER;
		isPlanDetailFlag = false;
        oldVersionFlag = (showVersion != 2);
        //2017/02/28 新版本対応　by zy BEGIN
        //新版本不check此flag
        if (!oldVersionFlag) { 
        	isHaveSeminar = true;
        	isHaveEbInfo = true;
        }
		//2017/02/28 新版本対応　by zy END
		// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
        isBasePlanFlag = false;
        // 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
	    // 拡張予約項目を定義する
        String xmlName = (oldVersionFlag ? 'RoomTypeInventoryLeadInputExtendFieldsXml' : 'RoomTypeInventoryLeadInputExtendFieldsXml_V2');
	    try{
//system.debug(logginglevel.info,'branchShopNm:::' + branchShopNm);
		    Dom.XMLNode targetNode = CommXmlUtils.parseXmlDoc(xmlName,branchShopNm);
		    // 2016/10/12 見積明細設定機能対応 BEGIN by zh
			//プラン明細フラグ
	        Dom.XmlNode mitumoriNode =  targetNode.getChildElement('MITUMORIFLAG', null);
	        if(mitumoriNode != null) {
	            String mitumoriContent = mitumoriNode.getText();
				isPlanDetailFlag = boolean.valueOf(mitumoriContent);
				// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
				// 2020/06/03 6457 bug fix BY zyz BEGIN
				/*
                if (isPlanDetailFlag) {
                    isBasePlanFlag = boolean.valueOf(CommUtils.nullToBlank(mitumoriNode.getAttribute('BASEPLANFLAG',null)));
                }
                */
                // 2020/06/03 6457 bug fix BY zyz END
                // 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
	        }
	        // 2016/10/12 見積明細設定機能対応 END by zh
			//排除字段
			Dom.XmlNode exuteFields =  targetNode.getChildElement('EXUTEFIELD', null);
			if (exuteFields != null) {
				String excuteStrFields = CommUtils.nullToBlank(exuteFields.getText()).deleteWhitespace().toLowerCase();
				if (!CommUtils.isBlank(excuteStrFields)) dumyFieldSet.addAll(excuteStrFields.split(','));
//system.debug(logginglevel.info,'dumyFieldSet:::' + dumyFieldSet);
			}
			//非空字段
			Dom.XmlNode requiredFields =  targetNode.getChildElement('REQUIREDFIELDS', null);
			if (requiredFields != null) {
				String requiredFieldsDef = CommUtils.nullToBlank(requiredFields.getText().deleteWhitespace()).toLowerCase();
				if (!CommUtils.isBlank(requiredFieldsDef)) {
					requiredSet = new Set<String>();
					requiredSet.addAll(requiredFieldsDef.split(','));
//system.debug(logginglevel.info,'requiredSet:::' + requiredSet);
				}
			}
			
			// 項目幅のサイズを定義する
            Dom.XmlNode columnFields =  targetNode.getChildElement('COLNUMSIZE', null);
            if (columnFields != null) {
                String columnSize = CommUtils.nullToBlank(columnFields.getText()).deleteWhitespace();
                for (String col : columnSize.split(',')){
                    if(CommUtils.isBlank(col)) continue;
                    String[] colArr = col.split(':');
                    if ( colArr.size() >= 2) styleMap.put(colArr[0].toLowerCase(),'width:'+colArr[1]);
                }
//system.debug(logginglevel.info,'styleMap:::' + styleMap);
            }
			
 			// 店舗情報はＸＭＬから取得する
		    Dom.XmlNode shopFields =  targetNode.getChildElement('FIELDS', null);
 			//存在FIELDS节点
		    if(shopFields != null){
		    	//节点['FIELDS']下 含有的字符
 				odVerFiledStr = CommUtils.nullToBlank(shopFields.getText()).deleteWhitespace();
		    	//遍历FILEDS下所有节点
		    	for (Dom.XmlNode c : shopFields.getChildElements()) {
		    		//SECTION节点
			        if(c.getName() == 'SECTION'){
			        	//新规SECTION
			            SectionInfo p = new SectionInfo();
			            //表头信息
			            p.title = c.getAttribute('TITLE',null);
			            //一行显示列数
			            p.columnsInt = CommUtils.nullToIntZero( c.getAttribute('COLNUM',null));
			            //SECTION 显示字段名 去掉空格 如果是null转成空字符
			            String childFields = CommUtils.nullToBlank(c.getText()).deleteWhitespace();
			            //根据‘，’截取字段名并转换成小写格式
			            List<String> splitFields = childFields.trim().toLowerCase().split(',');
			          	//一个SECTION中的所有字段列表
			            oneSectionPageStringLst = new List<String>();
			            //截取字符串遍历
			            for (String fieldName : splitFields) {
			            	//判断是占位符号或者页面原有项目中不包含此字段的字段
			                if (fieldName == blankString || !nowFieldSet.contains(fieldName)){
			                    fieldsSplits.add(fieldName);
			                    nowFieldSet.add(fieldName);
			                    oneSectionPageStringLst.add(fieldName);
			                }
			                if(!styleMap.containsKey(fieldName)) styleMap.put(fieldName,'');
			            }
			            p.add(oneSectionPageStringLst);
			            newLPg.add(p);
			        }
		    	}
		    }else{
		    	//throw new CommException('指定の店舗コードの定義情報を見つかりません。['+pShopCd+']');
		    }
	    }catch (Exception e){
	    	system.debug(logginglevel.info,'e:::' + e.getStackTraceString());
	    }
	    //未做成SECTION列表
	    if(newLPg.isEmpty()){
	    	//将默认的信息做成SECTION
	    	defaultNewLeadPage(odVerFiledStr.toLowerCase(),isPlanDetailFlag);
//system.debug(logginglevel.info,'fieldsSplits:::' + fieldsSplits);
		}else {
			//2017/02/28 新版本対応　by zy BEGIN
			Set<String> fieldSet = windowDefFieldMap.keySet();
			if (!oldVersionFlag){
				fieldSet.remove('seminarorderflg__c');
				fieldSet.remove('extrabedchk__c');
			}
			newLPg[newLPg.size() -1].add(fieldSet);
			//2017/02/28 新版本対応　by zy END
		}
		processFileds(newLPg,dumyFieldSet,requiredSet);
//system.debug(logginglevel.info,'newLPg:::' + newLPg);
//system.debug(logginglevel.info,'dumyFieldSet:::' + dumyFieldSet);
//system.debug(logginglevel.info,'newLPg:::' + newLPg);
		//processXmlInputMessage(fieldsSplits, newLPg , dumyFieldSet,requiredSet);
    }
    
	private void processFileds(List<SectionInfo> curPLst , Set<String> dumyFieldSet,Set<String> requiredSet){
    	contactFields = '';
    	contactMapFields = '';
    	//字段前缀	
	    String nameSpace = CommBaseCtrl.getNs();
	    //参照字段MAP
	    Map<String,Map<String, Schema.DescribeFieldResult>> refModelValueMap = new Map<String,Map<String, Schema.DescribeFieldResult>>();
	    //字段名对应字段详细信息MAP 字段名为小写
	 	Map<String, Schema.DescribeFieldResult> modelDeafaultValuesMaps = CommSqlUtils.getAllFieldLst(Lead__c.sObjectType,false,true);
	    //已经遍历过一次的字段集合
		Set<String> hadUseDefFieldSet = new Set<String>();	
		Set<String> contactSet = new Set<String>{'katakana__c','kananame1__c','phone'};
		//遍历XML读取到的每个section
		for (SectionInfo  sec : curPLst) {
			//遍历每个section 中字段列表
			for (String fieldName : sec.fieldLst) {
//System.debug(logginglevel.info,'fieldName:::' + fieldName);
//System.debug(logginglevel.info,'hadUseDefFieldSet:::' + hadUseDefFieldSet);
				//页面排除字段
				//2017/03/01 bug fix by zy BEGIN
				if (dumyFieldSet.contains(fieldName)) {
					String lowerName = fieldName.toLowerCase();
					if (lowerName.contains('relcontact__r.')){
						lowerName = lowerName.replace('relcontact__r.','');
						if(contactSet.contains(lowerName)) contactSet.remove(lowerName);
					}
					continue;
				}
				//2017/03/01 bug fix by zy END
				//字段重复出现处理
				if (hadUseDefFieldSet.contains(fieldName)) continue;
				//定义字段作成
				CustomField cus = new CustomField();
				//字段已读入 空占位不进行判断
				if (fieldName != blankString) hadUseDefFieldSet.add(fieldName);
				//非空空的字段设置
				if (requiredSet.contains(fieldName)) {
					cus.isRequired = true;
				}
				//自定义size设定
				if (styleMap.containsKey(fieldName)) {
					cus.fieldStyle = styleMap.get(fieldName);
				}
				
				//如果添加非常规字段则不进行此步处理,原页面MAP中包含此字段跳过处理
	    		if(windowDefFieldMap.containsKey(fieldName)) {
	    			cus.fieldType = windowDefFieldMap.get(fieldName);
	    			sec.add(cus);
//System.debug(logginglevel.info,'cus:::' + cus);
		    		continue;
	    		}
	    		//若字段为参照关系
		    	if(fieldName.contains('__r')){
		    		//截取’.‘之前的字符串
		    		String refKey = fieldName.substringBefore('.');
		    		//将__r转成__c
		    		String refFieldName = refKey.replace('__r','__c');
		    		//查看字段名存在于Lead__c中
		    		if(modelDeafaultValuesMaps.containsKey(refFieldName)){
		    			//取的字段的描述信息
		    			Schema.DescribeFieldResult dr = modelDeafaultValuesMaps.get(refFieldName);
		    			//字段是参照关系
		    			if(dr.getType() == DisplayType.Reference){
		    				//参照MAP中未做成此字段的关联对象
		    				if(!refModelValueMap.containsKey(refKey)){
		    					//获取关联对象的SOBJECT定义
		    					SObjectType referenceObj = dr.getReferenceTo()[0];
		    					//根据获取的SOBJECT的类型，新规一个对象
		    					Sobject obj = referenceObj.newSObject();
		    					//关联字段名（小写）
		    					String relationName = dr.getRelationshipName().toLowerCase();
		    					//如果存在前缀且关联字段名包含前缀 则去掉前缀
		            			if(!CommUtils.isBlank(nameSpace) && relationName.startsWith(nameSpace)) relationName = relationName.replace(nameSpace,'');
		            			//将字段=>字段描述的MAP 存入关系MAP中
		    					refModelValueMap.put(refKey,CommSqlUtils.getAllFieldLst(referenceObj,false,true));
		    				}
		    				//字段名
		    				String refFiledName = fieldName;
		    				//字段前缀
		    				String refNamePrix = refKey + '.';
		    				//当前字段名包含此前缀,将前缀去掉剩下参照对象字段名
		    				if(fieldName.contains(refNamePrix)) refFiledName = fieldName.replace(refNamePrix,'');
		    				//取出参照字段的字段描述
		    				Schema.DescribeFieldResult refDr = refModelValueMap.get(refKey).get(refFiledName.trim());
		    				//若取不出则不进行任何处理
		    				if(refDr == null) continue;
		    				//拼写参照的字段名
		    				String refName = dr.getRelationshipName() + '.' + refDr.getLocalName();
							//如果是客户对象
		    				if(refName.contains('elcontact__r')){
		    					cus.fieldType = 'contact';
		    					cus.localName = refDr.getLocalName();
		    					cus.name = refDr.getName();
			                    //contactFields+= refDr.getLocalName() + ',';
			                    contactSet.add(refDr.getLocalName().toLowerCase());
			                    contactMapFields = checkAndAddFiledName(refDr,contactMapFields);
			                //其他参照对象
		    				} else {
		    					cus.fieldType = 'ref';
		    					cus.localName = refName;
		    					mapleadPingField = checkAndAddFiledName(refDr,mapleadPingField);
		    					leadFieldsAllStr += refName + ',';
		            			leadFields += refName + ',';
		    				}
		    				//将字段名对应的字段label存放到集合中
		    				cus.fieldLabel = refDr.getLabel();
		    			}
		    		}
		    	//字段是正常字段
		    	} else {
		    		// Get the Type corresponding to the class name
		    		//遍历字段是予約对象定义的字段
					if (modelDeafaultValuesMaps.containsKey(fieldName)){
						//字段描述
						Schema.DescribeFieldResult dr = modelDeafaultValuesMaps.get(fieldName);
						//如果集合中不存在字段名，则将对应关系保存到集合中去
						cus.localName = dr.getLocalName();
						cus.fieldLabel = dr.getLabel();
						cus.fieldType = 'lead';
		            	leadFieldsAllStr += dr.getLocalName() + ',';
		            	leadFields += dr.getLocalName() + ',';
		            	//排除不可更新字段
			        	mapleadPingField = checkAndAddFiledName(dr,mapleadPingField);
			        //无效字段名
					} else if (fieldName != blankString) continue;
		        }
		        sec.add(cus);
			}
		}
		hadRenderFields = new List<CustomField>();
		//将默认值转换成页面隐藏类型 
		for (String key : windowDefFieldMap.keySet()) {
			if (!hadUseDefFieldSet.contains(key)) hadRenderFields.add(new CustomField(key,windowDefFieldMap.get(key)));	
		}
//system.debug(logginglevel.info,'hadRenderFields::' + hadRenderFields);		
		//遍历set集合
		for (String fieldStr : contactSet) {
			//作成客户字段
			contactFields += fieldStr + ',';
		}
	}
	
	/*
	* 默认新規画面作成
	*/
	private void defaultNewLeadPage(String fieldXmlStr , boolean isPlanDetailFlag) {
//system.debug(logginglevel.info,'fieldXmlStr::' + fieldXmlStr);
		String planStr = '';
		List<String> newWindowDefSet = new List<String>{};
		if(!isPlanDetailFlag){
			planStr = 'field310__c,$_blank_$';
		}
//system.debug(logginglevel.info,'planStr::' + planStr);
		String fieldStr = 'relcontact__c, reftypeofrooms__c, name, entrytime__c, relcontact__r.katakana__c,field4__c, relcontact__r.kananame1__c, departure__c, relcontact__r.phone,'
						+'field3__c, staypersons__c,seminarorderflg__c, staysnums,extrabedchk__c, rroom__c,bookingrooms, _planStr_,'
						+'field315__c,$_blank_$, field2__c,$_blank_$, segment__c,$_blank_$';
		fieldStr = fieldStr.deleteWhitespace().replace('_planStr_',planStr);
//system.debug(logginglevel.info,'fieldStr::' + fieldStr);
		newWindowDefSet.addAll(fieldStr.trim().split(','));
		
		/*List<String> newWindowDefSet = new List<String>{'relcontact__c', 'reftypeofrooms__c', 'name', 'entrytime__c', 'relcontact__r.katakana__c', 
														'field4__c', 'relcontact__r.kananame1__c', 'departure__c', 'relcontact__r.phone', 
														'field3__c', 'staypersons__c','seminarorderflg__c', 'staynightcal__c','extrabedchk__c', 'rroom__c','broomnum', 'field310__c','$_blank_$',
														'field315__c','$_blank_$', 'field2__c', '$_blank_$', 'segment__c','$_blank_$'};*/
		//旧版本中扩展字段不为空
		if (!CommUtils.isBlank(fieldXmlStr)) {
			newWindowDefSet.addAll(fieldXmlStr.trim().split(','));
//system.debug(logginglevel.info,'newWindowDefSet::' + newWindowDefSet);	
		}
		SectionInfo defaultPg = new SectionInfo();
    	defaultPg.columnsInt = 2;
    	defaultPg.add(newWindowDefSet);
    	newLPg.add(defaultPg);
    	//特记事项做成BEGIN
    	SectionInfo commentPg = new SectionInfo();
    	commentPg.columnsInt = 1;
    	commentPg.add(new List<String>{'comment3__c'});
    	newLPg.add(commentPg);
//system.debug(logginglevel.info,'newLPg::' + newLPg);
	}
	/*
	* 判断字段是否是特殊类型
	*/
	private String checkAndAddFiledName(Schema.DescribeFieldResult dr, String  mapFields){
		if(dr.getType() == DisplayType.Date){
			mapFields += dr.getName() + ':' +  'Date,';
		} else if(dr.getType() == DisplayType.DateTime) {
			mapFields += dr.getName() + ':' +  'DateTime,';
		} else if(dr.getType() == DisplayType.textarea){ 
			mapFields += dr.getName() + ':' +  'TextArea,';
		} else if(dr.getType() == DisplayType.Boolean){ 
			mapFields += dr.getName() + ':' +  'Boolean,';
		} else if(dr.getType() == DisplayType.Phone){ 
			mapFields += dr.getName() + ':' +  'Phone,';
		} else if(dr.getType() == DisplayType.Email){ 
			mapFields += dr.getName() + ':' +  'Email,';
		}
		return mapFields;
	}
	//section定义信息
	public class SectionInfo{
		public Integer columnsInt{get;set;}
		public List<String> fieldLst{get;set;}
		public String title{get;set;}
		public List<CustomField> cusFields{get;set;}
		public boolean isHeadShowFlag{get{ return !CommUtils.isblank(title);}}
		public SectionInfo(){
		    columnsInt = 2;
		    fieldLst = new List<String>(); 
		    cusFields = new List<CustomField>();
		}
		public void add(Set<String> fLst){
		    fieldLst.addAll(fLst);
		}
		public void add(List<String> fLst){
		    fieldLst.addAll(fLst);
		}
		public void add(CustomField cus) {
			cusFields.add(cus);	
		}
	}
	//字段信息
    public class CustomField{
    	public String fieldName{get;set;}
    	public String fieldLabe{get;set;}
    	public boolean isRequired{get;set;}
    	public String fieldLabel{get;set;}
    	public String fieldType{get;set;}
    	public boolean isRefFlag{get;set;}
    	public String localName{get;set;}
    	public String name{get;set;}
    	public String fieldStyle{get;set;}
    	public CustomField(){
    		isRequired = false;
    		isRefFlag = false;
    		fieldType = 'blank';
    	}
    	public CustomField(String name,String fType){
    		fieldType = fType;
    		fieldName = name;
    	}
    }	
	
	
	/*
	* お客様のメッセージ取得する
	* contactFields:XML定義のお客様の項目
	* cId:お客様ID
	*/
	private static Contact queryContact(String contactFields,String cId){
		set<string> contactFieldsSet = new set<string>();
		Contact c = new Contact();
		contactFieldsSet.add('id');
		contactFieldsSet.addAll(Commutils.nullToBlank(contactFields).toLowerCase().deleteWhitespace().split(','));
		string contactQueryFields = '';
		//2016/11/29 tolabel error fix by zy BEGIN
		map<String, Schema.DescribeFieldResult> modelContactDeafaultValuesMap = CommSqlUtils.getAllFieldLst(Contact.sObjectType,true,true);
		//2016/11/29 tolabel error fix by zy END
		for (String key : contactFieldsSet) {
			if (CommUtils.isBlank(key)) continue;
			//2016/11/29 tolabel error fix by zy BEGIN
			if (modelContactDeafaultValuesMap.containsKey(key)){
				Schema.DescribeFieldResult dr = modelContactDeafaultValuesMap.get(key);
				if (dr.getType() == DisplayType.Picklist || dr.getType() == DisplayType.MultiPicklist){
	    			key = 'toLabel(' + dr.getName() + ')';
//system.debug(logginglevel.info,'key:::' + key);
	    		}
			}
			//2016/11/29 tolabel error fix by zy END
			contactQueryFields+= key + ',';
		}
		contactQueryFields = contactQueryFields.removeEnd(',');
		
		String contactQuery = 'Select ' + contactQueryFields + ' From Contact';
		String contactId = cId;
		contactQuery += ' where id=:contactId';
		List<Contact> contactLst = Database.query(contactQuery);
		if(!contactLst.isEmpty()) c = contactLst[0];
		return c; 
	}
	
	public String getDateTimeFormatStr() {
        return CommBaseCtrl.getDateTimeFormat();
    }
    public String getDateFormatStr() {
        return CommBaseCtrl.getDateFormat();
    }	
	// 2017/01/25 新規画面の項目自定義機能　by　zy　END
	// 2017/03/27 故障部屋一括解除機能対応 BEGIN
	Class RoomClean{
		List<String> dates;
		//部屋id
		String rid;
		//故障id
		String bid;
		//オブジェクトのタイプ
		String otp;
		// 故障房间为多泊判断
		boolean more;
		// 2018/02/07 故障時刻登録　by zy BEGIN
		// 故障部屋の時刻機能追加
		string start;
		String endtime;
		// 2018/02/07 故障時刻登録　by zy END
	}
	// 2017/03/27 故障部屋一括解除機能対応 END
	// remoteaction 用inner class
    public class RemoteInfo{
    	// time模式
		String viewMode;
		// 指定日
		String queryDate;
		// 除外info
		String expectInfo;
	}
    // 2018/02/07 故障時刻登録　by zy BEGIN
    private static List<RoomsStatus__c> createRoomStatus(RoomsStatus__c rs){
    	String statusName = rs.name;
    	String roomId = rs.RoomRef__c;
    	List<RoomsStatus__c> roomStatusLst = new List<RoomsStatus__c>();
    	Integer between = rs.StatusBeginDate__c.daysBetween(rs.StatusEndDate__c);
    	String start = rs.BeginTime__c;
    	String endTime = rs.OverTime__c;
    	for (integer i = 0 ; i <= between ; i++) {
    		date curDt = rs.StatusBeginDate__c.addDays(i);
    		RoomsStatus__c roomStatus = new RoomsStatus__c( Name = statusName, RoomRef__c = roomId ,
    										StatusBeginDate__c = curDt, StatusEndDate__c = curDt, 
    										Status__c = CommConst.ROOM_ST_TYPE_BED);
    		roomStatus.BeginTime__c = RoomStatusManager.DEF_START_TIME;
			roomStatus.OverTime__c = RoomStatusManager.DEF_END_TIME;
    		if ( i == 0 ) 
				if (!CommUtils.isBlank(start)) roomStatus.BeginTime__c = start;
			if ( i == between ) 
				if (!CommUtils.isBlank(endTime)) roomStatus.OverTime__c = endTime;
    		roomStatusLst.add(roomStatus);
    	}
    	return roomStatusLst;
    }
    // 2018/02/07 故障時刻登録　by zy END
    public boolean isShowGroupClConfirm{get{return CommConst.APPOTION_CHECKIN_GROUPCLCONFIRM;} private set;}
    // 過去の未割り当て予約アサインできる制御フラグ
    public Boolean isShowHisAssignWinFlg{get{ return CommConst.APPOTION_ROOMTYPE_INPUT_PASTDATA;}}
    public String filterHidRoom{get;set;}
    public String filteText{get;set;}
    public String moveFromLeadId{get;set;}
    public String moveToRoomId{get;set;}
	@remoteaction 
    global static String updateLeadMap(String leadId,String roomId,Boolean showToday,String queryDt) {
    	Date processDt = CommUtils.stringtoDate(queryDt);
    	RoomIndicatorInfo roomIndicator = new RoomIndicatorInfo(leadId,roomId,showToday, processDt);
    	roomIndicator.moveFromLeadId = leadId;
    	roomIndicator.moveToRoomId = roomId;
    	String result = '';
    	// 2018/06/06 編集権限チェックできる対応 BEGIN
    	Savepoint sp = Database.setSavepoint();
    	// 2018/06/06 編集権限チェックできる対応 END
    	try{
    		roomIndicator.updateMemoryRoomLeadMap();
    	}catch(exception e) {
    		// 2018/06/06 編集権限チェックできる対応 BEGIN
    		//result = e.getStackTraceString();
    		system.debug(loggingLevel.info, 'EXCEPTION='+e.getStackTraceString());
    		DataBase.rollback(sp);
		String errMsg = e.getMessage();
		result = CommUtils.getFieldValidationMessage(e.getMessage());
		// 2018/06/06 編集権限チェックできる対応 END
    	}
    	if (!CommUtils.isBlank(roomIndicator.errorMsg)) result += roomIndicator.errorMsg;
    	return result;
    }
    // 2018/02/06 予約検索条件はレコードタイプ外す改善対応 BEGIN
    private static final Boolean leadQueryRecTypeFlg = (CommDefine__c.getOrgDefaults().RoomIndicatorQueryLimitFlg__c == null ? false : CommDefine__c.getOrgDefaults().RoomIndicatorQueryLimitFlg__c);
    // 2018/02/06 予約検索条件はレコードタイプ外す改善対応 END
    // 画像数式処理用Pattern
    private static final Pattern pTool = Pattern.compile('.*src=["](/resource.*?)["].*');
    /**
	* 団体、単体の予約リストに表示する表示、[未割り当て予約]
	* 表示方式はTREEで(VIEW)
	**/
	// 2018/11/08 未割り当てウインドウの予約も該当部屋タイプのみ情報を表示する WGCH BEGIN
	/* noAssingLeadInfoAll => 此方法已经弃用 */
	@remoteAction
	global static List<RoomIndicatorInfo.NoAssignLeadInfoExt> noAssingLeadInfoAll(String queryDt, String branchShopCd, Boolean showToday,String viewMode) {
		return noAssingLeadInfoAllNew(queryDt, branchShopCd, showToday, viewMode, new String[]{});
	}
	@remoteAction
	global static List<RoomIndicatorInfo.NoAssignLeadInfoExt> noAssingLeadInfoAllNew(String queryDt, String branchShopCd, Boolean showToday,String viewMode, String[] roomTypeSelectId) {
		List<String> roomTypeIdLst = new List<String>();
		for(String roomTypeId : roomTypeSelectId){
			if(!CommUtils.isBlank(CommUtils.nullToBlank(roomTypeId))) roomTypeIdLst.add(CommUtils.nullToBlank(roomTypeId));
		}
	// 2018/11/08 未割り当てウインドウの予約も該当部屋タイプのみ情報を表示する WGCH END
		// 指定日により、
		Date searchDt = (String.isEmpty(queryDt)) ? Date.today() : CommUtils.stringToDate(queryDt);
		TimeModel gModeInfo = new TimeModel(searchDt, viewMode);
		Date endDt  = gModeInfo.lastDate;
        // 2017/11/14　未割り当て予約並べる by zy BEGIN
        String orderSQL = getAssignOrderQuery(branchShopCd);
        // 2017/11/14　未割り当て予約並べる by zy END
        List<Id> recTypeLst = RoomIndicatorInfo.getLeadBookingRecTypeLst();
		// 到着日は指定日と同じ、有効な予約データ、部屋番号は未設定場合、
		Integer cancelBool = CommConst.LEAD_ST_CANCEL_FLG;
        String noAssingQuerySQL = ' Select id, Name, Field353__c,EntryTime__c,Departure__c,Field3__c,Field4__c, LeadIndexRef__c,RoomGroupNo__c,LeadIndexSubId__c, Relcontact__r.Name, refTypeOfRooms__r.Name,refTypeOfRooms__c From Lead__c ';
		String noAssingQuery = ' Where CancelBool__c != : cancelBool ';
		// 2018/02/06 予約検索条件はレコードタイプ外す改善対応 BEGIN
        if (leadQueryRecTypeFlg == false ) {
//System.debug(loggingLevel.info, '======= STEP1-001[1] =========');
        // 2018/02/06 予約検索条件はレコードタイプ外す改善対応 END
		noAssingQuery += ' And RecordTypeId in :recTypeLst ';
        // 2018/02/06 予約検索条件はレコードタイプ外す改善対応 BEGIN
        }
//System.debug(loggingLevel.info, '======= STEP1-001[2] =========');
        // 2018/02/06 予約検索条件はレコードタイプ外す改善対応 END
		noAssingQuery += ' And Rroom__c = null ';
		noAssingQuery += ' And DAY_ONLY(convertTimezone(EntryTime__c)) >= :searchDt ';
		// 多日mode下时间区分
		if (viewMode == CONST_VIEWMODE_1 || viewMode == CONST_VIEWMODE_2 || viewMode == CONST_VIEWMODE_3 ) noAssingQuery += ' And DAY_ONLY(convertTimezone(EntryTime__c)) < :endDt ';
		// 单日mode下时间区分
		else noAssingQuery += ' And DAY_ONLY(convertTimezone(EntryTime__c)) <= :endDt ';
		 
		// 2013/09/02 ADD
		if (!CommUtils.isBlank(branchShopCd)) noAssingQuery += ' And (refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c = \'' + String.escapeSingleQuotes(branchShopCd) + '\' OR refTypeOfRooms__c = null) ';
		//if (!String.isEmpty(queryRoomType)) noAssingQuery += ' And refTypeOfRooms__c = :queryRoomType ';
		// 2018/11/08 未割り当てウインドウの予約も該当部屋タイプのみ情報を表示する WGCH BEGIN
		if(CommConst.ROOM_TYPE_SELECT_MODE == 1 && !roomTypeIdLst.isEmpty()) noAssingQuery += ' And refTypeOfRooms__c in: roomTypeIdLst ';
		// 2018/11/08 未割り当てウインドウの予約も該当部屋タイプのみ情報を表示する WGCH END
		String preQueryStr = 'select id,LeadIndexRef__c,RoomGroupNo__c,LeadIndexSubId__c from lead__c '+ noAssingQuery + ' order by LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c,EntryTime__c';
		List<Lead__c> preQueryLead = DataBase.query(preQueryStr);
		set<id> leadSet = new set<id>();
		Set<String> leadKeySet = new Set<String>();
		for(Lead__c item : preQueryLead) {
			// 同じ予約ＩＮＤＥＸ、予約ＩＮＤＥＸＳＵＢ、グループＮＯの場合、同じ予約連泊情報を認識する
			String leadKey =	CommUtils.nullToBlank(item.LeadIndexRef__c) 
					+ '_' +	CommUtils.nullToBlank(item.LeadIndexSubId__c) 
					+ '_' +	CommUtils.nullToZero(item.RoomGroupNo__c);
			if (leadKeySet.contains(leadKey)) continue;
			leadKeySet.add(leadKey);
			leadSet.add(item.id);
		}
		String aftQueryStr = noAssingQuerySQL + ' where id in:leadSet' ;
		// 2017/11/14　未割り当て予約並べる by zy BEGIN
		if (!CommUtils.isBlank(orderSQL)) aftQueryStr += ' order by ' + orderSQL;
		// 2017/11/14　未割り当て予約並べる by zy END
		List<Lead__c> noAssignList = DataBase.query(aftQueryStr);
		// Map<LeadIndex_ID, 予約情報>
		//Map<Id, RoomIndicatorInfo.NoAssignLeadInfoExt> leadMap = new Map<Id, RoomIndicatorInfo.NoAssignLeadInfoExt>();
		Map<String, RoomIndicatorInfo.NoAssignLeadInfoExt> leadMap = new Map<String, RoomIndicatorInfo.NoAssignLeadInfoExt>();
		//
		List<RoomIndicatorInfo.NoAssignLeadInfoExt> rsList = new List<RoomIndicatorInfo.NoAssignLeadInfoExt>();
		// 2017/11/14　未割り当て予約並べる by zy BEGIN
		List<Id> leadIndexIdLst = new List<Id>();
		// map<日付,list<leadindexのid>> 日別の予約インデックス順番情報を格納する
		Map<String,List<Id>> leadIndexIdLstMap = new Map<String,List<Id>>();
		// 2017/11/14　未割り当て予約並べる by zy END
		Map<String,RoomIndicatorInfo.NoAssignLeadInfoExt> curItemMap = new Map<String,RoomIndicatorInfo.NoAssignLeadInfoExt>();
		//RoomIndicatorInfo.NoAssignLeadInfoExt curItem = null;
		List<Date> entryDtLst = new List<Date>();
		// 多日mode
		for (Lead__c item : noAssignList) {
			Id leadIndexId = item.LeadIndexRef__c;
			Date entryDt = item.entrytime__c.date();
			String dtStr = entryDt.format();
			// 日単位のタイトル情報を設定する
			if (!curItemMap.containsKey(dtStr)) {
			    // 並び順日付情報を格納
				entryDtLst.add(entryDt);
				// １日間の未割り当て予約情報を格納する
				RoomIndicatorInfo.NoAssignLeadInfoExt curItem = new RoomIndicatorInfo.NoAssignLeadInfoExt(true);
				curItem.id = item.entrytime__c.date().format();
				curItem.text = dtStr;
				curItemMap.put(dtStr,curItem);
				// 日別の予約インデックス配列初期化する
				leadIndexIdLstMap.put(dtStr,new List<Id>());
			}
			// 同じ到着日の未割り当て予約情報を取得する
			String indexKey = dtStr + '_' + leadIndexId;
			// 日別予約インデックス別の予約情報]
			if (!leadMap.containsKey(indexKey)) {
				// 第一階層で、顧客名で階層名に設定を行う、一括設定する場合、該当階層に含めの予約は全部自動部屋アサインを行う
				RoomIndicatorInfo.NoAssignLeadInfoExt noAssItem = new RoomIndicatorInfo.NoAssignLeadInfoExt(true);
				noAssItem.id = leadIndexId;
				noAssItem.text = item.Relcontact__r.Name;
				leadMap.put(indexKey, noAssItem);
				// 該当インデックスのIDを日別のリストに格納する
				leadIndexIdLstMap.get(dtStr).add(leadIndexId);
			}
			// 予約単位の情報を設定して、LeadIndexの配列に設定を行う
			// 子情報ない設定を行う
			RoomIndicatorInfo.NoAssignLeadInfoExt noAssParentItem = leadMap.get(indexKey);
			RoomIndicatorInfo.NoAssignLeadInfoExt noAssChildItem = new RoomIndicatorInfo.NoAssignLeadInfoExt(false);
			noAssChildItem.id = item.Id;
			noAssChildItem.rowNums = noAssParentItem.items.size();
			//noAssChildItem.text = String.valueOf(noAssChildItem.rowNums + 1) + '.' + item.Name;
			noAssChildItem.text = item.Name;//item.Name.length() > 18 ? item.Name.substring(0,18) : item.Name;
			//noAssChildItem.contactName = item.Relcontact__r.Name;
			if (item.refTypeOfRooms__c != null) {
				noAssChildItem.text += '(' + item.refTypeOfRooms__r.Name + ')';
			} else {
				//部屋タイプなし
				noAssChildItem.text += '('+ Label.CONST_008_0115 +')';
			}
			noAssChildItem.roomTypeName = item.refTypeOfRooms__r.Name;
			noAssChildItem.roomTypeId = item.refTypeOfRooms__c;
			String statusIcon = CommUtils.nullToBlank(item.Field353__c);
			if (!String.isEmpty(statusIcon)) {
                Matcher m = pTool.matcher(statusIcon);
                if(m.Matches()) statusIcon = m.group(1);
                else statusIcon = '';
            }
			noAssChildItem.statusIcon = statusIcon;
            // 予約関連の到着時刻と出発時刻情報を格納する
            noAssChildItem.startDateTime = item.EntryTime__c.format('yyyyMMdd') + item.Field4__c;
            noAssChildItem.endDateTime   = item.Departure__c.format('yyyyMMdd') + item.Field3__c;
            noAssParentItem.cssClass = 'noAssignLead';
			noAssChildItem.cssClass = 'noAssignLead';
            // 同じグループの予約情報を追加する
			noAssParentItem.addItem(noAssChildItem);
		}
		// 日期排序
		entryDtLst.sort();
		// 显示内容排序
		for (Date sdt : entryDtLst) {
		    String dt = sdt.format();
		    // 該当日別関連情報を設定する
			if (curItemMap.containsKey(dt)) {
				Integer childItemsInt = 0;
				// 該当日別のタイトル情報を取得する
				RoomIndicatorInfo.NoAssignLeadInfoExt curItem = curItemMap.get(dt);
				// 該当日別格納する予約インデックスリストを取得する
				List<Id> leadIdxLst = leadIndexIdLstMap.get(dt);
				// 該当日別の全て予約インデックスグループ単位で出力情報を設定する
				if (leadIdxLst != null) {
					for (Id leadIdxId : leadIdxLst) {
						String dateKey = dt + '_' + leadIdxId;
						// 該当日の該当予約インデックスの予約情報リストを取得する（N部屋)
						RoomIndicatorInfo.NoAssignLeadInfoExt titleItem = leadMap.get(dateKey);
						titleItem.subdataid = titleItem.subdataid.substringBeforeLast(',');
						//件
						titleItem.text += '　【'+ titleItem.subdataid.split(',').size() +'】' + Label.CONST_008_0116 ;
						childItemsInt += titleItem.items.size();
						curItem.addItem(titleItem);
					}
				}
				curItem.text += '　【'+ childItemsInt +'】' + Label.CONST_008_0116 ;
				curItem.totalInt = childItemsInt;
				rsList.add(curItem);
			}
		}
		return rsList;
	}
	// 2017/11/14　未割り当て予約並べる by zy BEGIN
    // 排序字段内容作成する
    private static String getAssignOrderQuery(String spcd){
    	String orderSQL = '';
    	Map<String, Schema.DescribeFieldResult> modelDeafaultValuesMaps = CommSqlUtils.getAllFieldLst(Lead__c.sObjectType,true,true);
	    // 2016/08/01 店舗設定情報を取得する
	    // 拡張予約項目を定義する
	    String xmlName = 'RoomIndicatorInfoLeadOutputExtendFieldsXml';
	    try{
		    Dom.XMLNode targetNode = CommXmlUtils.parseXmlDoc(xmlName,spcd);
		    Dom.XmlNode sortNode =  targetNode.getChildElement('NOASSIGNSORT', null);
		    if ( sortNode != null ) {
		    	orderSQL = CommUtils.nullToBlank(sortNode.getText());
		    }
		    if ( CommUtils.isBlank(orderSQL)) orderSQL = ' CreatedDate asc';
//System.debug(loggingLevel.info, 'orderSQL===' + orderSQL);
		    // 2017/08/17 ルームインジケータ画面に、縦セルに表示項目をカスタマイズできるように改善対応 WGCH END
	    }catch (Exception e){}
	    return orderSQL;
    }
    // 2017/11/14　未割り当て予約並べる by zy END
    @remoteAction
	global static RoomIndicatorInfo.MsgItem preUpdateMemoryRoomLeadMap(String fromLeadId, String toRoomId, String queryDt, List<Lead__c> fromLeadList, List<Lead__c> toLeadList, Boolean showToday) {
		return RoomIndicatorInfo.preUpdateMemoryRoomLeadMap(null, fromLeadId, toRoomId, null, queryDt, fromLeadList, toLeadList, showToday);
	}
	// 部屋アサインの取消機能対応(NO370)
    @remoteAction
    global static RoomIndicatorInfo.AutoAssignRoomResult autoCancelAssignRoomToLead(String[] fromLeadIds, String queryDt, Boolean showToday) {
    	return RoomIndicatorInfo.autoCancelAssignRoomToLead(fromLeadIds, queryDt, showToday);
    }
    @remoteAction
	global static RoomIndicatorInfo.AutoAssignRoomResult autoAssignRoomToLead(String[] fromLeadIds, String startRoomId, String queryDt, 
															 String nocleanOkRoomIds, String nocleanNgRoomIds, Boolean showToday) {
		Date processDt = CommUtils.stringtodate(queryDt);
        List<String> roomIds = new  List<String>();
        for (RoomsStatus__c roomSt : [select id,StatusEndDate__c,StatusBeginDate__c,name,RoomRef__c,Status__c,IsStockSyncTarget__c,Result__c,Describe__c,TypeOfRoomTypeId__c 
	    										,BeginTime__c,OverTime__c
	    												from RoomsStatus__c 
	    												where Status__c = :CommConst.ROOM_ST_TYPE_CLS and StatusBeginDate__c <= :processDt and StatusEndDate__c >= :processDt and Result__c = :CommConst.LEAD_ROOM_ST_UNCLEAN]) {
        	roomIds.add(roomSt.RoomRef__c);
        }
		return RoomIndicatorInfo.autoAssignRoomToLead(fromLeadIds, startRoomId,queryDt, roomIds,nocleanOkRoomIds,nocleanNgRoomIds,showToday);									
	}
	//お客様の項目は更新フラグ
    public Boolean hadUpdContactFlag{get;set;} 
    public List<SectionInfo> pageLst{get;set;}
	// ご予約へ編集権限あり、なし
	@remoteaction
	global static LeadInfo refreshRoomByLeadId(String leadId,String branchShopNm,String processDateStr,String viewMode,String colSize,String statusCode) {
		LeadInfo leadInf = new LeadInfo();
		Set<Id> roomSet = new Set<Id>();
		List<Lead__c> leadLst = [select id,LeadIndexRef__c,LeadIndexSubId__c,Rroom__c,RoomGroupNo__c from lead__c where id = :leadId];
		if (!leadLst.isEmpty()) {
			String roomIds = '';
			Lead__c newLead = leadLst[0];
			if (newLead.Rroom__c != null) {
				roomIds += newLead.Rroom__c + ',';
				roomSet.add(newLead.Rroom__c);
			}
			// Query SQL
			List<Lead__c> leads = [select id, Name,Rroom__c from Lead__c where LeadIndexRef__c = :newLead.LeadIndexRef__c
												//And LeadIndexSubId__c = :newLead.LeadIndexSubId__c
												//And RoomGroupNo__c = :newLead.RoomGroupNo__c
												//And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 
												Order By EntryTime__c ] ;
			for (Lead__c lead : leads) {
				if (lead.Rroom__c != null) {
					if (roomSet.contains(lead.Rroom__c)) continue;
					roomSet.add(lead.Rroom__c);
					roomIds += lead.Rroom__c + ',';
				}
			}
			if (!CommUtils.isBlank(roomIds)) {
				roomIds = roomIds.removeEnd(',');
				return refreshRoomByIds(roomIds,branchShopNm,processDateStr,viewMode,colSize,statusCode);
			}
		}
		return leadInf;
	}
	// 2018/05/02 タイムテーブルの初期表示の単位値は定義できるように改善 by zy BEGIN
	// カスタム設定の表示モード
	private static String defaultMode{get{return CommDefine__c.getOrgDefaults().TimeTableDefaultMode__c;}}
	private String getDefMode() {
		Map<String,String> defMap = new Map<String,String>{
			'90日' => CONST_VIEWMODE_3, 
			'31日' => CONST_VIEWMODE_1,
			'7日' =>  CONST_VIEWMODE_2,
			'30分' => CONST_VIEWMODE_4,
			'15分' => CONST_VIEWMODE_7,
			'10分' => CONST_VIEWMODE_5,
			'5分' =>  CONST_VIEWMODE_6
		};
		String defaultMode = defMap.get(defaultMode);
		if (CommUtils.isBlank(defaultMode)) defaultMode = CONST_VIEWMODE_1;
		return defaultMode;
	}
	// 2018/05/02 タイムテーブルの初期表示の単位値は定義できるように改善 by zy END
	// 2018/07/27 宿泊税計算 WGCH BEGIN
	public String hotelTaxDefineInfoJson {get{ return JSON.serialize(CommLogicProcess.getHotelTaxDefInstance());}}
	// 2018/07/27 宿泊税計算 WGCH END
	// 2019/01/15 タイムテーブルを開いた際、デフォルトで表示される部屋タイプを指定できるようにする by zy BEGIN
	// COOKIE設定情報
	private CookieInfo cookieInfo;
	private class CookieInfo{
		// 元設定部屋タイプ
		public String spcd;
		// 元設定店舗コード
		public String roomTypeIds;
		public void changeSpcd(String branchCode){
			if (spcd != branchCode) {
				spcd = branchCode;
				roomTypeIds = '';
				RoomScheduleReport.saveCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.DEPARTCODES.name(),'',JSON.serialize(this));
			}
		}
		public void changeRoomType(String typeIds,String branchShopNm){
			if (CommUtils.nullToBlank(roomTypeIds) != typeIds) {
				roomTypeIds = typeIds;
				spcd = CommUtils.nullToBlank(branchShopNm);
				RoomScheduleReport.saveCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.DEPARTCODES.name(),'',JSON.serialize(this));
			}
		}
	}
	// 初期化
	private void initCookieInfo(){
		String cookieJson = getCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.DEPARTCODES.name(),'');
		cookieInfo = new CookieInfo();
		if (!CommUtils.isBlank(cookieJson)) cookieInfo = (CookieInfo)JSON.deserialize(cookieJson,CookieInfo.class);
	}
	private static String getCookieInfo(String subType,String spcd){
		map<String,String> userBookMap = UserConfigCompCtrl.getCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.TIMETABLE,
											UserUtil.CurrentUser.id,spcd);
		String cookieInfo = CommUtils.nullToBlank(userBookMap.get(subType));
	   	return cookieInfo;
	}
	// COOKIE指定内容保存
	private static void saveCookieInfo(String subType,String spcd ,String settingInfo){
		// Cookieからレイアウトモードを取得する
		UserConfigCompCtrl.saveCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.TIMETABLE,
				subType,settingInfo,UserUtil.CurrentUser.id,spcd);
	}
	// 2019/01/15 タイムテーブルを開いた際、デフォルトで表示される部屋タイプを指定できるようにする by zy END
    // 2019/04/30 増税仮対応 WGCH BEGIN
    // 增税商品json数据 
    public String taxIncMstItemJson{get { return CommLogicProcess.getTaxIncMstJson();} private set;}
    // 2019/04/30 増税仮対応 WGCH END
	// 2019/07/31 20190527.04.タイムテーブル、ルームインジケータ、マルチタスク機能編集モードと読み込み専用モード対応必要 by zy BEGIN
	public Boolean notReadOnlyFlg{get;set;}
	// 2019/07/31 20190527.04.タイムテーブル、ルームインジケータ、マルチタスク機能編集モードと読み込み専用モード対応必要 by zy END
	// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
	public static boolean planBrkToHeaderCalFlg{get{ return CommConst.PLAN_BRKTOHEADER_CAL_FLG;} private set;}
	// 2019/10/02 PlanHeader算法切换对应 WGCH END
	// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
	public Integer addRowsMan{get;set;}
	public Boolean isBasePlanFlag{get;set;}
    // 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
}