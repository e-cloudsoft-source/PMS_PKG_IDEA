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
private class BI_OrderWebServiceTest {
    @testsetup
    static void dataSetup(){
        TestCommon.createOrderConfigXml();
        Lead__c lead = TestCommon.createLead();
        lead.field298__c = CommConst.LEAD_GUEST_ST_CI;
        update lead;
        update new Room__c (id = lead.Rroom__c , seq__c = 1318);
        List<AccountMaster__c> accs = TestCommon.createProductMst(5);
        String orderMessage = '';
        for (AccountMaster__c acc : accs) {
            orderMessage += acc.id + ':' + 1 + ',';
        }
        OrderMainCtrl.processOrder(orderMessage,lead.Rroom__c,'','192.168.1.101','',false);
        List<OrderEntryInfo__c> orders = [select id,AccountRef__c from OrderEntryInfo__c where OrderStatus__c = '印刷情報'];
        if (!orders.isEmpty()) {
            insert new CooperationResult__c(
					AccountAcountRef__c = orders[0].AccountRef__c,
					FunctionType__c = 'レーシト印刷',
					ManageID__c = orders[0].id,
					Status__c = '予約取込待ち'
				);
        }
        
    }
    static testMethod void myUnitTest() {
        List<CooperationResult__c> coos = [select id,ManageID__c,Status__c,AccountAcountRef__c from CooperationResult__c where Status__c = '予約取込待ち'];
        if (!coos.isEmpty()) {
            Map<String,String> reqMap = new Map<String,String>{'orderId' => coos[0].id , 'localIp' => '192.168.10.123'};
            Test.startTest();
            BI_OrderWebService.getOrderInfo(JSON.serialize(reqMap));
            Test.stopTest();
        }
    }
}