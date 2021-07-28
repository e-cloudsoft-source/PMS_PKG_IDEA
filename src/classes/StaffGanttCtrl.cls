public with sharing class StaffGanttCtrl {
	public Lead__c newLead{get;set;}
	public String curUserId{get;set;}
	public ProjectMain__c projectMain{get;set;}
	public boolean isManager{get;set;}
	public boolean isAssign{get;set;}
	public List<SelectOption> projectOpts{get;set;}
	
	public String mainProjectId{get;set;}
	private UserUtil.UserShopInfo userInf;
	// プロジェックト明細移動対応
	private static String EVENT_TYPE_UP = 'UP';
	private static String EVENT_TYPE_DOWN = 'DOWN';
	private static String EVENT_TYPE_LEFT = 'LEFT';
	private static String EVENT_TYPE_RIGHT = 'RIGHT';
	// プロジェックト明細関連関係取得
	private static String EVENT_TYPE_DEPREAD = 'DEPREAD';
	// プロジェックト明細関連関係作成
	private static String EVENT_TYPE_DEPCREATE = 'DEPCREATE';
	private static String EVENT_TYPE_DEPDESTORY = 'DEPDESTORY';
	private static String EVENT_TYPE_DEPUPDATE = 'DEPUPDATE';
	// プロジェクト明細取得
	private static String EVENT_TYPE_READ = 'READ';
	// プロジェクト明細更新する
	private static String EVENT_TYPE_DTUPDATE = 'DTUPDATE';
	// プロジェックト明細作成
	private static String EVENT_TYPE_DTCREATE = 'DTCREATE';
	// プロジェクト明細削除
	private static String EVENT_TYPE_DTDESTORY = 'DTDESTORY';
	// プロジェックト作成する
	private static String EVENT_TYPE_CREATEPROJECT = 'CREATEPROJECT';
	// タスク→プロジェックト明細作成
	private static String EVENT_TYPE_TASKTOPROJECT = 'TASKTOPROJECT';
	// 検索側タスク取得する
	private static String EVENT_TYPE_GETTASK = 'GETTASK';
	// プロジェックト取得する
	private static String EVENT_TYPE_GETPROJECT = 'GETPROJECT';
	// 担当者とマネージャー取得する
	private static String EVENT_TYPE_GETMANAGER = 'GETMANAGER';
	// プロジェックト担当者
	private static String EVENT_TYPE_GETPJASSIGN = 'GETPJASSIGN';
	// プロジェックト担当者
	private static String EVENT_TYPE_GETPJBYUSER = 'GETPJBYUSER';
	// COOKIE 該当プロジェックト保存
	private static String EVENT_TYPE_SAVECOOKIEPJ = 'SAVECOOKIEPJ';
	// 2018/11/15 顾客最后操作的内容，自动记录 by zy BEGIN
	// COOKIE 該当レイアウト保存
	private static String EVENT_TYPE_SAVECOOKIELY = 'SAVECOOKIELY';
	// COOKIE 該当表示フィルート保存
	private static String EVENT_TYPE_SAVECOOKIEFS = 'SAVECOOKIEFD';
	// COOKIE 該当データ並べ替え保存
	private static String EVENT_TYPE_SAVECOOKIESORT = 'SAVECOOKIESORT';
	// COOKIE 該当プロジェックトタイプ保存
	private static String EVENT_TYPE_SAVECOOKIEPT = 'SAVECOOKIEPT';
	// COOKIE 該当予定と実績状態保存
	private static String EVENT_TYPE_SAVECOOKIEVIEW = 'SAVECOOKIEVIEW';
	// COOKIE 該当担当者保持
	private static String EVENT_TYPE_SAVECOOKIEUSER = 'SAVECOOKIEUSER';
	// 2018/11/15 顾客最后操作的内容，自动记录 by zy END
	// 2018/11/30 関連書類の紐付け by cxw BEGIN
	private static String EVENT_TYPE_ATTACHMENT = 'ATTACHMENT';
	private static String EVENT_TYPE_ATTACHMENT_DELETE = 'ATTACHMENT_DELETE';
	// 2018/11/30 関連書類の紐付け by cxw END
	// 2018/11/30 行動を範囲選択してコピーできるといい。 by cxw BEGIN
	private static String EVENT_TYPE_DTUPDATE_ALL = 'DTUPDATE_ALL';
	// 2018/11/30 行動を範囲選択してコピーできるといい。 by cxw END
	// 2020/09/31 画面スクロールを２分割したい by zy BEGIN
	public StaffGanttCtrl(){
		// 予定と実績
		initTaskViewSetting();
	}
	// 2020/09/31 画面スクロールを２分割したい by zy END
	// 初期化
	public void init(){
		// 2019/03/15 マルチタスクの表示を切り替える by cxw BEGIN
		finishMode = false;
		// 2019/03/15 マルチタスクの表示を切り替える by cxw END
		// 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy BEGIN
		Map<String,String> parMap = ApexPages.currentPage().getParameters();
	   	if (parMap.containsKey('eventindex')) {
	   		String eventIndex = CommUtils.nullToBlank(parMap.get('eventindex'));
	   		if (!CommUtils.isBlank(eventIndex)) {
	   			Set<String> eventId = new Set<String>();
	   			for (Event evt : [select id from Event where eventIndex__c = :eventIndex]){
	   				eventId.add(evt.id);
	   			}
	   			if (!eventId.isEmpty()) {
	   				List<ProjectDetail__c> details = [select id,ProjectMain__c from ProjectDetail__c where taskId__c = :eventId];
	   				if (!details.isEmpty()) pProjectId = details[0].ProjectMain__c;
	   				ProjectMain__c main = StaffTaskHelp.getProjectMain(pProjectId);
	   				if (main != null) {
	   					finishMode = main.finish__c;
	   				}
	   			}
	   		}
	   	}
		// 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy END
		// 2020/10/30 プロジェクトオブジェクトのレコードにプロジェクトコードを作成し by zy BEGIN
		loadXmlInfo();
		// 2020/10/30 プロジェクトオブジェクトのレコードにプロジェクトコードを作成し by zy END
		doAction();
	}
	// データ処理
	private void doAction(){
		initInfo();
	}
	private void initInfo(){
		isManager = false;
		isAssign = false;
		userInf = UserUtil.CurrentUserInfo;
		projectOpts = new List<SelectOption>();
		newLead = new Lead__c(SearchDate__c = system.today());
		projectMain = null;
		// 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy BEGIN
		String projectId = !CommUtils.isBlank(pProjectId) ? pProjectId : getCookieProjectId();
		// 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy END
		// 2020/08/31 担当部署列の追加、ユーザに紐づく部署ではなく、選択リストを引用するように by zy BEGIN
		//部署リスト内容作成
		departOptJson = '';
		List<Schema.PicklistEntry> entrys = Schema.SObjectType.ProjectDetail__c.fields.Department__c.getPicklistValues();
		Set<String> departOpts = new Set<String>();
		for(Schema.PicklistEntry entry : entrys) {
			departOpts.add( entry.getValue());
		}
		if (!departOpts.isEmpty()) departOptJson = JSON.serialize(departOpts);
		// 2020/10/30 2.14.特定日のマーキング機能、スケジュールのなかでポイントをうち、右の表示マークをつける機能 by zy BEGIN
		// 字段設定内容取得
		entrys = Schema.SObjectType.ProjectDetail__c.fields.MarkType__c.getPicklistValues();
		Set<String> markOpts = new Set<String>();
		// 内容フィルター
		for(Schema.PicklistEntry entry : entrys) {
			markOpts.add( entry.getValue());
		}
		// マーク選択リスト内容
		if (!markOpts.isEmpty()) markJsons = JSON.serialize(markOpts);
		// 2020/10/30 2.14.特定日のマーキング機能、スケジュールのなかでポイントをうち、右の表示マークをつける機能 by zy END
		// 2020/08/31 担当部署列の追加、ユーザに紐づく部署ではなく、選択リストを引用するように by zy END
		curUserId = userInf.u.id;
		boolean userTopRoleFlag = userInf.u.StaffScheduleAllEdit__c;
		// Cookie　プロジェックトIDあり
		if (!CommUtils.isBlank(projectId)) {
			ProjectMain__c main = StaffTaskHelp.getProjectMain(projectId);
			if (main != null) {
				isManager = CommUtils.nullToBlank(main.ManagerUser__c).contains(curUserId);
				isAssign = CommUtils.nullToBlank(main.AssignUser__c).contains(curUserId);
				if (isAssign || isManager || main.IsPublicFlag__c){
					// 2019/03/15 マルチタスクの表示を切り替える by cxw BEGIN
					if(main.finish__c == finishMode) {
					// 2019/03/15 マルチタスクの表示を切り替える by cxw END
						// 2020/09/31 画面スクロールを２分割したい by zy BEGIN
						if ((isPublicFlg && (isAssign || isManager)) || !isPublicFlg) {
							projectMain = main; 
							projectOpts.add(new SelectOption(main.id,main.name));
						}
						// 2020/09/31 画面スクロールを２分割したい by zy END
					}
				}
			}
		} 
		if (projectMain == null){
			// 2019/03/15 マルチタスクの表示を切り替える by cxw BEGIN
			List<ProjectMain__c> projs = StaffTaskHelp.getMainPorjects(curUserId,userTopRoleFlag);
			List<ProjectMain__c> mains = new List<ProjectMain__c>();
			for(ProjectMain__c p : projs) {
				// 2020/09/31 画面スクロールを２分割したい by zy BEGIN
				if(p.finish__c == finishMode) {
					boolean pIsManager = CommUtils.nullToBlank(p.ManagerUser__c).contains(curUserId);
					boolean pIsAssign = CommUtils.nullToBlank(p.AssignUser__c).contains(curUserId);
					if ((isPublicFlg && (pIsAssign || pIsManager)) || !isPublicFlg) {
						mains.add(p);
					}
				}
				// 2020/09/31 画面スクロールを２分割したい by zy END
			}
			// 2019/03/15 マルチタスクの表示を切り替える by cxw END
			if (!mains.isEmpty()) {
				projectMain = mains[0];
				isManager = CommUtils.nullToBlank(projectMain.ManagerUser__c).contains(curUserId);
				isAssign = CommUtils.nullToBlank(projectMain.AssignUser__c).contains(curUserId);
				saveCookieProjectId(projectMain.id);
				projectOpts.add(new SelectOption(projectMain.id,projectMain.name));
			}
		}
		if (projectMain == null) projectMain = new ProjectMain__c(StartDt__c = system.today(),endDt__c = system.today());
		mainProjectId = projectMain.id;
		// 2018/11/30 時間軸を日にした際に時間単位で表示される。日単位で切り替えできるように改善対応 by zy BEGIN
		// 日付切替モード設定
		projectMode = CommUtils.nullToBlank(projectMain.DateMode__c);
		// 2018/11/30 時間軸を日にした際に時間単位で表示される。日単位で切り替えできるように改善対応 by zy END
		// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
		isCalenDarFlg = projectMain.CalendarFlg__c ? CALENDAR_HIDE_LABEL : CALENDAR_SHOW_LABEL;
		// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
		// 2019/07/15 プロジェクト明細のURLをプロジェクト管理画面から出力できるように陣屋コネクトとしての改善要望です。 by zy BEGIN
		chatterOpts = new List<SelectOption>();
		List<CollaborationGroup> chatterGroups = [select Id, Name from CollaborationGroup where isarchived = false];
		for(CollaborationGroup gp : chatterGroups) {
			chatterOpts.add(new SelectOption(gp.id,gp.name));
		}
		// 2019/07/15 プロジェクト明細のURLをプロジェクト管理画面から出力できるように陣屋コネクトとしての改善要望です。 by zy END
		// 2018/11/15 顾客最后操作的内容，自动记录 by zy BEGIN
		// レイアウト内容
		initCookieInfo();
		// 2018/11/15 顾客最后操作的内容，自动记录 by zy END
	}
	//　カスタム設定タスク時間範囲取得
	private static Integer getHourLen(){
		integer hours = 2;
		try{
			// XML読み込み
			Dom.XmlNode targetNode = CommXmlUtils.encodeParseXmlDoc('StaffScheduleConfigXml',null,new String[]{'<COONDITION>','</COONDITION>'});
			// 勤怠ボタンの背景と文字の色
			Dom.XmlNode summaryNode;
			for(Dom.XMLNode xmlNode : targetNode.getChildElements()){
				// タグ名
				String attributeName = xmlNode.getName();
				if(attributeName.equalsIgnoreCase('GANTTCONFIG')){
					Dom.XmlNode hourNode = xmlNode.getChildElement('DAYSBETWEEN',null);
					if (hourNode != null) hours = CommUtils.nullToIntZero(hourNode.getText());
				}
			}
		} catch(exception e) {}
		return hours;
	}
	// カスタムデファルトタスク名前取得
	private static String getTaskName(){
		String defTaskName = '新規行動';
		try{
			// XML読み込み
			Dom.XmlNode targetNode = CommXmlUtils.encodeParseXmlDoc('StaffScheduleConfigXml',null,new String[]{'<COONDITION>','</COONDITION>'});
			// 勤怠ボタンの背景と文字の色
			Dom.XmlNode summaryNode;
			for(Dom.XMLNode xmlNode : targetNode.getChildElements()){
				// タグ名
				String attributeName = xmlNode.getName();
				if(attributeName.equalsIgnoreCase('GANTTCONFIG')){
					Dom.XmlNode taskNode = xmlNode.getChildElement('EVENT_TITLE',null);
					if (taskNode != null) defTaskName = CommUtils.nullToBlank(taskNode.getText());
				}
			}
		} catch(exception e) {}
		return defTaskName;
	}
	@remoteaction
	public static List<Object> taskFunction(String functionType,String dataReq){
		List<Object> response = new List<Object>();
		// プロジェクト明細取得
		if (functionType == EVENT_TYPE_READ) response = getPorjectDetails(dataReq);
		// プロジェックト明細作成
		else if (functionType == EVENT_TYPE_DTCREATE) response = createProjectDetail(dataReq);
		// プロジェクト明細更新する
		else if (functionType == EVENT_TYPE_DTUPDATE) response = updateProjectDetail(dataReq);
		// プロジェクト明細削除
		else if (functionType == EVENT_TYPE_DTDESTORY) response = destoryProject(dataReq);
		// プロジェックト明細関連関係取得
		else if (functionType == EVENT_TYPE_DEPREAD) response = getDependencie(dataReq);
		// プロジェックト明細関連関係作成
		else if (functionType == EVENT_TYPE_DEPCREATE) createProjectDep(dataReq);
		// プロジェックト明細関連関係作成
		else if (functionType == EVENT_TYPE_DEPDESTORY) deleteProjectDep(dataReq);
		// 検索側タスク取得する
		else if (functionType == EVENT_TYPE_GETTASK) response = getTasks(dataReq);
		// タスク→プロジェックト明細作成
		else if (functionType == EVENT_TYPE_TASKTOPROJECT) response = taskToProjectDetail(dataReq);
		// プロジェックト作成する
		else if (functionType == EVENT_TYPE_CREATEPROJECT) response = createProject(dataReq);
		// プロジェックト取得する
		else if (functionType == EVENT_TYPE_GETPROJECT) response = getProject(dataReq);
		// 担当者とマネージャー取得する
		else if (functionType == EVENT_TYPE_GETMANAGER) response = getManagers(dataReq);
		// プロジェックト担当者
		else if (functionType == EVENT_TYPE_GETPJASSIGN) response = getProjectAssings(dataReq);
		// 担当者のプロジェックトリスト
		else if (functionType == EVENT_TYPE_GETPJBYUSER) response = getProjectsByUser(dataReq);
		// COOKIE 該当プロジェックト保存
		else if (functionType == EVENT_TYPE_SAVECOOKIEPJ) remoteSaveProjectId(dataReq);
		// 2018/11/15 顾客最后操作的内容，自动记录 by zy BEGIN
		// COOKIE 該当レイアウト保存
		else if (functionType == EVENT_TYPE_SAVECOOKIELY) remoteSaveLayout(dataReq);
		// COOKIE 該当表示フィルート保存
		else if (functionType == EVENT_TYPE_SAVECOOKIEFS) remoteSaveFieds(dataReq);
		// COOKIE 該当データ並べ替え保存
		else if (functionType == EVENT_TYPE_SAVECOOKIESORT) remoteSaveFiedSort(dataReq);
		// COOKIE 該当プロジェックトタイプ保存
		else if (functionType == EVENT_TYPE_SAVECOOKIEPT) remoteSaveType(dataReq);
		// COOKIE 該当予定と実績状態保存
		else if (functionType == EVENT_TYPE_SAVECOOKIEVIEW) remoteSaveTaskView(dataReq);
		// COOKIE 該当担当者保持
		else if (functionType == EVENT_TYPE_SAVECOOKIEUSER) remoteSaveUserId(dataReq);
		// 2018/11/15 顾客最后操作的内容，自动记录 by zy END
		// 2018/11/30 関連書類の紐付け by cxw BEGIN
		else if (functionType == EVENT_TYPE_ATTACHMENT) response = remoteAttachment(dataReq);
		else if (functionType == EVENT_TYPE_ATTACHMENT_DELETE) response = remoteDelAttachment(dataReq);
		// 2018/11/30 関連書類の紐付け by cxw END
		// 2018/11/30 行動を範囲選択してコピーできるといい by cxw BEGIN
		else if(functionType == EVENT_TYPE_DTUPDATE_ALL) response = updateAll(dataReq);
		// 2018/11/30 行動を範囲選択してコピーできるといい by cxw END
		// 2018/12/30 拡大機能[+/-]ボタンにより、ZOOMのバーにより、全体はズーム機能 by cxw BEGIN
		else if (functionType == 'saveCookieInfo') saveRemoteCookieInfo(dataReq);
		// 2018/12/30 拡大機能[+/-]ボタンにより、ZOOMのバーにより、全体はズーム機能 by cxw END
		// 2019/03/15 変更履歴機能追加 by cxw BEGIN
		else if (functionType == 'getProjectHistory') response = getProjectHistory(dataReq);
		// 2019/03/15 変更履歴機能追加 by cxw END
		// 2019/07/15 プロジェクト明細のURLをプロジェクト管理画面から出力できるように陣屋コネクトとしての改善要望です。 by zy BEGIN
		// CHATTER
		else if (functionType == 'chatterPostItem') return chatterPostItem(dataReq);
		else if (functionType == 'getProjectUsers') return getProjectUsers(dataReq);
		else if (functionType == 'preCheckChatter') return preCheckChatter(dataReq);
		// 2019/07/15 プロジェクト明細のURLをプロジェクト管理画面から出力できるように陣屋コネクトとしての改善要望です。 by zy END
		// 2020/10/31 2.07.取引先の紐付け by zy BEGIN
		else if (functionType == 'getAccount') return getAccount(dataReq);
		// 2020/10/31 2.07.取引先の紐付け by zy END
		return response;
	}
	// プロジェクト明細取得
	private static List<Object> getPorjectDetails(String dataReq){
		List<Object> response = new List<Object>();
		ProjectMain main = (ProjectMain)JSON.deserializeStrict(dataReq,ProjectMain.class);
		String projectId = main.projectid;
		Date startDt = CommUtils.stringtodate(main.startDt);
		Date endDt = CommUtils.stringtodate(main.endDt);
		List<StaffTaskHelp.PdetailInfo> projects = StaffTaskHelp.getProjectLst(projectId,startDt,endDt);
		// 2018/11/30 関連書類の紐付け by cxw BEGIN
		Set<String> eventids = new Set<String>();
		// 2019/03/15 変更履歴機能追加 by cxw BEGIN
		Set<Id> dataIds = new Set<Id>();
		for(StaffTaskHelp.PdetailInfo pd : projects) {
			eventids.add(pd.pd.TaskId__c);
			dataIds.add(pd.pd.id);
		}
		// 2019/03/15 変更履歴機能追加 by cxw END
		Map<String, List<AttachmentStruct>> attInfoMap = queryEventAttachment(eventids);
		// 2019/03/15 変更履歴機能追加 by cxw BEGIN
		Map<String, Integer> historyMap = StaffTaskHelp.getHistoryCount(dataIds);
		// 2019/03/15 変更履歴機能追加 by cxw END
		// 2018/11/30 関連書類の紐付け by cxw END
		for (StaffTaskHelp.PdetailInfo pd : projects) {
			// 2018/11/30 関連書類の紐付け by cxw BEGIN
			// response.add(makeMapByProject(pd));
			Map<String,Object> result = makeMapByProject(pd);
			if(result.containsKey('eventid') && attInfoMap.containsKey(String.valueOf(result.get('eventid')))) result.put('isExistAtt', true);
			// 2019/03/15 変更履歴機能追加 by cxw BEGIN
			if(historyMap.containsKey(pd.pd.id) && historyMap.get(pd.pd.id) > 0) result.put('history', true);
			// 2019/03/15 変更履歴機能追加 by cxw END
			response.add(result);
			// 2018/11/30 関連書類の紐付け by cxw END
		}
		return response;
	}
	private static List<Object> updateProjectDetail(String dataReq){
		List<Object> response = new List<Object>();
		ProjectInfo p = (ProjectInfo)JSON.deserializeStrict(dataReq,ProjectInfo.class);
		StaffTaskHelp.PdetailInfo detail = StaffTaskHelp.getProjectDetail(p.dataid);
		ProjectDetail__c curProj = detail.pd;
		// 2018/11/15 編集画面保存bug修正 by zy BEGIN
		Datetime stDt = null;
		Datetime endDt = null;
		if (p.StartDt != null) stDt = Datetime.newInstance(p.StartDt);
		if (p.EndDt != null) endDt = Datetime.newInstance(p.EndDt);
		// 2018/11/15 編集画面保存bug修正 by zy END
		// 2018/07/23 タスク終了日時字段変更　by zy BEGIN
    	Integer maxMiuteLen = 14 * 24 * 60;
		// 2018/07/23 タスク終了日時字段変更　by zy END
		if (curProj != null) {
			// 2019/03/15 変更履歴機能追加 by cxw BEGIN
			curProj = new ProjectDetail__c(id = curProj.id);
			// 2019/03/15 変更履歴機能追加 by cxw END
			curProj.OrderId__c = p.OrderId;
			curProj.ParentProject__c = p.parentDataId;
			curProj.PercentComplete__c = p.PercentComplete;
			curProj.Summary__c = p.Summary;
			// 2018/11/15 17.プロジェクト管理を開いたときにタスクが開いた状態から始まる by zy BEGIN
			curProj.Expanded__c = p.Expanded;
			// 2018/11/15 17.プロジェクト管理を開いたときにタスクが開いた状態から始まる by zy END
			// 2019/1/15 プロジェックト機能のPriority(重要度）列を追加 by cxw BEGIN
			curProj.Importance__c = p.importance;
			// 2019/1/15 プロジェックト機能のPriority(重要度）列を追加 by cxw END
			// 2018/11/15 8.予定と実績を表示させる、させないの切り替え by zy BEGIN
			if (p.dueStart != null) curProj.DueStartDt__c = Datetime.newInstance(p.dueStart);
			if (p.dueEnd != null) curProj.DueEndDt__c =  Datetime.newInstance(p.dueEnd);
			// 2018/11/15 8.予定と実績を表示させる、させないの切り替え by zy END
			// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
			if (p.CalendarFlg != null) curProj.CalendarFlg__c = p.CalendarFlg == CALENDAR_HIDE_LABEL;
			// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
			if (detail.evt != null) {
				if (p.userid != null && p.userid != '') {
					detail.evt.ownerid = p.userid;
					// 2019/03/15 変更履歴機能追加 by cxw BEGIN
					curProj.UserRef__c = p.userid;
					// 2019/03/15 変更履歴機能追加 by cxw END
				}
				// 2019/03/15 変更履歴機能追加 by cxw BEGIN
				if (endDt != null) {
					detail.evt.EndDatetime__c = endDt;
					curProj.EndDt__c = endDt;
				}
				// 2019/03/15 変更履歴機能追加 by cxw END
				if (stDt != null) {
					detail.evt.StartDatetime = stDt;
					// 2019/03/15 変更履歴機能追加 by cxw BEGIN
					curProj.StartDt__c = stDt;
					// 2019/03/15 変更履歴機能追加 by cxw END
					// 2018/07/23 タスク終了日時字段変更　by zy BEGIN	
					/*
					if (detail.evt.StartDatetime.date().daysBetween(detail.evt.endDatetime.date()) > 14) {
						if (detail.evt.endDatetime__c == null) detail.evt.endDatetime__c = detail.evt.endDatetime;
						detail.evt.endDatetime = detail.evt.StartDatetime.addDays(13);
					} else{
						detail.evt.endDatetime = detail.evt.StartDatetime.addDays(1);
					}*/
					// 2018/07/23 タスク終了日時字段変更　by zy END
				}
				if (!CommUtils.isBlank(p.Title)) {
					detail.evt.subject = p.Title;
					// 2019/03/15 変更履歴機能追加 by cxw BEGIN
					curProj.title__c = p.Title;
					// 2019/03/15 変更履歴機能追加 by cxw END
				}
				// 2018/07/23 タスク終了日時字段変更　by zy BEGIN	
				if (endDt != null && stDt != null) {
					Integer durMinutes = CommUtils.nullToIntZero((endDt.getTime() - stDt.getTime())/ (60 *1000));
					detail.evt.DurationInMinutes = durMinutes > maxMiuteLen ? maxMiuteLen : durMinutes;
					detail.evt.EndDateTime = stDt.addMinutes(detail.evt.DurationInMinutes);
					if (detail.evt.IsAllDayEvent) detail.evt.IsAllDayEvent = false;
				}
				// 2018/07/23 タスク終了日時字段変更　by zy END
				// 2018/08/07 進捗メモ追加　by zy BEGIN
				if (!CommUtils.isBlank(p.comment)) detail.evt.Description = p.comment;
				// 2018/08/07 進捗メモ追加　by zy END
				StaffTaskHelp.updEvent(detail.evt);
			} else if (detail.taskObj != null) {
				if (p.userid != null && p.userid != '') {
					detail.taskObj.ownerid = p.userid;
					// 2019/03/15 変更履歴機能追加 by cxw BEGIN
					curProj.UserRef__c = p.userid;
					// 2019/03/15 変更履歴機能追加 by cxw END
				}
				if (stDt != null) {
					detail.taskObj.ActivityDate = stDt.date();
					// 2019/03/15 変更履歴機能追加 by cxw BEGIN
					curProj.StartDt__c = stDt;
					// 2019/03/15 変更履歴機能追加 by cxw END
					// ToDo 開始時刻保存用
					detail.taskObj.TaskStartTime__c = stDt.format('HH:mm');
				}
				// 2019/03/15 変更履歴機能追加 by cxw BEGIN
				if (endDt != null) {
					detail.taskObj.EndDatetime__c = endDt;
					curProj.EndDt__c = endDt;
				}
				// 2019/03/15 変更履歴機能追加 by cxw END
				if (!CommUtils.isBlank(p.Title)) {
					detail.taskObj.subject = p.Title;
					// 2019/03/15 変更履歴機能追加 by cxw BEGIN
					curProj.title__c = p.Title;
					// 2019/03/15 変更履歴機能追加 by cxw END
				}
				// 2018/08/07 進捗メモ追加　by zy BEGIN
				if (!CommUtils.isBlank(p.comment)) detail.taskObj.Description = p.comment;
				// 2018/08/07 進捗メモ追加　by zy END	
				StaffTaskHelp.updateChangeTasks(new List<Task>{detail.taskObj});
			// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
			} else {
				if (p.userid != null && p.userid != '') curProj.UserRef__c = p.userid;
				if (stDt != null) curProj.StartDt__c = stDt;
				if (endDt != null) curProj.EndDt__c = endDt;
				if (!CommUtils.isBlank(p.Title)) curProj.title__c = p.Title;
				// 2018/08/07 進捗メモ追加　by zy BEGIN
				if (!CommUtils.isBlank(p.comment)) curProj.Comment__c = p.comment;
			}
			// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
			// 2020/08/31 担当部署列の追加、ユーザに紐づく部署ではなく、選択リストを引用するように by zy BEGIN
			curProj.Department__c = p.depart;
			// 2020/08/31 担当部署列の追加、ユーザに紐づく部署ではなく、選択リストを引用するように by zy END
			// 2020/10/30 2.14.特定日のマーキング機能、スケジュールのなかでポイントをうち、右の表示マークをつける機能 by zy BEGIN
			curProj.marks__c = CommUtils.nullToblank(p.marks).unescapeXml();
			// 2020/10/30 2.14.特定日のマーキング機能、スケジュールのなかでポイントをうち、右の表示マークをつける機能 by zy END
			// 2020/10/31 担当者を複数設定できるように by zy BEGIN
			curProj.userRefs__c = p.userids;
			// 2020/10/31 担当者を複数設定できるように by zy END
			// 2020/10/31 タスク単位でマネージャー、担当者を設定できるようにする。設定していない場合はその親プロジェクトの権限を参照する。 by zy BEGIN
			curProj.AssignUser__c = CommUtils.nullToBlank(p.assign);
			curProj.ManagerUser__c = CommUtils.nullToBlank(p.manager);
			// 2020/10/31 タスク単位でマネージャー、担当者を設定できるようにする。設定していない場合はその親プロジェクトの権限を参照する。 by zy END
			// 更新明細
			StaffTaskHelp.updateProjectDetail(curProj);
		}
		StaffTaskHelp.PdetailInfo detainInfo = StaffTaskHelp.getProjectDetail(curProj.id);
		response.add(makeMapByProject(detainInfo));
		return response;
	}
	// プロジェクト明細削除
	private static List<Object> destoryProject(String dataReq){
		ProjectMain pm = (ProjectMain)JSON.deserializeStrict(dataReq,ProjectMain.class);
		List<StaffTaskHelp.PdetailInfo> curProjs = StaffTaskHelp.getProjects(pm.tasks);
		// 2018/11/30 関連書類の紐付け by cxw BEGIN
		Set<String> eventids = new Set<String>();
		// 2018/12/15 削除タスク順序不計算修正 by cxw BEGIN
		Set<String> parentIds = new Set<String>();
		Set<String> refreshParentsSet = new Set<String>();
		if(pm.refreshParents != null ) refreshParentsSet.addAll(pm.refreshParents);
		for(StaffTaskHelp.PdetailInfo p : curProjs){
			eventids.add(p.pd.TaskId__c);
			if(refreshParentsSet.contains(p.pd.id)) parentIds.add(p.pd.ParentProject__c);
		}
		// 2018/12/15 削除タスク順序不計算修正 by cxw END
		StaffTaskHelp.removeAttachmentForEvent(eventids);
		// 2018/11/30 関連書類の紐付け by cxw END
		StaffTaskHelp.deleteProjects(curProjs);
		// 2018/12/15 削除タスク順序不計算修正 by cxw BEGIN
		if(!parentIds.isEmpty()){
			Map<String, List<ProjectDetail__c>> refreshMap = StaffTaskHelp.getOrderDetailsForParents(pm.projectid, parentIds);
			List<ProjectDetail__c> updateItems = new List<ProjectDetail__c>();
			for(String parentId : refreshMap.keySet()){
				List<ProjectDetail__c> pds = refreshMap.get(parentId);
				for(Integer i = 0; i < pds.size(); i++) pds.get(i).OrderId__c = i;
				updateItems.addAll(pds);
			}
			if(!updateItems.isEmpty()) StaffTaskHelp.updateProjectDetail(updateItems);
		}
		// 2018/12/15 削除タスク順序不計算修正 by cxw END
		List<Object> response = new List<Object>();
		List<StaffTaskHelp.PdetailInfo> projects = StaffTaskHelp.getProjectLst(pm.projectid,null,null);
		for (StaffTaskHelp.PdetailInfo pd : projects) {
			response.add(makeMapByProject(pd));
		}
		return response;
	}
	// プロジェックト明細作成
	private static List<Object> createProjectDetail(String dataReq){
		Savepoint sp = Database.setSavepoint();
		List<Object> response = new List<Object>();
		Map<String,Object> dataRequest = (Map<String,Object>)JSON.deserializeUntyped(dataReq);
		// プロジェックトID
		String projectId = CommUtils.nullToBlank(dataRequest.get('projectid'));
		String dataId = CommUtils.nullToBlank(dataRequest.get('dataid'));
		String userId = UserUtil.CurrentUserInfo.u.id;
		String viewType = CommUtils.nullToBlank(dataRequest.get('view'));
		List<ProjectDetail__c> updDetails = new List<ProjectDetail__c>();
		// 利用id取得該当プロジェックト
		ProjectMain__c pm = StaffTaskHelp.getProjectMain(projectId);
		// 2018/11/15 14.タスクの移動がドラッグでできるが、望むところに移動せず、動かすつもりのないタスクも動 by zy BEGIN
		String newDetailId;
		// 2018/11/15 14.タスクの移動がドラッグでできるが、望むところに移動せず、動かすつもりのないタスクも動 by zy END
		try{
			// 選択プロジェックト取得
			StaffTaskHelp.PdetailInfo detail = StaffTaskHelp.getProjectDetail(dataId);
			ProjectDetail__c p = new ProjectDetail__c();
			Datetime startDt = System.now();
			// 2018/11/30 時間軸を日にした際に時間単位で表示される。日単位で切り替えできるように改善対応 by zy BEGIN
			Datetime endDt = System.now().addHours(getHourLen());
			if (viewType != 'day') {
				startDt = CommUtils.convertDatetime(System.today(),'00:00');
				endDt = CommUtils.convertDatetime(System.today(),'23:59');
			}
			// 2018/11/30 時間軸を日にした際に時間単位で表示される。日単位で切り替えできるように改善対応 by zy END
			// 選択プロジェックト明細あり
			if (detail != null) {
				ProjectDetail__c selPj = detail.pd;
				// 選択プロジェックト明細コピー
				p.OrderID__c = selPj.OrderID__c + 1;
				// 选中任务的子级
				p.ParentProject__c = selPj.ParentProject__c;
				startDt = detail.start;
				endDt = detail.endDt;
			} else {
				ProjectDetail__c lastPd = StaffTaskHelp.getLastOrderDetail(projectId,null);
				if (lastPd != null) p.OrderId__c = CommUtils.nullToZero(lastPd.OrderId__c) +1;
				// 2018/11/15 タスクの移動がドラッグでできるが、望むところに移動せず by zy BEGIN
				// else p.OrderId__c = 1;
				else p.OrderId__c = 0;
				// 2018/11/15 タスクの移動がドラッグでできるが、望むところに移動せず by zy END
			}
			p.PercentComplete__c = 0;
			//p.Title__c = getTaskName();
			p.ProjectMain__c = projectId;
			updDetails = StaffTaskHelp.getAfterCureentOrderDetails(p.OrderId__c,projectId,p.ParentProject__c);
			if (!updDetails.isEmpty()) {
				for (ProjectDetail__c pd : updDetails) {
					pd.OrderId__c += 1;
				}
				StaffTaskHelp.updateProjectDetail(updDetails);
			}
			// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
			String calenDarText = CommUtils.nullToBlank(dataRequest.get('calendarFlg'));
			p.calendarFlg__c = calenDarText == CALENDAR_HIDE_LABEL;
			// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
			// 該当ユーザ「プロジェックト担当者リスト」含むの場合
			Event ev = new Event();
			ev.OwnerId = userId;
			ev.Subject = getTaskName();
			ev.StartDateTime = startDt;
			// 2018/11/30 時間軸を日にした際に時間単位で表示される。日単位で切り替えできるように改善対応 by zy BEGIN
			//ev.EndDateTime = endDt;
			ev.EndDateTime = CommUtils.eventSafeEndDateTm(startDt,endDt);
			// 2018/11/30 時間軸を日にした際に時間単位で表示される。日単位で切り替えできるように改善対応 by zy END
			ev.EndDatetime__c = endDt;
			ev.ProjectFlag__c = true;
			StaffTaskHelp.updEvent(ev);
			p.taskId__c = ev.id;
			p.EventType__c = StaffTaskHelp.EVENT_TYPE_EVENT;
			//2019/03/15 変更履歴機能追加 by cxw BEGIN
			p.Title__c = ev.Subject;
			p.StartDt__c = ev.StartDateTime;
			p.EndDt__c = ev.EndDatetime__c;
			p.UserRef__c = ev.OwnerId;
			//2019/03/15 変更履歴機能追加 by cxw END
			// 2020/08/31 担当部署列の追加、ユーザに紐づく部署ではなく、選択リストを引用するように by zy BEGIN
			p.Department__c = CommUtils.nullToBlank(dataRequest.get('depart'));
			// 2020/08/31 担当部署列の追加、ユーザに紐づく部署ではなく、選択リストを引用するように by zy END
			// 新規プロジェックト明細
			StaffTaskHelp.insertProjectDetail(p);
			// 2018/11/15 14.タスクの移動がドラッグでできるが、望むところに移動せず、動かすつもりのないタスクも動 by zy BEGIN
			newDetailId = p.id;
			// 2018/11/15 14.タスクの移動がドラッグでできるが、望むところに移動せず、動かすつもりのないタスクも動 by zy END
			// プロジェックト親明細
			StaffTaskHelp.refreshParentNodeByLst(new List<ProjectDetail__c>{p});
		} catch(exception e) {
			Database.rollBack(sp);
			throw New CommException(CommUtils.getFieldValidationMessage(e.getMessage()));
		}
		List<StaffTaskHelp.PdetailInfo> projects = StaffTaskHelp.getProjectLst(projectId,null,null);
		for (StaffTaskHelp.PdetailInfo pd : projects) {
			// 2018/11/15 14.タスクの移動がドラッグでできるが、望むところに移動せず、動かすつもりのないタスクも動 by zy BEGIN
			Map<String,Object> makeMapByProject = makeMapByProject(pd);
			if (!CommUtils.isBlank(newDetailId) && pd.pd.id == newDetailId) makeMapByProject.put('newFlag',true);
			response.add(makeMapByProject);
			// 2018/11/15 14.タスクの移動がドラッグでできるが、望むところに移動せず、動かすつもりのないタスクも動 by zy END
		}
		return response;
	}
	// プロジェックト明細関連関係取得
	private static List<Object> getDependencie(String dataReq){
		Map<String,Object> dataRequest = (Map<String,Object>)JSON.deserializeUntyped(dataReq);
		String projectId = (String)dataRequest.get('projectid');
		return getDependencies(projectId);
	}
	private static List<Object> getDependencies(String projectId){
		List<Map<String,Object>> infos = new List<Map<String,Object>>();
		List<ProjectDetail__c> projects = StaffTaskHelp.getDependencie(null,projectId);
		for (ProjectDetail__c pro : projects) {
			Integer objId = CommUtils.nullToIntZero(pro.name);
			Map<String,object> evet = new Map<String,Object>{'ID' => objId,'dataid' => pro.id,'PredecessorID' => CommUtils.nullToIntZero(pro.PreRowNo__c)
																,'SuccessorID' => CommUtils.nullToIntZero(pro.NextRowNo__c),'Type' => CommUtils.nullToIntZero(pro.ProjectType__c)};
			infos.add(evet);
		}
		return infos;
	}
	// プロジェックト明細関連関係作成
	private static List<Object> createProjectDep(String dataReq){
		Map<String,Object> dataRequest = (Map<String,Object>)JSON.deserializeUntyped(dataReq);
		String projectId = (String)dataRequest.get('projectid');
		ProjectDetail__c p = new ProjectDetail__c();
		p.PreRowNo__c = CommUtils.nullToBlank(CommUtils.nullToIntZero(dataRequest.get('PredecessorID')));
		p.NextRowNo__c = CommUtils.nullToBlank(CommUtils.nullToIntZero(dataRequest.get('SuccessorID')));
		p.ProjectType__c = CommUtils.nullToBlank(CommUtils.nullToIntZero(dataRequest.get('Type')));
		p.projectMain__c = projectId;
		StaffTaskHelp.insertProjectDetail(p);
		return getDependencies(projectId);
	}
	// プロジェックト明細関連関係作成
	private static List<Object> deleteProjectDep(String dataReq) {
		Map<String,Object> dataRequest = (Map<String,Object>)JSON.deserializeUntyped(dataReq);
		String projectId = (String)dataRequest.get('projectid');
		String dataId = (String)dataRequest.get('dataid');
		StaffTaskHelp.deleteDependencie(dataId);
		return getDependencies(projectId);
	}
	// 検索側タスク取得する
	private static List<Object> getTasks(String dataReq){
		List<Object> objMaps = new List<Object>();
		Map<String,Object> dataRequest = (Map<String,Object>)JSON.deserializeUntyped(dataReq);
		Date startDt = CommUtils.stringtodate((String)dataRequest.get('start'));
		Date endDt = CommUtils.stringtodate((String)dataRequest.get('end'));
		String userId = (String)dataRequest.get('userid');
		String selectType = (String)dataRequest.get('type');
		String contactId =  (String)dataRequest.get('contactid');
		String taskName = (String) dataRequest.get('taskname');
		if (!CommUtils.isBlank(taskName)) taskName = '%' + taskName + '%';
		// what id 前三位== account开始才可以设名字
		String accountPrex = Account.sObjectType.getDescribe().getKeyPrefix();
		if (selectType == '1') { 
			List<Event> events = StaffTaskHelp.getEvents(userId,contactId,taskName,startDt,endDt);
			for (event eve : events) {
				String whatName = '';
				// 2018/07/23 バグ修正日付=nullの場合エラー発生修正　by　zy BEGIN
				String startDtStr = '';
				String endDtStr = '';
				Datetime endDateTime = eve.EndDateTime__c;
				if (endDateTime == null) endDateTime = eve.EndDateTime;
				if (eve.StartDateTime != null) startDtStr = eve.StartDateTime.format('yyyy/MM/dd');
				if (endDateTime != null) endDtStr = endDateTime.format('yyyy/MM/dd');
				// 2018/07/23 バグ修正日付=nullの場合エラー発生修正　by　zy END
				if (CommUtils.nullToBlank(eve.whatid).startsWith(accountPrex)) whatName = CommUtils.nullToBlank(eve.What.Name);
				Map<String,object> evet = new Map<String,Object>{'id' => eve.id,'name' => eve.subject,'CreateBy' => eve.Owner.name,
										// 2018/07/23 バグ修正日付=nullの場合エラー発生修正　by　zy BEGIN
										//'startDate' => eve.StartDateTime.format('yyyy/MM/dd'),'endDate' =>   eve.EndDateTime.format('yyyy/MM/dd'),
										'startDate' => startDtStr,'endDate' => endDtStr,
										// 2018/07/23 バグ修正日付=nullの場合エラー発生修正　by　zy END
										'PercentComplete' => '0.43','CssStyle' => eve.CssStyle__c,'userid' => eve.OwnerId,'DoBy' => whatName}; 
				objMaps.add(evet);
			}
		} else {
			List<Task> events = StaffTaskHelp.getTasks(userId,contactId,taskName,startDt,endDt);
			for (Task eve : events) {
				String whatName = '';
				// 2018/07/23 バグ修正日付=nullの場合エラー発生修正　by　zy BEGIN
				String startDtStr = '';
				String endDtStr = '';
				// 2018/07/23 バグ修正日付=nullの場合エラー発生修正　by　zy END
				Date endDateTime = eve.ActivityDate;
				if (eve.EndDateTime__c != null) endDateTime = eve.EndDateTime__c.date();
				// 2018/07/23 バグ修正日付=nullの場合エラー発生修正　by　zy BEGIN
				if (eve.ActivityDate != null) startDtStr = eve.ActivityDate.format();
				if (endDateTime != null) endDtStr = endDateTime.format();
				// 2018/07/23 バグ修正日付=nullの場合エラー発生修正　by　zy END
            	if (CommUtils.nullToBlank(eve.whatid).startsWith(accountPrex)) whatName = CommUtils.nullToBlank(eve.What.Name);
				Map<String,object> evet = new Map<String,Object>{'id' => eve.id,'name' => eve.subject,'CreateBy' => eve.Owner.name,
										// 2018/07/23 バグ修正日付=nullの場合エラー発生修正　by　zy BEGIN
										//'startDate' => eve.ActivityDate.format(),'endDate' =>   eve.ActivityDate.format(),
										'startDate' => startDtStr,'endDate' => endDtStr,
										// 2018/07/23 バグ修正日付=nullの場合エラー発生修正　by　zy END
										'PercentComplete' => '0.43','userid' => eve.OwnerId,'DoBy' => whatName}; 
				objMaps.add(evet);
			}
		}
		return objMaps; 
	}
	// タスク→プロジェックト明細作成
	private static List<Object> taskToProjectDetail(String dataReq){
		ProjectMain main = (ProjectMain)JSON.deserializeStrict(dataReq,ProjectMain.class);
		String selType = main.seltype == '1' ? StaffTaskHelp.EVENT_TYPE_EVENT : StaffTaskHelp.EVENT_TYPE_TODO;
		List<ProjectDetail__c> peojects = new List<ProjectDetail__c>();
		ProjectDetail__c pd = StaffTaskHelp.getLastOrderDetail(main.projectid,null);
		Decimal maxOrder = 0;
		// 2018/11/15 タスクの移動がドラッグでできるが、望むところに移動せず by zy BEGIN
		if (pd != null) {
			maxOrder = pd.orderId__c;
			maxOrder += 1;
		}
		// 2018/11/15 タスクの移動がドラッグでできるが、望むところに移動せず by zy END
		// 2018/11/15 14.タスクの移動がドラッグでできるが、望むところに移動せず、動かすつもりのないタスクも動 by zy BEGIN
		String newDetailId;
		// 2018/11/15 14.タスクの移動がドラッグでできるが、望むところに移動せず、動かすつもりのないタスクも動 by zy END
		Set<String> noAssignSet = new Set<String>();
		// 未追加プロジェックト担当者
		ProjectMain__c curMain = StaffTaskHelp.getProjectMain(main.projectid);
		if (curMain != null) {
			noAssignSet.addAll(CommUtils.nullToBlank(curMain.AssignUser__c).split(','));
		}
		// 2020/08/31 担当部署列の追加、ユーザに紐づく部署ではなく、選択リストを引用するように by zy BEGIN
		Map<String,String> departMap = main.depart != null ? main.depart : new Map<String,String>();
		// 2020/08/31 担当部署列の追加、ユーザに紐づく部署ではなく、選択リストを引用するように by zy END
		if (selType == StaffTaskHelp.EVENT_TYPE_EVENT) {
			List<event> events = StaffTaskHelp.getEvents(main.tasks);
			for (event ev : events) {
				if (!noAssignSet.contains(ev.ownerid)) noAssignSet.add(ev.ownerid);
				// 2018/11/15 タスクの移動がドラッグでできるが、望むところに移動せず by zy BEGIN
				//maxOrder++;
				// 2018/11/15 タスクの移動がドラッグでできるが、望むところに移動せず by zy END
				ProjectDetail__c p = new ProjectDetail__c();
				p.OrderId__c = maxOrder;
				p.PercentComplete__c = 0;
				//p.Title__c = ev.subject;
				p.TaskId__c = ev.id;
				p.ProjectMain__c = main.projectid;
				p.EventType__c = StaffTaskHelp.EVENT_TYPE_EVENT;
				// 2020/08/31 担当部署列の追加、ユーザに紐づく部署ではなく、選択リストを引用するように by zy BEGIN
				p.Department__c = departMap.get(ev.ownerId);
				// 2020/08/31 担当部署列の追加、ユーザに紐づく部署ではなく、選択リストを引用するように by zy END
				peojects.add(p);
				ev.ProjectFlag__c = true;
				// 2018/11/15 タスクの移動がドラッグでできるが、望むところに移動せず by zy BEGIN
				maxOrder++;
				// 2018/11/15 タスクの移動がドラッグでできるが、望むところに移動せず by zy END
			}
			StaffTaskHelp.updateEvents(events);
		} else {
			List<Task> events = StaffTaskHelp.getTasks(main.tasks);
			for (Task ev : events) {
				if (!noAssignSet.contains(ev.ownerid)) noAssignSet.add(ev.ownerid);
				// 2018/11/15 タスクの移動がドラッグでできるが、望むところに移動せず by zy BEGIN
				//maxOrder++;
				// 2018/11/15 タスクの移動がドラッグでできるが、望むところに移動せず by zy END
				ProjectDetail__c p = new ProjectDetail__c();
				p.OrderId__c = maxOrder;
				p.PercentComplete__c = 0;
				//p.Title__c = ev.subject;
				p.TaskId__c = ev.id;
				p.ProjectMain__c = main.projectid;
				p.EventType__c = StaffTaskHelp.EVENT_TYPE_TODO;
				// 2020/08/31 担当部署列の追加、ユーザに紐づく部署ではなく、選択リストを引用するように by zy BEGIN
				p.Department__c = departMap.get(ev.ownerId);
				// 2020/08/31 担当部署列の追加、ユーザに紐づく部署ではなく、選択リストを引用するように by zy END
				peojects.add(p);
				ev.ProjectFlag__c = true;
				// 2018/11/15 タスクの移動がドラッグでできるが、望むところに移動せず by zy BEGIN
				maxOrder++;
				// 2018/11/15 タスクの移動がドラッグでできるが、望むところに移動せず by zy END
			}
			StaffTaskHelp.updateChangeTasks(events);
		}
		/*
		if (curMain != null) {
			String assignUser = '';
			for (String userId : noAssignSet) {
				if (!CommUtils.isBlank(userId)) assignUser += userId + ',';
			}
			curMain.AssignUser__c = assignUser.removeEnd(',');
			StaffTaskHelp.updateProjectMain(curMain);
		}*/
		StaffTaskHelp.insertProjectDetail(peojects);
		// 2018/11/15 14.タスクの移動がドラッグでできるが、望むところに移動せず、動かすつもりのないタスクも動 by zy BEGIN
		if (!peojects.isEmpty()) newDetailId = peojects[peojects.size() - 1].id;
		// 2018/11/15 14.タスクの移動がドラッグでできるが、望むところに移動せず、動かすつもりのないタスクも動 by zy END
		List<Object> reponse = new List<Object>();
		List<StaffTaskHelp.PdetailInfo> projects = StaffTaskHelp.getProjectLst(main.projectid,null,null);
		for (StaffTaskHelp.PdetailInfo detailInfo : projects) {
			// 2018/11/15 14.タスクの移動がドラッグでできるが、望むところに移動せず、動かすつもりのないタスクも動 by zy BEGIN
			Map<String,Object> makeMapByProject = makeMapByProject(detailInfo);
			if (!CommUtils.isBlank(newDetailId) && detailInfo.pd.id == newDetailId) makeMapByProject.put('newFlag',true);
			reponse.add(makeMapByProject);
			// reponse.add(makeMapByProject(detailInfo));
			// 2018/11/15 14.タスクの移動がドラッグでできるが、望むところに移動せず、動かすつもりのないタスクも動 by zy END
		}
		return reponse;
	}
	// プロジェックト作成する
	private static List<Object> createProject(String dataReq){
		ProjectMain dataRequest = (ProjectMain)JSON.deserializeStrict(dataReq,ProjectMain.class);
		String projectId = dataRequest.projectid;
		ProjectMain__c main = new ProjectMain__c();
		main.name = dataRequest.name;
		main.AssignUser__c = dataRequest.users;
		main.startDt__c = CommUtils.StringtoDate(dataRequest.startDt);
		main.endDt__c = CommUtils.StringtoDate(dataRequest.endDt);
		main.Describe__c = CommUtils.nullToBlank(dataRequest.pDesc);
		main.IsPublicFlag__c = dataRequest.pub;
		main.ManagerUser__c = dataRequest.managerName;
		// 2018/11/30 時間軸を日にした際に時間単位で表示される。日単位で切り替えできるように改善対応 by zy BEGIN
		main.DateMode__c = boolean.valueOf(CommUtils.nullToBlank(dataRequest.dateMode));
		// 2018/11/30 時間軸を日にした際に時間単位で表示される。日単位で切り替えできるように改善対応 by zy END
		// 2019/03/15 マルチタスクの表示を切り替える by cxw BEGIN
		if(dataRequest.finish == null) dataRequest.finish = false;
		main.finish__c = boolean.valueOf(dataRequest.finish);
		// 2020/10/31 タスク単位でマネージャー、担当者を設定できるようにする。設定していない場合はその親プロジェクトの権限を参照する。 by zy BEGIN
		main.RoleDetailFlg__c = boolean.valueOf(CommUtils.nullToBlank(dataRequest.roleDetailFlg));
		// 2020/10/31 タスク単位でマネージャー、担当者を設定できるようにする。設定していない場合はその親プロジェクトの権限を参照する。 by zy END
		// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
		if (dataRequest.calendarFlg != null) main.CalendarFlg__c = dataRequest.calendarFlg;
		// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
		// 2020/03/31 プロジェクトオブジェクトのレコードにプロジェクトコードを作成し by zy BEGIN
		if (!CommUtils.isBlank(dataRequest.record)) {
			Map<String, Schema.DescribeFieldResult> sobjResutltMap = CommSqlUtils.getAllFieldLst(ProjectMain__c.sobjectType,true,true,true);
			Schema.DescribeFieldResult ds = sobjResutltMap.get(dataRequest.record.toLowerCase());
			if (ds != null && !ds.isAutoNumber()) main.put(dataRequest.record,CommUtils.nullToBLank(dataRequest.title));
		}
		// 2019/03/15 マルチタスクの表示を切り替える by cxw END
		try {
			if (CommUtils.isBlank(projectId)) StaffTaskHelp.insertProjectMain(main);
			else {
				main.id = projectId;
				StaffTaskHelp.updateProjectMain(main);
			}
		} catch(exception e) {
			String msg = validateMessage(KEY_DUPLICATE_VALUE,e.getMessage());
			throw new CommException(msg);
		}
		// 2020/03/31 プロジェクトオブジェクトのレコードにプロジェクトコードを作成し by zy END
		saveCookieProjectId(main.id);
		// 2020/03/31 プロジェクトオブジェクトのレコードにプロジェクトコードを作成し by zy BEGIN
	 	if (!CommUtils.isBlank(dataRequest.record)) main = StaffTaskHelp.getProjectMain(main.id);
		ProjectMain pm = convertProjectMain(main);
		if (!CommUtils.isBlank(dataRequest.record)) pm.record = Commutils.nullToBlank(main.get(dataRequest.record));
		return new List<ProjectMain>{pm};
		// 2020/03/30 プロジェクトオブジェクトのレコードにプロジェクトコードを作成し by zy END
	}
	// プロジェックト取得する
	private static List<Object> getProject(String dataReq){
		// 2020/10/31 プロジェクトオブジェクトのレコードにプロジェクトコードを作成し by zy BEGIN
		Map<String, String> req = (Map<String, String>)JSON.deserializeStrict(dataReq, Map<String, String>.class);
		String projectId = req.get('id');
		String fieldName = req.get('record');
		// 2020/10/31 プロジェクトオブジェクトのレコードにプロジェクトコードを作成し by zy END
		
		List<Object> response = new List<Object>();
		if (!CommUtils.isBlank(projectId)) {
			ProjectMain__c main = StaffTaskHelp.getProjectMain(projectId);
			if (main != null) {
				ProjectMain pm = new ProjectMain();
				pm.name = main.name;
				pm.projectid = main.id;
				if (main.startDt__c != null) pm.startDt = main.startDt__c.format();
				if (main.endDt__c != null) pm.endDt = main.endDt__c.format();
				List<Map<String,String>> userLst = new List<Map<String,String>>();
				List<String> userIds = new List<String>();
				if (!CommUtils.isBlank(main.AssignUser__c)) pm.users = CommUtils.nullToBlank(main.AssignUser__c);
				if (!CommUtils.isBlank(main.ManagerUser__c)) pm.managerName = CommUtils.nullToBlank(main.ManagerUser__c);
				pm.pDesc = CommUtils.nullToblank(main.Describe__c);
				pm.pub = main.IsPublicFlag__c;
				// 2018/11/30 時間軸を日にした際に時間単位で表示される。日単位で切り替えできるように改善対応 by zy BEGIN
				pm.dateMode = CommUtils.nullToBlank(main.DateMode__c);
				// 2018/11/30 時間軸を日にした際に時間単位で表示される。日単位で切り替えできるように改善対応 by zy END
				// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
				pm.calendarFlg = main.CalendarFlg__c;
				// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
				pm.finish = main.finish__c;
				// 2020/10/30 プロジェクトオブジェクトのレコードにプロジェクトコードを作成し by zy BEGIN
				if (!CommUtils.isBlank(fieldName)) pm.record = Commutils.nullTOBlank(main.get(fieldName));
				// 2020/10/30 プロジェクトオブジェクトのレコードにプロジェクトコードを作成し by zy END
				// 2020/10/31 タスク単位でマネージャー、担当者を設定できるようにする。設定していない場合はその親プロジェクトの権限を参照する。 by zy BEGIN
				pm.roleDetailFlg = main.RoleDetailFlg__c;
				// 2020/10/31 タスク単位でマネージャー、担当者を設定できるようにする。設定していない場合はその親プロジェクトの権限を参照する。 by zy END
				response.add(pm);
			}
		}
		return response;
	}
	
	// 担当者とマネージャー取得する
	private static List<Object> getManagers(String dataReq){
		List<Object> response = new List<Object>();
		
        Map<String,User> staffMap = new Map<String,User>();
		// 関連ユーザー一覧情報を取得する
        List<User> userLst = StaffTaskHelp.getAllActiveUsers(null);
        for (User u : userLst) {
        	staffMap.put(u.id,u);
        }
        String projectId = (String)JSON.deserialize(dataReq,String.class);
        UserUtil.UserShopInfo userInf = UserUtil.CurrentUserInfo;
		// 私有プロジェックト
		List<ProjectMain__c> priveteProjects = StaffTaskHelp.getProjectMainLst(false);
		Set<String> assignRoleSet = new Set<String>();
		Set<String> managerRoleSet = new Set<String>();
		Set<String> lastRoleSet = new Set<String>();
		List<String> managerLst = new List<String>();
		List<String> assignLst = new List<String>();
		Map<String ,ProjectMain__c> projectMap = new Map<String ,ProjectMain__c>();
		for (ProjectMain__c projectMain : priveteProjects) {
			projectMap.put(projectMain.id,projectMain);
			// マネージャー
			String managerUser = CommUtils.nullToBlank(projectMain.ManagerUser__c);
			List<String> managers = managerUser.split(',');
			if (managerUser.contains(userInf.u.id)) {
				managerLst.addAll(managers);
				managerRoleSet.addAll(managers);
			} else lastRoleSet.addAll(managers);
			// 担当者
			String assignUser = CommUtils.nullToBlank(projectMain.AssignUser__c);
			List<String> assigns = assignUser.split(',');
			if (assignUser.contains(userInf.u.id)) {
				assignLst.addAll(assigns);
				assignRoleSet.addAll(assigns);
			} else lastRoleSet.addAll(assigns);
		}
		
		// マネージャーリスト作成
		// 常用マネージャー頂上
		response.addAll(createUserLst(managerLst,staffMap));
		response.addAll(createUserLst(assignLst,staffMap));
		response.addAll(createUserLst(new List<String>(lastRoleSet),staffMap));
		for (User u : staffMap.values()) {
			if (!managerRoleSet.contains(u.id) && !assignRoleSet.contains(u.id) && !lastRoleSet.contains(u.id) ) 
				response.add(new Map<String,String>{'text' => u.name,'value' => u.id });
		}
		return response;
	}
	private static List<Object> createUserLst(List<String> users,Map<String,user> staffMap){
		List<Object> response = new List<Object>();
		if (!users.isEmpty()) {
			for (String userId : users) {
				User u = staffMap.get(userId);
				if (u != null) {
					response.add(new Map<String,String>{'text' => u.name,'value' => u.id });
					staffMap.remove(userId);
				}
			}
		}
		return response;
	}
	// 获取project下所有user
	private static List<Object> getProjectAssings(String dataReq) {
		List<Object> response = new List<Object>();
		String projectId = (String) JSON.deserialize(dataReq,String.class);
		ProjectMain__c projectMain = StaffTaskHelp.getProjectMain(projectId);
		Set<String> userIds = new Set<String>();
		if (projectMain != null) {
			userIds = new Set<String>(CommUtils.nullToBlank(projectMain.AssignUser__c).split(','));
			userIds.addAll(CommUtils.nullToBlank(projectMain.ManagerUser__c).split(','));
		}
		response = getUserLst(userIds);
		return response;
	}
	// 担当者のプロジェックトリスト
	private static List<object> getProjectsByUser(String dataReq){
		Map<string, string> parms = (Map<string, string>) JSON.deserialize(dataReq,Map<string, string>.class);
		List<object> response = new List<object>();
		String userId = UserUtil.CurrentUserInfo.u.id;
		boolean userTopRoleFlag = UserUtil.CurrentUserInfo.u.StaffScheduleAllEdit__c;
		// 2019/03/15 マルチタスクの表示を切り替える by cxw BEGIN
		boolean finishFlag = boolean.valueOf(CommUtils.nullToBlank(parms.get('finishMode')));
		// 2019/03/15 マルチタスクの表示を切り替える by cxw END
		// 2020/09/30 右上のタスク選択リストに自分が関連するタスクのみ表示機能と検索機能運用が始まると200以上のタスクが作られることが想定されるため探しやすくするため by zy BEGIN
		boolean publicFlag = boolean.valueOf(CommUtils.nullToBlank(parms.get('publicMode')));
		String filterText = CommUtils.nullToBlank(parms.get('filterValue'));
		String whereSQL = ' where (id != null ';
		String projectId = CommUtils.nullToBlank(parms.get('projectId'));
		if (!CommUtils.isBlank(filterText)) whereSQL += ' and name like \'' + filterText + '%\'';
		whereSQL += ')';
		if (!CommUtils.isBlank(projectId)) whereSQL += ' or id = \'' + projectId + '\'';
		integer limitInt = null;
		// 私有プロジェックト
		List<ProjectMain__c> priveteProjects = StaffTaskHelp.getMainPorjects(userId,userTopRoleFlag,whereSQL);
		// 2020/09/30 右上のタスク選択リストに自分が関連するタスクのみ表示機能と検索機能運用が始まると200以上のタスクが作られることが想定されるため探しやすくするため by zy END
		// 2020/10/31 プロジェクトオブジェクトのレコードにプロジェクトコードを作成し by zy BEGIN
		String recordName = CommUtils.nullToBlank(parms.get('record'));
		// 2020/10/31 プロジェクトオブジェクトのレコードにプロジェクトコードを作成し by zy END
		List<object> data = new List<object>();
		Integer otherLen = 0;
		for (ProjectMain__c main : priveteProjects) {
			String manaUser = CommUtils.nullToBlank(main.ManagerUser__c);
			String assignUser = CommUtils.nullToBlank(main.AssignUser__c);
			// 2019/03/15 マルチタスクの表示を切り替える by cxw BEGIN
			// 2020/09/30 右上のタスク選択リストに自分が関連するタスクのみ表示機能と検索機能運用が始まると200以上のタスクが作られることが想定されるため探しやすくするため by zy BEGIN
			// 开关有效，过滤不是个人参加的project且公开的
			if (publicFlag && !manaUser.contains(userId) && !assignUser.contains(userId)) continue;
			if(finishFlag == main.finish__c) {
				if (limitInt != null && limitInt <= 0 && main.id != projectId) continue;
				else if (limitInt != null) limitInt--;
				// 2020/09/30 右上のタスク選択リストに自分が関連するタスクのみ表示機能と検索機能運用が始まると200以上のタスクが作られることが想定されるため探しやすくするため by zy END
				// 2020/10/31 プロジェクトオブジェクトのレコードにプロジェクトコードを作成し by zy BEGIN
				String projectName = main.name;
				if (!CommUtils.isBlank(recordName)) {
					String record = CommUtils.nullToBlank(main.get(recordName));
					if (!CommUtils.isBlank(record)) projectName += '(' + record + ')';
				}
				data.add(new Map<String,Object>{'text'=> projectName,'value'=>main.id,'ismanager' => manaUser.contains(userId),'isAssign' => assignUser.contains(userId), 'isFinish' => main.finish__c
					// 2020/10/31 タスク単位でマネージャー、担当者を設定できるようにする。設定していない場合はその親プロジェクトの権限を参照する。 by zy BEGIN
					,'roleDetailFlg' => main.RoleDetailFlg__c == true
					// 2020/10/31 タスク単位でマネージャー、担当者を設定できるようにする。設定していない場合はその親プロジェクトの権限を参照する。 by zy END
				});
				// 2020/10/31 プロジェクトオブジェクトのレコードにプロジェクトコードを作成し by zy END
			} else otherLen++;
			// 2019/03/15 マルチタスクの表示を切り替える by cxw END
		}
		// 2019/03/15 マルチタスクの表示を切り替える by cxw BEGIN
		// 2020/09/30 右上のタスク選択リストに自分が関連するタスクのみ表示機能と検索機能運用が始まると200以上のタスクが作られることが想定されるため探しやすくするため by zy BEGIN
		Map<string, object> obj = new Map<string, object>{'data'=>data, 'otherlen'=>otherLen };
		response.add(obj);
		// 2020/09/30 右上のタスク選択リストに自分が関連するタスクのみ表示機能と検索機能運用が始まると200以上のタスクが作られることが想定されるため探しやすくするため by zy END
		// 2019/03/15 マルチタスクの表示を切り替える by cxw END
		return response;
	}
	// COOKIE 該当プロジェックト保存
	private static void remoteSaveProjectId(String dataReq){
		String projectId = (String) JSON.deserialize(dataReq,String.class);
		saveCookieProjectId(projectId);
	}
	// 2018/11/15 顾客最后操作的内容，自动记录 by zy BEGIN
	// COOKIE 該当レイアウト保存
	private static void remoteSaveLayout(String dataReq){
		CookieInfo projectInfo = (CookieInfo) JSON.deserialize(dataReq,CookieInfo.class);
		saveCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.PROJECTLAYOUT.name(),JSON.serialize(projectInfo));
	}
	// COOKIE 該当表示フィルート保存
	private static void remoteSaveFieds(String dataReq){
		// Cookieからレイアウトモードを取得する
		saveCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.PROJECTFIELD.name(), dataReq);
	}
	// COOKIE 該当データ並べ替え保存
	private static void remoteSaveFiedSort(String dataReq){
		// Cookieからレイアウトモードを取得する
		saveCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.PROJECTFIELDSORT.name(), dataReq);
	}
	// COOKIE 該当プロジェックトタイプ保存
	private static void remoteSaveType(String dataReq){
		// Cookieからレイアウトモードを取得する
		saveCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.PROJECTTYPE.name(), dataReq);
	}
	// COOKIE 該当予定と実績状態保存
	private static void remoteSaveTaskView(String dataReq){
		// Cookieからレイアウトモードを取得する
		saveCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.PROJECTVIEWFLG.name(), dataReq);
	}
	// COOKIE 該当担当者保持
	private static void remoteSaveUserId(String dataReq){
		saveCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.PROJECTUSER.name(), dataReq);
	}
	// 2018/11/15 顾客最后操作的内容，自动记录 by zy END
	private static List<Object> getUserLst(Set<String> userSet){
		List<Object> response = new List<Object>();
		response.add(new Map<String,String>{'UserName'=> Label.MSG_005_0035,'UserId'=> ''});
		if (userSet != null && !userSet.isEmpty()) {
			for(User u : StaffTaskHelp.getAllActiveUsers(new List<String>(userSet))) {
				response.add(new Map<String,String>{'UserName'=> u.name,'UserId'=>u.id});
			}
		}
		return response;
	}
	// プロジェックト作成する
	private static ProjectMain convertProjectMain(ProjectMain__c main){
		ProjectMain pm = new ProjectMain();
		String userId = UserUtil.CurrentUserInfo.u.id;
		// 2020/10/31 プロジェクトオブジェクトのレコードにプロジェクトコードを作成し by zy BEGIN
		main = StaffTaskHelp.getProjectMain(main.id);
		// 2020/10/31 プロジェクトオブジェクトのレコードにプロジェクトコードを作成し by zy END
		if (CommUtils.nullToBlank(main.ManagerUser__c).contains(userId) 
			|| CommUtils.nullToBlank(main.AssignUser__c).contains(userId)
			|| main.IsPublicFlag__c) {
			pm.name = main.name;
			pm.projectid = main.id;
			if (main.startDt__c != null) pm.startDt = main.startDt__c.format();
			if (main.endDt__c != null) pm.endDt = main.endDt__c.format();
		}
		// 2018/11/30 時間軸を日にした際に時間単位で表示される。日単位で切り替えできるように改善対応 by zy BEGIN
		pm.dateMode = CommUtils.nullToBlank(main.DateMode__c);
		// 2018/11/30 時間軸を日にした際に時間単位で表示される。日単位で切り替えできるように改善対応 by zy END
		// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
		pm.calendarFlg = main.CalendarFlg__c;
		// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
		// 2020/10/31 タスク単位でマネージャー、担当者を設定できるようにする。設定していない場合はその親プロジェクトの権限を参照する。 by zy BEGIN
		pm.roleDetailFlg = main.RoleDetailFlg__c;
		// 2020/10/31 タスク単位でマネージャー、担当者を設定できるようにする。設定していない場合はその親プロジェクトの権限を参照する。 by zy END
		return pm;
	}
	public static List<Map<String,Object>> getProjects(String dataId){
		List<Map<String,Object>> infos = new List<Map<String,Object>>();
		StaffTaskHelp.PdetailInfo detail = StaffTaskHelp.getProjectDetail(dataId);
		if (detail != null ) {
			Map<String,Object> proj = makeMapByProject(detail);
			infos.add(proj);
		}
		return infos;
	}
	// プロジェックト明細→画面用JSON
	private static Map<String,Object> makeMapByProject(StaffTaskHelp.PdetailInfo taskDetail){
		ProjectDetail__c eve = taskDetail.pd;
		Integer objId = CommUtils.nullToIntZero(eve.name);
		// 正常
		String curStatus = '4';
		Datetime startDt = taskDetail.Start;
		Datetime endDt = taskDetail.EndDt;
		String startDtStr = '';
		String endDtStr = '';
		String descript = '';
		if (startDt != null) {
			startDtStr = '/Date(' + startDt.getTime() + ')/';
		}
		String ownerId = '';
		String ownerName = '';
		String eventTitle = '';
		// 2018/08/07 進捗メモ追加　by zy BEGIN
		String comment = '';
		// 2018/08/07 進捗メモ追加　by zy END	
		// 2018/11/15 8.予定と実績を表示させる、させないの切り替え by zy BEGIN
		Datetime dueStartDt;
		Datetime dueEndDt;
		// 2018/11/15 8.予定と実績を表示させる、させないの切り替え by zy END
		if (taskDetail.evt != null) {
			// 2018/07/23 バグ修正日付=nullの場合エラー発生修正　by　zy END
			ownerId = CommUtils.nullToBlank(taskDetail.evt.ownerid);
			ownerName = CommUtils.nullToBlank(taskDetail.evt.owner.name);
			eventTitle = CommUtils.nullToBlank(taskDetail.evt.subject);
			// 2018/08/07 進捗メモ追加　by zy BEGIN
			comment = CommUtils.nullToBlank(taskDetail.evt.Description);
			// 2018/08/07 進捗メモ追加　by zy END
		}
		if (taskDetail.taskObj != null) {
			ownerId = CommUtils.nullToBlank(taskDetail.taskObj.ownerid);
			ownerName = CommUtils.nullToBlank(taskDetail.taskObj.owner.name);
			eventTitle = CommUtils.nullToBlank(taskDetail.taskObj.subject);
			// 2018/08/07 進捗メモ追加　by zy BEGIN
			comment = CommUtils.nullToBlank(taskDetail.taskObj.Description);
			// 2018/08/07 進捗メモ追加　by zy END
		}
		// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
		if (taskDetail.taskObj == null && taskDetail.evt == null) {
			ownerId = CommUtils.nullToBlank(taskDetail.pd.UserRef__c);
			ownerName = CommUtils.nullToBlank(taskDetail.pd.UserRef__r.name);
			eventTitle = CommUtils.nullToBlank(taskDetail.pd.Title__c);
			// 進捗メモ追加　
			comment = CommUtils.nullToBlank(taskDetail.pd.Comment__c);
		}
		// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
		// 2020/10/31 担当者を複数設定できるように by zy BEGIN
		String assigneds = '';
		if (!taskDetail.userNameSet.isEmpty()) {
			assigneds = String.join(new List<String>(taskDetail.userNameSet),',');
		}
		// 2020/10/31 担当者を複数設定できるように by zy END
		// 2020/10/31 2.07.取引先の紐付け by zy BEGIN
		String accnames = '';
		if (!taskDetail.accNames.isEmpty()) {
			accnames = String.join(new List<String>(taskDetail.accNames),',');
		}
		// 2020/10/31 2.07.取引先の紐付け by zy END
		Date todayDt = system.today();
		if (endDt != null) {
			// 延迟
			if ( todayDt > endDt.date()) curStatus = '3';
			// 着手中
			else if (todayDt >= startDt.date()){
				// 时间总长
				Decimal totalDays = startDt.date().daysbetween(endDt.date()) + 1;
				// 已用时
				Decimal daysBetween = startDt.date().daysbetween(todayDt) + 1;
				// 当前完成率 = 已用时/时间总长;
				decimal curPercent = daysBetween/totalDays;
				Decimal percentComplete = CommUtils.nullToZero(eve.PercentComplete__c);
				// 当前完成率 > 实际完成率
				if (curPercent > percentComplete) curStatus = '2';
			}
			// 完了
			if (CommUtils.nullToZero(eve.PercentComplete__c) == 1) curStatus = '1';
			endDtStr = '/Date(' + endDt.getTime() + ')/';
		}
		return new Map<String,Object>{'ID' => objId,'dataid' => eve.id,
									// 2018/07/25 件名→行動の件名 by zy BEGIN
									 //'Title'=>eve.Title__c,
									'Title'=> eventTitle,
									// 2018/07/25 件名→行動の件名 by zy END
									'ParentID'=>CommUtils.nullToZero(eve.ParentProject__r.name) == 0 ? null : CommUtils.nullToZero(eve.ParentProject__r.name),'OrderID' => eve.OrderId__c,
									'Start' => startDtStr,'End' => endDtStr ,
									// 2018/11/15 17.プロジェクト管理を開いたときにタスクが開いた状態から始まる by zy BEGIN
									'PercentComplete' => eve.PercentComplete__c,'Expanded'=>eve.Expanded__c,
									// 2018/11/15 17.プロジェクト管理を開いたときにタスクが開いた状態から始まる by zy END
									// 2018/07/25 担当者→行動の任命先 by zy BEGIN
									//'userid' => CommUtils.nullToBlank(eve.UserRef__c),'orgassign'=>CommUtils.nullToBlank(eve.UserRef__r.name),
									//'assigned' => CommUtils.nullToBlank(eve.UserRef__r.name),
									'userid' => ownerId,
									'assigned' => ownerName,
									// 2018/08/07 進捗メモ追加　by zy BEGIN
									'comment' => comment,
									// 2018/08/07 進捗メモ追加　by zy END
									// 2018/07/25 担当者→行動の任命先 by zy END
									// 2018/11/15 8.予定と実績を表示させる、させないの切り替え by zy BEGIN
								 	'dueStart' => taskDetail.pd.DueStartDt__c != null ? '/Date(' + taskDetail.pd.DueStartDt__c.getTime() + ')/' : startDtStr,
									'dueEnd' => taskDetail.pd.DueEndDt__c != null ? '/Date(' + taskDetail.pd.DueEndDt__c.getTime() + ')/' : endDtStr,
									// 2018/11/15 8.予定と実績を表示させる、させないの切り替え by zy END
									'wbs'=> '','Summary' => eve.Summary__c ,'warning' => curStatus
									// 2018/11/30 関連書類の紐付け by cxw BEGIN
									// 2019/1/15 プロジェックト機能のPriority(重要度）列を追加 by cxw BEGIN
									,'importance'=>CommUtils.nullToBlank(eve.Importance__c)
									// 2019/1/15 プロジェックト機能のPriority(重要度）列を追加 by cxw END
									// 2019/07/15 プロジェクト明細のURLをプロジェクト管理画面から出力できるように陣屋コネクトとしての改善要望です。 by zy BEGIN
									,'chatter' => eve.chatterRef__c
									// 2019/07/15 プロジェクト明細のURLをプロジェクト管理画面から出力できるように陣屋コネクトとしての改善要望です。 by zy end
									// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
									,'calendarFlg'=> taskDetail.pd.CalendarFlg__c ? CALENDAR_HIDE_LABEL:CALENDAR_SHOW_LABEL
									// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
									// 2020/08/31 担当部署列の追加、ユーザに紐づく部署ではなく、選択リストを引用するように by zy BEGIN 
									, 'depart' => CommUtils.nullTOBlank(taskDetail.pd.Department__c)
									// 2020/08/31 担当部署列の追加、ユーザに紐づく部署ではなく、選択リストを引用するように by zy END 
									// 2020/10/31 担当者を複数設定できるように by zy BEGIN
									,'userids' => Commutils.nullToBlank(taskDetail.pd.userRefs__c)
									,'assigneds' => CommUtils.nullToBlank(assigneds)
									// 2020/10/31 担当者を複数設定できるように by zy END
									,'eventid'=>eve.TaskId__c
									// 2020/10/30 2.14.特定日のマーキング機能、スケジュールのなかでポイントをうち、右の表示マークをつける機能 by zy BEGIN
									,'marks' => CommUtils.nullTOBlank(taskDetail.pd.Marks__c)
									// 2020/10/30 2.14.特定日のマーキング機能、スケジュールのなかでポイントをうち、右の表示マークをつける機能 by zy END
									// 2020/10/31 2.07.取引先の紐付け by zy BEGIN
									,'account' => CommUtils.nullTOBlank(taskDetail.pd.AccountRefs__c)
									,'accname' => CommUtils.nullTOBlank(accnames)
									// 2020/10/31 2.07.取引先の紐付け by zy END
									// 2020/10/31 タスク単位でマネージャー、担当者を設定できるようにする。設定していない場合はその親プロジェクトの権限を参照する。 by zy BEGIN
									,'assign' => CommUtils.nullTOBlank(taskDetail.pd.AssignUser__c)
									,'manager' => CommUtils.nullTOBlank(taskDetail.pd.ManagerUser__c)
									// 2020/10/31 タスク単位でマネージャー、担当者を設定できるようにする。設定していない場合はその親プロジェクトの権限を参照する。 by zy END
								};
									// 2018/11/30 関連書類の紐付け by cxw END
	}
	// cookie プロジェックト取得
	private static String getCookieProjectId() {
		map<String,String> userBookMap = UserConfigCompCtrl.getCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.TASK,UserUtil.CurrentUser.id,'');
		String projectId = CommUtils.nullToBlank(userBookMap.get(UserConfigCompCtrl.KREP_SUBTYPE.PROJECTMAIN.name()));
	   	return projectId;
	}
	// cookie プロジェックト保存
	private static void saveCookieProjectId(String projectId){
		// Cookieからレイアウトモードを取得する
		UserConfigCompCtrl.saveCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.TASK,
				UserConfigCompCtrl.KREP_SUBTYPE.PROJECTMAIN.name(),projectId,UserUtil.CurrentUser.id,'');
	}
	class ProjectMain {
		String name;
		String startDt;
		String endDt;
		String users;
		String projectid;
		List<String> tasks;
		String seltype;
		boolean pub;
		String pDesc;
		String dataid;
		String managerName;
		// 2018/11/30 時間軸を日にした際に時間単位で表示される。日単位で切り替えできるように改善対応 by zy BEGIN
		String dateMode;
		// 2018/11/30 時間軸を日にした際に時間単位で表示される。日単位で切り替えできるように改善対応 by zy END
		// 2018/12/15 削除タスク順序不計算修正 by cxw BEGIN
		List<String> refreshParents;
		// 2018/12/15 削除タスク順序不計算修正 by cxw END
		Boolean finish;
		// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
		boolean calendarFlg;
		// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
		// 2020/08/31 担当部署列の追加、ユーザに紐づく部署ではなく、選択リストを引用するように by zy BEGIN
		Map<String,String> depart;
		// 2020/08/31 担当部署列の追加、ユーザに紐づく部署ではなく、選択リストを引用するように by zy END
		// 2020/03/31 プロジェクトオブジェクトのレコードにプロジェクトコードを作成し by zy BEGIN
		String record;
		String title;
		// 2020/03/31 プロジェクトオブジェクトのレコードにプロジェクトコードを作成し by zy END
		// 2020/10/31 タスク単位でマネージャー、担当者を設定できるようにする。設定していない場合はその親プロジェクトの権限を参照する。 by zy BEGIN
		boolean roleDetailFlg;
		// 2020/10/31 タスク単位でマネージャー、担当者を設定できるようにする。設定していない場合はその親プロジェクトの権限を参照する。 by zy END
	}
	class ProjectInfo{
		Integer ID;
		String EndTm;
		String Start;
		String Title;
		String dataid;
		Integer OrderID;
		Integer ParentID;
		boolean Summary;
		Boolean Expanded;
		long StartDt;
		long EndDt;
		String assigned;
		String wbs;
		String userid;
		String warning;
		String projectid;
		String parentDataId;
		List<String> parents;
		Decimal PercentComplete;
		// 2018/08/07 進捗メモ追加　by zy BEGIN
		String comment;
		// 2018/08/07 進捗メモ追加　by zy END
		// 2018/11/15 8.予定と実績を表示させる、させないの切り替え by zy BEGIN
		long dueStart;
		long dueEnd;
		// 2018/11/15 8.予定と実績を表示させる、させないの切り替え by zy END
		// 2018/11/30 行動を範囲選択してコピーできるといい。 by cxw BEGIN
		Boolean copyItem;
		String Status;
		// 2019/1/15 プロジェックト機能のPriority(重要度）列を追加 by cxw BEGIN
		String importance;
		// 2019/1/15 プロジェックト機能のPriority(重要度）列を追加 by cxw END
		// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
		String calendarFlg;
		// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
		// 2020/08/31 担当部署列の追加、ユーザに紐づく部署ではなく、選択リストを引用するように by zy BEGIN
		String depart;
		// 2020/08/31 担当部署列の追加、ユーザに紐づく部署ではなく、選択リストを引用するように by zy END
		// 2020/10/30 2.14.特定日のマーキング機能、スケジュールのなかでポイントをうち、右の表示マークをつける機能 by zy BEGIN
		String marks; // マーク情報
		// 2020/10/30 2.14.特定日のマーキング機能、スケジュールのなかでポイントをうち、右の表示マークをつける機能 by zy END
		// 2020/10/31 担当者を複数設定できるように by zy BEGIN	
		String userids;
		// 2020/10/31 担当者を複数設定できるように by zy END
		// 2020/10/31 2.07.取引先の紐付け by zy BEGIN
		String accid;
		// 2020/10/31 2.07.取引先の紐付け by zy END
		// 2020/10/31 タスク単位でマネージャー、担当者を設定できるようにする。設定していない場合はその親プロジェクトの権限を参照する。 by zy BEGIN
		String assign;
		String manager;
		// 2020/10/31 タスク単位でマネージャー、担当者を設定できるようにする。設定していない場合はその親プロジェクトの権限を参照する。 by zy END
	}
	// 2018/11/15 顾客最后操作的内容，自动记录 by zy BEGIN
	// レイアウト内容
	public String layoutJSON{get;set;}
	// フィルート内容
	public String fieldJSON{get;set;}
	// 並べ替え内容
	public String sortJSON{get;set;}
	//　該当プロジェックト表示タイプ
	public String ganttType{get;set;}
	// 予定と実績
	public boolean taskViewFlag{get;set;}
	// 担当者保持
	public String projectUserId{get;set;}
	// 2018/11/30 時間軸を日にした際に時間単位で表示される。日単位で切り替えできるように改善対応 by zy BEGIN
	// 日付切替モード設定
	public String projectMode{get;set;}
	// 2018/11/30 時間軸を日にした際に時間単位で表示される。日単位で切り替えできるように改善対応 by zy END
	private void initCookieInfo(){
		// レイアウト設定
		initLayoutSetting();
		// フィルート横幅設定
		initFieldSetting();
		// フィルート並べ設定
		initSortSetting();
		// プロジェックト表示タイプ
		initGanttTypeSetting();
		// 予定と実績
		initTaskViewSetting();
		// 担当者保持
		initProjectUser();
		// 2018/12/30 拡大機能[+/-]ボタンにより、ZOOMのバーにより、全体はズーム機能 by cxw BEGIN
		// 字体サイズ設定
		initFontSizeSetting();
		// 2018/12/30 拡大機能[+/-]ボタンにより、ZOOMのバーにより、全体はズーム機能 by cxw END
	}
	// COOKIE指定内容取得
	private static String getCookieInfo(String subType) {
		map<String,String> userBookMap = UserConfigCompCtrl.getCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.TASK,UserUtil.CurrentUser.id,'');
		String projectInfo = CommUtils.nullToBlank(userBookMap.get(subType));
	   	return projectInfo;
	}
	// COOKIE指定内容保存
	private static void saveCookieInfo(String subType, String settingInfo){
		// UserConfigCompCtrl.KREP_SUBTYPE.PROJECTMAIN.name()
		// Cookieからレイアウトモードを取得する
		UserConfigCompCtrl.saveCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.TASK,
				subType,settingInfo,UserUtil.CurrentUser.id,'');
	}
	// 画面設定情報保存
	public class CookieInfo{
		// タスク画面横幅
		public String tWd;
		// 明細画面横幅
		public String dWd;
		public CookieInfo(){
			tWd = '0px';
			dWd = '680px';
		}
	}
	// レイアウト設定
	private	void initLayoutSetting(){
		String userCookie = getCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.PROJECTLAYOUT.name());
		if (!CommUtils.isBlank(userCookie)) layoutJSON = userCookie;
		else {
			CookieInfo cookieInfo = new CookieInfo();
			layoutJSON = JSON.serialize(cookieInfo);
		}
	}
	// 初期化フィルート横幅
	private void initFieldSetting(){
		// 初期化
		fieldJson = '';
		Map<String,Map<String,object>> defFieldMap = new Map<String,Map<String,object>>{
			//2019/03/15 変更履歴機能追加 by cxw BEGIN
			'icon' => convertFiedSetting('icon', ' ', 48)
			,'wbs' => convertFiedSetting('wbs','番号',50,null,true)
			//2019/03/15 変更履歴機能追加 by cxw END
			,'title' => convertFiedSetting('title','件名',120,true,true)
			,'userid' => convertFiedSetting('userid','担当者',100,true,true,null,'userEditor')
			// 2020/08/31 担当部署列の追加、ユーザに紐づく部署ではなく、選択リストを引用するように by zy BEGIN
			,'depart' => convertFiedSetting('depart','部署',100,true,true,null,'departEditor')
			// 2020/08/31 担当部署列の追加、ユーザに紐づく部署ではなく、選択リストを引用するように by zy END
			,'percentComplete' => convertFiedSetting('percentComplete','進捗',80,true,true,'{0:p0}')
			,'warning' => convertFiedSetting('warning','状態',46,null,true)
			// 2019/1/15 プロジェックト機能のPriority(重要度）列を追加 by cxw BEGIN
			,'importance' => convertFiedSetting('importance','優先度',70,true,true,null,'importanceEditor')
			// 2019/1/15 プロジェックト機能のPriority(重要度）列を追加 by cxw END
			// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
			,'calendarFlg' => convertFiedSetting('calendarFlg','カレンダー非表示',70,true,true,null,'calendarEditor')
			// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
			,'start' => convertFiedSetting('start','開始',140,true,true,'{0:yyyy/MM/dd HH:mm}', 'dateComponentCustomization')
			,'end' => convertFiedSetting('end','終了',140,true,true,'{0:yyyy/MM/dd HH:mm}', 'dateComponentCustomization')
			,'dueStart' => convertFiedSetting('dueStart','予定開始',140,true,true,'{0:yyyy/MM/dd HH:mm}', 'dateComponentCustomization')
			,'dueEnd' => convertFiedSetting('dueEnd','予定終了',140,true,true,'{0:yyyy/MM/dd HH:mm}', 'dateComponentCustomization')
			,'comment' => convertFiedSetting('comment','進捗メモ',140,true,true,'{0:yyyy/MM/dd HH:mm}')
			// 2020/10/31 2.07.取引先の紐付け by zy BEGIN
			,'account' => convertFiedSetting('account','取引先',140,true,false,null,'accountEditor')
			// 2020/10/31 2.07.取引先の紐付け by zy END
		};
		// 2019/1/15 プロジェックト機能のPriority(重要度）列を追加 by cxw BEGIN
		//2019/03/15 変更履歴機能追加 by cxw BEGIN
		List<String> defFieldSort = new List<String>{'icon','wbs','title'
		//2019/03/15 変更履歴機能追加 by cxw END				
						,'userid'
						// 2020/08/31 担当部署列の追加、ユーザに紐づく部署ではなく、選択リストを引用するように by zy BEGIN
						,'depart'
						// 2020/08/31 担当部署列の追加、ユーザに紐づく部署ではなく、選択リストを引用するように by zy END
						// 2020/10/31 2.07.取引先の紐付け by zy BEGIN
						,'account'
						// 2020/10/31 2.07.取引先の紐付け by zy END
						,'percentComplete','warning','importance'
						// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
						,'calendarFlg'
						// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy END
						,'dueStart','dueEnd','start','end','comment'
						};
		// 2019/1/15 プロジェックト機能のPriority(重要度）列を追加 by cxw END
		// 該当ユーザーCOOKIE情報取得
		String userCookie = getCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.PROJECTFIELD.name());
		// 横幅設定情報
		Map<String,object> fieldWdMap = new Map<String,object>();
		Map<String,String> labelMap = new Map<String,String>();
		// 2020/09/30 任意行を非表示にする。もしくはフィルター機能。 by zy BEGIN
		Map<String,boolean> hidMap = new Map<String,boolean>();
		Map<String,String> dictionaryMap = new Map<String,String>{'action' => 'icon','no' => 'wbs','pic' => 'userid','progress' => 'percentComplete','status' => 'warning','priority' => 'importance','noevent' => 'calendarFlg','startdate' => 'start','enddate' => 'end','schstartdate' => 'dueStart','schenddate' => 'dueEnd','memo' => 'comment'};
		// 2020/09/30 任意行を非表示にする。もしくはフィルター機能。 by zy END
		// XML指定情報設定
		ProSetting pro = getXmlSetting();
		if (pro.fieldInfos != null && pro.fieldInfos.size() > 0) {
			// 2020/09/30 任意行を非表示にする。もしくはフィルター機能。 by zy BEGIN
			// defFieldSort = new List<String>{'wbs'};
			defFieldSort = new List<String>();
			set<String> exitSet = new Set<String>();
			// 2020/09/30 任意行を非表示にする。もしくはフィルター機能。 by zy END
			for (FieldInfo field : pro.fieldInfos) {
				// 2020/09/30 任意行を非表示にする。もしくはフィルター機能。 by zy BEGIN
				String fieldName = dictionaryMap.containsKey(field.name) ? dictionaryMap.get(field.name) : field.name;
				// 2020/09/30 任意行を非表示にする。もしくはフィルター機能。 by zy END
				if (defFieldMap.containsKey(fieldName)) {
					// 2020/09/30 任意行を非表示にする。もしくはフィルター機能。 by zy BEGIN
					// カスタム字段並べ替え
					if (!exitSet.contains(fieldName)) defFieldSort.add(fieldName);
					exitSet.add(fieldName);
					// 2020/09/30 任意行を非表示にする。もしくはフィルター機能。 by zy END
					// カスタムラベル設定
					if (!CommUtils.isBlank(field.label))
						defFieldMap.get(fieldName).put('title',field.label);
				}
			}
			// 2020/09/30 任意行を非表示にする。もしくはフィルター機能。 by zy BEGIN
			List<String> defFieldLst = new List<String>{'title','userid','start','end'};
			for (String def : defFieldLst) {
				if (!exitSet.contains(def)) {
					defFieldSort.add(def);
				}
			}
			// 2020/09/30 任意行を非表示にする。もしくはフィルター機能。 by zy END
 		}
		// 情報あり
		if (!CommUtils.isBlank(userCookie)){
			List<Object> objLst = (List<Object>)JSON.deserializeUntyped(userCookie);
			if (!objLst.isEmpty()) {
				for (Object obj : objLst) {
					Map<String,object> objmap = (Map<String,object>) obj;
					fieldWdMap.put(CommUtils.nulltoBlank(objmap.get('field')),objmap.get('width'));
					// 2020/09/30 任意行を非表示にする。もしくはフィルター機能。 by zy BEGIN
					hidMap.put(CommUtils.nulltoBlank(objmap.get('field')),boolean.valueOf(CommUtils.nullToBlank(objmap.get('hidden'))));
					// 2020/09/30 任意行を非表示にする。もしくはフィルター機能。 by zy END
				}
			}
		}
		List<Map<String,object>> objects = new List<Map<String,object>>();
		for (String sortField : defFieldSort) {
			// 2018/11/15 8.予定と実績を表示させる、させないの切り替え by zy BEGIN
			if (CommUtils.isBlank(projectMain.PlanBaseName__c) &&
				(sortField.equalsIgnoreCase('dueStart') || 
					sortField.equalsIgnoreCase('dueEnd')) ) continue;
			// 2018/11/15 8.予定と実績を表示させる、させないの切り替え by zy END
			Map<String,Object> objmap = defFieldMap.get(sortField);
			// 字段横幅設定
			if (fieldWdMap.containsKey(sortField)) objmap.put('width',fieldWdMap.get(sortField));
			// 2020/09/30 任意行を非表示にする。もしくはフィルター機能。 by zy BEGIN
			if (hidMap.containsKey(sortField)) objmap.put('hidden',hidMap.get(sortField));
			// 2020/09/30 任意行を非表示にする。もしくはフィルター機能。 by zy END
			objects.add(objmap);
		}
		fieldJSON = JSON.serialize(objects);
	}
	// フィルート並べ設定
	private void initSortSetting(){
		String userCookie = getCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.PROJECTFIELDSORT.name());
		sortJSON = userCookie;
	}
	// プロジェックト表示タイプ
	private void initGanttTypeSetting(){
		ganttType = 'month';
		String userCookie = getCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.PROJECTTYPE.name());
		if (!CommUtils.isBlank(userCookie)) ganttType = userCookie;
	}
	// 予定と実績
	private	void initTaskViewSetting(){
		taskViewFlag = false;
		// 2020/09/31 画面スクロールを２分割したい by zy BEGIN
		splitFlg = false;
		// 2020/09/31 画面スクロールを２分割したい by zy END
		// 2020/09/30 右上のタスク選択リストに自分が関連するタスクのみ表示機能と検索機能運用が始まると200以上のタスクが作られることが想定されるため探しやすくするため by zy BEGIN
		isPublicFlg = false;
		// 2020/09/30 右上のタスク選択リストに自分が関連するタスクのみ表示機能と検索機能運用が始まると200以上のタスクが作られることが想定されるため探しやすくするため by zy END
		String userCookie = getCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.PROJECTVIEWFLG.name());
		// 2020/09/31 画面スクロールを２分割したい by zy BEGIN
		if (userCookie.indexof('{') >=0 ) {
			ToolbarInfo info = (ToolbarInfo)JSON.deserializeStrict(userCookie,ToolbarInfo.class);
			if (info.taskview != null) taskViewFlag = info.taskview;
			if (info.split != null) splitFlg = info.split;
			if (info.pubflg != null) isPublicFlg = info.pubflg;
		} else 
		// 2020/09/31 画面スクロールを２分割したい by zy END
		if (!CommUtils.isBlank(userCookie)) taskViewFlag = boolean.valueof(userCookie);
	}
	// 担当者保持
	private void initProjectUser() {
		projectUserId = '';
		String userCookie = getCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.PROJECTUSER.name());
		if (!CommUtils.isBlank(userCookie)) projectUserId = CommUtils.nullToblank(userCookie);
	}
	private Map<String,object> convertFiedSetting(String field,String title,Integer width){
		return convertFiedSetting(field,title,width,null,null,null,null);
	}
	private Map<String,object> convertFiedSetting(String field,String title,Integer width,boolean editable,boolean sortable){
		return convertFiedSetting(field,title,width,editable,sortable,null,null);
	}
	private Map<String,object> convertFiedSetting(String field,String title,Integer width,boolean editable,boolean sortable,String format){
		return convertFiedSetting(field,title,width,editable,sortable,format,null);
	}
	private Map<String,object> convertFiedSetting(String field,String title,Integer width,
							boolean editable,boolean sortable,String format,String edtior){
		Map<String,object> objMap = new Map<String,object>();
		objMap.put('field',field);
		objMap.put('title',title);
		if (width != null) objMap.put('width',width);
		if (!CommUtils.isBlank(format)) objMap.put('format',format);
		if (!CommUtils.isBlank(edtior)) objMap.put('editor',edtior);
		if (editable != null) objMap.put('editable',editable);
		if (sortable != null) objMap.put('sortable',sortable);
		return objMap;
	}
	// XML指定情報設定
	private static ProSetting getXmlSetting(){
		ProSetting pro = new ProSetting();
		try{
			// XML読み込み
			Dom.XmlNode targetNode = CommXmlUtils.encodeParseXmlDoc('StaffScheduleConfigXml',null,new String[]{'<COONDITION>','</COONDITION>'});
			for(Dom.XMLNode xmlNode : targetNode.getChildElements()){
				// タグ名
				String attributeName = xmlNode.getName();
				if(attributeName.equalsIgnoreCase('GANTTCONFIG')){
					Dom.XmlNode fieldSortNode = xmlNode.getChildElement('FIELDS',null);
					if (fieldSortNode != null) {
						// 2020/10/31 8443 bug fixed by zy BEGIN
						String sortStr = CommUtils.nullToBlank(fieldSortNode.getText()).deleteWhitespace().trim();
						// 2020/10/31 8443 bug fixed by zy END
						if (!CommUtils.isBlank(sortStr)) {
							for(String field : sortStr.split(',')) {
								String[] fieldMsg = field.split(':');
								if (fieldMsg.size() > 1) pro.fieldInfos.add(new FieldInfo(fieldMsg[0],fieldMsg[1]));
								else pro.fieldInfos.add(new FieldInfo(fieldMsg[0]));
							}
						}
					}
				}
			}
		} catch(exception e) {}
		return pro;
	}
	// XML指定情報設定
	class ProSetting{
		List<FieldInfo> fieldInfos;
		public ProSetting(){
			fieldInfos = new List<FieldInfo>();
		}
	}
	// 字段指定情報設定
	class FieldInfo{
		String name;
		String label;
		public FieldInfo(String fieldName){
			name = CommUtils.nullToBlank(fieldName).trim().deleteWhitespace();
		}
		public FieldInfo(String fieldName,String labelStr){
			name = CommUtils.nullToBlank(fieldName).trim().deleteWhitespace();
			label = labelStr;
		}
	}
	// 2018/11/15 顾客最后操作的内容，自动记录 by zy END
	// 2018/11/15 8.予定と実績を表示させる、させないの切り替え by zy BEGIN
	public void saveBasePlan(){
		ProjectMain__c mainPj = new ProjectMain__c(id = mainProjectId);
		mainPj.PlanBaseName__c = CommUtils.nullToBlank(projectMain.PlanBaseName__c);
		StaffTaskHelp.updateProjectMain(mainPj);
		if (!CommUtils.isBlank(mainPj.PlanBaseName__c)) StaffTaskHelp.updDueDatetime(mainProjectId);
		// 2020/09/30 右上のタスク選択リストに自分が関連するタスクのみ表示機能と検索機能運用が始まると200以上のタスクが作られることが想定されるため探しやすくするため by zy BEGIN
		ToolbarInfo info = new ToolBarInfo();
		info.split = splitFlg;
		info.taskview = !CommUtils.isBlank(mainPj.PlanBaseName__c);
		info.pubflg = isPublicFlg;
		// Cookieからレイアウトモードを取得する
		UserConfigCompCtrl.saveCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.TASK,
				UserConfigCompCtrl.KREP_SUBTYPE.PROJECTVIEWFLG.name(),JSON.serialize(info),UserUtil.CurrentUser.id,'');
		// レイアウト内容
		initCookieInfo();
	}
	// 2019/03/15 マルチタスクの表示を切り替える by cxw BEGIN
	public Boolean finishMode{get; set;}
	// 2019/03/15 マルチタスクの表示を切り替える by cxw END
	public void changeProejct(){
		// Cookieからレイアウトモードを取得する
		UserConfigCompCtrl.saveCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.TASK,
				UserConfigCompCtrl.KREP_SUBTYPE.PROJECTMAIN.name(),mainProjectId,UserUtil.CurrentUser.id,'');
		doAction();
	}
	// 2018/11/15 8.予定と実績を表示させる、させないの切り替え by zy END
	// 2018/11/30 関連書類の紐付け by cxw BEGIN
   public String hostName{get{
   		return CommUtils.getHostNameUrl();
   }}
   // 添加附件
   	private static List<Object> remoteAttachment(String dataReq){
		Map<String, String> response = (Map<String, String>)JSON.deserializeStrict(dataReq, Map<String, String>.class);
		if(response.containsKey('eventid')){
			String eventid = response.get('eventid');
			Map<String, List<AttachmentStruct>> result = queryEventAttachment(new Set<String>{response.get('eventid')});
			if(result.containsKey(eventid)) return result.get(eventid);
		}
		return new List<Object>();
	}
	
	// 删除附件
	private static List<Object> remoteDelAttachment(String dataReq){
		Map<String, String> response = (Map<String, String>)JSON.deserializeStrict(dataReq, Map<String, String>.class);
		String eventid = null;
		String attid = null;
		if(response.containsKey('eventid')) eventid = response.get('eventid');
		if(response.containsKey('attid')) attid = response.get('attid');
		if(!CommUtils.isBlank(attid)){
			//delete [select id from Attachment where id = :attid];
			StaffTaskHelp.removeAttachment(new Set<String>{attid});
		}else{
			StaffTaskHelp.removeAttachmentForEvent(new Set<String>{eventid});
		}
		Map<String, List<AttachmentStruct>> result = queryEventAttachment(new Set<String>{eventid});
		return result.containsKey(eventid) ? result.get(eventid) : new List<Object>();
	}
	
	// 查询附件
	private static Map<String, List<AttachmentStruct>> queryEventAttachment(Set<String> eventids){
		Map<String, List<AttachmentStruct>> result = new Map<String, List<AttachmentStruct>>();
		if(!eventids.isEmpty()){
			for(Attachment att : StaffTaskHelp.queryAttachmentByEvent(eventids)){
				if(!result.containsKey(att.ParentId)) result.put(att.ParentId, new List<AttachmentStruct>());
				result.get(att.ParentId).add(new AttachmentStruct(att.name, att.id));
			}
		}
		return result; 
	}

	private class AttachmentStruct{
		String fileName;
		String attachmentId;
		public AttachmentStruct(String fileName, String attachmentId){
			this.fileName = fileName;
			this.attachmentId = attachmentId;
		}
	}
	// 2018/11/30 関連書類の紐付け by cxw END
	// 2018/11/30 行動を範囲選択してコピーできるといい。 by cxw BEGIN
	private static List<Object> updateAll(String dataReq){
		Map<String, ProjectInfo> response = (Map<String, ProjectInfo>)JSON.deserializeStrict(dataReq, Map<String, ProjectInfo>.class);
		String projectId = null;
		Boolean isCopy = false;
		Set<String> copyItems = new Set<String>();
		if(response.containsKey('projectId')){
			projectId = response.get('projectId').dataid;
			isCopy = response.get('projectId').Status == null ? false : true;
			response.remove('projectId');
		}
		String userId = UserUtil.CurrentUserInfo.u.id;
		// ----------- 新建
		List<Object> result = new List<Object>();
		if(response.isEmpty()) return result;
		Map<String, ProjectDetail__c> createdMap = new Map<String, ProjectDetail__c>();
		Map<String, Event> eventsMap = new Map<String, Event>();
		Map<String, List<ProjectDetail__c>> parentsMap = new Map<String, List<ProjectDetail__c>>();
		for(String dataId : response.keySet()){
			if(dataId.endsWith('_new')){ // dataId 已 "_new" 结尾, 则为新建
				ProjectInfo pi = response.get(dataId);
				ProjectDetail__c pd = new ProjectDetail__c();
				pd.OrderId__c = pi.OrderID;
				pd.PercentComplete__c = 0;
				pd.ProjectMain__c = projectId;
				// 2019/1/15 プロジェックト機能のPriority(重要度）列を追加 by cxw BEGIN
				pd.Importance__c = pi.importance;
				// 2019/1/15 プロジェックト機能のPriority(重要度）列を追加 by cxw END
				pd.EventType__c = StaffTaskHelp.EVENT_TYPE_EVENT;
				if(pi.Summary != null) pd.Summary__c = pi.Summary;
				if(pi.Expanded != null) pd.Expanded__c = pi.Expanded;
				Event ev = new Event();
				ev.OwnerId = userId;
				ev.Subject = pi.Title;
				ev.StartDateTime = Datetime.newInstance(pi.StartDt);
				ev.EndDateTime = Datetime.newInstance(pi.StartDt);
				ev.EndDatetime__c = Datetime.newInstance(pi.EndDt);
				ev.ProjectFlag__c = true;
				//2019/03/15 変更履歴機能追加 by cxw BEGIN
				pd.Title__c = ev.Subject;
				pd.StartDt__c = ev.StartDateTime;
				pd.EndDt__c = ev.EndDatetime__c;
				pd.UserRef__c = ev.OwnerId;
				//2019/03/15 変更履歴機能追加 by cxw END
				eventsMap.put(dataId, ev); // event 存起来;
				createdMap.put(dataId, pd); // projentDetail 存起来;
				if(pi.copyItem == true) copyItems.add(dataId);
				if(pi.parentDataId != null && pi.parentDataId.endsWith('_new')){
					if(!parentsMap.containsKey(pi.parentDataId)) parentsMap.put(pi.parentDataId, new List<ProjectDetail__c>());
					parentsMap.get(pi.parentDataId).add(pd);
				}else{
					pd.ParentProject__c = pi.parentDataId;
				}
				// 2020/08/31 担当部署列の追加、ユーザに紐づく部署ではなく、選択リストを引用するように by zy BEGIN
				pd.Department__c = pi.depart;
				// 2020/08/31 担当部署列の追加、ユーザに紐づく部署ではなく、選択リストを引用するように by zy END
				// 2020/10/31 2.07.取引先の紐付け by zy BEGIN
				pd.AccountRefs__c = pi.accid;
				// 2020/10/31 2.07.取引先の紐付け by zy END
			}
		}
		StaffTaskHelp.upsertEvents(eventsMap.values());
		StaffTaskHelp.insertProjectDetail(createdMap.values());
		Map<String, Id> updateParentsMap = new Map<String, Id>(); // 存放新建时的dataId名字, 和 存到数据库生成的Id
		for(String dataId : createdMap.keySet()){
			ProjectDetail__c pd = createdMap.get(dataId);
			if(copyItems.contains(dataId)){
				copyItems.remove(dataId);
				copyItems.add(pd.id);
			}
			pd.taskId__c = eventsMap.get(dataId).id;
			updateParentsMap.put(dataId, pd.id);
			if(parentsMap.containsKey(dataId)){
				List<ProjectDetail__c> parents = parentsMap.get(dataId);
				for(ProjectDetail__c parent : parents){
					parent.ParentProject__c = pd.id;
				}
			}
		}
		StaffTaskHelp.updateProjectDetail(createdMap.values());
		
		// --------- 更新
		List<StaffTaskHelp.PdetailInfo> projects = StaffTaskHelp.getProjects(new List<String>(response.keySet()));
		List<Task> tasks = new List<Task>();
		Map<String, Event> eventMap = new Map<String, Event>();
		List<ProjectDetail__c> pds = new List<ProjectDetail__c>();
		for(StaffTaskHelp.PdetailInfo detail : projects){
			ProjectDetail__c curProj = detail.pd;
			ProjectInfo p = response.get(curProj.id);
			if(p == null) continue;
			Datetime stDt = null;
			Datetime endDt = null;
			if (p.StartDt != null) stDt = Datetime.newInstance(p.StartDt);
			if (p.EndDt != null) endDt = Datetime.newInstance(p.EndDt);
			// 2018/11/15 編集画面保存bug修正 by zy END
			// 2018/07/23 タスク終了日時字段変更　by zy BEGIN
	    	Integer maxMiuteLen = 14 * 24 * 60;
			// 2018/07/23 タスク終了日時字段変更　by zy END
			if (curProj != null) {
				curProj.OrderId__c = p.OrderId;
				curProj.ParentProject__c = p.parentDataId;
				// 2019/1/15 プロジェックト機能のPriority(重要度）列を追加 by cxw BEGIN
				curProj.Importance__c = p.importance;
				// 2019/1/15 プロジェックト機能のPriority(重要度）列を追加 by cxw END
				if(updateParentsMap.containsKey(p.parentDataId)) curProj.ParentProject__c = updateParentsMap.get(p.parentDataId);
				curProj.PercentComplete__c = p.PercentComplete;
				curProj.Summary__c = p.Summary;
				// 2018/11/15 17.プロジェクト管理を開いたときにタスクが開いた状態から始まる by zy BEGIN
				curProj.Expanded__c = p.Expanded;
				// 2018/11/15 17.プロジェクト管理を開いたときにタスクが開いた状態から始まる by zy END
				// 2018/11/15 8.予定と実績を表示させる、させないの切り替え by zy BEGIN
				if (p.dueStart != null) curProj.DueStartDt__c = Datetime.newInstance(p.dueStart);
				if (p.dueEnd != null) curProj.DueEndDt__c =  Datetime.newInstance(p.dueEnd);
				// 2018/11/15 8.予定と実績を表示させる、させないの切り替え by zy END
				if (detail.evt != null) {
					if (p.userid != null && p.userid != '') {
						detail.evt.ownerid = p.userid;
					}
					if (endDt != null) detail.evt.EndDatetime__c = endDt;
					if (stDt != null) {
						detail.evt.StartDatetime = stDt;
					}
					if (!CommUtils.isBlank(p.Title)) {
						detail.evt.subject = p.Title;
					}
					// 2018/07/23 タスク終了日時字段変更　by zy BEGIN	
					if (endDt != null && stDt != null) {
						Integer durMinutes = CommUtils.nullToIntZero((endDt.getTime() - stDt.getTime())/ (60 *1000));
						detail.evt.DurationInMinutes = durMinutes > maxMiuteLen ? maxMiuteLen : durMinutes;
						detail.evt.EndDateTime = stDt.addMinutes(detail.evt.DurationInMinutes);
						if (detail.evt.IsAllDayEvent) detail.evt.IsAllDayEvent = false;
					}
					// 2018/07/23 タスク終了日時字段変更　by zy END
					// 2018/08/07 進捗メモ追加　by zy BEGIN
					if (!CommUtils.isBlank(p.comment)) detail.evt.Description = p.comment;
					// 2018/08/07 進捗メモ追加　by zy END	
					eventMap.put(detail.evt.id, detail.evt);
	
				} else if (detail.taskObj != null) {
					if (p.userid != null && p.userid != '') {
						detail.taskObj.ownerid = p.userid;
					}
					if (stDt != null) {
						detail.taskObj.ActivityDate = stDt.date();
						// ToDo 開始時刻保存用
						detail.taskObj.TaskStartTime__c = stDt.format('HH:mm');
					}
					if (endDt != null) detail.taskObj.EndDatetime__c = endDt;
					if (!CommUtils.isBlank(p.Title)) {
						detail.taskObj.subject = p.Title;
					}
					// 2018/08/07 進捗メモ追加　by zy BEGIN
					if (!CommUtils.isBlank(p.comment)) detail.taskObj.Description = p.comment;
					// 2018/08/07 進捗メモ追加　by zy END	
					tasks.add(detail.taskObj);
				}
			}
			pds.add(curProj);
		}
		
		if(!pds.isEmpty()) StaffTaskHelp.updateProjectDetail(pds);
		if(!eventMap.isEmpty()) StaffTaskHelp.updateEvents(eventMap);
		if(!tasks.isEmpty()) StaffTaskHelp.updateChangeTasks(tasks);
		List<StaffTaskHelp.PdetailInfo> ps = StaffTaskHelp.getProjectLst(projectId,null,null);
		for (StaffTaskHelp.PdetailInfo pd : ps) {
			// 2018/11/15 14.タスクの移動がドラッグでできるが、望むところに移動せず、動かすつもりのないタスクも動 by zy BEGIN
			Map<String,Object> makeMapByProject = makeMapByProject(pd);
			if (isCopy && copyItems.contains(pd.pd.id)) makeMapByProject.put('newFlag',true);
			result.add(makeMapByProject);
			// 2018/11/15 14.タスクの移動がドラッグでできるが、望むところに移動せず、動かすつもりのないタスクも動 by zy END
		}
		return result;
	}
   // 2018/11/30 行動を範囲選択してコピーできるといい。 by cxw END
   // 2018/12/30 拡大機能[+/-]ボタンにより、ZOOMのバーにより、全体はズーム機能 by cxw BEGIN
   public Integer fontSizeInt{get;set;}
   // 字体サイズ設定
   private void initFontSizeSetting(){
   	  	// 字体サイズ設定
   	  	fontSizeInt = 12;
   	  	// COOKIE設定内容
   	  	String userCookie = getCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.FONTSIZE.name());
   	 	if (!CommUtils.isBlank(userCookie)) {
   	  	 	integer fontSize = CommUtils.nullToIntZero(userCookie);
   	  	 	/*if (fontSize >= 12 && fontSize <= 20)*/
   	  	 	fontSizeInt = fontSize;
   	  	}
   }
   //　COOKIE内容保存
   private static void saveRemoteCookieInfo(String dataReq){
   		Map<String,Object> dataRequest = (Map<String,Object>)JSON.deserializeUntyped(dataReq);
		String subType = CommUtils.nullToBlank(dataRequest.get('subType'));
		String cookieValue = CommUtils.nullToBlank(dataRequest.get('value'));
		saveCookieInfo(subType,cookieValue);
   }
   // 2018/12/30 拡大機能[+/-]ボタンにより、ZOOMのバーにより、全体はズーム機能 by cxw END
   // 2019/1/15 プロジェックト機能のPriority(重要度）列を追加 by cxw BEGIN
   public String importanceLstJson{get{
	   List<Schema.PicklistEntry> entrys = Schema.SObjectType.ProjectDetail__c.fields.importance__c.getPicklistValues();
	   List<Map<string, string>> result = new List<Map<string, string>>();
	   result.add(new Map<string, string>{'value' => '', 'label' => '　'});
	   for(Schema.PicklistEntry entry : entrys) {
		   result.add(new Map<string, string>{'value' => entry.getValue(), 'label' => entry.getLabel()});
	   }
	   return JSON.serialize(result);
   } set;}
   
   
   public String defaultValue{get{
	   return CommUtils.nullToBlank(String.valueOf(Schema.SObjectType.ProjectDetail__c.fields.importance__c.getDefaultValue()));
   } set;}
// 2019/1/15 プロジェックト機能のPriority(重要度）列を追加 by cxw END
   //2019/03/15 変更履歴機能追加 by cxw BEGIN
	private static List<Object> getProjectHistory(String dataReq){ 
		Set<Id> projectSet = new Set<Id>();
		List<String> prodArr = (List<String>)JSON.deserialize(dataReq,List<String>.class);
		for (String projId : prodArr) {
			projectSet.add(projId);
		}
		List<Object> result = StaffTaskHelp.getHistory('ProjectDetail__c',projectSet);
		return result;
	}
	//2019/03/15 変更履歴機能追加 by cxw END
	// 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy BEGIN
	private String pProjectId;
	// 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy END
	// 2019/07/15 プロジェクト明細のURLをプロジェクト管理画面から出力できるように陣屋コネクトとしての改善要望です。 by zy BEGIN
	public List<SelectOption> chatterOpts{get;set;}
	private static List<Object> chatterPostItem(String dataReq){
		Map<String,Object> dataRequest = (Map<String,Object>)JSON.deserializeUntyped(dataReq);
		String taskId = (String) dataRequest.get('id');
		StaffTaskHelp.PdetailInfo ps = StaffTaskHelp.getProjectDetail(taskId);
		String chatterGroupId = (String) dataRequest.get('chatter');
		String content = (String) dataRequest.get('desc');
		LisT<Object> users = (LisT<Object>) dataRequest.get('users');
		String title = ps.evt != null ? ps.evt.subject : (ps.taskObj != null ? ps.taskObj.subject : '');
		
		ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
		
		ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
		ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();

		messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
		
		if (users != null) {
			for (Object userId : users) {
				ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
				mentionSegmentInput.id = CommUtils.nullToBlank(userId);
				messageBodyInput.messageSegments.add(mentionSegmentInput);
			}
		}
		
		textSegmentInput.text = '\n' + title + '\n' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + ps.pd.id + '\n' + content;
		messageBodyInput.messageSegments.add(textSegmentInput);
		feedItemInput.body = messageBodyInput;
		feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
		feedItemInput.subjectId = chatterGroupId;
		/*
		LinkAttachmentInput
		​Feed​Item​Attachment​​Input attachInput = new ​Feed​Item​Attachment​​Input();
		attachInput.add(new LinkAttachmentInput(url = '/00P0W0000196JMdUAM'));
		feedItemInput.attachment = feedItemInput;*/
		// ConnectApi.FeedItemInput input = ConnectApiHelper.createFeedItemInputFromBody(item.body);
		ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
		ProjectDetail__c pd = new ProjectDetail__c (id = taskId,ChatterRef__c = feedElement.id);
		update pd;
		return new List<map<String,Object>>{new Map<String,Object>{'dataid' => pd.id,'chatter' => pd.chatterRef__c}};
	}
	private static List<object> getProjectUsers(String dataReq){
		String projectId = (String) JSON.deserialize(dataReq,String.class);
		ProjectMain__c projectMain = StaffTaskHelp.getProjectMain(projectId);
		Set<String> userIds = new Set<String>();
		if (projectMain != null) {
			userIds = new Set<String>(CommUtils.nullToBlank(projectMain.AssignUser__c).split(','));
			userIds.addAll(CommUtils.nullToBlank(projectMain.ManagerUser__c).split(','));
		}
		List<Map<String,String>> userLst = new List<Map<String,String>>();
		if (!userIds.isEmpty()) {
			for (User u : [select id,name,lastName,firstName from user where Id = :userIds]){
				userLst.add(new Map<String,String>{'id' => u.id,'name' => CommUtils.nullTOBlank(u.firstName) + CommUtils.nullTOBlank(u.lastName)});
			}
		}
		return userLst;
	}
	private static List<Object> preCheckChatter(String dataReq){
		String chatterId = (String)JSON.deserialize(dataReq,String.class);
		List<FeedItem> items = [select id from FeedItem where id=:chatterId];
		if (items.isEmpty()) {
			List<ProjectDetail__c> pds = [select id,chatterRef__c from ProjectDetail__c where chatterRef__c = :chatterId];
			if (!pds.isEmpty()) {
				pds[0].chatterRef__c = null;
				update pds[0];
				return new List<Map<String,String>>{new Map<String,String>{'id' => pds[0].id}};
			}
		}
		return null;
	}
	// 2019/07/15 プロジェクト明細のURLをプロジェクト管理画面から出力できるように陣屋コネクトとしての改善要望です。 by zy END
	// 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy BEGIN
	public String isCalenDarFlg{get;set;}
	public String calendarJson{get{
	   List<Map<string, string>> result = new List<Map<string, string>>();
	   result.add(new Map<string, string>{'value' => CALENDAR_SHOW_LABEL, 'label' => CALENDAR_SHOW_LABEL});
	   result.add(new Map<string, string>{'value' => CALENDAR_HIDE_LABEL, 'label' => CALENDAR_HIDE_LABEL});
	   return JSON.serialize(result);
   } set;}
   public static String CALENDAR_SHOW_LABEL = '表示';
   public static String CALENDAR_HIDE_LABEL = '非表示';
   // 2019/12/30 タスクがカレンダーに表示させるか、表示させない切替対応 by zy EN
   // 2020/08/31 担当部署列の追加、ユーザに紐づく部署ではなく、選択リストを引用するように by zy BEGIN
   public String departOptJson{get;set;}
   // 2020/08/31 担当部署列の追加、ユーザに紐づく部署ではなく、選択リストを引用するように by zy END
   // 2020/09/30 右上のタスク選択リストに自分が関連するタスクのみ表示機能と検索機能運用が始まると200以上のタスクが作られることが想定されるため探しやすくするため by zy BEGIN
   public boolean isPublicFlg{get;set;}
   // 2020/09/30 右上のタスク選択リストに自分が関連するタスクのみ表示機能と検索機能運用が始まると200以上のタスクが作られることが想定されるため探しやすくするため by zy BEGIN
   
   // 2020/09/31 画面スクロールを２分割したい by zy BEGIN
   class ToolbarInfo{
	   boolean split;    //２分割
	   boolean taskview; //予定と実績
	   boolean pubflg;    //表示プロジェクト
	}
	public boolean splitFlg{get;set;}
	// 2020/09/31 画面スクロールを２分割したい by zy END
	// 2020/10/30 2.14.特定日のマーキング機能、スケジュールのなかでポイントをうち、右の表示マークをつける機能 by zy BEGIN
	public String markJsons{get;set;} // マーク選択リスト内容
	// 2020/10/30 2.14.特定日のマーキング機能、スケジュールのなかでポイントをうち、右の表示マークをつける機能 by zy END
	// 2020/10/31 プロジェクトオブジェクトのレコードにプロジェクトコードを作成し by zy BEGIN
	// DabaLock重複ロックチェック用キー
	private static final String KEY_DUPLICATE_VALUE = 'duplicate value found:';
  	public String projectFieldName{get;set;}
  	public String projectFieldLabel{get;set;}
  	private static String validateMessage(String key ,String message){
  		message = CommUtils.getFieldValidationMessage(message);
  		if (message.contains(key)) {
			Integer idx = message.indexOf(key) + key.length() + 1;
			String msgStr = message.substring(idx);
			return msgStr.removeEnd(': []');
		} else {
			return message;
		}
  	}
   	private void loadXmlInfo(){
	   projectFieldName = '';
	   projectFieldLabel = '';
	   try{
			// XML読み込み
			Dom.XmlNode targetNode = CommXmlUtils.encodeParseXmlDoc('StaffScheduleConfigXml',null,new String[]{'<COONDITION>','</COONDITION>'});
			for(Dom.XMLNode xmlNode : targetNode.getChildElements()){
				// タグ名
				String attributeName = xmlNode.getName();
				if(attributeName.equalsIgnoreCase('GANTTCONFIG')){
					// 表示tip
					String titleNode = xmlNode.getAttribute('PROJECTCODE_API',null);
					if (!CommUtils.isBlank(titleNode)) {
						projectFieldName = CommUtils.nullTOBlank(titleNode);
						// 2020/10/31 8490 bug fixed by zy BEGIN
						Map<String, Schema.DescribeFieldResult> sobjResutltMap = CommSqlUtils.getAllFieldLst(ProjectMain__c.sobjectType,false,true,true);
						// 2020/10/31 8490 bug fixed by zy END
						if (!sobjResutltMap.containsKey(projectFieldName.toLowerCase())) projectFieldName = '';
						else {
							Schema.DescribeFieldResult ds = sobjResutltMap.get(projectFieldName.toLowerCase());
							if (!ds.isAutoNumber()) projectFieldLabel = ds.getLabel();
						}
					}
				}
			}
		} catch(exception e) {}
   	}
   	// 2020/1-/31 プロジェクトオブジェクトのレコードにプロジェクトコードを作成し by zy END
	// 2020/10/31 2.07.取引先の紐付け by zy BEGIN
	private static List<Account> getAccount(String dataReq){
		Map<String,Object> dataMap = (Map<String,Object>)JSON.deserializeUntyped(dataReq);
		String querySQL = 'select id,name from Account ';
		String dataVal = CommUtils.nulltoBlank(dataMap.get('data')).replaceAll('\"','').replaceAll('\'','');
		if (!COmmUtils.isBLank(dataVal)) querySQL += ' where name like \'%' + dataVal + '%\'';
		querySQL += ' limit 200';
		List<account> accs = Database.query(querySQL);
		return accs;
	}
	// 2020/10/31 2.07.取引先の紐付け by zy END
}