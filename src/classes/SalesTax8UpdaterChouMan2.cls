/**
* 2019/09/05 見積明細の合計金額を変更せず、単価自動調整を対応する
*	1.普通の商品の場合、合計金額により、10%の税率により、単価を再度計算を行う
*	2.プランの場合、プランのHeaderの金額により、プラン明細の単価を再設定を行う
*	  プランのHeaderの単価金額も再度計算を行う
**/
global class SalesTax8UpdaterChouMan2 implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    public final String Query;					// 検索SOQL
	
	// 増税開始の日付を定義する
	// 2019/08/12消費税は8%から10%に変更対応 WSQ BEGIN
	private static final Date CONST_TAXRATE_RECDATE = Date.newInstance(2019,3,31);
	private static final Date CONST_TAXRATE_CHGDATE = Date.newInstance(2019,10,1);
	private static final String CONST_BATCH_STATUS = '2';	// 2014/04/01 ５％ー＞８％へ増税処理済みフラグ
	private static final Decimal CONST_OLD_TAXRATE = 8;
	private static final Decimal CONST_NEW_TAXRATE = 10;
	// 2019/08/12消費税は8%から10%に変更対応 WSQ END
	private static final String CONST_SF_BASEURL = 'https://login.salesforce.com';
	// 処理成功件数と失敗件数統計する
	//private Integer IsOKCounts;
	//private Integer IsNgCounts;
	private String errorMessage;
	// スケジュール定義者
	private Id scheduleCreatedById;
	// 未処理結果対象リスト情報を格納する
	private list<ERRINFO> errmsgLst = null;
	private list<ERRINFO> errmsgLst2 = null;
	// 2019/10/05 見積もり明細の金額変更ロジック by zy BEGIN
	public String currentStatus;
	// 2019/10/05 見積もり明細の金額変更ロジック by zy END
	// スケジュールインスタンス関数
	global SalesTax8UpdaterChouMan2 () {}
	// バッチ起動インスタンス関数
	global SalesTax8UpdaterChouMan2 (Id userId) {
		// 予約受付日は2019/04/01以後　かつ　到着日は2019/10/10以後の予約データを取得する
		Query = ' select id from lead__c where DAY_ONLY(convertTimezone(EntryTime__c)) >= :CONST_TAXRATE_CHGDATE And DAY_ONLY(ReservedDate__c) >: CONST_TAXRATE_RECDATE and CancelBool__c != 1 ';
		// 集計変数
		//IsOKCounts = 0;
		//IsNgCounts = 0;
		errorMessage = '';
		scheduleCreatedById = userId;
		// メッセージ情報を格納する
		errmsgLst = new list<ERRINFO>();
		errmsgLst2= new list<ERRINFO>();
		// 2019/09/30 会计明细消费税变更对应 WGCH BEGIN
		accErrmsgLst = new list<ACCERRINFO>();
		accErrmsgLst2= new list<ACCERRINFO>();
		// 2019/09/30 会计明细消费税变更对应 WGCH END
		// 8% -> 10%処理を行う
		updateTaxRateMst();
	}
	// ***********************************
	// 消費税8％ー＞10％変更ロジック対応する　
	// ***********************************	
	private void updateTaxRateMst () {
		// 2018/03/07 Security Check BEGIN
		List<String> chkFields = new List<String>{'TaxRate__c'};
		Map<String,Schema.SObjectField> m = Schema.SObjectType.JMST__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(chkFields, m)) {
			return;
		}
		// 2018/03/07 Security Check END
		// 商品税8％のデータを探す、存在すると、更新を行う
		List<JMST__c> taxRates = [Select Id, TaxRate__c From JMST__c where TaxRate__c > 0 Order By CreatedDate asc limit 1];
		if (!taxRates.isEmpty()) {
			// 消費税設定率は8の場合、10％へ更新を行う
			if (taxRates[0].TaxRate__c == CONST_OLD_TAXRATE) {
				// 消費税
				taxRates[0].TaxRate__c = CONST_NEW_TAXRATE;
				update taxRates;
			}
		}
	}
	// ***********************************
	// スケジュール処理開始
	// ***********************************
   public void execute(SchedulableContext SC) {
   	  // スケジュール定義情報を取得して、スケジュール定義者へバッチ処理結果を送信する
   	  CronTrigger cron = [Select CreatedById From CronTrigger Where Id = :SC.getTriggerId() ];
      SalesTax8UpdaterChouMan2 batch = new SalesTax8UpdaterChouMan2(cron.CreatedById);
	  // 2019/10/05 見積もり明細の金額変更ロジック by zy BEGIN
	  if (!CommUtils.isBlank(currentStatus)) batch.currentStatus = currentStatus;
	  // 2019/10/05 見積もり明細の金額変更ロジック by zy END
      DataBase.executeBatch(batch,5);
   }
	// ***********************************
	// バッチ処理開始
	// ***********************************
	public Database.QueryLocator start(Database.BatchableContext BC){
		// DEBUG
		//String locQuery = Query + ' and id in (\'a0o5D000000iVoR\',\'a0o5D000000iVoS\')';
		//return Database.getQueryLocator(locQuery);
    	return Database.getQueryLocator(Query);
	}

	/**
	* 情報集計
	**/
	public void execute(Database.BatchableContext BC, List<Lead__c> leads){
		// 2018/03/07 Security Check BEGIN
		List<String> chkFields = new List<String>{'TaxRate__c','SpTotal__c','BatchProcessStatusDiv__c'};
		Map<String,Schema.SObjectField> m = Schema.SObjectType.BookingEstimateItem__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(chkFields, m)) {
			return;
		}
		// 2018/03/07 Security Check END	
		// 2019/08/12 消費税は8%から10%に変更対応 WGCH BEGIN
		// #合計金額　＝　単価（税込）　＊　数量　＋　(単価（税込）　＊　数量) * サビース料金(%)　＋ 特別税　
    	// CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo();
    	set<id> leadIds = new set<id>();
    	for(Lead__c item : leads)  leadIds.add(item.Id);
		// 2019/10/05 見積もり明細の金額変更ロジック by zy BEGIN
    	String estQuery = ' Select Id, Name, TaxRate__c, UnitPrice__c, SpTotal__c, SpecialTax__c, ServiceRate__c, Amount__c, ParentBookingItemRef__c, BatchProcessStatusDiv__c, refAccountMaster__c, refBooking__c,refBooking__r.Name,refBooking__r.Id, UnitPriceDefKbCal__c, ActionType__c,PlanDetailSyncInfo__c from BookingEstimateItem__c where BatchProcessStatusDiv__c != :CONST_BATCH_STATUS And TaxRate__c > 0 and refBooking__c in :leadIds ';
		// 2019/10/05 見積もり明細の金額変更ロジック by zy END
		// 2019/08/12 消費税は8%から10%に変更対応 WGCH BEGIN
		CommLogicProcess.TaxIncMstInfo taxIncMstItem = CommLogicProcess.getTaxIncMstInfo();
		// 自動増税商品が存在場合、該当商品が存在の明細を更新対象外
		Set<Id> noTargetLeadIdSet = new Set<Id>();
		if(!CommUtils.isBlank(taxIncMstItem.taxIncMstId)) {
			Id upd2rateId = taxIncMstItem.taxIncMstId;
			List<BookingEstimateItem__c> ests = [Select refBooking__c from BookingEstimateItem__c where  refAccountMaster__c = :upd2rateId];
			for (BookingEstimateItem__c est : ests) noTargetLeadIdSet.add(est.refBooking__c);
		}
		if (!noTargetLeadIdSet.isEmpty()) {
			estQuery += ' And refBooking__c not in :noTargetLeadIdSet ';
		}
		// 2019/10/05 見積もり明細の金額変更ロジック by zy BEGIN
		if (!CommUtils.isBlank(currentStatus)) {
			estQuery += ' And BatchProcessStatusDiv__c = :currentStatus ';
		}
		// 2019/10/05 見積もり明細の金額変更ロジック by zy END
		estQuery += ' Order By ParentBookingItemRef__c,Name ';
    	List<BookingEstimateItem__c> scope = Database.query(estQuery);
//System.debug(Logginglevel.info,'scope='+scope);
//System.debug(Logginglevel.info,'leadIds='+leadIds);
//System.debug(Logginglevel.info,'leadIds[R1]='+[select id from BookingEstimateItem__c where refBooking__c in :leadIds]);
//System.debug(Logginglevel.info,'leadIds[R2]='+[select id from BookingEstimateItem__c where BatchProcessStatusDiv__c != :CONST_BATCH_STATUS ]);
//System.debug(Logginglevel.info,'leadIds[R3]='+[select id from BookingEstimateItem__c where TaxRate__c > 0]);
    	// 2019/08/12 消費税は8%から10%に変更対応 WGCH END
		// 预约对应的見積明細情報Map
		Map<String, List<BookingEstimateItem__c>> ldToBookEstMap = new Map<String, List<BookingEstimateItem__c>>();
		for (BookingEstimateItem__c subItem : scope) {
			// 预约Id
			String leadId = CommUtils.nullToBlank(subItem.refBooking__c);
			// 根据预约Id集计
			if(!ldToBookEstMap.containsKey(leadId)) ldToBookEstMap.put(leadId, new List<BookingEstimateItem__c>());
			ldToBookEstMap.get(leadId).add(subItem);
		}
		// 更新対象見積明細情報を格納する
		List<BookingEstimateItem__c> nwUpdLst = new List<BookingEstimateItem__c>();
		// 予約別見積明細を再計算する
		for(List<BookingEstimateItem__c> bookEstLst : ldToBookEstMap.values()){
			// プランのBREAK明細情報を格納する
			map<Id, List<BookingEstimateItem__c>> planSubMap = new map<Id, List<BookingEstimateItem__c>>();
			// 該当予約の親見積明細リストを格納する
			list<BookingEstimateItem__c> headeritems = new List<BookingEstimateItem__c>();
			// 該当予約に紐付く見積明細を取得する
			ERRINFO einfo = null;
			for (BookingEstimateItem__c est : bookEstLst) {
				// 親見積明細のIDを取得取得
				Id parentId = est.ParentBookingItemRef__c;
				// 親見積明細が存在場合、該当プランの明細をリストに格納する
				if (parentId != null) {
					if (!planSubMap.containsKey(parentId)) planSubMap.put(parentId, new list<BookingEstimateItem__c>());
					planSubMap.get(parentId).add(est);
				} else {
					// 特別税存在場合、処理対象外、MESSAGEに格納する
					// 該当明細の特別税が存在場合、処理対象外（手動で再設定が必要）
					if (CommUtils.nullToZero(est.SpecialTax__c) > 0) {
						if (einfo == null) einfo = new ERRINFO(est.refBooking__r);
						einfo.addItem(est);
						continue;
					}
					headeritems.add(est);
				}
			}
			if (einfo != null) errmsgLst.add(einfo);

//if (einfo != null) system.debug(loggingLevel.info, 'einfo='+einfo.tomessage());
			// 税込み更新リストを格納する
			List<BookingEstimateItem__c> incTaxEsts = new list<BookingEstimateItem__c>();
			// 指定区分でサ込、税込金額を取得する
			// Headerの明細金額を自動計算する（商品種別は支払の場合、対象外）
			for (BookingEstimateItem__c hditem : headeritems) {
				// 商品明細の単価定義区分は３と４の場合、再計算が必要、１と２の場合、再計算が不要です
				Integer kbn = CommUtils.nullToIntZero(hditem.UnitPriceDefKbCal__c);
//system.debug(loggingLevel.info, 'kbn='+kbn);
				if (kbn == CommConst.APPOPTION_UTP_DEF_KB_OP1 || kbn == CommConst.APPOPTION_UTP_DEF_KB_OP2) {
				} else {
					// 単価定義区分３と４（単価に税抜）
					decimal qty = CommUtils.nullTozero(hditem.Amount__c);
					decimal serviceRate = CommUtils.nullToZero(hditem.ServiceRate__c);
					if (qty == 0) continue;
					// 子明細データが非存在場合、合計金額により、単価金額を再計算を行う
					// 現在の単価により、既存の単価再計算を行う
					Decimal total = (CommUtils.nullToZero(hditem.SpTotal__c) - CommUtils.nullToZero(hditem.SpecialTax__c)) / qty;
	                hditem.UnitPrice__c = CommUtils.convertPriceByTaxKbn(total, CONST_NEW_TAXRATE,serviceRate, 
	                                                                        CommConst.APPOPTION_UTP_DEF_KB_OP2, 
	                                                                        CommConst.APPOPTION_UTP_DEF_KB);
	                hditem.UnitPrice__c = checkIfHadScale(hditem.UnitPrice__c, CONST_NEW_TAXRATE, serviceRate, CommConst.APPOPTION_UTP_DEF_KB);
//System.debug(Logginglevel.info,'total='+total);
				}


				// 該当親の子明細に室料が非存在場合、情報格納する     
				ERRINFO einfo2 = null;                                  	
				// 子明細データが存在場合、子明細情報を再計算する
				if (planSubMap.containsKey(hditem.id)) {
					// 明細単位の金額を自動計算を行う「室料ある場合、差分値が室料で調整を行う、室料がない場合、該当明細が１行目のみ存在場合、該当明細に単価調整を行う(子供プラン対応想定)
					list<BookingEstimateItem__c> subitems = planSubMap.get(hditem.id);
					if (subitems.size() == 1) {
						subitems[0].UnitPrice__c = hditem.UnitPrice__c;
						subitems[0].TaxRate__c = CONST_NEW_TAXRATE;
						subitems[0].BatchProcessStatusDiv__c = CONST_BATCH_STATUS;
						// 2019/10/05 見積もり明細の金額変更ロジック by zy BEGIN
						hditem = changeSyncInfo(hditem,subitems[0]);						
						// 2019/10/05 見積もり明細の金額変更ロジック by zy END
						nwUpdLst.add(subitems[0]);
//----------------------------------------------   
//System.debug(Logginglevel.info,'======[STEP2]======');  
//System.debug(Logginglevel.info,'subitems[0]='+subitems[0]);
//----------------------------------------------   
					} else {
						// 税込の場合
						if (kbn == CommConst.APPOPTION_UTP_DEF_KB_OP1 || kbn == CommConst.APPOPTION_UTP_DEF_KB_OP2) {
							// Header関連の明細の消費税を設定する
							for (BookingEstimateItem__c est : subitems) {
								est.TaxRate__c = CONST_NEW_TAXRATE;
								est.BatchProcessStatusDiv__c = CONST_BATCH_STATUS;
							}
							nwUpdLst.addAll(subitems);
							
							// Headerの消費税と処理区分を設定する
							hditem.TaxRate__c = CONST_NEW_TAXRATE;
							hditem.BatchProcessStatusDiv__c = CONST_BATCH_STATUS;
			                nwUpdLst.add(hditem);  
							continue;
						}
						// ============= 税抜の場合 [BEG]==============
						// 室料明細に格納する
						BookingEstimateItem__c roomEst = null;
						Decimal othSumPrice = 0;
						// 室料以外の明細を格納する
						list<BookingEstimateItem__c> otherEsts = new list<BookingEstimateItem__c>();
						for (BookingEstimateItem__c est : subitems) {
							// 室料情報が存在場合、該当明細に最新調整後金額を自動設定する
							if (roomEst == null && est.ActionType__c == CommConst.PROD_ACTION_TYPE_RP) {
								roomEst = est;
							} else {
								othSumPrice += CommUtils.nullToZero(est.UnitPrice__c);
								// 室料以外の明細の消費税を再設定する
								est.TaxRate__c = CONST_NEW_TAXRATE;
								est.BatchProcessStatusDiv__c = CONST_BATCH_STATUS;
								otherEsts.add(est);
							}
						}
						
						if (roomEst == null) {
							// 自動設定できず、メール通知へ記載する
							if (einfo2 == null) einfo2 = new ERRINFO(hditem.refBooking__r);
							// 室料明細がない場合、自動設定できないの場合
							einfo2.addItem(hditem);
							
						} else {
							roomEst.UnitPrice__c = CommUtils.nullToZero(hditem.UnitPrice__c - othSumPrice);
							roomEst.TaxRate__c = CONST_NEW_TAXRATE;
							roomEst.BatchProcessStatusDiv__c = CONST_BATCH_STATUS;
							nwUpdLst.add(roomEst);
							// 室料以外の明細を確認する
							nwUpdLst.addAll(otherEsts);
							// 2019/10/05 見積もり明細の金額変更ロジック by zy BEGIN
							hditem = changeSyncInfo(hditem,roomEst);
							// 2019/10/05 見積もり明細の金額変更ロジック by zy END
						}
						// ============= 税抜の場合 [END]============== 
					}
				}
				// 該当親のBreakdown明細に室料明細が非存在場合
				if (einfo2 != null) errmsgLst2.add(einfo2);
				else {
					// 消費税と処理区分を設定する
					hditem.TaxRate__c = CONST_NEW_TAXRATE;
					hditem.BatchProcessStatusDiv__c = CONST_BATCH_STATUS;
	                nwUpdLst.add(hditem);  
				}
//----------------------------------------------               
//System.debug(Logginglevel.info,'headerInfo='+hditem);     
//System.debug(Logginglevel.info,'hditem.TaxRate__c='+hditem.TaxRate__c);  
//System.debug(Logginglevel.info,'hditem.ServiceRate__c='+hditem.ServiceRate__c); 
//System.debug(Logginglevel.info,'hditem.UnitPrice__c='+hditem.UnitPrice__c);  
//System.debug(Logginglevel.info,'hditem.planSubMap='+planSubMap); 
//----------------------------------------------     
			} // for (BookingEstimateItem__c hditem : headeritems)
		}

		if (!nwUpdLst.isEmpty()) {
			//DataFixManagerUtils.stopTranTriggger();
			try {
				Database.SaveResult[] results = Database.update(nwUpdLst,false);
				if (results != null){
					Integer idx = 0;
					for (Database.SaveResult result : results) {
						if (!result.isSuccess()) {
							// エラー件数統計
							//IsNgCounts++;
							Database.Error[] errs = result.getErrors();
							for(Database.Error err : errs) {
								errorMessage += '\nエラー発生：' + nwUpdLst[idx].Name + '('+err.getStatusCode() + ' - ' + err.getMessage()+')'+ '\n';
								errorMessage += CONST_SF_BASEURL + '/'+nwUpdLst[idx].Id;
							}	
						} else {
							// 成功件数統計
							//IsOKCounts++;
						}
						idx++;
					}
				}
				
			} catch (Exception e) {
				System.debug(e.getTypeName() + ' - ' + e.getCause() + ': ' + e.getMessage());
			}
			//DataFixManagerUtils.begTranTriggger();
		}
		// 2019/09/30 会计明细消费税变更对应 WGCH BEGIN
		// 2019/10/05 見積もり明細の金額変更ロジック by zy BEGIN
		String tran1Query = ' Select Id, Name, Field1__r.Name, Field1__r.Relreserve__r.LeadIndexRef__c, Field1__r.Relreserve__r.LeadIndexSubId__c, Field1__r.Relreserve__r.RoomGroupNo__c, TaxRate__c, Field20__c, Field41__c, SpecialTax__c, ServiceRate__c, Field21__c, ParentTran1Ref__c, BatchProcessStatusDiv__c, Field7__c, UnitPriceDefKbCal__c, ActionType__c,PlanDetailSyncInfo__c from Tran1__c where BatchProcessStatusDiv__c != :CONST_BATCH_STATUS And TaxRate__c > 0 and Field1__r.Relreserve__c in :leadIds ';
		// 2019/10/05 見積もり明細の金額変更ロジック by zy END
		// 自動増税商品が存在場合、該当商品が存在の明細を更新対象外
		Set<Id> noTargetAccIdSet = new Set<Id>();
		Set<String> noRoomKeySet = new Set<String>(); // 过滤同一个房间Key
		if(!CommUtils.isBlank(taxIncMstItem.taxIncMstId)) {
			Id upd2rateId = taxIncMstItem.taxIncMstId;
			List<Tran1__c> tran1s = [Select Field1__c, Field1__r.Relreserve__r.LeadIndexRef__c, Field1__r.Relreserve__r.LeadIndexSubId__c, Field1__r.Relreserve__r.RoomGroupNo__c from Tran1__c where Field7__c = :upd2rateId];
			for (Tran1__c tran1 : tran1s){
				// ONEROOMの識別キー
				String Key = tran1.Field1__r.Relreserve__r.LeadIndexRef__c + '_' + tran1.Field1__r.Relreserve__r.LeadIndexSubId__c + '_' + tran1.Field1__r.Relreserve__r.RoomGroupNo__c;
				noRoomKeySet.add(Key);
				noTargetAccIdSet.add(tran1.Field1__c);
			}
		}
		if (!noTargetAccIdSet.isEmpty()) {
			tran1Query += ' And Field1__c not in :noTargetAccIdSet ';
		}
		// 2019/10/05 見積もり明細の金額変更ロジック by zy BEGIN
		if (!CommUtils.isBlank(currentStatus)) {
			tran1Query += ' And BatchProcessStatusDiv__c = :currentStatus ';
		}
		// 2019/10/05 見積もり明細の金額変更ロジック by zy END
		tran1Query += ' Order By ParentTran1Ref__c, Name ';
    	List<Tran1__c> tran1Lst = Database.query(tran1Query);
    	List<Tran1__c> tran1EndLst = new List<Tran1__c>();
    	for(Tran1__c tran1 : tran1Lst){
    		// ONEROOMの識別キー
    		String Key = tran1.Field1__r.Relreserve__r.LeadIndexRef__c + '_' + tran1.Field1__r.Relreserve__r.LeadIndexSubId__c + '_' + tran1.Field1__r.Relreserve__r.RoomGroupNo__c;
    		if(noRoomKeySet.contains(Key)) continue;
    		tran1EndLst.add(tran1);
    	}
		Map<String, List<Tran1__c>> accToTran1Map = new Map<String, List<Tran1__c>>();
		for (Tran1__c tran1 : tran1EndLst) {
			// accId
			String accId = CommUtils.nullToBlank(tran1.Field1__c);
			// 根据accId集计
			if(!accToTran1Map.containsKey(accId)) accToTran1Map.put(accId, new List<Tran1__c>());
			accToTran1Map.get(accId).add(tran1);
		}
		// 更新対象見積明細情報を格納する
		List<Tran1__c> nwUpdTran1Lst = new List<Tran1__c>();
		// 予約別見積明細を再計算する
		for(List<Tran1__c> tranLst : accToTran1Map.values()){
			// プランのBREAK明細情報を格納する
			map<Id, List<Tran1__c>> planSubMap = new map<Id, List<Tran1__c>>();
			// 該当予約の親見積明細リストを格納する
			list<Tran1__c> headeritems = new List<Tran1__c>();
			// 該当予約に紐付く見積明細を取得する
			ACCERRINFO einfo = null;
			for (Tran1__c tran1 : tranLst) {
				// 親見積明細のIDを取得取得
				Id parentId = tran1.ParentTran1Ref__c;
				// 親見積明細が存在場合、該当プランの明細をリストに格納する
				if (parentId != null) {
					if (!planSubMap.containsKey(parentId)) planSubMap.put(parentId, new list<Tran1__c>());
					planSubMap.get(parentId).add(tran1);
				} else {
					// 特別税存在場合、処理対象外、MESSAGEに格納する
					// 該当明細の特別税が存在場合、処理対象外（手動で再設定が必要）
					if (CommUtils.nullToZero(tran1.SpecialTax__c) > 0) {
						if (einfo == null) einfo = new ACCERRINFO(tran1);
						einfo.addItem(tran1);
						continue;
					}
					headeritems.add(tran1);
				}
			}
			if (einfo != null) accErrmsgLst.add(einfo);
//system.debug(loggingLevel.info, 'einfo='+einfo);

			// 税込み更新リストを格納する
			List<Tran1__c> incTaxEsts = new list<Tran1__c>();
			// Headerの明細金額を自動計算する（商品種別は支払の場合、対象外）
			for (Tran1__c hditem : headeritems) {
				// 商品明細の単価定義区分は３と４の場合、再計算が必要、１と２の場合、再計算が不要です
				Integer kbn = CommUtils.nullToIntZero(hditem.UnitPriceDefKbCal__c);
//system.debug(loggingLevel.info, 'kbn='+kbn);
				if (kbn == CommConst.APPOPTION_UTP_DEF_KB_OP1 || kbn == CommConst.APPOPTION_UTP_DEF_KB_OP2) {
				} else {
					// 単価定義区分３と４（単価に税抜）
					decimal qty = CommUtils.nullTozero(hditem.Field21__c);
					decimal serviceRate = CommUtils.nullToZero(hditem.ServiceRate__c);
					if (qty == 0) continue;
					// 子明細データが非存在場合、合計金額により、単価金額を再計算を行う
					// 現在の単価により、既存の単価再計算を行う
					Decimal total = (CommUtils.nullToZero(hditem.Field41__c) - CommUtils.nullToZero(hditem.SpecialTax__c)) / qty;
	                hditem.Field20__c = CommUtils.nullToBlank(CommUtils.convertPriceByTaxKbn(total, CONST_NEW_TAXRATE,serviceRate, 
	                                                                        CommConst.APPOPTION_UTP_DEF_KB_OP2, 
	                                                                        CommConst.APPOPTION_UTP_DEF_KB));
	                hditem.Field20__c = CommUtils.nullToBlank(checkIfHadScale(CommUtils.nullToZero(hditem.Field20__c), CONST_NEW_TAXRATE, serviceRate, CommConst.APPOPTION_UTP_DEF_KB));
				}
				// 該当親の子明細に室料が非存在場合、情報格納する     
				ACCERRINFO einfo2 = null;                                  	
				// 子明細データが存在場合、子明細情報を再計算する
				if (planSubMap.containsKey(hditem.id)) {
					// 明細単位の金額を自動計算を行う「室料ある場合、差分値が室料で調整を行う、室料がない場合、該当明細が１行目のみ存在場合、該当明細に単価調整を行う(子供プラン対応想定)
					list<Tran1__c> subitems = planSubMap.get(hditem.id);
					if (subitems.size() == 1) {
						subitems[0].Field20__c = hditem.Field20__c;
						subitems[0].TaxRate__c = CONST_NEW_TAXRATE;
						subitems[0].BatchProcessStatusDiv__c = CONST_BATCH_STATUS;
						// 2019/10/05 見積もり明細の金額変更ロジック by zy BEGIN
						hditem = changeSyncInfo(hditem,subitems[0]);
						// 2019/10/05 見積もり明細の金額変更ロジック by zy END
						nwUpdTran1Lst.add(subitems[0]);
//----------------------------------------------   
//System.debug(Logginglevel.info,'======[STEP2]======');  
//System.debug(Logginglevel.info,'subitems[0]='+subitems[0]);
//----------------------------------------------   
					} else {
						// 税込の場合
						if (kbn == CommConst.APPOPTION_UTP_DEF_KB_OP1 || kbn == CommConst.APPOPTION_UTP_DEF_KB_OP2) {
							// Header関連の明細の消費税を設定する
							for (Tran1__c tran1 : subitems) {
								tran1.TaxRate__c = CONST_NEW_TAXRATE;
								tran1.BatchProcessStatusDiv__c = CONST_BATCH_STATUS;
							}
							nwUpdTran1Lst.addAll(subitems);
			
							// Headerの消費税と処理区分を設定する
							hditem.TaxRate__c = CONST_NEW_TAXRATE;
							hditem.BatchProcessStatusDiv__c = CONST_BATCH_STATUS;
			                nwUpdTran1Lst.add(hditem);  
							continue;
						}
						// ============= 税抜の場合 [BEG]==============
						// 室料明細に格納する
						Tran1__c roomTran1 = null;
						Decimal othSumPrice = 0;
						// 室料以外の明細を格納する
						list<Tran1__c> otherTran1s = new list<Tran1__c>();
						for (Tran1__c tran1 : subitems) {
							// 室料情報が存在場合、該当明細に最新調整後金額を自動設定する
							if (roomTran1 == null && tran1.ActionType__c == CommConst.PROD_ACTION_TYPE_RP) {
								roomTran1 = tran1;
							} else {
								othSumPrice += CommUtils.nullToZero(tran1.Field20__c);
								// 室料以外の明細の消費税を再設定する
								tran1.TaxRate__c = CONST_NEW_TAXRATE;
								tran1.BatchProcessStatusDiv__c = CONST_BATCH_STATUS;
								otherTran1s.add(tran1);
							}
						}
						if (roomTran1 == null) {
							// 自動設定できず、メール通知へ記載する
							if (einfo2 == null) einfo2 = new ACCERRINFO(hditem);
							// 室料明細がない場合、自動設定できないの場合
							einfo2.addItem(hditem);
							
						} else {
							roomTran1.Field20__c = CommUtils.nullToBlank(CommUtils.nullToZero(hditem.Field20__c) - othSumPrice);
							roomTran1.TaxRate__c = CONST_NEW_TAXRATE;
							roomTran1.BatchProcessStatusDiv__c = CONST_BATCH_STATUS;
							// 2019/10/05 見積もり明細の金額変更ロジック by zy BEGIN
							hditem = changeSyncInfo(hditem,roomTran1);
							// 2019/10/05 見積もり明細の金額変更ロジック by zy END
							nwUpdTran1Lst.add(roomTran1);
							// 室料以外の明細を確認する
							nwUpdTran1Lst.addAll(otherTran1s);
						}
						// ============= 税抜の場合 [END]============== 
					}
				}
				// 該当親のBreakdown明細に室料明細が非存在場合
				if (einfo2 != null) accErrmsgLst2.add(einfo2);
				else {
					// 消費税と処理区分を設定する
					hditem.TaxRate__c = CONST_NEW_TAXRATE;
					hditem.BatchProcessStatusDiv__c = CONST_BATCH_STATUS;
	                nwUpdTran1Lst.add(hditem);  
				}
//----------------------------------------------               
//System.debug(Logginglevel.info,'headerInfo='+hditem);     
//System.debug(Logginglevel.info,'hditem.TaxRate__c='+hditem.TaxRate__c);  
//System.debug(Logginglevel.info,'hditem.ServiceRate__c='+hditem.ServiceRate__c); 
//System.debug(Logginglevel.info,'hditem.Field20__c='+hditem.Field20__c);  
//System.debug(Logginglevel.info,'hditem.planSubMap='+planSubMap); 
//----------------------------------------------     
			} // for (BookingEstimateItem__c hditem : headeritems)
		}
		if (!nwUpdTran1Lst.isEmpty()) {
			//DataFixManagerUtils.stopTranTriggger();
			try {
				Database.SaveResult[] results = Database.update(nwUpdTran1Lst,false);
				if (results != null){
					Integer idx = 0;
					for (Database.SaveResult result : results) {
						if (!result.isSuccess()) {
							// エラー件数統計
							//IsNgCounts++;
							Database.Error[] errs = result.getErrors();
							for(Database.Error err : errs) {
								errorMessage += '\nエラー発生：' + nwUpdTran1Lst[idx].Name + '('+err.getStatusCode() + ' - ' + err.getMessage()+')'+ '\n';
								errorMessage += CONST_SF_BASEURL + '/'+nwUpdTran1Lst[idx].Id;
							}	
						} else {
							// 成功件数統計
							//IsOKCounts++;
						}
						idx++;
					}
				}
			} catch (Exception e) {
				System.debug(e.getTypeName() + ' - ' + e.getCause() + ': ' + e.getMessage());
			}
			//DataFixManagerUtils.begTranTriggger();
		}
		// 2019/09/30 会计明细消费税变更对应 WGCH END
	}
	/**
	* 処理終了
	**/
	public void finish(Database.BatchableContext BC){
		//　スケジュール定義者のメールで送付する
		User setupUser = [select email from User where id = :scheduleCreatedById];
		String mailAdds = setupUser.email;
		if (CommUtils.isBlank(mailAdds)) return;
		
		// 未更新件数を統計する
		//AggregateResult rsAvg = [Select count(id) cnt from BookingEstimateItem__c where TaxRate__c != :CONST_NEW_TAXRATE And TaxRate__c > 0 And DAY_ONLY(convertTimezone(refBooking__r.EntryTime__c)) >= :CONST_TAXRATE_CHGDATE];
		//Integer noUpdateRsNum = Integer.valueOf(rsAvg.get('cnt'));
		
		// メール情報を設定する
		String mailBodyStr = '処理結果詳細';
		String errBodyStr = '';
		if (errmsgLst != null && !errmsgLst.isEmpty()) {
			errBodyStr += '\n特別税存在ため、下記対象明細が手動修正が必要：\n';
			for (ERRINFO err : errmsgLst) {
				errBodyStr += err.tomessage();
			}
		}
		if (errmsgLst2 != null && !errmsgLst2.isEmpty()) {
			errBodyStr += '\n該当プラン配下に室料明細がないため、自動調整対象外、下記対象明細が手動修正が必要：\n';
			for (ERRINFO err : errmsgLst2) {
				errBodyStr += err.tomessage();
			}
		}
		// 2019/09/30 会计明细消费税变更对应 WGCH BEGIN
		// メール情報を設定する
		if (accErrmsgLst != null && !accErrmsgLst.isEmpty()) {
			errBodyStr += '\n特別税存在ため、下記対象明細が手動修正が必要：\n';
			for (ACCERRINFO err : accErrmsgLst) {
				errBodyStr += err.tomessage();
			}
		}
		if (accErrmsgLst2 != null && !accErrmsgLst2.isEmpty()) {
			errBodyStr += '\n該当プラン配下に室料明細がないため、自動調整対象外、下記対象明細が手動修正が必要：\n';
			for (ACCERRINFO err : accErrmsgLst2) {
				errBodyStr += err.tomessage();
			}
		}
		if (CommUtils.isBlank(errBodyStr)) {
			mailBodyStr += '\n 見積明細・会計明細消費税と単価更新処理済み';
		} else mailBodyStr += errBodyStr;
		// 2019/09/30 会计明细消费税变更对应 WGCH END
		//mailBodyStr += '\n更新成功件数：' + IsOKCounts + '(件)';
		//mailBodyStr += '\n更新失敗件数：' + IsNgCounts + '(件)';
		//mailBodyStr += '\n未更新対象件数：' + (noUpdateRsNum - IsNgCounts) + '(件)';
		//if (noUpdateRsNum != IsNgCounts ) {
		//	mailBodyStr += '\n未更新対象データが存在するため、データを確認の上て、バッチを再実施してください。';
		//}
		mailBodyStr += errorMessage;
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = new String[]{mailAdds};
		mail.setToAddresses(toAddresses);
		mail.setSubject('[SalesTax8UpdaterChouMan2] バッチ処理結果の通知');
		mail.setPlainTextBody(mailBodyStr);
		// テストクラスの場合、実施しない
		if(!Test.isRunningTest())
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	}
	
	class ERRINFO {
		public ERRINFO(lead__c l) {
			leadId = l.id;
			leadName = l.Name;
			childItem = new list<BookingEstimateItem__c>();
		}
		private String leadId{get;set;}
		private String leadName{get;set;}
		private list<BookingEstimateItem__c> childItem{get;set;}
		public void addItem (BookingEstimateItem__c est) {
			childItem.add(est);
		}
		public String toMessage() {
			String s = '予約：'+leadName + '('+ CONST_SF_BASEURL + '/'+leadId + ')\n';
			for (BookingEstimateItem__c est : childItem) {
				s += '  見積明細：' + est.Name + '('+ CONST_SF_BASEURL + '/'+est.Id + ')\n';
			}
			return s;
		}
	}
	// 2019/09/30 会计明细消费税变更对应 WGCH BEGIN
	// 未処理結果対象リスト情報を格納する
	private list<ACCERRINFO> accErrmsgLst = null;
	private list<ACCERRINFO> accErrmsgLst2 = null;
	class ACCERRINFO {
		public ACCERRINFO(Tran1__c t) {
			accId = t.Field1__c;
			accName = t.Field1__r.Name;
			childItem = new list<Tran1__c>();
		}
		private String accId{get;set;}
		private String accName{get;set;}
		private list<Tran1__c> childItem{get;set;}
		public void addItem (Tran1__c tran1) {
			childItem.add(tran1);
		}
		public String toMessage() {
			String s = '会計：'+accName + '('+ CONST_SF_BASEURL + '/'+accId + ')\n';
			for (Tran1__c tran1 : childItem) {
				s += '  会計明細：' + tran1.Name + '('+ CONST_SF_BASEURL + '/'+tran1.Id + ')\n';
			}
			return s;
		}
	}
	// 2019/09/30 会计明细消费税变更对应 WGCH END
	
    // 小数桁数はシステム定義により、長い場合、単数処理後の処理値は検証する
    private Decimal checkIfHadScale(Decimal orgPrice,Decimal taxRate,Decimal serviceRate,Integer kbn){
        // システム小数点の長さ
        Integer pointLen = CommUtils.getPointLen(); 
        // 変換値の小数点桁数
        Integer pricePointLen = orgPrice.stripTrailingZeros().scale();
        // システム予想の小数桁数により、長小数点をもっている場合
        if(pricePointLen > pointLen){
            // 指定区分でサ込、税込金額を取得する
            CommUtils.ProductInfo pro =  new CommUtils.ProductInfo(kbn);
            pro.process(orgPrice,1,taxRate,serviceRate);
            Decimal orgIncTaxServicePrice = pro.unitPriceTax;
            
            // 指定小数まで切上げで変換する
            Decimal roundPrice = CommUtils.RoundProcess(orgPrice, pointLen, RoundingMode.CEILING);
            pro.process(roundPrice,1,taxRate,serviceRate);
            if (pro.unitPriceTax == orgIncTaxServicePrice) return roundPrice;
            
            // 指定小数まで切り捨てで変換する
            roundPrice = CommUtils.RoundProcess(orgPrice, pointLen, RoundingMode.FLOOR);
            pro.process(roundPrice,1,taxRate,serviceRate);
            if (pro.unitPriceTax == orgIncTaxServicePrice) return roundPrice;
        }
        return orgPrice;
    }
	// 2019/10/05 見積もり明細の金額変更ロジック by zy BEGIN
	private BookingEstimateItem__c changeSyncInfo(BookingEstimateItem__c parItem,BookingEstimateItem__c chdItem){
		// 明細ありの場合
		if (!CommUtils.isBlank(parItem.PlanDetailSyncInfo__c)){
			// 変更明細情報
			parItem.PlanDetailSyncInfo__c = processSyncInfo(parItem.PlanDetailSyncInfo__c,chdItem.id,chdItem.unitPrice__c);
		}
		return parItem;
	}
	private Tran1__c changeSyncInfo(Tran1__c parItem,Tran1__c chdItem){
		// 明細ありの場合
		if (!CommUtils.isBlank(parItem.PlanDetailSyncInfo__c)){
			// 変更明細情報
			parItem.PlanDetailSyncInfo__c = processSyncInfo(parItem.PlanDetailSyncInfo__c,chdItem.id,chdItem.Field20__c);
		}
		return parItem;
	}
	// 変更明細情報
	private String processSyncInfo(String syncInfo,String sobjectId,Decimal unitPrice){
		return processSyncInfo(syncInfo,sobjectId,CommUtils.nullToBlank(CommUtils.numberFormat(CommUtils.nullToZero(unitPrice))));
	}
	private String processSyncInfo(String syncInfo,String sobjectId,String unitPrice){
		// 見積もり明細の金額変更のフラグ
		boolean hadItemChg = false;
		List<String> msgInfos = new List<String>();
		for (String msg  : syncInfo.split(';') ) {
			String[] infos = msg.split(':');
			String bookingestId = infos[0];
			// 見積もり明細の金額変更
			if ( bookingestId == sobjectId) {
				infos[1] = CommUtils.nullToBlank(unitPrice);
				hadItemChg = true;
			}
			msg = String.join(infos,':');
			msgInfos.add(msg);
		}
		if (hadItemChg) syncInfo = String.join(msgInfos,';');
		return syncInfo;
	}
	// 2019/10/05 見積もり明細の金額変更ロジック by zy END
}