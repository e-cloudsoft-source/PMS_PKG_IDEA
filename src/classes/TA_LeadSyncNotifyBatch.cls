public with sharing class TA_LeadSyncNotifyBatch implements  Schedulable{
	
	//定数
	private static final string CONST_RESULT_FUNCTION_TYPE_LEAD_IMPORT = '予約取込';
	private static final String SERVICE_KEY = TA_ServiceCtrl.SERVICE_KEY;

	public TA_LeadSyncNotifyBatch(){}
	// ***********************************
	// スケジュール処理開始
	// ***********************************
	public void execute(SchedulableContext SC) {
		//clear lead__c 
		integer leadDeleteVal = -14;
		try {
			leadDeleteVal = TA_ServiceConfigHelp.getCommConfig().mLeadDeleteVal;
			Date clearDate = Date.today().addDays(leadDeleteVal);
			// 2018/03/07 Security Check BEGIN
			if (!CommSecurityUtils.isDeleteable(CooperationResult__c.getSObjectType())) {
				return;
			}
			// 2018/03/07 Security Check END
			// 過去履歴情報を削除する
			List<CooperationResult__c> parentCooLst = [select id from CooperationResult__c where createdDate < :clearDate  and FunctionType__c = :CONST_RESULT_FUNCTION_TYPE_LEAD_IMPORT and ProcessingType__c = :SERVICE_KEY limit 1000];
			if (!parentCooLst.isEmpty()) DataBase.delete (parentCooLst, false);
		} catch (exception e){}
		// 管理データを作成する
		TA_ServiceConfigHelp.insUpdLeadLockData();
		// 2016/12/14 該当バッチは処理中止するがどうかチェック　Wgch BEGIN
		if (TA_ServiceConfigHelp.isLeadBatchStopCheck()) {
			System.abortJob(SC.getTriggerId());
			return;
		}
		// 2016/12/14 該当バッチは処理中止するがどうかチェック　Wgch END
		// バッチ処理を開始する
		TA_LeadSyncNotifyBatchExtend batch = new TA_LeadSyncNotifyBatchExtend();
		// バッチ処理設定
		Id batchJobId = DataBase.executeBatch(batch, 1);
		// スケジュールABORTする　
		System.abortJob(SC.getTriggerId());
	} 
}