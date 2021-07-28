public with sharing class QQNRoomTrainBatch implements Schedulable,Database.Batchable<sObject>, Database.Stateful{
	// 実行行列
   	public List<String> excuteFields;
   	public static Set<String> fieldSet = new Set<String>{'ps__Rroom__c','ps__refTypeOfRooms__c','ps__ReservedType__c','ps__Field367__c','ps__Segment__c'};
	public static Set<String> aiSet = new Set<String>{'AIEvent'};
	public static Set<String> trainSet = new Set<String>{'Train'};
	public static Set<String> deleteSet = new Set<String>{'Delete'};
	// 開始日付
	private Date startDt;
	// 出発日付
	private Date endDt;
	// 店舗コード
	private String spcd;
   	public QQNRoomTrainBatch(){}
   	public QQNRoomTrainBatch(String shopCode,Date pStartDt,Date pEndDt){
   		spcd = shopCode;
   		startDt = pStartDt;
   		endDt = pEndDt;
   	}
    // ***********************************
	// スケジュール処理開始
	// ***********************************
	public void execute(SchedulableContext SC) {
		// 部屋自動割当機能AI
		// AI参照内容処理
		List<String> fieldLst = new List<String>{'ps__Rroom__c','ps__refTypeOfRooms__c',
														'ps__ReservedType__c','ps__Field367__c','ps__Segment__c',
														'AIEvent','Train'};//,'Delete'
		// 既存訓練無効
		List<QQNTruncatedDQN__c> truncateds = [SELECT id,IsActive__c FROM QQNTruncatedDQN__c WHERE IsActive__c = true ORDER BY Name DESC];
		for (QQNTruncatedDQN__c truncate : truncateds) {
			truncate.IsActive__c = false;
		}
		if (!truncateds.isEmpty()) update truncateds;
		QQNRoomTrainBatch.nextExcuteBatch(fieldLst,spcd,startDt,endDt);
	}
	// 自動機能実行行列
	public static void nextExcuteBatch(List<String> functions){
		nextExcuteBatch(functions,null,null,null);
	}
	// 自動機能実行行列
	public static void nextExcuteBatch(List<String> functions,String spcd,Date start,Date endDt){
		if (functions != null && !functions.isEmpty()) {
			String nextFunction = functions[0];
			functions.remove(0);
			// Lookup
			if (fieldSet.contains(nextFunction)) {
				QQNAILookupFieldBatch lookupBatch = new QQNAILookupFieldBatch('ps__Lead__c', nextFunction);
				lookupBatch.excuteFields = functions;
				lookupBatch.spcd = spcd;
   				lookupBatch.startDt = start;
   				lookupBatch.endDt = endDt;
				Database.executebatch(lookupBatch);
			// 权重值修改
			} else if (aiSet.contains(nextFunction)) {
				integer fetchLimit = 10000;
				// 既存勉強対象
				String tdqnId = QQNRoomReservationAI.getActiveTDQNId();
				// 既存勉強なし
				if (tdqnId == null) {
					QQNAIEventLoaderBatch lookupBatch = new QQNAIEventLoaderBatch(fetchLimit);
					lookupBatch.excuteFields = functions;
					lookupBatch.spcd = spcd;
	   				lookupBatch.startDt = start;
	   				lookupBatch.endDt = endDt;
					Database.executebatch(lookupBatch);
				// 既存勉強ありと訓練完了なし
				} else QQNRoomTrainBatch.nextExcuteBatch(functions);
			// 权重值修改
			} else if (trainSet.contains(nextFunction)) {
				// 既存勉強対象
				String tdqnId = QQNRoomReservationAI.getActiveTDQNId();
				if (tdqnId == null) {
					QQNAIConfigurationCreator config = new QQNAIConfigurationCreator();
    				config.load();
    				tdqnId = config.createRecords();
				}
				// AI訓練
				//QQNRoomReservationAI.trainFromXMLConfig();
				QQNAIDriver pDriver = new QQNAIDriver(tdqnId);
		    	pDriver.setOnLoadHandler(new QQNTrainingTdqnLoadHandler());
		    	pDriver.setTrainingBatchCreator(new QQNEventTrainingBatchCreator());
		        pDriver.load();
			// AI訓練内容クリア
			} else if (deleteSet.contains(nextFunction)) {
				// 2019/02/15 AI功能改修 by zy BEGIN
				//Database.executebatch(new QQNRoomTrainBatch(),2000);
				// 2019/02/15 AI功能改修 by zy END
			}
		}
	}
	public static final integer N_FIELDS = 4;
	private QQNAIDriver pDriver;
	private QQNAILookup aiLookup;
	private String tqdnId;
	private double mse;
	private boolean loadingOverFlag;
	public QQNRoomTrainBatch(String truncateId){
		tqdnId = truncateId;
	}
	public QQNRoomTrainBatch(QQNAIDriver driver){
		pDriver = driver;
	}
	public Database.QueryLocator start(Database.BatchableContext BC){
    		// 
    		aiLookup = new QQNAILookup();
			aiLookup.loadAll();
			// 2019/02/15 AI功能改修 by zy BEGIN
        	// String strNeuronquery = 'select id from QQNAIEvent__c';
        	String strNeuronquery = 'select id,ps_LeadIndexRef__c,RoomState__c from QQNAIEvent__c';
        	// 2019/02/15 AI功能改修 by zy END
        	return Database.getQueryLocator(strNeuronquery);
	}
    public void execute(Database.BatchableContext BC, List<QQNAIEvent__c> scope) {
    	// 2019/09/15 Security Check BY zyz BEGIN
    	if (!CommSecurityUtils.isDeleteable(QQNAIEvent__c.getSObjectType())) {
    		return;
    	}
    	// 2019/09/15 Security Check BY zyz END
    	Set<Id> leadSet = new Set<Id>();
        Map<String,String> beforeMap = new Map<String,String>();
    	for (QQNAIEvent__c event : scope) {
    		leadSet.add(event.ps_LeadIndexRef__c);
    		// 2019/02/15 AI功能改修 by zy BEGIN
    		beforeMap.put(event.ps_LeadIndexRef__c,event.RoomState__c);
    		//beforeMap.put(event.ps_LeadIndexRef__c,event.StateBefore__c);
    		// 2019/02/15 AI功能改修 by zy END
    	}
    	List<ps__Lead__c> leads = [select ps__Rroom__c,ps__refTypeOfRooms__c,ps__ReservedType__c,ps__Field367__c,ps__Segment__c from ps__lead__c where id = :leadSet];
		// 訓練
        List<double> state;
		List<double> endstate;
		List<QQNQLearningTuple> trainingBatch = new List<QQNQLearningTuple>();
		integer maxAction = pDriver.neuralNetwork.getOutputCount();
		// 取得训练batch
    	for (ps__Lead__c lead : leads) {
    		state = new List<double>();
        	//	TODO Translate remaining field values through AILookup
        	//	ps__refTypeOfRooms__c, ps__ReservedType__c, ps__Field367__c, ps__Segment__c
        	state.add(aiLookup.translate('ps__Lead__c', 'ps__refTypeOfRooms__c', lead.ps__refTypeOfRooms__c).normalizedValue);
        	state.add(aiLookup.translate('ps__Lead__c', 'ps__ReservedType__c', lead.ps__ReservedType__c).normalizedValue);
        	state.add(aiLookup.translate('ps__Lead__c', 'ps__Field367__c', lead.ps__Field367__c).normalizedValue);
        	state.add(aiLookup.translate('ps__Lead__c', 'ps__Segment__c', lead.ps__Segment__c).normalizedValue);
        	QQNEventTrainingBatchCreator.roomStateToArray(beforeMap.get(lead.id), state);
        	integer action = aiLookup.translate('ps__Lead__c', 'ps__Rroom__c', lead.ps__Rroom__c).intValue;
        	if (action >= maxAction) continue;
        	//reward = 1;
			integer reward = state[N_FIELDS + action] <= 0 ? 1 : -1;
        	endstate = new List<double>(state);
        	endstate[N_FIELDS + action] = 1.0;
        	trainingBatch.add(new QQNQLearningTuple(state, action, reward, endState));
        	// 訓練件数
        	pDriver.prcessInt++;
    	}
    	if (!trainingBatch.isEmpty()) pDriver.mse = pDriver.tdqn.trainBatch(trainingBatch);
    	if (!scope.isEmpty()) delete scope;
    }
    public void finish(Database.BatchableContext BC){
		Database.executebatch(new QQNAISaveNeurons(pDriver),1);
    }
}