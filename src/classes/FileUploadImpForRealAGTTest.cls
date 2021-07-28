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
private class FileUploadImpForRealAGTTest {

	// 汎用マスタ（リアルAGT情報を作成する
	// CSV アップロード機能テスト
	static testMethod void RealAGT_UPD_Case1() {
		CreateBaseInfo();
		String csvBody = 	'旅行会社名,店舗名,部屋タイプ名,開始日付,終了日付,部屋数\n';
		//+'HIS,東京都千代田区１号店,S1,2014/01/15,2013/05/19,5\n'
		
		// 取引先情報を作成する
		List<Account> accs = CreateTravelAccount(3);
		// 支店情報を作成する
		ShopInformation__c shop1 = TestCommon.createShopInfo();
		ShopInformation__c shop2 = TestCommon.createShopInfo();
		ShopInformation__c shop3 = TestCommon.createShopInfo();
		
		// 部屋タイプ情報を作成する
		List<TypeOfRooms__c> TypeOfRooms1 = TestCommon.createTypeOfRoomByShop(shop1.Id, 3);
		//List<TypeOfRooms__c> TypeOfRooms2 = TestCommon.createTypeOfRoomByShop(shop2.Id, 3);
		//List<TypeOfRooms__c> TypeOfRooms3 = TestCommon.createTypeOfRoomByShop(shop3.Id, 3);
		
		Date today = Date.today();
		DateTime startTime = DateTime.newInstance(today.year(),today.month(),today.day());
		DateTime endTime = startTime.addYears(1);
		String strStartDate = startTime.format('yyyy/MM/dd');
		String strEndDate = endTime.format('yyyy/MM/dd');
		// CSVアップロード内容設定
		csvBody += 	accs[0].Name + ',' + shop1.Name + ',' + TypeOfRooms1[0].Name + ',' + strStartDate + ',' + strEndDate + ',' + '3\n'+
					accs[0].Name + ',' + shop1.Name + ',' + TypeOfRooms1[1].Name + ',' + strStartDate + ',' + strEndDate + ',' + '2\n'+
					accs[0].Name + ',' + shop1.Name + ',' + TypeOfRooms1[2].Name + ',' + strStartDate + ',' + strEndDate + ',' + '1\n'+
					accs[1].Name + ',' + shop2.Name + ',' + TypeOfRooms1[0].Name + ',' + strStartDate + ',' + strEndDate + ',' + '3\n'+
					accs[1].Name + ',' + shop2.Name + ',' + TypeOfRooms1[1].Name + ',' + strStartDate + ',' + strEndDate + ',' + '2\n'+
					accs[1].Name + ',' + shop2.Name + ',' + TypeOfRooms1[2].Name + ',' + strStartDate + ',' + strEndDate + ',' + '1\n'+
					accs[2].Name + ',' + shop3.Name + ',' + TypeOfRooms1[0].Name + ',' + strStartDate + ',' + strEndDate + ',' + '3\n'+
					accs[2].Name + ',' + shop3.Name + ',' + TypeOfRooms1[1].Name + ',' + strStartDate + ',' + strEndDate + ',' + '2\n'+
					accs[2].Name + ',' + shop3.Name + ',' + TypeOfRooms1[2].Name + ',' + strStartDate + ',' + strEndDate + ',' + '1\n';
		Test.startTest();
		// ファイルアップロード処理
		FileUploadImpForRealAGT fileHandel = new FileUploadImpForRealAGT();
		fileHandel.filehand.setFileName('TestUploadFile');
		fileHandel.filehand.setFileBody(Blob.valueOf(csvBody));
		fileHandel.processCsvFile();
		System.assert(!fileHandel.filehand.result.isHasErrMsg,fileHandel.filehand.result);
		// 汎用マスタのリアルAGT情報を確認する
		// 旅行会社１関連データは３件、部屋タイプは
		String querySql = CommSqlUtils.generateQueryString('RealAGT__c');
		List<RealAGT__c> totalNums = DataBase.query(querySql);
		System.assertEquals(totalNums.size(), 9);
		Test.stopTest();
					
	}
	/**
	* CSV関連チェックテスト
	* ファイルは非存在する場合
	**/
	static testMethod void RealAGT_UPD_Case2() {
		CreateBaseInfo();
		// ファイルアップロード処理
		FileUploadImpForRealAGT fileHandel = new FileUploadImpForRealAGT();
		fileHandel.filehand.setFileName('TestUploadFile');
		fileHandel.processCsvFile();
		System.assert(fileHandel.filehand.result.isHasErrMsg,fileHandel.filehand.result);
	}
	/**
	* Header以外の情報はない場合
	**/
	static testMethod void RealAGT_UPD_Case3() {
		CreateBaseInfo();
		String csvBody = 	'旅行会社名,店舗名,部屋タイプ名,開始日付,終了日付,部屋数\n';
		// ファイルアップロード処理
		FileUploadImpForRealAGT fileHandel = new FileUploadImpForRealAGT();
		fileHandel.filehand.setFileName('TestUploadFile');
		fileHandel.filehand.setFileBody(Blob.valueOf(csvBody));
		fileHandel.processCsvFile();
		System.assert(!fileHandel.filehand.result.isHasErrMsg,fileHandel.filehand.result);
		System.assert(fileHandel.filehand.result.isHasInfoMsg,fileHandel.filehand.result);
	}
	/**
	* 項目数設定不正
	**/
	static testMethod void RealAGT_UPD_Case4() {
		CreateBaseInfo();
		String csvBody = 	'旅行会社名,店舗名,部屋タイプ名,開始日付,終了日付,部屋数\n' + 
							'1,2,3\n';
		// ファイルアップロード処理
		FileUploadImpForRealAGT fileHandel = new FileUploadImpForRealAGT();
		fileHandel.filehand.setFileName('TestUploadFile');
		fileHandel.filehand.setFileBody(Blob.valueOf(csvBody));
		fileHandel.processCsvFile();
		System.assert(fileHandel.filehand.result.isHasErrMsg,fileHandel.filehand.result);
		System.assert(!fileHandel.filehand.result.isHasInfoMsg,fileHandel.filehand.result);
	}
	/**
	* 項目有効性チェック
	**/
	static testMethod void RealAGT_UPD_Case5() {
		CreateBaseInfo();
		String csvBody = 	'旅行会社名,店舗名,部屋タイプ名,開始日付,終了日付,部屋数\n' + 
							'1,,3,4,5,6\n' +
							'1,2,,4,5,6\n' +
							'1,2,3,,5,6\n' +
							'1,2,3,4,,6\n' +
							'1,2,3,4,5,\n' +
							'1,2,3,2013/11/12,2014/12/01,xx\n';
		// ファイルアップロード処理
		FileUploadImpForRealAGT fileHandel = new FileUploadImpForRealAGT();
		fileHandel.filehand.setFileName('TestUploadFile');
		fileHandel.filehand.setFileBody(Blob.valueOf(csvBody));
		fileHandel.processCsvFile();
		System.assert(fileHandel.filehand.result.isHasErrMsg,fileHandel.filehand.result);
		System.assert(!fileHandel.filehand.result.isHasInfoMsg,fileHandel.filehand.result);
	}
	
	/**
	* 旅行会社、支店、部屋タイプファイル内重複設定チエック
	**/
	static testMethod void RealAGT_UPD_Case6() {
		CreateBaseInfo();
		String csvBody = 	'旅行会社名,店舗名,部屋タイプ名,開始日付,終了日付,部屋数\n' + 
							'1,1,1,2013/11/12,2014/12/01,6\n' +
							'1,1,1,2013/11/12,2014/12/01,6\n';
		// ファイルアップロード処理
		FileUploadImpForRealAGT fileHandel = new FileUploadImpForRealAGT();
		fileHandel.filehand.setFileName('TestUploadFile');
		fileHandel.filehand.setFileBody(Blob.valueOf(csvBody));
		fileHandel.processCsvFile();
		System.assert(fileHandel.filehand.result.isHasErrMsg,fileHandel.filehand.result);
		System.assert(!fileHandel.filehand.result.isHasInfoMsg,fileHandel.filehand.result);
	}
	/**
	* 設定の旅行会社、支店、部屋タイプ非存在する場合
	*/
	static testMethod void RealAGT_UPD_Case7() {
		CreateBaseInfo();
		String csvBody = 	'旅行会社名,店舗名,部屋タイプ名,開始日付,終了日付,部屋数\n' + 
							'1,1,1,2013/11/12,2014/12/01,6\n' ;
		// ファイルアップロード処理
		FileUploadImpForRealAGT fileHandel = new FileUploadImpForRealAGT();
		fileHandel.filehand.setFileName('TestUploadFile');
		fileHandel.filehand.setFileBody(Blob.valueOf(csvBody));
		fileHandel.processCsvFile();
		System.assert(fileHandel.filehand.result.isHasErrMsg,fileHandel.filehand.result);
		System.assert(!fileHandel.filehand.result.isHasInfoMsg,fileHandel.filehand.result);
	}
	

	
	/**
	* 旅行会社取引先情報を作成する
	**/
	private static List<Account> CreateTravelAccount(Integer rsSize) { 
		List<Account> items = new List<Account>();
		for (Integer i=0; i<rsSize; i++) {
			Account acc = new Account(
				Name = 'ACC_' + i,
				AccountType__c = '旅行会社'
			);
			items.add(acc);
		}
		insert items;
		return items;
	}
	
	private static RealAGT__c createRealAgts (Id accId, Id roomTypeId, Integer rooms, Date startDt, Date endDt) {
			
            RealAGT__c newItem = new RealAGT__c(
                AccountRef__c = accId
            ,   RoomTypeRel__c = roomTypeId
            ,   AgtMaxRooms__c = rooms
            ,   StartDate__c = startDt
            ,   EndDate__c = endDt
            );
            insert newItem;
            // 2015/12/01 Assert BEGIN
			System.assertEquals([select Id from RealAGT__c].size(), 1);
			// 2015/12/01 Assert END
            return newItem;
	}
	private static void CreateBaseInfo () {
		delete [select id from RealAGT__c];
	}
}