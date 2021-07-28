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
private class ChangeMachineHelpTest {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        getCsvSetupConfig();
        ChangeMachineHelp help = new ChangeMachineHelp('02');
        String ipJson = help.getIpMapJson(ChangeMachineHelp.PAGETYPE_ACCOUNT);
        Object ipObj  = JSON.deserializeUntyped(ipJson);
        Map<String,Object> ipMap = (Map<String,Object>)ipObj;
        Map<String,Object> ipSetup = (Map<String,Object>)ipMap.get('192.168.10.123');
        system.debug(logginglevel.info,'ipMap:::' + ipMap);
        //( Map<String,String>)
        //JSON.deserializeUntyped()
        System.assertEquals(ipSetup.get('allReturn'), true);
        ChangeMachineHelp help1 = new ChangeMachineHelp('02',true);
        help1.getIpMapJson(ChangeMachineHelp.PAGETYPE_CASH);
        System.assertEquals(help1.getPriceMap().get('TwoThousandCashNums__c'), '紙幣機内総金額-2千円');
    }
    private static String getCsvSetupConfig() {
        String csv = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP><SHOPCODE>02</SHOPCODE>		<!-- 店舗コード --><ISDEBUG></ISDEBUG><ACCOUNTSWITCH>true</ACCOUNTSWITCH><CASHSWITCH>true</CASHSWITCH><PRINTCONFIG NAME="POS01">	<WEBSOCKET>wss</WEBSOCKET>	<PRINT>192.168.10.107</PRINT>	<PRINTPORT>443</PRINTPORT>	<POSNO>001</POSNO></PRINTCONFIG><DEVICECONFIG>	<DEVICE>		<ACCOUNT>false</ACCOUNT>		<LOCAL>192.168.10.122</LOCAL>		<PRINTER>POS01</PRINTER>	</DEVICE>	<DEVICE>		<LOCAL>192.168.10.120</LOCAL>		<PRINTER>POS01</PRINTER>	</DEVICE>	<DEVICE>		<ALLRETURN>true</ALLRETURN>		<LOCAL>192.168.10.123</LOCAL>		<PRINTER>POS01</PRINTER>	</DEVICE></DEVICECONFIG><PRICEMAPPING>	<CONVERT>		<APINAME>TenThousandCashNums__c</APINAME><CHANGE>紙幣機内総金額-1万円</CHANGE>	</CONVERT>	<CONVERT>		<APINAME>FiveThousandCashNums__c</APINAME><CHANGE>紙幣機内総金額-5千円</CHANGE>	</CONVERT>	<CONVERT>		<APINAME>TwoThousandCashNums__c</APINAME><CHANGE>紙幣機内総金額-2千円</CHANGE>	</CONVERT>	<CONVERT>		<APINAME>OneThousandCashNums__c</APINAME><CHANGE>紙幣機内総金額-1千円</CHANGE>	</CONVERT>	<CONVERT>		<APINAME>FiveHundredCashNums__c</APINAME><CHANGE>硬貨機内総金額-500円</CHANGE>	</CONVERT>	<CONVERT>		<APINAME>OneHundredCashNums__c</APINAME><CHANGE>硬貨機内総金額-100円</CHANGE>	</CONVERT>	<CONVERT>		<APINAME>FiftyCashNums__c</APINAME><CHANGE>硬貨機内総金額-50円</CHANGE>	</CONVERT>	<CONVERT>		<APINAME>TenCashNums__c</APINAME> <CHANGE>硬貨機内総金額-10円</CHANGE>	</CONVERT>	<CONVERT>		<APINAME>FiveCashNums__c</APINAME> <CHANGE>硬貨機内総金額-1円</CHANGE>	</CONVERT></PRICEMAPPING></SHOP></root>';
        Document doc = new Document();
        doc.Name = 'ChangeMachineConfig';
        doc.DeveloperName = doc.Name;
        doc.FolderId = UserInfo.getUserId();
        doc.Body = Blob.valueOf(csv);
        insert doc;
        return csv;
    }
}