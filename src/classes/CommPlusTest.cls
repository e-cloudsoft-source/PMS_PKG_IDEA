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
private class CommPlusTest {

    static testMethod void CalendarExtendTest() {
        // TO DO: implement unit test
        CommDefine__c comDef = TestCommon.createCommDefine();
        TestCommon.createBatchRequestXml();
    	String defaultTier = comDef.RackRateTableTierDefault__c;
    	String defaultPeos = comDef.RackRateTablePeopleDefault__c;
    	Date dt = Date.today();
        // 祝日情報作成
        createHolidayDoc();
        // 部屋と宴会場データ作成
        Room__c enkaiRoom = TestCommon.createEnkaiRooms();
        // 客室情報を作成する
        Room__c guestRoom = TestCommon.createRooms();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Room__c where UseOfRoom__c = '客室'].size(), 1);
        // 2015/12/01 Assert END
        // Tier情報設定を行う
        RackRateTable__c raceRate = TestCommon.createRaceRateInfo(guestRoom.TypeRoomRef__c, defaultTier, defaultPeos);
        // 当日予約日データを作成する、集計情報を確認する
        // 宴会場予約作成
        Lead__c enkaiLead = TestCommon.createEnkaiLead(dt, enkaiRoom.Id);
        // 普通の予約情報を作成する
        Lead__c normalLead = TestCommon.createBookingLead(dt, guestRoom.TypeRoomRef__c, 0);
        
        Test.startTest();
        // Calendar表示する
        CalendarExtend cal = new CalendarExtend();
        cal.thisYear = 2014;
        cal.thisMonth = 1;
        cal.gotoYearMonth();
        cal.toPrev();
        cal.toNext();
        Test.stopTest();
        
        DatePickerCtrl d = new DatePickerCtrl();
    }
    private static void createHolidayDoc() {
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'HolidayDefineXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf('<root><year value="2014">'
    				+'<dates label="元日">2014/01/01</dates>'
    				+'<dates label="成人の日">2014/01/13</dates>'
    				+'<dates label="春分の日">2014/03/21</dates>'
    				+'<dates label="文化の日">2014/11/03</dates>'
    				+'</year></root>');
    	insert item;
    }
    static testMethod void DeleteCallInfoScedulerTest() {
        // TO DO: implement unit test
        DeleteCallInfoSceduler del = new DeleteCallInfoSceduler();
    	String sch = getScheduleTime();
    	System.schedule('AAAA', sch, del);
    	
    	DeleteCallInfoSceduler.checkCallInformationPermission();
    	
    	DeleteCallInfoSceduler.HttpCalloutMockImpl http = new DeleteCallInfoSceduler.HttpCalloutMockImpl();
    	http.respond(new HTTPRequest());
    }
    private static String getScheduleTime() {
    	DateTime nowTime = DateTime.now().addSeconds(10);
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
		return sch;
    }
    static testMethod void MessageInformationCtrlTest0() {
        // 別ページからINCLUDE True
    	Apexpages.currentPage().getParameters().put('frame','0');
    	
        MessageInformationCtrl m = new MessageInformationCtrl();
        
        System.assertEquals(m.isIncludeMode, true);
        System.assertEquals(m.numberOfDispRec, 6);
        
    }
    static testMethod void MessageInformationCtrlTest1() {
        // TO DO: implement unit test
    	CommDefine__c comm = TestCommon.createCommDefine();
    	comm.IotNormalStatusAlertFlg__c = false;
    	update comm;
    	
    	List<MessageInformation__c> mInfoLst = new List<MessageInformation__c>();
    	mInfoLst.add(new MessageInformation__c(MessageType__c = 'IOT', MessageLevel__c = 'Info'));
    	mInfoLst.add(new MessageInformation__c());
    	
    	insert mInfoLst;
    	
        MessageInformationCtrl m = new MessageInformationCtrl();
        
        System.assertEquals(m.isIncludeMode, false);
        System.assertEquals(m.messageLst.Size(), 1);
    }
    static testMethod void MessageInformationCtrlTest2() {
        // TO DO: implement unit test
        // limit 0
    	CommDefine__c comm = TestCommon.createCommDefine();
    	comm.maxrecords_DSP__c = 1;
    	update comm;
    	
    	List<MessageInformation__c> mInfoLst = new List<MessageInformation__c>();
    	mInfoLst.add(new MessageInformation__c(MessageType__c = 'IOT', MessageLevel__c = ''));
    	mInfoLst.add(new MessageInformation__c(MessageType__c = '', MessageLevel__c = 'Info'));
    	
    	insert mInfoLst;
    	
        MessageInformationCtrl m = new MessageInformationCtrl();
        
        System.assertEquals(m.isIncludeMode, false);
        System.assertEquals(m.messageLst.Size(), 1);
    }
    static testMethod void PdfAutoSaveUtilTest() {
        // TO DO: implement unit test
        Map<String, String> paramMap = new Map<String, String>{'g' => '1', 'gno' => '0'};
        Lead__c lead1 = TestCommon.createLead();
    	lead1.Field298__c = CommConst.LEAD_GUEST_ST_CI;
    	update lead1;
        Room__c newRoom = TestCommon.createRooms(lead1.refTypeOfRooms__c);
    	String leadId = lead1.Id;
    	String roomId = lead1.Rroom__c;
    	List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadId];
        PdfAutoSaveUtil.syncAccountPdfToAtta(paramMap, accObjLst[0].Id, '/apex/LeadPDF');
        PdfAutoSaveUtil.syncBillPdfToAtta(paramMap, accObjLst[0].Id, '/apex/LeadPDF');
        //PdfAutoSaveUtil.syncLeadPdfToAtta(paramMap, leadId, '/apex/LeadPDF');
        // 共通定義により、PDF自動作成する、しない確認する[会計書]
        PdfAutoSaveUtil.isRunAutoPdfFutureForAccount();
        // 共通定義により、PDF自動作成する、しない確認する[請求書]
        PdfAutoSaveUtil.isRunAutoPdfFutureForBill();
        // 共通定義により、PDF自動作成する、しない確認する[見積書]
        PdfAutoSaveUtil.isRunAutoPdfFutureForEst();
    }
    static testMethod void ReportXmlParserHelperTest0() {
        // TO DO: implement unit test
        ReportXmlParserHelper.getPdfPagePaperSize('else');
        ReportXmlParserHelper.getPdfPagePaperSize('A4');
        ReportXmlParserHelper.getPdfPagePaperSize('A3');
        ReportXmlParserHelper.getPdfPagePaperSize('A5');
        ReportXmlParserHelper.getPdfPagePaperSize('B4');
        ReportXmlParserHelper.getPdfPagePaperSize('B5');
        
        ReportXmlParserHelper.convertXmlTagToHtml(null);
    }
    // テストケース
	static testmethod void ReportXmlParserHelperTest1() {
		// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'CashRegisterCardPdfConfig';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf('<root><SHOP><SHOPCODE></SHOPCODE><MEMO_OUTPUTFIELD><LEAD>Field293__c,Name,Field354__c:料理補足,Relcontact__r.Field28__c:注意事項,Comment3__c,Relcontact__r.Level__c,Relcontact__r.Name</LEAD><YADOCHOU>Field13__c:特記事項,Field15__r.name,Field11__c :御部屋名,Field12__c:宿泊日</YADOCHOU> </MEMO_OUTPUTFIELD>'
						    	+'<YADOTYO_CUSTOME_DEF>'
								+'	<LINE_NUMBER>5</LINE_NUMBER>'
								+'	<ROWS>'
								+'		<ROW>'
								+'			<COL STYLE="width:135px;display:inline-block;">■ ご宿泊の趣旨</COL>'
								+'			<COL STYLE="width:125px;display:inline-block;">お祝い（</COL>'
								+'			<COL STYLE="width:275px;display:inline-block;">　） ビジネス　観光　その他（　</COL>'
								+'			<COL STYLE="display:inline-block;">　）</COL>'
								+'		</ROW>'
								+'		<ROW>'
								+'			<COL STYLE="width:135px;display:inline-block;">■ ご利用の経緯</COL>'
								+'			<COL STYLE="width:164px;display:inline-block;">当館のホームページをみて</COL>'
								+'			<COL STYLE="width:236px;display:inline-block;">知人の紹介（ご紹介者</COL>'
								+'			<COL STYLE="display:inline-block;">　）</COL>'
								+'		</ROW>'
								+'		<ROW>'
								+'			<COL STYLE="position:relative;">'
								+'				<UNDERLINE STYLE="height:28px;width:90%;" REPEAT="3"/>'
								+'				<SQUARE STYLE="height:38px; width:38px; position:absolute;right:0;bottom:0;"></SQUARE>'
								+'			</COL>'
								+'		</ROW>'
								+'	</ROWS>'
								+'</YADOTYO_CUSTOME_DEF>'
    							+'</SHOP></root>');
    	insert item;
        // Report Logo作成
        TestCommon.createRepLogo();
 		User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	loginUser.ShopCode__c = null;
    	update loginUser;
        //update loginUser;
        System.runAs(loginUser) {
        Contact guest = TestCommon.createContact();
        Contact guest1 = TestCommon.createContact();
        Contact guest2 = TestCommon.createContact();
        // お客様作成
    	Contact cont = TestCommon.createContact();
    	//cont.Field28__c = 'QQQQQWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMWWWWWWWMWWMMWMWMWMWMMWQQQQQWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMWWWWWWWMWWMMWMWMWMWMMW';
        update cont;
        // 明細情報を登録して、保存する処理
        List<Lead__c> leads = TestCommon.createLead(Date.today(), 1,2,guest.Id);
        for (Lead__c lead : leads) {
        	lead.Field293__c = '18:30';
       	 	lead.Morningtime__c = '7:00';
       	 	lead.Field354__c = 'QQQQQWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMWWWWWWWMWWMMWMWMWMWMMWQQQQQWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMWWWWWWWMWWMMWMWMWMWMMW';
       	 	lead.Relcontact__c = cont.Id;
        }
        update leads;
        
        Yadochou__c yadochou = new Yadochou__c(
            Name = 'TestCode',
            Field1__c = leads[0].Id,
            Field15__c = guest.Id
        );
        insert yadochou;
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

        // PDF書を取得する
        ApexPages.StandardController contrl1 = new ApexPages.StandardController(yadochou);
        CashRegisterCardPDF ctrl1 = new CashRegisterCardPDF(contrl1);
        ctrl1.pdf4Init();
        System.assertEquals(ctrl1.getAvailable1().size(), 3);
        System.assertEquals(ctrl1.getAvailable2().size(), 3);
        System.assertEquals(ctrl1.getPointInfo1().size(), 3);
        System.assertEquals(ctrl1.getPointInfo2().size(), 4);
        
        ReportLogo__c rep = ctrl1.ReportInfo;
        System.assertEquals(ctrl1.bulkAllPageList.size(), 1);
        CashRegisterCardPDF.OnePage oPage = ctrl1.bulkAllPageList[0].allPageList[0];
        // Default Page Size 7(レジカードコードは１の場合)
        System.assertEquals(oPage.onePageList.size(), 5);
        
        Test.stopTest();
        }
	}
}