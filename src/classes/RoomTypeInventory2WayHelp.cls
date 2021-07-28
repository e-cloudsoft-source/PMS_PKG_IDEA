/**
*
**/
public with sharing class RoomTypeInventory2WayHelp {
	
	// TA残室情報を取得と表示対応
	public List<ShopInfo> getTaSalesInfo(Date conStartDate, Date conEndDate, list<SelectOption> branchShopLst, String branchShopNm) {   
		
		// ネット販売とリアル販売の在庫、残室数照会APIを呼び出す
		// 多店舗兼務　かつ　ALLの場合、兼務店舗範囲の販売状態情報を確認する
		List<ShopInfo> showShopList = new List<ShopInfo>();
		map<String, String> shopInfoMap = new map<String, String>();
		for (SelectOption so : branchShopLst) { shopInfoMap.put(so.getValue(), so.getLabel()); }
		
		// ALLの場合、含めされている店舗リストは全部取得対象で、TLから在庫情報を取得する
		if (CommUtils.isBlank(branchShopNm)) {
			// ALLの店舗情報から取得する
			for (SelectOption so : branchShopLst) { 
				// XMLに定義されている
				if (!TA_ServiceConfigHelp.isContractShop(so.getValue())) continue;
				showShopList.add(new ShopInfo(so.getValue(), so.getLabel())); 
			}
			// 店舗定義情報なしの場合、対応する
			if (branchShopLst.isEmpty() && TA_ServiceConfigHelp.isContractShop(branchShopNm)) showShopList.add(new ShopInfo('',''));
		} else {
			// 契約店舗のみ、情報設定
			if (TA_ServiceConfigHelp.isContractShop(branchShopNm)) {
				// 指定の店舗コードから販売状態を取得する
				showShopList.add(new ShopInfo(branchShopNm, shopInfoMap.get(branchShopNm)));
			}
		}
System.debug(logginglevel.info, 'showShopList::' + showShopList);
		if (showShopList.isEmpty()) return showShopList;
		
		// 照会期間情報を設定する
		List<DateInfo> dispHeaders = new List<DateInfo>();
		while (conStartDate <= conEndDate) {
			dispHeaders.add(new DateInfo(conStartDate));
			conStartDate = conStartDate.adddays(1);
		}
		set<string> shopCdsSet = new set<string>();
		// 店舗表示情報の初期化
		for (ShopInfo shop : showShopList) {
			// 合計値情報を初期化する
			for (DateInfo disp : dispHeaders) {
				shop.remaindCountSumMap.put(disp.yyyymmdd, 0);
			}
			shopCdsSet.add(shop.shopCode);
		}
		// 各店舗に定義のTA室タイプ情報を取得する
		map<string, set<string>> shopTaRoomTypeMap = new map<string, set<string>>();
		// API SERVICE 初期化
		TA_ServiceCtrl taService = new TA_ServiceCtrl();
		// 指定の多店舗情報から各店舗の在庫情報を取得する
		for (ShopInfo shop : showShopList) {
			String shopCd = shop.shopCode;
			if (!shopTaRoomTypeMap.containsKey(shopCd)) shopTaRoomTypeMap.put(shopCd, new set<string>());
			// 該当店舗に所属の部屋タイプ定義情報
			TA_RoomTypeInfoItem rep = taService.callRoomTypeMasterSearchService(shopCd);
			// サビース初期化
			if (!rep.commonResponse.isSuccess) {
				// エラー処理ログを記録する
				String errMsg = rep.commonResponse.failureReason+':'+rep.commonResponse.errorDescription;	
				throw new CommException(errMsg);
			} else {
				for (TA_RoomTypeInfoItem.RoomInfo rmInf : rep.roomList) {
					// 部屋タイプ空白の場合、対象外
					if (CommUtils.isBlank(rmInf.roomTypeCode)) continue;
					shopTaRoomTypeMap.get(shopCd).add(rmInf.roomTypeCode);
				}
			}
		}
		set<string> allRmTypeCdSet = new set<string>();
		for (set<string> rmTypeCdSet : shopTaRoomTypeMap.values()) {
			allRmTypeCdSet.addAll(rmTypeCdSet);
		}
		map<string, list<TypeOfRooms__c>> sfShopRmTypeCdMap = new map<string, list<TypeOfRooms__c>>();
		// SF側に定義の部屋タイプリストを取得する
		list<TypeOfRooms__c> sfRmTypeList = [select ShopInfoRef__r.ShopCode__c, RoomTypeCode__c, Name from TypeOfRooms__c where ShopInfoRef__r.ShopCode__c in :shopCdsSet And RoomTypeCode__c in :allRmTypeCdSet order by seq__c];
		for (TypeOfRooms__c sfRmType :sfRmTypeList) {
			String shopCd = CommUtils.nullToBlank(sfRmType.ShopInfoRef__r.ShopCode__c);
			String rmTypeCd = Commutils.nullToBlank(sfRmType.RoomTypeCode__c);
			set<string> rmTypeCdSet = shopTaRoomTypeMap.get(shopCd);
			if (rmTypeCdSet != null && rmTypeCdSet.contains(rmTypeCd)) {
				if (!sfShopRmTypeCdMap.containsKey(shopCd)) sfShopRmTypeCdMap.put(shopCd, new list<TypeOfRooms__c>());
				sfShopRmTypeCdMap.get(shopCd).add(sfRmType);
			}
		}
System.debug(logginglevel.INFO, 'sfShopRmTypeCdMap::' + sfShopRmTypeCdMap);	
		Date locToday = Date.today();
		// 各店舗の各部屋タイプの一ヶ月の在庫情報を取得する
		for (ShopInfo shop : showShopList) {
			String shopCd = shop.shopCode;
			if (!sfShopRmTypeCdMap.containsKey(shopCd)) continue;
			// 各部屋タイプの在庫数を初期化する?
			
			// 店舗単位の在庫情報を取得する
			List<TA_RoomStockInfoGetItem.RoomStockInfo> extractionConditionLst 
				= new List<TA_RoomStockInfoGetItem.RoomStockInfo>();
			for (TypeOfRooms__c sfTypeOfRoom : sfShopRmTypeCdMap.get(shopCd)) {
				String roomTypeCd = sfTypeOfRoom.RoomTypeCode__c;
				String roomTypeNm = sfTypeOfRoom.Name;
				// 初期化する　
				SfRoomTypeInfo sfRoomType = new SfRoomTypeInfo(roomTypeCd, roomTypeNm);
				// 一ヶ月期間
				for (DateInfo disp : dispHeaders) {
					// !!! 順番は重要、CONTINUEの前に初期値が必要
					// 該当部屋タイプの初期値設定を行う
					sfRoomType.remaindCountSumMap.put(disp.yyyymmdd, new SalesDayInfo());
					// 過去日の在庫取得できない
					if (disp.dt < locToday) continue;
					// 取得条件設定
					TA_RoomStockInfoGetItem.RoomStockInfo extractionCondition 
						= new TA_RoomStockInfoGetItem.RoomStockInfo();
					extractionCondition.roomTypeCode = roomTypeCd;	// 部屋タイプコード
					extractionCondition.stockDate = disp.yyyy_mm_dd;	// 取得日付
					extractionConditionLst.add(extractionCondition);

				}
				// 各部屋タイプコード配列を格納
				shop.sfRmTypeCdLst.add(roomTypeCd);
				// 各部屋タイプコードの３１日間の在庫情報を格納する
				shop.sfRmTypeMap.put(roomTypeCd, sfRoomType);
			}
			if (extractionConditionLst.isEmpty()) return showShopList;
			// 在庫状況照会(ネット販売)API 呼出
			TA_RoomStockInfoGetItem rep = taService.callStockSearchService(shopCd, extractionConditionLst);
			// 指定店舗の販売状態を戻る
			// 異常発生する場合、エラーは画面に戻る
			if (!rep.commonResponse.isSuccess) {
				// エラー処理ログを記録する
				String errMsg = rep.commonResponse.failureReason+':'+rep.commonResponse.errorDescription;	
				throw new CommException(errMsg);
			} 
			// 該当店舗の販売状態を戻る場合
			else {
				// 2015/10/28 残室数は０の場合、エラーは戻る、メールを送信する機能対応 END
				for (TA_RoomStockInfoGetItem.RoomStockInfo stock : rep.roomStockList) {
					SfRoomTypeInfo sfRoomTypeStockInfo = shop.sfRmTypeMap.get(stock.roomTypeCode);
					//sfRoomTypeStockInfo.remaindCountSumMap()
					String yyyymmdd = stock.stockDate.replace('-','');
					SalesDayInfo stockInfo = sfRoomTypeStockInfo.remaindCountSumMap.get(yyyymmdd);
					stockInfo.saleDate = yyyymmdd;
					stockInfo.remainingCount = CommUtils.nullToBlank(stock.remainingCount);
					stockInfo.salesStatus = CommUtils.nullToBlank(stock.salesClosed);
				}	
			}
		} // End For(各店舗設定情報)
		
		// 店舗別の残室数を合計する
		for (ShopInfo shop : showShopList) {
			for (String rmTypeCd  : shop.sfRmTypeCdLst) {
				SfRoomTypeInfo sfRm = shop.sfRmTypeMap.get(rmTypeCd);
				for (DateInfo disp : dispHeaders) {
					//System.debug(loggingLevel.INFo, sfRm.remaindCountSumMap.get(disp.yyyymmdd));
					String key = disp.yyyymmdd;
					Integer shopRemaindCount = shop.remaindCountSumMap.get(key);
					shopRemaindCount += CommUtils.nullToIntZero(sfRm.remaindCountSumMap.get(key).remainingCount);
					shop.remaindCountSumMap.put(key, shopRemaindCount);
				}
			}
		}
		return showShopList;
	} 

	public class ShopInfo {
		public ShopInfo(String cd, String nm) {
			shopCode = CommUtils.nullToBlank(cd);
			shopName = nm;
			sfRmTypeCdLst = new list<string>();
			sfRmTypeMap = new map<String, SfRoomTypeInfo>();	// SF側の部屋タイプ単位を情報を格納する
			remaindCountSumMap = new map<String, Integer>();
		}
		public String shopCode{get;set;}
		public String shopName{get;set;}
		public List<String> sfRmTypeCdLst{get;private set;}
		public map<String, SfRoomTypeInfo> sfRmTypeMap{get;private set;}
		// 残室数の合計値「月間」(店舗単位)
		public map<String, Integer> remaindCountSumMap{get;set;}
		public void clear() {
			sfRmTypeCdLst.clear();
			sfRmTypeMap.clear();
		}
	}
	// SF側の部屋タイプに関連のTL側の販売先の在庫情報を格納する
	public class SfRoomTypeInfo {
		public SfRoomTypeInfo(String cd, String nm) {
			rmTypeCode = cd;
			rmTypeName = nm;
			remaindCountSumMap = new map<String, SalesDayInfo>();
		}
		public String rmTypeCode{get;set;}
		public String rmTypeName{get;set;}
		// 残室数の合計値「月間」
		public map<String, SalesDayInfo> remaindCountSumMap{get;set;}
		/*
		// 該当AGTの残室数合計計算を行う[室タイプグループ単位、販売停止以外の残室数合計]
		public void calRemaindCount(List<dispHeader> dispHeaders) {
			// 指定期間の残室数を計算する
			for (dispHeader disp : dispHeaders) {
				remaindCountSumMap.put(disp.yyyymmdd, 0);
			}
		}*/
	}
	
	public class DateInfo {
		public DateInfo(Date currDt) {
			DateTime formatter = DateTime.newInstance(currDt.year(), currDt.month(), currDt.day());
			yyyy_mm_dd = formatter.format('yyyy-MM-dd');
			yyyymmdd = formatter.format('yyyyMMdd');
			dt = currDt;
		}
		public Date dt{get; private set;}
		public string yyyy_mm_dd{get; private set;}
		public string yyyymmdd{get;private set;}
	}
	// 日単位販売情報格納
	public class SalesDayInfo {
		public String saleDate{get;set;}	// YYYYMMDD
		public String salesCount{get;set;}	// 販売数
		public String remainingCount{get;set;}	// 残室数
		public String salesStatus{get;set;}	// 販売ステータス
	}
}