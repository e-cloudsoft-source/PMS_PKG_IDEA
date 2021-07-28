@isTest
private class TA_ServiceCtrlTest {
    // 部屋情報取得
    static testMethod void callRoomTypeMasterSearchService() {
    	
        TestCommon.createTa2WayConfigDoc();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl());
      	TA_ServiceCtrl ctrl = new TA_ServiceCtrl();
      	      	      	
	    TA_RoomTypeInfoItem rep = ctrl.callRoomTypeMasterSearchService('');
	    Test.stopTest();
	    System.assertEquals(rep.commonResponse.isSuccess, true);
	
    }
    static testMethod void callRoomTypeMasterSearchService_Err() {
    	
        TestCommon.createTa2WayConfigDoc();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true, true));
      	TA_ServiceCtrl ctrl = new TA_ServiceCtrl();
      	      	      	
	    TA_RoomTypeInfoItem rep = ctrl.callRoomTypeMasterSearchService('');
	    Test.stopTest();
	    System.assertEquals(rep.commonResponse.isSuccess, false);
	    
    }
    static testMethod void callRoomTypeMasterSearchService_Err2() {
    	
        TestCommon.createTa2WayConfigDoc();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true, false));
      	TA_ServiceCtrl ctrl = new TA_ServiceCtrl();
      	      	      	
	    TA_RoomTypeInfoItem rep = ctrl.callRoomTypeMasterSearchService('');
	    Test.stopTest();
	    System.assertEquals(rep.commonResponse.isSuccess, false);
	    
    }
	// 在庫取得
	static testMethod void callStockSearchService() {
		TestCommon.createTa2WayConfigDoc();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl());
      	TA_ServiceCtrl ctrl = new TA_ServiceCtrl();
      	list<TA_RoomStockInfoGetItem.RoomStockInfo> stockInfLst = new list<TA_RoomStockInfoGetItem.RoomStockInfo> ();
      	TA_RoomStockInfoGetItem.RoomStockInfo room = new TA_RoomStockInfoGetItem.RoomStockInfo(); 
      	room.roomTypeCode = 'SGL';
		room.stockDate = system.NOW().format('yyyy-MM-dd');
		room.remainingCount = 're';
		room.salesClosed = 'sa';
		room.errorCode = 'er';
		room.errorMessage = 'err';
		stockInfLst.add(room);      	      	
		TA_RoomStockInfoGetItem rep = ctrl.callStockSearchService('',stockInfLst); 
	    Test.stopTest();
	    System.assertEquals(rep.commonResponse.isSuccess, true);
	}
	// 在庫取得
	static testMethod void callStockSearchService_Err() {
		TestCommon.createTa2WayConfigDoc();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true,true));
      	TA_ServiceCtrl ctrl = new TA_ServiceCtrl();
      	list<TA_RoomStockInfoGetItem.RoomStockInfo> stockInfLst = new list<TA_RoomStockInfoGetItem.RoomStockInfo> ();
      	TA_RoomStockInfoGetItem.RoomStockInfo room = new TA_RoomStockInfoGetItem.RoomStockInfo(); 
      	room.roomTypeCode = 'SGL';
		room.stockDate = system.NOW().format('yyyy-MM-dd');
		room.remainingCount = 're';
		room.salesClosed = 'sa';
		room.errorCode = 'er';
		room.errorMessage = 'err';
		stockInfLst.add(room);      	      	
		TA_RoomStockInfoGetItem rep = ctrl.callStockSearchService('',stockInfLst); 
	    Test.stopTest();
	    System.assertEquals(rep.commonResponse.isSuccess, false);
	}
	static testMethod void callStockSearchService_Err2() {
		TestCommon.createTa2WayConfigDoc();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true,false));
      	TA_ServiceCtrl ctrl = new TA_ServiceCtrl();
      	list<TA_RoomStockInfoGetItem.RoomStockInfo> stockInfLst = new list<TA_RoomStockInfoGetItem.RoomStockInfo> ();
      	TA_RoomStockInfoGetItem.RoomStockInfo room = new TA_RoomStockInfoGetItem.RoomStockInfo(); 
      	room.roomTypeCode = 'SGL';
		room.stockDate = system.NOW().format('yyyy-MM-dd');
		room.remainingCount = 're';
		room.salesClosed = 'sa';
		room.errorCode = 'er';
		room.errorMessage = 'err';
		stockInfLst.add(room);      	      	
		TA_RoomStockInfoGetItem rep = ctrl.callStockSearchService('',stockInfLst); 
	    Test.stopTest();
	    System.assertEquals(rep.commonResponse.isSuccess, false);
	}
	// 在庫更新
	static testMethod void callStockAdjustmentService() {
		TestCommon.createTa2WayConfigDoc();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl());
      	TA_ServiceCtrl ctrl = new TA_ServiceCtrl();
      	list<TA_RoomStockInfoUpdItem.RoomStockInfo> stockInfLst = new list<TA_RoomStockInfoUpdItem.RoomStockInfo> ();
      	TA_RoomStockInfoUpdItem.RoomStockInfo room = new TA_RoomStockInfoUpdItem.RoomStockInfo(); 
      	room.roomTypeCode = 'SGL';
		room.stockDate = system.NOW().format('yyyy-MM-dd');
		room.roomStockNum = '5';
     	room.salesClosed = '22';
     	room.isForce = 'A';
		stockInfLst.add(room);      	      	
		TA_RoomStockInfoUpdItem rep = ctrl.callStockAdjustmentService('',stockInfLst); 
	    Test.stopTest();
	    System.assertEquals(rep.commonResponse.isSuccess, true);

	}
	// 在庫更新
	static testMethod void callStockAdjustmentService_Err() {
		TestCommon.createTa2WayConfigDoc();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true, true));
      	TA_ServiceCtrl ctrl = new TA_ServiceCtrl();
      	list<TA_RoomStockInfoUpdItem.RoomStockInfo> stockInfLst = new list<TA_RoomStockInfoUpdItem.RoomStockInfo> ();
      	TA_RoomStockInfoUpdItem.RoomStockInfo room = new TA_RoomStockInfoUpdItem.RoomStockInfo(); 
      	room.roomTypeCode = 'SGL';
		room.stockDate = system.NOW().format('yyyy-MM-dd');
		room.roomStockNum = '5';
     	room.salesClosed = '22';
     	room.isForce = 'A';
		stockInfLst.add(room);      	      	
		TA_RoomStockInfoUpdItem rep = ctrl.callStockAdjustmentService('',stockInfLst); 
	    Test.stopTest();
	    System.assertEquals(rep.commonResponse.isSuccess, false);

	}
	static testMethod void callStockAdjustmentService_Err2() {
		TestCommon.createTa2WayConfigDoc();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true, false));
      	TA_ServiceCtrl ctrl = new TA_ServiceCtrl();
      	list<TA_RoomStockInfoUpdItem.RoomStockInfo> stockInfLst = new list<TA_RoomStockInfoUpdItem.RoomStockInfo> ();
      	TA_RoomStockInfoUpdItem.RoomStockInfo room = new TA_RoomStockInfoUpdItem.RoomStockInfo(); 
      	room.roomTypeCode = 'SGL';
		room.stockDate = system.NOW().format('yyyy-MM-dd');
		room.roomStockNum = '5';
     	room.salesClosed = '22';
     	room.isForce = 'A';
		stockInfLst.add(room);      	      	
		TA_RoomStockInfoUpdItem rep = ctrl.callStockAdjustmentService('',stockInfLst); 
	    Test.stopTest();
	    System.assertEquals(rep.commonResponse.isSuccess, false);

	}
	// 予約通知
	static testMethod void callBookingInfoOutputService() {
		
		TestCommon.createTa2WayConfigDoc();
		
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl());
      	TA_ServiceCtrl ctrl = new TA_ServiceCtrl();
		TA_BookingInfoOutputInfoItem rep = ctrl.callBookingInfoOutputService(''); 
	    Test.stopTest();
	    //System.assertEquals(rep.isSuccess, true);

	}
	static testMethod void callBookingInfoOutputService_Err() {
		
		TestCommon.createTa2WayConfigDoc();
		
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true, true));
      	TA_ServiceCtrl ctrl = new TA_ServiceCtrl();
		TA_BookingInfoOutputInfoItem rep = ctrl.callBookingInfoOutputService(''); 
	    Test.stopTest();
	   System.assertEquals(rep.commonResponse.isSuccess, false);

	}
	static testMethod void callBookingInfoOutputService_Err2() {
		
		TestCommon.createTa2WayConfigDoc();
		
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true, false));
      	TA_ServiceCtrl ctrl = new TA_ServiceCtrl();
		TA_BookingInfoOutputInfoItem rep = ctrl.callBookingInfoOutputService(''); 
	    Test.stopTest();
		System.assertEquals(rep.commonResponse.isSuccess, false);

	}
	// 予約通知完了機能
    static testMethod void callOutputCompleteService() {
    	
        TestCommon.createTa2WayConfigDoc();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl());
      	TA_ServiceCtrl ctrl = new TA_ServiceCtrl();
      	      	      	
	    TA_OutputCompleteInfoItem rep = ctrl.callOutputCompleteService('','0000000001');
	    Test.stopTest();
	    System.assertEquals(rep.commonResponse.isSuccess, true);
    }
    static testMethod void callOutputCompleteService_Err() {
    	
        TestCommon.createTa2WayConfigDoc();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true, true));
      	TA_ServiceCtrl ctrl = new TA_ServiceCtrl();
      	      	      	
	    TA_OutputCompleteInfoItem rep = ctrl.callOutputCompleteService('','0000000001');
	    Test.stopTest();
	    System.assertEquals(rep.commonResponse.isSuccess, false);
    }
    static testMethod void callOutputCompleteService_Err2() {
    	
        TestCommon.createTa2WayConfigDoc();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true, false));
      	TA_ServiceCtrl ctrl = new TA_ServiceCtrl();
      	      	      	
	    TA_OutputCompleteInfoItem rep = ctrl.callOutputCompleteService('','0000000001');
	    Test.stopTest();
	    System.assertEquals(rep.commonResponse.isSuccess, false);
    }
    /*
	// エージェント情報取得
	static testMethod void callAgtListService() {
		TestCommon.createTa2WayConfigDoc();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl());
      	TA_ServiceCtrl ctrl = new TA_ServiceCtrl();
      	      	      	
	    TA_OTAInfoItem rep = ctrl.callAgtListService('');
	    Test.stopTest();
	    //System.assertEquals(rep.commonResponse.isSuccess, true);
	}*/
	// プラン情報取得
	static testMethod void callNetPlanMasterSearchService() {
		TestCommon.createTa2WayConfigDoc();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl());
      	TA_ServiceCtrl ctrl = new TA_ServiceCtrl();
      	      	      	
	    TA_PlanInfoItem rep = ctrl.callNetPlanMasterSearchService('');
	    Test.stopTest();
	    System.assertEquals(rep.commonResponse.isSuccess, true);

	}
	static testMethod void callNetPlanMasterSearchService_Err() {
		TestCommon.createTa2WayConfigDoc();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true, true));
      	TA_ServiceCtrl ctrl = new TA_ServiceCtrl();
      	      	      	
	    TA_PlanInfoItem rep = ctrl.callNetPlanMasterSearchService('');
	    Test.stopTest();
	    System.assertEquals(rep.commonResponse.isSuccess, false);

	}
	static testMethod void callNetPlanMasterSearchService_Err2() {
		TestCommon.createTa2WayConfigDoc();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true, false));
      	TA_ServiceCtrl ctrl = new TA_ServiceCtrl();
      	      	      	
	    TA_PlanInfoItem rep = ctrl.callNetPlanMasterSearchService('');
	    Test.stopTest();
	    System.assertEquals(rep.commonResponse.isSuccess, false);

	}
	
	static testMethod void planCase() {
		TestCommon.createTa2WayConfigDoc();
		System.assertEquals([select Id from Document where Name = 'Ta2wayServiceConfigXml'].size(), 1);
      Test.startTest(); 
      Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl());
      String rsMsg = TA_MasterSyncService.importPlanMaster('',false);
      system.assertEquals(rsMsg,'取込正常に完了しました。');
      Test.stopTest();
    }
	static testMethod void OtherCase() {
		TestCommon.createTa2WayConfigDoc();
		
		Test.startTest(); 
		Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl());
		String a = TA_ServiceCtrl.getManagerDataId('00000376572');
		String b = 'TA_00000376573';
		System.assertEquals(TA_ServiceCtrl.setManagerDataId(a), '00000376572');
		System.assertEquals(TA_ServiceCtrl.setManagerDataId(b), '00000376573');
		Test.stopTest();
    }
}