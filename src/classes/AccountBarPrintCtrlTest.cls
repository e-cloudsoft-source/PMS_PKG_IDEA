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
private class AccountBarPrintCtrlTest {

    static testMethod void myUnitTest() {
    	TestCommon.createOrderConfigXml();
    	// マージ元の取引先情報を作成する
		List<AccountMaster__c> accounts = TestCommon.createProductMst(6);
		Map<String,String> request = new Map<String,String>{'pid' => accounts[0].id,'ip'=>'192.168.10.XXX'};
		AccountBarPrintCtrl.savePrintCount(accounts[0].id);
		AccountBarPrintCtrl.savePrintCount(accounts[0].id);
		AccountBarPrintCtrl.getPrintInfo(JSON.serialize(request));
		request.put('pos','POS01');
		AccountBarPrintCtrl.getPrintByIp(JSON.serialize(request));
        // TO DO: implement unit test
        ApexPages.StandardSetController controller = new ApexPages.StandardSetController(accounts);
        AccountBarPrintCtrl ctrl = new AccountBarPrintCtrl(controller);
        ctrl.init();
        AccountBarPrintCtrl.getViewInfo();
        AccountBarPrintCtrl.savePrintLodToDb('abc');
    }
}