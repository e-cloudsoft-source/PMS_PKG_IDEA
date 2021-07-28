/**
* 予約情報取得完了 - レスポンス
* 予約情報取得完了応答
**/
public with sharing class TA_OutputCompleteInfoItem {
	public TA_OutputCompleteInfoItem(){}
    public TA_OutputCompleteInfoItem(String strXmlBody) {
		if (strXmlBody.indexOfIgnoreCase('BookingReportCompleteResult') < 0 && strXmlBody.indexOfIgnoreCase('<Error>') < 0) {
			commonResponse = new CompleteResult(CommUtils.nullToBlank(strXmlBody).stripHtmlTags());
			return;
		}
		Dom.Document doc = new Dom.Document();
		doc.load(strXmlBody);
		Dom.XmlNode root = doc.getRootElement();
		String rootNodeName = root.getName();
		if (rootNodeName == 'Error')  commonResponse = new CompleteResult(CommUtils.nullToBlank(new TA_ResultInfoItem(root)));// 失敗設定する
		
		for (Dom.XMLNode node : root.getChildElements()) {
			// タグ名
			String nodeName = node.getName();
			if (nodeName == 'CompleteResult') {
				commonResponse = new CompleteResult(node);
			} else if (nodeName == 'TransactionInType') {
				for (Dom.XMLNode roomNode : node.getChildElements()) {
					transactionInType = new TransactionInType(roomNode);
				}
			}
		}
    }
    public TransactionInType transactionInType{get; private set;}
    public CompleteResult commonResponse{get; set;}
	
	public class TransactionInType {
		public TransactionInType(Dom.XMLNode transactionInTypeNode) {
   			Dom.XMLNode dataFromField =transactionInTypeNode.getChildElement('DataFrom', null);  			
			Dom.XMLNode dataClassificationField = transactionInTypeNode.getChildElement('DataClassification', null);	
			Dom.XMLNode dataIDField = transactionInTypeNode.getChildElement('DataID', null);	
			Dom.XMLNode systemDateField = transactionInTypeNode.getChildElement('SystemDate', null);	
			Dom.XMLNode systemTimeField = transactionInTypeNode.getChildElement('SystemTime', null);	
			if (dataFromField != null) dataFrom = CommUtils.nullToBlank(dataFromField.getText());
			if (dataClassificationField != null) dataFrom = CommUtils.nullToBlank(dataClassificationField.getText());
			if (dataIDField != null) dataID = CommUtils.nullToBlank(dataIDField.getText());
			if (systemDateField != null) systemDate = CommUtils.stringToDate(systemDateField.getText());
			if (systemTimeField != null) systemTime = CommUtils.stringToTime(systemTimeField.getText());
		}
		public string dataFrom{get;set;}
		public string dataClassification{get;set;}
		public string dataID{get;set;}
		public Date systemDate{get;set;}
		public Time systemTime{get;set;}
	}
	public class CompleteResult {
		public CompleteResult(String pStatus){ status = pStatus;}
		public CompleteResult(Dom.XMLNode completeResultNode) {
			Dom.XMLNode statusField = completeResultNode.getChildElement('Status', null);	
			if (statusField != null) status = CommUtils.nullToBlank(statusField.getText());
		}
		public String status{get;set;}
		public Boolean isSuccess{get{ return status == '1';}}
	}
}