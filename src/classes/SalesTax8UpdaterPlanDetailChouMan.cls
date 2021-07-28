/**
* プラン明細の消費税設定内容更新対応バッチ
* 既存のプラン明細に、消費税率は５％のデータの消費税は８％に更新を行う
* 2014/03/18 Create
**/
public with sharing class SalesTax8UpdaterPlanDetailChouMan  implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

	public final String Query;					// 検索SOQL
	
	// 増税開始の日付を定義する
	//private static final Date CONST_TAXRATE_CHGDATE = Date.newInstance(2014,4,1); 
	//private static final String CONST_BATCH_STATUS = '1';	// 2014/04/01 ５％ー＞８％へ増税処理済みフラグ
	// 2019/08/12 消費税は8%から10%に変更対応 WGCH BEGIN
	/*
	private static final Decimal CONST_OLD_TAXRATE = 5;
	private static final Decimal CONST_NEW_TAXRATE = 8;
	*/
	private static final Decimal CONST_OLD_TAXRATE = 8;
	private static final Decimal CONST_NEW_TAXRATE = 10;
	// 2019/08/12 消費税は8%から10%に変更対応 WGCH END
	private static final String CONST_SF_BASEURL = 'https://login.salesforce.com';
	// 処理成功件数と失敗件数統計する
	private Integer IsOKCounts;
	private Integer IsNgCounts;
	private String errorMessage;
	// スケジュール定義者
	private Id scheduleCreatedById;
	
	// スケジュールインスタンス関数
	public SalesTax8UpdaterPlanDetailChouMan () {}
	// バッチ起動インスタンス関数
	public SalesTax8UpdaterPlanDetailChouMan (Id userId) {

		Query = ' Select Id, Name, TaxRate__c from PlanDetail__c where TaxRate__c = :CONST_OLD_TAXRATE ';
		IsOKCounts = 0;
		IsNgCounts = 0;
		errorMessage = '';
		scheduleCreatedById = userId;
	}
	// ***********************************
	// スケジュール処理開始
	// ***********************************
   public void execute(SchedulableContext SC) {
   	  // スケジュール定義情報を取得して、スケジュール定義者へバッチ処理結果を送信する
   	  CronTrigger cron = [Select CreatedById From CronTrigger Where Id = :SC.getTriggerId() ];
      SalesTax8UpdaterPlanDetailChouMan batch = new SalesTax8UpdaterPlanDetailChouMan(cron.CreatedById);
      DataBase.executeBatch(batch);
   }
	// ***********************************
	// バッチ処理開始
	// ***********************************
	public Database.QueryLocator start(Database.BatchableContext BC){
    	return Database.getQueryLocator(Query);
	}

	/**
	* 情報集計
	**/
	public void execute(Database.BatchableContext BC, List<PlanDetail__c> scope){
		// 2018/03/07 Security Check BEGIN
		List<String> chkFields = new List<String>{'TaxRate__c'};
		Map<String,Schema.SObjectField> m = Schema.SObjectType.PlanDetail__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(chkFields, m)) {
			return;
		}
		// 2018/03/07 Security Check END	
		// 更新対象リスト    	
		List<PlanDetail__c> updLst = new List<PlanDetail__c>();
		// 更新対象予約見積明細情報を取得、更新内容を設定する
		for (PlanDetail__c subItem : scope) {
			subItem.TaxRate__c = CONST_NEW_TAXRATE;
			updLst.add(subItem);
		}
		if (!updLst.isEmpty()) {
			try {
				Database.SaveResult[] results = Database.update(updLst,false);
				if (results != null){
					Integer idx = 0;
					for (Database.SaveResult result : results) {
						if (!result.isSuccess()) {
							// エラー件数統計
							IsNgCounts++;
							Database.Error[] errs = result.getErrors();
							for(Database.Error err : errs) {
								errorMessage += '\nエラー発生：' + updLst[idx].Name + '('+err.getStatusCode() + ' - ' + err.getMessage()+')'+ '\n';
								errorMessage += CONST_SF_BASEURL + '/'+updLst[idx].Id;
							}	
						} else {
							// 成功件数統計
							IsOKCounts++;
						}
						idx++;
					}
				}
			} catch (Exception e) {
				System.debug(e.getTypeName() + ' - ' + e.getCause() + ': ' + e.getMessage());
			}
		}
	}
	/**
	* 処理終了
	**/
	public void finish(Database.BatchableContext BC){
		//　スケジュール定義者のメールで送付する
		User setupUser = [select email from User where id = :scheduleCreatedById];
		String mailAdds = setupUser.email;
		if (CommUtils.isBlank(mailAdds)) return;
		
		// 未更新件数を統計する[5%のまま]
		AggregateResult rsAvg = [Select count(id) cnt from PlanDetail__c where TaxRate__c = :CONST_OLD_TAXRATE];
		Integer noUpdateRsNum = Integer.valueOf(rsAvg.get('cnt'));
		
		// メール情報を設定する
		String mailBodyStr = '処理結果詳細';
		mailBodyStr += '\n更新成功件数：' + IsOKCounts + '(件)';
		mailBodyStr += '\n更新失敗件数：' + IsNgCounts + '(件)';
		mailBodyStr += '\n未更新対象件数：' + (noUpdateRsNum - IsNgCounts) + '(件)';
		if (noUpdateRsNum != IsNgCounts ) {
			mailBodyStr += '\n未更新対象データが存在するため、データを確認の上て、バッチを再実施してください。';
		}
		mailBodyStr += errorMessage;
		
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = new String[]{mailAdds};
		mail.setToAddresses(toAddresses);
		mail.setSubject('[SalesTax8UpdaterPlanDetailChouMan] バッチ処理結果の通知');
		mail.setPlainTextBody(mailBodyStr);
		// テストクラスの場合、実施しない
		if(!Test.isRunningTest())
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	}
/**
*2015-11-18 
*テストクラスSalesTax8UpdaterPlanDetailChouManTestに移行する
	@isTest(SeeAllData=false)
	static void testCase1() {
 
		// ２０１４・０３・３０開始４連泊予約情報を設定する
		Date startDt = Date.newInstance(2014,3,30);
		Date changeDate = Date.newInstance(2014,4,1);
    	// 予約情報を作成する(4連泊予約情報を作成する)
    	Plan__c plan = TestCommon.createPlan();
		// 見積もり明細情報を更新を行う（消費税マスタは５％のまま、更新する場合、2014/04/01以後の見積もり明細の消費税率は全部８％に変更されるの確認
		List<PlanDetail__c> confirms = [select Id, TaxRate__c from PlanDetail__c where PlanRef__c = :plan.Id];
		for (PlanDetail__c planDetail : confirms) {
			planDetail.TaxRate__c = 5;
		}
		confirms[0].TaxRate__c = 4;
		update confirms;
		
		Test.startTest();
		SalesTax8UpdaterPlanDetailChouMan m = new SalesTax8UpdaterPlanDetailChouMan();
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
		
		SalesTax8UpdaterPlanDetailChouMan batch = new SalesTax8UpdaterPlanDetailChouMan(UserInfo.getUserId());
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		List<PlanDetail__c> items = [select Id, TaxRate__c from PlanDetail__c where PlanRef__c = :plan.Id And TaxRate__c = 8];
		// 全部明細件数を計算する
		System.assertEquals(items.size(), confirms.size()-1);
		/*
		for (PlanDetail__c item : items) {
			system.assertEquals(item.TaxRate__c, 8, item);
		}*/
/**
*2015-11-18 
*テストクラスSalesTax8UpdaterPlanDetailChouManTestに移行する
	}
*/

}