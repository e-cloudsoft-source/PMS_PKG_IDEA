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
private class BookingLeadWindowTest {

    static testMethod void myUnitTest1() {
        // TO DO: implement unit test
        createDocument();
	    BookingLeadWindow book = new BookingLeadWindow();
	    book.getInitXmlNode();
	    book.staysNums = null;
	    book.startDays = '2016/07/27';
	    Date entryDate = null;
	    Date curDay = entryDate == null ? Date.today() : entryDate;
    	DateTime startDate = DateTime.newInstance(curDay, Time.newInstance(0, 0, 0, 0));
    	Room__c room = TestCommon.createRooms();
    	// 連泊データを自動作成
    	book.newCustomLead = new Lead__c(
    	   RecordTypeId = CommLogicProcess.getLeadBookingRecType(),
    	   name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
    	   Relcontact__c = TestCommon.createContact().Id,    // 顧客名
    	   ReservedDate__c = System.now(),
    	   ReservedContact__c = 'Ono',
    	   EntryTime__c = startDate.addDays(-1),
    	   Field4__c = '15:30',
    	   Departure__c = startDate,
    	   Field3__c = '10:00',
    	   Field310__c = TestCommon.createPlan().Id,
    	   StayPersons__c = 3,
    	   Rroom__c = room.Id);
    	/*List<Lead__c> updLead = [select Id, Rroom__c from lead__c];
    	for(Lead__c newCustomLead : updLead){
			newCustomLead.Rroom__c = room.Id;
			book.newCustomLead = newCustomLead;
		}*/

	   // book.refeshDomNode();
	    book.bookingLeadCreate();
    	
    }
    static testMethod void myUnitTest2() {
        // TO DO: implement unit test
        createDocument1();
        BookingLeadWindow book = new BookingLeadWindow();
        book.getInitXmlNode();
        book.xmlShopCode = null;
        book.staysNums = 0;
       // book.refeshDomNode();
        book.bookingLeadCreate();
        
        
    }
    static testMethod void myUnitTest3() {
	    // TO DO: implement unit test
	    createDocument();
        BookingLeadWindow book = new BookingLeadWindow();
        book.getInitXmlNode();
        book.xmlShopCode = '01';
        book.startDays = '2016/07/28';
        //book.refeshDomNode();
        book.bookingLeadCreate();
        List<Lead__c> accObjLst = [select id from Lead__c];
        for(Lead__c accObj : accObjLst){
    		ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
    		Apexpages.currentPage().getParameters().put('Name',accObj.Id);
    	}
    }
    static testMethod void myUnitTest4() {
        // TO DO: implement unit test
        createDocument2();
	    BookingLeadWindow book = new BookingLeadWindow();
	    book.getInitXmlNode();
	    book.xmlShopCode = '01';
	    book.startDays = '2016/07/29';
	   // book.refeshDomNode();
	    book.bookingLeadCreate();
	    
    	
    }
    static testMethod void myUnitTest5() {
        // TO DO: implement unit test
   		createDocument();
	    BookingLeadWindow book = new BookingLeadWindow();
	    book.getInitXmlNode();
	    book.staysNums = 2;
	    book.startDays = '2016/07/27';
	    book.bookingRooms = 3 ;
	    Date entryDate = null;
	    Date curDay = entryDate == null ? Date.today() : entryDate;
    	DateTime startDate = DateTime.newInstance(curDay, Time.newInstance(0, 0, 0, 0));
    	Room__c room = TestCommon.createRooms();
    	// 連泊データを自動作成
    	book.newCustomLead = new Lead__c(
    	   RecordTypeId = CommLogicProcess.getLeadBookingRecType(),
    	   name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
    	   Relcontact__c = TestCommon.createContact().Id,    // 顧客名
    	   ReservedDate__c = System.now(),
    	   ReservedContact__c = 'Ono',
    	   EntryTime__c = startDate.addDays(-1),
    	   Field4__c = '15:30',
    	   Departure__c = startDate,
    	   Field3__c = '10:00',
    	   Field310__c = TestCommon.createPlan().Id,
    	   StayPersons__c = 3,
    	   Rroom__c = room.Id);
	       book.bookingLeadCreate();
     }
     static testMethod void myUnitTest6() {
        // TO DO: implement unit test
   		createDocument();
	    BookingLeadWindow book = new BookingLeadWindow();
	    book.getInitXmlNode();
	   //book.staysNums = 0;
	    book.startDays = '2016/08/02';
	    Date entryDate = null;
	    Date curDay = entryDate == null ? Date.today() : entryDate;
    	DateTime startDate = DateTime.newInstance(curDay, Time.newInstance(0, 0, 0, 0));
    	Room__c room = TestCommon.createRooms();
    	// 連泊データを自動作成
    	book.newCustomLead = new Lead__c(
    	   RecordTypeId = CommLogicProcess.getLeadBookingRecType(),
    	   name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
    	   Relcontact__c = TestCommon.createContact().Id,    // 顧客名
    	   ReservedDate__c = System.now(),
    	   ReservedContact__c = 'Ono',
    	   EntryTime__c = startDate.addDays(-1),
    	   Field4__c = '15:30',
    	   Departure__c = startDate,
    	   Field3__c = '10:00',
    	   Field310__c = TestCommon.createPlan().Id,
    	   StayPersons__c = 3,
    	   Rroom__c = room.Id);
	       book.bookingLeadCreate();
	
    }
    static testMethod void myUnitTest7() {
        // TO DO: implement unit test
   		createDocument();
	    BookingLeadWindow.dispRecord book = new BookingLeadWindow.dispRecord();
	    BookingLeadWindow.TrvaleRecord book1 = new BookingLeadWindow.TrvaleRecord();
	    Room__c room = TestCommon.createRooms(); 
	    book1.getDispRecord(room.Id);  
	    book1.getRoomTypes();
	    
        Test.startTest();
		Test.setMock(WebServiceMock.class, new TestCommonMockImpl());
        BookingLeadWindow book2 = new BookingLeadWindow();
        // 初期処理
        book2.getInitXmlNode();
        Contact guest = TestCommon.createContact();
        String strId = (String)guest.id;
    	String guestName = guest.LastName + ' ' + guest.FirstName;
        BookingLeadWindow.refreshContcatInfo(strId,guestName);
	   	// 2way照会
        book2.bookingLeadCreate();
        Test.stopTest();
    }
    static testMethod void myUnitTest8() {
    	CommDefine__c comm = TestCommon.createCommDefine();
    	comm.RoomPriceProdName__c = '室料[A]';
    	update comm;
    	List<AccountMaster__c> productMst = TestCommon.createProductMst(1);
    	productMst[0].name = '室料[A]';
    	productMst[0].ActionType__c = '室料';
    	update productMst;
        // TO DO: implement unit test
        createDocument();
	    BookingLeadWindow book = new BookingLeadWindow();
	    book.getInitXmlNode();
	    book.staysNums = null;
	    book.startDays = '2016/07/27';
	    Date entryDate = null;
	    book.bookingRooms = 2 ;
	    
	    Date curDay = entryDate == null ? Date.today() : entryDate;
    	DateTime startDate = DateTime.newInstance(curDay, Time.newInstance(0, 0, 0, 0));
    	Room__c room = TestCommon.createRooms();
    	// 連泊データを自動作成
    	book.newCustomLead = new Lead__c(
    	   RecordTypeId = CommLogicProcess.getLeadBookingRecType(),
    	   name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
    	   Relcontact__c = TestCommon.createContact().Id,    // 顧客名
    	   ReservedDate__c = System.now(),
    	   ReservedContact__c = 'Ono',
    	   EntryTime__c = startDate.addDays(-1),
    	   Field4__c = '15:30',
    	   Departure__c = startDate,
    	   Field3__c = '10:00',
    	   Field310__c = TestCommon.createPlan().Id,
    	   StayPersons__c = 3,
    	   Rroom__c = room.Id);
    	Lead__c lead = (Lead__c)book.sobjectMap.get('Lead__c');
    	lead.StayPersons__c = 3;
    	lead.name = '予約単体テスト_UNIT_TEST_LEAD' + System.now();
    	lead.Relcontact__c = TestCommon.createContact().Id;
    	lead.ReservedContact__c = 'Ono';
    	lead.EntryTime__c = startDate.addDays(-1);
    	lead.Field4__c = '15:30';
    	lead.Departure__c = startDate;
    	lead.Field3__c = '10:00';
    	lead.Field310__c = TestCommon.createPlan().Id; 
    	book.bookingLeadCreate();
	    
    	
    }
     static testMethod void myUnitTest9() {
        // TO DO: implement unit test
        CommDefine__c comm = TestCommon.createCommDefine();
    	comm.RoomPriceProdName__c = '室料[A]';
    	update comm;
    	List<AccountMaster__c> productMst = TestCommon.createProductMst(1);
    	productMst[0].name = '室料[A]';
    	productMst[0].ActionType__c = '室料';
    	update productMst;
    	
   		createDocument();
	    BookingLeadWindow book = new BookingLeadWindow();
	    book.getInitXmlNode();
	    book.staysNums = 0;
	    book.startDays = '2016/07/27';
	    book.bookingRooms = 3 ;
	    Date entryDate = null;
	    Date curDay = entryDate == null ? Date.today() : entryDate;
    	DateTime startDate = DateTime.newInstance(curDay, Time.newInstance(0, 0, 0, 0));
    	Room__c room = TestCommon.createRooms();
    	// 連泊データを自動作成
    	book.newCustomLead = new Lead__c(
    	   RecordTypeId = CommLogicProcess.getLeadBookingRecType(),
    	   name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
    	   Relcontact__c = TestCommon.createContact().Id,    // 顧客名
    	   ReservedDate__c = System.now(),
    	   ReservedContact__c = 'Ono',
    	   EntryTime__c = startDate.addDays(-1),
    	   Field4__c = '15:30',
    	   Departure__c = startDate,
    	   Field3__c = '10:00',
    	   Field310__c = TestCommon.createPlan().Id,
    	   StayPersons__c = 3,
    	   Rroom__c = room.Id);  
	    book.bookingLeadCreate();
     }
     static testMethod void myUnitTest10() {
    	CommDefine__c comm = TestCommon.createCommDefine();
    	comm.RoomPriceProdName__c = '室料[A]';
    	update comm;
    	List<AccountMaster__c> productMst = TestCommon.createProductMst(1);
    	productMst[0].name = '室料[A]';
    	productMst[0].ActionType__c = '室料';
    	update productMst;
        // TO DO: implement unit test
        createDocument();
	    BookingLeadWindow book = new BookingLeadWindow();
	    book.getInitXmlNode();
	    book.staysNums = null;
	    book.startDays = '2016/07/27';
	    Date entryDate = null;
	    book.bookingRooms = 2 ;
	    
	    Date curDay = entryDate == null ? Date.today() : entryDate;
    	DateTime startDate = DateTime.newInstance(curDay, Time.newInstance(0, 0, 0, 0));
    	Room__c room = TestCommon.createRooms();
    	// 連泊データを自動作成
    	book.newCustomLead = new Lead__c(
    	   RecordTypeId = CommLogicProcess.getLeadBookingRecType(),
    	   name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
    	   Relcontact__c = TestCommon.createContact().Id,    // 顧客名
    	   ReservedDate__c = System.now(),
    	   ReservedContact__c = 'Ono',
    	   EntryTime__c = startDate.addDays(-1),
    	   Field4__c = '15:30',
    	   Departure__c = startDate,
    	   Field3__c = '10:00',
    	   Field310__c = null,
    	   StayPersons__c = 3,
    	   Rroom__c = room.Id);
    	Lead__c lead = (Lead__c)book.sobjectMap.get('Lead__c');
    	lead.StayPersons__c = 3;
    	lead.name = '予約単体テスト_UNIT_TEST_LEAD' + System.now();
    	lead.Relcontact__c = TestCommon.createContact().Id;
    	lead.ReservedContact__c = 'Ono';
    	lead.EntryTime__c = startDate.addDays(-1);
    	lead.Field4__c = '15:30';
    	lead.Departure__c = startDate;
    	lead.Field3__c = '10:00';
    	lead.Field310__c = null; 
    	book.bookingLeadCreate();
    }
    static testMethod void myUnitTest11() {
    	CommDefine__c comm = TestCommon.createCommDefine();
    	comm.RoomPriceProdName__c = '室料[A]';
    	update comm;
    	List<AccountMaster__c> productMst = TestCommon.createProductMst(1);
    	productMst[0].name = '室料[A]';
    	productMst[0].ActionType__c = '室料';
    	update productMst;
        // TO DO: implement unit test
        createDocument();
	    BookingLeadWindow book = new BookingLeadWindow();
	    book.getInitXmlNode();
	    TestCommon.createRaceRateDetail('A','B',5);
	    book.staysNums = null;
	    book.startDays = '2016/07/27';
	    Date entryDate = null;
	    book.bookingRooms = 2 ;
	    book.xmlShopCode = '02';
	    
	    Date curDay = entryDate == null ? Date.today() : entryDate;
    	DateTime startDate = DateTime.newInstance(curDay, Time.newInstance(0, 0, 0, 0));
    	Room__c room = TestCommon.createRooms();
    	// 連泊データを自動作成
    	book.newCustomLead = new Lead__c(
    	   RecordTypeId = CommLogicProcess.getLeadBookingRecType(),
    	   name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
    	   Relcontact__c = TestCommon.createContact().Id,    // 顧客名
    	   ReservedDate__c = System.now(),
    	   ReservedContact__c = 'Ono',
    	   EntryTime__c = startDate.addDays(-1),
    	   Field4__c = '15:30',
    	   Departure__c = startDate,
    	   Field3__c = '10:00',
    	   Field310__c = null,
    	   StayPersons__c = 3,
    	   Rroom__c = room.Id);
    	Lead__c lead = (Lead__c)book.sobjectMap.get('Lead__c');
    	lead.StayPersons__c = 3;
    	lead.name = '予約単体テスト_UNIT_TEST_LEAD' + System.now();
    	lead.Relcontact__c = TestCommon.createContact().Id;
    	lead.ReservedContact__c = 'Ono';
    	lead.EntryTime__c = startDate.addDays(-1);
    	lead.Field4__c = '15:30';
    	lead.Departure__c = startDate;
    	lead.Field3__c = '10:00';
    	lead.Field310__c = null;
    	book.bookingLeadCreate();
    	
    	
    }
    static testMethod void myUnitTest12() {
	    CommDefine__c comm = TestCommon.createCommDefine();
    	comm.RoomPriceProdName__c = '室料[A]';
    	update comm;
    	List<AccountMaster__c> productMst = TestCommon.createProductMst(1);
    	productMst[0].name = '室料[A]';
    	productMst[0].ActionType__c = '室料';
    	update productMst;
        // TO DO: implement unit test
        createDocument();
	    BookingLeadWindow book = new BookingLeadWindow();
	    book.getInitXmlNode();
	    book.staysNums = null;
	    book.startDays = '2016/07/27';
	    Date entryDate = null;
	    book.bookingRooms = 2 ;
	    //book.xmlShopCode = '02';
	    
	    Date curDay = entryDate == null ? Date.today() : entryDate;
    	DateTime startDate = DateTime.newInstance(curDay, Time.newInstance(0, 0, 0, 0));
    	Room__c room = TestCommon.createRooms();
    	// 連泊データを自動作成
    	book.newCustomLead = new Lead__c(
    	   RecordTypeId = CommLogicProcess.getLeadBookingRecType(),
    	   name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
    	   Relcontact__c = TestCommon.createContact().Id,    // 顧客名
    	   ReservedDate__c = System.now(),
    	   ReservedContact__c = 'Ono',
    	   EntryTime__c = startDate.addDays(-1),
    	   Field4__c = '15:30',
    	   Departure__c = startDate,
    	   Field3__c = '10:00',
    	   Field310__c = null,
    	   StayPersons__c = 3,
    	   Rroom__c = room.Id);
    	Lead__c lead = (Lead__c)book.sobjectMap.get('Lead__c');
    	lead.StayPersons__c = 3;
    	lead.name = '予約単体テスト_UNIT_TEST_LEAD' + System.now();
    	lead.Relcontact__c = TestCommon.createContact().Id;
    	lead.ReservedContact__c = 'Ono';
    	lead.EntryTime__c = startDate.addDays(-1);
    	lead.Field4__c = '15:30';
    	lead.Departure__c = startDate;
    	lead.Field3__c = '10:00';
    	lead.Field310__c = null; 
    	book.bookingLeadCreate();
		List<RackRateTableDetail__c> insDetail = new List<RackRateTableDetail__c>();
    	for (Integer i = 0; i<3; i++) {
    		Date setupDate = date.today().addDays(i);
	    	RackRateTableDetail__c rackDetail = new RackRateTableDetail__c(
	    		Tier__c = 'ABC',
	    		PriceSetupDate__c = setupDate,
	    		ShopInfoRef__c = null,
	    		SearchKey__c = '_'+setupDate
	    	);	
	    	insDetail.add(rackDetail);
    	}
    	insert insDetail;									
		
    }
     static testMethod void myUnitTest13() {
	    CommDefine__c comm = TestCommon.createCommDefine();
	    // 商品情報を作成する[5件商品を作成する]
        List<AccountMaster__c> productLst = TestCommon.createProductMst(5);
        
    	comm.RoomPriceProdName__c = '室料[A]';
    	update comm;
    	List<AccountMaster__c> productMst = TestCommon.createProductMst(1);
    	productMst[0].name = '室料[A]';
    	productMst[0].ActionType__c = '室料';
    	update productMst;
        // TO DO: implement unit test
        createDocument3();
	    BookingLeadWindow book = new BookingLeadWindow();
	    book.getInitXmlNode();
	    book.staysNums = 1;
	    book.startDays = '2016/07/27';
	    Date entryDate = null;
	    book.bookingRooms = 2 ;
	    //book.xmlShopCode = '02';
	    
	    Date curDay = entryDate == null ? Date.today() : entryDate;
    	DateTime startDate = DateTime.newInstance(curDay, Time.newInstance(0, 0, 0, 0));
    	Room__c room = TestCommon.createRooms();
    	// 連泊データを自動作成
    	book.newCustomLead = new Lead__c(
    	   RecordTypeId = CommLogicProcess.getLeadBookingRecType(),
    	   name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
    	   Relcontact__c = TestCommon.createContact().Id,    // 顧客名
    	   ReservedDate__c = System.now(),
    	   ReservedContact__c = 'Ono',
    	   EntryTime__c = startDate.addDays(-1),
    	   Field4__c = '15:30',
    	   Departure__c = startDate,
    	   Field3__c = '10:00',
    	   Field310__c = null,
    	   StayPersons__c = 3,
    	   CouponTypeLst__c = 'JTBポイント',
    	   Mans__c = 2,
    	   Femails__c = 1,
    	   ReservedType__c = '昼 賑',
    	   OrgCreateDate__c = startDate,
    	   Rroom__c = room.Id);
    	Lead__c lead = (Lead__c)book.sobjectMap.get('Lead__c');
    	lead.StayPersons__c = 3;
    	lead.name = '予約単体テスト_UNIT_TEST_LEAD' + System.now();
    	lead.Relcontact__c = TestCommon.createContact().Id;
    	lead.ReservedContact__c = 'Ono';
    	lead.EntryTime__c = startDate.addDays(-1);
    	lead.Field4__c = '15:30';
    	lead.Departure__c = startDate;
    	lead.Field3__c = '10:00';
    	lead.Field310__c = null; 
    	
    	//List<BookingLeadWindow.BookEstItem> estLst = book.oBookEstLst;
    	system.debug(logginglevel.info,'book.oBookEstLst:::' + book.oBookEstLst);
    	book.oBookEstLst[0].sobj.refAccountMaster__c = productLst[0].id;
    	book.oBookEstLst[0].unitPrice = CommUtils.nullToBlank(CommUtils.nullToZero(productLst[0].Field5__c));
    	book.oBookEstLst[0].prodNums = CommUtils.nullToBlank(lead.StayPersons__c);
        book.oBookEstLst[0].sobj.UnitPrice__c = CommUtils.nullToZero(productLst[0].Field5__c);
        book.oBookEstLst[0].sobj.Amount__c = lead.StayPersons__c ;          
    	book.bookingLeadCreate();
		List<RackRateTableDetail__c> insDetail = new List<RackRateTableDetail__c>();
    	for (Integer i = 0; i<3; i++) {
    		Date setupDate = date.today().addDays(i);
	    	RackRateTableDetail__c rackDetail = new RackRateTableDetail__c(
	    		Tier__c = 'ABC',
	    		PriceSetupDate__c = setupDate,
	    		ShopInfoRef__c = null,
	    		SearchKey__c = '_'+setupDate
	    	);	
	    	insDetail.add(rackDetail);
    	}
    	insert insDetail;									
    	List<BookingEstimateItem__c> bLst = [select id,UnitPrice__c,Amount__c from BookingEstimateItem__c];
  		
    	System.assertEquals(bLst[0].Amount__c , lead.StayPersons__c);
		
    }
    static testMethod void myUnitTest14() {
	    CommDefine__c comm = TestCommon.createCommDefine();
	    // 商品情報を作成する[5件商品を作成する]
	    Plan__c plan = TestCommon.createPlan();
        List<AccountMaster__c> productLst = TestCommon.createProductMst(5);
    	comm.RoomPriceProdName__c = '室料[A]';
    	comm.RoomTypeNewBookingWinVersion__c = 2;
    	update comm;
    	List<AccountMaster__c> productMst = TestCommon.createProductMst(1);
    	productMst[0].name = '室料[A]';
    	productMst[0].ActionType__c = '室料';
    	update productMst;
        // TO DO: implement unit test
        createDocument4();
	    BookingLeadWindow book = new BookingLeadWindow();
	    book.getInitXmlNode();
	    book.staysNums = 3;
	    book.startDays = '2016/07/27';
	    Date entryDate = null;
	    book.bookingRooms = 2 ;
	    //book.xmlShopCode = '02';
	    
	    Date curDay = entryDate == null ? Date.today() : entryDate;
    	DateTime startDate = DateTime.newInstance(curDay, Time.newInstance(0, 0, 0, 0));
    	Room__c room = TestCommon.createRooms();
    	// 連泊データを自動作成
    	book.newCustomLead = new Lead__c(
    	   RecordTypeId = CommLogicProcess.getLeadBookingRecType(),
    	   name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
    	   //Relcontact__c = TestCommon.createContact().Id,    // 顧客名
    	   ReservedDate__c = System.now(),
    	   ReservedContact__c = 'Ono',
    	   EntryTime__c = startDate.addDays(-3),
    	   Field4__c = '15:30',
    	   Departure__c = startDate,
    	   Field3__c = '10:00',
    	   Field310__c = null,
    	   StayPersons__c = 3,
    	   CouponTypeLst__c = 'JTBポイント',
    	   Mans__c = 2,
    	   Femails__c = 1,
    	   ReservedType__c = '昼 賑',
    	   OrgCreateDate__c = startDate,
    	   Rroom__c = room.Id);
    	book.contactName = 'UNIT_TEST_LEAD';
    	system.debug(logginglevel.info,'book.oBookEstLst:::' + book.oBookEstLst);
    	book.oBookEstLst[0].sobj.refAccountMaster__c = productLst[0].id;
    	book.oBookEstLst[0].unitPrice = CommUtils.nullToBlank(CommUtils.nullToZero(productLst[0].Field5__c));
    	book.oBookEstLst[0].prodNums = CommUtils.nullToBlank(book.newCustomLead.StayPersons__c);
        book.oBookEstLst[0].sobj.UnitPrice__c = CommUtils.nullToZero(productLst[0].Field5__c);
        book.oBookEstLst[0].sobj.Amount__c = book.newCustomLead.StayPersons__c ;          
    	book.bookingLeadCreate();
		List<RackRateTableDetail__c> insDetail = new List<RackRateTableDetail__c>();
    	for (Integer i = 0; i<3; i++) {
    		Date setupDate = date.today().addDays(i);
	    	RackRateTableDetail__c rackDetail = new RackRateTableDetail__c(
	    		Tier__c = 'ABC',
	    		PriceSetupDate__c = setupDate,
	    		ShopInfoRef__c = null,
	    		SearchKey__c = '_'+setupDate
	    	);	
	    	insDetail.add(rackDetail);
    	}
    	insert insDetail;									
    	List<BookingEstimateItem__c> bLst = [select id,UnitPrice__c,Amount__c from BookingEstimateItem__c];
  		BookingLeadWindow.getProductItemInfo(productLst[0].Field3__c);
  		BookingLeadWindow.getArrayProductItemInfoNoPlan(productLst[0].Field3__c);
  		BookingLeadWindow.getArrayProductDetailItemInfo(productLst[0].Field3__c);
  		BookingLeadWindow.getAccountMstLstByPlan(productLst[0].id,'3000');
  		
    	//System.assertEquals(bLst[0].Amount__c , book.newCustomLead.StayPersons__c);
		
    }
    public static testMethod void testremoteaction1(){
       Plan__c plan = TestCommon.createPlan();
       String plandId = (String)plan.id;
       BookingLeadWindow.getPlanDetailListById(plandId);
       BookingLeadWindow.getArrayProductItemInfo('02');
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
    	String documentFileStr = '<?xml version="1.0" encoding="UTF-8"?><root>	<SHOP>		<SHOPCODE></SHOPCODE>		<COLNUMS>2</COLNUMS>	<!-- Layoutに１行に表示の列数[1,2]と定義する -->		<FIELDS>		Segment__c		,CouponTypeLst__c		,Mans__c		,Femails__c		,ChildFA__c		,Childs__c		,ChildC__c		,ChildD__c		,Field348__c		,ReservedType__c		,Comment3__c		</FIELDS>	</SHOP>	<SHOP>		<SHOPCODE>01</SHOPCODE>		<FIELDS>		CouponTypeLst__c		,Mans__c		,Femails__c		,ChildFA__c		,Childs__c		,ChildC__c		,ChildD__c		,ReservedType__c		,OrgCreateDate__c		,OrgUpdateDate__c		,Rich2__c		,Comment3__cS		</FIELDS>	</SHOP></root>';
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'RoomTypeInventoryLeadInputExtendFieldsXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(documentFileStr);
    	getCsvSetupConfig();
    	insert item;
    }
    private static void createDocument2(){
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
    private static void createDocument3(){
    	String documentFileStr = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP><VERSION>1.0</VERSION><SHOPCODE>02</SHOPCODE><COLNUMS>1</COLNUMS><FIELDS>CouponTypeLst__c,Mans__c,Femails__c,ReservedType__c,OrgCreateDate__c,OrgUpdateDate__c,Rich2__c,Comment3__c,ChildFA__c,Childs__c,ChildC__c,ChildD__c,Field276__c,Field302__c,X1y1__c</FIELDS><REQUIREDFIELDS>CouponTypeLst__c,Mans__c,Femails__c,ReservedType__c,OrgCreateDate__c</REQUIREDFIELDS><MITUMORIFLAG>TRUE</MITUMORIFLAG></SHOP></root>';
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'RoomTypeInventoryLeadInputExtendFieldsXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(documentFileStr);
    	getCsvSetupConfig();
    	insert item;
    }
	private static void createDocument4(){
    	String documentFileStr = '<?xml version="1.0" encoding="UTF-8"?><root>	<SHOP>		<SHOPCODE></SHOPCODE>		<MITUMORIFLAG>TRUE</MITUMORIFLAG>		<FIELDS>			<SECTION COLNUM="2">			<!-- お客様 -->			Relcontact__c			,refTypeOfRooms__c,			,Name			,EntryTime__c			,Relcontact__r.KanaName1__c			,Field4__c			,Relcontact__r.Katakana__c			,Departure__c			,Relcontact__r.Phone			,Field3__c			,StayPersons__c			,$_blank_$			,staysNums			</SECTION>			<SECTION COLNUM="1">			,$_blank_$			,bookingRooms			,Field310__c			</SECTION>			<SECTION COLNUM="2">			,Field315__c			,$_blank_$			,Field2__c			,$_blank_$			,Segment__c			</SECTION>			<SECTION COLNUM="1">			Comment3__c			</SECTION>		</FIELDS> 		<!-- 必須項目対象API名 -->		<REQUIREDFIELDS>		Relcontact__c,Name,StayPersons__c,EntryTime__c,Departure__c		</REQUIREDFIELDS>		<!-- デフォルト項目は除外の項目API名 -->		<EXUTEFIELD>		<!-- Relcontact__r.KanaName1__c,Relcontact__r.Katakana__c -->		</EXUTEFIELD>		<COLNUMSIZE>		Relcontact__c:180px		,Name:180px		,Field310__c:450px		</COLNUMSIZE>	</SHOP></root>';
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'RoomTypeInventoryLeadInputExtendFieldsXml_V2';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(documentFileStr);
    	getCsvSetupConfig();
    	insert item;
    }
    private static void getCsvSetupConfig() {
        String csv = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP><SHOPCODE></SHOPCODE><PAYMENT><CONVERT><PAYTYPE>現金</PAYTYPE><MEIDALAB>預り／現計</MEIDALAB></CONVERT><CONVERT><PAYTYPE>カード</PAYTYPE><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB></CONVERT><CONVERT><PAYTYPE>売掛金</PAYTYPE><MEIDALAB>掛計</MEIDALAB></CONVERT><CONVERT><PAYTYPE>クーポン</PAYTYPE><MEIDALAB>クーポン</MEIDALAB></CONVERT><CONVERT><PAYTYPE>値引</PAYTYPE><MEIDALAB>値引・割引券</MEIDALAB></CONVERT><CONVERT><PAYTYPE>予約金</PAYTYPE><MEIDALAB>予約金</MEIDALAB></CONVERT></PAYMENT><PAYMEIDA><CONVERT><MEIDALAB>預り／現計</MEIDALAB><PRODCODE>87001</PRODCODE></CONVERT><CONVERT><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB><PRODCODE>85201</PRODCODE></CONVERT><CONVERT><MEIDALAB>掛計</MEIDALAB><PRODCODE>85101</PRODCODE></CONVERT><CONVERT><MEIDALAB>クーポン</MEIDALAB><PRODCODE>85610</PRODCODE></CONVERT><CONVERT><MEIDALAB>値引・割引券</MEIDALAB><PRODCODE>87005</PRODCODE></CONVERT><CONVERT><MEIDALAB>予約金</MEIDALAB><PRODCODE>87001</PRODCODE></CONVERT></PAYMEIDA></SHOP></root>';
        Document doc = new Document();
        doc.Name = 'BillSimpleHelpConfig';
        doc.DeveloperName = doc.Name;
        doc.FolderId = UserInfo.getUserId();
        doc.Body = Blob.valueOf(csv);
        insert doc;
    }
}