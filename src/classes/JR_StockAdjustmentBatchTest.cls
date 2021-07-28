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
private class JR_StockAdjustmentBatchTest {

    // ネット販売（AGTなし）[正常調整ケース]
    static testMethod void netSalesStock_c001() {
        // 部屋タイプを作成して、該当部屋タイプから予約を作成する、
       
        // その後、バッチを起動して、テスト実施を行う
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'JRServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        // TLから部屋タイプを取得する
        TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
        typeOfRoom.RoomTypeCode__c = '002';
        typeOfRoom.RoomTypeName__c = '部屋タイプ1';
        update typeOfRoom;
        Lead__c lead = TestCommon.createBookingLead(Date.today(), typeOfRoom.id, 1);
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl());
            JR_StockAdjustmentBatch batch = new JR_StockAdjustmentBatch();
            DateTime nowDt = System.now();
            JR_StockAdjustmentBatchExtend batch2 = new JR_StockAdjustmentBatchExtend(new List<Id>{typeOfRoom.id});
            DataBase.executeBatch(batch2,1);
        Test.stopTest();
    }

    // ネット販売（AGTなし）[部屋タイプが対象外]
    static testMethod void netSalesStock_c001_s02() {
        // 部屋タイプを作成して、該当部屋タイプから予約を作成する、
       
        // その後、バッチを起動して、テスト実施を行う
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'JRServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        // TLから部屋タイプを取得する
        TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
        typeOfRoom.RoomTypeCode__c = 'A03';
        typeOfRoom.RoomTypeName__c = '部屋タイプA';
        update typeOfRoom;
        Lead__c lead = TestCommon.createBookingLead(Date.today(), typeOfRoom.id, 1);
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl());
            JR_StockAdjustmentBatch batch = new JR_StockAdjustmentBatch();
            DateTime nowDt = System.now();
            JR_StockAdjustmentBatchExtend batch2 = new JR_StockAdjustmentBatchExtend(new List<Id>{typeOfRoom.id});
            DataBase.executeBatch(batch2,1);
        Test.stopTest();
    }

    // ネット販売（AGTなし）[店舗定義はXMLに未定義]
    static testMethod void netSalesStock_c001_s03() {
        // 部屋タイプを作成して、該当部屋タイプから予約を作成する、
        ShopInformation__c shop = TestCommon.createShopInfo();
        // その後、バッチを起動して、テスト実施を行う
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'JRServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        // TLから部屋タイプを取得する
        TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
        typeOfRoom.RoomTypeCode__c = 'A03';
        typeOfRoom.RoomTypeName__c = '部屋タイプA';
        typeOfRoom.ShopInfoRef__c = shop.Id;
        update typeOfRoom;
        Lead__c lead = TestCommon.createBookingLead(Date.today(), typeOfRoom.id, 1);
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl());
            JR_StockAdjustmentBatch batch = new JR_StockAdjustmentBatch();
            DateTime nowDt = System.now();
            JR_StockAdjustmentBatchExtend batch2 = new JR_StockAdjustmentBatchExtend(new List<Id>{typeOfRoom.id});
            DataBase.executeBatch(batch2,1);
        Test.stopTest();
    }
    // API連携異常の場合[TestCommonMockImpl]
    // ネット販売（AGTなし）[店舗定義はXMLに未定義]
    static testMethod void netSalesStock_c001_s04() {
        // その後、バッチを起動して、テスト実施を行う
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'JRServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        // TLから部屋タイプを取得する
        TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
        typeOfRoom.RoomTypeCode__c = '03';
        typeOfRoom.RoomTypeName__c = '部屋タイプ03';
        update typeOfRoom;
        Lead__c lead = TestCommon.createBookingLead(Date.today(), typeOfRoom.id, 1);
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(false,true));
            JR_StockAdjustmentBatch batch = new JR_StockAdjustmentBatch();
            DateTime nowDt = System.now();
            JR_StockAdjustmentBatchExtend batch2 = new JR_StockAdjustmentBatchExtend(new List<Id>{typeOfRoom.id});
            DataBase.executeBatch(batch2,1);
        Test.stopTest();
    }
    private static void createConfigDoc() {
        TestCommon.createJr2WayConfigDoc();
    }
}