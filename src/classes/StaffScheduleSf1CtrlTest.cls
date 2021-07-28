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
private class StaffScheduleSf1CtrlTest {

    static testMethod void myUnitTest() {
        StaffScheduleSf1Ctrl ctrl  =new StaffScheduleSf1Ctrl();
        
        ctrl.customStatus = 'TEST COMMENT';
        ctrl.commentSelLst = new List<String>{ctrl.commentLabLst[0].getValue(),
        										ctrl.commentLabLst[1].getValue()};
        ctrl.customStatus = 'TEST STATUS';
        ctrl.statusSelLst = new List<String>{ctrl.statusLabLst[0].getValue(),
        										ctrl.statusLabLst[1].getValue()};
		// 2015/12/01 Assert BEGIN
		System.assertEquals(ctrl.statusSelLst.size(), 2);
		// 2015/12/01 Assert END
        ctrl.upsertData();
        
        ctrl.gotoDate();
    }
    
}