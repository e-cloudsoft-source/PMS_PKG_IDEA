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
private class InfoOutputProcessCtrlTest {

	// 店舗あり
    static testMethod void Case1() {
    	// 店舗作成
    	ShopInformation__c shop = TestCommon.createShopInfo();
    	// 取引先
    	Account account = TestCommon.createNormalAccount();
		// 口座情報の作成
		String shopAccLocalName = ShopAccountInfo__c.sObjectType.getDescribe().getName();
        List<RecordType> rts = [SELECT Id,Name FROM RecordType WHERE SobjectType  = :shopAccLocalName];
        String kouzaIds = createShopAccount(5,account,rts,shop.id);
		
		User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        loginUser.ShopCode__c = shop.shopcode__c;
        update loginUser;
        
		ApexPages.currentPage().getParameters().put('rIds',kouzaIds);
		InfoOutputProcessCtrl ctrl = new InfoOutputProcessCtrl();
		Pagereference page = ctrl.generalKouzaInfo();
		System.assert(page.getUrl().contains('rid'),page.getUrl());
    }

    // 店舗なし
    static testMethod void Case2() {
    	// 取引先
    	Account account = TestCommon.createNormalAccount();
		// 口座情報の作成
		String shopAccLocalName = ShopAccountInfo__c.sObjectType.getDescribe().getName();
        List<RecordType> rts = [SELECT Id,Name FROM RecordType WHERE SobjectType  = :shopAccLocalName];
        String kouzaIds = createShopAccount(5,account,rts,null);
		
		User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        loginUser.ShopCode__c = null;
        update loginUser;
		ApexPages.currentPage().getParameters().put('rIds',kouzaIds);
		InfoOutputProcessCtrl ctrl = new InfoOutputProcessCtrl();
		Pagereference page = ctrl.generalKouzaInfo();
		System.assert(page.getUrl().contains('rid'),page.getUrl());
    }
    
    public static String createShopAccount(Integer size,account acc,List<RecordType> recs, id shopid) {
		List<ShopAccountInfo__c> saLst = new List<ShopAccountInfo__c>();
		for (Integer i= 0; i<size; i++) {
			for (RecordType rectype : recs) {
				ShopAccountInfo__c dsa = new ShopAccountInfo__c(
					BankNumber__c = CommUtils.getRandom(4),
					BankBranchNumber__c = CommUtils.getRandom(3),         
				    DepositsType__c = '普通',
				    BankAccountNo__c = CommUtils.getRandom(7),
				    BankName__c = '住友銀行' + CommUtils.getRandom(10),
				    BankBranchName__c = '目黒支店' + CommUtils.getRandom(10),
				    BankBranchNameKana__c = 'してんバンゴの確認',
				    RequestUserName__c = 'ｶﾏﾙｷ' + CommUtils.getRandom(10),
				    TransferChargeKbn__c = '先方負担',
				    RequestUserCode__c = 'REQ_'+CommUtils.getRandom(6),
				    AccountTypeLst__c = '買掛入金',
				    ShopInfoRef__c = shopid,
					AccountRef__c = acc.id,
					recordTypeId = rectype.id
				);
				saLst.add(dsa);
			}
		}
		insert saLst;
		String kouzaIds = '';
		for(ShopAccountInfo__c info : saLst){
			kouzaIds += info.Id + ',';
		}
		return kouzaIds;
	}
    
    
}