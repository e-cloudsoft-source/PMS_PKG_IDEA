/****************
* 勤怠管理一連動作のテストクラス
*****************/
@isTest
private class UserManagerTest {

    static testMethod void myUnitTest1() {
    	createWorkDefine();
    	// 2015/12/01 Assert BEGIN
		System.assertEquals([select Id from Document where Name = 'StaffScheduleConfigXml'].size(), 1);
		// 2015/12/01 Assert END
        //追加テスト
        DateTime beforeDt = System.now().addDays(-1);
		Date beforeDay = beforeDt.date();
		TimeManagement__c beforeItem = new TimeManagement__c(
		    Status__c = System.Label.MSG_1019,
			WorkDay__c = beforeDay,
			WorkerRef__c = UserInfo.getUserId(),
			WorkerName__c = UserInfo.getName(),
			WorkBeginTime__c = System.now().addDays(-1),
			OutingTime__c = System.now().addDays(-1),
			OutingTime2__c = System.now().addDays(-1), 
			OutingTime3__c = System.now().addDays(-1) 
		);
		insert beforeItem;
		System.currentPageReference().getParameters().put('actionType','9');
		UserManager.regiestWorkTime(9);
		UserManager con = new UserManager();
		con.getNowDateTime();
		con.apexRegiestWorkTime();
		System.currentPageReference().getParameters().put('actionType','2');
		con.apexRegiestWorkTime();
		System.currentPageReference().getParameters().put('actionType','3');
        con.apexRegiestWorkTime();
        //時間端数処理テスト
        List<User> userList = [select Id,RestCalMethodType__c,RestTimeUnit__c from User where Id = :userInfo.getUserId()];
	    if(!userList.isEmpty()){
	    	userList[0].RestCalMethodType__c = System.Label.MSG_1022;
	    	userList[0].RestTimeUnit__c = '10分';
	    	update userList;
	    	
	    	System.currentPageReference().getParameters().put('actionType','1');
	        UserManager con0 = new UserManager();
	        con0.apexRegiestWorkTime();
	        con0.BeforeApprovalProcess();
	        DateTime newDt = System.now();
			Date busDay = newDt.date();
	        List<TimeManagement__c> wkTimeLst = [select Id,
	        											Status__c,
														WorkBeginTime__c,
														WorkEndTime__c,
														OutingTime__c,
														EnteringTime__c 
				from TimeManagement__c where WorkerRef__c = :userInfo.getUserId() And WorkDay__c = :busDay limit 1];
			if(!wkTimeLst.isEmpty()){
				wkTimeLst[0].Status__c = System.Label.MSG_1019;
				wkTimeLst[0].OutingTime__c = System.now().addHours(2);
				wkTimeLst[0].EnteringTime__c = System.now().addHours(3);
				update wkTimeLst[0];
				
				userList[0].RestCalMethodType__c = System.Label.MSG_1023;
		    	userList[0].RestTimeUnit__c = '1分';
		    	update userList;
		    	
		    	wkTimeLst[0].Status__c = System.Label.MSG_1019;
				wkTimeLst[0].OutingTime__c = System.now().addHours(2);
				wkTimeLst[0].EnteringTime__c = System.now().addHours(4);
				update wkTimeLst[0];
				
				userList[0].RestCalMethodType__c = System.Label.MSG_1023;
		    	userList[0].RestTimeUnit__c = '10分';
		    	update userList;
		    	
		    	wkTimeLst[0].Status__c = System.Label.MSG_1019;
				wkTimeLst[0].OutingTime__c = System.now().addHours(2);
				wkTimeLst[0].EnteringTime__c = System.now().addHours(5);
				update wkTimeLst[0];
				
				userList[0].RestCalMethodType__c = System.Label.MSG_1024;
		    	userList[0].RestTimeUnit__c = '60分';
		    	update userList;
		    	
		    	wkTimeLst[0].Status__c = System.Label.MSG_1019;
				wkTimeLst[0].OutingTime__c = datetime.newInstance(2014, 1, 5, 12, 0, 0);
				wkTimeLst[0].EnteringTime__c = datetime.newInstance(2014, 1, 5, 14, 0, 0);
				update wkTimeLst[0];
				
				wkTimeLst[0].Status__c = System.Label.MSG_1019;
				wkTimeLst[0].OutingTime__c = datetime.newInstance(2014, 1, 5, 12, 0, 0);
				wkTimeLst[0].EnteringTime__c = datetime.newInstance(2014, 1, 5, 12, 40, 0);
				update wkTimeLst[0];
				
				wkTimeLst[0].Status__c = System.Label.MSG_1019;
				wkTimeLst[0].OutingTime__c = datetime.newInstance(2014, 1, 5, 12, 0, 0);
				wkTimeLst[0].EnteringTime__c = datetime.newInstance(2014, 1, 5, 12, 20, 0);
				update wkTimeLst[0];
				
				userList[0].RestCalMethodType__c = null;
		    	userList[0].RestTimeUnit__c = '60分';
		    	update userList;
		    	
		    	wkTimeLst[0].Status__c = System.Label.MSG_1019;
				wkTimeLst[0].OutingTime__c = datetime.newInstance(2014, 1, 5, 12, 0, 0);
				wkTimeLst[0].EnteringTime__c = datetime.newInstance(2014, 1, 5, 12, 30, 0);
				update wkTimeLst[0];
				
			}
	    }
    }
    
    static testMethod void myUnitTest2() {
    	createWorkDefine();
    	// 2015/12/01 Assert BEGIN
		System.assertEquals([select Id from Document where Name = 'StaffScheduleConfigXml'].size(), 1);
		// 2015/12/01 Assert END
    	
        System.currentPageReference().getParameters().put('actionType','1');
        UserManager con0 = new UserManager();
        con0.apexRegiestWorkTime();
        con0.BeforeApprovalProcess();
        DateTime newDt = System.now();
		Date busDay = newDt.date();
        List<TimeManagement__c> wkTimeLst = [select Id,
        											Status__c,
													WorkBeginTime__c,
													WorkEndTime__c,
													OutingTime__c,
													EnteringTime__c,
													OutingTime2__c,
													EnteringTime2__c,
													OutingTime3__c,
													EnteringTime3__c
			from TimeManagement__c where WorkerRef__c = :userInfo.getUserId() And WorkDay__c = :busDay limit 1];
		if(!wkTimeLst.isEmpty()){
			//
			wkTimeLst[0].Status__c = System.Label.MSG_1019;
			wkTimeLst[0].OutingTime__c = System.now().addHours(2);
			wkTimeLst[0].EnteringTime__c = System.now().addHours(3);
			wkTimeLst[0].OutingTime2__c = System.now().addHours(5);
			wkTimeLst[0].EnteringTime2__c = System.now().addHours(6);
			wkTimeLst[0].OutingTime3__c = null;
			wkTimeLst[0].EnteringTime3__c = null;
			wkTimeLst[0].WorkEndTime__c = System.now().addHours(10);
			update wkTimeLst[0];
			UserManager con2 = new UserManager();
			System.currentPageReference().getParameters().put('actionType','2');
			con2.apexRegiestWorkTime();
			System.currentPageReference().getParameters().put('actionType','3');
	        con2.apexRegiestWorkTime();
			//
			wkTimeLst[0].Status__c = System.Label.MSG_1019;
			wkTimeLst[0].OutingTime__c = System.now().addHours(2);
			wkTimeLst[0].EnteringTime__c = System.now().addHours(3);
			wkTimeLst[0].OutingTime2__c = null;
			wkTimeLst[0].EnteringTime2__c = null;
			wkTimeLst[0].OutingTime3__c = null;
			wkTimeLst[0].EnteringTime3__c = null;
			wkTimeLst[0].WorkEndTime__c = System.now().addHours(10);
			update wkTimeLst[0];
			UserManager con3 = new UserManager();
			System.currentPageReference().getParameters().put('actionType','2');
			con3.apexRegiestWorkTime();
			System.currentPageReference().getParameters().put('actionType','3');
	        con3.apexRegiestWorkTime();
			//
			wkTimeLst[0].Status__c = System.Label.MSG_1019;
			wkTimeLst[0].OutingTime__c = null;
			wkTimeLst[0].EnteringTime__c = null;
			wkTimeLst[0].OutingTime2__c = null;
			wkTimeLst[0].EnteringTime2__c = null;
			wkTimeLst[0].OutingTime3__c = null;
			wkTimeLst[0].EnteringTime3__c = null;
			wkTimeLst[0].WorkEndTime__c = null;
			update wkTimeLst[0];
			System.currentPageReference().getParameters().put('actionType','2');
			UserManager con4 = new UserManager();
			con4.apexRegiestWorkTime();
	        System.currentPageReference().getParameters().put('actionType','3');
	        con4.apexRegiestWorkTime();
	        System.currentPageReference().getParameters().put('actionType','9');
        	con4.apexRegiestWorkTime();
        	
		}
    }
    
    static testMethod void myUnitTest2_1() {
    	createWorkDefine();
    	// 2015/12/01 Assert BEGIN
		System.assertEquals([select Id from Document where Name = 'StaffScheduleConfigXml'].size(), 1);
		// 2015/12/01 Assert END
        System.currentPageReference().getParameters().put('actionType','1');
        UserManager con0 = new UserManager();
        con0.apexRegiestWorkTime();
        con0.BeforeApprovalProcess();
        DateTime newDt = System.now();
		Date busDay = newDt.date();
        List<TimeManagement__c> wkTimeLst = [select Id,
        											Status__c,
													WorkBeginTime__c,
													WorkEndTime__c,
													OutingTime__c,
													EnteringTime__c,
													OutingTime2__c,
													EnteringTime2__c,
													OutingTime3__c,
													EnteringTime3__c
			from TimeManagement__c where WorkerRef__c = :userInfo.getUserId() And WorkDay__c = :busDay limit 1];
		if(!wkTimeLst.isEmpty()){
			//
			wkTimeLst[0].Status__c = System.Label.MSG_1019;
			wkTimeLst[0].OutingTime__c = null;
			wkTimeLst[0].EnteringTime__c = null;
			wkTimeLst[0].OutingTime2__c = null;
			wkTimeLst[0].EnteringTime2__c = null;
			wkTimeLst[0].OutingTime3__c = null;
			wkTimeLst[0].EnteringTime3__c = null;
			wkTimeLst[0].WorkEndTime__c = null;
			update wkTimeLst[0];
			System.currentPageReference().getParameters().put('actionType','2');
			UserManager con4 = new UserManager();
			con4.apexRegiestWorkTime();
	        System.currentPageReference().getParameters().put('actionType','3');
	        con4.apexRegiestWorkTime();
	        System.currentPageReference().getParameters().put('actionType','9');
        	con4.apexRegiestWorkTime();
        	
        	wkTimeLst[0].Status__c = System.Label.MSG_1019;
			wkTimeLst[0].OutingTime__c = System.now().addHours(2);
			wkTimeLst[0].EnteringTime__c = System.now().addHours(3);
			wkTimeLst[0].OutingTime2__c = System.now().addHours(5);
			wkTimeLst[0].EnteringTime2__c = System.now().addHours(6);
			wkTimeLst[0].OutingTime3__c = System.now().addHours(7);
			wkTimeLst[0].EnteringTime3__c = System.now().addHours(8);
			wkTimeLst[0].WorkEndTime__c = System.now().addHours(10);
			wkTimeLst[0].WorkBeginTimeHM__c = '01:00';
			wkTimeLst[0].WorkEndTimeHM__c = '10:00';
			wkTimeLst[0].OutingTimeHM__c = '02:00';
			wkTimeLst[0].EnteringTimeHM__c = '03:00';
			wkTimeLst[0].OutingTime2HM__c = '04:00';
			wkTimeLst[0].EnteringTime2HM__c = '05:00';
			wkTimeLst[0].OutingTime3HM__c = '06:10';
			wkTimeLst[0].EnteringTime3HM__c = '07:00';
			update wkTimeLst[0];
			UserManager con1 = new UserManager();
			System.currentPageReference().getParameters().put('actionType','2');
			con1.apexRegiestWorkTime();
			System.currentPageReference().getParameters().put('actionType','3');
	        con1.apexRegiestWorkTime();
	        wkTimeLst[0].Status__c = '';
	        update wkTimeLst[0];
        	con1.ViewReportProcess();
		}
    }
    
    static testMethod void myUnitTest3() {
    	createWorkDefine();
    	// 2015/12/01 Assert BEGIN
		System.assertEquals([select Id from Document where Name = 'StaffScheduleConfigXml'].size(), 1);
		// 2015/12/01 Assert END
        System.currentPageReference().getParameters().put('actionType','1');
        UserManager con0 = new UserManager();
        con0.apexRegiestWorkTime();
        con0.BeforeApprovalProcess();
        DateTime newDt = System.now();
		Date busDay = newDt.date();
        List<TimeManagement__c> wkTimeLst = [select Id,
        											Status__c,
													WorkBeginTime__c,
													WorkEndTime__c,
													OutingTime__c,
													EnteringTime__c,
													OutingTime2__c,
													EnteringTime2__c,
													OutingTime3__c,
													EnteringTime3__c
			from TimeManagement__c where WorkerRef__c = :userInfo.getUserId() And WorkDay__c = :busDay limit 1];
		if(!wkTimeLst.isEmpty()){
			//
			wkTimeLst[0].Status__c = System.Label.MSG_1019;
			wkTimeLst[0].OutingTime__c = System.now().addHours(2);
			wkTimeLst[0].EnteringTime__c = System.now().addHours(3);
			wkTimeLst[0].OutingTime2__c = System.now().addHours(5);
			wkTimeLst[0].EnteringTime2__c = System.now().addHours(6);
			wkTimeLst[0].OutingTime3__c = null;
			wkTimeLst[0].EnteringTime3__c = null;
			wkTimeLst[0].WorkEndTime__c = System.now().addHours(10);
			update wkTimeLst[0];
        	
        	//勤務休憩時間を作成する
            RestTimeManagement__c restTimeItem = new RestTimeManagement__c(
                WorkTimeInfo__c = wkTimeLst[0].Id,
                OutingTime__c = System.now().addHours(1),
                OutingTimeHM__c = '10:00',
                EnteringTime__c = System.now().addHours(1)
            );
            insert restTimeItem ;
            UserManager con1 = new UserManager();
            
            restTimeItem.EnteringTime__c = System.now().addHours(2);
            restTimeItem.EnteringTimeHM__c = '18:40';
            update restTimeItem;
            /*
            //承認プロセスを起こします
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Submitting request for approval.');
            req1.setObjectId(wkTimeLst[0].Id);
            req1.setNextApproverIds(new Id[]{UserInfo.getUserId()});
            Approval.ProcessResult result = Approval.process(req1);
            //承認プロセスを承認する
            List<Id> newWorkItemIds = result.getNewWorkitemIds();
            Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
            req2.setComments('Approving request.');
            req2.setAction('Approve');
            //req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});
            req2.setWorkitemId(newWorkItemIds.get(0));
            Approval.ProcessResult result2 =  Approval.process(req2);
            */
            //勤怠管理を更新
            wkTimeLst[0].WorkEndTimeHM__c = '10:00';
            try{update wkTimeLst[0];}catch(DmlException e){}
            //勤務休憩時間を更新
            restTimeItem.EnteringTimeHM__c = '03:00';
            restTimeItem.OutingTimeHM__c = '04:00';
            try{update restTimeItem;}catch(DmlException e){}
		}
    }
    
    static testMethod void myUnitTest4() {
    	createWorkDefine();
    	// 2015/12/01 Assert BEGIN
		System.assertEquals([select Id from Document where Name = 'StaffScheduleConfigXml'].size(), 1);
		// 2015/12/01 Assert END
    	User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
    	User u;
		System.runAs ( thisUser ) {
		    //List<Profile> pList = [SELECT Id FROM Profile WHERE Name =: System.Label.MSG_1016]; 
		    u = new User(Alias = 'standt', Email='standarduser11'+commutils.getRandom(6)+'@testorg.com', 
		    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
		    LocaleSidKey='en_US', ProfileId = UserInfo.getProfileId(),//pList[0].Id, 
		    TimeZoneSidKey='America/Los_Angeles', UserName='standarduser111'+commutils.getRandom(6)+'@testorg.com');
		}
        
	    System.runAs(u) {
		    System.currentPageReference().getParameters().put('actionType','1');
	        UserManager con0 = new UserManager();
	        con0.apexRegiestWorkTime();
	        DateTime newDt = System.now();
			Date busDay = newDt.date();
	        List<TimeManagement__c> wkTimeLst = [select Id,Status__c from TimeManagement__c where WorkerRef__c = :userInfo.getUserId() And WorkDay__c = :busDay limit 1];
				if(!wkTimeLst.isEmpty()){
					//勤務休憩時間を作成する
	            	RestTimeManagement__c restTimeItem = new RestTimeManagement__c(
	                WorkTimeInfo__c = wkTimeLst[0].Id,
	                OutingTime__c = System.now().addHours(1),
	                OutingTimeHM__c = '10:00'
		            );
		            insert restTimeItem ;
		            restTimeItem.EnteringTime__c = System.now().addHours(2);
		            restTimeItem.EnteringTimeHM__c = '18:40';
		            try{update restTimeItem;}catch(DmlException e){}
		            
		            wkTimeLst[0].Status__c = System.Label.MSG_1019;
		            update wkTimeLst;
		            
		            restTimeItem.EnteringTime__c = System.now().addHours(2);
		            restTimeItem.EnteringTimeHM__c = '18:40';
		            try{update restTimeItem;}catch(DmlException e){}
		            
				}
	    }
    }
    // 夜間出勤(またがり)
    static testMethod void myUnitTest5() {
    	createWorkDefine();
    	// 2015/12/01 Assert BEGIN
		System.assertEquals([select Id from Document where Name = 'StaffScheduleConfigXml'].size(), 1);
		// 2015/12/01 Assert END
    	User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
    	User u;
		System.runAs ( thisUser ) {
		    //List<Profile> pList = [SELECT Id FROM Profile WHERE Name =: System.Label.MSG_1016]; 
		    u = new User(Alias = 'standt', Email='standarduser11'+commutils.getRandom(6)+'@testorg.com', 
		    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
		    LocaleSidKey='en_US', ProfileId = UserInfo.getProfileId(),//pList[0].Id, 
		    TimeZoneSidKey='America/Los_Angeles', UserName='standarduser111'+commutils.getRandom(6)+'@testorg.com');
		}
        
	    System.runAs(u) {
		    System.currentPageReference().getParameters().put('actionType','1');
	        UserManager con0 = new UserManager();
	        con0.apexRegiestWorkTime();
	        DateTime newDt = System.now();
			Date busDay = Date.today();
	        List<TimeManagement__c> wkTimeLst = [select Id,Status__c from TimeManagement__c where WorkerRef__c = :userInfo.getUserId() And WorkDay__c = :busDay limit 1];
			if(!wkTimeLst.isEmpty()){
				wkTimeLst[0].WorkDay__c = busDay.addDays(-1);
				update wkTimeLst[0];
				
				System.currentPageReference().getParameters().put('actionType','2');
				UserManager con2 = new UserManager();
				System.currentPageReference().getParameters().put('actionType','3');
				con2 = new UserManager();
				con2.apexRegiestWorkTime();
				System.currentPageReference().getParameters().put('actionType','2');
				con2 = new UserManager();
				con2.apexRegiestWorkTime();
				System.currentPageReference().getParameters().put('actionType','3');
				con2 = new UserManager();
				con2.apexRegiestWorkTime();
				System.currentPageReference().getParameters().put('actionType','2');
				con2 = new UserManager();
				con2.apexRegiestWorkTime();
				System.currentPageReference().getParameters().put('actionType','3');
				con2 = new UserManager();
				con2.apexRegiestWorkTime();
				System.currentPageReference().getParameters().put('actionType','2');
				con2 = new UserManager();
				con2.apexRegiestWorkTime();
				System.currentPageReference().getParameters().put('actionType','3');
				con2 = new UserManager();
				con2.apexRegiestWorkTime();
				System.currentPageReference().getParameters().put('actionType','9');
				con2 = new UserManager();
				con2.apexRegiestWorkTime();
			}
	    }
    }
    
    private static void createWorkDefine() {
    	WorkTimeDefine__c newItem = new WorkTimeDefine__c(Name = '共通(削除禁止)');
    	insert newItem;
    	
    	String csv = '<?xml version="1.0" encoding="utf-8"?><root>    <SHOP>        <SHOPCODE></SHOPCODE>        <SUMMARY TITLE="泊素(2〜3人)">          <LOGIC>({0} OR {1}) AND {2}</LOGIC>          <COONDITION>              StayPersons__c  <10           </COONDITION>           <COONDITION>             StayPersons__c  >3          </COONDITION>          <COONDITION>             Departure__c >= 2013-11-01T00:00:00Z          </COONDITION>        </SUMMARY>        <SUMMARY TITLE="日帰(3人以上)">        <LOGIC> {0}</LOGIC>          <COONDITION>                 (StayPersons__c  <10 or  StayPersons__c  >3)  and Departure__c = 2015-09-15T00:00:00Z          </COONDITION>        </SUMMARY>        <SUMMARY TITLE="婚礼">        	<LOGIC>{0} and {1}</LOGIC>          <COONDITION>                StayPersons__c >= 2          </COONDITION>          <COONDITION>          		StayPersons__c < 10          </COONDITION>                  </SUMMARY>        <WORKTIME>        	<WORK_START>        		<BACKCOLOR>#afeeee</BACKCOLOR>        		<FONTCOLOR>black</FONTCOLOR>        	</WORK_START>        	<WORK_REST_START>        		<BACKCOLOR>#ffa500</BACKCOLOR>        		<FONTCOLOR>black</FONTCOLOR>        	</WORK_REST_START>        	<WORK_REST_END>        		<BACKCOLOR>#f5deb3</BACKCOLOR>        		<FONTCOLOR>black</FONTCOLOR>        	</WORK_REST_END>        	<WORK_END>        		<BACKCOLOR>#dcdcdc</BACKCOLOR>        		<FONTCOLOR>black</FONTCOLOR>        	</WORK_END>        	<WORK_COMMENT>        		<BACKCOLOR>#f5deb3</BACKCOLOR>        		<FONTCOLOR>black</FONTCOLOR>        	</WORK_COMMENT>        </WORKTIME>    </SHOP></root>';

    	Document StaffScheduleConfigXml = new Document();
		StaffScheduleConfigXml.Name = 'StaffScheduleConfigXml';
		StaffScheduleConfigXml.DeveloperName = StaffScheduleConfigXml.Name;
    	StaffScheduleConfigXml.FolderId = UserInfo.getUserId();
    	StaffScheduleConfigXml.Body = Blob.valueOf(csv);
    	insert StaffScheduleConfigXml;	
    }
    // 2019/02/28 BY zyz BEGIN
    static testMethod void myUnitTest6() {
    	createWorkDefine1();
    	// 2015/12/01 Assert BEGIN
		System.assertEquals([select Id from Document where Name = 'StaffScheduleConfigXml'].size(), 1);
		// 2015/12/01 Assert END
    	User thisUser = [ select Id,Name,DefaultShopCode__c from User where Id = :UserInfo.getUserId() ];
        //勤怠情報
        DateTime beforeDt = System.now().addDays(-1);
		Date beforeDay = beforeDt.date();
		string startTime='8:00';
		DateTime timeInfo = CommUtils.convertDatetime(beforeDay,'8:00');
        TimeManagement__c beforeItem = new TimeManagement__c(
		    Status__c = System.Label.MSG_1019,
			WorkDay__c = beforeDay,
			WorkerRef__c = UserInfo.getUserId(),
			WorkerName__c = UserInfo.getName(),
			WorkBeginTime__c =  timeInfo,
			OutingTime__c = System.now().addDays(-1),
			OutingTime2__c = System.now().addDays(-1), 
			OutingTime3__c = System.now().addDays(-1) 
		);
		insert beforeItem;
    	
    	StaffSchedule__c staff = new StaffSchedule__c(
    		StatusLst__c = '10:00',
    		StopStatusLst__c = '18:00',
    		TimeManagementRef__c = beforeItem.Id,
    		WorkDay__c = beforeDay,
    		EventTitle__c = 'sf',
    		StaffUserRef__c = UserInfo.getUserId()
    	);
    	insert staff;
    	
	    Test.startTest();
   		Date DT = Date.today();
        WorkTimeBatch schedule = new WorkTimeBatch();
        DateTime nowTime = DateTime.now().addDays(10);
		// 起動ＣＲＯＮを設定する
		String timeStr = nowTime.format('yyyyMMddHHmmss');
		String yy = timeStr.substring(0,4);
		String mm = timeStr.substring(4,6);
		String dd = timeStr.substring(6,8);
		String hh = timeStr.substring(8,10);
		String ms = timeStr.substring(10,12);
		String ss = timeStr.substring(12,14);
		String sch = ss + ' ' +
		       ms + ' ' +
		       hh + ' ' +
		       dd + ' ' +
		       mm + ' ' +
		       ' ? ' + yy;
		String jobName = DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, sch, schedule);
		Test.stopTest();
		System.assert(jobId != null);
    }
    static testMethod void myUnitTest7() {
    	createWorkDefine1();
    	List<CollaborationGroup> groups = TestCommon.createGroups(1);
		CommDefine__c newDef = new CommDefine__c(
	    	ChatterGroupName__c = '3:'+groups[0].name
		);	
		insert newDef;
    	// 2015/12/01 Assert BEGIN
		System.assertEquals([select Id from Document where Name = 'StaffScheduleConfigXml'].size(), 1);
		// 2015/12/01 Assert END
    	User thisUser = [ select Id,Name,DefaultShopCode__c from User where Id = :UserInfo.getUserId() ];
        //勤怠情報
        DateTime beforeDt = System.now().addDays(-1);
		Date beforeDay = beforeDt.date();
		string startTime='8:00';
		DateTime timeInfo = CommUtils.convertDatetime(beforeDay,'8:00');
        TimeManagement__c beforeItem = new TimeManagement__c(
		    Status__c = System.Label.MSG_1019,
			WorkDay__c = beforeDay,
			WorkerRef__c = thisUser.Id,
			WorkerName__c = thisUser.Name,
			WorkBeginTime__c =  timeInfo,
			OutingTime__c = System.now().addDays(-1),
			OutingTime2__c = System.now().addDays(-1), 
			OutingTime3__c = System.now().addDays(-1) 
		);
		insert beforeItem;
    	// シフト
    	StaffSchedule__c staff = new StaffSchedule__c(
    		StatusLst__c = '10:00',
    		StopStatusLst__c = '18:00',
    		TimeManagementRef__c = beforeItem.Id,
    		WorkDay__c = beforeDay,
    		EventTitle__c = 'sf',
    		StaffUserRef__c = thisUser.Id
    	);
    	insert staff;
    	
	    Test.startTest();
	    Date begDt = CommUtils.StringtoDate('2019/02/01');
	    Date endDt = CommUtils.stringtoDate('2019/02/28');
	    WorkTimeBatch batch = new WorkTimeBatch('01',begDt,endDt);
	    DataBase.executeBatch(batch);
	    WorkTimeBatch batch1 = new WorkTimeBatch('01',begDt,null);
	    DataBase.executeBatch(batch1);
	    Test.stopTest();
    }
    private static void createWorkDefine1() {
    	WorkTimeDefine__c newItem = new WorkTimeDefine__c(Name = '共通(削除禁止)');
    	insert newItem;
    	
    	String csv = '<?xml version="1.0" encoding="utf-8"?><root><SHOP><SHOPCODE>02</SHOPCODE><WORKTIMECHECK><BEGTIME_RANGE>30</BEGTIME_RANGE><ENDTIME_RANGE>30</ENDTIME_RANGE><SCHEDULE_DAYS>2</SCHEDULE_DAYS></WORKTIMECHECK></SHOP></root>';
    	Document StaffScheduleConfigXml = new Document();
		StaffScheduleConfigXml.Name = 'StaffScheduleConfigXml';
		StaffScheduleConfigXml.DeveloperName = StaffScheduleConfigXml.Name;
    	StaffScheduleConfigXml.FolderId = UserInfo.getUserId();
    	StaffScheduleConfigXml.Body = Blob.valueOf(csv);
    	insert StaffScheduleConfigXml;	
    }	
    // 2019/02/28 BY zyz END
}