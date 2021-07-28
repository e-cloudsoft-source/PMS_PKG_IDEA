public class ProjectDetailCommTriggerProcess {
	public void proejctDetailChg(ProjectDetail__c[] newLst, ProjectDetail__c[] oldLst, CommConst.TriggerMethod action){
		Set<String> delEvts = new Set<String>();
		Set<String> delTodos = new Set<String>();
		Map<String,Event> insertEventMap = new Map<String,Event>();
		// 2020/10/31 担当者を複数設定できるように by zy BEGIN
		Set<String> userKeySet = new Set<String>();// 複数担当者の行動鍵
		Map<String,Event> insUsersEvtMap = new Map<String,Event>();// 新規行動
		// 2020/10/31 担当者を複数設定できるように by zy END
		// 2020/10/31 担当者を複数設定できるように by zy BEGIN
		// カレンダー非表示集合
		Map<String,ProjectDetail__c> calendarDetailMap = new Map<String,ProjectDetail__c>();
		// 2020/10/31 担当者を複数設定できるように by zy END
		for (integer i = 0 ; i < newLst.size() ; i++) {
			ProjectDetail__c pd = newLst[i];
			if (action == CommConst.TriggerMethod.isInsert) {
				if(pd.calendarFlg__c && !CommUtils.isBlank(pd.taskId__c)) {
					pd.taskId__c = '';
					if (pd.EventType__c == StaffTaskHelp.EVENT_TYPE_EVENT) delEvts.add(pd.taskId__c);
					else if (pd.EventType__c == StaffTaskHelp.EVENT_TYPE_TODO) delTodos.add(pd.taskId__c);
					pd.EventType__c = StaffTaskHelp.EVENT_TYPE_DETAIL;
				}
				// 2020/10/31 担当者を複数設定できるように by zy BEGIN
				// カレンダー表示と複数担当者の場合
				if (!pd.calendarFlg__c && pd.UserRefs__c != null) {
					// 新規の行動の複数担当者の子行動作成
					for (String userId : pd.UserRefs__c.split(',')){
						// ユーザId有効チェック
						if (CommUtils.isBlank(userId)) continue;
						// 該当担当者以外のユーザー対応
						if (userId != pd.UserRef__c) {
							Event evt = createEvent(pd,userId);
							insUsersEvtMap.put(evt.MutliUserDetail__c,evt);
						}
					}
				}
				// 2020/10/31 担当者を複数設定できるように by zy END
			} else {
				ProjectDetail__c oldPd = oldLst[i];
				// 2020/10/31 担当者を複数設定できるように by zy BEGIN
				// 指定複数ユーザー
				Set<String> userRefSet = new Set<String>();
				Set<String> userRefOrgSet = new Set<String>(CommUtils.nullToBlank(pd.UserRefs__c).split(','));
				Set<String> deleteSet = new Set<String>();
				// 無効ユーザーフィルター
				userRefOrgSet.remove('');
				userRefOrgSet.remove(pd.UserRef__c);
				// 複数ユーザー変更の場合
				if (pd.UserRefs__c != oldPd.UserRefs__c) {
					userRefSet = userRefOrgSet;
					deleteSet = new Set<String>(CommUtils.nullTOBlank(oldPd.UserRefs__c).split(','));
				}
				// 2020/10/31 担当者を複数設定できるように by zy END
				if (oldPd.calendarFlg__c != pd.calendarFlg__c){
					// 2020/10/31 担当者を複数設定できるように by zy BEGIN
					if (!pd.calendarFlg__c)  {
						if (userRefSet.isEmpty()) userRefSet = userRefOrgSet;
						insertEventMap.put(pd.id,createEvent(pd));
					}
					// 2020/10/31 担当者を複数設定できるように by zy END
					else if (!CommUtils.isBlank(pd.taskId__c)) {
						if (pd.EventType__c == StaffTaskHelp.EVENT_TYPE_EVENT) delEvts.add(pd.taskId__c);
						else if (pd.EventType__c == StaffTaskHelp.EVENT_TYPE_TODO) delTodos.add(pd.taskId__c);
                        pd.taskId__c = '';
						pd.EventType__c = StaffTaskHelp.EVENT_TYPE_DETAIL;
						// 2020/10/31 担当者を複数設定できるように by zy BEGIN
						// カレンダー非表示の場合、関連行動全部削除
						deleteSet.addAll(userRefOrgSet);
						// 2020/10/31 担当者を複数設定できるように by zy END
					}
					// 2020/10/31 2.07.取引先の紐付け by zy BEGIN
					calendarDetailMap.put(pd.id,pd);
					// 2020/10/31 2.07.取引先の紐付け by zy END
				}
				// 2020/10/31 担当者を複数設定できるように by zy BEGIN
				// 2020/10/31 2.07.取引先の紐付け by zy BEGIN
				// チェック字段変更
				else if (pd.calendarFlg__c && checkFieldChg(pd,oldPd,new List<String>{'Title__c'})) {
					calendarDetailMap.put(pd.id,pd);
				}
				// 2020/10/31 2.07.取引先の紐付け by zy END
				// 削除の行動対応
				for (String userId : deleteSet) {
					if (CommUtils.isBlank(userId)) continue;
					if (!userRefSet.contains(userId)) {
						userKeySet.add(String.join(new List<String>{userId,pd.id},'_'));
					} else userRefSet.remove(userId);
				}
				// カレンダー表示
				if (!pd.calendarFlg__c && !userRefSet.isEmpty()) {
					for (String userId : userRefSet) {
						Event evt = createEvent(pd,userId);
						insUsersEvtMap.put(evt.MutliUserDetail__c,evt);
					}
				}
				// 2020/10/31 担当者を複数設定できるように by zy END
			}
		}
		if (!delEvts.isEMpty()){
			delete [select id from event where id=:delEvts];
		}
		if (!delTodos.isEmpty()){
			delete [select id from Task where id=:delTodos];
		}
		if (!insertEventMap.isEmpty()) {
			insert insertEventMap.values();
			for (ProjectDetail__c pd : newLst) {
				if (insertEventMap.containsKey(pd.id)) {
					pd.taskId__c = insertEventMap.get(pd.id).id;
					pd.EventType__c = StaffTaskHelp.EVENT_TYPE_EVENT;
				}
			}
		}
		// 2020/10/31 担当者を複数設定できるように by zy BEGIN
		if (!userKeySet.isEmpty()) {
			List<Event> evts = [select id,OwnerId,MutliUserDetail__c,EventIndex__c from Event where MutliUserDetail__c =:userKeySet];
			// 超出14日数据
      		Set<String> eventSet = new Set<String>();
			for (Event oldEvt : evts) {
		        if (!CommUtils.isBlank(oldEvt.EventIndex__c)) eventSet.add(oldEvt.EventIndex__c);
		      }
			// 2020/10/31 担当者を複数設定できるように by zy BEGIN
			if (!evts.isEmpty()) delete evts;
			if (!eventSet.isEmpty()) delete[select id from Event where EventIndex__c in :eventSet];
		}
		// 複数の担当者追加
		if (!insUsersEvtMap.isEmpty()) {
			// 既存行動チェック
			for (event evt : [select id,OwnerId,MutliUserDetail__c from Event where MutliUserDetail__c =:insUsersEvtMap.keySet()]){
				if (insUsersEvtMap.containsKey(evt.MutliUserDetail__c)) insUsersEvtMap.remove(evt.MutliUserDetail__c);
			}
			if (!insUsersEvtMap.isEmpty()) insert insUsersEvtMap.values();
		}
		// 2020/10/31 担当者を複数設定できるように by zy END
		// 2020/10/31 2.07.取引先の紐付け by zy BEGIN
		if (!calendarDetailMap.isEmpty()) {
			List<ActivityRefAccount__c> accs = new List<ActivityRefAccount__c>();
			for (ActivityRefAccount__c acc : [select id,RelationIdRefName__c,RelationIdRef__c,ProjectDetailRef__c from ActivityRefAccount__c where ProjectDetailRef__c in :calendarDetailMap.keySet()]) {
				acc.RelationIdRefName__c = calendarDetailMap.get(acc.ProjectDetailRef__c).Title__c;
				acc.RelationIdRef__c = calendarDetailMap.get(acc.ProjectDetailRef__c).taskId__c;
				accs.add(acc);
			}
			if (!accs.isEmpty()) update accs;
		}
		// 2020/10/31 2.07.取引先の紐付け by zy END
	}
	// 2020/10/31 担当者を複数設定できるように by zy BEGIN
	public EVent createEvent(ProjectDetail__c pd){
		return createEvent(pd,null);
	}
	public EVent createEvent(ProjectDetail__c pd,String userId){
	// 2020/10/31 担当者を複数設定できるように by zy END
		Event ev = new Event();
		ev.OwnerId = pd.UserRef__c;
		ev.Subject = pd.Title__c;
		ev.StartDateTime = pd.StartDt__c;
		// 2018/11/30 時間軸を日にした際に時間単位で表示される。日単位で切り替えできるように改善対応 by zy BEGIN
		ev.EndDateTime = CommUtils.eventSafeEndDateTm(pd.StartDt__c,pd.EndDt__c);
		// 2018/11/30 時間軸を日にした際に時間単位で表示される。日単位で切り替えできるように改善対応 by zy END
		ev.EndDatetime__c = pd.EndDt__c;
		ev.ProjectFlag__c = true;
        ev.CssStyle__c = pd.CssStyle__c;
        ev.CreateType__c = pd.CreateType__c;
        ev.GroupCode__c = pd.GroupCode__c;
        // 2020/10/31 担当者を複数設定できるように by zy BEGIN
        ev.CustomEventFlag__c = true; // 取引先关联用新规不生成关联数据控制
        // 指定ユーザーの場合
        if (!CommUtils.isBlank(userId)) {
        	ev.OwnerId = userId;
			ev.LockFlag__c = true;// 行動変更不能
			ev.MutliUserDetail__c = String.join(new List<String>{userId,pd.id},'_');
        } else if (!CommUtils.isBlank(pd.AccountRefs__c)){
        	String accid = CommUtils.nullToBlank(pd.AccountRefs__c).split(',')[0];
        	if (!CommUtils.isBlank(accid)) ev.whatid = accid;
        }
		// 2020/10/31 担当者を複数設定できるように by zy END
		return ev;
	}
	// 2020/10/31 2.07.取引先の紐付け by zy BEGIN
	// チェック字段変更
	private boolean checkFieldChg(ProjectDetail__c old , ProjectDetail__c pd , String[] fields){
		for (String f : fields) {
			if (old == null || pd == null) return true;
			if (pd.get(f) != old.get(f)) return true;
		}
		return false;
	}
	// 2020/10/31 2.07.取引先の紐付け by zy BEGIN
}