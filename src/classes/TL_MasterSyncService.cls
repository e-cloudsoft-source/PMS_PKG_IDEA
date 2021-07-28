/**
* TLのマスタ情報定義情報からSFへ取込機能
* 2015/09/11 プランマスタ取込、部屋タイプ取込み
**/
global with sharing class TL_MasterSyncService {

	//public static String OK{get{return 'OK';}}
	//public static String NG{get{return 'NG';}}
	/**
	* TL側のプランマスタ定義情報の取込み
	* 取り込み後、自動的に、関連のプラン会計商品も自動作成
	**/
	webservice static String importPlanMaster(String branchShopCd, Boolean isSync) {
		// 指定の店舗コードはNULLの場合、店舗情報マスタから店舗コードを取得する、多店舗じゃない場合、単店舗情報を取得する
		List<String> shopCdsLst = getImportShopCodes(branchShopCd);
		Map<String, ShopInformation__c> shopInfoMap = ShopInfoUtil.getShopInfoMap();
		// 消費税マスタ
		JMST__c taxRateInf = CommLogicProcess.getTaxRateInfo();
		// 初期化
		map<String, Plan__c> tlMsgTypeRooms = new map<String, Plan__c>();
		set<String> planShopSet = new set<String>();
		set<String> pkgCdSet = new set<String>();
		TL_ServiceCtrl tlService = new TL_ServiceCtrl();
		Map<String, Account> accMap = new Map<String, Account>();

		// 既存のAGT情報を取得する
		String salesOfficeCompanyType =  'ネット';
		String contractStatus =  '有効';
		String accountType =  CommConst.ACCOUNT_TYPE_TRAVEL;
		List<Account> accList = [select Id, Name, SalesOfficeCompanyCodeTLAPI__c from Account where SalesOfficeCompanyType__c = :salesOfficeCompanyType and ContractStatus__c = :contractStatus and AccountType__c = :accountType];
		Map<String, String> agtCodeMap = new Map<String, String>();
		for (Account s:accList ) {
			agtCodeMap.put(s.SalesOfficeCompanyCodeTLAPI__c, s.Id);
		}
		// 各店舗のプラン定義情報を取得する
		for (String shopCd : shopCdsLst) {
			// 契約していない店舗情報は取込対象外になる
			if (!TL_ServiceConfigHelp.isContractShop(shopCd)) continue;
			// APIを呼出
			TL_NetPlanMasterSearchService.extractionCondition condition =
				new TL_NetPlanMasterSearchService.extractionCondition();
			condition.extractionProcedureCode = '0';
			
			TL_NetPlanMasterSearchService.planMstSearchForNetResponse netRep =
				tlService.callNetPlanMasterSearchService(shopCd, condition);
			if (!netRep.commonResponse.isSuccess) {
				return netRep.commonResponse.failureReason + ':' + netRep.commonResponse.errorDescription;
			}
			netRep.planList = (netRep.planList == null) ? new TL_NetPlanMasterSearchService.plan[0] : netRep.planList;
			for (TL_NetPlanMasterSearchService.plan rm: netRep.planList) {
				Plan__c nPlan = new Plan__c(
					PackageCode__c = rm.planCode,
					Name = rm.planName,
					client__c = agtCodeMap.get(rm.agtCode),
					ShopInfoRef__c = shopInfoMap.containsKey(shopCd) ? shopInfoMap.get(shopCd).Id : null,
					Price__c = 0,
					JmstRef__c = taxRateInf.Id
				);
				String nkey = getPlanKey(nPlan);
				tlMsgTypeRooms.put(nkey, nPlan);
				planShopSet.add(shopCd);
				pkgCdSet.add(rm.planCode);
			}
			netRep.planGroupList = (netRep.planGroupList == null) ? new TL_NetPlanMasterSearchService.planGroup[0] : netRep.planGroupList;
			for (TL_NetPlanMasterSearchService.planGroup rm: netRep.planGroupList) {
				Plan__c nPlan = new Plan__c(
					PackageCode__c = rm.planGroupCode,
					Name = rm.planGroupName,
					ShopInfoRef__c = shopInfoMap.containsKey(shopCd) ? shopInfoMap.get(shopCd).Id : null,
					Price__c = 0,
					JmstRef__c = taxRateInf.Id
				);
				String nkey = getPlanKey(nPlan);
				tlMsgTypeRooms.put(nkey, nPlan);
				planShopSet.add(shopCd);
				pkgCdSet.add(rm.planGroupCode);
			}
		}
		
		if (!tlMsgTypeRooms.isEmpty()) {
			List<Plan__c> nwlst = new List<Plan__c>();
			List<Plan__c> existRoomTypes = [select Id, Name, AccountA__c, AccountB__c, AccountC__c, AccountTotal__c, Charge1__c, Charge2__c, Charge3__c, ChargeRC__c, Comment__c, DpRef__c, GpRef__c, Image1__c, Image2__c, Image3__c, Image4__c, IsClosed__c, JmstRef__c, Lunch__c, PackageCode__c, PlanNo__c, PlanStartDateandtime__c, Plan_URL__c, Planclosedateandtime__c, Price__c, PublicPlan__c, Roomname__c, Roomtype__c, Seq__c, ServiceN__c, ServiceRate__c, Service__c, client__c, dinner__c, mealcost__c, morning__c, BasePlanFlg__c, ShopInfoRef__c from Plan__c 
											where ShopInfoRef__r.ShopCode__c in :planShopSet and PackageCode__c in :pkgCdSet ];
			map<String, Plan__c> existRoomTypeMap = new map<String, Plan__c>();
			for (Plan__c oPlan : existRoomTypes) {
				String okey = getPlanKey(oPlan);
				existRoomTypeMap.put(okey, oPlan);
			}
			for (String skey : tlMsgTypeRooms.keySet()){
				// システムに該当プランが非存在の場合、新規登録を行う
				if (!existRoomTypeMap.containsKey(skey)) {
					nwlst.add(tlMsgTypeRooms.get(skey));
				}
			}
			if (!nwlst.isEmpty()) insert nwLst;
		}
		//取込正常に完了しました。
		return Label.MSG_038_0021;
	}
	/**
	* TL側の部屋タイプ定義情報の取込み
	* 支店単位に、部屋タイプマスタを取り込みを行う（多店舗は重複な部屋タイプが存在する）
	* 多店舗から一括取込する場合、同じ部屋タイプコードが存在するので、店舗・部屋タイプコード単位で予約情報を取り込み
	* 店舗コードが引渡しない場合、全て店舗情報は一括取込みを行う
	* isSyncMaxRoomNum:TL側の（販売数＋残室数）はSFDCに反映するがどうか判断フラグ
	* isOnlyConfirm:TL側室タイプ名とコードのマッピング情報を表示する
	**/
	webservice static String[] importRoomTypeMaster(String branchShopCd, String isSyncMaxRoomNum) {
		/* 2015/10/21 無効なコードになる
		return syncRoomTypeMaster(branchShopCd,isSyncMaxRoomNum,String.valueOf(false));*/
		return new String[0];
	}
	webservice static String[] confirmRoomTypeMaster(String branchShopCd, String isOnlyConfirm) {
		/* 2015/10/21 無効なコードになる
		return syncRoomTypeMaster(branchShopCd,String.valueOf(false),isOnlyConfirm);*/
		return new String[0];
	}
	/* 2015/10/21 無効なコードになる
	private static String[] syncRoomTypeMaster(String branchShopCd, String isSyncMaxRoomNum, String isOnlyConfirm) {
		// 処理結果
		String[] rs = new String[]{'取込正常に完了致しました。',OK};

		// APIから部屋タイプマスタ定義情報を取得する
		// 既存の全て部屋タイプをLOCK
		map<String, ShopInformation__c> shopInfoMap = ShopInfoUtil.getShopInfoMap();
		// 指定の店舗コードはNULLの場合、店舗情報マスタから店舗コードを取得する、多店舗じゃない場合、単店舗情報を取得する
		List<String> shopCdsLst = getImportShopCodes(branchShopCd);
		// 部屋タイプ情報を作成する
		// TODO 多店舗対応が必要
		map<String, TypeOfRooms__c> tlMsgTypeRooms = new map<String, TypeOfRooms__c>();
		// 店舗単位の各部屋タイプ情報
		map<String, map<String, TypeOfRooms__c>> tlMsgTypeCodeMap = new map<String, map<String, TypeOfRooms__c>>();
		// 部屋タイプコード
		set<String> typeRoomCdSet = new set<String>();
		// 店舗単位で全て店舗情報から部屋タイプに取込を行う
		TL_ServiceCtrl tlService = new TL_ServiceCtrl();
		for (String shopCd : shopCdsLst) {
			// 契約していない店舗情報は取込対象外になる
			if (!TL_ServiceConfigHelp.isContractShop(shopCd)) continue;
			// 部屋タイプマスタ検索(ネット販売)API
			TL_NetRoomTypeMasterSearchService.extractionCondition condition =
				new TL_NetRoomTypeMasterSearchService.extractionCondition();
			condition.extractionProcedureCode = '0';
			
			TL_NetRoomTypeMasterSearchService.rmTypeMstSearchForNetResponse netRep =
				tlService.callNetRoomTypeMasterSearchService(shopCd, condition);
			if (!netRep.commonResponse.isSuccess) {
				rs[0] = netRep.commonResponse.failureReason + ':' + netRep.commonResponse.errorDescription;
				rs[1] = NG;
				return rs;
			}
			
			// 部屋タイプマスタ検索(旅行会社)API
			TL_RealRoomTypeMasterSearchService.rmTypeMstSearchForRealResponse realRep = 
				tlService.callRealRoomTypeMasterSearchService(shopCd);
			// エラーが発生する場合
			if (!realRep.commonResponse.isSuccess) {
				rs[0] = realRep.commonResponse.failureReason + ':' + realRep.commonResponse.errorDescription;
				rs[1] = NG;
				return rs;
			}
			
			// 部屋タイプマスタ検索(ネット販売)API -> 
			netRep.rmTypeList = (netRep.rmTypeList == null) 
									? new TL_NetRoomTypeMasterSearchService.rmType[0]		
									: netRep.rmTypeList;
			for (TL_NetRoomTypeMasterSearchService.rmType rm: netRep.rmTypeList) {
				
				TypeOfRooms__c rType = new TypeOfRooms__c(
					RoomTypeCode__c = rm.rmTypeCode,
					RoomTypeName__c = rm.rmTypeName,
					Name = rm.rmTypeName,
					ShopInfoRef__c = shopInfoMap.containsKey(shopCd) ? shopInfoMap.get(shopCd).Id : null
				);
				String key = getRoomTypeKey(rType);
				tlMsgTypeRooms.put(key, rType);
				typeRoomCdSet.add(rm.rmTypeCode);
				// 各店舗の部屋タイプコード情報を格納する
				if (!tlMsgTypeCodeMap.containskey(shopCd)) {
					tlMsgTypeCodeMap.put(shopCd, new map<String, TypeOfRooms__c>());
				}
				tlMsgTypeCodeMap.get(shopCd).put(CommUtils.paddingLeftZero(rm.rmTypeCode,100), rType);
			}*/
			/*
			// 室タイプコードと室タイプグループコードにより、販売室数を自動設定を行う
			if (Boolean.valueOf(isSyncMaxRoomNum)) {
				// map<ネット室タイプグループコードー＞室タイプコード>
				map<string, string> rmTypeGroupCdToRmTypeCdMap = new map<String, String>();
				// ネット室タイプグループ
				netRep.netRmTypeGroupList = (netRep.netRmTypeGroupList == null) 
									? new TL_NetRoomTypeMasterSearchService.netRmTypeGroup[0]		
									: netRep.netRmTypeGroupList;
				for (TL_NetRoomTypeMasterSearchService.netRmTypeGroup typeGroup : netRep.netRmTypeGroupList) {
					// 室タイプー＞グループコードMAPPING情報を格納する
					rmTypeGroupCdToRmTypeCdMap.put(typeGroup.netRmTypeGroupCode,typeGroup.rmTypeCode);
				}
				// 在庫情報を取得する
				String ajdustDate = System.now().format('yyyyMMdd');
				// 指定日、指定タイプグループコードで、在庫照会を行う
				TL_NetStockSearchService.extractionCondition extractionCondition
					= new TL_NetStockSearchService.extractionCondition();
				extractionCondition.extractionProcedure = '2';			// 「2」:照会期間で検索、
				extractionCondition.searchDurationFrom = ajdustDate;	// 照会期間FROM
				extractionCondition.searchDurationTo = ajdustDate;		// 照会期間TO
				
				//*****在庫状況照会(ネット販売)API 呼出開始******
				// 在庫状況照会(ネット販売)API 呼出
				TL_NetStockSearchService.stockSearchForNetResponse stockNetRep
					= tlService.callNetStockSearchService(shopCd, extractionCondition);
				// 取得APIがエラーが発生する場合
				if (!stockNetRep.commonResponse.isSuccess) {
					rs[0] = stockNetRep.commonResponse.failureReason + ':' + stockNetRep.commonResponse.errorDescription;
					rs[1] = NG;
					return rs;
				} else {

					// ネット室タイプグループ日別在庫状況
					stockNetRep.netRmTypeGroupAndDailyStockStatusList = (stockNetRep.netRmTypeGroupAndDailyStockStatusList == null)
										? new TL_NetStockSearchService.netRmTypeGroupAndDailyStockStatus[0] 
										: stockNetRep.netRmTypeGroupAndDailyStockStatusList;
					// 室タイプグループコード単位の販売数、残室数情報を取得する
					map<string, decimal> stockMap = new map<String, Decimal>();
					for (TL_NetStockSearchService.netRmTypeGroupAndDailyStockStatus stock : stockNetRep.netRmTypeGroupAndDailyStockStatusList) {
						// 調整外ｎ室タイプグループの場合、処理対象外
						if (!rmTypeGroupCdToRmTypeCdMap.containsKey(stock.netRmTypeGroupCode)) continue;
						// 該当室タイプグループの残室数を取得して、今回の変動数を加算して、調整後の残室数を設定する
						Decimal newRemainingCount = CommUtils.nullToZero(stock.remainingCount);
						Decimal newSalesCount = CommUtils.nullToZero(stock.salesCount);
						// 指定日の調整対象室タイプグループの残室数を設定する
						stockMap.put(stock.netRmTypeGroupCode, newRemainingCount+newSalesCount);
					}

					// 部屋タイプー＞タイプグループー＞提供室数
					for (String rmGroupKey : rmTypeGroupCdToRmTypeCdMap.keySet()) {
						// 販売情報が存在する場合
						if (stockMap.containsKey(rmGroupKey)) {
							// 該当部屋タイプの提供室数を設定する
							TypeOfRooms__c rType = new TypeOfRooms__c(
								RoomTypeCode__c = rmTypeGroupCdToRmTypeCdMap.get(rmGroupKey),
								ShopInfoRef__c = shopInfoMap.containsKey(shopCd) ? shopInfoMap.get(shopCd).Id : null
							); 
							String key = getRoomTypeKey(rType);
							if (tlMsgTypeRooms.containsKey(key)) {
								TypeOfRooms__c newType = tlMsgTypeRooms.get(key);
								newType.MaxRooms__c = stockMap.get(rmGroupKey);
							}
						}
					}
				}
			}*//*
			// リアル販売室数
			realRep.rmTypeList = (realRep.rmTypeList == null)
									? new TL_RealRoomTypeMasterSearchService.rmType[0]
									: realRep.rmTypeList;
			for (TL_RealRoomTypeMasterSearchService.rmType rm: realRep.rmTypeList) {
				
				TypeOfRooms__c rType = new TypeOfRooms__c(
					RoomTypeCode__c = rm.rmTypeCode,
					RoomTypeName__c = rm.rmTypeName,
					Name = rm.rmTypeName,
					ShopInfoRef__c = shopInfoMap.containsKey(shopCd) ? shopInfoMap.get(shopCd).Id : null
				);
				String key = getRoomTypeKey(rType);
				if (!tlMsgTypeRooms.containsKey(key)) {tlMsgTypeRooms.put(key, rType);}
				typeRoomCdSet.add(rm.rmTypeCode);
				// 各店舗の部屋タイプコード情報を格納する
				if (!tlMsgTypeCodeMap.containskey(shopCd)) {
					tlMsgTypeCodeMap.put(shopCd, new map<String, TypeOfRooms__c>());
				}
				tlMsgTypeCodeMap.get(shopCd).put(CommUtils.paddingLeftZero(rm.rmTypeCode,100), rType);
			}
			*/
			/*
			// 室タイプー＞販売先室タイプコード
			if (Boolean.valueOf(isSyncMaxRoomNum)) {
				// 販売先室タイプ->室タイプコード情報MAPPING
				map<string, string> realRmTypeCdToRmTypeCdMap = new map<String, String>();
				// 旅行会社室タイプ
				realRep.realAgtRmTypeList = (realRep.realAgtRmTypeList == null) 
										? new TL_RealRoomTypeMasterSearchService.realAgtRmType[0]		
										: realRep.realAgtRmTypeList;
				for (TL_RealRoomTypeMasterSearchService.realAgtRmType agt : realRep.realAgtRmTypeList) {
					// 室タイプコード
					String rmTypeCode = agt.rmTypeCode;
					String key = getRealRmTypeKey(agt.agtCode, agt.realAgtRmTypeCode, agt.frame);
					realRmTypeCdToRmTypeCdMap.put(key, rmTypeCode);
				}
				
				// 在庫情報を取得する
				String ajdustDate = System.now().format('yyyyMMdd');	
				// 指定日、指定タイプグループコードで、在庫照会を行う
				// 旅行会社（リアル）の販売状態(2. 在庫状況照会(ネット販売)API ) 
				TL_RealStockSearchService.extractionCondition realCondition 
					= new TL_RealStockSearchService.extractionCondition();
				realCondition.extractionProcedureCode = '2';					// 「2」:照会期間で検索、
				realCondition.searchDurationFrom = ajdustDate;					// 照会期間FROM
				realCondition.searchDurationTo = ajdustDate;					// 照会期間TO
				
				// 在庫状況照会(ネット販売)API 呼出
				TL_RealStockSearchService.stockSearchForRealResponse rep 
					= tlService.callRealStockSearchService(shopCd, realCondition);
				if (!rep.commonResponse.isSuccess) {
					// エラー処理ログを記録する
					rs[0] = rep.commonResponse.failureReason+':'+rep.commonResponse.errorDescription;
					rs[1] = NG;
 				} else {
	
					// 正常の場合、取得の情報はメモに格納する
					// map<販売先コート+'_'+旅行会社室タイプコート+'_'+枠 +'_'+調整日付
					map<string, decimal> stockMap = new map<String, Decimal>();
					//map<string, RealRmTypeInfo> stockAdjustInfoMap = new map<String, RealRmTypeInfo>();
					// 旅行会社室タイプ
					rep.realAgtRmTypeList = (rep.realAgtRmTypeList == null) 
							? new TL_RealStockSearchService.realAgtRmType[0] 
							: rep.realAgtRmTypeList;
					// 旅行会社室タイフ
					for (TL_RealStockSearchService.realAgtRmType realAgtStock : rep.realAgtRmTypeList) {
						String key = getRealRmTypeKey(realAgtStock.agtCode, realAgtStock.realAgtRmTypeCode, realAgtStock.frame);
						// 処理対象外販売先の室タイプ
						if (!realRmTypeCdToRmTypeCdMap.containsKey(key)) continue;
						// 指定の日別在庫状況
						// 日別在庫状況
						realAgtStock.dailyStockStatusList = (realAgtStock.dailyStockStatusList == null) 
								? new TL_RealStockSearchService.dailyStockStatus[0] 
								: realAgtStock.dailyStockStatusList;
						for (TL_RealStockSearchService.dailyStockStatus dayStatus : realAgtStock.dailyStockStatusList) {
							// 該当室タイプグループの残室数を取得して、今回の変動数を加算して、調整後の残室数を設定する
							Decimal newRemainingCount = CommUtils.nullToZero(dayStatus.remainingCount);
							Decimal newSalesCount = CommUtils.nullToZero(dayStatus.salesCount);
							// 指定日の調整対象室タイプグループの残室数を設定する
							stockMap.put(key, newRemainingCount + newSalesCount);
						}
					}
					

					// 部屋タイプー＞タイプグループー＞提供室数
					for (String realKey : realRmTypeCdToRmTypeCdMap.keySet()) {
						// 販売情報が存在する場合
						if (stockMap.containsKey(realKey)) {
							// 該当部屋タイプの提供室数を設定する
							TypeOfRooms__c rType = new TypeOfRooms__c(
								RoomTypeCode__c = realRmTypeCdToRmTypeCdMap.get(realKey),
								ShopInfoRef__c = shopInfoMap.containsKey(shopCd) ? shopInfoMap.get(shopCd).Id : null
							); 
							String key = getRoomTypeKey(rType);
							if (tlMsgTypeRooms.containsKey(key)) {
								TypeOfRooms__c newType = tlMsgTypeRooms.get(key);
								// 累計加算を行う
								newType.MaxRooms__c = CommUtils.nullToZero(newType.MaxRooms__c) + stockMap.get(realKey);
							}
						}
					}
				}	
			}*//*

		}
		if (Boolean.valueOf(isOnlyConfirm)) {
			String confirMsg = '';
			for (String shopCd : shopCdsLst) {
				// 対象外店舗
				if (!tlMsgTypeCodeMap.containsKey(shopCd)) continue;
				
				if (shopCdsLst.size() > 1) {
					confirMsg += '店舗['+shopCd+']の定義情報:名:部屋タイプコード\n';
					confirMsg += '==================================\n';
				}
				List<String> sortKeyLst = new List<String>();
				map<String, TypeOfRooms__c> shopTypesMap = tlMsgTypeCodeMap.get(shopCd);
				sortKeyLst.addAll(shopTypesMap.keySet());
				sortKeyLst.sort();
				for (String key : sortKeyLst) {
					TypeOfRooms__c rm = shopTypesMap.get(key);
					confirMsg += rm.Name + ' : '+rm.RoomTypeCode__c+'\n';
				}
			}
			rs[0] = confirMsg;
			rs[1] = OK;
			return rs;
		}
		
		// 処理対象情報が存在する場合、処理を行う
		if (!tlMsgTypeRooms.isEmpty()) {
			List<TypeOfRooms__c> nwlst = new List<TypeOfRooms__c>();
			List<TypeOfRooms__c> uplst = new List<TypeOfRooms__c>();
			// 指定の店舗に紐付く部屋タイプリストを取得する
			List<TypeOfRooms__c> existRoomTypes = [select id, name, MaxRooms__c,ShopInfoRef__c,RoomTypeCode__c from TypeOfRooms__c where RoomTypeCode__c in :typeRoomCdSet and ShopInfoRef__r.ShopCode__c in :shopCdsLst for update];
			map<String, TypeOfRooms__c> existRoomTypeMap = new map<String, TypeOfRooms__c>();
			for (TypeOfRooms__c rType : existRoomTypes) {
				String key = getRoomTypeKey(rType);
				existRoomTypeMap.put(key, rType);
			}
			for (String key : tlMsgTypeRooms.keySet()){
				if (existRoomTypeMap.containsKey(key)) {
					// 提供室を更新しますか？何も処理なし
					// 元の提供室数はNULLの場合、最新の提供室数を更新を行う
					TypeOfRooms__c od = existRoomTypeMap.get(key);
					TypeOfRooms__c nw = tlMsgTypeRooms.get(key);
					if (CommUtils.nullToZero(od.MaxRooms__c) == 0 && CommUtils.nullToZero(nw.MaxRooms__c) > 0) {
						od.MaxRooms__c = nw.MaxRooms__c;
						uplst.add(od);
					}
				} else {
					nwlst.add(tlMsgTypeRooms.get(key));
				}
			}
			try {
				if (!nwlst.isEmpty()) insert nwLst;
				if (!uplst.isEmpty()) update uplst;
			} catch (Exception e) {
				rs[0] = '[ERROR]' + e.getMessage();
				rs[1] = NG;
				return rs;
			}
		}

		return rs;
	}
	private static String getRealRmTypeKey(String agtCode, String rmTypeCode, String frame) {
		return agtCode + '_' + rmTypeCode + '_' + frame;
	}

	private static String getRoomTypeKey(TypeOfRooms__c typeRoom) {
		return CommUtils.nullToBlank(typeRoom.ShopInfoRef__c) + '_' + typeRoom.RoomTypeCode__c;
	}*/
	private static String getPlanKey(Plan__c plan) {
		return plan.PackageCode__c + '_' + CommUtils.nullToBlank(plan.ShopInfoRef__c);
	}
	// 取込の店舗コードリストを設定する
	private static List<String> getImportShopCodes(String branchShopCd) {
		// 指定の店舗コードはNULLの場合、店舗情報マスタから店舗コードを取得する、多店舗じゃない場合、単店舗情報を取得する
		List<String> shopCdsLst = new List<String>();
		if (CommUtils.isBLank(branchShopCd)) {
			map<String, ShopInformation__c> shopInfoMap = ShopInfoUtil.getShopInfoMap();
			for (ShopInformation__c shop : shopInfoMap.values()) {
				shopCdsLst.add(shop.ShopCode__c);
			}
		} else {
			shopCdsLst.add(branchShopCd);
		}
		// 単店舗の場合
		if (shopCdsLst.isEmpty()) shopCdsLst.add('');
		// 50以内の店舗情報制御が必要
		if (shopCdsLst.size() > 50) {
			//一括取込できる店舗数を超えました。
			throw new CommException(Label.MSG_038_0022);
		}
		return shopCdsLst;
	}
}