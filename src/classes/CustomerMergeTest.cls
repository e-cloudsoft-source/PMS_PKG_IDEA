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
private class CustomerMergeTest {

    @isTest(SeeAllData=false)
	static void testMergeListChk() {
		List<Document> sr = [select body, name from Document where DeveloperName = 'ContactInfoMergeFields'];
		
		String configXml = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP><SHOPCODE></SHOPCODE><MODE><TYPE>ADD</TYPE><FIELDS><FIELD>Usage_Charge__c</FIELD><FIELD>Usage_Count__c</FIELD></FIELDS></MODE><VIEWLISTFIELDS>Id:Name,ID__c:,DelFlg__c:削除区分,Birthdate:誕生日,Department:部署</VIEWLISTFIELDS></SHOP></root>';
		if (sr.isEmpty()) {
			Document newDoc = new Document(
				Name = 'ContactInfoMergeFields',
				DeveloperName = 'ContactInfoMergeFields',
				body = Blob.valueOf(configXml),
				FolderId = UserInfo.getUserId()
			);
			insert newDoc;
 		} else {
			sr[0].Body = Blob.valueOf(configXml);
			update sr;
 		}
		Contact newC = TestCommon.createContact();
		Contact oldC = TestCommon.createContact();
		oldC.LastName = 'MergetName';
		oldC.FirstName = 'OK';
		newC.LastName = oldC.LastName;
		newC.FirstName = oldC.FirstName;
		oldC.Phone = '03-1111-2222';
		newC.Phone = oldC.Phone;
		update newC;
		Database.DMLOptions dml = new Database.DMLOptions();
		dml.DuplicateRuleHeader.AllowSave = true;
		Database.SaveResult sr2 = Database.update(oldC, dml);
		List<Id> idLst = new List<Id>();
		idLst.add(newC.Id);
		idLst.add(oldC.Id);
		Test.setFixedSearchResults(idLst);
		ApexPages.StandardController scc = new ApexPages.StandardController(newC);
		CustomerMerge mergeCtrl = new CustomerMerge(scc);
		mergeCtrl.initAction();
		// 検索結果確認する
		List<Contact> contacts = mergeCtrl.contacts;
		System.assertEquals(contacts.size(), 1);
		mergeCtrl.findKey = oldC.LastName;
		mergeCtrl.queryConcatInfo();
		Test.startTest();
		mergeCtrl.oldContactId = oldC.Id;
		mergeCtrl.newContactId = newC.Id;
		// mergeCtrl.mergerRelList();
		
		Test.stopTest();
		List<Contact> mergeOld = [select isDelete__c,MergeNewId__c from contact where id = :oldC.Id];
		/*
		System.assert(mergeOld.isDelete__c);
		System.assertEquals(mergeOld.MergeNewId__c, newC.Id);
		*/
		System.assert(!mergeOld.isEmpty());
		mergeCtrl.findKey = '1';
		mergeCtrl.queryConcatInfo();
		
		
		System.assert(ApexPages.hasMessages(ApexPages.Severity.Error));
		mergeCtrl.gotoBack();
	}

	@isTest(SeeAllData=false)
	static void testMergetContatInfo() {

		List<Document> sr = [select body, name from Document where DeveloperName = 'ContactInfoMergeFields'];
		
		String configXml = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP><SHOPCODE></SHOPCODE><MODE><TYPE>ADD</TYPE><FIELDS><FIELD>Usage_Charge__c</FIELD><FIELD>Usage_Count__c</FIELD></FIELDS></MODE></SHOP></root>';
		if (sr.isEmpty()) {
			Document newDoc = new Document(
				Name = 'ContactInfoMergeFields',
				DeveloperName = 'ContactInfoMergeFields',
				body = Blob.valueOf(configXml),
				FolderId = UserInfo.getUserId()
			);
			insert newDoc;
 		} else {
			sr[0].Body = Blob.valueOf(configXml);
			update sr;
 		}
		
		Contact newC = TestCommon.createContact();
		Contact oldC = TestCommon.createContact();
		newC.Memo1__c = 'M11_'+CommUtils.getRandom(10);
		newC.Memo2__c = 'M12_'+CommUtils.getRandom(10);
		newC.Memo3__c = 'M13_'+CommUtils.getRandom(10);
		newC.Memo4__c = 'M14_'+CommUtils.getRandom(10);
		newC.Memo5__c = 'M15_'+CommUtils.getRandom(10);
		newC.Memo6__c = 'M16_'+CommUtils.getRandom(10);
		oldC.Memo1__c = 'M21_'+CommUtils.getRandom(10);
		oldC.Memo2__c = 'M22_'+CommUtils.getRandom(10);
		oldC.Memo3__c = 'M23_'+CommUtils.getRandom(10);
		oldC.Memo4__c = 'M24_'+CommUtils.getRandom(10);
		oldC.Memo5__c = 'M25_'+CommUtils.getRandom(10);
		oldC.Memo6__c = 'M26_'+CommUtils.getRandom(10);
		update newC;
		update oldC;
		
		Test.startTest();
		ApexPages.currentPage().getParameters().put('nwid',newC.Id);
		ApexPages.currentPage().getParameters().put('odid',oldC.Id);
		ApexPages.StandardController ctrl = new ApexPages.StandardController (newC);
		CustomerMerge mergeCtrl = new CustomerMerge(ctrl);
		mergeCtrl.initMergetFieldPage();
		
		string mergeFields = 'Memo1__c,Memo2__c,Memo3__c,Memo4__c,Memo5__c';
		String constqueryFields = 'LastName,FirstName,Katakana__c,KanaName1__c,Name1__c,Phone';
		String modeTypes='REP,REP,REP,REP,REP,REP,REP,REP,REP,REP,REP';//上書き
		String rs = CustomerMerge.mergetContatInfo2(mergeCtrl.newContactId, mergeCtrl.oldContactId, constqueryFields + ',' +mergeFields, constqueryFields + ',' +mergeFields, modeTypes);
		System.assert(String.isEmpty(rs), rs);
		Id newId = newC.Id;
		Contact reNew = Database.query('Select ' + constqueryFields + ',' +mergeFields + ' From Contact Where id = :newId');
		System.assertEquals(reNew.LastName, oldC.LastName);
		System.assertEquals(reNew.FirstName, oldC.FirstName);
		System.assertEquals(reNew.Katakana__c, oldC.Katakana__c);
		System.assertEquals(reNew.KanaName1__c, oldC.KanaName1__c);
		System.assertEquals(reNew.Name1__c, oldC.Name1__c);
		System.assertEquals(reNew.Phone, oldC.Phone);
		
		System.assertEquals(reNew.Memo1__c, oldC.Memo1__c);
		System.assertEquals(reNew.Memo2__c, oldC.Memo2__c);
		System.assertEquals(reNew.Memo3__c, oldC.Memo3__c);
		System.assertEquals(reNew.Memo4__c, oldC.Memo4__c);
		System.assertEquals(reNew.Memo5__c, oldC.Memo5__c);
		//System.assertNotEquals(reNew.Memo6__c, oldC.Memo6__c);
	}
	@isTest(SeeAllData=false)
	static void testMergetContatInfo_3() {
		Contact newC = TestCommon.createContact();
		delete newC;
		ApexPages.StandardController scc = new ApexPages.StandardController(newC);
		CustomerMerge mergeCtrl = new CustomerMerge(scc);
		mergeCtrl.initAction();
		System.assert(mergeCtrl.initHaveErrFlg);
	}
}