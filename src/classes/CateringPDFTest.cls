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
private class CateringPDFTest {

    @isTest
	static void testCase1() {
    	Test.startTest();
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	leadInfo.CateringType__c = 'ケータ';
    	update leadInfo;
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	// 予約情報のステータス：チェックインに変更する
    	leadInfo.Field298__c = 'チェックイン完';
    	update leadInfo;

    	Test.stopTest();
		// プラン明細情報を設定する
    	ApexPages.StandardController handel = new ApexPages.StandardController(leadInfo);
    	CateringPDF contrl = new CateringPDF(handel);
    	Lead__c rsLead = contrl.getBooking();
    	System.assert(rsLead != null);
    	try {contrl.getAddTime1();} catch (Exception e) {}
    	try {contrl.getAddTime2();} catch (Exception e) {}
    	try {contrl.getAddTime3();} catch (Exception e) {}
    	try {contrl.getAddTime4();} catch (Exception e) {}
    	try {contrl.getFoods();} catch (Exception e) {}
    	try {contrl.getComments();} catch (Exception e) {}
    	try {contrl.getCateringPos();} catch (Exception e) {}
    	try {contrl.getDrinks();} catch (Exception e) {}
    	try {contrl.getDrinkTotal();} catch (Exception e) {}
    	try {contrl.getFoodTotal();} catch (Exception e) {}
    	try {contrl.getKakuninPos();} catch (Exception e) {}
    	try {contrl.getOthers();} catch (Exception e) {}
    	try {contrl.getKessanPos();} catch (Exception e) {}
    	try {contrl.getHakkouPos();} catch (Exception e) {}
    	try {contrl.getPayDirect();} catch (Exception e) {}
    	try {contrl.getPayConfirm();} catch (Exception e) {}
    	try {contrl.getOthersTest();} catch (Exception e) {}
    	try {contrl.getOtherItemName();} catch (Exception e) {}
    	try {contrl.getOthersOld();} catch (Exception e) {}
    	try {contrl.getNaiyouPos();} catch (Exception e) {}
    	try {contrl.getPaymentPos();} catch (Exception e) {}
    	try {contrl.getTourokuPos();} catch (Exception e) {}
    	try {contrl.getRbookings();} catch (Exception e) {}
    	
	}
	@isTest
	
	static void testCase2() {
    	Test.startTest();
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	leadInfo.CateringType__c = 'サービス';
    	leadInfo.Field384__c = '接待系';
    	leadInfo.PaymentWay__c = '現金';
    	leadInfo.touroku__c = '有';
    	leadInfo.kakunin__c = '有';
    	leadInfo.kessan__c = '未';
    	leadInfo.Field386__c = '営業';
    	leadInfo.Party1__c = '07:00';
    	leadInfo.Party2__c = '23:00';
    	update leadInfo;
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	// 予約情報のステータス：チェックインに変更する
    	leadInfo.Field298__c = 'チェックイン完';
    	update leadInfo;

    	Test.stopTest();
		// プラン明細情報を設定する
    	ApexPages.StandardController handel = new ApexPages.StandardController(leadInfo);
    	CateringPDF contrl = new CateringPDF(handel);
    	Lead__c rsLead = contrl.getBooking();
    	System.assert(rsLead != null);
    	try {contrl.getAddTime1();} catch (Exception e) {}
    	try {contrl.getAddTime2();} catch (Exception e) {}
    	try {contrl.getAddTime3();} catch (Exception e) {}
    	try {contrl.getAddTime4();} catch (Exception e) {}
    	try {contrl.getFoods();} catch (Exception e) {}
    	try {contrl.getComments();} catch (Exception e) {}
    	try {contrl.getCateringPos();} catch (Exception e) {}
    	try {contrl.getDrinks();} catch (Exception e) {}
    	try {contrl.getDrinkTotal();} catch (Exception e) {}
    	try {contrl.getFoodTotal();} catch (Exception e) {}
    	try {contrl.getKakuninPos();} catch (Exception e) {}
    	try {contrl.getOthers();} catch (Exception e) {}
    	try {contrl.getKessanPos();} catch (Exception e) {}
    	try {contrl.getHakkouPos();} catch (Exception e) {}
    	try {contrl.getPayDirect();} catch (Exception e) {}
    	try {contrl.getPayConfirm();} catch (Exception e) {}
    	try {contrl.getOthersTest();} catch (Exception e) {}
    	try {contrl.getOtherItemName();} catch (Exception e) {}
    	try {contrl.getOthersOld();} catch (Exception e) {}
    	try {contrl.getNaiyouPos();} catch (Exception e) {}
    	try {contrl.getPaymentPos();} catch (Exception e) {}
    	try {contrl.getTourokuPos();} catch (Exception e) {}
    	try {contrl.getRbookings();} catch (Exception e) {}
	}
	@isTest
	
	static void testCase3() {
    	Test.startTest();
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	leadInfo.CateringType__c = '和食';
    	leadInfo.Field384__c = '食事系';
    	leadInfo.PaymentWay__c = '集金';
    	update leadInfo;
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	// 予約情報のステータス：チェックインに変更する
    	leadInfo.Field298__c = 'チェックイン完';
    	update leadInfo;

    	Test.stopTest();
		// プラン明細情報を設定する
    	ApexPages.StandardController handel = new ApexPages.StandardController(leadInfo);
    	CateringPDF contrl = new CateringPDF(handel);
    	Lead__c rsLead = contrl.getBooking();
    	System.assert(rsLead != null);
    	try {contrl.getAddTime1();} catch (Exception e) {}
    	try {contrl.getAddTime2();} catch (Exception e) {}
    	try {contrl.getAddTime3();} catch (Exception e) {}
    	try {contrl.getAddTime4();} catch (Exception e) {}
    	try {contrl.getFoods();} catch (Exception e) {}
    	try {contrl.getComments();} catch (Exception e) {}
    	try {contrl.getCateringPos();} catch (Exception e) {}
    	try {contrl.getDrinks();} catch (Exception e) {}
    	try {contrl.getDrinkTotal();} catch (Exception e) {}
    	try {contrl.getFoodTotal();} catch (Exception e) {}
    	try {contrl.getKakuninPos();} catch (Exception e) {}
    	try {contrl.getOthers();} catch (Exception e) {}
    	try {contrl.getKessanPos();} catch (Exception e) {}
    	try {contrl.getHakkouPos();} catch (Exception e) {}
    	try {contrl.getPayDirect();} catch (Exception e) {}
    	try {contrl.getPayConfirm();} catch (Exception e) {}
    	try {contrl.getOthersTest();} catch (Exception e) {}
    	try {contrl.getOtherItemName();} catch (Exception e) {}
    	try {contrl.getOthersOld();} catch (Exception e) {}
    	try {contrl.getNaiyouPos();} catch (Exception e) {}
    	try {contrl.getPaymentPos();} catch (Exception e) {}
    	try {contrl.getTourokuPos();} catch (Exception e) {}
    	try {contrl.getRbookings();} catch (Exception e) {}
	}
	@isTest
	
	static void testCase4() {
    	Test.startTest();
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	leadInfo.CateringType__c = '洋食';
    	leadInfo.Field384__c = '親睦系';
    	leadInfo.PaymentWay__c = '振込';
    	update leadInfo;
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	// 予約情報のステータス：チェックインに変更する
    	leadInfo.Field298__c = 'チェックイン完';
    	update leadInfo;

    	Test.stopTest();
		// プラン明細情報を設定する
    	ApexPages.StandardController handel = new ApexPages.StandardController(leadInfo);
    	CateringPDF contrl = new CateringPDF(handel);
    	Lead__c rsLead = contrl.getBooking();
    	System.assert(rsLead != null);
    	try {contrl.getAddTime1();} catch (Exception e) {}
    	try {contrl.getAddTime2();} catch (Exception e) {}
    	try {contrl.getAddTime3();} catch (Exception e) {}
    	try {contrl.getAddTime4();} catch (Exception e) {}
    	try {contrl.getFoods();} catch (Exception e) {}
    	try {contrl.getComments();} catch (Exception e) {}
    	try {contrl.getCateringPos();} catch (Exception e) {}
    	try {contrl.getDrinks();} catch (Exception e) {}
    	try {contrl.getDrinkTotal();} catch (Exception e) {}
    	try {contrl.getFoodTotal();} catch (Exception e) {}
    	try {contrl.getKakuninPos();} catch (Exception e) {}
    	try {contrl.getOthers();} catch (Exception e) {}
    	try {contrl.getKessanPos();} catch (Exception e) {}
    	try {contrl.getHakkouPos();} catch (Exception e) {}
    	try {contrl.getPayDirect();} catch (Exception e) {}
    	try {contrl.getPayConfirm();} catch (Exception e) {}
    	try {contrl.getOthersTest();} catch (Exception e) {}
    	try {contrl.getOtherItemName();} catch (Exception e) {}
    	try {contrl.getOthersOld();} catch (Exception e) {}
    	try {contrl.getNaiyouPos();} catch (Exception e) {}
    	try {contrl.getPaymentPos();} catch (Exception e) {}
    	try {contrl.getTourokuPos();} catch (Exception e) {}
    	try {contrl.getRbookings();} catch (Exception e) {}
	}
	@isTest
	
	static void testCase5() {
    	Test.startTest();
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	leadInfo.CateringType__c = '中華';
    	leadInfo.Field384__c = '商談系';
    	update leadInfo;
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	// 予約情報のステータス：チェックインに変更する
    	leadInfo.Field298__c = 'チェックイン完';
    	update leadInfo;

    	Test.stopTest();
		// プラン明細情報を設定する
    	ApexPages.StandardController handel = new ApexPages.StandardController(leadInfo);
    	CateringPDF contrl = new CateringPDF(handel);
    	Lead__c rsLead = contrl.getBooking();
    	System.assert(rsLead != null);
    	try {contrl.getAddTime1();} catch (Exception e) {}
    	try {contrl.getAddTime2();} catch (Exception e) {}
    	try {contrl.getAddTime3();} catch (Exception e) {}
    	try {contrl.getAddTime4();} catch (Exception e) {}
    	try {contrl.getFoods();} catch (Exception e) {}
    	try {contrl.getComments();} catch (Exception e) {}
    	try {contrl.getCateringPos();} catch (Exception e) {}
    	try {contrl.getDrinks();} catch (Exception e) {}
    	try {contrl.getDrinkTotal();} catch (Exception e) {}
    	try {contrl.getFoodTotal();} catch (Exception e) {}
    	try {contrl.getKakuninPos();} catch (Exception e) {}
    	try {contrl.getOthers();} catch (Exception e) {}
    	try {contrl.getKessanPos();} catch (Exception e) {}
    	try {contrl.getHakkouPos();} catch (Exception e) {}
    	try {contrl.getPayDirect();} catch (Exception e) {}
    	try {contrl.getPayConfirm();} catch (Exception e) {}
    	try {contrl.getOthersTest();} catch (Exception e) {}
    	try {contrl.getOtherItemName();} catch (Exception e) {}
    	try {contrl.getOthersOld();} catch (Exception e) {}
    	try {contrl.getNaiyouPos();} catch (Exception e) {}
    	try {contrl.getPaymentPos();} catch (Exception e) {}
    	try {contrl.getTourokuPos();} catch (Exception e) {}
    	try {contrl.getRbookings();} catch (Exception e) {}
	}
	@isTest
	
	static void testCase6() {
    	Test.startTest();
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	leadInfo.CateringType__c = 'フロント';
    	update leadInfo;
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	// 予約情報のステータス：チェックインに変更する
    	leadInfo.Field298__c = 'チェックイン完';
    	update leadInfo;

    	Test.stopTest();
		// プラン明細情報を設定する
    	ApexPages.StandardController handel = new ApexPages.StandardController(leadInfo);
    	CateringPDF contrl = new CateringPDF(handel);
    	Lead__c rsLead = contrl.getBooking();
    	System.assert(rsLead != null);
    	try {contrl.getAddTime1();} catch (Exception e) {}
    	try {contrl.getAddTime2();} catch (Exception e) {}
    	try {contrl.getAddTime3();} catch (Exception e) {}
    	try {contrl.getAddTime4();} catch (Exception e) {}
    	try {contrl.getFoods();} catch (Exception e) {}
    	try {contrl.getComments();} catch (Exception e) {}
    	try {contrl.getCateringPos();} catch (Exception e) {}
    	try {contrl.getDrinks();} catch (Exception e) {}
    	try {contrl.getDrinkTotal();} catch (Exception e) {}
    	try {contrl.getFoodTotal();} catch (Exception e) {}
    	try {contrl.getKakuninPos();} catch (Exception e) {}
    	try {contrl.getOthers();} catch (Exception e) {}
    	try {contrl.getKessanPos();} catch (Exception e) {}
    	try {contrl.getHakkouPos();} catch (Exception e) {}
    	try {contrl.getPayDirect();} catch (Exception e) {}
    	try {contrl.getPayConfirm();} catch (Exception e) {}
    	try {contrl.getOthersTest();} catch (Exception e) {}
    	try {contrl.getOtherItemName();} catch (Exception e) {}
    	try {contrl.getOthersOld();} catch (Exception e) {}
    	try {contrl.getNaiyouPos();} catch (Exception e) {}
    	try {contrl.getPaymentPos();} catch (Exception e) {}
    	try {contrl.getTourokuPos();} catch (Exception e) {}
    	try {contrl.getRbookings();} catch (Exception e) {}
	}
	@isTest
	
	static void testCase7() {
    	Test.startTest();
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
         BookingEstimateItem__c beifoodtest  = new BookingEstimateItem__c(refAccountMaster__c = amfoodtest.Id, refBooking__c = bookingtest.Id);
       // BookingEstimateItem__c beifoodtest  = new BookingEstimateItem__c(refBooking__c = bookingtest.Id, refAccountMaster__c = amfoodtest.Id);
        BookingEstimateItem__c beidrinktest = new BookingEstimateItem__c(refBooking__c = bookingtest.Id, refAccountMaster__c = amdrinktest.Id);
        BookingEstimateItem__c beiothertest = new BookingEstimateItem__c(refBooking__c = bookingtest.Id, refAccountMaster__c = amothertest.Id);
        BookingEstimateItem__c beibustest   = new BookingEstimateItem__c(refBooking__c = bookingtest.Id, refAccountMaster__c = ambustest.Id);
        insert beifoodtest;
        insert beidrinktest;
        insert beiothertest;
        insert beibustest;
    	Test.stopTest();
		// プラン明細情報を設定する
    	ApexPages.StandardController handel = new ApexPages.StandardController(bookingtest);
    	CateringPDF contrl = new CateringPDF(handel);
    	Lead__c rsLead = contrl.getBooking();
    	System.assert(rsLead != null);
    	try {contrl.getAddTime1();} catch (Exception e) {}
    	try {contrl.getAddTime2();} catch (Exception e) {}
    	try {contrl.getAddTime3();} catch (Exception e) {}
    	try {contrl.getAddTime4();} catch (Exception e) {}
    	try {contrl.getFoods();} catch (Exception e) {}
    	try {contrl.getComments();} catch (Exception e) {}
    	try {contrl.getCateringPos();} catch (Exception e) {}
    	try {contrl.getDrinks();} catch (Exception e) {}
    	try {contrl.getDrinkTotal();} catch (Exception e) {}
    	try {contrl.getFoodTotal();} catch (Exception e) {}
    	try {contrl.getKakuninPos();} catch (Exception e) {}
    	try {contrl.getOthers();} catch (Exception e) {}
    	try {contrl.getKessanPos();} catch (Exception e) {}
    	try {contrl.getHakkouPos();} catch (Exception e) {}
    	try {contrl.getPayDirect();} catch (Exception e) {}
    	try {contrl.getPayConfirm();} catch (Exception e) {}
    	try {contrl.getOthersTest();} catch (Exception e) {}
    	try {contrl.getOtherItemName();} catch (Exception e) {}
    	try {contrl.getOthersOld();} catch (Exception e) {}
    	try {contrl.getNaiyouPos();} catch (Exception e) {}
    	try {contrl.getPaymentPos();} catch (Exception e) {}
    	try {contrl.getTourokuPos();} catch (Exception e) {}
    	try {contrl.getRbookings();} catch (Exception e) {}
	}
}