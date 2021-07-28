/*
 * 機能名     : 見積明細トリガーから呼び出し機能
 * ファイル名 : BookingEstimateItemTriggerProcess.cls
 *
 *  VERSION    DATE        BY          CHANGE/COMMENT
 * ----------------------------------------------------------------
 *  1.00       2012/07/06  WSQ         Create
 *  4.28       2014/04/02  WSQ         プランのBreakDown商品の合計金額（単価区分３を計算する）
 *  X.XX       2015/09/20  WSQ	       単価定義区分に従って、過去見積もり明細金額変更あり不具合修正
 *             2015/10/13  WSQ         PLAN商品非課税商品明細含めする場合、対応を行う[プラン金額から税金を外す]
 *             2015/10/18  WSQ         [プラン明細個別設定情報]により、プラン明細自動展開する・しない処理追加
 *			   2018/07/27  WGCH        宿泊税自動計算
 *			   2020/01/30  zyz         予約作成段階では「利用日」が入力
 */
public with sharing class BookingEstimateItemTriggerProcess {

	/**
	* 見積り明細情報設定にて、該当所属する予約へ情報を連携を行う(After Insert/After Update)
	* 2013/01/24 見積り明細の商品の処理種別：朝食の場合、所属する予約データの朝食フラグを設定する
	**/
	public void syncInfoToLead(BookingEstimateItem__c[] newLst) {
		//
		Set<Id> leadIdSet = new Set<Id>();
		for (BookingEstimateItem__c nw : newLst) {
			// 所属種別は「朝食」場合、予約の朝食へ更新を行う
			if (nw.ActionType__c == CommConst.PROD_ACTION_TYPE_MO) {
				leadIdSet.add(nw.refBooking__c);
			}
		}
		// 2017/04/14 性能改善対応 BEGIN
		if (leadIdSet.isEmpty()) return;
		// 2017/04/14 性能改善対応 END
		Set<Id> accMstIdSet = new Set<Id>();
		for (BookingEstimateItem__c nw : newLst) {
			// 既に設定済みの予約の場合、同じ予約、再処理を行わない
			if (leadIdSet.contains(nw.refBooking__c)) continue;
			// 該当商品はプランの場合、プラン明細設定情報をみて、関連チェックを行う
			if (nw.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) {
				accMstIdSet.add(nw.refAccountMaster__c);
			} 
		}
		// 該当プランに所属明細に、朝食が存在する場合、該当予約の朝食フラグも設定を行う
		Set<Id> moringFoodSet = new Set<Id>();
		for (AggregateResult rs : [
							select PlanProdcut__c productId from PlanDetail__c 
							where AccountMasterRef__r.ActionType__c = :CommConst.PROD_ACTION_TYPE_MO And PlanProdcut__c in :accMstIdSet
							Group By PlanProdcut__c]) {
			moringFoodSet.add((Id)rs.get('productId'));
		}
		for (BookingEstimateItem__c nw : newLst) {
			if (leadIdSet.contains(nw.refBooking__c)) continue;
			// 朝食存在する場合
			if (moringFoodSet.contains(nw.refAccountMaster__c)) {
				leadIdSet.add(nw.refBooking__c);
			}
		}
		
		List<Lead__c> updLeadLst = [Select Morningfood__c from Lead__c where id in :leadIdSet and Morningfood__c = false];
		for (Lead__c lead : updLeadLst) {
			lead.Morningfood__c = true;
		}
		if(!updLeadLst.isEmpty()) update updLeadLst;
	}

	/**
	* 会計商品マスタから見積明細へ連携、設定を行う
	* 見積明細新規作成のタイミング、選択する会計商品から初期値自動設定を行う
	* Action Time: Before Insert
	**/
	public void syncAccountMstToBookingItem(BookingEstimateItem__c[] newLst, BookingEstimateItem__c[] oldLst, CommConst.TriggerMethod action){
		// 新規以外場合、処理中止
		if (action != CommConst.TriggerMethod.isInsert && action != CommConst.TriggerMethod.isUpdate) return;
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		map<string,CommLogicProcess.HotelTaxDefineInfo> hotelTax = CommLogicProcess.getHotelTaxDefInstance();
		// 2019/07/30 軽減税率機能対応 WGCH END
		// 会計商品最新情報を取得する
		Set<Id> accMstSet = new Set<Id>();
		//if (action == CommConst.TriggerMethod.isInsert) {
		for (BookingEstimateItem__c item: newLst) {
			accMstSet.add(item.refAccountMaster__c);
		}
		//} else {
		//	for (Integer i =0; i<newLst.size(); i++) {
		//		BookingEstimateItem__c nw = newLst[i];
		//		BookingEstimateItem__c od = oldLst[i];
		//		if (nw.refAccountMaster__c != od.refAccountMaster__c) accMstSet.add(nw.refAccountMaster__c);
		//	}
		//}
        // 更新する場合
        Set<Id> chgProdIdSet = new Set<Id>();
        if (action == CommConst.TriggerMethod.isUpdate) {
        	// 会計明細を更新される場合
			for (Integer i =0; i<newLst.size(); i++) {
				BookingEstimateItem__c nw = newLst[i];
				BookingEstimateItem__c od = oldLst[i];
				if (nw.refAccountMaster__c != od.refAccountMaster__c) chgProdIdSet.add(nw.Id);
			}
        }
		if (accMstSet.isEmpty()) return;
		
		// 商品マスタ最新情報を取得する
		Map<Id, AccountMaster__c> accMstMap = getAccMstInfoMap(accMstSet);
		
		// 2013/01/23 TARIF商品の場合、関連の単価は
		Set<Id> tarifProdIdSet = new Set<Id>();
		// 該当所属する予約のSubIndexの売価から取得、単価に設定を行う
		for (AccountMaster__c prod : accMstMap.values()) {
			// TARIFプラン商品場合
			if (prod.Name.contains(Label.CST_0001) &&
				prod.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) {
				tarifProdIdSet.add(prod.Id);
			}
		}
		// <会計商品ID/予約ID>
		Map<Integer, Id> prodIdMap = new Map<Integer, Id>();
		Map<Integer, Id> leadIdMap = new Map<Integer, Id>();
		Map<Id, Id> subIndexIdMap = new Map<Id, Id>();
		Map<Id, LeadIndex__c> subIdxMap = null;
		
		if (!tarifProdIdSet.isEmpty()) {
			//for (BookingEstimateItem__c item: newLst) {
			for (Integer i = 0; i < newLst.size(); i++) {
				BookingEstimateItem__c item = newLst[i];
				// TARIF商品場合、該当見積り明細の予約データIDを取得して、該当関連のSUBINDEXの売価を取得して
				// 会計商品の単価に設定を行う
				if (tarifProdIdSet.contains(item.refAccountMaster__c)) {
					// TARIF商品
					//leadIdSet.add(item.refBooking__c);
					prodIdMap.put(i, item.refAccountMaster__c);
					leadIdMap.put(i, item.refBooking__c);
				}
			}
			for (lead__c lead : [select Id, LeadIndexSubId__c from Lead__c where id in :leadIdMap.values() ]) {
				subIndexIdMap.put(lead.Id, lead.LeadIndexSubId__c);
			}
			subIdxMap = new Map<Id, LeadIndex__c> ([select id, Name, SalesPrice__c from LeadIndex__c where id in :subIndexIdMap.values()]);
		}
//System.debug('prodIdMap::: ' + prodIdMap);
//System.debug('leadIdMap::: ' + leadIdMap);
//System.debug('subIndexIdMap::: ' + subIndexIdMap);
//System.debug('subIdxMap::: ' + subIdxMap);
		// 新規作成の見積もり明細情報を自動設定を行う
		for (Integer i = 0; i < newLst.size(); i++) {
			BookingEstimateItem__c item = newLst[i];
		//for (BookingEstimateItem__c item: newLst) {
			AccountMaster__c accMstItem = accMstMap.get(item.refAccountMaster__c);
			// 該当商品は未変更する場合、処理対象外
			if (accMstItem == null) continue;
			// 該当商品はTARIF商品場合 BEGIN
			if (tarifProdIdSet.contains(accMstItem.Id)) {
				// 該当商品に関連している売価を取得して、単価を設定する
				Id subIdxId = subIndexIdMap.get(leadIdMap.get(i));
				if (subIdxId != null) {
					accMstItem.Field5__c = subIdxMap.get(subIdxId).SalesPrice__c;
				}
			}
			// 該当商品はTARIF商品場合 END
			
			//if (CommUtils.isBlank(item.DPChange__c)) 
			item.DPChange__c =  accMstItem.DPChange__c;  // #DP
			//if (CommUtils.isBlank(item.Field10__c)) 
			item.Field10__c =  accMstItem.Field10__c;  // 小計割引／割増
			//if (CommUtils.isBlank(item.Field11__c)) 
			item.Field11__c =  accMstItem.Field11__c;  // ﾌﾘｰ宣言
			//if (CommUtils.isBlank(item.Field3__c)) 
			item.Field3__c =  accMstItem.Field3__c;  // 商品コード

			//if (CommUtils.isBlank(item.Field4__c)) 
			item.Field4__c =  accMstItem.Field4__c;  // リンクＤＰコード
			//if (item.Field6__c == null) 
			item.Field6__c =  accMstItem.Field6__c;  // ｻﾌﾞ単価
			//if (item.Field7__c == null) 
			item.Field7__c =  accMstItem.Field7__c;  // 原価
			//if (item.Field8__c == null) 
			item.Field8__c =  accMstItem.Field8__c;  // 単価2
			//if (CommUtils.isBlank(item.Field9__c)) 
			item.Field9__c =  accMstItem.Field9__c;  // ｾｯﾄ宣言
			//if (CommUtils.isBlank(item.GPChange__c)) 
			item.GPChange__c =  accMstItem.GPChange__c;  // #GP
			//if (CommUtils.isBlank(item.OES__c)) 
			item.OES__c =  accMstItem.OES__c;  // OES用ﾒﾆｭｰ
			//if (CommUtils.isBlank(item.OP__c)) 
			item.OP__c =  accMstItem.OP__c;  // 会計OP
//			if (CommUtils.isBlank(item.OrderDate__c)) item.OrderDate__c =  accMstItem.OrderDate__c;  // 発注日
//			if (CommUtils.isBlank(item.Orderer__c)) item.Orderer__c =  accMstItem.Orderer__c;  // 発注者
			//if (CommUtils.isBlank(item.PLU__c)) 
			item.PLU__c =  accMstItem.PLU__c;  // PLUｺｰﾄﾞ
			//if (CommUtils.isBlank(item.SCP_5__c)) 
			item.SCP_5__c =  accMstItem.SCP_5__c;  // SCP(5)
//			if (CommUtils.isBlank(item.SpTotal__c)) item.SpTotal__c =  accMstItem.SpTotal__c;  // #合計金額
//			if (CommUtils.isBlank(item.Supplier__c)) item.Supplier__c =  accMstItem.Supplier__c;  // 発注先
//			if (CommUtils.isBlank(item.Total__c)) item.Total__c =  accMstItem.Total__c;  // $合計金額(税込)
			if (item.UnitPrice__c == null) item.UnitPrice__c =  accMstItem.Field5__c;  // 単価(税込)
			//if (CommUtils.isBlank(item.X1__c)) 
			item.X1__c =  accMstItem.X1__c;  // 名称1(ｶﾅ)
            //if (CommUtils.isBlank(item.X2_1__c)) 
            item.X2_1__c =  accMstItem.Name;  // 名称2(漢1)
			//if (CommUtils.isBlank(item.X3_2__c)) 
			item.X3_2__c =  accMstItem.X3_2__c;  // 名称3(漢2)
			//if (CommUtils.isBlank(item.X4_3__c)) 
			item.X4_3__c =  accMstItem.X4_3__c;  // 名称4(漢3)
			// 2019/10/30 明細入力時に自動で反映 WGCH BEGIN
			// 会計GP名
			item.AccMstGPName__c = accMstItem.GPChange__r.Name;
			// 会計DP名
			item.AccMstDPName__c = accMstItem.DPChange__r.Name;
			// 会計OP名
			item.AccMstOPName__c = accMstItem.OP__r.Name;
			// 部屋タイプ名
			item.TypeOfRoomName__c = item.TypeOfRoomNameCal__c;
			// お部屋名
			item.RoomName__c = item.RoomNameCal__c;
			// 予約タイプ
			item.ReservedType__c = item.ReservedTypeCal__c;
			// 2019/10/30 明細入力時に自動で反映 WGCH END
//			if (CommUtils.isBlank(item.refAccountMaster__c)) item.refAccountMaster__c =  accMstItem.refAccountMaster__c;  // 商品名
			//if (item.ServiceRate__c == null) 
// 該当明細に新規　OR　既存の明細の商品IDを変更される場合、消費税など最新情報を取得する
if (action == CommConst.TriggerMethod.isInsert || chgProdIdSet.contains(item.Id)) {
	// Breakdown情報の消費税、サビース連動を行わない
	if (item.ParentBookingItemRef__c == null) {
			item.ServiceRate__c =  accMstItem.ServiceRate__c;  // サービス料(%)
			//if (item.SpecialTax__c == null) 
			item.SpecialTax__c =  accMstItem.SpecialTax__c;  // 特別税
			//if (item.TaxRate__c == null) 
			item.TaxRate__c =  accMstItem.TaxRateCal__c;  // 消費税*/
	}
}
			// 2012/08/24 WSQ ADD BEGIN[設定じゃなく、実際の設定からコピーする]
			item.ActionType__c = accMstItem.ActionType__c;  // 商品処理種別
			// 2013/01/13 WSQ
			if (CommUtils.isBlank(item.ProductName__c)) item.ProductName__c =  accMstItem.Name;  // 名称2(漢1)
			// 2015/02/09 WSQ
			item.PaymentType__c = accMstItem.PaymentType__c; // 支払種別
		}

	}
	// #合計金額など項目内容の自動設定
	public void autoSetupFieldValue(BookingEstimateItem__c[] newLst, BookingEstimateItem__c[] oldLst, CommConst.TriggerMethod action){
		// #合計金額　＝　単価（税込）　＊　数量　＋　(単価（税込）　＊　数量) * サビース料金(%)　＋ 特別税　
    	// 2014/08/06   単価定義区分に従って、過去見積もり明細金額変更あり不具合修正 BEGIN
    	//CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo();
    	// 2014/08/06   単価定義区分に従って、過去見積もり明細金額変更あり不具合修正 END
        // 2016/04/13 JPY以外の場合、２桁小数の単価（税抜き）計算を行う BEGIN
        Integer locPointLen = CommUtils.getPointLen();
        // 2016/04/13 JPY以外の場合、２桁小数の単価（税抜き）計算を行う END
//2017/04/24 見積もり明細効率改修　by zy BEGIN
        map<String,Decimal> totalMap = new map<String,Decimal>();
        map<String,Decimal> totalExcMap = new map<String,Decimal>();
//2017/04/24 見積もり明細効率改修　by zy END      
        
        // 2018/07/27 宿泊税計算 WGCH BEGIN
        // 宿泊税対象リスト
        List<BookingEstimateItem__c> roomRateCalLst = new List<BookingEstimateItem__c>();
        // プランのHeader情報リスト
        List<BookingEstimateItem__c> planHeaderLst = new List<BookingEstimateItem__c>();
        for (Integer i = 0; i < newLst.size(); i++) {
        	BookingEstimateItem__c nw =  newLst[i];
        	if (oldLst != null) {
        		BookingEstimateItem__c od =  oldLst[i];
        		// 処理対象外明細
        		if (nw.TriggerIsStopFlg__c != od.TriggerIsStopFlg__c) continue;
        		// 2019/11/11 BUGFIEX修正 WGCH BEGIN
        		nw.TankanonetaxNew__c = 0;
        		// 2019/11/11 BUGFIEX修正 WGCH END
        	}

            // 該当明細は室料の場合、該当室料の宿泊税計算を行う
            if (RackRateUtils.isRoomRateProduct(nw.ActionType__c)) {
            	roomRateCalLst.add(nw);
            }
            // プランの場合、プランニア用をクリアする
            if (nw.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) {
            	planHeaderLst.add(nw);
            }
        }
//System.debug(loggingLevel.info, 'roomRateCalLst='+roomRateCalLst);
//System.debug(loggingLevel.info, 'planHeaderLst='+planHeaderLst);
		if (!roomRateCalLst.isEmpty() || !planHeaderLst.isEmpty()) {
			map<string,CommLogicProcess.HotelTaxDefineInfo> hotelTaxDefMap = CommLogicProcess.getHotelTaxDefInstance();
			if (!hotelTaxDefMap.isEmpty()) {
				// 明細の宿泊税を計算する
				if (!roomRateCalLst.isEmpty()) {
					// 宿泊税計算を行う
					for (BookingEstimateItem__c nw: roomRateCalLst) {
						String spcd = CommUtils.nullToBlank(nw.ShopCodeCal__c);
						// 該当明細の店舗に対して、宿泊情報を定義が存在する場合
						if (hotelTaxDefMap.containsKey(spcd)) {
							// 2018/11/14 修正 WGCH BEGIN
							// nw.SpecialTax__c = CommLogicProcess.getHotelTax(nw.Tankanonetax__c,hotelTaxDefMap.get(spcd)) * CommUtils.nullToZero(nw.Amount__c);
							CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(nw.UnitPriceDefKbCal__c));
							// 2019/07/30 軽減税率機能対応 WGCH BEGIN
							if(CommConst.REDUCED_TAXRATE_FLG){
								CommLogicProcess.HotelTaxInfo hotelTaxItem = CommLogicProcess.getHotelTaxInfo(spcd, CommUtils.nullToBlank(nw.ActionType__c), CommUtils.nullToZero(nw.UnitPrice__c), CommUtils.nullToZero(nw.Amount__c), nw.TaxRate__c, nw.ServiceRate__c, priceInfo, hotelTaxDefMap);
								priceInfo = hotelTaxItem.priceInfo;
								nw.TankanonetaxNew__c = priceInfo.unitPriceIncServiceExcTax;
								nw.SpTotal__c = priceInfo.priceIncTax;
								nw.SpecialTax__c = 0;
								if(hotelTaxItem.autoSetFlg){
									nw.SpecialTax__c = hotelTaxItem.newNumSepcTaxSum;
									nw.SpTotal__c = priceInfo.priceIncTax + hotelTaxItem.newNumSepcTaxSum;
								}
								continue;
							}
							// 2019/07/30 軽減税率機能対応 WGCH END
							priceInfo.process(CommUtils.nullToZero(nw.UnitPrice__c), CommUtils.nullToZero(nw.Amount__c), nw.TaxRate__c, nw.ServiceRate__c);
							nw.SpecialTax__c = CommLogicProcess.getHotelTax(priceInfo.unitPriceIncServiceExcTax,hotelTaxDefMap.get(spcd)) * CommUtils.nullToZero(nw.Amount__c);
							// 2019/03/15 特别税を設定bug改修 WGCH BEGIN
							// plan明细,自动设定的特别税,特别税字段的值没有合计到#合計金額字段里
							if(!CommUtils.isBlank(nw.ParentBookingItemRef__c)) nw.SpTotal__c = CommUtils.nullToZero(nw.SpTotal__c) + CommUtils.nullToZero(nw.SpecialTax__c);
							// 2019/03/15 特别税を設定bug改修 WGCH END
							// 2018/11/14 修正 WGCH END
						}
					}
				}
				// 各プランの特別税をクリアする
				for (BookingEstimateItem__c plan : planHeaderLst) {
					plan.SpecialTax__c = 0;
				}
			}
		}
        // 2018/07/27 宿泊税計算 WGCH END
        
		for (BookingEstimateItem__c nw: newLst) {
			//2017/04/24 見積もり明細効率改修　by zy BEGIN
			// 2019/02/15 単価定義区分を設定bug改修 BY zyz BEGIN
			// String searchKey = CommUtils.nullToZero(nw.UnitPrice__c) + '_' + CommUtils.nullToZero(nw.Amount__c) + '_' + nw.TaxRate__c  + '_' + nw.ServiceRate__c;
      	  	String searchKey = CommUtils.nullToZero(nw.UnitPrice__c) + '_' + CommUtils.nullToZero(nw.Amount__c) + '_' + nw.TaxRate__c  + '_' + nw.ServiceRate__c + '_' + nw.UnitPriceDefKb__c;
      	  	// 2019/04/15 JINYABUG-1591 bug fix by zy BEGIN
      	  	searchKey += '_' + CommUtils.nullToZero(nw.SpecialTax__c);
      	  	// 2019/04/15 JINYABUG-1591 bug fix by zy END
      	  	// 2019/02/15 単価定義区分を設定bug改修 BY zyz END
      	  	//2017/04/24 見積もり明細効率改修　by zy END
			// 2013/01/13 WSQ
			//if (nw.ProductName__c != nw.X2_1__c) nw.X2_1__c = nw.ProductName__c;
			// #合計金額非存在する場合
			if (nw.SpTotal__c == null) {
//2017/04/24 見積もり明細効率改修　by zy BEGIN
				if (!totalMap.containsKey(searchKey)){
//2017/04/24 見積もり明細効率改修　by zy END
					// 2014/08/06   単価定義区分に従って、過去見積もり明細金額変更あり不具合修正 BEGIN
					CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(nw.UnitPriceDefKbCal__c));
					// 2014/08/06   単価定義区分に従って、過去見積もり明細金額変更あり不具合修正 END
	/* 20121005修正を行う（商品単価多目意味機能対応） */
	            	priceInfo.process(CommUtils.nullToZero(nw.UnitPrice__c), CommUtils.nullToZero(nw.Amount__c), nw.TaxRate__c, nw.ServiceRate__c);
	/*				// 売価
					Decimal totalPrice = CommUtils.nullToZero(nw.UnitPrice__c) * CommUtils.nullToZero(nw.Amount__c);
					// サービス料
					Decimal servicePrices = CommUtils.RoundProcess(totalPrice * (CommUtils.nullToZero(nw.ServiceRate__c) / 100),0);
					// #合計金額設定
					nw.SpTotal__c = totalPrice + servicePrices + CommUtils.nullToZero(nw.SpecialTax__c);*/
					nw.SpTotal__c = priceInfo.priceIncTax + CommUtils.nullToZero(nw.SpecialTax__c);
//2017/04/24 見積もり明細効率改修　by zy BEGIN					
					totalMap.put(searchKey,nw.SpTotal__c);
				} else {
					nw.SpTotal__c = totalMap.get(searchKey);
				}
//2017/04/24 見積もり明細効率改修　by zy END
			}
			
			// 2016/04/13 JPY以外の場合、２桁小数の単価（税抜き）計算を行う BEGIN
            // 単価（税抜き）金額は再計算して、設定を行う
            if (locPointLen > 0) {
//2017/04/24 見積もり明細効率改修　by zy BEGIN
            	if (!totalExcMap.containsKey(searchKey)){
//2017/04/24 見積もり明細効率改修　by zy END
            		CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(nw.UnitPriceDefKbCal__c));
	            	priceInfo.process(CommUtils.nullToZero(nw.UnitPrice__c), CommUtils.nullToZero(nw.Amount__c), nw.TaxRate__c, nw.ServiceRate__c);
	           	 	nw.TankawithoutTaxSys__c = priceInfo.unitPriceIncServiceExcTax;
//2017/04/24 見積もり明細効率改修　by zy BEGIN	           	 	
	           	 	totalExcMap.put(searchKey,nw.TankawithoutTaxSys__c);
            	} else {
            		nw.TankawithoutTaxSys__c = totalExcMap.get(searchKey);
            	}
//2017/04/24 見積もり明細効率改修　by zy END
            }
            // 2016/04/13 JPY以外の場合、２桁小数の単価（税抜き）計算を行う END
			// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz BEGIN
			if (nw.useDate__c == null && nw.UseDateCal__c != null) nw.useDate__c = nw.UseDateCal__c.date();
			// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz END
		}
	}

	// プラン設定されている場合、プラン明細は自動見積もり明細に追加する
    /**********************************************
    * プラン会計商品を登録されている場合、
    * 既存の会計商品は既にプラン商品で登録される場合、常にプラン明細商品を登録する
    * 該当プラン関連の会計明細商品は見積もり明細に自動追加する
    * After Insert/[After Update]/Before Delete
    * 2014/06/20 プランからBreakdown明細情報展開する場合、明細が室料ありかつ室料金は０の場合、ラクレート金額を取得、プランのBreakdownへ反映する
    *            室料を設定すると、プランの金額は既存金額から＋室料を加算して、単価再設定する
    *            既存の見積もり明細から明細詳細再変更の反映はこのMethodに含めない、プラン新規設定　OR　プラン設定変更のみ対応です
    ***********************************************/
    public void expandPlanItem (List<BookingEstimateItem__c> nw, List<BookingEstimateItem__c> od, CommConst.TriggerMethod act) {
    	// 2019/09/15 Security Check BY zyz BEGIN
    	if (!CommSecurityUtils.isDeleteable(BookingEstimateItem__c.getSObjectType())) {
    		return;
    	}
    	// 2019/09/15 Security Check BY zyz END
    	// 処理する会計商品に、会計商品（プラン）が存在する場合、プラン明細は自動会計明細へ追加する
    	// 見積もり明細ID/見積もり明細
    	Map<Id, BookingEstimateItem__c> insPlanTranMap = new Map<Id, BookingEstimateItem__c>();
    	// 会計明細のデータはプラン場合、該当IDは格納する<会計明細ID/プラン商品ID>
    	Map<Id, Id> tranPlanIdMap = new Map<Id,Id>();
		// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
		Map<String,Map<Id,String>> leadAndEstPersonMap = new Map<String,Map<Id,String>>();
		// 予約下の見積明細の会員種別集合
		Map<String,Map<Id,String>> leadAndEstGuestTypeMap = new Map<String,Map<Id,String>>();
		Map<String,List<BookingEstimateItem__c>> bookingEstMap = new Map<String,List<BookingEstimateItem__c>>();
		// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
    	// 会計明細（プラン）明細の数量連動設定
    	//Map<Id, String> tranPlanItemMap = new Map<Id, String>();
    	// 新規作業場合
    	if (act == CommConst.TriggerMethod.IsInsert ) {
	        for (BookingEstimateItem__c tr : nw) {
	        	// 商品は「プラン」場合、処理対象になる
	            if (tr.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) {
	            	// 2015/10/18 [プラン明細個別設定情報]により、プラン明細自動展開する・しない処理追加 BEGIN
	            	if(!itemExpandCheck(tr.PlanDetailSyncInfo__c)) continue;
	            	// 2015/10/18 [プラン明細個別設定情報]により、プラン明細自動展開する・しない処理追加 END
	            	// プラン商品の情報を格納する
	            	insPlanTranMap.put(tr.id, tr);
	            	// 会計明細の参照している商品IDを取得する
	            	tranPlanIdMap.put(tr.id, tr.refAccountMaster__c);
					// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
					if (!bookingEstMap.containsKey(tr.refBooking__c)) bookingEstMap.put(tr.refBooking__c,new List<BookingEstimateItem__c>());
					bookingEstMap.get(tr.refBooking__c).add(tr.clone(true,true));
					// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
	            }
	        }
    	}
    	// 更新作業場合[商品コード変更 && 変更前の商品タイプはプラン，該当プランがなくなるため、関連の明細データも一緒に削除する]
    	else if (act == CommConst.TriggerMethod.IsUpdate ) {
    		Set<Id> delPlanTranSet = new Set<Id>();
    		for (Integer i = 0; i < nw.size(); i++) {
    			BookingEstimateItem__c nwItem = nw[i];
    			BookingEstimateItem__c odItem = od[i];
        		// 2018/07/27 宿泊税計算 WGCH BEGIN
        		// 処理対象外明細
        		if (nwItem.TriggerIsStopFlg__c != odItem.TriggerIsStopFlg__c) continue;
        		// 2018/07/27 宿泊税計算 WGCH END
        		
    			// 2015/10/18 [プラン明細個別設定情報]により、プラン明細自動展開する・しない処理追加 BEGIN
    			// 商品変更なし、既存のプランの個別設定情報は無効、新設定の明細情報が有効の場合、
    			if (nwItem.refAccountMaster__c == odItem.refAccountMaster__c &&
    				nwItem.ActionType__c == CommConst.PROD_ACTION_TYPE_PL &&
    				itemExpandCheck(nwItem.PlanDetailSyncInfo__c) &&
    				itemExpandCheck(odItem.PlanDetailSyncInfo__c) != true) {
					// プラン商品の情報を格納する
	            	insPlanTranMap.put(nwItem.id, nwItem);
	            	// 会計明細の参照している商品IDを取得する
	            	tranPlanIdMap.put(nwItem.id, nwItem.refAccountMaster__c);
    				continue;		
    			}
    			// 2015/10/18 [プラン明細個別設定情報]により、プラン明細自動展開する・しない処理追加 END
				// 商品変更する場合
				//2017/06/26 見積もり明細の価格対応　by　zy　BEGIN
				// 一括予約画面の場合下、プラン明細更新可能する
				if (nwItem.refAccountMaster__c == odItem.refAccountMaster__c && nwItem.PlanRefreshFlg__c == odItem.PlanRefreshFlg__c) continue;
				//2017/06/26 見積もり明細の価格対応　by　zy　END
				// 変更前の商品はプラン場合 && 商品の商品種別はプラン場合
				if (odItem.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) {
					delPlanTranSet.add(odItem.Id);				
				}
				// 新商品の商品種別はプラン場合
				if (nwItem.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) {
					// プラン商品の情報を格納する
	            	insPlanTranMap.put(nwItem.id, nwItem);
	            	// 会計明細の参照している商品IDを取得する
	            	tranPlanIdMap.put(nwItem.id, nwItem.refAccountMaster__c);
					// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
					if (!bookingEstMap.containsKey(nwItem.refBooking__c)) bookingEstMap.put(nwItem.refBooking__c,new List<BookingEstimateItem__c>());
					bookingEstMap.get(nwItem.refBooking__c).add(nwItem.clone(true,true));
					// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
				}
    			//if (!delPlanTranSet.isEmpty()) delete [select id from BookingEstimateItem__c where ParentBookingItemRef__c in :delPlanTranSet];
    		}
			// 2015/10/18 削除処理効率改善 BEGIN
    		if (!delPlanTranSet.isEmpty()) delete [select id from BookingEstimateItem__c where ParentBookingItemRef__c in :delPlanTranSet];
    		// 2015/10/18 削除処理効率改善 END
        }
    	// 削除作業場合
    	else if (act == CommConst.TriggerMethod.IsDelete ) {
    		Set<Id> delPlanTranSet = new Set<Id>();
            for (BookingEstimateItem__c tr : od) {
                // 商品は「プラン」場合、処理対象になる
                if (tr.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) {
                    delPlanTranSet.add(tr.Id);
                }
            }
            if (!delPlanTranSet.isEmpty()) delete [select id from BookingEstimateItem__c where ParentBookingItemRef__c in :delPlanTranSet];
            return;
    	}
    	// 処理対象データがない場合、処理終了
    	if (insPlanTranMap.isEmpty()) return;
    	// 関連処理を行う
    	// プラン明細情報を取得する[新規用情報]
    	// TODO：プラン明細設定画面に、消費税(参照関係)未設定するため、該当部份の対応が必要です
    	List<BookingEstimateItem__c> insLst = new List<BookingEstimateItem__c>();
    	Map<Id, List<PlanDetail__c>> planDetailMap = new Map<Id, List<PlanDetail__c>>();	//=>1会計商品（プラン）→Nプラン明細情報格納
    	// プラン明細に室料項目の場合、情報を格納する
    	String roomRateProdName = CommConst.APPOPTION_ROOMPRICE_PRODNAME;
    	// 会計商品種別は室料
    	String roomRateTypeName = CommConst.PROD_ACTION_TYPE_RP;
    	// Map<商品（プラン）ID/プラン明細ID>
		Map<Id, Set<Id>> planRoomRateMap = new Map<Id, Set<Id>>();	// 室料設定必要の見積もり明細プラン情報を格納する
		// 2020/04/03 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz BEGIN	
		Set<String> basePlanSet = new Set<String>();
		Map<String,Decimal> basePlanRoomRateMap = new Map<String,Decimal>();
		// 2020/04/03 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz BEGIN	
    	//---------------------------------------------
    	// 見積もり明細→会計商品から、プラン明細設定情報を取得する
    	// tranPlanIdMap.values() : 会計商品（プラン）のID群
    	//---------------------------------------------
        for (PlanDetail__c pd : [select Id, AccountMasterRef__c, AccountMasterRef__r.Name, AccountMasterRef__r.ActionType__c,
        						AccountMasterRef__r.SCP_5__c, AccountMasterRef__r.TaxRateCal__c,
        						AccountMasterRef__r.PaymentType__c,		// 2015/02/09 支払種別コピー
        						AccountMasterRef__r.Field4__c,PlanRef__c,
                                AccountMasterRef__r.Field5__c, Price__c, TaxRate__c, JmstRef__c,
								ServiceRate__c, ProductNumber__c, PlanProdcut__c
								// 2020/04/03 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz BEGIN	
								,PlanRef__r.BasePlanFlg__c
								// 2020/04/03 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz END	
                                // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
                                ,OptionAccMstFLG__c
                                // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
                                from PlanDetail__c where PlanProdcut__c in :tranPlanIdMap.values()]) {
            // 商品（プラン）非存在する場合
            /*
            if (!planDetailMap.containsKey(pd.PlanProdcut__c)) {
                List<PlanDetail__c> pdLst = new List<PlanDetail__c>();
                pdLst.add(pd);
                planDetailMap.put(pd.PlanProdcut__c, pdLst);
            } else {
                planDetailMap.get(pd.PlanProdcut__c).add(pd);
            }*/
            if (!planDetailMap.containsKey(pd.PlanProdcut__c)) planDetailMap.put(pd.PlanProdcut__c, new List<PlanDetail__c>());
            planDetailMap.get(pd.PlanProdcut__c).add(pd);
            
            // プラン明細の会計商品は室料商品の場合 && 商品名は指定の室料商品場合
            // 室料は０円の場合、該当プラン明細の所属するラクレート室料情報を取得、プラン
	    	// 2015/10/18 プラン明細に室料存在チェックロジックの修正 BEGIN
            //if (pd.AccountMasterRef__r.Name == roomRateProdName &&
            //	pd.AccountMasterRef__r.ActionType__c == roomRateTypeName &&
            if (RackRateUtils.isRoomRateProduct(pd.AccountMasterRef__r) &&
            // 2015/10/18 プラン明細に室料存在チェックロジックの修正 END
            	CommUtils.nullToZero(pd.Price__c) == 0) {
            	//planRoomRateMap.put(pd.Id, pd.Price__c);
            	if (!planRoomRateMap.containskey(pd.PlanProdcut__c)) planRoomRateMap.put(pd.PlanProdcut__c, new Set<Id>());
				planRoomRateMap.get(pd.PlanProdcut__c).add(pd.Id);	// 会計商品（プラン）のIDに関連の室料未設定のプラン明細情報を格納する
				// 2020/04/03 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz BEGIN	
				// 連泊作成の場合の見積もり料金が変わる
				if (!CommConst.APPOPTION_ROOMPRICE_NOATSETUPFLG && pd.PlanRef__r.BasePlanFlg__c) basePlanSet.add(pd.PlanRef__c);
				// 2020/04/03 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz END	
            }
        }
        // 室料が０円のプラン明細に対して、予約データ単位の室料を自動取得、明細に設定を行う
        // Map<Lead Id / 室料>
        Map<Id, Decimal> leadRoomRateMap = new Map<Id, Decimal>();	// 予約データ単位の室料情報を格納用
        // 2018/04/03 プランBreakDown明細が室料が存在、かつ室料金額が０円の場合、ラックレートにより、金額設定しない、するフラグ BEGIN
        // フラグはTRUEの場合、室料自動設定しない変更する
        if (CommConst.APPOPTION_ROOMPRICE_NOATSETUPFLG) planRoomRateMap.clear();
        // 2018/04/03 プランBreakDown明細が室料が存在、かつ室料金額が０円の場合、ラックレートにより、金額設定しない、するフラグ END
        // 室料未設定のプラン明細が存在する場合
        // 該当見積もり明細所属する予約データの設定情報により、室料設定情報を取得する（RackRateUtils共通）
        if (!planRoomRateMap.isEmpty()) {
        	
        	// 室料自動設定必要の予約ID情報を格納する
        	Set<id> roomRateLeadIdset = new Set<Id>();
        	// insPlanTranMap: 見積もり明細→プラン情報を格納する
        	// tranPlanIdMap : 見積もり明細→プラン関連の会計商品ID
        	// 見積もり明細
        	for (Id bookingItemId : insPlanTranMap.keySet()) {
        		// 該当見積もり明細(プラン)に含め明細の中に室料明細ありかつ室料は０の明細が存在
        		// その場合、関連のプランの予約のラクレットで室料金を取得、設定する
        		Id planProdId = tranPlanIdMap.get(bookingItemId);
        		// 会計商品（プラン）のIDは室料設定必要のID群に存在する場合、該当見積もり明細所属する予約のIDを取得する
        		if (planRoomRateMap.containsKey(planProdId)) {
        			roomRateLeadIdset.add(insPlanTranMap.get(bookingItemId).refBooking__c);
        		}
        	}
        	if (!roomRateLeadIdset.isEmpty()) {
        		// 予約関連のラクレットを取得する「注意：宿泊の予約ので処理対象です」
        		// 予約の予約人数
        		// 到着日
        		// 部屋タイプ
        		// 関連予約の室料情報を取得する
				RackRateUtils rcUtil = new RackRateUtils();
				// 2020/04/03 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz BEGIN	
				// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
				if (!bookingEstMap.isEmpty()) rcUtil.bookingEstMap = bookingEstMap;
				// if (!leadAndEstPersonMap.isEmpty()) rcUtil.bookingEstPersonMap = leadAndEstPersonMap;
				// if (!leadAndEstGuestTypeMap.isEmpty()) rcUtil.bookingEstGuestTypeMap = leadAndEstGuestTypeMap;
				// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
				leadRoomRateMap = rcUtil.getRoomRateByLead(roomRateLeadIdset,basePlanSet);	
				basePlanRoomRateMap = rcUtil.basePlanRoomRateMap;
				// 2020/04/03 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz END
        	}
		}
		// 会計商品（プラン）関連のプラン明細設定情報が存在する場合
        if (!planDetailMap.isEmpty()) {
        	
			// 会計商品（プラン）の合計値格納する
			Map<Id, Decimal> planProdSummaryMap = new Map<Id, Decimal>();
//2017/04/24 見積もり明細効率改修　by zy BEGIN
       		map<String,decimal> detailSkipMap = new map<String,decimal>();
//2017/04/24 見積もり明細効率改修　by zy END     			
			// 2020/05/29 多泊多見積BUGFIX WGCH BEGIN
			// KEY:見積ID;VAL:新的PLAN对应的SYNC
			map<String,String> planPlanDetailSyncInfoMap = new map<String,String>();
			// 2020/05/29 多泊多見積BUGFIX WGCH END
			// 個別設定する商品の

        	// 金額計算共通
        	// 2014/08/06   単価定義区分に従って、過去見積もり明細金額変更あり不具合修正 BEGIN
        	//CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo();
        	// 2014/08/06   単価定義区分に従って、過去見積もり明細金額変更あり不具合修正 END
        	// 新規場合
        	// 商品（プラン）の会計明細データから、関連所属プラン明細データはDBへ反映する
        	for (Id bookingItemId : insPlanTranMap.keySet()) {
                // 商品（プラン）IDを取得する
        		Id planProdId = tranPlanIdMap.get(bookingItemId);
        		// 商品（プラン）に所属するプラン明細が非存在する場合
        		if (!planDetailMap.containsKey(planProdId)) continue;
	            // 商品（プラン）の見積明細情報を取得する
	            BookingEstimateItem__c planTran = insPlanTranMap.get(bookingItemId);
        		// プラン明細の個別設定情報の存在チェック ADD 2013/01/25
        		Map<Id,String> planItemSyncMap = new Map<Id,String>();
        		// プラン明細→会計商品設定情報の存在チェック
        		Map<Id, Id> planItemAccMstSyncMap = new Map<Id, Id>();
        		Map<Id, String> planItemAccMstProdNmMap = new Map<Id, String>();	// Map<プラン明細ID/会計商品名>
        		// 2020/05/29 多泊多見積BUGFIX WGCH BEGIN
				// PLAN明细ID:单价:商品ID:商品名字;
				String nwPlanDetailSyncInfo = '';
				// 2020/05/29 多泊多見積BUGFIX WGCH END
        		
        		if (!CommUtils.isBlank(planTran.PlanDetailSyncInfo__c)) {			// 該当プランに所属する設定情報が存在する場合
        			// １明細の商品IDと数量格納する
        			String planSynInfo = planTran.PlanDetailSyncInfo__c.substringBeforeLast(';');
        			String[] prodInfoLst = planSynInfo.split(';');
        			for (String prodInfo : prodInfoLst) {
        				String[] prodItem = prodInfo.split(':');
        				planItemSyncMap.put((Id)prodItem[0], prodItem[1]);				// prodItem[0](見積明細ID OR プラン明細ID)   prodItem[1]個別設定情報の「会計商品」金額
        				if (prodItem.size() > 2) {
        					planItemAccMstSyncMap.put((Id)prodItem[0], (Id)prodItem[2]);// 個別設定情報の「会計商品」ID
        				}
        				if (prodItem.size() > 3) {
        					planItemAccMstProdNmMap.put((Id)prodItem[0], prodItem[3]);	// 個別設定情報の「会計商品」名
        				}
        			}
        		}
        		//Set<Id> roomRateAutoSetupIdSet = planRoomRateMap.get(bookingItemId);
	     		// 該当見積もり明細（プラン）に室料の定義情報を取得する
	     		Id leadId = insPlanTranMap.get(bookingItemId).refBooking__c;
	     		// 2020/05/30 6464 bug fix WGCH BEGIN
				Decimal roomRate = CommUtils.nullToZero(leadRoomRateMap.get(leadId));
				// 2020/05/30 6464 bug fix WGCH END
				// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
				if (leadRoomRateMap.containsKey(bookingItemId)) roomRate = leadRoomRateMap.get(bookingItemId);
				// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
// プランの金額は再自動計算を行う
				Decimal planSummary = 0;
	            // 商品（プラン）に所属する明細商品リストを取得する
	            // 見積もり明細（会計商品「プラン」           ---- planProdId
	            //                 ------明細1 ---- planDetailMap.get(planProdId)
	            //                 ------明細2 ----
	            //                 ------明細3 ----
	            for (PlanDetail__c pd : planDetailMap.get(planProdId)) {
	            
	            // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
	            if(CommConst.REDUCED_TAXRATE_FLG && CommConst.OPTION_MODE == CommConst.OPTION_MODE_ON){
	            	// OPTION明细FLG->TRUE; && SYNC内不含有当前Plan明细ID;就跳出当前数据明细作成流程
	            	if(pd.OptionAccMstFLG__c && !planItemSyncMap.isEmpty() && !planItemSyncMap.containsKey(pd.Id)) continue;
	            }
	            // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
	            // 該当プラン明細商品の単価設定値を個別取得、設定を行う
	            String unitPrice = planItemSyncMap.containsKey(pd.Id) ? planItemSyncMap.get(pd.Id) : String.valueOf(pd.Price__c);
// 該当プラン明細は室料設定必要がどうかチエックする
// 2017/11/24 室料自動設定の判断基準は変換、会計商品の種別は「室料」の場合、自動設定を行う BEGIN
//if (pd.AccountMasterRef__r.Name == roomRateProdName &&
//	pd.AccountMasterRef__r.ActionType__c == roomRateTypeName &&
// 2020/04/03 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz BEGIN	
if (pd.AccountMasterRef__r.ActionType__c == roomRateTypeName && CommUtils.nullToZero(unitPrice) == 0 ){
	String basePlanKey = RackRateUtils.genLeadPlanSerachKey(leadId,pd.PlanRef__c);
	// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
	String basePlanEstKey = RackRateUtils.genLeadPlanEstSerachKey(leadId, pd.PlanRef__c,bookingItemId);
	if (basePlanRoomRateMap.containsKey(basePlanEstKey) || basePlanRoomRateMap.containsKey(basePlanKey)) roomRate = basePlanRoomRateMap.containsKey(basePlanEstKey) ? basePlanRoomRateMap.get(basePlanEstKey) : basePlanRoomRateMap.get(basePlanKey);
	// if (basePlanRoomRateMap.containsKey(basePlanKey)) roomRate = basePlanRoomRateMap.get(basePlanKey);
	// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
}
// 2020/04/03 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz END	
if (pd.AccountMasterRef__r.ActionType__c == roomRateTypeName &&
// 2017/11/24 室料自動設定の判断基準は変換、会計商品の種別は「室料」の場合、自動設定を行う END
	CommUtils.nullToZero(unitPrice) == 0 &&
	roomRate != null) {
	unitPrice = String.valueOf(roomRate);
}
// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
if(CommConst.REDUCED_TAXRATE_FLG && CommConst.OPTION_MODE == CommConst.OPTION_MODE_ON && pd.AccountMasterRef__r.ActionType__c == roomRateTypeName && !CommUtils.isBlank(planTran.OptionTotal__c)){
	String basePlanKey = RackRateUtils.genLeadPlanSerachKey(leadId, pd.PlanRef__c);
	// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
	String basePlanEstKey = RackRateUtils.genLeadPlanEstSerachKey(leadId, pd.PlanRef__c,bookingItemId);
	// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
	//if (basePlanRoomRateMap.containsKey(basePlanKey)){
	if (basePlanRoomRateMap.containsKey(basePlanEstKey) || basePlanRoomRateMap.containsKey(basePlanKey)){
		Decimal rate = basePlanRoomRateMap.containsKey(basePlanEstKey) ? basePlanRoomRateMap.get(basePlanEstKey) : basePlanRoomRateMap.get(basePlanKey);
		// 2020/05/30 6464 bug fix WGCH BEGIN
		roomRate = CommUtils.nullToZero(rate) - CommUtils.nullToZero(planTran.OptionTotal__c);
		// 2020/05/30 6464 bug fix WGCH END
		//roomRate = basePlanRoomRateMap.get(basePlanKey) - CommUtils.nullToZero(planTran.OptionTotal__c);
		unitPrice = String.valueOf(roomRate);
	} else {
		// 2020/05/30 6464 bug fix WGCH BEGIN
		unitPrice = String.valueOf(CommUtils.nullToZero(roomRate) - CommUtils.nullToZero(planTran.OptionTotal__c));
		// 2020/05/30 6464 bug fix WGCH END
	}
}
// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
				Id accMstRefId = planItemAccMstSyncMap.containsKey(pd.Id) 	? planItemAccMstSyncMap.get(pd.Id)
																			: pd.AccountMasterRef__c;
				String prodName = planItemAccMstProdNmMap.containsKey(pd.Id)? planItemAccMstProdNmMap.get(pd.Id)
																			: pd.AccountMasterRef__r.Name;
// 2020/05/29 多泊多見積BUGFIX WGCH BEGIN
// OPTION商品功能设定有效; && 当前PLANHEADER含有SYNC就处理重置动作
if(CommConst.REDUCED_TAXRATE_FLG && CommConst.OPTION_MODE == CommConst.OPTION_MODE_ON && !CommUtils.isBlank(planTran.PlanDetailSyncInfo__c)){
	// PLAN明细ID:单价:商品ID:商品名字;
	nwPlanDetailSyncInfo += pd.Id + ':' + unitPrice + ':' + accMstRefId + ':' + prodName + ';';
}
// 2020/05/29 多泊多見積BUGFIX WGCH END
// 設定した金額は元の金額と違う場合、該当データの見積もり明細の総金額は再計算する
				planSummary += CommUtils.nullToZero(unitPrice);
				// 2014/08/06   単価定義区分に従って、過去見積もり明細金額変更あり不具合修正 BEGIN
				CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(planTran.UnitPriceDefKbCal__c));
				// 2014/08/06   単価定義区分に従って、過去見積もり明細金額変更あり不具合修正 END
	        	// プラン金額から単価区分により、金額再計算を行う
//2017/04/24 見積もり明細効率改修　by zy BEGIN
        		String searchKey = CommUtils.nullToZero(unitPrice) + '_' + CommUtils.nullToZero(planTran.Amount__c) + '_' + pd.TaxRate__c  + '_' + pd.ServiceRate__c;
	        	Decimal spTotal = 0;
	        	if (!detailSkipMap.containsKey(searchKey)) {
	        		priceInfo.process(CommUtils.nullToZero(unitPrice) , CommUtils.nullToZero(planTran.Amount__c), pd.TaxRate__c, pd.ServiceRate__c);
	        	 	spTotal = priceInfo.priceIncTax;
	        	 	detailSkipMap.put(searchKey,spTotal);
	        	} else {
	        		spTotal = detailSkipMap.get(searchKey);
	        	}
//2017/04/24 見積もり明細効率改修　by zy END
	        	// 消費税の設定に関して、再確認が必要です[TODO]プラン明細定義から
	        	insLst.add(new BookingEstimateItem__c(
	                refBooking__c = planTran.refBooking__c,                 // ご予約
	                UnitPriceDefKb__c = planTran.UnitPriceDefKbCal__c,		// 単価定義区分の自動設定
	                refAccountMaster__c  = accMstRefId,	//pd.AccountMasterRef__c,          // 商品コード
	                ActionType__c = pd.AccountMasterRef__r.ActionType__c,   // 商品処理種別
	                TaxRate__c = pd.TaxRate__c,                             // 消費税
	                ServiceRate__c = pd.ServiceRate__c,                     // サービス料
	                // 2013/01/21 商品単価：プラン明細に入力金額に設定する・合計金額：単価＊プランの数量
	                //Field20__c = String.valueOf(pd.Price__c),				// 単価
	                // 2013/01/25 明細単価入力可能するため、単価設定方法が変更を行う
	                UnitPrice__c = CommUtils.nullToZero(unitPrice),								// 単価
	                //Field20__c = (pd.AccountMasterRef__r.Field5__c == null ? null : String.valueOf(pd.AccountMasterRef__r.Field5__c)),      // 単価(税込)
		            Amount__c = (planTran.Amount__c == null ? null : planTran.Amount__c),  // 数量
		            //SpTotal__c = CommUtils.nullToZero(unitPrice) * CommUtils.nullToZero(planTran.Amount__c),  // $合計金額(税込)
		            //2017/04/24 見積もり明細効率改修　by zy BEGIN
		            SpTotal__c = spTotal,  // $合計金額(税込)
		            //2017/04/24 見積もり明細効率改修　by zy END
		            //Field23__c = String.valueOf(pd.Price__c),               // $合計金額(税込)
	                ParentBookingItemRef__c = bookingItemId,                         // 親予約見積明細
	                ProductName__c = prodName, //pd.AccountMasterRef__r.Name,
	                X2_1__c =  pd.AccountMasterRef__r.Name,					 // 名称2(漢1)
	                Field4__c = pd.AccountMasterRef__r.Field4__c,    		 // リンクＤＰコード
	                PaymentType__c = pd.AccountMasterRef__r.PaymentType__c,	 // 支払種別(2015/02/09 ADD)
		            // --------- 初期値設定を行う ---------
		            // 商品種別 ->SCP(5) = '0'    M   ; SCP(5) != '0'   P
		            //Field2__c = (pd.AccountMasterRef__r.SCP_5__c == '0') ? 'M' : 'P',
		            // 処理種別１
		            //Field3__c = '1',
		            // 処理種別２
		            //Field4__c = '1',
		            // 消費税　種別(消費税＝０の場合、非課税/)
		            //Field27__c = (pd.AccountMasterRef__r.TaxRateCal__c == 0 ? '2' : '1'),
		            // POSNo.
		            //POSNo__c = CommUtils.getPosNoByComdefine(),
		            // 集計対象外
		           	NoneAccount__c = true
		            // 請求書非表示
		            //InvoiceNoShowFlg__c = true
					// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz BEGIN
					// 设定到着日为利用日
					,UseDate__c = planTran.UseDate__c != null ? planTran.UseDate__c : (planTran.UseDateCal__c != null ? planTran.UseDateCal__c.date() : null)
					// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz END
		        	));

	            } // End For :プラン含めの明細商品LOOP　END
// 2020/05/29 多泊多見積BUGFIX WGCH BEGIN
if(!CommUtils.isBlank(nwPlanDetailSyncInfo)){
	planPlanDetailSyncInfoMap.put(bookingItemId, nwPlanDetailSyncInfo);
}
// 2020/05/29 多泊多見積BUGFIX WGCH END 
// プランの金額は再更新を行う
planProdSummaryMap.put(bookingItemId,planSummary);

        	} // End For : 全部の商品（プラン）所属明細一覧処理END [for (Id bookingItemId : insPlanTranMap.keySet())]
        	
			if (!planProdSummaryMap.isEmpty()) {
				List<BookingEstimateItem__c> estPlanItems = [select id,SpTotal__c,UnitPrice__c from BookingEstimateItem__c where id in :planProdSummaryMap.keySet()];
				for (BookingEstimateItem__c est : estPlanItems) {
					est.SpTotal__c = null;
					est.UnitPrice__c = planProdSummaryMap.get(est.Id);
					// 2020/05/29 多泊多見積BUGFIX WGCH BEGIN
					// 当之前存在SYNC的时候, 重置最新的SYNC, 针对连泊室料单价变更
					if(planPlanDetailSyncInfoMap.containsKey(est.Id)){
						est.PlanDetailSyncInfo__c = planPlanDetailSyncInfoMap.get(est.Id);
					}
					// 2020/05/29 多泊多見積BUGFIX WGCH END
				}
				
				update estPlanItems;
			}
	
        }
        // 新規作成
        if (!insLst.isEmpty()) insert insLst;
    }
    // 2015/10/18 [プラン明細個別設定情報]により、プラン明細自動展開する・しない処理追加 BEGIN
    // プランのプラン明細自動展開対象するがどうかチエック用
    // TRUE:自動展開
    private boolean itemExpandCheck(String customStr) {
    	return !CommUtils.nullToBlank(customStr).startsWith(CommConst.CONST_PLANITEM_NOEXPAND);
    }
    // 2015/10/18 [プラン明細個別設定情報]により、プラン明細自動展開する・しない処理追加 END
	/**
	* プランの数量は所属する会計明細に連けする
	* after update (2013/01/19)
	**/
	public void syncNumsPlanToDetail(List<BookingEstimateItem__c> nwLst, List<BookingEstimateItem__c> odLst) {

		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'sptotal__c','amount__c','productname__c','refaccountmaster__c','unitprice__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.BookingEstimateItem__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
			return ;
		}
		// 2019/09/15 Security Check BY zyz END
		// 会計明細はプラン　AND　数量が変更する場合
    	// 見積もり明細ID（プラン）/BreakDown明細と金額情報を格納する
    	Map<Id, Decimal> planNumsTranMap = new Map<Id, Decimal>();
    	// プランの明細単価情報を維持する
		Map<Id, Map<Id, String>> planItemPriceMap = new Map<Id, Map<Id, String>>();
		// 見積もり明細ID（プラン）/BreakDown明細の最新の会計商品IDと商品名情報格納する
		Map<Id, Map<Id, String>> planItemProdIdMap = new Map<Id, Map<Id, String>>();
		Map<Id, Map<Id, String>> planItemProdNmMap = new Map<Id, Map<Id, String>>();
		// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz BEGIN
		Map<Id, Date> planDateTranMap = new Map<Id, Date>();
		// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz END
		
        for (Integer i = 0; i < nwLst.size(); i++) {
        	BookingEstimateItem__c nw =  nwLst[i];
        	//BookingEstimateItem__c od =  odLst[i];
        	// 2018/07/27 宿泊税計算 WGCH BEGIN
        	if (odLst != null) {
        		BookingEstimateItem__c od =  odLst[i];
        		// 処理対象外明細
        		if (nw.TriggerIsStopFlg__c != od.TriggerIsStopFlg__c) continue;
        	}
        	// 2018/07/27 宿泊税計算 WGCH END
        	
        	// 商品は「プラン」場合、処理対象になる
            //if (nw.ActionType__c == CommConst.PROD_ACTION_TYPE_PL &&
            //	nw.Field21__c != od.Field21__c) {
            if (nw.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) {
            	// 2015/10/18 [プラン明細個別設定情報]により、プラン明細自動展開する・しない処理追加 BEGIN
				if(!itemExpandCheck(nw.PlanDetailSyncInfo__c)) continue;
				// 2015/10/18 [プラン明細個別設定情報]により、プラン明細自動展開する・しない処理追加 END
            	// プラン商品の数量情報を格納する
            	planNumsTranMap.put(nw.Id, nw.Amount__c);
            	// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz BEGIN
            	planDateTranMap.put(nw.Id, nw.UseDate__c);
            	// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz END
        		Map<Id,String> planItemSyncMap = new Map<Id,String>();	// BreakDown明細ID/金額
        		Map<Id,String> planItemProdIdSyncMap = new Map<Id, String>();	// 個別設定の商品ID
        		Map<Id,String> planItemProdNmSyncMap = new Map<Id, String>();	// 個別設定の商品ID
        		if (!CommUtils.isBlank(nw.PlanDetailSyncInfo__c)) {
        			// １明細の商品IDと数量格納する
        			String planSynInfo = nw.PlanDetailSyncInfo__c.substringBeforeLast(';');
        			String[] prodInfoLst = planSynInfo.split(';');
        			for (String prodInfo : prodInfoLst) {
        				String[] prodItem = prodInfo.split(':');
        				Id itemId = (Id)prodItem[0]; // プラン明細ID OR 見積もり明細ID
        				planItemSyncMap.put(itemId, prodItem[1]);
        				if (prodItem.size() > 2) planItemProdIdSyncMap.put(itemId, prodItem[2]);
        				if (prodItem.size() > 3) planItemProdNmSyncMap.put(itemId, prodItem[3]);
        			}
        			planItemPriceMap.put(nw.Id, planItemSyncMap);
        			// 2014/06/23 ADD
        			planItemProdIdMap.put(nw.Id, planItemProdIdSyncMap);
        			planItemProdNmMap.put(nw.Id, planItemProdNmSyncMap);
        		}
            }
        }
        if (planNumsTranMap.isEmpty()) return;
        // 金額計算共通
        // 2014/08/06   単価定義区分に従って、過去見積もり明細金額変更あり不具合修正 BEGIN
    	//CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo();
    	// 2014/08/06   単価定義区分に従って、過去見積もり明細金額変更あり不具合修正 END
        // 該当プラン関連のプラン明細へ、数量連動更新を行う
        // 2014/11/17 プラン明細に課税・非課税混在のプラン金額（税込）計算対応
        Map<Id, List<BookingEstimateItem__c>> planHeaderMap = new Map<Id, List<BookingEstimateItem__c>>();
//2017/04/24 見積もり明細効率改修　by zy BEGIN
        map<String,Decimal> detailSkipMap = new map<String,Decimal>();
//2017/04/24 見積もり明細効率改修　by zy END       
        List<BookingEstimateItem__c> updLst = new List<BookingEstimateItem__c>();
        for (BookingEstimateItem__c tran : [select UnitPriceDefKbCal__c,ParentBookingItemRef__c,UnitPrice__c,TaxRate__c,ServiceRate__c, Amount__c, SpTotal__c,
        									ParentBookingItemRef__r.TaxRate__c,
        									ParentBookingItemRef__r.ServiceRate__c,
        									ParentBookingItemRef__r.UnitPriceDefKbCal__c,
        									ParentBookingItemRef__r.Amount__c
        									// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz BEGIN
        									,ParentBookingItemRef__r.UseDate__c	
        									,UseDate__c	
        									// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz END
        									from BookingEstimateItem__c where ParentBookingItemRef__c in :planNumsTranMap.keySet()]) {
        	// 順番は重要です、必ず単価を先に設定のする後に、合計値再計算を行う
        	if (planItemPriceMap.containsKey(tran.ParentBookingItemRef__c)) {
        		Map<Id,String> unitPriceMap = planItemPriceMap.get(tran.ParentBookingItemRef__c);
        		if (unitPriceMap.get(tran.Id) != null)  tran.UnitPrice__c = CommUtils.nullToZero(unitPriceMap.get(tran.Id));
        	}
        	if (planItemProdIdMap.containsKey(tran.ParentBookingItemRef__c)) {
        		Map<Id,String> planItemProdIdSyncMap = planItemProdIdMap.get(tran.ParentBookingItemRef__c);
        		if (planItemProdIdSyncMap.containsKey(tran.Id)) tran.refAccountMaster__c = planItemProdIdSyncMap.get(tran.Id);
        	}
        	if (planItemProdNmMap.containsKey(tran.ParentBookingItemRef__c)) {
        		Map<Id,String> planItemProdNmSyncMap = planItemProdNmMap.get(tran.ParentBookingItemRef__c);
        		if (planItemProdNmSyncMap.containsKey(tran.Id)) tran.ProductName__c = planItemProdNmSyncMap.get(tran.Id);
        	}
        	
	        // 2014/08/06   単価定義区分に従って、過去見積もり明細金額変更あり不具合修正 BEGIN
	    	CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(tran.UnitPriceDefKbCal__c));
	    	// 2014/08/06   単価定義区分に従って、過去見積もり明細金額変更あり不具合修正 END
	    	
        	// 数量を取得、更新を行う
        	tran.Amount__c = planNumsTranMap.get(tran.ParentBookingItemRef__c);
        	// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz BEGIN
        	tran.UseDate__c = planDateTranMap.get(tran.ParentBookingItemRef__c);
        	// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz END
			// 単価区分により、総金額再計算を行う
/* 2014/09/05 数量小数点機能対応	
        	priceInfo.process(CommUtils.nullToZero(tran.UnitPrice__c) , CommUtils.nullToIntZero(tran.Amount__c), tran.TaxRate__c, tran.ServiceRate__c);
*/
//2017/04/24 見積もり明細効率改修　by zy BEGIN
		// 2019/02/15 単価定義区分を設定bug改修 BY zyz BEGIN
		// String searchKey = CommUtils.nullToZero(tran.UnitPrice__c) + '_' + CommUtils.nullToZero(tran.Amount__c) + '_' + tran.TaxRate__c  + '_' + tran.ServiceRate__c;
		String searchKey = CommUtils.nullToZero(tran.UnitPrice__c) + '_' + CommUtils.nullToZero(tran.Amount__c) + '_' + tran.TaxRate__c  + '_' + tran.ServiceRate__c + '_' + tran.UnitPriceDefKb__c;
		// 2019/02/15 単価定義区分を設定bug改修 BY zyz END
		if (!detailSkipMap.containsKey(searchKey)) {
//2017/04/24 見積もり明細効率改修　by zy END
			priceInfo.process(CommUtils.nullToZero(tran.UnitPrice__c) , CommUtils.nullToZero(tran.Amount__c), tran.TaxRate__c, tran.ServiceRate__c);
        	// 金額：単価　＊　数量
        	//tran.SpTotal__c = CommUtils.nullToZero(tran.UnitPrice__c) * CommUtils.nullToZero(tran.Amount__c);
        	tran.SpTotal__c = priceInfo.priceIncTax;
//2017/04/24 見積もり明細効率改修　by zy BEGIN
			detailSkipMap.put(searchKey,priceInfo.priceIncTax);
		} else {
			tran.SpTotal__c = detailSkipMap.get(searchKey);
		} // End if (!detailSkipMap.containsKey(searchKey))
//2017/04/24 見積もり明細効率改修　by zy END
        	// 更新リストに追加する
        	updLst.add(tran);
        	// プラン明細はまとめる
        	// 2015/10/13 見積明細から非課税商品が存在する場合、該当商品の合計金額から消費税金額を計算して、計算後の金額はプラン利用総金額から外す
        	if (tran.TaxRate__c == 0) {
        		if (!planHeaderMap.containsKey(tran.ParentBookingItemRef__c)) planHeaderMap.put(tran.ParentBookingItemRef__c, new List<BookingEstimateItem__c>());
        		planHeaderMap.get(tran.ParentBookingItemRef__c).add(tran);
        	}
        }
        if (!updLst.isEmpty()) update updLst;
        
        // プラン合計値を更新処理を行う
        // プラン明細からプランの合計値計算を行う
        Map<Id, Decimal> updPlanHeaderSumMap = new Map<Id, Decimal>();
        for (Id planId : planHeaderMap.keySet()) {
        	Decimal noTaxSummary = 0;
        	// 非課税商品の合計値を合計する
        	for (BookingEstimateItem__c subItem : planHeaderMap.get(planId)) {
        		// 非課税商品の合計金額
        		noTaxSummary += CommUtils.nullToZero(subItem.UnitPrice__c);
        	}
        	if (noTaxSummary <= 0) continue;
        	// 非課税の合計値を格納する
        	updPlanHeaderSumMap.put(planId ,noTaxSummary);
        }
        // 合計値計算後、プランへ反映する
        if (!updPlanHeaderSumMap.isEmpty()) {
        	
        	List<BookingEstimateItem__c> planHeaderLstRs = [select id, SpTotal__c,UnitPriceDefKbCal__c,UnitPrice__c,Amount__c,TaxRate__c,ServiceRate__c,SpecialTax__c from BookingEstimateItem__c where id = :updPlanHeaderSumMap.keySet()];
        	List<BookingEstimateItem__c> updPlanHeaderLst = new List<BookingEstimateItem__c>();
        	for (BookingEstimateItem__c header : planHeaderLstRs) {
        		//subItem.SpTotal__c = updPlanHeaderSumMap.get(subItem.Id);
        		CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(header.UnitPriceDefKbCal__c));
        		Decimal noTaxSummary = updPlanHeaderSumMap.get(header.Id);
        		Decimal planAmount = CommUtils.nullToZero(header.Amount__c);
        		Decimal planTaxRate = CommUtils.nullToZero(header.TaxRate__c);
        		Decimal planService = CommUtils.nullToZero(header.ServiceRate__c);
        		// 非課税商品の合計値
        		priceInfo.process(noTaxSummary, planAmount, 0, planService);
        		Decimal noTaxCalTotal = priceInfo.priceIncTax;
        		// 課税商品の合計値
        		Decimal incTaxSummary = CommUtils.nullToZero(header.UnitPrice__c) - noTaxSummary;
        		priceInfo.process(incTaxSummary, planAmount, planTaxRate, planService);
        		Decimal incTaxCalTotal = priceInfo.priceIncTax;
        		// 課税、非課税合計値は税込金額項目を設定を行う+特別税
        		Decimal calSpTotal = noTaxCalTotal + incTaxCalTotal + CommUtils.nullToZero(header.SpecialTax__c);
				// 合計金額を変更される場合、更新対象になる
        		if (header.SpTotal__c != calSpTotal) {
        			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
        			if(CommConst.REDUCED_TAXRATE_FLG) continue;
        			// 2019/07/30 軽減税率機能対応 WGCH END
        			header.SpTotal__c = calSpTotal;
        			updPlanHeaderLst.add(header);
        		}
        	}
        	if (!updPlanHeaderLst.isEmpty()) {
        		DataFixManagerUtils.stopTranTriggger();
        		update updPlanHeaderLst;
        		DataFixManagerUtils.begTranTriggger();
        	}
        }
	}
	// 2018/07/27 宿泊税計算 WGCH BEGIN
	// プラン明細の宿泊税からプランに反映対応
	public void planDetailToPlanHeader(List<BookingEstimateItem__c> nwLst, List<BookingEstimateItem__c> odLst, CommConst.TriggerMethod act) {
		// 宿泊税情報を未定義の場合、処理中止
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'triggerisstopflg__c','sptotal__c','specialtax__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.BookingEstimateItem__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
			return ;
		}
		// 2019/09/15 Security Check BY zyz END
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		if(CommConst.REDUCED_TAXRATE_FLG) return;
		// 2019/07/30 軽減税率機能対応 WGCH END
		map<string,CommLogicProcess.HotelTaxDefineInfo> hotelTax = CommLogicProcess.getHotelTaxDefInstance();
		if (hotelTax.isEmpty()) return;
		
		map<Id,Decimal> planHeaderMap = new map<Id, Decimal>();
        for (Integer i = 0; i < nwLst.size(); i++) {
        	BookingEstimateItem__c nw =  nwLst[i];
       		if (odLst != null) {
        		BookingEstimateItem__c od =  odLst[i];
        		// 処理対象外明細
        		if (nw.TriggerIsStopFlg__c != od.TriggerIsStopFlg__c) continue;
        	}
			// プラン明細　かつ　明細の商品タイプは室料場合、宿泊税値合計値を自動計算を行う
			Id planId = nw.ParentBookingItemRef__c;
			if (!CommUtils.isBlank(planId) && RackRateUtils.isRoomRateProduct(nw.ActionType__c)) {
				// 宿泊税が存在する場合
				Decimal specialTax = CommUtils.nullToZero(nw.SpecialTax__c);
				if (specialTax <= 0) continue;
				
				if (!planHeaderMap.containsKey(planId)) planHeaderMap.put(planId, specialTax);
				else planHeaderMap.put(planId, (planHeaderMap.get(planId) + specialTax));
			}
		}
		
		if (planHeaderMap.isEmpty()) return;

		// 既存プラン情報を検索する
		if (!planHeaderMap.isEmpty()) {
			List<BookingEstimateItem__c> updPlanHeaderLst = new list<BookingEstimateItem__c>();
        	list<BookingEstimateItem__c> planHeaders =  [	select id, SpecialTax__c,SpTotal__c,TriggerIsStopFlg__c,ParentBookingItemRef__c
        													from BookingEstimateItem__c 
        													where id in :planHeaderMap.keySet()];
        	for (BookingEstimateItem__c est : planHeaders) {
				// 宿泊税情報合計
        		Decimal specTax = 0;
        		Id parentId = est.Id;
        		// 宿泊税情報が非存在場合
        		if (!planHeaderMap.containsKey(parentId)) specTax = 0;
        		else specTax = planHeaderMap.get(parentId);
        		// 明細から合計した宿泊税はプランの宿泊税と一致しない場合、更新対象になる
        		if (specTax != est.SpecialTax__c) {
        			est.SpTotal__c = CommUtils.nullToZero(est.SpTotal__c) - CommUtils.nullToZero(est.SpecialTax__c) + specTax;
        			est.SpecialTax__c = specTax;
        			// 以外のトリガー処理は連動防止するため、フラグ項目を設定する
        			est.TriggerIsStopFlg__c = !est.TriggerIsStopFlg__c;
        			updPlanHeaderLst.add(est);
        		}
        	}
        	// 該当プランの明細の宿泊税合計値はプランHEADERに更新する
        	if (!updPlanHeaderLst.isEmpty()) {
        		DataFixManagerUtils.stopTranTriggger();
        		update updPlanHeaderLst;
        		DataFixManagerUtils.begTranTriggger();
        	}
		}
	}
	// 2018/07/27 宿泊税計算 WGCH END
	
	public Map<Id, AccountMaster__c> getAccMstInfoMap(Set<Id> accMstIdSet) {
		return new Map<Id, AccountMaster__c>(
				[ SELECT
					a.PaymentType__c,	// 2015/02/09 ADD[支払種別]
				    a.ActionType__c,
				    a.proftPer__c,
				    a.nextitemcode__c,
				    a.jmstRef__c,
				    a.detail13__c,
				    a.X4_3__c,
				    a.X3_2__c,
				    a.X1__c,
				    a.TaxRateCal__c,
				    a.SystemModstamp,
				    a.StsTaxfee__c,
				    a.SpecialTax__c,
				    a.ServiceRate__c,
				    a.SalesnoneTax__c,
				    a.SCP_5__c,
				    a.Profit__c,
				    a.PLU__c,
				    a.OwnerId,
				    a.OP__c,
				    a.OES__c,
				    a.Name,
				    a.KD__c,
				    a.Id,
				    a.Genkaritsu__c,
				    a.GPChange__c,
				    a.Field9__c,
				    a.Field8__c,
				    a.Field7__c,
				    a.Field6__c,
				    a.Field5__c,
				    a.Field4__c,
				    a.Field3__c,
				    a.Field2__c,
				    a.Field13_del__c,
				    a.Field12__c,
				    a.Field11__c,
				    a.Field10__c,
				    a.DPChange__c
				    // 2019/10/30 明細入力時に自動で反映 WGCH BEGIN
				    ,a.GPChange__r.Name
				    ,a.DPChange__r.Name
				    ,a.OP__r.Name
				    // 2019/10/30 明細入力時に自動で反映 WGCH END
				FROM AccountMaster__c a Where id in :accMstIdSet ]);


	}
	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
	public void updataPlanBrkToHeader(List<BookingEstimateItem__c> nwLst, List<BookingEstimateItem__c> odLst, CommConst.TriggerMethod act) {
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'planbrkinfo__c','triggerisstopflg__c','specialtax__c','sptotal__c','tankanonetaxnew__c','unitprice__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.BookingEstimateItem__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
			return ;
		}
		// 2019/09/15 Security Check BY zyz END
		if(!CommConst.REDUCED_TAXRATE_FLG) return;
		map<string,CommLogicProcess.HotelTaxDefineInfo> hotelTaxMap = CommLogicProcess.getHotelTaxDefInstance();
		map<Id, List<BookingEstimateItem__c>> planBrkMap = new map<Id, List<BookingEstimateItem__c>>();
		for (Integer i = 0; i < nwLst.size(); i++) {
			BookingEstimateItem__c nw =  nwLst[i];
			if (odLst != null) {
				BookingEstimateItem__c od =  odLst[i];
				// 処理対象外明細
				if (nw.TriggerIsStopFlg__c != od.TriggerIsStopFlg__c) continue;
			}
			// プラン明細　かつ　明細の商品タイプは室料場合、宿泊税値合計値を自動計算を行う
			Id planId = nw.ParentBookingItemRef__c;
			if (!CommUtils.isBlank(planId)) {
				if (!planBrkMap.containsKey(planId)) planBrkMap.put(planId, new List<BookingEstimateItem__c>());
				planBrkMap.get(planId).add(nw);
			}
		}
		// 既存プラン情報を検索する
		if (!planBrkMap.isEmpty()) {
			
			list<BookingEstimateItem__c> planHeaderLst =  [	select id, UnitPrice__c, TankanonetaxNew__c, SpTotal__c,  SpecialTax__c, TriggerIsStopFlg__c
															// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
															, Amount__c, TaxRate__c, ServiceRate__c, UnitPriceDefKbCal__c
															// 2019/10/02 PlanHeader算法切换对应 WGCH END
															// 2020/01/30 标准页面保存修正 WGCH BEGIN
															,(select Id from ParentBookingItemRef__r)
															// 2019/01/30 标准页面保存修正 WGCH END
															from BookingEstimateItem__c 
															where id in :planBrkMap.keySet()];
			list<BookingEstimateItem__c> updPlanHeaderLst = new list<BookingEstimateItem__c>();
			// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
			Boolean planBrkToHeaderCalFlg = CommConst.PLAN_BRKTOHEADER_CAL_FLG;
			// 2019/10/02 PlanHeader算法切换对应 WGCH END
			for (BookingEstimateItem__c plan : planHeaderLst) {
				if(!planBrkMap.containsKey(plan.Id)) continue;
				plan.UnitPrice__c = 0;
				plan.TankanonetaxNew__c = 0;
				plan.SpTotal__c = 0;
				plan.SpecialTax__c = 0;
				plan.TriggerIsStopFlg__c = !plan.TriggerIsStopFlg__c;
				plan.PlanBrkInfo__c = '';
				// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
				// 2020/01/30 标准页面保存修正 WGCH BEGIN
				Integer updateSize = planBrkMap.get(plan.Id).size(); // 当前plan对应的更新明细数量
				Integer hasdateSize = (plan.ParentBookingItemRef__r).size(); // 当前plan对应的明细数量
				// 处理size与存在的数量不等时跳出处理
				if(updateSize != hasdateSize) continue;
				// 2020/01/30 标准页面保存修正 WGCH END
				if(planBrkToHeaderCalFlg){
					for(BookingEstimateItem__c brk : planBrkMap.get(plan.Id)){
						CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(brk.UnitPriceDefKbCal__c));
						CommLogicProcess.HotelTaxInfo hotelTaxItem = CommLogicProcess.getHotelTaxInfo(CommUtils.nullToBlank(brk.ShopCodeCal__c), CommUtils.nullToBlank(brk.ActionType__c), CommUtils.nullToZero(brk.UnitPrice__c), CommUtils.nullToZero(brk.Amount__c), brk.TaxRate__c, brk.ServiceRate__c, priceInfo, hotelTaxMap);
						priceInfo = hotelTaxItem.priceInfo;
						plan.PlanBrkInfo__c =	CommUtils.nullToBlank(plan.PlanBrkInfo__c) +  // 原有累积的明细
												CommLogicProcess.getPlanBrkInfo(
													CommUtils.nullToBlank(brk.UnitPrice__c), // 単価
													CommUtils.nullToBlank(brk.TaxRate__c), // 消費税
													CommUtils.nullToBlank(brk.ServiceRate__c), // サービス料
													CommUtils.nullToBlank(brk.Amount__c), // 数量
													CommUtils.nullToBlank(hotelTaxItem.autoSetFlg ? hotelTaxItem.newNumSepcTaxSum : 0), // 特別税
													CommUtils.nullToBlank(brk.UnitPriceDefKbCal__c), // 会計商品単価定義区分
													CommUtils.nullToBlank(brk.refAccountMaster__c), // 会計商品Id
													CommUtils.nullToBlank(brk.ActionType__c) // 商品処理種別
												);
						plan.UnitPrice__c = CommUtils.nullToZero(plan.UnitPrice__c) + CommUtils.nullToZero(brk.UnitPrice__c);
						plan.TankanonetaxNew__c = CommUtils.nullToZero(plan.TankanonetaxNew__c) + priceInfo.unitPriceIncServiceExcTax;
						plan.SpTotal__c = CommUtils.nullToZero(plan.SpTotal__c) + priceInfo.priceIncTax;
						if(hotelTaxItem.autoSetFlg){
							plan.SpecialTax__c = CommUtils.nullToZero(plan.SpecialTax__c) + hotelTaxItem.newNumSepcTaxSum;
							plan.SpTotal__c = CommUtils.nullToZero(plan.SpTotal__c) + hotelTaxItem.newNumSepcTaxSum;
						}
					}
				} else {
					Decimal hasTaxUnitPrice = 0;
					Decimal noTaxUnitPrice = 0;
					for(BookingEstimateItem__c brk : planBrkMap.get(plan.Id)){
						Decimal brkTaxRate = CommUtils.nullToZero(brk.TaxRate__c);
						if(brkTaxRate > 0) hasTaxUnitPrice += CommUtils.nullToZero(brk.UnitPrice__c);
						else if(brkTaxRate == 0) noTaxUnitPrice += CommUtils.nullToZero(brk.UnitPrice__c);
						
						CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(brk.UnitPriceDefKbCal__c));
						CommLogicProcess.HotelTaxInfo hotelTaxItem = CommLogicProcess.getHotelTaxInfo(CommUtils.nullToBlank(brk.ShopCodeCal__c), CommUtils.nullToBlank(brk.ActionType__c), CommUtils.nullToZero(brk.UnitPrice__c), CommUtils.nullToZero(brk.Amount__c), (brkTaxRate > 0 ? plan.TaxRate__c : 0), plan.ServiceRate__c, priceInfo, hotelTaxMap);
						priceInfo = hotelTaxItem.priceInfo;
						plan.PlanBrkInfo__c =	CommUtils.nullToBlank(plan.PlanBrkInfo__c) +  // 原有累积的明细
												CommLogicProcess.getPlanBrkInfo(
													CommUtils.nullToBlank(brk.UnitPrice__c), // 単価
													CommUtils.nullToBlank(brk.TaxRate__c), // 消費税
													CommUtils.nullToBlank(brk.ServiceRate__c), // サービス料
													CommUtils.nullToBlank(brk.Amount__c), // 数量
													CommUtils.nullToBlank(hotelTaxItem.autoSetFlg ? hotelTaxItem.newNumSepcTaxSum : 0), // 特別税
													CommUtils.nullToBlank(brk.UnitPriceDefKbCal__c), // 会計商品単価定義区分
													CommUtils.nullToBlank(brk.refAccountMaster__c), // 会計商品Id
													CommUtils.nullToBlank(brk.ActionType__c) // 商品処理種別
												);
						if(hotelTaxItem.autoSetFlg){
							plan.SpecialTax__c = CommUtils.nullToZero(plan.SpecialTax__c) + hotelTaxItem.newNumSepcTaxSum;
						}
					}
					CommUtils.ProductInfo planPriceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(plan.UnitPriceDefKbCal__c));
					// 当前行含税单价计算处理
					planPriceInfo.process(hasTaxUnitPrice, CommUtils.nullToZero(plan.Amount__c), CommUtils.nullToZero(plan.TaxRate__c), CommUtils.nullToZero(plan.ServiceRate__c));
					plan.UnitPrice__c = CommUtils.nullToZero(hasTaxUnitPrice);
					plan.TankanonetaxNew__c = planPriceInfo.unitPriceIncServiceExcTax;
					plan.SpTotal__c = planPriceInfo.priceIncTax;
					// 当前行不含税单价计算处理
					planPriceInfo.process(noTaxUnitPrice, CommUtils.nullToZero(plan.Amount__c), 0, CommUtils.nullToZero(plan.ServiceRate__c));
					plan.UnitPrice__c = CommUtils.nullToZero(plan.UnitPrice__c) + CommUtils.nullToZero(noTaxUnitPrice);
					plan.TankanonetaxNew__c = CommUtils.nullToZero(plan.TankanonetaxNew__c) + planPriceInfo.unitPriceIncServiceExcTax;
					plan.SpTotal__c = CommUtils.nullToZero(plan.SpTotal__c) + planPriceInfo.priceIncTax + CommUtils.nullToZero(plan.SpecialTax__c);
				}
				// 2019/10/02 PlanHeader算法切换对应 WGCH END
				updPlanHeaderLst.add(plan);
			}
			if(!updPlanHeaderLst.isEmpty()){
				DataFixManagerUtils.stopTranTriggger();
				update updPlanHeaderLst;
				DataFixManagerUtils.begTranTriggger();
			}
		}
	}
	// 2019/07/30 軽減税率機能対応 WGCH END
}