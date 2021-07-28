public with sharing class TA_RoomTypeInfoItem {
    
    public TA_RoomTypeInfoItem(String strXmlBody) {
    	
    	roomList = new list<RoomInfo>();
		if (strXmlBody.indexOfIgnoreCase('GetRoomListRS') < 0 && strXmlBody.indexOfIgnoreCase('<Error>') < 0) {
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
			} else if (nodeName == 'RoomList') {
				for (Dom.XMLNode roomNode : node.getChildElements()) {
					RoomInfo roomInf = new RoomInfo(roomNode);
					roomList.add(roomInf);
				}
			}
		}
    }
    // 共通戻る結果
    public TA_ResultInfoItem commonResponse{get; private set;}
    // 部屋タイプ定義
    public list<RoomInfo> roomList{get; private set;}
    
	public class RoomInfo {
   		public RoomInfo(Dom.XMLNode roomNode) {
			Dom.XMLNode roomNameField = roomNode.getChildElement('RoomName', null);
			Dom.XMLNode roomTypeCodeField = roomNode.getChildElement('RoomTypeCode', null);
			if (roomNameField != null) roomName = CommUtils.nullToBlank(roomNameField.getText());
			if (roomTypeCodeField != null) roomTypeCode= CommUtils.nullToBlank(roomTypeCodeField.getText());
   		}
		public string roomName{get;set;}
		public String roomTypeCode{get;set;}
   	
	} 
	
}