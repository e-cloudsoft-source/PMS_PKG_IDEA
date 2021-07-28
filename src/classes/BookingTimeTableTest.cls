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
private class BookingTimeTableTest {
	
	@isTest(SeeAllData=false)
	static void testBookingTimeTable(){	// Testmethod of BookingTimeTable 
		Room__c proom = new Room__c(Name = CommUtils.getRandom(10), UseOfRoom__c = CommConst.ROOM_UseOfType_PTY, Seq__c = Integer.valueOf(CommUtils.getRandom(6)), CapacityHaku__c = 0, Capacity__c = 80, heyadashiryou__c = 20000, heyadashiryouryou__c = 20000);
		insert proom;
		Room__c roomtest = new Room__c(Name = CommUtils.getRandom(10), ParentRoomRef__c= proom.Id, UseOfRoom__c = CommConst.ROOM_UseOfType_PTY, Seq__c = Integer.valueOf(CommUtils.getRandom(6)), CapacityHaku__c = 1, Capacity__c = 180, heyadashiryou__c = 22000, heyadashiryouryou__c = 24000);
		insert roomtest;
		Date curDay  = Date.today();
		DateTime startDate = DateTime.newInstance(curDay.addDays(30), Time.newInstance(0, 0, 0, 0));
//		Lead__c bookingtest = new Lead__c(Name = 'TestBooking', Morningfood__c = true, room1__c = 20000, EntryTime__c = datetime.now(), ReservedDate__c = datetime.now(), Rroom__c = roomtest.Id);
		Lead__c bookingtest = new Lead__c(
		   name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
    	   Relcontact__c = TestCommon.createContact().Id,                  // 顧客名
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
		BookingTimeTable__c btttest = new BookingTimeTable__c(Checkinday__c = bookingtest.EntryTime__c.date());
		insert btttest;

		OP__c opothertest = new OP__c(Name = 'その他');
		insert opothertest;
		AccountMaster__c amtest = new AccountMaster__c(OP__c = opothertest.Id);
		insert amtest;
		BookingEstimateItem__c beifoodtest  = new BookingEstimateItem__c(refBooking__c = bookingtest.Id, refAccountMaster__c = amtest.Id);
		insert beifoodtest;

		BookingTimeTable btt = new BookingTimeTable();
		btt.selectDate.Checkinday__c = bookingtest.EntryTime__c.date();
		btt.gotoDate();
		System.assertEquals(btt.cdate, bookingtest.EntryTime__c.date());

		List<Room__c>	wgetRoom		= btt.getRoom();
//		Object[]		wgetBookingData	= btt.getBookingData();
//		Object[]		wgetRoomData	= btt.getRoomData();

        for (BookingTimeTable.OneRoomAssingInfo obj: btt.roomBookingMap.values()) {
        	System.assertNotEquals(obj.tdHtml, null);
        }
		List<integer>	wgetHours		= btt.getHours();
		btt.refreshTimePanel();
		PageReference	wbookingCreate	= btt.bookingCreate();
		btt.toNext();
		btt.toPrev();
		btt.toToday();
		btt.toPrevWeek();
		btt.toNextWeek();
		btt.setTimeLineHtml();
		//BookingTimeTable btt2 = new BookingTimeTable(new ApexPages.StandardController(btttest));

	}
	
	@isTest(SeeAllData=false)
    static void testCustomInputFields(){
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'BookingTimeLeadInputExtendFieldsXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf('<root><shop><SHOPCODE></SHOPCODE><FIELDS>Mans__c,Femails__c,Morningfood__c</FIELDS></shop></root>');
    	insert item;
    	// 2015/12/01 Assert BEGIN
		System.assertEquals([select Id from Document where Name = 'BookingTimeLeadInputExtendFieldsXml'].size(), 1);
		// 2015/12/01 Assert END

		//Room__c proom = new Room__c(Name = CommUtils.getRandom(10), UseOfRoom__c = ROOM_TYPE_PTY, Seq__c = Integer.valueOf(CommUtils.getRandom(6)), CapacityHaku__c = 0, Capacity__c = 80, heyadashiryou__c = 20000, heyadashiryouryou__c = 20000);
		Room__c proom = new Room__c(Name = CommUtils.getRandom(10), UseOfRoom__c = CommConst.ROOM_UseOfType_PTY, Seq__c = Integer.valueOf(CommUtils.getRandom(6)), CapacityHaku__c = 0, Capacity__c = 80, heyadashiryou__c = 20000, heyadashiryouryou__c = 20000);
		insert proom;
		//Room__c roomtest = new Room__c(Name = CommUtils.getRandom(10), ParentRoomRef__c= proom.Id, UseOfRoom__c = ROOM_TYPE_PTY, Seq__c = Integer.valueOf(CommUtils.getRandom(6)), CapacityHaku__c = 1, Capacity__c = 180, heyadashiryou__c = 22000, heyadashiryouryou__c = 24000);
		Room__c roomtest = new Room__c(Name = CommUtils.getRandom(10), ParentRoomRef__c= proom.Id, UseOfRoom__c = CommConst.ROOM_UseOfType_PTY, Seq__c = Integer.valueOf(CommUtils.getRandom(6)), CapacityHaku__c = 1, Capacity__c = 180, heyadashiryou__c = 22000, heyadashiryouryou__c = 24000);
		insert roomtest;
		Date curDay  = Date.today();
		DateTime startDate = DateTime.newInstance(curDay.addDays(30), Time.newInstance(0, 0, 0, 0));
		
		BookingTimeTable ctrl = new BookingTimeTable();
		ctrl.getInputExtendFields();
	}
}