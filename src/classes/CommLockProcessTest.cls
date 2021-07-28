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
private class CommLockProcessTest {

    /**
    * 多店舗の場合
    **/
    /**
    * 店舗別々で選択する場合、EIDTOR可能
    **//*
   	static testMethod void Case_Muliti_Case1_1() {
   		
        String appName = 'TestCommon';
        Id userId = UserInfo.getUserId();

   		// 店舗作成
   		ShopInformation__c shop1 =  TestCommon.createShopInfo();
   		ShopInformation__c shop2 =  TestCommon.createShopInfo();
   		User runUsr = [select id, shopCode__c from User Where Id = :UserInfo.getUserId()];
   		runUsr.shopCode__c = shop1.ShopCode__c;
   		update runUsr;
   		System.runAs(runUsr) {
   			// 店舗１予定表編集を行う　
   			CommLockProcess.LockMessage lm = SobjectLockComp.beforeEdit(appName, shop1.ShopCode__c);
   			System.assertEquals(lm.isNewOrHadlock, true, lm);
   			// DBにロック情報を自動書込する
   			List<DataLock__c> ds = getDataLockByAppShop(appName, new Set<Id>{shop1.Id});
   			System.assertEquals(ds.size(), 1, ds);
   		}
   		runUsr.shopCode__c = shop2.ShopCode__c;
   		update runUsr;
   		System.runAs(runUsr) {
   			// 店舗１予定表編集を行う　
   			CommLockProcess.LockMessage lm = SobjectLockComp.beforeEdit(appName, shop2.ShopCode__c);
   			System.assertEquals(lm.isNewOrHadlock, true, lm);
   			// DBにロック情報を自動書込する
   			List<DataLock__c> ds = getDataLockByAppShop(appName, new Set<Id>{shop2.Id});
   			System.assertEquals(ds.size(), 1, ds);
   		}
   	}*/
    /**
    * A：店舗はALL選択する場合→STEP1->自動全て店舗のLOCK情報を新規作成する
    * B：店舗はA選択する→STEP2
    **/
   	static testMethod void Case_Muliti_Case1_2() {
   		
        String appName = 'TestCommon';
        Id userId = UserInfo.getUserId();

   		// 店舗作成
   		ShopInformation__c shop1 =  TestCommon.createShopInfo();
   		ShopInformation__c shop2 =  TestCommon.createShopInfo();
		
		
		// 店舗１予定表編集を行う　
		CommLockProcess.LockMessage lm = SobjectLockComp.beforeEdit(appName, '');
		System.assertEquals(lm.isNewOrHadlock, true, lm);
		// DBにロック情報を自動書込する
		List<DataLock__c> ds = getDataLockByAppShop(appName);
		System.assertEquals(ds.size(), 2, ds);
		
		User user2 = TestCommon.CreateUser();
		System.runAs(user2) {
			
			// 店舗１予定表編集を行う　
			CommLockProcess.LockMessage lm2 = SobjectLockComp.beforeEdit(appName, shop1.ShopCode__c);
			System.assertEquals(lm2.isNewOrHadlock, false, lm2);
			// ログイン者情報は確認
			System.assertEquals(lm2.dl.LockByRef__c, userId, lm2);
			System.assertEquals(lm2.dl.TimeStmp__c, lm.dl.TimeStmp__c, lm2);
			// DBにロック情報を自動書込する
			ds = getDataLockByAppShop(appName);
			System.assertEquals(ds.size(), 2, ds);
			// B店舗は強制進める
			CommLockProcess.LockMessage lm3 = SobjectLockComp.unlockOrChangeLockStatus(appName, false, lm2.dl.TimeStmp__c, shop1.ShopCode__c);
			System.assertEquals(lm3.isNewOrHadlock, true, lm3 + '['+ shop1.Id +'][' +  shop2.Id + ']');
			System.assertNotEquals(lm3.dl.TimeStmp__c, lm2.dl.TimeStmp__c, lm3);
			// 既存のロックデータは２件、１件はALLのLock情報、１件は店舗１のLOCK情報
			ds = getDataLockByAppShop(appName);
			System.assertEquals(ds.size(), 2, ds);
			System.assertNotEquals(ds[0].TimeStmp__c , ds[1].TimeStmp__c, ds);
			// 変更、保存処理
			CommLockProcess.LockMessage lm4 = SobjectLockComp.beforeUpdate(appName, shop1.ShopCode__c, lm3.dl.TimeStmp__c);
			// 自分のロック情報を比較する
			System.assertEquals(lm4.dl.TimeStmp__c, lm3.dl.TimeStmp__c, lm4);
		}
		// 店舗ALLは保存処理を行う
		CommLockProcess.LockMessage lm5 = SobjectLockComp.beforeUpdate(appName, '', lm.dl.TimeStmp__c);
		// 店舗LM5はエラーが発生、自分のロック情報を見つからなかった
		system.assertEquals(lm5.dl , null, lm5);
		system.assertEquals(lm5.timeStr, lm.timeStr, lm5);
   	}
    /**
    * A：店舗はA選択する場合→STEP1->自動全て店舗のLOCK情報を新規作成する
    * B：店舗はALL選択する→STEP2
    **/
   	static testMethod void Case_Muliti_Case1_3() {
   		
        String appName = 'TestCommon';
        Id userId = UserInfo.getUserId();

   		// 店舗作成
   		ShopInformation__c shop1 =  TestCommon.createShopInfo();
   		ShopInformation__c shop2 =  TestCommon.createShopInfo();
		
		
		// 店舗１予定表編集を行う　
		CommLockProcess.LockMessage lm = SobjectLockComp.beforeEdit(appName, shop1.ShopCode__c);
		System.assertEquals(lm.isNewOrHadlock, true, lm);
		// DBにロック情報を自動書込する
		List<DataLock__c> ds = getDataLockByAppShop(appName);
		System.assertEquals(ds.size(), 1, ds);
		
		User user2 = TestCommon.CreateUser();
		System.runAs(user2) {
			
			// 店舗１予定表編集を行う　
			CommLockProcess.LockMessage lm2 = SobjectLockComp.beforeEdit(appName, '');
			System.assertEquals(lm2.isNewOrHadlock, false, lm2);
			// ログイン者情報は確認
			System.assertEquals(lm2.dl.LockByRef__c, userId, lm2);
			System.assertEquals(lm2.dl.TimeStmp__c, lm.dl.TimeStmp__c, lm2);
			// DBにロック情報を自動書込する
			ds = getDataLockByAppShop(appName);
			System.assertEquals(ds.size(), 1, ds);
			// B店舗は強制進める
			CommLockProcess.LockMessage lm3 = SobjectLockComp.unlockOrChangeLockStatus(appName, false, lm2.dl.TimeStmp__c, '');
			System.assertEquals(lm3.isNewOrHadlock, true, lm3 + '['+ shop1.Id +'][' +  shop2.Id + ']');
			System.assertNotEquals(lm3.dl.TimeStmp__c, lm2.dl.TimeStmp__c, lm3);
			// 既存のロックデータは２件、2件はALLのLock情報
			ds = getDataLockByAppShop(appName);
			System.assertEquals(ds.size(), 2, ds);
			System.assertEquals(ds[0].TimeStmp__c , ds[1].TimeStmp__c, ds);
			// 変更、保存処理
			CommLockProcess.LockMessage lm4 = SobjectLockComp.beforeUpdate(appName, '', lm3.dl.TimeStmp__c);
			// 自分のロック情報を比較する
			System.assertEquals(lm4.dl.TimeStmp__c, lm3.dl.TimeStmp__c, lm4);
		}
		// 店舗ALLは保存処理を行う
		CommLockProcess.LockMessage lm5 = SobjectLockComp.beforeUpdate(appName, shop1.ShopCode__c, lm.dl.TimeStmp__c);
		// 店舗LM5はエラーが発生、自分のロック情報を見つからなかった
		system.assertEquals(lm5.dl , null, lm5);
		system.assertEquals(lm5.timeStr, lm.timeStr, lm5);
   		
   	}
   	
    /**
    * A：店舗はA選択する場合→STEP1->
    * B：店舗はA選択する→STEP2
    **/
   	static testMethod void Case_Muliti_Case1_4() {
   		
        String appName = 'TestCommon';
        Id userId = UserInfo.getUserId();

   		// 店舗作成
   		ShopInformation__c shop1 =  TestCommon.createShopInfo();
   		ShopInformation__c shop2 =  TestCommon.createShopInfo();

		// 店舗１予定表編集を行う　
		CommLockProcess.LockMessage lm = SobjectLockComp.beforeEdit(appName, shop1.ShopCode__c);
		System.assertEquals(lm.isNewOrHadlock, true, lm);
		// DBにロック情報を自動書込する
		List<DataLock__c> ds = getDataLockByAppShop(appName);
		System.assertEquals(ds.size(), 1, ds);
		
		User user2 = TestCommon.CreateUser();
		System.runAs(user2) {
			
			// 店舗１予定表編集を行う　
			CommLockProcess.LockMessage lm2 = SobjectLockComp.beforeEdit(appName, shop1.ShopCode__c);
			System.assertEquals(lm2.isNewOrHadlock, false, lm2);
			// ログイン者情報は確認
			System.assertEquals(lm2.dl.LockByRef__c, userId, lm2);
			System.assertEquals(lm2.dl.TimeStmp__c, lm.dl.TimeStmp__c, lm2);
			// DBにロック情報を自動書込する
			ds = getDataLockByAppShop(appName);
			System.assertEquals(ds.size(), 1, ds);
			// B店舗は強制進める
			CommLockProcess.LockMessage lm3 = SobjectLockComp.unlockOrChangeLockStatus(appName, false, lm2.dl.TimeStmp__c, shop1.ShopCode__c);
			System.assertEquals(lm3.isNewOrHadlock, true, lm3 + '['+ shop1.Id +'][' +  shop2.Id + ']');
			System.assertNotEquals(lm3.dl.TimeStmp__c, lm2.dl.TimeStmp__c, lm3);
			// 既存のロックデータは２件、2件はALLのLock情報
			ds = getDataLockByAppShop(appName);
			System.assertEquals(ds.size(), 1, ds);
			// 変更、保存処理
			CommLockProcess.LockMessage lm4 = SobjectLockComp.beforeUpdate(appName, shop1.ShopCode__c, lm3.dl.TimeStmp__c);
			// 自分のロック情報を比較する
			System.assertEquals(lm4.dl.TimeStmp__c, lm3.dl.TimeStmp__c, lm4);
		}
		// 店舗ALLは保存処理を行う
		CommLockProcess.LockMessage lm5 = SobjectLockComp.beforeUpdate(appName, shop1.ShopCode__c, lm.dl.TimeStmp__c);
		// 店舗LM5はエラーが発生、自分のロック情報を見つからなかった
		system.assertEquals(lm5.dl , null, lm5);
		system.assertEquals(lm5.timeStr, lm.timeStr, lm5);
   		
   	}

    /**
    * A：店舗なし選択する場合→STEP1->
    * B：店舗なし選択する→STEP2
    **/
   	static testMethod void Case_Muliti_Case2_1() {
   		
        String appName = 'TestCommon';
        Id userId = UserInfo.getUserId();

		// 店舗１予定表編集を行う　
		CommLockProcess.LockMessage lm = SobjectLockComp.beforeEdit(appName, '');
		System.assertEquals(lm.isNewOrHadlock, true, lm);
		// DBにロック情報を自動書込する
		List<DataLock__c> ds = getDataLockByAppShop(appName);
		System.assertEquals(ds.size(), 1, ds);
		
		User user2 = TestCommon.CreateUser();
		System.runAs(user2) {
			
			// 店舗１予定表編集を行う　
			CommLockProcess.LockMessage lm2 = SobjectLockComp.beforeEdit(appName, '');
			System.assertEquals(lm2.isNewOrHadlock, false, lm2);
			// ログイン者情報は確認
			System.assertEquals(lm2.dl.LockByRef__c, userId, lm2);
			System.assertEquals(lm2.dl.TimeStmp__c, lm.dl.TimeStmp__c, lm2);
			// DBにロック情報を自動書込する
			ds = getDataLockByAppShop(appName);
			System.assertEquals(ds.size(), 1, ds);
			// B店舗は強制進める
			CommLockProcess.LockMessage lm3 = SobjectLockComp.unlockOrChangeLockStatus(appName, false, lm2.dl.TimeStmp__c, '');
			System.assertEquals(lm3.isNewOrHadlock, true, lm3);
			System.assertNotEquals(lm3.dl.TimeStmp__c, lm2.dl.TimeStmp__c, lm3);
			// 既存のロックデータは２件、2件はALLのLock情報
			ds = getDataLockByAppShop(appName);
			System.assertEquals(ds.size(), 1, ds);
			// 変更、保存処理
			CommLockProcess.LockMessage lm4 = SobjectLockComp.beforeUpdate(appName, '', lm3.dl.TimeStmp__c);
			// 自分のロック情報を比較する
			System.assertEquals(lm4.dl.TimeStmp__c, lm3.dl.TimeStmp__c, lm4);
		}
		// 店舗ALLは保存処理を行う
		CommLockProcess.LockMessage lm5 = SobjectLockComp.beforeUpdate(appName, '', lm.dl.TimeStmp__c);
		// 店舗LM5はエラーが発生、自分のロック情報を見つからなかった
		system.assertEquals(lm5.dl , null, lm5);
		system.assertEquals(lm5.timeStr, lm.timeStr, lm5);
   		
   	}

    /**
    * A：店舗なし選択する場合→STEP1->
    * B：店舗なし選択する→STEP2
    * B強制編集、そして、キャンセルの場合
    **/
   	static testMethod void Case_Muliti_Case2_2() {
   		
        String appName = 'TestCommon';
        Id userId = UserInfo.getUserId();

		// 店舗１予定表編集を行う　
		CommLockProcess.LockMessage lm = SobjectLockComp.beforeEdit(appName, '');
		System.assertEquals(lm.isNewOrHadlock, true, lm);
		// DBにロック情報を自動書込する
		List<DataLock__c> ds = getDataLockByAppShop(appName);
		System.assertEquals(ds.size(), 1, ds);
		
		User user2 = TestCommon.CreateUser();
		System.runAs(user2) {
			
			// 店舗１予定表編集を行う　
			CommLockProcess.LockMessage lm2 = SobjectLockComp.beforeEdit(appName, '');
			System.assertEquals(lm2.isNewOrHadlock, false, lm2);
			// ログイン者情報は確認
			System.assertEquals(lm2.dl.LockByRef__c, userId, lm2);
			System.assertEquals(lm2.dl.TimeStmp__c, lm.dl.TimeStmp__c, lm2);
			// DBにロック情報を自動書込する
			ds = getDataLockByAppShop(appName);
			System.assertEquals(ds.size(), 1, ds);
			// B店舗は強制進める
			CommLockProcess.LockMessage lm3 = SobjectLockComp.unlockOrChangeLockStatus(appName, false, lm2.dl.TimeStmp__c, '');
			System.assertEquals(lm3.isNewOrHadlock, true, lm3);
			System.assertNotEquals(lm3.dl.TimeStmp__c, lm2.dl.TimeStmp__c, lm3);
			// 既存のロックデータは1件
			ds = getDataLockByAppShop(appName);
			System.assertEquals(ds.size(), 1, ds);
			// キャンセルボタン
			CommLockProcess.LockMessage lm4 = SobjectLockComp.unlockOrChangeLockStatus(appName, true, lm3.dl.TimeStmp__c, '');
			// 自分のロック情報を比較する
			ds = getDataLockByAppShop(appName);
			System.assertEquals(ds.size(), 0, ds);
			System.assertEquals(lm4, null);
		}
		// 店舗ALLは保存処理を行う
		CommLockProcess.LockMessage lm5 = SobjectLockComp.beforeUpdate(appName, '', lm.dl.TimeStmp__c);
		// 店舗LM5はエラーが発生、自分のロック情報を見つからなかった
		system.assertEquals(lm5.dl , null, lm5);
		system.assertEquals(lm5.timeStr, lm.timeStr, lm5);
   		
   	}

    /**
    * A：店舗なし選択する場合→STEP1->
    * B：店舗なし選択する→STEP2
    * B強制編集、そして、キャンセルの場合
    **/
   	static testMethod void Case_Muliti_Case2_3() {
   		
        String appName = 'TestCommon';
        Id userId = UserInfo.getUserId();

		// 店舗１予定表編集を行う　
		CommLockProcess.LockMessage lm = SobjectLockComp.beforeEdit(appName, '');
		System.assertEquals(lm.isNewOrHadlock, true, lm);
		// DBにロック情報を自動書込する
		List<DataLock__c> ds = getDataLockByAppShop(appName);
		System.assertEquals(ds.size(), 1, ds);
		
		User user2 = TestCommon.CreateUser();
		System.runAs(user2) {
			
			// 店舗１予定表編集を行う　
			CommLockProcess.LockMessage lm2 = SobjectLockComp.beforeEdit(appName, '');
			System.assertEquals(lm2.isNewOrHadlock, false, lm2);
			// ログイン者情報は確認
			System.assertEquals(lm2.dl.LockByRef__c, userId, lm2);
			System.assertEquals(lm2.dl.TimeStmp__c, lm.dl.TimeStmp__c, lm2);
			// DBにロック情報を自動書込する
			ds = getDataLockByAppShop(appName);
			System.assertEquals(ds.size(), 1, ds);
			// B店舗は強制進める
			CommLockProcess.LockMessage lm3 = SobjectLockComp.unlockOrChangeLockStatus(appName, false, lm2.dl.TimeStmp__c, '');
			System.assertEquals(lm3.isNewOrHadlock, true, lm3);
			System.assertNotEquals(lm3.dl.TimeStmp__c, lm2.dl.TimeStmp__c, lm3);
			// 既存のロックデータは２件、2件はALLのLock情報
			ds = getDataLockByAppShop(appName);
			System.assertEquals(ds.size(), 1, ds);
		}
		// 店舗ALLは保存処理を行う
		// キャンセルボタン
		CommLockProcess.LockMessage lm5 = SobjectLockComp.unlockOrChangeLockStatus(appName, true, lm.dl.TimeStmp__c, '');
		// 店舗LM5はエラーが発生、自分のロック情報を見つからなかった
		system.assertEquals(lm5, null);
		// 自分のロック情報を比較する
		ds = getDataLockByAppShop(appName);
		System.assertEquals(ds.size(), 1, ds);
		System.assertNotEquals(ds[0].TimeStmp__c, lm.dl.TimeStmp__c, ds);
   	}
    /**
    * A：店舗なし選択する場合→STEP1->
    * B：店舗なし選択する→STEP2
    * C：店舗なし選択する→STEP3
    * 
    **/
   	static testMethod void Case_Muliti_Case2_4() {
   		
        String appName = 'TestCommon';
        Id userId = UserInfo.getUserId();

		// 店舗１予定表編集を行う　
		CommLockProcess.LockMessage lm = SobjectLockComp.beforeEdit(appName, '');
		System.assertEquals(lm.isNewOrHadlock, true, lm);
		// DBにロック情報を自動書込する
		List<DataLock__c> ds = getDataLockByAppShop(appName);
		System.assertEquals(ds.size(), 1, ds);
		
		
		CommLockProcess.LockMessage lm2 = null;
		User user2 = TestCommon.CreateUser();
		System.runAs(user2) {
			
			// 店舗１予定表編集を行う　
			lm2 = SobjectLockComp.beforeEdit(appName, '');
			System.assertEquals(lm2.isNewOrHadlock, false, lm2);
			// ログイン者情報は確認
			System.assertEquals(lm2.dl.LockByRef__c, userId, lm2);
			System.assertEquals(lm2.dl.TimeStmp__c, lm.dl.TimeStmp__c, lm2);
			// DBにロック情報を自動書込する
			ds = getDataLockByAppShop(appName);
			System.assertEquals(ds.size(), 1, ds);
			
		}
		
		CommLockProcess.LockMessage lm3 = null;
		User user3 = TestCommon.CreateUser();
		System.runAs(user3) {
			// 店舗１予定表編集を行う　
			lm3 = SobjectLockComp.beforeEdit(appName, '');
			System.assertEquals(lm3.isNewOrHadlock, false, lm3);
			// ログイン者情報は確認
			System.assertEquals(lm3.dl.LockByRef__c, userId, lm3);
			System.assertEquals(lm3.dl.TimeStmp__c, lm.dl.TimeStmp__c, lm3);
			// DBにロック情報を自動書込する
			ds = getDataLockByAppShop(appName);
			System.assertEquals(ds.size(), 1, ds);
		}
		CommLockProcess.LockMessage lm2_1 = null;
		System.runAs(user2) {
			// B店舗は強制進める
			lm2_1 = SobjectLockComp.unlockOrChangeLockStatus(appName, false, lm2.dl.TimeStmp__c, '');
			System.assertEquals(lm2_1.isNewOrHadlock, true, lm2_1);
			System.assertNotEquals(lm2_1.dl.TimeStmp__c, lm2.dl.TimeStmp__c, lm2_1);
			// 既存のロックデータは２件、2件はALLのLock情報
			ds = getDataLockByAppShop(appName);
			System.assertEquals(ds.size(), 1, ds);
		}
		
		System.runAs(user3) {
			// C店舗は強制進める
			CommLockProcess.LockMessage lm3_1 = SobjectLockComp.unlockOrChangeLockStatus(appName, false, lm3.dl.TimeStmp__c, '');
			System.assertEquals(lm3_1.isNewOrHadlock, false, lm3_1);
			// Bは既に先に強制解除するので、lm3.dl.TimeStmp__cのロック情報は既に更新された
			System.assertEquals(lm3_1.dl.TimeStmp__c, lm2_1.dl.TimeStmp__c, lm3_1);
			ds = getDataLockByAppShop(appName);
			System.assertEquals(ds.size(), 1, ds);

			// B店舗は強制進める
			CommLockProcess.LockMessage lm3_2 = SobjectLockComp.unlockOrChangeLockStatus(appName, false, lm3_1.dl.TimeStmp__c, '');
			System.assertEquals(lm3_2.isNewOrHadlock, true, lm3_2);
			System.assertNotEquals(lm3_2.dl.TimeStmp__c, lm3_1.dl.TimeStmp__c, lm3_2);
			// 既存のロックデータは２件、2件はALLのLock情報
			ds = getDataLockByAppShop(appName);
			System.assertEquals(ds.size(), 1, ds);
		}
   	}
   	
   	private static List<DataLock__c> getDataLockByAppShop(String appName, Set<Id> shopIds) {
   		// 2015/12/01 Assert BEGIN
		System.assertEquals(shopIds != null, true);
		// 2015/12/01 Assert END
 		return [select id, Name,AppName__c,LockTime__c,LockByRef__c,TimeStmp__c,ShopInfoRef__c,LockByRef__r.lastname,LockByRef__r.firstname  from DataLock__c where AppName__c = :appName And ShopInfoRef__c in :shopIds ];
   	}
   	private static List<DataLock__c> getDataLockByAppShop(String appName) {
   		return [select id, Name,AppName__c,LockTime__c,LockByRef__c,TimeStmp__c,ShopInfoRef__c,LockByRef__r.lastname,LockByRef__r.firstname  from DataLock__c where AppName__c = :appName];
   	}
}