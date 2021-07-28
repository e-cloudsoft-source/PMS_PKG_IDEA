public class QQNEventTrainingBatchCreator implements QQNTrainingBatchCreator {
	public static final integer N_FIELDS = 4;
	
	private integer maxEvents;
	private QQNAILookup aiLookup;
	
	/*private class EventLeadIndex {
		public AIEvent__c event;
		public ps__LeadIndex__c leadIndex;
		
		public EventLeadIndex(AIEvent__c event) {
			this.event = event;
		}
		
		public ps__Lead__c pickLeadRecord() {
			ps__Lead__c leadRecord = null;
			
			if(leadIndex != null) {
				integer nRec = leadIndex.ps__LeadIndexRef__r.size();
				if(nRec > 1) {
					integer leadPos = Math.floor(Math.random() * nRec).intValue();
					leadRecord = leadIndex.ps__LeadIndexRef__r[leadPos];
				} else {
					leadRecord = leadIndex.ps__LeadIndexRef__r[0];
				}
			}
			
			return leadRecord;
		}
	}*/
	// 訓練対象
	private class EventLead {
		// 訓練权重
		public QQNAIEvent__c event;
		// 予約データ
		public ps__Lead__c lead;
		
		public EventLead(QQNAIEvent__c event) {
			this.event = event;
		}
	}
	
	public QQNEventTrainingBatchCreator() {
		aiLookup = new QQNAILookup();
		aiLookup.loadAll();
		
		maxEvents = -1;
		getMaxEvents();
	}
	
	public List<QQNQLearningTuple> prepareBatch(QQNAIDriver driver) {
		integer batchSize = driver.getBatchSize();
		List<QQNQLearningTuple> trainingBatch = new List<QQNQLearningTuple>();
		// 随机抽取予約データ
        List<EventLead> eventLeadRecords = fetchRandomRecords(batchSize);
        // 訓練
        List<double> state;
		integer action;
		integer reward;
        List<double> endstate;
        for(EventLead eli : eventLeadRecords) {
        	state = new List<double>();
        	//	TODO Translate remaining field values through AILookup
        	//	ps__refTypeOfRooms__c, ps__ReservedType__c, ps__Field367__c, ps__Segment__c
        	state.add(aiLookup.translate('ps__Lead__c', 'ps__refTypeOfRooms__c', eli.lead.ps__refTypeOfRooms__c).normalizedValue);
        	state.add(aiLookup.translate('ps__Lead__c', 'ps__ReservedType__c', eli.lead.ps__ReservedType__c).normalizedValue);
        	state.add(aiLookup.translate('ps__Lead__c', 'ps__Field367__c', eli.lead.ps__Field367__c).normalizedValue);
        	state.add(aiLookup.translate('ps__Lead__c', 'ps__Segment__c', eli.lead.ps__Segment__c).normalizedValue);
        	roomStateToArray(eli.event.StateBefore__c, state);
        	action = aiLookup.translate('ps__Lead__c', 'ps__Rroom__c', eli.lead.ps__Rroom__c).intValue;
        	//reward = 1;
			reward = state[N_FIELDS + action] <= 0 ? 1 : -1;
        	endstate = new List<double>(state);
        	endstate[N_FIELDS + action] = 1.0;
        	
        	trainingBatch.add(new QQNQLearningTuple(state, action, reward, endState));
        }
        
        return trainingBatch;
	}
	// 随机抽出预约数据
	private List<EventLead> fetchRandomRecords(integer batchSize) {
		Set<integer> eventIds = new Set<integer>();
        integer nEvents = getMaxEvents();
        if (nEvents == 0) eventIds.add(nEvents);
        else  {
	        //	Pick random record IDs
	        while(eventIds.size() < batchSize) {
	        	eventIds.add(Math.round(Math.random() * nEvents));
	        }
        }
        //	Fetch AIEvent__c records corresponding to the randomly picked IDs
        List<QQNAIEvent__c> eventRecords = [
        	select id, EventId__c, IsEntry__c, Ps_LeadIndexRef__c, RoomsAssigned__c, StateBefore__c, Time__c
        	from QQNAIEvent__c
        	where EventId__c in :eventIds
        ];
        
        Map<string, EventLead> leadIds = new Map<string, EventLead>();
        for(QQNAIEvent__c event : eventRecords) {
        	leadIds.put(event.Ps_LeadIndexRef__c, new EventLead(event));
        }
        
        //	Fetch ps__Lead__c records corresponding to the randomly picked IDs
        List<ps__Lead__c> leadRecords = [
			select id, ps__refTypeOfRooms__c, ps__Rroom__c, ps__ReservedType__c, ps__Field367__c, ps__Segment__c
        	from ps__Lead__c where id in :leadIds.keySet()
        ];
        
        for(ps__Lead__c lead : leadRecords) {
        	leadIds.get(lead.id).lead = lead;
        }
        
        return leadIds.values();
	}
	// 房间分配权重值设定
	public static void roomStateToArray(string roomState, List<double> state) {
		// before字段拆分
		string[] roomStateArray = roomState.split('');
		for(string roomStateChar : roomStateArray) {
			// 有分配 1 无分配 0
			integer rState = integer.valueOf(roomStateChar);
			state.add(rState == 1 ? 1.0 : -1.0);
		}
	}
	
	private integer getMaxEvents() {
		if(maxEvents < 0) {
			List<QQNAIEvent__c> maxEventList = [select EventId__c from QQNAIEvent__c order by EventId__c desc limit 1];
			if(maxEventList != null && maxEventList.size() > 0)
				maxEvents = maxEventList[0].EventId__c.intValue();
		}
		
		return maxEvents;
	}
}