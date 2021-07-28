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
private class CustomButtonTest {
	@isTest(seeAllData=true)
    static void testCustomButtonCon(){
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	List<Report> existReps = [select id,Name from Report limit 2];
    	comDef.Tier4Report__c = existReps[0].Name;
    	comDef.CustomTimeReport__c = existReps[1].Name;
    	update comDef;
    	
    	Lead__c yy = TestCommon.createLead();
    	//Lead__c yy = [select Id, name from Lead__c limit 1];
		CustomButtonCon wCustomButtonCon = new CustomButtonCon(new ApexPages.StandardController(yy));
		wCustomButtonCon.ViewRmAssNoon();
		PageReference pg = wCustomButtonCon.ViewSchedule();
		System.assert(pg != null);
	}
	@isTest(seeAllData=true)
    static void testCustomButtonPur(){
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	List<Report> existReps = [select id,Name from Report limit 2];
    	comDef.A1CookingReport__c = existReps[0].Name;
    	comDef.PurchaseReport__c = existReps[1].Name;
    	update comDef;
    	
        Purchase__c yy = TestCommon.createPurchase();
        //Purchase__c yy = [select Id, name from Purchase__c limit 1];
        CustomButtonPur wCustomButtonPur = new CustomButtonPur(new ApexPages.StandardController(yy));
        wCustomButtonPur.ViewCost();
        Pagereference pg = wCustomButtonPur.ViewPurchase();
        System.assert(pg != null);
    }
	@isTest(seeAllData=true)
    static void testCustomButtonRac(){
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	List<Report> existReps = [select id,Name from Report limit 1];
    	comDef.WhiteBoardReport__c = existReps[0].Name;
    	update comDef;
    	
    	RsvAccount__c yy = TestCommon.createRsvAccount();
    	//RsvAccount__c yy = [select Id, name from RsvAccount__c limit 1];
		CustomButtonRac wCustomButtonRac = new CustomButtonRac(new ApexPages.StandardController(yy));
		Pagereference pg = wCustomButtonRac.ViewWhiteBoard();
		System.assert(pg != null);
	}
}