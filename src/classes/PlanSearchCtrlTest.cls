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
private class PlanSearchCtrlTest {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        ShopInformation__c shopInfo = TestCommon.createShopInfo();
        Plan__c item = TestCommon.createPlan();
    	PlanSearchCtrl ctrl = new PlanSearchCtrl();
    	ctrl.init();
    	ctrl.ShopCode = shopInfo.Id;
    	ctrl.c_planNm = item.Name;
    	ctrl.c_dpId = '1111';
    	ctrl.c_gpId = '2222';
    	ctrl.nextPage();
        ctrl.lastPage();
        ctrl.previousPage();
        ctrl.firstPage();
    	ctrl.queryInfo();
        
    }
    // 室料情報を取得する
    static testMethod void myUnitTest1() {
        // TO DO: implement unit test
        ShopInformation__c shop = TestCommon.createShopInfo();
		shop.ShopCode__c = '02';
		upsert shop;
        User cUser = [select shopCode__c from User Where id = :UserInfo.getUserId()];
		cUser.shopCode__c = '01,02:1,03';
		update cUser;
        
        JMST__c taxMst =  TestCommon.createTaxMst();
    	taxMst.TaxRate__c = 0;
    	update taxMst;
        AccountMaster__c shitulyoItem1 = new AccountMaster__c(
           Name = '食事1',
           ActionType__c = CommConst.PROD_ACTION_TYPE_RP,
           jmstRef__c = taxMst.Id,
           StsTaxfee__c = '0',
           Field3__c = '100999',
           Field5__c = 1050,
           ServiceRate__c = 10,
           SpecialTax__c = 100
        );
        AccountMaster__c shitItem2 = new AccountMaster__c(
           Name = '室料',
           ActionType__c = CommConst.PROD_ACTION_TYPE_RP,
           jmstRef__c = taxMst.Id,
           StsTaxfee__c = '0',
           Field3__c = '10099434',
           Field5__c = 0,
           ServiceRate__c = 10
        );
        List<AccountMaster__c> itemLst = new List<AccountMaster__c>();
        itemLst.add(shitulyoItem1);
        itemLst.add(shitItem2);
        insert itemLst;
        Plan__c planItem = TestCommon.createPlan();
    	planItem.packageCode__c = 'U0001';
    	planItem.PlanNo__c = '00000001';
    	planItem.AccountA__c = shitulyoItem1.Id;
    	planItem.AccountB__c = shitItem2.Id;
    	planItem.Name = 'テストプラン情報の設定をを行う111';
    	update planItem;
    	PlanDetail__c detail = new PlanDetail__c(
			TaxRate__c = 0,
        	PlanRef__c = planItem.Id,
        	AccountMasterRef__c = shitItem2.Id
        );
        insert detail;
    	Apexpages.currentPage().getParameters().put('par','1');
    	PlanSearchCtrl ctrl = new PlanSearchCtrl();    	
    	ctrl.init();
    	ctrl.ShopCode = shop.Id;
    	ctrl.c_planNm = 'テストプラン情報の設定をを行う111';
    	ctrl.c_dpId = '1111';
    	ctrl.c_gpId = '2222';
    	ctrl.queryInfo();
    	
        
    }
    // 2020/05/30 BY zyz BEGIN
    static testMethod void myUnitPlanTest() {
        // TO DO: implement unit test
        ShopInformation__c shopInfo = TestCommon.createShopInfo();
		List<TypeOfRooms__c> TypeOfRooms1 = TestCommon.createTypeOfRoomByShop(shopInfo.Id, 3);
        Plan__c plan = TestCommon.createPlan();
		plan.BasePlanFlg__c = true;
		update plan;
		TestCommon.createRaceRateDetail('A','B',5);
    	BasePlanSetupViewCtrl ctrl = new BasePlanSetupViewCtrl();
    	ctrl.c_planNm = 'テストプラン情報の設定をを行う111';
    	ctrl.c_dpId = '1111';
    	ctrl.c_gpId = '2222';
    	ctrl.queryInfo();
        
    }
    // 2020/05/30 BY zyz END
}