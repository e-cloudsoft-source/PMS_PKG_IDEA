public with sharing class TA_RoomStockInfoUpdItem {
    public TA_RoomStockInfoUpdItem(String strXmlBody) {
    	errorRoomList = new list<RoomInfo>();	
		if (strXmlBody.indexOfIgnoreCase('UpdateRoomStockRS') < 0 && strXmlBody.indexOfIgnoreCase('<Error>') < 0) {
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
//System.debug(logginglevel.INFO, node);
			// タグ名
			 String nodeName = node.getName();
			if (nodeName == 'Result') {
				commonResponse = new TA_ResultInfoItem(node);
			} else if (nodeName == 'ErrorRoomList') {
				for (Dom.XMLNode roomNode : node.getChildElements()) {
					RoomInfo roomInf = new RoomInfo(roomNode);
//System.debug(logginglevel.INFO, 'roomInf:'+roomInf);
					errorRoomList.add(roomInf);
				}
			}
		}
    }
    // 共通戻る結果
	public TA_ResultInfoItem commonResponse{get; private set;}
    // 部屋タイプ定義
    public list<RoomInfo> errorRoomList{get; private set;}
    
	public class RoomInfo {
		public RoomInfo() {}
   		public RoomInfo(Dom.XMLNode roomNode) {
   			Dom.XMLNode roomTypeCodeField =roomNode.getChildElement('RoomTypeCode', null);
			Dom.XMLNode stockDateField = roomNode.getChildElement('Date', null);
			Dom.XMLNode errorCodeFiled =roomNode.getChildElement('ErrorCode', null);
			Dom.XMLNode errorMessageFiled =roomNode.getChildElement('ErrorMessage', null);
			if (roomTypeCodeField != null) roomTypeCode = CommUtils.nullToBlank(roomTypeCodeField.getText());
			if (stockDateField != null) stockDate = CommUtils.nullToBlank(stockDateField.getText());
			if (errorCodeFiled != null) errorCode = CommUtils.nullToBlank(errorCodeFiled.getText());
			if (errorMessageFiled != null) errorMessage = CommUtils.nullToBlank(errorMessageFiled.getText());
			//roomTypeCode= CommUtils.nullToBlank(roomTypeCodeField.getText());
			//stockDate= CommUtils.nullToBlank(stockDateField.getText());
			//errorCode= CommUtils.nullToBlank(errorCodeFiled.getText());
			//errorMessage= CommUtils.nullToBlank(errorMessageFiled.getText());
   		}
		public String roomTypeCode{get;set;}
   	    public String stockDate{get;set;}
   	    public String errorCode{get;set;}
   	    public String errorMessage{get;set;}
	} 

	// 在庫情報を格納する
	public class RoomStockInfo {
		public String roomTypeCode{get;set;}
		public String stockDate{get;set;}
		public String roomStockNum{get;set;}
		public String salesClosed{get;set;}
		public String errorCode{get;set;}
		public String errorMessage{get;set;}
		public String isForce{get;set;}	// 強制更新設定
	}
}