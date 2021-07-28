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
private class SyncStatusManagerCtrlTest {
	// SysncStatusManager Method Test
    static testMethod void case001() {
        // XML DEFINE CREATE
        initSetupConfig();
        getCsvSetupConfig();
        //
        SyncStatusManagerCtrl ctrl = new SyncStatusManagerCtrl();
        ctrl.init();
        SyncStatusManagerCtrl.BatchChkAndRestore batChk = ctrl.batChkAndRestore;
        List<SyncStatusManagerCtrl.BatchStatusInfo> batchDefLst = batChk.batchStatusLst;
        String uuid = CommUtils.getRandom(10);
        SyncStatusManagerCtrl.BatchStatusInfo batch = batchDefLst[0];
        SyncStatusManagerCtrl.stopBatchProcess(batch.jobTypeStr, uuid, batch.jsonStr);
        SyncStatusManagerCtrl.restBatchProcess(batch.jobTypeStr, uuid, batch.jsonStr);
        SyncStatusManagerCtrl.refreshBatchStatus(batch.jobTypeStr, uuid, batch.jsonStr, false);
        
        batch = batchDefLst[1];
        SyncStatusManagerCtrl.stopBatchProcess(batch.jobTypeStr, uuid, batch.jsonStr);
        SyncStatusManagerCtrl.restBatchProcess(batch.jobTypeStr, uuid, batch.jsonStr);
        SyncStatusManagerCtrl.refreshBatchStatus(batch.jobTypeStr, uuid, batch.jsonStr, false);
        
        batch = batchDefLst[2];
        SyncStatusManagerCtrl.stopBatchProcess(batch.jobTypeStr, uuid, batch.jsonStr);
        SyncStatusManagerCtrl.restBatchProcess(batch.jobTypeStr, uuid, batch.jsonStr);
        SyncStatusManagerCtrl.refreshBatchStatus(batch.jobTypeStr, uuid, batch.jsonStr, false);
        
        batch = batchDefLst[3];
        SyncStatusManagerCtrl.stopBatchProcess(batch.jobTypeStr, uuid, batch.jsonStr);
        SyncStatusManagerCtrl.restBatchProcess(batch.jobTypeStr, uuid, batch.jsonStr);
        SyncStatusManagerCtrl.refreshBatchStatus(batch.jobTypeStr, uuid, batch.jsonStr, false);

        batch = batchDefLst[4];
        SyncStatusManagerCtrl.stopBatchProcess(batch.jobTypeStr, uuid, batch.jsonStr);
        SyncStatusManagerCtrl.restBatchProcess(batch.jobTypeStr, uuid, batch.jsonStr);
        SyncStatusManagerCtrl.refreshBatchStatus(batch.jobTypeStr, uuid, batch.jsonStr, false);

        batch = batchDefLst[5];
        SyncStatusManagerCtrl.stopBatchProcess(batch.jobTypeStr, uuid, batch.jsonStr);
        SyncStatusManagerCtrl.restBatchProcess(batch.jobTypeStr, uuid, batch.jsonStr);
        SyncStatusManagerCtrl.refreshBatchStatus(batch.jobTypeStr, uuid, batch.jsonStr, false);
        
        SyncStatusManagerCtrl.BatchStatusInfo watchBat = batchDefLst[6];
        SyncStatusManagerCtrl.stopBatchProcess(watchBat.jobTypeStr, uuid, watchBat.jsonStr);
        SyncStatusManagerCtrl.restBatchProcess(watchBat.jobTypeStr, uuid, watchBat.jsonStr);
        SyncStatusManagerCtrl.refreshBatchStatus(watchBat.jobTypeStr, uuid, watchBat.jsonStr, true);
        
    }
    // SyncStatusManagerUploadCtrl Test Case
    /*
    static testMethod void case002_01() {
		// XML DEFINE CREATE
        initSetupConfig();
        // TL IMP XML
        // TA IMP XML
        CooperationResult__c coo = TestCommon.createTaLeadImportAndImpotNG('');
        Attachment att = TestCommon.createTa2waySyncAttachment(coo.id);
        // UPLOADテスト
    	SyncStatusManagerUploadCtrl ctrl = new SyncStatusManagerUploadCtrl();
    	ctrl.init();
    	ctrl.xmlUpd.xmlUpdShopCode = '';
    	System.assert(ctrl.xmlUpd.isCanUpload);
    	ctrl.filehand.setFileName('TestUploadFile');
		ctrl.filehand.setFileBody(att.body);
		ctrl.xmlUpd.processingType = SyncStatusManagerCtrl.JOBTYPE.TAIMP.name();
		ctrl.uploadLeadXml();
		SyncStatusManagerUploadCtrl.UploadResult updRs = ctrl.updRs;
		System.debug(loggingLevel.info, updRs);
    }*/
    static testMethod void case002_02() {
		// XML DEFINE CREATE
        initSetupConfig();
        // TL IMP XML
        CooperationResult__c coo = TestCommon.createLeadImportAndWaitImpot('');
        Attachment att = TestCommon.createTl2waySyncAttachment(coo.id);
        // UPLOADテスト
    	SyncStatusManagerUploadCtrl ctrl = new SyncStatusManagerUploadCtrl();
    	ctrl.init();
    	/*
    	ctrl.xmlUpd.xmlUpdShopCode = '';
    	System.assert(ctrl.xmlUpd.isCanUpload);
    	ctrl.filehand.setFileName('TestUploadFile');
		ctrl.filehand.setFileBody(att.body);
		ctrl.xmlUpd.processingType = SyncStatusManagerCtrl.JOBTYPE.TLIMP.name();
		ctrl.uploadLeadXml();*/
		// 連携結果はNGのデータは再表示、復旧処理を行う
		CooperationResult__c upd = [select Status__c from CooperationResult__c where id = :coo.id];
		upd.Status__c = CommConst.COOP_FUNTYPE_LEADIMP_NG;
		update upd;
		//検索
		List<SelectOption> opts = ctrl.retryTargetLst;
		DateTime nowDt = System.now();
		String begDt = nowDt.format(CommBaseCtrl.getDateFormat());
		String endDt = nowDt.format(CommBaseCtrl.getDateFormat());
		// TL
		List<SyncStatusManagerUploadCtrl.SyncResultInfo> rs = SyncStatusManagerUploadCtrl.getLeadRetryViewInfo('',begDt,endDt, opts[0].getValue());
		System.assertEquals(rs.size(),1,rs);
		List<Id> restoreIds = new List<Id>();
		for (SyncStatusManagerUploadCtrl.SyncResultInfo item : rs) {
			restoreIds.add(item.sfid);
		}
		SyncStatusManagerUploadCtrl.syncRestoreStatus(restoreIds);
		SyncStatusManagerUploadCtrl.RestoreResultInfo refRs = SyncStatusManagerUploadCtrl.refreshRestoreStatus(restoreIds);
    }
    // Watch Batch Test
    static testMethod void case003_01() {
		// XML DEFINE CREATE
        initSetupConfig();
        List<CollaborationGroup> groups = TestCommon.createGroups(1);
        CommDefine__c comDef = TestCommon.createCommDefine();
        comDef.ChatterGroupName__c = CommConst.Coop_ChatterGroupNameType+':'+groups[0].name;
        update comDef;
        // 指定時刻からスケジールを起動する
        DateTime startTime = system.now();
        DateTime nextTime = startTime.addMinutes(1);
		// 起動ＣＲＯＮを設定する
		String timeStr = nextTime.format('yyyyMMddHHmmss');
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
		Test.startTest();
        SyncStatusManagerWatchBatch watch = new SyncStatusManagerWatchBatch(startTime);
		String jobName = 'SyncStatusManagerWatchBatch_' + DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, sch, watch);
		Test.stopTest();
    }
    private static String getCsvSetupConfig() {
        String csv = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP><SHOPCODE>01</SHOPCODE>		<!-- 店舗コード --><ISDEBUG></ISDEBUG><ACCOUNTSWITCH>true</ACCOUNTSWITCH><CASHSWITCH>true</CASHSWITCH><PRINTCONFIG NAME="POS01">	<WEBSOCKET>wss</WEBSOCKET>	<PRINT>192.168.10.107</PRINT>	<PRINTPORT>443</PRINTPORT>	<POSNO>001</POSNO></PRINTCONFIG><DEVICECONFIG>	<DEVICE>		<ACCOUNT>false</ACCOUNT>		<LOCAL>192.168.10.122</LOCAL>		<PRINTER>POS01</PRINTER>	</DEVICE>	<DEVICE>		<LOCAL>192.168.10.120</LOCAL>		<PRINTER>POS01</PRINTER>	</DEVICE>	<DEVICE>		<ALLRETURN>true</ALLRETURN>		<LOCAL>192.168.10.123</LOCAL>		<PRINTER>POS01</PRINTER>	</DEVICE></DEVICECONFIG><PRICEMAPPING>	<CONVERT>		<APINAME>TenThousandCashNums__c</APINAME><CHANGE>紙幣機内総金額-1万円</CHANGE>	</CONVERT>	<CONVERT>		<APINAME>FiveThousandCashNums__c</APINAME><CHANGE>紙幣機内総金額-5千円</CHANGE>	</CONVERT>	<CONVERT>		<APINAME>TwoThousandCashNums__c</APINAME><CHANGE>紙幣機内総金額-2千円</CHANGE>	</CONVERT>	<CONVERT>		<APINAME>OneThousandCashNums__c</APINAME><CHANGE>紙幣機内総金額-1千円</CHANGE>	</CONVERT>	<CONVERT>		<APINAME>FiveHundredCashNums__c</APINAME><CHANGE>硬貨機内総金額-500円</CHANGE>	</CONVERT>	<CONVERT>		<APINAME>OneHundredCashNums__c</APINAME><CHANGE>硬貨機内総金額-100円</CHANGE>	</CONVERT>	<CONVERT>		<APINAME>FiftyCashNums__c</APINAME><CHANGE>硬貨機内総金額-50円</CHANGE>	</CONVERT>	<CONVERT>		<APINAME>TenCashNums__c</APINAME> <CHANGE>硬貨機内総金額-10円</CHANGE>	</CONVERT>	<CONVERT>		<APINAME>FiveCashNums__c</APINAME> <CHANGE>硬貨機内総金額-1円</CHANGE>	</CONVERT></PRICEMAPPING></SHOP></root>';
        Document doc = new Document();
        doc.Name = 'ChangeMachineConfig';
        doc.DeveloperName = doc.Name;
        doc.FolderId = UserInfo.getUserId();
        doc.Body = Blob.valueOf(csv);
        insert doc;
        return csv;
    }
    private static void initSetupConfig() {
	    String configXml = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP><SHOPCODE></SHOPCODE><TLIMPJOBCONFIG><BATCHLABEL>TL予約取込</BATCHLABEL><BATCHOPEN>TRUE</BATCHOPEN></TLIMPJOBCONFIG><TLSTOCKJOBCONFIG><BATCHLABEL>TL在庫調整</BATCHLABEL><BATCHOPEN>TRUE</BATCHOPEN></TLSTOCKJOBCONFIG><TAIMPJOBCONFIG><BATCHLABEL>TA予約取込</BATCHLABEL><BATCHOPEN>TRUE</BATCHOPEN></TAIMPJOBCONFIG><TASTOCKJOBCONFIG><BATCHLABEL>TA在庫調整</BATCHLABEL><BATCHOPEN>TRUE</BATCHOPEN></TASTOCKJOBCONFIG>'+
	    '<JRIMPJOBCONFIG><BATCHLABEL>JR予約取込</BATCHLABEL><BATCHOPEN>FALSE</BATCHOPEN></JRIMPJOBCONFIG><JRSTOCKJOBCONFIG><BATCHLABEL>JR在庫調整</BATCHLABEL><BATCHOPEN>FALSE</BATCHOPEN></JRSTOCKJOBCONFIG>'+
	    '<WATCHBATCHCONFIG><BATCHLABEL>監視バッチ</BATCHLABEL><BATCHOPEN>TRUE</BATCHOPEN><INTERVAL>60</INTERVAL><APEXJOBNAME>2way監視バッチ</APEXJOBNAME><SENDMAIL>true</SENDMAIL></WATCHBATCHCONFIG></SHOP></root>';
		Document doc = new Document();
		doc.Name = 'SyncStatusManagerConfigXml';
		doc.DeveloperName = doc.Name;
		doc.FolderId = UserInfo.getUserId();
		doc.Body = Blob.valueOf(configXml);
		insert doc;
		
		TestCommon.createTl2WayConfigDoc();
    	TestCommon.createTa2WayConfigDoc();
    	TestCommon.createTaxMst();
    	TestCommon.createBillSimpleHelpConfigDoc();
	}
}