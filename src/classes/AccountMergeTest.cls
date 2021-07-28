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
private class AccountMergeTest {
	@isTest(SeeAllData=false)
	static void testMergeListChk() {
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
		// 商談
		Opportunity opps = new Opportunity(
			Name = '商談情報' + CommUtils.getRandom(10),
			CloseDate = Date.today(),
			StageName = 'Prospecting',
			AccountId = toAccountId
		);
		insert opps;
		// ケース
		Case newCase = new Case(
			Origin = 'Phone',
			AccountId = toAccountId
		);
		insert newCase;
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
		// メモ & 添付ファイル
		Note newNote = new Note (
			ParentId = toAccountId,
			Title    = 'NoteTitle'
		);
		insert newNote;
		
		Blob attBlog = Blob.valueOf('AttText Test Content');
		Attachment newAttach = new Attachment(
			ParentId = toAccountId,
			Name = 'TestJsFile',
			ContentType = 'application/x-javascript',
			Body = attBlog
		);
		insert newAttach;
		// Call_information__c
		Call_information__c newCall = new Call_information__c(
			Account__c = toAccountId,
			SNO__c = '0123456789'
		);
		insert newCall;
		// 予約関連[請求先]
		Lead__c reqLead = TestCommon.createBookingLead(Date.today(), null, 1);
		reqLead.refAccount__c = toAccountId;
		update reqLead;
		// 予約関連[旅行会社情報]
		Lead__c travLead = TestCommon.createBookingLead(Date.today(), null, 1);
		travLead.SalesOfficeInfoRef__c = toAccountId;
		update travLead;
		// プランのAGT
		Plan__c plan = TestCommon.createPlan();
		plan.client__c = toAccountId;
		update plan;
		// リアルAGTのAGT
		RealAGT__c agt = new RealAGT__c(
			AccountRef__c = toAccountId,
			AgtMaxRooms__c = 10,
			EndDate__c = Date.today().addDays(10),
			StartDate__c = Date.today()
		);
		insert agt;
		// 契約[Contract]
		Contract newCon = new Contract(
			AccountId = toAccountId,
			StartDate = Date.today(),
			ContractTerm = 3
		);
		insert newCon;
		// 仕入[Purchase__c][仕入先]
		RsvAccount__c rsv = TestCommon.createRsvAccount();
		Purchase__c newPur = new Purchase__c(
			JinyaRevenue__c = rsv.Id,
			Purchasesource__c = toAccountId,
			Denpyoukei__c = 1200000
		);
		insert newPur;
		
		Test.startTest();
		// マージ初期化確認
		ApexPages.currentPage().getParameters().put('Id',FrAccounts.Id);
		ApexPages.StandardController scc = new ApexPages.StandardController(FrAccounts);
		AccountMerge ctrl = new AccountMerge(scc);
		// 初期化
		ctrl.initAction();
		ctrl.queryConcatInfo();
		List<Account> acc = ctrl.queryRs;
		System.assertEquals(acc.size(), 1, acc);
		// マージ処理を行う
		ctrl.newContactId = FrAccounts.Id;
		ctrl.oldcontactId = ToAccounts.Id;
		// マージ処理実施
		ctrl.mergerRelList();
		Id newId = FrAccounts.Id;
		// 処理結果を確認する
		List<Contact> newContacts = [select id, AccountId from Contact where AccountId = :newId];
		List<Opportunity> newOpps = [select AccountId from Opportunity where AccountId = :newId];
		List<Case> newCases       = [select AccountId from Case where AccountId = :newId];
		List<Event> newEvents     = [select WhatId from Event where WhatId = :newId];
		List<Task> newTasks       = [select WhatId from Task where WhatId = :newId];
		List<Note> newNotse       = [select ParentId from Note where ParentId = :newId];
		List<Attachment> newAtts  = [select ParentId from Attachment where ParentId = :newId];
		List<Call_information__c> newCalls = [Select Id,Account__c from Call_information__c where Account__c = :newId];
		List<Lead__c> newLead1    = [select Id, refAccount__c from Lead__c where refAccount__c = :newId];
		List<Lead__c> newLead2    = [select Id, SalesOfficeInfoRef__c from Lead__c where SalesOfficeInfoRef__c = :newId];
		List<Plan__c> newPlans    = [select Id, client__c from Plan__c where client__c = :newId];
		List<RealAGT__c> newAgts  = [select Id, AccountRef__c from RealAGT__c where AccountRef__c = :newId];
		List<Contract> newContrs  = [select Id, AccountId from Contract where AccountId = :newId];
		List<Purchase__c> newPurs = [select Id, Purchasesource__c from Purchase__c where Purchasesource__c = :newId];
		
		System.assertEquals(newContacts.size(), 1);
		System.assertEquals(newOpps.size(), 1);
		System.assertEquals(newCases.size(), 1);
		System.assertEquals(newEvents.size(), 1);
		System.assertEquals(newTasks.size(), 1);
		System.assertEquals(newNotse.size(), 1);
		System.assertEquals(newAtts.size(), 1);
		System.assertEquals(newCalls.size(), 1);
		
		System.assertEquals(newLead1.size(), 1);
		System.assertEquals(newLead2.size(), 1);
		System.assertEquals(newPlans.size(), 1);
		System.assertEquals(newAgts.size(), 1);
		System.assertEquals(newContrs.size(), 1);
		System.assertEquals(newPurs.size(), 1);
		
		List<Account> delAccs = [select id from Account where Id = :toAccountId];
		System.assert(delAccs.isEmpty());
		Test.stopTest();
	}
	// テストクラス実施
	@isTest(SeeAllData=false)
	static void testMergeFieldChk() {
		// マージ元の取引先情報を作成する
		Account FrAccounts = TestCommon.createNormalAccount();
		// 下記の取引先の関連情報はマージ元(FrAccounts)にコピーする
		Account ToAccounts = FrAccounts.clone(false,true);
		ToAccounts.phone = CommUtils.getRandom(10);
		ToAccounts.fax = CommUtils.getRandom(10);
		insert ToAccounts;
		Test.startTest();
		// マージ初期化確認
		ApexPages.currentPage().getParameters().put('Id',FrAccounts.Id);
		ApexPages.StandardController scc = new ApexPages.StandardController(FrAccounts);
		AccountMerge ctrl = new AccountMerge(scc);
		// 初期化
		ctrl.initAction();
		ctrl.queryConcatInfo();
		List<Account> acc = ctrl.queryRs;
		
		ApexPages.currentPage().getParameters().put('nwid',FrAccounts.Id);
		ApexPages.currentPage().getParameters().put('odid',ToAccounts.Id);
		
		ApexPages.StandardController scc2 = new ApexPages.StandardController(FrAccounts);
		AccountMerge ctrl2 = new AccountMerge(scc2);
		ctrl2.initMergetFieldPage();
		
		AccountMerge.mergetContatInfo(FrAccounts.Id, ToAccounts.Id, 'phone,fax','phone,fax');
		ctrl2.readContactInf();
		Account newContact = ctrl2.newContact;
		Account oldContact = ctrl2.oldContact;
		System.assertEquals(newContact.fax, oldContact.fax);
		System.assertEquals(newContact.phone, oldContact.phone);
		
		ApexPages.currentPage().getParameters().put('nwid',null);
		ApexPages.currentPage().getParameters().put('odid',ToAccounts.Id);
		ApexPages.StandardController scc3 = new ApexPages.StandardController(FrAccounts);
		AccountMerge ctrl3 = new AccountMerge(scc3);
		ctrl3.initMergetFieldPage();
		ApexPages.currentPage().getParameters().put('nwid',FrAccounts.Id);
		ApexPages.currentPage().getParameters().put('odid',null);
		ApexPages.StandardController scc4 = new ApexPages.StandardController(FrAccounts);
		AccountMerge ctrl4 = new AccountMerge(scc4);
		ctrl4.initMergetFieldPage();
	}
}