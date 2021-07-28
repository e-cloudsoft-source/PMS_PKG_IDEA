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
private class RoomIndicatorInfoDayUseTest {

	// 予約情報をアサインして、パラメータ設定、Dayuse情報を設定する
    static testMethod void myUnitTest() {
        Date todayDt = Date.today();
        TypeOfRooms__c roomType = TestCommon.createTypeOfRoom();
        List<Room__c> rooms = TestCommon.createRooms(1, roomType.Id);
        Lead__c dayLead1 = TestCommon.createBookingLead(todayDt, roomType.Id, 0);
        Lead__c dayLead2 = TestCommon.createBookingLead(todayDt, roomType.Id, 0);
        Lead__c dayLead3 = TestCommon.createBookingLead(todayDt, roomType.Id, 1);
        
        dayLead2.Rroom__c = rooms[0].Id;
        dayLead2.Field4__c = '10:00';
        dayLead2.Field3__c = '12:00';
        
        dayLead1.Rroom__c = rooms[0].Id;
        dayLead1.Field4__c = '14:00';
        dayLead1.Field3__c = '17:00';
        
        dayLead3.Rroom__c = rooms[0].Id;
        dayLead3.Field4__c = '18:00';
        dayLead3.Field3__c = '10:00';
        
        List<Lead__c> updLst = new List<Lead__c>();
        updLst.add(dayLead1);
        updLst.add(dayLead2);
        updLst.add(dayLead3);
        update updLst;
        
        Test.startTest();
        // パラメータ設定を行う
        //Pagereference pg = new Pagereference
		Test.setCurrentPageReference(new PageReference('Page.RoomIndicatorInfoDayUse')); 
		System.currentPageReference().getParameters().put('roomId', rooms[0].Id);
        System.currentPageReference().getParameters().put('queryDate', todayDt.format());
        System.currentPageReference().getParameters().put('checkflag', String.valueOf(true));
        System.currentPageReference().getParameters().put('topLeadId', dayLead1.Id);
        
        RoomIndicatorInfoDayUse dayUse = new RoomIndicatorInfoDayUse();
        dayUse.init();
        List<RoomIndicatorInfoDayUse.LeadInfo> leads = dayUse.leadInfos;
        
        System.assertEquals(leads.size(), 3);
        System.assertEquals(dayuse.topLeadId, dayLead1.Id);
        
        RoomIndicatorInfoDayUse.LeadInfo firstLead = leads[0];
        System.assertEquals(firstLead.s.id, dayLead2.Id);
        
        Test.stopTest();
    }
}