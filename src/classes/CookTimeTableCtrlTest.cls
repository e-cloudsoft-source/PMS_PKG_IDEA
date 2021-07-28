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
private class CookTimeTableCtrlTest {
	static testMethod void myunittest001(){
		CommDefine__c def = TestCommon.createCommDefine();
		createOrderConfigXml();
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
		/*
    	Lead__c leadInfo = TestCommon.createLead();
    	leadInfo.Field298__c = 'チェックイン完';
    	leadInfo.refTypeOfRooms__c = typeOfRoom[0].Id;     	   
    	*/
    	Lead__c leadInfo2 = TestCommon.createLead();
    	leadInfo2.refTypeOfRooms__c = typeOfRoom[0].Id;
    	leadInfo2.Rroom__c = null;
    	List<Lead__c> updLeads = new List<Lead__c>{leadInfo2};  
    	update updLeads;	 		
		Test.startTest();
		Room__c rooms = TestCommon.createRooms(typeOfRoom[0].Id);
    	rooms.UseOfRoom__c = '客室';
    	rooms.ShopInfoRef__c = shopInfo.Id;
    	update rooms; 
		Test.stopTest(); 
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 2015/12/01 Assert BEGIN
        createFoodDetail(productLst[0].id);
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
        List<Object> objStr = new List<Object>{new Map<String,Object>{'status' =>'','begTm'=>'08:01'}};
        AccountAcount__c acc =TestCommon.createAccountAcount(rsv.Id,leadInfo2.Id);
        Tran1__c tran1 = new Tran1__c(
    		Field7__c = productLst[0].Id,
    		Field1__c = acc.Id,
    		RelAccount__c = rsv.Id,
    		CookInfo__c = JSON.serialize(objStr)
    	);
    	
    	insert tran1;  	 
    	
    	// 見積明細を作成する
    	BookingEstimateItem__c items = TestCommon.createBookEstItem(leadInfo2, productLst[0]);
    	items.OP__c = opItem[0].Id;
    	items.ActionType__c= '朝食';
		items.useDate__c = system.today();
    	items.CookInfo__c = JSON.serialize(objStr);
    	update items;
		/*
    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo, productLst[0]);
		*/
        // TO DO: implement unit test
        Map<String,Object> resultMap = new Map<String,Object>{'spcd' => '02','orderId' => tran1.id ,'cookId'=>'','begTm' =>'19:00','done' => true};
        Object res = CookTimeTableCtrl.cookRemoteData('queryCookData',JSON.serialize(resultMap));
        resultMap = new Map<String,Object>{'spcd' => '02','orderId' => tran1.id ,'cookId'=>'','begTm' =>'19:00','done' => true,'busType' =>'15:00~24:00~17:30'};
        res = CookTimeTableCtrl.cookRemoteData('queryCookData',JSON.serialize(resultMap));
	}
	static testMethod void myunittest002(){
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
    	Test.startTest();
		
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
		Test.stopTest(); 
        RsvAccount__c rsv = TestCommon.createRsvAccount();
        List<Object> objStr = new List<Object>{new Map<String,Object>{'status' =>'','begTm'=>'08:01'}};
        AccountAcount__c acc =TestCommon.createAccountAcount(rsv.Id,leadInfo2.Id);
        Tran1__c tran1 = new Tran1__c(
    		Field7__c = productLst[0].Id,
    		Field1__c = acc.Id,
    		RelAccount__c = rsv.Id,
    		CookInfo__c = JSON.serialize(objStr)
    	);
    	
    	insert tran1;  	 
    	
    	// 見積明細を作成する
    	BookingEstimateItem__c items = TestCommon.createBookEstItem(leadInfo2, productLst[0]);
    	items.OP__c = opItem[0].Id;
    	items.ActionType__c= '朝食';
    	items.CookInfo__c = JSON.serialize(objStr);
    	update items;
    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo, productLst[0]);
        // TO DO: implement unit test
		createOrderConfigXml();
		CookTimeTableCtrl ctrl = new CookTimeTableCtrl();
		ctrl.curMode = '60';
		ctrl.init();
        Map<String,Object> resultMap = new Map<String,Object>{'spcd' => '02','orderId' => tran1.id ,'cookId'=>'','begTm' =>'19:00','done' => true,'orderids' => new List<String>{tran1.id},'oids' => new String[]{':1'},'name'=>'seq'};
        Object res = CookTimeTableCtrl.cookRemoteData('cookDoneData',JSON.serialize(resultMap));
		res = CookTimeTableCtrl.cookRemoteData('cookTimeData',JSON.serialize(resultMap));
		resultMap.put('orderids', new List<String>{leadInfo.id});
		res = CookTimeTableCtrl.cookRemoteData('leadCookDone',JSON.serialize(resultMap));
	}
	static testMethod void myunittest003(){
		CommDefine__c def = TestCommon.createCommDefine();
    	def.ReportKScheduleWhere__c = '会席,お膳,単品,仕出し,朝食:1';
    	update def;
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
		CookTimeTableCtrl ctrl = new CookTimeTableCtrl();
        ctrl.init();
        ctrl.curType = '10:00~20:00';
        ctrl.chgType();
        ctrl.chgMode();
		ctrl.refreshBranchShopInfo();
		// 商品情報を作成する
		List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
		List<OP__c> opItem = TestCommon.createOP(3);
        // 見積明細を作成する
    	BookingEstimateItem__c items = TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	items.OP__c = opItem[0].Id;
    	items.ActionType__c= '朝食';
		items.useDate__c = system.today();
    	update items;
		TestCommon.createOrderConfigXml();
		ctrl.chgType();
		Map<String,Object> resultMap = new Map<String,Object>{'spcd' => '02','orderId'=>items.id,'cookId'=>productLst[0].id,'begTm' =>'19:00','done' => true,'oids' => new String[]{''},'sumflg' => false};
		Object res = CookTimeTableCtrl.cookRemoteData('cookChgData',JSON.serialize(resultMap));
	}
	/*
    static testMethod void myUnitTest() {
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
    	Test.startTest();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
		//createFoodDetail(productLst[0].id);
    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo, productLst[0]);
        // TO DO: implement unit test
        CookTimeTableCtrl ctrl = new CookTimeTableCtrl();
        ctrl.init();
        ctrl.curType = '10:00~20:00';
        ctrl.chgType();
        ctrl.chgMode();
        ctrl.refreshBranchShopInfo();
        List<BookingEstimateItem__c> books = [select id from BookingEstimateItem__c where ParentBookingItemRef__c = null];
        TestCommon.createOrderConfigXml();
        Test.stopTest();
        Map<String,Object> resultMap = new Map<String,Object>{'spcd' => '02','orderId' => books[0].id ,'cookId'=>'','begTm' =>'19:00','done' => true};
        Object res = CookTimeTableCtrl.cookRemoteData('queryCookData',JSON.serialize(resultMap));
        
        res = CookTimeTableCtrl.cookRemoteData('cookDoneData',JSON.serialize(resultMap));
        res = CookTimeTableCtrl.cookRemoteData('cookTimeData',JSON.serialize(resultMap));
    }*/
    public static List<FoodDetail__c> createFoodDetail(String accId) {
    	List<String> statusLst = new List<String>{'先付','お凌ぎ','お椀','向付','八寸'};
    	List<FoodDetail__c> foods = new List<FoodDetail__c>();
    	List<AccountMaster__c> masters = TestCommon.createProductMst(5);
    	for (integer i = 0 ; i < statusLst.size() ; i++) {
    		FoodDetail__c food = new FoodDetail__c();
    		String status = statusLst[i];
    		food.AccountMasterRef__c = accId;
    		food.DetailType__c = status;
    		food.BreakName__c = masters[i].name;
    		food.AccountMasterSubRef__c = masters[i].id;
			foods.add(food);
    	}
    	insert foods;
    	return foods;
    }
    public static document createOrderConfigXml() {
    	String domString = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP><SHOPCODE>01</SHOPCODE><PRINTCONFIG NAME="POS01"><WEBSOCKET>wss</WEBSOCKET><LAYOUT><ORDER>table_reciept2</ORDER><SIMPLEACCOUNT>retail_reciept2</SIMPLEACCOUNT><ACCOUNT>retail_reciept1</ACCOUNT><DOOROPENSEQ>kick_drawer</DOOROPENSEQ></LAYOUT><PRINT>192.168.10.107</PRINT><PRINTPORT>8081</PRINTPORT><STATUS>192.168.10.107</STATUS><STATUSPORT>8081</STATUSPORT><PREMARK>□ </PREMARK><HEADSTAND>true</HEADSTAND><PRINTNO>S01</PRINTNO><HIKAE>(控)</HIKAE></PRINTCONFIG><DEVICECONFIG><DEVICE><LOCAL>192.168.10.XXX</LOCAL><ROOMSEQ>6</ROOMSEQ><PRINTER>POS01</PRINTER><POSNO>001</POSNO></DEVICE></DEVICECONFIG><BUTTONTAB><TABLABEL>●会席料理</TABLABEL><PRODUCT ><NAME>SF)かに丼</NAME><CODE>9127</CODE></PRODUCT><PRODUCT ><NAME>SF)幼児朝食</NAME><CODE>9128</CODE></PRODUCT><PRODUCT ><NAME>会席料理200</NAME><CODE>0140</CODE></PRODUCT><PRODUCT ><NAME>調理長お任せ会席</NAME><CODE>0000000001101</CODE></PRODUCT></BUTTONTAB><FOODSCHEDULE><BUSSINESSTIME>    <TIME>     <LABEL>朝</LABEL>     <BEGIN>6:00</BEGIN>     <END>11:00</END>     <COOKTIME>10:00</COOKTIME>    </TIME>    <TIME>     <LABEL>昼</LABEL>     <BEGIN>11:00</BEGIN>     <END>15:00</END>     <COOKTIME>12:00</COOKTIME>    </TIME>    <TIME>     <LABEL>夕</LABEL>     <BEGIN>15:00</BEGIN>     <END>24:00</END>     <COOKTIME>16:30</COOKTIME>    </TIME>		   </BUSSINESSTIME><COLORINFO>  <COOKBG>white</COOKBG> <COOKPROCBG>white</COOKPROCBG> <COOKDONEBG>gray</COOKDONEBG>  <COOKDETAILBG>darkcyan</COOKDETAILBG></COLORINFO>  <TIMEINFO> 	<MINUTE>10</MINUTE> </TIMEINFO>		 </FOODSCHEDULE></SHOP></root>';
    	Document item = new Document();
    	item.Name = 'OrderProductConfig';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(domString);
    	insert item;
    	return item;
	}
}