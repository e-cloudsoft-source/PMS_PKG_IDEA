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
private class RoomScheduleReportTest {
	
    static testMethod void myUnitTest() {
    	Test.startTest();
    	// 予約情報を作成する
    	Date curDt = Date.today();
    	//List<Lead__c> leads1 = TestCommon.createLead(curDt, 3, 2);
        
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'AppSetupConfigXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(getCsvSetupConfig());
    	insert item;
    	
		RoomScheduleReport R1 = NEW RoomScheduleReport();
		R1.init();
		Test.stopTest();
		Map<Id, RoomScheduleReport.OneRoomAssingInfo> roomBookingMap = R1.roomBookingMap;
		R1.refreshBranchShopInfo();
		List<List<Id>> roomList = R1.roomList;
		for (List<Id> rooms : roomList) {
			for (Id roomId : rooms) {
				RoomScheduleReport.OneRoomAssingInfo one = roomBookingMap.get(roomId);
				System.assert(one.tdHtml != '');
			}
		}	
    }
    
    static testMethod void Case002_CreateLead() {
    	// 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
		CommDefine__c comm = TestCommon.createCommDefine();
    	// 入汤税设定Mode
    	comm.AccountBathTaxAutoSetupFlg2__c = CommConst.PLAN_BATHTAXAUTOSET_3;
		update comm;
		// 2020/07/30 入湯税の自動入力機能について改善 WGCH END
    	createHolidayXml();
    	createDocument1();
    	Test.startTest();
    	// 予約情報を作成する
    	Date curDt = Date.today();
    	//List<Lead__c> leads1 = TestCommon.createLead(curDt, 3, 2);
    	TypeOfRooms__c typeRoom1 = TestCommon.createTypeOfRoom(10);
		Room__c roomA = TestCommon.createRooms(typeRoom1.Id);
		ShopInformation__c shop = TestCommon.createShopInfo();
		shop.ShopCode__c = '02';
		upsert shop;
		roomA.ShopInfoRef__c = shop.Id;
		upsert roomA;
		//leads1[0].Rroom__c = roomA.Id;
		//upsert leads1;
		Plan__c plan = TestCommon.createPlan();
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'AppSetupConfigXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(getCsvSetupConfig());
    	insert item;
    	// 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'AppSetupConfigXml'].size(), 1);
        // 2015/12/01 Assert END
		RoomScheduleReport ctl = NEW RoomScheduleReport();
		ctl.init();
		ctl.getViewModeList();
		Test.stopTest();
        // 予約
        ctl.contactName = 'GUESTNAME' + CommUtils.getRandom(10);
        ctl.newContact.Katakana__c = CommUtils.getRandom(10);
        ctl.newLead.name = 'LEADNAME' + CommUtils.getRandom(10);
        ctl.newLead.Field2__c = 'テストセル';
        ctl.newLead.StayPersons__c = 1;
        ctl.roomIds = roomA.ID+'_'+typeRoom1.id;
        ctl.newLead.Field310__c = plan.id;
        ctl.staysNums = 2;
        ctl.startDays = Date.today().format();
        //ctl.bookingRooms = 2;
        ctl.newLead.ExtraBedChk__c = true;
        ctl.viewMode = 'ONEDAY-05';
        // 予約作成
        ctl.bookingCreate();
        ctl.refreshTypeOfRoomInfo();
    }
    static testMethod void Case003_CreateLead() {
    	createHolidayXml();
    	createDocument();
    	Test.startTest();
    	// 予約情報を作成する
    	Date curDt = Date.today();
    	CommDefine__c comm = TestCommon.createCommDefine();
	    // 商品情報を作成する[5件商品を作成する]
        List<AccountMaster__c> productLst = TestCommon.createProductMst(5);
        comm.RoomIndicatorInfoNameType__c = 1;
    	comm.RoomPriceProdName__c = '室料[A]';
    	comm.RoomTypeNewBookingWinVersion__c = 2;
		// 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
		comm.AccountRenpakuBathTaxAutoSetupFlg__c = true;
    	// 入汤税设定Mode
    	comm.AccountBathTaxAutoSetupFlg2__c = CommConst.PLAN_BATHTAXAUTOSET_2;
		// 2020/07/30 入湯税の自動入力機能について改善 WGCH END
		comm.CheckInDayUserConfigFlg__c = true;
    	update comm;
    	List<AccountMaster__c> productMst = TestCommon.createProductMst(1);
    	productMst[0].name = '室料[A]';
    	productMst[0].ActionType__c = '室料';
    	update productMst;
    	//List<Lead__c> leads1 = TestCommon.createLead(curDt, 3, 2);

    	TypeOfRooms__c typeRoom1 = TestCommon.createTypeOfRoom(10);
		Room__c roomA = TestCommon.createRooms(typeRoom1.Id);
		ShopInformation__c shop = TestCommon.createShopInfo();
		shop.ShopCode__c = '02';
		upsert shop;
		roomA.ShopInfoRef__c = shop.Id;
		upsert roomA;
		//leads1[0].Rroom__c = roomA.Id;
		//upsert leads1;
		Plan__c plan = TestCommon.createPlan();
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'AppSetupConfigXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(getCsvSetupConfig());
    	insert item;
    	// 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'AppSetupConfigXml'].size(), 1);
        // 2015/12/01 Assert END
		RoomScheduleReport ctl = NEW RoomScheduleReport();
		ctl.init();
		ctl.getViewModeList();
		ctl.getInputExtendFields();
		Test.stopTest();
        // 予約
        ctl.contactName = 'GUESTNAME' + CommUtils.getRandom(10);
        ctl.newContact.Katakana__c = CommUtils.getRandom(10);
        ctl.newLead.name = 'LEADNAME' + CommUtils.getRandom(10);
        ctl.newLead.Field2__c = 'テストセル';
        ctl.newLead.StayPersons__c = null;
        ctl.roomIds = roomA.ID+'_'+typeRoom1.id;
        ctl.newLead.Field310__c = plan.id;
        ctl.staysNums = 0;
        //ctl.newLeadIndex.Nights__c = staysNums;
        ctl.startDays = Date.today().format();
        //ctl.bookingRooms = 2;
        ctl.newLead.ExtraBedChk__c = true;
        ctl.viewMode = 'ONEDAY-10';
        // 予約作成
        ctl.bookingCreate();
        ctl.refreshTypeOfRoomInfo();
    }
   static testMethod void Case004_CreateLead() {
    	createHolidayXml();   	
        createPlanHadHoomZero('80');
    	Test.startTest();
    	 Date startDate = Date.newInstance(2013, 9, 15);
    	// 予約情報を作成する
    	Date curDt = Date.today();
    	//List<Lead__c> leads1 = TestCommon.createLead(curDt, 3, 2);
    	TypeOfRooms__c typeRoom1 = TestCommon.createTypeOfRoom(2);
		Room__c roomA = TestCommon.createRooms(typeRoom1.Id);
		upsert roomA;
		//leads1[0].Rroom__c = roomA.Id;
		//upsert leads1;
		RoomsStatus__c rStatus1 = new RoomsStatus__c(   RoomRef__c=roomA.Id, 
                                                        Status__c=CommConst.ROOM_ST_TYPE_BED,
                                                        StatusBeginDate__c=startDate,
                                                        StatusEndDate__c = startDate.addDays(2),
                                                        Result__c = '修理中');
        RoomsStatus__c rStatus2 = new RoomsStatus__c(   RoomRef__c=roomA.Id, 
                                                        Status__c=CommConst.ROOM_ST_TYPE_BED_FIN,
                                                        StatusBeginDate__c=startDate,
                                                        StatusEndDate__c = startDate); 
        
        List<RoomsStatus__c> insRooms = new List<RoomsStatus__c>();
        insRooms.add(rStatus1);
        insRooms.add(rStatus2);
        insert insRooms;
        Contact con = new Contact(
    		firstName = 'UNIT_TEST_顧客名' + CommUtils.getRandom(6),
    		LastName = 'LASTNAME'+CommUtils.getRandom(6),
    		Katakana__c = 'Katakana__c'+CommUtils.getRandom(10),
    		KanaName1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Name1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Phone = CommUtils.getRandom(10)
    		);
    	insert con;
    	Plan__c plan = TestCommon.createPlan();
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'AppSetupConfigXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(getCsvSetupConfig());
    	insert item;
    	// 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'AppSetupConfigXml'].size(), 1);
        // 2015/12/01 Assert END
		RoomScheduleReport ctl = NEW RoomScheduleReport();
		ctl.init();
		ctl.getViewModeList();
		ctl.getDefaultCheckinTime();
		ctl.getDefaultCheckoutTime();
		ctl.getPageTitleInfo();
		Test.stopTest();
        // 予約
        ctl.contactName = 'GUESTNAME' + CommUtils.getRandom(10);
        ctl.newContact.Katakana__c = CommUtils.getRandom(10);
        ctl.newLead.name = 'LEADNAME' + CommUtils.getRandom(10);
        ctl.newLead.Field2__c = 'テストセル';
        ctl.newLead.StayPersons__c = 1;
        ctl.roomIds = roomA.ID+'_'+typeRoom1.id;
        ctl.newLead.Field310__c = null;
        ctl.staysNums = 2;
        ctl.startDays = Date.today().format();
        //ctl.bookingRooms = 2;
        ctl.newLead.ExtraBedChk__c = true;
        ctl.viewMode = 'ONEDAY-30';
        // 予約作成
        ctl.bookingCreate();
        ctl.refreshTypeOfRoomInfo();
    }
    static testMethod void Case005_CreateLead() {
    	createHolidayXml();
    	createDocument1();
    	Test.startTest();
    	// 予約情報を作成する
    	Date curDt = Date.today();
    	Date startDate = Date.newInstance(2016, 9, 29);
    	CommDefine__c comm = TestCommon.createCommDefine();
	    // 商品情報を作成する[5件商品を作成する]
        List<AccountMaster__c> productLst = TestCommon.createProductMst(5);
        comm.RoomIndicatorInfoNameType__c = 2;
    	comm.RoomPriceProdName__c = '室料[A]';
    	comm.RoomTypeNewBookingWinVersion__c = 2;
    	update comm;
    	//List<Lead__c> leads1 = TestCommon.createLead(curDt, 3, 2);
    	TypeOfRooms__c typeRoom1 = TestCommon.createTypeOfRoom(10);
		Room__c roomA = TestCommon.createRooms(typeRoom1.Id);
		Room__c roomB = TestCommon.createRooms(typeRoom1.Id);
		ShopInformation__c shop = TestCommon.createShopInfo();
		shop.ShopCode__c = '02';
		upsert shop;
		roomA.ShopInfoRef__c = shop.Id;
		roomB.ShopInfoRef__c = shop.Id;
		upsert roomA;
		upsert roomB;
		//leads1[0].Rroom__c = roomA.Id;
		//upsert leads1;
		RoomsStatus__c rStatus1 = new RoomsStatus__c(   RoomRef__c=roomA.Id, 
                                                        Status__c='通常:1,休館,貸切',
                                                        StatusBeginDate__c=startDate,
                                                        StatusEndDate__c = startDate.addDays(2));
        RoomsStatus__c rStatus2 = new RoomsStatus__c(   RoomRef__c=roomA.Id, 
                                                        Status__c='通常:1,休館,貸切',
                                                        StatusBeginDate__c=startDate,
                                                        StatusEndDate__c = startDate); 
        
        List<RoomsStatus__c> insRooms = new List<RoomsStatus__c>();
        insRooms.add(rStatus1);
        insRooms.add(rStatus2);
        insert insRooms;
		Contact con = new Contact(
    		firstName = 'UNIT_TEST_顧客名' + CommUtils.getRandom(6),
    		LastName = 'LASTNAME'+CommUtils.getRandom(6),
    		Katakana__c = 'Katakana__c'+CommUtils.getRandom(10),
    		KanaName1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Name1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Phone = CommUtils.getRandom(10)
    		);
    	insert con;
		Plan__c plan = TestCommon.createPlan();
		LeadIndex__c index = new LeadIndex__c(
    		ID__c = String.valueOf(Math.random()),
    		Nights__c = 2,
     		EntryTime__c = '10:00',
    		EntryDate__c = startDate,
    		DepartureTime__c = '15:30',
    		DepartureDate__c = startDate,
			EventSource__c = 'テストクラスから',
			Rooms__c = 1
    	);
    	insert index;
    	Lead__c item1 = new Lead__c(
    	   RecordTypeId = CommLogicProcess.getLeadBookingRecType(),
    	   name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
    	   Relcontact__c = con.Id,                  // 顧客名
    	   ReservedStatus__c = '確認中',
    	   ReservedDate__c = System.now(),
    	   ReservedContact__c = 'Ono',
    	   EntryTime__c = startDate,
    	   Field4__c = '15:30',
    	   Departure__c = startDate,
    	   Field3__c = '18:00',
    	   StayPersons__c = 4,
    	   Field2__c = 'FAX',
    	   Field310__c = plan.Id,
    	   LeadIndexRef__c = index.Id,
    	   Rroom__c = roomA.Id,
    	   refTypeOfRooms__c = roomA.TypeRoomRef__c);
    	   Lead__c item2 = new Lead__c(
    	   RecordTypeId = CommLogicProcess.getLeadBookingRecType(),
    	   name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
    	   Relcontact__c = con.Id,                  // 顧客名
    	   ReservedStatus__c = '確認中',
    	   ReservedDate__c = System.now(),
    	   ReservedContact__c = 'Two',
    	   EntryTime__c = startDate,
    	   Field4__c = '15:30',
    	   Departure__c = startDate.addDays(1),
    	   Field3__c = '10:00',
    	   StayPersons__c = 4,
    	   Field2__c = 'FAX',
    	   Field310__c = plan.Id,
    	   LeadIndexRef__c = index.Id,
    	   Rroom__c = roomA.Id,
    	   refTypeOfRooms__c = roomA.TypeRoomRef__c);
    	insert (new List<Lead__c>{item1, item2});
    	List<AccountMaster__c> productMst = TestCommon.createProductMst(1);
    	productMst[0].name = null;
    	productMst[0].ActionType__c = '室料';
    	update productMst;
    	 BookingEstimateItem__c booking = new BookingEstimateItem__c (
           //Name = '名称2(漢1)_UNIT_TEST_AUTONUM_' + system.now(),
           Amount__c = 4,
           refBooking__c = item1.id,
           refAccountMaster__c = productMst[0].Id,      // 商品名
           Field3__c = productMst[0].Field3__c,         // 商品コード
           UnitPrice__c = 20000,
           PaymentType__c = '予約金'
        );
        insert booking;
        
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'AppSetupConfigXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(getCsvSetupConfig());
    	insert item;
    	// 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'AppSetupConfigXml'].size(), 1);
        // 2015/12/01 Assert END
		RoomScheduleReport ctl = NEW RoomScheduleReport();
		ctl.init();
		ctl.getViewModeList();
		ctl.getDefaultCheckinTime();
		ctl.getDefaultCheckoutTime();
		ctl.getPageTitleInfo();
		RoomScheduleReport.refreshContcatInfo(con.Id,con.Name);
		RoomScheduleReport.getPlanDetailListById(plan.Id);
		RoomScheduleReport.getArrayProductItemInfo(productMst[0].Id);
		RoomScheduleReport.getRoomMessageJson('02',roomA.Id);		
		RoomScheduleReport.LeadInfo l = RoomScheduleReport.changeRoomByAjax(roomA.Id,roomB.Id,item1.Id+'_'+roomB.Id+'_'+startDate,'02','2016/09/29','ONEWEEK','124','部屋ｽﾃｰﾀｽ');
		//RoomScheduleReport.LeadInfo lea = RoomScheduleReport.preAddLeadMessage(roomA.Id,'02','2016/09/29','ONEWEEK',guuid,'部屋ｽﾃｰﾀｽ');
		RoomScheduleReport.LeadInfo le = RoomScheduleReport.refreshRoomByIds(roomA.Id,'02','2016/09/29','ONEWEEK','124','部屋ｽﾃｰﾀｽ');
		RoomScheduleReport.getBadRoomMessage('2016/09/29','ONEWEEK');
		Test.stopTest();
        // 予約
        ctl.contactName = 'GUESTNAME' + CommUtils.getRandom(10);
        ctl.newContact.Katakana__c = CommUtils.getRandom(10);
        ctl.newLead.name = 'LEADNAME' + CommUtils.getRandom(10);
        ctl.newLead.Field2__c = 'テストセル';
        ctl.newLead.StayPersons__c = 1;
        ctl.roomIds = roomA.ID+'_'+typeRoom1.id;
        ctl.newLead.Field310__c = plan.id;
        ctl.staysNums = 2;
        ctl.startDays = Date.today().format();
        //ctl.bookingRooms = 2;
        ctl.newLead.ExtraBedChk__c = true;
        // 予約作成
        ctl.viewMode = 'ONEWEEK';
        ctl.bookingCreate();
        ctl.refreshTypeOfRoomInfo();
    }
    static testMethod void Case006_CreateLead_Excption() {
    	createHolidayXml();
    	createDocument1();
    	Test.startTest();
    	// 予約情報を作成する
    	Date curDt = Date.today();
    	Date startDate = Date.newInstance(2016, 9, 29);
    	CommDefine__c comm = TestCommon.createCommDefine();
	    // 商品情報を作成する[5件商品を作成する]
        List<AccountMaster__c> productLst = TestCommon.createProductMst(5);
        comm.RokuyoIsNoShow__c = true;
    	comm.RoomPriceProdName__c = '室料[A]';
    	comm.RoomTypeNewBookingWinVersion__c = 2;
    	update comm;
    	List<AccountMaster__c> productMst = TestCommon.createProductMst(1);
    	productMst[0].name = '室料[A]';
    	productMst[0].ActionType__c = '室料';
    	update productMst;
    	//List<Lead__c> leads1 = TestCommon.createLead(curDt, 3, 2);
    	TypeOfRooms__c typeRoom1 = TestCommon.createTypeOfRoom(10);
		Room__c roomA = TestCommon.createRooms(typeRoom1.Id);
		Room__c roomB = TestCommon.createRooms(typeRoom1.Id);
		ShopInformation__c shop = TestCommon.createShopInfo();
		shop.ShopCode__c = '02';
		upsert shop;
		roomA.ShopInfoRef__c = shop.Id;
		roomB.ShopInfoRef__c = shop.Id;
		upsert roomA;
		upsert roomB;
		//leads1[0].Rroom__c = roomA.Id;
		//upsert leads1;
		Contact con = new Contact(
    		firstName = 'UNIT_TEST_顧客名' + CommUtils.getRandom(6),
    		LastName = 'LASTNAME'+CommUtils.getRandom(6),
    		Katakana__c = 'Katakana__c'+CommUtils.getRandom(10),
    		KanaName1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Name1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Phone = CommUtils.getRandom(10)
    		);
    	insert con;
		Plan__c plan = TestCommon.createPlan();
    	Lead__c item1 = new Lead__c(
    	   RecordTypeId = CommLogicProcess.getLeadBookingRecType(),
    	   name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
    	   Relcontact__c = con.Id,                  // 顧客名
    	   ReservedStatus__c = '確認中',
    	   ReservedDate__c = System.now(),
    	   ReservedContact__c = 'Ono',
    	   EntryTime__c = startDate,
    	   Field4__c = '',
    	   Departure__c = startDate,
    	   Field3__c = '',
    	   StayPersons__c = 4,
    	   Field2__c = 'FAX',
    	   Field310__c = plan.Id,
    	   //LeadIndexRef__c = leadIndex.Id,
    	   Rroom__c = roomA.Id,
    	   refTypeOfRooms__c = roomA.TypeRoomRef__c);
    	   Lead__c item2 = new Lead__c(
    	   RecordTypeId = CommLogicProcess.getLeadBookingRecType(),
    	   name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
    	   Relcontact__c = con.Id,                  // 顧客名
    	   ReservedStatus__c = '確認中',
    	   ReservedDate__c = System.now(),
    	   ReservedContact__c = 'Ono',
    	   EntryTime__c = startDate,
    	   Field4__c = '',
    	   Departure__c = startDate,
    	   Field3__c = '',
    	   StayPersons__c = 4,
    	   Field2__c = 'FAX',
    	   Field310__c = plan.Id,
    	   //LeadIndexRef__c = leadIndex.Id,
    	   Rroom__c = roomA.Id,
    	   refTypeOfRooms__c = roomA.TypeRoomRef__c);
    	insert (new List<Lead__c>{item1, item2});
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'AppSetupConfigXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(getCsvSetupConfig());
    	insert item;
    	// 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'AppSetupConfigXml'].size(), 1);
        // 2015/12/01 Assert END
		RoomScheduleReport ctl = NEW RoomScheduleReport();
		ctl.init();
		ctl.getViewModeList();
		Test.stopTest();
        // 予約
        ctl.contactName = 'GUESTNAME' + CommUtils.getRandom(10);
        ctl.newContact.Katakana__c = CommUtils.getRandom(10);
        ctl.newLead.name = 'LEADNAME' + CommUtils.getRandom(10);
        ctl.newLead.Field2__c = 'テストセル';
        ctl.newLead.StayPersons__c = 1;
        ctl.roomIds = roomA.ID+'_'+typeRoom1.id;
        ctl.newLead.Field310__c = plan.id;
        ctl.staysNums = 0;
        ctl.viewMode = '90DAYS';
        ctl.startDays = Date.today().format();
        //ctl.bookingRooms = 2;
        ctl.newLead.ExtraBedChk__c = false;
        // 予約作成
        ctl.bookingCreate();	
        //ctl.roomBookingMap.get(roomA.ID).tdhtml();
        ctl.newLead.Field4__c = '03:00';
    	ctl.newLead.Field3__c = '04:00';
    	ctl.bookingCreate();
    	ctl.viewMode = '90DAYS';
        ctl.refreshTypeOfRoomInfo();
    }
    static testMethod void Case007_CreateLead() {
    	createHolidayXml();
    	createDocument1();
    	Test.startTest();
    	// 予約情報を作成する
    	Date curDt = Date.today();
    	Date startDate = Date.newInstance(2016, 9, 29);
    	CommDefine__c comm = TestCommon.createCommDefine();
	    // 商品情報を作成する[5件商品を作成する]
        List<AccountMaster__c> productLst = TestCommon.createProductMst(5);
        comm.RokuyoIsNoShow__c = false;
    	comm.RoomPriceProdName__c = '室料[A]';
    	comm.RoomTypeNewBookingWinVersion__c = 2;
    	update comm;
    	List<AccountMaster__c> productMst = TestCommon.createProductMst(1);
    	productMst[0].name = '室料[A]';
    	productMst[0].ActionType__c = '室料';
    	update productMst;
    	//List<Lead__c> leads1 = TestCommon.createLead(curDt, 3, 2);
    	TypeOfRooms__c typeRoom1 = TestCommon.createTypeOfRoom(10);
		Room__c roomA = TestCommon.createRooms(typeRoom1.Id);
		ShopInformation__c shop = TestCommon.createShopInfo();
		shop.ShopCode__c = '02';
		upsert shop;
		roomA.ShopInfoRef__c = shop.Id;
		upsert roomA;
		//leads1[0].Rroom__c = roomA.Id;
		//upsert leads1;
		Contact con = new Contact(
    		firstName = 'UNIT_TEST_顧客名' + CommUtils.getRandom(6),
    		LastName = 'LASTNAME'+CommUtils.getRandom(6),
    		Katakana__c = 'Katakana__c'+CommUtils.getRandom(10),
    		KanaName1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Name1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Phone = CommUtils.getRandom(10)
    		);
    	insert con;
		Plan__c plan = TestCommon.createPlan();
    	Lead__c item1 = new Lead__c(
    	   RecordTypeId = CommLogicProcess.getLeadBookingRecType(),
    	   name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
    	   Relcontact__c = con.Id,                  // 顧客名
    	   ReservedStatus__c = '確認中',
    	   ReservedDate__c = System.now(),
    	   ReservedContact__c = 'Ono',
    	   EntryTime__c = startDate,
    	   Field4__c = '',
    	   Departure__c = startDate,
    	   Field3__c = '',
    	   StayPersons__c = 4,
    	   Field2__c = 'FAX',
    	   Field310__c = plan.Id,
    	   //LeadIndexRef__c = leadIndex.Id,
    	   Rroom__c = roomA.Id,
    	   refTypeOfRooms__c = roomA.TypeRoomRef__c);
    	   Lead__c item2 = new Lead__c(
    	   RecordTypeId = CommLogicProcess.getLeadBookingRecType(),
    	   name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
    	   Relcontact__c = con.Id,                  // 顧客名
    	   ReservedStatus__c = '確認中',
    	   ReservedDate__c = System.now(),
    	   ReservedContact__c = 'Ono',
    	   EntryTime__c = startDate,
    	   Field4__c = '15:30',
    	   Departure__c = startDate.addDays(1),
    	   Field3__c = '10:00',
    	   StayPersons__c = 4,
    	   Field2__c = 'FAX',
    	   Field310__c = plan.Id,
    	   //LeadIndexRef__c = leadIndex.Id,
    	   Rroom__c = roomA.Id,
    	   refTypeOfRooms__c = roomA.TypeRoomRef__c);
    	insert (new List<Lead__c>{item1, item2});
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'AppSetupConfigXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(getCsvSetupConfig());
    	insert item;
    	// 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'AppSetupConfigXml'].size(), 1);
        // 2015/12/01 Assert END
		RoomScheduleReport ctl = NEW RoomScheduleReport();
		ctl.init();
		ctl.getViewModeList();
		Test.stopTest();
        // 予約
        ctl.contactName = 'GUESTNAME' + CommUtils.getRandom(10);
        ctl.newContact.Katakana__c = CommUtils.getRandom(10);
        ctl.newLead.name = 'LEADNAME' + CommUtils.getRandom(10);
        ctl.newLead.Field2__c = 'テストセル';
        ctl.newLead.StayPersons__c = 1;
        ctl.roomIds = roomA.ID+'_'+typeRoom1.id;
        ctl.newLead.Field310__c = plan.id;
        ctl.staysNums = 2;
        ctl.startDays = Date.today().format();
        //ctl.bookingRooms = 2;
        ctl.newLead.ExtraBedChk__c = false;
        // 予約作成
        ctl.viewMode = '90DAYS';
        ctl.bookingCreate();
		ctl.refreshTypeOfRoomInfo();
		ctl.getRollTimerVal();
		RoomScheduleReport.getAccountMstLstByPlan(productLst[0].field3__c);
		RoomScheduleReport.getArrayProductItemInfoNoPlan(plan.id);
		Map<String,String> infoMap = new Map<String,String>{'viewMode' => ctl.viewMode,'queryDate' => system.today().format(),'expectInfo' => ''};
		RoomScheduleReport.BadRequest rs = RoomScheduleReport.InsertBadRoomExt('abc',JSON.serialize(new List<Map<String,String>>{new Map<String,String>{'rid' => roomA.ID}}),'1',JSON.serialize(new List<Map<String,String>>{infoMap}));
		// System.assertEquals(rs.message, '');
		RoomScheduleReport.InsertBadRoomExt('abc',roomA.ID,'2',JSON.serialize(new List<Map<String,String>>{infoMap}));
		RoomScheduleReport.refreshRoomByLeadId(item1.id,'02',system.today().format(),ctl.viewMode,'4','room');
		RoomScheduleReport.noAssingLeadInfoAll(system.today().format(),'02',true,ctl.viewMode);
		// List<Lead__c> leads1 = TestCommon.createLead(curDt, 3, 2);
		RoomScheduleReport.preUpdateMemoryRoomLeadMap(item1.id,roomA.id,system.today().format(),new List<Lead__c>{item1},new List<Lead__c>(),true);
		RoomScheduleReport.autoCancelAssignRoomToLead(new String[]{item1.id},system.today().format(),false);
		RoomScheduleReport.autoAssignRoomToLead(new String[]{item1.id},roomA.id,startDate.format(),null,null,true);
		RoomScheduleReport.updateLeadMap(item1.id,item1.rroom__c,true,curDt.format());
	}
	
	static testMethod void Case008_CreateLead() {
    	createHolidayXml();
    	createDocument1();
    	Test.startTest();
    	// 予約情報を作成する
    	Date curDt = Date.today();
    	Date startDate = Date.newInstance(2016, 9, 29);
    	CommDefine__c comm = TestCommon.createCommDefine();
	    // 商品情報を作成する[5件商品を作成する]
        List<AccountMaster__c> productLst = TestCommon.createProductMst(5);
        comm.RokuyoIsNoShow__c = false;
    	comm.RoomPriceProdName__c = '室料[A]';
    	comm.RoomTypeNewBookingWinVersion__c = 2;
    	update comm;
    	List<AccountMaster__c> productMst = TestCommon.createProductMst(1);
    	productMst[0].name = '室料[A]';
    	productMst[0].ActionType__c = '室料';
    	update productMst;
    	//List<Lead__c> leads1 = TestCommon.createLead(curDt, 3, 2);
    	TypeOfRooms__c typeRoom1 = TestCommon.createTypeOfRoom(10);
		Room__c roomA = TestCommon.createRooms(typeRoom1.Id);
		ShopInformation__c shop = TestCommon.createShopInfo();
		shop.ShopCode__c = '02';
		upsert shop;
		roomA.ShopInfoRef__c = shop.Id;
		upsert roomA;
		//leads1[0].Rroom__c = roomA.Id;
		//upsert leads1;
		Contact con = new Contact(
    		firstName = 'UNIT_TEST_顧客名' + CommUtils.getRandom(6),
    		LastName = 'LASTNAME'+CommUtils.getRandom(6),
    		Katakana__c = 'Katakana__c'+CommUtils.getRandom(10),
    		KanaName1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Name1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Phone = CommUtils.getRandom(10)
    		);
    	insert con;
		Plan__c plan = TestCommon.createPlan();
    	Lead__c item1 = new Lead__c(
    	   RecordTypeId = CommLogicProcess.getLeadBookingRecType(),
    	   name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
    	   Relcontact__c = con.Id,                  // 顧客名
    	   ReservedStatus__c = '確認中',
    	   ReservedDate__c = System.now(),
    	   ReservedContact__c = 'Ono',
    	   EntryTime__c = startDate,
    	   Field4__c = '',
    	   Departure__c = startDate,
    	   Field3__c = '',
    	   StayPersons__c = 4,
    	   Field2__c = 'FAX',
    	   Field310__c = plan.Id,
    	   //LeadIndexRef__c = leadIndex.Id,
    	   Rroom__c = roomA.Id,
    	   refTypeOfRooms__c = roomA.TypeRoomRef__c);
    	   Lead__c item2 = new Lead__c(
    	   RecordTypeId = CommLogicProcess.getLeadBookingRecType(),
    	   name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
    	   Relcontact__c = con.Id,                  // 顧客名
    	   ReservedStatus__c = '確認中',
    	   ReservedDate__c = System.now(),
    	   ReservedContact__c = 'Ono',
    	   EntryTime__c = startDate,
    	   Field4__c = '15:30',
    	   Departure__c = startDate.addDays(1),
    	   Field3__c = '10:00',
    	   StayPersons__c = 4,
    	   Field2__c = 'FAX',
    	   Field310__c = plan.Id,
    	   //LeadIndexRef__c = leadIndex.Id,
    	   Rroom__c = roomA.Id,
    	   refTypeOfRooms__c = roomA.TypeRoomRef__c);
		insert (new List<Lead__c>{item1, item2});
		String  moreRoomMsg = typeRoom1.id + '_' + curDt.format() + '_' + '10:00' + '_' + curDt.addDays(1).format() + '_' + '15:00' + '_' + roomA.id + ',';
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'AppSetupConfigXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(getCsvSetupConfig());
    	insert item;
    	// 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'AppSetupConfigXml'].size(), 1);
        // 2015/12/01 Assert END
		RoomScheduleReport ctl = NEW RoomScheduleReport();
		ctl.init();
		ctl.getViewModeList();
		Test.stopTest();
        // 予約
        ctl.contactName = 'GUESTNAME' + CommUtils.getRandom(10);
        ctl.newContact.Katakana__c = CommUtils.getRandom(10);
        ctl.newLead.name = 'LEADNAME' + CommUtils.getRandom(10);
        ctl.newLead.Field2__c = 'テストセル';
        ctl.newLead.StayPersons__c = 1;
		ctl.roomIds = roomA.ID + '_' + typeRoom1.id;
		ctl.mainRoomId = roomA.ID;
        ctl.newLead.Field310__c = plan.id;
        ctl.staysNums = 2;
        ctl.startDays = Date.today().format();
        //ctl.bookingRooms = 2;
        ctl.newLead.ExtraBedChk__c = false;
        // 予約作成
		ctl.viewMode = '90DAYS';
		ctl.MoreRoomMessage = moreRoomMsg;
        ctl.bookingCreate();
    }
   
    public static Plan__c createPlanHadHoomZero(String packageCode){
    	JMST__c taxMst =  TestCommon.createTaxMst();
    	if(CommUtils.isBlank(packageCode)) packageCode = '3333';
    	Plan__c plan = new Plan__c();
    	plan.name = '日帰り温泉入浴とレストランでのお食事プラン';
    	plan.PlanNo__c = CommUtils.getRandom(10);
    	plan.Price__c = 11500;
    	plan.PackageCode__c = '80';
    	plan.JmstRef__c = taxMst.Id;
    	insert plan;
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(5);
        productLst[2].Name = CommConst.APPOPTION_ROOMPRICE_PRODNAME;
        productLst[2].ActionType__c = CommConst.PROD_ACTION_TYPE_RP;
        update productLst; 
        
        ApexPages.StandardController contrl = new ApexPages.StandardController(plan);
        PlanProductSetup ctrl = new PlanProductSetup(contrl);
        List<PlanProductSetup.PlanDetail> planDeLst = ctrl.planDetailList;
        planDeLst[0].productNm = productLst[0].Name;
        planDeLst[0].sobj.AccountMasterRef__c = productLst[0].Id;
        planDeLst[0].sobj.Price__c = 1000;
        planDeLst[0].sobj.taxRate__c = taxMst.taxRate__c;
        planDeLst[1].productNm = productLst[1].Name;
        planDeLst[1].sobj.AccountMasterRef__c = productLst[1].Id;
        planDeLst[1].sobj.Price__c = 1500;
        planDeLst[2].productNm = productLst[2].Name;
        planDeLst[2].sobj.AccountMasterRef__c = productLst[2].Id;
        planDeLst[2].sobj.Price__c = 0;
        planDeLst[2].sobj.taxRate__c = taxMst.taxRate__c;
        planDeLst[3].productNm = productLst[3].Name;
        planDeLst[3].sobj.AccountMasterRef__c = productLst[3].Id;
        planDeLst[3].sobj.Price__c = 300;
        planDeLst[3].sobj.taxRate__c = taxMst.taxRate__c;
        planDeLst[4].productNm = productLst[4].Name;
        planDeLst[4].sobj.AccountMasterRef__c = productLst[4].Id;
        planDeLst[4].sobj.Price__c = 500;
        planDeLst[4].sobj.ServiceRate__c = 150;
        planDeLst[4].sobj.taxRate__c = taxMst.taxRate__c;
        ctrl.savePlanDetail();
    	return plan;
    } 
    private static String getCsvSetupConfig() {
    	String csv = '<root><shop><SHOPCODE></SHOPCODE><LEADSTATUSCOLOR>'
    				+'<STATUS><KEY>確定</KEY><COLOR>#C6E2FF</COLOR></STATUS>'
    				+'<STATUS><KEY>確認中</KEY><COLOR>#FFEC8B</COLOR></STATUS>'
    				+'<STATUS><KEY>仮予約</KEY><COLOR>#C1FFC1</COLOR></STATUS>'
    				+'<STATUS><KEY>キャンセルまち</KEY><COLOR>#FF83FA</COLOR></STATUS>'
    				+'</LEADSTATUSCOLOR></shop></root>';
    	return csv; 
    }
    private static void createHolidayXml() {
    	String xml = '<?xml version="1.0" encoding="UTF-8"?><root><year value="2014"><dates label="元日">2014/01/01</dates><dates label="成人の日">2014/01/13</dates><dates label="建国記念の日">2014/02/11</dates><dates label="春分の日">2014/03/21</dates><dates label="昭和の日">2014/04/29</dates><dates label="憲法記念日">2014/05/03</dates><dates label="みどりの日">2014/05/04</dates><dates label="こどもの日">2014/05/05</dates><dates label="振替休日">2014/05/06</dates><dates label="海の日">2014/07/21</dates><dates label="敬老の日">2014/09/15</dates><dates label="秋分の日">2014/09/23</dates><dates label="体育の日">2014/10/13</dates><dates label="文化の日">2014/11/03</dates><dates label="勤労感謝の日">2014/11/23</dates><dates label="振替休日">2014/11/24</dates><dates label="天皇誕生日">2014/12/23</dates></year></root>';
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'HolidayDefineXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(xml);
    	insert item;
		// 2015/12/01 Assert BEGIN
		System.assertEquals([select Id from Document where Name = 'HolidayDefineXml'].size(), 1);
		// 2015/12/01 Assert END
    }
    private static void createDocument(){       
        String documentFileStr = '<?xml version="1.0" encoding="UTF-8"?>'+
                                    '<root><SHOP><VERSION>2.0</VERSION><SHOPCODE></SHOPCODE><FIELDS><SECTION TITLE="11" COLNUM="2">Relcontact__c,refTypeOfRooms__c,Name,EntryTime__c,Relcontact__r.Katakana__c,Field4__c,Relcontact__r.KanaName1__c,Departure__c,Relcontact__r.Phone,Relcontact__r.Fax,Relcontact__r.AssistantName,Relcontact__r.Email,Relcontact__r.Field28__c,Relcontact__r.Usage_Count__c,Relcontact__r.Age__c,Relcontact__r.MailingAddress,Relcontact__r.Birthdate,Relcontact__r.Usage_Charge__c,Relcontact__r.gender__c,Relcontact__r.AccountId,Relcontact__r.Account,$_blank_$</SECTION><SECTION TITLE="22" COLNUM="1">,Rroom__c,Field3__c,StayPersons__c,staysNums,bookingRooms,Field310__c,Field315__c,Field2__c,Segment__c,Comment3__c,CouponTypeLst__c,Mans__c,Femails__c,ChildFA__c  ,Childs__c,ChildC__c,ChildD__c,ReservedType__c,OrgCreateDate__c,OrgUpdateDate__c,Rich2__c,Field276__c,Field302__c,X1y1__c,Field305__c,UnitPriceDefKbCal__c,Salesaccount__c,SearchDate__c,VBChecker__c,ContactEmail__c,ContactPhone__c,Field15__c</SECTION></FIELDS><EXUTEFIELD>Relcontact__r.Kana1__c</EXUTEFIELD></SHOP>'+
                                    '<SHOP><SHOPCODE>01</SHOPCODE><FIELDS>CouponTypeLst__c,Mans__c,Femails__c,ChildFA__c,Childs__c,ChildC__c,ChildD__c,ReservedType__c,OrgCreateDate__c,OrgUpdateDate__c,Rich2__c,Comment3__c,Field276__c,Field302__c,X1y1__c</FIELDS><REQUIREDFIELDS>,Mans__c,Femails__cChildFA__c,Childs__c,ChildC__c,ChildD__c</REQUIREDFIELDS></SHOP>'+
                                    '<SHOP><VERSION>1.0</VERSION><SHOPCODE>02</SHOPCODE><COLNUMS>1</COLNUMS><FIELDS>CouponTypeLst__c,Mans__c,Femails__c,ReservedType__c,OrgCreateDate__c,OrgUpdateDate__c,Rich2__c,Comment3__c,ChildFA__c,Childs__c,ChildC__c,ChildD__c,Field276__c,Field302__c,X1y1__c</FIELDS><REQUIREDFIELDS>CouponTypeLst__c,Mans__c,Femails__c,ReservedType__c,OrgCreateDate__c</REQUIREDFIELDS></SHOP></root>';
        // ドキュメントを作成する
        Document item = new Document();
        item.Name = 'RoomTypeInventoryLeadInputExtendFieldsXml';
        item.DeveloperName = item.Name;
        item.FolderId = UserInfo.getUserId();
        item.Body = Blob.valueOf(documentFileStr);
        getCsvSetupConfig();
        insert item;
    }
    private static void createDocument1(){
        String documentFileStr = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP><VERSION>1.0</VERSION><SHOPCODE>02</SHOPCODE><COLNUMS>1</COLNUMS><FIELDS>CouponTypeLst__c,Mans__c,Femails__c,ReservedType__c,OrgCreateDate__c,OrgUpdateDate__c,Rich2__c,Comment3__c,ChildFA__c,Childs__c,ChildC__c,ChildD__c,Field276__c,Field302__c,X1y1__c</FIELDS><REQUIREDFIELDS>CouponTypeLst__c,Mans__c,Femails__c,ReservedType__c,OrgCreateDate__c</REQUIREDFIELDS></SHOP></root>';
        // ドキュメントを作成する
        Document item = new Document();
        item.Name = 'RoomTypeInventoryLeadInputExtendFieldsXml';
        item.DeveloperName = item.Name;
        item.FolderId = UserInfo.getUserId();
        item.Body = Blob.valueOf(documentFileStr);
        getCsvSetupConfig();
        insert item;
    }
}