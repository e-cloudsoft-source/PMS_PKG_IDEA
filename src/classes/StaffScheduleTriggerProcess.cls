/*********************************************
* スタッフの関連トリガー処理を行う
* 2015/12/08: スタッフ情報から活動データの連動
**/
public with sharing class StaffScheduleTriggerProcess {
	/**
	* before insert/befoer update/before delete
	**/
	public void autoSetupStaffSchedule(StaffSchedule__c[] newList, StaffSchedule__c[] oldList, CommConst.TriggerMethod action){
		// 検索キーを自動設定
		Set<Id> userIdSet = new Set<Id>();
		Set<Date> workDateSet = new Set<Date>();
		map<String, StaffSchedule__c> updDataMap = new map<String, StaffSchedule__c>();
		// 2018/03/07 Security Check BEGIN
		List<String> chkFields = new List<String>{'Description','OwnerId','EndDateTime','StartDateTime','IsAllDayEvent','Subject'};//,'Id'
		Map<String,Schema.SObjectField> m = Schema.SObjectType.Event.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFields, m)) {
			return;
		}
		// 2018/03/07 Security Check END
		// 2019/09/15 Security Check BY zyz BEGIN
		if (!CommSecurityUtils.isDeleteable(Event.getSObjectType())) {
			return;
		}
		// 2019/09/15 Security Check BY zyz END
		// 活動へ連動するスタッフ情報
		list<StaffSchedule__c> eventSyncStaffList = new list<StaffSchedule__c>();
		set<Id> delEventids = new set<Id>();
		// 新規、更新の場合
		if (action == CommConst.TriggerMethod.IsUpdate ||
			action == CommConst.TriggerMethod.IsInsert) {
			Integer idx = 0;
			// 関連の勤怠情報のIDを自動設定を行う
			for (StaffSchedule__c nw : newList) {
				nw.SearchKey__c = getSearchKey(nw.StaffUserRef__c, nw.WorkDay__c);
				// Clone問題回避
				nw.TimeManagementRef__c = null;
				// 関連勤怠情報をリンクする
				if ( action == CommConst.TriggerMethod.IsInsert) {
					userIdSet.add(nw.StaffUserRef__c);
					workDateSet.add(nw.WorkDay__c);
					// 開始、終了ステータスが設定する場合
					if (!CommUtils.isBlank(nw.StatusLst__c)) {
						eventSyncStaffList.add(nw);
					}
				}
				// 更新の場合
				else if ( action == CommConst.TriggerMethod.IsUpdate) {
					if (nw.StaffUserRef__c != oldList[idx].StaffUserRef__c ||
						nw.WorkDay__c != oldList[idx].WorkDay__c) {
						userIdSet.add(nw.StaffUserRef__c);
						workDateSet.add(nw.WorkDay__c);
					}
					
					// 開始、終了、コメント内容を変更される場合
					StaffSchedule__c od = oldList[idx];
					if ((nw.StatusLst__c != od.StatusLst__c ||
							nw.StopStatusLst__c != od.StopStatusLst__c ||
							nw.CommentLst__c != od.CommentLst__c)) {
						// 開始時刻はクリアすると、既存の活動情報をクリアする
						if (CommUtils.isBlank(nw.StatusLst__c)) {
							if (!CommUtils.isBlank(nw.EventId__c)) delEventids.add(nw.EventId__c);
						} else {
							// 活動更新対象
							eventSyncStaffList.add(nw);
						}
					}
				}
				updDataMap.put(nw.SearchKey__c, nw);
				idx++;
			}
		} else if (action == CommConst.TriggerMethod.IsDelete) {
			// 削除の場合
			for (StaffSchedule__c od : oldList) {
				if (!CommUtils.isBlank(od.EventId__c)) delEventids.add(od.EventId__c);
			}
		}
		if (!delEventids.isEmpty()) delete [select id from Event where id in :delEventids];
		
		if (!eventSyncStaffList.isEmpty()) {
			List<Event> upsertEvents = new List<Event>();
			// 更新、新規の場合
			for (StaffSchedule__c nw: eventSyncStaffList) {
				// 該当スタッフにより、活動情報を新規、更新を行う
				// 開始ステータスの情報を取得する
				String stfStatusLst = CommStringUtils.zenkakuEisujiToHankakuEisuji(nw.StatusLst__c);
				String stfStopStatusLst = CommStringUtils.zenkakuEisujiToHankakuEisuji(nw.StopStatusLst__c);
				Date workDay = nw.WorkDay__c;
				
				Event ev = new Event();
				if (!CommUtils.isBlank(nw.EventId__c)) ev.Id = nw.EventId__c;
				Time evTime;
				Time evStopTime;
				try {
					if (!CommUtils.isBlank(stfStatusLst)) evTime = Commutils.stringToTime(stfStatusLst);
				} catch (Exception e) {}
				try {
					if (!CommUtils.isBlank(stfStopStatusLst)) evStopTime = Commutils.stringToTime(stfStopStatusLst);
				} catch (Exception e) {}
				if (evTime != null) {
					// 件名
					// 2015/12/17 行動件名個別指定機能対応 BEIGN
					//ev.Subject = '作業';
					//作業
					String eventTitle = CommUtils.isBlank(nw.EventTitle__c) ? Label.CONST_035_0149 : nw.EventTitle__c; 
					ev.Subject = eventTitle;
					// 2015/12/17 行動件名個別指定機能対応 END
					// 終日行動
					ev.IsAllDayEvent = false;
					// 開始
					ev.StartDateTime = DateTime.newInstance(workDay, evTime);
					// 終了
					if (evStopTime == null) ev.EndDateTime = ev.StartDateTime.addHours(1);
					else {
						// 跨がり日の場合:23:00〜10:00
						if (evStopTime < evTime) ev.EndDateTime = DateTime.newInstance(workDay.addDays(1), evStopTime);
						else ev.EndDateTime = DateTime.newInstance(workDay, evStopTime);
					}
				}else {
					// 件名
					ev.Subject = stfStatusLst;
					// 終日行動
					ev.IsAllDayEvent = true;
					// 開始
					ev.StartDateTime = DateTime.newInstanceGMT(workDay.Year(),workDay.month(),workDay.day());
					// 終了
					ev.EndDateTime = ev.StartDateTime;
				}
				// 任命先
				ev.OwnerId = nw.StaffUserRef__c;
				// 説明
				ev.Description = CommUtils.nullToBLank(nw.CommentLst__c);
				// 新規、更新対象リスト
				upsertEvents.add(ev);
			}
			if (!upsertEvents.isEmpty()) {
				set<id> existEventIds = new set<id>();
				for (Event updEvent : upsertEvents) {
					if (!Commutils.isBlank(updEvent.id)) {
						existEventIds.add(updEvent.id);
					}
				}
				// 既存の活動を取得する
				set<id> existevents = new set<id>();
				if (!existEventIds.isEmpty()) {
					for (Event evt : [select id from event where id in :existEventIds for update]) {
						existevents.add(evt.id);
					}
				}
				for (Event updEvent : upsertEvents) {
					if (!Commutils.isBlank(updEvent.id) && !existevents.contains(updEvent.Id)) {
						updEvent.id = null;
					}
				}
				upsert upsertEvents;
			}
			// スタッフに設定を行う
			Integer updIdx = 0;
			for (Event evt : upsertEvents) {
				eventSyncStaffList[updIdx].EventId__c = evt.Id;
				updIdx++;
			}
		}
		
		// 処理対象がなかった
		if (userIdSet.isEmpty()) return;
		// Map<勤怠者_勤怠日， 勤怠ID>
		Map<String, Id> timeRelMap = new Map<String, Id>();
		List<TimeManagement__c> times = [select WorkerRef__c, WorkDay__c from TimeManagement__c where WorkerRef__c in :userIdSet and WorkDay__c in :workDateSet order by LastModifiedDate desc];
		for (TimeManagement__c tm : times) {
			String key = getSearchKey(tm.WorkerRef__c, tm.WorkDay__c);
			if (!timeRelMap.containsKey(key)) timeRelMap.put(key, tm.id);
		}
		// 勤怠データ参照リンクを設定する
		for (String key : updDataMap.keySet()) {
			if (timeRelMap.containsKey(key)) {
				updDataMap.get(key).TimeManagementRef__c = timeRelMap.get(key);
			}
		}
	}

	private string getSearchKey(Id workId, Date workDate) {
		return CommUtils.nullToBLank(workId) + '_' + workDate.format();
	}
}