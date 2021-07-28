/**
* 在庫変更履歴共通トリガー
**/
public with sharing class StockChangeHisotryTriggerProcess {
	/**
	* 項目情報の自動設定機能対応
	**/
	public void autoSetupValue(StockChangeHisotry__c[] nwList, StockChangeHisotry__c[] odList, CommConst.TriggerMethod action) {
		for (StockChangeHisotry__c nw : nwList) {
			if (nw.StockChangeDate__c != null) {
				Date d = nw.StockChangeDate__c;
				if (d != null && CommUtils.isBlank(nw.StockChangeDateKey__c)) {
					nw.StockChangeDateKey__c = (Datetime.newInstance(d.year(), d.month(), d.day())).format('yyyyMMdd');
				}
			}
		}
	}
	/**
	* TL側のキャンセル発行する場合、SF側にTL連携ステータスは論理連携済のデータが存在すると、
	* 該当論理連携済のデータの連携ステータスは「未連携」に変更、再連携を行う
	**/
	public void tlMeragerLogicStockInfo(StockChangeHisotry__c[] nwList, StockChangeHisotry__c[] odList, CommConst.TriggerMethod action){
		if (action != CommConst.TriggerMethod.IsInsert) return;
		//map<String, list<
		set<date> stockDateSet = new set<Date>();
		set<id> stockRoomTypeIdset = new set<Id>();
		map<string, list<StockChangeHisotry__c>> tlCancelInfoMap = new map<string, list<StockChangeHisotry__c>>();
		Date currDate = Date.today();
		for (StockChangeHisotry__c nw : nwList) {
			// TL側からキャンセルする場合
			if (nw.CreateSource__c == CommConst.BI_PROCESS_TYPE.TL.Name() &&
				nw.StockChangeCnt__c > 0 &&
				nw.StockChangeDate__c >= currDate) {
				// 同じ日付、同じ部屋タイプに論理連携済対象が存在チェックを行う
				String key = nw.TypeOfRoomRef__c + '_' + nw.StockChangeDate__c.format();
				if (!tlCancelInfoMap.containsKey(key)) tlCancelInfoMap.put(key, new list<StockChangeHisotry__c>());
				tlCancelInfoMap.get(key).add(nw);
				// 検索用条件を格納する
				stockRoomTypeIdset.add(nw.TypeOfRoomRef__c);
				stockDateSet.add(nw.StockChangeDate__c);
			}
		}
		if (stockDateSet.isEmpty()) return;

		// 既存の論理連携情報存在チェックを行う
		String ltSyncLogicOK = TL_StockAdjustmentBatch.STOCK_STATUS_LOGIC_SYNCOK;
		map<String, list<StockChangeHisotry__c>> logicSyncOkMap = new map<String, list<StockChangeHisotry__c>>();
		// 2018/06/04 20万件検索問題回避対応 BEGIN
		Boolean isFixedFlg = DataFixManagerUtils.getInstance().StockChangeHisotryFixed__c;
		set<string> targetDtSet = new set<string>();
		if (isFixedFlg) {
			for (Date d : stockDateSet) targetDtSet.add((Datetime.newInstance(d.year(),d.month(),d.day())).format('yyyyMMdd'));
		}
		/*
		for (StockChangeHisotry__c stock : [select TypeOfRoomRef__c,StockChangeDate__c,StatusLst__c
						from StockChangeHisotry__c
						Where StockChangeDate__c = :stockDateSet
						And TypeOfRoomRef__c = :stockRoomTypeIdset
						And StatusLst__c = :ltSyncLogicOK]) {*/
		String queryStr = 'select TypeOfRoomRef__c,StockChangeDate__c,StatusLst__c from StockChangeHisotry__c '+
						' Where TypeOfRoomRef__c = :stockRoomTypeIdset And StatusLst__c = :ltSyncLogicOK ';
		if (DataFixManagerUtils.getInstance().StockChangeHisotryFixed__c) {
			queryStr += ' And StockChangeDateKey__c = :targetDtSet';
		} else{
			queryStr += ' And StockChangeDate__c = :stockDateSet';
		}
		for (StockChangeHisotry__c stock : DataBase.query(queryStr)) {
		// 2018/06/04 20万件検索問題回避対応 END
			String key = stock.TypeOfRoomRef__c + '_' + stock.StockChangeDate__c.format();
			// TL側からキャンセル対象がない場合、関連処理対象外
			if (!tlCancelInfoMap.containsKey(key)) continue;
			
			if (!logicSyncOkMap.containskey(key)) logicSyncOkMap.put(key, new list<StockChangeHisotry__c>());
			logicSyncOkMap.get(key).add(stock);
		}
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'statuslst__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.StockChangeHisotry__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
			return ;
		}
		// 2019/09/15 Security Check BY zyz END
		List<StockChangeHisotry__c> updLst = new List<StockChangeHisotry__c>();
		for (String key : logicSyncOkMap.keyset()) {
			list<StockChangeHisotry__c> logicOkLst  = logicSyncOkMap.get(key);
			list<StockChangeHisotry__c> tlCancelLst = tlCancelInfoMap.get(key);
			Integer maxLen = logicOkLst.size() > tlCancelLst.size() ? tlCancelLst.size() : logicOkLst.size();
			for (Integer i=0; i<maxLen; i++) {
				StockChangeHisotry__c logicOkStock = logicOkLst[i];
				logicOkStock.StatusLst__c = TL_StockAdjustmentBatch.STOCK_STATUS_NOSYNC;
				updLst.add(logicOkStock);
			}
		}
		if (!updLst.isEmpty()) update updLst;
	}
	
	// 在庫変更により、物理在庫数情報を設定・更新を行う　
	public void calStockInfoByChangeHis(StockChangeHisotry__c[] nwList, StockChangeHisotry__c[] odList, CommConst.TriggerMethod action){
//System.debug(logginglevel.info,'calStockInfoByChangeHis begin');
		if (action != CommConst.TriggerMethod.IsInsert) return;
		// 2017/09/04 性能問題解消対応 BEGIN
		// フラグはTRUEの場合、在庫管理データを作成する
		if (!CommConst.STOCK_CREATE_NOFITYDATA_FLG) return;
//System.debug(logginglevel.info,'calStockInfoByChangeHis begin2');
		// 2017/09/04 性能問題解消対応 END
		// 在庫変更履歴により、在庫変更履歴情報を設定する
		// 指定の部屋タイプ
		//Map<String,StockChangeHisotry__c>
		// 指定の部屋タイプID,指定の日付、在庫残室数を計算する
		set<Id> roomTypeIds = new set<Id>();
		set<Date> entryDts = new set<Date>();
		for (StockChangeHisotry__c stock : nwList) {
			// 指定の部屋タイプID　＆＆　日付により、
			roomTypeIds.add(stock.TypeOfRoomRef__c);
			entryDts.add(stock.StockChangeDate__c);
		}
		if (roomTypeIds.isEmpty()) return;
		// 部屋タイプの最大在庫数を取得する
    	map<Id,Decimal> roomTypeMap = new map<Id, Decimal>();
    	List<TypeOfRooms__c> rommTypesLst = [select id, MaxRooms__c from TypeOfRooms__c where id in :roomTypeIds And SumNotApplicableFlg__c != TRUE ];
		for (TypeOfRooms__c rType : rommTypesLst) {
			roomTypeMap.put(rType.Id, CommUtils.nullToZero(rType.MaxRooms__c));
		}
		// SF該当タイミングの実際在庫数を取得する
		// 有効の予約情報を取得
		// 故障部屋の情報を取得する
		// 最大数から減算する
		StockChangeHelpUtils helpUtils = new StockChangeHelpUtils();
		map<string, Decimal> usdRoomsMap = helpUtils.getStockUsedInfo(roomTypeMap.keyset(),entryDts);
		// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
		map<string, GuestRoomStock__c> guestRoomsMap = helpUtils.getGuestRoomInfo(roomTypeMap.keyset(),entryDts);
		// 2018/12/15 在庫調整と販売状態管理 by zy END
		// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH BEGIN
		Map<String, Boolean> notAgtSettingFlgMap = new Map<String, Boolean>();
		// キー別最大在庫数情報を格納する
		Map<string, Integer> maxAGTRoomsMap = new Map<string, Integer>();
		// 在庫联动功能开启
		if(StockChangeHelpUtils.isStockSyncIsMode == StockChangeHelpUtils.STOCK_SYNC_MODE_0){
			// 存在设定的部屋在库管理数据
			for (GuestRoomStock__c wkStock : guestRoomsMap.values()){
				// 未设定过的标识FLG
				notAgtSettingFlgMap.put(wkStock.ManagerKey__c, CommUtils.isBlank(wkStock.AGTChangeRoomsJSON__c));
			}
			// 获取AGT最大在库数
			Map<String, Decimal> realAGTRoomMap = StockChangeHelpUtils.getAgtMaxRoomsMap(roomTypeMap.keyset(),entryDts);
			for(String wkKey : realAGTRoomMap.keySet()){
				// 取引先Id_部屋タイプId_在库日
				List<String> wkKeyLst = wkKey.split('_');
				if(wkKeyLst.size() != 3) continue;
				String wkManagerKey = wkKeyLst[1] + '_' + wkKeyLst[2];
				// 存在设定过AGT-JSON的情况跳到下一个循环
				if((notAgtSettingFlgMap.containsKey(wkManagerKey) && !notAgtSettingFlgMap.get(wkManagerKey))) continue;
				// 集计 部屋タイプId_在库日 的AGT最大在库数
				if(!maxAGTRoomsMap.containsKey(wkManagerKey)) maxAGTRoomsMap.put(wkManagerKey, 0);
				// 累计处理
				Integer wkMaxRooms = CommUtils.nullToIntZero(realAGTRoomMap.get(wkKey)) + maxAGTRoomsMap.get(wkManagerKey);
				maxAGTRoomsMap.put(wkManagerKey, wkMaxRooms);
			}
		}
		// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH END
		set<string> dupKeyFilterSet = new set<string>();
//System.debug(loggingLevel.info, 'usdRoomsMap='+usdRoomsMap);
		List<GuestRoomStock__c> upsertLst = new List<GuestRoomStock__c>();
		// TEST LOG BEGIN
		CommLogUtils log = new CommLogUtils('StockChangeHisotryTriggerProcess', true);
		log.write_method_start('calStockInfoByChangeHis');
		// TEST LOG END
		// 残室数を取得、計算して、通知情報はオブジェクトに格納する
		for (StockChangeHisotry__c stock : nwList) {
			// TEST LOG BEGIN
			log.write_log('STOCK：'+stock);
			// TEST LOG END
			// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
			if(stock.SettingFlg__c) continue;
			// 2018/12/15 在庫調整と販売状態管理 by zy END
			Id roomTypeId = stock.TypeOfRoomRef__c;
			String key = helpUtils.getRoomStockKey(stock.TypeOfRoomRef__c, stock.StockChangeDate__c);
//System.debug(loggingLevel.info, 'key='+key);
			// 既に作成の情報は再度処理を行わない
			if (dupKeyFilterSet.contains(key)) continue;
			dupKeyFilterSet.add(key);
			if (!roomTypeMap.containsKey(roomTypeId)) continue;
			// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
			Decimal maxRooms = guestRoomsMap.containsKey(key) ? CommUtils.nullToZero(guestRoomsMap.get(key).MaxRoomsCal__c) : CommUtils.nullToZero(roomTypeMap.get(roomTypeId));
			// 2018/12/15 在庫調整と販売状態管理 by zy END
			// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH BEGIN
			// 减掉满足条件下AGT的最大在库数(例如: 房间最大在库数15, AGT的最大在库数5, 即满足条件后最大残室数 15 - 5 = 10)
			if(maxAGTRoomsMap.containsKey(key)) maxRooms -= CommUtils.nullToIntZero(maxAGTRoomsMap.get(key));
			// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH END
			Decimal usdRooms = CommUtils.nullToZero(usdRoomsMap.get(key));
//System.debug(loggingLevel.info, 'maxRooms='+maxRooms);
//System.debug(loggingLevel.info, 'usdRooms='+usdRooms);
			GuestRoomStock__c notify = new GuestRoomStock__c(
				ManagerKey__c = key,
				QtyOfStock__c = (maxRooms - usdRooms),
				StockDate__c = stock.StockChangeDate__c,
				RoomTypeRef__c = roomTypeId
			);
			// TEST LOG BEGIN
			log.write_log('notify：'+notify);
			// TEST LOG END
//System.debug(loggingLevel.info, 'notify='+notify);
			upsertLst.add(notify);
		}
		log.write_log('upsertLst：'+upsertLst);
		try {
			if (!upsertLst.isEmpty()) DataBase.upsert(upsertLst, GuestRoomStock__c.ManagerKey__c);
		} catch(exception e) {
			log.write_error(e.getMessage());
			log.write_error(e.getStackTraceString());
			log.write_method_end();
			CommLogUtils.LogDefine logDef = new CommLogUtils.LogDefine();
			logDef.docName = 'STOCK_LOG';
			CommLogUtils.saveLogToDb(log.getAllLog(),logDef);
		}
	}
}