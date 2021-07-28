/*
 * 2way連携： 完了通知APIへ通信処理
 * TL-リンカーン機能連携
 * 2015/10/01 INIT
 * 2016/08/08 TLの通信API処理結果はNGでも次の処理を続ける処理できるように変更
 */
//public with sharing class TL_LeadSyncNotifyBatch  implements  Database.Batchable<Sobject>, Database.Stateful, Schedulable ,Database.AllowsCallouts{
public with sharing class TL_LeadSyncNotifyBatch implements Schedulable {
	
	private static final string CONST_RESULT_FUNCTION_TYPE_LEAD_IMPORT = '予約取込';
	private static final String SERVICE_KEY = TL_ServiceCtrl.SERVICE_KEY;
	// Apexスケジュールから起動
	public TL_LeadSyncNotifyBatch(){
		isChainSchFlg = false;
		beginDt = system.now();
	}
	// 定期バッチの開始日
	private DateTime beginDt;
	// Chain Batch Flg
	private boolean isChainSchFlg;
	// バッチChainから該当スケジュールを再起動の場合、該当バッチ初期起動の日付情報を格納する
	public TL_LeadSyncNotifyBatch(DateTime pBeginDate) {
		beginDt = pBeginDate;
		isChainSchFlg = true;
	}
	// ***********************************
	// スケジュール処理開始
	// ***********************************
	public void execute(SchedulableContext SC) {
		//clear lead__c 
		integer leadDeleteVal = -14;
		try {
			leadDeleteVal = TL_ServiceConfigHelp.getCommConfig().mLeadDeleteVal;
			Date clearDate = Date.today().addDays(leadDeleteVal);
			// 2018/03/07 Security Check BEGIN
   			if (!CommSecurityUtils.isDeleteable(CooperationResult__c.getSObjectType())){
   				return;
   			}
   			// 2018/03/07 Security Check END
			// 過去履歴情報を削除する
			List<CooperationResult__c> parentCooLst = [select id from CooperationResult__c where createdDate < :clearDate  and FunctionType__c = :CONST_RESULT_FUNCTION_TYPE_LEAD_IMPORT and ProcessingType__c = :SERVICE_KEY LIMIT 1000];
			if (!parentCooLst.isEmpty()) DataBase.delete (parentCooLst, false);
		} catch(exception e) {}
		// 管理データを作成する
		TL_ServiceConfigHelp.insUpdLeadLockData();
		// 2016/12/14 該当バッチは処理中止するがどうかチェック　Wgch BEGIN
		if (TL_ServiceConfigHelp.isLeadBatchStopCheck()) {
			System.abortJob(SC.getTriggerId());
			return;
		}
		// 定時実施のスケジュールに対して、新たChainのバッチを起動する場合、最新の日付を設定して、バッチを起動する
		if (!isChainSchFlg) beginDt = System.now();
		// 2016/12/14 該当バッチは処理中止するがどうかチェック　Wgch END
		// バッチ処理を開始する
		TL_LeadSyncNotifyBatchExtend batch = new TL_LeadSyncNotifyBatchExtend();
		// バッチ処理設定
		Id batchJobId = DataBase.executeBatch(batch, 1);
		// スケジュールABORTする　
		System.abortJob(SC.getTriggerId());
	}
}