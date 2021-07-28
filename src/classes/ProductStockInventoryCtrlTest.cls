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
private class ProductStockInventoryCtrlTest {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        List<AccountMaster__c> accs = TestCommon.createProductMst(20);
        ProductStockInventoryCtrl ctrl = new ProductStockInventoryCtrl();
        ctrl.initStock();
        String label = ctrl.masterOpts[0].getLabel();
        for (AccountMaster__c acc : accs) {
        	acc.Shelves__c = label;
        }
        update accs;
        ctrl.masterOptVal = label;
        ctrl.changeMaster();
        Map<String,object> reqMap = new Map<String,object>{'groupName' =>label};
        ProductStockInventoryCtrl.remoteCenter('queryStockData',JSON.serialize(reqMap));
        List<Map<String,object>> stocks = new List<Map<String,object>>{
        	new Map<String,object>{'stockQty' =>2,'groupName' =>label,'accountId' =>accs[0].id,'checkFlag' => true},
        	new Map<String,object>{'stockQty' =>3,'groupName' =>label,'accountId' =>accs[1].id,'checkFlag' => true}
        };
        ProductStockInventoryCtrl.remoteCenter('updateStockData',JSON.serialize(stocks));
        ctrl.initStock();
    }
}