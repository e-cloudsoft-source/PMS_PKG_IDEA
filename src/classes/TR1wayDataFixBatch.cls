public with sharing class TR1wayDataFixBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable{
	private static final String ServiceKey = 'TR';
 	// TODO：未来日　かつ　キャンセルされる対象外  AND id=\'a0kp00000015XUL\'
 	private static final String Query = ' Select Id,Name,Id__c from LeadIndex__c where ParentLeadIndxRef__c = null And OrgId__c = null And EventSource__c =  :eventSourceSet And (APPNAME__c = null or APPNAME__c = :ServiceKey) And EntryDate__c >= :VARTODAY ';
	// 処理成功件数と失敗件数統計する
	private Integer IsOKCounts;
	private String errorMessage;
	// スケジュール定義者
	private Id scheduleCreatedById;
	// テスト用XML情報格納用
	@TestVisible private String testLoadXmlMsg;
	public TR1wayDataFixBatch () {}
	// バッチ起動インスタンス関数
	public TR1wayDataFixBatch (Id userId) {
		scheduleCreatedById = userId;
		IsOKCounts = 0;
		errorMessage = '';
	}
	// ***********************************
	// スケジュール処理開始
	// ***********************************
	public void execute(SchedulableContext SC) {
   	  // スケジュール定義情報を取得して、スケジュール定義者へバッチ処理結果を送信する
   	  CronTrigger cron = [Select CreatedById From CronTrigger Where Id = :SC.getTriggerId() ];
      TR1wayDataFixBatch batch = new TR1wayDataFixBatch(cron.CreatedById);
      DataBase.executeBatch(batch, 1);
	}
	// ***********************************
	// バッチ処理開始
	// ***********************************
	public Database.QueryLocator start(Database.BatchableContext BC){
		//String Key = 'TR';
		Date VARTODAY = Date.today();
		set<string> eventSourceSet = new set<string>{'FromNeppan','Neppan'};
    	return Database.getQueryLocator(Query);
	}

	/**
	* 情報集計
	**/
	public void execute(Database.BatchableContext BC, List<LeadIndex__c> scope){
		// 2018/03/07 Security Check BEGIN
	    List<String> chkFields = new List<String>{'OrgID__c','ID__c'};
	    Map<String,Schema.SObjectField> m = Schema.SObjectType.LeadIndex__c.fields.getMap();
	    if (!CommSecurityUtils.isCanUpdateable(chkFields, m)) {
			return;
	    }
	    // 2018/03/07 Security Check END
//		system.debug(loggingLevel.INfo, 'scope[0]=' + scope[0]);
   		String dataID;
		String salesOfficeCompanyCode;
		String travelAgencyBookingNumber;
		
		LeadIndex__c leadIndex = scope[0];
		//if (leadIndex.ID__c.length() != 20) return;
		list<attachment> attList = [select id, name, body from attachment  where parentId = :leadIndex.Id order by createddate asc limit 1];
        if (attList.isEmpty()) return;
        attachment attdata  = attList[0];
		// 既存のXML情報を取得する
		String body = attdata.body.tostring();
		Dom.Document doc = new Dom.Document();
		if (Test.isRunningTest()) doc.load(testLoadXmlMsg);
		else doc.load(body);
		//
		Integer countNum = 0;
		// DATA/BOOKINGID 
		Dom.XMLNode allotmentBookingReportNode = doc.getRootElement();		  	 		
		if(allotmentBookingReportNode != null){
			for(Dom.XMLNode childNode : allotmentBookingReportNode.getChildElements()){
				if(childNode.getName().equalsIgnoreCase('TransactionType')){						   	 
					Dom.XMLNode transactionTypeNode = childNode;
					if(transactionTypeNode != null){
				    	dataID = CommUtils.nullToBlank(getChildElementByName(transactionTypeNode,'DataID'));
				    	countNum++;
				    }
				}
				if(childNode.getName().equalsIgnoreCase('SalesOfficeInformation')){
					Dom.XMLNode salesOfficeNode = childNode;
					if(salesOfficeNode != null){
						salesOfficeCompanyCode = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'SalesOfficeCompanyCode'));
						countNum++;
					}
				}	
				if(childNode.getName().equalsIgnoreCase('BasicInformation')){
					Dom.XMLNode basicNode = childNode;
					if(basicNode != null){
						travelAgencyBookingNumber = CommUtils.nullToBlank(getChildElementByName(basicNode,'TravelAgencyBookingNumber'));						
						countNum++;
					}	    	
				}
				if (countNum == 3) break;
			}				
		}
		// 情報入り替えする
		String bookingNumberID = CommUtils.nullToBlank(salesOfficeCompanyCode) + '_' + CommUtils.nullToBlank(travelAgencyBookingNumber);
		String orgDataId  =CommUtils.nullToBlank(leadIndex.ID__c);
		if(DataID == orgDataId && bookingNumberID != orgDataId){ 
			leadIndex.OrgID__c = leadIndex.ID__c;
			leadIndex.ID__c = bookingNumberID;
			errorMessage += ' \n予約インデックス['+leadIndex.Name+']: ' + dataID + ' → ' + bookingNumberID + ' ;';
			IsOKCounts++;
			update leadIndex;
		}
	}
	private static string getChildElementByName(Dom.XMLNode parentNode,String elementName){
		if (parentNode == null) return null;
		Dom.XMLNode childrenNode = parentNode.getChildElement(elementName, null);
		return getChildElementValue(childrenNode);
	}
	private static String getChildElementValue(Dom.XMLNode childNode) {
		if (childNode == null) return null;
		return CommUtils.nullToBlank(childNode.getText());
	} 
	/**
	* 処理終了
	**/
	
	public void finish(Database.BatchableContext BC){
		//　スケジュール定義者のメールで送付する
//		system.debug(loggingLevel.INfo, '==処理終了==' );
		User setupUser = [select email from User where id = :scheduleCreatedById order by createddate asc limit 1];
//		system.debug(loggingLevel.INfo, '==setupUser==' + setupUser);
		String mailAdds = setupUser.email;
		if (CommUtils.isBlank(mailAdds)) return;
		// メール情報を設定する
		String mailBodyStr = '処理結果詳細	BEGIN';
		mailBodyStr += '\n更新成功件数：' + IsOKCounts + '(件)';
		if (IsOKCounts > 0) {
		mailBodyStr += '\n更新対象履歴：' + errorMessage;
		}
		mailBodyStr += '\n処理結果詳細	END';
//		system.debug(loggingLevel.INfo, '==errorMessage[0]==' + errorMessage);
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = new String[]{mailAdds};
		mail.setToAddresses(toAddresses);
		mail.setSubject('[Tr1wayDataFixBatch] バッチ処理結果の通知');
		mail.setPlainTextBody(mailBodyStr);
		// テストクラスの場合、実施しない
		if(!Test.isRunningTest())
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	}
}