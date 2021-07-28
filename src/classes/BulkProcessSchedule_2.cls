/*
* バッチ処理自動起動スケジュール
* バッチ起動日付により、処理日の売上情報更新を行う
* バッチ日の売上更新ボタン機能を呼び出し
*/
// 2020/03/31 会計ロック機能 by zy BEGIN
public with sharing class BulkProcessSchedule_2 implements Database.Batchable<sObject>, Schedulable, Database.Stateful{
// 2020/03/31 会計ロック機能 by zy END
	private Boolean isFromSchedule;				// スケジュールからバッチ起動する
	private String gSaleDate;					// 売上計上日
	// 2020/03/31 会計ロック機能 by zy BEGIN
	private String errorMsg;
	// 2020/03/31 会計ロック機能 by zy END
	// スケジュールで該当Methodを呼び出する
	public BulkProcessSchedule_2() {
		isFromSchedule = true;
	}
	// 手動でリクエストバッチから起動の場合
	public BulkProcessSchedule_2(Date pSaleDate) {
		isFromSchedule = false;
		gSaleDate = DateTime.newInstance(pSaleDate.year(), pSaleDate.month(), pSaleDate.day()).format('yyyyMMdd');
	}
	// バッチ起動インスタンス化
	private BulkProcessSchedule_2(String pSaleDate, Boolean pIsFromSchedule) {
			isFromSchedule = pIsFromSchedule;
			gSaleDate = pSaleDate;
	}
	public void execute(SchedulableContext SC) {
		// 2016/08/25 SF初期化値を紛失機能回避
		if (isFromSchedule == null) isFromSchedule = true;
		if (isFromSchedule) {
			// システム日と処理日の差異日数
      		Integer days = CommDefine__c.getOrgDefaults().Schedule1DeviationDays__c == null ? 0 : CommDefine__c.getOrgDefaults().Schedule1DeviationDays__c.intValue();
      		//BulkProcessBatch batch = new BulkProcessBatch();
      		gSaleDate = (DateTime.now().addDays(days)).format('yyyyMMdd');
		}

		// 「売上更新」ボタン機能
		//ssumaccount.getrevenue(rsv[0].Id);
		// バッチクラスを呼び出す
		BulkProcessSchedule_2 batch = new BulkProcessSchedule_2(gSaleDate,isFromSchedule);
		// バッチ処理設定
		DataBase.executeBatch(batch, 1);
   }
	// ***********************************
	// バッチ処理開始
	// ***********************************
	public Database.QueryLocator start(Database.BatchableContext BC){
		return Database.getQueryLocator('select id,Name from RsvAccount__c where name = :gSaleDate');
	}
	// ***********************************
	// バッチロジック処理開始
	// ***********************************
	public void execute(Database.BatchableContext BC, List<RsvAccount__c> scope){
		// 2020/03/31 会計ロック機能 by zy BEGIN
		try{
		// 2020/03/31 会計ロック機能 by zy END
		ssumaccount.summaryNewInfo(scope[0].Id);
		// 2020/03/31 会計ロック機能 by zy BEGIN
		} catch(exception e){			 errorMsg  =  CommUtils.getFieldValidationMessage(e.getmessage());
		}
		// 2020/03/31 会計ロック機能 by zy END
	}
	// ***********************************
	// バッチ終了処理開始
	// ***********************************
	public void finish(Database.BatchableContext BC){
		// メール送信
		sendFreeeMail();
	}
	/**
	* メール送信機能対応:
	**/
	private void sendFreeeMail() {
		// 連携結果履歴に記録する
		// メール通知先のメールアドバイスを取得、設定する
		AccountingSyncBatchHelp config = new AccountingSyncBatchHelp('');
		// 送付先メールアドレス情報を取得する
		if (config == null || config.sendMailAddr.isEmpty()) return;
		// メール情報を設定する
		//売上バッチが以下の通リ終了しましたのでお知らせいたします。
		String mailBodyStr = Label.INF_0003_02;
		//売上計上日:
		mailBodyStr += '\n'+ Label.CONST_046_0025 +' ' + gSaleDate;
		// 2020/03/31 会計ロック機能 by zy BEGIN
		if (!CommUtils.isBlank(errorMsg)) {
			mailBodyStr += '\n' + Label.MSG_036_0014 + '\n' + errorMsg;
		}
		// 2020/03/31 会計ロック機能 by zy END
		mailBodyStr += '\n\n' + Label.INF_9001 + '\n';	//  JinyaConnect Enterprise system R&D team.

	    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = config.sendMailAddr;
		mail.setToAddresses(toAddresses);
		//売上バッチ処理結果の通知
		mail.setSubject('['+UserInfo.getOrganizationName()+'] ' + Label.CONST_046_0026);
		mail.setPlainTextBody(mailBodyStr);
	   	// テストクラスの場合、実施しない
		if(!Test.isRunningTest())
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	}
}