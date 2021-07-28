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
private class CashRegisterCardPDFTest {

	// テストケース
	static testmethod void testRateUnit() {

		// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'CashRegisterCardPdfConfig';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf('<root><SHOP><SHOPCODE></SHOPCODE><MEMO_OUTPUTFIELD><LEAD>Relcontact__r.Phone,Comment3__c,Relcontact__r.Name </LEAD><YADOCHOU>Field13__c:特記事項,Field15__r.name,Field11__c :御部屋名,Field12__c:宿泊日</YADOCHOU></MEMO_OUTPUTFIELD></SHOP></root>');
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
        
        Lead__c lead = TestCommon.createLead();
        lead.Field293__c = '18:30';
        lead.Morningtime__c = '7:00';
        update lead;
        
        Yadochou__c yadochou = new Yadochou__c(
            Name = 'TestCode',
            Field1__c = lead.Id,
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
        // 画面遷移を行う
        ApexPages.StandardController contrl0 = new ApexPages.StandardController(yadochou);
         CashRegisterCardPDF ctrl0 = new CashRegisterCardPDF(contrl0);
        PageReference pg = ctrl0.switchPdf();
        PageReference sign = ctrl0.switchSign();
        // PDF書を取得する
        ApexPages.StandardController contrl1 = new ApexPages.StandardController(yadochou);
        CashRegisterCardPDF ctrl1 = new CashRegisterCardPDF(contrl1);
        ctrl1.pdfInit();
        System.assertEquals(ctrl1.getAvailable1().size(), 3);
        System.assertEquals(ctrl1.getAvailable2().size(), 3);
        System.assertEquals(ctrl1.getPointInfo1().size(), 3);
        System.assertEquals(ctrl1.getPointInfo2().size(), 4);
        
        ReportLogo__c rep = ctrl1.ReportInfo;
        System.assertEquals(ctrl1.bulkAllPageList.size(), 1);
        CashRegisterCardPDF.OnePage oPage = ctrl1.bulkAllPageList[0].allPageList[0];
        // Default Page Size 7(レジカードコードは１の場合)
        System.assertEquals(oPage.onePageList.size(), 7);
        
        Test.stopTest();
        }
	}
	
	// テストケース
	static testmethod void testCode4() {
		// 2019/11/13 BY zyz BEGIN
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	comDef.ReducedTaxRateFlg__c = true;
    	comDef.PDFPlanBrkIsShowFlg__c = true;
    	update comDef;
    	// 2019/11/13 BY zyz END
		// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'CashRegisterCardPdfConfig';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf('<root><SHOP><SHOPCODE></SHOPCODE><MEMO_OUTPUTFIELD><LEAD>Field293__c,Name,Field354__c:料理補足,Relcontact__r.Field28__c:注意事項,Comment3__c,Relcontact__r.Level__c,Relcontact__r.Name</LEAD><YADOCHOU>Field13__c:特記事項,Field15__r.name,Field11__c :御部屋名,Field12__c:宿泊日</YADOCHOU> </MEMO_OUTPUTFIELD></SHOP></root>');
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
        // 2019/11/13 BY zyz BEGIN
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(4);
        // 見積明細を作成する
        TestCommon.createBookEstItem(leads[0], productLst[0]);
        // 2019/11/13 BY zyz END
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
	// テストケース
	static testmethod void testCode2() {
		// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'CashRegisterCardPdfConfig';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf('<root><SHOP><SHOPCODE></SHOPCODE><MEMO_OUTPUTFIELD ALWAYSTITLE="TRUE"><LEAD>Relcontact__r.Phone,Comment3__c,Relcontact__r.Name </LEAD><YADOCHOU>Field13__c:特記事項,Field15__r.name,Field11__c :御部屋名,Field12__c:宿泊日</YADOCHOU></MEMO_OUTPUTFIELD><YADOTYO_CUSTOME_DEF><ROWS><ROW><UNDERLINE REPEAT="2">$$_Field15__c_$$</UNDERLINE></ROW></ROWS></YADOTYO_CUSTOME_DEF></SHOP></root>');
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
        update cont;
        // 明細情報を登録して、保存する処理
        List<Lead__c> leads = TestCommon.createLead(Date.today(), 1,2,guest.Id);
        for (Lead__c lead : leads) {
        	lead.Field293__c = '18:30';
       	 	lead.Morningtime__c = '7:00';
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
        // 2019/11/13 BY zyz BEGIN
        CashRegisterCardPDF.refreshsignatureInfo(yadochou.Id,' ');
        CashRegisterCardPDF.refreshCanvasInfo(yadochou.Id,new list<String>());
        // 2019/11/13 BY zyz END
        ctrl1.pdf4Init();
        System.assertEquals(ctrl1.getAvailable1().size(), 3);
        System.assertEquals(ctrl1.getAvailable2().size(), 3);
        System.assertEquals(ctrl1.getPointInfo1().size(), 3);
        System.assertEquals(ctrl1.getPointInfo2().size(), 4);
        
        ReportLogo__c rep = ctrl1.ReportInfo;
        System.assertEquals(ctrl1.bulkAllPageList.size(), 1);
        CashRegisterCardPDF.OnePage oPage = ctrl1.bulkAllPageList[0].allPageList[0];
        // Default Page Size 7(レジカードコードは１の場合)
        System.assertEquals(oPage.onePageList.size(), 7);
        
        Test.stopTest();
        }
	}
	// PDF5 BEGIN
	// テストケース
	static testmethod void testRateUnitPDF() {
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
    	comDef.ReducedTaxRateFlg__c = true;
    	comDef.PDFPlanBrkIsShowFlg__c = true;
    	update comDef;
    	// 2019/07/30 軽減税率機能対応 WGCH END
		// ドキュメントを作成する
		Document item = new Document();
		item.Name = 'CashRegisterCardPdfConfig';
		item.DeveloperName = item.Name;
		item.FolderId = UserInfo.getUserId();
		item.Body = Blob.valueOf('<root><SHOP><SHOPCODE></SHOPCODE><MEMO_OUTPUTFIELD><LEAD>Relcontact__r.Name </LEAD><YADOCHOU>Field13__c:特記事項</YADOCHOU></MEMO_OUTPUTFIELD><YADOTYO_BULK_PDF><FILTER>Field1__r.EntryTime__c != null</FILTER></YADOTYO_BULK_PDF></SHOP></root>');
		insert item;
		// Report Logo作成
		TestCommon.createRepLogo();
		User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
		loginUser.ShopCode__c = '02';
		update loginUser;
		ShopInformation__c shopInfo = TestCommon.createShopInfo();
		shopInfo.FacilityCode__c = '23';
		shopInfo.shopCode__c = '02';
		update shopInfo;
		Room__c rooms = TestCommon.createRooms();
		rooms.ShopInfoRef__c = shopInfo.Id;
		update rooms;
		//update loginUser;
		System.runAs(loginUser) {
			Contact guest = TestCommon.createContact();
			update guest;
			Lead__c lead = new Lead__c(
				RecordTypeId = CommLogicProcess.getLeadEnkaiRecType(),
				name = '予約単体テスト_宴会場' + System.now(), // 予約名
				Relcontact__c = guest.Id,                  // 顧客名
				ReservedStatus__c = '確認中',
				ReservedDate__c = System.now(),
				ReservedContact__c = 'Ono',
				EntryTime__c = Date.today(),
				Field4__c = '00:00',
				Departure__c = Date.today() + 1,
				Field3__c = '16:00',
				StayPersons__c = 4,
				Rroom__c = rooms.Id,
				Field2__c = 'FAX'
			);
			insert lead;
			Yadochou__c yadochou = new Yadochou__c(
				Field1__c = lead.Id,
				Field15__c = guest.Id,
				Name = guest.Name,
				Field13__c = '34536'
			);
			insert yadochou;
			// Report Logo作成
			ReportLogo__c replogo = TestCommon.createRepLogo();
			replogo.ShopInfoRef__c = shopInfo.Id;
			update replogo;
			Test.startTest();
			// PDF書を取得する
			ApexPages.StandardController contrl1 = new ApexPages.StandardController(yadochou);
			CashRegisterCardExtPDF ctrl1 = new CashRegisterCardExtPDF(contrl1);
			Apexpages.currentPage().getParameters().put('cardDate',String.valueOf(Date.today()));
			Apexpages.currentPage().getParameters().put('cardCd','02');
			ctrl1.initPdf();
			        
			System.assertEquals(ctrl1.bulkAllPageList.size(), 2);
			CashRegisterCardExtPDF.OnePage oPage = ctrl1.bulkAllPageList[0][0].allPageList[0];
			System.assertEquals(oPage.onePageList.size(), 1);
			Test.stopTest();
		}
	}
	// テストケース
	static testmethod void testRateUnitPDF5() {
    	//CommDefine__c comDef = TestCommon.createCommDefine();
		CommDefine__c newDef = new CommDefine__c(
			ReducedTaxRateFlg__c = true,
			PDFPlanBrkIsShowFlg__c = true,
			CashRegSaveLeadCheckInFlg__c = true,
			CashRegisterSwitchCode__c = '7'
		);	
		insert newDef;
		// ドキュメントを作成する
		Document item = new Document();
		item.Name = 'CashRegisterCardPdfConfig';
		item.DeveloperName = item.Name;
		item.FolderId = UserInfo.getUserId();
		item.Body = Blob.valueOf('<root><SHOP><SHOPCODE></SHOPCODE><MEMO_OUTPUTFIELD ALWAYSTITLE="TRUE"><LEAD>Field293__c,Name,Field354__c:料理補足,Relcontact__r.Field28__c:注意事項,Comment3__c,Relcontact__r.Level__c,Relcontact__r.Name</LEAD><YADOCHOU>Field13__c:特記事項,Field15__r.name,Field11__c :御部屋名,Field12__c:宿泊日</YADOCHOU> </MEMO_OUTPUTFIELD><STAYCARD_6><NATIONALITY><LEAD>Field302__c</LEAD></NATIONALITY><PASSPORT><LEAD>Relcontact__r.Phone</LEAD></PASSPORT><ARRIVEDFROM><LEAD>Comment1__c</LEAD></ARRIVEDFROM><NEXTDESTINATION><LEAD>email__c</LEAD></NEXTDESTINATION><CUSTOM_SIGNATURE>私は署名します。</CUSTOM_SIGNATURE><LOGO_POS_TOPLEFT_FLG WIDTH="245px" HEIGHT="70px">FALSE</LOGO_POS_TOPLEFT_FLG><CUSTOM><ROW><COL>Field15__r.Phone:Phone number&lt;br/&gt;電話</COL><COL>Field15__r.Email:Email&lt;br/&gt;メールアドレス</COL></ROW></CUSTOM></STAYCARD_6><YADOTYO_STAYCARD>Field15__c:顧客</YADOTYO_STAYCARD></SHOP></root>');
		insert item;
		// Report Logo作成
		TestCommon.createRepLogo();
		User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
		loginUser.ShopCode__c = null;
		update loginUser;
		ShopInformation__c shopInfo = TestCommon.createShopInfo();
		shopInfo.FacilityCode__c = '23';
		shopInfo.shopCode__c = '02';
		update shopInfo;
		Room__c rooms = TestCommon.createRooms();
		rooms.ShopInfoRef__c = shopInfo.Id;
		update rooms;
		//update loginUser;
		System.runAs(loginUser) {
			Contact guest = TestCommon.createContact();
			// お客様作成
			Contact cont = TestCommon.createContact();
			update cont;
			// 明細情報を登録して、保存する処理
			List<Lead__c> leads = TestCommon.createLead(Date.today(), 1,2,guest.Id);
			for (Lead__c lead : leads) {
				lead.Field293__c = '18:30';
				lead.Morningtime__c = '7:00';
				lead.Field354__c = 'QQQQQWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMWWWWWWWMWWMMWMWMWMWMMWQQQQQWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMWWWWWWWMWWMMWMWMWMWMMW';
				lead.Relcontact__c = cont.Id;
				lead.EntryTime__c = Date.today();
				lead.Field4__c = '00:00';
				lead.Departure__c = Date.today() + 1;
				lead.Field3__c = '16:00';
				lead.StayPersons__c = 4;
				lead.Rroom__c = rooms.Id;
			}
			update leads;
			Yadochou__c yadochou = new Yadochou__c(
				Name = 'TestCode',
				Field1__c = leads[0].Id,
				Field15__c = guest.Id,
				Field13__c = 'shuzhang'
			);
			insert yadochou;
			Test.startTest();
			
			// PDF書を取得する
			ApexPages.StandardController contrl1 = new ApexPages.StandardController(yadochou);
			CashRegisterCardExtPDF ctrl1 = new CashRegisterCardExtPDF(contrl1);
			CashRegisterCardExtPDF.refreshsignatureInfo(yadochou.Id,' ');
			// 2019/11/13 BY zyz BEGIN
			CashRegisterCardExtPDF.refreshCanvasInfo(yadochou.Id,new list<String>());
			// 2019/11/13 BY zyz END
			Apexpages.currentPage().getParameters().put('cardDate',String.valueOf(Date.today()));
			Apexpages.currentPage().getParameters().put('cardCd','02');
			ctrl1.initPdf();
			// 2019/11/13 BY zyz BEGIN
			ctrl1.getNumberFormat();
			ctrl1.initPdfSign();
			// 2019/11/13 BY zyz END
			        
			ReportLogo__c rep = ctrl1.ReportInfo;
			System.assertEquals(ctrl1.bulkAllPageList.size(), 2);
			Test.stopTest();
		}
	}
	// PDF5 END
	// pdf8对应class
	static testmethod void testRateUnitPDF8() {
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	comDef.CashRegisterSwitchCode__c = '8';
    	comDef.CashRegisterAutoCreateFlg__c = true;
    	update comDef;
		// ドキュメントを作成する
		Document item = new Document();
		item.Name = 'CashRegisterCardPdfConfig';
		item.DeveloperName = item.Name;
		item.FolderId = UserInfo.getUserId();
		item.Body = Blob.valueOf('<root><SHOP><SHOPCODE></SHOPCODE><STAYCARD_8><PAGESIZE BUBO="false">A5</PAGESIZE><HEADER><ROW><COL STYLE="font-size:18pt;">STAY CARD 宿泊者カード</COL><COL STYLE="text-align:right;vertical-align: bottom;">$$_Field1__r.LeadReceiptDate__c_$$</COL></ROW></HEADER><BODY COLGROUP="17%,10%,13%,10%,17%,10%,13%,10%"><ROW><COL STYLE="text-align:center;" >Name$_br_$お名前</COL><COL STYLE="" SPANNUM="7">$$_Field1__r.name_$$</COL></ROW><ROW><COL STYLE="text-align:center;" >特記事項$_br_$memo</COL><COL SPANNUM="3" STYLE="text-align:center;" >$$_Field13__c_$$</COL><COL STYLE="text-align:center;" >会場$_br_$memo</COL><COL SPANNUM="3" STYLE="text-align:center;" >$$_Field1__r.Layout__c_$$</COL></ROW></BODY><FOOTER><ROW><COL STYLE="text-align:center;">$_LOGO_$</COL></ROW></FOOTER></STAYCARD_8></SHOP></root>');
		insert item;
		// Report Logo作成
		TestCommon.createRepLogo();
		User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
		loginUser.ShopCode__c = null;
		update loginUser;
		ShopInformation__c shopInfo = TestCommon.createShopInfo();
		shopInfo.FacilityCode__c = '23';
		shopInfo.shopCode__c = '02';
		update shopInfo;
		Room__c rooms = TestCommon.createRooms();
		rooms.ShopInfoRef__c = shopInfo.Id;
		update rooms;
		//update loginUser;
		System.runAs(loginUser) {
			Contact guest = TestCommon.createContact();
			// お客様作成
			Contact cont = TestCommon.createContact();
			update cont;
			// 明細情報を登録して、保存する処理
			List<Lead__c> leads = TestCommon.createLead(Date.today(), 1,2,guest.Id);
			for (Lead__c lead : leads) {
				lead.Field293__c = '18:30';
				lead.Morningtime__c = '7:00';
				lead.Field354__c = 'QQQQQWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMWWWWWWWMWWMMWMWMWMWMMWQQQQQWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMWWWWWWWMWWMMWMWMWMWMMW';
				lead.Relcontact__c = cont.Id;
				lead.EntryTime__c = Date.today();
				lead.Field4__c = '00:00';
				lead.Departure__c = Date.today() + 1;
				lead.Field3__c = '16:00';
				lead.StayPersons__c = 4;
				lead.Rroom__c = rooms.Id;
			}
			update leads;
			Yadochou__c yadochou = new Yadochou__c(
				Name = 'TestCode',
				Field1__c = leads[0].Id,
				Field15__c = guest.Id,
				Field13__c = 'shuzhang'
			);
			insert yadochou;
			Test.startTest();
			
			// PDF書を取得する
			ApexPages.StandardController contrl1 = new ApexPages.StandardController(yadochou);
			CashRegisterCardExtPDF ctrl1 = new CashRegisterCardExtPDF(contrl1);
			Apexpages.currentPage().getParameters().put('cardDate',String.valueOf(Date.today()));
			Apexpages.currentPage().getParameters().put('cardCd','02');
			ctrl1.initPdf();
			        
			ReportLogo__c rep = ctrl1.ReportInfo;
			System.assertEquals(ctrl1.bulkAllPageList.size(), 2);
			Test.stopTest();
		}
	}
}