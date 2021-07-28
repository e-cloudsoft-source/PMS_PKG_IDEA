public class QQNAIEventLoaderBatch implements Database.Batchable<sObject>, Database.Stateful {
	private final long MS_18_5_H = (18 * 60 + 30) * 60 * 1000;
	// ８時処理
	private final long MS_8_H = (8 * 60) * 60 * 1000;
	// 実行行列
   	public List<String> excuteFields;
   	public String spcd;
   	public Date startDt;
   	public Date endDt;
    private class SortableAIEventWrapper implements Comparable {
        public QQNAIEvent__c event;
        private long eTime;
        private string roomId;
        
        public SortableAIEventWrapper(QQNAIEvent__c event, ps__Lead__c record) {
            this.event = event;
            this.eTime = event.Time__c.longValue();
            this.roomId = record.ps__Rroom__c;
        }
        
        public integer compareTo(Object otherObject) {
            SortableAIEventWrapper otherWrapper = (SortableAIEventWrapper) otherObject;
            long comparison = eTime - otherWrapper.eTime;
            
            return comparison == 0
            		? ((event.IsEntry__c ? 1 : -1) - (otherWrapper.event.IsEntry__c ? 1 : -1))
            		: (comparison < 0 ? -1 : 1);
        }
    }
    
    /*private static Long toMinutes(date eDate, string eTime) {
        if(eDate == null)
            return 0;
        
        string[] eTimeParts = eTime != null ? eTime.split(':') : null;
        DateTime eDateTime;
        if(eTimeParts != null && eTimeParts.size() == 2) {
            eDateTime = DateTime.newInstance(eDate.year(), eDate.month(), eDate.day(), Integer.valueOf(eTimeParts[0]), Integer.valueOf(eTimeParts[1]), 0);
        } else {
            eDateTime = DateTime.newInstance(eDate.year(), eDate.month(), eDate.day(), 0, 0, 0);
        }
        
        return eDateTime.getTime();
    }*/
    
    private List<SortableAIEventWrapper> events;
    // 指定取得データ数
    private integer fetchLimit;
    
    public QQNAIEventLoaderBatch() {
        this(0);
    }
    private integer maxRooms = 3;
    // 初期化
    public QQNAIEventLoaderBatch(integer fetchLimit) {
        events = new List<SortableAIEventWrapper>();
        this.fetchLimit = fetchLimit;
    }
    // バッチ開始
	public List<ps__Lead__c> start(Database.BatchableContext BC) {
		// AI配置
		QQNAIConfigurationCreator aicc = new QQNAIConfigurationCreator();
		// 当前AI配置取得
		aicc.load();
		// 予約データ取得以外状態字段指定
		//	<Property key="soql_deleted" value="削除"/>
		String deletedString = aicc.getProperty('soql_deleted');
		//	<Property key="soql_cancelled" value="キャンセル"/>
		String cancelledString = aicc.getProperty('soql_cancelled');
		//	<Property key="soql_noshow" value="NO SHOW"/>
		String noshowString = aicc.getProperty('soql_noshow');
		
		system.debug('deletedString = ' + deletedString + ', cancelledString = ' + cancelledString + ', noshowString = ' + noshowString +', fetchLimit = ' + fetchLimit);
		
		if(noshowString == null || cancelledString == null || deletedString == null) {
			return [select id from ps__Lead__c limit 0];
		}
		// 今日以前のデータ取得
		String strQuery = 'SELECT id, ps__EntryTime__c, ps__Departure__c, ps__Rroom__c FROM ps__Lead__c ' + 
	    					'WHERE ps__ReservedStatus__c <> \'' + noshowString + '\' AND ' +
	                        'ps__ReservedStatus__c <> \'' + cancelledString + '\' AND ' +
	                        // 2019/02/15 AI功能改修 by zy BEGIN
	                        'ps__ReservedStatus__c <> \'' + deletedString + '\'' + 
	                        // 2019/02/15 AI功能改修 by zy END
	                        //+ '\' AND ps__EntryTime__c <= TODAY' 
	                        + ' and ps__Rroom__c != null ' ;
	    // 2018/12/30 部屋自動割当機能AI対応 by zy BEGIN
	    // 開始日
	    // if (!CommUtils.isBlank(aicc.sqlWhere)) strQuery += aicc.sqlWhere;
	    // if (!CommUtils.isBlank(spcd)) strQuery += ' and refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c = :spcd ';
    	if (startDt != null) strQuery += 'And DAY_ONLY(convertTimezone(EntryTime__c)) >= :startDt ';
    	if (endDt != null) strQuery += ' And DAY_ONLY(convertTimezone(EntryTime__c)) < :endDt ';
	    // 2018/12/30 部屋自動割当機能AI対応 by zy END
	    // 2019/02/15 AI功能改修 by zy BEGIN
	    // 指定部屋タイプ処理対象
	    Set<Decimal> rommTypCodeSet = QQNAIConfigurationCreator.getRoomTypeSQL();
	   	if (!rommTypCodeSet.isEmpty()) strQuery += ' and refTypeOfRooms__r.Seq__c in :rommTypCodeSet';
	    fetchLimit = QQNAIConfigurationCreator.getTrainDataLimit();
	   	strQuery += ' ORDER BY ps__EntryTime__c LIMIT ' + fetchLimit;
	   	maxRooms = QQNAIConfigurationCreator.getMaxNueronsCount();
	   	// 2019/02/15 AI功能改修 by zy END
		return Database.query(strQuery);
    }
    // バッチ処理
    public void execute(Database.BatchableContext BC, List<ps__Lead__c> scope) {
    	// AI指定
        QQNAIEvent__c entryEvent, departureEvent;
        // 
        for(ps__Lead__c record : scope) {
        	// 到着日と部屋あり
        	if(record.ps__EntryTime__c != null && record.ps__Rroom__c != null) {
        		long eTime = record.ps__EntryTime__c.getTime();
        		long dTime = record.ps__Departure__c.getTime();
        		// 宿泊時長超過指定時間
        		//if(dTime - eTime > MS_8_H) {
        			// 到着日のデータ作成
		            entryEvent = new QQNAIEvent__c();
		            //entryEvent.Time__c = toMinutes(record.ps__EntryDate__c, record.ps__EntryTime__c);
		            //　処理時間設定
		            entryEvent.Time__c = eTime;
		            entryEvent.IsEntry__c = true;
		            // 予約ID
		            entryEvent.Ps_LeadIndexRef__c = record.Id;
		            events.add(new SortableAIEventWrapper(entryEvent, record));
		            // 出発日のデータ作成
		            departureEvent = new QQNAIEvent__c();
		            //departureEvent.Time__c = toMinutes(record.ps__DepartureDate__c, record.ps__DepartureTime__c);
		            //departureEvent.Time__c = entryEvent.Time__c + MS_18_5_H;
		            departureEvent.Time__c = dTime;
		            departureEvent.IsEntry__c = false;
		             // 予約ID
		            departureEvent.Ps_LeadIndexRef__c = record.Id;
		            events.add(new SortableAIEventWrapper(departureEvent, record));
        		//}
        	}
        }
    }
    
    public void finish(Database.BatchableContext BC) {
    	//	Build map of rooms
    	QQNAILookup lookup = new QQNAILookup();
    	// 指定部屋字段処理
    	Map<string, QQNAILookup.LookupValue> roomLookup = lookup.loadField('ps__Lead__c', 'ps__Rroom__c');
    	
    	//	Room occupancy status (0: available, 1: occupied)
    	integer zero = '0'.charAt(0);
        integer one = '1'.charAt(0);
    	
    	//	Initialize room state
       	integer[] roomState = new integer[maxRooms];
        //List<Double> roomState = new List<Double>();
        for(integer rlIndex = 0; rlIndex < maxRooms; rlIndex++) {
        	roomState[rlIndex] = zero;
        }
        /*
        // 上一次矩阵利用
    	List<QQNAIEvent__c> lastEventList = [
			SELECT id, Ps_LeadIndexRef__c, Time__c, RoomsAssigned__c, StateBefore__c
			FROM QQNAIEvent__c
			ORDER BY Time__c DESC, Ps_LeadIndexRef__c ASC
			LIMIT 1
		];
		if (!lastEventList.isEmpty()) QQNEventTrainingBatchCreator.roomStateToArray(lastEventList[0].StateBefore__c, roomState);
		*/
		// 時間順ソート
        events.sort();
        
        integer eventId = 0;
        List<QQNAIEvent__c> sfEvents = new List<QQNAIEvent__c>();
        for(SortableAIEventWrapper ew : events) {
        	// 2019/02/15 AI功能改修 by zy BEGIN
   			ew.event.RoomState__c = string.fromCharArray(roomState);
        	// ew.event.StateBefore__c = string.fromCharArray(roomState);
        	// 2019/02/15 AI功能改修 by zy END
        	ew.event.RoomsAssigned__c = updateRoomState(ew.roomId,
        			ew.event.IsEntry__c ? one : zero, roomLookup, roomState);
        	
        	//System.debug('[' + ew.event.Ps_LeadIndexRef__c + ']' + Datetime.newInstance(ew.event.Time__c.longValue()) + (ew.event.IsEntry__c ? ' +:' : ' -:') + ew.event.StateBefore__c + ' > ' + ew.event.RoomsAssigned__c);
        	// 到着日のデータ追加
        	if(ew.event.IsEntry__c) {
	        	ew.event.EventId__c = eventId++;
	            sfEvents.add(ew.event);
        	}
        }
        // 自動機能実行行列
        QQNAIEventSaverBatch batch = new QQNAIEventSaverBatch(sfEvents);
        batch.excuteFields = excuteFields;
         
        //	Save to DB
        Database.executeBatch(batch);
    }
    
    private string updateRoomState(string roomId, integer state,
			Map<string, QQNAILookup.LookupValue> roomLookup, integer[] roomState) {
		QQNAILookup.LookupValue lookValue = roomLookup.get(roomId);
    	integer room = 0;
    	if (lookValue != null) room = lookValue.intValue;
    	// 2019/02/15 AI功能改修 by zy BEGIN
    	if (room < roomState.size()) {
			roomState[room] = state;
    	}
    	// 2019/02/15 AI功能改修 by zy END
		return '' + room;
    }
    
    /*private string setRoomStates(List<ps__Lead__c> leadRecords, integer state, 
    							Map<string, AILookup.LookupValue> roomLookup,
    							integer[] roomState) {
    	string roomsAssigned = '';
    	
    	for(ps__Lead__c lead : leadRecords) {
    		integer room = roomLookup.get(lead.ps__Rroom__c).intValue;
    		if(room != null) {
    			roomState[room] = state;
    			
    			if(roomsAssigned.length() > 0) {
    				roomsAssigned += ',';
    			}
    			roomsAssigned += room;
    		}
    	}
    	
    	return roomsAssigned;
    }*/
}