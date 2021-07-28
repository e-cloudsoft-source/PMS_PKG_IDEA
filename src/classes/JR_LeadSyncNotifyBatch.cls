/**
* 2way連携： 完了通知APIへ通信処理
* JR-リンカーン機能連携
* 2015/10/01 INIT
* 2016/08/08 JRの通信API処理結果はNGでも次の処理を続ける処理できるように変更
**/
//public with sharing class JR_LeadSyncNotifyBatch  implements  Database.Batchable<Sobject>, Database.Stateful, Schedulable ,Database.AllowsCallouts{
public with sharing class JR_LeadSyncNotifyBatch implements Schedulable {
	
	private static final string CONST_RESULT_FUNCTION_TYPE_LEAD_IMPORT = JR_ServiceCtrl.CONST_RESULT_FUNCTION_TYPE_LEAD_IMPORT;
	private static final String SERVICE_KEY = JR_ServiceCtrl.SERVICE_KEY;
	public JR_LeadSyncNotifyBatch(){}
	// ***********************************
	// スケジュール処理開始
	// ***********************************
	public void execute(SchedulableContext SC) {
		//clear lead__c 
		integer leadDeleteVal = -14;
		try {
			leadDeleteVal = BI_JR_ServiceConfigHelp.getCommConfig().mLeadDeleteVal;
			Date clearDate = Date.today().addDays(leadDeleteVal);
			// 2018/03/07 Security Check BEGIN
			if (!CommSecurityUtils.isDeleteable(CooperationResult__c.getSObjectType())) {
				return;
			}
			// 2018/03/07 Security Check END
			// 過去履歴情報を削除する
			List<CooperationResult__c> parentCooLst = [select id from CooperationResult__c where createdDate < :clearDate  and FunctionType__c = :CONST_RESULT_FUNCTION_TYPE_LEAD_IMPORT and ProcessingType__c = :SERVICE_KEY LIMIT 1000];
			if (!parentCooLst.isEmpty()) DataBase.delete (parentCooLst, false);
		} catch(exception e) {}
		// 管理データを作成する
		BI_JR_ServiceConfigHelp.insUpdLeadLockData();
		// バッチ状態チェック
		if (BI_JR_ServiceConfigHelp.isLeadBatchStopCheck()) {
			System.abortJob(SC.getTriggerId());
			return;
		}
		// バッチ処理を開始する「XML取り込みする」
		JR_LeadSyncXmlImportBatch batch = new JR_LeadSyncXmlImportBatch();
		// バッチ処理設定
		Id batchJobId = DataBase.executeBatch(batch, 1);
		// スケジュールABORTする　
		System.abortJob(SC.getTriggerId());
	}
}