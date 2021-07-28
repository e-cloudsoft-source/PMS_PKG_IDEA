/*
* 処理バッチ連続起動機能コントロール
* 2014/07/17 為替レート取得バッチ起動時間機能対応
* 
*/
public with sharing class BulkProcessSchedule implements Schedulable {
	
	// スケジュール定義起動
	public void execute(SchedulableContext SC) {
		Integer exchangeStartHour = CommUtils.nullToIntZero(CommDefine__c.getOrgDefaults().ExchangeRateStartHours__c);
		if (exchangeStartHour < 0 || exchangeStartHour > 23) {
			
   	  		// スケジュール定義情報を取得して、スケジュール定義者へバッチ処理結果を送信する
   	  		CronTrigger cron = [Select CreatedById From CronTrigger Where Id = :SC.getTriggerId() ];
      		Id scheduleCreatedById = cron.CreatedById;
			//　スケジュール定義者のメールで送付する
			User setupUser = [select email from User where id = :scheduleCreatedById];
			String mailAdds = setupUser.email;
		
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			String[] toAddresses = new String[]{mailAdds};
			mail.setToAddresses(toAddresses);
			//為替レート取得結果の通知
			//(エラー)
			mail.setSubject('['+UserInfo.getOrganizationName()+']'+ Label.MSG_006_0322 + Label.MSG_006_0323);
			// パラメータ設定不正のメール送信
			//為替レート取得バッチ起動時間（HH）パラメータ設定不正、０〜２３間数値定義してください。
			String mailBodyStr = Label.MSG_006_0324 +'('+exchangeStartHour+')';
			mail.setPlainTextBody(mailBodyStr);
			// テストクラスの場合、実施しない
			if(!Test.isRunningTest())
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
		} else {
			// バッチ起動時間により、設定時間は早いの場合、翌日の該当設定時間から起動する
			DateTime nowTime = System.now().addSeconds(60);
			Integer nowHour = nowTime.hour();
			// スケジュール起動の時間は為替レート取得の起動時間により、以後の時間の場合、翌日の指定時間を起動する
			if (nowHour >= exchangeStartHour) {
				nowTime = nowTime.addDays(1);
			}
			// 起動ＣＲＯＮを設定する
			String timeStr = nowTime.format('yyyyMMddHHmmss');
			String yy = timeStr.substring(0,4);
			String mm = timeStr.substring(4,6);
			String dd = timeStr.substring(6,8);
			String hh = CommUtils.paddingLeftZero(exchangeStartHour,2);
			String sch = 00 + ' ' +
			       00 + ' ' +
			       hh + ' ' +
			       dd + ' ' +
			       mm + ' ' +
			       ' ? ' + yy;
			FinanceXchangeService m = new FinanceXchangeService();
			String jobName = DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
			String jobId = system.schedule(jobName, sch, m);
		}	
	}
}