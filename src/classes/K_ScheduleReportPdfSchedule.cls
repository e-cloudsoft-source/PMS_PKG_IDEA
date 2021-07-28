/**
* 予定表情報定期出力スケジュール
* 2017/01/17 INIT
* 
**/
public with sharing class K_ScheduleReportPdfSchedule implements Schedulable {
	// 2017/05/12 PDFpost等机能对应 BEGIN By Wgch
	/*
	public void execute(SchedulableContext SC) {

		// Chatterポスト先に定義情報を先に確認する
		List<String> chatterGroupNamesLst = CommConst.GetChatterGroupNameByCode(CommConst.KSCH_ChatterGroupNameType);
		if (chatterGroupNamesLst.isEmpty()) {
			// ポスト先にChatterグループを未設定の場合
			setSendMailAddress();
			//return;
		}
		List<CollaborationGroup> chatterGroups = [select Id, Name from CollaborationGroup where name = :chatterGroupNamesLst and isarchived = false];
		if (!chatterGroupNamesLst.isEmpty() && chatterGroups.isEmpty()) {
			// ポスト先にChatterグループを未設定の場合
			setSendMailAddress();
			//return;
		}
		// バッチ処理を開始する
		list<string> chatterGroupIdLst = new list<string>();
		for (CollaborationGroup col : chatterGroups) {
			chatterGroupIdLst.add(col.id);
		}

		K_ScheduleReportPdfBatch batch = new K_ScheduleReportPdfBatch(chatterGroupIdLst);
		// バッチ処理設定
		Id batchJobId = DataBase.executeBatch(batch, 1);
		// スケジュールABORTする　
		System.abortJob(SC.getTriggerId());
	}
	*/
	// 前回スケジール実施時間を格納る
	private DateTime preScheduleDt;
	public K_ScheduleReportPdfSchedule(){}
	public K_ScheduleReportPdfSchedule(DateTime dt){
		preScheduleDt = dt;
	}
	public void execute(SchedulableContext SC) {
		DateTime nowDt = System.now();
		Date todayDt = nowDt.date();
		if(preScheduleDt == null || preScheduleDt.date() < todayDt) {
			// 2018/03/07 Security Check BEGIN
			if (!CommSecurityUtils.isDeleteable(ReservationListWork__c.getSObjectType())) {
				return;
			}
			// 2018/03/07 Security Check END
			// 删除旧比較用情報
			delete [select Id from ReservationListWork__c Where EntryDate__c < :todayDt limit 10000];
		}
		// PDF処理バッチを起動する
		K_ScheduleReportPdfBatch batch = new K_ScheduleReportPdfBatch(nowDt);
		// バッチ処理設定
		Id batchJobId = DataBase.executeBatch(batch, 1);
		// スケジュールABORTする　
		System.abortJob(SC.getTriggerId());
	}

	/**
	* メール通知先のアドレス宛を設定する
	**/
	/*
	public void setSendMailAddress(){
		String mailAdds = CommDefine__c.getOrgDefaults().ScheduleResultMailAddress__c;
		// メール情報を設定する
		String errMsg = '予定表PDFポスト用チャターグループを未定義またはアーカイブされるため、予定表PDFポスト失敗になりました。\n\n';
		//エラー内容：
		if (CommUtils.isBlank(mailAdds)) return;
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = mailAdds.split(',');
		mail.setToAddresses(toAddresses);
		//スケジュール処理エラーの通知
		mail.setSubject('['+UserInfo.getOrganizationName()+'] '+ Label.MSG_036_0015);
		mail.setPlainTextBody(errMsg);
		// テストクラスの場合、実施しない
		if(!Test.isRunningTest()) Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	}
	*/
	// 2017/05/12 PDFpost等机能对应 END By Wgch
}