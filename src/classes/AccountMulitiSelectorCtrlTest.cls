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
private class AccountMulitiSelectorCtrlTest {

	static testMethod void testMulitiEvent() {
		// マージ元の取引先情報を作成する
		Account FrAccounts = TestCommon.createNormalAccount();
		// 下記の取引先の関連情報はマージ元(FrAccounts)にコピーする
		Account ToAccounts = FrAccounts.clone(false,true);
		insert ToAccounts;
		Id toAccountId = ToAccounts.Id;
		Id [] fixedSearchResults= new Id[1];
       	fixedSearchResults[0] = toAccountId;
		Test.setFixedSearchResults(fixedSearchResults);
		// お客様
		Contact contacts = TestCommon.createContact();
		contacts.AccountId = ToAccounts.Id;
		update contacts;
		// 活動予定
		Event newEvent = new Event(
			Subject = 'Send Letter',
			WhatId = toAccountId ,
			DurationInMinutes = 30 ,
			ActivityDateTime = System.now().addDays(2)
		);
		insert newEvent;
		Task newTask = new Task(
			Subject = 'Send Letter-Task',
			WhatId = toAccountId
		);
		insert newTask;
		ActivityRefAccount__c todoAcc = new ActivityRefAccount__c(
			AccountMainRef__c = toAccountId,
			AccountSubRef__c = toAccountId
		);
		insert todoAcc;
		
		List<Id> delId = new List<Id>();
		delId.add(todoAcc.AccountMainRef__c);
		List<String> accName = new List<String>();
		List<Id> accId = new List<Id>();
		List<Account> delAccs = [select id,Name from Account where Id = :toAccountId];
		for(Account acc : delAccs){
			accName.add(acc.Name);
			accId.add(acc.Id);
		}
		Test.startTest();
		// マージ初期化確認
		Apexpages.currentPage().getParameters().put('Id',newEvent.Id);
		AccountMulitiSelectorCtrl ctrl = new AccountMulitiSelectorCtrl();
		// 初期化
		ctrl.accQueryKey = '1';
		ctrl.init();
		AccountMulitiSelectorCtrl.saveSelectAccounts(accName,newEvent.Id,accId);
		ctrl.nameSearch();
		Test.stopTest();
	}
	static testMethod void testMulitiTask() {
		// マージ元の取引先情報を作成する
		Account FrAccounts = TestCommon.createNormalAccount();
		// 下記の取引先の関連情報はマージ元(FrAccounts)にコピーする
		Account ToAccounts = FrAccounts.clone(false,true);
		insert ToAccounts;
		Id toAccountId = ToAccounts.Id;
		Id [] fixedSearchResults= new Id[1];
       	fixedSearchResults[0] = toAccountId;
		Test.setFixedSearchResults(fixedSearchResults);
		// お客様
		Contact contacts = TestCommon.createContact();
		contacts.AccountId = ToAccounts.Id;
		update contacts;
		// 活動予定
		Event newEvent = new Event(
			Subject = 'Send Letter',
			WhatId = toAccountId ,
			DurationInMinutes = 30 ,
			ActivityDateTime = System.now().addDays(2)
		);
		insert newEvent;
		Task newTask = new Task(
			Subject = 'Send Letter-Task',
			WhatId = toAccountId
		);
		insert newTask;
		
		List<String> accName = new List<String>();
		List<Id> accId = new List<Id>();
		List<Account> delAccs = [select id,Name from Account where Id = :toAccountId];
		for(Account acc : delAccs){
			accName.add(acc.Name);
			accId.add(acc.Id);
		}
		Test.startTest();
		// マージ初期化確認
		Apexpages.currentPage().getParameters().put('Id',newTask.Id);
		AccountMulitiSelectorCtrl ctrl = new AccountMulitiSelectorCtrl();
		// 初期化
		ctrl.accQueryKey = '日本';
		ctrl.init();
		AccountMulitiSelectorCtrl.saveSelectAccounts(accName,newTask.Id,accId);
		ctrl.nameSearch();
		Test.stopTest();
	}
	static testMethod void testMulitiTask1() {
		// マージ元の取引先情報を作成する
		Account FrAccounts = TestCommon.createNormalAccount();
		// 下記の取引先の関連情報はマージ元(FrAccounts)にコピーする
		Account ToAccounts = FrAccounts.clone(false,true);
		insert ToAccounts;
		Id toAccountId = ToAccounts.Id;
		Id [] fixedSearchResults= new Id[1];
       	fixedSearchResults[0] = toAccountId;
		Test.setFixedSearchResults(fixedSearchResults);
		// お客様
		Contact contacts = TestCommon.createContact();
		contacts.AccountId = ToAccounts.Id;
		update contacts;
		// 活動予定
		Event newEvent = new Event(
			Subject = 'Send Letter',
			WhatId = toAccountId ,
			DurationInMinutes = 30 ,
			ActivityDateTime = System.now().addDays(2)
		);
		insert newEvent;
		Task newTask = new Task(
			Subject = 'Send Letter-Task',
			WhatId = toAccountId
		);
		insert newTask;
		Account newItems = new Account(
    		Name = 'テスト会社s' + CommUtils.getRandom(10),
    		Phone= CommUtils.getRandom(10),
    		Fax  = CommUtils.getRandom(10)
    	);
    	insert newItems;
    	newTask.WhatId = newItems.Id;
    	update newTask;
    	delete newEvent;
		
		List<String> accName = new List<String>();
		List<Id> accId = new List<Id>();
		List<Account> delAccs = [select id,Name from Account where Id = :toAccountId];
		for(Account acc : delAccs){
			accName.add(acc.Name);
			accId.add(acc.Id);
		}
		Test.startTest();
		// マージ初期化確認
		Apexpages.currentPage().getParameters().put('Id',newTask.Id);
		AccountMulitiSelectorCtrl ctrl = new AccountMulitiSelectorCtrl();
		// 初期化
		ctrl.accQueryKey = '日本';
		ctrl.init();
		AccountMulitiSelectorCtrl.saveSelectAccounts(accName,newTask.Id,accId);
		ctrl.nameSearch();
		Test.stopTest();
	}
}