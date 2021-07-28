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
private class RackRateUtilsTest {
	
	// Shop Util Test
    static testMethod void myUnitTest() {
		ShopInformation__c shop1 = TestCommon.createShopInfo();
		ShopInformation__c shop2 = TestCommon.createShopInfo();
		List<SelectOption> options = ShopInfoUtil.getBranchShopLst();
		Map<String,ShopInformation__c> shopMap = ShopInfoUtil.getShopInfoMap();
		ShopInformation__c getShop1 = ShopInfoUtil.getShop(shop1.ShopCode__c);
		System.assertEquals(options.size(), 2);
		System.assertEquals(shopMap.size(), 2);

		System.assertEquals(getShop1.Id, shop1.Id, shopMap);
	}
	
	// ラクレート機能テスト
	@isTest(SeeAllData=true)
	static void raceRateCase1() {
		// レックレートデータを作成する
		Test.startTest();
		CommDefine__c def = TestCommon.createCommDefine();
		def.AccountEditAuthCheckFlg__c = false;
		update def;
		CreateBaseInfo();
		String csvBody = 	'店舗名,ラックレート名,人数,部屋タイプ名,金額\n';
		
		// 支店情報を作成する
		ShopInformation__c shop1 = TestCommon.createShopInfo();
		ShopInformation__c shop2 = TestCommon.createShopInfo();
		ShopInformation__c shop3 = TestCommon.createShopInfo();	
		// 部屋タイプ情報を作成する
		List<TypeOfRooms__c> TypeOfRooms1 = TestCommon.createTypeOfRoomByShop(shop1.Id, 3);
		// CSVアップロード内容設定
		csvBody += 	shop1.Name + ',' + 'Tier1' + ',' + '3' + ',' + TypeOfRooms1[0].Name+ ',' + '10000\n'+
					shop1.Name + ',' + 'Tier1' + ',' + '2' + ',' + TypeOfRooms1[1].Name+ ',' + '11000\n'+
					shop1.Name + ',' + 'Tier1' + ',' + '1' + ',' + TypeOfRooms1[2].Name+ ',' + '12000\n'+
					shop2.Name + ',' + 'Tier2' + ',' + '3' + ',' + TypeOfRooms1[0].Name+ ',' + '13000\n'+
					shop2.Name + ',' + 'Tier2' + ',' + '2' + ',' + TypeOfRooms1[1].Name+ ',' + '14000\n'+
					shop2.Name + ',' + 'Tier2' + ',' + '1' + ',' + TypeOfRooms1[2].Name+ ',' + '15000\n'+
					shop3.Name + ',' + 'Tier3' + ',' + '3' + ',' + TypeOfRooms1[0].Name+ ',' + '16000\n'+
					shop3.Name + ',' + 'Tier3' + ',' + '2' + ',' + TypeOfRooms1[1].Name+ ',' + '17000\n'+
					shop3.Name + ',' + 'Tier3' + ',' + '1' + ',' + TypeOfRooms1[2].Name+ ',' + '18000\n';
		
		// ファイルアップロード処理
		FileUploadImpForRackRateTable fileHandel = new FileUploadImpForRackRateTable();
		fileHandel.filehand.setFileName('TestUploadFile');
		fileHandel.filehand.setFileBody(Blob.valueOf(csvBody));
		fileHandel.processCsvFile();
		System.assert(!fileHandel.filehand.result.isHasErrMsg,fileHandel.filehand.result);
		// 汎用マスタのリアルAGT情報を確認する
		// 旅行会社１関連データは３件、部屋タイプは
		String querySql = CommSqlUtils.generateQueryString('RackRateTable__c');
		List<RackRateTable__c> totalNums = DataBase.query(querySql);
		System.assertEquals(totalNums.size(), 9);
		Test.stopTest();
		
		Date testDate = Date.today();
		// 予約の部屋タイプ、人数(1)、Shop1のTierはTier1
		Lead__c newLead = TestCommon.createBookingLead(testDate, TypeOfRooms1[2].Id, 1);
		Set<Id> newLeadIdSet = new Set<Id>();
		newLeadIdSet.add(newLead.Id);
		RackRateUtils rUtils = new RackRateUtils();
		Map<Id,Decimal> rackMap = rUtils.getRoomRateByLead(newLeadIdSet);
		System.assertEquals(rackMap.get(newLead.Id), 12000, rackMap);
	}
	// Data Clear
	private static void CreateBaseInfo () {
		delete [select id from RackRateTable__c];
		delete [select id from TypeOfRooms__c];
		delete [select id from ShopInformation__c];
	}
}