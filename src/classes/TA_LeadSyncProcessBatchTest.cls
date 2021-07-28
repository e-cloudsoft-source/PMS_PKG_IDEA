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
private class TA_LeadSyncProcessBatchTest {

    static testMethod void myUnitTest1() {
        // TO DO: implement unit test
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Ta2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        //連絡結果　予約取り込待ち
        CooperationResult__c coo = TestCommon.createLeadImportAndWaitImpot('','TA');
        TypeOfRooms__c roomType = TestCommon.createTypeOfRoom();
        createSyncXml(coo.id,'NewBookReport',roomType.RoomTypeCode__c);
        
        Test.startTest();
    	Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl());
    	TA_LeadSyncProcessBatch batch = new TA_LeadSyncProcessBatch();    
		ID batchprocessid = Database.executeBatch(batch,1);
        Test.stopTest(); 
    }
    
    /**
    *case :not have plan 
    */
    static testMethod void myUnitTest2() {
        // TO DO: implement unit test
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Ta2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
         //連絡結果　予約取り込待ち
        CooperationResult__c coo = TestCommon.createTaLeadImportAndImpotNG('');
        createAttachment(coo.id);
        createCommonAcc();
        
        Test.startTest();
    	Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl());
    	TA_LeadSyncProcessBatch batch = new TA_LeadSyncProcessBatch();    
		ID batchprocessid = Database.executeBatch(batch,1);
        Test.stopTest();
        System.debug(loggingLevel.info, [select id,ProcessLog__c from CooperationResult__c where id = :coo.id]); 
        
    }
    /**
    * 連絡結果　予約取り込待ち
    */
    static testMethod void myUnitTest3() {
        // TO DO: implement unit test
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Ta2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        CommDefine__c newDef = new CommDefine__c(
	    	RoomTypeReport__c = '$0001 客室タイプ別予約表',
	    	Posreg__c = '0',
	    	UnitPriceDefKb__c = 2,
	    	ScheduleResultMailAddress__c = '1@a.com,2@b.com,3@c.com,4@d.com,5@e.com,6@f.com',
			RoomIndicatorInfoMaxLength__c = 4,
			RoomSortDiv__c = '1',
			BookingMansDef__c = 1,
			BookingFemailsDef__c = 0,
			BookingChildrenDef__c = 0,
			LeadSplitDivCode__c = 2
		);	
		insert newDef;
         //連絡結果　予約取り込待ち
        CooperationResult__c coo = TestCommon.createLeadImportAndWaitImpot('','TA');
        createAttachment(coo.id);
        Test.startTest();
    	Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true));
    	TA_LeadSyncProcessBatch batch = new TA_LeadSyncProcessBatch();    
		ID batchprocessid = Database.executeBatch(batch,1);
        Test.stopTest(); 
    }
    
    /**
    * case :have plan no detail
    */
    static testMethod void myUnitTest4() {
        // TO DO: implement unit test
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Ta2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END

        JMST__c taxMst =  TestCommon.createTaxMst();
    	Plan__c plan = new Plan__c();
    	plan.name = 'テストプランデータ' + CommUtils.getRandom(5);
    	plan.PlanNo__c = CommUtils.getRandom(10);
    	plan.Price__c = 35000;
    	plan.PackageCode__c = '3333';
    	plan.JmstRef__c = taxMst.Id;
    	insert plan;
    	
         //連絡結果　予約取り込待ち
        CooperationResult__c coo = TestCommon.createLeadImportAndWaitImpot('','TA');
        createattachmentCaseAllMessage(coo.id);
        createCommonAcc();
        
        Test.startTest();
    	Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true));
    	TA_LeadSyncProcessBatch batch = new TA_LeadSyncProcessBatch();    
		ID batchprocessid = Database.executeBatch(batch,1);
        Test.stopTest(); 
        
    }
    
    
    /**
    *case : have detail no 室料 
    */
    static testMethod void myUnitTes5() {
        // TO DO: implement unit test
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Ta2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        Plan__c plan = TestCommon.createPlan();
        plan.PackageCode__c = '3333';
        update plan;
        createCommonAcc();
        
         //連絡結果　予約取り込待ち
        CooperationResult__c coo = TestCommon.createTaLeadImportAndImpotNG('');
        coo.shopCode__c = '';
        update coo;
        
        Test.startTest();
    	Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true));
    	TA_LeadSyncProcessBatch batch = new TA_LeadSyncProcessBatch();    
		ID batchprocessid = Database.executeBatch(batch,1);
        Test.stopTest(); 
    }
    
    /**
    *case :not have have detail  室料 > 0
    */
    static testMethod void myUnitTest6() {
        // TO DO: implement unit test
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Ta2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
         //連絡結果　予約取り込待ち
        //TestCommon.createLeadImportAndWaitImpot('','TA');
        createPlanHadHoomNoZero();
         TypeOfRooms__c typeItem = new TypeOfRooms__c(
            Name = '純和風客室(バスルーム無し)',
            RoomTypeCode__c = '1',
            MaxRooms__c = 99); 
        insert typeItem;
        Room__c roomItem = new Room__c(
    		Name = '部屋テスト' + CommUtils.getRandom(6),
    		CapacityHaku__c = 4,
    		Capacity__c = 2,
    		Area__c = '本館',
    		Floor__c = '1F',
    		UseOfRoom__c = '客室',
    		heyadashiryouryou__c = 40000,
    		TypeRoomRef__c = typeItem.Id,
    		heyadashiryou__c = 25000);
		insert roomItem;
		
        RoomsStatus__c rs = new RoomsStatus__c(RoomRef__c = roomItem.id,
        									Status__c = '故障',
        									StatusBeginDate__c = CommUtils.stringToDate('2013-08-18'),
        									StatusEndDate__c =  CommUtils.stringToDate('2013-08-19'));
        insert rs;
        createCommonAcc();
         //連絡結果　予約取り込待ち
        CooperationResult__c coo = TestCommon.createLeadImportAndWaitImpot('','TA');
        createAttachment(coo.id);
        
        Test.startTest();
    	Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true));
    	TA_LeadSyncProcessBatch batch = new TA_LeadSyncProcessBatch();    
		ID batchprocessid = Database.executeBatch(batch,1);
        Test.stopTest(); 
    }
    
    
    /**
    * case :not have have detail  室料 = 0
    */
    static testMethod void myUnitTest7() {
        // TO DO: implement unit test
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Ta2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
         //連絡結果　予約取り込待ち
        //TestCommon.createLeadImportAndWaitImpot('','TA');
        TestCommon.createTypeOfRoom();
        createPlanHadHoomZero(null);
        createCommonAcc();
         //連絡結果　予約取り込待ち
        CooperationResult__c coo = TestCommon.createLeadImportAndWaitImpot('','TA');
        createAttachment(coo.id);
        
        Test.startTest();
    	Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true));
    	TA_LeadSyncProcessBatch batch = new TA_LeadSyncProcessBatch();    
		ID batchprocessid = Database.executeBatch(batch,1);
        Test.stopTest(); 
    }
    
    /**
    * case :bookinginfo cancel
    */
    static testMethod void myUnitTest8() {
        // TO DO: implement unit test
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Ta2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        DateTime startDate = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
        
        LeadIndex__c item = new LeadIndex__c(
    		ID__c = String.valueOf('101731864'),
    		Nights__c = 1,
     		EntryTime__c = '10:00',
    		EntryDate__c = startDate.date(),
    		DepartureTime__c = '15:30',
    		DepartureDate__c = startDate.addDays(1).date(),
			EventSource__c = 'FromTravelAgency',
			APPNAME__c = 'TA',
			Rooms__c = 1
    	);
    	insert item;
    	TypeOfRooms__c typeItem = new TypeOfRooms__c(
            Name = '純和風客室(バスルーム無し)',
            RoomTypeCode__c = '1',
            MaxRooms__c = 99); 
        insert typeItem;
        Room__c roomItem = new Room__c(
    		Name = '部屋テスト' + CommUtils.getRandom(6),
    		CapacityHaku__c = 4,
    		Capacity__c = 2,
    		Area__c = '本館',
    		Floor__c = '1F',
    		UseOfRoom__c = '客室',
    		heyadashiryouryou__c = 40000,
    		TypeRoomRef__c = typeItem.Id,
    		heyadashiryou__c = 25000);
		insert roomItem;
		
        RoomsStatus__c rs = new RoomsStatus__c(RoomRef__c = roomItem.id,
        									Status__c = '故障',
        									StatusBeginDate__c = CommUtils.stringToDate('2013-07-22'),
        									StatusEndDate__c =  CommUtils.stringToDate('2013-07-23'));
        insert rs;
         //連絡結果　予約取り込待ち
        CooperationResult__c coo = TestCommon.createTaLeadImportAndImpotNG('');
        TestCommon.createTypeOfRoom();
        createPlanHadHoomZero(null);
        createCommonAcc();
        createDocementActionUpdate(coo.id);
        coo.shopCode__c = '';
        update coo;
        
        Test.startTest();
    	Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true));
    	TA_LeadSyncProcessBatch batch = new TA_LeadSyncProcessBatch();    
		ID batchprocessid = Database.executeBatch(batch,2);
        Test.stopTest(); 
    }
    /**
    * case :bookinginfo had member 
    */
    static testMethod void myUnitTest9() {
        // TO DO: implement unit test
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Ta2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        DateTime startDate = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
        
        LeadIndex__c item = new LeadIndex__c(
    		ID__c = String.valueOf('101731864'),
    		Nights__c = 1,
     		EntryTime__c = '10:00',
    		EntryDate__c = startDate.date(),
    		DepartureTime__c = '15:30',
    		DepartureDate__c = startDate.addDays(1).date(),
			EventSource__c = 'FromTravelAgency',
			APPNAME__c = 'TA',
			Rooms__c = 1
    	);
    	insert item;
    	
         //連絡結果　予約取り込待ち
        CooperationResult__c coo = TestCommon.createTaLeadImportAndImpotNG('');
        TestCommon.createTypeOfRoom();
        createPlanHadHoomZero(null);
        createCommonAcc();
        createDocumentHadMember(coo.id);
        coo.shopCode__c = '';
        update coo;
        
        Test.startTest();
    	Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true));
    	TA_LeadSyncProcessBatch batch = new TA_LeadSyncProcessBatch();    
		ID batchprocessid = Database.executeBatch(batch,2);
        Test.stopTest(); 
    }
    /**
    * case :bookinginfo had Roomrate 
    */
    static testMethod void myUnitTest10() {
        // TO DO: implement unit test
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Ta2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        DateTime startDate = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
        
        LeadIndex__c item = new LeadIndex__c(
    		ID__c = String.valueOf('101731864'),
    		Nights__c = 1,
     		EntryTime__c = '10:00',
    		EntryDate__c = startDate.date(),
    		DepartureTime__c = '15:30',
    		DepartureDate__c = startDate.addDays(1).date(),
			EventSource__c = 'FromTravelAgency',
			APPNAME__c = 'TA',
			Rooms__c = 1
    	);
    	insert item;
    	
         //連絡結果　予約取り込待ち
        CooperationResult__c coo = TestCommon.createTaLeadImportAndImpotNG('');
        TypeOfRooms__c typeItem = new TypeOfRooms__c(
            Name = 'デラックスシングル（禁煙）(シングル)',
            RoomTypeCode__c = '20',
            MaxRooms__c = 99); 
        insert typeItem;
        
        Room__c roomItem = new Room__c(
    		Name = '部屋テスト' + CommUtils.getRandom(6),
    		CapacityHaku__c = 4,
    		Capacity__c = 2,
    		Area__c = '本館',
    		Floor__c = '1F',
    		UseOfRoom__c = '客室',
    		heyadashiryouryou__c = 40000,
    		TypeRoomRef__c = typeItem.Id,
    		heyadashiryou__c = 25000);
		insert roomItem;
		
        createPlanHadHoomZero(null);
        RoomsStatus__c rs = new RoomsStatus__c(RoomRef__c = roomItem.id,
        									Status__c = '故障',
        									StatusBeginDate__c = CommUtils.stringToDate('2013-08-18'),
        									StatusEndDate__c =  CommUtils.stringToDate('2013-08-19'));
        insert rs;
        createCommonAcc();
        createDocumentRoomRate(coo.id);
        coo.shopCode__c = '';
        update coo;
        
        Test.startTest();
    	Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true));
    	TA_LeadSyncProcessBatch batch = new TA_LeadSyncProcessBatch();    
		ID batchprocessid = Database.executeBatch(batch,2);
        Test.stopTest(); 
    }
    /**
    * case :bookinginfo had Roomrate 
    */
    static testMethod void myUnitTest11() {
        // TO DO: implement unit test
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Ta2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        DateTime startDate = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
        
        LeadIndex__c item = new LeadIndex__c(
    		ID__c = String.valueOf('106557046'),
    		Nights__c = 1,
     		EntryTime__c = '10:00',
    		EntryDate__c = startDate.date(),
    		DepartureTime__c = '15:30',
    		DepartureDate__c = startDate.addDays(1).date(),
			EventSource__c = 'FromTravelAgency',
			APPNAME__c = 'TA',
			Rooms__c = 1
    	);
    	insert item;
    	
         //連絡結果　予約取り込待ち
        CooperationResult__c coo = TestCommon.createTaLeadImportAndImpotNG('');
        TestCommon.createTypeOfRoom();
        createPlanHadHoomZero(null);
        createCommonAcc();
        createDocumentRoomRate(coo.id);
        coo.shopCode__c = '';
        update coo;
        
        Test.startTest();
    	Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true));
    	TA_LeadSyncProcessBatch batch = new TA_LeadSyncProcessBatch();    
		ID batchprocessid = Database.executeBatch(batch,2);
        Test.stopTest(); 
    }
    /**
    * case :bookinginfo error
    */
    static testMethod void myUnitTest12() {
        // TO DO: implement unit test
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Ta2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END

         //連絡結果　予約取り込待ち
        CooperationResult__c coo = TestCommon.createTaLeadImportAndImpotNG('');
        TestCommon.createTypeOfRoom();
        createPlanHadHoomZero(null);
        createDocementActionCancel(coo.id);
        coo.shopCode__c = '';
        update coo;
        
        Test.startTest();
    	Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true));
    	TA_LeadSyncProcessBatch batch = new TA_LeadSyncProcessBatch();    
		ID batchprocessid = Database.executeBatch(batch);
        Test.stopTest(); 
    }
    /**
    * case :bookinginfo lead__c cancel 
    */
    static testMethod void myUnitTest13() {
        // TO DO: implement unit test
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Ta2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        DateTime startDate = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
        
        LeadIndex__c item = new LeadIndex__c(
    		ID__c = String.valueOf('107338085'),
    		Nights__c = 1,
     		EntryTime__c = '10:00',
    		EntryDate__c = startDate.date(),
    		DepartureTime__c = '15:30',
    		DepartureDate__c = startDate.addDays(1).date(),
			EventSource__c = 'FromTravelAgency',
			APPNAME__c = 'TA',
			Rooms__c = 1
    	);
    	insert item;
    	
         //連絡結果　予約取り込待ち
        CooperationResult__c coo = TestCommon.createTaLeadImportAndImpotNG('');
        TestCommon.createTypeOfRoom();
        coo.shopCode__c = '';
        update coo;
        createPlanHadHoomZero(null);
        createCommonAcc();
        createDocumentSetDiv2(coo.id);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true));
    	TA_LeadSyncProcessBatch batch = new TA_LeadSyncProcessBatch();    
		ID batchprocessid = Database.executeBatch(batch);
        Test.stopTest(); 
    }
    
    /**
    * case :bookinginfo lead__c cancel 
    */
    static testMethod void myUnitTest14() {
        // TO DO: implement unit test
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Ta2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        DateTime startDate = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
        
        LeadIndex__c item = new LeadIndex__c(
    		ID__c = String.valueOf('107338085'),
    		Nights__c = 1,
     		EntryTime__c = '10:00',
    		EntryDate__c = startDate.date(),
    		DepartureTime__c = '15:30',
    		DepartureDate__c = startDate.addDays(1).date(),
			EventSource__c = 'FromTravelAgency',
			APPNAME__c = 'TA',
			Rooms__c = 1
    	);
    	insert item;
    	
         //連絡結果　予約取り込待ち
        CooperationResult__c coo = TestCommon.createTaLeadImportAndImpotNG('');
        TestCommon.createTypeOfRoom();
        coo.shopCode__c = '';
        update coo;
        createPlanHadHoomZero(null);
        createCommonAcc();
        createDocumentBlank(coo.id);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true));
    	TA_LeadSyncProcessBatch batch = new TA_LeadSyncProcessBatch();    
		ID batchprocessid = Database.executeBatch(batch);
        Test.stopTest(); 
    }
    /**
    * case :bookinginfo no dataid 
    */
    static testMethod void myUnitTest15() {
        // TO DO: implement unit test
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Ta2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        DateTime startDate = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
        
        LeadIndex__c item = new LeadIndex__c(
    		ID__c = String.valueOf('107338085'),
    		Nights__c = 1,
     		EntryTime__c = '10:00',
    		EntryDate__c = startDate.date(),
    		DepartureTime__c = '15:30',
    		DepartureDate__c = startDate.addDays(1).date(),
			EventSource__c = 'FromTravelAgency',
			APPNAME__c = 'TA',
			Rooms__c = 1
    	);
    	insert item;
    	JMST__c taxMst =  TestCommon.createTaxMst();
    	// 室単料　会計商品
        AccountMaster__c optionName = new AccountMaster__c(
           Name = 'Option_Name',
           ActionType__c = CommConst.PROD_ACTION_TYPE_RP,
           jmstRef__c = taxMst.Id,
           StsTaxfee__c = '0',
           Field3__c = 'OptionCode',         // 商品コード
           Field5__c = 1050,
           ServiceRate__c = 10,
           SpecialTax__c = 100
        );
    	
         //連絡結果　予約取り込待ち
        CooperationResult__c coo = TestCommon.createTaLeadImportAndImpotNG('');
        TestCommon.createTypeOfRoom();
        coo.shopCode__c = '';
        update coo;
        createPlanHadHoomZero(null);
        createCommonAcc();
        createDocumentNoData(coo.id);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true));
    	TA_LeadSyncProcessBatch batch = new TA_LeadSyncProcessBatch();    
		ID batchprocessid = Database.executeBatch(batch);
        Test.stopTest(); 
    }
    /**
    * case :bookinginfo no dataid 
    */
    
    static testMethod void myUnitTest16() {
        // TO DO: implement unit test
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Ta2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        DateTime startDate = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
        LeadIndex__c item = new LeadIndex__c(
    		ID__c = String.valueOf('106535992'),
    		Nights__c = 1,
     		EntryTime__c = '10:00',
    		EntryDate__c = startDate.date(),
    		DepartureTime__c = '15:30',
    		DepartureDate__c = startDate.addDays(1).date(),
			EventSource__c = 'FromTravelAgency',
			APPNAME__c = 'TA',
			Rooms__c = 1
    	);
    	insert item;
        
        Contact guest = TestCommon.createContact();
    	// 連泊データを自動作成
    	Lead__c item1 = new Lead__c(
    	   name = '予約単体テスト_' + System.now(), // 予約名
    	   Relcontact__c = guest.Id,                  // 顧客名
    	   ReservedStatus__c = '確認中',
    	   ReservedDate__c = System.now(),
    	   LeadIndexRef__c = item.id,
    	   ReservedContact__c = 'Ono',
    	   EntryTime__c = startDate,
    	   Field4__c = '10:00',
    	   Departure__c = startDate,
    	   Field3__c = '16:00',
    	   StayPersons__c = 4,
    	   Field2__c = 'FAX');
    	insert item1;
    	
        //連絡結果　予約取り込待ち
        CooperationResult__c coo = TestCommon.createLeadImportAndWaitImpot('','TA');
        TestCommon.createTypeOfRoom();
        coo.shopCode__c = '';
        update coo;
        createPlanHadHoomZero('222');
        createCommonAcc();
        createAttachmentCaseUpd2(coo.id);
       // CooperationResult__c coo1 = TestCommon.createLeadImportAndWaitImpot('','TA');
       // coo1.shopCode__c = '';
        //update coo1;
        //createAttachmentCaseUpd2(coo1.id);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true));
    	TA_LeadSyncProcessBatch batch = new TA_LeadSyncProcessBatch();    
		ID batchprocessid = Database.executeBatch(batch,1);
        Test.stopTest(); 
    }
    static testMethod void bathTaxTest3Mode3() {
    	List<AccountMaster__c> productMst = TestCommon.createProductMst(1);
    	CommDefine__c comm = TestCommon.createCommDefine();
    	// 入汤税设定Mode
    	// comm.PlanBathTaxAutoSetMode__c = CommConst.PLAN_BATHTAXAUTOSET_3;
        comm.AccountBathTaxCode__c = productMst[0].Field3__c;
        comm.ReducedTaxRateFlg__c = true;
        comm.ReducedTaxPlanDetailCalFlg__c = true;
        comm.OptionPlanSetMode__c = CommConst.OPTION_MODE_ON;
        comm.LeadSplitDivCode__c = CommConst.APPOTION_LEADSPLIT_DIV_CODE_SPLIT;
        update comm; 
    	// TO DO: implement unit test
        createAllConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'Ta2wayServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        DateTime startDate = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
        
        LeadIndex__c item = new LeadIndex__c(
    		ID__c = String.valueOf('101731864'),
    		Nights__c = 1,
     		EntryTime__c = '10:00',
    		EntryDate__c = startDate.date(),
    		DepartureTime__c = '15:30',
    		DepartureDate__c = startDate.addDays(1).date(),
            EventSource__c = 'FromTravelAgency',
            StockLogicProcessFlg__c = true,
            LeadName__c = '123',
			APPNAME__c = CommConst.BI_PROCESS_TYPE.TA.name(),
			Rooms__c = 1
    	);
        insert item;
        Leadindex__c subItem = new LeadIndex__c(ParentLeadIndxRef__c = item.id);
        insert subItem;

        TypeOfRooms__c typeItem = new TypeOfRooms__c(
            Name = '純和風客室(バスルーム無し)',
            RoomTypeCode__c = '1',
            MaxRooms__c = 99); 
        insert typeItem;

        Room__c roomItem = new Room__c(
    		Name = '部屋テスト' + CommUtils.getRandom(6),
    		CapacityHaku__c = 4,
    		Capacity__c = 2,
    		Area__c = '本館',
    		Floor__c = '1F',
    		UseOfRoom__c = '客室',
    		heyadashiryouryou__c = 40000,
    		TypeRoomRef__c = typeItem.Id,
    		heyadashiryou__c = 25000);
        insert roomItem;
        
        Account acc = new Account(AccountType__c = CommConst.ACCOUNT_TYPE_TRAVEL,SalesOfficeCompanyCodeTL__c = '88',SalesOfficeCompanyCodeTA__c = '88',name='test1',SalesOfficeCompanyType__c = '1');
        insert acc;

        Lead__c lead = new lead__c(leadindexref__c = item.id, name='123',rroom__c = roomItem.id,ReservedDate__c = system.today(),EntryTime__c = system.today(),BookingDataID__c = '101731864',LeadIndexSubId__c = subItem.id,StayPersons__c = 3,SalesOfficeInfoRef__c = acc.id);
		insert lead;
        
        RoomsStatus__c rs = new RoomsStatus__c(RoomRef__c = roomItem.id,
        									Status__c = '故障',
        									StatusBeginDate__c = CommUtils.stringToDate('2013-07-22'),
        									StatusEndDate__c =  CommUtils.stringToDate('2013-07-23'));
        insert rs;
        //連絡結果　予約取り込待ち
        CooperationResult__c coo = TestCommon.createLeadImportAndWaitImpot('','TA');
        TestCommon.createTypeOfRoom();

        insert new StockChangeHisotry__c(
            StockChangeCnt__c = -1,
            CreateSource__c = CommConst.BI_PROCESS_TYPE.TL.name(),
            AgtRef__c = lead.SalesOfficeInfoRef__c,
            StockChangeDate__c = lead.EntryTime__c.date(),	// 到着日ー＞調整日付
            TypeOfRoomRef__c = typeItem.id,
            LeadRef__c = lead.id
        );
       
        Plan__c plan = createPlanHadHoomZero('zhtest001');
        plan.client__c = acc.id;
        plan.PackageCode__c = '186';
        update plan;
        Plan__c childPlan = createPlanHadHoomZero(null);
        childPlan.PlanNo__c = '00000003';
        update childPlan;
        createCommonAcc();
        createDocementActionUpdate(coo.id);
        coo.shopCode__c = '';
        update coo;
        
        Test.startTest();
    	Test.setMock(WebServiceMock.class, new TestCommonMockImpl(true));
    	TA_LeadSyncProcessBatch batch = new TA_LeadSyncProcessBatch();    
		ID batchprocessid = Database.executeBatch(batch,2);
        Test.stopTest();
    }
    private static void createConfigDoc() {
    	TestCommon.createTa2WayConfigDoc();
    }
    private static void createConfigBill(){
    	Document BillSimpleHelpConfig = new Document();
        BillSimpleHelpConfig.Name = 'BillSimpleHelpConfig';
        BillSimpleHelpConfig.DeveloperName = BillSimpleHelpConfig.Name;
        BillSimpleHelpConfig.FolderId = UserInfo.getUserId();
        BillSimpleHelpConfig.Body = Blob.valueOf(getCsvSetupConfig());
        insert BillSimpleHelpConfig;

        List<String> products = new List<String>{'M99000','M99001','M99002','M99003','M99004','M99005'};
        List<AccountMaster__c> accMst = TestCommon.createPayProductMst(products);
    }
    private static String getCsvSetupConfig() {
        String csv = '<root><SHOP><SHOPCODE></SHOPCODE><PAYMENT><CONVERT><PAYTYPE>現金</PAYTYPE><MEIDALAB>預り／現計</MEIDALAB></CONVERT><CONVERT><PAYTYPE>カード</PAYTYPE><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB></CONVERT><CONVERT><PAYTYPE>売掛金</PAYTYPE><MEIDALAB>掛計</MEIDALAB></CONVERT><CONVERT><PAYTYPE>クーポン</PAYTYPE><MEIDALAB>クーポン</MEIDALAB></CONVERT><CONVERT><PAYTYPE>値引</PAYTYPE><MEIDALAB>値引・割引券</MEIDALAB></CONVERT><CONVERT><PAYTYPE>予約金</PAYTYPE><MEIDALAB>予約金</MEIDALAB></CONVERT></PAYMENT><PAYMEIDA><CONVERT><MEIDALAB>預り／現計</MEIDALAB><PRODCODE>87001</PRODCODE></CONVERT><CONVERT><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB><PRODCODE>85201</PRODCODE></CONVERT><CONVERT><MEIDALAB>掛計</MEIDALAB><PRODCODE>85101</PRODCODE></CONVERT><CONVERT><MEIDALAB>クーポン</MEIDALAB><PRODCODE>85610</PRODCODE></CONVERT><CONVERT><MEIDALAB>値引・割引券</MEIDALAB><PRODCODE>87005</PRODCODE></CONVERT><CONVERT><MEIDALAB>予約金</MEIDALAB><PRODCODE>87001</PRODCODE></CONVERT></PAYMEIDA></SHOP>'
                    + '</root>';
        return csv;
    }
    private static void createDocementActionUpdate(String parentId){
    	String infoTravelXML = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><AllotmentBookingReport>    <TransactionType>        <DataFrom>FromTravelAgency</DataFrom>        <DataClassification>ModificationReport</DataClassification>        <DataID>101731864-2</DataID><BookingDataID>101731864-1</BookingDataID>        <SystemDate>2013-07-09</SystemDate>    </TransactionType>    <AccommodationInformation>        <AccommodationName>元湯陣屋</AccommodationName>        <AccommodationCode>14000010</AccommodationCode>    </AccommodationInformation>    <SalesOfficeInformation><SalesOfficeCompanyCode>88</SalesOfficeCompanyCode><SalesOfficeCompanyName>予約プロ</SalesOfficeCompanyName>        <SalesOfficeName>予約プロ</SalesOfficeName>        <SalesOfficeCode>88</SalesOfficeCode>        <SalesOfficePhoneNumber>052-262-8041</SalesOfficePhoneNumber>    </SalesOfficeInformation>    <BasicInformation>        <TravelAgencyBookingNumber>A001781590</TravelAgencyBookingNumber>        <TravelAgencyBookingDate>2013-07-09</TravelAgencyBookingDate>        <TravelAgencyBookingTime>23:47:14</TravelAgencyBookingTime>        <TravelAgencyReportNumber>00000051</TravelAgencyReportNumber>        <GuestOrGroupNameSingleByte>ﾃｽﾄﾖﾔｸ _</GuestOrGroupNameSingleByte>        <GuestOrGroupNameKanjiName>テスト予約No. 2013/07/09 _</GuestOrGroupNameKanjiName>        <CheckInDate>2013-07-22</CheckInDate>        <CheckInTime>15:30:00</CheckInTime>        <CheckOutDate>2013-07-23</CheckOutDate>        <Nights>1</Nights>        <TotalRoomCount>2</TotalRoomCount>        <GrandTotalPaxCount>14</GrandTotalPaxCount>        <TotalPaxMaleCount>2</TotalPaxMaleCount>        <TotalPaxFemaleCount>2</TotalPaxFemaleCount>        <TotalChildA70Count>2</TotalChildA70Count>        <TotalChildB50Count>4</TotalChildB50Count>        <TotalChildC30Count>2</TotalChildC30Count>        <TotalChildDNoneCount>2</TotalChildDNoneCount>        <PackagePlanName>【１泊朝食付】朝膳朝食付きプラン　チェックイン24:00までOK！</PackagePlanName>        <PackagePlanCode>186</PackagePlanCode>        <MealCondition>1nightBreakfast</MealCondition>        <SpecificMealCondition>None Specified</SpecificMealCondition>        <OtherServiceInformation>○携帯電話番号[Mobile Phone Number]：00-2345-6789○ご要望・ご質問：N rooms N nightsのテストのため</OtherServiceInformation>    </BasicInformation>    <BasicRateInformation>        <RoomRateOrPersonalRate>PersonalRate</RoomRateOrPersonalRate>        <TaxServiceFee>WithoutSerivceAndTax</TaxServiceFee>        <TotalAccommodationCharge>429135</TotalAccommodationCharge>    </BasicRateInformation>    <RoomAndGuestInformation>        <RoomAndGuestList>            <RoomInformation>                <RoomTypeCode>1</RoomTypeCode>                <RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName>                <PerRoomPaxCount>7</PerRoomPaxCount>                <RoomPaxMaleCount>1</RoomPaxMaleCount>                <RoomPaxFemaleCount>1</RoomPaxFemaleCount>                <RoomChildA70Count>1</RoomChildA70Count>                <RoomChildB50Count>2</RoomChildB50Count>                <RoomChildC30Count>1</RoomChildC30Count>                <RoomChildDNoneCount>1</RoomChildDNoneCount>            </RoomInformation>            <RoomRateInformation>                <RoomDate>2013-07-22</RoomDate>                <PerPaxRate>12000</PerPaxRate>                <PerChildA70Rate>12000</PerChildA70Rate>                <PerChildB50Rate>12000</PerChildB50Rate>                <PerChildC30Rate>3000</PerChildC30Rate>                <PerChildDRate>10000</PerChildDRate>                <TotalRoomHotSpringTax>0</TotalRoomHotSpringTax>                <TotalPerRoomServiceFee>0</TotalPerRoomServiceFee>            </RoomRateInformation>            <RoomRateInformation>                <RoomDate>2013-07-22</RoomDate>                <PerChildB50Rate>0</PerChildB50Rate>            </RoomRateInformation>        </RoomAndGuestList>        <RoomAndGuestList>            <RoomInformation>                <RoomTypeCode>1</RoomTypeCode>                <RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName>                <PerRoomPaxCount>2</PerRoomPaxCount>                <RoomPaxMaleCount>1</RoomPaxMaleCount>                <RoomPaxFemaleCount>1</RoomPaxFemaleCount>            </RoomInformation>            <RoomRateInformation>                <RoomDate>2013-07-22</RoomDate>                <PerPaxRate>12000</PerPaxRate>                <PerChildA70Rate>12000</PerChildA70Rate>                <PerChildB50Rate>12000</PerChildB50Rate>                <PerChildC30Rate>3000</PerChildC30Rate>                <PerChildDRate>10000</PerChildDRate>                <TotalRoomHotSpringTax>0</TotalRoomHotSpringTax>                <TotalPerRoomServiceFee>0</TotalPerRoomServiceFee>            </RoomRateInformation>            <RoomRateInformation>                <RoomDate>2013-07-22</RoomDate>                <PerChildB50Rate>0</PerChildB50Rate>            </RoomRateInformation>        </RoomAndGuestList>    </RoomAndGuestInformation>    <RisaplsInformation>        <RisaplsCommonInformation>            <Basic>                <SalesOfficeCompanyCode>88</SalesOfficeCompanyCode>                <TelegramDiv></TelegramDiv>                <RisaplsDataID></RisaplsDataID>                <RisaplsTelegramNumber></RisaplsTelegramNumber> ';
    	infoTravelXML +=  '<TelegramData>予約通知 予約プロ                                      SNT-NET 07-09 23:49 (88) 予約番号： A001781590  NO.00000051 元湯陣屋様(14000010)宿泊者情報：  テスト予約No. 2013/07/09 _  TEL:01-2345-6789  ﾃｽﾄﾖﾔｸ _  Mail:hiroyuki_morimoto@jinya-inn.com  住所:(〒257-0001)神奈川県秦野市鶴巻北プラン名：【１泊朝食付】朝膳朝食付きプラン　チェックイン24:00までOK！(185)2013年07月22日から    3泊  朝食付  サ込税込入込方法：                   チェックイン時間：15:30人員総数：  14人  内訳：(男)2名+(女)2名+(Ａ)2名+(Ｂ)4名+(Ｃ)2名+(Ｄ)2名客室総数：   2室07月22日  24  (純和風客室(バスルーム無し))          大人（男）     1名    @12,000          大人（女）     1名    @12,000          子供Ａ         1名    @12,000  小学生          子供Ｂ         1名    @12,000  小児（食事布団あり）          子供Ｂ         1名         @0  小児（食事布団なし）          子供Ｃ         1名     @3,000  小児（食事のみ）          子供Ｄ         1名    @10,000  小児（布団のみ）          24  (純和風客室(バスルーム無し))          大人（男）     1名    @12,000          大人（女）     1名    @12,000          子供Ａ         1名    @12,000  小学生          子供Ｂ         1名    @12,000  小児（食事布団あり）          子供Ｂ         1名         @0  小児（食事布団なし）          子供Ｃ         1名     @3,000  小児（食事のみ）          子供Ｄ         1名    @10,000  小児（布団のみ）07月23日  24  (純和風客室(バスルーム無し))          大人（男）     1名    @12,000          大人（女）     1名    @12,000          子供Ａ         1名    @12,000  小学生          子供Ｂ         1名    @12,000  小児（食事布団あり）          子供Ｂ         1名         @0  小児（食事布団なし）          子供Ｃ         1名     @3,000  小児（食事のみ）          子供Ｄ         1名    @10,000  小児（布団のみ）          24  (純和風客室(バスルーム無し))          大人（男）     1名    @12,000          大人（女）     1名    @12,000          子供Ａ         1名    @12,000  小学生          子供Ｂ         1名    @12,000  小児（食事布団あり）          子供Ｂ         1名         @0  小児（食事布団なし）          子供Ｃ         1名     @3,000  小児（食事のみ）          子供Ｄ         1名    @10,000  小児（布団のみ）07月24日  24  (純和風客室(バスルーム無し))          大人（男）     1名    @12,000          大人（女）     1名    @12,000          子供Ａ         1名    @12,000  小学生          子供Ｂ         1名    @12,000  小児（食事布団あり）          子供Ｂ         1名         @0  小児（食事布団なし）          子供Ｃ         1名     @3,000  小児（食事のみ）          子供Ｄ         1名    @10,000  小児（布団のみ）          24  (純和風客室(バスルーム無し))          大人（男）     1名    @12,000          大人（女）     1名    @12,000          子供Ａ         1名    @12,000  小学生          子供Ｂ         1名    @12,000  小児（食事布団あり）          子供Ｂ         1名         @0  小児（食事布団なし）          子供Ｃ         1名     @3,000  小児（食事のみ）          子供Ｄ         1名    @10,000  小児（布団のみ）                                   宿泊料金計                ：   \\366,000オプション：07月22日  特選会席料理                     4 個      @12,000             お土産（陣屋どらやき　6個入）    1 個         @960             お土産（やまと豚の桜味噌漬け 1   3 個       @1,575             お土産（やまと豚の桜味噌漬け 2   3 個       @3,150                                      オプション料金計          ：    \\63,135                       合計料金                              ：   \\429,135                     【宿泊者への請求額】                    ：   \\429,135           ---------------------------------------------------------------------ご確認事項：○携帯電話番号[Mobile Phone Number]：00-2345-6789○ご要望・ご質問：N rooms N nightsのテストのため取扱個所：予約プロ(88)  TEL 052-262-8041  FAX 052-262-8042---</TelegramData>                <PhoneNumber>01-2345-6789</PhoneNumber>                <Email>hiroyuki_morimoto@jinya-inn.com</Email>                <PostalCode>257-0001</PostalCode>                <Address>神奈川県秦野市鶴巻北</Address>                <TotalPaxManCount>4</TotalPaxManCount>                <BranchFaxNumber>052-262-8042</BranchFaxNumber>                <Version>2.0</Version>                <AccommodationId>X36969</AccommodationId>            </Basic>            <Allotment>                <AssignDiv>1</AssignDiv>                <GenderDiv>1</GenderDiv>                <HandleDiv>1</HandleDiv>                <RsvUserDiv>0</RsvUserDiv>                <UseDiv>0</UseDiv>            </Allotment>            <RoomAndRoomRateInformation>                <RoomInformation>                    <RoomTypeCode>1</RoomTypeCode>                    <RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName>                    <PerRoomPaxCount>7</PerRoomPaxCount>                    <RoomPaxMaleCount>1</RoomPaxMaleCount>                    <RoomPaxFemaleCount>1</RoomPaxFemaleCount>                    <RoomChildA70Count>1</RoomChildA70Count>                    <RoomChildB50Count>2</RoomChildB50Count>                    <RoomChildC30Count>1</RoomChildC30Count>                    <RoomChildDNoneCount>1</RoomChildDNoneCount>                    <RoomChildA70Request>小学生</RoomChildA70Request>                    <RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request>                    <RoomChildC30Request>小児（食事のみ）</RoomChildC30Request>                    <RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest>                    <RoomTypeAgent>88</RoomTypeAgent>                    <RoomFrame>--</RoomFrame>                    <NetRmTypeGroupCode>49</NetRmTypeGroupCode>                    <PlanGroupCode>---</PlanGroupCode>                </RoomInformation>                <RoomRateInformation>                    <RoomDate>2013-07-22</RoomDate>                    <PerPaxRate>12000</PerPaxRate>                    <PerChildA70Rate>12000</PerChildA70Rate>                    <PerChildB50Rate>12000</PerChildB50Rate>                    <PerChildC30Rate>3000</PerChildC30Rate>                    <PerChildDRate>10000</PerChildDRate>                    <TotalRoomHotSpringTax>0</TotalRoomHotSpringTax>                    <TotalPerRoomServiceFee>0</TotalPerRoomServiceFee>                    <PerMaleRate>12000</PerMaleRate>                    <PerFemaleRate>12000</PerFemaleRate>                    <RoomRatePaxMaleCount>1</RoomRatePaxMaleCount>                    <RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount>                    <RoomRateChildA70Count>1</RoomRateChildA70Count>                    <RoomRateChildB50Count>1</RoomRateChildB50Count>                    <RoomRateChildC30Count>1</RoomRateChildC30Count>                    <RoomRateChildDNoneCount>1</RoomRateChildDNoneCount>                    <RoomRateChildA70Request>小学生</RoomRateChildA70Request>                    <RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request>                    <RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request>                    <RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest>                </RoomRateInformation>                <RoomRateInformation>                    <RoomDate>2013-07-22</RoomDate>                    <PerChildB50Rate>0</PerChildB50Rate>                    <RoomRateChildB50Count>1</RoomRateChildB50Count>                    <RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request>                </RoomRateInformation>            </RoomAndRoomRateInformation>            <RoomAndRoomRateInformation>                <RoomInformation>                    <RoomTypeCode>1</RoomTypeCode>                    <RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName>                    <PerRoomPaxCount>7</PerRoomPaxCount>                    <RoomPaxMaleCount>1</RoomPaxMaleCount>                    <RoomPaxFemaleCount>1</RoomPaxFemaleCount>                    <RoomChildA70Count>1</RoomChildA70Count>                    <RoomChildB50Count>2</RoomChildB50Count>                    <RoomChildC30Count>1</RoomChildC30Count>                    <RoomChildDNoneCount>1</RoomChildDNoneCount>                    <RoomChildA70Request>小学生</RoomChildA70Request>                    <RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request>                    <RoomChildC30Request>小児（食事のみ）</RoomChildC30Request>                    <RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest>                    <RoomTypeAgent>88</RoomTypeAgent>                    <RoomFrame>--</RoomFrame>                    <NetRmTypeGroupCode>49</NetRmTypeGroupCode>                    <PlanGroupCode>---</PlanGroupCode>                </RoomInformation>                <RoomRateInformation>                    <RoomDate>2013-07-22</RoomDate>                    <PerPaxRate>12000</PerPaxRate>                    <PerChildA70Rate>12000</PerChildA70Rate>                    <PerChildB50Rate>12000</PerChildB50Rate>                    <PerChildC30Rate>3000</PerChildC30Rate>                    <PerChildDRate>10000</PerChildDRate>                    <TotalRoomHotSpringTax>0</TotalRoomHotSpringTax>                    <TotalPerRoomServiceFee>0</TotalPerRoomServiceFee>                    <PerMaleRate>12000</PerMaleRate>                    <PerFemaleRate>12000</PerFemaleRate>                    <RoomRatePaxMaleCount>1</RoomRatePaxMaleCount>                    <RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount>                    <RoomRateChildA70Count>1</RoomRateChildA70Count>                    <RoomRateChildB50Count>1</RoomRateChildB50Count>                    <RoomRateChildC30Count>1</RoomRateChildC30Count>                    <RoomRateChildDNoneCount>1</RoomRateChildDNoneCount>                    <RoomRateChildA70Request>小学生</RoomRateChildA70Request>                    <RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request>                    <RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request>                    <RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest>                </RoomRateInformation>                <RoomRateInformation>                    <RoomDate>2013-07-22</RoomDate>                    <PerChildB50Rate>0</PerChildB50Rate>                    <RoomRateChildB50Count>1</RoomRateChildB50Count>                    <RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request>                </RoomRateInformation>            </RoomAndRoomRateInformation>            <OtherInfo>                <GuestRequest>○携帯電話番号[Mobile Phone Number]：00-2345-6789○ご要望・ご質問：N rooms N nightsのテストのため</GuestRequest>            </OtherInfo>        </RisaplsCommonInformation>        <AgentNativeInformation>            <Extend>                <AmountClaimed>429135</AmountClaimed>            </Extend>        </AgentNativeInformation>    </RisaplsInformation></AllotmentBookingReport>';
    	String dateKey = System.now().format('yyMMddHHMMssSSS');
    	Attachment newAttach = new Attachment(
									ParentId = parentId,
									Name = 'TAPDATA_' + dateKey + '1_Test.xml', 
									ContentType = 'text/xml',
									Body = Blob.valueOf(infoTravelXML)
								);
		insert newAttach;
    }
    private static void createDocementActionCancel(String parentId){
    	String infoTravelXML = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><AllotmentBookingReport>    <TransactionType>        <DataFrom>FromTravelAgency</DataFrom>        <DataClassification>CancellationReport</DataClassification>        <DataID>107338085-1</DataID><BookingDataID>107338085-1</BookingDataID><SystemDate>2013-08-23</SystemDate>    </TransactionType>    <AccommodationInformation>        <AccommodationName>松本丸の内ﾎﾃﾙ</AccommodationName>        <AccommodationCode>5192-096</AccommodationCode>    </AccommodationInformation>    <SalesOfficeInformation><SalesOfficeCompanyCode>88</SalesOfficeCompanyCode><SalesOfficeCompanyName>JTB</SalesOfficeCompanyName>        <SalesOfficeName>新宿本社営業１</SalesOfficeName>        <SalesOfficeCode>0001573</SalesOfficeCode>        <SalesOfficePersonInCharge>ｵｵｸﾎﾞ</SalesOfficePersonInCharge>        <SalesOfficePhoneNumber>03-5909-4016</SalesOfficePhoneNumber>    </SalesOfficeInformation>    <BasicInformation>        <TravelAgencyBookingNumber>3JN0BH-01</TravelAgencyBookingNumber>        <TravelAgencyBookingDate>2013-08-22</TravelAgencyBookingDate>        <TravelAgencyBookingTime>00:00:00</TravelAgencyBookingTime>        <TravelAgencyReportNumber>02125</TravelAgencyReportNumber>        <GuestOrGroupNameSingleByte>ﾀﾞｲｲﾁ ｻﾝｷﾖｳ</GuestOrGroupNameSingleByte>        <GuestOrGroupNameKanjiName>第一三共株式会社</GuestOrGroupNameKanjiName>        <CheckInDate>2013-11-08</CheckInDate>        <CheckOutDate>2013-11-09</CheckOutDate>        <Nights>1</Nights>        <TotalRoomCount>1</TotalRoomCount>        <GrandTotalPaxCount>1</GrandTotalPaxCount>        <TotalPaxMaleCount>1</TotalPaxMaleCount>        <MealCondition>Other</MealCondition>        <SpecificMealCondition>None Specified</SpecificMealCondition>    </BasicInformation>    <BasicRateInformation>        <RoomRateOrPersonalRate>PersonalRate</RoomRateOrPersonalRate>        <TaxServiceFee>IncludingServiceAndTax</TaxServiceFee>        <TotalAccommodationCharge>9000</TotalAccommodationCharge>    </BasicRateInformation>    <RoomAndGuestInformation>        <RoomAndGuestList>            <RoomInformation>                <RoomTypeCode>65</RoomTypeCode>                <RoomTypeName>05</RoomTypeName>                <PerRoomPaxCount>1</PerRoomPaxCount>                <RoomPaxMaleCount>1</RoomPaxMaleCount>            </RoomInformation>            <RoomRateInformation>                <RoomDate>2013-11-08</RoomDate>            </RoomRateInformation>        </RoomAndGuestList>    </RoomAndGuestInformation>    <RisaplsInformation>        <RisaplsCommonInformation>            <Basic>                <SalesOfficeCompanyCode>01</SalesOfficeCompanyCode>                <TelegramDiv></TelegramDiv>                <RisaplsDataID></RisaplsDataID>                <RisaplsTelegramNumber></RisaplsTelegramNumber>                <TelegramData>JTB*************(HI) ｵｷﾔｸｻﾏﾂｳﾁNo:02125** 2013/08/23 01:50 **(ｷﾞﾖｳﾑﾂｳﾁNo:02440)**JTB通知 NH-10   松本丸の内ﾎﾃﾙ                             5192-096                新宿本社営業１                            0001573                TEL:03-5909-4016                          担当：ｵｵｸﾎﾞ     取消通知  (手配)                                                      ３ＪＮ０ＢＨ‐０１ﾀﾞｲｲﾁ ｻﾝｷﾖｳ           第一三共株式会社    2013/11/08  宿泊合計金額（販売料金）     \\9000(消費税サービス料込み)                男　  1名             05-    1               計   1室メッセージ                                                                   操作日時：2013/08/22 10:40***</TelegramData>                <TotalPaxManCount>1</TotalPaxManCount>                <Version>2.0</Version>                <AccommodationId>G66249</AccommodationId>            </Basic>            <Allotment>                <AssignDiv>0</AssignDiv>                <GenderDiv>0</GenderDiv>                <HandleDiv>1</HandleDiv>                <RsvUserDiv>0</RsvUserDiv>                <UseDiv>0</UseDiv>            </Allotment>            <RoomAndRoomRateInformation>                <RoomInformation>                    <RoomTypeCode>65</RoomTypeCode>                    <RoomTypeName>05</RoomTypeName>                    <PerRoomPaxCount>1</PerRoomPaxCount>                    <RoomPaxMaleCount>1</RoomPaxMaleCount>                    <RoomTypeAgent>01</RoomTypeAgent>                    <RoomFrame>--</RoomFrame>                </RoomInformation>                <RoomRateInformation>                    <RoomDate>2013-11-08</RoomDate>                </RoomRateInformation>            </RoomAndRoomRateInformation>        </RisaplsCommonInformation>    </RisaplsInformation></AllotmentBookingReport> ';
    	String dateKey = System.now().format('yyMMddHHMMssSSS');
    	Attachment newAttach = new Attachment(
									ParentId = parentId,
									Name = 'TAPDATA_' + dateKey + '1_Test.xml', 
									ContentType = 'text/xml',
									Body = Blob.valueOf(infoTravelXML)
								);
		insert newAttach;
    }
    private static void createDocumentHadMember(String parentId){
    	String infoTravelXML = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><AllotmentBookingReport>    <TransactionType>        <DataFrom>FromTravelAgency</DataFrom>        <DataClassification>NewBookReport</DataClassification>        <DataID>106535992-1</DataID><BookingDataID>106535992-1</BookingDataID><SystemDate>2013-08-23</SystemDate>    </TransactionType>    <AccommodationInformation>        <AccommodationName>松本丸の内ホテル (旧アルモニービアン）</AccommodationName>        <AccommodationCode>Y81153</AccommodationCode>    </AccommodationInformation>    <SalesOfficeInformation><SalesOfficeCompanyCode>88</SalesOfficeCompanyCode><SalesOfficeCompanyName>じゃらんnet</SalesOfficeCompanyName>        <SalesOfficeName>じゃらんnet宿予約サービス</SalesOfficeName>        <SalesOfficeCode>66</SalesOfficeCode>        <SalesOfficeEmail>support@jalan.net</SalesOfficeEmail>        <SalesOfficePhoneNumber>0570-005972</SalesOfficePhoneNumber>    </SalesOfficeInformation>    <BasicInformation>        <TravelAgencyBookingNumber>0HVAXER7</TravelAgencyBookingNumber>        <TravelAgencyBookingDate>2013-08-16</TravelAgencyBookingDate>        <TravelAgencyBookingTime>15:27:26</TravelAgencyBookingTime>        <TravelAgencyReportNumber>00000013</TravelAgencyReportNumber>        <GuestOrGroupNameSingleByte>ｹﾞﾝ ｼﾘｭｳ _!</GuestOrGroupNameSingleByte>        <GuestOrGroupNameKanjiName>玄 志龍 _!</GuestOrGroupNameKanjiName>        <CheckInDate>2013-08-24</CheckInDate>        <CheckInTime>20:00:00</CheckInTime>        <CheckOutDate>2013-08-25</CheckOutDate>        <CheckOutTime>11:00:00</CheckOutTime>        <Nights>1</Nights>        <TotalRoomCount>1</TotalRoomCount>        <GrandTotalPaxCount>1</GrandTotalPaxCount>        <TotalPaxMaleCount>1</TotalPaxMaleCount>        <PackagePlanName>◇基本プラン◇【朝食付】</PackagePlanName>        <PackagePlanCode>00646064</PackagePlanCode>        <MealCondition>1nightBreakfast</MealCondition>        <SpecificMealCondition>None Specified</SpecificMealCondition>        <OtherServiceInformation>ポイント利用(現:200pt)朝食付質問1：・駐車場ご利用のお客様はこちらに必要台数をご記入ください・専用駐車場が満車の場合、近隣の提携駐車場へのご案内となる場合があります・チェックイン時間がご予定より大幅に遅れられる場合は、ご連絡ください・当日お客様と連絡が取れる電話番号（携帯番号など）をお教えください(回答1：駐車場ご利用：1台Tel：09035983092)</OtherServiceInformation>    </BasicInformation>    <BasicRateInformation>        <RoomRateOrPersonalRate>PersonalRate</RoomRateOrPersonalRate>        <TaxServiceFee>IncludingServiceAndTax</TaxServiceFee>        <TotalAccommodationCharge>9800</TotalAccommodationCharge>    </BasicRateInformation>    <RoomAndGuestInformation>        <RoomAndGuestList>            <RoomInformation>                <RoomTypeCode>30</RoomTypeCode>                <RoomTypeName>スタンダードダブル18㎡（禁煙）</RoomTypeName>                <PerRoomPaxCount>1</PerRoomPaxCount>                <RoomPaxMaleCount>1</RoomPaxMaleCount>            </RoomInformation>            <RoomRateInformation>                <RoomDate>2013-08-24</RoomDate>                <PerPaxRate>9800</PerPaxRate>            </RoomRateInformation>        </RoomAndGuestList>    </RoomAndGuestInformation>    <RisaplsInformation>        <RisaplsCommonInformation>            <Basic>                <SalesOfficeCompanyCode>66</SalesOfficeCompanyCode>                <TelegramDiv></TelegramDiv>                <RisaplsDataID></RisaplsDataID>                <RisaplsTelegramNumber></RisaplsTelegramNumber>                <TelegramData>予約通知 じゃらんnet                                   SNT-NET 08-16 15:27 (66) 予約番号： 0HVAXER7  NO.00000013 松本丸の内ホテル (旧アルモニービアン）様(Y81153)宿泊者情報：  玄 志龍 _!  TEL:09035983092  ｹﾞﾝ ｼﾘｭｳ _!  住所:(〒3330811)埼玉県川口市戸塚６－７－６　エスペランサ１０３  性別:        年代:35-39才予約者情報：  玄 志龍  ｹﾞﾝ ｼﾘｭｳ  Mail:ziontrek@gmail.comプラン名：◇基本プラン◇【朝食付】(00646064)2013年08月24日から    1泊  朝食付  サ込税込入込方法：                   チェックイン時間：20:00  チェックアウト時間：11:00人員総数：   1人  内訳：(男)1名客室総数：   1室08月24日  0133893  (スタンダードダブル18㎡（禁煙）)          大人（男）     1名     @9,800                                   宿泊料金計                ：     \\9,800                       合計料金                              ：     \\9,800                       割引額(現ポイント)                    ：      \\200                     【宿泊者への請求額】                    ：     \\9,600           ---------------------------------------------------------------------ご確認事項：ポイント利用(現:200pt)朝食付質問1：・駐車場ご利用のお客様はこちらに必要台数をご記入ください・専用駐車場が満車の場合、近隣の提携駐車場へのご案内となる場合があります・チェックイン時間がご予定より大幅に遅れられる場合は、ご連絡ください・当日お客様と連絡が取れる電話番号（携帯番号など）をお教えください(回答1：駐車場ご利用：1台Tel：09035983092)取扱個所：じゃらんnet宿予約サービス(66)  TEL 0570-005972Mail support@jalan.net※「ＰＣサイト」より予約がはいりました。ご確認をお願いいたします。キャンセル□／NO SHOW□／変更□キャンセル・NO SHOW・変更が発生した場合、お手数ですが上記にチェックの上、このままFAXにてご返信ください。変更の場合は上記項目のうち変更になったもの（部屋数・人数等）を訂正の上お送り下さい。TEL 0570-005972(03-3980-2018)/FAX  0570-005973(03-3980-2032)---</TelegramData>                <PhoneNumber>09035983092</PhoneNumber>                <PostalCode>3330811</PostalCode>                <Address>埼玉県川口市戸塚６－７－６　エスペランサ１０３</Address>                <TotalPaxManCount>1</TotalPaxManCount>                <Version>2.0</Version>                <RepresentativeGeneration>35-39才</RepresentativeGeneration>                <AccommodationId>G66249</AccommodationId>            </Basic>            <Allotment>                <AssignDiv>1</AssignDiv>                <GenderDiv>0</GenderDiv>                <HandleDiv>1</HandleDiv>                <RsvUserDiv>1</RsvUserDiv>                <UseDiv>0</UseDiv>            </Allotment>            <RoomAndRoomRateInformation>                <RoomInformation>                    <RoomTypeCode>30</RoomTypeCode>                    <RoomTypeName>スタンダードダブル18㎡（禁煙）</RoomTypeName>                    <PerRoomPaxCount>1</PerRoomPaxCount>                    <RoomPaxMaleCount>1</RoomPaxMaleCount>                    <RoomTypeAgent>66</RoomTypeAgent>                    <RoomFrame>--</RoomFrame>                    <NetRmTypeGroupCode>6</NetRmTypeGroupCode>                    <PlanGroupCode>31</PlanGroupCode>                </RoomInformation>                <RoomRateInformation>                    <RoomDate>2013-08-24</RoomDate>                    <PerPaxRate>9800</PerPaxRate>                    <PerMaleRate>9800</PerMaleRate>                    <RoomRatePaxMaleCount>1</RoomRatePaxMaleCount>                </RoomRateInformation>            </RoomAndRoomRateInformation>            <Member>                <UserName>玄 志龍</UserName>                <UserKana>ｹﾞﾝ ｼﾘｭｳ</UserKana>                <UserMailAddr>ziontrek@gmail.com</UserMailAddr>            </Member>            <OtherInfo>                <GuestRequest>ポイント利用(現:200pt)朝食付</GuestRequest>                <QuestionAndAnswerList>                    <QuestionToGuest>・駐車場ご利用のお客様はこちらに必要台数をご記入ください・専用駐車場が満車の場合、近隣の提携駐車場へのご案内となる場合があります・チェックイン時間がご予定より大幅に遅れられる場合は、ご連絡ください・当日お客様と連絡が取れる電話番号（携帯番号など）をお教えください</QuestionToGuest>                    <AnswerToHotel>駐車場ご利用：1台Tel：09035983092</AnswerToHotel>                </QuestionAndAnswerList>            </OtherInfo>            <BasicRate>                <TotalAccomodationServiceCharge>0</TotalAccomodationServiceCharge>                <PointsDiscountList>                    <PointsDiv>2</PointsDiv>                    <PointsDiscountName>現ポイント</PointsDiscountName>                    <PointsDiscount>200</PointsDiscount>                </PointsDiscountList>            </BasicRate>        </RisaplsCommonInformation>        <AgentNativeInformation>            <Extend>                <PointDiv>エージェント原資</PointDiv>                <PointName>現ポイント</PointName>                <Points>200</Points>                <TotalAccommodationDecleasePoints>9600</TotalAccommodationDecleasePoints>                <TotalAccommodationConsumptionTax>0</TotalAccommodationConsumptionTax>                <AmountClaimed>9600</AmountClaimed>            </Extend>            <Extendmytrip>                <SettlementDiv>0</SettlementDiv>            </Extendmytrip>        </AgentNativeInformation>    </RisaplsInformation></AllotmentBookingReport>';
    	//infoTravelXML +=
    	String dateKey = System.now().format('yyMMddHHMMssSSS');
    	Attachment newAttach = new Attachment(
									ParentId = parentId,
									Name = 'TAPDATA_' + dateKey + '1_Test.xml', 
									ContentType = 'text/xml',
									Body = Blob.valueOf(infoTravelXML)
								);
		insert newAttach;
    }
    private static void createDocumentRoomRate(String parentId){
    	String infoTravelXML = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><AllotmentBookingReport>    <TransactionType>        <DataFrom>FromTravelAgency</DataFrom>        <DataClassification>NewBookReport</DataClassification>        <DataID>106557046-1</DataID><BookingDataID>106557046-1</BookingDataID><SystemDate>2013-08-23</SystemDate>    </TransactionType>    <AccommodationInformation>        <AccommodationName>松本丸の内ホテル</AccommodationName>        <AccommodationCode>00001782</AccommodationCode>    </AccommodationInformation>    <SalesOfficeInformation><SalesOfficeCompanyCode>80</SalesOfficeCompanyCode><SalesOfficeCompanyName>一休.com</SalesOfficeCompanyName>        <SalesOfficeName>株式会社一休</SalesOfficeName>        <SalesOfficeCode>001</SalesOfficeCode>        <SalesOfficePhoneNumber>03-6685-0065</SalesOfficePhoneNumber>    </SalesOfficeInformation>    <BasicInformation>        <TravelAgencyBookingNumber>IK0144977541</TravelAgencyBookingNumber>        <TravelAgencyBookingDate>2013-08-16</TravelAgencyBookingDate>        <TravelAgencyBookingTime>20:55:14</TravelAgencyBookingTime>        <TravelAgencyReportNumber>00000003</TravelAgencyReportNumber>        <GuestOrGroupNameSingleByte>ﾉﾑﾗ ｶｽﾞﾕｷ</GuestOrGroupNameSingleByte>        <GuestOrGroupNameDoubleByte>のむら かずゆき</GuestOrGroupNameDoubleByte>        <GuestOrGroupNameKanjiName>野村 豊幸</GuestOrGroupNameKanjiName>        <CheckInDate>2013-08-18</CheckInDate>        <CheckInTime>15:00:00</CheckInTime>        <CheckOutDate>2013-08-19</CheckOutDate>        <Nights>1</Nights>        <TotalRoomCount>1</TotalRoomCount>        <GrandTotalPaxCount>1</GrandTotalPaxCount>        <TotalPaxMaleCount>1</TotalPaxMaleCount>        <TotalPaxFemaleCount>0</TotalPaxFemaleCount>        <TotalChildA70Count>0</TotalChildA70Count>        <TotalChildB50Count>0</TotalChildB50Count>        <TotalChildC30Count>0</TotalChildC30Count>        <TotalChildDNoneCount>0</TotalChildDNoneCount>        <PackagePlanName>ビジネス応援「ゆったりデラックス」素泊まり</PackagePlanName>        <PackagePlanCode>bien14</PackagePlanCode>        <MealCondition>WithoutMeal</MealCondition>        <SpecificMealCondition>None Specified</SpecificMealCondition>        <OtherServiceInformation>支払い方法：現払い食事なし禁煙ルームをお願いします質問1:駐車場ご利用の場合はAとお車の台数を、ご利用のない場合はBとご記入ください。回答1:B</OtherServiceInformation>    </BasicInformation>    <BasicRateInformation>        <RoomRateOrPersonalRate>RoomRate</RoomRateOrPersonalRate>        <TaxServiceFee>IncludingServiceAndTax</TaxServiceFee>        <Payment>Cash</Payment>        <TotalAccommodationCharge>8000</TotalAccommodationCharge>        <TotalAccommodationHotSpringTax>0</TotalAccommodationHotSpringTax>    </BasicRateInformation>    <RoomAndGuestInformation>        <RoomAndGuestList>            <RoomInformation>                <RoomTypeCode>20</RoomTypeCode>                <RoomTypeName>デラックスシングル（禁煙）(シングル)</RoomTypeName>                <PerRoomPaxCount>1</PerRoomPaxCount>                <RoomPaxMaleCount>1</RoomPaxMaleCount>                <RoomPaxFemaleCount>0</RoomPaxFemaleCount>                <RoomChildA70Count>0</RoomChildA70Count>                <RoomChildB50Count>0</RoomChildB50Count>                <RoomChildC30Count>0</RoomChildC30Count>                <RoomChildDNoneCount>0</RoomChildDNoneCount>            </RoomInformation>            <RoomRateInformation>                <RoomDate>2013-08-18</RoomDate>                <PerPaxRate>8000</PerPaxRate>                <PerChildA70Rate>0</PerChildA70Rate>                <PerChildB50Rate>0</PerChildB50Rate>                <PerChildC30Rate>0</PerChildC30Rate>                <PerChildDRate>0</PerChildDRate>                <TotalPerRoomRate>8000</TotalPerRoomRate>                <TotalRoomHotSpringTax>100</TotalRoomHotSpringTax>                <TotalPerRoomServiceFee>500</TotalPerRoomServiceFee>            </RoomRateInformation>        </RoomAndGuestList>    </RoomAndGuestInformation>    <RisaplsInformation>        <RisaplsCommonInformation>            <Basic>                <SalesOfficeCompanyCode>80</SalesOfficeCompanyCode>                <TelegramDiv></TelegramDiv>                <RisaplsDataID></RisaplsDataID>                <RisaplsTelegramNumber></RisaplsTelegramNumber>                <TelegramData>予約通知 一休.com                                      SNT-NET 08-16 20:56 (80) 予約番号： IK0144977541  NO.00000003 松本丸の内ホテル様(00001782)宿泊者情報：  野村 豊幸  TEL:0423241785  ﾉﾑﾗ ｶｽﾞﾕｷ  住所:(〒185-0023)東京都 国分寺市 西元町　2-11-7  性別:男        年代:40代        年齢:予約者情報：  野村 豊幸  のむら かずゆき  住所:(〒185-0023)東京都 国分寺市 西元町　2-11-7  性別:男                     生年月日:  会員種別:会員               メルマガ希望:プラン名：ビジネス応援「ゆったりデラックス」素泊まり(bien14)2013年08月18日から    1泊  ＲＣ  サ込税込入込方法：                   チェックイン時間：15:00人員総数：   1人  内訳：(男)1名客室総数：   1室08月18日  dsn  (デラックスシングル（禁煙）(シングル))  @8,000          大人（男）     1名                                   宿泊料金計                ：     \\8,000                       合計料金                              ：     \\8,000                     【宿泊者への請求額】                    ：     \\8,000           ---------------------------------------------------------------------支払い方法  ：現払いご確認事項：食事なし禁煙ルームをお願いします質問1:駐車場ご利用の場合はAとお車の台数を、ご利用のない場合はBとご記入ください。回答1:B取扱個所：株式会社一休(001)  TEL 03-6685-0065  FAX 03-6234-8921会員番号：01006096---</TelegramData>                <PhoneNumber>0423241785</PhoneNumber>                <PostalCode>185-0023</PostalCode>                <Address>東京都 国分寺市 西元町　2-11-7</Address>                <TotalPaxManCount>1</TotalPaxManCount>                <BranchFaxNumber>03-6234-8921</BranchFaxNumber>                <Version>2.0</Version>                <RepresentativePhoneType>2</RepresentativePhoneType>                <RepresentativeGeneration>40代</RepresentativeGeneration>                <RepresentativeGendar>0</RepresentativeGendar>                <AccommodationId>G66249</AccommodationId>            </Basic>            <Allotment>                <AssignDiv>1</AssignDiv>                <GenderDiv>0</GenderDiv>                <HandleDiv>1</HandleDiv>                <RsvUserDiv>1</RsvUserDiv>                <UseDiv>1</UseDiv>            </Allotment>  <Option>                <OptionDate>2013-07-22</OptionDate>                <Name>特選会席料理</Name>                <OptionCount>4</OptionCount>                <OptionRate>12000</OptionRate>            </Option>            <Option>                <OptionDate>2013-07-22</OptionDate>                <Name>お土産（陣屋どらやき　6個入）</Name>                <OptionCount>1</OptionCount>                <OptionRate>960</OptionRate>            </Option>            <Option>                <OptionDate>2013-07-22</OptionDate>                <Name>お土産（やまと豚の桜味噌漬け 10枚入）</Name>                <OptionCount>3</OptionCount>                <OptionRate>1575</OptionRate>            </Option>            <Option>                <OptionDate>2013-07-22</OptionDate>                <Name>お土産（やまと豚の桜味噌漬け 20枚入）</Name>                <OptionCount>3</OptionCount>                <OptionRate>3150</OptionRate>            </Option>          <RoomAndRoomRateInformation>                <RoomInformation>                    <RoomTypeCode>20</RoomTypeCode>                    <RoomTypeName>デラックスシングル（禁煙）(シングル)</RoomTypeName>                    <PerRoomPaxCount>1</PerRoomPaxCount>                    <RoomPaxMaleCount>1</RoomPaxMaleCount>                    <RoomPaxFemaleCount>0</RoomPaxFemaleCount>                    <RoomChildA70Count>0</RoomChildA70Count>                    <RoomChildB50Count>0</RoomChildB50Count>                    <RoomChildC30Count>0</RoomChildC30Count>                    <RoomChildDNoneCount>0</RoomChildDNoneCount>                    <RoomTypeAgent>80</RoomTypeAgent>                    <RoomFrame>--</RoomFrame>                    <NetRmTypeGroupCode>4</NetRmTypeGroupCode>                    <PlanGroupCode>18</PlanGroupCode>                </RoomInformation>                <RoomRateInformation>                    <RoomDate>2013-08-18</RoomDate>                    <PerPaxRate>8000</PerPaxRate>                    <PerChildA70Rate>0</PerChildA70Rate>                    <PerChildB50Rate>0</PerChildB50Rate>                    <PerChildC30Rate>0</PerChildC30Rate>                    <PerChildDRate>0</PerChildDRate>                    <TotalPerRoomRate>8000</TotalPerRoomRate>                    <PerMaleRate>8000</PerMaleRate>                    <RoomRatePaxMaleCount>1</RoomRatePaxMaleCount>                    <RoomRatePaxFemaleCount>0</RoomRatePaxFemaleCount>                    <RoomRateChildA70Count>0</RoomRateChildA70Count>                    <RoomRateChildB50Count>0</RoomRateChildB50Count>                    <RoomRateChildC30Count>0</RoomRateChildC30Count>                    <RoomRateChildDNoneCount>0</RoomRateChildDNoneCount>                     <TotalRoomHotSpringTax>100</TotalRoomHotSpringTax>                    <TotalPerRoomServiceFee>500</TotalPerRoomServiceFee>                </RoomRateInformation>            </RoomAndRoomRateInformation>            <Member>                <UserName>野村 豊幸</UserName>                <UserKana>のむら かずゆき</UserKana>                <UserZip>185-0023</UserZip>                <UserAddr>東京都 国分寺市 西元町　2-11-7</UserAddr>                <UserID>01006096</UserID>                <UserType>会員</UserType>                <UserGendar>0</UserGendar>            </Member>            <OtherInfo>                <GuestRequest>食事なし禁煙ルームをお願いします</GuestRequest>                <AdditionalInformation>質問1:駐車場ご利用の場合はAとお車の台数を、ご利用のない場合はBとご記入ください。回答1:B</AdditionalInformation>            </OtherInfo>        </RisaplsCommonInformation>        <AgentNativeInformation>            <Extend>                <TotalAccommodationDecleasePoints>8000</TotalAccommodationDecleasePoints>                <AmountClaimed>8000</AmountClaimed>            </Extend>            <Extendmytrip>                <SettlementDiv>0</SettlementDiv>            </Extendmytrip>        </AgentNativeInformation>    </RisaplsInformation></AllotmentBookingReport>';
    	String dateKey = System.now().format('yyMMddHHMMssSSS');
    	Attachment newAttach = new Attachment(
									ParentId = parentId,
									Name = 'TAPDATA_' + dateKey + '1_Test.xml', 
									ContentType = 'text/xml',
									Body = Blob.valueOf(infoTravelXML)
								);
		insert newAttach;
    }
    private static void createDocumentSetDiv1(String parentId){
    	String infoTravelXML = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><AllotmentBookingReport>    <TransactionType>        <DataFrom>FromTravelAgency</DataFrom>        <DataClassification>NewBookReport</DataClassification>        <DataID>108197271-1</DataID><BookingDataID>108197271-1</BookingDataID><SystemDate>2013-08-29</SystemDate>    </TransactionType>    <AccommodationInformation>        <AccommodationName>松本丸の内ホテル</AccommodationName>        <AccommodationCode>70763</AccommodationCode>    </AccommodationInformation>    <SalesOfficeInformation><SalesOfficeCompanyCode>88</SalesOfficeCompanyCode><SalesOfficeCompanyName>楽天トラベル</SalesOfficeCompanyName>    </SalesOfficeInformation>    <BasicInformation>        <TravelAgencyBookingNumber>RYa034869d</TravelAgencyBookingNumber>        <TravelAgencyBookingDate>2013-08-29</TravelAgencyBookingDate>        <TravelAgencyBookingTime>18:08:10</TravelAgencyBookingTime>        <TravelAgencyReportNumber>00000212</TravelAgencyReportNumber>        <GuestOrGroupNameSingleByte>なかつ はつお　＊【精算不要】</GuestOrGroupNameSingleByte>        <GuestOrGroupNameKanjiName>なかつ はつお　＊【精算不要】</GuestOrGroupNameKanjiName>        <CheckInDate>2013-09-12</CheckInDate>        <CheckInTime>20:00:00</CheckInTime>        <CheckOutDate>2013-09-13</CheckOutDate>        <Nights>1</Nights>        <TotalRoomCount>1</TotalRoomCount>        <GrandTotalPaxCount>1</GrandTotalPaxCount>        <TotalPaxMaleCount>1</TotalPaxMaleCount>        <TotalPaxFemaleCount>0</TotalPaxFemaleCount>        <TotalChildA70Count>0</TotalChildA70Count>        <TotalChildB50Count>0</TotalChildB50Count>        <TotalChildC30Count>0</TotalChildC30Count>        <TotalChildDNoneCount>0</TotalChildDNoneCount>        <PackagePlanName>快眠★セミダブルベットルーム１名様ご利用プラン☆★☆</PackagePlanName>        <PackagePlanCode>1923021</PackagePlanCode>        <MealCondition>WithoutMeal</MealCondition>        <SpecificMealCondition>None Specified</SpecificMealCondition>        <OtherServiceInformation>決済内容：法人利用★  支払額：7,000円食事なしＡ　レクサスＨＳ１台　駐車場は１２:００から止めさせて頂くことを希望します2013-08-29 18:02:462013-08-29 18:07:16</OtherServiceInformation>    </BasicInformation>    <BasicRateInformation>        <RoomRateOrPersonalRate>PersonalRate</RoomRateOrPersonalRate>        <TaxServiceFee>IncludingServiceAndTax</TaxServiceFee>        <TotalAccommodationCharge>7000</TotalAccommodationCharge>        <TotalAccommodationOtherFee>0</TotalAccommodationOtherFee>    </BasicRateInformation>    <RoomAndGuestInformation>        <RoomAndGuestList>            <RoomInformation>                <RoomTypeCode>55</RoomTypeCode>                <RoomTypeName>スタンダードツインstn（禁煙）</RoomTypeName>                <RoomPaxMaleCount>1</RoomPaxMaleCount>                <RoomSpecialRequest>一人あたりの料金にて</RoomSpecialRequest>            </RoomInformation>            <RoomRateInformation>                <RoomDate>2013-09-12</RoomDate>                <PerPaxRate>7000</PerPaxRate>            </RoomRateInformation>        </RoomAndGuestList>    </RoomAndGuestInformation>    <RisaplsInformation>        <RisaplsCommonInformation>            <Basic>                <SalesOfficeCompanyCode>61</SalesOfficeCompanyCode>                <TelegramDiv></TelegramDiv>                <RisaplsDataID></RisaplsDataID>                <RisaplsTelegramNumber></RisaplsTelegramNumber>                <TelegramData>予約通知 楽天トラベル                                  SNT-NET 08-29 18:09 (61) 予約番号： RYa034869d  NO.00000212 松本丸の内ホテル様(70763)宿泊者情報：  なかつ はつお　＊【精算不要】  TEL:090-5240-3824  なかつ はつお　＊【精算不要】予約者情報：  中津 初雄  TEL:090-5240-3824  ﾅｶﾂ ﾊﾂｵプラン名：快眠★セミダブルベットルーム１名様ご利用プラン☆★☆(1923021)2013年09月12日から    1泊  食事なし  サ込税込入込方法：                   チェックイン時間：20:00人員総数：   1人  内訳：(男)1名客室総数：   1室09月12日  nstwpp  (スタンダードツインstn（禁煙）)          大人（男）     1名     @7,000                                   宿泊料金計                ：     \\7,000                       合計料金                              ：     \\7,000                     【宿泊者への請求額】                    ：         \\0           ---------------------------------------------------------------------                                 決済内容：法人利用★  支払額：7,000円ご確認事項：食事なしＡ　レクサスＨＳ１台　駐車場は１２:００から止めさせて頂くことを希望しますお問い合わせ：[大人:7000円×1＝7000円]会員ポイント：付与ポイント0ポイント使用ポイント0ポイント---</TelegramData>                <PhoneNumber>090-5240-3824</PhoneNumber>                <TotalPaxManCount>1</TotalPaxManCount>                <Version>2.0</Version>                <AccommodationId>G66249</AccommodationId>            </Basic>            <Allotment>                <AssignDiv>1</AssignDiv>                <GenderDiv>0</GenderDiv>                <HandleDiv>0</HandleDiv>                <RsvUserDiv>1</RsvUserDiv>                <UseDiv>1</UseDiv>            </Allotment>            <RoomAndRoomRateInformation>                <RoomInformation>                    <RoomTypeCode>55</RoomTypeCode>                    <RoomTypeName>スタンダードツインstn（禁煙）</RoomTypeName>                    <RoomPaxMaleCount>1</RoomPaxMaleCount>                    <RoomSpecialRequest>一人あたりの料金にて</RoomSpecialRequest>                    <RoomTypeAgent>61</RoomTypeAgent>                    <RoomFrame>--</RoomFrame>                    <NetRmTypeGroupCode>10</NetRmTypeGroupCode>                    <PlanGroupCode>68</PlanGroupCode>                </RoomInformation>                <RoomRateInformation>                    <RoomDate>2013-09-12</RoomDate>                    <PerPaxRate>7000</PerPaxRate>                    <PerMaleRate>7000</PerMaleRate>                    <RoomRatePaxMaleCount>1</RoomRatePaxMaleCount>                </RoomRateInformation>            </RoomAndRoomRateInformation>            <Member>                <UserName>中津 初雄</UserName>                <UserKana>ﾅｶﾂ ﾊﾂｵ</UserKana>                <UserTel>090-5240-3824</UserTel>                <UserGivingPoints>0</UserGivingPoints>                <UserUsePoints>0</UserUsePoints>            </Member>            <OtherInfo>                <GuestRequest>食事なしＡ　レクサスＨＳ１台　駐車場は１２:００から止めさせて頂くことを希望します</GuestRequest>            </OtherInfo>        </RisaplsCommonInformation>        <AgentNativeInformation>            <Extendmytrip>                <TodayReserve>---</TodayReserve>                <TotalMaleCount>1</TotalMaleCount>                <TotalFemaleCount>0</TotalFemaleCount>                <SettlementDiv>1</SettlementDiv>            </Extendmytrip>        </AgentNativeInformation>    </RisaplsInformation></AllotmentBookingReport>';
    	String dateKey = System.now().format('yyMMddHHMMssSSS');
    	Attachment newAttach = new Attachment(
									ParentId = parentId,
									Name = 'TAPDATA_' + dateKey + '1_Test.xml', 
									ContentType = 'text/xml',
									Body = Blob.valueOf(infoTravelXML)
								);
		insert newAttach;
    }
    private static void createDocumentSetDiv2(String parentId){
    	String infoTravelXML = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><AllotmentBookingReport>    <TransactionType>        <DataFrom>FromTravelAgency</DataFrom>        <DataClassification>NewBookReport</DataClassification>        <DataID>107514837-1</DataID><BookingDataID>107514837-1</BookingDataID><SystemDate>2013-08-24</SystemDate>    </TransactionType>    <AccommodationInformation>        <AccommodationName>松本丸の内ホテル</AccommodationName>        <AccommodationCode>00001782</AccommodationCode>    </AccommodationInformation>    <SalesOfficeInformation><SalesOfficeCompanyCode>88</SalesOfficeCompanyCode><SalesOfficeCompanyName>一休.com</SalesOfficeCompanyName>        <SalesOfficeName>株式会社一休</SalesOfficeName>        <SalesOfficeCode>001</SalesOfficeCode>        <SalesOfficePhoneNumber>03-6685-0065</SalesOfficePhoneNumber>    </SalesOfficeInformation>    <BasicInformation>        <TravelAgencyBookingNumber>IK0145414533</TravelAgencyBookingNumber>        <TravelAgencyBookingDate>2013-08-24</TravelAgencyBookingDate>        <TravelAgencyBookingTime>15:45:13</TravelAgencyBookingTime>        <TravelAgencyReportNumber>00000061</TravelAgencyReportNumber>        <GuestOrGroupNameSingleByte>ﾅｶﾉﾒ ﾔｴｺ</GuestOrGroupNameSingleByte>        <GuestOrGroupNameDoubleByte>なかのめ やえこ</GuestOrGroupNameDoubleByte>        <GuestOrGroupNameKanjiName>中目 八重子</GuestOrGroupNameKanjiName>        <CheckInDate>2013-08-31</CheckInDate>        <CheckInTime>15:00:00</CheckInTime>        <CheckOutDate>2013-09-01</CheckOutDate>        <Nights>1</Nights>        <TotalRoomCount>1</TotalRoomCount>        <GrandTotalPaxCount>2</GrandTotalPaxCount>        <TotalPaxMaleCount>0</TotalPaxMaleCount>        <TotalPaxFemaleCount>2</TotalPaxFemaleCount>        <TotalChildA70Count>0</TotalChildA70Count>        <TotalChildB50Count>0</TotalChildB50Count>        <TotalChildC30Count>0</TotalChildC30Count>        <TotalChildDNoneCount>0</TotalChildDNoneCount>        <PackagePlanName>「体にきく」長野県発！ハーブの恵みプレゼント朝食付</PackagePlanName>        <PackagePlanCode>bien16</PackagePlanCode>        <MealCondition>1nightBreakfast</MealCondition>        <SpecificMealCondition>None Specified</SpecificMealCondition>        <OtherServiceInformation>決済内容：カード決済★朝食付き質問1:駐車場ご利用の場合はAとお車の台数を、ご利用なない場合はBとご記入ください。回答1:ｂ質問2:ご宿泊当日にご連絡可能なお電話番号をお教えください。回答2:０９０４５３４５３９１</OtherServiceInformation>    </BasicInformation>    <BasicRateInformation>        <RoomRateOrPersonalRate>RoomRate</RoomRateOrPersonalRate>        <TaxServiceFee>IncludingServiceAndTax</TaxServiceFee>        <TotalAccommodationCharge>16000</TotalAccommodationCharge>        <TotalAccommodationHotSpringTax>0</TotalAccommodationHotSpringTax>    </BasicRateInformation>    <RoomAndGuestInformation>        <RoomAndGuestList>            <RoomInformation>                <RoomTypeCode>45</RoomTypeCode>                <RoomTypeName>デラックスダブル（禁煙）(ダブル)</RoomTypeName>                <PerRoomPaxCount>2</PerRoomPaxCount>                <RoomPaxMaleCount>0</RoomPaxMaleCount>                <RoomPaxFemaleCount>2</RoomPaxFemaleCount>                <RoomChildA70Count>0</RoomChildA70Count>                <RoomChildB50Count>0</RoomChildB50Count>                <RoomChildC30Count>0</RoomChildC30Count>                <RoomChildDNoneCount>0</RoomChildDNoneCount>            </RoomInformation>            <RoomRateInformation>                <RoomDate>2013-08-31</RoomDate>                <PerPaxRate>16000</PerPaxRate>                <PerChildA70Rate>0</PerChildA70Rate>                <PerChildB50Rate>0</PerChildB50Rate>                <PerChildC30Rate>0</PerChildC30Rate>                <PerChildDRate>0</PerChildDRate>                <TotalPerRoomRate>16000</TotalPerRoomRate>            </RoomRateInformation>        </RoomAndGuestList>    </RoomAndGuestInformation>    <RisaplsInformation>        <RisaplsCommonInformation>            <Basic>                <SalesOfficeCompanyCode>80</SalesOfficeCompanyCode>                <TelegramDiv></TelegramDiv>                <RisaplsDataID></RisaplsDataID>                <RisaplsTelegramNumber></RisaplsTelegramNumber>                <TelegramData>予約通知 一休.com                                      SNT-NET 08-24 15:46 (80) 予約番号： IK0145414533  NO.00000061 松本丸の内ホテル様(00001782)宿泊者情報：  中目 八重子  TEL:0235241225  ﾅｶﾉﾒ ﾔｴｺ  住所:(〒997-0027)山形県 鶴岡市昭和町10-1  性別:女        年代:60代以上        年齢:予約者情報：  中目 八重子  なかのめ やえこ  住所:(〒997-0027)山形県 鶴岡市昭和町10-1  性別:女                     生年月日:  会員種別:会員               メルマガ希望:プラン名：「体にきく」長野県発！ハーブの恵みプレゼント朝食付(bien16)2013年08月31日から    1泊  ＲＣ  サ込税込入込方法：                   チェックイン時間：15:00人員総数：   2人  内訳：(女)2名客室総数：   1室08月31日  ddbn  (デラックスダブル（禁煙）(ダブル))  @16,000          大人（女）     2名                                   宿泊料金計                ：    \\16,000                       合計料金                              ：    \\16,000                       割引額(ポイント・補助金)              ：       \\320                       割引後の金額                          ：    \\15,680                     【宿泊者への請求額】                    ：         \\0           ---------------------------------------------------------------------                                 決済内容：カード決済★ご確認事項：朝食付き質問1:駐車場ご利用の場合はAとお車の台数を、ご利用なない場合はBとご記入ください。回答1:ｂ質問2:ご宿泊当日にご連絡可能なお電話番号をお教えください。回答2:０９０４５３４５３９１取扱個所：株式会社一休(001)  TEL 03-6685-0065  FAX 03-6234-8921会員番号：00192926---</TelegramData>                <PhoneNumber>0235241225</PhoneNumber>                <PostalCode>997-0027</PostalCode>                <Address>山形県 鶴岡市昭和町10-1</Address>                <TotalPaxManCount>2</TotalPaxManCount>                <BranchFaxNumber>03-6234-8921</BranchFaxNumber>                <Version>2.0</Version>                <RepresentativePhoneType>2</RepresentativePhoneType>                <RepresentativeGeneration>60代以上</RepresentativeGeneration>                <RepresentativeGendar>1</RepresentativeGendar>                <AccommodationId>G66249</AccommodationId>            </Basic>            <Allotment>                <AssignDiv>1</AssignDiv>                <GenderDiv>1</GenderDiv>                <HandleDiv>1</HandleDiv>                <RsvUserDiv>1</RsvUserDiv>                <UseDiv>0</UseDiv>            </Allotment>            <RoomAndRoomRateInformation>                <RoomInformation>                    <RoomTypeCode>45</RoomTypeCode>                    <RoomTypeName>デラックスダブル（禁煙）(ダブル)</RoomTypeName>                    <PerRoomPaxCount>2</PerRoomPaxCount>                    <RoomPaxMaleCount>0</RoomPaxMaleCount>                    <RoomPaxFemaleCount>2</RoomPaxFemaleCount>                    <RoomChildA70Count>0</RoomChildA70Count>                    <RoomChildB50Count>0</RoomChildB50Count>                    <RoomChildC30Count>0</RoomChildC30Count>                    <RoomChildDNoneCount>0</RoomChildDNoneCount>                    <RoomTypeAgent>80</RoomTypeAgent>                    <RoomFrame>--</RoomFrame>                    <NetRmTypeGroupCode>8</NetRmTypeGroupCode>                    <PlanGroupCode>51</PlanGroupCode>                </RoomInformation>                <RoomRateInformation>                    <RoomDate>2013-08-31</RoomDate>                    <PerPaxRate>16000</PerPaxRate>                    <PerChildA70Rate>0</PerChildA70Rate>                    <PerChildB50Rate>0</PerChildB50Rate>                    <PerChildC30Rate>0</PerChildC30Rate>                    <PerChildDRate>0</PerChildDRate>                    <TotalPerRoomRate>16000</TotalPerRoomRate>                    <PerFemaleRate>16000</PerFemaleRate>                    <RoomRatePaxMaleCount>0</RoomRatePaxMaleCount>                    <RoomRatePaxFemaleCount>2</RoomRatePaxFemaleCount>                    <RoomRateChildA70Count>0</RoomRateChildA70Count>                    <RoomRateChildB50Count>0</RoomRateChildB50Count>                    <RoomRateChildC30Count>0</RoomRateChildC30Count>                    <RoomRateChildDNoneCount>0</RoomRateChildDNoneCount>                </RoomRateInformation>            </RoomAndRoomRateInformation>            <Member>                <UserName>中目 八重子</UserName>                <UserKana>なかのめ やえこ</UserKana>                <UserZip>997-0027</UserZip>                <UserAddr>山形県 鶴岡市昭和町10-1</UserAddr>                <UserID>00192926</UserID>                <UserType>会員</UserType>                <UserGendar>1</UserGendar>            </Member>            <OtherInfo>                <GuestRequest>朝食付き</GuestRequest>                <AdditionalInformation>質問1:駐車場ご利用の場合はAとお車の台数を、ご利用なない場合はBとご記入ください。回答1:ｂ質問2:ご宿泊当日にご連絡可能なお電話番号をお教えください。回答2:０９０４５３４５３９１</AdditionalInformation>            </OtherInfo>            <BasicRate>                <PointsDiscountList>                    <PointsDiscount>320</PointsDiscount>                </PointsDiscountList>            </BasicRate>        </RisaplsCommonInformation>        <AgentNativeInformation>            <Extend>                <Points>320</Points>                <TotalAccommodationDecleasePoints>15680</TotalAccommodationDecleasePoints>                <AmountClaimed>0</AmountClaimed>            </Extend>            <Extendmytrip>                <SettlementDiv>2</SettlementDiv>            </Extendmytrip>        </AgentNativeInformation>    </RisaplsInformation></AllotmentBookingReport>';
    	String dateKey = System.now().format('yyMMddHHMMssSSS');
    	Attachment newAttach = new Attachment(
									ParentId = parentId,
									Name = 'TAPDATA_' + dateKey + '1_Test.xml', 
									ContentType = 'text/xml',
									Body = Blob.valueOf(infoTravelXML)
								);
		insert newAttach;
    }
    private static void createDocumentBlank(String parentId){
    	String infoTravelXML = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><AllotmentBookingReport>    <TransactionType>        <DataFrom>Rakujan</DataFrom>        <DataClassification>NewBookReport</DataClassification>        <DataID>120902002</DataID><BookingDataID>120902002-1</BookingDataID><SystemDate>2012-09-02</SystemDate>        <SystemTime>11:43:00</SystemTime>    </TransactionType>    <ResultInformation>    	<ResultCode>0</ResultCode>    	<DetailedInformation>    		<ErrorCode>ErrorCode=0</ErrorCode>   		    		<ErrorText>ErrorText=空白</ErrorText>   		    	</DetailedInformation>    </ResultInformation>    <AccommodationInformation>		<AccommodationArea>AccommodationArea-1</AccommodationArea>		<AccommodationName>AccommodationName-1</AccommodationName>		<AccommodationCode>AccommodationCode-1</AccommodationCode>		<ChainName>ChainName-1</ChainName>		<AccommodationPersonInCharge>AccommodationPersonInCharge-1</AccommodationPersonInCharge>		<AccommodationEmail>AccommodationEmail-1</AccommodationEmail>		<AccommodationPhoneNumber>AccommodationPhoneNumber-1</AccommodationPhoneNumber>        <AccommodationCPUAddress>AccommodationCPUAddress-1</AccommodationCPUAddress>        <BankList>			<BankName>BankName-1</BankName>			<BankAccountNumber>BankAccountNumber-1</BankAccountNumber>			<BankBranchName>BankBranchName-1</BankBranchName>			<BankAccountClassification>BankAccountClassification-1</BankAccountClassification>			<BankAccountName>BankAccountName-1</BankAccountName>        </BankList>        <BankList>			<BankName>BankName-2</BankName>			<BankAccountNumber>BankAccountNumber-2</BankAccountNumber>			<BankBranchName>BankBranchName-2</BankBranchName>			<BankAccountClassification>BankAccountClassification-2</BankAccountClassification>			<BankAccountName>BankAccountName-2</BankAccountName>        </BankList>    </AccommodationInformation>    <SalesOfficeInformation>		<SalesOfficeCompanyCode>01</SalesOfficeCompanyCode>		<SalesOfficeCompanyName>SalesOfficeCompanyName-1</SalesOfficeCompanyName>		<SalesOfficeName>SalesOfficeName-1</SalesOfficeName>		<SalesOfficeCode>SalesOfficeCode-1</SalesOfficeCode>		<SalesOfficePersonInCharge>SalesOfficePersonInCharge-1</SalesOfficePersonInCharge>		<SalesOfficeEmail>SalesOfficeEmail-1</SalesOfficeEmail>		<SalesOfficePhoneNumber>SalesOfficePhoneNumber-1</SalesOfficePhoneNumber>		<SalesOfficeStateProvidence>SalesOfficeStateProvidence-1</SalesOfficeStateProvidence>		<SalesOfficeCityName>SalesOfficeCityName-1</SalesOfficeCityName>		<SalesOfficeAddressLine>SalesOfficeAddressLine-1</SalesOfficeAddressLine>		<SalesOfficeStreetNumber>SalesOfficeStreetNumber-1</SalesOfficeStreetNumber>		<SalesOfficePostalCode>SalesOfficePostalCode-1</SalesOfficePostalCode>		<SalesOfficeRegisteredCategory>SalesOfficeRegisteredCategory-1</SalesOfficeRegisteredCategory>		<SalesOfficeLicenseNumber>SalesOfficeLicenseNumber-1</SalesOfficeLicenseNumber>		<SalesOfficeRegisteredPrefecture>SalesOfficeRegisteredPrefecture-1</SalesOfficeRegisteredPrefecture>		<SalesOfficeCPUAddress>SalesOfficeCPUAddress-1</SalesOfficeCPUAddress>		<RetailerCompanyName>RetailerCompanyName-1</RetailerCompanyName>		<RetailerOfficeName>RetailerOfficeName-1</RetailerOfficeName>		<RetailerOfficeCode>RetailerOfficeCode-1</RetailerOfficeCode>		<RetailerPersonInCharge>RetailerPersonInCharge-1</RetailerPersonInCharge>		<RetailerEmail>RetailerEmail-1</RetailerEmail>		<RetailerPhoneNumber>RetailerPhoneNumber-1</RetailerPhoneNumber>		<RetailerStateProvidence>RetailerStateProvidence-1</RetailerStateProvidence>		<RetailerCityName>RetailerCityName-1</RetailerCityName>		<RetailerAddressLine>RetailerAddressLine-1</RetailerAddressLine>		<RetailerStreetNumber>RetailerStreetNumber-1</RetailerStreetNumber>		<RetailerPostalCode>RetailerPostalCode-1</RetailerPostalCode>		<RetailerRegisteredCategory>RetailerRegisteredCategory-1</RetailerRegisteredCategory>		<RetailerLicenseNumber>RetailerLicenseNumber-1</RetailerLicenseNumber>		<RetailerRegisteredPrefecture>RetailerRegisteredPrefecture-1</RetailerRegisteredPrefecture>    </SalesOfficeInformation>    <BasicInformation>		<TravelAgencyBookingNumber>TravelAgencyBookingNumber-1</TravelAgencyBookingNumber>		<TravelAgencyBookingDate>2012-08-26</TravelAgencyBookingDate>		<TravelAgencyBookingTime>00:00:00</TravelAgencyBookingTime>		<TravelAgencyReportNumber>TravelAgencyReportNumber-1</TravelAgencyReportNumber>		<AccommodationConfirmationNumber>AccommodationConfirmationNumber-1</AccommodationConfirmationNumber>		<GuestOrGroupNameSingleByte>GuestOrGroupNameSingleByte-1</GuestOrGroupNameSingleByte>		<GuestOrGroupNameDoubleByte>GuestOrGroupNameDoubleByte-1</GuestOrGroupNameDoubleByte>		<GuestOrGroupNameKanjiName>3日泊まりお客様</GuestOrGroupNameKanjiName>		<GroupNameWelcomeBoard>GroupNameWelcomeBoard-1</GroupNameWelcomeBoard>		<CheckInDate>2012-09-01</CheckInDate>		<CheckInTime>13:00:00</CheckInTime>		<CheckOutDate>2012-09-04</CheckOutDate>		<CheckOutTime>11:00:00</CheckOutTime>		<Nights>3</Nights>		<Transportaion>Transportaion-1</Transportaion>		<CoachCount>10</CoachCount>		<CoachCompany>CoachCompany-1</CoachCompany>		<TotalRoomCount>1</TotalRoomCount>		<GrandTotalPaxCount>20</GrandTotalPaxCount>		<TotalPaxMaleCount>2</TotalPaxMaleCount>		<TotalPaxFemaleCount>2</TotalPaxFemaleCount>		<TotalChildA70Count>2</TotalChildA70Count>		<TotalChildB50Count>2</TotalChildB50Count>		<TotalChildC30Count>2</TotalChildC30Count>		<TotalChildDNoneCount>2</TotalChildDNoneCount>		<TotalChildECount>2</TotalChildECount>		<TotalChildFCount>2</TotalChildFCount>		<TotalChildOtherCount>2</TotalChildOtherCount>		<TotalTourConductorCount>2</TotalTourConductorCount>		<TotalCoachDriverCount>2</TotalCoachDriverCount>		<TotalGuideCount>2</TotalGuideCount>		<TypeOfGroup>TypeOfGroup-1</TypeOfGroup>		<Status>Status-1</Status>		<PackageType>PackageType-2</PackageType>		<PackagePlanName>PackagePlanName-2</PackagePlanName>		<PackagePlanCode>PackagePlanCode-2</PackagePlanCode>		<PackagePlanContent>PackagePlanContent-2</PackagePlanContent>		<Option>			<OptionDate>2001-01-01</OptionDate>			<Name>Option_Name</Name>			<NameRequest>Option_NameRequest</NameRequest>			<OptionCount>11</OptionCount>			<OptionRate>111</OptionRate>	<OptionCode>111</OptionCode>	</Option>		<Option>			<OptionDate>2001-01-02</OptionDate>			<Name>Option_Name2</Name>			<NameRequest>Option_NameRequest2</NameRequest>			<OptionCount>22</OptionCount>			<OptionRate>222</OptionRate>		</Option>		<MealCondition>1night2meals</MealCondition>		<SpecificMealCondition>SpecificMealCondition-1</SpecificMealCondition>		<MealPlace>MealPlace-1</MealPlace>		<BanquetRoom>BanquetRoom-1</BanquetRoom>		<ModificationType>ModificationType-1</ModificationType>		<ModificationPoint>ModificationPoint-3</ModificationPoint>		<CancellationNumber>CancellationNumber-1</CancellationNumber>		<PreviousPlace>PreviousPlace-1</PreviousPlace>		<PreviousAccommodationName>PreviousAccommodationName-1</PreviousAccommodationName>		<PreviousAccommodationName>PreviousAccommodationName-2</PreviousAccommodationName>		<PreviousAccommodationName>PreviousAccommodationName-3</PreviousAccommodationName>		<SpecialServiceRequest>SpecialServiceRequest-1</SpecialServiceRequest>		<SpecialServiceRequest>SpecialServiceRequest-2</SpecialServiceRequest>		<SpecialServiceRequest>SpecialServiceRequest-3</SpecialServiceRequest>		<OtherServiceInformation>OtherServiceInformation-1</OtherServiceInformation>		<FollowUpInformation>FollowUpInformation-1</FollowUpInformation>    </BasicInformation>    <BasicRateInformation>		<RoomRateOrPersonalRate>PersonalRate</RoomRateOrPersonalRate>		<TaxServiceFee>IncludingServiceWithOutTax</TaxServiceFee>		<Payment>Payment-1</Payment>		<BareNetRate>1000</BareNetRate>		<CancellationCharge>2000</CancellationCharge>		<CreditCardAuthority>CreditCardAuthority-1</CreditCardAuthority>		<CreditCardNumber>CreditCardNumber-1</CreditCardNumber>		<ExpireDate>2020-01-01</ExpireDate>		<CardHolderName>CardHolderName-1</CardHolderName>		<TotalAccommodationCharge>100000</TotalAccommodationCharge>		<TotalAccommodationConsumptionTax>5000</TotalAccommodationConsumptionTax>		<TotalAccommodationHotSpringTax>2000</TotalAccommodationHotSpringTax>		<TotalAccommodationHotelTax>30000</TotalAccommodationHotelTax>		<TotalAccommodationServiceFee>3000</TotalAccommodationServiceFee>		<TotalAccommodationBreakfastFee>50000</TotalAccommodationBreakfastFee>		<TotalAccommodationOtherFee>100000</TotalAccommodationOtherFee>		<CommissionPercentage>0.5</CommissionPercentage>		<TotalAccommodationCommissionAmount>234567</TotalAccommodationCommissionAmount>		<TotalAccommodationCommissionConsumptionTax>5555</TotalAccommodationCommissionConsumptionTax>		<TotalAccommodationChargeAfterCheckIn>123451</TotalAccommodationChargeAfterCheckIn>		<TotalBalanceAfterCheckIn>23456</TotalBalanceAfterCheckIn>		<TotalAccommodationConsumptionAfterCheckIn>9876</TotalAccommodationConsumptionAfterCheckIn>		<CancellationChargeAfterCheckIn>321987</CancellationChargeAfterCheckIn>		<MembershipFee>335577</MembershipFee>		<AdjustmentFee>112233</AdjustmentFee>        <CouponList>			<CouponAmount>1</CouponAmount>			<CouponType>CouponType-1</CouponType>			<CouponNumber>CouponNumber-1</CouponNumber>			<CouponIssueDate>CouponIssueDate-1</CouponIssueDate>        </CouponList>        <CouponList>			<CouponAmount>2</CouponAmount>			<CouponType>CouponType-2</CouponType>			<CouponNumber>CouponNumber-2</CouponNumber>			<CouponIssueDate>CouponIssueDate-2</CouponIssueDate>        </CouponList>    </BasicRateInformation>    <RoomAndGuestInformation>        <RoomAndGuestList>            <RoomInformation>				<RoomTypeCode>R004</RoomTypeCode>				<RoomTypeName>ベッドルーム付き和洋室</RoomTypeName>				<RoomCategory>RoomCategory-1</RoomCategory>				<ViewType>ViewType-1</ViewType>				<SmokingOrNonSmoking>SmokingOrNonSmoking-1</SmokingOrNonSmoking>				<RoomPaxMaleCount>2</RoomPaxMaleCount>				<RoomPaxFemaleCount>2</RoomPaxFemaleCount>				<RoomChildA70Count>2</RoomChildA70Count>				<RoomChildB50Count>2</RoomChildB50Count>				<RoomChildC30Count>2</RoomChildC30Count>				<RoomChildDNoneCount>2</RoomChildDNoneCount>				<RoomChildECount>2</RoomChildECount>				<RoomChildFCount>2</RoomChildFCount>				<RoomChildOtherCount>2</RoomChildOtherCount>				<RoomByRoomStatus>RoomByRoomStatus-1</RoomByRoomStatus>				<RoomByRoomConfirmationNumber>RoomByRoomConfirmationNumber-1</RoomByRoomConfirmationNumber>				<Facilities>Facilities-1</Facilities>				<Facilities>Facilities-2</Facilities>				<Facilities>Facilities-3</Facilities>				<AssignedRoomNumber>AssignedRoomNumber-1</AssignedRoomNumber>				<RoomSpecialRequest>RoomSpecialRequest-1</RoomSpecialRequest>				<RoomSpecialRequest>RoomSpecialRequest-2</RoomSpecialRequest>				<RoomSpecialRequest>RoomSpecialRequest-3</RoomSpecialRequest>				<RoomTypeAgent>RoomTypeAgent-1</RoomTypeAgent>				<RoomTypeAgent>RoomTypeAgent-2</RoomTypeAgent>				<RoomTypeAgent>RoomTypeAgent-3</RoomTypeAgent>            </RoomInformation>            <RoomRateInformation>				<RoomDate>2012-09-01</RoomDate>				<PerPaxRate>35000</PerPaxRate>				<PerChildA70Rate>12000</PerChildA70Rate>				<PerChildB50Rate>10000</PerChildB50Rate>				<PerChildC30Rate>8000</PerChildC30Rate>				<PerChildDRate>7000</PerChildDRate>				<PerChildERate>7010</PerChildERate>				<PerChildFRate>7060</PerChildFRate>				<PerChildOtherRate>6000</PerChildOtherRate>				<TotalPerRoomRate>70000</TotalPerRoomRate>				<TotalPerRoomConsumptionTax>3500</TotalPerRoomConsumptionTax>				<TotalRoomHotSpringTax>2500</TotalRoomHotSpringTax>				<TotalPerRoomHotelTax>2000</TotalPerRoomHotelTax>				<TotalPerRoomServiceFee>15000</TotalPerRoomServiceFee>				<TotalPerRoomBreakfastFee>35678</TotalPerRoomBreakfastFee>				<TotalPerRoomOtherFee>12345</TotalPerRoomOtherFee>				<TotalPerRoomCommissionAmount>56789</TotalPerRoomCommissionAmount>				<TotalPerRoomCommissionConsumptionTax>3567</TotalPerRoomCommissionConsumptionTax>				<RoomRateDetailInformation>					<RateCategory>1</RateCategory>					<RoomRate>15890</RoomRate>					<RatePaxCount>11</RatePaxCount>					<RateDetailInformation>RateDetailInformation-11</RateDetailInformation>				</RoomRateDetailInformation>				<RoomRateDetailInformation>					<RateCategory>2</RateCategory>					<RoomRate>28760</RoomRate>					<RatePaxCount>22</RatePaxCount>					<RateDetailInformation>RateDetailInformation-12</RateDetailInformation>				</RoomRateDetailInformation>            </RoomRateInformation>            <RoomRateInformation>				<RoomDate>2012-09-02</RoomDate>				<PerPaxRate>35002</PerPaxRate>				<PerChildA70Rate>12002</PerChildA70Rate>				<PerChildB50Rate>10002</PerChildB50Rate>				<PerChildC30Rate>8002</PerChildC30Rate>				<PerChildDRate>7002</PerChildDRate>				<PerChildERate>7022</PerChildERate>				<PerChildFRate>7082</PerChildFRate>				<PerChildOtherRate>6002</PerChildOtherRate>				<TotalPerRoomRate>70002</TotalPerRoomRate>				<TotalPerRoomConsumptionTax>3502</TotalPerRoomConsumptionTax>				<TotalRoomHotSpringTax>2502</TotalRoomHotSpringTax>				<TotalPerRoomHotelTax>2002</TotalPerRoomHotelTax>				<TotalPerRoomServiceFee>15002</TotalPerRoomServiceFee>				<TotalPerRoomBreakfastFee>35672</TotalPerRoomBreakfastFee>				<TotalPerRoomOtherFee>12342</TotalPerRoomOtherFee>				<TotalPerRoomCommissionAmount>56782</TotalPerRoomCommissionAmount>				<TotalPerRoomCommissionConsumptionTax>3562</TotalPerRoomCommissionConsumptionTax>				<RoomRateDetailInformation>					<RateCategory>1</RateCategory>					<RoomRate>35890</RoomRate>					<RatePaxCount>33</RatePaxCount>					<RateDetailInformation>RateDetailInformation-21</RateDetailInformation>				</RoomRateDetailInformation>				<RoomRateDetailInformation>					<RateCategory>2</RateCategory>					<RoomRate>48760</RoomRate>					<RatePaxCount>44</RatePaxCount>					<RateDetailInformation>RateDetailInformation-22</RateDetailInformation>				</RoomRateDetailInformation>            </RoomRateInformation>            <RoomRateInformation>				<RoomDate>2012-09-03</RoomDate>				<PerPaxRate>35003</PerPaxRate>				<PerChildA70Rate>12003</PerChildA70Rate>				<PerChildB50Rate>10003</PerChildB50Rate>				<PerChildC30Rate>8003</PerChildC30Rate>				<PerChildDRate>7003</PerChildDRate>				<PerChildERate>7033</PerChildERate>				<PerChildFRate>7093</PerChildFRate>				<PerChildOtherRate>6003</PerChildOtherRate>				<TotalPerRoomRate>70003</TotalPerRoomRate>				<TotalPerRoomConsumptionTax>3503</TotalPerRoomConsumptionTax>				<TotalRoomHotSpringTax>2503</TotalRoomHotSpringTax>				<TotalPerRoomHotelTax>2003</TotalPerRoomHotelTax>				<TotalPerRoomServiceFee>15003</TotalPerRoomServiceFee>				<TotalPerRoomBreakfastFee>35673</TotalPerRoomBreakfastFee>				<TotalPerRoomOtherFee>12343</TotalPerRoomOtherFee>				<TotalPerRoomCommissionAmount>56783</TotalPerRoomCommissionAmount>				<TotalPerRoomCommissionConsumptionTax>3563</TotalPerRoomCommissionConsumptionTax>				<RoomRateDetailInformation>					<RateCategory>1</RateCategory>					<RoomRate>55890</RoomRate>					<RatePaxCount>55</RatePaxCount>					<RateDetailInformation>RateDetailInformation-31</RateDetailInformation>				</RoomRateDetailInformation>				<RoomRateDetailInformation>					<RateCategory>2</RateCategory>					<RoomRate>68760</RoomRate>					<RatePaxCount>66</RatePaxCount>					<RateDetailInformation>RateDetailInformation-32</RateDetailInformation>				</RoomRateDetailInformation>            </RoomRateInformation>            <GuestInformation>            	<GuestInformationList>					<GuestNameSingleByte>GuestNameSingleByte-1</GuestNameSingleByte>					<GuestSurName>GuestSurName-1</GuestSurName>					<GuestGivenName>GuestGivenName-1</GuestGivenName>					<GuestMiddleName>GuestMiddleName-1</GuestMiddleName>					<GuestNamePrefix>GuestNamePrefix-1</GuestNamePrefix>					<GuestKanjiName>GuestKanjiName-1</GuestKanjiName>					<GuestGender>GuestGender-1</GuestGender>					<GuestAge>100</GuestAge>					<GuestDateOfBirth>1912-12-31</GuestDateOfBirth>					<GuestType>GuestType-1</GuestType>					<GuestShubetsu>GuestShubetsu-1</GuestShubetsu>					<GuestPhoneNumber>GuestPhoneNumber-1</GuestPhoneNumber>					<GuestEmergencyPhoneNumber>GuestEmergencyPhoneNumber-1</GuestEmergencyPhoneNumber>					<GuestEmail>GuestEmail-1</GuestEmail>					<GuestCountry>GuestCountry-1</GuestCountry>					<GuestStateProvidence>GuestStateProvidence-1</GuestStateProvidence>					<GuestCityName>GuestCityName-1</GuestCityName>					<GuestAddressLine>GuestAddressLine-1</GuestAddressLine>					<GuestStreetNumber>GuestStreetNumber-1</GuestStreetNumber>					<GuestPostalCode>GuestPostalCode-1</GuestPostalCode>					<GuestBuildingName>GuestBuildingName-1</GuestBuildingName>					<GuestFFPCarrier>GuestFFPCarrier-1</GuestFFPCarrier>					<GuestFFPNumber>GuestFFPNumber-1</GuestFFPNumber>					<GuestCoachNumber>GuestCoachNumber-1</GuestCoachNumber>					<SpecialInformation>SpecialInformation-11</SpecialInformation>					<SpecialInformation>SpecialInformation-12</SpecialInformation>					<SpecialInformation>SpecialInformation-13</SpecialInformation>            	</GuestInformationList>            	<GuestInformationList>					<GuestNameSingleByte>GuestNameSingleByte-2</GuestNameSingleByte>					<GuestSurName>GuestSurName-2</GuestSurName>					<GuestGivenName>GuestGivenName-2</GuestGivenName>					<GuestMiddleName>GuestMiddleName-2</GuestMiddleName>					<GuestNamePrefix>GuestNamePrefix-2</GuestNamePrefix>					<GuestKanjiName>GuestKanjiName-2</GuestKanjiName>					<GuestGender>GuestGender-2</GuestGender>					<GuestAge>0</GuestAge>					<GuestDateOfBirth>2012-10-10</GuestDateOfBirth>					<GuestType>GuestType-2</GuestType>					<GuestShubetsu>GuestShubetsu-2</GuestShubetsu>					<GuestPhoneNumber>GuestPhoneNumber-2</GuestPhoneNumber>					<GuestEmergencyPhoneNumber>GuestEmergencyPhoneNumber-2</GuestEmergencyPhoneNumber>					<GuestEmail>GuestEmail-2</GuestEmail>					<GuestCountry>GuestCountry-2</GuestCountry>					<GuestStateProvidence>GuestStateProvidence-2</GuestStateProvidence>					<GuestCityName>GuestCityName-2</GuestCityName>					<GuestAddressLine>GuestAddressLine-2</GuestAddressLine>					<GuestStreetNumber>GuestStreetNumber-2</GuestStreetNumber>					<GuestPostalCode>GuestPostalCode-2</GuestPostalCode>					<GuestBuildingName>GuestBuildingName-2</GuestBuildingName>					<GuestFFPCarrier>GuestFFPCarrier-2</GuestFFPCarrier>					<GuestFFPNumber>GuestFFPNumber-2</GuestFFPNumber>					<GuestCoachNumber>GuestCoachNumber-2</GuestCoachNumber>					<SpecialInformation>SpecialInformation-21</SpecialInformation>					<SpecialInformation>SpecialInformation-22</SpecialInformation>					<SpecialInformation>SpecialInformation-23</SpecialInformation>            	</GuestInformationList>            </GuestInformation>        </RoomAndGuestList>    </RoomAndGuestInformation>    <RisaplsInformation>        <RisaplsCommonInformation>            <Basic>                <SalesOfficeCompanyCode>80</SalesOfficeCompanyCode>                <TelegramDiv></TelegramDiv>                <RisaplsDataID></RisaplsDataID>                <RisaplsTelegramNumber></RisaplsTelegramNumber>                <TelegramData>予約通知 一休.com                                      SNT-NET 08-16 20:56 (80) 予約番号： IK0144977541  NO.00000003 松本丸の内ホテル様(00001782)宿泊者情報：  野村 豊幸  TEL:0423241785  ﾉﾑﾗ ｶｽﾞﾕｷ  住所:(〒185-0023)東京都 国分寺市 西元町　2-11-7  性別:男        年代:40代        年齢:予約者情報：  野村 豊幸  のむら かずゆき  住所:(〒185-0023)東京都 国分寺市 西元町　2-11-7  性別:男                     生年月日:  会員種別:会員               メルマガ希望:プラン名：ビジネス応援「ゆったりデラックス」素泊まり(bien14)2013年08月18日から    1泊  ＲＣ  サ込税込入込方法：                   チェックイン時間：15:00人員総数：   1人  内訳：(男)1名客室総数：   1室08月18日  dsn  (デラックスシングル（禁煙）(シングル))  @8,000          大人（男）     1名                                   宿泊料金計                ：     \\8,000                       合計料金                              ：     \\8,000                     【宿泊者への請求額】                    ：     \\8,000           ---------------------------------------------------------------------支払い方法  ：現払いご確認事項：食事なし禁煙ルームをお願いします質問1:駐車場ご利用の場合はAとお車の台数を、ご利用のない場合はBとご記入ください。回答1:B取扱個所：株式会社一休(001)  TEL 03-6685-0065  FAX 03-6234-8921会員番号：01006096---</TelegramData>                <PhoneNumber>0423241785</PhoneNumber>                <PostalCode>185-0023</PostalCode>                <Address>東京都 国分寺市 西元町　2-11-7</Address>                <TotalPaxManCount>1</TotalPaxManCount>                <BranchFaxNumber>03-6234-8921</BranchFaxNumber>                <Version>2.0</Version>                <RepresentativePhoneType>2</RepresentativePhoneType>                <RepresentativeGeneration>40代</RepresentativeGeneration>                <RepresentativeGendar>0</RepresentativeGendar>                <AccommodationId>G66249</AccommodationId>            </Basic>            <Allotment>                <AssignDiv>1</AssignDiv>                <GenderDiv>0</GenderDiv>                <HandleDiv>1</HandleDiv>                <RsvUserDiv>1</RsvUserDiv>                <UseDiv>1</UseDiv>            </Allotment>            <RoomAndRoomRateInformation>                <RoomInformation>                    <RoomTypeCode>20</RoomTypeCode>                    <RoomTypeName>デラックスシングル（禁煙）(シングル)</RoomTypeName>                    <PerRoomPaxCount>1</PerRoomPaxCount>                    <RoomPaxMaleCount>1</RoomPaxMaleCount>                    <RoomPaxFemaleCount>0</RoomPaxFemaleCount>                    <RoomChildA70Count>0</RoomChildA70Count>                    <RoomChildB50Count>0</RoomChildB50Count>                    <RoomChildC30Count>0</RoomChildC30Count>                    <RoomChildDNoneCount>0</RoomChildDNoneCount>                    <RoomTypeAgent>80</RoomTypeAgent>                    <RoomFrame>--</RoomFrame>                    <NetRmTypeGroupCode>4</NetRmTypeGroupCode>                    <PlanGroupCode>18</PlanGroupCode>                </RoomInformation>                <RoomRateInformation>                    <RoomDate>2013-08-18</RoomDate>                    <PerPaxRate>8000</PerPaxRate>                    <PerChildA70Rate>0</PerChildA70Rate>                    <PerChildB50Rate>0</PerChildB50Rate>                    <PerChildC30Rate>0</PerChildC30Rate>                    <PerChildDRate>0</PerChildDRate>                    <TotalPerRoomRate>8000</TotalPerRoomRate>                    <PerMaleRate>8000</PerMaleRate>                    <RoomRatePaxMaleCount>1</RoomRatePaxMaleCount>                    <RoomRatePaxFemaleCount>0</RoomRatePaxFemaleCount>                    <RoomRateChildA70Count>0</RoomRateChildA70Count>                    <RoomRateChildB50Count>0</RoomRateChildB50Count>                    <RoomRateChildC30Count>0</RoomRateChildC30Count>                    <RoomRateChildDNoneCount>0</RoomRateChildDNoneCount>                     <TotalRoomHotSpringTax>100</TotalRoomHotSpringTax>                    <TotalPerRoomServiceFee>500</TotalPerRoomServiceFee>                </RoomRateInformation>                <GuestInformation>            	<GuestInformationList>					<GuestNameSingleByte>GuestNameSingleByte-1</GuestNameSingleByte>					<GuestSurName>GuestSurName-1</GuestSurName>					<GuestGivenName>GuestGivenName-1</GuestGivenName>					<GuestMiddleName>GuestMiddleName-1</GuestMiddleName>					<GuestNamePrefix>GuestNamePrefix-1</GuestNamePrefix>					<GuestKanjiName>GuestKanjiName-1</GuestKanjiName>					<GuestGender>GuestGender-1</GuestGender>					<GuestAge>100</GuestAge>					<GuestDateOfBirth>1912-12-31</GuestDateOfBirth>					<GuestType>GuestType-1</GuestType>					<GuestShubetsu>GuestShubetsu-1</GuestShubetsu>					<GuestPhoneNumber>GuestPhoneNumber-1</GuestPhoneNumber>					<GuestEmergencyPhoneNumber>GuestEmergencyPhoneNumber-1</GuestEmergencyPhoneNumber>					<GuestEmail>GuestEmail-1</GuestEmail>					<GuestCountry>GuestCountry-1</GuestCountry>					<GuestStateProvidence>GuestStateProvidence-1</GuestStateProvidence>					<GuestCityName>GuestCityName-1</GuestCityName>					<GuestAddressLine>GuestAddressLine-1</GuestAddressLine>					<GuestStreetNumber>GuestStreetNumber-1</GuestStreetNumber>					<GuestPostalCode>GuestPostalCode-1</GuestPostalCode>					<GuestBuildingName>GuestBuildingName-1</GuestBuildingName>					<GuestFFPCarrier>GuestFFPCarrier-1</GuestFFPCarrier>					<GuestFFPNumber>GuestFFPNumber-1</GuestFFPNumber>					<GuestCoachNumber>GuestCoachNumber-1</GuestCoachNumber>					<SpecialInformation>SpecialInformation-11</SpecialInformation>					<SpecialInformation>SpecialInformation-12</SpecialInformation>					<SpecialInformation>SpecialInformation-13</SpecialInformation>            	</GuestInformationList>            	<GuestInformationList>					<GuestNameSingleByte>GuestNameSingleByte-2</GuestNameSingleByte>					<GuestSurName>GuestSurName-2</GuestSurName>					<GuestGivenName>GuestGivenName-2</GuestGivenName>					<GuestMiddleName>GuestMiddleName-2</GuestMiddleName>					<GuestNamePrefix>GuestNamePrefix-2</GuestNamePrefix>					<GuestKanjiName>GuestKanjiName-2</GuestKanjiName>					<GuestGender>GuestGender-2</GuestGender>					<GuestAge>0</GuestAge>					<GuestDateOfBirth>2012-10-10</GuestDateOfBirth>					<GuestType>GuestType-2</GuestType>					<GuestShubetsu>GuestShubetsu-2</GuestShubetsu>					<GuestPhoneNumber>GuestPhoneNumber-2</GuestPhoneNumber>					<GuestEmergencyPhoneNumber>GuestEmergencyPhoneNumber-2</GuestEmergencyPhoneNumber>					<GuestEmail>GuestEmail-2</GuestEmail>					<GuestCountry>GuestCountry-2</GuestCountry>					<GuestStateProvidence>GuestStateProvidence-2</GuestStateProvidence>					<GuestCityName>GuestCityName-2</GuestCityName>					<GuestAddressLine>GuestAddressLine-2</GuestAddressLine>					<GuestStreetNumber>GuestStreetNumber-2</GuestStreetNumber>					<GuestPostalCode>GuestPostalCode-2</GuestPostalCode>					<GuestBuildingName>GuestBuildingName-2</GuestBuildingName>					<GuestFFPCarrier>GuestFFPCarrier-2</GuestFFPCarrier>					<GuestFFPNumber>GuestFFPNumber-2</GuestFFPNumber>					<GuestCoachNumber>GuestCoachNumber-2</GuestCoachNumber>					<SpecialInformation>SpecialInformation-21</SpecialInformation>					<SpecialInformation>SpecialInformation-22</SpecialInformation>					<SpecialInformation>SpecialInformation-23</SpecialInformation>            	</GuestInformationList>            </GuestInformation>            </RoomAndRoomRateInformation>	<Member>		<UserName>UserName-1</UserName>		<UserKana>UserKana-1</UserKana>		<UserTel>UserTel-1</UserTel>		<UserMailAddr>UserMailAddr-1</UserMailAddr>		<UserZip>UserZip-1</UserZip>		<UserAddr>UserAddr-1</UserAddr>		<UserCorp>UserCorp-1</UserCorp>		<UserDep>UserDep-1</UserDep>		<UserID>UserID-1</UserID>		<VIPCode>VIPCode-1</VIPCode>		<PointCompanyName>PointCompanyName-1</PointCompanyName>		<PointName>PointName-1</PointName>		<UserGivinPoints>100000</UserGivinPoints>		<UserUsePoints>5432</UserUsePoints>		<TotalAccommodationDecleasePoints>11111</TotalAccommodationDecleasePoints>		<TotalAccommodationConsumptaionTax>2222</TotalAccommodationConsumptaionTax>		<AmountClaimed>123456</AmountClaimed>		<ChargeEquation>ChargeEquation-1</ChargeEquation>		<UserUsePointList>			<PointName>PointName-1</PointName>			<UserUsePoint>10000</UserUsePoint>		</UserUsePointList>		<UserUsePointList>			<PointName>PointName-2</PointName>			<UserUsePoint>20000</UserUsePoint>		</UserUsePointList>	</Member>	<OtherInfo>                <GuestRequest>食事なし禁煙ルームをお願いします</GuestRequest>                <AdditionalInformation>質問1:駐車場ご利用の場合はAとお車の台数を、ご利用のない場合はBとご記入ください。回答1:B</AdditionalInformation>				<QuestionAndAnswerList>					<QuestionToGuest>QuestionToGuest-1</QuestionToGuest>					<AnswerToHotel>AnswerToHotel-1</AnswerToHotel>				</QuestionAndAnswerList>				<QuestionAndAnswerList>					<QuestionToGuest>QuestionToGuest-2</QuestionToGuest>					<AnswerToHotel>AnswerToHotel-2</AnswerToHotel>				</QuestionAndAnswerList>            </OtherInfo>            <BlockReport>				<RoomTypeCode>1A</RoomTypeCode>				<InquiryDate>20120825</InquiryDate>				<TotalRoomsBlock>10</TotalRoomsBlock>				<TotalRoomsNotYetSold>101</TotalRoomsNotYetSold>			</BlockReport>			<BlockReport>				<RoomTypeCode>1A</RoomTypeCode>				<InquiryDate>20120826</InquiryDate>				<TotalRoomsBlock>10</TotalRoomsBlock>				<TotalRoomsNotYetSold>102</TotalRoomsNotYetSold>			</BlockReport>            <BasicRate>				<TotalAccomodationServiceCharge>12345678</TotalAccomodationServiceCharge>				<PointsDiscountList>					<PointsDiv>1</PointsDiv>					<PointsDiscountName>PointsDiscountName-1</PointsDiscountName>					<PointsDiscount>10000</PointsDiscount>				</PointsDiscountList>				<PointsDiscountList>					<PointsDiv>2</PointsDiv>					<PointsDiscountName>PointsDiscountName-2</PointsDiscountName>					<PointsDiscount>20000</PointsDiscount>				</PointsDiscountList>				<DepositList>					<DepositAmount>12345</DepositAmount>				</DepositList>				<DepositList>					<DepositAmount>23456</DepositAmount>				</DepositList>			</BasicRate>        </RisaplsCommonInformation>        <AgentNativeInformation>            <Extend>                <TotalAccommodationDecleasePoints>8000</TotalAccommodationDecleasePoints>                <AmountClaimed>8000</AmountClaimed>            </Extend>            <Extendmytrip>                <SettlementDiv>0</SettlementDiv>            </Extendmytrip>        </AgentNativeInformation>    </RisaplsInformation></AllotmentBookingReport>';	
    	String dateKey = System.now().format('yyMMddHHMMssSSS');
    	Attachment newAttach = new Attachment(
									ParentId = parentId,
									Name = 'TAPDATA_' + dateKey + '1_Test.xml', 
									ContentType = 'text/xml',
									Body = Blob.valueOf(infoTravelXML)
								);
		insert newAttach;
    }
    private static void createDocumentNoData(String parentId){
    	String infoTravelXML = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><AllotmentBookingReport>    <TransactionType>        <DataFrom>Rakujan</DataFrom>        <DataClassification>NewBookReport</DataClassification>        <DataID></DataID><BookingDataID></BookingDataID><SystemDate>2012-09-02</SystemDate>        <SystemTime>11:43:00</SystemTime>    </TransactionType>    <ResultInformation>    	<ResultCode>0</ResultCode>    	<DetailedInformation>    		<ErrorCode>ErrorCode=0</ErrorCode>   		    		<ErrorText>ErrorText=空白</ErrorText>   		    	</DetailedInformation>    </ResultInformation>    <AccommodationInformation>		<AccommodationArea>AccommodationArea-1</AccommodationArea>		<AccommodationName>AccommodationName-1</AccommodationName>		<AccommodationCode>AccommodationCode-1</AccommodationCode>		<ChainName>ChainName-1</ChainName>		<AccommodationPersonInCharge>AccommodationPersonInCharge-1</AccommodationPersonInCharge>		<AccommodationEmail>AccommodationEmail-1</AccommodationEmail>		<AccommodationPhoneNumber>AccommodationPhoneNumber-1</AccommodationPhoneNumber>        <AccommodationCPUAddress>AccommodationCPUAddress-1</AccommodationCPUAddress>        <BankList>			<BankName>BankName-1</BankName>			<BankAccountNumber>BankAccountNumber-1</BankAccountNumber>			<BankBranchName>BankBranchName-1</BankBranchName>			<BankAccountClassification>BankAccountClassification-1</BankAccountClassification>			<BankAccountName>BankAccountName-1</BankAccountName>        </BankList>        <BankList>			<BankName>BankName-2</BankName>			<BankAccountNumber>BankAccountNumber-2</BankAccountNumber>			<BankBranchName>BankBranchName-2</BankBranchName>			<BankAccountClassification>BankAccountClassification-2</BankAccountClassification>			<BankAccountName>BankAccountName-2</BankAccountName>        </BankList>    </AccommodationInformation>    <SalesOfficeInformation>		<SalesOfficeCompanyCode>01</SalesOfficeCompanyCode>		<SalesOfficeCompanyName>SalesOfficeCompanyName-1</SalesOfficeCompanyName>		<SalesOfficeName>SalesOfficeName-1</SalesOfficeName>		<SalesOfficeCode>SalesOfficeCode-1</SalesOfficeCode>		<SalesOfficePersonInCharge>SalesOfficePersonInCharge-1</SalesOfficePersonInCharge>		<SalesOfficeEmail>SalesOfficeEmail-1</SalesOfficeEmail>		<SalesOfficePhoneNumber>SalesOfficePhoneNumber-1</SalesOfficePhoneNumber>		<SalesOfficeStateProvidence>SalesOfficeStateProvidence-1</SalesOfficeStateProvidence>		<SalesOfficeCityName>SalesOfficeCityName-1</SalesOfficeCityName>		<SalesOfficeAddressLine>SalesOfficeAddressLine-1</SalesOfficeAddressLine>		<SalesOfficeStreetNumber>SalesOfficeStreetNumber-1</SalesOfficeStreetNumber>		<SalesOfficePostalCode>SalesOfficePostalCode-1</SalesOfficePostalCode>		<SalesOfficeRegisteredCategory>SalesOfficeRegisteredCategory-1</SalesOfficeRegisteredCategory>		<SalesOfficeLicenseNumber>SalesOfficeLicenseNumber-1</SalesOfficeLicenseNumber>		<SalesOfficeRegisteredPrefecture>SalesOfficeRegisteredPrefecture-1</SalesOfficeRegisteredPrefecture>		<SalesOfficeCPUAddress>SalesOfficeCPUAddress-1</SalesOfficeCPUAddress>		<RetailerCompanyName>RetailerCompanyName-1</RetailerCompanyName>		<RetailerOfficeName>RetailerOfficeName-1</RetailerOfficeName>		<RetailerOfficeCode>RetailerOfficeCode-1</RetailerOfficeCode>		<RetailerPersonInCharge>RetailerPersonInCharge-1</RetailerPersonInCharge>		<RetailerEmail>RetailerEmail-1</RetailerEmail>		<RetailerPhoneNumber>RetailerPhoneNumber-1</RetailerPhoneNumber>		<RetailerStateProvidence>RetailerStateProvidence-1</RetailerStateProvidence>		<RetailerCityName>RetailerCityName-1</RetailerCityName>		<RetailerAddressLine>RetailerAddressLine-1</RetailerAddressLine>		<RetailerStreetNumber>RetailerStreetNumber-1</RetailerStreetNumber>		<RetailerPostalCode>RetailerPostalCode-1</RetailerPostalCode>		<RetailerRegisteredCategory>RetailerRegisteredCategory-1</RetailerRegisteredCategory>		<RetailerLicenseNumber>RetailerLicenseNumber-1</RetailerLicenseNumber>		<RetailerRegisteredPrefecture>RetailerRegisteredPrefecture-1</RetailerRegisteredPrefecture>    </SalesOfficeInformation>    <BasicInformation>		<TravelAgencyBookingNumber>TravelAgencyBookingNumber-1</TravelAgencyBookingNumber>		<TravelAgencyBookingDate>2012-08-26</TravelAgencyBookingDate>		<TravelAgencyBookingTime>00:00:00</TravelAgencyBookingTime>		<TravelAgencyReportNumber>TravelAgencyReportNumber-1</TravelAgencyReportNumber>		<AccommodationConfirmationNumber>AccommodationConfirmationNumber-1</AccommodationConfirmationNumber>		<GuestOrGroupNameSingleByte>GuestOrGroupNameSingleByte-1</GuestOrGroupNameSingleByte>		<GuestOrGroupNameDoubleByte>GuestOrGroupNameDoubleByte-1</GuestOrGroupNameDoubleByte>		<GuestOrGroupNameKanjiName>3日泊まりお客様</GuestOrGroupNameKanjiName>		<GroupNameWelcomeBoard>GroupNameWelcomeBoard-1</GroupNameWelcomeBoard>		<CheckInDate>2012-09-01</CheckInDate>		<CheckInTime>13:00:00</CheckInTime>		<CheckOutDate>2012-09-04</CheckOutDate>		<CheckOutTime>11:00:00</CheckOutTime>		<Nights>3</Nights>		<Transportaion>Transportaion-1</Transportaion>		<CoachCount>10</CoachCount>		<CoachCompany>CoachCompany-1</CoachCompany>		<TotalRoomCount>1</TotalRoomCount>		<GrandTotalPaxCount>20</GrandTotalPaxCount>		<TotalPaxMaleCount>2</TotalPaxMaleCount>		<TotalPaxFemaleCount>2</TotalPaxFemaleCount>		<TotalChildA70Count>2</TotalChildA70Count>		<TotalChildB50Count>2</TotalChildB50Count>		<TotalChildC30Count>2</TotalChildC30Count>		<TotalChildDNoneCount>2</TotalChildDNoneCount>		<TotalChildECount>2</TotalChildECount>		<TotalChildFCount>2</TotalChildFCount>		<TotalChildOtherCount>2</TotalChildOtherCount>		<TotalTourConductorCount>2</TotalTourConductorCount>		<TotalCoachDriverCount>2</TotalCoachDriverCount>		<TotalGuideCount>2</TotalGuideCount>		<TypeOfGroup>TypeOfGroup-1</TypeOfGroup>		<Status>Status-1</Status>		<PackageType>PackageType-2</PackageType>		<PackagePlanName>PackagePlanName-2</PackagePlanName>		<PackagePlanCode>PackagePlanCode-2</PackagePlanCode>		<PackagePlanContent>PackagePlanContent-2</PackagePlanContent>		<Option>			<OptionDate>2001-01-01</OptionDate>			<Name>Option_Name</Name>			<NameRequest>Option_NameRequest</NameRequest>			<OptionCount>11</OptionCount>			<OptionRate>111</OptionRate>	<OptionCode>111</OptionCode>	</Option>		<Option>			<OptionDate>2001-01-02</OptionDate>			<Name>Option_Name2</Name>			<NameRequest>Option_NameRequest2</NameRequest>			<OptionCount>22</OptionCount>			<OptionRate>222</OptionRate>		</Option>		<MealCondition>1night2meals</MealCondition>		<SpecificMealCondition>SpecificMealCondition-1</SpecificMealCondition>		<MealPlace>MealPlace-1</MealPlace>		<BanquetRoom>BanquetRoom-1</BanquetRoom>		<ModificationType>ModificationType-1</ModificationType>		<ModificationPoint>ModificationPoint-3</ModificationPoint>		<CancellationNumber>CancellationNumber-1</CancellationNumber>		<PreviousPlace>PreviousPlace-1</PreviousPlace>		<PreviousAccommodationName>PreviousAccommodationName-1</PreviousAccommodationName>		<PreviousAccommodationName>PreviousAccommodationName-2</PreviousAccommodationName>		<PreviousAccommodationName>PreviousAccommodationName-3</PreviousAccommodationName>		<SpecialServiceRequest>SpecialServiceRequest-1</SpecialServiceRequest>		<SpecialServiceRequest>SpecialServiceRequest-2</SpecialServiceRequest>		<SpecialServiceRequest>SpecialServiceRequest-3</SpecialServiceRequest>		<OtherServiceInformation>OtherServiceInformation-1</OtherServiceInformation>		<FollowUpInformation>FollowUpInformation-1</FollowUpInformation>    </BasicInformation>    <BasicRateInformation>		<RoomRateOrPersonalRate>PersonalRate</RoomRateOrPersonalRate>		<TaxServiceFee>IncludingServiceWithOutTax</TaxServiceFee>		<Payment>Payment-1</Payment>		<BareNetRate>1000</BareNetRate>		<CancellationCharge>2000</CancellationCharge>		<CreditCardAuthority>CreditCardAuthority-1</CreditCardAuthority>		<CreditCardNumber>CreditCardNumber-1</CreditCardNumber>		<ExpireDate>2020-01-01</ExpireDate>		<CardHolderName>CardHolderName-1</CardHolderName>		<TotalAccommodationCharge>100000</TotalAccommodationCharge>		<TotalAccommodationConsumptionTax>5000</TotalAccommodationConsumptionTax>		<TotalAccommodationHotSpringTax>2000</TotalAccommodationHotSpringTax>		<TotalAccommodationHotelTax>30000</TotalAccommodationHotelTax>		<TotalAccommodationServiceFee>3000</TotalAccommodationServiceFee>		<TotalAccommodationBreakfastFee>50000</TotalAccommodationBreakfastFee>		<TotalAccommodationOtherFee>100000</TotalAccommodationOtherFee>		<CommissionPercentage>0.5</CommissionPercentage>		<TotalAccommodationCommissionAmount>234567</TotalAccommodationCommissionAmount>		<TotalAccommodationCommissionConsumptionTax>5555</TotalAccommodationCommissionConsumptionTax>		<TotalAccommodationChargeAfterCheckIn>123451</TotalAccommodationChargeAfterCheckIn>		<TotalBalanceAfterCheckIn>23456</TotalBalanceAfterCheckIn>		<TotalAccommodationConsumptionAfterCheckIn>9876</TotalAccommodationConsumptionAfterCheckIn>		<CancellationChargeAfterCheckIn>321987</CancellationChargeAfterCheckIn>		<MembershipFee>335577</MembershipFee>		<AdjustmentFee>112233</AdjustmentFee>        <CouponList>			<CouponAmount>1</CouponAmount>			<CouponType>CouponType-1</CouponType>			<CouponNumber>CouponNumber-1</CouponNumber>			<CouponIssueDate>CouponIssueDate-1</CouponIssueDate>        </CouponList>        <CouponList>			<CouponAmount>2</CouponAmount>			<CouponType>CouponType-2</CouponType>			<CouponNumber>CouponNumber-2</CouponNumber>			<CouponIssueDate>CouponIssueDate-2</CouponIssueDate>        </CouponList>    </BasicRateInformation>    <RoomAndGuestInformation>        <RoomAndGuestList>            <RoomInformation>				<RoomTypeCode>R004</RoomTypeCode>				<RoomTypeName>ベッドルーム付き和洋室</RoomTypeName>				<RoomCategory>RoomCategory-1</RoomCategory>				<ViewType>ViewType-1</ViewType>				<SmokingOrNonSmoking>SmokingOrNonSmoking-1</SmokingOrNonSmoking>				<RoomPaxMaleCount>2</RoomPaxMaleCount>				<RoomPaxFemaleCount>2</RoomPaxFemaleCount>				<RoomChildA70Count>2</RoomChildA70Count>				<RoomChildB50Count>2</RoomChildB50Count>				<RoomChildC30Count>2</RoomChildC30Count>				<RoomChildDNoneCount>2</RoomChildDNoneCount>				<RoomChildECount>2</RoomChildECount>				<RoomChildFCount>2</RoomChildFCount>				<RoomChildOtherCount>2</RoomChildOtherCount>				<RoomByRoomStatus>RoomByRoomStatus-1</RoomByRoomStatus>				<RoomByRoomConfirmationNumber>RoomByRoomConfirmationNumber-1</RoomByRoomConfirmationNumber>				<Facilities>Facilities-1</Facilities>				<Facilities>Facilities-2</Facilities>				<Facilities>Facilities-3</Facilities>				<AssignedRoomNumber>AssignedRoomNumber-1</AssignedRoomNumber>				<RoomSpecialRequest>RoomSpecialRequest-1</RoomSpecialRequest>				<RoomSpecialRequest>RoomSpecialRequest-2</RoomSpecialRequest>				<RoomSpecialRequest>RoomSpecialRequest-3</RoomSpecialRequest>				<RoomTypeAgent>RoomTypeAgent-1</RoomTypeAgent>				<RoomTypeAgent>RoomTypeAgent-2</RoomTypeAgent>				<RoomTypeAgent>RoomTypeAgent-3</RoomTypeAgent>            </RoomInformation>            <RoomRateInformation>				<RoomDate>2012-09-01</RoomDate>				<PerPaxRate>35000</PerPaxRate>				<PerChildA70Rate>12000</PerChildA70Rate>				<PerChildB50Rate>10000</PerChildB50Rate>				<PerChildC30Rate>8000</PerChildC30Rate>				<PerChildDRate>7000</PerChildDRate>				<PerChildERate>7010</PerChildERate>				<PerChildFRate>7060</PerChildFRate>				<PerChildOtherRate>6000</PerChildOtherRate>				<TotalPerRoomRate>70000</TotalPerRoomRate>				<TotalPerRoomConsumptionTax>3500</TotalPerRoomConsumptionTax>				<TotalRoomHotSpringTax>2500</TotalRoomHotSpringTax>				<TotalPerRoomHotelTax>2000</TotalPerRoomHotelTax>				<TotalPerRoomServiceFee>15000</TotalPerRoomServiceFee>				<TotalPerRoomBreakfastFee>35678</TotalPerRoomBreakfastFee>				<TotalPerRoomOtherFee>12345</TotalPerRoomOtherFee>				<TotalPerRoomCommissionAmount>56789</TotalPerRoomCommissionAmount>				<TotalPerRoomCommissionConsumptionTax>3567</TotalPerRoomCommissionConsumptionTax>				<RoomRateDetailInformation>					<RateCategory>1</RateCategory>					<RoomRate>15890</RoomRate>					<RatePaxCount>11</RatePaxCount>					<RateDetailInformation>RateDetailInformation-11</RateDetailInformation>				</RoomRateDetailInformation>				<RoomRateDetailInformation>					<RateCategory>2</RateCategory>					<RoomRate>28760</RoomRate>					<RatePaxCount>22</RatePaxCount>					<RateDetailInformation>RateDetailInformation-12</RateDetailInformation>				</RoomRateDetailInformation>            </RoomRateInformation>            <RoomRateInformation>				<RoomDate>2012-09-02</RoomDate>				<PerPaxRate>35002</PerPaxRate>				<PerChildA70Rate>12002</PerChildA70Rate>				<PerChildB50Rate>10002</PerChildB50Rate>				<PerChildC30Rate>8002</PerChildC30Rate>				<PerChildDRate>7002</PerChildDRate>				<PerChildERate>7022</PerChildERate>				<PerChildFRate>7082</PerChildFRate>				<PerChildOtherRate>6002</PerChildOtherRate>				<TotalPerRoomRate>70002</TotalPerRoomRate>				<TotalPerRoomConsumptionTax>3502</TotalPerRoomConsumptionTax>				<TotalRoomHotSpringTax>2502</TotalRoomHotSpringTax>				<TotalPerRoomHotelTax>2002</TotalPerRoomHotelTax>				<TotalPerRoomServiceFee>15002</TotalPerRoomServiceFee>				<TotalPerRoomBreakfastFee>35672</TotalPerRoomBreakfastFee>				<TotalPerRoomOtherFee>12342</TotalPerRoomOtherFee>				<TotalPerRoomCommissionAmount>56782</TotalPerRoomCommissionAmount>				<TotalPerRoomCommissionConsumptionTax>3562</TotalPerRoomCommissionConsumptionTax>				<RoomRateDetailInformation>					<RateCategory>1</RateCategory>					<RoomRate>35890</RoomRate>					<RatePaxCount>33</RatePaxCount>					<RateDetailInformation>RateDetailInformation-21</RateDetailInformation>				</RoomRateDetailInformation>				<RoomRateDetailInformation>					<RateCategory>2</RateCategory>					<RoomRate>48760</RoomRate>					<RatePaxCount>44</RatePaxCount>					<RateDetailInformation>RateDetailInformation-22</RateDetailInformation>				</RoomRateDetailInformation>            </RoomRateInformation>            <RoomRateInformation>				<RoomDate>2012-09-03</RoomDate>				<PerPaxRate>35003</PerPaxRate>				<PerChildA70Rate>12003</PerChildA70Rate>				<PerChildB50Rate>10003</PerChildB50Rate>				<PerChildC30Rate>8003</PerChildC30Rate>				<PerChildDRate>7003</PerChildDRate>				<PerChildERate>7033</PerChildERate>				<PerChildFRate>7093</PerChildFRate>				<PerChildOtherRate>6003</PerChildOtherRate>				<TotalPerRoomRate>70003</TotalPerRoomRate>				<TotalPerRoomConsumptionTax>3503</TotalPerRoomConsumptionTax>				<TotalRoomHotSpringTax>2503</TotalRoomHotSpringTax>				<TotalPerRoomHotelTax>2003</TotalPerRoomHotelTax>				<TotalPerRoomServiceFee>15003</TotalPerRoomServiceFee>				<TotalPerRoomBreakfastFee>35673</TotalPerRoomBreakfastFee>				<TotalPerRoomOtherFee>12343</TotalPerRoomOtherFee>				<TotalPerRoomCommissionAmount>56783</TotalPerRoomCommissionAmount>				<TotalPerRoomCommissionConsumptionTax>3563</TotalPerRoomCommissionConsumptionTax>				<RoomRateDetailInformation>					<RateCategory>1</RateCategory>					<RoomRate>55890</RoomRate>					<RatePaxCount>55</RatePaxCount>					<RateDetailInformation>RateDetailInformation-31</RateDetailInformation>				</RoomRateDetailInformation>				<RoomRateDetailInformation>					<RateCategory>2</RateCategory>					<RoomRate>68760</RoomRate>					<RatePaxCount>66</RatePaxCount>					<RateDetailInformation>RateDetailInformation-32</RateDetailInformation>				</RoomRateDetailInformation>            </RoomRateInformation>            <GuestInformation>            	<GuestInformationList>					<GuestNameSingleByte>GuestNameSingleByte-1</GuestNameSingleByte>					<GuestSurName>GuestSurName-1</GuestSurName>					<GuestGivenName>GuestGivenName-1</GuestGivenName>					<GuestMiddleName>GuestMiddleName-1</GuestMiddleName>					<GuestNamePrefix>GuestNamePrefix-1</GuestNamePrefix>					<GuestKanjiName>GuestKanjiName-1</GuestKanjiName>					<GuestGender>GuestGender-1</GuestGender>					<GuestAge>100</GuestAge>					<GuestDateOfBirth>1912-12-31</GuestDateOfBirth>					<GuestType>GuestType-1</GuestType>					<GuestShubetsu>GuestShubetsu-1</GuestShubetsu>					<GuestPhoneNumber>GuestPhoneNumber-1</GuestPhoneNumber>					<GuestEmergencyPhoneNumber>GuestEmergencyPhoneNumber-1</GuestEmergencyPhoneNumber>					<GuestEmail>GuestEmail-1</GuestEmail>					<GuestCountry>GuestCountry-1</GuestCountry>					<GuestStateProvidence>GuestStateProvidence-1</GuestStateProvidence>					<GuestCityName>GuestCityName-1</GuestCityName>					<GuestAddressLine>GuestAddressLine-1</GuestAddressLine>					<GuestStreetNumber>GuestStreetNumber-1</GuestStreetNumber>					<GuestPostalCode>GuestPostalCode-1</GuestPostalCode>					<GuestBuildingName>GuestBuildingName-1</GuestBuildingName>					<GuestFFPCarrier>GuestFFPCarrier-1</GuestFFPCarrier>					<GuestFFPNumber>GuestFFPNumber-1</GuestFFPNumber>					<GuestCoachNumber>GuestCoachNumber-1</GuestCoachNumber>					<SpecialInformation>SpecialInformation-11</SpecialInformation>					<SpecialInformation>SpecialInformation-12</SpecialInformation>					<SpecialInformation>SpecialInformation-13</SpecialInformation>            	</GuestInformationList>            	<GuestInformationList>					<GuestNameSingleByte>GuestNameSingleByte-2</GuestNameSingleByte>					<GuestSurName>GuestSurName-2</GuestSurName>					<GuestGivenName>GuestGivenName-2</GuestGivenName>					<GuestMiddleName>GuestMiddleName-2</GuestMiddleName>					<GuestNamePrefix>GuestNamePrefix-2</GuestNamePrefix>					<GuestKanjiName>GuestKanjiName-2</GuestKanjiName>					<GuestGender>GuestGender-2</GuestGender>					<GuestAge>0</GuestAge>					<GuestDateOfBirth>2012-10-10</GuestDateOfBirth>					<GuestType>GuestType-2</GuestType>					<GuestShubetsu>GuestShubetsu-2</GuestShubetsu>					<GuestPhoneNumber>GuestPhoneNumber-2</GuestPhoneNumber>					<GuestEmergencyPhoneNumber>GuestEmergencyPhoneNumber-2</GuestEmergencyPhoneNumber>					<GuestEmail>GuestEmail-2</GuestEmail>					<GuestCountry>GuestCountry-2</GuestCountry>					<GuestStateProvidence>GuestStateProvidence-2</GuestStateProvidence>					<GuestCityName>GuestCityName-2</GuestCityName>					<GuestAddressLine>GuestAddressLine-2</GuestAddressLine>					<GuestStreetNumber>GuestStreetNumber-2</GuestStreetNumber>					<GuestPostalCode>GuestPostalCode-2</GuestPostalCode>					<GuestBuildingName>GuestBuildingName-2</GuestBuildingName>					<GuestFFPCarrier>GuestFFPCarrier-2</GuestFFPCarrier>					<GuestFFPNumber>GuestFFPNumber-2</GuestFFPNumber>					<GuestCoachNumber>GuestCoachNumber-2</GuestCoachNumber>					<SpecialInformation>SpecialInformation-21</SpecialInformation>					<SpecialInformation>SpecialInformation-22</SpecialInformation>					<SpecialInformation>SpecialInformation-23</SpecialInformation>            	</GuestInformationList>            </GuestInformation>        </RoomAndGuestList>    </RoomAndGuestInformation>    <RisaplsInformation>        <RisaplsCommonInformation>            <Basic>                <SalesOfficeCompanyCode>80</SalesOfficeCompanyCode>                <TelegramDiv></TelegramDiv>                <RisaplsDataID></RisaplsDataID>                <RisaplsTelegramNumber></RisaplsTelegramNumber>                <TelegramData>予約通知 一休.com                                      SNT-NET 08-16 20:56 (80) 予約番号： IK0144977541  NO.00000003 松本丸の内ホテル様(00001782)宿泊者情報：  野村 豊幸  TEL:0423241785  ﾉﾑﾗ ｶｽﾞﾕｷ  住所:(〒185-0023)東京都 国分寺市 西元町　2-11-7  性別:男        年代:40代        年齢:予約者情報：  野村 豊幸  のむら かずゆき  住所:(〒185-0023)東京都 国分寺市 西元町　2-11-7  性別:男                     生年月日:  会員種別:会員               メルマガ希望:プラン名：ビジネス応援「ゆったりデラックス」素泊まり(bien14)2013年08月18日から    1泊  ＲＣ  サ込税込入込方法：                   チェックイン時間：15:00人員総数：   1人  内訳：(男)1名客室総数：   1室08月18日  dsn  (デラックスシングル（禁煙）(シングル))  @8,000          大人（男）     1名                                   宿泊料金計                ：     \\8,000                       合計料金                              ：     \\8,000                     【宿泊者への請求額】                    ：     \\8,000           ---------------------------------------------------------------------支払い方法  ：現払いご確認事項：食事なし禁煙ルームをお願いします質問1:駐車場ご利用の場合はAとお車の台数を、ご利用のない場合はBとご記入ください。回答1:B取扱個所：株式会社一休(001)  TEL 03-6685-0065  FAX 03-6234-8921会員番号：01006096---</TelegramData>                <PhoneNumber>0423241785</PhoneNumber>                <PostalCode>185-0023</PostalCode>                <Address>東京都 国分寺市 西元町　2-11-7</Address>                <TotalPaxManCount>1</TotalPaxManCount>                <BranchFaxNumber>03-6234-8921</BranchFaxNumber>                <Version>2.0</Version>                <RepresentativePhoneType>2</RepresentativePhoneType>                <RepresentativeGeneration>40代</RepresentativeGeneration>                <RepresentativeGendar>0</RepresentativeGendar>                <AccommodationId>G66249</AccommodationId>            </Basic>            <Allotment>                <AssignDiv>1</AssignDiv>                <GenderDiv>0</GenderDiv>                <HandleDiv>1</HandleDiv>                <RsvUserDiv>1</RsvUserDiv>                <UseDiv>1</UseDiv>            </Allotment>            <RoomAndRoomRateInformation>                <RoomInformation>                    <RoomTypeCode>20</RoomTypeCode>                    <RoomTypeName>デラックスシングル（禁煙）(シングル)</RoomTypeName>                    <PerRoomPaxCount>1</PerRoomPaxCount>                    <RoomPaxMaleCount>1</RoomPaxMaleCount>                    <RoomPaxFemaleCount>0</RoomPaxFemaleCount>                    <RoomChildA70Count>0</RoomChildA70Count>                    <RoomChildB50Count>0</RoomChildB50Count>                    <RoomChildC30Count>0</RoomChildC30Count>                    <RoomChildDNoneCount>0</RoomChildDNoneCount>                    <RoomTypeAgent>80</RoomTypeAgent>                    <RoomFrame>--</RoomFrame>                    <NetRmTypeGroupCode>4</NetRmTypeGroupCode>                    <PlanGroupCode>18</PlanGroupCode>                </RoomInformation>                <RoomRateInformation>                    <RoomDate>2013-08-18</RoomDate>                    <PerPaxRate>8000</PerPaxRate>                    <PerChildA70Rate>0</PerChildA70Rate>                    <PerChildB50Rate>0</PerChildB50Rate>                    <PerChildC30Rate>0</PerChildC30Rate>                    <PerChildDRate>0</PerChildDRate>                    <TotalPerRoomRate>8000</TotalPerRoomRate>                    <PerMaleRate>8000</PerMaleRate>                    <RoomRatePaxMaleCount>1</RoomRatePaxMaleCount>                    <RoomRatePaxFemaleCount>0</RoomRatePaxFemaleCount>                    <RoomRateChildA70Count>0</RoomRateChildA70Count>                    <RoomRateChildB50Count>0</RoomRateChildB50Count>                    <RoomRateChildC30Count>0</RoomRateChildC30Count>                    <RoomRateChildDNoneCount>0</RoomRateChildDNoneCount>                     <TotalRoomHotSpringTax>100</TotalRoomHotSpringTax>                    <TotalPerRoomServiceFee>500</TotalPerRoomServiceFee>                </RoomRateInformation>                <GuestInformation>            	<GuestInformationList>					<GuestNameSingleByte>GuestNameSingleByte-1</GuestNameSingleByte>					<GuestSurName>GuestSurName-1</GuestSurName>					<GuestGivenName>GuestGivenName-1</GuestGivenName>					<GuestMiddleName>GuestMiddleName-1</GuestMiddleName>					<GuestNamePrefix>GuestNamePrefix-1</GuestNamePrefix>					<GuestKanjiName>GuestKanjiName-1</GuestKanjiName>					<GuestGender>GuestGender-1</GuestGender>					<GuestAge>100</GuestAge>					<GuestDateOfBirth>1912-12-31</GuestDateOfBirth>					<GuestType>GuestType-1</GuestType>					<GuestShubetsu>GuestShubetsu-1</GuestShubetsu>					<GuestPhoneNumber>GuestPhoneNumber-1</GuestPhoneNumber>					<GuestEmergencyPhoneNumber>GuestEmergencyPhoneNumber-1</GuestEmergencyPhoneNumber>					<GuestEmail>GuestEmail-1</GuestEmail>					<GuestCountry>GuestCountry-1</GuestCountry>					<GuestStateProvidence>GuestStateProvidence-1</GuestStateProvidence>					<GuestCityName>GuestCityName-1</GuestCityName>					<GuestAddressLine>GuestAddressLine-1</GuestAddressLine>					<GuestStreetNumber>GuestStreetNumber-1</GuestStreetNumber>					<GuestPostalCode>GuestPostalCode-1</GuestPostalCode>					<GuestBuildingName>GuestBuildingName-1</GuestBuildingName>					<GuestFFPCarrier>GuestFFPCarrier-1</GuestFFPCarrier>					<GuestFFPNumber>GuestFFPNumber-1</GuestFFPNumber>					<GuestCoachNumber>GuestCoachNumber-1</GuestCoachNumber>					<SpecialInformation>SpecialInformation-11</SpecialInformation>					<SpecialInformation>SpecialInformation-12</SpecialInformation>					<SpecialInformation>SpecialInformation-13</SpecialInformation>            	</GuestInformationList>            	<GuestInformationList>					<GuestNameSingleByte>GuestNameSingleByte-2</GuestNameSingleByte>					<GuestSurName>GuestSurName-2</GuestSurName>					<GuestGivenName>GuestGivenName-2</GuestGivenName>					<GuestMiddleName>GuestMiddleName-2</GuestMiddleName>					<GuestNamePrefix>GuestNamePrefix-2</GuestNamePrefix>					<GuestKanjiName>GuestKanjiName-2</GuestKanjiName>					<GuestGender>GuestGender-2</GuestGender>					<GuestAge>0</GuestAge>					<GuestDateOfBirth>2012-10-10</GuestDateOfBirth>					<GuestType>GuestType-2</GuestType>					<GuestShubetsu>GuestShubetsu-2</GuestShubetsu>					<GuestPhoneNumber>GuestPhoneNumber-2</GuestPhoneNumber>					<GuestEmergencyPhoneNumber>GuestEmergencyPhoneNumber-2</GuestEmergencyPhoneNumber>					<GuestEmail>GuestEmail-2</GuestEmail>					<GuestCountry>GuestCountry-2</GuestCountry>					<GuestStateProvidence>GuestStateProvidence-2</GuestStateProvidence>					<GuestCityName>GuestCityName-2</GuestCityName>					<GuestAddressLine>GuestAddressLine-2</GuestAddressLine>					<GuestStreetNumber>GuestStreetNumber-2</GuestStreetNumber>					<GuestPostalCode>GuestPostalCode-2</GuestPostalCode>					<GuestBuildingName>GuestBuildingName-2</GuestBuildingName>					<GuestFFPCarrier>GuestFFPCarrier-2</GuestFFPCarrier>					<GuestFFPNumber>GuestFFPNumber-2</GuestFFPNumber>					<GuestCoachNumber>GuestCoachNumber-2</GuestCoachNumber>					<SpecialInformation>SpecialInformation-21</SpecialInformation>					<SpecialInformation>SpecialInformation-22</SpecialInformation>					<SpecialInformation>SpecialInformation-23</SpecialInformation>            	</GuestInformationList>            </GuestInformation>            </RoomAndRoomRateInformation>	<Member>		<UserName>UserName-1</UserName>		<UserKana>UserKana-1</UserKana>		<UserTel>UserTel-1</UserTel>		<UserMailAddr>UserMailAddr-1</UserMailAddr>		<UserZip>UserZip-1</UserZip>		<UserAddr>UserAddr-1</UserAddr>		<UserCorp>UserCorp-1</UserCorp>		<UserDep>UserDep-1</UserDep>		<UserID>UserID-1</UserID>		<VIPCode>VIPCode-1</VIPCode>		<PointCompanyName>PointCompanyName-1</PointCompanyName>		<PointName>PointName-1</PointName>		<UserGivinPoints>100000</UserGivinPoints>		<UserUsePoints>5432</UserUsePoints>		<TotalAccommodationDecleasePoints>11111</TotalAccommodationDecleasePoints>		<TotalAccommodationConsumptaionTax>2222</TotalAccommodationConsumptaionTax>		<AmountClaimed>123456</AmountClaimed>		<ChargeEquation>ChargeEquation-1</ChargeEquation>		<UserUsePointList>			<PointName>PointName-1</PointName>			<UserUsePoint>10000</UserUsePoint>		</UserUsePointList>		<UserUsePointList>			<PointName>PointName-2</PointName>			<UserUsePoint>20000</UserUsePoint>		</UserUsePointList>	</Member>	<OtherInfo>                <GuestRequest>食事なし禁煙ルームをお願いします</GuestRequest>                <AdditionalInformation>質問1:駐車場ご利用の場合はAとお車の台数を、ご利用のない場合はBとご記入ください。回答1:B</AdditionalInformation>				<QuestionAndAnswerList>					<QuestionToGuest>QuestionToGuest-1</QuestionToGuest>					<AnswerToHotel>AnswerToHotel-1</AnswerToHotel>				</QuestionAndAnswerList>				<QuestionAndAnswerList>					<QuestionToGuest>QuestionToGuest-2</QuestionToGuest>					<AnswerToHotel>AnswerToHotel-2</AnswerToHotel>				</QuestionAndAnswerList>            </OtherInfo>            <BlockReport>				<RoomTypeCode>1A</RoomTypeCode>				<InquiryDate>20120825</InquiryDate>				<TotalRoomsBlock>10</TotalRoomsBlock>				<TotalRoomsNotYetSold>101</TotalRoomsNotYetSold>			</BlockReport>			<BlockReport>				<RoomTypeCode>1A</RoomTypeCode>				<InquiryDate>20120826</InquiryDate>				<TotalRoomsBlock>10</TotalRoomsBlock>				<TotalRoomsNotYetSold>102</TotalRoomsNotYetSold>			</BlockReport>            <BasicRate>				<TotalAccomodationServiceCharge>12345678</TotalAccomodationServiceCharge>				<PointsDiscountList>					<PointsDiv>1</PointsDiv>					<PointsDiscountName>PointsDiscountName-1</PointsDiscountName>					<PointsDiscount>10000</PointsDiscount>				</PointsDiscountList>				<PointsDiscountList>					<PointsDiv>2</PointsDiv>					<PointsDiscountName>PointsDiscountName-2</PointsDiscountName>					<PointsDiscount>20000</PointsDiscount>				</PointsDiscountList>				<DepositList>					<DepositAmount>12345</DepositAmount>				</DepositList>				<DepositList>					<DepositAmount>23456</DepositAmount>				</DepositList>			</BasicRate>        </RisaplsCommonInformation>        <AgentNativeInformation>            <Extend>                <TotalAccommodationDecleasePoints>8000</TotalAccommodationDecleasePoints>                <AmountClaimed>8000</AmountClaimed>            </Extend>            <Extendmytrip>                <SettlementDiv>0</SettlementDiv>            </Extendmytrip>        </AgentNativeInformation>    </RisaplsInformation></AllotmentBookingReport>';	
    	String dateKey = System.now().format('yyMMddHHMMssSSS');
    	Attachment newAttach = new Attachment(
									ParentId = parentId,
									Name = 'TAPDATA_' + dateKey + '1_Test.xml', 
									ContentType = 'text/xml',
									Body = Blob.valueOf(infoTravelXML)
								);
		insert newAttach;
    }
    public static void createAttachment(String parentId){
    	//String infoTravelXML = '<?xmlversion="1.0"encoding="UTF-8"standalone="yes"?><AllotmentBookingReport><TransactionType><DataFrom>FromTravelAgency</DataFrom><DataClassification>NewBookReport</DataClassification><DataID>101731864-1</DataID><BookingDataID>101731864-1</BookingDataID><SystemDate>2013-07-09</SystemDate></TransactionType><AccommodationInformation><AccommodationName>元湯陣屋</AccommodationName><AccommodationCode>14000010</AccommodationCode></AccommodationInformation><SalesOfficeInformation><SalesOfficeCompanyCode>88</SalesOfficeCompanyCode><SalesOfficeCompanyName>予約プロ</SalesOfficeCompanyName><SalesOfficeName>予約プロ</SalesOfficeName><SalesOfficeCode>88</SalesOfficeCode><SalesOfficePhoneNumber>052-262-8041</SalesOfficePhoneNumber></SalesOfficeInformation><BasicInformation><TravelAgencyBookingNumber>A001781590</TravelAgencyBookingNumber><TravelAgencyBookingDate>2013-07-09</TravelAgencyBookingDate><TravelAgencyBookingTime>23:47:14</TravelAgencyBookingTime><TravelAgencyReportNumber>00000051</TravelAgencyReportNumber><GuestOrGroupNameSingleByte>ﾃｽﾄﾖﾔｸ_</GuestOrGroupNameSingleByte><GuestOrGroupNameKanjiName>テスト予約No.2013/07/09_</GuestOrGroupNameKanjiName><CheckInDate>2013-07-22</CheckInDate><CheckInTime>15:30:00</CheckInTime><CheckOutDate>2013-07-25</CheckOutDate><Nights>3</Nights><TotalRoomCount>2</TotalRoomCount><GrandTotalPaxCount>14</GrandTotalPaxCount><TotalPaxMaleCount>2</TotalPaxMaleCount><TotalPaxFemaleCount>2</TotalPaxFemaleCount><TotalChildA70Count>2</TotalChildA70Count><TotalChildB50Count>4</TotalChildB50Count><TotalChildC30Count>2</TotalChildC30Count><TotalChildDNoneCount>2</TotalChildDNoneCount><PackagePlanName>【１泊朝食付】朝膳朝食付きプラン　チェックイン24:00までOK！</PackagePlanName><PackagePlanCode>3333</PackagePlanCode><MealCondition>1nightBreakfast</MealCondition><SpecificMealCondition>NoneSpecified</SpecificMealCondition><OtherServiceInformation>○携帯電話番号[MobilePhoneNumber]：00-2345-6789○ご要望・ご質問：NroomsNnightsのテストのため</OtherServiceInformation></BasicInformation><BasicRateInformation><RoomRateOrPersonalRate>PersonalRate</RoomRateOrPersonalRate><TaxServiceFee>IncludingServiceAndTax</TaxServiceFee><TotalAccommodationCharge>429135</TotalAccommodationCharge></BasicRateInformation><RoomAndGuestInformation><RoomAndGuestList><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount></RoomInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerChildB50Rate>0</PerChildB50Rate></RoomRateInformation></RoomAndGuestList><RoomAndGuestList><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>2</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount></RoomInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerChildB50Rate>0</PerChildB50Rate></RoomRateInformation></RoomAndGuestList><RoomAndGuestList><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount></RoomInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerChildB50Rate>0</PerChildB50Rate></RoomRateInformation></RoomAndGuestList><RoomAndGuestList><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>2</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount></RoomInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerChildB50Rate>0</PerChildB50Rate></RoomRateInformation></RoomAndGuestList><RoomAndGuestList><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount></RoomInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerChildB50Rate>0</PerChildB50Rate></RoomRateInformation></RoomAndGuestList><RoomAndGuestList><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>1</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount></RoomInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerChildB50Rate>0</PerChildB50Rate></RoomRateInformation></RoomAndGuestList></RoomAndGuestInformation><RisaplsInformation><RisaplsCommonInformation><Basic><SalesOfficeCompanyCode>88</SalesOfficeCompanyCode><TelegramDiv></TelegramDiv><RisaplsDataID></RisaplsDataID><RisaplsTelegramNumber></RisaplsTelegramNumber>';
    	//infoTravelXML += '<TelegramData>予約通知予約プロSNT-NET07-0923:49(88)予約番号：A001781590NO.00000051元湯陣屋様(14000010)宿泊者情報：テスト予約No.2013/07/09_TEL:01-2345-6789ﾃｽﾄﾖﾔｸ_Mail:hiroyuki_morimoto@jinya-inn.com住所:(〒257-0001)神奈川県秦野市鶴巻北inn.com住所:(〒257-0001)神奈川県秦野市鶴巻北プラン名：【１泊朝食付】朝膳朝食付きプラン　チェックイン24:00までOK！(185)2013年07月22日から3泊朝食付サ込税込入込方法：チェックイン時間：15:30人員総数：14人内訳：(男)2名+(女)2名+(Ａ)2名+(Ｂ)4名+(Ｃ)2名+(Ｄ)2名客室総数：2室07月22日24(純和風客室(バスルーム無し))大人（男）1名@12,000大人（女）1名@12,000子供Ａ1名@12,000小学生子供Ｂ1名@12,000小児（食事布団あり）子供Ｂ1名@0小児（食事布団なし）子供Ｃ1名@3,000小児（食事のみ）子供Ｄ1名@10,000小児（布団のみ）24(純和風客室(バスルーム無し))大人（男）1名@12,000大人（女）1名@12,000子供Ａ1名@12,000小学生子供Ｂ1名@12,000小児（食事布団あり）子供Ｂ1名@0小児（食事布団なし）子供Ｃ1名@3,000小児（食事のみ）子供Ｄ1名@10,000小児（布団のみ）07月23日24(純和風客室(バスルーム無し))大人（男）1名@12,000大人（女）1名@12,000子供Ａ1名@12,000小学生子供Ｂ1名@12,000小児（食事布団あり）子供Ｂ1名@0小児（食事布団なし）子供Ｃ1名@3,000小児（食事のみ）子供Ｄ1名@10,000小児（布団のみ）24(純和風客室(バスルーム無し))大人（男）1名@12,000大人（女）1名@12,000子供Ａ1名@12,000小学生子供Ｂ1名@12,000小児（食事布団あり）子供Ｂ1名@0小児（食事布団なし）子供Ｃ1名@3,000小児（食事のみ）子供Ｄ1名@10,000小児（布団のみ）07月24日24(純和風客室(バスルーム無し))大人（男）1名@12,000大人（女）1名@12,000子供Ａ1名@12,000小学生子供Ｂ1名@12,000小児（食事布団あり）子供Ｂ1名@0小児（食事布団なし）子供Ｃ1名@3,000小児（食事のみ）子供Ｄ1名@10,000小児（布団のみ）24(純和風客室(バスルーム無し))大人（男）1名@12,000大人（女）1名@12,000子供Ａ1名@12,000小学生子供Ｂ1名@12,000小児（食事布団あり）子供Ｂ1名@0小児（食事布団なし）子供Ｃ1名@3,000小児（食事のみ）子供Ｄ1名@10,000小児（布団のみ）宿泊料金計：\\366,000オプション：07月22日特選会席料理4個@12,000お土産（陣屋どらやき　6個入）1個@960お土産（やまと豚の桜味噌漬け13個@1,575お土産（やまと豚の桜味噌漬け23個@3,150 オプション料金計：\\63,135合計料金：\\429,135【宿泊者への請求額】：\\429,135---------------------------------------------------------------------ご確認事項：○携帯電話番号[MobilePhoneNumber]：00-2345-6789○ご要望・ご質問：NroomsNnightsのテストのため取扱個所：予約プロ(88)TEL052-262-8041FAX052-262-8042---</TelegramData><PhoneNumber>01-2345-6789</PhoneNumber><Email>hiroyuki_morimoto@jinya-inn.com</Email>';
    	//infoTravelXML += '<PostalCode>257-0001</PostalCode><Address>神奈川県秦野市鶴巻北</Address><TotalPaxManCount>4</TotalPaxManCount><BranchFaxNumber>052-262-8042</BranchFaxNumber><Version>2.0</Version><AccommodationId>X36969</AccommodationId></Basic><Allotment><AssignDiv>1</AssignDiv><GenderDiv>1</GenderDiv><HandleDiv>1</HandleDiv><RsvUserDiv>0</RsvUserDiv><UseDiv>0</UseDiv></Allotment><Option><OptionDate>2013-07-22</OptionDate><OptionCode>33</OptionCode><Name>特選会席料理</Name><OptionCount>4</OptionCount><OptionRate>12000</OptionRate></Option><Option><OptionDate>2013-07-22</OptionDate><Name>お土産（陣屋どらやき　6個入）</Name><OptionCount>1</OptionCount><OptionRate>960</OptionRate></Option><Option><OptionDate>2013-07-22</OptionDate><Name>お土産（やまと豚の桜味噌漬け10枚入）</Name><OptionCount>3</OptionCount><OptionRate>1575</OptionRate></Option><Option><OptionDate>2013-07-22</OptionDate><Name>お土産（やまと豚の桜味噌漬け20枚入）</Name><OptionCount>3</OptionCount><OptionRate>3150</OptionRate></Option><RoomAndRoomRateInformation><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount><RoomChildA70Request>小学生</RoomChildA70Request><RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request><RoomChildC30Request>小児（食事のみ）</RoomChildC30Request><RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest><RoomTypeAgent>88</RoomTypeAgent><RoomFrame>--</RoomFrame><NetRmTypeGroupCode>49</NetRmTypeGroupCode><PlanGroupCode>---</PlanGroupCode></RoomInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee><PerMaleRate>12000</PerMaleRate><PerFemaleRate>12000</PerFemaleRate><RoomRatePaxMaleCount>1</RoomRatePaxMaleCount><RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount><RoomRateChildA70Count>1</RoomRateChildA70Count><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildC30Count>1</RoomRateChildC30Count><RoomRateChildDNoneCount>1</RoomRateChildDNoneCount><RoomRateChildA70Request>小学生</RoomRateChildA70Request><RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request><RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request><RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerChildB50Rate>0</PerChildB50Rate><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request></RoomRateInformation></RoomAndRoomRateInformation><RoomAndRoomRateInformation><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount><RoomChildA70Request>小学生</RoomChildA70Request><RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request>';
    	//infoTravelXML += '<RoomChildC30Request>小児（食事のみ）</RoomChildC30Request><RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest><RoomTypeAgent>88</RoomTypeAgent><RoomFrame>--</RoomFrame><NetRmTypeGroupCode>49</NetRmTypeGroupCode><PlanGroupCode>---</PlanGroupCode></RoomInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee><PerMaleRate>12000</PerMaleRate><PerFemaleRate>12000</PerFemaleRate><RoomRatePaxMaleCount>1</RoomRatePaxMaleCount><RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount><RoomRateChildA70Count>1</RoomRateChildA70Count><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildC30Count>1</RoomRateChildC30Count><RoomRateChildDNoneCount>1</RoomRateChildDNoneCount><RoomRateChildA70Request>小学生</RoomRateChildA70Request><RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request><RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request><RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerChildB50Rate>0</PerChildB50Rate><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request></RoomRateInformation></RoomAndRoomRateInformation><RoomAndRoomRateInformation><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount><RoomChildA70Request>小学生</RoomChildA70Request><RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request><RoomChildC30Request>小児（食事のみ）</RoomChildC30Request><RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest><RoomTypeAgent>88</RoomTypeAgent><RoomFrame>--</RoomFrame><NetRmTypeGroupCode>49</NetRmTypeGroupCode><PlanGroupCode>---</PlanGroupCode></RoomInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee><PerMaleRate>12000</PerMaleRate><PerFemaleRate>12000</PerFemaleRate><RoomRatePaxMaleCount>1</RoomRatePaxMaleCount><RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount><RoomRateChildA70Count>1</RoomRateChildA70Count><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildC30Count>1</RoomRateChildC30Count><RoomRateChildDNoneCount>1</RoomRateChildDNoneCount><RoomRateChildA70Request>小学生</RoomRateChildA70Request><RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request><RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request><RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerChildB50Rate>0</PerChildB50Rate><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request></RoomRateInformation></RoomAndRoomRateInformation><RoomAndRoomRateInformation><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount><RoomChildA70Request>小学生</RoomChildA70Request><RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request><RoomChildC30Request>小児（食事のみ）</RoomChildC30Request><RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest><RoomTypeAgent>88</RoomTypeAgent><RoomFrame>--</RoomFrame><NetRmTypeGroupCode>49</NetRmTypeGroupCode><PlanGroupCode>---</PlanGroupCode></RoomInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee><PerMaleRate>12000</PerMaleRate><PerFemaleRate>12000</PerFemaleRate><RoomRatePaxMaleCount>1</RoomRatePaxMaleCount><RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount><RoomRateChildA70Count>1</RoomRateChildA70Count><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildC30Count>1</RoomRateChildC30Count><RoomRateChildDNoneCount>1</RoomRateChildDNoneCount><RoomRateChildA70Request>小学生</RoomRateChildA70Request><RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request><RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request><RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerChildB50Rate>0</PerChildB50Rate><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request></RoomRateInformation></RoomAndRoomRateInformation><RoomAndRoomRateInformation><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount><RoomChildA70Request>小学生</RoomChildA70Request><RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request><RoomChildC30Request>小児（食事のみ）</RoomChildC30Request><RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest><RoomTypeAgent>88</RoomTypeAgent><RoomFrame>--</RoomFrame><NetRmTypeGroupCode>49</NetRmTypeGroupCode><PlanGroupCode>---</PlanGroupCode></RoomInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee><PerMaleRate>12000</PerMaleRate><PerFemaleRate>12000</PerFemaleRate><RoomRatePaxMaleCount>1</RoomRatePaxMaleCount><RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount><RoomRateChildA70Count>1</RoomRateChildA70Count><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildC30Count>1</RoomRateChildC30Count><RoomRateChildDNoneCount>1</RoomRateChildDNoneCount><RoomRateChildA70Request>小学生</RoomRateChildA70Request><RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request><RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request><RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerChildB50Rate>0</PerChildB50Rate><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request></RoomRateInformation></RoomAndRoomRateInformation><RoomAndRoomRateInformation><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount><RoomChildA70Request>小学生</RoomChildA70Request><RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request><RoomChildC30Request>小児（食事のみ）</RoomChildC30Request><RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest><RoomTypeAgent>88</RoomTypeAgent><RoomFrame>--</RoomFrame><NetRmTypeGroupCode>49</NetRmTypeGroupCode><PlanGroupCode>---</PlanGroupCode></RoomInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee><PerMaleRate>12000</PerMaleRate><PerFemaleRate>12000</PerFemaleRate><RoomRatePaxMaleCount>1</RoomRatePaxMaleCount><RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount><RoomRateChildA70Count>1</RoomRateChildA70Count><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildC30Count>1</RoomRateChildC30Count><RoomRateChildDNoneCount>1</RoomRateChildDNoneCount><RoomRateChildA70Request>小学生</RoomRateChildA70Request><RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request><RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request><RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerChildB50Rate>0</PerChildB50Rate><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request></RoomRateInformation></RoomAndRoomRateInformation><OtherInfo><GuestRequest>○携帯電話番号[MobilePhoneNumber]：00-2345-6789○ご要望・ご質問：NroomsNnightsのテストのため</GuestRequest></OtherInfo></RisaplsCommonInformation><AgentNativeInformation><Extend><AmountClaimed>429135</AmountClaimed></Extend><Extendmytrip><SettlementDiv>4</SettlementDiv></Extendmytrip></AgentNativeInformation></RisaplsInformation></AllotmentBookingReport>';
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
    }
    public static void createAttachmentCaseUpd1(String parentId){
    	String infoTravelXML = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><AllotmentBookingReport>    <TransactionType>        <DataFrom>FromTravelAgency</DataFrom>        <DataClassification>NewBookReport</DataClassification>        <DataID>106535992-1</DataID>        <SystemDate>2013-08-23</SystemDate>    </TransactionType>    <AccommodationInformation>        <AccommodationName>松本丸の内ホテル (旧アルモニービアン）</AccommodationName>        <AccommodationCode>Y81153</AccommodationCode>    </AccommodationInformation>    <SalesOfficeInformation><SalesOfficeCompanyCode>88</SalesOfficeCompanyCode><SalesOfficeCompanyName>じゃらんnet</SalesOfficeCompanyName>        <SalesOfficeName>じゃらんnet宿予約サービス</SalesOfficeName>        <SalesOfficeCode>66</SalesOfficeCode>        <SalesOfficeEmail>support@jalan.net</SalesOfficeEmail>        <SalesOfficePhoneNumber>0570-005972</SalesOfficePhoneNumber>    </SalesOfficeInformation>    <BasicInformation>        <TravelAgencyBookingNumber>0HVAXER7</TravelAgencyBookingNumber>        <TravelAgencyBookingDate>2013-08-16</TravelAgencyBookingDate>        <TravelAgencyBookingTime>15:27:26</TravelAgencyBookingTime>        <TravelAgencyReportNumber>00000013</TravelAgencyReportNumber>        <GuestOrGroupNameSingleByte>ｹﾞﾝ ｼﾘｭｳ _!</GuestOrGroupNameSingleByte>        <GuestOrGroupNameKanjiName>玄 志龍 _!</GuestOrGroupNameKanjiName>        <CheckInDate>2013-08-24</CheckInDate>        <CheckInTime>20:00:00</CheckInTime>        <CheckOutDate>2013-08-25</CheckOutDate>        <CheckOutTime>11:00:00</CheckOutTime>        <Nights>1</Nights>        <TotalRoomCount>1</TotalRoomCount>        <GrandTotalPaxCount>1</GrandTotalPaxCount>        <TotalPaxMaleCount>1</TotalPaxMaleCount>        <PackagePlanName>◇基本プラン◇【朝食付】</PackagePlanName>        <PackagePlanCode>222</PackagePlanCode>        <MealCondition>1nightBreakfast</MealCondition>        <SpecificMealCondition>None Specified</SpecificMealCondition>        <OtherServiceInformation>ポイント利用(現:200pt)朝食付</OtherServiceInformation>    </BasicInformation>    <BasicRateInformation>        <RoomRateOrPersonalRate>PersonalRate</RoomRateOrPersonalRate>        <TaxServiceFee>IncludingServiceAndTax</TaxServiceFee>        <TotalAccommodationCharge>9800</TotalAccommodationCharge>    </BasicRateInformation>    <RoomAndGuestInformation>        <RoomAndGuestList>            <RoomInformation>                <RoomTypeCode>30</RoomTypeCode>                <RoomTypeName>スタンダードダブル18㎡（禁煙）</RoomTypeName>                <PerRoomPaxCount>1</PerRoomPaxCount>                <RoomPaxMaleCount>1</RoomPaxMaleCount>            </RoomInformation>            <RoomRateInformation>                <RoomDate>2013-08-24</RoomDate>                <PerPaxRate>9800</PerPaxRate>            </RoomRateInformation>        </RoomAndGuestList>    </RoomAndGuestInformation>    <RisaplsInformation>        <RisaplsCommonInformation>            <Basic>                <SalesOfficeCompanyCode>66</SalesOfficeCompanyCode>                <TelegramDiv></TelegramDiv>                <RisaplsDataID></RisaplsDataID>                <RisaplsTelegramNumber></RisaplsTelegramNumber>                <TelegramData>予約通知 じゃらんnet---</TelegramData>                <PhoneNumber>09035983092</PhoneNumber>                <PostalCode>3330811</PostalCode>                <Address>埼玉県川口市戸塚６－７－６　エスペランサ１０３</Address>                <TotalPaxManCount>1</TotalPaxManCount>                <Version>2.0</Version>                <RepresentativeGeneration>35-39才</RepresentativeGeneration>                <AccommodationId>G66249</AccommodationId>            </Basic>            <Allotment>                <AssignDiv>1</AssignDiv>                <GenderDiv>0</GenderDiv>                <HandleDiv>1</HandleDiv>                <RsvUserDiv>1</RsvUserDiv>                <UseDiv>0</UseDiv>            </Allotment>            <RoomAndRoomRateInformation>                <RoomInformation>                    <RoomTypeCode>30</RoomTypeCode>                    <RoomTypeName>スタンダードダブル18㎡（禁煙）</RoomTypeName>                    <PerRoomPaxCount>1</PerRoomPaxCount>                    <RoomPaxMaleCount>1</RoomPaxMaleCount>                    <RoomTypeAgent>66</RoomTypeAgent>                    <RoomFrame>--</RoomFrame>                    <NetRmTypeGroupCode>6</NetRmTypeGroupCode>                    <PlanGroupCode>31</PlanGroupCode>                </RoomInformation>                <RoomRateInformation>                    <RoomDate>2013-08-24</RoomDate>                    <PerPaxRate>9800</PerPaxRate>                    <PerMaleRate>9800</PerMaleRate>                    <RoomRatePaxMaleCount>1</RoomRatePaxMaleCount>                </RoomRateInformation>            </RoomAndRoomRateInformation>            <Member>                <UserName>玄 志龍</UserName>                <UserKana>ｹﾞﾝ ｼﾘｭｳ</UserKana>                <UserMailAddr>ziontrek@gmail.com</UserMailAddr>            </Member>            <OtherInfo>                <GuestRequest>ポイント利用(現:200pt)朝食付</GuestRequest>                <QuestionAndAnswerList>                    <QuestionToGuest>・駐車場ご利用のお客様はこちらに必要台数をご記入ください</QuestionToGuest>                    <AnswerToHotel>駐車場ご利用：1台Tel：09035983092</AnswerToHotel>                </QuestionAndAnswerList>            </OtherInfo>            <BasicRate>                <TotalAccomodationServiceCharge>0</TotalAccomodationServiceCharge>                <PointsDiscountList>                    <PointsDiv>2</PointsDiv>                    <PointsDiscountName>現ポイント</PointsDiscountName>                    <PointsDiscount>200</PointsDiscount>                </PointsDiscountList>            </BasicRate>        </RisaplsCommonInformation>        <AgentNativeInformation>            <Extend>                <PointDiv>エージェント原資</PointDiv>                <PointName>現ポイント</PointName>                <Points>200</Points>                <TotalAccommodationDecleasePoints>9600</TotalAccommodationDecleasePoints>                <TotalAccommodationConsumptionTax>0</TotalAccommodationConsumptionTax>                <AmountClaimed>9600</AmountClaimed>            </Extend>            <Extendmytrip>                <SettlementDiv>0</SettlementDiv>            </Extendmytrip>        </AgentNativeInformation>    </RisaplsInformation></AllotmentBookingReport>';
    	String dateKey = System.now().format('yyMMddHHMMssSSS');
    	Attachment newAttach = new Attachment(
									ParentId = parentId,
									Name = 'TAPDATA_' + dateKey + '1_Test.xml', 
									ContentType = 'text/xml',
									Body = Blob.valueOf(infoTravelXML)
								);
		insert newAttach;
    
    }
    public static void createAttachmentCaseUpd2(String parentId){
    	String infoTravelXML = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><AllotmentBookingReport>    <TransactionType>        <DataFrom>FromTravelAgency</DataFrom>        <DataClassification>ModificationReport</DataClassification>        <DataID>106535992-1</DataID>        <SystemDate>2013-08-23</SystemDate>    </TransactionType>    <AccommodationInformation>        <AccommodationName>松本丸の内ホテル (旧アルモニービアン）</AccommodationName>        <AccommodationCode>Y81153</AccommodationCode>    </AccommodationInformation>    <SalesOfficeInformation><SalesOfficeCompanyCode>88</SalesOfficeCompanyCode><SalesOfficeCompanyName>じゃらんnet</SalesOfficeCompanyName>        <SalesOfficeName>じゃらんnet宿予約サービス</SalesOfficeName>        <SalesOfficeCode>66</SalesOfficeCode>        <SalesOfficeEmail>support@jalan.net</SalesOfficeEmail>        <SalesOfficePhoneNumber>0570-005972</SalesOfficePhoneNumber>    </SalesOfficeInformation>    <BasicInformation>        <TravelAgencyBookingNumber>0HVAXER7</TravelAgencyBookingNumber>        <TravelAgencyBookingDate>2013-08-16</TravelAgencyBookingDate>        <TravelAgencyBookingTime>15:27:26</TravelAgencyBookingTime>        <TravelAgencyReportNumber>00000013</TravelAgencyReportNumber>        <GuestOrGroupNameSingleByte>ｹﾞﾝ ｼﾘｭｳ _!</GuestOrGroupNameSingleByte>        <GuestOrGroupNameKanjiName>玄 志龍 _!</GuestOrGroupNameKanjiName>        <CheckInDate>2013-08-24</CheckInDate>        <CheckInTime>20:00:00</CheckInTime>        <CheckOutDate>2013-08-25</CheckOutDate>        <CheckOutTime>11:00:00</CheckOutTime>        <Nights>1</Nights>        <TotalRoomCount>1</TotalRoomCount>        <GrandTotalPaxCount>1</GrandTotalPaxCount>        <TotalPaxMaleCount>1</TotalPaxMaleCount>        <PackagePlanName>◇基本プラン◇【朝食付】</PackagePlanName>        <PackagePlanCode>222</PackagePlanCode>        <MealCondition>1nightBreakfast</MealCondition>        <SpecificMealCondition>None Specified</SpecificMealCondition>        <OtherServiceInformation>ポイント利用(現:200pt)朝食付 Tel：09035983092)</OtherServiceInformation>    </BasicInformation>    <BasicRateInformation>        <RoomRateOrPersonalRate>PersonalRate</RoomRateOrPersonalRate>        <TaxServiceFee>IncludingServiceAndTax</TaxServiceFee>        <TotalAccommodationCharge>9800</TotalAccommodationCharge>    </BasicRateInformation>    <RoomAndGuestInformation>        <RoomAndGuestList>            <RoomInformation>                <RoomTypeCode>30</RoomTypeCode>                <RoomTypeName>スタンダードダブル18㎡（禁煙）</RoomTypeName>                <PerRoomPaxCount>1</PerRoomPaxCount>                <RoomPaxMaleCount>1</RoomPaxMaleCount>            </RoomInformation>            <RoomRateInformation>                <RoomDate>2013-08-24</RoomDate>                <PerPaxRate>9800</PerPaxRate>            </RoomRateInformation>        </RoomAndGuestList>    </RoomAndGuestInformation>    <RisaplsInformation>        <RisaplsCommonInformation>            <Basic>                <SalesOfficeCompanyCode>66</SalesOfficeCompanyCode>                <TelegramDiv></TelegramDiv>                <RisaplsDataID></RisaplsDataID>                <RisaplsTelegramNumber></RisaplsTelegramNumber>                <TelegramData>予約通知 じゃらんnet---</TelegramData>                <PhoneNumber>09035983092</PhoneNumber>                <PostalCode>3330811</PostalCode>                <Address>埼玉県川口市戸塚６－７－６　エスペランサ１０３</Address>                <TotalPaxManCount>1</TotalPaxManCount>                <Version>2.0</Version>                <RepresentativeGeneration>35-39才</RepresentativeGeneration>                <AccommodationId>G66249</AccommodationId>            </Basic>            <Allotment>                <AssignDiv>1</AssignDiv>                <GenderDiv>0</GenderDiv>                <HandleDiv>1</HandleDiv>                <RsvUserDiv>1</RsvUserDiv>                <UseDiv>0</UseDiv>            </Allotment>            <RoomAndRoomRateInformation>                <RoomInformation>                    <RoomTypeCode>30</RoomTypeCode>                    <RoomTypeName>スタンダードダブル18㎡（禁煙）</RoomTypeName>                    <PerRoomPaxCount>1</PerRoomPaxCount>                    <RoomPaxMaleCount>1</RoomPaxMaleCount>                    <RoomTypeAgent>66</RoomTypeAgent>                    <RoomFrame>--</RoomFrame>                    <NetRmTypeGroupCode>6</NetRmTypeGroupCode>                    <PlanGroupCode>31</PlanGroupCode>                </RoomInformation>                <RoomRateInformation>                    <RoomDate>2013-08-24</RoomDate>                    <PerPaxRate>9800</PerPaxRate>                    <PerMaleRate>9800</PerMaleRate>                    <RoomRatePaxMaleCount>1</RoomRatePaxMaleCount>                </RoomRateInformation>            </RoomAndRoomRateInformation>            <Member>                <UserName>玄 志龍</UserName>                <UserKana>ｹﾞﾝ ｼﾘｭｳ</UserKana>                <UserMailAddr>ziontrek@gmail.com</UserMailAddr>            </Member>            <OtherInfo>                <GuestRequest>ポイント利用(現:200pt)朝食付</GuestRequest>                <QuestionAndAnswerList>                    <QuestionToGuest>・駐車場ご利用のお客様はこちらに必要台数をご記入ください</QuestionToGuest>                    <AnswerToHotel>駐車場ご利用：1台 Tel：09035983092</AnswerToHotel>                </QuestionAndAnswerList>            </OtherInfo>            <BasicRate>                <TotalAccomodationServiceCharge>0</TotalAccomodationServiceCharge>                <PointsDiscountList>                    <PointsDiv>2</PointsDiv>                    <PointsDiscountName>現ポイント</PointsDiscountName>                    <PointsDiscount>200</PointsDiscount>                </PointsDiscountList>            </BasicRate>        </RisaplsCommonInformation>        <AgentNativeInformation>            <Extend>                <PointDiv>エージェント原資</PointDiv>                <PointName>現ポイント</PointName>                <Points>200</Points>                <TotalAccommodationDecleasePoints>9600</TotalAccommodationDecleasePoints>                <TotalAccommodationConsumptionTax>0</TotalAccommodationConsumptionTax>                <AmountClaimed>9600</AmountClaimed>            </Extend>            <Extendmytrip>                <SettlementDiv>0</SettlementDiv>            </Extendmytrip>        </AgentNativeInformation>    </RisaplsInformation></AllotmentBookingReport>';
    	String dateKey = System.now().format('yyMMddHHMMssSSS');
    	Attachment newAttach = new Attachment(
									ParentId = parentId,
									Name = 'TAPDATA_' + dateKey + '2_Test.xml', 
									ContentType = 'text/xml',
									Body = Blob.valueOf(infoTravelXML)
								);
		insert newAttach;
    
    }
    public static void createattachmentCaseAllMessage(String parentId){
    	String infoTravelXML = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><AllotmentBookingReport>    <TransactionType>        <DataFrom>FromTravelAgency</DataFrom>        <DataClassification>NewBookReport</DataClassification>        <DataID>101731864-1</DataID>        <SystemDate>2013-07-09</SystemDate>    </TransactionType>    <AccommodationInformation>        <AccommodationName>元湯陣屋</AccommodationName>        <AccommodationCode>14000010</AccommodationCode>    </AccommodationInformation>    <SalesOfficeInformation><SalesOfficeCompanyCode>88</SalesOfficeCompanyCode><SalesOfficeCompanyName>予約プロ</SalesOfficeCompanyName>        <SalesOfficeName>予約プロ</SalesOfficeName>        <SalesOfficeCode>88</SalesOfficeCode>        <SalesOfficePhoneNumber>052-262-8041</SalesOfficePhoneNumber>    </SalesOfficeInformation>    <BasicInformation>        <TravelAgencyBookingNumber>A001781590</TravelAgencyBookingNumber>        <TravelAgencyBookingDate>2013-07-09</TravelAgencyBookingDate>        <TravelAgencyBookingTime>23:47:14</TravelAgencyBookingTime>        <TravelAgencyReportNumber>00000051</TravelAgencyReportNumber>        <GuestOrGroupNameSingleByte>ﾃｽﾄﾖﾔｸ _</GuestOrGroupNameSingleByte>        <GuestOrGroupNameKanjiName>テスト予約No. 2013/07/09 _</GuestOrGroupNameKanjiName>        <CheckInDate>2013-07-22</CheckInDate>        <CheckInTime>15:30:00</CheckInTime>        <CheckOutDate>2013-07-25</CheckOutDate>        <Nights>3</Nights>        <TotalRoomCount>2</TotalRoomCount>        <GrandTotalPaxCount>14</GrandTotalPaxCount>        <TotalPaxMaleCount>2</TotalPaxMaleCount>        <TotalPaxFemaleCount>2</TotalPaxFemaleCount>        <TotalChildA70Count>2</TotalChildA70Count>        <TotalChildB50Count>4</TotalChildB50Count>        <TotalChildC30Count>2</TotalChildC30Count>        <TotalChildDNoneCount>2</TotalChildDNoneCount>        <PackagePlanName>【１泊朝食付】朝膳朝食付きプラン　チェックイン24:00までOK！</PackagePlanName>        <PackagePlanCode>185</PackagePlanCode>        <MealCondition>1nightBreakfast</MealCondition>        <SpecificMealCondition>None Specified</SpecificMealCondition>        <OtherServiceInformation>○携帯電話番号[Mobile Phone Number]：00-2345-6789○ご要望・ご質問：N rooms N nightsのテストのため</OtherServiceInformation>    </BasicInformation>    <BasicRateInformation>        <RoomRateOrPersonalRate>PersonalRate</RoomRateOrPersonalRate>        <TaxServiceFee>IncludingServiceAndTax</TaxServiceFee>        <TotalAccommodationCharge>429135</TotalAccommodationCharge>    </BasicRateInformation>    <RoomAndGuestInformation>        <RoomAndGuestList>            <RoomInformation>                <RoomTypeCode>1</RoomTypeCode>                <RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName>                <PerRoomPaxCount>7</PerRoomPaxCount>                <RoomPaxMaleCount>1</RoomPaxMaleCount>                <RoomPaxFemaleCount>1</RoomPaxFemaleCount>                <RoomChildA70Count>1</RoomChildA70Count>                <RoomChildB50Count>2</RoomChildB50Count>                <RoomChildC30Count>1</RoomChildC30Count>                <RoomChildDNoneCount>1</RoomChildDNoneCount>            </RoomInformation>            <RoomRateInformation>                <RoomDate>2013-07-22</RoomDate>                <PerPaxRate>12000</PerPaxRate>                <PerChildA70Rate>12000</PerChildA70Rate>                <PerChildB50Rate>12000</PerChildB50Rate>                <PerChildC30Rate>3000</PerChildC30Rate>                <PerChildDRate>10000</PerChildDRate>                <TotalRoomHotSpringTax>0</TotalRoomHotSpringTax>                <TotalPerRoomServiceFee>0</TotalPerRoomServiceFee>            </RoomRateInformation>            <RoomRateInformation>                <RoomDate>2013-07-22</RoomDate>                <PerChildB50Rate>0</PerChildB50Rate>            </RoomRateInformation>        </RoomAndGuestList>        <RoomAndGuestList>            <RoomInformation>                <RoomTypeCode>1</RoomTypeCode>                <RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName>                <PerRoomPaxCount>2</PerRoomPaxCount>                <RoomPaxMaleCount>1</RoomPaxMaleCount>                <RoomPaxFemaleCount>1</RoomPaxFemaleCount>            </RoomInformation>            <RoomRateInformation>                <RoomDate>2013-07-22</RoomDate>                <PerPaxRate>12000</PerPaxRate>                <PerChildA70Rate>12000</PerChildA70Rate>                <PerChildB50Rate>12000</PerChildB50Rate>                <PerChildC30Rate>3000</PerChildC30Rate>                <PerChildDRate>10000</PerChildDRate>                <TotalRoomHotSpringTax>0</TotalRoomHotSpringTax>                <TotalPerRoomServiceFee>0</TotalPerRoomServiceFee>            </RoomRateInformation>            <RoomRateInformation>                <RoomDate>2013-07-22</RoomDate>                <PerChildB50Rate>0</PerChildB50Rate>            </RoomRateInformation>        </RoomAndGuestList>        <RoomAndGuestList>            <RoomInformation>                <RoomTypeCode>1</RoomTypeCode>                <RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName>                <PerRoomPaxCount>7</PerRoomPaxCount>                <RoomPaxMaleCount>1</RoomPaxMaleCount>                <RoomPaxFemaleCount>1</RoomPaxFemaleCount>                <RoomChildA70Count>1</RoomChildA70Count>                <RoomChildB50Count>2</RoomChildB50Count>                <RoomChildC30Count>1</RoomChildC30Count>                <RoomChildDNoneCount>1</RoomChildDNoneCount>            </RoomInformation>            <RoomRateInformation>                <RoomDate>2013-07-23</RoomDate>                <PerPaxRate>12000</PerPaxRate>                <PerChildA70Rate>12000</PerChildA70Rate>                <PerChildB50Rate>12000</PerChildB50Rate>                <PerChildC30Rate>3000</PerChildC30Rate>                <PerChildDRate>10000</PerChildDRate>                <TotalRoomHotSpringTax>0</TotalRoomHotSpringTax>                <TotalPerRoomServiceFee>0</TotalPerRoomServiceFee>            </RoomRateInformation>            <RoomRateInformation>                <RoomDate>2013-07-23</RoomDate>                <PerChildB50Rate>0</PerChildB50Rate>            </RoomRateInformation>        </RoomAndGuestList>        <RoomAndGuestList>            <RoomInformation>                <RoomTypeCode>1</RoomTypeCode>                <RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName>                <PerRoomPaxCount>2</PerRoomPaxCount>                <RoomPaxMaleCount>1</RoomPaxMaleCount>                <RoomPaxFemaleCount>1</RoomPaxFemaleCount>            </RoomInformation>            <RoomRateInformation>                <RoomDate>2013-07-23</RoomDate>                <PerPaxRate>12000</PerPaxRate>                <PerChildA70Rate>12000</PerChildA70Rate>                <PerChildB50Rate>12000</PerChildB50Rate>                <PerChildC30Rate>3000</PerChildC30Rate>                <PerChildDRate>10000</PerChildDRate>                <TotalRoomHotSpringTax>0</TotalRoomHotSpringTax>                <TotalPerRoomServiceFee>0</TotalPerRoomServiceFee>            </RoomRateInformation>            <RoomRateInformation>                <RoomDate>2013-07-23</RoomDate>                <PerChildB50Rate>0</PerChildB50Rate>            </RoomRateInformation>        </RoomAndGuestList>        <RoomAndGuestList>            <RoomInformation>                <RoomTypeCode>1</RoomTypeCode>                <RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName>                <PerRoomPaxCount>7</PerRoomPaxCount>                <RoomPaxMaleCount>1</RoomPaxMaleCount>                <RoomPaxFemaleCount>1</RoomPaxFemaleCount>                <RoomChildA70Count>1</RoomChildA70Count>                <RoomChildB50Count>2</RoomChildB50Count>                <RoomChildC30Count>1</RoomChildC30Count>                <RoomChildDNoneCount>1</RoomChildDNoneCount>            </RoomInformation>            <RoomRateInformation>                <RoomDate>2013-07-24</RoomDate>                <PerPaxRate>12000</PerPaxRate>                <PerChildA70Rate>12000</PerChildA70Rate>                <PerChildB50Rate>12000</PerChildB50Rate>                <PerChildC30Rate>3000</PerChildC30Rate>                <PerChildDRate>10000</PerChildDRate>                <TotalRoomHotSpringTax>0</TotalRoomHotSpringTax>                <TotalPerRoomServiceFee>0</TotalPerRoomServiceFee>            </RoomRateInformation>            <RoomRateInformation>                <RoomDate>2013-07-24</RoomDate>                <PerChildB50Rate>0</PerChildB50Rate>            </RoomRateInformation>        </RoomAndGuestList>        <RoomAndGuestList>            <RoomInformation>                <RoomTypeCode>1</RoomTypeCode>                <RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName>                <PerRoomPaxCount>1</PerRoomPaxCount>                <RoomPaxMaleCount>1</RoomPaxMaleCount>            </RoomInformation>            <RoomRateInformation>                <RoomDate>2013-07-24</RoomDate>                <PerPaxRate>12000</PerPaxRate>                <PerChildA70Rate>12000</PerChildA70Rate>                <PerChildB50Rate>12000</PerChildB50Rate>                <PerChildC30Rate>3000</PerChildC30Rate>                <PerChildDRate>10000</PerChildDRate>                <TotalRoomHotSpringTax>0</TotalRoomHotSpringTax>                <TotalPerRoomServiceFee>0</TotalPerRoomServiceFee>            </RoomRateInformation>            <RoomRateInformation>                <RoomDate>2013-07-24</RoomDate>                <PerChildB50Rate>0</PerChildB50Rate>            </RoomRateInformation>        </RoomAndGuestList>    </RoomAndGuestInformation>    <RisaplsInformation>        <RisaplsCommonInformation>            <Basic>                <SalesOfficeCompanyCode>88</SalesOfficeCompanyCode>                <TelegramDiv></TelegramDiv>                <RisaplsDataID></RisaplsDataID>                <RisaplsTelegramNumber></RisaplsTelegramNumber>                <TelegramData>予約通知 予約プロ---</TelegramData>                <PhoneNumber>01-2345-6789</PhoneNumber>                <Email>hiroyuki_morimoto@jinya-inn.com</Email>                <PostalCode>257-0001</PostalCode>                <Address>神奈川県秦野市鶴巻北</Address>                <TotalPaxManCount>4</TotalPaxManCount>                <BranchFaxNumber>052-262-8042</BranchFaxNumber>                <Version>2.0</Version>                <AccommodationId>X36969</AccommodationId>            </Basic>            <Allotment>                <AssignDiv>1</AssignDiv>                <GenderDiv>1</GenderDiv>                <HandleDiv>1</HandleDiv>                <RsvUserDiv>0</RsvUserDiv>                <UseDiv>0</UseDiv>            </Allotment>            <Option>                <OptionDate>2013-07-22</OptionDate>                <Name>特選会席料理</Name>                <OptionCount>4</OptionCount>                <OptionRate>12000</OptionRate>            </Option>            <Option>                <OptionDate>2013-07-22</OptionDate>                <Name>お土産（陣屋どらやき　6個入）</Name>                <OptionCount>1</OptionCount>                <OptionRate>960</OptionRate>            </Option>            <Option>                <OptionDate>2013-07-22</OptionDate>                <Name>お土産（やまと豚の桜味噌漬け 10枚入）</Name>                <OptionCount>3</OptionCount>                <OptionRate>1575</OptionRate>            </Option>            <Option>                <OptionDate>2013-07-22</OptionDate>                <Name>お土産（やまと豚の桜味噌漬け 20枚入）</Name>                <OptionCount>3</OptionCount>                <OptionRate>3150</OptionRate>            </Option>            <RoomAndRoomRateInformation>                <RoomInformation>                    <RoomTypeCode>1</RoomTypeCode>                    <RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName>                    <PerRoomPaxCount>7</PerRoomPaxCount>                    <RoomPaxMaleCount>1</RoomPaxMaleCount>                    <RoomPaxFemaleCount>1</RoomPaxFemaleCount>                    <RoomChildA70Count>1</RoomChildA70Count>                    <RoomChildB50Count>2</RoomChildB50Count>                    <RoomChildC30Count>1</RoomChildC30Count>                    <RoomChildDNoneCount>1</RoomChildDNoneCount>                    <RoomChildA70Request>小学生</RoomChildA70Request>                    <RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request>                    <RoomChildC30Request>小児（食事のみ）</RoomChildC30Request>                    <RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest>                    <RoomTypeAgent>88</RoomTypeAgent>                    <RoomFrame>--</RoomFrame>                    <NetRmTypeGroupCode>49</NetRmTypeGroupCode>                    <PlanGroupCode>---</PlanGroupCode>                </RoomInformation>                <RoomRateInformation>                    <RoomDate>2013-07-22</RoomDate>                    <PerPaxRate>12000</PerPaxRate>                    <PerChildA70Rate>12000</PerChildA70Rate>                    <PerChildB50Rate>12000</PerChildB50Rate>                    <PerChildC30Rate>3000</PerChildC30Rate>                    <PerChildDRate>10000</PerChildDRate>                    <TotalRoomHotSpringTax>0</TotalRoomHotSpringTax>                    <TotalPerRoomServiceFee>0</TotalPerRoomServiceFee>                    <PerMaleRate>12000</PerMaleRate>                    <PerFemaleRate>12000</PerFemaleRate>                    <RoomRatePaxMaleCount>1</RoomRatePaxMaleCount>                    <RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount>                    <RoomRateChildA70Count>1</RoomRateChildA70Count>                    <RoomRateChildB50Count>1</RoomRateChildB50Count>                    <RoomRateChildC30Count>1</RoomRateChildC30Count>                    <RoomRateChildDNoneCount>1</RoomRateChildDNoneCount>                    <RoomRateChildA70Request>小学生</RoomRateChildA70Request>                    <RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request>                    <RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request>                    <RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest>                </RoomRateInformation>                <RoomRateInformation>                    <RoomDate>2013-07-22</RoomDate>                    <PerChildB50Rate>0</PerChildB50Rate>                    <RoomRateChildB50Count>1</RoomRateChildB50Count>                    <RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request>                </RoomRateInformation>            </RoomAndRoomRateInformation>            <RoomAndRoomRateInformation>                <RoomInformation>                    <RoomTypeCode>1</RoomTypeCode>                    <RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName>                    <PerRoomPaxCount>7</PerRoomPaxCount>                    <RoomPaxMaleCount>1</RoomPaxMaleCount>                    <RoomPaxFemaleCount>1</RoomPaxFemaleCount>                    <RoomChildA70Count>1</RoomChildA70Count>                    <RoomChildB50Count>2</RoomChildB50Count>                    <RoomChildC30Count>1</RoomChildC30Count>                    <RoomChildDNoneCount>1</RoomChildDNoneCount>                    <RoomChildA70Request>小学生</RoomChildA70Request>                    <RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request>                    <RoomChildC30Request>小児（食事のみ）</RoomChildC30Request>                    <RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest>                    <RoomTypeAgent>88</RoomTypeAgent>                    <RoomFrame>--</RoomFrame>                    <NetRmTypeGroupCode>49</NetRmTypeGroupCode>                    <PlanGroupCode>---</PlanGroupCode>                </RoomInformation>                <RoomRateInformation>                    <RoomDate>2013-07-22</RoomDate>                    <PerPaxRate>12000</PerPaxRate>                    <PerChildA70Rate>12000</PerChildA70Rate>                    <PerChildB50Rate>12000</PerChildB50Rate>                    <PerChildC30Rate>3000</PerChildC30Rate>                    <PerChildDRate>10000</PerChildDRate>                    <TotalRoomHotSpringTax>0</TotalRoomHotSpringTax>                    <TotalPerRoomServiceFee>0</TotalPerRoomServiceFee>                    <PerMaleRate>12000</PerMaleRate>                    <PerFemaleRate>12000</PerFemaleRate>                    <RoomRatePaxMaleCount>1</RoomRatePaxMaleCount>                    <RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount>                    <RoomRateChildA70Count>1</RoomRateChildA70Count>                    <RoomRateChildB50Count>1</RoomRateChildB50Count>                    <RoomRateChildC30Count>1</RoomRateChildC30Count>                    <RoomRateChildDNoneCount>1</RoomRateChildDNoneCount>                    <RoomRateChildA70Request>小学生</RoomRateChildA70Request>                    <RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request>                    <RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request>                    <RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest>                </RoomRateInformation>                <RoomRateInformation>                    <RoomDate>2013-07-22</RoomDate>                    <PerChildB50Rate>0</PerChildB50Rate>                    <RoomRateChildB50Count>1</RoomRateChildB50Count>                    <RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request>                </RoomRateInformation>            </RoomAndRoomRateInformation>            <RoomAndRoomRateInformation>                <RoomInformation>                    <RoomTypeCode>1</RoomTypeCode>                    <RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName>                    <PerRoomPaxCount>7</PerRoomPaxCount>                    <RoomPaxMaleCount>1</RoomPaxMaleCount>                    <RoomPaxFemaleCount>1</RoomPaxFemaleCount>                    <RoomChildA70Count>1</RoomChildA70Count>                    <RoomChildB50Count>2</RoomChildB50Count>                    <RoomChildC30Count>1</RoomChildC30Count>                    <RoomChildDNoneCount>1</RoomChildDNoneCount>                    <RoomChildA70Request>小学生</RoomChildA70Request>                    <RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request>                    <RoomChildC30Request>小児（食事のみ）</RoomChildC30Request>                    <RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest>                    <RoomTypeAgent>88</RoomTypeAgent>                    <RoomFrame>--</RoomFrame>                    <NetRmTypeGroupCode>49</NetRmTypeGroupCode>                    <PlanGroupCode>---</PlanGroupCode>                </RoomInformation>                <RoomRateInformation>                    <RoomDate>2013-07-23</RoomDate>                    <PerPaxRate>12000</PerPaxRate>                    <PerChildA70Rate>12000</PerChildA70Rate>                    <PerChildB50Rate>12000</PerChildB50Rate>                    <PerChildC30Rate>3000</PerChildC30Rate>                    <PerChildDRate>10000</PerChildDRate>                    <TotalRoomHotSpringTax>0</TotalRoomHotSpringTax>                    <TotalPerRoomServiceFee>0</TotalPerRoomServiceFee>                    <PerMaleRate>12000</PerMaleRate>                    <PerFemaleRate>12000</PerFemaleRate>                    <RoomRatePaxMaleCount>1</RoomRatePaxMaleCount>                    <RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount>                    <RoomRateChildA70Count>1</RoomRateChildA70Count>                    <RoomRateChildB50Count>1</RoomRateChildB50Count>                    <RoomRateChildC30Count>1</RoomRateChildC30Count>                    <RoomRateChildDNoneCount>1</RoomRateChildDNoneCount>                    <RoomRateChildA70Request>小学生</RoomRateChildA70Request>                    <RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request>                    <RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request>                    <RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest>                </RoomRateInformation>                <RoomRateInformation>                    <RoomDate>2013-07-23</RoomDate>                    <PerChildB50Rate>0</PerChildB50Rate>                    <RoomRateChildB50Count>1</RoomRateChildB50Count>                    <RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request>                </RoomRateInformation>            </RoomAndRoomRateInformation>            <RoomAndRoomRateInformation>                <RoomInformation>                    <RoomTypeCode>1</RoomTypeCode>                    <RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName>                    <PerRoomPaxCount>7</PerRoomPaxCount>                    <RoomPaxMaleCount>1</RoomPaxMaleCount>                    <RoomPaxFemaleCount>1</RoomPaxFemaleCount>                    <RoomChildA70Count>1</RoomChildA70Count>                    <RoomChildB50Count>2</RoomChildB50Count>                    <RoomChildC30Count>1</RoomChildC30Count>                    <RoomChildDNoneCount>1</RoomChildDNoneCount>                    <RoomChildA70Request>小学生</RoomChildA70Request>                    <RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request>                    <RoomChildC30Request>小児（食事のみ）</RoomChildC30Request>                    <RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest>                    <RoomTypeAgent>88</RoomTypeAgent>                    <RoomFrame>--</RoomFrame>                    <NetRmTypeGroupCode>49</NetRmTypeGroupCode>                    <PlanGroupCode>---</PlanGroupCode>                </RoomInformation>                <RoomRateInformation>                    <RoomDate>2013-07-23</RoomDate>                    <PerPaxRate>12000</PerPaxRate>                    <PerChildA70Rate>12000</PerChildA70Rate>                    <PerChildB50Rate>12000</PerChildB50Rate>                    <PerChildC30Rate>3000</PerChildC30Rate>                    <PerChildDRate>10000</PerChildDRate>                    <TotalRoomHotSpringTax>0</TotalRoomHotSpringTax>                    <TotalPerRoomServiceFee>0</TotalPerRoomServiceFee>                    <PerMaleRate>12000</PerMaleRate>                    <PerFemaleRate>12000</PerFemaleRate>                    <RoomRatePaxMaleCount>1</RoomRatePaxMaleCount>                    <RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount>                    <RoomRateChildA70Count>1</RoomRateChildA70Count>                    <RoomRateChildB50Count>1</RoomRateChildB50Count>                    <RoomRateChildC30Count>1</RoomRateChildC30Count>                    <RoomRateChildDNoneCount>1</RoomRateChildDNoneCount>                    <RoomRateChildA70Request>小学生</RoomRateChildA70Request>                    <RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request>                    <RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request>                    <RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest>                </RoomRateInformation>                <RoomRateInformation>                    <RoomDate>2013-07-23</RoomDate>                    <PerChildB50Rate>0</PerChildB50Rate>                    <RoomRateChildB50Count>1</RoomRateChildB50Count>                    <RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request>                </RoomRateInformation>            </RoomAndRoomRateInformation>            <RoomAndRoomRateInformation>                <RoomInformation>                    <RoomTypeCode>1</RoomTypeCode>                    <RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName>                    <PerRoomPaxCount>7</PerRoomPaxCount>                    <RoomPaxMaleCount>1</RoomPaxMaleCount>                    <RoomPaxFemaleCount>1</RoomPaxFemaleCount>                    <RoomChildA70Count>1</RoomChildA70Count>                    <RoomChildB50Count>2</RoomChildB50Count>                    <RoomChildC30Count>1</RoomChildC30Count>                    <RoomChildDNoneCount>1</RoomChildDNoneCount>                    <RoomChildA70Request>小学生</RoomChildA70Request>                    <RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request>                    <RoomChildC30Request>小児（食事のみ）</RoomChildC30Request>                    <RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest>                    <RoomTypeAgent>88</RoomTypeAgent>                    <RoomFrame>--</RoomFrame>                    <NetRmTypeGroupCode>49</NetRmTypeGroupCode>                    <PlanGroupCode>---</PlanGroupCode>                </RoomInformation>                <RoomRateInformation>                    <RoomDate>2013-07-24</RoomDate>                    <PerPaxRate>12000</PerPaxRate>                    <PerChildA70Rate>12000</PerChildA70Rate>                    <PerChildB50Rate>12000</PerChildB50Rate>                    <PerChildC30Rate>3000</PerChildC30Rate>                    <PerChildDRate>10000</PerChildDRate>                    <TotalRoomHotSpringTax>0</TotalRoomHotSpringTax>                    <TotalPerRoomServiceFee>0</TotalPerRoomServiceFee>                    <PerMaleRate>12000</PerMaleRate>                    <PerFemaleRate>12000</PerFemaleRate>                    <RoomRatePaxMaleCount>1</RoomRatePaxMaleCount>                    <RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount>                    <RoomRateChildA70Count>1</RoomRateChildA70Count>                    <RoomRateChildB50Count>1</RoomRateChildB50Count>                    <RoomRateChildC30Count>1</RoomRateChildC30Count>                    <RoomRateChildDNoneCount>1</RoomRateChildDNoneCount>                    <RoomRateChildA70Request>小学生</RoomRateChildA70Request>                    <RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request>                    <RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request>                    <RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest>                </RoomRateInformation>                <RoomRateInformation>                    <RoomDate>2013-07-24</RoomDate>                    <PerChildB50Rate>0</PerChildB50Rate>                    <RoomRateChildB50Count>1</RoomRateChildB50Count>                    <RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request>                </RoomRateInformation>            </RoomAndRoomRateInformation>            <RoomAndRoomRateInformation>                <RoomInformation>                    <RoomTypeCode>1</RoomTypeCode>                    <RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName>                    <PerRoomPaxCount>7</PerRoomPaxCount>                    <RoomPaxMaleCount>1</RoomPaxMaleCount>                    <RoomPaxFemaleCount>1</RoomPaxFemaleCount>                    <RoomChildA70Count>1</RoomChildA70Count>                    <RoomChildB50Count>2</RoomChildB50Count>                    <RoomChildC30Count>1</RoomChildC30Count>                    <RoomChildDNoneCount>1</RoomChildDNoneCount>                    <RoomChildA70Request>小学生</RoomChildA70Request>                    <RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request>                    <RoomChildC30Request>小児（食事のみ）</RoomChildC30Request>                    <RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest>                    <RoomTypeAgent>88</RoomTypeAgent>                    <RoomFrame>--</RoomFrame>                    <NetRmTypeGroupCode>49</NetRmTypeGroupCode>                    <PlanGroupCode>---</PlanGroupCode>                </RoomInformation>                <RoomRateInformation>                    <RoomDate>2013-07-24</RoomDate>                    <PerPaxRate>12000</PerPaxRate>                    <PerChildA70Rate>12000</PerChildA70Rate>                    <PerChildB50Rate>12000</PerChildB50Rate>                    <PerChildC30Rate>3000</PerChildC30Rate>                    <PerChildDRate>10000</PerChildDRate>                    <TotalRoomHotSpringTax>0</TotalRoomHotSpringTax>                    <TotalPerRoomServiceFee>0</TotalPerRoomServiceFee>                    <PerMaleRate>12000</PerMaleRate>                    <PerFemaleRate>12000</PerFemaleRate>                    <RoomRatePaxMaleCount>1</RoomRatePaxMaleCount>                    <RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount>                    <RoomRateChildA70Count>1</RoomRateChildA70Count>                    <RoomRateChildB50Count>1</RoomRateChildB50Count>                    <RoomRateChildC30Count>1</RoomRateChildC30Count>                    <RoomRateChildDNoneCount>1</RoomRateChildDNoneCount>                    <RoomRateChildA70Request>小学生</RoomRateChildA70Request>                    <RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request>                    <RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request>                    <RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest>                </RoomRateInformation>                <RoomRateInformation>                    <RoomDate>2013-07-24</RoomDate>                    <PerChildB50Rate>0</PerChildB50Rate>                    <RoomRateChildB50Count>1</RoomRateChildB50Count>                    <RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request>                </RoomRateInformation>            </RoomAndRoomRateInformation>            <OtherInfo>                <GuestRequest>○携帯電話番号[Mobile Phone Number]：00-2345-6789○ご要望・ご質問：N rooms N nightsのテストのため</GuestRequest>            </OtherInfo>        </RisaplsCommonInformation>        <AgentNativeInformation>            <Extend>                <AmountClaimed>429135</AmountClaimed>            </Extend>        </AgentNativeInformation>    </RisaplsInformation></AllotmentBookingReport>';
    	String dateKey = System.now().format('yyMMddHHMMssSSS');
    	Attachment newAttach = new Attachment(
									ParentId = parentId,
									Name = 'TAPDATA_' + dateKey + '2_Test.xml', 
									ContentType = 'text/xml',
									Body = Blob.valueOf(infoTravelXML)
								);
		insert newAttach;
    }
    private static void createCommonAcc(){
    	
        JMST__c taxMst =  TestCommon.createTaxMst();
        // 室単料　会計商品
        AccountMaster__c shitulyoItem = new AccountMaster__c(
           Name = CommConst.APPOPTION_ROOMPRICE_PRODNAME,
           ActionType__c = CommConst.PROD_ACTION_TYPE_RP,
           jmstRef__c = taxMst.Id,
           StsTaxfee__c = '0',
           Field3__c = '100999',         // 商品コード
           Field5__c = 1050,
           ServiceRate__c = 10,
           SpecialTax__c = 100
        );
        insert shitulyoItem;
        
        // 入湯料　会計商品
        AccountMaster__c nyuutouItem = new AccountMaster__c(
           Name = '入湯料' + CommUtils.getRandom(9),
           jmstRef__c = taxMst.Id,
           StsTaxfee__c = '0',
           Field3__c = '5041',         // 商品コード
           Field5__c = 150,
           ServiceRate__c = 10,
           SpecialTax__c = 100
        );
        insert nyuutouItem;
        
        // サービス料　会計商品
        AccountMaster__c serviceItem = new AccountMaster__c(
           Name = 'サービス料' + CommUtils.getRandom(9),
           jmstRef__c = taxMst.Id,
           StsTaxfee__c = '0',
           Field3__c = 'S0000',         // 商品コード
           Field5__c = 1550,
           ServiceRate__c = 10,
           SpecialTax__c = 100
        );
        insert serviceItem;
        createConfigBill();
    }
    
    private static Plan__c createPlanHadHoomNoZero(){
    	JMST__c taxMst =  TestCommon.createTaxMst();
    	Plan__c plan = new Plan__c();
    	plan.name = 'テストプランデータ' + CommUtils.getRandom(5);
    	plan.PlanNo__c = CommUtils.getRandom(10);
    	plan.Price__c = 11200;
    	plan.PackageCode__c = '3333';
    	plan.JmstRef__c = taxMst.Id;
    	insert plan;
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(3);
        productLst[2].Name = CommConst.APPOPTION_ROOMPRICE_PRODNAME;
        productLst[2].ActionType__c = CommConst.PROD_ACTION_TYPE_RP;
        update productLst; 
        
        ApexPages.StandardController contrl = new ApexPages.StandardController(plan);
        PlanProductSetup ctrl = new PlanProductSetup(contrl);
        List<PlanProductSetup.PlanDetail> planDeLst = ctrl.planDetailList;
        planDeLst[0].productNm = productLst[0].Name;
        planDeLst[0].sobj.AccountMasterRef__c = productLst[0].Id;
        planDeLst[0].sobj.Price__c = 10000;
        planDeLst[0].sobj.taxRate__c = taxMst.taxRate__c;
        planDeLst[1].productNm = productLst[1].Name;
        planDeLst[1].sobj.AccountMasterRef__c = productLst[1].Id;
        planDeLst[1].sobj.Price__c = 200;
        planDeLst[1].sobj.taxRate__c = taxMst.taxRate__c;
        planDeLst[2].productNm = productLst[2].Name;
        planDeLst[2].sobj.AccountMasterRef__c = productLst[2].Id;
        planDeLst[2].sobj.Price__c = 1000;
        planDeLst[2].sobj.taxRate__c = taxMst.taxRate__c;
        ctrl.savePlanDetail();
    	return plan;
    }
    private static Plan__c createPlanHadHoomZero(String packageCode){
    	JMST__c taxMst =  TestCommon.createTaxMst();
    	if(CommUtils.isBlank(packageCode)) packageCode = '3333';
    	Plan__c plan = new Plan__c();
    	plan.name = 'テストプランデータ' + CommUtils.getRandom(5);
    	plan.PlanNo__c = CommUtils.getRandom(10);
    	plan.Price__c = 11500;
    	plan.PackageCode__c = '3333';
    	plan.JmstRef__c = taxMst.Id;
    	insert plan;
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(5);
        productLst[2].Name = CommConst.APPOPTION_ROOMPRICE_PRODNAME;
        productLst[2].ActionType__c = CommConst.PROD_ACTION_TYPE_RP;
        update productLst; 
        
        ApexPages.StandardController contrl = new ApexPages.StandardController(plan);
        PlanProductSetup ctrl = new PlanProductSetup(contrl);
        List<PlanProductSetup.PlanDetail> planDeLst = ctrl.planDetailList;
        planDeLst[0].productNm = productLst[0].Name;
        planDeLst[0].sobj.AccountMasterRef__c = productLst[0].Id;
        planDeLst[0].sobj.Price__c = 1000;
        planDeLst[0].sobj.taxRate__c = taxMst.taxRate__c;
        planDeLst[1].productNm = productLst[1].Name;
        planDeLst[1].sobj.AccountMasterRef__c = productLst[1].Id;
        planDeLst[1].sobj.Price__c = 1500;
        planDeLst[1].sobj.taxRate__c = taxMst.taxRate__c;
        planDeLst[2].productNm = productLst[2].Name;
        planDeLst[2].sobj.AccountMasterRef__c = productLst[2].Id;
        planDeLst[2].sobj.Price__c = 0;
        planDeLst[2].sobj.taxRate__c = taxMst.taxRate__c;
        planDeLst[3].productNm = productLst[3].Name;
        planDeLst[3].sobj.AccountMasterRef__c = productLst[3].Id;
        planDeLst[3].sobj.Price__c = 300;
        planDeLst[3].sobj.taxRate__c = taxMst.taxRate__c;
        planDeLst[4].productNm = productLst[4].Name;
        planDeLst[4].sobj.AccountMasterRef__c = productLst[4].Id;
        planDeLst[4].sobj.Price__c = 500;
        planDeLst[4].sobj.taxRate__c = taxMst.taxRate__c;
        ctrl.savePlanDetail();
    	return plan;
    } 
    
    static testMethod void myUnitTest_roomRate() {
        // TO DO: implement unit test
        createConfigDoc();
         //連絡結果　予約取り込待ち
        CooperationResult__c coo = TestCommon.createTaLeadImportAndImpotNG('');
        TypeOfRooms__c roomType = TestCommon.createTypeOfRoom();
        TypeOfRooms__c roomType1 = TestCommon.createTypeOfRoom();
        TestCommon.createRooms(1,roomType.Id);
        createPlanHadHoomZero('P00000003');
        createCommonAcc();
        createSyncXml(coo.id,'NewBookReport',roomType.RoomTypeCode__c);
        coo.shopCode__c = '';
        update coo;
        
        Test.startTest();
    	Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true));
    	TA_LeadSyncProcessBatch batch = new TA_LeadSyncProcessBatch();    
		ID batchprocessid = Database.executeBatch(batch,2);
        Test.stopTest(); 
    }
    static testMethod void myUnitTest_roomRate_upd() {
        // TO DO: implement unit test
        createConfigDoc();
         //連絡結果　予約取り込待ち
        CooperationResult__c coo = TestCommon.createTaLeadImportAndImpotNG('');
        TypeOfRooms__c roomType = TestCommon.createTypeOfRoom();
        TypeOfRooms__c roomType1 = TestCommon.createTypeOfRoom();
        List<Room__c> rooms = TestCommon.createRooms(2,roomType1.Id);
        // 部屋１は故障部屋に設定する
        TestCommon.createBadRoom(rooms[0].Id, Date.newInstance(2016,1,1));
        createPlanHadHoomZero('P00000003');
        createCommonAcc();
        createSyncXml(coo.id,'ModificationReport',roomType.RoomTypeCode__c);
        coo.shopCode__c = '';
        update coo;
        
        Test.startTest();
    	Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true));
    	TA_LeadSyncProcessBatch batch = new TA_LeadSyncProcessBatch();    
		ID batchprocessid = Database.executeBatch(batch,2);
        Test.stopTest(); 
    }
    static testMethod void myUnitTest_roomRate_cancel() {
        // TO DO: implement unit test
        createConfigDoc();
         //連絡結果　予約取り込待ち
        CooperationResult__c coo = TestCommon.createTaLeadImportAndImpotNG('');
        TypeOfRooms__c roomType = TestCommon.createTypeOfRoom();
        TypeOfRooms__c roomType1 = TestCommon.createTypeOfRoom();
        createPlanHadHoomZero('P00000003');
        createCommonAcc();
        createSyncXml(coo.id,'CancellationReport',roomType.RoomTypeCode__c);
        coo.shopCode__c = '';
        update coo;
        
        Test.startTest();
    	Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true));
    	TA_LeadSyncProcessBatch batch = new TA_LeadSyncProcessBatch();    
		ID batchprocessid = Database.executeBatch(batch,2);
        Test.stopTest(); 
    }
    private static void createSyncXml(String parentId, String actionType,String roomTypeCd){
    	String infoTravelXML = '<AllotmentBookingReport><TransactionType>    <DataFrom>FromTravelAgency</DataFrom>    <DataClassification>'+actionType+'</DataClassification>    <BookingDataID>00000688615-B-20110629224000</BookingDataID>    <SystemDate>2016-05-27</SystemDate>    <SystemTime>19:36:50</SystemTime></TransactionType><AccommodationInformation>    <AccommodationName>まごころの宿PMS連携テスト</AccommodationName>    <AccommodationCode>01</AccommodationCode></AccommodationInformation><SalesOfficeInformation>    <SalesOfficeCompanyCode>02</SalesOfficeCompanyCode>    <SalesOfficeCompanyName>isaizu</SalesOfficeCompanyName>    <SalesOfficeName>b</SalesOfficeName>    <SalesOfficeCode>0000002</SalesOfficeCode>    <SalesOfficePersonInCharge>i</SalesOfficePersonInCharge>    <SalesOfficePhoneNumber>093</SalesOfficePhoneNumber></SalesOfficeInformation><BasicInformation>    <TravelAgencyBookingNumber>0XA2X8GJ</TravelAgencyBookingNumber>    <TravelAgencyBookingDate>2011-06-29</TravelAgencyBookingDate>    <TravelAgencyBookingTime>22:40:00</TravelAgencyBookingTime>    <GuestOrGroupNameSingleByte>ﾋｶｸ ｼﾞﾛｳ</GuestOrGroupNameSingleByte>    <GuestOrGroupNameDoubleByte>ひかく　じろう</GuestOrGroupNameDoubleByte>    <GuestOrGroupNameKanjiName>比較　二郎</GuestOrGroupNameKanjiName>    <CheckInDate>2016-05-01</CheckInDate>    <CheckInTime>23:30</CheckInTime>    <CheckOutDate>2016-05-02</CheckOutDate>    <Nights>1</Nights>    <PackagePlanName>☆★ダミープラン★☆</PackagePlanName>    <PackagePlanCode>P00000003</PackagePlanCode>            <OtherServiceInformation>備考</OtherServiceInformation></BasicInformation><BasicRateInformation>    <RoomRateOrPersonalRate>PersonalRate</RoomRateOrPersonalRate>    <TaxServiceFee>IncludingServiceAndTax</TaxServiceFee>    <Payment>事前カード決済</Payment>    <TotalAccommodationCharge>4500</TotalAccommodationCharge></BasicRateInformation> <RoomAndGuestInformation>    <RoomAndGuestList>    <RoomInformation>                   <RoomTypeCode>'+roomTypeCd+'</RoomTypeCode>      <RoomTypeName>【禁煙有線LAN】セミダブル</RoomTypeName>      <PerRoomPaxCount>2</PerRoomPaxCount>      <RoomPaxMaleCount>2</RoomPaxMaleCount>      <RoomPaxFemaleCount>1</RoomPaxFemaleCount>      <RoomChildA70Count>2</RoomChildA70Count>      <RoomChildB50Count>3</RoomChildB50Count>      <RoomChildC30Count>4</RoomChildC30Count>      <RoomChildDNoneCount>5</RoomChildDNoneCount>      <RoomChildOtherCount>6</RoomChildOtherCount>          </RoomInformation>    <RoomRateInformation>        <RoomDate>2016-05-01</RoomDate>        <PerPaxRate>10000</PerPaxRate>        <PerChildA70Rate>8000</PerChildA70Rate>        <PerChildB50Rate>6000</PerChildB50Rate>        <PerChildC30Rate>3000</PerChildC30Rate>        <PerChildDRate>1000</PerChildDRate>        <PerChildOtherRate>0</PerChildOtherRate>        <TotalPerRoomRate>13569</TotalPerRoomRate>    </RoomRateInformation>              <GuestInformation>      <GuestInformationList>        <GuestNameSingleByte>ﾋｶｸ ﾀﾛｳ</GuestNameSingleByte>        <GuestSurName>ひかく　たろう</GuestSurName>        <GuestKanjiName>比較　太郎</GuestKanjiName>        <GuestPhoneNumber>03-3473-4345</GuestPhoneNumber>        <GuestEmail>test@temairazu.com</GuestEmail>        <GuestStateProvidence>東京都渋谷区恵比寿1-21-3</GuestStateProvidence>        <GuestPostalCode>000-0000</GuestPostalCode>      </GuestInformationList>    </GuestInformation>  </RoomAndGuestList>   </RoomAndGuestInformation> <Member>  <UserName>比較　二郎</UserName>  <UserKana>ﾋｶｸ ｼﾞﾛｳ</UserKana>  <UserTel>03-3473-4345</UserTel>  <UserMailAddr>test@temairazu.com</UserMailAddr>  <UserZip>000-0000</UserZip>  <UserAddr>東京都渋谷区恵比寿1-21-3</UserAddr>  <UserCorp></UserCorp>  <UserGivinPoints>0</UserGivinPoints>  <UserUsePoints>0</UserUsePoints>  <TotalAccommodationDecleasePoints>4500</TotalAccommodationDecleasePoints>  <AmountClaimed>4500</AmountClaimed></Member></AllotmentBookingReport>';
    	String dateKey = System.now().format('yyMMddHHMMssSSS');
    	Attachment newAttach = new Attachment(
									ParentId = parentId,
									Name = 'TAPDATA_' + dateKey + '1_Test.xml', 
									ContentType = 'text/xml',
									Body = Blob.valueOf(infoTravelXML)
								);
		insert newAttach;
    }
    private static Document createAllConfigDoc(){
        String configXml = '<?xml version="1.0" encoding="UTF-8"?><root><COMMON><STOCKINTERVAL>60</STOCKINTERVAL><STOCKDELETEVAL>-60</STOCKDELETEVAL><LEADINTERVAL>60</LEADINTERVAL><LEADDELETEVAL>-60</LEADDELETEVAL><SERVICE_URL_UP>https://sv2.temairazu.net/pmsup</SERVICE_URL_UP><SERVICE_URL>https://sv2.temairazu.net/pms/</SERVICE_URL><STOCK_RESTORE_START_DATE>2016-05-27</STOCK_RESTORE_START_DATE></COMMON><SHOP><SHOPCODE></SHOPCODE><APPCONFIG><SYSTEMID></SYSTEMID><USERID>pms-test</USERID><PASSWORD>temairazu</PASSWORD><UCACTISSYNC>TRUE</UCACTISSYNC><ROOMAUTOASSIGN>TRUE</ROOMAUTOASSIGN><ROOMSORT>ASC</ROOMSORT></APPCONFIG><ACCOUNTCONFIG><NYUUTOUACCOUNT>5041</NYUUTOUACCOUNT><SERVICEACCOUNT>SR0001</SERVICEACCOUNT><CHGROOMTYPE>true</CHGROOMTYPE><PAYMEDIATOLASTDAY>true</PAYMEDIATOLASTDAY><CONTACT_ALWAYS_NEW>true</CONTACT_ALWAYS_NEW><RESET_ESTITEMS>true</RESET_ESTITEMS></ACCOUNTCONFIG><PLANCODE_CONVERT><AGT AGTCODE="02"><CONVERT><AGTPACKAGECODE>A268Q,234,235</AGTPACKAGECODE><SFPLANNO>00002911</SFPLANNO></CONVERT></AGT></PLANCODE_CONVERT><PAYMENT_CONVERTS><POINT_CONVERT PAYKBN="カード決済"><CONVERT AGTCODE="80">M90201</CONVERT></POINT_CONVERT><PAYMENT_CONVERT PAYKBN="カード決済"><CONVERT AGTCODE="80">M90201</CONVERT></PAYMENT_CONVERT></PAYMENT_CONVERTS><PRE_PAYMENT_DEF>   <CRAD>事前カード決済</CRAD><CREDIT>一括精算,パッケージ予約</CREDIT></PRE_PAYMENT_DEF><CHILD_PLAN_CONVERT>	<MATCH RATE="70" PRICE="5000">00000702</MATCH><MATCH RATE="50">00000806</MATCH>	<MATCH PRICE="3000">00000806</MATCH><MATCH RATE="30">00000807</MATCH>	<MATCH RATE="10">00000805</MATCH></CHILD_PLAN_CONVERT></SHOP></root>';
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'Ta2wayServiceConfigXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(configXml);
    	insert item;
    	return item;
    }
}