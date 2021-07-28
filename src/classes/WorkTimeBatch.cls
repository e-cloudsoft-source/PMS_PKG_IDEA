public with sharing class WorkTimeBatch implements Database.Batchable<User>, Database.Stateful, Schedulable{
	private Date workbeginDate; 			// 时间范围开始时间
	private Date workendDate; 				// 时间范围结束时间
	private Date workStatusDate; 			// 记录时间
	private String gShopCode;				// 店舗コード
	private Boolean isRequest = false;
	private static final String TIME_WORK_DAY = '勤怠日： ';
	private static final String TIME_WORK_USER = '勤怠者： ';
	private static final String TIME_BOOKING_SERVICE = '出勤予定時間： ';
	private static final String TIME_CHECKIN_SERVICE = '出勤実際時間： ';
	private static final String TIME_BOOKING_QUIT = '退勤予定時間： ';
	private static final String TIME_CHECKOUT_QUIT = '退勤実際時間： ';
	private static final String TIME_NOLEAD_WORK = '勤怠予定あり、実際勤怠情報を見つかりません。 ';
	private static final String TIME_NOSERVICE_WORK = '勤怠予定なし、実際勤怠情報を登録されている。 ';
	private static final String WORK_SIGN = '\n';
	private Map<String,String> userBodyMap;
	private boolean isOneDay = false;
	private Map<String,String> groupFeedItem;
	// Schedule的时间设定
    public static Integer workAddDay = CommDefine__c.getOrgDefaults().ScheduleWorkTimeDays__c == null ?  -2 : CommDefine__c.getOrgDefaults().ScheduleWorkTimeDays__c.intValue();
	// 设定时间范围执行batch
	public WorkTimeBatch(String  pShopCd, Date beginDate , Date endDate){
		isRequest = true;
		gShopCode = pShopCd;
		workbeginDate = beginDate;
		workendDate = endDate;
		workStatusDate = beginDate;
	}
	// 默认执行batch
	public WorkTimeBatch(){
		workStatusDate = system.today();
		if (workAddDay > 0) {
			workbeginDate = workStatusDate;
			workendDate = workStatusDate.addDays(workAddDay);
		} else {
			workbeginDate = workStatusDate.addDays(workAddDay);
			workendDate = workStatusDate;
		}
	}
	// ***********************************
	// スケジュール処理開始
	// ***********************************
	public void execute(SchedulableContext SC) {
		if(isRequest){
			WorkTimeBatch batch = new WorkTimeBatch(gShopCode,workbeginDate,workendDate);
			DataBase.executeBatch(batch,50);
		} else {
			WorkTimeBatch batch = new WorkTimeBatch();
			DataBase.executeBatch(batch,50);
		}
	}
	
	// ***********************************
	// バッチ処理開始
	// ***********************************
	public Iterable<User> start(Database.BatchableContext info){ 
		if (workendDate == null) {
			workendDate = workStatusDate;
			isOneDay = true;
		}
		String userQuery = 'select id,name,DefaultShopCode__c from User where StaffScheduleNoshow__c != true And IsActive = true ';
		if (!CommUtils.isBlank(gShopCode))
			userQuery += ' and ( DefaultShopCode__c = :gShopCode or ShopCode__c = :gShopCode )';
		userQuery += ' order by Department Nulls Last , EmployeeCode__c asc Nulls Last , Name asc Nulls Last';
		List<User> users = DataBase.query(userQuery);
		// 設定情報初期化
		getXmlField();
		groupFeedItem = new Map<String,String>();
		userBodyMap = new Map<String,String>();
		return users;
	}
	// ***********************************
	// バッチロジック処理開始
	// ***********************************
	public void execute(Database.BatchableContext BC, List<User> scope){
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'feeditemid','commentbody'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.FeedComment.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(chkFieldsLst, mm)) {
			return ;
		}
		// 2019/09/15 Security Check BY zyz END
		// 従業員set数据
		set<Id> userIdSet = new set<Id>();
		// 処理ユーザー集合
		Set<Id> processSet = new Set<Id>();
		Map<String,User> userMap = new Map<String,USer>();
		// post数据list
		list<FeedItem> feedItemLst = new list<FeedItem>();
		// 従業員処理作成
		for (User user : scope) {
			userIdSet.add(user.id);
			userMap.put(user.id,user);
		}
		// 检索勤怠管理数据
		list<TimeManagement__c> timeManagementlst = [select id,Name,WorkDay__c,Status__c,WorkerRef__c,
															WorkerName__c,WorkerRef__r.DefaultShopCode__c,WorkerRef__r.Name,
															WorkBeginTime__c,WorkEndTime__c
															from TimeManagement__c where WorkDay__c >=: workbeginDate and WorkDay__c <=: workendDate 
															and WorkerRef__c = :userIdSet
															order by WorkerRef__r.DefaultShopCode__c, WorkerRef__r.Name, WorkDay__c];
		// 勤怠データ作成
		Map<String,TimeManagement__c> userTimeMap = new Map<String,TimeManagement__c>();
		for(TimeManagement__c s : timeManagementlst){
			String key = s.WorkerRef__c + '_' + s.WorkDay__c;
			// 行動の有効
			userTimeMap.put(key,s);
			// 処理ユーザー追加
			processSet.add(s.WorkerRef__c);
		}
		// シフトデータ作成
		Map<string,StaffSchedule__c> staffMap = new Map<string,StaffSchedule__c>();
		for(StaffSchedule__c ss :[select Id,WorkDay__c,StatusLst__c,StopStatusLst__c,StaffUserRef__c from StaffSchedule__c where WorkDay__c >=: workbeginDate AND WorkDay__c <=: workendDate  AND StaffUserRef__c=:userIdSet]){
			String key = ss.StaffUserRef__c + '_' + ss.WorkDay__c;
			staffMap.put(key,ss);
			// 処理ユーザー追加
			processSet.add(ss.StaffUserRef__c);
		}
		// ChatterGroup的Id
		Set<Id> parentSet = getChatterGroup();
		map<String,List<String>> feedItemMap = new map<String,List<String>>();
		Date processDate = workbeginDate;
		while (processDate <= workendDate) {
			for (String userId : processSet) {
				String key = userId + '_' + processDate;
				User user = userMap.get(userId);
				TimeManagement__c tm = userTimeMap.get(key);
				StaffSchedule__c staff = staffMap.get(key);
				String body = '';
				// 無効データ
				if (tm == null && staff == null) continue;
				// 出勤予定なし、実際勤怠情報を登録
				if (tm != null && staff == null) body = TIME_NOSERVICE_WORK + WORK_SIGN + URL.getSalesforceBaseUrl().toExternalForm() + '/' + tm.Id;
				// 出勤予定あり、実際勤怠情報を見つかりませ
				if (tm == null && staff != null) {
					if ((!CommUtils.isBlank(staff.StatusLst__c) && CommUtils.isBlank(staff.StatusLst__c.replaceAll('[0-9:：]', '')))
						||
						(!CommUtils.isBlank(staff.StopStatusLst__c) && CommUtils.isBlank(staff.StopStatusLst__c.replaceAll('[0-9:：]', '')))) 
					body = TIME_NOLEAD_WORK + WORK_SIGN + URL.getSalesforceBaseUrl().toExternalForm() + '/' + staff.Id;
				}
				// 出勤予定あり、実際勤怠あり
				if (tm != null && staff != null) {
					XmlInfo info = null;
					if (shopXmlInfo.containsKey(user.DefaultShopCode__c)) info = shopXmlInfo.get(user.DefaultShopCode__c);
					else info = defXmlInfo;
					TimeInfo timeInfo = new TimeInfo(staff.WorkDay__c,staff.StatusLst__c,staff.StopStatusLst__c);
					body = timeInfo.getWorkTimeInfo(info,tm);
					if (!CommUtils.isBlank(body)) body +=  URL.getSalesforceBaseUrl().toExternalForm() + '/' + tm.Id;
				}
				// Chatterへ送信する
				if(!CommUtils.isBlank(body)){
					if(!feedItemMap.containsKey(userId)) feedItemMap.put(userId,new List<String>());
					String workDay = TIME_WORK_DAY + (DateTime.newInstance(processDate.year(), processDate.month(), processDate.day())).format('yyyy/MM/dd');
					String workbody = WORK_SIGN + WORK_SIGN + workDay + WORK_SIGN + body;
					feedItemMap.get(userId).add(workbody);	
				}
			}
			processDate = processDate.addDays(1);
		}
		for(String userId : feedItemMap.keyset()){
			User user = userMap.get(userId);
			List<String> bodys = feedItemMap.get(userId);
			String workbody = TIME_WORK_USER + user.Name + '(' + bodys.size() + '件)';
			for (String body : bodys) {
				workbody += body;
			}
			for (String parentId : parentSet) {
				FeedItem post = new FeedItem();
				post.Type = 'TextPost';
				post.Body = workbody;
				post.ParentId = ParentId;
				feedItemLst.add(post);
			}
			userBodyMap.put(userId,workbody);
		}
		// Chatterへ送信する
		if (!feedItemLst.isEmpty()) {
			list<FeedComment> insertFeedComments = new list<FeedComment>();
			List<FeedItem> insertFeeds = new List<FeedItem>();
			List<FeedItem> otherFeeds = new List<FeedItem>();
			Map<String,List<FeedComment>> commentMap = new Map<String,List<FeedComment>>();
			for (FeedItem post : feedItemLst) {
				if (!groupFeedItem.containsKey(post.ParentId)) {
					insertFeeds.add(post);
					groupFeedItem.put(post.ParentId,null);
				} else otherFeeds.add(post);
			}
			if (!insertFeeds.isEmpty()) {
				insert insertFeeds;
				for (FeedItem post : insertFeeds) {
					groupFeedItem.put(post.ParentId,post.id);
				}
			}
			for (FeedItem post : otherFeeds) {
				FeedComment contentFC = new FeedComment();
			    contentFC.CommentBody = post.Body;
				contentFC.FeedItemId = groupFeedItem.get(post.ParentId); 
			 	insertFeedComments.add(contentFC);
			}
			if (!insertFeedComments.isEmpty()) insert insertFeedComments;
		}
	}
	// ***********************************
	// バッチ終了処理開始
	// ***********************************
	public void finish(Database.BatchableContext BC){
	    sendMail(workbeginDate);
	}
	// 获取XML定义信息
    private void getXmlField(){
    	shopXmlInfo = new Map<String,XmlInfo>();
    	// 店舗指定
    	if(!CommUtils.isBlank(gShopCode)) {
    		Dom.XMLNode targetNode = CommXmlUtils.parseXmlDoc('StaffScheduleConfigXml',gShopCode);
    		defXmlInfo = new XmlInfo(targetNode);
    	// 多店舗作成
    	} else {
    		List<Dom.XMLNode> targetNodes = CommXmlUtils.getAllTopXmlNode('StaffScheduleConfigXml');
    		for (Dom.XMLNode target : targetNodes) {
    			XmlInfo info = new XmlInfo(target);
    			if (defXmlInfo == null) defXmlInfo = info;
    			shopXmlInfo.put(info.spcd,info);
    		}
    	}
    }
    // 获取ChatterGroup的ID
    private Set<Id> getChatterGroup(){
    	Set<ID> chatterGroupSet = new Set<Id>();
    	// 共通定義:チャターグループ名関連定数取得'10'
        List<String> chatterGroupNamesLst = CommConst.GetChatterGroupNameByCode(CommConst.WORK_ChatterCheckType);
		if (!chatterGroupNamesLst.isEmpty()) {
			List<CollaborationGroup> chatterGroups = [select Id, Name from CollaborationGroup where name = :chatterGroupNamesLst and isarchived = false];
        	if (!chatterGroups.isEmpty()){
        		for (CollaborationGroup chatter : chatterGroups) {
        			chatterGroupSet.add(chatter.id);
        		}
        	}
        }
        return chatterGroupSet;
    }
    // 时间比较处理，返回Body内容
    public static String getWorkTimeBody(String leadTime,String realTime,boolean difFlag){
    	String body = '';
    	if (!CommUtils.isBlank(leadTime) && !CommUtils.isBlank(realTime)) {
    		String begStr = difFlag ? TIME_BOOKING_SERVICE : TIME_BOOKING_QUIT;
    		String endStr = difFlag ? TIME_CHECKIN_SERVICE : TIME_CHECKOUT_QUIT;
    		return begStr + CommUtils.nullToBlank(leadTime) + ' ' + endStr + CommUtils.nullToBlank(realTime) + WORK_SIGN;
    	} else if (CommUtils.isBlank(leadTime) && !CommUtils.isBlank(realTime))
    		return TIME_NOSERVICE_WORK + WORK_SIGN;
    	else if (!CommUtils.isBlank(leadTime) && CommUtils.isBlank(realTime))
    		return TIME_NOLEAD_WORK + WORK_SIGN;
    	return body;
    }
	// Apexでエラー情報を送信を行う
	private void sendMail(Date procDate) {
		//　ScheduleResultMailAddress__c
		String mailAdds = CommDefine__c.getOrgDefaults().ScheduleResultMailAddress__c;
		// メール情報を設定する
		String mailBodyStr = '';
		Map<String, ShopInformation__c> shopInfoMap = ShopInfoUtil.getShopInfoMap();
		String shopName = '';
		// 店铺判断
		if(!shopInfoMap.isEmpty() && shopInfoMap.containsKey(gShopCode)) shopName = CommUtils.nullToBlank(shopInfoMap.get(gShopCode).Name);
		if(!CommUtils.isBlank(shopName)) mailBodyStr += '\n店舗： ' + shopName;
		mailBodyStr += '\n処理期間：';
		if (isOneDay) mailBodyStr += workStatusDate.format();
		else mailBodyStr += workStatusDate.format() + '-' + workendDate.format();
		mailBodyStr += '\n処理結果詳細BEGIN';
		String body = '';
		for (String userId : userBodyMap.keySet()) {
			body += CommUtils.nullToBlank(userBodyMap.get(userId)) + WORK_SIGN + WORK_SIGN;
		}
		if (!CommUtils.isBlank(body)) mailBodyStr += '\n\n' + body;
		
		mailBodyStr += '\n処理結果詳細END';
		mailBodyStr += '\n\n' + Label.INF_9001 + '\n';    //  JinyaConnect Enterprise system R&D team.
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = CommUtils.nullToBlank(mailAdds).split(',');
		mail.setToAddresses(toAddresses);
		mail.setSubject('[勤怠時間チェック] バッチ処理結果の通知['+UserInfo.getOrganizationName()+']');
		mail.setPlainTextBody(mailBodyStr);
		// テストクラスの場合、実施しない
		if(!Test.isRunningTest()) {
			try {
				Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
			} catch(Exception e){}
		}
	}
	private XmlInfo defXmlInfo;
    private Map<String,XmlInfo> shopXmlInfo;
    // 店舗設定情報
    class XmlInfo{
    	public Integer workBeginTimeInt; // 开始时间范围
	    public Integer workEndTimeInt;	 // 结束时间范围
	    public String spcd;
	    public String eventTitle;
	    public boolean eventFlag;
	    public XmlInfo(Dom.XmlNode targetNode){
	    	workBeginTimeInt = 30;
		    workEndTimeInt = 30;
		   	eventFlag = false;
		    if(targetNode != null){
		    	Dom.XmlNode shopNode = targetNode.getChildElement('SHOPCODE', null);
		    	if (shopNode != null) spcd = CommUtils.nullToBlank(shopNode.getText());
		    	Dom.XmlNode workTimeCheck = targetNode.getChildElement('WORKTIMECHECK', null);
		    	if(workTimeCheck != null){
		    		Dom.XmlNode beginTimeRange = workTimeCheck.getChildElement('BEGTIME_RANGE', null);
		    		Dom.XmlNode endTimeRange = workTimeCheck.getChildElement('ENDTIME_RANGE', null);
		    		if(beginTimeRange != null) workBeginTimeInt = CommUtils.nullToIntZero(beginTimeRange.getText());
		    		if(endTimeRange != null) workEndTimeInt = CommUtils.nullToIntZero(endTimeRange.getText());
		    	}
		    	// マルチタスク有効
		    	if (eventFlag) {
		    		Dom.XmlNode appNode = targetNode.getChildElement('APPCONFIG', null);
		    		if (appNode != null) {
		    			Dom.XmlNode eventNode = appNode.getChildElement('EVENT_TITLE',null);
		    			if (eventNode != null) eventTitle = CommUtils.nullToBlank(eventNode.getText());
		    		}
		    	}
		    }
	    }
    }
	class TimeInfo{
		String startStatus;
		String stopStatus;
		Datetime startDt;
		Datetime endDt;
		TimeInfo (Date workDay,String startTm,String endTm) {
			startStatus = startTm;
			stopStatus = endTm;
			String begTime = '';
			if (!CommUtils.isBlank(startStatus) && CommUtils.isBlank(startStatus.replaceAll('[0-9:：]', ''))) {
				// 開始時間
				begTime = CommStringUtils.zenkakuToHankaku(startStatus);
				startDt = CommUtils.convertDatetime(workDay,begTime);
			}
			if (!CommUtils.isBlank(stopStatus) && CommUtils.isBlank(stopStatus.replaceAll('[0-9:：]', ''))) {
				// 終了
				String endTime = CommStringUtils.zenkakuToHankaku(stopStatus);
				// 跨がり日の場合:23:00〜10:00
				if (!CommUtils.isBlank(begTime) && CommUtils.stringtoTime(begTime) > CommUtils.stringtoTime(endTime)) 
					endDt = CommUtils.convertDatetime(workDay.addDays(1),endTime);
				else 
					endDt = CommUtils.convertDatetime(workDay,endTime);
			}
		}
		public String getWorkTimeInfo(XmlInfo info,TimeManagement__c tm){
			String body = '';
			String startBody = '';
			String endBody = '';
			startBody = startDt == null ? CommUtils.nullToBlank(startStatus) : startDt.format('HH:mm');
			endBody = tm.WorkBeginTime__c == null ? '' : tm.WorkBeginTime__c.format('HH:mm');
			// 無効データ
			if (CommUtils.isBlank(startBody) && CommUtils.isBlank(endBody)) return body;
			if (startDt != null && tm.WorkBeginTime__c != null && !checkMaxAfterTime(startDt,tm.WorkBeginTime__c,info.workBeginTimeInt)) body = '';
			else body += getWorkTimeBody(startBody,endBody,true);
//system.debug(logginglevel.info,'body:::' + body);
			startBody = endDt == null ? CommUtils.nullToBlank(stopStatus) : endDt.format('HH:mm');
			endBody = tm.WorkEndTime__c == null ? '' : tm.WorkEndTime__c.format('HH:mm');
			
			// 無効データ
			if (CommUtils.isBlank(startBody) && CommUtils.isBlank(endBody)) return body;
			if (endDt != null && tm.WorkEndTime__c != null && !checkMaxAfterTime(tm.WorkEndTime__c,endDt,info.workEndTimeInt)) return body;
			
			String endBodyStr = getWorkTimeBody(startBody,endBody,false);
			// 去重处理
			if (body.indexOf(endBodyStr) < 0) body += endBodyStr;
			
			return body;
		}
		private boolean checkMaxAfterTime(Datetime begTm,Datetime endTm,Integer checkDiff){
			integer difTime = CommUtils.nullToIntZero((begTm.getTime() - endTm.getTime()) / (1000 * 60));
			return difTime > checkDiff;
		}
	}
}