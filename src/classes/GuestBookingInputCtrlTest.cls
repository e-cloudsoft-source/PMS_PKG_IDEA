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
private class GuestBookingInputCtrlTest {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        Test.startTest();
        
        Contact guest = TestCommon.createContact();
        Lead__c leadInfo = TestCommon.createLead();
        update leadInfo;
		Yadochou__c yadochou = new Yadochou__c(
            Name = 'TestCode',
            Field1__c = leadInfo.Id,
            Field15__c = guest.Id
        );
        insert yadochou;
        Guestbookcustomer__c sub1 = new Guestbookcustomer__c(
            customer__c = guest.Id,
            GuestbookNmae__c = yadochou.Id
        );
        insert sub1;
        Test.stopTest();
        
        ApexPages.StandardController contrl = new ApexPages.StandardController(yadochou);
        GuestBookingInputCtrl ctrl = new GuestBookingInputCtrl(contrl);
        ctrl.init();
        ctrl.confirm();
        ctrl.addNewLine();
        ctrl.saveGuestInfo();
        System.assertEquals(ctrl.roomGuestList.size(), 1);
        GuestBookingInputCtrl.OneRoomInfo OneRoom = ctrl.roomGuestList[0];
        System.assertEquals(OneRoom.guestList.size(), 4);
    }
	static testmethod void testCode1() {
        createDocument();
        // Report Logo作成
        TestCommon.createRepLogo();
        TestCommon.createCommDefine();
 		User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	loginUser.ShopCode__c = null;
    	update loginUser;
        //update loginUser;
        System.runAs(loginUser) {
        Contact guest = TestCommon.createContact();
        Contact guest1 = TestCommon.createContact();
        Contact guest2 = TestCommon.createContact();
        // 明細情報を登録して、保存する処理
        List<Lead__c> leads = TestCommon.createLead(Date.today(), 1,2,guest.Id);
        for (Lead__c lead : leads) {
        	lead.Field293__c = '18:30';
       	 	lead.Morningtime__c = '7:00';
        }
        update leads;
        /* 宿帳は新規自動機能により、下記改修を行う
        Yadochou__c yadochou = new Yadochou__c(
            Name = 'TestCode',
            Field1__c = leads[0].Id,
            Field15__c = guest.Id
        );
        insert yadochou;
        */
        Yadochou__c yadochou = [select id from Yadochou__c where Field1__c = :leads[0].Id];
        Guestbookcustomer__c sub1 = new Guestbookcustomer__c(
            customer__c = guest1.Id,
            GuestbookNmae__c = yadochou.Id
        );
        Guestbookcustomer__c sub2 = new Guestbookcustomer__c(
            customer__c = guest1.Id,
            GuestbookNmae__c = yadochou.Id
        );
        List<Guestbookcustomer__c> subs = new List<Guestbookcustomer__c>{sub1, sub2};
        insert subs;
        
        Test.startTest();

        ApexPages.StandardController contrl1 = new ApexPages.StandardController(yadochou);
        GuestBookingInputCtrl ctrl1 = new GuestBookingInputCtrl(contrl1);
        ctrl1.init();
        ctrl1.confirm();
        // 2019/02/15 客様の名前を変更した場合、宿帳もそれに伴って名前が変更 BY zyz BEGIN
        GuestBookingInputCtrl.convertYadoName(null,guest1.Name);
        GuestBookingInputCtrl.convertYadoName('abc',null);
        // 2019/02/15 客様の名前を変更した場合、宿帳もそれに伴って名前が変更 BY zyz END
		Apexpages.currentPage().getParameters().put('roomIndex','0');       
        Integer idx = 1;
        GuestBookingInputCtrl.OneRoomInfo OneRoom = ctrl1.roomGuestList[0];
        for (GuestBookingInputCtrl.OneRoomGuestInfo oneGuest : oneRoom.guestList) {
        	oneGuest.rowsNo = idx;
        	idx++;
        }
        ctrl1.addNewLine();
        System.assertEquals(ctrl1.roomGuestList.size(), 1);
        ctrl1.saveGuestInfo();
        System.assertEquals(ctrl1.roomGuestList.size(), 1);
        System.assertEquals(OneRoom.guestList.size(), 3);
        
        Test.stopTest();
        }
	}
	static testmethod void testCode_error() {
	    TestCommon.createCommDefine();
        Contact guest = TestCommon.createContact();
        // 明細情報を登録して、保存する処理
        List<Lead__c> leads = TestCommon.createLead(Date.today(), 1,2,guest.Id);
        Id leadIndexId = [select leadIndexRef__c from Lead__c where id = :leads[0].Id].leadIndexRef__c;
		map<string,string> parMap = ApexPages.currentPage().getParameters();
		parMap.put('frame','true');
		parMap.put('pid',leadIndexId);
        ApexPages.StandardController contrl1 = new ApexPages.StandardController(new Yadochou__c());
        GuestBookingInputCtrl ctrl1 = new GuestBookingInputCtrl(contrl1);
        ctrl1.init();
        System.assertNotEquals(ctrl1.autoComLeadNoFilter, null);
		System.assert(!ctrl1.isShowHeader);
		ctrl1.inputLead.LeadIndexRef__c = null;
		ctrl1.confirm();
		parMap.put('pid','');
        ApexPages.StandardController contrl2 = new ApexPages.StandardController(new Yadochou__c());
        GuestBookingInputCtrl ctrl2 = new GuestBookingInputCtrl(contrl2);
        ctrl2.init();
	}
	static testmethod void testCode2() {
		createDocument();
        // Report Logo作成
        TestCommon.createCommDefine();
        TestCommon.createRepLogo();
 		User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	loginUser.ShopCode__c = null;
    	update loginUser;
        //update loginUser;
        System.runAs(loginUser) {
	        Contact guest = TestCommon.createContact();
	        Contact guest1 = TestCommon.createContact();
	        Contact guest2 = TestCommon.createContact();
	        // 明細情報を登録して、保存する処理
	        List<Lead__c> leads = TestCommon.createLead(Date.today(), 1,2,guest.Id);
	        for (Lead__c lead : leads) {
	        	lead.Field293__c = '18:30';
	       	 	lead.Morningtime__c = '7:00';
	        }
	        update leads;
	        
	        Yadochou__c yadochou = [select id,name from Yadochou__c where Field1__c = :leads[0].Id];
	        Guestbookcustomer__c sub1 = new Guestbookcustomer__c(
	            customer__c = guest1.Id,
	            GuestbookNmae__c = yadochou.Id
	        );
	        Guestbookcustomer__c sub2 = new Guestbookcustomer__c(
	            customer__c = guest2.Id,
	            GuestbookNmae__c = yadochou.Id
	        );
	        List<Guestbookcustomer__c> subs = new List<Guestbookcustomer__c>{sub1, sub2};
	        insert subs;
	        
	        Test.startTest();
	
	        ApexPages.StandardController contrl1 = new ApexPages.StandardController(yadochou);
	        GuestBookingInputCtrl ctrl1 = new GuestBookingInputCtrl(contrl1);
	        ctrl1.init();
	        ctrl1.confirm();
	        ctrl1.addNewLine();
	        // 2019/02/15 客様の名前を変更した場合、宿帳もそれに伴って名前が変更 BY zyz BEGIN
	        GuestBookingInputCtrl.convertYadoName(yadochou.Name,guest1.Name);
	        // 2019/02/15 客様の名前を変更した場合、宿帳もそれに伴って名前が変更 BY zyz END
	        Integer idx = 1;
	        GuestBookingInputCtrl.OneRoomInfo OneRoom = ctrl1.roomGuestList[0];
	        for (GuestBookingInputCtrl.OneRoomGuestInfo oneGuest : oneRoom.guestList) {
	        	oneGuest.rowsNo = idx;
	        	idx++;
	        }
	        ctrl1.saveGuestInfo();
	        GuestBookingInputCtrl.ContactXmlDef item = ctrl1.parseItem;
	        item.getDateTimeFormatStr();
	        item.getDateFormatStr();
	        //ctrl1.parseFieldsXml();
			ctrl1.saveGuestInfo();
	        //GuestBookingInputCtrl.refreshContcatInfo(yadochou.Field15__r.id, yadochou.Field15__r.name,ctrl1.parseItem.contactString);
	        System.assertEquals(ctrl1.roomGuestList.size(), 1);
	        OneRoom = ctrl1.roomGuestList[0];
	        System.assertEquals(OneRoom.guestList.size(), 3);
	        
	        Test.stopTest();
        }
	}
	static testmethod void testCode5() {
		createDocument3();
        // Report Logo作成
        TestCommon.createCommDefine();
        TestCommon.createRepLogo();
 		User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	loginUser.ShopCode__c = null;
    	update loginUser;
        //update loginUser;
        System.runAs(loginUser) {
	        Contact guest = TestCommon.createContact();
	        Contact guest1 = TestCommon.createContact();
	        Contact guest2 = TestCommon.createContact();
	        // 明細情報を登録して、保存する処理
	        List<Lead__c> leads = TestCommon.createLead(Date.today(), 1,2,guest.Id);
	        for (Lead__c lead : leads) {
	        	lead.Field293__c = '18:30';
	       	 	lead.Morningtime__c = '7:00';
	        }
	        update leads;
	        
	        Yadochou__c yadochou = [select id from Yadochou__c where Field1__c = :leads[0].Id];
	        Guestbookcustomer__c sub1 = new Guestbookcustomer__c(
	            customer__c = guest1.Id,
	            GuestbookNmae__c = yadochou.Id
	        );
	        Guestbookcustomer__c sub2 = new Guestbookcustomer__c(
	            customer__c = guest2.Id,
	            GuestbookNmae__c = yadochou.Id
	        );
	        List<Guestbookcustomer__c> subs = new List<Guestbookcustomer__c>{sub1, sub2};
	        insert subs;
	        
	        Test.startTest();
	
	        ApexPages.StandardController contrl1 = new ApexPages.StandardController(yadochou);
	        GuestBookingInputCtrl ctrl1 = new GuestBookingInputCtrl(contrl1);
	        ctrl1.init();
	        ctrl1.confirm();
	        ctrl1.addNewLine();
	        Integer idx = 1;
	        GuestBookingInputCtrl.OneRoomInfo OneRoom = ctrl1.roomGuestList[0];
	        for (GuestBookingInputCtrl.OneRoomGuestInfo oneGuest : oneRoom.guestList) {
	        	oneGuest.rowsNo = idx;
	        	idx++;
	        }
	        ctrl1.saveGuestInfo();
	        GuestBookingInputCtrl.ContactXmlDef item = ctrl1.parseItem;
	        item.getDateTimeFormatStr();
	        item.getDateFormatStr();
	        //ctrl1.parseFieldsXml();
			ctrl1.saveGuestInfo();
	        //GuestBookingInputCtrl.refreshContcatInfo(yadochou.Field15__r.id, yadochou.Field15__r.name,ctrl1.parseItem.contactString);
	        System.assertEquals(ctrl1.roomGuestList.size(), 1);
	        OneRoom = ctrl1.roomGuestList[0];
	        System.assertEquals(OneRoom.guestList.size(), 3);
	        
	        Test.stopTest();
        }
	}
	private static void createDocument(){
		String fileXml = '<root><SHOP><SHOPCODE></SHOPCODE><MEMO_OUTPUTFIELD><LEAD>Relcontact__r.ReportsTo,Comment3__c,Relcontact__r.Name </LEAD><YADOCHOU>Field13__c:特記事項,Field15__r.name,Field11__c :御部屋名,Field12__c:宿泊日</YADOCHOU></MEMO_OUTPUTFIELD><YADOTYO_INPUT_UI><FIELDS>Katakana__c,Phone,Email,gender__c,Birthdate,OrgCreateDate__c,	DelFlg__c,MailingPostalCode,MailingCountry,MailingState,MailingCity,MailingStreet</FIELDS><COLNUMSIZE>Katakana__c:100px,Phone:100px,Email:150px,gender__c:100px</COLNUMSIZE></YADOTYO_INPUT_UI></SHOP></root>';
		// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'CashRegisterCardPdfConfig';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(fileXml);
    	insert item;
	}
	private static void createDocument1(){
		String fileXml = '<root><SHOP><SHOPCODE></SHOPCODE><MEMO_OUTPUTFIELD><LEAD>Relcontact__r.ReportsTo,Comment3__c,Relcontact__r.Name </LEAD><YADOCHOU>Field13__c:特記事項,Field15__r.name,Field11__c :御部屋名,Field12__c:宿泊日</YADOCHOU></MEMO_OUTPUTFIELD><YADOTYO_INPUT_UI><FIELDS></FIELDS><COLNUMSIZE></COLNUMSIZE></YADOTYO_INPUT_UI></SHOP></root>';
		// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'CashRegisterCardPdfConfig';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(fileXml);
    	insert item;
	}
	private static void createDocument2(){
		String fileXml = '<root><SHOP><SHOPCODE></SHOPCODE><MEMO_OUTPUTFIELD><LEAD>Relcontact__r.ReportsTo,Comment3__c,Relcontact__r.Name </LEAD><YADOCHOU>Field13__c:特記事項,Field15__r.name,Field11__c :御部屋名,Field12__c:宿泊日</YADOCHOU></MEMO_OUTPUTFIELD><YADOTYO_INPUT_UI><FIELDS></FIELDS><COLNUMSIZE></COLNUMSIZE></YADOTYO_INPUT_UI></SHOP></root>';
		// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'CashRegisterCardPdfConfig';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(fileXml);
    	insert item;
	}	
	private static void createDocument3(){
		String fileXml = '<root><SHOP><SHOPCODE></SHOPCODE><MEMO_OUTPUTFIELD><LEAD>Relcontact__r.ReportsTo,Comment3__c,Relcontact__r.Name </LEAD><YADOCHOU>Field13__c:特記事項,Field15__r.name,Field11__c :御部屋名,Field12__c:宿泊日</YADOCHOU></MEMO_OUTPUTFIELD><YADOTYO_INPUT_UI><FIELDS>Katakana__c:ひらがな,Phone:電話,Email:メール,gender__c:性別,Birthdate:誕生日,MailingPostalCode:郵便番号,MailingState:都道府県,MailingCity:市区郡,MailingStreet:町名・番地</FIELDS><COLNUMSIZE>Katakana__c:100px,Phone:100px,Email:150px,gender__c:100px</COLNUMSIZE></YADOTYO_INPUT_UI></SHOP></root>';
		// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'CashRegisterCardPdfConfig';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(fileXml);
    	insert item;
	}
}