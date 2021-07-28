/************************************************************************
 Name: AILayerLoaderBatch
 Purpose: To handle all the DB interaction and drive the training process
 History:  
*************************************************************************   
    Version        Created by         Date             Description       
      1            Ajay/Akshay      11/24/2016          Created
*************************************************************************/


public class QQNAILayerLoaderBatch implements Database.Batchable<sObject>, Database.Stateful {
    // 神経単位チェック
    private boolean blnLoadNewNeuron;
    private integer intInputCount;
    private integer intLayerNumber;
    // 処理層
    private QQNLayer objLayer;
    private QQNAIDriver objAIDriver;
    // 2018/12/30 部屋自動割当機能AI対応 by zy BEGIN
    // 初期化神経単位
    private List<QQNNeuron> nerurons;
    private boolean isRoomLookUpFlag;
    // 2018/12/30 部屋自動割当機能AI対応 by zy END
    // Construtor
    public QQNAILayerLoaderBatch(QQNLayer pObjLayer, QQNAIDriver pObjAIDriver, integer pintInputCnt, integer pLayerNumber){
        blnLoadNewNeuron = true;
        intInputCount = pintInputCnt;
        intLayerNumber = pLayerNumber;
        objLayer = pObjLayer; 
        objAIDriver = pObjAIDriver; 
        // 2018/12/30 部屋自動割当機能AI対応 by zy BEGIN
        nerurons = new List<QQNNeuron>();
        isRoomLookUpFlag = false;
        // 2018/12/30 部屋自動割当機能AI対応 by zy END
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        String strLayerIdToProcess = objLayer.getSFObject().Id;
        String strNeuronquery = 'select Id, NeuronId__c, LayerId__c, WeightCount__c, Weights__c' +
                       ' from QQNNeuron__c where LayerId__c = \'' + strLayerIdToProcess + '\''+ 
                       ' order by NeuronId__c ASC';
        /*
        // 2018/12/30 部屋自動割当機能AI対応 by zy BEGIN
        // 神経単位不存在
        List<QQNNeuron__c> QQNNeurons = [select id from QQNNeuron__c where LayerId__c = :strLayerIdToProcess limit 100];
        if (QQNNeurons.isEmpty()) {
        	isRoomLookUpFlag = true;
        	strNeuronquery = 'select id from Room__c limit ' + intInputCount;
        }
        // 2018/12/30 部屋自動割当機能AI対応 by zy END
        */
        return Database.getQueryLocator(strNeuronquery);
    }
    // 2018/12/30 部屋自動割当機能AI対応 by zy BEGIN
    public void execute(Database.BatchableContext BC, List<Sobject> scope) {
    	if (isRoomLookUpFlag) {
    		nerurons.add(new QQNNeuron(intInputCount + 1, objLayer));
    	} else {
    		// 神経単位あり
        	blnLoadNewNeuron = false;
	        // 該当処理層の神経単位追加
	        for(Sobject neuronObj : scope) {
	        	QQNNeuron__c neuronSFObject = (QQNNeuron__c) neuronObj;
	            QQNNeuron neuron = new QQNNeuron(neuronSFObject, objLayer);
	            objLayer.addNeuron(neuron);
	        }
    	}
    }
    // 2018/12/30 部屋自動割当機能AI対応 by zy END
    public void finish(Database.BatchableContext BC){
    	// 不存在数据
        if(blnLoadNewNeuron)
        	// 処理層初期化神経単位（部屋数）
        	//objLayer.initialize(nerurons);
            objLayer.initialize(intInputCount, Integer.valueof(objLayer.getSFObject().NeuronCount__c)); 
        if(!Test.isRunningTest())
        	objAIDriver.layerLoaded(objLayer, blnLoadNewNeuron, intLayerNumber);
    }
}