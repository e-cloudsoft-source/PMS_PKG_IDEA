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
private class K_ScheduleReportTest {

    static testMethod void myUnitTest() {
    	Test.startTest();
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'ScheduleReportFieldsXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf('<root><shop><SHOPCODE></SHOPCODE></shop></root>');
    	insert item;
    	
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	Test.stopTest();
    	
    	K_ScheduleReport rp = new K_ScheduleReport();
    	String queryDt = DateTime.now().format('yyyy/MM/dd');
    	String[] strArr = new String[]{'','','','',''};
    	K_ScheduleReport.getReportViewInfo('', queryDt, '1', 'true', strArr,'true');
    	System.assertEquals(rp.roomViewLst.size() ,2);
    	Pagereference page = rp.gotoSwitchShop();
    	System.assert(page != null);
    	K_ScheduleReport.FoodSummarySetupInfo foodSummary = K_ScheduleReport.foodSummaryInfo;
    	
        K_ScheduleCookingHelper schedult = new K_ScheduleCookingHelper( Date.today(),'');
        schedult.queryEstLead();
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
    	item.Body = Blob.valueOf('<root><shop><SHOPCODE></SHOPCODE><FIELDS SHOWFOOD="true">Morningtime__c:朝食時間,Relcontact__r.Name:お客様,EntryTime__c:到着日</FIELDS>'
    				+'<LINKFIELD>Name:Id</LINKFIELD><AGGREGATE>StayPersons__c</AGGREGATE>'
    				+'<HIDDENFIELD>refTypeOfRooms__r.ShopInfoRef__r.Name</HIDDENFIELD>'
    				+'<COLNUMSIZE>Rroom__r.Seq__c:46px,Field353__c:36px</COLNUMSIZE>'
    				+'<COLNUMTYPE>Rroom__r.Seq__c:number,Rroom__r.Rnumber__c:number,EntryTime__c:date,</COLNUMTYPE>'
    				+'<COLNUMEDIT>Field4__c,StayPersons__c,Mans__c,Femails__c</COLNUMEDIT>'
    				+'<FOODSUMMARY>'
					+'<COLNUMSIZE><MIDDAYICON>60</MIDDAYICON><PRODCUTNMAEM>240</PRODCUTNMAEM><PRODUCTSUMMY>60</PRODUCTSUMMY></COLNUMSIZE>'
					+'<COLNUMSTYLE><MIDDAYICON>font-size: 14px;</MIDDAYICON><PRODCUTNMAEM>font-size: 14px;</PRODCUTNMAEM><PRODUCTSUMMY>text-align: right; font-size: 14px</PRODUCTSUMMY></COLNUMSTYLE>'
					+'</FOODSUMMARY>'
					+'<HISTORY><BGCOLOR>TRUE</BGCOLOR><COLOR><VALUE>green</VALUE><FREQUENCY>3</FREQUENCY><FIELDS>Mans__c</FIELDS>'
					+'</COLOR><COLOR><VALUE>blue</VALUE><FREQUENCY>4</FREQUENCY><FIELDS>Mans__c</FIELDS></COLOR><COLOR><VALUE>black</VALUE><FREQUENCY>5</FREQUENCY><FIELDS>Mans__c</FIELDS></COLOR>'
					+'<COLOR><VALUE>red</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Femails__c,Childs__c</FIELDS></COLOR><COLOR><VALUE>green</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Field4__c</FIELDS></COLOR>'
					+'<COLOR><VALUE>blue</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Field3__c,StayPersons__c</FIELDS></COLOR><COLOR><VALUE>blue</VALUE><FREQUENCY></FREQUENCY><FIELDS>Rroom__r.Name,Relcontact__r.ApplicantName__c</FIELDS></COLOR>'
					+'<FOODSUMMARYCOLOR DETLEISSHOW="TRUE">'
					+'<VALUE>chartreuse</VALUE>'
					+'</FOODSUMMARYCOLOR>'
					+'</HISTORY>' 
    				+'</shop>'
    				+'<PDFOUTPUT>'
    				+'<PAGEWIDTH>500px</PAGEWIDTH>'
    				+'<COLNUMSIZE>Field291__c:100px,EntryTime__c:100px,ChildFA__c:100px,Childs__c:100px,Name:100px</COLNUMSIZE>'
    				+'<COLNUMSIZE><MIDDAYICON>60</MIDDAYICON><PRODCUTNMAEM>240</PRODCUTNMAEM><PRODUCTSUMMY>60</PRODUCTSUMMY></COLNUMSIZE>'
					+'<COLNUMSTYLE><MIDDAYICON>font-size: 14px;</MIDDAYICON><PRODCUTNMAEM>font-size: 14px;</PRODCUTNMAEM><PRODUCTSUMMY>text-align: right; font-size: 14px</PRODUCTSUMMY></COLNUMSTYLE>'
					+'<PAGEWIDTHFLG>TRUE</PAGEWIDTHFLG>'
					+'<WATCHBATCHTIME>2</WATCHBATCHTIME>'
					+'</PDFOUTPUT></root>');	
    	insert item;
    	Test.startTest();
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	//Lead__c leadInfo1 = TestCommon.createLead();
    	Test.stopTest();
   		Lead__c leadInfo2 = TestCommon.createLead();
   		
    	//leadInfo1.Rroom__c = null;
    	leadInfo2.Field298__c = 'チェックイン完';
    	//List<Lead__c> updLeads = new List<Lead__c>{leadInfo1,leadInfo2};
    	List<Lead__c> updLeads = new List<Lead__c>{leadInfo2};
    	update updLeads;
		
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 2015/12/01 Assert BEGIN
        System.assertEquals(productLst.size(), 1);
        // 2015/12/01 Assert END

    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	
    	K_ScheduleReport rp = new K_ScheduleReport();
    	String queryDt = DateTime.now().format('yyyy/MM/dd');
    	String termDays = '4';
    	//K_ScheduleReport.getReportViewInfo('', queryDt, termDays, 'false');
    	String[] strArr = new String[]{'','','','',''};
    	K_ScheduleReport.getReportViewInfo('', queryDt, termDays, 'false', strArr,'true');
    	
        K_ScheduleCookingHelper schedult = new K_ScheduleCookingHelper( Date.today(),'');
        schedult.queryEstLead();
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
    	item.Body = Blob.valueOf('<root><shop><SHOPCODE></SHOPCODE><FIELDS SHOWFOOD="true">Morningtime__c:朝食時間,Relcontact__r.Name:お客様,EntryTime__c:到着日</FIELDS>'
    				+'<LINKFIELD>Name:Id</LINKFIELD><AGGREGATE>StayPersons__c</AGGREGATE>'
    				+'<HIDDENFIELD>refTypeOfRooms__r.ShopInfoRef__r.Name</HIDDENFIELD>'
    				+'<COLNUMSTYLE>EntryTime__c:text-align: right; font-size: 14px</COLNUMSTYLE>'
    				+'<COLNUMSIZE>Rroom__r.Seq__c:46px,Field353__c:36px</COLNUMSIZE>'
    				+'<COLNUMTYPE>Rroom__r.Seq__c:number,Rroom__r.Rnumber__c:number,EntryTime__c:date,</COLNUMTYPE>'
    				+'<COLNUMEDIT>Field4__c,StayPersons__c,Mans__c,Femails__c</COLNUMEDIT>'
    				+'<FOODSUMMARY>'
					+'<COLNUMSIZE><MIDDAYICON>60</MIDDAYICON><PRODCUTNMAEM>240</PRODCUTNMAEM><PRODUCTSUMMY>60</PRODUCTSUMMY></COLNUMSIZE>'
					+'<COLNUMSTYLE><MIDDAYICON>font-size: 14px;</MIDDAYICON><PRODCUTNMAEM>font-size: 14px;</PRODCUTNMAEM><PRODUCTSUMMY>text-align: right; font-size: 14px</PRODUCTSUMMY></COLNUMSTYLE>'
					+'</FOODSUMMARY>'
					+'<HISTORY><BGCOLOR>TRUE</BGCOLOR><COLOR><VALUE>green</VALUE><FREQUENCY>3</FREQUENCY><FIELDS>Mans__c</FIELDS>'
					+'</COLOR><COLOR><VALUE>blue</VALUE><FREQUENCY>4</FREQUENCY><FIELDS>Mans__c</FIELDS></COLOR><COLOR><VALUE>black</VALUE><FREQUENCY>5</FREQUENCY><FIELDS>Mans__c</FIELDS></COLOR>'
					+'<COLOR><VALUE>red</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Femails__c,Childs__c</FIELDS></COLOR><COLOR><VALUE>green</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Field4__c</FIELDS></COLOR>'
					+'<COLOR><VALUE>blue</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Field3__c,StayPersons__c</FIELDS></COLOR><COLOR><VALUE>blue</VALUE><FREQUENCY></FREQUENCY><FIELDS>Rroom__r.Name,Relcontact__r.ApplicantName__c</FIELDS></COLOR>'
					+'<FOODSUMMARYCOLOR DETLEISSHOW="TRUE">'
					+'<VALUE>chartreuse</VALUE>'
					+'</FOODSUMMARYCOLOR>'
					+'</HISTORY>' 
    				+'</shop>'
    				+'<PDFOUTPUT>'
    				+'<PAGEWIDTH>500px</PAGEWIDTH>'
    				+'<COLNUMSIZE>Field291__c:100px,EntryTime__c:100px,ChildFA__c:100px,Childs__c:100px,Name:100px</COLNUMSIZE>'
    				+'<COLNUMSIZE><MIDDAYICON>60</MIDDAYICON><PRODCUTNMAEM>240</PRODCUTNMAEM><PRODUCTSUMMY>60</PRODUCTSUMMY></COLNUMSIZE>'
					+'<COLNUMSTYLE><MIDDAYICON>font-size: 14px;</MIDDAYICON><PRODCUTNMAEM>font-size: 14px;</PRODCUTNMAEM><PRODUCTSUMMY>text-align: right; font-size: 14px</PRODUCTSUMMY></COLNUMSTYLE>'
					+'<PAGEWIDTHFLG>TRUE</PAGEWIDTHFLG>'
					+'<WATCHBATCHTIME>2</WATCHBATCHTIME>'
					+'</PDFOUTPUT></root>');	
    	insert item;
    	//Lead__c leadInfo1 = TestCommon.createLead();
    	ShopInformation__c shopInfo = TestCommon.createShopInfo();
    	List<TypeOfRooms__c> typeOfRoom = TestCommon.createTypeOfRoomByShop(shopInfo.Id,3);
    	Lead__c leadInfo = TestCommon.createBookingLead(system.today(), typeOfRoom[0].id, 1);
    	//leadInfo1.Rroom__c = null;
    	//leadInfo2.Field298__c = 'チェックイン完';
    	//List<Lead__c> updLeads = new List<Lead__c>{leadInfo1,leadInfo2};
    	//List<Lead__c> updLeads = new List<Lead__c>{leadLst[0]};
    	//update updLeads;
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 2015/12/01 Assert BEGIN
        System.assertEquals(productLst.size(), 1);
        // 2015/12/01 Assert END
        CommDefine__c conf = TestCommon.createCommDefine();
    	conf.ReportKScheduleWhere__c = '朝食:1,会席';
		List<OP__c> opItem = TestCommon.createOP(3);
    	// 見積明細を作成する
    	BookingEstimateItem__c items = TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	items.OP__c = opItem[0].Id;
    	items.ActionType__c= '朝食';
    	update items;
    	K_ScheduleReport rp = new K_ScheduleReport();
    	String queryDt = DateTime.now().format('yyyy/MM/dd');
    	String termDays = '4';
    	String[] strArr = new String[]{'','','','',''};
    	Test.startTest();
    	K_ScheduleReport.getReportViewInfo('', queryDt, termDays, 'false', strArr,'false');
    	  
        K_ScheduleCookingHelper schedult = new K_ScheduleCookingHelper( Date.today(),'');
        schedult.queryEstLead();
        Test.stopTest();  	
    }
    static testMethod void myUnitTest3_1() {
    	
    	CommDefine__c def = TestCommon.createCommDefine();
    	def.ReportKScheduleWhere__c = '会席,お膳,単品,仕出し,朝食:1';
    	update def;
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'ScheduleReportFieldsXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf('<root><shop><SHOPCODE></SHOPCODE><FIELDS SHOWFOOD="true">Morningtime__c:朝食時間,Relcontact__r.Name:お客様,EntryTime__c:到着日</FIELDS>'
    				+'<LINKFIELD>Name:Id</LINKFIELD><AGGREGATE>StayPersons__c</AGGREGATE>'
    				+'<HIDDENFIELD>refTypeOfRooms__r.ShopInfoRef__r.Name</HIDDENFIELD>'
    				+'<COLNUMSTYLE>EntryTime__c:text-align: right; font-size: 14px</COLNUMSTYLE>'
    				+'<COLNUMSIZE>Rroom__r.Seq__c:46px,Field353__c:36px</COLNUMSIZE>'
    				+'<COLNUMTYPE>Rroom__r.Seq__c:number,Rroom__r.Rnumber__c:number,EntryTime__c:date,</COLNUMTYPE>'
    				+'<COLNUMEDIT>Field4__c,StayPersons__c,Mans__c,Femails__c</COLNUMEDIT>'
    				+'<FOODSUMMARY>'
					+'<COLNUMSIZE><MIDDAYICON>60</MIDDAYICON><PRODCUTNMAEM>240</PRODCUTNMAEM><PRODUCTSUMMY>60</PRODUCTSUMMY></COLNUMSIZE>'
					+'<COLNUMSTYLE><MIDDAYICON>font-size: 14px;</MIDDAYICON><PRODCUTNMAEM>font-size: 14px;</PRODCUTNMAEM><PRODUCTSUMMY>text-align: right; font-size: 14px</PRODUCTSUMMY></COLNUMSTYLE>'
					+'</FOODSUMMARY>'
					+'<HISTORY><BGCOLOR>TRUE</BGCOLOR><COLOR><VALUE>green</VALUE><FREQUENCY>3</FREQUENCY><FIELDS>Mans__c</FIELDS>'
					+'</COLOR><COLOR><VALUE>blue</VALUE><FREQUENCY>4</FREQUENCY><FIELDS>Mans__c</FIELDS></COLOR><COLOR><VALUE>black</VALUE><FREQUENCY>5</FREQUENCY><FIELDS>Mans__c</FIELDS></COLOR>'
					+'<COLOR><VALUE>red</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Femails__c,Childs__c</FIELDS></COLOR><COLOR><VALUE>green</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Field4__c</FIELDS></COLOR>'
					+'<COLOR><VALUE>blue</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Field3__c,StayPersons__c</FIELDS></COLOR><COLOR><VALUE>blue</VALUE><FREQUENCY></FREQUENCY><FIELDS>Rroom__r.Name,Relcontact__r.ApplicantName__c</FIELDS></COLOR>'
					+'<FOODSUMMARYCOLOR DETLEISSHOW="TRUE">'
					+'<VALUE>chartreuse</VALUE>'
					+'</FOODSUMMARYCOLOR>'
					+'</HISTORY>' 
    				+'</shop>'
    				+'<PDFOUTPUT>'
    				+'<PAGEWIDTH>500px</PAGEWIDTH>'
    				+'<COLNUMSIZE>Field291__c:100px,EntryTime__c:100px,ChildFA__c:100px,Childs__c:100px,Name:100px</COLNUMSIZE>'
    				+'<COLNUMSIZE><MIDDAYICON>60</MIDDAYICON><PRODCUTNMAEM>240</PRODCUTNMAEM><PRODUCTSUMMY>60</PRODUCTSUMMY></COLNUMSIZE>'
					+'<COLNUMSTYLE><MIDDAYICON>font-size: 14px;</MIDDAYICON><PRODCUTNMAEM>font-size: 14px;</PRODCUTNMAEM><PRODUCTSUMMY>text-align: right; font-size: 14px</PRODUCTSUMMY></COLNUMSTYLE>'
					+'<PAGEWIDTHFLG>TRUE</PAGEWIDTHFLG>'
					+'<WATCHBATCHTIME>2</WATCHBATCHTIME>'
					+'</PDFOUTPUT></root>');	
    	insert item;
    	//Lead__c leadInfo1 = TestCommon.createLead();
    	ShopInformation__c shopInfo = TestCommon.createShopInfo();
    	List<TypeOfRooms__c> typeOfRoom = TestCommon.createTypeOfRoomByShop(shopInfo.Id,3);
    	Lead__c leadInfo = TestCommon.createBookingLead(system.today(), typeOfRoom[0].id, 1);
    	leadInfo.Field298__c = 'チェックイン完';
    	update leadInfo;
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 2015/12/01 Assert BEGIN
        System.assertEquals(productLst.size(), 1);
        // 2015/12/01 Assert END
        CommDefine__c conf = TestCommon.createCommDefine();
    	conf.ReportKScheduleWhere__c = '朝食:1,会席';
		List<OP__c> opItem = TestCommon.createOP(3);
		RsvAccount__c rsv = TestCommon.createRsvAccount();
        AccountAcount__c acc =TestCommon.createAccountAcount(rsv.Id,leadInfo.Id);
        Tran1__c tran1 = new Tran1__c(
    		Field7__c = productLst[0].Id,
    		Field1__c = acc.Id,
    		RelAccount__c = rsv.Id
    	);
    	insert tran1;
    	K_ScheduleReport rp = new K_ScheduleReport();
    	String queryDt = DateTime.now().format('yyyy/MM/dd');
    	String termDays = '4';
    	String[] strArr = new String[]{'','','','',''};
    	Test.startTest();
    	K_ScheduleReport.getReportViewInfo('', queryDt, termDays, 'false', strArr,'false');
    	  
        K_ScheduleCookingHelper schedult = new K_ScheduleCookingHelper( Date.today(),'');
        schedult.queryEstLead();
        Test.stopTest();  	
    }
    static testMethod void myUnitTest4() {
    	
    	CommDefine__c def = TestCommon.createCommDefine();
    	def.ReportKScheduleWhere__c = '会席,お膳,単品,仕出し,朝食:1';
    	update def;
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'ScheduleReportFieldsXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf('<root><shop><SHOPCODE></SHOPCODE><OPTIONS><ASSIGNONLYROOM>FALSE</ASSIGNONLYROOM><POLLERTIMER>60</POLLERTIMER></OPTIONS><FIELDS SHOWFOOD="true" SHOWFOODPOS="1">refTypeOfRooms__r.ShopInfoRef__r.Name:支店,SeminarOrderFlg__c:セミナー,StayPersons__c:予約人数,Field315__c:御支払,Morningtime__c:朝食時間,Relcontact__r.Name:お客様,EntryTime__c:到着日,SalesOfficeInfoRef__c:Name</FIELDS>'
    				+'<LINKFIELD>Name:Id,SalesOfficeInfoRef__c:Name</LINKFIELD><AGGREGATE>StayPersons__c</AGGREGATE>'
    				+'<HIDDENFIELD>refTypeOfRooms__r.ShopInfoRef__r.Name</HIDDENFIELD>'
    				+'<COLNUMSIZE>Field315__c:46px,Field353__c:36px</COLNUMSIZE>'
    				+'<COLNUMSTYLE>SalesOfficeInfoRef__c:text-align: right; font-size: 14px,SalesOfficeInfoRef__c:text-align: right; font-size: 14px</COLNUMSTYLE>'
    				+'<COLNUMTYPE>Rroom__r.Seq__c:number,Rroom__r.Rnumber__c:number,EntryTime__c:date,SeminarOrderFlg__c:boolean,Field315__c:list</COLNUMTYPE>'
    				+'<COLNUMEDIT>Field4__c,StayPersons__c,Mans__c,Femails__c</COLNUMEDIT>'
    				+'<FOODSUMMARY>'
					+'<COLNUMSIZE><MIDDAYICON>60</MIDDAYICON><PRODCUTNMAEM>240</PRODCUTNMAEM><PRODUCTSUMMY>60</PRODUCTSUMMY></COLNUMSIZE>'
					+'<COLNUMSTYLE><MIDDAYICON>font-size: 14px;</MIDDAYICON><PRODCUTNMAEM>font-size: 14px;</PRODCUTNMAEM><PRODUCTSUMMY>text-align: right; font-size: 14px</PRODUCTSUMMY></COLNUMSTYLE>'
					+'</FOODSUMMARY>'
					+'<HISTORY><BGCOLOR>TRUE</BGCOLOR><COLOR><VALUE TMFROM="1">green</VALUE><FREQUENCY>3</FREQUENCY><FIELDS>EntryTime__c</FIELDS>'
					+'</COLOR><COLOR><VALUE TO="1">blue</VALUE><FREQUENCY>4</FREQUENCY><FIELDS>Mans__c</FIELDS></COLOR><COLOR><VALUE>black</VALUE><FREQUENCY>5</FREQUENCY><FIELDS>Mans__c</FIELDS></COLOR>'
					+'<COLOR><VALUE>red</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Femails__c,Childs__c</FIELDS></COLOR><COLOR><VALUE>green</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Field4__c</FIELDS></COLOR>'
					+'<COLOR><VALUE>blue</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Relcontact__r.Name,StayPersons__c</FIELDS></COLOR><COLOR><VALUE>blue</VALUE><FREQUENCY></FREQUENCY><FIELDS>Rroom__r.Name,Relcontact__r.ApplicantName__c</FIELDS></COLOR>'
					+'<FOODSUMMARYCOLOR DETAILISSHOW="TRUE">'
					+'<VALUE>chartreuse</VALUE>'
					+'</FOODSUMMARYCOLOR>'
					+'</HISTORY>' 
    				+'</shop>'
    				+'<shop><SHOPCODE></SHOPCODE>01<OPTIONS><ASSIGNONLYROOM>FALSE</ASSIGNONLYROOM><POLLERTIMER>60</POLLERTIMER></OPTIONS><FIELDS SHOWFOOD="true" SHOWFOODPOS="1">refTypeOfRooms__r.ShopInfoRef__r.Name:支店,SeminarOrderFlg__c:セミナー,StayPersons__c:予約人数,Field315__c:御支払,Morningtime__c:朝食時間,Relcontact__r.Name:お客様,EntryTime__c:到着日,SalesOfficeInfoRef__c:Name</FIELDS>'
    				+'<LINKFIELD>Name:Id,SalesOfficeInfoRef__c:Name</LINKFIELD><AGGREGATE>StayPersons__c</AGGREGATE>'
    				+'<HIDDENFIELD>refTypeOfRooms__r.ShopInfoRef__r.Name</HIDDENFIELD>'
    				+'<COLNUMSIZE>Rroom__r.Seq__c:46px,Field315__c:36px</COLNUMSIZE>'
    				+'<COLNUMSTYLE>SalesOfficeInfoRef__c:text-align: right; font-size: 14px</COLNUMSTYLE>'
    				+'<COLNUMTYPE>Rroom__r.Seq__c:number,Rroom__r.Rnumber__c:number,EntryTime__c:date,SeminarOrderFlg__c:boolean,Field315__c:list</COLNUMTYPE>'
    				+'<COLNUMEDIT>Field4__c,StayPersons__c,Mans__c,Femails__c</COLNUMEDIT>'
    				+'<FOODSUMMARY>'
					+'<COLNUMSIZE><MIDDAYICON>60</MIDDAYICON><PRODCUTNMAEM>240</PRODCUTNMAEM><PRODUCTSUMMY>60</PRODUCTSUMMY></COLNUMSIZE>'
					+'<COLNUMSTYLE><MIDDAYICON>font-size: 14px;</MIDDAYICON><PRODCUTNMAEM>font-size: 14px;</PRODCUTNMAEM><PRODUCTSUMMY>text-align: right; font-size: 14px</PRODUCTSUMMY></COLNUMSTYLE>'
					+'</FOODSUMMARY>'
					+'<HISTORY><BGCOLOR>TRUE</BGCOLOR><COLOR><VALUE TMFROM="1">green</VALUE><FREQUENCY>3</FREQUENCY><FIELDS>EntryTime__c</FIELDS>'
					+'</COLOR><COLOR><VALUE TO="1">blue</VALUE><FREQUENCY>4</FREQUENCY><FIELDS>Mans__c</FIELDS></COLOR><COLOR><VALUE>black</VALUE><FREQUENCY>5</FREQUENCY><FIELDS>Mans__c</FIELDS></COLOR>'
					+'<COLOR><VALUE>red</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Femails__c,Childs__c</FIELDS></COLOR><COLOR><VALUE>green</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Field4__c</FIELDS></COLOR>'
					+'<COLOR><VALUE>blue</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Relcontact__r.Name,StayPersons__c</FIELDS></COLOR><COLOR><VALUE>blue</VALUE><FREQUENCY></FREQUENCY><FIELDS>Rroom__r.Name,Relcontact__r.ApplicantName__c</FIELDS></COLOR>'
					+'<FOODSUMMARYCOLOR DETAILISSHOW="TRUE">'
					+'<VALUE>chartreuse</VALUE>'
					+'</FOODSUMMARYCOLOR>'
					+'</HISTORY>' 
    				+'</shop>'
    				+'<shop><SHOPCODE>02</SHOPCODE><OPTIONS><ASSIGNONLYROOM>FALSE</ASSIGNONLYROOM><POLLERTIMER>60</POLLERTIMER></OPTIONS><FIELDS SHOWFOOD="true" SHOWFOODPOS="1">refTypeOfRooms__r.ShopInfoRef__r.Name:支店,SeminarOrderFlg__c:セミナー,StayPersons__c:予約人数,Field315__c:御支払,Morningtime__c:朝食時間,Relcontact__r.Name:お客様,EntryTime__c:到着日,SalesOfficeInfoRef__c:Name</FIELDS>'
    				+'<LINKFIELD>Name:Id,SalesOfficeInfoRef__c:Name</LINKFIELD><AGGREGATE>StayPersons__c</AGGREGATE>'
    				+'<HIDDENFIELD>refTypeOfRooms__r.ShopInfoRef__r.Name</HIDDENFIELD>'
    				+'<COLNUMSIZE>Field315__c:46px,Field353__c:36px</COLNUMSIZE>'
    				+'<COLNUMSTYLE>SalesOfficeInfoRef__c:text-align: right; font-size: 14px</COLNUMSTYLE>'
    				+'<COLNUMTYPE>Rroom__r.Seq__c:number,Rroom__r.Rnumber__c:number,EntryTime__c:date,SeminarOrderFlg__c:boolean,Field315__c:list</COLNUMTYPE>'
    				+'<COLNUMEDIT>Field4__c,StayPersons__c,Mans__c,Femails__c</COLNUMEDIT>'
    				+'<FOODSUMMARY>'
					+'<COLNUMSIZE><MIDDAYICON>60</MIDDAYICON><PRODCUTNMAEM>240</PRODCUTNMAEM><PRODUCTSUMMY>60</PRODUCTSUMMY></COLNUMSIZE>'
					+'<COLNUMSTYLE><MIDDAYICON>font-size: 14px;</MIDDAYICON><PRODCUTNMAEM>font-size: 14px;</PRODCUTNMAEM><PRODUCTSUMMY>text-align: right; font-size: 14px</PRODUCTSUMMY></COLNUMSTYLE>'
					+'</FOODSUMMARY>'
					+'<HISTORY><BGCOLOR>TRUE</BGCOLOR><COLOR><VALUE TMFROM="1">green</VALUE><FREQUENCY>3</FREQUENCY><FIELDS>EntryTime__c</FIELDS>'
					+'</COLOR><COLOR><VALUE TO="1">blue</VALUE><FREQUENCY>4</FREQUENCY><FIELDS>Mans__c</FIELDS></COLOR><COLOR><VALUE>black</VALUE><FREQUENCY>5</FREQUENCY><FIELDS>Mans__c</FIELDS></COLOR>'
					+'<COLOR><VALUE>red</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Femails__c,Childs__c</FIELDS></COLOR><COLOR><VALUE>green</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Field4__c</FIELDS></COLOR>'
					+'<COLOR><VALUE>blue</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Relcontact__r.Name,StayPersons__c</FIELDS></COLOR><COLOR><VALUE>blue</VALUE><FREQUENCY></FREQUENCY><FIELDS>Rroom__r.Name,Relcontact__r.ApplicantName__c</FIELDS></COLOR>'
					+'<FOODSUMMARYCOLOR DETAILISSHOW="TRUE">'
					+'<VALUE>chartreuse</VALUE>'
					+'</FOODSUMMARYCOLOR>'
					+'</HISTORY>' 
    				+'</shop>'
    				+'<PDFOUTPUT>'
    				+'<PAGEWIDTH>500px</PAGEWIDTH>'
    				+'<COLNUMSIZE>Field291__c:100px,EntryTime__c:100px,ChildFA__c:100px,Childs__c:100px,Name:100px</COLNUMSIZE>'
    				+'<COLNUMSIZE><MIDDAYICON>60</MIDDAYICON><PRODCUTNMAEM>240</PRODCUTNMAEM><PRODUCTSUMMY>60</PRODUCTSUMMY></COLNUMSIZE>'
					+'<COLNUMSTYLE><MIDDAYICON>font-size: 14px;</MIDDAYICON><PRODCUTNMAEM>font-size: 14px;</PRODCUTNMAEM><PRODUCTSUMMY>text-align: right; font-size: 14px</PRODUCTSUMMY></COLNUMSTYLE>'
					+'<PAGEWIDTHFLG>TRUE</PAGEWIDTHFLG>'
					+'<WATCHBATCHTIME>2</WATCHBATCHTIME>'
					+'</PDFOUTPUT>'
					+'<GROUPABLE>'
					+'<AUTOEXPAND>true</AUTOEXPAND>'
					+'<GROUPTITLE> StayPersons__c:予約人数,Name,Rroom__r.Seq__c,Field372__c,Field4__c:1,Rroom__r.Name:部屋,Comment3__c:特記事項,Rroom__r.Sno__c</GROUPTITLE>'
					+'</GROUPABLE>'
					+'<SORTFIELD>Rroom__r.SEQ__c</SORTFIELD>'
					+'</root>');	
    	insert item;
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
    	List<TypeOfRooms__c> typeOfRoom = TestCommon.createTypeOfRoomByShop(shopInfo.Id,3);
    	Room__c rooms = TestCommon.createRooms(typeOfRoom[0].Id);
    	rooms.ShopInfoRef__c = shopInfo.Id; 	
    	rooms.UseOfRoom__c = '客室';
    	update rooms;
    	// 予約情報を作成する
    	
    	//Lead__c leadInfo2 = TestCommon.createLead();  		
    	//leadInfo2.Field298__c = 'チェックイン完';
		Lead__c leadInfo = TestCommon.createLead();
    	leadInfo.Rroom__c = rooms.Id;
    	leadInfo.Field298__c = 'チェックイン完';
    	List<Lead__c> updLeads = new List<Lead__c>{leadInfo};
    	update updLeads;
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 2015/12/01 Assert BEGIN
        System.assertEquals(productLst.size(), 1);
        // 2015/12/01 Assert END
        CommDefine__c conf = TestCommon.createCommDefine();
    	conf.ReportKScheduleWhere__c = '朝食:1,会席';
		List<OP__c> opItem = TestCommon.createOP(3);
		
		Plan__c planItem = TestCommon.createPlan();
    	planItem.AccountA__c = productLst[0].Id;
    	update planItem;
    	PlanDetail__c detail = new PlanDetail__c(
        	PlanRef__c = planItem.Id,
        	AccountMasterRef__c = productLst[0].Id
        );
        insert detail;
        /*
        RsvAccount__c rsv = TestCommon.createRsvAccount();
        AccountAcount__c acc =TestCommon.createAccountAcount(rsv.Id,leadInfo.Id);
        Tran1__c tran1 = new Tran1__c(
    		Field7__c = productLst[0].Id,
    		Field1__c = acc.Id,
    		RelAccount__c = rsv.Id
    	);
    	
    	insert tran1; 
    	/*
    	// 見積明細を作成する
    	BookingEstimateItem__c items = TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	items.OP__c = opItem[0].Id;
    	items.ActionType__c= '朝食';
    	update items;
    	*/
        Test.startTest();
    	K_ScheduleReport rp = new K_ScheduleReport();
    	
    	String queryDt = DateTime.now().format('yyyy/MM/dd');
    	String termDays = '4';
    	//K_ScheduleReport.getReportViewInfo('', queryDt, termDays, 'false');
    	String[] strArr = new String[]{'','','','',''};
    	K_ScheduleReport.getReportViewInfo('02', queryDt, termDays, 'true', strArr,'false');
    	
    	String jsonEditColumn = 'boolean,date,String';
		Map<String,String> columnType =new Map<String,String>();
		
		columnType.put('EntryDate__c','date');
		columnType.put('boolean','boolean');
		columnType.put('String','String');
		columnType.put('Id',updLeads[0].Id);
		
		List<Map<String,String>> jsondata = new List<Map<String,String>>();
		jsondata.add(columnType);
		K_ScheduleReport.updateLeadMsg(JSON.serialize(jsondata), jsonEditColumn, JSON.serialize(columnType));
    	Test.stopTest();
    }
    static testMethod void myUnitTest5() {
    	Test.startTest();
    	CommDefine__c def = TestCommon.createCommDefine();
    	def.ReportKScheduleWhere__c = '会席,お膳,単品,仕出し,朝食:1';
    	update def;
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'ScheduleReportFieldsXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf('<root><shop><SHOPCODE>02</SHOPCODE><FIELDS SHOWFOOD="true">Morningtime__c:朝食時間,Relcontact__r.Name:お客様,EntryTime__c:到着日</FIELDS>'
    				+'<LINKFIELD>Name:Id</LINKFIELD><AGGREGATE>StayPersons__c</AGGREGATE>'
    				+'<HIDDENFIELD>refTypeOfRooms__r.ShopInfoRef__r.Name</HIDDENFIELD>'
    				+'<COLNUMSTYLE>EntryTime__c:text-align: right; font-size: 14px</COLNUMSTYLE>'
    				+'<COLNUMSIZE>Rroom__r.Seq__c:46px,Field353__c:36px</COLNUMSIZE>'
    				+'<COLNUMTYPE>Rroom__r.Seq__c:number,Rroom__r.Rnumber__c:number,EntryTime__c:date</COLNUMTYPE>'
    				+'<COLNUMEDIT>Field4__c,StayPersons__c,Mans__c,Femails__c</COLNUMEDIT>'
    				+'<FOODSUMMARY>'
					+'<COLNUMSIZE><MIDDAYICON>60</MIDDAYICON><PRODCUTNMAEM>240</PRODCUTNMAEM><PRODUCTSUMMY>60</PRODUCTSUMMY></COLNUMSIZE>'
					+'<COLNUMSTYLE><MIDDAYICON>font-size: 14px;</MIDDAYICON><PRODCUTNMAEM>font-size: 14px;</PRODCUTNMAEM><PRODUCTSUMMY>text-align: right; font-size: 14px</PRODUCTSUMMY></COLNUMSTYLE>'
					+'</FOODSUMMARY>'
					+'<HISTORY><BGCOLOR>TRUE</BGCOLOR><COLOR><VALUE>green</VALUE><FREQUENCY>3</FREQUENCY><FIELDS>Mans__c</FIELDS>'
					+'</COLOR><COLOR><VALUE>blue</VALUE><FREQUENCY>4</FREQUENCY><FIELDS>Mans__c</FIELDS></COLOR><COLOR><VALUE>black</VALUE><FREQUENCY>5</FREQUENCY><FIELDS>Mans__c</FIELDS></COLOR>'
					+'<COLOR><VALUE>red</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Femails__c,Childs__c</FIELDS></COLOR><COLOR><VALUE>green</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Field4__c</FIELDS></COLOR>'
					+'<COLOR><VALUE>blue</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Field3__c,StayPersons__c</FIELDS></COLOR><COLOR><VALUE>blue</VALUE><FREQUENCY></FREQUENCY><FIELDS>Rroom__r.Name,Relcontact__r.ApplicantName__c</FIELDS></COLOR>'
					+'<FOODSUMMARYCOLOR DETLEISSHOW="TRUE">'
					+'<VALUE>chartreuse</VALUE>'
					+'</FOODSUMMARYCOLOR>'
					+'</HISTORY>' 
    				+'</shop>'
    				+'<PDFOUTPUT>'
    				+'<PAGEWIDTH>500px</PAGEWIDTH>'
    				+'<COLNUMSIZE>Field291__c:100px,EntryTime__c:100px,ChildFA__c:100px,Childs__c:100px,Name:100px</COLNUMSIZE>'
    				+'<COLNUMSIZE><MIDDAYICON>60</MIDDAYICON><PRODCUTNMAEM>240</PRODCUTNMAEM><PRODUCTSUMMY>60</PRODUCTSUMMY></COLNUMSIZE>'
					+'<COLNUMSTYLE><MIDDAYICON>font-size: 14px;</MIDDAYICON><PRODCUTNMAEM>font-size: 14px;</PRODCUTNMAEM><PRODUCTSUMMY>text-align: right; font-size: 14px</PRODUCTSUMMY></COLNUMSTYLE>'
					+'<PAGEWIDTHFLG>TRUE</PAGEWIDTHFLG>'
					+'<WATCHBATCHTIME>2</WATCHBATCHTIME>'
					+'</PDFOUTPUT></root>');	
    	insert item;
    	
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
    	typeOfRoom[0].MaxRooms__c = 0;
    	update typeOfRoom;
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	leadInfo.Field298__c = 'チェックイン完';
    	leadInfo.refTypeOfRooms__c = typeOfRoom[0].Id;   	   
    	
    	Test.stopTest(); 
    	/*
    	Lead__c leadInfo2 = TestCommon.createLead();

    	leadInfo2.Field298__c = 'チェックイン完';
    	leadInfo2.refTypeOfRooms__c = typeOfRoom[0].Id;
    	leadInfo2.Rroom__c = null;
    	//leadInfo2.Rroom__c = null;
    	List<Lead__c> updLeads = new List<Lead__c>{leadInfo2};  
    	update updLeads;
    	*/
		Room__c rooms = TestCommon.createRooms(typeOfRoom[0].Id);
    	rooms.UseOfRoom__c = '客室';
    	rooms.ShopInfoRef__c = shopInfo.Id;
    	update rooms; 
    	

    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 2015/12/01 Assert BEGIN
        System.assertEquals(productLst.size(), 1);
        // 2015/12/01 Assert END
        CommDefine__c conf = TestCommon.createCommDefine();
    	conf.ReportKScheduleWhere__c = '朝食:1,会席';
		List<OP__c> opItem = TestCommon.createOP(3);
  	
		Plan__c planItem = TestCommon.createPlan();
    	planItem.AccountA__c = productLst[0].Id;
    	update planItem;
    	PlanDetail__c detail = new PlanDetail__c(
        	PlanRef__c = planItem.Id,
        	AccountMasterRef__c = productLst[0].Id
        );
        insert detail;
        RsvAccount__c rsv = TestCommon.createRsvAccount();
        /*
        AccountAcount__c acc =TestCommon.createAccountAcount(rsv.Id,leadInfo2.Id);
        Tran1__c tran1 = new Tran1__c(
    		Field7__c = productLst[0].Id,
    		Field1__c = acc.Id,
    		RelAccount__c = rsv.Id
    	);
    	
    	insert tran1;    
    	
    	// 見積明細を作成する
    	BookingEstimateItem__c items = TestCommon.createBookEstItem(leadInfo2, productLst[0]);
    	items.OP__c = opItem[0].Id;
    	items.ActionType__c= '朝食';
    	update items;
    	*/
    	K_ScheduleReport rp = new K_ScheduleReport();
    	String queryDt = DateTime.now().format('yyyy/MM/dd');
    	String termDays = '4';
    	String[] strArr = new String[]{'','','','',''};
    	K_ScheduleReport.getReportViewInfo('02', queryDt, termDays, 'false', strArr,'true');
        //K_ScheduleCookingHelper schedult = new K_ScheduleCookingHelper( Date.today(),'02');
        //schedult.queryEstLead();
    }
    static testMethod void myUnitTest6() {
    	
    	CommDefine__c def = TestCommon.createCommDefine();
    	def.ReportKScheduleWhere__c = '会席,お膳,単品,仕出し,朝食:1';
    	update def;
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'ScheduleReportFieldsXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf('<root><shop><SHOPCODE>02</SHOPCODE><FIELDS SHOWFOOD="true">Morningtime__c:朝食時間,Relcontact__r.Name:お客様,EntryTime__c:到着日</FIELDS>'
    				+'<LINKFIELD>Name:Id</LINKFIELD><AGGREGATE>StayPersons__c</AGGREGATE>'
    				+'<HIDDENFIELD>refTypeOfRooms__r.ShopInfoRef__r.Name</HIDDENFIELD>'
    				+'<COLNUMSTYLE>EntryTime__c:text-align: right; font-size: 14px</COLNUMSTYLE>'
    				+'<COLNUMSIZE>Rroom__r.Seq__c:46px,Field353__c:36px</COLNUMSIZE>'
    				+'<COLNUMTYPE>Rroom__r.Seq__c:number,Rroom__r.Rnumber__c:number,EntryTime__c:date</COLNUMTYPE>'
    				+'<COLNUMEDIT>Field4__c,StayPersons__c,Mans__c,Femails__c</COLNUMEDIT>'
    				+'<FOODSUMMARY>'
					+'<COLNUMSIZE><MIDDAYICON>60</MIDDAYICON><PRODCUTNMAEM>240</PRODCUTNMAEM><PRODUCTSUMMY>60</PRODUCTSUMMY></COLNUMSIZE>'
					+'<COLNUMSTYLE><MIDDAYICON>font-size: 14px;</MIDDAYICON><PRODCUTNMAEM>font-size: 14px;</PRODCUTNMAEM><PRODUCTSUMMY>text-align: right; font-size: 14px</PRODUCTSUMMY></COLNUMSTYLE>'
					+'</FOODSUMMARY>'
					+'<HISTORY><BGCOLOR>TRUE</BGCOLOR><COLOR><VALUE>green</VALUE><FREQUENCY>3</FREQUENCY><FIELDS>Mans__c</FIELDS>'
					+'</COLOR><COLOR><VALUE>blue</VALUE><FREQUENCY>4</FREQUENCY><FIELDS>Mans__c</FIELDS></COLOR><COLOR><VALUE>black</VALUE><FREQUENCY>5</FREQUENCY><FIELDS>Mans__c</FIELDS></COLOR>'
					+'<COLOR><VALUE>red</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Femails__c,Childs__c</FIELDS></COLOR><COLOR><VALUE>green</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Field4__c</FIELDS></COLOR>'
					+'<COLOR><VALUE>blue</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Field3__c,StayPersons__c</FIELDS></COLOR><COLOR><VALUE>blue</VALUE><FREQUENCY></FREQUENCY><FIELDS>Rroom__r.Name,Relcontact__r.ApplicantName__c</FIELDS></COLOR>'
					+'<FOODSUMMARYCOLOR DETLEISSHOW="TRUE">'
					+'<VALUE>chartreuse</VALUE>'
					+'</FOODSUMMARYCOLOR>'
					+'</HISTORY>' 
    				+'</shop>'
    				+'<PDFOUTPUT>'
    				+'<PAGEWIDTH>500px</PAGEWIDTH>'
    				+'<COLNUMSIZE>Field291__c:100px,EntryTime__c:100px,ChildFA__c:100px,Childs__c:100px,Name:100px</COLNUMSIZE>'
    				+'<COLNUMSIZE><MIDDAYICON>60</MIDDAYICON><PRODCUTNMAEM>240</PRODCUTNMAEM><PRODUCTSUMMY>60</PRODUCTSUMMY></COLNUMSIZE>'
					+'<COLNUMSTYLE><MIDDAYICON>font-size: 14px;</MIDDAYICON><PRODCUTNMAEM>font-size: 14px;</PRODCUTNMAEM><PRODUCTSUMMY>text-align: right; font-size: 14px</PRODUCTSUMMY></COLNUMSTYLE>'
					+'<PAGEWIDTHFLG>TRUE</PAGEWIDTHFLG>'
					+'<WATCHBATCHTIME>2</WATCHBATCHTIME>'
					+'</PDFOUTPUT></root>');	
    	insert item;
    	Test.startTest();
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
    	typeOfRoom[0].MaxRooms__c = 0;
    	update typeOfRoom;
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	leadInfo.Field298__c = 'チェックイン完';
    	leadInfo.refTypeOfRooms__c = typeOfRoom[0].Id;     	   
    	Test.stopTest(); 
    	Lead__c leadInfo2 = TestCommon.createLead();
    	leadInfo2.refTypeOfRooms__c = typeOfRoom[0].Id;
    	leadInfo2.Rroom__c = null;
    	List<Lead__c> updLeads = new List<Lead__c>{leadInfo2};  
    	update updLeads;	 		
		Room__c rooms = TestCommon.createRooms(typeOfRoom[0].Id);
    	rooms.UseOfRoom__c = '客室';
    	rooms.ShopInfoRef__c = shopInfo.Id;
    	update rooms; 
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 2015/12/01 Assert BEGIN
        System.assertEquals(productLst.size(), 1);
        // 2015/12/01 Assert END
        CommDefine__c conf = TestCommon.createCommDefine();
    	conf.ReportKScheduleWhere__c = '朝食:1,会席';
		List<OP__c> opItem = TestCommon.createOP(3);
		
		Plan__c planItem = TestCommon.createPlan();
    	planItem.AccountA__c = productLst[0].Id;
    	update planItem;
    	PlanDetail__c detail = new PlanDetail__c(
        	PlanRef__c = planItem.Id,
        	AccountMasterRef__c = productLst[0].Id
        );
        insert detail;
        RsvAccount__c rsv = TestCommon.createRsvAccount();
        AccountAcount__c acc =TestCommon.createAccountAcount(rsv.Id,leadInfo2.Id);
        Tran1__c tran1 = new Tran1__c(
    		Field7__c = productLst[0].Id,
    		Field1__c = acc.Id,
    		RelAccount__c = rsv.Id
    	);
    	
    	insert tran1;  	 
    	// 見積明細を作成する
    	BookingEstimateItem__c items = TestCommon.createBookEstItem(leadInfo2, productLst[0]);
    	items.OP__c = opItem[0].Id;
    	items.ActionType__c= '朝食';
    	update items;
    	K_ScheduleReport rp = new K_ScheduleReport();
    	String queryDt = DateTime.now().format('yyyy/MM/dd');
    	String termDays = '4';
    	String[] strArr = new String[]{'','','','',''};
    	K_ScheduleReport.getReportViewInfo('02', queryDt, termDays, 'false', strArr,'false');
    	
        K_ScheduleCookingHelper schedult = new K_ScheduleCookingHelper( Date.today(),'02');
        schedult.queryEstLead();
    }
    static testMethod void myUnitTest7() {
    	
    	CommDefine__c def = TestCommon.createCommDefine();
    	def.ReportKScheduleWhere__c = '会席,お膳,単品,仕出し,朝食:1';
    	update def;
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'ScheduleReportFieldsXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf('<root><shop><SHOPCODE>02</SHOPCODE><FIELDS SHOWFOOD="true">Morningtime__c:朝食時間,Relcontact__r.Name:お客様,EntryTime__c:到着日</FIELDS>'
    				+'<LINKFIELD>Name:Id</LINKFIELD><AGGREGATE>StayPersons__c</AGGREGATE>'
    				+'<HIDDENFIELD>refTypeOfRooms__r.ShopInfoRef__r.Name</HIDDENFIELD>'
    				+'<COLNUMSTYLE>EntryTime__c:text-align: right; font-size: 14px</COLNUMSTYLE>'
    				+'<COLNUMSIZE>Rroom__r.Seq__c:46px,Field353__c:36px</COLNUMSIZE>'
    				+'<COLNUMTYPE>Rroom__r.Seq__c:number,Rroom__r.Rnumber__c:number,EntryTime__c:date</COLNUMTYPE>'
    				+'<COLNUMEDIT>Field4__c,StayPersons__c,Mans__c,Femails__c</COLNUMEDIT>'
    				+'<FOODSUMMARY>'
					+'<COLNUMSIZE><MIDDAYICON>60</MIDDAYICON><PRODCUTNMAEM>240</PRODCUTNMAEM><PRODUCTSUMMY>60</PRODUCTSUMMY></COLNUMSIZE>'
					+'<COLNUMSTYLE><MIDDAYICON>font-size: 14px;</MIDDAYICON><PRODCUTNMAEM>font-size: 14px;</PRODCUTNMAEM><PRODUCTSUMMY>text-align: right; font-size: 14px</PRODUCTSUMMY></COLNUMSTYLE>'
					+'</FOODSUMMARY>'
					+'<HISTORY><BGCOLOR>TRUE</BGCOLOR><COLOR><VALUE>green</VALUE><FREQUENCY>3</FREQUENCY><FIELDS>Mans__c</FIELDS>'
					+'</COLOR><COLOR><VALUE>blue</VALUE><FREQUENCY>4</FREQUENCY><FIELDS>Mans__c</FIELDS></COLOR><COLOR><VALUE>black</VALUE><FREQUENCY>5</FREQUENCY><FIELDS>Mans__c</FIELDS></COLOR>'
					+'<COLOR><VALUE>red</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Femails__c,Childs__c</FIELDS></COLOR><COLOR><VALUE>green</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Field4__c</FIELDS></COLOR>'
					+'<COLOR><VALUE>blue</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Field3__c,StayPersons__c</FIELDS></COLOR><COLOR><VALUE>blue</VALUE><FREQUENCY></FREQUENCY><FIELDS>Rroom__r.Name,Relcontact__r.ApplicantName__c</FIELDS></COLOR>'
					+'<FOODSUMMARYCOLOR DETLEISSHOW="TRUE">'
					+'<VALUE>chartreuse</VALUE>'
					+'</FOODSUMMARYCOLOR>'
					+'</HISTORY>' 
    				+'</shop>'
    				+'<PDFOUTPUT>'
    				+'<PAGEWIDTH>500px</PAGEWIDTH>'
    				+'<COLNUMSIZE>Field291__c:100px,EntryTime__c:100px,ChildFA__c:100px,Childs__c:100px,Name:100px</COLNUMSIZE>'
    				+'<COLNUMSIZE><MIDDAYICON>60</MIDDAYICON><PRODCUTNMAEM>240</PRODCUTNMAEM><PRODUCTSUMMY>60</PRODUCTSUMMY></COLNUMSIZE>'
					+'<COLNUMSTYLE><MIDDAYICON>font-size: 14px;</MIDDAYICON><PRODCUTNMAEM>font-size: 14px;</PRODCUTNMAEM><PRODUCTSUMMY>text-align: right; font-size: 14px</PRODUCTSUMMY></COLNUMSTYLE>'
					+'<PAGEWIDTHFLG>TRUE</PAGEWIDTHFLG>'
					+'<WATCHBATCHTIME>2</WATCHBATCHTIME>'
					+'</PDFOUTPUT></root>');	
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
    	typeOfRoom[0].MaxRooms__c = 0;
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
    	K_ScheduleReport rp = new K_ScheduleReport();
    	String queryDt = DateTime.now().format('yyyy/MM/dd');
    	String termDays = '4';
    	String[] strArr = new String[]{'','','','',''};
    	K_ScheduleReport.getReportViewInfo('02', queryDt, termDays, 'false', strArr,'false');
    	
        K_ScheduleCookingHelper schedult = new K_ScheduleCookingHelper( Date.today(),'02');
        schedult.queryEstLead();
    }
    static testMethod void myUnitTest8() {
    	
    	CommDefine__c def = TestCommon.createCommDefine();
    	def.ReportKScheduleWhere__c = '会席,お膳,単品,仕出し,朝食:1';
    	update def;
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'ScheduleReportFieldsXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf('<root><SHOP>'
+'	<SHOPCODE></SHOPCODE>'
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
    	typeOfRoom[0].MaxRooms__c = 0;
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
    	K_ScheduleReport rp = new K_ScheduleReport();
    	String queryDt = DateTime.now().format('yyyy/MM/dd');
    	String termDays = '5';
    	String[] strArr = new String[]{'','','','',''};
    	K_ScheduleReport.getReportViewInfo('', queryDt, termDays, 'true', strArr,'true');
    	
    	Map<String,Map<String, K_ScheduleReport.ReportDetail>> perSumaryMap = new Map<String,Map<String, K_ScheduleReport.ReportDetail>>();
    	String json = JSON.serialize(perSumaryMap);
    	String[] strArr1 = new String[]{json, '', '', '', ''};
    	K_ScheduleReport.getReportViewInfo('', queryDt, termDays, 'false', strArr1,'true');
    	
        K_ScheduleCookingHelper schedult = new K_ScheduleCookingHelper( Date.today(),'02');
        schedult.queryEstLead();
    }
    static testMethod void myUnitTest9() {
    	
    	CommDefine__c def = TestCommon.createCommDefine();
    	def.ReportKScheduleWhere__c = '会席,お膳,単品,仕出し,朝食:1';
    	update def;
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'ScheduleReportFieldsXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf('<root><SHOP>'
+'	<SHOPCODE></SHOPCODE>'
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
    	typeOfRoom[0].MaxRooms__c = 0;
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
    	K_ScheduleReport rp = new K_ScheduleReport();
    	String queryDt = DateTime.now().format('yyyy/MM/dd');
    	String termDays = '5';
    	String[] strArr = new String[]{'','','','',''};
    	K_ScheduleReport.getReportViewInfo('', queryDt, termDays, 'true', strArr,'true');
    	
    	Map<String,Map<String, K_ScheduleReport.ReportDetail>> perSumaryMap = new Map<String,Map<String, K_ScheduleReport.ReportDetail>>();
    	String json = JSON.serialize(perSumaryMap);
    	String[] strArr1 = new String[]{json, '', '', '', ''};
    	K_ScheduleReport.getReportViewInfo('', queryDt, termDays, 'false', strArr1,'true');
    	
        K_ScheduleCookingHelper schedult = new K_ScheduleCookingHelper( Date.today(),'02');
        schedult.queryEstLead();
    }
    static testMethod void canvasTest() {
    	CommDefine__c def = TestCommon.createCommDefine();
    	def.ReportKScheduleWhere__c = '会席,お膳,単品,仕出し,朝食:1';
    	update def;
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'ScheduleReportFieldsXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf('<root><shop><SHOPCODE></SHOPCODE><HANDWRITE><REAPPEAR>true</REAPPEAR></HANDWRITE><FIELDS SHOWFOOD="true">Morningtime__c:朝食時間,Relcontact__r.Name:お客様,EntryTime__c:到着日</FIELDS>'
    				+'<LINKFIELD>Name:Id</LINKFIELD><AGGREGATE>StayPersons__c</AGGREGATE>'
    				+'<HIDDENFIELD>refTypeOfRooms__r.ShopInfoRef__r.Name</HIDDENFIELD>'
    				+'<COLNUMSIZE>Rroom__r.Seq__c:46px,Field353__c:36px</COLNUMSIZE>'
    				+'<COLNUMTYPE>Rroom__r.Seq__c:number,Rroom__r.Rnumber__c:number,EntryTime__c:date,</COLNUMTYPE>'
    				+'<COLNUMEDIT>Field4__c,StayPersons__c,Mans__c,Femails__c</COLNUMEDIT>'
    				+'<FOODSUMMARY>'
					+'<COLNUMSIZE><MIDDAYICON>60</MIDDAYICON><PRODCUTNMAEM>240</PRODCUTNMAEM><PRODUCTSUMMY>60</PRODUCTSUMMY></COLNUMSIZE>'
					+'<COLNUMSTYLE><MIDDAYICON>font-size: 14px;</MIDDAYICON><PRODCUTNMAEM>font-size: 14px;</PRODCUTNMAEM><PRODUCTSUMMY>text-align: right; font-size: 14px</PRODUCTSUMMY></COLNUMSTYLE>'
					+'</FOODSUMMARY>'
					+'<HISTORY><BGCOLOR>TRUE</BGCOLOR><COLOR><VALUE>green</VALUE><FREQUENCY>3</FREQUENCY><FIELDS>Mans__c</FIELDS>'
					+'</COLOR><COLOR><VALUE>blue</VALUE><FREQUENCY>4</FREQUENCY><FIELDS>Mans__c</FIELDS></COLOR><COLOR><VALUE>black</VALUE><FREQUENCY>5</FREQUENCY><FIELDS>Mans__c</FIELDS></COLOR>'
					+'<COLOR><VALUE>red</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Femails__c,Childs__c</FIELDS></COLOR><COLOR><VALUE>green</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Field4__c</FIELDS></COLOR>'
					+'<COLOR><VALUE>blue</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Field3__c,StayPersons__c</FIELDS></COLOR><COLOR><VALUE>blue</VALUE><FREQUENCY></FREQUENCY><FIELDS>Rroom__r.Name,Relcontact__r.ApplicantName__c</FIELDS></COLOR>'
					+'<FOODSUMMARYCOLOR DETLEISSHOW="TRUE">'
					+'<VALUE>chartreuse</VALUE>'
					+'</FOODSUMMARYCOLOR>'
					+'</HISTORY>' 
    				+'</shop>'
    				+'<PDFOUTPUT>'
    				+'<PAGEWIDTH>500px</PAGEWIDTH>'
    				+'<COLNUMSIZE>Field291__c:100px,EntryTime__c:100px,ChildFA__c:100px,Childs__c:100px,Name:100px</COLNUMSIZE>'
    				+'<COLNUMSIZE><MIDDAYICON>60</MIDDAYICON><PRODCUTNMAEM>240</PRODCUTNMAEM><PRODUCTSUMMY>60</PRODUCTSUMMY></COLNUMSIZE>'
					+'<COLNUMSTYLE><MIDDAYICON>font-size: 14px;</MIDDAYICON><PRODCUTNMAEM>font-size: 14px;</PRODCUTNMAEM><PRODUCTSUMMY>text-align: right; font-size: 14px</PRODUCTSUMMY></COLNUMSTYLE>'
					+'<PAGEWIDTHFLG>TRUE</PAGEWIDTHFLG>'
					+'<WATCHBATCHTIME>2</WATCHBATCHTIME>'
					+'</PDFOUTPUT></root>');	
    	insert item;
    	Test.startTest();
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	Test.stopTest();
   		Lead__c leadInfo2 = TestCommon.createLead();
   		
    	leadInfo2.Field298__c = 'チェックイン完';
    	List<Lead__c> updLeads = new List<Lead__c>{leadInfo2};
    	update updLeads;
		
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        System.assertEquals(productLst.size(), 1);
    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	K_ScheduleReport rp = new K_ScheduleReport();
    	String queryDt = DateTime.now().format('yyyy/MM/dd');
    	String termDays = '4';
    	String[] strArr = new String[]{'','','','',''};
    	K_ScheduleReport.getReportViewInfo('', queryDt, termDays, 'false', strArr,'true');
    	list<String> imgkeylst = new list<String>{'img'};
    	K_ScheduleReport.getImg(imgkeylst);
    	K_ScheduleReport.saveImg('img', 'img', '[]', '50');
    	
        K_ScheduleCookingHelper schedult = new K_ScheduleCookingHelper( Date.today(),'');
        schedult.queryEstLead();
    }
    static testMethod void myUnitTest10() {
    	Test.startTest();
    	CommDefine__c def = TestCommon.createCommDefine();
    	def.ReportKScheduleWhere__c = '会席,お膳,単品,仕出し,朝食:1';
    	update def;
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'ScheduleReportFieldsXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf('<root><shop><SHOPCODE>02</SHOPCODE><FIELDS SHOWFOOD="true" SHOWGUEST="true" SHOWGUESTPOS ="2">Morningtime__c:朝食時間,Relcontact__r.Name:お客様,EntryTime__c:到着日</FIELDS>'
    				+'<LINKFIELD>Name:Id</LINKFIELD><AGGREGATE>StayPersons__c</AGGREGATE>'
    				+'<HIDDENFIELD>refTypeOfRooms__r.ShopInfoRef__r.Name</HIDDENFIELD>'
    				+'<COLNUMSTYLE>EntryTime__c:text-align: right; font-size: 14px</COLNUMSTYLE>'
    				+'<COLNUMSIZE>Rroom__r.Seq__c:46px,Field353__c:36px</COLNUMSIZE>'
    				+'<COLNUMTYPE>Rroom__r.Seq__c:number,Rroom__r.Rnumber__c:number,EntryTime__c:date</COLNUMTYPE>'
    				+'<COLNUMEDIT>Field4__c,StayPersons__c,Mans__c,Femails__c</COLNUMEDIT>'
    				+'<FOODSUMMARY>'
					+'<COLNUMSIZE><MIDDAYICON>60</MIDDAYICON><PRODCUTNMAEM>240</PRODCUTNMAEM><PRODUCTSUMMY>60</PRODUCTSUMMY></COLNUMSIZE>'
					+'<COLNUMSTYLE><MIDDAYICON>font-size: 14px;</MIDDAYICON><PRODCUTNMAEM>font-size: 14px;</PRODCUTNMAEM><PRODUCTSUMMY>text-align: right; font-size: 14px</PRODUCTSUMMY></COLNUMSTYLE>'
					+'</FOODSUMMARY>'
					+'<HISTORY><BGCOLOR>TRUE</BGCOLOR><COLOR><VALUE>green</VALUE><FREQUENCY>3</FREQUENCY><FIELDS>Mans__c</FIELDS>'
					+'</COLOR><COLOR><VALUE>blue</VALUE><FREQUENCY>4</FREQUENCY><FIELDS>Mans__c</FIELDS></COLOR><COLOR><VALUE>black</VALUE><FREQUENCY>5</FREQUENCY><FIELDS>Mans__c</FIELDS></COLOR>'
					+'<COLOR><VALUE>red</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Femails__c,Childs__c</FIELDS></COLOR><COLOR><VALUE>green</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Field4__c</FIELDS></COLOR>'
					+'<COLOR><VALUE>blue</VALUE><FREQUENCY>2</FREQUENCY><FIELDS>Field3__c,StayPersons__c</FIELDS></COLOR><COLOR><VALUE>blue</VALUE><FREQUENCY></FREQUENCY><FIELDS>Rroom__r.Name,Relcontact__r.ApplicantName__c</FIELDS></COLOR>'
					+'<FOODSUMMARYCOLOR DETLEISSHOW="TRUE">'
					+'<VALUE>chartreuse</VALUE>'
					+'</FOODSUMMARYCOLOR>'
					+'</HISTORY>' 
    				+'</shop>'
    				+'<PDFOUTPUT>'
    				+'<PAGEWIDTH>500px</PAGEWIDTH>'
    				+'<COLNUMSIZE>Field291__c:100px,EntryTime__c:100px,ChildFA__c:100px,Childs__c:100px,Name:100px</COLNUMSIZE>'
    				+'<COLNUMSIZE><MIDDAYICON>60</MIDDAYICON><PRODCUTNMAEM>240</PRODCUTNMAEM><PRODUCTSUMMY>60</PRODUCTSUMMY></COLNUMSIZE>'
					+'<COLNUMSTYLE><MIDDAYICON>font-size: 14px;</MIDDAYICON><PRODCUTNMAEM>font-size: 14px;</PRODCUTNMAEM><PRODUCTSUMMY>text-align: right; font-size: 14px</PRODUCTSUMMY></COLNUMSTYLE>'
					+'<PAGEWIDTHFLG>TRUE</PAGEWIDTHFLG>'
					+'<WATCHBATCHTIME>2</WATCHBATCHTIME>'
					+'</PDFOUTPUT></root>');	
    	insert item;
    	
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
    	typeOfRoom[0].MaxRooms__c = 0;
    	update typeOfRoom;
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	leadInfo.Field298__c = 'チェックイン完';
    	leadInfo.refTypeOfRooms__c = typeOfRoom[0].Id;   	   
    	
    	Test.stopTest(); 
		Room__c rooms = TestCommon.createRooms(typeOfRoom[0].Id);
    	rooms.UseOfRoom__c = '客室';
    	rooms.ShopInfoRef__c = shopInfo.Id;
    	update rooms; 
    	

    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 2015/12/01 Assert BEGIN
        System.assertEquals(productLst.size(), 1);
        // 2015/12/01 Assert END
        CommDefine__c conf = TestCommon.createCommDefine();
    	conf.ReportKScheduleWhere__c = '朝食:1,会席';
		List<OP__c> opItem = TestCommon.createOP(3);
  	
		Plan__c planItem = TestCommon.createPlan();
    	planItem.AccountA__c = productLst[0].Id;
    	update planItem;
    	PlanDetail__c detail = new PlanDetail__c(
        	PlanRef__c = planItem.Id,
        	AccountMasterRef__c = productLst[0].Id
        );
        insert detail;
        RsvAccount__c rsv = TestCommon.createRsvAccount();
    	K_ScheduleReport rp = new K_ScheduleReport();
    	String queryDt = DateTime.now().format('yyyy/MM/dd');
    	String termDays = '4';
    	String[] strArr = new String[]{'','','','',''};
    	K_ScheduleReport.getReportViewInfo('02', queryDt, termDays, 'false', strArr,'true');
    }
}