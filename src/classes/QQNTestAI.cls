/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class QQNTestAI {
 	
 	@isTest(SeeAllData=true)
 	static void testRoomReservationAI(){
 		 Test.startTest();
		 QQNRoomReservationAI.prepareAILookup();
		 QQNRoomReservationAI.prepareTimeline(0);
		 QQNRoomReservationAI.createAI();
		 QQNRoomReservationAI.train();
		 QQNRoomReservationAI.printStats();
		 QQNRoomReservationAI.emailStats();
		 Test.stopTest();	
 	}
 	
 	@isTest(SeeAllData=true)
 	static void testRoomReservationAIXMLCreate(){
 		Test.startTest();

		QQNRoomReservationAI.trainFromXMLConfig();		
		
		Test.stopTest();
 	}
 	
 	@isTest(SeeAllData=true)
 	static void testRoomReservationAIXMLUpdate() {
 		QQNNeuralNetwork__c cNN = new QQNNeuralNetwork__c();
        cNN.InputCount__c = 2;
        cNN.LayerCount__c = 1;
        cNN.LearningRate__c = -1;
        insert cNN;
        
        List<QQNLayer__c> cLayers = new List<QQNLayer__c>();
        
        QQNLayer__c cLayer = new QQNLayer__c();
        cLayer.NetworkId__c = cNN.id;
        cLayer.LayerId__c = 0;
        cLayer.LearningRate__c = 0.01;
        cLayer.IsOutput__c = true;
        cLayer.NeuronCount__c = 2;
        cLayers.add(cLayer);
        
        insert cLayers;
        
        System.debug(cNN.id + ': ' + cNN.Name);
        QQNTruncatedDQN__c cTdqn = new QQNTruncatedDQN__c();
        cTdqn.QTableRef__c = cNN.id;
        cTdqn.BatchSize__c = 64;
        cTdqn.Comment__c = 'Square test';
        cTdqn.DiscountFactor__c = 0.9;
        cTdqn.MseThreshold__c = 0.001;
        cTdqn.PendingBatches__c = 64;
        insert cTdqn;
        
 		Test.startTest();
 		List<Document> lstDocument = [select Id , body from document where Name='AI Configuration'];
		Dom.Document objDomDoc = new Dom.Document();
		objDomDoc.load(lstDocument[0].body.tostring());
		Dom.XmlNode tdqnNode = objDomDoc.getRootElement().getChildElement('TruncatedDQN', null);
		tdqnNode.setAttribute('Id', cTdqn.id);
		Dom.XmlNode pendingBatchesNode = tdqnNode.getChildElement('PendingBatches', null);
		for(Dom.XmlNode child : pendingBatchesNode.getChildren()) {
			if(child.getNodeType() == Dom.XmlNodeType.Text) {
				pendingBatchesNode.removeChild(child);
				pendingBatchesNode.addTextNode('2');
				break;
			}
		}
		lstDocument[0].body = Blob.valueof(objDomDoc.toXmlString());
		update lstDocument[0];
		
		QQNRoomReservationAI.trainFromXMLConfig();
		
		Test.stopTest();
 	}
 	
 	@isTest(SeeAllData=true)
 	static void testRoomReservationAICustomButton(){
 		 Test.startTest();
		// RoomReservationAI.prepareAILookup();
		// RoomReservationAI.prepareTimeline(0);
		 QQNRoomReservationAI.createAI();
		 List<QQNTruncatedDQN__c> tdqnList = [
    		SELECT id FROM QQNTruncatedDQN__c WHERE IsActive__c = true ORDER BY Name DESC
    	];
    	 if(tdqnList.size() > 0)
		 //zyz TQDNCustomButtonHandler.train(tdqnList[0].id);
		 Test.stopTest();	
 	}
 	
 	@isTest
 	static void testAIEventLoaderBatchDetail(){
 		QQNNeuralNetwork__c cNN = new QQNNeuralNetwork__c();
        cNN.InputCount__c = 2;
        cNN.LayerCount__c = 1;
        cNN.LearningRate__c = -1;
        insert cNN;
        
        List<QQNLayer__c> cLayers = new List<QQNLayer__c>();
        
        QQNLayer__c cLayer = new QQNLayer__c();
        cLayer.NetworkId__c = cNN.id;
        cLayer.LayerId__c = 0;
        cLayer.LearningRate__c = 0.01;
        cLayer.IsOutput__c = true;
        cLayer.NeuronCount__c = 2;
        cLayers.add(cLayer);
        
        insert cLayers;
        
        System.debug(cNN.id + ': ' + cNN.Name);
        QQNTruncatedDQN__c cTdqn = new QQNTruncatedDQN__c();
        cTdqn.QTableRef__c = cNN.id;
        cTdqn.BatchSize__c = 64;
        cTdqn.Comment__c = 'Square test';
        cTdqn.DiscountFactor__c = 0.9;
        cTdqn.MseThreshold__c = 0.001;
        cTdqn.PendingBatches__c = 64;
        insert cTdqn;
        
        ps__TypeOfRooms__c objRoomTypes = new ps__TypeOfRooms__c();
 		objRoomTypes.Name = '露天風呂付';
 		insert objRoomTypes; 
        
        ps__Room__c objPsRoom = new ps__Room__c();
 		objPsRoom.Name = 'Test Room';
 		objPsRoom.ps__CapacityHaku__c = 2;
 		objPsRoom.ps__Capacity__c = 2;
 		objPsRoom.ps__TypeRoomRef__c = objRoomTypes.Id;
 		insert objPsRoom;
 		
 		QQNAILookup__c objAILookup = new QQNAILookup__c();
 		objAILookup.FieldName__c = 'ps__Rroom__c';
 		objAILookup.FieldValue__c = objPsRoom.id;
 		objAILookup.TableName__c = 'ps__Lead__c';
 		objAILookup.TranslatedValue__c = 0;
 		insert objAILookup;
 		
 		Account objAcc = new Account();
 		objAcc.name = 'Test Account';
 		insert objAcc;
 		
 		Contact objContact = new Contact();
 		objContact.lastname = 'Testing';
 		objContact.AccountId = objAcc.id;
 		insert objContact;
 		
 		List<ps__Lead__c> lstPsLead = new List<ps__Lead__c>();
 		
 		List<RecordType> lstRecordType = [select Id ,DeveloperName,sobjecttype from 
 		                                  RecordType where DeveloperName = 'BaseRecType'];
 		
 		String strRecordType = lstRecordType.size() > 0 ? lstRecordType[0].Id : '';
 		
 	    ps__Type__c objRoomType = new ps__Type__c();
 		objRoomType.ps__Field1__c = 'Test';
 		objRoomType.Name = 'Test';
 		insert objRoomType;
 		
 	
 		
 		for(integer i=0;i<1;i++){
 			ps__Lead__c objPsLead = new ps__Lead__c();
 			objPsLead.Name = 'Test Record '+ i;
 			objPsLead.recordTypeId = strRecordType;
 			objPsLead.ps__Relcontact__c = objContact.Id;
 			objPsLead.ps__ReservedStatus__c = '確認中';
 			objPsLead.ps__ReservedDate__c = Date.today() - 1 ;
 			objPsLead.ps__EntryTime__c = Date.today() - 1 ;
 			objPsLead.ps__Departure__c = Date.today() ;
 			objPsLead.ps__StayPersons__c = 1;
 			objPsLead.ps__Rroom__c = objPsRoom.Id;
 			objPsLead.ps__refTypeOfRooms__c = objRoomTypes.Id; 
 			objPsLead.ps__ReservedType__c ='昼 特企';
 			objPsLead.ps__Field367__c = '婚礼';
 			objPsLead.ps__Segment__c = '陣屋コネクト 契約関係';
 			objPsLead.field4__c = '10:00';
 			objPsLead.field3__c = '4:00';
 			lstPsLead.add(objPsLead);
 		}
 		insert lstPsLead;
 		test.starttest();
 		Database.executebatch(new QQNAILookupFieldBatch('ps__Lead__c', 'ps__Rroom__c'));
 		Database.executebatch(new QQNAIEventLoaderBatch(0));
 		test.stoptest();
        
        for(QQNAIEvent__c event : [
        		select Time__c, Ps_LeadIndexRef__c, StateBefore__c, RoomsAssigned__c
        		from QQNAIEvent__c order by Time__c]) {
        	System.debug(event);
        }
 	}
 	
 	@isTest
 	static void testAIEventLoaderBatch() {
 		string xmlConfigString = '<?xml version="1.0" encoding="UTF-8"?>' +
		'<Configuration>' + 
			'<Properties>' +
				'<Property key="soql_deleted" value="削除"/>' +
				'<Property key="soql_cancelled" value="キャンセル"/>' +
				'<Property key="soql_noshow" value="NO SHOW"/>' +
			'</Properties>' +
		'</Configuration>';
		
		Document doc = new Document(Name='AI Configuration', FolderId=UserInfo.getUserId());
		doc.body = Blob.valueof(xmlConfigString);
        insert doc;
        
        system.debug('XML inserted');
        
 		QQNNeuralNetwork__c cNN = new QQNNeuralNetwork__c();
        cNN.InputCount__c = 2;
        cNN.LayerCount__c = 1;
        cNN.LearningRate__c = -1;
        insert cNN;
        
        List<QQNLayer__c> cLayers = new List<QQNLayer__c>();
        
        QQNLayer__c cLayer = new QQNLayer__c();
        cLayer.NetworkId__c = cNN.id;
        cLayer.LayerId__c = 0;
        cLayer.LearningRate__c = 0.01;
        cLayer.IsOutput__c = true;
        cLayer.NeuronCount__c = 2;
        cLayers.add(cLayer);
        
        insert cLayers;
        
        System.debug(cNN.id + ': ' + cNN.Name);
        QQNTruncatedDQN__c cTdqn = new QQNTruncatedDQN__c();
        cTdqn.QTableRef__c = cNN.id;
        cTdqn.BatchSize__c = 64;
        cTdqn.Comment__c = 'Square test';
        cTdqn.DiscountFactor__c = 0.9;
        cTdqn.MseThreshold__c = 0.001;
        cTdqn.PendingBatches__c = 64;
        insert cTdqn;
        
        QQNBatchMSE__c objBatchMse = new QQNBatchMSE__c();
        objBatchMse.BatchNumber__c = 1;
        objBatchMse.MSE__c = 2;
        objBatchMse.TdqnId__c = cTdqn.id;
        insert objBatchMse;
        
        QQNAIDriver.callLoad(cTdqn.Id);
 		
 		Account objAcc = new Account();
 		objAcc.name = 'Test Account';
 		insert objAcc;
 		
 		Contact objContact = new Contact();
 		objContact.lastname = 'Testing';
 		objContact.AccountId = objAcc.id;
 		insert objContact;
 		
 		List<ps__Lead__c> lstPsLead = new List<ps__Lead__c>();
 		
 		List<RecordType> lstRecordType = [select Id ,DeveloperName,sobjecttype from 
 		                                  RecordType where DeveloperName = 'BaseRecType'];
 		
 		String strRecordType = lstRecordType.size() > 0 ? lstRecordType[0].Id : '';
 		
 		ps__Room__c objPsRoom = new ps__Room__c();
 		objPsRoom.Name = 'Test Room';
 		objPsRoom.ps__CapacityHaku__c = 2;
 		objPsRoom.ps__Capacity__c = 2;
 		insert objPsRoom;
 		
 		for(integer i=0;i<100;i++){
 			ps__Lead__c objPsLead = new ps__Lead__c();
 			objPsLead.Name = 'Test Record '+ i;
 			objPsLead.recordTypeId = strRecordType;
 			objPsLead.ps__Relcontact__c = objContact.Id;
 			objPsLead.ps__ReservedStatus__c = '確認中';
 			objPsLead.ps__ReservedDate__c = Date.today() - 1 ;
 			objPsLead.ps__EntryTime__c = Date.today() - 1 ;
 			objPsLead.ps__Departure__c = Date.today() ;
 			objPsLead.ps__StayPersons__c = 1;
 			objPsLead.ps__Rroom__c = objPsRoom.Id;
 			objPsLead.field4__c = '10:00';
 			objPsLead.field3__c = '4:00';
 			lstPsLead.add(objPsLead);
 		}
 		insert lstPsLead;
 		
 		
 		test.starttest();
 		Database.executeBatch(new QQNAILookupFieldBatch('ps__Lead__c','ps__Rroom__c'));
 		test.stoptest();
 		Database.executeBatch(new QQNAIEventLoaderBatch(100));
 		
 		for(QQNAIEvent__c event : [
    		select Time__c, Ps_LeadIndexRef__c, StateBefore__c, RoomsAssigned__c
    		from QQNAIEvent__c order by Time__c
        ]) {
        	System.debug(event);
        }
 	}
 	
    @isTest
    static void testTanhActivationFunction() {
        double[] values = new double[]{-5, -1, 0, 1, 5};
        QQNTanhActivationFunction phi = new QQNTanhActivationFunction();
        
        for(double value : values) {
            double th = Math.tanh(value);
            System.assertEquals(phi.evaluate(value), th);
            System.assertEquals(phi.tangent(value), 1 - th*th);
        }
    }
    
    @isTest
    static void testReLUActivationFunction() {
        double[] values = new double[]{-5, -1, 0, 1, 5};
        QQNReLUActivationFunction phi = new QQNReLUActivationFunction();
        
        for(double value : values) {
            System.assertEquals(phi.evaluate(value), value > 0 ? value : 0);
            System.assertEquals(phi.tangent(value), value > 0 ? 1 : 0);
        }
    }
    
    //@isTest
    static void testNeuron() {
        //  y = x - 0.5
        double classLimit = 0.5;
        double alpha = 0.1;
        QQNNeuralNetwork network = new QQNNeuralNetwork(null);
        QQNLayer layer = new QQNLayer(null, alpha, network);
        layer.initialize(1, 1);
        network.addLayer(layer, true);
        
        QQNNeuron neuron = layer.getNeuron(1);
        double[] errors = new double[2];
        double[] input = new double[2];
        double[] output;
        double expected;
        errors[0] = 0;
        input[0] = 1;
        for(integer i=0; i<15000; i++) {
            input[1] = Math.random();
            expected = input[1] > classLimit ? input[1] - classLimit : 0;
            output = network.evaluate(input);
            errors[1] = expected - output[1];
            if(Math.mod(i, 1000) == 0)
                System.debug('[' + i + ']: input = ' + input + ', output = ' + output +
                    ', expected = ' + expected + ', errors = ' + errors +
                    ', weights = ' + neuron.weights);
            network.doUpdate(errors);
        }
        
        System.debug('Final weights = ' + neuron.weights);
        for(integer i=0; i<100; i++) {
            input[1] = Math.random();
            output = network.evaluate(input);
            System.debug('[' + i + ']: input = ' + input + ', output = ' + output);
        }
        
        input[1] = 0.45;
        System.assert(network.evaluate(input)[1] <= 0.0);
        input[1] = 0.55;
        System.assert(network.evaluate(input)[1] > 0.0);
        input[1] = 0.5;
        System.assert(network.evaluate(input)[1] >= 0.0);
    }
    
    static QQNLayer__c createQQNLayer() {
    	QQNNeuralNetwork__c cNN = new QQNNeuralNetwork__c();
        cNN.InputCount__c = 2;
        cNN.LayerCount__c = 1;
        cNN.LearningRate__c = -1;
        insert cNN;
        
        List<QQNLayer__c> cLayers = new List<QQNLayer__c>();
        
        QQNLayer__c cLayer = new QQNLayer__c();
        cLayer.NetworkId__c = cNN.id;
        cLayer.LayerId__c = 0;
        cLayer.LearningRate__c = 0.01;
        cLayer.IsOutput__c = true;
        cLayer.NeuronCount__c = 2;
        cLayers.add(cLayer);
        
        insert cLayers;
        
        System.debug(cNN.id + ': ' + cNN.Name);
        QQNTruncatedDQN__c cTdqn = new QQNTruncatedDQN__c();
        cTdqn.QTableRef__c = cNN.id;
        cTdqn.BatchSize__c = 64;
        cTdqn.Comment__c = 'Square test';
        cTdqn.DiscountFactor__c = 0.9;
        cTdqn.MseThreshold__c = 0.001;
        cTdqn.PendingBatches__c = 64;
        insert cTdqn;
        return cLayers[0];
    }
    
    @isTest
    static void testNeuralNetwork() {
    	//  y = x1 ^ x2
    	double alpha = 0.1;
    	//double alpha = 1;
    	QQNNeuralNetwork network = new QQNNeuralNetwork(null);
    	QQNLayer__c objLayer = createQQNLayer();
        QQNLayer layer = new QQNLayer(objLayer, alpha, network);
        layer.initialize(2, 2);
        network.addLayer(layer, false);
        layer = new QQNLayer(objLayer, alpha, network);
        layer.initialize(2, 1);
        network.addLayer(layer, true);
        network.getLayer(0);
        network.getOutputCount();
        network.deepCopy();
        
        double[] errors = new double[2];
        double[] input = new double[3];
        double[] output;
        double expected;
        errors[0] = 0;
        input[0] = 1;
        
        for(integer i=0; i<5000; i++) {
            input[1] = Math.round(Math.random());
            input[2] = Math.round(Math.random());
            
            output = network.evaluate(input);
            expected = (Integer.valueOf(input[1]) ^ Integer.valueOf(input[2]));
            errors[1] = expected - output[1];
            
            if(i < 50 || Math.mod(i, 1000) == 0) {
                System.debug(weightsToString(network));
                System.debug('[' + i + ']: input = ' + input + ', output = ' + output + ', error = ' + errors);
            }
            
            network.doUpdate(errors);
        }
        
        System.debug('FINAL NETWORK\n' + network + weightsToString(network));
        for(integer i=0; i<20; i++) {
            input[1] = Math.round(Math.random());
            input[2] = Math.round(Math.random());
            output = network.evaluate(input);
            expected = Double.valueOf(Integer.valueOf(input[1]) ^ Integer.valueOf(input[2]));
            System.debug('[' + i + ']: input = ' + input + ', output = ' + output);
            // System.assert(approximatelyEquals(expected, output[1], Double.valueOf(0.0001)));
        }
    }
    
    class DummyHandler1 implements QQNTrainingBatchCreator, QQNAIOnTrainHandler {
        private double input() {
            return Math.round(Math.random() * 10) / 5.0 - 1;
        }
        
        private integer eval(double[] input) {
            return input[0] + input[1] > 0 ? 1 : 0;
        }
        
        private integer reward(double[] input, integer action) {
            return Math.round(action == 0 ? input[0] + input[1] : 20 - input[0] + input[1]);
        }
        
        public Id createTDQN() {
            QQNNeuralNetwork__c cNN = new QQNNeuralNetwork__c();
            cNN.InputCount__c = 2;
            cNN.LayerCount__c = 1;
            cNN.LearningRate__c = -1;
            insert cNN;
            
            List<QQNLayer__c> cLayers = new List<QQNLayer__c>();
            
            QQNLayer__c cLayer = new QQNLayer__c();
            cLayer.NetworkId__c = cNN.id;
            cLayer.LayerId__c = 0;
            cLayer.LearningRate__c = 0.01;
            cLayer.IsOutput__c = true;
            cLayer.NeuronCount__c = 3;
            cLayers.add(cLayer);
            
            insert cLayers;
            
            System.debug(cNN.id + ': ' + cNN.Name);
            QQNTruncatedDQN__c cTdqn = new QQNTruncatedDQN__c();
            cTdqn.QTableRef__c = cNN.id;
            cTdqn.BatchSize__c = 64;
            cTdqn.Comment__c = 'Square test';
            cTdqn.DiscountFactor__c = 0.9;
            cTdqn.MseThreshold__c = 0.001;
            cTdqn.PendingBatches__c = 64;
            insert cTdqn;
            
            return cTdqn.id;
        }
        
        public List<QQNQLearningTuple> prepareBatch(QQNAIDriver driver) {
    		integer batchSize = driver.getBatchSize();
    		List<QQNQLearningTuple> trainingBatch = new List<QQNQLearningTuple>();
    		double[] state;
    		integer action;
    		integer reward;
            double[] endstate = new double[]{0, 0};
    		for(integer i=0; i<batchSize; i++) {
    			state = new double[] {input(), input()};
    			action = eval(state);
    			reward = 1;
    			
                if(action==0)
                	endState = new double[] {state[0] - 0.2, state[1] - 0.2};
                else
                	endState = new double[] {state[0] + 0.2, state[1] + 0.2};
                	
                for(integer j=0; j<2; j++) {
                	if(endState[j] < -1)
                		endState[j] = 1;
                	else if(endState[j] > 1)
                		endState[j] = -1;
                }
                
    			QQNQLearningTuple tuple = new QQNQLearningTuple(state, action, reward, endState);
    			trainingBatch.add(tuple);
    		}
    		
            system.debug('trainingBatch: ' + trainingBatch + weightsToString(driver.neuralNetwork));
    		return trainingBatch;
    	}
        
        public void trainingComplete(QQNAIDriver driver) {
    		QQNTruncatedDQN tdqn = driver.getTDQN();
    		double[] input = new double[2];
    		integer output;
    		string row;
    		
    		for(double i=-1; i<=1; i+=0.2) {
    			input[0] = i;
    			row = '';
    			for(double j=-1; j<=1; j+=0.2) {
	            	input[1] = j;
	            	output = tdqn.evaluate(input);
	            	row = row + output + '\t';
    			}
    			System.debug(row);
    		}
    		
    		for(integer i=0; i<20; i++) {
	            input[0] = input();
	            input[1] = input();
	            output = tdqn.evaluate(input);
                System.debug('input=' + input + ', expected=' + eval(input) + ', observed=' + output);
	           // System.assertEquals(eval(input), output);
	        }
    	}
    }
    
    @isTest
    static void testTDQN() {
    	DummyHandler1 handler = new DummyHandler1();
    	
        Id tdqnId = handler.createTDQN();
        QQNAIDriver driver = new QQNAIDriver(tdqnId);
        driver.setOnLoadHandler(new QQNTrainingTdqnLoadHandler());
        
        driver.setOnTrainHandler(handler);
        driver.setTrainingBatchCreator(handler);
        
        Test.startTest();
        QQNTruncatedDQN tdqn = driver.load();
        QQNNeuralNetwork network = driver.neuralNetwork;
        Double alpha = 0.1;
        QQNLayer layer = new QQNLayer([select id from QQNLayer__c][0], alpha, network);
        layer.initialize(2, 2);
        network.addLayer(layer, false);
        layer = new QQNLayer([select id, NetworkId__c, IsOutput__c,NeuronCount__c,LayerId__c,LearningRate__c from QQNLayer__c][0], alpha, network);
        layer.initialize(2, 2);
        network.addLayer(layer, true);
        driver.trainTDQN();
        Test.stopTest();
    }
    
    /*@isTest
    static void testTimeline() {
    	Test.startTest();
    	Database.executeBatch(new AILookupFieldBatch('ps__Lead__c', 'ps__Rroom__c'));
    	Database.executeBatch(new AIEventLoaderBatch());
    	Test.stopTest();
    }*/
    
    /*@isTest
    static void testRoomReservationAI() {
    	RoomReservationAI.createAI();
    	
        Test.startTest();
        RoomReservationAI.prepareAILookup();
        RoomReservationAI.prepareTimeline(1000);
        Test.stopTest();
    }*/
    
    static boolean approximatelyEquals(double a, double b, double precision) {
        return Math.abs(a-b) < precision;
    }
    
    static string weightsToString(QQNNeuralNetwork network) {
        QQNLayer layer;
        QQNNeuron neuron;
        string weights = '';
        for (Integer k = 0; (layer = network.getLayer(k)) != null; k++) {
            for(Integer j = 1; (neuron = layer.getNeuron(j)) != null; j++) {
                weights += ('\nneuron[' + k + '][' + j + ']: ' + neuron.weights);
                neuron.getWeight(0);
                neuron.getWeights();
                neuron.getLastOutput();
                if(layer.getSFObject() != null) {
                	QQNNeuron__c objNeuron = neuron.getSFObject();
	                neuron.setSFObject(objNeuron);
	                new QQNNeuron(objNeuron, layer);
                }
                neuron.deepCopy(null);
            }
        }
        
        return weights;
    }
    
    
}