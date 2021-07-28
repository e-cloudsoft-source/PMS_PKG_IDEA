/**
* 部屋在庫数計算共通UTIL
* 2019/02/11 予約在庫の利用数集計方法と故障部屋の重複重複機能変更対応
* 2019/10/09 部屋状態管理インデックス機能対応
**/
// 2020/02/28 SITE機能対応　by zy BEGIN
public without sharing class StockChangeHelpUtils {
// 2020/02/28 SITE機能対応　by zy END
	
	// 2017/10/27 既に割り当て済み部屋情報を取得できるよう追加 BEGIN
	// BookingAPI機能利用予定、該当部屋にどの部屋は既に割当されている確認用
	// 割り当て済み部屋情報を取得する・しないフラグ
	private boolean isGetUsedRoomFlg{get; private set;}
	// map<部屋ID_日付,残室情報>
	private map<String, Decimal> roomUsedInfMap;
	public map<String, Decimal> getRoomStockUsedInfo () {
	    return roomUsedInfMap;
	}
	public StockChangeHelpUtils () {isGetUsedRoomFlg = false;}
	public StockChangeHelpUtils (Boolean pIsGetUsedRoomFlg) { 
        isGetUsedRoomFlg = pIsGetUsedRoomFlg;
        roomUsedInfMap = new map<String, Decimal>();
	}
	// 2017/10/27 既に割り当て済み部屋情報を取得できるよう追加 END
	// p1:roomTypeMapはNULLの場合、最新
	// 指定部屋タイプ<ID>/指定期間日付リスト
	// rt:map<部屋タイプID_日付,残室情報>
    public map<String, Decimal> getStockUsedInfo(set<id> roomTypeIds, set<Date> stockDates) {
    	// 販売部屋合計値
        //Map<String, Decimal> usedRoomsMap = new Map<String, Decimal>();
        /*
    	// 指定部屋タイプIDと日付リストの在庫残室数を取得する　
    	//map<String, Decimal> usedRoomsInfMap = new map<String, GuestRoomStock__c>();
    	// 部屋タイプの最大販売情報を取得する
    	map<Id,Decimal> roomTypeMap = new map<Id, Decimal>();
    	List<TypeOfRooms__c> rommTypesLst = [select id, MaxRooms__c from TypeOfRooms__c where id in :roomTypeIds And SumNotApplicableFlg__c != TRUE ];
		for (TypeOfRooms__c rType : rommTypesLst) {
			roomTypeMap.put(rType.Id, CommUtils.nullToZero(rType.MaxRooms__c));
		}
		/*
		//roomTypeIds = roomTypeMap.keySet();
		// ---------------------------
		// 有効な予約データ件数を統計する
		// --------------------------
        
        Integer leadCancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
        String roomTypeNormalFlg = CommConst.ROOMTYPE_NORMAL;
		String leadQuery = ' Select Count(ID) usedRoom ,refTypeOfRooms__c typeRoomId , DAY_ONLY(convertTimezone(EntryTime__c)) cidate From Lead__c ' +
						 ' Where CancelBool__c != :leadCancelFlg ' +
						 ' And refTypeOfRooms__r.SumNotApplicableFlg__c != true ' +
						 ' And DAY_ONLY(convertTimezone(EntryTime__c)) = :stockDates ' +
						 // 部屋タイプ種別=通常
						 ' And refTypeOfRooms__r.ActionType__c = :roomTypeNormalFlg ' +
						 ' And (refTypeOfRooms__c in :roomTypeIds Or Rroom__r.TypeRoomRef__c in :roomTypeIds ) ';
		leadQuery += 	 ' Group By refTypeOfRooms__c, DAY_ONLY(convertTimezone(EntryTime__c)) ' +
						 ' Order by refTypeOfRooms__c, DAY_ONLY(convertTimezone(EntryTime__c)) ';
		// 集計値を取得する			 
		for (AggregateResult ar : DataBase.query(leadQuery)) {			 
            // 部屋タイプIDを取得する
			Id roomTypeId = (Id)ar.get('typeRoomId');
        	// 到着日
        	Date ciDate = (Date)ar.get('cidate');
        	// 使える部屋数
        	Decimal userRoom = (Decimal)ar.get('usedRoom'); 
        	// 処理キーを取得する
        	String roomTypeKey = getRoomStockKey(roomTypeId, ciDate);
        	// 最大販売室数
        	Decimal maxRooms = roomTypeMap.get(roomTypeId);
			// 既に使用した部屋数を計算を行う
			//dispRecordMap.get(roomTypeId).roomList[days].QtyOfStock__c = dispRecordMap.get(roomTypeId).roomList[days].QtyOfStock__c - userRoom;
			if (!usedRoomsMap.containsKey(roomTypeKey)) {
				StockInfo stock = new StockInfo(roomTypeId);
				usedRoomsMap.put(roomTypeKey, stock);
			}
			// 利用部屋数と最大部屋数情報を格納する
			StockInfo stock = usedRoomsMap.get(roomTypeKey);
			stock.maxRooms = maxRooms;
			stock.useRooms += userRoom;
			//usedRoomsMap.put(roomTypeKey, stock);

		} // End For(予約データ取得・在庫設定処理完了)
		// 故障部屋情報を取得する
		Map<String, StockInfo> badRoomsMap = queryBadRoomMap(roomTypeIds, stockDates);
		*/
		// 2018/04/04 部屋単位の予約情報を取得する[故障部屋は時間単位登録対応] BEGIN
		isGetUsedRoomFlg = true;
		roomUsedInfMap = new map<String, Decimal>();
		// 2018/04/04 部屋単位の予約情報を取得する[故障部屋は時間単位登録対応] END
		// 有効の予約から利用している部屋数を集計する
		map<string, decimal> leadUsdRoomMaps = queryExistLeadMap(roomTypeIds, stockDates);
		// 故障部屋から利用部屋数を取得する
		map<string, decimal> badRoomUsdRoomMaps = queryBadRoomMap(roomTypeIds, stockDates);
		// 利用情報キーリストを作成する
		List<String> loopKeyLst = new list<string>();
		loopKeyLst.addAll(leadUsdRoomMaps.keySet());
		loopKeyLst.addAll(badRoomUsdRoomMaps.keySet());
		
		map<String, Decimal> usedRoomsMap = new map<String, Decimal>();
		for (String key : loopKeyLst) {
			Decimal usedRooms = 0;
			if (leadUsdRoomMaps.containskey(key)) {
				usedRooms += leadUsdRoomMaps.get(key);
			}
			if (badRoomUsdRoomMaps.containskey(key)) {
				usedRooms += badRoomUsdRoomMaps.get(key);
			}
			usedRoomsMap.put(key, usedRooms);
		}
//System.debug(loggingLevel.info, 'usedRoomsMap='+usedRoomsMap);
		return usedRoomsMap;
						 
    }
	// 有効な予約データ件数を統計する
	// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
    public map<String, Decimal> queryExistLeadMap(set<id> roomTypeIds, set<Date> stockDates) {
    // 2018/12/15 在庫調整と販売状態管理 by zy END
		// ---------------------------
		// 有効な予約データ件数を統計する
		// ---------------------------
        // 販売部屋合計値
        Map<String, Decimal> leadUsedRoomsMap = new Map<String, Decimal>();
		// 2018/08/23 予約検索機能性能改善対応 BEGIN
		// 予約データのインデックス項目を設定済みにより、検索用項目のWHERE条件を変更する
		Boolean isFixedFlg = DataFixManagerUtils.getInstance().LeadFixed__c;
		set<string> targetDtSet = (isFixedFlg ? DataFixManagerUtils.dateListToStrYMD(stockDates) : null);
		// 2018/08/23 予約検索機能性能改善対応 END
        Integer leadCancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
        String roomTypeNormalFlg = CommConst.ROOMTYPE_NORMAL;
        // 2019/02/11 予約在庫の利用数集計方法と故障部屋の重複重複機能変更対応 WSQ BEGIN
        // GROUP機能、部屋タイプ単位まで集計に変更する
		//String leadQuery = ' Select Count(ID) usedRoom ,refTypeOfRooms__c typeRoomId , DAY_ONLY(convertTimezone(EntryTime__c)) cidate From Lead__c ' +
		String leadQuery = ' Select Rroom__c, refTypeOfRooms__c, EntryTime__c From Lead__c '+
		// 2019/02/11 予約在庫の利用数集計方法と故障部屋の重複重複機能変更対応 WSQ END
						 ' Where CancelBool__c != :leadCancelFlg ' +
						 // 2017/09/04 性能問題解消対応 BEGIN
						 //' And refTypeOfRooms__r.SumNotApplicableFlg__c != true ' +
						 // 2018/08/23 予約検索機能性能改善対応 BEGIN
						 //' And DAY_ONLY(convertTimezone(EntryTime__c)) = :stockDates ' +
						 (isFixedFlg ? ' And EntryDateKey__c = :targetDtSet ' :' And DAY_ONLY(convertTimezone(EntryTime__c)) = :stockDates ') +
						 // 2018/08/23 予約検索機能性能改善対応 END
						 // 部屋タイプ種別=通常
						 //' And refTypeOfRooms__r.ActionType__c = :roomTypeNormalFlg ' +
						 //' And (refTypeOfRooms__c in :roomTypeIds Or Rroom__r.TypeRoomRef__c in :roomTypeIds ) ';
						 ' And refTypeOfRooms__c in :roomTypeIds';
						 // 2017/09/04 性能問題解消対応 END
		// 2019/02/11 予約在庫の利用数集計方法と故障部屋の重複重複機能変更対応 WSQ BEGIN
		//leadQuery += 	 ' Group By refTypeOfRooms__c, DAY_ONLY(convertTimezone(EntryTime__c)) ' +
		//				 ' Order by refTypeOfRooms__c, DAY_ONLY(convertTimezone(EntryTime__c)) ';
		// 2019/02/11 予約在庫の利用数集計方法と故障部屋の重複重複機能変更対応 WSQ END
		// 2020/05/29 在庫計算ロジック改修 WGCH BEGIN
		if(isStockSyncIsMode == STOCK_SYNC_MODE_0) leadQuery += ' And AgtFlg__c = false ';
		// 2020/05/29 在庫計算ロジック改修 WGCH END
system.debug(loggingLevel.info,'leadQuery='+leadQuery);
		// 集計値を取得する			 
		// 2019/02/11 予約在庫の利用数集計方法と故障部屋の重複重複機能変更対応 WSQ BEGIN
		/*
		for (AggregateResult ar : DataBase.query(leadQuery)) {
            // 部屋タイプIDを取得する
			Id roomTypeId = (Id)ar.get('typeRoomId');
        	// 到着日
        	Date ciDate = (Date)ar.get('cidate');
        	// 使える部屋数
        	Decimal usedRoom = (Decimal)ar.get('usedRoom'); 
        	*/
		for (Lead__c ld : DataBase.query(leadQuery)) {
			// 部屋タイプIDを取得する
			Id roomTypeId = ld.refTypeOfRooms__c;
        	// 到着日
        	Date ciDate = ld.EntryTime__c.date();
        	// 利用した部屋数
        	Decimal usedRoom = 1;
        	// 部屋IDを取得する
        	Id roomId = ld.Rroom__c;
        	if (!CommUtils.isBlank(roomId)) {
	            // 処理キーを取得する
	            String roomKey = getRoomStockKey(roomId, ciDate);
	            // 該当部屋は該当日に利用されている
	            roomUsedInfMap.put(roomKey, 1);
        	}
        // 2019/02/11 予約在庫の利用数集計方法と故障部屋の重複重複機能変更対応 WSQ END
        	// 処理キーを取得する
        	String roomTypeKey = getRoomStockKey(roomTypeId, ciDate);
        	// 最大販売室数
        	//Decimal maxRooms = roomTypeMap.get(roomTypeId);
			// 既に使用した部屋数を計算を行う
			if (!leadUsedRoomsMap.containsKey(roomTypeKey)) leadUsedRoomsMap.put(roomTypeKey, 0);
			leadUsedRoomsMap.put(roomTypeKey, (leadUsedRoomsMap.get(roomTypeKey) + usedRoom));

		} // End For(予約データ取得・在庫設定処理完了)
		// 2019/02/11 予約在庫の利用数集計方法と故障部屋の重複重複機能変更対応 WSQ BEGIN
		/*
		// 2017/10/27 既に割り当て済み部屋情報を取得できるよう追加 BEGIN
		if (isGetUsedRoomFlg) {
            // 指定の部屋タイプの予約に既に割り当て済み部屋情報
            leadQuery = ' Select Rroom__c roomId , DAY_ONLY(convertTimezone(EntryTime__c)) cidate From Lead__c ' +
                         ' Where CancelBool__c != :leadCancelFlg ' +
                         // 2018/08/23 予約検索機能性能改善対応 BEGIN
                         //' And DAY_ONLY(convertTimezone(EntryTime__c)) = :stockDates ' +
                         (isFixedFlg ? ' And EntryDateKey__c = :targetDtSet ' :' And DAY_ONLY(convertTimezone(EntryTime__c)) = :stockDates ') +
                         // 2018/08/23 予約検索機能性能改善対応 END
                         ' And refTypeOfRooms__c in :roomTypeIds'+
                         ' And Rroom__c != null '+
                         ' Group By Rroom__c, DAY_ONLY(convertTimezone(EntryTime__c)) ' +
                         ' Order by Rroom__c, DAY_ONLY(convertTimezone(EntryTime__c)) ';
system.debug(loggingLevel.info,'leadQuery2='+leadQuery);
            for (AggregateResult ar : DataBase.query(leadQuery)) {
	            // 部屋タイプIDを取得する
	            Id roomId = (Id)ar.get('roomId');
	            // 到着日
	            Date ciDate = (Date)ar.get('cidate');
	            // 処理キーを取得する
	            String roomKey = getRoomStockKey(roomId, ciDate);
	            // 該当部屋は該当日に利用されている
	            roomUsedInfMap.put(roomKey, 1);
            }
		}
		*/
		// 2019/02/11 予約在庫の利用数集計方法と故障部屋の重複重複機能変更対応 WSQ END
		// 2017/10/27 既に割り当て済み部屋情報を取得できるよう追加 END
		return leadUsedRoomsMap;
    }
    // 過去在庫情報を対象外
    // 指定日付の故障部屋情報を取得する
    // RETURN: map<部屋タイプID_日付,故障数>
	public Map<String, Decimal> queryBadRoomMap (set<id> roomTypeIds, set<Date> stockDates) {
		// 2019/10/09 部屋状態管理インデックス機能対応 WSQ BEGIN
		Boolean isFixedFlg = DataFixManagerUtils.getInstance().RoomsStatusFixed__c;
		// 2019/10/09 部屋状態管理インデックス機能対応 WSQ END
		// 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
		Boolean isFixedFlg1 = DataFixManagerUtils.getInstance().RoomsStatusFixed1__c;
		// 2020/08/30 部屋状態管理インデックス機能対応 WGCH END
    	// 当日日付
    	Date todayDt = Date.today();
    	// 期間リストを取得する
    	List<Date> dateRangeLst = new List<Date>();
    	dateRangeLst.addAll(stockDates);
    	dateRangeLst.sort();
    	Date conBegDate = dateRangeLst[0];
    	Date conEndDate = dateRangeLst[dateRangeLst.size() - 1];
    	// set<部屋ID_日付>
    	Set<String> badRoomKeySet = new Set<String>();
    	// Map<Date,Map<Id, Integer>> badRoomNumMap = new Map<Date, Map<Id, Integer>>();
    	Map<String, Decimal> badRoomNumsMap = new Map<String, Decimal>();
    	// 取得対象情報
        String queryHd = CommSqlUtils.generateQueryString('RoomsStatus__c',new String[]{'RoomRef__r.TypeRoomRef__c'});
        // 部屋ステータス：故障　AND　処理結果は　修理済　以外の場合
        String queryWhere = ' where Status__c = \'' + String.escapeSingleQuotes(CommConst.ROOM_ST_TYPE_BED) + '\'';
        queryWhere += ' And Result__c != \'' + String.escapeSingleQuotes(CommConst.ROOM_ST_TYPE_BED_FIN) + '\'';
        //queryWhere += ' And StatusBeginDate__c <= :todayDt ';
        //queryWhere += ' And StatusEndDate__c >= :todayDt';
        // 2019/10/09 部屋状態管理インデックス機能対応 WSQ BEGIN
        String conEndDateStr = DataFixManagerUtils.dateToYMDstr(conEndDate);
        String conBegDateStr = DataFixManagerUtils.dateToYMDstr(conBegDate);
        // 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
        Integer conEndDateInt = CommUtils.nullToIntZero(conEndDateStr);
        Integer conBegDateInt = CommUtils.nullToIntZero(conBegDateStr);
        /*
        if (isFixedFlg) {
        	queryWhere += ' And StatusBeginDateKey__c <= :conEndDateStr ';
        	queryWhere += ' And StatusEndDateKey__c >= :conBegDateStr';
        }
        */
        if (isFixedFlg1) {
        	queryWhere += ' And StatusBeginDateIntKey__c <= :conEndDateInt ';
        	queryWhere += ' And StatusEndDateIntKey__c >= :conBegDateInt';
        }
        else if(isFixedFlg){
        	queryWhere += ' And StatusBeginDateKey__c <= :conEndDateStr ';
        	queryWhere += ' And StatusEndDateKey__c >= :conBegDateStr';
        }
        // 2020/08/30 部屋状態管理インデックス機能対応 WGCH END
        else {
        // 2019/10/09 部屋状態管理インデックス機能対応 WSQ END
        queryWhere += ' And StatusBeginDate__c <= :conEndDate ';
        queryWhere += ' And StatusEndDate__c >= :conBegDate';
        // 2019/10/09 部屋状態管理インデックス機能対応 WSQ BEGIN
        }
        // 2019/10/09 部屋状態管理インデックス機能対応 WSQ END
        // 2017/09/04 性能問題解消対応 BEGIN
        // 指定の部屋タイプ範囲
        //queryWhere += ' And RoomRef__r.TypeRoomRef__c in :roomTypeIds ';
        // 2015/08/05 部屋タイプの集計対象外フラグの対応 BEGIN
        //queryWhere += ' And RoomRef__r.TypeRoomRef__r.SumNotApplicableFlg__c != true ';
        queryWhere += ' And RoomRef__c in (select id from Room__c where TypeRoomRef__c in :roomTypeIds And TypeRoomRef__r.SumNotApplicableFlg__c != true) ';
        // 2017/09/04 性能問題解消対応 END
        // 2015/08/05 部屋タイプの集計対象外フラグの対応 END
        String queryStr = queryHd + queryWhere;
//System.debug(loggingLevel.info, 'queryStr='+queryStr);
//System.debug(loggingLevel.info, 'conBegDate='+conBegDate);
//System.debug(loggingLevel.info, 'conEndDate='+conEndDate);
//System.debug(loggingLevel.info, 'conEndDateStr='+conEndDateStr);
//System.debug(loggingLevel.info, 'conBegDateStr='+conBegDateStr);
        // 2018/04/04 部屋単位の予約情報を取得する[故障部屋は時間単位登録対応] BEGIN
        map<String, Decimal> leadRoomUsedInfMap = roomUsedInfMap.clone();
        // 2018/04/04 部屋単位の予約情報を取得する[故障部屋は時間単位登録対応] END
        // 最新故障情報を取得する
        for (RoomsStatus__c roomSt : Database.query(queryStr)) {
			// 故障期間日付リスト
            List<Date> rangeList = getDateRange(roomSt.StatusBeginDate__c, roomSt.StatusEndDate__c);
            for (Integer i = 0; i < rangeList.size(); i++) {
            	// KEY=部屋ID+日付
            	String roomKey = getRoomStockKey(roomSt.RoomRef__c, rangeList[i]);
                // 2017/10/27 既に割り当て済み部屋情報を取得できるよう追加 BEGIN
                if (isGetUsedRoomFlg) {
                    roomUsedInfMap.put(roomKey, 1);
                }
            	//　部屋タイプ＿日付単位存在格納
            	if(badRoomKeySet.contains(roomKey)) continue;
            	// 2018/04/04 部屋単位の予約情報を取得する[故障部屋は時間単位登録対応] BEGIN
            	// 該当部屋、同じ日付に予約情報を存在する場合、重複在庫計算しない
            	if(leadRoomUsedInfMap.containsKey(roomKey)) continue;
            	// 2018/04/04 部屋単位の予約情報を取得する[故障部屋は時間単位登録対応] END
            	// 該当日付の部屋は格納する
            	badRoomKeySet.add(roomKey);
            	// 部屋タイプ＿日付故障数統計
            	String roomTypeKey = getRoomStockKey(roomSt.TypeOfRoomTypeId__c, rangeList[i]);
            	// 該当部屋タイプの在庫値初期化
            	if(!badRoomNumsMap.containsKey(roomTypeKey)) badRoomNumsMap.put(roomTypeKey, 1);
            	else badRoomNumsMap.put(roomTypeKey, (badRoomNumsMap.get(roomTypeKey) + 1));
            }
        }
//System.debug(loggingLevel.info, 'badRoomNumsMap='+badRoomNumsMap);
		return badRoomNumsMap;
    }
	public String getRoomStockKey(Id dataId, Date dt) {
		if (dataId == null) return (Date.today()).format();
		else return dataId + '_' + dt.format();
	}
	// 開始日から終了日まで　期間日付リストを取得する
	public List<Date> getDateRange(Date pst, Date pet) {
		Date st = (pst > pet ? pet : pst);
		Date et = (pst > pet ? pst : pet);
		Integer days = st.daysBetween(et);
		List<Date> dtRange = new List<Date>();
		for (Integer i = 0; i <= days; i++) {dtRange.add(st.addDays(i));}
		return dtRange;
	}
	
	// 2018/10/03 商品在庫管理機能追加に従って、関連共通関数関数を追加する WSQ BEGIN
	// 指定の商品IDリストにより、該当商品の在庫情報IDを返却する
	public map<id,id> getProdcutStockById(set<id> prodIds) {
        List<ProductStock__c> existInfLst = [select id,ProductRef__c from ProductStock__c where ProductRef__c = :prodIds for update];
        // 商品ID、商品の在庫情報ID
        map<id, id> retMap = new map<id,id>();
        // 商品ID
        set<Id> wkprodIds = prodIds.clone();
		// 非存在する場合、自動売上データを作成する
		for (ProductStock__c s : existInfLst) {
			Id prodID = s.ProductRef__c;
			if (wkprodIds.contains(prodID)) {
				retMap.put(prodID, s.Id);
				wkprodIds.remove(prodID);
			}
		}
		// 新規作成必要の場合
		if (!wkprodIds.isEmpty()) {
			List<ProductStock__c> updLst = new List<ProductStock__c>();
			for (Id prodId : wkprodIds) {
				updLst.add(new ProductStock__c(
					ProductRef__c = prodId,
					ProductSfId__c = prodId
				));
			}
			if (!updLst.isEmpty()) {
				upsert updLst ProductStock__c.ProductSfId__c;	
				for (ProductStock__c s : updLst) {
					retMap.put(s.ProductRef__c, s.Id);
				}
			}
		}
		return retMap;
	}
	// 2018/10/03 商品在庫管理機能追加に従って、関連共通関数関数を追加する WSQ END
	// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
	// 当前最大部屋数取得
	public integer getSfMaxRoomOfRoomType(StockChangeHisotry__c sfStock){
		Integer maxCount = CommUtils.nullToIntZero(sfStock.TypeOfRoomRef__r.MaxRooms__c);
		String managerKey = getRoomStockKey(sfStock.TypeOfRoomRef__c, sfStock.StockChangeDate__c);
		// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH BEGIN
		// String stockQuery = ' Select Id, ManagerKey__c, QtyOfStock__c,StockDate__c,SalesStatusLst__c, RemainingCount__c,MaxRoomsCal__c From GuestRoomStock__c Where ManagerKey__c = :managerKey';
		String stockQuery = ' Select Id, ManagerKey__c, QtyOfStock__c,StockDate__c,SalesStatusLst__c, RemainingCount__c,MaxRoomsCal__c, AGTChangeRoomsJSON__c From GuestRoomStock__c Where ManagerKey__c = :managerKey';
		Boolean notAgtSettingFlg = true;
		// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH END
		List<GuestRoomStock__c> stockLst = DataBase.query(stockQuery);
		if (!stockLst.isEmpty()) {
			GuestRoomStock__c stock = stockLst[0];
			maxCount = CommUtils.nullToIntZero(stock.MaxRoomsCal__c);
			// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH BEGIN
			// 未设定过的标识FLG
			notAgtSettingFlg = CommUtils.isBlank(stock.AGTChangeRoomsJSON__c);
			// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH END
		}
		// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH BEGIN
		// 在庫联动功能开启
		if(isStockSyncIsMode == STOCK_SYNC_MODE_0){
			// 不存在在庫管理数据 或者 存在但没有设定过的情况下
			if(stockLst.isEmpty() || notAgtSettingFlg){
				// 获取AGT最大在库数
				Map<String, Decimal> realAGTRoomMap = StockChangeHelpUtils.getAgtMaxRoomsMap(new Set<String>{CommUtils.nullToBlank(sfStock.TypeOfRoomRef__c)}, new Set<Date>{sfStock.StockChangeDate__c});
				for(Decimal val : realAGTRoomMap.values()){
					maxCount -= CommUtils.nullToIntZero(val);
				}
			}
		}
		// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH END
		return maxCount;
	}
	public Map<String,GuestRoomStock__c> getGuestRoomInfo(set<id> roomTypeIds, set<Date> stockDates){
		// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH BEGIN
		// String stockQuery = ' Select Id, ManagerKey__c, QtyOfStock__c,StockDate__c,SalesStatusLst__c, RemainingCount__c,MaxRoomsCal__c,SettingFlg__c From GuestRoomStock__c Where RoomTypeRef__c = :roomTypeIds and StockDate__c = :stockDates';
		String stockQuery = ' Select Id, ManagerKey__c, QtyOfStock__c,StockDate__c,SalesStatusLst__c, RemainingCount__c,MaxRoomsCal__c,SettingFlg__c,AGTChangeRoomsJSON__c From GuestRoomStock__c Where RoomTypeRef__c = :roomTypeIds and StockDate__c = :stockDates';
		// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH END
		List<GuestRoomStock__c> stockLst = DataBase.query(stockQuery);
		Map<String,GuestRoomStock__c> guestRoomMap = new Map<String,GuestRoomStock__c>();
		for (GuestRoomStock__c guest : stockLst) {
			guestRoomMap.put(guest.ManagerKey__c,guest);
		}
		return guestRoomMap;
	}
	// 2018/12/15 在庫調整と販売状態管理 by zy END
	// 当前最大部屋数取得
	public map<string,integer> getSfMaxRoomOfRoomType(TypeOfRooms__c pRoomType, set<Date> stockDateLst){
		// キー別最大在庫数情報を格納する
		map<string,integer> maxRoomsMap = new map<string,integer>();
		// 該当部屋タイプの最大在庫数を格納する
		Integer maxCount = CommUtils.nullToIntZero(pRoomType.MaxRooms__c);
		list<String> keyLst = new list<String>();
		for (Date dt : stockDateLst) {
			// キー
			String key = getRoomStockKey(pRoomType.Id, dt);
			// キー情報を配列に格納する
			keyLst.add(key);
			// 該当キー関連の最大在庫数を格納する
			maxRoomsMap.put(key, maxCount);
		}
		// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH BEGIN
		// String stockQuery = ' Select Id, ManagerKey__c, QtyOfStock__c,StockDate__c,SalesStatusLst__c, RemainingCount__c,MaxRoomsCal__c From GuestRoomStock__c Where ManagerKey__c = :keyLst';
		String stockQuery = ' Select Id, ManagerKey__c, QtyOfStock__c,StockDate__c,SalesStatusLst__c, RemainingCount__c,MaxRoomsCal__c,AGTChangeRoomsJSON__c From GuestRoomStock__c Where ManagerKey__c = :keyLst';
		Map<String, Boolean> notAgtSettingFlgMap = new Map<String, Boolean>();
		// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH END
		List<GuestRoomStock__c> stockLst = DataBase.query(stockQuery);
		for (GuestRoomStock__c stock : stockLst) {
			Integer maxCnt = CommUtils.nullToIntZero(stock.MaxRoomsCal__c);
			maxRoomsMap.put(stock.ManagerKey__c, maxCnt);
			// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH BEGIN
			// 未设定过的标识FLG
			notAgtSettingFlgMap.put(stock.ManagerKey__c, CommUtils.isBlank(stock.AGTChangeRoomsJSON__c));
			// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH END
		}
		// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH BEGIN
		// 在庫联动功能开启
		if(isStockSyncIsMode == STOCK_SYNC_MODE_0){
			// 获取AGT最大在库数
			Map<String, Decimal> realAGTRoomMap = StockChangeHelpUtils.getAgtMaxRoomsMap(new Set<String>{CommUtils.nullToBlank(pRoomType.Id)}, stockDateLst);
			for(String key : realAGTRoomMap.keySet()){
				// 取引先Id_部屋タイプId_在库日
				List<String> wkKeyLst = key.split('_');
				if(wkKeyLst.size() != 3) continue;
				String managerKey = wkKeyLst[1] + '_' + wkKeyLst[2];
				// 设定过AGT-JSON
				if((notAgtSettingFlgMap.containsKey(managerKey) && !notAgtSettingFlgMap.get(managerKey))) continue;
				// 减掉AGT的最大在库数
				maxRoomsMap.put(managerKey, CommUtils.nullToIntZero(maxRoomsMap.get(managerKey)) - CommUtils.nullToIntZero(realAGTRoomMap.get(key)));
			}
		}
		// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH END
		return maxRoomsMap;
	}
	// 2020/05/29 在庫計算ロジック改修 WGCH BEGIN
	public static final String ACCTYPE_TRAVE = '旅行会社';
	public static final String STOCK_SYNC_MODE_0 = '0';
	public static final String STOCK_SYNC_MODE_1 = '1';
	// 2020/07/06 默认值修订 WGCH BEGIN
	// public static String isStockSyncIsMode{get{return CommDefine__c.getOrgDefaults().StockSyncIsMode__c == null ? '0' : CommDefine__c.getOrgDefaults().StockSyncIsMode__c;}}
	public static String isStockSyncIsMode{get{return CommDefine__c.getOrgDefaults().StockSyncIsMode__c == null ? STOCK_SYNC_MODE_1 : CommDefine__c.getOrgDefaults().StockSyncIsMode__c;}}
	// 2020/07/06 默认值修订 WGCH END
    // 2021/03/16 リアルAGTの予約かどうかの識別に親取引先を参照にするBUG[#PC9889] WGCH BEGIN
    public static Boolean isAGTReferToParentFlg{get{return CommDefine__c.getOrgDefaults().AGTReferToParentFlg__c == null ? false : CommDefine__c.getOrgDefaults().AGTReferToParentFlg__c;}}
    // 2021/03/16 リアルAGTの予約かどうかの識別に親取引先を参照にするBUG[#PC9889] WGCH END
// 2020/05/29 在庫計算ロジック改修 WGCH END
	// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH BEGIN
	public static Map<String, Decimal> getAgtMaxRoomsMap(Set<Id> roomTypeIds, Set<Date> stockDateSet){
		Set<String> roomTypeIdSet = new Set<String>();
		for(Id roomTypeId : roomTypeIds){
			roomTypeIdSet.add(CommUtils.nullToBlank(roomTypeId));
		}
		return getAgtMaxRoomsMap(roomTypeIdSet, stockDateSet);
	}
	// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH END
	// 2020/08/30 リアルAGT支店别での対応 WGCH BEGIN
	// リアルＡＧＴ利用する部屋数情報を統計する
	public static Map<String, Decimal> getAgtMaxRoomsMap(Set<String> roomTypeIdSet, Set<Date> stockDateSet){
		// リアルAGT部屋から利用部屋数を取得する
		Map<String, Decimal> realAGTRoomMap = new Map<String, Decimal>();
		if(roomTypeIdSet.isEmpty() || stockDateSet.isEmpty()) return realAGTRoomMap;
		// 2020/08/30 代码优化 WGCH BEGIN
		Date dateBeg = null;
		Date dateEnd = null;
		for(Date stockDate : stockDateSet){
			dateBeg = dateBeg == null ? stockDate : (dateBeg > stockDate ? stockDate : dateBeg);
			dateEnd = dateEnd == null ? stockDate : (dateEnd < stockDate ? stockDate : dateEnd);
		}
		// 2020/08/30 代码优化 WGCH END
		// 指定期間により、各ＡＧＴに提供する部屋数を取得、格納する
		String realMstQuery = ' Select Id, AccountRef__c, AgtMaxRooms__c, StartDate__c, SearchKey__c, EndDate__c, RoomTypeRel__c '
								+ ' From RealAGT__c '
								+ ' Where AccountRef__r.AccountType__c =: ACCTYPE_TRAVE '
								+ ' And RoomTypeRel__c in: roomTypeIdSet '
								+ ' And AgtMaxRooms__c  > 0 ';
		// 2020/08/30 代码优化 WGCH BEGIN
		realMstQuery += ' And (StartDate__c <=: dateEnd And EndDate__c >=: dateBeg) ';
		// 2020/08/30 代码优化 WGCH END
		List<RealAGT__c> agtMsgLst = DataBase.query(realMstQuery);
		if (agtMsgLst.isEmpty()) return realAGTRoomMap;
		// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH BEGIN
		StockChangeHelpUtils stockUtils = null;
		Map<String,GuestRoomStock__c> guestRoomInfoMap = null;
		// 在庫联动功能开启
		if(isStockSyncIsMode == STOCK_SYNC_MODE_0){
			stockUtils = new StockChangeHelpUtils();
			Set<Id> roomTypeIdsSet = new Set<Id>();
			for(String typeId : roomTypeIdSet){
				roomTypeIdsSet.add((Id)typeId);
			}
			guestRoomInfoMap = stockUtils.getGuestRoomInfo(roomTypeIdsSet, stockDateSet);
		}
		// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH END
		// リアルＡＧＴマスタ設定情報を取得する
		// 各旅行開始社、期間により、販売最大可能部屋数
		for (RealAGT__c s : agtMsgLst) {
			// 最大販売できる部屋数 
			Decimal mstMaxRooms = CommUtils.nullToZero(s.AgtMaxRooms__c);
			for (Date stockDate : stockDateSet) {
				/*
				* TODO重叠设定怎么办 例如: A房间 2020.01.20-2020.02.20, 2房; A房间 2020.02.01-2020.02.20, 5房;
				*/
				if(stockDate >= s.StartDate__c && stockDate <= s.EndDate__c ){
					// 処理キーを取得する
					String key = getRealAGTRoomKey(s.AccountRef__c, s.RoomTypeRel__c, stockDate);
					// 該当部屋は該当日に利用されている
					if(!realAGTRoomMap.containsKey(key)) realAGTRoomMap.put(key, 0);
					Decimal gMstMaxRooms = realAGTRoomMap.get(key) + mstMaxRooms;
					// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH BEGIN
					// 在庫联动功能开启
					if(guestRoomInfoMap != null && isStockSyncIsMode == STOCK_SYNC_MODE_0){
						String managerKey = stockUtils.getRoomStockKey(s.RoomTypeRel__c, stockDate);
						GuestRoomStock__c guestRoom = guestRoomInfoMap.get(managerKey);
						if(guestRoom != null){
							Map<String, Object> atgChangeMap = getAGTChangeRoomsMap(guestRoom.AGTChangeRoomsJSON__c);
							// 加变更的数据值
							gMstMaxRooms += CommUtils.nullToZero(atgChangeMap.get(s.AccountRef__c));
						}
					}
					// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH END
					realAGTRoomMap.put(key, gMstMaxRooms);
				}
			}
		}
		return realAGTRoomMap;
	}
	// 获取RealAgtKey
	public static String getRealAGTRoomKey(String accountId, String roomTypeId, Date stockDate) {
		if (stockDate == null) stockDate = Date.today();
		// 取引先Id_部屋タイプId_在库日
		return CommUtils.nullToBlank(accountId) + '_' + CommUtils.nullToBlank(roomTypeId) + '_' + stockDate.format();
	}
	// 2020/08/30 リアルAGT支店别での対応 WGCH END
	// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH BEGIN
	// 获取リアルAGT残室数变更MAP
	public static Map<String, Object> getAGTChangeRoomsMap(String agtChangeRoomsJson) {
		Map<String, Object> objMap = new Map<String, Object>();
		// KEY: 取引先ID; VAL: AGT变更数
		if(CommUtils.isBlank(agtChangeRoomsJson)) return objMap;
		objMap = (Map<String, Object>)JSON.deserializeUntyped(CommUtils.nullToBlank(agtChangeRoomsJson));
		return objMap;
	}
	// 获取リアルAGT残室数变更JSON
	public static String setAGTChangeRoomsJson(Map<String, Decimal> agtChangeRoomsMap) {
		// リアルAGT残室数变更JSON
		return JSON.serialize(agtChangeRoomsMap);
	}
	// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH END
}