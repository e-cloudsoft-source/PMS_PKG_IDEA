global with sharing class DataFixBatchForLead implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
	
	// 更新処理対象
 	// 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
 	// private static final String Query = ' Select Id,EntryTime__c,EntryDateKey__c,Departure__c,DepartureDateKey__c from Lead__c Where EntryDateKey__c = null and CancelBool__c != 1 and DAY_ONLY(convertTimezone(EntryTime__c)) >= LAST_N_DAYS:30 ';
	private static final String Query = ' Select Id,EntryTime__c,EntryDateKey__c,Departure__c,DepartureDateKey__c,EntryDateIntKey__c,DepartureDateIntKey__c from Lead__c Where EntryDateIntKey__c = null and CancelBool__c != 1 and DAY_ONLY(convertTimezone(EntryTime__c)) >= LAST_N_DAYS:30 ';
	// 2020/08/30 部屋状態管理インデックス機能対応 WGCH END
	// 処理成功件数と失敗件数統計する
	private Integer IsOKCounts;
	private Integer AllRsSize;
	private Integer dataSize = 2000;
	private String errMsg;
	private String scheduleCreatedById;
	global DataFixBatchForLead () {}
	global DataFixBatchForLead (Integer psize) {
		dataSize = psize;
	}
	// バッチ起動インスタンス関数
	public DataFixBatchForLead (Id userId) {
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
    	DataFixBatchForLead batch = new DataFixBatchForLead(cron.CreatedById);
    	DataBase.executeBatch(batch, dataSize);
	}
	// ***********************************
	// バッチ処理開始
	// ***********************************
	public Database.QueryLocator start(Database.BatchableContext BC){
		// 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
		/*
		if (!DataFixManagerUtils.getInstance().LeadFixed__c) {
    		return Database.getQueryLocator(Query);
		} else {
			// 既に処理済み場合、該当バッチ処理を飛ばす
			return Database.getQueryLocator(Query + ' limit 0');
		}
		*/
		// 回避新功能失效设定 LeadFixed__c => Flase; LeadFixed1__c => Flase
		return Database.getQueryLocator(Query);
		// 2020/08/30 部屋状態管理インデックス機能対応 WGCH END
	}
	// ***********************************
	// バッチロジック処理開始
	// ***********************************
	public void execute(Database.BatchableContext BC, List<Lead__c> scope){
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'entrydatekey__c','departuredatekey__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.Lead__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
			return ;
		}
		// 2019/09/15 Security Check BY zyz END
		if (scope == null) return;
		// 店舗ごとの予約・会計権限はOFF
		DataFixManagerUtils utils = new DataFixManagerUtils();
		utils.beginCommDefOpt();
		List<Lead__c> updLst = new list<Lead__c>();
		for (Lead__c s : scope) {
			Boolean isChgFlg = false;
			Date sd = (s.EntryTime__c != null ? s.EntryTime__c.date() : null);
			if (sd != null) {
				String str = DataFixManagerUtils.dateToYMDstr(sd);
				if (s.EntryDateKey__c != str) {
					s.EntryDateKey__c = str;
					isChgFlg = true;
				}
				// 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
				Integer intKey = CommUtils.nullToIntZero(str);
				if (s.EntryDateIntKey__c != intKey) {
					s.EntryDateIntKey__c = intKey;
					isChgFlg = true;
				}
				// 2020/08/30 部屋状態管理インデックス機能対応 WGCH END
			}
			Date ed = (s.Departure__c != null ? s.Departure__c.date() : null);
			if (ed != null) {
				String str = DataFixManagerUtils.dateToYMDstr(ed);
				if (s.DepartureDateKey__c != str) {
					s.DepartureDateKey__c = str;
					isChgFlg = true;
				}
				// 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
				Integer intKey = CommUtils.nullToIntZero(str);
				if (s.DepartureDateIntKey__c != intKey) {
					s.DepartureDateIntKey__c = intKey;
					isChgFlg = true;
				}
				// 2020/08/30 部屋状態管理インデックス機能対応 WGCH END
			}
			if (isChgFlg) updLst.add(s);
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
		
		// 店舗ごとの予約・会計権限の設定戻る
		utils.endCommDefOpt();
	}
	// ***********************************
	// バッチ終了処理開始
	// ***********************************
	public void finish(Database.BatchableContext BC){
		// 更新結果にエラーデータが存在する場合、メッセージ通知を行う
system.debug(logginglevel.info, 'AllRsSize='+AllRsSize);
system.debug(logginglevel.info, 'IsOKCounts='+IsOKCounts);
		if (AllRsSize <> IsOKCounts) {
			//　スケジュール定義者のメールで送付する
			User setupUser = [select email from User where id = :scheduleCreatedById order by createddate asc limit 1];
			String mailAdds = setupUser.email;
			if (CommUtils.isBlank(mailAdds)) return;
			// メール情報を設定する
			String mailBodyStr = '処理結果詳細	BEGIN';
			mailBodyStr += '\n更新成功件数：' + IsOKCounts + '(件)';
			mailBodyStr += '\n更新失敗件数：' + (AllRsSize-IsOKCounts) + '(件)';
			mailBodyStr += '\n下記データは自動更新失敗するため、予約画面からデータ編集、保存してください\n';	
			mailBodyStr += 	errMsg;
			mailBodyStr += '\n処理結果詳細	END';
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			String[] toAddresses = new String[]{mailAdds};
			mail.setToAddresses(toAddresses);
			mail.setSubject('[予約データ更新] バッチ処理結果の通知['+UserInfo.getOrganizationName()+']');
			mail.setPlainTextBody(mailBodyStr);
			// テストクラスの場合、実施しない
			if(!Test.isRunningTest()) {
				try {
				Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
				} catch(Exception e){}
			}
			System.debug(loggingLevel.info,mailBodyStr );
		} else {
			// 全部処理対象がOK場合、パラメータはTRUEに更新する
			(new DataFixManagerUtils()).updLeadKeyFixed(true);
		}
	} 
}