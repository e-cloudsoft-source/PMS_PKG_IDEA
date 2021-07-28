public with sharing class BulkProcessLeadAccounRefFixBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    
    private final String Query;                 // 検索SOQL
	public Integer leadRsNums;					// 集計件数
    public BulkProcessLeadAccounRefFixBatch(){
        // 検索
        // 共通定義がFALSEの場合、処理しない制限を行う
        Query = CommConst.LEAD_REFACCOUNT_AUTOSETUP_FLG 
                ?
                'Select Id,refAccount__c,LeadAccountIdCal__c From Lead__c where CancelBool__c != 1 and AccountRefDiffFlgCal__c != true '
                :
                'Select id from Lead__c limit 0';
		// 集計件数
		leadRsNums = 0;
    }
    // ***********************************
    // スケジュール処理開始
    // ***********************************
    public void execute(SchedulableContext SC) {
        // バッチ処理設定
        BulkProcessLeadAccounRefFixBatch batch = new BulkProcessLeadAccounRefFixBatch();
        DataBase.executeBatch(batch,2000);
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
    public void execute(Database.BatchableContext BC, List<Lead__c> scope){
        // 取引先情報が一致しない場合、取引先IDを更新する　
        for (Lead__c p : scope) {
            p.refAccount__c = p.LeadAccountIdCal__c;
        }
        DataFixManagerUtils.stopTranTriggger();
        Database.update(scope);
        leadRsNums += scope.size();
        DataFixManagerUtils.begTranTriggger();
    }
    // ***********************************
    // バッチ終了処理開始
    // ***********************************
    public void finish(Database.BatchableContext BC){
		// メール送信
		String mailAdds = CommDefine__c.getOrgDefaults().ScheduleResultMailAddress__c;
		// メールアドレス未設定する場合、メール送信しない
		if (CommUtils.isBlank(mailAdds)) return;
		String mailBodyStr = 'ご予約の請求先更新処理が以下の通リ終了しましたのでお知らせいたします。';
		//処理件数:
		mailBodyStr += '\n処理件数： ' + leadRsNums;
		mailBodyStr += '\n\n' + Label.INF_9001 + '\n';    //  JinyaConnect Enterprise system R&D team.
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = mailAdds.split(',');
		mail.setSubject('[ご予約の請求先更新]バッチ処理結果の通知');
		mail.setToAddresses(toAddresses);
		mail.setPlainTextBody(mailBodyStr);
		// テストクラスの場合、実施しない
		if(!Test.isRunningTest())
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}