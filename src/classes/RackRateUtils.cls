public class RackRateUtils {

    // プラン明細に室料項目の場合、情報を格納する
    //private static final String roomRateProdName = CommConst.APPOPTION_ROOMPRICE_PRODNAME;
    // 会計商品種別は室料
    private static final String roomRateTypeName = CommConst.PROD_ACTION_TYPE_RP;
    	
	private Map<String,ShopInformation__c> shopInfoMap;
	public RackRateUtils() {
		shopInfoMap = ShopInfoUtil.getShopInfoMap();
		// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
		bookingEstPersonMap = new Map<String,Map<Id,String>>();
		bookingEstGuestTypeMap = new Map<String,Map<Id,String>>();
		bookingEstMap = new Map<String, List<BookingEstimateItem__c>> ();
		// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
		// 2020/06/30 6538 bug fix by zy BEGIN
		// 予約のベースプランの料理集合
		basePlanRoomRateMap = new Map<String,Decimal>();
		// 2020/06/30 6538 bug fix by zy END
	}
	// 2020/04/03 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz BEGIN		
	// 予約から該当日の室料を取得する
	public Map<Id,Decimal> getRoomRateByLead(Set<Id> leadIds){
		return getRoomRateByLead(leadIds,new Set<String>());
	}
	// 予約から該当日とベースプランの室料を取得する
	public Map<Id,Decimal> getRoomRateByLead(Set<Id> leadIds,Set<String> basePlanSet) {
	// 2020/04/03 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz END
		
		// 到着日、予約人数、部屋タイプ
		List<Lead__c> leads = [Select id,refTypeOfRooms__c,EntryTime__c,StayPersons__c,
										refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c,refTypeOfRooms__r.ShopInfoRef__c
								// 2020/04/03 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz BEGIN		
								,GuestType__c
								// 2020/04/03 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz END
								 From Lead__c 
								 where Id in : leadIds And refTypeOfRooms__c != null And StayPersons__c > 0
								 order by EntryTime__c ];
		// 店舗情報一覧を取得する
//System.debug(LoggingLevel.INFO, 'getRoomRateByLead::[leadIds]::' + leadIds);
  		// 自動料金設定する予約データがない場合、処理終了
  		if (leads.isEmpty()) return new Map<Id,Decimal>();
//System.debug(LoggingLevel.INFO, 'getRoomRateByLead::::' + leads);
  		// 既存の予約データの到着日の開始日と終了日を取得する
		//Date stDate = targets[0].EntryTime__c.date();
		//Date edDat  = targets[targets.size()-1].EntryTime__c.date();
	// 2020/04/03 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz BEGIN	
		return getRoomRateByLead(leads,basePlanSet);
	}
		
	// 予約から該当日の室料を取得する
	public Map<Id,Decimal> getRoomRateByLead(List<Lead__c> leads){
		return getRoomRateByLead(leads,new Set<String>());
	}
	public Map<Id,Decimal> getRoomRateByLead(List<Lead__c> leads,Set<String> basePlanSet) {
	// 2020/04/03 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz END
		//　予約単位の室料格納情報
		Map<Id, Decimal> leadRoomRateMap = new Map<Id, Decimal>();
		// 店舗条件
		// ラックレート検索キーを格納する
		//Map<Id, String> rakurateKeySet = new Map<Id, String>(); 
		//Map<Id, String> rakurateDetailKeySet = new Map<Id, String>();
		// ラックレート明細情報を格納する
		Set<String> rackRateItemSearchKeySet = new Set<String>();
		// 2020/04/03 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz BEGIN	
		Set<String> basePlankSearchKeySet = new Set<String>();
		// 2020/04/03 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz END	
		for (Lead__c lead : leads) {
			// 店舗コードを取得する
			//String shopCode = CommUtils.nullToBlank(lead.refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c);
			//String tier
			// Tier + "_" + 部屋タイプID + "_" + 人数 
			//String key = 
			// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　BEGIN
			rackRateItemSearchKeySet.add(genRackRateDetailSearchKey(lead.refTypeOfRooms__r.ShopInfoRef__c, lead.EntryTime__c.date()) + '%');
			// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　END
			// 2020/04/03 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz BEGIN	
			if (!CommUtils.isBlank(lead.GuestType__c))
				basePlankSearchKeySet.add(genRackRateBasePlanSearchKey(lead.refTypeOfRooms__r.ShopInfoRef__c,lead.GuestType__c,lead.EntryTime__c.date()) + '%');
			// 2020/04/03 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz END	
			// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
			// 予約の見積明細の会員種別対応
			if (bookingEstMap.containsKey(lead.id)) {
				for (BookingEstimateItem__c est : bookingEstMap.get(lead.id)) {
					String guestType = est.guestType__c;
					if (CommUtils.isBlank(guestType)) est.guestType__c = lead.GuestType__c;
					if (est.SysSelBasePlanNums__c == null || est.SysSelBasePlanNums__c == 0) est.SysSelBasePlanNums__c = CommUtils.nullToZero(lead.StayPersons__c);
					basePlankSearchKeySet.add(genRackRateBasePlanSearchKey(lead.refTypeOfRooms__r.ShopInfoRef__c,est.guestType__c,lead.EntryTime__c.date()) + '%');
				}
			}
			/*
			if (bookingEstGuestTypeMap.containsKey(lead.id)) {
				Map<Id,String> bookingGuestTypes = bookingEstGuestTypeMap.get(lead.id);
				for (String bookingEstId : bookingGuestTypes.keySet()) {
					String guestType = bookingGuestTypes.get(bookingEstId);
					if (!CommUtils.isBlank(guestType))
						basePlankSearchKeySet.add(genRackRateBasePlanSearchKey(lead.refTypeOfRooms__r.ShopInfoRef__c,guestType,lead.EntryTime__c.date()) + '%');
				}
			}*/
			// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
			// ラックレートのキーを作成する
		}
//System.debug(LoggingLevel.INFO, 'rackRateItemSearchKeySet::::' + rackRateItemSearchKeySet);
  		// 店舗単位の期間範囲のTier情報を取得する
  		String queryRRDetailHeader = ' Select SearchKey__c, Tier__c, ShopInfoRef__c, ShopInfoRef__r.ShopCode__c,PriceSetupDate__c From RackRateTableDetail__c ';
		// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　BEGIN
		String queryRRDetailString = queryRRDetailHeader + ' Where SearchKey__c like :rackRateItemSearchKeySet ';
		RackDetailUtils rackDetail = getRackDetaiInfo(DataBase.query(queryRRDetailString));
		
  		/*
		
		// 期間単位のTier情報を取得する
		// SearchKey/TIER
		Map<String, String> setupTierMap = new Map<String, String>();
		for (RackRateTableDetail__c detail : DataBase.query(queryRRDetailString)) {
			setupTierMap.put(detail.SearchKey__c, detail.Tier__c);
		}
		*/
		// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　END
		// システムDefaultの設定値
		//String systemDefaultTier =  CommUtils.nullToBlank( CommDefine__c.getOrgDefaults().RackRateTableTierDefault__c );
//System.debug(LoggingLevel.INFO, 'setupTierMap::::' + setupTierMap);
		Set<String> rackRateSearchKeySet = new Set<String>();
		Map<Id, String> leadRackRatekeyMap = new Map<Id, String>();
		// 2020/04/03 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz BEGIN
		// プランのTIER対応
		Map<String,String> planTierMap = getBasePlanTierMap(basePlankSearchKeySet,basePlanSet);
		// 予約のベースプランのTIER対応
		Map<String,String> leadBasePlanTierMap = new Map<String,String>();
		// 2021/04/18 ラックレート設定ベースプラン金額 BY zyz BEGIN
		// 予約のベースプランのTIER対応（ラックレート）
		Map<String,String> leadBasePlanRackTierMap = new Map<String,String>();
		// 2021/04/18 ラックレート設定ベースプラン金額 BY zyz END
		// 2020/06/30 6538 bug fix by zy BEGIN
		// 予約のベースプランの料理集合
		// basePlanRoomRateMap = new Map<String,Decimal>();
		// 2020/06/30 6538 bug fix by zy END
		// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
		// 見積明細のTier情報集合
		Map<String,String> estTierMap = new Map<String,String>();
		// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
		// 2020/04/03 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz END
		for (Lead__c lead : leads) {
			
			String detailSearchKey = genRackRateDetailSearchKey(lead.refTypeOfRooms__r.ShopInfoRef__c, lead.EntryTime__c.date());
			// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　BEGIN
			String leadTier = rackDetail.getCurTier(lead.EntryTime__c.date(),lead.refTypeOfRooms__r.ShopInfoRef__c,lead.refTypeOfRooms__c); //systemDefaultTier;
			//if (setupTierMap.containsKey(detailSearchKey)) leadTier = setupTierMap.get(detailSearchKey).getTierByRoomTypeId(lead.refTypeOfRooms__c);
			if (CommUtils.isBlank(leadTier)) leadTier = getDefTier(lead.refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c);
			// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　END
			
			// 予約人数と部屋タイプIDにより、ラックレートの検索キーを作成する
			String searchKey = genRackRateSearchKey(leadTier, lead.refTypeOfRooms__c, CommUtils.nullToBlank(lead.StayPersons__c));
			rackRateSearchKeySet.add(searchKey);
			// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
			if (bookingEstMap.containsKey(lead.id)) {
				for (BookingEstimateItem__c est : bookingEstMap.get(lead.id)) {
					// 見積人数情報
					String bookingEstPerson = CommUtils.nullTOBlank(est.SysSelBasePlanNums__c);
					if (Commutils.nullToZero(bookingEstPerson) == 0) {
						bookingEstPerson = Commutils.nullToBlank(lead.StayPersons__c);
						est.SysSelBasePlanNums__c = Commutils.nullToZero(lead.StayPersons__c);
					}
					// TIER鍵
					searchKey = genRackRateSearchKey(leadTier, lead.refTypeOfRooms__c, CommUtils.nullToBlank(bookingEstPerson));
					// TIER取得
					rackRateSearchKeySet.add(searchKey);
					// 見積の鍵
					estTierMap.put(est.id,searchKey);
				}
			}
			/*
			// 指定見積明細の人数のTier値対応
			if (bookingEstPersonMap.containsKey(lead.id)) {
				// 見積人数情報
				Map<Id,String> estPersonMap = bookingEstPersonMap.get(lead.id);
				// 見積の人数のTIER取得
				for (Id estId : estPersonMap.keySet()) {
					// 見積人数情報
					String bookingEstPerson = estPersonMap.get(estId);
					if (Commutils.nullToZero(bookingEstPerson) == 0) bookingEstPerson = Commutils.nullToBlank(lead.StayPersons__c);
					// TIER鍵
					searchKey = genRackRateSearchKey(leadTier, lead.refTypeOfRooms__c, CommUtils.nullToBlank(bookingEstPerson));
					// TIER取得
					rackRateSearchKeySet.add(searchKey);
					// 見積の鍵
					estTierMap.put(estId,searchKey);
				}
			}*/
			// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
			//
			leadRackRatekeyMap.put(lead.Id, searchKey);
			// 2020/04/03 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz BEGIN
			for (String planId : basePlanSet) {
				// 該当ベースプランキー
				String planDetailKey = genRackRateBasePlanSearchKey(lead.refTypeOfRooms__r.ShopInfoRef__c,lead.GuestType__c,lead.EntryTime__c.date()) + '_' + planId;
				// 該当ベースプランの設定あり
				if (planTierMap.containsKey(planDetailKey)) {
					// ベースプラン対応TIER
					leadTier = planTierMap.get(planDetailKey);
					// TIERのキー
					searchKey = genRackRateSearchKey(leadTier, lead.refTypeOfRooms__c, CommUtils.nullToBlank(lead.StayPersons__c));
					rackRateSearchKeySet.add(searchKey);
					// 2021/04/18 ラックレート設定ベースプラン金額 BY zyz BEGIN
					// 追加plan设定的key
					String searchPlanKey = searchKey + '_' + planId;
					rackRateSearchKeySet.add(searchPlanKey);
					leadBasePlanRackTierMap.put(genLeadPlanSerachKey(lead.Id,planId),searchPlanKey);
					leadBasePlanTierMap.put(genLeadPlanSerachKey(lead.Id,planId),searchKey);
					// 2021/04/18 ラックレート設定ベースプラン金額 BY zyz END
				}
				// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
				// 予約の見積明細の会員種別対応
				if (bookingEstMap.containsKey(lead.id)) {
					for (BookingEstimateItem__c est : bookingEstMap.get(lead.id)) {
						String guestType = est.GuestType__c;
						planDetailKey = genRackRateBasePlanSearchKey(lead.refTypeOfRooms__r.ShopInfoRef__c,guestType,lead.EntryTime__c.date()) + '_' + planId;
						// ベースプラン対応TIER
						// 2021/04/28 #10811 bug fix by zyz BEGIN
						if(planTierMap.containskey(planDetailKey)) leadTier = planTierMap.get(planDetailKey);
						// 2021/04/28 #10811 bug fix by zyz END
						String person = CommUtils.nullToBlank(est.SysSelBasePlanNums__c);
						// TIERのキー
						searchKey = genRackRateSearchKey(leadTier, lead.refTypeOfRooms__c, person);
						rackRateSearchKeySet.add(searchKey);
						// 2021/04/18 ラックレート設定ベースプラン金額 BY zyz BEGIN
						// 追加plan设定的key
						String searchPlanKey = searchKey + '_' + planId;
						rackRateSearchKeySet.add(searchPlanKey);
						leadBasePlanRackTierMap.put(genLeadPlanEstSerachKey(lead.Id,planId,est.id),searchPlanKey);
						// 予約の見積明細のベースプラン
						leadBasePlanTierMap.put(genLeadPlanEstSerachKey(lead.Id,planId,est.id),searchKey);
						// 2021/04/18 ラックレート設定ベースプラン金額 BY zyz END
					}
				}
				/*
				// 予約の見積明細の会員種別対応
				if (bookingEstGuestTypeMap.containsKey(lead.id)) {
					Map<Id,String> bookingGuestTypes = bookingEstGuestTypeMap.get(lead.id);
					for (String bookingEstId : bookingGuestTypes.keySet()) {
						String guestType = bookingGuestTypes.get(bookingEstId);
						system.debug(LoggingLevel.info,'guestType:::' + guestType);
						planDetailKey = genRackRateBasePlanSearchKey(lead.refTypeOfRooms__r.ShopInfoRef__c,guestType,lead.EntryTime__c.date()) + '_' + planId;
						// ベースプラン対応TIER
						leadTier = planTierMap.get(planDetailKey);
						String person = CommUtils.nullToBlank(lead.StayPersons__c);
						if (bookingEstPersonMap.containsKey(lead.id) && bookingEstPersonMap.get(lead.id).containsKey(bookingEstId)) person = bookingEstPersonMap.get(lead.id).get(bookingEstId);
						// TIERのキー
						searchKey = genRackRateSearchKey(leadTier, lead.refTypeOfRooms__c, person);
						rackRateSearchKeySet.add(searchKey);
						// 予約の見積明細のベースプラン
						leadBasePlanTierMap.put(genLeadPlanEstSerachKey(lead.Id,planId,bookingEstId),searchKey);
					}
				}*/
				// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
			}
			// 2020/04/03 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz END
		}
//System.debug(LoggingLevel.INFO, 'RESULT:::' + [select id, SearchKey__c, Tier__c, Price__c,RoomTypeRel__c from RackRateTable__c]);
		// 同じ部屋タイプ、同じTIER、人数で、料金情報を取得する
		List<RackRateTable__c> raceRateMst = [select id, SearchKey__c,Tier__c, Price__c from RackRateTable__c where SearchKey__c in :rackRateSearchKeySet ]; 
  		// 同じ部屋タイプ、同じ人数で、各TIER情報を取得する
  		Map<String, Decimal> tierMstMap = new Map<String, Decimal>();
  		for (RackRateTable__c raceRate : raceRateMst) {
  			tierMstMap.put(raceRate.SearchKey__c, raceRate.Price__c);
  		}
//System.debug(LoggingLevel.INFO, 'tierMstMap[]::::' + tierMstMap);
  		for (Lead__c lead : leads) {
  			if (leadRackRatekeyMap.containsKey(lead.Id)) {
  				String searchKey = leadRackRatekeyMap.get(lead.Id);
  				// 該当キーの室料を取得する
  				if (tierMstMap.containskey(searchkey)) {
  					leadRoomRateMap.put(lead.Id, tierMstMap.get(searchkey));
				}
			}
			// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
			if (bookingEstMap.containsKey(lead.id)) {
				// 見積の人数対応の集合作成
				for (BookingEstimateItem__c est : bookingEstMap.get(lead.id)) {
					String searchKey = estTierMap.get(est.id);
					// 該当キーの室料を取得する
					if (tierMstMap.containskey(searchkey)) {
						leadRoomRateMap.put(est.id, tierMstMap.get(searchkey));
				  	}
  				}
			}
			/*
			if (bookingEstPersonMap.containsKey(lead.id)) {
				// 見積の人数対応の集合作成
				Map<Id,String> estPersonMap = bookingEstPersonMap.get(lead.id);
				for (Id estId : estPersonMap.keySet()) {
					String searchKey = estTierMap.get(estId);
					// 該当キーの室料を取得する
					if (tierMstMap.containskey(searchkey)) {
						leadRoomRateMap.put(estId, tierMstMap.get(searchkey));
				  	}
  				}
			}*/
			// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
			// 2020/04/03 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz BEGIN
			for (String planId : basePlanSet) {
				// 該当ベースプランキー
				String planDetailKey = genLeadPlanSerachKey(lead.Id,planId);
				if (leadBasePlanTierMap.containsKey(planDetailKey)) {
					String searchkey = leadBasePlanTierMap.get(planDetailKey);
					// 2021/04/18 ラックレート設定ベースプラン金額 BY zyz BEGIN
					String searchPlankey = leadBasePlanRackTierMap.get(planDetailKey);
					if (tierMstMap.containskey(searchPlankey) && CommConst.RACKRATE_BASEPLAN){
						basePlanRoomRateMap.put(planDetailKey, tierMstMap.get(searchPlankey));
					} else 
					// 2021/04/18 ラックレート設定ベースプラン金額 BY zyz END
					// ベースプラン料金作成
					// 該当キーの室料を取得する
					// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
					if (tierMstMap.containskey(searchkey)) basePlanRoomRateMap.put(planDetailKey, tierMstMap.get(searchkey));
					// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
				}
				// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
				if (bookingEstMap.containsKey(lead.id)) {
					// 見積の人数対応の集合作成
					for (BookingEstimateItem__c est : bookingEstMap.get(lead.id)) {
						// 見積明細のプランの鍵
						planDetailKey = genLeadPlanEstSerachKey(lead.Id,planId,est.id);
						// 見積明細のプランのTier対応
						if (leadBasePlanTierMap.containsKey(planDetailKey)) {
							String searchkey = leadBasePlanTierMap.get(planDetailKey);
							// 2021/04/18 ラックレート設定ベースプラン金額 BY zyz BEGIN
							String searchPlankey = leadBasePlanRackTierMap.get(planDetailKey);
							// ベースプラン料金作成
							if (tierMstMap.containskey(searchPlankey) && CommConst.RACKRATE_BASEPLAN){
								basePlanRoomRateMap.put(planDetailKey, tierMstMap.get(searchPlankey));
							} else 
							// 2021/04/18 ラックレート設定ベースプラン金額 BY zyz END
							// 該当キーの室料を取得する
							if (tierMstMap.containskey(searchkey)) basePlanRoomRateMap.put(planDetailKey, tierMstMap.get(searchkey));
						}
					}
				}
				/*
				// 見積の会員種別対応
				if (bookingEstGuestTypeMap.containsKey(lead.id)) {
					// 見積明細の処理
					for (String estId : bookingEstGuestTypeMap.get(lead.id).keySet()){
						// 見積明細のプランの鍵
						planDetailKey = genLeadPlanEstSerachKey(lead.Id,planId,estId);
						// 見積明細のプランのTier対応
						if (leadBasePlanTierMap.containsKey(planDetailKey)) {
							String searchkey = leadBasePlanTierMap.get(planDetailKey);
							System.debug(LoggingLevel.INFO, 'searchkey[]::::' + searchkey);
							// ベースプラン料金作成
							// 該当キーの室料を取得する
							if (tierMstMap.containskey(searchkey)) basePlanRoomRateMap.put(planDetailKey, tierMstMap.get(searchkey));
						}
					}
				}*/
				// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
			}
			// 2020/04/03 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz END
		}
		
  		return leadRoomRateMap;
	}
	private String getDefTier(String shopCd) {
		if (shopInfoMap.containsKey(shopCd)) {
			return 	CommUtils.isBLank((shopInfoMap.get(shopCd)).TierDefault__c) 
					? CommUtils.nullToBlank( CommDefine__c.getOrgDefaults().RackRateTableTierDefault__c )
					: CommUtils.nullToBlank( (shopInfoMap.get(shopCd)).TierDefault__c );
		} else {
			return CommUtils.nullToBlank( CommDefine__c.getOrgDefaults().RackRateTableTierDefault__c );
		}
	}
	// 
	private static String genRackRateSearchKey(string tierName, Id roomTypeId, String peoples) {
    	return (tierName + '_' + roomTypeId + '_' + peoples);
    }
	private static String genRackRateDetailSearchKey(Id shopId, Date configDate) {
    	return (CommUtils.nullToBlank(shopId) + '_' + configDate);
    }
    // 室料商品がどうか判別用
    // 2015/10/14 室料会計商品判定ロジック変更：名一致&&商品処理種別：室料→商品処理種別：室料　のみチェックを行う
    public static Boolean isRoomRateProduct(AccountMaster__c accMst) {
    	// 2015/10/14 EDIT BEGIN
    	//return (accMst.Name == roomRateProdName &&
        //    	accMst.ActionType__c == roomRateTypeName);
        return (accMst.ActionType__c == roomRateTypeName);
        // 2015/10/14 EDIT END
    }
    // 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　BEGIN
    public static Boolean isRoomRateProduct(String s) {
    	return s == roomRateTypeName;
    }
	// ラックレート明細の部屋タイプ別の保存
	// TierAutoSetupConfig
	public static void saveRackDetailsByRoomType(Set<String> typeIdSet , List<RackRateTableDetail__c> details,boolean clearDetail) {
		Map<String,RackRateTableDetail__c> searchKeyMap = new Map<String,RackRateTableDetail__c>();
		List<RackRateTableDetail__c> updLst = new List<RackRateTableDetail__c>();
		List<String> searchKeyLst = new List<String>();
		// seachkey查询
		for (RackRateTableDetail__c detail : details) {
			searchKeyLst.add(detail.SearchKey__c + '%');
			searchKeyMap.put(detail.SearchKey__c,detail);
			// 部屋タイプ別の作成
			if (!typeIdSet.isEmpty()) {
				for (String typeId : typeIdSet) {
					if (CommUtils.isBlank(typeId)) continue;
					RackRateTableDetail__c  d = detail.clone(false,false);
					d.SearchKey__c += '_' + typeId;
					d.RoomTypeRef__c = typeId;
					updLst.add(d);
				}
			} else updLst.add(detail);
		}
		// 
		List<Id> deleteLst = new List<Id>();
		// ラックレート部屋タイプ別の明細クリア
		if (clearDetail) {
			// 清除当日下所有部屋タイプ別数据
			if (!searchKeyLst.isEmpty()) delete [select id from RackRateTableDetail__c where SearchKey__c like :searchKeyLst and RoomTypeRef__c != null];
		}
		// 不存在主tier的，进行保存
		if (!updLst.isEmpty()) upsert updLst RackRateTableDetail__c.SearchKey__c;
		
	}
	public static TierHelp getTierMap() { 
    	TierHelp help = new TierHelp();
    	try{
	    	List<Dom.XmlNode> topNodeXmlList = CommXmlUtils.getAllTopXmlNode('TierAutoSetupConfig',new List<String>());
			// XML NODE
			for (Dom.XmlNode node : topNodeXmlList) {
				// XML TAG
				string xmlTagName = node.getName();
				if(xmlTagName.equals('COMMON')){
					help.commSet = new CommonSetting(node);
				} else if (xmlTagName.equals('SHOP')) {
					Dom.XmlNode shopcode =  node.getChildElement('SHOPCODE', null);
					String strShopCode = CommUtils.nullToBlank(shopcode.getText());
					Dom.XmlNode rule =  node.getChildElement('Rule', null);
					Dom.XmlNode color =  node.getChildElement('TierColor', null);
					help.add(strShopCode,new ShopTier(rule,color));
				}
			}
    	} catch(exception e) {}
        return help;
	}
	public static RackDetailUtils getRackDetaiInfo(List<RackRateTableDetail__c> details) {
		// 店舗単位の期間範囲のTier情報を取得する
		RackDetailUtils rateUtil = new RackDetailUtils();
		if (!details.isEmpty()) {
			for (RackRateTableDetail__c detail : details) {
				rateUtil.addDetail(detail);
			}
		}
		return rateUtil;
	}
	// ラックレート対応
	public class RackDetailUtils {
		// 鍵別
		private Map<String,RackRateTableDetail__c> setupTierMap;
		// 利用日別と鍵別
		private Map<Date,Map<String,RackRateTableDetail__c>> dateRmTypMap;
		public Set<String> tierSet;
		public RackDetailUtils() {
			tierSet = new Set<String>();
			setupTierMap = new Map<String,RackRateTableDetail__c>();
			dateRmTypMap = new Map<Date,Map<String,RackRateTableDetail__c>>();
		}
		public void addDetail(RackRateTableDetail__c detail) {
			// 鍵別対応
			if (!setupTierMap.containsKey(detail.SearchKey__c)) setupTierMap.put(detail.SearchKey__c,detail);
			// 利用日別の鍵別の対応
			if (!dateRmTypMap.containsKey(detail.PriceSetupDate__c)) dateRmTypMap.put(detail.PriceSetupDate__c,new Map<String,RackRateTableDetail__c>());
			Map<String,RackRateTableDetail__c> detailMap = dateRmTypMap.get(detail.PriceSetupDate__c);
			if (!detailMap.containsKey(detail.SearchKey__c)) detailMap.put(detail.SearchKey__c,detail);
			tierSet.add(detail.tier__c);
		}
		public RackRateTableDetail__c getDetailByKey(String key , String roomTypeId) {
			return setupTierMap.get(key + '_' + roomTypeId);
		}
		public boolean hadDetail(String key) {
			return setupTierMap.containsKey(key);
		}
		public boolean hadDetail(Date hidDate) {
			return dateRmTypMap.containsKey(hidDate);
		}
		public String getCurTier(String key , String roomTypeId) {
			return getDetailByKey(key,roomTypeId).tier__c;
		}
		public String getCurTier(Date queryDt,Id shopId,Id typeId) {
			String sumKey = CommUtils.nullToBlank(shopId) + '_' + queryDt;
			Map<String,RackRateTableDetail__c> detailMap = dateRmTypMap.get(queryDt);
			String defaultTier = '';
			if (detailMap != null && detailMap.containsKey(sumKey)) defaultTier = detailMap.get(sumKey).tier__c;
			sumKey += '_' + CommUtils.nullToBlank(typeId);
			if (detailMap != null && detailMap.containsKey(sumKey)) defaultTier = detailMap.get(sumKey).tier__c;
			return defaultTier;
		}
	}
	public class TierHelp {
		public CommonSetting commSet;
		public Map<String,ShopTier> shopTierMap;
		public ShopTier defaultTier;
		public TierHelp () {
			shopTierMap = new Map<String,ShopTier>();
			commSet = new CommonSetting();
		}
		public void add(String spcd,ShopTier tier) {
			if (defaultTier == null) defaultTier= tier;
			shopTierMap.put(spcd,tier);
		}
		public String getTier(String spcd,String typeCode,Integer days,Decimal rooms) {
			ShopTier shopTier = shopTierMap.get(spcd);
			if (shopTier == null) shopTier = defaultTier;
			if (shopTier != null) {
				return shopTier.processTier(typeCode,days,CommUtils.nullToIntZero(rooms));
			}
			return null;
		}
		// 多店舗Tier色設定情報の取得
		public List<TierSetting> getAllTierSetting() {
			List<TierSetting> allSetting = new List<TierSetting>();
			// 默认颜色定义
			if (defaultTier != null) allSetting.addAll(defaultTier.getTierSetting());
			// 单独店铺区分
			for (String shopCode : shopTierMap.keySet()) {
				// 店舗別のTier色表示用CSSのCLASS情報定義する
				String tierSpcd = '.TierSpcd_' + shopCode;
				ShopTier tier = shopTierMap.get(shopCode);
				// カラー設定
				for (TierSetting setting : tier.getTierSetting()) {
					// カラーのクラス名更新
					List<String> tierName = setting.tierName.split(',');
					TierSetting newTier = new TierSetting(setting.background);
					newTier.textColor = setting.textColor;
					// 店舗別の名前対応
					if (!CommUtils.isBlank(tierSpcd)) {
						String newName = '';
						// 添加shopcode
						for (String name : tierName) {
							if (CommUtils.isBlank(name)) continue;
							newName += tierSpcd + name + ',';
						}
						newTier.tierName = newName.removeEnd(',');
					}
					allSetting.add(newTier);
				}
			}
			return allSetting;
		}
		public List<TierSetting> getTierSetting(String spcd) {
			if (shopTierMap.containsKey(spcd)) return shopTierMap.get(spcd).getTierSetting();
			else if (defaultTier != null) return defaultTier.getTierSetting();
			return new List<TierSetting>();
		}
	}
	// 店舗別INFO
	public class ShopTier{
		// 部屋タイプ別Map
		public Map<String,TierUtils> tierUtilsMap ;
		public TierUtils defaultUtils;
		public List<TierSetting> tierSetting;
		public TierSetting defaultSetting;
		public ShopTier(Dom.Xmlnode tierRule,Dom.Xmlnode tierColor){
			tierUtilsMap = new Map<String,TierUtils>();
			tierSetting = new List<TierSetting>();
			// 添加规则
			if (tierRule != null) {
				for (Dom.Xmlnode tier : tierRule.getChildElements()) {
					String tierName = tier.getName();
					if (tierName == 'RuleItem') {
						Dom.XmlNode roomTypeNode = tier.getChildElement('RoomTypeSeq',null);
						Set<String> roomTypeSet = new Set<String>();
						if (roomTypeNode != null) {
							String roomTypeSeq = CommUtils.nullToBlank(roomTypeNode.getText());
							if (!CommUtils.isBlank(roomTypeSeq)) {
								roomTypeSet.addAll(roomTypeSeq.split(','));
							}
						}
						add(roomTypeSet,tier);
					}
				}
			}
			// 添加颜色设定
			if (tierColor != null) {
				String color = tierColor.getAttribute('Color',null);
				defaultSetting = new TierSetting(color);
				for (Dom.XmlNode tierNode : tierColor.getChildElements()) {
					add(new TierSetting(tierNode));
				}
			}
		}
		public void add(Set<String> typeCodeSet, Dom.XmlNode tierNode){
			if (typeCodeSet.isEmpty()) addTypeToMap('',tierNode);
			else {
				for (String typeCode : typeCodeSet) {
					addTypeToMap(typeCode,tierNode);
				}
			}
		}
		// 添加xmlnode
		private void addTypeToMap(String typeCode,Dom.XmlNode tierNode) {
			// 全处理场合
			if (CommUtils.isBlank(typeCode)) {
				if (defaultUtils == null) defaultUtils = new TierUtils();
				defaultUtils.add(tierNode );
			} else {
				if (!tierUtilsMap.containsKey(typeCode)) tierUtilsMap.put(typeCode,new TierUtils());
				tierUtilsMap.get(typeCode).add(tierNode);
			}
		}
		public void add(TierSetting t){
			tierSetting.add(t);
		}
		public String processTier(String typeCode,Integer days,Integer rooms){
			TierUtils utils = null;
			if (tierUtilsMap.containsKey(typeCode)) utils = tierUtilsMap.get(typeCode);
			String tier = '';
			if (utils != null) tier = utils.processCond(days,rooms);
			if (!CommUtils.isBlank(tier)) return tier;
			if (defaultUtils != null) return defaultUtils.processCond(days,rooms);
			return null;
		}
		// 取得color设定
		public List<TierSetting> getTierSetting(){
			List<TierSetting> tierLst = new List<TierSetting>();
			if (defaultSetting != null) tierLst.add(defaultSetting);
			if (tierSetting != null && !tierSetting.isEmpty()) tierLst.addAll(tierSetting);
			return tierLst;
		}
	}
	// バッチ設定
	public class CommonSetting {
		public Integer batchSize;
		public Integer targetMonth;
		public CommonSetting() {
			// 初期化
			batchSize = 5;
			targetMonth = 36;
		}
		public CommonSetting (Dom.XmlNode setNode) {
			// 初期化
			batchSize = 20;
			targetMonth = 12;
			if (setNode != null) {
				Dom.XmlNode batchSizeNode = setNode.getChildElement('BATCHSIZE', null);
				Dom.XmlNode targetNode = setNode.getChildElement('TARGETMONTH', null);
				if (batchSizeNode != null) {
					batchSize = CommUtils.nullToIntZero(batchSizeNode.getText());
				}
				if (targetNode != null) {
					targetMonth = CommUtils.nullToIntZero(targetNode.getText());
				}
			}
		}
	}
	// カラー設定
	public class TierSetting {
		public String tierName{get;set;}
		public String background{get;set;}
		public String textColor{get;set;}
		public TierSetting (String color) {
			tierName = '.defaultTierClass';
			background = color;
			textColor = '';
		} 
		public TierSetting (Dom.XmlNode color) {
			tierName = '.defaultTierClass';
			background = '';
			textColor = '';
			if (color != null) {
				String keyStr = color.getAttribute('Key',null);
				String fontColor = color.getAttribute('fontColor',null);
				if (!CommUtils.isBlank(keyStr)) {
					String name = '';
					for (String keyName : keyStr.split(',')) {
						if (CommUtils.isBlank(keyName)) continue;
						name += '.' + keyName + ',';
					}
					if (!CommUtils.isBlank(name)) name = name.removeEnd(',');
					tierName = name;
				}
				background = CommUtils.nullToBlank(color.getText());
				textColor =  CommUtils.nullToBlank(fontColor);
			}
		}
	}
	// Tierルールリストのクラス
	public class TierUtils {
		// 休日ルール
		// List<Tier> holiTiers;
		// ルールリスト
		List<Tier> tiers;
		//String typeCode;
		public TierUtils(){
			tiers = new List<Tier>();
			//holiTiers = new List<Tier>();
		}
		public void add(Dom.XmlNode node) {
		    Tier tierRule = new Tier(node);
		    if (tierRule.isValidata()) tiers.add(tierRule);
		}
		public String processCond(Integer days,Integer rooms){
			//List<Tier> tierLst = new List<Tier>();
			//if (isHoliday) tierLst.addAll(holiTiers);
			//tierLst.addAll(tiers);
			//for (Tier tier : tierLst) {
			for (Tier tier : tiers) {
				if (tier.chkCondition(days,rooms)) return tier.value;
			}
			return '';
		}
	}
	class Tier {
		integer minRoom;
		integer maxRoom;
		integer begDays;
		integer endDays;//
		String value;// Tier値
		boolean isok;
		public Tier (Dom.XmlNode node) {
            // 最小残室数
			Dom.XmlNode minRoomsNode = node.getChildElement('RemainedMinRooms',null); 
			// 最大残室数
			Dom.XmlNode maxRoomsNode = node.getChildElement('RemainedMaxRooms',null);
            // 何日前から
            Dom.XmlNode begDaysNode = node.getChildElement('RemainedStartDays',null);
			// 何日前まで
			Dom.XmlNode endDaysNode = node.getChildElement('RemainedEndDays',null);
			// Tier値
			Dom.XmlNode tierNode = node.getChildElement('Tier',null);
			minRoom = getNodeVal(minRoomsNode);
			maxRoom = getNodeVal(maxRoomsNode);
			begDays = getNodeVal(begDaysNode);
			endDays = getNodeVal(endDaysNode);
			if (tierNode != null) value = CommUtils.nullToBlank(tierNode.getText());
			// データルール有効、無効チェック
			isok = !((minRoom == null && maxRoom == null && begDays == null && endDays == null) || CommUtils.isBlank(value));
			if (isok) {
                if (minRoom == null) minRoom = -99999999;
                if (maxRoom == null) maxRoom = 99999999;
                if (begDays == null) begDays = 99999999;
                if (endDays == null) endDays = 0;
			}
		}
		// 添加int类型的node节点 如果设定为0 或者大于0的数字则可以用
		private Integer getNodeVal(Dom.XmlNode node) {
		    Integer rs = null;
			if (node != null) {
				String nodeVal = CommUtils.nullToBlank(node.getText());
				if (!CommUtils.isBlank(nodeVal)) {
				    Integer val = CommUtils.nullToIntZero(nodeVal);
				    if (val >= 0) rs = val;
				}
			}
			return rs;
		}
		public boolean isValidata() {
		    return isok;
		}
		// 查看检索条件
		// Return: trueの場合、ルール適応する
		public boolean chkCondition(Integer daysBetween,Integer rooms){
			// 対象条件チェック
			return !((rooms > maxRoom ) || (rooms < minRoom) || (daysBetween < endDays) || ( daysBetween > begDays));
		}
	}
	// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　END
	// 2020/04/03 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz BEGIN	
	// ベースプランキー作成
	public static String genRackRateBasePlanSearchKey(String shopId ,String guestType,Date configDate) {
		String key = '';
		if (!CommUtils.isBlank(shopId)) key += shopId + '_';
		key += guestType + '_' + DateTime.newInstance(configDate,Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd HH:mm:ss');
    	return key;
	}
	// 予約とベースプランキー作成
	public static String genLeadPlanSerachKey(String leadId,String planId) {
		return CommUtils.nullToBLank(leadId) + '_' + CommUtils.nullToBLank(planId);
	}
	// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
	// 予約とベースプランキー作成
	public static String genLeadPlanEstSerachKey(String leadId,String planId,String bookingEstId) {
		return CommUtils.nullToBLank(leadId) + '_' + CommUtils.nullToBLank(planId) + '_' + CommUtils.nullToBlank(bookingEstId);
	}
	// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
	// ベースプランのTIER取得
	public Map<String,String> getBasePlanTierMap(Set<String> searchKeySet,Set<String> basePlanIdSet){
		// プランのTIER対応
		Map<String,String> planTierMap = new Map<String,String> ();
		if (!basePlanIdSet.isEmpty()) {
			List<BasePlanDetail__c> planDetails = genRackRateBasePlanBySearchKey(searchKeySet);
			if (!planDetails.isEmpty()) {
				// プランのTIER対応
				for (BasePlanDetail__c detail :  planDetails) {
					// ベースプラン指定の場合
					if (detail.BasePlanRef__c != null) {
						planTierMap.put(detail.SearchKey__c,detail.tier__c);
					// ベースプラン未指定の場合
					} else {
						// 全てベースプランの対応作成
						for (String planId : basePlanIdSet) {
							// 6243 bug fix by zy BEGIN
							String searchKey = detail.SearchKey__c + '_' + planId;
							// 6243 bug fix by zy END
							planTierMap.put(searchKey,detail.tier__c);
						}
					}
				}
			}
		}
		return planTierMap;
	}
	// ベースプランリスト取得
	public static List<BasePlanDetail__c> genRackRateBasePlanBySearchKey(Set<String> searchKeySet) {
		List<BasePlanDetail__c> planDetail = new List<BasePlanDetail__c>();
		// 2020/05/30 bug 6415 fixed by zy BEGIN
		if (!searchKeySet.isEmpty()) planDetail = [select id,SearchKey__c,Tier__c,PriceSetupDate__c,SalesStatus__c,BasePlanRef__c from BasePlanDetail__c where SearchKey__c like :searchKeySet order by BasePlanRef__c NULLS FIRST];
		// 2020/05/30 bug 6415 fixed by zy BEGIN
		return planDetail;
	}
	// 予約とベースプラン料金作成
	public Map<String,Decimal> basePlanRoomRateMap;
	// 2020/04/03 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz END	
	// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
	// 予約下の見積明細の指定人数集合
	public Map<String,Map<Id,String>> bookingEstPersonMap;

	// 予約下の見積明細の会員種別集合
	public Map<String,Map<Id,String>> bookingEstGuestTypeMap;
	// 予約下の見積明細の指定人数集合
	public Map<String,List<BookingEstimateItem__c>> bookingEstMap;
	// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
 }