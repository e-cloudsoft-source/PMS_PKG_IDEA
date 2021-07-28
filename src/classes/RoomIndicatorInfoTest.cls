/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class RoomIndicatorInfoTest {

    static testMethod void myUnitTest() {
    	getCsvSetupConfig();
    	createDocument1();
		Lead__c lead1 = TestCommon.createLead();
    	//Lead__c lead2 = TestCommon.createLead();
    	//Lead__c lead3 = TestCommon.createLead();
    	//Lead__c lead4 = TestCommon.createLead();
    	//Lead__c lead5 = TestCommon.createLead();
        Room__c newRoom = TestCommon.createRooms(lead1.refTypeOfRooms__c);
        Test.startTest();
    	String leadId = lead1.Id;
    	String roomId = lead1.Rroom__c;
     	String indexRefId = lead1.LeadIndexRef__c;
     	String entryTime = lead1.EntryTime__c.format('yyyy/MM/dd');

    	// 予約データを作成する　
    	RoomIndicatorInfo indicator = new RoomIndicatorInfo();
    	indicator.toToday();
    	// 2020/02/29 BY zyz BEGIN
    	// List<RoomIndicatorInfo.AreaRoomInfo> areaInfLst = indicator.areaInfLst;
    	indicator.strLeadId = leadId;
    	// indicator.checkInByRoom();
    	Test.stopTest();
    	
    	// indicator.checkOutByRoom();
    	// indicator.gotoDate();
    	// 2020/02/29 BY zyz END
    	indicator.toNext();
    	indicator.toPrev();
    	// 予約データを作成する
        String jsonField = 'ReservationDate__c,SearchDate__c';
        String contactFields = 'Phone,email';
        RoomIndicatorInfo.PopupWinInfo popupInfo = RoomIndicatorInfo.getRoomInfoExt(roomId,leadId,jsonField,contactFields);
    	System.assertNotEquals(popupInfo.leadId, null);

    	SObject[] sLst = RoomIndicatorInfo.getChangeRoom(leadId, '');
        indicator.strNewRoomId = newRoom.Id;
        //indicator.changeRoom();
        String queryDt = DateTime.now().format('yyyy/MM/dd');
        //RoomIndicatorInfo.cleanRoomAction(new List<Id>{roomId}, queryDt, leadId);
        RoomIndicatorInfo.cleanRoomAction(new List<Id>{roomId}, queryDt);
        // 部屋の予約データはチェックアウトする場合
        
    }
    static testMethod void remoteActionTest(){
    	//indicator.changeRoom();
    	Lead__c lead1 = TestCommon.createLead();
        Room__c newRoom = TestCommon.createRooms(lead1.refTypeOfRooms__c);
    	String leadId = lead1.Id;
    	String roomId = lead1.Rroom__c;
    	String queryDt = DateTime.now().format('yyyy/MM/dd');
    	Test.startTest();
        
        RoomIndicatorInfo.cleanRoomAction(new List<Id>{roomId}, queryDt);
        List<Lead__c> newLst = new List<Lead__c>();
        newLst.add(lead1);
		// 2015/12/01 Assert BEGIN
		System.assertEquals(newLst.size(), 1);
		// 2015/12/01 Assert END
        //RoomIndicatorInfo.cleanRoomAction(new List<Id>{roomId}, queryDt, leadId);
        
        RoomIndicatorInfo.preUpdateMemoryRoomLeadMap(null, leadId, roomId, null, queryDt, newLst, null, false);

        RoomIndicatorInfo.autoCancelAssignRoomToLead(new String[]{leadId}, queryDt, true);
        
        RoomIndicatorInfo.noAssingLeadInfo(queryDt, lead1.refTypeOfRooms__c);
        
        RoomIndicatorInfo.noAssingLeadInfoAll(queryDt, '', true);
        
        Test.stopTest();
        
        
        // indicator.updateMemoryRoomLeadMap();
    }
    static testMethod void remoteActionTest2(){
    	//indicator.changeRoom();
    	Lead__c lead1 = TestCommon.createLead();
        Room__c newRoom = TestCommon.createRooms(lead1.refTypeOfRooms__c);
    	String leadId = lead1.Id;
    	String roomId = lead1.Rroom__c;
    	String queryDt = DateTime.now().format('yyyy/MM/dd');
    	Test.startTest();
        
        RoomIndicatorInfo.cleanRoomAction(new List<Id>{roomId}, queryDt);
        List<Lead__c> newLst = new List<Lead__c>();
        newLst.add(lead1);
		// 2015/12/01 Assert BEGIN
		System.assertEquals(newLst.size(), 1);
		// 2015/12/01 Assert END
        //RoomIndicatorInfo.cleanRoomAction(new List<Id>{roomId}, queryDt, leadId);
        RoomIndicatorInfo.autoCancelAssignRoomToLead(new String[]{leadId}, queryDt, true);
        Test.stopTest();
    }
    static testMethod void remoteActionTest3(){
    	//indicator.changeRoom();
    	Lead__c lead1 = TestCommon.createLead();
        Room__c newRoom = TestCommon.createRooms(lead1.refTypeOfRooms__c);
    	String leadId = lead1.Id;
    	String roomId = lead1.Rroom__c;
    	String queryDt = DateTime.now().format('yyyy/MM/dd');
    	Test.startTest();
        
        RoomIndicatorInfo.cleanRoomAction(new List<Id>{roomId}, queryDt);
        List<Lead__c> newLst = new List<Lead__c>();
        newLst.add(lead1);
		// 2015/12/01 Assert BEGIN
		System.assertEquals(newLst.size(), 1);
		// 2015/12/01 Assert END
        RoomIndicatorInfo.noAssingLeadInfo(queryDt, lead1.refTypeOfRooms__c);
        Test.stopTest();
    }
    static testMethod void remoteActionTest4(){
    	//indicator.changeRoom();
    	Lead__c lead1 = TestCommon.createLead();
        Room__c newRoom = TestCommon.createRooms(lead1.refTypeOfRooms__c);
    	String leadId = lead1.Id;
    	String roomId = lead1.Rroom__c;
    	String queryDt = DateTime.now().format('yyyy/MM/dd');
    	Test.startTest();
        
        RoomIndicatorInfo.cleanRoomAction(new List<Id>{roomId}, queryDt);
        List<Lead__c> newLst = new List<Lead__c>();
        newLst.add(lead1);
		// 2015/12/01 Assert BEGIN
		System.assertEquals(newLst.size(), 1);
		// 2015/12/01 Assert END
        RoomIndicatorInfo.noAssingLeadInfoAll(queryDt, '', true);
        Test.stopTest();
    }
    static testMethod void oterTest(){
    	getCsvSetupConfig();
    	createDocument1();
    	Lead__c lead1 = TestCommon.createLead();
    	// 2015/12/01 Assert BEGIN
		System.assertEquals([select Id from Lead__c].size(), 2);
		// 2015/12/01 Assert END
        Room__c newRoom = TestCommon.createRooms(lead1.refTypeOfRooms__c);
    	String leadId = lead1.Id;
    	String roomId = lead1.Rroom__c;
    	String queryDt = DateTime.now().format('yyyy/MM/dd');
    	
    	Test.startTest();
    	
    	RoomIndicatorInfo indicator = new RoomIndicatorInfo();
		List<RoomIndicatorInfo.AreaRoomInfo> areaInfLst = indicator.areaInfLst;
    	indicator.strLeadId = leadId;
    	       
    	indicator.isShowTodayAction();
    	indicator.refreshBranShop();
    	String dateStr = indicator.strProcessDate;
    	RoomIndicatorInfo.LeadInfo  info = new RoomIndicatorInfo.LeadInfo(lead1);
    	RoomIndicatorInfo.RoomInfo roomInfo = new RoomIndicatorInfo.RoomInfo(newRoom,'222');
    	roomInfo.setLeadInfo(lead1,null );
    	Test.stopTest();
    }
    // グループ単位の部屋アサインテスト
    static testMethod void GroupRoomAssingTest() {
    	// 一括予約で予約データを作成する
		// 予約データの明細情報を変更して、再登録する
    	Test.startTest();
    	getCsvSetupConfig();
    	createDocument1();
    	Contact guest = TestCommon.createContact();
		// 部屋タイプを定義する
		TypeOfRooms__c typeRoom1 = TestCommon.createTypeOfRoom(10);
		TypeOfRooms__c typeRoom2 = TestCommon.createTypeOfRoom(15);
//System.debug(loggingLevel.ERROR, 'typeRoom1::' + [select ActionType__c from TypeOfRooms__c]);	
		// 当日から３日分の故障部屋１件：ステータス「故障」処理結果：NULL　部屋A
		// 当日は１日分の故障部屋１件：　ステータス「故障」処理結果：修理中 部屋A
		// 当日は１日分の故障部屋１件：　ステータス「NULL」処理結果：NULL 部屋C
		// 当日は１日分の故障部屋１件：　ステータス「故障」処理結果：修理中 部屋B
		// 当日は１日分の故障部屋１件：　ステータス「故障」処理結果：修理済 部屋A
		Date startDate = Date.newInstance(2013, 9, 15);
		List<Room__c> updRoomList = new List<Room__c>();
		// 処理結果：当日分の故障部屋数：2件
		Room__c roomA = TestCommon.createRooms(typeRoom1.Id);
		roomA.Seq__c = 1;
		roomA.Floor__c = '1F';
		updRoomList.add(roomA);
		Room__c roomB = TestCommon.createRooms(typeRoom1.Id);
		roomB.Seq__c = 2;
		roomB.Floor__c = '2F';
		updRoomList.add(roomB);
		Room__c roomC = TestCommon.createRooms(typeRoom1.Id);
		roomC.Seq__c = 3;
		roomC.Floor__c = '10F';
		updRoomList.add(roomC);
		Room__c roomD = TestCommon.createRooms(typeRoom2.Id);
		roomD.Seq__c = 4;
		roomD.Floor__c = '11F';
		updRoomList.add(roomD);
		Room__c roomE = TestCommon.createRooms(typeRoom2.Id);
		roomE.Seq__c = 5;
		roomE.Floor__c = '11F';
		updRoomList.add(roomE);
		
		update updRoomList;
//System.debug(loggingLevel.ERROR, 'updRoomList::' + updRoomList);
		RoomsStatus__c rStatus1 = new RoomsStatus__c(	RoomRef__c=roomB.Id, 
														Status__c=CommConst.ROOM_ST_TYPE_BED,
														StatusBeginDate__c=startDate,
														StatusEndDate__c = startDate);
		insert rStatus1;
		// 新規登録
		LeadIndex__c sobj = new LeadIndex__c();
    	ApexPages.StandardController contrl = new ApexPages.StandardController(sobj);
    	BookingApp app = new BookingApp(contrl);
    	
		app.leadBaseInf.s.EntryDate__c = startDate;
		app.leadBaseInf.s.EntryTime__c = '16:00';
		app.leadBaseInf.s.Nights__c = 1;
		app.leadBaseInf.s.DepartureDate__c = app.leadBaseInf.s.EntryDate__c.addDays(app.leadBaseInf.s.Nights__c.intValue());
		app.leadBaseInf.s.DepartureTime__c = '10:30';
        // 顧客情報を更新を行う
        app.refreshContcatInfo();

 		app.leadBaseInf.contactName = 'UNAME' + Crypto.getRandomLong();
 		app.leadBaseInf.l.Field2__c = '本社';
 		app.leadBaseInf.l.Segment__c = 'CARD';
        app.leadBaseInf.accoutName = 'ACC-NEW' + CommUtils.getRandom(10);
		app.leadBaseInf.s.contactRef__c = guest.Id;
		app.leadBaseInf.s.LeadName__c = 'テストケースの予約名';
		app.leadBaseInf.s.Comment__c = 'Comment_'+ CommUtils.getRandom(10);
		
		BookingApp.LeadItem subItem = app.oLeadLst[0];
		subItem.s.EntryDate__c = app.leadBaseInf.s.EntryDate__c;
		subItem.nights = String.valueOf(app.leadBaseInf.s.Nights__c);
		subItem.s.DepartureDate__c = app.leadBaseInf.s.DepartureDate__c;
		subItem.s.RoomTypeRef__c = typeRoom1.Id;
		subItem.persons = String.valueOf(1);
		subItem.rooms = String.valueOf(3);
		// １件予約データを作成する
 		app.createLeadInfo();
 		RoomIndicatorInfo indicator = new RoomIndicatorInfo();
    	indicator.queryRoomStatus();
    	
    	Test.stopTest();
    	
    	// グループアサイン
    	List<Lead__c> leads = [select id from lead__c where rroom__c = null];
    	System.assertEquals(leads.size(), 3, leads);
    	String leadIds = '';
    	for (Lead__c lead : leads) {
    		leadIds += lead.Id + ',';
    	}
    	leadIds = leadIds.substringBeforeLast(',');
    	String[] fromLeads = leadIds.split(',');
    	String[] noCleanRoomIds = new String[]{};
    	String okRoomIds = '';
    	String ngRoomIds = '';
    	while (true) {
    		RoomIndicatorInfo.AutoAssignRoomResult rs = RoomIndicatorInfo.autoAssignRoomToLead(fromLeads, String.valueOf(roomD.Id), startDate.format(), noCleanRoomIds, okRoomIds, ngRoomIds, false);
    		if (rs.nextLeadIds.size() == 0 ) break;
    		fromLeads = rs.nextLeadIds;
    	}
    	// 2件予約データは割り当てるされる
    	List<Lead__c> assignedLeads = [select id,rroom__c from lead__c where rroom__c != null];
    	Set<Id> roomIdSet = new Set<Id>();
    	roomIdSet.add(roomA.Id);
    	roomIdSet.add(roomC.Id);
    	System.assertEquals(assignedLeads.size(), 2, assignedLeads);
    	Plan__c plan = TestCommon.createPlan();
    	for (Lead__c lead : assignedLeads) {
    		lead.Field310__c = plan.id;
    		System.assert(roomIdSet.contains(lead.Rroom__c), roomIdSet);
    	}
    	indicator.autoCreateBookingEstItems(assignedLeads, sobj.EntryDate__c,sobj.DepartureDate__c);
    	//indicator.upsertContact();
    }
    // 日数変更機能
    static testMethod void chgSaveNightsInfoTest() {
    	Date startDate = Date.today();
    	List<Lead__c> leads = TestCommon.createLead(startDate, 2, 2);
    	// 2015/12/01 Assert BEGIN
		System.assertEquals(leads.size(), 4);
		// 2015/12/01 Assert END
    	// 部屋アサインする
        // 予約データを作成する　
        
        RoomIndicatorInfo indicator = new RoomIndicatorInfo();
        Test.startTest();
        indicator.toToday();
        // 2020/02/29 BY zyz BEGIN
        // List<RoomIndicatorInfo.AreaRoomInfo> areaInfLst = indicator.areaInfLst;
        // 2020/02/29 BY zyz END
        indicator.strLeadId = leads[0].Id;
        String jsonField = 'ReservationDate__c,SearchDate__c';
        String contactFields = 'Phone,email';
        indicator.leadInfo = RoomIndicatorInfo.getRoomInfoExt(leads[0].rroom__c, indicator.strLeadId,jsonField,contactFields);
		// 2020/02/29 BY zyz BEGIN
		// indicator.checkInByRoom();
		// 2020/02/29 BY zyz END
		// 期間変更
		indicator.hadUpdContactFlag = true;
        indicator.leadInfo.nights = indicator.leadInfo.nights+2;
		indicator.chgSaveNightsInfo();
		indicator.leadInfo.nights = indicator.leadInfo.nights-2;
        indicator.chgSaveNightsInfo();
		Test.stopTest();
	}
	// 日数変更機能
    static testMethod void chgSaveNightsInfoTest01() {
		Date startDate = Date.today();
		CommDefine__c comm = TestCommon.createCommDefine();
    	comm.RoomIndicatorEstIsCloneFlg__c = true;
		update comm;
    	List<Lead__c> leads = TestCommon.createLead(startDate, 2, 1);
    	// 2015/12/01 Assert BEGIN
		System.assertEquals(leads.size(), 2);
		// 2015/12/01 Assert END
    	// 部屋アサインする
        // 予約データを作成する　
		RoomIndicatorInfo indicator = new RoomIndicatorInfo();
		Test.startTest();
		indicator.toToday();
        // 2020/02/29 BY zyz BEGIN
        // List<RoomIndicatorInfo.AreaRoomInfo> areaInfLst = indicator.areaInfLst;
        // 2020/02/29 BY zyz END
        indicator.strLeadId = leads[0].Id;
        String jsonField = 'ReservationDate__c,SearchDate__c';
		String contactFields = 'Phone,email';
        indicator.leadInfo = RoomIndicatorInfo.getRoomInfoExt(leads[0].rroom__c, indicator.strLeadId,jsonField,contactFields);
		// 2020/02/29 BY zyz BEGIN
		// indicator.checkInByRoom();
		// 2020/02/29 BY zyz END
		// 期間変更
		indicator.hadUpdContactFlag = true;
		indicator.leadInfo.nights = 1;
		indicator.chgSaveNightsInfo();
		Test.stopTest();
	}
	// 日数変更機能
    static testMethod void chgSaveNightsInfoTest03() {
		Date startDate = Date.today();
		CommDefine__c comm = TestCommon.createCommDefine();
    	comm.RoomIndicatorEstIsCloneFlg__c = true;
		update comm;
    	List<Lead__c> leads = TestCommon.createLead(startDate, 2, 2);
    	// 2015/12/01 Assert BEGIN
		System.assertEquals(leads.size(), 4);
		// 2015/12/01 Assert END
    	// 部屋アサインする
        // 予約データを作成する　
        RoomIndicatorInfo indicator = new RoomIndicatorInfo();
        
        indicator.toToday();
        // 2020/02/29 BY zyz BEGIN
        // List<RoomIndicatorInfo.AreaRoomInfo> areaInfLst = indicator.areaInfLst;
        // 2020/02/29 BY zyz END
        indicator.strLeadId = leads[0].Id;
        String jsonField = 'ReservationDate__c,SearchDate__c';
		String contactFields = 'Phone,email';
        indicator.leadInfo = RoomIndicatorInfo.getRoomInfoExt(leads[0].rroom__c, indicator.strLeadId,jsonField,contactFields);
		// 2020/02/29 BY zyz BEGIN
		// indicator.checkInByRoom();
		// 2020/02/29 BY zyz END
		Test.startTest();

		leads[0].LeadIndexSubId__c = null;
		update leads[0];
		indicator.leadInfo.entryTime = '01:00';
		indicator.chgSaveNightsInfo();
		Test.stopTest();
		
    }
    // 予約新規登録機能
    static testmethod void createLeadTest() {
    	CommDefine__c comm = TestCommon.createCommDefine();
    	comm.RoomPriceProdName__c = '室料[A]';
    	update comm;
    	List<AccountMaster__c> productMst = TestCommon.createProductMst(1);
    	productMst[0].name = '室料[A]';
    	productMst[0].ActionType__c = '室料';
    	update productMst;

    	createDocument();
    	// 2015/12/01 Assert BEGIN
		System.assertEquals([select Id from Document where Name = 'RoomTypeInventoryLeadInputExtendFieldsXml'].size(), 1);
		// 2015/12/01 Assert END
    	// 到着日
    	String startDt = system.now().format('yyyy/MM/dd');
    	// お客様情報を設定する
    	Contact guest = TestCommon.createContact();
    	// 部屋、部屋タイプ作成する
    	Room__c room = TestCommon.createRooms();
    	// Daynmic設定情報を取得する
    	RoomIndicatorInfo indicator = new RoomIndicatorInfo();
    	indicator.filteText = '部屋テスト';
    	List<String> rooms = RoomIndicatorInfo.getFilterRooms(indicator.filteText,'',startDt,false);
    	String filterRoomids = '';
    	if (!rooms.isEmpty()) {
    		for (String roomid : rooms) {
    			filterRoomids += roomid + ',';
    		}
    	}
    	indicator.filterHidRoom = filterRoomids;
    	indicator.gotoDate();
    	Component.Apex.pageBlockSection p = indicator.getInputExtendFields();
    	// 情報設定を行う
    	Lead__c newLead = indicator.newLead;
    	indicator.contactName = guest.name;
    	newLead.Relcontact__c = guest.Id;
    	newLead.refTypeOfRooms__c = room.TypeRoomRef__c;
    	newLead.Rroom__c = room.Id;
    	newLead.name = guest.name + 'ABC';
    	indicator.startDays = startDt;
    	newLead.StayPersons__c = 3;
    	newLead.Field2__c = '電話';
    	Test.startTest();
    	indicator.bookingCreate();
    	Test.stopTest();
    }
    //予約キャンセル機能対応
	static testMethod void leadCancelTest() {
    	Test.startTest();
    	getCsvSetupConfig();
    	createDocument1();
		Lead__c lead1 = TestCommon.createLead();
        Room__c newRoom = TestCommon.createRooms(lead1.refTypeOfRooms__c);
    	String leadId = lead1.Id;
    	String roomId = lead1.Rroom__c;


    	// 予約データを作成する　
    	RoomIndicatorInfo indicator = new RoomIndicatorInfo();
    	indicator.toToday();
    	List<RoomIndicatorInfo.AreaRoomInfo> areaInfLst = indicator.areaInfLst;
    	indicator.strLeadId = leadId;
    	indicator.leadCancel();
    	Test.stopTest();
    }
	// XML 部屋詳細情報 layout  
    static testMethod void addCase2() {
    	getCsvSetupConfig();
    	createDocument1();
    	User currUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	currUser.ShopCode__c = '';
    	update currUser;
    	
    	CommDefine__c comm = TestCommon.createCommDefine();
    	comm.RoomIndicatorIsShowTimeInfo__c = true;
    	comm.RoomIndicatorShowHisFlg__c = true;
    	comm.WatermarkRate__c = true;
    	comm.RoomIndicatorIsShowStayPersons__c = true;
    	update comm;

    	Lead__c lead1 = TestCommon.createLead();
        Room__c newRoom = TestCommon.createRooms(lead1.refTypeOfRooms__c);
    	String leadId = lead1.Id;
    	String strLeadsId = lead1.Id;
    	String roomId = lead1.Rroom__c;
    	String strRoomsId = newRoom.id;
		Test.startTest();
    	RoomIndicatorInfo indicator = new RoomIndicatorInfo();
    	Boolean rLookupHoverIsShowFlg = indicator.rLookupHoverIsShowFlg;
    	Integer staysNums = indicator.staysNums;
    	Boolean isShowQreqki = indicator.isShowQreqki;
    	//String processDtStr = indicator.processDtStr;
    	Boolean isShowHisFlg = indicator.isShowHisFlg;
    	Boolean isShowHisAssignWinFlg = indicator.isShowHisAssignWinFlg;
    	Integer roomInfoNameTypeLeadname = RoomIndicatorInfo.ROOM_INFO_NAME_TYPE_LEADNAME;
    	// Integer roomDivWidth = RoomIndicatorInfo.roomDivWidth;
    	Boolean watermarkRate = indicator.WatermarkRate;
    	Boolean isShowStayPerson = indicator.isShowStayPerson;
    	Boolean mainIsShowErr = indicator.mainIsShowErr;
    	List<Selectoption> roomNameTypeOptions = indicator.getRoomNameTypeOptions();
    	String rRoomsStatusinfo = indicator.rRoomsStatusinfo;
    	String rRoomsStatusColorinfo = indicator.rRoomsStatusColorinfo;
    	// String strToday = indicator.strToday;

    	//indicator.toToday();
    	List<RoomIndicatorInfo.AreaRoomInfo> areaInfLst = indicator.areaInfLst;
    	indicator.strLeadId = leadId;
    	indicator.checkInByRoom();
    	
    	indicator.checkOutByRoom();
    	Test.stopTest();
    	indicator.toNext();
    	indicator.toPrev();
    	//indicator.gotoDate();
    	// 予約データを作成する
    	//RoomIndicatorInfo.PopupWinInfo popupInfo = RoomIndicatorInfo.getRoomInfo(roomId, leadId);
    	//System.assertNotEquals(popupInfo.leadId, null);

    	SObject[] sLst = RoomIndicatorInfo.getChangeRoom(leadId, '');
        indicator.strNewRoomId = newRoom.Id;
        //indicator.changeRoom();
        String queryDt = DateTime.now().format('yyyy/MM/dd');
        RoomIndicatorInfo.cleanRoomAction(new List<Id>{roomId}, queryDt);
        RoomIndicatorInfo.preChgSaveNightsInfo(newRoom.Id, lead1.Id, 1, 2, '', true);
    }
    static testMethod void addCase1() {
    	getCsvSetupConfig();
    	createDocument1();
    	User currUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	currUser.ShopCode__c = '';
    	update currUser;
    	
    	CommDefine__c comm = TestCommon.createCommDefine();
    	comm.RoomIndicatorIsShowTimeInfo__c = true;
    	comm.RoomIndicatorShowHisFlg__c = true;
    	comm.WatermarkRate__c = true;
		comm.RoomIndicatorIsShowStayPersons__c = true;
    	update comm;

    	Lead__c lead1 = TestCommon.createLead();
    	// 做重复顾客数据
    	Contact defContact = new Contact(
    		firstName = 'UNIT_TEST_顧客名' + CommUtils.getRandom(6),
    		LastName = 'LASTNAME'+CommUtils.getRandom(6),
    		Katakana__c = 'Katakana__c'+CommUtils.getRandom(10),
    		KanaName1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Name1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Phone = CommUtils.getRandom(10)
    		);
    	defContact.Phone = lead1.Relcontact__r.Phone;
    	insert defContact;
        Room__c newRoom = TestCommon.createRooms(lead1.refTypeOfRooms__c);
    	String leadId = lead1.Id;
    	String roomId = lead1.Rroom__c;
		Test.startTest();
    	RoomIndicatorInfo indicator = new RoomIndicatorInfo();
    	Boolean rLookupHoverIsShowFlg = indicator.rLookupHoverIsShowFlg;
    	Integer staysNums = indicator.staysNums;
    	Boolean isShowQreqki = indicator.isShowQreqki;
    	//String processDtStr = indicator.processDtStr;
    	Boolean isShowHisFlg = indicator.isShowHisFlg;
    	Boolean isShowHisAssignWinFlg = indicator.isShowHisAssignWinFlg;
    	Integer roomInfoNameTypeLeadname = RoomIndicatorInfo.ROOM_INFO_NAME_TYPE_LEADNAME;
    	// Integer roomDivWidth = RoomIndicatorInfo.roomDivWidth;
    	Boolean watermarkRate = indicator.WatermarkRate;
    	Boolean isShowStayPerson = indicator.isShowStayPerson;
    	Boolean mainIsShowErr = indicator.mainIsShowErr;
    	List<Selectoption> roomNameTypeOptions = indicator.getRoomNameTypeOptions();
    	String rRoomsStatusinfo = indicator.rRoomsStatusinfo;
    	String rRoomsStatusColorinfo = indicator.rRoomsStatusColorinfo;
    	// String strToday = indicator.strToday;


    	//indicator.toToday();
    	List<RoomIndicatorInfo.AreaRoomInfo> areaInfLst = indicator.areaInfLst;
    	indicator.strLeadId = leadId;
    	indicator.checkInByRoom();
    	
    	indicator.checkOutByRoom();
    	Test.stopTest();
    	indicator.toNext();
    	indicator.toPrev();
    	//indicator.gotoDate();
    	// 予約データを作成する
        String jsonField = 'ReservationDate__c,SearchDate__c';
        String contactFields = 'Phone,email';
    	//RoomIndicatorInfo.PopupWinInfo popupInfo = RoomIndicatorInfo.getRoomInfoExt(roomId, leadId,jsonField,contactFields);
    	//System.assertNotEquals(popupInfo.leadId, null);

    	SObject[] sLst = RoomIndicatorInfo.getChangeRoom(leadId, '');
        indicator.strNewRoomId = newRoom.Id;
        //indicator.changeRoom();
        String queryDt = DateTime.now().format('yyyy/MM/dd');
        //RoomIndicatorInfo.cleanRoomAction(new List<Id>{roomId}, queryDt, leadId);
        RoomIndicatorInfo.cleanRoomAction(new List<Id>{roomId}, queryDt);
        RoomIndicatorInfo.preChgSaveNightsInfo(newRoom.Id, lead1.Id, 1, 2, '', true);
		BookingGuest__c book = new BookingGuest__c(IndexSubRef__c =  lead1.LeadIndexRef__c);
		insert book;
		book.RoomRef__c = roomId;
		update book;
    }
    // 2020/02/29 BY zyz BEGIN
    static testMethod void myUnitTest1() {
    	Test.startTest();
    	getCsvSetupConfig();
    	createDocument1();
		Lead__c lead1 = TestCommon.createLead();
        Room__c newRoom = TestCommon.createRooms(lead1.refTypeOfRooms__c);
    	String leadId = lead1.Id;
    	Test.stopTest();
        String entryTime = lead1.EntryTime__c.format('yyyy/MM/dd');
        RoomIndicatorInfo.leadNightInfo(leadId,lead1.LeadIndexRef__c,entryTime);
        Map<String,object> req = new Map<String,object>{'leadId'=>leadId,'roomNumStr'=>'1'};
        RoomIndicatorInfo.createLeadInfo(JSON.serialize(req),false);
    }
	// 2020/02/29 BY zyz END
	// 日数変更機能
    static testMethod void outAndInRoomTest() {
		createCleanRoomConfigDocument();
		Date startDate = Date.today();
		CommDefine__c comm = TestCommon.createCommDefine();
		comm.RoomIndicatorEstIsCloneFlg__c = true;
		comm.ShopAccountSearchDiv__c = '1';
		update comm;
    	List<Lead__c> leads = TestCommon.createLead(startDate, 2, 1);
    	// 2015/12/01 Assert BEGIN
		System.assertEquals(leads.size(), 2);
		// 2015/12/01 Assert END
    	// 部屋アサインする
        // 予約データを作成する　
		RoomIndicatorInfo indicator = new RoomIndicatorInfo();
		Test.startTest();
		indicator.toToday();
        // 2020/02/29 BY zyz BEGIN
        // List<RoomIndicatorInfo.AreaRoomInfo> areaInfLst = indicator.areaInfLst;
        // 2020/02/29 BY zyz END
        indicator.strLeadId = leads[0].Id;
		indicator.outByRoom();
		indicator.returnByRoom();
		indicator.strLeadId = '';
		indicator.outByRoom();
		indicator.returnByRoom();
		Plan__c plan = TestCommon.createPlanIncRoom0();
		List<AccountMaster__c> accs = [select id , Field3__c from AccountMaster__c ];
		if (!accs.isEmpty()) {
			RoomIndicatorInfo.getArrayProductDetailItemInfo(accs[0].Field3__c);
			RoomIndicatorInfo.getArrayProductItemInfoNoPlan(accs[0].Field3__c);
		}
		Test.stopTest();
		// indicator.defaultDetialPage();
		String shopStr = indicator.shopLst;
	}
    private static void createDocument(){
    	String documentFileStr = '<?xml version="1.0" encoding="UTF-8"?><root>	<SHOP>		<SHOPCODE></SHOPCODE><DEFROOMTYPE><DEFVALUES SEQ="1"><DEFINE><APINAME>Field4__c</APINAME><DEFVALUE>15:00</DEFVALUE></DEFINE></DEFVALUES></DEFROOMTYPE><COLNUMS>2</COLNUMS>	<!-- Layoutに１行に表示の列数[1,2]と定義する -->		<FIELDS>		Segment__c		,CouponTypeLst__c		,Mans__c		,Femails__c		,ChildFA__c		,Childs__c		,ChildC__c		,ChildD__c		,Field348__c		,ReservedType__c		,Comment3__c		</FIELDS>	</SHOP>	<SHOP>		<SHOPCODE>01</SHOPCODE>		<FIELDS>		CouponTypeLst__c		,Mans__c		,Femails__c		,ChildFA__c		,Childs__c		,ChildC__c		,ChildD__c		,ReservedType__c		,OrgCreateDate__c		,OrgUpdateDate__c		,Rich2__c		,Comment3__c		</FIELDS>	</SHOP></root>';
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'RoomTypeInventoryLeadInputExtendFieldsXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(documentFileStr);
    	insert item;
    }
    private static String getCsvSetupConfig() {
        String csv = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP><SHOPCODE></SHOPCODE><PAYMENT><CONVERT><PAYTYPE>現金</PAYTYPE><MEIDALAB>預り／現計</MEIDALAB></CONVERT><CONVERT><PAYTYPE>カード</PAYTYPE><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB></CONVERT><CONVERT><PAYTYPE>売掛金</PAYTYPE><MEIDALAB>掛計</MEIDALAB></CONVERT><CONVERT><PAYTYPE>クーポン</PAYTYPE><MEIDALAB>クーポン</MEIDALAB></CONVERT><CONVERT><PAYTYPE>値引</PAYTYPE><MEIDALAB>値引・割引券</MEIDALAB></CONVERT><CONVERT><PAYTYPE>予約金</PAYTYPE><MEIDALAB>予約金</MEIDALAB></CONVERT></PAYMENT><PAYMEIDA><CONVERT><MEIDALAB>預り／現計</MEIDALAB><PRODCODE>87001</PRODCODE></CONVERT><CONVERT><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB><PRODCODE>85201</PRODCODE></CONVERT><CONVERT><MEIDALAB>掛計</MEIDALAB><PRODCODE>85101</PRODCODE></CONVERT><CONVERT><MEIDALAB>クーポン</MEIDALAB><PRODCODE>85610</PRODCODE></CONVERT><CONVERT><MEIDALAB>値引・割引券</MEIDALAB><PRODCODE>87005</PRODCODE></CONVERT><CONVERT><MEIDALAB>予約金</MEIDALAB><PRODCODE>87001</PRODCODE></CONVERT></PAYMEIDA></SHOP></root>';
        Document doc = new Document();
        doc.Name = 'BillSimpleHelpConfig';
        doc.DeveloperName = doc.Name;
        doc.FolderId = UserInfo.getUserId();
        doc.Body = Blob.valueOf(csv);
        insert doc;
    	return csv;    
    }
    private static void createDocument1(){
    	String documentFileStr = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP><SHOPCODE>02</SHOPCODE><RELCONTACT><DUPRULES><DUPRULE>name</DUPRULE></DUPRULES><DUPRULES><DUPRULE>phone</DUPRULE></DUPRULES></RELCONTACT><CREATEINFO><LEADSINFO CONTION="RecordType.Name=\'宿泊\'"><LEADINFO NIGHTS="0" OFFSETDAYS="1"><CLONE>FIELD3__c,ReservedDate__c,EntryTime__c,Field4__c,Departure__c</CLONE><ASSIGN FIELD="StayPersons__c">3</ASSIGN><ROOMTYPE>1</ROOMTYPE></LEADINFO></LEADSINFO></CREATEINFO><FIELDS><SECTION  COLNUM="2">Relcontact__c,Relcontact__r.KanaName1__c,$_blank_$,Checkmorining__c,Field3__c,Field305__c,Departure__c,Rroom__c,Field369__c,DEMO_00012__c,SalesOfficeInfoRef__c,Field298__c,BridalDantaikei__c,Relcontact__r.gender__c,Relcontact__r.Phone2__c,Relcontact__r.Name1__c,Relcontact__r.Usage_Charge__c,Relcontact__r.CarNo__c,Relcontact__r.Usage_Count__c,Relcontact__r.Email2__c,Relcontact__r.Field28__c,Relcontact__r.OrgCreateDate__c,Relcontact__r.LastUsageDate__c,Relcontact__r.SmokeFlg__c,Relcontact__r.DelFlg__c,Relcontact__r.ParentContactRef__c</SECTION><SECTION TITLE="Title2" COLNUM="1">Relcontact__c,Relcontact__r.Field1__c,QuotationComment__c,Morimongn__c,FoodComment__c,Field283__c,Field351__c </SECTION></FIELDS><DISPLAY><WINDOWWIDTH>700</WINDOWWIDTH><WINDOWHEIGHT>500</WINDOWHEIGHT><LINEHEIGHT>false</LINEHEIGHT></DISPLAY></SHOP></root>';
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'RoomIndicatorInfoLeadOutputExtendFieldsXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(documentFileStr);
    	insert item;
	}
	static void createCleanRoomConfigDocument(){
    	String domString = '<?xml version="1.0" encoding="UTF-8"?><ROOT>    <SHOP>        <SHOPCODE></SHOPCODE>        <COMPLETESTATUS>インスペ完</COMPLETESTATUS>        <COLORCONFIG> <STATUS COLOR="darkcyan" ROOMINDICATOR="FALSE">未清掃</STATUS><STATUS COLOR="#00ccff" ROOMINDICATOR="FALSE">清掃中</STATUS><STATUS COLOR="darkgreen" ROOMINDICATOR="FALSE">清掃完了インスペ未完</STATUS><STATUS COLOR="royalblue" ROOMINDICATOR="FALSE">インスペ中</STATUS><STATUS COLOR="gray" ROOMINDICATOR="FALSE">インスペ完</STATUS>    </COLORCONFIG>        <CHATERCONFIG>        	<STATUS GROUP="TL2WAY連携管理グループ2" MESSAGE="@room @status対応します">未清掃,清掃完了インスペ未完,インスペ中</STATUS>        </CHATERCONFIG><CHECKCONFIG><CHECKLIST><STATUS>インスペ中</STATUS><NEXTSTATUS>インスペ完</NEXTSTATUS><FIELDS>CheckItem1__c,CheckItem2__c,CheckItem3__c,CheckItem4__c,CheckItem5__c</FIELDS></CHECKLIST></CHECKCONFIG></SHOP>    </ROOT>';
    	Document item = new Document();
    	item.Name = 'CleanRoomConfig';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(domString);
    	insert item;
    }
}