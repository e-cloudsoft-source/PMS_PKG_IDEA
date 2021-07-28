/*
* RFM利用回数集計バッチ
* 2014/07/30 処理前の事前チェック処理追加
* 2015/06/18 ご利用回数のカウントについて、チェックイン後に+1するように変更
* 2017/05/26 予約インデックス単位で集計する場合、ご予約情報からお客様対象に変更対応
*/
public with sharing class BulkProcessRRMBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

	public Integer contactRsNums;
	public final String Query;					// 検索SOQL
	public final Date queryEndDate;				// バッチ実施日
	private static String CONST_USAGECONUNT_SINGLE = '1';
	private final String contactUsageCountDiv;
	public BulkProcessRRMBatch(){
		// 検索
		Query = 'Select Id,Usage_Count__c,Usage_Charge__c,LastUsageDate__c From Contact';
		//Query = 'select  Relcontact__c from Lead__c where Relcontact__c in :contactIdSet And CancelBool__c != 1 
		// 集計日
		queryEndDate = Date.today();
		// 集計件数
		contactRsNums = 0;
		// カスタム設定により、情報を設定する
		contactUsageCountDiv = 	CommDefine__c.getOrgDefaults().ContactUsageCountDiv__c == null
								? CONST_USAGECONUNT_SINGLE
								: CommDefine__c.getOrgDefaults().ContactUsageCountDiv__c;
	}
	// ***********************************
	// スケジュール処理開始
	// ***********************************
	public void execute(SchedulableContext SC) {
		// バッチ処理設定
		BulkProcessRRMBatch batch = new BulkProcessRRMBatch();
		DataBase.executeBatch(batch);
	}
	// ***********************************
	// バッチ処理開始
	// ***********************************
	public Database.QueryLocator start(Database.BatchableContext BC){
		return Database.getQueryLocator(Query);
	}
	// ***********************************
	// バッチロジック処理開始
	// ***********************************
	public void execute(Database.BatchableContext BC, List<Contact> scope){
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'usage_charge__c','usage_count__c','lastusagedate__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.Contact.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
			return ;
		}
		// 2019/09/15 Security Check BY zyz END
		// お客様IDの配列リスト格納
		Set<Id> contactIdSet = new Set<Id>();
		for (Contact c : scope) {
			contactIdSet.add(c.Id);
		}
		// 有効な予約データ[泊数単位で統計する]
		List<AggregateResult> UsageCountRs = null;
		if (contactUsageCountDiv == CONST_USAGECONUNT_SINGLE) {
			UsageCountRs = [select  Relcontact__c contactId, count(Id) cunt, max(EntryTime__c) lastUseDate 
					   		from Lead__c 
							where Relcontact__c in :contactIdSet And CancelBool__c != 1 
							And DAY_ONLY(convertTimezone(EntryTime__c)) <= :queryEndDate
							And Field298__c != null
							group by Relcontact__c];
		} else {
			// 有効な予約インデクスデータ
			// 2017/05/26 予約インデックス単位で集計する場合、ご予約情報からお客様対象に変更対応 BEGIN
			//UsageCountRs = [select LeadIndexRef__r.contactRef__c contactId, COUNT_DISTINCT(LeadIndexRef__c) cunt, max(EntryTime__c) lastUseDate 
			UsageCountRs = [select Relcontact__c contactId, COUNT_DISTINCT(LeadIndexRef__c) cunt, max(EntryTime__c) lastUseDate 
			// 2017/05/26 予約インデックス単位で集計する場合、ご予約情報からお客様対象に変更対応 END
					   		from Lead__c 
							where Relcontact__c in :contactIdSet 
							And CancelBool__c != : CommConst.LEAD_ST_CANCEL_FLG
							And Field298__c != null
							And DAY_ONLY(convertTimezone(EntryTime__c)) <= :queryEndDate
							And LeadIndexRef__r.ParentLeadIndxRef__c = null	//予約インデクスSUB対象外にする
							// 2017/05/26 予約インデックス単位で集計する場合、ご予約情報からお客様対象に変更対応 BEGIN
							//And LeadIndexRef__r.StatusLst__c != : CommConst.LEAD_ST_CANCEL	// 通常が必要
							//And LeadIndexRef__r.DataClassification__c != : BI_LeadInfoSync.BI_DmlAction.CANCEL.name()	// キャンセルが対象外
							//And LeadIndexRef__r.contactRef__c in :contactIdSet 
							//And LeadIndexRef__r.EntryDate__c <= :queryEndDate
							//group by LeadIndexRef__r.contactRef__c];
							group by Relcontact__c];
							// 2017/05/26 予約インデックス単位で集計する場合、ご予約情報からお客様対象に変更対応 END
		}
		Map<Id, Decimal> usageCountMap = new Map<Id, Decimal>();
		Map<Id, Date> lastUseDateMap = new Map<Id, Date>();
		for (AggregateResult rs : UsageCountRs) {
			Id contactId = (Id)rs.get('contactId');
			Decimal usageCnt = (Decimal)rs.get('cunt');
			usageCountMap.put(contactId, usageCnt);
			Date lastUseDate = ((DateTime)rs.get('lastUseDate')).date();
			lastUseDateMap.put(contactId, lastUseDate);
		}
		// 利用金額
		Map<Id, Decimal> usageChargeMap = new Map<Id, Decimal>();
		List<AggregateResult> UsageChargeRs = 
							[select relaccount__c contactId,sum(Field147__c) total 
							 from AccountAcount__c 
							 where  OutSideAccount__c = 1 
							 	And relaccount__c in :contactIdSet
							 	And SalesdayCal__c <= :queryEndDate
							 group by relaccount__c];
		for (AggregateResult rs : UsageChargeRs) {
			Id contactId = (Id)rs.get('contactId');
			Decimal usageCharge = (Decimal)rs.get('total');
			usageChargeMap.put(contactId, usageCharge);
		}
		List<Contact> updLst = new List<Contact>();
		for (Contact c : scope) {
			Decimal UsageCount = usageCountMap.containsKey(c.Id) ? usageCountMap.get(c.Id) : 0;
			Decimal UsageCharge = usageChargeMap.containsKey(c.Id) ? usageChargeMap.get(c.Id) : 0;
			Date LastUsageDate = lastUseDateMap.containsKey(c.Id) ? lastUseDateMap.get(c.Id) : null;
			if (CommUtils.nullToZero(c.Usage_Count__c) != UsageCount ||
				CommUtils.nullToZero(c.Usage_Charge__c) != UsageCharge ||
				c.LastUsageDate__c != LastUsageDate ) {
				c.Usage_Count__c = UsageCount;
				c.Usage_Charge__c = UsageCharge;
				c.LastUsageDate__c = LastUsageDate;
				updLst.add(c);	
			}
		}
		if(!updLst.isEmpty()) update updLst;
		// 集計件数設定
		contactRsNums += updLst.size();
	}
	// ***********************************
	// バッチ終了処理開始
	// ***********************************
	public void finish(Database.BatchableContext BC){
		// メール送信
		String mailAdds = CommDefine__c.getOrgDefaults().ScheduleResultMailAddress__c;
		// メールアドレス未設定する場合、メール送信しない
		if (CommUtils.isBlank(mailAdds)) return;
		// メール情報を設定する
		//String mailBodyStr ='集計処理が完了しました。';
		String mailBodyStr = Label.INF_0001;
		//更新日:
		mailBodyStr += '\n'+ Label.MSG_013_0026 +' ' + DateTime.newInstance(queryEndDate.year(),queryEndDate.month(),queryEndDate.day()).format('yyyy/MM/dd'); 
		//更新レコード件数:
		mailBodyStr += '\n'+ Label.MSG_013_0027 +' ' + contactRsNums;
		mailBodyStr += '\n\n' + Label.INF_9001;	//  JinyaConnect Enterprise system R&D team.
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = mailAdds.split(',');
		mail.setToAddresses(toAddresses);
		//mail.setSubject('[BulkProcessRRMBatch] バッチ集計結果の通知');
		//RFMバッチ処理結果の通知
		mail.setSubject('['+UserInfo.getOrganizationName()+'] '+ Label.MSG_013_0028);
		mail.setPlainTextBody(mailBodyStr);
		// テストクラスの場合、実施しない
		if(!Test.isRunningTest())
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	}
/**
*2015-11-18 
*テストクラスBulkProcessRRMBatchTestに移行する	
	// ***********************************
	// テストクラス実施
	// ***********************************
	@isTest(SeeAllData=false)
	static void testCase1() {
		CommDefine__c comDef = TestCommon.createCommDefine();
		comDef.AccountSaleDateSetupDiv__c = '1';
		comDef.ScheduleResultMailAddress__c = 'aaa@bbb.ccc.com';
		update comDef; 
		Date startDt = Date.today();
    	// 予約情報を作成する[プラン付け]
    	Lead__c leadInfo = TestCommon.createLead(startDt);
    	// 商品情報を作成する
		// Normal商品
		List<AccountMaster__c> productLst = TestCommon.createProductMst(2);
		// 見積明細を作成する
    	TestCommon.createBookEstItems(leadInfo, productLst);
    	// 予約情報のステータス：チェックインに変更する
    	leadInfo.Field298__c = 'チェックイン完';
    	update leadInfo;
    	// 会計画面に動作確認を行う
    	List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfo.Id];
    	AccountAcount__c accObj = accObjLst[0];

    	ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
    	BillInput_Ctrl ctrl = new BillInput_Ctrl(contrl);
    	ctrl.initAction();
    	ctrl.calPaymentInfo();
    	ctrl.upsertData();
    	
    	List<AccountAcount__c> accLst = [select OutSideAccount__c, relaccount__c,SalesdayCal__c,Field147__c from AccountAcount__c where Relreserve__c = :leadInfo.Id];
    	System.assertEquals(accLst.size(), 1, accLst);
    	System.assertEquals(accLst[0].relaccount__c, leadInfo.Relcontact__c, accLst);
    	System.assertEquals(accLst[0].OutSideAccount__c, 1, accLst);

		Test.startTest();

		BulkProcessRRMBatch m = new BulkProcessRRMBatch();
		DateTime nowTime = DateTime.now().addSeconds(10);
		// 起動ＣＲＯＮを設定する
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
		String jobId = system.schedule(jobName, sch, m);
		
		BulkProcessRRMBatch batch = new BulkProcessRRMBatch();
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		Contact cRs = [select Usage_Count__c,Usage_Charge__c,LastUsageDate__c From Contact where id = :leadInfo.Relcontact__c];
		System.assertEquals(cRs.Usage_Count__c, 1, cRs);
		System.assertEquals(cRs.Usage_Charge__c, accLst[0].Field147__c, cRs);
		System.assertEquals(cRs.LastUsageDate__c, leadInfo.EntryTime__c.date(), cRs);
	}
	//BulkProcessRRMBatch
	// 団体の場合、集計区分２、１来店１回利用回数計算するテスト
	@isTest(SeeAllData=false)
	static void testCase2() {
		Test.startTest();
		CommDefine__c comDef = TestCommon.createCommDefine();
		comDef.AccountSaleDateSetupDiv__c = '1';
		comDef.ContactUsageCountDiv__c = '2';		// お客様利用回数集計区分:2：実際の来店回数で集計（N部屋N泊連泊でも、１回で集計する）
		comDef.ScheduleResultMailAddress__c = 'aaa@bbb.ccc.com';
		update comDef; 
		Integer nights = 3;
		Date startDt = Date.today().addDays(-1*nights);
    	// 予約情報を作成する[プラン付け]
    	List<Lead__c> leads = TestCommon.createLead(startDt, 2, nights);
    	leads[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
    	update leads[0];
    	// 集計計算を行う
		BulkProcessRRMBatch batch = new BulkProcessRRMBatch();
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		Contact cRs = [select Usage_Count__c,Usage_Charge__c,LastUsageDate__c From Contact where id = :leads[0].Relcontact__c];
		System.assertEquals(cRs.Usage_Count__c, 1, cRs);
		//System.assertEquals(cRs.Usage_Charge__c, accLst[0].Field147__c, cRs);
		//System.assertEquals(cRs.LastUsageDate__c, leadInfo.EntryTime__c.date(), cRs);
	}
	// 団体の場合、集計区分２、１来店１回利用回数計算するテスト
	@isTest(SeeAllData=false)
	static void testCase2_0() {
		CommDefine__c comDef = TestCommon.createCommDefine();
		comDef.AccountSaleDateSetupDiv__c = '1';
		comDef.ContactUsageCountDiv__c = '2';		// お客様利用回数集計区分:2：実際の来店回数で集計（N部屋N泊連泊でも、１回で集計する）
		comDef.ScheduleResultMailAddress__c = 'aaa@bbb.ccc.com';
		comDef.RenpakuBatchCheckinIsCanFlg__c = false;
		update comDef; 
		Integer nights = 3;
		Date startDt = Date.today().addDays(-1*nights);
    	// 予約情報を作成する[プラン付け]
    	
    	List<Lead__c> leads = TestCommon.createLead(startDt, 2, nights);
    	Test.startTest();
    	List<Lead__c> leads2 = TestCommon.createLead(startDt, 2, nights, leads[0].Relcontact__c);
    	
    	List<Lead__c> updLeads = new List<Lead__c>();
    	leads[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
    	leads2[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
    	updLeads.add(leads[0]);
    	updLeads.add(leads2[0]);
    	update updLeads;
    	// 集計計算を行う
		BulkProcessRRMBatch batch = new BulkProcessRRMBatch();
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		Contact cRs = [select Usage_Count__c,Usage_Charge__c,LastUsageDate__c From Contact where id = :leads[0].Relcontact__c];
		System.assertEquals(cRs.Usage_Count__c, 2, cRs);
		
	}
	
	// 団体の場合、集計区分２、１来店１回利用回数計算するテスト[予約データはキャンセルされる場合]
	@isTest(SeeAllData=false)
	static void testCase2_1() {
		Test.startTest();
		CommDefine__c comDef = TestCommon.createCommDefine();
		comDef.AccountSaleDateSetupDiv__c = '1';
		comDef.ContactUsageCountDiv__c = '2';		// お客様利用回数集計区分:2：実際の来店回数で集計（N部屋N泊連泊でも、１回で集計する）
		comDef.ScheduleResultMailAddress__c = 'aaa@bbb.ccc.com';
		update comDef; 
		Integer nights = 3;
		Date startDt = Date.today().addDays(-1*nights);
    	// 予約情報を作成する[プラン付け]
    	List<Lead__c> leads = TestCommon.createLead(startDt, 2,nights);
    	for (Lead__c p : leads ) {
    		p.ReservedStatus__c = 'キャンセル';
    	}
    	update leads;
    	// 集計計算を行う
		BulkProcessRRMBatch batch = new BulkProcessRRMBatch();
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		Contact cRs = [select Usage_Count__c,Usage_Charge__c,LastUsageDate__c From Contact where id = :leads[0].Relcontact__c];
		System.assertEquals(CommUtils.nullToZero(cRs.Usage_Count__c), 0, cRs);
		//System.assertEquals(cRs.Usage_Charge__c, accLst[0].Field147__c, cRs);
		//System.assertEquals(cRs.LastUsageDate__c, leadInfo.EntryTime__c.date(), cRs);
	}
	// 団体の場合、集計区分２、１来店１回利用回数計算するテスト[予約データはキャンセルされる場合あり]
	@isTest(SeeAllData=false)
	static void testCase2_2() {
		CommDefine__c comDef = TestCommon.createCommDefine();
		comDef.AccountSaleDateSetupDiv__c = '1';
		comDef.ContactUsageCountDiv__c = '2';		// お客様利用回数集計区分:2：実際の来店回数で集計（N部屋N泊連泊でも、１回で集計する）
		comDef.ScheduleResultMailAddress__c = 'aaa@bbb.ccc.com';
		update comDef; 
		Integer nights = 3;
		Date startDt = Date.today().addDays(-1*nights);
    	// 予約情報を作成する[プラン付け]
    	List<Lead__c> leads = TestCommon.createLead(startDt, 2,nights);
    	Test.startTest();
    	for (Lead__c p : leads ) {
    		p.ReservedStatus__c = 'キャンセル';
    	}
    	update leads;
    	List<Lead__c> leads2 = TestCommon.createLead(startDt, 2,nights, leads[0].Relcontact__c);
    	leads2[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
    	update leads2[0];
    	// 集計計算を行う
		BulkProcessRRMBatch batch = new BulkProcessRRMBatch();
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		Contact cRs = [select Usage_Count__c,Usage_Charge__c,LastUsageDate__c From Contact where id = :leads[0].Relcontact__c];
		System.assertEquals(CommUtils.nullToZero(cRs.Usage_Count__c), 1, cRs);
	}
	// 団体の場合、集計区分２、１来店１回利用回数計算するテスト[予約データはキャンセルされる場合あり]
	@isTest(SeeAllData=false)
	static void testCase2_3() {
		CommDefine__c comDef = TestCommon.createCommDefine();
		comDef.AccountSaleDateSetupDiv__c = '1';
		comDef.ContactUsageCountDiv__c = '2';		// お客様利用回数集計区分:2：実際の来店回数で集計（N部屋N泊連泊でも、１回で集計する）
		comDef.ScheduleResultMailAddress__c = 'aaa@bbb.ccc.com';
		update comDef; 
		Integer nights = 3;
		Date startDt = Date.today().addDays(-1*nights);
    	// 予約情報を作成する[プラン付け]
    	List<Lead__c> leads = TestCommon.createLead(startDt, 2,nights);
    	Test.startTest();
    	List<Lead__c> leads2 = TestCommon.createLead(startDt, 2,nights, leads[0].Relcontact__c);
    	leads[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
    	//update leads[0];
    	leads2[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
    	//update leads2[0];
    	List<Lead__c> updLeads = new List<Lead__c>();
    	updLeads.add(leads[0]);
    	updLeads.add(leads2[0]);
    	update updLeads;
    	// 集計計算を行う
		BulkProcessRRMBatch batch = new BulkProcessRRMBatch();
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		Contact cRs = [select Usage_Count__c,Usage_Charge__c,LastUsageDate__c From Contact where id = :leads[0].Relcontact__c];
		System.assertEquals(CommUtils.nullToZero(cRs.Usage_Count__c), 2, cRs);
	}
	// 団体の場合、集計区分1、予約データ数が利用回数計算するテスト
	@isTest(SeeAllData=false)
	static void testCase3() {
		Test.startTest();
		CommDefine__c comDef = TestCommon.createCommDefine();
		comDef.AccountSaleDateSetupDiv__c = '1';
		comDef.ContactUsageCountDiv__c = '1';		// お客様利用回数集計区分:2：実際の来店回数で集計（N部屋N泊連泊でも、１回で集計する）
		comDef.ScheduleResultMailAddress__c = 'aaa@bbb.ccc.com';
		update comDef; 
		Integer nights = 3;
		Date startDt = Date.today().addDays(-1*nights);
    	// 予約情報を作成する[プラン付け]
    	List<Lead__c> leads = TestCommon.createLead(startDt, 2, nights);
    	for (Lead__c lead : leads) {
    		lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
    	}
    	update leads;
    	// 集計計算を行う
		BulkProcessRRMBatch batch = new BulkProcessRRMBatch();
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		Contact cRs = [select Usage_Count__c,Usage_Charge__c,LastUsageDate__c From Contact where id = :leads[0].Relcontact__c];
		System.assertEquals(cRs.Usage_Count__c, 6, cRs);
	}
	@isTest(SeeAllData=false)
	static void testCase3_1() {
		CommDefine__c comDef = TestCommon.createCommDefine();
		comDef.AccountSaleDateSetupDiv__c = '1';
		comDef.ContactUsageCountDiv__c = '1';		// お客様利用回数集計区分:2：実際の来店回数で集計（N部屋N泊連泊でも、１回で集計する）
		comDef.ScheduleResultMailAddress__c = 'aaa@bbb.ccc.com';
		update comDef; 
		Integer nights = 3;
		Date startDt = Date.today().addDays(-1*nights);
    	// 予約情報を作成する[プラン付け]
    	List<Lead__c> leads = TestCommon.createLead(startDt, 2, nights);
    	Test.startTest();
    	List<Lead__c> leads2 = TestCommon.createLead(startDt, 2,nights, leads[0].Relcontact__c);
    	
    	for (Lead__c lead : leads) {
    		lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
    	}
    	update leads;
    	for (Lead__c lead : leads2) {
    		lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
    	}
    	update leads2;
    	// 集計計算を行う
		BulkProcessRRMBatch batch = new BulkProcessRRMBatch();
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		Contact cRs = [select Usage_Count__c,Usage_Charge__c,LastUsageDate__c From Contact where id = :leads[0].Relcontact__c];
		System.assertEquals(cRs.Usage_Count__c, 12, cRs);
	}
*/
}