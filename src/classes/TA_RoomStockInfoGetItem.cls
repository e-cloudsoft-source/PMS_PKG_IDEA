public with sharing class TA_RoomStockInfoGetItem {
    public TA_RoomStockInfoGetItem(String strXmlBody) {

    	roomStockList = new list<RoomStockInfo>();	
		if (strXmlBody.indexOfIgnoreCase('GetRoomStockRS') < 0 && strXmlBody.indexOfIgnoreCase('<Error>') < 0) {
			commonResponse = new TA_ResultInfoItem();
			commonResponse.setFail(strXmlBody);
			return;
		}

		Dom.Document doc = new Dom.Document();
		doc.load(strXmlBody);
		Dom.XmlNode root = doc.getRootElement();
		String rootNodeName = root.getName();
		if (rootNodeName == 'Error')  commonResponse = new TA_ResultInfoItem(root);
		
		for (Dom.XMLNode node : root.getChildElements()) {
			// タグ名
			String nodeName = node.getName();
			if (nodeName == 'Result') {
				commonResponse = new TA_ResultInfoItem(node);
			} else if (nodeName == 'RoomStockList') {
				for (Dom.XMLNode roomNode : node.getChildElements()) {
					RoomStockInfo roomStockInf = new RoomStockInfo(roomNode);
					roomStockList.add(roomStockInf);
				}
			}
		}
    }
    // 共通戻る結果
    public TA_ResultInfoItem commonResponse{get;private set;}
    // 部屋タイプ定義
    public list<RoomStockInfo> roomStockList{get;private set;}
    
	public class RoomStockInfo {
		public RoomStockInfo(){}
   		public RoomStockInfo(Dom.XMLNode roomNode) {
   			Dom.XMLNode roomTypeCodeField =roomNode.getChildElement('RoomTypeCode', null);  			
			Dom.XMLNode stockDateField = roomNode.getChildElement('Date', null);			
			Dom.XMLNode roomStockNumField = roomNode.getChildElement('RoomStockNum', null);			
			Dom.XMLNode salesClosedFiled =roomNode.getChildElement('SalesClosed', null);			
			Dom.XMLNode errorCodeFiled =roomNode.getChildElement('ErrorCode', null);			
			Dom.XMLNode errorMessageFiled =roomNode.getChildElement('ErrorMessage', null);
			if (RoomTypeCodeField != null) roomTypeCode = CommUtils.nullToBlank(RoomTypeCodeField.getText());
			if (stockDateField != null) stockDate = CommUtils.nullToBlank(stockDateField.getText());
			if (roomStockNumField != null) remainingCount = CommUtils.nullToBlank(roomStockNumField.getText());
			if (salesClosedFiled != null) salesClosed = CommUtils.nullToBlank(salesClosedFiled.getText());
			if (errorCodeFiled != null) errorCode = CommUtils.nullToBlank(errorCodeFiled.getText());
			if (errorMessageFiled != null) errorMessage = CommUtils.nullToBlank(errorMessageFiled.getText());
			//roomTypeCode= CommUtils.nullToBlank(roomTypeCodeField.getText());
			//stockDate= CommUtils.nullToBlank(stockDateField.getText());
			//roomStockNum= CommUtils.nullToBlank(roomStockNumField.getText());
			//salesClosed= CommUtils.nullToBlank(salesClosedFiled.getText());
			//errorCode= CommUtils.nullToBlank(errorCodeFiled.getText());
			//errorMessage= CommUtils.nullToBlank(errorMessageFiled.getText());
   		}
		public String roomTypeCode{get;set;}
   	    public String stockDate{get;set;}
   	    public String remainingCount{get;set;}
   	    public String salesClosed{get;set;}
   	    public String errorCode{get;set;}
   	    public String errorMessage{get;set;}
	} 
	
}