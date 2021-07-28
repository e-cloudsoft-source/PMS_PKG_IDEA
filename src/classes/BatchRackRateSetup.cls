public with sharing class BatchRackRateSetup implements Database.Batchable<TypeOfRooms__c>, Database.Stateful, Schedulable{
	private RackRateUtils.TierHelp help;
	private Map<String,ChatterInfo> chatterMap;
	private Map<String,ShopInformation__c> shopInfoMap;
	private Integer outputLen = 10000;
	// スケジュールで該当Methodを呼び出する
	public BatchRackRateSetup(){}
	public BatchRackRateSetup(RackRateUtils.TierHelp tierHelp) {
		help = tierHelp;
		chatterMap = new Map<String,ChatterInfo>();
		shopInfoMap = ShopInfoUtil.getShopInfoMap();
	}
    // ***********************************
	// スケジュール処理開始
	// ***********************************
	public void execute(SchedulableContext SC) {
		help = RackRateUtils.getTierMap();
		// バッチクラスを呼び出す
		BatchRackRateSetup batch = new BatchRackRateSetup(help);
		// バッチ処理設定
		DataBase.executeBatch(batch, help.commSet.batchSize);
	
	}
	// ***********************************
	// バッチ処理開始
	// ***********************************
	public Iterable<TypeOfRooms__c> start(Database.BatchableContext info){
		// 検索条件を追加
		set<string> typeOfRoomActType = new set<string>{CommConst.ROOMTYPE_NORMAL};
		// スケジュールから起動する場合、全て店舗を処理する
		return [select Id, Name, SumNotApplicableFlg__c,MaxRooms__c,MaxNumber__c,
						ShopInfoRef__c,ShopInfoRef__r.ShopCode__c,ShopInfoRef__r.name,Seq__c From TypeOfRooms__c 
							where ActionType__c = :typeOfRoomActType order by ShopInfoRef__r.ShopCode__c,Seq__c,RoomTypeCode__c];
	}

	// ***********************************
	// バッチロジック処理開始
	// ***********************************
	public void execute(Database.BatchableContext BC, List<TypeOfRooms__c> scope){
		Date begDt = Date.today();
		// 処理２月データ
		Integer monthInt = help.commSet.targetMonth;
		Date endDt = begDt.addMonths(monthInt);
		Integer daysLen = begDt.daysBetween(endDt);
		Set<Date> sotckDts = new Set<Date>();
		Set<String> spcdSet = new Set<String>();
		//　基本情報を取得する
		Set<Id> typeOfRoomIdSet = new Set<Id>();
		Map<String,TypeOfRooms__c> typeNameMap = new Map<String,TypeOfRooms__c>();
		Map<String,RackRateTableDetail__c> detailMaps = new Map<String,RackRateTableDetail__c>();
		for (TypeOfRooms__c typeRoom : scope) {
			typeOfRoomIdSet.add(typeRoom.id);
			spcdSet.add(typeRoom.ShopInfoRef__c);
		}
		for (integer i = 0 ; i < daysLen ; i++) {
			sotckDts.add(begDt.addDays(i));
		}
		Map<String,String> rateDefaultMap = new Map<String,String>();
		Map<String,RackRateTableDetail__c> detailMap = new Map<String,RackRateTableDetail__c>();
		// 日単位のTIER設定情報を取得する
		String queryRRDetailHeader = ' Select id,Tier__c, ShopInfoRef__c, ShopInfoRef__r.ShopCode__c,PriceSetupDate__c,SearchKey__c,RoomTypeRef__c From RackRateTableDetail__c ';
		String queryRRDetailString = queryRRDetailHeader + ' Where PriceSetupDate__c >=:begDt And PriceSetupDate__c <= :endDt and ShopInfoRef__c = :spcdSet';
		// 店舗条件
		for(RackRateTableDetail__c detail : Database.query(queryRRDetailString)){
			if (detail.RoomTypeRef__c == null) {
				rateDefaultMap.put(detail.SearchKey__c,detail.Tier__c);
			} else {
				detailMap.put(detail.SearchKey__c,detail);
			}
		}
		// 部屋数
		StockChangeHelpUtils helpUtils = new StockChangeHelpUtils();
		Map<String,Decimal> typeRoomsMap = helpUtils.getStockUsedInfo(typeOfRoomIdSet, sotckDts);
		for (TypeOfRooms__c typeRoom : scope) {
			String shopId = CommUtils.nullToBlank(typeRoom.ShopInfoRef__c);
			String spcd = CommUtils.nullToBlank(typeRoom.ShopInfoRef__r.ShopCode__c);
			// 根据日期过滤条件
			for (integer i = 0 ; i < daysLen ; i++) {
				Date queryDt = begDt.addDays(i);
				String detailKey = shopId + '_' + queryDt;
				String roomNumKey = typeRoom.id + '_' + queryDt.format();
				// 残室数
				integer rooms = CommUtils.nullToIntZero(CommUtils.nullToZero(typeRoom.MaxRooms__c) - CommUtils.nullToZero(typeRoomsMap.get(roomNumKey)));
				// 店铺默认tier
				String defaultTier = getDefTier(spcd);
				// ラックレート明細主tier
				if (rateDefaultMap.containsKey(detailKey)) defaultTier = rateDefaultMap.get(detailKey);
				// 条件设定tier取得
				String tier = help.getTier(spcd,CommUtils.nullToBlank(typeRoom.Seq__c),i,rooms);
				// 存在符合条件場合
				if (!CommUtils.isBlank(tier) && defaultTier != tier) {
					String searchKey = (shopId + '_' + queryDt + '_' + typeRoom.id);
					// 変更前のラックレート明細
					RackRateTableDetail__c orgDetail = new RackRateTableDetail__c(Tier__c = defaultTier);
					// ラックレート部屋タイプ別のデータあり
					if (detailMap.containsKey(searchKey)) orgDetail = detailMap.get(searchKey);
					// tier无变换
					if (tier == orgDetail.Tier__c) continue;
					// 新明細作成する
					RackRateTableDetail__c item = new RackRateTableDetail__c(
						Tier__c = tier,
						PriceSetupDate__c = queryDt,
						SearchKey__c = searchKey,
						RoomTypeRef__c = typeRoom.id);
					if (!CommUtils.isBlank(shopId)) item.ShopInfoRef__c = shopId;
					// チャット作成
					if (!chatterMap.containsKey(spcd)) chatterMap.put(spcd,new ChatterInfo());
					String message = makeDetaiMsg(orgDetail, item,typeRoom);
					chatterMap.get(spcd).add(searchKey,queryDt.format(),message);
					// 最終更新リスト
					detailMaps.put(searchKey,item);
				}
			}
		}
		// データ更新する
		if (!detailMaps.isEmpty()) upsert detailMaps.values() RackRateTableDetail__c.SearchKey__c;
	}
	// ***********************************
	// バッチ終了処理開始
	// ***********************************
	public void finish(Database.BatchableContext BC){
		String chatterMsgOth = '';
		if (!chatterMap.isEmpty()) {
			for (String shopId : chatterMap.keySet()) {
				// 店铺判断
				String shopName = '';
				if (shopInfoMap.containsKey(shopId)) shopName = shopInfoMap.get(shopId).name;
				ChatterInfo chatter = chatterMap.get(shopId);
				String contentMsg = chatter.getResult();
				if (!CommUtils.isBlank(contentMsg)) {
					contentMsg = '店舗：' + shopName + '\n' + contentMsg;
					chatterMsgOth += contentMsg;
				}
			}
		}
		String chatterMsg = 'ラックレート処理完了しましたのでお知らせいたします。';
		if (!CommUtils.isBlank(chatterMsgOth)) {
			chatterMsg += '\n変更詳細：\n';
			Integer logLen = chatterMsgOth.length();
			if (logLen > outputLen) {
				chatterMsgOth = CommLogUtils.removeOverLogString(chatterMsgOth,outputLen - 100 , true);
				chatterMsgOth += '\n ...';
			}
			chatterMsg += chatterMsgOth;
		}
		sendMsgToChatter(chatterMsg);
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
	// chatter post メーセッジ作成
	private String makeDetaiMsg(RackRateTableDetail__c orgDetail,RackRateTableDetail__c detail,TypeOfRooms__c typeRoom){
		String contentMsg = ' 部屋タイプ「' + typeRoom.name + '」' + orgDetail.Tier__c + '→' + detail.Tier__c + '\n';
		return contentMsg;
	}
	// ポストメッセージ→チャタ
	private void sendMsgToChatter(String pMsgBody) {
		// 
		List<String> chatterGroupNamesLst = CommConst.GetChatterGroupNameByCode(CommConst.TIER_ChatterGroupNameType);
		List<CollaborationGroup> chatterGroups = [select Id, Name from CollaborationGroup where name = :chatterGroupNamesLst and isarchived = false];
    	if (chatterGroups.isEmpty()) return;
  		
    	List<FeedItem> feedItems = new List<FeedItem>();
    	//String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
    	for (CollaborationGroup cGroup : chatterGroups) {
			
			FeedItem post = new FeedItem();
			post.Type = 'TextPost';
	        post.Body = pMsgBody;
	        post.ParentId = cGroup.Id;
	        feedItems.add(post);
    	}
    	if (!feedItems.isEmpty()) insert feedItems;
	}
	private class ChatterInfo {
		private map<String,Map<String,String>> dateChatterMap;
		public integer dateLen;
		public ChatterInfo() {
			dateLen = 0;
			dateChatterMap = new map<String,Map<String,String>>();
		}
		public void add(String searchKey,String dateStr,String msg) {
			change(searchKey,dateStr,msg);
			dateLen++;
		}
		public void change(String searchKey,String dateStr,String msg) {
			if (!dateChatterMap.containsKey(dateStr)) dateChatterMap.put(dateStr,new Map<String,String>());
			//Map<String,String> chatterMsgMap = 
			dateChatterMap.get(dateStr).put(searchKey,msg);
		}
		public String getResult() {
			String result = '';
			if (!dateChatterMap.isEmpty() ) {
				List<String> dateLst = new List<String>(dateChatterMap.keySet());
				dateLst.sort();
				for (String dateStr : dateLst) {
					result += dateStr + '\n';
					Map<String,String> chatterMsgMap = dateChatterMap.get(dateStr);
					for (String msg : chatterMsgMap.values()) {
						result += msg;
					}
				}
			}
			return result;
		}
	}
}