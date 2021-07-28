/**
* 指定WebSiteからお知らせ情報とイメージを取得機能対応
**/	
public without sharing class BatchGetWebSiteInfo implements Schedulable { 

    public BatchGetWebSiteInfo () {
		// Futureで最新情報を取得する
    	//getNewsMessage(retryCnt, errMsg);
    }
    public BatchGetWebSiteInfo(Integer pRetryCnt, String pErrMsg) {
    	retryCnt = pRetryCnt;
    	errMsg = pErrMsg;
    }
    // 最大タイムアウト時間を定義する
    private static final integer COMMONCALL_TIME_OUT_VALUE = 120000;
    // 
    private Integer retryCnt = 1;
    private String errMsg = '';
    //@TestVisible public static String WorkFileMsgForCampaing = 'WorkFileMsgForCampaing';
    //@TestVisible public static String WorkFileImgForCampaign = 'WorkFileImgForCampaign';
    @TestVisible private static Integer MaxRetryNum = 5;
    // スケジュール起動
    public void execute(SchedulableContext SC) {
    	if (retryCnt > MaxRetryNum) {
    		// Add Error Message To MessageWindow
    		sendErrorMail(SC.getTriggerId(), errMsg);
  			return;
    	} else {
    		BatchGetWebSiteInfo.getNewsMessage(retryCnt, errMsg);
    	}
    }
    
    //  指定WebSiteからお知らせ情報とイメージを取得機能対応
    @future(callout=true)    
    public static void getNewsMessage(Integer retryCnt, String errMsg ) {
		// XML定義情報を取得する　
    	loadXml();
try {
		// 2017/04/13 Field Security Check BEGIN by wx
		List<String> insChkFields = new List<String>{'Body','ContentType','FolderId','DeveloperName','Name'}; 
		Map<String,Schema.SObjectField> insm = Schema.SObjectType.Document.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(insChkFields, insm)) {
			return;
		}
		if (!CommSecurityUtils.isCanUpdateable(insChkFields, insm)) {
			return;
		}
		//System.debug(logginglevel.info,'Field Security Check:::[44-53]:::>>Pass');
		// 2017/04/13 Field Security Check End by wx
		// SITE URLを未設定する場合　
		if (CommUtils.isBlank(inf.sitePageUrl)) return;
    	// 定義情報により、HTMLの関連情報を取得する
        Http http = new Http();
        HttpRequest reqs = new HttpRequest();   
        reqs.setEndpoint(inf.sitePageUrl);
        reqs.setMethod('GET');
        reqs.setTimeout(COMMONCALL_TIME_OUT_VALUE);
        reqs.setCompressed(true);
        HttpResponse res = http.send(reqs);
        String htmlBodyStr = res.getBody();
		if (Commutils.isBlank(htmlBodyStr)) return;
        // Html Message Body
        SectionInfo msgBlock = inf.msgBlock;
        SectionInfo imgBlock = inf.imgBlock;
        //最新お知らせメッセージを取得
        String orgMsgHtml = '';
        if (msgBlock != null) orgMsgHtml = htmlBodyStr.substringBetween(msgBlock.begKey,msgBlock.endKey);
        // 画像情報を取得のHTML分
        String orgImgHtml = '';
        if (imgBlock != null) orgImgHtml = htmlBodyStr.substringBetween(imgBlock.begKey,imgBlock.endKey);
        // 両方とも定義のHTML情報を取得できない場合
		if (CommUtils.isBlank(orgMsgHtml) && CommUtils.isBlank(orgImgHtml)) {
			return;
		}
		// 最新お知らせ情報を取得する
		String msgResult = '';
		if (msgBlock != null) msgResult = getParseMsg(msgBlock.joinFilter, orgMsgHtml);
		// Imeage Url取得
		String imageUrl = '';
		if (imgBlock != null) imageUrl = getParseMsg(imgBlock.joinFilter, orgImgHtml);
		Blob imageBody = null;
		if (!CommUtils.isBlank(imageUrl)) {
	        HttpRequest req = new HttpRequest();
	        req.setEndpoint(imageUrl);
	        req.setTimeout(COMMONCALL_TIME_OUT_VALUE);
	        req.setMethod('POST');
	        req.setHeader('ContentType', 'image/jpeg'); 
	        req.setCompressed(true); 
	        HttpResponse re = http.send(req);
	        imageBody = re.getBodyAsBlob();
		}
		if (CommUtils.isBlank(msgResult) && imageBody == null) return;
        // 最新お知らせ情報を格納フォルダを取得する
        String folderName = 'WorkFiles';
        List<Folder> folders = [select id from Folder Where DeveloperName = :folderName];
        if (folders.isEmpty()) {
        	throw new CommException('folder '+folderName+' not found.');
        }
        Id folderId = folders[0].Id;
        if (!CommUtils.isBlank(msgResult)) {
        	String msgDocDeveloperNm = msgBlock.fileName;
        	List<Document> messageDoc = [select id from Document where DeveloperName = :msgDocDeveloperNm for update];
        	Document msgDoc = null;
        	String contentType = CommUtils.isBlank(msgBlock.contentType) ? 'text/plain' : msgBlock.contentType;
        	if (messageDoc.isEmpty()) {
				msgDoc = new Document();
				msgDoc.Name = 'キャンペーンメッセージ';
				msgDoc.DeveloperName = msgDocDeveloperNm;
				msgDoc.FolderId = folderId;
				msgDoc.Body = Blob.valueOf(msgResult);
				msgDoc.ContentType =  contentType;
				insert msgDoc;
        	} else {
        		msgDoc = messageDoc[0];
        		msgDoc.Body = Blob.valueOf(msgResult);
        		msgDoc.ContentType =  contentType;
        		update msgDoc;
        	}
        	
        }
        if (imageBody != null) {
        	String imgDocDeveloperNm = imgBlock.fileName;
        	List<Document> imgDocs = [select id from Document where DeveloperName = :imgDocDeveloperNm ];
			Document imgDoc = null;
			String contentType = CommUtils.isBlank(imgBlock.contentType) ? 'image/jpeg' : imgBlock.contentType;
			if (imgDocs.isEmpty()) {
				imgDoc = new Document();
		    	imgDoc.Name = 'キャンペーン写真';
		    	imgDoc.DeveloperName = imgDocDeveloperNm;
		    	imgDoc.FolderId = folderId;
		    	imgDoc.ContentType =  contentType;
		    	imgDoc.Body = imageBody;
				insert imgDoc;
        	} else {
        		imgDoc = imgDocs[0];
        		imgDoc.Body = imageBody;
        		imgDoc.ContentType =  contentType;
        		update imgDoc;
        	}
        }
} catch (CalloutException e) {
    retryCnt++;
    //ID jobID = System.enqueueJob(new BatchGetWebSiteInfo(retryCnt, e.getMessage()));
    // ５分後再度取得をRETRY
	BatchGetWebSiteInfo schedule= new BatchGetWebSiteInfo(retryCnt,e.getMessage());
	DateTime nowTime = DateTime.now().addSeconds(300);
	// 起動ＣＲＯＮを設定する
	String timeStr = nowTime.format('yyyyMMddHHmmss');
	String yy = timeStr.substring(0,4);
	String mm = timeStr.substring(4,6);
	String dd = timeStr.substring(6,8);
	String hh = timeStr.substring(8,10);
	String ms = timeStr.substring(10,12);
	String ss = timeStr.substring(12,14);
	String sch = ss + ' ' +
	       ms + ' ' +
	       hh + ' ' +
	       dd + ' ' +
	       mm + ' ' +
	       ' ? ' + yy;
	String jobName = 'BatchGetWebSiteInfoBatch_' + DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
	String jobId = system.schedule(jobName, sch, schedule);
}
   
    }
	/**
	* メール送信機能対応:
	**/
    private void sendErrorMail(Id jobId, String errMsg) {
    	if (CommUtils.isBlank(errMsg)) return;
	  	// スケジュール定義情報を取得して、スケジュール定義者へバッチ処理結果を送信する
	  	CronTrigger cron = [Select CreatedById From CronTrigger Where Id = :jobId ];
  		Id scheduleCreatedById = cron.CreatedById;
		//　スケジュール定義者のメールで送付する
		User setupUser = [select email from User where id = :scheduleCreatedById];
		String mailAdds = setupUser.email;
	
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = new String[]{mailAdds};
		mail.setToAddresses(toAddresses);
		//為替レート取得結果の通知
		//(エラー)
		mail.setSubject('['+UserInfo.getOrganizationName()+']最新お知らせ情報取得');
		// パラメータ設定不正のメール送信
		//為替レート取得バッチ起動時間（HH）パラメータ設定不正、０〜２３間数値定義してください。
		String mailBodyStr = 'エラーが発生しました('+errMsg+')';
		mail.setPlainTextBody(mailBodyStr);
		// テストクラスの場合、実施しない
		if(!Test.isRunningTest())
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    // 2017/03/06 添加Schedulable begin by wx
    //private String getParseMsg(list<Filter> pFilters,String orgMessage) {
    private static String getParseMsg(list<Filter> pFilters,String orgMessage) {
    // 2017/03/06 添加Schedulable end by wx	
    	String msgResult = '';
    	
        for (Filter filterInf : pFilters) {
        	String wkMessage = orgMessage;
        	// BEGのキーからメッセージを分割する　
        	for (String begKey : filterInf.begKeys) {
        		wkMessage = CommUtils.nullToBlank(wkMessage).substringAfter(begKey);
        	}
			// ENDのキーからメッセージを分割する　
        	for (String endKey : filterInf.endKeys) {
        		wkMessage = CommUtils.nullToBlank(wkMessage).substringBefore(endKey);
        	}
        	// HTML STRIPにより、メッセージ再設定する
        	if (filterInf.htmlStrip) wkMessage = wkMessage.stripHtmlTags();
        	if (!CommUtils.isBlank(wkMessage)) msgResult += wkMessage + '\n'; 
        	
        	System.debug(loggingLevel.info, 'wkMessage='+wkMessage);
        	System.debug(loggingLevel.info, 'msgResult='+msgResult);
        }
        return msgResult;
    }
    public static ParseInfo getParseInfo() {
    	ParseInfo resInf = new ParseInfo();
     	// XML LOADする
		String xmlname= 'BatchGetWebSiteInfoConfig';
		List<Document> sr = [select body, name from Document where DeveloperName = :xmlname];
		Blob xmlBody = sr[0].Body;
		String strXmlBody = xmlBody.toString();
		Dom.Document doc = new Dom.Document();
		doc.load(strXmlBody);
		Dom.XMLNode rootNode = doc.getRootElement();
		Dom.XmlNode CampaignField = rootNode.getChildElement('Campaign', null);
        if(CampaignField != null){
			Dom.XmlNode AutoGetInfoField = CampaignField.getChildElement('AutoGetInfo', null);
			if(AutoGetInfoField != null){
				Dom.XmlNode WebSiteUrlField = AutoGetInfoField.getChildElement('WebSiteUrl',null);
                Dom.XmlNode MessageField = AutoGetInfoField.getChildElement('MessageBlock',null);
                Dom.XmlNode ImageField = AutoGetInfoField.getChildElement('ImageBlock',null);
                if (WebSiteUrlField != null) resInf.sitePageUrl = CommUtils.nullToBlank(WebSiteUrlField.getText());
                if (MessageField != null) {
                	// 
                	resInf.msgBlock = new SectionInfo(MessageField);
                	if (CommUtils.isBlank(resInf.msgBlock.fileName)) resInf.msgBlock.fileName = 'WorkFileMsgForCampaing';
                }
                if (ImageField != null) {
                	//
                	resInf.imgBlock = new SectionInfo(ImageField);
                	if (CommUtils.isBlank(resInf.imgBlock.fileName)) resInf.imgBlock.fileName = 'WorkFileImgForCampaign';
                }
			}  
		}
		return resInf;
    }
	// LoadXml
    private static void loadXml() {
    	inf = getParseInfo();
    }
    
    public static ParseInfo inf;
    public class ParseInfo {
    	public String sitePageUrl{get;set;}
    	public SectionInfo msgBlock{get;set;}
    	public SectionInfo imgBlock{get;set;}
    }
    public class SectionInfo {
    	public SectionInfo(Dom.XMLNode root) {
    		joinFilter = new list<Filter>();
    		begKey = endKey = contentType = '';
    		// XML PARSE
    		if (root == null) return;
			for ( Dom.xmlNode node : root.getChildElements()){
				String nodeName = node.getName();
				if (nodeName == 'HTML_BEG') {
					begKey = CommUtils.nullToBlank(node.getText());
				} else if (nodeName == 'HTML_END') {
					endKey = CommUtils.nullToBlank(node.getText());
				} else if (nodeName == 'FILTER') {
					joinFilter.add(new Filter(node));	
				} else if (nodeName == 'CONTENT_TYPE') {
					contentType = CommUtils.nullToBlank(node.getText());
				} else if (nodeName == 'FILE_NAME') {
					fileName = CommUtils.nullToBlank(node.getText());
				}
			}

    	}
    	public String begKey{get;set;}
    	public String endKey{get;set;}
    	public List<Filter> joinFilter{get;set;}
    	public String contentType{get;set;}
    	public String fileName{get;set;}
    }
    public class Filter {
    	public Filter(Dom.XMLNode root) {
    		htmlStrip = true;
    		begKeys = new list<string>();
    		endKeys = new list<string>();
    		for ( Dom.xmlNode node : root.getChildElements()){
	    		String nodeName = node.getName();
	    		String val = CommUtils.nullToBlank(node.getText());
	    		if (CommUtils.isBlank(val)) continue;
	    		if (nodeName == 'HTML_BEG') {
	    			begKeys.add(val);
	    		} else if (nodeName == 'HTML_END') {
	    			endKeys.add(val);
	    		} else if (nodeName == 'HTML_STRIP') {
	    			htmlStrip = Boolean.valueOf(val);	
	    		}
    		}
    	}
    	public List<String> begKeys{get;set;}
    	public List<String> endKeys{get;set;}
    	public boolean htmlStrip{get;set;}
    }
}