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
private class BookingAppTest {

    @isTest(SeeAllData=false)
	static void testCase1() {
    	Test.startTest();
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
		
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	Test.stopTest();
    	// Idで最新情報を取得する
    	String idxName = [select LeadIndexRef__r.Name from Lead__c where id = :leadInfo.Id].LeadIndexRef__r.Name;
    	List<LeadIndex__c> leadIdxLst = [select id from LeadIndex__c where name = :idxName];
    	ApexPages.StandardController contrl = new ApexPages.StandardController(leadIdxLst[0]);
    	BookingApp app = new BookingApp(contrl);
    	app.leadBaseInf.leadNo = idxName;
    	app.refreshExistLeadInfo();
        // 顧客情報を更新を行う
        app.refreshContcatInfo();

 		app.leadBaseInf.contactName = 'UNAME' + Crypto.getRandomLong();
 		app.leadBaseInf.l.Field2__c = '本社';
 		app.leadBaseInf.l.Segment__c = 'CARD';
        app.leadBaseInf.accoutName = 'ACC-NEW' + CommUtils.getRandom(10);

 		app.createLeadInfo();

 		// SubIndex登録を行う
 		//LeadItem item = new LeadItem();
 		app.indexSubId = app.oLeadLst[0].s.Id;
 		app.expandGuestLst();
 		System.assertNotEquals(app.indexSubId, null);
 		app.createGuestInfo();
 		String typos = TestCommon.createTypeOfRoom().Id;
	}
	// 宿泊者名簿関連テスト
	// P1:連泊の予約があり、部屋はすでにアサイン済み、宿泊者名簿が未存在する場合、明細情報をクリックすると、後ろから、部屋アサインありの部屋が宿泊者名簿に表示する
	@isTest(SeeAllData=false)
	static void testCase2() {
		// 予約データの明細情報を変更して、再登録する
    	Test.startTest();
    	Contact guest = TestCommon.createContact();
		TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
		
		// 新規登録
		LeadIndex__c sobj = new LeadIndex__c();
    	ApexPages.StandardController contrl = new ApexPages.StandardController(sobj);
    	BookingApp app = new BookingApp(contrl);
    	
		app.leadBaseInf.s.EntryDate__c = Date.today();
		app.leadBaseInf.s.EntryTime__c = '16:00';
		app.leadBaseInf.s.Nights__c = 3;
		app.leadBaseInf.s.DepartureDate__c = app.leadBaseInf.s.EntryDate__c.addDays(3);
		app.leadBaseInf.s.DepartureTime__c = '10:30';
        // 顧客情報を更新を行う
        app.refreshContcatInfo();

 		app.leadBaseInf.contactName = 'UNAME' + Crypto.getRandomLong();
 		app.leadBaseInf.l.Field2__c = '本社';
 		app.leadBaseInf.l.Segment__c = 'CARD';
        app.leadBaseInf.accoutName = 'ACC-NEW' + CommUtils.getRandom(10);
		app.leadBaseInf.s.contactRef__c = guest.Id;
		app.leadBaseInf.s.LeadName__c = 'テストケースの予約名';
		app.leadBaseInf.s.Comment__c = 'Comment_'+ CommUtils.getRandom(10);
		
		//LeadItem subItem = app.oLeadLst[0];
		BookingApp.LeadItem subItem = app.oLeadLst[0];
		subItem.s.EntryDate__c = app.leadBaseInf.s.EntryDate__c;
		subItem.nights = '3';
		subItem.s.DepartureDate__c = app.leadBaseInf.s.DepartureDate__c;
		subItem.s.RoomTypeRef__c = typeOfRoom.Id;
		subItem.persons = String.valueOf(1);
		subItem.rooms = String.valueOf(2);
		
 		app.createLeadInfo();
		Test.stopTest();
System.assertNotEquals(app.leadBaseInf.leadNo, null, app.leadBaseInf.leadNo);
		app.leadBaseInf.s.LeadName__c = 'テストケースの予約名2';
		app.leadBaseInf.s.Payment__c = '現金';
		app.leadBaseInf.s.Comment__c = 'Comment2_'+ CommUtils.getRandom(10);
		
		subItem = app.oLeadLst[0];
		subItem.s.EntryDate__c = app.leadBaseInf.s.EntryDate__c;
		subItem.nights = '2';
		subItem.s.DepartureDate__c = subItem.s.EntryDate__c.addDays(2);
		subItem.s.RoomTypeRef__c = typeOfRoom.Id;
		subItem.persons = String.valueOf(2);
		subItem.rooms = String.valueOf(1);
		app.createLeadInfo();
		
		// 顧客様のリスト設定する
		app.indexSubId = subItem.s.Id;
		app.expandGuestLst();
		
		app.bulkCheckIn();
	}
	// 明細情報に関連付くの予約データは全部無効になると、該当明細情報は非表示する
	// キャンセルなど予約データから有効な予約データに変更すると、該当明細情報は再表示する
	@isTest(SeeAllData=false)
	static void testCase3() {
		// 予約データの明細情報を変更して、再登録する
    	Test.startTest();
    	TestCommon.createBillSimpleHelpConfigDoc();
    	Contact guest = TestCommon.createContact();
		TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
		
		// 新規登録
		LeadIndex__c sobj = new LeadIndex__c();
    	ApexPages.StandardController contrl = new ApexPages.StandardController(sobj);
    	BookingApp app = new BookingApp(contrl);
    	
		app.leadBaseInf.s.EntryDate__c = Date.today();
		app.leadBaseInf.s.EntryTime__c = '16:00';
		app.leadBaseInf.s.Nights__c = 1;
		app.leadBaseInf.s.DepartureDate__c = app.leadBaseInf.s.EntryDate__c.addDays(app.leadBaseInf.s.Nights__c.intValue());
		app.leadBaseInf.s.DepartureTime__c = '10:30';
        // 顧客情報を更新を行う
        app.refreshContcatInfo();

 		app.leadBaseInf.contactName = 'UNAME' + Crypto.getRandomLong();
 		app.leadBaseInf.l.Field2__c = '本社';
 		app.leadBaseInf.l.Segment__c = 'CARD';
        app.leadBaseInf.accoutName = 'ACC-NEW' + CommUtils.getRandom(10);
		app.leadBaseInf.s.contactRef__c = guest.Id;
		app.leadBaseInf.s.LeadName__c = 'テストケースの予約名';
		app.leadBaseInf.s.Comment__c = 'Comment_'+ CommUtils.getRandom(10);
		
		BookingApp.LeadItem subItem = app.oLeadLst[0];
		subItem.s.EntryDate__c = app.leadBaseInf.s.EntryDate__c;
		subItem.nights = String.valueOf(app.leadBaseInf.s.Nights__c);
		subItem.s.DepartureDate__c = app.leadBaseInf.s.DepartureDate__c;
		subItem.s.RoomTypeRef__c = typeOfRoom.Id;
		subItem.persons = String.valueOf(1);
		subItem.rooms = String.valueOf(1);
		// １件予約データを作成する
 		app.createLeadInfo();
		Test.stopTest();
		// 予約データをキャンセルすると、明細情報は非表示になる
		List<Lead__c> updLead = [select Id, LeadIndexRef__c, ReservedStatus__c from lead__c];
		System.assertEquals(updLead.size(), 1);
		updLead[0].ReservedStatus__c = CommConst.LEAD_ST_CANCEL;
		update updLead;
//System.debug(logginglevel.ERROR,'BBBBB:'+updLead);
		// 最新データを取得する
		app.refreshExistLeadInfo();
		// 明細情報第一番目を取得する
		subItem = app.oLeadLst[0];
//System.debug(logginglevel.ERROR,'AAAAA:'+app.leadBaseInf.leadNo);
		System.assertEquals(subItem.s.Id, null);
		
		// 予約回復する
		updLead[0].ReservedStatus__c = CommConst.LEAD_ST_CHECKED;
		update updLead;
		// 最新データを取得する
		app.refreshExistLeadInfo();
		// 明細情報第一番目を取得する
		subItem = app.oLeadLst[0];
//System.debug(logginglevel.ERROR,'AAAAA:'+app.leadBaseInf.leadNo);
		System.assertNotEquals(subItem.s.Id, null);
//System.debug(logginglevel.ERROR,'guest:'+guest);
		// お客様情報を新規作成
		Contact newGuest = TestCommon.createContact();
		newGuest = [select id, name from contact where id = :newGuest.Id];
		app.leadBaseInf.s.contactRef__c = newGuest.Id;
		app.leadBaseInf.contactName = newGuest.Name;
		app.refreshContcatInfo();
		app.createLeadInfo();
		updLead = [select Id, Relcontact__c from lead__c limit 1];
		System.assertEquals(updLead[0].Relcontact__c, newGuest.id, newGuest);
	}

	@isTest(SeeAllData=false)
	static void testCase4() {
		// 予約データの明細情報を変更して、再登録する
    	Test.startTest();
    	Contact guest = TestCommon.createContact();
    	String guestName = guest.LastName + ' ' + guest.FirstName;
		TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
		// 新規登録
		LeadIndex__c sobj = new LeadIndex__c();
    	ApexPages.StandardController contrl = new ApexPages.StandardController(sobj);
    	BookingApp app = new BookingApp(contrl);
    	BookingApp.ContactInfo contactInf = BookingApp.refreshContcatInfo(guest.Id, guestName);
    	System.assertEquals(contactInf.KanjiName, CommUtils.nullToBlank(guest.Name1__c), contactInf);
    	System.assertEquals(contactInf.KanaName, CommUtils.nullToBlank(guest.KanaName1__c), contactInf);
    	System.assertEquals(contactInf.KatakanaName, CommUtils.nullToBlank(guest.Katakana__c), contactInf);
    	System.assertEquals(contactInf.phone, CommUtils.nullToBlank(guest.Phone), contactInf);
    	//System.assertEquals(contactInf.accountName, CommUtils.nullToBlank(guest.Account.Name), contactInf);
    	System.assertEquals(contactInf.ApplicantName, CommUtils.nullToBlank(guest.ApplicantName__c), contactInf);
    	System.assertEquals(contactInf.ApplicantPhone, CommUtils.nullToBlank(guest.ApplicantPhone__c), contactInf);
    	System.assertEquals(contactInf.Memo1, CommUtils.nullToBlank(guest.Memo1__c), contactInf);
    	System.assertEquals(contactInf.Memo2, CommUtils.nullToBlank(guest.Memo2__c), contactInf);
    	System.assertEquals(contactInf.Memo3, CommUtils.nullToBlank(guest.Memo3__c), contactInf);
	}
}