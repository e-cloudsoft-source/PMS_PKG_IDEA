public without sharing class StaffTaskHelp {
 
    public static List<Event> getTasks(list<id> userids, Date begDate, Date endDate){ 
    	// 2018/06/25 マルチタスクのタスク登録機能改善繰り返し期間追加 by BEGIN
    	List<Event> evetns = [select id, OwnerId, Owner.name,ActivityDate,Subject,StartDateTime,EndDateTime,CssStyle__c,RecurrenceActivityId
    										,IsAllDayEvent
    										// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける）by cxw BEGIN
    										,GroupCode__c
    										// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける）by cxw END
    										,EndDatetime__c 
    										// 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy BEGIN
											,EventIndex__c
   											// 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy END
   											// 2019/07/15 マルチタスク、一度決めたシフトを個人ごとにロックするボタンなどは設置可能 by zy BEGIN
   											,IsCantUpdFlg__c
   											// 2019/07/15 マルチタスク、一度決めたシフトを個人ごとにロックするボタンなどは設置可能 by zy END
    										from Event 
                                            where OwnerId =:userids 
                                            and 
                                            	((EndDatetime__c  = null and DAY_ONLY(convertTimezone(EndDateTime)) >= :begDate )
											 or (EndDatetime__c != null and DAY_ONLY(convertTimezone(EndDatetime__c)) >= :begDate))
                                            //DAY_ONLY(convertTimezone(EndDateTime)) >= :begDate 
                                            and DAY_ONLY(convertTimezone(StartDateTime)) <= :endDate 
                                             // 2018/06/25 マルチタスクのタスク登録機能改善繰り返し期間追加 by BEGIN
                                             // 定期のタスク、親定期タスク非表示
                                             and IsRecurrence = false
                                             // 2018/06/25 マルチタスクのタスク登録機能改善繰り返し期間追加 by END
                                            order by CreatedDate];
    	// 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy BEGIN
       	return refreshEvent(evetns);  
	// 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy END
    }  
    // 2018/07/15 プロジェックト機能追加　by　zy　BEGIN
    public static List<Event> getTaskByIdForUpdate(String taskId){
    	return [select id,EndDatetime__c,EndDateTime,StartDateTime,
    			// 2018/07/23 カスタム更新フラグ追加 by zy BEGIN
    			IsAllDayEvent,
    			CustomEventFlag__c from Event  where id = :taskId for update] ;
    			// 2018/07/23 カスタム更新フラグ追加 by zy END
    }
    // 2018/07/15 プロジェックト機能追加　by　zy　END
    /*
    * タスク新規と更新
    */
    public static void updEvent(Event event){
    	// 2018/07/23 カスタム更新フラグ追加 by zy BEGIN
    	// 既存行動の場合
    	if (event.id != null) {
    		List<event> events = [select id,CustomEventFlag__c,LockFlag__c from event where id=:event.id];
    		if (!events.isEmpty()) {
    			event.CustomEventFlag__c = !events[0].CustomEventFlag__c;
    		}
    	}
    	// 2018/07/23 カスタム更新フラグ追加 by zy END
    	upsert event;
    }
    // 2018/06/25 マルチタスクのタスク登録機能改善繰り返し期間追加 by BEGIN
    public static void updateTasks(List<Event> es){}
    public static void deleteTaskByIdForUpdate(String taskId){
    	deleteTaskByIdForUpdate(taskId,false);
    }
    public static void deleteTaskByIdForUpdate(String taskId,boolean delSameFlag) {
		// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
		// プロジェックトId前三位
		String projectPrefix = ProjectDetail__c.sObjectType.getDescribe().getKeyPrefix();
		// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
    	List<Event> taskLst = [select id,RecurrenceActivityId,ActivityDate from Event  where id = :taskId for update] ;
    	if (!taskLst.isEmpty()) {
    		Event task = taskLst[0];
    		// 削除定期タスク
    		if (delSameFlag) {
	    		// 該当タスク今後のイベントの場合
	    		for (Event e : [select id from Event where RecurrenceActivityId = :task.RecurrenceActivityId and ActivityDate >= :task.ActivityDate and id != :task.id]) {
	    			taskLst.add(e);
	    		}
	    	}
			// 2018/03/07 Security Check BEGIN
			if (!CommSecurityUtils.isDeleteable(Event.getSObjectType())) {
				return;
			}
			// 2018/03/07 Security Check END
    		delete taskLst;
    		// 定期タスクすべて削除の場合
    		if (task.RecurrenceActivityId != null) {
    			// 親定期タスク削除
    			List<event> lastTask = [select id,RecurrenceActivityId,IsRecurrence from event where RecurrenceActivityId = :task.RecurrenceActivityId];
    			if (!lastTask.isEmpty()){
    				List<event> childTasks = new List<event>();
    				Event parentEvent = null;
    				for (Event ev : lastTask) {
    					if (ev.IsRecurrence) parentEvent = ev;
    					else childTasks.add(ev);
    				}
    				if (childTasks.isEmpty() && parentEvent != null) delete parentEvent;
    			}
    		}
		// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
    	} else if (taskId.startsWith(projectPrefix)) {
			List<ProjectDetail__c> pds = [select id,RecurrenceActivityId__c,StartDt__c from ProjectDetail__c where id=:taskId for update];
			if (!pds.isEmpty()){
				String activityId = pds[0].RecurrenceActivityId__c;
				Datetime startDt = pds[0].StartDt__c;
				delete pds;
				// 削除定期タスク
				if (delSameFlag) {
					// 該当タスク今後のイベントの場合
					List<ProjectDetail__c> delDetails =  [select id from ProjectDetail__c where RecurrenceActivityId__c = :activityId and StartDt__c >= :startDt];
					if (!delDetails.isEmpty()) delete delDetails;
				}
			}
    	}
		// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
    }
    /**
	* FIELD_INTEGRITY_EXCEPTIONエラーメッセージ内容を取得する
	**/
	public static String getFieldValidationMessage(String message) {
		String key = 'FIELD_INTEGRITY_EXCEPTION';
		if (message.contains(key)) {
			Integer idx = message.indexOf(key) + key.length() + 1;
			String msgStr = message.substring(idx);
			return msgStr.substringBefore(':');
		} else {
			return message;
		}
	}
    // 2018/06/25 マルチタスクのタスク登録機能改善繰り返し期間追加 by END
    // 2018/07/15 プロジェックト機能追加　by　zy　BEGIN
    // プロジェックト
	public static String EVENT_TYPE_TODO = 'ToDo';
	public static String EVENT_TYPE_EVENT = '行動';
	// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
	public static String EVENT_TYPE_DETAIL = '明細';
	// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
	// 2018/11/15 17.プロジェクト管理を開いたときにタスクが開いた状態から始まる by zy BEGIN
	// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
	// 2020/08/31 担当部署列の追加、ユーザに紐づく部署ではなく、選択リストを引用するように by zy BEGIN
	// 2020/10/30 2.14.特定日のマーキング機能、スケジュールのなかでポイントをうち、右の表示マークをつける機能 by zy BEGIN
	// 2020/10/31 担当者を複数設定できるように by zy BEGIN
	// 2020/10/31 2.07.取引先の紐付け by zy BEGIN
	// 2020/10/31 タスク単位でマネージャー、担当者を設定できるようにする。設定していない場合はその親プロジェクトの権限を参照する。 by zy BEGIN
	public static String projectQuery = 'select id,name,OrderId__c,ParentProject__c,ParentProject__r.name,EventType__c,Importance__c,PercentComplete__c,PreRowNo__c,ProjectType__c,NextRowNo__c,Summary__c,UserRef__r.name,TaskId__c,ProjectMain__c,Expanded__c,DueStartDt__c,DueEndDt__c,ChatterRef__c,Title__c,StartDt__c,EndDt__c,Comment__c,CalendarFlg__c,cssStyle__c,createType__c,GroupCode__c,RecurrenceActivityId__c,IsCantUpdFlg__c,Department__c,Marks__c,UserRefs__c,AccountRefs__c,AssignUser__c,ManagerUser__c from ProjectDetail__c';
	// 2020/10/31 タスク単位でマネージャー、担当者を設定できるようにする。設定していない場合はその親プロジェクトの権限を参照する。 by zy END
	// 2020/10/31 2.07.取引先の紐付け by zy END
	// 2020/10/31 担当者を複数設定できるように by zy END
	// 2020/10/30 2.14.特定日のマーキング機能、スケジュールのなかでポイントをうち、右の表示マークをつける機能 by zy END
	// 2020/08/31 担当部署列の追加、ユーザに紐づく部署ではなく、選択リストを引用するように by zy END
    // 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
	// 2018/11/15 17.プロジェクト管理を開いたときにタスクが開いた状態から始まる by zy END
    public class PdetailInfo{
    	public Datetime Start;
    	public Datetime EndDt;
    	public ProjectDetail__c pd;
    	public Task taskObj;
    	public event evt;
		// 2020/10/31 担当者を複数設定できるように by zy BEGIN
		public Set<String> userIdSet;		// 複数担当者Id集合
		public Set<String> userNameSet; // 複数担当者集合
		// 2020/10/31 担当者を複数設定できるように by zy END
		// 2020/10/31 2.07.取引先の紐付け by zy BEGIN
		public Set<String> accIds;
		public List<String> accNames;
		// 2020/10/31 2.07.取引先の紐付け by zy END
    	public PdetailInfo(ProjectDetail__c detail){
    		pd = detail;
    		taskObj = null;
    		evt = null;
			// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
			Start = detail.StartDt__c;
    		EndDt = detail.EndDt__c;
			// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
			// 2020/10/31 担当者を複数設定できるように by zy BEGIN
			userIdSet = new Set<String>();
			userNameSet = new Set<String>();
			// 2020/10/31 担当者を複数設定できるように by zy END
			// 2020/10/31 2.07.取引先の紐付け by zy BEGIN
			accIds = new Set<String>();
			accNames = new List<String>();
			// 2020/10/31 2.07.取引先の紐付け by zy END
    	}
    	public void initDatetime(Task task){
    		taskObj = task;
    		String startTm = '00:00';
    		if (task.ActivityDate != null) {
    		// 開始時刻更新の場合
    		if (!CommUtils.isBlank(task.TaskStartTime__c)) {
    			startTm = task.TaskStartTime__c;
    			Start = CommUtils.convertDatetime(task.ActivityDate,startTm);
    		// 初期化
    		} else Start = Datetime.newInstanceGmt(task.ActivityDate,CommUtils.stringtotime(startTm));
    			EndDt = task.EndDatetime__c == null ? Start : task.EndDatetime__c;
    		}
    	}
    	public void initDatetime(Event task){
    		evt = task;
    		Start = task.StartDateTime;
    		EndDt = task.EndDatetime__c == null ? task.EndDateTime : task.EndDatetime__c;
    		// 2018/07/24 終日行動対応　by　zy BEGIN
    		if (task.IsAllDayEvent) {
    			Start = CommUtils.convertDatetime(task.StartDateTime.date(),'00:00');
    			EndDt = CommUtils.convertDatetime(EndDt.date(),'00:00');
    		}
    		// 2018/07/24 終日行動対応　by　zy END
    	}
    }
    // ユーザリスト
    public static List<User> getAllActiveUsers(List<String> userLst){
    	// 固定検索のAPI項目
		String userQuery = 'select Id,Name,EmployeeCode__c,Department,UserRole.name,Username from User where IsActive = true ';
		if (userLst != null && !userLst.isEmpty()) userQuery += ' and id =:userLst';
		List<User> users = DataBase.query(String.escapeSingleQuotes(userQuery));
		return users;
    }
    // 最後明細取得
	public static ProjectDetail__c getLastOrderDetail(String projectMainId,String projectId){
		ProjectDetail__c pd = null;
		if (!CommUtils.isBlank(projectMainId)) {
			String projectWhere = ' where ProjectType__c = null and ProjectMain__c =:projectMainId';
			projectWhere += ' order by OrderId__c desc limit 1';
			List<ProjectDetail__c> projects = Database.query(projectQuery + projectWhere);
			if (!projects.isEmpty()) pd = projects[0];
		}
		return pd;
	}
	// 当前order以後のプロジェックト明細
	public static List<ProjectDetail__c> getAfterCureentOrderDetails(Decimal orderId,String projectMainId,String parentId){
		List<ProjectDetail__c> pds = new List<ProjectDetail__c>();
		if (orderId != null) {
			String projectWhere = ' where ProjectType__c = null and OrderId__c >= :orderId';
			if (!CommUtils.isBlank(projectMainId)) projectWhere += ' and ProjectMain__c =:projectMainId';
			if (!CommUtils.isBlank(parentId)) projectWhere += ' and ParentProject__c =:parentId';
			else projectWhere += ' and ParentProject__c =null';
			projectWhere += ' order by OrderId__c';
			pds = Database.query(projectQuery + projectWhere);
		}
		return pds;
	}
	
	public static Map<String, List<ProjectDetail__c>> getOrderDetailsForParents(String projectMainId, Set<String> parentIds){
		Map<String, List<ProjectDetail__c>> result = new Map<String, List<ProjectDetail__c>>();
		String projectWhere = ' where ProjectType__c = null and ProjectMain__c =:projectMainId and ParentProject__c =:parentIds order by OrderId__c';
		for(ProjectDetail__c pd : Database.query(projectQuery + projectWhere)){
			if(!result.containsKey(pd.ParentProject__c)) result.put(pd.ParentProject__c, new List<ProjectDetail__c>());
			result.get(pd.ParentProject__c).add(pd);
		}
		return result;
	}
	
	// 子明細なしの場合、親明細更新
	public static boolean refreshParentNode(ProjectDetail__c orgParDetail,String childId){
		List<ProjectDetail__c> orgChildLst = [select id from ProjectDetail__c where ParentProject__c = :orgParDetail.id and id != :childId and ProjectType__c = null ];
		if (orgChildLst.isEmpty()) return true;
		return false;
	}
	// 利用ID検索タスクリスト
	// 検索タスク
	public static List<Event> getEvents(List<String> taskIds){ 
		List<Event> events = [select id,subject,StartDateTime,EndDateTime,EndDatetime__c,Owner.Name,OwnerId
								// 2018/07/24 終日行動対応　by　zy BEGIN
								,IsAllDayEvent,DurationInMinutes
								// 2018/07/24 終日行動対応　by　zy END
								// 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy BEGIN
								,EventIndex__c
								// 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy END
								// 2018/07/23 カスタム更新フラグ追加 by zy BEGIN
								,CustomEventFlag__c,Description from event where id = :taskIds and IsArchived != true];
								// 2018/07/23 カスタム更新フラグ追加 by zy END
		// 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy BEGIN
		return refreshEvent(events);
		// 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy END
	}
	// 検索タスク
	public static List<Event> getEvents(String userId, String contactId,String taskName, Date startDt, Date endDt){ 
    	String eventQuery = 'select id,subject,StartDateTime,EndDateTime,EndDatetime__c,Owner.Name,CssStyle__c,OwnerId,whatid,What.name,Description '
    						// 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy BEGIN
    						+  ',EventIndex__c ' + 
							// 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy END
    						'from event where ProjectFlag__c = false and IsRecurrence = false and RecurrenceActivityId = null and IsArchived != true';
		if (startDt != null) {
			eventQuery += ' and ((EndDatetime__c  = null and DAY_ONLY(convertTimezone(EndDateTime)) >= :startDt) ';
			eventQuery += ' or (EndDatetime__c  != null and DAY_ONLY(convertTimezone(EndDatetime__c)) >= :startDt))';
		}
		if (endDt != null)  eventQuery += ' and DAY_ONLY(convertTimezone(StartDateTime)) <= :endDt';
		if (!CommUtils.isBlank(userId)) eventQuery += ' and ownerid =:userId ';
		if (!CommUtils.isBlank(contactId)) eventQuery += ' and WhatId =:contactId ';
		if (!CommUtils.isBlank(taskName)) eventQuery += ' and subject like :taskName ';
		eventQuery += ' order by CreatedDate limit 200';
		List<event> events = Database.query(eventQuery);
        // 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy BEGIN
	return refreshEvent(events);
	// 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy END
    }  
    // 利用ID検索Todo
    public static Task getTaskById(String taskId){
    	Task task = null;
    	List<Task> events = [select id,subject,ActivityDate,Owner.Name,OwnerId,whatid,What.name,Description from Task where id = :taskId];
    	if (!events.isEmpty()) task = events[0];
    	return task;
    }
    // 利用ID検索Todoリスト
	public static List<Task> getTasks(List<String> taskIds){ 
		List<Task> events = [select id,subject,ActivityDate,EndDatetime__c,Owner.Name,OwnerId,whatid,What.name,TaskStartTime__c,Description 
								// 2019/07/15 マルチタスク、一度決めたシフトを個人ごとにロックするボタンなどは設置可能 by zy BEGIN
								,IsCantUpdFlg__c
								// 2019/07/15 マルチタスク、一度決めたシフトを個人ごとにロックするボタンなどは設置可能 by zy END
								from Task where id = :taskIds and IsArchived != true and ActivityDate != null];
        return events;  
    } 
    // 検索Todo
	public static List<Task> getTasks(String userId, String contactId,String taskName, Date startDt, Date endDt){ 
    	String eventQuery = 'select id,subject,ActivityDate,EndDatetime__c,Owner.Name,CssStyle__c,OwnerId,whatid,What.name,TaskStartTime__c,Description '
    						// 2019/07/15 マルチタスク、一度決めたシフトを個人ごとにロックするボタンなどは設置可能 by zy BEGIN
    	 					+ ',IsCantUpdFlg__c'
							// 2019/07/15 マルチタスク、一度決めたシフトを個人ごとにロックするボタンなどは設置可能 by zy END
    						+ ' from Task where ProjectFlag__c = false and IsRecurrence = false and IsArchived != true and RecurrenceActivityId = null and ActivityDate != null and IsClosed != true ';
		if (startDt != null) eventQuery += ' and ActivityDate >= :startDt';
		if (endDt != null)  eventQuery += ' and ActivityDate <= :endDt';
		if (!CommUtils.isBlank(userId)) eventQuery += ' and ownerid =:userId ';
		if (!CommUtils.isBlank(contactId)) eventQuery += ' and WhatId =:contactId ';
		if (!CommUtils.isBlank(taskName)) eventQuery += ' and subject like :taskName ';
		eventQuery += ' order by CreatedDate  limit 2000';
		List<Task> events = Database.query(eventQuery);
        return events;  
    }  
	// 利用ID取得プロジェックトリスト
	// 2020/09/30 右上のタスク選択リストに自分が関連するタスクのみ表示機能と検索機能運用が始まると200以上のタスクが作られることが想定されるため探しやすくするため by zy BEGIN
	public static List<ProjectMain__c> getMainPorjects(String userId,Boolean isAllEdit) {
		return getMainPorjects(userId,isAllEdit,null);
	}
	public static List<ProjectMain__c> getMainPorjects(String userId,Boolean isAllEdit,String whereSQL) {
	// 2020/09/30 右上のタスク選択リストに自分が関連するタスクのみ表示機能と検索機能運用が始まると200以上のタスクが作られることが想定されるため探しやすくするため by zy END	
		List<ProjectMain__c> projects = new List<ProjectMain__c>();
		if (!CommUtils.isBlank(userId)) {
			// 私有プロジェックト
			// 2019/02/28 プロジェクトリストの並び替え by zy BEGIN
			//List<ProjectMain__c> priveteProjects = getProjectMainLst(false);
			// 2020/09/30 右上のタスク選択リストに自分が関連するタスクのみ表示機能と検索機能運用が始まると200以上のタスクが作られることが想定されるため探しやすくするため by zy BEGIN
			List<ProjectMain__c> priveteProjects = getProjectMainLst(whereSQL);
			// 2020/09/30 右上のタスク選択リストに自分が関連するタスクのみ表示機能と検索機能運用が始まると200以上のタスクが作られることが想定されるため探しやすくするため by zy END
			// 2019/02/28 プロジェクトリストの並び替え by zy END
			Map<String ,ProjectMain__c> projectMap = new Map<String ,ProjectMain__c>();
			for (ProjectMain__c projectMain : priveteProjects) {
				if (projectMain.IsPublicFlag__c) {
					projects.add(projectMain);
					continue;
				}
				String manaUser = CommUtils.nullToBlank(projectMain.ManagerUser__c);
				String assignUser = CommUtils.nullToBlank(projectMain.AssignUser__c);
				if (manaUser.contains(userId) || assignUser.contains(userId) || isAllEdit) 
					projects.add(projectMain);
			}
		// 2019/02/28 プロジェクトリストの並び替え by zy BEGIN
		} else {
			for (ProjectMain__c main : getProjectMainLst(true)) {
				projects.add(main);
			}
		}
		// 2019/02/28 プロジェクトリストの並び替え by zy END
		return projects;
	}
	// 2020/10/31 プロジェクトオブジェクトのレコードにプロジェクトコードを作成し by zy BEGIN
	private static String projectMainSQL = CommSqlUtils.generateQueryString(ProjectMain__c.SobjectType.getDescribe().name,null);
	// 2020/10/31 プロジェクトオブジェクトのレコードにプロジェクトコードを作成し by zy END
	// プロジェックト公開・非公開リスト取得
	public static List<ProjectMain__c> getProjectMainLst(boolean isPublicFlag){
		// 2020/10/31 プロジェクトオブジェクトのレコードにプロジェクトコードを作成し by zy BEGIN
		String query = projectMainSQL;
		query += ' where IsPublicFlag__c = :isPublicFlag';
		return database.query(query);
		// 2020/10/31 プロジェクトオブジェクトのレコードにプロジェクトコードを作成し by zy END
		// 2018/11/15 8.予定と実績を表示させる、させないの切り替え by zy BEGIN
		// 2019/03/15 マルチタスクの表示を切り替える by cxw BEGIN
		List<ProjectMain__c> projectMains = [select id,name,AssignUser__c,ManagerUser__c,Describe__c,PlanBaseName__c, finish__c, EndDt__c
		// 2019/03/15 マルチタスクの表示を切り替える by cxw END
			// 2018/11/30 時間軸を日にした際に時間単位で表示される。日単位で切り替えできるように改善対応 by zy BEGIN
			,DateMode__c
			// 2018/11/30 時間軸を日にした際に時間単位で表示される。日単位で切り替えできるように改善対応 by zy END
			from ProjectMain__c where IsPublicFlag__c = :isPublicFlag];
		// 2018/11/15 8.予定と実績を表示させる、させないの切り替え by zy END
		return projectMains;
	}
	// 利用ID取得プロジェックト
	public static ProjectMain__c getProjectMain(String dataId){
		ProjectMain__c main = null;
		if (!CommUtils.isBlank(dataId)) {
			// 2020/10/31 プロジェクトオブジェクトのレコードにプロジェクトコードを作成し by zy BEGIN
			String query = projectMainSQL;
			query += ' where id =:dataId';
			List<ProjectMain__c> projects = database.query(query);
			if (!projects.isEmpty()) return projects[0];
			// 2020/10/31 プロジェクトオブジェクトのレコードにプロジェクトコードを作成し by zy END
			// 2019/03/15 マルチタスクの表示を切り替える by cxw BEGIN
			List<ProjectMain__c> mains = [select id,name,AssignUser__c,StartDt__c,endDt__c,ManagerUser__c,IsPublicFlag__c,Describe__c, finish__c
			// 2019/03/15 マルチタスクの表示を切り替える by cxw END
				// 2018/11/15 8.予定と実績を表示させる、させないの切り替え by zy BEGIN
				,PlanBaseName__c
				// 2018/11/15 8.予定と実績を表示させる、させないの切り替え by zy END
				// 2018/11/30 時間軸を日にした際に時間単位で表示される。日単位で切り替えできるように改善対応 by zy BEGIN
				,DateMode__c
				// 2018/11/30 時間軸を日にした際に時間単位で表示される。日単位で切り替えできるように改善対応 by zy END
				// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
				,CalendarFlg__c
				// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
				// 2020/10/31 タスク単位でマネージャー、担当者を設定できるようにする。設定していない場合はその親プロジェクトの権限を参照する。 by zy BEGIN
				,RoleDetailFlg__c
				// 2020/10/31 タスク単位でマネージャー、担当者を設定できるようにする。設定していない場合はその親プロジェクトの権限を参照する。 by zy END
				from ProjectMain__c where id =:dataId];
			if (!mains.isEmpty()) main = mains[0];
		}
		return main;
	}
	// 利用ID取得プロジェックト明細
	public static List<PdetailInfo> getProjectLst(String projectId,Date startDt,Date endDt ){
		String projectWhere = ' where ProjectType__c = null ';
		if (!CommUtils.isBlank(projectId)) projectWhere += ' and ProjectMain__c = :projectId';
		//if (startDt != null) projectWhere += ' and DAY_ONLY(StartDt__c) >=:startDt';
		//if (endDt != null) projectWhere += ' and DAY_ONLY(StartDt__c) <=:endDt';
		projectWhere += ' order by OrderId__c';
		List<ProjectDetail__c> projects = Database.query(projectQuery + projectWhere);
		List<PdetailInfo> infos = converDetilInfos(projects);
		return infos;
	}
	// 利用ID取得プロジェックト明細
	public static PdetailInfo getProjectDetail(String dataId){
		PdetailInfo pd = null;
		if (!CommUtils.isBlank(dataId)) {
			String projectWhere = ' where ProjectType__c = null ';
			if (!CommUtils.isBlank(dataId)) projectWhere += ' and id=:dataId';
			projectWhere += ' order by OrderId__c';
			List<ProjectDetail__c> projects = Database.query(projectQuery + projectWhere);
			List<PdetailInfo> infos = converDetilInfos(projects);
			if (!infos.isEmpty()) pd = infos[0];
		}
		return pd;
	}
	public static List<PdetailInfo> getProjects(List<String> projectDetails){
		// プロジェックト明細リスト
		List<ProjectDetail__c> projects = getProjectDetails(projectDetails);
		List<PdetailInfo> infos = converDetilInfos(projects);
		return infos;
	}
	// プロジェックト明細関連関係取得
	public static List<ProjectDetail__c> getDependencie(String dataId,String projectId){
		String projectWhere = ' where ProjectType__c != null';
		if (!CommUtils.isBlank(dataId)) projectWhere += ' and id=:dataId';
		if (!CommUtils.isBlank(projectId)) projectWhere += ' and projectMain__c=:projectId';
		List<ProjectDetail__c> projects = Database.query(projectQuery + projectWhere);
		return projects;
	}
	// プロジェックト明細リスト
	public static List<ProjectDetail__c> getProjectDetails(List<String> detailIds){
		String projectWhere = ' where ProjectType__c = null ';
		if (!detailIds.isEmpty()) projectWhere += ' and id = :detailIds';
		projectWhere += ' order by OrderId__c';
		List<ProjectDetail__c> projects = Database.query(projectQuery + projectWhere);
		return projects;
	}
	// プロジェックト明細リストの削除
	public static void deleteProjects(List<PdetailInfo> curProjs){
		List<Event> updEvent = new List<Event>();
		List<Task> updTask = new List<Task>();
		// 2018/03/07 Security Check BEGIN
		if (!CommSecurityUtils.isCanUpdateable(Event.getSObjectType())) {
			return;
		}
		if (!CommSecurityUtils.isCanUpdateable(Task.getSObjectType())) {
			return;
		}
		if (!CommSecurityUtils.isDeleteable(ProjectDetail__c.getSObjectType())) {
			return;
		}
		// 2018/03/07 Security Check END
		List<ProjectDetail__c> details = new List<ProjectDetail__c>();
		// 2020/10/31 2.07.取引先の紐付け by zy BEGIN
		Set<String> delAccSet = new Set<String>();
		// 2020/10/31 2.07.取引先の紐付け by zy END
		for (PdetailInfo detail : curProjs) {
			if (detail.evt != null){
				detail.evt.ProjectFlag__c = false;
				updEvent.add(detail.evt);
			}
			if (detail.taskObj != null) {
				detail.taskObj.ProjectFlag__c = false;
				updTask.add(detail.taskObj);
			}
			// 2020/10/31 2.07.取引先の紐付け by zy BEGIN
			if (!detail.pd.CalendarFlg__c) delAccSet.add(detail.pd.id);
			// 2020/10/31 2.07.取引先の紐付け by zy END
			details.add(detail.pd);
		}
		// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける）by cxw BEGIN
		boolean deleteFlag = getDeleteFlag();
		//if (!updEvent.isEmpty()) update updEvent;
		if (!updEvent.isEmpty()) {
			if (deleteFlag) delete updEvent;
			else update updEvent;
		}
		//if (!updTask.isEmpty()) update updTask;
		if (!updTask.isEmpty()) {
			if (deleteFlag) delete updTask;
			else update updTask;
		}
		if (!details.isEmpty()) delete details;
		// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける）by cxw END
		// 2020/10/31 2.07.取引先の紐付け by zy BEGIN
		if (!delAccSet.isEmpty()) {
			List<ActivityRefAccount__c> acts = [select id from ActivityRefAccount__c where ProjectDetailRef__c in :delAccSet];
			if (!acts.isEmpty()) delete acts;
		}
		// 2020/10/31 2.07.取引先の紐付け by zy END
		refreshParentNodeByLst(details);
	}
	// 删除线
	public static void deleteDependencie(String dataId){
		// 2018/03/07 Security Check BEGIN
		if (!CommSecurityUtils.isDeleteable(ProjectDetail__c.getSObjectType())) {
			return;
		}
		LIst<ProjectDetail__c> pds = [select id from ProjectDetail__c where id = :dataId];
		if (!pds.isEmpty()) {
			delete pds[0];
		}
	}
	// 更新プロジェックト明細summary
	public static void refreshParentNodeByLst(List<ProjectDetail__c> pds){
		Set<String> projectSet = new Set<String>();
		for (ProjectDetail__c pd : pds) {
			if (pd.ParentProject__c != null) projectSet.add(pd.ParentProject__c);
		}
		refresParentHadSummary(projectSet);
	}
	// 更新プロジェックト明細summary
	public static void refresParentHadSummary(Set<String> projectSet){
		Map<String,List<ProjectDetail__c>> childMaps = new Map<String,List<ProjectDetail__c>>();
		List<ProjectDetail__c> orgChildLst = [select id,ParentProject__c from ProjectDetail__c where ParentProject__c = :projectSet and ProjectType__c = null ];
		for (ProjectDetail__c pd : orgChildLst) {
			if (!childMaps.containsKey(pd.ParentProject__c)) childMaps.put(pd.ParentProject__c,new List<ProjectDetail__c>());
			childMaps.get(pd.ParentProject__c).add(pd);
		}
		List<String> parIdLst = new List<String>();
		List<String> hadchildIdLst = new List<String>();
		// 节点的parent没有相同子节点情况下
		for (String projectId : projectSet) {
			if (!childMaps.containsKey(projectId)) parIdLst.add(projectId);
			else hadchildIdLst.add(projectId);
		}
		// summary->false
		if (!parIdLst.isEmpty()) {
			List<ProjectDetail__c> updDetails = new List<ProjectDetail__c>();
			for (ProjectDetail__c pd : [select id,summary__c from ProjectDetail__c where id = :parIdLst and summary__c = true]){
				pd.summary__c = false;
				updDetails.add(pd);
			}
			if (!updDetails.isEmpty()) update updDetails;
		}
		// summary -> true
		if (!hadchildIdLst.isEmpty()) {
			List<ProjectDetail__c> updDetails = new List<ProjectDetail__c>();
			for (ProjectDetail__c pd : [select id,summary__c from ProjectDetail__c where id = :hadchildIdLst and summary__c = false]){
				pd.summary__c = true;
				updDetails.add(pd);
			}
			if (!updDetails.isEmpty()) update updDetails;
		}
	}
	
	//　プロジェックト明細保存
	public static void insertProjectDetail(ProjectDetail__c detail){
		insertProjectDetail(new List<ProjectDetail__c>{detail});
	}
	//　プロジェックト明細保存
	public static void insertProjectDetail(List<ProjectDetail__c> details){
		insert details;
	}
	//　プロジェックト保存
	public static void insertProjectMain(ProjectMain__c main){
		insert main;
	}
	public static void updateProjectMain(ProjectMain__c main){
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'planbasename__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.GuestRoomStock__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
			return ;
		}
		// 2019/09/15 Security Check BY zyz END
		update main;
	}
	// タスクリスト更新
	public static void updateEvents(List<Event> events){
		for (Event evt : events) {
			evt.CustomEventFlag__c = !evt.CustomEventFlag__c;
			evt.LockFlag__c = !evt.LockFlag__c;
		}
		update events;
	}
	// Todoリスト更新
	public static void updateChangeTasks(List<Task> events){
		update events;
	}
	//　プロジェックト明細保存
	public static void updateProjectDetail(ProjectDetail__c detail){
		updateProjectDetail(new List<ProjectDetail__c>{detail});
	}
	//　プロジェックト明細保存
	public static void updateProjectDetail(List<ProjectDetail__c> details){
		update details;
	}
	// プロジェクト明細の順番更新
	public static void afterChangeOrder(ProjectDetail__c curProj){
		Decimal beginIdx = curProj.OrderId__c;
		List<ProjectDetail__c> pds = [select id,OrderId__c from ProjectDetail__c where id != :curProj.id 
										and OrderId__c >= :curProj.OrderId__c and ParentProject__c =:curProj.ParentProject__c and ProjectMain__c = :curProj.ProjectMain__c and ProjectType__c = null order by OrderId__c];
		if (!pds.isEmpty()) {
			Map<Decimal,ProjectDetail__c> orderMap = new Map<Decimal,ProjectDetail__c>();
			List<Decimal> orderLst = new List<Decimal>();
			for (ProjectDetail__c pd : pds) {
				beginIdx++;
				pd.OrderId__c = beginIdx;
			}
			update pds;
		}
	}
	
	// プロジェックト明細、タスクとTODO 開始日時と終了日時
	private static List<PdetailInfo> converDetilInfos(List<ProjectDetail__c> pds){
		List<PdetailInfo> infos = new List<PdetailInfo>();
		Set<String>eventSet = new Set<String>();
		Set<String>taskSet = new Set<String>();
		Map<String,PdetailInfo> taskTimeMap = new Map<String,PdetailInfo>();
		// 2020/10/31 担当者を複数設定できるように by zy BEGIN
		Set<String> userSet = new Set<String>(); // ユーザ集合
		// 2020/10/31 担当者を複数設定できるように by zy END
		// 2020/10/31 2.07.取引先の紐付け by zy BEGIN
		Set<String> pdSet = new Set<String>();
		// 2020/10/31 2.07.取引先の紐付け by zy END
		for (ProjectDetail__c pd : pds) {
			PdetailInfo info = new PdetailInfo(pd);
			if (pd.eventType__c == EVENT_TYPE_EVENT) eventSet.add(pd.taskId__c);
			// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
			else if(pd.EventType__c == EVENT_TYPE_TODO) taskSet.add(pd.taskId__c);
			else infos.add(info);
			// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
			// 2020/10/31 担当者を複数設定できるように by zy BEGIN
			// カレンダー表示非表示対応
			if (!CommUtils.isBlank(pd.taskId__c)) taskTimeMap.put(pd.taskId__c,info);
			else taskTimeMap.put(pd.id,info);
			// 複数担当者の場合
			if (!CommUtils.isBlank(pd.UserRefs__c)) {
				// プロジェクトのユーザ追加
				info.userIdSet = new Set<String>(CommUtils.nullToBlank(pd.UserRefs__c).split(','));
				userSet.addAll(info.userIdSet);
			}
			// 2020/10/31 2.07.取引先の紐付け by zy BEGIN
			// 複数担当者の場合
			if (!CommUtils.isBlank(pd.AccountRefs__c)) {
				// プロジェクトのユーザ追加
				pdSet.add(pd.id);
			}
			// 2020/10/31 2.07.取引先の紐付け by zy END
			// 2020/10/31 担当者を複数設定できるように by zy END
		}
		// 2020/10/31 担当者を複数設定できるように by zy BEGIN
		Map<String,User> userMap = new Map<String,User>();
		// 複数ユーザ取得
		if (!userSet.isEmpty()) userMap = new Map<String,User>([select id,name,lastname,firstname from User where id =:userSet]);
		// 2020/10/31 担当者を複数設定できるように by zy END
		// 2020/10/31 2.07.取引先の紐付け by zy BEGIN
		Map<String,List<String>> projectAccNames = new Map<String,List<String>>();
		if (!pdSet.isEmpty()) {
			// 活動関連取引先取得
			for (ActivityRefAccount__c p : [select AccountSubRef__r.name,ProjectDetailRef__c from ActivityRefAccount__c where ProjectDetailRef__c in :pdSet]){
				if (!projectAccNames.containsKey(p.ProjectDetailRef__c)) projectAccNames.put(p.ProjectDetailRef__c,new List<String>());
				projectAccNames.get(p.ProjectDetailRef__c).add(p.AccountSubRef__r.name);
			}
		}
		// 2020/10/31 2.07.取引先の紐付け by zy END
		List<Event> events = getEvents(new List<String>(eventSet));
		for (Event evt : events) {
			taskTimeMap.get(evt.id).initDatetime(evt);
		}
		List<Task> tasks = getTasks(new List<String>(taskSet));
		for (Task evt : tasks) {
			taskTimeMap.get(evt.id).initDatetime(evt);
		}
		for (ProjectDetail__c pd : pds) {
			// 2020/10/31 担当者を複数設定できるように by zy BEGIN
			// PdetailInfo curDetail = taskTimeMap.get(pd.taskId__c);
			PdetailInfo curDetail = taskTimeMap.containsKey(pd.taskId__c) ? taskTimeMap.get(pd.taskId__c) : taskTimeMap.get(pd.id);
			if (!curDetail.userIdSet.isEmpty()) {
				for (String userId : curDetail.userIdSet) {
					if (userMap.containsKey(userId)){
						User u = userMap.get(userId);
						String userName = u.name;
						curDetail.userNameSet.add(userName);
					}
				}
			}
			// 2020/10/31 2.07.取引先の紐付け by zy BEGIN
			if (projectAccNames.containsKey(pd.id)) curDetail.accNames = projectAccNames.get(pd.id);
			// 2020/10/31 2.07.取引先の紐付け by zy END
			// 2020/10/31 担当者を複数設定できるように by zy END
			if (curDetail.taskObj != null || curDetail.evt != null) infos.add(curDetail);
		}
		return infos;
	}
	// 2018/07/15 プロジェックト機能追加　by　zy　END
	// 2018/10/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける）by cxw BEGIN
    public static boolean getDeleteFlag(){
    	boolean deleteFlag = true;
    	try{
			// XML読み込み
			Dom.XmlNode targetNode = CommXmlUtils.encodeParseXmlDoc('StaffScheduleConfigXml',null,new String[]{'<COONDITION>','</COONDITION>'});
			// 勤怠ボタンの背景と文字の色
			Dom.XmlNode summaryNode;
			for(Dom.XMLNode xmlNode : targetNode.getChildElements()){
				// タグ名
				String attributeName = xmlNode.getName();
				if(attributeName.equalsIgnoreCase('GANTTCONFIG')){
					Dom.XmlNode removeNode = xmlNode.getChildElement('EVENT_REMOVE',null);
					if (removeNode != null) {
						String removeStr = CommUtils.nullToBlank(removeNode.getText());
						if (!CommUtils.isBlank(removeStr)) deleteFlag = Boolean.valueof(removeStr);
					}
				}
			}
		} catch(exception e) {}
		return deleteFlag;
    }
    // 既存行動グループコード取得
    public static Set<String> getGroups(List<Id> userIds){
    	// 返るリスト初期化
    	Set<String> result = new Set<String>();
    	// 既存グループコード取得
    	for(AggregateResult e : [select GroupCode__c groupCode from Event where GroupCode__c != null and ownerid in :userIds group by GroupCode__c]){
    		// グループコード
    		String name = CommUtils.nullToBlank(e.get('groupCode'));
    		// 特殊グループ処理
    		String groupName = name.trim();
    		// グループコード追加
    		if(!CommUtils.isBlank(groupName)) result.add(groupName);    	
    	}
    	return result;
    }
    // 指定条件行動リスト取得
	public static List<Event> getTasks(list<id> userids, Date begDate, Date endDate,String filters){
	// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy BEGIN	
		return getTasks(userids,begDate,endDate,filters,null,null);
	}
	 // 指定条件行動リスト取得
	public static List<Event> getTasks(list<Id> userids, Date begDate, Date endDate,String filters,String fieldName,List<String> fieldValues){
    // 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy END
		// タスクSQL文
    	String taskSQL = 'select id, OwnerId, Owner.name,ActivityDate,Subject,StartDateTime,EndDateTime,CssStyle__c,RecurrenceActivityId'
    				// 2019/07/15 マルチタスク、一度決めたシフトを個人ごとにロックするボタンなどは設置可能 by zy BEGIN
 					+ ',IsCantUpdFlg__c'
					// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy BEGIN
					+ ',CreateType__c' 
					// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy END
					// 2019/07/15 マルチタスク、一度決めたシフトを個人ごとにロックするボタンなどは設置可能 by zy END
					// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
					+ ',Description,Location'
					// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
					// 2020/10/31 担当者を複数設定できるように by zy BEGIN
					+ ',MutliUserDetail__c'
					// 2020/10/31 担当者を複数設定できるように by zy END
    				// 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy BEGIN
					+ ',IsAllDayEvent,EndDatetime__c,GroupCode__c,EventIndex__c';
					// 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy END
    	taskSQL += ' from Event'; 
    	// 既存条件設定
    	String taskWhere = ' where ((EndDatetime__c  = null and DAY_ONLY(convertTimezone(EndDateTime)) >= :begDate ) or (EndDatetime__c != null and DAY_ONLY(convertTimezone(EndDatetime__c)) >= :begDate))';
    	taskWhere += ' and DAY_ONLY(convertTimezone(StartDateTime)) <= :endDate  and IsRecurrence = false';
		// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy BEGIN
		if (userids != null && !userids.isEmpty()) taskWhere += ' and OwnerId =:userids';
		if (!CommUtils.isBlank(fieldName) && fieldValues != null && !fieldValues.isEmpty()) taskWhere += ' and ' + fieldName + ' =:fieldValues';
		// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy END
    	// シフト勤務フラグ
    	boolean staffExpect = false;
    	// その他フラグ
    	boolean otherFlag = false;
    	// フィルター条件
    	String filterWhere = '';
    	// グループコード条件集合
		Set<String> filterSet = new Set<String>();
		// 指定プロジェックトId集合
		Set<String> projSet = new Set<String>();
		// プロジェックトId前三位
		String projectPrefix = ProjectMain__c.sObjectType.getDescribe().getKeyPrefix();
		// 指定条件あり
    	if (!CommUtils.isBlank(filters)) {
    		List<String> filterArr = filters.split(',');
    		for (String name : filterArr) {
    			// 空値対応
    			if (CommUtils.isBlank(name)) continue;
    			// プロジェックトID対応
    			if (name.contains(projectPrefix)) projSet.add(name);
    			// シフト勤務対応
    			else if (name.equalsIgnoreCase(DEF_STAFF)) staffExpect = true;
    			// その他対応
    			else if (name.equalsIgnoreCase(DEF_OTHER)) otherFlag = true;
    			// 指定グループコード対応
				else filterSet.add(name.trim());
    		}    		
    	}
		if(!filterSet.isEmpty()) filterWhere += ' GroupCode__c = :filterSet ';
		// シフト集合
    	Set<String> staffEvents = new Set<String>();
    	// その他集合
    	Set<String> otherEvents = new Set<String>();
    	// 「シフト勤怠」と「その他」の場合
    	if (staffExpect || otherFlag) {
    		// シフト勤怠データ取得
    		List<StaffSchedule__c> staffs = getUserStaffTask(userids,begDate,endDate);
    		for (StaffSchedule__c staff: staffs) {
    			// シフトと行動関連あり
    			if (!CommUtils.isBlank(staff.EventId__c)) {
    				// 「その他」集合内容追加
    				if (otherFlag) otherEvents.add(staff.EventId__c);
    				// シフト勤怠集合内容追加
    				if (staffExpect) staffEvents.add(staff.EventId__c);
    			}
    		}
    	}
		// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy BEGIN
		List<Event> projpdLst = new List<Event>();
		// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy END
    	// プロジェックトあり
    	if (!projSet.isEmpty()) {
			// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように by zy BEGIN
			// 2020/10/31 担当者を複数設定できるように by zy BEGIN
    		for (ProjectDetail__c pd : [select id,TaskId__c,StartDt__c,UserRef__c,UserRef__r.name,EndDt__c,title__c,CalendarFlg__c,cssStyle__c,createType__c,GroupCode__c,RecurrenceActivityId__c,IsCantUpdFlg__c
						    			,UserRefs__c 
						    			from ProjectDetail__c where ProjectMain__c in : projSet]){
    		// 2020/10/31 担当者を複数設定できるように by zy END	
    			if  (CommUtils.isBlank(pd.TaskId__c)) {
					projpdLst.addAll(convertProjectDetailToEvent(new List<ProjectDetail__c>{pd}));
				}
			// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy END
    			staffEvents.add(pd.TaskId__c);
    		}
    	}
		// シフト集合
    	if (!staffEvents.isEmpty()) {
			String prefix = CommUtils.isBlank(filterWhere) ? ' ' : ' or';
			filterWhere += prefix + ' id in :staffEvents ';
		}
		// その他対応
		if (otherFlag) {
			String prefix = CommUtils.isBlank(filterWhere) ? ' ' : ' or';
			String otherWhere = ' (';
			otherWhere += ' ProjectFlag__c = false and GroupCode__c = null';
			if (!otherEvents.isEmpty()) otherWhere += ' and id != :otherEvents ';
			filterWhere += prefix + otherWhere + ')';
		}
    	// フィルター条件あり
    	if (!CommUtils.isBlank(filterWhere)) taskWhere += ' and (' + filterWhere + ')';
    	String orderSQL = ' order by CreatedDate';
    	List<Event> events = Database.query(taskSQL + taskWhere + orderSQL);
		if (!projpdLst.isEmpty()) events.addAll(projpdLst);
		// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy BEGIN
		String projectWhere = ' where DAY_ONLY(convertTimezone(EndDt__c)) >= :begDate and taskId__c = null ';
    	projectWhere += ' and DAY_ONLY(convertTimezone(StartDt__c)) <= :endDate ';
		if (userids != null && !userids.isEmpty()) projectWhere += ' and UserRef__c =:userids';
		if (!CommUtils.isBlank(fieldName) && fieldValues != null && !fieldValues.isEmpty()) {
			// タスクベース場合、单独更新指定行不含「その他」の場合、GROUPフィルター有効
			// 如果刷新指定行内包含「その他」，则不进行过滤，全部查出来进行处理
			if (!Commutils.isBlank(fieldValues[fieldValues.size() - 1]))
				projectWhere += ' and ' + fieldName + ' =:fieldValues';
		}
		if(!filterSet.isEmpty()) projectWhere += ' and GroupCode__c = :filterSet ';
		events.addAll(convertProjectDetailToEvent(Database.query(projectQuery + projectWhere)));
		// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy END
    	// 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy BEGIN
        return refreshEvent(events); 
	// 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy END
    }
    // 指定条件のシフト自動作成行動取得
    public static List<StaffSchedule__c> getUserStaffTask(List<Id> userSet,Date begDt,Date endDt){
    	List<StaffSchedule__c> staffs = [select EventId__c,id from StaffSchedule__c where WorkDay__c <=:endDt and WorkDay__c >=:begDt and StaffUserRef__c in :userSet and EventId__c != null];
    	return staffs;
    }
    // 指定条件の「その他」行動取得
    public static List<Event> getUserOtherEvent(List<Id> userIds,Date begDt,Date endDt,Set<String> excuteSet){
    	// タスクSQL文
    	String taskSQL = 'select id, OwnerId, Owner.name,ActivityDate,Subject,StartDateTime,EndDateTime,CssStyle__c,RecurrenceActivityId'
    					+ ',IsAllDayEvent,EndDatetime__c,GroupCode__c';
    	taskSQL += ' from Event'; 
    	// 既存条件設定
    	String taskWhere = ' where OwnerId =:userIds and ((EndDatetime__c  = null and DAY_ONLY(convertTimezone(EndDateTime)) >= :begDt ) or (EndDatetime__c != null and DAY_ONLY(convertTimezone(EndDatetime__c)) >= :begDt))';
    	taskWhere += ' and DAY_ONLY(convertTimezone(StartDateTime)) <= :endDt  and IsRecurrence = false and ProjectFlag__c = false and GroupCode__c = null';
    	if (excuteSet != null && !excuteSet.isEmpty()) taskWhere += ' and id not in : excuteSet ';
    	List<Event> events = Database.query(taskSQL + taskWhere);
    	return events;
    }
    // シフト勤怠
    public static String DEF_STAFF = 'STAFF$$99';
    // その他
    public static String DEF_OTHER = 'OTHER$$99';
    // 2018/11/15 マルチタスクの改善対応(スケジュールとタスクの連動、シフトとタスクの分ける）by cxw END
	// 2018/11/15 8.予定と実績を表示させる、させないの切り替え by zy BEGIN
    public static void updDueDatetime(String projectId){
    	// 2019/09/15 Security Check BY zyz BEGIN
    	List<String> chkFieldsLst = new List<String>{'dueenddt__c','duestartdt__c'};
    	Map<String,Schema.SObjectField> mm = Schema.SObjectType.ProjectDetail__c.fields.getMap();
    	if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
    		return ;
    	}
    	// 2019/09/15 Security Check BY zyz END
    	List<PdetailInfo> pds = getProjectLst(projectId,null,null);
    	List<ProjectDetail__c> details = new List<ProjectDetail__c>();
    	for (PdetailInfo info : pds) {
    		info.pd.DueStartDt__c = info.Start;
    		info.pd.DueEndDt__c = info.EndDt;
    		details.add(info.pd);
    	}
    	if (!details.isEmpty()) update details;
    }
    // 2018/11/15 8.予定と実績を表示させる、させないの切り替え by zy END
    	// 2018/11/30 関連書類の紐付け by cxw BEGIN
	public static void removeAttachmentForEvent(Set<String> ids){
		delete [select id, Name, ParentId from Attachment where ParentId = :ids];
	}
	
	public static void removeAttachment(Set<String> ids){
		delete [select id from Attachment where id = :ids];
	}
	public static List<Attachment> queryAttachmentByEvent(Set<String> eventIds){
		return [select id, Name, ParentId from Attachment where ParentId = :eventIds ORDER BY LastModifiedDate ASC NULLS FIRST];
	}
	// 2018/11/30 関連書類の紐付け by cxw END
	// 2018/11/30 行動を範囲選択してコピーできるといい by cxw BEGIN
	public static void updateEvents(Map<String, Event> eventMap){
		List<event> eves = [select id,CustomEventFlag__c from event where id=:eventMap.keySet()];
		for(Event e : eves){
			Event eventForMap = eventMap.get(e.id);
			if(eventForMap == null) continue;
			eventForMap.CustomEventFlag__c = !e.CustomEventFlag__c;
		}
		upsert eventMap.values();
	}
	public static void upsertEvents(List<Event> events){
		upsert events;
	}
	// 2018/11/30 行動を範囲選択してコピーできるといい by cxw END
	// 2019/02/28 プロジェクトリストの並び替え by zy BEGIN
	// 2020/09/30 右上のタスク選択リストに自分が関連するタスクのみ表示機能と検索機能運用が始まると200以上のタスクが作られることが想定されるため探しやすくするため by zy BEGIN
	public static LIst<ProjectMain__c> getProjectMainLst() {
		return getProjectMainLst('');
	}
	public static LIst<ProjectMain__c> getProjectMainLst(String whereSQL) {
	// 2020/09/30 右上のタスク選択リストに自分が関連するタスクのみ表示機能と検索機能運用が始まると200以上のタスクが作られることが想定されるため探しやすくするため by zy END
		List<ProjectMain__c> projectMains = new List<ProjectMain__c>();
		// 2019/03/15 マルチタスクの表示を切り替える by cxw BEGIN
		// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
		// 2020/03/31 プロジェクトオブジェクトのレコードにプロジェクトコードを作成し by zy BEGIN
		String projQuery = projectMainSQL;
		/*
		String projQuery = 'select id,name,AssignUser__c,ManagerUser__c,Describe__c,PlanBaseName__c,IsPublicFlag__c, finish__c, EndDt__c,CalendarFlg__c'
		// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
		// 2019/03/15 マルチタスクの表示を切り替える by cxw END
							+ ',DateMode__c'
							+ ' from ProjectMain__c ';
		// 2020/09/30 右上のタスク選択リストに自分が関連するタスクのみ表示機能と検索機能運用が始まると200以上のタスクが作られることが想定されるため探しやすくするため by zy BEGIN
		*/
		// 2020/03/31 プロジェクトオブジェクトのレコードにプロジェクトコードを作成し by zy END
		if (!CommUtils.isBlank(whereSQL)) projQuery += whereSQL;
		// 2020/09/30 右上のタスク選択リストに自分が関連するタスクのみ表示機能と検索機能運用が始まると200以上のタスクが作られることが想定されるため探しやすくするため by zy END
		String sortStr = getSortString();
		projQuery += ' order by ' + sortStr;
		projectMains = database.query(projQuery);
		return projectMains;
	}
	// 並べ替え機能追加
	public static String getSortString(){
    	String sortString = ' name ';
    	try{
			// XML読み込み
			Dom.XmlNode targetNode = CommXmlUtils.encodeParseXmlDoc('StaffScheduleConfigXml',null,new String[]{'<COONDITION>','</COONDITION>'});
			// 勤怠ボタンの背景と文字の色
			Dom.XmlNode summaryNode;
			for(Dom.XMLNode xmlNode : targetNode.getChildElements()){
				// タグ名
				String attributeName = xmlNode.getName();
				if(attributeName.equalsIgnoreCase('GANTTCONFIG')){
					Dom.XmlNode removeNode = xmlNode.getChildElement('PROJTECTSORT',null);
					if (removeNode != null) {
						String removeStr = CommUtils.nullToBlank(removeNode.getText());
						if (!CommUtils.isBlank(removeStr)) sortString = removeStr;
					}
				}
			}
		} catch(exception e) {}
		return sortString;
    }
    // 2019/02/28 プロジェクトリストの並び替え by zy END
	// 2019/03/15 変更履歴機能追加 by cxw BEGIN
	public static Map<String, Integer> getHistoryCount(Set<Id> projectDetailIds){
		Map<String, Integer> result = new Map<String, Integer>();
		// projectID 不为空, 并且环境中有 ProjectDetail__history Sobject 
		if(!projectDetailIds.isEmpty() && hasSobject(CommConst.APPOTION_NAMESPACE + 'projectdetail__history') ) {
			Map<String, Schema.DescribeFieldResult> sobjResutltMap = CommSqlUtils.getAllFieldLst(ProjectDetail__c.sobjectType,true,true);
			Set<String> fieldNames = new Set<String>();
			for(Schema.DescribeFieldResult dr : sobjResutltMap.values()) {
				fieldNames.add(dr.getName());
			}
			
			String sql = 'select count(id), parentId from ProjectDetail__history where Field =:fieldNames and parentId =:projectDetailIds group by parentId';
			List<AggregateResult> aggregateResult = new List<AggregateResult>();
			aggregateResult = database.query(sql);				
			for(AggregateResult ar : aggregateResult) {
				result.put((String)ar.get('ParentId'), Integer.valueOf(ar.get('expr0')));
			}
		}
		return result;
	}
	
	// 全局描述中是否含有 name
	private static boolean hasSobject(String name) {
		if(CommUtils.isBlank(name)) return false;
		Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
		return gd.containsKey(name.toLowerCase());
	}
	
    public static List<object> getHistory(String sojbectNm,Set<Id> projectSet){
    	String ns = CommConst.APPOTION_NAMESPACE;
    	List<Object> result = new List<Object>();
    	// 履歴SQL文
    	String tableName = sojbectNm.replace('__c','') + '__History';
    	String sqlQuery = 'Select ParentId,Parent.Name, OldValue, NewValue, Field, CreatedDate,CreatedById,CreatedBy.Name From ' + tableName 
    							+ ' where ParentId in :projectSet'
    							+ ' order by ParentId, CreatedDate desc';
    	// projectID 不为空, 并且环境中有 tableName Sobject 
    	if (!projectSet.isEMpty() && hasSobject(ns + tableName)) {
    		//2019/03/15 変更履歴機能追加 by cxw BEGIN
    		String query = CommSqlUtils.generateQueryString(sojbectNm) + ' where id =:projectSet';
			// 変更履歴リスト
    		List<Sobject> sobjs = database.query(sqlQuery);
			// プロジェクト明細リスト
    		List<Sobject> normal = database.query(query);    			
    		Map<String, Sobject> normalMap = new Map<String, Sobject>();
    		for(Sobject s : normal) {
    			normalMap.put((String)s.get('id'), s);
    		}
    		//2019/03/15 変更履歴機能追加 by cxw END
	    	// オブジェクト取得
			Schema.SObjectType sobjectType = new List<Id>(projectSet)[0].getSObjectType();
			Map<String, Schema.DescribeFieldResult> sobjResutltMap = CommSqlUtils.getAllFieldLst(sobjectType,true,true);
	    	for (Sobject s : sobjs) {
	    		// 作成日
	    		String theDate = datetime.valueof(s.get('CreatedDate')).format();
	    		// 作成者
	            Sobject refSobj = s.getSobject('CreatedBy');
	            // 作成者名
	            String who = String.valueOf(refSobj.get('Name'));
	            // プロジェクト明細Id
	            String parentId = CommUtils.nullToBlank(s.get('ParentId'));
	            // プロジェクト明細字段名
	            String fieldName = CommUtils.nullToBlank(s.get('Field')).toLowerCase();
	            if(!CommUtils.isBlank(ns) && fieldName.startsWith(ns)) fieldName = fieldName.substring(ns.length());
	            Schema.DescribeFieldResult sobjResutlt = sobjResutltMap.get(fieldName);
	            // 字段不存在
	            if (sobjResutlt == null) continue;
	            // 字段ラベル
				String fieldLabel = sobjResutlt.getLabel();
				// 字段タイプ
				DisplayType valueType = sobjResutlt.getType();
				Object objValue = s.get('OldValue');
				Object newValue = s.get('NewValue');
	            String oldText = null;
	    		String newText = null;
	    		String action = '';
	    		// 予定特殊対応
	    		if((fieldName == 'duestartdt__c' || fieldName == 'dueenddt__c') && objValue == null) {
	    			try {
	    				objValue = normalMap.get(parentId).get(fieldName == 'duestartdt__c' ? 'startdt__c' : 'enddt__c');
	    			}catch(Exception e) {}
	    		}
	    		//　変更前字段値処理
	    		if (objValue != null) {
	    			// 進捗処理
	    			if(valueType == DisplayType.Percent || fieldName == 'percentcomplete__c') {
	    				// 2019/04/15 変更履歴の進捗率表示対応 by zy BEGIN
						oldText = CommUtils.nullToBlank((CommUtils.nulltoZero(objValue) * 100).round(System.RoundingMode.HALF_EVEN).intValue()) + '%';
	    				// 2019/04/15 変更履歴の進捗率表示対応 by zy END
				} else if(valueType == DisplayType.Date) {
	    				oldText = Date.valueOf(objValue).format();
	    			} else if(valueType == DisplayType.DateTime) {
	    				oldText = DateTime.valueOf(objValue).format();
	    			} else if(valueType == DisplayType.Reference) {
	    				String value = String.valueOf(objValue);
	    				try {
	    					Id.valueOf(value);
	    					continue;
	    				}catch(Exception e) {
	    					oldText = value;
	    				}
	    			} else {
	    				oldText = String.valueOf(objValue);
	    			}
	    		}
	    		//　変更後字段値処理
	    		if (newValue != null) {
					if(valueType == DisplayType.Percent || fieldName == 'percentcomplete__c') {
						// 2019/04/15 変更履歴の進捗率表示対応 by zy BEGIN
						newText = CommUtils.nullToBlank((CommUtils.nulltoZero(newValue) * 100).round(System.RoundingMode.HALF_EVEN).intValue()) + '%';
	    				// 2019/04/15 変更履歴の進捗率表示対応 by zy END
				} else if(valueType == DisplayType.Date) {
	    				newText = Date.valueOf(newValue).format();
	    			} else if(valueType == DisplayType.DateTime) {
	    				newText = DateTime.valueOf(newValue).format();
	    			} else if(valueType == DisplayType.Reference) {
	    				String value = String.valueOf(newValue);
	    				try {
	    					Id.valueOf(value);
	    					continue;
	    				}catch(Exception e) {
	    					newText = value;
	    				}
	    			} else {
	    				newText = String.valueOf(newValue);
	    			}
	    		}
		        // Set the Action value
		        if (oldText != null && newText == null) { // when deleting a value from a field
					// Format the Date and if there's an error, catch it and re
					//の
					//は削除されました。
		           	action = fieldLabel + ' '+ Label.CONST_041_0029 +' ' + CommUtils.nullToBlank(oldText) + ' '+ Label.CONST_041_0030;
				}
		        if(oldText != null && newText != null) {
		        	action = fieldLabel + ' '+ Label.CONST_041_0032 +' ' + CommUtils.nullToBlank(oldText) + ' '+ Label.CONST_041_0031 +' '  + CommUtils.nullToBlank(newText) + ' '+ Label.CONST_041_0033;
		        }
		        if(oldText == null && newText != null || (oldText == newText && newText != null)) {
		        	action = fieldLabel + ' ' + 'は '+ CommUtils.nullToBlank(newText) +' に変更されました。';
		        }
		        if(oldText == null && newText == null) {
		        	action = fieldLabel + ' ' + 'が変更されました。';
		        }
		        
				if(!CommUtils.isBlank(action)) result.add(new Map<String,String>{'who' => who,'date' => theDate , 'action' => action, 'id' => parentId});
	        }
    	}
        return result;
    }
    // 2019/03/15 変更履歴機能追加 by cxw END
    // 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy BEGIN
    private static List<Event> refreshEvent(List<Event> events){
    	Set<String> eventSet = new Set<String> ();
    	for (Event evt : events) {
    		if (CommUtils.isBlank(evt.EventIndex__c)) continue;
    		if (!eventSet.contains(evt.EventIndex__c)) eventSet.add(evt.EventIndex__c);
    	}
    	List<Event> evnts = [select id,StartDateTime,EndDateTime,EventIndex__c from event where EventIndex__c = :eventSet order by StartDateTime];
    	Map<String,Event> eventMap = new Map<String,Event>();
    	for (Event evt : evnts) {
    		if (!eventMap.containsKey(evt.EventIndex__c)) eventMap.put(evt.EventIndex__c,evt);
    		Event orgEvt = eventMap.get(evt.EventIndex__c);
    		if (orgEvt.StartDateTime > evt.StartDateTime) orgEvt.StartDateTime = evt.StartDateTime;
    		if (orgEvt.EndDateTime < evt.EndDateTime) orgEvt.EndDateTime = evt.EndDateTime;
    	}
    	List<Event> filterEvents = new List<Event>();
    	for (Event evt : events) {
    		if (CommUtils.isBlank(evt.EventIndex__c)) filterEvents.add(evt);
    		else if (eventMap.containsKey(evt.EventIndex__c)) {
    			Event orgEvt = eventMap.get(evt.EventIndex__c);
    			evt.StartDateTime = orgEvt.StartDateTime;
    			evt.EndDateTime = orgEvt.EndDateTime;
    			filterEvents.add(evt);
    			eventMap.remove(evt.EventIndex__c);
    			evt.EndDatetime__c = null;
    		}
    	}
    	return filterEvents;
    }
    // 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy END
	// 2019/09/15 マルチタスクで自分専用のグループを作れるようにする(高) by zy BEGIN
	public static String USER_GROUP_SUB = 'usergroup_';
	public static List<UserConfig__c> getUserConfig(String userId,String configId,String spcd){
		String querySQL = 'select id,ConfigInfo__c,FunctionSubType__c from UserConfig__c ';
		String queryWhere = ' where FunctionSubType__c like \'' + USER_GROUP_SUB + '%\'';
		if (!CommUtils.isBlank(spcd)) queryWHere += ' and ShopCode__c =:spcd';
		if (!CommUtils.isBlank(configId)) queryWHere += ' and id =:configId';
		else queryWHere +=  ' and UserRef__c =:userId ';
		return database.query(querySQL + queryWhere);
	}
	public static void updateUserConfig(UserConfig__c config){
		update config;
	}
	public static String insertUserConfig(UserConfig__c config){
		insert config;
		return config.id;
	}
	public static void deleteUserGroup(UserConfig__c config){
		// 2019/09/19 Security Check BY zyz BEGIN
		if (!CommSecurityUtils.isDeleteable(UserConfig__c.getSObjectType())){
			return;
		}
		// 2019/09/19 Security Check BY zyz END
		delete config;
	}
	// 2019/09/15 マルチタスクで自分専用のグループを作れるようにする(高) by zy END
	// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように   by zy BEGIN
	public static Set<String> getExitEventGroup(Date begDate, Date endDate,List<Id> userIds){
		Set<String> eventSet = new Set<String>();
		for (AggregateResult lead: [select CreateType__c type from event where OwnerId =:userids 
                                            and 
                                            	((EndDatetime__c  = null and DAY_ONLY(convertTimezone(EndDateTime)) >= :begDate )
											 or (EndDatetime__c != null and DAY_ONLY(convertTimezone(EndDatetime__c)) >= :begDate))
											 and CreateType__c != null
                                            and DAY_ONLY(convertTimezone(StartDateTime)) <= :endDate  group by CreateType__c]) {
            eventSet.add(CommUtils.nullToBlank(lead.get('type')));
        }
		return eventSet;
	}
	// 2019/12/30 マルチタスク機能、タスクベースの形式に切り替えできるように  by zy END
	// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
	public static String PROJ_MAIN_BASE_NAME = '$$マルチタスクマイ$$';
    // プロジェックト明細リスト
	public static List<ProjectDetail__c> getProjectMainDetails(String projectId){
		String projectWhere = ' where ProjectType__c = null ';
		if (!CommUtils.isBlank(projectId)) projectWhere += ' and ProjectMain__c = :projectId';
		//if (startDt != null) projectWhere += ' and DAY_ONLY(StartDt__c) >=:startDt';
		//if (endDt != null) projectWhere += ' and DAY_ONLY(StartDt__c) <=:endDt';
		projectWhere += ' order by OrderId__c';
		List<ProjectDetail__c> projects = Database.query(projectQuery + projectWhere);
		return projects;
	}
	private static List<Event> convertProjectDetailToEvent(List<ProjectDetail__c> pds){
		List<Event> events = new List<Event>();
		for (ProjectDetail__c pd : pds){
			if  (CommUtils.isBlank(pd.TaskId__c)) {
				Event evt = new Event(Description = JSON.serialize(pd),OwnerId = pd.UserRef__c,Location = pd.UserRef__r.name, StartDateTime = pd.StartDt__c,EndDateTime = pd.EndDt__c,subject = pd.title__c,cssStyle__c = pd.cssStyle__c,createType__c = pd.createType__c,GroupCode__c = pd.GroupCode__c);
				events.add(evt);
			}
		}
		return events;
	}
	public static ProjectMain__c getTaskProjectMain(){
		List<ProjectMain__c> mains = [select id from ProjectMain__c where name = :PROJ_MAIN_BASE_NAME];
		if (!mains.isEmpty()) {
			return mains[0];
		}
		ProjectMain__c main = new ProjectMain__c();
		main.name = PROJ_MAIN_BASE_NAME;
		main.finish__c = true;
		main.IsPublicFlag__c = false;
		insert main;
		return main;
	}
	// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
}