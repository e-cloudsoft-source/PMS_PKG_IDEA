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
private class SSLookupHoverDetailCtrlTest {

    static testMethod void staffLeadCase1() {
       	Test.startTest();
       	createDocument();
		CommDefine__c comDef = TestCommon.createCommDefine();
		Integer nights = 3;
		Date startDt = Date.today().addDays(-1*nights);
    	// 予約情報を作成する[プラン付け]
    	List<Lead__c> leads = TestCommon.createLead(startDt, 2, nights);
    	// 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Lead__c].size(), 6);
        // 2015/12/01 Assert END
		String leadIds = '';
		for (Lead__c lead : leads) {
			leadIds+=lead.Id+',';
		}
		String s = SSLookupHoverDetailCtrl.getLeadsInfo(leadIds.removeEnd(','),'02');
		System.assert(s.length() > 0);
		
		String s1 = SSLookupHoverDetailCtrl.getLeadsInfo(null,null);
		System.assert(s1.length() == 0,s1);
    }
    static testMethod void taskCase1() {
       	Test.startTest();
		CommDefine__c comDef = TestCommon.createCommDefine();
		DateTime nowTime  = System.now();
		Event ev = new Event(
			Subject = 'TEST001',
			ActivityDate = nowTime.date(),
			Description = 'DESC',
			StartDateTime = nowTime,
			EndDateTime = System.now().addMinutes(10),
			OwnerId = UserInfo.getUserId()
		);
		insert ev;
		String s = SSLookupHoverDetailCtrl.getTaskInfo(UserInfo.getUserId(), nowTime.format('yyyy/MM/dd'));
		String s1 = SSLookupHoverDetailCtrl.getTaskInfo(null, nowTime.format('yyyy/MM/dd'));
		System.assert(s1.length() == 0,s1);
    }
    // 2019/04/15 BY zyz BEGIN
    static testMethod void eventTaskCase1() {
       	Test.startTest();
		CommDefine__c comDef = TestCommon.createCommDefine();
		DateTime nowTime  = System.now();
    	TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
    	List<Room__c> createRooms = TestCommon.createRooms(3, typeOfRoom.Id);
		Event ev = new Event(
			Subject = 'TEST001',
			ActivityDate = Date.today(),
			Description = 'DESC',
			StartDateTime = nowTime,
			EndDateTime = System.now().addMinutes(10),
			OwnerId = UserInfo.getUserId(),
			RoomRef__c = createRooms[0].id,
			WhoId = TestCommon.createContact().id
		);
		insert ev;
    }
    static testMethod void eventTaskCase2() {
       	Test.startTest();
		CommDefine__c comDef = TestCommon.createCommDefine();
		DateTime nowTime  = System.now();
    	TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
    	List<Room__c> createRooms = TestCommon.createRooms(3, typeOfRoom.Id);
		Event ev = new Event(
			Subject = 'TEST001',
			ActivityDate = Date.today(),
			Description = 'DESC',
			StartDateTime = nowTime,
			EndDateTime = System.now().addMinutes(10),
			OwnerId = UserInfo.getUserId()
		);
		insert ev;
		ev.ActivityDate = Date.today()+1;
		update ev;
    }
    // 2019/04/15 BY zyz END
    private static void createDocument(){
    	String csv = '<?xml version="1.0" encoding="utf-8"?><root>    <SHOP><SHOPCODE></SHOPCODE><SUMMARYEXTFIELD>Name,StayPersons__c,Field4__c,Field3__c</SUMMARYEXTFIELD></SHOP></root>';

    	Document StaffScheduleConfigXml = new Document();
		StaffScheduleConfigXml.Name = 'StaffScheduleConfigXml';
		StaffScheduleConfigXml.DeveloperName = StaffScheduleConfigXml.Name;
    	StaffScheduleConfigXml.FolderId = UserInfo.getUserId();
    	StaffScheduleConfigXml.Body = Blob.valueOf(csv);
    	insert StaffScheduleConfigXml;
    }
}