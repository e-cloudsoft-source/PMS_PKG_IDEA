global with sharing class TA_MasterSyncService {
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
		TA_ServiceCtrl taService = new TA_ServiceCtrl();
		/*
		Map<String, Account> accMap = new Map<String, Account>();
		
		// 既存のAGT情報を取得する
		String salesOfficeCompanyType =  'ネット';
		String contractStatus =  '有効';
		String accountType =  CommConst.ACCOUNT_TYPE_TRAVEL;
		List<Account> accList = [select Id, Name, SalesOfficeCompanyCodeTLAPI__c from Account where SalesOfficeCompanyType__c = :salesOfficeCompanyType and ContractStatus__c = :contractStatus and AccountType__c = :accountType];
		Map<String, String> agtCodeMap = new Map<String, String>();
		for (Account s:accList ) {
			agtCodeMap.put(s.SalesOfficeCompanyCodeTLAPI__c, s.Id);
		}*/
		// 各店舗のプラン定義情報を取得する
		for (String shopCd : shopCdsLst) {
			// 契約していない店舗情報は取込対象外になる
			if (!TA_ServiceConfigHelp.isContractShop(shopCd)) continue;
			// APIを呼出
			TA_PlanInfoItem netRep = taService.callNetPlanMasterSearchService(shopCd);
			if (!netRep.commonResponse.isSuccess) {
				return netRep.commonResponse.failureReason + ':' + netRep.commonResponse.errorDescription;
			}
			for (TA_PlanInfoItem.PlanInfo rm: netRep.planList) {
				Plan__c nPlan = new Plan__c(
					PackageCode__c = rm.planCode,
					Name = rm.planName,
					//client__c = agtCodeMap.get(rm.agtCode),
					ShopInfoRef__c = shopInfoMap.containsKey(shopCd) ? shopInfoMap.get(shopCd).Id : null,
					Price__c = 0,
					JmstRef__c = taxRateInf.Id
				);
				String nkey = getPlanKey(nPlan);
				tlMsgTypeRooms.put(nkey, nPlan);
				planShopSet.add(shopCd);
				pkgCdSet.add(rm.planCode);
			}
			/*
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
			}*/
		}
System.debug(loggingLevel.INFO, 'tlMsgTypeRooms:=' + tlMsgTypeRooms);
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
		
		return '取込正常に完了しました。';
	}  
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
			throw new CommException('一括取込できる店舗数を超えました。');
		}
		return shopCdsLst;
	}
}