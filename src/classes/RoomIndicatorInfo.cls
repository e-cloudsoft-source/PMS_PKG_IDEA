/*********************************************
* Roomindicator画面
* 2013/10/28 POPUP画面に「印刷」ボタン追加
*            未割り当予約件数を表示する
* 2013/12/26 予約ステータス表示追加
* 2014/05/22 標識用マークを追加する
* 2014/07/11 お客様名・ご予約名を切り替え機能
* 2014/09/15 一括清掃機能追加
* 2014/11/27 RichEditor機能対応
* 2014/12/25 六輝表示・非表示制御追加（外貨の場合、非表示）
* 2015/09/01 多店舗機能対応
* 2015/10/27 連絡事項共通化
* 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 BEGIN
* 2015/10/29 エラー処理ロジック追加：
*            故障部屋により、泊数変更、ルームChanageなど処理エラーが発生する場合、エラーメッセージ表示対応
* 2016/01/28 予約ステータス/部屋ステータス表示の切替できる対応
* 2016/02/17 ルームインジケータは部屋SWAPする場合、2wayの在庫調整を発行しない機能対応を行う 
* 2016/10/13 別画面からINCLUDE場合の対応
* 2016/11/04 予約キャンセル機能対応
* 2016/10/12 見積明細設定機能対応
* 2017/01/05 予約のキャンセルボタンを表示する・しない対応
* 2017/08/17 ルームインジケータ画面に、縦セルに表示項目をカスタマイズできるように改善対応
* 2017/12/21 レジカードにサインしたのがルームインジケータでわかるように改善対応
* 2018/02/06 予約検索条件はレコードタイプ外す改善対応
* 2018/05/11 複数店舗を選択表示できる機能対応
* 2018/11/08 未割り当てウインドウの予約も該当部屋タイプのみ情報を表示する
* 2019/05/30 こちらをルームインジケータ上からも1日単位の作成、削除（削除だけでもほしい）
* 2019/06/15 新規予約を部屋ごとに時間と到着日をデフォルト設定
* 2019/07/15 多泊の場合、外出の場合、多泊の予約に同じ状態を更新する
* 2019/07/30 軽減税率機能対応
* 2019/09/03 VOIDされた会計データは取得対象外対応
* 2019/11/15 ルームインジケータの表示について、清掃済だけでなくインスペ完の状況を追加したいです。
* 2019/12/30 名前か電話番号のどちらかだけ一致するお客様がすでに存在する
* 2019/12/30 小部屋の作成
* 2020/02/29 小部屋機能改善 
* 2020/07/30 入湯税の自動入力機能について改善
*********************************************/
global with sharing class RoomIndicatorInfo extends CommBaseCtrl {
	// ご予約へ編集権限あり、なし
	public boolean isCanUpdateLead{get{return CommSecurityUtils.isCanUpdateLead();}}
	// 2017/01/26 連絡事項表示、非表示制御フラグ
	// 2018/05/11 複数店舗を選択表示できる機能対応 WSQ BEGIN
	private static final Boolean MessageShopCodeDivFlg = CommDefine__c.getOrgDefaults().MessageShopCodeDivFlg__c;
	public boolean isShowMessageCompFlg{get{return !(MessageShopCodeDivFlg && CommUtils.isBlank(branchShopNm) && branchShopLst.size() > 0);}}
	// 2018/05/11 複数店舗を選択表示できる機能対応 WSQ END
   	// -------------------------------------------
   	// 予約新規登録用変数情報
    // -------------------------------------------
	// 画面入力用
	public Lead__c newLead{get;set;}
	public Contact newContact{get;set;}
    // E/B機能存在するかどうか標識用
    public Boolean isHaveEbInfo{get; private set;}
	public Boolean isHaveSeminar{get; private set;}
	public Boolean rLookupHoverIsShowFlg{get{return CommDefine__c.getOrgDefaults().RoomIndicatorLookupHoverIsShowFlg__c;}}
	// 
	public boolean isGroupFlg{get;set;}
	public boolean isShowGroupConfirm{get; private set;}
	public boolean isShowGroupClConfirm{get; private set;}
	public boolean isShwoGroupCancelConfirm{get{return CommDefine__c.getOrgDefaults().RoomIndicatorGpClMsgIsShow__c;}}
	// 2019/07/15 多泊の場合、外出の場合、多泊の予約に同じ状態を更新する BY zyz BEGIN
	public boolean isShowGroupOIConfirm{get; private set;}
	// 2019/07/15 多泊の場合、外出の場合、多泊の予約に同じ状態を更新する BY zyz END
	// 2017/01/05 予約のキャンセルボタンを表示する・しない対応 BEGIN by wx
	public boolean roomIndicatorIsShowLeadCancelBtn{get{return CommDefine__c.getOrgDefaults().RoomIndicatorIsShowLeadCancelBtn__c;}}
	// 2017/01/05 予約のキャンセルボタンを表示する・しない対応 END by wx
	// 泊数
	public Integer staysNums{get;set;}
	// Hidden項目・到着日
	public String startDays{get;set;}
    // お客様名
	public String contactName{get;set;}
	// 会計支払方法
	public List<Selectoption> paymentTypeLst{get; private set;}
	// 室料登録用商品情報を維持する
	private AccountMaster__c roomPriceInfo = null;
	// 2016/12/28 连接plan页面替换标准页面  begin by wx
 	public String planName{get;set;}
 	// 2016/12/28 连接plan页面替换标准页面  end by wx
	// 祝日情報を取得する[Calendar情報格納用]
	private CalendarExtend calExt;
	// 六輝表示がどうか判断用 TRUE:表示
	public boolean isShowQreqki{get{return CommConst.IsOrgRokuyoIsNoShow();}}
	// 2018/11/30  レジカード一括印刷機能追加 by zyz BEGIN 
	public Boolean isCanSelItemForCashPrint{get{return CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomIndicatorCashRegisterCode__c) == '2';}}
	// 2018/11/30  レジカード一括印刷機能追加 by zyz END
	// 本物の予約ID判別用キー
	public static final String leadPreFixKey{get; private set;}
	static {
		// 2014/12/08 KeyPreFix
		Schema.DescribeSObjectResult r = Lead__c.sObjectType.getDescribe();
		leadPreFixKey = r.getKeyPrefix();
	}
	// -------------------------------------------
    // タイムテーブル情報格納変数
    // -------------------------------------------
    public BookingTimeTable dayInfo{get; private set;}
    // 2015/09/01 多店舗機能対応 BEGIN
    public UserUtil.UserShopInfo userInf;
    // 2015/09/01 多店舗機能対応 END
    // 2016/10/13 別画面からINCLUDE場合の対応 BEGIN
    public Boolean isIncludeMode{get;private set;}
    // 2016/10/13 別画面からINCLUDE場合の対応 END
    public Id leadBookingRecTypeId{get;private set;}
    // 2015/10/27 連絡事項共通化 BEGIN
    /*
    public String processDtStr{get{
    	return DateTime.newInstance(processDate.year(), processDate.month(), processDate.day()).format('yyyyMMdd');
    }}*/
    // 2015/10/27 連絡事項共通化 END
    // 2016/06/09 翻訳：曜日機能対応 BEGIN
    private static final String g_DateFormat = CommBaseCtrl.getDateFormat();
    // 2016/06/09 翻訳：曜日機能対応 END
    // 2016/10/12 見積明細設定機能対応 BEGIN by zh
    //見積もり明細表示・非表示
    public Boolean isPlanDetailFlag{get;set;}
    // 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
    public Boolean isBasePlanFlag{get;set;}
    // 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
    // すでに設定済み明細一覧情報を取得する
    // leadId:リードID
    public List<BookEstItem> oBookEstLst{get; private set;}
    //見積もり明細行目
    public String curRows{get;set;}
    // 2016/12/07 ルームインジケータ新規後一画面へ遷移 BEGIN by zh
    public String indexId{get;private set;}
    // ルームインジケータ新規後一画面へ自動遷移制御
    public boolean RoomTypeGotoBookingFlexApp{get{return CommDefine__c.getOrgDefaults().RoomIndicatorGoBookingFlexAppFlg__c;}}
    // ルームインジケータ新規後一画面へ遷移する・しない切替選択機能制御
    public boolean RoomTypeGotoBookingFlexAppConfirm{get{return CommDefine__c.getOrgDefaults().RoomIndicatorGoBookingFlexAppConfirmFlg__c;}}
    // 2016/12/07 ルームインジケータ新規後一画面へ遷移 END by zh 
	// 2016/12/13 zyz CTI予約 BEGIN
	public String ctiContactInf {get; set;}
	// 2016/12/13 zyz CTI予約 END
	// 2017/09/18  会計一括印刷機能  WGCH BEGIN
	private boolean accPrnShowBtnFlg;
	public boolean getAccPrnShowBtnFlg(){return accPrnShowBtnFlg;}
	public void initAccPrnShowBtnFlg(String shopCd) {
	    // 2018/05/11 複数店舗を選択表示できる機能対応 BEGIN
	    // ALL店舗の場合
	    if ((CommUtils.isBlank(branchShopNm) || getMulitSpCd().size() > 1 ) && branchShopLst.size() > 0 ) {
	    // 2018/05/11 複数店舗を選択表示できる機能対応 END
	        accPrnShowBtnFlg = false;
	        return;
	    }
	    // 2017/11/06  会計一括印刷機能[全施設対応]  WGCH BEGIN
	    /*
	    String fc = CommUtils.nullToBlank( CommDefine__c.getOrgDefaults().FacilityCode__c );
        if (shopInfoMap.containsKey(shopCd)) {
            fc = CommUtils.isBLank((shopInfoMap.get(shopCd)).FacilityCode__c) 
                    ? CommUtils.nullToBlank( CommDefine__c.getOrgDefaults().FacilityCode__c )
                    : CommUtils.nullToBlank( (shopInfoMap.get(shopCd)).FacilityCode__c );
        }
        accPrnShowBtnFlg = (fc == '33' || fc == '34');
        */
        accPrnShowBtnFlg = true;
		// 2017/11/06  会計一括印刷機能[全施設対応]  WGCH END
	}
	// 2017/09/18  会計一括印刷機能  WGCH END
	// 2017/12/18 延泊処理時の見積自動コピー機能対応 WGCH BEGIN
	private static final Boolean isCloneBookEstFlg = CommDefine__c.getOrgDefaults().RoomIndicatorEstIsCloneFlg__c;
	// 2017/12/18 延泊処理時の見積自動コピー機能対応 WGCH END
	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
	public Boolean isReducedTaxFlg{get{ return CommConst.REDUCED_TAXRATE_FLG;} set;}
	// 2019/07/30 軽減税率機能対応 WGCH END
	// 2019/09/15 指定日自动记忆機能対応 WGCH BEGIN
	public Boolean toTodayFlg = false;
	public Boolean isChkInDayFlg{get{ return CommConst.USERCONFIG_CHECKINDAY_FLG;} set;}
	public String userId{get{ return UserInfo.getUserId();} private set;} // UserId
	// 2019/09/15 指定日自动记忆機能対応 WGCH END
    // 見積もり明細行目追加
    public void addBookingItem() {
    	if(CommUtils.isBlank(curRows)){
    		if (oBookEstLst.size() > LIST_INPUT_DEF_ROWS) {
    			List<BookEstItem> orgBookingLst = new List<BookEstItem>();
	            for (Integer i = 0; i < LIST_INPUT_DEF_ROWS; i++) {
	            	orgBookingLst.add(oBookEstLst[i]);
	            }
	            oBookEstLst = orgBookingLst;
	            //curRows = LIST_INPUT_DEF_ROWS+'';
	            // 2016/10/27 BEGIN
	            curRows = String.valueOf(LIST_INPUT_DEF_ROWS);
	            // 2016/10/27 END
	        }
    	}
    	// 2016/10/26 BEGIN
    	refreshBookingOrder();
    	// 2016/10/26 END
    	// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
    	Integer addInputRows = LIST_INPUT_DEF_ROWS;
    	// 2020/06/01 6438 bug fix BY zyz BEGIN
    	if(addRowsMan != null && addRowsMan != 0) {
    		if(addInputRows >= addRowsMan) addRowsMan = LIST_INPUT_DEF_ROWS;
    		addInputRows = Math.Ceil(addRowsMan/LIST_INPUT_DEF_ROWS).intValue() * LIST_INPUT_DEF_ROWS;
    	}
    	addRowsMan = null;
    	// 2020/06/01 6438 bug fix BY zyz END
    	// for (Integer i = 0; i < LIST_INPUT_DEF_ROWS; i++) {
    	for (Integer i = 0; i < addInputRows; i++) {
    	// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
	    	BookEstItem estItem = new BookEstItem(new BookingEstimateItem__c(),oBookEstLst.size());
	    	estItem.addRowStr = 'rowStr';
	        oBookEstLst.add(estItem);
	        curRows = String.valueOf(CommUtils.nullToIntZero(curRows)+1);
    	}
        //return null;
    }	
    	// 2016/10/26 顺序保持 fix BEGIN
	private void refreshBookingOrder(){
		Map<Integer, BookEstItem> locSortMap = new Map<Integer, BookEstItem>();
		for (BookEstItem item : oBookEstLst) {
//system.debug(logginglevel.info,'item.sobj.rowNo__c:::' + item.sobj.rowNo__c);
			// 画面表示順により、ソートを行う
			locSortMap.put(CommUtils.nullToIntZero(item.sobj.rowNo__c),item);
		}
		List<Integer> sortKeyLst = new List<Integer>();
		sortKeyLst.addAll(locSortMap.keySet());
		sortKeyLst.sort();
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
		// 2016/10/26 顺序保持 fix END
    	
        
    }
    // 返金キー情報格納用
    public String refundItemString{get{return JSON.serialize(BillSimpleHelp.getRefundItemStr());}}
    // XMLの定義情報から取得する
    private Map<String, String> PAYMENT_MATCH_MAP = new Map<String, String>();
    public String payTypeConvertJson{get{return JSON.serialize(PAYMENT_MATCH_MAP);}}
    private static final Integer LIST_INPUT_DEF_ROWS = ( CommUtils.nullToIntZero(CommConst.APPOTION_DETAIL_DEF_INPUTLINES) == 0 
                                                        ? 27 
                                                        : CommUtils.nullToIntZero(CommConst.APPOTION_DETAIL_DEF_INPUTLINES) );
    // 2016/10/12 見積明細設定機能対応 END by zh
    // 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
    public Integer addRowsMan{get;set;}
    // 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
    private Boolean norefreshFlag = false;
    public String errorMsg = '';
    public RoomIndicatorInfo(String leadid,String roomId,boolean todayFlag,Date queryDt) {
    	strLeadId = leadid;
    	groupLeadIds = '';
    	topLeadIdsHid = '';
    	isShowToday = todayFlag;
    	processDate = queryDt;
    	userInf = UserUtil.CurrentUserInfo;
    	selectDate = new BookingTimeTable__c();
    	selectDate.Checkinday__c = processDate;
    	norefreshFlag = true;
    }
    // 2018/05/11 複数店舗を選択表示できる機能対応 BEGIN
    public String multiDepartCds{get;set;}
    // 店舗が複数選択有効フラグ
    public Boolean multiSelectCompFlg{get{ 
    	// 共通定義情報を取得する
    	Boolean isComSelectFlg = CommDefine__c.getOrgDefaults().RoomIndicatorMultiSelectFlg__c;
    	// 多店舗（2店舗以上かつ共通定義のフラグTRUEの場合）
    	return (isComSelectFlg == true && branchShopLst.size() > 1);
    }}
    // 2018/05/11 複数店舗を選択表示できる機能対応 END
    // コンタクト初期化
    public RoomIndicatorInfo() {
        // 初期化選択条件
        strLeadId = '';
        groupLeadIds = '';
        topLeadIdsHid = '';
        processDate = Date.today();
        isShowGroupConfirm = CommConst.APPOTION_CHECKIN_GROUPCONFIRM;
        isShowGroupClConfirm = CommConst.APPOTION_CHECKIN_GROUPCLCONFIRM;
        // 2019/07/15 多泊の場合、外出の場合、多泊の予約に同じ状態を更新する BY zyz BEGIN
        isShowGroupOIConfirm = CommConst.APPOTION_OUT_GROUPCONFIRM;
        // 2019/07/15 多泊の場合、外出の場合、多泊の予約に同じ状態を更新する BY zyz END
        isShowToday = (System.now().format('HH:mm') < equalTime.format('HH:mm') ? false : true);
        selectDate = new BookingTimeTable__c();
        leadBookingRecTypeId = CommLogicProcess.getLeadBookingRecType();
        // 2013/12/12 パラメータ追加,指定日の情報を表示する
        String startDt = ApexPages.currentPage().getParameters().get('dt');
        if (!CommUtils.isBlank(startDt)) {
        	//processDate = Date.parse(startDt);
        	processDate = CommUtils.stringToDate(startDt);
        	selectDate.Checkinday__c = processDate;
        	// 2014.10.20 指定日の場合、当日以外はチェックイン・チェックアウトボタンを非表示すうため、下記変数が影響なし
        	// 当日の場合、上記[isShowToday = (System.now().format('HH:mm') < equalTime.format('HH:mm') ? false : true);]で判定する
        	//isShowToday = false;
        }
	    // 2016/10/13 別画面からINCLUDE場合の対応 BEGIN
	    isIncludeMode = ApexPages.currentPage().getParameters().containsKey('frame');//別のページに含めているがどうか
	    // 2016/10/13 別画面からINCLUDE場合の対応 END
		// 2014/11/29 祝日情報を初期化
		calExt = new CalendarExtend(true);
        // 2015/09/01 多店舗機能対応 BEGIN	
        userInf = UserUtil.CurrentUserInfo;
        // 2015/09/01 多店舗機能対応 END
		// 2019/07/31 20190527.04.タイムテーブル、ルームインジケータ、マルチタスク機能編集モードと読み込み専用モード対応必要 by zy BEGIN
		notReadOnlyFlg = userInf.hadRoomFlg;
		// 2019/07/31 20190527.04.タイムテーブル、ルームインジケータ、マルチタスク機能編集モードと読み込み専用モード対応必要 by zy END
        setInitBranShopLst();
        setInitRoomTypeLst();
        // 2016/01/28 予約ステータス/部屋ステータス表示の切替できる対応 BEGIN
        CookieInf cookInf = getCookieInf();
        statusCode = CommUtils.isBlank(cookInf.statusMode) ? constStatusCodeRoom : cookInf.statusMode;
        initColorInfo();
        // 2016/01/28 予約ステータス/部屋ステータス表示の切替できる対応 END
        leadInfo = new PopupWinInfo();
        RoomDetail = new RoomInfo();
    	RoomDetail.leadDetail = new Lead__c(RecordTypeId = CommLogicProcess.getLeadBookingRecType());
        // タイムテーブル情報を初期化する
        if (isShowTimeTable) dayInfo = new BookingTimeTable();
	   	// -------------------------------------------
	   	// 予約新規登録用変数初期化
	    // -------------------------------------------
	    /*
		newLead = new Lead__c();
		newContact = new Contact();
		// 予約のレコードタイプ
    	newLead.RecordTypeId = CommLogicProcess.getLeadBookingRecType();
    	// チェックイン時刻、チェックアウト時刻
    	newLead.Field4__c = CommConst.DEF_CHECKIN_TIME;
    	newLead.Field3__c = CommConst.DEF_CHECKOT_TIME;
    	*/
    	//initBookingFormInfo();
		// 支払方法リスト初期化する
		paymentTypeLst = new List<Selectoption>();
		Schema.DescribeFieldResult fieldResult = Lead__c.Field315__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
	   	for( Schema.PicklistEntry f : ple) {
           paymentTypeLst.add(new SelectOption(f.getValue(),f.getLabel()));
	   	}
	   	// 2016/11/24 チェックアウト多国語対応 BEGIN
	   	setMulitiCheckoutLabelFun();
	   	// 2016/11/24 チェックアウト多国語対応 END
		// アプリのE/B機能起動がどうかフラグを設定する
		isHaveEbInfo = CommConst.APPOPTION_ISUSR_EB;
		isHaveSeminar = CommConst.APPOTION_ISSHOW_SEMINAR;
		isGroupFlg = false;
		// 部屋にお客様名・予約名表示制御フラグの初期値設定する
		roomNameType = String.valueOf(ROOM_INFO_NAME_TYPE);
		// XML___wgch 2016/11/16 BEGIN
		refeshDomNode();
		// XML___wgch 2016/11/16 END
		// 2017/01/25 新規画面の項目自定義機能 by zy BEGIN
        loadInsertWindow();
        // 2017/01/25 新規画面の項目自定義機能 by zy END
        // 2017/09/18  会計一括印刷機能  WGCH BEGIN
        initAccPrnShowBtnFlg(branchShopNm);
        // 2017/09/18  会計一括印刷機能  WGCH END
		// 2019/11/15 ルームインジケータの表示について、清掃済だけでなくインスペ完の状況を追加したいです。 by zy BEGIN
		//　清掃情報初期化
        initCleanStatus();
		// 2019/11/15 ルームインジケータの表示について、清掃済だけでなくインスペ完の状況を追加したいです。 by zy END
    }
    // 2016/11/24 チェックアウト多国語対応 BEGIN
    public String mulitiCheckoutLabel{get;private set;}
    // 2019/02/28 滞在・外出状態の管理 WGCH BEGIN
    public String mulitiOutLabel{get;private set;}
    public String mulitiCheckinLabel{get;private set;}
    // 2019/02/28 滞在・外出状態の管理 WGCH END
    private void setMulitiCheckoutLabelFun() {
		Schema.DescribeFieldResult fieldResult = Lead__c.Field298__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
	   	for( Schema.PicklistEntry f : ple) {
	   		// 2019/02/28 滞在・外出状態の管理 WGCH BEGIN
	   		/*
	   		if (f.getValue() == CommConst.LEAD_GUEST_ST_CO) {
	   			mulitiCheckoutLabel = f.getLabel();
	   			break;
	   		}
	   		*/
	   		if (f.getValue() == CommConst.LEAD_GUEST_ST_CO) {
	   			mulitiCheckoutLabel = f.getLabel();
	   		} else if (f.getValue() == CommConst.LEAD_GUEST_ST_OUT) {
	   			mulitiOutLabel = f.getLabel();
	   		} else if (f.getValue() == CommConst.LEAD_GUEST_ST_CI) {
	   			mulitiCheckinLabel = f.getLabel();
	   		}
	   		// 2019/02/28 滞在・外出状態の管理 WGCH END
	   	}
    }
    // 2016/11/24 チェックアウト多国語対応 END
    // 過去・未来参照できる機能制御の追加
    public Boolean isShowHisFlg{get{ return CommDefine__c.getInstance().RoomIndicatorShowHisFlg__c;}}
    // 過去の未割り当て予約アサインできる制御フラグ
    public Boolean isShowHisAssignWinFlg{get{ return CommConst.APPOTION_ROOMTYPE_INPUT_PASTDATA;}}
    // 部屋表示順フラグ定数定義
    private static final String ROOM_SORT_NAME_DIV = '1';
    //private static final String ROOM_SORT_DISPLAY_DIV = '2';
    private static final String ROOM_SORT_DIV = CommDefine__c.getOrgDefaults().RoomSortDiv__c == null ? ROOM_SORT_NAME_DIV : CommDefine__c.getOrgDefaults().RoomSortDiv__c;
	
	// 2013/05/23 部屋表示サイズ調査対応
	private static final Integer ROOM_INFO_MAX_SIZE = CommDefine__c.getOrgDefaults().RoomIndicatorInfoMaxLength__c == null ? 4 : (CommDefine__c.getOrgDefaults().RoomIndicatorInfoMaxLength__c.intValue() < 4 ? 4 : CommDefine__c.getOrgDefaults().RoomIndicatorInfoMaxLength__c.intValue());
	//2013/07/22 部屋約名標識
	public static Integer ROOM_INFO_NAME_TYPE_GUESTNAME	{get{return 1;}}
	public static Integer ROOM_INFO_NAME_TYPE_LEADNAME	{get{return 2;}}
	private static final Integer ROOM_INFO_NAME_TYPE = CommDefine__c.getOrgDefaults().RoomIndicatorInfoNameType__c == null ? ROOM_INFO_NAME_TYPE_GUESTNAME : CommDefine__c.getOrgDefaults().RoomIndicatorInfoNameType__c.intValue();
	// 2013/07／30 営業日切替時間追加
	private static final String BUSINESS_HHMM = CommDefine__c.getOrgDefaults().RoomIndicatorBusinessHourMM__c == null ? '1200' : CommDefine__c.getOrgDefaults().RoomIndicatorBusinessHourMM__c;
	// 2013/08/11 予約名
	private static final String LEAD_NAME_PREFIX = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomDelegatePrefix__c);	
	// 2013/08/14 DEF_CHECKOT_TIME設定
	private static final String DEF_CHECKOT_TIME = CommConst.DEF_CHECKOT_TIME;
	public Integer roomDivWidth {get{
		return ROOM_INFO_MAX_SIZE * 14;
	}}
	// 画像数式処理用Pattern
    private static final Pattern pTool = Pattern.compile('.*src=["](/resource.*?)["].*');
	// 2013/10/12 DB更新処理標識フラグ
	public Boolean bookingCreateOK{get;set;}
	// 2013/10/30 透か度取得
	public Boolean WatermarkRate{get{return CommDefine__c.getOrgDefaults().WatermarkRate__c == null ? false : CommDefine__c.getOrgDefaults().WatermarkRate__c;}}
	// 2013/11/03 タイムテーブル表示・非表示制御フラグ
	public Boolean isShowTimeTable{get{return CommDefine__c.getOrgDefaults().RoomIndicatorIsShowTimeInfo__c == null ? false : CommDefine__c.getOrgDefaults().RoomIndicatorIsShowTimeInfo__c;}}
	// 2014/05/30 予約人数表示・非表示制御
	public Boolean isShowStayPerson{get{return CommDefine__c.getOrgDefaults().RoomIndicatorIsShowStayPersons__c == null ? false :  CommDefine__c.getOrgDefaults().RoomIndicatorIsShowStayPersons__c;}}
    // 2017/05/22 レジカードサイン機能 zyz 
	public Boolean isCashRegisterSignFlg{get{return CommDefine__c.getOrgDefaults().CashRegisterSign__c == null ? false :  CommDefine__c.getOrgDefaults().CashRegisterSign__c;}}
	// 2017/12/21 レジカードにサインしたのがルームインジケータでわかるように改善対応 zyz BEGIN
	public String cashCode {get{ return CommConst.APPOTION_CARREGISTSWITCH_DIV_CODE;}}
	// 2017/12/21 レジカードにサインしたのがルームインジケータでわかるように改善対応 zyz END
    // 2014/02/10 部屋単位の時刻リスト情報を格納する
    public transient Map<Id, String> roomTimesMap{get; private set;}
    // 2014/06/17 部屋にお客様名・予約名表示制御フラグ情報格納
 	public String roomNameType{get;set;}
 	// 2015/10/30 主コンテンツにエラーを表示するがどうか
 	public Boolean mainIsShowErr{get;set;}
 	public List<Selectoption> getRoomNameTypeOptions(){
		List<Selectoption> options = new List<Selectoption>();
		//お客様名
 		options.add(new Selectoption(String.valueOf(ROOM_INFO_NAME_TYPE_GUESTNAME), Label.CONST_008_0122));
 		//予約名
 		options.add(new Selectoption(String.valueOf(ROOM_INFO_NAME_TYPE_LEADNAME), Label.CONST_008_0123));
 		return options;
 	}
	/**
	* ルーム情報検索する
	**/
	// 2018/07/27 宿泊税計算 WGCH BEGIN
	// private static final String QueryHeader = 'Select  Name ,Id ,Area__c ,Basu__c ,CapacityHaku__c ,Capacity__c ,Field10__c ,Field11__c ,Field12__c ,Field13__c ,Field14__c ,Field15__c ,Field16__c ,Field17__c ,Field18__c ,Field19__c ,Field1__c ,Field4__c ,Field5__c ,Field6__c ,Field7__c ,Field8__c ,Field9__c ,Height__c ,ID__c ,LAN__c ,Lat__c ,Left__c ,Lng__c ,Rank_2__c ,Rank_3__c ,Rank_4__c ,Rank_5__c ,Rank__c ,Rnumber__c ,RoomName__c ,Seq__c ,Tier123__c ,Top__c ,UseOfRoom__c ,Width__c ,centreLat__c ,centreLng__c ,furo__c ,heyadashiryou__c ,heyadashiryouryou__c ,kakuzuke__c ,priority__c ,roomimage__c ,rotenburo__c ,TypeRoomRef__c ,Nosmoking__c ,ParentRoomRef__c ,Floor__c ,TypeRoomRef__r.Name From  Room__c ';
	// 2019/11/30 清掃エラー修正　by　zy BEGIN
	private static final String QueryHeader = 'Select  Name ,Id ,Area__c ,Basu__c ,CapacityHaku__c ,Capacity__c ,Field10__c ,Field11__c ,Field12__c ,Field13__c ,Field14__c ,Field15__c ,Field16__c ,Field17__c ,Field18__c ,Field19__c ,Field1__c ,Field4__c ,Field5__c ,Field6__c ,Field7__c ,Field8__c ,Field9__c ,Height__c ,ID__c ,LAN__c ,Lat__c ,Left__c ,Lng__c ,Rank_2__c ,Rank_3__c ,Rank_4__c ,Rank_5__c ,Rank__c ,Rnumber__c ,RoomName__c ,Seq__c ,Tier123__c ,Top__c ,UseOfRoom__c ,Width__c ,centreLat__c ,centreLng__c ,furo__c ,heyadashiryou__c ,heyadashiryouryou__c ,kakuzuke__c ,priority__c ,roomimage__c ,rotenburo__c ,TypeRoomRef__c ,Nosmoking__c ,ParentRoomRef__c ,Floor__c ,TypeRoomRef__r.Name ,ShopInfoRef__r.ShopCode__c,RoomNotCreateFlg__c From  Room__c ';
	// 2019/11/30 清掃エラー修正　by　zy END
	// 2018/07/27 宿泊税計算 WGCH END
	// 場所別部屋情報
	// 2018/05/10 ビューステータス修正　by　zy BEGIN
	public transient List<AreaRoomInfo> areaInfLst {get; private set;}
	// 2018/05/10 ビューステータス修正　by　zy END
	// Floor最大部屋数
	public Integer maxRooms{get; private set;}
	// 詳細画面情報維持
	public RoomInfo RoomDetail{get;set;}
	public String strLeadId{get;set;}
	public String groupLeadIds{get;set;}
	// 2015/12/17 FIX BEGIN
	public String rRoomsStatusinfo{get; set;}
	public String rRoomsStatusColorinfo{get; set;}
	public String rRoomsStaProcessinfo{get; set;}
	public String rRoomsStaProcessColorinfo{get; set;}

	//通常
	private String CONST_NORMAL_HOTEL = Label.CONST_008_0109;
	private String CONST_NORMAL_COLOR = 'black';
 	private String CONST_NORMAL_OTCOLOR = 'red';
 	// 2019/02/28 滞在・外出状態の管理 WGCH BEGIN
 	public static Boolean outButtonShowFlg{get{return CommDefine__c.getOrgDefaults().outButtonShowFlg__c == null ? false :  CommDefine__c.getOrgDefaults().outButtonShowFlg__c;}}
 	// 2019/02/28 滞在・外出状態の管理 WGCH END

	public String[] rRoomsStatus(Date dt) {
		String[] rsStatusArr = new List<String>{'',''};
		// 支店は未指定 && 支店リストはが存在する場合
    	if (CommUtils.isBlank(branchShopNm) && branchShopLst.size() > 0) return rsStatusArr;

		// 共通定義情報を取得、解析する
		Map<String, String> statusColorMap = new Map<String, String>();
		String roomTSS = CommConst.APPOTION_DEF_ROOMTYPE_SALESTATUS();
		Set<String> roomTSSSet = new Set<String>();
		// 解析共通定义设置
		if (!String.isEmpty(roomTSS)) {
			String[] roomLst = roomTSS.split(',');
			for (String key : roomLst) {
        		String[] subKey = key.split(':');
        		if (subKey.size() > 1) CONST_NORMAL_HOTEL = subKey[0];
				else roomTSSSet.add(subKey[0].split(';')[0]);
				String[] colorKey = key.split(';');
				if (colorKey.size() > 1) statusColorMap.put(subKey[0].split(';')[0], colorKey[1]);
			}
		}
		// 添加默认Status颜色
		if (!statusColorMap.containsKey(CONST_NORMAL_HOTEL)) statusColorMap.put(CONST_NORMAL_HOTEL, CONST_NORMAL_COLOR);

    	// 支店は未指定 && 支店リストはが存在する場合
    	// 画面期間範囲の 休館/全館貸切 情報を取得する
		Date firstDay = dt;
		String statusinfo = CONST_NORMAL_HOTEL;
		String colorinfo = CONST_NORMAL_COLOR;
		List<RoomsStatus__c> roomsStatus = [select id, Status__c, StatusBeginDate__c, StatusEndDate__c from RoomsStatus__c
												where (Status__c in : roomTSSSet)
												And StatusBeginDate__c <= :firstDay And StatusEndDate__c >= :firstDay
												And (
												   RoomRef__r.ShopInfoRef__r.ShopCode__c = :branchShopNm
												OR RoomRef__r.TypeRoomRef__r.ShopInfoRef__r.ShopCode__c = :branchShopNm
												) limit 1];
		if(roomsStatus.size() > 0) statusinfo = roomsStatus[0].Status__c;

		if(statusColorMap.containsKey(statusinfo)) colorinfo = statusColorMap.get(statusinfo);
		else if(statusinfo != CONST_NORMAL_HOTEL) colorinfo = CONST_NORMAL_OTCOLOR;
		
		rsStatusArr[0] = statusinfo;
		rsStatusArr[1] = colorinfo;
		return rsStatusArr;
	}
	public String strToday{get{
		DateTime nowDt = System.now();
		//nowDt = DateTime.newInstance(2014,12,23);
		Date dt = nowDt.date();
		// 曜日
		String yobi = CommUtils.getYobi(dt);
		String holidayLab = '';
		if (calExt.holidayMap.containsKey(dt)) {
			if(isShowQreqki)
				holidayLab = ' ' + calExt.holidayMap.get(dt);
		}
		// 営業ステータスを取得、設定する
		String[] tempStatusinfo = rRoomsStatus(dt);
		rRoomsStatusinfo = tempStatusinfo[0];
		rRoomsStatusColorinfo = tempStatusinfo[1];

		return (nowDt.format('yyyy-MM-dd') + ' (' + yobi +') ' + nowDt.format('HH:mm') + holidayLab);
	}}
	// 指定日の関連の日付情報
	public String strProcessDate{get{
		Date pageInputDate = getInputDate(0);
		String yobi = CommUtils.getYobi(pageInputDate);
		String holidayLab = '';
		if (calExt.holidayMap.containsKey(pageInputDate)) {
			holidayLab = ' ' + calExt.holidayMap.get(pageInputDate);
		}
		DateTime processDt = DateTime.newInstance(pageInputDate.year(),pageInputDate.month(),pageInputDate.day());
		// 営業ステータスを取得、設定する
		String[] tempStatusinfo = rRoomsStatus(pageInputDate);
		rRoomsStaProcessinfo = tempStatusinfo[0];
		rRoomsStaProcessColorinfo = tempStatusinfo[1];

		return (processDt.format('yyyy-MM-dd') + ' (' + yobi +')' + holidayLab);
	}}
	// 2015/12/17 FIX END
	// RoomChange　No
	public String strNewRoomNo{get;set;}
	public String strNewRoomId{get;set;}
	// 処理日
	private Date processDate = null;
	// 2017/03/29 レジカード一括印刷対応 BEGIN
	public String getProcessDate() {
		return processDate.format();
	}
	// 2017/03/29 レジカード一括印刷対応 END
    // 12時で、予約データを見える範囲
    private static DateTime equalTime = DateTime.newInstance(Date.today(), Time.newInstance(Integer.valueOf(BUSINESS_HHMM.SUBSTRING(0,2)),Integer.valueOf(BUSINESS_HHMM.SUBSTRING(2,4)),0,0));
   /**
    * 当日のチェックインレイアウト・チェックアウトレイアウト切替画面制御
    * TRUEの場合、当日のチェックイン情報を表示する(画面の指定日は)
    * FALSEの場合、当日のチェックアウト情報を表示する
    */
    public Boolean isShowToday{get;set;}            // 当日
    public static String topLeadIdsHid{get;set;}    //
    /************************************
    * 各タイプルームのSTYLE　COLOR
    *************************************/
	// 空室
	private final String strEmptyStatusColor = 'isEmptyStatus';
	// 割当済
	private final String strAssignedStatusColor = 'isAssignedStatus';
	// 2019/02/28 滞在・外出状態の管理 WGCH BEGIN
	// 外出
	private final String strIsOutStatusColor = 'isOutStatus';
	// 2019/02/28 滞在・外出状態の管理 WGCH END
	// 滞中
    private final String strIsStayStatusColor = 'isStayStatus';
    // 出発予定
    private final String strCheckOutDayStatusColor = 'isChkOutDayStatus';
    // 出発
    private final String strCheckOutStatusColor = 'isChkOutStatus';
    // 故障
    private final String strIsBadStatusColor = 'isBadStatus';
    // 部屋未アサイン
    private final String strIsNoneStatusColor = 'isNoneStatus';
	// 未掃除
	private final String strIsNoCleanStatusColor = 'isCleanStatus';
	// 2020/09/30 当日チェックアウトの日帰り予約がチェックイン後にルームチェンジできなくなる不具合の解消 by zy BEGIN
	private final String strIsOneDayStayColor = 'isOneDayStayStatus';
	// 2020/09/30 当日チェックアウトの日帰り予約がチェックイン後にルームチェンジできなくなる不具合の解消 by zy END
    //private final String strIsConfirmationingColor = 'isConfirmationing';
    /************************************
    * 各タイプルームの合計値統計
    *************************************/
    public Integer iEmptyStatusSum{get;set;}
    public Integer isAssignedStatusSum{get;set;}
    // 2019/02/28 滞在・外出状態の管理 WGCH BEGIN
    public Integer outStatusSum{get;set;}
    // 2019/02/28 滞在・外出状態の管理 WGCH END
    public Integer isStayStatusSum{get;set;}
    public Integer checkOutDayStatusSum{get;set;}
    public Integer checkOutStatusSum{get;set;}
    public Integer isBadStatusSum{get;set;}
    public Integer isNoCleanStatusSum{get;set;}
    private Map<Id,Integer> roomLeadsCount;
    public Set<String> topLeadIdSet{get;set;}
    
	/**
	* 各部屋のアサイン最新状態情報を取得する
	**/
	@TestVisible private void queryRoomStatus () {
		// 統計情報内容の初期化
		iEmptyStatusSum = 0;
		isAssignedStatusSum = 0;
		// 2019/02/28 滞在・外出状態の管理 WGCH BEGIN
		outStatusSum = 0;
		// 2019/02/28 滞在・外出状態の管理 WGCH END
        isStayStatusSum = 0;
        checkOutDayStatusSum = 0;
        checkOutStatusSum = 0;
        isBadStatusSum = 0;
        isNoCleanStatusSum = 0;
        //isConfirmationSum = 0;
        roomTimesMap = new Map<Id, String>();
        // 部屋情報を格納要配列初期化
        areaInfLst = new List<AreaRoomInfo>();
        // 行最大部屋数の初期化
        maxRooms = 0;
		// 部屋マスた情報を取得する
		// 各部屋のステータス取得する
        String queryWhere = ' where UseOfRoom__c = \'' + String.escapeSingleQuotes(CommConst.ROOM_UseOfType_Guest) + '\' ';
        // 2018/05/11 複数店舗を選択表示できる機能対応 BEGIN
    	list<string> mulitiSpcd = getMulitSpCd();
        if (mulitiSpcd.size() > 1) {
        	queryWhere+= ' And ShopInfoRef__r.ShopCode__c in :mulitiSpcd';
        }
        // 2015/09/01 多店舗機能対応 BEGIN
        else if (!CommUtils.isBlank(branchShopNm)) {
        // 2018/05/11 複数店舗を選択表示できる機能対応 END
            queryWhere+= ' And ShopInfoRef__r.ShopCode__c = \'' + String.escapeSingleQuotes(BranchShopNm) + '\'';
        }else if (userInf.isShopCodePlex) {
            Set<String> shopSt = userInf.shopSt;
            queryWhere+= ' And ShopInfoRef__r.ShopCode__c in :shopSt';
        }
        //2019/2/15 ルームインジケータの部屋タイプ絞り込み機能を、タイムテーブルと同じように、複数タイプ指定できるようにして欲しい by cxw BEGIN
        if(orgSettingValue != multiRoomTypeIds) {
        	orgSettingValue = multiRoomTypeIds;
        	RoomIndicatorInfo.saveCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.DEPARTCODES.name(),'', orgSettingValue);
        }
		// 2015/09/01 多店舗機能対応 END
        //if (!CommUtils.isBlank(roomTypeNm)) queryWhere+= ' And TypeRoomRef__c = \'' + String.escapeSingleQuotes(roomTypeNm) + '\'';
        multiRoomTypeIds = multiRoomTypeIds.removeStart(',');
        if (!CommUtils.isBlank(multiRoomTypeIds)) {
        	List<string> lstRoomType = multiRoomTypeIds.split(',');
        	queryWhere+= ' And TypeRoomRef__c = :lstRoomType'; 
        }
        ////2019/2/15 ルームインジケータの部屋タイプ絞り込み機能を、タイムテーブルと同じように、複数タイプ指定できるようにして欲しい by cxw END
        // 2013/05/22 部屋並べ替え機能修正
        //String queryOrder = ' Order By AREA__c asc, Floor__c asc, Seq__c asc ';
        String queryOrder = ' Order By AREA__c asc, Floor__c asc, ';
        if (ROOM_SORT_DIV == ROOM_SORT_NAME_DIV) {
        	queryOrder += ' Seq__c asc ';
        } else {
        	queryOrder += ' DisplayNo__c asc ';
        }
        String queryStr = QueryHeader + queryWhere + queryOrder;
        // 場所情報を維持する
        Set<String> areaSet = new Set<String>();
        Set<String> floorSet = new Set<String>();
        // 2017/12/22 画面フィルター機能追加　by　zy　BEGIN
		Set<String> filterRoomSet = new Set<String>();
		String filterClass = '';
		if (!CommUtils.isBlank(filterHidRoom)) {
			filterRoomSet.addAll(filterHidRoom.split(','));
			filterClass = 'filteredRow';
		}
		// 2017/12/22 画面フィルター機能追加　by　zy　END
        // 2021/03/05 50001エラー修正 by zy BEGIN
        boolean isRoomLimitFlg = false;         // 判断是否超过最大限制
        limitShopStr = '';                      // 限制内店舗コード
        Set<String> spcdSet = new Set<String>();// 該当部屋の店舗コード集合
        integer roomIdx = 0;                    // 当前に処理の部屋数
        // 2021/03/05 50001エラー修正 by zy END
        // 各部屋情報を取得する
        for (Room__c s: Database.query(queryStr)) {
            // 2021/03/05 50001エラー修正 by zy BEGIN
            // ALL店舗の限制外の場合、処理停止
            if (isRoomLimitFlg) {
                break;
            }
            // 2021/03/05 50001エラー修正 by zy END
        	String areaNm = CommUtils.nullToBlank(s.Area__c);
            // 新た場所に切り替えする場合
            if (!areaSet.contains(areaNm)) {
            	areaSet.add(areaNm);
            	// リスト情報を格納する
                AreaRoomInfo newArea = new AreaRoomInfo(areaNm);
                areaInfLst.add(newArea);
                // 新規Floor初期化
                floorSet.clear();
            }
            // Floor情報が存在チェックを行う
            if (!floorSet.contains(s.Floor__c)) {
            	FloorRoomInfo floor = new FloorRoomInfo();
            	// 2017/12/22 画面フィルター機能追加　by　zy　BEGIN
            	if (!filterRoomSet.isEmpty()) floor.cssClass = filterClass;
            	// 2017/12/22 画面フィルター機能追加　by　zy　END
            	areaInfLst.get(areaSet.size()-1).addFoorRoomInfo(floor);
            	floorSet.add(s.Floor__c);
            }
            // Room Info Add
            FloorRoomInfo floorRoom = areaInfLst[areaSet.size()-1].floorRoomLst[floorSet.size()-1];
            RoomInfo room = new RoomInfo(s, roomNameType);
            // 2017/12/22 画面フィルター機能追加　by　zy　BEGIN
            // 行包含房间id则不进行隐藏
            if (filterRoomSet.contains(s.id)) {
            	floorRoom.cssClass = '';
            // 房间id不包含的隐藏
            } else {
            	room.filterClass = filterClass;
            }
            // 2017/12/22 画面フィルター機能追加　by　zy　END
            floorRoom.addRoom(room);
            // 部屋情報初期化を行う
            roomTimesMap.put(s.Id, '');
	        // 2021/03/05 50001エラー修正 by zy BEGIN
            // ALL店舗の場合、制限有効
            if (CommUtils.isBlank(branchShopNm) && branchShopLst.size() > 0) {
                // 処理部屋計数
                roomIdx++;
                // 部屋の限界チェック
                isRoomLimitFlg = roomIdx >= limitSize;
                // 該当部屋の店舗追加
                spcdSet.add(s.ShopInfoRef__r.ShopCode__c);
            }
            // 2021/03/05 50001エラー修正 by zy END
        } // End For
        // 2021/03/05 50001エラー修正 by zy BEGIN
        // 部屋の限界有効の場合
        if (isRoomLimitFlg) {
            // 限制内店舗コード
            limitShopStr = String.join(new List<String>(spcdSet),',');
        }
        // 2021/03/05 50001エラー修正 by zy END
        // ************************
        // 関連情報を取得する
        // ************************
        // 既存の予約データを取得する
        Map<Id, Lead__c> roomLeadMap = this.queryLeadInfo();
        // 2014/05/22 印刷済みフラグ格納
        Map<Id, Boolean> isAccountedFlgMap = this.getAccountedFlgMap(roomLeadMap.values());
        // 2017/12/21 レジカードにサインしたのがルームインジケータでわかるように改善対応 zyz BEGIN
        Map<Id, String> isGuestFlgMap = this.getGuestFlgMap(roomLeadMap.values());
        // 2017/12/21 レジカードにサインしたのがルームインジケータでわかるように改善対応 zyz END
        // 2020/02/29 小部屋機能改善 BY zyz BEGIN
        // 处理数据是否只在主予约显示
        Map<Id, Boolean> isleadRoomLMap = this.getRoomFlgMap(roomLeadMap.values());
        // 2020/02/29 小部屋機能改善 BY zyz END
        // 2019/12/30 小部屋の作成 BY zyz BEGIN
        Map<Id, Boolean> isleadSmallRoomLMap = this.getSmallRoomMap(roomLeadMap.values());
        // 2019/12/30 小部屋の作成 BY zyz END
        // 故障部屋情報を取得する
        //Set<Id> badRoomSet = this.queryBadRoomSet();
        Map<Id,List<RoomsStatus__c>> badRoomMap = this.queryBadRoomSet();
        // 部屋清掃情報を取得する
        // 2013/11/06 部屋掃除情報の取得は当日の指定日で設定する
        //Map<Id, String> cleanStatusRoomMap = (new RoomStatusManager()).getCleanStatusRooms(processDate);
        // 2018/8/28 ルームインジケーターのチェックアウトから日をまたぐと未清掃が反映 by cxw begin
        //Map<Id, String> cleanStatusRoomMap = (new RoomStatusManager()).getCleanStatusRooms(getInputDate(0));
        Map<Id, String> cleanStatusRoomMap = (isKeepCleanFlag) ? 
                            // 未清掃保持の場合、処理部屋、清掃処理日数設定
        					(new RoomStatusManager()).getCleanStatusRooms(roomTimesMap.keySet(), null) :
        					(new RoomStatusManager()).getCleanStatusRooms(getInputDate(0));
        // 2018/8/28 ルームインジケーターのチェックアウトから日をまたぐと未清掃が反映 by cxw end
        // 2019/11/15 ルームインジケータの表示について、清掃済だけでなくインスペ完の状況を追加したいです。 by zy BEGIN
		Set<Id> noCleanDataRoomIds = new Set<Id>(roomTimesMap.keySet());
        // 未清掃状態保持の場合、処理部屋、清掃処理日数設定
        Map<String,List<RoomsStatus__c>> cleanDetailStatusRoomMap = cleansLst.isEmpty() ? new Map<String,List<RoomsStatus__c>>() : RoomStatusManager.cleanDetailStatusRoomMap(noCleanDataRoomIds, isKeepCleanFlag ? null : getInputDate(0));
        // 2019/11/15 ルームインジケータの表示について、清掃済だけでなくインスペ完の状況を追加したいです。 by zy END
        // 清掃するべき部屋ID配列
        Set<Id> cleanRoomIdSet = new Set<Id>();
        // システム時間（分まで）
        String systemDtFormat = System.now().format('yyyyMMddHHmm');
        // 画面から指定する日付情報を格納する【変換なし、そのまま使う】
        Date uiInputDate = getInputDate(0);
        // 予約情報は設定する
        for (AreaRoomInfo area : areaInfLst) {
        	for (FloorRoomInfo floor : area.floorRoomLst) {
        		// フロア単位の最大部屋数統計する
        		if (maxRooms < floor.roomLst.size()) maxRooms = floor.roomLst.size();
        		// 部屋に、予約データを設定する
        		for (RoomInfo room : floor.roomLst) {
                    // 該当部屋に予約数情報を設定する
                    if(roomLeadsCount.containsKey(room.sobj.Id)) room.leadsCount = roomLeadsCount.get(room.sobj.Id);
        			// 故障部屋の場合
        		    if (badRoomMap.containsKey(room.sobj.Id)) {
        		    	RoomsStatus__c badRoom = badRoomMap.get(room.sobj.Id)[0];
        		    	// 2018/06/06 故障Tips内容更新 by zy BEGIN
        		    	String bgTm = CommUtils.isBlank(badRoom.BeginTime__c) || selectDate.Checkinday__c != badRoom.StatusBeginDate__c ? 
        		    						'00:00' : badRoom.BeginTime__c;
        		    	String edTm = CommUtils.isBlank(badRoom.OverTime__c) || selectDate.Checkinday__c != badRoom.StatusEndDate__c ? 
        		    						'24:00' : badRoom.OverTime__c;
        		    	String timeMsg = '（' + bgTm + '〜' +  edTm + '）';
        		    	room.simpleGuestNm = badRoom.Name + timeMsg;
        		    	// 2018/06/06 故障Tips内容更新 by zy END
        		    	// 2017/05/05 故障部屋の詳細説明情報はバルーンで表示 begin by wx
        		    	// 2018/06/06 故障Tips内容更新 by zy BEGIN
        		    	if(!CommUtils.isBlank(badRoom.Describe__c)) room.guestName = badRoom.Describe__c.stripHtmlTags() + timeMsg;
        		    	if (CommUtils.isBlank(room.guestName)) room.guestName = badRoom.Name + timeMsg;
        		    	// 2018/06/06 故障Tips内容更新 by zy END
        		    	// 2017/05/05 故障部屋の詳細説明情報はバルーンで表示 end by wx
        		    	//room.leadId = badRoom.Id;// 故障情報のIDを設定する
        		    	room.cssClass = this.strIsBadStatusColor;
        		    	isBadStatusSum += 1;
        		    	//2015/10/26 トップ予約show
        		    	if(roomLeadMap.containsKey(room.sobj.Id)){
        		    		room.isBadRoom = true;
        		    	}
        		    	Id topLeadId = roomLeadMap.get(room.sobj.Id) != null ? roomLeadMap.get(room.sobj.Id).id : null;
        		    	if(!topLeadIdSet.contains(topLeadId)) continue;
        		    }
        		    // 未清掃の部屋存在する場合、設定を行う
        		    if (cleanStatusRoomMap.containsKey(room.sobj.Id)) {
        		    	if (cleanStatusRoomMap.get(room.sobj.Id) == CommConst.LEAD_ROOM_ST_UNCLEAN) {
        		    		room.isUnClean = true;
        		    		if (headSameCleanStautsFlg || cleansLst.isEmpty()) isNoCleanStatusSum++;
        		    	}
        		    }
        			// 予約データが存在する場合
        			if (roomLeadMap.containsKey(room.sobj.Id)) {
        				Lead__c lead = roomLeadMap.get(room.sobj.Id);
        				// 部屋情報に、予約情報を維持する
        				room.setLeadInfo(lead, (statusCode != constStatusCodeLead ? null : leadStatusColorMap));
						// 印刷済みフラグ設定する
						room.isAccountedFlg = isAccountedFlgMap.containsKey(lead.Id) ? isAccountedFlgMap.get(lead.Id) : false;
						// 2017/12/21 レジカードにサインしたのがルームインジケータでわかるように改善対応 zyz BEGIN
						room.isYadoStr = isGuestFlgMap.get(lead.Id);
						// 2017/12/21 レジカードにサインしたのがルームインジケータでわかるように改善対応 zyz END
						// 2020/02/29 小部屋機能改善 BY zyz BEGIN
						room.isRoomFlg = isleadRoomLMap.containsKey(lead.Id) ? isleadRoomLMap.get(lead.Id) : false;
						room.roomTypeCode = CommUtils.nullToBlank(room.sobj.ShopInfoRef__r.ShopCode__c);
						// 2020/02/29 小部屋機能改善 BY zyz END
						// 2019/12/30 小部屋の作成 BY zyz BEGIN
						room.isSmallRoomFlg = isleadSmallRoomLMap.containsKey(lead.Id) ? isleadSmallRoomLMap.get(lead.Id) : false;
						// 2019/12/30 小部屋の作成 BY zyz END
	        		    //お部屋ステータス：[未清掃]
						// 2019/11/30 清掃エラー修正　by　zy BEGIN
						// if (lead.Field299__c == CommConst.LEAD_ROOM_ST_UNCLEAN) {
						if (lead.Field299__c == CommConst.LEAD_ROOM_ST_UNCLEAN && !room.sobj.RoomNotCreateFlg__c) {
						// 2019/11/30 清掃エラー修正　by　zy END
							room.isUnClean = true;
						}

        				// 予約ステータス[チェックイン完/外出中/滞在中]
        				String status = lead.Field298__c;
        				// 2019/02/28 滞在・外出状態の管理 WGCH BEGIN
        				if(lead.Field298__c == CommConst.LEAD_GUEST_ST_OUT && outButtonShowFlg ) {		// 外出ボタンで切り替え表示するため、ステータスはチェックアウトすると、出発状態を表示する
        					// 外出予定
        					room.cssClass = this.strIsOutStatusColor;
        					outStatusSum += 1;
        				}
        				else if( status == CommConst.LEAD_GUEST_ST_CI ||
                            status == CommConst.LEAD_GUEST_ST_OUT ||
                            status == CommConst.LEAD_GUEST_ST_BATH){
                        // 2019/02/28 滞在・外出状態の管理 WGCH END
							// 出発日は今の日付の場合：出発予定
        					//if(lead.LeadIndexRef__r.DepartureDate__c == processDate){
        					if (lead.LeadIndexRef__r.DepartureDate__c == uiInputDate) {
        						room.cssClass = this.strCheckOutDayStatusColor;
        						checkOutDayStatusSum += 1;
								// 2020/09/30 当日チェックアウトの日帰り予約がチェックイン後にルームチェンジできなくなる不具合の解消 by zy BEGIN
								if (oneDayCanMoveFlg && lead.StayNightCal__c == 0) room.cssClass += ' ' + this.strIsOneDayStayColor;
								// 2020/09/30 当日チェックアウトの日帰り予約がチェックイン後にルームチェンジできなくなる不具合の解消 by zy END
        					}
        					// 滞中
        					else{
        						// 2018/05/09 ルームインジケータの最終日意外泊目のステータスも自動で赤に変え　by ZY BEGIN
        						//room.cssClass = this.strIsStayStatusColor;
        						room.cssClass = getCheckOutColor(lead);
        						// 2018/05/09 ルームインジケータの最終日意外泊目のステータスも自動で赤に変え　by ZY END
        						isStayStatusSum += 1;
        						//2017/03/13 ルームインジケーターにて、すでに宿泊予約で部屋変更不可の予約が入っている部屋に、アサインができるように改善対応 by zy BEGIN
	        					// 該当部屋のデータは移動可能
	        					//room.isCanMove = true && !room.isBlocked;
	        					room.isCanMove = true ;
	        					//2017/03/13 ルームインジケーターにて、すでに宿泊予約で部屋変更不可の予約が入っている部屋に、アサインができるように改善対応 by zy END
								// 清掃データ状態確認、既に未清掃の場合、下記処理はスキップする
	        					if (!room.isUnClean) {
	        						// 既に清掃済の場合、表示しない[存在すると、既に清掃済に認識する]
	        						if (!cleanStatusRoomMap.containsKey(room.sobj.Id)) {
			        					// 2013/08/14 滞中のデータに対して、清掃データは自動作成する（期間は当日分の清掃データ）
			        					// 清掃データ作成タイミング：予約データのC/O時刻から清掃データを作成する
			        					// 該当部屋は清掃データ範囲内場合
			        					// 出発日時間はシステム時間により、超える場合
										Time departTime = CommUtils.stringToTime(lead.Field3__c == null ? DEF_CHECKOT_TIME : lead.Field3__c);
										DateTime leadDepartDt = DateTime.newInstance(lead.Departure__c.date(), departTime);
										// 2018/01/24 清掃不要機能追加　by　zy　BEGIN
										// if (systemDtFormat >= leadDepartDt.format('yyyyMMddHHmm')) {
			        					if (systemDtFormat >= leadDepartDt.format('yyyyMMddHHmm') && !lead.NoCleanRoomFlg__c) {
			        					// 2018/01/24 清掃不要機能追加　by　zy　END	
			        						// 連泊など滞中の掃除ステータスは無条件に清掃対象
			        						cleanRoomIdSet.add(room.sobj.Id);
			        					}
	        						} // End If (!cleanStatusRoomMap.containsKey(room.sobj.Id))
	        					} // End If (!room.isUnClean)
        					}
        				}
        				// 予約ステータス[チェックアウト完 && 出発日は処理日場合]
//        				else if(lead.Field298__c == CommConst.LEAD_GUEST_ST_CO &&
//        						lead.LeadIndexRef__r.DepartureDate__c == processDate) {
        				else if(lead.Field298__c == CommConst.LEAD_GUEST_ST_CO ) {		// チェックインＡＮＤチェックアウトボタンで切り替え表示するため、ステータスはチェックアウトすると、出発状態を表示する
        					// 出発予定
        					room.cssClass = this.strCheckOutStatusColor;
        					checkOutStatusSum += 1;
        				}
        				else{
        					// 空室「顧客存在、未チェックイン場合」
        					//room.cssClass = this.strEmptyStatusColor;
        					room.cssClass = this.strAssignedStatusColor;
        					//2017/03/13 ルームインジケーターにて、すでに宿泊予約で部屋変更不可の予約が入っている部屋に、アサインができるように改善対応 by zy BEGIN
        					// 該当部屋のデータは移動可能
        					//room.isCanMove = true && !room.isBlocked;
        					room.isCanMove = true;
        					//2017/03/13 ルームインジケーターにて、すでに宿泊予約で部屋変更不可の予約が入っている部屋に、アサインができるように改善対応 by zy END
        					//iEmptyStatusSum += 1;
        					isAssignedStatusSum ++;
        				}
        			}else{
        				// 空室「予約データがない場合」
        				room.cssClass = this.strIsNoneStatusColor;
        				iEmptyStatusSum += 1;
        			}
					// 2019/11/15 ルームインジケータの表示について、清掃済だけでなくインスペ完の状況を追加したいです。 by zy BEGIN
        			if(cleanDetailStatusRoomMap.containsKey(room.sobj.Id)) {
        				RoomSstatus__c rs = cleanDetailStatusRoomMap.get(room.sobj.Id)[0];
						String status = !exitColorMap.containsKey(rs.cleanStatus__c) ? defStatus : exitColorMap.get(rs.cleanStatus__c);
        		    	// 5252 bug fixed by zy BEGIN
						if (rs.Result__c == CommConst.LEAD_ROOM_ST_CLEANED && CommUtils.isBlank(room.status)) {
							if( room.leadDetail.Field298__c != CommConst.LEAD_GUEST_ST_CI &&
								room.leadDetail.Field298__c != CommConst.LEAD_GUEST_ST_OUT &&
								room.leadDetail.Field298__c != CommConst.LEAD_GUEST_ST_BATH 
								// 2020/03/31 清掃ステータス,清掃完了カラー未設定の場合、カラー非表示 by zy BEGIN
								&& exitColorMap.containsKey(rs.cleanStatus__c)){
								// 2020/03/31 清掃ステータス,清掃完了カラー未設定の場合、カラー非表示 by zy END
								room.status = status;
							}
						} else {
							room.status = status;
							if (!headSameCleanStautsFlg && status == defStatus) isNoCleanStatusSum++;
						}
						// 5252 bug fixed by zy END
        			}
			    	// 2019/11/15 ルームインジケータの表示について、清掃済だけでなくインスペ完の状況を追加したいです。 by zy END
        		}
        	}
        }
        // 空欄を補足する
        for (AreaRoomInfo area : areaInfLst) {
            for (FloorRoomInfo floor : area.floorRoomLst) {
            	Integer dumyRooms = maxRooms - floor.roomLst.size();
            	// 2018/05/10 レスバンス15M超出修正　by　zy BEGIN
            	floor.blankSize = new list<Integer>{};
            	// 2018/05/10 レスバンス15M超出修正　by　zy END
                for (Integer i = 0; i < dumyRooms; i++) {
                	// 2018/05/10 レスバンス15M超出修正　by　zy BEGIN
                	/*
                	// 2017/12/22 画面フィルター機能追加　by　zy　BEGIN
                	RoomInfo info = new RoomInfo(new Room__c(), roomNameType);
                	if (!CommUtils.isBlank(filterHidRoom) && CommUtils.isBlank(floor.cssClass)) {
						info.filterClass = filterClass;
					}
                	floor.addRoom(info);
                	// 2017/12/22 画面フィルター機能追加　by　zy　END
                	*/
                	floor.blankSize.add(i);
                	// 2018/05/10 レスバンス15M超出修正　by　zy END
                }
            }
        }
        // 2013/08/14
        if (!cleanRoomIdSet.isEmpty()) {			
        	// この部屋は清掃データ自動作成を行う
        	Date tmpDate = getInputDate(0); // 指定日で掃除情報を作成する
			(new RoomStatusManager()).createNoCleanRooms(tmpDate, cleanRoomIdSet);
        }
        // 2013/04/14
        this.setMessageItem(processDate);
        // 2016/10/12 見積明細設定機能対応 by zh
        initBookingFormInfo();
        // 2016/10/12 見積明細設定機能対応 by zh
	}
	
	/**
	* 期間変更に従って、期間部屋アサイン重複チェックを行う
	* leadId: 変更された予約ID：
	* newNights: 変更された泊数
	* roomId: 既にアサインされている部屋ID
	* queryDt : 画面の指定日
	**/
	@remoteAction
	global static MsgItem preChgSaveNightsInfo(String roomId, String fromLeadId, Integer orgNights, Integer newNights, String queryDt, Boolean showToday) {
		
		// 泊数は１までの場合、重複チェックなし
		if (newNights <= 1) return new MsgItem(); //'';
		if (orgNights >= newNights) return new MsgItem(); //'';
		// 処理日取得
		//Date todayDt = (String.isEmpty(queryDt)) ? Date.today() : Date.parse(queryDt);
		Date todayDt = (String.isEmpty(queryDt)) ? Date.today() : CommUtils.stringToDate(queryDt);
		Date searchDt = getProcessDate(todayDt, showToday);
		List<Lead__c> leads = getOrgMoveLeadInfo(fromLeadId, searchDt);
		// 泊数により、新た予約ダミデータを作成する
		Date startDt = leads[leads.size()-1].EntryTime__c.date();
		// チエック用予約格納
		List<Lead__c> chkLeads = new List<Lead__c>();
		//Date startDt =  leads[leads.size()-1].EntryTime__c.Date();
		for (Integer i = orgNights; i < newNights; i++) {
			// 開始日
			startDt = startDt.addDays(1);
			// ダミ予約データ
			Lead__c dumyLead = new Lead__c (
				EntryTime__c = startDt,
				Departure__c = startDt.addDays(1)
			);
			chkLeads.add(dumyLead);
		}
		if (chkLeads.isEmpty()) return new MsgItem(); //'';
		// 重複期間チェックを行う
		else return preUpdateMemoryRoomLeadMap(null, fromLeadId, roomId, null, queryDt, chkLeads, null, showToday);
	}
	// 変更情報格納用クラス
	public PopupWinInfo leadInfo{get; set;}
	/**
	* 予約情報チャンジ処理を行う
	* 泊数変更機能対応
	**/
	public void chgSaveNightsInfo () {
		
		// クリックした予約ID
		String leadId = strLeadId; //leadInfo.leadId;
		// 最新の予約情報を取得する
		List<Lead__c> leadInfLst = [select id, LeadIndexRef__c, LeadIndexSubId__c,RoomGroupNo__c,
									refTypeOfRooms__c, StayPersons__c
									,ExtraBedChk__c,Field310__c
									from Lead__c 
									where Id = :leadId And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG  ];
		// 既存有効な予約データが見つからない場合
		if (leadInfLst.isEmpty()) {
			//該当予約データが見つかりません。
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_008_0103));
			// 2018/05/14 报错以后房间消失问题对应 by zy BEGIN
		    refreshPage();
		    // 2018/05/14 报错以后房间消失问题对应 by zy END
			return;
		}
		
		// 入力情報により、関連の予約情報を一括変更を行う
		// 泊数、最後の出発日変更対応を行う
		// 同じグループNO、同じSUBINDEXの予約データは連動更新を行う
		List<Lead__c> leads = [select id, Name,Rroom__c,UnitPriceDefKbCal__c,Relcontact__c,
				StayPersons__c,EntryTime__c,Departure__c,Field4__c,Field3__c,Comment3__c
			from Lead__c 
			where LeadIndexRef__c = :leadInfLst[0].LeadIndexRef__c 
			And LeadIndexSubId__c = :leadInfLst[0].LeadIndexSubId__c
			And RoomGroupNo__c = :leadInfLst[0].RoomGroupNo__c
			And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 
			Order By EntryTime__c ] ;
		// 到着時刻と出発時刻を変更される場合
		Boolean timeChangeFlg = false;
		for (Lead__c upd : leads) {
			if (upd.Field4__c != leadInfo.entryTime || upd.Field3__c != leadInfo.departureTime) {
				timeChangeFlg = true;
				upd.Field4__c = leadInfo.entryTime;
				upd.Field3__c = leadInfo.departureTime;
			}
		}
Savepoint sp = Database.setSavepoint();
try {
		//2016/11/25 お客様の項目の入力機能追加　BEGIN
		if(hadUpdContactFlag){
			newContact.id = leads[0].Relcontact__c;
			upsertCustomContact();
			bookingCreateOK = true;
		}
		//2016/11/25 お客様の項目の入力機能追加　END
		// 泊数の日付情報
		Date startDate = leads[0].EntryTime__c.date();
		Date endDate = leads[leads.size()-1].Departure__c.date();
		// XML___wgch 2016/11/16 特記事項 BEGIN
		String oldComment3 = leads[0].Comment3__c;
		String newComment3 = leadInfo.Comment3;
		// XML___wgch 2016/11/16 特記事項 END
		// 元泊数 / 新泊数
		Integer orgNights = startDate.daysBetween(endDate);
		Integer newNights = Commutils.nullToZero(leadInfo.nights).intValue();
		// 新予約人数/元予約人数
		Integer leadPeopleNum = Commutils.nullToZero(leadInfo.leadPeopleNum).intValue();
		Integer orgLeadPeopleNum = Commutils.nullToZero(leadInfo.orgLeadPeopleNum).intValue();
		// 変更なし[泊数・人数]
		//if (orgNights == newNights && leadPeopleNum == orgLeadPeopleNum && !timeChangeFlg) return;
		// XML___wgch 2016/11/16 特記事項 BEGIN 
		if (orgNights == newNights && leadPeopleNum == orgLeadPeopleNum && !timeChangeFlg && oldComment3 == newComment3) return;
		// XML___wgch 2016/11/16 特記事項 END
		// ------------------------------------------
		// SUBINDEX関連情報の自動設定対応
		// ------------------------------------------
		// SUBINDEXのID対応の実データが未存在する場合、下記処理を行う
		if (!CommUtils.isBlank(leadInfLst[0].LeadIndexSubId__c)) {
			List<LeadIndex__c> subIdxExistChkLst = [select id from LeadIndex__c where id = :leadInfLst[0].LeadIndexSubId__c];
			if (subIdxExistChkLst.isEmpty()) leadInfLst[0].LeadIndexSubId__c = null;
		}
		// SubIndex関連情報を取得、再設定を行う
		String subIdxId = leadInfLst[0].LeadIndexSubId__c == null ? leadInfLst[0].LeadIndexRef__c : leadInfLst[0].LeadIndexSubId__c;
		String subIdxQueryStr = CommSqlUtils.generateQueryString('LeadIndex__c');
		subIdxQueryStr += ' Where Id = :subIdxId ';
		List<LeadIndex__c> idxLsts = DataBase.query(subIdxQueryStr);
		// 部屋数は１以上の場合、
		// TODO:元SUBINDEXに、複数部屋は存在する場合、この一つの部屋の期間を調整する場合
		// 該当予約関連のSUBINDEXは自動新規作成を行う
		// 該当SUBINDEXだけ存在する場合、直接SUBINDEX新規・更新を行う
		LeadIndex__c subIdx = null;

		// SUBINDEXは未存在する場合、予約インデクスから自動コピー、設定を行う
		if (leadInfLst[0].LeadIndexSubId__c == null) {
			// INDEXからコピーして、SUBINDEXを作成する
			subIdx = idxLsts[0].clone(false,true);
			subIdx.ParentLeadIndxRef__c = idxLsts[0].Id;
			subIdx.RoomTypeRef__c = leadInfLst[0].refTypeOfRooms__c;
			subIdx.StayPersons__c = leadInfLst[0].StayPersons__c;
			subIdx.PlanRef__c = leadInfLst[0].Field310__c;
			subIdx.ExtraBedChk__c = leadInfLst[0].ExtraBedChk__c;
			subIdx.Rooms__c = 1;
		} else {
			// SUBINDEX情報を設定する
			if (idxLsts[0].Rooms__c > 1) {
				subIdx = idxLsts[0].clone(false,true);
				subIdx.Rooms__c = 1;
				subIdx.RoomTypeRef__c = leadInfLst[0].refTypeOfRooms__c;
				subIdx.StayPersons__c = leadInfLst[0].StayPersons__c;
				// 元SUBINDEXの部屋数はマナス１に計算する
				idxLsts[0].Rooms__c --;
				update idxLsts[0];
			} else {
				subIdx = idxLsts[0];
			}
		}

		// ------------------------------------------
		// 期間変更対応
		// ------------------------------------------
		// 日帰り場合、泊数０ですが、計算するため、１に自動転換する
		if (orgNights == 0 && newNights >= 1) {
			leads[0].Departure__c = leads[0].Departure__c.addDays(1);
			orgNights = 1;
		}
			
		// -------------------
		// 泊期間延長の場合
		// -------------------
		// 2017/12/18 延泊処理時の見積自動コピー機能対応 WGCH BEGIN
		List<BookingEstimateItem__c> cloneBookEstLst = null;
		Map<String,List<PlanDetail__c>> prodDetailMap = new Map<String,List<PlanDetail__c>>();
		// 2017/12/18 延泊処理時の見積自動コピー機能対応 WGCH END
		if (orgNights < newNights) {
			// 新規の予約データを自動設定、作成を行う
			// コピー元は同じ部屋の最後の予約データの設定情報
			// 最後の最新予約データん全項目を取得して、コピーを行う「全項目設定情報を取得する」
			String locLeadId = leads[leads.size()-1].Id;
			String leadQueryStr = CommSqlUtils.generateQueryString('Lead__c');
			leadQueryStr += ' Where id = :locLeadId ';
			Lead__c cloneLead = Database.query(leadQueryStr);
			// 2016/11/10 時刻再設定を行う BEGIN
			cloneLead.Field4__c = leads[leads.size()-1].Field4__c;
			cloneLead.Field3__c = leads[leads.size()-1].Field3__c;
			// 2016/11/10 時刻再設定を行う END
			// 2014/08/27 単価定義区分機能対応
			cloneLead.UnitPriceDefKb__c = cloneLead.UnitPriceDefKbCal__c;
			// 2017/12/18 延泊処理時の見積自動コピー機能対応 WGCH BEGIN
			if(isCloneBookEstFlg){
				// 取到最后一天的見積明細
				cloneBookEstLst= [select id, name, refBooking__c, ActionType__c,Amount__c,RowNo__c,
							refAccountMaster__c, refAccountMaster__r.Name, TaxRate__c, ServiceRate__c, SpecialTax__c, UnitPrice__c,
							// 2016/12/08 見積明細利用日機能対応 BEGIN zyz
							UseDate__c, refBooking__r.EntryTime__c, refBooking__r.Departure__c
							// 2016/12/08 見積明細利用日機能対応 END zyz
							,GoukeinoneTax__c, SpTotal__c, ProductName__c, PlanDetailSyncInfo__c
							// 2017/12/13 見積明細非表示機能対応 WGCH BEGIN
							,InvoiceNoShowFlg__c, NoShowRequestFlg__c
							// 2017/12/13 見積明細非表示機能対応 WGCH END
							from BookingEstimateItem__c where refBooking__c =: cloneLead.Id and ParentBookingItemRef__c = null and ActionType__c !=: ACTTYPE_PAY and ActionType__c !=: ACTTYPE_AR Order By RowNo__c,Name];
				Set<String> pAccMasterIdSet = new Set<String>();
				for(BookingEstimateItem__c bookEst : cloneBookEstLst){
					// 取 最后一天見積明細里 会计商品为Plan的会计商品Id
					if(bookEst.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) pAccMasterIdSet.add(bookEst.refAccountMaster__c);
				}
				// 取 最后一天見積明細里 会计商品为Plan的会计商品   的plan明细
				for (PlanDetail__c pd : [select AccountMasterRef__c, AccountMasterRef__r.name 
											,AccountMasterRef__r.ActionType__c,PlanProdcut__c, Price__c from PlanDetail__c where PlanProdcut__c in: pAccMasterIdSet]) {
					if (!prodDetailMap.containsKey(pd.PlanProdcut__c)) prodDetailMap.put(pd.PlanProdcut__c,new List<PlanDetail__c>());
					prodDetailMap.get(pd.PlanProdcut__c).add(pd);
				}
			}
			// 2017/12/18 延泊処理時の見積自動コピー機能対応 WGCH END
			// コピー元の予約データを取得、
			for (Integer i = orgNights; i < newNights; i++) {
				// コピー元の予約情報を取得する
				Lead__c lead = cloneLead.clone(false,true);
				// 受付日
				lead.ReservedDate__c = System.now();
				// 受付者
				lead.ReservedContact__c = UserInfo.getName();
				// お客様ステータス
				lead.Field298__c = null;
				// 2013/11/30 部屋変更不可のクリア
				lead.Field276__c = false;
				// 到着日、出発日設定を行う
				lead.EntryTime__c = leads[leads.size()-1].EntryTime__c.addDays(1);
				lead.Departure__c = leads[leads.size()-1].Departure__c.addDays(1);
				// 新規データを追加する
				leads.add(lead);
			}

			// 予約名
			String orgLeadName = cloneLead.Name;
			
			// 予約名切替用キー
			//泊目
			String repRegExpKey1 = LEAD_NAME_PREFIX + '([0-9]+-[0-9]+'+ Label.CONST_008_0110 +')';
			//泊目
			String repRegExpKey2 = '([0-9]+-[0-9]+'+ Label.CONST_008_0110 +')';
			String repRegKey = String.valueOf(DateTime.now().getTime())+Crypto.getRandomLong();

			// 元予約データ名は：999-999泊目+予約名　方式　OR　代表部屋標識+999-999泊目+予約名
			// 上記方式の場合、直接Replace方式で名前再設定を行う
			// 元予約名は 代表部屋標識+予約名の場合、999-999泊目に入り替えする, 予約名の場合、直接 999-999泊目方式に設定する
			String regexpResult1 = orgLeadName.replaceFirst(repRegExpKey1, repRegKey);
			String regexpResult2 = orgLeadName.replaceFirst(repRegExpKey2, repRegKey);
			
			// 泊目書式場合
			if (regexpResult1 != orgLeadName || regexpResult2 != orgLeadName) {
				// 代表部屋標識+999-999泊目+予約名 && 999-999泊目+予約名
				// 予約名の再設定を行う
				for (Integer i = 0; i < newNights; i++ ) {
					// 予約名を設定する
					if (newNights > 1) {
						//泊目
						String newName = newNights + '-' + (i+1) + Label.CONST_008_0110 +' ';
						leads[i].Name = orgLeadName.replaceFirst(repRegExpKey2, newName);
					} else {
						leads[i].Name = orgLeadName.replaceFirst(repRegExpKey2, '');
					}
				}
			} else if (orgLeadName.startsWith(LEAD_NAME_PREFIX)) {
				// 代表部屋標識+予約名の場合
				for (Integer i = 0; i < newNights; i++ ) {
					// 予約名を設定する
					if (newNights > 1) {
						//泊目
						String newName = LEAD_NAME_PREFIX + newNights + '-' + (i+1) + Label.CONST_008_0110 +' ';
						leads[i].Name = orgLeadName.replaceFirst(LEAD_NAME_PREFIX, newName);
					}
				}
			} else {
				// 予約名の場合
				for (Integer i = 0; i < newNights; i++ ) {
					// 予約名を設定する
					if (newNights > 1) {
						//泊目
						leads[i].Name = newNights + '-' + (i+1) + Label.CONST_008_0110 +' ' + orgLeadName;
					}
				}
			}
		} 
		// -------------------
		// 期間短縮の場合
		// -------------------
		else if (orgNights > newNights) {
			
			// 泊数は０の場合、日帰りデータになりました
			if (newNights == 0) {
				// 日帰りの場合、出発日は当日になる
				leads[0].Departure__c = leads[0].EntryTime__c;
			} 
			
			Integer locNewNights = (newNights == 0 ? 1 : newNights);
//			System.debug('locNewNights-------------' + leads[0].Name);
			for(Integer i = 0 ; i < locNewNights ; i ++){
				if(newNights > 1){
					leads[i].Name = changeLeadName(leads[i].Name,false,newNights,i);
				}else{
					leads[0].Name = changeLeadName(leads[0].Name,true,newNights,0);
				}
//				System.debug('-------------' + leads[i].Name);
			}
			
			// 期間外の予約データは全部キャンセル処理を行う
			for (Integer i = locNewNights; i < orgNights; i++) {
				// 期間対象外の予約データはキャンセル更新
				leads[i].ReservedStatus__c = CommConst.LEAD_ST_CANCEL;
			}
			// 期間短縮後の部屋は「宿泊者名簿」に登録する部屋と照合する
			// 元宿泊期間は１泊以上場合、期間変更に従って、部屋変更すると、宿泊者名簿に反映連動を行う
			if (orgNights > 1 ) {
				Lead__c lead = leads[locNewNights-1];
				List<BookingGuest__c> updGuestList = [select RoomRef__c from BookingGuest__c 
					where IndexSubRef__c = :leadInfLst[0].LeadIndexSubId__c and RoomGroupNo__c = :leadInfLst[0].RoomGroupNo__c
					And RoomRef__c != :leads[locNewNights-1].Rroom__c];
				if (!updGuestList.isEmpty()) {
					for (BookingGuest__c bookGuest : updGuestList) {
						bookGuest.RoomRef__c = lead.Rroom__c;
					}
					update updGuestList;
				}
			}
		}
		
		// 営業処理日
		Date searchDt = getProcessDate(processDate, isShowToday);

		// 人数変更場合
		if (leadPeopleNum != orgLeadPeopleNum ) {
			// 処理日を取得して、該当処理日から変更を行う
			
			// 期間外の予約データは全部キャンセル処理を行う
			for (Lead__c lead : leads) {
				if (lead.EntryTime__c.date() < searchDt) continue;
				//for (Integer i = newNights; i < orgNights; i++) {
				lead.StayPersons__c = leadPeopleNum;
			}
			// 人数は再設定を行う
			subIdx.StayPersons__c = leadPeopleNum;
		}
		// SUBINDEXの
		subIdx.EntryDate__c = leads[0].EntryTime__c.Date();
		// 日帰り、N泊処理機能
		subIdx.DepartureDate__c = leads[newNights == 0 ? 0 : newNights-1].Departure__c.Date();
		subIdx.Nights__c = newNights;
		Database.UpsertResult subRs = Database.upsert(subIdx);
		if (subRs.isCreated()) {
			for (Lead__c lead : leads) {
				lead.LeadIndexSubId__c = subRs.getId();
				lead.RoomGroupNo__c = 0;
			}
		}
		// XML___wgch 2016/11/16 特記事項 BEGIN
		if(oldComment3 != newComment3){
			for (Lead__c lead : leads) {
				if(lead.EntryTime__c.date() >= searchDt){
					lead.Comment3__c = newComment3;
				}	
			}
		}
		// XML___wgch 2016/11/16 特記事項 END	
		// 予約情報更新処理を行う
		upsert leads;
		// 2017/12/18 延泊処理時の見積自動コピー機能対応 WGCH BEGIN
		if(isCloneBookEstFlg && orgNights < newNights && cloneBookEstLst != null){
			// 見積明細ID判断
			String BOOKING_SOBJ_KEY = BookingEstimateItem__c.sObjectType.getDescribe().getKeyPrefix();
			List<Lead__c> newLeadLst = new List<Lead__c>();
			// 取得 延长的新预约
			for (Integer i = orgNights; i < leads.size(); i++) {
				newLeadLst.add(leads[i]);
			}
			// 删除自动克隆过来的見積明細
			delete [select id from BookingEstimateItem__c where ParentBookingItemRef__c != null And refBooking__c in: newLeadLst];
			delete [select id from BookingEstimateItem__c where ParentBookingItemRef__c = null And refBooking__c in: newLeadLst];
			List<BookingEstimateItem__c> newBookEstLst = new List<BookingEstimateItem__c>();
			// 克隆新的見積明細
			for(Lead__c ld : newLeadLst){
				for(BookingEstimateItem__c bookEst : cloneBookEstLst){
					BookingEstimateItem__c newBookEst = bookEst.clone(false,true);
					// 克隆新的Plan見積明細
					if (prodDetailMap.containsKey(newBookEst.refAccountMaster__c) && newBookEst.PlanDetailSyncInfo__c != null) {
						List<PlanDetail__c> detailLst = prodDetailMap.get(newBookEst.refAccountMaster__c);
						String[] prods = newBookEst.PlanDetailSyncInfo__c.split(';');
						String syncPlan = '';
						// 重置新的Sync字段
						for (integer m = 0 ; m < prods.size() ; m++) {
							String message = prods[m];
							if (CommUtils.isBlank(message)) continue;
							String firstId = message.subStringBefore(':');
							// 見積明細ID判断
							if (!firstId.startsWith(BOOKING_SOBJ_KEY)) {
								syncPlan += message + ';';
								continue;
							}
							String lastMsg = message.subStringAfter(':');
							syncPlan += detailLst[m].id + ':' + lastMsg + ';';
						}
						// 新的Sync
						newBookEst.PlanDetailSyncInfo__c = syncPlan;
					}
					newBookEst.refBooking__c = ld.Id;
					newBookEst.UseDate__c = ld.EntryTime__c != null ? ld.EntryTime__c.Date() : null;
					newBookEstLst.add(newBookEst);
				}
			}
			// 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
	        newBookEstLst.addAll(CommLogicProcess.getBathTaxBookEstLst(newLeadLst, newBookEstLst));
			// 2020/07/30 入湯税の自動入力機能について改善 WGCH END
			if(!newBookEstLst.isEmpty()) upsert newBookEstLst;
		}
		// 2017/12/18 延泊処理時の見積自動コピー機能対応 WGCH END
		if (subRs.isCreated()) {
			// 関連新規作成したSUBINDEXの部屋は宿泊者名簿にコピーする
			List<Lead__c> existList = getOrgMoveLeadInfo(leads[leads.size()-1].Id, searchDt);
			createBookingGuest(existList[existList.size()-1]);
		}
} catch(Exception e) {
	// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 BEGIN
	String errMsg = e.getMessage();
	if(!CommUtils.isFieldValidationMessage(errMsg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
	// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 END
	DataBase.rollback(sp);
	// 2018/05/14 报错以后房间消失问题对应 by zy BEGIN
    refreshPage();
    // 2018/05/14 报错以后房间消失问题对应 by zy END
	bookingCreateOK = false;
	return;
}
		// 最新情報を取得して、画面に表示する
		refreshPage();
bookingCreateOK = true;
	}

    /**
    * 部屋情報の明細情報を取得する
    * 該当部屋に予約データの詳細情報を取得する
    **/
    // XML___wgch 2016/11/16 BEGIN
    @RemoteAction
    global static PopupWinInfo getRoomInfo(String roomId, String leadId) {
    	throw new CommException('This Method No Used');
    }
    private static final String QueryRoomInfoFields = 'Id,Name,Field298__c,Rroom__r.Name, Relcontact__r.Id, Relcontact__r.Name, Field310__r.Name, LeadIndexRef__r.Name,Field276__c,LeadIndexSubId__c,RoomGroupNo__c,LeadIndexRef__c,StayPersons__c,Field2__c,Comment3__c'.toLowerCase();
    @RemoteAction
    global static PopupWinInfo getRoomInfoExt(String roomId, String leadId, String jsonField,String contactFields) {
    	if(String.escapeSingleQuotes(roomId) != '' && String.escapeSingleQuotes(leadId) != ''){
    		// 2014/11/27 指定オブジェクトの項目情報は
    		//2016/11/29 tolabel error fix by zy BEGIN
			map<String, Schema.DescribeFieldResult> modelDeafaultValuesMap = CommSqlUtils.getAllFieldLst(Lead__c.sObjectType,true,true);
			//2016/11/29 tolabel error fix by zy END
			/* XML___wgch 2016/11/16 BEGIN
    	    Lead__c leadDetail = [	Select Id, Name, RecordType.Name, Receptiondate__c, LeadIndexRef__r.Name,
    	    						Rroom__c, Rroom__r.Name, Relcontact__r.Id, Relcontact__r.Name,Field276__c,
    	                           	LeadIndexSubId__c, LeadIndexRef__c, RoomGroupNo__c, ReservedStatus__c, 
    	                          	//LeadIndexRef__c,LeadIndexRef__r.EntryDate__c,LeadIndexRef__r.EntryTime__c,
    	                           	//LeadIndexRef__r.DepartureDate__c,LeadIndexRef__r.DepartureTime__c, 
    	                           	EntryTime__c, Field4__c,
    	                           	Departure__c, Field3__c, Field310__r.Name, toLabel(ps__Field298__c),StayPersons__c,SeminarOrderFlg__c,Field2__c,
    	                           	Field308__c,Comment3__c 
    	                           	From Lead__c where Id = :leadId];*/	
    	    set<string> filterFieldsSet = new set<string>(QueryRoomInfoFields.deleteWhitespace().split(','));
	    	filterFieldsSet.addAll(CommUtils.nulltoBlank(jsonField).toLowerCase().deleteWhitespace().split(','));
	    	String leadQueryFields = '';
	    	for (String key : filterFieldsSet) {
	    		if (CommUtils.isBlank(key)) continue;
	    		//2016/11/29 tolabel error fix by zy BEGIN
	    		if (modelDeafaultValuesMap.containsKey(key)){

	    			Schema.DescribeFieldResult dr = modelDeafaultValuesMap.get(key);
		    		if (dr.getType() == DisplayType.Picklist || dr.getType() == DisplayType.MultiPicklist){
		    			key = 'toLabel(' + dr.getName() + ')';

		    		}
	    		}
	    		//2016/11/29 tolabel error fix by zy END
	    		leadQueryFields += key + ',';
	    	}
	    	// 2019/12/30 名前か電話番号のどちらかだけ一致するお客様がすでに存在する BY zyz BEGIN
	    	// 顾客名字段/电话字段检索追加
	    	if (!leadQueryFields.toLowerCase().contains('relcontact__r.name')) leadQueryFields += 'Relcontact__r.Name,';
	    	if (!leadQueryFields.toLowerCase().contains('relcontact__r.phone')) leadQueryFields += 'Relcontact__r.Phone,';
	    	if (!leadQueryFields.toLowerCase().contains('rroom__r.shopinforef__r.shopcode__c')) leadQueryFields += 'Rroom__r.ShopInfoRef__r.ShopCode__c,';
	    	if (!leadQueryFields.toLowerCase().contains('reftypeofrooms__r.shopinforef__r.shopcode__c')) leadQueryFields += 'refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c,';	
	    	// 2019/12/30 名前か電話番号のどちらかだけ一致するお客様がすでに存在する BY zyz END
	    	leadQueryFields = leadQueryFields.removeEnd(',');
			String leadQueryStr = 'Select ' + leadQueryFields +' From Lead__c ';

			leadQueryStr += ' Where id = :leadId ';
			List<Lead__c> leadLst = Database.query(leadQueryStr);
    	    Lead__c leadDetail = leadLst[0];					
    	    // 連泊情報を取得する
			List<Lead__c> leads = [ select id, EntryTime__c,Departure__c,Field4__c,Field3__c,Field298__c,Relcontact__c
		// XML___wgch 2016/11/16 END									
									from Lead__c 
									where LeadIndexRef__c = :leadDetail.LeadIndexRef__c 
									And LeadIndexSubId__c = :leadDetail.LeadIndexSubId__c
									And RoomGroupNo__c = :leadDetail.RoomGroupNo__c
									And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 
									Order By EntryTime__c] ;
	    	// 会計情報を取得する　
	    	// 2019/07/17 VOIDされた会計データは取得対象外対応 WSQ BEGIN
	    	//List<AccountAcount__c> acountAcountLst = [select id,Field53__c,AccountName__c,ContactName__c,AccountReceiptName__c,BillingCal__c,AccountProviso__c from AccountAcount__c where Relreserve__c = :leadId order by LastModifiedDate desc limit 1];
	    	List<AccountAcount__c> acountAcountLst = [select id,Field53__c,AccountName__c,ContactName__c,AccountReceiptName__c,BillingCal__c,AccountProviso__c from AccountAcount__c where Relreserve__c = :leadId And Field39__c = :CommConst.ACC_TRADE_NORMAL order by LastModifiedDate desc limit 1];
			// 2019/07/17 VOIDされた会計データは取得対象外対応 WSQ BEGIN
			// 2017/05/12 部屋詳細情報画面レジカード機能対応 zyz BEGIN
			List<Yadochou__c> yadoQueryStr=[select Id,Field1__c from Yadochou__c where Field1__r.id = :leadId ];
			// 2017/05/12 部屋詳細情報画面レジカード機能対応 zyz END
			// 予約データのSubIndex設定データが存在する場合、該当データの情報を取得する
			PopupWinInfo roomInfoDetail = new PopupWinInfo();
			// 2017/05/12 部屋詳細情報画面レジカード機能対応 zyz BEGIN
			if(!yadoQueryStr.isEmpty()){
				roomInfoDetail.yadoId = yadoQueryStr[0].Id;
			}
			// 2017/05/12 部屋詳細情報画面レジカード機能対応 zyz END
			// 予約番号
			roomInfoDetail.leadIndexNo = leadDetail.LeadIndexRef__r.Name;
			roomInfoDetail.leadIndexId = leadDetail.LeadIndexRef__c;
			// 予約名
			roomInfoDetail.leadId = leadDetail.Id;
			roomInfoDetail.leadName = leadDetail.Name;
			// お客様
			roomInfoDetail.customId = leadDetail.Relcontact__c;
			if (leadDetail.Relcontact__c != null) roomInfoDetail.customName = leadDetail.Relcontact__r.Name;
			// 2019/12/30 名前か電話番号のどちらかだけ一致するお客様がすでに存在する BY zyz BEGIN
			// 当前笔数据的店铺code获取
			String present_shopcode = CommUtils.isBlank(leadDetail.rroom__r.shopinforef__r.shopcode__c) ? CommUtils.nullToBlank(leadDetail.reftypeofrooms__r.shopinforef__r.shopcode__c) : CommUtils.nullToBlank(leadDetail.rroom__r.shopinforef__r.shopcode__c);
			// 获取重复的数据
			if (leadDetail.Relcontact__c != null) roomInfoDetail.conLst = getContactLst(leadDetail.Relcontact__r.Name,leadDetail.Relcontact__r.Phone,leadDetail.Relcontact__c,present_shopcode);
			// 2019/12/30 名前か電話番号のどちらかだけ一致するお客様がすでに存在する BY zyz END
			// お客様ステータス
			roomInfoDetail.customStatus = CommUtils.nullToBlank(leadDetail.Field298__c);
			/*
			if (!subLeadIdxLst.isEmpty()) {
                // 到着日
                roomInfoDetail.entryDate =  subLeadIdxLst[0].EntryDate__c;
                // 到着時刻
                roomInfoDetail.entryTime = subLeadIdxLst[0].EntryTime__c;
                // 出発日
                roomInfoDetail.departureDate = subLeadIdxLst[0].DepartureDate__c;
                // 出発時刻
                roomInfoDetail.departureTime = subLeadIdxLst[0].DepartureTime__c;
			} else if (leadDetail.LeadIndexRef__c != null) {
				// 到着日
				roomInfoDetail.entryDate =  leadDetail.LeadIndexRef__r.EntryDate__c;
				// 到着時刻
				roomInfoDetail.entryTime = leadDetail.LeadIndexRef__r.EntryTime__c;
				// 出発日
				roomInfoDetail.departureDate = leadDetail.LeadIndexRef__r.DepartureDate__c;
				// 出発時刻
				roomInfoDetail.departureTime = leadDetail.LeadIndexRef__r.DepartureTime__c;
			}*/
            // 到着日
            roomInfoDetail.entryDate =  leads[0].EntryTime__c.format(g_DateFormat);
            // 到着時刻
            roomInfoDetail.entryTime = leads[0].Field4__c;
            // 出発日
            roomInfoDetail.departureDate = leads[leads.size()-1].Departure__c.format(g_DateFormat);
            // 出発時刻
            roomInfoDetail.departureTime = leads[leads.size()-1].Field3__c;
			// 泊数
			roomInfoDetail.nights = leads[0].EntryTime__c.date().daysBetween(leads[leads.size()-1].Departure__c.date());
			
			// チェックインありフラグ設定
			roomInfoDetail.checkInFlg = false;
			for (Lead__c lead : leads) {
				if (CommUtils.nullToBlank(lead.Field298__c) == CommConst.LEAD_GUEST_ST_CI ||
					CommUtils.nullToBlank(lead.Field298__c) == CommConst.LEAD_GUEST_ST_OUT ||
					CommUtils.nullToBlank(lead.Field298__c) == CommConst.LEAD_GUEST_ST_BATH) {
					roomInfoDetail.checkInFlg = true;
					break;
				}
			}
			// 予約人数
			roomInfoDetail.leadPeopleNum = leadDetail.StayPersons__c;
			// 予約チャネル
			roomInfoDetail.leadChannel = leadDetail.Field2__c;
			// プラン
			roomInfoDetail.leadPlan = leadDetail.Field310__r.Name;
			// 部屋
			roomInfoDetail.leadRoom = leadDetail.Rroom__r.Name;
			roomInfoDetail.leadRoomId = leadDetail.Rroom__c;
			// 特記事項
			roomInfoDetail.leadMemo = leadDetail.Comment3__c;
			// 部屋ＢＬＯＣＫ
			roomInfoDetail.isBlocked = leadDetail.Field276__c;
			//roomInfoDetail.setLeadInfo(leadDetail);
			if (!acountAcountLst.isEmpty()) {
				roomInfoDetail.accountId = acountAcountLst[0].Id;
				// 2013/10/28 会計済制御内容を追加する（POPUP画面に「印刷」ボタン追加ため）
				// Blankの場合、未会計の状態、「印刷」ボタンを非表示する
				roomInfoDetail.isAccountedFlg = CommUtils.isBlank(acountAcountLst[0].Field53__c) ? false : true;
				if (roomInfoDetail.isAccountedFlg) {
					roomInfoDetail.openAccPdfUrl = '/apex/AccountPdfSwitch?id=' + roomInfoDetail.accountId;
					// 会計書宛名
					String param1 = CommUtils.isBlank(acountAcountLst[0].AccountName__c) ?
                                    CommUtils.nullToBlank(acountAcountLst[0].ContactName__c) : acountAcountLst[0].AccountName__c;
					// 請求書宛名
					String param2 = CommUtils.isBlank(acountAcountLst[0].AccountReceiptName__c) ?
                                    CommUtils.nullToBlank(acountAcountLst[0].BillingCal__c) : acountAcountLst[0].AccountReceiptName__c;
					// 領収書但し
					String param3 = CommUtils.nullToBlank(acountAcountLst[0].AccountProviso__c);
					roomInfoDetail.openAccPdfUrl += '&cuName=' + param1 + '&language=jp&recpName=' + param2 +
													'&accountProviso=' + param3;
					// 2017/09/06 直接印刷するとき、泊数情報を再設定しないように改善対応 BEGIN
					roomInfoDetail.openAccPdfUrl += '&prm=1';
					// 2017/09/06 直接印刷するとき、泊数情報を再設定しないように改善対応 END
				}
			}
			// XML___wgch 2016/11/16 BEGIN		
			roomInfoDetail.leadObj = leadDetail;
			// 2017/01/25 新規画面の項目自定義機能 by zy BEGIN
			String contactId = leads[0].Relcontact__c;
			roomInfoDetail.contactObj = queryContact(contactFields,contactId);
			/*
			set<string> contactFieldsSet = new set<string>();
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
		    		}
				}
				//2016/11/29 tolabel error fix by zy END
				contactQueryFields+= key + ',';
			}
			contactQueryFields = contactQueryFields.removeEnd(',');
			
			String contactQuery = 'Select ' + contactQueryFields + ' From Contact';
			String contactId = leads[0].Relcontact__c;
			contactQuery += ' where id=:contactId';
			List<Contact> contactLst = Database.query(contactQuery);
			if(!contactLst.isEmpty())
			roomInfoDetail.contactObj = contactLst[0];	
			*/
			// 2017/01/25 新規画面の項目自定義機能 by zy END
			// XML___wgch 2016/11/16 END		
			return roomInfoDetail;
    	}else {
    		//return null;
    		if (!CommUtils.isBlank(roomId)) {
    			Room__c  room = [select id, Name from Room__c where id = :roomId];
    			PopupWinInfo roomInfoDetail = new PopupWinInfo();
    			roomInfoDetail.leadRoom = room.Name;
    			roomInfoDetail.leadRoomId = room.Id;
    			return roomInfoDetail;
    		} else {
    			return null;
    		}
    	}
    }
    // **********************
    // Room Change可能の部屋リストを取得する
    // 2013/06/23から、下記Methodも使わない
    // **********************
    @remoteAction
    global static SObject[] getChangeRoom(String leadId, String filter) {
    	List<Room__c> roomLst = new List<Room__c>();
    	// 選択可能の部屋を選択する
    	List<Lead__c> leadLst = [select LeadIndexSubId__c,refTypeOfRooms__c,RecordTypeId, Rroom__c,EntryTime__c from Lead__c where id = :leadId And LeadIndexSubId__c != null And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG];
    	if (leadLst.isEmpty()) return roomLst;
    	// Sub-LeadIndex情報の開始日と終了日を取得して、期間合わせる部屋情報を取得する
    	List<LeadIndex__c> subLeadIdxLst = [select RoomTypeRef__c, EntryDate__c, DepartureDate__c from LeadIndex__c where id = :leadLst[0].LeadIndexSubId__c];
    	if (subLeadIdxLst.isEmpty()) return roomLst;
    	// 到着日から、出発日まで間の部屋チェックを行う
		//Date startDt = selectDate.Checkinday__c;
		Date startDt = leadLst[0].EntryTime__c.date();
		Date endDt = subLeadIdxLst[0].DepartureDate__c;
		Id roomTypeId = subLeadIdxLst[0].RoomTypeRef__c;
		//Id bookingRecTypeId = leadLst[0].RecordTypeId;
		List<Id> recTypeLst = getLeadBookingRecTypeLst();
        // 予約データは期間と部屋タイプにて、部屋在庫データを検索して、アサインできる部屋をチェックする

        // 該当部屋タイプに含めの部屋一覧を取得する
        Set<Id> roomIdSet = new Set<Id>();
        // 既に予約データに入る場合、該当部屋は選択対象外になる
        for (AggregateResult lead :  [select Rroom__c roomId from Lead__c
        	where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG And RecordTypeId in :recTypeLst
                And DAY_ONLY(convertTimezone(EntryTime__c)) >= :startDt
                And DAY_ONLY(convertTimezone(EntryTime__c)) < :endDt
                And refTypeOfRooms__c = :roomTypeId And Rroom__c != null
                Group By Rroom__c]) {
        	roomIdSet.add((Id)lead.get('roomId'));
        }
        // 障害部屋TODO
        //List<Room__c> roomLst = new List<Room__c>();
        String queryStr = 'select Id, Name from Room__c where TypeRoomRef__c = :roomTypeId And Id not in :roomIdSet ';
        if (!CommUtils.isBlank(filter)) queryStr += ' And Name like \'%' + String.escapeSingleQuotes(filter) + '%\'';
        queryStr += ' Order By Seq__c';
//System.debug('queryStr::::' + queryStr);
        //Integer maxRoomLst = 20;
        for (Room__c rm  : DataBase.query(queryStr)) {
        	roomLst.add(rm);
        }
    	return roomLst;
    }
	private String changeLeadName(String orgLeadName , boolean isFirst, Integer newNights, Integer leadIndex){
			String newLeadName = '';
			//String orgLeadName = leads[0].Name;
				// 予約名切替用キー
			//泊目
			String repRegExpKey1 = LEAD_NAME_PREFIX + '([0-9]+-[0-9]+'+ Label.CONST_008_0110 +')';
			//泊目
			String repRegExpKey2 = '([0-9]+-[0-9]+'+ Label.CONST_008_0110 +')';
			String repRegKey = String.valueOf(DateTime.now().getTime())+Crypto.getRandomLong();

			// 元予約データ名は：999-999泊目+予約名　方式　OR　代表部屋標識+999-999泊目+予約名
			// 上記方式の場合、直接Replace方式で名前再設定を行う
			// 元予約名は 代表部屋標識+予約名の場合、999-999泊目に入り替えする, 予約名の場合、直接 999-999泊目方式に設定する
			String regexpResult1 = orgLeadName.replaceFirst(repRegExpKey1, repRegKey);
			String regexpResult2 = orgLeadName.replaceFirst(repRegExpKey2, repRegKey);
			
			// 泊目書式場合
			if (regexpResult1 != orgLeadName || regexpResult2 != orgLeadName) {
				
				if (isFirst) {
					newLeadName = orgLeadName.replaceFirst(repRegExpKey2, '');
					//System.debug('newLeadName1------' + newLeadName);
				}else{
					//泊目
					String newName = newNights + '-' + (leadIndex+1) + Label.CONST_008_0110 +' ';
					newLeadName = orgLeadName.replaceFirst(repRegExpKey2, newName);
					//System.debug('newLeadName2------' + newLeadName);
				}
			}else if (orgLeadName.startsWith(LEAD_NAME_PREFIX)) {
				// 予約名を設定する
				if (newNights > 1) {
					//泊目
					String newName = LEAD_NAME_PREFIX + newNights + '-' + (leadIndex+1) + Label.CONST_008_0110 + ' ';
					newLeadName = orgLeadName.replaceFirst(LEAD_NAME_PREFIX, newName);
					//System.debug('newLeadName3------' + newLeadName);
				}else{
					newLeadName = orgLeadName;
				}
			}else{
				newLeadName = orgLeadName;
			}
			return newLeadName;
	}
	/**
	* 部屋割り当て事前チェック
	* fromRoomId:  移動元の部屋ID
	* fromLeadId:  移動元の予約ID
	* toRoomId  :  移動先の部屋ID
	* toLeadId  :  移動先の予約ID
	* queryDt   :  移動開始日
	* fromLeadList : 移動元の予約IDリスト
	* toLeadList:  移動先の予約IDリスト
	* showToday :  当日(TRUE:検索日付は指定日と同じ日付　FALSE:検索日付は指定日の前日付)
	**/
	@remoteAction
	global static MsgItem preUpdateMemoryRoomLeadMap(String fromRoomId, String fromLeadId, String toRoomId, String toLeadId, String queryDt, List<Lead__c> fromLeadList, List<Lead__c> toLeadList, Boolean showToday) {
		String strChkMsg = '';
		MsgItem msg = new MsgItem();
		// 指定日により、
		//Date todayDt = (String.isEmpty(queryDt)) ? Date.today() : Date.parse(queryDt);
		Date todayDt = (String.isEmpty(queryDt)) ? Date.today() : CommUtils.stringToDate(queryDt);
		Date searchDt = getProcessDate(todayDt, showToday);
//System.debug('queryDt:::' + queryDt);
		List<Id> recTypeLst = getLeadBookingRecTypeLst();
		// 予約に部屋アサインを行う
		// 選択した予約関連の予約データはLeadIndexSubの関連一括予約を一括アサインする
		// リードを検索して、該当リードに部屋アサインを行う
		/*
		// 遷移元の予約関連情報取得
		Lead__c keyLead = [select Rroom__c, refTypeOfRooms__c, LeadIndexSubId__c, RoomGroupNo__c from lead__c where id = :fromLeadId];
		// 部屋アサイン対象期間予約リストを取得する
		List<Lead__c> updList = [select Rroom__c,refTypeOfRooms__c,EntryTime__c from Lead__c 
									where LeadIndexSubId__c = :keyLead.LeadIndexSubId__c 
									And RoomGroupNo__c = :keyLead.RoomGroupNo__c
									And DAY_ONLY(convertTimezone(EntryTime__c)) >= :searchDt Order By EntryTime__c asc ];
		*/
		// 移動元側予約データに部屋BLOCKのデータ有り・なしチェックを行う
		List<Lead__c> updList = (fromLeadList == null ? getOrgMoveLeadInfo(fromLeadId, searchDt) : fromLeadList);
		// 既にＢＬＯＣＫされるの予約データに対して、部屋変更ができません
		for (Lead__c fromLead : updList) {
			if (fromLead.Field276__c) {
				//部屋[XXXXXX]は既にブロッキングされているため、ご確認してください。日付：
				//msg.errMsg += '部屋['+CommUtils.nullToBlank(fromLead.Rroom__r.Name)+']は既にブロッキングされているため、ご確認してください。日付：['+fromLead.EntryTime__c.format('yyyy/MM/dd')+']\n';
				msg.errMsg += Label.MSG_008_0111.replace('XXXXXX',CommUtils.nullToBlank(fromLead.Rroom__r.Name)) + '['+ fromLead.EntryTime__c.format(g_DateFormat)+']\n';
			}
		}
		// アサインする予約データのID情報を格納する
		Set<Id> fromLeadIdSet = new Set<Id>();
		for (Lead__c l : updList) { fromLeadIdSet.add(l.Id); }
		// 遷移元の予約データの予約期間日付を設定する
		Date beginDate = updList[0].EntryTime__c.date();
		Date endDate = updList[updList.size() -1].EntryTime__c.date();
			
		// 遷移先の既存関連情報取得
		Lead__c toKeyLead = null;
		List<Lead__c> toUpdList = null;
		Date toBeginDate = null;
		Date toEndDate = null;
		// 遷移先側既に予約データが存在する場合、自動予約設定交換を行う
		// 遷移先側予約データに部屋BLOCKのデータ有り・なしチェックを行う
		if (!CommUtils.isBlank(toLeadId)) {
			// 遷移先の予約データ存在場合
			/*
			toKeyLead = [select Rroom__c, refTypeOfRooms__c, LeadIndexSubId__c, RoomGroupNo__c from lead__c where id = :moveToLeadId];
			toUpdList = [select Rroom__c,refTypeOfRooms__c,EntryTime__c from Lead__c 
										where LeadIndexSubId__c = :toKeyLead.LeadIndexSubId__c 
										And RoomGroupNo__c = :toKeyLead.RoomGroupNo__c
										And DAY_ONLY(convertTimezone(EntryTime__c)) >= :searchDt Order By EntryTime__c asc ];*/
			toUpdList = (toLeadList == null ? getOrgMoveLeadInfo(toLeadId, searchDt) : toLeadList);
		//2017/03/13 ルームインジケーターにて、すでに宿泊予約で部屋変更不可の予約が入っている部屋に、アサインができるように改善対応 by zy BEGIN
		if (!CommUtils.isBlank(fromRoomId)) {
		//2017/03/13 ルームインジケーターにて、すでに宿泊予約で部屋変更不可の予約が入っている部屋に、アサインができるように改善対応 by zy END
			// 既にＢＬＯＣＫされるの予約データに対して、部屋変更ができません
			for (Lead__c toLead : toUpdList) {
				if (toLead.Field276__c) {
					//部屋[XXXXXX]は既にブロッキングされているため、ご確認してください。日付：
					//msg.errMsg += '部屋['+CommUtils.nullToBlank(toLead.Rroom__r.Name)+']は既にブロッキングされているため、ご確認してください。日付：['+toLead.EntryTime__c.format('yyyy/MM/dd')+']\n';
					msg.errMsg += Label.MSG_008_0111.replace('XXXXXX',CommUtils.nullToBlank(toLead.Rroom__r.Name)) + '['+ toLead.EntryTime__c.format(g_DateFormat)+']\n';
				}
			}
		//2017/03/13 ルームインジケーターにて、すでに宿泊予約で部屋変更不可の予約が入っている部屋に、アサインができるように改善対応 by zy BEGIN
		}
		//2017/03/13 ルームインジケーターにて、すでに宿泊予約で部屋変更不可の予約が入っている部屋に、アサインができるように改善対応 by zy END
			toBeginDate = toUpdList[0].EntryTime__c.date();
			toEndDate = toUpdList[toUpdList.size() -1].EntryTime__c.date();
		}
		Set<Id> toLeadIdSet = new Set<Id>();
		if (toUpdList != null) {
			for (Lead__c l : toUpdList) { toLeadIdSet.add(l.id); }
		}
		
		// 該当部屋はすでに予約されているがどうか、チェックを行う
		// アサインする部屋はすでに予約にアサインされているがどうか、チェックを行う
		// 2018/02/06 予約検索条件はレコードタイプ外す改善対応 BEGIN
		/*
		List<Lead__c> existLeadLst = [
			Select Id,Name,Rroom__r.Name,EntryTime__c,Field276__c From Lead__c
			Where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 		// 有効な予約データ
				And RecordTypeId in :recTypeLst							// 基本、宿泊のレコードタイプ予約データ
                And DAY_ONLY(convertTimezone(EntryTime__c)) >= :beginDate		// 到着日は指定日と一致する
                And DAY_ONLY(convertTimezone(EntryTime__c)) <= :endDate
                And Rroom__c = :toRoomId								// 部屋設定場合
                And Id not in :toLeadIdSet
			Order By EntryTime__c];
			*/
		Integer cancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
        String existLeadQuery = 'Select Id,Name,Rroom__r.Name,EntryTime__c,Field276__c From Lead__c '
                            + 'Where CancelBool__c != :cancelFlg '
                            + 'And DAY_ONLY(convertTimezone(EntryTime__c)) >= :beginDate '
                            + 'And DAY_ONLY(convertTimezone(EntryTime__c)) <= :endDate '
                            + 'And Rroom__c = :toRoomId '
                            + 'And Id not in :toLeadIdSet ';
        if (leadQueryRecTypeFlg == false ) {
            existLeadQuery += 'And RecordTypeId in :recTypeLst ';
        }
        existLeadQuery += ' Order By EntryTime__c';
        List<Lead__c> existLeadLst = DataBase.query(existLeadQuery);
//System.debug(loggingLevel.info, '======= STEP2 =========');
	    // 2018/02/06 予約検索条件はレコードタイプ外す改善対応 END
		// 存在すると、エラーに戻る
		if (!existLeadLst.isEmpty()) {
			//ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARING, '該当部屋はすでに別の予約アサインされているため、ご確認してください。¥n'));
//			strChkMsg += '部屋['+existLeadLst[0].Rroom__r.Name+']はすでに別の予約アサインされているため、ご確認してください。</br>';
			//部屋[XXXXXX]はすでに別の予約アサインされているため、ご確認してください。
			//msg.infMsg += '部屋['+existLeadLst[0].Rroom__r.Name+']はすでに別の予約アサインされているため、ご確認してください。\n';
			msg.infMsg += Label.MSG_008_0113.replace('XXXXXX',existLeadLst[0].Rroom__r.Name) +'\n';
			for (Lead__c extLead : existLeadLst) {
				//2017/03/13 ルームインジケーターにて、すでに宿泊予約で部屋変更不可の予約が入っている部屋に、アサインができるように改善対応 by zy BEGIN
				/*
				if (extLead.Field276__c) {
					//部屋[XXXXXX]は既にブロッキングされているため、ご確認してください。日付：
					//msg.errMsg += '部屋['+extLead.Rroom__r.Name+']は既にブロッキングされているため、ご確認してください。日付：['+extLead.EntryTime__c.format('yyyy/MM/dd')+']\n';
					msg.errMsg += Label.MSG_008_0111.replace('XXXXXX',extLead.Rroom__r.Name) + '['+ extLead.EntryTime__c.format(g_DateFormat)+']\n';
				}
				*/
				//2017/03/13 ルームインジケーターにて、すでに宿泊予約で部屋変更不可の予約が入っている部屋に、アサインができるように改善対応 by zy END
//				strChkMsg += '<a href="/'+extLead.Id+'" target="_blank"><span style="font-weight: bold; color: blue;">' + extLead.Name + ' ['+extLead.EntryTime__c.format('yyyy/MM/dd')+']</span></a></br>';
				msg.infMsg += extLead.Name + ' ['+extLead.EntryTime__c.format(g_DateFormat)+']\n';
			}
		}
		// 遷移先予約情報も存在する場合
        if (!toLeadIdSet.isEmpty() && !CommUtils.isBlank(fromRoomId)) {
            // 2018/02/06 予約検索条件はレコードタイプ外す改善対応 BEGIN
            /*
			List<Lead__c> existLeadLst2 = [
				Select Id,Name,Rroom__r.Name,EntryTime__c,Field276__c From Lead__c
				Where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 		// 有効な予約データ
					And RecordTypeId in :recTypeLst							// 基本、宿泊のレコードタイプ予約データ
	                And DAY_ONLY(convertTimezone(EntryTime__c)) >= :toBeginDate		// 到着日は指定日と一致する
	                And DAY_ONLY(convertTimezone(EntryTime__c)) <= :toEndDate
	                And Rroom__c = :fromRoomId								// 部屋設定場合
	                And Id not in :fromLeadIdSet
				Order By EntryTime__c];
			*/
	        String existLeadQuery2 = 'Select Id,Name,Rroom__r.Name,EntryTime__c,Field276__c From Lead__c '
	                            + 'Where CancelBool__c != :cancelFlg '
	                            + 'And DAY_ONLY(convertTimezone(EntryTime__c)) >= :toBeginDate '
	                            + 'And DAY_ONLY(convertTimezone(EntryTime__c)) <= :toEndDate '
	                            + 'And Rroom__c = :fromRoomId '
	                            + 'And Id not in :fromLeadIdSet ';
	        if (leadQueryRecTypeFlg == false ) {
	            existLeadQuery += 'And RecordTypeId in :recTypeLst ';
	        }
	        existLeadQuery += ' Order By EntryTime__c';
	        List<Lead__c> existLeadLst2 = DataBase.query(existLeadQuery2);
//System.debug(loggingLevel.info, '======= STEP3 =========');
			// 2018/02/06 予約検索条件はレコードタイプ外す改善対応 END
			// 存在すると、エラーに戻る
			if (!existLeadLst2.isEmpty()) {
				//ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARING, '該当部屋はすでに別の予約アサインされているため、ご確認してください。¥n'));
//				strChkMsg += '部屋['+existLeadLst2[0].Rroom__r.Name+']はすでに別の予約アサインされているため、ご確認してください。</br>';
				//部屋[XXXXXX]はすでに別の予約アサインされているため、ご確認してください。
				//msg.infMsg += '部屋['+existLeadLst2[0].Rroom__r.Name+']はすでに別の予約アサインされているため、ご確認してください。\n';
				msg.infMsg += Label.MSG_008_0113.replace('XXXXXX',existLeadLst2[0].Rroom__r.Name) +'\n';
				for (Lead__c extLead : existLeadLst2) {
					//2017/03/13 ルームインジケーターにて、すでに宿泊予約で部屋変更不可の予約が入っている部屋に、アサインができるように改善対応 by zy BEGIN
					/*
					if (extLead.Field276__c) {
						//部屋[XXXXXX]は既にブロッキングされているため、ご確認してください。日付：
						//msg.errMsg += '部屋['+extLead.Rroom__r.Name+']は既にブロッキングされているため、ご確認してください。日付：['+extLead.EntryTime__c.format('yyyy/MM/dd')+']\n';
						msg.errMsg += Label.MSG_008_0111.replace('XXXXXX',extLead.Rroom__r.Name) +'['+extLead.EntryTime__c.format(g_DateFormat)+']\n';
					}
					*/
					//2017/03/13 ルームインジケーターにて、すでに宿泊予約で部屋変更不可の予約が入っている部屋に、アサインができるように改善対応 by zy END
//					strChkMsg += '<a href="/'+extLead.Id+'" target="_blank"><span style="font-weight: bold; color: blue;">' + extLead.Name + ' ['+extLead.EntryTime__c.format('yyyy/MM/dd')+']</span></a></br>';
					msg.infMsg += extLead.Name + ' ['+extLead.EntryTime__c.format(g_DateFormat)+']\n';
				}
			}
		}
		//return strChkMsg;
		return msg;
	}
	/**
	* 割り当て予約関連の予約データを取得する
	* 	①部屋未割り当てる予約取得する
	*	②部屋割り当てする場合、アサインする予定の期間に、予約データ存在チェック用予約取得する
	*   ③部屋割り当てする場合、該当移動する予約に関連の予約一覧を取得する
	**/
	private static List<Lead__c> getOrgMoveLeadInfo(String leadId, Date searchDt) {
		// 遷移元の予約関連情報取得
		Lead__c keyLead = [select Rroom__c, refTypeOfRooms__c, LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c from lead__c where id = :leadId];
		// 部屋アサイン対象期間予約リストを取得する
		List<Lead__c> updList = [select Rroom__c,refTypeOfRooms__c,refTypeOfRooms__r.Name,Rroom__r.Name,
										StayPersons__c, Relcontact__r.Name, Relcontact__r.Name1__c,Field276__c,
                                        EntryTime__c, Field4__c, Field3__c,
                                        Field298__c,LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c
                                        // 2016/02/17 ルームインジケータは部屋SWAPする場合、2wayの在庫調整を発行しない機能対応を行う BEGIN
                                        , StockAdjustTargetFlg__c
                                        // 2016/02/17 ルームインジケータは部屋SWAPする場合、2wayの在庫調整を発行しない機能対応を行う END
										// 2019/08/31 42.ご予約チェックアウト後の「未清掃」ステータスの付与処理をお部屋によってON/OFFができるようにしたい by zy BEGIN 
										, Rroom__r.RoomNotCreateFlg__c
										// 2019/08/31 42.ご予約チェックアウト後の「未清掃」ステータスの付与処理をお部屋によってON/OFFができるようにしたい by zy END
									from Lead__c 
									where LeadIndexSubId__c = :keyLead.LeadIndexSubId__c 
									And LeadIndexRef__c = :keyLead.LeadIndexRef__c
									And RoomGroupNo__c = :keyLead.RoomGroupNo__c
									//And Rroom__c = null
									And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 		// 有効な予約データ
									And DAY_ONLY(convertTimezone(EntryTime__c)) >= :searchDt Order By EntryTime__c asc ];
		return updList;
	}


	/**
	* グループ単位で一括部屋アサイン処理を行う
	* Parameter: fromLeadIndexId [予約インデクスID]
	*            startRoomId[指定した開始部屋]
	*			 queryDt[処理日]
	*			 noCleanRoomIds 未清掃部屋リスト
	*            nocleanOkRoomIds
	*			 nocleanNgRoomIds
	**/
	@remoteAction
	global static AutoAssignRoomResult autoAssignRoomToLead(String[] fromLeadIds, String startRoomId, String queryDt, 
															String[] noCleanRoomIds, String nocleanOkRoomIds, String nocleanNgRoomIds, Boolean showToday) {
		// 処理結果格納する
		AutoAssignRoomResult res = new AutoAssignRoomResult();
		// 指定日により、
		//Date todayDt = (String.isEmpty(queryDt)) ? Date.today() : Date.parse(queryDt);
		Date todayDt = (String.isEmpty(queryDt)) ? Date.today() : CommUtils.stringToDate(queryDt);
		Date searchDt = getProcessDate(todayDt, showToday);
//System.debug(loggingLevel.Info, 'queryDt:::' + queryDt);
		//List<Id> recTypeLst = getLeadBookingRecTypeLst();
		// 未清掃部屋リストを格納する
		Set<Id> noCleanRoomIdsSet = new Set<Id>();
		for (String roomId : noCleanRoomIds) {noCleanRoomIdsSet.add(roomId);}
		// 未清掃部屋は割り当てする、SKIP制御情報を設定する
		Set<Id> excludeRoomIds = new Set<Id>();
		Set<Id> includeRoomIds = new Set<Id>();
		if (!CommUtils.isBlank(nocleanOkRoomIds)) {
			for (String roomId : nocleanOkRoomIds.split(',')) {
				if(!CommUtils.isBlank(roomId)) includeRoomIds.add(roomId);
			}
		}
		if (!CommUtils.isBlank(nocleanNgRoomIds)) {
			for (String roomId : nocleanNgRoomIds.split(',')) {
				if(!CommUtils.isBlank(roomId)) excludeRoomIds.add(roomId);
			}
		}
//System.debug(loggingLevel.Info, 'noCleanRoomIdsSet:::' + noCleanRoomIdsSet);	
//System.debug(loggingLevel.Info, 'includeRoomIds:::' + includeRoomIds);	
//System.debug(loggingLevel.Info, 'excludeRoomIds:::' + excludeRoomIds);	
		// 予約に部屋アサインを行う
		// 選択した予約関連の予約データはLeadIndexSubの関連一括予約を一括アサインする
		// リードを検索して、該当リードに部屋アサインを行う
		// 遷移元の予約関連情報取得
		List<Lead__c> updList = getOrgMoveLeadInfo(fromLeadIds[0], searchDt);
		// アサインする予約データのID情報を格納する
		Set<Id> fromLeadIdSet = new Set<Id>();
		for (Lead__c l : updList) { fromLeadIdSet.add(l.Id); }
		// 遷移元の予約データの予約期間日付を設定する
		Date beginDate = updList[0].EntryTime__c.date();
		Date endDate = updList[updList.size() -1].EntryTime__c.date();
		
		
		// 使用可能の部屋を取得する
		Room__c canUseRoom = getCanAssignRoom(startRoomId, updList[0].refTypeOfRooms__c ,beginDate, endDate, excludeRoomIds);
		if (canUseRoom != null) {
			// 割り当てする部屋IDを格納する
			res.currRoomId = canUseRoom.Id;
			// 未清掃OK部屋IDは選択可能の部屋は違う場合、未清掃チェックを行う
			// 未清掃部屋の場合、警告情報を設定する
			if (!includeRoomIds.contains(canUseRoom.Id) && noCleanRoomIdsSet.contains(canUseRoom.Id)) {
				//部屋[XXXXXX]が未清掃、宜しいでしょう
				//res.message = '部屋['+canUseRoom.Name+']が未清掃、宜しいでしょう';
				res.message = Label.MSG_008_0114.replace('XXXXXX',canUseRoom.Name);
				res.nextLeadIds.addAll(fromLeadIds);
				return res;	
			}
			
			// 設定可能の部屋が見つかる場合
			for (Lead__c updLead : updList) {
				updLead.Rroom__c = canUseRoom.Id;
				// 部屋タイプをNULLに設定すると、該当部屋の部屋タイプはトリガーで自動設定
				updLead.refTypeOfRooms__c = null;
			}
			update updList;
			
			// 宿泊名簿自動作成
			Lead__c lead = updList[updList.size()-1];
			List<BookingGuest__c> updGuestList = [select RoomRef__c from BookingGuest__c where IndexSubRef__c = :lead.LeadIndexSubId__c and RoomGroupNo__c = :lead.RoomGroupNo__c];
			for (BookingGuest__c bookGuest : updGuestList) {
				bookGuest.RoomRef__c = canUseRoom.Id;
			}
			// 未設定する場合、新規宿泊名簿作成、一括予約へ連動する
			if (updGuestList.isEmpty()) {
				// TODO
				createBookingGuest(lead);
			} else {
				update updGuestList;
			}
		}
		if (fromLeadIds.size() == 1) {
			// 処理済みの場合
		} else {
			for (Integer i = 1; i < fromLeadIds.size(); i++) {
				res.nextLeadIds.add(fromLeadIds[i]);
			}
		}
		return res;

	}
	// 部屋アサインの取消機能対応(NO370)
    @remoteAction
    global static AutoAssignRoomResult autoCancelAssignRoomToLead(String[] fromLeadIds, String queryDt, Boolean showToday) {
        
        AutoAssignRoomResult res = new AutoAssignRoomResult();
		// 検索の日付情報を取得する
		//Date todayDt = (String.isEmpty(queryDt)) ? Date.today() : Date.parse(queryDt);
		Date todayDt = (String.isEmpty(queryDt)) ? Date.today() : CommUtils.stringToDate(queryDt);
		Date searchDt = getProcessDate(todayDt, showToday);
		// 指定の予約データから関連の予約データの部屋取り消し
		List<Lead__c> updList = getOrgMoveLeadInfo(fromLeadIds[0], searchDt);
        for (Lead__c dex:updList ) {
            dex.Rroom__c = null;           
        }
  		// DB操作を行う
  		Savepoint sp = Database.setSavepoint();
  		try{
        // 予約更新データは存在する場合、更新処理を行う
        if (!updList.isEmpty()) update updList;
  		}catch (Exception e){
            Database.rollback(sp);
           	// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 BEGIN
			String errMsg = CommUtils.getFieldValidationMessage(e.getMessage());
			throw new CommException(errMsg);
			// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 END
  		} 
        // 処理結果を確認する
		if (fromLeadIds.size() > 1) {
			// 次の処理を予備する
			Set<String> dupFilterSet = new Set<String>();
			for (Integer i = 1; i < fromLeadIds.size(); i++) {
				if (!dupFilterSet.contains(fromLeadIds[i])) {
					res.nextLeadIds.add(fromLeadIds[i]);
					dupFilterSet.add(fromLeadIds[i]);
				}
			}
		}
        return res;
    }
	/*
	* 該当予約に自動アサインできる部屋を取得する
	* Return: Nullの場合、使用可能の部屋がなかった場合
	**/
	private static Room__c getCanAssignRoom(String beginRoomId, Id roomTypeId, Date startDt, Date endDt, Set<Id> excludeRoomIds) {
		// 2019/10/30 ルームインジケータに「自動一括アサイン」ボタンが欲しい by zy BEGIN
		// 自動アサイン用部屋情報
		Room__c autoAssignRoom = new Room__c();
		// 自動アサインの場合、部屋ID不指定
		if (CommUtils.isBLank(beginRoomId)) {
			// 指定部屋タイプの部屋取得
			List<Room__c> rooms = [select Id, Name, AREA__c, ShopInfoRef__c, Floor__c, TypeRoomRef__c,Seq__c, DisplayNo__c from Room__c where TypeRoomRef__c = :roomTypeId limit 1];
			// 自動アサイン用部屋情報設定
			if (!rooms.isEmpty()) autoAssignRoom = rooms[0];
		}
		// 取得部屋情報指定
		Room__c beginRoom = CommUtils.isBLank(beginRoomId) ? autoAssignRoom : [select Id, Name, AREA__c, ShopInfoRef__c, Floor__c, TypeRoomRef__c,Seq__c, DisplayNo__c from Room__c where id = :beginRoomId];
		// 2019/10/30 ルームインジケータに「自動一括アサイン」ボタンが欲しい by zy END
		//Id roomTypeId = beginRoom.TypeRoomRef__c;
		String area = beginRoom.AREA__c;
		String branch = beginRoom.ShopInfoRef__c;
//		String floor = beginRoom.Floor__c;
		Decimal sortSeqNo = beginRoom.Seq__c;
		Decimal sortDisNo = beginRoom.DisplayNo__c;
		//Room__c[] rooms = [select id, name from Room__c]
        String queryWhere = ' where UseOfRoom__c = \'' + String.escapeSingleQuotes(CommConst.ROOM_UseOfType_Guest) + '\'';
        // 同じエアリ、同じ支店、同じ部屋タイプ
		// 2019/10/30 ルームインジケータに「自動一括アサイン」ボタンが欲しい by zy BEGIN
        if (!CommUtils.isBLank(beginRoomId)) queryWhere += ' And AREA__c = :area ';
		// 2019/10/30 ルームインジケータに「自動一括アサイン」ボタンが欲しい by zy END
        queryWhere+= ' And ShopInfoRef__c = :branch ';
        queryWhere+= ' And TypeRoomRef__c = :roomTypeId ';
        // 2013/10/10 未清掃の部屋は対象外の部屋IDを格納する
        if (!excludeRoomIds.isEmpty()) queryWhere+= ' And Id != :excludeRoomIds ';
        // 該当部屋のFLOOR以下の部屋自動アサイン
		// 2013/10/07 Floorは条件対象外になる
		// queryWhere+= ' And Floor__c <= :floor ';
        // 仮にHeight FloorからLow Floorに自動割り当て
		// String queryOrder = ' Order By Floor__c desc, ';
		String queryOrder = ' Order By ';
		// 2019/10/30 ルームインジケータに「自動一括アサイン」ボタンが欲しい by zy BEGIN
		if (CommUtils.isBLank(beginRoomId)){
			queryOrder += ' priority__c asc ';
		} else 
		// 2019/10/30 ルームインジケータに「自動一括アサイン」ボタンが欲しい by zy END
        if (ROOM_SORT_DIV == ROOM_SORT_NAME_DIV) {
        	queryWhere += ' And Seq__c <= :sortSeqNo ';
        	queryOrder += ' Seq__c desc ';
        } else {
        	queryWhere += ' And DisplayNo__c <= :sortDisNo ';
        	queryOrder += ' DisplayNo__c desc ';
        }
        String queryStr = QueryHeader + queryWhere + queryOrder;
// System.debug(LoggingLevel.INFO, 'queryStr:' + queryStr);		
		// 部屋リストを取得する
		List<Room__c> canUseRoomList = new List<Room__c>();
		Set<Id> existRoomIdSet = new Set<Id>();
		for (Room__c room : DataBase.query(queryStr)) {
			existRoomIdSet.add(room.Id);
			canUseRoomList.add(room);
		}
		// 上記ROOMに既に使い済みの部屋リストを取得する
        List<Id> recTypeLst = getLeadBookingRecTypeLst();
        // 故障部屋状態を取得する
        RoomStatusManager roomStatus = new RoomStatusManager();
        Set<Id> badRoomSet = roomStatus.queryBadRoomSet(startDt,endDt);
        // 有効な予約データ、一日一部屋で処理するため、重複することは処理対象外
        Set<Id> roomIdExistLeadSet = new Set<Id>();
        // 既に予約データに入る場合、該当部屋は選択対象外になる
        // 2018/02/06 予約検索条件はレコードタイプ外す改善対応 BEGIN
        /*
        for (AggregateResult lead :  [
        	select Rroom__c roomId from Lead__c
        	where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 
        		And RecordTypeId in :recTypeLst
                And DAY_ONLY(convertTimezone(EntryTime__c)) >= :startDt
                And DAY_ONLY(convertTimezone(EntryTime__c)) <= :endDt
                //And refTypeOfRooms__c = :roomTypeId 
                And Rroom__c in :existRoomIdSet
                Group By Rroom__c]) {
        	roomIdExistLeadSet.add((Id)lead.get('roomId'));
        }
        */
        Integer cancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
        String roomIdExistLeadQuery = 'select Rroom__c roomId from Lead__c '
                    + 'where CancelBool__c != :cancelFlg '
                    + 'And DAY_ONLY(convertTimezone(EntryTime__c)) >= :startDt '
                    + 'And DAY_ONLY(convertTimezone(EntryTime__c)) <= :endDt '
                    + 'And Rroom__c in :existRoomIdSet ';
        if (leadQueryRecTypeFlg == false ) {
            roomIdExistLeadQuery += 'And RecordTypeId in :recTypeLst ';
        }
        roomIdExistLeadQuery += 'Group By Rroom__c';
        List<AggregateResult> leadAvgs = DataBase.query(roomIdExistLeadQuery);
        for (AggregateResult lead : leadAvgs) {
            roomIdExistLeadSet.add((Id)lead.get('roomId'));
        }
//System.debug(loggingLevel.info, '======= STEP4 =========');
        // 2018/02/06 予約検索条件はレコードタイプ外す改善対応 END
        for (Room__c room : canUseRoomList) {
        	if (!roomIdExistLeadSet.contains(room.Id) && !badRoomSet.contains(room.Id)) return room;
        }
        // 残りの予約情報を設定
		return null;
	}
	/**
	* 部屋自動アサイン処理結果
	**/
	global class AutoAssignRoomResult {
		public AutoAssignRoomResult() {
			message = '';
			currRoomId = '';
			nextLeadIds = new List<String>();
		}
		public List<String> nextLeadIds{get;set;}
		public String message{get;set;}
		public String currRoomId{get;set;}	// 該当予約データに割り当てする部屋IDを格納する
	}

	// Map<部屋ID　/ 予約ID> [画面に未チェックインの予約は部屋IDとMatch関連情報を格納する]
	// Drop
	//private Map<Id, Id> roomLeadIdMap = new Map<Id, Id>();
	public String moveFromRoomId{get;set;}
	public String moveFromLeadId{get;set;}
	public String moveToRoomId{get;set;}
	public String moveToLeadId{get;set;}
	// ********************************
	// 予約データの部屋割り当てる処理
	// 部屋交換・予約データの部屋割り当て機能対応
	// Drop -> Room -> Assign
	// ********************************
	public void updateMemoryRoomLeadMap() {
System.debug('moveFromRoomId:::' + moveFromRoomId);
System.debug('moveFromLeadId:::' + moveFromLeadId);
System.debug('moveToRoomId:::' + moveToRoomId);
System.debug('moveToLeadId:::' + moveToLeadId);
		/*
		// 移動部屋IDセット
		Set<Id> moveRoomIdSet = new Set<Id>();
		if (!CommUtils.isBlank(moveFromRoomId)) moveRoomIdSet.add(moveFromRoomId);
		if (!CommUtils.isBlank(moveToRoomId)) moveRoomIdSet.add(moveToRoomId);
		// 移動予約IDセット
		Set<Id> moveLeadIdSet = new Set<Id>();
		if (!CommUtils.isBlank(moveFromLeadId)) moveLeadIdSet.add(moveFromLeadId);
		if (!CommUtils.isBlank(moveToLeadId)) moveLeadIdSet.add(moveToLeadId);
		*/
		// 処理日を取得する
		Date searchDt = getProcessDate(processDate, isShowToday);
		
		List<Lead__c> updList = getOrgMoveLeadInfo(moveFromLeadId, searchDt);
		List<Lead__c> toUpdList = new List<Lead__c>();
        // 遷移先の部屋タイプは存在&&予約ID存在する
        if (!CommUtils.isBlank(moveToLeadId) && !CommUtils.isBlank(moveFromRoomId)) {
			toUpdList = getOrgMoveLeadInfo(moveToLeadId, searchDt);
		}
		/*
		// WARNING情報を格納する
		String strAlertMsg = preUpdateMemoryRoomLeadMap(moveFromRoomId, moveFromLeadId, moveToRoomId, moveToLeadId, searchDt.format(), updList, toUpdList);
		
		// チェック結果をチェックして、結果を画面に戻る
		//if (!String.isEmpty(strAlertMsg)) return;
		if (!String.isEmpty(strAlertMsg)) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, strAlertMsg));
		*/
// DB操作を行う
Savepoint sp = Database.setSavepoint();
try{
		if (!ApexPages.hasMessages(ApexPages.Severity.ERROR)) {
            // Drop元の予約の予約部屋にアサインする
			for (Lead__c updLead : updList) {
				updLead.Rroom__c = moveToRoomId;
				// 部屋タイプをNULLに設定すると、該当部屋の部屋タイプはトリガーで自動設定
				updLead.refTypeOfRooms__c = null;
			}
			// 関連の宿泊名簿情報に部屋設定情報を更新設定を行う
			if (!updList.isEmpty()) {
				Lead__c lead = updList[updList.size()-1];
				List<BookingGuest__c> updGuestList = [select RoomRef__c from BookingGuest__c where IndexSubRef__c = :lead.LeadIndexSubId__c and RoomGroupNo__c = :lead.RoomGroupNo__c];
				for (BookingGuest__c bookGuest : updGuestList) {
					bookGuest.RoomRef__c = moveToRoomId;
				}
				// 未設定する場合、新規宿泊名簿作成、一括予約へ連動する
				if (updGuestList.isEmpty()) {
					// TODO
					createBookingGuest(lead);
				} else {
					update updGuestList;
				}
			}
			
			for (Lead__c updLead : toUpdList) {
				updLead.Rroom__c = moveFromRoomId;
				// 部屋タイプをNULLに設定すると、該当部屋の部屋タイプはトリガーで自動設定
				updLead.refTypeOfRooms__c = null;
			}
			if (!toUpdList.isEmpty()) {
				Lead__c lead = toUpdList[toUpdList.size()-1];
				List<BookingGuest__c> updGuestList = [select RoomRef__c from BookingGuest__c where IndexSubRef__c = :lead.LeadIndexSubId__c and RoomGroupNo__c = :lead.RoomGroupNo__c];
				for (BookingGuest__c bookGuest : updGuestList) {
					bookGuest.RoomRef__c = moveFromRoomId;
				}
				// 未設定する場合、新規宿泊名簿作成、一括予約へ連動する
				if (updGuestList.isEmpty()) {
					// TODO
					createBookingGuest(lead);
				} else {
					update updGuestList;
				}
			}
			// 2016/02/17 ルームインジケータは部屋SWAPする場合、2wayの在庫調整を発行しない機能対応を行う BEGIN
			//update updList;
			if (toUpdList != null && !toUpdList.isEmpty() && !updList.isEmpty()) {
				Integer maxLen = toUpdList.size() > updList.size() ? updList.size() : toUpdList.size();
				for (Integer i = 0; i < maxLen; i++) {
					Lead__c fromLead  = updList[i];
					Lead__c toLead = toUpdList[i];
					fromLead.StockAdjustTargetFlg__c = !fromLead.StockAdjustTargetFlg__c;
					toLead.StockAdjustTargetFlg__c = !toLead.StockAdjustTargetFlg__c;
				}
			}
			//if (toUpdList != null) update toUpdList;
			if (toUpdList != null) updList.addAll(toUpdList);
			if (!updList.isEmpty()) update updList;
			// 2016/02/17 ルームインジケータは部屋SWAPする場合、2wayの在庫調整を発行しない機能対応を行う END
		}
		// 遷移の部屋IDが設定されている場合 && 関連の予約データはチェックイン済み場合
		// 移動元は部屋アサイン、移動先は空室の場合
		if (!CommUtils.isBlank(moveFromRoomId) && !CommUtils.isBlank(moveFromLeadId)) {
			// 予約データは既にチェックイン済みの場合、
			for (Lead__c updLead : updList) {
				// 予約データ既にチェックイン済みの場合、部屋移動すると、移動元の
				if (updLead.Id == moveFromLeadId && !CommUtils.isBlank(updLead.Field298__c) && updLead.Field298__c != CommConst.LEAD_GUEST_ST_CO) {
					// この部屋は清掃データ自動作成を行う
					Date tmpDate = getInputDate(0); // 指定日で掃除情報を作成する
					// 2019/08/31 42.ご予約チェックアウト後の「未清掃」ステータスの付与処理をお部屋によってON/OFFができるようにしたい by zy BEGIN 
					if ( updLead.Rroom__r.RoomNotCreateFlg__c != true) 
					// 2019/08/31 42.ご予約チェックアウト後の「未清掃」ステータスの付与処理をお部屋によってON/OFFができるようにしたい by zy END 
						(new RoomStatusManager()).createNoCleanRooms(tmpDate, new Set<Id>{moveFromRoomId});
					// 処理終了
					break;
				}
			}
		}
		// 移動予約IDセット
		if (!CommUtils.isBlank(moveToRoomId) && !CommUtils.isBlank(moveToLeadId)) {
			if (!toUpdList.isEmpty()) {
				// 予約データは既にチェックイン済みの場合、
				for (Lead__c updLead : toUpdList) {
					// 予約データ既にチェックイン済みの場合、部屋移動すると、移動元の
					if (updLead.Id == moveToLeadId && !CommUtils.isBlank(updLead.Field298__c) && updLead.Field298__c != CommConst.LEAD_GUEST_ST_CO) {
						// この部屋は清掃データ自動作成を行う
						Date tmpDate = getInputDate(0); // 指定日で掃除情報を作成する
						// 2019/08/31 42.ご予約チェックアウト後の「未清掃」ステータスの付与処理をお部屋によってON/OFFができるようにしたい by zy BEGIN 
						if ( updLead.Rroom__r.RoomNotCreateFlg__c != true) 
						// 2019/08/31 42.ご予約チェックアウト後の「未清掃」ステータスの付与処理をお部屋によってON/OFFができるようにしたい by zy END 
							(new RoomStatusManager()).createNoCleanRooms(tmpDate, new Set<Id>{moveToRoomId});
						// 処理終了
						break;
					}
				}
			}
		}
}catch (Exception e){
	// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 BEGIN
	String errMsg = e.getMessage();
	if(!CommUtils.isFieldValidationMessage(errMsg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
	bookingCreateOK = false;
	mainIsShowErr = true;
	// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 END
	Database.rollback(sp);
	// 2018/05/14 报错以后房间消失问题对应 by zy BEGIN
	// 2018/06/06 編集権限チェックできる対応 BEGIN
	//refreshPage();
	// 別の機能から呼び出しする場合、該当処理が不要
	if (!norefreshFlag) refreshPage();
	// 2018/06/06 編集権限チェックできる対応 END
	// 2018/05/14 报错以后房间消失问题对应 by zy END
	if (norefreshFlag) errorMsg = CommUtils.getFieldValidationMessage(errMsg);
	return;
}
bookingCreateOK = true;
		// 最新アサイン情報を更新を行う
		if (!norefreshFlag) gotoDate();
	}
	
	// ******************************
	// 宿泊者名簿情報を作成する
	// ******************************
	private static void createBookingGuest(Lead__c lead) {
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'contactref__c','roomref__c','roomgroupno__c','indexsubref__c','guestname__c','name','delegateflg__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.BookingGuest__c.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(chkFieldsLst, mm)) {
			return ;
		}
		// 2019/09/15 Security Check BY zyz END
		List<LeadIndex__c> existSubIdx = [select id from LeadIndex__c where id = :lead.LeadIndexSubId__c];
		if (existSubIdx.isEmpty()) return;
		List<BookingGuest__c> insBookingGuestLst = new List<BookingGuest__c>();
		for (Integer j = 0 ; j<lead.StayPersons__c;j++) {
			BookingGuest__c item = new BookingGuest__c();
	        if ( j == 0) item.DelegateFlg__c = true;
	        item.Name = lead.Relcontact__r.Name;
	        item.GuestName__c = lead.Relcontact__r.Name1__c;
	        //item.roomType = lead.refTypeOfRooms__r.Name;
	        //item.roomTypeId = lead.refTypeOfRooms__c;
	        item.IndexSubRef__c = lead.LeadIndexSubId__c;
	        item.RoomGroupNo__c = lead.RoomGroupNo__c;
	        item.RoomRef__c = lead.Rroom__c;
	      	item.ContactRef__c = lead.Relcontact__c;
	      	
	        insBookingGuestLst.add(item);
		}
		if (!insBookingGuestLst.isEmpty()) insert insBookingGuestLst;	
	}
	// ***********************************
	// 予約アサインするべき顧客リスト情報を取得する
	// 指定日により、アサインするべき顧客リストを取得する
	// 下記Methodが使わない
	// ***********************************
	@remoteAction
	global static List<NoAssignLeadInfo> noAssingLeadInfo(String queryDt, String queryRoomType) {
	/*
		// 指定日により、
		Date todayDt = (String.isEmpty(queryDt)) ? Date.today() : Date.parse(queryDt);
		Date searchDt = getProcessDate(todayDt);
System.debug('queryDt:::' + queryDt);
		// 予約データは基本、宿泊場合、
		//Id bookRecTypeId = CommLogicProcess.getLeadBookingRecType();
        //Id baseRecTypeId = CommLogicProcess.getLeadBaseRecType();
        //List<Id> recTypeLst = new List<Id>{bookRecTypeId, baseRecTypeId};
        List<Id> recTypeLst = getLeadBookingRecTypeLst();
		// 到着日は指定日と同じ、有効な予約データ、部屋番号は未設定場合、
		Integer cancelBool = CommConst.LEAD_ST_CANCEL_FLG;
		String noAssingQuery = ' Select id, Name, Relcontact__r.Name, refTypeOfRooms__r.Name,refTypeOfRooms__c From Lead__c ';
		noAssingQuery += ' Where CancelBool__c != : cancelBool ';
		noAssingQuery += ' And RecordTypeId in :recTypeLst ';
		noAssingQuery += ' And Rroom__c = null ';
		noAssingQuery += ' And DAY_ONLY(convertTimezone(EntryTime__c)) = :searchDt ';
		if (!String.isEmpty(queryRoomType)) noAssingQuery += ' And refTypeOfRooms__c = :queryRoomType ';
		List<Lead__c> noAssignList = DataBase.query(noAssingQuery);
		
		List<NoAssignLeadInfo> rsList = new List<NoAssignLeadInfo>();
		for (Lead__c item : noAssignList) {
			NoAssignLeadInfo leadItem = new NoAssignLeadInfo();
			leadItem.contactName = item.Relcontact__r.Name.length() > 20 ? item.Relcontact__r.Name.substring(0,18) : item.Relcontact__r.Name;
			leadItem.leadId = item.Id;
			leadItem.leadName = item.Name;
			leadItem.roomTypeName = item.refTypeOfRooms__r.Name;
			leadItem.roomTypeId = item.refTypeOfRooms__c;
			rsList.add(leadItem);
		}
		return rsList;
		*/
		return null;
	}
	
	/**
	* 団体、単体の予約リストに表示する表示、[未割り当て予約]
	* 表示方式はTREEで(VIEW)
	**/
	// 2018/11/08 未割り当てウインドウの予約も該当部屋タイプのみ情報を表示する WGCH BEGIN
	/* noAssingLeadInfoAll => 此方法已经弃用 */
	@remoteAction
	global static List<NoAssignLeadInfoExt> noAssingLeadInfoAll(String queryDt, String branchShopCd, Boolean showToday) {
		return noAssingLeadInfoAllNew(queryDt, branchShopCd, showToday, null);
	}
	@remoteAction
	global static List<NoAssignLeadInfoExt> noAssingLeadInfoAllNew(String queryDt, String branchShopCd, Boolean showToday, String roomTypeSelectId) {
	// 2018/11/08 未割り当てウインドウの予約も該当部屋タイプのみ情報を表示する WGCH END
		// 指定日により、
		//Date todayDt = (String.isEmpty(queryDt)) ? Date.today() : Date.parse(queryDt);
		Date todayDt = (String.isEmpty(queryDt)) ? Date.today() : CommUtils.stringToDate(queryDt);
		Date searchDt = getProcessDate(todayDt, showToday);
//System.debug('queryDt:::' + queryDt);
		// 予約データは基本、宿泊場合、
		//Id bookRecTypeId = CommLogicProcess.getLeadBookingRecType();
        //Id baseRecTypeId = CommLogicProcess.getLeadBaseRecType();
        //List<Id> recTypeLst = new List<Id>{bookRecTypeId, baseRecTypeId};
        // 2017/11/14　未割り当て予約並べる by zy BEGIN
        String orderSQL = getAssignOrderQuery(branchShopCd);
        // 2017/11/14　未割り当て予約並べる by zy END
        List<Id> recTypeLst = getLeadBookingRecTypeLst();
		// 到着日は指定日と同じ、有効な予約データ、部屋番号は未設定場合、
		Integer cancelBool = CommConst.LEAD_ST_CANCEL_FLG;
        String noAssingQuery = ' Select id, Name, Field353__c,EntryTime__c,Departure__c,Field3__c,Field4__c, LeadIndexRef__c, Relcontact__r.Name, refTypeOfRooms__r.Name,refTypeOfRooms__c From Lead__c ';
		noAssingQuery += ' Where CancelBool__c != : cancelBool ';
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
		noAssingQuery += ' And DAY_ONLY(convertTimezone(EntryTime__c)) = :searchDt ';
        // 2018/05/11 複数店舗を選択表示できる機能対応 BEGIN
        List<String> mulitiSpcd = CommUtils.nullToBlank(branchShopCd).split(',');
        if (mulitiSpcd.size() > 1) {
			noAssingQuery += ' And (refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c = :mulitiSpcd OR refTypeOfRooms__c = null) ';
        } else if (!CommUtils.isBlank(branchShopCd)) {
		// 2013/09/02 ADD
		//if (!CommUtils.isBlank(branchShopCd)) noAssingQuery += ' And (refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c = \'' + String.escapeSingleQuotes(branchShopCd) + '\' OR refTypeOfRooms__c = null) ';
			noAssingQuery += ' And (refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c = \'' + String.escapeSingleQuotes(branchShopCd) + '\' OR refTypeOfRooms__c = null) ';
        }
        // 2018/05/11 複数店舗を選択表示できる機能対応 END
        // 2018/11/08 未割り当てウインドウの予約も該当部屋タイプのみ情報を表示する WGCH BEGIN
        // noAssingQuery += ' And refTypeOfRooms__c =: roomTypeSelectId '; 2019/2/2
        if(CommConst.ROOM_TYPE_SELECT_MODE == 1 && !CommUtils.isBlank(roomTypeSelectId)) {
        	List<string> lstRoomTypeId = roomTypeSelectId.split(',');
        	noAssingQuery += ' And refTypeOfRooms__c =: lstRoomTypeId ';
        }
        // 2018/11/08 未割り当てウインドウの予約も該当部屋タイプのみ情報を表示する WGCH END
		//if (!String.isEmpty(queryRoomType)) noAssingQuery += ' And refTypeOfRooms__c = :queryRoomType ';
		// 2017/11/14　未割り当て予約並べる by zy BEGIN
		if (!CommUtils.isBlank(orderSQL)) noAssingQuery += ' order by ' + orderSQL;
		// 2017/11/14　未割り当て予約並べる by zy END
		List<Lead__c> noAssignList = DataBase.query(noAssingQuery);
		// Map<LeadIndex_ID, 予約情報>
		Map<Id, NoAssignLeadInfoExt> leadMap = new Map<Id, NoAssignLeadInfoExt>();
		//
		List<NoAssignLeadInfoExt> rsList = new List<NoAssignLeadInfoExt>();
		// 2017/11/14　未割り当て予約並べる by zy BEGIN
		List<Id> leadIndexIdLst = new List<Id>();
		// 2017/11/14　未割り当て予約並べる by zy END
		for (Lead__c item : noAssignList) {
			Id leadIndexId = item.LeadIndexRef__c;
			// 該当予約は未設定する場合
			if (!leadMap.containsKey(leadIndexId)) {
				// 第一階層で、顧客名で階層名に設定を行う、一括設定する場合、該当階層に含めの予約は全部自動部屋アサインを行う
				NoAssignLeadInfoExt noAssItem = new NoAssignLeadInfoExt(true);
				noAssItem.id = leadIndexId;
				noAssItem.text = item.Relcontact__r.Name;
				//noAssItem.contactName = item.Relcontact__r.Name;
				leadMap.put(leadIndexId, noAssItem);
				// 2017/11/14　未割り当て予約並べる by zy BEGIN
				leadIndexIdLst.add(leadIndexId);
				// 2017/11/14　未割り当て予約並べる by zy END
			}
			// 予約単位の情報を設定して、LeadIndexの配列に設定を行う
			// 子情報ない設定を行う
			NoAssignLeadInfoExt noAssParentItem = leadMap.get(leadIndexId);
			NoAssignLeadInfoExt noAssChildItem = new NoAssignLeadInfoExt(false);
			
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
            // 同じグループの予約情報を追加する
			noAssParentItem.addItem(noAssChildItem);
		}
		// 2017/11/14　未割り当て予約並べる by zy BEGIN
		//List<Id> leadIndexIdLst = new List<Id>(leadMap.keySet());
		//leadIndexIdLst.sort();
		// 2017/11/14　未割り当て予約並べる by zy END
		for (Id leadIdxId : leadIndexIdLst) {
			NoAssignLeadInfoExt titleItem = leadMap.get(leadIdxId);
			titleItem.subdataid = titleItem.subdataid.substringBeforeLast(',');
			// 未割り当てる予約件数を設定する
			//件
			titleItem.text += '　【'+ titleItem.subdataid.split(',').size() +'】' + Label.CONST_008_0116 ;
			rsList.add(titleItem);
		}
		return rsList;
	}
	// 最新情報を画面Refreshする
	public void refreshPage() {
		queryRoomStatus();
	}
	// アサイン顧客情報を格納
	// ---予約名
	// ---顧客名　（部屋タイプ）
	global class NoAssignLeadInfo {
		public String contactName{get;set;}
		public Id leadId{get;set;}
		public String leadName{get;set;}
		public String roomTypeName{get;set;} 
		public Id roomTypeId{get;set;}
	}
	global class NoAssignLeadInfoExt {
		public NoAssignLeadInfoExt(Boolean childFlg) {
			isHasChildren = childFlg;
            //subdataid = new List<String>();
            subdataid = '';
            //rowNums = 0;
            items = new List<NoAssignLeadInfoExt>();
            cssClass = '';
            totalInt = 0;
		}
		//public String contactName{get;set;}
        public String id{get;set;}
        public String text{get;set;}
        public Boolean isHasChildren{get;set;}
        public String subdataid{get; set;}
		public Integer rowNums{get;set;}
		public String roomTypeName{get;set;} 
		public Id roomTypeId{get;set;}
		public String statusIcon{get;set;}
		public List<NoAssignLeadInfoExt> items{get; private set;}
        // 予約到着時間と出発時間情報を格納する
        public String startDateTime {get;set;}
        public String endDateTime   {get;set;}
        public String cssClass{get;set;}
        public Integer totalInt;
        public void addItem(NoAssignLeadInfoExt item) {
            items.add(item);
            subdataid += item.id +',';
        }
	}
	/**
	* 割り当てる可能の部屋リストを取得する
	* queryDate:入住開始日
	* maxDays:部屋空室の最大必要日数
	**/
	/*
	@remoteAction
	public static List<RoomInfo> noAssignRoomList (String leadIndexId, String queryDate, String maxDays) {
		// 部屋空室できる期間日数
		Decimal decMaxDays = CommUtils.nullToZero(maxDays);
		Integer intMaxDays = decMaxDays <= 0 ? 3 : decMaxDays.intValue();
		// 開始日と終了日の期間変数を設定する
		Date qDate = (String.isEmpty(queryDate)) ? Date.today() : Date.parse(queryDate);
		//Date endDt = startDt.addDays(intMaxDays);
		Date searchDt = getProcessDate(qDate);
		// 宿泊対象予約データレコードタイプ
		List<Id> recTypeLst = getLeadBookingRecTypeLst();
        // 該当部屋タイプに含めの部屋一覧を取得する
        Set<Id> roomIdSet = new Set<Id>();
        // 既に予約データに入る場合、該当部屋は選択対象外になる
        for (AggregateResult lead :  [
        	select Rroom__c roomId from Lead__c
        	where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG And RecordTypeId in :recTypeLst
                And DAY_ONLY(convertTimezone(EntryTime__c)) = :searchDt
                //And DAY_ONLY(convertTimezone(EntryTime__c)) < :endDt
                //And refTypeOfRooms__c = :roomTypeId 
                And Rroom__c != null
                Group By Rroom__c]) {
        	roomIdSet.add((Id)lead.get('roomId'));
        }
        // 障害部屋TODO
        //List<Room__c> roomLst = new List<Room__c>();
        String queryStr = 	' select Id, Name from Room__c ' +
        					' where UseOfRoom__c = \'' + String.escapeSingleQuotes(CommConst.ROOM_UseOfType_Guest) + '\'' +
        					'  And Id not in :roomIdSet ';
        //if (!CommUtils.isBlank(filter)) queryStr += ' And Name like \'%' + String.escapeSingleQuotes(filter) + '%\'';
        queryStr += ' Order By Seq__c';
        
        List<RoomInfo> rsLst = new List<RoomInfo>();
        for (Room__c rm  : DataBase.query(queryStr)) {
        	//roomLst.add(rm);
        	RoomInfo item = new RoomInfo(rm);
        	rsLst.add(item);
        }
    	return rsLst;
	}*/
	
    // *************************
    // 部屋変更処理
    // 2013/06/23から使わない
    // *************************
    public void changeRoom() {
        // 予約データは期間と部屋タイプにて、部屋在庫データを検索して、アサインできる部屋をチェックする
    	// 画面の指定日から、部屋変換を行う
    	// 選択する予約データを取得する
    	/* 2013/08/10 DELETE
    	List<Lead__c> leadLst = [select LeadIndexSubId__c,refTypeOfRooms__c,RecordTypeId, RoomGroupNo__c from Lead__c
    							where id = :strLeadId And LeadIndexSubId__c != null And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG];
    	if (leadLst.isEmpty()) {
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '予約データが既に削除されているため、処理失敗しました。'));
    		return;
    	}
    	// Sub-LeadIndex情報の開始日と終了日を取得して、期間合わせる部屋情報を取得する
    	String strSubIdxSql = CommSqlUtils.generateQueryString('LeadIndex__c');
    	String strSubIdxQuery = strSubIdxSql + ' where id = \'' + leadLst[0].LeadIndexSubId__c + '\'';
    	List<LeadIndex__c> subLeadIdxLst = Database.query(strSubIdxQuery);
    	if (subLeadIdxLst.isEmpty()) {
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'データ整合性問題が発生するため、処理失敗しました。'));
    		return;
    	}
    	LeadIndex__c orgleadSubIdx = subLeadIdxLst[0];
//System.debug('orgleadSubIdx::::::' + orgleadSubIdx);
        // 部屋変更後の新SubIndexデータを作成する
    	LeadIndex__c newLeadSubIdx = orgleadSubIdx.clone(false,true);
    	// 到着日から、出発日まで間の部屋チェックを行う
		Date startDt = selectDate.Checkinday__c;
		Date endDt = orgleadSubIdx.DepartureDate__c;
		Id roomTypeId = orgleadSubIdx.RoomTypeRef__c;
		Id bookingRecTypeId = leadLst[0].RecordTypeId;
		Decimal orgGroupRoomNo = leadLst[0].RoomGroupNo__c;
		Decimal newGroupRoomNo = 1;
        // ******************
        // 元SUBINDEX情報設定する
        // ******************
        // 1部屋だけ場合
        if (orgLeadSubIdx.Rooms__c == 1) {
			// 元SubIndexの出発日はルーム変換開始日
			orgleadSubIdx.DepartureDate__c = startDt;
			// 泊数を再計算を行う
			orgleadSubIdx.Nights__c = orgleadSubIdx.EntryDate__c.daysBetween(orgleadSubIdx.DepartureDate__c);
        }
        // 複数部屋場合
        else if (orgLeadSubIdx.Rooms__c > 1) {
            // 部屋数は-1で計算、更新を行う
            orgleadSubIdx.Rooms__c --;
        }
        // ******************
        // 新SUBINDEX情報設定する
        // ******************
        newLeadSubIdx.Rooms__c = 1;
		newLeadSubIdx.EntryDate__c = startDt;
		newLeadSubIdx.DepartureDate__c = endDt;
		newLeadSubIdx.Nights__c = newLeadSubIdx.EntryDate__c.daysBetween(newLeadSubIdx.DepartureDate__c);
		insert newLeadSubIdx;
		// 該当SubIndex関連付くの宿泊者情報も自動コピー、作成を行う
		String bookGuestSel = CommSqlUtils.generateQueryString('BookingGuest__c');
		String bookGuestQuery = bookGuestSel + ' Where IndexSubRef__c = \'' + orgleadSubIdx.Id + '\' ';
		bookGuestQuery += ' And RoomGroupNo__c = ' + leadLst[0].RoomGroupNo__c;
		// 宿泊者情報をコピーをコピー、新規作成を行う
		List<BookingGuest__c> guestCloneLst = new List<BookingGuest__c>();
		List<BookingGuest__c> orgGuestLst = Database.query(bookGuestQuery);
		for(BookingGuest__c guest : orgGuestLst) {
			guest.IndexSubRef__c = newLeadSubIdx.Id;
			guest.RoomRef__c = strNewRoomId;
			guest.RoomGroupNo__c = newGroupRoomNo;
            guestCloneLst.add(guest.clone(false,true));
		}
		// 予想は：SubIndex (1) -> 宿泊者名簿 -> N :  宿泊者名簿(1) -> N予約
		// 同じSubIndexに、RoomGroupNo__cは順番発行するため、1予約１宿泊名簿の状態
		insert guestCloneLst;
    	// 該当予約関連のSUB　INDEXに所属する予約データを取得して、部屋を変更を行う
    	List<Lead__c> updLeadLst = [select Rroom__c from Lead__c
    			Where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG And RecordTypeId = :bookingRecTypeId
                And DAY_ONLY(convertTimezone(EntryTime__c)) >= :startDt
                And DAY_ONLY(convertTimezone(EntryTime__c)) < :endDt
                And LeadIndexSubId__c = :orgleadSubIdx.Id
                And RoomGroupNo__c = :orgGroupRoomNo
                And refTypeOfRooms__c = :roomTypeId And Rroom__c != null];
        for (Lead__c lead : updLeadLst) {
        	lead.Rroom__c = strNewRoomId;
        	lead.LeadIndexSubId__c = newLeadSubIdx.Id;
        	// 予約関連の宿泊名簿データを自動作成を行う
        	lead.RoomGroupNo__c = newGroupRoomNo;
        }
        update updLeadLst;
        // 注意：元のSubIndexの開始日と終了日は同じ日付になる場合、自動削除を行う
        if (orgleadSubIdx.Nights__c == 0) {
        	// 宿泊者も削除を行う
        	//delete [select id from BookingGuest__c where IndexSubRef__c = :orgleadSubIdx.Id];
        	delete orgleadSubIdx;
        	delete orgGuestLst;
        } else update orgleadSubIdx;
        // 変更元の部屋は掃除指示データを作成する
        RoomsStatus__c newRoomSt = new RoomsStatus__c(
            Name = 'ルーム・チェンジの自動掃除指示' + System.now().format('yyyyMMddHHmm'),
            RoomRef__c = strNewRoomId,
            Status__c = CommConst.ROOM_ST_TYPE_CLS,     // 掃除
            StatusBeginDate__c = startDt,
            StatusEndDate__c = startDt,
            Describe__c = 'ルーム・チェンジに従って、掃除指示データ自動作成'
        );
        insert newRoomSt;
		// 最新部屋の状態画面情報を更新する
		queryRoomStatus();
		*/
    }
    // 支店選択リスト
	private Map<String,ShopInformation__c> shopInfoMap;
    public List<SelectOption> branchShopLst{get; private set;}
    public String branchShopNm{get; set;}
    public ShopInfoUtil.Color statusColor{get; private set;}	// 部屋ステータスの色情報を格納
    private void setInitBranShopLst() {
    	/* 2014/08/29 支店機能ソース改善
    	shopInfoMap = new Map<String,ShopInformation__c>();
        branchShopLst = new List<SelectOption>();
        */
        /* 2013/07/01 支店機能対応
        for (AggregateResult r : [  SELECT BranchShopName__c shopName FROM Room__c Where BranchShopName__c != null GROUP BY BranchShopName__c ORDER BY BranchShopName__c limit 10000]) {
            branchShopLst.add(new SelectOption(String.valueof(r.get('shopName')),String.valueof(r.get('shopName'))));
        }*/
        /* 2014/08/29 支店機能ソース改善
        for (ShopInformation__c shop : [select id, name,ShopCode__c,TierDefault__c from ShopInformation__c order by Seq__c limit 1000]) {
            branchShopLst.add(new SelectOption(shop.ShopCode__c, shop.name));
            shopInfoMap.put(shop.ShopCode__c, shop);
        }
        */
		// 2015/09/01 多店舗機能対応 BEGIN
        branchShopLst = ShopInfoUtil.getBranchShopLst(userInf.shops);
        shopInfoMap   = ShopInfoUtil.getShopInfoMap(userInf.shops);
		// 2015/09/01 多店舗機能対応 END
		//2016/11/02 shop 参数设定   wx BEGIN
		if (ApexPages.currentPage().getParameters().containsKey('spcd')) {
        	branchShopNm = ApexPages.currentPage().getParameters().get('spcd');
        }else{
    		//2016/11/02 shop 参数设定   wx END
        	if (!branchShopLst.isEmpty()) {
				// 2019/07/31 ルームインジケータの店舗の初期値をallにしたいとの要望です by zy BEGIN
				branchShopNm = getCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.SPCD.name(), '',true);
				// 自動記憶店舗集合
				List<String> exitCodeLst = new List<String>();
				Set<String> codeSet = new Set<String>();
				// 指定デフォルトコード
				String defSpcd = '';
				// 自動記憶店舗あり
				if (branchShopNm != null) {
					branchShopNm = (String)JSON.deserialize(branchShopNm, String.class);
					codeSet = new Set<String>(branchShopNm.split(','));
				}
				// 2019/07/31 ルームインジケータの店舗の初期値をallにしたいとの要望です by zy END
        		// 顧客に設定する支店で初期値に設定する[2013/06/30]
        		String locShopCode = UserUtil.CurrentUser.ShopCode__c;
        		for (SelectOption s : branchShopLst) {
					// 2019/07/31 ルームインジケータの店舗の初期値をallにしたいとの要望です by zy BEGIN
					String spcd = s.getValue();
					if (branchShopNm != null) {
						if (codeSet.contains(spcd)) exitCodeLst.add(spcd);
						if (spcd == locShopCode) defSpcd = locShopCode;
						continue;
					}
					// 2019/07/31 ルームインジケータの店舗の初期値をallにしたいとの要望です by zy END
        			if (s.getValue() == locShopCode) branchShopNm = locShopCode;
	        	}
				// 2019/07/31 ルームインジケータの店舗の初期値をallにしたいとの要望です by zy BEGIN
				if (branchShopNm != '') {
					if(!exitCodeLst.isEmpty()) {
						if (multiSelectCompFlg) branchShopNm = String.join(exitCodeLst,',');
						else branchShopNm = exitCodeLst[0];
					} else branchShopNm = defSpcd;
				}
				// 2019/07/31 ルームインジケータの店舗の初期値をallにしたいとの要望です by zy END
        	}
        }
        // 2018/05/11 複数店舗を選択表示できる機能対応 BEGIN
    	multiDepartCds = branchShopNm;
    	// 2018/05/11 複数店舗を選択表示できる機能対応 END
        // 支店関連のCOLOR情報初期化を行う
        setBranShopColorInfo();
    }
    private void setBranShopColorInfo() {
    	statusColor = ShopInfoUtil.getStatusColor(branchShopNm);
    }
	// 部屋タイプ情報
	public List<SelectOption> roomTypeLst{get; private set;}
	public String roomTypeNm{get; set;}
	//2019/2/15 ルームインジケータの部屋タイプ絞り込み機能を、タイムテーブルと同じように、複数タイプ指定できるようにして欲しい by cxw BEGIN
	private String orgSettingValue;
	public String multiRoomTypeIds{get; set;}
	//2019/2/15 ルームインジケータの部屋タイプ絞り込み機能を、タイムテーブルと同じように、複数タイプ指定できるようにして欲しい by cxw END
    private void setInitRoomTypeLst() {
    	roomTypeLst = new List<SelectOption>();
		// 部屋タイプ一覧取得用
		//for (TypeOfRooms__c r : [ Select Id, Name From TypeOfRooms__c Order By Seq__c limit 500]) {
		/*
		String typeRoomQuery = ' Select Id, Name From TypeOfRooms__c ';
		if (!String.isEmpty(branchShopNm)) typeRoomQuery += ' Where ShopInfoRef__r.ShopCode__c = :branchShopNm ';
		typeRoomQuery += ' Order By Seq__c limit 500 ';
		for (TypeOfRooms__c r : DataBase.query(typeRoomQuery) ) {
		*/
	// 2015/09/01 多店舗機能対応 BEGIN
        List<TypeOfRooms__c> roomTypeLstRs = new List<TypeOfRooms__c>();
        // 2018/05/11 複数店舗を選択表示できる機能対応 BEGIN
        List<String> mulitiSpcd =  getMulitSpCd();
        if (mulitiSpcd.size() > 1) {
        	roomTypeLstRs = (new CommLogicProcess()).getTypeOfRooms(mulitiSpcd);
        	for (TypeOfRooms__c rt : roomTypeLstRs) {
        		rt.Name = rt.Name + '('+CommUtils.nullToBlank(rt.ShopInfoRef__r.ShopCode__c)+')';
        	}
        } else if (CommUtils.isBlank(branchShopNm) && userInf.isShopCodePlex) {
        // 2018/05/11 複数店舗を選択表示できる機能対応 END
            roomTypeLstRs = (new CommLogicProcess()).getTypeOfRooms(userInf.shops);
        }else {
            roomTypeLstRs = (new CommLogicProcess()).getTypeOfRooms(branchShopNm);
        }
	// 2015/09/01 多店舗機能対応 END
        //2019/2/15 ルームインジケータの部屋タイプ絞り込み機能を、タイムテーブルと同じように、複数タイプ指定できるようにして欲しい by cxw BEGIN
        String strType = CommUtils.nullToBlank(RoomIndicatorInfo.getCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.DEPARTCODES.name(), ''));
        Set<String> setType = new Set<String>(strType.split(','));
        Set<String> setAllType = new Set<String>();
		for (TypeOfRooms__c r : roomTypeLstRs) {
    		roomTypeLst.add(new SelectOption(r.Id, r.Name));
    		setAllType.add(r.Id);
		}
		setType.retainAll(setAllType);
		roomTypeNm = multiRoomTypeIds = orgSettingValue = String.join(new List<String>(setType), ',');
		//2019/2/15 ルームインジケータの部屋タイプ絞り込み機能を、タイムテーブルと同じように、複数タイプ指定できるようにして欲しい by END
		// 2017/12/22 画面フィルター機能追加　by　zy　BEGIN
        filterHidRoom = '';
        filteText = '';
        // 2017/12/22 画面フィルター機能追加　by　zy　END
    }

    /**
    * 色表示関連情報の初期化
    * 2016/01/28 予約ステータス/部屋ステータス表示の切替できる対応
    **/
	// 予約情報ステータスの色制御情報を格納
	public String statusCode{get; set;}
	public String constStatusCodeRoom{get{ return 'room';}}
	public String constStatusCodeLead{get{ return 'lead';}}
	public Map<String, AppSetupConfigXmlUtil.Config> leadStatusColorMap{get; private set;}
	public List<SelectOption> leadStatusInfoLst{get; private set;}
    private void initColorInfo () {
    	if (statusCode != constStatusCodeLead) return;
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
    }
    public void changeStatusMode() {
 		// 選択値はCOOKIEへ反映する
 		CookieInf inf = new CookieInf();
 		inf.statusMode = statusCode;
        setCookieInf(inf);
    	// 2016/01/28 予約ステータス/部屋ステータス表示の切替できる対応 BEGIN
        initColorInfo();
        // 2016/01/28 予約ステータス/部屋ステータス表示の切替できる対応 END
  		gotoDate();
    }

    // 画面の部屋にて、該当予約情報をチェックインする
    public void checkInByRoom() {
    	if(strLeadId != ''){
    		Set<String> leadIds = new Set<String>();
    		// 宿泊のレコードタイプ
			//Id bookRecTypeId = CommLogicProcess.getLeadBookingRecType();
	        //Id baseRecTypeId = CommLogicProcess.getLeadBaseRecType();
	        //List<Id> recTypeLst = new List<Id>{bookRecTypeId, baseRecTypeId};
	        // 団体一括チェックインを設定される場合
	        if(isGroupFlg)
	        { 
			
	        	for(String leadId : groupLeadIds.split(','))
	        	{
	        		leadIds.add(leadId);
	        	}
	        }else
	        {
	        	leadIds.add(strLeadId);
	        }
	        List<Id> recTypeLst = getLeadBookingRecTypeLst();
	        // 昼12時過ぎすると、到着日は当日のデータを表示する、12時前の場合、到着日は前日のデータを表示する
	        Date searchDt = getProcessDate(processDate, isShowToday);
			// 選択した予約データ
			List<Lead__c> checkInLead = [select Id, Field298__c, LeadIndexRef__c from Lead__c
				where Id = :leadIds And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
				And DAY_ONLY(convertTimezone(EntryTime__c)) = :searchDt
				And RecordTypeId in :recTypeLst
				And Field298__c = null for update];
			if(checkInLead.size() > 0){
				/* 2013/09/23 一括チェックインから個別チェックインに変更する
				// 関連の部屋数は統計する
				Id leadIndexId = checkInLead[0].LeadIndexRef__c;
				AggregateResult roomsResult = [select sum(Rooms__c) rooms from LeadIndex__c 
						where ParentLeadIndxRef__c = :leadIndexId
						And EntryDate__c <= :searchDt And DepartureDate__c >= :searchDt];
				Decimal rooms = (Decimal)roomsResult.get('rooms');
System.debug('rooms:::' + rooms);
				// 団体（複数部屋場合)
				if (rooms > 1) {
					checkInLead = [select Id, Field298__c, LeadIndexRef__c from Lead__c
									where LeadIndexRef__c = :leadIndexId And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
									And DAY_ONLY(convertTimezone(EntryTime__c)) = :searchDt
									And RecordTypeId in :recTypeLst
									And Rroom__c != null
									And Field298__c = null];
					for (Lead__c item : checkInLead) {
						item.Field298__c = CommConst.LEAD_GUEST_ST_CI;
					}
				} 
				// 個別部屋場合
				else {
				*/
					//checkInLead[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
				//}
					 if(isGroupFlg)
			        { 
			        	for(Lead__c lead : checkInLead)
			        	{
			        		lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
			        	}
			        }else
			        {
			        	checkInLead[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
			        }
				try{
					update checkInLead;
				}catch(Exception e){
					// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 BEGIN
					String errMsg = e.getMessage();
					if(!CommUtils.isFieldValidationMessage(errMsg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
					// 2018/05/14 报错以后房间消失问题对应 by zy BEGIN
		            refreshPage();
		            // 2018/05/14 报错以后房间消失问题对应 by zy END
					bookingCreateOK = false;
					// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 END
					return;
				}
				queryRoomStatus();

			}else{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'the lead Detail is not able to checkin'));
				// 2018/05/14 报错以后房间消失问题对应 by zy BEGIN
	            refreshPage();
	            // 2018/05/14 报错以后房间消失问题对应 by zy END
				return;
			}
    	}else{
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'the leadId is null'));
    		// 2018/05/14 报错以后房间消失问题对应 by zy BEGIN
            refreshPage();
            // 2018/05/14 报错以后房间消失问题对应 by zy END
			return;
    	}
        bookingCreateOK = true;
    }
    // 2013/06/14 ADD
  //2019/2/15 ルームインジケータの部屋タイプ絞り込み機能を、タイムテーブルと同じように、複数タイプ指定できるようにして欲しい by cxw BEGIN
	public static void saveCookieInfo(String subType,String spcd ,String settingInfo){
		// Cookieからレイアウトモードを取得する
		UserConfigCompCtrl.saveCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.INDICATOR,
				subType,settingInfo,UserUtil.CurrentUser.id,spcd);
	}
	// 2019/07/31 ルームインジケータの店舗の初期値をallにしたいとの要望です by zy BEGIN
	public static String getCookieInfo(String subType,String spcd){
		return getCookieInfo(subType,spcd,false);
	}
	public static String getCookieInfo(String subType,String spcd,boolean isHadNull){
	// 2019/07/31 ルームインジケータの店舗の初期値をallにしたいとの要望です by zy END
		map<String,String> userBookMap = UserConfigCompCtrl.getCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.INDICATOR,
											UserUtil.CurrentUser.id,spcd);
		// 2019/07/31 ルームインジケータの店舗の初期値をallにしたいとの要望です by zy BEGIN
		String cookieInfo = userBookMap.get(subType);
		if (!isHadNull) cookieInfo = CommUtils.nullToBlank(cookieInfo);
		// 2019/07/31 ルームインジケータの店舗の初期値をallにしたいとの要望です by zy END
	   	return cookieInfo;
	}
	//2019/2/15 ルームインジケータの部屋タイプ絞り込み機能を、タイムテーブルと同じように、複数タイプ指定できるようにして欲しい by cxw END
    // 画面の部屋にて、該当予約情報をチェックアウトする
    public void checkOutByRoom() {
    	if(strLeadId != ''){
    		// 宿泊のレコードタイプ
			//Id bookRecTypeId = CommLogicProcess.getLeadBookingRecType();
	        //Id baseRecTypeId = CommLogicProcess.getLeadBaseRecType();
	        //List<Id> recTypeLst = new List<Id>{bookRecTypeId, baseRecTypeId};
			List<Id> recTypeLst = getLeadBookingRecTypeLst();
	        // 昼12時過ぎすると、到着日は当日のデータを表示する、12時前の場合、到着日は前日のデータを表示する
	        Date searchDt = getProcessDate(processDate, isShowToday);
			// 一括チェックアウト処理を追加
			Set<String> leadIds = new Set<String>();
			leadIds.add(strLeadId);
			// 一括処理の場合
			if(isGroupFlg) {
				groupLeadIds = groupLeadIds.removeEnd(',');
				leadIds.addAll(groupLeadIds.split(','));
	        }
			List<Lead__c> checkInLead = [select Id, Field298__c,Rroom__c,checkoutdate__c 
				// 2019/08/31 42.ご予約チェックアウト後の「未清掃」ステータスの付与処理をお部屋によってON/OFFができるようにしたい by zy BEGIN 
				, Rroom__r.RoomNotCreateFlg__c
				// 2019/08/31 42.ご予約チェックアウト後の「未清掃」ステータスの付与処理をお部屋によってON/OFFができるようにしたい by zy END
				from Lead__c
				//where Id = :strLeadId And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
				where Id = :leadIds And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
				And DAY_ONLY(convertTimezone(EntryTime__c)) = :searchDt
				And RecordTypeId in :recTypeLst
				And Rroom__c != null
				And Field298__c != null And Field298__c != :CommConst.LEAD_GUEST_ST_CO for update];
			if(checkInLead.size() > 0){
				for (Lead__c lead : checkInLead) {
					//checkInLead[0].Field298__c = CommConst.LEAD_GUEST_ST_CO;
					lead.Field298__c = CommConst.LEAD_GUEST_ST_CO;
				}
				Savepoint sp = Database.setSavepoint();
				try{
					update checkInLead;
					// 該当部屋の清掃データを作成する[画面に指定日にて、清掃管理データを作成する]
					// 2013/08/14 ADD
					// 2013/11/06 日付調整により、清掃データの日付修正する
					Date tmpDate = getInputDate(0); // 指定日で清掃情報を作成する
					(new RoomStatusManager()).createNoCleanRooms(tmpDate, checkInLead);
				}catch(Exception e){
					// 登録ROLLBACK
					DataBase.rollback(sp);
					// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 BEGIN
					String errMsg = e.getMessage();
					if(!CommUtils.isFieldValidationMessage(errMsg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
					bookingCreateOK = false;
					// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 END
					// 2018/05/14 报错以后房间消失问题对应 by zy BEGIN
		            refreshPage();
		            // 2018/05/14 报错以后房间消失问题对应 by zy END
					return;
				}
				// 最新部屋情報を取得する
				queryRoomStatus();

			}else{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'the lead Detail is not able to checkout'));
				// 2018/05/14 报错以后房间消失问题对应 by zy BEGIN
	            refreshPage();
	            // 2018/05/14 报错以后房间消失问题对应 by zy END
				return;
			}
    	}else{
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'the leadId is null'));
    		// 2018/05/14 报错以后房间消失问题对应 by zy BEGIN
            refreshPage();
            // 2018/05/14 报错以后房间消失问题对应 by zy END
			return;
    	}
		bookingCreateOK = true;
    }
	// 2019/02/28 滞在・外出状態の管理 WGCH BEGIN
	// 画面の部屋にて、該当予約情報を外出する
	public void outByRoom() {
		if(strLeadId != ''){
			List<Id> recTypeLst = getLeadBookingRecTypeLst();
			// 昼12時過ぎすると、到着日は当日のデータを表示する、12時前の場合、到着日は前日のデータを表示する
			Date searchDt = getProcessDate(processDate, isShowToday);
			// 一括チェックアウト処理を追加
			Set<String> leadIds = new Set<String>();
			// 2019/07/15 多泊の場合、外出の場合、多泊の予約に同じ状態を更新する BY zyz BEGIN
			//leadIds.add(strLeadId);
			// 団体一括チェックインを設定される場合
			if(isGroupFlg){ 
				for(String leadId : groupLeadIds.split(',')){
					leadIds.add(leadId);
				}
			}else{
				leadIds.add(strLeadId);
			}
			// 2019/07/15 多泊の場合、外出の場合、多泊の予約に同じ状態を更新する BY zyz END
			List<Lead__c> checkInLead = [select Id, Field298__c,Rroom__c,checkoutdate__c from Lead__c
				where Id = :leadIds And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
				And DAY_ONLY(convertTimezone(EntryTime__c)) = :searchDt
				And RecordTypeId in :recTypeLst
				And Rroom__c != null
				And Field298__c != null And Field298__c != :CommConst.LEAD_GUEST_ST_CO And Field298__c != :CommConst.LEAD_GUEST_ST_OUT for update];
			if(checkInLead.size() > 0){
				for (Lead__c lead : checkInLead) {
					lead.Field298__c = CommConst.LEAD_GUEST_ST_OUT;
				}
				Savepoint sp = Database.setSavepoint();
				try{
					update checkInLead;
				}catch(Exception e){
					// 登録ROLLBACK
					DataBase.rollback(sp);
					// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 BEGIN
					String errMsg = e.getMessage();
					if(!CommUtils.isFieldValidationMessage(errMsg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
					bookingCreateOK = false;
					// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 END
					// 2018/05/14 报错以后房间消失问题对应 by zy BEGIN
					refreshPage();
					// 2018/05/14 报错以后房间消失问题对应 by zy END
					return;
				}
				// 最新部屋情報を取得する
				queryRoomStatus();
			}else{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'the lead Detail is not able to out'));
				// 2018/05/14 报错以后房间消失问题对应 by zy BEGIN
				refreshPage();
				// 2018/05/14 报错以后房间消失问题对应 by zy END
				return;
			}
		}else{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'the leadId is null'));
			// 2018/05/14 报错以后房间消失问题对应 by zy BEGIN
			refreshPage();
			// 2018/05/14 报错以后房间消失问题对应 by zy END
			return;
		}
		bookingCreateOK = true;
	}
	// 画面の部屋にて、該当予約情報を戻るする
	public void returnByRoom() {
		if(strLeadId != ''){
			List<Id> recTypeLst = getLeadBookingRecTypeLst();
			// 昼12時過ぎすると、到着日は当日のデータを表示する、12時前の場合、到着日は前日のデータを表示する
			Date searchDt = getProcessDate(processDate, isShowToday);
			// 一括チェックアウト処理を追加
			Set<String> leadIds = new Set<String>();
			// 2019/07/15 多泊の場合、外出の場合、多泊の予約に同じ状態を更新する BY zyz BEGIN
			// leadIds.add(strLeadId);
			// 団体一括チェックインを設定される場合
			if(isGroupFlg){ 
				for(String leadId : groupLeadIds.split(',')){
					leadIds.add(leadId);
				}
			}else{
				leadIds.add(strLeadId);
			}
			// 2019/07/15 多泊の場合、外出の場合、多泊の予約に同じ状態を更新する BY zyz END
			List<Lead__c> checkInLead = [select Id, Field298__c,Rroom__c,checkoutdate__c from Lead__c
				where Id = :leadIds And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
				And DAY_ONLY(convertTimezone(EntryTime__c)) = :searchDt
				And RecordTypeId in :recTypeLst
				And Rroom__c != null
				And Field298__c != null And Field298__c != :CommConst.LEAD_GUEST_ST_CO And Field298__c != :CommConst.LEAD_GUEST_ST_CI for update];
			if(checkInLead.size() > 0){
				for (Lead__c lead : checkInLead) {
					lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
				}
				Savepoint sp = Database.setSavepoint();
				try{
					update checkInLead;
				}catch(Exception e){
					// 登録ROLLBACK
					DataBase.rollback(sp);
					// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 BEGIN
					String errMsg = e.getMessage();
					if(!CommUtils.isFieldValidationMessage(errMsg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
					bookingCreateOK = false;
					// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 END
					// 2018/05/14 报错以后房间消失问题对应 by zy BEGIN
					refreshPage();
					// 2018/05/14 报错以后房间消失问题对应 by zy END
					return;
				}
				// 最新部屋情報を取得する
				queryRoomStatus();
			}else{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'the lead Detail is not able to checkin'));
				// 2018/05/14 报错以后房间消失问题对应 by zy BEGIN
				refreshPage();
				// 2018/05/14 报错以后房间消失问题对应 by zy END
				return;
			}
		}else{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'the leadId is null'));
			// 2018/05/14 报错以后房间消失问题对应 by zy BEGIN
			refreshPage();
			// 2018/05/14 报错以后房间消失问题对应 by zy END
			return;
		}
		bookingCreateOK = true;
	}
	// 2019/02/28 滞在・外出状態の管理 WGCH END
	// 2016/11/04 予約キャンセル機能対応 BEGIN  
    public void leadCancel() {
    	bookingCreateOK = false;
    	if(strLeadId != ''){
    		Set<String> leadIds = new Set<String>();
	        // 団体一括チェックインを設定される場合
	        if(isGroupFlg){ 
	        	for(String leadId : groupLeadIds.split(',')){
	        		leadIds.add(leadId);
	        	}
	        } else{
	        	leadIds.add(strLeadId);
	        }
	        //List<Id> recTypeLst = getLeadBookingRecTypeLst();
	        // 昼12時過ぎすると、到着日は当日のデータを表示する、12時前の場合、到着日は前日のデータを表示する
	        Date searchDt = getProcessDate(processDate, isShowToday);
	        // 指定の予約IDにより、キャンセル日から以後の予約情報を全部キャンセルを行う
	        List<Lead__c> cancelOrgLeads = [select Id, LeadIndexRef__c,LeadIndexSubId__c,ReservedStatus__c,RoomGroupNo__c from Lead__c where Id = :leadIds];
	        // 関連の予約情報を取得機能
	        set<id> leadIndexIdSet = new set<id>();
	        set<id> leadIndexSubIdSet = new set<id>();
	        set<decimal> groupNoSet = new set<decimal>();
	       	for (Lead__c lead : cancelOrgLeads) {
	       		leadIndexIdSet.add(lead.LeadIndexRef__c);
	       		leadIndexSubIdSet.add(lead.LeadIndexSubId__c);
	       		groupNoSet.add(lead.RoomGroupNo__c);
	       	}									
	       	List<Lead__c> cancelLeads = [select id,ReservedStatus__c,LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c from lead__c 
								where LeadIndexRef__c in :leadIndexIdSet And LeadIndexSubId__c in :leadIndexSubIdSet And RoomGroupNo__c in :groupNoSet
								And DAY_ONLY(convertTimezone(EntryTime__c)) >= :searchDt
								// 有効な予約のみ関連更新を行う
								And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG for update];
			// map<leadindex_leadinexsub_groupno, list<lead__c>>
			map<String, list<Lead__c>> leadsInfoMap = new map<string, list<lead__c>>();
			map<Id, String> leadIdTokeyMap = new map<Id, String>();
			for (Lead__c lead : cancelLeads) {
				String key = getKeyOfSameGroupLead(lead);
				leadIdTokeyMap.put(lead.Id, key);
				if (!leadsInfoMap.containskey(key)) leadsInfoMap.put(key, new list<Lead__c>());
				leadsInfoMap.get(key).add(lead);
			}
			List<Lead__c> cancelUpdLeads = new List<Lead__c>();
			for (Lead__c lead : cancelOrgLeads) {
				if (!leadIdTokeyMap.containsKey(lead.Id)) continue;
				String key = leadIdTokeyMap.get(lead.id);
				if (leadsInfoMap.containsKey(key)) {
					cancelUpdLeads.addAll(leadsInfoMap.get(key));
				}
			}
        	for(Lead__c lead : cancelUpdLeads){
        		lead.ReservedStatus__c = CommConst.LEAD_ST_CANCEL;
        	}
			try{
				if (!cancelUpdLeads.isEmpty()) update cancelUpdLeads;
			}catch(Exception e){
				String errMsg = e.getMessage();
				if(!CommUtils.isFieldValidationMessage(errMsg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
				// 2018/05/14 报错以后房间消失问题对应 by zy BEGIN
	            refreshPage();
	            // 2018/05/14 报错以后房间消失问题对应 by zy END
				return;
			}
			// 最新部屋情報を取得する
			queryRoomStatus();
    	}else{
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'the leadId is null'));
			return;
    	}
        bookingCreateOK = true;
    }
	private String getKeyOfSameGroupLead(Lead__c lead) {
		return 	  CommUtils.nullToBlank(Lead.LeadIndexRef__c) 
				+ '_' 
				+ CommUtils.nullToBlank(lead.LeadIndexSubId__c) 
				+ '_' 
				+ CommUtils.nullToBlank(lead.RoomGroupNo__c);
	}
	// 2016/11/04 予約キャンセル機能対応 END    
    /***************
    * 部屋清掃済更新を行う
    * roomId : 清掃対象部屋のIDs
    * queryDt: 清掃処理の処理日
    * leadId : 未使用のパラメータ
    ***************/
    @remoteAction
	//public static String cleanRoomAction(List<Id> roomId, String queryDt, String leadId) {
	global static String cleanRoomAction(List<Id> roomId, String queryDt) {
    	// 指定日の該当部屋のステータス管理データは「清掃済」に更新を行う
    	//Date todayDt = (String.isEmpty(queryDt)) ? Date.today() : Date.parse(queryDt);
    	Date todayDt = (String.isEmpty(queryDt)) ? Date.today() : CommUtils.stringToDate(queryDt);
    	// 該当日付の部屋清掃済に更新を行う
    	//Set s = new Set{'Jon', 'Quinton'};
    	Set<Id> roomIdSet = new Set<Id>();
    	roomIdSet.addAll(roomId);
    	// 2018/8/28 ルームインジケーターのチェックアウトから日をまたぐと未清掃が反映 BY WSQ BEGIN
    	//(new RoomStatusManager()).upClearnStatus(todayDt, roomIdSet);
    	// 清掃フラグ状態を保持フラグが有効の場合、日付を指定なし、全て未清掃データをクリアする　
    	(new RoomStatusManager()).upClearnStatus((isKeepCleanFlag ? null : todayDt), roomIdSet);
    	// 2018/8/28 ルームインジケーターのチェックアウトから日をまたぐと未清掃が反映 BY WSQ END
    	return '';
	}
	
	
    // 宿泊の対象データ表示機能
    public static List<Id> getLeadBookingRecTypeLst () {
		Id bookRecTypeId = CommLogicProcess.getLeadBookingRecType();
	    Id baseRecTypeId = CommLogicProcess.getLeadBaseRecType();
	    List<Id> recTypeLst = new List<Id>{bookRecTypeId, baseRecTypeId};
	    return recTypeLst;
    }
    
	// 最新連絡事項情報取得
	public MessageItem__c messageObj{get; set;}
	private void setMessageItem(Date currDate) {
		// 2015/10/27 連絡事項共通化 BEGIN
		// 去年の年月
		currDate = selectDate.Checkinday__c;
		//Date oldYearMonth = currDate.addYears(-1);
		DateTime currDt = DateTime.newInstance(currDate, Time.newInstance(0,0,0,0));
		String currYm = currDt.format('yyyyMMdd');
		/*
		String oldYm = currDt.addYears(-1).format('yyyyMMdd');
		String querySql = CommSqlUtils.generateQueryString('MessageItem__c');
		//List<MessageItem__c> msgLst = [select id, name, message1__c, message2__c, message3__c, message4__c, message5__c, Message6__c
		//		from MessageItem__c where name = :currYm or name = :oldYm order by name desc limit 2];
		if (Commconst.OLDDATE_ISSHOW_MESSAGE) querySql += ' where name = :currYm or name = :oldYm order by name desc limit 2 ';
		else querySql += ' where name = :currYm order by name desc limit 1 ';
		//querySql += ' where name = :currYm or name = :oldYm order by name desc limit 2 ';
		List<MessageItem__c> msgLst = DataBase.query(querySql);
		if (msgLst.isEmpty()) {
			// 今年の連絡事項がなかった場合、去年の同じ年月の
			messageObj = new MessageItem__c(name=currYm);
		} else {
			messageObj = msgLst[0].clone(false,true);
			messageObj.Name = currYm;
			messageObj.ownerId = UserInfo.getUserId();
		}*/
		messageObj = new MessageItem__c(name=currYm);
		// 2015/10/27 連絡事項共通化 END
	}
	// 2015/10/27 連絡事項共通化 BEGIN
	/*
	public void saveMessageItem() {
		Database.upsert(messageObj, MessageItem__c.name);
	}*/
	// 2015/10/27 連絡事項共通化 END
    
    /* 処理日 */
    public static Date getProcessDate (Date procDate, boolean pIsCheckInLayout) {
    	// 選択の日付は当日分の場合、切替時間により、表示を行う
    	// 選択の日付は翌日からの未来日の場合、選択日の日付はデータ抽出日付で判定する
    	/* 2013/08/23 変更戻すVer3.72->V3.69 */
    	if (procDate != Date.today()) return procDate;
    	// 当日のチェックインの情報を切り替えする場合、選択の日付で抽出条件日付でデータを表示する
    	else if (pIsCheckInLayout) return procDate;
    	//else return (System.now().format('HH:mm') < equalTime.format('HH:mm') ? procDate.addDays(-1) : procDate);
    	else return procDate.addDays(-1);
    	//return (System.now().format('HH:mm') < equalTime.format('HH:mm') ? procDate.addDays(-1) : procDate);
    }
    // 2017/08/17 ルームインジケータ画面に、縦セルに表示項目をカスタマイズできるように改善対応 WGCH BEGIN
	//　部屋に関連付の予約情報を取得する
    //private final String QueryLeadHeader = 'Select id,Name,Mans__c,Femails__c,ChildC__c,ChildD__c,ChildE__c,ChildFA__c,ChildF__c,Childs__c,StayPersons__c,RecordType.Name, Rroom__c,Field276__c, Relcontact__r.Name, Relcontact__r.Katakana__c, Relcontact__r.KanaName1__c ,Relcontact__r.KanaName2__c ,ReservedStatus__c, LeadIndexSubId__c, LeadIndexRef__c, LeadIndexRef__r.DepartureDate__c, EntryTime__c, Field4__c, Departure__c, Field3__c, Field310__c, Field298__c, Field299__c,DayNightCal__c From Lead__c ';
	// 2018/01/24 清掃不要機能追加　by　zy　BEGIN
	// 2018/12/15 レジカード改善 小人その他追加 BY zyz BEGIN
	// 2019/12/30 小部屋の作成 BY zyz BEGIN
	// 2020/09/30 当日チェックアウトの日帰り予約がチェックイン後にルームチェンジできなくなる不具合の解消 by zy BEGIN
	private final String QueryLeadHeader = 'id,Name,Mans__c,Femails__c,ChildOther__c,ChildC__c,ChildD__c,ChildE__c,ChildFA__c,ChildF__c,Childs__c,StayPersons__c,RecordType.Name, Rroom__c,Field276__c, Relcontact__r.Name, Relcontact__r.Katakana__c, Relcontact__r.KanaName1__c ,Relcontact__r.KanaName2__c ,ReservedStatus__c, LeadIndexSubId__c, LeadIndexRef__c, LeadIndexRef__r.DepartureDate__c, EntryTime__c, Field4__c, Departure__c, Field3__c, Field310__c, Field298__c, Field299__c,DayNightCal__c,NoCleanRoomFlg__c,ParentLeadId__c,StayNightCal__c';
	// 2020/09/30 当日チェックアウトの日帰り予約がチェックイン後にルームチェンジできなくなる不具合の解消 by zy END
	// 2019/12/30 小部屋の作成 BY zyz END
	// 2018/12/15 レジカード改善 小人その他追加 BY zyz END
	// 2018/01/24 清掃不要機能追加　by　zy　END
	// 2017/08/17 ルームインジケータ画面に、縦セルに表示項目をカスタマイズできるように改善対応 WGCH END
	//private final String QueryBadRoomHeader = CommSqlUtils.
	/**
	* 処理日に予約済みの予約データを取得する、アサインされている部屋をチェックを行う
	**/
	private Map<Id, Lead__c> queryLeadInfo () {

        // 宿泊のレコードタイプを取得する
        //Id bookRecTypeId = CommLogicProcess.getLeadBookingRecType();
        //Id baseRecTypeId = CommLogicProcess.getLeadBaseRecType();
        //List<Id> recTypeLst = new List<Id>{bookRecTypeId, baseRecTypeId};
        List<Id> recTypeLst = getLeadBookingRecTypeLst();
        roomLeadsCount = new Map<Id,Integer>();         // 部屋毎に格納した予約数
        // 有効な予約データ、一日一部屋で処理するため、重複することは処理対象外
        // 昼12時過ぎすると、到着日は当日のデータを表示する、12時前の場合、到着日は前日のデータを表示する
        Date searchDt = getProcessDate(processDate, isShowToday);
        String queryWhere = ' Where DAY_ONLY(convertTimezone(EntryTime__c)) = ' + String.valueOf(searchDt);
        queryWhere += ' And CancelBool__c != ' + CommConst.LEAD_ST_CANCEL_FLG;
        queryWhere += ' And Rroom__c != null ';
	    // 2018/02/06 予約検索条件はレコードタイプ外す改善対応 BEGIN
	    if (leadQueryRecTypeFlg == false ) {
//System.debug(loggingLevel.info, '======= STEP1-002[1] ========='); 
	    // 2018/02/06 予約検索条件はレコードタイプ外す改善対応 END
        queryWhere += ' And RecordTypeId in :recTypeLst ';
        // 2018/02/06 予約検索条件はレコードタイプ外す改善対応 BEGIN
	    }
//System.debug(loggingLevel.info, '======= STEP1-002[2] =========');
        // 2018/02/06 予約検索条件はレコードタイプ外す改善対応 END
	// 2015/09/01 多店舗機能対応 BEGIN
        // 2018/05/11 複数店舗を選択表示できる機能対応 BEGIN
    	list<string> mulitiSpcd = getMulitSpCd();
        if (mulitiSpcd.size() > 1) {
        	queryWhere+= ' And Rroom__r.ShopInfoRef__r.ShopCode__c in :mulitiSpcd';
        }
        else if (!CommUtils.isBlank(branchShopNm)) {
        // 2018/05/11 複数店舗を選択表示できる機能対応 END
            queryWhere+= ' And Rroom__r.ShopInfoRef__r.ShopCode__c = \'' + String.escapeSingleQuotes(BranchShopNm) + '\'';
        }else if (userInf.isShopCodePlex) {
            Set<String> shopSt = userInf.shopSt;
            queryWhere+= ' And Rroom__r.ShopInfoRef__r.ShopCode__c in :shopSt';
        }
	// 2015/09/01 多店舗機能対応 END
        // 到着時刻順番で表示する
        String queryOrder = ' Order By Field4Cal__c asc ';
        // 2017/08/17 ルームインジケータ画面に、縦セルに表示項目をカスタマイズできるように改善対応 WGCH BEGIN
        //String queryStr = QueryLeadHeader + queryWhere + queryOrder;
        // 原有的ApiSet
        Set<String> apiSet = new  Set<String>();
        // 新追加的查询字段
        String roomExtLeadFieldApiStr = '';
        for(String apiItem : QueryLeadHeader.split(',')){
        	// 去掉前后空格 和 转成小写的 处理
        	apiSet.add(CommUtils.nullToBlank(apiItem.toLowerCase()));
        }
        for (String roomExtApi : roomExtLeadFieldApiLst) {
        	// 去重API处理
        	if(!apiSet.contains(roomExtApi.toLowerCase())) roomExtLeadFieldApiStr += ',' + roomExtApi; 
    	}
        String queryStr = 'Select ' + QueryLeadHeader + roomExtLeadFieldApiStr + ' From Lead__c '+ queryWhere + queryOrder;
        // 2017/08/17 ルームインジケータ画面に、縦セルに表示項目をカスタマイズできるように改善対応 WGCH END
System.debug(LoggingLevel.INFO, 'QueryLead:::' + queryStr); 

        // Map<RoomId, Lead>
        Map<Id, List<Lead__c>> roomLeadsMap = new Map<Id, List<Lead__c>>();
        Map<Id, Lead__c> roomLeadMap = new Map<Id, Lead__c>();
        // 現状のシステム時刻を取得する
        String nowTime = System.now().format('yyyyMMddHH:mm');
        // 画面から予約情報TOPに切り替え指定の場合
        
        // 開始日、終了日はSUBINDEXから取得、設定を行う
        List<Lead__c> existLeads = Database.query(queryStr);
        Set<String> subIdxSet = new Set<String>();
        for (Lead__c lead : existLeads) {
            // SUBINDEXのIDを格納する
            if(!CommUtils.isBlank(lead.LeadIndexSubId__c)) subIdxSet.add(lead.LeadIndexSubId__c);
            // １部屋に予約数統計する
            if (!roomLeadsMap.containsKey(lead.Rroom__c)) roomLeadsMap.put(lead.Rroom__c, new List<Lead__c>());
            roomLeadsMap.get(lead.Rroom__c).add(lead);
        }
        
        // 部屋単位に複数予約情報が存在する場合、該当予約の到着時刻と出発時刻を格納する
        // Map<部屋ID、List<到着時刻+','+出発時刻>>
        //roomTimesMap = new Map<Id, List<String>>();
        // 部屋毎、存在する部屋数設定を行う
        for (Id roomId : roomLeadsMap.keySet()) {
            List<Lead__c> leads = roomLeadsMap.get(roomId);
            // 所属する予約情報
            roomLeadsCount.put(roomId, leads.size());
            String times = '';
            // 所属する予約の時刻リストを設定する
            for (Lead__c lead : leads) {
                String timeStr = lead.EntryTime__c.format('yyyyMMdd') + lead.Field4__c + '||'
                                +lead.Departure__c.format('yyyyMMdd') + lead.Field3__c;
                times += timeStr + ',';
            }
            // 
            roomTimesMap.put(roomId, times.removeEnd(','));
        }
        
        Map<Id, LeadIndex__c> subIdxMap = new Map<Id, LeadIndex__c>();
        // 予約SUBINDEX関連情報を取得する
        for (LeadIndex__c subIdx : [select Id, DepartureDate__c from LeadIndex__c where id in :subIdxSet]) {
        	subIdxMap.put(subIdx.Id, subIdx);
        }
        // 画面からTOPに指定する場合
        // 画面から未設定する場合部屋の場合、システム時刻により、泊まる期間はシステム時刻比較、比較時刻期間外の場合、初期予約データ　または　最後の予約データを表示する
        topLeadIdSet = new Set<String>(CommUtils.nullToBlank(topLeadIdsHid).deleteWhitespace().removeEnd(',').split(','));

        //for (Lead__c lead : Database.query(queryStr)) {
        for (Lead__c lead : existLeads) {
            // 該当予約関連のSUBINDEX設定情報を設定する
            if (subIdxMap.containsKey(lead.LeadIndexSubId__c)) lead.LeadIndexRef__r = subIdxMap.get(lead.LeadIndexSubId__c);
            // すでに設定済みの場合、同じ部屋は以外の予約データは対象外
            if (roomLeadMap.containsKey(lead.Rroom__c)) continue;
            
            // 画面から個別予約情報はTOPに表示する設定
            if (topLeadIdSet.contains(String.valueOf(lead.id))) {
            	roomLeadMap.put(lead.Rroom__c, lead);
            } 
        }
        // 画面から個別指定以外の予約データに対して、システム時間は宿泊時間の予約情報を設定、画面に表示する
        for (Lead__c lead : existLeads) {
            // すでに設定済みの場合、同じ部屋は以外の予約データは対象外
            if (roomLeadMap.containsKey(lead.Rroom__c)) continue;
            // 画面から個別予約情報はTOPに表示する設定の場合
            // システム時刻は該当予約の到着時刻と出発時刻間の場合、該当予約は画面TOPに表示する
            String startDtime = lead.EntryTime__c.format('yyyyMMdd') + lead.Field4__c;
            String endDtime = lead.Departure__c.format('yyyyMMdd') + lead.Field3__c;
            if (startDtime <= nowTime && nowTime <= endDtime) {
                roomLeadMap.put(lead.Rroom__c, lead);
            }
        }
        // 部屋に表面に表示予約情報は未設定する場合、設定を行う
        for (Id roomId : roomLeadsMap.keySet()) {
            //　画面から個別指定される場合い
            if (roomLeadMap.containsKey(roomId)) continue;
            // 予約リストを取得する、システム時刻は初め到着時刻により、早い場合、最初の予約は画面に表示する、その以外の場合、最後の予約データは画面に表示する
            List<Lead__c> leads = roomLeadsMap.get(roomId);
            for (Lead__c lead : leads) {
                // システム時間により、次の予約情報を表示する
                String startDtime = lead.EntryTime__c.format('yyyyMMdd') + lead.Field4__c;
                if (startDtime >= nowTime ) {
                    roomLeadMap.put(roomId, lead);
                    break;
                }
            }
            // 最後の予約情報は画面へ表示する
            if (!roomLeadMap.containsKey(roomId)) {
                roomLeadMap.put(roomId, leads[leads.size()-1]);
            }
        }
        // 部屋単位の時間リスト情報を格納する
        
        return roomLeadMap;
    }
    /**
    * 予約に紐付く会計データの情報(会計済がどうか)を取得する
    **/
    private Map<Id, Boolean> getAccountedFlgMap(List<Lead__c> leads) {
    	Set<Id> leadIds = new Set<Id>();
    	for (Lead__c lead : leads) leadIds.add(lead.Id);//order by LastModifiedDate
    	List<AggregateResult> acountAccRs = [
    	                                    // 2017/09/10 印刷済みの判断条件を変更する「会計保存かつPDF印刷されたからPDF印刷されたへ変更」BEGIN
    	                                    // max(Field53__c)->max(id)
											select max(id) accountedTime, Relreserve__c leadId from AccountAcount__c 
											// 2017/09/10 印刷済みの判断条件を変更する「会計保存かつPDF印刷されたからPDF印刷されたへ変更」END
											where Relreserve__c in :leadIds 
												And Field39__c != :CommConst.ACC_TRADE_VOID 
												And IssueDate__c != null
											group by Relreserve__c];
    	//List<AccountAcount__c> acountAcountLst = [select id,Field53__c,AccountName__c,ContactName__c,AccountReceiptName__c,BillingCal__c,AccountProviso__c from AccountAcount__c where Relreserve__c = :leadId order by LastModifiedDate desc limit 1];
    	Map<Id, Boolean> isAccountedMap = new Map<Id, Boolean>();
    	for (AggregateResult avg : acountAccRs) {
    		Id leadId = (ID)avg.get('leadId');
    		//DateTime updateTime = DateTime.valueOf(avg.get('updateTime'));
    		// 時刻情報が存在する場合、会計済み認識する
    		Boolean isAccountedFlg = !CommUtils.isBlank((String)avg.get('accountedTime'));
    		isAccountedMap.put(leadId, isAccountedFlg);
    	}
    	return isAccountedMap;
    }
    // 2017/12/21 レジカードにサインしたのがルームインジケータでわかるように改善対応 zyz BEGIN
    private Map<Id, String> getGuestFlgMap(List<Lead__c> leads) {
    	Map<Id, String> isGuestMap = new Map<Id, String>();
    	// 2018/07/17 レジカードコード7の署名機能追加 zyz BEGIN
    	// 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz BEGIN
    	if((cashCode !='4' && cashCode !='5' && cashCode !='7' && cashCode !='8') || !isCashRegisterSignFlg) return isGuestMap;
    	// 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz END
    	// 2018/07/17 レジカードコード7の署名機能追加 zyz END
    	Set<Id> leadIds = new Set<Id>();
    	for (Lead__c lead : leads) leadIds.add(lead.Id);
    	List<Yadochou__c> yadochouLst = [select Id,Field1__c,Signature__c,PageSignature__c from Yadochou__c where Field1__c in :leadIds ];
    	for (Yadochou__c yado : yadochouLst) {
    		String isGuestFlg = 'false';
    		Id leadId = yado.Field1__c;
    		// 2018/07/17 レジカードコード7の署名機能追加 zyz BEGIN
    		// 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz BEGIN
			if((!CommUtils.isBlank(CommUtils.nullToBlank(yado.Signature__c)) && (cashCode !='7' || cashCode !='8')) || !CommUtils.isBlank(CommUtils.nullToBlank(yado.PageSignature__c))) {isGuestFlg = 'true';}
    		// 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz END
    		// 2018/07/17 レジカードコード7の署名機能追加 zyz END
    		isGuestMap.put(leadId, isGuestFlg);
    	}
    	return isGuestMap;
    }
    // 2017/12/21 レジカードにサインしたのがルームインジケータでわかるように改善対応 zyz END
    // 2020/02/29 小部屋機能改善 BY zyz BEGIN
    // 数据符合小部屋条件的map<leadIndexId,leadId> 
    private map<String,String> setLeadIndexMap{get;set;}
    // 2020/02/29 小部屋機能改善 BY zyz END
    // 2019/12/30 小部屋の作成 BY zyz BEGIN
    private Map<Id, Boolean> getSmallRoomMap(List<Lead__c> leads) {
    	Set<Id> leadIds = new Set<Id>();
    	Set<Id> leadIndexIds = new Set<Id>();
    	// 2020/02/29 小部屋機能改善 BY zyz BEGIN
    	// 用于小部屋主予约显示的特殊处理map<leadId,leadIndexId>
    	Map<String, String> leadRoomMap = new Map<String, String>();
    	// 2020/02/29 小部屋機能改善 BY zyz END
    	// 取得当前显示的予约数据ID
    	for (Lead__c lead : leads) {
    		leadIndexIds.add(lead.LeadIndexRef__c);
    		leadIds.add(lead.Id);
    		// 2020/02/29 小部屋機能改善 BY zyz BEGIN
    		// 只在主予约显示小部屋，子予约符合显示条件的处理
    		if (setLeadIndexMap.containsKey(lead.LeadIndexRef__c)) leadRoomMap.put(lead.Id,lead.LeadIndexRef__c);
    		// 2020/02/29 小部屋機能改善 BY zyz END
    	}
    	// 检索已做成小部屋主数据或者小部屋数据
    	Map<Id, Boolean> leadSmallRoomLMap = new Map<Id, Boolean>();
    	for (AggregateResult avgRs : [select ParentLeadId__c parentId,count(id) cnt from Lead__c
        	where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG And ParentLeadId__c in :leadIds And LeadIndexRef__c in :leadIndexIds
        	group by ParentLeadId__c]) {
            Integer cnt = CommUtils.nullToIntZero(avgRs.get('cnt'));
            if (cnt == 0) continue;
            Id relId = (ID)(avgRs.get('parentId'));
        	leadSmallRoomLMap.put(relId,true);
        }
    	// 2020/02/29 小部屋機能改善 BY zyz BEGIN
    	// 其他位置生成的数据是否符合已作成小部屋条件，显示小部屋作成
    	// 符合小部屋做成的数据的leadIndex集合
    	set<String> leadIndexlst = new set<String>();
    	// 获取XML设定条件
    	String RoomWhereStr = getXmlRoomWhere();
    	if(!CommUtils.isBlank(RoomWhereStr)){
	    	Integer cancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
	    	String AggregateStr = 'select Id,refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c,LeadIndexRef__c from Lead__c where CancelBool__c != : cancelFlg And Id in :leadIds And (LeadIndexRef__c in :leadIndexIds ';
	    	AggregateStr +=' And ('+ RoomWhereStr + ' )) ';
	    	list<Lead__c> Aggregatelst = DataBase.query(AggregateStr);
	    	for(lead__c lead: Aggregatelst){
	    		// 符合小部屋已做成数据
	    		if(!leadSmallRoomLMap.containsKey(lead.Id)) leadSmallRoomLMap.put(lead.Id,true);
	    		if (!leadIndexlst.contains(lead.LeadIndexRef__c)) leadIndexlst.add(lead.LeadIndexRef__c);
	    	}
    	}
    	// 小部屋图标只在主予约显示，且主予约不符合条件的特殊处理
    	for(String  leadId : leadRoomMap.keySet()){
    		String indexId = leadRoomMap.get(leadId);
    		if(leadIndexlst.contains(indexId)){
    			leadSmallRoomLMap.put(CommUtils.nullToBlank(setLeadIndexMap.get(indexId)),true);
    		}
    	}
    	// 2020/02/29 小部屋機能改善 BY zyz END
    	return leadSmallRoomLMap;

    }
    // 2019/12/30 小部屋の作成 BY zyz END
    // 2020/02/29 小部屋機能改善 BY zyz BEGIN
    // 主予约和子予约是否都显示小部屋处理
    private Map<Id, Boolean> getRoomFlgMap(List<Lead__c> leads) {
    	Set<Id> leadIds = new Set<Id>();
    	Set<Id> leadIndexIds = new Set<Id>();
    	// 取得当前显示的予约数据ID
    	for (Lead__c lead : leads) {
    		leadIndexIds.add(lead.LeadIndexRef__c);
    		leadIds.add(lead.Id);
    	}
    	// 检索已做成小部屋主数据或者小部屋数据
    	// 显示小部屋图标的集合
    	Map<Id, Boolean> leadRoomFlgMap = new Map<Id, Boolean>();
    	// Map<Id, String> leadCodeMap = new Map<Id, String>(); 
    	// 获取XML设定条件
    	String RoomWhereStr = getXmlRoomWhere();
    	Integer cancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
    	String AggregateStr = 'select Id,Name,refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c,LeadIndexSubId__c,LeadIndexRef__r.Id,LeadIndexRef__r.ParentFlg__c from Lead__c where CancelBool__c != : cancelFlg And Id in :leadIds And (LeadIndexRef__c in :leadIndexIds ';
    	if(!CommUtils.isBlank(RoomWhereStr)) AggregateStr +=' Or '+ RoomWhereStr;
    	AggregateStr +=' ) order by LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c ';
    	list<Lead__c> Aggregatelst = DataBase.query(AggregateStr);
    	// 主予约显示只对应一个处理的set
    	set<id> leadIndexSet = new set<id>();
    	// 数据符合小部屋条件的map<leadIndexId,leadId> 
    	setLeadIndexMap = new map<String,String>();
    	// 处理当前符合条件的数据
    	for(lead__c lead: Aggregatelst){
    		// 获取予约数据的房型code
    		String leadCode = CommUtils.nullToBlank(lead.refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c);
    		// 主予约显示控制，默认值为true
    		// Boolean roomFlg = false;
    		Boolean roomFlg = true;

    		if(!CommUtils.isBlank(leadCode)) {
    			roomFlg = roomFlgMap.containsKey(leadCode) ? boolean.valueOf(roomFlgMap.get(leadCode)) : defRoomFlg;
    		} else {
    			roomFlg = defRoomFlg;
    		}
    		// 主予约显示
    		if(roomFlg){
    			// 只处理一笔数据
    			if (leadIndexSet.contains(lead.LeadIndexRef__r.Id)) continue;
    			leadIndexSet.add(lead.LeadIndexRef__r.Id);
    			if (!leadRoomFlgMap.containsKey(lead.Id)) leadRoomFlgMap.put(lead.Id,true);
    			// 数据符合小部屋的主予约数据，用于特殊处理
    			if (!setLeadIndexMap.containsKey(lead.LeadIndexRef__r.Id)) setLeadIndexMap.put(lead.LeadIndexRef__r.Id,lead.Id);
    		// 全部数据都显示
    		}else {
    			if (!leadRoomFlgMap.containsKey(lead.Id)) leadRoomFlgMap.put(lead.Id,true);
    		}
    	}
    	return leadRoomFlgMap;
    }
    // 2020/02/29 小部屋機能改善 BY zyz END
        
    /**
    * 予約データの作成
    **/
    public PageReference bookingCreate(){
    	// 事前チェックを行う
		if (!preBookingCreate()) {
			// 2018/06/06 报错以后予約信息中房间被清空 by zy BEGIN
            Lead__c cloneLead = newLead.clone();
            // 2018/06/06 报错以后予約信息中房间被清空 by zy END
			// 2018/05/14 报错以后房间消失问题对应 by zy BEGIN
		    refreshPage();
		    // 2018/05/14 报错以后房间消失问题对应 by zy END
		    newLead = cloneLead;
			return null;
		}

  		// DB操作を行う
  		Savepoint sp = Database.setSavepoint();
  		try{
  		// Hidden項目から到着日を取得する
  		//Date defaultDate = Date.parse(startDays);
  		Date defaultDate = CommUtils.stringToDate(startDays);
  		/* 2013/01/21 到着時間と出発時間、設定によて、自動取得、設定を行う */
        Datetime defCheInDt = Datetime.newInstance(defaultDate, converHHMMtoTime(newLead.Field4__c));
        Datetime defCheOutDt = Datetime.newInstance(defaultDate.addDays(1), converHHMMtoTime(newLead.Field3__c));
    	// 2013/10/07お客様情報を自動登録機能追加する
  		upsertContact();
  		
  		// 挿入用リスト
  		List<Lead__c> insList = new List<Lead__c>();
  		// 予約受付日を処理当日に指定
  		newLead.ReservedDate__c = Datetime.now();
  		//newLead.Rroom__c = bookingRoomId;
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
		newLeadIndex.Rooms__c = 1;
		newLeadIndex.LeadName__c = newLead.name;
		newLeadIndex.RoomTypeRef__c = newLead.refTypeOfRooms__c;	// 部屋タイプ
		// 予約チャネル
		newLeadIndex.Channel__c = newLead.Field2__c;
		// セグメント
		newLeadIndex.Segment__c = newLead.Segment__c;
		// 支払方法
		newLeadIndex.Payment__c = newLead.Field315__c;
		// 特記事項
		newLeadIndex.Comment__c = newLead.Comment3__c;
		insert newLeadIndex;

		newLead.LeadIndexRef__c = newLeadIndex.Id;
		// 2016/12/07 ルームインジケータ新規後一画面へ遷移 BEGIN by zh
        indexId = newLead.LeadIndexRef__c ;
        // 2016/12/07 ルームインジケータ新規後一画面へ遷移 END by zh
		// 予約インデックス情報を作成する 2012/08/23 ADD END
  		// 予約の内容を作成する
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
  			// 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
        	//newLead.EntryTime__c = defCheInDt.addDays(0);
  			//newLead.Departure__c = defCheInDt.addDays(0);
        	Datetime curDatetime = defCheInDt.addDays(0);
            newLead.EntryTime__c = curDatetime;
            Datetime curChkoutTime = Datetime.newInstance(curDatetime.date(), converHHMMtoTime(newLead.Field3__c));
            newLead.Departure__c = curChkoutTime;
            // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
			//newLead.refTypeOfRooms__c = roomType;
  			Lead__c cloneLead =  newLead.clone(false, true);
  			// 2013/07/20 UPDATE
  			cloneLead.RoomGroupNo__c = 0;
  			insList.add(cloneLead);
		} else {
			// 1泊以上場合
	  		for(Integer i = 0; i < staysNums; i ++){
	  			//泊目
	  			if (staysNums > 1) newLead.name = String.valueOf(staysNums) + '-' + (i+1) + Label.CONST_008_0110 + ' ' + leadName;
	  			newLead.EntryTime__c = defCheInDt.addDays(i);
	  			newLead.Departure__c = defCheOutDt.addDays(i);
	  			// 到着時刻
	  			newLead.Field4__c = newLeadIndex.EntryTime__c;//newLead.EntryTime__c.format('HH:mm');
	  			// 出発時刻
	  			newLead.FIeld3__c = newLeadIndex.DepartureTime__c;//newLead.Departure__c.format('HH:mm');
	  			//newLead.refTypeOfRooms__c = roomType;
  			   	Lead__c cloneLead =  newLead.clone(false, true);
	  			// 2013/07/20 UPDATE
	  			cloneLead.RoomGroupNo__c = 0;
	  			insList.add(cloneLead);
	  		}

		}

  			// 2012/12/22 WSQ ADD
  			// SUBINDEX自動作成
  			CommLogicProcess logic = new CommLogicProcess();
  			logic.autoCreateIndexSub(insList);
  			// データの挿入
  			insert insList;
  			// 料金表情報にて、予約情報見積もり明細自動設定を行う
  			autoCreateBookingEstItems(insList, newLeadIndex.EntryDate__c,newLeadIndex.DepartureDate__c);
  			// 画面データを再構築する
  			gotoDate();
  		}catch (Exception e){
  			// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 BEGIN
			String errMsg = e.getMessage();
			if(!CommUtils.isFieldValidationMessage(errMsg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
			// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 END
            Database.rollback(sp);
            // 2018/06/06 报错以后予約信息中房间被清空 by zy BEGIN
            Lead__c cloneLead = newLead.clone();
            // 2018/06/06 报错以后予約信息中房间被清空 by zy END
            // 2018/05/14 报错以后房间消失问题对应 by zy BEGIN
            refreshPage();
            // 2018/05/14 报错以后房间消失问题对应 by zy END
            newLead = cloneLead;
            bookingCreateOK = false;
            return null;
  		}
  		// 2013/06/24 ADD BEGIN
  		// Data Create OK
  		bookingCreateOK = true;
  		// 設定情報をクリアする【注意：クリアしないと、常にContact　IDを更新されない】
  		//newContact = new Contact();
  		initBookingFormInfo();
  		
    	return null;
    }
   	// 予約登録FORM初期化処理
	private void initBookingFormInfo() {
        contactName = '';
        // 2016/12/28 连接plan页面替换标准页面  begin by wx
        planName = '';
        // 2016/12/28 连接plan页面替换标准页面  end by wx
		// 2020/06/15 予約ポップのデフォルト字段エラー修正 by zy BEGIN
		// newLead = new Lead__c();
		newLead = (Lead__c)Lead__c.sObjectType.newSObject(leadBookingRecTypeId, true);
		// 2020/06/15 予約ポップのデフォルト字段エラー修正 by zy END
		newContact = new Contact();
		// 2020/06/15 予約ポップのデフォルト字段エラー修正 by zy BEGIN
		// 予約のレコードタイプ
		// newLead.RecordTypeId = leadBookingRecTypeId;
		// 2020/06/15 予約ポップのデフォルト字段エラー修正 by zy END
        // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
        // チェックイン時刻、チェックアウト時刻
        //newLead.Field4__c = CommConst.DEF_CHECKIN_TIME;
        //newLead.Field3__c = CommConst.DEF_CHECKOT_TIME;
    	ShopInfoUtil.ShopLeadInfo shopInfo = ShopInfoUtil.getShopDefInfo(branchShopNm);
    	newLead.Field4__c = shopInfo.defCheckInTimeStr;
		newLead.Field3__c = shopInfo.defCheckOtTimeStr;
		staysNums = shopInfo.defStayNums;
		// 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
		// 2016/12/12 zyz CTI予約 BEGIN
		String ctiContactId = Apexpages.currentpage().getparameters().get('contactid');
		String ctiContactNm = Apexpages.currentpage().getparameters().get('contactnm');
		ctiContactInf = CommUtils.isBlank(ctiContactId) ? '' : (ctiContactNm + '#' + ctiContactId);
        // 2016/12/12 zyz CTI予約 END
    	//見積もり明細の初期化処理
    	// 2016/10/12 見積明細設定機能対応 BEGIN by zh
    	initBookEstItem();
    	// 2016/10/12 見積明細設定機能対応 END by zh
	}
	
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
  	// プランなしの予約データに対して、料金表にて、見積もり明細データを作成する
  	@TestVisible private void autoCreateBookingEstItems(List<Lead__c> leads, Date stDate, Date edDat) {
  		// 料金情報設定用商品が非存在する場合、処理中止
  		//if (roomPriceInfo == null) return;
  		// 2016/10/12 見積明細設定機能対応 BEGIN by zh
  		refreshBookingOrder();
  		// 2016/10/12 見積明細設定機能対応 END by zh
  		// 予約の料金表情報を設定する
  		List<Lead__c> targets = new List<Lead__c>();
	  		for (Lead__c lead : leads) {
	  			//if (CommConst.APPOTION_LEADSPLIT_DIV_CODE == CommConst.APPOTION_LEADSPLIT_DIV_CODE_SPLIT) return;
	  			// 予約人数は０の場合、見積もり明細作成対象外
	  			// プラン未設定 && 予約人数は０以上場合、室料の見積もり明細を自動作成する
	  			// 2016/12/28 连接plan页面替换标准页面  begin by wx
	     		//if (lead.Field310__c == null && CommUtils.nullToZero(lead.StayPersons__c) > 0) {
	     		if (CommUtils.isBlank(lead.Field310__c)) { //  && CommUtils.nullToZero(lead.StayPersons__c) > 0
	     		// 2016/12/28 连接plan页面替换标准页面  end by wx
	  				targets.add(lead);
	  		}
  		}
  		// 自動料金設定する予約データがない場合、処理終了
  		if (targets.isEmpty()) return;	
  		// 2016/10/12 見積明細設定機能対応 BEGIN by zh
        List<BookingEstimateItem__c> updLst = new List<BookingEstimateItem__c> ();
        // 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
	  	// 处理预约信息数据集合分类
	  	CommLogicProcess.ProLeadInfo proLead = CommLogicProcess.getProLeadInfo(targets);
        // 2020/07/30 入湯税の自動入力機能について改善 WGCH END
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
                //obj.sobj.rowNo__c = idx;
                // 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
                if(!CommUtils.isBlank(obj.bTaxToPlanRowIndex)) proLead.proBookEst.proAccMstIdSet.add(obj.sobj.refAccountMaster__c);
                // 2020/07/30 入湯税の自動入力機能について改善 WGCH END
                updLst.add(obj.sobj);
                // 2014/08/05 宿泊税自動設定機能外す END
                //idx++;
            }
        }
  		// 2016/10/12 見積明細設定機能対応 END by zh
		// 2014/01/27 料金自動設定用商品情報を取得する
	  	AccountMaster__c roomPriceInfo = null;
	  	String roomPriceProdName = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomPriceProdName__c);
	  	if (!CommUtils.isBlank(roomPriceProdName)) {
			//List<AccountMaster__c> accMsts = [select Id, Name  From AccountMaster__c Where Name = :roomPriceProdName limit 1];
			List<AccountMaster__c> accMsts = ProductItemUtils.getRoomRateProduct(roomPriceProdName);
			if (!accMsts.isEmpty()) roomPriceInfo = accMsts[0];
	  	}
		// 料金情報設定用商品が非存在する場合、処理中止
		// 2016/10/12 見積明細設定機能対応 BEGIN by zh
  		//if (roomPriceInfo == null) return;
  		// 2016/10/12 見積明細設定機能対応 END by zh
  		// これから、料金表設定情報にて、見積もり明細情報を作成する
  		// 店舗単位の期間範囲のTier情報を取得する
  		// 見積明細リストに有効な明細が非存在　OR　旧レイアウトに見積明細非表示の場合
        // 2016/10/12 見積明細設定機能対応 BEGIN by zh
        if (updLst.isEmpty()) {
        // 料金情報設定用商品が非存在する場合、処理中止
        if (roomPriceInfo == null) return;
		// 2016/10/12 見積明細設定機能対応 END by zh
		// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　BEGIN
		String queryRRDetailHeader = ' Select Tier__c, ShopInfoRef__c, ShopInfoRef__r.ShopCode__c,PriceSetupDate__c,SearchKey__c From RackRateTableDetail__c ';
		// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　END
		String queryRRDetailString = queryRRDetailHeader + ' Where PriceSetupDate__c >=:stDate And PriceSetupDate__c <= :edDat ';
		// 店舗条件
		// 2015/09/01 多店舗機能対応 BEGIN
			// 2018/05/11 複数店舗を選択表示できる機能対応 BEGIN
			list<string> mulitiSpcd = getMulitSpCd();
			if (mulitiSpcd.size() > 1) {
	        		queryRRDetailString+= ' And ShopInfoRef__r.ShopCode__c  in :mulitiSpcd';
			}
			else if (!CommUtils.isBlank(branchShopNm)) {
			// 2018/05/11 複数店舗を選択表示できる機能対応 END
            queryRRDetailString += ' And ShopInfoRef__r.ShopCode__c = :branchShopNm ';
        }else if (userInf.isShopCodePlex) {
            Set<String> shopSt = userInf.shopSt;
            queryRRDetailString+= ' And ShopInfoRef__r.ShopCode__c in :shopSt';
        }
		// 2015/09/01 多店舗機能対応 END
		// 該当期間のTIER設定配列を格納する
		// 期間単位のTier情報を取得する
		// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　BEGIN
		RackRateUtils.RackDetailUtils rackDetail = RackRateUtils.getRackDetaiInfo(DataBase.query(queryRRDetailString));
        Set<String> tierSet = rackDetail.tierSet;
        // 2018/03/27 店舗なしの不具合改修 BEGIN
        Id shopId = (shopInfoMap.containsKey(branchShopNm)) ? shopInfoMap.get(branchShopNm).Id : null;
        // 2018/03/27 店舗なしの不具合改修 END
        /*
		Map<Date, String> setupTierMap = new Map<Date, String>();
		Set<String> tierSet = new Set<String>();
			
		// 支店コード_日付/TIER
		for (RackRateTableDetail__c detail : DataBase.query(queryRRDetailString)) {
			//String key = CommUtils.nullToBlank(branchShopNm) + '_' + detail.PriceSetupDate__c;
			setupTierMap.put(detail.PriceSetupDate__c, detail.Tier__c);
			tierSet.add(detail.Tier__c);
		}*/
		// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　END
		// 料金表からDefaultの料金情報を取得する
		Id roomTypeId = newLead.refTypeOfRooms__c;
		
		// 料金表からTier関連金額を取得する
  		String defTier = getDefTier(branchShopNm);
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
  			// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　BEGIN
	  		//String tierKey = setupTierMap.containsKey(keyDate) ? setupTierMap.get(keyDate) : defTier;
	  		String tierKey = rackDetail.getCurTier(keyDate,shopId,roomTypeId);
            if (CommUtils.isBlank(tierKey)) tierKey = defTier;
            // 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　END
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
  		if (!insertEstItems.isEmpty()) insert insertEstItems;
	  	// 2016/10/12 見積明細設定機能対応 BEGIN by zh
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
                    // 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
                    if(CommLogicProcess.proBathTaxAccMst(proLead, lead, cloneItem, staysNums)) continue;
                    // 2020/07/30 入湯税の自動入力機能について改善 WGCH END
                    insLst.add(cloneItem);
                }
            }
            if (!insLst.isEmpty()) insert insLst;
       }
       // 2016/10/12 見積明細設定機能対応 END by zh
  	}
  	private String getDefTier(String shopCd) {
  		
		if (shopInfoMap.containsKey(shopCd)) {
			return 	CommUtils.isBLank((shopInfoMap.get(shopCd)).TierDefault__c) 
					? CommUtils.nullToBlank( CommDefine__c.getOrgDefaults().RackRateTableTierDefault__c )
					: CommUtils.nullToBlank( (shopInfoMap.get(shopCd)).TierDefault__c );
		} else {
			return CommUtils.nullToBlank( CommDefine__c.getOrgDefaults().RackRateTableTierDefault__c );
		}
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
			List<String> splitContactFields = contactInserFields.split(',');
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
    // データ登録の事前チェック
  	private Boolean preBookingCreate() {
  		// 処理に必須な項目が未入力の場合、処理を中止する
  		// お客様/予約名/予約チャネル
		// 2017/01/25 新規画面の項目自定義機能　by　zy　BEGIN
  		/*if((CommUtils.isBlank(newLead.Relcontact__c) && CommUtils.isBlank(contactName) ) ||
  			CommUtils.isBlank(newLead.Name) ||
  			CommUtils.isBlank(newLead.Field2__c) ||
  			newLead.StayPersons__c == null) {
  			//必須項目を入力してください。
  			Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_008_0106));
  			return false;
  		}*/	
		Contact curContact =  CommLogicProcess.getOrInsertTempContact();
		if (CommUtils.isBlank(newLead.Relcontact__c) && CommUtils.isBlank(contactName)) {
			 newContact.id = curContact.id;
		}
		
		if (CommUtils.isBlank(newLead.Name)){
			newLead.Name = curContact.name;
		}
//system.debug(logginglevel.info,'newLead.Name:::' + newLead.Name);
		//CommUtils.isBlank(newLead.Field2__c) ||
  		if(  newLead.StayPersons__c == null) {
  			//必須項目を入力してください。
  			Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_005_0075));
  			return false;
  		}
  		// 2017/01/25 新規画面の項目自定義機能　by　zy　END
  		// 日帰りの場合、到着日と出発日の時刻チェックを行う
  		if (staysNums == 0) {
  			// 2013/09/16 TIME:[H:M]書式対応ため、下記処理を追加する
  			Time startTime = CommUtils.stringToTime(newLead.Field4__c);
  			Time endTime = CommUtils.stringToTime(newLead.Field3__c);
  			//if (newLead.Field4__c >= newLead.Field3__c) {
  			if (startTime >= endTime) {
  				//出発時刻には到着時刻以降の時刻を指定して下さい
  				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_008_0107));
  				return false;
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
    /**
    * 部屋故障状態を読み込む
    **/
    //private Set<Id> queryBadRoomSet () {
    private Map<Id,List<RoomsStatus__c>> queryBadRoomSet () {
    	/* 2014/12/08 部屋ステータス故障情報を取得関数は共通クラスに集める
    	Set<Id> badRoomSet = new Set<Id>();
        String queryHd = CommSqlUtils.generateQueryString('RoomsStatus__c');
        String queryWhere = ' where Status__c = \'' + String.escapeSingleQuotes(CommConst.ROOM_ST_TYPE_BED) + '\'';
        queryWhere += ' And Result__c != \'' + String.escapeSingleQuotes(CommConst.ROOM_ST_TYPE_BED_FIN) + '\'';
        queryWhere += ' And StatusBeginDate__c <= ' + String.valueOf(processDate);
        queryWhere += ' And StatusEndDate__c >= ' + String.valueOf(processDate);
        String queryStr = queryHd + queryWhere;
        for (RoomsStatus__c roomSt : Database.query(queryStr)) {
            badRoomSet.add(roomSt.RoomRef__c);
        }
        return badRoomSet;
        */
        Map<Id,List<RoomsStatus__c>> roomStatusMap = new Map<Id,List<RoomsStatus__c>>();
        List<RoomsStatus__c> roomStatus = (new RoomStatusManager()).queryBadRoomList(processDate, processDate);
        for(RoomsStatus__c rs : roomStatus) {
        	if(!roomStatusMap.containsKey(rs.RoomRef__c)) roomStatusMap.put(rs.RoomRef__c, new List<RoomsStatus__c>());
			roomStatusMap.get(rs.RoomRef__c).add(rs);
        }
        return roomStatusMap;
    }
    
    // ボタン「翌日」の処理
    public void toNext() {
        //processDate = processDate.addDays(1);
    	processDate = getProcessDate(getInputDate(1), isShowToday);
        //setDateField(processDate);
        topLeadIdsHid = '';
        queryRoomStatus();
		// タイムテーブル情報を更新する
    	refreshTimeTableInfo();
    }

    public void toToday() {
    	// 2019/09/15 指定日自动记忆機能対応 WGCH BEGIN
    	toTodayFlg = true;
    	// 2019/09/15 指定日自动记忆機能対応 WGCH END
    	//processDate = Date.today();
    	selectDate.Checkinday__c = null;		// 今日の場合、当日の飛びますので、指定日は初期化する
    	processDate = getProcessDate(getInputDate(0), isShowToday);
        topLeadIdsHid = '';
    	//setDateField(processDate);
    	queryRoomStatus();
		// タイムテーブル情報を更新する
    	refreshTimeTableInfo();
    }

    // ボタン「前日」の処理
    public void toPrev(){
        //processDate = processDate.addDays(-1);
        processDate = getProcessDate(getInputDate(-1), isShowToday);
        topLeadIdsHid = '';
        //setDateField(processDate);
        queryRoomStatus();
		// タイムテーブル情報を更新する
    	refreshTimeTableInfo();
    }
    public BookingTimeTable__c selectDate{get; private set;}
    // 年/月/日を選択する場合
    public void gotoDate() {
    	//selectDate.Checkinday__c = selectDate.Checkinday__c == null ? Date.today() : selectDate.Checkinday__c;
        //processDate = getProcessDate(selectDate.Checkinday__c, isShowToday);
        processDate = getProcessDate(getInputDate(0) , isShowToday);
        // 最新情報を取得する
        queryRoomStatus();
		// タイムテーブル情報を更新する
    	refreshTimeTableInfo();
    }
    // 指定日を取得する
    private Date getInputDate(Integer days) {
    	// 2019/09/15 指定日自动记忆機能対応 WGCH BEGIN
    	if(isChkInDayFlg && !toTodayFlg && selectDate.Checkinday__c == null){
    		Map<string,string> userConfigMap = UserConfigCompCtrl.getKrepConfig(userId, '');
			// 指定日KEY
			String checkInDayKey = UserConfigCompCtrl.KREP_SUBTYPE.CHECKINDAY.name();
			if(userConfigMap.containsKey(checkInDayKey)){
				String queryDt = userConfigMap.get(checkInDayKey); // 记忆指定日
				selectDate.Checkinday__c = (String.isEmpty(queryDt)) ? Date.today() : CommUtils.stringToDate(queryDt);
			}
    	}
    	toTodayFlg = false;
    	// 2019/09/15 指定日自动记忆機能対応 WGCH END
    	selectDate.Checkinday__c = (selectDate.Checkinday__c == null ? Date.today() : selectDate.Checkinday__c).addDays(days);
    	return selectDate.Checkinday__c;
    }
    
    // タイムテーブル情報を更新する
    private void refreshTimeTableInfo() {
    	// タイムテーブル情報を表示・非表示制御する
    	if (!isShowTimeTable) return;
    	// 処理日を設定する
    	dayInfo.selectDate.Checkinday__c = getInputDate(0);
    	// 支店と部屋タイプを設定する
    	dayInfo.branchShopNm = branchShopNm;
		// 2019/07/31 JINYABUG-2000 bug fix by zy BEGIN
    	// dayInfo.gotoDate();    
		dayInfo.refreshBranchShopInfo();
		// 2019/07/31 JINYABUG-2000 bug fix by zy END
    }
    // 2018/05/11 複数店舗を選択表示できる機能対応 BEGIN
    public List<String> getMulitSpCd() {
		// 選択対象
        List<String> mSpCds = commUtils.nullToBlank(multiDepartCds).split(',');
        // 1店舗の場合、複数選択機能有効でも、複数選択できないように対応
        if (!mSpCds.isEmpty() && multiSelectCompFlg) branchShopNm = mSpCds[0];
        return mSpCds;
    }
    public List<String> getMsgCompSpLst() {
    	// 店舗別ごと連絡事項機能不要の場合
    	if (!MessageShopCodeDivFlg) {
    		List<String> rsList = new List<String>();
    		rsList.add('');
    		return rsList;
    	} 
    	// 多店舗選択じゃない場合
    	else if (!multiSelectCompFlg) {
    		List<String> rsList = new List<String>();
    		rsList.add(branchShopNm);
    		return rsList;
    	}
    	else {
    		return getMulitSpCd();
    	}
    }
    // 2018/05/11 複数店舗を選択表示できる機能対応 END
    // 支店コードにより、支店関連の情報を取得する
    public void refreshBranShop() {
    	// 指定設定情報により、店舗色設定を行う
        // COLOR制御設定情報を取得する
        // 2019/02/28 複数店舗を選択表示できる機能BUG修正 WGCH BEGIN
        /*
        setBranShopColorInfo();
        */
        // 2019/02/28 複数店舗を選択表示できる機能BUG修正 WGCH END
        // 支店関連の部屋タイプ一覧を取得する
    	setInitRoomTypeLst();
    	// 2019/02/28 複数店舗を選択表示できる機能BUG修正 WGCH BEGIN
    	// 指定設定情報により、店舗色設定を行う
        // COLOR制御設定情報を取得する
    	setBranShopColorInfo();
    	// 2019/02/28 複数店舗を選択表示できる機能BUG修正 WGCH END
        // 2016/01/28 予約ステータス/部屋ステータス表示の切替できる対応 BEGIN
        initColorInfo();
        // 2016/01/28 予約ステータス/部屋ステータス表示の切替できる対応 END
    	//gotoDate();
    	//selectDate.Checkinday__c = selectDate.Checkinday__c == null ? Date.today() : selectDate.Checkinday__c;
        //processDate = selectDate.Checkinday__c;
		processDate = getProcessDate(getInputDate(0) , isShowToday);
		// 2020/09/30 当日チェックアウトの日帰り予約がチェックイン後にルームチェンジできなくなる不具合の解消 by zy BEGIN
        refeshDomNode();
		// 2020/09/30 当日チェックアウトの日帰り予約がチェックイン後にルームチェンジできなくなる不具合の解消 by zy END
        queryRoomStatus();
        // 2020/09/30 当日チェックアウトの日帰り予約がチェックイン後にルームチェンジできなくなる不具合の解消 by zy BEGIN
        // XML___wgch 2016/11/16 BEGIN
        // refeshDomNode();
		// XML___wgch 2016/11/16 END
		// 2020/09/30 当日チェックアウトの日帰り予約がチェックイン後にルームチェンジできなくなる不具合の解消 by zy END
        // 2017/01/25 新規画面の項目自定義機能　by　zy BEGIN
        loadInsertWindow();
        // 2017/01/25 新規画面の項目自定義機能　by　zy　END
        // 2017/09/18  会計一括印刷機能  WGCH BEGIN
        initAccPrnShowBtnFlg(branchShopNm);
        // 2017/09/18  会計一括印刷機能  WGCH END
		// 2019/07/31 ルームインジケータの店舗の初期値をallにしたいとの要望です by zy BEGIN
		saveCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.SPCD.name(), '',
			JSON.serialize(CommUtils.nullToBlank(multiSelectCompFlg ? multiDepartCds : branchShopNm)));
    	// 2019/07/31 ルームインジケータの店舗の初期値をallにしたいとの要望です by zy END
    	// タイムテーブル情報を表示・非表示制御する
    	if (!isShowTimeTable) return;
    	// 処理日を設定する
    	dayInfo.selectDate.Checkinday__c = getInputDate(0);
    	// 支店と部屋タイプを設定する
    	dayInfo.branchShopNm = branchShopNm; 	
    	// タイムテーブル情報を更新する
    	dayInfo.refreshBranchShopInfo();
    }
    
	/**
	* 日付の期間切替制御
	* 当日の場合、チェックイン、チェックアウトボタン表示制御
	**/
	public void isShowTodayAction() {
		// 画面REFRESH切替する
    	processDate = getProcessDate(getInputDate(0) , isShowToday);
        //setDateField(processDate);
        queryRoomStatus();
	}
	
    // 業務ロジック関連日付設定を行う
    /* 2013/11/06 DELETE
    private void setDateField(Date currDate) {
    	// 検索条件：日付連動設定
    	selectDate.Checkinday__c = currDate;
        // 営業開始時間から営業終了時間設定を行う
        //beginBusinessTime = DateTime.newInstance(currDate,Time.newInstance(CONST_BUSNIESS_TIME, 0, 0, 0));
        //endBusinessTime = beginBusinessTime.addHours(24);
    }*/
    global class MsgItem {
    	public MsgItem() {
    		infMsg = '';
    		errMsg = '';
    	}
    	public String infMsg{get;set;}
    	public String errMsg{get;set;}
    	public Boolean isEmptyMsg{get{return String.isEmpty(infMsg) && String.isEmpty(errMsg);}}
    }
	// 各エリアの部屋情報
	global class AreaRoomInfo {
		public AreaRoomInfo(String pArea) {
			areaName = CommUtils.nullToBlank(pArea);
			floorRoomLst = new List<FloorRoomInfo>();
			//index = pIndex;
		}
		public void addFoorRoomInfo(FloorRoomInfo floor) {
			floorRoomLst.add(floor);
		}
		public String areaName{get; private set;}
		// 場所に最大フロア数
		public Integer maxFloors{get{return floorRoomLst.size();}}
		public List<FloorRoomInfo> floorRoomLst{get; private set;}
		//public Integer index{get; private set;}
	}

    // OneFloorの部屋情報
    global class FloorRoomInfo {
    	public FloorRoomInfo() {
    		roomLst = new List<RoomInfo>();
    		//index = pIndex;
    	}
    	public void addRoom(RoomInfo r) {
    		roomLst.add(r);
    	}
    	public String floorName{get{return CommUtils.nullToBlank(roomLst[0].sobj.Floor__c); }}
    	public List<RoomInfo> roomLst{get; private set;}
    	// 2018/05/10 レスバンス15M超出修正　by　zy BEGIN
    	public Integer[] blankSize{get;set;}
    	// 2018/05/10 レスバンス15M超出修正　by　zy END
    	// 2017/12/22 画面フィルター機能追加　by　zy　BEGIN
    	public String cssClass{get;set;}
    	// 2017/12/22 画面フィルター機能追加　by　zy　END
    	//public Integer index{get; private set;}
    }
    // 部屋ステータス照会情報
    global class PopupWinInfo {
    	// 予約名
    	public String leadId{get; set;}
    	public String leadName{get; set;}
    	// お客様
    	public String customId{get; set;}
    	public String customName{get; set;}
    	// お客様ステータス
    	public String customStatus{get; set;}
    	// 到着日
    	//public Date entryDate{get; set;}
    	public String entryDate{get; set;}
    	// 到着時刻
    	public String entryTime{get; set;}
    	// 出発日
    	//public Date departureDate{get; set;}
    	public String departureDate{get; set;}
    	// 出発時刻
    	public String departureTime{get; set;}
    	// 予約人数
    	public Decimal leadPeopleNum {get ;set;}
    	public Decimal orgLeadPeopleNum {get ;set;}
    	// 予約チャネル
    	public String leadChannel{get; set;}
    	// プラン
    	public String leadPlan{get; set;}
    	// 部屋
    	public String leadRoom{get; set;}
    	public String leadRoomId{get; set;}
    	// 特記事項
    	public String leadMemo{get; set;}
    	// 会計ID
    	public String accountId{get; set;}
    	// 2017/05/12 部屋詳細情報画面レジカード機能対応 zyz BEGIN
    	public String yadoId{get; set;}
    	// 2017/05/12 部屋詳細情報画面レジカード機能対応 zyz END
    	// 泊数
    	public Decimal nights{get;set;}
    	public Decimal orgNights{get;set;}
    	
    	// チェックインありフラグ
    	public Boolean checkInFlg{get;set;}
    	public String leadIndexNo{get;set;}
    	public String leadIndexId{get;set;}
    	// 会計済み標識フラグ
    	public Boolean isAccountedFlg{get;set;}
    	// 会計書開くURL情報を格納する
    	public String openAccPdfUrl{get;set;}
    	// 該当予約の部屋はＢＬＯＣＫされている
    	public Boolean isBlocked{get;set;}
		// XML___wgch 2016/11/16 BEGIN	
    	public Lead__c leadObj{get;set;}
    	public Contact contactObj{get;set;}
    	public String Comment3{get;set;}
		// XML___wgch 2016/11/16 END
		// 2019/12/30 名前か電話番号のどちらかだけ一致するお客様がすでに存在する BY zyz BEGIN
		// 顾客名和电话重复的顾客数据
		public list<Contact> conLst{get;set;}
		// 2019/12/30 名前か電話番号のどちらかだけ一致するお客様がすでに存在する BY zyz END
    }
    global class LeadInfo{
        public LeadInfo(Lead__c lead){
            checkoutTime = lead.Field3__c;
            checkinTime = lead.Field4__c;
            leadName = lead.name;
            guestName = lead.Relcontact__r.name;
            roomNo = lead.Rroom__r.Name;
            roomId = lead.Rroom__c;
            leadId = lead.id;
            guestId = lead.Relcontact__c;
        }
        public String roomId;
        public String checkoutTime;
        public String checkinTime;
        public String leadName;
        public String guestName;
        public String roomNo;
        public String leadId;
        public String guestId;
    }
    
    // 人数表示情報
    //private static final String CONST_STAYPERSONS_ADULTS = '$_STAYPERSON_$名（男:$_MANS_$ 女:$_FEMALE_$$_CHILDS_$）';
    private static final String CONST_STAYPERSONS_ADULTS = '$_STAYPERSON_$'+ Label.CONST_008_0117 +'（'+ Label.CONST_008_0118 +'$_MANS_$ '+ Label.CONST_008_0119 +'$_FEMALE_$$_CHILDS_$）';
    //private static final String CONST_STAYPERSONS_CHILDS = '子供:$_CHILDREN_$名（A:$_CHILDA_$, B:$_CHILDB_$, C:$_CHILDC_$, D:$_CHILDD_$$_CHILDE_$$_CHILDF_$）';
    private static final String CONST_STAYPERSONS_CHILDS = Label.CONST_008_0120 +'$_CHILDREN_$'+ Label.CONST_008_0117 +'（A:$_CHILDA_$, B:$_CHILDB_$, C:$_CHILDC_$, D:$_CHILDD_$$_CHILDE_$$_CHILDF_$）';
    // 部屋情報維持する
    global class RoomInfo {
    	public RoomInfo(){}
    	public RoomInfo (Room__c s, String pRoomNameType) {
    		sobj = s;
    		// 空室の場合、色なし
    		cssClass = '';
    		leadId = '';
            hiddenLeadId = '';
    		//accountId = '';
    		// 2019/05/29 版本升级后，页面显示null对应 BY zyz BEGIN
    		childrens = 0;
    		leadsCount = 0;
    		isBadRoom = false;
    		// 2019/05/29 版本升级后，页面显示null对应 BY zyz END
    		//清潔
    		isUnClean = false;
    		// 
    		roomNameType = pRoomNameType;
    	}
    	public Room__c sobj{get; private set;}
    	private String roomNameType;

    	public void setLeadInfo (Lead__c pLead, Map<String, AppSetupConfigXmlUtil.Config> pLeadStatusColorMap){
    		leadDetail = pLead;
            String fullGuestName = CommUtils.nullToBlank(pLead.Relcontact__r.Name);
            guestName = (CommUtils.isBlank(pLead.Relcontact__r.Katakana__c) ? 	'' : pLead.Relcontact__r.Katakana__c + ',') + 
            			(CommUtils.isBlank(pLead.Relcontact__r.KanaName1__c) ? 	'' : pLead.Relcontact__r.KanaName1__c + ',') + 
            			(CommUtils.isBlank(pLead.Relcontact__r.KanaName2__c) ? 	'' : pLead.Relcontact__r.KanaName2__c);
            guestName = CommUtils.isBlank(guestName) ? 	fullGuestName : (guestName.endsWith(',') ? guestName.substringBeforeLast(',') : guestName);
            String simpleGName = '';
            //if(ROOM_INFO_NAME_TYPE == 2){
            if (Integer.valueOf(roomNameType) != ROOM_INFO_NAME_TYPE_GUESTNAME) {
            	String fullSimpleGName = CommUtils.nullToBlank(pLead.Name);
            	simpleGName = (fullSimpleGName.length() > ROOM_INFO_MAX_SIZE) ? fullSimpleGName.substring(0,ROOM_INFO_MAX_SIZE) : fullSimpleGName;
            }else{
            	simpleGName = (fullGuestName.length() > ROOM_INFO_MAX_SIZE) ? fullGuestName.substring(0,ROOM_INFO_MAX_SIZE) : fullGuestName;
            }
            simpleGuestNm = simpleGName;
            leadId = pLead.Id;
            // 部屋変更可・不可制御フラグを設定する
            isBlocked = pLead.Field276__c;
            startTime = pLead.EntryTime__c.format('yyyyMMdd') + pLead.Field4__c;
            endTime = pLead.Departure__c.format('yyyyMMdd') + pLead.Field3__c;
            isDayUseFlg = !CommUtils.isBlank(pLead.DayNightCal__c);
            childrens = CommUtils.nullToIntZero(pLead.ChildC__c) + 
            			CommUtils.nullToIntZero(pLead.ChildD__c) + 
            			CommUtils.nullToIntZero(pLead.ChildE__c) + 
            			CommUtils.nullToIntZero(pLead.ChildFA__c) + 
            			CommUtils.nullToIntZero(pLead.ChildF__c) + 
            			// 2018/12/15 レジカード改善 小人その他追加 BY zyz BEGIN
            			CommUtils.nullToIntZero(pLead.ChildOther__c) + 
            			// 2018/12/15 レジカード改善 小人その他追加 BY zyz END
            			CommUtils.nullToIntZero(pLead.Childs__c);
            adults = 	CommUtils.nullToIntZero(pLead.Mans__c) +
            			CommUtils.nullToIntZero(pLead.Femails__c);
            			
    		stayPersonHelp1 = CONST_STAYPERSONS_ADULTS
								.replace('$_STAYPERSON_$', 		String.valueOf(CommUtils.nullToZero(pLead.StayPersons__c)))
								.replace('$_MANS_$', 			String.valueOf(CommUtils.nullToZero(pLead.Mans__c)))
								.replace('$_FEMALE_$', 			String.valueOf(CommUtils.nullToZero(pLead.Femails__c)))
								//子:
								.replace('$_CHILDS_$',			(childrens > 0 ? (' '+ Label.CONST_008_0121 + String.valueOf(childrens) ) : ''));
			
    		//if (childrens > 0 ) {		
    		// 2014/07/04 表示書式変更：小人A〜小人Dまで常に表示、小人EとFは０以上の場合のみ、表示する  
			stayPersonHelp2 = CONST_STAYPERSONS_CHILDS
							.replace('$_CHILDREN_$', 		String.valueOf(childrens))
							.replace('$_CHILDA_$', 			String.valueOf(CommUtils.nullToZero(pLead.ChildFA__c)))
							.replace('$_CHILDB_$', 			String.valueOf(CommUtils.nullToZero(pLead.Childs__c)))
							.replace('$_CHILDC_$', 			String.valueOf(CommUtils.nullToZero(pLead.ChildC__c)))
							.replace('$_CHILDD_$', 			String.valueOf(CommUtils.nullToZero(pLead.ChildD__c)))
							.replace('$_CHILDE_$', 			CommUtils.nullToZero(pLead.ChildE__c) > 0 ? ', E:' + String.valueOf(CommUtils.nullToZero(pLead.ChildE__c)) : '')
							.replace('$_CHILDF_$', 			CommUtils.nullToZero(pLead.ChildF__c) > 0 ? ', F:' + String.valueOf(CommUtils.nullToZero(pLead.ChildF__c)) : '');
    		//}
    		// 2016/01/28 予約ステータス/部屋ステータス表示の切替できる対応 BEGIN
    		String leadStatus = CommUtils.nullToBlank(pLead.ReservedStatus__c);
    		// 予約ステータス以外のモードの場合
    		if (pLeadStatusColorMap == null) leadStatusStyle = '';
    		else {
    		// 予約ステータスモードの場合
    			leadStatusStyle = 'background-color:';
    			// 予約ステータスあり　かつ　該当予約ステータスの色を設定　かつ　色設定値が存在する場合
    			if (!CommUtils.isBlank(leadStatus) && 
					pLeadStatusColorMap.containsKey(leadStatus) &&
					!CommUtils.isBlank(pLeadStatusColorMap.get(leadStatus).val) ) {
					leadStatusStyle += pLeadStatusColorMap.get(leadStatus).val;
				} else {
				// デフォルト値を設定する
					leadStatusStyle += 'white';
				}
			}
    		// 2016/01/28 予約ステータス/部屋ステータス表示の切替できる対応 END
    	}
    	// 顧客名
    	public String guestName{get; private set;}
    	// 顧客名：省略名
    	public String simpleGuestNm{get; private set;}
    	// LeadId
    	public String leadId{get; private set;}
    	// LeadInfo
    	public Lead__c leadDetail{get;set;}
    	// 2014/06/06 予約人数
    	//（大人数）
    	public Integer adults{get; private set;}
    	//（小人数）
    	public Integer childrens{get; private set;}
    	public String stayPersonHelp1{get; private set;}	// 大人
    	public String stayPersonHelp2{get; private set;}	// 子供
    	// 画面の部屋Sectionの下部のCSS制御クラス名
    	public String cssClass{get; private set;}
    	// 部屋ステータス管理フラグ
        // 掃除ステータス
        public Boolean isUnClean{get;set;}
        // クリック可能標識
    	public Boolean isCanClick{get{
    		// 予約情報が存在する場合
    		return !CommUtils.isBlank(leadId) && leadId.startsWith(leadPreFixKey);
    	}}
    	// 移動可否
    	public Boolean isCanMove{get;set;}
    	// LOCKされる部屋
    	public Boolean isBlocked{get;set;}
    	// 昼マーク標識
    	public Boolean isDayUseFlg{get;set;}
    	// 印刷済み標識【TODO】会計済みがどうチェックロジック追加が必要
    	public Boolean isAccountedFlg{get;set;}
    	// 2017/12/21 レジカードにサインしたのがルームインジケータでわかるように改善対応 zyz BEGIN
    	public String isYadoStr{get;set;} 
    	// 2017/12/21 レジカードにサインしたのがルームインジケータでわかるように改善対応 zyz END
    	// 2019/12/30 小部屋の作成 BY zyz BEGIN
    	public Boolean isSmallRoomFlg{get;set;}		// 做成小部屋数据控制
    	// 2019/12/30 小部屋の作成 BY zyz END
    	// 2020/02/29 小部屋機能改善 BY zyz BEGIN
    	public Boolean isRoomFlg{get;set;} // 小部屋图标显示控制
    	public String roomTypeCode{get;set;} // 数据的房型code
    	// 2020/02/29 小部屋機能改善 BY zyz END
    	    	
        // Leads count
        public Integer leadsCount {get;set;}
        //top Lead Id
        public String hiddenLeadId{get;set;}
        public String startTime{get;set;}
        public String endTime{get;set;}
        public Boolean isBadRoom{get;set;}
        // 予約ステータス色情報の設定
        public String leadStatusStyle{get;set;}
        // 2017/12/22 画面フィルター機能追加　by　zy　END
        public String filterClass{get;set;}
        // 2017/12/22 画面フィルター機能追加　by　zy　END
		// 2019/11/15 ルームインジケータの表示について、清掃済だけでなくインスペ完の状況を追加したいです。 by zy BEGIN
        public String status{get;set;}
		// 2019/11/15 ルームインジケータの表示について、清掃済だけでなくインスペ完の状況を追加したいです。 by zy END
    }

	
	
   	// -------------------------------------------
   	// 予約新規登録機能対応開始
   	// 各店舗の表示する項目情報を取得、格納を行う
    // -------------------------------------------
    private static final String LeadConstFields  = 'Name,Relcontact__c,refTypeOfRooms__c,EntryTime__c,Field4__c,Departure__c,Field3__c,StayPersons__c,SeminarOrderFlg__c,ExtraBedChk__c,Rroom__c,Field310__c,Field315__c,Field2__c,Segment__c,Comment3__c';

   	private Component.Apex.pageBlockSection parseFieldsXml(String pShopCode) {
   		
   		Component.Apex.pageBlockSection psection = new Component.Apex.pageBlockSection();
		psection.columns = 1;
		// 2019/12/30 新规窗口、plan未显示、见积明细也没显示bug对应 BY zyz BEGIN
		isPlanDetailFlag = false;
		// 2019/12/30 新规窗口、plan未显示、见积明细也没显示bug对应 BY zyz END
		// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
		isBasePlanFlag = false;
		// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END

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
		
		// 2016/10/12 見積明細設定機能対応 BEGIN by zh
		//プラン明細フラグ
        Dom.XmlNode mitumoriNode =  targetNode.getChildElement('MITUMORIFLAG', null);
        if(mitumoriNode != null) {
            String mitumoriContent = mitumoriNode.getText();
            isPlanDetailFlag = boolean.valueOf(mitumoriContent);
            // 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
            // 2020/06/03 6457 bug fix BY zyz BEGIN
            /* 
            if(isPlanDetailFlag){
            	isBasePlanFlag = boolean.valueOf(CommUtils.nullToBlank(mitumoriNode.getAttribute('BASEPLANFLAG',null)));
            }
            */
            // 2020/06/03 6457 bug fix BY zyz END
            // 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
        }
        // 2016/10/12 見積明細設定機能対応 END by zh 
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
		// 2017/01/25 新規画面の項目自定義機能 by zy BEGIN
		List<String> fieldsSplits = strFields.trim().split(',');
		// 2017/01/25 新規画面の項目自定義機能 by zy END
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
				// 2016/10/12 見積明細設定機能対応 BEGIN by zh
				if(isRequired(descField)){
					inputField.styleClass += ' repuiredClass';
				}
				// 2016/10/12 見積明細設定機能対応 END by zh
				inputField.id = fieldKey;
				psection.childComponents.add(inputField);
			} else {
				Component.Apex.InputField inputField = new Component.Apex.InputField();
				// 2016/10/12 見積明細設定機能対応 BEGIN by zh
				if(isRequired(descField)){
					inputField.styleClass += ' repuiredClass';
				}
				// 2016/10/12 見積明細設定機能対応 END by zh
				inputField.expressions.value = '{!newLead.'+fieldKey+'}';
				psection.childComponents.add(inputField);
			}

		}	
		return psection;
   	}
   	// 2016/11/03 BEGIN check自定义项目为系统默认的必填项  by zh
   	private boolean isRequired(Schema.DescribeFieldResult dr) {
    	return !dr.isNillable() && dr.isCreateable() && !dr.isDefaultedOnCreate();
    }
   	// 2016/11/03 END check自定义项目为系统默认的必填项  by zh
	/**
	* 予約情報拡張設定項目作成する
	**/
	public Component.Apex.pageBlockSection getInputExtendFields () {
		// 拡張情報を取得する
		Component.Apex.pageBlockSection psection = parseFieldsXml(branchShopNm);
		return psection;
	}
	/**
	* 顧客情報最新取得を行う
	**/
	@remoteAction
	global static DTO.ContactInfo refreshContcatInfo(String contactId, String contactName) {
		return RoomTypeInventory.refreshContcatInfo(contactId, contactName);
	}
	// 2017/01/25 新規画面の項目自定義機能　by　zy　BEGIN
	/**
	* 顧客情報最新取得を行う
	**/
	@remoteAction
	global static Contact refreshCustomContcatInfo(String contactId, String contactFields) {
		return  queryContact(contactFields, contactId);
	}
	// 2017/01/25 新規画面の項目自定義機能　by　zy　END
	
	// プラン明細情報を取得する
	@remoteAction
	global static List<ProductItemUtils.PlanDetail> getPlanDetailListById(String planId) {
		return ProductItemUtils.getPlanDetailList(planId);
	}
	// 商品コードにより、会計商品情報を取得する
	@remoteAction
	global static List<ProductItemUtils.ProductItem> getArrayProductItemInfo(String prodCode) {
		return ProductItemUtils.getArrayProdcutItemByCode(prodCode, true, true);
	}

	// **************** COOKIE ***************
	// 2016/02/04 前回選択値を記憶する BEGIN
    private CookieInf getCookieInf () {
    	CookieInf inf = new CookieInf();
		Cookie statucModeCookie;
		statucModeCookie = ApexPages.currentPage().getCookies().get('_RoomIndicatorInfo_cookie_statusMode');
        if (statucModeCookie != null) inf.statusMode = statucModeCookie.getValue();
        return inf;
    }
    private void setCookieInf (CookieInf inf) {
		// 画面最後利用する画面モードはCookiesに維持する
		Cookie statucModeCookie = new Cookie('_RoomIndicatorInfo_cookie_statusMode', inf.statusMode, null, -1, true);
		ApexPages.currentPage().setCookies(new Cookie[]{statucModeCookie});
    }
    public class CookieInf {
    	public String statusMode{get; set;}
    	public CookieInf(){}
    }
    // 2016/02/04 前回選択値を記憶する END
    // 2016/10/12 見積明細設定機能対応 BEGIN by zh
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
//system.debug(logginglevel.info,'sobj:::' + sobj);
            index = rsIndex;
            rowNo = String.valueOf(rsIndex);
            s.rowNo__c = rsIndex;
            // 商品名
            productNm = CommUtils.isBlank(sobj.ProductName__c) ? s.refAccountMaster__r.Name : sobj.ProductName__c;
//system.debug(logginglevel.info,'productNm:::' + productNm);
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
		// 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
		public String bTaxAccMstId{get {if(bTaxAccMstId == null) bTaxAccMstId = ''; return bTaxAccMstId;} set;}
		public String bTaxToPlanRowIndex{get {if(bTaxToPlanRowIndex == null) bTaxToPlanRowIndex = ''; return bTaxToPlanRowIndex;} set;}
		public String bTaxAccMstItem{get {if(bTaxAccMstItem == null) bTaxAccMstItem = ''; return bTaxAccMstItem ;} set;}
		// 2020/07/30 入湯税の自動入力機能について改善 WGCH END
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
        return items;*/
        // 2017/10/17 商品情報店舗別を検索を行う by zh END
        return ProductItemUtils.getArrayProdcutItemByCode(prodCode, false, false);
    }
    
    // プラン関連の商品明細を取得する
    // accId:会計ID/会計商品（プラン）ID
    /**
    * planId : プランID
    * tierPrice　: tier 
    * rateFLagStr : true 室料設定、false 自動计算
    **/
    @remoteAction
    //public static List<PlanDetail> getAccountMstLstByPlan(String planId,String tierPrice) {
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
    // 2016/10/12 見積明細設定機能対応 END by zh
	// XML___wgch 2016/11/16 BEGIN   
	//お客様の項目は更新フラグ
    public Boolean hadUpdContactFlag{get;set;} 
    public List<SectionInfo> pageLst{get;set;}
    // 部屋名[transient]
    private Map<String,Sobject> sobjectMap;
    //XML读取到的字段LABEL集合
    public Map<String,String> fieldLabelMap{get;set;}
	//XML读取到的字段对应SOBJECT中字段名集合    
    public map<String,String> pathToFieldMap{get;set;}
    //字段参照类型集合 
    public Map<String,String> fieldTypeMap{get;set;}// Xml Field Define Info map<fieldApi,dataType>
    private static final String blankString = '$_blank_$';
   	public Decimal widthPx{get; set;}
   	public String heightPx{get; set;}
    public String leadFields{get;set;}
    //XML中予約所有字段并包含特殊字段类型
    public String mapleadPingField{get;set;}
    //详细画面用字段
    public String contactFields{get;set;}
     // 2017/01/25 新規画面の項目自定義機能　by　zy　BEGIN
    //新规窗口用字段
	public String contactInserFields{get;set;}
	 // 2017/01/25 新規画面の項目自定義機能　by　zy　END
    private static final Set<String> queryDefFieldSet = new Set<String>{'Id','LeadIndexRef__c','Name','RecordType.Name','Relcontact__r.Name','Relcontact__c','nights','Field298__c','EntryTime__c','Departure__c','StayPersons__c','Field2__c','Field310__c','Rroom__c','Comment3__c'};
    private static final Set<String> leadQuerySet = new Set<String>{'Id','LeadIndexRef__c','Name','Relcontact__r.Name','Field298__c','StayPersons__c','Field2__c','Comment3__c','Rroom__r.Name','Relcontact__r.Id','Field310__r.Name','LeadIndexRef__r.Name','Field276__c','LeadIndexSubId__c','RoomGroupNo__c'};
    // 2017/01/25 新規画面の項目自定義機能　by　zy　BEGIN
    public List<SectionInfo> newLPg{get;set;}
	List<String> constFieldList = LeadConstFields.deleteWhitespace().split(',');
	Set<String> dupliaSet = new Set<String>(constFieldList);
	Set<String> excuteSet = new Set<String>();
	public map<String,boolean> fieldRequiredMap{get;set;}
	//被排除字段集合
    public List<CustomField> hadRenderFields{get;set;}
    public Map<String,String> styleMap{get;set;}
    // 2017/01/25 新規画面の項目自定義機能　by　zy　END
    public Boolean isLineHeightFlg{get;set;}
    //全部予約字段名
    public String leadFieldsAllStr{get;set;}
    //参照字段的数据类型
    public String contactMapFields{get;set;}
    // 2017/08/17 ルームインジケータ画面に、縦セルに表示項目をカスタマイズできるように改善対応 WGCH BEGIN
    //　部屋枠に個別表示したい項目APIリスト情報を格納する
    public List<String> roomExtLeadFieldApiLst{get;private set;}
    // 2017/08/17 ルームインジケータ画面に、縦セルに表示項目をカスタマイズできるように改善対応 WGCH END
    // 2018/02/06 予約検索条件はレコードタイプ外す改善対応 BEGIN
    private static final Boolean leadQueryRecTypeFlg = (CommDefine__c.getOrgDefaults().RoomIndicatorQueryLimitFlg__c == null ? false : CommDefine__c.getOrgDefaults().RoomIndicatorQueryLimitFlg__c);
    // 2018/02/06 予約検索条件はレコードタイプ外す改善対応 END
    // 2019/12/30 小部屋の作成 BY zyz BEGIN
    public Boolean smallRoomFlg{get;set;}
    // 2019/12/30 小部屋の作成 BY zyz END
    private void refeshDomNode(){
	    // 列数定義タグ存在チェック[2016/07/06]
	    leadFields = '';
	    contactFields = '';
	    leadFieldsAllStr = '';
		widthPx = 550;
		heightPx = '';
		contactMapFields = '';
		isLineHeightFlg = true;		
		// 2020/09/30 当日チェックアウトの日帰り予約がチェックイン後にルームチェンジできなくなる不具合の解消 by zy BEGIN
		oneDayCanMoveFlg = true;	// デフォルト日帰り予約移動可能
		// 2020/09/30 当日チェックアウトの日帰り予約がチェックイン後にルームチェンジできなくなる不具合の解消 by zy END
		hadUpdContactFlag = false;
	    List<String> fieldsSplits = new List<String>();
	    pageLst = new List<SectionInfo>();
	    fieldTypeMap = new Map<String,String>();
	    fieldLabelMap = new Map<String,String>();
	    pathToFieldMap = new map<String,String>();
	    // 2017/08/17 ルームインジケータ画面に、縦セルに表示項目をカスタマイズできるように改善対応 WGCH BEGIN
	    roomExtLeadFieldApiLst = new List<String>();
	    // 2017/08/17 ルームインジケータ画面に、縦セルに表示項目をカスタマイズできるように改善対応 WGCH END
	    // 2019/12/30 小部屋の作成 BY zyz BEGIN
	    smallRoomFlg = false;
	    // 2019/12/30 小部屋の作成 BY zyz END
	    Map<String, Schema.DescribeFieldResult> modelDeafaultValuesMaps = CommSqlUtils.getAllFieldLst(Lead__c.sObjectType,false);
	    // 2016/08/01 店舗設定情報を取得する
		// 2020/02/28 ルームインジケータ、タイムテーブル改修対象画面 BY zyz BEGIN
		confirmChgFlg = false;
		// 2020/02/28 ルームインジケータ、タイムテーブル改修対象画面 BY zyz END
	    // 拡張予約項目を定義する
	    String xmlName = 'RoomIndicatorInfoLeadOutputExtendFieldsXml';
	    try{
		    Dom.XMLNode targetNode = CommXmlUtils.parseXmlDoc(xmlName,branchShopNm);
		    Dom.XmlNode disPlay =  targetNode.getChildElement('DISPLAY', null);
		    if(disPlay != null){
			    Dom.XmlNode width =  disPlay.getChildElement('WINDOWWIDTH', null);
				if (width != null) {
					String widthText = CommUtils.nullToBlank(width.getText()).deleteWhitespace();
					if (!CommUtils.isBlank(widthText) && Pattern.matches('[0-9]*', widthText))
					widthPx = CommUtils.nullToZero(widthText);
				}
				Dom.XmlNode height =  disPlay.getChildElement('WINDOWHEIGHT', null);
				if (height != null) {
					String heightText = CommUtils.nullToBlank(height.getText()).deleteWhitespace();
					if (!CommUtils.isBlank(heightText) && Pattern.matches('[0-9]*', heightText))
					heightPx = CommUtils.nullToIntZero(heightText) + 'px';
				}  
				Dom.XmlNode lineHeight =  disPlay.getChildElement('LINEHEIGHT', null); 
				if (lineHeight != null) {
					String lineHeightText = lineHeight.getText().deleteWhitespace();
	                isLineHeightFlg = boolean.valueOf(lineHeightText);
				}
		    }
		    // 店舗情報はＸＭＬから取得する
		    Dom.XmlNode shopFields =  targetNode.getChildElement('FIELDS', null);
		    String strFields = (shopFields == null ? '' : CommUtils.nullToBlank(shopFields.getText()).deleteWhitespace());
		    Set<String> nowFieldSet = new Set<String>(fieldsSplits);
		    List<String> oneSectionPageStringLst = new List<String>();
		    //其他layout对应
		    for ( Dom.XmlNode c : shopFields.getChildElements()) {
		        if(c.getName() == 'SECTION'){
		            SectionInfo p = new SectionInfo();
		            p.title = c.getAttribute('TITLE',null);
		            p.columnsInt = CommUtils.nullToIntZero( c.getAttribute('COLNUM',null));
		            String childFields = CommUtils.nullToBlank(c.getText()).deleteWhitespace();
		            List<String> splitFields = childFields.split(',');
		            oneSectionPageStringLst = new List<String>();
		            for (String fieldName : splitFields) {
		                if (fieldName == blankString || !nowFieldSet.contains(fieldName)){  
		                    fieldsSplits.add(fieldName);
		                    nowFieldSet.add(fieldName);
		                    oneSectionPageStringLst.add(fieldName);
		                }
		            }
		            p.add(oneSectionPageStringLst);
		            pageLst.add(p);
		        }
		    }
		    // 2017/08/17 ルームインジケータ画面に、縦セルに表示項目をカスタマイズできるように改善対応 WGCH BEGIN
		    Dom.XmlNode shopRoomInfExtFields =  targetNode.getChildElement('ROOMINFOEXT', null);
		    String roomExtFieldsStr = (shopRoomInfExtFields == null ? '' : CommUtils.nullToBlank(shopRoomInfExtFields.getText()).deleteWhitespace());
		    if (!CommUtils.isBlank(roomExtFieldsStr)) {
		    	List<String> roomExtFieldsLst = roomExtFieldsStr.split(',');
		    	for(String api : roomExtFieldsLst) { if(!CommUtils.isBlank(api)) roomExtLeadFieldApiLst.add( CommUtils.nullToBlank(api)); }
		    }
		    // 2017/08/17 ルームインジケータ画面に、縦セルに表示項目をカスタマイズできるように改善対応 WGCH END
		    // 2018/02/06 予約検索条件はレコードタイプ外す改善対応 BEGIN
	        //leadQueryRecTypeFlg = false;
            //Dom.XmlNode leadQueryNorecTypeFields =  targetNode.getChildElement('LEADQUERY_NORECOTYPE', null);
            //leadQueryRecTypeFlg = leadQueryNorecTypeFields == null ? false : Boolean.valueOf(CommUtils.nullToBlank(leadQueryNorecTypeFields.getText()).deleteWhitespace());
		    // 2018/02/06 予約検索条件はレコードタイプ外す改善対応 END
		    // 2019/12/30 小部屋の作成 BY zyz BEGIN
		    Dom.XmlNode createInfoNode =  targetNode.getChildElement('CREATEINFO', null);
		    if(createInfoNode != null ) smallRoomFlg = true;
		    // 2019/12/30 小部屋の作成 BY zyz END
			// 2020/02/28 ルームインジケータ、タイムテーブル改修対象画面 BY zyz BEGIN
			Dom.XmlNode confirmNode =  targetNode.getChildElement('CONFIRMCHANGE', null);
		    if(confirmNode != null ) 
				confirmChgFlg = boolean.valueOf(CommUtils.nullToBlank(confirmNode.getText()));
			// 2020/02/28 ルームインジケータ、タイムテーブル改修対象画面 BY zyz END
			// 2020/09/30 当日チェックアウトの日帰り予約がチェックイン後にルームチェンジできなくなる不具合の解消 by zy BEGIN
			Dom.XmlNode ondayMoveNode =  targetNode.getChildElement('DAYUSEMOVE', null);
			if (ondayMoveNode != null) 
				oneDayCanMoveFlg = boolean.valueOf(CommUtils.nullToBlank(ondayMoveNode.getText()));
			// 2020/09/30 当日チェックアウトの日帰り予約がチェックイン後にルームチェンジできなくなる不具合の解消 by zy END
            // 2021/03/05 50001エラー修正 by zy BEGIN
            // 部屋処理最大限に関数設定
	        Dom.XmlNode allLmitRoomIntNode =  targetNode.getChildElement('ALL_LIMIT_ROOM_INT', null);
            if (allLmitRoomIntNode != null) {
                String limitRoomInt = Commutils.nulltoBlank(allLmitRoomIntNode.getText());
                if (!CommUtils.isBlank(limitRoomInt)) {
                    limitSize = COmmUtils.nullToIntZero(limitRoomInt);
                }
            }
	        // 2021/03/05 50001エラー修正 by zy END
	    }catch (Exception e){}
	    if(pageLst.isEmpty()){
	    	SectionInfo defaultPg = new SectionInfo();
	    	defaultPg.columnsInt = 1;
	    	pageLst.add(defaultPg);
		}
	    sobjectMap = new Map<String,Sobject>();
	    String nameSpace = CommBaseCtrl.getNs();
	    for (Schema.DescribeFieldResult dr : modelDeafaultValuesMaps.values()) {
	        if(dr.getType() == DisplayType.Reference){
	            SObjectType referenceObj = dr.getReferenceTo()[0];
	            Sobject obj = referenceObj.newSObject();
	            String relationName = dr.getRelationshipName();
	            if(!CommUtils.isBlank(nameSpace) && relationName.startsWith(nameSpace)) relationName = relationName.replace(nameSpace,'');
	            sobjectMap.put(relationName,obj);
	        }
	    }
	    set<String> dumyFieldSet = new set<String>();
		Map<String,String> fieldToRefKeyMap = new Map<String,String>();	   
		String mapFields = '';
	    // 予約に固定使用する項目APIから無くす
	    for (String extendField : fieldsSplits) {
	    	if(queryDefFieldSet.contains(extendField)) {
	    		dumyFieldSet.add(extendField);
	    		continue;
	    	}
	    	boolean hadPutFieldTypeFlag = false;
	        //是否包含参照关系
	        if (extendField.contains('__r')) {
	            for (String refKey : sobjectMap.keySet()) {
	                if (extendField.contains(refKey)) {
	                    String fieldNm = extendField.replace(refKey+'.','');
	                    pathToFieldMap.put(extendField,fieldNm);
	                    if(extendField.contains('Relcontact__r')){ 
	                    	contactFields += fieldNm + ',';
							fieldToRefKeyMap.put(extendField,refKey);	                    	
	                    	fieldTypeMap.put(extendField,'contact');
	                    	hadPutFieldTypeFlag = true;
	                    }
	                    break;
	                }
	            }
	        } else {
        // Get the Type corresponding to the class name
        		if(!CommUtils.isBlank(extendField)) {
					String trimFieldName = extendField.trim();
					if(modelDeafaultValuesMaps.containsKey(trimFieldName)){
						Schema.DescribeFieldResult result = modelDeafaultValuesMaps.get(trimFieldName);
						if(result.getType() == DisplayType.Date){
							mapFields += extendField + ':' +  'Date,';
						} else if(result.getType() == DisplayType.DateTime) {
							mapFields += extendField + ':' +  'DateTime,';
						} else if(result.getType() == DisplayType.textarea){ 
							mapFields += extendField + ':' +  'TextArea,';
						}
					}
				}
				mapleadPingField = mapFields;
				if(extendField != blankString){
					leadFieldsAllStr += extendField + ',';
				} else {
					leadFieldsAllStr += 'blank' + ',';
				}	
				if ((extendField != blankString) && (!leadQuerySet.contains(extendField))) {			
	        		leadFields += extendField + ',';
				}
	        }
	        String refName = fieldToRefKeyMap.get(extendField);
	        Schema.DescribeFieldResult dr;
	        
			if (modelDeafaultValuesMaps.containsKey(extendField)) {
	            dr = modelDeafaultValuesMaps.get(extendField);
            	if (!pathToFieldMap.containsKey(extendField)) pathToFieldMap.put(extendField,extendField);
	        } 
	        else if (!CommUtils.isBlank(refName) && sobjectMap.containsKey(refName)){
	            dr = CommSqlUtils.getAllFieldLst(sobjectMap.get(refName).getSObjectType(), false).get(pathToFieldMap.get(extendField));
	        }
	        if (dr != null) {
	            //排除不可更新字段
	          	fieldLabelMap.put(extendField,dr.getLabel());
	        	if(!hadPutFieldTypeFlag) fieldTypeMap.put(extendField,'lead');
	        }else {
	            if (extendField == blankString) {
	                fieldTypeMap.put(extendField,'blank');
	                continue;
	            }
	            dumyFieldSet.add(extendField);
	        }
	    }
	    for (String fieldName : dumyFieldSet) {
	    	for (SectionInfo s : pageLst) {
                for (integer i = 0 ; i < s.fieldLst.size() ; i++) {
                    String fieldNm = s.fieldLst[i];
                    if (fieldName == fieldNm) s.fieldLst.remove(i); 
                }
            }
	    }	    
	    // 元画面常に表示される項目に対して、デフォルト値設定を行う
	    sobjectMap.put('Lead__c',new Lead__c());
	    //特殊のお客様の項目の作成する
	    Map<String, Schema.DescribeFieldResult> contactDeafaultValuesMaps = CommSqlUtils.getAllFieldLst(Contact.sObjectType,false);
		for (String fieldName :contactFields.split(',') ) {
			if(!CommUtils.isBlank(fieldName)) {
				String trimFieldName = fieldName.trim();
				if(contactDeafaultValuesMaps.containsKey(trimFieldName)){
					Schema.DescribeFieldResult result = contactDeafaultValuesMaps.get(trimFieldName);
					if(result.getType() == DisplayType.Date){
						contactMapFields += result.getLocalName() + ':' +  'Date,';
					} else if(result.getType() == DisplayType.DateTime) {
						contactMapFields += result.getLocalName() + ':' +  'DateTime,';
					} else if(result.getType() == DisplayType.textarea){ 
						contactMapFields += result.getLocalName() + ':' +  'TextArea,';
					 // 2017/01/25 新規画面の項目自定義機能　by　zy　BEGIN
					} else if(result.getType() == DisplayType.Boolean){
						contactMapFields += result.getLocalName() + ':' +  'Boolean,';
					}
					 // 2017/01/25 新規画面の項目自定義機能　by　zy　END
				}
			}
		}
		// 2019/10/15 iPadは陣屋コネクトとして推奨しているモバイル端末であり、iPadでは一切ドラッグ＆ドロップができなくなるのも困りますので、編集モードと閲覧モードの切り替えができる様にお願いします by zy BEGIN
		mobileReadOnlyFlg = PageAuthConfigCtrl.getMobileReadonlyFlg(branchShopNm);
		// 2019/10/15 iPadは陣屋コネクトとして推奨しているモバイル端末であり、iPadでは一切ドラッグ＆ドロップができなくなるのも困りますので、編集モードと閲覧モードの切り替えができる様にお願いします by zy END
	}
    // 2017/01/25 新規画面の項目自定義機能　by　zy　BEGIN		 
    //新规窗口XML读取
    private void loadInsertWindow() {
//system.debug(logginglevel.info,'RoomTypeInventoryLeadInputExtendFieldsXml:::');
		// 2019/12/30 新规窗口、plan未显示、见积明细也没显示bug对应 BY zyz BEGIN
		isPlanDetailFlag = false;
		// 2019/12/30 新规窗口、plan未显示、见积明细也没显示bug对应 BY zyz END
		// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
		isBasePlanFlag = false;
		// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
		styleMap = new Map<String,String>();
		contactInserFields = '';
	    //页面所有字段列表
	    List<String> fieldsSplits = new List<String>();
	    //无效字段集合
		set<String> dumyFieldSet = new set<String>();
		//不可为空字段集合
	    set<string> requiredSet = new set<string>{'relcontact__c','name','staypersons__c','field4__c','field2__c','field3__c'};
	    newLPg = new List<SectionInfo>();
	    String fieldStr = 'relcontact__c,reftypeofrooms__c,name,entrytime__c,relcontact__r.katakana__c,'
							+'field4__c,relcontact__r.kananame1__c,departure__c,relcontact__r.phone,'
							+'field3__c,staypersons__c,seminarorderflg__c,staysnums,extrabedchk__c,rroom__c,$_blank_$,_planStr_,'
							+'field315__c,$_blank_$,field2__c,$_blank_$,segment__c,$_blank_$';
	    newWindowDefSet = new List<String>();
	    // 拡張予約項目を定義する
	    String odVerFiledStr = '';
	    Set<String> nowFieldSet = new Set<String>(fieldsSplits);
	    List<String> oneSectionPageStringLst = new List<String>();
	    boolean oldVersionFlag = false;
        Integer showVersion = CommConst.APPOTION_NEWBOOKING_VER;
        oldVersionFlag = (showVersion != 2);
        //2017/02/28 新版本対応　by zy BEGIN
        //新版本不check此flag
        if (!oldVersionFlag) { 
        	isHaveSeminar = true;
        	isHaveEbInfo = true;
        }
        //2017/02/28 新版本対応　by zy END
	    // 拡張予約項目を定義する
        String xmlName = (oldVersionFlag ? 'RoomTypeInventoryLeadInputExtendFieldsXml' : 'RoomTypeInventoryLeadInputExtendFieldsXml_V2');
	    try{
	        // 2019/06/15 新規予約を部屋ごとに時間と到着日をデフォルト設定 BY zyz BEGIN
	        getDefLead(xmlName,branchShopNm);
	        // 2019/06/15 新規予約を部屋ごとに時間と到着日をデフォルト設定 BY zyz END
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
	            if(isPlanDetailFlag){
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
			            }
			            p.add(oneSectionPageStringLst);
			            newLPg.add(p);
			        }
		    	}
		    }else{
		    	//throw new CommException('指定の店舗コードの定義情報を見つかりません。['+pShopCd+']');
		    }
		    String planStr = '';
			if(!isPlanDetailFlag){
				planStr = 'field310__c,$_blank_$';
			}	
			fieldStr = fieldStr.deleteWhitespace().replace('_planStr_',planStr);
	    }catch (Exception e){
	    	system.debug(logginglevel.info,'e:::' + e.getStackTraceString());
	    }
	    //未做成SECTION列表
	    if(newLPg.isEmpty()){
	    	newWindowDefSet.addAll(fieldStr.trim().split(','));
	    	//将默认的信息做成SECTION
	    	defaultNewLeadPage(odVerFiledStr.toLowerCase());
//system.debug(logginglevel.info,'fieldsSplits:::' + fieldsSplits);
		} else {
			//如果只是不足默认值的时候，去掉空
			fieldStr = fieldStr.replace('$_blank_$','');
			//2017/02/28 新版本対応　by zy BEGIN
			if (!oldVersionFlag)
				fieldStr = fieldStr.replace('seminarorderflg__c,','')
        					   .replace('extrabedchk__c','');
        	//2017/02/28 新版本対応　by zy END
			newWindowDefSet.addAll(fieldStr.trim().split(','));
			newWindowDefSet.add('comment3__c');
			newLPg[newLPg.size() -1].add(newWindowDefSet);
		}
		processFileds(newLPg,dumyFieldSet,requiredSet);
		//processXmlInputMessage(fieldsSplits, newLPg , dumyFieldSet,requiredSet);
    }
	private void processFileds(List<SectionInfo> curPLst , Set<String> dumyFieldSet,Set<String> requiredSet){
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
//system.debug(logginglevel.info,'refName::' + refName);
							//如果是客户对象
		    				if(refName.contains('Relcontact__r')){
		    					cus.fieldType = 'contact';
		    					cus.localName = refDr.getLocalName();
		    					cus.name = refDr.getName();
		    					contactSet.add(refDr.getLocalName());
			                    //contactFields+= refDr.getLocalName() + ',';
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
						cus.name = dr.getName();
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
		for (String key : newWindowDefSet) {
			if (!hadUseDefFieldSet.contains(key)) {
				hadRenderFields.add(new CustomField(key,windowDefFieldMap.get(key)));	
			}
		}
		for (String fieldStr : contactSet) {
			contactInserFields += fieldStr + ',';
		}
	}
	//原画面默认字段名及对应关系
	private static final  Map<String,String> windowDefFieldMap = new Map<String,String>{'relcontact__c' => 'relcontact', 'reftypeofrooms__c' => 'refTypeOfRooms', 'name' => 'leadName', 'entrytime__c' => 'entryDate', 'relcontact__r.katakana__c' => 'katakana', 'field4__c' => 'entryTime', 'relcontact__r.kananame1__c' => 'kanaName', 'departure__c' => 'departureDate', 'relcontact__r.phone' => 'custPhone', 'field3__c' => 'departureTime', 'staypersons__c' => 'stayPerson', 'staysnums' => 'staysNums', 'rroom__c' => 'brooms', 'field310__c' => 'plan','field315__c' => 'paymentType',  'comment3__c' => 'comment3', 'field2__c' => 'channel','segment__c'=> 'segment','seminarorderflg__c'=> 'seminarorder','extrabedchk__c'=> 'extrabedchk','bookingrooms' => 'broomNum'};
	private List<String> newWindowDefSet;
	/*
	* 默认新規画面作成
	*/
	private void defaultNewLeadPage(String fieldXmlStr) {
		/*List<String> newWindowDefSet = new List<String>{'relcontact__c', 'reftypeofrooms__c', 'name', 'entrytime__c', 'relcontact__r.katakana__c', 
														'field4__c', 'relcontact__r.kananame1__c', 'departure__c', 'relcontact__r.phone', 
														'field3__c', 'staypersons__c','seminarorderflg__c', 'staynightcal__c','extrabedchk__c', 'rroom__c','$_blank_$', 'field310__c','$_blank_$',
														'field315__c','$_blank_$', 'field2__c', '$_blank_$', 'segment__c','$_blank_$'};*/
		
		List<String> resLst = new List<String>();
		//旧版本中扩展字段不为空
//system.debug(logginglevel.info,'fieldXmlStr::' + fieldXmlStr);
		if (!CommUtils.isBlank(fieldXmlStr)) {
			newWindowDefSet.addAll(fieldXmlStr.deleteWhitespace().split(','));
		}
//system.debug(logginglevel.info,'newWindowDefSet111::' + newWindowDefSet);
		SectionInfo defaultPg = new SectionInfo();
    	defaultPg.columnsInt = 2;
    	defaultPg.add(newWindowDefSet);
    	newLPg.add(defaultPg);
    	resLst.addAll(newWindowDefSet);
    	//特记事项做成BEGIN
    	SectionInfo commentPg = new SectionInfo();
    	commentPg.columnsInt = 1;
    	commentPg.add(new List<String>{'comment3__c'});
    	newLPg.add(commentPg);
    	resLst.add('comment3__c');
//system.debug(logginglevel.info,'newLPg::' + newLPg);
//system.debug(logginglevel.info,'resLst::' + resLst);    	
	}
	
	/*
	* 默认详细页面做成
	*/
	private List<String> defaultDetialPage(){
		List<String> defaultFieldLst = new List<String>{'relcontact__c', 'reftypeofrooms__c', 'name', 'entrytime__c', 'relcontact__r.katakana__c', 
														'field4__c', 'relcontact__r.kanaName1__c', 'departure__c', 'relcontact__r.phone', 'field3__c', 
														'staypersons__c', 'staynightcal__c', 'rroom__c', 'field310__c','field315__c', 'field2__c'};
		List<String> resLst = new List<String>();
		SectionInfo defaultPg = new SectionInfo();
		defaultPg.columnsInt = 2;
		defaultPg.add(defaultFieldLst);
//system.debug(logginglevel.info,'defaultPg::' + defaultPg); 
		pageLst.add(defaultPg);
		resLst.addAll(defaultFieldLst);
		SectionInfo commentPg = new SectionInfo();
		commentPg.columnsInt = 1;
		commentPg.add(new List<String>{'comment3__c'});
		pageLst.add(commentPg);
		resLst.add('comment3__c');
//system.debug(logginglevel.info,'pageLst11111::' + pageLst); 
//system.debug(logginglevel.info,'resLst1111::' + resLst); 
		return resLst;
	}
	/*
	* 判断字段是否是特殊类型
	*/
	private String checkAndAddFiledName(Schema.DescribeFieldResult dr, String  mapFields){
		system.debug(logginglevel.info,'dr.getType():::' + dr.getType());
		if(dr.getType() == DisplayType.Date){
			mapFields += dr.getName() + ':' +  'Date,';
		} else if(dr.getType() == DisplayType.DateTime) {
			mapFields += dr.getName() + ':' +  'DateTime,';
		} else if(dr.getType() == DisplayType.textarea){ 
			mapFields += dr.getName() + ':' +  'TextArea,';
		} 
		else if(dr.getType() == DisplayType.Boolean){ 
			mapFields += dr.getName() + ':' +  'Boolean,';
		} 
		/*
		else if(dr.getType() == DisplayType.Phone){ 
			mapFields += dr.getName() + ':' +  'Phone,';
		} else if(dr.getType() == DisplayType.Email){ 
			mapFields += dr.getName() + ':' +  'Email,';
		}*/
		return mapFields;
	}
	// 2017/01/25 新規画面の項目自定義機能　by　zy　END
	//section定义信息
	public class SectionInfo{
		public Integer columnsInt{get;set;}
		public List<String> fieldLst{get;set;}
		public String title{get;set;}
		// 2017/01/25 新規画面の項目自定義機能　by　zy　BEGIN
		public List<CustomField> cusFields{get;set;}
		// 2017/01/25 新規画面の項目自定義機能　by　zy　END
		public boolean isHeadShowFlag{get{ return !CommUtils.isblank(title);}}
		public SectionInfo(){
		    columnsInt = 2;
		    fieldLst = new List<String>(); 
		    // 2017/01/25 新規画面の項目自定義機能　by　zy　BEGIN
		    cusFields = new List<CustomField>();
		    // 2017/01/25 新規画面の項目自定義機能　by　zy　END
		}
		public void add(Set<String> fLst){
		    fieldLst.addAll(fLst);
		}
		public void add(List<String> fLst){
		    fieldLst.addAll(fLst);
		}
		// 2017/01/25 新規画面の項目自定義機能　by　zy　BEGIN
		public void add(CustomField cus) {
			cusFields.add(cus);	
		}
		// 2017/01/25 新規画面の項目自定義機能　by　zy　END
	}
	public String getDateTimeFormatStr() {
        return CommBaseCtrl.getDateTimeFormat();
    }
    public String getDateFormatStr() {
        return CommBaseCtrl.getDateFormat();
    }	
    // 2017/01/25 新規画面の項目自定義機能　by　zy　BEGIN
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
    		fieldStyle = '';
    	}
    	public CustomField(String name,String fType){
    		fieldType = fType;
    		fieldName = name;
    	}
    }
    // 2017/01/25 新規画面の項目自定義機能　by　zy　END	
	// XML___wgch 2016/11/16 END
	/**
	* カスタム設定のお客様の項目の入力更新する
	* 2016/11/25 by zy
	**/
	private void upsertCustomContact(){
		Contact updContact = new Contact(id = newContact.id);
		for(String fieldName : contactFields.split(',')) {
			if (!CommUtils.isBlank(fieldName))
				updContact.put(fieldName,newContact.get(fieldName));
		}
		update updContact;
		hadUpdContactFlag = false;
	}
	// 2017/01/25 新規画面の項目自定義機能　by　zy　BEGIN
	/*
	* お客様のメッセージ取得する
	* contactFields:XML定義のお客様の項目
	* cId:お客様ID
	*/
	//共通化处理
	private static Contact queryContact(String contactFields,String cId){
		set<string> contactFieldsSet = new set<string>{'id','katakana__c','kananame1__c'};
		Contact c = new Contact();
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
//system.debug(logginglevel.info,'contactQueryFields:::' + contactQueryFields);
		contactQueryFields = contactQueryFields.removeEnd(',');	
		String contactQuery = 'Select ' + contactQueryFields + ' From Contact';
		String contactId = cId;
		contactQuery += ' where id=:contactId';
		List<Contact> contactLst = Database.query(contactQuery);
		if(!contactLst.isEmpty()) c = contactLst[0];
		return c; 
	}
	// 2017/01/25 新規画面の項目自定義機能　by　zy　END
	 // 2017/11/14　未割り当て予約並べる by zy BEGIN
    // 排序字段内容作成する
    private static String getAssignOrderQuery(String spcd){
    	String orderSQL = '';
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
	    }catch (Exception e){}
	    return orderSQL;
    }
    // 2017/11/14　未割り当て予約並べる by zy END
    // 2017/12/22 画面フィルター機能追加　by　zy　BEGIN
    // 过滤房间
    public String filterHidRoom{get;set;}
    public String filteText{get;set;}
    global static List<String> getFilterRooms(String filterText,String spcd,String queryDate) {
    	throw new CommException('該当METHODは既に利用廃止');
    }
    @remoteaction
    global static List<String> getFilterRooms(String filterText,String spcd,String queryDate,Boolean showToday) {
    	// 房间检索
    	String queryWhereStr = '';
    	UserUtil.UserShopInfo userInf = UserUtil.CurrentUserInfo;
    	// 2015/09/01 多店舗機能対応 BEGIN
        // 2018/05/11 複数店舗を選択表示できる機能対応 BEGIN
    	list<string> mulitiSpcd = CommUtils.nullToBlank(spcd).split(',');
        if (mulitiSpcd.size() > 1) {
        	queryWhereStr+= ' Where ShopInfoRef__r.ShopCode__c in :mulitiSpcd';
        }
        else if (!CommUtils.isBlank(spcd)) {
        // 2018/05/11 複数店舗を選択表示できる機能対応 END
            queryWhereStr += ' where ShopInfoRef__r.ShopCode__c = \'' + String.escapeSingleQuotes(spcd) + '\'';
        }else if (userInf.isShopCodePlex) {
            Set<String> shopSt = UserUtil.CurrentUserInfo.shopSt;
            queryWhereStr += ' where ShopInfoRef__r.ShopCode__c in :shopSt';
        }
		// 2015/09/01 多店舗機能対応 END
    	String robjNm = CommConst.APPOTION_NAMESPACE + 'Room__c';
    	String roomQuery = 'FIND :filterText IN ALL FIELDS RETURNING '+robjNm +'(Id ' + queryWhereStr + ')';
    	Set<String> roomIds = new Set<String>();
    	List<List<Sobject>> existRs = search.query(roomQuery);
    	List<Room__c> roomLst = existRs[0];
    	for (Room__c room : roomLst) {
    		roomIds.add(room.id);
    	}
		// 当日予約検索
		Date todayDt = (String.isEmpty(queryDate)) ? Date.today() : CommUtils.stringToDate(queryDate);
    	Date curDt = getProcessDate(todayDt, showToday);
    	Set<Id> contactIds = new Set<id> ();
    	Map<String,Set<String>> contactMap = new Map<String,Set<String>>();
    	Integer LEAD_ST_CANCEL_FLG = CommConst.LEAD_ST_CANCEL_FLG;
    	String leadQuery = 'select relcontact__c,Rroom__c from lead__c';
    	String leadWhere = ' where Rroom__c != null And CancelBool__c !=:LEAD_ST_CANCEL_FLG';
    	leadWhere += ' And DAY_ONLY(convertTimezone(EntryTime__c)) = :curDt ';
        // 2018/05/11 複数店舗を選択表示できる機能対応 BEGIN
        if (mulitiSpcd.size() > 1) {
        	leadWhere+= ' and Rroom__r.ShopInfoRef__r.ShopCode__c in :mulitiSpcd';
        }
        else if (!CommUtils.isBlank(spcd)) {
        // 2018/05/11 複数店舗を選択表示できる機能対応 END
            leadWhere += ' and Rroom__r.ShopInfoRef__r.ShopCode__c = \'' + String.escapeSingleQuotes(spcd) + '\'';
        }else if (userInf.isShopCodePlex) {
            Set<String> shopSt = UserUtil.CurrentUserInfo.shopSt;
            leadWhere += ' and Rroom__r.ShopInfoRef__r.ShopCode__c in :shopSt';
        }
    	List<Lead__c> leadLst = Database.query(leadQuery + leadWhere);
    	if (!leadLst.isEmpty()) {
			// 2019/08/15 ルームインジケータの検索窓では、これに「予約名」も追加していただきたいです。 by zy BEGIN
			List<Id> leadIdLst = new List<Id>();
			// 2019/08/15 ルームインジケータの検索窓では、これに「予約名」も追加していただきたいです。 by zy END
	    	for ( Lead__c lead : leadLst) {
				// 2019/08/15 ルームインジケータの検索窓では、これに「予約名」も追加していただきたいです。 by zy BEGIN
				leadIdLst.add(lead.id);
				// 2019/08/15 ルームインジケータの検索窓では、これに「予約名」も追加していただきたいです。 by zy END
	    		contactIds.add(lead.relcontact__c);			
	    		if (!contactMap.containsKey(lead.relcontact__c)) contactMap.put(lead.relcontact__c,new Set<String>());	
	    		contactMap.get(lead.relcontact__c).add(lead.Rroom__c);
	    	}
	    	String leadWhereStr = 'where id=:contactIds';
	    	String findQuery = 'FIND :filterText IN ALL FIELDS RETURNING Contact(Id ' + leadWhereStr + ')';
	    	List<List<Sobject>> leadRs = search.query(findQuery);
	    	List<Contact> contacts = leadRs[0];
	    	for (Contact con : contacts) {
	    		if (contactMap.containsKey(con.id)) roomIds.addAll(contactMap.get(con.id));
	    	}
			// 2019/08/15 ルームインジケータの検索窓では、これに「予約名」も追加していただきたいです。 by zy BEGIN
			findQuery = 'FIND :filterText IN name FIELDS RETURNING ps__Lead__c(Id,Rroom__c where id =:leadIdLst)';
			leadRs = search.query(findQuery);
	    	List<Lead__c> leads = leadRs[0];
			if (!leads.isEmpty()) {
				for(Lead__c l : leads) {
					roomIds.add(l.Rroom__c);
				}
			}
			// 2019/08/15 ルームインジケータの検索窓では、これに「予約名」も追加していただきたいです。 by zy END
    	}
    	return new List<String>(roomIds);
    }
    // 2017/12/22 画面フィルター機能追加　by　zy　END
    // 2018/05/01 ルームインジケータで予約をクリックして、『部屋詳細情報』が開きます。
    // その後、『予約名』や『お客様』にて、次の画面が開きます。次の画面に移動した際に、
    // そのタブは『部屋詳細情報』が開いたままの状態でキープされ続けているのですが、
    // この画面（『部屋詳細情報』のみ）を自動で閉じてもらうようにすることはできますでしょうか by zy BEGIN
    public boolean isAutoClassFlag{get { return CommDefine__c.getOrgDefaults().RoomIndicatorDetailWindowAutoCloseFlg__c == null ? false : CommDefine__c.getOrgDefaults().RoomIndicatorDetailWindowAutoCloseFlg__c;}set;}
	// 2018/05/01 ルームインジケータで予約をクリックして by zy END
	// 2018/05/09 ルームインジケータの最終日意外泊目のステータスも自動で赤に変え　by ZY BEGIN
	private String getCheckOutColor(Lead__c lead) {
		String defaultColor = this.strIsStayStatusColor;
		// カスタム設定、デフォルトはfalse
		boolean isChgCheckOutFlag = CommDefine__c.getOrgDefaults().RoomIndicatorPastLeadToCoColorFlg__c == null ? false : CommDefine__c.getOrgDefaults().RoomIndicatorPastLeadToCoColorFlg__c;
		// カスタム設定あり、過去日ありの場合
		if (isChgCheckOutFlag && lead.EntryTime__c.date() < system.today()) defaultColor = this.strCheckOutStatusColor;
		return defaultColor;
	}
	// 2018/05/09 ルームインジケータの最終日意外泊目のステータスも自動で赤に変え　by ZY END
	// 2018/07/27 宿泊税計算 WGCH BEGIN
	public String hotelTaxDefineInfoJson {get{ return JSON.serialize(CommLogicProcess.getHotelTaxDefInstance());}}
	// 2018/07/27 宿泊税計算 WGCH END
	// 2018/8/28 ルームインジケーターのチェックアウトから日をまたぐと未清掃が反映 by cxw begin
	private static boolean isKeepCleanFlag = CommConst.LEAD_ROOM_ST_ISKEEPCLEANFLG;
	// 2018/8/28 ルームインジケーターのチェックアウトから日をまたぐと未清掃が反映 by cxw END
	// 2019/04/30 増税仮対応 WGCH BEGIN
	// 增税商品json数据 
	public String taxIncMstItemJson{get	{ return CommLogicProcess.getTaxIncMstJson();} private set;}
	// 2019/04/30 増税仮対応 WGCH END
	// 2019/05/30 こちらをルームインジケータ上からも1日単位の作成、削除（削除だけでもほしい）by zy BEGIN
	@remoteaction
	global static object remoteCenter(String dataType,String req){
		if (dataType == 'badRoomAction') return badRoomAction(req);
		return null;
	}
	private static object badRoomAction(String req){
		RequestInfo info = (RequestInfo)JSON.deserialize(req, RequestInfo.class);
		String queryDt = info.queryDt;
		Date todayDt = (String.isEmpty(queryDt)) ? Date.today() : CommUtils.stringToDate(queryDt);
		// 2020/06/30 6907 bug fixed by zy BEGIN
		todayDt = getProcessDate(todayDt, boolean.valueOf(CommUtils.nullToBlank(info.showToday)));
		// 2020/06/30 6907 bug fixed by zy END
		// 該当日付の部屋清掃済に更新を行う
    	Set<String> roomIdSet = new Set<String>();
    	roomIdSet.addAll(info.roomIds);
    	// 清掃フラグ状態を保持フラグが有効の場合、日付を指定なし、全て未清掃データをクリアする　
    	RoomStatusManager.updBadRoomStatus(roomIdSet,new Set<Date>{todayDt});
    	return '';
	}
	class RequestInfo{
		List<String> roomIds; 
		String queryDt;
		// 2019/11/15 ルームインジケータの表示について、清掃済だけでなくインスペ完の状況を追加したいです。 by zy BEGIN
		String status;
		// 2019/11/15 ルームインジケータの表示について、清掃済だけでなくインスペ完の状況を追加したいです。 by zy END
		// 2020/06/30 6907 bug fixed by zy BEGIN
		// 指定日の場合、当日以外はチェックイン・チェックアウトボタンを非表示すうため
		String showToday;
		// 2020/06/30 6907 bug fixed by zy END
	}
	// 2019/05/30 こちらをルームインジケータ上からも1日単位の作成、削除（削除だけでもほしい）by zy END
    // 2019/06/15 新規予約を部屋ごとに時間と到着日をデフォルト設定 BY zyz BEGIN
    public String leadTimeJsons{get;set;}
    // 定义特殊处理的字段 ： 到着時刻,出発時刻,予約人数,セミナー,泊数,エキストラベッド,支払方法,予約チャネル,セグメント
    // 2020/01/30 「予約チャネル」设定值不生效bug对应 BY zyz BEGIN
    // private static map<String,String> defPopupWinMap = new map<String,String>{'Field4__c'=>'entryTime','Field3__c'=>'departureTime','StayPersons__c'=>'stayPerson','SeminarOrderFlg__c'=>'seminarOrderFlg','staysNums'=>'staysNums','ExtraBedChk__c'=>'extrabedFlg','Field315__c'=>'paymentType','Field2__c'=>'leadChannel','Segment__c'=>'segment'};
    private static map<String,String> defPopupWinMap = new map<String,String>{'Field4__c'=>'entryTime','Field3__c'=>'departureTime','StayPersons__c'=>'stayPerson','SeminarOrderFlg__c'=>'seminarOrderFlg','staysNums'=>'staysNums','ExtraBedChk__c'=>'extrabedFlg','Field315__c'=>'paymentType','Field2__c'=>'chanelId','Segment__c'=>'segment'};
    // 2020/01/30 「予約チャネル」设定值不生效bug对应 BY zyz END
    private void getDefLead(String xmlName,String branchShopNm){
    	leadTimeJsons = PageCustomeFieldHelper.getNewWindowLeadFieldDefValue(xmlName,branchShopNm,defPopupWinMap);
    }
	// 2019/06/15 新規予約を部屋ごとに時間と到着日をデフォルト設定 BY zyz END
	// 2019/07/31 20190527.04.タイムテーブル、ルームインジケータ、マルチタスク機能編集モードと読み込み専用モード対応必要 by zy BEGIN
	public Boolean notReadOnlyFlg{get;set;}
	// 2019/07/31 20190527.04.タイムテーブル、ルームインジケータ、マルチタスク機能編集モードと読み込み専用モード対応必要 by zy END
	// 2019/10/15 iPadは陣屋コネクトとして推奨しているモバイル端末であり、iPadでは一切ドラッグ＆ドロップができなくなるのも困りますので、編集モードと閲覧モードの切り替えができる様にお願いします by zy BEGIN
	public boolean mobileReadOnlyFlg{get;set;}
	// 2019/10/15 iPadは陣屋コネクトとして推奨しているモバイル端末であり、iPadでは一切ドラッグ＆ドロップができなくなるのも困りますので、編集モードと閲覧モードの切り替えができる様にお願いします by zy END
	// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
	public static boolean planBrkToHeaderCalFlg{get{ return CommConst.PLAN_BRKTOHEADER_CAL_FLG;} private set;}
	// 2019/10/02 PlanHeader算法切换对应 WGCH END
	// 2019/11/15 ルームインジケータの表示について、清掃済だけでなくインスペ完の状況を追加したいです。 by zy BEGIN
	public List<CleanStatus> cleansLst{get;set;} // 清掃状態設定リスト
	private Map<String,String> exitColorMap;
	public Boolean headSameCleanStautsFlg{get;set;} // 清掃リストに、【未清掃】が存在是否の判断
	private String defStatus;
	// 清掃状態対象
	public class CleanStatus{
		public String name{get;set;}  // 清掃状態名
		public String color{get;set;} // 清掃カラー
		// 初期化
		public CleanStatus(String nm,String co){
			name = nm;
			color = co;
		}
	}
	//　清掃情報初期化
    private void initCleanStatus(){
		// 初期化
    	cleansLst = new List<CleanStatus>();
		exitColorMap = new Map<String,String>();
		// 選択リスト全部状態取得
    	Schema.DescribeFieldResult fieldResult = RoomsStatus__c.CleanStatus__c.getDescribe();
    	List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<Map<String,String>> statusInfoLst = new List<Map<String,String>>();
		if (!ple.isEmpty()) defStatus = ple[0].getValue();
		// 指定店舗のカラー情報取得
        Map<String,String> colorMap = getRoomStatusColorXML(branchShopNm);
		// 未清掃チェック
		headSameCleanStautsFlg = colorMap.containsKey(Label.MSG_008_0013);
		String preStatusName = defStatus;
		// 清掃情報設定
        for( Schema.PicklistEntry f : ple) {
        	String statusName = f.getValue();
            // 設定カラー
            if (colorMap.containsKey(statusName)) {
				preStatusName = statusName;
            	cleansLst.add(new CleanStatus(statusName,colorMap.get(statusName)));
				exitColorMap.put(statusName,statusName);
			// 2020/03/31 清掃ステータス,清掃完了カラー未設定の場合、カラー非表示 by zy BEGIN
            } else if (comlateStatus != statusName){
			// 2020/03/31 清掃ステータス,清掃完了カラー未設定の場合、カラー非表示 by zy END
				exitColorMap.put(statusName,preStatusName);
			}
        }
	}
	// 2020/03/31 清掃ステータス,清掃完了カラー未設定の場合、カラー非表示 by zy BEGIN
	private static String comlateStatus; // 指定清掃済みの状態
	// 2020/03/31 清掃ステータス,清掃完了カラー未設定の場合、カラー非表示 by zy END
	// 指定店舗のカラー情報取得
    public static Map<String,String> getRoomStatusColorXML(String spcd){
    	Map<String,String> colorMap = new Map<String,String>();
    	try{
    		// 2018/08/02 清掃チェックリスト機能追加 by zy END
    		Dom.XMLNode targetNode = CommXmlUtils.parseXmlDoc('CleanRoomConfig',spcd);
    		if (targetNode != null) {
				// 2020/03/31 清掃ステータス,清掃完了カラー未設定の場合、カラー非表示 by zy BEGIN
				Dom.XmlNode completeNode = targetNode.getChildElement('COMPLETESTATUS',null);
				if (completeNode != null) comlateStatus = COmmUtils.nullToBlank(completeNode.getText());
				// 2020/03/31 清掃ステータス,清掃完了カラー未設定の場合、カラー非表示 by zy END
	        	//カラー設定
	        	Dom.XmlNode colorNode =  targetNode.getChildElement('COLORCONFIG', null);
	        	if (colorNode != null) {
					// カラーフィルター
	        		for (Dom.XmlNode color : colorNode.getChildElements()) {
	        			if (color != null) {
							// 清掃状態名
	        				String name = CommUtils.nullToBlank(color.getText());
							// 画面表示のフラグ
	        				String roomShowStr = CommUtils.nullToBlank(color.getAttribute('ROOMINDICATOR',null));
	        				if (CommUtils.isBLank(roomShowStr) || !Boolean.valueof(roomShowStr))  continue;
							// 清掃カラー
	        				String colorStr = CommUtils.nullToBlank(color.getAttribute('COLOR',null));
	        				if (!CommUtils.isBlank(colorStr)) colorMap.put(name,colorStr);
	        			}
	        		}
	        	}
    		}
    	}catch(exception e) {}
    	return colorMap;
    }
    // 2019/11/15 ルームインジケータの表示について、清掃済だけでなくインスペ完の状況を追加したいです。 by zy END
    // 2019/12/30 名前か電話番号のどちらかだけ一致するお客様がすでに存在する BY zyz BEGIN
    // 处理显示10比数据
    public static list<contact> getContactLst(String conNameStr,String phoneStr,Id cId,String preShopcode){
    	list<contact> contactDefLst = new list<contact>();
    	// 当前数据的顾客ID
    	String contactId = cId;
    	// 获取XML定义信息
    	loadIContactWhere(preShopcode);
    	// 字段是否有效开关
    	Boolean relcontact_apiFlg = true;
    	try{
	    	Map<String, Schema.DescribeFieldResult> modelDeafaultValuesMaps = CommSqlUtils.getAllFieldLst(Contact.sObjectType,false,true);
	    	String queryApiStr = 'id,name,phone';
	    	set<String> queryApiSet = new set<String>{'id','name','phone'};
	    	if (relcontact_apiset.isEmpty()) return contactDefLst;
	    	// 判断字段是否存在和SQL拼成
	    	for(String api : relcontact_apiset){
	    		if(!modelDeafaultValuesMaps.containsKey(api)) {
	    			relcontact_apiFlg = false;
	    			continue;
	    		}
	    		if (queryApiSet.contains(api)) continue;
	    		queryApiStr += ',' + api+' ';
	    	}
	    	if(!relcontact_apiFlg) return contactDefLst;
	    	// 检索当前顾客数据
	    	String preContactStr =  ' select '+queryApiStr+' from contact where Id =: contactId ';
	    	// 当前顾客
	    	list<contact> contactPreLst = Database.query(preContactStr);
	    	contact contactPre = contactPreLst[0];
	    	// 处理检索重复顾客数据条件内容
	    	for(String api : relcontact_apiset){
	    		String fieldVal = CommUtils.nullToBlank(contactPre.get(api));
	    		whereContactStr = whereContactStr.Replace(api+'_api','\'' + fieldVal + '\'');
	    	}
	    	// 检索重复顾客数据
	    	String defcontactStr = ' select '+queryApiStr+' from contact where IsDelete__c != true and Id !=: contactId ';
    		// XML设定检索条件
	    	String whereStr =  whereContactStr;
	    	// 检索条件追加
	    	if(!CommUtils.isBlank(whereStr)) whereStr = ' and(' + whereStr +') ';
	    	// limit设定
	    	whereStr +=' order by LastModifiedDate desc limit 10';
	    	defcontactStr += whereStr ;
	    	contactDefLst = Database.query(defcontactStr);
    	}catch(exception e) {}
    	return contactDefLst;
    }
    // xml自定义检索条件
    public static String whereContactStr{get;set;}	
    // 追加api的set
    public static set<String> relcontact_apiset{get;set;}	
    // 获取XML定义条件	
    private static void loadIContactWhere(String preShopcode) {
	    // 自定义的检索条件
        whereContactStr = '';
        // 字段集合
        relcontact_apiset = new set<String>();
        String xmlName = 'RoomIndicatorInfoLeadOutputExtendFieldsXml';
	    try{
		    Dom.XMLNode targetNode = CommXmlUtils.parseXmlDoc(xmlName,preShopcode);
	        Dom.XmlNode relcontactNode =  targetNode.getChildElement('RELCONTACT', null);
	        // 循环外层的OR条件设定
	        for (Dom.xmlNode orNode : relcontactNode.getChildElements()) {
	        	String andWhereStr = '';
	        	// 循环内层的AND条件设定
	        	for(Dom.xmlNode andNode : orNode.getChildElements()){
	        		// 设定内容不可为空
	        		if(CommUtils.isBlank(CommUtils.nullToBlank(andNode.getText()))) continue;
	        		// 出力设定的API内容
	        		String apiNameStr= CommUtils.nullToBlank(andNode.getText().toLowerCase());
	        		if (!relcontact_apiset.contains(apiNameStr)) relcontact_apiset.add(apiNameStr);
	        		// 拼成AND检索条件字符串
	        		if(CommUtils.isBlank(andWhereStr)) andWhereStr = apiNameStr +' = '+apiNameStr + '_api ';
	        		else andWhereStr +=' and ' + apiNameStr+' = '+apiNameStr + '_api ';
	        	}
	        	// 拼成OR检索条件字符串
	        	if(CommUtils.isBlank(whereContactStr)) whereContactStr = '(' + andWhereStr + ')';
	        	else whereContactStr +=' or (' + andWhereStr + ')';
	        }
	    }catch (Exception e){ }
    }
    // 2019/12/30 名前か電話番号のどちらかだけ一致するお客様がすでに存在する BY zyz END
    // 2019/12/30 小部屋の作成 BY zyz BEGIN
    @RemoteAction
    global static Boolean leadNightInfo(String roomIdStr,String leadIndexStr,String EntryDateStr) {
    	// 连泊数据判定 连泊：true ；单泊：false
    	Boolean LeadStayNightFlg = false;
		// 日期转换
		Date EntryDate = Date.parse(EntryDateStr);
    	list<Lead__c> leadLst = [select Id from Lead__c where LeadIndexRef__c =: leadIndexStr and Rroom__c =: roomIdStr and DAY_ONLY(convertTimezone(EntryTime__c)) >= :EntryDate];
    	if(leadLst.size()> 1) LeadStayNightFlg = true;
    	return LeadStayNightFlg;
    }
    // 2020/02/29 小部屋機能改善 BY zyz BEGIN
    private static final String LEAD_NAME_PREFIX_ROOM = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomDelegatePrefix__c);
    // josn字符串
    class RoomLeadInfo{
		String leadId;					// 予约Id
		String roomNumStr;				// 小部屋做成数
    }
    @RemoteAction
    global static Boolean createLeadInfo(String leadJson,Boolean LeadStayNightFlg) {
    //global static Boolean createLeadInfo(String leadId,Boolean LeadStayNightFlg) {
    	if(CommUtils.isBlank(leadJson)) return false;
    	RoomLeadInfo info = (RoomLeadInfo)JSON.deserialize(leadJson,RoomLeadInfo.class);
    	String leadId = CommUtils.nullToBlank(info.leadId);
    	Integer RoomNum = CommUtils.NullToIntZero(info.roomNumStr);
    // 2020/02/29 小部屋機能改善 BY zyz END
    	// 返回结果，用于判断小部屋数据是否做成
    	Boolean statusValFlg = false;
    	// LEAD取得[部屋タイプー＞店舗コード、部屋ー＞店舗コード](無店舗可能性あり)
    	list<Lead__c> leadLst = [select Id,refTypeOfRooms__c,Rroom__c,LeadIndexRef__c,EntryTime__c,refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c,Rroom__r.ShopInfoRef__r.ShopCode__c from Lead__c where Id=:leadId];
    	Lead__c holdLead = leadLst[0];
    	// XML的code值处理
    	String shopCd = '';
    	if(!CommUtils.isBlank(holdLead.refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c)) shopCd = holdLead.refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c;
    	else if(!CommUtils.isBlank(holdLead.Rroom__r.ShopInfoRef__r.ShopCode__c)) shopCd = holdLead.Rroom__r.ShopInfoRef__r.ShopCode__c;
    	// 获取所有字段处理
    	Map<String, Schema.DescribeFieldResult> modelDeafaultValuesMaps = CommSqlUtils.getAllFieldLst(Lead__c.sObjectType,false,true);
		// 共通定义追加的时间
		Integer addStayHours = CommConst.DEF_DAYUSE_STAY_HOURS;
		// 获取XML定义内容
        String docName = 'RoomIndicatorInfoLeadOutputExtendFieldsXml';
        Dom.XmlNode shopRoot = CommXmlUtils.parseXmlDoc(docName, shopCd);
        Dom.XmlNode createInfoNode = shopRoot.getChildElement('CREATEINFO', null);
		// 主予约数据
		list<leadGroupTemplate>  groupLateLst = new list<leadGroupTemplate>();
        if(createInfoNode != null){
        	// 循环符合条件的定义
			for(Dom.xmlNode createNode : createInfoNode.getChildElements()){
        		groupLateLst.add(new leadGroupTemplate(createNode,modelDeafaultValuesMaps));
			}
        }
		leadGroupTemplate targetTemplate = null;
		// 取得符合数据的XML定义
		for (leadGroupTemplate gp : groupLateLst) {
			if (CommUtils.isBlank(gp.condition)) {
				targetTemplate = gp;
			} else {
				string wkQueryStr = 'select id from lead__c where id = :leadId and ' +gp.condition + ' limit 1';
				list<lead__c> leads = Database.query(wkQueryStr);
				if (!leads.isEmpty()) {
					targetTemplate = gp;
				}
			}
			if (targetTemplate != null) break;
		}
		// 做成小部屋数据集合
		list<Lead__c> smallLeadLst= new list<Lead__c>();
		// 做小部屋数据
		if(targetTemplate != null){
			// 获取房型的seq集合
			set<Decimal> roomTypeSeqset = targetTemplate.roomTypeSeqset;
			// 房型赋值的map<房型的seq,房型的Id> 
			map<String,string> roomTypeSepMap = new map<String,string>();
			if(!roomTypeSeqset.isEmpty()) {
				list<TypeOfRooms__c> roomTypeLst = [select Id,Name,Seq__c from TypeOfRooms__c where Seq__c =:roomTypeSeqset];
				for(TypeOfRooms__c roomtp : roomTypeLst){
					String seqVal = CommUtils.nullToBlank(roomtp.Seq__c);
					roomTypeSepMap.put(seqVal,roomtp.Id);
				}
			}
			// 取得SQL内容
			String ChildLeadApiStr = targetTemplate.queryfields;
			// 检索予约数据的sql
			String queryStr = 'select '+ ChildLeadApiStr + ' from Lead__c ';
			// 连泊做成还是单泊做成的check false:只做检索当前一笔数据做成；true:连泊数据检索后做成
			if(LeadStayNightFlg) {
				String leadIndexStr = holdLead.LeadIndexRef__c;
				String roomIdStr = holdLead.Rroom__c;
				Date EntryDate = holdLead.EntryTime__c.date();
				queryStr += 'where LeadIndexRef__c =: leadIndexStr and Rroom__c =: roomIdStr and DAY_ONLY(convertTimezone(EntryTime__c)) >= :EntryDate';
			}else {
				String leadIdStr = holdLead.Id;
				queryStr += ' where id =: leadIdStr ';
			}
			// 数据排序方式
			queryStr += ' Order By EntryTime__c asc ';
			// 做小部屋予约数据集合
			list<Lead__c> queryLeadLst= Database.query(queryStr);
			// 2020/02/29 小部屋機能改善 BY zyz BEGIN
			// 主予约数据的集合
			list<Lead__c> oldLeadLst= new list<Lead__c>();
			// 2020/02/29 小部屋機能改善 BY zyz END
			// 连泊数据处理
			for(lead__c ld : queryLeadLst){
				// groupNo设值
				Integer groupNoInt = 0;
				// 2020/02/29 小部屋機能改善 BY zyz BEGIN
				// 做成小部屋后，原予约数据的名称追加マーク
				String newLeadName = ld.Name;
				if (!newLeadName.startsWith(LEAD_NAME_PREFIX_ROOM)) {
					newLeadName = LEAD_NAME_PREFIX_ROOM + ' ' +newLeadName;
				}
				ld.Name = newLeadName;
				// 作成小部屋数量的设定循环
				for(Integer i=0; i < RoomNum; i++){
				// 2020/02/29 小部屋機能改善 BY zyz END
				// 对应所以数据内容的处理
				for(ChildLeadTemplate cl : targetTemplate.childs){
					// 初期部分默认值
					lead__c leadOne = new lead__c(
						Relcontact__c = ld.Relcontact__c,
						LeadIndexRef__c = ld.LeadIndexRef__c,
						ParentLeadId__c = ld.id,
						RoomGroupNo__c = groupNoInt,
						Name = ld.Relcontact__r.name,
						EntryTime__c = ld.EntryTime__c,
						Departure__c = ld.Departure__c,
						Field4__c = ld.Field4__c,
						Field3__c = ld.Field3__c,
						ReservedDate__c = ld.ReservedDate__c
					);
					// 房型设值
					if(roomTypeSepMap.containsKey(cl.roomtypeSeq) && !CommUtils.isBlank(cl.roomtypeSeq)){
						leadOne.refTypeOfRooms__c = roomTypeSepMap.get(cl.roomtypeSeq);
					}
					// copy主数据处理
					for(String coField : cl.cloneFieldlist){
						leadOne.put(coField,ld.get(coField));
					}
					// 设定自定义值
					for(OptionItem opField : cl.constFieldlist){
						// 字段API
						String apiKey = opField.val;
						// 字段XML指定值
						String apiVal = opField.lab;
						// 处理字段类型
						Schema.DescribeFieldResult dr = modelDeafaultValuesMaps.get(apiKey);
						if(!CommUtils.isBlank(apiVal)) leadOne.put(apiKey,CommUtils.ConvByFielType(apiVal,dr.getType()));
					}
					// 0泊数据 / 1泊数据
					if(cl.nights != null){
						// 获取数据：0泊还是1泊
						Integer nightInt = CommUtils.nullToIntZero(cl.nights);
						if(nightInt != 0) nightInt = 1;
						// 设定出发日期
						DateTime EntryTimeDate = leadOne.entrytime__c.addDays(nightInt);
						Time depTime = CommUtils.stringToTime(leadOne.field3__c);
						EntryTimeDate = DateTime.newInstance(EntryTimeDate.date(), depTime);
						leadOne.Departure__c = EntryTimeDate;
					}
					// 到着查分日期
					if(cl.offsetDays != null){
						// 差分日期
						Integer diffInt = CommUtils.nullToIntZero(cl.offsetDays);
						// 到着日
						leadOne.entrytime__c = leadOne.entrytime__c.addDays(diffInt);
						// 出発日
						leadOne.departure__c = leadOne.departure__c.addDays(diffInt);
					}
					groupNoInt++;
					smallLeadLst.add(leadOne);
				}
				// 2020/02/29 小部屋機能改善 BY zyz BEGIN
				}
				// 原予约数据的集合
				oldLeadLst.add(ld);
				// 2020/02/29 小部屋機能改善 BY zyz END
			}
			// 小部屋数据插入
			if(!smallLeadLst.isEmpty()) {
				// 数据追加IndexSubId
				CommLogicProcess logic = new CommLogicProcess();
				logic.autoCreateRoomIndexSub(smallLeadLst);
				// 数据插入
				insert smallLeadLst;
				// 2020/02/29 小部屋機能改善 BY zyz BEGIN
				// 更新原数据的マーク
				update oldLeadLst;
				// 2020/02/29 小部屋機能改善 BY zyz END				
				statusValFlg = true;
			}
		}
		return statusValFlg;
    }
    global class leadGroupTemplate {
    	public leadGroupTemplate(Dom.xmlNode defNode, Map<String, Schema.DescribeFieldResult> modelDeafaultValuesMaps) {
    		condition = CommUtils.nullToBlank(defNode.getAttribute('CONTION',null));
    		childs = new list<ChildLeadTemplate>();
    		for(Dom.xmlNode leadsNode : defNode.getChildElements()){
    			childs.add(new ChildLeadTemplate(leadsNode,modelDeafaultValuesMaps));
    		}
    	}
    	string condition{get;set;}
    	list<ChildLeadTemplate> childs{get;set;}
    	// コピー取得
    	string queryfields{get{
    		set<string> fieldset = new set<string>{'id','name','field3__c','field4__c','entrytime__c','departure__c','reserveddate__c','relcontact__c','relcontact__r.name','leadindexref__c','leadindexsubid__c','leadindexref__r.contactref__c','leadindexref__r.channel__c','leadindexref__r.segment__c','leadindexref__r.leadname__c','leadindexref__r.comment__c','leadindexref__r.payment__c'};
    		for (ChildLeadTemplate tp : childs) {
    			for(String childApi : tp.allApiSet){
					if (fieldset.contains(childApi)) continue;
					fieldset.add(childApi);
    			}
    		}
    		return String.join(new List<String>(fieldset),',');
    	}}
    	// 房型Seq取得
    	set<Decimal> roomTypeSeqset{get{
    		set<Decimal> roomTypeset = new set<Decimal>();
    		for (ChildLeadTemplate tp : childs) {
    			Decimal seqDec= CommUtils.nullToZero(tp.roomtypeSeq);
    			if (roomTypeset.contains(seqDec)) continue;
    			roomTypeset.add(seqDec);
    		}
    		return roomTypeset;
    	}}
    }
   	global class ChildLeadTemplate {
   		public ChildLeadTemplate(Dom.xmlNode defNode,Map<String, Schema.DescribeFieldResult> modelDeafaultValuesMaps) {
   			// 固定値APIリストを格納する
   			constFieldlist = new list<OptionItem>();
   			cloneFieldlist = new list<String>();
   			roomtypeSeq = '';
   			nights = CommUtils.nullToZero(defNode.getAttribute('NIGHTS',null));
   			offsetDays = CommUtils.nullToZero(defNode.getAttribute('OFFSETDAYS',null));
   			// 重复字段处理
   			allApiSet = new set<String>();
   			for(Dom.xmlNode leadNode : defNode.getChildElements()){
	   			String tagNm = leadNode.getName();
				// 新数据的值在XML自定义
				if(tagNm == 'ASSIGN'){
					String fieldApiStr = CommUtils.nullToBlank(leadNode.getAttribute('FIELD',null)).toLowerCase();
					String fieldvalStr = CommUtils.nullToBlank(leadNode.getText());
					// 无效的字段判断
					if(!modelDeafaultValuesMaps.containsKey(fieldApiStr))continue;
					// jzdmap.put(fieldApiStr,fieldvalStr);
					if (allApiSet.contains(fieldApiStr)) continue;
					allApiSet.add(fieldApiStr);
					constFieldlist.add(new OptionItem(fieldApiStr,fieldvalStr));
				// 新数据的值copy主数据的值
				}else if(tagNm == 'CLONE'){
					String fieldApis = CommUtils.nullToBlank(leadNode.getText()).toLowerCase().deleteWhitespace().trim();
					for(String api : fieldApis.split(',')){
						// 无效的字段判断
						if(!modelDeafaultValuesMaps.containsKey(api))continue;
						if (allApiSet.contains(api)) continue;
						allApiSet.add(api);
						cloneFieldlist.add(api);
					}
				// 房型数据的特殊处理
				}else if(tagNm == 'ROOMTYPE'){
					roomtypeSeq = CommUtils.nullToBlank(leadNode.getText());
				}
   			}
   		} 
   		// 部屋タイプSEQ
   		String roomtypeSeq{get;set;}
   		// 拍数
   		decimal nights{get;set;}
   		// 到着日により差分日数
   		decimal offsetDays{get;set;}
   		// コピー元API
   		list<String> cloneFieldlist{get;set;}
   		// 固定値設定API配列
   		list<OptionItem> constFieldlist{get;set;}
   		// 所有定义的有效字段
   		set<String> allApiSet{get;set;}
   	}
    // 2019/12/30 小部屋の作成 BY zyz END
	// 2020/02/29 レジカードのロゴを出力した部屋の「店舗情報」対応 BY zyz BEGIN
	public Boolean CashLogoFlg{get{return CommConst.APPOTION_CARREGISTER_LOGO_FLG;}}
	public String shopLst{get{
	    	String shopLstStr ='';
	    	if(CashLogoFlg) {
	    		List<String> ShopInfoLst = ShopInfoUtil.getCanSelectShopLst(UserInfo.getUserId());
	    		if(!ShopInfoLst.isEmpty() && ShopInfoLst.size() > 1) shopLstStr = JSON.serialize(ShopInfoLst);
	    	}
	    	return shopLstStr;
	}}
	// 2020/02/29 レジカードのロゴを出力した部屋の「店舗情報」対応 BY zyz END
	// 2020/02/29 小部屋機能改善 BY zyz BEGIN
	public map<String,Boolean> roomFlgMap{get;set;} // 显示小部屋启动的设定
	public Boolean defRoomFlg{get;set;} // 默认的值
	public String roomSelectJsonStr{get;set;} // 显示小部屋启动的设定json
	public Boolean defRoomWinFlg{get;set;} // 默认的值
	// 初期XML设定小部屋显示条件和启动小部屋作成状态
	private String getXmlRoomWhere() {
		// 数据处理条件的map
		map<String,String> codeMap = new map<String,String>();
		// 小部屋启动window的储存
		map<String,Boolean> roomWindowMap = new map<String,Boolean>();
		// 小部屋是否在主予约显示的控制map
		roomFlgMap = new map<String,Boolean>();
		// 小部屋数据条件
		String roomWhereStr = '';
		Boolean defWhereFlg = true;
		String defWhereStr = '';
		// 小部屋主房间显示的默认值
		String defRoomStr = '';
		defRoomFlg = true;
		// 小部屋启动window的默认值
		String defRoomWinStr = '';
		defRoomWinFlg = false;
		// 获取整个XML定义
		try{
			String docName = 'RoomIndicatorInfoLeadOutputExtendFieldsXml';
			List<Dom.XmlNode> shopRootList = CommXmlUtils.getAllTopXmlNode(docName);
			for (Dom.XmlNode shopRoot : shopRootList) {
				// 店舗コード
	   	 		Dom.XmlNode shopCodeField =  shopRoot.getChildElement('SHOPCODE', null);
				String shopcode = CommUtils.nullToBlank(shopCodeField.getText());
				// SET XML
				Dom.XmlNode nodeCreate =  shopRoot.getChildElement('CREATEINFO', null);
				String whereStr = '';
			  	if (nodeCreate != null) {
			  		whereStr = CommUtils.nullToBlank(nodeCreate.getAttribute('SUBFILTER',null)).toLowerCase();
			  		if(defWhereFlg) {
			  			defWhereFlg = false;
			  			defWhereStr = whereStr;
			  		}
			  		String roomFlgStr = CommUtils.nullToBlank(nodeCreate.getAttribute('SUBICONFLG',null)).toLowerCase();
			  		// 小部屋主房间显示的默认值处理
			  		if(CommUtils.isBlank(defRoomStr)) {
			  			defRoomStr = roomFlgStr;
			  			defRoomFlg = boolean.valueOf(roomFlgStr);
			  		}
			  		if (!roomFlgMap.containsKey(shopcode)) roomFlgMap.put(shopcode,boolean.valueOf(roomFlgStr));
			  		String roomWindowFlgStr = CommUtils.nullToBlank(nodeCreate.getAttribute('CREATENUMS',null)).toLowerCase();
			  		// 小部屋启动window的默认值处理
			  		if(CommUtils.isBlank(roomWindowFlgStr)) {
			  			defRoomWinStr = roomWindowFlgStr;
			  			defRoomWinFlg = boolean.valueOf(roomWindowFlgStr);
			  		}
			  		if (!roomWindowMap.containsKey(shopcode)) roomWindowMap.put(shopcode,boolean.valueOf(roomWindowFlgStr));
			  	}
			  	if (!codeMap.containsKey(shopcode) && !CommUtils.isBlank(whereStr)) codeMap.put(shopcode,whereStr);
			}
		} catch(Exception e){}
		// 启动window控制json
		roomSelectJsonStr = JSON.serialize(roomWindowMap);
		// 处理数据的where条件
		if(!shopInfoMap.isEmpty()){
			for(String key : shopInfoMap.keyset()){
				// 获取XML的定义条件
				String val = CommUtils.nullToBlank(codeMap.get(key));
				if(CommUtils.isBlank(val) && CommUtils.isBlank(defWhereStr)) continue;
				if(!CommUtils.isBlank(roomWhereStr)) roomWhereStr +=' or ';
				// 条件为空，使用默认的条件
				if(CommUtils.isBlank(val)) roomWhereStr += ' ( refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c = \'' + key+'\' and ( '+ defWhereStr + ' )) ';
				else roomWhereStr += ' ( refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c = \'' + key+'\' and ( '+ val + ' )) ';
			}
		} else {
			// Default XMLの抽出条件を設定
			if (!CommUtils.isBlank(defWhereStr)) roomWhereStr = ' (' + defWhereStr + ' ) ';
		}
		return roomWhereStr;
	}
	// 2020/02/29 小部屋機能改善 BY zyz END
	// 2020/02/28 ルームインジケータ、タイムテーブル改修対象画面 BY zyz BEGIN
	public boolean confirmChgFlg{get;set;}
	// 2020/02/28 ルームインジケータ、タイムテーブル改修対象画面 BY zyz END
	// 2020/09/30 当日チェックアウトの日帰り予約がチェックイン後にルームチェンジできなくなる不具合の解消 by zy BEGIN
	private boolean oneDayCanMoveFlg; // XML設定
	// 2020/09/30 当日チェックアウトの日帰り予約がチェックイン後にルームチェンジできなくなる不具合の解消 by zy END
    // 2021/03/05 50001エラー修正 by zy BEGIN
    public String limitShopStr{get;set;} // 限制内店舗コード
    private Integer limitSize = 600;     // ALL店舗処理部屋数限界のデフォルト値
    // 2021/03/05 50001エラー修正 by zy END
}