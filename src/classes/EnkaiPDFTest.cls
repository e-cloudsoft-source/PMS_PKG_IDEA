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
private class EnkaiPDFTest {

    static testMethod void testEnkaiPDF(){                                                      // Testmethod of EnkaiPDF
        TestCommon.createCommDefine();                                                                                      // creating test records
        Lead__c bookingtest = new Lead__c(Name = 'TestBooking', Morningfood__c = true, room1__c = 20000, ReservedDate__c = datetime.now(), 
                                            MealStyle__c = '卓盛り', DrinkStyle__c = 'フリードリンク', BusWelcomeSend__c = 'お迎え', PaymentWay__c = '現金', Layout__c = '<img src="">');
        insert bookingtest;
        OP__c opfoodtest  = new OP__c(Name = '料理');
        OP__c opdrinktest = new OP__c(Name = '飲料');
        OP__c opothertest = new OP__c(Name = 'その他');
        insert opfoodtest;
        insert opdrinktest;
        insert opothertest;
        AccountMaster__c amfoodtest  = new AccountMaster__c(OP__c = opfoodtest.Id,  EstimateFieldNo__c = -1);
        AccountMaster__c amdrinktest = new AccountMaster__c(OP__c = opdrinktest.Id, EstimateFieldNo__c = -1);
        AccountMaster__c amothertest = new AccountMaster__c(OP__c = opothertest.Id, EstimateFieldNo__c = -1);
        AccountMaster__c ambustest   = new AccountMaster__c(OP__c = opothertest.Id, EstimateFieldNo__c =  1, Name = '送迎バス');
        insert amfoodtest;
        insert amdrinktest;
        insert amothertest;
        insert ambustest;
        BookingEstimateItem__c beifoodtest  = new BookingEstimateItem__c(refBooking__c = bookingtest.Id, refAccountMaster__c = amfoodtest.Id);
        BookingEstimateItem__c beidrinktest = new BookingEstimateItem__c(refBooking__c = bookingtest.Id, refAccountMaster__c = amdrinktest.Id);
        BookingEstimateItem__c beiothertest = new BookingEstimateItem__c(refBooking__c = bookingtest.Id, refAccountMaster__c = amothertest.Id);
        BookingEstimateItem__c beibustest   = new BookingEstimateItem__c(refBooking__c = bookingtest.Id, refAccountMaster__c = ambustest.Id);
        insert beifoodtest;
        insert beidrinktest;
        insert beiothertest;
        insert beibustest;
        
        Date curDay  = Date.today();
        DateTime startDate = DateTime.newInstance(curDay.addDays(11), Time.newInstance(0, 0, 0, 0));
           	Lead__c item = new Lead__c(
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
    	   Rroom__c = createRooms().Id);
    	insert item;
                                                                                                    // invoke constractor
//        Lead__c bookingtest1 = [select Id, name from Lead__c limit 1];                                                                                                   
        EnkaiPDF enkaipdf = new EnkaiPDF(new ApexPages.StandardController(item));
//for test cover of Package        EnkaiPDF enkaipdf = new EnkaiPDF(new ApexPages.StandardController(bookingtest));
        System.assertEquals(enkaipdf.booking.name, item.name);
                                                                                                    // invoke methods
        Lead__c                         wgetBooking     = enkaipdf.getBooking();
        List<Lead__c>                   wgetRbookings   = enkaipdf.getRbookings();
        List<BookingEstimateItem__c>    wFoods          = enkaipdf.getFoods();
        List<BookingEstimateItem__c>    wDrinks         = enkaipdf.getDrinks();
        List<BookingEstimateItem__c>    wOthers         = enkaipdf.getOthers();
        List<string>                    wOtherItemName  = enkaipdf.getOtherItemName();
        decimal                         wFoodTotal      = enkaipdf.getFoodTotal();
        decimal                         wDrinkTotal     = enkaipdf.getDrinkTotal();
        decimal                         wOtherTotal     = enkaipdf.getOtherTotal();
        decimal                         wRoomTotal      = enkaipdf.getRoomTotal();
        decimal                         wBusTotal       = enkaipdf.getBusTotal();
        string                          wMealStylePos   = enkaipdf.getMealStylePos();
        string                          wDrinkStylePos  = enkaipdf.getDrinkStylePos();
        string                          wBusWSPos       = enkaipdf.getBusWSPos();
        string                          wPaymentPos     = enkaipdf.getPaymentPos();
        string                          wLayoutURL      = enkaipdf.getLayoutURL();
        List<string>                    wComments       = enkaipdf.getComments();
    }
        public static Contact createContact() {
    	Contact item = new Contact(
    		firstName = 'UNIT_TEST_顧客名' + System.now(),
    		LastName = 'LASTNAME');
    	insert item;
    	return item;
    }
    
    public static Room__c createRooms() {
    	Room__c item = new Room__c(
    		Name = '部屋テストUNIT_VIP_TEST',
    		CapacityHaku__c = 4,
    		Capacity__c = 2,
    		heyadashiryouryou__c = 40000,
    		heyadashiryou__c = 25000);
		insert item;
		return item;
    }
}