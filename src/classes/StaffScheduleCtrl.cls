/**
* スタッフスケジュール：SFユーザー単位に、勤怠スケジュール定義、管理、照会
* 2015/07/14 INIT
* 2015/10/01 部署の選択リスト値設定不正の不具合修正
*            別名情報も画面に表示する
* 2015/10/29 部署の選択リストは表示するスタッフの部署のみ選択に表示→該当店舗に全てスタッフの部署を表示する
**/
public with sharing class StaffScheduleCtrl {
	// 画面レイアウト定数定義
	// 処理日付
	private Date processDay;
	// 処理年
	public Integer thisYear{get; set;}
	// 処理月
	public Integer thisMonth{get; set;}
	// 処理月・日数
	private Integer daysInMonth;
	// 表示の開始日
	private Date startDate;
	
	public StaffSchedule__c newStaffSchedule{get;set;}
	// 画面上に表示される予約一覧のヘッダー部
	public transient List<dispHeader> dispHeaders{get;set;}
	// 画面上に表示される予約一覧のデータ部
//	public List<dispRecord> dispRecords{get;set;}
private static Boolean isNightIncludeMode = true;	
	// Hidden項目・到着日
	public String startDays{get;set;}
//=======================	
	public transient List<User> userLst{get; private set;}	
	public transient Map<Id, dispRecord> dispRecordMap{get; private set;}
	public transient List<TimeManagement__c> timeLst{get; private set;}
	public TimeManagement__c timeManage{get;set;}
	public Datetime validateBeginTime;
	// 編集権限のみ参照の制御フラグ
//	public Boolean isOnlyShowCanEditData{get;set;}
	// 並び順項目格納用
	// 2018/05/22 4000ユーザ、シフト機能対応できる改善 by zy BEGIN
	public static String getSortFieldForUser(){return 'user';}
	public static String getSortFieldForDepart(){return 'dept';}
	// 2018/05/22 4000ユーザ、シフト機能対応できる改善 by zy END
	public String currSortField{get; private set;}
	public String currSortStatus{get; private set;}
	public String currSortStatusMark{get{return ( currSortStatus == 'asc'  ? '▲':'▼');}}
//=======================	
	private Set<Id> canEditRoleUserIds;
	
	// 年度選択リスト[今日から前１０～未来10年]
	public List<SelectOption> yearList {get; private set;}
    // Header色制御
    public transient Map<Integer, String> headerColorMap{get; private set;}
    // 詳細列のステータス制御変数定義
    public transient Map<Date, colStatus> colStatusMap{get; private set;}
	// 六輝表示がどうか判断用 TRUE:表示
	public boolean isShowQreqki{get{return CommConst.IsOrgRokuyoIsNoShow();}}
	// 2015/08/08 初期化追加
	public List<SelectOption> staffStatusLst{get;set;}
    // 休館情報を格納する
    public transient Map<Integer,String> restInfoMap{get; private set;}
    // スタッフのステータスとコメント区分キー
    public String getStaffStatusMsgKbn(){return 's_';}
    public String getStaffCommentMsgKbn(){return 'c_';}
    public String getStaffStopStatusMsgKbn(){return 't_';}
	// 室料登録用商品情報を維持する
	//private AccountMaster__c roomPriceInfo = null;
	// ラックレートレポート
	//public Id raceRateReportId{get; private set;}
	// Calendar情報格納用
	public CalendarExtend calExt{get; private set;}
	//public String userCd{get;set;}
	public String departCd{get;set;}
	// 開始日表示モード："1":毎月の１日から一月間データを表示する（Default値）/ "2":当日から一月間データを表示する
	private static final Boolean CONST_SHOW_START_TODAY = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomTypeStartDateMode__c) == '2' ? true :false;
	// 予約ポップの年月条件表示場所:"1":予約ポップ画面の右上に表示する (Default値) / "2":予約ポップ画面の左上に表示する
	public Boolean yearMonthRightPosition{get{ return (!CONST_SHOW_START_TODAY);}}
	public String staffMessageJsonStr{get;set;}
	public transient Map<String,Decimal> dayTimeWroksSumMap{get;set;}	// 日別勤怠時間集計値
	public Decimal allWorkDaysCount{get;set;}
	// 集計指定店舗コード情報可能
	public String summaryShopCode{get; private set;}
	// 2015/12/17 行動件名個別指定機能対応 BEIGN
	public String defEventTitle{get; private set;}
	// 2015/12/17 行動件名個別指定機能対応 END
	
	public StaffScheduleCtrl() {
		// 処理化処理
	   staffStatusLst = new List<Selectoption>();
	   // 2015/12/17 行動件名個別指定機能対応 BEIGN
	   staffStatusLst.add(new SelectOption(getStaffStatusMsgKbn(),''));
	   staffStatusLst.add(new SelectOption(getStaffCommentMsgKbn(),''));
	   staffStatusLst.add(new SelectOption(getStaffStopStatusMsgKbn(),''));
	   // 2015/12/17 行動件名個別指定機能対応 END
	   Schema.DescribeFieldResult fieldResult = StaffSchedule__c.StatusLst__c.getDescribe();
	   List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
	   for( Schema.PicklistEntry f : ple) {
			staffStatusLst.add(new SelectOption(getStaffStatusMsgKbn()+f.getValue(),f.getLabel()));
	   }
	   fieldResult = StaffSchedule__c.CommentLst__c.getDescribe();
	   ple = fieldResult.getPicklistValues();
	   for( Schema.PicklistEntry f : ple) {
			staffStatusLst.add(new SelectOption(getStaffCommentMsgKbn()+f.getValue(),f.getLabel()));
	   }
		
	   fieldResult = StaffSchedule__c.StopStatusLst__c.getDescribe();
	   ple = fieldResult.getPicklistValues();
	   for( Schema.PicklistEntry f : ple) {
			staffStatusLst.add(new SelectOption(getStaffStopStatusMsgKbn() + f.getValue(),f.getLabel()));
	   }
	   newStaffSchedule = new StaffSchedule__c();
	   currSortField = getSortFieldForUser();
	   currSortStatus = 'asc';
	   // 部屋の支店選択リスト設定する
	   setInitBranShopLst();
	   // 2015/10/29 部署選択リスト値設定ロジック変更 BEGIN
	   setDeaprtList();
	   // 2015/10/29 部署選択リスト値設定ロジック変更 END
	   // 部屋ステータス初期化
	   initRoomStatusList();
	   
	   // ロール処理
	   initEditRoleInfo();
	   
	   // Calendar情報初期化
	   calExt = new CalendarExtend(true);
	   // 2017/09/11 シフト画面に設定条件を自動記憶する BEGIN
	   // ページから引き渡す情報が存在するとき、関連情報を初期設定する
	   // branchShopNm
	   // departCd
	   // thisYear
	   // thisMonth
	   Map<String,String> parMap = ApexPages.currentPage().getParameters();
	   if (parMap.containsKey('pspcd')) branchShopNm = CommUtils.nullToBlank(parMap.get('pspcd'));
	   if (parMap.containsKey('pdpcd')) departCd = CommUtils.nullToBlank(parMap.get('pdpcd'));
	   if (parMap.containsKey('pyr')) thisYear = CommUtils.nullToIntZero(parMap.get('pyr'));
	   if (parMap.containsKey('pmo')) thisMonth = CommUtils.nullToIntZero(parMap.get('pmo'));
	   if (parMap.containsKey('pstkey')) currSortField = CommUtils.nullToBlank(parMap.get('pstkey'));//並び順キー
	   if (parMap.containsKey('pstval')) currSortStatus = CommUtils.nullToBlank(parMap.get('pstval'));//並び順値
	   // 2017/09/11 シフト画面に設定条件を自動記憶する END
	}

   	// -------------------------------------------
   	// 各店舗の表示する項目情報を取得、格納を行う
    // -------------------------------------------
	// 初期処理
	public void init(){
		// 初期情報を設定する
		doAction(null);
	}
	// 画面最新情報を表示する
	public void refreshNewInfo() {
		doAction(0);
	}
	// 2015/10/29 部署選択リスト値設定ロジック変更 BEGIN
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
		departCd = '';
	}
	// 2015/10/29 部署選択リスト値設定ロジック変更 END
	// 画面表示処理ロジック
	private void doAction(Integer month){

		// 変数の初期化
		dispHeaders = new List<dispHeader>();
		//newLead = new Lead__c();
		//newContact = new Contact();
		userCodeLst = new List<Selectoption>();
		// 2015/10/29 部署選択リスト値設定ロジック変更 BEGIN
		//departCodeLst = new List<Selectoption>();
		// 2015/10/29 部署選択リスト値設定ロジック変更 END
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
		daysInMonth = Date.daysInMonth(thisYear, thisMonth);
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
		// 処理年、月にて、選択できる年選択リストを再設定を行う
		yearList = new List<SelectOption>();
        // 日単位の部屋残り合計する
        //sumRoomsMap = new Map<Integer, Decimal>();
        // 販売部屋合計値
        //usedRoomsMap = new Map<Integer, Decimal>();
        // 故障部屋合計値
        //badRoomsMap = new Map<Integer, Decimal>();
		// 日単位のE/B残り合計値
		//sumEbRoomMap = new Map<Integer, Decimal>();
		// 日単位の全部部屋タイプの総部屋数
		//sumDayMaxRooms = 0;
		// Header曜日の色制御設定
		headerColorMap = new Map<Integer, String>();
		// 詳細列のステータス制御変数定義
		colStatusMap = new Map<Date, colStatus>();
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
		// 2017/05/26 シフトの開始日は変更できるように改善対応 Wgch END
		// データ表示開始日
		Date conStartDate = startDate;
		// データ表示終了日
		Date conEndDate = startDate.addDays(daysInMonth-1);
        // 営業情報を取得する
        queryRestHotelInfo(conStartDate, conEndDate);
        // 2016/07/22  ゆもとや様より改善要望(シフト表示開始日の変更)  wgch		BEGIN
        // XML設定情報を取得する
        //AppConfig appConfig = new AppConfig(branchShopNm, null);
        // 2016/07/22  ゆもとや様より改善要望(シフト表示開始日の変更)  wgch		END
        // 指定店舗コード情報を設定する
        summaryShopCode = appConfig.summaryShopCode;
        // 2015/12/17 行動件名個別指定機能対応 BEIGN
        defEventTitle = appConfig.eventTitle;
        // 2015/12/17 行動件名個別指定機能対応 END
		Integer oldTenYears = processDay.addYears(-10).year();
		Integer newTenYears = processDay.addYears(10).year();
		for (Integer year = oldTenYears; year <=newTenYears; year++ ) {
			//年
			yearList.add(new SelectOption(String.valueof(year),String.valueof(year)+ Label.CONST_035_0142));
		}
		// 日別勤怠時間合計値
		dayTimeWroksSumMap = new Map<String,Decimal>();
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
			
			dispHeaders.add(header);
			// 初期化を行う
			//sumRoomsMap.put(i, 0);
			//usedRoomsMap.put(i, 0);
			//badRoomsMap.put(i, 0);
			//sumEbRoomMap.put(i, 0);
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

		// 重複判別用マップ<部屋タイプID、dispRecord>
		dispRecordMap = new Map<Id, dispRecord>();
		/*
        Set<Id> canEditUserIds = new Set<Id>();
	    Set<Id> roleUserIds = CommRoleUtils.getRoleSubordinateUsers(UserInfo.getUserId());
System.debug(loggingLevel.INFO,'roleUserIds-----------------' +roleUserIds); 
	    canEditUserIds.addAll(roleUserIds);
	    canEditUserIds.add(UserInfo.getUserId());
        }*/
		timeManage = new TimeManagement__c (); 
//===============================================
		// 2018/05/22 4000ユーザ、シフト機能対応できる改善 by zy BEGIN
		//String sortFieldName = System.currentPageReference().getParameters().get('sortFieldName');
		sortFieldName = System.currentPageReference().getParameters().get('sortFieldName');
		integer limitUserInt = 200;
		// 2018/05/22 4000ユーザ、シフト機能対応できる改善 by zy END
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
        if (!CommUtils.isBlank(departCd)) userQuery += 'and Department = :departCd ';
        // 編集権限のみのユーザ情報を参照できる
		// 並び順[社員コード・氏名]
		if (currSortField == getSortFieldForUser()) {
	        userQuery += 'order by EmployeeCode__c '+String.escapeSingleQuotes(currSortStatus)+' Nulls Last , Name '+String.escapeSingleQuotes(currSortStatus)+' Nulls Last';
		} else {
			userQuery += 'order by Department '+String.escapeSingleQuotes(currSortStatus) + ' Nulls Last , EmployeeCode__c asc Nulls Last , Name asc Nulls Last';
		}
		// 関連ユーザー一覧情報を取得する
		// 2018/03/07 Security Check BEGIN
		//userLst = DataBase.query(userQuery);
		userLst = DataBase.query(String.escapeSingleQuotes(userQuery));
		// 2018/03/07 Security Check END
		Set<Id> userIds = new Set<Id>();
		// 2018/05/22 4000ユーザ、シフト機能対応できる改善 by zy BEGIN
		List<User> tempLst = new List<User>();
		integer curIndex = 0;
		allUserIds = '';
		// 2018/05/22 4000ユーザ、シフト機能対応できる改善 by zy END
        for(User s: userLst) {	
        	// 2018/05/22 4000ユーザ、シフト機能対応できる改善 by zy BEGIN
        	allUserIds += s.id + ',';
        	if (curIndex >= limitUserInt) continue;
        	curIndex ++;
        	tempLst.add(s);
        	// 2018/05/22 4000ユーザ、シフト機能対応できる改善 by zy END
        	userIds.add(s.Id);
        }
		// 2018/05/22 4000ユーザ、シフト機能対応できる改善 by zy BEGIN
		userLst = tempLst;
		allUserIds.removeEnd(',');
		// 2018/05/22 4000ユーザ、シフト機能対応できる改善 by zy END
        Map<String ,StaffSchedule__c> staffMap = new Map<String ,StaffSchedule__c>();
        Map<String, Integer> utMap = new Map<String, Integer>();

        // ユーザ出勤情報
		// 2019/11/26 シフトCPU limit修正 by zy BEGIN
        //Map<String,List<WorkTimeStstusInfo>> mapTime = getWorkTimeInfo(userIds, conStartDate, conEndDate);
		// 2019/11/26 シフトCPU limit修正 by zy END	
		// 2015/07/30 TODOは表示対象に変更があります BEGIN
		List<AggregateResult> etResult = [	select count(ID) cnt, OwnerId, ActivityDate from Event 
									    	where OwnerId =:userIds and ActivityDate >= :conStartDate and ActivityDate <= :conEndDate
									    	// 2018/06/25 マルチタスクのタスク登録機能改善繰り返し期間追加 by BEGIN
                                             // 定期のタスク、親定期タスク非表示
                                             and IsRecurrence = false
                                             // 2018/06/25 マルチタスクのタスク登録機能改善繰り返し期間追加 by END
									    	group by OwnerId, ActivityDate];
		for (AggregateResult avg : etResult) {
	    		Object activityDate = avg.get('ActivityDate');
	    		String key = (activityDate == null ? '' : ((Date)activityDate).format()) +'_'+ CommUtils.nullToBlank(avg.get('OwnerId'));
	    		utMap.put(key, CommUtils.nullToIntZero(avg.get('cnt')));
		}

        List<StaffSchedule__c> staffSchedules = [select StatusLst__c,TimeManagementRef__c,WorkDay__c,StaffUserRef__c,CommentLst__c,StopStatusLst__c,LastModifiedDate,SearchKey__c from StaffSchedule__c where StaffUserRef__c = :userIds 
        										and WorkDay__c >= :conStartDate and WorkDay__c <= :conEndDate];
        
       
       allWorkDaysCount = 0;
       // 2019/11/26 シフトCPU limit修正 by zy BEGIN
	   /*
		List<AggregateResult> daytimeLst = [select WorkDay__c workDay, sum(WorksT__c) sumWorkTimes
									        		from TimeManagement__c
													where (WorkDay__c != null And WorkDay__c >= :conStartDate and WorkDay__c <= :conEndDate ) and WorkerRef__c = :userIds
													group by WorkDay__c];
			
    	for (AggregateResult rs : daytimeLst) {
    		String key = ((Date)rs.get('workDay')).format();
    		dayTimeWroksSumMap.put(key,(Decimal)rs.get('sumWorkTimes'));
    		allWorkDaysCount += (Decimal)rs.get('sumWorkTimes');
    	}
    	Map<String,Decimal> workUserTimeMap = new Map<String,Decimal>();
    	 
		List<AggregateResult > usertimeLst = [select WorkerRef__c workId,  sum(WorksT__c) sumWorkTimes
									        		from TimeManagement__c
													where (WorkDay__c != null And WorkDay__c >= :conStartDate and WorkDay__c <= :conEndDate ) 
															and WorkerRef__c = :userIds
													group by WorkerRef__c];
		for (AggregateResult rs : usertimeLst) {
    		String key = (String)rs.get('workId');
    		workUserTimeMap.put(key,(Decimal)rs.get('sumWorkTimes'));
    	}
    	*/
	// 2019/11/26 シフトCPU limit修正 by zy END
        JSONGenerator gen = JSON.createGenerator(false);
    	gen.writeStartObject();
        for(StaffSchedule__c staff : staffSchedules){
        	String key = staff.StaffUserRef__c + '_' + staff.WorkDay__c.format() ;
        	staffMap.put(key,staff);
        	StaffSchedule schdule = new StaffSchedule(staff);
        	gen.writeFieldName(staff.SearchKey__c);
        	gen.writeObject(schdule);
        	//gen.writeObjectField(staff.SearchKey__c, staff);
        }
		gen.writeEndObject();
        staffMessageJsonStr = gen.getAsString();
		// 2015/10/01 BugFix BEGIN
		// 2015/10/29 部署選択リスト値設定ロジック変更 BEGIN
		//Set<String> departFilterSet = new Set<String>();
		// 2015/10/29 部署選択リスト値設定ロジック変更 END
		// 2017/09/05 指定権限制限機能追加 BEGIN
		// ログインユーザーのロール名
		String curUsrRoleNm = CommUtils.nullToBlank(userInf.u.UserRole.name);
		// 2017/09/05 指定権限制限機能追加 END
		// 2015/10/01 BugFix END
        for (User s: userLst) {
        	dispRecord nwRec = new dispRecord();
        	nwRec.userId = s.Id;
			// 2017/03/07 シフト->新規行動機能対応 BEGIN zyz
			nwRec.eventNm = s.Name;
			// 2017/03/07 シフト->新規行動機能対応 END zyz
			if(!CommUtils.isBlank(s.EmployeeCode__c))
				nwRec.userNm = s.EmployeeCode__c + '_' + s.Name;
			else
				nwRec.userNm = s.Name;
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
			// 2015/10/01 BugFix BEGIN
			// 2015/10/29 部署選択リスト値設定ロジック変更 BEGIN
			/*
			if(!CommUtils.isBlank(s.Department) && !departFilterSet.contains(s.Department)) {
				departCodeLst.add(new SelectOption(s.Department, s.Department));
				departFilterSet.add(s.Department);
			}*/
			// 2015/10/29 部署選択リスト値設定ロジック変更 END	
			// 2015/10/01 BugFix END
//System.debug(loggingLevel.INFO,'s.Id-----------------' +s.Id); 
            // 2017/09/05 指定権限制限機能追加 BEGIN
			//if(canEditRoleUserIds.isEmpty() || canEditRoleUserIds.contains(s.Id)){
			// 部下のタスク　または　同じロールかつ該当ロールは同士間に編集可能定義されている場合、タスク登録可能
			if(canEditRoleUserIds.isEmpty() || canEditRoleUserIds.contains(s.Id) || (usrRoleNm == curUsrRoleNm && roleConfig.isEditForSameRole(usrRoleNm))){
			// 2017/09/05 指定権限制限機能追加 END
				nwRec.roleClass = '';
			}else{
				nwRec.roleClass = 'notRoleCol';
			}	
			Decimal timeWorkSumByUser = 0;
	        for(Integer day = 1; day <= daysInMonth; day ++){
	        	Date hibiDt = startDate.addDays(day-1);
	        	String strDate = hibiDt.format();
				String key = s.Id+'_'+strDate;
				
				TimeMessage tm = new TimeMessage();
				/*
	        	if(mapTime.containsKey(key)){
	        		List<TimeManagement__c> tms1 = mapTime.get(key);
	        		tm = new TimeMessage(tms1,workTimeBtnInfo);
	        	}*/
			// 2019/11/26 シフトCPU limit修正 by zy BEGIN
				/*
	        	if(mapTime.containsKey(key)){
	        		List<WorkTimeStstusInfo> wkinfo = mapTime.get(key);
	        		if (wkinfo.size() > 1) {
	        			tm.currentNightStatusStyleStr = wkinfo[0].status;
	        			tm.currentStatusStyleStr = wkinfo[1].status; 
	        			tm.workDay =  wkinfo[1].workDay.format();
	        			tm.isShowCloneFlag =  wkinfo[1].isStraddle;
	        		} else {
	        			tm.currentStatusStyleStr = wkinfo[0].status;
	        			tm.workDay =  wkinfo[0].workDay.format();
	        			tm.isShowCloneFlag =  wkinfo[0].isStraddle;
	        		}
	        		tm.setKey =  wkinfo[0].workDay.format();
	        	}*/
			// 2019/11/26 シフトCPU limit修正 by zy END
	        	
	        	tm.staff = staffMap.get(key);
	        	if(tm.staff != null)
	        		tm.staffTimeLong = String.valueOf(tm.staff.LastModifiedDate.getTime());
//System.debug(loggingLevel.INFO,'staffMap-----------------' +staffMap);  
				tm.searchKey = genSearchKey(CommUtils.nullToBlank(s.Id) ,hibiDt);
        		tm.taskNum = CommUtils.nullToZero(utMap.get(strDate + '_' + s.Id)); 
        		tm.taskDt = strDate;
		        nwRec.timeList.add(tm);
        	}
        	// nwRec.timeWorkSumByUser = workUserTimeMap.get(s.id);
        	dispRecordMap.put(s.Id, nwRec);
        }
       // System.debug(loggingLevel.INFO,'dispRecordMap-----------------' +dispRecordMap);                                  

		// 20120924 ADD
		//this.setMessageItem(conStartDate);
         // 予約関連の集計情報の初期化
	  	//initXmlDefineInfo(branchShopNm);
	   	initXmlSummaryInfo(branchShopNm);
		
//System.debug(loggingLevel.INFO, '::::DOACTION::::' + summaryInfo);
//System.debug(loggingLevel.INFO, '::::month::::' + month);
	}
	
	// ************************************************
	// Headerに予約関連集計情報を作成する【BEGIN】
	// ************************************************
	// 予約指定項目により、集計を行う
	// RemoteActionから非同期で集計取得を行う
	@remoteAction
	public static map<String, String> summaryTitleInfo(String shopCode, String pConStartDate, String pConEndDate ,String jsonSummaryInfo) {
		// Query Where Var
		Integer leadCancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
		
		Date conStartDate = CommUtils.stringToDate(pConStartDate);
		Date conEndDate   = CommUtils.stringToDate(pConEndDate);
		
		LeadSummaryInfo locSummaryInfo = (LeadSummaryInfo)JSON.deserializeStrict(jsonSummaryInfo, LeadSummaryInfo.class);
//System.debug(loggingLevel.INFO, 'summaryInfo:::' + locSummaryInfo);

		// XMLに指定の項目により、関連予約情報を集計を行う
		Set<String> preFiedSet = new Set<String>{'id','name','StayPersons__c','EntryTime__c'}; 
		String queryField = getSummaryQueryHeader(preFiedSet, locSummaryInfo);
		String querySelect = 'Select ' + queryField + ' From Lead__c ';
		String queryWhere  = ' Where CancelBool__c != :leadCancelFlg  '+
								' And DAY_ONLY(convertTimezone(EntryTime__c)) >= :conStartDate ' +
						 		' And DAY_ONLY(convertTimezone(EntryTime__c)) <= :conEndDate ';
		if (!CommUtils.isBlank(shopCode)) queryWhere+= ' And refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c = :shopCode ';
		queryWhere += getSummaryQueryWhere(locSummaryInfo);
		String queryStr = querySelect + queryWhere + ' Order By EntryTime__c asc ';
		
		map<String, Integer> leadSummaryMap = new map<String, Integer>();
		map<String, Integer> peopleSummaryMap = new map<String, Integer>();
		for (Sobject lead : Database.query(queryStr)) {
			// XMLに指定の種別により、別々の集計を行う
			for (String field : locSummaryInfo.summaryKeyValMap.keySet()) {
				Object val = lead.get(field);
				Integer peoples = CommUtils.nullToIntZero(lead.get('StayPersons__c'));
				// 集計の項目から情報を取得して、集計を行う
				for(String eqVal : locSummaryInfo.summaryKeyValMap.get(field) ) {
					// 集計項目の場合
					if (eqVal == val) {
						String key = getSummaryKey(field, eqVal, (DateTime)lead.get('EntryTime__c'));
						if (!leadSummaryMap.containsKey(key)) leadSummaryMap.put(key, 1);
						else leadSummaryMap.put(key, leadSummaryMap.get(key) + 1);
						if (!peopleSummaryMap.containsKey(key)) peopleSummaryMap.put(key, peoples);
						else peopleSummaryMap.put(key, peopleSummaryMap.get(key) + peoples);
					}
				}
			}
		}
		map<String, String> returnJsonMsgMap = new map<String, String>();
		for (String key : leadSummaryMap.keySet()) {
			returnJsonMsgMap.put(key, leadSummaryMap.get(key) + '(' + peopleSummaryMap.get(key) + ')');
		}
		return returnJsonMsgMap;
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
	public class LeadMessageInfo{
		public Map<String,String> result;
		public Map<String,String> leadIds;
		public LeadMessageInfo(Map<String,String> peopleResult,Map<String,String> leadIdResult){
			result = peopleResult;
			leadIds = leadIdResult;
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
	// 集計用SQLのWhereキーを定義する
	private static String getSummaryQueryWhere (LeadSummaryInfo pSummaryInfo) {
			String queryWhere = '';
			for (integer i =0; i<pSummaryInfo.conditionKey.size();i++) {
				String key = pSummaryInfo.conditionKey[i];
				String val = pSummaryInfo.conditionVal[i];
				queryWhere += key + '=\'' + String.escapeSingleQuotes(val) + '\' OR ';
			}
			if (queryWhere.length() > 0) return ' And (' + queryWhere.removeEnd(' OR ') +' ) ';
			else return '';
	}
	// 集計情報JSON定義
	public String getJsonSummaryInfo() {
		return JSON.serialize(summaryInfo);
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
	
	private static Map<String,String> initXmlSummaryInfo(String branchShopNm){
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
				summaryInfo.addXmlNodeInfo(field, title);
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
				//System.debug(loggingLevel.INFO, 'changeWhereLst:1::' + changeWhereLst);
				//System.debug(loggingLevel.INFO, 'size:1::' + changeWhereLst.size());
				for(integer i = 0 ; i < changeWhereLst.size(); i++){
					/*
					if(i == (changeWhereLst.size() - 1)){
						sqlWhere += changeWhereLst[i];
					}else{
						sqlWhere += changeWhereLst[i] + ' AND ';
					}*/
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
		/*
		if (COMMENTBTN != null) {
			// 出勤ボタン
			Dom.XMLNode backColorNode = COMMENTBTN.getChildElement('BACKCOLOR', null);
			Dom.XMLNode fontColoeNode = COMMENTBTN.getChildElement('FONTCOLOR', null);
			if (backColorNode != null) {
				String backColorVal = CommUtils.nullToBlank(backColorNode.getText()).trim();
				if (!CommUtils.isBlank(backColorVal)) wkInfo.Memo_BackColor = backColorVal;

			}
			if (fontColoeNode != null) {
				String fontColoeVal = CommUtils.nullToBlank(fontColoeNode.getText()).trim();
				if (!CommUtils.isBlank(fontColoeVal)) wkInfo.Memo_FontColor = fontColoeVal;
			}
		}*/
		return wkInfo;
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
    // Tier/営業のHeader部情報を表示・非表示制御する
    public Boolean isShowBussinisHeader {get{
    	// 支店あり、全店舗を選べる場合、TIERのHeader情報を非表示する
    	return !(CommUtils.isBlank(branchShopNm) && branchShopLst.size() > 0);
    }}
    /*
    // Copy期間設定情報を格納する
    public CopySetupInfo copyInfo{get;set;}
    // Copy期間設定情報初期化する
	private void initCopyInfoClass() {
		copyInfo = new CopySetupInfo();
	}
    public void copyScheduleInfo() {

		// コピー元日付情報を格納する
		Date cloneOrgDate = Date.Parse(copyInfo.copyOrgDate);
		// ユーザーIDの配列
		List<String> userIds = copyInfo.copyUserIds.split(',');
		// 指定期間内勤怠情報をコピーする
		Date startDt = Date.Parse(copyInfo.startDate);
		Date endDt = Date.Parse(copyInfo.endDate);
		// Copy元のスタッフ情報を取得する
		List<StaffSchedule__c> cloneStaff = [select id, StatusLst__c,StaffUserRef__c,WorkDay__c,SearchKey__c from StaffSchedule__c where StaffUserRef__c in :userIds And WorkDay__c = :cloneOrgDate];
		// データ更新用配列
		List<StaffSchedule__c> upsertLst = new List<StaffSchedule__c>();
		// 指定期間の日付
		List<Date> toDates = new List<Date>(); 
    	// 毎週
    	if (copyInfo.isWeekRepeat) {

    		// 開始日から、一週間の曜日日付を取得する
    		List<String> weekOpts = copyInfo.weekOpts.split(',');
    		Set<String> weekOptsSet = new Set<String>(weekOpts);

    		DateTime startDTime = DateTime.newInstance(startDt.year(), startDt.month(), startDt.day());
    		DateTime endDTime = DateTime.newInstance(endDt.year(), endDt.month(), endDt.day());
			// 指定日、指定ユーザーリストから情報コピーを行う
    		while (startDTime <= endDTime) {
    			String weekKey = startDTime.format('EEEE');
    			if (weekOptsSet.contains(weekKey)) {
    				Date configDate = startDTime.date();
    				for (StaffSchedule__c staff : cloneStaff) {
    					StaffSchedule__c newItem = staff.clone(false,true);
    					newItem.WorkDay__c = configDate;
    					newItem.SearchKey__c = genSearchKey(staff.StaffUserRef__c, configDate);
    					upsertLst.add(newItem);
    				}
    				toDates.add(configDate);
    			}
    			startDTime = startDTime.addDays(1);
    		}	
    	}
		// DB操作を行う
  		Savepoint sp = Database.setSavepoint();
    	try {
    		// 指定期間の既存の情報をクリアする
    		if(!toDates.isEmpty()) delete [select id from StaffSchedule__c where StaffUserRef__c in :userIds And WorkDay__c in :toDates];
    		// 料金設定情報を反映する
			if(!upsertLst.isEmpty()) upsert upsertLst SearchKey__c;  
    	} catch (Exception e) {
  			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
  			Database.rollback(sp);
            //bookingCreateOK = false;
            return;
    	} 
    	// 処理結果を設定する 	
    	//bookingCreateOK = true;
    	// 最新表示用情報を取得する
    	doAction(0);
    }*/
    
    public class CopySetupInfo {
    	public CopySetupInfo() {isWeekRepeat=true;}
    	public String copyOrgDate{get;set;}		// 画面から指定のコピー元の日付情報を格納する
    	public String copyUserIds{get;set;}		// 画面から指定のコピー元のユーザーID情報を格納する
    	public Boolean isWeekRepeat{get;set;}
    	public String weekOpts{get;set;}		// 頻度は「毎週」の場合、繰り返しの曜日情報を格納「,」区きり
    	//public Boolean isDayOfMonth{get;set;}
    	//public Integer dayOfMonth{get;set;}      // 1-31-最終
    	//public Integer weekOfMonth{get;set;}		// 1,2,3,4,9
    	///public String dayOfWeek{get;set;}		// Monthday-Sunday
    	public String startDate{get;set;}
    	public String endDate{get;set;}
    }
    // Tier Detail Key
	private static String genSearchKey(Id userId, Date configDate) {
    	return (userId + '_' + configDate.format());
    }
    
    // 休館設定情報を格納する
    public HotelStatusInfo hotelInf{get; private set;}

	//通常
    private String CONST_NORMAL_HOTEL = Label.CONST_035_0145;
    private String CONST_NORMAL_COLOR = 'black';							// 默认颜色
	private String CONST_NORMAL_OTCOLOR = 'red';							// 非默认颜色
    public String getNoramlStatus() {return CONST_NORMAL_HOTEL;}
    // private static final String CONST_REST_HOTEL = '休館';
    // private static final String CONST_FULL_HOTEL = '貸切';
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
    	hotelInf = new HotelStatusInfo(getNoramlStatus());
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
    }

	// ボタン「来月」の処理
	public void toNext(){
		doAction(1);
	}

	// ボタン「先月」の処理
	public void toPrev(){
		doAction(-1);
	}
    // 年・月を選択する場合
    public void gotoYearMonth() {
    	// 選択する年月にて、今日までの月数を計算を行う
        //Date selDate = Date.newInstance(thisYear, thisMonth, Date.today().day());
    	//doAction(processDay.monthsBetween(selDate));
    	doAction(0);
    }
    // 2017/09/11 シフト画面に設定条件を自動記憶する BEGIN
    public void toThisMo() {
        thisYear = thisMonth = null;
        doAction(null);
    }
    // 2017/09/11 シフト画面に設定条件を自動記憶する END
    // ************************
    // 支店選択リスト
    // ************************
	private Map<String,ShopInformation__c> shopInfoMap;
    public List<SelectOption> branchShopLst{get; private set;}
    public List<SelectOption> userCodeLst{get; private set;}
    public List<SelectOption> departCodeLst{get; private set;}
    public UserUtil.UserShopInfo userInf;
    public String branchShopNm{get; set;}
    private void setInitBranShopLst() {
    	userInf = UserUtil.CurrentUserInfo;
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
    
	// 支店設定変更する場合
	public void changeBranchShop() {
		// 2015/10/29 部署選択リスト値設定ロジック変更 BEGIN
		setDeaprtList();
		// 2015/10/29 部署選択リスト値設定ロジック変更 END
		// 最新情報を取得する
		refreshNewInfo();
	}
    // ***************************
  	// 予約を保存する
  	// 設定情報にて、予約、予約インデックス情報を新規登録する
  	// ***************************
	@remoteAction
	public static List<StaffSchedule> saveTimeMessage(String messageJson, String workEventTitle) {
		List<Object> staffs =  (List<Object>)JSON.deserializeUntyped(messageJson);
		List<StaffSchedule__c> schedules = new List<StaffSchedule__c>();
		List<StaffSchedule> messageSchedules = new List<StaffSchedule>();
		String staffSearchKey = '';
		if (staffs.isEmpty()) {
			return messageSchedules;
		} else {
			// DB操作を行う
	  		Savepoint sp = Database.setSavepoint();
	    	try {
	    		List<StaffSchedule__c> editSchedules = new List<StaffSchedule__c>();
	    		List<StaffSchedule__c> deleteSchedules = new List<StaffSchedule__c>();
	    		Set<String> searchKeys = new Set<String>();
	    		Map<String,StaffSchedule> editStaffMap = new Map<String,StaffSchedule>();
				for(Object obj : staffs){
					Map<String,Object> staff = (Map<String,Object>)obj;
					if(staff != null){
						Date workDay = CommUtils.objectToDate(staff.get('staffdate'));
						staffSearchKey = genSearchKey(CommUtils.nullToBlank(staff.get('uid')), workDay);
						String uid = CommUtils.nullToBlank(staff.get('uid'));
						StaffSchedule__c schedule = new StaffSchedule__c(
													StatusLst__c = CommUtils.nullToBlank(staff.get('staffStatus')),
													StaffUserRef__c = uid ,
													StopStatusLst__c = CommUtils.nullToBlank(staff.get('stopStatus')),
													WorkDay__c = workDay,
													SearchKey__c = staffSearchKey,
													CommentLst__c =  CommUtils.nullToBlank(staff.get('staffComment'))
													) ;
						// 2015/12/17 行動件名個別指定機能対応 BEIGN
						schedule.EventTitle__c = workEventTitle;
						// 2015/12/17 行動件名個別指定機能対応 END
						String scheduleId = CommUtils.nullToBlank(staff.get('staffid'));
						
						if(!CommUtils.isBlank(scheduleId))
							schedule.Id = scheduleId;
						StaffSchedule innerSchedule = new StaffSchedule(schedule);
						innerSchedule.timeStmp = CommUtils.nullToBlank(staff.get('timeStmp')); 
						innerSchedule.errorMsg = CommUtils.nullToBlank(staff.get('status'));
						if(staff.get('status') == 'delete')
							deleteSchedules.add(schedule);
						searchKeys.add(schedule.SearchKey__c);
						
						editStaffMap.put(staffSearchKey,innerSchedule);
					}
				}
				//,LastModifiedBy.Name
				List<StaffSchedule__c> searchStaffs = [select StatusLst__c,TimeManagementRef__c,WorkDay__c,StopStatusLst__c,
																CommentLst__c,SearchKey__c,LastModifiedDate,LastModifiedBy.id,LastModifiedBy.Name
														 from StaffSchedule__c where SearchKey__c = :searchKeys for update];
				
        		for(StaffSchedule__c staff : searchStaffs){
        			if(editStaffMap.containsKey(staff.SearchKey__c)){
        				StaffSchedule insertStaff = editStaffMap.get(staff.SearchKey__c);
        				
//System.debug(loggingLevel.INFO,'insertStaff.staff.StaffUserRef__c-----------------' +UserInfo.getUserId() );  

//System.debug(loggingLevel.INFO,'staff.StaffUserRef__c-----------------' + staff.LastModifiedBy.id);  
        				if(insertStaff.timeStmp != String.valueOf(staff.LastModifiedDate.getTime()) && UserInfo.getUserId() !=  staff.LastModifiedBy.id){
        					//変更を保存できません
        					//編集していたレコードは、編集セッション中に【XXXXXX】によって変更されました。
        					//editStaffMap.get(staff.SearchKey__c).errorMsg = '変更を保存できません \n 編集していたレコードは、編集セッション中に【' + staff.LastModifiedBy.Name +'】によって変更されました。 ';
							editStaffMap.get(staff.SearchKey__c).errorMsg = Label.CONST_035_0146 + '\n '+ Label.CONST_035_0147.replace('XXXXXX',String.valueOf(staff.LastModifiedBy.Name)) ;
							//System.debug(loggingLevel.INFO,'error-----------------' + editStaffMap.get(staff.SearchKey__c).errorMsg);  
        				}
        			}
        		}
        		for(String searchKey : editStaffMap.keySet()){
        			StaffSchedule staff = editStaffMap.get(searchKey);
        			if(CommUtils.isBlank(staff.errorMsg))
        				editSchedules.add(editStaffMap.get(searchKey).staff);
        			else
        				messageSchedules.add(editStaffMap.get(searchKey));
        		}
        		 
				if(!editSchedules.isEmpty()){
					upsert editSchedules SearchKey__c;
					
					for(StaffSchedule__c staff : [select StatusLst__c,StopStatusLst__c,TimeManagementRef__c,WorkDay__c,StaffUserRef__c,
																CommentLst__c,SearchKey__c,LastModifiedDate 
														 from StaffSchedule__c where SearchKey__c = :searchKeys]){
						StaffSchedule innerSchedule = new StaffSchedule(staff);
						innerSchedule.timeStmp = CommUtils.nullToBlank(staff.LastModifiedDate.getTime()); 
						messageSchedules.add(innerSchedule);				 	
					}
				}
				if(!deleteSchedules.isEmpty()){
					delete deleteSchedules;
				}
	    	} catch (Exception e) {
	  			//ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
	  			StaffSchedule schedule = new StaffSchedule(new StaffSchedule__c(SearchKey__c = staffSearchKey));
	  			schedule.errorMsg = String.valueOf(e);
	  			if (schedule.errorMsg.contains('OP_WITH_INVALID_USER_TYPE_EXCEPTION')) schedule.errorMsg = Label.MSG_022_0003;
	  			messageSchedules.add(schedule);
	  			Database.rollback(sp);
	            return messageSchedules;
	    	} 
			return messageSchedules;
		}
	}
	@remoteAction
	public static RefreshResult refreshTimeMessage(String startDtStr,String endDtStr,String uids,boolean isOnlyHead) {
		List<StaffSchedule> schedules = new List<StaffSchedule>();
		List<Id> uidLst = uids.split(',');
		Map<Id, dispRecord> dispRecordMap = new Map<Id, dispRecord>();
		RefreshResult rr = new RefreshResult();
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
		if (!isOnlyHead) {
			// 2019/11/26 シフトCPU limit修正 by zy BEGIN
			// ユーザ出勤情報
	   		 Map<String,List<WorkTimeStstusInfo>> mapTime = getWorkTimeInfo(userIds, startDt, endDt);
			// 2019/11/26 シフトCPU limit修正 by zy END
			// 2015/07/30 TODOは表示対象に変更があります BEGIN
			List<AggregateResult> etResult = [	select count(ID) cnt, OwnerId, ActivityDate from Event 
										    	where OwnerId =:userIds and ActivityDate >= :startDt and ActivityDate <= :endDt
										    	// 2018/06/25 マルチタスクのタスク登録機能改善繰り返し期間追加 by BEGIN
	                                            // 定期のタスク、親定期タスク非表示
	                                            and IsRecurrence = false
	                                            // 2018/06/25 マルチタスクのタスク登録機能改善繰り返し期間追加 by END
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
					// 2019/11/26 シフトCPU limit修正 by zy BEGIN
					if(mapTime.containsKey(key)){
						List<WorkTimeStstusInfo> wkinfo = mapTime.get(key);
						if (wkinfo.size() > 1) {
							tm.currentNightStatusStyleStr = wkinfo[0].status;
							tm.currentStatusStyleStr = wkinfo[1].status;
							tm.workDay =  wkinfo[1].workDay.format();
							tm.isShowCloneFlag =  wkinfo[1].isStraddle;
						} else {
							tm.currentStatusStyleStr = wkinfo[0].status;
							tm.workDay =  wkinfo[0].workDay.format();
							tm.isShowCloneFlag =  wkinfo[0].isStraddle;
						}
						tm.setKey =  wkinfo[0].workDay.format();
					}
					// 2019/11/26 シフトCPU limit修正 by zy END
					tm.staff = staffMap.get(key);
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
		}
        rr.dayliTimeSumMap = workDayTimeMap;
        rr.allWorkDaysCount = allWorkDaysCount;
		return rr;
	}
	public class RefreshResult{
		public Map<Id, dispRecord> dispRecordMap;
		public Map<String,Decimal> dayliTimeSumMap;
		public Decimal allWorkDaysCount;
	}
	// ************************************************
	// 勤怠管理情報関連取得を行う
	// ************************************************
	private static Map<String,List<WorkTimeStstusInfo>> getWorkTimeInfo(Set<Id> userIds, Date startDate, Date endDate) {
		// KEY:ユーザーID_勤怠日 
		Map<String,List<WorkTimeStstusInfo>> mapTime = new Map<String,List<WorkTimeStstusInfo>>();
		// 同じ勤怠日は
		Map<String,TimeManagement__c> existTimesMap = new Map<String, TimeManagement__c>();
		
		map<String, Set<Date>> userWorkDays = new map<String, Set<Date>>();
		//
		//List<Date> workDaysLst = new List<Date>();
		//Set<Date> workDaysSet = new Set<Date>();
		Date locEndDate = Date.today();
		
		List<TimeManagement__c> preWkTimeLst = null;
		//map<Date> existDateMap = new map<Date>();
        if (isNightIncludeMode) {
        	Set<Id> preUserIds = new Set<Id>();
        	Set<Date> preWorkDays = new Set<Date>();
        	Set<DateTime> preWorkDatimes = new Set<DateTime>();
        	
        	// 開始日から前日の勤務している勤怠情報を探す[既に退勤情報は参照しない]
        	List<AggregateResult> gpPreWkTimeLst = [select WorkerRef__c userid, max(WorkDay__c) workday, max(CreatedDate) createDate,WorkerRef__c 
									        		from TimeManagement__c
													where (WorkDay__c != null And WorkDay__c <:startDate) 
															and WorkerRef__c = :userIds
													group by WorkerRef__c
        	];
        	// 関連の勤怠情報が存在する場合、該当勤怠情報を再取得を行う
        	// 該当勤怠情報の未退勤　OR　退勤日は今回表示の期間単位の場合、該当勤怠情報も画面に表現する
        	for (AggregateResult rs : gpPreWkTimeLst) {
        		preUserIds.add((ID)rs.get('userid'));
        		preWorkDays.add((Date)rs.get('workday'));
        		preWorkDatimes.add((DateTime)rs.get('createDate'));
        	}
        	
        	if (!preUserIds.isEmpty()) {		
        		// 前日の勤怠情報を再取得を行う
				preWkTimeLst = [select Id,
									WorkDay__c,
									WorkBeginTime__c,
									WorkEndTime__c,
									OutingTime__c,
									EnteringTime__c,
									OutingTime2__c,
									EnteringTime2__c,
									OutingTime3__c,
									EnteringTime3__c,
									WorksT__c,
									WorkerRef__c,
									(Select Id, EnteringTime__c, OutingTime__c From WorkTimeRelation__r  order by CreatedDate limit 1) 
								from TimeManagement__c 
								where WorkerRef__c = :preUserIds And WorkDay__c in :preWorkDays And CreatedDate in :preWorkDatimes
								Order by WorkerRef__c,WorkDay__c,CreatedDate];     
        		// 前日の勤怠情報をMapに格納する
        		// 未退勤　OR　退勤日は開始日範囲の場合、該当勤怠の勤怠ステータスを表示が必要です
				for (TimeManagement__c wk : preWkTimeLst) {
        			if (wk.WorkEndTime__c == null || wk.WorkEndTime__c.date() >= startDate) {

        				// 同じ勤怠日情報が存在する場合、最後作成された勤怠情報を格納する
        				String key = getSobjWorkTimeStatusKey(wk);
        				existTimesMap.put(key, wk);

        			}
        		}
        	}
        } // 前月分の勤怠情報を取得する
        // 今月分を勤怠情報を取得する
		List<TimeManagement__c> wkTimeLst = [select Id,
									WorkDay__c,
									WorkBeginTime__c,
									WorkEndTime__c,
									OutingTime__c,
									EnteringTime__c,
									OutingTime2__c,
									EnteringTime2__c,
									OutingTime3__c,
									EnteringTime3__c,
									WorksT__c,
									WorkerRef__c,
									(Select Id, EnteringTime__c, OutingTime__c From WorkTimeRelation__r  order by CreatedDate limit 1) 
							from TimeManagement__c where WorkerRef__c = :userIds And WorkDay__c >= :startDate and WorkDay__c <= :locEndDate
							order by WorkerRef__c,WorkDay__c,CreatedDate
							];       
		for (TimeManagement__c wk : wkTimeLst) {     

				// 同じ勤怠日情報が存在する場合、最新を自動作成された
				String key = getSobjWorkTimeStatusKey(wk);
				existTimesMap.put(key, wk);

		}
		
		//if (preWkTimeLst != null) {
			// 勤怠ステータス処理を行う
			//for (TimeManagement__c wk : preWkTimeLst) {
			for (TimeManagement__c wk : existTimesMap.values()) {

        		List<WorkTimeStstusInfo> wkStatusLst = setStatusByWorkInfo(wk, startDate, endDate, existTimesMap, isNightIncludeMode);
        		for (WorkTimeStstusInfo cloneWk : wkStatusLst) {
        			String key = cloneWk.getKey();
        			if (!mapTime.containsKey(key)) mapTime.put(key, new List<WorkTimeStstusInfo>());
        			mapTime.get(key).add(cloneWk);
        		}
        		
			}
		//}
		/*
		//for (TimeManagement__c wk : wkTimeLst) {
System.debug(loggingLevel.INFO, 'cloneWk:::' + wk);	
			List<WorkTimeStstusInfo> wkStatusLst = setStatusByWorkInfo(wk, startDate, endDate, existTimesMap, isNightIncludeMode);
System.debug(loggingLevel.INFO, 'wkStatusLst::' + wkStatusLst);
    		for (WorkTimeStstusInfo cloneWk : wkStatusLst) {

    			String key = cloneWk.getKey();
    			if (!mapTime.containsKey(key)) mapTime.put(key, new List<WorkTimeStstusInfo>());
    			mapTime.get(key).add(cloneWk);
    		}
		}*/
/*
System.debug(loggingLevel.INFO, 'startDate format:::' + startDate.format());
System.debug(loggingLevel.INFO, 'locEndDate format:::' + locEndDate.format());
		for (String key : mapTime.keySet()) {
			System.debug(loggingLevel.INFO, 'KEY::::['+key+']' + mapTime.get(key));
		}
*/		
		return mapTime;
	}
	private static String getSobjWorkTimeStatusKey(TimeManagement__c tm) {
		return tm.WorkerRef__c + '_' + tm.WorkDay__c.format();
	}
		
	private static String getObjWorkTimeStatusKey(WorkTimeStstusInfo tm) {
		return tm.workId + '_' + tm.cloneDate.format();
	}
	class WorkTimeStstusInfo {
		public Id workId{get;set;}
		public Date workDay{get;set;}
		public String status{get;set;}
		public Date cloneDate{get;set;}//連続出勤、出勤日跨りの場合、出勤ステータス続ける表示するため、CLONEの日付を格納する
		public Boolean isStraddle{get;set;}
		public Decimal workTime{get;set;}
		public String getKey() {
			return workId + '_' + cloneDate.format();
		}
	}
	// 指定の勤怠情報は指定期間内勤怠ステータスを管理する
	private static List<WorkTimeStstusInfo> setStatusByWorkInfo(	
																TimeManagement__c wkTime, 
																Date pStartDate, Date pEndDate, 
																Map<String,TimeManagement__c> existTimesMap,
																Boolean pIsNightIncludeMode) {
		// 勤怠日は表示反映前の日付の場合、退勤日がなかったの場合、当日まで同じステータスを設定する
		String workStatus = getWorkStatus(wkTime);
		// 当日に勤怠情報がない場合
		if (String.isEmpty(workStatus)) return new List<WorkTimeStstusInfo>();
		if (!pIsNightIncludeMode) {
			// 当日のステータスを設定した語、戻る
			WorkTimeStstusInfo info = new WorkTimeStstusInfo();
			info.status = workStatus;
			info.workDay = wkTime.WorkDay__c;
			info.cloneDate = wkTime.WorkDay__c;
			info.workTime = wkTime.WorksT__c;
			info.isStraddle = false;
			info.workId = wkTime.WorkerRef__c;
			return new List<WorkTimeStstusInfo>{info};
		}
		// 勤務の開始と退勤日間の日付に同じステータスを設定する
		Date locStartDt , locEndDt = null;
		String selfKey = getSobjWorkTimeStatusKey(wkTime);
		existTimesMap.remove(selfKey);
		// 表示範囲外の勤怠情報に対して、設定期間は勤怠表示開始日から、退勤日まで自動設定を行う「退勤日情報がない場合、システム日まで自動設定を行う」
		//if (wkTime.WorkDay__c < startDate) {
		if (wkTime.WorkBeginTime__c == null || wkTime.WorkBeginTime__c.date() < pStartDate) locStartDt = pStartDate;
		else locStartDt = wkTime.WorkBeginTime__c.date();
		if (wkTime.WorkEndTime__c == null) locEndDt = Date.today();
		else locEndDt = wkTime.WorkEndTime__c.date();
		// 
		
		// 指定期間の出勤ステータスを格納する
		List<WorkTimeStstusInfo> rsLst = new List<WorkTimeStstusInfo>();
		while (locStartDt <= locEndDt ) {

			
			WorkTimeStstusInfo info = new WorkTimeStstusInfo();
			info.status = workStatus;
			info.workDay = wkTime.WorkDay__c;
			info.cloneDate = locStartDt;
			info.isStraddle = (wkTime.WorkDay__c != locStartDt);
			info.workId = wkTime.WorkerRef__c;
			info.workTime = wkTime.WorksT__c;
			rsLst.add(info);
			
			String nextKey = wkTime.WorkerRef__c + '_' + locStartDt.format();
			if (existTimesMap.containsKey(nextKey)) break;
			
			locStartDt = locStartDt.adddays(1);
			

		}
		return rsLst;
	}
	// 指定の勤怠情報により、出勤ステータスを判断する
	private static String getWorkStatus(TimeManagement__c timeManagement) {
		// 指定の勤怠日の勤怠ステータスを判別する
        String currentStatus = '';
        String currentStatusStyleStr = '';
        if (timeManagement == null) return currentStatusStyleStr;
//System.debug(loggingLevel.INFO, 'timeManagement:::' + timeManagement); 
        TimeManagement__c wkTime = timeManagement;
        // 関連の休憩時間の取得
        List<RestTimeManagement__c> restTimeList = wkTime.WorkTimeRelation__r;
		// 該当日付の出勤情報が存在する場合
        if(wkTime.WorkBeginTime__c != null){
        	currentStatus = System.Label.MSG_1006;
        }
        // 退勤時間ある場合、退勤ステータスは優先で設定する
        if(wkTime.WorkEndTime__c != null){
            currentStatus = System.Label.MSG_1007;
        } else {
            // 関連休み情報が存在する場合
            if(!restTimeList.isEmpty()){
            	// 外出の時間が存在する場合
                if(restTimeList[0].OutingTime__c != null){
                    currentStatus = System.Label.MSG_1014;
                }
                // 入室の時間が存在する場合
                if(restTimeList[0].EnteringTime__c != null){
                    currentStatus = System.Label.MSG_1013;
                }
            }else{
            	// 勤怠管理に３回め休み時間のチェック
            	Integer i = 0;
            	if(wkTime.OutingTime3__c != null){
            		i = 3;
					currentStatus = System.Label.MSG_1014;
		    	}else if(wkTime.OutingTime2__c != null){
		    		i = 2;
					currentStatus = System.Label.MSG_1014;
		    	}else if(wkTime.OutingTime__c != null){
		    		i = 1;
					currentStatus = System.Label.MSG_1014;
		    	}
		    	if(wkTime.EnteringTime3__c != null && i == 3){
					currentStatus = System.Label.MSG_1013;
		    	}else if(wkTime.EnteringTime2__c != null && i == 2){
					currentStatus = System.Label.MSG_1013;
		    	}else if(wkTime.EnteringTime__c != null && i == 1){
					currentStatus = System.Label.MSG_1013;
		    	}
            }
        }
        
        // 出勤の場合
		if (currentStatus == System.Label.MSG_1006) currentStatusStyleStr = 'TimeStatus_Work';
        // 休憩の場合
		else if (currentStatus == System.Label.MSG_1014) currentStatusStyleStr = 'TimeStatus_Out';
        // 入室の場合
        else if (currentStatus == System.Label.MSG_1013) currentStatusStyleStr = 'TimeStatus_Back';
        // 退勤の場合
		else if (currentStatus == System.Label.MSG_1007) currentStatusStyleStr = 'TimeStatus_End';
      
		return currentStatusStyleStr;
	}

  	// 曜日の取得処理
  	private String getYobi(Date vdDate){
  		
		return CommUtils.getYobi(vdDate);
	}

  	// インナークラス・ヘッダー
  	public class dispHeader{
  		public String label{get;set;}
  		public String name{get;set;}
  		public Integer days{get;set;}
  		public String holidayLab{get;set;}		// 祝い日Label
  		public dispHeader(Integer p0, String p1, String p2){
  			label = p1;
  			name = p2;
  			days = p0;
  			isCloseOrFutureDay = false;
  		}
  		public Boolean isCloseOrFutureDay{get;set;}	// 該当日の未来日　OR　休館日
  	}
	
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
  		public String userPlusInf{get;set;}
  		public List<TimeMessage> timeList{get;set;}
  		public String roleClass{get;set;}
  		public Decimal dateTimeSum{get;set;}
  		public Decimal timeWorkSumByUser{get;set;}
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
	// 2018/05/22 4000ユーザ、シフト機能対応できる改善 by zy BEGIN
	// インナークラス・データ
	public List<FastUserInfo> fastUserLst;
	public class FastUserInfo{
		public String userId{get;set;}
		public String userNm{get;set;}
		public String titleNm{get;set;}
		public String depart{get;set;}
		public String roleClass{get;set;}
		public String staffTimeLong{get;set;}
		public String userPlusInf{get;set;}
  		public Decimal timeWorkSumByUser{get;set;}
  		// 内容を設定すると、ログインユーザーは該当ユーザーの既存情報が参照のみ
        public String isViewFlg{get;set;}
		public List<TimeMessage> dayLst{get;set;}
		public FastUserInfo(User u){
			userId = u.id;
			userNm = u.name;
			userPlusInf = '';
			isViewFlg = '';
			depart = CommUtils.nullToBlank(u.Department);
			if (CommUtils.isBlank(u.EmployeeCode__c )) titleNm = u.Name;
			else titleNm = u.EmployeeCode__c + '_' + u.Name;
			dayLst = new List<TimeMessage>();
		}
	}
	public String sortFieldName{get;set;}
	// 
	private static List<FastUserInfo> initQuickMap(List<User> userLst,Map<String,List<WorkTimeStstusInfo>> mapTime,Map<String,StaffSchedule__c> staffMap,
								AppConfig appConfig,RoleConfig roleConfig,String curUsrRoleNm,Map<String, Integer> utMap,
								Map<String,Decimal> workUserTimeMap,Set<Id> canEditRoleUserIds,
								Date startDate,Integer daysInMonth){
		List<FastUserInfo> fastUsers = new List<FastUserInfo>();
		for (User s: userLst) {
        	FastUserInfo fui = new FastUserInfo(s);
			// 2015/10/01 EDIT BEGIN
			// 氏名列に補足表示情報が設定する
			fui.userPlusInf = appConfig.getPlusInfFromUser(s);
			// 2015/10/01 EDIT END
			// 2017/09/05 権限チェック追加対応　BEGIN
			String usrName = CommUtils.nullToBlank(s.Username);
			String usrRoleNm = CommUtils.nullToBlank(s.UserRole.name);
			if (s.Id != UserInfo.getUserId()) {
				Set<String> managerSet = roleConfig.getUserViewDefSet(usrName);
				if (managerSet != null && !managerSet.contains(curUsrRoleNm)) fui.isViewFlg = '1';
			}
			// 2017/09/05 権限チェック追加対応　END
			//userCodeLst.add(new SelectOption(fui.userId, fui.userNm));
            // 2017/09/05 指定権限制限機能追加 BEGIN
			//if(canEditRoleUserIds.isEmpty() || canEditRoleUserIds.contains(s.Id)){
			// 部下のタスク　または　同じロールかつ該当ロールは同士間に編集可能定義されている場合、タスク登録可能
			if(canEditRoleUserIds.isEmpty() || canEditRoleUserIds.contains(s.Id) || (usrRoleNm == curUsrRoleNm && roleConfig.isEditForSameRole(usrRoleNm))){
			// 2017/09/05 指定権限制限機能追加 END
				fui.roleClass = '';
			}else{
				fui.roleClass = 'notRoleCol';
			}	
			Decimal timeWorkSumByUser = 0;
	        for(Integer day = 1; day <= daysInMonth; day ++){
	        	Date hibiDt = startDate.addDays(day-1);
	        	String strDate = hibiDt.format();
				String key = s.Id+'_'+strDate;
				
				TimeMessage tm = new TimeMessage();
				if(mapTime.containsKey(key)){
	        		List<WorkTimeStstusInfo> wkinfo = mapTime.get(key);
	        		if (wkinfo.size() > 1) {
	        			tm.currentNightStatusStyleStr = wkinfo[0].status;
	        			tm.currentStatusStyleStr = wkinfo[1].status;
	        			tm.workDay =  wkinfo[1].workDay.format();
	        			tm.isShowCloneFlag =  wkinfo[1].isStraddle;
	        		} else {
	        			tm.currentStatusStyleStr = wkinfo[0].status;
	        			tm.workDay =  wkinfo[0].workDay.format();
	        			tm.isShowCloneFlag =  wkinfo[0].isStraddle;
	        		}
	        		tm.setKey =  wkinfo[0].workDay.format();
	        	}
	        	tm.staff = staffMap.get(key);
	        	if(tm.staff != null)
	        		tm.staffTimeLong = String.valueOf(tm.staff.LastModifiedDate.getTime());
//System.debug(loggingLevel.INFO,'staffMap-----------------' +staffMap);  
				tm.searchKey = genSearchKey(CommUtils.nullToBlank(s.Id) ,hibiDt);
        		tm.taskNum = CommUtils.nullToZero(utMap.get(strDate + '_' + s.Id)); 
        		tm.taskDt = strDate;
        		tm.workDay = strDate;
		        fui.dayLst.add(tm);
        	}
        	fui.timeWorkSumByUser = workUserTimeMap.get(s.id);
        	fastUsers.add(fui);
        }
        return fastUsers;
	}
	@remoteaction
	public static List<FastUserInfo> getExitAllUser(String userIds,String sortFieldName,String branchShopNm,String departCd,String startDtStr,String endDtStr) {
		List<FastUserInfo> req = new List<FastUserInfo>();
		
		if (!CommUtils.isBlank(userIds)) {
			List<Id> userLst = userIds.split(',');
			UserUtil.UserShopInfo userInf = UserUtil.CurrentUserInfo;
			String currSortField = getSortFieldForUser();
			String currSortStatus = '';
			if (!CommUtils.isBlank(sortFieldName)) {
				if (currSortField != sortFieldName) {
					currSortField = sortFieldName;
					currSortStatus = 'asc';
				} else {
					currSortStatus = (currSortStatus == 'asc' ? 'desc' : 'asc');
				}
			}
			 // XML設定情報を取得する
        	AppConfig appConfig = new AppConfig(branchShopNm, null);
			// 指定API名により、関連の予約情報を取得する
			String userQuery = 'select ' + appConfig.queryQueryUserField() + ' from User where StaffScheduleNoshow__c != true And IsActive = true ';
	        if (!CommUtils.isBlank(branchShopNm)) {
	            userQuery += 'and ( DefaultShopCode__c = :branchShopNm or ShopCode__c = :branchShopNm ) ';
	        }else if (userInf.isShopCodePlex) {
	            Set<String> shopSt = userInf.shopSt;
	            userQuery += 'and ( DefaultShopCode__c = :shopSt or ShopCode__c = :shopSt ) ';
	        }
	        if (!CommUtils.isBlank(departCd)) userQuery += 'and Department = :departCd ';
	        userQuery += ' and id = :userLst ';
	        // 編集権限のみのユーザ情報を参照できる
			// 並び順[社員コード・氏名]
			if (currSortField == getSortFieldForUser()) {
		        userQuery += 'order by EmployeeCode__c '+String.escapeSingleQuotes(currSortStatus)+' Nulls Last , Name '+String.escapeSingleQuotes(currSortStatus)+' Nulls Last';
			} else {
				userQuery += 'order by Department '+String.escapeSingleQuotes(currSortStatus) + ' Nulls Last , EmployeeCode__c asc Nulls Last , Name asc Nulls Last';
			}
			// 2018/03/07 Security Check BEGIN
	        List<User> userRes = DataBase.query(String.escapeSingleQuotes(userQuery));
	        // 2018/03/07 Security Check END
			// データ表示開始日
			Date conStartDate = CommUtils.stringToDate(startDtStr);
			// データ表示終了日
			Date conEndDate = CommUtils.stringToDate(endDtStr);
			// 処理月・日数の設定
			// 処理年の設定
			integer thisYear = conStartDate.year();
			// 処理月の設定
			integer thisMonth = conStartDate.month();
			integer daysInMonth = Date.daysInMonth(thisYear, thisMonth);
			Map<String ,StaffSchedule__c> staffMap = new Map<String ,StaffSchedule__c>();
	        Map<String, Integer> utMap = new Map<String, Integer>();
			Decimal allWorkDaysCount = 0;
			Map<String,Decimal> dayTimeWroksSumMap = new Map<String,Decimal>();
	        // ユーザ出勤情報
	        Map<String,List<WorkTimeStstusInfo>> mapTime = getWorkTimeInfo(new Set<Id>(userLst), conStartDate, conEndDate);
	   
			// 2015/07/30 TODOは表示対象に変更があります BEGIN
			List<AggregateResult> etResult = [	select count(ID) cnt, OwnerId, ActivityDate from Event 
										    	where OwnerId =:userLst and ActivityDate >= :conStartDate and ActivityDate <= :conEndDate
										    	// 2018/06/25 マルチタスクのタスク登録機能改善繰り返し期間追加 by BEGIN
	                                            // 定期のタスク、親定期タスク非表示
	                                            and IsRecurrence = false
	                                            // 2018/06/25 マルチタスクのタスク登録機能改善繰り返し期間追加 by END
										    	group by OwnerId, ActivityDate];
			for (AggregateResult avg : etResult) {
	    		Object activityDate = avg.get('ActivityDate');
	    		String key = (activityDate == null ? '' : ((Date)activityDate).format()) +'_'+ CommUtils.nullToBlank(avg.get('OwnerId'));
	    		utMap.put(key, CommUtils.nullToIntZero(avg.get('cnt')));
			}
	
	        List<StaffSchedule__c> staffSchedules = [select StatusLst__c,TimeManagementRef__c,WorkDay__c,StaffUserRef__c,CommentLst__c,StopStatusLst__c,LastModifiedDate,SearchKey__c from StaffSchedule__c where StaffUserRef__c = :userLst 
	        										and WorkDay__c >= :conStartDate and WorkDay__c <= :conEndDate];
	        
	        for (StaffSchedule__c staff : staffSchedules) {
	       		String key = staff.StaffUserRef__c + '_' + staff.WorkDay__c.format() ;
	        	staffMap.put(key,staff);
	        }
	        allWorkDaysCount = 0;
			List<AggregateResult> daytimeLst = [select WorkDay__c workDay, sum(WorksT__c) sumWorkTimes
										        		from TimeManagement__c
														where (WorkDay__c != null And WorkDay__c >= :conStartDate and WorkDay__c <= :conEndDate ) and WorkerRef__c = :userLst
														group by WorkDay__c];
				
	    	for (AggregateResult rs : daytimeLst) {
	    		String key = ((Date)rs.get('workDay')).format();
	    		dayTimeWroksSumMap.put(key,(Decimal)rs.get('sumWorkTimes'));
	    		allWorkDaysCount += (Decimal)rs.get('sumWorkTimes');
	    	}
	    	
	    	Map<String,Decimal> workUserTimeMap = new Map<String,Decimal>();
	    	 
			List<AggregateResult > usertimeLst = [select WorkerRef__c workId,  sum(WorksT__c) sumWorkTimes
										        		from TimeManagement__c
														where (WorkDay__c != null And WorkDay__c >= :conStartDate and WorkDay__c <= :conEndDate ) 
																and WorkerRef__c = :userLst
														group by WorkerRef__c];
			for (AggregateResult rs : usertimeLst) {
	    		String key = (String)rs.get('workId');
	    		workUserTimeMap.put(key,(Decimal)rs.get('sumWorkTimes'));
	    	}
			// ログインユーザーのロール名
			String curUsrRoleNm = CommUtils.nullToBlank(userInf.u.UserRole.name);
			RoleConfig roleConfig = new RoleConfig(branchShopNm, null);
			Set<Id> canEditRoleUserIds = new Set<Id>();
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
			req = initQuickMap(userRes,mapTime,staffMap,appConfig,roleConfig,curUsrRoleNm,utMap,workUserTimeMap,canEditRoleUserIds,conStartDate,daysInMonth);
		}
		return req;
	}
	public String allUserIds{get;set;}
	// 2018/05/22 4000ユーザ、シフト機能対応できる改善 by zy END
}