@isTest
private class StaffScheduleTriggerProcessTest {
    static testMetHod void case01() {
		Profile p = [select id from profile limit 1];

		createWorkDefine();

		User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	loginUser.ShopCode__c = null;
    	update loginUser;
    	system.runAs(loginUser) {
		TimeManagement__c tmItem = new TimeManagement__c(
						WorkDay__c = Date.today());
		List<TimeManagement__c> tm = new List<TimeManagement__c>();
		tmItem.WorkerRef__c = loginUser.id;
		tm.add(tmItem);
		insert tm;

		StaffSchedule__c ssItem = new StaffSchedule__c(
		 				WorkDay__c = Date.today(),StaffUserRef__c = loginUser.Id);
		List<StaffSchedule__c> ssList = new List<StaffSchedule__c>();
		ssList.add(ssItem);
		// 2015/12/01 Assert BEGIN
		System.assertEquals(ssList.size(), 1);
		// 2015/12/01 Assert END
		insert ssList;
    	}
    }
    static testMetHod void case02() {
		Profile p = [select id from profile limit 1];

		User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	loginUser.ShopCode__c = null;
    	update loginUser;

		StaffSchedule__c ssItem = new StaffSchedule__c(
		 				WorkDay__c = Date.today(),StaffUserRef__c = loginUser.Id);
		List<StaffSchedule__c> ssList = new List<StaffSchedule__c>();
		ssList.add(ssItem);
		// 2015/12/01 Assert BEGIN
		System.assertEquals(ssList.size(), 1);
		// 2015/12/01 Assert END
		insert ssList;

		Date s1 = Date.today();
		Date s2 = s1.addDays(-10);

		List<StaffSchedule__c> ssNList = new List<StaffSchedule__c>();
		ssNList = [select Id, WorkDay__c from StaffSchedule__c];
		ssNList[0].WorkDay__c = s2;
		ssNList[0].StatusLst__c = '09:00';

		update ssNList;
    }
    static testMetHod void case03() {
		Profile p = [select id from profile limit 1];

		createWorkDefine();

		User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	loginUser.ShopCode__c = null;
    	update loginUser;
    	system.runAs(loginUser) {
		TimeManagement__c tmItem = new TimeManagement__c(
						WorkDay__c = Date.today());
		List<TimeManagement__c> tm = new List<TimeManagement__c>();
		tmItem.WorkerRef__c = loginUser.id;
		tm.add(tmItem);
		insert tm;

		StaffSchedule__c ssItem = new StaffSchedule__c(
		 				WorkDay__c = Date.today(),StaffUserRef__c = loginUser.Id,StatusLst__c = 'TEST');
		List<StaffSchedule__c> ssList = new List<StaffSchedule__c>();
		ssList.add(ssItem);
		// 2015/12/01 Assert BEGIN
		System.assertEquals(ssList.size(), 1);
		// 2015/12/01 Assert END
		insert ssList;
    	}
    }
    static testMetHod void case04() {
		Profile p = [select id from profile limit 1];

		User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	loginUser.ShopCode__c = null;
    	update loginUser;

		StaffSchedule__c ssItem = new StaffSchedule__c(
		 				WorkDay__c = Date.today(),StaffUserRef__c = loginUser.Id);
		List<StaffSchedule__c> ssList = new List<StaffSchedule__c>();
		ssList.add(ssItem);
		// 2015/12/01 Assert BEGIN
		System.assertEquals(ssList.size(), 1);
		// 2015/12/01 Assert END
		insert ssList;

		Date s1 = Date.today();
		Date s2 = s1.addDays(-10);

		List<StaffSchedule__c> ssNList = new List<StaffSchedule__c>();
		ssNList = [select Id, WorkDay__c from StaffSchedule__c];
		ssNList[0].WorkDay__c = s2;
		ssNList[0].StatusLst__c = 'TEST';

		update ssNList;
    }
    static testMetHod void case05() {
		Profile p = [select id from profile limit 1];

		createWorkDefine();

		User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	loginUser.ShopCode__c = null;
    	update loginUser;
    	system.runAs(loginUser) {
		TimeManagement__c tmItem = new TimeManagement__c(
						WorkDay__c = Date.today());
		List<TimeManagement__c> tm = new List<TimeManagement__c>();
		tmItem.WorkerRef__c = loginUser.id;
		tm.add(tmItem);
		insert tm;

		StaffSchedule__c ssItem = new StaffSchedule__c(
		 				WorkDay__c = Date.today(),StaffUserRef__c = loginUser.Id,StatusLst__c = '09:30');
		List<StaffSchedule__c> ssList = new List<StaffSchedule__c>();
		ssList.add(ssItem);
		// 2015/12/01 Assert BEGIN
		System.assertEquals(ssList.size(), 1);
		// 2015/12/01 Assert END
		insert ssList;
    	}
    }
    static testMetHod void case06() {
		Profile p = [select id from profile limit 1];

		User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	loginUser.ShopCode__c = null;
    	update loginUser;

		StaffSchedule__c ssItem = new StaffSchedule__c(
		 				WorkDay__c = Date.today(),StaffUserRef__c = loginUser.Id);
		List<StaffSchedule__c> ssList = new List<StaffSchedule__c>();
		ssList.add(ssItem);
		// 2015/12/01 Assert BEGIN
		System.assertEquals(ssList.size(), 1);
		// 2015/12/01 Assert END
		insert ssList;

		Date s1 = Date.today();
		Date s2 = s1.addDays(-10);

		List<StaffSchedule__c> ssNList = new List<StaffSchedule__c>();
		ssNList = [select Id, WorkDay__c from StaffSchedule__c];
		ssNList[0].WorkDay__c = s2;
		ssNList[0].StatusLst__c = '09:30';

		update ssNList;
    }
    static testMetHod void case07() {
		Profile p = [select id from profile limit 1];

		User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	loginUser.ShopCode__c = null;
    	update loginUser;

		StaffSchedule__c ssItem = new StaffSchedule__c(
		 				WorkDay__c = Date.today(),StaffUserRef__c = loginUser.Id);
		List<StaffSchedule__c> ssList = new List<StaffSchedule__c>();
		ssList.add(ssItem);
		// 2015/12/01 Assert BEGIN
		System.assertEquals(ssList.size(), 1);
		// 2015/12/01 Assert END
		insert ssList;

		List<StaffSchedule__c> ssNList = new List<StaffSchedule__c>();
		ssNList = [select Id, WorkDay__c from StaffSchedule__c];
		ssNList[0].StatusLst__c = '';

		update ssNList;
    }
    static testMetHod void case08() {
		Profile p = [select id from profile limit 1];

		User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	loginUser.ShopCode__c = null;
    	update loginUser;

		StaffSchedule__c ssItem = new StaffSchedule__c(
		 				WorkDay__c = Date.today(),StaffUserRef__c = loginUser.Id,StatusLst__c = '09:30');
		List<StaffSchedule__c> ssList = new List<StaffSchedule__c>();
		ssList.add(ssItem);
		// 2015/12/01 Assert BEGIN
		System.assertEquals(ssList.size(), 1);
		// 2015/12/01 Assert END
		insert ssList;

		Test.startTest();
		List<StaffSchedule__c> ssNList = new List<StaffSchedule__c>();
		ssNList = [select Id from StaffSchedule__c where id = :ssList[0].Id];

		delete ssNList[0];
		Test.stopTest();
    }
    private static void createWorkDefine() {
    	WorkTimeDefine__c newItem = new WorkTimeDefine__c(Name = '共通(削除禁止)');
    	insert newItem;
    }
}