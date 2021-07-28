public class QQNEvalTrainingDataBatch implements Database.Batchable<sObject>, Database.Stateful, QQNTdqnLoadHandler {
	private static final integer JOB_LIMIT = 30;
	
	private class EvalJob implements Queueable {
		private List<string> resultList;
		private integer jobId;
		private QQNEvalTrainingDataBatch parent;
		
		public EvalJob(QQNEvalTrainingDataBatch parent, integer jobId) {
			this.parent = parent;
			resultList = new List<string>();
			this.jobId = jobId;
		}
		
		public void execute(QueueableContext qc) {
			System.debug('Job #' + jobId + ' started!');
			
	    	string result = 'lead.id'+ 
					',assignedRoomLookupId' + 
					',Room Assigned by AI' + 
					',Room Assigned by human (lead.ps__Rroom__c)' + 
					',lead.ps__refTypeOfRooms__c' + 
					',lead.ps__ReservedType__c' + 
					',lead.ps__Field367__c' + 
					',lead.ps__Segment__c' + 
					',lead.ps__EntryTime__c' + 
					',lead.ps__Departure__c' +
					',';
			integer nRooms = parent.roomMap.size();
			for(integer i=0; i<nRooms; i++) {
				result += (',' + i);
			}
			
			for(string resultCSV : resultList) {
				result += resultCSV;
			}
			
			QQNTruncatedDQN tdqn = parent.driver.getTDQN();
			QQNRoomReservationAI.sendEmail('[TDQN] QQNEvalTrainingDataBatch results for TDQN ' + tdqn.getSFObject().id,
				'PFA test results for TDQN:\nid=' + tdqn.getSFObject().id + '\njob=' + jobId,
				result);
		}
		
		public EvalJob addBatch(string resultCSV) {
			resultList.add(resultCSV);
			
			if(resultList.size() >= JOB_LIMIT) {
				enqueue();
				return new EvalJob(parent, jobId + 1);
			} else
				return this;
		}
		
		public void enqueue() {
			if(resultList.size() > 0) {
				System.debug('Job #' + jobId + ' queued!');
				System.enqueueJob(this);
			}
		}
	}
	
	private QQNAIDriver driver;
	private QQNAILookup aiLookup;
	private Map<string, QQNAILookup.LookupValue> roomMap;
	private string[] roomReverseList;
	private EvalJob currentJob;
	private integer nEventRecords;
	private integer nLeadRecords;
	
    public void tdqnLoaded(QQNAIDriver driver) {
    	this.driver = driver;
    	Database.executeBatch(this);
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
    	this.aiLookup = new QQNAILookup();
		
		aiLookup.loadAll();
    	
    	roomMap = aiLookup.getFieldValueMap('ps__Lead__c', 'ps__Rroom__c');
		integer nRooms = roomMap.size();
		roomReverseList = new string[nRooms];
		
		for(string roomSFId : roomMap.keySet()) {
			QQNAILookup.LookupValue value = roomMap.get(roomSFId);
			roomReverseList[value.intValue] = roomSFId;
		}
		
		nEventRecords = 0;
		nLeadRecords = 0;
		currentJob = new EvalJob(this, 1);
		
    	return Database.getQueryLocator(
    		'SELECT ps_LeadIndexRef__c, StateBefore__c,RoomState__c FROM QQNAIEvent__c ORDER BY Time__c'
    	);
    }
    
    public void execute(Database.BatchableContext BC, List<QQNAIEvent__c> scope) {
    	try{
	    	Map<Id, QQNAIEvent__c> eventsById = new Map<Id, QQNAIEvent__c>();
	    	for(QQNAIEvent__c event : scope) {
	    		eventsById.put(event.ps_LeadIndexRef__c, event);
	    	}
	    	
	    	List<ps__Lead__c> leads = [
	    		SELECT id, ps__refTypeOfRooms__c, ps__ReservedType__c, ps__Field367__c, ps__Segment__c, ps__EntryTime__c, ps__Departure__c, ps__Rroom__c
				FROM ps__Lead__c
				WHERE id IN :eventsById.keySet()
	    	];
	    	
	    	integer assignedRoomLookupId;
		    string assignedRoomLookupValue;
		    QQNTruncatedDQN tdqn = driver.getTDQN();
		    system.debug(logginglevel.info,'tdqn::::' + tdqn);
		    string result = '';
	    	for(ps__Lead__c lead : leads) {
	    		List<double> state = new List<double>();
				state.add(aiLookup.translate('ps__Lead__c', 'ps__refTypeOfRooms__c', lead.ps__refTypeOfRooms__c).normalizedValue);
	        	state.add(aiLookup.translate('ps__Lead__c', 'ps__ReservedType__c', lead.ps__ReservedType__c).normalizedValue);
	        	state.add(aiLookup.translate('ps__Lead__c', 'ps__Field367__c', lead.ps__Field367__c).normalizedValue);
	        	state.add(aiLookup.translate('ps__Lead__c', 'ps__Segment__c', lead.ps__Segment__c).normalizedValue);
	        	
	        	QQNAIEvent__c event = eventsById.get(lead.id);
	        	QQNEventTrainingBatchCreator.roomStateToArray(event.RoomState__c, state);
				
				assignedRoomLookupId = tdqn.evaluate(state);
				assignedRoomLookupValue = roomReverseList[assignedRoomLookupId];
				
				String csvRow = '\n' + lead.id + 
						',' + assignedRoomLookupId + 
						','  + assignedRoomLookupValue + 
						',' + lead.ps__Rroom__c + 
						',' + lead.ps__refTypeOfRooms__c + 
						',' + lead.ps__ReservedType__c + 
						',' + lead.ps__Field367__c + 
						',' + lead.ps__Segment__c + 
						',' + lead.ps__EntryTime__c + 
						',' + lead.ps__Departure__c + 
						',' + QQNRoomAssignmentTest.occupancyToCSV(state, QQNEventTrainingBatchCreator.N_FIELDS);
				
				result += csvRow;
			}
	    	
	    	nEventRecords += scope.size();
	    	nLeadRecords += leads.size();
	    	   	
			currentJob = currentJob.addBatch(result);
    	}catch(exception ex){
    		system.debug(logginglevel.info,'ex:::' + ex.getStackTraceString());
			QQNErrorLog__c objErrorLog = new QQNErrorLog__c(Description__c='Error while running the EvalTrainingBatch '+ ex.getMessage() );
      		insert objErrorLog;
		}
    }
    
    public void finish(Database.BatchableContext BC) {
    	System.debug('# event records = ' + nEventRecords);
    	System.debug('# lead records = ' + nLeadRecords);
    	currentJob.enqueue();
    }
    
    public static void test() {
    	QQNAIDriver driver = new QQNAIDriver(QQNRoomReservationAI.getActiveTDQNId());
    	driver.setOnLoadHandler(new QQNEvalTrainingDataBatch());
    	driver.load();
    }
}