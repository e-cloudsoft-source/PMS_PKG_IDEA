/*********************************************
* 予約の関連トリガー処理を行う
* 2015/05/11 支払情報は見積明細に入力できるように対応するため、チェックインのタイミング
*            支払情報は会計支払メデイアに作成を行う
* 2015/07/26 部屋から自動部屋タイプを紐付く機能が追加する
* 2015/12/14 予約取込プランフラグは変更する場合、予約のプランから見積明細に反映を行わない
* 2015/12/16 ルームインジケータ画面から同じ部屋タイプ内部に部屋変更すると、発生源更新される不具合改修
* 2017/07/15 チェックアウト通知対象外機能対応
* 2019/06/14 ご予約内にある「プラン」という項目を入力すると予約見積明細にもこのプランが登録されますが、こちらを登録しない設定にしたいです。
* 2019/07/30 連泊予約の2泊目以降の予約には宿帳自動作成
* 2019/07/30 複数部屋に自動で宿帳作成改善対応
* 2019/09/23 取引先に紐づくお客様の予約を、取引先の画面で表示するように改善対応
* 2020/05/15 到着日を変更した際に紐づいている予約見積明細の利用日も自動変更する機能対応
*********************************************/
public with sharing class LeadTriggerProcess {
	// 予約人数と予約見積明細の数量連動制御フラグ
	private static final Boolean leadStayPersonsIsSyncToEstitemFlg = CommConst.APPOTION_LEAD_STAYPERSIONS_SYNCTO_ESTITEM_FLG;
	//2016/12/27 会計人數自動設定機能封印 BEGIN by zh
	// 会計画面の予約人數は０人のとき、自動男性、女性、子供人數から集計値を自動設定する、しない制御
	private static final Boolean AccounntStayPersonsAutoSetupFlg = CommDefine__c.getOrgDefaults().AccounntStayPersonsAutoSetupFlg__c == null ? false : CommDefine__c.getOrgDefaults().AccounntStayPersonsAutoSetupFlg__c;
	//2016/12/27 会計人數自動設定機能封印 END by zh
	
	public LeadTriggerProcess() {}

	/**
	* 部屋タイプ単位で、部屋使用数計算を行う
	**//*
	private void calRoomStockByRoomType(Date procDt, Map<Id, Map<Date ,Integer>> stockMap, Id roomTypeId, Integer usedRoom) {
		// 部屋タイプが未設定する場合、処理終了
		if (roomTypeId == null) return;
		// 該当部屋タイプに既に定義情報が存在する場合
		if (stockMap.containsKey(roomTypeId)) {
			Map<Date ,Integer> usedRoomsMap = stockMap.get(roomTypeId);
			if (usedRoomsMap.containsKey(procDt)) {
				usedRoomsMap.put(procDt, usedRoomsMap.get(procDt) + usedRoom);
			} else{
				usedRoomsMap.put(procDt, usedRoom);
			}
		} else {
			Map<Date ,Integer> usedRoomsMap = new Map<Date ,Integer>();
			usedRoomsMap.put(procDt, usedRoom);
			stockMap.put(roomTypeId, usedRoomsMap);
		}
	}*/
	/**
	* 予約画面から、予約新規データを作成すると予約更新：ステータスは予約
	* 部屋在庫情報連携処理を行う
	* 2012/08/30 E/B連携機能追加/2012/09/07 該当E/B連携機能削除
	* 2013/06/20 部屋タイプ変更に従って、在庫数処理ロジック追加対応 
	* After Insert/ After Update
	**//*
	public void syncGuestRoomStock(Lead__c[] newList, Lead__c[] oldList, CommConst.TriggerMethod action){
        //Map<部屋タイプID, 残室数>
        Map<Id, Map<Date ,Integer>> stockMap = new Map<Id, Map<Date ,Integer>>();
        //List<String>
        Set<Date> checkInSet = new Set<Date>();
        List<Date> checkinLst = new List<Date>();
        // E/B連携情報格納用
        //Map<Date, Decimal> ebUsedRoomMap = new Map<Date, Decimal>();
        // 新規場合
        if (action == CommConst.TriggerMethod.IsInsert) {
            for (Lead__c nw : newList) {
            	// 新作成のデータに対して、ステータスは（'NO SHOW'/'キャンセル'/'削除'）場合、処理対象外
            	if (!isLeadOK(nw.ReservedStatus__c)) continue;
            	// 部屋タイプ未設定する場合、処理対象外
            	if (nw.refTypeOfRooms__c == null) continue;

            	// チェックイン日
            	Date checkinDate = nw.EntryTime__c.date();
//System.debug('------checkinDate:------' + checkinDate);
            	// チェックイン日範囲を設定する
            	//checkinLst.add(checkinDate);
            	checkInSet.add(checkinDate);
                // 処理対象データに対して、残室更新処理を行う
                if (stockMap.containsKey(nw.refTypeOfRooms__c)) {
                	//該当日付のルーム数を計算する
                	Map<Date ,Integer> roomTypeMap = stockMap.get(nw.refTypeOfRooms__c);
                	// 非存在する場合
					if (roomTypeMap.containsKey(checkinDate)) roomTypeMap.put(checkinDate, roomTypeMap.get(checkinDate) + 1);
					else roomTypeMap.put(checkinDate, 1);
                } else {
                	Map<Date ,Integer> roomTypeMap = new Map<Date ,Integer>();
                	roomTypeMap.put(checkinDate, 1);
                	stockMap.put(nw.refTypeOfRooms__c, roomTypeMap);
                }
                // E/B合計計算
                //if (nw.ExtraBedChk__c) ebUsedRoomMap.put(checkinDate, CommUtils.nullToZero(ebUsedRoomMap.get(checkinDate)) + 1);
            }
        }
        // 更新場合
        else if (action == CommConst.TriggerMethod.IsUpdate) {
            Integer lstSize = newList.size();
            for (Integer i=0; i<lstSize; i++) {
            	Lead__c nw = newList[i];
            	Lead__c od = oldList[i];
            	// 部屋タイプ未設定する場合、処理対象外
            	if (nw.refTypeOfRooms__c == null) continue;
            	// チェックイン日
            	Date checkinDate = nw.EntryTime__c.date();
            	// チェックイン日範囲を設定する
            	//checkinLst.add(checkinDate);
            	checkInSet.add(checkinDate);

            	// ステータス変更場合「キャンセルなどに変更する場合」
            	if (nw.ReservedStatus__c != od.ReservedStatus__c) {
            		// 有効な予約データから無効な予約データに変更する場合,在庫数「１」が減らす
            		if (!isLeadOK(nw.ReservedStatus__c) && isLeadOK(od.ReservedStatus__c)) {
                        // 有効→無効に変更する場合、元有効の予約データに定義している使用している部屋使用数は１を減らす
                        calRoomStockByRoomType(checkinDate, stockMap,od.refTypeOfRooms__c, -1);
            		} else {
            			// 無効から有効に変更する場合、変更先設定した部屋タイプの部屋使用数は１
            			calRoomStockByRoomType(checkinDate, stockMap,nw.refTypeOfRooms__c, 1);
            		}
            	} else {
	            	// 部屋タイプを変更される場合 && ステータス変更されない場合
	            	if (nw.refTypeOfRooms__c != od.refTypeOfRooms__c ) {
	            		// 変更元の予約データは無効な予約データ場合、部屋数再計算を行わない
	            		if (isLeadOK(od.ReservedStatus__c)) {
		            		// 旧部屋タイプの部屋利用数は１を減らす
		            		calRoomStockByRoomType(checkinDate, stockMap, od.refTypeOfRooms__c, -1);
	            		}
	            		// 変更先の予約データは無効な予約データ場合、部屋数再計算を行わない
	            		if (isLeadOK(nw.ReservedStatus__c)) {
		            		// 新部屋タイプの部屋利用数は１を増える
		            		calRoomStockByRoomType(checkinDate, stockMap, nw.refTypeOfRooms__c, 1);
	            		}
	            	}
            	}
            }
        }
//System.debug('-------------- [stockMap] ----------'+ stockMap);
//System.debug('-------------- [ebUsedRoomMap] ----------'+ ebUsedRoomMap);
		if (stockMap.isEmpty()) return;
        // チェックイン日範囲を取得を行う
		checkinLst.addAll(checkInSet);
        checkinLst.sort();
        Date beginDate = checkinLst[0];
        Date endDate = checkinLst[checkinLst.size()-1];
        List<GuestRoomStock__c> updList = new List<GuestRoomStock__c>();
        List<GuestRoomStock__c> insList = new List<GuestRoomStock__c>();
        // 部屋在庫データ更新を行う
        if (!stockMap.isEmpty()) {
        	Map<Id, Set<Date>> queryRommTypeIdSet = new Map<Id, Set<Date>>();
        	// 既存の在庫管理データを取得する
        	Map<String, GuestRoomStock__c> existStockMap = new Map<String, GuestRoomStock__c>();
	        for (GuestRoomStock__c item : [ select id, QtyOfStock__c, StockDate__c, RoomTypeRef__c from GuestRoomStock__c
                                            where RoomTypeRef__c in :stockMap.keySet()
						                    And RoomTypeRef__r.ActionType__c = :CommConst.ROOMTYPE_NORMAL
						                    And StockDate__c >= :beginDate And StockDate__c <= :endDate for update]) {
	            // 既存の在庫管理データ情報を格納する
                existStockMap.put(getRoomStockKey(item.RoomTypeRef__c, item.StockDate__c), item);
            }
	        // 予約情報にて、在庫データ更新を行う
        	for (Id roomTypeId : stockMap.keySet()) {
        		// 各日単位の在庫情報を設定する
        		Map<Date,Integer> unitRoomTypeStock = stockMap.get(roomTypeId);

        		for (Date dt : unitRoomTypeStock.keySet()) {
                    String key = getRoomStockKey(roomTypeId, dt);
                    // 既存在庫管理データを探す、存在すれば、在庫数を計算を行う
                    if (existStockMap.containsKey(key)) {
                    	GuestRoomStock__c updSobj = existStockMap.get(key);
                    	updSobj.QtyOfStock__c = updSobj.QtyOfStock__c - unitRoomTypeStock.get(dt);
                    	updList.add(updSobj);
                    	// 新規作成対象外になる
                    	existStockMap.remove(key);
                    }
                    // 非存在場合、該当日の在庫最大数を自動作成して、更新を行う
                    else {
						if (queryRommTypeIdSet.containsKey(roomTypeId)) {
							queryRommTypeIdSet.get(roomTypeId).add(dt);
						} else {
							Set<Date> dtSet = new Set<Date>();
							dtSet.add(dt);
							queryRommTypeIdSet.put(roomTypeId, dtSet);
						}
                    }
        		}
        	} // for (Id roomTypeId : stockMap.keySet()) {

        	// 新規部屋在庫データ作成必要場合
            // 新規作成用
            //List<GuestRoomStock__c> insList = new List<GuestRoomStock__c>();
        	if (!queryRommTypeIdSet.isEmpty()) {
        		// 部屋タイプ設定情報を取得する
	            Map<Id, TypeOfRooms__c> mstTypeOfRoomMap = new Map<Id, TypeOfRooms__c> (
	                               [select id, Name, MaxRooms__c from TypeOfRooms__c
									where ActionType__c = :CommConst.ROOMTYPE_NORMAL And MaxRooms__c != null And Id in :queryRommTypeIdSet.keySet()]);
                for (Id roomTypeId : queryRommTypeIdSet.keySet()) {
	                // 各日単位の在庫情報を設定する
	                Map<Date,Integer> unitRoomTypeStock = stockMap.get(roomTypeId);
					Set<Date> insDtSet = queryRommTypeIdSet.get(roomTypeId);

                	for (Date dt : unitRoomTypeStock.keySet()) {
                		if (!insDtSet.contains(dt)) continue;
		                GuestRoomStock__c newStockObj = new GuestRoomStock__c();
		                newStockObj.StockDate__c = dt;
		                // 2013/02/26 MaxRooms__c : NULL -> 0
		                newStockObj.QtyOfStock__c = CommUtils.nullToZero(mstTypeOfRoomMap.get(roomTypeId).MaxRooms__c) - unitRoomTypeStock.get(dt);
		                newStockObj.RoomTypeRef__c = roomTypeId;
		                newStockObj.Name = getRoomStockKey(roomTypeId, dt);
		                insList.add(newStockObj);
                	}
                }

        	} // if (!queryRommTypeIdSet.isEmpty()) {

        } // if (!stockMap.isEmpty()) {


//        for(GuestRoomStock__c item : [select id, QtyOfStock__c,RoomTypeRef__c from GuestRoomStock__c where RoomTypeRef__c in :stockMap.keySet()]){
//            item.QtyOfStock__c = item.QtyOfStock__c - stockMap.get(item.RoomTypeRef__c);
//            updList.add(item);
//        }
        if (!updList.isEmpty()) update updList;
        if (!insList.isEmpty()) insert insList;
	}
    // 予約ステータス状態の判定
    private boolean isLeadOK(String status) {
    	return (
    	       status != CommConst.LEAD_ST_NOSHOW &&
    	       status != CommConst.LEAD_ST_DELETE &&
    	       status != CommConst.LEAD_ST_CANCEL );
    }
    // 予約データ識別用キー作成
    private String getRoomStockKey(Id rommTypeId, Date dt) {
        if (rommTypeId == null) return DateTime.newInstance(dt,Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd HH:mm:ss');
        else return rommTypeId + '_' + DateTime.newInstance(dt,Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd HH:mm:ss');
    }*/
    /*
    * 予約情報のプランを設定されている場合、自動的にプランの明細商品は見積り明細を作成する
    * 実施タイミング：Insert/After;  Update/After
    */
    public void autoSetupBookingItemByPlan (Lead__c[] newList, Lead__c[] oldList, CommConst.TriggerMethod action){
        // 2019/06/14 ご予約内にある「プラン」という項目を入力すると予約見積明細にもこのプランが登録されますが、こちらを登録しない設定にしたいです。 by zy BEGIN
        if (CommConst.LEAD_AUTO_CREATE_BOOKINGEST) return;
        // 2019/06/14 ご予約内にある「プラン」という項目を入力すると予約見積明細にもこのプランが登録されますが、こちらを登録しない設定にしたいです。 by zy END
        // 予約ID/プランID
        Map<Id,Id> leadIdMap = new Map<Id,Id>();
        Map<Id,Lead__c> leadInfoMap = new Map<Id, Lead__c>();
        Map<Id,Id> delPlanIdMap = new Map<Id,Id>();
        Map<Id,String> syncInfoMap = new Map<Id, String>(); //予約に格納しているプランカスタムマイズ情報
        Set<Id> allPlanIdSet = new Set<Id>();

        if (action == CommConst.TriggerMethod.IsInsert) {
            // プラン情報設定されている場合
            for (Lead__c nw: newList) {
                // 2019/06/14 ご予約内にある「プラン」という項目を入力すると予約見積明細にもこのプランが登録されますが、こちらを登録しない設定にしたいです。 by zy BEGIN
                if (nw.Field310__c != null && !nw.planSycnFlag__c) {
                    // 2019/06/14 ご予約内にある「プラン」という項目を入力すると予約見積明細にもこのプランが登録されますが、こちらを登録しない設定にしたいです。 by zy END
            		leadIdMap.put(nw.Id, nw.Field310__c);
            		syncInfoMap.put(nw.Id, nw.PlanDetailSyncInfo__c);//連携情報格納
            	}
                leadInfoMap.put(nw.Id, nw);
            }
        } else if (action == CommConst.TriggerMethod.IsUpdate) {
            // プランを変更されている　かつ　変更後のプランが存在する場合
            Integer index = 0;
            for (Lead__c nw: newList) {
                Lead__c od = oldList[index];
                // 2015/12/14 予約取込プランフラグは変更する場合、予約のプランから見積明細に反映を行わない BEGIN
                if (nw.planSycnFlag__c != od.planSycnFlag__c) {
                    index++;
                    continue;
                }
                // 2015/12/14 予約取込プランフラグは変更する場合、予約のプランから見積明細に反映を行わない END
                // プラン情報を変更することがある場合
                // 2015/02/25 制御フラグを追加する
                if (
                	((	nw.Field310__c != od.Field310__c ||
                		nw.StayPersons__c != od.StayPersons__c) &&
                	 	leadStayPersonsIsSyncToEstitemFlg == true )	// 予約人数と予約見積明細の数量連動制御フラグTRUEの場合、人數変更すると、見積明細の数量も変更を行う
                	||
                	(	nw.Field310__c != od.Field310__c  &&
                		leadStayPersonsIsSyncToEstitemFlg != true)	// // 予約人数と予約見積明細の数量連動制御フラグFALSEの場合、プラン変更のみ、見積明細連動を行う
                ) {
                    // 削除予定のプランID
                    if (od.Field310__c != null) delPlanIdMap.put(od.Id, od.Field310__c);
                    // 新規追加予定プランID
                    if (nw.Field310__c != null) {
                    	leadIdMap.put(nw.Id, nw.Field310__c);
                    	if (nw.PlanDetailSyncInfo__c != od.PlanDetailSyncInfo__c) {// プランに格納するプラン明細カスタムマイズ情報は見積明細へ連携必要
                    		syncInfoMap.put(nw.Id, nw.PlanDetailSyncInfo__c);
                    	}
                    }
                }
                index++;
                leadInfoMap.put(nw.Id, nw);
            }
        }
        allPlanIdSet.addAll(leadIdMap.values());
        allPlanIdSet.addAll(delPlanIdMap.values());
        // 処理対象なし、処理終了
        if (allPlanIdSet.isEmpty()) return;

        // プラン関連の会計商品（プラン）を取得する
        Map<Id, Id> planIdMap = new Map<Id, Id>();
        for (AggregateResult r : [select PlanRef__c planRef, min(PlanProdcut__c) planProdId from PlanDetail__c where PlanRef__c in :allPlanIdSet and PlanProdcut__c != null group by PlanRef__c]) {
        	planIdMap.put((Id)r.get('planRef'), (Id)r.get('planProdId'));
        }

        // 変更前のプラン関連の見積明細
        if (!delPlanIdMap.isEmpty()) {
        	Set<Id> delProdSet = new Set<Id>();
        	for (Id planId : delPlanIdMap.values()) {
        		if (planIdMap.containsKey(planId)) delProdSet.add(planIdMap.get(planId));
        	}
            // 同じ予約ID　AND　予約プラン明細のデータを削除する
            if (!delProdSet.isEmpty()) {
            	//delete [select id from BookingEstimateItem__c where refAccountMaster__c in :delProdSet And refBooking__c in :delPlanIdMap.keySet() ];
            	Map<Id, BookingEstimateItem__c> delPlanEstItems =new Map<Id, BookingEstimateItem__c> ([select id from BookingEstimateItem__c where refAccountMaster__c in :delProdSet And refBooking__c in :delPlanIdMap.keySet() ]);
            	// 見積もり明細（プラン明細）も一緒に削除を行う
            	delete [select id from BookingEstimateItem__c where ParentBookingItemRef__c in :delPlanEstItems.keySet()];
            	delete delPlanEstItems.values();
            }
        }
        // 新規追加プランデータ存在する場合
        List<BookingEstimateItem__c> insLst = new List<BookingEstimateItem__c>();
        for (Id leadId: leadIdMap.keySet()) {
            // 該当予約データのプランの会計商品（プラン）存在する場合、新た見積明細商品を作成する
            if (planIdMap.containsKey(leadIdMap.get(leadId))) {
                insLst.add(new BookingEstimateItem__c (
                    refBooking__c = leadId,
                    refAccountMaster__c = planIdMap.get(leadIdMap.get(leadId)),
                    Amount__c = leadInfoMap.get(leadId).StayPersons__c,
                    // 2014/08/27 単価定義区分は予約からコピーする
                    UnitPriceDefKb__c = leadInfoMap.get(leadId).UnitPriceDefKbCal__c,
                    PlanDetailSyncInfo__c = syncInfoMap.get(leadId)	// 予約に該当プラン情報をカスタムマイズ情報
                    ));
            }
        }

        if (!insLst.isEmpty()) insert insLst;
    	// プラン存在する場合、
    	/*
    	// Map<プランID/List<商品ID>>
    	Map<Id, List<PlanDetail__c>> planItemMap = new Map<Id, List<PlanDetail__c>>();
    	// 各プランの明細商品を取得して、各予約の見積明細情報を設定する
    	for (PlanDetail__c s :
    		[select id, name, AccountMasterRef__c, PlanProdcut__c, PlanRef__c ,ProductNumber__c
    			From PlanDetail__c where PlanRef__c in :leadIdMap.values() Order By PlanRef__c]) {
    		// 各プランの商品IDを設定する
    		if (!planItemMap.containsKey(s.PlanRef__c)) {
    			List<PlanDetail__c> productLst = new List<PlanDetail__c>();
				planItemMap.put(s.PlanRef__c, productLst);
    		}
    		planItemMap.get(s.PlanRef__c).add(s);
    	}
    	// 見積明細登録を行う
    	// TODO:プラン設定機能に対して、見積り明細へ登録する場合、プラン商品の登録は未実装、プラン設定画面作成後、再開する
    	List<BookingEstimateItem__c> insLst = new List<BookingEstimateItem__c>();
    	for (Id leadId: leadIdMap.keySet()) {
    		// プランの見積明細が存在する場合
    		Id planId = leadIdMap.get(leadId);
    		if (planItemMap.containsKey(planId)) {
    			for (PlanDetail__c planItem: planItemMap.get(planId)) {
	    			insLst.add(
	    			new BookingEstimateItem__c (
						refBooking__c = leadId,
	    				refAccountMaster__c = planItem.AccountMasterRef__c,
	    				Amount__c = planItem.ProductNumber__c,
	    				PlanDetailRef__c = planItem.Id,
	    				SpTotal__c = planItem.Price__c		// 合計金額はプラン明細に設定する金額に設定する
	    			)); //
    			} // End For
    		} // End If
    	} // End For*/
    	//if (!insLst.isEmpty()) insert insLst;
    }
	/**
	* 2017/06/26 お客様がチェックアウトしたタイミングで音声通知機能
	**/
	public static final String CoKey = 'CO';
	// 2019/10/15 チェックイン時に自動音声で通知 BY zyz BEGIN
	public static final String CiKey = 'CI';
	// 2019/10/15 チェックイン時に自動音声で通知 BY zyz END
	public void notifyMsgByCheckout(Lead__c[] newList, Lead__c[] oldList, CommConst.TriggerMethod action){
		// 予約ステータスが変更の場合（XXX→チェックアウトに変更すると）
		if (action != CommConst.TriggerMethod.IsUpdate) return;
		// 共通定義はTRUEの場合、処理を行う
		// 2019/10/15 チェックイン時に自動音声で通知 BY zyz BEGIN
		Boolean checkinFlg = true;
		Boolean checkoutFlg = true;
		// if (!CommConst.NOTIFY_CO_IS_SPEECHALERT && !CommConst.NOTIFY_CO_IS_CHATTERPOST) return;
		if (!CommConst.NOTIFY_CO_IS_SPEECHALERT && !CommConst.NOTIFY_CO_IS_CHATTERPOST) checkoutFlg = false;
		if (!CommConst.NOTIFY_CI_IS_SPEECHALERT && !CommConst.NOTIFY_CI_IS_CHATTERPOST) checkinFlg = false;
		// 2019/10/15 チェックイン時に自動音声で通知 BY zyz END
		// 2017/12/07 チェックアウトの通知メッセージは自由にカスタマイズできるように改善対応 zyz BEGIN
		//Set<Id> roomIdSet = new Set<Id>();
		// 2017/12/07 チェックアウトの通知メッセージは自由にカスタマイズできるように改善対応 zyz BEGIN
		List<Call_information__c> notifyMsgLst = new List<Call_information__c>();
		// 2017/12/07 チェックアウトの通知メッセージは自由にカスタマイズできるように改善対応 zyz BEGIN
		Set<Id> leadIdSet = new Set<Id>();
		String apiStr='';
		// 2019/10/15 チェックイン時に自動音声で通知 BY zyz BEGIN
		String labelStr = Label.MSG_002_0379_1;
		String labelStrci = Label.MSG_002_0380_1;
		// checkin和checkout自定义内的字段获取
		set<String> apiset = CommLogicProcess.parseFieldByLable(labelStr);
		set<String> cipiset = CommLogicProcess.parseFieldByLable(labelStrci);
		// checkin和checkout对应的所有字段
		for(String ciApi : cipiset){
		    if (apiset.contains(ciApi)) continue;
		    apiset.add(ciApi);
		}
		// set<String> apiset = CommLogicProcess.parseFieldByLable(labelStr);
		map<String,String> labelMap = new map<String,String>();
		// 2019/10/15 チェックイン時に自動音声で通知 BY zyz END
		// 2017/12/07 チェックアウトの通知メッセージは自由にカスタマイズできるように改善対応 zyz END
		for (Integer i=0 ; i<newList.size(); i++) {
			Lead__c nw = newList[i];
			Lead__c od = oldList[i];
			// 無効な予約の場合、処理対象外
			if (nw.Rroom__c == null) continue;
			if (nw.CancelBool__c == CommConst.LEAD_ST_CANCEL_FLG) continue;
			// 2019/10/15 チェックイン時に自動音声で通知 BY zyz BEGIN
			// if (nw.Field298__c == CommConst.LEAD_GUEST_ST_CO && nw.Field298__c != od.Field298__c) {
			if (((nw.Field298__c == CommConst.LEAD_GUEST_ST_CO && nw.Field298__c != od.Field298__c)
			|| (nw.Field298__c == CommConst.LEAD_GUEST_ST_CI && nw.Field298__c != od.Field298__c))
			&& nw.SysIsBulkCheckinFlg__c == od.SysIsBulkCheckinFlg__c
			) {
				String labelVal = '';
				String ValKey = '';
				// checkin处理
				if(nw.Field298__c == CommConst.LEAD_GUEST_ST_CI) {
					if(!checkinFlg) continue;
					ValKey = CiKey;
					labelVal = labelStrci;
				}
				// checkout处理
				else if(nw.Field298__c == CommConst.LEAD_GUEST_ST_CO){
					if(!checkoutFlg) continue;
					ValKey = CoKey;
					labelVal = labelStr;
				}
			// 2019/10/15 チェックイン時に自動音声で通知 BY zyz END
				// 2017/12/07 チェックアウトの通知メッセージは自由にカスタマイズできるように改善対応 zyz BEGIN
			    // 重複部屋除外処理を行う
			    //if (roomIdSet.contains(nw.Rroom__c)) continue;
			    //	roomIdSet.add(nw.Rroom__c);
				// 予约Id
				if (leadIdSet.contains(nw.Id)) continue;
				leadIdSet.add(nw.Id);
				// 2017/12/07 チェックアウトの通知メッセージは自由にカスタマイズできるように改善対応 zyz END
				// 通知用メッセージを作成する
	        	Call_information__c newCall = new Call_information__c(
	        		// 2017/12/07 チェックアウトの通知メッセージは自由にカスタマイズできるように改善対応 zyz BEGIN
	        		//NAM__c = nw.Rroom__c,
	        		NAM__c = nw.Id,
	        		// 2017/12/07 チェックアウトの通知メッセージは自由にカスタマイズできるように改善対応 zyz END
	        		// 2019/10/15 チェックイン時に自動音声で通知 BY zyz BEGIN
	        		// CallType__c = CoKey,
	        		CallType__c = ValKey,
	        		// 2019/10/15 チェックイン時に自動音声で通知 BY zyz END
	        		Contact__c = od.Relcontact__c,
	        		Call_Time__c = System.now(),
	        		MessageUUID__c = CommUtils.getGUID()
	        	);
	        	// 2019/10/15 チェックイン時に自動音声で通知 BY zyz BEGIN
	        	labelMap.put(nw.Id,labelVal);
	        	// 2019/10/15 チェックイン時に自動音声で通知 BY zyz END
	        	notifyMsgLst.add(newCall);
			}
		}
		// 2017/12/07 チェックアウトの通知メッセージは自由にカスタマイズできるように改善対応 zyz BEGIN
		//if (roomIdSet.isEmpty()) return;
		
		//map<id,Room__c> roomsMap = new map<id, Room__c>([select id, name from Room__c where id = :roomIdSet and CoMessageNotifyFlg__c = false]);
		if (leadIdSet.isEmpty()) return;
		map<id,Lead__c> leadsMap = new map<id, Lead__c>();
		// 判断是否追加label变更,无变更输出{XXXXXX}号室チェックアウトしました,有变更按照变更输出
		if(apiset.isEmpty()) {
			apiStr += 'Id,Rroom__r.Name ';
		} else {
			set<String> wkapiset = new set<String>();
			for (String wkapi : apiset){
				String lowerApi = wkapi.toLowerCase();
				if(lowerApi == 'relcontact__r.name') {if (!wkapiset.contains('relcontact__r.katakana__c')) wkapiset.add('relcontact__r.katakana__c');}
				wkapiset.add(lowerApi);
			}
			for (String api : wkapiset){ apiStr += (CommUtils.isBlank(apiStr) ? '' : ',') + api;}
		}
		// 检索予约数据
		String leadQuery ='select ' + apiStr + ' from Lead__c where id = :leadIdSet';
		list<Lead__c> leadlst = null;
		// 用于判断使用默认label
		Boolean isleadRoom = false;
		try{
			leadlst = Database.query(leadQuery);
			for (Lead__c lead : leadlst){
				leadsMap.put(lead.id,lead);
			}
		} catch(Exception e){ 
			isleadRoom = true;
			leadlst = [select Id,Rroom__r.Name from Lead__c where id = :leadIdSet and Rroom__c != null];
			for (Lead__c lead : leadlst){
				leadsMap.put(lead.id,lead);
			}
		}
		for (Call_information__c call : notifyMsgLst) {
		    // 2017/07/15 チェックアウト通知対象外機能対応 BEGIN
		    // 2017/12/07 チェックアウトの通知メッセージは自由にカスタマイズできるように改善対応 zyz BEGIN
		    //if (!roomsMap.containsKey(call.NAM__c)) {
		    if (!leadsMap.containsKey(call.NAM__c)) {
		    // 2017/12/07 チェックアウトの通知メッセージは自由にカスタマイズできるように改善対応 zyz END
		        call.NAM__c = null;
		        continue;
		    }
		    //2017/07/15 チェックアウト通知対象外機能対応 END
		    // 2017/12/07 チェックアウトの通知メッセージは自由にカスタマイズできるように改善対応 zyz BEGIN
		    // 根据予约Id取得予约数据
		    Lead__c lead = leadsMap.get(call.NAM__c);
		    // 2019/10/15 チェックイン時に自動音声で通知 BY zyz BEGIN
		    // 获取定义的label
		    if (labelMap.containsKey(call.NAM__c)) labelStr = labelMap.get(call.NAM__c);
		    // 自定义label
		    // if (!isleadRoom && !apiset.isEmpty()){
		    if (!isleadRoom && !apiset.isEmpty() && labelStr.indexOf('@') != -1){
		        // labelStr = Label.MSG_002_0379_1;
		        // 2019/10/15 チェックイン時に自動音声で通知 BY zyz END
			    for (String Str : apiset){
			    	String fieldVal = CommUtils.nullToBlank(CommUtils.getFielValue(lead,Str));
			    	if(Str.toLowerCase() == 'relcontact__r.name'){
			    		String fieldkana = CommUtils.nullToBlank(CommUtils.getFielValue(lead,'relcontact__r.katakana__c'));
			    		if(!CommUtils.isBlank(fieldkana)) fieldVal = fieldkana;
			    	}
			    	labelStr = labelStr.Replace('{@' +Str+'}' ,fieldVal);
			    }
			// 默认label
			// 2019/10/15 チェックイン時に自動音声で通知 BY zyz BEGIN
		    // } else { labelStr = Label.MSG_002_0379.Replace(CommConst.LABEL_MSG_REPKEY1,lead.Rroom__r.Name);}
		    } else { 
		    	String defLabelStr = Label.MSG_002_0379;
		    	if(call.CallType__c == CiKey) defLabelStr = Label.MSG_002_0380;
		    	// if(call.CallType__c == CiKey) defLabelStr = '{XXXXXX}号室チェックインしました';
		    	labelStr = defLabelStr.Replace(CommConst.LABEL_MSG_REPKEY1,lead.Rroom__r.Name);
		    }
		    // 2019/10/15 チェックイン時に自動音声で通知 BY zyz END
		    call.NAM__c = labelStr;
		    //String wkNofityMsg = Label.MSG_002_0379.Replace(CommConst.LABEL_MSG_REPKEY1,roomsMap.get(call.NAM__c).Name);
		    //call.NAM__c = wkNofityMsg;//roomsMap.get(call.NAM__c).Name + '号室チェックアウトしました';
		    // 2017/12/07 チェックアウトの通知メッセージは自由にカスタマイズできるように改善対応 zyz END
		}
		Integer maxDbRecs = 400;
		// 既存データチェックを行う
		list<Call_information__c> callLst = [select id from Call_information__c where CallType__c = :CoKey order by LastmodifiedDate asc limit :maxDbRecs];
		//　Insert可能件数
		Integer insertRs = maxDbRecs - callLst.size();
		List<Call_information__c> insertLst = new List<Call_information__c>();
		List<Call_information__c> updateLst = new List<Call_information__c>();
		
		for (Integer i = 0; i < notifyMsgLst.size(); i++) {
		    // 2017/07/15 チェックアウト通知対象外機能対応 BEGIN
		    if (CommUtils.isBlank(notifyMsgLst[i].NAM__c)) continue;
		    // 2017/07/15 チェックアウト通知対象外機能対応 END
			if (i < insertRs) {
				insertLst.add(notifyMsgLst[i]);
			} else {
				Call_information__c upd = notifyMsgLst[i];
				upd.Id = callLst[updateLst.size()].Id;
				updateLst.add(upd);
			}
		}
		if (!insertLst.isEmpty()) insert insertLst;
		if (!updateLst.isEmpty()) update updateLst;
 	}
 	// 2017/06/26 お客様がチェックアウトしたタイミングで音声通知機能 END
    /**
    * 予約データダブルブッキング処理（予約の重複）
    * 参考URL：        http://www.niji.or.jp/home/toru/notes/58.html
    * http://blog.yaju.jp/200812/article_13.html
    *
    * 同じタイミング帯に、重複設定することをチェックを行う
    * Ver0.1: 宴会タイプチェックを追加する[新規/更新場合(有効対象)]
    **/
    public void checkDuplicateTime(Lead__c[] newList, Lead__c[] oldList, CommConst.TriggerMethod action){

    	// 予約データは新規・更新以外の場合、処理中止
    	if(action != CommConst.TriggerMethod.isInsert && action != CommConst.TriggerMethod.isUpdate ) { return; }

    	// 新規場合、新規追加の予約情報の開始時間と終了時間帯は重複するかどうかチェックを行う
    	Id enkaiRecTypeId = CommLogicProcess.getLeadEnkaiRecType();
    	// 対象マップMap<部屋SID,List<予約SObj>> [同じ部屋に、予約データを維持する]
    	Map<Id, List<Lead__c>> roomMap = new Map<Id, List<Lead__c>>();
    	// 親子部屋マップMap<子供部屋SID,親部屋SID>
    	Map<String, String> roomIdMap = new Map<String, String>();
    	// SOQL条件：Set<既存部屋SID>
    	Set<Id> allRoomIdSet = new Set<Id>();
    	// SOQL条件：Set<到着日>
    	Set<Date> entryTimeSet = new Set<Date>();
    	// 予約処理対象は宴会場合、既存の予約データダブルブッキングをチェックする
    	for (Lead__c nw : newList) {
    		// 宴会以外のデータは処理対象外
    		if (enkaiRecTypeId != nw.RecordTypeId) continue;
    		// 部屋なし場合、処理対象外
			if (nw.Rroom__c == null) continue;
			// 各部屋のリース配列初期化する[新規追加データ維持する]
			if (!roomMap.containsKey(nw.Rroom__c)){
				List<Lead__c> leadLst = new List<Lead__c>();
				roomMap.put(nw.Rroom__c, leadLst);
			}
            roomMap.get(nw.Rroom__c).add(nw);
            //if(nw.Rroom__c != null) roomIdSet.add(nw.Rroom__c);
            if(nw.EntryTime__c != null) entryTimeSet.add(nw.EntryTime__c.date());
    	}
    	// 処理対象なし場合、処理終了
    	if (roomMap.isEmpty()) return;

        // *******************************
        // 部屋関連MAPを取得する
        // *******************************
        Map<Id, List<Id>> mainSubMap = new Map<Id, List<Id>>();
        // Map<子部屋ID・親部屋ID>
        Map<Id, Id> subMainMap = new Map<Id, Id>();
        // 部屋の親子関係を取得する[子部屋から親部屋取得する、そして、親部屋から子部屋を取得する]
        if(!roomMap.isEmpty()){
            // TODO:親・子部屋設定は１階層だけ対応出来る
            // 親部屋を全部取得する
            for (Room__c item: [select id, ParentRoomRef__c from Room__c where ParentRoomRef__c = null and UseOfRoom__c =: CommConst.ROOM_UseOfType_PTY]) {
                List<Id> subRoomLst = new List<Id>();
                mainSubMap.put(item.id,  subRoomLst);
            }
            // 子部屋を全部取得する
            for(Room__c item : [select Id, ParentRoomRef__c from Room__c where ParentRoomRef__c != null and UseOfRoom__c =: CommConst.ROOM_UseOfType_PTY]) {
                mainSubMap.get(item.ParentRoomRef__c).add(item.Id);
                subMainMap.put(item.Id, item.ParentRoomRef__c);
            }
        }
        // 親関係なしの部屋は対象外処理する
        for (Id parentId : mainSubMap.keyset()) { if (mainSubMap.get(parentId).isEmpty()) mainSubMap.remove(parentId); }
        // 2016/12/06 宴会場の部屋定義がなかった場合、該当チェック処理を中止する BEGIN
        if (mainSubMap.isEmpty() && subMainMap.isEmpty()) return;
        // 2016/12/06 宴会場の部屋定義がなかった場合、該当チェック処理を中止する END
        // 処理対象ホームID
        allRoomIdSet.addAll(roomMap.keySet());
        allRoomIdSet.addAll(mainSubMap.keySet());
        allRoomIdSet.addAll(subMainMap.keySet());

    	//　新規追加する予約データから既存の予約データ間の重複チェックを行う
    	for(Lead__c exist : [  select Id, EntryTime__c, Departure__c, Field4__c, Field3__c, Rroom__c
                            from Lead__c
    	                    where RecordTypeId = :enkaiRecTypeId
    	                    and CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
    	                    and Rroom__c in :allRoomIdSet
    	                    and DAY_ONLY(convertTimezone(EntryTime__c)) in:entryTimeSet]){
			if (!roomMap.containsKey(exist.Rroom__c)){
				List<Lead__c> leadLst = new List<Lead__c>();
				roomMap.put(exist.Rroom__c, leadLst);
			}
			roomMap.get(exist.Rroom__c).add(exist);
		}
    	// 同じ部屋に、時間帯重複チェックを行う
    	for (List<Lead__c> roomLeadLst : roomMap.values()) {
    		// 該当部屋に一つだけ予約データが存在する場合、部屋内の重複チェックSKIPする
    		if (roomLeadLst.size() < 1) continue;
    		for(Integer i = 0; i < roomLeadLst.size(); i ++){
				for(Integer j = i + 1; j < roomLeadLst.size(); j ++){
					// 更新する場合、同じデータIDすれば、処理SKIPする
					if (roomLeadLst[i].Id == roomLeadLst[j].Id) continue;
					// 時間帯重複チェックを行う
					if(	getCalTimeDate(roomLeadLst[i].EntryTime__c, roomLeadLst[i].Field4__c) < getCalTimeDate(roomLeadLst[j].Departure__c, roomLeadLst[j].Field3__c) &&
						getCalTimeDate(roomLeadLst[i].Departure__c, roomLeadLst[i].Field3__c) > getCalTimeDate(roomLeadLst[j].EntryTime__c, roomLeadLst[j].Field4__c)) {
						//時間帯重複データが存在するため、データ登録ができません。
						newList[0].addError(Label.MSG_002_0374);
						return;
					}
				}
    		}
    	}

    	// 新規作成・変更するデータの場合、内部にLockする現象チェックを行う
    	// 親から子供の設定時間とMatchする
    	Set<Id> checkOverSet = new Set<Id>();
    	for (Id roomId : roomMap.keySet()) {
    		// 処理済のIDは対象外する　
    		if (checkOverSet.contains(roomId)) continue;
    		// 処理済対応IDを追加する
    		//checkOverSet.add(roomId);
    		// 部屋処理対象は親部屋場合
    		if (mainSubMap.containsKey(roomId)) {
	    		// 処理済対応IDを追加する
	    		checkOverSet.add(roomId);
    			// 該当部屋は親部屋の場合
    			List<Lead__c> mainRoomLeadLst = roomMap.get(roomId);
    			// 該当部屋の関連の子供予約情報を取得する
    			for (Id subRoomId : mainSubMap.get(roomId)) {
    				// 変更データの中に、子部屋が非存在する場合
    				if (!roomMap.containsKey(subRoomId)) continue;
    				// 子データの情報を処理済に追加する
    				checkOverSet.add(subRoomId);
					// 親と子の関連重複チェックを行う
					List<Lead__c> subRoomLeadLst = roomMap.get(subRoomId);
		    		for(Integer i = 0; i < mainRoomLeadLst.size(); i ++){
						for(Integer j = 0; j < subRoomLeadLst.size(); j ++){

							// 時間帯重複チェックを行う
							if(	getCalTimeDate(mainRoomLeadLst[i].EntryTime__c, mainRoomLeadLst[i].Field4__c) < getCalTimeDate(subRoomLeadLst[j].Departure__c, subRoomLeadLst[j].Field3__c) &&
								getCalTimeDate(mainRoomLeadLst[i].Departure__c, mainRoomLeadLst[i].Field3__c) > getCalTimeDate(subRoomLeadLst[j].EntryTime__c, subRoomLeadLst[j].Field4__c)) {
								//時間帯重複データが存在するため、データ登録ができません。
								newList[0].addError(Label.MSG_002_0374);
								return;
							}
						}
		    		}
    			}
    		}
    		// 子部屋のデータ場合：子部屋と親部屋の関連チェックを行う　
    		else if (subMainMap.containsKey(roomId)) {
    			// 該当部屋の親部屋チェックする
    			Id mainRoomId = subMainMap.get(roomId);
				// 親の予約情報ガみ存在する場合、処理SKIP
				if (!roomMap.containsKey(mainRoomId)) continue;
				List<Lead__c> mainRoomLeadLst = roomMap.get(mainRoomId);
				List<Lead__c> subRoomLeadLst = roomMap.get(roomId);
				// 関連チェックを行う
		    		for(Integer i = 0; i < mainRoomLeadLst.size(); i ++){
						for(Integer j = 0; j < subRoomLeadLst.size(); j ++){
							// 時間帯重複チェックを行う
							if(	getCalTimeDate(mainRoomLeadLst[i].EntryTime__c, mainRoomLeadLst[i].Field4__c) < getCalTimeDate(subRoomLeadLst[j].Departure__c, subRoomLeadLst[j].Field3__c) &&
								getCalTimeDate(mainRoomLeadLst[i].Departure__c, mainRoomLeadLst[i].Field3__c) > getCalTimeDate(subRoomLeadLst[j].EntryTime__c, subRoomLeadLst[j].Field4__c)) {
								//時間帯重複データが存在するため、データ登録ができません。
								newList[0].addError(Label.MSG_002_0374);
								return;
							}
						}
		    		}
    		} // End Else If
    	}
    }
	private DateTime getCalTimeDate ( DateTime orgDateTime, String hmTime) {
        //Integer hh = (hmTime.length() == 4 ? Integer.valueOf(hmTime.substring(0,1)) : Integer.valueOf(hmTime.substring(0,2)));
        //Integer mm = (hmTime.length() == 4 ? Integer.valueOf(hmTime.substring(2,4)) : Integer.valueOf(hmTime.substring(3,5)));
        //return DateTime.newInstance(orgDateTime.date(), Time.newInstance(hh, mm, 0, 0));
        return DateTime.newInstance(orgDateTime.date(), CommUtils.stringToTime(hmTime));
	}
    /*
    * 予約データは登録前の項目自動設定機能
    * 部屋情報にて、部屋タイプの自動設定を行う
    * 2013/09/18 到着時刻、出発時刻書式変更機能追加「H:MM->HH:MM」
    */
    public void autoSetupInfo(Lead__c[] newList, Lead__c[] oldList, CommConst.TriggerMethod action){
    	
    	// 2018/06/06 編集権限チェックできる対応 BEGIN
    	if (CommSecurityUtils.getAuthInstance().NoEditLead__c == true) {
    		//throw new CommException('該当権限がありません。');
    		newList[0].addError(Label.MSG_9105);
    		return;
    	}
    	// 2018/06/06 編集権限チェックできる対応 END
    	// 2020/08/30 リアルAGT支店别での対応 WGCH BEGIN
    	Map<String, Decimal> realAGTRoomMap = new Map<String, Decimal>();
    	if(action == CommConst.TriggerMethod.IsInsert){
    		Set<String> roomTypeIdSet = new Set<String>();
    		Set<Date> stockDateSet = new Set<Date>();
    		for (Lead__c nw : newList) {
    			// 2020/08/30 代码优化 WGCH BEGIN
    			if(!nw.OldAgtCal__c) continue;
    			// 2020/08/30 代码优化 WGCH END
    			if(nw.refTypeOfRooms__c != null){
    				roomTypeIdSet.add(nw.refTypeOfRooms__c);
    			}
	    		if(nw.EntryTime__c != null){
	    			stockDateSet.add(nw.EntryTime__c.date());
	    		}
	    	}
	    	realAGTRoomMap = StockChangeHelpUtils.getAgtMaxRoomsMap(roomTypeIdSet, stockDateSet);
    	}
    	// 2020/08/30 リアルAGT支店别での対応 WGCH END
    	// 部屋存在、部屋タイプを未登録される場合：
    	Set<Id> rootIdSet = new Set<Id>();
    	// 部屋存在、部屋タイプも存在する場合、関連正常性チェックを行う
    	Set<Id> roomIdAndTypeIdSet = new Set<Id>();
    	Integer rsIdx = 0;
    	for (Lead__c nw: newList) {
    	   // 部屋存在、部屋タイプが未存在する場合、設定を行う
    	   if (nw.Rroom__c != null && nw.refTypeOfRooms__c == null) {
               rootIdSet.add(nw.Rroom__c);
    	   }
    	   if (nw.Rroom__c != null && nw.refTypeOfRooms__c != null) {
               roomIdAndTypeIdSet.add(nw.Rroom__c);
    	   }
    	   // 出発時刻、到着時刻変更対応（４桁→５桁）
		   if (!String.isEmpty(nw.Field3__c) && nw.Field3__c.length() != 5) {
		   		nw.Field3__c = (DateTime.newInstance(Date.today(), CommUtils.stringToTime(nw.Field3__c))).format('HH:mm');
		   }
		   if (!String.isEmpty(nw.Field4__c) && nw.Field4__c.length() != 5) {
		   		nw.Field4__c = (DateTime.newInstance(Date.today(), CommUtils.stringToTime(nw.Field4__c))).format('HH:mm');
		   }
		   // 2018/08/23 検索用キーを自動設定する BEGIN
		   if (nw.EntryTime__c != null) {
			   Date dt = nw.EntryTime__c.date();
			   nw.EntryDateKey__c = DataFixManagerUtils.dateToYMDstr(dt);
			   // 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
			   nw.EntryDateIntKey__c = CommUtils.nullToIntZero(nw.EntryDateKey__c);
			   // 2020/08/30 部屋状態管理インデックス機能対応 WGCH END
               // 2021/03/25 #9919 BugFix WSQ BEGIN
               if (CommUtils.isBlank(nw.Field4__c)) {
                  nw.Field4__c = nw.EntryTime__c.format('HH:mm');
               } else
               if (nw.EntryTime__c.format('HH:mm') != nw.Field4__c) {
                    nw.EntryTime__c = DateTime.newInstance(dt,CommUtils.stringToTime(nw.Field4__c));
               }
               // 2021/03/25 #9919 BugFix WSQ END
		   }
		   if (nw.Departure__c != null) {
			   Date dt = nw.Departure__c.date();
			   nw.DepartureDateKey__c = DataFixManagerUtils.dateToYMDstr(dt);
			   // 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
			   nw.DepartureDateIntKey__c = CommUtils.nullToIntZero(nw.DepartureDateKey__c);
			   // 2020/08/30 部屋状態管理インデックス機能対応 WGCH END
               // 2021/03/25 #9919 BugFix WSQ BEGIN
               if (CommUtils.isBlank(nw.Field3__c)) {
                  nw.Field3__c = nw.Departure__c.format('HH:mm');
               } else 
               if (nw.Departure__c.format('HH:mm') != nw.Field3__c) {
                    nw.Departure__c = DateTime.newInstance(dt,CommUtils.stringToTime(nw.Field3__c));
               }
               // 2021/03/25 #9919 BugFix WSQ END
		   }
		   // 2018/08/23 検索用キーを自動設定する END
		   // 2019/09/23 取引先に紐づくお客様の予約を、取引先の画面で表示するように改善対応 WSQ BEGIN
		   if (Commconst.LEAD_REFACCOUNT_AUTOSETUP_FLG) nw.refAccount__c = nw.LeadAccountIdCal__c;
		   // 2019/09/23 取引先に紐づくお客様の予約を、取引先の画面で表示するように改善対応 WSQ END
		   // 2020/05/29 在庫計算ロジック改修 WGCH BEGIN
		   if(action == CommConst.TriggerMethod.IsInsert){
		   		// 2020/08/30 リアルAGT支店别での対応 WGCH BEGIN
				// if(StockChangeHelpUtils.isStockSyncIsMode == StockChangeHelpUtils.STOCK_SYNC_MODE_0) nw.AgtFlg__c = nw.OldAgtCal__c;
				if(!realAGTRoomMap.isEmpty() && StockChangeHelpUtils.isStockSyncIsMode == StockChangeHelpUtils.STOCK_SYNC_MODE_0){
					// 処理キーを取得する
					String realAGTRoomKey = null;
					// 2021/03/16 リアルAGTの予約かどうかの識別に親取引先を参照にするBUG[#PC9889] WGCH BEGIN
					// if(nw.EntryTime__c != null) realAGTRoomKey = StockChangeHelpUtils.getRealAGTRoomKey(nw.SalesOfficeInfoRef__c, nw.refTypeOfRooms__c, nw.EntryTime__c.date());
					if (nw.EntryTime__c != null) {
						String accountId = nw.SalesOfficeInfoRef__c;
						if (StockChangeHelpUtils.isAGTReferToParentFlg && !CommUtils.isBlank(nw.SalesOfficeCompanyCal__c)) {
							accountId = nw.SalesOfficeCompanyCal__c;
						}
						realAGTRoomKey = StockChangeHelpUtils.getRealAGTRoomKey(accountId, nw.refTypeOfRooms__c, nw.EntryTime__c.date());
					}
					// 2021/03/16 リアルAGTの予約かどうかの識別に親取引先を参照にするBUG[#PC9889] WGCH END
					// リアルAGT支店别
					nw.AgtFlg__c = nw.OldAgtCal__c && realAGTRoomKey != null && realAGTRoomMap.containsKey(realAGTRoomKey);
				}
				// 2020/08/30 リアルAGT支店别での対応 WGCH END
		   }
		   // 2020/05/29 在庫計算ロジック改修 WGCH END
		   /* ルームインジケータ画面から同じ部屋タイプ内部に部屋変更すると、発生源更新される不具合改修
		   if (oldList != null) {
		   		Lead__c od = oldList[rsIdx];
		   		rsIdx++;
		   		// 予約情報変更あり「部屋タイプ変更、予約ステータス変更、到着日変更」
				if (isUpdEventSourceTarget(nw, od)) {
			   		if (nw.EventSource__c == od.EventSource__c) {
			   			nw.EventSource__c = CommConst.BI_PROCESS_TYPE.SFDC.Name();
			   		}
				}
		   }*/
    	}
    	// 2018/12/30 部屋自動割当機能AI対応 by zy BEGIN
    	if (action == CommConst.TriggerMethod.IsInsert) {
    		if (CommConst.ROOM_ASSIGN_FLG) {
    			list<lead__c> assginLst = new list<lead__c>();
    			for (Lead__c nw: newList) {
					// 2019/12/30 5330 bug fix by zy BEGIN
    				if (nw.Rroom__c == null && nw.refTypeOfRooms__c != null) assginLst.add(nw);
					// 2019/12/30 5330 bug fix by zy END
    			}
    			if (!assginLst.isEmpty()) QQNRoomReservationAI.checkLeadRoom(assginLst);
    		}
    	}
    	// 2018/12/30 部屋自動割当機能AI対応 by zy END
    	if (rootIdSet.isEmpty() && roomIdAndTypeIdSet.isEmpty()) return;
    	// 部屋タイプを取得する
    	Map<Id, Id> roomToRoomTypeMap = new Map<Id, Id>();
    	// ご予約の部屋と部屋タイプの設定が矛盾の場合、連携キャンセル不能の不具合改修 BEGIN
    	//for (Room__c room: [select id, TypeRoomRef__c from Room__c where (id in :rootIdSet or id in :roomIdAndTypeIdSet )and TypeRoomRef__c != null]) {
    	for (Room__c room: [select id, TypeRoomRef__c from Room__c where (id in :rootIdSet or id in :roomIdAndTypeIdSet )]) {
        // ご予約の部屋と部屋タイプの設定が矛盾の場合、連携キャンセル不能の不具合改修 END
    		roomToRoomTypeMap.put(room.id, room.TypeRoomRef__c);
    	}
    	if (roomToRoomTypeMap.isEmpty()) return;
    	// 予約データ再設定を行う
        for (Lead__c nw: newList) {
           // 部屋存在、部屋タイプが未存在する場合、設定を行う
           //if (nw.Rroom__c != null && nw.refTypeOfRooms__c == null) {
           if (nw.Rroom__c != null) {
               if (roomToRoomTypeMap.containsKey(nw.Rroom__c)) nw.refTypeOfRooms__c = roomToRoomTypeMap.get(nw.Rroom__c);
           }
        }
        // ルームインジケータ画面から同じ部屋タイプ内部に部屋変更すると、発生源更新される不具合改修 BEGIN
        // 上記の部屋により、部屋タイプ再設定により、部屋タイプ設定をチェックする
        rsIdx = 0;
    	for (Lead__c nw: newList) {
		   if (oldList != null) {
		   		Lead__c od = oldList[rsIdx];
		   		rsIdx++;
		   		// 予約情報変更あり「部屋タイプ変更、予約ステータス変更、到着日変更」
				if (isUpdEventSourceTarget(nw, od)) {
			   		if (nw.EventSource__c == od.EventSource__c) {
			   			nw.EventSource__c = CommConst.BI_PROCESS_TYPE.SFDC.Name();
			   		}
				}
		   }
    	}
    	// ルームインジケータ画面から同じ部屋タイプ内部に部屋変更すると、発生源更新される不具合改修 END
    }
    /* 2014/06/24 プラングループ新VERSIONにより、下記チェックが外す
    // ベースプランは直接設定不可チェック追加(2014/05/31)[Before Insert/Before Update]
    public void checkPlanInfo (Lead__c[] newList, Lead__c[] oldList, CommConst.TriggerMethod action){
    	Set<Id> planIdSet = new Set<Id>();
    	if (action == CommConst.TriggerMethod.isInsert) {
    		for (Lead__c nw : newList) {
    			if (nw.Field310__c != null) planIdSet.add(nw.Field310__c);
    		}
    	} else if (action == CommConst.TriggerMethod.isUpdate) {
    		for (Integer i = 0; i < newList.size(); i++) {
    			Lead__c nw = newList[i];
    			Lead__c od = oldList[i];
    			if (nw.Field310__c != od.Field310__c && nw.Field310__c != null) planIdSet.add(nw.Field310__c);
    		}
    	}
    	if (planIdSet.isEmpty()) return;
    	// ベースプランを捜す
    	Map<Id, Plan__c> basePlanMaps = new Map<Id, Plan__c>([select id From Plan__c where BasePlanFlg__c = true And id in :planIdSet]);
    	if (basePlanMaps.isEmpty()) return;	// 設定のプラン中に、ベースプランが非存在する
    	for (Lead__c nw : newList) {
    		if (basePlanMaps.containsKey(nw.Field310__c)) nw.addError('ベースプランに設定されたプランを選択できません。');
    		return;
    	}
    }*/

    /**
    * 予約データが新規作成する場合(Before Insert)/予約インデックス設定されているがどうかチェックして、未設定する場合、自動Indexデータを作成する
    **/
    public void autoSetupIndexInfo(Lead__c[] newList, Lead__c[] oldList, CommConst.TriggerMethod action){
    	// 予約データの予約インデックス項目はNULL場合、予約インデックス自動作成対象データ
    	// 作成ルールのは１予約１予約インデックスで作成する
    	Map<Integer, LeadIndex__c> newIndexMap = new Map<Integer, LeadIndex__c>();
    	Map<Integer, LeadIndex__c> newSubIdxMap = new Map<Integer, LeadIndex__c>();
    	// Index Id: Lead
    	//Map<Id, List<Lead__c>> indexLeadMap = new Map<Id, List<Lead__c>>();
        for (Integer i = 0; i < newList.size(); i++) {
        	Lead__c nw = newList[i];
        	// Indexが未設定する場合、自動的にIndexを作成する[1部屋１日]
        	if (nw.LeadIndexRef__c == null) {
		        LeadIndex__c newLeadIndex = new LeadIndex__c();
		        newLeadIndex.EntryDate__c = nw.EntryTime__c.date();
		        newLeadIndex.EntryTime__c = nw.Field4__c;
		        newLeadIndex.DepartureDate__c = nw.Departure__c.date();
		        newLeadIndex.DepartureTime__c = nw.Field3__c;
		        // 顧客ID + RandomID
		        newLeadIndex.ID__c = null;//CommUtils.nullToBlank(nw.Relcontact__c) + '_' + Crypto.getRandomLong();
		        newLeadIndex.EventSource__c = 'FromUI';
		        newLeadIndex.Nights__c = newLeadIndex.EntryDate__c.daysBetween(newLeadIndex.DepartureDate__c);
		        newLeadIndex.Rooms__c = 1;
                newLeadIndex.contactRef__c = nw.Relcontact__c;
                newLeadIndex.LeadName__c = nw.Name;
                // 支払方法
                newLeadIndex.Payment__c = nw.Field315__c;
                // 予約チャネル
                newLeadIndex.Channel__c = nw.Field2__c;
                // セグメント
                newLeadIndex.Segment__c = nw.Segment__c;
                // 特記事項
                newLeadIndex.Comment__c = nw.Comment3__c;
                
                newIndexMap.put(i, newLeadIndex);

                // SUB INDEXも移動作成を行う
                LeadIndex__c nwSub = new LeadIndex__c();
                // エキストラベッド(E/B)
                nwSub.ExtraBedChk__c = nw.ExtraBedChk__c;
                nwSub.PlanRef__c = nw.Field310__c;
                nwSub.Nights__c = newLeadIndex.Nights__c;
                nwSub.Rooms__c = newLeadIndex.Rooms__c;
                nwSub.RoomTypeRef__c = nw.refTypeOfRooms__c;
                nwSub.DepartureDate__c = nw.Departure__c.Date();
                nwSub.EntryDate__c = nw.EntryTime__c.Date();
                nwSub.StayPersons__c = nw.StayPersons__c;
                nwSub.contactRef__c = nw.Relcontact__c;
                nwSub.LeadName__c = nw.Name;
                // 2013/12/03 標準画面から予約データを登録する場合、明細情報時刻設定不正不具合修正
                nwSub.EntryTime__c = newLeadIndex.EntryTime__c;
                nwSub.DepartureTime__c = newLeadIndex.DepartureTime__c;
                // 支払方法
                nwSub.Payment__c = newLeadIndex.Payment__c;
                // 予約チャネル
                nwSub.Channel__c = newLeadIndex.Channel__c;
                // セグメント
                nwSub.Segment__c = newLeadIndex.Segment__c;
                // 特記事項
                nwSub.Comment__c = newLeadIndex.Comment__c;
                
                newSubIdxMap.put(i, nwSub);

                // 宿泊名簿情報を登録する
                // 2013/04/28 ADD 標準SF画面から自動LeadIndexを作成する場合、「標準画面登録」はTRUEに設定する
                nw.SfRegisteredFlg__c = true;
        	}
        }
        // ************ CASE1 ******************
        // Lead Index 未設定ケース場合
        if (!newIndexMap.isEmpty()) {
            // Indexデータを新規作成する
            insert newIndexMap.values();
            for (Integer i = 0; i < newList.size(); i++) {
                if (newIndexMap.containsKey(i)) {
                    newSubIdxMap.get(i).ParentLeadIndxRef__c = newIndexMap.get(i).Id;
                }
            }
            insert newSubIdxMap.values();
            for (Integer i = 0; i < newList.size(); i++) {
                Lead__c nw = newList[i];
                if (newIndexMap.containsKey(i)) {
                    nw.LeadIndexRef__c = newIndexMap.get(i).Id;
                    nw.LeadIndexSubId__c = newSubIdxMap.get(i).Id;
                    nw.RoomGroupNo__c = 0;
                }
            }
        }
    }

	/**
	* SF画面から直接登録した予約データに対して、到着日と出発日は変わる場合、自動関連のLeadIndexへ連動コピーを行う
	* 注：　予約　⇒　予約LeadIndex　⇒　予約SubLeadIndex
	* After Update / After Insert(2013/09/05 New Add)
	* 2013/09/05 予約データは関連の予約インデックスの期間範囲連動するため、ロジック修正を行う
	*         1:予約データの到着日と出発日は変更される場合、　該当予約の関連の予約インデックスの期間を再設定を行う
	*           設定ルール：該当予約インデックスの予約データの最大期間を設定する
	**/
	public void syncLeadInfoToLeadIndex(Lead__c[] newList, Lead__c[] oldList, CommConst.TriggerMethod action){
		// 対象データ：予約データ：標準画面登録(SfRegisteredFlg__c)＝TRUEのみ、処理対象
		// Map<LeadIdex Id/Lead Id>
		//Map<Id, Lead__c> leadIdxIdMap = new Map<Id, Lead__c>();
		//Map<Id, Lead__c> leadSubIdxMap = new Map<Id, Lead__c>();
		Set<Id> leadIdxIdSet = new Set<Id>();
		Set<String> leadIdxSubIdSet = new Set<String>();
		// 新規の場合
		if (action == CommConst.TriggerMethod.isInsert ) {
			for (Integer i = 0; i < newList.size() ; i++) {
				Lead__c nw = newList[i];
				// 予約インデクスID
				if(nw.LeadIndexRef__c != null) leadIdxIdSet.add(nw.LeadIndexRef__c);
				// 予約インデックスSUBのID
				if(nw.LeadIndexSubId__c != null) leadIdxSubIdSet.add(nw.LeadIndexSubId__c);
			}
		} else if (action == CommConst.TriggerMethod.isUpdate ) {
			// 予約データを更新する場合：
			// 到着日、出発日を変更する場合　OR　予約ステータス変更する場合（有効から→無効　OR　無効→有効)
			for (Integer i = 0; i < newList.size() ; i++) {
				Lead__c nw = newList[i];
				Lead__c od = oldList[i];
				// 到着日変更、出発日変更、予約ステータス変更
				if (nw.EntryTime__c != od.EntryTime__c || nw.Departure__c != od.Departure__c || 
					nw.CancelBool__c != od.CancelBool__c ||
					nw.LeadIndexSubId__c != od.LeadIndexSubId__c ||
					nw.LeadIndexRef__c != od.LeadIndexRef__c) {
					// 予約インデクスID
					if(nw.LeadIndexRef__c != null) leadIdxIdSet.add(nw.LeadIndexRef__c);
					// 予約インデックスSUBのID
					if(nw.LeadIndexSubId__c != null) leadIdxSubIdSet.add(nw.LeadIndexSubId__c);
				}
			}
		}
//		if (leadIdxIdMap.isEmpty()) return;
		if (leadIdxIdSet.isEmpty()) return;

		// 予約の期間範囲を取得する
		Map<Id, Date> entryDateMap = new Map<Id, Date>();
		Map<Id, Date> departDateMap = new Map<Id, Date>();
		// 予約インデックスの期間範囲を取得する
		for (AggregateResult rs : [select min(EntryTime__c) minStartDT, max(Departure__c) maxEndDT, LeadIndexRef__c leadIdxId
                                   from Lead__c where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG And LeadIndexRef__c in :leadIdxIdSet
                                   Group by  LeadIndexRef__c]) {
			// 期間情報を設定する
		    Id key = (ID)rs.get('leadIdxId');
		    Date entryDate = ((DateTime)rs.get('minStartDT')).date();
		    Date departDate = ((DateTime)rs.get('maxEndDT')).date();
		    entryDateMap.put(key,entryDate);
		    departDateMap.put( key, departDate);
        }
        // 予約インデックスSUBの期間範囲を取得する[予約に関連しているインデックスSUBが未存在のケースが存在]
		Map<Id, Date> subEntryDateMap = new Map<Id, Date>();
		Map<Id, Date> subDepartDateMap = new Map<Id, Date>();
		for (AggregateResult rs : [select min(EntryTime__c) minStartDT, max(Departure__c) maxEndDT, LeadIndexSubId__c leadIdxId
                                   from Lead__c where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG And LeadIndexSubId__c in :leadIdxSubIdSet
                                   Group by  LeadIndexRef__c, LeadIndexSubId__c]) {
			// 期間情報を設定する
		    Id key = (ID)rs.get('leadIdxId');
		    Date entryDate = ((DateTime)rs.get('minStartDT')).date();
		    Date departDate = ((DateTime)rs.get('maxEndDT')).date();
		    subEntryDateMap.put(key,entryDate);
		    subDepartDateMap.put( key, departDate);
        }
		// 予約から予約LeadIndexへ連動処理を行う
		List<LeadIndex__c> updList = new List<LeadIndex__c>();
		for (LeadIndex__c leadIdx : [select EntryDate__c,EntryTime__c, DepartureDate__c, DepartureTime__c,Nights__c,ParentLeadIndxRef__c
									 from LeadIndex__c 
									 where id in :leadIdxIdSet or (ParentLeadIndxRef__c != null and id in :leadIdxSubIdSet )]) {
			// 該当情報を設定を行う[leadIndex]
			if (leadIdx.ParentLeadIndxRef__c == null) {
				// 該当予約インデックスに、有効な予約データが未存在する場合、処理SKIP
				if (!entryDateMap.containsKey(leadIdx.Id)) continue;
				// 予約インデックス
				if (leadIdx.EntryDate__c != entryDateMap.get(leadIdx.Id) ||
					leadIdx.DepartureDate__c != departDateMap.get(leadIdx.Id)) {
						
					leadIdx.EntryDate__c = entryDateMap.get(leadIdx.Id);
					leadIdx.DepartureDate__c = departDateMap.get(leadIdx.Id);
					leadIdx.Nights__c = leadIdx.EntryDate__c.daysBetween(leadIdx.DepartureDate__c);
					
					updList.add(leadIdx);
				}
			} else {
				// 該当予約インデックスに、有効な予約データが未存在する場合、処理SKIP
				if (!subEntryDateMap.containsKey(leadIdx.Id)) continue;
				// 予約インデックスSUB情報
				if (leadIdx.EntryDate__c != subEntryDateMap.get(leadIdx.Id) ||
					leadIdx.DepartureDate__c != subDepartDateMap.get(leadIdx.Id)) {

					leadIdx.EntryDate__c = subEntryDateMap.get(leadIdx.Id);
					leadIdx.DepartureDate__c = subDepartDateMap.get(leadIdx.Id);
					leadIdx.Nights__c = leadIdx.EntryDate__c.daysBetween(leadIdx.DepartureDate__c);
				
					updList.add(leadIdx);
				}

			}
			
		}
		if (!updList.isEmpty()) update updList;
	    // 2017/01/09 宿帳データ自動作成功能  begin
	    // 宿帳自動作成する・しない切替できるように改善対応 BEGIN
		//if (action == CommConst.TriggerMethod.isInsert ) {
		if (action == CommConst.TriggerMethod.isInsert && CommDefine__c.getOrgDefaults().CashRegisterAutoCreateFlg__c) {
        // 宿帳自動作成する・しない切替できるように改善対応 END
			// 宿帳なしの予約インデックスIDを格納する
			Set<Id> noYadotyoLeadIdxIdSet = leadIdxIdSet.clone();
			//予约数据是否做有宿账
			for (AggregateResult rs : [select count(id) rsCnt, Field1__r.LeadIndexRef__c leadIdxId
										from Yadochou__c 
										where Field1__c != null
										And Field1__r.CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
										And Field1__r.LeadIndexRef__c = :leadIdxIdSet
										Group by Field1__r.LeadIndexRef__c]) {
				// 存在のデータから対象リストからはずす
				Id exitLeadIdxId = (Id)rs.get('leadIdxId');
				noYadotyoLeadIdxIdSet.remove(exitLeadIdxId);
			}
			// 宿帳情報が非存在の場合、関連の予定情報の初日の予約に予約情報へリンクを行う
			if (!noYadotyoLeadIdxIdSet.isEmpty()) {
				List<Yadochou__c> initYadoLst = new list<Yadochou__c>();
				// 2019/07/30 複数部屋に自動で宿帳作成改善対応 BY zyz BEGIN
				List<LeadIndex__c> targetLeads = [Select id, (Select Id,Name,Relcontact__c,LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c From LeadIndexRef__r order by LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c, EntryTime__c) 
													From LeadIndex__c where id in :noYadotyoLeadIdxIdSet];
				Boolean LeadIndexRefFlg = CommDefine__c.getOrgDefaults().RoomsCashRegAutoCreateFlg__c;
				// 宿帳データを新規作成
				for (LeadIndex__c leadIdx : targetLeads) {
					if (!leadIdx.LeadIndexRef__r.isEmpty()) {
						// Lead__c lead = leadIdx.LeadIndexRef__r[0];
						// initYadoLst.add(new Yadochou__c(Field15__c = lead.Relcontact__c,Field1__c = lead.id,Name =lead.Name ));
						list<Lead__c> leadIdxLst = new list<Lead__c>();
						if(LeadIndexRefFlg) leadIdxLst.addAll(leadIdx.LeadIndexRef__r);
						else leadIdxLst.add(leadIdx.LeadIndexRef__r[0]);
						set<String> roomGroupNoSet = new set<String>();
						for(Lead__c lead : leadIdxLst){
							String setkeyVal = lead.LeadIndexRef__c + '_' + lead.LeadIndexSubId__c + '_' + lead.RoomGroupNo__c;
							if (roomGroupNoSet.contains(setkeyVal)) continue;
						initYadoLst.add(new Yadochou__c(Field15__c = lead.Relcontact__c,Field1__c = lead.id,Name =lead.Name ));
							roomGroupNoSet.add(setkeyVal);
						}
					}
				}
				// 2019/07/30 複数部屋に自動で宿帳作成改善対応 BY zyz END
				if (!initYadoLst.isEmpty()) insert initYadoLst;
			}
		}
		// 2017/01/09 宿帳データ自動作成功能  end
	}

	/**
	* 予約情報から会計情報に自動連携を行う->新規または更新：ステータス変更する場合
	*  会計・会計明細・会計支払自動作成機能
	*  該当機能は After Insert/After Update実施を行う
	* 画面操作タイミングは：　予約情報を登録して、見積明細も登録済みの上で、ステータス変更を行う
	**/
	public void syncBookingInfoToAccounts(Lead__c[] newList, Lead__c[] oldList, CommConst.TriggerMethod action){

		// 予約情報:お客様ステータス->'チェックイン完'の場合：連携対象に設定を行う
		Map<Id, Lead__c> syncItemMap = new Map<Id, Lead__c>();
		// 予約情報：関連のチェックイン日を維持する：→予約情報:EntryTime__c
		Map<Id, String> checkDateMap = new Map<Id, String>();
		// 出発日情報を格納する
		Map<Id, String> checkOutDateMap = new Map<Id, String>();
		// 新規場合
		if (action == CommConst.TriggerMethod.IsInsert) {
			for (Lead__c nw: newList) {
				// チェックイン完場合
                if (nw.Field298__c == CommConst.LEAD_GUEST_ST_CI) {
                	syncItemMap.put(nw.id, nw);
                	checkDateMap.put(nw.id, nw.EntryTime__c.format('yyyyMMdd'));
                	checkOutDateMap.put(nw.Id, nw.Departure__c.format('yyyyMMdd'));
                }
			}
		}
		// 更新場合
		else if (action == CommConst.TriggerMethod.IsUpdate) {
			Integer len = newList.size();
            for (Integer i = 0; i < len; i++) {
            	Lead__c nw = newList[i];
            	Lead__c od = oldList[i];
            	// 2019/03/08 外出ー＞入室により、再度チェックイン処理ロジック不具合対応 WSQ BEGIN
            	// チェックイン完場合[ステータスは空白からチェックイン場合、関連処理を行う]
            	// if (nw.Field298__c != od.Field298__c && nw.Field298__c == CommConst.LEAD_GUEST_ST_CI) {
            	if (CommUtils.isBlank(od.Field298__c) && nw.Field298__c == CommConst.LEAD_GUEST_ST_CI) {
            	// 2019/03/08 外出ー＞入室により、再度チェックイン処理ロジック不具合対応 WSQ END
                	syncItemMap.put(nw.id, nw);
                    checkDateMap.put(nw.id, nw.EntryTime__c.format('yyyyMMdd'));
                    checkOutDateMap.put(nw.Id, nw.Departure__c.format('yyyyMMdd'));
                }
            }
		}
		// 連携対象非存在する場合、処理中止
        if (syncItemMap.isEmpty()) return;
        // 対象連携を行う[1予約*25見積明細：5000件対応]
        Set<String> checkinDateSet = new Set<String>();
        if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE == CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI) {
        	// チェックイン日で売上計上日に計算する
        	checkinDateSet.addAll(checkDateMap.values());
        } else {
        	// チエックアウト日で売上計上日に計算する
        	checkinDateSet.addAll(checkOutDateMap.values());
        }
        
        // 売上日→売上ID
        Map<String, Id> rsvDataMap = new Map<String, Id>();
        // チェックイン日の売上データが存在するかどうか、チェックを行う
        for (RsvAccount__c rsvItem: [select id, name from RsvAccount__c where name in :checkinDateSet]) {
        	rsvDataMap.put(rsvItem.name, rsvItem.id);
            checkinDateSet.remove(rsvItem.name);
        }
        // 該当チェックイン日の売上未存在する場合、新規売上データを作成する
        if (!checkinDateSet.isEmpty()) {
        	List<RsvAccount__c> rsvInsLst = new List<RsvAccount__c>();
        	for (String checkInDate: checkinDateSet) {
        		rsvInsLst.add(new RsvAccount__c(name = checkInDate));
        	}
        	//insert rsvInsLst;
        	// 2013/12/03 売上更新処理は重複登録回避機能する
        	upsert rsvInsLst name;
        	for (RsvAccount__c newRsv: rsvInsLst) {
        		rsvDataMap.put(newRsv.name, newRsv.id);
        	}
        }
        // 予約から会計データを作成する
        // Map<予約ID, 会計情報>
        Map<Id, AccountAcount__c> insAccMap = new Map<Id, AccountAcount__c>();
        for (Lead__c booking : syncItemMap.values()) {
        	String frsKey = booking.EntryTime__c.format('yyyyMMdd');
        	if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI) {
        		frsKey = booking.Departure__c.format('yyyyMMdd');
        	}
        	AccountAcount__c item = new AccountAcount__c(
               // 初期値設定を行う[BillInput_Ctrlロジック一致が必要]
               // --------- 初期値設定を行う ---------
               Field39__c = CommConst.ACC_TRADE_NORMAL,            // 取引種別
               Field40__c = '',                                    // ＶＯＩＤレシートＮｏ．
               POSNo__c = CommUtils.getPosNoByComdefine(),
               // 参照関係設定を行う
        	   frs__c = rsvDataMap.get(frsKey),
        	   // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
        	   RespectLst__c = booking.RespectLst__c,
        	   // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
        	   Relreserve__c = booking.id,
        	   relaccount__c = booking.Relcontact__c);
        	// 2014/07/31 単価定義区分と日本消費税項目会計にコピーを行う
        	//if (!CommUtils.isBlank(booking.UnitPriceDefKb__c)) item.UnitPriceDefKb__c = booking.UnitPriceDefKb__c;
        		if (booking.ExchangeTaxRate__c != null) item.ExchangeTaxRate__c = booking.ExchangeTaxRate__c;
        		item.UnitPriceDefKb__c = booking.UnitPriceDefKb__c;
        		//item.ExchangeTaxRate__c = booking.ExchangeTaxRate__c;
        			//2016/12/27 会計人數自動設定機能封印 BEGIN by zh
	        		if(AccounntStayPersonsAutoSetupFlg == false){
		        		item.Field57__c = String.valueOf(CommUtils.nullToZero(booking.StayPersons__c));
			        	item.Field66__c = String.valueOf(CommUtils.nullToZero(booking.Mans__c));
			        	item.Field67__c = String.valueOf(CommUtils.nullToZero(booking.Femails__c));
			        	item.Field68__c = String.valueOf(CommUtils.nullToZero(booking.ChildFA__c) + CommUtils.nullToZero(booking.Childs__c));
	        		}
            		//2016/12/27 会計人數自動設定機能封印 END by zh
            insAccMap.put(booking.id, item);
        }
		// 2017/05/04 店舗ごとの予約・会計権限機能対応 BEGIN
		CommLogicProcess logic = new CommLogicProcess();
		// 新規登録・変更対象データはチェック対象外に設定する
		logic.preventShopAuthCheckSetup(insAccMap.values());
		// 2017/05/04 店舗ごとの予約・会計権限機能対応 END
        // 会計情報を作成する
        insert insAccMap.values();
        // 会計ID情報を格納する
        List<Id> accIdsLst = new List<Id>();
        // 会計支払データを作成する
        //List<TTend__c> insTtendLst = new List<TTend__c>();
        for (AccountAcount__c accAcount : insAccMap.values()) {
        	/*
        	// 予約データから支払方法を取得する
        	String mediaType = syncItemMap.get(accAcount.Relreserve__c).Field315__c;
        	// 初期値設定を行う
			String ttendType = CommConst.MEDIA_TYPE_CD_01;
			if (mediaType == 'カード') ttendType = CommConst.MEDIA_TYPE_CD_02;
			else if (mediaType == '売掛') ttendType = CommConst.MEDIA_TYPE_CD_03;
			else if (mediaType == 'クーポン') ttendType = CommConst.MEDIA_TYPE_CD_11;
			String ttendTypeName = CommConst.getPaymentTypeLabelByKey(ttendType);
			// 2014/04/28 金券種別項目追加、予約から会計支払へコピー
        	TTend__c item = new TTend__c(
        	   RelAccount__c = accAcount.frs__c,
        	   Field1__c = accAcount.id,
        	   Field2__c = ttendType,
        	   Field3__c = ttendTypeName,
        	   CouponTypeLst__c = syncItemMap.get(accAcount.Relreserve__c) == null ? null : syncItemMap.get(accAcount.Relreserve__c).CouponTypeLst__c,
        	   // --------- 初期値設定を行う ---------
               Field4__c = '1',
               Field5__c = '1',
               POSNo__c = CommUtils.getPosNoByComdefine()
        	   );
            insTtendLst.add(item);
            */
            accIdsLst.add(accAcount.Id);
        }
/* 2015/07/17 ダミな会計支払情報を作成なしの対応 BEGIN
        insert insTtendLst;
// 2015/02/09 会計支払情報の金額の再自動設定 BEGIN
List<Id> ttendIdsLst = new List<Id>();
for (TTend__c ttend : insTtendLst) {
	ttendIdsLst.add(ttend.Id);
}
// 2015/04/15 会計支払情報自動作成するがどうか制御対応 BEGIN
if (CommDefine__c.getOrgDefaults().AccountPaymentIsAutoGenFlg__c) {
if (!ttendIdsLst.isEmpty()) BillSimpleHelp.autoCalTTendInfo(ttendIdsLst);
}
*/
// 2019/06/14 JINYABUG-1842 bug fix by zy BEGIN
try{
if (CommDefine__c.getOrgDefaults().AccountPaymentIsAutoGenFlg__c && System.IsBatch() == false) {
// 2019/06/14 JINYABUG-1842 bug fix by zy END	
    if (!accIdsLst.isEmpty()) BillSimpleHelp.autoCalTTendInfo(accIdsLst);
}
// 2019/06/14 JINYABUG-1842 bug fix by zy BEGIN
}catch(Exception e){}
// 2019/06/14 JINYABUG-1842 bug fix by zy END
// 2015/07/17 ダミな会計支払情報を作成なしの対応 END
// 2015/04/15 会計支払情報自動作成するがどうか制御対応 END
// 2015/02/09 会計支払情報の金額の再自動設定 END

        // 関連の明細データを連携を行う
        //Map<Id, List<Tran1__c>> tranMap = new Map<Id, List<Tran1__c>>();
        List<Tran1__c> tranInsLst = new List<Tran1__c>();
        List<Ttend__c> tendInsLst = new List<Ttend__c>();
        // 親見積もり明細ID/インサートする順番
        Map<Id, Integer> parentTranMap = new Map<Id, Integer>();
        // ParentId/Childs<List>
        Map<Id, List<Tran1__c>> planDetailMap = new Map<Id, List<Tran1__c>>();
        // 見積明細を取得する
        List<BookingEstimateItem__c> relBookingEstList = [ Select Id ,Name ,refBooking__c ,refAccountMaster__r.Name,ProductName__c,UnitPriceDefKb__c,
                                                ServiceRate__c ,SpecialTax__c,TaxRate__c ,ActionType__c,ParentBookingItemRef__c,RowNo__c,PaymentType__c,
                                                refAccountMaster__r.Field5__c, refAccountMaster__r.TaxRateCal__c, refAccountMaster__r.ServiceRate__c, refAccountMaster__r.SpecialTax__c,
                                                A__c ,AccountOutside__c ,Amount__c ,DPChange__c ,Field10__c ,Field11__c ,Field3__c ,Field4__c ,Field6__c ,Field7__c ,Field8__c ,Field9__c ,GPChange__c ,NoneAccount__c ,OES__c ,OP__c ,OrderDate__c ,Orderer__c ,PLU__c ,SCP_5__c ,Supplier__c ,Total__c ,UnitPrice__c ,X1__c ,X3_2__c ,X4_3__c ,refAccountMaster__c
                                                ,refBooking__r.EntryTime__c,refBooking__r.Departure__c
                                                ,PlanDetailSyncInfo__c
												// 2016/12/27 見積明細利用日機能対応 BEGIN zyz
                                                ,UseDate__c
												// 2016/12/27 見積明細利用日機能対応 END zyz
												// 2017/12/13 見積明細非表示機能対応 WGCH BEGIN
												,InvoiceNoShowFlg__c 
												,NoShowRequestFlg__c
												// 2017/12/13 見積明細非表示機能対応 WGCH END
												// 2018/08/31 料理進捗機能追加 by zy BEGIN
												,CookInfo__c
												// 2018/08/31 料理進捗機能追加 by zy END
												// 2019/07/30 軽減税率機能対応 WGCH BEGIN
												,TankanonetaxNew__c
												// 2019/07/30 軽減税率機能対応 WGCH END
												// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
												,OptionNo__c
												// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
                                                From BookingEstimateItem__c
                                                Where refBooking__c in :syncItemMap.keyset() 
                                                Order By refBooking__c, Name];//) {
        
        // 支払の見積もり明細情報が存在する場合
        Boolean isHavePayEstItemFlg = false;
        for (BookingEstimateItem__c bookItem: relBookingEstList) {
        	if (bookItem.ActionType__c == CommConst.PROD_ACTION_TYPE_PY) {
        		// 支払明細情報が存在する場合、会計支払明細に作成を行う
        		isHavePayEstItemFlg = true;
        		break;
        	}
        }
		// 支払種別→支払メデイアに交換用MAP
		Map<String, String> paymentTypeToMediaLabMap = null;
        if (isHavePayEstItemFlg) {
        	// 支払情報ラベル変換情報を取得する
        	BillSimpleHelp billHelp = new BillSimpleHelp('');
        	paymentTypeToMediaLabMap = billHelp.getPaymentTypeToMediaLabMap();
        } else {
        	paymentTypeToMediaLabMap = new Map<String, String>();
        }
        
        for (BookingEstimateItem__c bookItem: relBookingEstList) {
            /*
            List<Tran1__c> tranSubLst = null;
            // 移行データを取得して、会計明細へ送信を行う
            if (!tranMap.containsKey(bookItem.refBooking__c)) {
            	tranSubLst = new List<Tran1__c>();
            	tranMap.put(bookItem.refBooking__c, tranSubLst);
            } else {
            	tranSubLst = tranMap.get(bookItem.refBooking__c);
            }*/
            // 情報をコピして、リストへ追加する[会計情報を取得する]
            AccountAcount__c accInfo = insAccMap.get(bookItem.refBooking__c);
            
            if (bookItem.ActionType__c == CommConst.PROD_ACTION_TYPE_PY) {
            	// 見積もり明細（支払）→会計支払に表示
            	Ttend__c cpTend = copyBookItemToTtend(bookItem, accInfo, paymentTypeToMediaLabMap);
            	tendInsLst.add(cpTend);
            } else {
	            // 会計情報にて、見積もり明細情報を設定する
	            Tran1__c cpTran = copyBookItemToTran(bookItem, accInfo);
	            if (CommUtils.IsBlank(bookItem.ParentBookingItemRef__c)) {
	            	// プラン明細自動展開しないフラグを設定する
	            	//cpTran.PlanExpandFlg__c = true;
	            	// 普通の見積もり明細情報を格納する[プラン含め]
	            	tranInsLst.add(cpTran);
	            	// 親のプランを設定する
	            	parentTranMap.put(bookItem.Id, tranInsLst.size());
	            } else {
	            	// プラン単位で、プラン明細の見積もり明細情報を配列に格納する
	            	if (!planDetailMap.containsKey(bookItem.ParentBookingItemRef__c)) planDetailMap.put(bookItem.ParentBookingItemRef__c, new List<Tran1__c>());
	            	planDetailMap.get(bookItem.ParentBookingItemRef__c).add(cpTran);
	            }
            }
        }
        // 見積もり明細は子見積もり明細存在するがどうかチェックを行う
        for (Id parentId : planDetailMap.keySet()) {
        	// 親のプランが存在する場合
			if (parentTranMap.containsKey(parentId)) {
				Integer idx = parentTranMap.get(parentId)-1;
				Tran1__c parentTran = tranInsLst[idx];
				parentTran.PlanExpandFlg__c = true;
			}
        }
        // 親の会計明細を作成する
        insert tranInsLst;
        // プラン明細が存在する場合、該当明細は会計明細にコピーを行う
        List<Tran1__c> subTranInsLst = new List<Tran1__c>();
        for (Id parentId : planDetailMap.keySet()) {
			if (parentTranMap.containsKey(parentId)) {
				Integer idx = parentTranMap.get(parentId)-1;
				Tran1__c parentTran = tranInsLst[idx];
				for (Tran1__c tran : planDetailMap.get(parentId)) {
					tran.ParentTran1Ref__c = parentTran.Id;
				}
				subTranInsLst.addAll(planDetailMap.get(parentId));
			}
        }
        if (!subTranInsLst.isEmpty()) insert subTranInsLst;
        if (!tendInsLst.isEmpty()) insert tendInsLst;

	}
	
	/**
	* 予約情報から会計情報に自動連携を行う->：予約ステータスは有効から無効に変更
	*  予約データはキャンセルされる場合、関連の会計データもキャンセルされる処理を行う
	*  該当機能は After Update実施を行う
	**/
	public void syncBookingCancelInfoToAccounts(Lead__c[] newList, Lead__c[] oldList, CommConst.TriggerMethod action){
		// キャンセルされる予約IDsを格納する
		Set<Id> cancelLeads = new Set<Id>();
		Integer len = newList.size();
        // 2019/04/15 改善要望：予約から活動の作成 by zy BEGIN
        Set<Id> cancelEvents = new Set<Id>();
        // 2019/04/15 改善要望：予約から活動の作成 by zy END
        for (Integer i = 0; i < len; i++) {
        	Lead__c nw = newList[i];
        	Lead__c od = oldList[i];
            // 予約ステータスは変更して、変更後に無効な予約データの場合
            if (nw.CancelBool__c != od.CancelBool__c && nw.CancelBool__c == CommConst.LEAD_ST_CANCEL_FLG) {
            	cancelLeads.add(nw.Id);
                // 2019/04/15 改善要望：予約から活動の作成 by zy BEGIN
                if (!CommUtils.isBlank(nw.EventId__c)) cancelEvents.add(nw.EventId__c);
                // 2019/04/15 改善要望：予約から活動の作成 by zy END
            }
            // 2018/04/18 お客様ステータスは設定ありから未設定する場合、既存の会計情報はVOIDに変更する BEGIN
            //lead.Field298__c != CommConst.LEAD_GUEST_ST_CI
            else if (CommUtils.isBlank(nw.Field298__c) && !CommUtils.isBlank(od.Field298__c)) {
                cancelLeads.add(nw.Id);
            }
            // 2018/04/18 お客様ステータスは設定ありから未設定する場合、既存の会計情報はVOIDに変更する END
        }
        if (cancelLeads.isEmpty()) return;
        String cancelDateTime = DateTime.valueOf(String.valueOf(System.now())).format('yyyyMMddHHmmss');
        List<AccountAcount__c> cancelAcounts = [select id, Field39__c,Field53__c from AccountAcount__c where Relreserve__c = :cancelLeads];
        for (AccountAcount__c acc : cancelAcounts) {
        	acc.Field39__c = CommConst.ACC_TRADE_VOID;
        }
        if (!cancelAcounts.isEmpty()) update cancelAcounts;
        // 2019/04/15 改善要望：予約から活動の作成 by zy BEGIN
        if (!cancelEvents.isEmpty()) delete [select id from Event where id = :cancelEvents]; 
        // 2019/04/15 改善要望：予約から活動の作成 by zy END
	}
	/**
	* 予約から会計に情報連動を行う
	* 予約側に、設定情報を変更されている場合、会計に連携処理機能
	* Action: Lead Update After
	*/
	public void syncBookingUpdInfoToAccount(Lead__c[] newList, Lead__c[] oldList, CommConst.TriggerMethod action){
		// map<予約ID, 部屋名>
		set<Id> changeLeadIdSet = new set<Id>();
		Integer len = newList.size();
        for (Integer i = 0; i < len; i++) {
        	Lead__c nw = newList[i];
        	Lead__c od = oldList[i];
            // 予約ステータスは変更して、変更後に無効な予約データの場合
            if (nw.Rroom__c != od.Rroom__c) {
            	changeLeadIdSet.add(nw.Id);
            }
        }
        if (changeLeadIdSet.isEmpty()) return;
        List<AccountAcount__c> relateAcounts = [select id,  Relreserve__r.Rroom__r.DisplayNo__c, 
        													Relreserve__r.Rroom__r.Seq__c, 
        													Relreserve__r.Rroom__r.Name,
        													RoomName__c,RoomSeq__c,RoomDisplayNo__c from AccountAcount__c where Relreserve__c = :changeLeadIdSet];
        for (AccountAcount__c acc : relateAcounts) {
			// 部屋情報設定
			acc.RoomDisplayNo__c = acc.Relreserve__r.Rroom__r.DisplayNo__c;
			acc.RoomSeq__c = acc.Relreserve__r.Rroom__r.Seq__c;
			acc.RoomName__c = acc.Relreserve__r.Rroom__r.Name;
        }
        if (!relateAcounts.isEmpty()) update relateAcounts;
	}
	/**
	* 予約情報の変更に従って、関連の予約情報も自動更新を行う
	**/
	private void syncBookingInfoToRelLeads(Map<Id, Lead__c> chgPeoplesMap, Map<Id, Lead__c> chgGuestStatusMap, Map<Id, Lead__c> chgLeadStatusMap) {
		/*
		List<Lead__c> syncInfoToRelLeads = [select id,LeadIndexRef__c, LeadIndexSubId__c,RoomGroupNo__c 
											,StayPersons__c,Mans__c,Femails__c,ChildFA__c,Childs__c
											,EntryTime__c
											from Lead__c where id in :changeLeadIds];
		*/
		// 連泊予約一括チェックイン機能制御フラグ
		Boolean isBatchCheckinFlg = CommDefine__c.getOrgDefaults().RenpakuBatchCheckinIsCanFlg__c;
		// 2019/02/15 チェックアウト、連泊の場合、該当泊の前泊もチェックアウトできるよに改善対応 WSQ BEGIN
		Boolean isBatchCheckoutFlg = CommDefine__c.getOrgDefaults().RenpakuBatchCheckOutIsCanFlg__c;
		// 2019/02/15 チェックアウト、連泊の場合、該当泊の前泊もチェックアウトできるよに改善対応 WSQ END
		// 変更される予約情報リストを格納する
		Set<Id> leadIdxIds = new Set<Id>();
		Set<Id> leadSubIdxIds = new Set<Id>();
		Set<Decimal> groupNos = new Set<Decimal>();
		
		Map<String, Lead__c> uiChangePeopleLeadMap = new Map<String, Lead__c>(); 	// 画面から予約人數変更の予約情報を格納
		Map<String, Lead__c> uiChangeGuestStatusMap = new Map<String, Lead__c>(); 	// 画面からお客様ステータス変更の予約情報を格納
		Map<String, Lead__c> uiChangeLeadStatusMap = new Map<String, Lead__c>(); 	// 画面から予約ステータス変更の予約情報を格納
		
		for (Lead__c lead : chgPeoplesMap.values()) {
			leadIdxIds.add(lead.LeadIndexRef__c);
			leadSubIdxIds.add(lead.LeadIndexSubId__c);
			groupNos.add(lead.RoomGroupNo__c);
			uiChangePeopleLeadMap.put(getKeyOfSameGroupLead(lead.LeadIndexRef__c,lead.LeadIndexSubId__c,lead.RoomGroupNo__c), lead);
		}
		for (Lead__c lead : chgGuestStatusMap.values()) {
			leadIdxIds.add(lead.LeadIndexRef__c);
			leadSubIdxIds.add(lead.LeadIndexSubId__c);
			groupNos.add(lead.RoomGroupNo__c);
			uiChangeGuestStatusMap.put(getKeyOfSameGroupLead(lead.LeadIndexRef__c,lead.LeadIndexSubId__c,lead.RoomGroupNo__c), lead);
		}
		// 2015/07/30 キャンセル一括設定・しない制御フラグ機能追加
		Boolean batchCanleFlg = CommDefine__c.getOrgDefaults().RenpakuBatchCancelIsCanFlg__c;
		for (Lead__c lead : chgLeadStatusMap.values()) {
			// キャンセルに変更されるの場合
			if (!batchCanleFlg && lead.CancelBool__c == CommConst.LEAD_ST_CANCEL_FLG) continue;
			leadIdxIds.add(lead.LeadIndexRef__c);
			leadSubIdxIds.add(lead.LeadIndexSubId__c);
			groupNos.add(lead.RoomGroupNo__c);
			uiChangeLeadStatusMap.put(getKeyOfSameGroupLead(lead.LeadIndexRef__c,lead.LeadIndexSubId__c,lead.RoomGroupNo__c), lead);
		}
		
		List<Lead__c> updLeads = new List<Lead__c>();
		// 処理対象の予約の関連予約情報（同じグループ）の予約
		for (Lead__c lead : [	select id, LeadIndexRef__c, LeadIndexSubId__c,RoomGroupNo__c
										,StayPersons__c,Mans__c,Femails__c,ChildFA__c,Childs__c
										,EntryTime__c
										// お客様ステータス
										,Field298__c
										// 予約ステータス
										,ReservedStatus__c
								from lead__c 
								where LeadIndexRef__c in :leadIdxIds And LeadIndexSubId__c in :leadSubIdxIds And RoomGroupNo__c in :groupNos
								// 有効な予約のみ関連更新を行う
								And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
								])  {
			// 指定の予約情報により、以後の関聯予約情報を更新する
			String key = getKeyOfSameGroupLead(lead.LeadIndexRef__c,lead.LeadIndexSubId__c,lead.RoomGroupNo__c);			
			Boolean isChangeFlg = false;
			// 会計人數	
			if (uiChangePeopleLeadMap.containsKey(key)) {
				Lead__c org = uiChangePeopleLeadMap.get(key);
				// 未来日の予約情報処理を行う
				if (lead.EntryTime__c > org.EntryTime__c) {
		            if (lead.StayPersons__c != org.StayPersons__c || 
		            	lead.Mans__c != org.Mans__c ||
		            	lead.Femails__c != org.Femails__c || 
		            	lead.ChildFA__c != org.ChildFA__c || 
		            	lead.Childs__c != org.Childs__c ) {
		            	// 人數更新を行う
		            	lead.StayPersons__c = org.StayPersons__c;
		            	lead.Mans__c 		= org.Mans__c;
		            	lead.Femails__c		= org.Femails__c;
		            	lead.ChildFA__c 	= org.ChildFA__c;
		            	lead.Childs__c 		= org.Childs__c;
		            	
		            	isChangeFlg = true;
		            	//updLeads.add(lead);
		            }
				}
			} // 
			// お客様ステータス連動
			if (uiChangeGuestStatusMap.containsKey(key)) {
				Lead__c org = uiChangeGuestStatusMap.get(key);
				// 未来日の予約情報処理を行う
				if (lead.EntryTime__c > org.EntryTime__c) {
		            // お客様のステータスを変更される場合
		            // 2019/02/15 チェックアウト、連泊の場合、該当泊の前泊もチェックアウトできるよに改善対応 WSQ BEGIN
		            //if (isBatchCheckinFlg && lead.Field298__c != CommConst.LEAD_GUEST_ST_CI) {
		            if (org.Field298__c == CommConst.LEAD_GUEST_ST_CI && isBatchCheckinFlg && lead.Field298__c != CommConst.LEAD_GUEST_ST_CI) {
		             // 2019/02/15 チェックアウト、連泊の場合、該当泊の前泊もチェックアウトできるよに改善対応 WSQ END
		            	//chgGuestStatusMap.put(nw.id, nw);
		            	lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
		            	// 2019/10/15 チェックイン時に自動音声で通知 BY zyz BEGIN
		            	lead.SysIsBulkCheckinFlg__c = !lead.SysIsBulkCheckinFlg__c;
		            	// 2019/10/15 チェックイン時に自動音声で通知 BY zyz BEGIN
		            	isChangeFlg = true;
		            }
				}
				// 2019/02/15 チェックアウト、連泊の場合、該当泊の前泊もチェックアウトできるよに改善対応 WSQ BEGIN
	            // お客様のステータスを変更される場合
	            // 過去日の予約情報処理を行う
				if (lead.EntryTime__c < org.EntryTime__c) {
		            // お客様のステータスを変更される場合
		            if (org.Field298__c == CommConst.LEAD_GUEST_ST_CO && isBatchCheckoutFlg && lead.Field298__c != CommConst.LEAD_GUEST_ST_CO) {
		            	//chgGuestStatusMap.put(nw.id, nw);
		            	lead.Field298__c = CommConst.LEAD_GUEST_ST_CO;
		            	isChangeFlg = true;
		            }
				}
				// 2019/02/15 チェックアウト、連泊の場合、該当泊の前泊もチェックアウトできるよに改善対応 WSQ END
			}
			// 予約ステータス連動
			if (uiChangeLeadStatusMap.containsKey(key)) {
				Lead__c org = uiChangeLeadStatusMap.get(key);
				// 未来日の予約情報処理を行う
				if (lead.EntryTime__c > org.EntryTime__c) {
		            // 予約ステータス
	            	lead.ReservedStatus__c = org.ReservedStatus__c;
	            	isChangeFlg = true;
				}
			}
			// 変更される予約を格納する
			if (isChangeFlg) updLeads.add(lead);
			
		} // for (Lead__c lead : [	select 
		if (!updLeads.isEmpty()) update updLeads;
		
	}
	private static String getKeyOfSameGroupLead(Id leadIdxId, Id leadSubIdx, Decimal groupNo) {
		return 	  CommUtils.nullToBlank(leadIdxId) 
				+ '_' 
				+ CommUtils.nullToBlank(leadSubIdx) 
				+ '_' 
				+ CommUtils.nullToBlank(groupNo);
	}
	/**
	* 予約の予約人數変更すると、関聯の会計人數へ連動を行う
	* 予約人數、男性、女性、子供A,子供B数を変更される場合、関聯会計へ同期を行う
	**/
	public void syncBookingInfoToRelLeadsProc(Lead__c[] newList, Lead__c[] oldList, CommConst.TriggerMethod action){
		Map<Id, Lead__c> chgPeoplesMap = new Map<Id, Lead__c>();
		Map<Id, Lead__c> chgGuestStatusMap = new Map<Id, Lead__c>();
		Map<Id, Lead__c> chgLeadStatusMap = new Map<Id, Lead__c>();
		// 連泊予約一括チェックイン機能制御フラグ
		Boolean isBatchCheckinFlg = CommDefine__c.getOrgDefaults().RenpakuBatchCheckinIsCanFlg__c;
		// 2019/02/15 チェックアウト、連泊の場合、該当泊の前泊もチェックアウトできるよに改善対応 WSQ BEGIN
		Boolean isBatchCheckoutFlg = CommDefine__c.getOrgDefaults().RenpakuBatchCheckOutIsCanFlg__c;
		// 2019/02/15 チェックアウト、連泊の場合、該当泊の前泊もチェックアウトできるよに改善対応 WSQ END
		// 2019/07/15 多泊の場合、外出の場合、多泊の予約に同じ状態を更新する BY zyz BEGIN
		Boolean isBatchGoingoutFlg = CommDefine__c.getOrgDefaults().RenpakuBatchGoingoutIsCanFlg__c;
        // 外出の予約リスト
        List<Lead__c> goingOutLeads = new List<Lead__c>();
        List<Lead__C> goingInLeads = new List<Lead__c>();
		// 2019/07/15 多泊の場合、外出の場合、多泊の予約に同じ状態を更新する BY zyz END
		Integer len = newList.size();
        for (Integer i = 0; i < len; i++) {
        	Lead__c nw = newList[i];
        	Lead__c od = oldList[i];
/*
System.debug(LoggingLevel.info, 'nw.Name='+nw.Name);
System.debug(LoggingLevel.info, 'nw.StayPersons__c='+nw.StayPersons__c);
System.debug(LoggingLevel.info, 'od.StayPersons__c='+od.StayPersons__c);
System.debug(LoggingLevel.info, 'Persons__c='+(nw.StayPersons__c != od.StayPersons__c));
System.debug(LoggingLevel.info, 'nw.Mans__c='+nw.Mans__c);
System.debug(LoggingLevel.info, 'od.Mans__c='+od.Mans__c);
System.debug(LoggingLevel.info, 'Mans__c='+(nw.Mans__c != od.Mans__c));
System.debug(LoggingLevel.info, 'nw.Femails__c='+nw.Femails__c);
System.debug(LoggingLevel.info, 'od.Femails__c='+od.Femails__c);
System.debug(LoggingLevel.info, 'Femails__c='+(nw.Femails__c != od.Femails__c));
System.debug(LoggingLevel.info, 'nw.ChildFA__c='+nw.ChildFA__c);
System.debug(LoggingLevel.info, 'od.ChildFA__c='+od.ChildFA__c);
System.debug(LoggingLevel.info, 'ChildFA__c='+(nw.ChildFA__c != od.ChildFA__c));
System.debug(LoggingLevel.info, 'nw.Childs__c='+nw.Childs__c);
System.debug(LoggingLevel.info, 'od.Childs__c='+od.Childs__c); 
System.debug(LoggingLevel.info, 'Childs__c='+(nw.Childs__c != od.Childs__c));
*/
            // 人數変更の場合
            if (nw.StayPersons__c != od.StayPersons__c || 
            	nw.Mans__c != od.Mans__c ||
            	nw.Femails__c != od.Femails__c || 
            	nw.ChildFA__c != od.ChildFA__c || 
            	nw.Childs__c != od.Childs__c ) {
            	chgPeoplesMap.put(nw.Id, nw);

//System.debug(LoggingLevel.info, '★★★★★★nw.Name★★★★★★★'+nw.Name);
            }
            // お客様のステータスを変更される場合
            if (isBatchCheckinFlg && nw.Field298__c != od.Field298__c && nw.Field298__c == CommConst.LEAD_GUEST_ST_CI) {
            	chgGuestStatusMap.put(nw.id, nw);
            }
            // 2019/02/15 チェックアウト、連泊の場合、該当泊の前泊もチェックアウトできるよに改善対応 WSQ BEGIN
            if (isBatchCheckoutFlg && nw.Field298__c != od.Field298__c && nw.Field298__c == CommConst.LEAD_GUEST_ST_CO) {
            	chgGuestStatusMap.put(nw.id, nw);
            }
            // 2019/02/15 チェックアウト、連泊の場合、該当泊の前泊もチェックアウトできるよに改善対応 WSQ END
            // 予約ステータスを変更される場合
            if (nw.ReservedStatus__c != od.ReservedStatus__c) {
            	chgLeadStatusMap.put(nw.id, nw);
            }
            // 2019/07/15 多泊の場合、外出の場合、多泊の予約に同じ状態を更新する BY zyz BEGIN
            // お客様のステータスを変更される場合
            if (isBatchGoingoutFlg && nw.Field298__c != od.Field298__c 
                    && nw.Field298__c == CommConst.LEAD_GUEST_ST_OUT) 
            	goingOutLeads.add(nw);
            if (!isBatchCheckinFlg && nw.Field298__c != od.Field298__c 
                    && od.Field298__c == CommConst.LEAD_GUEST_ST_OUT && nw.Field298__c == CommConst.LEAD_GUEST_ST_CI)
                goingInLeads.add(nw);
            // 2019/07/15 多泊の場合、外出の場合、多泊の予約に同じ状態を更新する BY zyz END
        }
/*
System.debug(LoggingLevel.info, 'chgPeoplesMap='+chgPeoplesMap);
System.debug(LoggingLevel.info, 'chgGuestStatusMap='+chgGuestStatusMap);
System.debug(LoggingLevel.info, 'chgLeadStatusMap='+chgLeadStatusMap);
*/
        // 処理対象予約情報が非存在の場合、処理終了
        // 2019/07/15 多泊の場合、外出の場合、多泊の予約に同じ状態を更新する BY zyz BEGIN
        if (chgPeoplesMap.isEmpty() && chgGuestStatusMap.isEmpty() && chgLeadStatusMap.isEmpty() 
                && goingOutLeads.isEmpty() && goingInLeads.isEmpty() ) return;
        // 2019/07/15 多泊の場合、外出の場合、多泊の予約に同じ状態を更新する BY zyz END
        // 関聯の会計へ更新を行う
        if (!chgPeoplesMap.isEmpty()) {
        	// 2017/04/11 現在の会計情報はPOSから取り込みのデータ場合、該当会計人數は予約へ連携する、しない処理対応 BEGIN
			//List<AccountAcount__c> chgAcounts = [select id, Relreserve__c,Field57__c,Field66__c,Field67__c,Field68__c from AccountAcount__c where Relreserve__c = :chgPeoplesMap.keySet()];
			List<AccountAcount__c> chgAcounts = [select id, Field150__c, Relreserve__c,Field57__c,Field66__c,Field67__c,Field68__c from AccountAcount__c where Relreserve__c = :chgPeoplesMap.keySet()];
			// 2017/04/11 現在の会計情報はPOSから取り込みのデータ場合、該当会計人數は予約へ連携する、しない処理対応 END
	        for (AccountAcount__c acc : chgAcounts) {
	        	// 2017/04/11 現在の会計情報はPOSから取り込みのデータ場合、該当会計人數は予約へ連携する、しない処理対応 BEGIN
	        	// POSデータの人數は連携なし　かつ　該当会計データはPOS取り込み会計データの場合
	        	if (!CommConst.POSDATAISSYNCFLG && CommLogicProcess.isPosImportData(acc)) continue;
	        	// 2017/04/11 現在の会計情報はPOSから取り込みのデータ場合、該当会計人數は予約へ連携する、しない処理対応 END
	        	Lead__c ld = chgPeoplesMap.get(acc.Relreserve__c);
	        	acc.Field57__c = String.valueOf(CommUtils.nullToZero(ld.StayPersons__c));
	        	acc.Field66__c = String.valueOf(CommUtils.nullToZero(ld.Mans__c));
	        	acc.Field67__c = String.valueOf(CommUtils.nullToZero(ld.Femails__c));
	        	acc.Field68__c = String.valueOf(CommUtils.nullToZero(ld.ChildFA__c) + CommUtils.nullToZero(ld.Childs__c));
	        }
	        update chgAcounts;
        }
//System.debug(LoggingLevel.INFO, 'chgPeoplesMap:::' + chgPeoplesMap);
//System.debug(LoggingLevel.INFO, 'chgGuestStatusMap:::' + chgGuestStatusMap);
//System.debug(LoggingLevel.INFO, 'chgLeadStatusMap:::' + chgLeadStatusMap);
        // 関聯の予約情報を連動処理を行う
		syncBookingInfoToRelLeads(chgPeoplesMap, chgGuestStatusMap, chgLeadStatusMap);
        // 2019/07/15 多泊の場合、外出の場合、多泊の予約に同じ状態を更新する BY zyz BEGIN
        if (!goingOutLeads.isEmpty()) syncInfoToRelLeadsGoingout(goingOutLeads,false);
        if (!goingInLeads.isEmpty()) syncInfoToRelLeadsGoingout(goingInLeads,true);
        // 2019/07/15 多泊の場合、外出の場合、多泊の予約に同じ状態を更新する BY zyz END
	}

	/**
	* 予約情報から会計情報に自動連携を行う->：有効な予約データ　AND　お客様情報状態変更　AND　新客様情報はチェックアウトする場合
	*  予約データはチェックアウトのされる場合、関連の会計データは既に会計済みのチェックを行う（会計日時は存在AND集計対象が必要）
	*  該当機能は Before Update実施を行う
	* 2014/03/24 (BIGUSERリリース後の使う不便するため、該当チェック(checkoutByAcountsInfo)を外す)
	**//*
	public void checkoutByAcountsInfo(Lead__c[] newList, Lead__c[] oldList, CommConst.TriggerMethod action){
        Map<Id, Lead__c> leadsMap = new Map<Id, Lead__c>();
        Integer len = newList.size();
        for (Integer i = 0; i < len; i++) {
        	Lead__c nw = newList[i];
        	Lead__c od = oldList[i];
            // 予約ステータスは変更して、変更後に無効な予約データの場合
            if (nw.CancelBool__c != CommConst.LEAD_ST_CANCEL_FLG &&
            	nw.Field298__c != od.Field298__c && nw.Field298__c == CommConst.LEAD_GUEST_ST_CO) {
            	leadsMap.put(nw.Id, nw);
            }
        }
        if (leadsMap.isEmpty()) return;
        // 既に会計済みチエックを行う
        List<AccountAcount__c> acounts = [select id, Relreserve__c from AccountAcount__c 
        									where Relreserve__c = :leadsMap.keySet() And Field53__c != null And Field39__c = '00' ];
        Set<Id> existLeadsIdset = new Set<Id>();
        for (AccountAcount__c acc : acounts) {
        	existLeadsIdset.add(acc.Relreserve__c);
        }
        for (Id leadId : existLeadsIdset) {
        	leadsMap.remove(leadId);
        }
        for (Lead__c lead : leadsMap.values()) {
        	//が未会計するため、チェックアウトできません。
        	lead.addError(lead.Name + Label.MSG_002_0375);
        }
	}*/
	/**
	* 見積明細→会計明細データコピー機能
	**/
	private Tran1__c copyBookItemToTran(BookingEstimateItem__c bookItem, AccountAcount__c acc) {
		Decimal unitPrice = (bookItem.UnitPrice__c == null ? bookItem.refAccountMaster__r.Field5__c : bookItem.UnitPrice__c);
		Decimal serviceRate = (bookItem.ServiceRate__c == null ? bookItem.refAccountMaster__r.ServiceRate__c : bookItem.ServiceRate__c);
		Decimal specialTax = (bookItem.SpecialTax__c == null ? bookItem.refAccountMaster__r.SpecialTax__c : bookItem.SpecialTax__c);
		Decimal taxRate = (bookItem.TaxRate__c == null ? bookItem.refAccountMaster__r.TaxRateCal__c : bookItem.TaxRate__c);
		// 2016/12/27 見積明細利用日機能対応 BEGIN zyz
		Date useDate = bookItem.refBooking__r.EntryTime__c.date();
		// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH BEGIN
		if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI && !CommConst.BOOKEST_USERDATE_FLG) {
		// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH END
    		useDate = bookItem.refBooking__r.Departure__c.date();
    	}
    	// 2016/12/27 見積明細利用日機能対応 END zyz
		Tran1__c newItem = new Tran1__c(
		    RelAccount__c = acc.frs__c,                          // 売上
		    Field1__c  = acc.Id,                                 // 会計
            Field7__c  = bookItem.refAccountMaster__c,           // 商品コード
            Field25__c = bookItem.Field4__c,                     // リンクＤＰコード
//            Field26__c = bookItem.OP__c,                         // 会計OP
            noneaccount__c = bookItem.NoneAccount__c,            // 集計対象外
			// 2013/08/22 編集後の商品名称で会計明細に設定を行う
			Field5__c = bookItem.ProductName__c,
//		    Field5__c = bookItem.refAccountMaster__r.Name,       // 商品名称（または券名称）
		    ActionType__c = bookItem.ActionType__c,              // 商品処理種別
		    TaxRate__c = taxRate,                // 消費税
		    ServiceRate__c = serviceRate,        // サービス料
		    SpecialTax__c = specialTax,          // 特別税
		    Field20__c = String.valueOf(unitPrice),              // 単価(税込)
		    Field21__c = String.ValueOf(bookItem.Amount__c),     // 数量
		    Field23__c = String.valueOf(bookItem.Total__c),      // $合計金額(税込)
		    // --------- 初期値設定を行う ---------
		    // 商品種別 ->SCP(5) = '0'    M   ; SCP(5) != '0'   P
		    Field2__c = (bookItem.SCP_5__c == '0') ? 'M' : 'P',
            // 処理種別１
            Field3__c = '1',
            // 処理種別２
            Field4__c = '1',
            // 消費税　種別(消費税＝０の場合、非課税/)
            Field27__c = (bookItem.TaxRate__c == 0 ? '2' : '1'),
            // 2014/08/15 単価定義区分コピー
            UnitPriceDefKb__c = bookItem.UnitPriceDefKb__c,
            // POSNo.
            POSNo__c = CommUtils.getPosNoByComdefine()
            // 2015/01/04 RowNo__cコピー追加
            ,RowNo__c = bookItem.RowNo__c
            // 2015/02/09 支払種別コピー追加
            ,PaymentType__c = bookItem.PaymentType__c
            // 2015/10/19 
            ,PlanDetailSyncInfo__c = bookItem.PlanDetailSyncInfo__c
            // 2016/12/27 見積明細利用日機能対応 BEGIN zyz
            ,UseDate__c = (bookItem.UseDate__c == null ? useDate : bookItem.UseDate__c)
            // 2016/12/27 見積明細利用日機能対応 END zyz
            // 2017/12/13 見積明細非表示機能対応 WGCH BEGIN
            ,InvoiceNoShowFlg__c = bookItem.InvoiceNoShowFlg__c
            ,NoShowRequestFlg__c = bookItem.NoShowRequestFlg__c
            // 2017/12/13 見積明細非表示機能対応 WGCH END
            // 2018/08/31 料理進捗機能追加 by zy BEGIN
			,CookInfo__c = bookItem.CookInfo__c
			// 2018/08/31 料理進捗機能追加 by zy END
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			,TankanonetaxNew__c = bookItem.TankanonetaxNew__c
			// 2019/07/30 軽減税率機能対応 WGCH END
		);
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
		if(bookItem.OptionNo__c != null) newItem.OptionNo__c = bookItem.OptionNo__c;
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
		return newItem;
	}
	/**
	* 見積明細（支払）→会計支払にコピーを行う
	**/
	private Ttend__c copyBookItemToTtend(BookingEstimateItem__c bookItem, AccountAcount__c acc, Map<String, String> payTypeToMediaLabMap) {
		// 支払メデイアに変換
		String mediaName = payTypeToMediaLabMap.get(bookItem.PaymentType__c);
		if (CommUtils.isBlank(mediaName)) mediaName = CommConst.MEDIA_TYPE_01;
		// 2016/12/27 見積明細利用日機能対応 BEGIN zyz
    	Date useDate = bookItem.refBooking__r.EntryTime__c.date();
		// 2016/12/27 見積明細利用日機能対応 END zyz
		// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH BEGIN
		// if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI) {
		if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI && !CommConst.BOOKEST_USERDATE_FLG) {
		// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH END
    		useDate = bookItem.refBooking__r.Departure__c.date();
    	}
    	String paymentCd = CommConst.getMediaCodeByMediaName(mediaName);
		Ttend__c newItem = new Ttend__c(
            // *********** 初期値設定 **********
            Field4__c = '1',
            Field5__c = '1',
            POSNo__c = CommUtils.getPosNoByComdefine(),
            // *********** 計算額設定 **********
            // 支払方法
            Field2__c = paymentCd,
            Field3__c = mediaName,
			// 支払商品情報の自動設定
			PayProductRef__c = bookItem.refAccountMaster__c,
			PaymentType__c = bookItem.PaymentType__c,
			PayProductName__c = bookItem.ProductName__c,
			// 2016/12/27 見積明細利用日機能対応 BEGIN zyz
			UseDate__c = (bookItem.UseDate__c == null ? useDate : bookItem.UseDate__c),
			// 2016/12/27 見積明細利用日機能対応 END zyz
            // *********** 合計金額 **********
			// 画面に入力金額は預かり金額に更新
			Field19__c = CommUtils.nullToBlank(bookItem.Total__c),
			// 利用金額
			Field20__c = CommUtils.nullToBlank(bookItem.Total__c),
			// お釣り金額
			Field21__c = CommUtils.nullToBlank(0),
            // メディア毎消費税額設定を行う【あとで計算を行う】
            Field25__c = String.valueOf(0),
            // 2015/01/04 RowNo__cコピー追加
            RowNo__c = bookItem.RowNo__c,
            // *********** 参照関係設定 **********[新規登録する場合、現在の画面の会計に紐付く]
            // 売上情報
            RelAccount__c = acc.frs__c,
            // 会計情報
            Field1__c = acc.Id
            // 2017/12/13 見積明細非表示機能対応 WGCH BEGIN
            ,InvoiceNoShowFlg__c = bookItem.InvoiceNoShowFlg__c
            // 2017/12/13 見積明細非表示機能対応 WGCH END
		);
		// 2015/03/03 BUGFIX 会計商品から「カード種別、金券種別、金券数量、単価」情報を設定する
		if (paymentCd == CommConst.MEDIA_TYPE_CD_02) {
			// カード種別に反映する
			newItem.CardTypeLst__c = newItem.PayProductName__c ;
		} else if ( paymentCd == CommConst.MEDIA_TYPE_CD_11 ||
					paymentCd == CommConst.MEDIA_TYPE_CD_12) {
			// 金券種別
		    newItem.CouponTypeLst__c = newItem.PayProductName__c;
		    // 金券単価と数量
		    newItem.Field16__c = CommUtils.nullToBlank(bookItem.UnitPrice__c);
		    newItem.Field17__c = CommUtils.nullToBlank(bookItem.Amount__c);
		}	
		return newItem;	
	}
	
	// **************************
	// 在庫調整数自動設定機能
	// 予約新規作成の場合「予約部屋タイプにより、在庫調整」
	// 予約変更「部屋タイプ変更」する場合、変更前の部屋タイプの在庫数増える、変更後の在庫数を減らす
	// 予約変更「有効→キャンセル」該当部屋タイプの在庫数を増える
	// 予約変更「キャンセル→有効」該当部屋タイプの在庫数を減らす
	// **************************
	public void stockChangeSyncToDb(Lead__c[] newList, Lead__c[] oldList, CommConst.TriggerMethod action){
		Integer maxLen = newList != null ? newList.size() : oldList.size();
		// 同じ日付、同じ部屋タイプに対して、対応を行う
		//map<String, integer> stockInfoMap = new map<String, integer>();
		List<StockChangeHisotry__c> stockChangeList = new List<StockChangeHisotry__c>();
		// 2018/02/07 故障時刻登録　by zy BEGIN
		Map<id,Set<Date>> stockRoomMap = getCheckBadRoom(newList,oldList,action);
		// 2018/02/07 故障時刻登録　by zy END
		if (action == CommConst.TriggerMethod.isInsert) {
			// 無効な予約　OR　予約の部屋タイプを設定されていない場合、対象外になる
			// 作成元の取得が必要「予約インデックスから」
			for(Integer i = 0; i < maxLen; i++) {
				Lead__c nw = newList[i];
				// 有効な予約情報を新規登録される場合
				if (nw.CancelBool__c != CommConst.LEAD_ST_CANCEL_FLG &&
					nw.refTypeOfRooms__c != null) {
					// 2018/02/07 故障時刻登録　by zy BEGIN
					if (checkBadRoom(stockRoomMap,nw)) continue;
					// 2018/02/07 故障時刻登録　by zy END
					// 在庫減らす
					stockChangeList.add(getNewStockChangeInfo(nw, -1));
				}
			}
		} 
		// 予約情報を変更される場合
		else if (action == CommConst.TriggerMethod.isUpdate) {

			// 変更される場合、
			// 2019/07/30 連泊予約の2泊目以降の予約には宿帳自動作成 BY zyz BEGIN
			Set<Id> LeadIndexRefSet = new Set<Id>();
			Set<Id> LeadIndexSubIdSet = new Set<Id>();
			Set<Decimal> RoomGroupNoSet = new Set<Decimal>();
			// 2019/07/30 連泊予約の2泊目以降の予約には宿帳自動作成 BY zyz END
			for(Integer i = 0; i < maxLen; i++) {
				Lead__c nw = newList[i];
				Lead__c od = oldList[i];
				// 2019/07/30 連泊予約の2泊目以降の予約には宿帳自動作成 BY zyz BEGIN
				if(nw.CancelBool__c != od.CancelBool__c && nw.ReservedStatus__c != od.ReservedStatus__c){
					if(nw.LeadIndexRef__c != null) {
						LeadIndexRefSet.add(nw.LeadIndexRef__c);
						LeadIndexSubIdSet.add(nw.LeadIndexSubId__c);
						RoomGroupNoSet.add(nw.RoomGroupNo__c);
					}
				}
				// 2019/07/30 連泊予約の2泊目以降の予約には宿帳自動作成 BY zyz END
				// 部屋タイプ、予約ステータス、到着日は変更されないと、処理対象外になる
				//if (nw.refTypeOfRooms__c == od.refTypeOfRooms__c &&
				//	nw.CancelBool__c == od.CancelBool__c &&
				//	nw.EntryTime__c.date() == od.EntryTime__c.date()) continue;
				// 2018/02/07 故障時刻登録　by WSQ BEGIN
				//if (!isUpdEventSourceTarget(nw, od)) continue;
				if (!isStockUpdEventSourceTarget(nw, od)) continue;
				// 2018/02/07 故障時刻登録　by WSQ END
				// =======================
				// 在庫数調整情報を設定する
				// =======================
				// 変更前の部屋タイプが存在
				if (od.refTypeOfRooms__c != null) {
					// 元の予約ステータスは有効の場合、
					if (od.CancelBool__c != CommConst.LEAD_ST_CANCEL_FLG) {
						StockChangeHisotry__c stockHistory = getNewStockChangeInfo(od, 1);
						// 新予約の発生源はSFDCの場合、元のデータの変更元もSFDC原因で変更されているの発生源を設定する
						if (nw.EventSource__c == CommConst.BI_PROCESS_TYPE.SFDC.Name()) {
							stockHistory.CreateSource__c = CommConst.BI_PROCESS_TYPE.SFDC.Name();
						}
						// 2020/08/11 予約泊数変更＆到着日変更の場合、在庫変更履歴設定不正の不具合改修 WSQ BEGIN
						// 既存予約キャンセルされる　かつ　キャンセル元とキャンセル先の部屋タイプが一致　かつ　変更元の発生元がSFDC、変更先がSFDC以外の場合、在庫変更履歴が変更先と一致する
						if (nw.CancelBool__c == CommConst.LEAD_ST_CANCEL_FLG &&
							nw.refTypeOfRooms__c == od.refTypeOfRooms__c &&
							(nw.EventSource__c != CommConst.BI_PROCESS_TYPE.SFDC.Name() &&
							 od.EventSource__c == CommConst.BI_PROCESS_TYPE.SFDC.Name())) 
						{
							stockHistory.CreateSource__c = getEventSource(nw.EventSource__c); 	
						}
						// 2020/08/11 予約泊数変更＆到着日変更の場合、在庫変更履歴設定不正の不具合改修 WSQ END
						// 在庫増える
						// 2018/02/07 故障時刻登録　by zy BEGIN
						// stockChangeList.add(stockHistory);
                        // 部屋変更により、変更情報により、在庫調整を行う
                        Boolean stockSyncFlg = false;
						// 故障なしの場合、
						if (!checkBadRoom(stockRoomMap,od)) {
						    // 変更先故障データ存在場合、在校マージするため、変更元の在庫+1になる
                            if (checkBadRoom(stockRoomMap, nw)) {
                                stockHistory.CreateSource__c = CommConst.BI_PROCESS_TYPE.SFDC.Name();
                                stockSyncFlg = true;
                            }
                            // 部屋タイプ変更あり場合
                            else if (isUpdEventSourceTarget(nw,od)) stockSyncFlg = true;
						}
						if (stockSyncFlg) stockChangeList.add(stockHistory);
						// 2018/02/07 故障時刻登録　by zy END
					}
				}	
				// 変更後の部屋タイプが存在する場合
				if (nw.refTypeOfRooms__c != null ) {
					// 新の予約ステータスは有効の場合、
					if (nw.CancelBool__c != CommConst.LEAD_ST_CANCEL_FLG) {
                        // 部屋変更により、変更情報により、在庫調整を行う
                        Boolean stockSyncFlg = false;
                        StockChangeHisotry__c stockHistory = getNewStockChangeInfo(nw, -1);
                        // 部屋：未割り当て済ー＞未割り当ての場合
                        if (od.rRoom__c != null && nw.rRoom__c == null) {
                            // 変更元の該当日付の部屋の故障データ存在する場合、変更先(NEW)の部屋タイプの在庫-1になる（在庫マージ状態から分割になる）
                            if (checkBadRoom(stockRoomMap,od)) {
                                stockHistory.CreateSource__c = CommConst.BI_PROCESS_TYPE.SFDC.Name();
                                stockSyncFlg = true;
                            }
                            // 変更元の故障データがない、部屋タイプ変更あり場合、変更先(NEW)の部屋タイプの在庫-1になる（部屋タイプ変更により、在庫調整を行う）
                            else if (isUpdEventSourceTarget(nw,od)) stockSyncFlg = true;
                        } 
                        //　部屋：未割り当てー＞割り当てへ変更
                        else if (od.rRoom__c == null && nw.rRoom__c != null) {
                            // 変更先の該当日付の部屋の故障データなし、部屋タイプ変更あり場合、変更先(NEW)の部屋タイプの在庫-1になる（部屋タイプ変更により、在庫調整を行う）
                            if (!checkBadRoom(stockRoomMap,nw) && isUpdEventSourceTarget(nw,od)) stockSyncFlg = true;
                        }
                        // 部屋：変更なし場合
                        else if (od.rRoom__c == nw.rRoom__c) {
                            // 変更先の部屋は故障データなし　かつ　部屋タイプ変更あり場合、在庫-1
                            if (!checkBadRoom(stockRoomMap, nw) && isUpdEventSourceTarget(nw,od)) stockSyncFlg = true;
                        }
                        // 部屋：CHANGEの場合
                        else if (od.rRoom__c != nw.rRoom__c) {
                            // 変更先の部屋に対して、故障データ存在しない場合、部屋タイプ変更場合、在庫-1になる
                            if (!checkBadRoom(stockRoomMap,nw)) {
                                // 部屋タイプ変更あり場合
                                if (isUpdEventSourceTarget(nw,od)) stockSyncFlg = true;
                                // 変更元の故障データ存在する場合、在庫分割管理するため、在庫-1する
                                else if(checkBadRoom(stockRoomMap,od)) {
                                    stockHistory.CreateSource__c = CommConst.BI_PROCESS_TYPE.SFDC.Name();
                                    stockSyncFlg = true;
                                }
                            }
                        } 
						// 新部屋の在庫数を減らす
						// 2018/02/07 故障時刻登録　by zy BEGIN
						// stockChangeList.add(getNewStockChangeInfo(nw, -1));
						if (stockSyncFlg) stockChangeList.add(stockHistory);
						// 2018/02/07 故障時刻登録　by zy END
					}
				}
			}
			// 2019/07/30 連泊予約の2泊目以降の予約には宿帳自動作成 BY zyz BEGIN
			list<Lead__c> leadLst = [Select Id,Name,CancelBool__c,Relcontact__c,LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c,
									(Select Id, Name, Field11__c, Field15__c, Field1__c, LeadIndexId__c,Field1__r.LeadIndexRef__c,Field1__r.LeadIndexSubId__c,Field1__r.RoomGroupNo__c,Field1__r.CancelBool__c From Yadouchou8DYp__r)
									From Lead__c
									where LeadIndexRef__c = :LeadIndexRefSet
									And LeadIndexSubId__c = :LeadIndexSubIdSet
									And RoomGroupNo__c = :RoomGroupNoSet
									order by EntryTime__c];
			map<String,Lead__c> leadMap = new map<String,Lead__c>();
			map<String,Yadochou__c> YadoMap = new map<String,Yadochou__c>();
			List<Yadochou__c> initYadoLst = new list<Yadochou__c>();
			for(Lead__c lead : leadLst){
				String mapkeyVal = lead.LeadIndexRef__c + '_' + lead.LeadIndexSubId__c + '_' + lead.RoomGroupNo__c;
				if(lead.CancelBool__c != CommConst.LEAD_ST_CANCEL_FLG){
					if(!leadMap.containsKey(mapkeyVal)) leadMap.put(mapkeyVal,lead);
				}
				for(Yadochou__c yado : lead.Yadouchou8DYp__r){
					YadoMap.put(mapkeyVal,yado);
				}
			}
			for(String keyval : leadMap.keyset()){
				lead__c lead = leadMap.get(keyval);
				if(YadoMap.containsKey(keyval)) {
					Yadochou__c yadochou= YadoMap.get(keyval);
					yadochou.Name = lead.Name;
					yadochou.Field1__c = lead.id;
					initYadoLst.add(yadochou);
				}
			}
			if (!initYadoLst.isEmpty()) update initYadoLst;
			// 2019/07/30 連泊予約の2泊目以降の予約には宿帳自動作成 BY zyz END
		}
		// 2015/12/03 予約情報を物理削除される場合、在庫調整情報を設定する
		else if (action == CommConst.TriggerMethod.isDelete) {
			for(Integer i = 0; i < maxLen; i++) {
				Lead__c od = oldList[i];
				// 有効な予約情報を新規登録される場合
				if (od.CancelBool__c != CommConst.LEAD_ST_CANCEL_FLG &&
					od.refTypeOfRooms__c != null) {
					// 2018/02/07 故障時刻登録　by zy BEGIN
					if (checkBadRoom(stockRoomMap,od)) continue;
					// 2018/02/07 故障時刻登録　by zy END
					// 在庫減らす
					stockChangeList.add(getNewStockChangeInfo(od, 1));
				}
			}
		}
		// 在庫変動が存在する場合、在庫連動情報を作成する
		if (!stockChangeList.isEmpty()) insert stockChangeList;
	}
	/**
	* 予約情報登録の故障部屋有効チェックを行う
	**/
	public void autoCheckHadBadRoom(Lead__c[] newList, Lead__c[] oldList, CommConst.TriggerMethod action){
		
    	// 部屋存在、部屋タイプを未登録される場合：
    	Set<Id> roomIdSet = new Set<Id>();
    	Date todayDt = Date.today();
    	Date startDt = null;
    	Date endDt = todayDt;
    	Date preDate = todayDt.addDays(-1);
    	// 2018/02/07 故障時刻登録　by zy BEGIN
    	//　連泊取得する
    	RoomStatusManager.GroupRoomStatus groupStatus = new RoomStatusManager.GroupRoomStatus();
    	// 2018/02/07 故障時刻登録　by zy END
    	//if (action == CommConst.TriggerMethod.isInsert) {
    	Integer arrLen = newList.size();
    	for (Integer i = 0; i < arrLen; i++) {
    		Lead__c nw = newList[i];
    		Lead__c od = oldList == null ?  null : oldList[i];
    		Date entryDate = nw.EntryTime__c.date();
    		// 今日から未来日の予約情報をチェックする
			if (entryDate < todayDt) continue;
			// 部屋存在 かつ　有効な予約情報の場合
			if (nw.Rroom__c != null && nw.CancelBool__c != CommConst.LEAD_ST_CANCEL_FLG ) {
    	   		// 新規登録　または　部屋設定変更の場合
    	   		//if (od == null || nw.Rroom__c != od.Rroom__c) {
    	   			roomIdSet.add(nw.Rroom__c);
					// 故障部屋情報取得期間の日付の最大と最小日
			        if(startDt == null || startDt > entryDate) startDt = entryDate;
				   	if(endDt < entryDate) endDt = entryDate;
				//}
        		groupStatus.addLeads(nw);
			}
    	}
		// 対象データがないと、処理中止
    	if (roomIdSet.isEmpty()) return;
        // 関連の連泊予約情報を取得する
        groupStatus.queryRelLeads(roomIdSet);
    	// 部屋ステータスを取得する共通クラス
    	RoomStatusManager roomStatusManger = new RoomStatusManager();
    	// 指定期間内の故障部屋リストを取得する
    	List<RoomsStatus__c> roomsStatus = roomStatusManger.queryBadRoomList(startDt,endDt,roomIdSet);
    	// 指定部屋の故障ありの日付情報を格納する
    	Map<id,Set<Date>> badRoomStatusMap = new Map<id,Set<Date>>();
    	Map<Id, String> roomNameMap = new map<Id, String>();
    	// 2018/02/07 故障時刻登録　by zy BEGIN
    	Map<Id,List<RoomsStatus__c>> roomStatusMap = new Map<Id,List<RoomsStatus__c>>();
    	// 2018/02/07 故障時刻登録　by zy END
    	for(RoomsStatus__c roomStatus : roomsStatus){
    		roomNameMap.put(roomStatus.RoomRef__c, roomStatus.RoomRef__r.Name);
            // 2018/02/07 故障時刻登録　by zy BEGIN
            // 時刻項目を設定されている場合、時刻範囲でチェックする
            if (!CommUtils.isBlank(roomStatus.BeginTime__c) || !CommUtils.isBlank(roomStatus.OverTime__c) ) {
                if (!roomStatusMap.containsKey(roomStatus.RoomRef__c)) roomStatusMap.put(roomStatus.RoomRef__c,new List<RoomsStatus__c>());
                roomStatusMap.get(roomStatus.RoomRef__c).add(roomStatus);
            } 
            // 時刻項目を設定されてない場合、日付単位でチェック用情報は変数へ格納する
            else {
            // 2018/02/07 故障時刻登録　by zy END
	    		if(!badRoomStatusMap.containsKey(roomStatus.RoomRef__c)){
	    			badRoomStatusMap.put(roomStatus.RoomRef__c,new Set<Date>());
	    		}
	    		Set<Date> curSet = badRoomStatusMap.get(roomStatus.RoomRef__c);
	    		integer betweenLength = roomStatus.StatusBeginDate__c.daysBetween(roomStatus.StatusEndDate__c);
	    		curSet.addAll(CommUtils.getDaysList(roomStatus.StatusBeginDate__c,betweenLength));
    		// 2018/02/07 故障時刻登録　by zy BEGIN
            }
            // 2018/02/07 故障時刻登録　by zy END
    	}
        // 予約データ再設定を行う
        for (Lead__c nw: newList) {
        	// 今日から未来日の故障部屋のみチエックする
    		Date entryDate = nw.EntryTime__c.date();
    		// 今日から未来日の予約情報をチェックする
			if (entryDate < todayDt) continue;
			// 故障部屋チエックを行う
			// 2018/02/07 故障時刻登録　by WSQ BEGIN
        	//if (nw.Rroom__c != null && badRoomStatusMap.containsKey(nw.Rroom__c)) {
        	if (nw.Rroom__c != null) {
        	    // 時刻範囲の故障状態チェックを行う
        	    if (roomStatusMap.containsKey(nw.Rroom__c)) {
				    String rsMsg = groupStatus.checkRoomStatus(nw,roomStatusMap.get(nw.Rroom__c),roomNameMap.get(nw.Rroom__c)) ;
				    if (!CommUtils.isBlank(rsMsg)) {
				        nw.addError(rsMsg);
				        continue;
				    }
				} else if (badRoomStatusMap.containsKey(nw.Rroom__c)) {
					// 時刻OK、まる１日分の故障データをチェックする
				// 2018/02/07 故障時刻登録　by WSQ END
	           		if(badRoomStatusMap.get(nw.Rroom__c).contains(nw.EntryTime__c.date())){
	           			//日付:
	           			//の部屋
	           			//が故障するため、該当予約に割当てできませんでした。
	           			// 2016/11/25 TIMEZON fix BEGIN by zh
	           			//nw.addError(Label.MSG_002_0376 + nw.EntryTime__c.format('yyyyMMdd') + Label.MSG_002_0377 +'['+roomNameMap.get(nw.Rroom__c)+']'+ Label.MSG_002_0378);
	           			nw.addError(Label.MSG_002_0376 + nw.EntryTime__c.format(CommBaseCtrl.getDateFormat()) + Label.MSG_002_0377 +'['+roomNameMap.get(nw.Rroom__c)+']'+ Label.MSG_002_0378);
	           			// 2016/11/25 TIMEZON fix END by zh
	           		}
				// 2018/02/07 故障時刻登録　by WSQ BEGIN
				}
				// 2018/02/07 故障時刻登録　by WSQ END
            }
        }
	}
	/**
	* 在庫調整するがどうか設定対象チェック
	**/
	private Boolean isUpdEventSourceTarget(Lead__c nw, Lead__c od) {
		if (nw.StockAdjustTargetFlg__c != od.StockAdjustTargetFlg__c) return false;
		if (nw.refTypeOfRooms__c == od.refTypeOfRooms__c &&
					nw.CancelBool__c == od.CancelBool__c &&
					nw.EntryTime__c.date() == od.EntryTime__c.date()) return false;
		return true;
	}
	private String getEventSource(String eventSource) {
		if (CommUtils.isBlank(eventSource)) return CommConst.BI_PROCESS_TYPE.SFDC.Name();
		if (eventSource.startsWith(CommConst.BI_PROCESS_TYPE.TL.Name())) {
			return CommConst.BI_PROCESS_TYPE.TL.Name();
		} else if (eventSource.startsWith(CommConst.BI_PROCESS_TYPE.TA.Name())) {
			return CommConst.BI_PROCESS_TYPE.TA.Name();
		} else if (eventSource.startsWith(CommConst.BI_PROCESS_TYPE.TR.Name())) {
			return CommConst.BI_PROCESS_TYPE.TR.Name();
		} else if (eventSource.startsWith(CommConst.BI_PROCESS_TYPE.JR.Name())) {
			return CommConst.BI_PROCESS_TYPE.JR.Name();
		} else return CommConst.BI_PROCESS_TYPE.SFDC.Name();
	}
	/**
	* 在庫調整情報を作成する
	**/
	private StockChangeHisotry__c getNewStockChangeInfo(Lead__c ld, Integer calNum ) {
		// 予約情報をチェックイン後、予約を変更されると、TLへ連動が必要
		String eventSource = getEventSource(ld.EventSource__c);
		return new StockChangeHisotry__c(
			//StatusLst__c = ''
			StockChangeCnt__c = calNum,
			CreateSource__c = eventSource,
			AgtRef__c = ld.SalesOfficeInfoRef__c,
			StockChangeDate__c = ld.EntryTime__c.date(),	// 到着日ー＞調整日付
			TypeOfRoomRef__c = ld.refTypeOfRooms__c,
			LeadRef__c = ld.Id
		);
	}
	
	// 2017/01/25 店舗ごとの予約権限機能対応 by zh BEGIN
	public void checkShopInfo(Lead__c[] newList, Lead__c[] oldList, CommConst.TriggerMethod action){
		// 新規以外の場合、処理なし
    	if (CommConst.TriggerMethod.IsInsert != action &&
    		CommConst.TriggerMethod.IsUpdate != action ) return;
		// 処理フラグは処理対象外の場合、処理中止
		if (!CommConst.ShopEditAuthCheckFlg) return;
        // 変更される予約情報リストを格納する
		Set<Id> leadIdSet = new Set<Id>();
		//Set<String> leadIdxSubIdSet = new Set<String>();
		Integer maxLen = newList.size();
		for (Integer i = 0; i < maxLen; i++) {
			Lead__c nw = newList[i];
			//String eventSource = getEventSource(nw.EventSource__c);
			// 該当データの作成元はUI以外の場合
			//if (eventSource != CommConst.BI_PROCESS_TYPE.SFDC.Name()) continue;
			// チェック対象外
			if (nw.OtherShopEditCheckFlg__c) continue;
			if (oldList == null) {
				leadIdSet.add(nw.Id);
			} else {
				Lead__c od = oldList[i];
				// 変更前はチェック対象外の場合、この変更もチェック対象外
				if (od.OtherShopEditCheckFlg__c) continue;
				// 該当フラグ
				//if (nw.OtherShopEditCheckFlg__c != od.OtherShopEditCheckFlg__c) continue;
				leadIdSet.add(nw.Id);
			}
		}
		// 対象データがなかったの場合、処理中止
		if (leadIdSet.isEmpty()) return;
		
        // 予約ID,該当部屋・部屋タイプ関連の店舗コード
        map<id, String> leadToShopCdMap = new map<id, String>();
    	for (Lead__c lead : [Select Id,Rroom__r.ShopInfoRef__r.ShopCode__c,RefTypeOfRooms__r.ShopInfoRef__r.ShopCode__c
    						 From Lead__c Where Id = :leadIdSet And (Rroom__r.ShopInfoRef__r.ShopCode__c != '' or RefTypeOfRooms__r.ShopInfoRef__r.ShopCode__c != '') ]) {
    		// 部屋と部屋タイプ関連の店舗コード情報
    		String roomShopCd = CommUtils.nullToBlank(lead.Rroom__r.ShopInfoRef__r.ShopCode__c);
    		String roomTypeShopCd = CommUtils.nullToBlank(lead.RefTypeOfRooms__r.ShopInfoRef__r.ShopCode__c);
    		if (!CommUtils.isBlank(roomShopCd)) leadToShopCdMap.put(lead.id, roomShopCd);
    		else leadToShopCdMap.put(lead.id, roomTypeShopCd);
    	}
    	if (leadToShopCdMap.isEmpty()) return;
    	set<string> canEditShopCdSet = UserUtil.CurrentUserInfo.shopSt;
    	
    	//String defShopCode = UserUtil.CurrentUser.DefaultShopCode__c;
    	// 店舗情報を未設定する場合、全て店舗処理可能で認識する
    	if (canEditShopCdSet.isEmpty()) return;
    	//if(CommUtils.isBlank(defShopCode)) return;
    	// チェックを行う
    	for (Lead__c lead : newList) {
    		if (!leadToShopCdMap.containsKey(lead.Id)) continue;
    		String shopCd = leadToShopCdMap.get(lead.Id);
    		//if (!canEditShopCdMap.containsKey(shopCd)) {
    		if (!canEditShopCdSet.contains(shopCd)) {
				lead.addError('別の店舗の予約情報を更新できません');	
				return;
    		} else if (CommConst.TriggerMethod.IsUpdate == action) {
    			lead.OtherShopEditCheckFlg__c = false;
    		}
    	}
    }
    // 2017/01/25 店舗ごとの予約権限機能対応 by zh END
    // 2018/02/07 故障時刻登録　by zy BEGIN
    // 対象予約リストに関しての故障データリスト情報を取得する
	private Map<id,Set<Date>> getCheckBadRoom(Lead__c[] newList, Lead__c[] oldList,CommConst.TriggerMethod action) {
		// 指定部屋の故障ありの日付情報を格納する
		// map<部屋ID,SET<故障情報あり日付>
    	Map<id,Set<Date>> badRoomStatusMap = new Map<id,Set<Date>>();
		// 故障データ取得範囲期間
    	Date todayDt = Date.today();
    	Date startDt = todayDt;
    	Date endDt = todayDt;
    	// 故障部屋ID配列
    	Set<Id> badRoomIdSet = new Set<Id>();
        // 対応データの配列数
        Integer maxLen = newList != null ? newList.size() : oldList.size();
        // 2018/02/07 故障時刻登録　by zy END
        if (action == CommConst.TriggerMethod.isInsert) {
            // 無効な予約　OR　予約の部屋タイプを設定されていない場合、対象外になる
            // 作成元の取得が必要「予約インデックスから」
            for(Integer i = 0; i < maxLen; i++) {
                Lead__c nw = newList[i];
                // 有効な予約情報を新規登録される場合[部屋割り当てされる場合]
                if (nw.CancelBool__c != CommConst.LEAD_ST_CANCEL_FLG &&
                    nw.rRoom__c != null) {
                    // 該当日付の予約に対して、故障チェック対象になる
                    Date tDt = nw.EntryTime__c.date();
                    if (startDt > tDt) startDt = tDt;
                    if (endDt < tDt) endDt = tDt;
                    // 故障部屋IDは配列に格納する
                    badRoomIdSet.add(nw.rRoom__c);
                }
            }
        } 
        // 予約情報を変更される場合
        else if (action == CommConst.TriggerMethod.isUpdate) {
            // 変更される場合、
            for(Integer i = 0; i < maxLen; i++) {
                Lead__c nw = newList[i];
                Lead__c od = oldList[i];
                // 部屋、予約ステータス、到着日は変更されないと、処理対象外になる
                //if (!isBadRoomCheckTarget(nw, od)) continue;
                // 変更前の部屋タイプが存在
                if (od.rRoom__c != null) {
                    // 元の予約ステータスは有効の場合、
                    if (od.CancelBool__c != CommConst.LEAD_ST_CANCEL_FLG) {
	                    // 該当日付の故障データチェックが必要
	                    Date tDt = od.EntryTime__c.date();
	                    if (startDt > tDt) startDt = tDt;
	                    if (endDt < tDt) endDt = tDt;
	                    // 故障部屋IDは配列に格納する
	                    badRoomIdSet.add(od.rRoom__c);
                    }
                }   
                // 変更後の部屋タイプが存在する場合
                if (nw.rRoom__c != null ) {
                    // 新の予約ステータスは有効の場合、
                    if (nw.CancelBool__c != CommConst.LEAD_ST_CANCEL_FLG) {
	                    // 該当日付の故障データチェックが必要
	                    Date tDt = nw.EntryTime__c.date();
	                    if (startDt > tDt) startDt = tDt;
	                    if (endDt < tDt) endDt = tDt;
	                    // 故障部屋IDは配列に格納する
	                    badRoomIdSet.add(nw.rRoom__c);
                    }
                }
            }
        }
        // 2015/12/03 予約情報を物理削除される場合、在庫調整情報を設定する
        else if (action == CommConst.TriggerMethod.isDelete) {
            for(Integer i = 0; i < maxLen; i++) {
                Lead__c od = oldList[i];
                // 有効な予約情報を新規登録される場合
                if (od.CancelBool__c != CommConst.LEAD_ST_CANCEL_FLG &&
                    od.rRoom__c != null) {
                    // 該当日付の故障データチェックが必要
                    Date tDt = od.EntryTime__c.date();
                    if (startDt > tDt) startDt = tDt;
                    if (endDt < tDt) endDt = tDt;
                    // 故障部屋IDは配列に格納する
                    badRoomIdSet.add(od.rRoom__c);
                }
            }
        }
		// 対象データがないと、処理中止
    	if (badRoomIdSet.isEmpty()) return badRoomStatusMap;
    	// 部屋ステータスを取得する共通クラス
    	RoomStatusManager roomStatusManger = new RoomStatusManager();
    	// 指定期間ないの故障部屋リストを取得する
    	List<RoomsStatus__c> roomsStatus = roomStatusManger.queryBadRoomList(startDt,endDt,badRoomIdSet);
    	for(RoomsStatus__c roomStatus : roomsStatus){
    		if(!badRoomStatusMap.containsKey(roomStatus.RoomRef__c)){
    			badRoomStatusMap.put(roomStatus.RoomRef__c,new Set<Date>());
    		}
    		Set<Date> curSet = badRoomStatusMap.get(roomStatus.RoomRef__c);
    		integer betweenLength = roomStatus.StatusBeginDate__c.daysBetween(roomStatus.StatusEndDate__c);
    		curSet.addAll(CommUtils.getDaysList(roomStatus.StatusBeginDate__c,betweenLength));
    	}
        return badRoomStatusMap;
	}
	// 該当予約に対して、故障データ存在チェックを行う
	// TRUE:該当日付の予約に対して、故障データが存在する
	// FALSE:故障データが存在しない
	private boolean checkBadRoom(Map<id,Set<Date>> badRoomStatusMap, Lead__c nw){
    	// 今日から未来日の故障部屋のみチエックする
		Date entryDate = nw.EntryTime__c.date();
		// 今日から未来日の予約情報をチェックする
		if (entryDate < Date.today()) return true;
		// 故障部屋チエックを行う
    	if (nw.Rroom__c != null && badRoomStatusMap.containsKey(nw.Rroom__c)) {
       		if(badRoomStatusMap.get(nw.Rroom__c).contains(entryDate)) return true;
       	}
        return false;
    }
    // 対象項目チェック
    private Boolean isStockUpdEventSourceTarget(Lead__c nw, Lead__c od) {
        if (nw.StockAdjustTargetFlg__c != od.StockAdjustTargetFlg__c) return false;
        if (nw.refTypeOfRooms__c == od.refTypeOfRooms__c &&
                  nw.CancelBool__c == od.CancelBool__c &&
                  nw.rRoom__c == od.rRoom__c &&
                  nw.EntryTime__c.date() == od.EntryTime__c.date()) return false;
        return true;
    }
    // 2018/02/07 故障時刻登録　by zy END
    // 2019/04/15 改善要望：予約から活動の作成 by zy BEGIN
    public void createEventInfo(Lead__c[] newList, Lead__c[] oldList,CommConst.TriggerMethod action){
    	// 作成活動
    	List<Event> events = new List<Event>();
        // 作成活動
        List<Event> updEvents = new List<Event>();
        Set<String> eventIdset = new Set<String>();
        // 行動関連処理
        for (integer i = 0 ; i < newList.size() ; i++) {
            Lead__c newLead = newList[i];
            // 関連変更
            if ( newLead.EventFlg__c != null && newLead.EventFlg__c) {
                if (!Commutils.isBlank(newLead.EventId__c))eventIdset.add(newLead.EventId__c);
            }
        }
        // 既存行動チェック
        Map<String,Event> exitEvent = new Map<String,Event>();
        if (!eventIdset.isEmpty()) {
            // 2019/05/31 008.行動からご予約の自動生成機能で、ご予約生成後に行動を変更（日時など）を変えた時にご予約は変更されないようです。by zy BEGIN
            for (Event evt : [select id,subject,StartDatetime,EndDatetime,LeadRef__c,RoomRef__c,WhoId from event where id = :eventIdset]){
            // 2019/05/31 008.行動からご予約の自動生成機能で、ご予約生成後に行動を変更（日時など）を変えた時にご予約は変更されないようです。by zy END
                exitEvent.put(evt.id,evt);
            }
        }
        // 2019/05/31 008.行動からご予約の自動生成機能で、ご予約生成後に行動を変更（日時など）を変えた時にご予約は変更されないようです。by zy BEGIN
        Set<String> exitEventSet = new Set<String>();
        // 2019/05/31 008.行動からご予約の自動生成機能で、ご予約生成後に行動を変更（日時など）を変えた時にご予約は変更されないようです。by zy END
		// 行動関連処理
    	for (integer i = 0 ; i < newList.size() ; i++) {
    		Lead__c newLead = newList[i];
			// 関連変更
			if ( newLead.EventFlg__c != null && newLead.EventFlg__c) {
                if (CommUtils.isBlank(newLead.EventId__c)) {
                    Event newEvent = new Event();
                    // 任命先 
                    newEvent.OwnerId = newLead.OwnerId;
                    // 件名 
                    newEvent.Subject = newLead.name;
                    // 開始  
                    newEvent.StartDateTime = CommUtils.convertDatetime(newLead.entryTime__c.date(), newLead.field4__c);
                    // 終了
                    newEvent.EndDateTime =  CommUtils.convertDatetime(newLead.Departure__c.date(), newLead.field3__c);
                    // グループコード設定 
                    newEvent.leadRef__c = newLead.id;
                    newEvent.RoomRef__c = newLead.Rroom__c;
                    // ロック
                    newEvent.LockFlag__c = true;
                    newEvent.WhoId = newLead.relcontact__c;
                    // 説明
                    newEvent.Description = newLead.Comment3__c;
                    events.add(newEvent);
                } else if (exitEvent.containskey(newLead.EventId__c)) {
                    Event evt = exitEvent.get(newLead.EventId__c);
                    // 2019/05/31 008.行動からご予約の自動生成機能で、ご予約生成後に行動を変更（日時など）を変えた時にご予約は変更されないようです。by zy BEGIN
                    /*
                    if (evt.RoomRef__c != newLead.Rroom__c || evt.LeadRef__c == null) {
                        evt.RoomRef__c = newLead.Rroom__c;
                        if(evt.LeadRef__c == null) evt.LeadRef__c = newLead.id;
                        updEvents.add(evt);
                    }
                    */
                    // チェック行動対応予約字段一致
                    if (!exitEventSet.contains(evt.id) && checkUpdEvent(evt,newLead)) updEvents.add(evt);
                    exitEventSet.add(evt.id);
                    // 2019/05/31 008.行動からご予約の自動生成機能で、ご予約生成後に行動を変更（日時など）を変えた時にご予約は変更されないようです。by zy END
                }
            }
    	}
        // 行動作成
		if (!events.isEmpty()) insert events;
        // 行動更新
        if (!updEvents.isEmpty()) update updEvents;
    }
    // 2019/04/15 改善要望：予約から活動の作成 by zy END
    // 2019/05/31 008.行動からご予約の自動生成機能で、ご予約生成後に行動を変更（日時など）を変えた時にご予約は変更されないようです。by zy BEGIN
    // チェック行動対応予約字段一致
    private boolean checkUpdEvent(Event evt,Lead__c newLead){
        // 結果予約
        boolean chkFlag = false;
        // 部屋チェック
        if (evt.RoomRef__c != newLead.Rroom__c) {
            // 部屋設定
            evt.RoomRef__c = newLead.Rroom__c;
            chkFlag = true;
        }
        if (evt.LeadRef__c == null) {
            evt.LeadRef__c = newLead.id;
            chkFlag = true;
        }
        // 開始 
        Datetime startDt = CommUtils.convertDatetime(newLead.entryTime__c.date(), newLead.field4__c);
        // 終了
        Datetime endDt = CommUtils.convertDatetime(newLead.Departure__c.date(), newLead.field3__c);
        // 開始時間と到着日チェック
        if (evt.StartDateTime != startDt) {
            evt.StartDateTime = startDt;
            chkFlag = true;
        }
        // 終了時間と出発日チェック
        if (evt.EndDateTime != endDt) {
            evt.EndDateTime = endDt;
            chkFlag = true;
        }
        // 件名と予約名チェック
        if (evt.Subject != newLead.name) {
            evt.Subject = newLead.name;
            chkFlag = true;
        }
        // 任命先チェック
        if (evt.WhoId != newLead.Relcontact__c && newLead.Relcontact__c != null) {
            evt.WhoId = newLead.Relcontact__c;
            chkFlag = true;
        }
        return chkFlag;
    }
    // 行動自動作成の情報チェック
    public void checkEventInfo(Lead__c[] newList, Lead__c[] oldList, CommConst.TriggerMethod action){
        set<String> eventIdSet = new set<String>();
        // 新規予約の場合、既存行動Id対応関係チェック
        for (integer i = 0 ; i < newList.size(); i++) {
            Lead__c newLead = newList[i];
            // 該当新規予約の行動指定の場合
            if (!CommUtils.isBlank(newLead.EventId__c)) eventIdSet.add(newLead.EventId__c);
        }
        // 関連行動データあり
        if (!eventIdSet.isEmpty()) {
            // 指定行動と予約関連集合
            Map<String,String> evetMap = new Map<String,String>();
            // 新規の場合、行動の自動作成予約Id、行動の「予約Id」字段「空」必須！！！
            // 取得行動の予約Id指定、関連不正のデータ取得
            for (Event evt : [select id,leadRef__c from Event where id = :eventIdSet and leadRef__c != null]){
                // データ追加
                evetMap.put(evt.id,evt.leadRef__c);
            }
            // 新規予約リストのコピーのデータチェック
            for (integer i = 0 ; i < newList.size(); i++) {
                Lead__c newLead = newList[i];
                // 予約行動設定の場合
                if (!CommUtils.isBlank(newLead.EventId__c)) {
                    // 予約行動不正
                    if (evetMap.containsKey(newLead.EventId__c)){
                        // 指定関連解除
                        newLead.EventId__c = null;
                    }
                }
            }
        }
    }
    // 2019/05/31 008.行動からご予約の自動生成機能で、ご予約生成後に行動を変更（日時など）を変えた時にご予約は変更されないようです。by zy END
    // 2019/07/15 多泊の場合、外出の場合、多泊の予約に同じ状態を更新する BY zyz BEGIN
	private void syncInfoToRelLeadsGoingout(List<Lead__c> goingOutLeads,boolean isChkInFlg) {
		// 変更される予約情報リストを格納する
		Set<Id> leadIdxIds = new Set<Id>();
		Set<Id> leadSubIdxIds = new Set<Id>();
        Set<Id> exitLeadIdSet = new Set<Id>();
		Set<Decimal> groupNos = new Set<Decimal>();
        // 更新リスト
        List<Lead__c> updLeads = new List<Lead__c>();
        // 画面からお客様ステータス変更の予約情報を格納
        Map<String, Lead__c> uiChangeGuestStatusMap = new Map<String, Lead__c>();   
        // 同じ予約作成
		for (Lead__c lead : goingOutLeads) {
            // 既存予約
            exitLeadIdSet.add(lead.Id);
            // 連泊予約鍵
            leadIdxIds.add(lead.LeadIndexRef__c);
            leadSubIdxIds.add(lead.LeadIndexSubId__c);
            groupNos.add(lead.RoomGroupNo__c);
            uiChangeGuestStatusMap.put(getKeyOfSameGroupLead(lead.LeadIndexRef__c,lead.LeadIndexSubId__c,lead.RoomGroupNo__c), lead);
        }
        String querySQL = 'select id, LeadIndexRef__c, LeadIndexSubId__c,RoomGroupNo__c,StayPersons__c,Mans__c,Femails__c,ChildFA__c,Childs__c,EntryTime__c'
                            // お客様ステータス
                            + ',Field298__c'
                            // 予約ステータス
                            + ' ,ReservedStatus__c'
                            + ' from lead__c ';
        String queryWhere = ' where LeadIndexRef__c in :leadIdxIds And LeadIndexSubId__c in :leadSubIdxIds And RoomGroupNo__c in :groupNos'                       
                            // 有効な予約のみ関連更新を行う
                            + ' And CancelBool__c != ' + CommConst.LEAD_ST_CANCEL_FLG
                            + ' and id != :exitLeadIdSet';
        // 2019/07/15 JINYABUG-1950 bug fix by zy BEGIN
        if (isChkInFlg) queryWhere += ' and Field298__c = \'' + CommConst.LEAD_GUEST_ST_OUT + '\'';
        else queryWhere += ' and Field298__c = \'' + CommConst.LEAD_GUEST_ST_CI + '\'';
        // 2019/07/15 JINYABUG-1950 bug fix by zy END';
		// 処理対象の予約の関連予約情報（同じグループ）の予約
		for (Lead__c lead : Database.query(querySQL + queryWhere)) {
			// 指定の予約情報により、以後の関聯予約情報を更新する
			String key = getKeyOfSameGroupLead(lead.LeadIndexRef__c,lead.LeadIndexSubId__c,lead.RoomGroupNo__c);			
			// お客様ステータス連動
			if (uiChangeGuestStatusMap.containsKey(key)) {
				Lead__c orgLead = uiChangeGuestStatusMap.get(key);
				// 未来日の予約情報処理を行う
				if (lead.EntryTime__c > orgLead.EntryTime__c) {
                    if (isChkInFlg) 
                        lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
		            // お客様のステータスを変更される場合
                    else
                        lead.Field298__c = CommConst.LEAD_GUEST_ST_OUT;
                    // 変更される予約を格納する
                    updLeads.add(lead);
				}
			}
		} 
		if (!updLeads.isEmpty()) update updLeads;
	}
    // 2019/07/15 多泊の場合、外出の場合、多泊の予約に同じ状態を更新する BY zyz END
    // 2020/05/15 到着日を変更した際に紐づいている予約見積明細の利用日も自動変更する機能対応 WSQ BEGIN
    // 予約情報変更に従って、見積明細へ連動対応
    public void leadInfoSyncEstItems(Lead__c[] newList, Lead__c[] oldList, CommConst.TriggerMethod action){
    	// 更新以外場合、処理中止
    	if (action != CommConst.TriggerMethod.IsUpdate) return;
    	// 到着日は売上計上日で設定場合
    	boolean isEntryDtAsSdFlg = (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE == CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI);
    	// 到着日　OR　出発日を変更される場合
    	// map<予約ID、変更差異日数>
    	map<id,integer> diffDaysMap = new map<id, integer>();
		// 更新場合
		Integer len = newList.size();
        for (Integer i = 0; i < len; i++) {
        	Lead__c nw = newList[i];
        	Lead__c od = oldList[i];
			// 到着日と出発日は売上日計上設定により、変更チェック日付を設定する
    		Date nwCalDate = isEntryDtAsSdFlg ? nw.EntryTime__c.date() : nw.Departure__c.date();
    		Date odCalDate = isEntryDtAsSdFlg ? od.EntryTime__c.date() : od.Departure__c.date();
        	// 日付を変更される場合
	        if (nwCalDate != odCalDate) {
	        	diffDaysMap.put(nw.id, (odCalDate.daysBetween(nwCalDate)));
	        }
        }
        // 処理対象データが存在場合
        if (!diffDaysMap.isEmpty()) {
        	list<BookingEstimateItem__c> estUpdLst = new list<BookingEstimateItem__c>();
        	// 見積明細連動更新を行う
        	for (BookingEstimateItem__c est : [select id, UseDate__c,refBooking__c from BookingEstimateItem__c where refBooking__c in :diffDaysMap.keyset() and UseDate__c != null]) {
        		Integer diffDasy = diffDaysMap.get(est.refBooking__c);
        		est.UseDate__c = est.UseDate__c.addDays(diffDasy);
        		estUpdLst.add(est);
        	}
        	if (!estUpdLst.isEmpty()) {
        		// 連携トリガー更新ストップ
        		DataFixManagerUtils.stopTranTriggger();
        		update estUpdLst;
        		// 連携トリガー更新再開
        		DataFixManagerUtils.begTranTriggger();
        	}
        }
    }
    // 2020/05/15 到着日を変更した際に紐づいている予約見積明細の利用日も自動変更する機能対応 WSQ END
}