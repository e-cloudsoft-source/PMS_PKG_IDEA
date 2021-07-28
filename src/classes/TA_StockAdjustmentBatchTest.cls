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
@isTest(seeAllData=false)
private class TA_StockAdjustmentBatchTest {
   
	// ネット販売（AGTなし）
    static testMethod void netSalesStock_c001() {
        // 部屋タイプを作成して、該当部屋タイプから予約を作成する、
       
        // その後、バッチを起動して、テスト実施を行う
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Ta2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        // TLから部屋タイプを取得する
        TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
        typeOfRoom.RoomTypeCode__c = '002';
        typeOfRoom.RoomTypeName__c = '部屋タイプ1';
        update typeOfRoom;
        Lead__c lead = TestCommon.createBookingLead(Date.today(), typeOfRoom.id, 1);
        Test.startTest();
        	Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl());
        	TA_StockAdjustmentBatch batch = new TA_StockAdjustmentBatch();
        	DateTime nowDt = System.now();
        	TA_StockAdjustmentBatchExtend batch2 = new TA_StockAdjustmentBatchExtend(nowDt);
        	DataBase.executeBatch(batch2,1);
        Test.stopTest();
    }
	// ネット販売（AGTなし）
    static testMethod void netSalesStock_c001_s01() {
        // 部屋タイプを作成して、該当部屋タイプから予約を作成する、
       
        // その後、バッチを起動して、テスト実施を行う
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Ta2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        // TLから部屋タイプを取得する
        TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
        typeOfRoom.RoomTypeCode__c = '003';
        typeOfRoom.RoomTypeName__c = '部屋タイプ1';
        update typeOfRoom;
        Lead__c lead = TestCommon.createBookingLead(Date.today(), typeOfRoom.id, 1);
        Test.startTest();
        	Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl());
        	TA_StockAdjustmentBatch batch = new TA_StockAdjustmentBatch();
        	DateTime nowDt = System.now();
        	TA_StockAdjustmentBatchExtend batch2 = new TA_StockAdjustmentBatchExtend(nowDt);
        	DataBase.executeBatch(batch2,1);
        Test.stopTest();
    }
	// ネット販売（AGTあり）
    static testMethod void netSalesStock_c002() {

        // その後、バッチを起動して、テスト実施を行う
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Ta2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
		// 部屋タイプを作成して、該当部屋タイプから予約を作成する、
       	Account acc = TestCommon.createTravelCompany();
       	acc.SalesOfficeCompanyType__c = 'ネット';
       	acc.SalesOfficeCompanyCodeTAAPI__c = '164';
       	update acc;
       
        // TLから部屋タイプを取得する
        TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
        typeOfRoom.RoomTypeCode__c = '002';
        typeOfRoom.RoomTypeName__c = '部屋タイプ1';
        update typeOfRoom;

        Lead__c lead = TestCommon.createBookingLead(Date.today(), typeOfRoom.id, 1);
        
        delete [select id from StockChangeHisotry__c];
        Id orgTypeId = [select refTypeOfRooms__c from Lead__c where id = :lead.Id].refTypeOfRooms__c;
        lead.Rroom__c = null;
        lead.EntryTime__c = lead.EntryTime__c.addDays(1);
        lead.Departure__c = lead.Departure__c.addDays(1);
        lead.SalesOfficeInfoRef__c = acc.Id;
        update lead;
        Test.startTest();
        	Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true));
        	TA_StockAdjustmentBatch batch = new TA_StockAdjustmentBatch();
        	DateTime nowDt = System.now();
        	//TA_StockAdjustmentBatch batch2 = new TA_StockAdjustmentBatch(nowDt);
        	//DataBase.executeBatch(batch2,2);
        Test.stopTest(); 
    }
	// ネット販売（AGTなし）[ERROR]
    static testMethod void netSalesStock_c003() {
        // 部屋タイプを作成して、該当部屋タイプから予約を作成する、
       
        // その後、バッチを起動して、テスト実施を行う
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Ta2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        // TLから部屋タイプを取得する
        TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
        typeOfRoom.RoomTypeCode__c = '1';
        typeOfRoom.RoomTypeName__c = '部屋タイプ1';
        update typeOfRoom;
        Lead__c lead = TestCommon.createBookingLead(Date.today(), typeOfRoom.id, 1);
        Test.startTest();
        	//Test.setMock(WebServiceMock.class, new TestCommonMockImpl(true));
        	TA_StockAdjustmentBatch batch = new TA_StockAdjustmentBatch();
        	DateTime nowDt = System.now();
        	TA_StockAdjustmentBatchExtend batch2 = new TA_StockAdjustmentBatchExtend(nowDt);
        	DataBase.executeBatch(batch2,1);
        Test.stopTest();
    }

	// リアル（AGTあり）[エラー設定機能]
    static testMethod void RealSalesStock_c003() {

        // その後、バッチを起動して、テスト実施を行う
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Ta2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
		// 部屋タイプを作成して、該当部屋タイプから予約を作成する、
       	Account acc = TestCommon.createTravelCompany();
       	acc.SalesOfficeCompanyType__c = 'リアル';
       	acc.SalesOfficeCompanyCodeTAAPI__c = '103';	// TestCommonMockImplの設置と一致が必要
       	update acc;
       
        // TLから部屋タイプを取得する
        TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
        typeOfRoom.RoomTypeCode__c = '1';
        typeOfRoom.RoomTypeName__c = '部屋タイプ1';
        update typeOfRoom;

        Lead__c lead = TestCommon.createBookingLead(Date.today(), typeOfRoom.id, 1);
        
        delete [select id from StockChangeHisotry__c];
        Id orgTypeId = [select refTypeOfRooms__c from Lead__c where id = :lead.Id].refTypeOfRooms__c;
        lead.Rroom__c = null;
        lead.EntryTime__c = lead.EntryTime__c.addDays(1);
        lead.Departure__c = lead.Departure__c.addDays(1);
        lead.SalesOfficeInfoRef__c = acc.Id;
        update lead;
        delete [select id from StockChangeHisotry__c limit 1];
        Test.startTest();
        	Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true));
        	TA_StockAdjustmentBatch batch = new TA_StockAdjustmentBatch();
        	DateTime nowDt = System.now();
        	TA_StockAdjustmentBatchExtend batch2 = new TA_StockAdjustmentBatchExtend(nowDt);
        	DataBase.executeBatch(batch2,2);
        Test.stopTest(); 
    }
    // 通知ERRORケース
    static testMethod void NofityError () {
    	createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Ta2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        // TLから部屋タイプを取得する
        TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
        typeOfRoom.RoomTypeCode__c = '002';
        typeOfRoom.RoomTypeName__c = '部屋タイプ1';
        update typeOfRoom;
        Lead__c lead = TestCommon.createBookingLead(Date.today(), typeOfRoom.id, 1);
        Test.startTest();
        	Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true,true));
        	TA_StockAdjustmentBatch batch = new TA_StockAdjustmentBatch();
        	DateTime nowDt = System.now();
        	TA_StockAdjustmentBatchExtend batch2 = new TA_StockAdjustmentBatchExtend(nowDt);
        	DataBase.executeBatch(batch2,1);
        Test.stopTest();
    }
    private static void createConfigDoc() {
    	TestCommon.createTa2WayConfigDoc();
    }
    
}