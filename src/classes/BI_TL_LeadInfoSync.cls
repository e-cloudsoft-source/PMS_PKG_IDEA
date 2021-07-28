/**
* バッチ連携：外から連携する顧客情報を反映する
* TL-リンカーン機能連携
* 2013/06/20 予約変更ステータスデータ連携する場合、処理対象外にする
* 2013/12/09 旅行会社の検索と新規作成ロジック変更
* 2014/02/25 旅行会社予約番号設定追加
* 2014/11/12 プランに店舗情報設定に従って、店舗コード＋Packageコードでプラン情報を自動探す対応
* 2015/06/08 お客様情報取得検索方式変更
* 2016/02/01 取引先（旅行会社）情報取得方式変更
* 2016/02/01 ネットからの取込時に予約チャネルに旅行会社名で設定する
* 2016/10/26 部屋タイプと部屋が1対1の場合は故障部屋を割当される不具合改修
* 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修
* 2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する
**/
global with sharing class BI_TL_LeadInfoSync {
	// 中継アプリの名
	private static final String APPNAME = 'TL';
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
	webservice static BI_TL_SyncResult upsertLeadInfo(BI_TL_SyncInfo bookingInfo) {
		// 2017/06/30 XML特殊記号文字UTF-8対応 BEGIN
        unescapeXmlProcess(bookingInfo);
        // 2017/06/30 XML特殊記号文字UTF-8対応 END
		// 予約情報を更新を行う
System.debug(logginglevel.INFO,bookingInfo);
		BI_TL_SyncResult rs = new BI_TL_SyncResult();
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
		if (bookingInfo.dmlAction == BI_TL_DmlAction.UPD ||
			bookingInfo.dmlAction == BI_TL_DmlAction.CANCEL) {
            // Data発生源の条件を追加する
            String dataFrom = bookingInfo.DataFrom;
			// 既存の予約インデックス情報を取得する
			String pString = CommSqlUtils.generateQueryString('LeadIndex__c') + ' Where ID__c = \'' + String.escapeSingleQuotes(bookingInfo.DataID) + '\' And EventSource__c = :dataFrom And (APPNAME__c = :APPNAME OR APPNAME__c = null ) ';
			List<LeadIndex__c> rslst = Database.query(pString);
			if (rslst.isEmpty()) {
				//throw new CommException('更新する予約データが見つかりません。データID:(' + bookingInfo.DataID + ')');
				// 2013/07/17 仮に、データOKに設定する、overフォルダに移動する TODO:ERRORフォルダに移動対応が必要
				rs.result = BI_TL_Result.OK;
				return rs;
			} else {
				if (bookingInfo.dmlAction == BI_TL_DmlAction.UPD)rslst[0].TravelAgencyBookingUpdDateTime__c = DateTime.newInstance(bookingInfo.TravelAgencyBookingDate, bookingInfo.TravelAgencyBookingTime !=null?bookingInfo.TravelAgencyBookingTime: Time.newInstance(0,0,0,0) );
				if (bookingInfo.dmlAction == BI_TL_DmlAction.CANCEL) rslst[0].TravelAgencyBookingDelDateTime__c = DateTime.newInstance(bookingInfo.TravelAgencyBookingDate, bookingInfo.TravelAgencyBookingTime !=null?bookingInfo.TravelAgencyBookingTime: Time.newInstance(0,0,0,0));
				// 予約インデックスのデータ種別に更新を行う
				rslst[0].DataClassification__c = bookingInfo.dmlAction.name();
				// 2016/08/10 ADD BEGIN
				rslst[0].APPNAME__c = APPNAME;
				// 2016/08/10 ADD END
				update rslst[0];
			}
			rs.sfdcId = rslst[0].Id;
			rs.result = BI_TL_Result.OK;
			return rs;
		}
		try {
			// 旅行会社情報の新規・更新を行う
			// 2016/02/01 ネットからの取込時に予約チャネルに旅行会社名で設定する BEGIN
			//Account traveCompany = upsertTravelInfo(bookingInfo);
			List<Account> traveCompany = upsertTravelInfo(bookingInfo);
			// 2016/02/01 ネットからの取込時に予約チャネルに旅行会社名で設定する END
			// 団体代表者の情報は顧客へ登録する
			Contact pkuser = upsertContact(bookingInfo);
			// 予約インデックスオブジェクト
			LeadIndex__c leadIndex = upsertLeadIndex(bookingInfo, pkuser, traveCompany);
			// 予約データを作成する　
			upsertLead(bookingInfo, leadIndex, pkuser, traveCompany);
			// 処理結果設定を行う
			rs.sfdcId = leadIndex.Id;
			rs.result = BI_TL_Result.OK;
		} catch (CommException ex) {
			System.debug(LoggingLevel.ERROR, ex.getStackTraceString());
			rs.result = BI_TL_Result.NG;
			rs.message = ex.getMessage();
		} catch (Exception e) {
			System.debug(LoggingLevel.ERROR, e.getStackTraceString());
			rs.result = BI_TL_Result.NG;
			rs.message = e.getMessage();
		}
		return rs;
	}

	/**
	* 予約基本情報
	**/
	private static LeadIndex__c upsertLeadIndex(BI_TL_SyncInfo bookingInfo, Contact pkuser, List<Account> TraveCompany) {
		LeadIndex__c leadIndex;
		// ネット旅行Agency
		// 更新/キャンセル場合:存在チェックを行う
		if (bookingInfo.dmlAction == BI_TL_DmlAction.UPD ||
			bookingInfo.dmlAction == BI_TL_DmlAction.CANCEL) {
			// 2013/07/14 DELETE 更新・キャンセル機能削除
			/*
			// 既存の予約インデックス情報を取得する
			String pString = CommSqlUtils.generateQueryString('LeadIndex__c') + ' Where ID__c = \'' + String.escapeSingleQuotes(bookingInfo.DataID) + '\'';
System.debug('pString:' + pString);
			List<LeadIndex__c> rslst = Database.query(pString);
			if (rslst.isEmpty()) {
				throw new CommException('更新する予約データが見つかりません。データID:(' + bookingInfo.DataID + ')');
			}
			leadIndex = rslst[0];

			// キャンセルステータスに変更する
			if (bookingInfo.dmlAction == BI_TL_DmlAction.CANCEL) leadIndex.StatusLst__c = CommConst.LEAD_ST_CANCEL;

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
			update leadIndex;

			// 既存のSUBINDEXを削除を行う
			delete [select id from LeadIndex__c where ParentLeadIndxRef__c = :leadIndex.Id];
			*/
		} else {
			// 新規データ作成を行う
			DateTime checkInDt = (bookingInfo.CheckInTime == null ? null : DateTime.newInstance(bookingInfo.CheckInDate, bookingInfo.CheckInTime));
			BI_TL_Member member = bookingInfo.risaplsinformation.risaplsCommonInformation.member;
			leadIndex = new LeadIndex__c();
			// 2016/08/10 ADD BEGIN
			leadIndex.APPNAME__c = APPNAME;
			// 2016/08/10 ADD END
			leadIndex.DataClassification__c = bookingInfo.dmlAction.name();
			leadIndex.EventSource__c = bookingInfo.DataFrom;
			leadIndex.ID__c = bookingInfo.DataID;
			leadIndex.TravelLeadNo__c = bookingInfo.TravelAgencyBookingNumber;	// 2013/12/27 ADD
			leadIndex.EntryDate__c = bookingInfo.CheckInDate;
			leadIndex.EntryTime__c = checkInDt == null ? (bookingInfo.Nights == 0 ? defaultDayUseCheckInTime : defaultCheckInTimeStr) : checkInDt.format('HH:mm');
			//leadIndex.DepartureDate__c = bookingInfo.CheckOutDate;
			leadIndex.DepartureDate__c = bookingInfo.CheckOutDate == null ? (bookingInfo.CheckInDate.addDays(bookingInfo.Nights)) : bookingInfo.CheckOutDate;
			// 2014/02/25 補足情報を追加する BEGIN
			if(member != null){
				leadIndex.MemberUserName__c = member.UserName;
				leadIndex.MemberUserKana__c = member.UserKana;
				leadIndex.MemberAddPoint__c = member.UserGivingPoints;
				leadIndex.MemberUsePoint__c = member.UserUsePoints;
				leadIndex.MemberUserTel__c = member.UserTel;	// 会員電話番号 
				leadIndex.MemberUserMailAddr__c = member.UserMailAddr;	// 会員Email 
				leadIndex.MemberUserZip__c = member.UserZip;	// 会員郵便番号 
				leadIndex.MemberUserAddr__c = member.UserAddr;	// 会員住所 
				leadIndex.MemberUserCorp__c = member.UserCorp;	// 会員会社 
				leadIndex.MemberUserDep__c = member.UserDep;	// 会員所属部署 
				leadIndex.MemberUserID__c = member.UserID;	// 会員番号 
				leadIndex.MemberUserType__c = member.UserType;	// 会員種別
				leadIndex.MemberUserDateOfBirth__c = member.UserDateOfBirth;	// 会員生年月日
				leadIndex.MemberUserGendar__c = (member.UserGendar == '0' 
				//男性
												? Label.CONST_038_0032 
												: (member.UserGendar == '1' 
				//女性
													? Label.CONST_038_0033 
				//不明
													: (member.UserGendar == '2' ? Label.CONST_038_0034 : '' )));	// 会員性別 
				leadIndex.MemberUserEmergencyPhoneNumber__c = member.UserEmergencyPhoneNumber;	// 会員緊急連絡先番号(携帯等)
			}
			leadIndex.TotalAccommodationCharge__c = String.valueOf(bookingInfo.TotalAccommodationCharge);
			leadIndex.Payment__c = getLocalPaymentInfo(bookingInfo.Payment);
			// 2014/02/25 補足情報を追加する END
			// チェックアウト時間はDefault値設定を行う
			leadIndex.DepartureTime__c = 	(	bookingInfo.CheckOutTime == null
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
			// 2013/07/16 ADD 予約チャネルに設定を行う
			// 2016/02/01 ネットからの取込時に予約チャネルに旅行会社名で設定する BEGIN
			//leadIndex.Channel__c = TraveCompany.Name;
			leadIndex.Channel__c = (TraveCompany.size() > 0 ? TraveCompany[0].Name : null);
			// 2016/02/01 ネットからの取込時に予約チャネルに旅行会社名で設定する END
			// 2013/08/16 予約名追加
			leadIndex.LeadName__c = CommUtils.isBlank(bookingInfo.GuestOrGroupNameKanjiName) ? bookingInfo.GuestOrGroupNameSingleByte : bookingInfo.GuestOrGroupNameKanjiName;
			// 2013/09/10 特記事項設定追加
			leadIndex.Comment__c = bookingInfo.OtherServiceInformation;
			leadIndex.TravelAgencyBookingInsDateTime__c = DateTime.newInstance(bookingInfo.TravelAgencyBookingDate, bookingInfo.TravelAgencyBookingTime !=null?bookingInfo.TravelAgencyBookingTime: Time.newInstance(0,0,0,0));
			insert leadIndex;
		}
		return leadIndex;
	}
	/**
	* プラン情報を設定する
	* 2013/06/22 プラン未設定のケース場合
	**/
	private static Plan__c upsertPlan(BI_TL_SyncInfo bookingInfo, List<Account> TraveCompany) {
		// プランのPackageCode/プラン名は両方とも存在する場合、処理対象です
		if (  CommUtils.isBlank(bookingInfo.PackagePlanName) &&
		      CommUtils.isBlank(bookingInfo.PackagePlanCode)) { return null; }
		// 同じプラン名情報を検索する
		Plan__c rsPlan = null;
		List<Plan__c> existPlanLst = new List<Plan__c>();
		// プラン名が存在する場合とプランコード
		/* 2014/06/06 プラン検索方式変更
		if (!CommUtils.isBlank(bookingInfo.PackagePlanName)) {
			existPlanLst = [select Id, name from Plan__c Where name = :bookingInfo.PackagePlanName limit 1];
		}*/
		String packageCode = CommUtils.nullToBlank(bookingInfo.PackagePlanCode);
		String packageName = CommUtils.nullToBlank(bookingInfo.PackagePlanName);
		// 2016/02/01 ネットからの取込時に予約チャネルに旅行会社名で設定する BEGIN
		//String agtId = TraveCompany.Id;
		String agtId = (TraveCompany.size() > 1 ? TraveCompany[1].Id : TraveCompany[0].Id);
		// 2016/02/01 ネットからの取込時に予約チャネルに旅行会社名で設定する END
		String shopCode = bookingInfo.AccommodationCode;
		// 店舗情報格納する
		Map<String, ShopInformation__c> shopInfoMap = new Map<String, ShopInformation__c>(); 
		/* 2014.11.18 プラン検索ロジック変更、店舗検索機能を追加 */
		String queryHeader = ' select Id, name from Plan__c ';
		String queryLimit = ' limit 1 ';
		// 2014/07/16 非公開プランは検索対象外に対応
		//String whereStr = ' Where (';
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
//System.debug(loggingLevel.info, 'SQL1::' + queryHeader + whereStr + whereStr2 + queryLimit);
			existPlanLst = DataBase.query(queryHeader + whereStr + whereStr2 + queryLimit);
		}
		if (existPlanLst.isEmpty()) {
			existPlanLst = DataBase.query(queryHeader + whereStr + queryLimit);
		}
		// Plan非存在する場合：新規作成
		if (existPlanLst == null || existPlanLst.isEmpty()) {
			rsPlan = new Plan__c();
			//rsPlan.ShopInfoRef__c = shopId;	// 2014/11/18 店舗設定機能を追加
			rsPlan.ShopInfoRef__c = shopInfoMap.containsKey(shopCode) ? shopInfoMap.get(shopCode).Id : null;
			rsPlan.name = packageName.length() > 80 ?packageName.subString(0,80) : packageName;
			rsPlan.PackageCode__c = bookingInfo.PackagePlanCode;
			// 2016/02/01 ネットからの取込時に予約チャネルに旅行会社名で設定する BEGIN
			//rsPlan.client__c = TraveCompany.Id;
			rsPlan.client__c = agtId;
			// 2016/02/01 ネットからの取込時に予約チャネルに旅行会社名で設定する END
			insert rsPlan;
		}  else {
			rsPlan = existPlanLst[0];
		}
		return rsPlan;
	}
	/**
	* 予約情報を登録する
	*/
	private static void upsertLead(BI_TL_SyncInfo bookingInfo, LeadIndex__c leadIndex, Contact pkuser, List<Account> TraveCompany) {
		// 予約キャンセル　と　更新場合:　既存予約データを全部キャンセルする
		if (bookingInfo.dmlAction == BI_TL_DmlAction.UPD ||
			bookingInfo.dmlAction == BI_TL_DmlAction.CANCEL) {
			// 既存予約データをキャンセルする
			List<Lead__c> existLeadLst = [select id, ReservedStatus__c, Comment3__c from Lead__c where LeadIndexRef__c = :leadIndex.Id And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG];
			for (Lead__c lead : existLeadLst) {
				lead.ReservedStatus__c = CommConst.LEAD_ST_CANCEL;
				//キャンセル対応(外部インタネットから自動連携)
				lead.Comment3__c = CommUtils.nullToBlank(lead.Comment3__c) + '\n' + System.now().format('yyyy/MM/dd HH:mm:ss:SSS') + ' '+ Label.CONST_038_0035;
			}
			update existLeadLst;
		}
		// キャンセル場合、処理中止
		if (bookingInfo.dmlAction == BI_TL_DmlAction.CANCEL) return;

		//  プラン情報を取得、作成する
		Plan__c curPlan = upsertPlan(bookingInfo, TraveCompany);

		// 部屋タイプID情報を取得する
		Set<String> roomTypeCdSet = new Set<String>();
		// 2013/02/26 部屋タイプ名情報を格納する
		Set<String> roomTypeNmSet = new Set<String>();
		
		for (BI_TL_RoomAndGuestInfo roomAndGuest: bookingInfo.roomAndGuestLst) {
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
        // 自動割り当てフラグはTRUEのみ、該当関連取得を行う
		if (oneRoomAutoAssingRoomFlg) {
			for ( TypeOfRooms__c r : [Select id, (Select Id From TypeRoomRef__r limit 2) From TypeOfRooms__c] ) {
			    if (r.TypeRoomRef__r != null && r.TypeRoomRef__r.size() == 1) {
					oneTypeToRoomMap.put( r.Id, r.TypeRoomRef__r[0].Id );
			    }
			}
		}
		// 2015/07/22  部屋タイプが存在　かつ　対応部屋タイプに対して、１部屋のみの場合、該当部屋は自動的に予約にアサインする END
		// 2016/10/26 部屋タイプと部屋が1対1の場合は故障部屋を割当される不具合改修 BEGIN
        map<Integer, Room__c> oneRoomCanAssignRoomMap = new map<Integer, Room__c>();
        // 部屋タイプが存在する場合
        if (!oneTypeToRoomMap.isEmpty()) {
        	// 割当できる部屋情報を取得する　
        	oneRoomCanAssignRoomMap = getCanAssignRoom(leadIndex,roomTypeMap,oneRoomAutoAssingRoomFlg,bookingInfo);
        }
		// 2016/10/26 部屋タイプと部屋が1対1の場合は故障部屋を割当される不具合改修 END
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
        //Integer roomNoIdx = 0;
    	// メール本文[7XXXXX]
    	BI_TL_RisaplBasic risaplBasic = bookingInfo.risaplsinformation.risaplsCommonInformation.risaplBasic;
    	// 2013.05.29 ADD パタン６確認する（連泊、１室、１部屋タイプ）
    	// 2013.07.10 ADD 同じ日付のデータ数：部屋数　　部屋利用日の範囲は泊数設定
    	// 定義した総泊数からLOOPして、その後、部屋数LOOPする
    	Integer nights = bookingInfo.Nights;			// 総宿泊数
    	if (nights == 0) nights = 1;
    	Integer rooms = bookingInfo.TotalRoomCount;		// 総部屋数
		// 2013/07/05 予約名自動設定対応、団体名または代表者氏名 漢字ー＞団体名または代表者氏名(半角)
		//String leadName = CommUtils.isBlank(bookingInfo.GuestOrGroupNameKanjiName) ? bookingInfo.GuestOrGroupNameSingleByte : bookingInfo.GuestOrGroupNameKanjiName;
		String leadName = leadIndex.LeadName__c;
		// 複数件予約データを作成する
		List<Lead__c> insLeadLst = new List<Lead__c>();
		// 2013/07/16 記号機能対応 BEGIN
		// N rooms N nightsのとき、特記事項をその日は、一つにする対応と同様に、親部屋マーク（一文字記号）をカスタム設定のパラメータとして、定義、この定義されたマークを予約名の文字列先頭に付加する、
		// また、人数とプランも一つの予約データのみに取り込み、他の予約データは、人数ゼロ、プランなし、と設定する
		String strRoomDelegatePrefix = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomDelegatePrefix__c);
		// N部屋N泊数標識フラグ
		//Boolean isNroomNnightFlg = (nights > 1 && rooms > 1);
		// 2013/07/16 記号機能対応 End
		
		// 複数予約日ー＞複数部屋タイプから　１部屋タイプ１日予約データを作成する
		//for (BI_TL_RoomAndGuestInfo roomAndGuest: bookingInfo.roomAndGuestLst) {
		// 日単位情報
		for(Integer i = 0; i < nights; i ++){
			// １部屋タイプから複数日予約データを作成する
			/*
			// 複数日から１日単位に作成する
			Integer staysNums = roomAndGuest.roomRateLst.size();
			if (isParten6Flg) staysNums = nights;
			*/
			// 部屋単位情報
			for(Integer j = 0; j < rooms; j ++){
				// データ取得INDEX
				Integer idx = i * rooms + j;
				//　到着日
				//Date checkInDate = (isParten6Flg ? bookingInfo.roomAndGuestLst[i].roomRateLst[0].RoomDate : roomAndGuest.roomRateLst[i].RoomDate);
				//if (isParten6Flg) roomAndGuest = bookingInfo.roomAndGuestLst[i];
				BI_TL_RoomAndGuestInfo roomAndGuest = bookingInfo.roomAndGuestLst[idx];
				// 部屋利用日（到着日)
				Date checkInDate = roomAndGuest.roomRateLst[0].RoomDate;
				
				// 新規予約データ作成
				Lead__c newLead = new Lead__c();
				
				// 2013/07/16 記号機能対応 BEGIN
				// 親部屋マーク標識用の文字は予約名の文字列先頭に付加
				newLead.name = (rooms > 1 && j == 0 ? strRoomDelegatePrefix : '');
				// 2013/07/16 記号機能対応 END
				
				// 予約データ名設定を行う
				//泊目
				if (nights > 1) newLead.name += String.valueOf(nights) + '-' + (i+1) + Label.CONST_038_0036 + leadName;  //bookingInfo.GuestOrGroupNameKanjiName;
				else newLead.name += leadName; //bookingInfo.GuestOrGroupNameKanjiName;
				// レコードタイプ：宿泊タイプ
				newLead.RecordTypeId = bookingRcTypeId;
				// お客様情報
				newLead.Relcontact__c = pkuser.Id;
				// 予約受付日
				// 2013/06/19 予約受付日の受付時間設定ミス、不具合修正、時間項目を設定する
				newLead.ReservedDate__c = DateTime.newInstance(bookingInfo.TravelAgencyBookingDate, bookingInfo.TravelAgencyBookingTime);
				// 支払方法 ----------------BEGIN----------------------
				// 2014/04/25 支払方法設定共通化
				/*
				String mediaType = bookingInfo.Payment;
				String ttendType = null;
				if (mediaType == 'Cach') ttendType = CommConst.MEDIA_TYPE_CD_01;
				else if (mediaType == 'CreditCard') ttendType = CommConst.MEDIA_TYPE_CD_02;
				//else if (mediaType == '売掛') ttendType = CommConst.MEDIA_TYPE_CD_03;
				else if (mediaType == 'Coupon') ttendType = CommConst.MEDIA_TYPE_CD_11;
				// 支払方法設定
				String mediaTypeName = CommConst.getPaymentTypeLabelByKey(ttendType);
				newLead.Field315__c = (mediaTypeName == null ? mediaType : mediaTypeName);*/
				newLead.Field315__c = getLocalPaymentInfo(bookingInfo.Payment);
				// 支払方法 -----------------END-----------------------
				// 予約ステータス[Deafult:確認中]
				//newLead.ReservedStatus__c =
				// First Dayの場合
				if (i == 0) {
					// チェックイン日
					//newLead.EntryTime__c = checkInFirstDayDt;
					// チェックイン時間
					newLead.Field4__c = (bookingInfo.CheckInTime == null 
						// DayUserの場合の時刻情報
						?  (bookingInfo.Nights == 0 ? defaultDayUseCheckInTime : defaultCheckInTimeStr)
						:  (DateTime.newInstance(Date.today(), bookingInfo.CheckInTime)).format('HH:mm') );
					newLead.EntryTime__c = DateTime.newInstance(checkInFirstDayDt.date(), CommUtils.stringtotime(newLead.Field4__c));
				} else {
					// チェックイン日
					newLead.EntryTime__c = DateTime.newInstance(checkInDate, defaultCheckinTime);
					// チェックイン時間
					newLead.Field4__c = defaultCheckInTimeStr;
				}
				// 最後日の場合
				if (i == nights - 1) {
					// チェックアウト日
					// 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
					//newLead.Departure__c = checkOutLastDayDt;
					// 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
					// チェックアウト時間
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
				// 部屋タイプID
				newLead.refTypeOfRooms__c = roomTypeMap.get(roomAndGuest.room.RoomTypeCode);
				// 2013/02/26 部屋タイプ名：部屋ID情報を格納する
				if (newLead.refTypeOfRooms__c == null ) newLead.refTypeOfRooms__c = roomTypeNmMap.get(roomAndGuest.room.RoomTypeName);
				
				// 2015/07/22  部屋タイプが存在　かつ　対応部屋タイプに対して、１部屋のみの場合、該当部屋は自動的に予約にアサインする BEGIN
				if(newLead.refTypeOfRooms__c != null && oneTypeToRoomMap.containsKey(newLead.refTypeOfRooms__c) && oneRoomCanAssignRoomMap.containsKey(idx)){
					newLead.Rroom__c = oneTypeToRoomMap.get(newLead.refTypeOfRooms__c);
				}
				// 2015/07/22  部屋タイプが存在　かつ　対応部屋タイプに対して、１部屋のみの場合、該当部屋は自動的に予約にアサインする EN
				
				// 2013/06/09 宿泊人数は未設定する場合、自動Default値を設定する
				Integer calRoomPaxCount =  CommUtils.nullToZero(roomAndGuest.room.RoomPaxMaleCount) + 
										   CommUtils.nullToZero(roomAndGuest.room.RoomPaxFemaleCount) + 
										   CommUtils.nullToZero(roomAndGuest.room.RoomChildA70Count) +
										   CommUtils.nullToZero(roomAndGuest.room.RoomChildB50Count) +
										   CommUtils.nullToZero(roomAndGuest.room.RoomChildC30Count);
				String warningMsg = '';
				if (roomAndGuest.room.PerRoomPaxCount == null || roomAndGuest.room.PerRoomPaxCount == 0) {
					// XMLの中に、未設定する場合、自動的にSFの初期値で自動設定を行う「非設定する場合、自動設定を行う」
					if (calRoomPaxCount > 0) {
						// 1室利用人数
						newLead.StayPersons__c = calRoomPaxCount;
					} else {
						// 該当ケースする場合、注意事項に自動内容追加を行う
						//サイトコントローラからの予約データのなかに、予約人数がありませんでしたので、デフォルト値(仮の値)を設定させていただきました、つきましては、ご予約者の方へご確認していただきまして、本予約データの予約人数を手動にて変更ください。
						warningMsg = '<font color="red">'+ Label.MSG_038_0037 +'</font><br/>';
					}
				} else {
					// 1室利用人数
					newLead.StayPersons__c = roomAndGuest.room.PerRoomPaxCount;
				}
				// 大人人員(男性)
				newLead.Mans__c = roomAndGuest.room.RoomPaxMaleCount;
				// 大人人員(女性)
				newLead.Femails__c = roomAndGuest.room.RoomPaxFemaleCount;
				// 子供A人数
				newLead.ChildFA__c = roomAndGuest.room.RoomChildA70Count;
				// 子供B人数
				newLead.Childs__c = roomAndGuest.room.RoomChildB50Count;
				// 子供C人数
				newLead.ChildC__c = roomAndGuest.room.RoomChildC30Count;
				//　予約インデックスID
				newLead.LeadIndexRef__c = leadIndex.Id;
				// プラン情報
				newLead.Field310__c = curPlan == null ? null : curPlan.Id;
				// 特記事項設定[一泊で2部屋以上の自動とりこみ予約のときは、特記事項を一つのみとする]
				//if (j == 0) {
				newLead.Comment3__c = warningMsg + bookingInfo.OtherServiceInformation;
				//}
				// 2013/07/16 記号機能対応 BEGIN
				// 予約データは親部屋に集めるの場合
				//else 
				if (j > 0 && CommConst.APPOTION_LEADSPLIT_DIV_CODE == CommConst.APPOTION_LEADSPLIT_DIV_CODE_UNION){
					// 代表部屋以外のデータ
					newLead.StayPersons__c = 0;
					// 大人人員(男性)
					newLead.Mans__c = 0;
					// 大人人員(女性)
					newLead.Femails__c = 0;
					// 子供A人数
					newLead.ChildFA__c = 0;
					// 子供B人数
					newLead.Childs__c = 0;
					// 子供C人数
					newLead.ChildC__c = 0;
					// プラン情報 <- NULL
					newLead.Field310__c = null;
					// コメント
					newLead.Comment3__c = null;
				}
				// 2013/07/16 記号機能対応 END
				// 旅行会社関連参照情報設定
				// 2016/02/01 ネットからの取込時に予約チャネルに旅行会社名で設定する BEGIN
				//newLead.SalesOfficeInfoRef__c = TraveCompany.Id;
				newLead.SalesOfficeInfoRef__c = (TraveCompany.size() > 1 ? TraveCompany[1].Id : TraveCompany[0].Id);
				// 2016/02/01 ネットからの取込時に予約チャネルに旅行会社名で設定する END
//System.debug('bookingInfo.OtherServiceInformation:' + bookingInfo.OtherServiceInformation);
//System.debug('newLead.Comment3__c:' + newLead.Comment3__c);
				// メール本文
				newLead.email__c = risaplBasic.TelegramData;
				// 2012/12/23  Add
				newLead.RoomGroupNo__c = j;//roomNoIdx;
				// 2013/06/25 ADD 旅行会社名から予約チャネルに設定する
				// 2016/02/01 ネットからの取込時に予約チャネルに旅行会社名で設定する BEGIN
				//newLead.Field2__c = TraveCompany.Name;
				newLead.Field2__c = (TraveCompany.size() > 0 ? TraveCompany[0].Name : null);
				// 2016/02/01 ネットからの取込時に予約チャネルに旅行会社名で設定する END
				// 2016/10/10 在庫変更処理対応(発生源) BEGIN by zh
				newLead.EventSource__c = APPNAME + '_' + bookingInfo.DataID + '_' + DateTime.now().getTime();
				// 2016/10/10 在庫変更処理対応(発生源) END by zh
				insLeadLst.add(newLead);
			}
			// Parent6の場合、外部LOOPを行わない
			//if (isParten6Flg) break;
			//roomNoIdx++;
		}
		// 見積り金額設定を行う「一件のみ設定する」
		insLeadLst[0].BridalDantaikei__c = bookingInfo.TotalAccommodationCharge;

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

    private static map<Integer,Room__c> getCanAssignRoom(LeadIndex__c leadIndex, Map<String,Id> roomTypeMap, boolean autoAssingRoomflag, BI_TL_SyncInfo bookingInfo){
            
            map<Id, Id> targetRoomIdTypeMap = new map<Id, Id>();
            map<Id, List<Room__c>> wkCanAssignRoomMap = new map<Id, List<Room__c>>();
            map<Integer,Room__c> resultMap = new map<Integer, Room__c>();
            // 自動割り振りの順次でアサイン対象部屋情報を取得する
	    	List<Id> roomTypeIdLst = roomTypeMap.values();
            String queryHead = 'select id,Name,TypeRoomRef__c from Room__c ';
            String queryWhere = ' where UseOfRoom__c = \'' + String.escapeSingleQuotes(CommConst.ROOM_UseOfType_Guest) + '\'' +
                                ' And TypeRoomRef__c in :roomTypeIdLst ';
            String queryOrder = ' Order By priority__c NULLS LAST ';
            String queryString = queryHead + queryWhere + queryOrder;
            //mLogUtils.write_log('queryString::' + queryString);
			// 今回XMLに指定の部屋タイプに関連の部屋定義情報を取得する
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
            // アサインできる部屋はない場合、チェック処理中止
            if(canAssignRoomMap.isEmpty()) return resultMap;
            // 2015/10/31 故障部屋チエックロジックを追加対応 BEGIN
            // 同じ部屋、利用日により、同じ部屋は連続の日付はリストに入る
            // 開始日　〜　終了日期間日を取得する
	        Integer nights = bookingInfo.Nights;            // 総宿泊数
	        if (nights == 0) nights = 1;
	        Integer rooms = bookingInfo.TotalRoomCount;     // 総部屋数
			// 部屋→部屋タイプリスト→map<部屋タイプコード、関連の日付>
			//List<List<map<string,list<Date>>>> roomTypeList = new List<List<map<string,list<Date>>>>(); 
			//map<Integer, list<date>> roomTypeDateLinkMap = new map<Integer, list<date>>();
			
			// 部屋単位に、宿泊期間内の部屋タイプリスト一覧情報を格納する
			map<Integer, list<string>> tmpRoomTypeListMap = new map<Integer, list<string>>();
			// 宿泊期間情報を格納する、1部屋A：1/1,1/2,1/3日は同じ部屋タイプすると、0,1,2は同じリストを格納する<1, <1/1,1/2,1/3>, 2,<1/1,1/2,1/3>>...
			map<Integer, list<date>> roomTypeDateLinkByIdxMap = new map<Integer, list<date>>();
            BI_TL_RoomAndGuestInfo[] roomAndGuest = bookingInfo.roomAndGuestLst;
			// XMLの宿泊部屋単位情報
        	for(Integer j = 0; j < rooms; j ++){
        		list<string> oneRoomRoomTypes = new list<string>();
        		tmpRoomTypeListMap.put(j, oneRoomRoomTypes);
        		// 1部屋N日単位情報
	        	for(Integer i = 0; i < nights; i ++){
	        		// 情報を取得IDEXを定義する
	        		Integer idx = i * rooms + j;
	        		// 部屋タイプリスト情報を格納する
	        		String roomTypeCd = roomAndGuest[idx].room.RoomTypeCode;
	        		// 部屋利用日（到着日)
                	Date stayDate = roomAndGuest[idx].roomRateLst[0].RoomDate;
					if (oneRoomRoomTypes.isEmpty()) {
						oneRoomRoomTypes.add(roomTypeCd);
						list<date> newitems = new list<date>{stayDate};
						roomTypeDateLinkByIdxMap.put(idx, newitems);
					} else {
						// 前回の部屋タイプを取得して、
						string preRoomTypeCd = oneRoomRoomTypes[oneRoomRoomTypes.size()-1];
						// 泊期間に、部屋タイプ変更の場合
						if (preRoomTypeCd != roomTypeCd) {
							oneRoomRoomTypes.add(roomTypeCd);
							list<date> newitems = new list<date>{stayDate};
							roomTypeDateLinkByIdxMap.put(idx, newitems);
						} else {
							// 日付を連続に設定を行う
							list<date> preitems = roomTypeDateLinkByIdxMap.get((i-1) * rooms + j);
							preitems.add(stayDate);
							roomTypeDateLinkByIdxMap.put(idx, preitems);
						}
					}
	        	}
        	}
        	// 2015/10/31 故障部屋チエックロジックを追加対応 END
        	set<id> isAutoAssignRoomtSet = new set<Id>();
        	for (list<Room__c> canAssRooms : canAssignRoomMap.values()) {
        		for (Room__c canAssRoom : canAssRooms) {
        			isAutoAssignRoomtSet.add(canAssRoom.id);
        		}
        	}
            RoomStatusManager roomStatusManger = new RoomStatusManager();
	    	// 指定期間ないの故障部屋リストを取得する
	    	List<RoomsStatus__c> roomsStatus = roomStatusManger.queryBadRoomList(leadIndex.EntryDate__c,leadIndex.DepartureDate__c ,isAutoAssignRoomtSet);
	//system.debug(logginglevel.info,'=========' + roomsStatus);
	    	// 指定部屋の故障ありの日付情報を格納する
	    	Map<id,List<RoomsStatus__c>> badRoomStatusMap = new Map<id,List<RoomsStatus__c>>();
	    	//Map<Id, String> roomNameMap = new map<Id, String>();
	    	for(RoomsStatus__c roomStatus : roomsStatus){
	    		//roomNameMap.put(roomStatus.RoomRef__c, roomStatus.RoomRef__r.Name);
	    		if(!badRoomStatusMap.containsKey(roomStatus.RoomRef__c)){
	    			badRoomStatusMap.put(roomStatus.RoomRef__c,new List<RoomsStatus__c>());
	    		}
	    		badRoomStatusMap.get(roomStatus.RoomRef__c).add(roomStatus);
	    		//Set<Date> curSet = badRoomStatusMap.get(roomStatus.RoomRef__c);
	    		//integer betweenLength = roomStatus.StatusBeginDate__c.daysBetween(roomStatus.StatusEndDate__c);
	    		//curSet.addAll(CommUtils.getDaysList(roomStatus.StatusBeginDate__c,betweenLength));
	    		//if(canAssignRoomMap.containsKey(roomStatus.RoomRef__c))canAssignRoomMap.remove(roomStatus.RoomRef__c);
	    	}
	    	
	    	// 部屋単位
			for(Integer j = 0; j < rooms; j ++){
        		// 日単位情報
	        	for(Integer i = 0; i < nights; i ++){
					// 情報を取得IDEXを定義する
	        		Integer idx = i * rooms + j;
	        		// 部屋タイプリスト情報を格納する
	        		String roomTypeCd = roomAndGuest[idx].room.RoomTypeCode;
	        		Id roomTypeId = roomTypeMap.get(roomTypeCd);
	        		if (roomTypeId == null) continue;
	        		// 部屋タイプ関連の部屋リストを取得する
	        		List<Room__c> locCanAssingRoomList = canAssignRoomMap.get(roomTypeId);
	        		if (locCanAssingRoomList == null || locCanAssingRoomList.isEmpty()) continue;
    				// 該当部屋は故障チェックの期間情報を取得する
    				list<date> assingRangeDates = roomTypeDateLinkByIdxMap.get(idx);
    				// 連続期間ない場合、処理対象外
    				if (assingRangeDates == null || assingRangeDates.isEmpty()) continue;
    				// 同部屋タイプ連泊の期間日付の開始と終了日付を取得する
    				Date startDt = assingRangeDates[0];
    				Date endDt = assingRangeDates[assingRangeDates.size()-1];
	        		// 該当部屋は指定期間に、故障あり、なしチエックを行う
	        		Room__c targetRoom = null;
	        		for (Room__c room : locCanAssingRoomList) {
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
	    				resultMap.put(idx, targetRoom);
	    				// 連続の期間が存在する場合、同じ部屋は同じ部屋タイプにアサインする
	    				integer betweenLength = startDt.daysBetween(endDt);
	    				// 連泊期間内の同じ部屋を割当てする設定を行う「次の泊から」
	    				for (integer cKey = 1; cKey <= betweenLength; cKey++) {
							integer plusIdx = i + cKey;
	    					integer key = plusIdx * rooms + j;
	    					resultMap.put(key, targetRoom);
	    				}
	    				i += betweenLength;
        			}	
	        	}
			}
            return resultMap;
    }
	/**
	* 代表者として、取引先責任者作成する
	**/
	private static Contact upsertContact(BI_TL_SyncInfo bookingInfo) {
System.debug('-------- upsertContact Begin ------');

		// 2013.07.12 ADD 申込者と申込電話は予約に設定する
		// 予約者情報
		BI_TL_Member member = bookingInfo.risaplsinformation.risaplsCommonInformation.member;
		String applicantName = member != null ? member.UserName : null;		// 申込者
		String applicantPhone = member != null ? member.UserTel : null;		// 申込者電話
		// 代表者情報
		BI_TL_RisaplBasic risaplBasic = bookingInfo.risaplsinformation.risaplsCommonInformation.risaplBasic;
		// 代表者電話番号
		String phoneNumber = risaplBasic.PhoneNumber;
		// 顧客様名
		//Contact existContact
		String contactNameKana = bookingInfo.GuestOrGroupNameSingleByte;
		String contactNameKanji = bookingInfo.GuestOrGroupNameKanjiName;
		String contactNameKataKana = bookingInfo.GuestOrGroupNameDoubleByte;
		String contactName = CommUtils.isBlank(bookingInfo.GuestOrGroupNameKanjiName) ? bookingInfo.GuestOrGroupNameSingleByte : bookingInfo.GuestOrGroupNameKanjiName;
		String[] contactNameArr = CommUtils.splitName(contactName);
		String lastName = contactNameArr[0];
		String firstName = (contactNameArr.size() > 1 ? contactNameArr[1] : '');
		String fullName = (lastName + ' ' + firstName).trim();
		// 顧客様名と顧客様電話番号で、既存データ存在チェックを行う
		List<Contact> existCList = null;
		// 2016/05/25 お客様電文番号は[--]の場合、エラー回避
		phoneNumber = CommUtils.convTelphoneNumber(phoneNumber);
		// 2017/12/14 SOSLキーチェック追加対応 BEGIN
		//if (!CommUtils.isBlank(phoneNumber)) {
		if (CommUtils.isValidateSoslKey(phoneNumber)) {
		// 2017/12/14 SOSLキーチェック追加対応 END
			// 既存顧客様情報を探す
			//phoneNumber = CommUtils.convTelphoneNumber(phoneNumber);
			//String exitQueryStr = ' Select id,ApplicantName__c,ApplicantPhone__c From contact where ( KanaName1__c = :contactNameKana OR Name = :fullName ';
			//2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH BEGIN 
			// ,Name1__c,KanaName1__c,Katakana__c,Email,MailingPostalCode,Phone取得項目を追加する
			String soslQuery = 'FIND :phoneNumber IN PHONE FIELDS RETURNING CONTACT (id, name,Name1__c,KanaName1__c,Katakana__c,Email,MailingPostalCode,Phone where Name = :fullName ';
			//2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH END
			if (!CommUtils.isBlank(contactNameKana)) soslQuery += ' OR KanaName1__c =:contactNameKana ';
			if (!CommUtils.isBlank(contactNameKanji)) soslQuery += ' OR Name1__c = :contactNameKanji ';
			if (!CommUtils.isBlank(contactNameKataKana)) soslQuery += ' OR Katakana__c = :contactNameKataKana ';
			//exitQueryStr += ' ) And Phone = :phoneNumber ';
			//existCList = [select id from contact where (Name = :contactName Or Name1__c = :contactName Or KanaName1__c = :contactName Or Katakana__c = :contactName ) And Phone = :phoneNumber ];
			//existCList = DataBase.query(exitQueryStr);
			soslQuery += ' limit 1) ';
			List<List<Sobject>> existRs = search.query(soslQuery);
			existCList = existRs[0];
		}
		if (existCList != null && !existCList.isEmpty()) {
			existCList[0].ApplicantName__c = applicantName;
			existCList[0].ApplicantPhone__c = applicantPhone;
			//2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH BEGIN
			// 団体名または代表者氏名 漢字
			if(CommUtils.isBlank(existCList[0].Name1__c) && !CommUtils.isBlank(bookingInfo.GuestOrGroupNameKanjiName))
				existCList[0].Name1__c = bookingInfo.GuestOrGroupNameKanjiName;
			// 団体名または代表者氏名(半角)
			if(CommUtils.isBlank(existCList[0].KanaName1__c) && !CommUtils.isBlank(bookingInfo.GuestOrGroupNameSingleByte))
				existCList[0].KanaName1__c = bookingInfo.GuestOrGroupNameSingleByte;
			// ひらがな ←　団体名または代表者氏名よみがな(全角)
			if(CommUtils.isBlank(existCList[0].Katakana__c) && !CommUtils.isBlank(bookingInfo.GuestOrGroupNameDoubleByte))
				existCList[0].Katakana__c = bookingInfo.GuestOrGroupNameDoubleByte;
			// メール
			if(CommUtils.isBlank(existCList[0].Email) && !CommUtils.isBlank(risaplBasic.Email))
				existCList[0].Email = risaplBasic.Email;
			// 郵便番号
			if(CommUtils.isBlank(existCList[0].MailingPostalCode) && !CommUtils.isBlank(risaplBasic.PostalCode))
				existCList[0].MailingPostalCode = risaplBasic.PostalCode;
			// Phone
			if(CommUtils.isBlank(existCList[0].Phone) && !CommUtils.isBlank(risaplBasic.PhoneNumber))
				existCList[0].Phone = risaplBasic.PhoneNumber;
			//2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH END
			//2016/05/24  お客様重複チェック対応 BEGIN
			//update existCList[0];
			existCList[0] = (new CommLogicProcess()).upsertDuplicateErrorProcess(existCList[0]);
			//2016/05/24  お客様重複チェック対応 END
			return existCList[0];
		}
		// 非存在する場合（あり得ない）
		//throw new CommException('代表者情報の詳細情報を未設定するため、確認必要があり');
		// 代表者は顧客新規作成を行う
		Contact newContact = new Contact(
			// 2013/07/17 団体名または代表者氏名 漢字優先で設定、空白場合、団体名または代表者氏名(半角)に設定する
			// 団体名または代表者氏名(半角)
			LastName =  lastName,
			FirstName = firstName,
			// 団体名または代表者氏名 漢字
			Name1__c = bookingInfo.GuestOrGroupNameKanjiName,
			// 2013/07/17 団体名または代表者氏名(半角)に設定する
			// 団体名または代表者氏名よみがな(全角)
			//KanaName1__c = bookingInfo.GuestOrGroupNameDoubleByte,
			KanaName1__c = bookingInfo.GuestOrGroupNameSingleByte,
			// ひらがな ←　団体名または代表者氏名よみがな(全角)
			Katakana__c = bookingInfo.GuestOrGroupNameDoubleByte,
			// 電話
			//Phone = risaplBasic.PhoneNumber,
			Phone = CommUtils.isBlank(phoneNumber) ? null : risaplBasic.PhoneNumber,
			// メール
			Email = risaplBasic.Email,
			// 郵便番号
			MailingPostalCode = risaplBasic.PostalCode,
			// 住所
			MailingStreet = risaplBasic.Address,
			// 申込者
			ApplicantName__c = applicantName,
			// 申込者電話番号
			ApplicantPhone__c = applicantPhone
		 );
		//2016/05/24  お客様重複チェック対応 BEGIN
		//insert newContact;
		newContact = (new CommLogicProcess()).upsertDuplicateErrorProcess(newContact);
        // 2016/05/24 お客様重複チェック対応 END
return newContact;
		// 2013/07/14 DELETE 更新・キャンセル機能削除
		/*
		// 既存の代表者が存在する場合　
		//List<Contact> pkContactLst = [select id, name, phone from Contact
		//	where name = :bookingInfo.GuestOrGroupNameSingleByte And Phone = :bookingInfo. ]
		// 代表者詳細情報を取得する
		Map<String, Contact> contactMap = new Map<String, Contact>();
System.debug('-------- bookingInfo.roomAndGuestLst ------' + bookingInfo.roomAndGuestLst);
		for (BI_TL_RoomAndGuestInfo roomAndGuest: bookingInfo.roomAndGuestLst) {
			// 顧客明細情報がない場合、下記設定処理SKIP
			if (roomAndGuest.guestLst == null) break;
			for (BI_TL_GuestInfo guest : roomAndGuest.guestLst) {
				// 顧客名
				String contactNm = guest.GuestNameSingleByte;
				// すでに存在している情報はSKIPする
				if (contactMap.containsKey(contactNm)) continue;

				// 新規存在の顧客情報を設定する
				Contact contactItem = new Contact();
				// 顧客名
				contactItem.LastName = guest.GuestNameSingleByte;
				// 漢字
				contactItem.Name1__c = guest.GuestKanjiName;
				// カナ
				//contactItem.KanaName1__c = guest.GuestNameSingleByte;
				// 性別
				if (!CommUtils.isBlank(guest.GuestGender)) contactItem.gender__c = (guest.GuestGender == 'Female' ? '女性' : '男性');
				// 年齢
				if (guest.GuestAge != null) contactItem.Birthdate = Date.newInstance(Date.today().year() - guest.GuestAge, Date.today().month(), Date.today().day());
				// 誕生日
				if (guest.GuestDateOfBirth != null) contactItem.Birthdate = guest.GuestDateOfBirth;
				// Phone
				contactItem.Phone = guest.GuestPhoneNumber;
				// 緊急連絡先
				contactItem.Phone2__c = guest.GuestEmergencyPhoneNumber;
				// お客様Email
				contactItem.Email = guest.GuestEmail;
				// お客様住所都道府県
				contactItem.MailingStreet = guest.GuestStateProvidence;
				// MAPに、顧客上はMAPに格納する
				contactMap.put(contactNm, contactItem);
			}
		}
System.debug('-------- upsertContact step1 ------');
		// 代表者情報は取得取得処理を行う
		String primaryUsr = bookingInfo.GuestOrGroupNameSingleByte;
		Contact curContact = null;
		// メンバー設定情報から代表者詳細情報を取得、登録する
		if (contactMap.containsKey(primaryUsr)) {
			curContact = contactMap.get(primaryUsr);
			// 存在する場合、顧客情報はSFから情報存在チェックを行う
			// 顧客存在するかどうかチェックTODO：方法が確認が必要
			List<Contact> existContactLst = [select id from Contact where LastName = :primaryUsr and phone = :curContact.phone limit 1];
			// 存在する場合、更新を行う
			if (!existContactLst.isEmpty()) {
				// TODO UPDATE
				curContact = existContactLst[0];
			} else {
				// INSERT CONTACT
				insert curContact;
			}
		} else {
			// 非存在する場合（あり得ない）
			//throw new CommException('代表者情報の詳細情報を未設定するため、確認必要があり');
			// 代表者は顧客新規作成を行う
			curContact = new Contact(
				// 団体名または代表者氏名(半角)
				LastName = bookingInfo.GuestOrGroupNameSingleByte,
				// 団体名または代表者氏名 漢字
				Name1__c = bookingInfo.GuestOrGroupNameKanjiName,
				// 団体名または代表者氏名よみがな(全角)
				KanaName1__c = bookingInfo.GuestOrGroupNameDoubleByte
			 );
			 insert curContact;
		}
System.debug('-------- upsertContact End ------');
		return curContact;
		*/
	}


	/*
	 * 旅行会社情報はSFへ登録を行う
	 * 会社・営業所が存在する場合、営業所は
	 */
	private static List<Account> upsertTravelInfo (BI_TL_SyncInfo bookingInfo) {
		// 旅行会社のPakcageコードは再設定を行う
		BI_TL_RisaplBasic risaplBasic = bookingInfo.risaplsinformation.risaplsCommonInformation.risaplBasic;
		bookingInfo.SalesOfficeCompanyCode = risaplBasic.SalesOfficeCompanyCode;
		// 旅行会社名と同じ取引先が存在するかどうかチェックを行う
		Account travelCompany = null;
		// 2016/02/01 取引先（旅行会社）情報取得方式変更 BEGIN
		if (!CommUtils.isBlank(bookingInfo.SalesOfficeCompanyCode) ) {
			List<Account> travelCompanyLst = [select id , name from Account
				where AccountType__c = :CommConst.ACCOUNT_TYPE_TRAVEL
				and SalesOfficeCompanyCodeTL__c = :bookingInfo.SalesOfficeCompanyCode limit 1];
			if (!travelCompanyLst.isEmpty()) travelCompany = travelCompanyLst[0];
		}
		// 2016/02/01 取引先（旅行会社）情報取得方式変更 END
		// 旅行会社存在する場合
		if (travelCompany == null &&
			!CommUtils.isBlank(bookingInfo.SalesOfficeCompanyName) &&
			!CommUtils.isBlank(bookingInfo.SalesOfficeCompanyCode) ) {
			List<Account> travelCompanyLst = [select id , name, SalesOfficeCompanyCodeTL__c from Account
				where name = :bookingInfo.SalesOfficeCompanyName 
				And AccountType__c = :CommConst.ACCOUNT_TYPE_TRAVEL
				and SalesOfficeCompanyCode__c = :bookingInfo.SalesOfficeCompanyCode limit 1];
			// 存在なければ、取引先を新規作成する
			if (travelCompanyLst.isEmpty()) {
					travelCompany = new Account();
					travelCompany.Name = bookingInfo.SalesOfficeCompanyName;
					travelCompany.SalesOfficeCompanyCode__c = bookingInfo.SalesOfficeCompanyCode;
					travelCompany.AccountType__c = CommConst.ACCOUNT_TYPE_TRAVEL;
					// 2016/02/01 取引先（旅行会社）情報取得方式変更 BEGIN
					travelCompany.SalesOfficeCompanyCodeTL__c = bookingInfo.SalesOfficeCompanyCode;
					// 2016/02/01 取引先（旅行会社）情報取得方式変更 END
					insert travelCompany;
			} else {
				travelCompany = travelCompanyLst[0];
				// 2016/02/01 取引先（旅行会社）情報取得方式変更 BEGIN
				if (CommUtils.isBlank(travelCompany.SalesOfficeCompanyCodeTL__c)) {
					travelCompany.SalesOfficeCompanyCodeTL__c = bookingInfo.SalesOfficeCompanyCode;
					update travelCompany;
				}
				// 2016/02/01 取引先（旅行会社）情報取得方式変更 END
			}
		}

		Account traveOffice = null;
        // 2016/02/01 旅行会社（営業所）の取得方式変更（「営業所コード」と「取引先ID」で合わせて取得する）BEGIN
		if (!CommUtils.isBlank(bookingInfo.SalesOfficeCode)) {
			// 取引先IDと営業所コードで存在チェックを行う
			List<Account> traveOfficeLst = [select id , name, ParentId,SalesOfficeCodeTL__c from Account
				where AccountType__c = :CommConst.ACCOUNT_TYPE_TRAVEL
				and ParentId = :travelCompany.Id
				and	(SalesOfficeCodeTL__c = :bookingInfo.SalesOfficeCode
					OR
					 SalesOfficeCode__c = :bookingInfo.SalesOfficeCode)
				limit 1];
			if (!traveOfficeLst.isEmpty()) {
				traveOffice = traveOfficeLst[0];
				// 既存の取引先（営業所）のコードはNULLの場合、自動設定を行う
				if (CommUtils.isBlank(traveOffice.SalesOfficeCodeTL__c)) {
					traveOffice.SalesOfficeCodeTL__c = bookingInfo.SalesOfficeCode;
					update traveOffice;
				}
			}
		}
		// 2016/02/01 旅行会社（営業所）の取得方式変更（「営業所コード」と「取引先ID」で合わせて取得する）END
		// 旅行会社営業所情報が存在する場合
		if (traveOffice == null &&
			!CommUtils.isBlank(bookingInfo.SalesOfficeCode) &&
			!CommUtils.isBlank(bookingInfo.SalesOfficeName) ) {
			// 旅行会社営業所情報をチェックを行う
			List<Account> traveOfficeLst = [select id , name, ParentId, SalesOfficeCodeTL__c from Account
				where name = :bookingInfo.SalesOfficeName 
				and AccountType__c = :CommConst.ACCOUNT_TYPE_TRAVEL
				and SalesOfficeCode__c = :bookingInfo.SalesOfficeCode limit 1];
			if (traveOfficeLst.isEmpty()) {
				traveOffice = new Account();
				traveOffice.Name = bookingInfo.SalesOfficeName;
				traveOffice.AccountType__c = CommConst.ACCOUNT_TYPE_TRAVEL;
				traveOffice.SalesOfficeCode__c = bookingInfo.SalesOfficeCode;
				// 2016/02/01 旅行会社（営業所）の取得方式変更（「営業所コード」と「取引先ID」で合わせて取得する）BEGIN
				traveOffice.SalesOfficeCodeTL__c = bookingInfo.SalesOfficeCode;
				// 2016/02/01 旅行会社（営業所）の取得方式変更（「営業所コード」と「取引先ID」で合わせて取得する）END
				traveOffice.ParentId = (travelCompany != null ? travelCompany.Id : null);
				traveOffice.Phone = bookingInfo.SalesOfficePhoneNumber;
				insert traveOffice;
			} else {
				traveOffice = traveOfficeLst[0];
				// 既存の取引先（営業所）のコードはNULLの場合、自動設定を行う
				if(traveOffice.ParentId != travelCompany.Id || CommUtils.isBlank(traveOffice.SalesOfficeCodeTL__c)) {
					traveOffice.ParentId = travelCompany.Id;
					traveOffice.SalesOfficeCodeTL__c = bookingInfo.SalesOfficeCode;
					update traveOffice;
				}
			}
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
		// 2016/02/01 ネットからの取込時に予約チャネルに旅行会社名で設定する BEGIN
		//return (traveOffice == null ? travelCompany: traveOffice);
		List<Account> rsAccountLst = new List<Account>();
        if (travelCompany != null) rsAccountLst.add(travelCompany);
        if (traveOffice != null) rsAccountLst.add(traveOffice);
        return rsAccountLst;
        // 2016/02/01 ネットからの取込時に予約チャネルに旅行会社名で設定する END
	}

	// 支払方法転換
	private static string getLocalPaymentInfo (String mediaType) {
		String ttendType = null;
		if (mediaType == 'Cach'|| mediaType == 'Cash') ttendType = CommConst.MEDIA_TYPE_CD_01;
		else if (mediaType == 'CreditCard') ttendType = CommConst.MEDIA_TYPE_CD_02;
		//else if (mediaType == '売掛') ttendType = CommConst.MEDIA_TYPE_CD_03;
		else if (mediaType == 'Coupon') ttendType = CommConst.MEDIA_TYPE_CD_11;
		// 支払方法設定
		String mediaTypeName = CommConst.getPaymentTypeLabelByKey(ttendType);
		return (mediaTypeName == null ? mediaType : mediaTypeName);
	}

	global class BI_TL_SyncInfo {
		// 情報区分 TransactionType
		webservice String DataFrom;
		//webservice String DataClassification;
		webservice BI_TL_DmlAction dmlAction;
		webservice String DataID;                     // 外部キー：予約管理ID（一意制御あり）
		webservice Date SystemDate;                   // 使わない
		webservice Time SystimTime;                   // 使わない
		// 宿泊施設側情報
		webservice String AccommodationName;          // 使わない
		webservice String AccommodationCode;          // 使わない
        webservice String AccommodationArea;  //宿泊地区名
        webservice String ChainName;  //チェーンホテル名        
        webservice String AccommodationPersonInCharge;  //宿泊施設担当者名      
        webservice String AccommodationEmail;  //宿泊施設担当者Email       
        webservice String AccommodationPhoneNumber;  //宿泊施設電話番号     
		webservice List<BI_TL_BankInfo> bankLst;    //振込銀行情報
		webservice String AccommodationCPUAddress;  //宿泊施設宛先指定  
		// 	旅行会社情報 : SalesOfficeInformation
		webservice String SalesOfficeCompanyCode;	  // XMLに該当項目がないので、常にNULLで初期化されれている
		webservice String SalesOfficeCompanyName;
		webservice String SalesOfficeName;
		webservice String SalesOfficeCode;
		webservice String SalesOfficePersonInCharge;
		webservice String SalesOfficeEmail;
		webservice String SalesOfficePhoneNumber;
		//// 住所
		webservice String SalesOfficeStateProvidence;
		webservice String SalesOfficeCityName;
		webservice String SalesOfficeAddressLine;
		webservice String SalesOfficeStreetNumber;
		webservice String SalesOfficePostalCode;
		webservice String SalesOfficeRegisteredCategory;                //旅行会社登録種別
        webservice String SalesOfficeLicenseNumber;             //旅行会社登録番号
        webservice String SalesOfficeRegisteredPrefecture;              //旅行会社登録行政庁
        webservice String SalesOfficeCPUAddress;                //旅行会社宛先指定
        webservice String RetailerCompanyName;              //販売代理店会社名
        webservice String RetailerOfficeName;               //販売代理店営業所名
        webservice String RetailerOfficeCode;               //販売代理店営業所コード
        webservice String RetailerPersonInCharge;               //販売代理店担当者名
        webservice String RetailerEmail;                //販売代理店担当者Email
        webservice String RetailerPhoneNumber;              //販売代理店電話番号
        webservice String RetailerStateProvidence;              //販売代理店住所都道府県
        webservice String RetailerCityName;             //販売代理店住所区市名
        webservice String RetailerAddressLine;              //販売代理店住所町村名
        webservice String RetailerStreetNumber;             //販売代理店住所番地名
        webservice String RetailerPostalCode;               //販売代理店住所郵便番号
        webservice String RetailerRegisteredCategory;               //販売代理店登録種別
        webservice String RetailerLicenseNumber ;           //販売代理店登録番号
        webservice String RetailerRegisteredPrefecture;             //販売代理店登録行政
		// 基本宿泊情報: BasicInformation
		webservice String TravelAgencyBookingNumber;      // 使わない
		webservice Date TravelAgencyBookingDate;
		webservice Time TravelAgencyBookingTime;
		webservice String TravelAgencyReportNumber;
		//// 団体名または代表者氏名(半角)->必須
		webservice String GuestOrGroupNameSingleByte;
		webservice String GuestOrGroupNameDoubleByte;
		webservice String GuestOrGroupNameKanjiName;
		webservice Date CheckInDate;
		webservice Time CheckInTime;
		webservice Date CheckOutDate;
		webservice Time CheckOutTime;
		webservice Integer Nights;
		webservice String Transportaion;
		////利用客室合計数
		webservice Integer TotalRoomCount;
		////お客様総合計人数
		webservice Integer GrandTotalPaxCount;
		webservice Integer TotalPaxMaleCount;
		webservice Integer TotalPaxFemaleCount;
		webservice Integer TotalChildA70Count;
		webservice Integer TotalChildB50Count;
		webservice Integer TotalChildC30Count;
		webservice Integer TotalChildDNoneCount;
		webservice String PackagePlanName;
		webservice String PackagePlanCode;
		webservice String PackagePlanContent;
		////食事条件:TODO　名から実際のあ約タイプに変換する
		webservice String MealCondition;
		////食事有無情報
		webservice String SpecificMealCondition;
		////食事個所情報
		webservice String MealPlace;                  // 非使用
		// 電文(予約詳細： 一日ごとの大人子供人数の内訳、料金詳細などを出力する。 予約詳細情報は最初の情報が「ZZ」で始まり「,ZZ」で区切られる。)
		webservice String SpecialServiceRequest;
		// 備考
		webservice String OtherServiceInformation;
		// 詳細情報有無
		webservice String FollowUpInformation;        // 非使用
		webservice String AccommodationConfirmationNumber;              //宿泊個所予約番号
        webservice String GroupNameWelcomeBoard;                //団体名(ウェルカムボード用)
        webservice Integer CoachCount;              //入込バス台数
        webservice String CoachCompany;             //入込バス会社名
        webservice Integer TotalChildOtherCount;                //子供その他人数合計
        webservice Integer TotalTourConductorCount;             //添乗員人数合計
        webservice Integer TotalCoachDriverCount;               //バスドライバー人数合計
        webservice Integer TotalGuideCount;             //バスガイド人数合計
        webservice String TypeOfGroup;              //参加形態
        webservice String Status;               //予約ステータス
        webservice String PackageType;              //企画商品区分
        webservice String BanquetRoom;              //宴会場利用
        webservice String ModificationType;             //変更点区分
        webservice String ModificationPoint;                //変更ポイント説明
        webservice String CancellationNumber;               //宿泊施設取消番号
        webservice String PreviousPlace ;           //前泊地
        webservice String PreviousAccommodationName;                //前泊宿泊施設名       
        // BasicRateInformation
        webservice String RoomRateOrPersonalRate;
        webservice String TaxServiceFee;
        webservice String Payment;
        webservice Integer BareNetRate;
        webservice String CreditCardAuthority;
        webservice String CreditCardNumber;
		// 合計宿泊料金(総額)
		webservice Integer TotalAccommodationCharge;
        webservice Integer TotalAccommodationHotSpringTax;
        webservice Integer TotalAccommodationServiceFee;
		webservice Integer TotalAccommodationOtherFee;
		webservice Decimal CommissionPercentage;
		webservice List<BI_TL_CouponInfo> CouponLst;        //クーポン明細
        webservice Integer CancellationCharge;              //前広取消に対する取消料情報
        webservice Date ExpireDate;             //クレジットカード有効期限
        webservice String CardHolderName;               //クレジットカード保有者氏名
        webservice Integer TotalAccommodationConsumptionTax;                //合計宿泊料金消費税
        webservice Integer TotalAccommodationHotelTax;              //合計宿泊料金ホテル税他
        webservice Integer TotalAccommodationBreakfastFee;              //合計朝食料金
        webservice Integer TotalAccommodationCommissionAmount;              //合計手数料総額
        webservice Integer TotalAccommodationCommissionConsumptionTax;              //合計手数料消費税総額
        webservice Integer TotalAccommodationChargeAfterCheckIn;                //宿泊当日変更後の宿泊料金(総額)
        webservice Integer TotalBalanceAfterCheckIn;                //宿泊当日変更後の宿泊料金(差額)
        webservice Integer TotalAccommodationConsumptionAfterCheckIn;               //宿泊当日変更後の手数料消費税
        webservice Integer CancellationChargeAfterCheckIn;              //宿泊当日取消に対する取消料情報
        webservice Integer MembershipFee;               //定率会費
        webservice Integer AdjustmentFee;               //精算調整額
		// 個々の部屋とお客様情報<1:N>
		webservice List<BI_TL_RoomAndGuestInfo> roomAndGuestLst;
		// 7-1
		webservice BI_TL_Risaplsinformation risaplsinformation;
	}
	global class BI_TL_BankInfo {
        webservice String BankName;         //振込銀行名
        webservice String BankAccountNumber;            //口座番号
        webservice String BankBranchName;           //振込銀行支店名
        webservice String BankAccountClassification;            //振込銀行口座種別
        webservice String BankAccountName;          //口座名
    }
    global class BI_TL_CouponInfo {
        webservice Integer CouponAmount;            //クーポン券面額
        webservice String CouponType;           //クーポン種類
        webservice String CouponNumber;         //クーポン番号
        webservice Date CouponIssueDate;            //クーポン発行日
    }
	// １部屋利用情報(1:1)
	global class BI_TL_RoomAndGuestInfo {
		webservice BI_TL_RoomsInfo room;
		//webservice List<Date> roomDateLst;
		webservice List<BI_TL_RoomRateInfomation> roomRateLst;
		webservice List<BI_TL_GuestInfo> guestLst;
	}
	// 1部屋の部屋料金情報(1:N){連泊}
	global class BI_TL_RoomRateInfomation {
		webservice Date RoomDate;
		webservice Integer PerPaxRate;
		webservice Integer PerChildA70Rate;
		webservice Integer PerChildB50Rate;
		webservice Integer PerChildC30Rate;
		webservice Integer PerChildDRate;
		webservice Integer TotalPerRoomRate;
		webservice Integer TotalRoomHotSpringTax;
		webservice Integer TotalPerRoomServiceFee;
		webservice Integer PerChildOtherRate;       //子供その他一人料金 
        webservice Integer PerChildOtherRate2;      //子供その他2一人料金    
        webservice Integer TotalPerRoomConsumptionTax;      //1室あたり宿泊料金消費税合計    
        webservice Integer TotalPerRoomHotelTax;        //1室あたり宿泊料金ホテル税他合計  
        webservice Integer TotalPerRoomBreakfastFee;        //1室あたり朝食料金合計   
        webservice Integer TotalPerRoomOtherFee;        //1室あたりその他料金合計  
        webservice Integer TotalPerRoomCommissionAmount;        //1室あたり手数料総額    
        webservice Integer TotalPerRoomCommissionConsumptionTax;        //1室あたり手数料消費税額  
        webservice Integer PerMaleRate;             //大人(男)一人料金
        webservice Integer PerFemaleRate;               //大人(女)一人料金
        webservice Integer RoomRatePaxMaleCount;            //大人人員（男性）
        webservice Integer RoomRatePaxFemaleCount;              //大人人員（女性）
        webservice Integer RoomRateChildA70Count;               //子供A人数
        webservice Integer RoomRateChildB50Count;               //子供B人数
        webservice Integer RoomRateChildC30Count;               //子供C人数
        webservice Integer RoomRateChildDNoneCount;             //子供D人数
        webservice String RoomRatePaxMaleRequest;               //大人（男性）リクエスト
        webservice String RoomRatePaxFemaleRequest  ;           //大人（女性）リクエスト
        webservice String RoomRateChildA70Request;              //子供Aリクエスト
        webservice String RoomRateChildB50Request;              //子供Bリクエスト
        webservice String RoomRateChildC30Request;              //子供Cリクエスト
        webservice String RoomRateChildDNoneRequest;            //子供Dリクエスト
	}
	// 部屋情報
	global class BI_TL_RoomsInfo{
		webservice String RoomTypeCode;
		webservice String RoomTypeName;
		webservice String RoomCategory;
		webservice String ViewType;
		webservice String SmokingOrNonSmoking;
		webservice Integer PerRoomPaxCount;
		webservice Integer RoomPaxMaleCount;
		webservice Integer RoomPaxFemaleCount;
		webservice Integer RoomChildA70Count;
		webservice Integer RoomChildB50Count;
		webservice Integer RoomChildC30Count;
		webservice Integer RoomChildDNoneCount;
		webservice String Facilities;             // その他設備：複数存在場合、[,]連結して、設定を行う
		webservice String AssignedRoomNumber;
		webservice String RoomSpecialRequest;     // 客室に対する特別リクエスト：複数存在場合、[,]連結して、設定を行う
		webservice Integer RoomChildOtherCount;     //子供その他人数
        webservice Integer RoomChildOtherCount2;             //子供その他人数2
        webservice String RoomByRoomStatus;     //部屋毎予約ステイタス
        webservice String RoomByRoomConfirmationNumber;     //部屋毎予約番号   
        webservice String RoomPaxMaleRequest;             //大人人員(男性)備考
        webservice String RoomPaxFemaleRequest;             //大人人員(女性)備考
        webservice String RoomChildA70Request;             //子供A備考
        webservice String RoomChildB50Request;             //子供B備考
        webservice String RoomChildC30Request;             //子供C備考
        webservice String RoomChildDNoneRequest;             //子供D備考
        webservice String RoomChildOtherRequest;             //子供その他備考
        webservice String RoomChildOtherRequest2;             //子供その他備考2
        webservice String RoomTypeAgent;             //在庫引落先旅行会社ID
        webservice String RoomFrame;             //枠
        webservice String NetRmTypeGroupCode;             //ネット室タイプグループコード
        webservice String PlanGroupCode;             //プラングループコード
        webservice String RepresentativePersonName;             //代表者名
	}
	// 顧客情報
	global class BI_TL_GuestInfo {
		webservice String GuestNameSingleByte;
		webservice String GuestSurName;
		webservice String GuestKanjiName;
		webservice String GuestGender;                // お客様男女区分
		webservice String GuestPhoneNumber;
		webservice Integer GuestAge;
		webservice Date GuestDateOfBirth;
		webservice String GuestEmergencyPhoneNumber;  // お客様緊急連絡先
		webservice String GuestEmail;                 // お客様Email
		webservice String GuestStateProvidence;       // お客様住所都道府県
		webservice String GuestGivenName;   //お客様氏名全角ふりがな(名)
        webservice String GuestMiddleName;  //お客様氏名半角英字(ミドルネーム)
        webservice String GuestNamePrefix;  //お客様肩書き
        webservice String GuestType;           //お客様人員区分
        webservice String GuestShubetsu;           //お客様種別
        webservice String GuestCountry;        //お客様国籍
        webservice String GuestCityName;           //お客様住所区市名
        webservice String GuestAddressLine;        //お客様住所町村名
        webservice String GuestStreetNumber;           //お客様住所番地名
        webservice String GuestPostalCode;         //お客様住所郵便番号
        webservice String GuestBuildingName;           //お客様住所ビル・部屋名
        webservice String GuestFFPCarrier;         //お客様FFPキャリア
        webservice String GuestFFPNumber;          //お客様FFPNo.
        webservice String GuestCoachNumber;        //お客様バス号車番号
        webservice String SpecialInformation;          //お客様特記情報
	}
	// リザプリ情報[07]
	global class BI_TL_Risaplsinformation {
		// 07-01
		webservice BI_TL_RisaplsCommonInformation risaplsCommonInformation;		// リザプリ共通情報
    	webservice BI_TL_AgentNativeInformation agentNativeInformation;     // リザプリ共通情報
	}
	// リザプリ共通情報[07-01]
	global class BI_TL_RisaplsCommonInformation {
		webservice BI_TL_RisaplBasic risaplBasic;											// 予約基本情報
		webservice BI_TL_Member member;		// [07-01-05]
		webservice BI_TL_Allotment allotment;       //予約情報      
        webservice List<BI_TL_Option> option;       //オプション情報
        webservice List<BI_TL_RoomAndRoomRateInformation> roomAndRoomRateInformationLst;        //個々の部屋と部屋料金情報  
        webservice List<BI_TL_BlockReport> blockReportLst;      //提供室数、残室   
        webservice BI_TL_OtherInfo otherInfo;       //その他情報 
		webservice BI_TL_BasicRate basicRate;       //基本料金情報 
	}
	
	// 予約基本情報[07-01-01]
	global class BI_TL_RisaplBasic {
		webservice String	SalesOfficeCompanyCode;		// 旅行会社コード
		webservice String TelegramDiv;          //電文種別
        webservice String RisaplsDataID;            //リザプリデータID·
        webservice String RisaplsTelegramNumber;            //リザプリ電文ID
		webservice String	TelegramData;					// リザプリ電文
		webservice String	PhoneNumber;		// 	団体または代表者番号 String
		webservice String	Email;		// 	団体または代表者Email String
		webservice String	PostalCode;		// 	団体または代表者郵便番号 String
		webservice String	Address;		// 	団体または代表者住所 String
		webservice String	TotalPaxManCount;		// 	大人人数 Integer
		webservice String	BranchFaxNumber;		// 	旅行会社営業所FAX番号 String
		webservice String	Version;		// 	TravelXML(シーナッツXML)バージョン String
		webservice String	RepresentativeMiddleName;		// 	代表者ミドルネーム String
		webservice String	RepresentativePhoneType;		// 	代表者連絡先種別 String
		webservice String	RepresentativeAge;		// 	代表者年齢 String
		webservice String	RepresentativeCellularPhone;		// 	代表者携帯電話 String
		webservice String	RepresentativeOfficialPhone;		// 	代表者勤務先電話番号 String
		webservice String	RepresentativeGeneration;		// 	代表者年代 String
		webservice String	RepresentativeGendar;		// 	代表者男女区分 Integer
		webservice String RepresentativeCorp;             //代表者会社
        webservice String RepresentativeDep;              //代表者所属部署
        webservice String RepresentativeOccupation;           //代表者ご職業
        webservice String RepresentativePost;             //代表者役職
        webservice String RepresentativeOfficeAddr;           //代表者勤務先住所
        webservice String RepresentativeOfficeFAX;            //代表者勤務先FAX番号
        webservice String RepresentativeID;           //代表者会員番号
        webservice String RepresentativeType;             //代表者会員種別
        webservice String RepresentativeDateOfBirth;              //代表者生年月日
        webservice String RepresentativeMailMagazineFromAccommodation;            //宿泊施設からのメ ルマ ガ受 信希 望( 宿泊者)
		webservice String	AccommodationId;		// 	施設ID String
	}
	
	// 予約情報 [07-01-02]
	global class BI_TL_Allotment {
		webservice Integer AssignDiv;            //部屋割区分
        webservice Integer GenderDiv;            //男女区分
        webservice Integer HandleDiv;            //取扱区分
        webservice Integer RsvUserDiv;           //予約者情報区分
        webservice Integer UseDiv;           //利用区分
	}
	
	//オプション情報[07-01-03]
	global class BI_TL_Option {
		webservice Date OptionDate;             //オプション利用年月日
        webservice String Name;             //オプション名称
        webservice String NameRequest;          //オプション名備考
        webservice Integer OptionCount;             //オプション個数
        webservice Integer OptionRate;          //オプション料金単価
        webservice String OptionCode;           //オプションコード
	}
 	global class BI_TL_RoomAndRoomRateInformation {
        webservice BI_TL_RoomsInfo room;
        webservice List<BI_TL_RoomRateInfomation> roomRateLst;
        webservice List<BI_TL_GuestInfo> guestLst;
    }   
    
    global class BI_TL_GuestInformation {
        webservice String GuestNameSingleByte;          //お客様氏名半角カタカナ英字(姓名)
        webservice String GuestSurName;             //お客様氏名全角ふりがな(姓)
        webservice String GuestGivenName;           //お客様氏名全角ふりがな(名)
        webservice String GuestMiddleName;          //お客様氏名半角英字(ミドルネーム)
        webservice String GuestNamePrefix;          //お客様肩書き
        webservice String GuestKanjiName;           //お客様氏名全角漢字(姓名)
        webservice String GuestGender;          //お客様男女区分
        webservice Integer GuestAge;            //お客様年齢
        webservice Date GuestDateOfBirth;           //お客様生年月日
        webservice String GuestType;            //お客様人員区分
        webservice String GuestShubetsu;            //お客様種別
        webservice String GuestPhoneNumber;             //お客様電話番号
        webservice String GuestEmergencyPhoneNumber;            //お客様緊急連絡先
        webservice String GuestEmail;           //お客様Email
        webservice String GuestCountry;             //お客様国籍
        webservice String GuestStateProvidence;             //お客様住所都道府県
        webservice String GuestCityName;            //お客様住所区市名
        webservice String GuestAddressLine;             //お客様住所町村名
        webservice String GuestStreetNumber;            //お客様住所番地名
        webservice String GuestPostalCode;          //お客様住所郵便番号
        webservice String GuestBuildingName;            //お客様住所ビル・部屋名
        webservice String GuestFFPCarrier;          //お客様FFPキャリア
        webservice String GuestFFPNumber;           //お客様FFPNo.
        webservice String GuestCoachNumber;             //お客様バス号車番号
        webservice String SpecialInformation;           //お客様特記情報
    }
    
    global class BI_TL_BlockReport {
        webservice String RoomTypeCode;             //部屋タイプコード
        webservice String InquiryDate;              //照会日
        webservice Integer TotalRoomsBlock;             //提供室数
        webservice Integer TotalRoomsNotYetSold;                //残室数
    }
    
    global class BI_TL_OtherInfo {
        webservice String Reference;              //通信欄
        webservice String GuestRequest;           //お客様からの要望
        webservice String AdditionalInformation;              //予約補足情報
        webservice List<BI_TL_QuestionAndAnswerInfo> questionAndAnswerLst;            //宿泊者への質問と回答リスト
    }
    
    global class BI_TL_QuestionAndAnswerInfo {
        webservice String QuestionToGuest;         //宿泊者への質問
        webservice String AnswerToHotel;           //宿泊者からの回答       
    }
	global class BI_TL_BasicRate {
		webservice Integer TotalAccomodationServiceCharge;               //合計宿泊料金に対するサービス料
        webservice List<BI_TL_PointsDiscountInfo> pointsDiscountLst;                 //ポイント割引・補助金情報
		webservice List<BI_TL_DepositInfo> depositLst;               //デポジット情報
    }
    
    global class BI_TL_PointsDiscountInfo {
        webservice Integer PointsDiv;                //ポイント割引・補助金区分
        webservice String PointsDiscountName;                //ポイント割引・補助金名称
        webservice Integer PointsDiscount;               //ポイント割引・補助金額
    }
    
	global class BI_TL_DepositInfo {        
        webservice Integer DepositAmount;         //デポジット額
    }
    
    global class BI_TL_AgentNativeInformation{
        webservice BI_TL_Extend extend;         //独自情報1
        webservice BI_TL_Extendmytrip extendmytrip;         //独自情報2
    }
    
    global class BI_TL_Extend{
        webservice String PointDiv;            //ポイント区分
        webservice String PointName;               //ポイント名称・補助金名称
        webservice Integer Points;             //ポイント割引金額・補助金額
        webservice Integer TotalAccommodationDecleasePoints;               //割引後の総額
        webservice Integer TotalAccommodationConsumptionTax;               //割引後の総額に対する、消費税額
        webservice Integer AmountClaimed;              //宿泊者請求額
        webservice String Pamphlet;            //パンフレット利用フラグ
        webservice String FromHotelQuestion;               //宿泊施設への質問事項
        webservice String ToHotelAnswer;               //宿泊施設からの回答
        webservice String AgentComment;            //じゃらんnetから宿泊施設へのコメント
    }
    
    global class BI_TL_Extendmytrip{
        webservice String VIPCode;                //VIPコード
        webservice String GetPoint;               //付与ポイント
        webservice String UsePoint;               //充当ポイント
        webservice String ChargeEquation;                 //宿泊料金計算式
        webservice String ReceiveDateTime;                //受付日
        webservice String CancelDateTime;                 //キャンセル受付日
        webservice String Answer1;                //質問への回答1
        webservice String Answer2;                //質問への回答2
        webservice String Answer3;                //質問への回答3
        webservice String Answer4;                //質問への回答4
        webservice String Answer5;                //質問への回答5
        webservice String AgoRsvNumber;               //変更前予約番号
        webservice String FromRsvNumber;                  //変更後予約番号
        webservice String TodayReserve;               //当日予約
        webservice String RoomSelect;                 //室タイプ選択
        webservice String Reference;                  //通信欄
        webservice Integer TotalMaleCount;                //合計男性人数
        webservice Integer TotalFemaleCount;                  //合計女性人数
        webservice Integer SettlementDiv;                 //事前決済区分
        webservice String CancellationCharge;                 //事前決済に対するキャンセル料金
        webservice String CancellationNotice;                 //取消料補足説明事項
    }
	// 予約者・会員情報[07-01-05]
	global class BI_TL_Member {
		webservice String UserName;	// 	予約者・会員名漢字 
		webservice String UserKana;	// 	予約者・会員名カタカナ 
		webservice String UserTel;	// 	予約者・会員電話番号 
		webservice String UserMailAddr;	// 	予約者・会員Email 
		webservice String UserZip;	// 	予約者・会員郵便番号 
		webservice String UserAddr;	// 	予約者・会員住所 
		webservice String UserCorp;	// 	予約者・会員会社 
		webservice String UserDep;	// 	予約者・会員所属部署 
		webservice String UserID;	// 	予約者・会員番号 
		webservice String UserGivingPoints;	// 	付与ポイント 
		webservice String UserUsePoints;	// 	使用ポイント 
		webservice String UserType;	// 	会員種別 
		webservice String UserDateOfBirth;	// 	予約者生年月日 
		webservice String UserGendar;	// 	予約者性別 
		webservice String UserEmergencyPhoneNumber;	// 	予約者緊急連絡先番号(携帯等) 
		webservice String UserOfficePhone;	// 	予約者勤務先電話番号 
		webservice String UserCorpID;	// 	予約者・会員会社コード 
		webservice String UserCorpKana;	// 	予約者・会員会社名カナ 
		webservice String MemberOfficePostalCode;	// 	予約者・会員勤務先郵便番号 
		
		webservice String UserOccupation;                   //予約者ご職業
        webservice String UserMailMagazineFromAccommodation;                //宿泊施設からのメルマガ受信希望(予約
        webservice String UserMiddleName;                   //予約者ミドルネーム
        webservice String UserPost;                 //予約者役職
        webservice String UserOfficeAddr;                   //予約者勤務先住所
        webservice String UserOfficeFAX ;               //予約者勤務先FAX番号
        webservice String UserTotalPoint;                   //累計ポイント
	}

	global class BI_TL_SyncResult {
		// 処理結果
		webservice BI_TL_Result result;
		webservice Id sfdcId;
		webservice String message;
		webservice Id sfdcJobId;
	}
	// 戻る結果：処理成功、処理失敗、処理中。
	global enum BI_TL_Result{OK, NG, WAIT}
	// INS:新規 / UPD:更新 / 削除：キャンセル
	global enum BI_TL_DmlAction{INS, UPD, CANCEL, CONFIRM, TEJIMA, ISSUE, OTHER }
	// 2017/06/30 XML特殊記号文字UTF-8対応 BEGIN
    static void unescapeXmlProcess(BI_TL_SyncInfo bookingInfo) {
    	// 宿泊施設側情報
    	bookingInfo.AccommodationArea = unescapeXml(bookingInfo.AccommodationArea);
		bookingInfo.AccommodationName = unescapeXml(bookingInfo.AccommodationName);
		bookingInfo.AccommodationCode = unescapeXml(bookingInfo.AccommodationCode);	
		bookingInfo.ChainName = unescapeXml(bookingInfo.ChainName);  
		bookingInfo.AccommodationPersonInCharge = unescapeXml(bookingInfo.AccommodationPersonInCharge);   
		bookingInfo.AccommodationEmail = unescapeXml(bookingInfo.AccommodationEmail);  	
		bookingInfo.AccommodationPhoneNumber = unescapeXml(bookingInfo.AccommodationPhoneNumber);  
		bookingInfo.AccommodationCPUAddress = unescapeXml(bookingInfo.AccommodationCPUAddress);  
    	// 振込銀行情報 BankList
    	List<BI_TL_BankInfo> bankLst = bookingInfo.bankLst;
        if(bankLst != null){
        	for(BI_TL_BankInfo bank : bankLst){
	            bank.BankName = unescapeXml(bank.BankName);  				
				bank.BankAccountNumber = unescapeXml(bank.BankAccountNumber);				
				bank.BankBranchName	= unescapeXml(bank.BankBranchName);				
				bank.BankAccountClassification = unescapeXml(bank.BankAccountClassification);				
				bank.BankAccountName = unescapeXml(bank.BankAccountName);				
        	}
        }
    	//  旅行会社情報
    	bookingInfo.SalesOfficeCompanyCode = unescapeXml(bookingInfo.SalesOfficeCompanyCode); 
		bookingInfo.SalesOfficeCompanyName = unescapeXml(bookingInfo.SalesOfficeCompanyName);         
		bookingInfo.SalesOfficeName = unescapeXml(bookingInfo.SalesOfficeName); 
		bookingInfo.SalesOfficeCode = unescapeXml(bookingInfo.SalesOfficeCode); 
		bookingInfo.SalesOfficePersonInCharge = unescapeXml(bookingInfo.SalesOfficePersonInCharge);  
		bookingInfo.SalesOfficeEmail = unescapeXml(bookingInfo.SalesOfficeEmail);           
		bookingInfo.SalesOfficePhoneNumber = unescapeXml(bookingInfo.SalesOfficePhoneNumber);     
		bookingInfo.SalesOfficeStateProvidence = unescapeXml(bookingInfo.SalesOfficeStateProvidence);     
		bookingInfo.SalesOfficeCityName = unescapeXml(bookingInfo.SalesOfficeCityName); 
		bookingInfo.SalesOfficeAddressLine = unescapeXml(bookingInfo.SalesOfficeAddressLine);         
		bookingInfo.SalesOfficeStreetNumber = unescapeXml(bookingInfo.SalesOfficeStreetNumber);        
		bookingInfo.SalesOfficePostalCode = unescapeXml(bookingInfo.SalesOfficePostalCode);          
		bookingInfo.SalesOfficeRegisteredCategory = unescapeXml(bookingInfo.SalesOfficeRegisteredCategory);  
		bookingInfo.SalesOfficeLicenseNumber = unescapeXml(bookingInfo.SalesOfficeLicenseNumber);       
		bookingInfo.SalesOfficeRegisteredPrefecture = unescapeXml(bookingInfo.SalesOfficeRegisteredPrefecture);
		bookingInfo.SalesOfficeCPUAddress = unescapeXml(bookingInfo.SalesOfficeCPUAddress);          
		bookingInfo.RetailerCompanyName = unescapeXml(bookingInfo.RetailerCompanyName); 
		bookingInfo.RetailerOfficeName = unescapeXml(bookingInfo.RetailerOfficeName);       
		bookingInfo.RetailerOfficeCode = unescapeXml(bookingInfo.RetailerOfficeCode);       
		bookingInfo.RetailerPersonInCharge = unescapeXml(bookingInfo.RetailerPersonInCharge);   
		bookingInfo.RetailerEmail = unescapeXml(bookingInfo.RetailerEmail); 
		bookingInfo.RetailerPhoneNumber = unescapeXml(bookingInfo.RetailerPhoneNumber);      
		bookingInfo.RetailerStateProvidence = unescapeXml(bookingInfo.RetailerStateProvidence);  
		bookingInfo.RetailerCityName = unescapeXml(bookingInfo.RetailerCityName);         
		bookingInfo.RetailerAddressLine = unescapeXml(bookingInfo.RetailerAddressLine);      
		bookingInfo.RetailerStreetNumber = unescapeXml(bookingInfo.RetailerStreetNumber);     
		bookingInfo.RetailerPostalCode = unescapeXml(bookingInfo.RetailerPostalCode);       
		bookingInfo.RetailerRegisteredCategory = unescapeXml(bookingInfo.RetailerRegisteredCategory);     
		bookingInfo.RetailerLicenseNumber = unescapeXml(bookingInfo.RetailerLicenseNumber); 
		bookingInfo.RetailerRegisteredPrefecture = unescapeXml(bookingInfo.RetailerRegisteredPrefecture);     
    	// 基本宿泊情報
    	bookingInfo.TravelAgencyBookingNumber = unescapeXml(bookingInfo.TravelAgencyBookingNumber);      			
		bookingInfo.TravelAgencyReportNumber = unescapeXml(bookingInfo.TravelAgencyReportNumber);       			
		bookingInfo.AccommodationConfirmationNumber	= unescapeXml(bookingInfo.AccommodationConfirmationNumber);			
		bookingInfo.GuestOrGroupNameSingleByte = unescapeXml(bookingInfo.GuestOrGroupNameSingleByte);     			
		bookingInfo.GuestOrGroupNameDoubleByte = unescapeXml(bookingInfo.GuestOrGroupNameDoubleByte);     			
		bookingInfo.GuestOrGroupNameKanjiName = unescapeXml(bookingInfo.GuestOrGroupNameKanjiName);      			
		bookingInfo.GroupNameWelcomeBoard = unescapeXml(bookingInfo.GroupNameWelcomeBoard);          			
		bookingInfo.Transportaion = unescapeXml(bookingInfo.Transportaion);    			
		bookingInfo.CoachCompany = unescapeXml(bookingInfo.CoachCompany);     			
		bookingInfo.Status = unescapeXml(bookingInfo.Status);           			
		bookingInfo.TypeOfGroup = unescapeXml(bookingInfo.TypeOfGroup);      			
		bookingInfo.PackageType = unescapeXml(bookingInfo.PackageType);      			
		bookingInfo.PackagePlanName = unescapeXml(bookingInfo.PackagePlanName);  			
		bookingInfo.PackagePlanCode = unescapeXml(bookingInfo.PackagePlanCode);  			
		bookingInfo.PackagePlanContent = unescapeXml(bookingInfo.PackagePlanContent);    			
		bookingInfo.MealCondition = unescapeXml(bookingInfo.MealCondition);         			
		bookingInfo.SpecificMealCondition = unescapeXml(bookingInfo.SpecificMealCondition); 			
		bookingInfo.MealPlace = unescapeXml(bookingInfo.MealPlace);            			
		bookingInfo.BanquetRoom = unescapeXml(bookingInfo.BanquetRoom);           			
		bookingInfo.ModificationType = unescapeXml(bookingInfo.ModificationType);      			
		bookingInfo.ModificationPoint = unescapeXml(bookingInfo.ModificationPoint);     			
		bookingInfo.CancellationNumber = unescapeXml(bookingInfo.CancellationNumber);    			
		bookingInfo.PreviousPlace = unescapeXml(bookingInfo.PreviousPlace);         			
		bookingInfo.PreviousAccommodationName = unescapeXml(bookingInfo.PreviousAccommodationName);      			
		bookingInfo.SpecialServiceRequest = unescapeXml(bookingInfo.SpecialServiceRequest);			
		bookingInfo.OtherServiceInformation = unescapeXml(bookingInfo.OtherServiceInformation);			
		bookingInfo.FollowUpInformation = unescapeXml(bookingInfo.FollowUpInformation);			
    	
    	// 基本情報 BasicRateInformation
    	bookingInfo.RoomRateOrPersonalRate= unescapeXml(bookingInfo.RoomRateOrPersonalRate); 				
		bookingInfo.TaxServiceFee = unescapeXml(bookingInfo.TaxServiceFee);      				
		bookingInfo.Payment = unescapeXml(bookingInfo.Payment);            				
		bookingInfo.CreditCardAuthority = unescapeXml(bookingInfo.CreditCardAuthority);				
		bookingInfo.CreditCardNumber = unescapeXml(bookingInfo.CreditCardNumber);   				
		bookingInfo.CardHolderName = unescapeXml(bookingInfo.CardHolderName);         				
    	// クーポン明細 0:N
    	List<BI_TL_CouponInfo> couponLst = bookingInfo.CouponLst;
    	if(couponLst != null){
    		for(BI_TL_CouponInfo coupon : couponLst){
				coupon.CouponType = unescapeXml(coupon.CouponType);     			
				coupon.CouponNumber = unescapeXml(coupon.CouponNumber);   			
    		}
    	}
    	// 個々の部屋とお客様情報<1:N>
		for(BI_TL_RoomAndGuestInfo roomGuestInfo : bookingInfo.roomAndGuestLst){
			// 部屋情報
			BI_TL_RoomsInfo roomInfo = roomGuestInfo.room;
			if(roomInfo != null){
				roomInfo.RoomTypeCode = unescapeXml(roomInfo.RoomTypeCode);        		
				roomInfo.RoomTypeName = unescapeXml(roomInfo.RoomTypeName);        		
				roomInfo.RoomCategory = unescapeXml(roomInfo.RoomCategory);        		
				roomInfo.ViewType = unescapeXml(roomInfo.ViewType);            		
				roomInfo.SmokingOrNonSmoking = unescapeXml(roomInfo.SmokingOrNonSmoking);        		
				roomInfo.RoomByRoomStatus = unescapeXml(roomInfo.RoomByRoomStatus);           		
				roomInfo.RoomByRoomConfirmationNumber = unescapeXml(roomInfo.RoomByRoomConfirmationNumber);		
				roomInfo.Facilities = unescapeXml(roomInfo.Facilities);             		
				roomInfo.AssignedRoomNumber = unescapeXml(roomInfo.AssignedRoomNumber);     		
				roomInfo.RoomSpecialRequest = unescapeXml(roomInfo.RoomSpecialRequest);     		
				roomInfo.RoomTypeAgent = unescapeXml(roomInfo.RoomTypeAgent); 
				roomInfo.RoomPaxMaleRequest = unescapeXml(roomInfo.RoomPaxMaleRequest);
				roomInfo.RoomPaxFemaleRequest = unescapeXml(roomInfo.RoomPaxFemaleRequest);
				roomInfo.RoomChildA70Request = unescapeXml(roomInfo.RoomChildA70Request);
				roomInfo.RoomChildB50Request = unescapeXml(roomInfo.RoomChildB50Request);
				roomInfo.RoomChildC30Request = unescapeXml(roomInfo.RoomChildC30Request);
				roomInfo.RoomChildDNoneRequest = unescapeXml(roomInfo.RoomChildDNoneRequest);
				roomInfo.RoomChildOtherRequest = unescapeXml(roomInfo.RoomChildOtherRequest);
				roomInfo.RoomChildOtherRequest2	= unescapeXml(roomInfo.RoomChildOtherRequest2);
				roomInfo.RoomFrame = unescapeXml(roomInfo.RoomFrame);
				roomInfo.NetRmTypeGroupCode = unescapeXml(roomInfo.NetRmTypeGroupCode);
				roomInfo.PlanGroupCode = unescapeXml(roomInfo.PlanGroupCode);
				roomInfo.RepresentativePersonName = unescapeXml(roomInfo.RepresentativePersonName);
			}
			// 1部屋の部屋料金情報(1:N){連泊}
			List<BI_TL_RoomRateInfomation> roomRateLst = roomGuestInfo.roomRateLst;
			if(roomRateLst != null){
				for(BI_TL_RoomRateInfomation roonRate : roomRateLst){
					roonRate.RoomRatePaxMaleRequest = unescapeXml(roonRate.RoomRatePaxMaleRequest);
					roonRate.RoomRatePaxFemaleRequest = unescapeXml(roonRate.RoomRatePaxFemaleRequest);
					roonRate.RoomRateChildA70Request = unescapeXml(roonRate.RoomRateChildA70Request);
					roonRate.RoomRateChildB50Request = unescapeXml(roonRate.RoomRateChildB50Request);
					roonRate.RoomRateChildC30Request = unescapeXml(roonRate.RoomRateChildC30Request);
					roonRate.RoomRateChildDNoneRequest= unescapeXml(roonRate.RoomRateChildDNoneRequest);
	    		}
			}
    		// 顧客情報
    		List<BI_TL_GuestInfo> guestLst = roomGuestInfo.guestLst;
    		if(guestLst != null){
    			for (BI_TL_GuestInfo guest : guestLst) {
	    			guest.GuestNameSingleByte = unescapeXml(guest.GuestNameSingleByte);  		
					guest.GuestSurName = unescapeXml(guest.GuestSurName);         		
					guest.GuestGivenName = unescapeXml(guest.GuestGivenName);       		
					guest.GuestMiddleName = unescapeXml(guest.GuestMiddleName);      		
					guest.GuestNamePrefix = unescapeXml(guest.GuestNamePrefix);      		
					guest.GuestKanjiName = unescapeXml(guest.GuestKanjiName);       		
					guest.GuestGender = unescapeXml(guest.GuestGender);          		
					guest.GuestType = unescapeXml(guest.GuestType);            		
					guest.GuestShubetsu = unescapeXml(guest.GuestShubetsu);        		
					guest.GuestPhoneNumber = unescapeXml(guest.GuestPhoneNumber);    		
					guest.GuestEmergencyPhoneNumber = unescapeXml(guest.GuestEmergencyPhoneNumber);		
					guest.GuestEmail = unescapeXml(guest.GuestEmail);            		
					guest.GuestCountry = unescapeXml(guest.GuestCountry);          		
					guest.GuestStateProvidence = unescapeXml(guest.GuestStateProvidence);  		
					guest.GuestCityName = unescapeXml(guest.GuestCityName);         		
					guest.GuestAddressLine = unescapeXml(guest.GuestAddressLine);      		
					guest.GuestStreetNumber = unescapeXml(guest.GuestStreetNumber);     		
					guest.GuestPostalCode = unescapeXml(guest.GuestPostalCode);       		
					guest.GuestBuildingName = unescapeXml(guest.GuestBuildingName);     		
					guest.GuestFFPCarrier = unescapeXml(guest.GuestFFPCarrier);       		
					guest.GuestFFPNumber = unescapeXml(guest.GuestFFPNumber);        		
					guest.GuestCoachNumber = unescapeXml(guest.GuestCoachNumber);      		
					guest.SpecialInformation = unescapeXml(guest.SpecialInformation);    		
	    		}
    		}
		}
		// リザプリ情報
		BI_TL_Risaplsinformation risaplsInfo = bookingInfo.risaplsinformation;
		if(risaplsInfo != null){
			// リザプリ共通情報
			BI_TL_RisaplsCommonInformation risaplsCommonInformation = risaplsInfo.risaplsCommonInformation;
			if(risaplsCommonInformation != null){
				// 予約基本情報
				BI_TL_RisaplBasic risaplBasic = risaplsCommonInformation.risaplBasic;
				if(risaplBasic != null){
		    		risaplBasic.SalesOfficeCompanyCode = unescapeXml(risaplBasic.SalesOfficeCompanyCode);
					risaplBasic.TelegramDiv= unescapeXml(risaplBasic.TelegramDiv);
					risaplBasic.RisaplsDataID = unescapeXml(risaplBasic.RisaplsDataID);
					risaplBasic.RisaplsTelegramNumber = unescapeXml(risaplBasic.RisaplsTelegramNumber);
					risaplBasic.TelegramData = unescapeXml(risaplBasic.TelegramData);
					risaplBasic.PhoneNumber = unescapeXml(risaplBasic.PhoneNumber);
					risaplBasic.Email = unescapeXml(risaplBasic.Email);
					risaplBasic.PostalCode= unescapeXml(risaplBasic.PostalCode);
					risaplBasic.Address= unescapeXml(risaplBasic.Address);
					risaplBasic.TotalPaxManCount = unescapeXml(risaplBasic.TotalPaxManCount);
					risaplBasic.BranchFaxNumber = unescapeXml(risaplBasic.BranchFaxNumber);
					risaplBasic.Version = unescapeXml(risaplBasic.Version);
					risaplBasic.RepresentativeMiddleName = unescapeXml(risaplBasic.RepresentativeMiddleName);
					risaplBasic.RepresentativePhoneType = unescapeXml(risaplBasic.RepresentativePhoneType);
					risaplBasic.RepresentativeAge = unescapeXml(risaplBasic.RepresentativeAge);
					risaplBasic.RepresentativeCellularPhone= unescapeXml(risaplBasic.RepresentativeCellularPhone);
					risaplBasic.RepresentativeOfficialPhone= unescapeXml(risaplBasic.RepresentativeOfficialPhone);
					risaplBasic.RepresentativeGeneration = unescapeXml(risaplBasic.RepresentativeGeneration);
					risaplBasic.RepresentativeGendar = unescapeXml(risaplBasic.RepresentativeGendar);
					risaplBasic.RepresentativeCorp = unescapeXml(risaplBasic.RepresentativeCorp);
					risaplBasic.RepresentativeDep = unescapeXml(risaplBasic.RepresentativeDep);
					risaplBasic.RepresentativeOccupation  = unescapeXml(risaplBasic.RepresentativeOccupation);
					risaplBasic.RepresentativePost= unescapeXml(risaplBasic.RepresentativePost );
					risaplBasic.RepresentativeOfficeAddr  = unescapeXml(risaplBasic.RepresentativeOfficeAddr);
					risaplBasic.RepresentativeOfficeFAX= unescapeXml(risaplBasic.RepresentativeOfficeFAX);
					risaplBasic.RepresentativeID= unescapeXml(risaplBasic.RepresentativeID  );
					risaplBasic.RepresentativeType= unescapeXml(risaplBasic.RepresentativeType );
					risaplBasic.RepresentativeDateOfBirth = unescapeXml(risaplBasic.RepresentativeDateOfBirth);
					risaplBasic.RepresentativeMailMagazineFromAccommodation= unescapeXml(risaplBasic.RepresentativeMailMagazineFromAccommodation);
					risaplBasic.AccommodationId = unescapeXml(risaplBasic.AccommodationId);
		    	}
				BI_TL_Member member = risaplsCommonInformation.member;
				if(member != null){
		    		member.UserName = unescapeXml(member.UserName);        				
					member.UserKana = unescapeXml(member.UserKana);        				
					member.UserTel = unescapeXml(member.UserTel);         				
					member.UserMailAddr = unescapeXml(member.UserMailAddr);    				
					member.UserZip = unescapeXml(member.UserZip);         				
					member.UserAddr = unescapeXml(member.UserAddr);        				
					member.UserCorp = unescapeXml(member.UserCorp);        				
					member.UserDep = unescapeXml(member.UserDep);         				
					member.UserID = unescapeXml(member.UserID);          				
					member.UserGivingPoints = unescapeXml(member.UserGivingPoints);
					member.UserUsePoints = unescapeXml(member.UserUsePoints);
					member.UserType = unescapeXml(member.UserType);
					member.UserDateOfBirth= unescapeXml(member.UserDateOfBirth);
					member.UserGendar = unescapeXml(member.UserGendar);
					member.UserEmergencyPhoneNumber = unescapeXml(member.UserEmergencyPhoneNumber);
					member.UserOfficePhone = unescapeXml(member.UserOfficePhone);
					member.UserCorpID = unescapeXml(member.UserCorpID);
					member.UserCorpKana = unescapeXml(member.UserCorpKana);
					member.MemberOfficePostalCode = unescapeXml(member.MemberOfficePostalCode);
					member.UserOccupation = unescapeXml(member.UserOccupation);
					member.UserMailMagazineFromAccommodation = unescapeXml(member.UserMailMagazineFromAccommodation);
					member.UserMiddleName = unescapeXml(member.UserMiddleName);
					member.UserPost = unescapeXml(member.UserPost);
					member.UserOfficeAddr = unescapeXml(member.UserOfficeAddr);
					member.UserOfficeFAX = unescapeXml(member.UserOfficeFAX);
					member.UserTotalPoint = unescapeXml(member.UserTotalPoint);
		    	}
				//オプション情報
		    	List<BI_TL_Option> optionLst = risaplsCommonInformation.option;
		    	if(optionLst != null){
		    		for(BI_TL_Option option : optionLst){
			            option.Name = unescapeXml(option.Name);       
						option.NameRequest = unescapeXml(option.NameRequest);
						option.OptionCode = unescapeXml(option.OptionCode);				
		        	}
		    	}
		    	//個々の部屋と部屋料金情報
		    	List<BI_TL_RoomAndRoomRateInformation> roomAndRoomRateInformationLst = risaplsCommonInformation.roomAndRoomRateInformationLst;
		    	if(roomAndRoomRateInformationLst != null){
		    		for(BI_TL_RoomAndRoomRateInformation roomAndRoomRateInfo : roomAndRoomRateInformationLst){
			        	BI_TL_RoomsInfo roomInfo = roomAndRoomRateInfo.room;
						if(roomInfo != null){
							roomInfo.RoomTypeCode = unescapeXml(roomInfo.RoomTypeCode);        		
							roomInfo.RoomTypeName = unescapeXml(roomInfo.RoomTypeName);        		
							roomInfo.RoomCategory = unescapeXml(roomInfo.RoomCategory);        		
							roomInfo.ViewType = unescapeXml(roomInfo.ViewType);            		
							roomInfo.SmokingOrNonSmoking = unescapeXml(roomInfo.SmokingOrNonSmoking);        		
							roomInfo.RoomByRoomStatus = unescapeXml(roomInfo.RoomByRoomStatus);           		
							roomInfo.RoomByRoomConfirmationNumber = unescapeXml(roomInfo.RoomByRoomConfirmationNumber);		
							roomInfo.Facilities = unescapeXml(roomInfo.Facilities);             		
							roomInfo.AssignedRoomNumber = unescapeXml(roomInfo.AssignedRoomNumber);     		
							roomInfo.RoomSpecialRequest = unescapeXml(roomInfo.RoomSpecialRequest);     		
							roomInfo.RoomTypeAgent = unescapeXml(roomInfo.RoomTypeAgent); 
							roomInfo.RoomPaxMaleRequest = unescapeXml(roomInfo.RoomPaxMaleRequest);
							roomInfo.RoomPaxFemaleRequest = unescapeXml(roomInfo.RoomPaxFemaleRequest);
							roomInfo.RoomChildA70Request = unescapeXml(roomInfo.RoomChildA70Request);
							roomInfo.RoomChildB50Request = unescapeXml(roomInfo.RoomChildB50Request);
							roomInfo.RoomChildC30Request = unescapeXml(roomInfo.RoomChildC30Request);
							roomInfo.RoomChildDNoneRequest = unescapeXml(roomInfo.RoomChildDNoneRequest);
							roomInfo.RoomChildOtherRequest = unescapeXml(roomInfo.RoomChildOtherRequest);
							roomInfo.RoomChildOtherRequest2	= unescapeXml(roomInfo.RoomChildOtherRequest2);
							roomInfo.RoomFrame = unescapeXml(roomInfo.RoomFrame);
							roomInfo.NetRmTypeGroupCode = unescapeXml(roomInfo.NetRmTypeGroupCode);
							roomInfo.PlanGroupCode = unescapeXml(roomInfo.PlanGroupCode);
							roomInfo.RepresentativePersonName = unescapeXml(roomInfo.RepresentativePersonName); 
						}
						// 1部屋の部屋料金情報(1:N){連泊}
						List<BI_TL_RoomRateInfomation> roomRateLst = roomAndRoomRateInfo.roomRateLst;
						if(roomRateLst != null){
							for(BI_TL_RoomRateInfomation roonRate : roomRateLst){
								roonRate.RoomRatePaxMaleRequest = unescapeXml(roonRate.RoomRatePaxMaleRequest);
								roonRate.RoomRatePaxFemaleRequest = unescapeXml(roonRate.RoomRatePaxFemaleRequest);
								roonRate.RoomRateChildA70Request = unescapeXml(roonRate.RoomRateChildA70Request);
								roonRate.RoomRateChildB50Request = unescapeXml(roonRate.RoomRateChildB50Request);
								roonRate.RoomRateChildC30Request = unescapeXml(roonRate.RoomRateChildC30Request);
								roonRate.RoomRateChildDNoneRequest= unescapeXml(roonRate.RoomRateChildDNoneRequest);
				    		}
						}
			    		// 顧客情報
			    		List<BI_TL_GuestInfo> guestLst = roomAndRoomRateInfo.guestLst;
			    		if(guestLst != null){
			    			for (BI_TL_GuestInfo guest : guestLst) {
				    			guest.GuestNameSingleByte = unescapeXml(guest.GuestNameSingleByte);  		
								guest.GuestSurName = unescapeXml(guest.GuestSurName);         		
								guest.GuestGivenName = unescapeXml(guest.GuestGivenName);       		
								guest.GuestMiddleName = unescapeXml(guest.GuestMiddleName);      		
								guest.GuestNamePrefix = unescapeXml(guest.GuestNamePrefix);      		
								guest.GuestKanjiName = unescapeXml(guest.GuestKanjiName);       		
								guest.GuestGender = unescapeXml(guest.GuestGender);          		
								guest.GuestType = unescapeXml(guest.GuestType);            		
								guest.GuestShubetsu = unescapeXml(guest.GuestShubetsu);        		
								guest.GuestPhoneNumber = unescapeXml(guest.GuestPhoneNumber);    		
								guest.GuestEmergencyPhoneNumber = unescapeXml(guest.GuestEmergencyPhoneNumber);		
								guest.GuestEmail = unescapeXml(guest.GuestEmail);            		
								guest.GuestCountry = unescapeXml(guest.GuestCountry);          		
								guest.GuestStateProvidence = unescapeXml(guest.GuestStateProvidence);  		
								guest.GuestCityName = unescapeXml(guest.GuestCityName);         		
								guest.GuestAddressLine = unescapeXml(guest.GuestAddressLine);      		
								guest.GuestStreetNumber = unescapeXml(guest.GuestStreetNumber);     		
								guest.GuestPostalCode = unescapeXml(guest.GuestPostalCode);       		
								guest.GuestBuildingName = unescapeXml(guest.GuestBuildingName);     		
								guest.GuestFFPCarrier = unescapeXml(guest.GuestFFPCarrier);       		
								guest.GuestFFPNumber = unescapeXml(guest.GuestFFPNumber);        		
								guest.GuestCoachNumber = unescapeXml(guest.GuestCoachNumber);      		
								guest.SpecialInformation = unescapeXml(guest.SpecialInformation);    		
				    		}
			    		}   			
		        	}
		    	}
		    	//提供室数、残室 
		    	List<BI_TL_BlockReport> blockReportLst = risaplsCommonInformation.blockReportLst;      
		    	if(blockReportLst != null){
		    		for(BI_TL_BlockReport blockReport : blockReportLst){
		    			blockReport.RoomTypeCode = unescapeXml(blockReport.RoomTypeCode);      		
						blockReport.InquiryDate = unescapeXml(blockReport.InquiryDate);
		    		}
		    		 
		    	}
		    	//その他情報 
		    	BI_TL_OtherInfo otherInfo = risaplsCommonInformation.otherInfo; 
		    	if(otherInfo != null){
		    		otherInfo.Reference = unescapeXml(otherInfo.Reference);      		
					otherInfo.GuestRequest = unescapeXml(otherInfo.GuestRequest);
					otherInfo.AdditionalInformation = unescapeXml(otherInfo.AdditionalInformation);
					List<BI_TL_QuestionAndAnswerInfo> questionAndAnswerLst  = otherInfo.questionAndAnswerLst; 
					if(questionAndAnswerLst != null){
						for(BI_TL_QuestionAndAnswerInfo questionAndAnswer : questionAndAnswerLst){
							questionAndAnswer.QuestionToGuest = unescapeXml(questionAndAnswer.QuestionToGuest);
							questionAndAnswer.AnswerToHotel = unescapeXml(questionAndAnswer.AnswerToHotel);
						}
					}
		    	}
		    	//基本料金情報 
		    	BI_TL_BasicRate basicRate = risaplsCommonInformation.basicRate;
		    	if(basicRate != null){
		    		List<BI_TL_PointsDiscountInfo> pointsDiscountLst = basicRate.pointsDiscountLst; 
		    		if(pointsDiscountLst != null){
		    			for(BI_TL_PointsDiscountInfo pointsDiscount : pointsDiscountLst){
		    				pointsDiscount.PointsDiscountName = unescapeXml(pointsDiscount.PointsDiscountName);
		    			}
		    		}
		    	} 
			}
			// リザプリ共通情報
			BI_TL_AgentNativeInformation agentNativeInformation = risaplsInfo.agentNativeInformation;
			if(agentNativeInformation != null){
				//独自情報1
				BI_TL_Extend extend = agentNativeInformation.extend;
				if(extend != null){
					extend.PointDiv = unescapeXml(extend.PointDiv);           				
					extend.PointName = unescapeXml(extend.PointName);               				
					extend.Pamphlet = unescapeXml(extend.Pamphlet );           				
					extend.FromHotelQuestion = unescapeXml(extend.FromHotelQuestion );  				
					extend.ToHotelAnswer = unescapeXml(extend.ToHotelAnswer);       				
					extend.AgentComment = unescapeXml(extend.AgentComment); 				
				}
				//独自情報2
				BI_TL_Extendmytrip extendmytrip = agentNativeInformation.extendmytrip; 
				if(extendmytrip != null){
					extendmytrip.VIPCode = unescapeXml(extendmytrip.VIPCode);           			
					extendmytrip.GetPoint = unescapeXml(extendmytrip.GetPoint);          			
					extendmytrip.UsePoint = unescapeXml(extendmytrip.UsePoint);          			
					extendmytrip.ChargeEquation  = unescapeXml(extendmytrip.ChargeEquation);    			
					extendmytrip.ReceiveDateTime = unescapeXml(extendmytrip.ReceiveDateTime);   			
					extendmytrip.CancelDateTime = unescapeXml(extendmytrip.CancelDateTime);    			
					extendmytrip.Answer1 = unescapeXml(extendmytrip.Answer1);           			
					extendmytrip.Answer2 = unescapeXml(extendmytrip.Answer2);           			
					extendmytrip.Answer3 = unescapeXml(extendmytrip.Answer3);           			
					extendmytrip.Answer4 = unescapeXml(extendmytrip.Answer4);           			
					extendmytrip.Answer5 = unescapeXml(extendmytrip.Answer5);           			
					extendmytrip.AgoRsvNumber = unescapeXml(extendmytrip.AgoRsvNumber);      			
					extendmytrip.FromRsvNumber = unescapeXml(extendmytrip.FromRsvNumber);     			
					extendmytrip.TodayReserve = unescapeXml(extendmytrip.TodayReserve);      			
					extendmytrip.RoomSelect = unescapeXml(extendmytrip.RoomSelect);        			
					extendmytrip.Reference = unescapeXml(extendmytrip.Reference);         			
					extendmytrip.CancellationCharge = unescapeXml(extendmytrip.CancellationCharge);			
					extendmytrip.CancellationNotice	= unescapeXml(extendmytrip.CancellationNotice);			
				}
			}
		}
    }
    static string unescapeXml(String s) {
        if (CommUtils.isBlank(s)) return s;
        return s.unescapeXml();
    }
    // 2017/06/30 XML特殊記号文字UTF-8対応 END

}