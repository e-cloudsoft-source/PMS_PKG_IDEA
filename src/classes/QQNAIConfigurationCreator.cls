public without sharing class QQNAIConfigurationCreator {
    private Dom.Document objDomDoc;
    private List<Document> lstDocument;
    private Map<string, string> properties;
    // 2018/12/30 部屋自動割当機能AI対応 by zy BEGIN
    public String sqlWhere;
    // 2018/12/30 部屋自動割当機能AI対応 by zy END
    public QQNAIConfigurationCreator() {
    	properties = new Map<string, string>();
    	// 2018/12/30 部屋自動割当機能AI対応 by zy BEGIN
    	sqlWhere = '';
    	// 2018/12/30 部屋自動割当機能AI対応 by zy END
    }
    
    public void load() {
        lstDocument = [select Id , body from document where Name='AI Configuration'];
        
        system.debug('>>>>>>>>>lstDocument'+lstDocument);
        if(lstDocument.size() > 0 && lstDocument[0].body !=null){
			objDomDoc = new Dom.Document();
			objDomDoc.load(lstDocument[0].body.tostring());
           
			Dom.XMLNode objRootElement = objDomDoc.getRootElement();
	        Dom.XMLNode propertiesNode = objRootElement.getChildElement('Properties', null);
	        
	        for(Dom.XMLNode propertyNode : propertiesNode.getChildElements()) {
	        	if(propertyNode.getName() == 'Property') {
	        		string key = propertyNode.getAttribute('key', null);
	        		string value = propertyNode.getAttribute('value', null);
	        		properties.put(key, value);
	        	}
	        }
	        // 2018/12/30 部屋自動割当機能AI対応 by zy BEGIN
	        // 指定予約SQL文
	        Dom.XMLNode leadNode = objRootElement.getChildElement('LeadQuery', null);
	        if (leadNode != null) {
	        	Dom.XMLNode whereNode = leadNode.getChildElement('SQLWHERE',null);
	        	if (whereNode != null) sqlWhere = CommUtils.nullToBlank(whereNode.getText());
	        }
			// 2018/12/30 部屋自動割当機能AI対応 by zy END
        }
    }
    
    public boolean isNew(){
        if(objDomDoc != null){
           Dom.XMLNode objRootElement = objDomDoc.getRootElement();
           system.debug('>>>>>Count'+objRootElement.getChildElement('TruncatedDQN', null).getName());
           // 2018/12/30 部屋自動割当機能AI対応 by zy BEGIN
           /*
            if(objRootElement.getChildElement('TruncatedDQN', null).getName() == 'TruncatedDQN' && 
              (objRootElement.getChildElement('TruncatedDQN', null).getAttributeCount() == 0 || 
               objRootElement.getChildElement('TruncatedDQN', null).getAttribute('Id',null) =='')){
                 return true;
           }
           */
           Dom.XMLNode tqdnNode = objRootElement.getChildElement('TruncatedDQN', null);
           if (tqdnNode != null) {
           	String tqdnId = tqdnNode.getAttribute('Id',null);
           	if (CommUtils.isBlank(tqdnId) && tqdnNode.getAttributeCount() == 0) return true;
           }
           // 2018/12/30 部屋自動割当機能AI対応 by zy END
        }
        return false;
    }
    
    public boolean validateInput(Dom.XMLNode pXMLNode,string strElementName){
        system.debug('>>>pXMLNode.getChildElement(strElementName,null).getName()'+pXMLNode.getChildElement(strElementName,null).getName());
        system.debug('ElementNamestrElementName'+strElementName);
        if(pXMLNode.getChildElement(strElementName,null).getName() == strElementName && 
           pXMLNode.getChildElement(strElementName,null).getText() != '' && 
           pXMLNode.getChildElement(strElementName,null).getText() != null){
           return true;
        }
        else{
            return false;
        }   
    }
   
    public integer returnInteger(Dom.XMLNode pXMLNode,string strElementName){
        return integer.valueof(pXMLNode.getChildElement(strElementName,null).getText());
    }
    
    public double returnDouble(Dom.XMLNode pXMLNode,string strElementName){
        return double.valueof(pXMLNode.getChildElement(strElementName,null).getText());
    }
    
    public Id createRecords(){
        system.debug('>>>>>>>>>objDomDoc'+objDomDoc);
        // 2019/09/15 Security Check BY zyz BEGIN
        List<String> chkFieldsLst = new List<String>{'comment__c','isactive__c','pendingbatches__c','msethreshold__c','discountfactor__c','batchsize__c','qtableref__c'};
        Map<String,Schema.SObjectField> mm = Schema.SObjectType.QQNTruncatedDQN__c.fields.getMap();
        if (!CommSecurityUtils.isCanCreateable(chkFieldsLst, mm)) {
        	return null;
        }
        List<String> chkFieldLst = new List<String>{'neuroncount__c','learningrate__c','layerid__c','isoutput__c'};
        Map<String,Schema.SObjectField> m = Schema.SObjectType.QQNLayer__c.fields.getMap();
        if (!CommSecurityUtils.isCanCreateable(chkFieldLst, m)) {
        	return null;
        }
        List<String> chkinFieldLst = new List<String>{'layercount__c','inputcount__c'};
        Map<String,Schema.SObjectField> inm = Schema.SObjectType.QQNNeuralNetwork__c.fields.getMap();
        if (!CommSecurityUtils.isCanCreateable(chkinFieldLst, inm)) {
        	return null;
        }
        // 2019/09/15 Security Check BY zyz END
        if(objDomDoc !=null){
           Dom.XMLNode objRootElement = objDomDoc.getRootElement(); 
           Dom.XMLNode objNeuralNetworkNode = objRootElement.getChildElement('TruncatedDQN', null).getChildElement('NeuralNetwork',null);
           Integer maxNeuronCount = getMaxRoomCount();
           // 初始化神经网络
           QQNNeuralNetwork__c cNN = new QQNNeuralNetwork__c();
           //cNN.InputCount__c = validateInput(objNeuralNetworkNode,'InputCount') ? returnInteger(objNeuralNetworkNode,'InputCount') : 3 ;
           //if (maxNeuronCount > cNN.InputCount__c) 
           cNN.InputCount__c = maxNeuronCount + 4;
           cNN.LayerCount__c = validateInput(objNeuralNetworkNode,'LayerCount') ? returnInteger(objNeuralNetworkNode,'LayerCount') : null ;
           cNN.LearningRate__c = validateInput(objNeuralNetworkNode,'LearningRate')? returnDouble(objNeuralNetworkNode,'LearningRate'):0.01 ;
           insert cNN;
           List<QQNLayer__c> lstLayers = new List<QQNLayer__c>();
           List<Dom.XMLNode> lstChildren = objNeuralNetworkNode.getChildElements() ;
           //system.debug('>>>>>>>lstChildren>'+lstChildren);
           for(integer i=0;i<lstChildren.size() ; i++){
               if(lstChildren[i].getChildElements().size() > 0){
                   QQNLayer__c objSFLayer = new QQNLayer__c(NetworkId__c =cNN.Id );
                   for(Dom.XMLNode child : lstChildren[i].getChildElements()){
                       if(child.getName() == 'LayerId')
                       objSFLayer.LayerId__c = integer.valueof(child.getText());
                       if(child.getName() == 'LearningRate')
                       objSFLayer.LearningRate__c = double.valueof(child.getText());
                       if(child.getName() == 'IsOutput')
                       objSFLayer.IsOutput__c = boolean.valueof(child.getText());
                       if(child.getName() == 'NeuronCount'){
                       	objSFLayer.NeuronCount__c = integer.valueof(child.getText());
                       	if (maxNeuronCount > objSFLayer.NeuronCount__c) objSFLayer.NeuronCount__c = maxNeuronCount;
                       }
                   }
                   objSFLayer.NeuronCount__c = maxNeuronCount;
                   lstLayers.add(objSFLayer);
               }
           }
           
           if(lstLayers.size() > 0){
              insert lstLayers;
           }
           
           /*String alphas = '{global: ' + cNN.LearningRate__c;
           for(Layer__c l : lstLayers) {
               alphas += ', layer[' + l.LayerId__c + ']: ' + l.LearningRate__c; 
           }
           alphas += '}';*/
           
           Dom.XmlNode objTDQNNode = objRootElement.getChildElement('TruncatedDQN', null);
           QQNTruncatedDQN__c cTdqn = new QQNTruncatedDQN__c();
           cTdqn.QTableRef__c = cNN.id;
           cTdqn.BatchSize__c = validateInput(objTDQNNode,'BatchSize') ? returnInteger(objTDQNNode,'BatchSize') : 64 ;
           cTdqn.DiscountFactor__c = validateInput(objTDQNNode,'DiscountFactor') ? returnDouble(objTDQNNode,'DiscountFactor') : 0.9 ;
           cTdqn.MseThreshold__c = validateInput(objTDQNNode,'MseThreshold') ? returnDouble(objTDQNNode,'MseThreshold') : 0 ;
           cTdqn.PendingBatches__c = validateInput(objTDQNNode,'PendingBatches') ? returnInteger(objTDQNNode,'PendingBatches') : 100 ;
           cTdqn.IsActive__c = validateInput(objTDQNNode,'IsActive') ? boolean.valueof(objTDQNNode.getChildElement('IsActive',null).getText()):false;
           cTdqn.Comment__c = validateInput(objTDQNNode,'Comment') ? objTDQNNode.getChildElement('Comment',null).getText() : '';
           //'[11] One layer NN (alpha=' + alphas + ', gamma=' + cTdqn.DiscountFactor__c + '). Re-assign penalty!';
           insert cTdqn;
           
           objRootElement.getChildElement('TruncatedDQN', null).setAttribute('Id',cTdqn.Id);
           //system.debug('>>>>>>>>>objDomDoc.toXmlString()'+objDomDoc.toXmlString());
           //system.debug('>>>>>>>>>lstDocument[0].body'+lstDocument);
           lstDocument[0].body = Blob.valueof(objDomDoc.toXmlString());
           //update lstDocument[0];
           //system.debug('>>>>>>>>>cNN'+cNN);
           //system.debug('>>>>>>>>>lstLayers'+lstLayers);
           //system.debug('>>>>>>>>>cTdqn'+cTdqn);
           return cTdqn.Id;
        }
        
       return null;
    }
    
    public Id updateRecords(){
        if(objDomDoc !=null){
           Dom.XMLNode objRootElement = objDomDoc.getRootElement();
           
           if(objRootElement.getChildElement('TruncatedDQN', null).getAttribute('Id',null) != ''){
              Id truncatedqnId = objRootElement.getChildElement('TruncatedDQN', null).getAttribute('Id',null);
              Dom.XMLNode objNeuralNetworkNode = objRootElement.getChildElement('TruncatedDQN', null);
              //system.debug('>>>>>>>objNeuralNetworkNode.getChildElemengetText()'+objNeuralNetworkNode);
              List<QQNTruncatedDQN__c> lstTruncatedDqn = [select Id,IsActive__c,MseThreshold__c,QTableRef__c,PendingBatches__c,BatchSize__c from QQNTruncatedDQN__c where id = :truncatedqnId];
              if(lstTruncatedDqn.size() > 0){
                 //system.debug('>>>>>>>objNeuralNetworkNode.getChildElemengetText()'+objNeuralNetworkNode.getChildElement('IsActive',null).getText());
                 lstTruncatedDqn[0].IsActive__c = boolean.valueof(objNeuralNetworkNode.getChildElement('IsActive',null).getText());
                 lstTruncatedDqn[0].MseThreshold__c = validateInput(objNeuralNetworkNode,'MseThreshold') ? returnDouble(objNeuralNetworkNode,'MseThreshold') : lstTruncatedDqn[0].MseThreshold__c ; 
                 lstTruncatedDqn[0].PendingBatches__c = validateInput(objNeuralNetworkNode,'PendingBatches') ? returnInteger(objNeuralNetworkNode,'PendingBatches'):lstTruncatedDqn[0].PendingBatches__c;
                 lstTruncatedDqn[0].BatchSize__c = validateInput(objNeuralNetworkNode,'BatchSize') ? returnInteger(objNeuralNetworkNode,'BatchSize'):lstTruncatedDqn[0].BatchSize__c; 
                 lstTruncatedDqn[0].DiscountFactor__c = validateInput(objNeuralNetworkNode,'DiscountFactor') ? returnDouble(objNeuralNetworkNode,'DiscountFactor') : lstTruncatedDqn[0].DiscountFactor__c ; 
                 update lstTruncatedDqn;
                 //system.debug('>>>>>>>>>>>>lstTruncatedDqn'+lstTruncatedDqn);
                 List<QQNNeuralNetwork__c> lstNeuralNetwork = [select Id,LearningRate__c from QQNNeuralNetwork__c where Id = :lstTruncatedDqn[0].QTableRef__c ];
                 if(lstNeuralNetwork.size() > 0){
                    if(objNeuralNetworkNode.getChildElement('NeuralNetwork', null).getChildElement('LearningRate',null).getText() != '')
                       lstNeuralNetwork[0].LearningRate__c = double.valueof(objNeuralNetworkNode.getChildElement('NeuralNetwork', null).getChildElement('LearningRate',null).getText());  
                       update lstNeuralNetwork;
                    // system.debug('>>>>>>>>>>>>lstNeuralNetwork'+lstNeuralNetwork);
                    map<integer,QQNLayer__c> mapLayerIdLayer = new map<integer,QQNLayer__c>();
                    
                    for(QQNLayer__c objLayer : [select id,LayerId__c,LearningRate__c from QQNLayer__c where NetworkId__c= :lstNeuralNetwork[0].Id ]){
                        if(objLayer.LayerId__c !=null)
                           mapLayerIdLayer.put(integer.valueof(objLayer.LayerId__c),objLayer);
                    }
                    
                    if(mapLayerIdLayer.size() > 0){
                       List<Dom.XMLNode> lstChildren = objNeuralNetworkNode.getChildElement('NeuralNetwork', null).getChildElements() ;
                       List<QQNLayer__c> lstLayerXML = new List<QQNLayer__c>();
                       for(integer i=0;i<lstChildren.size() ; i++){
                            if(lstChildren[i].getChildElements().size() > 0){
                                QQNLayer__c objSFLayer = new QQNLayer__c();
                                for(Dom.XMLNode child : lstChildren[i].getChildElements()){
                                    if(child.getName() == 'LayerId')
                                       objSFLayer.LayerId__c = integer.valueof(child.getText());
                                    if(child.getName() == 'LearningRate')
                                       objSFLayer.LearningRate__c = double.valueof(child.getText());
                                }
                                lstLayerXML.add(objSFLayer);
                            }
                        }
                        
                        List<QQNLayer__c> lstLayertoUpdate = new List<QQNLayer__c>();
                        if(lstLayerXML.size() > 0){
                            for(QQNLayer__c objLayer : lstLayerXML){
                                if(objLayer.LayerId__c !=null && mapLayerIdLayer.containskey(integer.valueof(objLayer.LayerId__c))){ 
                                   QQNLayer__c objNewLayer = new QQNLayer__C(Id = mapLayerIdLayer.get(integer.valueof(objLayer.LayerId__c)).Id);
                                   objNewLayer.LearningRate__c = objLayer.LearningRate__c ;
                                   lstLayertoUpdate.add(objNewLayer);
                                }
                            }
                        }
                        //system.debug('>>>>>>>>>>>>lstLayertoUpdate'+lstLayertoUpdate);
                       if(lstLayertoUpdate.size() > 0)
                           upsert lstLayertoUpdate;
                    }
                 }
                 return lstTruncatedDqn[0].id;
              }
           }
        }
        return null;
    }
    public string getProperty(string key) {
    	return properties.get(key);
    }
    public Integer getMaxRoomCount(){
    	// 参照ツール
		List<QQNAILookup__c> looks = [select id from QQNAILookup__c where FieldName__c = 'ps__Rroom__c'];
		integer maxRoomInt = 600;
		integer roomInts = looks.size();
		if (roomInts > maxRoomInt) roomInts = maxRoomInt;
		// 部屋リスト作成
    	return roomInts;
    }
    public static Integer getMaxNueronsCount(){
    	Integer maxRoomInt = 600;
    	Integer inputCount = 0;
    	try {
	    	// 処理ターゲットのNODEを取得する
			Dom.XmlNode targetNode = CommXmlUtils.encodeParseXmlNoShopCodeNodeDoc('AI_Configuration',new String[]{});
	       	Dom.XMLNode objNeuralNetworkNode = targetNode.getChildElement('TruncatedDQN', null).getChildElement('NeuralNetwork',null);
	       	if (objNeuralNetworkNode != null) {
	       		Dom.XmlNode inputNode = objNeuralNetworkNode.getChildElement('InputCount',null);
	       		if (inputNode != null) inputCount = CommUtils.nullToIntZero(inputNode.getText());
	       	}
    	} catch (exception e) {}
       	// 参照ツール
		List<QQNAILookup__c> looks = [select id from QQNAILookup__c where FieldName__c = 'ps__Rroom__c'];
		// 2019/02/15 AI功能改修 by zy BEGIN
		if (inputCount < looks.size()) inputCount = looks.size() + 1;
		// 2019/02/15 AI功能改修 by zy END
		if (maxRoomInt < inputCount) inputCount = maxRoomInt;
		return inputCount;
    }
    // 2019/02/15 AI功能改修 by zy BEGIN
    public static double getLearningRate(){
    	double discountFactor = 0.01;
    	try {
    	// 処理ターゲットのNODEを取得する
		Dom.XmlNode targetNode = CommXmlUtils.encodeParseXmlNoShopCodeNodeDoc('AI_Configuration',new String[]{});
       	Dom.XMLNode truncatedDQNNode = targetNode.getChildElement('TruncatedDQN', null);
    	if (truncatedDQNNode != null) {
    		Dom.XmlNode inputNode = truncatedDQNNode.getChildElement('LearningRate',null);
       		if (inputNode != null) discountFactor = double.valueof(CommUtils.nullToZero(inputNode.getText()));
    	}
    	} catch(exception e){}
    	return discountFactor;
    }
    public static double getDiscountFactor(){
    	double discountFactor = 0.9;
    	try {
    	// 処理ターゲットのNODEを取得する
		Dom.XmlNode targetNode = CommXmlUtils.encodeParseXmlNoShopCodeNodeDoc('AI_Configuration',new String[]{});
       	Dom.XMLNode truncatedDQNNode = targetNode.getChildElement('TruncatedDQN', null);
    	if (truncatedDQNNode != null) {
    		Dom.XmlNode inputNode = truncatedDQNNode.getChildElement('DiscountFactor',null);
       		if (inputNode != null) discountFactor = double.valueof(CommUtils.nullToZero(inputNode.getText()));
    	}
    	} catch(exception e){}
    	return discountFactor;
    }
    //　訓練データ最大限設定
    public static integer getTrainDataLimit(){
    	Integer limitSize = 10000;
    	try {
	    	// 処理ターゲットのNODEを取得する
			Dom.XmlNode targetNode = CommXmlUtils.encodeParseXmlNoShopCodeNodeDoc('AI_Configuration',new String[]{});
	       	Dom.XMLNode truncatedDQNNode = targetNode.getChildElement('TRAINLIMIT', null);
	    	if (truncatedDQNNode != null) {
	    		limitSize = CommUtils.nullToIntZero(truncatedDQNNode.getText());
	    	}
    	} catch(exception e){}
    	return limitSize;
    }
     //　指定部屋タイプ最大限設定
    public static Set<Decimal> getRoomTypeSQL(){
    	Set<Decimal> roomTypeSet = new Set<Decimal>();
    	try {
	    	// 処理ターゲットのNODEを取得する
			Dom.XmlNode targetNode = CommXmlUtils.encodeParseXmlNoShopCodeNodeDoc('AI_Configuration',new String[]{});
	       	Dom.XMLNode roomTypeNode = targetNode.getChildElement('ROOMTYPESEQ', null);
	    	if (roomTypeNode != null) {
	    		String roomTypes = CommUtils.nullToBlank(roomTypeNode.getText());
	    		for (String splitDecimal : CommUtils.nullToBlank(roomTypes).trim().deletewhitespace().split(',')) {
	    			if (CommUtils.isBlank(splitDecimal)) continue;
	    			roomTypeSet.add(CommUtils.nullToZero(splitDecimal));
	    		}
	    	}
    	} catch(exception e){}
    	return roomTypeSet;
    }
    // 2019/02/15 AI功能改修 by zy END
}