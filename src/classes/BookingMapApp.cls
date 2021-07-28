global with sharing class BookingMapApp  extends CommBaseCtrl {
	private static date checkinday;																		/* Current checkin day */
	private List<Lead__c> BookingData;																	/* Real time Booking data */
	private List<Room__c> RoomData;																		/* Room Data*/
	public String roomMessageJson{get;set;}
	public String leadJson{get;set;}
	public BookingTimeTable__c selectDate{get; private set;}
	public Id leadId{get;private set;}
	//　部屋に関連付の予約情報を取得する
    private final String QueryLeadHeader = 'Select id,Name,Mans__c,Femails__c,ChildC__c,ChildD__c,ChildE__c,ChildFA__c,ChildF__c,Childs__c,StayPersons__c,RecordType.Name, Rroom__c,Field276__c, Relcontact__r.Name, Relcontact__r.Katakana__c, Relcontact__r.KanaName1__c ,Relcontact__r.KanaName2__c ,ReservedStatus__c, LeadIndexSubId__c, LeadIndexRef__c, LeadIndexRef__r.DepartureDate__c, EntryTime__c, Field4__c, Departure__c, Field3__c, Field310__c, Field298__c, Field299__c,DayNightCal__c From Lead__c ';
	// 部屋表示順フラグ定数定義
    private static final String ROOM_SORT_NAME_DIV = '1';
    //private static final String ROOM_SORT_DISPLAY_DIV = '2';
    private static final String ROOM_SORT_DIV = CommDefine__c.getOrgDefaults().RoomSortDiv__c == null ? ROOM_SORT_NAME_DIV : CommDefine__c.getOrgDefaults().RoomSortDiv__c;
	// 2013/05/23 部屋表示サイズ調査対応
	private static final Integer ROOM_INFO_MAX_SIZE = CommDefine__c.getOrgDefaults().RoomIndicatorInfoMaxLength__c == null ? 4 : (CommDefine__c.getOrgDefaults().RoomIndicatorInfoMaxLength__c.intValue() < 4 ? 4 : CommDefine__c.getOrgDefaults().RoomIndicatorInfoMaxLength__c.intValue());
	// 2013/08/11 予約名
	private static final String LEAD_NAME_PREFIX = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomDelegatePrefix__c);	
	// 2013/08/14 DEF_CHECKOT_TIME設定
	private static final String DEF_CHECKOT_TIME = CommConst.DEF_CHECKOT_TIME;
	/**
	* ルーム情報検索する
	**/
	// 2019/02/15 マップ機能無効ソース処理　by zy BEGIN
	//private static final String QueryHeader = 'Select  Name ,Id ,Area__c ,Basu__c ,CapacityHaku__c ,Capacity__c ,Field10__c ,Field11__c ,Field12__c ,Field13__c ,Field14__c ,Field15__c ,Field16__c ,Field17__c ,Field18__c ,Field19__c ,Field1__c ,Field4__c ,Field5__c ,Field6__c ,Field7__c ,Field8__c ,Field9__c ,Height__c ,ID__c ,LAN__c ,Lat__c ,Left__c ,Lng__c ,Rank_2__c ,Rank_3__c ,Rank_4__c ,Rank_5__c ,Rank__c ,Rnumber__c ,RoomName__c ,Seq__c ,Tier123__c ,Top__c ,UseOfRoom__c ,Width__c ,centreLat__c ,centreLng__c ,furo__c ,heyadashiryou__c ,heyadashiryouryou__c ,kakuzuke__c ,priority__c ,roomimage__c ,rotenburo__c ,TypeRoomRef__c ,Nosmoking__c ,ParentRoomRef__c ,Floor__c ,TypeRoomRef__r.Name From  Room__c ';
	private static final String QueryHeader = 'Select  Name ,Id ,Area__c ,Basu__c ,CapacityHaku__c ,Capacity__c ,Field10__c ,Field11__c ,Field12__c ,Field13__c ,Field14__c ,Field15__c ,Field16__c ,Field17__c ,Field18__c ,Field19__c ,Field1__c ,Field4__c ,Field5__c ,Field6__c ,Field7__c ,Field8__c ,Field9__c ,Height__c ,ID__c ,LAN__c ,Lat__c ,Left__c ,Lng__c ,Rank_2__c ,Rank_3__c ,Rank_4__c ,Rank_5__c ,Rank__c ,Rnumber__c ,RoomName__c ,Seq__c  ,UseOfRoom__c ,Width__c ,centreLat__c ,centreLng__c ,furo__c ,kakuzuke__c ,priority__c  ,rotenburo__c ,TypeRoomRef__c ,Nosmoking__c ,ParentRoomRef__c ,Floor__c ,TypeRoomRef__r.Name From  Room__c ';
	// 2019/02/15 マップ機能無効ソース処理　by zy END
	//2013/07/22 部屋約名標識
	public static Integer ROOM_INFO_NAME_TYPE_GUESTNAME	{get{return 1;}}
	public static Integer ROOM_INFO_NAME_TYPE_LEADNAME	{get{return 2;}}
	// 祝日情報を取得する[Calendar情報格納用]
	private CalendarExtend calExt;
	// 画面入力用
	public Lead__c newLead{get;set;}
	public Contact newContact{get;set;}
	// お客様名
	public String contactName{get;set;}
	// Hidden項目・到着日
	public String startDays{get;set;}
	// DB更新処理標識フラグ
	public Boolean bookingCreateOK{get;set;}
	// E/B機能存在するかどうか標識用
    public Boolean isHaveEbInfo{get; private set;}
    public Boolean isHaveSeminar{get; private set;}
    // 泊数
	public Integer staysNums{get;set;}
	// 会計支払方法
	public List<Selectoption> paymentTypeLst{get; private set;}
	// 変更情報格納用クラス
	public PopupWinInfo leadInfo{get; set;}
	// 詳細画面情報維持
	public RoomInfo RoomDetail{get;set;}
	public String strLeadId{get;set;}
	public String groupLeadIds{get;set;}
	public boolean isGroupFlg{get;set;}
	// 処理日
	// 2019/02/15 マップ機能無効ソース処理　by zy BEGIN
	/*
	private Date processDate = null;
	// 場所別部屋情報
	public List<AreaRoomInfo> areaInfLst {get; private set;}
	*/
	// 2019/02/15 マップ機能無効ソース処理　by zy END
	// Floor最大部屋数
	public Integer maxRooms{get; private set;}
	
	// 本物の予約ID判別用キー
	public static final String leadPreFixKey{get; private set;}
	/**
    * 当日のチェックインレイアウト・チェックアウトレイアウト切替画面制御
    * TRUEの場合、当日のチェックイン情報を表示する(画面の指定日は)
    * FALSEの場合、当日のチェックアウト情報を表示する
    */
    public Boolean isShowToday{get;set;}            // 当日
    public static String topLeadIdsHid{get;set;}    //
    /************************************
    * 各タイプルームの合計値統計
    *************************************/
    // 2019/02/15 マップ機能無効ソース処理　by zy BEGIN
    /*
    public Integer iEmptyStatusSum{get;set;}
    public Integer isAssignedStatusSum{get;set;}
    public Integer isStayStatusSum{get;set;}
    public Integer checkOutDayStatusSum{get;set;}
    public Integer checkOutStatusSum{get;set;}
    public Integer isBadStatusSum{get;set;}
    public Integer isNoCleanStatusSum{get;set;}
    */
    // 2019/02/15 マップ機能無効ソース処理　by zy END
    /************************************
    * 各タイプルームのSTYLE　COLOR
    *************************************/
	// 空室
	private final String strEmptyStatusColor = 'isEmptyStatus';
	// 割当済
	private final String strAssignedStatusColor = 'isAssignedStatus';
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
    public Map<Id,Integer> roomLeadsCount;
    public Set<String> topLeadIdSet{get;set;}
    // 2014/02/10 部屋単位の時刻リスト情報を格納する
    public transient Map<Id, String> roomTimesMap{get; private set;}
    // 2014/06/17 部屋にお客様名・予約名表示制御フラグ情報格納
 	public String roomNameType{get;set;}
 	// 最新連絡事項情報取得
	public MessageItem__c messageObj{get; set;}
	public boolean isShowGroupConfirm{get; private set;}
	public boolean isShowGroupClConfirm{get; private set;}
	public String refreshMode{get;set;}
	public string titleInfoLstJson{get;set;}
	public String strToday{get{
		DateTime nowDt = System.now();
		//nowDt = DateTime.newInstance(2014,12,23);
		Date dt = nowDt.date();
		// 曜日
		String yobi = CommUtils.getYobi(dt);
		String holidayLab = '';
		// 2014/11/29 祝日情報を初期化
		calExt = new CalendarExtend(true);
		if (calExt.holidayMap.containsKey(dt)) {
			holidayLab = ' ' + calExt.holidayMap.get(dt);
		}
		return (nowDt.format('yyyy-MM-dd') + ' (' + yobi +') ' + nowDt.format('HH:mm') + holidayLab);
	}}
	// 2015/12/17 FIX END
	// RoomChange　No
	public String strNewRoomNo{get;set;}
	public String strNewRoomId{get;set;}
	private Set<Id> showRoomSet;
	public BookingMapApp(){
		//leadId = 'a0P1000000Mz8ai';
		//stdController.getId();
		refreshMode = 'main';
		userInf = UserUtil.CurrentUserInfo;
		//stdController.getId() 	
																		/* Get current BookingPlus record */
		// 2019/02/15 マップ機能無効ソース処理　by zy BEGIN
		//List<BookingPlus__c> bookPlusLst = [select Id, Name, Checkinday__c from BookingPlus__c where Id = :leadId limit 1];
		// 2019/02/15 マップ機能無効ソース処理　by zy END
		checkinday = Date.today();
		//bookPlusLst[0].Checkinday__c;	
		BookingData = new List<Lead__c>();
																										/* Getting nearby account with current account */
		// 2019/02/15 マップ機能無効ソース処理　by zy BEGIN
		/*
		BookingData = [SELECT Id, Name, ReservationDate__c, Field4__c, CancelBool__c, ReservedStatus__c, StayPersons__c, Field310__r.Name, Field310__c, Field2__c, ReservedType__c, rRoom__c, rRoom__r.Name, refTypeOfRooms__r.Name, rRoom__r.centreLat__c, rRoom__r.centreLng__c
									FROM Lead__c where CancelBool__c != 1 and ReservationDate__c = :checkinday];
		*/
		// 2019/02/15 マップ機能無効ソース処理　by zy END
		RoomData = new List<Room__c>();
		// 2019/02/15 マップ機能無効ソース処理　by zy BEGIN
		/*
		RoomData = [select id, Name, Seq__c, Lat__c, Lng__c, Height__c, Width__c, centreLat__c, centreLng__c from Room__c where Name != null order by Seq__c ASC];
		*/
		// 2019/02/15 マップ機能無効ソース処理　by zy END
		selectDate = new BookingTimeTable__c();
		selectDate.Checkinday__c = Date.today();
		showRoomSet = new Set<Id>();
		setInitBranShopLst();
		setInitRoomTypeLst();
		List<OrgRoomInfo> roomInfoLst = loadConfigXMl();
		roomMessageJson = JSON.serialize(roomInfoLst);
		setInitLead();
		// 支払方法リスト初期化する
		paymentTypeLst = new List<Selectoption>();
		Schema.DescribeFieldResult fieldResult = Lead__c.Field315__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
	   	for( Schema.PicklistEntry f : ple) {
           paymentTypeLst.add(new SelectOption(f.getValue(),f.getLabel()));
	   	}
	   	leadInfo = new PopupWinInfo();
	   	// 2016/12/23 IOT状態管理機能の追加 BEGIN
	   	loadIotMessage(roomInfoLst);
	   	// 2016/12/23 IOT状態管理機能の追加 END
	}
	/*
	public Test011(ApexPages.StandardController stdController) {
		leadId = stdController.getId();
		refreshMode = 'main';
		userInf = UserUtil.CurrentUserInfo;
																									*/	/* Get current BookingPlus record */
		/* checkinday = [select Id, Name, Checkinday__c from BookingPlus__c where Id = :stdController.getId() limit 1].Checkinday__c;
		BookingData = new List<Lead__c>();
																									*/	/* Getting nearby account with current account *//*
		BookingData = [SELECT Id, Name, ReservationDate__c, Field4__c, CancelBool__c, ReservedStatus__c, StayPersons__c, Field310__r.Name, Field310__c, Field2__c, ReservedType__c, rRoom__c, rRoom__r.Name, refTypeOfRooms__r.Name, rRoom__r.centreLat__c, rRoom__r.centreLng__c
									FROM Lead__c where CancelBool__c != 1 and ReservationDate__c = :checkinday];
		RoomData = new List<Room__c>();
		RoomData = [select id, Name, Seq__c, Lat__c, Lng__c, Height__c, Width__c, centreLat__c, centreLng__c from Room__c where Name != null order by Seq__c ASC];
		selectDate = new BookingTimeTable__c();
		selectDate.Checkinday__c = Date.today();
		
		setInitBranShopLst();
		setInitRoomTypeLst();
		List<OrgRoomInfo> roomInfoLst = loadConfigXMl();
		roomMessageJson = JSON.serialize(roomInfoLst);
		setInitLead();
		// 支払方法リスト初期化する
		paymentTypeLst = new List<Selectoption>();
		Schema.DescribeFieldResult fieldResult = Lead__c.Field315__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
	   	for( Schema.PicklistEntry f : ple) {
           paymentTypeLst.add(new SelectOption(f.getValue(),f.getLabel()));
	   	}
	   	leadInfo = new PopupWinInfo();
	}*/
	 // 支店コードにより、支店関連の情報を取得する
    public void refreshBranShop() {
		//checkinday = [select Id, Name, Checkinday__c from BookingPlus__c where Id = :leadId limit 1].Checkinday__c;
		BookingData = new List<Lead__c>();
																										/* Getting nearby account with current account */
		// 2019/02/15 マップ機能無効ソース処理　by zy BEGIN
		/*
		BookingData = [SELECT Id, Name, ReservationDate__c, Field4__c, CancelBool__c, ReservedStatus__c, StayPersons__c, Field310__r.Name, Field310__c, Field2__c, ReservedType__c, rRoom__c, rRoom__r.Name, refTypeOfRooms__r.Name, rRoom__r.centreLat__c, rRoom__r.centreLng__c
									FROM Lead__c where CancelBool__c != 1 and ReservationDate__c = :checkinday];
		*/
		// 2019/02/15 マップ機能無効ソース処理　by zy END
		setInitRoomTypeLst();
		// 2019/01/30 改善対応: 一括予約、地図機能の復活対応 by cxw BEGIN
		List<OrgRoomInfo> roomInfoLst = loadConfigXMl();
		roomMessageJson = JSON.serialize(roomInfoLst);
		// 2019/01/30 改善対応: 一括予約、地図機能の復活対応 by cxw END
    	setInitLead();
    }
    // 年/月/日を選択する場合
    public void gotoDate() {
        setInitRoomTypeLst();
    	setInitLead();
    }
    // 2019/02/15 マップ機能無効ソース処理　by zy BEGIN
    /*
    // 最新情報を画面Refreshする
	public void refreshPage() {
		queryRoomStatus();
	}*/
	// 2019/02/15 マップ機能無効ソース処理　by zy END
	private void setInitLead(){
		bookingCreateOK = true;
		contactName = '';
		staysNums = 0;
		newLead = new Lead__c();
		newContact = new Contact();
		// 予約のレコードタイプ
    	newLead.RecordTypeId = CommLogicProcess.getLeadBookingRecType();
    	// チェックイン時刻、チェックアウト時刻
    	newLead.Field4__c = CommConst.DEF_CHECKIN_TIME;
    	newLead.Field3__c = CommConst.DEF_CHECKOT_TIME;
        // 有効な予約データ、一日一部屋で処理するため、重複することは処理対象外
        // 昼12時過ぎすると、到着日は当日のデータを表示する、12時前の場合、到着日は前日のデータを表示する
        Date searchDt = selectDate.Checkinday__c == null ? System.today() : selectDate.Checkinday__c;
        String queryWhere = ' Where DAY_ONLY(convertTimezone(EntryTime__c)) = ' + String.valueOf(searchDt);
        queryWhere += ' And CancelBool__c != ' + CommConst.LEAD_ST_CANCEL_FLG;
        if(!showRoomSet.isEmpty())
        	queryWhere += ' And Rroom__c = :showRoomSet';
        //queryWhere += ' And Rroom__c != null ';
		// 多店舗機能対応 BEGIN
        if (!CommUtils.isBlank(branchShopNm)) {
            queryWhere+= ' And Rroom__r.ShopInfoRef__r.ShopCode__c = \'' + String.escapeSingleQuotes(BranchShopNm) + '\'';
        }else if (userInf.isShopCodePlex) {
            Set<String> shopSt = userInf.shopSt;
            queryWhere+= ' And Rroom__r.ShopInfoRef__r.ShopCode__c in :shopSt';
        }
        
	// 2015/09/01 多店舗機能対応 END
        // 到着時刻順番で表示する
        String queryOrder = ' Order By Field4Cal__c asc ';
        String queryStr = QueryLeadHeader + queryWhere + queryOrder;
//System.debug(LoggingLevel.INFO, 'QueryLead:::' + queryStr); 

        // 開始日、終了日はSUBINDEXから取得、設定を行う
        List<Lead__c> existLeads = Database.query(queryStr);
        List<LeadTitleInf> leadTitleInfLst = new List<LeadTitleInf>();
        for(Lead__c pLead : existLeads){
        	Integer childrens = CommUtils.nullToIntZero(pLead.ChildC__c) +
            			CommUtils.nullToIntZero(pLead.ChildD__c) +
            			CommUtils.nullToIntZero(pLead.ChildE__c) +
            			CommUtils.nullToIntZero(pLead.ChildFA__c) +
            			CommUtils.nullToIntZero(pLead.ChildF__c) +
            			CommUtils.nullToIntZero(pLead.Childs__c);
            // 大人
        	String stayPersonHelp1 = CONST_STAYPERSONS_ADULTS
								.replace('$_STAYPERSON_$', 		String.valueOf(CommUtils.nullToZero(pLead.StayPersons__c)))
								.replace('$_MANS_$', 			String.valueOf(CommUtils.nullToZero(pLead.Mans__c)))
								.replace('$_FEMALE_$', 			String.valueOf(CommUtils.nullToZero(pLead.Femails__c)))
								.replace('$_CHILDS_$',			(childrens > 0 ? (' 子:' + String.valueOf(childrens) ) : ''));

    		//if (childrens > 0 ) {
    		// 2014/07/04 表示書式変更：小人A〜小人Dまで常に表示、小人EとFは０以上の場合のみ、表示する
			String stayPersonHelp2 = CONST_STAYPERSONS_CHILDS
							.replace('$_CHILDREN_$', 		String.valueOf(childrens))
							.replace('$_CHILDA_$', 			String.valueOf(CommUtils.nullToZero(pLead.ChildFA__c)))
							.replace('$_CHILDB_$', 			String.valueOf(CommUtils.nullToZero(pLead.Childs__c)))
							.replace('$_CHILDC_$', 			String.valueOf(CommUtils.nullToZero(pLead.ChildC__c)))
							.replace('$_CHILDD_$', 			String.valueOf(CommUtils.nullToZero(pLead.ChildD__c)))
							.replace('$_CHILDE_$', 			CommUtils.nullToZero(pLead.ChildE__c) > 0 ? ', E:' + String.valueOf(CommUtils.nullToZero(pLead.ChildE__c)) : '')
							.replace('$_CHILDF_$', 			CommUtils.nullToZero(pLead.ChildF__c) > 0 ? ', F:' + String.valueOf(CommUtils.nullToZero(pLead.ChildF__c)) : '');
    		//}
    		LeadTitleInf titleInf = new LeadTitleInf(stayPersonHelp1  + stayPersonHelp2,pLead.Id);//+ '\n'
    		leadTitleInfLst.add(titleInf);
        }
        titleInfoLstJson = JSON.serialize(leadTitleInfLst);
//System.debug(LoggingLevel.INFO, 'existLeads:::' + existLeads); 
        leadJson = JSON.serialize(existLeads);
	}
	/**
    * 予約データの作成
    *
    public PageReference bookingCreate(){
    	// 事前チェックを行う
		if (!preBookingCreate()) {
			return null;
		}

  		// DB操作を行う
  		Savepoint sp = Database.setSavepoint();
  		try{

  		// Hidden項目から到着日を取得する
  		Date defaultDate = Date.parse(startDays);
  		*//* 2013/01/21 到着時間と出発時間、設定によて、自動取得、設定を行う 
        Datetime defCheInDt = Datetime.newInstance(defaultDate, converHHMMtoTime(newLead.Field4__c));
        Datetime defCheOutDt = Datetime.newInstance(defaultDate.addDays(1), converHHMMtoTime(newLead.Field3__c));
    	// 2013/10/07お客様情報を自動登録機能追加する
  		upsertContact();
  		
  		// 挿入用リスト
  		List<Lead__c> insList = new List<Lead__c>();
  		// 予約受付日を処理当日に指定
  		newLead.ReservedDate__c = Datetime.now();
  		newLead.Rroom__c = strNewRoomId;
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
  			newLead.EntryTime__c = defCheInDt.addDays(0);
  			newLead.Departure__c = defCheInDt.addDays(0);
			//newLead.refTypeOfRooms__c = roomType;
  			Lead__c cloneLead =  newLead.clone(false, true);
  			// 2013/07/20 UPDATE
  			cloneLead.RoomGroupNo__c = 0;
  			insList.add(cloneLead);
		} else {
			// 1泊以上場合
	  		for(Integer i = 0; i < staysNums; i ++){
	  			if (staysNums > 1) newLead.name = String.valueOf(staysNums) + '-' + (i+1) + '泊目 ' + leadName;
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
		System.debug(logginglevel.info,'insList:::' + insList );
		
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
    }*/
    /**
	* 予約情報チャンジ処理を行う
	* 泊数変更機能対応
	**/
	// 2019/02/15 マップ機能無効ソース処理　by zy BEGIN
	/*
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
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '該当予約データが見つかりません。'));
			return;
		}
		
		// 入力情報により、関連の予約情報を一括変更を行う
		// 泊数、最後の出発日変更対応を行う
		// 同じグループNO、同じSUBINDEXの予約データは連動更新を行う
		List<Lead__c> leads = [select id, Name,Rroom__c,UnitPriceDefKbCal__c,
				StayPersons__c,EntryTime__c,Departure__c,Field4__c,Field3__c
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
		
		// 泊数の日付情報
		Date startDate = leads[0].EntryTime__c.date();
		Date endDate = leads[leads.size()-1].Departure__c.date();
		
		// 元泊数 / 新泊数
		Integer orgNights = startDate.daysBetween(endDate);
		Integer newNights = Commutils.nullToZero(leadInfo.nights).intValue();
		// 新予約人数/元予約人数
		Integer leadPeopleNum = Commutils.nullToZero(leadInfo.leadPeopleNum).intValue();
		Integer orgLeadPeopleNum = Commutils.nullToZero(leadInfo.orgLeadPeopleNum).intValue();
		// 変更なし[泊数・人数]
		if (orgNights == newNights && leadPeopleNum == orgLeadPeopleNum && !timeChangeFlg) return;

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

		Savepoint sp = Database.setSavepoint();
		try {
				// 2017/02/21 Field Security Check BEGIN
				List<String> chkFields = new List<String>{'ReservedStatus__c','Name','Departure__c','EntryTime__c','Field276__c','Field298__c'
														,'ReservedContact__c','ReservedDate__c','UnitPriceDefKb__c'};
				Map<String,Schema.SObjectField> m = Schema.SObjectType.Lead__c.fields.getMap();
				if (!CommSecurityUtils.isCanUpsertable(chkFields, m)) {
					return;
				}
				List<String> chkFieldsLst = new List<String>{'StayPersons__c','Rooms__c','RoomTypeRef__c','PlanRef__c','ParentLeadIndxRef__c'
														,'Nights__c','ExtraBedChk__c','EntryDate__c','DepartureDate__c'};
				Map<String,Schema.SObjectField> mm = Schema.SObjectType.LeadIndex__c.fields.getMap();
				if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
					return;
				}
				// 2017/02/21 Field Security Check End
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
				if (orgNights < newNights) {
					// 新規の予約データを自動設定、作成を行う
					// コピー元は同じ部屋の最後の予約データの設定情報
					// 最後の最新予約データん全項目を取得して、コピーを行う「全項目設定情報を取得する」
					String locLeadId = leads[leads.size()-1].Id;
					String leadQueryStr = CommSqlUtils.generateQueryString('Lead__c');
					leadQueryStr += ' Where id = :locLeadId ';
					Lead__c cloneLead = Database.query(leadQueryStr);
					
					// 2014/08/27 単価定義区分機能対応
					cloneLead.UnitPriceDefKb__c = cloneLead.UnitPriceDefKbCal__c;
					
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
					String repRegExpKey1 = LEAD_NAME_PREFIX + '([0-9]+-[0-9]+泊目)';
					String repRegExpKey2 = '([0-9]+-[0-9]+泊目)';
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
								String newName = newNights + '-' + (i+1) + '泊目 ';
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
								String newName = LEAD_NAME_PREFIX + newNights + '-' + (i+1) + '泊目 ';
								leads[i].Name = orgLeadName.replaceFirst(LEAD_NAME_PREFIX, newName);
							}
						}
					} else {
						// 予約名の場合
						for (Integer i = 0; i < newNights; i++ ) {
							// 予約名を設定する
							if (newNights > 1) {
								leads[i].Name = newNights + '-' + (i+1) + '泊目 ' + orgLeadName;
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
				
				// 予約情報更新処理を行う
				upsert leads;
				
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
			bookingCreateOK = false;
			return;
		}
		// 最新情報を取得して、画面に表示する
		refreshPage();
		bookingCreateOK = true;
	}
	// 画面の部屋にて、該当予約情報をチェックインする
    public void checkInByRoom() {
    	// 2017/02/21 Field Security Check BEGIN
	    List<String> chkFields = new List<String>{'Field298__c'};
	    Map<String,Schema.SObjectField> m = Schema.SObjectType.Lead__c.fields.getMap();
	    if (!CommSecurityUtils.isCanUpdateable(chkFields, m)) {
			return;
	    }
	    // 2017/02/21 Field Security Check End
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
					bookingCreateOK = false;
					// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 END
					return;
				}
				queryRoomStatus();

			}else{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'the lead Detail is not able to checkin'));
				return;
			}
    	}else{
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'the leadId is null'));
			return;
    	}
        bookingCreateOK = true;
    }
    // 2013/06/14 ADD
    // 画面の部屋にて、該当予約情報をチェックアウトする
    public void checkOutByRoom() {
    	if(strLeadId != ''){
    		// 宿泊のレコードタイプ
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
			List<Lead__c> checkInLead = [select Id, Field298__c,Rroom__c from Lead__c
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
				try{
					update checkInLead;
					// 該当部屋の清掃データを作成する[画面に指定日にて、清掃管理データを作成する]
					// 2013/08/14 ADD
					// 2013/11/06 日付調整により、清掃データの日付修正する
					Date tmpDate = getInputDate(0); // 指定日で清掃情報を作成する
					(new RoomStatusManager()).createNoCleanRooms(tmpDate, checkInLead);
				}catch(Exception e){
					// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 BEGIN
					String errMsg = e.getMessage();
					if(!CommUtils.isFieldValidationMessage(errMsg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
					bookingCreateOK = false;
					// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 END
					return;
				}
				// 最新部屋情報を取得する
				queryRoomStatus();

			}else{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'the lead Detail is not able to checkin'));
				return;
			}
    	}else{
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'the leadId is null'));
			return;
    	}
		bookingCreateOK = true;
    }
    */
    // 2019/02/15 マップ機能無効ソース処理　by zy BEGIN
    /*
    親部屋の対応
    public void refreshMessage(){
    	if(refreshMode == 'futu'){
	    	List<OrgRoomInfo> roomInfoLst = new List<OrgRoomInfo>();
	    	OrgRoomInfo roomInfo = new OrgRoomInfo();
	    	roomInfo.roomNm = 'N2490';
			roomInfo.roomTypeCode = '3';
			roomInfo.triangles = new TranglesInfo(new List<String>());
			roomInfo.myLatLng = new LatLng(55.774,-60.190);
	    	roomInfoLst.add(roomInfo);
	    	OrgRoomInfo roomInfo1 = new OrgRoomInfo();
	    	roomInfo1.roomNm = 'N2491';
			roomInfo1.roomTypeCode = '3';
			roomInfo1.triangles = new TranglesInfo(new List<String>());
			roomInfo1.myLatLng = new LatLng(-48.774,-60.190);
	    	roomInfoLst.add(roomInfo1);
	    	OrgRoomInfo roomInfo2 = new OrgRoomInfo();
	    	roomInfo2.roomNm = 'N2492';
			roomInfo2.roomTypeCode = '3';
			roomInfo2.triangles = new TranglesInfo(new List<String>());
			roomInfo2.myLatLng = new LatLng(-25.363,-60.044);
	    	roomInfoLst.add(roomInfo2);
	    	
	    	Set<String> nameSet = new Set<String>{'N2491','N2490'};
			Set<String> typeNmSet = new Set<String>{'3'};
	    	List<Room__c> roomLst = [Select TypeRoomRef__r.RoomTypeCode__c, RoomName__c, Name, Id From Room__c where name = :nameSet and TypeRoomRef__r.RoomTypeCode__c = :typeNmSet];
			system.debug(logginglevel.info,'roomLst:::' + roomLst);
			Map<String,Id> roomTypeMap = new Map<String,Id>();
			for(Room__c r : roomLst){
				roomTypeMap.put(r.Name + '_' + r.TypeRoomRef__r.RoomTypeCode__c,r.id);
			}
			system.debug(logginglevel.info,'roomTypeMap:::' + roomTypeMap);
			for(OrgRoomInfo rmInf : roomInfoLst){
				rmInf.roomId = roomTypeMap.get(rmInf.roomNm + '_' + rmInf.roomTypeCode);
			}
			roomMessageJson = JSON.serialize(roomInfoLst);
    	}else if(refreshMode == 'main'){
    		List<OrgRoomInfo> roomInfoLst = loadConfigXMl();
			roomMessageJson = JSON.serialize(roomInfoLst);
		}
    }*/
    /*
    // データ登録の事前チェック
  	private Boolean preBookingCreate() {
  		// 処理に必須な項目が未入力の場合、処理を中止する
  		// お客様/予約名/予約チャネル
  		if((CommUtils.isBlank(newLead.Relcontact__c) && CommUtils.isBlank(contactName) ) ||
  			CommUtils.isBlank(newLead.Name) ||
  			CommUtils.isBlank(newLead.Field2__c) ||
  			newLead.StayPersons__c == null) {
  			Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '必須項目を入力してください。'));
  			return false;
  		}
  		// 日帰りの場合、到着日と出発日の時刻チェックを行う
  		if (staysNums == 0) {
  			// 2013/09/16 TIME:[H:M]書式対応ため、下記処理を追加する
  			Time startTime = CommUtils.stringToTime(newLead.Field4__c);
  			Time endTime = CommUtils.stringToTime(newLead.Field3__c);
  			//if (newLead.Field4__c >= newLead.Field3__c) {
  			if (startTime >= endTime) {
  				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '出発時刻には到着時刻以降の時刻を指定して下さい'));
  				return false;
  			}
  		}
  		// Defautl値設定
  		if (staysNums == null) staysNums = 0;
  		if (!CommUtils.isBlank(newLead.Relcontact__c)) newContact.Id = newLead.Relcontact__c;
  		return true;
  	}
  	// お客様情報新規登録・更新を行う
    private void upsertContact() {
    	// 2017/02/21 Field Security Check BEGIN
		List<String> chkFields = new List<String>{'FirstName','LastName'};//,'Id'
		Map<String,Schema.SObjectField> m = Schema.SObjectType.Contact.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFields, m)) {
			return;
		}
		// 2017/02/21 Field Security Check End
    	// 顧客情報の新規作成
    	if (newContact.Id == null) {
    		String[] names = CommUtils.splitName(contactName);
    		newContact.LastName = names[0];
    		newContact.FirstName = names[1];
    	}
    	upsert newContact;
    	newLead.Relcontact__c = newContact.Id;
    }*/
    /**
	* 処理日に予約済みの予約データを取得する、アサインされている部屋をチェックを行う
	**/
	// 2019/02/15 マップ機能無効ソース処理　by zy BEGIN
    /*
	private Map<Id, Lead__c> queryLeadInfo () {

        // 宿泊のレコードタイプを取得する
        //Id bookRecTypeId = CommLogicProcess.getLeadBookingRecType();
        //Id baseRecTypeId = CommLogicProcess.getLeadBaseRecType();
        //List<Id> recTypeLst = new List<Id>{bookRecTypeId, baseRecTypeId};
        List<Id> recTypeLst = getLeadBookingRecTypeLst();
        roomLeadsCount = new Map<Id,Integer>();         // 部屋毎に格納した予約数
        // 有効な予約データ、一日一部屋で処理するため、重複することは処理対象外
        // 昼12時過ぎすると、到着日は当日のデータを表示する、12時前の場合、到着日は前日のデータを表示する
        // 2019/02/15 マップ機能無効ソース処理　by zy BEGIN
        // Date searchDt = getProcessDate(processDate, isShowToday);
        Date searchDt = (selectDate != null && selectDate.Checkinday__c == null) ? System.today() : selectDate.Checkinday__c;
        // 2019/02/15 マップ機能無効ソース処理　by zy END
        String queryWhere = ' Where DAY_ONLY(convertTimezone(EntryTime__c)) = ' + String.valueOf(searchDt);
        queryWhere += ' And CancelBool__c != ' + CommConst.LEAD_ST_CANCEL_FLG;
        queryWhere += ' And Rroom__c != null ';
        queryWhere += ' And RecordTypeId in :recTypeLst ';
		// 2015/09/01 多店舗機能対応 BEGIN
        if (!CommUtils.isBlank(branchShopNm)) {
            queryWhere+= ' And Rroom__r.ShopInfoRef__r.ShopCode__c = \'' + String.escapeSingleQuotes(BranchShopNm) + '\'';
        }else if (userInf.isShopCodePlex) {
            Set<String> shopSt = userInf.shopSt;
            queryWhere+= ' And Rroom__r.ShopInfoRef__r.ShopCode__c in :shopSt';
        }
	// 2015/09/01 多店舗機能対応 END
        // 到着時刻順番で表示する
        String queryOrder = ' Order By Field4Cal__c asc ';
        String queryStr = QueryLeadHeader + queryWhere + queryOrder;
//System.debug(LoggingLevel.INFO, 'QueryLead:::' + queryStr); 

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
    */
    // 2019/02/15 マップ機能無効ソース処理　by zy END
    /**
    * 予約に紐付く会計データの情報(会計済がどうか)を取得する
    **/
    // 2019/02/15 マップ機能無効ソース処理　by zy BEGIN
    /*
    private Map<Id, Boolean> getAccountedFlgMap(List<Lead__c> leads) {
    	Set<Id> leadIds = new Set<Id>();
    	for (Lead__c lead : leads) leadIds.add(lead.Id);//order by LastModifiedDate
    	List<AggregateResult> acountAccRs = [
											select max(Field53__c) accountedTime, Relreserve__c leadId from AccountAcount__c 
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
    // プランなしの予約データに対して、料金表にて、見積もり明細データを作成する
  	@TestVisible private void autoCreateBookingEstItems(List<Lead__c> leads, Date stDate, Date edDat) {
  		// 料金情報設定用商品が非存在する場合、処理中止
  		//if (roomPriceInfo == null) return;
  		// 予約の料金表情報を設定する
  		List<Lead__c> targets = new List<Lead__c>();
  		for (Lead__c lead : leads) {
  			//if (CommConst.APPOTION_LEADSPLIT_DIV_CODE == CommConst.APPOTION_LEADSPLIT_DIV_CODE_SPLIT) return;
  			// 予約人数は０の場合、見積もり明細作成対象外
  			// プラン未設定 && 予約人数は０以上場合、室料の見積もり明細を自動作成する
  			if (lead.Field310__c == null && CommUtils.nullToZero(lead.StayPersons__c) > 0) {
  				targets.add(lead);
  			}
  		}
  		// 自動料金設定する予約データがない場合、処理終了
  		if (targets.isEmpty()) return;	
		// 2014/01/27 料金自動設定用商品情報を取得する
	  	AccountMaster__c roomPriceInfo = null;
	  	String roomPriceProdName = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomPriceProdName__c);
	  	if (!CommUtils.isBlank(roomPriceProdName)) {
			//List<AccountMaster__c> accMsts = [select Id, Name  From AccountMaster__c Where Name = :roomPriceProdName limit 1];
			List<AccountMaster__c> accMsts = ProductItemUtils.getRoomRateProduct(roomPriceProdName);
			if (!accMsts.isEmpty()) roomPriceInfo = accMsts[0];
	  	}
		// 料金情報設定用商品が非存在する場合、処理中止
  		if (roomPriceInfo == null) return;
  		// これから、料金表設定情報にて、見積もり明細情報を作成する
  		// 店舗単位の期間範囲のTier情報を取得する
		String queryRRDetailHeader = ' Select Tier__c, ShopInfoRef__c, ShopInfoRef__r.ShopCode__c,PriceSetupDate__c From RackRateTableDetail__c ';
		String queryRRDetailString = queryRRDetailHeader + ' Where PriceSetupDate__c >=:stDate And PriceSetupDate__c <= :edDat ';
		// 店舗条件
		// 2015/09/01 多店舗機能対応 BEGIN
		if (!CommUtils.isBlank(branchShopNm)) {
            queryRRDetailString += ' And ShopInfoRef__r.ShopCode__c = :branchShopNm ';
        }else if (userInf.isShopCodePlex) {
            Set<String> shopSt = userInf.shopSt;
            queryRRDetailString+= ' And ShopInfoRef__r.ShopCode__c in :shopSt';
        }
		// 2015/09/01 多店舗機能対応 END
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
  		if (!insertEstItems.isEmpty()) insert insertEstItems;
  	}
  	*/
  	// 2019/02/15 マップ機能無効ソース処理　by zy END
  	 /**
    * 部屋故障状態を読み込む
    **/
    // 2019/02/15 マップ機能無効ソース処理　by zy BEGIN
    /*
    private Map<Id,List<RoomsStatus__c>> queryBadRoomSet () {
        Map<Id,List<RoomsStatus__c>> roomStatusMap = new Map<Id,List<RoomsStatus__c>>();
        List<RoomsStatus__c> roomStatus = (new RoomStatusManager()).queryBadRoomList(processDate, processDate);
        for(RoomsStatus__c rs : roomStatus) {
        	if(!roomStatusMap.containsKey(rs.RoomRef__c)) roomStatusMap.put(rs.RoomRef__c, new List<RoomsStatus__c>());
			roomStatusMap.get(rs.RoomRef__c).add(rs);
        }
        return roomStatusMap;
    }
    // 指定日を取得する
    private Date getInputDate(Integer days) {
    	selectDate.Checkinday__c = (selectDate.Checkinday__c == null ? Date.today() : selectDate.Checkinday__c).addDays(days);
    	return selectDate.Checkinday__c;
    }
    */
    // 2019/02/15 マップ機能無効ソース処理　by zy END
  	/**
	* 各部屋のアサイン最新状態情報を取得する
	**/
	// 2019/02/15 マップ機能無効ソース処理　by zy BEGIN
	/*
	@TestVisible private void queryRoomStatus () {
		// 統計情報内容の初期化
		iEmptyStatusSum = 0;
		isAssignedStatusSum = 0;
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
        // 2015/09/01 多店舗機能対応 BEGIN
	if (!CommUtils.isBlank(branchShopNm)) {
            queryWhere+= ' And ShopInfoRef__r.ShopCode__c = \'' + String.escapeSingleQuotes(BranchShopNm) + '\'';
        }else if (userInf.isShopCodePlex) {
            Set<String> shopSt = userInf.shopSt;
            queryWhere+= ' And ShopInfoRef__r.ShopCode__c in :shopSt';
        }
	// 2015/09/01 多店舗機能対応 END
        if (!CommUtils.isBlank(roomTypeNm)) queryWhere+= ' And TypeRoomRef__c = \'' + String.escapeSingleQuotes(roomTypeNm) + '\'';
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
        // 各部屋情報を取得する
        for (Room__c s: Database.query(queryStr)) {
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
            	areaInfLst.get(areaSet.size()-1).addFoorRoomInfo(floor);
            	floorSet.add(s.Floor__c);
            }
            // Room Info Add
            FloorRoomInfo floorRoom = areaInfLst[areaSet.size()-1].floorRoomLst[floorSet.size()-1];
            RoomInfo room = new RoomInfo(s, roomNameType);
            floorRoom.addRoom(room);
            // 部屋情報初期化を行う
            roomTimesMap.put(s.Id, '');
        } // End For
        // ************************
        // 関連情報を取得する
        // ************************
        // 既存の予約データを取得する
        Map<Id, Lead__c> roomLeadMap = this.queryLeadInfo();
        // 2014/05/22 会計済みフラグ格納
        Map<Id, Boolean> isAccountedFlgMap = this.getAccountedFlgMap(roomLeadMap.values());
        // 故障部屋情報を取得する
        //Set<Id> badRoomSet = this.queryBadRoomSet();
        Map<Id,List<RoomsStatus__c>> badRoomMap = this.queryBadRoomSet();
        // 部屋清掃情報を取得する
        // 2013/11/06 部屋掃除情報の取得は当日の指定日で設定する
        //Map<Id, String> cleanStatusRoomMap = (new RoomStatusManager()).getCleanStatusRooms(processDate);
        Map<Id, String> cleanStatusRoomMap = (new RoomStatusManager()).getCleanStatusRooms(getInputDate(0));
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
        		    	room.simpleGuestNm = badRoom.Name;
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
        		    		isNoCleanStatusSum++;
        		    	}
        		    }
        			// 予約データが存在する場合
        			if (roomLeadMap.containsKey(room.sobj.Id)) {
        				Lead__c lead = roomLeadMap.get(room.sobj.Id);
        				// 部屋情報に、予約情報を維持する
        				room.setLeadInfo(lead);
						// 会計済みフラグ設定する
						room.isAccountedFlg = isAccountedFlgMap.containsKey(lead.Id) ? isAccountedFlgMap.get(lead.Id) : false;
	        		    //お部屋ステータス：[未清掃]
						if (lead.Field299__c == CommConst.LEAD_ROOM_ST_UNCLEAN) {
							room.isUnClean = true;
						}

        				// 予約ステータス[チェックイン完/外出中/滞在中]
        				String status = lead.Field298__c;
        				if( status == CommConst.LEAD_GUEST_ST_CI ||
                            status == CommConst.LEAD_GUEST_ST_OUT ||
                            status == CommConst.LEAD_GUEST_ST_BATH){
							// 出発日は今の日付の場合：出発予定
        					//if(lead.LeadIndexRef__r.DepartureDate__c == processDate){
        					if (lead.LeadIndexRef__r.DepartureDate__c == uiInputDate) {
        						room.cssClass = this.strCheckOutDayStatusColor;
        						checkOutDayStatusSum += 1;
        					}
        					// 滞中
        					else{
        						room.cssClass = this.strIsStayStatusColor;
        						isStayStatusSum += 1;
	        					// 該当部屋のデータは移動可能
	        					room.isCanMove = true && !room.isBlocked;
	        					
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
			        					if (systemDtFormat >= leadDepartDt.format('yyyyMMddHHmm')) {
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
        					// 該当部屋のデータは移動可能
        					room.isCanMove = true && !room.isBlocked;
        					
        					//iEmptyStatusSum += 1;
        					isAssignedStatusSum ++;
        				}
        			}else{
        				// 空室「予約データがない場合」
        				room.cssClass = this.strIsNoneStatusColor;
        				iEmptyStatusSum += 1;
        			}
        		}
        	}
        }

        // 空欄を補足する
        for (AreaRoomInfo area : areaInfLst) {
            for (FloorRoomInfo floor : area.floorRoomLst) {
            	Integer dumyRooms = maxRooms - floor.roomLst.size();
                for (Integer i = 0; i < dumyRooms; i++) {
                	floor.addRoom(new RoomInfo(new Room__c(), roomNameType));
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
	}
	*/
	// 2019/02/15 マップ機能無効ソース処理　by zy END
	/**
    * 部屋情報の明細情報を取得する
    * 該当部屋に予約データの詳細情報を取得する
    **/
    @RemoteAction
    global static PopupWinInfo getRoomInfo(String roomId, String leadId) {
    	if(String.escapeSingleQuotes(roomId) != '' && String.escapeSingleQuotes(leadId) != ''){
    	    Lead__c leadDetail = [	Select Id, Name, RecordType.Name, Receptiondate__c, LeadIndexRef__r.Name,
    	    						Rroom__c, Rroom__r.Name, Relcontact__r.Id, Relcontact__r.Name,Field276__c,
    	                           	LeadIndexSubId__c, LeadIndexRef__c, RoomGroupNo__c, ReservedStatus__c, 
    	                          	//LeadIndexRef__c,LeadIndexRef__r.EntryDate__c,LeadIndexRef__r.EntryTime__c,
    	                           	//LeadIndexRef__r.DepartureDate__c,LeadIndexRef__r.DepartureTime__c, 
    	                           	EntryTime__c, Field4__c,
    	                           	Departure__c, Field3__c, Field310__r.Name, Field298__c,StayPersons__c,SeminarOrderFlg__c,Field2__c,
    	                           	Field308__c,Comment3__c 
    	                           	From Lead__c where Id = :leadId];
    	    // 連泊情報を取得する
			List<Lead__c> leads = [ select id, EntryTime__c,Departure__c,Field4__c,Field3__c,Field298__c
									from Lead__c 
									where LeadIndexRef__c = :leadDetail.LeadIndexRef__c 
									And LeadIndexSubId__c = :leadDetail.LeadIndexSubId__c
									And RoomGroupNo__c = :leadDetail.RoomGroupNo__c
									And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 
									Order By EntryTime__c] ;
	    	//Room__c tempRoom = [select Id,Name from Room__c where Id = :roomId];
	    	// 会計情報を取得する　
	    	List<AccountAcount__c> acountAcountLst = [select id,Field53__c,AccountName__c,ContactName__c,AccountReceiptName__c,BillingCal__c,AccountProviso__c from AccountAcount__c where Relreserve__c = :leadId order by LastModifiedDate desc limit 1];
			// 予約データのSubIndex設定データが存在する場合、該当データの情報を取得する
			//List<LeadIndex__c> subLeadIdxLst = [select RoomTypeRef__c, EntryDate__c, DepartureDate__c,EntryTime__c,DepartureTime__c from LeadIndex__c where id = :leadDetail.LeadIndexSubId__c];
			PopupWinInfo roomInfoDetail = new PopupWinInfo();
			// 予約番号
			roomInfoDetail.leadIndexNo = leadDetail.LeadIndexRef__r.Name;
			roomInfoDetail.leadIndexId = leadDetail.LeadIndexRef__c;
			// 予約名
			roomInfoDetail.leadId = leadDetail.Id;
			roomInfoDetail.leadName = leadDetail.Name;
			// お客様
			roomInfoDetail.customId = leadDetail.Relcontact__c;
			if (leadDetail.Relcontact__c != null) roomInfoDetail.customName = leadDetail.Relcontact__r.Name;
			// お客様ステータス
			roomInfoDetail.customStatus = CommUtils.nullToBlank(leadDetail.Field298__c);
			
            // 到着日
            roomInfoDetail.entryDate =  leads[0].EntryTime__c.format('yyyy/MM/dd');
            // 到着時刻
            roomInfoDetail.entryTime = leads[0].Field4__c;
            // 出発日
            roomInfoDetail.departureDate = leads[leads.size()-1].Departure__c.format('yyyy/MM/dd');
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
				}
			}
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
    // 2019/02/15 マップ機能無効ソース処理　by zy BEGIN
    /*
  	// 予約登録FORM初期化処理
	private void initBookingFormInfo() {
        contactName = '';
		newLead = new Lead__c();
		newContact = new Contact();
		// 予約のレコードタイプ
    	newLead.RecordTypeId = CommLogicProcess.getLeadBookingRecType();
    	// チェックイン時刻、チェックアウト時刻
    	newLead.Field4__c = CommConst.DEF_CHECKIN_TIME;
    	newLead.Field3__c = CommConst.DEF_CHECKOT_TIME;
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
	private String changeLeadName(String orgLeadName , boolean isFirst, Integer newNights, Integer leadIndex){
			String newLeadName = '';
			//String orgLeadName = leads[0].Name;
				// 予約名切替用キー
			String repRegExpKey1 = LEAD_NAME_PREFIX + '([0-9]+-[0-9]+泊目)';
			String repRegExpKey2 = '([0-9]+-[0-9]+泊目)';
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
					String newName = newNights + '-' + (leadIndex+1) + '泊目 ';
					newLeadName = orgLeadName.replaceFirst(repRegExpKey2, newName);
					//System.debug('newLeadName2------' + newLeadName);
				}
			}else if (orgLeadName.startsWith(LEAD_NAME_PREFIX)) {
				// 予約名を設定する
				if (newNights > 1) {
					String newName = LEAD_NAME_PREFIX + newNights + '-' + (leadIndex+1) + '泊目 ';
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
	*/
	// 2019/02/15 マップ機能無効ソース処理　by zy END
	/**
	* 割り当て予約関連の予約データを取得する
	* 	①部屋未割り当てる予約取得する
	*	②部屋割り当てする場合、アサインする予定の期間に、予約データ存在チェック用予約取得する
	*   ③部屋割り当てする場合、該当移動する予約に関連の予約一覧を取得する
	**/
	// 2019/02/15 マップ機能無効ソース処理　by zy BEGIN
	/*
	private static List<Lead__c> getOrgMoveLeadInfo(String leadId, Date searchDt) {
		// 遷移元の予約関連情報取得
		Lead__c keyLead = [select Rroom__c, refTypeOfRooms__c, LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c from lead__c where id = :leadId];
		// 部屋アサイン対象期間予約リストを取得する
		List<Lead__c> updList = [select Rroom__c,refTypeOfRooms__c,refTypeOfRooms__r.Name,Rroom__r.Name,
										StayPersons__c, Relcontact__r.Name, Relcontact__r.Name1__c,Field276__c,
                                        EntryTime__c, Field4__c, Field3__c,
                                        Field298__c,LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c
									from Lead__c 
									where LeadIndexSubId__c = :keyLead.LeadIndexSubId__c 
									And LeadIndexRef__c = :keyLead.LeadIndexRef__c
									And RoomGroupNo__c = :keyLead.RoomGroupNo__c
									//And Rroom__c = null
									And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 		// 有効な予約データ
									And DAY_ONLY(convertTimezone(EntryTime__c)) >= :searchDt Order By EntryTime__c asc ];
		return updList;
	}
	// ******************************
	// 宿泊者名簿情報を作成する
	// ******************************
	private static void createBookingGuest(Lead__c lead) {
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
	private void setMessageItem(Date currDate) {
		// 2015/10/27 連絡事項共通化 BEGIN
		// 去年の年月
		currDate = selectDate.Checkinday__c;
		//Date oldYearMonth = currDate.addYears(-1);
		DateTime currDt = DateTime.newInstance(currDate, Time.newInstance(0,0,0,0));
		String currYm = currDt.format('yyyyMMdd');
		messageObj = new MessageItem__c(name=currYm);
		// 2015/10/27 連絡事項共通化 END
	}
	*/
	// 2019/02/15 マップ機能無効ソース処理　by zy END
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
    // 宿泊の対象データ表示機能
    public static List<Id> getLeadBookingRecTypeLst () {
		Id bookRecTypeId = CommLogicProcess.getLeadBookingRecType();
	    Id baseRecTypeId = CommLogicProcess.getLeadBaseRecType();
	    List<Id> recTypeLst = new List<Id>{bookRecTypeId, baseRecTypeId};
	    return recTypeLst;
    }
	public Object[] getBookingData(){																	/* Create JSON DATA */
		Object[] jsonData = new Object[]{};
		double cLat = 0;																				/* Default Position of Marker */
		double cLng = 0;
		double wLat = 83.04752889355734;																/* Default Position of Marker if it is Not Assigned */
		double wLng = -22.5;
		string plan;
		for (integer i = 0; i < BookingData.size(); i++ ) {
			if ( BookingData[i].rRoom__c != null ) {													/* Check not assigned room ? */
				cLat = BookingData[i].rRoom__r.centreLat__c;
				cLng = BookingData[i].rRoom__r.centreLng__c;
			} else {
				cLat = wLat;
				cLng = wLng;
				wLat -= 3;																				/* for vertical position */
			}
			jsonData.add(																				/* Define JSON Data */
				'{name:\'' + ((BookingData[i].Name != null)? esc(BookingData[i].Name) : '') + 														/* Booking Name */
				'\', id:\'' + BookingData[i].Id + 														/* Booking Id */
				'\', flag:\'' + 0 + 																	/* Flag */
				'\', cLat:\'' + cLat + 																	/* If Assigned to Room, Set Marker Position on the Room Area in the map */
				'\', cLng:\'' + cLng + 
				'\', status:\'' + ((BookingData[i].ReservedStatus__c != null)? esc(BookingData[i].ReservedStatus__c) : '') + 									/* Reservation Sattus */
				'\', persons:\'' + BookingData[i].StayPersons__c + 										/* Number of Stay Persons */
				'\', roomid:\'' + BookingData[i].rRoom__c + 											/* Id of Room which Assigned to */
				'\', room:\'' + ((BookingData[i].rRoom__r.Name != null)? esc(BookingData[i].rRoom__r.Name) : '') + 											/* Name of Room which Assigned to */
				'\', roomType:\'' + ((BookingData[i].refTypeOfRooms__r.Name != null)? esc(BookingData[i].refTypeOfRooms__r.Name) : '') +								/* Name of RoomType which Assigned to */
				'\', plan:\'' + ((BookingData[i].Field310__r.Name != null)? esc(BookingData[i].Field310__r.Name) : '') +																	/* Plan name */
				'\', planid:\'' + BookingData[i].Field310__r.Id +								/* Plan Id */
				'\', segment:\'' + ((BookingData[i].Field2__c != null)? esc(BookingData[i].Field2__c) : '') +											/* Segment */
				'\', booktype:\'' + ((BookingData[i].ReservedType__c != null)? esc(BookingData[i].ReservedType__c) : '') +									/* Reservation Type */
				'\'}'
			);
	    }
//		system.debug('*************Debug:jsonData '+ jsonData);
		return jsonData;
	}
	public Object[] getRoomData(){																		/* Create Room JSON DATA */
		Object[] jsonData = new Object[]{};
		double clat1;
		double clng1;
		double clat2;
		double clng2;
		for (integer i = 0; i < RoomData.size(); i++ ) {
			clat1 = ((RoomData[i].Lat__c != null)&&(RoomData[i].Height__c != null))? (RoomData[i].Lat__c - RoomData[i].Height__c) : 0;
			clng1 = (RoomData[i].Lng__c != null)? RoomData[i].Lng__c : 0;
			clat2 = (RoomData[i].Lat__c != null)? RoomData[i].Lat__c : 0;
			clng2 = ((RoomData[i].Lng__c != null)&&(RoomData[i].Width__c  != null))? (RoomData[i].Lng__c + RoomData[i].Width__c): 0;
			
			jsonData.add(																				/* Define JSON Data */
				'{name:\'' + ((RoomData[i].Name != null)? esc(RoomData[i].Name) : '') + 														/* Room Name */
					'\', id:\'' + RoomData[i].Id + 														/* Room Id */
					'\', flag:\'' + 0 + 																/* Flag */
					'\', cLat1:\'' + clat1 + 															/* Room Lat Bottom-Left */
					'\', cLng1:\'' + clng1 + 															/* Room Lng Bottom-Left */
					'\', cLat2:\'' + clat2 + 															/* Room Lat Top-Right */
					'\', cLng2:\'' + clng2 + 															/* Room Lng Top-Right */
					'\', cCentreLat:\'' + RoomData[i].centreLat__c + 									/* Room Centre Lat */
					'\', cCentreLng:\'' + RoomData[i].centreLng__c + 									/* Room Centre Lat */
				'\'}'
			);
		}
		//system.debug('*************Debug:jsonData '+ jsonData);
		return jsonData;
	}
	public List<Lead__c> getbooking() {																/* get booking data*/
  		return BookingData;
    }
	public string getfixedday() {																			/* Get checkin date of current BookingPlus record */
		string cyear = string.valueof(checkinday.year());
		string cmonth = string.valueof(checkinday.month());
		string cday = string.valueof(checkinday.day());
		return cyear + '年 ' + cmonth + '月 ' + cday +'日';
    }
	public string getRecordId() {																		/* get cuurent record id */
		string json = '{id:\''+leadId+'\'}';
		return json;
		//return string.valueOf(recordid);
	}
	 // 支店選択リスト
	private Map<String,ShopInformation__c> shopInfoMap;
    public List<SelectOption> branchShopLst{get; private set;}
    public String branchShopNm{get; set;}
    public ShopInfoUtil.Color statusColor{get; private set;}	// 部屋ステータスの色情報を格納
    private UserUtil.UserShopInfo userInf;
    private void setInitBranShopLst() {
		// 2015/09/01 多店舗機能対応 BEGIN
        branchShopLst = ShopInfoUtil.getBranchShopLst(userInf.shops);
        shopInfoMap   = ShopInfoUtil.getShopInfoMap(userInf.shops);
		// 2015/09/01 多店舗機能対応 END
        if (!branchShopLst.isEmpty()) {
        	// 顧客に設定する支店で初期値に設定する[2013/06/30]
        	String locShopCode = UserUtil.CurrentUser.ShopCode__c;
        	for (SelectOption s : branchShopLst) {
        		if (s.getValue() == locShopCode) branchShopNm = locShopCode;
        	}
        }
        // 支店関連のCOLOR情報初期化を行う
        setBranShopColorInfo();
    }
    // 部屋タイプ情報
	public List<SelectOption> roomTypeLst{get; private set;}
	public String roomTypeNm{get; set;}
    private void setInitRoomTypeLst() {
    	roomTypeLst = new List<SelectOption>();
		// 部屋タイプ一覧取得用
		//for (TypeOfRooms__c r : [ Select Id, Name From TypeOfRooms__c Order By Seq__c limit 500]) {
		String typeRoomQuery = ' Select Id, Name From TypeOfRooms__c ';
		if (!String.isEmpty(branchShopNm)) typeRoomQuery += ' Where ShopInfoRef__r.ShopCode__c = :branchShopNm ';
		typeRoomQuery += ' Order By Seq__c limit 500 ';
	// 2015/09/01 多店舗機能対応 BEGIN
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
		roomTypeNm = '';
    }
    private void setBranShopColorInfo() {
    	statusColor = ShopInfoUtil.getStatusColor(branchShopNm);
    }
	//
	public String mapTilesRootPath{get;set;}
	public String mapTilesSubPath{get;set;}
	private List<OrgRoomInfo> loadConfigXMl(){
		mapTilesRootPath = '';
		mapTilesSubPath = '';
		String branchNm = ApexPages.currentPage().getParameters().get('shopCd');
		// 2019/01/30 改善対応: 一括予約、地図機能の復活対応 by cxw BEGIN
		if(CommUtils.isBlank(branchNm)) branchNm = branchShopNm;
		// 2019/01/30 改善対応: 一括予約、地図機能の復活対応 by cxw END
		if(CommUtils.isBlank(branchNm)) branchNm = UserUtil.CurrentUser.ShopCode__c;
		// 拡張予約項目を定義する
    	Dom.XmlNode targetNode = CommXmlUtils.parseXmlDoc('RoomIndicatorMapConfig', branchNm);
    	Dom.XmlNode mapNode = targetNode.getChildElement('MAPROOTPATH',null);
    	if(mapNode != null) mapTilesRootPath = mapNode.getText();
    	Dom.XmlNode mapTitleNode = targetNode.getChildElement('MAPSUBPATH',null);
    	if(mapTitleNode != null) mapTilesSubPath = mapTitleNode.getText();
    	String curShopCode = '';
    	if (!CommUtils.isBlank(branchShopNm)) {
            curShopCode = String.escapeSingleQuotes(BranchShopNm) ;
        }else {
        	curShopCode = UserUtil.CurrentUserInfo.defaultShopCode;
        }
		List<OrgRoomInfo> rmInfoLst = new List<OrgRoomInfo>();
		String roomQuery = 'select id,Lat__c,Lng__c,Seq__c,RoomName__c,RoomAlias__c,TypeRoomRef__c,TypeRoomRef__r.Name,TypeRoomRef__r.RoomTypeCode__c,NoShowLeadIcon__c from Room__c where Lng__c != null and Lat__c != null ';
		if (!CommUtils.isBlank(curShopCode)) {
			roomQuery += ' and ShopInfoRef__r.ShopCode__c = :curShopCode ';
		}
		for (Room__c room : DataBase.query(roomQuery)){
			rmInfoLst.add(new OrgRoomInfo(room));
			showRoomSet.add(room.id);
		}
		return rmInfoLst;
	}
	/**
  	* HH:MM 文字列からTIMEに変換処理
  	**/
  	private Time converHHMMtoTime(String timeStr) {
        return CommUtils.stringToTime(timeStr);
  	}
	/**
	* 団体、単体の予約リストに表示する表示、[未割り当て予約]
	* 表示方式はTREEで(VIEW)
	**/
	@remoteAction
	global static List<RoomIndicatorInfo.NoAssignLeadInfoExt> noAssingLeadInfoAll(String queryDt, String branchShopCd, Boolean showToday) {
		// 指定日により、
		Date searchDt = (String.isEmpty(queryDt)) ? Date.today() : Date.parse(queryDt);
		//Date todayDt Date searchDt = Date.today();
		// 予約データは基本、宿泊場合、
		//Id bookRecTypeId = CommLogicProcess.getLeadBookingRecType();
        //Id baseRecTypeId = CommLogicProcess.getLeadBaseRecType();
        //List<Id> recTypeLst = new List<Id>{bookRecTypeId, baseRecTypeId};
        //List<Id> recTypeLst = getLeadBookingRecTypeLst();
		// 到着日は指定日と同じ、有効な予約データ、部屋番号は未設定場合、
		Integer cancelBool = CommConst.LEAD_ST_CANCEL_FLG;
        String noAssingQuery = ' Select id, Name, Field353__c,EntryTime__c,Departure__c,Field3__c,Field4__c, LeadIndexRef__c, Relcontact__r.Name, refTypeOfRooms__r.Name,refTypeOfRooms__c From Lead__c ';
		noAssingQuery += ' Where CancelBool__c != : cancelBool ';
		//noAssingQuery += ' And RecordTypeId in :recTypeLst ';
		noAssingQuery += ' And Rroom__c = null ';
		noAssingQuery += ' And DAY_ONLY(convertTimezone(EntryTime__c)) = :searchDt ';
		// 2013/09/02 ADD
		if (!CommUtils.isBlank(branchShopCd)) noAssingQuery += ' And (refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c = \'' + String.escapeSingleQuotes(branchShopCd) + '\' OR refTypeOfRooms__c = null) ';
		
		//if (!String.isEmpty(queryRoomType)) noAssingQuery += ' And refTypeOfRooms__c = :queryRoomType ';
		List<Lead__c> noAssignList = DataBase.query(noAssingQuery);
		// Map<LeadIndex_ID, 予約情報>
		Map<Id, RoomIndicatorInfo.NoAssignLeadInfoExt> leadMap = new Map<Id, RoomIndicatorInfo.NoAssignLeadInfoExt>();
		//
		List<RoomIndicatorInfo.NoAssignLeadInfoExt> rsList = new List<RoomIndicatorInfo.NoAssignLeadInfoExt>();
		for (Lead__c item : noAssignList) {
			Id leadIndexId = item.LeadIndexRef__c;
			// 該当予約は未設定する場合
			if (!leadMap.containsKey(leadIndexId)) {
				// 第一階層で、顧客名で階層名に設定を行う、一括設定する場合、該当階層に含めの予約は全部自動部屋アサインを行う
				RoomIndicatorInfo.NoAssignLeadInfoExt noAssItem = new RoomIndicatorInfo.NoAssignLeadInfoExt(true);
				noAssItem.id = leadIndexId;
				noAssItem.text = item.Relcontact__r.Name;
				//noAssItem.contactName = item.Relcontact__r.Name;
				leadMap.put(leadIndexId, noAssItem);
			}
			// 予約単位の情報を設定して、LeadIndexの配列に設定を行う
			// 子情報ない設定を行う
			RoomIndicatorInfo.NoAssignLeadInfoExt noAssParentItem = leadMap.get(leadIndexId);
			RoomIndicatorInfo.NoAssignLeadInfoExt noAssChildItem = new RoomIndicatorInfo.NoAssignLeadInfoExt(false);
			
			noAssChildItem.id = item.Id;
			noAssChildItem.rowNums = noAssParentItem.items.size();
			//noAssChildItem.text = String.valueOf(noAssChildItem.rowNums + 1) + '.' + item.Name;
			noAssChildItem.text = item.Name;//item.Name.length() > 18 ? item.Name.substring(0,18) : item.Name;
			//noAssChildItem.contactName = item.Relcontact__r.Name;
			if (item.refTypeOfRooms__c != null) {
				noAssChildItem.text += '(' + item.refTypeOfRooms__r.Name + ')';
			} else {
				noAssChildItem.text += '(部屋タイプなし)';
			}
			noAssChildItem.roomTypeName = item.refTypeOfRooms__r.Name;
			noAssChildItem.roomTypeId = item.refTypeOfRooms__c;
			
			String statusIcon = CommUtils.nullToBlank(item.Field353__c);
			if (!String.isEmpty(statusIcon)) {
				Pattern pTool = Pattern.compile('.*src=["](/resource.*?)["].*');
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
		List<Id> leadIndexIdLst = new List<Id>(leadMap.keySet());
		leadIndexIdLst.sort();
		for (Id leadIdxId : leadIndexIdLst) {
			RoomIndicatorInfo.NoAssignLeadInfoExt titleItem = leadMap.get(leadIdxId);
			//titleItem.subdataid = titleItem.subdataid.substringBeforeLast(',');
			// 未割り当てる予約件数を設定する
			titleItem.text += '　【'+ titleItem.subdataid.split(',').size() +'】件' ;
			rsList.add(titleItem);
		}
		return rsList;
	}
	// -------------------------------------------
   	// 予約新規登録機能対応開始
   	// 各店舗の表示する項目情報を取得、格納を行う
    // -------------------------------------------
    private static final String LeadConstFields  = 'Name,Relcontact__c,refTypeOfRooms__c,EntryTime__c,Field4__c,Departure__c,Field3__c,StayPersons__c,SeminarOrderFlg__c,ExtraBedChk__c,Rroom__c,Field310__c,Field315__c,Field2__c,Segment__c,Comment3__c';
	
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
				inputField.id = fieldKey;
				psection.childComponents.add(inputField);
			} else {
				Component.Apex.InputField inputField = new Component.Apex.InputField();
				inputField.expressions.value = '{!newLead.'+fieldKey+'}';
				psection.childComponents.add(inputField);
			}

		}	
		return psection;
   	}
	/**
	* 予約情報拡張設定項目作成する
	**/
	public Component.Apex.pageBlockSection getInputExtendFields () {
		// 拡張情報を取得する
		Component.Apex.pageBlockSection psection = parseFieldsXml(branchShopNm);
		return psection;
	}
	class OrgRoomInfo{
		String roomNm;
		String roomId;
		String roomTypeCode;
		String roomTypeId;
		String roomTypeNm;
		String cssClass;
		boolean isAccountedFlg;
		boolean isUnClean;
		boolean isCanMove;
		boolean isBlocked;
		String filterMessage;
		TranglesInfo triangles;
		LatLng myLatLng;
		String roomSeq;
		boolean isEmptyNoShow;
		OrgRoomInfo(){
			roomNm = '';
			roomTypeCode = '';
		}
		OrgRoomInfo(Room__c room){
			roomNm = room.RoomName__c;
			roomId = room.id;
			roomTypeCode = room.TypeRoomRef__r.RoomTypeCode__c;
			roomTypeId = room.TypeRoomRef__c;
			roomTypeNm = room.TypeRoomRef__r.Name;
			cssClass = '';
			filterMessage = CommUtils.nullToBlank(room.RoomAlias__c);
			isEmptyNoShow = room.NoShowLeadIcon__c;
			//roomSeq = CommUtils.nullToZero(room.Seq__c);
			myLatLng = new LatLng(room.Lat__c,room.Lng__c);
			// 2019/02/15 マップ機能無効ソース処理　by zy BEGIN
			isBlocked = false;
			// 2019/02/15 マップ機能無効ソース処理　by zy END
		}
	}
	class LatLng{
		Decimal lat;
		Decimal lng;
		LatLng(Decimal l,Decimal n){
			lat = l;
			lng = n;
		}
	}
	class TranglesInfo{
		String maxValueX;
		String minValueX;
		String maxValueY;
		String minValueY;
		String trianglecoords;
		Decimal maxIntX = null;
		Decimal minIntX = null;
		Decimal maxIntY = null;
		Decimal minIntY = null;
		TranglesInfo(List<String> trianglecoords){
			for(String trian : trianglecoords){
				String[] trians = trian.split(',');
				Decimal xmlIntX = Decimal.valueOf(trians[0].trim());
				Decimal xmlIntY = Decimal.valueOf(trians[1].trim());
				if(maxIntX == null || maxIntX < xmlIntX) maxIntX = xmlIntX;
				if(minIntX == null || minIntX > xmlIntX) minIntX = xmlIntX;
				if(maxIntY == null || maxIntY < xmlIntY) maxIntY = xmlIntY;
				if(minIntY == null || minIntY > xmlIntY) minIntY = xmlIntY;
			}
			maxValueX = String.valueOf(maxIntX);
			minValueX = String.valueOf(minIntX);
			maxValueY = String.valueOf(maxIntY);
			minValueY = String.valueOf(minIntY);
		}
	}
	class AC{					/* ACdata Class for creating Update data from JSON data */
		string name;
		string id;
		integer flag;
		double cLat;
		double cLng;
		string status;
		string persons;
		string roomid;
		string room;
		string roomType;
		string plan;
		string planid;
		string segment;
		string booktype;
	}
	
	public string esc(string str){									/* Escape for XSS (characters: \ " / < > { } % = ; : ( ) & + - ) */
		return str.replace('\\', '\\\\').replace('&', '&amp').replace(';','&#59;').replace('&amp', '&amp;').replace('\'', '&#39;').replace('\"', '&quot;').replace('/','&#47;').replace('<', '&lt;').replace('>', '&gt;').replace('{','&#123;').replace('}','&#125').replace('%', '&#37;').replace('=','&#61;').replace(':','&#58;').replace('(','&#40;').replace(')','&#41;').replace('+','&#43;').replace('-','&#45;');
	}
	// 人数表示情報
    private static final String CONST_STAYPERSONS_ADULTS = '$_STAYPERSON_$名（男:$_MANS_$ 女:$_FEMALE_$$_CHILDS_$）';
    private static final String CONST_STAYPERSONS_CHILDS = '子供:$_CHILDREN_$名（A:$_CHILDA_$, B:$_CHILDB_$, C:$_CHILDC_$, D:$_CHILDD_$$_CHILDE_$$_CHILDF_$）';
   
	// 部屋情報維持する
    public class RoomInfo {
    	public RoomInfo (Room__c s, String pRoomNameType) {
    		sobj = s;
    		// 空室の場合、色なし
    		cssClass = '';
    		leadId = '';
            hiddenLeadId = '';
    		//accountId = '';
    		//清潔
    		isUnClean = false;
    		// 
    		roomNameType = pRoomNameType;
    	}
    	public Room__c sobj{get; private set;}
    	private String roomNameType;

    	public void setLeadInfo (Lead__c pLead){
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
            			CommUtils.nullToIntZero(pLead.Childs__c);
            adults = 	CommUtils.nullToIntZero(pLead.Mans__c) +
            			CommUtils.nullToIntZero(pLead.Femails__c);
            			
    		stayPersonHelp1 = CONST_STAYPERSONS_ADULTS
								.replace('$_STAYPERSON_$', 		String.valueOf(CommUtils.nullToZero(pLead.StayPersons__c)))
								.replace('$_MANS_$', 			String.valueOf(CommUtils.nullToZero(pLead.Mans__c)))
								.replace('$_FEMALE_$', 			String.valueOf(CommUtils.nullToZero(pLead.Femails__c)))
								.replace('$_CHILDS_$',			(childrens > 0 ? (' 子:' + String.valueOf(childrens) ) : ''));
			
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
    	    	
        // Leads count
        public Integer leadsCount {get;set;}
        //top Lead Id
        public String hiddenLeadId{get;set;}
        public String startTime{get;set;}
        public String endTime{get;set;}
        public Boolean isBadRoom{get;set;}
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
    }
	public class LeadInfo{
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
    // 2019/02/15 マップ機能無効ソース処理　by zy BEGIN
    /*
	// 各エリアの部屋情報
	public class AreaRoomInfo {
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
    public class FloorRoomInfo {
    	public FloorRoomInfo() {
    		roomLst = new List<RoomInfo>();
    		//index = pIndex;
    	}
    	public void addRoom(RoomInfo r) {
    		roomLst.add(r);
    	}
    	public String floorName{get{return CommUtils.nullToBlank(roomLst[0].sobj.Floor__c); }}
    	public List<RoomInfo> roomLst{get; private set;}
    	//public Integer index{get; private set;}
    }
    */
    // 2019/02/15 マップ機能無効ソース処理　by zy END
    public class LeadTitleInf{
    	private string titleStr;
    	private Id leadId;
    	public LeadTitleInf(String title,Id pLeadId){
    		titleStr = title;
    		leadId = pLeadId;
    	}
    }
    // 2016/12/23 IOT状態管理機能の追加 BEGIN
    // 地図に表示したい部屋ののIOTの最新異常情報を取得する
    public Boolean statusFlg{get{return CommDefine__c.getOrgDefaults().IotStatusManagerFlg__c == null ? false : CommDefine__c.getOrgDefaults().IotStatusManagerFlg__c;}}
    public String initIotMessage{get; private set;}
    private void loadIotMessage(List<OrgRoomInfo> roomInfoLst) {
    	List<MessageInformation__c> iotLst = new List<MessageInformation__c>();
    	
    	if (statusFlg) {
	    	set<string> roomAliasSet = new set<string>();
	    	for (MessageInformation__c message : [Select Id, Message__c, MessageCode__c, MessageLevel__c, MessageSub1__c, MessageType__c, Name, LastModifiedDate 
	    		from MessageInformation__c where MessageType__c = 'IOT' 
	    		and MessageLevel__c != null
	    		Order by LastModifiedDate desc ,MessageSub1__c
	    		]) {
	    		// 最新情報を取得する　
	    		String roomAlias = CommUtils.nullToBlank(message.MessageSub1__c);
	    		if (!roomAliasSet.contains(message.MessageSub1__c)) {
	    			iotLst.add(message);
	    			roomAliasSet.add(roomAlias);
	    		}
	    	}
    	}
    	initIotMessage = JSON.serialize(iotLst);
    }
    // 2016/12/23 IOT状態管理機能の追加 END
     // 2016/11/24 チェックアウト多国語対応 BEGIN
    public String mulitiCheckoutLabel{get;private set;}
    private void setMulitiCheckoutLabelFun() {
		Schema.DescribeFieldResult fieldResult = Lead__c.Field298__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
	   	for( Schema.PicklistEntry f : ple) {
	   		if (f.getValue() == CommConst.LEAD_GUEST_ST_CO) {
	   			mulitiCheckoutLabel = f.getLabel();
	   			break;
	   		}
	   	}
    }
    // 2016/11/24 チェックアウト多国語対応 END
}