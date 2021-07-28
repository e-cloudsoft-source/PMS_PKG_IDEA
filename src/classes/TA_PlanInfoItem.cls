public with sharing class TA_PlanInfoItem {

	public TA_PlanInfoItem(string strXmlBody) {
    	
    	planList = new list<PlanInfo>();
		if (strXmlBody.indexOfIgnoreCase('GetPlanListRS') < 0 && strXmlBody.indexOfIgnoreCase('<Error>') < 0) {
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
			String nodeName = node.getName();
			if(nodeName == 'Result'){
				commonResponse = new TA_ResultInfoItem(node);
			}else if (nodeName == 'PlanList') {
				for (Dom.XMLNode planNode : node.getChildElements()) {
					PlanInfo planInf = new PlanInfo(planNode);
					planList.add(planInf);
				}
			}
		}
    }
	
	public TA_ResultInfoItem commonResponse{get; private set;}  	  
	public list<PlanInfo> planList{get; private set;}
	
	
	public class PlanInfo {
		public PlanInfo(Dom.XMLNode otaNode){
			Dom.XMLNode planNameField = otaNode.getChildElement('PlanName', null);
			Dom.XMLNode planTypeCodeField = otaNode.getChildElement('PlanTypeCode', null);
			if(planNameField != null) planName = CommUtils.nullToBlank(planNameField.getText());
			if(planTypeCodeField != null) planCode = CommUtils.nullToBlank(planTypeCodeField.getText());
		}
		public string planName{get;set;}
		public string planCode{get;set;}
	}

}