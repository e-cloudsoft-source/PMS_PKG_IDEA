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
@isTest(SeeAllData=false)
private class CalendarExtendTest {
	
	// 支店なし、
    static testMethod void DateRange_Case1() {
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	TestCommon.createBatchRequestXml();
    	String defaultTier = comDef.RackRateTableTierDefault__c;
    	String defaultPeos = comDef.RackRateTablePeopleDefault__c;
    	Date dt = Date.today();
        // 祝日情報作成
        createHolidayDoc();
        // 部屋と宴会場データ作成
        Room__c enkaiRoom = TestCommon.createEnkaiRooms();
        // 客室情報を作成する
        Room__c guestRoom = TestCommon.createRooms();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Room__c where UseOfRoom__c = '客室'].size(), 1);
        // 2015/12/01 Assert END
        // Tier情報設定を行う
        RackRateTable__c raceRate = TestCommon.createRaceRateInfo(guestRoom.TypeRoomRef__c, defaultTier, defaultPeos);
        // 当日予約日データを作成する、集計情報を確認する
        // 宴会場予約作成
        Lead__c enkaiLead = TestCommon.createEnkaiLead(dt, enkaiRoom.Id);
        // 普通の予約情報を作成する
        Lead__c normalLead = TestCommon.createBookingLead(dt, guestRoom.TypeRoomRef__c, 0);
        
        Test.startTest();
        // Calendar表示する
        CalendarExtend cal = new CalendarExtend();
        cal.thisYear = 2014;
        cal.thisMonth = 1;
        cal.gotoYearMonth();
        cal.toPrev();
        cal.toNext();
        Test.stopTest();
    }
	// 支店あり、
    static testMethod void DateRange_Case2() {
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	TestCommon.createBatchRequestXml();
    	String defaultTier = comDef.RackRateTableTierDefault__c;
    	String defaultPeos = comDef.RackRateTablePeopleDefault__c;
    	Date dt = Date.today();
        // 祝日情報作成
        createHolidayDoc();
        // 部屋と宴会場データ作成
        Room__c enkaiRoom = TestCommon.createEnkaiRooms();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Room__c where UseOfRoom__c = '宴会場'].size(), 1);
        // 2015/12/01 Assert END
        // 客室情報を作成する[支店]
        ShopInformation__c shop1 = TestCommon.createShopInfo();
        ShopInformation__c shop2 = TestCommon.createShopInfo();
        
        List<TypeOfRooms__c> roomType1 = TestCommon.createTypeOfRoomByShop(shop1.Id, 1);
        List<TypeOfRooms__c> roomType2 = TestCommon.createTypeOfRoomByShop(shop2.Id, 1);
        // Tier情報設定を行う
        RackRateTable__c raceRate1 = TestCommon.createRaceRateInfo(roomType1[0].Id, defaultTier, defaultPeos);
        RackRateTable__c raceRate2 = TestCommon.createRaceRateInfo(roomType2[0].Id, defaultTier, defaultPeos);
        // 当日予約日データを作成する、集計情報を確認する
        // 宴会場予約作成
        Lead__c enkaiLead = TestCommon.createEnkaiLead(dt, enkaiRoom.Id);
        // 普通の予約情報を作成する
        Lead__c normalLead1 = TestCommon.createBookingLead(dt, roomType1[0].Id, 0);
        Lead__c normalLead2 = TestCommon.createBookingLead(dt, roomType2[0].Id, 0);
        
 		User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	loginUser.ShopCode__c = shop1.shopCode__c;
    	update loginUser;
    	
        Test.startTest();
        system.runAs(loginUser) {
        // Calendar表示する
        CalendarExtend cal = new CalendarExtend();
        cal.thisYear = 2014;
        cal.thisMonth = 1;
        cal.branchShopNm = cal.branchShopLst[0].getValue();
        cal.gotoSwitchShop();
        }
        Test.stopTest();
    }
    private static void createHolidayDoc() {
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'HolidayDefineXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf('<root><year value="2014">'
    				+'<dates label="元日">2014/01/01</dates>'
    				+'<dates label="成人の日">2014/01/13</dates>'
    				+'<dates label="春分の日">2014/03/21</dates>'
    				+'<dates label="文化の日">2014/11/03</dates>'
    				+'</year></root>');
    	insert item;
    }
}