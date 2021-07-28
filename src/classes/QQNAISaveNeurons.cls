/************************************************************************
 Name: AILayerLoaderBatch
 Purpose: To handle all the DB interaction and drive the training process
 History:  
*************************************************************************   
    Version        Created by         Date             Description       
      1            Ajay/Akshay      11/28/2016          Created
*************************************************************************/

public class QQNAISaveNeurons implements Database.Batchable<sObject>,Database.Stateful {
	
	private QQNAIDriver objAIDriver;
	private Map<Id, QQNLayer> layerMap;
	
	public QQNAISaveNeurons(QQNAIDriver pobjAIDriver) {
		objAIDriver = pobjAIDriver;
		layerMap = new Map<Id, QQNLayer>();
    }
    // 2019/02/15 AI功能改修 by zy BEGIN
    public QQNAISaveNeurons(QQNAIDriver pobjAIDriver,Integer layoutCnt,integer neuronCnt) {
    	intLayerCnt = layoutCnt;
    	intNeuronCnt = neuronCnt;
    	objAIDriver = pobjAIDriver;
    }
    private integer intLayerCnt = 0;
    private integer intNeuronCnt = 0;
    public List<QQNNeuron__c> start(Database.BatchableContext BC){
    	List<QQNNeuron__c> lstNeuronToInsert = new List<QQNNeuron__c>();
    	if (objAIDriver != null && objAIDriver.neuralNetwork != null) {
	        QQNLayer objLayer = objAIDriver.neuralNetwork.getLayer(intLayerCnt);
	        if (objLayer != null) {
	        	for (integer i = 0 ; i <= objLayer.getNeuronCount() ; i++) {
	        		lstNeuronToInsert.add(new QQNNeuron__c());
	        	}
	        }
    	}
        return lstNeuronToInsert;
    }
    public void execute(Database.BatchableContext BC, List<QQNNeuron__c> plstNeuronToInsert) {
      	// 2019/09/15 Security Check BY zyz BEGIN
      	List<String> chkFieldsLst = new List<String>{'neuronid__c','weights__c','weightcount__c','layerid__c'};
      	Map<String,Schema.SObjectField> mm = Schema.SObjectType.QQNNeuron__c.fields.getMap();
      	if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
      		return ;
      	}
      	// 2019/09/15 Security Check BY zyz END
      	QQNLayer objLayer = objAIDriver.neuralNetwork.getLayer(intLayerCnt);
      	List<QQNNeuron__c> neurons = new List<QQNNeuron__c>();
      	for (QQNNeuron__c neuron : plstNeuronToInsert) {
      		QQNNeuron objneuron = objLayer.getNeuron(intNeuronCnt);
      		if (objneuron != null) {
      			QQNNeuron__c objNeuronSF = objneuron.getSFObject();
            	objNeuronSF.NeuronId__c = intNeuronCnt;
            	neurons.add(objNeuronSF);
      		}
      		objLayer.removeNeuron(intNeuronCnt);
      		intNeuronCnt++;
      	}
      	try {
      		if(objAIDriver.isInsertRequired()) {
	      		insert neurons;
    
	      		//	Update IDs of the newly inserted neurons in the corresponding Neuron objects
				/*
	      		for(QQNNeuron__c neuron : neurons) {

	      			objLayer.getNeuron(Integer.valueOf(neuron.NeuronId__c)).setSFObject(neuron);
	      		}*/
      		} else {
system.debug(logginglevel.info,'neurons:::' + neurons);
      			update neurons;
      		}
      	} catch(Dmlexception ex) {
      		// 2019/09/15 Security Check BY zyz BEGIN
      		List<String> chkFieldLst = new List<String>{'description__c'};
      		Map<String,Schema.SObjectField> m = Schema.SObjectType.QQNErrorLog__c.fields.getMap();
      		if (!CommSecurityUtils.isCanCreateable(chkFieldLst, m)) {
      			return ;
      		}
      		// 2019/09/15 Security Check BY zyz END
      		QQNErrorLog__c objErrorLog = new QQNErrorLog__c();
      		objErrorLog.Description__c = 'Error while creating the Neurons : '+ ex.getMessage();
      		insert objErrorLog;
      	}
    }
    /*
    // 2019/02/15 AI功能改修 by zy END
    public List<QQNNeuron__c> start(Database.BatchableContext BC){
    	List<QQNNeuron__c> lstNeuronToInsert = new List<QQNNeuron__c>();
        QQNLayer objLayer;
        QQNNeuron objneuron;
        if (objAIDriver != null && objAIDriver.neuralNetwork != null) {
	        // 取得更新的神经元
	        for (Integer intLayerCnt = 0;
	        		(objLayer = objAIDriver.neuralNetwork.getLayer(intLayerCnt)) != null; intLayerCnt++) {
	        	layerMap.put(objLayer.getSFObject().id, objLayer);
	            for(Integer intNeuronCnt = 1; (objneuron = objLayer.getNeuron(intNeuronCnt)) != null; intNeuronCnt++) {
	                QQNNeuron__c objNeuronSF = objneuron.getSFObject();
	                objNeuronSF.NeuronId__c = intNeuronCnt;
	                lstNeuronToInsert.add(objNeuronSF);
	            }
	        }
        }
        return lstNeuronToInsert;
    }
    
    public void execute(Database.BatchableContext BC, List<QQNNeuron__c> plstNeuronToInsert) {
      	QQNLayer objLayer;
      	
      	try {
      		if(objAIDriver.isInsertRequired()) {
	      		insert plstNeuronToInsert;
	      		
	      		//	Update IDs of the newly inserted neurons in the corresponding Neuron objects
	      		objLayer = null;
	      		Id lastLayerId = null;
	      		for(QQNNeuron__c neuron : plstNeuronToInsert) {
	      			if(lastLayerId != neuron.LayerId__c) {
	      				lastLayerId = neuron.LayerId__c;
	      				objLayer = layerMap.get(lastLayerId);
	      			}
	      			objLayer.getNeuron(Integer.valueOf(neuron.NeuronId__c)).setSFObject(neuron);
	      		}
      		} else {
      			update plstNeuronToInsert;
      		}
      	} catch(Dmlexception ex) {
      		QQNErrorLog__c objErrorLog = new QQNErrorLog__c();
      		objErrorLog.Description__c = 'Error while creating the Neurons : '+ ex.getMessage();
      		insert objErrorLog;
      	}
    }
    // 2019/02/15 AI功能改修 by zy BEGIN
    */
    // 2019/02/15 AI功能改修 by zy END
    public void finish(Database.BatchableContext BC) {
    	//system.debug('NEURONS INSERTED: ' + objAIDriver);
        //objAIDriver.neuronsSaved();
        if(objAIDriver != null) objAIDriver.trainingBatchComplete();
    }
}