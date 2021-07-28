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
private class BookingFlexAppTest {
   
    @isTest(SeeAllData=false)
    static void testCase1() {
        Test.startTest();
        getCsvSetupConfig();
        
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
        BookingFlexApp app = new BookingFlexApp(contrl);
        app.leadBaseInf.leadNo = idxName;
        app.refreshExistLeadInfo();
        // 顧客情報を更新を行う
        //app.refreshContcatInfo();
        BookingFlexApp.refreshContcatInfo(app.leadBaseInf.c.id, app.leadBaseInf.c.name,app.planString);

        app.leadBaseInf.contactName = 'UNAME' + Crypto.getRandomLong();
        app.leadBaseInf.l.Field2__c = '本社';
        app.leadBaseInf.l.Segment__c = 'CARD';
        app.leadBaseInf.accoutName = 'ACC-NEW' + CommUtils.getRandom(10);

        app.createLeadInfo();
        // SubIndex登録を行う
        //LeadItem item = new LeadItem();
        app.indexSubId = app.oLeadLst[0].s.Id;
        //app.expandGuestLst();
        System.assertNotEquals(app.indexSubId, null);
        //app.createGuestInfo();
        String typos = TestCommon.createTypeOfRoom().Id;
    }
    // 宿泊者名簿関連テスト
    // P1:連泊の予約があり、部屋はすでにアサイン済み、宿泊者名簿が未存在する場合、明細情報をクリックすると、後ろから、部屋アサインありの部屋が宿泊者名簿に表示する
    @isTest(SeeAllData=false)
    static void testCase2() {
        // 予約データの明細情報を変更して、再登録する
        Test.startTest();
        getCsvSetupConfig();
        Contact guest = TestCommon.createContact();
        TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
        
        // 新規登録
        LeadIndex__c sobj = new LeadIndex__c();
        ApexPages.StandardController contrl = new ApexPages.StandardController(sobj);
        BookingFlexApp app = new BookingFlexApp(contrl);
        
        app.leadBaseInf.s.EntryDate__c = Date.today();
        app.leadBaseInf.s.EntryTime__c = '16:00';
        app.leadBaseInf.s.Nights__c = 3;
        app.leadBaseInf.s.DepartureDate__c = app.leadBaseInf.s.EntryDate__c.addDays(3);
        app.leadBaseInf.s.DepartureTime__c = '10:30';
        // 顧客情報を更新を行う
        //app.refreshContcatInfo();

        app.leadBaseInf.contactName = 'UNAME' + Crypto.getRandomLong();
        app.leadBaseInf.l.Field2__c = '本社';
        app.leadBaseInf.l.Segment__c = 'CARD';
        app.leadBaseInf.accoutName = 'ACC-NEW' + CommUtils.getRandom(10);
        app.leadBaseInf.s.contactRef__c = guest.Id;
        app.leadBaseInf.s.LeadName__c = 'テストケースの予約名';
        app.leadBaseInf.s.Comment__c = 'Comment_'+ CommUtils.getRandom(10);
        
        //LeadItem subItem = app.oLeadLst[0];
        BookingFlexApp.LeadItem subItem = app.oLeadLst[0];
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
        //app.expandGuestLst();
        
        //app.bulkCheckIn();
    }
    // 明細情報に関連付くの予約データは全部無効になると、該当明細情報は非表示する
    // キャンセルなど予約データから有効な予約データに変更すると、該当明細情報は再表示する
    @isTest(SeeAllData=false)
    static void testCase3() {
        // 予約データの明細情報を変更して、再登録する
        Test.startTest();
        getCsvSetupConfig();
        TestCommon.createBillSimpleHelpConfigDoc();
        Contact guest = TestCommon.createContact();
        TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
        
        // 新規登録
        LeadIndex__c sobj = new LeadIndex__c();
        ApexPages.StandardController contrl = new ApexPages.StandardController(sobj);
        BookingFlexApp app = new BookingFlexApp(contrl);
        
        app.leadBaseInf.s.EntryDate__c = Date.today();
        app.leadBaseInf.s.EntryTime__c = '16:00';
        app.leadBaseInf.s.Nights__c = 1;
        app.leadBaseInf.s.DepartureDate__c = app.leadBaseInf.s.EntryDate__c.addDays(app.leadBaseInf.s.Nights__c.intValue());
        app.leadBaseInf.s.DepartureTime__c = '10:30';
        // 顧客情報を更新を行う
        //app.refreshContcatInfo();

        app.leadBaseInf.contactName = 'UNAME' + Crypto.getRandomLong();
        app.leadBaseInf.l.Field2__c = '本社';
        app.leadBaseInf.l.Segment__c = 'CARD';
        app.leadBaseInf.accoutName = 'ACC-NEW' + CommUtils.getRandom(10);
        app.leadBaseInf.s.contactRef__c = guest.Id;
        app.leadBaseInf.s.LeadName__c = 'テストケースの予約名';
        app.leadBaseInf.s.Comment__c = 'Comment_'+ CommUtils.getRandom(10);
        
        BookingFlexApp.LeadItem subItem = app.oLeadLst[0];
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
        //System.assertEquals(updLead.size(), 1);
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
        //app.refreshContcatInfo();
        app.createLeadInfo();
        updLead = [select Id, Relcontact__c from lead__c limit 1];
        //System.assertEquals(updLead[0].Relcontact__c, newGuest.id, newGuest);
    }

    @isTest(SeeAllData=false)
    static void testCase4() {
        // 予約データの明細情報を変更して、再登録する
        Test.startTest();
        getCsvSetupConfig();
        Contact guest = TestCommon.createContact();
        String guestName = guest.LastName + ' ' + guest.FirstName;
        TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
        // 新規登録
        LeadIndex__c sobj = new LeadIndex__c();
        ApexPages.StandardController contrl = new ApexPages.StandardController(sobj);
        BookingFlexApp app = new BookingFlexApp(contrl);
        /*
        Contact contactInf = BookingFlexApp.refreshContcatInfo(guest.Id, guestName, 'Name1__c,KanaName1__c,Katakana__c,Phone,ApplicantName__c,ApplicantPhone__c,Memo1__c,Memo2__c,Memo3__c');
        System.assertEquals(contactInf.Name1__c, CommUtils.nullToBlank(guest.Name1__c), contactInf);
        System.assertEquals(contactInf.KanaName1__c, CommUtils.nullToBlank(guest.KanaName1__c), contactInf);
        System.assertEquals(contactInf.Katakana__c, CommUtils.nullToBlank(guest.Katakana__c), contactInf);
        System.assertEquals(contactInf.phone, CommUtils.nullToBlank(guest.Phone), contactInf);
        //System.assertEquals(contactInf.accountName, CommUtils.nullToBlank(guest.Account.Name), contactInf);
        System.assertEquals(CommUtils.nullToBlank(contactInf.ApplicantName__c), CommUtils.nullToBlank(guest.ApplicantName__c), contactInf);
        System.assertEquals(CommUtils.nullToBlank(contactInf.ApplicantPhone__c), CommUtils.nullToBlank(guest.ApplicantPhone__c), contactInf);
        System.assertEquals(CommUtils.nullToBlank(contactInf.Memo1__c), CommUtils.nullToBlank(guest.Memo1__c), contactInf);
        System.assertEquals(CommUtils.nullToBlank(contactInf.Memo2__c), CommUtils.nullToBlank(guest.Memo2__c), contactInf);
        System.assertEquals(CommUtils.nullToBlank(contactInf.Memo3__c), CommUtils.nullToBlank(guest.Memo3__c), contactInf);
        */
    }
    @isTest(SeeAllData=false)
    static void testCase5() {
        Test.startTest();
        getCsvSetupConfig();
        
        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
        
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(3);     
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfo, productLst[0]);
        Test.stopTest();
        // Idで最新情報を取得する
        String idxName = [select LeadIndexRef__r.Name from Lead__c where id = :leadInfo.Id].LeadIndexRef__r.Name;
        List<LeadIndex__c> leadIdxLst = [select id from LeadIndex__c where name = :idxName];
        ApexPages.StandardController contrl = new ApexPages.StandardController(leadIdxLst[0]);  
        BookingFlexApp app = new BookingFlexApp(contrl);
        //app.detailMessage = '0#2016/10/17_$$$$&#124;¥n0#2016/10/17_'+ productLst[0].id +'$1500$1$$&#124;¥n0#2016/10/17_$$$$_'+ productLst[1].id +'$31110$1$a0mp00000007Fo9AAE:1110;'+ productLst[2].id +':30000;$&#124;¥n¥n¥n';
        //app.deleteMessage = leadIdxLst[0].id + ',';
        app.leadBaseInf.leadNo = idxName;
        app.refreshExistLeadInfo();
        // 顧客情報を更新を行う
        //app.refreshContcatInfo();

        app.leadBaseInf.contactName = 'UNAME' + Crypto.getRandomLong();
        app.leadBaseInf.l.Field2__c = '本社';
        app.leadBaseInf.l.Segment__c = 'CARD';
        app.leadBaseInf.accoutName = 'ACC-NEW' + CommUtils.getRandom(10);
        
        app.createLeadInfo();

        // SubIndex登録を行う
        //LeadItem item = new LeadItem();
        app.indexSubId = app.oLeadLst[0].s.Id;
        //app.expandGuestLst();
        System.assertNotEquals(app.indexSubId, null);
        //app.createGuestInfo();
        String typos = TestCommon.createTypeOfRoom().Id;
        app.psub = leadIdxLst[0].id + ',999';
        PageReference redirectChkIn = app.redirectChkIn();
        
        Room__c guestRoom = TestCommon.createRooms();
        //SObject[] IdleRoom = BookingFlexApp.getIdleRoom(guestRoom.TypeRoomRef__c,'2016/10/17','2016/10/17','2');
        app.cookieMessage = '77\\$77\\$77,88\\$88\\$11\\$22,211\\$88\\$88';
        app.setCookieInf();
    }
    @isTest(SeeAllData=false)
    static void testCase6() {
        Test.startTest();
        getCsvSetupConfig();
        
        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
        
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(3);     
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfo, productLst[0]);
        Test.stopTest();
        // Idで最新情報を取得する
        String idxName = [select LeadIndexRef__r.Name from Lead__c where id = :leadInfo.Id].LeadIndexRef__r.Name;
        List<LeadIndex__c> leadIdxLst = [select id from LeadIndex__c where name = :idxName];
        ApexPages.StandardController contrl = new ApexPages.StandardController(leadIdxLst[0]);  
        BookingFlexApp app = new BookingFlexApp(contrl);
        //app.init();
       // app.detailMessage = '0#2016/10/17_$$$$&#124;¥n0#2016/10/17_'+ productLst[0].id +'$1500$1$$&#124;¥n0#2016/10/17_$$$$_'+ productLst[1].id +'$31110$1$a0mp00000007Fo9AAE:1110;'+ productLst[2].id +':30000;$&#124;¥n¥n¥n';
       // app.deleteMessage = leadIdxLst[0].id + ',';
        app.leadBaseInf.leadNo = idxName;
        app.refreshExistLeadInfo();
        // 顧客情報を更新を行う
        //app.refreshContcatInfo();

        app.leadBaseInf.contactName = 'UNAME' + Crypto.getRandomLong();
        app.leadBaseInf.l.Field2__c = '本社';
        app.leadBaseInf.l.Segment__c = 'CARD';
        app.leadBaseInf.accoutName = 'ACC-NEW' + CommUtils.getRandom(10);
        
        app.createLeadInfo();

        // SubIndex登録を行う
        //LeadItem item = new LeadItem();
        app.indexSubId = app.oLeadLst[0].s.Id;
        //app.expandGuestLst();
        System.assertNotEquals(app.indexSubId, null);
        //app.createGuestInfo();
        String typos = TestCommon.createTypeOfRoom().Id;
        app.psub = leadIdxLst[0].id + ',999';
        PageReference redirectChkIn = app.redirectChkIn();
        
        Room__c guestRoom = TestCommon.createRooms();
        //SObject[] IdleRoom = BookingFlexApp.getIdleRoom(guestRoom.TypeRoomRef__c,'2016/10/17','2016/10/17','2');
        app.cancelSubDetail();
    }
    @isTest(SeeAllData=false)
    static void testCase7() {
        // 予約データの明細情報を変更して、再登録する
        Test.startTest();
        getCsvSetupConfig();
        Contact guest = TestCommon.createContact();
        TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
        
        // 新規登録
        LeadIndex__c sobj = new LeadIndex__c();
        ApexPages.StandardController contrl = new ApexPages.StandardController(sobj);
        BookingFlexApp app = new BookingFlexApp(contrl);
        //app.deleteMessage = '8888888,9999999999,111111111111';
        app.leadBaseInf.s.EntryDate__c = Date.today();
        app.leadBaseInf.s.EntryTime__c = '16:00';
        app.leadBaseInf.s.Nights__c = 3;
        app.leadBaseInf.s.DepartureDate__c = app.leadBaseInf.s.EntryDate__c.addDays(3);
        app.leadBaseInf.s.DepartureTime__c = '10:30';
        // 顧客情報を更新を行う
        //app.refreshContcatInfo();

        app.leadBaseInf.contactName = 'UNAME' + Crypto.getRandomLong();
        app.leadBaseInf.l.Field2__c = '本社';
        app.leadBaseInf.l.Segment__c = 'CARD';
        app.leadBaseInf.accoutName = 'ACC-NEW' + CommUtils.getRandom(10);
        app.leadBaseInf.s.contactRef__c = guest.Id;
        app.leadBaseInf.s.LeadName__c = 'テストケースの予約名';
        app.leadBaseInf.s.Comment__c = 'Comment_'+ CommUtils.getRandom(10);
        
        //LeadItem subItem = app.oLeadLst[0];
        BookingFlexApp.LeadItem subItem = app.oLeadLst[0];
        subItem.s.EntryDate__c = app.leadBaseInf.s.EntryDate__c;
        subItem.nights = '3';
        subItem.s.DepartureDate__c = app.leadBaseInf.s.DepartureDate__c;
        subItem.s.RoomTypeRef__c = typeOfRoom.Id;
        subItem.persons = String.valueOf(1);
        subItem.rooms = String.valueOf(2);
        
        app.createLeadInfo();
        
		Date amoutDt = Date.parse('2016/10/17');
		DateTime wkDt = DateTime.newInstance(amoutDt.year(),amoutDt.month(),amoutDt.day());
       // LeadIndex__c lead = TestCommon.createLeadIndex(5,wkDt,wkDt);
        //ApexPages.StandardController contrl1 = new ApexPages.StandardController(lead);
        //BookingFlexApp app1 = new BookingFlexApp(contrl1);
        // 顧客情報を更新を行う
        //app1.refreshContcatInfo();
  
        BookingFlexApp.LeadItem subItem1 = app.oLeadLst[0];
        //app1.createLeadInfo();
        
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
        //app.expandGuestLst();
        app.psub = sobj.id + ',999';
        PageReference redirectChkIn = app.redirectChkIn();
   
        Room__c guestRoom = TestCommon.createRooms();
        //SObject[] IdleRoom = BookingFlexApp.getIdleRoom(guestRoom.TypeRoomRef__c,'2016/10/17','2016/10/17','2');
        app.cancelSubDetail();
    }
    @isTest(SeeAllData=false)
    static void testCase8() {
        Plan__c plan = TestCommon.createPlan();
        SObject[] PlanInfo = BookingFlexApp.getPlanInfo(plan.id);   
        
        Room__c guestRoom = TestCommon.createRooms();
        //SObject[] IdleRoom = BookingFlexApp.getIdleRoom(guestRoom.TypeRoomRef__c,'2016/10/17','2016/10/17','2');
        BookingFlexApp.getPlanDetailListById(plan.id);
        BookingFlexApp.getArrayProductItemInfo('02');
        BookingFlexApp.getArrayProductDetailItemInfo('02');
        BookingFlexApp.getArrayProductItemInfoNoPlan('02');
        BookingFlexApp.getAccountMstLstByPlan(plan.id,'5');
    }
    @isTest(SeeAllData=false)
    static void testCase9() {
    	
        getNewCsvSetupConfig();
        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
        
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(3);     
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfo, productLst[0]);
        // Idで最新情報を取得する
        String idxName = [select LeadIndexRef__r.Name from Lead__c where id = :leadInfo.Id].LeadIndexRef__r.Name;
        List<LeadIndex__c> leadIdxLst = [select id from LeadIndex__c where name = :idxName];
        ApexPages.StandardController contrl = new ApexPages.StandardController(new Leadindex__c(id = leadInfo.LeadIndexSubId__c));  
        //contrl.
        BookingFlexApp app = new BookingFlexApp(contrl);
        //app.init();
       // app.detailMessage = '0#2016/10/17_$$$$&#124;¥n0#2016/10/17_'+ productLst[0].id +'$1500$1$$&#124;¥n0#2016/10/17_$$$$_'+ productLst[1].id +'$31110$1$a0mp00000007Fo9AAE:1110;'+ productLst[2].id +':30000;$&#124;¥n¥n¥n';
       // app.deleteMessage = leadIdxLst[0].id + ',';
        app.leadBaseInf.leadNo = idxName;
        app.refreshExistLeadInfo();
        Test.startTest();
        Plan__c p = TestCommon.createPlan();
        // 顧客情報を更新を行う
        //app.refreshContcatInfo();
        app.newLead.ReservedDate__c = system.now();
		app.preCopyAction();
		app.cloneLeadAction();
		
		app.searchLeadIdxId = leadIdxLst[0].id;
		app.queryExistLeadByLeadIndexIdByEdit();
		//app.refreshPlanLst(new Leadindex__c(id = leadInfo.LeadIndexSubId__c));
        Test.stopTest();
       
         /*
        //app.oLeadLst[0].
        app.redirectKaikei();
       
        
        User currUser = [select id, ShopCode__c,BookingFlexAppLayoutNo__c from user where id = :UserInfo.getUserId()];
    	currUser.BookingFlexAppLayoutNo__c = '01';
    	update currUser;
    	system.runAs(currUser) {
        	contrl = new ApexPages.StandardController(new Leadindex__c());  
        	Apexpages.currentpage().getparameters().put('contactid',leadInfo.Relcontact__c);
        	app = new BookingFlexApp(contrl);
        	app.changeLayoutNo();
    	}
        
        BookingFlexApp.getPlanInfos('',productLst[0].id);
        BookingFlexApp.getPlanInfos(p.id,productLst[0].id);
        BookingFlexApp.getPlanDetailListById(p.id);
        
        //BookingFlexApp.getProductItemInfo(productLst[0]);
        //p.id
        app.redirectInit();
        app.cancelClonInfo();
        app.redirectChkIn();
        app.cancelSubDetail();*/
    }
    @isTest(SeeAllData=false)
    static void testCase10(){
    	getNewCsvSetupConfig();
        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
        
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(3);     
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfo, productLst[0]);
        // Idで最新情報を取得する
        String idxName = [select LeadIndexRef__r.Name from Lead__c where id = :leadInfo.Id].LeadIndexRef__r.Name;
        List<LeadIndex__c> leadIdxLst = [select id from LeadIndex__c where name = :idxName];
        ApexPages.StandardController contrl = new ApexPages.StandardController(new Leadindex__c());  
        Apexpages.currentpage().getparameters().put('leadId',leadInfo.id);
        BookingFlexApp app = new BookingFlexApp(contrl);
        Plan__c p = TestCommon.createPlan();
        app.leadBaseInf.contactName = 'UNAME' + Crypto.getRandomLong();
        app.leadBaseInf.l.Field2__c = '本社';
        app.leadBaseInf.l.Segment__c = 'CARD';
        app.leadBaseInf.accoutName = 'ACC-NEW' + CommUtils.getRandom(10);
        Test.startTest();
        app.oLeadLst[0].s.PlanRef__c = p.id;
        app.newLead.ReservedDate__c = system.now();
        app.createleadinfo();
        Test.stopTest();
        /*
        app.oLeadLst[0].s.PlanRef__c = null;
        app.oLeadLst[0].s.AccountMasterRef__c = productLst[0].id;
        app.newLead.name ='13';
        String cnt = app.oLeadLst[0].salescnt;
        // == CommUtils.nullToblank(productLst[0].field5__c);
        app.createleadinfo();
        */
        
    }
    @isTest(SeeAllData=false)
    static void testCase11(){
       
        getNewCsvSetupConfig();
        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(3);     
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfo, productLst[0]);
        User currUser = [select id, ShopCode__c,BookingFlexAppLayoutNo__c from user where id = :UserInfo.getUserId()];
    	currUser.BookingFlexAppLayoutNo__c = '01';
    	update currUser;
    	system.runAs(currUser) {
        	ApexPages.StandardController contrl = new ApexPages.StandardController(new Leadindex__c());  
        	Apexpages.currentpage().getparameters().put('contactid',leadInfo.Relcontact__c);
        	BookingFlexApp app = new BookingFlexApp(contrl);
        	app.changeLayoutNo();
        	 app.redirectKaikei();
	        app.redirectInit();
	        app.cancelClonInfo();
	        app.redirectChkIn();
	        app.cancelSubDetail();
    	}
         Plan__c p = TestCommon.createPlan();
        BookingFlexApp.getPlanInfos('',productLst[0].id);
        BookingFlexApp.getPlanInfos(p.id,productLst[0].id);
        BookingFlexApp.getPlanDetailListById(p.id);
    }
     @isTest(SeeAllData=false)
    static void testCase12() {
        // 予約データの明細情報を変更して、再登録する
        getCsvSetupConfig();
        Contact guest = TestCommon.createContact();
        TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
         // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(3);     
        Date startDt = System.today();
        List<Lead__c> leads = TestCommon.createLead(startDt,1,3);
        // 新規登録
        LeadIndex__c sobj = new LeadIndex__c(id= leads[0].LeadIndexRef__c);
        ApexPages.StandardController contrl = new ApexPages.StandardController(sobj);
        Test.startTest();
        BookingFlexApp app = new BookingFlexApp(contrl);
        /*
        app.leadBaseInf.s.EntryDate__c = Date.today();
        app.leadBaseInf.s.EntryTime__c = '16:00';
        app.leadBaseInf.s.Nights__c = 3;
        app.leadBaseInf.s.DepartureDate__c = app.leadBaseInf.s.EntryDate__c.addDays(3);
        app.leadBaseInf.s.DepartureTime__c = '10:30';
        // 顧客情報を更新を行う
        //app.refreshContcatInfo();

        app.leadBaseInf.contactName = 'UNAME' + Crypto.getRandomLong();
        app.leadBaseInf.l.Field2__c = '本社';
        app.leadBaseInf.l.Segment__c = 'CARD';
        app.leadBaseInf.accoutName = 'ACC-NEW' + CommUtils.getRandom(10);
        app.leadBaseInf.s.contactRef__c = guest.Id;
        app.leadBaseInf.s.LeadName__c = 'テストケースの予約名';
        app.leadBaseInf.s.Comment__c = 'Comment_'+ CommUtils.getRandom(10);
        */
        //LeadItem subItem = app.oLeadLst[0];
        BookingFlexApp.LeadItem subItem = app.oLeadLst[0];
        //subItem.s.EntryDate__c = app.leadBaseInf.s.EntryDate__c;
        subItem = app.oLeadLst[0];
        subItem.nights = '4';
        subItem.s.DepartureDate__c = subItem.s.EntryDate__c.addDays(4);
        subItem.s.AccountMasterRef__c = productLst[0].id;
        app.newLead.Checkmorining__c = true;
        BookingFlexApp.LeadItem subItem1 = app.oLeadLst[1];
        subItem1.s.EntryDate__c = subItem.s.EntryDate__c;
        subItem1.s.DepartureDate__c = subItem.s.EntryDate__c.addDays(1);
        subItem1.nights = '1';
        subItem1.s.RoomTypeRef__c = typeOfRoom.id;
        subItem1.rooms = '1';
        app.createLeadInfo();
        Test.stopTest();
        // 顧客様のリスト設定する
        app.indexSubId = subItem.s.Id;
        String switchCode = app.pageSwitchCode;
        boolean commonShow = app.commentIsShow;
        String numberFor = app.getNumberFormat();
        String TaxNumberFormat = BookingFlexApp.getTaxNumberFormat();
        String currencyBmol = app.getCurrencySybmol();
        String actyPlan = app.ACTTYPE_PLAN;
        String actyPlan1 = app.ACTTYPE_PAY;
        String actyPlan2 = app.ACTTYPE_AR;
        String actyPlan3 = app.ACTTYPE_PAY_DIS_RATE;
        String actyPlan4 = app.ACTTYPE_PAY_DIS_RATE;
        String actyPlan5 = app.ACTTYPE_PAY_ADD_RATE;
        String actyPlan6 = app.refundItemString;
        //app.leadIsCancel(CommConst.LEAD_ST_NOSHOW);
        //app.expandGuestLst();
        
        //app.bulkCheckIn();
    }
    @isTest
    static void testCase13(){
    	TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
    	List<Room__c> createRooms = TestCommon.createRooms(3, typeOfRoom.Id);
    	Date startDt = System.today();
    	date endDt = startDt.addDays(1);
        List<Lead__c> leads = TestCommon.createLead(startDt,1,3);
    	Map<String,object> ajaxReq = new Map<String,object>{'ci'=>endDt.format(),'co'=> startDt.format(),'spcd' =>'','sid'=>leads[0].LeadIndexSubId__c,'ldxid'=>leads[0].LeadIndexRef__c};
  		BookingFlexApp.refreshCanAssign(JSON.serialize(ajaxReq));
  		ajaxReq = new Map<String,object>{'lid'=>leads[0].id,'id'=>createRooms[0].id,'spcd'=>''};
  		BookingFlexApp.saveLeadRoom(JSON.serialize(ajaxReq));
  		ajaxReq = new Map<String,object>{'lid'=>leads[0].id,'lock'=>true};
  		BookingFlexApp.lockRoom(JSON.serialize(ajaxReq));
        // 新規登録
        LeadIndex__c sobj = new LeadIndex__c(id= leads[0].LeadIndexRef__c);
        ApexPages.StandardController contrl = new ApexPages.StandardController(sobj);
        Test.startTest();
        getCsvSetupConfig();
        BookingFlexApp app = new BookingFlexApp(contrl);
  		app.getQuotaItemNum();
        Test.stopTest();
    }
    @isTest
    static void testCase14(){
    	//
        String xml ='<?xml version="1.0" encoding="UTF-8"?><ROOT><SHOP>'+
                    '    <SHOPCODE></SHOPCODE><FIELDS><SECTION COLNUM= "2" TITLE="ご予約の受付内容">'+
                    '                Name,$_blank_$,Relcontact__c,ReservedStatus__c,ReservedType__c,Field298__c,SalesOfficeInfoRef__c,Field2__c,ReservedDate__c,Segment__c,$_blank_$,Field315__c,CouponTypeLst__c'+
                    '            </SECTION><SECTION COLNUM= "2" TITLE="料理">'+
                    '                Field293__c,Field305__c,$_blank_$'+
                    '            </SECTION><SECTION  TITLE="ご予約の詳細内容">'+
                    '                Comment3__c'+
                    '            </SECTION><SECTION COLNUM="2">'+
                    '                Comment2__c'+
                    '            </SECTION><SECTION COLNUM= "2" TITLE="ブライダル">'+
                    '                Field370__c,Field371__c'+
                    '            </SECTION><SECTION TITLE="ご予約メール" >'+
                    '                email__c'+
                    '            </SECTION></FIELDS><REQUIREDFIELDS>'+
                    '            Name,Relcontact__c,ReservedDate__c,EntryTime__c,StayPersons__c,Field4__c,Departure__c,Field3__c'+
                    '        </REQUIREDFIELDS><COLOR>'+
                    '            lightskyblue'+
                    '        </COLOR>'+
                    '		<UPDATE> Field305__c,BookingFlag__c,clubflag__c,microbusflag__c,R_C__c  </UPDATE>' + 
                    '</SHOP></ROOT>';
        Document doc = new Document();
        doc.Name = 'BookingFlexAppLayoutDefine';
        doc.DeveloperName = doc.Name;
        doc.FolderId = UserInfo.getUserId();
        doc.Body = Blob.valueOf(xml);
        insert doc;
        Contact guest = TestCommon.createContact();
        TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
         // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(3);     
        Date startDt = System.today();
        List<Lead__c> leads = TestCommon.createLead(startDt,1,3);
        // 新規登録
        LeadIndex__c sobj = new LeadIndex__c(id= leads[0].LeadIndexRef__c);
        ApexPages.StandardController contrl = new ApexPages.StandardController(sobj);
        Test.startTest();
        BookingFlexApp app = new BookingFlexApp(contrl);
    	app.isChgConFlag = true;
    	app.newLead.Field305__c = true;
    	app.createLeadInfo();
    }
    
    private static void getCsvSetupConfig() {
    	
    	//
		Schema.DescribeSObjectResult d = LeadIndex__c.sObjectType.getDescribe();
		//return descResult.fields.getMap().keySet();
		Map<String, Schema.SObjectField> fieldsMap = d.fields.getMap();
    	
        String xml ='<?xml version="1.0" encoding="UTF-8"?><ROOT><SHOP>'+
                    '    <SHOPCODE></SHOPCODE><FIELDS><SECTION COLNUM= "2" TITLE="ご予約の受付内容">'+
                    '                Name,$_blank_$,Relcontact__c,ReservedStatus__c,ReservedType__c,Field298__c,SalesOfficeInfoRef__c,Field2__c,ReservedDate__c,Segment__c,$_blank_$,Field315__c,CouponTypeLst__c'+
                    '            </SECTION><SECTION COLNUM= "2" TITLE="料理">'+
                    '                Field293__c,Field305__c,$_blank_$'+
                    '            </SECTION><SECTION  TITLE="ご予約の詳細内容">'+
                    '                Comment3__c'+
                    '            </SECTION><SECTION COLNUM="2">'+
                    '                Comment2__c'+
                    '            </SECTION><SECTION COLNUM= "2" TITLE="ブライダル">'+
                    '                Field370__c,Field371__c'+
                    '            </SECTION><SECTION TITLE="ご予約メール" >'+
                    '                email__c'+
                    '            </SECTION></FIELDS><REQUIREDFIELDS>'+
                    '            Name,Relcontact__c,ReservedDate__c,EntryTime__c,StayPersons__c,Field4__c,Departure__c,Field3__c'+
                    '        </REQUIREDFIELDS><COLOR>'+
                    '            lightskyblue'+
                    '        </COLOR>'+
                    '</SHOP></ROOT>';
        Document doc = new Document();
        doc.Name = 'BookingFlexAppLayoutDefine';
        doc.DeveloperName = doc.Name;
        doc.FolderId = UserInfo.getUserId();
        doc.Body = Blob.valueOf(xml);
        insert doc;
    }
    private static void getNewCsvSetupConfig() {
        String xml ='<?xml version="1.0" encoding="UTF-8"?><ROOT><SHOP>'+
                    '    <SHOPCODE></SHOPCODE><FIELDS><SECTION COLNUM= "2" TITLE="ご予約の受付内容">'+
                    '                Name,$_blank_$,Relcontact__c,ReservedStatus__c,ReservedType__c,Field298__c,SalesOfficeInfoRef__c,Field2__c,ReservedDate__c,Segment__c,$_blank_$,Field315__c,CouponTypeLst__c'+
                    '            </SECTION><SECTION COLNUM= "2" TITLE="料理">'+
                    '                Field293__c,Field305__c,$_blank_$'+
                    '            </SECTION><SECTION  TITLE="ご予約の詳細内容">'+
                    '                Comment3__c'+
                    '            </SECTION><SECTION COLNUM="2">'+
                    '                Comment2__c'+
                    '            </SECTION><SECTION COLNUM= "2" TITLE="ブライダル">'+
                    '                Field370__c,Field371__c'+
                    '            </SECTION><SECTION TITLE="ご予約メール" >'+
                    '                email__c'+
                    '            </SECTION></FIELDS><REQUIREDFIELDS>'+
                    '            Name,Relcontact__c,ReservedDate__c,EntryTime__c,StayPersons__c,Field4__c,Departure__c,Field3__c'+
                    '        </REQUIREDFIELDS><COLOR>'+
                    '            lightskyblue'+
                    '        </COLOR>'+
                    '</SHOP>'+
                    '<LAYOUT>' + 
				    '	<LAYOUTLABEL>02</LAYOUTLABEL>' + 
				    '	<LAYOUTCODE>3</LAYOUTCODE>' + 
				    '	<FIELDS><SECTION COLNUM= "2" TITLE="ご予約の受付内容">'+
                    '                Name,$_blank_$,Relcontact__c,ReservedStatus__c,ReservedType__c,Field298__c,SalesOfficeInfoRef__c,Field2__c,ReservedDate__c,Segment__c,$_blank_$,Field315__c,CouponTypeLst__c'+
                    '            </SECTION><SECTION COLNUM= "2" TITLE="料理">'+
                    '                Field293__c,Field305__c,$_blank_$'+
                    '            </SECTION><SECTION  TITLE="ご予約の詳細内容">'+
                    '                Comment3__c'+
                    '            </SECTION><SECTION COLNUM="2">'+
                    '                Comment2__c'+
                    '            </SECTION><SECTION COLNUM= "2" TITLE="ブライダル">'+
                    '                Field370__c,Field371__c'+
                    '            </SECTION><SECTION TITLE="ご予約メール" >'+
                    '                email__c'+
                    '            </SECTION></FIELDS><REQUIREDFIELDS>'+
                    '            Name,Relcontact__c,ReservedDate__c,EntryTime__c,StayPersons__c,Field4__c,Departure__c,Field3__c'+
                    '        </REQUIREDFIELDS><COLOR>'+
                    '            lightskyblue'+
                    '        </COLOR>'+
				    '</LAYOUT> '+
                    '</ROOT>';
        Document doc = new Document();
        doc.Name = 'BookingFlexAppLayoutDefine';
        doc.DeveloperName = doc.Name;
        doc.FolderId = UserInfo.getUserId();
        doc.Body = Blob.valueOf(xml);
        insert doc;
        
    }                 
}