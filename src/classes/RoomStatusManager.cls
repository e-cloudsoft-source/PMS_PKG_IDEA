/*********************************************
* 部屋ステータス管理クラス
* 2013/08/14: CreateV1.0
* 2016/09/08: チェックアウトのタイミング、清掃データ作成する、しない切替機能対応
**/
public with sharing class RoomStatusManager {

	public static final String NOCLEAN = '未清掃';
	public static final String CLEANED = '清掃済';
	public static final String DEF_START_TIME = '00:00';
	public static final String DEF_END_TIME = '24:00';
	/**
	* 未清掃の部屋リストを取得する
	**/
	public Map<Id, String> getCleanStatusRooms (Date processDate) {
    	Map<Id, String> cleanStatusRoomMap = new Map<Id, String>();
        String queryHd = CommSqlUtils.generateQueryString('RoomsStatus__c');
        String queryWhere = ' where Status__c = \'' + String.escapeSingleQuotes(CommConst.ROOM_ST_TYPE_CLS) + '\'';
        queryWhere += ' And StatusBeginDate__c <= ' + String.valueOf(processDate);
        queryWhere += ' And StatusEndDate__c >= ' + String.valueOf(processDate);
        String queryStr = queryHd + queryWhere;
        for (RoomsStatus__c roomSt : Database.query(queryStr)) {
            if (cleanStatusRoomMap.containsKey(roomSt.RoomRef__c)) {
            	// 未清掃以外のデータが存在する場合、新データを更新を行う、１件異常の未清掃データ存在すると、未清掃と認識する
            	if (cleanStatusRoomMap.get(roomSt.RoomRef__c) != CommConst.LEAD_ROOM_ST_UNCLEAN) cleanStatusRoomMap.put(roomSt.RoomRef__c, roomSt.Result__c);
            } else {
            	cleanStatusRoomMap.put(roomSt.RoomRef__c, roomSt.Result__c);
            }
        }
        return cleanStatusRoomMap;
	}
	/**
	* 未清掃部屋データ作成を行う[予約データにより]
	* Checkoutの場合、チェックアウト日の日付により、未清掃データ作成する・しない対応
	**/
	public void createNoCleanRooms (Date procDate, List<Lead__c> leadList) {
		// 2016/09/08 チェックアウトのタイミング、清掃データ作成する、しない切替機能対応 BEGIN
		Boolean cleanDataCtrlFlg = false;
		if (CommDefine__c.getOrgDefaults().ClearDataCreateOnCheckoutDay__c != null) {
			cleanDataCtrlFlg = CommDefine__c.getOrgDefaults().ClearDataCreateOnCheckoutDay__c;
		}
		List<RoomsStatus__c> roomStatusLst = new List<RoomsStatus__c>();
		String todayStr =  DateTime.now().format('yyyyMMddHHmmssSSS');
		//Set<Id> roomIdSet = new Set<Id>();
		// 2016/09/08 チェックアウトのタイミング、清掃データ作成する、しない切替機能対応 END
        // 2019/08/31 42.ご予約チェックアウト後の「未清掃」ステータスの付与処理をお部屋によってON/OFFができるようにしたい by zy BEGIN
        Set<String> roomSet = new Set<String>();
        Set<String> notCreateSet = new Set<String>();
        for (Lead__c lead : leadList) roomSet.add(lead.Rroom__c);
        for (Room__c room : [select id,RoomNotCreateFlg__c from Room__c where id = :roomSet and RoomNotCreateFlg__c = true]) notCreateSet.add(room.id);
        // 2019/08/31 42.ご予約チェックアウト後の「未清掃」ステータスの付与処理をお部屋によってON/OFFができるようにしたい by zy END
		for (Lead__c lead : leadList) {
			// 2016/09/08 チェックアウトのタイミング、清掃データ作成する、しない切替機能対応 BEGIN
			//if (lead.Rroom__c != null) roomIdSet.add(lead.Rroom__c);
			if (lead.Rroom__c == null) continue;
            // 2019/08/31 42.ご予約チェックアウト後の「未清掃」ステータスの付与処理をお部屋によってON/OFFができるようにしたい by zy BEGIN
            if (notCreateSet.contains(lead.Rroom__c)) continue;
            // 2019/08/31 42.ご予約チェックアウト後の「未清掃」ステータスの付与処理をお部屋によってON/OFFができるようにしたい by zy END
			Date locProcDate = procDate;
			// FALSEの場合、チェックアウト日の日付の未清掃データを作成する
			if (!cleanDataCtrlFlg) locProcDate = lead.checkoutdate__c;
			// 新規部屋ステータス管理データ可能する
			roomStatusLst.add( new RoomsStatus__c(
            //清掃管理データ自動作成_
                Name = Label.CONST_012_0496 + todayStr,
				RoomRef__c = lead.Rroom__c,
				Status__c = CommConst.ROOM_ST_TYPE_CLS,
				StatusBeginDate__c = locProcDate,
				StatusEndDate__c = locProcDate,
				Result__c = CommConst.LEAD_ROOM_ST_UNCLEAN));
			// 2016/09/08 チェックアウトのタイミング、清掃データ作成する、しない切替機能対応 END
		}
		// 2016/09/08 チェックアウトのタイミング、清掃データ作成する、しない切替機能対応 BEGIN
		//createNoCleanRooms(procDate, roomIdSet);
		if (!roomStatusLst.isEmpty()) insert roomStatusLst;
		// 2016/09/08 チェックアウトのタイミング、清掃データ作成する、しない切替機能対応 END
	}
	// 引き渡す予約はチェックアウト後、関連の部屋は自動清掃管理データ作成を行う
	// 注意：引き渡す項目に、checkoutdate__c/EntryTime__c 必須
	public void createNoCleanRooms(List<Lead__c> leadList) {
		// String:到着日+部屋ID
		Set<String> filterSet = new Set<String>();
		// 記録作成時刻
		String todayStr =  DateTime.now().format('yyyyMMddHHmmssSSS');
		// 当時比較
		Date filterDate = Date.today();
		// 新規清掃データ情報を格納用配列
		List<RoomsStatus__c> roomStatusLst = new List<RoomsStatus__c>();
        // 2019/08/31 42.ご予約チェックアウト後の「未清掃」ステータスの付与処理をお部屋によってON/OFFができるようにしたい by zy BEGIN
        Set<String> roomSet = new Set<String>();
        Set<String> notCreateSet = new Set<String>();
        for (Lead__c lead : leadList) roomSet.add(lead.Rroom__c);
        for (Room__c room : [select id,RoomNotCreateFlg__c from Room__c where id = :roomSet and RoomNotCreateFlg__c = true]) notCreateSet.add(room.id);
        // 2019/08/31 42.ご予約チェックアウト後の「未清掃」ステータスの付与処理をお部屋によってON/OFFができるようにしたい by zy END
		for (Lead__c lead : leadList) {
			if (lead.Rroom__c == null) continue;
            // 2019/08/31 42.ご予約チェックアウト後の「未清掃」ステータスの付与処理をお部屋によってON/OFFができるようにしたい by zy BEGIN
            if (notCreateSet.contains(lead.Rroom__c)) continue;
            // 2019/08/31 42.ご予約チェックアウト後の「未清掃」ステータスの付与処理をお部屋によってON/OFFができるようにしたい by zy END
			// Clear Date:
			Date cleanDate = lead.checkoutdate__c;
			// 過去と未来のデータを無視する
			if (cleanDate != filterDate ) continue;
			// 同じ部屋、同じ日付のデータは一件だけ清掃データ作成を行う
			String key = lead.Rroom__c + '_' + lead.checkoutdate__c;
			// 既に作成済み清掃データは処理SKIPする
			if (filterSet.contains(key)) continue;
			// 新規部屋ステータス管理データ可能する
			roomStatusLst.add( new RoomsStatus__c(
            //清掃管理データ自動作成_
                Name = Label.CONST_012_0496 + todayStr,
				RoomRef__c = lead.Rroom__c,
				Status__c = CommConst.ROOM_ST_TYPE_CLS,
				StatusBeginDate__c = cleanDate,
				StatusEndDate__c = cleanDate,
				Result__c = CommConst.LEAD_ROOM_ST_UNCLEAN));
				
			filterSet.add(key);
		}
		if (!roomStatusLst.isEmpty()) insert roomStatusLst;
	}
	/**
	* 未清掃部屋データ作成を行う
	**/
	public void createNoCleanRooms (Date procDate, Set<Id> roomIdSet) {
		// 過去日の場合、清掃データは作成しません.
		// 2015/05/06 当日のみ、清掃データを作成する
//		if (procDate < Date.today()) return;
		if (procDate != Date.today()) return;
		// 部屋ステータス管理データ作成
		List<RoomsStatus__c> roomStatusLst = new List<RoomsStatus__c>();
        // 2019/08/31 42.ご予約チェックアウト後の「未清掃」ステータスの付与処理をお部屋によってON/OFFができるようにしたい by zy BEGIN
        Set<String> notCreateSet = new Set<String>();
        for (Room__c room : [select id,RoomNotCreateFlg__c from Room__c where id = :roomIdSet and RoomNotCreateFlg__c = true]) notCreateSet.add(room.id);
        // 2019/08/31 42.ご予約チェックアウト後の「未清掃」ステータスの付与処理をお部屋によってON/OFFができるようにしたい by zy END
		String todayStr =  DateTime.now().format('yyyyMMddHHmmssSSS');
		for (Id roomId : roomIdSet) {
            // 2019/08/31 42.ご予約チェックアウト後の「未清掃」ステータスの付与処理をお部屋によってON/OFFができるようにしたい by zy BEGIN
            if (notCreateSet.contains(roomId)) continue;
            // 2019/08/31 42.ご予約チェックアウト後の「未清掃」ステータスの付与処理をお部屋によってON/OFFができるようにしたい by zy END
			// 新規部屋ステータス管理データ可能する
			roomStatusLst.add( new RoomsStatus__c(
            //清掃管理データ自動作成_
                Name = Label.CONST_012_0496 + todayStr,
				RoomRef__c = roomId,
				Status__c = CommConst.ROOM_ST_TYPE_CLS,
				StatusBeginDate__c = procDate,
				StatusEndDate__c = procDate,
				Result__c = CommConst.LEAD_ROOM_ST_UNCLEAN));
		}
		insert roomStatusLst;
	}
    /**
    * 故障部屋状態を取得する
    * 2013/10/07
    **/
    public Set<Id> queryBadRoomSet(Date startDate, Date endDate) {
        Set<Id> badRoomSet = new Set<Id>();
        /*
        String queryHd = CommSqlUtils.generateQueryString('RoomsStatus__c');
        String queryWhere = ' where Status__c = \'' + String.escapeSingleQuotes(CommConst.ROOM_ST_TYPE_BED) + '\'';
        queryWhere += ' And Result__c != \'' + String.escapeSingleQuotes(CommConst.ROOM_ST_TYPE_BED_FIN) + '\'';
        queryWhere += ' And StatusBeginDate__c <= :endDate ';
        queryWhere += ' And StatusEndDate__c >= :startDate';
        String queryStr = queryHd + queryWhere;
        for (RoomsStatus__c roomSt : Database.query(queryStr)) {
        */
        for (RoomsStatus__c roomSt : queryBadRoomList(startDate, endDate)) {
            badRoomSet.add(roomSt.RoomRef__c);
        }
        return badRoomSet;
    }
    /**
    * 故障部屋状態を取得する
    * 2014/11/17
    **/
    public List<RoomsStatus__c> queryBadRoomList(Date startDate, Date endDate) {
        return queryBadRoomList(startDate, endDate, null);
    }
    public List<RoomsStatus__c> queryBadRoomList(Date startDate, Date endDate, Set<Id> roomIds) {
        String queryHd = CommSqlUtils.generateQueryString('RoomsStatus__c', new String[]{'RoomRef__r.Name'});
        String queryWhere = ' where Status__c = \'' + String.escapeSingleQuotes(CommConst.ROOM_ST_TYPE_BED) + '\'';
        queryWhere += ' And Result__c != \'' + String.escapeSingleQuotes(CommConst.ROOM_ST_TYPE_BED_FIN) + '\'';
        queryWhere += ' And StatusBeginDate__c <= :endDate ';
        queryWhere += ' And StatusEndDate__c >= :startDate';
        if (roomIds != null && !roomIds.isEmpty()) queryWhere += ' And RoomRef__c in :roomIds ';
        String queryStr = queryHd + queryWhere + ' Order By RoomRef__c asc, StatusBeginDate__c asc ';
        return Database.query(queryStr);
    }
    
    /**
    * 部屋ステータスは清掃済に管理する
    **/
    public void upClearnStatus(Date procDate, Set<Id> roomIdSet) {
    	// 2018/08/01 部屋清掃済みの場合清掃状態自動更新　by zy BEGIN
    	String spcd = '';
    	// 2018/08/01 部屋清掃済みの場合清掃状態自動更新　by zy END
        List<RoomsStatus__c> updLst = new List<RoomsStatus__c>();
        // 2018/8/28 ルームインジケーターのチェックアウトから日をまたぐと未清掃が反映 BY WSQ BEGIN
        // 日付を未指定の場合、指定部屋のすべて未清掃データは自動清掃済みになる
        String unCleanFlg = CommConst.LEAD_ROOM_ST_UNCLEAN;//未清掃保持フラグ
        String cleanedFlg = CommConst.ROOM_ST_TYPE_CLS;//清掃
        String queryStr = 'select id, Result__c,CleanStatus__c,RoomRef__r.ShopInfoRef__r.ShopCode__c'+
        					' from RoomsStatus__c'+
        					' Where Status__c = :cleanedFlg And Result__c = :unCleanFlg And RoomRef__c = :roomIdSet';
        if (procDate != null) {
        	queryStr += ' And StatusBeginDate__c <= :procDate And StatusEndDate__c >= :procDate';
        }
        /*
        for (RoomsStatus__c roomStatus : [select id, Result__c 
        									// 2018/08/01 部屋清掃済みの場合清掃状態自動更新　by zy BEGIN
        									,CleanStatus__c,RoomRef__r.ShopInfoRef__r.ShopCode__c
        									// 2018/08/01 部屋清掃済みの場合清掃状態自動更新　by zy END
        									from RoomsStatus__c
                                            Where Status__c = :CommConst.ROOM_ST_TYPE_CLS And Result__c = :CommConst.LEAD_ROOM_ST_UNCLEAN And RoomRef__c = :roomIdSet 
                                            And StatusBeginDate__c <= :procDate And StatusEndDate__c >= :procDate]) {
                                            	*/
        for (RoomsStatus__c roomStatus : Database.query(queryStr)) {
        // 2018/8/28 ルームインジケーターのチェックアウトから日をまたぐと未清掃が反映 BY WSQ END
            // 2018/08/01 部屋清掃済みの場合清掃状態自動更新　by zy BEGIN
            spcd = roomStatus.RoomRef__r.ShopInfoRef__r.ShopCode__c;
            // 2018/08/01 部屋清掃済みの場合清掃状態自動更新　by zy END
            roomStatus.Result__c = CommConst.LEAD_ROOM_ST_CLEANED;
            updLst.add(roomStatus);
        }
        // 2018/08/01 部屋清掃済みの場合清掃状態自動更新　by zy BEGIN
        Set<String> completeStatus = new Set<String>();
       	try{	
       		Dom.XMLNode targetNode = CommXmlUtils.parseXmlDoc('CleanRoomConfig',spcd);
    		if (targetNode != null) {
    			//完了状態
	        	Dom.XmlNode completeNode =  targetNode.getChildElement('COMPLETESTATUS', null);
	        	if (completeNode != null) {
	        		String[] comStatlist = CommUtils.nullToBlank(completeNode.getText()).split(',');
	        		for (String s : comStatlist) if (!CommUtils.isBlank(s)) completeStatus.add(CommUtils.nullToBlank(s));
	        	}
    		}
    	}catch(exception e) {}
    	// 未設定完了状態→最後状態
    	if (completeStatus.isEmpty()) {
    		List<Schema.PicklistEntry> ple = RoomsStatus__c.CleanStatus__c.getDescribe().getPicklistValues();
    		completeStatus.add(ple[ple.size() - 1].getValue());
    	}
    	String lastStatus = new List<String>(completeStatus)[0];
		for (RoomsStatus__c rs : updLst) {
			if (!completeStatus.contains(rs.CleanStatus__c)) rs.CleanStatus__c = lastStatus;
		}
		// 2018/08/01 部屋清掃済みの場合清掃状態自動更新　by zy END
        update updLst;
        /*
        delete [select id from RoomsStatus__c
                Where Status__c = :CommConst.ROOM_ST_TYPE_CLS And Result__c = :CommConst.LEAD_ROOM_ST_UNCLEAN And RoomRef__c = :roomIdSet ];
        */
    }
    public class GroupRoomStatus{
        // map<部屋ID_予約インデックスID, list<同じ部屋連泊の予約>>
    	public Map<String,List<GroupInfo>> roomGroupsMap;
    	public set<Id> LeadIndexSubIdSet;
    	public set<Id> LeadIndexRefSet;
    	public set<Decimal> RoomGroupNoSet;
    	public GroupRoomStatus(){
    		LeadIndexRefSet = new set<Id>();
	    	LeadIndexSubIdSet = new set<Id>();
	    	RoomGroupNoSet = new set<Decimal>();
	    	roomGroupsMap = new Map<String,List<GroupInfo>>();
    	}
    	public void addLeads(Lead__c nw) {
    		LeadIndexRefSet.add(nw.LeadIndexRef__c);
    		LeadIndexSubIdSet.add(nw.LeadIndexSubId__c);
    		RoomGroupNoSet.add(nw.RoomGroupNo__c);
    	}
    	// 指定の予約の関連の連泊情報を取得する
    	public void queryRelLeads(Set<Id> roomIdSet){
    	    queryRelLeads(roomIdSet, null, null);
    	}
    	public void queryRelLeads(Set<Id> roomIdSet, Date startDt, Date endDt){
    	    
    	    list<Lead__c> relLeads = null;
    	    if (startDt == null ) {
                Date preDate = Date.today().addDays(-1);
                relLeads = [select Rroom__c, LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c,
                                            EntryTime__c,Departure__c,Field4__c,Field3__c
                                      from Lead__c 
                                      where LeadIndexRef__c = :LeadIndexRefSet
                                      And LeadIndexSubId__c = :LeadIndexSubIdSet
                                      And RoomGroupNo__c = :RoomGroupNoSet
                                      And Rroom__c = :roomIdSet
                                      And DAY_ONLY(convertTimezone(EntryTime__c)) >= :preDate
                                      And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 
                                      Order by LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c,EntryTime__c];
    	    } else {
                relLeads = [select Rroom__c, LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c,
                                            EntryTime__c,Departure__c,Field4__c,Field3__c
                                      from Lead__c 
                                      where Rroom__c = :roomIdSet
                                        And (DAY_ONLY(convertTimezone(EntryTime__c)) >= :startDt
                                                And 
                                            DAY_ONLY(convertTimezone(EntryTime__c)) <= :endDt)
                                        And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 
                                      Order by LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c,EntryTime__c];
    	    }

            //map<string,list<GroupInfo>> roomGroupsMap = new map<string, list<GroupInfo>());
            // 同じ部屋、同じグループ、連続の予約の場合、情報格納する
            for (lead__c nw : relLeads) {
	            String dtKey =  CommUtils.nullToBlank(nw.LeadIndexRef__c) 
	                + '_' + CommUtils.nullToBlank(nw.LeadIndexSubId__c)
	                + '_' + CommUtils.nullToBlank(nw.RoomGroupNo__c)
                    + '_' + CommUtils.nullToBlank(nw.Rroom__c);
                // 同じ部屋、連続の情報格納
                if (!roomGroupsMap.containsKey(dtKey)) roomGroupsMap.put(dtKey, new List<GroupInfo>());
                list<GroupInfo> gpLst = roomGroupsMap.get(dtKey);
                if (gpLst.isEmpty()) gpLst.add(new GroupInfo(nw));
                else {
                    GroupInfo lastInfo = gpLst[gpLst.size()-1];
                    // 連泊の場合
                    if (lastInfo.isContinueLead(nw)) {
                        lastInfo.addNextLead(nw);
                    } else {
                        gpLst.add(new GroupInfo(nw));
                    }
                }
            }
    	}
    	// 查询故障是否在预约时间范围内
    	// string:エラーある場合、エラーメッセージを返却する
    	public string checkRoomStatus(Lead__c nw , List<RoomsStatus__c> rs, string roomName) {
        	// 同じ予約ＩＮＤＥＸ、予約ＩＮＤＥＸＳＵＢ、グループＮＯの場合、同じ予約連泊情報を認識する
			String dtKey =	CommUtils.nullToBlank(nw.LeadIndexRef__c) 
					+ '_' +	CommUtils.nullToBlank(nw.LeadIndexSubId__c) 
					+ '_' +	CommUtils.nullToBlank(nw.RoomGroupNo__c)
					+ '_' + CommUtils.nullToBlank(nw.Rroom__c);
			if (!roomGroupsMap.containsKey(dtKey)) return '';
			if (rs == null || rs.isEmpty()) return '';
			List<GroupInfo> groupInfos = roomGroupsMap.get(dtKey);
			for (RoomsStatus__c status : rs) {
				for (GroupInfo groupInfo: groupInfos ) {
				    if(!groupInfo.processInfo(status)) {
                        return (Label.MSG_002_0376 + status.StatusBeginDate__c.format() + Label.MSG_002_0377 +'['+roomName+']'+ Label.MSG_002_0378);
				    }
				}
			}
			return '';
    	}
    }
    public class GroupInfo {

		public datetime beginTm;// 該当グループの最大
		public datetime endTm;
		public Date curDate;//既存予約の到着日情報を格納する
		public Id roomId;//部屋ID情報を格納する
		public GroupInfo (lead__c lead) {
		    // 到着日
		    curDate = lead.EntryTime__c.date();
		    Date depDate = lead.Departure__c.date();
		    // 開始日
			beginTm = CommUtils.convertDatetime(curDate,lead.Field4__c);
			// 日帰の場合、出発時刻をそのまま設定
			// 宿泊の場合、到着日の24時まで設定する
			if (curDate == depDate) endTm = CommUtils.convertDatetime(depDate,lead.Field3__c);
			else endTm = CommUtils.convertDatetime(curDate,RoomStatusManager.DEF_END_TIME);
			// 部屋ID設定する
			roomId = lead.rRoom__c;
		}
		// 該当予約情報は既存予約に対して、連泊するがどうかチェック
		public Boolean isContinueLead(lead__c lead) {
		    // 次の予約の到着日は該当予約の到着日と１日間差チェックする
		    return (curDate.daysBetween(lead.EntryTime__c.date()) == 1);
		}
		// 同じ部屋、連泊の場合、予約情報更新する
		public void addNextLead(Lead__c lead) {
            // 到着日
            curDate = lead.EntryTime__c.date();
            // 次の予約情報[到着日の２４時まで故障チェック（０泊の場合、該当Methdoに入れない]
            endTm = CommUtils.convertDatetime(curDate,RoomStatusManager.DEF_END_TIME);
		}
		/*
		* 房间状态和予約进行确认
		* isProcessDayFlag : 房间状态开始日和予約到着日相同情况下，进行连泊确认，否则正常check
		* true:故障影響なし、予約データ変更可能 false:故障データあり、処理失敗
		*/
		public boolean processInfo(RoomsStatus__c roomStatus) {
            // 故障データ管理時間
   			if (CommUtils.isBlank(roomStatus.BeginTime__c)) roomStatus.BeginTime__c = RoomStatusManager.DEF_START_TIME;
   			if (CommUtils.isBlank(roomStatus.OverTime__c)) roomStatus.OverTime__c = RoomStatusManager.DEF_END_TIME;
            Datetime badBeginTm = CommUtils.convertDatetime(roomStatus.StatusBeginDate__c,roomStatus.BeginTime__c);
            Datetime badEndTm = CommUtils.convertDatetime(roomStatus.StatusEndDate__c,roomStatus.OverTime__c);
   			return (endTm <= badBeginTm || beginTm >= badEndTm) ;
		}
	}
	// 2018/07/30 清掃状態リスト追加 by zy BEGIN
	/**
	* 未清掃の部屋リストを取得する
	**/
    public static Map<Id, List<RoomsStatus__c>> getCleanStatusLst (Date processDate,Set<String> roomSet,List<String> fieldSet) {
        Map<Id, List<RoomsStatus__c>> cleanStatusRoomMap = new Map<Id, List<RoomsStatus__c>>();
        String queryHd = CommSqlUtils.generateQueryString('RoomsStatus__c',fieldSet);
        String queryWhere = ' where Status__c = \'' + String.escapeSingleQuotes(CommConst.ROOM_ST_TYPE_CLS) + '\'';
        // 2019/06/14 未清掃保持のフラグtrue データ超大エラー修正 by zy BEGIN
        Set<String> cleanIds = new Set<String>();
        // 2019/06/14 未清掃保持のフラグtrue データ超大エラー修正 by zy END
        // 2018/8/28 ルームインジケーターのチェックアウトから日をまたぐと未清掃が反映 by cxw begin
        if (processDate != null) {
        	queryWhere += ' And StatusBeginDate__c <= ' + String.valueOf(processDate);
        	queryWhere += ' And StatusEndDate__c >= ' + String.valueOf(processDate);
        // 2019/06/14 未清掃保持のフラグtrue データ超大エラー修正 by zy BEGIN
        } 
        else {
            // グループ取得指定部屋清掃状態取得
            Map<String,List<RoomsStatus__c>> roomGroupMap = groupCleanStatusRoomMap(roomSet,null);
            // 取得部屋清掃状態Id指定
            for (List<RoomsStatus__c> roomStatuss :roomGroupMap.values()) {
                for (RoomsStatus__c rs : roomStatuss) {
                    cleanIds.add(rs.id);
                }
            }
            if (cleanIds.isEmpty()) return cleanStatusRoomMap;
            queryWhere += ' And id = :cleanIds';
        }
        // 2019/06/14 未清掃保持のフラグtrue データ超大エラー修正 by zy END
        // 2018/8/28 ルームインジケーターのチェックアウトから日をまたぐと未清掃が反映 by cxw END
        if (roomSet != null) {
        	queryWhere += ' And RoomRef__c =:roomSet';
        }
        String queryStr = queryHd + queryWhere;
        for (RoomsStatus__c roomSt : Database.query(queryStr)) {
    		if (!cleanStatusRoomMap.containsKey(roomSt.RoomRef__c)) cleanStatusRoomMap.put(roomSt.RoomRef__c, new List<RoomsStatus__c>());
    		// 未清掃以外のデータが存在する場合、新データを更新を行う、１件異常の未清掃データ存在すると、未清掃と認識する
    		if (roomSt.Result__c == CommConst.LEAD_ROOM_ST_UNCLEAN) {
        		List<RoomsStatus__c> rs = new List<RoomsStatus__c>{roomSt};
        		rs.addAll(cleanStatusRoomMap.get(roomSt.RoomRef__c));
        		cleanStatusRoomMap.put(roomSt.RoomRef__c,rs);
    		} else if (!CommUtils.isBlank(roomSt.CleanStatus__c)) cleanStatusRoomMap.get(roomSt.RoomRef__c).add(roomSt);
        }
        return cleanStatusRoomMap;
	}
	// 2018/07/30 清掃状態リスト追加 by zy END
	// 2018/8/28 ルームインジケーターのチェックアウトから日をまたぐと未清掃が反映 by cxw begin
	public Map<Id, String> getCleanStatusRooms(Set<Id> ids, Date processDate){
		Map<Id, String> cleanStatusRoomMap = new Map<Id, String>();
		String queryHd = ' select RoomRef__c roomid, Result__c result from RoomsStatus__c';
		String queryWhere = ' WHERE Status__c = \'' + String.escapeSingleQuotes(CommConst.ROOM_ST_TYPE_CLS) + '\'';
		// 2021/03/05 50001エラー修正 by zy BEGIN
        queryWhere += ' AND Result__c = \'' + String.escapeSingleQuotes(CommConst.LEAD_ROOM_ST_UNCLEAN) + '\'';
        // 2019/06/14 未清掃保持のフラグtrue データ超大エラー修正 by zy BEGIN
        if (processDate == null) processDate = system.today();
        // 二週間の清掃データ
        String begDateStr = DataFixManagerUtils.dateToYMDstr(processDate); //開始時間STR
        Integer begDateInt = CommUtils.nullToIntZero(begDateStr);//開始時間INT
        Date endDt = processDate.addDays(-CommConst.CLEAN_KEEP_BEFORE_DAYLEN);//終了時間
        String endDtStr = DataFixManagerUtils.dateToYMDstr(endDt);//終了時間
        Integer endDateInt = CommUtils.nullToIntZero(endDtStr);//終了時間INT
        // 部屋状態管理インデックス機能
        Boolean isFixedFlg = DataFixManagerUtils.getInstance().RoomsStatusFixed__c;
        Boolean isFixedFlg1 = DataFixManagerUtils.getInstance().RoomsStatusFixed1__c;
        Set<Id> queryRoomSet = new Set<Id>(ids);
        if (isFixedFlg1) {
            queryWhere += ' and StatusBeginDateIntKey__c <= ' + begDateInt;
            queryWhere += ' and StatusBeginDateIntKey__c >= ' + endDateInt;
            queryWhere += ' And StatusEndDateIntKey__c <= ' + begDateInt;
            queryWhere += ' And StatusEndDateIntKey__c >= ' + endDateInt;
        }
        else if(isFixedFlg){
            queryWhere += ' and StatusBeginDateKey__c <= \'' + begDateStr+ '\'';
            queryWhere += ' and StatusBeginDateKey__c >= \'' + endDtStr+ '\'';
            queryWhere += ' And StatusEndDateKey__c <= \'' + begDateStr+ '\'';
            queryWhere += ' And StatusEndDateKey__c >= \'' + endDtStr+ '\'';
        }
        else {
            queryWhere += ' and StatusBeginDate__c <= ' + String.valueOf(processDate);
            queryWhere += ' and StatusBeginDate__c >= ' + String.valueOf(endDt);
            queryWhere += ' And StatusEndDate__c <= ' + String.valueOf(processDate);
            queryWhere += ' And StatusEndDate__c >= ' + String.valueOf(endDt);
        }
        // 2019/06/14 未清掃保持のフラグtrue データ超大エラー修正 by zy END
		if(queryRoomSet != null && !queryRoomSet.isempty()) {
            queryWhere += ' AND RoomRef__c IN :queryRoomSet';
            for (RoomsStatus__c rs : [select id,RoomRef__c,result__c from RoomsStatus__c where Status__c = :CommConst.ROOM_ST_TYPE_CLS and StatusBeginDate__c = :processDate and RoomRef__c = :queryRoomSet]){
                // 当日の清掃済みデータ作成
                // 初期化
                if (!cleanStatusRoomMap.containsKey(rs.RoomRef__c) || 
                    // 該当データは未清掃データ含むする
                    cleanStatusRoomMap.get(rs.RoomRef__c) != CommConst.LEAD_ROOM_ST_UNCLEAN) {
                    cleanStatusRoomMap.put(rs.RoomRef__c, rs.result__c);
                } 
                // 当日の清掃済みの部屋を削除する
                queryRoomSet.remove(rs.RoomRef__c);
    		}
        }
        // 2021/03/05 50001エラー修正 by zy END
        String groupBy = ' Group By RoomRef__c,Result__c';
        String queryStr = queryHd + queryWhere + groupBy;
        AggregateResult[] groupedResults = Database.query(queryStr);
        for (AggregateResult avgRs : groupedResults) {
            Id roomId = (ID)(avgRs.get('roomid'));
            String status = CommUtils.nullToBlank(avgRs.get('result'));
            if (cleanStatusRoomMap.containsKey(roomId)) {
                // 未清掃以外のデータが存在する場合、新データを更新を行う、１件異常の未清掃データ存在すると、未清掃と認識する
                if (cleanStatusRoomMap.get(roomId) != CommConst.LEAD_ROOM_ST_UNCLEAN) cleanStatusRoomMap.put(roomId, status);
            } else {
                cleanStatusRoomMap.put(roomId, status);
            }
        }
		return cleanStatusRoomMap;
	}
	// 2018/8/28 ルームインジケーターのチェックアウトから日をまたぐと未清掃が反映 by cxw END
    // 2019/05/30 こちらをルームインジケータ上からも1日単位の作成、削除（削除だけでもほしい）by zy BEGIN
    // 故障部屋解除機能
    public static void updBadRoomStatus(Set<String> expRoomIdSet,Set<Date> excDates){
        // 2019/09/15 Security Check BY zyz BEGIN
        List<String> chkFieldsLst = new List<String>{'statusenddate__c','overtime__c','statusbegindate__c','begintime__c','result__c'};
        Map<String,Schema.SObjectField> mm = Schema.SObjectType.RoomsStatus__c.fields.getMap();
        if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
        	return ;
        }
        // 2019/09/15 Security Check BY zyz END
        // 変更故障部屋リスト
        List<RoomsStatus__c> updRoomLst = new List<RoomsStatus__c>();
        //日期解除房间区分
        //多日故障处理
        if (!expRoomIdSet.isEmpty()) {
            // 指定部屋の故障部屋取得
            for ( RoomsStatus__c rs : [select id,StatusEndDate__c,StatusBeginDate__c,name,RoomRef__c,Status__c,IsStockSyncTarget__c,Result__c,Describe__c,TypeOfRoomTypeId__c 
                                            // 2018/02/07 故障時刻登録　by zy BEGIN
                                            ,BeginTime__c,OverTime__c
                                            // 2018/02/07 故障時刻登録　by zy END
                                                    from RoomsStatus__c 
                                                    where RoomRef__c = :expRoomIdSet and StatusBeginDate__c <= :excDates and StatusEndDate__c >= :excDates and Result__c != :CommConst.ROOM_ST_TYPE_BED_FIN and Status__c = :CommConst.ROOM_ST_TYPE_BED]) {
                // 单日故障チェック
                Integer daysBetween = rs.StatusBeginDate__c.daysBetween(rs.StatusEndDate__c);
                if( daysBetween == 0 && expRoomIdSet.contains(rs.RoomRef__c)){
                    //判定日
                    Date curDt = rs.StatusBeginDate__c;
                    // 单日故障
                    if (excDates.contains(curDt)){
                        //将检索到的元数据都清扫完了
                        rs.Result__c = CommConst.ROOM_ST_TYPE_BED_FIN;
                        updRoomLst.add(rs);
                    }
                    continue;
                }
                // 多日故障チェック
                updRoomLst.addAll(createRoomStatus(rs,excDates,CommConst.ROOM_ST_TYPE_BED_FIN));
            }
        }
        // 性能优化 トリガー処理
        if (!updRoomLst.isEmpty()) upsert updRoomLst;
    }
    // 多日故障の指定解除日切断
    private static List<RoomsStatus__c> createRoomStatus(RoomsStatus__c rs,Set<Date> badDates,String bedStatus){
        // 故障名
        String statusName = rs.name;
        // 指定部屋
        String roomId = rs.RoomRef__c;
        // 変更後故障リスト
        List<RoomsStatus__c> roomSs = new List<RoomsStatus__c>();
        for (Date curDt : badDates) {
            // 変更故障不存在
            if (roomSs.isEMpty()) {
                // 指定日故障切断
                roomSs = splitRoomStatusByDate(rs,curDt);
            // 切断後
            } else {
                // 変更後全部故障リスト
                List<RoomsStatus__c> otherStatus = new List<RoomsStatus__c>();
                // 切断後リスト
                for (RoomsStatus__c roomSt : roomSs) {
                    otherStatus.addAll(splitRoomStatusByDate(roomSt,curDt));
                }
                roomSs = otherStatus;
            }
        }
        return roomSs;
    }
    // 切断機能
    private static List<RoomsStatus__c> splitRoomStatusByDate(RoomsStatus__c rs, Date curDt){
        // 変更リスト
        List<RoomsStatus__c> roomSs = new List<RoomsStatus__c>();
        // 指定日の故障開始日、故障終了日期間の場合
        if (rs.StatusBeginDate__c <= curDt && curDt <= rs.StatusEndDate__c){
            // 切断後前日
            Date lastEndDt = curDt.addDays(-1);
            // 切断後後日
            Date nextStartDt = curDt.addDays(1);
            // 故障開始日と切断日同じ
            if (rs.StatusBeginDate__c == curDt) {
                // 故障解除の場合
                if (nextStartDt >  rs.StatusEndDate__c) rs.Result__c = CommConst.ROOM_ST_TYPE_BED_FIN;
                // 故障開始日変更
                else {
                    rs.StatusBeginDate__c = nextStartDt;
                    // リセット開始時間
                    rs.BeginTime__c = RoomStatusManager.DEF_START_TIME;
                }
                roomSs.add(rs);
            // 故障終了日と切断日同じ
            } else if (curDt == rs.StatusEndDate__c) {
                // 故障解除の場合
                if (lastEndDt <  rs.StatusBeginDate__c) rs.Result__c = CommConst.ROOM_ST_TYPE_BED_FIN;
                // 故障開始日変更
                else {
                    rs.StatusEndDate__c = lastEndDt;
                    // リセット終了時間
                    rs.OverTime__c = RoomStatusManager.DEF_END_TIME;
                }
                roomSs.add(rs);
            // 切断日在故障時間中
            } else{
                // 切断新規故障
                RoomsStatus__c cloneStatus = rs.clone(false,false);
                // 元故障終了日変更
                rs.StatusEndDate__c = lastEndDt;
                rs.OverTime__c = RoomStatusManager.DEF_END_TIME;
                // 切断故障開始日変更
                cloneStatus.StatusBeginDate__c = nextStartDt;
                cloneStatus.BeginTime__c = RoomStatusManager.DEF_START_TIME;
                roomSs.add(rs);
                roomSs.add(cloneStatus);
            }
        }
        return roomSs;
    }
    // 2019/05/30 こちらをルームインジケータ上からも1日単位の作成、削除（削除だけでもほしい）by zy END
    // 2019/06/14 未清掃保持のフラグtrue データ超大エラー修正 by zy BEGIN
    // グループ取得指定部屋清掃状態取得
    public static Map<String,List<RoomsStatus__c>> groupCleanStatusRoomMap(Set<String> ids,List<String> cleans){
        Map<String,List<RoomsStatus__c>> cleanRoomStatus = new Map<String,List<RoomsStatus__c>>();
        String queryHd = ' select RoomRef__c roomid, Result__c result,CleanStatus__c clean,max(id) id  from RoomsStatus__c';
        String queryWhere = ' WHERE Status__c = \'' + String.escapeSingleQuotes(CommConst.ROOM_ST_TYPE_CLS) + '\'';
        // 2021/03/05 50001エラー修正 by zy BEGIN
        boolean hadCleanedDataFlg = false;
        if (cleans != null && !cleans.isEmpty()){
            Set<String> cleanStatusSet = new Set<String>(cleans);
            //　清掃済みチェック
            if (cleanStatusSet.contains(CommConst.LEAD_ROOM_ST_CLEANED)) hadCleanedDataFlg = true;
            //　未清掃チェック
            if (cleanStatusSet.contains(CommConst.LEAD_ROOM_ST_UNCLEAN)) queryWhere += ' AND Result__c = \'' + String.escapeSingleQuotes(CommConst.LEAD_ROOM_ST_UNCLEAN) + '\'';
        // 清掃状態未設定の場合
        }
        // TODO cleans = null 为部屋清扫状态管理用，暂时不控制数据溢出问题
        // 指定日なしの場合,期間限定８月内
        Date processDate = system.today();
        // String endDtStr = String.valueOf(processDate.addMonths(-8));
        Set<String> queryRoomSet = new Set<String>(ids);
        // 
        // 二週間の清掃データ
        String begDateStr = DataFixManagerUtils.dateToYMDstr(processDate); //開始時間STR
        Integer begDateInt = CommUtils.nullToIntZero(begDateStr);//開始時間INT
        Date endDt = processDate.addDays(-CommConst.CLEAN_KEEP_BEFORE_DAYLEN);//終了時間
        String endDtStr = DataFixManagerUtils.dateToYMDstr(endDt);//終了時間
        Integer endDateInt = CommUtils.nullToIntZero(endDtStr);//終了時間INT
        // 部屋状態管理インデックス機能
        Boolean isFixedFlg = DataFixManagerUtils.getInstance().RoomsStatusFixed__c;
        Boolean isFixedFlg1 = DataFixManagerUtils.getInstance().RoomsStatusFixed1__c;
        if (isFixedFlg1) {
            queryWhere += ' and StatusBeginDateIntKey__c <= ' + begDateInt;
            queryWhere += ' and StatusBeginDateIntKey__c >= ' + endDateInt;
            queryWhere += ' And StatusEndDateIntKey__c <= ' + begDateInt;
            queryWhere += ' And StatusEndDateIntKey__c >= ' + endDateInt;
        }
        else if(isFixedFlg){
            queryWhere += ' and StatusBeginDateKey__c <= \'' + begDateStr + '\'';
            queryWhere += ' and StatusBeginDateKey__c >= \'' + endDtStr + '\'';
            queryWhere += ' And StatusEndDateKey__c <= \'' + begDateStr + '\'';
            queryWhere += ' And StatusEndDateKey__c >= \'' + endDtStr + '\'';
        }
        else {
            queryWhere += ' and StatusBeginDate__c <= ' + String.valueOf(processDate);
            queryWhere += ' And StatusBeginDate__c >= ' + String.valueOf(endDt);
            queryWhere += ' And StatusEndDate__c <= ' + String.valueOf(processDate);
            queryWhere += ' And StatusEndDate__c >= ' + String.valueOf(endDt);
        }
        // 
        if(queryRoomSet != null && !queryRoomSet.isempty()) {
            queryWhere += ' AND RoomRef__c IN :queryRoomSet';
            if (hadCleanedDataFlg) {
                for (RoomsStatus__c rs : [select id,RoomRef__c,result__c,CleanStatus__c from RoomsStatus__c where Status__c = :CommConst.ROOM_ST_TYPE_CLS AND StatusBeginDate__c = :processDate and RoomRef__c = :queryRoomSet]){
                    // 当日の清掃済みデータ作成
                    String roomId = rs.RoomRef__c;
                    if (!cleanRoomStatus.containsKey(roomId)) cleanRoomStatus.put(roomId,new List<RoomsStatus__c>());
                    // 未清掃TOP１
                    if (rs.result__c == CommConst.LEAD_ROOM_ST_UNCLEAN && !cleanRoomStatus.get(roomId).isEmpty()) {
                        cleanRoomStatus.get(roomId).set(0,rs);
                    } else {
                        cleanRoomStatus.get(roomId).add(rs);
                    }
                    // 当日の清掃済みの部屋を削除する
                    queryRoomSet.remove(rs.RoomRef__c);
                }
            }
        }
        // 2021/03/05 50001エラー修正 by zy END
        String groupBy = ' Group By RoomRef__c,Result__c,CleanStatus__c';
        String orderBy = ' Order by Result__c, CleanStatus__c';
        AggregateResult[] groupedResults = Database.query(queryHd + queryWhere + groupBy + orderBy);
        for (AggregateResult avgRs : groupedResults) {
            Id roomId = (ID)(avgRs.get('roomid'));
            String status = CommUtils.nullToBlank(avgRs.get('result'));
            String clean = CommUtils.nullToBlank(avgRs.get('clean'));
            String rsId = CommUtils.nullToBlank(avgRs.get('id'));
            RoomsStatus__c rs = new RoomsStatus__c(RoomRef__c = roomId,Result__c = status , CleanStatus__c = clean,id = rsId);
            if (!cleanRoomStatus.containsKey(roomId)) cleanRoomStatus.put(roomId,new List<RoomsStatus__c>());
            cleanRoomStatus.get(roomId).add(rs);
        }
        return cleanRoomStatus;
    }
    // 2019/06/14 未清掃保持のフラグtrue データ超大エラー修正 by zy END
    // 2019/09/15 モアレリゾート様他複数施設（落合楼村上様など）より、稼働率レポートで故障部屋設定を加味してほしいという要望をいただいております。（夜間バッチで故障数集計） by zy BEGIN
    public static Map<String,Decimal> getBadRoomStatusCntByTypes(set<String> roomTypes,Date processDate){
        Map<String,Set<String>> typeBadMap = new Map<String,Set<String>>();
        Map<String,Decimal> badStatusMap = new Map<String,Decimal>();
        if (roomTypes != null && !roomTypes.isEmpty()) {
            String roomQuery = 'select id,RoomRef__r.TypeRoomRef__c,RoomRef__c from RoomsStatus__c where Status__c = \'' + String.escapeSingleQuotes(CommConst.ROOM_ST_TYPE_BED) + '\' And Result__c != \'' + String.escapeSingleQuotes(CommConst.ROOM_ST_TYPE_BED_FIN) + '\' and RoomRef__r.TypeRoomRef__c in : roomTypes';
            String queryWhere = '';
            if (processDate != null) {
                queryWhere += ' and StatusBeginDate__c <= ' + String.valueOf(processDate);
                queryWhere += ' and StatusEndDate__c >= ' + String.valueOf(processDate);
            }
            for (RoomsStatus__c rs : Database.query(roomQuery + queryWhere)) {
                if (!typeBadMap.containsKey(rs.RoomRef__r.TypeRoomRef__c)) typeBadMap.put(rs.RoomRef__r.TypeRoomRef__c,new Set<String>());
                typeBadMap.get(rs.RoomRef__r.TypeRoomRef__c).add(rs.RoomRef__c);
            }
        }
        for (String typeId : roomTypes) {
            Integer badInt = typeBadMap.containsKey(typeId) ? typeBadMap.get(typeId).size() : 0;
            badStatusMap.put(typeId,CommUtils.nullToZero(badInt));
        }
        return badStatusMap;
    }
    // 2019/09/15 モアレリゾート様他複数施設（落合楼村上様など）より、稼働率レポートで故障部屋設定を加味してほしいという要望をいただいております。（夜間バッチで故障数集計） by zy END
    // 2019/11/15 ルームインジケータの表示について、清掃済だけでなくインスペ完の状況を追加したいです。 by zy BEGIN
    /**
    * 部屋ステータスは清掃済に管理する
    **/
    public void upClearnStatus(Date procDate, Set<String> roomIdSet,String status) {
        // 2018/08/01 部屋清掃済みの場合清掃状態自動更新　by zy BEGIN
        String spcd = '';
        // 2018/08/01 部屋清掃済みの場合清掃状態自動更新　by zy END
        List<RoomsStatus__c> updLst = new List<RoomsStatus__c>();
        // 2018/8/28 ルームインジケーターのチェックアウトから日をまたぐと未清掃が反映 BY WSQ BEGIN
        // 日付を未指定の場合、指定部屋のすべて未清掃データは自動清掃済みになる
        String unCleanFlg = CommConst.LEAD_ROOM_ST_UNCLEAN;//未清掃保持フラグ
        String cleanedFlg = CommConst.ROOM_ST_TYPE_CLS;//清掃
        String queryStr = 'select id, Result__c,CleanStatus__c,RoomRef__r.ShopInfoRef__r.ShopCode__c'+
                            ' from RoomsStatus__c'+
                            ' Where Status__c = :cleanedFlg And Result__c = :unCleanFlg And RoomRef__c = :roomIdSet';
        if (procDate != null) {
            queryStr += ' And StatusBeginDate__c <= :procDate And StatusEndDate__c >= :procDate';
        }
        for (RoomsStatus__c roomStatus : Database.query(queryStr)) {
        // 2018/8/28 ルームインジケーターのチェックアウトから日をまたぐと未清掃が反映 BY WSQ END
            // 2018/08/01 部屋清掃済みの場合清掃状態自動更新　by zy BEGIN
            spcd = roomStatus.RoomRef__r.ShopInfoRef__r.ShopCode__c;
            // 2018/08/01 部屋清掃済みの場合清掃状態自動更新　by zy END
            roomStatus.CleanStatus__c = status;
            updLst.add(roomStatus);
        }
        // 2018/08/01 部屋清掃済みの場合清掃状態自動更新　by zy BEGIN
        Set<String> completeStatus = new Set<String>();
        try{    
            Dom.XMLNode targetNode = CommXmlUtils.parseXmlDoc('CleanRoomConfig',spcd);
            if (targetNode != null) {
                //完了状態
                Dom.XmlNode completeNode =  targetNode.getChildElement('COMPLETESTATUS', null);
                if (completeNode != null) {
                    String[] comStatlist = CommUtils.nullToBlank(completeNode.getText()).split(',');
                    for (String s : comStatlist) if (!CommUtils.isBlank(s)) completeStatus.add(CommUtils.nullToBlank(s));
                }
            }
        }catch(exception e) {}
        // 未設定完了状態→最後状態
        if (completeStatus.isEmpty()) {
            List<Schema.PicklistEntry> ple = RoomsStatus__c.CleanStatus__c.getDescribe().getPicklistValues();
            completeStatus.add(ple[ple.size() - 1].getValue());
        }
        String lastStatus = new List<String>(completeStatus)[0];
        for (RoomsStatus__c rs : updLst) {
            if (completeStatus.contains(rs.CleanStatus__c)) 
                rs.Result__c = CommConst.LEAD_ROOM_ST_CLEANED;
        }
        // 2018/08/01 部屋清掃済みの場合清掃状態自動更新　by zy END
        update updLst;
    }
    public static Map<String,List<RoomsStatus__c>> cleanDetailStatusRoomMap(Set<Id> ids,Date processDate){
        Map<String,List<RoomsStatus__c>> cleanRoomStatus = new Map<String,List<RoomsStatus__c>>();
        List<String> statusLst = new List<String>{String.escapeSingleQuotes(CommConst.LEAD_ROOM_ST_UNCLEAN),String.escapeSingleQuotes(CommConst.LEAD_ROOM_ST_CLEANED)};
        if (processDate != null) {
            String queryHd = ' select RoomRef__c, Result__c,CleanStatus__c,CreatedDate from RoomsStatus__c';
            String queryWhere = ' WHERE Status__c = \'' + String.escapeSingleQuotes(CommConst.ROOM_ST_TYPE_CLS) + '\'';
            if(ids != null && !ids.isempty()) queryWhere += ' AND RoomRef__c IN :ids';
            queryWhere += ' AND Result__c = :statusLst '; // AND CleanStatus__c != null
            if (processDate != null) queryWhere += ' And StatusBeginDate__c <= :processDate And StatusEndDate__c >= :processDate';
            String queryOrderBy = ' order by Result__c,CleanStatus__c,LastModifiedDate';
            String queryStr = queryHd + queryWhere + queryOrderBy;
            for (RoomsStatus__c rs : Database.query(queryStr)) {
                if (!cleanRoomStatus.containsKey(rs.RoomRef__c)) cleanRoomStatus.put(rs.RoomRef__c,new List<RoomsStatus__c>());
                cleanRoomStatus.get(rs.RoomRef__c).add(rs);
            }
        } else { 
            Set<String> roomSet = new Set<String>();
            if (ids != null) {
                for (String id : ids) roomSet.add(id);
            }
            cleanRoomStatus = groupCleanStatusRoomMap(roomSet,statusLst);
        }
        return cleanRoomStatus;
    }
    /*
    public static Map<String,List<RoomsStatus__c>> groupCleanStatusRoomMap(Set<Id> ids,List<String> cleans){
        Map<String,List<RoomsStatus__c>> cleanRoomStatus = new Map<String,List<RoomsStatus__c>>();
        String queryHd = ' select RoomRef__c roomid, Result__c result,CleanStatus__c clean,id id  from RoomsStatus__c';
        String queryWhere = ' WHERE Status__c = \'' + String.escapeSingleQuotes(CommConst.ROOM_ST_TYPE_CLS) + '\'';
        if (cleans != null && !cleans.isEmpty())
            queryWhere += ' AND Result__c in :cleans';
        if(ids != null && !ids.isempty()) queryWhere += ' AND RoomRef__c IN :ids';
        String groupBy = ' Group By RoomRef__c,Result__c,CleanStatus__c,id';
        String orderBy = ' Order by Result__c, CleanStatus__c';
        AggregateResult[] groupedResults = Database.query(queryHd + queryWhere + groupBy + orderBy);
        for (AggregateResult avgRs : groupedResults) {
            Id roomId = (ID)(avgRs.get('roomid'));
            String status = CommUtils.nullToBlank(avgRs.get('result'));
            String clean = CommUtils.nullToBlank(avgRs.get('clean'));
            // if (status == CommConst.LEAD_ROOM_ST_UNCLEAN && CommUtils.isBlank(clean)) continue;
            String rsId = CommUtils.nullToBlank(avgRs.get('id'));
            RoomsStatus__c rs = new RoomsStatus__c(RoomRef__c = roomId,Result__c = status , CleanStatus__c = clean,id = rsId);
            if (!cleanRoomStatus.containsKey(roomId)) cleanRoomStatus.put(roomId,new List<RoomsStatus__c>());
            cleanRoomStatus.get(roomId).add(rs);
        }
        return cleanRoomStatus;
    }*/
    // 2019/11/15 ルームインジケータの表示について、清掃済だけでなくインスペ完の状況を追加したいです。 by zy END
}