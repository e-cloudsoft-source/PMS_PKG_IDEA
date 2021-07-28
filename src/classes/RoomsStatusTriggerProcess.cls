/*********************************************
* 部屋状態管理の関連トリガー処理を行う
* 2016/11/22 在庫連携データ自動作成機能
* 2017/09/18 長い故障期間登録されるの改善対応
**/
public with sharing class RoomsStatusTriggerProcess {
    // 画面から入金の開始日と終了日と時刻の整合性チェックする
	public void roomDateTimeCheck(RoomsStatus__c[] newList, RoomsStatus__c[] oldList, CommConst.TriggerMethod action) {
		// 时间段相反check
		for (integer i = 0 ; i < newList.size() ; i++) {
			RoomsStatus__c rs = newList[i];
			// 2019/10/09 部屋状態管理インデックス機能対応 WSQ BEGIN
			if (rs.StatusBeginDate__c == null) rs.StatusBeginDateKey__c = null;
			else rs.StatusBeginDateKey__c = DataFixManagerUtils.dateToYMDstr(rs.StatusBeginDate__c);
			if (rs.StatusEndDate__c == null) rs.StatusEndDateKey__c = null;
			else rs.StatusEndDateKey__c = DataFixManagerUtils.dateToYMDstr(rs.StatusEndDate__c);
			// 2019/10/09 部屋状態管理インデックス機能対応 WSQ END
			// 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
			if (rs.StatusBeginDate__c == null) rs.StatusBeginDateIntKey__c = null;
			else rs.StatusBeginDateIntKey__c = CommUtils.nullToIntZero(DataFixManagerUtils.dateToYMDstr(rs.StatusBeginDate__c));
			if (rs.StatusEndDate__c == null) rs.StatusEndDateIntKey__c = null;
			else rs.StatusEndDateIntKey__c = CommUtils.nullToIntZero(DataFixManagerUtils.dateToYMDstr(rs.StatusEndDate__c));
			// 2020/08/30 部屋状態管理インデックス機能対応 WGCH END
			// 新規故障部屋情報は
			if (isTargetCheck(rs)) {
			    String bt = CommUtils.isBlank(rs.BeginTime__c) ? RoomStatusManager.DEF_START_TIME : rs.BeginTime__c;//00:00
			    String et = CommUtils.isBlank(rs.OverTime__c) ? RoomStatusManager.DEF_END_TIME : rs.OverTime__c;//24:00
                // 期間チェックを行う
				Datetime beginTime = CommUtils.convertDatetime(rs.StatusBeginDate__c,bt);
				Datetime endTime = CommUtils.convertDatetime(rs.StatusEndDate__c,et);
				if (beginTime >= endTime) rs.addError(Label.MSG_012_0466_01);
			}
		}
	}
	// 故障データ登録の場合、関連チェックを行う
	// 故障データの期間に予約情報存在するがどうかチェックを行う
	public void roomDatetimeLeadChk(RoomsStatus__c[] newList, RoomsStatus__c[] oldList, CommConst.TriggerMethod action){
		Integer maxLen = newList != null ? newList.size() : oldList.size();
		//list<StockHisPlus> chkStockLst = new list<StockHisPlus>();
		set<id> targetRoomIdSet = new set<id>();
		set<integer> targetIdxSet = new set<Integer>();
		//set<id> targetSelfIdSet = new set<id>();
		Date startDt = Date.today();
		Date endDt = startDt;
		// map<部屋ID,set<故障日付>>
	    //set<id> roomIdSet = badRoomStatusMap.keyset();
		list<RoomsStatus__c> targetRoomStatus = new list<RoomsStatus__c>();
		// 新規故障部屋を新規 || 故障部屋情報を回復する場合
		if (action == CommConst.TriggerMethod.IsInsert || action == CommConst.TriggerMethod.IsUnDelete) {
			for (Integer i = 0; i < maxLen; i++) {
				RoomsStatus__c rstatus = newList[i];
				if (!rstatus.IsStockSyncTarget__c) continue;
				// 部屋ステータスは故障　かつ　該当部屋の処理結果は　修理済以外　の場合、在庫調整は-1
				if (isTargetCheck(rstatus)) {
					if (startDt > rstatus.StatusBeginDate__c) startDt = rstatus.StatusBeginDate__c;
					if (endDt < rstatus.StatusEndDate__c) endDt = rstatus.StatusEndDate__c;
					targetRoomStatus.add(rstatus);
					targetRoomIdSet.add(rstatus.RoomRef__c);
					targetIdxSet.add(i);
				}
			}
		}
		// 故障部屋の情報を変更する場合
		else if (action == CommConst.TriggerMethod.IsUpdate) {
			// 故障部屋を変更する場合
			for (Integer i = 0; i < maxLen; i++) {
				RoomsStatus__c nw = newList[i];
				RoomsStatus__c od = oldList[i];
				if (!nw.IsStockSyncTarget__c) continue;
				// 期間　または　ステータスを変更される場合
				// 部屋変更 || 日付を変更される場合 || ステータス
				// 2017/05/10 部屋状態管理の編集の場合、「部屋」を変更できる対応 BEGIN
				//if (nw.Status__c != CommConst.ROOM_ST_TYPE_BED && od.Status__c != CommConst.ROOM_ST_TYPE_BED) continue;
				if (nw.RoomRef__c == od.RoomRef__c && (nw.Status__c != CommConst.ROOM_ST_TYPE_BED && od.Status__c != CommConst.ROOM_ST_TYPE_BED)) continue;
				// 2017/05/10 部屋状態管理の編集の場合、「部屋」を変更できる対応 END
				// 変更なし場合、処理対象外
				if (nw.Status__c == od.Status__c &&
					nw.Result__c == od.Result__c &&
					// 2017/05/10 部屋状態管理の編集の場合、「部屋」を変更できる対応 BEGIN
					nw.RoomRef__c == od.RoomRef__c &&
					// 2017/05/10 部屋状態管理の編集の場合、「部屋」を変更できる対応 END
					nw.BeginTime__c == od.BeginTime__c &&
					nw.OverTime__c == od.OverTime__c &&
					nw.StatusBeginDate__c == od.StatusBeginDate__c &&
					nw.StatusEndDate__c == od.StatusEndDate__c) continue;
					
                // 部屋ステータスは故障　かつ　該当部屋の処理結果は　修理済以外　の場合、在庫調整は-1
                if (isTargetCheck(nw)) {
                    if (startDt > nw.StatusBeginDate__c) startDt = nw.StatusBeginDate__c;
                    if (endDt < nw.StatusEndDate__c) endDt = nw.StatusEndDate__c;
                    targetRoomStatus.add(nw);
                    targetRoomIdSet.add(nw.RoomRef__c);
                    targetIdxSet.add(i);
                }
			}
		}
        if (targetRoomIdSet.isEmpty()) return;
		// 指定期間の有効な予約情報が存在すると、エラーになる
		// 指定部屋と指定日付により、有効な予約情報を検索する
    	//　連泊取得する
    	RoomStatusManager.GroupRoomStatus groupStatus = new RoomStatusManager.GroupRoomStatus();
    	groupStatus.queryRelLeads(targetRoomIdSet,startDt,endDt);
        list<List<RoomStatusManager.GroupInfo>> groupLists = groupStatus.roomGroupsMap.values();
        map<id, list<RoomStatusManager.GroupInfo>> roomGroupMap = new map<id, list<RoomStatusManager.GroupInfo>>();
        for (List<RoomStatusManager.GroupInfo> gpLst : groupLists) {
            for (RoomStatusManager.GroupInfo gp : gpLst) {
                if (!roomGroupMap.containsKey(gp.roomId)) roomGroupMap.put(gp.roomId, new list<RoomStatusManager.GroupInfo>());
                roomGroupMap.get(gp.roomId).add(gp);
            }
        }
        for (Integer i = 0; i < maxLen; i++) {
            if (!targetIdxSet.contains(i)) continue;
            RoomsStatus__c nw = newList[i];
            Id roomId = nw.RoomRef__c;
            if (roomGroupMap.containsKey(roomId)) {
                List<RoomStatusManager.GroupInfo> gpLst = roomGroupMap.get(roomId);
                for (RoomStatusManager.GroupInfo gp : gpLst) {
                    // 故障関連の予約情報が存在する場合
                    if(!gp.processInfo(nw)) {
                        nw.addError(Label.MSG_012_0466);
                    }
                }
            }
        }
	}
	// 新規、変更、削除、UNDELETE
	public void stockChangeSyncToDb(RoomsStatus__c[] newList, RoomsStatus__c[] oldList, CommConst.TriggerMethod action){
		Integer maxLen = newList != null ? newList.size() : oldList.size();
		list<StockHisPlus> chkStockLst = new list<StockHisPlus>();
		list<StockChangeHisotry__c> insStockLst = new list<StockChangeHisotry__c>();
		//list<StatusPlus> preStatusLst = new list<StatusPlus>();
		set<id> targetRoomIdSet = new set<id>();
		set<id> targetSelfIdSet = new set<id>();
		
		// 新規故障部屋を新規 || 故障部屋情報を回復する場合
		if (action == CommConst.TriggerMethod.IsInsert || action == CommConst.TriggerMethod.IsUnDelete) {
			for (Integer i = 0; i < maxLen; i++) {
				RoomsStatus__c rstatus = newList[i];
				if (!rstatus.IsStockSyncTarget__c) continue;
				// 部屋ステータスは故障　かつ　該当部屋の処理結果は　修理済以外　の場合、在庫調整は-1
				if (isTargetCheck(rstatus)) {
					targetRoomIdset.add(rstatus.RoomRef__c);
					targetSelfIdSet.add(rstatus.id);
					// 指定期間の該当部屋の部屋タイプの在庫-1を作成する
					chkStockLst.addAll(getNewStockChangeInfo(rstatus, -1));
				}
				// 既に該当部屋は故障状態のデータが存在すると、新規在庫リスト情報を発行しない制御が必要
			}
			
		}
		// 故障部屋の情報を変更する場合
		else if (action == CommConst.TriggerMethod.IsUpdate) {
			// 故障部屋を変更する場合
			for (Integer i = 0; i < maxLen; i++) {
				RoomsStatus__c nw = newList[i];
				RoomsStatus__c od = oldList[i];
				if (!nw.IsStockSyncTarget__c) continue;
				// 期間　または　ステータスを変更される場合
				// 部屋変更 || 日付を変更される場合 || ステータス
				// 2017/05/10 部屋状態管理の編集の場合、「部屋」を変更できる対応 BEGIN
				//if (nw.Status__c != CommConst.ROOM_ST_TYPE_BED && od.Status__c != CommConst.ROOM_ST_TYPE_BED) continue;
				if (nw.RoomRef__c == od.RoomRef__c && (nw.Status__c != CommConst.ROOM_ST_TYPE_BED && od.Status__c != CommConst.ROOM_ST_TYPE_BED)) continue;
				// 2017/05/10 部屋状態管理の編集の場合、「部屋」を変更できる対応 END
				// 変更なし場合、処理対象外
				if (nw.Status__c == od.Status__c &&
					nw.Result__c == od.Result__c &&
					// 2017/05/10 部屋状態管理の編集の場合、「部屋」を変更できる対応 BEGIN
					nw.RoomRef__c == od.RoomRef__c &&
					// 2017/05/10 部屋状態管理の編集の場合、「部屋」を変更できる対応 END
					nw.StatusBeginDate__c == od.StatusBeginDate__c &&
					nw.StatusEndDate__c == od.StatusEndDate__c) continue;
				// 変更あり場合、変更内容により、在庫変更リストを作成する
				//List<StockChangeHisotry__c> oldStockList = null;
				// ステータス変更あり、なし場合
				// 新規間情報を取得する、旧期間情報も取得する、MAPPINGして、毎日のステータス変更チェックを行う
				set<Date> newStatusSet = new set<Date>();
				set<Date> oldStatusSet = new set<Date>();
				list<Date> newDateRange = getBetweenDates(nw, true);
				list<Date> oldDateRange = getBetweenDates(od, true);
				//for (Date dt : newDateRange) newStatusSet.put(dt, nw);
				//for (Date dt : oldDateRange) oldStatusMap.put(dt, od);
				newStatusSet.addAll(newDateRange);
				oldStatusSet.addAll(oldDateRange);
				
				for (Date dt : newDateRange) {
					// 新・旧両方とも存在する場合
					if (oldStatusSet.contains(dt)) {
						StockHisPlus rs = getChangeStockInfo(nw, od, dt);
						// 2017/05/10 部屋状態管理の編集の場合、「部屋」を変更できる対応 BEGIN
						// 部屋変更の場合、変更先の部屋の在庫は-1処理を行う
						if (nw.RoomRef__c != od.RoomRef__c) rs = getNewStockChangeInfo(nw,dt,-1);
						// 2017/05/10 部屋状態管理の編集の場合、「部屋」を変更できる対応 END
						if (rs != null) chkStockLst.add(rs);
						// 2017/05/10 部屋状態管理の編集の場合、「部屋」を変更できる対応 BEGIN
						//oldStatusSet.remove(dt);
						if (nw.RoomRef__c == od.RoomRef__c) oldStatusSet.remove(dt);
						// 2017/05/10 部屋状態管理の編集の場合、「部屋」を変更できる対応 END
						targetRoomIdset.add(nw.RoomRef__c);
						targetSelfIdSet.add(nw.id);
					} else {
						// 変更後の日付は旧データに非存在の場合、新規データとして、処理を行う
						StockHisPlus rs = getNewStockChangeInfo(nw,dt,-1);
						if (rs != null) chkStockLst.add(rs);
						targetRoomIdset.add(nw.RoomRef__c);
						targetSelfIdSet.add(nw.id);
					}
				}
				// 旧データは残り場合、該当データは削除処理と処理を行う
				for (Date dt : oldStatusSet) {
					StockHisPlus rs = getNewStockChangeInfo(od,dt,1);
					if (rs != null) chkStockLst.add(rs);
					targetRoomIdset.add(od.RoomRef__c);
					targetSelfIdSet.add(od.id);
				}
			}
		}
		// 故障部屋情報を削除する場合
		else if (action == CommConst.TriggerMethod.IsDelete) {
			// 2020.09.17 削除のデータは管理日は過去日付の場合、連携対象外になる WSQ BEGIN
			Date nowDt = Date.today();
			// 2020.09.17 削除のデータは管理日は過去日付の場合、連携対象外になる WSQ EDN
			// 削除の場合
			for (Integer i = 0; i < maxLen; i++) {
				RoomsStatus__c rstatus = oldList[i];
				// 2020.09.17 削除のデータは管理日は過去日付の場合、連携対象外になる WSQ BEGIN
				if (rstatus.StatusEndDate__c < nowDt) continue;
				// 2020.09.17 削除のデータは管理日は過去日付の場合、連携対象外になる WSQ END
				if (!rstatus.IsStockSyncTarget__c) continue;
				// 部屋ステータスは故障　かつ　該当部屋の処理結果は　修理済以外　の場合、在庫調整は+1
				if (isTargetCheck(rstatus)) {
					// 在庫+1
					chkStockLst.addAll(getNewStockChangeInfo(rstatus, 1));
					// 注意、該当期間に同じ部屋は故障部屋情報はまだ存在する・しないチェックする、同じ部屋は重複
					targetRoomIdset.add(rstatus.RoomRef__c);
					targetSelfIdSet.add(rstatus.id);
				}
			}
		}
//System.debug(loggingLevel.info, 'targetSelfIdSet:'+targetSelfIdSet);
//System.debug(loggingLevel.info, 'targetRoomIdset:'+targetRoomIdset);
//System.debug(loggingLevel.info, 'chkStockLst:'+chkStockLst);
		// 2017/03/30 故障部屋同じ部屋、同じ故障日、同じ在庫増えるの場合、重複データとして、FILTER処理を行う BEGIN
		List<StockHisPlus> chkTriggerDupLst = new List<StockHisPlus>();
		set<string> dupFilterSet = new set<string>();
		for (StockHisPlus inf : chkStockLst) {
			// 同じ部屋、同じ在庫処理方式（+1/-1)、同じ日付の場合、重複対象は外す
			String key = inf.roomId + '_' + inf.s.StockChangeDate__c + (inf.s.StockChangeCnt__c > 0 ? '_1' : '_0');
			if (dupFilterSet.contains(key)) continue;
			dupFilterSet.add(key);
			chkTriggerDupLst.add(inf);
		}
		chkStockLst = chkTriggerDupLst;
		// 2017/03/30 故障部屋同じ部屋、同じ故障日、同じ在庫増えるの場合、重複データとして、FILTER処理を行う END
		// 今日以後の故障部屋情報を取得する[在庫連携対象データが必要]
		List<RoomsStatus__c> existBadRoomStatus = [select id, RoomRef__c, StatusBeginDate__c, StatusEndDate__c from RoomsStatus__c 
				where IsStockSyncTarget__c = true 
					And Id not in :targetSelfIdSet 
					And RoomRef__c in :targetRoomIdset
					And Status__c = :CommConst.ROOM_ST_TYPE_BED 
					And Result__c != :CommConst.ROOM_ST_TYPE_BED_FIN
					And StatusEndDate__c >= TODAY];
		map<Id, list<RoomsStatus__c>> existBadInfoMap = new map<id, list<RoomsStatus__c>>();
		for (RoomsStatus__c status : existBadRoomStatus) {
			Id roomid = status.RoomRef__c;
			if (!existBadInfoMap.containsKey(roomid)) existBadInfoMap.put(roomid, new list<RoomsStatus__c>());
			existBadInfoMap.get(roomid).add(status);
		}

		// 指定期間の有効な予約情報が存在すると、エラーになる
		// 指定部屋と指定日付により、有効な予約情報を検索する
		set<id> roomIdSet = new set<id>();
		set<date> targetDateSet = new set<date>();
		// 2017/09/18 長い故障期間登録されるの改善対応 BEGIN
		Date startDt = null;
		Date endDt = null;
		// 2017/09/18 長い故障期間登録されるの改善対応 END
		//list<StockHisPlus> chkStockLst2 = new list<StockHisPlus>();
		// 登録対象データを処理する
		for (StockHisPlus inf : chkStockLst) {
			Boolean isTargetFlg = true;
			if (existBadInfoMap.containsKey(inf.roomId)) {
				for (RoomsStatus__c status : existBadInfoMap.get(inf.roomId)) {
					if (status.StatusBeginDate__c <= inf.s.StockChangeDate__c && status.StatusEndDate__c >= inf.s.StockChangeDate__c) {
						isTargetFlg = false;
						break;
					}
				}
			}
			if (isTargetFlg) {
				roomIdSet.add(inf.roomId);
				targetDateSet.add(inf.s.StockChangeDate__c);
				inf.isTarget = true;
                // 2017/09/18 長い故障期間登録されるの改善対応 BEGIN
                if (startDt == null ) startDt = inf.s.StockChangeDate__c;
                else if (startDt > inf.s.StockChangeDate__c) startDt = inf.s.StockChangeDate__c;
                if (endDt == null ) endDt = inf.s.StockChangeDate__c;
                else if (endDt < inf.s.StockChangeDate__c) endDt = inf.s.StockChangeDate__c;
                // 2017/09/18 長い故障期間登録されるの改善対応 END
			}
		}
		if (!roomIdSet.isEmpty()) {
			// 指定期間の有効な予約情報が存在すると、エラーになる
			// 指定部屋と指定日付により、有効な予約情報を検索する
            // 2017/09/18 長い故障期間登録されるの改善対応 BEGIN
            list<lead__c> existleads = null;
            // 条件に多い条件をいれると、エラーが発生可能性ありますので、200値をチェック、対応する
            if (targetDateSet.size() > 200) {
                existleads = [select id,Rroom__c,EntryTime__c from lead__c 
	                            where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
	                            And (DAY_ONLY(convertTimezone(EntryTime__c)) >= :startDt
	                                 And 
	                                 DAY_ONLY(convertTimezone(EntryTime__c)) <= :endDt)
	                            And Rroom__c in :roomIdSet];
            } else {
                existleads = [select id,Rroom__c,EntryTime__c from lead__c 
                                where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
                                And DAY_ONLY(convertTimezone(EntryTime__c)) = :targetDateSet
                                And Rroom__c in :roomIdSet];
            }
            // 2017/09/18 長い故障期間登録されるの改善対応 END
            map<Id,set<date>> roomRelDateMap = new map<Id, set<date>>();
            for (lead__c lead : existleads) {
                // 2017/09/18 長い故障期間登録されるの改善対応 BEGIN
            	if (!targetDateSet.contains(lead.EntryTime__c.date())) continue;
            	// 2017/09/18 長い故障期間登録されるの改善対応 END
            	Id roomId = lead.Rroom__c;
            	if (!roomRelDateMap.containskey(roomId)) roomRelDateMap.put(roomid, new set<date>());
            	roomRelDateMap.get(roomid).add(lead.EntryTime__c.date());
            }
			//insert insStockLst;
			for (StockHisPlus inf : chkStockLst) {
				if (!inf.isTarget) continue;
				Id roomId = inf.roomId;
				// 該当部屋に対して、有効予約情報が存在する場合
				if (roomRelDateMap.containsKey(roomId)) {
					//set<date> chkDtSet = roomRelDateMap.get(roomId);　
					set<Date> chkDtSet = roomRelDateMap.get(roomId);
					// 2018/03/22 故障部屋時刻機能追加　by　WSQ BEGIN
					// [inf.s.StockChangeCnt__c < 0]削除原因：故障データが有効な予約情報が存在する場合、在庫調整を行わない
					//if (chkDtSet.contains(inf.s.StockChangeDate__c) && inf.s.StockChangeCnt__c < 0) {
					// 該当日付に有効の予約情報が存在する場合、在庫変更調整対象外になる
					if (chkDtSet.contains(inf.s.StockChangeDate__c)) {
					// 2018/03/22 故障部屋時刻機能追加　by　WSQ BEGIN
						//throw new CommException('部屋に既にご予約を割り当てるため、故障情報を登録できません。');
						// 2018/03/22 故障部屋時刻機能追加　by　zy BEGIN
						//throw new CommException(Label.MSG_012_0466);
						// 該当日付は予約情報が既に存在する場合、該当在庫調整データを作成しない
						continue;
						// 2018/03/22 故障部屋時刻機能追加　by　zy BEGIN
					}
				}
				insStockLst.add(inf.s);
			}
			if ((insStockLst.size() + Limits.getDMLRows()) > Limits.getLimitDMLRows()) throw new CommException(Label.MSG_9104);
			if (!insStockLst.isEmpty()) insert insStockLst;
		}
	}
	// 在庫連携対象するがどうかチェック
	private boolean isTargetCheck(RoomsStatus__c rstatus) {
		return (rstatus.Status__c == CommConst.ROOM_ST_TYPE_BED && rstatus.Result__c != CommConst.ROOM_ST_TYPE_BED_FIN);
	}
	/*
	private string getRoomStatusKey(StockChangeHisotry__c s) {
		// 部屋タイプID_日付，在庫情報
		return (s.TypeOfRoomRef__c + '_' + s.StockChangeDate__c.format());
	}*/
	// 変更前の変更後の故障部屋情報チェックを行う
	private StockHisPlus getChangeStockInfo (RoomsStatus__c nw, RoomsStatus__c od, Date chkDate) {
		// NEW側の日付データは旧に非存在の場合、新規と認識する
		// NEW側の日付データは非存在、旧存在の場合、故障情報を削除と認識する　
		// NEW/OLD同じ日付存在する場合、ステータスと処理結果設定をチェックする
		// STATUSを変更される場合、
		// 日付は一致、ステータスと結果をチェックする
		if (nw.Status__c != od.Status__c) {
			// 新規故障部屋情報は
			if (isTargetCheck(nw)) {
				// 在庫情報減らす
				return getNewStockChangeInfo(nw, chkDate, -1);
			}
			// 旧データは故障部屋の場合
			if (isTargetCheck(od)) {
				// 在庫情報戻す
				return getNewStockChangeInfo(od, chkDate, 1);
			}
		} 
		// 既存は故障部屋情報
		else {
			// ステータス変更なし　かつ　処理結果が変更される場合
			if (nw.Result__c != od.Result__c) {
				// 新規故障部屋情報は故障部屋かつ結果は
				if (isTargetCheck(nw) && od.Result__c == CommConst.ROOM_ST_TYPE_BED_FIN) {
					// 在庫情報減らす
					return getNewStockChangeInfo(nw, chkDate, -1);
				}
				// 旧データは故障部屋の場合
				if (isTargetCheck(od) && nw.Result__c == CommConst.ROOM_ST_TYPE_BED_FIN) {
					// 在庫情報戻す
					return getNewStockChangeInfo(od, chkDate, 1);
				}
			}
		}
		return null;
	}

	/**
	* 在庫調整情報を作成する
	**/
	private StockHisPlus getNewStockChangeInfo(RoomsStatus__c rstatus, Date stockChangeDate, Integer calNum) {
		// 故障部屋じゃない場合、NULL情報を返却する
		if (!isTargetCheck(rstatus)) return null;
		if (rstatus.TypeOfRoomTypeId__c == null) return null;
		
		return (
			new StockHisPlus(
				new StockChangeHisotry__c(
				//StatusLst__c = ''
				StockChangeCnt__c = calNum,
				CreateSource__c = CommConst.BI_PROCESS_TYPE.SFDC.Name(),//部屋故障するため、発生源はSFDC
				AgtRef__c = null,
				StockChangeDate__c = stockChangeDate,	// 管理日ー＞調整日付
				TypeOfRoomRef__c = rstatus.TypeOfRoomTypeId__c,
				LeadRef__c = null
				// 2018/03/22 故障部屋時刻機能追加　by　zy BEGIN
				//),rstatus.RoomRef__c
				),rstatus
				// 2018/03/22 故障部屋時刻機能追加　by　zy END
			));
	}
	
	/**
	* 在庫調整情報を作成する
	**/
	private List<StockHisPlus> getNewStockChangeInfo(RoomsStatus__c rstatus, Integer calNum ) {
		list<StockHisPlus> stockHisLst = new list<StockHisPlus>();
		// 故障部屋じゃない場合、NULL情報を返却する
		if (!isTargetCheck(rstatus)) return stockHisLst;
		if (rstatus.TypeOfRoomTypeId__c == null) return stockHisLst;
		
		// 部屋は故障する場合、TL/TAへ連動が必要
		list<Date> dateRange = getBetweenDates(rstatus, true);
		// 期間内の調整情報を作成する
		//for (integer i = 0; i <= betweenDays; i++) {
		for (date stockChangeDate : dateRange) {
			//Date stockChangeDate = startDt.addDays(i);
			// 過去の日付は調整日付対象外
			//if (stockChangeDate < todayDt) continue;
			// 該当期間の
			stockHisLst.add(
				new StockHisPlus(
					new StockChangeHisotry__c(
						//StatusLst__c = ''
						StockChangeCnt__c = calNum,
						CreateSource__c = CommConst.BI_PROCESS_TYPE.SFDC.Name(),//部屋故障するため、発生源はSFDC
						AgtRef__c = null,
						StockChangeDate__c = stockChangeDate,	// 管理日ー＞調整日付
						TypeOfRoomRef__c = rstatus.TypeOfRoomTypeId__c,
						LeadRef__c = null
					// 2018/03/22 故障部屋時刻機能追加　by　zy BEGIN
					//),rstatus.RoomRef__c
					),rstatus
					// 2018/03/22 故障部屋時刻機能追加　by　zy END
				)
			);
		}
		return stockHisLst;
	}
	// 指定期間の日付リストを取得する（当日以後の日付リスト)
	private list<date> getBetweenDates (RoomsStatus__c rstatus, Boolean isTodayAft) {
		Date startDt = rstatus.StatusBeginDate__c;
		Date endDt = rstatus.StatusEndDate__c;
		Integer betweenDays = startDt.daysBetween(endDt);
		Date todayDt = Date.today();
		list<Date> datesLst = new list<Date>();
		// 期間内の調整情報を作成する
		for (integer i = 0; i <= betweenDays; i++) {
			Date nextDay = startDt.addDays(i);
			if (isTodayAft && nextDay < todayDt) continue;
			datesLst.add(nextDay);
		}
		return datesLst;
	}
	
	class StockHisPlus {
		// 2018/03/22 故障部屋時刻機能追加　by　zy BEGIN
		//public StockHisPlus(StockChangeHisotry__c ps, Id pRoomId) {
		public StockHisPlus(StockChangeHisotry__c ps, RoomsStatus__c status) {
			rs = status;
			String pRoomId = status.RoomRef__c;
		// 2018/03/22 故障部屋時刻機能追加　by　zy END
			s = ps;
			roomId = pRoomId;
			isTarget = false;
		}
		public StockChangeHisotry__c s{get;private set;}
		public Id roomId{get;private set;}
		public Boolean isTarget{get;set;}
		public RoomsStatus__c rs;
	}
}