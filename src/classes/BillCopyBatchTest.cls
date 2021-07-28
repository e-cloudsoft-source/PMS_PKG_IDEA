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
private class BillCopyBatchTest {
    static testMethod void myUnitTest() {
    	getCsvSetupConfig();
        // TO DO: implement unit test
        AccountAcount__c oAcountSobj = new AccountAcount__c(
			IssueDate__c = Date.today(),
			comment__c = '',
			salesDate__c = Date.today(),
			IsNewLayout__c = true
		);
		
		List<Lead__c> lstLead = TestCommon.createLead(Date.today(), 10, 2);
		List<Id> lstLeadId = new List<Id>();
		for(Lead__c lead : lstLead){
			// 予約チェックイン
			lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
			lstLeadId.add(lead.id);
		}
		update lstLead;
		Test.startTest();
		//List<AccountAcount__c> accounts = [select id from AccountAcount__c];
		BillCopyBatch batch = new BillCopyBatch(lstLeadId,oAcountSobj,1,null);
		Database.executeBatch(batch);
		Test.stopTest();
    }
    static testMethod void myUnitTest02() {
        getCsvSetupConfig();
        // TO DO: implement unit test
        AccountAcount__c oAcountSobj = new AccountAcount__c(
            IssueDate__c = Date.today(),
            comment__c = '',
            salesDate__c = Date.today(),
            IsNewLayout__c = true,
            PaymentFlg__c = true
        );
        
        List<Lead__c> lstLead = TestCommon.createLead(Date.today(), 10, 2);
        List<Id> lstLeadId = new List<Id>();
        for(Lead__c lead : lstLead){
            lstLeadId.add(lead.id);
        }
        Test.startTest();
        BillCopyBatch batch = new BillCopyBatch(lstLeadId,oAcountSobj,1,null);
        Database.executeBatch(batch);
        Test.stopTest();
    }
    static testMethod void myUnitTest03() {
        getCsvSetupConfig();
        // TO DO: implement unit test
        AccountAcount__c oAcountSobj = new AccountAcount__c(
            IssueDate__c = Date.today().addDays(2),
            comment__c = '',
            salesDate__c = Date.today().addDays(2),
            IsNewLayout__c = true,
            PaymentFlg__c = true
        );
        
        List<Lead__c> lstLead = TestCommon.createLead(Date.today(), 10, 2);
        List<Id> lstLeadId = new List<Id>();
        Test.startTest();
        for(Lead__c lead : lstLead){
            lstLeadId.add(lead.id);
        }
        BillCopyBatch batch = new BillCopyBatch(lstLeadId,oAcountSobj,1,null);
        Database.executeBatch(batch);
        Test.stopTest();
    }
    static testMethod void myUnitTest04() {
        getCsvSetupConfig();
        // TO DO: implement unit test
        AccountAcount__c oAcountSobj = new AccountAcount__c(
            IssueDate__c = Date.today().addDays(2),
            comment__c = '',
            salesDate__c = Date.today().addDays(2),
            IsNewLayout__c = true,
            PaymentFlg__c = true
        );
        
        List<Lead__c> lstLead = TestCommon.createLead(Date.today(), 10, 2);
        List<Id> lstLeadId = new List<Id>();
        Test.startTest();
        for(Lead__c lead : lstLead){
            lstLeadId.add(lead.id);
            // 予約チェックイン
            lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
        }
        update lstLead;
        BillCopyBatch batch = new BillCopyBatch(lstLeadId,oAcountSobj,1,null);
        Database.executeBatch(batch);
        Test.stopTest();
    }
    static testMethod void myUnitTest05() {
        getCsvSetupConfig();
        // TO DO: implement unit test
        AccountAcount__c oAcountSobj = new AccountAcount__c(
            IssueDate__c = Date.today().addDays(2),
            comment__c = '',
            salesDate__c = Date.today().addDays(2),
            IsNewLayout__c = true,
            PaymentFlg__c = true
        );
        
        List<Lead__c> lstLead = TestCommon.createLead(Date.today(), 10, 2);
        List<Id> lstLeadId = new List<Id>();
        Test.startTest();
        for(Lead__c lead : lstLead){
            lstLeadId.add(lead.id);
            // 予約チェックイン
            lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
        }
        update lstLead;
        Lead__c orgLead = lstLead[0];
        lstLead = TestCommon.createLead(Date.today().addDays(2), 10, 2);
        Lead__c nextLead = lstLead[0];
        nextLead.LeadIndexRef__c = orgLead.LeadIndexRef__c;
        nextLead.relcontact__c = orgLead.relcontact__c;
        nextLead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update nextLead;
        List<AccountAcount__c> accounts = [select id,IssueDate__c from AccountAcount__c where Relreserve__c = :nextLead.id];
        if (!accounts.isEmpty()) delete accounts;
        BillCopyBatch batch = new BillCopyBatch(lstLeadId,oAcountSobj,1,null);
        Database.executeBatch(batch);
        Test.stopTest();
    }
    private static void getCsvSetupConfig() {
        String csv = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP><SHOPCODE></SHOPCODE><PAYMENT><CONVERT><PAYTYPE>現金</PAYTYPE><MEIDALAB>預り／現計</MEIDALAB></CONVERT><CONVERT><PAYTYPE>カード</PAYTYPE><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB></CONVERT><CONVERT><PAYTYPE>売掛金</PAYTYPE><MEIDALAB>掛計</MEIDALAB></CONVERT><CONVERT><PAYTYPE>クーポン</PAYTYPE><MEIDALAB>クーポン</MEIDALAB></CONVERT><CONVERT><PAYTYPE>値引</PAYTYPE><MEIDALAB>値引・割引券</MEIDALAB></CONVERT><CONVERT><PAYTYPE>予約金</PAYTYPE><MEIDALAB>予約金</MEIDALAB></CONVERT></PAYMENT><PAYMEIDA><CONVERT><MEIDALAB>預り／現計</MEIDALAB><PRODCODE>87001</PRODCODE></CONVERT><CONVERT><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB><PRODCODE>85201</PRODCODE></CONVERT><CONVERT><MEIDALAB>掛計</MEIDALAB><PRODCODE>85101</PRODCODE></CONVERT><CONVERT><MEIDALAB>クーポン</MEIDALAB><PRODCODE>85610</PRODCODE></CONVERT><CONVERT><MEIDALAB>値引・割引券</MEIDALAB><PRODCODE>87005</PRODCODE></CONVERT><CONVERT><MEIDALAB>予約金</MEIDALAB><PRODCODE>87001</PRODCODE></CONVERT></PAYMEIDA></SHOP></root>';
        
        Document doc = new Document();
        doc.Name = 'BillSimpleHelpConfig';
        doc.DeveloperName = doc.Name;
        doc.FolderId = UserInfo.getUserId();
        doc.Body = Blob.valueOf(csv);
        insert doc;
        
	
    	csv = '<root><SHOP><SHOPCODE></SHOPCODE><LAYOUT><MAXCOLS>3</MAXCOLS><BTNSTYLE>width:125px;height:30px;</BTNSTYLE><TABLEWIDTH>450</TABLEWIDTH><TABLEHEIGHT>260</TABLEHEIGHT></LAYOUT><BUTTONTAB><TABLABEL>メディア</TABLABEL><BUTTON ISBLANK="FALSE"><LABEL>現金</LABEL><PRODCODE>87001</PRODCODE><ICONURL>/resource/AppImages/payicon/Cash.png</ICONURL></BUTTON><BUTTON ISBLANK="FALSE"><LABEL>VISA</LABEL><PRODCODE>85201</PRODCODE><ICONURL>/resource/simplepayimg/card/visa.jpg</ICONURL></BUTTON><BUTTON ISBLANK="FALSE"><LABEL>MASTER</LABEL><PRODCODE>85301</PRODCODE><ICONURL>/resource/simplepayimg/card/mc.jpg</ICONURL></BUTTON></BUTTONTAB><BUTTONTAB><TABLABEL>カード</TABLABEL><BUTTON ISBLANK="FALSE"><LABEL>VISA</LABEL><PRODCODE>85201</PRODCODE><ICONURL>/resource/simplepayimg/card/visa.jpg</ICONURL></BUTTON><BUTTON ISBLANK="FALSE"><LABEL>MASTER</LABEL><PRODCODE>85301</PRODCODE><ICONURL>/resource/simplepayimg/card/mc.jpg</ICONURL></BUTTON><BUTTON ISBLANK="FALSE"><LABEL>JCB</LABEL><PRODCODE>85401</PRODCODE><ICONURL>/resource/simplepayimg/card/jcb.jpg</ICONURL></BUTTON></BUTTONTAB><BUTTONTAB><TABLABEL>クーポン</TABLABEL><BUTTON ISBLANK="FALSE"><LABEL>楽天ポイント</LABEL><PRODCODE>85601</PRODCODE><ICONURL>/resource/simplepayimg/coupon/rt.jpg</ICONURL></BUTTON><BUTTON ISBLANK="FALSE"><LABEL>一休ポイント</LABEL><PRODCODE>85602</PRODCODE><ICONURL>/resource/simplepayimg/coupon/1x.jpg</ICONURL></BUTTON><BUTTON ISBLANK="FALSE"><LABEL>じゃらんポイント</LABEL><PRODCODE>85603</PRODCODE><ICONURL>/resource/simplepayimg/coupon/jal.jpg</ICONURL></BUTTON></BUTTONTAB></SHOP>'
					+ '</root>';
    	
        doc = new Document();
        doc.Name = 'BillSimplePaymentConfig';
        doc.DeveloperName = doc.Name;
        doc.FolderId = UserInfo.getUserId();
        doc.Body = Blob.valueOf(csv);
        insert doc;
        
        TestCommon.createDeviceConfigXml();
    }
}