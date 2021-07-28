public class QQNRoomAssignmentTest implements QQNTdqnLoadHandler {
	private class LeadByDepartureWrapper implements Comparable {
		private ps__Lead__c lead;
		
		public LeadByDepartureWrapper(ps__Lead__c lead) {
			this.lead = lead;
		}
		
		public integer compareTo(Object otherObject) {
            LeadByDepartureWrapper otherWrapper = (LeadByDepartureWrapper) otherObject;
            return lead.ps__Departure__c < otherWrapper.lead.ps__Departure__c ? -1 : 1;
        }
	}
	
	public void tdqnLoaded(QQNAIDriver driver) {
		List<QQNAIEvent__c> lastEventList = [
			SELECT id, Ps_LeadIndexRef__c, Time__c, RoomsAssigned__c, StateBefore__c
			FROM QQNAIEvent__c
			ORDER BY Time__c DESC, Ps_LeadIndexRef__c ASC
			LIMIT 20
		];
		
		List<double> state = new List<double>();
		for(integer i=0; i<QQNEventTrainingBatchCreator.N_FIELDS; i++) {
			state.add(0.0);
		}
		
		QQNEventTrainingBatchCreator.roomStateToArray(lastEventList[0].StateBefore__c, state);
		Integer assignedRoom = Integer.valueOf(lastEventList[0].RoomsAssigned__c);
		state[QQNEventTrainingBatchCreator.N_FIELDS + assignedRoom] = 1;
		List<ps__Lead__c> leads = [
			SELECT id, ps__refTypeOfRooms__c, ps__ReservedType__c, ps__Field367__c, ps__Segment__c, ps__EntryTime__c, ps__Departure__c, ps__Rroom__c
			FROM ps__Lead__c
			WHERE ps__Rroom__c=null AND ps__EntryTime__c > 2016-12-25T06:30:00.000+0000
			ORDER BY ps__EntryTime__c ASC
		];
		
		QQNAILookup aiLookup = new QQNAILookup();
		aiLookup.loadAll();
		Map<string, QQNAILookup.LookupValue> roomMap = aiLookup.getFieldValueMap('ps__Lead__c', 'ps__Rroom__c');
		integer nRooms = roomMap.size();
		string[] roomReverseList = new string[nRooms];
		for(string roomSFId : roomMap.keySet()) {
			QQNAILookup.LookupValue value = roomMap.get(roomSFId);
			roomReverseList[value.intValue] = roomSFId;
		}
		
		QQNTruncatedDQN tdqn = driver.getTDQN();
		List<LeadByDepartureWrapper> departures = new List<LeadByDepartureWrapper>();
		String result = 'id, assigned room (AILookup), ps__Rroom__c, ps__refTypeOfRooms__c, ps__ReservedType__c, ps__Field367__c, ps__Segment__c, ps__EntryTime__c, ps__Departure__c,';
		for(integer i=0; i < nRooms; i++) {
			result += ',' + i;
		}
		
		decimal lastEntry = lastEventList[0].Time__c;
		List<Id> leadDepartureIds = new List<Id>();
		for(QQNAIEvent__c event : lastEventList) {
			if(event.Time__c == lastEntry)
				leadDepartureIds.add(event.Ps_LeadIndexRef__c);
			else
				break;
		}
		
		List<ps__Lead__c> lastLeadList = [
			SELECT id, ps__refTypeOfRooms__c, ps__ReservedType__c, ps__Field367__c, ps__Segment__c, ps__EntryTime__c, ps__Departure__c, ps__Rroom__c
			FROM ps__Lead__c
			WHERE id in :leadDepartureIds
		];
		
		for(ps__Lead__c lastLead : lastLeadList) {
			departures.add(new LeadByDepartureWrapper(lastLead));
		}
		for(ps__Lead__c lead : leads) {
			while(departures.size() > 0 && departures[0].lead.ps__Departure__c <= lead.ps__EntryTime__c) {
				integer vacatedRoom = roomMap.get(departures[0].lead.ps__Rroom__c).intValue;
				state[QQNEventTrainingBatchCreator.N_FIELDS + vacatedRoom] = -1.0;
				departures.remove(0);
			}
			state[0] = aiLookup.translate('ps__Lead__c', 'ps__refTypeOfRooms__c', lead.ps__refTypeOfRooms__c).normalizedValue;
        	state[1] = aiLookup.translate('ps__Lead__c', 'ps__ReservedType__c', lead.ps__ReservedType__c).normalizedValue;
        	state[2] = aiLookup.translate('ps__Lead__c', 'ps__Field367__c', lead.ps__Field367__c).normalizedValue;
        	state[3] = aiLookup.translate('ps__Lead__c', 'ps__Segment__c', lead.ps__Segment__c).normalizedValue;
			
			assignedRoom = tdqn.evaluate(state);
			lead.ps__Rroom__c = roomReverseList[assignedRoom];
			
			String csvRow = '\n' + lead.id + ',' + assignedRoom + ',' + lead.ps__Rroom__c + ','
					+ lead.ps__refTypeOfRooms__c + ',' + lead.ps__ReservedType__c + ',' + lead.ps__Field367__c + ','
					+ lead.ps__Segment__c + ',' + lead.ps__EntryTime__c + ',' + lead.ps__Departure__c + ',' 
					+ occupancyToCSV(state, QQNEventTrainingBatchCreator.N_FIELDS);
			
			state[QQNEventTrainingBatchCreator.N_FIELDS + assignedRoom] = 1.0;
			
			System.debug(state);
			
			departures.add(new LeadByDepartureWrapper(lead));
			departures.sort();
			
			result += csvRow;
		}
System.debug(logginglevel.info,'tdqn:::' + tdqn);
		QQNRoomReservationAI.sendEmail('[TDQN] RoomAssignmentTest results for TDQN ' + tdqn.getSFObject().id,
			'PFA test results for TDQN with id ' + tdqn.getSFObject().id,
			result);
	}
	
	public static String occupancyToCSV(double[] state, integer offset) {
		String occupancy = '';
		integer nStates = state.size();
		for(integer i = offset; i < nStates; i++) {
			if(state[i] <= 0)
				occupancy += ',0';
			else
				occupancy += ',1';
		}
		
		return occupancy;
	}
	public static void checkLeadRoom(List<Id> leadLst){
		
		 List<ps__Lead__c> leads = [
			SELECT id, ps__refTypeOfRooms__c, ps__ReservedType__c, ps__Field367__c, ps__Segment__c, ps__EntryTime__c, ps__Departure__c, ps__Rroom__c
			FROM ps__Lead__c
			WHERE ps__Rroom__c=null AND id = :leadLst
			ORDER BY ps__EntryTime__c ASC
		];
		if (leads.isEmpty()) return;
		
		Id tdqnId = QQNRoomReservationAI.getActiveTDQNId();
		QQNAIDriver driver = new QQNAIDriver(tdqnId);
    	driver.setOnLoadHandler(new QQNTrainingTdqnLoadHandler());
    	driver.setOnTrainHandler(new QQNRoomReservationAI.TestHandler());
        driver.setTrainingBatchCreator(new QQNEventTrainingBatchCreator());
        driver.load();
        QQNTruncatedDQN tdqn = driver.getTDQN();
        List<QQNAIEvent__c> lastEventList = [
			SELECT id, Ps_LeadIndexRef__c, Time__c, RoomsAssigned__c, StateBefore__c
			FROM QQNAIEvent__c
			ORDER BY Time__c DESC, Ps_LeadIndexRef__c ASC
			LIMIT 20
		];
		
		List<double> state = new List<double>();
		for(integer i=0; i<QQNEventTrainingBatchCreator.N_FIELDS; i++) {
			state.add(0.0);
		}
		QQNEventTrainingBatchCreator.roomStateToArray(lastEventList[0].StateBefore__c, state);
		Integer assignedRoom = Integer.valueOf(lastEventList[0].RoomsAssigned__c);
		state[QQNEventTrainingBatchCreator.N_FIELDS + assignedRoom] = 1;
		
		QQNAILookup aiLookup = new QQNAILookup();
		aiLookup.loadAll();
		Map<string, QQNAILookup.LookupValue> roomMap = aiLookup.getFieldValueMap('ps__Lead__c', 'ps__Rroom__c');
		integer nRooms = roomMap.size();
		string[] roomReverseList = new string[nRooms];
		for(string roomSFId : roomMap.keySet()) {
			QQNAILookup.LookupValue value = roomMap.get(roomSFId);
			roomReverseList[value.intValue] = roomSFId;
		}
		
		List<LeadByDepartureWrapper> departures = new List<LeadByDepartureWrapper>();
		String result = 'id, assigned room (AILookup), ps__Rroom__c, ps__refTypeOfRooms__c, ps__ReservedType__c, ps__Field367__c, ps__Segment__c, ps__EntryTime__c, ps__Departure__c,';
		for(integer i=0; i < nRooms; i++) {
			result += ',' + i;
		}
		
		decimal lastEntry = lastEventList[0].Time__c;
		List<Id> leadDepartureIds = new List<Id>();
		for(QQNAIEvent__c event : lastEventList) {
			if(event.Time__c == lastEntry)
				leadDepartureIds.add(event.Ps_LeadIndexRef__c);
			else
				break;
		}
		
		List<ps__Lead__c> lastLeadList = [
			SELECT id, ps__refTypeOfRooms__c, ps__ReservedType__c, ps__Field367__c, ps__Segment__c, ps__EntryTime__c, ps__Departure__c, ps__Rroom__c
			FROM ps__Lead__c
			WHERE id in :leadDepartureIds
		];
		
		for(ps__Lead__c lastLead : lastLeadList) {
			departures.add(new LeadByDepartureWrapper(lastLead));
		}
		for(ps__Lead__c lead : leads) {
			while(departures.size() > 0 && departures[0].lead.ps__Departure__c <= lead.ps__EntryTime__c) {
				integer vacatedRoom = roomMap.get(departures[0].lead.ps__Rroom__c).intValue;
				state[QQNEventTrainingBatchCreator.N_FIELDS + vacatedRoom] = -1.0;
				departures.remove(0);
			}
			QQNAILookup.LookupValue lookVal = aiLookup.translate('ps__Lead__c', 'ps__refTypeOfRooms__c', lead.ps__refTypeOfRooms__c);
			if (lookVal != null) state[0] = lookVal.normalizedValue;
			lookVal = aiLookup.translate('ps__Lead__c', 'ps__ReservedType__c', lead.ps__ReservedType__c);
			if (lookVal != null) state[1] = lookVal.normalizedValue;
			lookVal = aiLookup.translate('ps__Lead__c', 'ps__Field367__c', lead.ps__Field367__c);
			if (lookVal != null) state[2] = lookVal.normalizedValue;
			lookVal = aiLookup.translate('ps__Lead__c', 'ps__Segment__c', lead.ps__Segment__c);
			if (lookVal == null) state[3] = lookVal.normalizedValue;
			if (tdqn == null) return;
			assignedRoom = tdqn.evaluate(state);
			lead.ps__Rroom__c = roomReverseList[assignedRoom];
			
			String csvRow = '\n' + lead.id + ',' + assignedRoom + ',' + lead.ps__Rroom__c + ','
					+ lead.ps__refTypeOfRooms__c + ',' + lead.ps__ReservedType__c + ',' + lead.ps__Field367__c + ','
					+ lead.ps__Segment__c + ',' + lead.ps__EntryTime__c + ',' + lead.ps__Departure__c + ',' 
					+ occupancyToCSV(state, QQNEventTrainingBatchCreator.N_FIELDS);
			
			state[QQNEventTrainingBatchCreator.N_FIELDS + assignedRoom] = 1.0;
			
			System.debug(state);
			
			departures.add(new LeadByDepartureWrapper(lead));
			departures.sort();
			
			result += csvRow;
		}
		
		QQNRoomReservationAI.sendEmail('[TDQN] RoomAssignmentTest results for TDQN ' + tdqn.getSFObject().id,
			'PFA test results for TDQN with id ' + tdqn.getSFObject().id,
			result);
	}
}