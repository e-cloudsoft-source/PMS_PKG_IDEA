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
private class ExpoLookupCtrlTest {

	static testMethod void myUnitTest() {
		ExpoCommonTest.createEmptyDoc();
		// TO DO: implement unit test
		ExpoLookupCtrl ctrl = new ExpoLookupCtrl();
		String prefix = AccountMaster__c.sObjectType.getDescribe().getKeyPrefix();
		Apexpages.currentPage().getParameters().put('lksrch',prefix);
		Apexpages.currentPage().getParameters().put('prefix',prefix);
		/*
		Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
		//Loop through all the sObject types returned by Schema
		for(Schema.SObjectType stype : gd.values()){
			Schema.DescribeSObjectResult r = stype.getDescribe();
			if(r == null) continue;
			String prefix = CommUtils.nullToBlank(r.getKeyPrefix());
			Apexpages.currentPage().getParameters().put('prefix', prefix);
			break;
		}*/
		
		ctrl.searchMode = 'ALL';
		ctrl.init();
		ctrl.queryInfo();
		if(ctrl.pageCtrl != null){
			ctrl.nextPage();
			ctrl.lastPage();
			ctrl.previousPage();
			ctrl.firstPage();
		}
		ctrl.cancelAct();
	}
	static testMethod void myUnitTest1() {
		// TO DO: implement unit test
		ExpoLookupCtrl ctrl = new ExpoLookupCtrl();
		String prefix = AccountMaster__c.sObjectType.getDescribe().getKeyPrefix();
		Apexpages.currentPage().getParameters().put('lksrch',prefix);
		//Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
		//Loop through all the sObject types returned by Schema
		String sobjName = 'AccountMaster__c';
		/*
		for(Schema.SObjectType stype : gd.values()){
			Schema.DescribeSObjectResult r = stype.getDescribe();
			if(r == null) continue;
			String prefix = CommUtils.nullToBlank(r.getKeyPrefix());
			Apexpages.currentPage().getParameters().put('prefix', prefix);
			sobjName = r.getName();
			break;
		}*/
		String body = '<?xml version="1.0" encoding="UTF-8"?><root>	<SHOP>	<SHOPCODE> </SHOPCODE>' +
    	'<LOOKUPLAYOUT>' +
    	'	<LAYOUT>' +
    	'	<SOBJECT>' +
    	+ sobjName +
    	'	</SOBJECT>' +
    	'	<FIELDS>' +
    	'	Id,Name' +
    	'	</FIELDS>' +
    	'	</LAYOUT>' +
    	'</LOOKUPLAYOUT>' +
    	'</SHOP></root>';
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'ExpoServiceConfig';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(body);
    	insert item;
		ctrl.searchMode = 'NAME';
		ctrl.init();
		ctrl.queryInfo();
		if(ctrl.pageCtrl != null){
			ctrl.nextPage();
			ctrl.lastPage();
			ctrl.previousPage();
			ctrl.firstPage();
		}
	}
	static testMethod void myUnitTest2() {
		// マージ元の取引先情報を作成する
		Account FrAccounts = TestCommon.createNormalAccount();
		// TO DO: implement unit test
		ExpoLookupCtrl ctrl = new ExpoLookupCtrl();
		Apexpages.currentPage().getParameters().put('lksrch','');
		//Loop through all the sObject types returned by Schema
		Schema.DescribeSObjectResult d = Account.sObjectType.getDescribe();
		Apexpages.currentPage().getParameters().put('prefix', CommUtils.nullToBlank(d.getKeyPrefix()));
		String body = '<?xml version="1.0" encoding="UTF-8"?><root>	<SHOP>	<SHOPCODE> </SHOPCODE>' +
    	'<LOOKUPLAYOUT>' +
    	'	<LAYOUT>' +
    	'	<SOBJECT>' +
    	'	Account' +
    	'	</SOBJECT>' +
    	'	<FIELDS>' +
    	'	Id,Name,Phone' +
    	'	</FIELDS>' +
    	'	</LAYOUT>' +
    	'</LOOKUPLAYOUT>' +
    	'</SHOP></root>';
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'ExpoServiceConfig';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(body);
    	insert item;
		ctrl.searchMode = 'NAME';
		ctrl.init();
		ctrl.queryInfo();
		ctrl.nextPage();
		ctrl.lastPage();
		ctrl.previousPage();
		ctrl.firstPage();
	}
}