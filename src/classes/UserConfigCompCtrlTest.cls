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
private class UserConfigCompCtrlTest {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        String userid = UserInfo.getuserId();
        String shopcd = '01';
        String config1 = 'Rroom__r_Seq__c:56,refTypeOfRooms__r_ShopInfoRef__r_Name:132,EntryTime__c:157,refTypeOfRooms__r_Name:167,Field372__c:117,';
        String config2 = 'Rroom__r_Rnumber__c:true,detailList:true,SalesOfficeInfoRef__c:true,Field4__c:true,';
        String config3 = 'false';
        String configKey1 = UserConfigCompCtrl.KREP_SUBTYPE.RESIZE.name();
        String configKey2 = UserConfigCompCtrl.KREP_SUBTYPE.HIDCOL.name();
        String configKey3 = UserConfigCompCtrl.KREP_SUBTYPE.GROUPTYPE.name();
        UserConfigCompCtrl.saveKrepConfig(configKey1,config1,userid, shopcd);
        UserConfigCompCtrl.saveKrepConfig(configKey2,config2,userid, shopcd);
        UserConfigCompCtrl.saveKrepConfig(configKey3,config3,userid, shopcd);
        map<String,String> rsMap = UserConfigCompCtrl.getKrepConfig(userid,shopcd);       
        System.assertEquals(rsMap.size(),3,rsMap);
        System.assertEquals(rsMap.get(configKey1),config1,rsMap);
        System.assertEquals(rsMap.get(configKey2),config2,rsMap);
        System.assertEquals(rsMap.get(configKey3),config3,rsMap);
        String config4 = '1';
        String config5 = '2';
        String config6 = '3';
        UserConfigCompCtrl.saveKrepConfig(configKey1,config4,userid, shopcd);
        UserConfigCompCtrl.saveKrepConfig(configKey2,config5,userid, shopcd);
        UserConfigCompCtrl.saveKrepConfig(configKey3,config6,userid, shopcd);
        rsMap = UserConfigCompCtrl.getKrepConfig(userid,shopcd);       
        System.assertEquals(rsMap.size(),3,rsMap);
        System.assertEquals(rsMap.get(configKey1),config4,rsMap);
        System.assertEquals(rsMap.get(configKey2),config5,rsMap);
        System.assertEquals(rsMap.get(configKey3),config6,rsMap);
 
    }
}