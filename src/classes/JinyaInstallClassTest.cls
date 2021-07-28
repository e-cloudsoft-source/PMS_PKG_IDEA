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
private class JinyaInstallClassTest {

    @isTest(seeAllData=true)
	static void testInstallScript() {
		//delete [select id from pushTopic];
		String[] codes = new List<String>{'M99000','M99001','M99002','M99003','M99004','M99005'};
		//delete [select id from AccountMaster__c where Field3__c in :codes and ActionType__c = :CommConst.PROD_ACTION_TYPE_PY and PaymentType__c != null];
  		JinyaInstallClass postinstall = new JinyaInstallClass();
    	Test.testInstall(postinstall, null);
    	Test.testInstall(postinstall, new Version(1,5), true);
    	Version v = System.requestVersion();
  		System.debug(logginglevel.info,'v:::' + v);
    	//UserInfo.isCurrentUserLicensed('your_namespace');
    	System.debug(logginglevel.info,'System.requestVersion()' + System.requestVersion());
    	//System.debug(logginglevel.info,'Account Master' + [select id,Field3__c,Name,ActionType__c,PaymentType__c from AccountMaster__c where Field3__c in :codes ]);
		//System.debug(logginglevel.info,'System.requestVersion().major()' + System.requestVersion().major());
   		List<ReportLogo__c> a = [Select id from ReportLogo__c where name =: CommRepUtils.REP_TYPE.LOGO_00_SYSDEF.name()];
    	System.assertEquals(a.size(), 1, 'ReportLogo not found');
    	System.assertEquals([select id from pushTopic].size(),6);
    	System.assertEquals([select id from AccountMaster__c where Field3__c in :codes and ActionType__c = :CommConst.PROD_ACTION_TYPE_PY and PaymentType__c != null].size(),codes.size());
		Test.startTest();
			JinyaInstallClassHelpBatch batch = new JinyaInstallClassHelpBatch();
            DataBase.executeBatch(batch, 1);
		Test.stopTest();
	}
}