@isTest
private class StaffScheduleCtrlTest {
    static testMethod void Case1() {
        
        createDocument();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'StaffScheduleConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        ShopInformation__c tempShop = TestCommon.createShopInfo();
        User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        loginUser.ShopCode__c = tempShop.shopcode__c;
        update loginUser;
        
        TestCommon.createWorkTimeDefine(tempShop.shopcode__c);
        
        System.runAs(loginUser) {
        List<TimeManagement__c> createTimeManagements = createTimeManagements(10,loginUser.id);
        List<Event> newEvents = createEvents(10);

        Test.startTest();
        StaffScheduleCtrl ssc = new StaffScheduleCtrl();

        // ssc.copyInfo = new StaffScheduleCtrl.CopySetupInfo();
        //ssc.copyInfo.copyOrgDate = '2015/08/01';
        //ssc.copyInfo.copyUserIds = UserInfo.getUserId();
        //ssc.copyInfo.isWeekRepeat = true;
        //ssc.copyInfo.weekOpts = 'Saturday';
        //ssc.copyInfo.startDate = '2015/08/02';
        //ssc.copyInfo.endDate = '2015/08/09';

        ssc.init();
        ssc.refreshNewInfo();
        //ssc.copyScheduleInfo();
        ssc.toNext();
        ssc.toPrev();
        ssc.gotoYearMonth();
        ssc.changeBranchShop();

        Test.stopTest();
        }
    }
    static testMethod void Case2() {
        Test.startTest();
        String st = '{"summaryKeyValMap":{"Segment__c":["婚礼","VIP","団体"],"ReservedType__c":["泊 素","日帰"]},"conditionVal":["泊 素","日帰","婚礼","VIP","団体"],"conditionKey":["ReservedType__c","ReservedType__c","Segment__c","Segment__c","Segment__c"]}';
        Map<String, String> summaryTitleInfo = StaffScheduleCtrl.summaryTitleInfo(UserUtil.CurrentUser.ShopCode__c,'2015/08/01','2015/08/31',st);
        // 2015/12/01 Assert BEGIN
        System.assertEquals(summaryTitleInfo.size(), 0);
        // 2015/12/01 Assert END
        Test.stopTest();
    }
    static testMethod void Case3() {
        Test.startTest();
        String st = '[{"staffdate":"2015/08/04","uid":"00510000004krQzAAI","staffStatus":"8時〜","staffComment":"","staffid":"a1A1000000086vaEAA","timeStmp":1439046045000}]';
        List<StaffScheduleCtrl.StaffSchedule> saveTimeMessage2 = StaffScheduleCtrl.saveTimeMessage(st,'テスト勤怠');
        // 2015/12/01 Assert BEGIN
        System.assertEquals(saveTimeMessage2.size(), 1);
        // 2015/12/01 Assert END
        Test.stopTest();
    }
    
    static testMethod void Case4() {
        User u = TestCommon.CreateUser();
        insert u ;
         CommDefine__c newDef = new CommDefine__c(
            RoomTypeReport__c = '$0001 客室タイプ別予約表',
            Posreg__c = '0',
            UnitPriceDefKb__c = 2,
            ScheduleResultMailAddress__c = '1@a.com,2@b.com,3@c.com,4@d.com,5@e.com,6@f.com',
            RoomIndicatorInfoMaxLength__c = 4,
            RoomSortDiv__c = '1',
            BookingMansDef__c = 1,
            BookingFemailsDef__c = 0,
            BookingChildrenDef__c = 0,
            RoomTypeStartDateMode__c = '2'
        );  
        insert newDef;
        
        createDocument();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'StaffScheduleConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        createStaffScedule(u.id);
        //createTimeManagements(20,u.id);
        Test.startTest();
        StaffScheduleCtrl ssc = new StaffScheduleCtrl();
        ssc.init();
        StaffScheduleCtrl.RefreshResult result = StaffScheduleCtrl.refreshTimeMessage('2015/08/04','2015/08/24',u.id,true);
        String summaryXml = '{\"summaryKeyValMap\":{\"null\":[\"泊素(2〜3人)\",\"日帰(3人以上)\",\"婚礼\"]},\"conditionVal\":[\"泊素(2〜3人)\",\"日帰(3人以上)\",\"婚礼\"],\"conditionKey\":[\"id\",\"id\",\"id\"]}';
        StaffScheduleCtrl.LeadMessageInfo info = StaffScheduleCtrl.summaryTitleInfoByXml('', '2015/08/04', '2015/08/24' ,summaryXml);
        Test.stopTest();
    }
    // 2016/07/22  ゆもとや様より改善要望(シフト表示開始日の変更)  wgch       BEGIN
    static testMethod void Case5() {
        
        createDocument1();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'StaffScheduleConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        ShopInformation__c tempShop = TestCommon.createShopInfo();
        User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        loginUser.ShopCode__c = tempShop.shopcode__c;
        update loginUser;
        
        TestCommon.createWorkTimeDefine(tempShop.shopcode__c);
        
        System.runAs(loginUser) {
        List<TimeManagement__c> createTimeManagements = createTimeManagements(10,loginUser.id);
        List<Event> newEvents = createEvents(10);

        Test.startTest();
        StaffScheduleCtrl ssc = new StaffScheduleCtrl();

        // ssc.copyInfo = new StaffScheduleCtrl.CopySetupInfo();
        //ssc.copyInfo.copyOrgDate = '2015/08/01';
        //ssc.copyInfo.copyUserIds = UserInfo.getUserId();
        //ssc.copyInfo.isWeekRepeat = true;
        //ssc.copyInfo.weekOpts = 'Saturday';
        //ssc.copyInfo.startDate = '2015/08/02';
        //ssc.copyInfo.endDate = '2015/08/09';

        ssc.init();
        ssc.refreshNewInfo();
        //ssc.copyScheduleInfo();
        ssc.toNext();
        ssc.toPrev();
        ssc.gotoYearMonth();
        ssc.changeBranchShop();

        Test.stopTest();
        }
    }
    // 2016/07/22  ゆもとや様より改善要望(シフト表示開始日の変更)  wgch       END
    static testMethod void Case6() {
        
        createDocument1();
        ShopInformation__c tempShop = TestCommon.createShopInfo();
        User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        loginUser.ShopCode__c = tempShop.shopcode__c;
        update loginUser;
        
        TestCommon.createWorkTimeDefine(tempShop.shopcode__c);
        TestCommon.createLead();
        System.runAs(loginUser) {
        List<Event> newEvents = createEvents(10);
        createStaffScedule(loginUser.id);
        Test.startTest();
        StaffTaskCtrl ssc = new StaffTaskCtrl();

        ssc.init();
        ssc.gotoYearMonth();
        ssc.changeBranchShop();
        ssc.refreshNewInfo();
        ssc.refreshMode();
        ssc.getViewModeList();
        ssc.getJsonSummaryInfo();
        /*
        ssc.leadJson;
        ssc.infos;
        ssc.dispHeaderJson;
        ssc.staffJson;*/
        /**/
        // -------------------
        Test.stopTest();
        }
    }
        
    static testMethod void Case7() {
        createDocument1();
        ShopInformation__c tempShop = TestCommon.createShopInfo();
        User u = TestCommon.CreateUser();
        u.shopCode__c = '02';
        insert u;
        String userId = u.id;
        String st = '[{"staffdate":"2015/08/04","uid":"' + userId + '","staffStatus":"8時〜","staffComment":"","staffid":"","timeStmp":1439046045000}]';
        List<StaffScheduleCtrl.StaffSchedule> saveTimeMessage2 = StaffScheduleCtrl.saveTimeMessage(st,'テスト勤怠');
        StaffScheduleCtrl.getExitAllUser(userId,'user','02','',system.today().format(),system.today().format());
    }
    static testMethod void Case8(){
        List<User> userLst = new List<User>();
        userLst.add(TestCommon.CreateUser());
        userLst.add(TestCommon.CreateUser());
        userLst.add(TestCommon.CreateUser());
        insert userLst;
        createDocument1();
        StaffGanttCtrl ctrl = new StaffGanttCtrl();
        ctrl.init();
        System.assertEquals(ctrl.isManager, false);
        System.assertEquals(ctrl.isAssign, false);
        System.assertEquals(ctrl.mainProjectId, null);
        Map<String,object> reqMap = new Map<String,object>();
        // プロジェックト作成する
        reqMap.put('name','プロジェックト００１');
        reqMap.put('managerName',userLst[0].id);
        reqMap.put('pub',false);
        // startDt endDt pub pDesc managerName users
        StaffGanttCtrl.taskFunction('CREATEPROJECT',JSON.serialize(reqMap));
        // プロジェックト作成する
        reqMap.put('name','プロジェックト００2');
        reqMap.put('managerName',userLst[1].id);
        reqMap.put('pub',true);
        StaffGanttCtrl.taskFunction('CREATEPROJECT',JSON.serialize(reqMap));
        List<ProjectMain__c> pms = [select id from ProjectMain__c];
        System.assertEquals(pms.isEmpty(), false);
        // 担当者とマネージャー取得する
        List<Object> res = StaffGanttCtrl.taskFunction('GETMANAGER',JSON.serialize(pms[0].id));
        // プロジェックト取得する
        res = StaffGanttCtrl.taskFunction('GETPROJECT',JSON.serialize(new Map<String,String>{'id' => pms[0].id}));
        // 担当者のプロジェックトリスト
        System.runAs(userLst[0]) {
            res = StaffGanttCtrl.taskFunction('GETPJBYUSER', JSON.serialize(new Map<String, String>{'finishMode'=> 'false'}));
        }
        // タスク→プロジェックト明細作成
        List<Event> events = createEvents(5);
        List<String> evets = new List<String>();
        for (Event evt : events) {
            evets.add(evt.id);
        }
        reqMap = new Map<String,Object>{'projectid' => pms[0].id,'selType' => 1,
                                        'tasks' => evets};
        Test.startTest();
        res = StaffGanttCtrl.taskFunction('TASKTOPROJECT',JSON.serialize(reqMap));
        // タスク→プロジェックト明細作成
        List<Task> Tasks = createTasks(5);
        List<String> taskLst = new List<String>();
        for (Event evt : events) {
            taskLst.add(evt.id);
        }
        reqMap = new Map<String,Object>{'projectid' => pms[0].id,'selType' => 2,
                                        'tasks' => taskLst};
        res = StaffGanttCtrl.taskFunction('TASKTOPROJECT',JSON.serialize(reqMap));
        // 検索側タスク取得する
        reqMap = new Map<String,Object>{'start' => System.today().format(),'type' => StaffTaskHelp.EVENT_TYPE_EVENT,
                                        'userid' => events[0].ownerid,'end' => System.today().format(),'taskname' => 'テスト'};
        //,'contactid' => evets
        res = StaffGanttCtrl.taskFunction('GETTASK',JSON.serialize(reqMap));
        // プロジェクト明細取得
        reqMap = new Map<String,Object>{'projectid' => pms[0].id,'startDt' => System.today().format(),'endDt' => System.today().format()};
        res = StaffGanttCtrl.taskFunction('READ',JSON.serialize(reqMap));
        // プロジェックト明細作成
        reqMap = new Map<String,Object>{'projectid' => pms[0].id,'dataid' => null};
        res = StaffGanttCtrl.taskFunction('DTCREATE',JSON.serialize(reqMap));
        List<ProjectDetail__c> ps = [select id from ProjectDetail__c where ProjectMain__c = :pms[0].id order by orderId__c];
        reqMap = new Map<String,Object>{'projectid' => pms[0].id,'dataid' => ps[0].id};
        res = StaffGanttCtrl.taskFunction('DTCREATE',JSON.serialize(reqMap));
        // プロジェクト明細更新する
        reqMap = new Map<String,Object>{'parentDataId' => ps[1].id,'dataid' => ps[0].id,'StartDt' => System.now().getTime(),
                                            'EndDt' => System.now().getTime(),'Summary' => false,'Expanded' => true};
        res = StaffGanttCtrl.taskFunction('DTUPDATE',JSON.serialize(reqMap));
        reqMap = new Map<String,Object>{'dataid' => ps[0].id,'StartDt' => system.now().addDays(-15).gettime()
                                        ,'EndDt' => System.now().getTime(),'Summary' => true,'Expanded' => true};
        
        Test.StopTest();
    }
    static testMethod void Case9(){
        createDocument1();
        ShopInformation__c tempShop = TestCommon.createShopInfo();
        User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        loginUser.ShopCode__c = tempShop.shopcode__c;
        update loginUser;
        
        TestCommon.createWorkTimeDefine(tempShop.shopcode__c);
        TestCommon.createLead();
        System.runAs(loginUser) {
            List<Event> newEvents = createEvents(10);
            createStaffScedule(loginUser.id);
            // -------------------
            Date begDt = system.today();
            Date endDt = begDt.addDays(20);
            Map<String,Object> reqMap = new Map<String,Object>{'begDate' => begDt.format(),'endDate' => endDt.format(),'userLst'=>new List<String>{loginUser.id},'isUserFlg' => false};

            StaffTaskCtrl.getTasks(JSON.serialize(reqMap));
            reqMap = new Map<String,Object>{'Subject' => 'taskABC','id' => newEvents[0].id,'isUserFlg' => false};
            StaffTaskCtrl.updateEvent(JSON.serialize(reqMap));
            reqMap = new Map<String,Object>{'taskid' => newEvents[0].id};
            StaffTaskCtrl.removeTasks(JSON.serialize(reqMap));
            Room__c room = TestCommon.createRooms();
            TestCommon.createBadRoom(room.id,begDt);
            String summaryXml = '{\"summaryKeyValMap\":{\"null\":[\"泊素(2〜3人)\",\"日帰(3人以上)\",\"婚礼\"]},\"conditionVal\":[\"泊素(2〜3人)\",\"日帰(3人以上)\",\"婚礼\"],\"conditionKey\":[\"id\",\"id\",\"id\"]}';
            StaffTaskCtrl.summaryTitleInfoByXml('', begDt.format(), endDt.format() ,summaryXml);
            StaffTaskCtrl.refreshTimeMessage(begDt.format(), endDt.format(),loginUser.id);
            User u = TestCommon.CreateUser();
            insert u ;
            String taskStr = '{"rowId":"'+ u.id + '","name":" 5322222222 ","style":"background:red","groupBeginLabel":"2018/06/01","beginLabel":"18:00","groupEndLabel":"2018/06/02","endLabel":"06:00","weekTotal":127,"weekOpts":"Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday","repeatDateBeg":"2018/06/01","repeatDateEnd":"2018/06/30","isUserFlg":true,"userId":"' + u.id + '"}';
            StaffTaskCtrl.updateEvent(taskStr);
            List<event> events = [select id from event where RecurrenceActivityId != null];
            if (!events.isEmpty()) {
                Event event = events[0];
                reqMap = new Map<String,Object>{'taskid' => event.id,'delSameFlag' => true};
                StaffTaskCtrl.removeTasks(JSON.serialize(reqMap));
            }
        }
    }
    
    static testMethod void Case10() {
        List<User> userLst = new List<User>();
        userLst.add(TestCommon.CreateUser());
        userLst.add(TestCommon.CreateUser());
        userLst.add(TestCommon.CreateUser());
        insert userLst;
        Map<String,Object> reqMap = new Map<String,Object>();
        reqMap.put('name','プロジェックト００2_new');
        reqMap.put('managerName',userLst[1].id);
        reqMap.put('pub',true);
        StaffGanttCtrl.taskFunction('CREATEPROJECT',JSON.serialize(reqMap));
        
        List<ProjectMain__c> pms = [select id from ProjectMain__c];
        List<Object> res;
        reqMap = new Map<String,Object>{'projectid' => pms[0].id,'dataid' => null};
        res = StaffGanttCtrl.taskFunction('DTCREATE',JSON.serialize(reqMap));
        List<ProjectDetail__c> ps = [select id from ProjectDetail__c where ProjectMain__c = :pms[0].id order by orderId__c];
        if (!ps.isEmpty()) {
            ps[0].title__c = '12333';
            update ps[0];
            //Test.isRunningTest()
        }
        Test.startTest();
        res = StaffGanttCtrl.taskFunction('getProjectHistory', JSON.serialize(new List<String>{ps[0].id}));
        Test.StopTest();
    }
    static testMethod void Case11() {
        List<User> userLst = new List<User>();
        userLst.add(TestCommon.CreateUser());
        userLst.add(TestCommon.CreateUser());
        userLst.add(TestCommon.CreateUser());
        insert userLst;
        Map<String,Object> reqMap = new Map<String,Object>();
        reqMap.put('name','プロジェックト００2_new');
        reqMap.put('managerName',userLst[1].id);
        reqMap.put('pub',true);
        StaffGanttCtrl.taskFunction('CREATEPROJECT',JSON.serialize(reqMap));
        
        List<ProjectMain__c> pms = [select id from ProjectMain__c];
        List<Object> res;
        reqMap = new Map<String,Object>{'projectid' => pms[0].id,'dataid' => null};
        res = StaffGanttCtrl.taskFunction('DTCREATE',JSON.serialize(reqMap));
        res = StaffGanttCtrl.taskFunction('DTCREATE',JSON.serialize(reqMap));
        res = StaffGanttCtrl.taskFunction('DTCREATE',JSON.serialize(reqMap));
        List<ProjectDetail__c> ps = [select id from ProjectDetail__c where ProjectMain__c = :pms[0].id order by orderId__c];
        
        Map<String,Object> updated = new Map<String,Object>();
        for(Integer i = 0; i < ps.size(); i++) {
            updated.put(ps[i].id, new Map<String,Object>{'dataid' => ps[i].id,'StartDt' => System.now().getTime(),
                    'EndDt' => System.now().getTime(),'Summary' => false,'Expanded' => true});
        }
        
        for(Integer i = 0; i < 10; i++) {
            updated.put(String.valueOf(i) + '_new', new Map<String,Object>{'dataid' => String.valueOf(i) + '_new', 'StartDt' => System.now().getTime(),
                    'EndDt' => System.now().getTime(),'Summary' => false,'Expanded' => true});
        }
        
        updated.put('projectId', new Map<String, Object>{'dataid'=>pms[0].id});
        
        Test.startTest();
        res = StaffGanttCtrl.taskFunction('DTUPDATE_ALL', JSON.serialize(updated));
        Test.StopTest();
        
    }
    static testMethod void Case12(){
        integer eventNums = 5;
        TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
        List<Room__c> createRooms = TestCommon.createRooms(eventNums, typeOfRoom.Id);
        List<Event> newEvents = new List<Event>();
        for (Integer i= 0; i < eventNums; i++) {
            newEvents.add(new Event(
                OwnerId = UserInfo.getUserId(),
                Subject = 'テスト' + CommUtils.getRandom(6),
                StartDateTime = system.now(),
                EndDateTime = system.now().addDays(2),
                RoomRef__c = createRooms[i].id
            ));
        }
        try{
            insert newEvents;
        } catch (exception e) {
            List<Lead__c> leads = [select id from Lead__c ];
            System.assertEquals(leads.size(), 0);
        }
        try{
            newEvents[0].EndDateTime = system.now().addDays(1);
            insert newEvents;
        } catch (exception e) {
            List<Lead__c> leads = [select id from Lead__c ];
            System.assertEquals(leads.size(), 0);
        }
        newEvents = new List<Event>();
        for (Integer i= 0; i < eventNums; i++) {
            newEvents.add(new Event(
                OwnerId = UserInfo.getUserId(),
                Subject = 'テスト' + CommUtils.getRandom(6),
                DurationInMinutes = 60,
                ActivityDateTime = System.now(),
                ActivityDate = Date.today(),
                RoomRef__c = createRooms[i].id,
                WhoId = TestCommon.createContact().id
            ));
        }
        insert newEvents;
    }
    /*
    static testMethod void Case5() {
        User u = TestCommon.CreateUser();
        createStaffScedule(u.id);
        createTimeManagements(20);
        Test.startTest();
        StaffScheduleCtrl.RefreshResult result = StaffScheduleCtrl.refreshTimeMessage('2015/08/04','2015/08/24',u.id);
        Test.stopTest();
    }*/
    static testMethod void Case13() {
        Event evt = new Event();
        evt.ActivityDate = system.today();
        evt.subject = '件名';
        evt.IsAllDayEvent = true;
        insert evt;
        evt.CustomEventFlag__c = true;
        update evt;
        Lead__c lead = TestCommon.createLead();
        lead.EventFlg__c = true;
        update lead;
        lead.EntryTime__c = system.today().addDays(1);
        lead.Departure__c = system.today().addDays(2);
        update lead;
        evt.ProjectFlag__c = true;
        ProjectMain__c main = new ProjectMain__c();
        insert main;
        ProjectDetail__c pj = new ProjectDetail__c(TaskId__c = evt.id,ProjectMain__c = main.id,Comment__c='123');
        insert pj;
        update evt;
        List<Lead__c> leads = [select id,eventId__c from lead__c where EventFlg__c = true];
        String eventId = leads[0].eventId__c;
        delete new Event(id = eventId);
    }
    static testMethod void Case14(){
        Event evt1 = new Event();
        evt1.ActivityDatetime = system.now();
        evt1.DurationInMinutes = 20;
        evt1.subject = '件名';
        evt1.RoomRef__c = TestCommon.createRooms().id;
        evt1.WhoId = TestCommon.createContact().id;
        insert evt1;
        List<User> userLst = new List<User>();
        userLst.add(TestCommon.CreateUser());
        insert userLst;
        Map<String,object> reqMap = new Map<String,object>();
        // プロジェックト作成する
        reqMap.put('name','プロジェックト００１');
        reqMap.put('managerName',userLst[0].id);
        reqMap.put('pub',false);
        // startDt endDt pub pDesc managerName users
        StaffGanttCtrl.taskFunction('CREATEPROJECT',JSON.serialize(reqMap));
        List<ProjectMain__c> pms = [select id from ProjectMain__c];
        // タスク→プロジェックト明細作成
        List<Event> events = createEvents(5);
        List<String> evets = new List<String>();
        for (Event evt : events) {
            evets.add(evt.id);
        }
        reqMap = new Map<String,Object>{'projectid' => pms[0].id,'selType' => 1,
                                        'tasks' => evets};
        List<Object> res = StaffGanttCtrl.taskFunction('TASKTOPROJECT',JSON.serialize(reqMap));
        List<ProjectDetail__c> ps = [select id from ProjectDetail__c where ProjectMain__c = :pms[0].id order by orderId__c];
        reqMap = new Map<String,Object>{'dataid' => ps[0].id,'PercentComplete' => 0.5,'StartDt' => System.now().getTime(),
                                            'EndDt' => System.now().getTime(),'Summary' => false,'Expanded' => true};
        res = StaffGanttCtrl.taskFunction('DTUPDATE',JSON.serialize(reqMap));
        // プロジェックト明細関連関係作成
        reqMap = new Map<String,Object>{'projectid' => pms[0].id};
        res = StaffGanttCtrl.taskFunction('DEPCREATE',JSON.serialize(reqMap));
        // プロジェックト明細関連関係取得
        reqMap = new Map<String,Object>{'projectid' => pms[0].id};
        res = StaffGanttCtrl.taskFunction('DEPREAD',JSON.serialize(reqMap));
        // プロジェックト明細移動対応
        reqMap = new Map<String,Object>{'dataid' => ps[1].id};
        res = StaffGanttCtrl.taskFunction('DOWN',JSON.serialize(reqMap));
        reqMap = new Map<String,Object>{'dataid' => ps[1].id,'projectid' => pms[0].id};
        res = StaffGanttCtrl.taskFunction('RIGHT',JSON.serialize(reqMap));
        //[select id,ParentProject__c from ProjectDetail where id = :ps[1].id];
        reqMap = new Map<String,Object>{'dataid' => ps[1].id};
        res = StaffGanttCtrl.taskFunction('LEFT',JSON.serialize(reqMap));
        reqMap = new Map<String,Object>{'dataid' => ps[ps.size()-1].id};
        res = StaffGanttCtrl.taskFunction('UP',JSON.serialize(reqMap));
        // プロジェックト担当者
        res = StaffGanttCtrl.taskFunction('GETPJASSIGN',JSON.serialize( pms[0].id));
        // COOKIE 該当プロジェックト保存
        res = StaffGanttCtrl.taskFunction('SAVECOOKIEPJ',JSON.serialize( pms[0].id));

        
        // プロジェクト明細削除
        reqMap = new Map<String,Object>{'projectid' => pms[0].id,'tasks' => new List<String>{ps[2].id}};
        res = StaffGanttCtrl.taskFunction('DTDESTORY',JSON.serialize(reqMap));
    }
    static testMethod void Case15(){
        createDocument1();
        ShopInformation__c tempShop = TestCommon.createShopInfo();
        User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        loginUser.ShopCode__c = tempShop.shopcode__c;
        update loginUser;
        
        List<Event> newEvents = createEvents(10);
        Test.startTest();
        StaffTaskCtrl ssc = new StaffTaskCtrl();

        ssc.init();
        ssc.changeInitProect();
        String val = ssc.otherValue;
        val = ssc.projectId;
        Map<String,Object> objMap = new Map<String,Object>{'begDate' => system.today(),
                                'endDate' => system.today(),'userLst' => new List<String>{UserUtil.CurrentUser.id},'spcd' =>'02'};
        StaffTaskCtrl.getProjectOpts(JSON.serialize(objMap));
        ssc.toPrev();
        ssc.toToday();
        //ssc.toNext();
        StaffTaskCtrl.remoteCenter('lockEvent',JSON.serialize(new map<String,Object>{'eventIds' => new List<String>{newEvents[0].id}}));
        StaffTaskCtrl.remoteCenter('unLockEvent',JSON.serialize(new map<String,Object>{'eventIds' => new List<String>{newEvents[0].id}}));
        StaffTaskCtrl.remoteCenter('saveSettingInfo',JSON.serialize(new Map<String,Object>{'viewMode' => 'ONEDAY-30', 'orFlg' => false,'userGroupId' => ''}));
        StaffTaskCtrl.remoteCenter('saveUserGroup',JSON.serialize(new map<String,Object>{'userLst' => new List<String>{UserUtil.CurrentUser.id},'label' => '123','spcd' =>'02'}));
        StaffTaskCtrl.remoteCenter('getUserLst',JSON.serialize(new map<String,Object>{'spcd' =>'02'}));
        List<UserConfig__c> configs = [select id from UserConfig__c limit 1];
        StaffTaskCtrl.remoteCenter('deleteUserGroup',JSON.serialize(new map<String,Object>{'taskid' => configs[0].id}));
        Test.stopTest();
        StaffTaskHelp.getTasks(new List<id>{loginUser.id},null,null);
        StaffTaskHelp.getFieldValidationMessage('FIELD_INTEGRITY_EXCEPTION123');
        Map<String,object> reqMap = new Map<String,object>();
        // プロジェックト作成する
        reqMap.put('name','プロジェックト００１');
        reqMap.put('managerName',loginUser.id);
        reqMap.put('pub',false);
        // startDt endDt pub pDesc managerName users
        StaffGanttCtrl.taskFunction('CREATEPROJECT',JSON.serialize(reqMap));
        List<ProjectMain__c> pms = [select id from ProjectMain__c];
        StaffTaskHelp.getOrderDetailsForParents(pms[0].id,null);
        StaffTaskHelp.getTasks(new List<Id>{loginUser.id},null,null,'123,222');
        StaffTaskHelp.refreshParentNode(new ProjectDetail__c(),null);
        StaffTaskHelp.getEvents(loginUser.id,null,null,null,null);
        StaffTaskHelp.deleteDependencie(null);
        StaffTaskHelp.updateProjectMain(pms[0]);
        StaffTaskHelp.afterChangeOrder(new ProjectDetail__c());
        StaffTaskHelp.updDueDatetime(null);
        StaffTaskHelp.removeAttachment(null);
        ssc.init();
    }
    static testMethod void Case16(){
        Contact cont = testcommon.createContact();
        StaffTaskHelp.getHistory('contact',new Set<Id>{cont.id});
        createDocument2();
        StaffTaskCtrl ssc = new StaffTaskCtrl();
        ssc.init();
        ssc.toNext();
        String createStr = '{"rowId":"接客 賑い亭","userId":"' + UserUtil.CurrentUser.id + '","groupEndLabel":"2019/12/06","endLabel":"01:00","calFlg":false,"groupBeginLabel":"2019/12/06","beginLabel":"00:00","name":"接客 賑い亭","style":"background:#bc7aff","groupName":"0001","rowfield":"CreateType__c","spcd":"02","isUserFlg":true}';
        StaffTaskCtrl.updateEvent(createStr);
        List<ProjectDetail__c> pds = [select id from ProjectDetail__c];

        if (!pds.isEmpty()) {
            String pdId = pds[0].id;
            String editStr = '{"beginLabel":"00:00","endLabel":"18:00","groupBeginLabel":"2019/12/06","groupEndLabel":"2019/12/06","groupName":"0001","id":"' + pdId + '","isLockFlg":false,"rowId":"接客 賑い亭","style":"background:#bc7aff","userId":"' + UserUtil.CurrentUser.id + '","rowfield":"CreateType__c","spcd":"02","isUserFlg":true}';
            StaffTaskCtrl.updateEvent(editStr);
        }
        Map<String,object> reqMap = new Map<String,object>();
        // プロジェックト作成する
        reqMap.put('name','プロジェックト００１');
        reqMap.put('managerName',UserUtil.CurrentUser.id);
        reqMap.put('pub',false);
        StaffGanttCtrl.taskFunction('CREATEPROJECT',JSON.serialize(reqMap));
        List<ProjectMain__c> pms = [select id from ProjectMain__c];
        // プロジェックト明細関連関係作成
        reqMap = new Map<String,Object>{'projectid' => pms[0].id,'dataid' => null};
        List<Object> res = StaffGanttCtrl.taskFunction('DTCREATE',JSON.serialize(reqMap));
        List<projectDetail__c> details = [select id,calendarFlg__c from projectDetail__c];
        details[0].calendarFlg__c = false;
        update details[0];
        details[0].calendarFlg__c = true;
        update details[0];
        StaffGanttCtrl gantt = new StaffGanttCtrl();
        String jsonStr = gantt.calendarJson;
        reqMap.put('id',details[0].id);
        try{
            res = StaffGanttCtrl.taskFunction('chatterPostItem', JSON.serialize(reqMap));
        } catch(Exception e){}
        res = StaffGanttCtrl.taskFunction('getProjectUsers', JSON.serialize(reqMap));
        res = StaffGanttCtrl.taskFunction('preCheckChatter', JSON.serialize(reqMap));
        StaffTaskHelp.getProjectMainDetails(null);
        StafftaskHelp.getDeleteFlag();
        Event evt = new Event(StartDateTime = system.now(),EndDateTime = system.now().addDays(1),subject='test');
        insert evt;
        evt.EndDateTime__c = system.now().addDays(15);
        evt.CustomEventFlag__c = !evt.CustomEventFlag__c;
        update evt;
        evt.subject = 'test002';
        evt.CustomEventFlag__c = !evt.CustomEventFlag__c;
        update evt;
        evt.EndDateTime__c = system.now().addDays(24);
        evt.CustomEventFlag__c = !evt.CustomEventFlag__c;
        evt.whoid = null;
        evt.subject = 'test002';
        update evt;
        delete evt;
    }
    private static void createStaffScedule(String uid){
        Date startDt = CommUtils.stringToDate('2015/08/04');
        Date endDt = CommUtils.stringToDate('2015/08/24');
        List<StaffSchedule__c> staffs = new List<StaffSchedule__c>();
        for(integer i = 0 ; i < startDt.daysBetween(endDt) ; i++){
            Date configDate = startDt.addDays(i);
            staffs.add(new StaffSchedule__c(
                            StatusLst__c = '8時〜',
                            WorkDay__c = configDate,
                            StaffUserRef__c = uid,
                            CommentLst__c = '電車遅延による遅刻',
                            SearchKey__c = (uid + '_' + configDate.format())
                        ));
        }
        insert staffs;
    }

    public static List<Task> createTasks(Integer taskNums) {
        List<Task> newTasks = new List<Task>();
        for (Integer i= 0; i<taskNums; i++) {
            newTasks.add(new Task(
                Subject = 'テスト' + CommUtils.getRandom(6)
                ));
        }
        // 2015/12/01 Assert BEGIN
        System.assertEquals(newTasks.size(), taskNums);
        // 2015/12/01 Assert END
        insert newTasks;
        return newTasks;
    }
    public static List<Event> createEvents(Integer eventNums) {
        List<Event> newEvents = new List<Event>();
        for (Integer i= 0; i<eventNums; i++) {
            newEvents.add(new Event(
                OwnerId = UserInfo.getUserId(),
                Subject = 'テスト' + CommUtils.getRandom(6),
                DurationInMinutes = 60,
                ActivityDateTime = System.now(),
                ActivityDate = Date.today()
                ));
        }
        insert newEvents;
        return newEvents;
    }
    public static List<TimeManagement__c> createTimeManagements(Integer tmNums,String userId) {
        Date processDay = Date.today();
        Integer thisYear = processDay.year();
        Integer thisMonth = processDay.month();
        Date startDate = Date.newinstance(thisYear, thisMonth, 1);
        Integer daysInMonth = Date.daysInMonth(thisYear, thisMonth);
        Date conStartDate = startDate;
        Date conEndDate = startDate.addDays(daysInMonth-1);

        List<TimeManagement__c> newTimeManagements = new List<TimeManagement__c>();
        Date currentDt = Date.today();
        for (Integer i= 0; i<tmNums; i++) {
            newTimeManagements.add(
                    new TimeManagement__c(
                        WorkDay__c = currentDt.addDays(-(i + 1)),
                        WorkerRef__c = userId,
                        WorkBeginTime__c = System.now().addDays(-(i + 1)),
                        OutingTime__c = System.now().addDays(-(i + 1)),
                        OutingTime2__c = System.now().addDays(-(i + 1)), 
                        OutingTime3__c = System.now().addDays(-(i + 1)) 
            /*
            new TimeManagement__c(
                WorkDay__c = currentDt.addDays(-(i + 1)),
                WorkerRef__c = UserInfo.getUserId(),
                WorkBeginTime__c = System.now().addDays(-(i + 1)),
                WorkEndTime__c =  System.now().addDays(-(i + 1))
            */
                        ));
        }
        // 2015/12/01 Assert BEGIN
        System.assertEquals(newTimeManagements.size(), tmNums);
        // 2015/12/01 Assert END
        insert newTimeManagements;
        return newTimeManagements;
    }
    // 2016/07/22  ゆもとや様より改善要望(シフト表示開始日の変更)  wgch       BEGIN
    private static void createDocument(){
        String csv = '<?xml version="1.0" encoding="utf-8"?><root>    <SHOP>        <SHOPCODE></SHOPCODE>        <SUMMARY TITLE="泊素(2〜3人)">          <LOGIC>({0} OR {1}) AND {2}</LOGIC>          <COONDITION>              StayPersons__c  <10           </COONDITION>           <COONDITION>             StayPersons__c  >3          </COONDITION>          <COONDITION>             Departure__c >= 2013-11-01T00:00:00Z          </COONDITION>        </SUMMARY>        <SUMMARY TITLE="日帰(3人以上)">        <LOGIC> {0}</LOGIC>          <COONDITION>                 (StayPersons__c  <10 or  StayPersons__c  >3)  and Departure__c = 2015-09-15T00:00:00Z          </COONDITION>        </SUMMARY>        <SUMMARY TITLE="婚礼">          <LOGIC>{0} and {1}</LOGIC>          <COONDITION>                StayPersons__c >= 2          </COONDITION>          <COONDITION>                StayPersons__c < 10          </COONDITION>                  </SUMMARY>        <WORKTIME>            <WORK_START>                <BACKCOLOR>#afeeee</BACKCOLOR>              <FONTCOLOR>black</FONTCOLOR>            </WORK_START>           <WORK_REST_START>               <BACKCOLOR>#ffa500</BACKCOLOR>              <FONTCOLOR>black</FONTCOLOR>            </WORK_REST_START>          <WORK_REST_END>             <BACKCOLOR>#f5deb3</BACKCOLOR>              <FONTCOLOR>black</FONTCOLOR>            </WORK_REST_END>            <WORK_END>              <BACKCOLOR>#dcdcdc</BACKCOLOR>              <FONTCOLOR>black</FONTCOLOR>            </WORK_END>         <WORK_COMMENT>              <BACKCOLOR>#f5deb3</BACKCOLOR>              <FONTCOLOR>black</FONTCOLOR>            </WORK_COMMENT>        </WORKTIME><APPCONFIG><USER_PLUSINF></USER_PLUSINF><BUSS_STATUS_CLOSE>休館</BUSS_STATUS_CLOSE><SUMMARY_SHOP></SUMMARY_SHOP><BUSS_END_DAY>20</BUSS_END_DAY></APPCONFIG>    </SHOP></root>';

        Document StaffScheduleConfigXml = new Document();
        StaffScheduleConfigXml.Name = 'StaffScheduleConfigXml';
        StaffScheduleConfigXml.DeveloperName = StaffScheduleConfigXml.Name;
        StaffScheduleConfigXml.FolderId = UserInfo.getUserId();
        StaffScheduleConfigXml.Body = Blob.valueOf(csv);
        insert StaffScheduleConfigXml;
    }
    private static void createDocument1(){
        String csv =   ' <?xml version="1.0" encoding="utf-8"?><root><SHOP>'+
                       ' <SHOPCODE></SHOPCODE><SUMMARY TITLE="宿泊"><LOGIC>{0}</LOGIC><COONDITION>ReservedType__c in (\'泊 ２食\',\'泊 朝半\',\'泊 夕半\',\'泊 素\',\'宿泊\')</COONDITION></SUMMARY>'+
                       ' <SUMMARY TITLE="団体"><LOGIC>{0}</LOGIC><COONDITION>StayPersons__c >= 10</COONDITION></SUMMARY>'+
                       ' <SUMMARY TITLE="婚礼"><LOGIC> {0}</LOGIC><COONDITION>Segment__c in (\'婚礼\',\'フォトプラン\',\'二次会\',\'通常料金\')</COONDITION></SUMMARY>'+
                       ' <WORKTIME><WORK_START><BACKCOLOR>#afeeee</BACKCOLOR></WORK_START><WORK_REST_START><BACKCOLOR>#ffa500</BACKCOLOR></WORK_REST_START><WORK_REST_END><BACKCOLOR>#f5deb3</BACKCOLOR></WORK_REST_END><WORK_END><BACKCOLOR>#dcdcdc</BACKCOLOR></WORK_END><WORK_TIME_EDIT><BACKCOLOR>#90EE90</BACKCOLOR></WORK_TIME_EDIT></WORKTIME>'+
                       '<ROLECONFIG><EDITABLE_ROLE>開発部</EDITABLE_ROLE><VIEW_ROLE> <MEMBER_ROLE MANGER="開発部">開発一部,開発二部</MEMBER_ROLE> <MEMBER_ROLE MANGER="開発部,人事部">開発一部</MEMBER_ROLE> </VIEW_ROLE></ROLECONFIG>'+
                       '<TASKCONFIG><TASK ROW="60" COLOR="pink">打ち合わせ(1h)</TASK><TASK ROW="30" COLOR="orange">問い合わせ(30min)</TASK></TASKCONFIG>'+
                       ' <APPCONFIG><USER_PLUSINF></USER_PLUSINF><BUSS_STATUS_CLOSE>休館</BUSS_STATUS_CLOSE><SUMMARY_SHOP></SUMMARY_SHOP><EVENT_TITLE>作業</EVENT_TITLE><BUSS_END_DAY>20</BUSS_END_DAY></APPCONFIG></SHOP></root>';
        Document StaffScheduleConfigXml = new Document();
        StaffScheduleConfigXml.Name = 'StaffScheduleConfigXml';
        StaffScheduleConfigXml.DeveloperName = StaffScheduleConfigXml.Name;
        StaffScheduleConfigXml.FolderId = UserInfo.getUserId();
        StaffScheduleConfigXml.Body = Blob.valueOf(csv);
        insert StaffScheduleConfigXml;
    }
    // 2016/07/22  ゆもとや様より改善要望(シフト表示開始日の変更)  wgch       END
    private static void createDocument2(){
        String csv =   ' <?xml version="1.0" encoding="utf-8"?><root><SHOP>'+
                       ' <SHOPCODE></SHOPCODE><SUMMARY TITLE="宿泊"><LOGIC>{0}</LOGIC><COONDITION>ReservedType__c in (\'泊 ２食\',\'泊 朝半\',\'泊 夕半\',\'泊 素\',\'宿泊\')</COONDITION></SUMMARY>'+
                       ' <SUMMARY TITLE="団体"><LOGIC>{0}</LOGIC><COONDITION>StayPersons__c >= 10</COONDITION></SUMMARY>'+
                       ' <SUMMARY TITLE="婚礼"><LOGIC> {0}</LOGIC><COONDITION>Segment__c in (\'婚礼\',\'フォトプラン\',\'二次会\',\'通常料金\')</COONDITION></SUMMARY>'+
                       ' <WORKTIME><WORK_START><BACKCOLOR>#afeeee</BACKCOLOR></WORK_START><WORK_REST_START><BACKCOLOR>#ffa500</BACKCOLOR></WORK_REST_START><WORK_REST_END><BACKCOLOR>#f5deb3</BACKCOLOR></WORK_REST_END><WORK_END><BACKCOLOR>#dcdcdc</BACKCOLOR></WORK_END><WORK_TIME_EDIT><BACKCOLOR>#90EE90</BACKCOLOR></WORK_TIME_EDIT></WORKTIME>'+
                       '<ROLECONFIG><EDITABLE_ROLE>開発部</EDITABLE_ROLE><VIEW_ROLE> <MEMBER_ROLE MANGER="開発部">開発一部,開発二部</MEMBER_ROLE> <MEMBER_ROLE MANGER="開発部,人事部">開発一部</MEMBER_ROLE> </VIEW_ROLE></ROLECONFIG>'+
                       '<TASKCONFIG QUCIKEDIT="BOTH" HORIZONTAL="true"><TASK ROW="60" COLOR="pink">打ち合わせ(1h)</TASK><TASK ROW="30" COLOR="orange">問い合わせ(30min)</TASK></TASKCONFIG>'+
                       ' <APPCONFIG><USER_PLUSINF></USER_PLUSINF><BUSS_STATUS_CLOSE>休館</BUSS_STATUS_CLOSE><SUMMARY_SHOP></SUMMARY_SHOP><EVENT_TITLE>作業</EVENT_TITLE><BUSS_END_DAY>20</BUSS_END_DAY></APPCONFIG><GANTTCONFIG><EVENT_REMOVE>true</EVENT_REMOVE></GANTTCONFIG></SHOP></root>';
        Document StaffScheduleConfigXml = new Document();
        StaffScheduleConfigXml.Name = 'StaffScheduleConfigXml';
        StaffScheduleConfigXml.DeveloperName = StaffScheduleConfigXml.Name;
        StaffScheduleConfigXml.FolderId = UserInfo.getUserId();
        StaffScheduleConfigXml.Body = Blob.valueOf(csv);
        insert StaffScheduleConfigXml;
    }
}