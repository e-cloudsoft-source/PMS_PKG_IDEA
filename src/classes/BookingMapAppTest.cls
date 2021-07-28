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
private class BookingMapAppTest {

	static void testCase1() {
		// 予約データの明細情報を変更して、再登録する
    	Test.startTest();
    	createDocument();
    	Room__c roomtest = new Room__c(Name = 'TestRoom', Lat__c = 0, Lng__c = 0, Height__c = 10, Width__c = 10, Seq__c = 1, CapacityHaku__c = 0, Capacity__c = 80, heyadashiryou__c = 20000, heyadashiryouryou__c = 20000);
		Date curDay  = Date.today();
		DateTime startDate = DateTime.newInstance(curDay.addDays(16), Time.newInstance(0, 0, 0, 0));
		// 新規登録
    	Lead__c bookingtest = new Lead__c(	
		   name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
    	   Relcontact__c = createContact().Id,                  // 顧客名
    	   ReservedStatus__c = '確認中',
    	   ReservedDate__c = System.now(),
    	   ReservedContact__c = 'Ono',
    	   EntryTime__c = startDate,
    	   Field4__c = '15:30',
    	   Departure__c = startDate.addDays(1),
    	   Field3__c = '10:00',
    	   StayPersons__c = 4,
    	   Field2__c = 'FAX',
    	   Rroom__c = roomtest.Id);
		insert bookingtest;
    	BookingPlus__c bptest = new BookingPlus__c(Checkinday__c = bookingtest.EntryTime__c.date());
		insert bptest;
    	Room__c guestRoom = TestCommon.createRooms();
    	BookingMapApp app = new BookingMapApp();
    	app.refreshMode = 'futu';
    	// 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
        String idxName = [select LeadIndexRef__r.Name from Lead__c where id = :leadInfo.Id].LeadIndexRef__r.Name;
        List<LeadIndex__c> leadIdxLst = [select id from LeadIndex__c where name = :idxName];
    	//app.refreshMessage();
    	//app.chgSaveNightsInfo();
    	//app.checkOutByRoom();
    	app.gotoDate();
    	Test.stopTest();
	}
      // 予約新規登録機能
    static testmethod void createLeadTest() {
      CommDefine__c comm = TestCommon.createCommDefine();
      comm.RoomPriceProdName__c = '室料[A]';
      comm.IotStatusManagerFlg__c = true;
      update comm;
      // 2019/04/15 BY zyz BEGIN
      createDocument1();
      // 2019/04/15 BY zyz END
      insert new MessageInformation__c(MessageType__c = 'IOT', MessageLevel__c = 'Info',MessageSub1__c='1');
      
      List<AccountMaster__c> productMst = TestCommon.createProductMst(1);
      productMst[0].name = '室料[A]';
      productMst[0].ActionType__c = '室料';
      update productMst;
      TypeOfRooms__c typeItem = new TypeOfRooms__c(
            Name = 'S1' + CommUtils.getRandom(10),
            RoomTypeCode__c = '3',
            MaxRooms__c = 99);
        insert typeItem;
	  Room__c roomItem = new Room__c(
    		Name = 'N2491',
    		CapacityHaku__c = 4,
    		Capacity__c = 2,
    		Area__c = '本館',
    		Floor__c = '1F',
    		UseOfRoom__c = '客室',
    		heyadashiryouryou__c = 40000,
    		TypeRoomRef__c = typeItem.Id,
    		heyadashiryou__c = 25000);
		insert roomItem;
      createDocument();
      // 2015/12/01 Assert BEGIN
    System.assertEquals([select Id from Document where Name = 'RoomIndicatorMapConfig'].size(), 1);
    // 2015/12/01 Assert END
      // 到着日
      String startDt = system.now().format('yyyy/MM/dd');
      // お客様情報を設定する
      Contact guest = TestCommon.createContact();
      // 部屋、部屋タイプ作成する
      Room__c room = TestCommon.createRooms();
      // Daynmic設定情報を取得する
      BookingMapApp indicator = new BookingMapApp();
      String dt = indicator.strToday;
      boolean flag001 = indicator.isShowGroupConfirm;
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
      // 2019/04/15 BY zyz BEGIN
      BookingMapApp.noAssingLeadInfoAll(startDt,'02',true);
      // 2019/04/15 BY zyz END
     //newLead.
      Test.startTest();
      //indicator.bookingCreate();
      indicator.staysNums = 0;
      //indicator.bookingCreate();
      indicator.staysNums = 2;
      //indicator.bookingCreate();
      Test.stopTest();
    }
	// zyz BEGIN
	static testMethod void chgSaveNightsInfoTest1() {
		createDocument();
		//Date startDate = Date.today();
		//List<Lead__c> leads = TestCommon.createLead(startDate, 2, 2);
		//lead__c lead = leads[0];
		Room__c roomtest = new Room__c(Name = 'TestRoom', Lat__c = 0, Lng__c = 0, Height__c = 10, Width__c = 10, Seq__c = 1, CapacityHaku__c = 0, Capacity__c = 80, heyadashiryou__c = 20000, heyadashiryouryou__c = 20000);
		Date curDay  = Date.today();
		DateTime startDate = DateTime.newInstance(curDay.addDays(16), Time.newInstance(0, 0, 0, 0));
		// 新規登録
		Lead__c leads = new Lead__c(	
		   name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
		   Relcontact__c = createContact().Id,                  // 顧客名
		   ReservedDate__c = System.now(),
		   ReservedContact__c = 'Ono',
		   EntryTime__c = startDate,
		   Field4__c = '15:30',
		   Departure__c = startDate.addDays(1),
		   Field3__c = '10:00',
		   StayPersons__c = 4,
		   Field2__c = 'FAX',
		   Rroom__c = roomtest.Id,
		   LeadIndexSubId__c = null);
		insert leads;
		// 2015/12/01 Assert BEGIN
		//System.assertEquals(leads.size(), 4);
		// 2015/12/01 Assert END
		// 部屋アサインする
		// 予約データを作成する
		//String leadId = leads.Id;
		BookingMapApp indicator = new BookingMapApp();
		//indicator.toToday();
		//indicator.strToday();
		indicator.strLeadId = leads.Id;
		String strToday = indicator.strToday;
    	//indicator.toToday();
		//indicator.leadInfo = BookingMapApp.getRoomInfo(leads.rroom__c, indicator.strLeadId);
		Test.startTest();
		indicator.getBookingData();
		indicator.getRoomData();
		indicator.getbooking();
		indicator.refreshBranShop();
		//indicator.getDefTier();
		//indicator.changeLeadName();
		indicator.getfixedday();
		indicator.getRecordId();
		//indicator.bookingCreate();
		indicator.isGroupFlg = true;
		indicator.refreshMode = 'futu';
		// 予約情報を作成する
		Lead__c leadInfo = TestCommon.createLead();
		String idxName = [select LeadIndexRef__r.Name from Lead__c where id = :leadInfo.Id].LeadIndexRef__r.Name;
		List<LeadIndex__c> leadIdxLst = [select id from LeadIndex__c where name = :idxName];
		//indicator.strLeadId = leadId;
		//indicator.groupLeadIds = leadId + ',';
		//indicator.strLeadId = leadInfo.id;
		//indicator.refreshMessage();
		//indicator.checkInByRoom();
		//indicator.checkOutByRoom();
		Test.stopTest();
	}
	// 予約新規登録機能
	static testmethod void createLeadTest1() {
		CommDefine__c comm = TestCommon.createCommDefine();
		comm.RoomPriceProdName__c = '室料[A]';
		update comm;
		List<AccountMaster__c> productMst = TestCommon.createProductMst(1);
		productMst[0].name = '室料[A]';
		productMst[0].ActionType__c = '室料';
		update productMst;
		
		createDocument();
		// 2015/12/01 Assert BEGIN
		System.assertEquals([select Id from Document where Name = 'RoomIndicatorMapConfig'].size(), 1);
		// 2015/12/01 Assert END
		// 到着日
		String startDt = system.now().format('yyyy/MM/dd');
		// お客様情報を設定する
		Contact guest = TestCommon.createContact();
		// 部屋、部屋タイプ作成する
		Room__c room = TestCommon.createRooms();
		// Daynmic設定情報を取得する
		BookingMapApp indicator = new BookingMapApp();
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
		newLead.StayPersons__c = null;
		newLead.Field2__c = '電話';
		newLead.Field298__c = 'チェックイン完';
		Test.startTest();
		//indicator.bookingCreate();
		Test.stopTest();
    }
	static testmethod void testCase2() {
		// 予約データの明細情報を変更して、再登録する
		Test.startTest();
		createDocument();
		Room__c roomtest = new Room__c(Name = 'TestRoom', Lat__c = 0, Lng__c = 0, Height__c = 10, Width__c = 10, Seq__c = 1, CapacityHaku__c = 0, Capacity__c = 80, heyadashiryou__c = 20000, heyadashiryouryou__c = 20000);
		Date curDay  = Date.today();
		DateTime startDate = DateTime.newInstance(curDay.addDays(16), Time.newInstance(0, 0, 0, 0));
		// 新規登録
		Lead__c bookingtest = new Lead__c(	
			name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
			Relcontact__c = createContact().Id,                  // 顧客名
			ReservedStatus__c = '確認中',
			ReservedDate__c = System.now(),
			ReservedContact__c = 'Ono',
			EntryTime__c = startDate,
			Field4__c = '15:30',
			Departure__c = startDate.addDays(1),
			Field3__c = '10:00',
			StayPersons__c = 4,
			Field2__c = 'FAX',
			Rroom__c = roomtest.Id);
		insert bookingtest;
		BookingPlus__c bptest = new BookingPlus__c(Checkinday__c = bookingtest.EntryTime__c.date());
		insert bptest;
		String leadId = bookingtest.Id;
		Room__c guestRoom = TestCommon.createRooms();
		BookingMapApp app = new BookingMapApp();
		app.refreshMode = 'futu';
		// 予約情報を作成する
		Lead__c leadInfo = TestCommon.createLead();
		leadInfo.Field298__c = 'チェックイン完';
		Test.stopTest();
		String idxName = [select LeadIndexRef__r.Name from Lead__c where id = :leadInfo.Id].LeadIndexRef__r.Name;
		List<LeadIndex__c> leadIdxLst = [select id from LeadIndex__c where name = :idxName];
		app.strLeadId = leadId;
    	app.groupLeadIds = leadId + ',';
		//app.refreshMessage();
		//app.chgSaveNightsInfo();
		//app.isGroupFlg = true;
		//app.checkInByRoom();
		//app.checkOutByRoom();
	}
	static testmethod void testCase3() {
		// 予約データの明細情報を変更して、再登録する
		Test.startTest();
		createDocument();
		Room__c roomtest = new Room__c(Name = 'TestRoom', Lat__c = 0, Lng__c = 0, Height__c = 10, Width__c = 10, Seq__c = 1, CapacityHaku__c = 0, Capacity__c = 80, heyadashiryou__c = 20000, heyadashiryouryou__c = 20000);
		Date curDay  = Date.today();
		DateTime startDate = DateTime.newInstance(curDay.addDays(16), Time.newInstance(0, 0, 0, 0));
		// 新規登録
		Lead__c bookingtest = new Lead__c(	
			name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
			Relcontact__c = createContact().Id,                  // 顧客名
			ReservedStatus__c = '確認中',
			ReservedDate__c = System.now(),
			ReservedContact__c = 'Ono',
			EntryTime__c = startDate,
			Field4__c = '15:30',
			Departure__c = startDate.addDays(1),
			Field3__c = '10:00',
			StayPersons__c = 4,
			Field2__c = 'FAX',
			Rroom__c = roomtest.Id);
		insert bookingtest;
		BookingPlus__c bptest = new BookingPlus__c(Checkinday__c = bookingtest.EntryTime__c.date());
		insert bptest;
		String leadId = bookingtest.Id;
		Room__c guestRoom = TestCommon.createRooms();
		BookingMapApp app = new BookingMapApp();
		app.refreshMode = 'main';
		// 予約情報を作成する
		Lead__c leadInfo = TestCommon.createLead();
		leadInfo.Field298__c = 'チェックイン完' ;
		leadInfo.EntryTime__c = startDate ;
		Test.stopTest();
		String idxName = [select LeadIndexRef__r.Name from Lead__c where id = :leadInfo.Id].LeadIndexRef__r.Name;
		List<LeadIndex__c> leadIdxLst = [select id from LeadIndex__c where name = :idxName];
		//app.strLeadId = leadId;
    	//app.groupLeadIds = leadId + ',';
    	app.strLeadId = leadInfo.id;
    	app.groupLeadIds = leadInfo.id + ',';
		//app.refreshMessage();
		//app.chgSaveNightsInfo();
		//app.isGroupFlg = true;
		//app.checkInByRoom();
		//app.checkOutByRoom();
	}
	static testMethod void chgSaveNightsInfoTest2() {
		createDocument();
		createDocument1();
		Date startDate = Date.today();
		// 2019/04/15 BY zyz BEGIN
    	TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
    	List<Room__c> createRooms = TestCommon.createRooms(3, typeOfRoom.Id);
    	// 2019/04/15 BY zyz END
		List<Lead__c> leads = TestCommon.createLead(startDate, 2, 2);
		lead__c lead = leads[0];
		// 2019/04/15 BY zyz BEGIN
		ExchangeRate__c rate = TestCommon.createExchangeRate(CommBaseCtrl.getCurrency(),'JPY');
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
    	// 見積明細を作成する
    	TestCommon.createBookEstItem(lead, productLst[0]);
    	// 予約情報のステータス：チェックインに変更する
    	lead.rRoom__c = createRooms[0].Id;
    	lead.Field298__c = 'チェックイン完';
    	update lead;
    	List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :lead.Id];
    	AccountAcount__c accObj = accObjLst[0];
    	accObj.Field53__c = '20190325142911';
    	update accObj;
    	// 2019/04/15 BY zyz END
		//Room__c roomtest = new Room__c(Name = 'TestRoom', Lat__c = 0, Lng__c = 0, Height__c = 10, Width__c = 10, Seq__c = 1, CapacityHaku__c = 0, Capacity__c = 80, heyadashiryou__c = 20000, heyadashiryouryou__c = 20000);
		//Date curDay  = Date.today();
		//DateTime startDate = DateTime.newInstance(curDay.addDays(16), Time.newInstance(0, 0, 0, 0));
		// 新規登録
		/*
		Lead__c leads = new Lead__c(	
		   name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
		   Relcontact__c = createContact().Id,                  // 顧客名
		   ReservedStatus__c = '確認中',
		   ReservedDate__c = System.now(),
		   ReservedContact__c = 'Ono',
		   EntryTime__c = startDate,
		   Field4__c = '15:30',
		   Departure__c = startDate.addDays(1),
		   Field3__c = '10:00',
		   StayPersons__c = 4,
		   Field2__c = 'FAX',
		   Rroom__c = roomtest.Id,
		   LeadIndexSubId__c = null);
		insert leads;*/
		// 2015/12/01 Assert BEGIN
		//System.assertEquals(leads.size(), 4);
		// 2015/12/01 Assert END
		// 部屋アサインする
		// 予約データを作成する　
		String leadId = lead.Id;
		BookingMapApp indicator = new BookingMapApp();
		//indicator.toToday();
		//indicator.strToday();
		// 2019/04/15 BY zyz BEGIN
		//indicator.strLeadId = leads[0].Id;
		indicator.strLeadId = lead.Id;
		// 2019/04/15 BY zyz END
		String strToday = indicator.strToday;
    	//indicator.toToday();
    	// 2019/04/15 BY zyz BEGIN
		//indicator.leadInfo = BookingMapApp.getRoomInfo(leads[0].rroom__c, indicator.strLeadId);
		indicator.leadInfo = BookingMapApp.getRoomInfo(lead.rroom__c, indicator.strLeadId);
		// 2019/04/15 BY zyz END
		Test.startTest();
		indicator.getBookingData();
		indicator.getRoomData();
		indicator.getbooking();
		indicator.refreshBranShop();
		indicator.getfixedday();
		indicator.getRecordId();
		//indicator.bookingCreate();
		indicator.isGroupFlg = true;
		indicator.refreshMode = 'futu';
		// 予約情報を作成する
		Lead__c leadInfo = TestCommon.createLead();
		String idxName = [select LeadIndexRef__r.Name from Lead__c where id = :leadInfo.Id].LeadIndexRef__r.Name;
		List<LeadIndex__c> leadIdxLst = [select id from LeadIndex__c where name = :idxName];
		indicator.strLeadId = leadId;
    	indicator.groupLeadIds = leadId + ',';
		Test.stopTest();
	}
	static testMethod void chgSaveNightsInfoTest3() {
		createDocument();
		Date startDate = Date.today();
		List<Lead__c> leads = TestCommon.createLead(startDate, 2, 2);
		lead__c lead = leads[0];
		lead.Rroom__c = null;
		//Room__c roomtest = new Room__c(Name = 'TestRoom', Lat__c = 0, Lng__c = 0, Height__c = 10, Width__c = 10, Seq__c = 1, CapacityHaku__c = 0, Capacity__c = 80, heyadashiryou__c = 20000, heyadashiryouryou__c = 20000);
		//Date curDay  = Date.today();
		//DateTime startDate = DateTime.newInstance(curDay.addDays(16), Time.newInstance(0, 0, 0, 0));
		// 新規登録
		/*
		Lead__c leads = new Lead__c(	
		   name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
		   Relcontact__c = createContact().Id,                  // 顧客名
		   ReservedStatus__c = '確認中',
		   ReservedDate__c = System.now(),
		   ReservedContact__c = 'Ono',
		   EntryTime__c = startDate,
		   Field4__c = '15:30',
		   Departure__c = startDate.addDays(1),
		   Field3__c = '10:00',
		   StayPersons__c = 4,
		   Field2__c = 'FAX',
		   Rroom__c = roomtest.Id,
		   LeadIndexSubId__c = null);
		insert leads;*/
		// 2015/12/01 Assert BEGIN
		//System.assertEquals(leads.size(), 4);
		// 2015/12/01 Assert END
		// 部屋アサインする
		// 予約データを作成する　
		String leadId = lead.Id;
		BookingMapApp indicator = new BookingMapApp();
		//indicator.toToday();
		//indicator.strToday();
		indicator.strLeadId = leads[0].Id;
		String strToday = indicator.strToday;
    	//indicator.toToday();
		//indicator.leadInfo = BookingMapApp.getRoomInfo(leads[0].rroom__c, indicator.strLeadId);
		Test.startTest();
		indicator.getBookingData();
		indicator.getRoomData();
		indicator.getbooking();
		indicator.refreshBranShop();
		indicator.getfixedday();
		indicator.getRecordId();
		//indicator.bookingCreate();
		indicator.isGroupFlg = true;
		indicator.refreshMode = 'futu';
		// 予約情報を作成する
		Lead__c leadInfo = TestCommon.createLead();
		String idxName = [select LeadIndexRef__r.Name from Lead__c where id = :leadInfo.Id].LeadIndexRef__r.Name;
		List<LeadIndex__c> leadIdxLst = [select id from LeadIndex__c where name = :idxName];
		indicator.strLeadId = leadId;
    	indicator.groupLeadIds = leadId + ',';
		//indicator.refreshMessage();
		Test.stopTest();
	}
	// zyz END
    public static Contact createContact() {
    	Contact item = new Contact(
    		firstName = 'UNIT_TEST_顧客名' + System.now(),
    		LastName = 'LASTNAME');
    	insert item;
    	return item;
    }
    private static void createDocument(){
    	String documentFileStr = '<?xml version="1.0" encoding="UTF-8"?><ROOT><SHOP><SHOPCODE></SHOPCODE><MAPROOTPATH>jinya_map</MAPROOTPATH><MAPSUBPATH>jinya-tiles</MAPSUBPATH></SHOP></ROOT>';
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'RoomIndicatorMapConfig';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(documentFileStr);
    	insert item;
    }
     private static void createDocument1(){       
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
        insert item;
    }
}