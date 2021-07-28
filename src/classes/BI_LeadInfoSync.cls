/**
* バッチ連携：外から連携する顧客情報を反映する
* 2013/06/20 予約変更ステータスデータ連携する場合、処理対象外にする
* 2015/06/08 お客様情報取得検索方式変更
* 2015/07/22 部屋タイプと部屋が1対1の場合は部屋の自動アサイン機能追加
* 2016/10/19 部屋タイプと部屋が1対1の場合は故障部屋を割当される不具合改修
* 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修
* 2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する
**/
global with sharing class BI_LeadInfoSync {
	// 中継アプリの名
	private static final String APPNAME = 'TA';
	// Default チェックアウト時間
	// 2013/02/25 EDIT BEGIN	
	//private static final Time defaultCheckinTime = Time.newInstance(15,30,0,0);
	//private static final Time defaultCheckoutTime = Time.newInstance(10,30,0,0);
	// 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
	//private static final Time defaultCheckinTime = CommConst.defCheckInTime;
	//private static final Time defaultCheckoutTime = CommConst.defCheckOtTime;
	// 2013/02/25 EDIT END
	//private static final String defaultCheckInTimeStr = (DateTime.newInstance(Date.today(), defaultCheckinTime)).format('HH:mm');
	//private static final String defaultCheckoutTimeStr = (DateTime.newInstance(Date.today(), defaultCheckoutTime)).format('HH:mm');
    private static Time defaultCheckinTime;
    private static Time defaultCheckoutTime;
    private static String defaultCheckInTimeStr;
    private static String defaultCheckoutTimeStr;
	// 2013/12/10 日帰到着時刻初期値
	//private static final String defaultDayUseCheckInTime = CommConst.DEF_DAYUSE_CHECKIN_TIME;
    private static String defaultDayUseCheckInTime;
    private static String defaultDayUseCheckOtTime;
    // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
	// 2014/11/20 店舗別プラン設定機能判断フラグ
	private static final Boolean isPlanOfShopFlg = CommConst.APPOTION_BI_SHOPPLAN_FLG;
	// 2015/07/22 部屋自動割り当て
	private static Boolean oneRoomAutoAssingRoomFlg { get{ return CommDefine__c.getOrgDefaults().AdvancesReceivedChk__c; }}
	/*
	* 外部から予約データ連携機能
	*/
	webservice static BI_SyncResult upsertLeadInfo(
			BI_SyncInfo bookingInfo) {
		// 2017/06/30 XML特殊記号文字UTF-8対応 BEGIN
        unescapeXmlProcess(bookingInfo);
        // 2017/06/30 XML特殊記号文字UTF-8対応 END
		// 予約情報を更新を行う
System.debug(logginglevel.INFO,bookingInfo);
		BI_SyncResult rs = new BI_SyncResult();
        // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
        String shopCd = bookingInfo.AccommodationCode;
        ShopInfoUtil.ShopLeadInfo shopInfo = ShopInfoUtil.getShopDefInfo(shopCd);
        defaultCheckinTime = shopInfo.defCheckInTime;
        defaultCheckoutTime = shopInfo.defCheckOtTime;
        defaultCheckInTimeStr = shopInfo.defCheckInTimeStr;
        defaultCheckoutTimeStr = shopInfo.defCheckOtTimeStr;
        defaultDayUseCheckInTime = shopInfo.defDayUseCheckInTimeStr;
        defaultDayUseCheckOtTime = shopInfo.defDayUseCheckOtTimeStr;
        // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
		// 2013/06/20 変更ステータス連携対象外
		if (bookingInfo.dmlAction == BI_DmlAction.UPD ||
			bookingInfo.dmlAction == BI_DmlAction.CANCEL) {
            // Data発生源の条件を追加する
            String dataFrom = bookingInfo.DataFrom;
			// 既存の予約インデックス情報を取得する
			// 2015/09/10 作成元情報のFilter条件に追加する BEGIN[And (APPNAME__c = :APPNAME OR APPNAME__c = null]
			String pString = CommSqlUtils.generateQueryString('LeadIndex__c') + ' Where ID__c = \'' + String.escapeSingleQuotes(bookingInfo.DataID) + '\' And EventSource__c = :dataFrom And (APPNAME__c = :APPNAME OR APPNAME__c = null ) ';
			List<LeadIndex__c> rslst = Database.query(pString);
			if (rslst.isEmpty()) {
				//throw new CommException('更新する予約データが見つかりません。データID:(' + bookingInfo.DataID + ')');
				// 2013/07/17 仮に、データOKに設定する、overフォルダに移動する TODO:ERRORフォルダに移動対応が必要
				rs.result = BI_Result.OK;
				return rs;
			} else {
				// 予約インデックスのデータ種別に更新を行う
				rslst[0].DataClassification__c = bookingInfo.dmlAction.name();
				// 2015/09/10 ADD BEGIN
				rslst[0].APPNAME__c = APPNAME;
				// 2015/09/10 ADD END
				update rslst[0];
			}
			rs.sfdcId = rslst[0].Id;
			rs.result = BI_Result.OK;
			return rs;
		}
		try {
			// 旅行会社情報の新規・更新を行う
			Account[] traveCompany = upsertTravelInfo(bookingInfo);
			// 団体代表者の情報は顧客へ登録する
			Contact pkuser = upsertContact(bookingInfo);
			// 予約インデックスオブジェクト
			LeadIndex__c leadIndex = upsertLeadIndex(bookingInfo, pkuser);
			// 予約データを作成する　
			upsertLead(bookingInfo, leadIndex, pkuser, traveCompany);
			// 処理結果設定を行う
			rs.sfdcId = leadIndex.Id;
			rs.result = BI_Result.OK;
		} catch (CommException ex) {
			System.debug(ex.getMessage());
			rs.result = BI_Result.NG;
			rs.message = ex.getMessage();
		} catch (Exception e) {
			System.debug(e.getMessage());
			rs.result = BI_Result.NG;
			rs.message = e.getMessage();
		}
		return rs;
	}

	/**
	* 予約基本情報
	**/
	private static LeadIndex__c upsertLeadIndex(BI_SyncInfo bookingInfo, Contact pkuser) {
		LeadIndex__c leadIndex;
		// ネット旅行Agency
		// 更新/キャンセル場合:存在チェックを行う
		if (bookingInfo.dmlAction == BI_DmlAction.UPD ||
			bookingInfo.dmlAction == BI_DmlAction.CANCEL) {
			// 2013/07/14 DELETE 更新・キャンセル機能削除
			/*
            // Data発生源の条件を追加する
            String dataFrom = bookingInfo.DataFrom;
			// 既存の予約インデックス情報を取得する
			String pString = CommSqlUtils.generateQueryString('LeadIndex__c') + ' Where ID__c = \'' + String.escapeSingleQuotes(bookingInfo.DataID) + '\' And EventSource__c = :dataFrom ';
			List<LeadIndex__c> rslst = Database.query(pString);
			if (rslst.isEmpty()) {
				throw new CommException('更新する予約データが見つかりません。データID:(' + bookingInfo.DataID + ')');
			}
			leadIndex = rslst[0];
			
			// キャンセルステータスに変更する
			if (bookingInfo.dmlAction == BI_DmlAction.CANCEL) {
				leadIndex.StatusLst__c = CommConst.LEAD_ST_CANCEL;
			}
            // 2012/12/24 Upsert Index Info
            DateTime checkInDt = (bookingInfo.CheckInTime == null ? null : DateTime.newInstance(bookingInfo.CheckInDate, bookingInfo.CheckInTime));
            leadIndex.EventSource__c = bookingInfo.DataFrom;
            leadIndex.EntryDate__c = bookingInfo.CheckInDate;
            leadIndex.EntryTime__c = checkInDt == null ? null : checkInDt.format('HH:mm');
            leadIndex.DepartureDate__c = bookingInfo.CheckOutDate;
            // チェックアウト時間はDefault値設定を行う
            leadIndex.DepartureTime__c = defaultCheckoutTimeStr;
            leadIndex.Nights__c = bookingInfo.Nights;
			// 2012/12/23 ADD
			leadIndex.contactRef__c = pkuser.Id; 
			leadIndex.Rooms__c = (bookingInfo.TotalRoomCount == null || bookingInfo.TotalRoomCount == 0) ? 
								bookingInfo.roomAndGuestLst.size() : bookingInfo.TotalRoomCount;
			// 2013/08/16 予約名設定追加
			leadIndex.LeadName__c = bookingInfo.GuestOrGroupNameKanjiName;
			// 2013/09/10 特記事項設定追加
			leadIndex.Comment__c = bookingInfo.OtherServiceInformation;
			update leadIndex;
			
			// 既存のSUBINDEXを削除を行う
			delete [select id from LeadIndex__c where ParentLeadIndxRef__c = :leadIndex.Id];
			*/
		} else {
			// 新規データ作成を行う
			DateTime checkInDt = (bookingInfo.CheckInTime == null ? null : DateTime.newInstance(bookingInfo.CheckInDate, bookingInfo.CheckInTime));
			leadIndex = new LeadIndex__c();
            // 2015/09/10 ADD BEGIN
            leadIndex.APPNAME__c = APPNAME;
            // 2015/09/10 ADD END
			leadIndex.DataClassification__c = bookingInfo.dmlAction.name();
			leadIndex.EventSource__c = bookingInfo.DataFrom;
			leadIndex.ID__c = bookingInfo.DataID;
			leadIndex.EntryDate__c = bookingInfo.CheckInDate;
			leadIndex.EntryTime__c = checkInDt == null ? (bookingInfo.Nights == 0 ? defaultDayUseCheckInTime : defaultCheckInTimeStr) : checkInDt.format('HH:mm');
			leadIndex.DepartureDate__c = bookingInfo.CheckOutDate;
			// チェックアウト時間はDefault値設定を行う
			leadIndex.DepartureTime__c = (	bookingInfo.CheckOutTime == null
																	? (bookingInfo.Nights == 0 
																	// 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
																	//	? (DateTime.newInstance(Date.today(), CommUtils.stringToTime(leadIndex.EntryTime__c).addHours(CommConst.DEF_DAYUSE_STAY_HOURS))).format('HH:mm') 
	                                                                    ? ( (bookingInfo.CheckOutTime == null && bookingInfo.CheckInTime == null) 
	                                                                       ? defaultDayUseCheckOtTime
	                                                                       : (DateTime.newInstance(Date.today(), CommUtils.stringToTime(leadIndex.EntryTime__c).addHours(CommConst.DEF_DAYUSE_STAY_HOURS))).format('HH:mm') 
	                                                                       )
																	// 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
																		: defaultCheckoutTimeStr) 
																	: (DateTime.newInstance(bookingInfo.CheckOutDate, bookingInfo.CheckOutTime)).format('HH:mm')
																);
			leadIndex.Nights__c = bookingInfo.Nights;
			// 2012/12/23 ADD
			leadIndex.contactRef__c = pkuser.Id;
			leadIndex.Rooms__c = (bookingInfo.TotalRoomCount == null || bookingInfo.TotalRoomCount == 0) ? 
								bookingInfo.roomAndGuestLst.size() : bookingInfo.TotalRoomCount;
			// 2013/08/16 予約名設定追加
			//leadIndex.LeadName__c = bookingInfo.GuestOrGroupNameKanjiName;
			leadIndex.LeadName__c = pkuser.LastName + ' ' + CommUtils.nullToBLank(pkuser.FirstName);
			// 2013/09/10 特記事項設定追加
			leadIndex.Comment__c = bookingInfo.OtherServiceInformation;
			
			insert leadIndex;
		}
		return leadIndex;
	}
	/**
	* プラン情報を設定する
	* 2012.10.09: プラン機能変更：
    * ①XMLにプラン情報はない場合、プラン参照設定しない
    * ②XMLにプラン情報あり、プラン定義情報に、
    * ③プランコードと一致するプラン情報が存在する場合、参照関係に登録する
	**/
	private static Plan__c upsertPlan(BI_SyncInfo bookingInfo, Account TraveCompany) {
		// プランのPackageCode/プラン名は両方とも存在する場合、処理対象です
		if (  CommUtils.isBlank(bookingInfo.PackagePlanName) &&
		      CommUtils.isBlank(bookingInfo.PackagePlanCode)) { return null; }
		// 情報が存在する場合、登録処理を行う
		// 同じプランPackageCode/AGT(SalesOfficeCompanyName)のプラン情報を検索する
		Plan__c rsPlan = null;
		//List<Plan__c> existPlanLst = [select Id, name from Plan__c Where name = :bookingInfo.PackagePlanName limit 1];
		// コードが存在する場合、コードで検索する
		// 2014/06/06 プラン検索方式変更
		List<Plan__c> existPlanLst = new List<Plan__c>();
		/*
		if (!CommUtils.isBlank(bookingInfo.PackagePlanCode)) {
			existPlanLst = [select Id, name from Plan__c Where PackageCode__c = :bookingInfo.PackagePlanCode And client__c = :TraveCompany.Id limit 1];
		} else if (!CommUtils.isBlank(bookingInfo.PackagePlanName)) {
			existPlanLst = [select Id, name from Plan__c Where name = :bookingInfo.PackagePlanName And client__c = :TraveCompany.Id limit 1];
		}*/
		String packageCode = bookingInfo.PackagePlanCode;
		String packageName = bookingInfo.PackagePlanName;
		String agtId = TraveCompany == null ? null : TraveCompany.Id;
		String shopCode = bookingInfo.AccommodationCode;
		// 店舗情報格納する
		Map<String, ShopInformation__c> shopInfoMap = new Map<String, ShopInformation__c>(); 
		/* 2014.11.18 プラン検索ロジック変更、店舗検索機能を追加 */
		String queryHeader = ' select Id, name from Plan__c ';
		String queryLimit = ' limit 1 ';
		// 2014/07/16 非公開プランは検索対象外に対応
		String whereStr = ' Where IsClosed__c != true And (';
		// 店舗別単位でプラン設定する場合、店舗コードとプランのPackageCodeは合わせる確認が必要です
		if (isPlanOfShopFlg) {
			shopInfoMap = ShopInfoUtil.getShopInfoMap();
			whereStr += ' PackageCode__c != null And PackageCode__c = :packageCode And ShopInfoRef__c != null And ShopInfoRef__r.ShopCode__c = :shopCode  ';
		} else {
			if (!CommUtils.isBlank(packageCode)) {
				whereStr += ' PackageCode__c = :packageCode ';
			}
			if (!CommUtils.isBlank(packageName)) {
				if (!CommUtils.isBlank(packageCode)) { whereStr += ' Or '; }
				whereStr += ' name = :packageName ';
			}
		}
		whereStr += ')';
		String whereStr2 = '';
		if (!CommUtils.isBlank(agtId)) {
			// AGT情報がXMLに設定されている場合、AGT条件に入れて、検索を行う
			whereStr2 = ' And client__c = :agtId ';
			existPlanLst = DataBase.query(queryHeader + whereStr + whereStr2 + queryLimit);
		}
		if (existPlanLst.isEmpty()) {
			existPlanLst = DataBase.query(queryHeader + whereStr + queryLimit);
		}
		/*
		if (!CommUtils.isBlank(bookingInfo.PackagePlanCode)) {
			whereStr += ' PackageCode__c = :packageCode ';
		}
		if (!CommUtils.isBlank(bookingInfo.PackagePlanName)) {
			if (!CommUtils.isBlank(bookingInfo.PackagePlanCode)) { whereStr += ' Or '; }
			whereStr += ' name = :packageName ';
		}
		whereStr += ')';
		String whereStr2 = '';
		if (!CommUtils.isBlank(agtId)) {
			whereStr2 = ' And client__c = :agtId ';
		}
		String queryHeader = ' select Id, name from Plan__c ';
		String queryLimit = ' limit 1 ';
		existPlanLst = DataBase.query(queryHeader + whereStr + whereStr2 + queryLimit);
		if (existPlanLst.isEmpty()) {
			existPlanLst = DataBase.query(queryHeader + whereStr + queryLimit);
		}*/
		//List<Plan__c> existPlanLst = [select Id, name from Plan__c Where PackageCode__c = :bookingInfo.PackagePlanCode And client__c = :TraveCompany.Id limit 1];
		// Plan非存在する場合：新規作成
		if (existPlanLst.isEmpty()) {
			rsPlan = new Plan__c();
			// 2014/12/12 プラン所属支店情報を設定
			rsPlan.ShopInfoRef__c = shopInfoMap.containsKey(shopCode) ? shopInfoMap.get(shopCode).Id : null;
			//rsPlan.name = bookingInfo.PackagePlanName;
			rsPlan.name = CommUtils.nullToBlank(bookingInfo.PackagePlanName).length() > 80 ? bookingInfo.PackagePlanName.subString(0,80) : bookingInfo.PackagePlanName;
			// 自動採番で設定を行う
			// rsPlan.PlanNo__c = bookingInfo.PackagePlanCode;
			rsPlan.PackageCode__c = bookingInfo.PackagePlanCode;
			rsPlan.client__c = agtId;
			insert rsPlan;
		}  else {
            rsPlan = existPlanLst[0];
		}
		return rsPlan;
	}
	/**
	* 予約情報を登録するrsPlan = existPlanLst[0];
	*/
	private static void upsertLead(BI_SyncInfo bookingInfo, LeadIndex__c leadIndex, Contact pkuser, Account[] TraveCompany) {
		// 予約キャンセル　と　更新場合:　既存予約データを全部キャンセルする
		if (bookingInfo.dmlAction == BI_DmlAction.UPD ||
			bookingInfo.dmlAction == BI_DmlAction.CANCEL) {
			// 既存予約データをキャンセルする
			List<Lead__c> existLeadLst = [select id, ReservedStatus__c, Comment3__c from Lead__c where LeadIndexRef__c = :leadIndex.Id And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG];
			for (Lead__c lead : existLeadLst) {
				lead.ReservedStatus__c = CommConst.LEAD_ST_CANCEL;
				//キャンセル対応(外部インタネットから自動連携)
				lead.Comment3__c = CommUtils.nullToBlank(lead.Comment3__c) + '\n' + System.now().format('yyyy/MM/dd HH:mm:ss:SSS') + ' '+ Label.CONST_044_0001;
			}
			update existLeadLst;
		}
		// キャンセル場合、処理中止
		if (bookingInfo.dmlAction == BI_DmlAction.CANCEL) return;

		//  プラン情報を取得、作成する
		Plan__c curPlan = upsertPlan(bookingInfo, TraveCompany[0]);
		
		// メール本文
		String emailMsg = mailArea(bookingInfo);

		// 部屋タイプID情報を取得する
		Set<String> roomTypeCdSet = new Set<String>();
		// 2013/02/26 部屋タイプ名情報を格納する
		Set<String> roomTypeNmSet = new Set<String>();
		
		for (BI_RoomAndGuestInfo roomAndGuest: bookingInfo.roomAndGuestLst) {
			roomTypeCdSet.add(roomAndGuest.room.RoomTypeCode);
			//roomTypeMap.put(roomAndGuest.room.RoomTypeCode);
            // 2013/02/26 部屋タイプ名：部屋ID情報を格納する
			if (!CommUtils.isBlank(roomAndGuest.room.RoomTypeName)) roomTypeNmSet.add(roomAndGuest.room.RoomTypeName);
		}
		// 部屋タイプMAP情報設定する
		Map<String,Id> roomTypeMap = new Map<String, Id>();
		// 2013/02/26 部屋タイプ名情報を格納する
		Map<String,Id> roomTypeNmMap = new Map<String, Id>();
		 
		for (TypeOfRooms__c roomType: [select id, RoomTypeName__c, RoomTypeCode__c from TypeOfRooms__c where RoomTypeCode__c in :roomTypeCdSet Or RoomTypeName__c in :roomTypeNmSet]) {
			roomTypeMap.put(roomType.RoomTypeCode__c, roomType.Id);
			// 2013/02/26 部屋タイプ名：部屋ID情報を格納する
			if (!CommUtils.isBlank(roomType.RoomTypeName__c)) roomTypeNmMap.put(roomType.RoomTypeName__c, roomType.Id);
		}
		// 2015/07/22  部屋タイプが存在　かつ　対応部屋タイプに対して、１部屋のみの場合、該当部屋は自動的に予約にアサインする BEGIN
        Map<Id, id> oneTypeToRoomMap = new Map<Id, Id>();
        // 2016/10/19 部屋タイプと部屋が1対1の場合は故障部屋を割当される不具合改修 BEGIN
        map<Integer, Room__c> oneRoomCanAssignRoomMap = new map<Integer, Room__c>();
        // 自動割り当てフラグはTRUEのみ、該当関連取得を行う
		if (oneRoomAutoAssingRoomFlg) {
			for ( TypeOfRooms__c r : [Select id, (Select Id From TypeRoomRef__r limit 2) From TypeOfRooms__c] ) {
			    if (r.TypeRoomRef__r != null && r.TypeRoomRef__r.size() == 1) {
					oneTypeToRoomMap.put( r.Id, r.TypeRoomRef__r[0].Id );
			    }
			}
			// 部屋タイプが存在する場合
	        if (!oneTypeToRoomMap.isEmpty()) {
	        	// 割当できる部屋情報を取得する　
	        	oneRoomCanAssignRoomMap = getCanAssignRoom(leadIndex,roomTypeMap,bookingInfo);
	        }
		}
		// 2016/10/19 部屋タイプと部屋が1対1の場合は故障部屋を割当される不具合改修 END
		// 2015/07/22  部屋タイプが存在　かつ　対応部屋タイプに対して、１部屋のみの場合、該当部屋は自動的に予約にアサインする END
		// 宿泊レコードタイプ
    	String bookingRcTypeId = CommLogicProcess.getLeadBookingRecType();
    	// 受付日
    	//DateTime reserverDt = DateTime.newInstance(bookingInfo.TravelAgencyBookingDate, bookingInfo.TravelAgencyBookingTime);
    	// チェックイン日付・日時[基本宿泊情報から]
    	DateTime checkInFirstDayDt = DateTime.newInstance(leadIndex.EntryDate__c,
    		bookingInfo.CheckInTime == null ? defaultCheckinTime : bookingInfo.CheckInTime);
    	// 最後日のチェックアウト日付・日時[基本宿泊情報から]
    	DateTime checkOutLastDayDt = DateTime.newInstance(leadIndex.DepartureDate__c, 
    		bookingInfo.CheckOutTime == null ? defaultCheckoutTime : bookingInfo.CheckOutTime);
    	//newLead.RecordTypeId = s.id;
        // 予約名
        String leadName = leadIndex.LeadName__c;
        
    	Integer roomNoIdx = 0;
		// 複数件予約データを作成する
		List<Lead__c> insLeadLst = new List<Lead__c>();
		// 複数予約日ー＞複数部屋タイプから　１部屋タイプ１日予約データを作成する
		for (BI_RoomAndGuestInfo roomAndGuest: bookingInfo.roomAndGuestLst) {
			// １部屋タイプから複数日予約データを作成する
			// 複数日から１日単位に作成する
			Integer staysNums = roomAndGuest.roomDateLst.size();
			// 日付単位情報
			for(Integer i = 0; i < staysNums; i ++){
				//　到着日
				Date checkInDate = roomAndGuest.roomDateLst[i];
				// 新規予約データ作成
				Lead__c newLead = new Lead__c();
				// 予約データ名設定を行う
				//泊目
				if (staysNums > 1) newLead.name = String.valueOf(staysNums) + '-' + (i+1) + Label.CONST_044_0002 + leadName;
				else newLead.name = leadName;
				// レコードタイプ：宿泊タイプ
				newLead.RecordTypeId = bookingRcTypeId;
				// お客様情報
				newLead.Relcontact__c = pkuser.Id;
				// 予約受付日
				// 2013/06/19 予約受付日の受付時間設定ミス、不具合修正、時間項目を設定する
				newLead.ReservedDate__c = DateTime.newInstance(bookingInfo.TravelAgencyBookingDate, bookingInfo.TravelAgencyBookingTime );
                // 2014/12/02 支払方法
                newLead.Field315__c = bookingInfo.basicRateInfo.Payment;
				// 予約ステータス[Deafult:確認中]
				//newLead.ReservedStatus__c =
				// First Dayの場合
				if (i == 0) {
					// チェックイン日
					// 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
					//newLead.EntryTime__c = checkInFirstDayDt;
					// 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
					// チェックイン時間
					newLead.Field4__c = (bookingInfo.CheckInTime == null 
						// DayUserの場合の時刻情報
						?  (bookingInfo.Nights == 0 ? defaultDayUseCheckInTime : defaultCheckInTimeStr)
						:  (DateTime.newInstance(Date.today(), bookingInfo.CheckInTime)).format('HH:mm') );
					// 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
					newLead.EntryTime__c = DateTime.newInstance(checkInFirstDayDt.date(), CommUtils.stringToTime(newLead.Field4__c));
					// 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
				} else {
					// チェックイン日
					newLead.EntryTime__c = DateTime.newInstance(checkInDate, defaultCheckinTime);
					// チェックイン時間
					newLead.Field4__c = defaultCheckInTimeStr;
				}
				// 最後日の場合
				if (i == staysNums - 1) {
					// チェックアウト日
					// 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
					//newLead.Departure__c = checkOutLastDayDt;
					// 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
					newLead.Field3__c = (bookingInfo.CheckOutTime == null 
						// DayUserの場合の時刻情報
						? (bookingInfo.Nights == 0
                                // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
								//? (DateTime.newInstance(Date.today(), CommUtils.stringToTime(newLead.Field4__c).addHours(CommConst.DEF_DAYUSE_STAY_HOURS))).format('HH:mm')
                                ? ((bookingInfo.CheckOutTime == null && bookingInfo.CheckInTime == null)
                                    ? defaultDayUseCheckOtTime
                                    : (DateTime.newInstance(Date.today(), CommUtils.stringToTime(newLead.Field4__c).addHours(CommConst.DEF_DAYUSE_STAY_HOURS))).format('HH:mm')
                                )
                                // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
								: defaultCheckoutTimeStr)
						: (DateTime.newInstance(Date.today(), bookingInfo.CheckOutTime)).format('HH:mm') );
						
					// 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
					newLead.Departure__c = DateTime.newInstance(checkOutLastDayDt.date(), CommUtils.stringToTime(newLead.Field3__c));
					// 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
				} else {
					// チェックアウト日
					newLead.Departure__c = DateTime.newInstance(checkInDate.addDays(1), defaultCheckoutTime);
					// チェックアウト時間
					newLead.Field3__c = defaultCheckoutTimeStr;
				}
				// チェックアウト時間
				//newLead.Field3__c = defaultCheckoutTimeStr;
				// 部屋タイプID
				newLead.refTypeOfRooms__c = roomTypeMap.get(roomAndGuest.room.RoomTypeCode);
				// 2013/02/26 部屋タイプ名：部屋ID情報を格納する
				if (newLead.refTypeOfRooms__c == null ) newLead.refTypeOfRooms__c = roomTypeNmMap.get(roomAndGuest.room.RoomTypeName);
				// 2015/07/22  部屋タイプが存在　かつ　対応部屋タイプに対して、１部屋のみの場合、該当部屋は自動的に予約にアサインする BEGIN
				// 2016/10/19 部屋タイプと部屋が1対1の場合は故障部屋を割当される不具合改修 BEGIN
				//if(newLead.refTypeOfRooms__c != null && oneTypeToRoomMap.containsKey(newLead.refTypeOfRooms__c)){
				if(newLead.refTypeOfRooms__c != null && oneTypeToRoomMap.containsKey(newLead.refTypeOfRooms__c) && oneRoomCanAssignRoomMap.containsKey(roomNoIdx)){
				// 2016/10/19 部屋タイプと部屋が1対1の場合は故障部屋を割当される不具合改修 END
					newLead.Rroom__c = oneTypeToRoomMap.get(newLead.refTypeOfRooms__c);
				}
				// 2015/07/22  部屋タイプが存在　かつ　対応部屋タイプに対して、１部屋のみの場合、該当部屋は自動的に予約にアサインする END
				// 1室利用人数
				newLead.StayPersons__c = roomAndGuest.room.PerRoomPaxCount;
				// 大人人員(男性)
				newLead.Mans__c = roomAndGuest.room.RoomPaxMaleCount;
				// 大人人員(女性)
				newLead.Femails__c = roomAndGuest.room.RoomPaxFemaleCount;
				// 子供A人数
				newLead.ChildFA__c = roomAndGuest.room.RoomChildA70Count;
				//　予約インデックスID
				newLead.LeadIndexRef__c = leadIndex.Id;
				// プラン情報
				newLead.Field310__c = (curPlan == null ? null : curPlan.Id);
				// 特記事項設定
				newLead.Comment3__c = bookingInfo.OtherServiceInformation;
				// 旅行会社関連参照情報設定
				newLead.SalesOfficeInfoRef__c = TraveCompany[1] == null ? (TraveCompany[0] == null ? null : TraveCompany[0].Id) : TraveCompany[1].Id;
				// 2012/10/12 ADD <SalesOfficeCompanyName>を予約チャネルへ設定する
				newLead.Field2__c = TraveCompany[0] != null ? 'AGT[' + TraveCompany[0].Name + ']' : '';
//System.debug('bookingInfo.OtherServiceInformation:' + bookingInfo.OtherServiceInformation);
//System.debug('newLead.Comment3__c:' + newLead.Comment3__c);
				// 2012/12/23  Add
				newLead.RoomGroupNo__c = roomNoIdx;
				// メール本文
				newLead.email__c = emailMsg ;
				// 2016/10/10 在庫変更処理対応(発生源) BEGIN by zh
				newLead.EventSource__c = APPNAME + '_' + bookingInfo.DataID + '_' + DateTime.now().getTime();
				// 2016/10/10 在庫変更処理対応(発生源) END by zh
				insLeadLst.add(newLead);
			}
			roomNoIdx++;
		}
		// 見積り金額設定を行う「一件のみ設定する」
		//insLeadLst[0].BridalDantaikei__c = bookingInfo.TotalAccommodationCharge;
  		insLeadLst[0].BridalDantaikei__c = bookingInfo.basicRateInfo.TotalAccommodationCharge;
  		// 2012/12/22 WSQ ADD
  		// SUBINDEX自動作成
  		CommLogicProcess logic = new CommLogicProcess();
  		logic.autoCreateIndexSub(insLeadLst);
  		// 2017/05/04 店舗ごとの予約・会計権限機能対応 BEGIN
		logic.preventShopAuthCheckSetup(insLeadLst);
		// 2017/05/04 店舗ごとの予約・会計権限機能対応 END	
		insert insLeadLst;
		// 2017/05/04 店舗ごとの予約・会計権限機能対応 BEGIN
		List<Lead__c> restoreLeads = new List<Lead__c>();
		restoreLeads.addAll(insLeadLst);
		logic.restoreShopAuthCheckSetup(restoreLeads, true);
		// 2017/05/04 店舗ごとの予約・会計権限機能対応 END
	}
	
    // 2013/12/28
    // メール本文情報を設定する
    private static String mailArea(BI_LeadInfoSync.BI_SyncInfo bookingInfo){
    	String mailString = '';
    	// 代表者情報
		String roomMsg = '';
		// 宿泊者情報
		String guestMsg = '';
		// XMLに記載する宿泊者情報を取得する
		for (Contact c : contactsLst) {
System.debug(LoggingLevel.INFO, 'C::::' + c);
			guestMsg += '\n';
			guestMsg += c.lastName + ' ' + c.firstName + ( CommUtils.isBlank(c.KanaName1__c) ? '' : '(' + c.KanaName1__c + ')' );
			// メール
			if (!CommUtils.isBlank(c.Email)) guestMsg += '\nMail: ' + c.Email;
			// 住所情報
			if (!CommUtils.isBlank(c.MailingStreet)) {
				//住所:
				guestMsg += '\n'+ Label.CONST_044_0003 +' ';
				if (!CommUtils.isBlank(c.MailingPostalCode)) guestMsg += '(〒'+c.MailingPostalCode+')';
				guestMsg += CommUtils.nullToBlank(c.MailingStreet); 
			}
			
			// 性別、電話番号、緊急連絡先、
			guestMsg += '\n';
			//性別:
			if (!CommUtils.isBlank(c.gender__c)) guestMsg += ' '+ Label.CONST_044_0005 +' ' + c.gender__c;
			//電話:
			if (!CommUtils.isBlank(c.Phone)) guestMsg += ' '+ Label.CONST_044_0006 +' ' + c.Phone;
			//緊急連絡先:
			if (!CommUtils.isBlank(c.Phone2__c)) guestMsg += ' '+ Label.CONST_044_0007 +' ' + c.Phone2__c;
		}
		
		
		// XML部屋と料金情報を取得する
		for(BI_LeadInfoSync.BI_RoomAndGuestInfo roomGuestInfo : bookingInfo.roomAndGuestLst){
			// RoomInformation[部屋タイプ定義情報]
			
			BI_RoomsInfo roomInfo = roomGuestInfo.room;
			/*
			if (!CommUtils.isBlank(roomInfo.RoomSpecialRequest)) {
				roomRequestMsg += '\n' + roomInfo.RoomTypeCode + ( CommUtils.isBlank(roomInfo.RoomTypeName) ? ' ' : ' (' + roomInfo.RoomTypeName +') ') + ':' + bookingInfo.RoomSpecialRequest;
			}*/ 
			//料金明细
			Map<Date,String> dateToDetail = new Map<Date,String>();
			/* 2014/03/14 特別リクエスト分析取り消し（ルールが不明の状態）
			if (!CommUtils.isBlank(bookingInfo.SpecialServiceRequest)) {
					for(String serviceReq : bookingInfo.SpecialServiceRequest.split(',ZZ')){
						String detailMsg = '';
						String dateStr = serviceReq.subString(serviceReq.lastindexOf('Z') + 1,serviceReq.lastindexOf('Z') + 11);
						detailMsg = '\n' + serviceReq.subString(serviceReq.lastindexOf('Z') + 1,serviceReq.length());
						Date detailDate = CommUtils.stringToDate(dateStr);
						
						dateToDetail.put(detailDate,detailMsg);
					}
				} */
			// 部屋設定料金情報を取得する
			
			for(Date roomRate : roomGuestInfo.roomDateLst){
				roomMsg += '\n';
				//yyyy年MM月dd日
				roomMsg += (DateTime.newInstance(roomRate.year(), roomRate.month(), roomRate.day()).format(Label.CONST_044_0008))  + 
							' ' + roomInfo.RoomTypeCode + ( CommUtils.isBlank(roomInfo.RoomTypeName) ? ' ' : ' (' + roomInfo.RoomTypeName +') ');
				if(roomInfo.RoomPaxMaleCount > 0 ){
					//大人（男）
					//名
					roomMsg += '\n'+ Label.CONST_044_0009 +' ' + roomInfo.RoomPaxMaleCount + Label.CONST_044_0010;
				}
				if(roomInfo.RoomPaxFemaleCount > 0 ){
					//大人（女）
					//名
					roomMsg += '\n'+ Label.CONST_044_0011 +' ' + roomInfo.RoomPaxFemaleCount + Label.CONST_044_0010;
				}
				// 子供人数
				Integer childCount = CommUtils.nullToZero(roomInfo.RoomChildA70Count);
				//子供
				//名
				if(childCount > 0 ) roomMsg += '\n'+ Label.CONST_044_0012 +' 　　　' + childCount + Label.CONST_044_0010;
				if(dateToDetail.containsKey(roomRate)){
					roomMsg += dateToDetail.get(roomRate);
					dateToDetail.remove(roomRate);
				
				}
			}
		}
		// 2014/12/01 料金区分連携項目を追加
		roomMsg += '\n\n';
		//料金区分:
		roomMsg += Label.CONST_044_0013 +' ' + bookingInfo.basicRateInfo.RoomRateOrPersonalRate + '\n';
		//税サ区分:
		roomMsg += Label.CONST_044_0014 +' ' + bookingInfo.basicRateInfo.TaxServiceFee + '\n';
		//支払い方法：
		roomMsg += Label.CONST_044_0015 +  CommUtils.nullToBlank(bookingInfo.basicRateInfo.Payment) + '\n';

		//roomMsg += '\n\n 宿泊料金計: ¥' + bookingInfo.TotalAccommodationCharge + '\n';
		//宿泊料金計:
		roomMsg += '\n '+ Label.CONST_044_0016 +' ¥' + bookingInfo.basicRateInfo.TotalAccommodationCharge + '\n';
		//【宿泊者への請求額】 ： \42,000
		if (bookingInfo.member != null ) {
			BI_MemberInfo member = bookingInfo.member;
			roomMsg += '\n';
			//使用ポイント
			if (member.UserUsePoints != null && member.UserUsePoints > 0) roomMsg += '\n 【'+ Label.CONST_044_0017 +'】： ' + member.UserUsePoints;
			//宿泊者への請求額
			if (member.AmountClaimed != null && member.AmountClaimed > 0) roomMsg += '\n 【'+ Label.CONST_044_0018 +'】： ¥' + member.AmountClaimed;
		}
		
		//予約通知：
		mailString +=	Label.CONST_044_0019 +' '+ bookingInfo.SalesOfficeCompanyName + '(' + bookingInfo.SalesOfficeCompanyCode +')';
		//予約番号：
		mailString +=	'\n' + Label.CONST_044_0020 +' ' + bookingInfo.TravelAgencyBookingNumber;
		
		//-------------------施設情報----------------------
		if(!CommUtils.isBlank(bookingInfo.AccommodationName))
		//様
		mailString +=	' ' + bookingInfo.AccommodationName +Label.CONST_044_0021 + ( CommUtils.isBlank(bookingInfo.AccommodationCode) == true ? '' : '(' + bookingInfo.AccommodationCode + ')' );
		
		mailString += 	'\n';
		//-------------------宿泊者情報----------------------
		//宿泊者情報：
		mailString += 	'\n' + Label.CONST_044_0022;
		/*
		if (!CommUtils.isBlank(bookingInfo.GuestOrGroupNameKanjiName)) {
			mailString += 	'\n' + bookingInfo.GuestOrGroupNameKanjiName
		}*/
		mailString += 	guestMsg;
		
		mailString += 	'\n';
		//-------------------予約者情報----------------------
		if (bookingInfo.member != null ) {
			BI_MemberInfo member = bookingInfo.member;
			//予約者情報：
			mailString += 	'\n' + Label.CONST_044_0023;
			if (!CommUtils.isBlank(member.UserName)) mailString += 	'\n' + member.UserName;
			if (!CommUtils.isBlank(member.UserKana)) mailString += 	'\n' + member.UserKana;
			//会社：
			if (!CommUtils.isBlank(member.UserCorp)) mailString += 	'\n' + Label.CONST_044_0024 +member.UserCorp;
			if (!CommUtils.isBlank(member.UserTel)) mailString += 	'\n' + 'TEL：'+member.UserTel;
			if (!CommUtils.isBlank(member.UserMailAddr)) mailString += 	'\n' + 'MAIL：'+member.UserMailAddr;
			//住所：
			if (!CommUtils.isBlank(member.UserAddr)) mailString += 	'\n' + Label.CONST_044_0025 +member.UserAddr;
		}
		//-------------------プラン情報----------------------
		mailString += 	'\n';
		//プラン名：
		mailString += 	'\n' + Label.CONST_044_0026 + bookingInfo.PackagePlanName + '(' + bookingInfo.PackagePlanCode + ')' + '\n';
		Date ciDate = bookingInfo.CheckInDate;
		//yyyy年MM月dd日
		//から
		//泊
		mailString +=	'\n' + (DateTime.newInstance(ciDate.year(), ciDate.month(), ciDate.day())).format(Label.CONST_044_0027) + ' '+ Label.CONST_044_0028 + bookingInfo.Nights + Label.CONST_044_0029;

		
		if (bookingInfo.CheckInTime != null)
		//チェックイン時間：
		mailString +=	' '+ Label.CONST_044_0030 + CommUtils.nullToBlank((DateTime.newInstance(Date.today(), bookingInfo.CheckInTime)).format('HH:mm'));
		//人員総数：
		mailString += 	'\n' + Label.CONST_044_0031 + bookingInfo.GrandTotalPaxCount
		//客室総数：
				   + 	'\n' + Label.CONST_044_0032 + bookingInfo.TotalRoomCount;
		
		mailString += '\n';
		mailString += 	roomMsg
				   + '\n-------------------------------------------------';
		//-------------------ご確認事項----------------------	
		// 客室へリクエスト情報を作成する
		String roomRequestMsg = '';	 
		if (!CommUtils.isBlank(bookingInfo.OtherServiceInformation)) {
			mailString += '\n' + bookingInfo.OtherServiceInformation;
		}
		/*
		if (!CommUtils.isBlank(bookingInfo.SpecialServiceRequest)) {
			mailString += '\n\n' + bookingInfo.SpecialServiceRequest;
		}*/
		if(!CommUtils.isBlank(bookingInfo.SalesOfficeName)){
			//取扱個所：
			mailString += '\n' + Label.CONST_044_0033;
			mailString += '\n' + bookingInfo.SalesOfficeName + '(' + bookingInfo.SalesOfficeCode + ')';
			if (!CommUtils.isBlank(bookingInfo.SalesOfficePhoneNumber)) mailString += '		TEL' + bookingInfo.SalesOfficePhoneNumber;
		}
		System.debug(LoggingLevel.INFO,'========>\n  '+mailString);
		return mailString;
	}

	// 顧客リスト情報を変数に格納する
	private static List<Contact> contactsLst;
	/**
	* 代表者として、取引先責任者作成する
	**/
	private static Contact upsertContact(BI_SyncInfo bookingInfo) {
		// 既存の代表者が存在する場合　
		//List<Contact> pkContactLst = [select id, name, phone from Contact
		//	where name = :bookingInfo.GuestOrGroupNameSingleByte And Phone = :bookingInfo. ]
		// 代表者詳細情報を取得する[漢字名で]
		Map<String, Contact> contactMap = new Map<String, Contact>();
		Map<String, Contact> kanaNmMap = new Map<String, Contact>();
        contactsLst = new List<Contact>();
		//
		for (BI_RoomAndGuestInfo roomAndGuest: bookingInfo.roomAndGuestLst) {
			for (BI_GuestInfo guest : roomAndGuest.guestLst) {
				// 顧客名
				String contactNm = guest.GuestKanjiName;
				String contactKana = guest.GuestNameSingleByte;
				// すでに存在している情報はSKIPする
				if (contactMap.containsKey(contactNm) || kanaNmMap.containsKey(contactKana)) continue;

				// 新規存在の顧客情報を設定する
				Contact contactItem = new Contact();
				
				String[] contactNameArr = CommUtils.splitName(contactNm);
				String lastName = contactNameArr[0];
				String firstName = (contactNameArr.size() > 1 ? contactNameArr[1] : null);
				contactItem.LastName = lastName;
				contactItem.FirstName = firstName;
				// 漢字
				//contactItem.LastName = guest.GuestKanjiName;
				contactItem.Name1__c = guest.GuestKanjiName;
				// カナ
				contactItem.KanaName1__c = guest.GuestNameSingleByte;
				// ひらがな
				contactItem.Katakana__c = guest.GuestSurName;
				// Phone
				//contactItem.Phone = guest.GuestPhoneNumber;
                String locPhone = CommUtils.convTelphoneNumber(guest.GuestPhoneNumber);
                if (!CommUtils.isBlank(locPhone)) contactItem.Phone = guest.GuestPhoneNumber;
				// 緊急連絡先
				//contactItem.Phone2__c = guest.GuestEmergencyPhoneNumber;
				locPhone = CommUtils.convTelphoneNumber(guest.GuestEmergencyPhoneNumber);
                if (!CommUtils.isBlank(locPhone)) contactItem.Phone2__c = guest.GuestEmergencyPhoneNumber;
				// お客様Email
				contactItem.Email = guest.GuestEmail;
				// お客様住所都道府県
				contactItem.MailingStreet = guest.GuestStateProvidence;
				// MAPに、顧客上はMAPに格納する
				contactMap.put(contactNm, contactItem);
				// MAPに、顧客KANAはMAPに格納する(2014/06/18 ADD)
				kanaNmMap.put(guest.GuestNameSingleByte, contactItem);
				
				contactsLst.add(contactItem);
			}
		}
		
		Contact curContact = null;
		// 代表者情報は取得取得処理を行う
		//String primaryUsr = bookingInfo.GuestOrGroupNameKanjiName;
		String primaryUsr = CommUtils.isBlank(bookingInfo.GuestOrGroupNameKanjiName) 
							? bookingInfo.GuestOrGroupNameSingleByte 
							: bookingInfo.GuestOrGroupNameKanjiName;
		// 2015/06/05 ユーザー情報が未設定する場合、仮ユーザ情報を自動設定を行う BEGIN
		if (CommUtils.isBlank(primaryUsr)) {
			curContact = CommLogicProcess.getOrInsertTempContact();
			return curContact;
		} 
		String[] contactNameArr = CommUtils.splitName(primaryUsr);
		String lastName = contactNameArr[0];
		String firstName = (contactNameArr.size() > 1 ? contactNameArr[1] : null);
		
		// メンバー設定情報から代表者詳細情報を取得、登録する
		if (contactMap.containsKey(primaryUsr) || kanaNmMap.containskey(primaryUsr)) {
			curContact = contactMap.containsKey(primaryUsr) 
						? contactMap.get(primaryUsr)
						: kanaNmMap.get(primaryUsr);
			// 存在する場合、顧客情報はSFから情報存在チェックを行う
			//List<Contact> existContactLst = [select id from Contact where LastName = :primaryUsr and phone = :curContact.phone limit 1];
			//List<Contact> existContactLst = [select id from Contact where Name = :primaryUsr and phone = :curContact.phone limit 1];
			// 2015/06/05 SOSLでお客様情報を検索する
			//String phoneNumber = curContact.phone;
			String phoneNumber = CommUtils.convTelphoneNumber(curContact.phone);
			// 2017/12/14 SOSLキーチェック追加対応 BEGIN
			//if (CommUtils.isBlank(phoneNumber)) {
			if (!CommUtils.isValidateSoslKey(phoneNumber)) {
				//	curContact.phone = null;
				curContact.phone = CommUtils.isBlank(phoneNumber) ? null : phoneNumber;
				// 2017/12/14 SOSLキーチェック追加対応 END
				//insert curContact;
				//2016/05/24  お客様重複チェック対応 BEGIN
				curContact = (new CommLogicProcess()).upsertDuplicateErrorProcess(curContact);
				// 2016/05/24 お客様重複チェック対応 END
				return curContact;
			}
			//phoneNumber = CommUtils.convTelphoneNumber(phoneNumber);
			String fullName = (lastName + ' ' + CommUtils.nullToBlank(firstName)).trim();
			String kajiname = CommUtils.nullToblank(bookingInfo.GuestOrGroupNameKanjiName);
			String kanaName = CommUtils.nullToblank(bookingInfo.GuestOrGroupNameSingleByte);
			String kanaKana = CommUtils.nullToblank(bookingInfo.GuestOrGroupNameDoubleByte);
			//2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH BEGIN 
			// Email,Phone,Phone2__c取得項目を追加する
			String soslQuery = 'FIND :phoneNumber IN PHONE FIELDS RETURNING CONTACT (id, name, LastName,FirstName,Name1__c,KanaName1__c,Katakana__c,Email,Phone,Phone2__c where Name = :fullName ';
			//2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH END
			if (!CommUtils.isBlank(kajiname)) soslQuery += ' OR Name1__c =:kajiname ';
			if (!CommUtils.isBlank(kanaName)) soslQuery += ' OR KanaName1__c =:kanaName ';
			if (!CommUtils.isBlank(kanaKana)) soslQuery += ' OR Katakana__c =:kanaKana ';
			soslQuery += ' limit 1) ';
			List<List<Sobject>> existRs = search.query(soslQuery);
			List<Contact> existContactLst = existRs[0];
			// 存在する場合、更新を行う
			if (!existContactLst.isEmpty()) {
				// TODO UPDATE
				//2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH BEGIN 
				if (CommUtils.isBlank(curContact.Name1__c)) curContact.Name1__c = kajiname;
				if (CommUtils.isBlank(curContact.KanaName1__c)) curContact.KanaName1__c = kanaName;
				if (CommUtils.isBlank(curContact.Katakana__c)) curContact.Katakana__c = kanaKana;
			
				// 団体名または代表者氏名 漢字
				if(CommUtils.isBlank(existContactLst[0].Name1__c) && !CommUtils.isBlank(curContact.Name1__c))
					existContactLst[0].Name1__c = curContact.Name1__c;
				// 団体名または代表者氏名よみがな(半角)
				if(CommUtils.isBlank(existContactLst[0].KanaName1__c) && !CommUtils.isBlank(curContact.KanaName1__c))
					existContactLst[0].KanaName1__c = curContact.KanaName1__c;
				// ひらがな ←　団体名または代表者氏名よみか゛な(全角)
				if(CommUtils.isBlank(existContactLst[0].Katakana__c) && !CommUtils.isBlank(curContact.Katakana__c))
					existContactLst[0].Katakana__c = curContact.Katakana__c;
				// メール
				if(CommUtils.isBlank(existContactLst[0].Email) && !CommUtils.isBlank(curContact.Email))
					existContactLst[0].Email = curContact.Email;
				// Phone
				if(CommUtils.isBlank(existContactLst[0].Phone) && !CommUtils.isBlank(curContact.Phone))
					existContactLst[0].Phone = curContact.Phone;
				// 緊急連絡先
				if(CommUtils.isBlank(existContactLst[0].Phone2__c) && !CommUtils.isBlank(curContact.Phone2__c))
					existContactLst[0].Phone2__c = curContact.Phone2__c;
				// 更新を行う
				existContactLst[0] = (new CommLogicProcess()).upsertDuplicateErrorProcess(existContactLst[0]);
				//2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH END 
				curContact = existContactLst[0];
                //curContact.LastName = lastName;
                //curContact.FirstName = firstName;
                //curContact.Name1__c = bookingInfo.GuestOrGroupNameKanjiName;
                //curContact.KanaName1__c = bookingInfo.GuestOrGroupNameSingleByte;
                //curContact.Katakana__c = bookingInfo.GuestOrGroupNameDoubleByte;
                //update curContact;
			} else {
				// INSERT CONTACT
				 //2016/05/24  お客様重複チェック対応 BEGIN
				//insert curContact;
		        curContact = (new CommLogicProcess()).upsertDuplicateErrorProcess(curContact);
		        // 2016/05/24 お客様重複チェック対応 END
			}

		} else {
			// 非存在する場合（あり得ない）
			//throw new CommException('代表者情報の詳細情報を未設定するため、確認必要があり');
			// 代表者は顧客新規作成を行う
			curContact = new Contact(
				// 団体名または代表者氏名(半角)
				//LastName = bookingInfo.GuestOrGroupNameSingleByte,
                LastName = lastName,
                FirstName = firstName,
				// 団体名または代表者氏名 漢字
				Name1__c = bookingInfo.GuestOrGroupNameKanjiName,
				// 団体名または代表者氏名よみがな(全角)
				//KanaName1__c = bookingInfo.GuestOrGroupNameDoubleByte
				KanaName1__c = bookingInfo.GuestOrGroupNameSingleByte,
				// ひらかな
				Katakana__c = bookingInfo.GuestOrGroupNameDoubleByte
			 );
			//2016/05/24  お客様重複チェック対応 BEGIN
			//insert curContact;
			curContact = (new CommLogicProcess()).upsertDuplicateErrorProcess(curContact);
			// 2016/05/24 お客様重複チェック対応 END
		}
		return curContact;
	}

    // 故障部屋は自動割当て機能に追加対応 BEGIN
	private static map<Integer,Room__c> getCanAssignRoom(LeadIndex__c leadIndex, Map<String,Id> roomTypeMap, BI_SyncInfo bookingInfo){
//System.debug(loggingLevel.INFO,'-------------::::::::::::::::::::::::getCanAssignRoom----------');            
        map<Id, Id> targetRoomIdTypeMap = new map<Id, Id>();
        map<Id, List<Room__c>> wkCanAssignRoomMap = new map<Id, List<Room__c>>();
        map<Integer,Room__c> resultMap = new map<Integer, Room__c>();
 		List<Id> roomTypeIdLst = roomTypeMap.values();
//System.debug(loggingLevel.INFO,'-------------::::::::::::::::::::::::roomTypeIdLst----------' + roomTypeIdLst);
        String queryHead = 'select id,Name,TypeRoomRef__c from Room__c ';
        String queryWhere = ' where UseOfRoom__c = \'' + String.escapeSingleQuotes(CommConst.ROOM_UseOfType_Guest) + '\'' +
                            ' And TypeRoomRef__c in :roomTypeIdLst ';
        String queryOrder = ' Order By priority__c NULLS LAST ';
        String queryString = queryHead + queryWhere + queryOrder;
//System.debug(loggingLevel.INFO,'-------------::::::::::::::::::::::::queryString----------' + queryString);	 	
	 	for (Room__c room : DataBase.query(queryString)) {
            // 部屋　と　部屋タイプマッピング情報を格納する
            targetRoomIdTypeMap.put(room.Id, room.TypeRoomRef__c);
            // 部屋単位の部屋情報を格納する
            if (!wkCanAssignRoomMap.containsKey(room.TypeRoomRef__c)) {
                wkCanAssignRoomMap.put(room.TypeRoomRef__c, new List<Room__c>());
            }
            wkCanAssignRoomMap.get(room.TypeRoomRef__c).add(room);
        }
    	// 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 BEGIN
    	Date wkBeginDate = leadIndex.EntryDate__c;
    	Date wkEndDate = leadIndex.DepartureDate__c;
    	Integer wkNights = bookingInfo.Nights;
    	if (wkNights > 0) wkEndDate = wkEndDate.addDays(-1);
    	// 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 END
        // 有効な予約データ、一日一部屋で処理するため、重複することは処理対象外
        Set<Id> usedRoomIdSet = new Set<Id>();
        // 既に予約データに入る場合、該当部屋は選択対象外になる
        for (AggregateResult lead :  [
            select Rroom__c roomId from Lead__c
            where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
            	// 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 BEGIN
                //And DAY_ONLY(convertTimezone(EntryTime__c)) >= :leadIndex.EntryDate__c
                //And DAY_ONLY(convertTimezone(EntryTime__c)) <= :leadIndex.DepartureDate__c 
            	And DAY_ONLY(convertTimezone(EntryTime__c)) >= :wkBeginDate
            	And DAY_ONLY(convertTimezone(EntryTime__c)) <= :wkEndDate
                // 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 END
                And Rroom__c in :targetRoomIdTypeMap.keySet()
                And LeadIndexRef__c != :leadIndex.Id
                Group By Rroom__c]) {
            usedRoomIdSet.add((Id)lead.get('roomId'));
//System.debug(loggingLevel.INFO,'-------------::::::::::::::::::::::::usedRoomIdSet----------' + usedRoomIdSet);
        }
	 	// 存在の部屋情報から予約データに利用している部屋は自動アサイン対象外になる
		// map<部屋タイプID,部屋リスト>
        map<Id, List<Room__c>> canAssignRoomMap = new map<Id, List<Room__c>>();
        for (Id roomTypeId : wkCanAssignRoomMap.keySet()) {
            List<Room__c> targetRoomLst = wkCanAssignRoomMap.get(roomTypeId);
            for (Room__c room : targetRoomLst) {
                // 既に使っている部屋の場合、対象外になる
                if (usedRoomIdSet.contains(room.Id)) continue;
                if (!canAssignRoomMap.containskey(roomTypeId)) canAssignRoomMap.put(roomTypeId, new List<Room__c>());
                canAssignRoomMap.get(roomTypeId).add(room);
            }
        }
//System.debug(loggingLevel.INFO,'-------------::::::::::::::::::::::::canAssignRoomMap----------' + canAssignRoomMap);	 	
	 	// アサインできる部屋はない場合、チェック処理中止
        if(canAssignRoomMap.isEmpty()) return resultMap;
	 	Integer nights = bookingInfo.Nights;            // 総宿泊数
        if (nights == 0) nights = 1;
//System.debug(loggingLevel.INFO,'-------------::::::::::::::::::::::::nights----------' + nights);
	 	Integer rooms = bookingInfo.roomAndGuestLst.size();
//System.debug(loggingLevel.INFO,'-------------::::::::::::::::::::::::rooms----------' + rooms);
	 	// 部屋単位に、宿泊期間内の部屋タイプリスト一覧情報を格納する
		//map<Integer, list<string>> tmpRoomTypeListMap = new map<Integer, list<string>>();
		map<Integer, string> tmpRoomTypeMap = new map<Integer, string>();
		// 宿泊期間情報を格納する、1部屋A：1/1,1/2,1/3日は同じ部屋タイプすると、0,1,2は同じリストを格納する<1, <1/1,1/2,1/3>, 2,<1/1,1/2,1/3>>...
		map<Integer, list<date>> roomTypeDateLinkByIdxMap = new map<Integer, list<date>>();

    	for(Integer j = 0; j < rooms; j ++){
    		BI_RoomAndGuestInfo roomAndGuest = bookingInfo.roomAndGuestLst[j];
    		// 該当部屋に指定の部屋タイプコード[TAの場合、１部屋１部屋タイプコード方式するため]
    		tmpRoomTypeMap.put(j,roomAndGuest.room.RoomTypeCode);
    		// 該当部屋に利用年月日情報を格納する
    		roomTypeDateLinkByIdxMap.put(j, new list<date>());
    		// 1部屋N日単位情報
        	//for(Integer i = 0; i < nights; i ++){
			Integer staysNums = roomAndGuest.roomDateLst.size();
			// 日付単位情報
			for(Integer i = 0; i < staysNums; i ++){
        		// 情報を取得IDEXを定義する
        		//Integer idx = i * rooms + j;
        		// 部屋利用日（到着日)
        		if (roomAndGuest.roomDateLst.size() > i) {
	            	Date stayDate = roomAndGuest.roomDateLst[i];
	            	roomTypeDateLinkByIdxMap.get(j).add(stayDate);
        		}
        	}
	 	}
	 	// 自動割当可能の部屋IDを格納する
	 	set<id> isAutoAssignRoomtSet = new set<Id>();
    	for (list<Room__c> canAssRooms : canAssignRoomMap.values()) {
    		for (Room__c canAssRoom : canAssRooms) {
    			isAutoAssignRoomtSet.add(canAssRoom.id);
    		}
    	}
system.debug(loggingLevel.INFO,'-------------::::::::::::::::::::::::isAutoAssignRoomtSet----------' + isAutoAssignRoomtSet);	 	
	 	// 部屋状態管理情報を取得する[故障部屋存在すると、割当対象外]
	 	RoomStatusManager roomStatusManger = new RoomStatusManager();
    	// 指定期間ないの故障部屋リストを取得する
    	List<RoomsStatus__c> roomsStatus = roomStatusManger.queryBadRoomList(leadIndex.EntryDate__c,leadIndex.DepartureDate__c ,isAutoAssignRoomtSet);
//system.debug(logginglevel.info,'=========roomsStatus' + roomsStatus);
    	// 指定部屋の故障ありの日付情報を格納する
    	Map<id,List<RoomsStatus__c>> badRoomStatusMap = new Map<id,List<RoomsStatus__c>>();
	 	for(RoomsStatus__c roomStatus : roomsStatus){
    		if(!badRoomStatusMap.containsKey(roomStatus.RoomRef__c)){
    			badRoomStatusMap.put(roomStatus.RoomRef__c,new List<RoomsStatus__c>());
    		}
    		badRoomStatusMap.get(roomStatus.RoomRef__c).add(roomStatus);
    	}
//system.debug(logginglevel.info,'=========badRoomStatusMap' + badRoomStatusMap);	 	
	 	// 部屋単位
		for(Integer j = 0; j < rooms; j ++){
			// 部屋タイプ
			String roomTypeCd = tmpRoomTypeMap.get(j);
    		// 部屋タイプリスト情報を格納する
    		Id roomTypeId = roomTypeMap.get(roomTypeCd);
    		if (roomTypeId == null) continue;
    		// 部屋タイプ関連の部屋リストを取得する
    		List<Room__c> locCanAssingRoomList = canAssignRoomMap.get(roomTypeId);
    		if (locCanAssingRoomList == null || locCanAssingRoomList.isEmpty()) continue;
			// 該当部屋は故障チェックの期間情報を取得する
			list<date> assingRangeDates = roomTypeDateLinkByIdxMap.get(j);
			// 連続期間ない場合、処理対象外
			if (assingRangeDates == null || assingRangeDates.isEmpty()) continue;
    		// 同部屋タイプ連泊の期間日付の開始と終了日付を取得する
			Date startDt = assingRangeDates[0];
			Date endDt = assingRangeDates[assingRangeDates.size()-1];
    		// 該当部屋は指定期間に、故障あり、なしチエックを行う
    		Room__c targetRoom = null;
    		for (Room__c room : locCanAssingRoomList){
    			// 該当部屋は指定期間に、故障がない場合
    			if (!badRoomStatusMap.containsKey(room.Id)) {
    				targetRoom = room;
    				break;
    			} else {
    				// 故障部屋情報リストを取得する
    				List<RoomsStatus__c> badInfoLst = badRoomStatusMap.get(room.Id);	        				
    				Boolean nextRoomFlg = false;
    				// 宿泊期間に故障情報が存在する場合、該当部屋は自動割当て対象外になる
    				for (RoomsStatus__c roomStatus : badInfoLst) {
    					if (roomStatus.StatusBeginDate__c <= endDt &&
    						roomStatus.StatusEndDate__c >= startDt) {
    						nextRoomFlg = true;
    						break;
    					}
    				}
    				// 故障部屋の場合、次の部屋を移動する
    				if (nextRoomFlg) continue;
    				// 有効な部屋の場合、処理完了
    				targetRoom = room;
    				break;
    			}
    		}
    		// 該当期間にアサインできる部屋が存在する場合
			if (targetRoom != null) {
				// 該当期間に、該当部屋は再利用できない様に制御設定を行う
				RoomsStatus__c virBadRoom = new RoomsStatus__c();
				virBadRoom.StatusBeginDate__c = startDt;
				virBadRoom.StatusEndDate__c = endDt;
				if (!badRoomStatusMap.containsKey(targetRoom.Id)) badRoomStatusMap.put(targetRoom.Id, new List<RoomsStatus__c>());
				badRoomStatusMap.get(targetRoom.Id).add(virBadRoom);
				// 該当部屋はアサイン期間OKの場合、部屋情報は該当IDXに設定を行う
				resultMap.put(j, targetRoom);
        	}
		}// 各部屋部屋割当
        return resultMap;
	 }
	/*
	 * 旅行会社情報はSFへ登録を行う
	 * 会社・営業所が存在する場合、営業所は
	 * TraveCompany[0] 会社
	 * TraveCompany[1] 営業所
	 */
	private static Account[] upsertTravelInfo (BI_SyncInfo bookingInfo) {
		// 旅行会社名と同じ取引先が存在するかどうかチェックを行う
		Account[] travelLst = new Account[2];
		Account travelCompany = null;
		// 旅行会社存在する場合
		if (!CommUtils.isBlank(bookingInfo.SalesOfficeCompanyName) &&
			!CommUtils.isBlank(bookingInfo.SalesOfficeCompanyCode) ) {
			List<Account> travelCompanyLst = [select id , name from Account
				where name = :bookingInfo.SalesOfficeCompanyName
				And AccountType__c = :CommConst.ACCOUNT_TYPE_TRAVEL
				and SalesOfficeCompanyCode__c = :bookingInfo.SalesOfficeCompanyCode limit 1];
			// 存在なければ、取引先を新規作成する
			if (travelCompanyLst.isEmpty()) {
				travelCompany = new Account();
				travelCompany.Name = bookingInfo.SalesOfficeCompanyName;
				travelCompany.SalesOfficeCompanyCode__c = bookingInfo.SalesOfficeCompanyCode;
				travelCompany.AccountType__c = CommConst.ACCOUNT_TYPE_TRAVEL;
				insert travelCompany;
			} else {
				travelCompany = travelCompanyLst[0];
			}
			travelLst[0] = travelCompany;
		}

		Account traveOffice = null;
		// 旅行会社営業所情報が存在する場合
		if (!CommUtils.isBlank(bookingInfo.SalesOfficeCode) &&
			!CommUtils.isBlank(bookingInfo.SalesOfficeName) ) {
			// 旅行会社営業所情報をチェックを行う
			List<Account> traveOfficeLst = [select id , name from Account
				where name = :bookingInfo.SalesOfficeName 
				and AccountType__c = :CommConst.ACCOUNT_TYPE_TRAVEL
				and SalesOfficeCode__c = :bookingInfo.SalesOfficeCode limit 1];
			if (traveOfficeLst.isEmpty()) {
				traveOffice = new Account();
				traveOffice.Name = bookingInfo.SalesOfficeName;
				traveOffice.AccountType__c = CommConst.ACCOUNT_TYPE_TRAVEL;
				traveOffice.SalesOfficeCode__c = bookingInfo.SalesOfficeCode;
				traveOffice.ParentId = (travelCompany != null ? travelCompany.Id : null);
				traveOffice.Phone = bookingInfo.SalesOfficePhoneNumber;
				insert traveOffice;
			} else {
				traveOffice = traveOfficeLst[0];
			}
			travelLst[1] = traveOffice;
		}
		// 担当者->取引先責任者に設定を行う
		// 取引担当者が存在する場合、担当者として、登録する
		if ((travelCompany != null || traveOffice != null) &&
			!CommUtils.isBlank(bookingInfo.SalesOfficePersonInCharge) &&
			!CommUtils.isBlank(bookingInfo.SalesOfficePhoneNumber) ) {
			// 同じ氏名と電話の担当者存在チェックを行う
			List<Contact> contactLst = [select id, name from Contact where LastName = :bookingInfo.SalesOfficePersonInCharge and phone = :bookingInfo.SalesOfficePhoneNumber];
			if (contactLst.isEmpty()) {
				Contact newContact = new Contact();
				newContact.LastName = bookingInfo.SalesOfficePersonInCharge;
				newContact.phone = bookingInfo.SalesOfficePhoneNumber;
				newContact.AccountId = (traveOffice == null ? travelCompany.Id : traveOffice.Id);
				insert newContact;
			}
		}

		//return (traveOffice == null ? travelCompany: traveOffice);
		return travelLst;
	}



	global class BI_SyncInfo {
		// TransactionType
		webservice String DataFrom;
		//webservice String DataClassification;
		webservice BI_DmlAction dmlAction;
		webservice String DataID;
		webservice Date SystemDate;
		webservice Time SystimTime;
		// 宿泊施設側情報
		webservice String AccommodationName;
		webservice String AccommodationCode;
		// 	旅行会社情報
		webservice String SalesOfficeCompanyCode;
		webservice String SalesOfficeCompanyName;
		webservice String SalesOfficeName;
		webservice String SalesOfficeCode;
		webservice String SalesOfficePersonInCharge;
		webservice String SalesOfficePhoneNumber;
		// 基本宿泊情報
		webservice String TravelAgencyBookingNumber;
		webservice Date TravelAgencyBookingDate;
		webservice Time TravelAgencyBookingTime;
		webservice String GuestOrGroupNameSingleByte;
		webservice String GuestOrGroupNameDoubleByte;
		webservice String GuestOrGroupNameKanjiName;
		webservice Date CheckInDate;
		webservice Time CheckInTime;
		webservice Date CheckOutDate;
		webservice Time CheckOutTime;
		webservice Integer Nights;
		webservice Integer TotalRoomCount;
		webservice Integer GrandTotalPaxCount;
		webservice String PackagePlanName;
		webservice String PackagePlanCode;
		// 電文(予約詳細： 一日ごとの大人子供人数の内訳、料金詳細などを出力する。 予約詳細情報は最初の情報が「ZZ」で始まり「,ZZ」で区切られる。)
		webservice String SpecialServiceRequest;
		// 備考
		webservice String OtherServiceInformation;
		// 2014/12/02 基本情報
		webservice BI_BasicRateInformation basicRateInfo;
		// 合計宿泊料金(総額)
		webservice Integer TotalAccommodationCharge;
		// 個々の部屋とお客様情報<1:N>
		webservice List<BI_RoomAndGuestInfo> roomAndGuestLst;
        // Member
        webservice BI_MemberInfo member;
	}
	// BasicRateInformation
	global class BI_BasicRateInformation {
		// 2014/12/02 最新2014/05最新API仕様により、連携項目を補足する
		webservice String RoomRateOrPersonalRate;	// 料金区分
		webservice String TaxServiceFee;			// 税サ区分
		webservice String Payment;					// 支払い方法
		webservice Integer TotalAccommodationCharge;	// 合計宿泊料金(総額)
	}
	// １部屋利用情報
	global class BI_RoomAndGuestInfo {
		webservice BI_RoomsInfo room;
		webservice List<Date> roomDateLst;
		webservice List<BI_GuestInfo> guestLst;
	}
	// 部屋情報
	global class BI_RoomsInfo{
		webservice String RoomTypeCode;
		webservice String RoomTypeName;
		webservice Integer PerRoomPaxCount;
		webservice Integer RoomPaxMaleCount;
		webservice Integer RoomPaxFemaleCount;
		webservice Integer RoomChildA70Count;
	}
	// 顧客情報
	global class BI_GuestInfo {
		webservice String GuestNameSingleByte;
		webservice String GuestSurName;
		webservice String GuestKanjiName;
		webservice String GuestPhoneNumber;
		webservice String GuestEmergencyPhoneNumber;
		webservice String GuestEmail;
		webservice String GuestStateProvidence;
	}
    // Member情報
    global class BI_MemberInfo {
    	webservice String UserName;
    	webservice String UserKana;
    	webservice String UserTel;
    	webservice String UserMailAddr;
    	webservice String UserAddr;
    	webservice String UserCorp;
    	webservice Integer UserUsePoints;
    	webservice Integer AmountClaimed;
    }
	global class BI_SyncResult {
		// 処理結果
		webservice BI_Result result;
		webservice Id sfdcId;
		webservice String message;
		webservice Id sfdcJobId;
	}
	// 戻る結果：処理成功、処理失敗、処理中。
	global enum BI_Result{OK, NG, WAIT}
	// INS:新規 / UPD:更新 / 削除：キャンセル
	global enum BI_DmlAction{INS, UPD, CANCEL}
	
	// 2017/06/30 XML特殊記号文字UTF-8対応 BEGIN
    static void unescapeXmlProcess(BI_SyncInfo bookingInfo) {
    	// 宿泊施設側情報
		bookingInfo.AccommodationName = unescapeXml(bookingInfo.AccommodationName);
		bookingInfo.AccommodationCode = unescapeXml(bookingInfo.AccommodationCode);	
    	//  旅行会社情報
    	bookingInfo.SalesOfficeCompanyCode = unescapeXml(bookingInfo.SalesOfficeCompanyCode); 
		bookingInfo.SalesOfficeCompanyName = unescapeXml(bookingInfo.SalesOfficeCompanyName);         
		bookingInfo.SalesOfficeName = unescapeXml(bookingInfo.SalesOfficeName); 
		bookingInfo.SalesOfficeCode = unescapeXml(bookingInfo.SalesOfficeCode); 
		bookingInfo.SalesOfficePersonInCharge = unescapeXml(bookingInfo.SalesOfficePersonInCharge);  
		bookingInfo.SalesOfficePhoneNumber = unescapeXml(bookingInfo.SalesOfficePhoneNumber);     
    	// 基本宿泊情報
    	bookingInfo.TravelAgencyBookingNumber = unescapeXml(bookingInfo.TravelAgencyBookingNumber);      			
		bookingInfo.GuestOrGroupNameSingleByte = unescapeXml(bookingInfo.GuestOrGroupNameSingleByte);     			
		bookingInfo.GuestOrGroupNameDoubleByte = unescapeXml(bookingInfo.GuestOrGroupNameDoubleByte);     			
		bookingInfo.GuestOrGroupNameKanjiName = unescapeXml(bookingInfo.GuestOrGroupNameKanjiName);      			
		bookingInfo.PackagePlanName = unescapeXml(bookingInfo.PackagePlanName);  			
		bookingInfo.PackagePlanCode = unescapeXml(bookingInfo.PackagePlanCode);  			
		bookingInfo.SpecialServiceRequest = unescapeXml(bookingInfo.SpecialServiceRequest);			
		bookingInfo.OtherServiceInformation = unescapeXml(bookingInfo.OtherServiceInformation);			
    	// 基本情報 BasicRateInformation
    	BI_BasicRateInformation basicRateInfo = bookingInfo.basicRateInfo; 
    	if(basicRateInfo != null){
    		basicRateInfo.RoomRateOrPersonalRate= unescapeXml(basicRateInfo.RoomRateOrPersonalRate); 				
			basicRateInfo.TaxServiceFee = unescapeXml(basicRateInfo.TaxServiceFee);      				
			basicRateInfo.Payment = unescapeXml(basicRateInfo.Payment); 
    	}
    	// 個々の部屋とお客様情報<1:N>
		for(BI_RoomAndGuestInfo roomGuestInfo : bookingInfo.roomAndGuestLst){
			// 部屋情報
			BI_RoomsInfo roomInfo = roomGuestInfo.room;
			if(roomInfo != null){
				roomInfo.RoomTypeCode = unescapeXml(roomInfo.RoomTypeCode);        		
				roomInfo.RoomTypeName = unescapeXml(roomInfo.RoomTypeName);        		
			}
    		// 顧客情報
    		List<BI_GuestInfo> guestLst = roomGuestInfo.guestLst;
    		if(guestLst != null){
    			for (BI_GuestInfo guest : guestLst) {
	    			guest.GuestNameSingleByte = unescapeXml(guest.GuestNameSingleByte);  		
					guest.GuestSurName = unescapeXml(guest.GuestSurName);  
					guest.GuestKanjiName = unescapeXml(guest.GuestKanjiName); 
					guest.GuestPhoneNumber = unescapeXml(guest.GuestPhoneNumber);    		
					guest.GuestEmergencyPhoneNumber = unescapeXml(guest.GuestEmergencyPhoneNumber);		
					guest.GuestEmail = unescapeXml(guest.GuestEmail);   
					guest.GuestStateProvidence = unescapeXml(guest.GuestStateProvidence);  	
					//guest.GuestPostalCode = unescapeXml(guest.GuestPostalCode);       		
	    		}
    		}
		}
        // Member    
        BI_MemberInfo member = bookingInfo.member;    
        if(member != null){
            member.UserName = unescapeXml(member.UserName);        				
			member.UserKana = unescapeXml(member.UserKana);        				
			member.UserTel = unescapeXml(member.UserTel);         				
			member.UserMailAddr = unescapeXml(member.UserMailAddr);    				
			//member.UserZip = unescapeXml(member.UserZip);         				
			member.UserAddr = unescapeXml(member.UserAddr);        				
			member.UserCorp = unescapeXml(member.UserCorp);   
			//member.UserGivinPoints = unescapeXml(member.UserGivinPoints); 
        }
    }
    static string unescapeXml(String s) {
        if (CommUtils.isBlank(s)) return s;
        return s.unescapeXml();
    }
    // 2017/06/30 XML特殊記号文字UTF-8対応 END

}