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
@isTest(SeeAllData=true)
private class FileUploadImpForRackRateTableTest {

	
	static testMethod void RaceRate_UPD_Case1() {
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
		Test.startTest();
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
		
		
	}
	
	// 支店なし、ファイルアップロード処理を行う
	static testmethod void RaceRate_NoShop_UPD_Case2() {

		CreateBaseInfo();

		String csvBody = 	'店舗名,ラックレート名,人数,部屋タイプ名,金額\n';
		
		// 部屋タイプ情報を作成する
		TypeOfRooms__c TypeOfRooms1 = TestCommon.createTypeOfRoom();
		TypeOfRooms__c TypeOfRooms2 = TestCommon.createTypeOfRoom();
		TypeOfRooms__c TypeOfRooms3 = TestCommon.createTypeOfRoom();
		// CSVアップロード内容設定
		csvBody += 	'' + ',' + 'Tier1' + ',' + '3' + ',' + TypeOfRooms1.Name+ ',' + '10000\n'+
					'' + ',' + 'Tier1' + ',' + '2' + ',' + TypeOfRooms1.Name+ ',' + '11000\n'+
					'' + ',' + 'Tier1' + ',' + '1' + ',' + TypeOfRooms1.Name+ ',' + '12000\n'+
					'' + ',' + 'Tier2' + ',' + '3' + ',' + TypeOfRooms2.Name+ ',' + '13000\n'+
					'' + ',' + 'Tier2' + ',' + '2' + ',' + TypeOfRooms2.Name+ ',' + '14000\n'+
					'' + ',' + 'Tier2' + ',' + '1' + ',' + TypeOfRooms2.Name+ ',' + '15000\n'+
					'' + ',' + 'Tier3' + ',' + '3' + ',' + TypeOfRooms3.Name+ ',' + '16000\n'+
					'' + ',' + 'Tier3' + ',' + '2' + ',' + TypeOfRooms3.Name+ ',' + '17000\n'+
					'' + ',' + 'Tier3' + ',' + '1' + ',' + TypeOfRooms3.Name+ ',' + '18000\n';
		Test.startTest();
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
	}
	
	/**
	* CSV関連チェックテスト
	* ファイルは非存在する場合
	**/
	static testMethod void RaceRate_UPD_Case2() {
		CreateBaseInfo();
		// ファイルアップロード処理
		FileUploadImpForRackRateTable fileHandel = new FileUploadImpForRackRateTable();
		fileHandel.filehand.setFileName('TestUploadFile');
		fileHandel.processCsvFile();
		System.assert(fileHandel.filehand.result.isHasErrMsg,fileHandel.filehand.result);
	}
	/**
	* Header以外の情報はない場合
	**/
	static testMethod void RaceRate_UPD_Case3() {
		CreateBaseInfo();
		String csvBody = 	'店舗名,ラックレート名,人数,部屋タイプ名,金額\n';
		// ファイルアップロード処理
		FileUploadImpForRackRateTable fileHandel = new FileUploadImpForRackRateTable();
		fileHandel.filehand.setFileName('TestUploadFile');
		fileHandel.filehand.setFileBody(Blob.valueOf(csvBody));
		fileHandel.processCsvFile();
		System.assert(!fileHandel.filehand.result.isHasErrMsg,fileHandel.filehand.result);
		System.assert(fileHandel.filehand.result.isHasInfoMsg,fileHandel.filehand.result);
	}
	/**
	* 項目数設定不正
	**/
	static testMethod void RaceRate_UPD_Case4() {
		CreateBaseInfo();
		String csvBody = 	'店舗名,ラックレート名,人数,部屋タイプ名,金額\n'+
							'1,2,3\n';
		// ファイルアップロード処理
		FileUploadImpForRackRateTable fileHandel = new FileUploadImpForRackRateTable();
		fileHandel.filehand.setFileName('TestUploadFile');
		fileHandel.filehand.setFileBody(Blob.valueOf(csvBody));
		fileHandel.processCsvFile();
		System.assert(fileHandel.filehand.result.isHasErrMsg,fileHandel.filehand.result);
		System.assert(!fileHandel.filehand.result.isHasInfoMsg,fileHandel.filehand.result);
	}
	/**
	* 項目有効性チェック
	**/
	static testMethod void RaceRate_UPD_Case5() {
		CreateBaseInfo();
		String csvBody = 	'店舗名,ラックレート名,人数,部屋タイプ名,金額\n'+
							'1,,3,4,5,6\n' +
							'1,2,,4,5,6\n' +
							'1,2,3,,5,6\n' +
							'1,2,3,4,,6\n' +
							'1,2,3,4,5,\n' +
							'1,2,3,2013/11/12,2014/12/01,xx\n';
		// ファイルアップロード処理
		FileUploadImpForRackRateTable fileHandel = new FileUploadImpForRackRateTable();
		fileHandel.filehand.setFileName('TestUploadFile');
		fileHandel.filehand.setFileBody(Blob.valueOf(csvBody));
		fileHandel.processCsvFile();
		System.assert(fileHandel.filehand.result.isHasErrMsg,fileHandel.filehand.result);
		System.assert(!fileHandel.filehand.result.isHasInfoMsg,fileHandel.filehand.result);
	}
	
	/**
	* 旅行会社、支店、部屋タイプファイル内重複設定チエック
	**/
	static testMethod void RaceRate_UPD_Case6() {
		CreateBaseInfo();
		String csvBody = 	'店舗名,ラックレート名,人数,部屋タイプ名,金額\n'+
							'1,1,1,1,6\n' +
							'1,1,1,1,7\n';
		// ファイルアップロード処理
		FileUploadImpForRackRateTable fileHandel = new FileUploadImpForRackRateTable();
		fileHandel.filehand.setFileName('TestUploadFile');
		fileHandel.filehand.setFileBody(Blob.valueOf(csvBody));
		fileHandel.processCsvFile();
		System.assert(fileHandel.filehand.result.isHasErrMsg,fileHandel.filehand.result);
		System.assert(!fileHandel.filehand.result.isHasInfoMsg,fileHandel.filehand.result);
	}
	/**
	* 設定の支店、部屋タイプ非存在する場合
	*/
	static testMethod void RaceRate_UPD_Case7() {
		CreateBaseInfo();
		String csvBody = 	'店舗名,ラックレート名,人数,部屋タイプ名,金額\n'+
							'1,1,1,1,6\n' ;
		// ファイルアップロード処理
		FileUploadImpForRackRateTable fileHandel = new FileUploadImpForRackRateTable();
		fileHandel.filehand.setFileName('TestUploadFile');
		fileHandel.filehand.setFileBody(Blob.valueOf(csvBody));
		fileHandel.processCsvFile();
		System.assert(fileHandel.filehand.result.isHasErrMsg,fileHandel.filehand.result);
		System.assert(!fileHandel.filehand.result.isHasInfoMsg,fileHandel.filehand.result);
	}
	// 2020/05/30 BY zyz BEGIN
	static testMethod void RaceRate_PLAN_Case1() {
		CreateBaseInfo();
		String csvBody = 	'店舗名,ラックレート名,ベースプラン名,部屋タイプ名,販売状態\n';
		
		// 支店情報を作成する
		ShopInformation__c shop1 = TestCommon.createShopInfo();
		ShopInformation__c shop2 = TestCommon.createShopInfo();
		ShopInformation__c shop3 = TestCommon.createShopInfo();	
		// 部屋タイプ情報を作成する
		List<TypeOfRooms__c> TypeOfRooms1 = TestCommon.createTypeOfRoomByShop(shop1.Id, 3);
		Plan__c plan = TestCommon.createPlan();
		plan.BasePlanFlg__c = true;
		plan.ShopInfoRef__c = shop1.Id;
		update plan;
		// CSVアップロード内容設定
		csvBody += 	shop1.Name + ',' + 'Tier1' + ',' + plan.Name + ',' + TypeOfRooms1[0].Name+ ',' + '止\n'+
					shop1.Name + ',' + 'Tier2' + ',' + plan.Name + ',' + TypeOfRooms1[0].Name+ ',' + '止\n'+
					shop1.Name + ',' + 'Tier3' + ',' + plan.Name + ',' + TypeOfRooms1[0].Name+ ',' + '止\n';
		Test.startTest();
		// ファイルアップロード処理
		FileUploadImpForRackRateTable fileHandel = new FileUploadImpForRackRateTable();
		fileHandel.filehand.setFileName('TestUploadFile');
		fileHandel.filehand.setFileBody(Blob.valueOf(csvBody));
		fileHandel.processCsvFilePlan();
		System.assert(!fileHandel.filehand.result.isHasErrMsg,fileHandel.filehand.result);
		// 汎用マスタのリアルAGT情報を確認する
		// 旅行会社１関連データは３件、部屋タイプは
		String querySql = CommSqlUtils.generateQueryString('RackRateTable__c');
		List<RackRateTable__c> totalNums = DataBase.query(querySql);
		System.assertEquals(totalNums.size(), 3);
		Test.stopTest();
		
		
	}
	// 2020/05/30 BY zyz END
	
	private static void CreateBaseInfo () {
		delete [select id from RackRateTable__c];
		delete [select id from TypeOfRooms__c];
		delete [select id from ShopInformation__c];
	}
}