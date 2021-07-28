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
private class QQNRoomTrainBatchTest {

    static testMethod void myUnitTest() {
    	createOrderConfigXml();
    	Date startDt = system.today();
    	Date endDt = startDt.addDays(5);
        // TO DO: implement unit test
        List<Lead__c> leads = TestCommon.createLead(startDt, 5, 2);
        QQNRoomTrainBatch bppb = new QQNRoomTrainBatch('',startDt,endDt);
        DateTime nowTime = DateTime.now().addSeconds(100);
        String timeStr = nowTime.format('yyyyMMddHHmmss');
        String yy = timeStr.substring(0,4);
        String mm = timeStr.substring(4,6);
        String dd = timeStr.substring(6,8);
        String hh = timeStr.substring(8,10);
        String ms = timeStr.substring(10,12);
        String ss = timeStr.substring(12,14);
        String sch = ss + ' ' +
               ms + ' ' +
               hh + ' ' +
               dd + ' ' +
               mm + ' ' +
               ' ? ' + yy;
        String jobName = DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
        String jobId = system.schedule(jobName, sch, bppb);
        List<String> fieldLst = new List<String>{'ps__Rroom__c','ps__refTypeOfRooms__c',
														'ps__ReservedType__c','ps__Field367__c','ps__Segment__c',
														'AIEvent','Train'};//,'Delete'
		String spcd = '';
		// 
		QQNRoomTrainBatch.nextExcuteBatch(fieldLst,spcd,startDt,endDt);
		fieldLst.remove(0);
		QQNRoomTrainBatch.nextExcuteBatch(fieldLst,spcd,startDt,endDt);
		fieldLst.remove(0);
		QQNRoomTrainBatch.nextExcuteBatch(fieldLst,spcd,startDt,endDt);
		fieldLst.remove(0);
		QQNRoomTrainBatch.nextExcuteBatch(fieldLst,spcd,startDt,endDt);
		// 既存勉強対象
		String tdqnId = QQNRoomReservationAI.getActiveTDQNId();
		Database.executebatch(new QQNRoomTrainBatch(tdqnId),1);
		QQNAIDriver pDriver = new QQNAIDriver(tdqnId);
		pDriver.setOnLoadHandler(new QQNTrainingTdqnLoadHandler());
		pDriver.setTrainingBatchCreator(new QQNEventTrainingBatchCreator());
		pDriver.load();
		Database.executebatch(new QQNRoomTrainBatch(pDriver),1);
    }
    static testMethod void myUnitTest02() {
    	createOrderConfigXml();
    	Date startDt = system.today();
    	Date endDt = startDt.addDays(5);
        // TO DO: implement unit test
        List<Lead__c> leads = TestCommon.createLead(startDt, 5, 2);
        List<Id> leadIds = new List<Id>();
        List<QQNAIEvent__c> events = new List<QQNAIEvent__c>();
    	
    	//	Room occupancy status (0: available, 1: occupied)
    	integer zero = '0'.charAt(0);
        integer one = '1'.charAt(0);
        Id typeId = Testcommon.createTypeOfRoom().Id;
    	List<Room__c> rooms = Testcommon.createRooms(70,typeId);
    	//	Initialize room state
       	List<integer> roomState = new List<integer>();
       	for (integer i = 0 ; i < (leads.size() + 4);i++ ) roomState.add(zero);
       	String beforeState = string.fromCharArray(roomState);
        integer index = 0;
        List<QQNAILookup__c> aiLookup = new List<QQNAILookup__c>();
        for (Room__c room : rooms) {
        	QQNAILookup__c objAILookup = new QQNAILookup__c();
	    	objAILookup.TableName__c = 'ps__Lead__c';
	        objAILookup.FieldName__c = 'ps__Rroom__c';
	        objAILookup.FieldValue__c = room.id;
	        objAILookup.TranslatedValue__c = index;
            if (index < leads.size()) {
                leads[index].Rroom__c = room.id;
                leadIds.add(leads[index].id);
            }
	        aiLookup.add(objAILookup);
        	index ++;
        }
        update leads;
        insert aiLookup;
        // 参照ツール
		QQNAILookup aiLookups = new QQNAILookup();
		// 取得全て参照内容
		aiLookups.loadAll();
		// 部屋リスト作成
		Map<string, QQNAILookup.LookupValue> roomLookup = aiLookups.getFieldValueMap('ps__Lead__c', 'ps__Rroom__c');
        index = 0;
        for (Lead__c lead : leads) {
        	String roomId = lead.rroom__c;
        	QQNAILookup.LookupValue lookValue = roomLookup.get(roomId);
	    	integer room = 0;
	    	if (lookValue != null) room = lookValue.intValue;
			roomState[room] = zero;
        	events.add(new QQNAIEvent__c(Ps_LeadIndexRef__c = lead.id, EventId__c = index ,StateBefore__c = beforeState,RoomsAssigned__c = '' + room , Time__c = lead.entrytime__c.getTime()));
        	index ++;
        }
		// 自動機能実行行列
        //QQNAIEventSaverBatch batch = new QQNAIEventSaverBatch(events);
        //Database.executebatch(batch);
        insert events;
        
        /*
		Database.executebatch(new QQNRoomTrainBatch(tdqnId),1);
		*/

        // 既存勉強対象
        String tdqnId = QQNRoomReservationAI.getActiveTDQNId();
        
		QQNAIDriver pDriver = new QQNAIDriver(tdqnId);
		pDriver.setOnLoadHandler(new QQNTrainingTdqnLoadHandler());
		pDriver.setTrainingBatchCreator(new QQNEventTrainingBatchCreator());
		pDriver.load();
		
    	QQNAIConfiguration qqnAi = new QQNAIConfiguration();
    	
    	QQNEvalTrainingDataBatch.test();
    	QQNEvalTrainingDataBatch eval = new QQNEvalTrainingDataBatch();
    	eval.tdqnLoaded(pDriver);
    	
    	QQNTrainingTdqnLoadHandler tdqnLoad = new QQNTrainingTdqnLoadHandler();
    	tdqnLoad.tdqnLoaded(pDriver);
    	QQNRoomReservationAI.fullTest();
    	QQNEventTrainingBatchCreator tranEvent = new QQNEventTrainingBatchCreator();
		tranEvent.prepareBatch(pDriver);
		for (Lead__c lead : leads) {
			lead.rroom__c = null;
		}
		update leads;
		system.debug(LoggingLevel.info,[select id from QQNTruncatedDQN__c]);
    	QQNRoomAssignmentTest.checkLeadRoom(leadIds);
        // AI配置
        QQNAIConfigurationCreator aicc = new QQNAIConfigurationCreator();
        // 当前AI配置取得
        aicc.load();
        aicc.createRecords();

        // 既存勉強対象
        tdqnId = QQNRoomReservationAI.getActiveTDQNId();
		
        pDriver = new QQNAIDriver(tdqnId);
        pDriver.setOnLoadHandler(new QQNTrainingTdqnLoadHandler());
        pDriver.setTrainingBatchCreator(new QQNEventTrainingBatchCreator());
        pDriver.load();
        QQNRoomAssignmentTest test = new QQNRoomAssignmentTest();
        test.tdqnLoaded(pDriver);
	}
	static testMethod void myUnitTest03() {
		Date startDt = system.today();
    	Date endDt = startDt.addDays(5);
        // TO DO: implement unit test
        List<Lead__c> leads = TestCommon.createLead(startDt, 5, 2);
		createOrderConfigXml();
		// 既存勉強対象
        String tdqnId = QQNRoomReservationAI.getActiveTDQNId();
		QQNRoomReservationAI.checkLeadRoom(leads);
		QQNRoomReservationAI.prepareAILookup();
		QQNRoomReservationAI.prepareTimeline(1);
		QQNRoomReservationAI.createAI();
		QQNRoomReservationAI.train();
		QQNRoomReservationAI.trainFromXMLConfig();
		QQNRoomReservationAI.printStats(tdqnId);
		QQNRoomReservationAI.emailStats();
	}
    static document createOrderConfigXml() {
    	String domString = '<?xml version="1.0" encoding="UTF-8"?><Configuration>	<TruncatedDQN>		<BatchSize>10</BatchSize>		<DiscountFactor>0.9</DiscountFactor>		<MseThreshold>0</MseThreshold>		<PendingBatches>10</PendingBatches>		<IsActive>true</IsActive>		<Comment>001 First AI</Comment>				<NeuralNetwork>			<!-- InputCount = number of rooms (including null) + 4 -->			<InputCount>5</InputCount>			<LayerCount>1</LayerCount>			<LearningRate>0.0001</LearningRate>			<Layer>				<LayerId>0</LayerId>				<LearningRate>-1</LearningRate>				<IsOutput>true</IsOutput>				<!-- NeuronCount = number of rooms  (including null) -->				<NeuronCount>5</NeuronCount>			</Layer>		</NeuralNetwork>	</TruncatedDQN>	<Properties>		<Property key="soql_deleted" value="削除" />		<Property key="soql_cancelled" value="キャンセル" />		<Property key="soql_noshow" value="NO SHOW" />	</Properties></Configuration>';
    	Document item = new Document();
    	item.Name = 'AI Configuration';
    	item.DeveloperName = 'AI_Configuration';
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(domString);
    	insert item;
    	return item;
	}
}