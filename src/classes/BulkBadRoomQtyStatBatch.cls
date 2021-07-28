/**
 * バッチ連携：指定期間の日別の有効予約数、部屋数を集計する
 *
 **/
public with sharing class BulkBadRoomQtyStatBatch implements Database.Batchable<TypeOfRooms__c>, Database.Stateful,Schedulable{
	public Date startDt;
	public Date endDt;
	public Date nowDt;//処理日
	public String spcd;
	private Boolean isFromSchedule;
	// XML定義情報を格納する
	public map<String,XmlConfig> shopConfigMap;
	// ***********************************
	// スケジュール定義により、起動場合
	// ***********************************
	public BulkBadRoomQtyStatBatch() {
		isFromSchedule = true;
	}
	// ***********************************
	// リクエストバッチから起動
	// ***********************************
	public BulkBadRoomQtyStatBatch(String pSpcd, Date pBegDt, Date pEndDt) {
		spcd = pSpcd;
		startDt = pBegDt;
		endDt = pEndDt;
		isFromSchedule = false;
	}
	// バッチ起動インスタンス化
	public BulkBadRoomQtyStatBatch(Date pBegDt, Date pEndDt, String pSpcd, Boolean pIsFromSchedule) {
		nowDt = Date.today();
		startDt = pBegDt;
		endDt = pEndDt;
		spcd = pSpcd;
		isFromSchedule = pIsFromSchedule;
	}
	// ***********************************
	// スケジュール処理開始
	// ***********************************
	public void execute(SchedulableContext SC) {
		BulkBadRoomQtyStatBatch batch = new BulkBadRoomQtyStatBatch(startDt, endDt, spcd, isFromSchedule);
		DataBase.executeBatch(batch,1);
	}
	
	// ***********************************
	// バッチ処理開始
	// ***********************************
	public List<TypeOfRooms__c> start(Database.BatchableContext BC){
		// 店舗コード
		set<String> shopcodeSet = new set<String>();
		// スケジュールから起動場合
		if (isFromSchedule) {
			List<ShopInformation__c> shops = [	
					SELECT 
	                Id
	                , Name
	                , ShopCode__c
	                From ShopInformation__c order by Seq__c limit 100];
	   		// Dumy Shop Info Create
			if (!shops.isEmpty()) {
	            for (ShopInformation__c shop : shops) {
	                shopcodeSet.add(shop.ShopCode__c);
	            }
			}
			//店舗なし対応
			if (shopcodeSet.isEmpty()) shopcodeSet.add('');
		} 
		// 手動でスケジュールを起動する
		else {
			// 指定店舗コードにより、店舗情報を取得する[店舗なし場合も対応]
			shopcodeSet.add(spcd);
		}
		// XML定義情報を取得する
		shopConfigMap = parseConfigXml(shopcodeSet);
		String xmlWhere = '';
		for (String spcd : shopcodeSet) {
			if (!shopConfigMap.containsKey(spcd)) continue;
			XmlConfig config = shopConfigMap.get(spcd);
			String condStr = config.toSqlString(spcd);
			if (CommUtils.isBLank(condStr)) continue;
			if (!CommUtils.isBlank(xmlWhere)) xmlWhere += ' OR ';
			xmlWhere += condStr;
		}
		// 部屋タイプ情報を取得する
		String sqlQuery = 'select id,name,RoomTypeCode__c,ShopInfoRef__r.ShopCode__c from TypeOfRooms__c where id != null ';
		// 数据条件设定
		if (!CommUtils.isBlank(xmlWhere)) sqlQuery += ' and (' + xmlWhere + ') ';
		return Database.query(sqlQuery);
	}
	// ***********************************
	// バッチロジック処理開始[BATCHのSIZEが１制限前提]
	// ***********************************
	public void execute(Database.BatchableContext BC, List<TypeOfRooms__c> rsLst){

		// 対象部屋タイプIDを格納する
		TypeOfRooms__c roomType = rsLst[0];
		set<Id> roomTypeIdSet = new set<Id>();
		roomTypeIdSet.add(roomType.Id);
		// 該当部屋タイプの店舗コードを取得する
		String curShopCd = CommUtils.nullToBlank(roomType.ShopInfoRef__r.ShopCode__c);
		// スケジュールからバッチ起動場合、開始日と終了日の期間はXML定義を参照する、定義する場合、該当定義により、期間計算する
		if (isFromSchedule) {
			XmlConfig config = shopConfigMap.get(curShopCd);
			// デフォルト値で自動設定する
			if (config == null) config = new XmlConfig();
			if(config.preDays != null) startDt = nowDt.addDays(-config.preDays);
			else startDt = nowDt.addMonths(-3);
			if(config.aftDays != null) endDt = nowDt.addDays(config.aftDays);
			else endDt = nowDt.addMonths(4);
		}
		// 在庫情報を集計する　
		StockChangeHelpUtils helpUtil = new StockChangeHelpUtils(true);
		// 対象期間
		List<Date> rangeList = helpUtil.getDateRange(startDt, endDt);
		set<Date> dateRangeSet = new set<Date>();
		dateRangeSet.addAll(rangeList);
		// 检索予约数据(以到着日处理)
		// 有効な予約情報を集計する　
		map<string, decimal> existLeadMap = helpUtil.queryExistLeadMap(roomTypeIdSet, dateRangeSet);
		// 检索故障数据
		map<string, decimal> beaRoomMap = helpUtil.queryBadRoomMap(roomTypeIdSet, dateRangeSet);
		// 做成データ集計数据集合
		map<String,DataSum__c> sumMap = new Map<String,DataSum__c>();
		// id,集計日,集計値,故障部屋数,予約数,部屋タイプ
		// 2020/06/15 故障部屋のレポートでのカウント機能 WGCH BEGIN
		// list<DataSum__c> DataSumLst = [select id,SumDate__c,RoomTypeRef__c from DataSum__c where RoomTypeRef__c = :roomTypeIdSet and SumDate__c = :dateRangeSet];
		list<DataSum__c> DataSumLst = [select id,SumDate__c,RoomTypeRef__c,RsvDataSumRef__c,StayPersons__c,AmountSumExc__c,AmountSumInc__c from DataSum__c where RoomTypeRef__c = :roomTypeIdSet and SumDate__c = :dateRangeSet];
		// 有效预约
		Integer leadCancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
		String roomTypeNormalFlg = CommConst.ROOMTYPE_NORMAL;
		// GROUP機能、部屋タイプ単位まで集計に変更する
		String leadQuery = ' Select StayPersons__c, refTypeOfRooms__c, EntryTime__c From Lead__c '+
					 		' Where CancelBool__c != :leadCancelFlg ' +
					 		' And DAY_ONLY(convertTimezone(EntryTime__c)) =: dateRangeSet ' +
					 		// 部屋タイプ種別=通常
					 		' And refTypeOfRooms__c in: roomTypeIdSet';
		List<Lead__c> leadLst = DataBase.query(leadQuery);
		// Key: (EntryTime__c).Date()「到着⽇」_refTypeOfRooms__c「房型ID」; Val: 予約⼈数
		Map<String, Decimal> stayPersonsSumMap = new Map<String, Decimal>();
		for(Lead__c ld : leadLst){
			String key = helpUtil.getRoomStockKey(ld.refTypeOfRooms__c, ld.EntryTime__c.date());
			if(!stayPersonsSumMap.containsKey(key)) stayPersonsSumMap.put(key, 0);
			// 予約⼈数集计
			Decimal stayPersonsSum = CommUtils.nullToZero(ld.StayPersons__c) + stayPersonsSumMap.get(key);
			stayPersonsSumMap.put(key, stayPersonsSum);
		}
		// 売上日处理
		List<String> whereDateLst = new List<String>();
		for(Date dt : dateRangeSet){
			// 該当日の売上存在がどうかチェックを行う
			DateTime wkDt = DateTime.newInstance(dt.year(), dt.month(), dt.day());
			String whereDate = wkDt.format('yyyyMMdd');
			whereDateLst.add(whereDate);
		}
		List<RsvAccount__c> existRsvAccLst = [select id, Salesday__c from RsvAccount__c where name in: whereDateLst for update];
		// Key: 売上日; Val: 売上ID
		Map<Date, Id> rsvAccMap = new Map<Date, Id>();
		for(RsvAccount__c rsv : existRsvAccLst){
			rsvAccMap.put(rsv.Salesday__c, rsv.Id);
		}
		// Key: (SalesdayCal__c)「売上日」_dRelreserve__r.RefTypeOfRooms__c「房型ID」; Val: $売上計III（税抜）金額
		Map<String, Decimal> amountSumExcMap = new Map<String, Decimal>();
		// Key: (SalesdayCal__c)「売上日」_dRelreserve__r.RefTypeOfRooms__c「房型ID」; Val: $売上計IV（税込）金額
		Map<String, Decimal> amountSumIncMap = new Map<String, Decimal>();
		// 有效会计处理
		List<AggregateResult> accRs = 
							[ select SalesdayCal__c salesday, Relreserve__r.RefTypeOfRooms__c refTypeOfRooms, sum(Field147__c) amountSumExc, sum(Field151__c) amountSumInc
								from AccountAcount__c
								where Field39__c !=: CommConst.ACC_TRADE_VOID And frs__c in: rsvAccMap.values() And Relreserve__r.RefTypeOfRooms__c in: roomTypeIdSet
								group by SalesdayCal__c, Relreserve__r.RefTypeOfRooms__c];
		for (AggregateResult rs : accRs) {
			String key = helpUtil.getRoomStockKey((Id)rs.get('refTypeOfRooms'), (Date)rs.get('salesday'));
			Decimal amountSumExc = (Decimal)rs.get('amountSumExc');
			Decimal amountSumInc = (Decimal)rs.get('amountSumInc');
			amountSumExcMap.put(key, amountSumExc);
			amountSumIncMap.put(key, amountSumInc);
		}
		// 2020/06/15 故障部屋のレポートでのカウント機能 WGCH END
		// 即存数据取得
		for(DataSum__c ds : DataSumLst){
			String key = helpUtil.getRoomStockKey(ds.RoomTypeRef__c, ds.SumDate__c);
			sumMap.put(key,ds);
		}
		list<DataSum__c> newDataSumLst = new list<DataSum__c>();
		for(Date dt : rangeList){
			for(Id roomtypeId: roomTypeIdSet){
				// キー作成
				String key = helpUtil.getRoomStockKey(roomtypeId, dt);
				// 获取データ集計数据
				DataSum__c OneDataSum = null;
				if (sumMap.containsKey(key)) OneDataSum = sumMap.get(key);
				else OneDataSum = new DataSum__c(SumDate__c = dt, RoomTypeRef__c = roomtypeId);
				// 获取予约数据
				Decimal leadNum = 0;
				if (existLeadMap.containsKey(key)) leadNum = CommUtils.nullToZero(existLeadMap.get(key));
				// 获取故障数据
				Decimal badroomNum = 0;
				if (beaRoomMap.containsKey(key)) badroomNum = CommUtils.nullToZero(beaRoomMap.get(key));	
				// 予約数と故障部屋数設定する
				OneDataSum.LeadSumVal__c = leadNum;
				OneDataSum.BedRoomSumVal__c = badroomNum;
				// 2020/06/15 故障部屋のレポートでのカウント機能 WGCH BEGIN
				// 売上
				if(rsvAccMap.containsKey(dt)) OneDataSum.RsvDataSumRef__c = rsvAccMap.get(dt);
				if(stayPersonsSumMap.containsKey(key)) OneDataSum.StayPersons__c = stayPersonsSumMap.get(key);
				if(amountSumExcMap.containsKey(key)) OneDataSum.AmountSumExc__c = amountSumExcMap.get(key);
				if(amountSumIncMap.containsKey(key)) OneDataSum.AmountSumInc__c = amountSumIncMap.get(key);
				// 2020/06/15 故障部屋のレポートでのカウント機能 WGCH END
				newDataSumLst.add(OneDataSum);
			}
		}
		// 插入数据
		if (!newDataSumLst.isEmpty()) upsert newDataSumLst;
	}
	
	// ***********************************
    // バッチ終了処理開始
    // ***********************************
    public void finish(Database.BatchableContext BC){
    	setEmailMessage();
    }
    // メール情報
    private void setEmailMessage(){
		// メール情報を設定する
		String mailAdds = CommDefine__c.getOrgDefaults().ScheduleResultMailAddress__c;
		if(CommUtils.isBlank(mailAdds)) return;
		// メール情報を設定する
		String mailBodyStr = '';
		
		Map<String, ShopInformation__c> shopInfoMap = ShopInfoUtil.getShopInfoMap();
		String spcdName = '';
			
		for (String key : shopConfigMap.keyset()) {
			if(isFromSchedule) {
				// 定義情報を取得する
				XmlConfig config = shopConfigMap.get(key);
				// デフォルト値で自動設定する
				if (config == null) config = new XmlConfig();
				if(config.preDays != null) startDt = nowDt.addDays(-config.preDays);
				else startDt = nowDt.addMonths(-3);
				if(config.aftDays != null) endDt = nowDt.addDays(config.aftDays);
				else endDt = nowDt.addMonths(4);
			}
			
			// 店铺判断
			if(!shopInfoMap.isEmpty() && shopInfoMap.containsKey(key)) spcdName = CommUtils.nullToBlank(shopInfoMap.get(key).Name);
			if(!CommUtils.isBlank(spcdName)) mailBodyStr += '\n店舗： ' + spcdName ;
			mailBodyStr += '\n故障部屋集計処理が完了しました（期間:' + startDt.format() + '-' + endDt.format() + '）\n';
		}
		mailBodyStr += '\n\nJinyaConnect Enterprise system R&D team.';
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = mailAdds.split(',');
		mail.setToAddresses(toAddresses);
		mail.setSubject('[故障部屋集計] バッチ処理結果の通知['+UserInfo.getOrganizationName()+']');
		mail.setPlainTextBody(mailBodyStr);
		// テストクラスの場合、実施しない
		if(!Test.isRunningTest()) {
			try {
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
			} catch(Exception e){
System.debug(logginglevel.info,'mailBodyStr='+mailBodyStr);
			}
		}
	
	}
	// XML情報分析と格納
	private map<String, XmlConfig> parseConfigXml(set<String> shopcodeSet) {
		// 2020/02/01 XML定义不生效修正 BY zyz BEGIN
		// 店舗別XML定義情報を格納する
		map<String, XmlConfig> shopConfigMap = new map<String, XmlConfig>();
		// Default定義NODE
		XmlConfig defConfig = null;
		try{
			String docName = 'BatchRequstConfigXml';
			List<Dom.XmlNode> shopRootList = CommXmlUtils.getAllTopXmlNode(docName);
			for (Dom.XmlNode shopRoot : shopRootList) {
				// 店舗コード
	   	 		Dom.XmlNode shopCodeField =  shopRoot.getChildElement('SHOPCODE', null);
				String shopcode = CommUtils.nullToBlank(shopCodeField.getText());
				// 対象外の店舗コード場合 または　デフォルト設定情報を取得済み場合、次の処理SKIP
				if (!shopcodeSet.contains(shopcode) && defConfig != null) continue;
				// 設定情報解析
				Dom.XmlNode nodeRequestBatch =  shopRoot.getChildElement('REQUEST_BATCH', null);
			  	if (nodeRequestBatch != null) {
			  		// BATCH LOOP
			  		for (Dom.XmlNode nodeBatch : nodeRequestBatch.getChildElements()) {
			  			// BATCH NODE
			  			if(nodeBatch != null){
			  				Dom.XmlNode batchKeyField = nodeBatch.getChildElement('BATCHKEY', null);
			  				// BadRoomSum以外の場合、SKIP
			  				if (BatchControlCenter.BATCH_KEY_ROOM_STATUS != CommXmlUtils.getChildElementValue(batchKeyField)) continue;
			  				// 定義情報解析
			  				XmlConfig config = new XmlConfig(nodeBatch);
							// 店舗コード別格納する
							if (shopcodeSet.contains(shopcode)) shopConfigMap.put(shopcode, config);
							// デフォルト値を格納する
							if (defConfig == null) defConfig = config;
			  			}
			  		}
			  	}
			}
		} catch(Exception e){}
		if (defConfig != null) {
			for (String spcd : shopcodeSet) {
				if (!shopConfigMap.containsKey(spcd)) shopConfigMap.put(spcd, defConfig);
			}
		}
		return shopConfigMap;
	}
	// XML定義情報を格納する
	public class XmlConfig{
		//public String shopCode{get;set;}	// 店铺code
		public String whereStr{get;set;}	// 对应的店铺的条件
		public Integer preDays{get;set;}//処理日からN日数
		public Integer aftDays{get;set;}//処理日以後N日数
		public XmlConfig(){}
		public XmlConfig(Dom.XmlNode nodeBatch){
			whereStr = CommXmlUtils.getChildElementByName(nodeBatch, 'PROCESSWHERE');
			string begStr = CommXmlUtils.getChildElementByName(nodeBatch, 'PROCESSBEG');
			string endStr = CommXmlUtils.getChildElementByName(nodeBatch, 'PROCESSEND');
			if (!CommUtils.isBlank(begStr)) preDays = CommUtils.nullToIntZero(begStr);
			if (!CommUtils.isBlank(endStr)) aftDays = CommUtils.nullToIntZero(endStr);
		}
		public String toSqlString(String shopCde){
			if (CommUtils.isBlank(whereStr) && !CommUtils.isBlank(CommUtils.nullToBlank(shopCde))) return ' ShopInfoRef__r.ShopCode__c = \''+String.escapeSingleQuotes(CommUtils.nullToBlank(shopCde)) +'\' ';
			else if (CommUtils.isBlank(whereStr)) return '';
			else return (' (('+ whereStr + ') and ShopInfoRef__r.ShopCode__c = \''+String.escapeSingleQuotes(CommUtils.nullToBlank(shopCde)) +'\' )' );
		}
	}
}