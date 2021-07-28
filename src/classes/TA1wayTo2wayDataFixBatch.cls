public with sharing class TA1wayTo2wayDataFixBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
	public String dataID;
	public String bookingInfo;
 	// TODO：未来日　かつ　キャンセルされる対象外  AND id=\'a0kp00000015XUL\'
 	private static final String Query = ' Select Id,Name,Id__c from LeadIndex__c where ParentLeadIndxRef__c = null And ID__c != null  And OrgId__c = null And EventSource__c =  \'FromTravelAgency\' And (APPNAME__c = null or APPNAME__c = :Key) And EntryDate__c >= :VARTODAY ';
	// 処理成功件数と失敗件数統計する
	private Integer IsOKCounts;
	private String errorMessage;
	// スケジュール定義者
	private Id scheduleCreatedById;
	// テスト用XML情報格納用
	@TestVisible private String testLoadXmlMsg;
	public Ta1wayTo2wayDataFixBatch () {}
	// バッチ起動インスタンス関数
	public Ta1wayTo2wayDataFixBatch (Id userId) {
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
      Ta1wayTo2wayDataFixBatch batch = new Ta1wayTo2wayDataFixBatch(cron.CreatedById);
      DataBase.executeBatch(batch, 1);
	}
	// ***********************************
	// バッチ処理開始
	// ***********************************
	public Database.QueryLocator start(Database.BatchableContext BC){
		String Key = TA_ServiceCtrl.SERVICE_KEY;
		Date VARTODAY = Date.today();
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
		LeadIndex__c leadIndex = scope[0];
		//if (leadIndex.ID__c.length() != 20) return;
		list<attachment> attList = [select id, name, body from attachment  where parentId = :leadIndex.Id order by createddate asc limit 1];
        if (attList.isEmpty()) return;
        attachment attdata  = attList[0];
//      system.debug(loggingLevel.INfo, 'attdata=' + attdata);
//      system.debug(loggingLevel.INfo, 'attdata.body=' + attdata.body);
        Boolean isSjisflg = false;
        try {
        	String utf8Checker = attdata.body.tostring();
//        	system.debug(loggingLevel.INfo, 'utf8Checker=' + utf8Checker);
        } catch(StringException e) {
        	string errorMsg = e.getMessage();
        	if (errorMsg.contains('BLOB is not a valid UTF-8 string')) isSjisflg = true;
        }
        // テストの場合、直接フラグを設定する
        if (Test.isRunningTest()) isSjisflg = true;
        if (!isSjisflg) return;
        
        String hex = EncodingUtil.convertToHex(attdata.body);
        String result = '%';
        Integer hexSize = 300000;
        Integer qu = hex.length() / hexSize;
        Integer i = 0;
        while(true) {
            if(i >= qu) {
                if(i == qu) {
                    result += hex.substring(i*hexSize).replaceAll('[[0-9][a-fA-F]]{2}', '$0%');
                    result = result.substring(0, result.length()-1);
                }
                break ;
            } else {
                result += hex.substring(i*hexSize, (i+1)*hexSize).replaceAll('[[0-9][a-fA-F]]{2}', '$0%');
            }
            i++;
        }
        String body = EncodingUtil.urlDecode(result, 'Windows-31J');
//		system.debug(loggingLevel.INfo, 'body=' + body);
		Dom.Document doc = new Dom.Document();
		if (Test.isRunningTest()) doc.load(testLoadXmlMsg);
		else doc.load(body);
		//Dom.XmlNode root = doc.getRootElement();
		// DATA/BOOKINGID 
		Dom.XMLNode allotmentBookingReportNode = doc.getRootElement();		  	 		
		if(allotmentBookingReportNode != null){   
			for(Dom.XMLNode childNode : allotmentBookingReportNode.getChildElements()){
				if(childNode.getName().equalsIgnoreCase('TransactionType')){						   	 
					Dom.XMLNode transactionTypeNode = childNode;
					if(transactionTypeNode != null){
				    	dataID = CommUtils.nullToBlank(getChildElementByName(transactionTypeNode,'DataID'));
				    	bookingInfo = CommUtils.nullToBlank(getChildElementByName(transactionTypeNode,'BookingDataID'));
				    }
				    break;
				}
			}				
		}
		// CommUtils.isBlank()
//		system.debug(loggingLevel.INfo, 'dataID=' + dataID);
//		system.debug(loggingLevel.INfo, 'bookingInfo=' + bookingInfo);
		if(!CommUtils.isBlank(dataID) && !CommUtils.isBlank(bookingInfo) ){
			if(bookingInfo.length() > 0){
				//String bookingInfoID = bookingInfo.split('-')[0];
				List<String> bookingDataIds = bookingInfo.split('-');
				if (bookingDataIds.isEmpty()) return;
				String bookingInfoID = bookingDataIds[0];
				if(DataID == leadIndex.ID__c && bookingInfoID != leadIndex.ID__c){ 
					leadIndex.OrgID__c = leadIndex.ID__c;
	    			leadIndex.ID__c = bookingInfoID;
//	    			system.debug(loggingLevel.INfo, 'bookingInfoID=' + bookingInfoID);
	    			errorMessage += ' \n予約インデックス['+leadIndex.Name+']: ' + dataID + ' → ' + bookingInfoID + ' ;';
	    			IsOKCounts++;
	    			update leadIndex;
				}
			}	
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
		mail.setSubject('[Ta1wayTo2wayDataFixBatch] バッチ処理結果の通知');
		mail.setPlainTextBody(mailBodyStr);
		// テストクラスの場合、実施しない
		if(!Test.isRunningTest())
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	}   
}