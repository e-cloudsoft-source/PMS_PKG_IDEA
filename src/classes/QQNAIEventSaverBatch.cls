public class QQNAIEventSaverBatch implements Database.Batchable<sObject>, Database.Stateful {
	private List<QQNAIEvent__c> events;
	// 実行行列
   	public List<String> excuteFields;
    public QQNAIEventSaverBatch(List<QQNAIEvent__c> events) {
    	this.events = events;
    }
    
    public List<QQNAIEvent__c> start(Database.BatchableContext BC) {
    	return events;
    }
    
    public void execute(Database.BatchableContext BC, List<QQNAIEvent__c> scope) {
    	try {insert scope;} catch(Dmlexception ex) {
    		QQNErrorLog__c objErrorLog = new QQNErrorLog__c(Description__c='Error while saving timeline events: '+ ex.getMessage() );
      		insert objErrorLog;}
    }
    
    public void finish(Database.BatchableContext BC) {
    	// 自動機能実行行列
    	QQNRoomTrainBatch.nextExcuteBatch(excuteFields);
    }
}