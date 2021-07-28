/**
* 見積明細のトリガー処理詳細対応
*/
public with sharing class QuotaItemTriggerProcess {
    
    // 宿泊税金額自動計算処理を行う
    public void calSpecialTaxProc(List<QuotaItem__c> nwLst, List<QuotaItem__c> odLst, CommConst.TriggerMethod act) {
    	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
    	// 2019/11/11 BUGFIEX修正 WGCH BEGIN
    	for (Integer i = 0; i < nwLst.size(); i++) {
    		QuotaItem__c nw = nwLst[i];
    		nw.TankanonetaxNew__c = 0;
    	}
    	// 2019/11/11 BUGFIEX修正 WGCH END
    	if(CommConst.REDUCED_TAXRATE_FLG){
    		// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
			Boolean planBrkToHeaderCalFlg = CommConst.PLAN_BRKTOHEADER_CAL_FLG;
			// 2019/10/02 PlanHeader算法切换对应 WGCH END
    		// トリガーは更新前の場合
			map<string,CommLogicProcess.HotelTaxDefineInfo> hotelTaxDefMap = CommLogicProcess.getHotelTaxDefInstance();
    		for (Integer i = 0; i < nwLst.size(); i++) {
    			QuotaItem__c nw = nwLst[i];
    			// 2019/11/11 BUGFIEX修正 WGCH BEGIN
    			if(nw.ActionType__c != CommConst.PROD_ACTION_TYPE_PL){
    				nw.PlanBrkInfo__c = '';
    				continue;
    			}
    			// 2019/11/11 BUGFIEX修正 WGCH END
    			if(!CommUtils.isBlank(nw.PlanBrkInfo__c)){
    				List<List<String>> brkInfoAllLst = CommLogicProcess.getPlanBrkInfoLst(CommUtils.nullToBlank(nw.PlanBrkInfo__c));
    				nw.TankanonetaxNew__c = 0;
    				nw.UnitPrice__c = 0;
    				// 2019/11/11 BUGFIEX修正 WGCH BEGIN
    				// 写重复了
    				// nw.TankanonetaxNew__c = 0;
    				// 2019/11/11 BUGFIEX修正 WGCH END
    				nw.SpTotal__c = 0;
    				nw.SpecialTax__c = 0;
    				nw.PlanBrkInfo__c = '';
    				// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
					if(planBrkToHeaderCalFlg){
	    				for(List<String> brkInfoLst : brkInfoAllLst){
	    					if(brkInfoLst.size() < 8) continue;
	    					// brkInfoLst下标含义:[0]=>单价,[1]=>消费税,[2]=>サービ料,[3]=>数量,[4]=>特别税,[5]=>单价定义区分,[6]=>商品ID,[7]=>商品处理种别
	    					Decimal unitPrice = CommUtils.nullToZero(brkInfoLst[0]); // 单价
	    					Decimal tax = CommUtils.nullToZero(brkInfoLst[1]); // 消费税
	    					Decimal serviceRate = CommUtils.nullToZero(brkInfoLst[2]); // サービ料
	    					Decimal nums = CommUtils.nullToZero(nw.Amount__c); // 数量
	    					Decimal specialTax = CommUtils.nullToZero(brkInfoLst[4]); // 特别税
	    					String unitPriceKbn = CommUtils.nullToBlank(brkInfoLst[5]); // 单价定义区分
	    					if(CommUtils.isBlank(unitPriceKbn)) unitPriceKbn = CommUtils.nullToBlank(nw.UnitPriceDefKb__c);
	    					String productId = CommUtils.nullToBlank(brkInfoLst[6]); // 商品ID
	    					String actionType = CommUtils.nullToBlank(brkInfoLst[7]); // 商品处理种别
	    					String spcd = CommUtils.nullToBlank(nw.ShopCode__c);
	    					CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(unitPriceKbn));
	    					CommLogicProcess.HotelTaxInfo hotelTaxItem = CommLogicProcess.getHotelTaxInfo(spcd, CommUtils.nullToBlank(actionType), CommUtils.nullToZero(unitPrice), CommUtils.nullToZero(nums), tax, serviceRate, priceInfo, hotelTaxDefMap);
	    					priceInfo = hotelTaxItem.priceInfo;
	    					nw.PlanBrkInfo__c = CommUtils.nullToBlank(nw.PlanBrkInfo__c) +  // 原有累积的明细
	    										CommLogicProcess.getPlanBrkInfo(
	    											CommUtils.nullToBlank(unitPrice), // 単価
	    											CommUtils.nullToBlank(tax), // 消費税
	    											CommUtils.nullToBlank(serviceRate), // サービス料
	    											CommUtils.nullToBlank(nums), // 数量
	    											CommUtils.nullToBlank(hotelTaxItem.autoSetFlg ? hotelTaxItem.newNumSepcTaxSum : 0), // 特別税
	    											CommUtils.nullToBlank(unitPriceKbn), // 会計商品単価定義区分
	    											CommUtils.nullToBlank(productId), // 会計商品Id
	    											CommUtils.nullToBlank(actionType) // 商品処理種別
	    										);
	    					nw.UnitPrice__c = CommUtils.nullToZero(nw.UnitPrice__c) + CommUtils.nullToZero(unitPrice);
							nw.TankanonetaxNew__c = CommUtils.nullToZero(nw.TankanonetaxNew__c) + priceInfo.unitPriceIncServiceExcTax;
							nw.SpTotal__c = CommUtils.nullToZero(nw.SpTotal__c) + priceInfo.priceIncTax;
							if(hotelTaxItem.autoSetFlg){
								nw.SpecialTax__c = CommUtils.nullToZero(nw.SpecialTax__c) + hotelTaxItem.newNumSepcTaxSum;
								nw.SpTotal__c = CommUtils.nullToZero(nw.SpTotal__c) + hotelTaxItem.newNumSepcTaxSum;
							}
	    				}
	    			} else {
	    				Decimal hasTaxUnitPrice = 0;
						Decimal noTaxUnitPrice = 0;
						for(List<String> brkInfoLst : brkInfoAllLst){
	    					if(brkInfoLst.size() < 8) continue;
	    					// brkInfoLst下标含义:[0]=>单价,[1]=>消费税,[2]=>サービ料,[3]=>数量,[4]=>特别税,[5]=>单价定义区分,[6]=>商品ID,[7]=>商品处理种别
	    					Decimal unitPrice = CommUtils.nullToZero(brkInfoLst[0]); // 单价
	    					Decimal tax = CommUtils.nullToZero(brkInfoLst[1]); // 消费税
	    					Decimal serviceRate = CommUtils.nullToZero(brkInfoLst[2]); // サービ料
	    					Decimal nums = CommUtils.nullToZero(nw.Amount__c); // 数量
	    					Decimal specialTax = CommUtils.nullToZero(brkInfoLst[4]); // 特别税
	    					String unitPriceKbn = CommUtils.nullToBlank(brkInfoLst[5]); // 单价定义区分
	    					if(CommUtils.isBlank(unitPriceKbn)) unitPriceKbn = CommUtils.nullToBlank(nw.UnitPriceDefKb__c);
	    					String productId = CommUtils.nullToBlank(brkInfoLst[6]); // 商品ID
	    					String actionType = CommUtils.nullToBlank(brkInfoLst[7]); // 商品处理种别
	    					String spcd = CommUtils.nullToBlank(nw.ShopCode__c);
	    					if(tax > 0) hasTaxUnitPrice += CommUtils.nullToZero(unitPrice);
							else if(tax == 0) noTaxUnitPrice += CommUtils.nullToZero(unitPrice);
	    					
	    					CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(unitPriceKbn));
	    					CommLogicProcess.HotelTaxInfo hotelTaxItem = CommLogicProcess.getHotelTaxInfo(spcd, CommUtils.nullToBlank(actionType), CommUtils.nullToZero(unitPrice), CommUtils.nullToZero(nums), (tax > 0 ? nw.TaxRate__c : 0), nw.ServiceRate__c, priceInfo, hotelTaxDefMap);
	    					priceInfo = hotelTaxItem.priceInfo;
	    					nw.PlanBrkInfo__c = CommUtils.nullToBlank(nw.PlanBrkInfo__c) +  // 原有累积的明细
	    										CommLogicProcess.getPlanBrkInfo(
	    											CommUtils.nullToBlank(unitPrice), // 単価
	    											CommUtils.nullToBlank(tax), // 消費税
	    											CommUtils.nullToBlank(serviceRate), // サービス料
	    											CommUtils.nullToBlank(nums), // 数量
	    											CommUtils.nullToBlank(hotelTaxItem.autoSetFlg ? hotelTaxItem.newNumSepcTaxSum : 0), // 特別税
	    											CommUtils.nullToBlank(unitPriceKbn), // 会計商品単価定義区分
	    											CommUtils.nullToBlank(productId), // 会計商品Id
	    											CommUtils.nullToBlank(actionType) // 商品処理種別
	    										);
							if(hotelTaxItem.autoSetFlg){
								nw.SpecialTax__c = CommUtils.nullToZero(nw.SpecialTax__c) + hotelTaxItem.newNumSepcTaxSum;
							}
	    				}
						CommUtils.ProductInfo planPriceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(nw.UnitPriceDefKbCal__c));
						// 当前行含税单价计算处理
						planPriceInfo.process(hasTaxUnitPrice, CommUtils.nullToZero(nw.Amount__c), CommUtils.nullToZero(nw.TaxRate__c), CommUtils.nullToZero(nw.ServiceRate__c));
						nw.UnitPrice__c = CommUtils.nullToZero(hasTaxUnitPrice);
						nw.TankanonetaxNew__c = planPriceInfo.unitPriceIncServiceExcTax;
						nw.SpTotal__c = planPriceInfo.priceIncTax;
						// 当前行不含税单价计算处理
						planPriceInfo.process(noTaxUnitPrice, CommUtils.nullToZero(nw.Amount__c), 0, CommUtils.nullToZero(nw.ServiceRate__c));
						nw.UnitPrice__c = CommUtils.nullToZero(nw.UnitPrice__c) + CommUtils.nullToZero(noTaxUnitPrice);
						nw.TankanonetaxNew__c = CommUtils.nullToZero(nw.TankanonetaxNew__c) + planPriceInfo.unitPriceIncServiceExcTax;
						nw.SpTotal__c = CommUtils.nullToZero(nw.SpTotal__c) + planPriceInfo.priceIncTax + CommUtils.nullToZero(nw.SpecialTax__c);
	    			}
    			}
    			// 2019/10/02 PlanHeader算法切换对应 WGCH END
    		}
    		return;
    	}
    	// 2019/07/30 軽減税率機能対応 WGCH END
    	// トリガーは更新前の場合
		map<string,CommLogicProcess.HotelTaxDefineInfo> hotelTaxDefMap = CommLogicProcess.getHotelTaxDefInstance();
		if (hotelTaxDefMap.isEmpty()) return;
        // 宿泊税対象リスト
        List<QuotaItem__c> roomRateCalLst = new List<QuotaItem__c>();
        // map<プランの会計商品ID,list<IDNEX>>
        map<Id, List<Integer>> noSyncRoomPriceMap = new map<Id, List<Integer>>();
        //map<INDEX,会計商品プランID>
        map<Integer, Id> noSyncIdxToProdMap = new map<Integer, Id>();
        // map<INDEX, 明細の商品IDと金額>
        map<Integer, List<ProdInfo>> exSyncRoomMap = new map<Integer, List<ProdInfo>>();
        set<Id> exSyncProdIdSet = new set<Id>();
        // プランに含めている会計商品IDを格納する
        Set<Id> planSyncProdIdSet = new Set<Id>();
        // プランのHeader情報リスト
        List<QuotaItem__c> planHeaderLst = new List<QuotaItem__c>();
        for (Integer i = 0; i < nwLst.size(); i++) {
        	QuotaItem__c nw =  nwLst[i];
        	String spcd = CommUtils.nullToBlank(nw.ShopCodeCal__c);
        	// 宿泊税計算対象外の場合、処理SKIP
        	if (!hotelTaxDefMap.containsKey(spcd)) continue;
        	
        	QuotaItem__c od = null;
        	if (odLst != null) od =  odLst[i];
            // 該当明細は室料の場合、該当室料の宿泊税計算を行う
            if (RackRateUtils.isRoomRateProduct(nw.ActionType__c)) {
            	roomRateCalLst.add(nw);
            }
            // プランの場合、プランニア用をクリアする
            if (nw.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) {
            	//planHeaderLst.add(nw);
            	// SYNC定義情報が非存在する場合、既存の宿泊税が存在する場合、該当宿泊税/変更前の数量*変更後の数量で宿泊税を設定する
        		if (!CommUtils.isBlank(nw.PlanDetailSyncInfo__c)) {
        			// １明細の商品IDと数量格納する
        			String planSynInfo = nw.PlanDetailSyncInfo__c.substringBeforeLast(';');
        			String[] prodInfoLst = planSynInfo.split(';');
        			for (String prodInfo : prodInfoLst) {
        				String[] prodItem = prodInfo.split(':');
        				Id prodId = null;
        				Decimal price = null;
        				if (prodItem.size() > 1 ) price = CommUtils.nullToZero(prodItem[1]);
        				if (prodItem.size() > 2 ) prodId = CommUtils.nullToBlank(prodItem[2]);
        				if (!CommUtils.isBlank(prodId) && price != null) {
        					if (!exSyncRoomMap.containsKey(i)) exSyncRoomMap.put(i, new List<ProdInfo>());
        					exSyncRoomMap.get(i).add(new ProdInfo(prodId, price));
        					// 室料商品検索用
        					exSyncProdIdSet.add(prodId);
        				}
        			}
        		}
        		// SYNC定義情報が非存在する場合、既存の宿泊税が存在する場合、プランBreakDownの室料により、宿泊税計算を行う
        		else {
        			// 該当商品により、プランBREAKDOWN情報を取得する
        			Id prodId = nw.refAccountMaster__c;
        			if (!noSyncRoomPriceMap.containsKey(prodId)) noSyncRoomPriceMap.put(prodId, new List<Integer>());
        			noSyncRoomPriceMap.get(prodId).add(i);
        			noSyncIdxToProdMap.put(i, prodId);
        		}
            }
        }
// System.debug(loggingLevel.info, 'roomRateCalLst='+roomRateCalLst);
// System.debug(loggingLevel.info, 'noSyncRoomPriceMap='+noSyncRoomPriceMap);
// System.debug(loggingLevel.info, 'exSyncRoomMap='+exSyncRoomMap);
		if (roomRateCalLst.isEmpty() && noSyncRoomPriceMap.isEmpty() && exSyncRoomMap.isEmpty()) return;
		// 明細の宿泊税を計算する
		if (!roomRateCalLst.isEmpty()) {
			// 宿泊税計算を行う
			for (QuotaItem__c nw: roomRateCalLst) {
				String spcd = CommUtils.nullToBlank(nw.ShopCodeCal__c);
				// 該当明細の店舗に対して、宿泊情報を定義が存在する場合
				if (hotelTaxDefMap.containsKey(spcd)) {
					// 2018/12/15 BUG修正对应 WGCH BEGIN
					// nw.SpecialTax__c = CommLogicProcess.getHotelTax(nw.Tankanonetax__c,hotelTaxDefMap.get(spcd)) * CommUtils.nullToZero(nw.Amount__c);
					CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(nw.UnitPriceDefKbCal__c));
					priceInfo.process(CommUtils.nullToZero(nw.UnitPrice__c), CommUtils.nullToZero(nw.Amount__c), CommUtils.nullToZero(nw.TaxRate__c), CommUtils.nullToZero(nw.ServiceRate__c));
					nw.SpecialTax__c = CommLogicProcess.getHotelTax(priceInfo.unitPriceIncServiceExcTax,hotelTaxDefMap.get(spcd)) * CommUtils.nullToZero(nw.Amount__c);
					// 2018/12/15 BUG修正对应 WGCH END
				}
			}
		}
		// SYNC未設定が存在する場合
		if (!noSyncRoomPriceMap.isEmpty()) {
			// 該当IDにより、会計商品プランのBREAKDOWN室料明細をが探す
			Map<Id, List<ProductItemUtils.PlanDetail>> retMap = ProductItemUtils.getRoomPriceByProdIds(noSyncRoomPriceMap.keyset());
			for (Integer i = 0; i < nwLst.size(); i++) {
				// 対象外
				if (!noSyncIdxToProdMap.containsKey(i)) continue;
				QuotaItem__c nw =  nwLst[i];
				// 該当INDEXにNOSYNCのプラン商品が存在する場合
				Id prodId = noSyncIdxToProdMap.get(i);
				String spcd = CommUtils.nullToBlank(nw.ShopCodeCal__c);
				// 該当プランの室料商品が非存在する場合
				if (!retMap.containsKey(prodId)) continue;
				// 該当明細の宿泊税計算する
				Decimal specTax = 0;
				// 税抜き金額を計算する
				CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(nw.UnitPriceDefKbCal__c));
				for (ProductItemUtils.PlanDetail pd : retMap.get(prodId)) {
					priceInfo.process(CommUtils.nullToZero(pd.prodPrice) , 1, nw.TaxRate__c, nw.ServiceRate__c);
					specTax += CommLogicProcess.getHotelTax(priceInfo.unitPriceIncServiceExcTax,hotelTaxDefMap.get(spcd)) * CommUtils.nullToZero(nw.Amount__c);
				}
				nw.SpecialTax__c = specTax;
			}
		} // end if (!noSyncRoomPriceMap.isEmpty()) 
		// SYNC設定されている場合
		if (!exSyncRoomMap.isEmpty()) {
			// 指定の会計商品IDにより、室料がどうかチェックする
			set<Id> roomProductSet = ProductItemUtils.checkRoomProduct(exSyncProdIdSet);
			for (Integer i = 0; i < nwLst.size(); i++) {
				if (!exSyncRoomMap.containsKey(i)) continue;
				QuotaItem__c nw =  nwLst[i];
				Decimal specTax = 0;
				CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(nw.UnitPriceDefKbCal__c));
				String spcd = CommUtils.nullToBlank(nw.ShopCodeCal__c);
				for (ProdInfo prod : exSyncRoomMap.get(i)) {
					// 該当商品は室料じゃない場合、処理対象外
					if (!roomProductSet.contains(prod.prodId)) continue;
					priceInfo.process(CommUtils.nullToZero(prod.price) , 1, nw.TaxRate__c, nw.ServiceRate__c);
					specTax += CommLogicProcess.getHotelTax(priceInfo.unitPriceIncServiceExcTax,hotelTaxDefMap.get(spcd)) * CommUtils.nullToZero(nw.Amount__c);
				}
				nw.SpecialTax__c = specTax;
			}
		}//if (!exSyncRoomMap.isEmpty()) {
    }
    class ProdInfo {
    	Id prodId{get;set;}
    	Decimal price{get;set;}
    	public ProdInfo(Id pId, Decimal p) {
    		prodId = pId;
    		price = CommUtils.nullToZero(p);
    	}
    }
}