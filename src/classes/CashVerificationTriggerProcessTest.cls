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
private class CashVerificationTriggerProcessTest {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
	RsvAccount__c rsv = TestCommon.createRsvAccount();
		delete [select id from CommDefine__c];
		CommDefine__c newDef = new CommDefine__c(
			ItemChangeHistoryAutoCreateFlg__c = true
		);	
		insert newDef;		
	CashVerification__c cash = new CashVerification__c(	 	
		RsvAccountRef__c = rsv.Id,
        SearchKey__c = '住友銀行',
		CashSales__c = 1 );
		insert cash;
		List<CashVerification__c> Cashlst = [select id, CashSales__c,RsvAccountRef__c from CashVerification__c where SearchKey__c = '住友銀行'];
		System.assert(!Cashlst.isEmpty());
   		for (CashVerification__c acc : [select RsvAccountRef__c, SearchKey__c, CashSales__c from CashVerification__c]) {
			System.assertEquals(acc.RsvAccountRef__c,rsv.Id);
			System.assertEquals(acc.SearchKey__c,'住友銀行');
			System.assertEquals(acc.CashSales__c,1);			
		}
		List<ItemChangeHistory__c> syncTargetLst = [select History__c from ItemChangeHistory__c ] ;
		System.assert(syncTargetLst.size() == 1);
		//System.debug(loggingLevel.INFO, 'syncTargetLst::::::=====>>insert=====>>'+syncTargetLst);
	cash.SearchKey__c='CA';
	cash.CashSales__c = 2 ;
      	update cash;
  		for (CashVerification__c acc : [select RsvAccountRef__c, SearchKey__c, CashSales__c from CashVerification__c]) {
			System.assertEquals(acc.RsvAccountRef__c,rsv.Id);
			System.assertEquals(acc.SearchKey__c,'CA');
			System.assertEquals(acc.CashSales__c,2);
		}
		List<ItemChangeHistory__c> upItemLst = [select History__c from ItemChangeHistory__c ] ;
		System.assert(upItemLst.size() == 2);
		//System.debug(loggingLevel.INFO, 'upItemLst::::::=====>>update=====>>'+upItemLst);
		update cash;
		for (CashVerification__c acc : [select RsvAccountRef__c, SearchKey__c, CashSales__c from CashVerification__c]) {
			System.assertEquals(acc.RsvAccountRef__c,rsv.Id);
			System.assertEquals(acc.SearchKey__c,'CA');
			System.assertEquals(acc.CashSales__c,2);
		}
		List<ItemChangeHistory__c> ItemLst = [select History__c from ItemChangeHistory__c ] ;
		System.assert(ItemLst.size() == 2);
		//System.debug(loggingLevel.INFO, 'ItemLst::::::=====>>update=====>>'+ItemLst);
    }
    
}