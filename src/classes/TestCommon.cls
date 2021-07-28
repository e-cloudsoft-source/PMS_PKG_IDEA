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
public class TestCommon {
	
	public static CommDefine__c createCommDefine() {
		delete [select id from CommDefine__c];
		CommDefine__c newDef = new CommDefine__c(
	    	RoomTypeReport__c = '$0001 客室タイプ別予約表',
	    	Posreg__c = '0',
	    	UnitPriceDefKb__c = 2,
	    	// 2018/03/21 App NameSpace BEGIN
	    	AppNS__c = 'ps__',
	    	// 2018/03/21 App NameSpace END
	    	ScheduleResultMailAddress__c = '1@a.com,2@b.com,3@c.com,4@d.com,5@e.com,6@f.com',
			RoomIndicatorInfoMaxLength__c = 4,
			RoomSortDiv__c = '1',
			BookingMansDef__c = 1,
			BookingFemailsDef__c = 0,
			BookingChildrenDef__c = 0,
			StockDataCreateFlg__c = false
			,GuestRooms__c = 20
		);	
		insert newDef;
		return newDef;
	}
	public static FreeeSeting__c createFreeeSeting() {
		delete [select id from FreeeSeting__c];
		FreeeSeting__c newFreee = new FreeeSeting__c(
			OffsetVal__c = 1,
			DisplayName__c  = 'testfreee',
			DeveloperName__c = 'freee/1'
		);
		insert newFreee;
		return newFreee;
	}
	// キャンセルルール規則
	public static list<CancelRuleDefine__c> createCancelRuleDefine(String shopCode) {
		delete [select id from CancelRuleDefine__c];
		list<CancelRuleDefine__c> insLst = new list<CancelRuleDefine__c>();
		CancelRuleDefine__c newItem1 = new CancelRuleDefine__c(
			Name = 'キャンセル料金_'+CommUtils.getRandom(10),
			RuleBefDayNums__c = 0,
			CancelRate__c = 100,
			ShopCode__c = shopCode
		);
		CancelRuleDefine__c newItem2 = new CancelRuleDefine__c(
			Name = 'キャンセル料金_'+CommUtils.getRandom(10),
			RuleBefDayNums__c = 1,
			CancelRate__c = 80,
			ShopCode__c = shopCode
		);
		CancelRuleDefine__c newItem3 = new CancelRuleDefine__c(
			Name = 'キャンセル料金_'+CommUtils.getRandom(10),
			RuleBefDayNums__c = 2,
			CancelRate__c = 50,
			ShopCode__c = shopCode
		);
		CancelRuleDefine__c newItem4 = new CancelRuleDefine__c(
			Name = 'キャンセル料金_'+CommUtils.getRandom(10),
			RuleBefDayNums__c = 3,
			CancelRate__c = 30,
			ShopCode__c = shopCode
		);
		CancelRuleDefine__c newItem5 = new CancelRuleDefine__c(
			Name = 'キャンセル料金_'+CommUtils.getRandom(10),
			RuleBefDayNums__c = 4,
			CancelRate__c = 20,
			ShopCode__c = shopCode
		);
		insLst.add(newItem1);
		insLst.add(newItem2);
		insLst.add(newItem3);
		insLst.add(newItem4);
		insLst.add(newItem5);
		insert insLst;
		return insLst;
	}
    // 売上情報を作成する
    public static RsvAccount__c createRsvAccount() {
    	RsvAccount__c item = new RsvAccount__c();
    	item.name = '20120101';
    	insert item;
    	return item;
    }
    // 仕入[調理]
    public static Purchase__c createPurchase() {
    	Purchase__c item = new Purchase__c();
    	item.JinyaRevenue__c = createRsvAccount().id;
    	item.Denpyoukei__c = 12000;
    	insert item;
    	return item;
    }
    // 取引先情報（旅行会社）
    public static Account createTravelCompany () {
    	Account newItem = new Account(
    		Name = '旅行会社_' + CommUtils.getRandom(10),
    		SalesOfficeCompanyCode__c = CommUtils.getRandom(10),
    		AccountType__c = '旅行会社',
    		ContractStatus__c = '有効',
    		SalesOfficeCompanyType__c = '旅行会社'
    	);
    	insert newItem;
    	return newItem;
    }
    public static Account createNormalAccount() {
    	Account newItem = new Account(
    		Name = 'テスト会社' + CommUtils.getRandom(10),
    		Phone= CommUtils.getRandom(10),
    		Fax  = CommUtils.getRandom(10)
    	);
    	insert newItem;
    	return newItem;
    }
    public static Lead__c createLead() {
    	Date curDay  = Date.today();
    	return createLead(curDay);
    }
    // 開始日により、Ｎ部屋Ｎ泊の予約データを作成する
    public static List<Lead__c> createLead(Date startDt, Integer rooms, Integer nights, Id pGuestId) {
		//Contact guest = pGuest;
		TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
		Plan__c plan = createPlan();
		List<Room__c> createRooms = createRooms(rooms, typeOfRoom.Id);
		Integer loopNights = nights == 0 ? 1 :nights;
		// 新規登録
		LeadIndex__c sobj = new LeadIndex__c();
    	ApexPages.StandardController contrl = new ApexPages.StandardController(sobj);
    	BookingApp app = new BookingApp(contrl);
    	
		app.leadBaseInf.s.EntryDate__c =startDt;
		app.leadBaseInf.s.EntryTime__c = '16:00';
		app.leadBaseInf.s.Nights__c = nights;
		app.leadBaseInf.s.DepartureDate__c = app.leadBaseInf.s.EntryDate__c.addDays(nights);
		app.leadBaseInf.s.DepartureTime__c = '10:30';
        // 顧客情報を更新を行う
 		app.leadBaseInf.contactName = 'UNAME' + Crypto.getRandomLong();
 		app.leadBaseInf.l.Field2__c = '本社';
 		app.leadBaseInf.l.Segment__c = 'CARD';
        app.leadBaseInf.accoutName = 'ACC-NEW' + CommUtils.getRandom(10);
		app.leadBaseInf.s.contactRef__c = pGuestId;
		app.leadBaseInf.s.LeadName__c = 'テストケースの予約名';
		app.leadBaseInf.s.Comment__c = 'Comment_'+ CommUtils.getRandom(10);
		
		BookingApp.LeadItem subItem = app.oLeadLst[0];
		subItem.s.EntryDate__c = app.leadBaseInf.s.EntryDate__c;
		subItem.nights = String.valueOf(app.leadBaseInf.s.Nights__c);
		subItem.s.DepartureDate__c = app.leadBaseInf.s.DepartureDate__c;
		subItem.s.RoomTypeRef__c = typeOfRoom.Id;
		subItem.persons = String.valueOf(1);
		subItem.rooms = String.valueOf(rooms);
		subItem.s.PlanRef__c = plan.Id;
		// １件予約データを作成する
 		app.createLeadInfo();
 		// 部屋アサインする
 		List<Lead__c> newLeads = [select Id, Relcontact__c,Rroom__c,EntryTime__c,Departure__c,Field298__c,LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c 
 														from lead__c where LeadIndexRef__c = :app.leadBaseInf.s.Id
 														Order By EntryTime__c, RoomGroupNo__c];
    	for (Integer i=0; i<rooms; i++) {
    		for (Integer j=0; j<loopNights; j++) {
    				newLeads[(i*loopNights) + j].Rroom__c = createRooms[i].Id;
    		}
    	}
    	update newLeads;
   		return newLeads;
    }
    
    // 開始日により、Ｎ部屋Ｎ泊の予約データを作成する
    public static List<Lead__c> createLead2IncRoomRate(Date startDt, Integer rooms, Integer nights, Plan__c pplan) {
		//Contact guest = pGuest;
		Contact guest = TestCommon.createContact();
		Id pGuestId = guest.Id;
		TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
		Plan__c plan = (pplan == null ? createPlanIncRoom() : pplan);
system.debug(loggingLevel.info, 'PALN-DETAIL='+[select id,name,Price__c from PlanDetail__c where PlanRef__c = :plan.iD]);
		List<Room__c> createRooms = createRooms(rooms, typeOfRoom.Id);
		Integer loopNights = nights == 0 ? 1 :nights;
		// 新規登録
		LeadIndex__c sobj = new LeadIndex__c();
    	ApexPages.StandardController contrl = new ApexPages.StandardController(sobj);
    	BookingApp app = new BookingApp(contrl);
    	
		app.leadBaseInf.s.EntryDate__c =startDt;
		app.leadBaseInf.s.EntryTime__c = '16:00';
		app.leadBaseInf.s.Nights__c = nights;
		app.leadBaseInf.s.DepartureDate__c = app.leadBaseInf.s.EntryDate__c.addDays(nights);
		app.leadBaseInf.s.DepartureTime__c = '10:30';
        // 顧客情報を更新を行う
 		app.leadBaseInf.contactName = 'UNAME' + Crypto.getRandomLong();
 		app.leadBaseInf.l.Field2__c = '本社';
 		app.leadBaseInf.l.Segment__c = 'CARD';
        app.leadBaseInf.accoutName = 'ACC-NEW' + CommUtils.getRandom(10);
		app.leadBaseInf.s.contactRef__c = pGuestId;
		app.leadBaseInf.s.LeadName__c = 'テストケースの予約名';
		app.leadBaseInf.s.Comment__c = 'Comment_'+ CommUtils.getRandom(10);
		
		BookingApp.LeadItem subItem = app.oLeadLst[0];
		subItem.s.EntryDate__c = app.leadBaseInf.s.EntryDate__c;
		subItem.nights = String.valueOf(app.leadBaseInf.s.Nights__c);
		subItem.s.DepartureDate__c = app.leadBaseInf.s.DepartureDate__c;
		subItem.s.RoomTypeRef__c = typeOfRoom.Id;
		subItem.persons = String.valueOf(1);
		subItem.rooms = String.valueOf(rooms);
		subItem.s.PlanRef__c = plan.Id;
		// １件予約データを作成する
 		app.createLeadInfo();
 		// 部屋アサインする
 		List<Lead__c> newLeads = [select Id, Relcontact__c,Rroom__c,EntryTime__c,Departure__c,Field298__c,LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c 
 														from lead__c where LeadIndexRef__c = :app.leadBaseInf.s.Id
 														Order By EntryTime__c, RoomGroupNo__c];
 System.debug(LoggingLevel.INFO, 'newLeads::::'  +newLeads);
    	for (Integer i=0; i<rooms; i++) {
    		for (Integer j=0; j<loopNights; j++) {
    				newLeads[(i*loopNights) + j].Rroom__c = createRooms[i].Id;
    		}
    	}
    	update newLeads;
   		return newLeads;
    }
    
    // 開始日により、Ｎ部屋Ｎ泊の予約データを作成する
    public static List<Lead__c> createLead(Date startDt, Integer rooms, Integer nights) {
    	Contact guest = TestCommon.createContact();
    	return createLead(startDt, rooms, nights, guest.Id);
    }
    // 宴会場情報作成する
    public static Lead__c createEnkaiLead(Date entryDate, Id roomId) {
    	Date curDay = entryDate == null ? Date.today() : entryDate;
    	DateTime startDate = DateTime.newInstance(curDay, Time.newInstance(0, 0, 0, 0));
    	// 連泊データを自動作成
    	Lead__c item1 = new Lead__c(
    	   RecordTypeId = CommLogicProcess.getLeadEnkaiRecType(),
    	   name = '予約単体テスト_宴会場' + System.now(), // 予約名
    	   Relcontact__c = createContact().Id,                  // 顧客名
    	   ReservedStatus__c = '確認中',
    	   ReservedDate__c = System.now(),
    	   ReservedContact__c = 'Ono',
    	   EntryTime__c = startDate,
    	   Field4__c = '10:00',
    	   Departure__c = startDate,
    	   Field3__c = '16:00',
    	   StayPersons__c = 4,
    	   Field2__c = 'FAX',
    	   Rroom__c = roomId);
    	insert item1;
    	return item1;
    }
    // 予約情報作成する
    public static Lead__c createBookingLead(Date entryDate, Id roomTypeId, Integer nights) {
    	Lead__c item1 = new Lead__c(
    	   RecordTypeId = CommLogicProcess.getLeadBookingRecType(),
    	   name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
    	   Relcontact__c = createContact().Id,                  // 顧客名
    	   ReservedStatus__c = '確認中',
    	   ReservedDate__c = System.now(),
    	   ReservedContact__c = 'Ono',
    	   EntryTime__c = entryDate,
    	   Field4__c = '15:30',
    	   Departure__c = entryDate.addDays(nights),
    	   Field3__c = (nights > 0 ? '10:00' : '19:00'),
    	   StayPersons__c = 1,
    	   Field2__c = 'FAX',
    	   refTypeOfRooms__c = roomTypeId);
    	insert item1;
    	return item1;
    }
    // 予約情報を作成する
    public static Lead__c createLead(Date entryDate) {
    	Date curDay = entryDate == null ? Date.today() : entryDate;
    	//DateTime startDate = DateTime.newInstance(curDay.addDays(10), Time.newInstance(0, 0, 0, 0));
    	DateTime startDate = DateTime.newInstance(curDay, Time.newInstance(0, 0, 0, 0));
    	//LeadIndex__c leadIndex = createLeadIndex(3, startDate, startDate.addDays(1));
    	Room__c room = TestCommon.createRooms();
    	// 連泊データを自動作成
    	Lead__c item1 = new Lead__c(
    	   RecordTypeId = CommLogicProcess.getLeadBookingRecType(),
    	   name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
    	   Relcontact__c = createContact().Id,                  // 顧客名
    	   ReservedStatus__c = '確認中',
    	   ReservedDate__c = System.now(),
    	   ReservedContact__c = 'Ono',
    	   EntryTime__c = startDate.addDays(-1),
    	   Field4__c = '15:30',
    	   Departure__c = startDate,
    	   Field3__c = '10:00',
    	   StayPersons__c = 4,
    	   Field2__c = 'FAX',
    	   Field310__c = createPlan().Id,
    	   //LeadIndexRef__c = leadIndex.Id,
    	   Rroom__c = room.Id,
    	   refTypeOfRooms__c = room.TypeRoomRef__c);
    	Lead__c item2 = new Lead__c(
    	   RecordTypeId = CommLogicProcess.getLeadBookingRecType(),
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
    	   Field310__c = createPlan().Id,
    	   //LeadIndexRef__c = leadIndex.Id,
    	   Rroom__c = room.Id,
    	   refTypeOfRooms__c = room.TypeRoomRef__c);
    	insert (new List<Lead__c>{item1, item2});
    	return item2;
    }
    public static LeadIndex__c createLeadIndex(Integer nights, DateTime s, DateTime e ) {
    	LeadIndex__c item = new LeadIndex__c(
    		ID__c = String.valueOf(Math.random()),
    		Nights__c = nights,
     		EntryTime__c = '10:00',
    		EntryDate__c = s.date(),
    		DepartureTime__c = '15:30',
    		DepartureDate__c = e.date(),
			EventSource__c = 'テストクラスから',
			Rooms__c = 1
    	);
    	insert item;
    	return item;
    }
    public static Contact createContact() {
    	Contact item = new Contact(
    		firstName = 'UNIT_TEST_顧客名' + CommUtils.getRandom(6),
    		LastName = 'LASTNAME'+CommUtils.getRandom(6),
    		Katakana__c = 'Katakana__c'+CommUtils.getRandom(10),
    		KanaName1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Name1__c = 'KanaName1__c'+CommUtils.getRandom(10),
			Phone = CommUtils.getRandom(10)
			,Email = '123' + CommUtils.getRandom(6) + '@222.com'
    		);
    	insert item;
    	return item;
    }

    public static Room__c createRooms() {
    	Room__c item = new Room__c(
    		Name = '部屋テスト' + CommUtils.getRandom(6),
    		CapacityHaku__c = 4,
    		Capacity__c = 2,
    		Area__c = '本館',
    		Floor__c = '1F',
    		UseOfRoom__c = '客室',
    		heyadashiryouryou__c = 40000,
    		TypeRoomRef__c = createTypeOfRoom().Id,
    		heyadashiryou__c = 25000);
		insert item;
		return item;
    }
    // 宴会場部屋情報を作成する
    public static Room__c createEnkaiRooms() {
    	Room__c item = new Room__c(
    		Name = '部屋宴会場テスト' + CommUtils.getRandom(6),
    		CapacityHaku__c = 4,
    		Capacity__c = 2,
    		Area__c = '本館',
    		Floor__c = '1F',
    		UseOfRoom__c = CommConst.ROOM_UseOfType_PTY,
    		heyadashiryouryou__c = 40000,
    		heyadashiryou__c = 25000);
		insert item;
		return item;
    }
    // Tier情報設定を行う
    public static RackRateTable__c createRaceRateInfo (Id roomTypeId, String tier, String peos) {
    	String key = tier + '_' + roomTypeId + '_' + peos;
    	RackRateTable__c raceRate = new RackRateTable__c(
    		Tier__c = tier,
    		Price__c = 1000,
    		Persons__c = peos,
    		RoomTypeRel__c = roomTypeId,
    		SearchKey__c = key
    	);
    	insert raceRate;
    	return raceRate;
    }
    
    public static List<Room__c> createRooms(Integer roomNums, Id roomTypeId) {
    	List<Room__c> newRooms = new List<Room__c>();
System.debug(LoggingLevel.INFO, 'roomTypeId1:::' + roomTypeId);
    	roomTypeId =( roomTypeId == null ? createTypeOfRoom().Id  : roomTypeId );
System.debug(LoggingLevel.INFO, 'roomTypeId2:::' + roomTypeId);
    	for (Integer i= 0; i<roomNums; i++) {
    		newRooms.add(new Room__c(
										    		Name = '部屋テスト' + CommUtils.getRandom(6),
										    		CapacityHaku__c = 4,
										    		Capacity__c = 2,
										    		Area__c = '本館',
										    		Floor__c = '1F',
										    		UseOfRoom__c = '客室',
										    		heyadashiryouryou__c = 40000,
										    		TypeRoomRef__c =roomTypeId,
										    		heyadashiryou__c = 25000
										   			));
    	}
    	insert newRooms;
    	return newRooms;
    }
    public static Room__c createRooms(Id roomType) {
        Room__c item = new Room__c(
            Name = '部屋テスト' + CommUtils.getRandom(6),
            CapacityHaku__c = 4,
            Capacity__c = 2,
            Area__c = '本館',
            Floor__c = '1F',
            UseOfRoom__c = '客室',
            heyadashiryouryou__c = 40000,
            TypeRoomRef__c = roomType,
            heyadashiryou__c = 25000);
        insert item;
        return item;
    }
	public static RoomsStatus__c createBadRoom(Id roomId, Date startDt) {
		RoomsStatus__c status = new RoomsStatus__c(
			RoomRef__c = roomId,
			Status__c = '故障',
			StatusBeginDate__c = startDt,
			StatusEndDate__c = startDt.addDays(365)
		);
		insert status;
		return status;
	}
	public static RoomsStatus__c createBadRoom(Id roomId, Date startDt, Date endDt) {
		RoomsStatus__c status = new RoomsStatus__c(
			RoomRef__c = roomId,
			Status__c = '故障',
			StatusBeginDate__c = startDt,
			StatusEndDate__c = endDt
		);
		insert status;
		return status;
	}
    public static TypeOfRooms__c createTypeOfRoom() {
        TypeOfRooms__c item = new TypeOfRooms__c(
            Name = 'S1' + CommUtils.getRandom(10),
            RoomTypeCode__c = CommUtils.getRandom(6),
            RoomTypeName__c = 'TYPENAME_'+CommUtils.getRandom(10),
            MaxRooms__c = 99);
        insert item;
        return item;
    }
    public static TypeOfRooms__c createTypeOfRoom(Integer rooms) {
        TypeOfRooms__c item = new TypeOfRooms__c(
            Name = 'S1' + CommUtils.getRandom(10),
            MaxRooms__c = rooms);
        insert item;
        return item;
    }
    public static list<TypeOfRooms__c> createTypeOfRoom(List<String> typeCds) {
		List<TypeOfRooms__c> types = new list<TypeOfRooms__c>();
		for (String cd : typeCds) {
		types.add(new TypeOfRooms__c(
            Name = 'S1' + CommUtils.getRandom(10),
            RoomTypeCode__c = cd,
            RoomTypeName__c = cd,
            MaxRooms__c = 99));
		}
        insert types;
        return types;
    }
    /**
    * 支店単位の部屋タイプ情報作成
    **/
    public static List<TypeOfRooms__c> createTypeOfRoomByShop(Id shopId, Integer nums) {
    	List<TypeOfRooms__c> typeRooms = new List<TypeOfRooms__c>();
    	for (Integer i=0; i<nums; i++) {
    		TypeOfRooms__c item = new TypeOfRooms__c(
            	Name = 'SS_' + CommUtils.getRandom(5),
            	MaxRooms__c = 5,
            	//Seq__c = i+1,
            	ShopInfoRef__c = shopId
           	);
           	typeRooms.add(item);
    	}

        insert typeRooms;
        return typeRooms;
    }
    // 見積明細
    public static BookingEstimateItem__c createBookEstItem(Lead__c leadInfo, AccountMaster__c prod) {
        BookingEstimateItem__c item = new BookingEstimateItem__c (
           //Name = '名称2(漢1)_UNIT_TEST_AUTONUM_' + system.now(),
           Amount__c = 4,
           refBooking__c = leadInfo.id,
           refAccountMaster__c = prod.Id,      // 商品名
           Field3__c = prod.Field3__c         // 商品コード
		   // 2020/01/30 利用日问题修复 by zy BEGIN
		   ,usedate__c = system.today()
		   // 2020/01/30 利用日问题修复 by zy END
        );
        insert item;
        return item;
    }
    public static List<BookingEstimateItem__c> createBookEstItems(Lead__c leadInfo, List<AccountMaster__c> prods) {
	
		List<BookingEstimateItem__c> insLst = new List<BookingEstimateItem__c>();
		for (AccountMaster__c prod : prods) {
	        BookingEstimateItem__c item = new BookingEstimateItem__c (
	           //Name = '名称2(漢1)_UNIT_TEST_AUTONUM_' + system.now(),
	           Amount__c = Integer.valueOf(CommUtils.getRandom(2)),
	           refBooking__c = leadInfo.id,
	           refAccountMaster__c = prod.Id,      // 商品名
	           Field3__c = prod.Field3__c         // 商品コード
	        );
	        insLst.add(item);
		}

        insert insLst;
        return insLst;
    }

	public static List<DP__c> createDP(Integer size) {
		List<DP__c> dpLst = new List<DP__c>();
		for (Integer i= 0; i<size; i++) {
			DP__c dp = new DP__c(
				Name = 'DP_UT_' + CommUtils.getRandom(10),
				Field1__c = String.valueOf(i+1000)
			);
			dpLst.add(dp);
		}
		insert dpLst;
		return dpLst;
	}
	public static List<GP__c> createGP(Integer size) {
		List<GP__c> gpLst = new List<GP__c>();
		for (Integer i= 0; i<size; i++) {
			GP__c dp = new GP__c(
				Name = 'GP_UT_' + CommUtils.getRandom(10),
				Field1__c = String.valueOf(i+1000)
			);
			gpLst.add(dp);
		}
		insert gpLst;
		return gpLst;
	}
	public static List<OP__c> createOP(Integer size) {
		List<OP__c> opLst = new List<OP__c>();
		for (Integer i= 0; i<size; i++) {
			OP__c dp = new OP__c(
				Name = 'OP_UT_' + CommUtils.getRandom(10),
				Field1__c = String.valueOf(i+1000)
			);
			opLst.add(dp);
		}
		insert opLst;
		return opLst;
	}
	public static List<KanjoKamoku__c> createKanjoKanmoku(Integer size) {
		List<KanjoKamoku__c> kkLst = new List<KanjoKamoku__c>();
		for (Integer i= 0; i<size; i++) {
			KanjoKamoku__c dp = new KanjoKamoku__c(
				Name = 'DP_UT_' + CommUtils.getRandom(10),
				Kanjocode__c = '9'+Integer.valueOf(CommUtils.getRandom(7)),
				KanjocodeCode__c = CommUtils.getRandom(8),
				KanjoHojocode__c = CommUtils.getRandom(8),
				KanjoHojoname__c = 'SUB_NAME_'+CommUtils.getRandom(10)
			);
			kkLst.add(dp);
		}
		insert kkLst;
		return kkLst;
	}
	
    // 会計商品
    public static List<AccountMaster__c> createProductMst(Integer intNum) {
    	List<AccountMaster__c> insLst = new List<AccountMaster__c>();
    	JMST__c taxMst =  createTaxMst();
        for (Integer i =0; i < intNum; i++) {
	        AccountMaster__c item = new AccountMaster__c(
	           Name = '名称2(漢1)UNIT_TEST' + CommUtils.getRandom(9),
	           jmstRef__c = taxMst.Id,
	           StsTaxfee__c = '0',
	           Field3__c = 'UNIT' + CommUtils.getRandom(9),         // 商品コード
	           Field5__c = 1050,
	           ServiceRate__c = 10,
	           SpecialTax__c = 100
	        );
        	insLst.add(item);
        }
        insert insLst;
        return insLst;
    }
     // 会計商品[室料]
    public static AccountMaster__c createRoomProductMst() {

    	JMST__c taxMst =  createTaxMst();
        AccountMaster__c item = new AccountMaster__c(
           Name = '室料' + CommUtils.getRandom(9),
           jmstRef__c = taxMst.Id,
           StsTaxfee__c = '0',
           Field3__c = 'UNIT' + CommUtils.getRandom(9),         // 商品コード
           Field5__c = 0,
           ActionType__c = CommConst.PROD_ACTION_TYPE_RP,//室料
           ServiceRate__c = 10,
           SpecialTax__c = 0
        );
		insert item;
        return item;
    }
    
    public static List<AccountMaster__c> createPayProductMst(List<String> productCds) {
    	List<AccountMaster__c> insLst = new List<AccountMaster__c>();
    	JMST__c taxMst =  createTaxMst();
        for (Integer i =0; i < productCds.size(); i++) {
	        AccountMaster__c item = new AccountMaster__c(
	           Name = '名称2(漢1)UNIT_TEST' + CommUtils.getRandom(9),
	           Field3__c = productCds[i],
	           jmstRef__c = taxMst.Id,
	           StsTaxfee__c = '0',
	           Field5__c = 1050,
	           ServiceRate__c = 10,
	           SpecialTax__c = 100
	        );
        	insLst.add(item);
        }
        insert insLst;
        return insLst;
    }
    // 会計商品
    public static List<AccountMaster__c> createFullProductMst(Integer intNum) {
    	List<AccountMaster__c> insLst = new List<AccountMaster__c>();
    	JMST__c taxMst =  createTaxMst();
    	List<DP__c> dpLst = createDP(intNum);
    	List<GP__c> gpLst = createGP(intNum);
    	List<OP__c> opLst = createOP(intNum);
    	List<KanjoKamoku__c> kkLst = createKanjoKanmoku(intNum);
    	
        for (Integer i =0; i < intNum; i++) {
	        AccountMaster__c item = new AccountMaster__c(

	           Name = '名称2(漢1)UNIT_TEST' + CommUtils.getRandom(9),
				// $会計マスタ
				//Field13_del__c =
				// $原価率
				//Genkaritsu__c =
				// $商品コード
				//nextitemcode__c =
				// $商品コード桁数
				//CodeNumbers__c  =
				// $粗利益
				//Profit__c  =
				// $粗利益率
				//proftPer__c  =
				// $単価(税抜)
				//SalesnoneTax__c  =
				// #DP
				DPChange__c  = dpLst[i].Id,
				// #GP
				GPChange__c  = gpLst[i].Id,
				// KD表示文字背景色
				KD__c  = 'red',
				// OES用ﾒﾆｭｰ
				OES__c  = CommUtils.getRandom(3),
				// PLUｺｰﾄﾞ
				PLU__c  = CommUtils.getRandom(10),
				// SCP(5)
				SCP_5__c  = CommUtils.getRandom(3),
				// お部屋
				//Field12__c  =
				// お料理
				//Field2__c  =
				// サービス料(%)
				ServiceRate__c  = Integer.valueOf(CommUtils.getRandom(1)),
				// セット
				//detail13__c  =
				// リンクＤＰコード
				Field4__c  = dpLst[i].Id,
				// 会計OP
				OP__c  = opLst[i].Id,
				// 会計科目
				KanjoKamokuRef__c  = kkLst[i].Id,
				// 見積項目#
				//EstimateFieldNo__c  =
				// 原価
				Field7__c  = Integer.valueOf(CommUtils.getRandom(4)),
				// 商品コード
				Field3__c  = 'F_IT' + CommUtils.getRandom(9),         // 商品コード
				// 商品処理種別
				//ActionType__c  =
				// 商品名称（英）
				ProductEnName__c  = 'EN_' + CommUtils.getRandom(10),
				// 小計割引／割増
				Field10__c  = CommUtils.getRandom(3),
				// 消費税
				//TaxRateCal__c  =
				// 消費税マスタ
				jmstRef__c  = taxMst.Id,
				// 税ｽﾃｰﾀｽ
				StsTaxfee__c  = '0',
				// 単価
				Field5__c  = Integer.valueOf(CommUtils.getRandom(6)),
				// 単価2
				Field8__c  = Integer.valueOf(CommUtils.getRandom(6)),
				// 特別税
				SpecialTax__c  = 100,
				// 名称1(ｶﾅ)
				X1__c  = 'カナ_' +  CommUtils.getRandom(10),
				// 名称3(漢2)
				X3_2__c  = '漢字1_' + CommUtils.getRandom(10),
				// 名称4(漢3)
				X4_3__c  = '漢字2_' + CommUtils.getRandom(10),
				// ｻﾌﾞ単価
				Field6__c  = Integer.valueOf(CommUtils.getRandom(4)),
				// ｾｯﾄ宣言
				Field9__c  = CommUtils.getRandom(3),
				// ﾌﾘｰ宣言
				Field11__c  = CommUtils.getRandom(3)
	        );
        	insLst.add(item);
        }
        insert insLst;
        return insLst;
    }
    public static list<AccountMaster__c> createPayProductMst (set<String> mediaType) {
    	
    	// 会計支払商品を自動作成を行う
    	//String[] names = new List<String>{'現金','カード','売掛金','クーポン','値引','予約金'};
    	String[] names = new List<String>{Label.CONST_012_0438,Label.CONST_012_0439,Label.CONST_012_0440,Label.CONST_012_0441,Label.CONST_012_0442,Label.CONST_012_0443};
    	String[] codes = new List<String>{'M99000','M99001','M99002','M99003','M99004','M99005'};
    	String[] pays = new List<String>{'現金','カード','売掛金','クーポン','値引','予約金'};
    	List<AccountMaster__c> newAccMst = new List<AccountMaster__c>();
    	for (Integer i = 0; i<codes.size();i++) {
    		if (mediaType !=null && !mediaType.contains(names[i])) continue;
    		String code = codes[i];
    		AccountMaster__c accMst = new AccountMaster__c(
    			Name = names[i],
    			Field3__c = code,
    			ActionType__c = CommConst.PROD_ACTION_TYPE_PY,
    			PaymentType__c = pays[i]
    		);
    		newAccMst.add(accMst);
    	}
    	if (!newAccMst.isempty()) upsert newAccMst Field3__c;
    	return newAccMst;
    }
    // 税金マスた
    public static JMST__c createTaxMst() {
    	JMST__c item = new JMST__c(
    	   TaxRate__c = 5
    	);
    	insert item;
    	return item;
    }
    // 2019/08/12 消費税は8%から10%に変更対応 WGCH BEGIN
    // 会計商品
    public static List<AccountMaster__c> createProductMst_8(Integer intNum) {
    	List<AccountMaster__c> insLst = new List<AccountMaster__c>();
    	JMST__c taxMst =  createTaxMst_8();
        for (Integer i =0; i < intNum; i++) {
	        AccountMaster__c item = new AccountMaster__c(
	           Name = '名称2(漢1)UNIT_TEST' + CommUtils.getRandom(9),
	           jmstRef__c = taxMst.Id,
	           StsTaxfee__c = '0',
	           Field3__c = 'UNIT' + CommUtils.getRandom(9),         // 商品コード
	           Field5__c = 1050,
	           ServiceRate__c = 10,
	           SpecialTax__c = 100
	        );
        	insLst.add(item);
        }
        insert insLst;
        return insLst;
    }
    // 税金マスた
    public static JMST__c createTaxMst_8() {
    	JMST__c item = new JMST__c(
    	   TaxRate__c = 8
    	);
    	insert item;
    	return item;
    }
    // 2019/08/12 消費税は8%から10%に変更対応 WGCH END
    // レポートロゴ
    public static ReportLogo__c createRepLogo() {
    	ReportLogo__c item = new ReportLogo__c();
    	item.name = CommRepUtils.REP_TYPE.LOGO_00_SYSDEF.name();
    	item.ReportLogo__c = 'ImagePiciure';
    	insert item;
    	return item;
    }

    public static Plan__c createPlan() {
    	JMST__c taxMst =  createTaxMst();
    	Plan__c plan = new Plan__c();
    	plan.name = 'テストプランデータ' + CommUtils.getRandom(5);
    	plan.PlanNo__c = CommUtils.getRandom(10);
    	plan.Price__c = 35000;
    	plan.PackageCode__c = 'PK_'+CommUtils.getRandom(10);
    	plan.JmstRef__c = taxMst.Id;
    	plan.PlanStartDateandtime__c = Date.newInstance(2000,1,1);
    	plan.Planclosedateandtime__c = Date.newInstance(2999,1,1);
    	insert plan;
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(3);
        ApexPages.StandardController contrl = new ApexPages.StandardController(plan);
        PlanProductSetup ctrl = new PlanProductSetup(contrl);
        List<PlanProductSetup.PlanDetail> planDeLst = ctrl.planDetailList;
        planDeLst[0].productNm = productLst[0].Name;
        planDeLst[0].sobj.AccountMasterRef__c = productLst[0].Id;
        planDeLst[0].sobj.Price__c = 10000;
        planDeLst[0].sobj.taxRate__c = taxMst.taxRate__c;
        planDeLst[1].productNm = productLst[1].Name;
        planDeLst[1].sobj.AccountMasterRef__c = productLst[1].Id;
        planDeLst[1].sobj.Price__c = 20000;
        planDeLst[1].sobj.taxRate__c = taxMst.taxRate__c;
        planDeLst[2].productNm = productLst[2].Name;
        planDeLst[2].sobj.AccountMasterRef__c = productLst[2].Id;
        planDeLst[2].sobj.Price__c = 5000;
        planDeLst[2].sobj.taxRate__c = taxMst.taxRate__c;
        ctrl.savePlanDetail();
    	return plan;
    }

    public static Plan__c createPlanIncRoom() {
    	JMST__c taxMst =  createTaxMst_8();
    	Plan__c plan = new Plan__c();
    	plan.name = 'テストプランデータ' + CommUtils.getRandom(5);
    	plan.PlanNo__c = CommUtils.getRandom(10);
    	plan.Price__c = 50000;
    	plan.PackageCode__c = 'PK_'+CommUtils.getRandom(10);
    	plan.JmstRef__c = taxMst.Id;
    	plan.PlanStartDateandtime__c = Date.newInstance(2000,1,1);
    	plan.Planclosedateandtime__c = Date.newInstance(2999,1,1);
    	insert plan;
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(3);
        AccountMaster__c roomProductItem = TestCommon.createRoomProductMst();
System.debug(LoggingLevel.info, 'roomProductItem='+roomProductItem);
        ApexPages.StandardController contrl = new ApexPages.StandardController(plan);
        PlanProductSetup ctrl = new PlanProductSetup(contrl);
        List<PlanProductSetup.PlanDetail> planDeLst = ctrl.planDetailList;
        planDeLst[0].productNm = productLst[0].Name;
        planDeLst[0].sobj.AccountMasterRef__c = productLst[0].Id;
        planDeLst[0].sobj.Price__c = 10000;
        planDeLst[0].sobj.taxRate__c = taxMst.taxRate__c;
        planDeLst[1].productNm = productLst[1].Name;
        planDeLst[1].sobj.AccountMasterRef__c = productLst[1].Id;
        planDeLst[1].sobj.Price__c = 20000;
        planDeLst[1].sobj.taxRate__c = taxMst.taxRate__c;
        planDeLst[2].productNm = productLst[2].Name;
        planDeLst[2].sobj.AccountMasterRef__c = productLst[2].Id;
        planDeLst[2].sobj.Price__c = 5000;
        planDeLst[2].sobj.taxRate__c = taxMst.taxRate__c;
        planDeLst[3].productNm = roomProductItem.Name;
        planDeLst[3].sobj.AccountMasterRef__c = roomProductItem.Id;
        planDeLst[3].sobj.Price__c = 15000;
        planDeLst[3].sobj.taxRate__c = taxMst.taxRate__c; 
System.debug(LoggingLevel.info, ' planDeLst='+ planDeLst);
        ctrl.savePlanDetail();
    	return plan;
	}
	public static Plan__c createPlanIncRoom0() {
    	JMST__c taxMst =  createTaxMst_8();
    	Plan__c plan = new Plan__c();
    	plan.name = 'テストプランデータ' + CommUtils.getRandom(5);
    	plan.PlanNo__c = CommUtils.getRandom(10);
    	plan.Price__c = 35000;
    	plan.PackageCode__c = 'PK_'+CommUtils.getRandom(10);
    	plan.JmstRef__c = taxMst.Id;
    	plan.PlanStartDateandtime__c = Date.newInstance(2000,1,1);
    	plan.Planclosedateandtime__c = Date.newInstance(2999,1,1);
    	insert plan;
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(3);
        AccountMaster__c roomProductItem = TestCommon.createRoomProductMst();
        ApexPages.StandardController contrl = new ApexPages.StandardController(plan);
        PlanProductSetup ctrl = new PlanProductSetup(contrl);
        List<PlanProductSetup.PlanDetail> planDeLst = ctrl.planDetailList;
        planDeLst[0].productNm = productLst[0].Name;
        planDeLst[0].sobj.AccountMasterRef__c = productLst[0].Id;
        planDeLst[0].sobj.Price__c = 10000;
        planDeLst[0].sobj.taxRate__c = taxMst.taxRate__c;
        planDeLst[1].productNm = productLst[1].Name;
        planDeLst[1].sobj.AccountMasterRef__c = productLst[1].Id;
        planDeLst[1].sobj.Price__c = 20000;
        planDeLst[1].sobj.taxRate__c = taxMst.taxRate__c;
        planDeLst[2].productNm = productLst[2].Name;
        planDeLst[2].sobj.AccountMasterRef__c = productLst[2].Id;
        planDeLst[2].sobj.Price__c = 5000;
        planDeLst[2].sobj.taxRate__c = taxMst.taxRate__c;
        planDeLst[3].productNm = roomProductItem.Name;
        planDeLst[3].sobj.AccountMasterRef__c = roomProductItem.Id;
        planDeLst[3].sobj.Price__c = 0;
        planDeLst[3].sobj.taxRate__c = taxMst.taxRate__c; 
        ctrl.savePlanDetail();
    	return plan;
    }
    
    /**
    * 店舗情報を設定する
    **/
    public static ShopInformation__c createShopInfo() {
    	ShopInformation__c shop = new ShopInformation__c(
    		Name='東京都新宿区２号店'
    		,Fax__c = '03-1111-2222'
    		,Seq__c = Integer.valueOf(CommUtils.getRandom(8))
    		,WebSite__c = 'http://www.branch002.softpark.com'
    		,Email__c = 'east.baranch0002@softpark.com'
    		,Address__c = '東京都新宿区１番地２３手目４０６号'
    		,ShopCode__c = CommUtils.getRandom(10)
    		,Phone__c = '03-0222-11111'
    		,Post__c = '19100011'
    		,TierDefault__c = 'Tier1'
    		,FacilityCode__c = CommUtils.getRandom(4)
    	);
    	insert shop;
    	return shop;
    }
	/**
	* 会計商品（プラン）作成、戻る
	**/
	public static AccountMaster__c createPlanProd() {
		Plan__c createPlan = createPlan();
		// 該当プランによて、関連の会計商品（プラン）を取得する
		String queryHeader = CommSqlUtils.generateQueryString('AccountMaster__c');
		Id planProdId = [select PlanProdcut__c from PlanDetail__c where PlanRef__c = :createPlan.Id limit 1].PlanProdcut__c;
		return Database.query(queryHeader + ' Where id = :planProdId');
	}
	/**
	*為替レート
	*/
	public static ExchangeRate__c createExchangeRate()
	{
		return createExchangeRate('USD','JPY');
	}
    public static ExchangeRate__c createExchangeRate(String fromCur, String toCur)
    {
        String dateFormat = System.now().format('yyyy/MM/dd');
        ExchangeRate__c e = new ExchangeRate__c(
                Name = fromCur+toCur+'_'+dateFormat,
                FromCurrency__c = fromCur,
                ToCurrency__c = toCur,
                RateDate__c = Date.today(),
                Rate__c = 101.4545
            );
            insert e;
            return e;
    }
	/**
	* テスト用ユーザー作成を行う
	*/
	public static User CreateUser() {
		//Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
		User u2 = new User(Alias = 'newUser', Email='newuser@testorg.com', 
         EmailEncodingKey='UTF-8', 
         LastName='LN_' + CommUtils.getRandom(9),
         ProfileId = UserInfo.getProfileId(),
         TimeZoneSidKey='Asia/Tokyo',
         LanguageLocaleKey='ja',
         LocaleSidKey='ja_JP',
         UserName='newuser' + CommUtils.getRandom(9) + '@testorg.com');
         return u2;
	}
    // 新規会計
    public static AccountAcount__c createAccountAcount(String rsvId,String leadID) {
        AccountAcount__c aaItem = new AccountAcount__c(
            frs__c = rsvId
            ,Relreserve__c = leadID
        );
        insert aaItem;
        return aaItem;
    }
    // 新規会計支払
    public static TTend__c createTTend(String rsvId,String aaId) {
        TTend__c ttitem = new TTend__c(
            RelAccount__c = rsvId
            ,Field1__c = aaId
        );
        insert ttitem;
        return ttitem;
    }
    // 新規会計支払[売上ID、会計ID、支払商品ID]
    public static TTend__c createTTend(String rsvId,String aaId, String prodID) {
        TTend__c ttitem = new TTend__c(
            RelAccount__c = rsvId
            ,Field1__c = aaId
            ,PayProductRef__c = prodID
            ,Field20__c = String.valueOf(10000)
        );
        insert ttitem;
        return ttitem;
    }
    // 終業規則
    public static WorkTimeDefine__c createWorkTimeDefine (String shopCode) {
        // 終業規則設定
        WorkTimeDefine__c wk = new WorkTimeDefine__c();
        wk.Name = '共通テスト';
        wk.ShopCode__c = shopCode;
        wk.DayOfRegularWorkTime__c = 8;
        wk.LateNightStartTime__c = '22:00';
        wk.LateNightEndTime__c = '05:00';
        insert wk;
        return wk;
    }
    public static CooperationResult__c createCooperationParentXMLImpot(){
    	return createCooperationParentXMLImpot(null);
    }
    public static CooperationResult__c createCooperationParentXMLImpot(String shopCd){
    	return createCooperationParentXMLImpot(shopCd,'TL');
    }
    public static CooperationResult__c createCooperationParentXMLImpot(String shopCd, String serviceKey){
    	CooperationResult__c parent = new CooperationResult__c(
											Status__c = 'XML取込完了',
											ErrorCount__c = 0,
											FunctionType__c = '予約取込',
											ManageID__c = 'K3437120150917000035'+CommUtils.getRandom(9),
											ProcessingType__c = serviceKey
										);
		if (!CommUtils.isBlank(shopCd)) parent.ShopCode__c = shopCd;
		insert parent;
		return parent;
    }
    public static CooperationResult__c createCooperationParentLeadImport(){
    	return createCooperationParentLeadImport(null);
    }
    public static CooperationResult__c createCooperationParentLeadImport(String shopCd){
    	CooperationResult__c parent = new CooperationResult__c(
											Status__c = '予約取込完了',
											ErrorCount__c = 0,
											FunctionType__c = '予約取込',
											ManageID__c = 'K3437120150917000034'+CommUtils.getRandom(9),
											ProcessingType__c = 'TL'
										);
		if (!CommUtils.isBlank(shopCd)) parent.ShopCode__c = shopCd;
		insert parent;
		return parent;
    }
    public static CooperationResult__c createLeadImportAndWaitImpot(){
    	return createLeadImportAndWaitImpot(null);
    }
	public static CooperationResult__c createLeadImportAndWaitImpot(String shopCd){
		return createLeadImportAndWaitImpot(shopCd, 'TL');
	}
	public static CooperationResult__c createLeadImportAndWaitImpot(String shopCd, String appName){
		CooperationResult__c parent = createCooperationParentXMLImpot(shopCd,appName);
		CooperationResult__c coo = new CooperationResult__c(
											Status__c = '予約取込待ち',
											FunctionType__c = '予約取込',
											ProcessingType__c = appName,
											ParentRef__c = parent.id
										);
		if (!CommUtils.isBlank(shopCd)) coo.ShopCode__c = shopCd;
		insert coo;
		return coo;
	}
    public static CooperationResult__c createLeadImportAndImpotNG(){
    	return createLeadImportAndImpotNG(null);
    }
    public static CooperationResult__c createLeadImportAndImpotNG(String shopCd){
    	CooperationResult__c parent = createCooperationParentXMLImpot(shopCd);
    	CooperationResult__c coo = new CooperationResult__c(
											Status__c = '予約取込待ち',
											FunctionType__c = '予約取込',
											ProcessingType__c = 'TL',
											ParentRef__c = parent.id
										);
		if (!CommUtils.isBlank(shopCd)) coo.ShopCode__c = shopCd;
		insert coo;
		return coo;
	}
    public static CooperationResult__c createTaLeadImportAndImpotNG(String shopCd){
    	CooperationResult__c parent = createCooperationParentXMLImpot(shopCd,'TA');
    	CooperationResult__c coo = new CooperationResult__c(
											Status__c = '予約取込待ち',
											FunctionType__c = '予約取込',
											ProcessingType__c = 'TA',
											ParentRef__c = parent.id
										);
		if (!CommUtils.isBlank(shopCd)) coo.ShopCode__c = shopCd;
		insert coo;
		return coo;
	}
	
    public static Document createTl2WayConfigDoc() {
    	String configXml = '<?xml version="1.0" encoding="UTF-8"?><root><COMMON><STOCKINTERVAL>120</STOCKINTERVAL><STOCKDELETEVAL>-3</STOCKDELETEVAL><LEADINTERVAL>10</LEADINTERVAL><LEADDELETEVAL>-30</LEADDELETEVAL><SERVICE_URL>https://test472.tl-lincoln.net/pmsservice/V1</SERVICE_URL></COMMON><SHOP><SHOPCODE></SHOPCODE><APPCONFIG><SYSTEMID>PFg69aA0</SYSTEMID><USERID>P6820207</USERID><PASSWORD>mj2UOAL.t3</PASSWORD><ROOMAUTOASSIGN>true</ROOMAUTOASSIGN><RELA_STOCK_REQ_SYNC>TRUE</RELA_STOCK_REQ_SYNC></APPCONFIG>	<ACCOUNTCONFIG><SHITULYOUACCOUNT>100999</SHITULYOUACCOUNT><NYUUTOUACCOUNT>5041</NYUUTOUACCOUNT><SERVICEACCOUNT>S0000</SERVICEACCOUNT></ACCOUNTCONFIG></SHOP></root>';
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'Tl2wayServiceConfigXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(configXml);
    	insert item;
    	return item;
    }
	
    public static Document createTa2WayConfigDoc() {
    	String configXml = '<?xml version="1.0" encoding="UTF-8"?><root><COMMON><STOCKINTERVAL>60</STOCKINTERVAL><STOCKDELETEVAL>-60</STOCKDELETEVAL><LEADINTERVAL>60</LEADINTERVAL><LEADDELETEVAL>-60</LEADDELETEVAL><SERVICE_URL_UP>https://sv2.temairazu.net/pmsup</SERVICE_URL_UP><SERVICE_URL>https://sv2.temairazu.net/pms/</SERVICE_URL><STOCK_RESTORE_START_DATE>2016-05-27</STOCK_RESTORE_START_DATE></COMMON><SHOP><SHOPCODE></SHOPCODE><APPCONFIG><SYSTEMID></SYSTEMID><USERID>pms-test</USERID><PASSWORD>temairazu</PASSWORD><UCACTISSYNC>TRUE</UCACTISSYNC><ROOMAUTOASSIGN>TRUE</ROOMAUTOASSIGN><ROOMSORT>ASC</ROOMSORT></APPCONFIG><ACCOUNTCONFIG><NYUUTOUACCOUNT>5041</NYUUTOUACCOUNT><SERVICEACCOUNT>SR0001</SERVICEACCOUNT></ACCOUNTCONFIG><PLANCODE_CONVERT><AGT AGTCODE="02"><CONVERT><AGTPACKAGECODE>A268Q,234,235</AGTPACKAGECODE><SFPLANNO>00002911</SFPLANNO></CONVERT></AGT></PLANCODE_CONVERT><PAYMENT_CONVERTS><POINT_CONVERT PAYKBN="カード決済"><CONVERT AGTCODE="80">M90201</CONVERT></POINT_CONVERT><PAYMENT_CONVERT PAYKBN="カード決済"><CONVERT AGTCODE="80">M90201</CONVERT></PAYMENT_CONVERT></PAYMENT_CONVERTS><PRE_PAYMENT_DEF>   <CRAD>事前カード決済</CRAD><CREDIT>一括精算,パッケージ予約</CREDIT></PRE_PAYMENT_DEF></SHOP></root>';
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'Ta2wayServiceConfigXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(configXml);
    	insert item;
    	return item;
    } 

    public static Document createJr2WayConfigDoc() {
        String configXml = '<?xml version="1.0" encoding="UTF-8"?><root>'+
        '<COMMON><SERVICE_URL>http://xxxxx.raku-2.jp</SERVICE_URL></COMMON>'+
        '<SHOP>'+
        '<SHOPCODE></SHOPCODE>'+
        '<APPCONFIG>'+
        '  <USERNAME>XXXXXXX</USERNAME><HOTELCODE>YYYYYYY</HOTELCODE><HOTELPASSWORD>ZZZZZZZ</HOTELPASSWORD>'+
        '  <UCACTISSYNC>FALSE</UCACTISSYNC>'+
        '  <ROOMAUTOASSIGN>FALSE</ROOMAUTOASSIGN>'+
        '  <ROOMSORT>ASC</ROOMSORT>'+
        '<COMPANYTOCHANEL></COMPANYTOCHANEL>'+
        '</APPCONFIG>'+
        '<ACCOUNTCONFIG>'+
        '  <NYUUTOUACCOUNT>M99000</NYUUTOUACCOUNT>'+
        '  <SERVICEACCOUNT>M99001</SERVICEACCOUNT>'+
        '</ACCOUNTCONFIG>'+
        '<PLANCODE_CONVERT>'+
        '<AGT NAME="60">'+
        '<CONVERT>'+
        '<AGTPACKAGECODE>A268Q,A2681</AGTPACKAGECODE>'+
        '<SFPLANNO>00000001</SFPLANNO>'+
        '</CONVERT>'+
        '</AGT>'+
        '</PLANCODE_CONVERT>'+
        '<PAYMENT_CONVERTS>'+
        '<POINT_CONVERT PAYKBN="現地決済">'+
        '<CONVERT AGTCODE="60">M90215</CONVERT>'+
        '</POINT_CONVERT>'+
        '<POINT_CONVERT PAYKBN="精算不要(ｶｰﾄﾞ決済)">'+
        '<CONVERT AGTCODE="60">M90216</CONVERT>'+
        '</POINT_CONVERT>'+
        '</PAYMENT_CONVERTS>'+
        '<PRE_PAYMENT_DEF>'+
        '<CRAD>精算不要(ｶｰﾄﾞ決済)</CRAD>'+
        '<CREDIT>JTB事前決済_HR2,精算不要(ﾊﾟｯｹｰｼﾞ),精算不要(事後ｶｰﾄﾞ決済)</CREDIT>'+
        '</PRE_PAYMENT_DEF>'+
        '<CHILD_PLAN_CONVERT>'+
        ' <MATCH RATE="70">00000001</MATCH>'+
        ' <MATCH RATE="50">00000002</MATCH>'+
        ' <MATCH RATE="30">00000003</MATCH>'+
        ' <MATCH RATE="10">00000004</MATCH>'+
        '</CHILD_PLAN_CONVERT>'+
        '<CHANNEL_CONVERTS>'+
        '<CONVERT AGTCODE="80">AGT[一休]</CONVERT>'+
        '<CONVERT AGTCODE="88">AGT[予約プロ]</CONVERT>'+
        '</CHANNEL_CONVERTS>'+
        '</SHOP>'+
        '</root>';
        // ドキュメントを作成する
        Document item = new Document();
        item.Name = 'JRServiceConfigXml';
        item.DeveloperName = item.Name;
        item.FolderId = UserInfo.getUserId();
        item.Body = Blob.valueOf(configXml);
        insert item;
        return item;
    } 
      
    public static Document createBillSimpleHelpConfigDoc() {
        String csv = '<root><SHOP><SHOPCODE></SHOPCODE><PAYMENT><!-- 会計商品：商品処理種別が「支払」の場合、会計商品の「支払種別」から会計支払Media種別変更ルール --><CONVERT><PAYTYPE>現金</PAYTYPE><MEIDALAB>預り／現計</MEIDALAB><MEIDACODE>01</MEIDACODE></CONVERT><CONVERT><PAYTYPE>カード</PAYTYPE><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB><MEIDACODE>02</MEIDACODE></CONVERT><CONVERT><PAYTYPE>売掛金</PAYTYPE><MEIDALAB>掛計</MEIDALAB><MEIDACODE>03</MEIDACODE></CONVERT><CONVERT><PAYTYPE>クーポン</PAYTYPE><MEIDALAB>クーポン</MEIDALAB><MEIDACODE>10</MEIDACODE></CONVERT><CONVERT><PAYTYPE>値引</PAYTYPE><MEIDALAB>値引・割引券</MEIDALAB><MEIDACODE>11</MEIDACODE></CONVERT><CONVERT><!-- 未使用 --><PAYTYPE>割引</PAYTYPE><MEIDALAB>値引・割引券</MEIDALAB><MEIDACODE>11</MEIDACODE></CONVERT><CONVERT><PAYTYPE>予約金</PAYTYPE><MEIDALAB>予約金</MEIDALAB><MEIDACODE>21</MEIDACODE></CONVERT><CONVERT><PAYTYPE>現金返金</PAYTYPE><MEIDALAB>預り／現計</MEIDALAB><MEIDACODE>01</MEIDACODE></CONVERT><CONVERT><PAYTYPE>カード返金</PAYTYPE><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB><MEIDACODE>02</MEIDACODE></CONVERT></PAYMENT><PAYMEIDA><!-- 元の支払メデイア情報により、どの会計商品を紐付くを定義する --><CONVERT><MEIDALAB>預り／現計</MEIDALAB><!-- 支払メディア種別 --><MEIDACODE>01</MEIDACODE><PRODCODE>M99000</PRODCODE><!-- 会計商品コード --></CONVERT><CONVERT><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB><MEIDACODE>02</MEIDACODE><PRODCODE>M99001</PRODCODE></CONVERT><CONVERT><MEIDALAB>掛計</MEIDALAB><MEIDACODE>03</MEIDACODE><PRODCODE>M99002</PRODCODE></CONVERT><CONVERT><MEIDALAB>クーポン</MEIDALAB><MEIDACODE>10</MEIDACODE><PRODCODE>M99003</PRODCODE></CONVERT><CONVERT><MEIDALAB>値引・割引券</MEIDALAB><MEIDACODE>11</MEIDACODE><PRODCODE>M99004</PRODCODE></CONVERT><CONVERT><MEIDALAB>予約金</MEIDALAB><MEIDACODE>21</MEIDACODE><PRODCODE>M99005</PRODCODE></CONVERT></PAYMEIDA><ACCOUNTCONFIG><SHITULYOUACCOUNT>100999</SHITULYOUACCOUNT><NYUUTOUACCOUNT>5041</NYUUTOUACCOUNT><SERVICEACCOUNT>S0000</SERVICEACCOUNT></ACCOUNTCONFIG></SHOP>'
                    + '</root>';
        Document BillSimpleHelpConfig = new Document();
        BillSimpleHelpConfig.Name = 'BillSimpleHelpConfig';
        BillSimpleHelpConfig.DeveloperName = BillSimpleHelpConfig.Name;
        BillSimpleHelpConfig.FolderId = UserInfo.getUserId();
        BillSimpleHelpConfig.Body = Blob.valueOf(csv);
        insert BillSimpleHelpConfig;
        return BillSimpleHelpConfig;
    }
    public static Document createBillSimplePaymentConfigDoc() {
        String csv = '<root><SHOP><SHOPCODE></SHOPCODE><LAYOUT><MAXCOLS>3</MAXCOLS><BTNSTYLE>width:124px;height:30px;</BTNSTYLE><TABLEWIDTH>420</TABLEWIDTH><TABLEHEIGHT>280</TABLEHEIGHT></LAYOUT><BUTTONTAB><TABLABEL>メディア</TABLABEL><BUTTON ISBLANK="FALSE"><LABEL>現金</LABEL><PRODCODE>M99000</PRODCODE><ICONURL>/resource/AppImages/payicon/Cash.png</ICONURL></BUTTON></BUTTONTAB></SHOP>'
                    + '</root>';
        Document config = new Document();
        config.Name = 'BillSimplePaymentConfig';
        config.DeveloperName = config.Name;
        config.FolderId = UserInfo.getUserId();
        config.Body = Blob.valueOf(csv);
        insert config;
        return config;
    }
    public static void createTesuryoConfigDoc() {
    	
    	String configXml = '<?xml version="1.0" encoding="utf-8"?><root><!-- 概要：銀行振り込み情報作成の関連定義情報 --><SHOP><!-- デフォルト設定情報、削除しない、支店舗追加したい場合、このＮＯＤＥコピーして、後ろに追加してください --><SHOPCODE></SHOPCODE><ROUND_TYPE>1</ROUND_TYPE><!-- 手数料の端数処理区分 0:切り捨て / 1:四捨五入 / 2:切り上げ --><!-- 処理通知先メールアドレス,「,」で複数メールアドレス定義可能（５個まで） --><RESULT_MAIL>test11111@1111cccsss999.com</RESULT_MAIL><!-- 銀行へ通信電文関連定義情報 --><!-- 銀行振り込み手数料:必須 --><BANK_TRANS_RATE><SAME_BANK><!-- 同銀行 --><SAME_BRANCH><!-- 同支店 --><RANK_LEVEL><MIN_VAL>0</MIN_VAL><MAX_VAL>9999</MAX_VAL><RATE>0</RATE></RANK_LEVEL><RANK_LEVEL><MIN_VAL>10000</MIN_VAL><MAX_VAL>29999</MAX_VAL><RATE>0</RATE></RANK_LEVEL><RANK_LEVEL><MIN_VAL>30000</MIN_VAL><RATE>0</RATE></RANK_LEVEL></SAME_BRANCH><DIFF_BRANCH><!-- 別支店 --><RANK_LEVEL><MIN_VAL>0</MIN_VAL><MAX_VAL>9999</MAX_VAL><RATE>108</RATE></RANK_LEVEL><RANK_LEVEL><MIN_VAL>10000</MIN_VAL><MAX_VAL>29999</MAX_VAL><RATE>108</RATE></RANK_LEVEL><RANK_LEVEL><MIN_VAL>30000</MIN_VAL><RATE>324</RATE></RANK_LEVEL></DIFF_BRANCH></SAME_BANK><DIFF_BANK><!-- 別銀行 --><RANK_LEVEL><MIN_VAL>0</MIN_VAL><MAX_VAL>9999</MAX_VAL><RATE>324</RATE></RANK_LEVEL><RANK_LEVEL><MIN_VAL>10000</MIN_VAL><MAX_VAL>29999</MAX_VAL><RATE>432</RATE></RANK_LEVEL><RANK_LEVEL><MIN_VAL>30000</MIN_VAL><RATE>648</RATE></RANK_LEVEL></DIFF_BANK></BANK_TRANS_RATE><!-- 口座情報定義する --><BANK_KOZAINFO><PUR_SETTLEMENT><!-- 買掛決済バッチ --><KOUZA_SEQ>2</KOUZA_SEQ><!-- 店舗口座情報#SEQ値 --><DESCRIPT>仕入支払口座</DESCRIPT><TRANS_TYPE>21</TRANS_TYPE><!-- 業務種別:21:総合 11または71:給与 12または72:賞与 --></PUR_SETTLEMENT></BANK_KOZAINFO><BANK_TELEGRAM_HEADER><DATA_KBN>1</DATA_KBN><!-- レコード種別:1:ヘッダレコード --><MESSAGE_LAYOUT>$$_データ区分_$$$$_種別コード_$$$$_コード区分_$$$$_委託者コード_$$$$_委託者名_$$$$_取組日_$$$$_仕向金融機関番号_$$$$_仕向金融機関名_$$$$_仕向支店番号_$$$$_仕向支店名_$$$$_預金種目(依頼人)_$$$$_口座番号(依頼人)_$$$$_ダミー_$$</MESSAGE_LAYOUT></BANK_TELEGRAM_HEADER><BANK_TELEGRAM_DETAIL><DATA_KBN>2</DATA_KBN><!-- レコード種別:2:データレコード --><IS_EDI>FALSE</IS_EDI><!-- EDI情報を使う --><IS_PLUSFORMAT>TRUE</IS_PLUSFORMAT><!-- $$_支払金額_$$,$$_先方負担手数料_$$,$$_振込手数料_$$追加情報を出力するがどうか --><!-- $$_識別表示_$$はYの場合、$$_顧客コード1_$$,$$_顧客コード2_$$全部長さ０空白文字を差し替え、$$_EDI情報_$$を設定する、 $$_識別表示_$$はY以外の場合、$$_顧客コード1_$$,$$_顧客コード2_$$は別々１０桁まで設定する、$$_EDI情報_$$は長さ０の空白文字を差し替え --><MESSAGE_LAYOUT>$$_データ区分_$$$$_被仕向金融機関番号_$$$$_被仕向金融機関名_$$$$_被仕向支店番号_$$$$_被仕向支店名_$$$$_手形交換所番号_$$$$_預金種目_$$$$_口座番号_$$$$_受取人名_$$$$_振込金額_$$$$_新規コード_$$$$_顧客コード1_$$$$_顧客コード2_$$$$_EDI情報_$$$$_振込区分_$$$$_識別表示_$$$$_ダミー_$$$$_支払金額_$$$$_先方負担手数料_$$$$_振込手数料_$$</MESSAGE_LAYOUT></BANK_TELEGRAM_DETAIL><BANK_TELEGRAM_TRAILER><DATA_KBN>8</DATA_KBN><!-- レコード種別:8:トレーラレコード --><MESSAGE_LAYOUT>$$_データ区分_$$$$_合計件数_$$$$_合計金額_$$$$_ダミー_$$</MESSAGE_LAYOUT></BANK_TELEGRAM_TRAILER><BANK_TELEGRAM_END><DATA_KBN>9</DATA_KBN><!-- レコード種別:9:エンドレコード --><MESSAGE_LAYOUT>$$_データ区分_$$$$_ダミー_$$</MESSAGE_LAYOUT></BANK_TELEGRAM_END><!-- カード販売手数料計算関連 --><CARD_SALESRATE><I_TYPENAME>支払手数料</I_TYPENAME><O_KAMOKU>買掛（月末振込）</O_KAMOKU></CARD_SALESRATE><AGT_SALESRATE><I_TYPENAME>販売手数料</I_TYPENAME><!-- 種別 --><O_KAMOKU>買掛（月末振込）</O_KAMOKU><!-- 科目 --><HOLIDAY_INC_SAT>FALSE</HOLIDAY_INC_SAT><!-- 休日定義に、土曜日は休日として定義する/しない制御　TRUE:休日、FALSE：休日外(デフォルト値) --><CHARGERATE_LOGIC><FILTER TESURYONO="$$_TESURYONO_$$"><!-- 該当手数料番号に関連のご予約の抽出条件 --><DESCRIPT>I.JTB/HR(宿泊)</DESCRIPT><LOGIC>{0}</LOGIC><COONDITION>Relreserve__r.StayNightCal__c > 0</COONDITION></FILTER></CHARGERATE_LOGIC><CANCEL_CODE>800001</CANCEL_CODE><SALES_TARGETOUT>「現地追加」</SALES_TARGETOUT><PRE_PAYMENT_INFO><PRE_PAYMENT RATE="2.5">M90201</PRE_PAYMENT></PRE_PAYMENT_INFO></AGT_SALESRATE></SHOP></root>';
    	//if (CommUtils.isBlank(tesuryoNo)) tesuryoNo = '';
    	//configXml.replace('$$_TESURYONO_$$',configXml);
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'AccountingSyncBatchConfig';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(configXml);
    	insert item;
    }
    public static List<CollaborationGroup> createGroups(Integer groupNums) {
    	
    	List<CollaborationGroup> groupList = new List<CollaborationGroup>();
    	for (Integer i = 0; i<groupNums; i++) {
		 CollaborationGroup newGroup = new CollaborationGroup(
			Name = 'Chattグループ'+CommUtils.getRandom(10),
			CollaborationType = 'public'    
		 );
		 groupList.add(newGroup);
		}
		insert groupList;
		return groupList;
    }
    // 2015/11/03 RackRate Create
    public static void createRaceRateMst(Id roomTypeId, String tierKey, String peoples, Decimal price) {
    	RackRateTable__c base = new RackRateTable__c(
    		Tier__c = tierKey,
    		Persons__c = peoples,
    		RoomTypeRel__c = roomTypeId,
    		Price__c = price,
    		SearchKey__c = tierKey + '_' + roomTypeId + '_' + peoples
    	);
    	insert base;
    }
    public static void createRaceRateDetail(String tierKey,String peoples,integer days) {
    	List<RackRateTableDetail__c> insDetail = new List<RackRateTableDetail__c>();
    	for (Integer i = 0; i<days; i++) {
    		Date setupDate = date.today().addDays(i);
	    	RackRateTableDetail__c rackDetail = new RackRateTableDetail__c(
	    		Tier__c = tierKey,
	    		PriceSetupDate__c = setupDate,
	    		ShopInfoRef__c = null,
	    		SearchKey__c = '_'+setupDate
	    	);	
	    	insDetail.add(rackDetail);
    	}
    	insert insDetail;
    }
    
    // 手数料情報の作成
    public static ChargeInfo__c createchargeInfo(Id accId) {
    	ChargeInfo__c newItem = new ChargeInfo__c(
    		ShortName__c = 'カード',
    		CategoryMain__c = 'VISA',
    		AccountRef__c = accId,
    		PayChargeFlg__c = true,
    		SalesRate__c = 3.5
    	);
    	insert newItem;
    	return newItem;
    }
    // 口座情報の作成
    public static String createShopBankAccount(Integer size,account acc,List<RecordType> recs, id shopid) {
		List<ShopAccountInfo__c> saLst = new List<ShopAccountInfo__c>();
		for (Integer i= 0; i<size; i++) {
			for (RecordType rectype : recs) {
				ShopAccountInfo__c dsa = new ShopAccountInfo__c(
					BankNumber__c = CommUtils.getRandom(4),
					BankBranchNumber__c = CommUtils.getRandom(3),         
				    DepositsType__c = '普通',
				    BankAccountNo__c = CommUtils.getRandom(7),
				    BankName__c = '住友銀行' + CommUtils.getRandom(10),
				    BankBranchName__c = '目黒支店' + CommUtils.getRandom(10),
				    BankBranchNameKana__c = 'してんバンゴの確認',
				    RequestUserName__c = 'ｶﾏﾙｷ' + CommUtils.getRandom(10),
				    TransferChargeKbn__c = '先方負担',
				    RequestUserCode__c = 'REQ_'+CommUtils.getRandom(6),
				    AccountTypeLst__c = '買掛入金',
				    ShopInfoRef__c = shopid,
					AccountRef__c = acc.id,
					recordTypeId = rectype.id
				);
				saLst.add(dsa);
			}
		}
		insert saLst;
		String kouzaIds = '';
		for(ShopAccountInfo__c info : saLst){
			kouzaIds += info.Id + ',';
		}
		return kouzaIds;
	}
	// 2017/02/27 Order関連のXML定義情報を作成する
	public static document createOrderConfigXml() {
    	String domString = '<?xml version="1.0" encoding="UTF-8"?><root>	<SHOP>		<SHOPCODE></SHOPCODE> <DEVICEFILTER><LINKDP>  <CODE POSNO="POS06">001</CODE>   </LINKDP>	<GP><CODE POSNO="POS03">101</CODE>	</GP>	<DP><CODE POSNO="POS04">001</CODE><CODE POSNO="POS05">002</CODE>	</DP>	<OP><CODE POSNO="POS05">13</CODE>	</OP></DEVICEFILTER> <INFO_CUSTOME_DEF><ALLERGIE><LINEMAXSIZE>15</LINEMAXSIZE><FILTER><FIELD>Comment3__c</FIELD> <KEY>アレルギー</KEY> <BEG saveKey="TRUE"></BEG><END>\n</END> </FILTER></ALLERGIE></INFO_CUSTOME_DEF>	<CAMPAIGN> <URL>http://www.jinya-inn.com/databox/data.php/topics_furusto_bridal_ja/code</URL> <MESSAGE></MESSAGE> <IMGNAME>WorkFileForCampaign</IMGNAME> </CAMPAIGN><LOGOIMG>https://c.cs31.content.force.com/servlet/rtaImage?eid=a0Tp0000000YzX7&feoid=00Np0000000hzrc&refid=0EMp00000004IGZ	</LOGOIMG>		<PRINTCONFIG NAME="POS01"><PRINT>192.168.10.123</PRINT><PRINTPORT>9999</PRINTPORT><STATUS>localhost</STATUS><STATUSPORT>9999</STATUSPORT>	<LAYOUT> <ORDER>table_reciept2</ORDER>	 <ACCOUNT>retail_reciept2</ACCOUNT> <SIMPLEACCOUNT>retail_reciept2</SIMPLEACCOUNT> <DOOROPENSEQ>kick_drawer</DOOROPENSEQ> </LAYOUT>	</PRINTCONFIG>		<LAYOUT><MAXCOLS>3</MAXCOLS><BTNSTYLE>width:124px;height:30px;</BTNSTYLE><TABLEWIDTH>420</TABLEWIDTH><TABLEHEIGHT>280</TABLEHEIGHT>		</LAYOUT>		<DEVICECONFIG><DEVICE>	<LOCAL>192.168.10.104</LOCAL>	<PRINTER>POS01</PRINTER><ROOMSEQ>101001</ROOMSEQ></DEVICE><DEVICE><PRINTER>POS01</PRINTER>	<LOCAL>192.168.1.101</LOCAL>	<ROOMSEQ>1318</ROOMSEQ></DEVICE>		</DEVICECONFIG>		<BUTTONTAB><TABLABEL>●会席料理</TABLABEL><PRODUCT ISBLANK="FALSE">	<LABEL>SF)かに丼</LABEL>	<PRODCODE>0000000112506</PRODCODE>	<ICONURL></ICONURL>	</PRODUCT>		    <PRODUCT ISBLANK="FALSE">		<LABEL>SF)幼児朝食</LABEL>		<PRODCODE>0000000112104</PRODCODE>		<ICONURL>/resource/OrderLib/images/75/shake.jpg</ICONURL></PRODUCT><PRODUCT ISBLANK="FALSE">		<LABEL>EF)宴会料理（０３０）</LABEL>		<PRODCODE>0000000121103</PRODCODE>		<ICONURL>/resource/OrderLib/images/75/miso-soup.jpg</ICONURL></PRODUCT>		</BUTTONTAB><CREATEINFO ODERITEMTOMASTER="true"><LEADINFO NIGHTS="1"><ASSIGN FIELD="Field3__c">20:00</ASSIGN></LEADINFO><MERGEINFO><CLONE>comment3__c</CLONE></MERGEINFO></CREATEINFO>	</SHOP><SHOP><SHOPCODE>01</SHOPCODE><INFO_CUSTOME_DEF><ALLERGIE><FILTER><FIELD>Comment3__c</FIELD><TAG>アレルギー</TAG><BEG>：,→</BEG><END>\\n,・,\\n\\n</END></FILTER><FILTER><FIELD>relcontact__r.Field28__c</FIELD></FILTER></ALLERGIE></INFO_CUSTOME_DEF><PRINTCONFIG NAME="POS01"><WEBSOCKET>wss</WEBSOCKET><LAYOUT><ORDER>table_reciept2</ORDER><SIMPLEACCOUNT>retail_reciept2</SIMPLEACCOUNT><ACCOUNT>retail_reciept1</ACCOUNT><DOOROPENSEQ>kick_drawer</DOOROPENSEQ></LAYOUT><PRINT>192.168.10.107</PRINT><PRINTPORT>8081</PRINTPORT><STATUS>192.168.10.107</STATUS><STATUSPORT>8081</STATUSPORT><PREMARK>□ </PREMARK><HEADSTAND>true</HEADSTAND><PRINTNO>S01</PRINTNO><HIKAE>(控)</HIKAE></PRINTCONFIG><DEVICECONFIG><DEVICE><LOCAL>192.168.10.XXX</LOCAL><ROOMSEQ>6</ROOMSEQ><PRINTER>POS01</PRINTER><POSNO>001</POSNO></DEVICE></DEVICECONFIG><BUTTONTAB><TABLABEL>●会席料理</TABLABEL><BUTTONSUBTAB><PRODUCT ><NAME>SF)かに丼</NAME><CODE>9127</CODE></PRODUCT></BUTTONSUBTAB><PRODUCT ><NAME>SF)幼児朝食</NAME><CODE>9128</CODE></PRODUCT><PRODUCT ><NAME>会席料理200</NAME><CODE>0140</CODE></PRODUCT><PRODUCT ><NAME>調理長お任せ会席</NAME><CODE>0000000001101</CODE></PRODUCT></BUTTONTAB><CREATEINFO><LEADINFO NIGHTS="1"><ASSIGN FIELD="Field3__c">20:00</ASSIGN></LEADINFO><MERGEINFO><CLONE>comment3__c</CLONE></MERGEINFO></CREATEINFO></SHOP></root>';
    	Document item = new Document();
    	item.Name = 'OrderProductConfig';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(domString);
    	insert item;
    	return item;
	}
	public static void createRollParameter() {
		insert new Rollupparameter__c(FunctionName__c='TtendToCash',InActive__c=true);
	}
	
	public static Attachment createTa2waySyncAttachment(String parentId){
    	String infoTravelXml = '<AllotmentBookingReport>'+
		'<TransactionType>'+
		'    <DataFrom>FromTravelAgency</DataFrom>'+
		'    <DataClassification>NewBookReport</DataClassification>'+
		'    <BookingDataID>00000376578-B-20110429230900</BookingDataID>'+
		'    <SystemDate>2016-08-26</SystemDate>'+
		'    <SystemTime>16:23:12</SystemTime>'+
		'</TransactionType>'+
		'<AccommodationInformation>'+
		'    <AccommodationName>まごころの宿PMS連携テスト</AccommodationName>'+
		'    <AccommodationCode>01</AccommodationCode>'+
		'</AccommodationInformation>'+
		'<SalesOfficeInformation>'+
		'    <SalesOfficeCompanyCode>02</SalesOfficeCompanyCode>'+
		'    <SalesOfficeCompanyName>isaizu</SalesOfficeCompanyName>'+
		'    <SalesOfficeName>b</SalesOfficeName>'+
		'    <SalesOfficeCode>0000002</SalesOfficeCode>'+
		'    <SalesOfficePersonInCharge>i</SalesOfficePersonInCharge>'+
		'    <SalesOfficePhoneNumber>093</SalesOfficePhoneNumber>'+
		'</SalesOfficeInformation>'+
		'<BasicInformation>'+
		'    <TravelAgencyBookingNumber>0GAWPV0W</TravelAgencyBookingNumber>'+
		'    <TravelAgencyBookingDate>2011-04-29</TravelAgencyBookingDate>'+
		'    <TravelAgencyBookingTime>23:09:00</TravelAgencyBookingTime>'+
		'    <GuestOrGroupNameSingleByte>ﾋｶｸ ｼﾞﾛｳ</GuestOrGroupNameSingleByte>'+
		'    <GuestOrGroupNameDoubleByte>ひかく　じろう</GuestOrGroupNameDoubleByte>'+
		'    <GuestOrGroupNameKanjiName>比較　二郎</GuestOrGroupNameKanjiName>'+
		'    <CheckInDate>2011-05-27</CheckInDate>'+
		'    <CheckInTime>24:00</CheckInTime>'+
		'    <CheckOutDate>2011-05-30</CheckOutDate>'+
		'    <Nights>3</Nights>'+
		'    <PackagePlanName>☆★ダミープラン★☆</PackagePlanName>'+
		'    <PackagePlanCode>00829025</PackagePlanCode>'+
		'            <OtherServiceInformation>備考</OtherServiceInformation>'+
		'</BasicInformation>'+
		'<BasicRateInformation>'+
		'    <RoomRateOrPersonalRate>PersonalRate</RoomRateOrPersonalRate>'+
		'    <TaxServiceFee>IncludingServiceAndTax</TaxServiceFee>'+
		'    <Payment>現地決済</Payment>'+
		'    <TotalAccommodationCharge>24000</TotalAccommodationCharge>'+
		'</BasicRateInformation>'+
		' <RoomAndGuestInformation>'+
		'    <RoomAndGuestList>'+
		'    <RoomInformation>'+
		'                   <RoomTypeCode>DBL</RoomTypeCode>'+
		'      <RoomTypeName>【禁煙有線LAN】セミダブル</RoomTypeName>'+
		'      <PerRoomPaxCount>1</PerRoomPaxCount>'+
		'      <RoomPaxMaleCount>1</RoomPaxMaleCount>'+
		'      <RoomPaxFemaleCount>0</RoomPaxFemaleCount>'+
		'      <RoomChildA70Count>0</RoomChildA70Count>'+
		'      <RoomChildB50Count>0</RoomChildB50Count>'+
		'      <RoomChildC30Count>0</RoomChildC30Count>'+
		'      <RoomChildDNoneCount>0</RoomChildDNoneCount>'+
		'          </RoomInformation>'+
		'             <RoomRateInformation>'+
		'      <RoomDate>2011-05-27</RoomDate>'+
		'             <TotalPerRoomRate>8000</TotalPerRoomRate>'+
		'          </RoomRateInformation>'+
		'        <RoomRateInformation>'+
		'      <RoomDate>2011-05-28</RoomDate>'+
		'             <TotalPerRoomRate>8000</TotalPerRoomRate>'+
		'          </RoomRateInformation>'+
		'        <RoomRateInformation>'+
		'      <RoomDate>2011-05-29</RoomDate>'+
		'             <TotalPerRoomRate>8000</TotalPerRoomRate>'+
		'          </RoomRateInformation>'+
		'         <GuestInformation>'+
		'      <GuestInformationList>'+
		'        <GuestNameSingleByte>ﾋｶｸ ﾀﾛｳ</GuestNameSingleByte>'+
		'        <GuestSurName>ひかく　たろう</GuestSurName>'+
		'        <GuestKanjiName>比較　太郎</GuestKanjiName>'+
		'        <GuestPhoneNumber>03-3473-4345</GuestPhoneNumber>'+
		'        <GuestEmail>test@temairazu.com</GuestEmail>'+
		'        <GuestStateProvidence>東京都渋谷区恵比寿1-21-3</GuestStateProvidence>'+
		'        <GuestPostalCode>000-0000</GuestPostalCode>'+
		'      </GuestInformationList>'+
		'    </GuestInformation>'+
		'  </RoomAndGuestList>'+
		'   </RoomAndGuestInformation>'+
		' <Member>'+
		'  <UserName>比較　二郎</UserName>'+
		'  <UserKana>ﾋｶｸ ｼﾞﾛｳ</UserKana>'+
		'  <UserTel>03-3473-4345</UserTel>'+
		'  <UserMailAddr>test@temairazu.com</UserMailAddr>'+
		'  <UserZip>000-0000</UserZip>'+
		'  <UserAddr>東京都渋谷区恵比寿1-21-3</UserAddr>'+
		'  <UserCorp></UserCorp>'+
		'  <UserGivinPoints>0</UserGivinPoints>'+
		'  <UserUsePoints>0</UserUsePoints>'+
		'  <TotalAccommodationDecleasePoints>24000</TotalAccommodationDecleasePoints>'+
		'  <AmountClaimed>24000</AmountClaimed>'+
		'</Member>'+
		'</AllotmentBookingReport>';
    	String dateKey = System.now().format('yyMMddHHMMssSSS');
    	Attachment newAttach = new Attachment(
									ParentId = parentId,
									Name = 'TAPDATA_' + dateKey + '1_Test.xml', 
									ContentType = 'text/xml',
									Body = Blob.valueOf(infoTravelXML)
								);
		insert newAttach;
		return newAttach;
    }
    public static Attachment createTl2waySyncAttachment(String parentId){
    	String infoTravelXML = '<?xmlversion="1.0"encoding="UTF-8"standalone="yes"?><AllotmentBookingReport><TransactionType><DataFrom>FromTravelAgency</DataFrom><DataClassification>NewBookReport</DataClassification><DataID>101731864-1</DataID><SystemDate>2013-07-09</SystemDate></TransactionType><AccommodationInformation><AccommodationName>元湯陣屋</AccommodationName><AccommodationCode>14000010</AccommodationCode></AccommodationInformation><SalesOfficeInformation><SalesOfficeCompanyName>予約プロ</SalesOfficeCompanyName><SalesOfficeName>予約プロ</SalesOfficeName><SalesOfficeCode>88</SalesOfficeCode><SalesOfficePhoneNumber>052-262-8041</SalesOfficePhoneNumber></SalesOfficeInformation><BasicInformation><TravelAgencyBookingNumber>A001781590</TravelAgencyBookingNumber><TravelAgencyBookingDate>2013-07-09</TravelAgencyBookingDate><TravelAgencyBookingTime>23:47:14</TravelAgencyBookingTime><TravelAgencyReportNumber>00000051</TravelAgencyReportNumber><GuestOrGroupNameSingleByte>ﾃｽﾄﾖﾔｸ_</GuestOrGroupNameSingleByte><GuestOrGroupNameKanjiName>テスト予約No.2013/07/09_</GuestOrGroupNameKanjiName><CheckInDate>2013-07-22</CheckInDate><CheckInTime>15:30:00</CheckInTime><CheckOutDate>2013-07-25</CheckOutDate><Nights>3</Nights><TotalRoomCount>2</TotalRoomCount><GrandTotalPaxCount>14</GrandTotalPaxCount><TotalPaxMaleCount>2</TotalPaxMaleCount><TotalPaxFemaleCount>2</TotalPaxFemaleCount><TotalChildA70Count>2</TotalChildA70Count><TotalChildB50Count>4</TotalChildB50Count><TotalChildC30Count>2</TotalChildC30Count><TotalChildDNoneCount>2</TotalChildDNoneCount><PackagePlanName>【１泊朝食付】朝膳朝食付きプラン　チェックイン24:00までOK！</PackagePlanName><PackagePlanCode>3333</PackagePlanCode><MealCondition>1nightBreakfast</MealCondition><SpecificMealCondition>NoneSpecified</SpecificMealCondition><OtherServiceInformation>○携帯電話番号[MobilePhoneNumber]：00-2345-6789○ご要望・ご質問：NroomsNnightsのテストのため</OtherServiceInformation></BasicInformation><BasicRateInformation><RoomRateOrPersonalRate>PersonalRate</RoomRateOrPersonalRate><TaxServiceFee>IncludingServiceAndTax</TaxServiceFee><TotalAccommodationCharge>429135</TotalAccommodationCharge></BasicRateInformation><RoomAndGuestInformation><RoomAndGuestList><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount></RoomInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerChildB50Rate>0</PerChildB50Rate></RoomRateInformation></RoomAndGuestList><RoomAndGuestList><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>2</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount></RoomInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerChildB50Rate>0</PerChildB50Rate></RoomRateInformation></RoomAndGuestList><RoomAndGuestList><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount></RoomInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerChildB50Rate>0</PerChildB50Rate></RoomRateInformation></RoomAndGuestList><RoomAndGuestList><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>2</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount></RoomInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerChildB50Rate>0</PerChildB50Rate></RoomRateInformation></RoomAndGuestList><RoomAndGuestList><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount></RoomInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerChildB50Rate>0</PerChildB50Rate></RoomRateInformation></RoomAndGuestList><RoomAndGuestList><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>1</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount></RoomInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerChildB50Rate>0</PerChildB50Rate></RoomRateInformation></RoomAndGuestList></RoomAndGuestInformation><RisaplsInformation><RisaplsCommonInformation><Basic><SalesOfficeCompanyCode>88</SalesOfficeCompanyCode><TelegramDiv></TelegramDiv><RisaplsDataID></RisaplsDataID><RisaplsTelegramNumber></RisaplsTelegramNumber>';
    	infoTravelXML += '<TelegramData>予約通知予約プロSNT-NET07-0923:49(88)予約番号：A001781590NO.00000051元湯陣屋様(14000010)宿泊者情報：テスト予約No.2013/07/09_TEL:01-2345-6789ﾃｽﾄﾖﾔｸ_Mail:hiroyuki_morimoto@jinya-inn.com住所:(〒257-0001)神奈川県秦野市鶴巻北inn.com住所:(〒257-0001)神奈川県秦野市鶴巻北プラン名：【１泊朝食付】朝膳朝食付きプラン　チェックイン24:00までOK！(185)2013年07月22日から3泊朝食付サ込税込入込方法：チェックイン時間：15:30人員総数：14人内訳：(男)2名+(女)2名+(Ａ)2名+(Ｂ)4名+(Ｃ)2名+(Ｄ)2名客室総数：2室07月22日24(純和風客室(バスルーム無し))大人（男）1名@12,000大人（女）1名@12,000子供Ａ1名@12,000小学生子供Ｂ1名@12,000小児（食事布団あり）子供Ｂ1名@0小児（食事布団なし）子供Ｃ1名@3,000小児（食事のみ）子供Ｄ1名@10,000小児（布団のみ）24(純和風客室(バスルーム無し))大人（男）1名@12,000大人（女）1名@12,000子供Ａ1名@12,000小学生子供Ｂ1名@12,000小児（食事布団あり）子供Ｂ1名@0小児（食事布団なし）子供Ｃ1名@3,000小児（食事のみ）子供Ｄ1名@10,000小児（布団のみ）07月23日24(純和風客室(バスルーム無し))大人（男）1名@12,000大人（女）1名@12,000子供Ａ1名@12,000小学生子供Ｂ1名@12,000小児（食事布団あり）子供Ｂ1名@0小児（食事布団なし）子供Ｃ1名@3,000小児（食事のみ）子供Ｄ1名@10,000小児（布団のみ）24(純和風客室(バスルーム無し))大人（男）1名@12,000大人（女）1名@12,000子供Ａ1名@12,000小学生子供Ｂ1名@12,000小児（食事布団あり）子供Ｂ1名@0小児（食事布団なし）子供Ｃ1名@3,000小児（食事のみ）子供Ｄ1名@10,000小児（布団のみ）07月24日24(純和風客室(バスルーム無し))大人（男）1名@12,000大人（女）1名@12,000子供Ａ1名@12,000小学生子供Ｂ1名@12,000小児（食事布団あり）子供Ｂ1名@0小児（食事布団なし）子供Ｃ1名@3,000小児（食事のみ）子供Ｄ1名@10,000小児（布団のみ）24(純和風客室(バスルーム無し))大人（男）1名@12,000大人（女）1名@12,000子供Ａ1名@12,000小学生子供Ｂ1名@12,000小児（食事布団あり）子供Ｂ1名@0小児（食事布団なし）子供Ｃ1名@3,000小児（食事のみ）子供Ｄ1名@10,000小児（布団のみ）宿泊料金計：\\366,000オプション：07月22日特選会席料理4個@12,000お土産（陣屋どらやき　6個入）1個@960お土産（やまと豚の桜味噌漬け13個@1,575お土産（やまと豚の桜味噌漬け23個@3,150 オプション料金計：\\63,135合計料金：\\429,135【宿泊者への請求額】：\\429,135---------------------------------------------------------------------ご確認事項：○携帯電話番号[MobilePhoneNumber]：00-2345-6789○ご要望・ご質問：NroomsNnightsのテストのため取扱個所：予約プロ(88)TEL052-262-8041FAX052-262-8042---</TelegramData><PhoneNumber>01-2345-6789</PhoneNumber><Email>hiroyuki_morimoto@jinya-inn.com</Email>';
    	infoTravelXML += '<PostalCode>257-0001</PostalCode><Address>神奈川県秦野市鶴巻北</Address><TotalPaxManCount>4</TotalPaxManCount><BranchFaxNumber>052-262-8042</BranchFaxNumber><Version>2.0</Version><AccommodationId>X36969</AccommodationId></Basic><Allotment><AssignDiv>1</AssignDiv><GenderDiv>1</GenderDiv><HandleDiv>1</HandleDiv><RsvUserDiv>0</RsvUserDiv><UseDiv>0</UseDiv></Allotment><Option><OptionDate>2013-07-22</OptionDate><OptionCode>33</OptionCode><Name>特選会席料理</Name><OptionCount>4</OptionCount><OptionRate>12000</OptionRate></Option><Option><OptionDate>2013-07-22</OptionDate><Name>お土産（陣屋どらやき　6個入）</Name><OptionCount>1</OptionCount><OptionRate>960</OptionRate></Option><Option><OptionDate>2013-07-22</OptionDate><Name>お土産（やまと豚の桜味噌漬け10枚入）</Name><OptionCount>3</OptionCount><OptionRate>1575</OptionRate></Option><Option><OptionDate>2013-07-22</OptionDate><Name>お土産（やまと豚の桜味噌漬け20枚入）</Name><OptionCount>3</OptionCount><OptionRate>3150</OptionRate></Option><RoomAndRoomRateInformation><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount><RoomChildA70Request>小学生</RoomChildA70Request><RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request><RoomChildC30Request>小児（食事のみ）</RoomChildC30Request><RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest><RoomTypeAgent>88</RoomTypeAgent><RoomFrame>--</RoomFrame><NetRmTypeGroupCode>49</NetRmTypeGroupCode><PlanGroupCode>---</PlanGroupCode></RoomInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee><PerMaleRate>12000</PerMaleRate><PerFemaleRate>12000</PerFemaleRate><RoomRatePaxMaleCount>1</RoomRatePaxMaleCount><RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount><RoomRateChildA70Count>1</RoomRateChildA70Count><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildC30Count>1</RoomRateChildC30Count><RoomRateChildDNoneCount>1</RoomRateChildDNoneCount><RoomRateChildA70Request>小学生</RoomRateChildA70Request><RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request><RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request><RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerChildB50Rate>0</PerChildB50Rate><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request></RoomRateInformation></RoomAndRoomRateInformation><RoomAndRoomRateInformation><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount><RoomChildA70Request>小学生</RoomChildA70Request><RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request>';
    	infoTravelXML += '<RoomChildC30Request>小児（食事のみ）</RoomChildC30Request><RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest><RoomTypeAgent>88</RoomTypeAgent><RoomFrame>--</RoomFrame><NetRmTypeGroupCode>49</NetRmTypeGroupCode><PlanGroupCode>---</PlanGroupCode></RoomInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee><PerMaleRate>12000</PerMaleRate><PerFemaleRate>12000</PerFemaleRate><RoomRatePaxMaleCount>1</RoomRatePaxMaleCount><RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount><RoomRateChildA70Count>1</RoomRateChildA70Count><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildC30Count>1</RoomRateChildC30Count><RoomRateChildDNoneCount>1</RoomRateChildDNoneCount><RoomRateChildA70Request>小学生</RoomRateChildA70Request><RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request><RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request><RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerChildB50Rate>0</PerChildB50Rate><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request></RoomRateInformation></RoomAndRoomRateInformation><RoomAndRoomRateInformation><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount><RoomChildA70Request>小学生</RoomChildA70Request><RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request><RoomChildC30Request>小児（食事のみ）</RoomChildC30Request><RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest><RoomTypeAgent>88</RoomTypeAgent><RoomFrame>--</RoomFrame><NetRmTypeGroupCode>49</NetRmTypeGroupCode><PlanGroupCode>---</PlanGroupCode></RoomInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee><PerMaleRate>12000</PerMaleRate><PerFemaleRate>12000</PerFemaleRate><RoomRatePaxMaleCount>1</RoomRatePaxMaleCount><RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount><RoomRateChildA70Count>1</RoomRateChildA70Count><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildC30Count>1</RoomRateChildC30Count><RoomRateChildDNoneCount>1</RoomRateChildDNoneCount><RoomRateChildA70Request>小学生</RoomRateChildA70Request><RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request><RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request><RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerChildB50Rate>0</PerChildB50Rate><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request></RoomRateInformation></RoomAndRoomRateInformation><RoomAndRoomRateInformation><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount><RoomChildA70Request>小学生</RoomChildA70Request><RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request><RoomChildC30Request>小児（食事のみ）</RoomChildC30Request><RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest><RoomTypeAgent>88</RoomTypeAgent><RoomFrame>--</RoomFrame><NetRmTypeGroupCode>49</NetRmTypeGroupCode><PlanGroupCode>---</PlanGroupCode></RoomInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee><PerMaleRate>12000</PerMaleRate><PerFemaleRate>12000</PerFemaleRate><RoomRatePaxMaleCount>1</RoomRatePaxMaleCount><RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount><RoomRateChildA70Count>1</RoomRateChildA70Count><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildC30Count>1</RoomRateChildC30Count><RoomRateChildDNoneCount>1</RoomRateChildDNoneCount><RoomRateChildA70Request>小学生</RoomRateChildA70Request><RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request><RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request><RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerChildB50Rate>0</PerChildB50Rate><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request></RoomRateInformation></RoomAndRoomRateInformation><RoomAndRoomRateInformation><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount><RoomChildA70Request>小学生</RoomChildA70Request><RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request><RoomChildC30Request>小児（食事のみ）</RoomChildC30Request><RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest><RoomTypeAgent>88</RoomTypeAgent><RoomFrame>--</RoomFrame><NetRmTypeGroupCode>49</NetRmTypeGroupCode><PlanGroupCode>---</PlanGroupCode></RoomInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee><PerMaleRate>12000</PerMaleRate><PerFemaleRate>12000</PerFemaleRate><RoomRatePaxMaleCount>1</RoomRatePaxMaleCount><RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount><RoomRateChildA70Count>1</RoomRateChildA70Count><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildC30Count>1</RoomRateChildC30Count><RoomRateChildDNoneCount>1</RoomRateChildDNoneCount><RoomRateChildA70Request>小学生</RoomRateChildA70Request><RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request><RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request><RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerChildB50Rate>0</PerChildB50Rate><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request></RoomRateInformation></RoomAndRoomRateInformation><RoomAndRoomRateInformation><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount><RoomChildA70Request>小学生</RoomChildA70Request><RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request><RoomChildC30Request>小児（食事のみ）</RoomChildC30Request><RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest><RoomTypeAgent>88</RoomTypeAgent><RoomFrame>--</RoomFrame><NetRmTypeGroupCode>49</NetRmTypeGroupCode><PlanGroupCode>---</PlanGroupCode></RoomInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee><PerMaleRate>12000</PerMaleRate><PerFemaleRate>12000</PerFemaleRate><RoomRatePaxMaleCount>1</RoomRatePaxMaleCount><RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount><RoomRateChildA70Count>1</RoomRateChildA70Count><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildC30Count>1</RoomRateChildC30Count><RoomRateChildDNoneCount>1</RoomRateChildDNoneCount><RoomRateChildA70Request>小学生</RoomRateChildA70Request><RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request><RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request><RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerChildB50Rate>0</PerChildB50Rate><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request></RoomRateInformation></RoomAndRoomRateInformation><OtherInfo><GuestRequest>○携帯電話番号[MobilePhoneNumber]：00-2345-6789○ご要望・ご質問：NroomsNnightsのテストのため</GuestRequest></OtherInfo></RisaplsCommonInformation><AgentNativeInformation><Extend><AmountClaimed>429135</AmountClaimed></Extend><Extendmytrip><SettlementDiv>4</SettlementDiv></Extendmytrip></AgentNativeInformation></RisaplsInformation></AllotmentBookingReport>';
    	
    	String dateKey = System.now().format('yyMMddHHMMssSSS');
    	Attachment newAttach = new Attachment(
									ParentId = parentId,
									Name = 'TLPDATA_' + dateKey + '1_Test.xml', 
									ContentType = 'text/xml',
									Body = Blob.valueOf(infoTravelXML)
								);
		insert newAttach;
		return newAttach;
    }
    public static document createDeviceConfigXml() {
        String configXml = '<?xml version="1.0" encoding="UTF-8"?>'+
'<root><SHOP><SHOPCODE></SHOPCODE>'+
'<ACCOUNT><CONFIG><CHARGE>TRUE</CHARGE><POSPRINT>TRUE</POSPRINT></CONFIG></ACCOUNT>'+
'<CASH><CONFIG><CHARGE>TRUE</CHARGE><POSPRINT>TRUE</POSPRINT><EDITABLE>TRUE</EDITABLE></CONFIG></CASH>'+  
'<SIMPLEACCOUNT><CONFIG><POSPRINT>TRUE</POSPRINT></CONFIG></SIMPLEACCOUNT></SHOP></root>';

        // ドキュメントを作成する
        Document item = new Document();
        item.Name = 'DeviceConfigXml';
        item.DeveloperName = item.Name;
        item.FolderId = UserInfo.getUserId();
        item.Body = Blob.valueOf(configXml);
        insert item;
        return item;
    }
    
    public static void createConfigDoc() {
        String configXml = '<?xml version="1.0" encoding="UTF-8"?><root><SpicalReg>^(015420|015421|015422|015423|015424|015425|015431|015432|015435|015436|015437|015438|015439|015440|015441|015442|015443|015444|015445|015446|015447|015451|015452|015453|015454|015455|015456|015457|015459|015460|015461|015462|015463|015464|015465|015466|015467|015468|015469|015491|015492|015495|015498|015499|015472|015473|015475|015476|015477|015478|015479|022320|022321|022322|022323|022324|022325|022326|022327|022328|022329|022330|022331|022332|022333|022334|022335|022336|022337|022338|022339|025570|025572|025573|025574|025575|025577|025578|025579|025581|025582|025583|025585|025586|025587|025588|025720|025721|025722|025723|025724|025725|025726|025727|025728|025729|025730|025731|025732|025733|025735|025737|025738|025741|025743|025745|025747|025748|026121|026122|026123|026125|026126|026129|026161|026162|026166|026171|026172|026174|026175|026178|026182|026183|026185|026188|026421|026422|026423|026424|026425|026426|026427|026433|026434|026436|026440|026441|026442|026444|026446|026447|026448|026452|026454|026455|026457|026458|026459|027820|027821|027822|027823|027824|027825|027830|027833|027840|027850|027852|027853|027854|027856|027858|027860|027862|027864|027866|027872|027875|027877|027878|027879|028320|028321|028322|028323|028324|028325|028326|028327|028353|028355|028357|028361|028362|028365|028366|028367|028378|028380|028384|028385|028386|028387|028388|028390|028391|028960|028962|028963|028964|028965|028966|028970|028971|028972|028973|028974|028975|028976|028977|028978|028982|028983|028984|028985|028986|028988|028990|028991|028993|028995|028999|029117|029130|029131|029132|029133|029134|029135|029136|029137|029139|029140|029144|029320|029322|029323|029324|029327|029328|029330|029332|029333|029335|029337|029340|029341|029342|029343|029344|029346|042200|042201|042202|042207|042208|042300|042301|042302|042303|042304|042306|042307|042308|042309|042310|042311|042312|042313|042314|042315|042316|042317|042318|042319|042320|042321|042322|042323|042324|042325|042326|042327|042328|042329|042330|042331|042332|042333|042334|042335|042336|042337|042338|042339|042340|042341|042342|042343|042344|042345|042346|042347|042348|042349|042350|042351|042352|042353|042354|042355|042356|042357|042358|042359|042360|042361|042362|042363|042364|042365|042366|042367|042368|042369|042370|042371|042372|042373|042374|042375|042376|042377|042378|042379|042380|042381|042382|042383|042384|042385|042386|042387|042388|042389|042390|042391|042392|042393|042394|042395|042396|042397|042398|042399|042400|042401|042402|042403|042404|042405|042406|042407|042408|042409|042410|042417|042420|042421|042422|042423|042424|042425|042426|042427|042428|042429|042430|042431|042432|042433|042436|042437|042438|042439|042440|042441|042442|042443|042444|042445|042446|042448|042449|042450|042451|042452|042453|042454|042455|042456|042457|042458|042459|042460|042461|042462|042463|042464|042465|042466|042467|042468|042469|042470|042471|042472|042473|042474|042475|042476|042477|042478|042479|042480|042481|042482|042483|042484|042485|042486|042487|042488|042489|042490|042491|042492|042493|042494|042495|042496|042497|042498|042499|042500|042501|042502|042503|042504|042505|042506|042507|042508|042510|042511|042512|042513|042514|042515|042516|042517|042518|042519|042520|042521|042522|042523|042524|042525|042526|042527|042528|042529|042530|042531|042532|042533|042534|042535|042536|042537|042538|042539|042540|042541|042542|042543|042544|042545|042546|042547|042548|042549|042550|042551|042552|042553|042554|042555|042556|042557|042558|042559|042560|042561|042562|042563|042564|042565|042566|042567|042568|042569|042570|042571|042572|042573|042574|042575|042576|042577|042578|042579|042580|042581|042582|042583|042584|042585|042586|042587|042588|042589|042590|042591|042592|042593|042594|042595|042596|042597|042598|042599|042610|042615|042617|042620|042621|042622|042623|042624|042625|042626|042627|042628|042629|042631|042632|042633|042634|042635|042636|042637|042638|042639|042641|042642|042643|042644|042645|042646|042648|042649|042650|042651|042652|042653|042654|042655|042656|042657|042658|042659|042660|042661|042662|042663|042664|042665|042666|042667|042668|042669|042670|042671|042673|042674|042675|042676|042677|042678|042679|042680|042681|042682|042683|042684|042685|042686|042687|042688|042689|042690|042691|042692|042693|042694|042695|042696|042697|042698|042699|042700|042701|042702|042703|042704|042705|042706|042707|042708|042709|042710|042711|042712|042713|042714|042715|042716|042717|042718|042719|042720|042721|042722|042723|042724|042725|042726|042727|042728|042729|042730|042731|042732|042733|042734|042735|042736|042737|042738|042739|042740|042741|042742|042743|042744|042745|042746|042747|042748|042749|042750|042751|042752|042753|042754|042755|042756|042757|042758|042759|042760|042761|042762|042763|042764|042765|042766|042767|042768|042769|042770|042771|042772|042773|042774|042775|042776|042777|042778|042779|042780|042781|042782|042783|042784|042785|042786|042787|042788|042789|042790|042791|042792|042793|042794|042795|042796|042797|042798|042799|042800|042803|042806|042808|042810|042812|042813|042814|042815|042816|042817|042840|042841|042842|042843|042844|042845|042846|042847|042848|042849|042850|042851|042852|042853|042854|042855|042856|042858|042859|042860|042861|042862|042863|042865|042866|042868|042869|042911|042917|042919|042970|042971|042972|042973|042974|042975|042976|042977|042978|042979|042980|042981|042982|042983|042984|042985|042986|042987|042988|042989|047300|047301|047302|047303|047304|047305|047306|047307|047308|047309|047310|047311|047312|047313|047314|047315|047316|047317|047318|047319|047320|047321|047322|047323|047324|047325|047326|047327|047328|047329|047330|047331|047332|047333|047334|047335|047336|047337|047338|047339|047340|047341|047342|047343|047344|047345|047346|047347|047348|047349|047350|047351|047352|047353|047354|047355|047356|047357|047358|047359|047360|047361|047362|047363|047364|047365|047366|047367|047368|047369|047370|047371|047372|047373|047374|047375|047376|047377|047378|047379|047380|047381|047382|047383|047384|047385|047386|047387|047388|047389|047390|047391|047392|047393|047394|047395|047396|047397|047398|047399|047400|047401|047402|047403|047404|047405|047406|047407|047408|047409|047410|047411|047412|047413|047419|047420|047421|047422|047423|047424|047425|047426|047427|047428|047429|047430|047431|047432|047433|047434|047435|047436|047437|047438|047439|047440|047441|047442|047443|047444|047445|047446|047447|047448|047449|047450|047451|047452|047453|047454|047455|047456|047457|047458|047459|047460|047461|047462|047463|047464|047465|047466|047467|047468|047469|047470|047471|047472|047473|047474|047475|047476|047477|047478|047479|047480|047481|047482|047483|047484|047485|047486|047487|047488|047489|047490|047491|047492|047493|047494|047495|047496|047497|047498|047499|047700|047701|047702|047703|047704|047705|047706|047707|047708|047709|047710|047711|047712|047713|047716|047717|047718|047720|047721|047722|047723|047724|047727|047729|047750|047751|047752|047754|047755|047758|047767|047769|047770|047773|047774|047775|047778|047779|047020|047022|047023|047024|047025|047027|047028|047029|047030|047031|047033|047036|047037|047038|047040|047041|047043|047044|047046|047047|047049|047050|047051|047053|047055|047057|047058|047060|047062|047063|047064|047066|047067|047068|047070|047071|047073|047074|047075|047076|047077|047080|047082|047083|047084|047085|047086|047087|047088|047520|047522|047523|047524|047525|047526|047527|047528|047530|047531|047532|047533|047534|047535|047536|047537|047538|047539|047540|047542|047543|047544|047546|047547|047548|047550|047551|047552|047553|047554|047555|047557|047558|047560|047566|047567|047568|047570|047571|047572|047573|047576|047577|047578|047580|047581|047582|047584|047585|047586|047587|047588|047589|047620|047621|047622|047623|047624|047626|047627|047628|047629|047630|047631|047632|047633|047634|047635|047636|047637|047640|047642|047645|047646|047647|047648|047649|047650|047655|047656|047658|047666|047670|047671|047672|047673|047676|047677|047680|047685|047688|047689|047690|047691|047692|047693|047694|047695|047696|047697|047698|047699|047850|047851|047852|047854|047855|047856|047857|047858|047859|047860|047868|047870|047871|047872|047873|047875|047877|047878|047879|047880|047882|047883|047886|047887|047888|047920|047921|047922|047923|047924|047925|047926|047927|047930|047931|047933|047935|047939|047940|047944|047946|047948|047950|047951|047952|047955|047957|047960|047961|047962|047963|047964|047966|047967|047968|047970|047971|047972|047973|047974|047975|047976|047977|047978|047979|047980|047982|047984|047985|047986|047987|047988|042220|042221|042222|042223|042224|042225|042226|042227|042228|042229|042230|042231|042232|042233|042234|042235|042236|042237|042238|042239|042240|042241|042242|042243|042244|042245|042246|042247|042248|042249|042250|042251|042252|042253|042254|042255|042256|042257|042258|042259|042260|042266|042267|042268|042269|042270|042271|042272|042274|042275|042276|042277|042278|042279|042287|042288|042290|042291|042820|042821|042822|042823|042824|042825|042826|042827|042828|042830|042831|042832|042833|042834|042835|042836|042838|042874|042875|042876|042877|042878|042879|042882|042883|042884|042885|042886|042887|042888|042890|042891|042898|053962|053963|053974|053977|059920|059921|059922|059924|059925|059926|059928|059932|059933|059934|059937|059938|059943|059944|059945|059946|059947|059952|059953|059954|059955|059956|059957|059958|059959|059964|059965|059966|059967|059968|059969|059972|059973|059977|059978|059984|059985|059988|059989|059792|059793|059794|059795|059796|059799|079460|079461|079462|079463|079464|079465|079466|079467|079468|079469|079470|079471|079472|079473|079474|079475|079476|079477|079478|079480|079481|079482|079483|079484|079485|079486|079487|079488|079489|079520|079521|079522|079523|079524|079525|079526|079527|079528|079529|079530|079532|079533|079534|079535|079536|079537|079538|079539|079540|079542|079543|079544|079545|079546|079547|079548|079549|079570|079571|079572|079573|079574|079575|079576|079577|079578|079579|079580|079581|079582|079583|079585|079586|079587|079588|079589|079520|079521|079522|079523|079524|079525|079526|079527|079528|079529|079530|079532|079533|079534|079535|079536|079537|079538|079539|079540|079542|079543|079544|079545|079546|079547|079548|079549|079570|079571|079572|079573|079574|079575|079576|079577|079578|079579|079580|079581|079582|079583|079585|079586|079587|079588|079589|079620|079621|079622|079623|079624|079626|079627|079628|079629|079632|079633|079634|079636|079637|079638|079639|079642|079643|079644|079645|079647|079648|079652|079653|079654|079655|079656|079657|079658|079680|079682|079683|079685|079686|079687|079688|079692|079693|079694|079695|079696|079697|079698|079699|082442|082443|082444|082448|082451|082452|082453|082454|082455|082456|082458|082462|082463|082464|082465|082466|082467|082468|082469|082470|082472|082473|082474|082475|082476|082478|082481|082482|082483|082484|082485|082486|082487|082488|082489|082920|082930|082931|082932|082934|082935|082936|082937|082938|082939|082940|082944|082945|082950|082951|082952|082954|082955|082956|082958|082959|082970|082972|082974|082977|082978|082983|082985|082986|082987|082988|083621|083622|083629|083631|083632|083633|083634|083635|083636|083637|083638|083639|083640|083641|083643|083644|083645|083648|083651|083652|083653|083654|083655|083658|083659|083660|083662|083664|083665|083666|083667|083668|083669|083671|083672|083673|083674|083675|083676|083677|083678|083679|083681|083682|083683|083684|083685|083688|083689|083691|083693|083698|083721|083722|083723|083725|083726|083727|083728|083729|083732|083733|083734|083735|083736|083737|083738|083742|083743|083748|083752|083753|083754|083755|083756|083757|083758|083760|083762|083763|083764|083765|083769|083962|083965|083967|083968|086321|086323|086330|086331|086332|086333|086341|086343|086351|086353|086355|086366|086371|086373|086376|086377|086381|086383|086388|086542|086543|086544|086545|086547|086548|086554|086558|086560|086561|086562|086563|086564|086565|086566|086567|086568|086569|086570|086571|086572|086575|086578|086621|086622|086623|086625|086626|086628|086629|086631|086632|086633|086634|086637|086638|086642|086645|086646|086648|086651|086652|086654|086655|086656|086657|086658|086662|086663|086665|086666|086667|086672|086673|086674|086675|086677|086682|086683|086684|086687|086688|086690|086692|086693|086694|086695|086696|086699|086725|086727|086733|086734|086735|086736|086740|086741|086742|086744|086745|086746|086752|086753|086754|086755|086756|086757|086758|086762|086765|086766|086767|086768|086770|086771|086772|086773|086774|086775|086776|086777|086778|086788|086792|086793|086794|086795|086796|086798|086820|086821|086822|086823|086824|086825|086826|086827|086828|086829|086830|086831|086832|086833|086835|086836|086837|086838|086839|086842|086844|086846|086848|086852|086854|086855|086856|086857|086858|086862|086864|086866|086867|086868|086869|086871|086872|086873|086874|086875|086876|086877|086878|086879|086880|086888|086921|086922|086924|086925|086926|086928|086934|086960|086962|086963|086964|086965|086966|086967|086969|086972|086974|086978|086984|086985|086988|086989|086992|086993|099321|099322|099323|099324|099325|099326|099327|099328|099332|099333|099334|099335|099336|099337|099338|099339|099340|099341|099349|099351|099352|099353|099355|099356|099357|099358|099359|099362|099363|099364|099366|099367|099368|099372|099373|099376|099377|099378|099383|099384|099385|099386|099387|099388|099389|099420|099422|099423|099424|099425|099426|099427|099428|099429|099430|099431|099432|099433|099434|099435|099436|099437|099438|099440|099441|099442|099443|099444|099445|099446|099447|099448|099449|099451|099452|099453|099455|099458|099462|099463|099465|099467|099468|099490|099491|099498)</SpicalReg><RegTag template="5-1-4">^(01267|01372|01374|01377|01392|01397|01398|01456|01457|01466|01558|01564|01586|01587|01632|01634|01635|01648|01654|01655|01656|01658|04992|04994|04996|04998|05769|07468|08387|08388|08477|08512|08514|09496|09802|09912|09913|09969)</RegTag><RegTag template="4-2-4">^(0123|0124|0125|0126|0133|0134|0135|0136|0137|0138|0139|0142|0143|0144|0145|0146|0152|0153|0155|0156|0157|0158|0162|0163|0164|0165|0166|0167|0172|0173|0174|0175|0176|0178|0179|0182|0183|0184|0185|0186|0187|0191|0192|0193|0194|0195|0197|0198|0220|0224|0225|0226|0228|0229|0233|0234|0235|0237|0238|0240|0241|0242|0243|0244|0246|0247|0248|0250|0254|0256|0258|0259|0260|0263|0265|0266|0267|0268|0269|0270|0274|0276|0277|0279|0280|0282|0284|0285|0287|0288|0294|0295|0296|0297|0299|0436|0438|0439|0460|0463|0465|0466|0467|0480|0493|0494|0495|0531|0532|0533|0536|0537|0538|0544|0545|0547|0548|0550|0551|0553|0554|0555|0556|0557|0558|0561|0562|0563|0564|0565|0566|0567|0568|0569|0572|0573|0574|0575|0576|0577|0578|0581|0584|0585|0586|0587|0594|0595|0596|0597|0598|0721|0725|0735|0736|0737|0738|0739|0740|0742|0743|0744|0745|0746|0747|0748|0749|0761|0763|0765|0766|0767|0768|0770|0771|0772|0773|0774|0776|0778|0779|0790|0791|0797|0798|0799|0820|0823|0826|0827|0833|0834|0835|0838|0845|0846|0847|0848|0852|0853|0854|0855|0856|0857|0858|0859|0875|0877|0879|0880|0883|0884|0885|0887|0889|0892|0893|0894|0895|0896|0897|0898|0920|0942|0943|0944|0946|0947|0948|0949|0950|0952|0954|0955|0956|0957|0959|0964|0965|0966|0967|0968|0969|0972|0973|0974|0977|0978|0979|0980|0982|0983|0984|0985|0986|0987|0995|0996|0997)</RegTag><RegTag template="3-3-4">^(011|015|017|018|019|022|023|024|025|026|027|028|029|043|044|045|046|048|049|052|053|054|055|058|059|072|073|075|076|077|078|079|082|083|084|086|087|088|089|092|093|095|096|097|098|099)</RegTag><RegTag template="2-4-4">^(03|04|06)</RegTag></root>';
        // ドキュメントを作成する
        Document item = new Document();
        item.Name = 'PhoneConfig';
        item.DeveloperName = item.Name;
        item.FolderId = UserInfo.getUserId();
        item.Body = Blob.valueOf(configXml);
        insert item;
    }
    public static void createConfigSimple(){
    	String configXml = '<?xml version="1.0" encoding="UTF-8"?><root>	<SHOP>		<SHOPCODE></SHOPCODE>        <BUTTONTAB>  <BUTTON>				<LABEL>現金</LABEL>				<PRODCODE>M99000</PRODCODE>  </BUTTON>  <BUTTON> <LABEL>Master</LABEL> <PRODCODE>M90002</PRODCODE>  </BUTTON>  <BUTTON> <LABEL>JCB</LABEL> <PRODCODE>M90003</PRODCODE>  </BUTTON>        </BUTTONTAB>        <BUTTONTAB>  <BUTTON> <LABEL>陣屋商品券</LABEL> <PRODCODE>M90209</PRODCODE>  </BUTTON>        </BUTTONTAB>	</SHOP></root>';
    	// ドキュメントを作成する
        Document item = new Document();
        item.Name = 'SimplePaymentConfig';
        item.DeveloperName = item.Name;
        item.FolderId = UserInfo.getUserId();
        item.Body = Blob.valueOf(configXml);
        insert item;
    }
    // BatchRequestBatchの設定ファイルを作成
    public static void createBatchRequestXml() {
        String configXml = '<?xml version="1.0" encoding="utf-8"?><root><SHOP><SHOPCODE></SHOPCODE><REQUEST_BATCH><BATCH FROMTO="TRUE" TIMETERM="今日"><LABEL>FROMTOBATCH</LABEL><BATCHKEY>ChargeBatch</BATCHKEY><BATCHKEY>PCABatch</BATCHKEY><BATCHKEY>KanBatch</BATCHKEY><BATCHKEY>FREEEBatch</BATCHKEY></BATCH></REQUEST_BATCH></SHOP></root>';
        // ドキュメントを作成する
        Document item = new Document();
        item.Name = 'BatchRequstConfigXml';
        item.DeveloperName = item.Name;
        item.FolderId = UserInfo.getUserId();
        item.Body = Blob.valueOf(configXml);
        insert item;
	}
	public static void createWsServiceConfigXML(){
		//String configXml = '<?xml version="1.0" encoding="UTF-8"?><root>	<SHOP>		<SHOPCODE>01</SHOPCODE>		<APPCONFIG>			<UCACTISSYNC>TRUE</UCACTISSYNC>			<ROOMAUTOASSIGN>FALSE</ROOMAUTOASSIGN>			<ROOMSORT>DESC</ROOMSORT>			<RESET_ESTITEMS>FALSE</RESET_ESTITEMS>			<CHGROMANTOKANA>FALSE</CHGROMANTOKANA>		</APPCONFIG>		<ACCOUNTCONFIG>			<NYUUTOUACCOUNT></NYUUTOUACCOUNT>			<SERVICEACCOUNT></SERVICEACCOUNT>		</ACCOUNTCONFIG>		<CONTACT_INFO_PARSE>			<PARSE_LOGIC_INFO AGTCODE="">				<KEYWORD>携帯電話;Mobile Phone Number;TEL:</KEYWORD>					<FORMAT>((090|080|070)[-| ]?\\d{4}[-| ]?\\d{4})</FORMAT>				<TOFIELD>Contact.Phone</TOFIELD>					<EXCLUDEVAL></EXCLUDEVAL>			</PARSE_LOGIC_INFO>			<PARSE_LOGIC_INFO AGTCODE=""><KEYWORD>誕生日;Birthday</KEYWORD>	<FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日;([0-9]{4})-([0-9]{1,2})-([0-9]{1,2});([0-9]{4})/([0-9]{1,2})/([0-9]{1,2})</FORMAT>				<TOFIELD>Contact.Birthday</TOFIELD>				<EXCLUDEVAL></EXCLUDEVAL>			</PARSE_LOGIC_INFO>		</CONTACT_INFO_PARSE>		<PAYMENT_CONVERTS>			<POINT_CONVERT PAYKBN="3">			          <CONVERT AGTCODE="80">M90201</CONVERT>			</POINT_CONVERT>			<PAYMENT_CONVERT PAYKBN="2">		          <CONVERT AGTCODE="80">M90201</CONVERT>			</PAYMENT_CONVERT>	     </PAYMENT_CONVERTS>	     <HTML_EMAIL_TEM>			部屋数：$$__ROOMNUM__$$部屋			　 （大人）$$__GROWNUP__$$名 (男性:$$__MAN__$$名　女性:$$__FEMAILS__$$名)			　 （子供A）$$__CHILDA__$$名			　 （子供B）$$__CHILDB__$$名			　 （子供C）$$__CHILDC__$$名			　 （子供D）$$__CHILDD__$$名			　 合計：$$__AMOUT__$$円			$$__AMOUT__$$:集计明细的合计值		   $$__ROOMNUM__$$:集计房间数量		   $$__MADDRESS__$$:地址信息的处理(住所(郵送先))		   $$__OADDRESS__$$:地址信息的处理(住所(その他))		   $$__CHECKIN__$$:チェックイン日		   $$__CHECKOUT__$$:チェックアウト日		   		  		  その他 料金表：$$__Field271__c__$$[料]要注意：$$__Field305__c__$$お客様住所：$$__ContactAddress__c__$$料理補足：$$__Field354__c__$$日本消費税：$$__ExchangeTaxRate__c__$$お客様Email：$$__ContactEmail__c__$$特記事項：$$__Comment3__c__$$所感：$$__Comment1__c__$$マッサージ：$$__Field16__c__$$お客様ステータス：$$__Field298__c__$$交通手段：$$__Field348__c__$$SearchDate：$$__SearchDate__c__$$VB_確認日時：$$__VBCheckTime__c__$$お客様Phone：$$__ContactPhone__c__$$会議室料：$$__Field279__c__$$小人A：$$__ChildFA__c__$$小人B：$$__Childs__c__$$小人C：$$__ChildC__c__$$小人D：$$__ChildD__c__$$小人E：$$__ChildE__c__$$小人F：$$__ChildF__c__$$女性：$$__Femails__c__$$男性：$$__Mans__c__$$出発時刻：$$__Field3__c__$$到着時刻：$$__Field4__c__$$Fax：$$__Relcontact__r.Fax__$$喫煙区分：$$__Relcontact__r.SmokeFlg__c__$$Languages：$$__Relcontact__r.Languages__c__$$アレルギーの内容：$$__Relcontact__r.DetailedAllergy__c__$$メール：$$__Relcontact__r.Email__$$コメント：$$__Relcontact__r.Field1__c__$$性別：$$__Relcontact__r.gender__c__$$DM許可：$$__Relcontact__r.DM__c__$$Usage Charge：$$__Relcontact__r.Usage_Charge__c__$$携帯：$$__Relcontact__r.MobilePhone__$$電話：$$__Relcontact__r.Phone__$$申込者電話：$$__Relcontact__r.ApplicantPhone__c__$$誕生日：$$__Relcontact__r.Birthdate__$$結婚記念日：$$__Relcontact__r.WeddingAnniversary__c__$$作成日：$$__Relcontact__r.CreatedDate__$$名前：$$__Relcontact__r.Name__$$説明：$$__Relcontact__r.Description__$$Usage Count：$$__Relcontact__r.Usage_Count__c__$$			</HTML_EMAIL_TEM>	</SHOP>	</root>';
		String configXml = '<?xml version="1.0" encoding="UTF-8"?><root>	<SHOP>		<SHOPCODE>01</SHOPCODE>		<APPCONFIG>			<UCACTISSYNC>TRUE</UCACTISSYNC>			<ROOMAUTOASSIGN>FALSE</ROOMAUTOASSIGN>			<ROOMSORT>DESC</ROOMSORT>			<RESET_ESTITEMS>FALSE</RESET_ESTITEMS>			<CHGROMANTOKANA>FALSE</CHGROMANTOKANA>		</APPCONFIG>		<ACCOUNTCONFIG>			<NYUUTOUACCOUNT></NYUUTOUACCOUNT>			<SERVICEACCOUNT></SERVICEACCOUNT>		</ACCOUNTCONFIG>		<CONTACT_INFO_PARSE>			<PARSE_LOGIC_INFO AGTCODE="">				<KEYWORD>携帯電話;Mobile Phone Number;TEL:</KEYWORD>					<FORMAT>((090|080|070)[-| ]?\\d{4}[-| ]?\\d{4})</FORMAT>				<TOFIELD>Contact.Phone</TOFIELD>					<EXCLUDEVAL></EXCLUDEVAL>			</PARSE_LOGIC_INFO>			<PARSE_LOGIC_INFO AGTCODE=""><KEYWORD>誕生日;Birthday</KEYWORD>	<FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日;([0-9]{4})-([0-9]{1,2})-([0-9]{1,2});([0-9]{4})/([0-9]{1,2})/([0-9]{1,2})</FORMAT>				<TOFIELD>Contact.Birthday</TOFIELD>				<EXCLUDEVAL></EXCLUDEVAL>			</PARSE_LOGIC_INFO>		</CONTACT_INFO_PARSE>		<PAYMENT_CONVERTS>			<POINT_CONVERT PAYKBN="3">			          <CONVERT AGTCODE="80">M90201</CONVERT>			</POINT_CONVERT>			<PAYMENT_CONVERT PAYKBN="2">		          <CONVERT AGTCODE="80">M90201</CONVERT>			</PAYMENT_CONVERT>	     </PAYMENT_CONVERTS>	     <HTML_EMAIL_TEM>			部屋数：$$__ROOMNUM__$$部屋			　 （大人）$$__GROWNUP__$$名 (男性:$$__MAN__$$名　女性:$$__FEMAILS__$$名)			　 （子供A）$$__CHILDA__$$名			　 （子供B）$$__CHILDB__$$名			　 （子供C）$$__CHILDC__$$名			　 （子供D）$$__CHILDD__$$名			　 合計：$$__AMOUT__$$円			$$__AMOUT__$$:集计明细的合计值		   $$__ROOMNUM__$$:集计房间数量		   $$__MADDRESS__$$:地址信息的处理(住所(郵送先))		   $$__OADDRESS__$$:地址信息的处理(住所(その他))		   $$__CHECKIN__$$:チェックイン日		   $$__CHECKOUT__$$:チェックアウト日		   		  		  その他 料金表：$$__Field271__c__$$[料]要注意：$$__Field305__c__$$お客様住所：$$__ContactAddress__c__$$料理補足：$$__Field354__c__$$日本消費税：$$__ExchangeTaxRate__c__$$お客様Email：$$__ContactEmail__c__$$特記事項：$$__Comment3__c__$$所感：$$__Comment1__c__$$マッサージ：$$__Field16__c__$$お客様ステータス：$$__Field298__c__$$交通手段：$$__Field348__c__$$SearchDate：$$__SearchDate__c__$$VB_確認日時：$$__VBCheckTime__c__$$お客様Phone：$$__ContactPhone__c__$$会議室料：$$__Field279__c__$$小人A：$$__ChildFA__c__$$小人B：$$__Childs__c__$$小人C：$$__ChildC__c__$$小人D：$$__ChildD__c__$$小人E：$$__ChildE__c__$$小人F：$$__ChildF__c__$$女性：$$__Femails__c__$$男性：$$__Mans__c__$$出発時刻：$$__Field3__c__$$到着時刻：$$__Field4__c__$$Fax：$$__Relcontact__r.Fax__$$喫煙区分：$$__Relcontact__r.SmokeFlg__c__$$Languages：$$__Relcontact__r.Languages__c__$$アレルギーの内容：$$__Relcontact__r.DetailedAllergy__c__$$メール：$$__Relcontact__r.Email__$$コメント：$$__Relcontact__r.Field1__c__$$性別：$$__Relcontact__r.gender__c__$$DM許可：$$__Relcontact__r.DM__c__$$Usage Charge：$$__Relcontact__r.Usage_Charge__c__$$携帯：$$__Relcontact__r.MobilePhone__$$電話：$$__Relcontact__r.Phone__$$申込者電話：$$__Relcontact__r.ApplicantPhone__c__$$誕生日：$$__Relcontact__r.Birthdate__$$結婚記念日：$$__Relcontact__r.WeddingAnniversary__c__$$作成日：$$__Relcontact__r.CreatedDate__$$名前：$$__Relcontact__r.Name__$$説明：$$__Relcontact__r.Description__$$Usage Count：$$__Relcontact__r.Usage_Count__c__$$			</HTML_EMAIL_TEM>	'+
'<PMS_EMAIL ALLROOMCNT="FALSE" LEADWHERE="">'+
'<HEAD>'+
'=========================='+
'＜料金明細＞'+
'=========================='+
'	     	</HEAD>'+
'	     	<DETAIL ROOMDATE_FORMAT="yyyy年MM月dd日">'+
' 部屋数：$__部屋数__$'+
' $__#大人人数__$名 (男性:$__大人人員(男性)__$名　女性:$__大人人員(女性)__$名)'+
' ＋ （子供A）x $__子供A人数__$名'+
' ＋ （子供B）x $__子供B人数__$名'+
' ＋ （幼児食事布団あり）x $__子供C人数__$名'+
' ＋ （幼児食事布団なし）x $__子供D人数__$名'+
' 小計：$__#料金小計__$円'+
' 	     	</DETAIL>'+
' 	     	<FOOT>'+
'=========================='+
'合計：$__#料金合計__$円（税込・サービス料込）'+
'=========================='+
'	     	</FOOT></PMS_EMAIL>'+
		+'</SHOP>	</root>';
        // ドキュメントを作成する
        Document item = new Document();
        item.Name = 'WSServiceConfigXml';
        item.DeveloperName = item.Name;
        item.FolderId = UserInfo.getUserId();
        item.Body = Blob.valueOf(configXml);
        insert item;
	}
}