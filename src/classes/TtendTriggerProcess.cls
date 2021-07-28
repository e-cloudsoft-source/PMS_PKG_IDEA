public with sharing class TtendTriggerProcess {
	// 2019/10/30 明細入力時に自動で反映 WGCH BEGIN
	public void syncAccountMstToTtendItem(TTend__c[] newList, TTend__c[] oldList, CommConst.TriggerMethod act){
		// 新規作成の見積もり明細情報を自動設定を行う
		for (Integer i = 0; i < newList.size(); i++) {
			TTend__c item = newList[i];
			// 会計GP名
			item.AccMstGPName__c = item.AccMstGPNameCal__c;
			// 会計DP名
			item.AccMstDPName__c = item.AccMstDPNameCal__c;
			// 会計OP名
			item.AccMstOPName__c = item.AccMstOPNameCal__c;
			// 部屋タイプ名
			item.TypeOfRoomName__c = item.TypeOfRoomNameCal__c;
			// お部屋名
			item.RoomName__c = item.RoomNameCal__c;
			// 予約タイプ
			item.ReservedType__c = item.ReservedTypeCal__c;
			// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz BEGIN
			// 新規作業場合
			if (act == CommConst.TriggerMethod.IsInsert ) {
				if (item.useDate__c == null && item.UseDateCal__c != null) 
					item.useDate__c = item.UseDateCal__c;
			}
			// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz END
		}
	}
	// 2019/10/30 明細入力時に自動で反映 WGCH END
    // 2017/07/13 POS単位現金合せ管理により、Triggerから自動現金へ連携処理を廃止する BEGIN
    
    // 会計支払明細変更により、関連の金額項目を自動同期処理を行う
    public void syncAccInfoToLead(TTend__c[] newList, TTend__c[] oldList, CommConst.TriggerMethod act){
    	CommLogicProcess logic = new CommLogicProcess();
    	list<Rollupparameter__c> rollupParams = logic.getRollupParameter(CommLogicProcess.ROLLUP_PAR.TTEND);
    	// パラメータを未定義　OR　定義しているパラメータは実施しない場合、次の処理を行わない
    	if (!(rollupParams.isEmpty() || rollupParams[0].InActive__c != true)) return;    	    	
    	// 明細情報から現金合せオブジェクトへ連携処理を行う	 
    	// 関連の売上IDリストを格納する
    	set<Id> rsvIdsSet = new set<Id>();
    	set<String> shopCdSet = new set<String>(); 
    	set<String> filterKeySet = new seT<String>();
    	// 新規作業場合
    	if (act == CommConst.TriggerMethod.IsInsert ) {
    		for (TTend__c ttend : newList) {
    			if (ttend.Field2__c != CommConst.MEDIA_TYPE_CD_01) continue;
    			rsvIdsSet.add(ttend.RelAccount__c);
    			shopCdSet.add(CommUtils.nullToBlank(ttend.ShopCodeCal__c));
    			filterKeySet.add(getFilterKey(ttend.RelAccount__c, ttend.ShopCodeCal__c));
    		}
    	// 更新作業場合
    	} else if (act == CommConst.TriggerMethod.IsUpdate ) {
    		Integer maxLen = newList.size();
    		//for (TTend__c ttend : newList) {
    		for (Integer i=0; i <maxLen; i++ ) {
    			TTend__c nw = newList[i];
    			TTend__c od = oldList[i];
    			// 変更元の変更先両方とも現金じゃない場合、処理対象外
    			if (nw.Field2__c != CommConst.MEDIA_TYPE_CD_01 && od.Field2__c != CommConst.MEDIA_TYPE_CD_01) continue;
    			// 支払種別変更なし　OR　支払コードは現金　＆＆　金額変更の場合
    			if (nw.RelAccount__c == od.RelAccount__c && nw.Field2__c == od.Field2__c && nw.Field28__c == od.Field28__c && nw.Field29__c == od.Field29__c) continue;
     			// 会計明細の売上日を変更される場合、関連の現金合せを同時連動を行う
     			if (nw.RelAccount__c != od.RelAccount__c) {
     				if (nw.Field2__c == CommConst.MEDIA_TYPE_CD_01) {
		     			rsvIdsSet.add(nw.RelAccount__c);
		    			shopCdSet.add(CommUtils.nullToBlank(nw.ShopCodeCal__c));
		    			filterKeySet.add(getFilterKey(nw.RelAccount__c, nw.ShopCodeCal__c));
     				}
     				if (od.Field2__c == CommConst.MEDIA_TYPE_CD_01) {
		     			rsvIdsSet.add(od.RelAccount__c);
		    			shopCdSet.add(CommUtils.nullToBlank(od.ShopCodeCal__c));
		    			filterKeySet.add(getFilterKey(od.RelAccount__c, od.ShopCodeCal__c));
     				}
     			} else {
	     			rsvIdsSet.add(nw.RelAccount__c);
	    			shopCdSet.add(CommUtils.nullToBlank(nw.ShopCodeCal__c));
	    			filterKeySet.add(getFilterKey(nw.RelAccount__c, nw.ShopCodeCal__c));
     			}
    		}
    	// 削除作業場合
    	} else if (act == CommConst.TriggerMethod.IsDelete ) {
    		for (TTend__c ttend : oldList) {
    			if (ttend.Field2__c != CommConst.MEDIA_TYPE_CD_01) continue;
    			rsvIdsSet.add(ttend.RelAccount__c);
    			shopCdSet.add(CommUtils.nullToBlank(ttend.ShopCodeCal__c));
    			filterKeySet.add(getFilterKey(ttend.RelAccount__c, ttend.ShopCodeCal__c));
    		}
    	}
//System.debug(loggingLevel.info, 'rsvIdsSet='+rsvIdsSet);
//System.debug(loggingLevel.info, 'filterKeySet='+filterKeySet);
    	if (rsvIdsSet.isEmpty()) return;
    	// 指定の売上日と店舗別の集計を行う
		// 指定の売上IDと店舗コードで、支払現金情報を取得する
		// 指定の現金情報を取得する
    	String cashCode = CommConst.MEDIA_TYPE_CD_01;
    	// 2016/06/10 現金合せ「売上金額」集計ロジック変更対応 BEGIN
//System.debug(loggingLevel.info, 'shopCdSet='+shopCdSet);
    	// 会計単位でグループする
    	String ttendQuery = 'select sum(Field28__c) reciveAmount, sum(Field29__c) realAmount, '+
// 2018/02/12 POSNO単位の現金合せ集計対応 BEGIN
    						'POSNo__c posno, '+
// 2018/02/12 POSNO単位の現金合せ集計対応 END
    						'RelAccount__r.Name rsvNm, RelAccount__c rsvId, Field1__r.ShopCode__c shopCode '+
    						'from TTend__c where RelAccount__c = :rsvIdsSet And OutSideAccount__c = 1 And Field2__c = :cashCode And (Field28__c <> 0 or Field29__c <> 0 ) ';
    	if (!shopCdSet.isEmpty()) ttendQuery += ' And Field1__r.ShopCode__c = :shopCdSet ';
// 2018/02/12 POSNO単位の現金合せ集計対応 BEGIN
        ttendQuery += ' Group by RelAccount__r.Name, RelAccount__c, Field1__r.ShopCode__c,POSNo__c ';
// 2018/02/12 POSNO単位の現金合せ集計対応 END
        
		List<AggregateResult> rsAvgs = DataBase.query(ttendQuery);
		// 2018/02/12 POSNO単位の現金合せ集計対応 BEGIN
		// map<売上日_店舗別, map<posno, 売上金額>>
		map<string,map<string,decimal>> cashRollupMap = new map<string, map<string,decimal>>();
		// 2018/02/12 POSNO単位の現金合せ集計対応 END
		if (!rsAvgs.isEmpty()) {
			// 売上の現金情報を取得する
			for (AggregateResult rsAvg : rsAvgs) {
				String rsvId = CommUtils.nullToBlank(rsAvg.get('rsvId'));
				String shopCd = CommUtils.nullToBlank(rsAvg.get('shopCode'));
				String filterKey = getFilterKey(rsvId, shopCd);
				// 更新対象外の現金合せ対象
				if (!filterKeySet.contains(filterKey)) continue;
				// 2018/02/12 POSNO単位の現金合せ集計対応 BEGIN
				//Boolean newLayout = (Boolean) rsAvg.get('IsNewLayout');
				// 2018/02/12 POSNO単位の現金合せ集計対応 END
				//String rsvNm = CommUtils.nullToBlank(rsAvg.get('rsvNm'));
				//String upsertKey = rsvNm + '_' + shopCd;
				Decimal salesAmount = 0;
				//if (newLayout) {
				//	salesAmount= CommUtils.nullToZero(rsAvg.get('reciveAmount'));
				//} else {
				salesAmount= CommUtils.nullToZero(rsAvg.get('realAmount'));
				//}
				// 2018/02/12 POSNO単位の現金合せ集計対応 BEGIN
				String posNo = CommUtils.nullToBlank(rsAvg.get('posno'));
				if (!cashRollupMap.containsKey(filterKey)) cashRollupMap.put(filterKey, new map<string,decimal>());
				map<string,decimal> cashRollupShopMap = cashRollupMap.get(filterKey);
				if (!cashRollupShopMap.containsKey(posNo)) cashRollupShopMap.put(posNo, salesAmount);
				else cashRollupShopMap.put(posNo, (cashRollupShopMap.get(posNo) + salesAmount));
				//if (!cashRollupMap.containsKey(filterKey)) cashRollupMap.put(filterKey, salesAmount);
				//else cashRollupMap.put(filterKey, (cashRollupMap.get(filterKey) + salesAmount));
				// 2018/02/12 POSNO単位の現金合せ集計対応 END
			}
		}
//System.debug(LoggingLevel.info, 'cashRollupMap='+cashRollupMap);
		//if (!cashRollupMap.isEmpty()) {
		//Set<String> keySet = cashRollupMap.keySet();
		List<CashVerification__c> updLst = new List<CashVerification__c>();
		// 2018/02/12 POSNO単位の現金合せ集計対応 BEGIN
		String queryStr = 'select POSNo__c, RsvAccountRef__c,ShopInfoRef__r.ShopCode__c,CashSales__c,SearchKey__c,AutoUpdateFlg__c,CaseDeposit__c,CasePayment__c,ReserveFund__c from CashVerification__c where RsvAccountRef__c = :rsvIdsSet ';
		// 2018/02/12 POSNO単位の現金合せ集計対応 END
		if (!shopCdSet.isEmpty()) queryStr += ' And ShopInfoRef__r.ShopCode__c = :shopCdSet '; 
		queryStr += ' for update ';
		list<CashVerification__c> sobjs = DataBase.query(queryStr);
		// 2018/02/12 POSNO単位の現金合せ集計対応 BEGIN
		// 店舗別売上金額情報を格納用
		map<string, decimal> shopCashMap = new map<string, decimal>();
		for (String key : cashRollupMap.keyset()) {
		    Decimal shopCashAmount = 0;
		    map<string, decimal> cashRollupShopMap = cashRollupMap.get(key);
		    for (String subkey : cashRollupShopMap.keySet()) {
		        shopCashAmount += cashRollupShopMap.get(subkey);
		    }
		    // 該当店舗全て売上金額情報を格納する
		    shopCashMap.put(key, shopCashAmount);
		}
		// 2018/02/12 POSNO単位の現金合せ集計対応 END
		for (CashVerification__c s : sobjs) {
			//String key = CommUtils.nullToBlank(s.SearchKey__c);
			String key = getFilterKey(s.RsvAccountRef__c, s.ShopInfoRef__r.ShopCode__c);
			// 2018/02/12 POSNO単位の現金合せ集計対応 BEGIN
			String posNo = CommUtils.nullToBlank(s.POSNo__c);
			Decimal orgCashSales = CommUtils.nullToZero(s.CashSales__c);
			// 2018/02/12 POSNO単位の現金合せ集計対応 END
			if (cashRollupMap.containsKey(key)) {
			    // 2018/02/12 POSNO単位の現金合せ集計対応 BEGIN
			    // 該当店舗の全て端末の売上金額情報
			    map<string,decimal> cashRollupShopMap = cashRollupMap.get(key);
			    // POSNOは空白の場合、店舗別の売上金額値を設定する
			    if (CommUtils.isBlank(posNo)) {
			        Decimal shopCashAmount = shopCashMap.get(key);
			        // 金額変更あり場合
			        if (shopCashAmount != orgCashSales) {
			            processCashVerification(s, shopCashAmount);
			            updLst.add(s);
			        }
			    }
			    // POSNO単位[その他]場合
			    else {
			        // その場合、DefaultのPOSNOでその他に集計する
			        if (posNo == '$$999$$') posNo = CommUtils.getPosNoByComdefine();
			        if (cashRollupShopMap.containsKey(posNo)) {
			            Decimal posCashAmount = cashRollupShopMap.get(posNo);
			            // 金額変更あり場合
			            if (posCashAmount != orgCashSales) {
			                processCashVerification(s, posCashAmount);
			                updLst.add(s);
			            }
			        } else {
			            // 金額クリアする
			            processCashVerification(s, 0);
			            updLst.add(s);
			        }
			    }
			    // 2018/02/12 POSNO単位の現金合せ集計対応 END
			} else {
				// 該当キーが非存在　かつ　該当キーは処理対象の場合、該当金額は０円に更新
				if (filterKeySet.contains(key)) {
					//s.CashSales__c = 0;
					//s.AutoUpdateFlg__c = !s.AutoUpdateFlg__c;
					processCashVerification(s, 0);
					updLst.add(s);
				}
			}
		}
		if (!updLst.isEmpty()) update updLst;
    }
    private String getFilterKey(String rsvId, String shopCode) {
    	return CommUtils.nullToBlank(rsvId) + '_' + CommUtils.nullToBlank(shopCode);
    }
    // 2018/02/12 POSNO単位の現金合せ集計対応 BEGIN
    private String getPosNoFilterKey(String key, String posno) {
        return CommUtils.nullToBlank(key) + '_' + 
            (CommUtils.isBlank(posNo) ? CommUtils.getPosNoByComdefine() : (posno));
    }
    // 2018/02/12 POSNO単位の現金合せ集計対応 END
    private void processCashVerification(CashVerification__c s, Decimal cashSales) {
    	// 売上現金項目金額の更新
    	s.CashSales__c = cashSales;
    	// 現金有高[論理]
    	s.CashAmountLogic__c = CommUtils.nullToZero(s.ReserveFund__c) 		// 準備金
    							+ cashSales 								// 売上現金
    							+ CommUtils.nullToZero(s.CaseDeposit__c) 	// 現金入金
    							- CommUtils.nullToZero(s.CasePayment__c);	// 現金出金
    }
    // 2017/07/13 POS単位現金合せ管理により、Triggerから自動現金へ連携処理を廃止する END
    // 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH BEGIN
	public void compareSalesdayCalInfo(List<TTend__c> nw, List<TTend__c> od, CommConst.TriggerMethod act) {
		// 获取管理员信息
		CommLogicProcess.AccountAdminInfo accAdminItem = CommLogicProcess.getAccountAdminInfo();
		// 获取锁定日期设定
		CommLogicProcess.ComDay comDayItem = new CommLogicProcess.ComDay();
		if(comDayItem.setComDay()){
			// 該当会計明細の関連の会計の予約データ存在　＆＆　部屋情報を設定されている場合、会計明細に反映を行う
			Set<Id> accAcountIdSet = new Set<Id>();
			// 新数据
			List<TTend__c> nwLst = null;
			// 旧数据
			List<TTend__c> odLst = null;
			// 新規場合
			if(act == CommConst.TriggerMethod.IsInsert){
				nwLst = nw;
				odLst = od;
			}
			// 更新作業場合
			if(act == CommConst.TriggerMethod.IsUpdate){
				nwLst = nw;
				odLst = od;
			}
			// 削除作業場合
			else if (act == CommConst.TriggerMethod.IsDelete ) {
				nwLst = od;
				odLst = od;
			}
			for (TTend__c ttend : nwLst) {
				accAcountIdSet.add(ttend.Field1__c);
			}
			// 会計情報を取得する
			List<AccountAcount__c> accLst = [select id, SalesdayCal__c, ShopCode__c from AccountAcount__c where id in :accAcountIdSet];
			// 会计对应的Lock的FLG
			Map<String, Boolean> accErrorMap = new Map<String, Boolean>();
			// 获取当前会计
			for(AccountAcount__c acc : accLst){
				// 设定Error成功跳出不可以变更PDF
				accErrorMap.put(acc.Id, CommLogicProcess.isAccLockFlg(acc, accAdminItem, comDayItem));
			}
			// 有效场合check
			for (Integer i = 0; i < nwLst.size(); i++){
				TTend__c ttend = nwLst[i];
				// 设定Error成功跳出不可以变更PDF
				if(accErrorMap.containsKey(ttend.Field1__c) && accErrorMap.get(ttend.Field1__c)){
					ttend.addError(Label.MSG_006_0459);
					continue;
				}
			}
		}
	}
	// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH END
}