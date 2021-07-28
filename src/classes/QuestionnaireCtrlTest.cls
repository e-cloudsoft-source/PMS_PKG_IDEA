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
private class QuestionnaireCtrlTest {

	// テストケース
	static testmethod void testYadochou() {
		// Insert Xml Defined
		String xmlStr = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP><SHOPCODE></SHOPCODE><HEADER>この度は数ある施設の中から「元湯 陣屋」にご宿泊頂きまして誠にありがとうございます。当館でのご滞在はいかがでございましたでしょうか。私どもは、お客様のご意見をお伺いし、次回ご滞在のより良いおもてなしへの向上に努めてまいりたいと考えております。お忙しい所、大変恐縮ではございますが、ご意見、ご感想をお伺い致したくご案内申し上げます。</HEADER><MANAGER_TITLE>元湯 陣屋 女将</MANAGER_TITLE></SHOP></root>';
        Document doc = new Document();
        doc.Name = 'QuestionnaireConfigXml';
        doc.DeveloperName = 'QuestionnaireConfigXml';
        doc.FolderId = UserInfo.getUserId();
        doc.Body = Blob.valueOf(xmlStr);
        insert doc;
        
        // Report Logo作成
        TestCommon.createRepLogo();
        User loginUser = UserUtil.CurrentUser;
        loginUser.ShopCode__c = null;
        //update loginUser;
        System.runAs(loginUser) {
	        Contact guest = TestCommon.createContact();
	        // 明細情報を登録して、保存する処理
	        List<Lead__c> leads = TestCommon.createLead(Date.today(), 1,2,guest.Id);
	        for (Lead__c lead : leads) {
	        	lead.Field293__c = '18:30';
	       	 	lead.Morningtime__c = '7:00';
	        }
	        update leads;
	        
	        Yadochou__c yadochou = new Yadochou__c(
	            Name = 'TestCode',
	            Field1__c = leads[0].Id,
	            Field15__c = guest.Id
	        );
	        insert yadochou;
	        
	        Test.startTest();
	
	        // PDF書を取得する
	        ApexPages.currentPage().getParameters().put('orgId',yadochou.Id);
	        ApexPages.StandardController contrl1 = new ApexPages.StandardController(yadochou);
	        QuestionnaireCtrl ctrl1 = new QuestionnaireCtrl();
			
	        
	        Test.stopTest();
	        System.assert(yadochou != null);
        }
        
	}
	// テストケース
	static testmethod void testQuestion() {
		// Insert Xml Defined
		String xmlStr = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP><SHOPCODE></SHOPCODE><HEADER>A</HEADER><MANAGER_TITLE>B</MANAGER_TITLE><EXT_MULITI_LANG><JAPANESE><HEADER>C</HEADER><MANAGER_TITLE>D</MANAGER_TITLE></JAPANESE></EXT_MULITI_LANG><SURVEY_CUSTOME_DEF><BODY LANGUAGE="jp"><GROUP TITLE="E"><ROW TITLE="F" SIZE="68,35,118,35,68">非常に満足,満足,どちらともいえない,不満,非常に不満</ROW><UNDERLINE STYLE="height:28px;width:100%;border-bottom: solid 1px #000000;" REPEAT="4"/></GROUP></BODY></SURVEY_CUSTOME_DEF></SHOP></root>';
        Document doc = new Document();
        doc.Name = 'QuestionnaireConfigXml';
        doc.DeveloperName = 'QuestionnaireConfigXml';
        doc.FolderId = UserInfo.getUserId();
        doc.Body = Blob.valueOf(xmlStr);
        insert doc;
        
        // Report Logo作成
        TestCommon.createRepLogo();
 		User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	loginUser.ShopCode__c = null;
    	update loginUser;
        //update loginUser;
        System.runAs(loginUser) {
        Contact guest = TestCommon.createContact();
        // 明細情報を登録して、保存する処理
        List<Lead__c> leads = TestCommon.createLead(Date.today(), 1,2,guest.Id);
        for (Lead__c lead : leads) {
        	lead.Field293__c = '18:30';
       	 	lead.Morningtime__c = '7:00';
        }
        update leads;
        
        Customersurvey__c survey = new Customersurvey__c(
            Reserved__c = leads[0].Id,
            Field15__c = guest.Id
        );
        insert survey;
        
        Test.startTest();

        // PDF書を取得する
        ApexPages.currentPage().getParameters().put('orgId',survey.Id);
        QuestionnaireCtrl ctrl1 = new QuestionnaireCtrl();
		System.assertEquals(ctrl1.oXmlDef.headerStr, new list<string>{'A'}, ctrl1.oXmlDef);
        System.assertEquals(ctrl1.oXmlDef.managerStr, 'B', ctrl1.oXmlDef);
        ctrl1.getReportInfo();
        Test.stopTest();
        }
	}
	static testmethod void testQuestion2() {
		// Insert Xml Defined
		String xmlStr = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP><SHOPCODE></SHOPCODE><HEADER>A</HEADER><MANAGER_TITLE>B</MANAGER_TITLE><EXT_MULITI_LANG><JAPANESE><HEADER>A</HEADER><MANAGER_TITLE>B</MANAGER_TITLE></JAPANESE><ENGLISH><HEADER>C</HEADER><MANAGER_TITLE>D</MANAGER_TITLE></ENGLISH></EXT_MULITI_LANG></SHOP></root>';
        Document doc = new Document();
        doc.Name = 'QuestionnaireConfigXml';
        doc.DeveloperName = 'QuestionnaireConfigXml';
        doc.FolderId = UserInfo.getUserId();
        doc.Body = Blob.valueOf(xmlStr);
        insert doc;
        
        // Report Logo作成
        TestCommon.createRepLogo();

        Contact guest = TestCommon.createContact();
        // 明細情報を登録して、保存する処理
        List<Lead__c> leads = TestCommon.createLead(Date.today(), 1,2,guest.Id);
        for (Lead__c lead : leads) {
        	lead.Field293__c = '18:30';
       	 	lead.Morningtime__c = '7:00';
        }
        update leads;
        
        Customersurvey__c survey = new Customersurvey__c(
            Reserved__c = leads[0].Id,
            anquete__c = guest.Id
        );
        insert survey;
        
        Test.startTest();

        // PDF書を取得する
        // IDなしの場合
        QuestionnaireCtrl ctrl1 = new QuestionnaireCtrl();
        System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR));
        Test.stopTest();

        ApexPages.currentPage().getParameters().put('orgId',guest.Id);
        ApexPages.currentPage().getParameters().put('lng','jp');
        QuestionnaireCtrl ctrl2 = new QuestionnaireCtrl();
        System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR));
	}
	// 2019/04/15 BY zyz BEGIN
	static testmethod void testQuestion3() {
		// Insert Xml Defined
		String xmlStr = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP><SHOPCODE></SHOPCODE><HEADER>A</HEADER><MANAGER_TITLE>B</MANAGER_TITLE><EXT_MULITI_LANG><JAPANESE><HEADER>A</HEADER><MANAGER_TITLE>B</MANAGER_TITLE></JAPANESE><ENGLISH><HEADER>C</HEADER><MANAGER_TITLE>D</MANAGER_TITLE></ENGLISH></EXT_MULITI_LANG></SHOP></root>';
        Document doc = new Document();
        doc.Name = 'QuestionnaireConfigXml';
        doc.DeveloperName = 'QuestionnaireConfigXml';
        doc.FolderId = UserInfo.getUserId();
        doc.Body = Blob.valueOf(xmlStr);
        insert doc;
        
        // Report Logo作成
        TestCommon.createRepLogo();

        Contact guest = TestCommon.createContact();
        // 明細情報を登録して、保存する処理
        List<Lead__c> leads = TestCommon.createLead(Date.today(), 1,2,guest.Id);
        for (Lead__c lead : leads) {
        	lead.Field293__c = '18:30';
       	 	lead.Morningtime__c = '7:00';
        }
        update leads;
        
        Customersurvey__c survey = new Customersurvey__c(
            Reserved__c = leads[0].Id,
            anquete__c = guest.Id
        );
        insert survey;
        
        Test.startTest();

        // PDF書を取得する
        // IDなしの場合
        QuestionnaireCtrl ctrl1 = new QuestionnaireCtrl();
        System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR));
        Test.stopTest();

        ApexPages.currentPage().getParameters().put('orgId',guest.Id);
        ApexPages.currentPage().getParameters().put('lng','en');
        QuestionnaireCtrl ctrl2 = new QuestionnaireCtrl();
        System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR));
	}
	// 2019/04/15 BY zyz END
}