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
private class UserUtilTest {


	@isTest
	static void TestUserCase1() {
		User userinf1 = UserUtil.CurrentUser;
		User userinf2 = UserUtil.getUser(UserInfo.getUserId());
		System.assert(userinf1.Id == userinf2.Id);
		
		try {
			User userinf3 = UserUtil.getUser('003d000001TpU89AAF');
		} catch (CommException e) {
			
			System.assertEquals('Unable to locate user id: 003d000001TpU89AAF', e.getMessage());
		}
		try {
			UserUtil.UserShopInfo usinfo = UserUtil.getUserInfo('003d000001TpU89AAF');
		} catch (CommException e) {
			
			System.assertEquals('Unable to locate user id: 003d000001TpU89AAF', e.getMessage());
		}
		String currcncy = UserUtil.getDefaultCurrency();
		String lng = UserUtil.getDefaultLanguage();
	}
	@isTest
	static void TestUserCase2() {
		User cUser = [select shopCode__c from User Where id = :UserInfo.getUserId()];
		cUser.shopCode__c = '01,02,03:1';
		update cUser;
		System.runAs(cUser){
		UserUtil.UserShopInfo usrInf = UserUtil.CurrentUserInfo;
		System.assertEquals(usrInf.defaultShopCode, '03');
		}
	}
	@isTest
	static void TestUserCase3() {
		User cUser = [select shopCode__c from User Where id = :UserInfo.getUserId()];
		cUser.shopCode__c = '01,02,03';
		update cUser;
		System.runAs(cUser){
		UserUtil.UserShopInfo usrInf = UserUtil.CurrentUserInfo;
		System.assertEquals(usrInf.defaultShopCode, '01');
		}
	}
	@isTest
	static void TestUserCase4() {
		User cUser = [select shopCode__c from User Where id = :UserInfo.getUserId()];
		cUser.shopCode__c = '01,02,03';
		update cUser;
		System.runAs(cUser){
		User userinf2 = UserUtil.getUser(UserInfo.getUserId());
		System.assertEquals(userinf2.ShopCode__c, '01');
		}
	}
	@isTest
	static void TestUserCase5() {
		Lead__c lead = TestCommon.createlead();
		TestCommon.createWsServiceConfigXML();
		String leadStr = JSON.serialize(new List<String>{lead.id});
		UserUtil.getEmailStatus(leadStr,true);
		UserUtil.getEmailBody(leadStr,true);
		UserUtil.getDefaultCurrencyAndBillComment();
		UserUtil.getAccSpCd(UserInfo.getUserId());
		UserUtil.getBillSpCd(UserInfo.getUserId());
		Set<String> spcdSet = new Set<String>{'02','','01'};
		UserUtil.getFixedMsgJSON(JSON.serialize(new List<String>(spcdSet)));
		UserUtil.getFixedMsgInfo(spcdSet);
		UserUtil.syncShopcodeToDefShopCode();
	}
	@isTest
	static void TestUserCase6() {
		Lead__c lead = TestCommon.createlead();
		lead.ReservedStatus__c = 'キャンセル';
		update lead;
		TestCommon.createWsServiceConfigXML();
		String leadStr = JSON.serialize(new List<String>{lead.id});
		UserUtil.getEmailStatus(leadStr,false);
		UserUtil.getEmailBody(leadStr,false);
		UserUtil.getDefaultCurrencyAndBillComment();
		UserUtil.getAccSpCd(UserInfo.getUserId());
		UserUtil.getBillSpCd(UserInfo.getUserId());
		Set<String> spcdSet = new Set<String>{'02','','01'};
		UserUtil.getFixedMsgJSON(JSON.serialize(new List<String>(spcdSet)));
		UserUtil.getFixedMsgInfo(spcdSet);
		UserUtil.syncShopcodeToDefShopCode();
	}
}