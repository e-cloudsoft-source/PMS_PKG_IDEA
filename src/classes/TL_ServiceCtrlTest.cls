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
private class TL_ServiceCtrlTest {

    static testMethod void case001() {
    	
        TestCommon.createTl2WayConfigDoc();
        
        Test.startTest();
        Test.setMock(WebServiceMock.class, new TestCommonMockImpl());
      	TL_ServiceCtrl ctrl = new TL_ServiceCtrl();
      	
      	TL_NetRoomTypeMasterSearchService.extractionCondition cond = new TL_NetRoomTypeMasterSearchService.extractionCondition();
      	      	
	    TL_NetRoomTypeMasterSearchService.rmTypeMstSearchForNetResponse rep = ctrl.callNetRoomTypeMasterSearchService('',cond);
	    Test.stopTest();
	    System.assertEquals(rep.commonResponse.isSuccess, true);
	    
    }
    static testMethod void case001_Err() {
    	
        TestCommon.createTl2WayConfigDoc();
        
        Test.startTest();
        Test.setMock(WebServiceMock.class, new TestCommonMockImpl(true,true));
      	TL_ServiceCtrl ctrl = new TL_ServiceCtrl();
      	
      	TL_NetRoomTypeMasterSearchService.extractionCondition cond = new TL_NetRoomTypeMasterSearchService.extractionCondition();
      	      	
	    TL_NetRoomTypeMasterSearchService.rmTypeMstSearchForNetResponse rep = ctrl.callNetRoomTypeMasterSearchService('',cond);
	    Test.stopTest();
	    System.assertEquals(rep.commonResponse.isSuccess, false);
	    
    }
    static testMethod void case002() {
        TestCommon.createTl2WayConfigDoc();
        Test.startTest();
        Test.setMock(WebServiceMock.class, new TestCommonMockImpl());
      	TL_ServiceCtrl ctrl = new TL_ServiceCtrl();
      	
      	TL_NetStockSearchService.extractionCondition cond = new TL_NetStockSearchService.extractionCondition();
      	      	
	    TL_NetStockSearchService.stockSearchForNetResponse rep = ctrl.callNetStockSearchService('',cond);
	    Test.stopTest();
	    System.assertEquals(rep.commonResponse.isSuccess, true);
	    
    }
    static testMethod void case002_Err() {
        TestCommon.createTl2WayConfigDoc();
        Test.startTest();
        Test.setMock(WebServiceMock.class, new TestCommonMockImpl(true,true));
      	TL_ServiceCtrl ctrl = new TL_ServiceCtrl();
      	
      	TL_NetStockSearchService.extractionCondition cond = new TL_NetStockSearchService.extractionCondition();
      	      	
	    TL_NetStockSearchService.stockSearchForNetResponse rep = ctrl.callNetStockSearchService('',cond);
	    Test.stopTest();
	    System.assertEquals(rep.commonResponse.isSuccess, false);
	    
    }
    static testMethod void case003() {
        TestCommon.createTl2WayConfigDoc();
        Test.startTest();
        Test.setMock(WebServiceMock.class, new TestCommonMockImpl());
      	TL_ServiceCtrl ctrl = new TL_ServiceCtrl();
      	
      	TL_NetStockAdjustmentService.adjustmentTarget cond = new TL_NetStockAdjustmentService.adjustmentTarget();
      	      	
	    TL_NetStockAdjustmentService.stockAdjustmentForNetResponse rep = ctrl.callNetStockAdjustmentService('',cond);
	    Test.stopTest();
	    System.assertEquals(rep.commonResponse.isSuccess, true);
	    
    }
    static testMethod void case003_Err() {
        TestCommon.createTl2WayConfigDoc();
        Test.startTest();
        Test.setMock(WebServiceMock.class, new TestCommonMockImpl(true,true));
      	TL_ServiceCtrl ctrl = new TL_ServiceCtrl();
      	
      	TL_NetStockAdjustmentService.adjustmentTarget cond = new TL_NetStockAdjustmentService.adjustmentTarget();
      	      	
	    TL_NetStockAdjustmentService.stockAdjustmentForNetResponse rep = ctrl.callNetStockAdjustmentService('',cond);
	    Test.stopTest();
	    System.assertEquals(rep.commonResponse.isSuccess, false);
	    
    }
    static testMethod void case004() {
    	TestCommon.createTl2WayConfigDoc();
    	Test.startTest();
    	Test.setMock(WebServiceMock.class, new TestCommonMockImpl());
      	TL_ServiceCtrl ctrl = new TL_ServiceCtrl();
    	
    	TL_NetPlanMasterSearchService.extractionCondition cond = new TL_NetPlanMasterSearchService.extractionCondition();
    	
    	TL_NetPlanMasterSearchService.planMstSearchForNetResponse rep = ctrl.callNetPlanMasterSearchService('', cond);
    	Test.stopTest();
    	System.assertEquals(rep.commonResponse.isSuccess, true);
	    
    }
    static testMethod void case004_Err() {
    	TestCommon.createTl2WayConfigDoc();
    	Test.startTest();
    	Test.setMock(WebServiceMock.class, new TestCommonMockImpl(true,true));
      	TL_ServiceCtrl ctrl = new TL_ServiceCtrl();
    	
    	TL_NetPlanMasterSearchService.extractionCondition cond = new TL_NetPlanMasterSearchService.extractionCondition();
    	
    	TL_NetPlanMasterSearchService.planMstSearchForNetResponse rep = ctrl.callNetPlanMasterSearchService('', cond);
    	Test.stopTest();
    	System.assertEquals(rep.commonResponse.isSuccess, false);
	    
    }
    /*
    static testMethod void case005() {
    	
    	Test.setMock(WebServiceMock.class, new TestCommonMockImpl());
      	TL_ServiceCtrl ctrl = new TL_ServiceCtrl();
    	
    	TL_NetPlanMasterSearchService.extractionCondition cond = new TL_NetPlanMasterSearchService.extractionCondition();
    	
    	TL_NetPlanMasterSearchService.planMstSearchForNetResponse rep = ctrl.callNetPlanMasterSearchService('', cond);
    	System.assertEquals(rep.commonResponse.isSuccess, true);
	    
    }*/
    
    static testMethod void case006() {
    	TestCommon.createTl2WayConfigDoc();
    	Test.startTest();
    	Test.setMock(WebServiceMock.class, new TestCommonMockImpl());
      	TL_ServiceCtrl ctrl = new TL_ServiceCtrl();
    	
    	TL_BookingInfoOutputService.bookingInfoResponse rep = ctrl.callBookingInfoOutputService('');
    	Test.stopTest();
    	System.assertEquals(rep.commonResponse.isSuccess, true);
	    
    }
    
    static testMethod void case006_Err() {
    	TestCommon.createTl2WayConfigDoc();
    	Test.startTest();
    	Test.setMock(WebServiceMock.class, new TestCommonMockImpl(true,true));
      	TL_ServiceCtrl ctrl = new TL_ServiceCtrl();
    	
    	TL_BookingInfoOutputService.bookingInfoResponse rep = ctrl.callBookingInfoOutputService('');
    	Test.stopTest();
    	System.assertEquals(rep.commonResponse.isSuccess, false);
	    
    }  
    
    static testMethod void case007() {
    	TestCommon.createTl2WayConfigDoc();
    	Test.startTest();
    	Test.setMock(WebServiceMock.class, new TestCommonMockImpl());
      	TL_ServiceCtrl ctrl = new TL_ServiceCtrl();
    	
    	TL_OutputCompleteService.outputCompleteResponse rep = ctrl.callOutputCompleteService('','CTRL0001');
    	Test.stopTest();
    	System.assertEquals(rep.commonResponse.isSuccess, true);
	    
    }
    
    static testMethod void case007_Err() {
    	TestCommon.createTl2WayConfigDoc();
    	Test.startTest();
    	Test.setMock(WebServiceMock.class, new TestCommonMockImpl(true,true));
      	TL_ServiceCtrl ctrl = new TL_ServiceCtrl();
    	
    	TL_OutputCompleteService.outputCompleteResponse rep = ctrl.callOutputCompleteService('','CTRL0001');
    	Test.stopTest();
    	System.assertEquals(rep.commonResponse.isSuccess, false);
	    
    }
    static testMethod void case008() {
    	TestCommon.createTl2WayConfigDoc();
    	Test.startTest();
    	Test.setMock(WebServiceMock.class, new TestCommonMockImpl());
      	TL_ServiceCtrl ctrl = new TL_ServiceCtrl();
    	
    	//TL_RealRoomTypeMasterSearchService.extractionCondition cond = new TL_RealRoomTypeMasterSearchService.extractionCondition();
    	
    	TL_RealRoomTypeMasterSearchService.rmTypeMstSearchForRealResponse rep = ctrl.callRealRoomTypeMasterSearchService('');
    	Test.stopTest();
    	System.assertEquals(rep.commonResponse.isSuccess, true);

    }
    static testMethod void case008_Err() {
    	TestCommon.createTl2WayConfigDoc();
    	Test.startTest();
    	Test.setMock(WebServiceMock.class, new TestCommonMockImpl(true,true));
      	TL_ServiceCtrl ctrl = new TL_ServiceCtrl();
    	
    	//TL_RealRoomTypeMasterSearchService.extractionCondition cond = new TL_RealRoomTypeMasterSearchService.extractionCondition();
    	
    	TL_RealRoomTypeMasterSearchService.rmTypeMstSearchForRealResponse rep = ctrl.callRealRoomTypeMasterSearchService('');
    	Test.stopTest();
    	System.assertEquals(rep.commonResponse.isSuccess, false);

    }
    static testMethod void case009() {
    	TestCommon.createTl2WayConfigDoc();
    	Test.startTest();
    	Test.setMock(WebServiceMock.class, new TestCommonMockImpl());
      	TL_ServiceCtrl ctrl = new TL_ServiceCtrl();
    	
    	TL_RealStockSearchService.extractionCondition cond = new TL_RealStockSearchService.extractionCondition();
    	
    	TL_RealStockSearchService.stockSearchForRealResponse rep = ctrl.callRealStockSearchService('',cond);
    	Test.stopTest();
    	System.assertEquals(rep.commonResponse.isSuccess, true);
	    
    }
    static testMethod void case009_Err() {
    	TestCommon.createTl2WayConfigDoc();
    	Test.startTest();
    	Test.setMock(WebServiceMock.class, new TestCommonMockImpl(true,true));
      	TL_ServiceCtrl ctrl = new TL_ServiceCtrl();
    	
    	TL_RealStockSearchService.extractionCondition cond = new TL_RealStockSearchService.extractionCondition();
    	
    	TL_RealStockSearchService.stockSearchForRealResponse rep = ctrl.callRealStockSearchService('',cond);
    	Test.stopTest();
    	System.assertEquals(rep.commonResponse.isSuccess, false);
	    
    }
    static testMethod void case010() {
    	TestCommon.createTl2WayConfigDoc();
    	Test.startTest();
    	Test.setMock(WebServiceMock.class, new TestCommonMockImpl());
      	TL_ServiceCtrl ctrl = new TL_ServiceCtrl();
    	
    	TL_RealStockAdjustmentService.adjustmentTarget cond = new TL_RealStockAdjustmentService.adjustmentTarget();
    	
    	TL_RealStockAdjustmentService.stockAdjustmentForRealResponse rep = ctrl.callRealStockAdjustmentService('',cond);
    	Test.stopTest();
    	System.assertEquals(rep.commonResponse.isSuccess, true);
	    
    }
    static testMethod void case010_Err() {
    	TestCommon.createTl2WayConfigDoc();
    	Test.startTest();
    	Test.setMock(WebServiceMock.class, new TestCommonMockImpl(true,true));
      	TL_ServiceCtrl ctrl = new TL_ServiceCtrl();
    	
    	TL_RealStockAdjustmentService.adjustmentTarget cond = new TL_RealStockAdjustmentService.adjustmentTarget();
    	
    	TL_RealStockAdjustmentService.stockAdjustmentForRealResponse rep = ctrl.callRealStockAdjustmentService('',cond);
    	Test.stopTest();
    	System.assertEquals(rep.commonResponse.isSuccess, false);
	    
    }
}