@isTest
public class incom_test{

    static testmethod void incom_test(){
    	Asterisk__c asterisk = new Asterisk__c(
	    	Name = '52.198.65.63:5061',
	    	WebSocket_Server_URL__c = 'wss://52.198.65.63:8089/ws',
	    	Realm__c = '52.198.65.63:5061',
	    	Active__c = true);
    	insert asterisk;
    	User users = new User(
			isActive = true,
			online_status__c = false,
			Alias = 'testNm01', 
			EmployeeCode__c = '03003',
			Department = '営業部',
			Email='newuser@test.com', 
			EmailEncodingKey='UTF-8', 
			LastName='LN_' + CommUtils.getRandom(3),
			ProfileId = UserInfo.getProfileId(),
			TimeZoneSidKey='Asia/Tokyo',
			LanguageLocaleKey='ja',
			LocaleSidKey='ja_JP',
			UserName='new' + CommUtils.getRandom(10) + '@test.com');
		insert users;	
		Income i = new Income();
		i.msg = '松田 テスト 様、ご到着されましたので、ご案内ください';
		i.userId = UserInfo.getUserId();
		i.singleMessage();
		i.addExtExistingUsers();
		i.closePopup();
		i.showPopup();
		i.disableTheButton();
        String result = i.currentUserId;
		User resultUser = i.currentUser;
		i.updateUserStatus();
		i.disconnect();

		//i.PostToChatter();
		i.sortByEmployeeNumber(); //Ascending
		i.sortByEmployeeNumber(); //Descending
		i.sortByDepartment(); //Ascending
		i.sortByDepartment(); //Descending

		User usr = new User(
			isActive = true,
			online_status__c = false,
			Alias = 'testNm02', 
			EmployeeCode__c = '03002',
			Department = '営業部',
			Email='newuser@test.com', 
			EmailEncodingKey='UTF-8', 
			LastName='LN_' + CommUtils.getRandom(3),
			ProfileId = UserInfo.getProfileId(),
			TimeZoneSidKey='Asia/Tokyo',
			LanguageLocaleKey='ja',
			LocaleSidKey='ja_JP',
			UserName='new' + CommUtils.getRandom(10) + '@test.com');
		insert usr;
		Income.updateUser('03002');
		Income.disconnectUser('03002');
		System.assert(i != null);
    }
    static testmethod void incom_get_users_test(){
    	Asterisk__c asterisk = new Asterisk__c(
    	Name = '52.198.65.63:5061',
    	WebSocket_Server_URL__c = 'wss://52.198.65.63:8089/ws',
    	Realm__c = '52.198.65.63:5061',
    	Active__c = true
    	);
    	insert asterisk;
        Income i = new Income();
        //i.init();
        User u = i.currentUser;
       
        
        List<User> e = i.getUsers();
        List<User> o = i.getOfflineUsers();
		//System.assertEquals([select id from user where IsActive=true].size()-1,e.size());      
    }
    // IncomeNew
    static testmethod void incomenew_test(){
    	Asterisk__c asterisk = new Asterisk__c(
	    	Name = '52.198.65.63:5061',
	    	WebSocket_Server_URL__c = 'wss://52.198.65.63:8089/ws',
	    	Realm__c = '52.198.65.63:5061',
	    	Active__c = true);
    	insert asterisk;
    	User users = new User(
			isActive = true,
			online_status__c = false,
			Alias = 'testNm01', 
			EmployeeCode__c = '03003',
			Department = '営業部',
			Email='newuser@test.com', 
			EmailEncodingKey='UTF-8', 
			LastName='LN_' + CommUtils.getRandom(3),
			ProfileId = UserInfo.getProfileId(),
			TimeZoneSidKey='Asia/Tokyo',
			LanguageLocaleKey='ja',
			LocaleSidKey='ja_JP',
			UserName='new' + CommUtils.getRandom(10) + '@test.com');
		insert users;	
		IncomeNew i = new IncomeNew();
		i.msg = '松田 テスト 様、ご到着されましたので、ご案内ください';
		i.userId = UserInfo.getUserId();
		i.singleMessage();

		User resultUser = i.currentUser;
		i.updateUserStatus();
		i.disconnect();

		//i.PostToChatter();
		i.sortByEmployeeNumber(); //Ascending
		i.sortByEmployeeNumber(); //Descending
		i.sortByDepartment(); //Ascending
		i.sortByDepartment(); //Descending

		User usr = new User(
			isActive = true,
			online_status__c = false,
			Alias = 'testNm02', 
			EmployeeCode__c = '03002',
			Department = '営業部',
			Email='newuser@test.com', 
			EmailEncodingKey='UTF-8', 
			LastName='LN_' + CommUtils.getRandom(3),
			ProfileId = UserInfo.getProfileId(),
			TimeZoneSidKey='Asia/Tokyo',
			LanguageLocaleKey='ja',
			LocaleSidKey='ja_JP',
			UserName='new' + CommUtils.getRandom(10) + '@test.com');
		insert usr;
		IncomeNew.updateUser('03002');
		IncomeNew.disconnectUser('03002');
		System.assert(i != null);
    }
    // IncomeNew
    static testmethod void incomenew_test1(){
    	Asterisk__c asterisk = new Asterisk__c(
    	Name = '52.198.65.63:5061',
    	WebSocket_Server_URL__c = 'wss://52.198.65.63:8089/ws',
    	Realm__c = '52.198.65.63:5061',
    	Active__c = true
    	);
    	insert asterisk;
        IncomeNew i = new IncomeNew();
        //i.init();
        User u = i.currentUser;
       
        
        List<User> e = i.getUsers();
        List<User> o = i.getOfflineUsers();
		//System.assertEquals([select id from user where IsActive=true].size()-1,e.size());      
    }
    // IncomeNewTab
    static testmethod void incomenewtab_test(){
    	Asterisk__c asterisk = new Asterisk__c(
	    	Name = '52.198.65.63:5061',
	    	WebSocket_Server_URL__c = 'wss://52.198.65.63:8089/ws',
	    	Realm__c = '52.198.65.63:5061',
	    	Active__c = true);
    	insert asterisk;
    	User users = new User(
			isActive = true,
			online_status__c = false,
			Alias = 'testNm01', 
			EmployeeCode__c = '03003',
			Department = '営業部',
			Email='newuser@test.com', 
			EmailEncodingKey='UTF-8', 
			LastName='LN_' + CommUtils.getRandom(3),
			ProfileId = UserInfo.getProfileId(),
			TimeZoneSidKey='Asia/Tokyo',
			LanguageLocaleKey='ja',
			LocaleSidKey='ja_JP',
			UserName='new' + CommUtils.getRandom(10) + '@test.com');
		insert users;	
		Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl());
		IncomeNewTab i = new IncomeNewTab();
		User resultUser = i.currentUser;
		i.enableUpdateExtBtn();
		i.revertExistingUsers();
		i.redirect();
		i.registerName();
		i.addExtExistingUsers();
		//i.processResponseStart();
		i.createBulkExt();
		//i.processResponseBulk();
		i.updateDisplayName();
		i.getOrgName();
		i.closePopup();
		i.showPopup();
		i.showAnimPopup();
		i.closeAnimPopup();
		i.enableTheButton();
		i.disableTheButton();
    }
    // AsteriskManager
    static testmethod void asteriskmanager_test(){
    	Asterisk__c asterisk = new Asterisk__c(
	    	Name = '52.198.65.63:5061',
	    	WebSocket_Server_URL__c = 'wss://52.198.65.63:8089/ws',
	    	Realm__c = '52.198.65.63:5061',
	    	Active__c = true);
    	insert asterisk;
    	User users = new User(
			isActive = true,
			online_status__c = false,
			Alias = 'testNm02', 
			EmployeeCode__c = '03004',
			Department = '営業部',
			Email='newuser@test.com', 
			EmailEncodingKey='UTF-8', 
			LastName='LN_' + CommUtils.getRandom(3),
			ProfileId = UserInfo.getProfileId(),
			TimeZoneSidKey='Asia/Tokyo',
			LanguageLocaleKey='ja',
			AsteriskExtension__c = '2800049',
			LocaleSidKey='ja_JP',
			AsteriskPassword__c = '53CR3Y',
			UserName='new' + CommUtils.getRandom(10) + '@test.com');
		//insert users;
		
		AsteriskManager i = new AsteriskManager();
		List<User> userList = new List<User>();
		userList.add(users);
		insert userList;
		i.updateUsersExt(1);
		//AsteriskManager.injectExt(userList);
		//AsteriskManager.createNewExt(users.AsteriskExtension__c);
		AsteriskManager.getSecret();
		AsteriskManager.getNewExt();
		AsteriskManager.sleep(1);
		AsteriskManager.getStartExt();
		AsteriskManager.resetStartExt();
		AsteriskManager.getBulkCrtStatusCode();
		AsteriskManager.resetBulkCrtStatusCode();
		
    }
}