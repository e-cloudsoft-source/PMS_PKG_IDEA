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
private class MessageItemCtrlTest {

    static testMethod void myUnitTest() {
        createTestMonthMessageItem();
        // 2015/12/01 Assert BEGIN
		System.assertEquals([select Id from MessageItem__c].size(), 1);
		// 2015/12/01 Assert END
		// 画面起動
        MessageItemCtrl ctrl = new MessageItemCtrl();
        ctrl.yyyymmdd = DateTime.now().format('yyyyMMdd');
        ctrl.messageMaxRows = 2;
        ctrl.getInit();
        ctrl.refreshMessage();
        ctrl.messageObj.Message1__c = '33333';
        String daoJson = '{"Message1__c":"33333"}';
        String daoName =  ctrl.yyyymmdd;
        String spcd = '';
		MessageItemCtrl.updateMessage(daoJson, daoName, spcd) ;
	} 
	static testMethod void myUnitTest1() {
        createTestYearMessageItem();
        // 2015/12/01 Assert BEGIN
		System.assertEquals([select Id from MessageItem__c].size(), 1);
		// 2015/12/01 Assert END
		// 画面起動
        MessageItemCtrl ctrl = new MessageItemCtrl();
        ctrl.yyyymmdd = DateTime.now().format('yyyyMM');
        ctrl.messageMaxRows = 2;
        ctrl.getInit();
        List<MessageItem__c> itemLst = [select id,Message1__c from MessageItem__c ];
        if(!itemLst.isEmpty()){
        	itemLst[0].Message1__c = '33333';
        	update itemLst[0];
        }
        ctrl.refreshMessage();
        ctrl.messageObj.Message1__c = '44444';
        String daoJson = '{"Message1__c":"44444"}';
        String daoName =  ctrl.yyyymmdd;
        String spcd = '';
		MessageItemCtrl.updateMessage(daoJson, daoName, spcd) ;
	}
	private static void createTestMonthMessageItem(){
		
		Date currDate = Date.today();
		String formatStr = 'yyyyMM';
		String yyyymmdd = DateTime.now().format('yyyyMMdd');
		if (yyyymmdd.length()==6) {
			currDate = CommUtils.stringToDate(yyyymmdd+'01');
		} else if (yyyymmdd.length()==8) {
			currDate = CommUtils.stringToDate(yyyymmdd);
			formatStr = 'yyyyMMdd';
		}
		String currYmd = yyyymmdd;
		String oldYmd = currDate.addYears(-1).year() + yyyymmdd.mid(4,4);
		
		MessageItem__c item = new MessageItem__c(
										name = oldYmd,
										message1__c = '122333',
										message2__c = '333333'
									);
		insert item;
	}
	private static void createTestYearMessageItem(){
		
		Date currDate = Date.today();
		String formatStr = 'yyyyMM';
		String yyyymmdd = DateTime.now().format(formatStr);
		if (yyyymmdd.length()==6) {
			currDate = CommUtils.stringToDate(yyyymmdd+'01');
		} else if (yyyymmdd.length()==8) {
			currDate = CommUtils.stringToDate(yyyymmdd);
			formatStr = 'yyyyMMdd';
		}
		String currYmd = yyyymmdd;
		String oldYmd = currDate.addYears(-1).year() + yyyymmdd.mid(4,4);
		
		MessageItem__c item = new MessageItem__c(
										name = oldYmd,
										message1__c = '122333',
										message2__c = '333333'
									);
		insert item;
	}
}