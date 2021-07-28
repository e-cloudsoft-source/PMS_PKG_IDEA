global with sharing class DataFixBatchForRoomsStatus implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
   	// 更新処理対象
   	// 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
 	// private static final String Query = ' Select Id,StatusBeginDateKey__c,StatusBeginDate__c,StatusEndDate__c,StatusEndDateKey__c from RoomsStatus__c where StatusBeginDateKey__c = null ';
 	private static final String Query = ' Select Id,StatusBeginDateKey__c,StatusBeginDate__c,StatusEndDate__c,StatusEndDateKey__c,StatusBeginDateIntKey__c,StatusEndDateIntKey__c from RoomsStatus__c where StatusBeginDateIntKey__c = null ';
	// 2020/08/30 部屋状態管理インデックス機能対応 WGCH END
	// 処理成功件数と失敗件数統計する
	private Integer IsOKCounts;
	private Integer AllRsSize;
	private Integer dataSize = 2000;
	private String errMsg;
	private String scheduleCreatedById;
	global DataFixBatchForRoomsStatus () {}
	global DataFixBatchForRoomsStatus (Integer psize) {
		dataSize = psize;
	}
	// バッチ起動インスタンス関数
	public DataFixBatchForRoomsStatus (Id userId) {
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
      DataFixBatchForRoomsStatus batch = new DataFixBatchForRoomsStatus(cron.CreatedById);
      DataBase.executeBatch(batch, dataSize);
	}
	// ***********************************
	// バッチ処理開始
	// ***********************************
	public Database.QueryLocator start(Database.BatchableContext BC){
		// 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
		/*
		if (!DataFixManagerUtils.getInstance().RoomsStatusFixed__c) {
    		return Database.getQueryLocator(Query);
		} else {
			// 既に処理済み場合、該当バッチ処理を飛ばす
			return Database.getQueryLocator(Query + ' limit 0');
		}
		*/
		// 回避新功能失效设定 RoomsStatusFixed__c => Flase; RoomsStatusFixed1__c => True
		return Database.getQueryLocator(Query);
		// 2020/08/30 部屋状態管理インデックス機能対応 WGCH END
		// 共通定義
	}
	// ***********************************
	// バッチロジック処理開始
	// ***********************************
	public void execute(Database.BatchableContext BC, List<RoomsStatus__c> scope){
		if (scope == null) return;
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'StatusBeginDateKey__c','StatusBeginDate__c','StatusEndDate__c','StatusEndDateKey__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.RoomsStatus__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
			return ;
		}
		// 2019/09/15 Security Check BY zyz END
		List<RoomsStatus__c> updLst = new list<RoomsStatus__c>();
		for (RoomsStatus__c s : scope) {
			Boolean isChgFlg = false;
			Date sd = s.StatusBeginDate__c;
			if (sd != null) {
				String str = DataFixManagerUtils.dateToYMDstr(sd);
				if (s.StatusBeginDateKey__c != str) {
					s.StatusBeginDateKey__c = str;
					isChgFlg = true;
				}
				// 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
				Integer intKey = CommUtils.nullToIntZero(str);
				if (s.StatusBeginDateIntKey__c != intKey) {
					s.StatusBeginDateIntKey__c = intKey;
					isChgFlg = true;
				}
				// 2020/08/30 部屋状態管理インデックス機能対応 WGCH END
			}
			Date ed = s.StatusEndDate__c;
			if (ed != null) {
				String str = DataFixManagerUtils.dateToYMDstr(ed);
				if (s.StatusEndDateKey__c != str) {
					s.StatusEndDateKey__c = str;
					isChgFlg = true;
				}
				// 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
				Integer intKey = CommUtils.nullToIntZero(str);
				if (s.StatusEndDateIntKey__c != intKey) {
					s.StatusEndDateIntKey__c = intKey;
					isChgFlg = true;
				}
				// 2020/08/30 部屋状態管理インデックス機能対応 WGCH END
			}
			if (isChgFlg) {
				DataFixManagerUtils.stopTranTriggger();
				updLst.add(s);
				DataFixManagerUtils.begTranTriggger();
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
			mail.setSubject('[部屋状態管理更新] バッチ処理結果の通知['+UserInfo.getOrganizationName()+']');
			mail.setPlainTextBody(mailBodyStr);
			// テストクラスの場合、実施しない
			if(!Test.isRunningTest()) {
				try {
				Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
				} catch(Exception e){
system.debug(logginglevel.info, 'mailBodyStr='+mailBodyStr);
				}
			}
		} else {
			// 全部処理対象がOK場合、パラメータはTRUEに更新する
			(new DataFixManagerUtils()).updRoomsStatusFixed(true);
		}
	}
}