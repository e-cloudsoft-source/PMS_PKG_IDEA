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
private class BookingPlusTest {

	static testMethod void testbookingplus(){						/* Testmethod of BookingPlus */
																	/* create a test booking data */
		Room__c roomtest = new Room__c(Name = 'TestRoom', Lat__c = 0, Lng__c = 0, Height__c = 10, Width__c = 10, Seq__c = 1, CapacityHaku__c = 0, Capacity__c = 80, heyadashiryou__c = 20000, heyadashiryouryou__c = 20000);
		insert roomtest;
		
		Date curDay  = Date.today();
		DateTime startDate = DateTime.newInstance(curDay.addDays(15), Time.newInstance(0, 0, 0, 0));
//		Lead__c bookingtest = new Lead__c(Name = 'TestBooking', ReservedDate__c = datetime.now(), EntryTime__c = datetime.now(), rRoom__c = roomtest.Id, Morningfood__c = true, room1__c = 20000);
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
																	/* trigger test */
		OP__c opothertest = new OP__c(Name = 'その他');
		insert opothertest;
		AccountMaster__c amtest = new AccountMaster__c(OP__c = opothertest.Id);
		insert amtest;
		BookingEstimateItem__c beitest = new BookingEstimateItem__c(refBooking__c = bookingtest.Id, refAccountMaster__c = amtest.Id);
		insert beitest;
																	/* create a record for standerd controller */
		BookingPlus__c bptest = new BookingPlus__c(Checkinday__c = bookingtest.EntryTime__c.date());
		insert bptest;
																	/* invoke constractor */
		BookingPlus bp = new BookingPlus(new ApexPages.StandardController(bptest));
		System.assertEquals(BookingPlus.checkinday, bookingtest.EntryTime__c.date());
		
		Object[]			wgetBookingData	= bp.getBookingData();
		Object[]			wgetRoomData	= bp.getRoomData();
		List<Lead__c>		wgetbooking		= bp.getbooking();
		string				wgetfixedday	= bp.getfixedday();
		string				wgetRecordId	= bp.getRecordId();
		
		BookingPlus.AC acdatatest = new BookingPlus.AC();
		//string jsonstr = '[{\'name\': \''+ bookingtest.Name + '\', \'id\': \''+ bookingtest.Id + '\', \'flag\': \'0\', \'cLat\': 0, \'cLng\': 0, \'status\': \'' + bookingtest.ReservedStatus__c + '\', \'persons\': 1, \'roomid\': \''+ bookingtest.rRoom__c +'\', \'room\': \''+ bookingtest.rRoom__r.Name +'\', \'roomType\': \''+ bookingtest.refTypeOfRooms__r.Name +'\', \'plan\': \'\', \'planid\': \'\', \'segment\': \'\', \'booktype\': \'\'}]';
		string jsonstr = '[{"name": "'+ bookingtest.Name + '", "id": "'+ bookingtest.Id + '", "flag": "0", "cLat": 0, "cLng": 0, "status": "' + bookingtest.ReservedStatus__c + '", "persons": 1, "roomid": "'+ bookingtest.rRoom__c +'", "room": "'+ bookingtest.rRoom__r.Name +'", "roomType": "'+ bookingtest.refTypeOfRooms__r.Name +'", "plan": "", "planid": "", "segment": "", "booktype": ""}]';
		integer				wRoomAssign		= BookingPlus.setRoomAssign(bptest.Id, jsonstr);
		System.assertEquals(wRoomAssign, 1);
		
		string				str				= '\"/<>{}%=;:()&+-';
		string				wesc			= bp.esc(str);
	}
	public static Contact createContact() {
    	Contact item = new Contact(
    		firstName = 'UNIT_TEST_顧客名' + System.now(),
    		LastName = 'LASTNAME');
    	insert item;
    	return item;
    }
}