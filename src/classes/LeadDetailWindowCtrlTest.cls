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
private class LeadDetailWindowCtrlTest {

    static testMethod void case01() {
    	createDocument();
    	Test.startTest();
    	// 予約情報を作成する
    	Date curDt = Date.today();
    	List<Lead__c> leads1 = TestCommon.createLead(curDt, 3, 2);
    	TypeOfRooms__c typeRoom1 = TestCommon.createTypeOfRoom(10);
		Room__c roomA = TestCommon.createRooms(typeRoom1.Id);
		ShopInformation__c shop = TestCommon.createShopInfo();
		shop.ShopCode__c = '02';
		upsert shop;
		roomA.ShopInfoRef__c = shop.Id;
		upsert roomA;
		//leads1[0].Rroom__c = roomA.Id;
		//upsert leads1;
		Plan__c plan = TestCommon.createPlan();
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'AppSetupConfigXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(getCsvSetupConfig());
    	insert item;
    	// 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'AppSetupConfigXml'].size(), 1);
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	comDef.RoomIndicatorEstIsCloneFlg__c = true;
    	update comDef;
    	Test.stopTest();
		LeadDetailWindowCtrl lead = new LeadDetailWindowCtrl();
		lead.strLeadId = leads1[0].id;
		
		lead.getInitXmlDefineInfo();
		
		Date startDate = leads1[0].EntryTime__c.date();
		Date endDate = leads1[leads1.size()-1].Departure__c.date();
		// 元泊数 / 新泊数
		Integer orgNights = startDate.daysBetween(endDate);
		lead.leadInfo.nights = orgNights + 1;
		
		lead.chgSaveNightsInfo();
	}
	static testMethod void case02() {
    	createDocument();
    	// 予約情報を作成する
    	Date curDt = Date.today();
    	List<Lead__c> leads1 = TestCommon.createLead(curDt, 3, 2);
    	leads1[0].LeadIndexSubId__c = null;
    	upsert leads1;
    	TypeOfRooms__c typeRoom1 = TestCommon.createTypeOfRoom(10);
		Room__c roomA = TestCommon.createRooms(typeRoom1.Id);
		ShopInformation__c shop = TestCommon.createShopInfo();
		shop.ShopCode__c = '02';
		upsert shop;
		Test.startTest();
		roomA.ShopInfoRef__c = shop.Id;
		upsert roomA;
		Plan__c plan = TestCommon.createPlan();
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'AppSetupConfigXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(getCsvSetupConfig());
    	insert item;
    	// 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'AppSetupConfigXml'].size(), 1);
    	
		LeadDetailWindowCtrl lead = new LeadDetailWindowCtrl();
		lead.strLeadId = leads1[0].id;
		
		lead.getInitXmlDefineInfo();
		
		Date startDate = leads1[0].EntryTime__c.date();
		Date endDate = leads1[leads1.size()-1].Departure__c.date();
		// 元泊数 / 新泊数
		Integer orgNights = startDate.daysBetween(endDate);
		lead.leadInfo.nights = orgNights + 1;
		
		lead.chgSaveNightsInfo();
		Test.stopTest();
	}
	static testMethod void case03() {
    	createDocument();
    	// 予約情報を作成する
    	Date curDt = Date.today();
    	List<Lead__c> leads1 = TestCommon.createLead(curDt, 3, 2);
    	TypeOfRooms__c typeRoom1 = TestCommon.createTypeOfRoom(10);
		Room__c roomA = TestCommon.createRooms(typeRoom1.Id);
		ShopInformation__c shop = TestCommon.createShopInfo();
		shop.ShopCode__c = '02';
		upsert shop;
		roomA.ShopInfoRef__c = shop.Id;
		upsert roomA;
		Test.startTest();
		//leads1[0].Rroom__c = roomA.Id;
		//upsert leads1;
		Plan__c plan = TestCommon.createPlan();
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'AppSetupConfigXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(getCsvSetupConfig());
    	insert item;
    	// 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'AppSetupConfigXml'].size(), 1);
    	Test.stopTest();
    	
		LeadDetailWindowCtrl lead = new LeadDetailWindowCtrl();
		lead.strLeadId = leads1[0].id;
		
		lead.getInitXmlDefineInfo();
		
		Date startDate = leads1[0].EntryTime__c.date();
		Date endDate = leads1[leads1.size()-1].Departure__c.date();
		// 元泊数 / 新泊数
		Integer orgNights = startDate.daysBetween(endDate);
		lead.leadInfo.nights = orgNights - 1;
		lead.isGroupFlg = true;
		for(Lead__c l : leads1){
			lead.groupLeadIds += l.Id + ',';
		}
		
		lead.chgSaveNightsInfo();
		lead.leadCancel();
		lead.checkInByRoom();
		lead.checkOutByRoom();
		LeadDetailWindowCtrl.getRoomInfoExt(roomA.Id, leads1[0].Id,'Id,Name,Field298__c,EntryTime__c,Rroom__r.Name, Relcontact__r.Id, Relcontact__r.Name, Field310__r.Name, LeadIndexRef__r.Name','id,name');
	}
	static testMethod void case04() {
    	createDocument();
    	Test.startTest();
    	// 予約情報を作成する
    	Date curDt = Date.today();
    	List<Lead__c> leads1 = TestCommon.createLead(curDt, 3, 2);
    	TypeOfRooms__c typeRoom1 = TestCommon.createTypeOfRoom(10);
		Room__c roomA = TestCommon.createRooms(typeRoom1.Id);
		ShopInformation__c shop = TestCommon.createShopInfo();
		shop.ShopCode__c = '02';
		upsert shop;
		roomA.ShopInfoRef__c = shop.Id;
		upsert roomA;
		//leads1[0].Rroom__c = roomA.Id;
		//upsert leads1;
		Plan__c plan = TestCommon.createPlan();
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'AppSetupConfigXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(getCsvSetupConfig());
    	insert item;
    	// 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'AppSetupConfigXml'].size(), 1);
    	
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	comDef.RoomIndicatorEstIsCloneFlg__c = true;
    	update comDef;
    	Test.stopTest();
    	
		LeadDetailWindowCtrl lead = new LeadDetailWindowCtrl();
		lead.strLeadId = leads1[0].id;
		
		lead.getInitXmlDefineInfo();
		
		Date startDate = leads1[0].EntryTime__c.date();
		Date endDate = leads1[leads1.size()-1].Departure__c.date();
		// 元泊数 / 新泊数
		Integer orgNights = startDate.daysBetween(endDate);
		lead.leadInfo.nights = orgNights + 1;
    	
		lead.isGroupFlg = true;
		for(Lead__c l : leads1){
			lead.groupLeadIds += l.Id + ',';
		}
		
		lead.chgSaveNightsInfo();
		lead.leadCancel();
		lead.checkInByRoom();
		lead.checkOutByRoom();
	}
	static testMethod void case05() {
    	createDocument();
    	Test.startTest();
    	// 予約情報を作成する
    	Date curDt = Date.today();
    	List<Lead__c> leads1 = TestCommon.createLead(curDt, 3, 2);
    	
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	comDef.RoomIndicatorEstIsCloneFlg__c = true;
    	update comDef;
    	Test.stopTest();
		LeadDetailWindowCtrl lead = new LeadDetailWindowCtrl();
		
		lead.strLeadId = leads1[0].id;
		
		lead.getInitXmlDefineInfo();
		Date startDate = leads1[0].EntryTime__c.date();
		Date endDate = leads1[leads1.size()-1].Departure__c.date();
		// 元泊数 / 新泊数
		Integer orgNights = startDate.daysBetween(endDate);
		lead.leadInfo.nights = orgNights + 5;
		
		lead.isGroupFlg = true;
		
		for(Lead__c l : leads1){
			lead.groupLeadIds += l.Id + ',';
		}
		
		lead.chgSaveNightsInfo();
		lead.leadCancel();
		lead.checkInByRoom();
		lead.checkOutByRoom();
	}
	// 2019/04/15 BY zyz BEGIN
	static testMethod void case06() {
    	createDocument();
    	Test.startTest();
    	// 予約情報を作成する
    	Date curDt = Date.today();
    	List<Lead__c> leads1 = TestCommon.createLead(curDt, 3, 2);
    	
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	comDef.RoomIndicatorEstIsCloneFlg__c = true;
    	comDef.RoomIndicatorGpClMsgIsShow__c = true;
    	comDef.RoomIndicatorIsShowLeadCancelBtn__c = true;
    	comDef.CashRegisterSign__c = true;
    	comDef.AccountRecipteIsShow__c = true;
    	update comDef;
    	leads1[0].Field298__c = CommConst.LEAD_GUEST_ST_OUT;
    	update leads1;
    	Test.stopTest();
		LeadDetailWindowCtrl lead = new LeadDetailWindowCtrl();
		
		lead.strLeadId = leads1[0].id;
		
		lead.getInitXmlDefineInfo();
		Date startDate = leads1[0].EntryTime__c.date();
		Date endDate = leads1[leads1.size()-1].Departure__c.date();
		// 元泊数 / 新泊数
		Integer orgNights = startDate.daysBetween(endDate);
		lead.leadInfo.nights = orgNights + 5;
		
		lead.isGroupFlg = true;
		lead.hadUpdContactFlag = true;
		
		for(Lead__c l : leads1){
			lead.groupLeadIds += l.Id + ',';
		}
		
		lead.chgSaveNightsInfo();
		lead.leadCancel();
		lead.checkInByRoom();
		lead.checkOutByRoom();
		lead.outByRoom();
		lead.returnByRoom();
	}
	// 2019/04/15 BY zyz END

	private static void createDocument(){       
		String documentFileStr = '<?xml version="1.0" encoding="UTF-8"?>'+
		                            '<root><SHOP><VERSION>2.0</VERSION><SHOPCODE></SHOPCODE><DISPLAY><WINDOWWIDTH>650</WINDOWWIDTH><WINDOWHEIGHT>500</WINDOWHEIGHT><LINEHEIGHT>FALSE</LINEHEIGHT></DISPLAY><FIELDS><SECTION TITLE="11" COLNUM="2">Relcontact__c,refTypeOfRooms__c,Name,EntryTime__c,Relcontact__r.Katakana__c,Field4__c,Relcontact__r.KanaName1__c,Departure__c,Relcontact__r.Phone,Relcontact__r.Fax,Relcontact__r.AssistantName,Relcontact__r.Email,Relcontact__r.Field28__c,Relcontact__r.Usage_Count__c,Relcontact__r.Age__c,Relcontact__r.MailingAddress,Relcontact__r.Birthdate,Relcontact__r.Usage_Charge__c,Relcontact__r.gender__c,Relcontact__r.AccountId,Relcontact__r.Account,$_blank_$</SECTION><SECTION TITLE="22" COLNUM="1">,Rroom__c,Field3__c,StayPersons__c,staysNums,bookingRooms,Field310__c,Field315__c,Field2__c,Segment__c,Comment3__c,CouponTypeLst__c,Mans__c,Femails__c,ChildFA__c  ,Childs__c,ChildC__c,ChildD__c,ReservedType__c,OrgCreateDate__c,OrgUpdateDate__c,Rich2__c,Field276__c,Field302__c,X1y1__c,Field305__c,UnitPriceDefKbCal__c,Salesaccount__c,SearchDate__c,VBChecker__c,ContactEmail__c,ContactPhone__c,Field15__c</SECTION></FIELDS><EXUTEFIELD>Relcontact__r.Kana1__c</EXUTEFIELD></SHOP>'+
		                            '<SHOP><SHOPCODE>01</SHOPCODE><FIELDS>CouponTypeLst__c,Mans__c,Femails__c,ChildFA__c,Childs__c,ChildC__c,ChildD__c,ReservedType__c,OrgCreateDate__c,OrgUpdateDate__c,Rich2__c,Comment3__c,Field276__c,Field302__c,X1y1__c</FIELDS><REQUIREDFIELDS>,Mans__c,Femails__cChildFA__c,Childs__c,ChildC__c,ChildD__c</REQUIREDFIELDS></SHOP>'+
		                            '<SHOP><VERSION>1.0</VERSION><SHOPCODE>02</SHOPCODE><COLNUMS>1</COLNUMS><FIELDS>CouponTypeLst__c,Mans__c,Femails__c,ReservedType__c,OrgCreateDate__c,OrgUpdateDate__c,Rich2__c,Comment3__c,ChildFA__c,Childs__c,ChildC__c,ChildD__c,Field276__c,Field302__c,X1y1__c</FIELDS><REQUIREDFIELDS>CouponTypeLst__c,Mans__c,Femails__c,ReservedType__c,OrgCreateDate__c</REQUIREDFIELDS><DISPLAY><WINDOWWIDTH>800</WINDOWWIDTH><WINDOWHEIGHT>600</WINDOWHEIGHT><LINEHEIGHT>FALSE</LINEHEIGHT></DISPLAY></SHOP></root>';
		// ドキュメントを作成する
		Document item = new Document();
		item.Name = 'RoomIndicatorInfoLeadOutputExtendFieldsXml';
		item.DeveloperName = item.Name;
		item.FolderId = UserInfo.getUserId();
		item.Body = Blob.valueOf(documentFileStr);
		getCsvSetupConfig();
		insert item;
	}
	private static String getCsvSetupConfig() {
    	String csv = '<root><shop><SHOPCODE></SHOPCODE><LEADSTATUSCOLOR>'
    				+'<STATUS><KEY>確定</KEY><COLOR>#C6E2FF</COLOR></STATUS>'
    				+'<STATUS><KEY>確認中</KEY><COLOR>#FFEC8B</COLOR></STATUS>'
    				+'<STATUS><KEY>仮予約</KEY><COLOR>#C1FFC1</COLOR></STATUS>'
    				+'<STATUS><KEY>キャンセルまち</KEY><COLOR>#FF83FA</COLOR></STATUS>'
    				+'</LEADSTATUSCOLOR></shop></root>';
    	return csv; 
    }
}