global with sharing class SalesTax8UpdaterChouMan3  implements Database.Batchable<sObject>, Database.Stateful, Schedulable{
    private static final String Query = 'select id,TaxRate__c,BatchProcessStatusDiv__c,PlanDetailSyncInfo__c from BookingEstimateItem__c where TaxRate__c = :CONST_NEW_TAXRATE and BatchProcessStatusDiv__c = :CONST_BATCH_STATUS and ActionType__c =:CONST_BOOK_PLAN and ParentBookingItemRef__c = null';
	private static final String TranQuery = ' Select Id, Name, Field1__c,Field1__r.Name, Field1__r.Relreserve__r.LeadIndexRef__c, Field1__r.Relreserve__r.LeadIndexSubId__c, Field1__r.Relreserve__r.RoomGroupNo__c, TaxRate__c, Field20__c, Field41__c, SpecialTax__c, ServiceRate__c, Field21__c, ParentTran1Ref__c, BatchProcessStatusDiv__c, Field7__c, UnitPriceDefKbCal__c, ActionType__c,PlanDetailSyncInfo__c from Tran1__c  where TaxRate__c = :CONST_NEW_TAXRATE and BatchProcessStatusDiv__c = :CONST_BATCH_STATUS and ActionType__c =:CONST_BOOK_PLAN and ParentTran1Ref__c = null';
    private static final Decimal CONST_OLD_TAXRATE = 8;
    private static final Decimal CONST_NEW_TAXRATE = 10;
    private static final String CONST_BATCH_STATUS = '2';	// 2014/04/01 ５％ー＞８％へ増税処理済みフラグ
	private static final String CONST_BATCH_ROLLBACK = '3';	// 2014/04/01 ５％ー＞８％へ増税処理済みフラグ
    private static final String CONST_BOOK_PLAN = commconst.PROD_ACTION_TYPE_PL;
	private static final String CONST_STATUS_TYPE = 'tran1';
    // 処理成功件数と失敗件数統計する
	private String errorMessage;
	private String createById;
	// スケジュール定義者
	private Id scheduleCreatedById;
	// 処理タイプ
	public String currentStatus;
	private Set<String> tranParIds;
    // スケジュールインスタンス関数
    global SalesTax8UpdaterChouMan3() {}
	// バッチ起動インスタンス関数
	global SalesTax8UpdaterChouMan3 (Id userId) {
		errorMessage = '';
		scheduleCreatedById = userId;
		tranParIds = new set<String>();
	}

	// ***********************************
	// スケジュール処理開始
	// ***********************************
   public void execute(SchedulableContext SC) {
   	  // スケジュール定義情報を取得して、スケジュール定義者へバッチ処理結果を送信する
   	  CronTrigger cron = [Select CreatedById From CronTrigger Where Id = :SC.getTriggerId() ];
	  createById = cron.CreatedById;
      SalesTax8UpdaterChouMan3 batch = new SalesTax8UpdaterChouMan3(createById);
      DataBase.executeBatch(batch,50);
   }
	// ***********************************
	// バッチ処理開始
	// ***********************************
	public Database.QueryLocator start(Database.BatchableContext BC){
		String sqlQuery = CommUtils.isBlank(currentStatus) ? Query : TranQuery;
		// DEBUG
    	return Database.getQueryLocator(sqlQuery);
	}

	/**
	* 情報集計
	**/
	public void execute(Database.BatchableContext BC, List<Sobject> scopes){
		// 会計明細対応
		if (currentStatus == CONST_STATUS_TYPE) processTran1(scopes);
		// 見積もり明細対応
		else processBookingest(scopes);
		
	}
	// 見積もり明細対応
	private void processBookingest(List<BookingEstimateItem__c> bookingests){
		// 2018/03/07 Security Check BEGIN
		List<String> chkFields = new List<String>{'TaxRate__c','SpTotal__c','BatchProcessStatusDiv__c'};
		Map<String,Schema.SObjectField> m = Schema.SObjectType.BookingEstimateItem__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(chkFields, m)) {
			return;
		}
		// 見積もり明細対応
        List<BookingEstimateItem__c> bookingLst = new List<BookingEstimateItem__c>();
		Set<id> parIds = new Set<Id>();
		// 2018/03/07 Security Check END
        for (BookingEstimateItem__c booking : bookingests) {
            if (!CommUtils.isBlank(booking.PlanDetailSyncInfo__c)) {
                parIds.add(booking.id);
                booking.TaxRate__c = CONST_OLD_TAXRATE;
				booking.BatchProcessStatusDiv__c = CONST_BATCH_ROLLBACK;
                bookingLst.add(booking);
            }
        }
        if (!parIds.isEmpty()) {
            for (BookingEstimateItem__c item : [select id from BookingEstimateItem__c where ParentBookingItemRef__c=:parIds]){
                item.TaxRate__c = CONST_OLD_TAXRATE;
				item.BatchProcessStatusDiv__c = CONST_BATCH_ROLLBACK;
                bookingLst.add(item);
            }
        }
        DataFixManagerUtils.stopTranTriggger();
        update bookingLst;
		DataFixManagerUtils.begTranTriggger();
	}
	// 会計明細対応
	private void processTran1(List<Tran1__c> tran1s){
		// 見積もり明細対応
		String tranIdFix = Tran1__c.sObjectType.getDescribe().getKeyPrefix();
        for (Tran1__c booking : tran1s) {
System.debug(loggingLevel.info, 'booking.PlanDetailSyncInfo__c='+booking.PlanDetailSyncInfo__c);
            if (!CommUtils.isBlank(booking.PlanDetailSyncInfo__c) && booking.PlanDetailSyncInfo__c.startsWith(tranIdFix)) {
                tranParIds.add(booking.Field1__c);
            }
        }
	}
	/**
	* 処理終了
	**/
	public void finish(Database.BatchableContext BC){
		if (CommUtils.isBlank(currentStatus)) {
			SalesTax8UpdaterChouMan3 batch = new SalesTax8UpdaterChouMan3(createById);
			batch.currentStatus = CONST_STATUS_TYPE;
      		DataBase.executeBatch(batch,50);
		} else 
		if (currentStatus == CONST_STATUS_TYPE) {
			//　スケジュール定義者のメールで送付する
			List<User> setupUsers = [select email from User where id = :createById];
			String mailAdds = '';
			if (!setupUsers.isEmpty()) {
				mailAdds = setupUsers[0].email;
			}
			if (!CommUtils.isBlank(mailAdds) && !tranParIds.isEmpty()) {
				// メール情報を設定する
				String mailBodyStr = '処理結果詳細';
				String errBodyStr = '';
				
				if (tranParIds != null && !tranParIds.isEmpty()) {
					errBodyStr += '\n該当会計関連の会計明細金額が再確認が必要：\n';
					for (String tranId : tranParIds) {
						errBodyStr += '\n会計：' + CommConst.SF_PROR_BASEURL + '/' + tranId;
					}
				}
				mailBodyStr += errBodyStr;
				
		System.debug(loggingLevel.info, 'mailBodyStr='+mailBodyStr);
				Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
				String[] toAddresses = new String[]{mailAdds};
				mail.setToAddresses(toAddresses);
				mail.setSubject('[SalesTax8UpdaterChouMan3] バッチ処理結果の通知');
				mail.setPlainTextBody(mailBodyStr);
				// テストクラスの場合、実施しない
				if(!Test.isRunningTest())
				Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
			}
			//　スケジュール定義者のメールで送付する
			SalesTax8UpdaterChouMan2 schedult = new SalesTax8UpdaterChouMan2(scheduleCreatedById);
			schedult.currentStatus = CONST_BATCH_ROLLBACK;
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
			String jobName = 'SalesTax8UpdaterChouMan2_' + DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
			String jobId = system.schedule(jobName, sch, schedult);
		}
		
	}
	
}