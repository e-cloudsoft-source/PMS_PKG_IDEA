public with sharing class StaffTaskCtrl {
	public String leadJson{get;set;}
	public String infos {get;set;}
	public String dispHeaderJson{get;set;}
	public String staffJson{get;set;}
	// Calendar情報格納用
	public CalendarExtend calExt{get; private set;}
	//通常
    private String CONST_NORMAL_HOTEL = Label.CONST_035_0145;
    private String CONST_NORMAL_COLOR = 'black';							// 默认颜色
	private String CONST_NORMAL_OTCOLOR = 'red';							// 非默认颜色
	public String getNoramlStatus() {return CONST_NORMAL_HOTEL;}
	public String taskJson{get;set;}
	/* 旧画面に変数 BEGIN */
	// 画面レイアウト定数定義
	// 処理日付
	private Date processDay;
	// 表示の開始日
	private Date startDate;
	// 処理月・日数
	private Integer daysInMonth;
	// 処理年
	public Integer thisYear{get; set;}
	// 処理月
	public Integer thisMonth{get; set;}
	public Decimal allWorkDaysCount{get;set;}
	private Set<Id> canEditRoleUserIds;
	// 画面上に表示される予約一覧のヘッダー部
	public transient List<dispHeader> dispHeaders{get;set;}
	// 画面上に表示される予約一覧のデータ部
	private static Boolean isNightIncludeMode = true;
	// 2019/09/22 不具合改修：マルチタスク機能、エラー『コレクションサイズ1,013が1,000の最大サイズを超えています。』の不具合改修 by zy BEGIN
	public transient List<UserSection> userInfos{get;set;}
	// 2019/09/22 不具合改修：マルチタスク機能、エラー『コレクションサイズ1,013が1,000の最大サイズを超えています。』の不具合改修 by zy END
	public transient List<User> userLst{get; private set;}	
	// 並び順項目格納用
	public String getSortFieldForUser(){return 'user';}
	public String getSortFieldForDepart(){return 'dept';}
	public String currSortField{get; private set;}
	public String currSortStatus{get; private set;}
	public String currSortStatusMark{get{return ( currSortStatus == 'asc'  ? '▲':'▼');}}
	// Header色制御
    public transient Map<Integer, String> headerColorMap{get; private set;}
    // 詳細列のステータス制御変数定義
    public transient Map<Date, colStatus> colStatusMap{get; private set;}
	// 六輝表示がどうか判断用 TRUE:表示
	public boolean isShowQreqki{get{return CommConst.IsOrgRokuyoIsNoShow();}}
	// 休館情報を格納する
    public transient Map<Integer,String> restInfoMap{get; private set;}
    // 開始日表示モード："1":毎月の１日から一月間データを表示する（Default値）/ "2":当日から一月間データを表示する
	private static final Boolean CONST_SHOW_START_TODAY = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomTypeStartDateMode__c) == '2' ? true :false;
    public transient Map<String,Decimal> dayTimeWroksSumMap{get;set;}	// 日別勤怠時間集計値
    public transient Map<Id, dispRecord> dispRecordMap{get; private set;}
    // スタッフのステータスとコメント区分キー
    public String getStaffStatusMsgKbn(){return 's_';}
    public String getStaffCommentMsgKbn(){return 'c_';}
    public String getStaffStopStatusMsgKbn(){return 't_';}
	// 集計指定店舗コード情報可能
	public String summaryShopCode{get; private set;}
    public Boolean blackFlag{get;set;}
    public List<String> taskHtml{get;set;}
    // 照会指定日情報を格納する
	public BookingTimeTable__c timeTable{get;set;}
	private Date orgDate;
	private Date xmlSetDay;
	public String eventTitle{get;private set;}
	public String taskColor{get;set;}
	// 2018/03/23 部署は複数選択できる機能対応 BY WGCH BEGIN
	public String multiDepartCds{get; set;}
	// 2018/03/23 部署は複数選択できる機能対応 BY WGCH END
	// 2018/03/27 タスクのTITLE変更可能機能追加　by　zy　BEGIN
	public Boolean isTitleChg{get;set;}
	// 2018/03/27 タスクのTITLE変更可能機能追加　by　zy　END
	/* 旧画面に変数 END */
	public StaffTaskCtrl(ApexPages.StandardController controller,Map<String,String> paramsMap){
		//parMap = paramsMap;
		initInfo();
	}
	public StaffTaskCtrl(ApexPages.StandardController controller){
    	// パラメータ情報を取得する
    	initInfo();
    }
    public StaffTaskCtrl(){
    	initInfo();
    }
    // -------------------------------------------
   	// 各店舗の表示する項目情報を取得、格納を行う
    // -------------------------------------------
	// 初期処理
	public void init(){
		// 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy BEGIN
    	if(hadDateFlg) doAction(0);
		// 初期情報を設定する
		else doAction(null);
		// 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy END
	}
	private void oldInit(){
	   currSortField = getSortFieldForUser();
	   currSortStatus = 'asc';
	   // 部屋の支店選択リスト設定する
	   setInitBranShopLst();
	   // 部署選択リスト値設定
	   setDeaprtList();
	   // 部屋ステータス初期化
	   initRoomStatusList();
	   // ロール処理
	   initEditRoleInfo();
	   // Calendar情報初期化
	   calExt = new CalendarExtend(true);
	   // 2019/08/31 マルチタスクについて、今「その他」で絞りをかけた後画面更新（Command+R）をするとプロジェクト管理が消えました。絞り込みの保持 by zy BEGIN
	   // Cookieからレイアウトモードを取得する
       	   // map<String,String> userBookMap = UserConfigCompCtrl.getCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.TASK,UserUtil.CurrentUser.id,'');
	   userBookMap = UserConfigCompCtrl.getCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.TASK,UserUtil.CurrentUser.id,'');
	   // 2019/08/31 マルチタスクについて、今「その他」で絞りをかけた後画面更新（Command+R）をするとプロジェクト管理が消えました。絞り込みの保持 by zy END
	   String viewModeStr = CommUtils.nullToBlank(userBookMap.get(UserConfigCompCtrl.KREP_SUBTYPE.VIEWMODE.name()));
	   // 2019/09/15 キーワード検索機能ですがAND検索になっていますのでORの検索もできればいい by zy BEGIN
	   isOrFlg = true;
	   if (viewModeStr.contains('orFlg')) {
		   CookieInfo req = (CookieInfo)JSON.deserializeStrict(viewModeStr, CookieInfo.class);
		   viewModeStr = req.viewMode;
		   isOrFlg = Boolean.valueOf(CommUtils.nullToBlank(req.orFlg));
		   // 2019/09/15 マルチタスクで自分専用のグループを作れるようにする(高) by zy BEGIN
		   pUserGroupId = userGroupId = Commutils.nullToBlank(req.userGroupId);
		   // 2019/09/15 マルチタスクで自分専用のグループを作れるようにする(高) by zy END
	   }
	   // 2019/09/15 キーワード検索機能ですがAND検索になっていますのでORの検索もできればいい by zy END
       // 画面モード初期値を設定する
       viewMode = CommUtils.isBlank(viewModeStr) ? CONST_VIEWMODE_4 : viewModeStr;
	   // 2017/09/11 シフト画面に設定条件を自動記憶する BEGIN
	   // ページから引き渡す情報が存在するとき、関連情報を初期設定する
	   Map<String,String> parMap = ApexPages.currentPage().getParameters();
	   if (parMap.containsKey('pspcd')) branchShopNm = CommUtils.nullToBlank(parMap.get('pspcd'));
	   if (parMap.containsKey('pdpcd')) departCd = CommUtils.nullToBlank(parMap.get('pdpcd'));
	   if (parMap.containsKey('pyr')) thisYear = CommUtils.nullToIntZero(parMap.get('pyr'));
	   if (parMap.containsKey('pmo')) thisMonth = CommUtils.nullToIntZero(parMap.get('pmo'));
	   if (parMap.containsKey('pstkey')) currSortField = CommUtils.nullToBlank(parMap.get('pstkey'));//並び順キー
	   if (parMap.containsKey('pstval')) currSortStatus = CommUtils.nullToBlank(parMap.get('pstval'));//並び順値
	}
	// 年・月を選択する場合
    public void gotoYearMonth() {
    	// 選択する年月にて、今日までの月数を計算を行う
        //Date selDate = Date.newInstance(thisYear, thisMonth, Date.today().day());
    	//doAction(processDay.monthsBetween(selDate));
    	doAction(0);
    }
	// 支店設定変更する場合
	public void changeBranchShop() {
		// 2018/03/23 部署は複数選択できる機能対応 BY WGCH BEGIN
		multiDepartCds = '';
		// 2018/03/23 部署は複数選択できる機能対応 BY WGCH END
		// 2015/10/29 部署選択リスト値設定ロジック変更 BEGIN
		setDeaprtList();
		// 2015/10/29 部署選択リスト値設定ロジック変更 END
		// 最新情報を取得する
		refreshNewInfo();
	}
	// 画面最新情報を表示する
	public void refreshNewInfo() {
		doAction(0);
	}
	public void refreshMode() {
		if ( orgDate == timeTable.Checkinday__c) {
			if ( viewMode != CONST_VIEWMODE_1) {
				timeTable.Checkinday__c = system.today();
				orgDate = timeTable.Checkinday__c;
			} else {
				timeTable.Checkinday__c = xmlSetDay;
				orgDate = xmlSetDay;
			}
		}
		doAction(0);
		// 2019/09/15 キーワード検索機能ですがAND検索になっていますのでORの検索もできればいい by zy BEGIN
		// UserConfigCompCtrl.saveCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.TASK,
				// UserConfigCompCtrl.KREP_SUBTYPE.VIEWMODE.name(),viewMode,UserUtil.CurrentUser.id,'');
		saveSettingCookie();
		// 2019/09/15 キーワード検索機能ですがAND検索になっていますのでORの検索もできればいい by zy END
	}
	// Tier/営業のHeader部情報を表示・非表示制御する
    public Boolean isShowBussinisHeader {get{
    	// 支店あり、全店舗を選べる場合、TIERのHeader情報を非表示する
    	return !(CommUtils.isBlank(branchShopNm) && branchShopLst.size() > 0);
    }}
	private void setDeaprtList() {
		departCodeLst = new List<Selectoption>();
		String departQuery = 'select Department depart from User where StaffScheduleNoshow__c != true And IsActive = true And Department != null ';
        if (!CommUtils.isBlank(branchShopNm)) {
            departQuery += 'and ( DefaultShopCode__c = :branchShopNm or ShopCode__c = :branchShopNm ) ';
        }else if (userInf.isShopCodePlex) {
            Set<String> shopSt = userInf.shopSt;
            departQuery += 'and ( DefaultShopCode__c = :shopSt or ShopCode__c = :shopSt ) ';
        }
        departQuery += 'Group By Department Order By Department ';
        List<AggregateResult> etResult = DataBase.query(departQuery);
        // 部署選択リストを初期化する
        
        for (AggregateResult rs : etResult) {
        	String departVal = CommUtils.nullToBlank(rs.get('depart'));
        	departCodeLst.add(new SelectOption(departVal, departVal));
        }
        // 2018/03/23 部署は複数選択できる機能対応 BY WGCH BEGIN
		departCd = multiDepartCds = '';
		// 2018/03/23 部署は複数選択できる機能対応 BY WGCH END
	}
    private void initInfo(){
    	Map<String,String> parMap = ApexPages.currentPage().getParameters();
    	blackFlag = parMap.containsKey('back');
    	taskColor = '#004080';
    	isTitleChg = false;
    	if (!blackFlag) oldInit();
    	// 2018/07/13 プロジェックト機能追加 by zy BEGIN
    	userSet = new Set<String>();
    	if (parMap.containsKey('Project')){
    		String projectId = parMap.get('Project');
    		List<ProjectMain__c> projectLst = [select id,AssignUser__c,ManagerUser__c from projectMain__c where id = :projectId];
    		if (!projectLst.isEmpty()) {
    			userSet = new Set<String>(CommUtils.nullToBlank(projectLst[0].AssignUser__c).split(','));
    			userSet.addAll(CommUtils.nullToBlank(projectLst[0].ManagerUser__c).split(','));
    		}
    	}
    	// 2018/07/13 プロジェックト機能追加 by zy END
    	// 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy BEGIN
    	if (parMap.containsKey('dt')) {
    		String dtFormat = parMap.get('dt');
    		hadDateFlg = true;
    		processDay = CommUtils.stringToDate(dtFormat);
    	}
    	if (parMap.containsKey('owner')) {
    		String userId = parMap.get('owner');
    		userSet = new Set<String>{userId};
    	}
    	// 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy END
    }
    // 2018/07/13 プロジェックト機能追加 by zy BEGIN
    public Set<String>userSet;
    // 2018/07/13 プロジェックト機能追加 by zy END
    private void refreshViewMode(){
    	// 変数の初期化
		dispHeaders = new List<dispHeader>();
		// Header曜日の色制御設定
		headerColorMap = new Map<Integer, String>();
		// 詳細列のステータス制御変数定義
		colStatusMap = new Map<Date, colStatus>();
		// データ表示開始日
		Date conStartDate = startDate;
		// 日別勤怠時間合計値
		dayTimeWroksSumMap = new Map<String,Decimal>();
		// XML設定情報を取得する
        AppConfig appConfig = new AppConfig(branchShopNm, null);
        integer hours = 24;
        Map<String,List<String>> dateTitles = new Map<String,List<String>> ();
        // 処理月・日数の設定
		if ( viewMode == CONST_VIEWMODE_1) {
			daysInMonth = Date.daysInMonth(thisYear, thisMonth);
			viewWidth = '100px;';
		} else if ( viewMode == CONST_VIEWMODE_2) {
			daysInMonth = 7;
			viewWidth = '200px;';
			// 2019/05/15 タスク管理でルームインジケーターの様に前日当日翌日のボタンを設置する事は可能でしょうか。
   			// また7日で表示させた際に4時間ごとの時間の区切りになりますが、1時間ごとの表示にすることは叶いませんでしょうか by zy BEGIN
			if (is24HourFlg) viewWidth = '660px';
			// 2019/05/15 タスク管理でルームインジケーターの様に前日当日翌日のボタンを設置する事は可能でしょうか。
   			// また7日で表示させた際に4時間ごとの時間の区切りになりますが、1時間ごとの表示にすることは叶いませんでしょうか by zy END
		} else if ( viewMode == CONST_VIEWMODE_5 || viewMode == CONST_VIEWMODE_4) {
			String beginTime = '05:00';
			Datetime begTime = Datetime.newInstance(startDate,CommUtils.stringtotime(beginTime));
			for (integer i = 0; i < hours ; i++) {
				String curDt = begTime.format('yyyy/MM/dd');
				if (!dateTitles.containsKey(curDt)) dateTitles.put(curDt,new List<String>());
				dateTitles.get(curDt).add(begTime.format('HH'));
				begTime = begTime.addHours(1);
			}
			daysInMonth = dateTitles.keySet().size();
			viewWidth = '';
		}
		// 2019/04/30 マルチタスクについて表示を「31日」にしても、30日分しか表示されません。 by zy BEGIN
		if (viewMode == CONST_VIEWMODE_1 && daysInMonth < 31) daysInMonth = 31;
		// データ表示終了日
		Date conEndDate = startDate.addDays(daysInMonth-1);
		// 2019/04/30 マルチタスクについて表示を「31日」にしても、30日分しか表示されません。 by zy END
        // 営業情報を取得する
        queryRestHotelInfo(conStartDate, conEndDate);
		// 画面上に表示される予約一覧のヘッダー部を構築する
		for(Integer i = 1; i <= daysInMonth; i ++){
			//Date tempDt = Date.newinstance(thisYear, thisMonth, i);
			Date tempDt = startDate.addDays(i-1);
			// 表示形式は「 日(曜日) 」
			String strYobi = getYobi(tempDt);
			//dispHeaders.add(new dispHeader(i, i+'(' + strYobi + ')', tempDt.format()));
			dispHeader header = new dispHeader(i, tempDt.day()+'(' + strYobi + ')', tempDt.format());
			// 営業日は休館　OR　未来日の場合、個別設定
			// ALLの店舗の場合、営業ステータスは共通できないので、営業日チェツクを行うない
			if (restInfoMap != null && appConfig.isCloseStatus(restInfoMap.get(header.days))) {
				header.isCloseOrFutureDay = true;
			}
			header.headTitles = new List<String>();
			// 処理月・日数の設定
			if ( viewMode == CONST_VIEWMODE_1) {
				header.headTitles = new List<String>{'0','6','12','18'};
			} else if ( viewMode == CONST_VIEWMODE_2) {
				header.headTitles = new List<String>{'0','4','8','12','16','20'};
				// 2019/05/15 タスク管理でルームインジケーターの様に前日当日翌日のボタンを設置する事は可能でしょうか。
	   			// また7日で表示させた際に4時間ごとの時間の区切りになりますが、1時間ごとの表示にすることは叶いませんでしょうか by zy BEGIN
				if (is24HourFlg) header.headTitles = new List<String>{'0','1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22','23'};
				// 2019/05/15 タスク管理でルームインジケーターの様に前日当日翌日のボタンを設置する事は可能でしょうか。
	   			// また7日で表示させた際に4時間ごとの時間の区切りになりますが、1時間ごとの表示にすることは叶いませんでしょうか by zy END
			} else if ( viewMode == CONST_VIEWMODE_4 || viewMode == CONST_VIEWMODE_5) {
				header.headTitles = dateTitles.get(tempDt.format());
				decimal orgDec = header.headTitles.size();
				header.viewWidth = CommUtils.nullToZero(orgDec.divide(hours,2) * 100) + '%';
			}
			dispHeaders.add(header);
			// 初期化を行う
			// Header曜日の色を個別設定を行う
			String colColor = '';
			//土
			if (strYobi == Label.CONST_035_0143) colColor = '#ffff66';
			//日
            else if (strYobi == Label.CONST_035_0144) colColor = '#ff3366';
            // 2014/02/07 祝い日
            if (calExt.holidayMap.containsKey(tempDt)) {
            	colColor = '#ff3366';
            	header.holidayLab = calExt.holidayMap.get(tempDt);
            }
            headerColorMap.put(i, colColor);
            // 各列の制御情報を初期化する
            colStatusMap.put(tempDt, new colStatus(colColor));
            // 初期化する
            dayTimeWroksSumMap.put(header.name,0);
		}		
		//roomTypeLst = (new CommLogicProcess()).getTypeOfRooms(branchShopNm);
		
    }
    // 2015/10/29 部署選択リスト値設定ロジック変更 END
	// 画面表示処理ロジック
	private void doAction(Integer month){
		if (blackFlag) return;
		//newLead = new Lead__c();
		//newContact = new Contact();
		userCodeLst = new List<Selectoption>();
    	//newLead.RecordTypeId = CommLogicProcess.getLeadBookingRecType();
    	// チェックイン時刻、チェックアウト時刻
    	//newLead.Field4__c = CommConst.DEF_CHECKIN_TIME;
    	//newLead.Field3__c = CommConst.DEF_CHECKOT_TIME;
    	// 2016/07/22  ゆもとや様より改善要望(シフト表示開始日の変更)  wgch		BEGIN
        // XML設定情報を取得する
        AppConfig appConfig = new AppConfig(branchShopNm, null);
        // 2016/07/22  ゆもとや様より改善要望(シフト表示開始日の変更)  wgch		END
        // 2017/09/05 指定権限制限機能追加 BEGIN
        RoleConfig roleConfig = new RoleConfig(branchShopNm, null);
        // 2017/09/05 指定権限制限機能追加 END
        TaskConfig taskConfig = new TaskConfig(branchShopNm, null,appConfig.eventTitle);
        // 2019/05/15 タスク管理でルームインジケーターの様に前日当日翌日のボタンを設置する事は可能でしょうか。
		
		// また7で表示させた際に4時間ごとの時間の区切りになりますが、1時間ごとの表示にすることは叶いませんでしょうか by zy BEGIN
        initDocment();
        // 2019/05/15 タスク管理でルームインジケーターの様に前日当日翌日のボタンを設置する事は可能でしょうか。
		// また7で表示させた際に4時間ごとの時間の区切りになりますが、1時間ごとの表示にすることは叶いませんでしょうか by zy END
        if (!CommUtils.isblank(taskConfig.color))taskColor = taskConfig.color;
        taskHtml = taskConfig.taskHtmlLst;
        eventTitle = appConfig.eventTitle;
		// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy BEGIN
		tempJson = taskConfig.tempInfoJson;
		// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy END	
       	// 2018/03/27 タスクのTITLE変更可能機能追加　by　zy　BEGIN
		isTitleChg = taskConfig.quickUpdFlag;
		// 2018/03/27 タスクのTITLE変更可能機能追加　by　zy　END
		// 2019/04/15 登録したタスクをダブルクリックで行動にリンクする by zy BEGIN
		isBothUpd = taskConfig.bothUpdFlag;
		// 2019/04/15 登録したタスクをダブルクリックで行動にリンクする by zy END
		// 初回表示時に、処理日付を現在の日付で設定
		if(month == null) {
		    // 2017/09/11 シフト画面に設定条件を自動記憶する BEGIN
			//processDay = Date.today();
			if (thisYear == null || thisMonth == null) processDay = Date.today();
			else processDay = Date.newinstance(thisYear, thisMonth, 1);
			// 2017/09/11 シフト画面に設定条件を自動記憶する END
		}
		// 先月・来月ボタン押下時に、処理日付を変更する
		else if(month != null && thisYear != null && thisMonth != null) {
			processDay = Date.newinstance(thisYear, thisMonth, 1).addMonths(month);
		}
		// 保存ボタン押下後、処理日付を到着日の月を設定する
		else if(month == 0){}

		// 処理年の設定
		thisYear = processDay.year();
		// 処理月の設定
		thisMonth = processDay.month();
		// 処理月・日数の設定
		if ( viewMode == CONST_VIEWMODE_1) {
			daysInMonth = Date.daysInMonth(thisYear, thisMonth);
		} else if ( viewMode == CONST_VIEWMODE_2) {
			daysInMonth = 7;
		} else if ( viewMode == CONST_VIEWMODE_5) {
			daysInMonth = 1;
		}
		// データ表示の開始日設定を行う【当日は開始日として、データ表示したい場合】
		if (CONST_SHOW_START_TODAY) {
			// 指定の日付により
			Date todayDt = Date.today();//Date.newInstance(2014,5,31);
			if (startDate == null) startDate = todayDt;
			// 指定の年月と開始日の年月の月数差
			//startDate = startDate.addDays(CommUtils.nullToIntZero(month) * 30);
			Integer diffmonths = todayDt.monthsBetween(processDay);
			//Date orgStartDate = startDate.addDays();
			startDate = todayDt.addMonths(diffmonths);
			Date endDate = todayDt.addMonths(diffmonths == 0 ? 1 : diffmonths+1).addDays(-1);
			daysInMonth = startDate.daysBetween(endDate) + 1;
		} else {
			// 毎月の１日から予約情報を表示の設定
			startDate = Date.newinstance(thisYear, thisMonth, 1);
		}
		// 2013/12/14 
		// 2016/07/22  ゆもとや様より改善要望(シフト表示開始日の変更)  wgch		BEGIN
		// 2017/05/26 シフトの開始日は変更できるように改善対応 Wgch BEGIN
		//if(appConfig.bussEndDayTitle != null && !CONST_SHOW_START_TODAY){
		if(appConfig.bussEndDayTitle != null && appConfig.bussStartDayTitle == null && !CONST_SHOW_START_TODAY ){
		// 2017/05/26 シフトの開始日は変更できるように改善対応 Wgch END
			// 表示期間の日付を再設定を行う
			// 処理日の当月の初日の日付を取得する
			Date wkCurrMonthFirstDay = Date.newInstance(thisYear,thisMonth,1);
			// 処理日の前月を最大日数を取得する
			Date wkPreMonthLastDay = wkCurrMonthFirstDay.addDays(-1);
			Integer wkPreMonthMaxDays = Date.daysInMonth(wkPreMonthLastDay.year(), wkPreMonthLastDay.month());
			// 指定の営業日は今月の最終表示日
			Integer wkLastDay = appConfig.bussEndDayTitle;
			// 指定の営業日＞今月の最大日付の場合、該当最大日付は表示まで日
			if (wkLastDay > daysInMonth) wkLastDay = daysInMonth;
			Date wkConEndDate = Date.newinstance(thisYear,thisMonth,wkLastDay);
			// 先月の表示開始日を計算する
			// 表示開始の日付 > 先月の最大日付の場合、
			Integer wkBegingDayNum = appConfig.bussEndDayTitle + 1;
			if (wkBegingDayNum > wkPreMonthMaxDays) startDate = Date.newinstance(thisYear,thisMonth,1);
			else startDate = Date.newinstance(wkPreMonthLastDay.year(), wkPreMonthLastDay.month(),wkBegingDayNum);
			daysInMonth = startDate.daysBetween(wkConEndDate) + 1;
		}
		// 2016/07/22  ゆもとや様より改善要望(シフト表示開始日の変更)  wgch		END
		// 指定店舗コード情報を設定する
        summaryShopCode = appConfig.summaryShopCode;
		// 2017/05/26 シフトの開始日は変更できるように改善対応 Wgch BEGIN
		if(appConfig.bussStartDayTitle != null){
			// 表示期間の日付を再設定を行う
			// 処理日の当月の初日の日付を取得する
			Date wkCurrMonthFirstDay = Date.newInstance(thisYear,thisMonth,1);
			// 开始日 所在月的最大天数取得
			Integer wkPreMonthMaxDays = Date.daysInMonth(wkCurrMonthFirstDay.year(), wkCurrMonthFirstDay.month());
			// 下个月最大天数取得
			Integer wkNextMonthMaxDays = Date.daysInMonth(wkCurrMonthFirstDay.year(), wkCurrMonthFirstDay.month()+1);
			// 指定の営業日は今月の开始表示日
			Integer wkStartDay = appConfig.bussStartDayTitle;
			// 指定の営業日は今月の结束表示日
			Integer wkLastDay = wkStartDay - 1;
			// 开始日 是否符合所在月的最大天数处理
			if (wkStartDay >= wkPreMonthMaxDays){
				wkStartDay = wkPreMonthMaxDays;
				wkLastDay = wkNextMonthMaxDays - 1;
			}
			// 指定の営業日＞今月の最大日付の場合、該当最大日付は表示まで日
			if (wkLastDay >= wkNextMonthMaxDays) wkLastDay = wkNextMonthMaxDays - 1;
			Date wkConEndDate;
			// 指定の営業日  ==>> 开始日
			startDate = Date.newinstance(wkCurrMonthFirstDay.year(), wkCurrMonthFirstDay.month(),wkStartDay);
			if(wkLastDay == 0){
				wkConEndDate = Date.newinstance(wkCurrMonthFirstDay.year(),wkCurrMonthFirstDay.month(),wkPreMonthMaxDays);
			} else {
				// 例如  Date.newinstance(2016,12 + 1 ,1); ==>> 2017-01-01 00:00:00
				wkConEndDate = Date.newinstance(thisYear,wkCurrMonthFirstDay.month()+1,wkLastDay);
			}
			daysInMonth = startDate.daysBetween(wkConEndDate) + 1;
		}
		xmlSetDay = startDate;
		// 非30日モード
		if ( viewMode != CONST_VIEWMODE_1) {
			startDate = system.today();
		} 
		// 2017/05/26 シフトの開始日は変更できるように改善対応 Wgch END
		if (timeTable == null) {
			timeTable = new BookingTimeTable__c();
			timeTable.Checkinday__c = startDate;
			orgDate = startDate;
		// 2019/02/15 入力指定日チェック追加　by zy BEGIN
		//} else startDate = timeTable.Checkinday__c;
		} else {
			if (timeTable.Checkinday__c == null) timeTable.Checkinday__c = system.today();
			startDate = timeTable.Checkinday__c;
		}
		// 2019/02/15 入力指定日チェック追加　by zy END
		// 重複判別用マップ<部屋タイプID、dispRecord>
		dispRecordMap = new Map<Id, dispRecord>();
		/*
        Set<Id> canEditUserIds = new Set<Id>();
	    Set<Id> roleUserIds = CommRoleUtils.getRoleSubordinateUsers(UserInfo.getUserId());
System.debug(loggingLevel.INFO,'roleUserIds-----------------' +roleUserIds); 
	    canEditUserIds.addAll(roleUserIds);
	    canEditUserIds.add(UserInfo.getUserId());
        }*/
		//===============================================
		refreshViewMode();
		String sortFieldName = System.currentPageReference().getParameters().get('sortFieldName');
		if (!CommUtils.isBlank(sortFieldName)) {
			if (currSortField != sortFieldName) {
				currSortField = sortFieldName;
				currSortStatus = 'asc';
			} else {
				currSortStatus = (currSortStatus == 'asc' ? 'desc' : 'asc');
			}
		}
		// 指定API名により、関連の予約情報を取得する
		// 2015/10/01 EDIT BEGIN
		//String userQuery = ' select Id,Name,RestTimeUnit__c,RestCalMethodType__c,EmploymentStatus__c,OutRestTimeUnit__c,OutRestCalMethodType__c,TimeUnit__c,CalMethodType__c,BeginTimeUnit__c,BeginTimeCalMethodType__c ,EmployeeCode__c,Department from User where StaffScheduleNoshow__c != true And IsActive = true '; //Order by Seq__c  limit 200';
		
		String userQuery = 'select ' + appConfig.queryQueryUserField() + ' from User where StaffScheduleNoshow__c != true And IsActive = true ';
        // 2015/10/01 EDIT END
        if (!CommUtils.isBlank(branchShopNm)) {
            userQuery += 'and ( DefaultShopCode__c = :branchShopNm or ShopCode__c = :branchShopNm ) ';
        }else if (userInf.isShopCodePlex) {
            Set<String> shopSt = userInf.shopSt;
            userQuery += 'and ( DefaultShopCode__c = :shopSt or ShopCode__c = :shopSt ) ';
        }
        // 2018/03/23 部署は複数選択できる機能対応 BY WGCH BEGIN
        // if (!CommUtils.isBlank(departCd)) userQuery += 'and Department = :departCd ';
        if (!CommUtils.isBlank(multiDepartCds)) {
        	list<string> locDepartCds = new List<String>();
        	for (String typeCd : CommUtils.nullToBlank(multiDepartCds).split(',')) {
        		if (!CommUtils.isBlank(typeCd)) locDepartCds.add(typeCd);
        	}
        	if (!locDepartCds.isEmpty())  userQuery+= ' And Department in: locDepartCds ';
        } else if (!CommUtils.isBlank(departCd)) {
        	userQuery += ' And Department =: departCd ';
        }
        // 2018/07/13 プロジェックト機能追加 by zy BEGIN
        if (userSet != null && !userSet.isEmpty()) {
        	userQuery += ' And id =: userSet ';
        }
        // 2018/07/13 プロジェックト機能追加 by zy END
		
        // 2018/03/23 部署は複数選択できる機能対応 BY WGCH END
        // 編集権限のみのユーザ情報を参照できる
		// 並び順[社員コード・氏名]
		if (currSortField == getSortFieldForUser()) {
	        userQuery += 'order by EmployeeCode__c '+String.escapeSingleQuotes(currSortStatus)+' Nulls Last , Name '+String.escapeSingleQuotes(currSortStatus)+' Nulls Last ';
		} else {
			userQuery += 'order by Department '+String.escapeSingleQuotes(currSortStatus) + ' Nulls Last , EmployeeCode__c asc Nulls Last , Name asc Nulls Last ';
		}
		// 関連ユーザー一覧情報を取得する
        // 2018/03/07 Security Check BEGIN
        //userLst = DataBase.query(userQuery);
		userLst = DataBase.query(String.escapeSingleQuotes(userQuery));
		// 2019/09/15 マルチタスクで自分専用のグループを作れるようにする(高) by zy BEGIN
		// ユーザーグループ取得
		userTasks = getUserConfig(userInf.u.id,null,branchShopNm);
		Set<String> userGroupSet = new Set<String>();
		Map<String,String> userMap = new Map<String,String>();
		if (!CommUtils.isBlank(userGroupId)) {
			// 2019/12/30 5310 bug fixed by zy BEGIN
			List<Task> tasks = getUserConfig(null,userGroupId,branchShopNm);
			// 2019/12/30 5310 bug fixed by zy END
			if (!tasks.isEmpty()) {
				String userLstStr = CommUtils.nullTOBlank(tasks[0].groupName);
				userGroupSet = new Set<String>(userLstStr.split(','));
			} else userGroupId = '';
		}
		if (pUserGroupId != userGroupId) saveSettingCookie();
		// 2019/09/15 マルチタスクで自分専用のグループを作れるようにする(高) by zy END
		if (!userTasks.isEmpty()) {
			List<User> us = new List<User>();
			for (User s : userLst) {
				userMap.put(s.id,s.name);
				if (!userGroupSet.isEmpty() && !userGroupSet.contains(s.id)) continue;
				us.add(s);
			}
			userLst = us;
		}
        // 2018/03/07 Security Check END
		// 2019/09/22 不具合改修：マルチタスク機能、エラー『コレクションサイズ1,013が1,000の最大サイズを超えています。』の不具合改修 by zy BEGIN
		userInfos = new List<UserSection>{new UserSection()};
		// 2019/09/22 不具合改修：マルチタスク機能、エラー『コレクションサイズ1,013が1,000の最大サイズを超えています。』の不具合改修 by zy END
        //staffJson = '';
        String curUsrRoleNm = CommUtils.nullToBlank(userInf.u.UserRole.name);
        List<Id> userIds = new List<Id>();
        for(User s: userLst) {
        	dispRecord nwRec = new dispRecord();
        	nwRec.userId = s.Id;
			// 2017/03/07 シフト->新規行動機能対応 BEGIN zyz
			nwRec.eventNm = s.Name;
			// 2017/03/07 シフト->新規行動機能対応 END zyz
			userIds.add(s.Id);
			if(!CommUtils.isBlank(s.EmployeeCode__c))
				nwRec.userNm = s.EmployeeCode__c + '_' + s.Name;
			else
				nwRec.userNm = s.Name;
			nwRec.name = s.Name;
			// 2015/10/01 EDIT BEGIN
			// 氏名列に補足表示情報が設定する
			nwRec.userPlusInf = appConfig.getPlusInfFromUser(s);
			// 2015/10/01 EDIT END
			// 2017/09/05 権限チェック追加対応　BEGIN
			String usrName = CommUtils.nullToBlank(s.Username);
			String usrRoleNm = CommUtils.nullToBlank(s.UserRole.name);
			if (s.Id != UserInfo.getUserId()) {
				Set<String> managerSet = roleConfig.getUserViewDefSet(usrName);
				if (managerSet != null && !managerSet.contains(curUsrRoleNm)) nwRec.isViewFlg = '1';
			}
			// 2017/09/05 権限チェック追加対応　END
			userCodeLst.add(new SelectOption(nwRec.userId, nwRec.userNm));
			// 部下のタスク　または　同じロールかつ該当ロールは同士間に編集可能定義されている場合、タスク登録可能
			if(canEditRoleUserIds.isEmpty() || canEditRoleUserIds.contains(s.Id) || (usrRoleNm == curUsrRoleNm && roleConfig.isEditForSameRole(usrRoleNm))){
			// 2017/09/05 指定権限制限機能追加 END
				nwRec.roleClass = '';
			}else{
				nwRec.roleClass = 'notRoleCol';
			}	
        	dispRecordMap.put(s.Id, nwRec);
			// 2019/09/22 不具合改修：マルチタスク機能、エラー『コレクションサイズ1,013が1,000の最大サイズを超えています。』の不具合改修 by zy BEGIN
			UserSection usc = userInfos[userInfos.size() - 1];		
			if (usc.isFull()) {
				userInfos.add(new UserSection());
			}
			usc.add(s);
			// 2019/09/22 不具合改修：マルチタスク機能、エラー『コレクションサイズ1,013が1,000の最大サイズを超えています。』の不具合改修 by zy END
        }
		// 2019/09/22 不具合改修：マルチタスク機能、エラー『コレクションサイズ1,013が1,000の最大サイズを超えています。』の不具合改修 by zy BEGIN
		userLst = null;
		// 2019/09/22 不具合改修：マルチタスク機能、エラー『コレクションサイズ1,013が1,000の最大サイズを超えています。』の不具合改修 by zy END
        // 予約関連の集計情報の初期化
	   	initXmlSummaryInfo(branchShopNm);
	   	// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける） by cxw BEGIN
	   	initProjectOpts(userIds,branchShopNm);
	   	// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける） by cxw END
		// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy BEGIN
		if (isUserTaskFlag) queryTaskLst(taskconfig.taskOpts,userIds);
		// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy END
	}
	// 画面制御モード変数
	public String viewMode	{get;set;}	// 画面制御モード:31日間、90日間、一週間、１日間
	public String viewWidth {get;set;}
	// 画面表示モード設定
    private static final String CONST_VIEWMODE_1 = '31DAYS';
    private static final String CONST_VIEWMODE_2 = 'ONEWEEK';
    private static final String CONST_VIEWMODE_3 = '90DAYS';
    private static final String CONST_VIEWMODE_4 = 'ONEDAY-30';
    private static final String CONST_VIEWMODE_5 = 'ONEDAY-10';
    private static final String CONST_VIEWMODE_6 = 'ONEDAY-05';
	// ページモードリスト
    public List<SelectOption> getViewModeList() {
        List<SelectOption> options = new List<SelectOption>();
        //90日
        //options.add(new SelectOption (CONST_VIEWMODE_3,Label.CONST_005_0080+'　'));
        //31日
        options.add(new SelectOption (CONST_VIEWMODE_1,Label.CONST_005_0081+'　'));
        //07日
        options.add(new SelectOption (CONST_VIEWMODE_2,Label.CONST_005_0082+'　'));
        //30分
        options.add(new SelectOption (CONST_VIEWMODE_4,Label.CONST_005_0083+'　'));
        //10分
        options.add(new SelectOption (CONST_VIEWMODE_5,Label.CONST_005_0084+'　'));
        //05分
        //options.add(new SelectOption (CONST_VIEWMODE_6,Label.CONST_005_0085+'　')); 
        return options;
    }
	// 集計情報JSON定義
	public String getJsonSummaryInfo() {
		return JSON.serialize(summaryInfo);
	}
	public static Map<String,String> initXmlSummaryInfo(String branchShopNm){
		// XML読み込み
		Dom.XmlNode targetNode = CommXmlUtils.encodeParseXmlDoc('StaffScheduleConfigXml',branchShopNm,new String[]{'<COONDITION>','</COONDITION>'});
		Map<String,String> sqlWhereMap = new Map<String,String>();
		summaryInfo = new LeadSummaryInfo();
		// 勤怠ボタンの背景と文字の色
		workTimeBtnInfo = new WorkTimeButtonInfo();
		String TITLETAG = 'TITLE';
		Dom.XmlNode summaryNode;
		for(Dom.XMLNode xmlNode : targetNode.getChildElements()){
			// タグ名
			String attributeName = xmlNode.getName();
			String summaryName = '';
			if(attributeName.equalsIgnoreCase('SHOPCODE'))continue;
			if(attributeName.equalsIgnoreCase('SUMMARY')){
				summaryNode = xmlNode;
				String title = summaryNode.getAttribute(TITLETAG, null);
				String field = summaryNode.getAttribute('FIELD', null);
				if (title == null) continue;
				summaryInfo.addXmlNodeInfo(CommUtils.nullToBlank(field), title);
				String sqlWhere = '';
				integer index = 0;
				List<string> changeWhereLst = new List<string>();
				for(Dom.XMLNode childNode : summaryNode.getChildElements()){
					// タグ名
					String childAttributeName = childNode.getName();
					if(childAttributeName.equalsIgnoreCase('LOGIC')){
						sqlWhere = childNode.getText();
					}
					if(childAttributeName.equalsIgnoreCase('COONDITION')){
						//Dom.XMLNode fieldNode = childNode.getChildElement('FIELD', null);
						if(childNode.getText() != null){
							changeWhereLst.add(childNode.getText());
							index++;
						}
					}
				}
				for(integer i = 0 ; i < changeWhereLst.size(); i++){
					//System.debug(loggingLevel.INFO, 'sqlWhere1:::' + sqlWhere);
					sqlWhere = sqlWhere.replace('{' + i + '}',changeWhereLst[i]); 
					//System.debug(loggingLevel.INFO, 'sqlWhere2:::' + sqlWhere);
					
				}
				sqlWhereMap.put(summaryNode.getAttribute(TITLETAG, null),sqlWhere);
			}else if (attributeName.equalsIgnoreCase('WORKTIME')) {
				workTimeBtnInfo = getWorkTimeButtonInfo(branchShopNm, xmlNode);
			}
		}
		return sqlWhereMap;
		
	}
	// 指定の店舗コードにより、XMLに定義の
	public static WorkTimeButtonInfo getWorkTimeButtonInfo(String branchShopCode, Dom.XMLNode workBtnNode) { 
		// 定義情報をXMLから取得、設定を行う
		WorkTimeButtonInfo wkInfo = new WorkTimeButtonInfo();
		if (workBtnNode == null) {
			workBtnNode = getNodeByNodeName('WORKTIME',branchShopCode);
		}
		if (workBtnNode == null) return wkInfo;
		Dom.XMLNode STARTBTN = workBtnNode.getChildElement('WORK_START', null);
		Dom.XMLNode OUTBTN = workBtnNode.getChildElement('WORK_REST_START', null);
		Dom.XMLNode BACKBTN = workBtnNode.getChildElement('WORK_REST_END', null);
		Dom.XMLNode ENDBTN = workBtnNode.getChildElement('WORK_END', null);
		Dom.XMLNode COMMENTBTN = workBtnNode.getChildElement('WORK_COMMENT', null);
		Dom.XMLNode WKEDITBTN = workBtnNode.getChildElement('WORK_TIME_EDIT', null);
		if (STARTBTN != null) {
			// 出勤ボタン
			Dom.XMLNode backColorNode = STARTBTN.getChildElement('BACKCOLOR', null);
			Dom.XMLNode fontColoeNode = STARTBTN.getChildElement('FONTCOLOR', null);
			if (backColorNode != null) {
				String backColorVal = CommUtils.nullToBlank(backColorNode.getText()).trim();
				if (!CommUtils.isBlank(backColorVal)) wkInfo.Start_BackColor = backColorVal;

			}
			if (fontColoeNode != null) {
				String fontColoeVal = CommUtils.nullToBlank(fontColoeNode.getText()).trim();
				if (!CommUtils.isBlank(fontColoeVal)) wkInfo.Start_FontColor = fontColoeVal;
			}
		}
		if (OUTBTN != null) {
			// 出勤ボタン
			Dom.XMLNode backColorNode = OUTBTN.getChildElement('BACKCOLOR', null);
			Dom.XMLNode fontColoeNode = OUTBTN.getChildElement('FONTCOLOR', null);
			if (backColorNode != null) {
				String backColorVal = CommUtils.nullToBlank(backColorNode.getText()).trim();
				if (!CommUtils.isBlank(backColorVal)) wkInfo.RestStart_BackColor = backColorVal;

			}
			if (fontColoeNode != null) {
				String fontColoeVal = CommUtils.nullToBlank(fontColoeNode.getText()).trim();
				if (!CommUtils.isBlank(fontColoeVal)) wkInfo.RestStart_FontColor = fontColoeVal;
			}
		}
		if (BACKBTN != null) {
			// 出勤ボタン
			Dom.XMLNode backColorNode = BACKBTN.getChildElement('BACKCOLOR', null);
			Dom.XMLNode fontColoeNode = BACKBTN.getChildElement('FONTCOLOR', null);
			if (backColorNode != null) {
				String backColorVal = CommUtils.nullToBlank(backColorNode.getText()).trim();
				if (!CommUtils.isBlank(backColorVal)) wkInfo.RestEnd_BackColor = backColorVal;

			}
			if (fontColoeNode != null) {
				String fontColoeVal = CommUtils.nullToBlank(fontColoeNode.getText()).trim();
				if (!CommUtils.isBlank(fontColoeVal)) wkInfo.RestEnd_FontColor = fontColoeVal;
			}
		}
		if (ENDBTN != null) {
			// 出勤ボタン
			Dom.XMLNode backColorNode = ENDBTN.getChildElement('BACKCOLOR', null);
			Dom.XMLNode fontColoeNode = ENDBTN.getChildElement('FONTCOLOR', null);
			if (backColorNode != null) {
				String backColorVal = CommUtils.nullToBlank(backColorNode.getText()).trim();
				if (!CommUtils.isBlank(backColorVal)) wkInfo.End_BackColor = backColorVal;

			}
			if (fontColoeNode != null) {
				String fontColoeVal = CommUtils.nullToBlank(fontColoeNode.getText()).trim();
				if (!CommUtils.isBlank(fontColoeVal)) wkInfo.End_FontColor = fontColoeVal;
			}
		}
		// 2015/11/16 勤怠修正ボタン色カスタマイズ対応 BEGIN
		if (WKEDITBTN != null) {
			// 出勤ボタン
			Dom.XMLNode backColorNode = WKEDITBTN.getChildElement('BACKCOLOR', null);
			Dom.XMLNode fontColoeNode = WKEDITBTN.getChildElement('FONTCOLOR', null);
			if (backColorNode != null) {
				String backColorVal = CommUtils.nullToBlank(backColorNode.getText()).trim();
				if (!CommUtils.isBlank(backColorVal)) wkInfo.WkTimeEdit_BackColor = backColorVal;

			}
			if (fontColoeNode != null) {
				String fontColoeVal = CommUtils.nullToBlank(fontColoeNode.getText()).trim();
				if (!CommUtils.isBlank(fontColoeVal)) wkInfo.WkTimeEdit_FontColor = fontColoeVal;
			}
		}
		return wkInfo;
	}
	// 曜日の取得処理
  	private String getYobi(Date vdDate){
		return CommUtils.getYobi(vdDate);
	}
	// ************************************************
	// Headerに予約関連集計情報を作成する【END】
	// ************************************************
	private void initEditRoleInfo() {
		canEditRoleUserIds = new Set<Id>();
        if (!CommUtils.isBlank(UserInfo.getUserRoleId())) {
        	try {
		    	Set<Id> roleUserIds = CommRoleUtils.getRoleSubordinateUsers(UserInfo.getUserId());
				// 権限取得する
			    canEditRoleUserIds.addAll(roleUserIds);
			    canEditRoleUserIds.add(UserInfo.getUserId());
        	} catch (CommException e) {
        		// 最大階層表示
        	}
        }
	}
	// ************************
    // 支店選択リスト
    // ************************
	private Map<String,ShopInformation__c> shopInfoMap;
    public List<SelectOption> branchShopLst{get; private set;}
    public List<SelectOption> userCodeLst{get; private set;}
    public List<SelectOption> departCodeLst{get; private set;}
    public String departCd{get;set;}
    public UserUtil.UserShopInfo userInf;
    public String branchShopNm{get; set;}
   	private void setInitBranShopLst() {
    	userInf = UserUtil.CurrentUserInfo;
		// 2019/07/31 20190527.04.タイムテーブル、ルームインジケータ、マルチタスク機能編集モードと読み込み専用モード対応必要 by zy BEGIN
		notReadOnlyFlg = userInf.hadTaskFlg;
		// 2019/07/31 20190527.04.タイムテーブル、ルームインジケータ、マルチタスク機能編集モードと読み込み専用モード対応必要 by zy END
    	branchShopLst = ShopInfoUtil.getBranchShopLst(userInf.shops);
        shopInfoMap   = ShopInfoUtil.getShopInfoMap(userInf.shops);
        if (!branchShopLst.isEmpty()) {
        	// 顧客に設定する支店で初期値に設定する[2013/06/30]
        	String locShopCode = UserUtil.CurrentUser.ShopCode__c;
        	for (SelectOption s : branchShopLst) {
        		if (s.getValue() == locShopCode) branchShopNm = locShopCode;
        	}
        }
    }
    /*
    * 获取全部タスク
    */
    @remoteAction
    public static List<Task> getTasks(String request){
    	AjaxRequest req = (AjaxRequest)JSON.deserializeStrict(request, AjaxRequest.class);
    	List<Task> tasks = new List<Task>();
    	Date begDate = CommUtils.stringtoDate(req.begDate);
    	Date endDate = CommUtils.stringtoDate(req.endDate);
    	// 2018/04/09 ロール設定機能追加　by ZY BEGIN
        //List<Event> etResult = [select id, OwnerId, Owner.name,ActivityDate,Subject,StartDateTime,EndDateTime,CssStyle__c from Event 
		//							    	where OwnerId =:req.userLst and DAY_ONLY(convertTimezone(EndDateTime)) >= :begDate and DAY_ONLY(convertTimezone(StartDateTime)) <= :endDate order by CreatedDate];
		// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける） by cxw BEGIN
		
		TaskConfig taskConfig = new TaskConfig(req.spcd, null,null);
		// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy BEGIN
		Map<Id,user> userMap = new Map<Id,User>();
		Set<String> userGroupSet = new Set<String>();
		if (!CommUtils.isBlank(req.taskid)) {
			// 2019/12/30 5310 bug fixed by zy BEGIN
			List<Task> tasksGroup = getUserConfig(null,req.taskid,req.spcd);
			// 2019/12/30 5310 bug fixed by zy END
			if (!tasksGroup.isEmpty()) {
				String userLstStr = CommUtils.nullTOBlank(tasksGroup[0].groupName);
				userGroupSet = new Set<String>(userLstStr.split(','));
			}
		}
		String userSQL = 'select id,department from user  ';
		String sqlWhere = '';
		String spcd = req.spcd;
		Set<String> departCodes = req.eventIds;
		List<String> querWhereLst = new List<String>();
		// 2020/01/08 指定店铺user不明确 bug fixed by zy BEGIN
		// if (!CommUtils.isBlank(spcd)) querWhereLst.add( 'shopcode__c like \'%' + spcd + '%\'');
		if (!CommUtils.isBlank(spcd)) querWhereLst.add( '( DefaultShopCode__c =  \'' + spcd + '\' or ShopCode__c = \'' + spcd + '\')');
		// 2020/01/08 指定店铺user不明确 bug fixed by zy END
		if (!userGroupSet.isEmpty()) querWhereLst.add( 'id = :userGroupSet');
		if (departCodes != null && !departCodes.isEmpty()) querWhereLst.add( 'department = :departCodes');
		if (!querWhereLst.isEmpty()) userSQL += ' where ' + string.join(querWhereLst,' and ');
		for (user u : database.query(userSQL)){
			userMap.put(u.id,u);
		}
		// List<Event> etResult = StaffTaskHelp.getTasks(req.userLst, begDate, endDate,req.filterTips);
		List<Event> etResult = req.isUserFlg ? StaffTaskHelp.getTasks(new List<Id>(userMap.keySet()), begDate, endDate,req.filterTips,EVENT_ROW_FIELD,req.userLst) : StaffTaskHelp.getTasks(req.userLst, begDate, endDate,req.filterTips);
		// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy END
		Map<String,String> groupNameMap = taskConfig.groupNameMap;
		// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける） by cxw END
		// 2018/04/09 ロール設定機能追加　by ZY END
		for (Event avg : etResult) {
			// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける） by cxw BEGIN
			if (!CommUtils.isBlank(req.filterTips)) {
				// 該当件名グループあり
				if (CommUtils.isBlank(avg.GroupCode__c)) avg.GroupCode__c = CommUtils.nullToBlank(groupNameMap.get(avg.subject));
			}
			// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける） by cxw END
			// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy BEGIN	
			Task t = new Task(avg);
			if (req.isUserFlg) {
				t.rowId = CommUtils.nullToBlank(avg.get(EVENT_ROW_FIELD));
				// プロジェクタ明細担当者設定
				if (!CommUtils.isBlank(avg.Location)) t.lockname = avg.Location;
				else t.lockname = avg.owner.name;
				// 部署名設定
				if (userMap.containsKey(avg.ownerId)) t.departname = userMap.get(avg.ownerId).department;
				t.userId = avg.ownerId;
			}
			tasks.add(t);
			// tasks.add(new Task(avg));
			// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy END
		}
		// 2019/08/31 マルチタスクについて、今「その他」で絞りをかけた後画面更新（Command+R）をするとプロジェクト管理が消えました。絞り込みの保持 by zy BEGIN
		UserConfigCompCtrl.saveCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.TASK,
				UserConfigCompCtrl.KREP_SUBTYPE.SETINFO.name(),CommUtils.nullToBlank(req.filterTips),UserUtil.CurrentUser.id,'');
		// 2019/08/31 マルチタスクについて、今「その他」で絞りをかけた後画面更新（Command+R）をするとプロジェクト管理が消えました。絞り込みの保持 by zy END
		return tasks;
    }
    /*
    * 指定タスク削除する
    */
    @remoteAction
    public static List<Task> removeTasks(String request){
    	AjaxRequest req = (AjaxRequest)JSON.deserializeStrict(request, AjaxRequest.class);
    	Savepoint sp = Database.setSavepoint();
    	try{
    		// 2018/04/16 ロール対応　by　zy　BEGIN
    		//List<Event> taskLst = [select id from Event  where id = :req.taskid for update] ;
    		//if (!taskLst.isEmpty()) delete taskLst;
    		// 2018/06/25 マルチタスクのタスク登録機能改善繰り返し期間追加 by BEGIN
    		StaffTaskHelp.deleteTaskByIdForUpdate(req.taskid,req.delSameFlag);
    		// 2018/06/25 マルチタスクのタスク登録機能改善繰り返し期間追加 by END
    		// 2018/04/16 ロール対応　by　zy　END
        	//delete [select id from Event where id = :req.taskid];
    	} catch (Exception e) {
    		DataBase.rollback(sp);
    	}
		List<Task> tasks = new List<Task>();
		return tasks;
    }
    @remoteAction
    public static List<Task> updateEvent(String taskJson){
    	Savepoint sp = Database.setSavepoint();
    	//List<String> ownLst = new List<String>();
    	// 2018/03/07 Security Check BEGIN
    	List<Task> res = new List<Task>();
		// 2018/07/23 タスク終了日時字段変更　by zy BEGIN
    	Integer maxMiuteLen = 14 * 24 * 60;
		// 2018/07/23 タスク終了日時字段変更　by zy END
		try{
			// 2018/07/15 タスク終了日時字段変更　by zy BEGIN
	    	List<String> chkFieldsLst = new List<String>{'enddatetime','enddatetime__c','startdatetime','subject','ownerid','cssstyle__c'};//'id'
	    	// 2018/07/15 タスク終了日時字段変更　by zy END
	    	Map<String,Schema.SObjectField> mm = Schema.SObjectType.Event.fields.getMap();
	    	if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
	    		return res;
	    	}
	    	// 2018/03/07 Security Check END
	    	Task taskReq = (Task)JSON.deserialize(taskJson,Task.class);
	    	Event event = new Event();
			// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
			boolean projectDetailFlg = CommUtils.nullToBlank(taskReq.id).startsWith(projectPrefix);
			if (projectDetailFlg) event.Description = taskReq.id;
			else 
			// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
	    	event.id = taskReq.id;
	    	Event updEvent = null;
	    	// 更新の場合
	    	if (event.id != null) {
	    		// 先进行查询修改的task已经被删掉则不能实行
	    		// 进行同步锁
	    		// 2018/04/16 ロール対応　by　zy　BEGIN
		    	List<Event> taskLst = StaffTaskHelp.getTaskByIdForUpdate(event.id);
		    	// 2018/04/16 ロール対応　by　zy　END
		    	// 存在情况下进行修改
		    	if (taskLst.isEmpty()) throw New CommException(Label.MSG_035_0136);
		    	else updEvent = taskLst[0];
		    		
	    	}
	    	if (!CommUtils.isBlank(taskReq.style)) {
	    		event.CssStyle__c = taskReq.style;
	    	}
	    	// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける） by cxw BEGIN
	    	// 2019/04/15 JINYABUG-1589 bug fix by zy BEGIN
	    	if(!CommUtils.isBlank(taskReq.groupName))event.GroupCode__c = taskReq.groupName;
	    	// 2019/04/15 JINYABUG-1589 bug fix by zy END
	    	// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける） by cxw END
	    	/*
	    	// 变更
	    	if (!CommUtils.isBlank(taskReq.orgId)) {
	    		ownLst.add(taskReq.orgId);
	    	}*/
			// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy BEGIN	
			if (!Commutils.isBlank(taskReq.rowId) && !taskReq.isUserFlg) event.OwnerId = taskReq.rowId;
			// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy END	
	    	// 未变更数据不进行修改
	    	if (!CommUtils.isBlank(taskReq.name)) event.Subject = taskReq.name;
			// 2019/10/15 マスタタスク、タスクテンプレートの文言を行動の任意の項目に自動で記入できるように改善対応 by zy BEGIN
			if (!CommUtils.isBlank(taskReq.nameField)) event.put(taskReq.nameField,taskReq.name);
			// 2019/10/15 マスタタスク、タスクテンプレートの文言を行動の任意の項目に自動で記入できるように改善対応 by zy END
	    	// 2018/06/25 マルチタスクのタスク登録機能改善繰り返し期間追加 by BEGIN
	    	if (!CommUtils.isBlank(taskReq.groupBeginLabel)) {
	    		event.StartDateTime = CommUtils.convertDatetime(CommUtils.stringtodate(taskReq.groupBeginLabel),taskReq.beginLabel);
	    		// 2018/07/15 タスク終了日時字段変更　by zy BEGIN
	    		// 2018/07/23 タスク終了日時字段変更　by zy BEGIN
				/*
	    		event.EndDateTime = event.StartDateTime.addDays(1);
	    		// 開始時刻変更の場合、終了日時自動変更
	    		if (updEvent != null) {
	    			long difTimelong = null;
	    			if (updEvent.EndDateTime__c != null) difTimelong = updEvent.EndDateTime__c.getTime() - updEvent.StartDateTime.getTime();
	    			else difTimelong = updEvent.EndDateTime.getTime() - updEvent.StartDateTime.getTime();
	    			if (difTimelong != null) {
	    				long lastTimeLong = event.StartDateTime.getTime() + difTimelong;
	    				event.EndDateTime__c = Datetime.newInstance(lastTimeLong);
	    			}
	    		}*/
			// 2018/07/23 タスク終了日時字段変更　by zy END
		    	// 2018/07/15 タスク終了日時字段変更　by zy END
	    	}
	    	// 只更改开始日期时间的case
		    // 2018/07/15 タスク終了日時字段変更　by zy BEGIN
		    //if (!CommUtils.isBlank(taskReq.groupEndLabel)) event.EndDateTime = CommUtils.convertDatetime(CommUtils.stringtodate(taskReq.groupEndLabel),taskReq.endLabel);
		    if (!CommUtils.isBlank(taskReq.groupEndLabel)) event.EndDateTime__c = CommUtils.convertDatetime(CommUtils.stringtodate(taskReq.groupEndLabel),taskReq.endLabel);
	    	else event.EndDateTime__c = null;
	    	// 新規の場合
	    	if (event.id == null) {
				// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
				if (event.EndDateTime__c != null) {
				// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
	    		Integer durMinutes = CommUtils.nullToIntZero((event.EndDateTime__c.getTime() - event.StartDateTime.getTime())/ (60 *1000));
	    		if (durMinutes > maxMiuteLen) event.EndDateTime = event.StartDateTime.addMinutes(maxMiuteLen);
	    		else event.EndDateTime = event.StartDateTime.addMinutes(durMinutes);
				// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
				}
				// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
				// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy BEGIN
				if (taskReq.temp != null) {
					TempInfo info = getTempNode(taskReq.temp,taskReq.spcd);
					if (info != null && info.fieldMap != null) {
						for (String fieldName : info.fieldMap.keySet()) {
							event.put(fieldName,CommUtils.nullToBlank(info.fieldMap.get(fieldName)));
						}
					}
				}
				// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy END
				// 2019/10/30 タスク（作業）を縦軸に置き、そこにアカウントを配置するような形式への切り替えをボタン一つで出来るようにすればより使い勝手がよくなるかと思いますので、是非ご検討いただきたいです by zy BEGIN
				// 2020/01/08 bug 5380 fixed by zy BEGIN
				if (!projectDetailFlg) //排除projectdetail非新规的场合
				event.CreateType__c = taskReq.name == OTHER_TASK_GROUP ? '' : taskReq.name;
				// 2020/01/08 bug 5380 fixed by zy END
				// 2019/10/30 タスク（作業）を縦軸に置き、そこにアカウントを配置するような形式への切り替えをボタン一つで出来るようにすればより使い勝手がよくなるかと思いますので、是非ご検討いただきたいです by zy END
	    	}
	    	// 2018/07/15 タスク終了日時字段変更　by zy END
	    	// 2018/06/25 マルチタスクのタスク登録機能改善繰り返し期間追加 by END
	    	//ownLst.add(taskReq.rowId);
	    	// 2018/06/25 マルチタスクのタスク登録機能改善繰り返し期間追加 by BEGIN
	    	// 繰り返し場合
	    	if (!CommUtils.isBlank(taskReq.weekOpts)) {
	    		// 処理期間
				Date endDt = Date.Parse(taskReq.repeatDateEnd);
		    	// 毎週
	    		// 曜日により、設定用日付を取得する
	    		// 開始日から、一週間の曜日日付を取得する
	    		List<String> weekOpts = taskReq.weekOpts.split(',');
	    		Set<String> weekOptsSet = new Set<String>(weekOpts);
	    		// 2018/06/27 表示時間段更新　JINYABUG-657　by　zy BEGIN
	    		DateTime startDTime = CommUtils.convertDatetime(CommUtils.stringtodate(taskReq.repeatDateBeg),taskReq.beginLabel);
	    		// 2018/06/27 表示時間段更新　JINYABUG-657　by　zy END
	    		// レピター設定
	    		// 繰り返しの開始日
	    		event.RecurrenceStartDateTime = startDTime;
	    		// 繰り返しの
	    		event.RecurrenceEndDateOnly = endDt;
	    		// 繰り返し種別「毎週」
	    		event.RecurrenceType = 'RecursWeekly';
	    		// 定期的な行動を作成
	    		event.IsRecurrence = true;
	    		event.RecurrenceDayOfWeekMask = taskReq.weekTotal;
	    		event.RecurrenceInterval = 1;
	    		//event.ActivityDate = startDTime.date();
	    		// 2018/07/15 タスク終了日時字段変更　by zy BEGIN
	    		Integer durMinutes = CommUtils.nullToIntZero((event.EndDateTime__c.getTime() - event.StartDateTime.getTime())/ (60 *1000));
	    		// 2018/07/23 タスク終了日時字段変更　by zy BEGIN
	    		if (durMinutes > maxMiuteLen) durMinutes = maxMiuteLen;
	    		// 2018/07/23 タスク終了日時字段変更　by zy END
	    		//event.DurationInMinutes = CommUtils.nullToIntZero((event.EndDateTime.getTime() - event.StartDateTime.getTime())/ (60 *1000));
	    		event.DurationInMinutes = durMinutes;
	    		// 2018/07/15 タスク終了日時字段変更　by zy END

	    		event.StartDateTime = null;
	    		event.EndDateTime = null;
	    		event.EndDateTime__c = null;
	    	}
	    	// 2018/06/25 マルチタスクのタスク登録機能改善繰り返し期間追加 by END
			// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy BEGIN	
			if (taskReq.isUserFlg){
				// 2020/01/08 その他改件名出错bug fix by zy BEGIN
				if(!CommUtils.isBlank(taskReq.userId)) event.OwnerId = taskReq.userId;
				// 2020/01/08 その他改件名出错bug fix by zy END
				event.put(EVENT_ROW_FIELD,taskReq.rowId);
			}
			// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy END
			// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
			if (taskReq.calFlg == false || projectDetailFlg) chgTaskUpdate(event,taskReq.weekOpts);
			else 
			// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
	    	// 2018/04/16 ロール対応　by　zy　BEGIN
	    	StaffTaskHelp.updEvent(event);
	    	// 2018/04/16 ロール対応　by　zy　END
    	} catch(Exception e){
			Database.rollBack(sp);
// system.debug(logginglevel.info,e.getStackTraceString());
			throw New CommException(StaffTaskHelp.getFieldValidationMessage(CommUtils.getFieldValidationMessage(e.getmessage())));
		}
		// 2018/03/07 Security Check BEGIN
		//List<Task> res = new List<Task>();
		// 2018/03/07 Security Check END
    	return res;
    }
	@remoteAction
	public static LeadMessageInfo summaryTitleInfoByXml(String shopCode, String pConStartDate, String pConEndDate ,String jsonSummaryInfo) {
		// Query Where Var
		Integer leadCancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
		
		Date conStartDate = CommUtils.stringToDate(pConStartDate);
		Date conEndDate   = CommUtils.stringToDate(pConEndDate);
//System.debug(loggingLevel.INFO, 'conStartDate:::' + conStartDate);
//System.debug(loggingLevel.INFO, 'conEndDate:::' + conEndDate);
		LeadSummaryInfo locSummaryInfo = (LeadSummaryInfo)JSON.deserializeStrict(jsonSummaryInfo, LeadSummaryInfo.class);
//System.debug(loggingLevel.INFO, 'summaryInfo:::' + locSummaryInfo);
		Map<String,String> titleSqlWhereMap = initXmlSummaryInfo(shopCode);
		map<String, String> returnJsonMsgMap = new map<String, String>();
		map<String,String> leadIdsMap = new Map<String,String>();
		for(String title : titleSqlWhereMap.keySet()){
			// XMLに指定の項目により、関連予約情報を集計を行う
			Set<String> preFiedSet = new Set<String>{'id','name','StayPersons__c','EntryTime__c'}; 
			String queryField = getSummaryQueryHeader(preFiedSet, locSummaryInfo);
			String querySelect = 'Select ' + queryField + ' From Lead__c ';
			String queryWhere  = ' Where CancelBool__c != :leadCancelFlg  '+
									' And DAY_ONLY(convertTimezone(EntryTime__c)) >= :conStartDate ' +
							 		' And DAY_ONLY(convertTimezone(EntryTime__c)) <= :conEndDate ';
			if (!CommUtils.isBlank(shopCode)) queryWhere+= ' And refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c = :shopCode ';
			String queryCustomWhere = '';
			if(titleSqlWhereMap.containsKey(title)){
				String titleByWhere = titleSqlWhereMap.get(title);
				if(!CommUtils.isBlank(titleByWhere) ){
					queryCustomWhere = 'And (' + titleSqlWhereMap.get(title) + ') ';
				}
//System.debug(loggingLevel.INFO, 'titleSqlWhereMap.get(title):::' + titleSqlWhereMap.get(title));
			 	
			}
			String queryStr = querySelect + queryWhere + queryCustomWhere + ' Order By EntryTime__c asc ';
//System.debug(loggingLevel.INFO, 'queryStr:::' + queryStr);		
			map<String, Integer> leadSummaryMap = new map<String, Integer>();
			map<String, Integer> peopleSummaryMap = new map<String, Integer>();
			for (Sobject lead : Database.query(queryStr)) {
				// XMLに指定の種別により、別々の集計を行う
				Integer peoples = CommUtils.nullToIntZero(lead.get('StayPersons__c'));
				String key = getSummaryKey('', title, (DateTime)lead.get('EntryTime__c'));
				if (!leadSummaryMap.containsKey(key)){
					 leadSummaryMap.put(key, 1);
					 leadIdsMap.put(key,lead.id);
				}else {
					integer leadNum = leadSummaryMap.get(key);
					leadIdsMap.put(key,lead.id + ',' + leadIdsMap.get(key));
					leadNum++;
					leadSummaryMap.put(key, leadNum);
				}if (!peopleSummaryMap.containsKey(key)) peopleSummaryMap.put(key, peoples);
				else peopleSummaryMap.put(key, peopleSummaryMap.get(key) + peoples);
			}
			for (String key : leadSummaryMap.keySet()) {
				returnJsonMsgMap.put(key, leadSummaryMap.get(key) + '(' + peopleSummaryMap.get(key) + ')');
			}
		}
		
		LeadMessageInfo info = new LeadMessageInfo(returnJsonMsgMap,leadIdsMap);
		return info;
	}
	@remoteAction
	public static RefreshResult refreshTimeMessage(String startDtStr,String endDtStr,String uids) {
		List<StaffSchedule> schedules = new List<StaffSchedule>();
		Map<Id, dispRecord> dispRecordMap = new Map<Id, dispRecord>();
		RefreshResult rr = new RefreshResult();
		if (CommUtils.isBLank(uids)) return rr;
		List<Id> uidLst = uids.split(',');
		Set<Id> userIds = new Set<Id>();
		for(Id userId : uidLst){
			userIds.add(userId);
		}
		Date startDt = CommUtils.stringToDate(startDtStr);
		Date endDt = CommUtils.stringToDate(endDtStr);
		integer daysInMonth = startDt.daysBetween(endDt);
		List<StaffSchedule__c> staffSchedules = [select StatusLst__c,TimeManagementRef__c,WorkDay__c,StaffUserRef__c,StopStatusLst__c,
																CommentLst__c,SearchKey__c,LastModifiedDate 
														 from StaffSchedule__c where (WorkDay__c >= :startDt or WorkDay__c <= :endDt) and StaffUserRef__c = :uidLst];
		Map<String,Decimal> workDayTimeMap = new Map<String,Decimal>();
		Decimal allWorkDaysCount = 0;
		List<AggregateResult> daytimeLst = [select WorkDay__c workDay, sum(WorksT__c) sumWorkTimes
									        		from TimeManagement__c
													where (WorkDay__c != null And WorkDay__c >= :startDt and WorkDay__c <= :endDt ) and WorkerRef__c = :userIds
													group by WorkDay__c];
			
    	for (AggregateResult rs : daytimeLst) {
    		String key = ((Date)rs.get('workDay')).format();
    		workDayTimeMap.put(key,(Decimal)rs.get('sumWorkTimes'));
    		allWorkDaysCount += (Decimal)rs.get('sumWorkTimes');
    	}
    	
    	Map<String,Decimal> workUserTimeMap = new Map<String,Decimal>();
    	
		List<AggregateResult > usertimeLst = [select WorkerRef__c workId,  sum(WorksT__c) sumWorkTimes
									        		from TimeManagement__c
													where (WorkDay__c != null And WorkDay__c >= :startDt and WorkDay__c <= :endDt ) 
															and WorkerRef__c = :userIds
													group by WorkerRef__c];
		for (AggregateResult rs : usertimeLst) {
    		String key = (String)rs.get('workId');
    		workUserTimeMap.put(key,(Decimal)rs.get('sumWorkTimes'));
    	}
    	
		Map<String ,StaffSchedule__c> staffMap = new Map<String ,StaffSchedule__c>();
        Map<String, Integer> utMap = new Map<String, Integer>();

	        
		// 2015/07/30 TODOは表示対象に変更があります BEGIN
		List<AggregateResult> etResult = [	select count(ID) cnt, OwnerId, ActivityDate from Event 
									    	where OwnerId =:userIds and ActivityDate >= :startDt and ActivityDate <= :endDt
									    	group by OwnerId, ActivityDate];
		for (AggregateResult avg : etResult) {
	    		Object activityDate = avg.get('ActivityDate');
	    		String key = (activityDate == null ? '' : ((Date)activityDate).format()) +'_'+ CommUtils.nullToBlank(avg.get('OwnerId'));
	    		utMap.put(key, CommUtils.nullToIntZero(avg.get('cnt')));
		}

        for(StaffSchedule__c staff : staffSchedules){
        	String key = staff.StaffUserRef__c + '_' + staff.WorkDay__c.format() ;
        	staffMap.put(key,staff);
        }
        Map<String,Decimal> dayTimeWroksSumMap = new Map<String,Decimal>();
        
        for (Id uid: uidLst) {
        	dispRecord nwRec = new dispRecord();
        	nwRec.userId = uid;
        	
        	Decimal timeWorkSumByUser = 0;
        	
	        for(Integer day = 0; day <= daysInMonth; day ++){
	        	Date hibiDt = startDt.addDays(day);
	        	String strDate = hibiDt.format();
				String key = uid + '_' + strDate;
				TimeMessage tm = new TimeMessage();
				if(staffMap.containsKey(key)){
					tm.schedule = new StaffSchedule(staffMap.get(key));
				}else{
					tm.schedule = null;
				}
//System.debug(loggingLevel.INFO,'key-----------------' +key);  
//System.debug(loggingLevel.INFO,'staffMap-----------------' +staffMap);  
				tm.searchKey = genSearchKey(CommUtils.nullToBlank(uid) ,hibiDt);
        		tm.taskNum = CommUtils.nullToZero(utMap.get(strDate + '_' + uid)); 
        		tm.taskDt = strDate;
        		nwRec.timeList.add(tm);
        	}
        	nwRec.timeWorkSumByUser = workUserTimeMap.get(uid);
        	dispRecordMap.put(uid, nwRec);
        }
        rr.dispRecordMap = dispRecordMap;
        rr.dayliTimeSumMap = workDayTimeMap;
        rr.allWorkDaysCount = allWorkDaysCount;
		return rr;
	}
	public class RefreshResult{
		public Map<Id, dispRecord> dispRecordMap;
		public Map<String,Decimal> dayliTimeSumMap;
		public Decimal allWorkDaysCount;
	}
	  // Tier Detail Key
	private static String genSearchKey(Id userId, Date configDate) {
    	return (userId + '_' + configDate.format());
    }
	public class TimeMessage{
		public String currentStatusStyleStr{get;set;}
		public String currentNightStatusStyleStr{get;set;}
		public String taskDt{get;set;}
		public Integer taskNum{get;set;}
		public StaffSchedule schedule{get;set;}
		public StaffSchedule__c staff{get;set;}
		public String searchKey{get;set;}
		public String setKey{get;set;}
		public String workDay{get;set;}
		public String staffTimeLong{get;set;}
		public Decimal timeWorkSum{get;set;}
		public Boolean isShowCloneFlag{get;set;}
		public Boolean isShowPreWorkInfo{get{
			return (!CommUtils.isBlank(currentNightStatusStyleStr));
		}}
		TimeMessage(){
			timeWorkSum = 0;
		}
	}
	public class StaffSchedule{
		public StaffSchedule__c staff{get;set;}
		public String errorMsg{get;set;}
		public String timeStmp{get;set;}
		public StaffSchedule(StaffSchedule__c schedule){
			staff = schedule;
			if( schedule != null && schedule.LastModifiedDate != null)
				timeStmp = String.valueOf(schedule.LastModifiedDate.getTime());
		}
	}
	// 比較用キーを取得する
	private static String getSummaryKey(String fieldApi, String fieldVal, DateTime dateTm) {
		//return fieldApi + '_' + fieldVal + '_' + dateTm.format('yyyy/MM/dd');
		//return fieldVal + '_' + dateTm.format('yyyy/MM/dd');
		return fieldVal + '_' + dateTm.date().format();
	}
    // 集計用SQLの検索キーを定義する
	private static String getSummaryQueryHeader(Set<String> pFilterKeySet, LeadSummaryInfo pSummaryInfo) {
			String queryFieldStr = '';
			for (String fieldStr : pFilterKeySet) {
				queryFieldStr += fieldStr +',';
			}
			for (String fieldStr : pSummaryInfo.conditionKey) {
				if (!pFilterKeySet.contains(fieldStr)) {
					queryFieldStr += fieldStr +',';
					pFilterKeySet.add(fieldStr);
				}
			}
			if (queryFieldStr.length() > 0) queryFieldStr = queryFieldStr.removeEnd(',');
			return queryFieldStr;
	}
	private Set<String> roomTSSSet ;
    private List<String> roomStatusList{get; private set;}		// 部屋ステータス切り替え情報格納
    // 2015/12/18 FIX BEGIN
    private Map<String, String> statusColorMap{get; private set;}
    // 2015/12/18 FIX END
    private void initRoomStatusList() {
    	roomStatusList = new List<String>();
    	// 2015/12/18 FIX BEGIN
    	statusColorMap = new Map<String, String>();
		// 2015/12/18 FIX END
        String roomTSS = CommConst.APPOTION_DEF_ROOMTYPE_SALESTATUS();
        roomTSSSet = new Set<String>();
        if (!String.isEmpty(roomTSS)) {
        	String[] roomLst = roomTSS.split(',');
        	for (String key : roomLst) {
        		String[] subKey = key.split(':');
        		if (subKey.size() > 1) CONST_NORMAL_HOTEL = subKey[0];
				else roomTSSSet.add(subKey[0].split(';')[0]);
        		       		
				String[] colorKey = key.split(';');
				if (colorKey.size() > 1) {
					statusColorMap.put(subKey[0].split(';')[0], colorKey[1]);
				}
    			roomStatusList.add(subKey[0].split(';')[0]);
        	}
        }
        // デフォルト営業スタータスの色の設定
       	if (!statusColorMap.containsKey(CONST_NORMAL_HOTEL)) statusColorMap.put(CONST_NORMAL_HOTEL, CONST_NORMAL_COLOR);
    }
	// 2015/12/18 FIX BEGIN
    public transient Map<Integer,String> colorInfoMap{get; private set;}
    // 部屋状態検索機能
    private void queryRestHotelInfo (Date stDate, Date edDat) {
    	//hotelInf = new HotelStatusInfo(getNoramlStatus());
    	// 支店は未指定 && 支店リストはが存在する場合
    	if (!isShowBussinisHeader) return;
    	// 画面期間範囲の 休館/全館貸切 情報を取得する
		List<RoomsStatus__c> roomsStatus = [select id, Status__c, StatusBeginDate__c, StatusEndDate__c from RoomsStatus__c 
											// where (Status__c = :CONST_REST_HOTEL OR Status__c = :CONST_FULL_HOTEL)
												where (Status__c in : roomTSSSet)
												And StatusBeginDate__c <= :edDat And StatusEndDate__c >= :stDate
												And (
												   RoomRef__r.ShopInfoRef__r.ShopCode__c = :branchShopNm
												OR RoomRef__r.TypeRoomRef__r.ShopInfoRef__r.ShopCode__c = :branchShopNm
												)];
   		// 休館情報を設定する
   		Date firstDay = startDate;//Date.newInstance(thisYear, thisMonth, 1);
   		Date endDay = firstDay.addDays(daysInMonth);//Date.newInstance(thisYear, thisMonth, daysInMonth);
		//restInfoMap = new Map<Integer, Boolean>();
		restInfoMap = new Map<Integer, String>();
		colorInfoMap = new Map<Integer, String>();
		for(Integer day = 1; day <= daysInMonth; day ++){
			//restInfoMap.put(day, false);
			restInfoMap.put(day, getNoramlStatus());
			colorInfoMap.put(day, statusColorMap.get(CONST_NORMAL_HOTEL));
		}
		for (RoomsStatus__c status : roomsStatus) {
			Date loopStart = status.StatusBeginDate__c;
			Date loopEnd   = status.StatusEndDate__c;
			while (loopStart <= loopEnd) {
				Integer index = firstDay.daysBetween(loopStart)+1;
				//restInfoMap.put(index, true);
				restInfoMap.put(index, status.Status__c);
				if (statusColorMap.containsKey(status.Status__c)) colorInfoMap.put(index, statusColorMap.get(status.Status__c));
				else if(status.Status__c != CONST_NORMAL_HOTEL) {
					colorInfoMap.put(index, CONST_NORMAL_OTCOLOR);
				}
				loopStart = loopStart.adddays(1);
				if (loopStart > endDay) break;
			}
		}
    }
    // 2015/12/18 FIX END
/***************************  INNER CLASS  ***************************/   
	public class colStatus {
    	public colStatus() {
    		bkColor = '';
    		disable = false;
    	}
    	public colStatus(String color) {
    		bkColor = color;
    		disable = false;
    	}
    	// 背景色
    	public String bkColor{get; set;}
    	// クリック不能制御
    	public Boolean disable{get; set;}
    }
    // 2019/09/15 マルチタスクで自分専用のグループを作れるようにする(高) by zy BEGIN
    public class Task{
    // 2019/09/15 マルチタスクで自分専用のグループを作れるようにする(高) by zy END
    	String beginLabel;
    	String endLabel;
    	String groupBeginLabel;
    	String groupEndLabel;
    	String rowId;
		// 2019/09/15 マルチタスクで自分専用のグループを作れるようにする(高) by zy BEGIN
    	public String name{get;set;}
    	public String id{get;set;}
		// 2019/09/15 マルチタスクで自分専用のグループを作れるようにする(高) by zy END
    	String orgId;
    	String style;
    	// 2018/06/25 マルチタスクのタスク登録機能改善繰り返し期間追加 by BEGIN
    	String weekVal;
    	String weekOpts;
    	Integer weekTotal;
    	String repeatDateBeg;
    	String repeatDateEnd;
    	String searchKey;
    	// 2018/06/25 マルチタスクのタスク登録機能改善繰り返し期間追加 by END
    	// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける）by cxw BEGIN
    	// 2019/09/15 マルチタスクで自分専用のグループを作れるようにする(高) by zy BEGIN
		public String groupName{get;set;}
		// 2019/09/15 マルチタスクで自分専用のグループを作れるようにする(高) by zy END
    	// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける）by cxw END
    	// 2019/07/15 マルチタスク、一度決めたシフトを個人ごとにロックするボタンなどは設置可能 by zy BEGIN
		boolean isLockFlg; //
		// 2019/07/15 マルチタスク、一度決めたシフトを個人ごとにロックするボタンなどは設置可能 by zy END
		// 2019/09/15 マルチタスクで自分専用のグループを作れるようにする by zy BEGIN
		public boolean checkedFlg{get;set;}
		// 2019/09/15 マルチタスクで自分専用のグループを作れるようにする by zy END
		// 2019/10/15 マスタタスク、タスクテンプレートの文言を行動の任意の項目に自動で記入できるように改善対応 by zy BEGIN
		String nameField;
		// 2019/10/15 マスタタスク、タスクテンプレートの文言を行動の任意の項目に自動で記入できるように改善対応 by zy END
		// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy BEGIN
		String temp;
		String spcd;
		String userId;
		String lockname;
		String departname;
		boolean isUserFlg;
		// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy END
		// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
		boolean calFlg;
		// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
		// 2020/10/31 担当者を複数設定できるように by zy BEGIN
		String userids;
		boolean cantupd;// 変更不可のフラグ
		// 2020/10/31 担当者を複数設定できるように by zy END
    	/* テストクラス　無効ソース対応　by　zy　
    	public Task(Lead__c lead){
    		name = lead.name;
    		rowId = lead.Relcontact__c + '_' +  lead.Rroom__c;
    		beginLabel = lead.field4__c;
    		endLabel = lead.field3__c;
    		groupBeginLabel = lead.EntryTime__c.date().format();
    		groupEndLabel = lead.Departure__c.date().format();
    		id = lead.id;
    	}*/
    	public Task(Event event){
    		name = event.Subject;
    		if (CommUtils.isBlank(name)) name = event.Owner.name;
    		rowId = event.OwnerId;
			// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
    		if (event.StartDateTime != null) beginLabel = event.StartDateTime.format('HH:mm');
    		// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
			// 2018/07/15 タスク終了日時字段変更　by zy BEGIN
    		if (event.EndDateTime__c == null) endLabel = event.EndDateTime.format('HH:mm');
    		else endLabel = event.EndDateTime__c.format('HH:mm');
    		// 2018/07/15 タスク終了日時字段変更　by zy END
    		groupBeginLabel = event.StartDateTime.date().format();
    		// 2018/07/15 タスク終了日時字段変更　by zy BEGIN
    		if (event.EndDateTime__c == null) groupEndLabel = event.EndDateTime.date().format();
    		else groupEndLabel = event.EndDateTime__c.date().format();
    		// 2018/07/15 タスク終了日時字段変更　by zy END
    		// 2018/07/24 終日行動対応　by　zy BEGIN
    		if (event.IsAllDayEvent) {
    			beginLabel = '00:00';
    			Date endDt = event.EndDateTime.date();
    			if (event.EndDateTime__c != null) {
    				endDt = event.EndDateTime__c.date();
    				// 同一天的情况下
	    			if (endDt.daysbetween(event.StartDateTime.date()) == 0) endLabel = '24:00';
	    			else endLabel = '00:00';
    			// 原来状况下的终日行动
    			} else {
    				endLabel = '24:00';
    			}
    		}
    		// 2018/07/24 終日行動対応　by　zy END
    		id = event.id;
    		style = event.CssStyle__c;
    		// 2018/06/25 マルチタスクのタスク登録機能改善繰り返し期間追加 by BEGIN
    		searchKey = event.RecurrenceActivityId;
    		// 2018/06/25 マルチタスクのタスク登録機能改善繰り返し期間追加 by END
    		// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける）by cxw BEGIN
    		groupName = event.GroupCode__c;
    		// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける）by cxw END
    		// 2019/07/15 マルチタスク、一度決めたシフトを個人ごとにロックするボタンなどは設置可能 by zy BEGIN
			isLockFlg = event.IsCantUpdFlg__c;
			// 2019/07/15 マルチタスク、一度決めたシフトを個人ごとにロックするボタンなどは設置可能 by zy END
			// 2020/10/31 担当者を複数設定できるように by zy BEGIN
			cantupd = !CommUtils.isBlank(event.MutliUserDetail__c);
			// 2020/10/31 担当者を複数設定できるように by zy END
			// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
			if (id == null && !CommUtils.isBlank(event.Description)){
				ProjectDetail__c pd = (ProjectDetail__c)JSON.deserialize(event.Description, ProjectDetail__c.class);
				id = pd.id;
				searchKey = pd.RecurrenceActivityId__c;
				isLockFlg = pd.IsCantUpdFlg__c;
				// 2020/10/31 担当者を複数設定できるように by zy BEGIN
				// カレンター非表示の場合、行動不作成、複数担当者画面表示の字段
				if (pd.CalendarFlg__c) userids = pd.UserRefs__c;
				// 2020/10/31 担当者を複数設定できるように by zy END
			} 
			// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
    	}
		// 2019/09/15 マルチタスクで自分専用のグループを作れるようにする(高) by zy BEGIN
		public Task(){}
		// 2019/09/15 マルチタスクで自分専用のグループを作れるようにする(高) by zy END
    }
    // インナークラス・ヘッダー
  	public class dispHeader{
  		public String label{get;set;}
  		public String name{get;set;}
  		public Integer days{get;set;}
  		public String holidayLab{get;set;}		// 祝い日Label
  		public List<String> headTitles{get;set;}
  		public dispHeader(Integer p0, String p1, String p2){
  			label = p1;
  			name = p2;
  			days = p0;
  			isCloseOrFutureDay = false;
  		}
  		public String viewWidth{get;set;}
  		public Boolean isCloseOrFutureDay{get;set;}	// 該当日の未来日　OR　休館日
  	}
    class InnerInfo {
    	String id;
    	String name;
    	String label;
    	InnerInfo parent;
    	public InnerInfo(String curId,String nameStr,String labelStr){
    		id = curId;
    		name = nameStr;
    		label = labelStr;
    	}
    	public InnerInfo(String curId,String nameStr,String labelStr, InnerInfo parend){
    		id = curId;
    		name = CommUtils.nullToBlank(nameStr);
    		label = CommUtils.nullToBlank(labelStr);
    		parent = parend;
    	}
    }
    public class AppConfig {
		
		// 固定検索のAPI項目
		private final Set<String> fixQueryFieldsSet = new Set<String>{'Id'.toLowerCase(),'Name'.toLowerCase(), 'EmployeeCode__c'.toLowerCase(), 'Department'.toLowerCase(), 'UserRole.name'.toLowerCase(), 'Username'.toLowerCase()};
		// 個別表示したい項目リスト
		private List<String> plusFieldsList = new List<String>();
		// NamepSpace Key
		//private final String NS = CommConst.APPOTION_NAMESPACE;
		// 営業の休館ステータス判断用キーワード
		private final String bussineIsCloseKey;
		// 集計指定店舗コード
		public String summaryShopCode{get;private set;}
		// 2015/12/17 行動指定連携の件名のタグ定義情報
		public String eventTitle{get; private set;}
		// 2016/07/22  ゆもとや様より改善要望(シフト表示開始日の変更)  wgch		BEGIN
		public Integer bussEndDayTitle{get; private set;}
		// 2016/07/22  ゆもとや様より改善要望(シフト表示開始日の変更)  wgch		END
		// 2017/05/26 シフトの開始日は変更できるように改善対応 Wgch BEGIN
		public Integer bussStartDayTitle{get; private set;}
		// 2017/05/26 シフトの開始日は変更できるように改善対応 Wgch END
		public AppConfig (String branchShopCode, Dom.XMLNode AppconfigNode) {
			if (AppconfigNode == null) {
				AppconfigNode = getNodeByNodeName('APPCONFIG',branchShopCode);
			}
			if (AppconfigNode == null) return;
			// 設定情報が存在する場合
			Dom.XMLNode userPlusInfField = AppconfigNode.getChildElement('USER_PLUSINF', null);
			String strPlusApiFields = (userPlusInfField == null ? '' : CommUtils.nullToBlank(userPlusInfField.getText()).deleteWhitespace());
			if (!CommUtils.isBLank(strPlusApiFields)) {
				List<String> fieldsSplits = strPlusApiFields.toLowerCase().split(',');
				Set<String> plusfieldFilterSet = new Set<String>();
				for (String api : fieldsSplits) {
					if (fixQueryFieldsSet.contains(api)) continue;
					if (plusfieldFilterSet.contains(api)) continue;
					plusFieldsList.add(api);
					plusfieldFilterSet.add(api);
				}
			}
			// 休館判断用キー
			Dom.XMLNode closeStatusField = AppconfigNode.getChildElement('BUSS_STATUS_CLOSE', null);
			bussineIsCloseKey = (closeStatusField == null ? '' : CommUtils.nullToBlank(closeStatusField.getText()));
			// 修正指定店舗コード
			Dom.XMLNode summaryShopCodeField = AppconfigNode.getChildElement('SUMMARY_SHOP', null);
			summaryShopCode = (summaryShopCodeField == null ? '' : CommUtils.nullToBlank(summaryShopCodeField.getText()));
			// 2015/12/17 行動指定連携の件名のタグ定義情報
			//作業
			eventTitle = Label.CONST_035_0149;
			Dom.XMLNode eventTitleField = AppconfigNode.getChildElement('EVENT_TITLE', null);
			if (eventTitleField != null) {
				String strEventTitle = CommUtils.nullToBlank(eventTitleField.getText());
				if (!CommUtils.isBlank(strEventTitle)) eventTitle = strEventTitle;
			}
			// 2016/07/22  ゆもとや様より改善要望(シフト表示開始日の変更)  wgch		BEGIN
			Dom.XMLNode bussEndDayField = AppconfigNode.getChildElement('BUSS_END_DAY', null);
			if (bussEndDayField != null) {
				String bussEndDay = CommUtils.nullToBlank(bussEndDayField.getText());
				if (!CommUtils.isBlank(bussEndDay) && Pattern.matches('[0-9]*', bussEndDay))
				bussEndDayTitle = CommUtils.nullToIntZero(bussEndDay);
			}
			// 2016/07/22  ゆもとや様より改善要望(シフト表示開始日の変更)  wgch		END
			// 2017/05/26 シフトの開始日は変更できるように改善対応 Wgch BEGIN
			Dom.XMLNode bussStartDayField = AppconfigNode.getChildElement('BUSS_START_DAY', null);
			if (bussStartDayField != null) {
				String bussStartDay = CommUtils.nullToBlank(bussStartDayField.getText());
				if (!CommUtils.isBlank(bussStartDay) && Pattern.matches('[0-9]*', bussStartDay))
				// 为了处理设配置文件设置成0等问题.
				bussStartDayTitle = CommUtils.nullToIntZero(bussStartDay) == 0 ? 1 : CommUtils.nullToIntZero(bussStartDay);
			}
			// 2017/05/26 シフトの開始日は変更できるように改善対応 Wgch END
		}
		// ユーザー情報を検索SQLの文字列を取得する
		public String queryQueryUserField() {
			String queryFields = '';
			for (String fieldApi : fixQueryFieldsSet) {
				queryFields += fieldApi + ',';
			}
			for (String fieldApi : plusFieldsList) {
				queryFields += fieldApi + ',';
			}
			return queryFields.removeEnd(',') + ' ';
		}
		public String getPlusInfFromUser(User usr) {
			if (plusFieldsList.isEmpty()) return '';
			else {
				String msg = '';
				for (String api : plusFieldsList) {
					msg += CommUtils.nullToBlank(usr.get(api)) + ' ';
				}
				return msg.trim();
			}
		}
		// 休館するがどうか、判断を行う
		public Boolean isCloseStatus(String status) {
			if (CommUtils.isBlank(bussineIsCloseKey)) return false;
			return (status == bussineIsCloseKey);
		}
	}
	// 指定タグ名で定義情報を戻る
	private static Dom.XMLNode getNodeByNodeName(String tagName, String branchShopCode) {
		Dom.XmlNode targetNode = CommXmlUtils.encodeParseXmlDoc('StaffScheduleConfigXml',branchShopCode,new String[]{'<COONDITION>','</COONDITION>'});
		Dom.XMLNode retXmlNode = null;
		for(Dom.XMLNode xmlNode : targetNode.getChildElements()){
			// タグ名
			String attributeName = xmlNode.getName();
			if (attributeName.equalsIgnoreCase(tagName)) {
				retXmlNode = xmlNode;
				break;
			}
		}
		return retXmlNode;
	}
	public Class TaskConfig {
		public List<String> taskHtmlLst;
		public TaskConfig(String branchShopCode, Dom.XMLNode taskConfigNode,String title) {
			// TASK 未割り当てタスク場合
			taskHtmlLst = new List<String>();
			// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける） by cxw BEGIN
			groupNameMap = new Map<String,String>();
			groupCodeMap = new Map<String,String>();
			// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける） by cxw END
			// 2019/04/15 登録したタスクをダブルクリックで行動にリンクする by zy BEGIN
            bothUpdFlag = false;
            // 2019/04/15 登録したタスクをダブルクリックで行動にリンクする by zy END
			// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy BEGIN
			tempInfoJson = '';
			taskOpts = new List<TaskInfo> ();
			TempInfo newInfo = new TempInfo();
			// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy END
			// 2019/10/15 マスタタスク、タスクテンプレートの文言を行動の任意の項目に自動で記入できるように改善対応 by zy BEGIN
			Map<String, Schema.DescribeFieldResult> sobjResutltMap = CommSqlUtils.getAllFieldLst(Event.sobjectType,true,true);
			// 2019/10/15 マスタタスク、タスクテンプレートの文言を行動の任意の項目に自動で記入できるように改善対応 by zy END
			// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy BEGIN
			Map<String,String> eventFieldMap = new Map<String,String>();
			for (FieldDefinition fd : [select DataType, DeveloperName, DurableId, ValueTypeId,QualifiedApiName from FieldDefinition where EntityDefinition.QualifiedApiName = 'Event' and QualifiedApiName like'%__c']){
				eventFieldMap.put(fd.QualifiedApiName,fd.DurableId.replace('Event.',''));
			}
			List<TempInfo> infos = new List<TempInfo>();
			// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy END
			if (taskConfigNode == null) {
                taskConfigNode = getNodeByNodeName('TASKCONFIG',branchShopCode);
            }
			if ( taskConfigNode != null ) {
				String colorStr = taskConfigNode.getAttribute('COLOR',null);
				if (!CommUtils.isBlank(colorStr)) color = colorStr;
				// 2018/03/27 タスクのTITLE変更可能機能追加　by　zy　BEGIN
				quickUpdFlag = false;
				String quickSaveStr = taskConfigNode.getAttribute('QUCIKEDIT',null);
				// 2019/04/15 登録したタスクをダブルクリックで行動にリンクする by zy BEGIN
				String quickSave = CommUtils.nullToblank(quickSaveStr);
				if (quickSave.toUpperCase() == 'BOTH') bothUpdFlag = true;
				// 2019/04/15 登録したタスクをダブルクリックで行動にリンクする by zy END
				if (!CommUtils.isBlank(quickSaveStr)) quickUpdFlag = boolean.valueOf(CommUtils.nullToBlank(quickSaveStr));
				// 2018/03/27 タスクのTITLE変更可能機能追加　by　zy　END
				for(Dom.XMLNode xmlNode : taskConfigNode.getChildElements()){
					String xmlName = xmlNode.getName();
					if ( xmlName == 'TASK') {
						TaskInfo task = new TaskInfo(xmlNode);
						if (CommUtils.isBlank(task.name)) task.name = title;
						// 失效数据跳过
						if (CommUtils.isBlank(task.row) && CommUtils.isBlank(task.beginTime) && CommUtils.isBlank(task.endTime)) continue;
						// 符合规范的时间check
						// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける） by cxw BEGIN
						if(!CommUtils.isBlank(task.groupName) && !CommUtils.isBlank(task.groupCode)) groupNameMap.put(task.name,task.groupCode);
						if(!CommUtils.isBlank(task.groupName) && !CommUtils.isBlank(task.groupCode)) groupCodeMap.put(task.groupCode,task.groupName);
						// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける） by cxw END
						if (!CommUtils.isBlank(task.beginTime)) {
							Time begTime = CommUtils.stringtotime(task.beginTime);
							if (begTime == null) continue;
							DateTime ft = DateTime.newInstance(Date.today(), begTime);
							task.beginTime = ft.format('HH:mm');
						}
						if (!CommUtils.isBlank(task.endTime)) {
							Time endTime = CommUtils.stringtotime(task.endTime);
							if (endTime == null) continue;
                            DateTime ft = DateTime.newInstance(Date.today(), endTime);
                            task.endTime = ft.format('HH:mm');
						}
						// 2019/10/15 マスタタスク、タスクテンプレートの文言を行動の任意の項目に自動で記入できるように改善対応 by zy BEGIN
						if (!CommUtils.isBlank(task.field) && sobjResutltMap.containsKey(task.field.tolowerCase())) task.field = sobjResutltMap.get(task.field.tolowerCase()).getLocalName();
						else task.field = null;
						// 2019/10/15 マスタタスク、タスクテンプレートの文言を行動の任意の項目に自動で記入できるように改善対応 by zy END
						taskHtmlLst.add(task.exportDiv());
					// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy BEGIN	
						taskOpts.add(task);
					} else if (xmlName == 'TEMP') {
						String name = xmlNode.getAttribute('name',null); 
						String newFlag = xmlNode.getAttribute('isnew',null); 
						TempInfo info = new TempInfo(name,xmlNode);
						if (!CommUtils.isBlank(newFlag) && Boolean.valueOf(CommUtils.nullToBlank(newFlag))) newInfo = info;
						infos.add(info);
					}
					// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy END
				}
			}
		}
		public String color;
		// 2018/03/27 タスクのTITLE変更可能機能追加　by　zy　BEGIN
		public boolean quickUpdFlag;
		// 2018/03/27 タスクのTITLE変更可能機能追加　by　zy　END
		// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける） by cxw BEGIN
		public Map<String,String> groupNameMap;
		public Map<String,String> groupCodeMap;
		// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける） by cxw END
		// 2019/04/15 登録したタスクをダブルクリックで行動にリンクする by zy BEGIN
		// 編集と件名機能開く
		public boolean bothUpdFlag;
		// 2019/04/15 登録したタスクをダブルクリックで行動にリンクする by zy END
		// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy BEGIN
		public String tempInfoJson;
		public String fieldStr;
		public List<TaskInfo> taskOpts;
		// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy END
	}
	// 2017/09/05 指定権限制限機能追加 BEGIN
	public class RoleConfig {
        public RoleConfig (String branchShopCode, Dom.XMLNode roleConfigNode) {
            editRoleSet = new set<String>();
            viewRoleMap = new map<String, Set<String>>();
            if (roleConfigNode == null) {
                roleConfigNode = getNodeByNodeName('ROLECONFIG',branchShopCode);
            }
            if (roleConfigNode == null) return;
            // 定義情報をチェックする
            Dom.XMLNode editableRoleField = roleConfigNode.getChildElement('EDITABLE_ROLE', null);
            if (editableRoleField != null) {
                String editableStr = CommUtils.nullToBlank(editableRoleField.getText());
                for (String s : editableStr.split(',')) {
                    s = CommUtils.nullToBlank(s);
                    if (!CommUtils.isBlank(s)) editRoleSet.add(s);
                }
            }
            Dom.XMLNode viewRoleField = roleConfigNode.getChildElement('VIEW_ROLE', null);
            if (viewRoleField != null) {
                for (Dom.XmlNode memberRole : viewRoleField.getChildElements()) {
                     String roleKeyStr = CommUtils.nullToBlank(memberRole.getText());
                     String roleManagerStr = CommUtils.nullToBlank(memberRole.getAttribute('MANGER',null));
                     if (CommUtils.isBLank(roleKeyStr) || CommUtils.isBlank(roleManagerStr)) continue;
                     List<String> roleKeys = roleKeyStr.split(',');
                     List<String> managers = roleManagerStr.split(',');
                     for (String roleKey : roleKeys) {
                         roleKey = CommUtils.nullToBlank(roleKey);
                         if (CommUtils.isBlank(roleKey)) continue;
                         for (String managerKey : managers) {
                             managerKey = CommUtils.nullToBlank(managerKey);
                             if (CommUtils.isBlank(managerKey)) continue;
                             if (!viewRoleMap.containsKey(roleKey)) viewRoleMap.put(roleKey, new set<string>());
                             viewRoleMap.get(roleKey).add(managerKey);
                         }
                     }
                }
            }    
//System.debug(loggingLevel.info, 'editRoleSet='+editRoleSet); 
//System.debug(loggingLevel.info, 'viewRoleMap='+viewRoleMap);
        }
        public Boolean isEditForSameRole(String rolenm) {
            return editRoleSet.contains(rolenm);
        }
        public Set<String> getUserViewDefSet(String rolenm) {
            return viewRoleMap.get(rolenm);
        }
        private set<String> editRoleSet{get; private set;}
        private map<String, Set<String>> viewRoleMap{get; private set;}
	}
	// 2017/09/05 指定権限制限機能追加 END
	/*テストクラス　無効ソース対応　by　zy　
	// 支店単位の休館、営業制御情報格納
    public class HotelStatusInfo {
    	public HotelStatusInfo (String normalStatus) {
    		//isOpenHotelFlg = true;
    		//hotelStatus = CONST_NORMAL_HOTEL;
    		hotelStatus = normalStatus;
    	}
    	//public Boolean isOpenHotelFlg{get;set;}	// 支店開館・休館フラグ
    	public String startDate{get;set;}		// 制御開始日
    	public String endDate{get;set;}			// 制御終了日
    	public String hotelStatus{get;set;}		//　支店のステータス
    }*/
    // インナークラス・データ
  	public class dispRecord{
  		public Id roomTypeId{get;set;}
  		public String roomTypeNm{get;set;}
//======================  		
  		public Id userId{get;set;}
  		public String userNm{get;set;}
		// 2017/03/07 シフト->新規行動機能対応 BEGIN zyz
		public String eventNm{get;set;}
		// 2017/03/07 シフト->新規行動機能対応 END zyz
		public String name{get;set;}
  		public String userPlusInf{get;set;}
  		public String roleClass{get;set;}
  		public Decimal dateTimeSum{get;set;}
  		public Decimal timeWorkSumByUser{get;set;}
  		public List<TimeMessage> timeList{get;set;}
//========================  		  		  		 		
        public List<GuestRoomStock__c> roomList{get;set;}
        public dispRecord(){
        	roomList = new List<GuestRoomStock__c>();
        	timeList = new List<TimeMessage>();
        }
        // 2017/09/05 指定権限制限機能追加 BEGIN
        // 内容を設定すると、ログインユーザーは該当ユーザーの既存情報が参照のみ
        public String isViewFlg{get;set;}
        // 2017/09/05 指定権限制限機能追加 END
  	}
  	// 集計定義情報
	public static LeadSummaryInfo summaryInfo{get; private set;}
	// XML定義情報を格納する
	class LeadSummaryInfo {
		public LeadSummaryInfo() {
			conditionKey = new List<String>();
			conditionVal = new List<String>();
			summaryKeyValMap = new map<String, List<String>>();
		}
		public map<String, List<String>> summaryKeyValMap{get; private set;}
		public List<String> conditionKey{get; private set;}
		public List<String> conditionVal{get; private set;}
		public void addXmlNodeInfo(String con, String val) {
			conditionKey.add('id');
			conditionVal.add(val.trim());
			if (!summaryKeyValMap.containsKey(con)) {
				summaryKeyValMap.put(con, new list<String>());
			}
			summaryKeyValMap.get(con).add(val);
		}
	}
	public static WorkTimeButtonInfo workTimeBtnInfo{get; private set;}
	public class WorkTimeButtonInfo {
		public WorkTimeButtonInfo() {
			/*
			Start_BackColor = '#0066ff';
			Start_FontColor = '#ffffff';
			RestStart_BackColor = '#006677';
			RestStart_FontColor = '#ffffff';
			RestEnd_BackColor = '#ff00ff';
			RestEnd_FontColor = '#ffffff';
			End_BackColor = '#ff0000';
			End_FontColor = '#ffffff';*/
		}
		// 勤怠開始ボタン
		public String Start_BackColor{get;set;}
		public String Start_FontColor{get;set;}
		public String startStyle{get{
			//return ('background-color:'+Start_BackColor + ';color:'+Start_FontColor+';');
			String styleStr = '';
			if (!CommUtils.isBlank(Start_BackColor)) styleStr += 'background-color:'+Start_BackColor+';';
			if (!CommUtils.isBlank(Start_FontColor)) styleStr += 'color:'+Start_FontColor+';';
			return styleStr;
		}}
		// 勤怠外出ボタン
		public String RestStart_BackColor{get;set;}
		public String RestStart_FontColor{get;set;}
		public String restStartStyle{get{
			//return ('background-color:'+RestStart_BackColor + ';color:'+RestStart_FontColor+';');
			String styleStr = '';
			if (!CommUtils.isBlank(RestStart_BackColor)) styleStr += 'background-color:'+RestStart_BackColor+';';
			if (!CommUtils.isBlank(RestStart_FontColor)) styleStr += 'color:'+RestStart_FontColor+';';
			return styleStr;
		}}
		// 勤怠入室ボタン
		public String RestEnd_BackColor{get;set;}
		public String RestEnd_FontColor{get;set;}
		public String restEndStyle{get{
			//return ('background-color:'+RestEnd_BackColor + ';color:'+RestEnd_FontColor+';');
			String styleStr = '';
			if (!CommUtils.isBlank(RestEnd_BackColor)) styleStr += 'background-color:'+RestEnd_BackColor+';';
			if (!CommUtils.isBlank(RestEnd_FontColor)) styleStr += 'color:'+RestEnd_FontColor+';';
			return styleStr;
		}}
		// 勤怠退勤ボタン
		public String End_BackColor{get;set;}
		public String End_FontColor{get;set;}
		public String endStyle{get{
			//return ('background-color:'+End_BackColor + ';color:'+End_FontColor+';');
			String styleStr = '';
			if (!CommUtils.isBlank(End_BackColor)) styleStr += 'background-color:'+End_BackColor+';';
			if (!CommUtils.isBlank(End_FontColor)) styleStr += 'color:'+End_FontColor+';';
			return styleStr;
		}}
		// 勤怠修正ボタン
		public String WkTimeEdit_BackColor{get;set;}
		public String WkTimeEdit_FontColor{get;set;}
		public String wkTimeEditStyle {get{
			String styleStr = '';
			if (!CommUtils.isBlank(WkTimeEdit_BackColor)) styleStr += 'background-color:'+WkTimeEdit_BackColor+';';
			if (!CommUtils.isBlank(WkTimeEdit_FontColor)) styleStr += 'color:'+WkTimeEdit_FontColor+';';
			return styleStr;
		}}
		/*
		// スタッフの色
		public String Memo_BackColor{get;set;}
		public String Memo_FontColor{get;set;}
		public String memoStyle{get{
			String styleStr = '';
			if (!CommUtils.isBlank(Memo_BackColor)) styleStr += 'background-color:'+Memo_BackColor+' !important;';
			if (!CommUtils.isBlank(Memo_FontColor)) styleStr += 'color:'+Memo_FontColor+' !important;';
			return styleStr;
		}}*/
	}
	public class LeadMessageInfo{
		public Map<String,String> result;
		public Map<String,String> leadIds;
		public LeadMessageInfo(Map<String,String> peopleResult,Map<String,String> leadIdResult){
			result = peopleResult;
			leadIds = leadIdResult;
		}
	}
	public class AjaxRequest {
		List<String> userLst;
		String begDate;
		String endDate;
		Integer columns;
		String label;
		String field;
		string taskid;
		// 2018/06/25 マルチタスクのタスク登録機能改善繰り返し期間追加 by BEGIN
		boolean delSameFlag;
		// 2018/06/25 マルチタスクのタスク登録機能改善繰り返し期間追加 by END
		List<AjaxRequest> rows;
		// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける） by cxw BEGIN
		String spcd;
		string filterTips;
		// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける） by cxw END
		// 2019/07/15 マルチタスク、一度決めたシフトを個人ごとにロックするボタンなどは設置可能 by zy BEGIN
		Set<String> eventIds;
		// 2019/07/15 マルチタスク、一度決めたシフトを個人ごとにロックするボタンなどは設置可能 by zy END
		// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy BEGIN
		boolean isUserFlg;
		String sqlWhere;
		// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy END
	}
	class TaskInfo{
		String row;
		String color;
		String beginTime;
		String endTime;
		String modeClass;
		String name;
		// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける） by cxw BEGIN
		String groupName;
		String groupCode;
		// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける） by cxw END
		// 2018/06/25 マルチタスクのタスク登録機能改善繰り返し期間追加 by BEGIN
		boolean isDaily;
		// 2018/06/25 マルチタスクのタスク登録機能改善繰り返し期間追加 by END
		// 2019/10/15 マスタタスク、タスクテンプレートの文言を行動の任意の項目に自動で記入できるように改善対応 by zy BEGIN
		String field;
		// 2019/10/15 マスタタスク、タスクテンプレートの文言を行動の任意の項目に自動で記入できるように改善対応 by zy END
		// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
		boolean calendarFlg;
		// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
		public TaskInfo(Dom.XmlNode taskNode){
			//modeClass = CommUtils.nullToBlank(taskNode.getAttribute('MODE',null));
			row = CommUtils.nullToBlank(taskNode.getAttribute('ROW',null));
			color = CommUtils.nullToBlank(taskNode.getAttribute('COLOR',null));
			beginTime = CommUtils.nullToBlank(taskNode.getAttribute('BEG',null));
			endTime = CommUtils.nullToBlank(taskNode.getAttribute('END',null));
			name = CommUtils.nullToBlank(taskNode.getText());
			// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける） by cxw BEGIN
			groupName = CommUtils.nullToBlank(taskNode.getAttribute('GPLABEL',null)).trim();
			groupCode = CommUtils.nullToBlank(taskNode.getAttribute('GPCODE',null)).trim();
			// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける） by cxw END
			// 2018/06/25 マルチタスクのタスク登録機能改善繰り返し期間追加 by BEGIN
			isDaily = false;
			String dailyStr = CommUtils.nullToBlank(taskNode.getAttribute('REPEAT',null));
			if (!CommUtils.isBlank(dailyStr)) isDaily = boolean.valueOf(dailyStr);
			// 2018/06/25 マルチタスクのタスク登録機能改善繰り返し期間追加 by END
			// 2019/10/15 マスタタスク、タスクテンプレートの文言を行動の任意の項目に自動で記入できるように改善対応 by zy BEGIN
			field = CommUtils.nullToBlank(taskNode.getAttribute('FIELD',null));
			// 2019/10/15 マスタタスク、タスクテンプレートの文言を行動の任意の項目に自動で記入できるように改善対応 by zy END
			// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
			calendarFlg = true;
			String calendarText = taskNode.getAttribute('CALENDAR',null);
			if (!Commutils.isblank(calendarText)) calendarFlg = Boolean.valueof(CommUtils.nullToBlank(calendarText));
			// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
		}
		public String exportDiv() {
			String div = '<div ';
			div += 'class="taskTemp ';
			//if (!CommUtils.isBlank(modeClass)) div += modeClass;
			div += '"';
			if (!CommUtils.isBlank(color)) div += ' background="' + color + '" style="background:' + color + '"';
			if (!CommUtils.isBlank(row)) div += ' row="' + row + '"';
			if (!CommUtils.isBlank(beginTime)) div += ' begin="' + beginTime + '"';
			if (!CommUtils.isBlank(endTime)) div += ' end="' + endTime + '"';
			// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける） by cxw BEGIN
			if (!CommUtils.isBlank(groupCode)) div += ' group="' + groupCode + '"';
			// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける） by cxw END
			// 2018/06/25 マルチタスクのタスク登録機能改善繰り返し期間追加 by BEGIN
			if (isDaily) div += ' daily="' + isDaily + '"';
			// 2018/06/25 マルチタスクのタスク登録機能改善繰り返し期間追加 by END
			// 2019/10/15 マスタタスク、タスクテンプレートの文言を行動の任意の項目に自動で記入できるように改善対応 by zy BEGIN
			if (!CommUtils.isBlank(field)) div += ' field="' + field + '"';
			// 2019/10/15 マスタタスク、タスクテンプレートの文言を行動の任意の項目に自動で記入できるように改善対応 by zy END
			// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
			if (!calendarFlg) div += ' cal="' + calendarFlg + '"';
			// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
			div += '> ' + name + ' </div>';
			return div;
		}
	}
	// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける） by cxw BEGIN
	public List<SelectOption> tipsOpts{get;set;}
	public String filterTips{get;set;}
	//　プロジェックト選択リスト
	public String projectId{get;set;}
	public String otherValue{get{return StaffTaskHelp.DEF_OTHER;}private set;}
	public void changeInitProect(){
		doAction(null);
	}
	// シフトのラベル取得
	private static Map<String,String> getDefCodeMap(String spcd,List<Id> userIds,date begDt,Date endDt){
		Map<String,String> groupCodeMap = new Map<String,String>();
		List<StaffSchedule__c> staffs = StaffTaskHelp.getUserStaffTask(userIds,begDt,endDt);
		Set<String> excudeEvents = new Set<String>();
		if (!staffs.isEmpty()) {
			String defStaffName = Label.CONST_035_0149;
			// XML読み込み
			Dom.XmlNode targetNode = CommXmlUtils.encodeParseXmlDoc('StaffScheduleConfigXml',spcd,new String[]{'<COONDITION>','</COONDITION>'});
			if (targetNode != null) {
				Dom.XMLNode eventTitleField = targetNode.getChildElement('EVENT_TITLE', null);
				if (eventTitleField != null) 
					groupCodeMap.put(StaffTaskHelp.DEF_STAFF,CommUtils.nulltoBlank(eventTitleField.getText()));
			}
			groupCodeMap.put(StaffTaskHelp.DEF_STAFF,defStaffName);
			for (StaffSchedule__c staff : staffs) {
				excudeEvents.add(staff.eventId__c);
			}
		}
		if (!StaffTaskHelp.getUserOtherEvent(userIds,begDt,endDt,excudeEvents).isEmpty()) groupCodeMap.put(StaffTaskHelp.DEF_OTHER,'その他');
		return groupCodeMap;
	}
	// プロジェックト選択リスト作成
	private void initProjectOpts(List<Id> userIds,String spcd){
		// 2019/08/31 マルチタスクについて、今「その他」で絞りをかけた後画面更新（Command+R）をするとプロジェクト管理が消えました。絞り込みの保持 by zy BEGIN
	   	// filterTips = '';
		// Cookieからレイアウトモードを取得する
		filterTips = CommUtils.nullToBlank(userBookMap.get(UserConfigCompCtrl.KREP_SUBTYPE.SETINFO.name()));
	   	// 2019/08/31 マルチタスクについて、今「その他」で絞りをかけた後画面更新（Command+R）をするとプロジェクト管理が消えました。絞り込みの保持 by zy END
		tipsOpts = new List<SelectOption>();
		if (CommUtils.isBlank(spcd) && branchShopLst.size() > 1) return;
		date begDt = startDate;
		Date endDt = startDate.addDays(daysInMonth);
		// フィルター選択リスト内容作成
		tipsOpts = getFilterOpts(userIds,spcd,begDt,endDt);
	}
	// フィルター選択リスト内容作成
	private static List<SelectOption> getFilterOpts(List<Id> userIds,String spcd,date begDt,Date endDt){
		Map<String,Selectoption> optsMap = new Map<String,Selectoption>();
		// 該当画面表示ユーザーの既存行動グループコード取得
		Set<String> filterSet = StaffTaskHelp.getGroups(userIds);
		TaskConfig taskConfig = new TaskConfig(spcd, null,null);
		Map<String,String> groupCodeMap = taskConfig.groupCodeMap;
		groupCodeMap.putAll(getDefCodeMap(spcd,userIds,begDt,endDt));
		for (String groupCode : groupCodeMap.keySet()) {
			if (!optsMap.containsKey(groupCode)) {
				String groupLabel = CommUtils.nullToBlank(groupCodeMap.get(groupCode));
				optsMap.put(groupCode,new SelectOption(groupCode,groupLabel));
			}
		}
		// 私有プロジェックト
		List<ProjectMain__c> priveteProjects = StaffTaskHelp.getMainPorjects(UserUtil.CurrentUser.id,UserUtil.CurrentUserInfo.u.StaffScheduleAllEdit__c);
		for (ProjectMain__c main : priveteProjects) {
			String manaUser = CommUtils.nullToBlank(main.ManagerUser__c);
			String assignUser = CommUtils.nullToBlank(main.AssignUser__c);
			optsMap.put(main.id,new SelectOption(main.id,CommUtils.nullToBlank(main.name)));
		}
		// 該当ユーザ
		for (String filter : filterSet) {
			if (optsMap.containsKey(filter)) 
				optsMap.get(filter).setLabel(groupCodeMap.get(filter));
		}
		return optsMap.values();
	}
	@remoteAction
	public static Object getProjectOpts(String req){
		List<Object> result = new List<Object>();
		if (!CommUtils.isBlank(req)) {
			AjaxRequest request = (AjaxRequest)JSON.deserializeStrict(req, AjaxRequest.class);
			String spcd = CommUtils.nullToblank(request.spcd);
			List<String> userIdStr = request.userLst;
			Date startDt = CommUtils.stringtoDate(CommUtils.nullToBlank(request.begDate));
			Date endDt = CommUtils.stringtoDate(CommUtils.nullToBlank(request.endDate));
			List<Id> userIds = new List<Id>();
			for (String userId : userIdStr) {
				userIds.add(Id.valueOf(userId));
			}
			List<SelectOption> tipsOpts = getFilterOpts(userIds,spcd,startDt,endDt);
			for (SelectOption sec : tipsOpts) {
				result.add(new Map<String,String>{'value' => sec.getValue(),'label' => sec.getLabel()});
			}
		}
		return result;
	}
	
	// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける） by cxw END
	// 2019/04/15 登録したタスクをダブルクリックで行動にリンクする by zy BEGIN
	public boolean isBothUpd{get;set;}
	// 2019/04/15 登録したタスクをダブルクリックで行動にリンクする by zy END
	// 2019/05/15 タスク管理でルームインジケーターの様に前日当日翌日のボタンを設置する事は可能でしょうか。
   	// また7日で表示させた際に4時間ごとの時間の区切りになりますが、1時間ごとの表示にすることは叶いませんでしょうか by zy BEGIN
	public void toPrev(){
		if (MONTH_MODE_FLG) {
			timeTable.Checkinday__c = timeTable.Checkinday__c.addMonths(-1);
		} else {
			timeTable.Checkinday__c = timeTable.Checkinday__c.addDays(-1);
		}
		processDay = timeTable.Checkinday__c;
		doAction(0);
	}
	public void toToday(){
		timeTable.Checkinday__c = system.today();
		doAction(null);
	}
	public void toNext(){
		// 月モード
		if (MONTH_MODE_FLG) {
			timeTable.Checkinday__c = timeTable.Checkinday__c.addMonths(1);
		} else {
			timeTable.Checkinday__c = timeTable.Checkinday__c.addDays(1);
		}
		processDay = timeTable.Checkinday__c;
		doAction(0);
	}
	public boolean isShowHisFlg{get;set;}
	private boolean is24HourFlg;
	// モード設定
	public String otherSetting{get;set;}
	// 月モード
	public boolean MONTH_MODE_FLG{get{ return viewMode == CONST_VIEWMODE_1 || viewMode == CONST_VIEWMODE_3;}private set;}
	private void initDocment(){
    	isShowHisFlg = false;
    	is24HourFlg = false;
    	otherSetting = '';
    	// 2019/06/30 マルチタスク、キーワード検索機能 by zy BEGIN
    	isShowFilterFlg = false;
    	// 2019/06/30 マルチタスク、キーワード検索機能 by zy END
    	// XML読み込み
		Dom.XmlNode targetNode = CommXmlUtils.encodeParseXmlDoc('StaffScheduleConfigXml',branchShopNm,new String[]{'<COONDITION>','</COONDITION>'});
		Dom.xmlNode taskConfig = targetNode.getChildElement('TASKCONFIG',null);
		if (taskConfig != null) {
			// 今日ボタン表示
			String dateBtnStr = taskConfig.getAttribute('SHOWDATEBTN',null);
			if (dateBtnStr != null) isShowHisFlg = Boolean.valueOf(CommUtils.nullToBlank(dateBtnStr));
			// 週モード２４時表示
			String weekHourStr = taskConfig.getAttribute('WEEK24HOUR',null);
			if (weekHourStr != null) is24HourFlg = Boolean.valueOf(CommUtils.nullToBlank(weekHourStr));
			// 2019/06/30 マルチタスク、キーワード検索機能 by zy BEGIN
			String filterStr = taskConfig.getAttribute('FILTER',null);
	    	if (!CommUtils.isBlank(filterStr)) isShowFilterFlg = boolean.valueof(COmmUtils.nullToblank(filterStr));
	    	// 2019/06/30 マルチタスク、キーワード検索機能 by zy END
		}
    	if (is24HourFlg) {
	    	otherSetting = JSON.serialize(new Map<String,Map<String,object>>{
	    		'ONEWEEK' => new Map<String,Object>{
	    			'daySync' => 24,
					'eachTime' => 60
	    		}
	    	});
    	}
	}
	// 2019/05/15 タスク管理でルームインジケーターの様に前日当日翌日のボタンを設置する事は可能でしょうか。
   	// また7日で表示させた際に4時間ごとの時間の区切りになりますが、1時間ごとの表示にすることは叶いませんでしょうか by zy END
   	
   	// 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy BEGIN
    // 指定日あり
    private boolean hadDateFlg = false;
    // 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy END
    // 2019/06/30 マルチタスク、キーワード検索機能 by zy BEGIN
    // フィルター機能表示フラグ
    public boolean isShowFilterFlg{get;set;}
    // 2019/06/30 マルチタスク、キーワード検索機能 by zy END
    // 2019/07/15 マルチタスク、一度決めたシフトを個人ごとにロックするボタンなどは設置可能 by zy BEGIN
   	@remoteAction
   	public static object remoteCenter(String dataType,String request){
   		// 行動ロック
   		if (dataType == 'lockEvent') lockEvent(request);
   		// 行動ロック解除
   		else if (dataType == 'unLockEvent') unLockEvent(request);
		// 2019/09/15 キーワード検索機能ですがAND検索になっていますのでORの検索もできればいい by zy BEGIN
		// 画面設定保持
		else if (dataType == 'saveSettingInfo') saveSettingInfo(request);
		// 2019/09/15 キーワード検索機能ですがAND検索になっていますのでORの検索もできればいい by zy END
		// 2019/09/15 マルチタスクで自分専用のグループを作れるようにする(高) by zy BEGIN
		// グループ追加
		else if (dataType == 'saveUserGroup') return saveUserGroup(request);
		else if (dataType == 'getUserLst') return getUserLst(request);
		else if (dataType == 'deleteUserGroup') return deleteUserGroup(request);
		// 2019/09/15 マルチタスクで自分専用のグループを作れるようにする(高) by zy END
   		return null;
   	}
   	// 行動ロック
   	private static void lockEvent(String req){
   		AjaxRequest request = (AjaxRequest)JSON.deserializeStrict(req, AjaxRequest.class);
   		List<Event> updLst = new List<event>();
		// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
		List<ProjectDetail__c> pds = new List<ProjectDetail__c>();
		// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
   		for (String eventId : request.eventIds) {
			// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
			if (eventId.startsWith(projectPrefix)) pds.add(new ProjectDetail__c(id = eventId,IsCantUpdFlg__c = true));
			else
			// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
   			updLst.add(new Event(id = eventId,IsCantUpdFlg__c = true));
   		}
   		if (!updLst.isEmpty()) update updLst;
		// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
		if (!pds.isEmpty()) StaffTaskHelp.updateProjectDetail(pds);
		// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
   	}
   	// 行動ロック解除
   	private static void unLockEvent(String req){
   		AjaxRequest request = (AjaxRequest)JSON.deserializeStrict(req, AjaxRequest.class);
   		List<Event> updLst = new List<event>();
		// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
		List<ProjectDetail__c> pds = new List<ProjectDetail__c>();
		// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
   		for (String eventId : request.eventIds) {
			// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
			if (eventId.startsWith(projectPrefix)) pds.add(new ProjectDetail__c(id = eventId,IsCantUpdFlg__c = false));
			else
			// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
   			updLst.add(new Event(id = eventId,IsCantUpdFlg__c = false));
   		}
   		if (!updLst.isEmpty()) update updLst;
		// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
		if (!pds.isEmpty()) StaffTaskHelp.updateProjectDetail(pds);
		// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
   	}
	// 2019/09/15 マルチタスクで自分専用のグループを作れるようにする(高) by zy BEGIN
	private static object saveUserGroup(String req){
		AjaxRequest request = (AjaxRequest)JSON.deserializeStrict(req, AjaxRequest.class);
		String userIds = String.join(request.userLst,',');
		String userGroupId = CommUtils.nullToBlank(request.taskid);
		if (CommUtils.isBlank(request.taskid)) {
   			userGroupId = StaffTaskHelp.insertUserConfig(new UserConfig__c(
				   FunctionType__c = UserConfigCompCtrl.FUNCTION_TYPE.TASK.name(),
				   FunctionSubType__c = StaffTaskHelp.USER_GROUP_SUB + request.label,
				   ConfigInfo__c = userIds,
				   UserRef__c = UserUtil.CurrentUser.id,
				   ShopCode__c = request.spcd
			   ));
		} else 
			StaffTaskHelp.updateUserConfig(
				new UserConfig__c(
					id = request.taskid,
					FunctionSubType__c = StaffTaskHelp.USER_GROUP_SUB + request.label,
					ConfigInfo__c = userIds
				)
			);
		return userGroupId;
	}
	private static Object deleteUserGroup(String req){
		AjaxRequest request = (AjaxRequest)JSON.deserializeStrict(req, AjaxRequest.class);
		StafftaskHelp.deleteUserGroup(new UserConfig__c(id = request.taskid));
		return null;
	}
	private static Object getUserLst(String req){
		AjaxRequest request = (AjaxRequest)JSON.deserializeStrict(req, AjaxRequest.class);
		String branchNm = request.spcd;
		// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy BEGIN
		String filterTips = request.filterTips;
		// 条件指定
		String limitSql = request.field;
		String sqlWhere = request.sqlWhere;
		Set<String> departCodes = request.eventIds != null ? request.eventIds : new Set<String>();
		String userQuery = 'select id,name,Department from User ';
		String userWhere = ' StaffScheduleNoshow__c != true And IsActive = true ';
        if (!CommUtils.isBlank(branchNm)) {
            // userQuery += 'and ( DefaultShopCode__c = :branchNm or ShopCode__c = :branchNm ) ';
	    	userWhere += 'and ( DefaultShopCode__c = :branchNm or ShopCode__c = :branchNm ) ';
        }
		// ユーザグループ指定
		String userGroupId = request.taskid;
		Set<String> userGroupSet = new Set<String>();
		if (!CommUtils.isBlank(userGroupId)){
			// 2019/12/30 5310 bug fixed by zy BEGIN
			List<Task> tasks = getUserConfig(null,userGroupId,branchNm);
			// 2019/12/30 5310 bug fixed by zy END
			if (!tasks.isEmpty()) {
				String userLstStr = CommUtils.nullTOBlank(tasks[0].groupName);
				userGroupSet = new Set<String>(userLstStr.split(','));
			}
		}
		if (!userGroupSet.isEmpty()) userWhere += ' and id = :userGroupSet ';
		if (!CommUtils.isBlank(sqlWhere)) userWhere += ' and (' + sqlWhere + ') ';
		if (!departCodes.isEMpty()) userWhere += ' and department in :departCodes ';
		userQuery += ' where ' + userWhere;
		// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy END
        userQuery += 'order by EmployeeCode__c asc Nulls Last , Name  Nulls Last ';
		if (!CommUtils.isBlank(limitSql)) userQuery += limitSql;
		List<Map<String,String>> userLst = new List<Map<String,String>>();
		// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy BEGIN
		List<User> userList = new List<User>();
		if (!CommUtils.isBlank(filterTips)) {
			String query = 'find :filterTips IN ALL FIELDS RETURNING user(id,name,Department where ' + userWhere + ')  ';
			List<List<Sobject>> userRs = search.query(query);
			userList = (List<User>)userRs[0];
		} else userList = Database.query(userQuery);
		for (User u : userList) {
		// for (User u : Database.query(userQuery)) {
			userLst.add(new Map<String,String>{'text'=> u.name,'value'=> u.id,'depart' => u.Department});
		// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy END
		}
		return userLst;
	}
	// 2019/09/15 マルチタスクで自分専用のグループを作れるようにする(高) by zy END
	// 2019/09/15 キーワード検索機能ですがAND検索になっていますのでORの検索もできればいい by zy BEGIN
	// 画面設定保持
	private static void saveSettingInfo(String req){
		CookieInfo request = (CookieInfo)JSON.deserializeStrict(req, CookieInfo.class);
   		UserConfigCompCtrl.saveCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.TASK,UserConfigCompCtrl.KREP_SUBTYPE.VIEWMODE.name(),JSON.serialize(request),UserUtil.CurrentUser.id,'');
	}
	// 2019/09/15 キーワード検索機能ですがAND検索になっていますのでORの検索もできればいい by zy END
	// 2019/07/15 マルチタスク、一度決めたシフトを個人ごとにロックするボタンなどは設置可能 by zy END
	// 2019/07/31 20190527.04.タイムテーブル、ルームインジケータ、マルチタスク機能編集モードと読み込み専用モード対応必要 by zy BEGIN
	public Boolean notReadOnlyFlg{get;set;}
	// 2019/07/31 20190527.04.タイムテーブル、ルームインジケータ、マルチタスク機能編集モードと読み込み専用モード対応必要 by zy END
	// 2019/08/31 マルチタスクについて、今「その他」で絞りをかけた後画面更新（Command+R）をするとプロジェクト管理が消えました。絞り込みの保持 by zy BEGIN
	private map<String,String> userBookMap;
	// 2019/08/31 マルチタスクについて、今「その他」で絞りをかけた後画面更新（Command+R）をするとプロジェクト管理が消えました。絞り込みの保持 by zy END
	// 2019/09/15 キーワード検索機能ですがAND検索になっていますのでORの検索もできればいい by zy BEGIN
	public boolean isOrFlg{get;set;} // フィルタータイプ
	class CookieInfo{
		String viewMode; // モード
		boolean orFlg;	 // フィルタータイプ
		String userGroupId;
	}
	// 画面設定内容保存
	private void saveSettingCookie(){
		CookieInfo cook = new CookieInfo();
		cook.viewMode = viewMode;
		cook.orFlg = isOrFlg;
		// 2019/09/15 マルチタスクで自分専用のグループを作れるようにする(高) by zy BEGIN
		cook.userGroupId = CommUtils.nullToBlank(userGroupId);
		// 2019/09/15 マルチタスクで自分専用のグループを作れるようにする(高) by zy END
		pUserGroupId = userGroupId;
		UserConfigCompCtrl.saveCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.TASK,
				UserConfigCompCtrl.KREP_SUBTYPE.VIEWMODE.name(),JSON.serialize(cook),UserUtil.CurrentUser.id,'');
	}
	// 2019/09/15 キーワード検索機能ですがAND検索になっていますのでORの検索もできればいい by zy END
	// 2019/09/15 マルチタスクで自分専用のグループを作れるようにする(高) by zy BEGIN
	public List<Task> userTasks{get;set;}
	// userGroup
	public static String userGroupId{get;set;}
	// 前回選択グループID
	private String pUserGroupId;
	private static List<Task> getUserConfig(String configId){
		return getUserConfig(null,configId,null);
	}
	private static List<Task> getUserConfig(String userId,String configId,String spcd){
		List<UserConfig__c> userConfigs = StaffTaskHelp.getUserConfig(userId,configId,spcd);
		List<Task> tasks = new List<Task>();
		Set<String> userGroupSet = new Set<String>();
		for (UserConfig__c config : userConfigs)  {
			Task task = new Task();
			task.id = config.id;
			task.name = config.FunctionSubType__c.replace(StaffTaskHelp.USER_GROUP_SUB,'');
			task.groupName = config.ConfigInfo__c;
			tasks.add(task);
			userGroupSet.add(config.id);
		}
		if (!userGroupSet.contains(userGroupId)) userGroupId = '';
		return tasks;
	}
	// 2019/09/15 マルチタスクで自分専用のグループを作れるようにする(高) by zy END
	// 2019/09/22 不具合改修：マルチタスク機能、エラー『コレクションサイズ1,013が1,000の最大サイズを超えています。』の不具合改修 by zy BEGIN
	class UserSection{
		public List<User> userLst{get;set;}
		// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy BEGIN
		public LIst<HorInfo> eventLst{get;set;}
		// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy END
		public UserSection(){
			userLst = new List<User>();
			// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy BEGIN
			eventLst = new List<HorInfo>();
			// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy END
		}
		public boolean isFull(){
			// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy BEGIN
			return userLst.size() == 999 || eventLst.size() == 999;
			// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy END
		}
		public void add(User u){
			userLst.add(u);
		}
		// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy BEGIN
		public void add(String rowId,String rowName,String userId) {
			HorInfo info = new HorInfo();
			info.rowId = rowId;
			info.userId = userId;
			info.rowName = rowName;
			eventLst.add(info);
		}
		// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy END
	}
	// 2019/09/22 不具合改修：マルチタスク機能、エラー『コレクションサイズ1,013が1,000の最大サイズを超えています。』の不具合改修 by zy END
	// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy BEGIN
	public class HorInfo{
		public String rowId{get;set;}
		public String rowName{get;set;}
		public String rowTitle{get;set;}
		public String objId{get;set;}
		public String userId{get;set;}
		public String otherInfo{get;set;}
		public HorInfo(){
			rowName = '';
			objId = '';
			userId = '';
		}
	}
	public String tempJson{get;set;}
	class TempInfo{
		String name;
		Map<String,String> fieldMap;
		public TempInfo(){
			name = '';
			fieldMap = new Map<String,String>();
		}
		public TempInfo(String tempName,Dom.XMLNode xmlNode){
			name = CommUtils.nullToBlank(tempName);
			fieldMap = new Map<String,String>();
			if (xmlNode != null) {
				for (Dom.XMLNode tempNode : xmlNode.getChildElements()) {
					String fieldName = tempNode.getAttribute('name',null); 
					String fieldContent = CommUtils.nullToBlank(tempNode.getText()); 
					fieldMap.put(fieldName,fieldContent);
				}
			}
		}
	}
	public static TempInfo getTempNode(String temp,String spcd){
		TempInfo info = null;
		Dom.XmlNode taskConfigNode = getNodeByNodeName('TASKCONFIG',spcd);
		if (taskConfigNode != null) {
			for (Dom.XmlNode target : taskConfigNode.getChildElements()){
				String nodeName = target.getName();
				if (nodeName == 'TEMP') {
					String name = target.getAttribute('name',null);
					if (name == temp) {
						info = new TempInfo(name,target);
					}
				}
			}
		}
		return info;
	}
	// モード「ユーザー」フラグ
	// 2020/01/30 ルチタスクのタスクベースとユーザーベースの切り替え表示が逆だと思います by zy BEGIN
	public boolean isUserTaskFlag{get{return currentMode == MODE_PACE_TASK;}set;}
	// 2020/01/30 ルチタスクのタスクベースとユーザーベースの切り替え表示が逆だと思います by zy END
	// XML指定タスク、指定ユーザ取得
	private void queryTaskLst(List<TaskInfo> exitTask,List<Id> userIds){
		if (!userIds.isEmpty()) {
			userInfos = new List<UserSection>{new UserSection()};
			Date endDt = startDate.addDays(daysInMonth);
			// 指定期間内、ユーザーのタスク名取得
			set<String> evts = StaffTaskHelp.getExitEventGroup(startDate, endDt,userIds);
			// 同じタスク名集合
			Set<String> exitSet = new Set<String>();
			// XML設定タスクテンプレート
			for (TaskInfo info : exitTask) {
				// テンプレートタスク名
				String name = info.name;
				if (exitSet.contains(name)) continue;
				UserSection usc = userInfos[userInfos.size() - 1];
				if (usc.isFull()) {
					userInfos.add(new UserSection());
				}
				usc.add(name,name,userIds[0]);
				// その他の情報設定、カラー、時間
				usc.eventLst[usc.eventLst.size() - 1].otherInfo = JSON.serialize(info);
				exitSet.add(name);
			}
			// 指定タスク名の集合削除
			evts.removeAll(exitSet);
			// その他のタスク名集合削除
			evts.remove('');
			// 縦軸ユーザー作成
			if (!evts.isEMpty()) setUserSec(evts,userIds[0]);
			// 最後「その他」の行追加
			userInfos[userInfos.size() - 1].add('',OTHER_TASK_GROUP,userIds[0]);
		}
	}
	// 縦軸ユーザー作成
	public void setUserSec(Set<String> exitSet,String userId){
		for (String name : exitSet) {
			UserSection usc = userInfos[userInfos.size() - 1];
			if (usc.isFull()) {
				userInfos.add(new UserSection());
			}
			usc.add(name,name,userId);
		}
	}
	public String currentMode{get;set;}
	public static final String EVENT_ROW_FIELD = 'CreateType__c';
	public static final String OTHER_TASK_GROUP = 'その他';
	public static final String MODE_PACE_TASK = 'タスクベース';
	public static final String MODE_PACE_USER = 'ユーザーベース';
	public List<SelectOption> userModeOpts{get{
		// 2020/01/30 ルチタスクのタスクベースとユーザーベースの切り替え表示が逆だと思います by zy BEGIN
		// return new List<SelectOption>{new SelectOption(MODE_PACE_TASK, MODE_PACE_TASK),new SelectOption(MODE_PACE_USER, MODE_PACE_USER)};
		return new List<SelectOption>{new SelectOption(MODE_PACE_USER, MODE_PACE_USER),new SelectOption(MODE_PACE_TASK, MODE_PACE_TASK)};
		// 2020/01/30 ルチタスクのタスクベースとユーザーベースの切り替え表示が逆だと思います by zy END
	}set;}
	public void refreshToolMode(){
		refreshNewInfo();
	}
	// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy END
	// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
	// プロジェックトId前三位
	public static String projectPrefix = ProjectDetail__c.sObjectType.getDescribe().getKeyPrefix();
	public static void chgTaskUpdate(Event ev,String weekOpts){
		ProjectDetail__c pd = null;
		List<ProjectDetail__c> pds = new List<ProjectDetail__c>();
		if (CommUtils.isBlank(ev.description)){
			ProjectMain__c pm = StaffTaskhelp.getTaskProjectMain();
			pd = new ProjectDetail__c();
			pd.ProjectMain__c = pm.id;
			pd.calendarFlg__c = true;
			pd.CssStyle__c = ev.CssStyle__c;
			pd.CreateType__c = ev.CreateType__c;
			pd.UserRef__c = ev.OwnerId;
			pd.Title__c = ev.Subject;
			pd.GroupCode__c = ev.GroupCode__c;
			pd.StartDt__c = ev.StartDateTime;
			if (ev.EndDateTime__c != null) pd.EndDt__c = ev.EndDatetime__c;
			else pd.EndDt__c = ev.EndDatetime;
			// 繰り返し場合
	    	if (!CommUtils.isBlank(weekOpts)) {
		    	// 毎週
	    		// 曜日により、設定用日付を取得する
	    		// 開始日から、一週間の曜日日付を取得する
	    		Set<String> weekOptsSet = new Set<String>(weekOpts.split(','));
				DateTime startDt = ev.RecurrenceStartDateTime;
				Date endDt = ev.RecurrenceEndDateOnly;
				DateTime startDTime = DateTime.newInstance(startDt.year(), startDt.month(), startDt.day());
	    		DateTime endDTime = DateTime.newInstance(endDt.year(), endDt.month(), endDt.day());
				String RecurrenceActivityId = CommUtils.getGUID();
	    		while (startDTime <= endDTime) {
	    			String weekKey = startDTime.format('EEEE');
	    			if (weekOptsSet.contains(weekKey)) {
	    				ProjectDetail__c cloneDetail = pd.clone(false,false);
						cloneDetail.StartDt__c = DateTime.newInstance(startDTime.date(),ev.RecurrenceStartDateTime.time());
						cloneDetail.EndDt__c = cloneDetail.StartDt__c.addMinutes(ev.DurationInMinutes);
						cloneDetail.RecurrenceActivityId__c = RecurrenceActivityId;
	    				pds.add(cloneDetail);
	    			}
	    			startDTime = startDTime.addDays(1);
	    		}
	    	}

			if (!pds.isEmpty()) StafftaskHelp.insertProjectDetail(pds);
			else StafftaskHelp.insertProjectDetail(pd);
		} else {
			pd = new ProjectDetail__c(id = ev.description);
			List<ProjectDetail__c> exitDetails = StaffTaskHelp.getProjectDetails(new List<String>{pd.id});
			if (!exitDetails.isEmpty()) {
				if (ev.CreateType__c != null) pd.CreateType__c = ev.CreateType__c;
				if (ev.OwnerId != null) pd.UserRef__c = ev.OwnerId;
				if (!CommUtils.isBlank(ev.Subject)) pd.Title__c = ev.Subject;
				if (ev.StartDateTime != null) {
					pd.StartDt__c = ev.StartDateTime;
				}
				if (ev.EndDateTime__c != null) pd.EndDt__c = ev.EndDatetime__c;
				else if (ev.EndDatetime != null) pd.EndDt__c = ev.EndDatetime;
				if (pd.StartDt__c != null && pd.EndDt__c == null) {
					Integer durMinutes = CommUtils.nullToIntZero((exitDetails[0].EndDt__c.getTime() - exitDetails[0].startDt__c.getTime())/ (60 *1000));
					pd.EndDt__c = pd.StartDt__c.addMinutes(durMinutes);
				}
				StaffTaskHelp.updateProjectDetail(pd);
			}
		}
	}
	// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
}