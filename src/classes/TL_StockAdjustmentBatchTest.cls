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
private class TL_StockAdjustmentBatchTest {

	// ネット販売（AGTなし）
    static testMethod void netSalesStock_c001() {
        // 部屋タイプを作成して、該当部屋タイプから予約を作成する、
       
        // その後、バッチを起動して、テスト実施を行う
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Tl2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        // TLから部屋タイプを取得する
        TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
        typeOfRoom.RoomTypeCode__c = '1';
        typeOfRoom.RoomTypeName__c = '部屋タイプ1';
        update typeOfRoom;
        Lead__c lead = TestCommon.createBookingLead(Date.today(), typeOfRoom.id, 1);
        Test.startTest();
        	Test.setMock(WebServiceMock.class, new TestCommonMockImpl());
        	TL_StockAdjustmentBatch batch = new TL_StockAdjustmentBatch();
        	DateTime nowDt = System.now().addDays(-1);
        	TL_StockAdjustmentBatchExtend batch2 = new TL_StockAdjustmentBatchExtend(nowDt);
        	DataBase.executeBatch(batch2,1);
        Test.stopTest();
    }

	// ネット販売（AGTあり）
    static testMethod void netSalesStock_c002() {

        // その後、バッチを起動して、テスト実施を行う
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Tl2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
		// 部屋タイプを作成して、該当部屋タイプから予約を作成する、
       	Account acc = TestCommon.createTravelCompany();
       	acc.SalesOfficeCompanyType__c = 'ネット';
       	acc.SalesOfficeCompanyCodeTLAPI__c = '164';
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
        Test.startTest();
        	Test.setMock(WebServiceMock.class, new TestCommonMockImpl());
        	TL_StockAdjustmentBatch batch = new TL_StockAdjustmentBatch();
        	DateTime nowDt = System.now();
        	//TL_StockAdjustmentBatch batch2 = new TL_StockAdjustmentBatch(nowDt);
        	//DataBase.executeBatch(batch2,2);
        Test.stopTest(); 
    }
	// ネット販売（AGTなし）[ERROR]
    static testMethod void netSalesStock_c003() {
        // 部屋タイプを作成して、該当部屋タイプから予約を作成する、
       
        // その後、バッチを起動して、テスト実施を行う
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Tl2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        // TLから部屋タイプを取得する
        TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
        typeOfRoom.RoomTypeCode__c = '1';
        typeOfRoom.RoomTypeName__c = '部屋タイプ1';
        update typeOfRoom;
        Lead__c lead = TestCommon.createBookingLead(Date.today(), typeOfRoom.id, 1);
        Test.startTest();
        	Test.setMock(WebServiceMock.class, new TestCommonMockImpl(true));
        	TL_StockAdjustmentBatch batch = new TL_StockAdjustmentBatch();
        	DateTime nowDt = System.now().addDays(-1);
        	TL_StockAdjustmentBatchExtend batch2 = new TL_StockAdjustmentBatchExtend(nowDt);
        	DataBase.executeBatch(batch2,1);
        Test.stopTest();
    }
  
	// リアル（AGTあり）
    static testMethod void RealSalesStock_c001() {

        // その後、バッチを起動して、テスト実施を行う
        createConfigDoc();
		// 部屋タイプを作成して、該当部屋タイプから予約を作成する、
       	Account acc = TestCommon.createTravelCompany();
       	acc.SalesOfficeCompanyType__c = 'リアル';
       	acc.SalesOfficeCompanyCodeTLAPI__c = '103';	// TestCommonMockImplの設置と一致が必要
       	update acc;
       
        // TLから部屋タイプを取得する
        TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
        typeOfRoom.RoomTypeCode__c = '17T101';
        typeOfRoom.RoomTypeName__c = '部屋タイプ1';
        update typeOfRoom;

        Lead__c lead = TestCommon.createBookingLead(Date.today(), typeOfRoom.id, 1);
        StockChangeHisotry__c stock = [select id,agtRef__c,AgtRef__r.SalesOfficeCompanyType__c from StockChangeHisotry__c ];
        stock.agtRef__c = acc.Id;
        update stock;
        /*
        delete [select id from StockChangeHisotry__c where StockChangeDate__c = :Date.today()];
        Id orgTypeId = [select refTypeOfRooms__c from Lead__c where id = :lead.Id].refTypeOfRooms__c;
        lead.Rroom__c = null;
        lead.EntryTime__c = lead.EntryTime__c.addDays(1);
        lead.Departure__c = lead.Departure__c.addDays(1);
        lead.SalesOfficeInfoRef__c = acc.Id;
        update lead;*/
        Test.startTest();
        	Test.setMock(WebServiceMock.class, new TestCommonMockImpl());
        	DateTime nowDt = System.now().addDays(-1);
        	TL_StockAdjustmentBatchExtend batch2 = new TL_StockAdjustmentBatchExtend(nowDt);
        	DataBase.executeBatch(batch2,1);	
        Test.stopTest(); 
        system.debug(loggingLevel.INFO, [select id,name,ProcessLog__c from CooperationResult__c]);
    }

	// リアル（AGTあり）[TL側に該当へ部屋タイプを定義されない]
    static testMethod void RealSalesStock_c002() {

        // その後、バッチを起動して、テスト実施を行う
        createConfigDoc();
		// 部屋タイプを作成して、該当部屋タイプから予約を作成する、
       	Account acc = TestCommon.createTravelCompany();
       	acc.SalesOfficeCompanyType__c = 'リアル';
       	acc.SalesOfficeCompanyCodeTLAPI__c = '103';	// TestCommonMockImplの設置と一致が必要
       	update acc;
       
        // TLから部屋タイプを取得する
        TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
        typeOfRoom.RoomTypeCode__c = '2';
        typeOfRoom.RoomTypeName__c = '部屋タイプ2';
        update typeOfRoom;

        Lead__c lead = TestCommon.createBookingLead(Date.today(), typeOfRoom.id, 1);
        /*
        delete [select id from StockChangeHisotry__c where StockChangeDate__c = :Date.today()];
        Id orgTypeId = [select refTypeOfRooms__c from Lead__c where id = :lead.Id].refTypeOfRooms__c;
        lead.Rroom__c = null;
        lead.EntryTime__c = lead.EntryTime__c.addDays(1);
        lead.Departure__c = lead.Departure__c.addDays(1);*/
        lead.SalesOfficeInfoRef__c = acc.Id;
        update lead;
        Test.startTest();
        	Test.setMock(WebServiceMock.class, new TestCommonMockImpl());
        	DateTime nowDt = System.now().addDays(-1);
			// 次のスケジュールを起動する
			TL_StockAdjustmentBatch schedule= new TL_StockAdjustmentBatch(nowDt);
			DateTime nowTime = DateTime.now().addSeconds(60);
			// 起動ＣＲＯＮを設定する
			String timeStr = nowTime.format('yyyyMMddHHmmss');
			String yy = timeStr.substring(0,4);
			String mm = timeStr.substring(4,6);
			String dd = timeStr.substring(6,8);
			String hh = timeStr.substring(8,10);
			String ms = timeStr.substring(10,12);
			String ss = timeStr.substring(12,14);
			String sch = ss + ' ' +
			       ms + ' ' +
			       hh + ' ' +
			       dd + ' ' +
			       mm + ' ' +
			       ' ? ' + yy;
			String jobName = 'TL_StockAdjustmentBatch_' + DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
			String jobId = system.schedule(jobName, sch, schedule);
			/*
        	TL_StockAdjustmentBatchExtend batch2 = new TL_StockAdjustmentBatchExtend(nowDt);
        	DataBase.executeBatch(batch2);*/
        Test.stopTest(); 
    }
	// リアル（AGTあり）[エラー設定機能]
    static testMethod void RealSalesStock_c003() {

        // その後、バッチを起動して、テスト実施を行う
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Tl2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
		// 部屋タイプを作成して、該当部屋タイプから予約を作成する、
       	Account acc = TestCommon.createTravelCompany();
       	acc.SalesOfficeCompanyType__c = 'リアル';
       	acc.SalesOfficeCompanyCodeTLAPI__c = '103';	// TestCommonMockImplの設置と一致が必要
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
        	Test.setMock(WebServiceMock.class, new TestCommonMockImpl(true));
        	TL_StockAdjustmentBatch batch = new TL_StockAdjustmentBatch();
        	DateTime nowDt = System.now().addDays(-1);
        	TL_StockAdjustmentBatchExtend batch2 = new TL_StockAdjustmentBatchExtend(nowDt);
        	DataBase.executeBatch(batch2,2);
        Test.stopTest(); 
    }

    private static void createConfigDoc() {
    	TestCommon.createTl2WayConfigDoc();
    }

}