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
private class BulkProcessKANBatchTest {

   
    static testMethod void case01(){
        Document doc1 = new Document();
        doc1.Name = 'KanSyncFieldConvertConfig';
        doc1.DeveloperName = doc1.Name;
        doc1.FolderId = UserInfo.getUserId();
        doc1.Body = Blob.valueOf(getCsvSetupConfig());
        insert doc1;
        
        Document doc2 = new Document();
        doc2.Name = 'BillSimpleHelpConfig';
        doc2.DeveloperName = doc2.Name;
        doc2.FolderId = UserInfo.getUserId();
        doc2.Body = Blob.valueOf(getCsvSetupConfig2());
        insert doc2;
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'KanSyncFieldConvertConfig'].size(), 1);
        // 2015/12/01 Assert END

        RsvAccount__c rsv = createRsvAccount();
        CommDefine__c comDef = TestCommon.createCommDefine();
        comDef.SchedulePcaDeviationDays__c = 0;
        comDef.ScheduleResultMailAddress__c = '111@aaa.com';
        update comDef;

        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfo, productLst[0]);
        // 予約情報のステータス：チェックインに変更する
        leadInfo.Field298__c = 'チェックイン完';
        update leadInfo;
        
        Test.startTest();
        BulkProcessKANBatch bppb = new BulkProcessKANBatch();
        DateTime nowTime = DateTime.now().addSeconds(100);
        String timeStr = nowTime.format('yyyyMMddHHmmss');
        String yy = timeStr.substring(0,4);
        String mm = timeStr.substring(4,6);
        String dd = timeStr.substring(6,8);
        String hh = timeStr.substring(8,10);
        String ms = timeStr.substring(10,12);
        String ss = timeStr.substring(12,14);
        String sch = ss + ' ' +
               ms + ' ' +
               hh + ' ' +
               dd + ' ' +
               mm + ' ' +
               ' ? ' + yy;
        String jobName = DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
        String jobId = system.schedule(jobName, sch, bppb);

        Test.stopTest();

    }
    // 通知モード３
    static testMethod void case02(){
    	Document doc1 = new Document();
        doc1.Name = 'KanSyncFieldConvertConfig';
        doc1.DeveloperName = doc1.Name;
        doc1.FolderId = UserInfo.getUserId();
        doc1.Body = Blob.valueOf(getCsvSetupConfig());
        insert doc1;
        
        Document doc2 = new Document();
        doc2.Name = 'BillSimpleHelpConfig';
        doc2.DeveloperName = doc2.Name;
        doc2.FolderId = UserInfo.getUserId();
        doc2.Body = Blob.valueOf(getCsvSetupConfig2());
        insert doc2;
        
        RsvAccount__c rsv = createRsvAccount();
        CommDefine__c comDef = TestCommon.createCommDefine();
        comDef.ScheduleResultMailAddress__c = '111@aaa.com';
        comDef.SchedulePcaResultSendType__c = '';
        comDef.SchedulePcaDeviationDays__c = 0;
        update comDef;

        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfo, productLst[0]);
        // 予約情報のステータス：チェックインに変更する
        leadInfo.Field298__c = 'チェックイン完';
        update leadInfo;
        
        Test.startTest();
        BulkProcessKANBatch bppb = new BulkProcessKANBatch('',Date.today(),Date.today(),new list<string>{'FREEEBatch'});
        DateTime nowTime = DateTime.now().addSeconds(100);
        String timeStr = nowTime.format('yyyyMMddHHmmss');
        String yy = timeStr.substring(0,4);
        String mm = timeStr.substring(4,6);
        String dd = timeStr.substring(6,8);
        String hh = timeStr.substring(8,10);
        String ms = timeStr.substring(10,12);
        String ss = timeStr.substring(12,14);
        String sch = ss + ' ' +
               ms + ' ' +
               hh + ' ' +
               dd + ' ' +
               mm + ' ' +
               ' ? ' + yy;
        String jobName = DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
        String jobId = system.schedule(jobName, sch, bppb);
        Test.stopTest();
        // パラメータ設定なしの場合、メール送信を行う
        List<Attachment> rsAtt = [select id from attachment where parentId = :rsv.Id];
        System.assert(rsAtt.isEmpty(), rsAtt);
    }
    // パラメータ:1
    static testMethod void case03(){
    	Document doc1 = new Document();
        doc1.Name = 'KanSyncFieldConvertConfig';
        doc1.DeveloperName = doc1.Name;
        doc1.FolderId = UserInfo.getUserId();
        doc1.Body = Blob.valueOf(getCsvSetupConfig());
        insert doc1;
        
        Document doc2 = new Document();
        doc2.Name = 'BillSimpleHelpConfig';
        doc2.DeveloperName = doc2.Name;
        doc2.FolderId = UserInfo.getUserId();
        doc2.Body = Blob.valueOf(getCsvSetupConfig2());
        insert doc2;
        
        RsvAccount__c rsv = createRsvAccount();
        CommDefine__c comDef = TestCommon.createCommDefine();
        comDef.ScheduleResultMailAddress__c = '111@aaa.com';
        comDef.SchedulePcaResultSendType__c = '1';
        comDef.SchedulePcaDeviationDays__c = 0;
        update comDef;

        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfo, productLst[0]);
        // 予約情報のステータス：チェックインに変更する
        leadInfo.Field298__c = 'チェックイン完';
        update leadInfo;
        
        Test.startTest();
        BulkProcessKANBatch bppb = new BulkProcessKANBatch('',Date.today(),null,new list<string>());
        DateTime nowTime = DateTime.now().addSeconds(100);
        String timeStr = nowTime.format('yyyyMMddHHmmss');
        String yy = timeStr.substring(0,4);
        String mm = timeStr.substring(4,6);
        String dd = timeStr.substring(6,8);
        String hh = timeStr.substring(8,10);
        String ms = timeStr.substring(10,12);
        String ss = timeStr.substring(12,14);
        String sch = ss + ' ' +
               ms + ' ' +
               hh + ' ' +
               dd + ' ' +
               mm + ' ' +
               ' ? ' + yy;
        String jobName = DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
        String jobId = system.schedule(jobName, sch, bppb);
        Test.stopTest();
        // パラメータ設定なしの場合、メール送信を行う
        List<Attachment> rsAtt = [select id from attachment where parentId = :rsv.Id];
        System.assert(rsAtt.isEmpty(), rsAtt);
    }
    // パラメータ:2
    static testMethod void case04(){
    	Document doc1 = new Document();
        doc1.Name = 'KanSyncFieldConvertConfig';
        doc1.DeveloperName = doc1.Name;
        doc1.FolderId = UserInfo.getUserId();
        doc1.Body = Blob.valueOf(getCsvSetupConfig());
        insert doc1;
        
        Document doc2 = new Document();
        doc2.Name = 'BillSimpleHelpConfig';
        doc2.DeveloperName = doc2.Name;
        doc2.FolderId = UserInfo.getUserId();
        doc2.Body = Blob.valueOf(getCsvSetupConfig2());
        insert doc2;
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'KanSyncFieldConvertConfig'].size(), 1);
        // 2015/12/01 Assert END
        RsvAccount__c rsv = createRsvAccount();
        CommDefine__c comDef = TestCommon.createCommDefine();
        comDef.ScheduleResultMailAddress__c = '111@aaa.com';
        comDef.SchedulePcaResultSendType__c = '2';
        comDef.SchedulePcaDeviationDays__c = 0;
        update comDef;
        
        Test.startTest();
        BulkProcessKANBatch bppb = new BulkProcessKANBatch('',date.today(),Date.today(),new list<string>());
        DateTime nowTime = DateTime.now().addSeconds(100);
        String timeStr = nowTime.format('yyyyMMddHHmmss');
        String yy = timeStr.substring(0,4);
        String mm = timeStr.substring(4,6);
        String dd = timeStr.substring(6,8);
        String hh = timeStr.substring(8,10);
        String ms = timeStr.substring(10,12);
        String ss = timeStr.substring(12,14);
        String sch = ss + ' ' +
               ms + ' ' +
               hh + ' ' +
               dd + ' ' +
               mm + ' ' +
               ' ? ' + yy;
        String jobName = DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
        String jobId = system.schedule(jobName, sch, bppb);
        Test.stopTest();
        // パラメータ設定なしの場合、メール送信を行う
        List<Attachment> rsAtt = [select id from attachment where parentId = :rsv.Id];
    }

    // パラメータ:3
    static testMethod void case05(){
    	Document doc1 = new Document();
        doc1.Name = 'KanSyncFieldConvertConfig';
        doc1.DeveloperName = doc1.Name;
        doc1.FolderId = UserInfo.getUserId();
        doc1.Body = Blob.valueOf(getCsvSetupConfig());
        insert doc1;
        
        Document doc2 = new Document();
        doc2.Name = 'BillSimpleHelpConfig';
        doc2.DeveloperName = doc2.Name;
        doc2.FolderId = UserInfo.getUserId();
        doc2.Body = Blob.valueOf(getCsvSetupConfig2());
        insert doc2;
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'KanSyncFieldConvertConfig'].size(), 1);
        // 2015/12/01 Assert END
        RsvAccount__c rsv = createRsvAccount();
        CommDefine__c comDef = TestCommon.createCommDefine();
        comDef.ScheduleResultMailAddress__c = '111@aaa.com';
        comDef.SchedulePcaResultSendType__c = '3';
        comDef.SchedulePcaDeviationDays__c = 0;
        update comDef;
        
        Test.startTest();
        BulkProcessKANBatch bppb = new BulkProcessKANBatch('',date.today(),Date.today(),new list<string>());
        DateTime nowTime = DateTime.now().addSeconds(100);
        String timeStr = nowTime.format('yyyyMMddHHmmss');
        String yy = timeStr.substring(0,4);
        String mm = timeStr.substring(4,6);
        String dd = timeStr.substring(6,8);
        String hh = timeStr.substring(8,10);
        String ms = timeStr.substring(10,12);
        String ss = timeStr.substring(12,14);
        String sch = ss + ' ' +
               ms + ' ' +
               hh + ' ' +
               dd + ' ' +
               mm + ' ' +
               ' ? ' + yy;
        String jobName = DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
        String jobId = system.schedule(jobName, sch, bppb);
        Test.stopTest();
        // パラメータ設定なしの場合、メール送信を行う
        List<Attachment> rsAtt = [select id from attachment where parentId = :rsv.Id];
    }
    static testMethod void case06(){
    	Document doc1 = new Document();
        doc1.Name = 'KanSyncFieldConvertConfig';
        doc1.DeveloperName = doc1.Name;
        doc1.FolderId = UserInfo.getUserId();
        doc1.Body = Blob.valueOf(getCsvSetupConfig());
        insert doc1;
        
        Document doc2 = new Document();
        doc2.Name = 'BillSimpleHelpConfig';
        doc2.DeveloperName = doc2.Name;
        doc2.FolderId = UserInfo.getUserId();
        doc2.Body = Blob.valueOf(getCsvSetupConfig2());
        insert doc2;
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'KanSyncFieldConvertConfig'].size(), 1);
        // 2015/12/01 Assert END
        RsvAccount__c rsv = createSimpleRsvAccount();
        CommDefine__c comDef = TestCommon.createCommDefine();
        comDef.ScheduleResultMailAddress__c = '111@aaa.com';
        comDef.SchedulePcaResultSendType__c = '2';
        comDef.SchedulePcaDeviationDays__c = 0;
        update comDef;


        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfo, productLst[0]);
        // 予約情報のステータス：チェックインに変更する
        leadInfo.Field298__c = 'チェックイン完';
        update leadInfo;
        
        Test.startTest();
        BulkProcessKANBatch bppb = new BulkProcessKANBatch('',date.today(),Date.today(),new list<string>());
        DateTime nowTime = DateTime.now().addSeconds(100);
        String timeStr = nowTime.format('yyyyMMddHHmmss');
        String yy = timeStr.substring(0,4);
        String mm = timeStr.substring(4,6);
        String dd = timeStr.substring(6,8);
        String hh = timeStr.substring(8,10);
        String ms = timeStr.substring(10,12);
        String ss = timeStr.substring(12,14);
        String sch = ss + ' ' +
               ms + ' ' +
               hh + ' ' +
               dd + ' ' +
               mm + ' ' +
               ' ? ' + yy;
        String jobName = DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
        String jobId = system.schedule(jobName, sch, bppb);
        Test.stopTest();
        // パラメータ設定なしの場合、メール送信を行う
        List<Attachment> rsAtt = [select id from attachment where parentId = :rsv.Id];
    }
    // パラメータ:3
    static testMethod void case07(){
    	Document doc1 = new Document();
        doc1.Name = 'KanSyncFieldConvertConfig';
        doc1.DeveloperName = doc1.Name;
        doc1.FolderId = UserInfo.getUserId();
        doc1.Body = Blob.valueOf(getCsvSetupConfig());
        insert doc1;
        
        Document doc2 = new Document();
        doc2.Name = 'BillSimpleHelpConfig';
        doc2.DeveloperName = doc2.Name;
        doc2.FolderId = UserInfo.getUserId();
        doc2.Body = Blob.valueOf(getCsvSetupConfig2());
        insert doc2;
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'KanSyncFieldConvertConfig'].size(), 1);
        // 2015/12/01 Assert END
        RsvAccount__c rsv = createRsvAccount();  
        List<CollaborationGroup> groups = TestCommon.createGroups(1);
        CommDefine__c comDef = TestCommon.createCommDefine();
        comDef.ScheduleResultMailAddress__c = '111@aaa.com';
        comDef.SchedulePcaResultSendType__c = '3';
        comDef.SchedulePcaDeviationDays__c = 0;
        comDef.ChatterGroupName__c = '4:'+groups[0].name + ';4,4:';
        update comDef;

        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfo, productLst[0]);
        // 予約情報のステータス：チェックインに変更する
        leadInfo.Field298__c = 'チェックイン完';
        update leadInfo;
        
        Test.startTest();
        BulkProcessKANBatch bppb = new BulkProcessKANBatch('',date.today(),Date.today(),new list<string>{'PCABatch'});
        DateTime nowTime = DateTime.now().addSeconds(100);
        String timeStr = nowTime.format('yyyyMMddHHmmss');
        String yy = timeStr.substring(0,4);
        String mm = timeStr.substring(4,6);
        String dd = timeStr.substring(6,8);
        String hh = timeStr.substring(8,10);
        String ms = timeStr.substring(10,12);
        String ss = timeStr.substring(12,14);
        String sch = ss + ' ' +
               ms + ' ' +
               hh + ' ' +
               dd + ' ' +
               mm + ' ' +
               ' ? ' + yy;
        String jobName = DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
        String jobId = system.schedule(jobName, sch, bppb);
        Test.stopTest();
        // パラメータ設定なしの場合、メール送信を行う
        List<Attachment> rsAtt = [select id from attachment where parentId = :rsv.Id];
    }
    private static String getCsvSetupConfig() {
        String csv = '<root><SHOP><SHOPCODE></SHOPCODE><PCA><PCA_FIELD><VER>#2</VER><STARTNO>6001</STARTNO><CALCULATIONKBN>0</CALCULATIONKBN><JOURNALKBN>1</JOURNALKBN><MANAGEACCJOUKBN>0</MANAGEACCJOUKBN><DEBDEPARTCODE>180</DEBDEPARTCODE><DEBCONSUMPTAX>0</DEBCONSUMPTAX><CREDEPARTCODE>180</CREDEPARTCODE><CRECONSUMPTAX>0</CRECONSUMPTAX><INPUTPROGRAMKBN>HANYOU</INPUTPROGRAMKBN></PCA_FIELD><PCA_TAX><KANJOCODE>3350</KANJOCODE></PCA_TAX><PCA_ADVPAY_L><KANJOCODE>3241003</KANJOCODE></PCA_ADVPAY_L><PCA_ADVPAY_R><KANJOCODE>3241003</KANJOCODE></PCA_ADVPAY_R></PCA><CASH><CASH_INPUT><CONVERT><KEMOKU>内金</KEMOKU><I_KANJOCODE>1110</I_KANJOCODE><O_KANJOCODE>3241002</O_KANJOCODE></CONVERT><CONVERT><KEMOKU>レンタル料金</KEMOKU><I_KANJOCODE>1110</I_KANJOCODE><O_KANJOCODE>3241</O_KANJOCODE></CONVERT></CASH_INPUT><CASH_OUTPUT><CONVERT><KEMOKU>交通費</KEMOKU><I_KANJOCODE>1841</I_KANJOCODE><O_KANJOCODE>1110</O_KANJOCODE></CONVERT></CASH_OUTPUT></CASH></SHOP>'
                    + '</root>';
        return csv;
    }
    private static String getCsvSetupConfig2() {
        String csv = '<?xml version="1.0" encoding="UTF-8"?>'
                                +'<root><SHOP><SHOPCODE></SHOPCODE><PAYMENT><CONVERT><PAYTYPE>現金</PAYTYPE><MEIDALAB>預り／現計</MEIDALAB></CONVERT><CONVERT><PAYTYPE>カード</PAYTYPE><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB></CONVERT><CONVERT><PAYTYPE>売掛金</PAYTYPE><MEIDALAB>掛計</MEIDALAB></CONVERT><CONVERT><PAYTYPE>クーポン</PAYTYPE><MEIDALAB>クーポン</MEIDALAB></CONVERT><CONVERT><PAYTYPE>値引</PAYTYPE><MEIDALAB>値引・割引券</MEIDALAB></CONVERT><CONVERT><PAYTYPE>予約金</PAYTYPE><MEIDALAB>予約金</MEIDALAB></CONVERT>'
                                +
                                '</PAYMENT><PAYMEIDA>'
                                    +'<CONVERT><MEIDALAB>預り／現計</MEIDALAB><PRODCODE>T90001</PRODCODE></CONVERT>'
                                    +'<CONVERT><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB><PRODCODE>T90002</PRODCODE></CONVERT>'
                                    +'<CONVERT><MEIDALAB>掛計</MEIDALAB><PRODCODE>T90003</PRODCODE></CONVERT>'
                                    +'<CONVERT><MEIDALAB>クーポン</MEIDALAB><PRODCODE>T90004</PRODCODE></CONVERT>'
                                    +'<CONVERT><MEIDALAB>値引・割引券</MEIDALAB><PRODCODE>T90005</PRODCODE></CONVERT>'
                                    +'<CONVERT><MEIDALAB>予約金</MEIDALAB><PRODCODE>T90006</PRODCODE></CONVERT>'
                                    +'</PAYMEIDA></SHOP></root>';
		return csv;
    }
    private static RsvAccount__c createSimpleRsvAccount() {
        RsvAccount__c item = new RsvAccount__c();
        item.name = DateTime.now().format('yyyyMMdd');
        upsert item name;
        return item;	
    }
    private static RsvAccount__c createRsvAccount() {
		RsvAccount__c rsv = createSimpleRsvAccount();
		createAccount();
		return rsv;
    }
    private static void createAccount() {
		// 商品作成する
		List<AccountMaster__c> prodList = TestCommon.createProductMst(1);
		// 
		SimpleAccountsCtrl ctrl = new SimpleAccountsCtrl();
		ctrl.mediaType = ctrl.mediaTypeOptionLst[1].getValue();
		ctrl.otran.Field20__c = '16000';
		ctrl.otran.Field21__c = '2';
		ctrl.otran.Field7__c = prodList[0].Id;
		ctrl.otran.ActionType__c = prodList[0].ActionType__c;
		ctrl.otran.TaxRate__c = prodList[0].TaxRateCal__c;
		ctrl.otran.ServiceRate__c = prodList[0].ServiceRate__c;
		ctrl.otran.SpecialTax__c = 200;
		ctrl.productNm = prodList[0].Name;
		
		ctrl.saveTranToMemory();
		
		ctrl.upsertData();
    }
}