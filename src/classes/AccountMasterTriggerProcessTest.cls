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
private class AccountMasterTriggerProcessTest {
	// 税ステータス自動設定機能
	@isTest(SeeAllData=false)
	static void testAutoSetupAccountMaster() {
		List<AccountMaster__c> productMstList = TestCommon.createProductMst(2);
		for (AccountMaster__c acc : [select StsTaxfee__c from AccountMaster__c]) {
			System.assertEquals(acc.StsTaxfee__c, '0');
		}
		productMstList[0].jmstRef__c = null;
		JMST__c newJmst = new JMST__c(TaxRate__c = 0);
		productMstList[1].jmstRef__c = newJmst.Id;
		update productMstList;
		for (AccountMaster__c acc : [select StsTaxfee__c from AccountMaster__c]) {
			System.assertEquals(acc.StsTaxfee__c, '99');
		}
		JMST__c newJmst2 = new JMST__c(TaxRate__c = 5);
		insert newJmst2;
		productMstList[1].jmstRef__c = newJmst2.Id;
		update productMstList[1];
		for (AccountMaster__c acc : [select StsTaxfee__c from AccountMaster__c where id = :productMstList[1].Id]) {
			System.assertEquals(acc.StsTaxfee__c, '0');
		}
		// 新規登録の確認
		AccountMaster__c newItem1 = new AccountMaster__c(
		   Name = '名称2(漢1)UNIT_TEST' + CommUtils.getRandom(9),
		   jmstRef__c = newJmst.Id,
		   Field3__c = 'UNIT' + CommUtils.getRandom(9)         // 商品コード
		);
		insert newItem1;
		for (AccountMaster__c acc : [select StsTaxfee__c from AccountMaster__c where id = :newItem1.Id]) {
			System.assertEquals(acc.StsTaxfee__c, '99');
		}
		AccountMaster__c newItem2 = new AccountMaster__c(
		   Name = '名称2(漢1)UNIT_TEST' + CommUtils.getRandom(9),
		   jmstRef__c = newJmst2.Id,
		   Field3__c = 'UNIT' + CommUtils.getRandom(9)         // 商品コード
		);
        insert newItem2;
		for (AccountMaster__c acc : [select StsTaxfee__c from AccountMaster__c where id = :newItem2.Id]) {
			System.assertEquals(acc.StsTaxfee__c, '0');
		}
	}
}