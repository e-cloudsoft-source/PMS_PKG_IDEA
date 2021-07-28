/****************
* ユーザ情報時間単位設定トリガーのテストクラス
*****************/
@isTest
private class UserTriggerProcessTest {
	static testMethod void myUnitTest1() {

		Profile p = [select id from profile where userType='Standard' limit 1];
		
		User userItem = new User(
		 				alias = 'AliasJia', 
		 				email='standarduser@testorg.com',
            			emailencodingkey='UTF-8', 
            			lastname='TestingUserLaseName', 
            			languagelocalekey='en_US',
            			localesidkey='en_US', 
            			profileid = p.Id,
            			timezonesidkey='America/Los_Angeles', 
            			username='standarduserForJinya@testorg.com');
		insert userItem;
		try { 
			WorkTimeDefine__c  wkDef = WorkTimeDefineUtil.getWkDefineByShopCode('102');
		} catch (Exception e) {
			system.assert(e.getMessage().contains('Unable to locate shop info:'));
		}
	}
}