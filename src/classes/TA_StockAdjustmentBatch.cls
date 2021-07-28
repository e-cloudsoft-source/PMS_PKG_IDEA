/**
* バッチ:在庫調整対象情報
* INIT:初期化する
* 2015/10/28 残室数は０の場合、エラーは戻る、メールを送信する
* 2015/12/11 在庫調整機能改善：在庫マイナス設定対象外、残室数はNULLの場合、未処理のまま残り、在庫連携対象期間を設定
*            調整不可の室タイプは調整対象外になる
*            バッチ起動後作成の在庫調整情報のみ在庫連携を行う
* 2016/01/20 販売ステータスは２「停止中」の場合、該当室タイプグループは連携対象外する
* 2016/01/29 リアル（旅行会社）に対して、在庫更新要求を発行する・しない制御パラメータを追加
* 2016/02/19 論理連携済のデータ検索条件変更対応
* 2016/05/12 在庫調整日付はデータ取得条件から削除
**/
public with sharing class TA_StockAdjustmentBatch implements Schedulable {

	//public static final String STOCK_STATUS_NOSYNC = '未連携';
	//public static final String STOCK_STATUS_LOGIC_SYNCOK = '論理連携済';
	private final DateTime gScheduleBeginTime;
	// 処理単位のログ記述する
	//private CommLogUtils log = new CommLogUtils('TA_StockAdjustmentBatch', true);
	//private final String logManagerId = 'TA_STOCK_LOG_000000000';
	// スケジュールで該当Methodを呼び出する
	public TA_StockAdjustmentBatch(){
		gScheduleBeginTime = System.now();
	}
	// スケジュールからバッチ起動用Method
	public TA_StockAdjustmentBatch(DateTime pScheduleBeginTime) {
		// バッチ起動時間
		gScheduleBeginTime = pScheduleBeginTime;
	}
	// ***********************************
	// スケジュール処理開始
	// ***********************************
	public void execute(SchedulableContext SC) {
		// 管理データを作成する
		TA_ServiceConfigHelp.insUpdStockLockData();
		// 2016/12/14 該当バッチは処理中止するがどうかチェック　Wgch BEGIN
		if (TA_ServiceConfigHelp.isStockBatchStopCheck()) {
			System.abortJob(SC.getTriggerId());
			return;
		}
		// 2016/12/14 該当バッチは処理中止するがどうかチェック　Wgch END
		// バッチ処理起動チエックを行う
		//log.write_method_start('スケジュール実施');
		//log.write_log('スケジュール正常に起動された');
		//TA_ServiceConfigHelp.writeLogToDb(log.getAllLog(), logManagerId, true);
		// バッチ実施開始の情報をInsertする
		TA_StockAdjustmentBatchExtend batch = new TA_StockAdjustmentBatchExtend(gScheduleBeginTime);
		Id batchJobId = DataBase.executeBatch(batch,1);
		// スケジュールABORTする　
		System.abortJob(SC.getTriggerId());
		// 次のSTEP記録する
		//log.clear();
		//log.write_log('バッチ定義済み、JOBID:'+batchJobId);
		//log.write_method_end();
		//TA_ServiceConfigHelp.writeLogToDb(log.getAllLog(), logManagerId, false);
	}
}