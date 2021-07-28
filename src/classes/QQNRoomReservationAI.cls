public class QQNRoomReservationAI {
	public static void prepareAILookup() {
		//	ps__Rroom__c, ps__refTypeOfRooms__c, ps__ReservedType__c, ps__Field367__c, ps__Segment__c
    	Database.executebatch(new QQNAILookupFieldBatch('ps__Lead__c', 'ps__Rroom__c'));
    	Database.executebatch(new QQNAILookupFieldBatch('ps__Lead__c', 'ps__refTypeOfRooms__c'));
    	Database.executebatch(new QQNAILookupFieldBatch('ps__Lead__c', 'ps__ReservedType__c'));
    	Database.executebatch(new QQNAILookupFieldBatch('ps__Lead__c', 'ps__Field367__c'));
    	Database.executebatch(new QQNAILookupFieldBatch('ps__Lead__c', 'ps__Segment__c'));
    }
    
    public static void prepareTimeline(integer fetchLimit) {
    	Database.executebatch(new QQNAIEventLoaderBatch(fetchLimit));
    }
    
    public static Id createAI() {
    	QQNNeuralNetwork__c cNN = new QQNNeuralNetwork__c();
        cNN.InputCount__c = 135;
        cNN.LayerCount__c = 1;
        cNN.LearningRate__c = 0.0001;
        insert cNN;
        
        List<QQNLayer__c> cLayers = new List<QQNLayer__c>();
        
        QQNLayer__c cLayer = new QQNLayer__c();
        /*cLayer.NetworkId__c = cNN.id;
        cLayer.LayerId__c = 0;
        cLayer.LearningRate__c = -1;
        cLayer.IsOutput__c = false;
        cLayer.NeuronCount__c = 135;
        cLayers.add(cLayer);
        
        cLayer = new Layer__c();*/
        cLayer.NetworkId__c = cNN.id;
        cLayer.LayerId__c = 0;
        cLayer.LearningRate__c = -1;
        cLayer.IsOutput__c = true;
        cLayer.NeuronCount__c = 131;
        cLayers.add(cLayer);
        
        insert cLayers;
        
        System.debug(cNN.id + ': ' + cNN.Name);
        
        String alphas = '{global: ' + cNN.LearningRate__c;
        for(QQNLayer__c l : cLayers) {
        	alphas += ', layer[' + l.LayerId__c + ']: ' + l.LearningRate__c; 
        }
        alphas += '}';
        
        QQNTruncatedDQN__c cTdqn = new QQNTruncatedDQN__c();
        cTdqn.QTableRef__c = cNN.id;
        cTdqn.BatchSize__c = 64;
        cTdqn.DiscountFactor__c = 0.9;
        cTdqn.MseThreshold__c = 0;
        cTdqn.PendingBatches__c = 2;
        cTdqn.IsActive__c = true;
        cTdqn.Comment__c = '[11] One layer NN (alpha=' + alphas + ', gamma=' + cTdqn.DiscountFactor__c + '). Re-assign penalty!';
        insert cTdqn;
        
        System.debug(cTdqn.id + ' - ' + cTdqn.Comment__c);
        
        return cTdqn.id;
    }
    
    public static void train(Id tdqnId) {
    	QQNAIDriver driver = new QQNAIDriver(tdqnId);
    	driver.setOnLoadHandler(new QQNTrainingTdqnLoadHandler());
    	driver.setOnTrainHandler(new TestHandler());
        driver.setTrainingBatchCreator(new QQNEventTrainingBatchCreator());
        driver.load();
    }
    
    public static void train() {
    	train(getActiveTDQNId());
    }
    
    public static void trainFromXMLConfig() {
    	QQNAIConfigurationCreator config = new QQNAIConfigurationCreator();
    	Id tdqnId;
    	
    	config.load();
    	if(config.isNew()) {
    		tdqnId = config.createRecords();
    	} else {
    		tdqnId = config.updateRecords();
    	}
    	
    	if(tdqnId != null)
    		train(tdqnId);
    	else
    		System.debug('ERROR: Something may be wrong with the XML configuration file.');
    }
    
    public static void printStats() {
    	printStats(getActiveTDQNId());
    }
    
    public static void printStats(Id tdqnId) {
    	List<QQNTruncatedDQN__c> tdqnList = [
    		SELECT id, Name, Comment__c, BatchSize__c, DiscountFactor__c, MseThreshold__c, PendingBatches__c, QTableRef__c
    		FROM QQNTruncatedDQN__c WHERE id = :tdqnId
    	];
    	
    	for(QQNTruncatedDQN__c t : tdqnList) {
	    	System.debug('TDQN Id,' + t.id);
	    	System.debug('Name,' + t.Name);
	    	System.debug('Comment,' + t.Comment__c);
	    	System.debug('Gamma,' + t.DiscountFactor__c);
	    	System.debug('MSE Threshold,' + t.MseThreshold__c);
	    	System.debug('Pending Batches,' + t.PendingBatches__c);
	    	System.debug('QTableRef,' + t.QTableRef__c);
    	}
    	
    	List<QQNBatchMSE__c> mseList = [
    		SELECT BatchNumber__c, MSE__c, CompletionTime__c
			FROM QQNBatchMSE__c
			WHERE TdqnId__c = :tdqnId
			ORDER BY BatchNumber__c ASC
		];
    	System.debug('\nBatchNumber,MSE');
    	for(QQNBatchMSE__c m : mseList) {
    		System.debug(m.BatchNumber__c+ ',' + m.MSE__c+ ',,' + m.CompletionTime__c);
    	}
    }
    
    public static void emailStats() {
    	emailStats(getActiveTDQNId(), 0);
    }
    
    public static void emailStats(integer fromBatch) {
    	emailStats(getActiveTDQNId(), fromBatch);
    }
    
    public static void emailStats(Id tdqnId, integer fromBatch) {
    	sendEmail('[TDQN] MSE for QQNTruncatedDQN ' + tdqnId, 'PFA stats for QQNTruncatedDQN ' + tdqnId, buildStatsString(tdqnId, fromBatch));
    }
    
    private static String buildStatsString(Id tdqnId, integer fromBatch) {
    	String strStats = '';
    	
    	List<QQNTruncatedDQN__c> tdqnList = [
    		SELECT id, Name, Comment__c, BatchSize__c, DiscountFactor__c, MseThreshold__c, PendingBatches__c, QTableRef__c
    		FROM QQNTruncatedDQN__c WHERE id = :tdqnId
    	];
    	
    	for(QQNTruncatedDQN__c t : tdqnList) {
	    	strStats += 'TDQN Id,' + t.id;
	    	strStats += '\nName,' + t.Name;
	    	strStats += '\nComment,' + t.Comment__c;
	    	strStats += '\nGamma,' + t.DiscountFactor__c;
	    	strStats += '\nMSE Threshold,' + t.MseThreshold__c;
	    	strStats += '\nPending Batches,' + t.PendingBatches__c;
	    	strStats += '\nQTableRef,' + t.QTableRef__c;
    	}
    	
    	List<QQNBatchMSE__c> mseList = [
    		SELECT BatchNumber__c, MSE__c, CompletionTime__c
			FROM QQNBatchMSE__c
			WHERE TdqnId__c = :tdqnId AND BatchNumber__c >= :fromBatch
			ORDER BY BatchNumber__c ASC
		];
    	strStats += '\n\nBatchNumber,MSE,,Completion time';
    	for(QQNBatchMSE__c m : mseList) {
    		strStats += '\n' + m.BatchNumber__c+ ',' + m.MSE__c+ ',,' + m.CompletionTime__c;
    	}
    	
    	return strStats;
    }
    
    public static Id getActiveTDQNId() {
    	List<QQNTruncatedDQN__c> tdqnList = [
    		SELECT id FROM QQNTruncatedDQN__c WHERE IsActive__c = true ORDER BY Name DESC
    	];
    	
    	return (tdqnList != null && tdqnList.size() > 0) ? tdqnList[0].id : null;
    }
    
    public class TestHandler implements QQNTdqnLoadHandler, QQNAIOnTrainHandler {
		public void tdqnLoaded(QQNAIDriver driver) {
			test(driver);
		}
		// 訓練終了
		public void trainingComplete(QQNAIDriver driver) {
			QQNRoomTrainBatch.nextExcuteBatch(new List<String>{'Delete'});
		}
		
		private String test(QQNAIDriver driver) {
			QQNEventTrainingBatchCreator bc = new QQNEventTrainingBatchCreator();
			List<QQNQLearningTuple> batch = bc.prepareBatch(driver);
			QQNTruncatedDQN tdqn = driver.getTdqn();
			String status = 'Expected, Observed, Assigned room state'; 
			
			for(QQNQLearningTuple tuple : batch) {
				integer action = tdqn.evaluate(tuple.state);
				String line = tuple.action + ', ' + action + ', ' + tuple.state[4 + action];
				System.debug(line);
				status += '\n' + line;
			}
			
			return status;
		}
	}
	
	public static void test() {
		test(getActiveTDQNId());
	}
	
	public static void test(Id tdqnId) {
    	QQNAIDriver driver = new QQNAIDriver(tdqnId);
    	driver.setOnLoadHandler(new TestHandler());
    	driver.load();
    }
    
    /*public static void realTest() {
    	fullTest(getActiveTDQNId());
    }
    
    public static void realTest(Id tdqnId) {
    	AIDriver driver = new AIDriver(tdqnId);
    	driver.setOnLoadHandler(new RoomAssignmentTest());
    	driver.load();
    }*/
    
    public static void fullTest() {
    	fullTest(getActiveTDQNId());
    }
    
    public static void fullTest(Id tdqnId) {
    	QQNAIDriver driver = new QQNAIDriver(tdqnId);
    	driver.setOnLoadHandler(new QQNEvalTrainingDataBatch());
    	driver.load();
    }
    
    public static void sendEmail(String subject, String emailBody, String csvAttachment) {
    	Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
		message.setSubject(subject);
		message.setToAddresses(new String[] {'zhouyu@e-cloudsoft.com'});
		message.setPlainTextBody(emailBody);
		
		if(csvAttachment != null) {
	    	Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
			blob csvBlob = Blob.valueOf(csvAttachment);
			csvAttc.setFileName('results.csv');
			csvAttc.setBody(csvBlob);
			message.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
		}
		// テストクラスの場合、実施しない
		if(!Test.isRunningTest()) {
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { message });
		}
    }
    public static void checkLeadRoom(List<Lead__c> leads){
		// データチェック
		if (leads.isEmpty()) return ;
		// 2019/02/15 AI功能改修 by zy BEGIN
		List<GroupLead> groupLeads = getCanAssignRoom(leads);
		// 神経単位チェック
		/*
		// 2019/02/15 AI功能改修 by zy END
		Id tdqnId = QQNRoomReservationAI.getActiveTDQNId();
		if (tdqnId == null) return;
		// 部屋自動割当運転中心
		QQNAIDriver driver = new QQNAIDriver(tdqnId);
    	driver.setOnLoadHandler(new QQNTrainingTdqnLoadHandler());
    	driver.setOnTrainHandler(new QQNRoomReservationAI.TestHandler());
        driver.setTrainingBatchCreator(new QQNEventTrainingBatchCreator());
	    QQNTruncatedDQN tdqn = driver.load();
		// 2019/02/15 AI功能改修 by zy BEGIN
		*/
		QQNTruncatedDQN tdqn = QQNAIDriver.getTqdn();
		// 2019/02/15 AI功能改修 by zy END
	    // 訓練チェック
	    if (tdqn == null) return;
	    try {
		    // 参照ツール
			QQNAILookup aiLookup = new QQNAILookup();
			// 取得全て参照内容
			aiLookup.loadAll();
			// 部屋リスト作成
			Map<string, QQNAILookup.LookupValue> roomMap = aiLookup.getFieldValueMap('ps__Lead__c', 'ps__Rroom__c');
			//	Room occupancy status (0: available, 1: occupied)
			// QQNAIConfigurationCreator
	    	//integer zero = '0'.charAt(0);
			integer nRooms = roomMap.size();
			string[] roomReverseList = new string[nRooms];
			// 2019/02/15 AI功能改修 by zy BEGIN
			List<double> roomState = new List<double>();
			List<Integer> nActions = new List<Integer>();
			// List<Integer> roomState = new List<Integer>();
			for(integer i=0; i<QQNEventTrainingBatchCreator.N_FIELDS; i++) {
				roomState.add(0.0);
			}
			// 2019/02/15 AI功能改修 by zy END
			for(string roomSFId : roomMap.keySet()) {
				QQNAILookup.LookupValue value = roomMap.get(roomSFId);
				roomReverseList[value.intValue] = roomSFId;
				// 2019/02/15 AI功能改修 by zy BEGIN
				roomState.add(-1.0);
				// 2019/02/15 AI功能改修 by zy END
			}
			// 2019/02/15 AI功能改修 by zy BEGIN
			roomState.add(1.0);
			for (GroupLead groupLead : groupLeads) {
				if (!groupLead.roomSet.isEmpty()) {
					groupLead.roomState = roomState;
					for (String roomId : groupLead.roomSet) {
						QQNAILookup.LookupValue value = roomMap.get(roomId);
						if (value != null) {
							nActions.add(value.intValue);
							groupLead.roomState[value.intValue] = 0.0;
						}
					}
				}
			}
			//for (integer i = 0 ; i < nRooms; i++) roomState.add(zero);
			//String roomBefore = string.fromCharArray(roomState);
			tdqn.initNeuron(nActions);
			Map<String,String> groupLeadRoomMap = new Map<String,String>();
			Map<String,List<Integer>> keyAssignGroup = new Map<String,List<Integer>>();
			for (GroupLead groupLead : groupLeads) {
				if (groupLead.roomState != null) {
					List<Double> pRoomState = groupLead.roomState;
					String assignKey = '';
		    		QQNAILookup.LookupValue roomTypeLook = aiLookup.translate('ps__Lead__c', 'ps__refTypeOfRooms__c', groupLead.typeId);
		    		// 匹配值处理
		    		if (roomTypeLook == null) continue;
					pRoomState[0] = roomTypeLook.normalizedValue;
					assignKey += roomTypeLook.normalizedValue + '_';
					roomTypeLook = aiLookup.translate('ps__Lead__c', 'ps__ReservedType__c', groupLead.reserType);
		        	if (roomTypeLook != null) pRoomState[1] = roomTypeLook.normalizedValue;
		        	assignKey += roomTypeLook.normalizedValue + '_';
		        	roomTypeLook = aiLookup.translate('ps__Lead__c', 'ps__Field367__c', groupLead.field367);
		        	if (roomTypeLook != null) pRoomState[2] = roomTypeLook.normalizedValue;
		        	assignKey += roomTypeLook.normalizedValue + '_';
		        	roomTypeLook = aiLookup.translate('ps__Lead__c', 'ps__Segment__c', groupLead.segment);
		        	if (roomTypeLook != null) pRoomState[3] = roomTypeLook.normalizedValue;
		        	assignKey += roomTypeLook.normalizedValue;
		        	if (!keyAssignGroup.containsKey(assignKey)) {
		        		List<integer> assignedRoomLookupIds = tdqn.evaluateLst(pRoomState);
		        		keyAssignGroup.put(assignKey,assignedRoomLookupIds);
		        	}
		        	List<Integer> assigns = keyAssignGroup.get(assignKey);
		        	if (assigns.isEmpty()) continue;
		        	// 該当部屋タイプ下の部屋チェック
		        	List<Integer> sameTypeRooms = new List<Integer>();
		        	for (Integer roomIdx : assigns) {
		        		if (roomIdx < roomReverseList.size()){
		        			String roomId = roomReverseList[roomIdx];
		        			if (CommUtils.isBlank(roomId) || !groupLead.roomSet.contains(roomId)) {
		        				continue;
		        			}
		        			sameTypeRooms.add(roomIdx);
		        		}
		        	}
		        	if (sameTypeRooms.isEmpty()) continue;
		        	assigns = sameTypeRooms;
		        	Integer assignedRoomLookupId = assigns[0];
					// 2019/02/15 AI功能改修 by zy END
					if (assignedRoomLookupId < roomReverseList.size()){
						String roomId = roomReverseList[assignedRoomLookupId];
						// 2019/03/29 JINYABUG-1552 bug fix by zy BEGIN
						if (CommUtils.isBlank(roomId) || !groupLead.roomSet.contains(roomId)) {
							assigns.remove(0);
							continue;
						}
						// 2019/03/29 JINYABUG-1552 bug fix by zy END
						groupLeadRoomMap.put(groupLead.groupKey,roomId);
						assigns.remove(0);
						keyAssignGroup.put(assignKey,assigns);
					}
				}
			}
			for (lead__c lead : leads) {
				String mainKey = CommUtils.nullToBlank(lead.LeadIndexRef__c) 
							+ '_' +	CommUtils.nullToBlank(lead.LeadIndexSubId__c) 
							+ '_' +	CommUtils.nullToZero(lead.RoomGroupNo__c);
				if (groupLeadRoomMap.containsKey(mainKey)) lead.Rroom__c = groupLeadRoomMap.get(mainKey);
				
			}
		} catch (exception e){
			system.debug(logginglevel.info,'e:::' + e.getStackTraceString());
		}
		/*
		// 部屋自動割当処理
		for(ps__Lead__c lead : leads) {
    		List<double> state = new List<double>();
    		QQNAILookup.LookupValue roomTypeLook = aiLookup.translate('ps__Lead__c', 'ps__refTypeOfRooms__c', lead.ps__refTypeOfRooms__c);
    		// 匹配值处理
    		if (roomTypeLook == null) continue;
			state.add(roomTypeLook.normalizedValue);
			roomTypeLook = aiLookup.translate('ps__Lead__c', 'ps__ReservedType__c', lead.ps__ReservedType__c);
        	// 2019/02/15 AI功能改修 by zy BEGIN
        	if (roomTypeLook != null) roomState.add(roomTypeLook.normalizedValue);
        	else roomState.add(0);
        	roomTypeLook = aiLookup.translate('ps__Lead__c', 'ps__Field367__c', lead.ps__Field367__c);
        	if (roomTypeLook != null) roomState.add(roomTypeLook.normalizedValue);
        	else roomState.add(0);
        	roomTypeLook = aiLookup.translate('ps__Lead__c', 'ps__Segment__c', lead.ps__Segment__c);
        	if (roomTypeLook != null) roomState.add(roomTypeLook.normalizedValue);
        	else roomState.add(0);
        	
        	//QQNEventTrainingBatchCreator.roomStateToArray(roomBefore, state);
			
			integer assignedRoomLookupId = tdqn.evaluate(roomState);
			// 2019/02/15 AI功能改修 by zy END
			if (assignedRoomLookupId < roomReverseList.size()){
				system.debug(logginglevel.info,'roomid:::' + roomReverseList[assignedRoomLookupId]);
				lead.ps__Rroom__c = roomReverseList[assignedRoomLookupId];
			}
		}*/
	}
	// 自動割り振りできる部屋リスト情報を取得する
    private static List<GroupLead> getCanAssignRoom(List<Lead__c> leads){
        Map<String,GroupLead> groupLeadMap = new Map<String,GroupLead>();
        Set<String> typeSet = new Set<String>();
        Set<Id> allRoomSet = new Set<Id>();
        Date startDt;Date endDt;
        // 予約グループ化
        for (Lead__c lead : leads) {
        	if (lead.entrytime__c == null || lead.Departure__c == null) continue;
        	String mainKey = CommUtils.nullToBlank(lead.LeadIndexRef__c) 
						+ '_' +	CommUtils.nullToBlank(lead.LeadIndexSubId__c) 
						+ '_' +	CommUtils.nullToZero(lead.RoomGroupNo__c);
			if (!groupLeadMap.containsKey(mainKey)) groupLeadMap.put(mainKey,new GroupLead(mainKey));
			groupLeadMap.get(mainKey).addLead(lead);
			typeSet.add(lead.ps__refTypeOfRooms__c);
			if (startDt == null || startDt > lead.entrytime__c.date()) startDt = lead.entrytime__c.date();
			if (endDt == null || endDt < lead.Departure__c.date()) endDt = lead.Departure__c.date();
        }
        // 部屋タイプ対応関係
        Map<String,Set<String>> roomTypeMap = new Map<String,Set<String>>();
        Map<String,String> roomToTypeMap = new Map<String,String>();
		for (ps__room__c room : [select id,TypeRoomRef__c from ps__room__c where UseOfRoom__c = :CommConst.ROOM_UseOfType_Guest and TypeRoomRef__c = :typeSet]) {
			if (!roomTypeMap.containsKey(room.TypeRoomRef__c)) roomTypeMap.put(room.TypeRoomRef__c,new Set<String>());
			roomTypeMap.get(room.TypeRoomRef__c).add(room.id);
			roomToTypeMap.put(room.id,room.ps__TypeRoomRef__c);
			allRoomSet.add(room.id);
		}
		List<GroupLead> results = new List<GroupLead>();
        for (GroupLead groupLead : groupLeadMap.values()) {
        	groupLead.roomSet = roomTypeMap.get(groupLead.typeId);
        	results.add(groupLead);
        }
        groupLeadMap.clear();
        if (results.isEmpty()) return results;
        // 既に予約データに入る場合、該当部屋は選択対象外になる
        for (lead__c lead :  [
            select Rroom__c,EntryTime__c,Departure__c,field4__c,field3__c,refTypeOfRooms__c,LeadIndexRef__c,
            				LeadIndexSubId__c,RoomGroupNo__c,ReservedType__c,Field367__c,Segment__c    
            		from Lead__c
		            where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
		                And DAY_ONLY(convertTimezone(EntryTime__c)) >= :startDt
		                And DAY_ONLY(convertTimezone(EntryTime__c)) <= :endDt
		                And Rroom__c in :allRoomSet]) {
		    String mainKey = CommUtils.nullToBlank(lead.LeadIndexRef__c) 
						+ '_' +	CommUtils.nullToBlank(lead.LeadIndexSubId__c) 
						+ '_' +	CommUtils.nullToZero(lead.RoomGroupNo__c);
			if (!groupLeadMap.containsKey(mainKey)) groupLeadMap.put(mainKey,new GroupLead());
			groupLeadMap.get(mainKey).addLead(lead);
        }
        Map<String,List<GroupLead>> otherGroupLead = new Map<String,List<GroupLead>>();
        for (GroupLead groupLead : groupLeadMap.values()) {
        	if (!otherGroupLead.containsKey(groupLead.typeId)) otherGroupLead.put(groupLead.typeId,new List<GroupLead>());
        	otherGroupLead.get(groupLead.typeId).add(groupLead);
        }
        RoomStatusManager roomStatusManger = new RoomStatusManager();
    	// 指定期間ないの故障部屋リストを取得する
    	List<RoomsStatus__c> roomsStatus = roomStatusManger.queryBadRoomList(startDt,endDt ,allRoomSet);
    	// 指定部屋の故障ありの日付情報を格納する
    	Map<id,List<RoomsStatus__c>> badRoomStatusMap = new Map<id,List<RoomsStatus__c>>();
    	//Map<Id, String> roomNameMap = new map<Id, String>();
    	for(RoomsStatus__c roomStatus : roomsStatus){
    		String typeId = roomToTypeMap.get(roomStatus.RoomRef__c);
    		if(!badRoomStatusMap.containsKey(typeId)){
    			badRoomStatusMap.put(typeId,new List<RoomsStatus__c>());
    		}
    		badRoomStatusMap.get(typeId).add(roomStatus);
    	}
        for (GroupLead groupLead : results) {
		    if (otherGroupLead.containsKey(groupLead.typeId)) groupLead.processGroup(otherGroupLead.get(groupLead.typeId));
		    if (badRoomStatusMap.containsKey(groupLead.typeId)) groupLead.processGroup(badRoomStatusMap.get(groupLead.typeId));
		}
        return results;
    }
    public class GroupLead{
		List<Lead__c> leads;
		Set<String> roomSet;
		datetime begnDt;
		// 2019/07/15 タイムテーブルの時間表示ずれる問題調査、予約コピーの影響正常処理bug fixed by zy BEGIN
		public datetime endDt;
		// 2019/07/15 タイムテーブルの時間表示ずれる問題調査、予約コピーの影響正常処理bug fixed by zy END
		String reserType;
		String field367;
		String segment;
		String typeId;
		String leadIndex;
		String roomId;
		// 部屋自動割当用
		List<double> roomState;
		// グールプ
		String groupKey;
		public GroupLead(){
			leads = new List<Lead__c>();
			roomSet = new Set<String>();
		}
		public GroupLead(String key) {
			groupKey = key;
			leads = new List<Lead__c>();
			roomSet = new Set<String>();
		}
		public void addLead(Lead__c lead){
			Datetime beg = Commutils.convertDatetime(lead.entrytime__c.date(),lead.field4__c);
			Datetime endTm = Commutils.convertDatetime(lead.Departure__c.date(),lead.field3__c);
			if (begnDt == null || begnDt > beg) begnDt = beg;
			if (endDt == null || endDt < endTm) endDt = endTm;
			if (CommUtils.isBlank(reserType) && !CommUtils.isBlank(lead.ps__ReservedType__c)) reserType = lead.ps__ReservedType__c;
			if (CommUtils.isBlank(field367) && !CommUtils.isBlank(lead.ps__Field367__c)) field367 = lead.ps__Field367__c;
			if (CommUtils.isBlank(segment) && !CommUtils.isBlank(lead.ps__Segment__c)) segment = lead.ps__Segment__c;
			if (CommUtils.isBlank(typeId) && !CommUtils.isBlank(lead.ps__refTypeOfRooms__c)) typeId = lead.ps__refTypeOfRooms__c;
			if (CommUtils.isBlank(leadIndex) && !CommUtils.isBlank(lead.LeadIndexRef__c)) leadIndex = lead.LeadIndexRef__c;
			if (CommUtils.isBlank(roomId) && !CommUtils.isBlank(lead.Rroom__c)) roomId = lead.Rroom__c;
			leads.add(lead);
		}
		public void processGroup(List<GroupLead> groups){
			for (GroupLead lead : groups) {
				//　グループの予約チェック
				// 2019/03/28 JINYABUG-1552 bug fix 同じ予約インデックス　by zy BEGIN
				if (!CommUtils.isBlank(lead.roomId) && roomSet.contains(lead.roomId)) {// && leadIndex != lead.leadIndex
				// 2019/03/28 JINYABUG-1552 bug fix 同じ予約インデックス　by zy END	
					if (begnDt >= lead.endDt || endDt <= lead.begnDt) continue;
    				else roomSet.remove(lead.roomId);
				}
			}
		}
		public void processGroup(List<RoomsStatus__c> roomStatus){
			for (RoomsStatus__c rs : roomStatus) {
				//　グループの予約チェック
				if (!CommUtils.isBlank(rs.RoomRef__c) && roomSet.contains(rs.RoomRef__c)) {
					Datetime badBeginTm = CommUtils.convertDatetime(rs.StatusBeginDate__c,rs.BeginTime__c);
           		 	Datetime badEndTm = CommUtils.convertDatetime(rs.StatusEndDate__c,rs.OverTime__c);
					if (begnDt >= badEndTm || endDt <= badBeginTm) continue;
    				else roomSet.remove(rs.RoomRef__c);
				}
			}
		}
	}
}