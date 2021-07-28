/************************************************************************
 Name: AIDriver 
 Purpose: To handle all the DB interaction and drive the training process
 History:  
 部屋自動割当運転クラス
*************************************************************************   
    Version        Created by         Date             Description       
      1            Ajay/Akshay      11/16/2016          Created
*************************************************************************/
// 2019/09/15 Security Check BY zyz BEGIN
global with sharing class QQNAIDriver {
// 2019/09/15 Security Check BY zyz END
    private integer pendingBatches;
    @TestVisible
    public QQNTruncatedDQN tdqn;
    private Id tdqnSFID; 
    public QQNNeuralNetwork neuralNetwork;
    private List<QQNLayer> lstLayerClass;
    private integer intbatchNumber;
    private boolean blnInsertRequired;
    private QQNTdqnLoadHandler onLoadHandler;
    private QQNAIOnTrainHandler onTrainHandler;
    private QQNTrainingBatchCreator trainingBatchCreator;
    private integer batchSize;
    private double mseThreshold;
    public double mse;
    
    public QQNAIDriver (Id ptdqnSFID){
        tdqnSFID = ptdqnSFID;
    }
    
    /** Method called on click of custom button from the TruncatedDQN record
      * @param salesforceId of the TruncatedDQN record
      */
    webservice static void callLoad(Id ptdqnSFID) {
        system.debug('>>>>>>>>Method Called'+ptdqnSFID);
        QQNAIDriver objAIDriver = new QQNAIDriver(ptdqnSFID);
        
        if(ptdqnSFID != null){
        	objAIDriver.setOnLoadHandler(new QQNTrainingTdqnLoadHandler());
        	//	objAIDriver.setTrainingBatchCreator(...);
            objAIDriver.load();
        }
    }
   
   /** Construct the Neural Network and TruncatedDQN instance using the TruncatedDQN SalesforceId
     * @return the instance of TruncatedDQN class
     */
    public QQNTruncatedDQN load(){
        List<QQNTruncatedDQN__c> lstTruncatedDqn = [Select BatchSize__c,DiscountFactor__c,
                                                 MseThreshold__c,PendingBatches__c,
                                                 QTableRef__c from QQNTruncatedDQN__c
                                                 where Id = :tdqnSFID] ;
                
        double discountFactor;
        integer qTableRef;
        string strNeuralNetworkSfId;
        
        if(lstTruncatedDqn.size() > 0){
            batchSize = Integer.valueOf(lstTruncatedDqn[0].BatchSize__c);
            mseThreshold = lstTruncatedDqn[0].MseThreshold__c;
            pendingBatches =  Integer.valueOf(lstTruncatedDqn[0].PendingBatches__c);
            discountFactor = lstTruncatedDqn[0].DiscountFactor__c;
            strNeuralNetworkSfId = lstTruncatedDqn[0].QTableRef__c;
            // 取得当前神经网络相关信息
            integer inputCount = loadNeuralNetwork(strNeuralNetworkSfId);
            // 作成当前处理平面
            tdqn = new QQNTruncatedDQN(lstTruncatedDqn[0],new QQNNNQTable(neuralNetwork), discountFactor);
            loadLayer(0, inputCount);
        }
        
        return tdqn;
    }
   
   /** Construct the NeuralNetwork Instance
     * @param NeuralNetwork Salesforce Id
     * @return the instance
     */ 
    private integer loadNeuralNetwork(string pstrNeuralNetworkSFId){
        List<QQNNeuralNetwork__c> lstNeuralNetwork = [select InputCount__c,
                                                   LayerCount__c,LearningRate__c 
                                                   from QQNNeuralNetwork__c where 
                                                   Id =:pstrNeuralNetworkSFId ];
        integer inputCount = 0;
        if(lstNeuralNetwork.size() > 0) {
        	// 处理房间数
            inputCount = Integer.valueOf(lstNeuralNetwork[0].InputCount__c) ;
            // 层级
            integer layerCount = Integer.valueOf(lstNeuralNetwork[0].LayerCount__c) ;
            // 学习比率 默认值0.001
            double globalLearningRate  = lstNeuralNetwork[0].LearningRate__c;
            neuralNetwork = new QQNNeuralNetwork(lstNeuralNetwork[0]);
            // 根据神经网络取得当前层级
            loadLayers(pstrNeuralNetworkSFId, neuralNetwork, globalLearningRate);
        }
        
        return inputCount;
    } 
  
   /** Evaluate the Layers and store it the Map collection
     * @param NeuralNetworkSalesforce Id,Neural Network instance, globallearning rate,inputcount
     * Call the loadNeuron() by passing map<LayerSFId,Layer> as a parameter
     * 当前层级取得
     */ 
    private void loadLayers(string pstrNeuralNetworkSFId, QQNNeuralNetwork neuralNetwork, 
                            double globalLearningRate){
        lstLayerClass = new List<QQNLayer>();
        // 当前神经网络参照层级
        List<QQNLayer__c> lstLayer = [select Id,LayerId__c,LearningRate__c,NetworkId__c,
                                   NeuronCount__c,IsOutput__c from QQNLayer__c 
                                   where NetworkId__c =:pstrNeuralNetworkSFId 
                                   order By LayerId__c ASC ];
        List<QQNAILayerLoaderBatch> loaders = new List<QQNAILayerLoaderBatch>();
        
        blnInsertRequired = false;
        for(QQNLayer__c objLayer : lstLayer) {
        	// 学习比率 默认值-1
            double localLearningRate = objLayer.LearningRate__c;
            double learningRate;
            if(globalLearningRate < 0)
               learningRate = localLearningRate;
            else 
               learningRate = globalLearningRate;
    
            QQNLayer layer = new QQNLayer(objLayer, learningRate, neuralNetwork);
            lstLayerClass.add(layer);
        }
    }
    /**
    * 処理層運転
    * layerNumber:処理層数
    * inputCount:運転数
    */
    private void loadLayer(integer layerNumber, integer inputCount) {
    	// 新規の場合
    	if(layerNumber < lstLayerClass.size()) {
    		Database.executebatch(new QQNAILayerLoaderBatch(lstLayerClass[layerNumber], this, inputCount, layerNumber));
    	} else if (onLoadHandler != null) {
    		Database.executebatch(new QQNRoomTrainBatch(this),1);
    		//onLoadHandler.tdqnLoaded(this);
    	}
    }
    
    /*
    * Callback method to be called after the contents of each layer have been fetched from DB
    * 処理層取得完了、運転訓練
    * pObjLayer：処理層
    * pblnInsertRequired：神経単位のデータあり
    * layerNumber：処理層数
    */
    public void layerLoaded(QQNLayer pObjLayer, boolean pblnInsertRequired, integer layerNumber) {
    	QQNLayer__c sfLayer = pObjLayer.getSFObject();
        blnInsertRequired = blnInsertRequired || pblnInsertRequired;
        System.debug('<AIDriver>: ' + this);
        System.debug('<Layer>: ' + pObjLayer);
        System.debug('<Layer__c>' + sfLayer);
        // 神经网络添加処理層
        neuralNetwork.addLayer(pObjLayer, sfLayer.IsOutput__c);
        // 処理層運転
        loadLayer(layerNumber + 1, Integer.valueOf(sfLayer.NeuronCount__c));
    }
    
    public void setOnLoadHandler(QQNTdqnLoadHandler handler) {
    	onLoadHandler = handler;
    }
    
    public void setTrainingBatchCreator(QQNTrainingBatchCreator creator) {
    	trainingBatchCreator = creator;
    }
    
    public void setOnTrainHandler(QQNAIOnTrainHandler handler) {
    	onTrainHandler = handler;
    }
    
    public integer getBatchSize() {
    	return batchSize;
    }
    
    public boolean isInsertRequired() {
    	return blnInsertRequired;
    }
    
    public QQNTruncatedDQN getTDQN() {
    	return tdqn;
    }
    public void trainTDQN() {
        if(tdqn != null) {
			/*List<AggregateResult> lstBatchMSE = [select max(BatchNumber__c) from BatchMSE__c 
			                                    where TdqnId__c=:tdqnSFID ];
			intbatchNumber = (lstBatchMSE.size() > 0)  && (lstBatchMSE[0].get('expr0') !=null) 
			              ? Integer.valueOf(lstBatchMSE[0].get('expr0')) + 1 
			              : 0;*/
			List<QQNBatchMSE__c> lstBatchMSE = [select BatchNumber__c, MSE__c from QQNBatchMSE__c
											where TdqnId__c=:tdqnSFID order by BatchNumber__c desc limit 1];
			if(lstBatchMSE.size() > 0) {
				intbatchNumber = Integer.valueOf(lstBatchMSE[0].BatchNumber__c) + 1; 
				mse = Double.valueOf(lstBatchMSE[0].MSE__c);
			} else {
				intbatchNumber = 0; 
				mse = mseThreshold + 1;
			}
			
			trainBatch();
        }
    }
    // 訓練バッチ処理
    private void trainBatch(){
        if(pendingBatches > 0 && trainingBatchCreator != null && mse > mseThreshold) {
        	// 取得训练batch
        	List<QQNQLearningTuple> batch = trainingBatchCreator.prepareBatch(this);
        	mse = tdqn.trainBatch(batch);
            system.debug('[' + intbatchNumber + ']: pendingBatches = ' + pendingBatches + ', mse = ' + mse);
        	pendingBatches--;
        	
			//	Dropped NeuronWeights table
			Database.executebatch(new QQNAISaveNeurons(this));
		} else if(onTrainHandler != null) {
			onTrainHandler.trainingComplete(this);
		}
    }
    public void trainingBatchComplete() {
    	blnInsertRequired = false;
    	try {
    		tdqn.getSFObject().PendingBatches__c = pendingBatches;
    		intbatchNumber = 0;
    		update tdqn.getSFObject();
    		QQNBatchMSE__c objBatchMSE = new QQNBatchMSE__c(BatchNumber__c = intbatchNumber,
                                                    MSE__c = mse ,
                                                    TdqnId__c = tdqnSFID
                                                    );
			insert objBatchMSE;
		} catch(DMLException ex) {
			generateErrorLog('Error while updating DQN or creating BatchMSE'+ex.getMessage());
		}
		
		intbatchNumber++;
        // 2019/02/15 AI功能改修 by zy BEGIN
        //trainBatch();
        sendMail();
        // 2019/02/15 AI功能改修 by zy END
    }
    public static void generateErrorLog(string strErrorMessage){
        // 2019/09/15 Security Check BY zyz BEGIN
        List<String> chkFieldsLst = new List<String>{'description__c'};
        Map<String,Schema.SObjectField> mm = Schema.SObjectType.QQNErrorLog__c.fields.getMap();
        if (!CommSecurityUtils.isCanCreateable(chkFieldsLst, mm)) {
        	return ;
        }
        // 2019/09/15 Security Check BY zyz END
        QQNErrorLog__c objErrorLog = new QQNErrorLog__c();
        objErrorLog.Description__c = strErrorMessage;
        insert objErrorLog;
    }
    // 2019/02/15 AI功能改修 by zy BEGIN
    public integer prcessInt = 0;
    public static QQNTruncatedDQN getTqdn() {
   		QQNNeuralNetwork neuralNetwork = createNetWork();
   		double discountFactor = QQNAIConfigurationCreator.getDiscountFactor();
   		QQNTruncatedDQN tdqn = new QQNTruncatedDQN(new QQNTruncatedDQN__c(),new QQNNNQTable(neuralNetwork), discountFactor);
   		return tdqn;
    }
   	private static QQNNeuralNetwork createNetWork(){
   		List<QQNNeuron__c> qqns = [select Id,  LayerId__c, Name, NeuronId__c , WeightCount__c, Weights__c from QQNNeuron__c];
        QQNNeuralNetwork netWork = new QQNNeuralNetwork(new QQNNeuralNetwork__c());
        Map<String,List<QQNNeuron__c>> layersMap = new map<String,List<QQNNeuron__c>>();
        // 学习比率
        double learningRate = QQNAIConfigurationCreator.getLearningRate();
        for (QQNNeuron__c qqn : qqns) {
        	if (!layersMap.containsKey(qqn.LayerId__c)) layersMap.put(qqn.LayerId__c,new List<QQNNeuron__c>());
        	layersMap.get(qqn.LayerId__c).add(qqn);
        }
        for (String layId : layersMap.keyset()) {
        	List<QQNNeuron__c> neurons = layersMap.get(layId);
        	QQNLayer layer = new QQNLayer(new QQNLayer__c(id = layId), learningRate, netWork);
        	List<QQNNeuron> qnnLst = new List<QQNNeuron>();
        	for (QQNNeuron__c qqn : neurons) {
        		QQNNeuron neuron = new QQNNeuron(qqn,layer);
        		qnnLst.add(neuron);
        	}
        	layer.initialize(qnnLst);
        	netWork.addLayer(layer,true);
        }
        return netWork;
   }
   	// 処理結果の送信処理
	private void sendMail() {
		String mailAdds = CommDefine__c.getOrgDefaults().ScheduleResultMailAddress__c;
		if(CommUtils.isBlank(mailAdds)) return;
		// メール情報を設定する
		String body = '';
		String mailBodyStr = 'データ学習処理が完了しました（ご予約：' + prcessInt + '件）';
		mailBodyStr += '\n\nJinyaConnect Enterprise system R&D team.';
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = mailAdds.split(',');
		mail.setToAddresses(toAddresses);
		mail.setSubject('[部屋自動割当機能] データ学習結果の通知['+UserInfo.getOrganizationName()+']');
		mail.setPlainTextBody(mailBodyStr);
		// テストクラスの場合、実施しない
		if(!Test.isRunningTest()) {
			try {
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
			} catch(Exception e){}
		}
	}
   // 2019/02/15 AI功能改修 by zy END
}// End of Class