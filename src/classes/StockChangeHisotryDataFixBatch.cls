global with sharing class StockChangeHisotryDataFixBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
	
	// 更新処理対象
 	private static final String Query = ' Select Id,StockChangeDateKey__c,StockChangeDate__c from StockChangeHisotry__c where StockChangeDateKey__c = null ';
	// 処理成功件数と失敗件数統計する
	private Integer IsOKCounts;
	private Integer AllRsSize;
	private Integer dataSize = 2000;
	private String errMsg;
	private String scheduleCreatedById;
	global StockChangeHisotryDataFixBatch () {}
	global StockChangeHisotryDataFixBatch (Integer psize) {
		dataSize = psize;
	}
	// バッチ起動インスタンス関数
	public StockChangeHisotryDataFixBatch (Id userId) {
		scheduleCreatedById = userId;
		IsOKCounts = 0;
		AllRsSize = 0;
		errMsg = '';
	}
	// ***********************************
	// スケジュール処理開始
	// ***********************************
	public void execute(SchedulableContext SC) {
   	  // スケジュール定義情報を取得して、スケジュール定義者へバッチ処理結果を送信する
   	  CronTrigger cron = [Select CreatedById From CronTrigger Where Id = :SC.getTriggerId() ];
      StockChangeHisotryDataFixBatch batch = new StockChangeHisotryDataFixBatch(cron.CreatedById);
      DataBase.executeBatch(batch, dataSize);
	}
	// ***********************************
	// バッチ処理開始
	// ***********************************
	public Database.QueryLocator start(Database.BatchableContext BC){
		if (!DataFixManagerUtils.getInstance().StockChangeHisotryFixed__c) {
    		return Database.getQueryLocator(Query);
		} else {
			// 既に処理済み場合、該当バッチ処理を飛ばす
			return Database.getQueryLocator(Query + ' limit 0');
		}
		// 共通定義
	}
	// ***********************************
	// バッチロジック処理開始
	// ***********************************
	public void execute(Database.BatchableContext BC, List<StockChangeHisotry__c> scope){
		if (scope == null) return;
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'stockchangedatekey__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.StockChangeHisotry__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
			return ;
		}
		// 2019/09/15 Security Check BY zyz END
		List<StockChangeHisotry__c> updLst = new list<StockChangeHisotry__c>();
		for (StockChangeHisotry__c s : scope) {
			Date d = s.StockChangeDate__c;
			if (d != null) {
				String strDt = DataFixManagerUtils.dateToYMDstr(d);
				if (s.StockChangeDateKey__c != strDt) {
					s.StockChangeDateKey__c = strDt;
					updLst.add(s);
				}
			}
		}
		try {
			string httpKey = 'https://login.salesforce.com/';
			AllRsSize += updLst.size();
			list<Database.SaveResult> saveRs = Database.update(updLst,false);
			Integer i=0;
			for (Database.SaveResult rs : saveRs) {
				if (rs.isSuccess()) {
					IsOKCounts++;
				} else {
					Database.Error err = rs.getErrors()[0];
					errMsg += err.getMessage() +'('+httpKey+updLst[i].Id+')\n';
				}
				i++;
			}
		} catch (Exception e) {}
		
	}
	// ***********************************
	// バッチ終了処理開始
	// ***********************************
	public void finish(Database.BatchableContext BC){

		if (AllRsSize <> IsOKCounts) {
			//　スケジュール定義者のメールで送付する
			User setupUser = [select email from User where id = :scheduleCreatedById order by createddate asc limit 1];
			String mailAdds = setupUser.email;
			if (CommUtils.isBlank(mailAdds)) return;
			// メール情報を設定する
			String mailBodyStr = '処理結果詳細	BEGIN';
			mailBodyStr += '\n更新成功件数：' + IsOKCounts + '(件)';
			mailBodyStr += '\n更新失敗件数：' + (AllRsSize-IsOKCounts) + '(件)';
			mailBodyStr += 	errMsg;
			mailBodyStr += '\n処理結果詳細	END';
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			String[] toAddresses = new String[]{mailAdds};
			mail.setToAddresses(toAddresses);
			mail.setSubject('[在庫変更履歴データ更新] バッチ処理結果の通知['+UserInfo.getOrganizationName()+']');
			mail.setPlainTextBody(mailBodyStr);
			// テストクラスの場合、実施しない
			if(!Test.isRunningTest()) {
				try {
				Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
				} catch(Exception e){}
			}
		} else {
			// 全部処理対象がOK場合、パラメータはTRUEに更新する
			(new DataFixManagerUtils()).updStockChangeHisotryFixed(true);
		}
		// 2018/09/10 データ自動FIX機能を一時CLOSEする
		/*
		try {
			DataFixBatchForLead batch = new DataFixBatchForLead(scheduleCreatedById);
			DataBase.executeBatch(batch, 2000);
		} catch (Exception e){}
		*/
	}

}