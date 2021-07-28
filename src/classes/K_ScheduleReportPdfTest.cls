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
private class K_ScheduleReportPdfTest {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        Test.startTest();
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'ScheduleReportFieldsXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf('<root><SHOP>'+
								'<SHOPCODE></SHOPCODE>'+
								'<FIELDS SHOWFOOD="true">Morningtime__c:朝食時間,Relcontact__r.Name:お客様,EntryTime__c:到着日</FIELDS>'+
								'<AGGREGATE>StayPersons__c</AGGREGATE>'+
								'<EXPORTPDF><FIELDS></FIELDS><MAXWIDTH>5000</MAXWIDTH></EXPORTPDF>'+
								'</SHOP></root>');
    	insert item;
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	Test.stopTest();
    	
    	K_ScheduleReportPdf rp = new K_ScheduleReportPdf();
    	rp.init();
        
    }
    static testMethod void myUnitTest2() {
    	CommDefine__c def = TestCommon.createCommDefine();
    	def.ReportKScheduleWhere__c = '会席,お膳,単品,仕出し,朝食:1';
    	update def;
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'ScheduleReportFieldsXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf('<root><SHOP>'+
								'<SHOPCODE></SHOPCODE>'+
								'<FIELDS >refTypeOfRooms__r.ShopInfoRef__r.Name:支店,Rroom__r.Seq__c:SEQ,Relcontact__r.ApplicantName__c:申込者,Rroom__r.Name:部屋,Relcontact__r.Name:お客様名,LeadIndexRef__r.Name:予約名,StayPersons__c:StayPersons</FIELDS>'+
								'<AGGREGATE>StayPersons__c,EntryTime__c</AGGREGATE>'+
								'<EXPORTPDF><FIELDS SHOWFOOD="true">Morningtime__c:朝食時間,Relcontact__r.Name:お客様,EntryTime__c:到着日,StayPersons__c:StayPersons</FIELDS><MAXWIDTH>5000</MAXWIDTH></EXPORTPDF>'+
								'</SHOP></root>');			
    	insert item;
    	Test.startTest();
    	ShopInformation__c shopInfo = new ShopInformation__c(
    		Name='東京都新宿区２号店'
    		,Fax__c = '03-1111-2222'
    		,Seq__c = Integer.valueOf(CommUtils.getRandom(8))
    		,WebSite__c = 'http://www.branch002.softpark.com'
    		,Email__c = 'east.baranch0002@softpark.com'
    		,Address__c = '東京都新宿区１番地２３手目４０６号'
    		,ShopCode__c = '02'
    		,Phone__c = '03-0222-11111'
    		,Post__c = '19100011'
    		,TierDefault__c = 'Tier1'
    		,FacilityCode__c = CommUtils.getRandom(4)
    	);
    	insert shopInfo;
    	List<TypeOfRooms__c> typeOfRoom = TestCommon.createTypeOfRoomByShop(shopInfo.Id,1);
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	leadInfo.Rroom__c = null;
    	List<Lead__c> updLeads1= new List<Lead__c>{leadInfo};
    	update updLeads1;
    	Test.stopTest();
   		Lead__c leadInfo2 = TestCommon.createLead();
   		ExchangeRate__c rate = TestCommon.createExchangeRate();
    	
    	leadInfo2.Field298__c = 'チェックイン完';
    	
    	List<Lead__c> updLeads = new List<Lead__c>{leadInfo2};
    	update updLeads;
		
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 2015/12/01 Assert BEGIN
        System.assertEquals(productLst.size(), 1);
        // 2015/12/01 Assert END
    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo2, productLst[0]);
    	RsvAccount__c rsv = TestCommon.createRsvAccount();
    	AccountAcount__c aa = TestCommon.createAccountAcount(rsv.Id, leadInfo2.Id);
    	AccountAcount__c bb = TestCommon.createAccountAcount(rsv.Id, leadInfo.Id);
    	K_ScheduleReportPdf rp = new K_ScheduleReportPdf();
    	rp.init();
    }
    static testMethod void myUnitTest3() {
    	CommDefine__c def = TestCommon.createCommDefine();
    	def.ReportKScheduleWhere__c = '会席,お膳,単品,仕出し,朝食:1';
    	update def;
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'ScheduleReportFieldsXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf('<root><SHOP>'+
								'<SHOPCODE></SHOPCODE>'+
								'<FIELDS >refTypeOfRooms__r.ShopInfoRef__r.Name:支店,Rroom__r.Seq__c:SEQ,Relcontact__r.ApplicantName__c:申込者,Rroom__r.Name:部屋,Relcontact__r.Name:お客様名,LeadIndexRef__r.Name:予約名</FIELDS>'+
								'<AGGREGATE>StayPersons__c</AGGREGATE>'+
								'<EXPORTPDF><FIELDS>refTypeOfRooms__r.ShopInfoRef__r.Name:支店</FIELDS><MAXWIDTH>5000</MAXWIDTH></EXPORTPDF>'+
								'</SHOP></root>');	
    	insert item;
    	Test.startTest();
    	// 予約情報を作成する
    	//Lead__c leadInfo = TestCommon.createLead();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 2015/12/01 Assert BEGIN
        System.assertEquals(productLst.size(), 1);
        // 2015/12/01 Assert END
    	// マージ元の取引先情報を作成する
		Account FrAccounts = TestCommon.createNormalAccount();
		Id toAccountId = FrAccounts.Id;
    	// 予約関連[旅行会社情報]
		Lead__c travLead = TestCommon.createBookingLead(Date.today(), null, 1);
		travLead.SalesOfficeInfoRef__c = toAccountId;
		update travLead;
		// 見積明細を作成する
    	TestCommon.createBookEstItem(travLead, productLst[0]);
    	RsvAccount__c rsv = TestCommon.createRsvAccount();
    	AccountAcount__c aa = TestCommon.createAccountAcount(rsv.Id, travLead.Id);
    	
    	Test.stopTest();
   		Lead__c leadInfo2 = TestCommon.createLead();
    	leadInfo2.Field298__c = 'チェックイン完';
    	List<Lead__c> updLeads = new List<Lead__c>{leadInfo2};
    	update updLeads;

    	K_ScheduleReportPdf rp = new K_ScheduleReportPdf();
    	rp.init();
    }
    static testMethod void myUnitTest4() {
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'ScheduleReportFieldsXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf('<root><SHOP>'+
								'<SHOPCODE></SHOPCODE>'+
								'<FIELDS >refTypeOfRooms__r.ShopInfoRef__r.Name:支店,Rroom__r.Seq__c:SEQ,Relcontact__r.ApplicantName__c:申込者,Rroom__r.Name:部屋,Relcontact__r.Name:お客様名,LeadIndexRef__r.Name:予約名</FIELDS>'+
								'<AGGREGATE>StayPersons__c</AGGREGATE>'+
								'<EXPORTPDF><FIELDS>refTypeOfRooms__r.ShopInfoRef__r.Name:支店</FIELDS><MAXWIDTH>5000</MAXWIDTH></EXPORTPDF>'+
								'</SHOP></root>');	
    	insert item;
    	Test.startTest();
    	// 店舗情報を初期化する
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	// 施設コード     
    	comDef.FacilityCode__c = '33';
    	comDef.AccountOldManModeFlg__c = true;
    	comDef.AccountIsShowCopy__c = false;
    	comDef.AccountReceiptDateDefValSetFlg__c= true;
    	comDef.AccountMediaIsShow__c = true;
    	comDef.AccountMoneyManasFlg__c = false;
    	comDef.BillInputSwitchCode__c='2';
    	comDef.AccountReceiptDateDefValSetFlg__c = true;
    	comDef.AccountReportSortKbn__c = '2';
    	update comDef;
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(4);
    	AccountMaster__c accMst = productLst[1];
		update accMst;
    	// 見積明細を作成する
    	//TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	BookingEstimateItem__c bookingItem = TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	// 予約情報のステータス：チェックインに変更する
    	bookingItem.UnitPrice__c = 20000;
    	bookingItem.ActionType__c = '前受付金';
    	//bookingItem.refBooking__c = leadInfo.Id; 
    	bookingItem.PaymentType__c = '予約金';
    	bookingItem.refAccountMaster__c = accMst.Id;
    	bookingItem.Amount__c = 4;
    	//bookingItem.UnitPriceDefKbCal__c = '1';
    	bookingItem.ParentBookingItemRef__c = null;
    	update bookingItem;
    	leadInfo.Field298__c = 'チェックイン完';
    	update leadInfo;

    	Test.stopTest();

    	// 会計画面に動作確認を行う
    	RsvAccount__c rsv = TestCommon.createRsvAccount();
    	rsv = [select Salesday__c from RsvAccount__c where id = :rsv.id];
		AccountAcount__c aa = TestCommon.createAccountAcount(rsv.Id, leadInfo.Id);
    	List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfo.Id];
    	AccountAcount__c accObj = accObjLst[0];
    	TTend__c ttitem = TestCommon.createTTend(rsv.Id, accObj.Id);
		ttitem.Field2__c = '22'; 
		ttitem.Field3__c = '予約金'; 
		ttitem.RowNo__c  = 44;  // メディア種別,メディア名称
		ttitem.Field16__c = '55';
		ttitem.Field17__c = '66';
		ttitem.Field19__c = '67';
		ttitem.Field20__c = '77';// 単価,枚数,支払金額 
		ttitem.Field21__c = '1'; //数量
		//ttitem.Field23__c = '123'; 
		ttitem.SplitGroupNo__c = '88';
		ttitem.PayProductRef__c = accMst.id;  // 支払商品
		ttitem.PayProductName__c = accMst.Name;
		ttitem.CardTypeLst__c = 'American Express';
		ttitem.CouponTypeLst__c = '楽天クーポン';
		ttitem.PaymentType__c = accMst.PaymentType__c;
		ttitem.RelAccount__c =rsv.Id;  // 主従関係(売上)
		ttitem.UseDate__c = Date.today();
		update ttitem;
		
		K_ScheduleReportPdf rp = new K_ScheduleReportPdf();
    	rp.init();
    }
    static testMethod void myUnitTest5() {
    	CommDefine__c def = TestCommon.createCommDefine();
    	def.FacilityCode__c = '33';
    	def.AccountOldManModeFlg__c = true;
    	def.AccountIsShowCopy__c = false;
    	def.AccountReceiptDateDefValSetFlg__c= true;
    	def.AccountMediaIsShow__c = true;
    	def.AccountMoneyManasFlg__c = false;
    	def.BillInputSwitchCode__c='2';
    	def.AccountReceiptDateDefValSetFlg__c = true;
    	def.AccountReportSortKbn__c = '2';
    	def.ReportKScheduleCookInfoDiv__c= true;
    	def.ReportKScheduleWhere__c = '会席,お膳,単品,仕出し,朝食:1';
    	update def;
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'ScheduleReportFieldsXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf('<root><SHOP>'
+'	<SHOPCODE></SHOPCODE>'
+'	<AGGREGATE>StayPersons__c</AGGREGATE>'
+'	<FIELDS SHOWFOOD="true" SHOWFOODSIMPLE="FALSE" SHOWGUEST="TRUE" SHOWFOODWIDTH="200px" SHOWFOODSTYLE="font-size: 16px;" >'
+'	refTypeOfRooms__r.ShopInfoRef__r.Name:支店'
+'	,Rroom__r.Seq__c:SEQ'
+'	,Rroom__r.Rnumber__c:R#'
+'	,Name:Name'
+'	,StayPersons__c:StayPersons__c'
+'	,Relcontact__r.Name:名前'
+'	,Relcontact__r.Katakana__c:カナ名'
+'	,Relcontact__r.gender__c:性別'
+'	</FIELDS>'
+'	<LINKFIELD>'
+'	Name:Id'
+'	</LINKFIELD>'
+'	<AGGREGATE>'
+'	</AGGREGATE>'
+'	<HIDDENFIELD>'
+'	refTypeOfRooms__r.ShopInfoRef__r.Name'
+'	</HIDDENFIELD>'
+'	<COLNUMSIZE>'
+'	Rroom__r.Seq__c:46px'
+'	</COLNUMSIZE>'
+'	<COLNUMSTYLE>'
+'	Name:font-size:10px;'
+'	</COLNUMSTYLE>'
+'	<COLNUMTYPE>'
+'	Rroom__r.Seq__c:number'
+'	</COLNUMTYPE>'
+'	<COLNUMEDIT>'
+'	StayPersons__c'
+'	</COLNUMEDIT>'
+'	<OPTIONS>'
+'		<POLLERTIMER>60</POLLERTIMER>'
+'		<ASSIGNONLYROOM>TRUE</ASSIGNONLYROOM>'
+'		<DAYBUTTONSHOW>TRUE</DAYBUTTONSHOW>'
+'	</OPTIONS>'
+'	<HANDWRITE>'
+'		<REAPPEAR>TRUE</REAPPEAR>'
+'		<SHAREFLG>TRUE</SHAREFLG>'
+'	</HANDWRITE>'
+'	<HISTORY>'
+'		<COLOR>'
+'			<VALUE TO="2">springgreen</VALUE>'
+'			<VALUE FROM="3" TO="4">lightblue</VALUE>'
+'			<VALUE FROM="5">papayawhip</VALUE>'
+'			<FIELDS>Name</FIELDS>'
+'		</COLOR>'
+'		<COLOR>'
+'			<VALUE TMTO="5">springgreen</VALUE>'
+'			<VALUE TMFROM="5" TMTO="60">lightblue</VALUE>'
+'			<VALUE TMFROM="60">papayawhip</VALUE>'
+'			<FIELDS>StayPersons__c</FIELDS>'
+'		</COLOR>'
+'		<COLOR>'
+'			<VALUE>lavender</VALUE>'
+'			<FIELDS>StayPersons__c</FIELDS>'
+'		</COLOR>'
+'		<FOODSUMMARYCOLOR DETAILISSHOW="TRUE">'
+'			<VALUE>springgreen</VALUE>'
+'		</FOODSUMMARYCOLOR>'
+'		<BGCOLOR>TRUE</BGCOLOR>'
+'	</HISTORY>'
+'	<NOSHOWROOM>10,20,30</NOSHOWROOM>'
+'	<SORTFIELD>Rroom__r.Rnumber__c</SORTFIELD>'
+'	<GROUPABLE>'
+'		<AUTOEXPAND>TRUE</AUTOEXPAND>'
+'		<GROUPTITLE>'
+'		StayPersons__c:1'
+'		</GROUPTITLE>'
+'	</GROUPABLE>'
+'	<GUESTYADOINFO TITLE="お客様特記事項">'
+'		Relcontact__r.Name:名前,'
+'		Relcontact__r.Katakana__c:カナ名,'
+'		Relcontact__r.gender__c:性別'
+'	</GUESTYADOINFO>'
+'	<FOODGROUPABLE>TRUE</FOODGROUPABLE>'
+'	<NIGHTSGROUPABLE>TRUE</NIGHTSGROUPABLE>'
+'	<FOODSUMMARY>'
+'		<COLNUMSIZE>'
+'			<MIDDAYICON>60</MIDDAYICON>'
+'			<PRODCUTNMAEM>240</PRODCUTNMAEM>'
+'			<PRODUCTSUMMY>60</PRODUCTSUMMY>'
+'			<UNITPRICE>100</UNITPRICE>'
+'		</COLNUMSIZE>'
+'		<COLNUMSTYLE>'
+'			<MIDDAYICON>font-size: 14px;</MIDDAYICON>'
+'			<PRODCUTNMAEM>font-size: 14px;</PRODCUTNMAEM>'
+'			<PRODUCTSUMMY>text-align: right; font-size: 14px</PRODUCTSUMMY>'
+'			<UNITPRICE>text-align: right; font-size: 14px;</UNITPRICE>'
+'		</COLNUMSTYLE>'
+'		<CONSECUTIVENIGHTS>'
+'			<BACKGROUNDCOLOR FROMNIGHT="1" TONIGHT="1">#ffcc33</BACKGROUNDCOLOR>'
+'			<BACKGROUNDCOLOR FROMNIGHT="2" TONIGHT="2">#33ff66</BACKGROUNDCOLOR>'
+'			<BACKGROUNDCOLOR FROMNIGHT="3" TONIGHT="3">yellow</BACKGROUNDCOLOR>'
+'			<BACKGROUNDCOLOR FROMNIGHT="4" >orange</BACKGROUNDCOLOR>'
+'		</CONSECUTIVENIGHTS>'
+'		<UNITPRICECOLSHOW MODE="0">TRUE</UNITPRICECOLSHOW>'
+'		<ONENIGHTSUMFLG>TRUE</ONENIGHTSUMFLG>'
+'		<SUMMARYFILTERCONFIG>TRUE</SUMMARYFILTERCONFIG>'
+'	</FOODSUMMARY>'
+'	<FOODSUMISNOSHOW>TRUE</FOODSUMISNOSHOW>'
+'	<FOODSUMISSHOWPROD>TRUE</FOODSUMISSHOWPROD>'
+'	<OPCOLISSHOW>TRUE</OPCOLISSHOW>'
+'	<TERMDATESIZE>10</TERMDATESIZE>'
+'	<EXPORTPDF><FIELDS>refTypeOfRooms__r.ShopInfoRef__r.Name:支店</FIELDS><MAXWIDTH>5000</MAXWIDTH></EXPORTPDF>'
+'</SHOP></root>');	
    	insert item;
    	//Test.startTest();
    	//Lead__c leadInfo1 = TestCommon.createLead();
    	ShopInformation__c shopInfo = new ShopInformation__c(
    		Name='東京都新宿区２号店'
    		,Fax__c = '03-1111-2222'
    		,Seq__c = Integer.valueOf(CommUtils.getRandom(8))
    		,WebSite__c = 'http://www.branch002.softpark.com'
    		,Email__c = 'east.baranch0002@softpark.com'
    		,Address__c = '東京都新宿区１番地２３手目４０６号'
    		,ShopCode__c = '02'
    		,Phone__c = '03-0222-11111'
    		,Post__c = '19100011'
    		,TierDefault__c = 'Tier1'
    		,FacilityCode__c = CommUtils.getRandom(4)
    	);
    	insert shopInfo;
        
    	List<TypeOfRooms__c> typeOfRoom = TestCommon.createTypeOfRoomByShop(shopInfo.Id,1);
    	typeOfRoom[0].MaxRooms__c = 5;
    	update typeOfRoom;
    	Contact cont = TestCommon.createContact();
    	// 予約情報を作成する
    	Lead__c item1 = new Lead__c(
    	   RecordTypeId = CommLogicProcess.getLeadBookingRecType(),
    	   name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
    	   Relcontact__c = cont.Id,                  // 顧客名
    	   ReservedStatus__c = '確認中',
    	   ReservedDate__c = System.now(),
    	   ReservedContact__c = 'Ono',
    	   EntryTime__c = Date.today(),
    	   Field4__c = '08:30',
    	   Departure__c = Date.today().addDays(1),
    	   Field3__c = '18:00',
    	   StayPersons__c = 4,
    	   Field2__c = 'FAX',
    	   refTypeOfRooms__c = typeOfRoom[0].Id
    	   );
    	insert item1;
    	item1.StayPersons__c = 3;
    	item1.EntryTime__c = Date.today().addDays(1);
    	update item1;
    	//Test.stopTest();

    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 2015/12/01 Assert BEGIN
        System.assertEquals(productLst.size(), 1);
        // 2015/12/01 Assert END
		List<OP__c> opItem = TestCommon.createOP(3);
		opItem[0].name = '朝食';
		update opItem;
		productLst[0].op__c = opItem[0].id;
		update productLst;
		Plan__c planItem = TestCommon.createPlan();
    	planItem.AccountA__c = productLst[0].Id;
    	update planItem;
    	PlanDetail__c detail = new PlanDetail__c(
        	PlanRef__c = planItem.Id,
        	AccountMasterRef__c = productLst[0].Id
        );
        insert detail;
        RsvAccount__c rsv = TestCommon.createRsvAccount();
        AccountAcount__c acc =TestCommon.createAccountAcount(rsv.Id,item1.Id);
        Tran1__c tran1 = new Tran1__c(
    		Field7__c = productLst[0].Id,
    		Field1__c = acc.Id,
    		RelAccount__c = rsv.Id
    	);
    	
    	insert tran1;     	 
    	// 見積明細を作成する
    	BookingEstimateItem__c items = TestCommon.createBookEstItem(item1, productLst[0]);
    	items.OP__c = opItem[0].Id;
    	items.ActionType__c= '朝食';
    	update items;
    	
    	// 見積明細を作成する
    	BookingEstimateItem__c items1 = TestCommon.createBookEstItem(item1, productLst[0]);
    	
		Apexpages.currentPage().getParameters().put('sp', '02');
		Apexpages.currentPage().getParameters().put('dt', System.now().format('yyyy/MM/dd'));
		Apexpages.currentPage().getParameters().put('pdf', '1');
		Apexpages.currentPage().getParameters().put('term', '5');
		Apexpages.currentPage().getParameters().put('gpflg', '1');
		
    	update item1;
		
		K_ScheduleReportPdfBatch batch = new K_ScheduleReportPdfBatch(System.now());
		DataBase.executeBatch(batch,1);
		
		K_ScheduleReportPdfBatch batch1 = new K_ScheduleReportPdfBatch(System.now().addDays(1));
		DataBase.executeBatch(batch1,1);
		
		K_ScheduleReportPdf rp = new K_ScheduleReportPdf();
    	rp.init();
    	item1.Field298__c = 'チェックイン完';
    	rp.init();
    }
    static testMethod void myUnitTest6() {
    	CommDefine__c def = TestCommon.createCommDefine();
    	def.FacilityCode__c = '33';
    	def.AccountOldManModeFlg__c = true;
    	def.AccountIsShowCopy__c = false;
    	def.AccountReceiptDateDefValSetFlg__c= true;
    	def.AccountMediaIsShow__c = true;
    	def.AccountMoneyManasFlg__c = false;
    	def.BillInputSwitchCode__c='2';
    	def.AccountReceiptDateDefValSetFlg__c = true;
    	def.AccountReportSortKbn__c = '2';
    	def.ReportKScheduleCookInfoDiv__c= true;
    	def.ReportKScheduleWhere__c = '会席,お膳,単品,仕出し,朝食:1';
    	update def;
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'ScheduleReportFieldsXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf('<root><SHOP>'
+'	<SHOPCODE></SHOPCODE>'
+'	<AGGREGATE>StayPersons__c</AGGREGATE>'
+'	<FIELDS SHOWFOOD="FALSE" SHOWFOODSIMPLE="FALSE" SHOWGUEST="FALSE" SHOWFOODWIDTH="200px" SHOWFOODSTYLE="font-size: 16px;" >'
+'	refTypeOfRooms__r.ShopInfoRef__r.Name:支店'
+'	,Rroom__r.Seq__c:SEQ'
+'	,Rroom__r.Rnumber__c:R#'
+'	,Name:Name'
+'	,StayPersons__c:StayPersons__c'
+'	,Relcontact__r.Name:名前'
+'	,Relcontact__r.Katakana__c:カナ名'
+'	,Relcontact__r.gender__c:性別'
+'	</FIELDS>'
+'	<LINKFIELD>'
+'	Name:Id'
+'	</LINKFIELD>'
+'	<AGGREGATE>'
+'	</AGGREGATE>'
+'	<HIDDENFIELD>'
+'	refTypeOfRooms__r.ShopInfoRef__r.Name'
+'	</HIDDENFIELD>'
+'	<COLNUMSIZE>'
+'	Rroom__r.Seq__c:46px'
+'	</COLNUMSIZE>'
+'	<COLNUMSTYLE>'
+'	Name:font-size:10px;'
+'	</COLNUMSTYLE>'
+'	<COLNUMTYPE>'
+'	Rroom__r.Seq__c:number'
+'	</COLNUMTYPE>'
+'	<COLNUMEDIT>'
+'	StayPersons__c'
+'	</COLNUMEDIT>'
+'	<OPTIONS>'
+'		<POLLERTIMER>60</POLLERTIMER>'
+'		<ASSIGNONLYROOM>FALSE</ASSIGNONLYROOM>'
+'		<DAYBUTTONSHOW>FALSE</DAYBUTTONSHOW>'
+'	</OPTIONS>'
+'	<HANDWRITE>'
+'		<REAPPEAR>FALSE</REAPPEAR>'
+'		<SHAREFLG>FALSE</SHAREFLG>'
+'	</HANDWRITE>'
+'	<HISTORY>'
+'		<COLOR>'
+'			<VALUE TO="2">springgreen</VALUE>'
+'			<VALUE FROM="3" TO="4">lightblue</VALUE>'
+'			<VALUE FROM="5">papayawhip</VALUE>'
+'			<FIELDS>Name</FIELDS>'
+'		</COLOR>'
+'		<COLOR>'
+'			<VALUE TMTO="5">springgreen</VALUE>'
+'			<VALUE TMFROM="5" TMTO="60">lightblue</VALUE>'
+'			<VALUE TMFROM="60">papayawhip</VALUE>'
+'			<FIELDS>StayPersons__c</FIELDS>'
+'		</COLOR>'
+'		<COLOR>'
+'			<VALUE>lavender</VALUE>'
+'			<FIELDS>StayPersons__c</FIELDS>'
+'		</COLOR>'
+'		<FOODSUMMARYCOLOR DETAILISSHOW="FALSE">'
+'			<VALUE>springgreen</VALUE>'
+'		</FOODSUMMARYCOLOR>'
+'		<BGCOLOR>FALSE</BGCOLOR>'
+'	</HISTORY>'
+'	<NOSHOWROOM>10,20,30</NOSHOWROOM>'
+'	<SORTFIELD>Rroom__r.Rnumber__c</SORTFIELD>'
+'	<GROUPABLE>'
+'		<AUTOEXPAND>FALSE</AUTOEXPAND>'
+'		<GROUPTITLE>'
+'		StayPersons__c:1'
+'		</GROUPTITLE>'
+'	</GROUPABLE>'
+'	<GUESTYADOINFO TITLE="お客様特記事項">'
+'		Relcontact__r.Name:名前,'
+'		Relcontact__r.Katakana__c:カナ名,'
+'		Relcontact__r.gender__c:性別'
+'	</GUESTYADOINFO>'
+'	<FOODGROUPABLE>FALSE</FOODGROUPABLE>'
+'	<NIGHTSGROUPABLE>FALSE</NIGHTSGROUPABLE>'
+'	<FOODSUMMARY>'
+'		<COLNUMSIZE>'
+'			<MIDDAYICON>60</MIDDAYICON>'
+'			<PRODCUTNMAEM>240</PRODCUTNMAEM>'
+'			<PRODUCTSUMMY>60</PRODUCTSUMMY>'
+'			<UNITPRICE>100</UNITPRICE>'
+'		</COLNUMSIZE>'
+'		<COLNUMSTYLE>'
+'			<MIDDAYICON>font-size: 14px;</MIDDAYICON>'
+'			<PRODCUTNMAEM>font-size: 14px;</PRODCUTNMAEM>'
+'			<PRODUCTSUMMY>text-align: right; font-size: 14px</PRODUCTSUMMY>'
+'			<UNITPRICE>text-align: right; font-size: 14px;</UNITPRICE>'
+'		</COLNUMSTYLE>'
+'		<CONSECUTIVENIGHTS>'
+'			<BACKGROUNDCOLOR FROMNIGHT="1" TONIGHT="1">#ffcc33</BACKGROUNDCOLOR>'
+'			<BACKGROUNDCOLOR FROMNIGHT="2" TONIGHT="2">#33ff66</BACKGROUNDCOLOR>'
+'			<BACKGROUNDCOLOR FROMNIGHT="3" TONIGHT="3">yellow</BACKGROUNDCOLOR>'
+'			<BACKGROUNDCOLOR FROMNIGHT="4" >orange</BACKGROUNDCOLOR>'
+'		</CONSECUTIVENIGHTS>'
+'		<UNITPRICECOLSHOW MODE="0">FALSE</UNITPRICECOLSHOW>'
+'		<ONENIGHTSUMFLG>FALSE</ONENIGHTSUMFLG>'
+'		<SUMMARYFILTERCONFIG>FALSE</SUMMARYFILTERCONFIG>'
+'	</FOODSUMMARY>'
+'	<FOODSUMISNOSHOW>FALSE</FOODSUMISNOSHOW>'
+'	<FOODSUMISSHOWPROD>FALSE</FOODSUMISSHOWPROD>'
+'	<OPCOLISSHOW>FALSE</OPCOLISSHOW>'
+'	<TERMDATESIZE>10</TERMDATESIZE>'
+'	<EXPORTPDF><FIELDS>refTypeOfRooms__r.ShopInfoRef__r.Name:支店</FIELDS><MAXWIDTH>5000</MAXWIDTH></EXPORTPDF>'
+'</SHOP></root>');	
    	insert item;
    	//Test.startTest();
    	//Lead__c leadInfo1 = TestCommon.createLead();
    	ShopInformation__c shopInfo = new ShopInformation__c(
    		Name='東京都新宿区２号店'
    		,Fax__c = '03-1111-2222'
    		,Seq__c = Integer.valueOf(CommUtils.getRandom(8))
    		,WebSite__c = 'http://www.branch002.softpark.com'
    		,Email__c = 'east.baranch0002@softpark.com'
    		,Address__c = '東京都新宿区１番地２３手目４０６号'
    		,ShopCode__c = '02'
    		,Phone__c = '03-0222-11111'
    		,Post__c = '19100011'
    		,TierDefault__c = 'Tier1'
    		,FacilityCode__c = CommUtils.getRandom(4)
    	);
    	insert shopInfo;
        
    	List<TypeOfRooms__c> typeOfRoom = TestCommon.createTypeOfRoomByShop(shopInfo.Id,1);
    	typeOfRoom[0].MaxRooms__c = 5;
    	update typeOfRoom;
    	Contact cont = TestCommon.createContact();
    	// 予約情報を作成する
    	Lead__c item1 = new Lead__c(
    	   RecordTypeId = CommLogicProcess.getLeadBookingRecType(),
    	   name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
    	   Relcontact__c = cont.Id,                  // 顧客名
    	   ReservedStatus__c = '確認中',
    	   ReservedDate__c = System.now(),
    	   ReservedContact__c = 'Ono',
    	   EntryTime__c = Date.today(),
    	   Field4__c = '08:30',
    	   Departure__c = Date.today().addDays(1),
    	   Field3__c = '18:00',
    	   StayPersons__c = 4,
    	   Field2__c = 'FAX',
    	   refTypeOfRooms__c = typeOfRoom[0].Id
    	   );
    	insert item1;
    	item1.StayPersons__c = 3;
    	item1.EntryTime__c = Date.today().addDays(1);
    	update item1;
    	//Test.stopTest();

    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 2015/12/01 Assert BEGIN
        System.assertEquals(productLst.size(), 1);
        // 2015/12/01 Assert END
		List<OP__c> opItem = TestCommon.createOP(3);
		opItem[0].name = '朝食';
		update opItem;
		productLst[0].op__c = opItem[0].id;
		update productLst;
		Plan__c planItem = TestCommon.createPlan();
    	planItem.AccountA__c = productLst[0].Id;
    	update planItem;
    	PlanDetail__c detail = new PlanDetail__c(
        	PlanRef__c = planItem.Id,
        	AccountMasterRef__c = productLst[0].Id
        );
        insert detail;
        RsvAccount__c rsv = TestCommon.createRsvAccount();
        AccountAcount__c acc =TestCommon.createAccountAcount(rsv.Id,item1.Id);
        Tran1__c tran1 = new Tran1__c(
    		Field7__c = productLst[0].Id,
    		Field1__c = acc.Id,
    		RelAccount__c = rsv.Id
    	);
    	
    	insert tran1;     	 
    	// 見積明細を作成する
    	BookingEstimateItem__c items = TestCommon.createBookEstItem(item1, productLst[0]);
    	items.OP__c = opItem[0].Id;
    	// items.ActionType__c= '朝食';
    	update items;
    	
    	// 見積明細を作成する
    	BookingEstimateItem__c items1 = TestCommon.createBookEstItem(item1, productLst[0]);
    	
		Apexpages.currentPage().getParameters().put('sp', '02');
		Apexpages.currentPage().getParameters().put('dt', System.now().format('yyyy/MM/dd'));
		Apexpages.currentPage().getParameters().put('pdf', '1');
		Apexpages.currentPage().getParameters().put('term', '5');
		Apexpages.currentPage().getParameters().put('gpflg', '1');
		
		K_ScheduleReportPdfBatch batch = new K_ScheduleReportPdfBatch(System.now());
		DataBase.executeBatch(batch,1);
		
		K_ScheduleReportPdfBatch batch1 = new K_ScheduleReportPdfBatch(System.now().addDays(1));
		DataBase.executeBatch(batch1,1);
		
		K_ScheduleReportPdf rp = new K_ScheduleReportPdf();
    	rp.init();
    	item1.Field298__c = 'チェックイン完';
    	update item1;
    	rp.init();
    }
    static testMethod void myUnitTest7() {
    	CommDefine__c def = TestCommon.createCommDefine();
    	def.FacilityCode__c = '33';
    	def.AccountOldManModeFlg__c = true;
    	def.AccountIsShowCopy__c = false;
    	def.AccountReceiptDateDefValSetFlg__c= true;
    	def.AccountMediaIsShow__c = true;
    	def.AccountMoneyManasFlg__c = false;
    	def.BillInputSwitchCode__c='2';
    	def.AccountReceiptDateDefValSetFlg__c = true;
    	def.AccountReportSortKbn__c = '2';
    	def.ReportKScheduleCookInfoDiv__c= true;
    	def.ReportKScheduleWhere__c = '朝食';
    	update def;
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'ScheduleReportFieldsXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf('<root><SHOP>'
+'	<SHOPCODE></SHOPCODE>'
+'	<AGGREGATE>StayPersons__c</AGGREGATE>'
+'	<FIELDS SHOWFOOD="true" SHOWFOODSIMPLE="FALSE" SHOWGUEST="TRUE" SHOWFOODWIDTH="200px" SHOWFOODSTYLE="font-size: 16px;" >'
+'	refTypeOfRooms__r.ShopInfoRef__r.Name:支店'
+'	,Rroom__r.Seq__c:SEQ'
+'	,Rroom__r.Rnumber__c:R#'
+'	,Name:Name'
+'	,StayPersons__c:StayPersons__c'
+'	,Relcontact__r.Name:名前'
+'	,Relcontact__r.Katakana__c:カナ名'
+'	,Relcontact__r.gender__c:性別'
+'	</FIELDS>'
+'	<LINKFIELD>'
+'	Name:Id'
+'	</LINKFIELD>'
+'	<AGGREGATE>'
+'	</AGGREGATE>'
+'	<HIDDENFIELD>'
+'	refTypeOfRooms__r.ShopInfoRef__r.Name'
+'	</HIDDENFIELD>'
+'	<COLNUMSIZE>'
+'	Rroom__r.Seq__c:46px'
+'	</COLNUMSIZE>'
+'	<COLNUMSTYLE>'
+'	Name:font-size:10px;'
+'	</COLNUMSTYLE>'
+'	<COLNUMTYPE>'
+'	Rroom__r.Seq__c:number'
+'	</COLNUMTYPE>'
+'	<COLNUMEDIT>'
+'	StayPersons__c'
+'	</COLNUMEDIT>'
+'	<OPTIONS>'
+'		<POLLERTIMER>60</POLLERTIMER>'
+'		<ASSIGNONLYROOM>TRUE</ASSIGNONLYROOM>'
+'		<DAYBUTTONSHOW>TRUE</DAYBUTTONSHOW>'
+'	</OPTIONS>'
+'	<HANDWRITE>'
+'		<REAPPEAR>TRUE</REAPPEAR>'
+'		<SHAREFLG>TRUE</SHAREFLG>'
+'	</HANDWRITE>'
+'	<HISTORY>'
+'		<COLOR>'
+'			<VALUE TO="2">springgreen</VALUE>'
+'			<VALUE FROM="3" TO="4">lightblue</VALUE>'
+'			<VALUE FROM="5">papayawhip</VALUE>'
+'			<FIELDS>Name</FIELDS>'
+'		</COLOR>'
+'		<COLOR>'
+'			<VALUE TMTO="5">springgreen</VALUE>'
+'			<VALUE TMFROM="5" TMTO="60">lightblue</VALUE>'
+'			<VALUE TMFROM="60">papayawhip</VALUE>'
+'			<FIELDS>StayPersons__c</FIELDS>'
+'		</COLOR>'
+'		<COLOR>'
+'			<VALUE>lavender</VALUE>'
+'			<FIELDS>StayPersons__c</FIELDS>'
+'		</COLOR>'
+'		<FOODSUMMARYCOLOR DETAILISSHOW="TRUE">'
+'			<VALUE>springgreen</VALUE>'
+'		</FOODSUMMARYCOLOR>'
+'		<BGCOLOR>TRUE</BGCOLOR>'
+'	</HISTORY>'
+'	<NOSHOWROOM>10,20,30</NOSHOWROOM>'
+'	<SORTFIELD>Rroom__r.Rnumber__c</SORTFIELD>'
+'	<GROUPABLE>'
+'		<AUTOEXPAND>TRUE</AUTOEXPAND>'
+'		<GROUPTITLE>'
+'		StayPersons__c:1'
+'		</GROUPTITLE>'
+'	</GROUPABLE>'
+'	<GUESTYADOINFO TITLE="お客様特記事項">'
+'		Relcontact__r.Name:名前,'
+'		Relcontact__r.Katakana__c:カナ名,'
+'		Relcontact__r.gender__c:性別'
+'	</GUESTYADOINFO>'
+'	<FOODGROUPABLE>TRUE</FOODGROUPABLE>'
+'	<NIGHTSGROUPABLE>TRUE</NIGHTSGROUPABLE>'
+'	<FOODSUMMARY>'
+'		<COLNUMSIZE>'
+'			<MIDDAYICON>60</MIDDAYICON>'
+'			<PRODCUTNMAEM>240</PRODCUTNMAEM>'
+'			<PRODUCTSUMMY>60</PRODUCTSUMMY>'
+'			<UNITPRICE>100</UNITPRICE>'
+'		</COLNUMSIZE>'
+'		<COLNUMSTYLE>'
+'			<MIDDAYICON>font-size: 14px;</MIDDAYICON>'
+'			<PRODCUTNMAEM>font-size: 14px;</PRODCUTNMAEM>'
+'			<PRODUCTSUMMY>text-align: right; font-size: 14px</PRODUCTSUMMY>'
+'			<UNITPRICE>text-align: right; font-size: 14px;</UNITPRICE>'
+'		</COLNUMSTYLE>'
+'		<CONSECUTIVENIGHTS>'
+'			<BACKGROUNDCOLOR FROMNIGHT="1" TONIGHT="1">#ffcc33</BACKGROUNDCOLOR>'
+'			<BACKGROUNDCOLOR FROMNIGHT="2" TONIGHT="2">#33ff66</BACKGROUNDCOLOR>'
+'			<BACKGROUNDCOLOR FROMNIGHT="3" TONIGHT="3">yellow</BACKGROUNDCOLOR>'
+'			<BACKGROUNDCOLOR FROMNIGHT="4" >orange</BACKGROUNDCOLOR>'
+'		</CONSECUTIVENIGHTS>'
+'		<UNITPRICECOLSHOW MODE="0">TRUE</UNITPRICECOLSHOW>'
+'		<ONENIGHTSUMFLG>TRUE</ONENIGHTSUMFLG>'
+'		<SUMMARYFILTERCONFIG>TRUE</SUMMARYFILTERCONFIG>'
+'	</FOODSUMMARY>'
+'	<FOODSUMISNOSHOW>TRUE</FOODSUMISNOSHOW>'
+'	<FOODSUMISSHOWPROD>TRUE</FOODSUMISSHOWPROD>'
+'	<OPCOLISSHOW>TRUE</OPCOLISSHOW>'
+'	<TERMDATESIZE>10</TERMDATESIZE>'
+'	<EXPORTPDF><FIELDS>refTypeOfRooms__r.ShopInfoRef__r.Name:支店</FIELDS><MAXWIDTH>5000</MAXWIDTH></EXPORTPDF>'
+'</SHOP></root>');	
    	insert item;
    	//Test.startTest();
    	//Lead__c leadInfo1 = TestCommon.createLead();
    	ShopInformation__c shopInfo = new ShopInformation__c(
    		Name='東京都新宿区２号店'
    		,Fax__c = '03-1111-2222'
    		,Seq__c = Integer.valueOf(CommUtils.getRandom(8))
    		,WebSite__c = 'http://www.branch002.softpark.com'
    		,Email__c = 'east.baranch0002@softpark.com'
    		,Address__c = '東京都新宿区１番地２３手目４０６号'
    		,ShopCode__c = '02'
    		,Phone__c = '03-0222-11111'
    		,Post__c = '19100011'
    		,TierDefault__c = 'Tier1'
    		,FacilityCode__c = CommUtils.getRandom(4)
    	);
    	insert shopInfo;
        
    	List<TypeOfRooms__c> typeOfRoom = TestCommon.createTypeOfRoomByShop(shopInfo.Id,1);
    	typeOfRoom[0].MaxRooms__c = 5;
    	update typeOfRoom;
    	Contact cont = TestCommon.createContact();
    	// 予約情報を作成する
    	Lead__c item1 = new Lead__c(
    	   RecordTypeId = CommLogicProcess.getLeadBookingRecType(),
    	   name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
    	   Relcontact__c = cont.Id,                  // 顧客名
    	   ReservedStatus__c = '確認中',
    	   ReservedDate__c = System.now(),
    	   ReservedContact__c = 'Ono',
    	   EntryTime__c = Date.today(),
    	   Field4__c = '08:30',
    	   Departure__c = Date.today().addDays(1),
    	   Field3__c = '18:00',
    	   StayPersons__c = 4,
    	   Field2__c = 'FAX',
    	   refTypeOfRooms__c = typeOfRoom[0].Id
    	   );
    	insert item1;
    	item1.StayPersons__c = 3;
    	item1.EntryTime__c = Date.today().addDays(1);
    	update item1;
    	//Test.stopTest();

    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 2015/12/01 Assert BEGIN
        System.assertEquals(productLst.size(), 1);
        // 2015/12/01 Assert END
		List<OP__c> opItem = TestCommon.createOP(3);
		opItem[0].name = '朝食';
		update opItem;
		productLst[0].op__c = opItem[0].id;
		update productLst;
		Plan__c planItem = TestCommon.createPlan();
    	planItem.AccountA__c = productLst[0].Id;
    	update planItem;
    	PlanDetail__c detail = new PlanDetail__c(
        	PlanRef__c = planItem.Id,
        	AccountMasterRef__c = productLst[0].Id
        );
        insert detail;
        RsvAccount__c rsv = TestCommon.createRsvAccount();
        AccountAcount__c acc =TestCommon.createAccountAcount(rsv.Id,item1.Id);
        Tran1__c tran1 = new Tran1__c(
    		Field7__c = productLst[0].Id,
    		Field1__c = acc.Id,
    		RelAccount__c = rsv.Id
    	);
    	
    	insert tran1;     	 
    	// 見積明細を作成する
    	BookingEstimateItem__c items = TestCommon.createBookEstItem(item1, productLst[0]);
    	items.OP__c = opItem[0].Id;
    	// items.ActionType__c= '朝食';
    	update items;
    	
    	// 見積明細を作成する
    	BookingEstimateItem__c items1 = TestCommon.createBookEstItem(item1, productLst[0]);
    	
    	item1.Field298__c = 'チェックイン完';
    	update item1;
		Apexpages.currentPage().getParameters().put('sp', '02');
		Apexpages.currentPage().getParameters().put('dt', System.now().format('yyyy/MM/dd'));
		Apexpages.currentPage().getParameters().put('pdf', '1');
		Apexpages.currentPage().getParameters().put('term', '5');
		Apexpages.currentPage().getParameters().put('gpflg', '1');
		
		K_ScheduleReportPdfBatch batch = new K_ScheduleReportPdfBatch(System.now());
		DataBase.executeBatch(batch,1);
		
		K_ScheduleReportPdfBatch batch1 = new K_ScheduleReportPdfBatch(System.now().addDays(1));
		DataBase.executeBatch(batch1,1);
		
		K_ScheduleReportPdf rp = new K_ScheduleReportPdf();
    	rp.init();
    }
    static testMethod void myUnitTest8() {
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'ScheduleReportFieldsXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf('<root><SHOP>'+
								'<SHOPCODE></SHOPCODE>'+
								'<FIELDS >refTypeOfRooms__r.ShopInfoRef__r.Name:支店,Rroom__r.Seq__c:SEQ,Relcontact__r.ApplicantName__c:申込者,Rroom__r.Name:部屋,Relcontact__r.Name:お客様名,LeadIndexRef__r.Name:予約名</FIELDS>'+
								'<AGGREGATE>StayPersons__c</AGGREGATE>'+
								'<EXPORTPDF><FIELDS>refTypeOfRooms__r.ShopInfoRef__r.Name:支店</FIELDS><MAXWIDTH>5000</MAXWIDTH></EXPORTPDF>'+
								'</SHOP></root>');	
    	insert item;
    	Test.startTest();
    	// 店舗情報を初期化する
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	// 施設コード     
    	comDef.FacilityCode__c = '33';
    	comDef.AccountOldManModeFlg__c = true;
    	comDef.AccountIsShowCopy__c = false;
    	comDef.AccountReceiptDateDefValSetFlg__c= true;
    	comDef.AccountMediaIsShow__c = true;
    	comDef.AccountMoneyManasFlg__c = false;
    	comDef.BillInputSwitchCode__c='2';
    	comDef.AccountReceiptDateDefValSetFlg__c = true;
    	comDef.AccountReportSortKbn__c = '2';
    	comDef.ReportKScheduleWhere__c = '会席,お膳,単品,仕出し,朝食:1';
    	update comDef;
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(4);
    	AccountMaster__c accMst = productLst[1];
		update accMst;
    	// 見積明細を作成する
    	//TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	BookingEstimateItem__c bookingItem = TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	// 予約情報のステータス：チェックインに変更する
    	bookingItem.UnitPrice__c = 20000;
    	bookingItem.ActionType__c = '前受付金';
    	//bookingItem.refBooking__c = leadInfo.Id; 
    	bookingItem.PaymentType__c = '予約金';
    	bookingItem.refAccountMaster__c = accMst.Id;
    	bookingItem.Amount__c = 4;
    	//bookingItem.UnitPriceDefKbCal__c = '1';
    	bookingItem.ParentBookingItemRef__c = null;
    	update bookingItem;
    	
    	List<OP__c> opItem = TestCommon.createOP(3);
		opItem[0].name = '朝食';
		update opItem;
		accMst.op__c = opItem[0].id;
		update accMst;
		BookingEstimateItem__c bookingItem1 = TestCommon.createBookEstItem(leadInfo, accMst);
    	bookingItem1.op__c = opItem[0].Id;
    	update bookingItem1;
    	
    	leadInfo.Field298__c = 'チェックイン完';
    	update leadInfo;

    	Test.stopTest();

    	// 会計画面に動作確認を行う
    	RsvAccount__c rsv = TestCommon.createRsvAccount();
    	rsv = [select Salesday__c from RsvAccount__c where id = :rsv.id];
		AccountAcount__c aa = TestCommon.createAccountAcount(rsv.Id, leadInfo.Id);
    	List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfo.Id];
    	AccountAcount__c accObj = accObjLst[0];
    	TTend__c ttitem = TestCommon.createTTend(rsv.Id, accObj.Id);
		ttitem.Field2__c = '22'; 
		ttitem.Field3__c = '予約金'; 
		ttitem.RowNo__c  = 44;  // メディア種別,メディア名称
		ttitem.Field16__c = '55';
		ttitem.Field17__c = '66';
		ttitem.Field19__c = '67';
		ttitem.Field20__c = '77';// 単価,枚数,支払金額 
		ttitem.Field21__c = '1'; //数量
		//ttitem.Field23__c = '123'; 
		ttitem.SplitGroupNo__c = '88';
		ttitem.PayProductRef__c = accMst.id;  // 支払商品
		ttitem.PayProductName__c = accMst.Name;
		ttitem.CardTypeLst__c = 'American Express';
		ttitem.CouponTypeLst__c = '楽天クーポン';
		ttitem.PaymentType__c = accMst.PaymentType__c;
		ttitem.RelAccount__c =rsv.Id;  // 主従関係(売上)
		ttitem.UseDate__c = Date.today();
		update ttitem;
		
		K_ScheduleReportPdf rp = new K_ScheduleReportPdf();
    	rp.init();
    }
	static testMethod void myUnitTestBatch() {
	    // ドキュメントを作成する
		Document item = new Document();
		item.Name = 'ScheduleReportFieldsXml';
		item.DeveloperName = item.Name;
		item.FolderId = UserInfo.getUserId();
		item.Body = Blob.valueOf('<root>'+
								'<SHOP>'+
								'<SHOPCODE></SHOPCODE>'+
								'<FIELDS >refTypeOfRooms__r.ShopInfoRef__r.Name:支店,Rroom__r.Seq__c:SEQ,Relcontact__r.ApplicantName__c:申込者,Rroom__r.Name:部屋,Relcontact__r.Name:お客様名,LeadIndexRef__r.Name:予約名</FIELDS>'+
								'<COLNUMTYPE>Rroom__r.Seq__c:number,Rroom__r.Rnumber__c:number,StayPersons__c:number,Mans__c:number,Femails__c:number,EntryTime__c:date,LeadReceiptDate__c:date</COLNUMTYPE>'+
								'<AGGREGATE>StayPersons__c</AGGREGATE>'+
								'<EXPORTPDF><FIELDS>refTypeOfRooms__r.ShopInfoRef__r.Name:支店</FIELDS><MAXWIDTH>5000</MAXWIDTH></EXPORTPDF>'+
								'</SHOP>'+
								'<PDFOUTPUT><POLLERTIMER>60</POLLERTIMER></PDFOUTPUT>'+
								'</root>');
							
		insert item;
	    Test.startTest();
	    
	    List<CollaborationGroup> groups = TestCommon.createGroups(1);
    	CommDefine__c comDef = TestCommon.createCommDefine();
        comDef.ChatterGroupName__c = '7:'+groups[0].name + ';7,7:';
        update comDef;
	    
		List<String> chatterGroupNamesLst = CommConst.GetChatterGroupNameByCode(CommConst.KSCH_ChatterGroupNameType);
		List<CollaborationGroup> chatterGroups = [select Id, Name from CollaborationGroup where name = :chatterGroupNamesLst and isarchived = false];
		// バッチ処理を開始する
		list<string> chatterGroupIdLst = new list<string>();
		for (CollaborationGroup col : chatterGroups) {
			chatterGroupIdLst.add(col.id);
		}
		DateTime now = System.now();
		K_ScheduleReportPdfBatch batch = new K_ScheduleReportPdfBatch(now);
		DataBase.executeBatch(batch,1);
	    Test.stopTest();
	}
	static testMethod void myUnitTestBatch1() {
	    // ドキュメントを作成する
		Document item = new Document();
		item.Name = 'ScheduleReportFieldsXml';
		item.DeveloperName = item.Name;
		item.FolderId = UserInfo.getUserId();
		item.Body = Blob.valueOf('<root>'+
								'<SHOP>'+
								'<SHOPCODE></SHOPCODE>'+
								'<FIELDS >refTypeOfRooms__r.ShopInfoRef__r.Name:支店,Rroom__r.Seq__c:SEQ,Relcontact__r.ApplicantName__c:申込者,Rroom__r.Name:部屋,Relcontact__r.Name:お客様名,LeadIndexRef__r.Name:予約名</FIELDS>'+
								'<COLNUMTYPE>Rroom__r.Seq__c:number,Rroom__r.Rnumber__c:number,StayPersons__c:number,Mans__c:number,Femails__c:number,EntryTime__c:date,LeadReceiptDate__c:date</COLNUMTYPE>'+
								'<AGGREGATE>StayPersons__c</AGGREGATE>'+
								'<EXPORTPDF><FIELDS>refTypeOfRooms__r.ShopInfoRef__r.Name:支店</FIELDS><MAXWIDTH>5000</MAXWIDTH></EXPORTPDF>'+
								'</SHOP>'+
								'<PDFOUTPUT><POLLERTIMER>60</POLLERTIMER></PDFOUTPUT>'+
								'</root>');
							
		insert item;
	    Test.startTest();
	    
	    List<CollaborationGroup> groups = TestCommon.createGroups(1);
    	CommDefine__c comDef = TestCommon.createCommDefine();
        comDef.ChatterGroupName__c = '';
        update comDef;
	    
		List<String> chatterGroupNamesLst = CommConst.GetChatterGroupNameByCode(CommConst.KSCH_ChatterGroupNameType);
		List<CollaborationGroup> chatterGroups = [select Id, Name from CollaborationGroup where name = :chatterGroupNamesLst and isarchived = false];
		// バッチ処理を開始する
		list<string> chatterGroupIdLst = new list<string>();
		for (CollaborationGroup col : chatterGroups) {
			chatterGroupIdLst.add(col.id);
		}
		DateTime now = System.now();
		K_ScheduleReportPdfBatch batch = new K_ScheduleReportPdfBatch(now);
		DataBase.executeBatch(batch,1);
	    Test.stopTest();
	}
	static testMethod void myUnitTestBatch2() {
	    // ドキュメントを作成する
		Document item = new Document();
		item.Name = 'ScheduleReportFieldsXml';
		item.DeveloperName = item.Name;
		item.FolderId = UserInfo.getUserId();
		item.Body = Blob.valueOf('<root>'+
								'<SHOP>'+
								'<SHOPCODE></SHOPCODE>'+
								'<FIELDS >refTypeOfRooms__r.ShopInfoRef__r.Name:支店,Rroom__r.Seq__c:SEQ,Relcontact__r.ApplicantName__c:申込者,Rroom__r.Name:部屋,Relcontact__r.Name:お客様名,LeadIndexRef__r.Name:予約名</FIELDS>'+
								'<COLNUMTYPE>Rroom__r.Seq__c:number,Rroom__r.Rnumber__c:number,StayPersons__c:number,Mans__c:number,Femails__c:number,EntryTime__c:date,LeadReceiptDate__c:date</COLNUMTYPE>'+
								'<AGGREGATE>StayPersons__c</AGGREGATE>'+
								'<EXPORTPDF><FIELDS>refTypeOfRooms__r.ShopInfoRef__r.Name:支店</FIELDS><MAXWIDTH>5000</MAXWIDTH></EXPORTPDF>'+
								'</SHOP>'+
								'<PDFOUTPUT><POLLERTIMER>60</POLLERTIMER></PDFOUTPUT>'+
								'</root>');
							
		insert item;
	    Test.startTest();
	    
	    List<CollaborationGroup> groups = TestCommon.createGroups(1);
    	CommDefine__c comDef = TestCommon.createCommDefine();
        comDef.ChatterGroupName__c = '7:'+groups[0].name + ';7,7:';
        update comDef;
	    
		List<String> chatterGroupNamesLst = CommConst.GetChatterGroupNameByCode(CommConst.KSCH_ChatterGroupNameType);
		list<CollaborationGroup> chatterGroups = new list<CollaborationGroup>();
		// バッチ処理を開始する
		list<string> chatterGroupIdLst = new list<string>();
		for (CollaborationGroup col : chatterGroups) {
			chatterGroupIdLst.add(col.id);
		}
		DateTime now = System.now();
		K_ScheduleReportPdfBatch batch = new K_ScheduleReportPdfBatch(now);
		DataBase.executeBatch(batch,1);
	    Test.stopTest();
	}
	static testMethod void myUnitTest10() {
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'ScheduleReportFieldsXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf('<root><SHOP>'+
								'<SHOPCODE></SHOPCODE>'+
								'<FIELDS SHOWFOOD="true" SHOWGUEST="true" SHOWGUESTPOS="2" >refTypeOfRooms__r.ShopInfoRef__r.Name:支店,Rroom__r.Seq__c:SEQ,Relcontact__r.ApplicantName__c:申込者,Rroom__r.Name:部屋,Relcontact__r.Name:お客様名,LeadIndexRef__r.Name:予約名</FIELDS>'+
								'<AGGREGATE>StayPersons__c</AGGREGATE>'+
								'<EXPORTPDF><FIELDS>refTypeOfRooms__r.ShopInfoRef__r.Name:支店</FIELDS><MAXWIDTH>5000</MAXWIDTH></EXPORTPDF>'+
								'</SHOP></root>');	
    	insert item;
    	Test.startTest();
    	// 店舗情報を初期化する
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	// 施設コード     
    	comDef.FacilityCode__c = '33';
    	comDef.AccountOldManModeFlg__c = true;
    	comDef.AccountIsShowCopy__c = false;
    	comDef.AccountReceiptDateDefValSetFlg__c= true;
    	comDef.AccountMediaIsShow__c = true;
    	comDef.AccountMoneyManasFlg__c = false;
    	comDef.BillInputSwitchCode__c='2';
    	comDef.AccountReceiptDateDefValSetFlg__c = true;
    	comDef.AccountReportSortKbn__c = '2';
    	comDef.ReportKScheduleWhere__c = '会席,お膳,単品,仕出し,朝食:1';
    	update comDef;
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(4);
    	AccountMaster__c accMst = productLst[1];
		update accMst;
    	// 見積明細を作成する
    	//TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	BookingEstimateItem__c bookingItem = TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	// 予約情報のステータス：チェックインに変更する
    	bookingItem.UnitPrice__c = 20000;
    	bookingItem.ActionType__c = '前受付金';
    	//bookingItem.refBooking__c = leadInfo.Id; 
    	bookingItem.PaymentType__c = '予約金';
    	bookingItem.refAccountMaster__c = accMst.Id;
    	bookingItem.Amount__c = 4;
    	//bookingItem.UnitPriceDefKbCal__c = '1';
    	bookingItem.ParentBookingItemRef__c = null;
    	update bookingItem;
    	
    	List<OP__c> opItem = TestCommon.createOP(3);
		opItem[0].name = '朝食';
		update opItem;
		accMst.op__c = opItem[0].id;
		update accMst;
		BookingEstimateItem__c bookingItem1 = TestCommon.createBookEstItem(leadInfo, accMst);
    	bookingItem1.op__c = opItem[0].Id;
    	update bookingItem1;
    	
    	leadInfo.Field298__c = 'チェックイン完';
    	update leadInfo;

    	Test.stopTest();

    	// 会計画面に動作確認を行う
    	RsvAccount__c rsv = TestCommon.createRsvAccount();
    	rsv = [select Salesday__c from RsvAccount__c where id = :rsv.id];
		AccountAcount__c aa = TestCommon.createAccountAcount(rsv.Id, leadInfo.Id);
    	List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfo.Id];
    	AccountAcount__c accObj = accObjLst[0];
    	TTend__c ttitem = TestCommon.createTTend(rsv.Id, accObj.Id);
		ttitem.Field2__c = '22'; 
		ttitem.Field3__c = '予約金'; 
		ttitem.RowNo__c  = 44;  // メディア種別,メディア名称
		ttitem.Field16__c = '55';
		ttitem.Field17__c = '66';
		ttitem.Field19__c = '67';
		ttitem.Field20__c = '77';// 単価,枚数,支払金額 
		ttitem.Field21__c = '1'; //数量
		//ttitem.Field23__c = '123'; 
		ttitem.SplitGroupNo__c = '88';
		ttitem.PayProductRef__c = accMst.id;  // 支払商品
		ttitem.PayProductName__c = accMst.Name;
		ttitem.CardTypeLst__c = 'American Express';
		ttitem.CouponTypeLst__c = '楽天クーポン';
		ttitem.PaymentType__c = accMst.PaymentType__c;
		ttitem.RelAccount__c =rsv.Id;  // 主従関係(売上)
		ttitem.UseDate__c = Date.today();
		update ttitem;
		
		K_ScheduleReportPdf rp = new K_ScheduleReportPdf();
    	rp.init();
    }
}