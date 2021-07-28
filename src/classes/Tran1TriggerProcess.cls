/***************************
* 会計明細トリガー関連の処理
* 2013.04.17 見積もり明細更新処理機能対応
* 2014.04.02 4.28プランのBreakDown商品の合計金額（単価区分３を計算する）
* 2014/09/05 数量小数点機能対応
* 2015/10/18 PLAN商品非課税商品明細含めする場合、対応を行う[プラン金額から税金を外す]【プラン明細課税、非課税混在対応】
*            [プラン明細個別設定情報]により、プラン明細自動展開する・しない処理追加
* 2016/12/19 プラン明細の非表示設定はプランタイトルと連動対応
* 2020/01/30 予約作成段階では「利用日」が入力
****************************/
// 2020/02/28 SITE機能対応　by zy BEGIN
public without sharing class Tran1TriggerProcess {
// 2020/02/28 SITE機能対応　by zy END
	// 2016/12/29 非表示機能とき、合計金額（税込）は０円でDBへ格納する、しない制御機能追加
	private static Boolean accountNoSetAmountWhenNoShowFlg{get{return CommDefine__c.getOrgDefaults().AccountNoSetAmountWhenNoShow__c;}}
    // 2020/01/30 非表示の一括解除、あるいは金額を0円にしない非表示設定の追加 WGCH BEGIN
	public final static String APPOTION_ACCOUNTNOSHOW_1 = CommConst.APPOTION_ACCOUNTNOSHOW_1;
	public static String accountNoSetAmountWhenNoShowMode{get{return CommConst.APPOTION_ACCOUNTNOSHOW_MODE;}}
    // 2020/01/30 非表示の一括解除、あるいは金額を0円にしない非表示設定の追加 WGCH END
    /**********************************************
    * プラン会計商品を登録されている場合、
    * 該当プラン関連の会計明細商品は会計明細に自動追加する
    * After Insert/[After Update]/Before Delete
    ***********************************************/
    public void expandPlanItem (List<Tran1__c> nw, List<Tran1__c> od, CommConst.TriggerMethod act) {
    	// 2019/09/15 Security Check BY zyz BEGIN
    	if (!CommSecurityUtils.isDeleteable(Tran1__c.getSObjectType())) {
    		return;
    	}
    	// 2019/09/15 Security Check BY zyz END
    	// 処理する会計商品に、会計商品（プラン）が存在する場合、プラン明細は自動会計明細へ追加する
    	// 会計明細ID/会計明細
    	Map<Id, Tran1__c> insPlanTranMap = new Map<Id, Tran1__c>();
    	// 会計明細のデータはプラン場合、該当IDは格納する<会計明細ID/プラン商品ID>
    	Map<Id, Id> tranPlanIdMap = new Map<Id,Id>();
    	// 会計明細（プラン）明細の数量連動設定
    	//Map<Id, String> tranPlanItemMap = new Map<Id, String>();
    	// 新規作業場合
    	if (act == CommConst.TriggerMethod.IsInsert ) {
	        for (Tran1__c tr : nw) {
	        	// 商品は「プラン」場合、処理対象になる
	            if (tr.ActionType__c == CommConst.PROD_ACTION_TYPE_PL && tr.PlanExpandFlg__c != true) {
	            	// 2015/10/18 [プラン明細個別設定情報]により、プラン明細自動展開する・しない処理追加 BEGIN
	            	if(!itemExpandCheck(tr.PlanDetailSyncInfo__c)) continue;
	            	// 2015/10/18 [プラン明細個別設定情報]により、プラン明細自動展開する・しない処理追加 END
	            	// プラン商品の情報を格納する
	            	insPlanTranMap.put(tr.id, tr);
	            	// 会計明細の参照している商品IDを取得する
	            	tranPlanIdMap.put(tr.id, tr.Field7__c);
	            }
	        }
    	}
    	// 更新作業場合[商品コード変更 && 変更前の商品タイプはプラン，該当プランがなくなるため、関連の明細データも一緒に削除する]
    	else if (act == CommConst.TriggerMethod.IsUpdate ) {
    		Set<Id> delPlanTranSet = new Set<Id>();
    		for (Integer i = 0; i < nw.size(); i++) {
    			Tran1__c nwItem = nw[i];
    			Tran1__c odItem = od[i];
    			// 2015/10/18 [プラン明細個別設定情報]により、プラン明細自動展開する・しない処理追加 BEGIN
    			// 商品変更なし、既存のプランの個別設定情報は無効、新設定の明細情報が有効の場合、
    			if (nwItem.Field7__c == odItem.Field7__c &&
    				itemExpandCheck(nwItem.PlanDetailSyncInfo__c) &&
    				itemExpandCheck(odItem.PlanDetailSyncInfo__c) != true) {
					// プラン商品の情報を格納する
	            	insPlanTranMap.put(nwItem.id, nwItem);
	            	// 会計明細の参照している商品IDを取得する
	            	tranPlanIdMap.put(nwItem.id, nwItem.Field7__c);
    				continue;		
    			}
    			// 2015/10/18 [プラン明細個別設定情報]により、プラン明細自動展開する・しない処理追加 END
				// 商品変更する場合
				if (nwItem.Field7__c == odItem.Field7__c) continue;
				// 変更前の商品はプラン場合 && 商品の商品種別はプラン場合
				if (odItem.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) {
					delPlanTranSet.add(odItem.Id);				
				}
				// 新商品の商品種別はプラン場合
				if (nwItem.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) {
					// プラン商品の情報を格納する
	            	insPlanTranMap.put(nwItem.id, nwItem);
	            	// 会計明細の参照している商品IDを取得する
	            	tranPlanIdMap.put(nwItem.id, nwItem.Field7__c);
				}
    			//if (!delPlanTranSet.isEmpty()) delete [select id from Tran1__c where ParentTran1Ref__c in :delPlanTranSet];
    		}
    		// 2015/10/18 削除処理効率改善 BEGIN
    		if (!delPlanTranSet.isEmpty()) delete [select id from Tran1__c where ParentTran1Ref__c in :delPlanTranSet];
    		// 2015/10/18 削除処理効率改善 END
    	}
    	// 削除作業場合
    	else if (act == CommConst.TriggerMethod.IsDelete ) {
    		Set<Id> delPlanTranSet = new Set<Id>();
            for (Tran1__c tr : od) {
                // 商品は「プラン」場合、処理対象になる
                if (tr.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) {
                    delPlanTranSet.add(tr.Id);
                }
            }
            if (!delPlanTranSet.isEmpty()) delete [select id from Tran1__c where ParentTran1Ref__c in :delPlanTranSet];
            return;
    	}
    	// 処理対象データがない場合、処理終了
    	if (insPlanTranMap.isEmpty()) return;
    	// 関連処理を行う
    	// プラン明細情報を取得する[新規用情報]
    	// TODO：プラン明細設定画面に、消費税(参照関係)未設定するため、該当部份の対応が必要です
    	List<Tran1__c> insLst = new List<Tran1__c>();
    	Map<Id, List<PlanDetail__c>> planDetailMap = new Map<Id, List<PlanDetail__c>>();
        for (PlanDetail__c pd : [select Id, AccountMasterRef__c, AccountMasterRef__r.Name, AccountMasterRef__r.ActionType__c,
        						AccountMasterRef__r.SCP_5__c, AccountMasterRef__r.TaxRateCal__c,
        						AccountMasterRef__r.Field4__c,
                                AccountMasterRef__r.Field5__c, Price__c, TaxRate__c, JmstRef__c,
                                ServiceRate__c, ProductNumber__c, PlanProdcut__c
                                from PlanDetail__c where PlanProdcut__c in :tranPlanIdMap.values()]) {
            // 商品（プラン）非存在する場合
            if (!planDetailMap.containsKey(pd.PlanProdcut__c)) {
                List<PlanDetail__c> pdLst = new List<PlanDetail__c>();
                pdLst.add(pd);
                planDetailMap.put(pd.PlanProdcut__c, pdLst);
            } else {
                planDetailMap.get(pd.PlanProdcut__c).add(pd);
            }
        }
        if (!planDetailMap.isEmpty()) {
			// 金額計算共通
			// 2014/08/06   単価定義区分に従って、過去見積もり明細金額変更あり不具合修正 BEGIN
        	//CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo();
        	// 2014/08/06  単価定義区分に従って、過去見積もり明細金額変更あり不具合修正 END
        	// 新規場合
        	// 商品（プラン）の会計明細データから、関連所属プラン明細データはDBへ反映する
        	for (Id tranId : insPlanTranMap.keySet()) {
                // 商品（プラン）IDを取得する
        		Id planProdId = tranPlanIdMap.get(tranId);
        		// 商品（プラン）に所属するプラン明細が非存在する場合
        		if (!planDetailMap.containsKey(planProdId)) continue;
	            // 商品（プラン）の会計明細情報を取得する
	            Tran1__c planTran = insPlanTranMap.get(tranId);
        		// プラン明細の個別設定情報の存在チェック ADD 2013/01/25
        		Map<Id,String> planItemSyncMap = new Map<Id,String>();
        		// 2019/12/30 会計機能、会計画面でプランの内訳を編集出来るように WGCH BEGIN
        		// プラン明細→会計商品設定情報の存在チェック
        		Map<Id, Id> planItemAccMstSyncMap = new Map<Id, Id>();
        		// Map<プラン明細ID/会計商品名>
        		Map<Id, String> planItemAccMstProdNmMap = new Map<Id, String>();
        		// 2019/12/30 会計機能、会計画面でプランの内訳を編集出来るように WGCH END
        		if (!CommUtils.isBlank(planTran.PlanDetailSyncInfo__c)) {
        			// １明細の商品IDと数量格納する
        			String planSynInfo = planTran.PlanDetailSyncInfo__c.substringBeforeLast(';');
        			String[] prodInfoLst = planSynInfo.split(';');
        			for (String prodInfo : prodInfoLst) {
        				String[] prodItem = prodInfo.split(':');
        				planItemSyncMap.put((Id)prodItem[0], prodItem[1]);
        				// 2019/12/30 会計機能、会計画面でプランの内訳を編集出来るように WGCH BEGIN
        				if (prodItem.size() > 2) {
        					planItemAccMstSyncMap.put((Id)prodItem[0], (Id)prodItem[2]); // 個別設定情報の「会計商品」ID
        				}
        				if (prodItem.size() > 3) {
        					planItemAccMstProdNmMap.put((Id)prodItem[0], prodItem[3]); // 個別設定情報の「会計商品」名
        				}
        				// 2019/12/30 会計機能、会計画面でプランの内訳を編集出来るように WGCH END
        			}
        		}
	            // 商品（プラン）に所属する明細商品リストを取得する
	            for (PlanDetail__c pd : planDetailMap.get(planProdId)) {
	            	// 該当プラン明細商品の単価設定値を個別取得、設定を行う
	            	String unitPrice = planItemSyncMap.containsKey(pd.Id) ? planItemSyncMap.get(pd.Id) : String.valueOf(pd.Price__c);
	            	
					// 2014/08/06   単価定義区分に従って、過去見積もり明細金額変更あり不具合修正 BEGIN
		        	CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(planTran.UnitPriceDefKbCal__c));
		        	// 2014/08/06  単価定義区分に従って、過去見積もり明細金額変更あり不具合修正 END
	        		// プラン金額から単価区分により、金額再計算を行う
	        		priceInfo.process(CommUtils.nullToZero(unitPrice) , 1, pd.TaxRate__c, pd.ServiceRate__c);
	        		// 2019/12/30 会計機能、会計画面でプランの内訳を編集出来るように WGCH BEGIN
	        		Id accMstRefId = planItemAccMstSyncMap.containsKey(pd.Id) 	? planItemAccMstSyncMap.get(pd.Id)
	        																	: pd.AccountMasterRef__c;
	        		String prodName = planItemAccMstProdNmMap.containsKey(pd.Id)? planItemAccMstProdNmMap.get(pd.Id)
	        																	: pd.AccountMasterRef__r.Name;
	        		// 2019/12/30 会計機能、会計画面でプランの内訳を編集出来るように WGCH END
	        	// 消費税の設定に関して、再確認が必要です[TODO]プラン明細定義から
	        	insLst.add(new Tran1__c(
	                RelAccount__c = planTran.RelAccount__c,                 // 売上
	                Field1__c  = planTran.Field1__c,                        // 会計
	                // 2019/12/30 会計機能、会計画面でプランの内訳を編集出来るように WGCH BEGIN
	                // Field7__c  = pd.AccountMasterRef__c,                    // 商品コード
	                Field7__c  = accMstRefId,                    // 商品コード
	                // 2019/12/30 会計機能、会計画面でプランの内訳を編集出来るように WGCH END
	                ActionType__c = pd.AccountMasterRef__r.ActionType__c,   // 商品処理種別
	                TaxRate__c = pd.TaxRate__c,                             // 消費税
	                ServiceRate__c = pd.ServiceRate__c,                     // サービス料
	                // 2013/01/21 商品単価：プラン明細に入力金額に設定する・合計金額：単価＊プランの数量
	                //Field20__c = String.valueOf(pd.Price__c),				// 単価
	                // 2013/01/25 明細単価入力可能するため、単価設定方法が変更を行う
	                Field20__c = unitPrice,									// 単価
	                //Field20__c = (pd.AccountMasterRef__r.Field5__c == null ? null : String.valueOf(pd.AccountMasterRef__r.Field5__c)),      // 単価(税込)
		            Field21__c = (planTran.Field21__c == null ? null : planTran.Field21__c),  // 数量
		            //Field23__c = String.valueOf(CommUtils.nullToZero(unitPrice) * CommUtils.nullToZero(planTran.Field21__c)),  // $合計金額(税込)
		            Field23__c = String.valueOf( priceInfo.unitPriceTax * CommUtils.nullToZero(planTran.Field21__c)),  // $合計金額(税込)
		            //Field23__c = String.valueOf(pd.Price__c),               // $合計金額(税込)
	                ParentTran1Ref__c = tranId,                             // 親メニューコード	(名称を未設定する)
	                // 2019/12/30 会計機能、会計画面でプランの内訳を編集出来るように WGCH BEGIN
	                // Field5__c = pd.AccountMasterRef__r.Name,
	                Field5__c = prodName,
	                // 2019/12/30 会計機能、会計画面でプランの内訳を編集出来るように WGCH END
	                Field25__c = pd.AccountMasterRef__r.Field4__c,			// リンクＤＰコード
		            // --------- 初期値設定を行う ---------
		            // 商品種別 ->SCP(5) = '0'    M   ; SCP(5) != '0'   P
		            Field2__c = (pd.AccountMasterRef__r.SCP_5__c == '0') ? 'M' : 'P',
		            // 処理種別１
		            Field3__c = '1',
		            // 処理種別２
		            Field4__c = '1',
		            // 消費税　種別(消費税＝０の場合、非課税/)
		            Field27__c = (pd.AccountMasterRef__r.TaxRateCal__c == 0 ? '2' : '1'),
		            // POSNo.
		            POSNo__c = CommUtils.getPosNoByComdefine(),
		            // 集計対象外
		            noneaccount__c = true
		            // 請求書非表示
		            //InvoiceNoShowFlg__c = true
		        	));

	            } // End For :プラン含めの明細商品LOOP　END

        	} // End For : 全部の商品（プラン）所属明細一覧処理END
        }
        // 新規作成
        if (!insLst.isEmpty()) insert insLst;
    }
	/**
	* プランの数量は所属する会計明細に連けする
	* after update (2013/01/19)
	**/
	public void syncNumsPlanToDetail(List<Tran1__c> nwLst, List<Tran1__c> odLst) {
		// 2018/03/07 Security Check BEGIN
	    List<String> chkFields = new List<String>{'RelAccount__c','InvoiceNoShowFlg__c','Field23__c','Field21__c','Field20__c','Field1__c'};
	    Map<String,Schema.SObjectField> m = Schema.SObjectType.Tran1__c.fields.getMap();
	    if (!CommSecurityUtils.isCanUpdateable(chkFields, m)) {
			return;
	    }
	    // 2018/03/07 Security Check END	
		// 会計明細はプラン　AND　数量が変更する場合
    	// 会計明細ID/会計明細
    	Map<Id, String> planNumsTranMap = new Map<Id, String>();
    	// プランの明細単価情報を維持する
		Map<Id, Map<Id, String>> planItemPriceMap = new Map<Id, Map<Id, String>>();
		// 2019/12/30 会計機能、会計画面でプランの内訳を編集出来るように WGCH BEGIN
		// 会計明細ID（プラン）/BreakDown明細の最新の会計商品IDと商品名情報格納する
		Map<Id, Map<Id, String>> planItemProdIdMap = new Map<Id, Map<Id, String>>();
		Map<Id, Map<Id, String>> planItemProdNmMap = new Map<Id, Map<Id, String>>();
		// 2019/12/30 会計機能、会計画面でプランの内訳を編集出来るように WGCH END
		// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz BEGIN
		Map<Id, Date> planDateTranMap = new Map<Id, Date>();
		// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz END
		// プラン（親）関連の売上参照情報を格納する
		//Map<Id, Id> planRelaccountMap = new Map<Id, Id>();
		Map<Id, Tran1__c> parentPlanItemMap = new Map<Id, Tran1__c>();
        for (Integer i = 0; i < nwLst.size(); i++) {
        	Tran1__c nw =  nwLst[i];
        	// Tran1__c od =  odLst[i];
        	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
        	if (CommConst.REDUCED_TAXRATE_FLG && odLst != null) {
            	Tran1__c od =  odLst[i];
            	// 処理対象外明細
        		if (nw.TriggerIsStopFlg__c != od.TriggerIsStopFlg__c) continue;
        	}
        	if (CommConst.REDUCED_TAXRATE_FLG && nw.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) parentPlanItemMap.put(nw.Id, nw);
        	// 2019/07/30 軽減税率機能対応 WGCH END
        	// 商品は「プラン」場合、処理対象になる
            //if (nw.ActionType__c == CommConst.PROD_ACTION_TYPE_PL &&
            //	nw.Field21__c != od.Field21__c) {
            if (nw.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) {
            	// 2015/10/18 [プラン明細個別設定情報]により、プラン明細自動展開する・しない処理追加 BEGIN
				if(!itemExpandCheck(nw.PlanDetailSyncInfo__c)) continue;
				// 2015/10/18 [プラン明細個別設定情報]により、プラン明細自動展開する・しない処理追加 END
            	// プラン商品の数量情報を格納する
            	planNumsTranMap.put(nw.Id, nw.Field21__c);
        		Map<Id,String> planItemSyncMap = new Map<Id,String>();
        		// 2019/12/30 会計機能、会計画面でプランの内訳を編集出来るように WGCH BEGIN
        		Map<Id,String> planItemProdIdSyncMap = new Map<Id, String>();	// 個別設定の商品ID
        		Map<Id,String> planItemProdNmSyncMap = new Map<Id, String>();	// 個別設定の商品名
        		// 2019/12/30 会計機能、会計画面でプランの内訳を編集出来るように WGCH END
            	// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz BEGIN
            	planDateTranMap.put(nw.Id, nw.UseDate__c);
            	// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz END
        		if (!CommUtils.isBlank(nw.PlanDetailSyncInfo__c)) {
        			// １明細の商品IDと数量格納する
        			String planSynInfo = nw.PlanDetailSyncInfo__c.substringBeforeLast(';');
        			String[] prodInfoLst = planSynInfo.split(';');
        			for (String prodInfo : prodInfoLst) {
        				String[] prodItem = prodInfo.split(':');
        				planItemSyncMap.put((Id)prodItem[0], prodItem[1]);
        				// 2019/12/30 会計機能、会計画面でプランの内訳を編集出来るように WGCH BEGIN
        				Id itemId = (Id)prodItem[0]; // プラン明細ID OR 見積もり明細ID
        				if (prodItem.size() > 2) planItemProdIdSyncMap.put(itemId, prodItem[2]);
        				if (prodItem.size() > 3) planItemProdNmSyncMap.put(itemId, prodItem[3]);
        				// 2019/12/30 会計機能、会計画面でプランの内訳を編集出来るように WGCH END
        			}
        			planItemPriceMap.put(nw.Id, planItemSyncMap);
        			// 2019/12/30 会計機能、会計画面でプランの内訳を編集出来るように WGCH BEGIN
        			planItemProdIdMap.put(nw.Id, planItemProdIdSyncMap);
        			planItemProdNmMap.put(nw.Id, planItemProdNmSyncMap);
        			// 2019/12/30 会計機能、会計画面でプランの内訳を編集出来るように WGCH END
        		}
        		// 売上設定情報を格納する
        		//planRelaccountMap.put(nw.Id, nw.RelAccount__c);
        		parentPlanItemMap.put(nw.Id, nw);
            }
        }
        if (planNumsTranMap.isEmpty()) return;
        
        // 金額計算共通
        // 2014/08/06   単価定義区分に従って、過去見積もり明細金額変更あり不具合修正 BEGIN
    	//CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo();
    	// 2014/08/06   単価定義区分に従って、過去見積もり明細金額変更あり不具合修正 END
        // 該当プラン関連のプラン明細へ、数量連動更新を行う
        // 2014/11/17 プラン明細に課税・非課税混在のプラン金額（税込）計算対応
        Map<Id, List<Tran1__c>> planHeaderMap = new Map<Id, List<Tran1__c>>();//該当プランの非課税対象明細情報を格納する
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
        map<Id, List<Tran1__c>> planBrkMap = new map<Id, List<Tran1__c>>();
        map<string,CommLogicProcess.HotelTaxDefineInfo> hotelTaxMap = CommLogicProcess.getHotelTaxDefInstance();
        // 2019/07/30 軽減税率機能対応 WGCH END
        List<Tran1__c> updLst = new List<Tran1__c>();
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
        // for (Tran1__c tran : [select Field1__c,UnitPriceDefKbCal__c,ParentTran1Ref__c, Field21__c, Field20__c,TaxRate__c,ServiceRate__c from Tran1__c where ParentTran1Ref__c in :planNumsTranMap.keySet()]) {
        // 2020/01/30 予約作成段階では「利用日」が入力 BY zyz BEGIN
        for (Tran1__c tran : [select Field1__c,UnitPriceDefKbCal__c,ParentTran1Ref__c, Field21__c, Field20__c,TaxRate__c,ServiceRate__c,TankanonetaxNew__c,Field23__c,SpecialTax__c,TriggerIsStopFlg__c,ShopCodeCal__c,ActionType__c,UseDate__c from Tran1__c where ParentTran1Ref__c in :planNumsTranMap.keySet()]) {
        // 2020/01/30 予約作成段階では「利用日」が入力 BY zyz END
        // 2019/07/30 軽減税率機能対応 WGCH END
        	// 順番は重要です、必ず単価を先に設定のする後に、合計値再計算を行う
        	if (planItemPriceMap.containsKey(tran.ParentTran1Ref__c)) {
        		Map<Id,String> unitPriceMap = planItemPriceMap.get(tran.ParentTran1Ref__c);
        		if (unitPriceMap.get(tran.Id) != null)  tran.Field20__c = unitPriceMap.get(tran.Id);
        	}
        	// 2019/12/30 会計機能、会計画面でプランの内訳を編集出来るように WGCH BEGIN
        	if (planItemProdIdMap.containsKey(tran.ParentTran1Ref__c)) {
        		Map<Id,String> planItemProdIdSyncMap = planItemProdIdMap.get(tran.ParentTran1Ref__c);
        		if (planItemProdIdSyncMap.containsKey(tran.Id)) tran.Field7__c = planItemProdIdSyncMap.get(tran.Id);
        	}
        	if (planItemProdNmMap.containsKey(tran.ParentTran1Ref__c)) {
        		Map<Id,String> planItemProdNmSyncMap = planItemProdNmMap.get(tran.ParentTran1Ref__c);
        		if (planItemProdNmSyncMap.containsKey(tran.Id)) tran.Field5__c = planItemProdNmSyncMap.get(tran.Id);
        	}
        	// 2019/12/30 会計機能、会計画面でプランの内訳を編集出来るように WGCH END
        	// 2014/08/06   単価定義区分に従って、過去見積もり明細金額変更あり不具合修正 BEGIN
        	CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(tran.UnitPriceDefKbCal__c));
        	// 2014/08/06   単価定義区分に従って、過去見積もり明細金額変更あり不具合修正 END
        	// 売上のID連動設定
        	tran.RelAccount__c = parentPlanItemMap.get(tran.ParentTran1Ref__c).RelAccount__c;//planRelaccountMap.get(tran.ParentTran1Ref__c);
        	// 2015/06/24 参照している会計IDも連動する
        	tran.Field1__c = parentPlanItemMap.get(tran.ParentTran1Ref__c).Field1__c;
        	// 数量を取得、更新を行う
        	tran.Field21__c = planNumsTranMap.get(tran.ParentTran1Ref__c);
        	// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz BEGIN
        	tran.UseDate__c = planDateTranMap.get(tran.ParentTran1Ref__c);
        	// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz END
			// 単価区分により、総金額再計算を行う
/* 2014/09/05 数量小数点機能対応	
        	//priceInfo.process(CommUtils.nullToZero(tran.Field20__c) , CommUtils.nullToIntZero(tran.Field21__c), tran.TaxRate__c, tran.ServiceRate__c);
*/        	
			priceInfo.process(CommUtils.nullToZero(tran.Field20__c) , CommUtils.nullToZero(tran.Field21__c), tran.TaxRate__c, tran.ServiceRate__c);
        	// 金額：単価　＊　数量
        	//tran.Field23__c = String.valueOf(CommUtils.nullToZero(tran.Field20__c) * CommUtils.nullToZero(tran.Field21__c));
        	tran.Field23__c = String.valueOf(priceInfo.priceIncTax);
        	// 2016/12/19 プラン明細の非表示設定はプランタイトルと連動対応 BEGIN
        	tran.InvoiceNoShowFlg__c = parentPlanItemMap.get(tran.ParentTran1Ref__c).InvoiceNoShowFlg__c;
        	// 2016/12/19 プラン明細の非表示設定はプランタイトルと連動対応 END
        	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
        	// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
        	if(CommConst.PLAN_BRKTOHEADER_CAL_FLG && CommConst.REDUCED_TAXRATE_FLG && tran.ParentTran1Ref__c != null){
        	// 2019/10/02 PlanHeader算法切换对应 WGCH END
        		CommLogicProcess.HotelTaxInfo hotelTaxItem = CommLogicProcess.getHotelTaxInfo(CommUtils.nullToBlank(tran.ShopCodeCal__c), CommUtils.nullToBlank(tran.ActionType__c), CommUtils.nullToZero(tran.Field20__c), CommUtils.nullToZero(tran.Field21__c), tran.TaxRate__c, tran.ServiceRate__c, priceInfo, hotelTaxMap);
        		priceInfo = hotelTaxItem.priceInfo;
        		tran.TankanonetaxNew__c = priceInfo.unitPriceIncServiceExcTax;
        		tran.Field23__c = CommUtils.nullToBlank(priceInfo.priceIncTax);
        		tran.SpecialTax__c = 0;
        		if(hotelTaxItem.autoSetFlg){
        			tran.SpecialTax__c = hotelTaxItem.newNumSepcTaxSum;
        			tran.Field23__c = CommUtils.nullToBlank(priceInfo.priceIncTax + CommUtils.nullToZero(tran.SpecialTax__c));
        		}
        		tran.TriggerIsStopFlg__c = !tran.TriggerIsStopFlg__c;
        		if (!planBrkMap.containsKey(tran.ParentTran1Ref__c)) planBrkMap.put(tran.ParentTran1Ref__c, new List<Tran1__c>());
        		planBrkMap.get(tran.ParentTran1Ref__c).add(tran);
        	}
        	// 2019/07/30 軽減税率機能対応 WGCH END
        	// 更新リストに追加する
        	updLst.add(tran);
            // 2015/10/13 見積明細から非課税商品が存在する場合、該当商品の合計金額から消費税金額を計算して、計算後の金額はプラン利用総金額から外す
            if (tran.TaxRate__c == 0) {
        	   // プラン明細はまとめる
        	   if (!planHeaderMap.containsKey(tran.ParentTran1Ref__c)) planHeaderMap.put(tran.ParentTran1Ref__c, new List<Tran1__c>());
        	   planHeaderMap.get(tran.ParentTran1Ref__c).add(tran);
            }
        }
        update updLst;
        
        // プラン合計値を更新処理を行う
        // プラン明細からプランの合計値計算を行う
        Map<Id, Decimal> updPlanHeaderSumMap = new Map<Id, Decimal>();
        for (Id planId : planHeaderMap.keySet()) {
            Decimal noTaxSummary = 0;
            // 非課税商品の合計値を合計する
            for (Tran1__c subItem : planHeaderMap.get(planId)) {
                // 非課税商品の単価の合計金額
                noTaxSummary += CommUtils.nullToZero(subItem.Field20__c);
            }
            if (noTaxSummary <= 0) continue;
            // 非課税の合計値を格納する
            updPlanHeaderSumMap.put(planId ,noTaxSummary);
        }
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
        // 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
        if(CommConst.REDUCED_TAXRATE_FLG && CommConst.PLAN_BRKTOHEADER_CAL_FLG){
        // 2019/10/02 PlanHeader算法切换对应 WGCH END
        	updPlanHeaderSumMap = new Map<Id, Decimal>();
        	for (Id planId : planBrkMap.keySet()) {
        		Decimal noTaxSummary = 0;
        		for (Tran1__c subItem : planBrkMap.get(planId)) {
        			// 非課税商品の単価の合計金額
        			if(subItem.TaxRate__c == 0) noTaxSummary += CommUtils.nullToZero(subItem.Field20__c);
        		}
        		updPlanHeaderSumMap.put(planId ,noTaxSummary);
        	}
        }
        // 2019/07/30 軽減税率機能対応 WGCH END
        // 合計値計算後、プランへ反映する
        if (!updPlanHeaderSumMap.isEmpty()) {
            // List<Tran1__c> planHeaderLstRs = [select id, TotalPriceIncTax__c from Tran1__c where id = :updPlanHeaderSumMap.keySet()];
            // 2019/07/30 軽減税率機能対応 WGCH BEGIN
            // List<Tran1__c> planHeaderLstRs = [select id, InvoiceNoShowFlg__c,Field23__c,Field41__c, UnitPriceDefKbCal__c,Field20__c,Field40__c,TaxRate__c,ServiceRate__c,SpecialTax__c from Tran1__c where id = :updPlanHeaderSumMap.keySet()];
            List<Tran1__c> planHeaderLstRs = [select id, InvoiceNoShowFlg__c,Field23__c,Field41__c, UnitPriceDefKbCal__c,Field20__c,Field40__c,TaxRate__c,ServiceRate__c,SpecialTax__c,TankanonetaxNew__c,TriggerIsStopFlg__c from Tran1__c where id = :updPlanHeaderSumMap.keySet()];
            // 2019/07/30 軽減税率機能対応 WGCH END
            List<Tran1__c> updPlanHeaderLst = new List<Tran1__c>();
            for (Tran1__c header : planHeaderLstRs) {
            	// 2016/12/29 非表示機能とき、合計金額（税込）は０円でDBへ格納する、しない制御機能追加 BEGIN
            	// 2020/01/30 非表示の一括解除、あるいは金額を0円にしない非表示設定の追加 WGCH BEGIN
            	// if (header.InvoiceNoShowFlg__c && accountNoSetAmountWhenNoShowFlg) continue;
            	if ((accountNoSetAmountWhenNoShowMode == APPOTION_ACCOUNTNOSHOW_1) && header.InvoiceNoShowFlg__c && accountNoSetAmountWhenNoShowFlg) continue;
            	// 2020/01/30 非表示の一括解除、あるいは金額を0円にしない非表示設定の追加 WGCH END
            	// 2016/12/29 非表示機能とき、合計金額（税込）は０円でDBへ格納する、しない制御機能追加 END
                //subItem.SpTotal__c = updPlanHeaderSumMap.get(subItem.Id);
                CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(header.UnitPriceDefKbCal__c));
                Decimal noTaxSummary = updPlanHeaderSumMap.get(header.Id);
                Decimal planAmount = CommUtils.nullToZero(header.Field40__c);       // 数量
                Decimal planTaxRate = CommUtils.nullToZero(header.TaxRate__c);      // 消費税
                Decimal planService = CommUtils.nullToZero(header.ServiceRate__c);  // サビース料
                // 非課税商品の合計値
                priceInfo.process(noTaxSummary, planAmount, 0, planService);
                Decimal noTaxCalTotal = priceInfo.priceIncTax;
                // 課税商品の合計値
                // 単価の課税金額＝プランの元の単価ー単価の非課税金額
                Decimal incTaxSummary = CommUtils.nullToZero(header.Field20__c) - noTaxSummary;
                // 課税単価の税込み金額を計算する
                priceInfo.process(incTaxSummary, planAmount, planTaxRate, planService);
                Decimal incTaxCalTotal = priceInfo.priceIncTax;
                // 2019/07/30 軽減税率機能対応 WGCH BEGIN
                // 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
                if(CommConst.PLAN_BRKTOHEADER_CAL_FLG && planBrkMap.containsKey(header.Id)){
                // 2019/10/02 PlanHeader算法切换对应 WGCH END
                	header.Field20__c = '0';
                	header.TankanonetaxNew__c = 0;
                	header.Field23__c = '0';
                	header.SpecialTax__c = 0;
                	header.TriggerIsStopFlg__c = !header.TriggerIsStopFlg__c;
                	for(Tran1__c brk : planBrkMap.get(header.Id)){
                		header.Field20__c = CommUtils.nullToBlank(CommUtils.nullToZero(header.Field20__c) + CommUtils.nullToZero(brk.Field20__c));
                		header.TankanonetaxNew__c = CommUtils.nullToZero(header.TankanonetaxNew__c) + brk.TankanonetaxNew__c;
                		header.Field23__c = CommUtils.nullToBlank(CommUtils.nullToZero(header.Field23__c) + CommUtils.nullToZero(brk.Field23__c));
                		header.SpecialTax__c = CommUtils.nullToZero(header.SpecialTax__c)+ CommUtils.nullToZero(brk.SpecialTax__c);
	        		}
	        		header.Field49__c = 'noTaxCalTotal:::' + (CommUtils.nullToZero(header.Field23__c) - noTaxSummary) + '[] incTaxCalTotal:::' + noTaxSummary + '[]header.Field41__c:::' + header.Field41__c;
	        		updPlanHeaderLst.add(header);
	        		continue;
                }
                // 2019/07/30 軽減税率機能対応 WGCH END
                // 課税、非課税合計値は税込金額項目を設定を行う
                Decimal calSpTotal = noTaxCalTotal + incTaxCalTotal + CommUtils.nullToZero(header.SpecialTax__c);
                // 合計金額を変更される場合、更新対象になる
                if (header.Field41__c != calSpTotal) {
                    header.Field23__c = String.valueOf(calSpTotal);
                    
                    header.Field49__c = 'noTaxCalTotal:::' + noTaxCalTotal + '[] incTaxCalTotal:::' + incTaxCalTotal + '[]header.Field41__c:::' + header.Field41__c;
                    updPlanHeaderLst.add(header);
                }
            }
            if (!updPlanHeaderLst.isEmpty()) update updPlanHeaderLst;
        	
        }
	}
	
	// *************************************
	// 会計商品の設定情報から、会計明細にコピーを行う
	// *************************************
	public void syncAccountMstToTran1Item(List<Tran1__c> nwLst, List<Tran1__c> odLst, CommConst.TriggerMethod action){
        // 新規以外場合、処理中止
        if (action != CommConst.TriggerMethod.isInsert && action != CommConst.TriggerMethod.isUpdate) return;
        // 会計商品最新情報を取得する
        Set<Id> accMstSet = new Set<Id>();
        // 2016/04/13 JPY以外の場合、２桁小数の単価（税抜き）計算を行う BEGIN
        Integer locPointLen = CommUtils.getPointLen();
        // 2016/04/13 JPY以外の場合、２桁小数の単価（税抜き）計算を行う END
        for (Tran1__c item: nwLst) {
            accMstSet.add(item.Field7__c);
        }
        // 更新する場合
        Set<Id> chgProdIdSet = new Set<Id>();
        if (action == CommConst.TriggerMethod.isUpdate) {
        	// 会計明細を更新される場合
			for (Integer i =0; i<nwLst.size(); i++) {
				Tran1__c nw = nwLst[i];
				Tran1__c od = odLst[i];
				if (nw.Field7__c != od.Field7__c) chgProdIdSet.add(nw.Id);
			}
        }
        // 2019/10/30 明細入力時に自動で反映 WGCH BEGIN
        // String actQuery = CommSqlUtils.generateQueryString('AccountMaster__c') + ' Where id in :accMstSet ';
        String actQuery = CommSqlUtils.generateQueryString('AccountMaster__c', new String[]{'GPChange__r.Name','DPChange__r.Name','OP__r.Name'}) + ' Where id in :accMstSet ';
        // 2019/10/30 明細入力時に自動で反映 WGCH END
        Map<Id, AccountMaster__c> accMstMap = new Map<Id, AccountMaster__c>((List<AccountMaster__c>)DataBase.query(actQuery));

        // 新規作成の見積もり明細情報を自動設定を行う
        for (Integer i = 0; i < nwLst.size(); i++) {
            Tran1__c item = nwLst[i];
            // 2019/11/11 BUGFIEX修正 WGCH BEGIN
            item.TankanonetaxNew__c = 0;
            // 2019/11/11 BUGFIEX修正 WGCH END
            AccountMaster__c accMstItem = accMstMap.get(item.Field7__c);
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

			item.TargetCost__c = accMstItem.TargetCost__c;		// 原価率目標値
//            if (CommUtils.isBlank(item.DPChange__c)) item.DPChange__c =  accMstItem.DPChange__c;  // #DP
//            if (CommUtils.isBlank(item.Field10__c)) item.Field10__c =  accMstItem.Field10__c;  // 小計割引／割増
//            if (CommUtils.isBlank(item.Field11__c)) item.Field11__c =  accMstItem.Field11__c;  // ﾌﾘｰ宣言
//            if (CommUtils.isBlank(item.Field3__c)) item.Field3__c =  accMstItem.Field3__c;  // 商品コード

            item.Field25__c =  accMstItem.Field4__c;  // リンクＤＰコード
			// 2013/03/25 原価設定コピーを行う
			item.Field24__c = String.valueOf(accMstItem.Field7__c);
//            if (item.Field6__c == null) item.Field6__c =  accMstItem.Field6__c;  // ｻﾌﾞ単価
//            if (item.Field7__c == null) item.Field7__c =  accMstItem.Field7__c;  // 原価
//            if (item.Field8__c == null) item.Field8__c =  accMstItem.Field8__c;  // 単価2
//            if (CommUtils.isBlank(item.Field9__c)) item.Field9__c =  accMstItem.Field9__c;  // ｾｯﾄ宣言
			item.Field26__c =  accMstItem.GPChange__c;  // #GP

//            if (CommUtils.isBlank(item.OES__c)) item.OES__c =  accMstItem.OES__c;  // OES用ﾒﾆｭｰ
//            if (CommUtils.isBlank(item.OP__c)) item.OP__c =  accMstItem.OP__c;  // 会計OP
////          if (CommUtils.isBlank(item.OrderDate__c)) item.OrderDate__c =  accMstItem.OrderDate__c;  // 発注日
////          if (CommUtils.isBlank(item.Orderer__c)) item.Orderer__c =  accMstItem.Orderer__c;  // 発注者
//            if (CommUtils.isBlank(item.PLU__c)) item.PLU__c =  accMstItem.PLU__c;  // PLUｺｰﾄﾞ
//            if (CommUtils.isBlank(item.SCP_5__c)) item.SCP_5__c =  accMstItem.SCP_5__c;  // SCP(5)
			// 2016/01/19 新規&&商品種別は設定の場合、個別設定が不要
			if (!CommUtils.isBlank(item.Field2__c) && action == CommConst.TriggerMethod.isInsert) {	
			} else item.Field2__c = (accMstItem.SCP_5__c == '0') ? 'M' : 'P';  // SCP(5)
////          if (CommUtils.isBlank(item.SpTotal__c)) item.SpTotal__c =  accMstItem.SpTotal__c;  // #合計金額
////          if (CommUtils.isBlank(item.Supplier__c)) item.Supplier__c =  accMstItem.Supplier__c;  // 発注先
////          if (CommUtils.isBlank(item.Total__c)) item.Total__c =  accMstItem.Total__c;  // $合計金額(税込)
//            if (item.UnitPrice__c == null) item.UnitPrice__c =  accMstItem.Field5__c;  // 単価(税込)
//            if (CommUtils.isBlank(item.X1__c)) item.X1__c =  accMstItem.X1__c;  // 名称1(ｶﾅ)
//            if (CommUtils.isBlank(item.X2_1__c)) item.X2_1__c =  accMstItem.Name;  // 名称2(漢1)
//            if (CommUtils.isBlank(item.X3_2__c)) item.X3_2__c =  accMstItem.X3_2__c;  // 名称3(漢2)
//            if (CommUtils.isBlank(item.X4_3__c)) item.X4_3__c =  accMstItem.X4_3__c;  // 名称4(漢3)
////          if (CommUtils.isBlank(item.refAccountMaster__c)) item.refAccountMaster__c =  accMstItem.refAccountMaster__c;  // 商品名
//            if (item.ServiceRate__c == null) item.ServiceRate__c =  accMstItem.ServiceRate__c;  // サービス料(%)
			// 該当会計明細に新規　OR　既存の会計明細の商品IDを変更される場合、消費税最新情報を取得する
// 2019/09/18 軽減税率対応、チェックインにより、自動見積明細から会計明細を作成場合、コピー情報を対応 WSQ BEGIN
//			if (action == CommConst.TriggerMethod.isInsert || chgProdIdSet.contains(item.Id)) {
//				if (item.ParentTran1Ref__c == null) {	// Breakdown関連情報は情報更新を行わない
//			item.ServiceRate__c =  accMstItem.ServiceRate__c;  // サービス料(%)
//            if (item.SpecialTax__c == null) item.SpecialTax__c =  accMstItem.SpecialTax__c;  // 特別税
//            if (item.TaxRate__c == null) item.TaxRate__c =  accMstItem.TaxRateCal__c;  // 消費税*/
//			item.TaxRate__c =  accMstItem.TaxRateCal__c;  // 消費税*/
//				}
//			}
			if (action == CommConst.TriggerMethod.isInsert) {
				if (item.ServiceRate__c == null) item.ServiceRate__c =  accMstItem.ServiceRate__c;  // サービス料(%)
				if (item.TaxRate__c == null) item.TaxRate__c =  accMstItem.TaxRateCal__c;  // 消費税*/
				// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz BEGIN
				if (item.useDate__c == null && item.UseDateCal__c != null) item.useDate__c = item.UseDateCal__c;
				// 2020/01/30 予約作成段階では「利用日」が入力 BY zyz END
			} else if (chgProdIdSet.contains(item.Id)) {
				item.ServiceRate__c =  accMstItem.ServiceRate__c;  // サービス料(%)
				item.TaxRate__c =  accMstItem.TaxRateCal__c;  // 消費税*/
			}
// 2019/09/18 軽減税率対応、チェックインにより、自動見積明細から会計明細を作成場合、コピー情報を対応 WSQ END	
            // 消費税　種別(消費税＝０の場合、非課税/)
//            item.Field27__c = (accMstItem.TaxRateCal__c == 0 ? '2' : '1');
			item.Field27__c = (item.TaxRate__c == 0 ? '2' : '1');

//            if (CommUtils.isBlank(item.ActionType__c)) item.ActionType__c = accMstItem.ActionType__c;  // 商品処理種別
			item.ActionType__c = accMstItem.ActionType__c;  // 商品処理種別
			if (CommUtils.isBlank(item.Field5__c)) item.Field5__c =  accMstItem.Name;  // 名称2(漢1)
        }
        // 2016/04/13 JPY以外の場合、２桁小数の単価（税抜き）計算を行う BEGIN
        for (Tran1__c item: nwLst) {  
            // 単価（税抜き）金額は再計算して、設定を行う
            if (locPointLen > 0) {
            	CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(item.UnitPriceDefKbCal__c));
	            priceInfo.process(Commutils.nullToZero(item.Field20__c), item.Field40__c, item.TaxRate__c, item.ServiceRate__c);
	            item.TankawithoutTaxSys__c = priceInfo.unitPriceIncServiceExcTax; 
            }
        }
        // 2016/04/13 JPY以外の場合、２桁小数の単価（税抜き）計算を行う END
	}
	/**
	* 会計の予約情報から予約データの部屋設定をコピーを行う
	* Before Insert
	**/
	public void copyLeadInfoToTranItem(List<Tran1__c> nwLst, List<Tran1__c> odLst, CommConst.TriggerMethod action){
		// 該当会計明細の関連の会計の予約データ存在　＆＆　部屋情報を設定されている場合、会計明細に反映を行う
		Set<Id> accAcountIdSet = new Set<Id>();
		for (Tran1__c tran : nwLst) {
			accAcountIdSet.add(tran.Field1__c);
		}
		// 会計情報を取得する
		// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH BEGIN
		// 会计对应的Lock的FLG
		Map<String, Boolean> accErrorMap = new Map<String, Boolean>();
		// 获取管理员信息
		CommLogicProcess.AccountAdminInfo accAdminItem = CommLogicProcess.getAccountAdminInfo();
		// 获取锁定日期设定
		CommLogicProcess.ComDay comDayItem = new CommLogicProcess.ComDay();
		Boolean isLock = comDayItem.setComDay();
		List<AccountAcount__c> accLst = [select id, Relreserve__r.Rroom__c, SalesdayCal__c, ShopCode__c from AccountAcount__c where id in :accAcountIdSet];
		// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH END
		Map<Id, Id> accRoomMap = new Map<Id, Id>();
		for (AccountAcount__c acc : accLst) {
			// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH BEGIN
			// 设定Error成功跳出不可以变更PDF
			accErrorMap.put(acc.Id, CommLogicProcess.isAccLockFlg(acc, accAdminItem, comDayItem));
			if(acc.Relreserve__r.Rroom__c == null) continue;
			// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH END
			accRoomMap.put(acc.Id, acc.Relreserve__r.Rroom__c);
		}
		for (Tran1__c tran : nwLst) {
			if (accRoomMap.containsKey(tran.Field1__c)) {
				tran.Field6__c = accRoomMap.get(tran.Field1__c);
			}
			// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH BEGIN
			// 设定Error成功跳出不可以变更PDF
			if(accErrorMap.containsKey(tran.Field1__c) && accErrorMap.get(tran.Field1__c)){
				tran.addError(Label.MSG_006_0459);
				continue;
			}
			// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH END
		}
	}
    // 2015/10/18 [プラン明細個別設定情報]により、プラン明細自動展開する・しない処理追加 BEGIN
    // プランのプラン明細自動展開対象するがどうかチエック用
    // TRUE:自動展開
    private boolean itemExpandCheck(String customStr) {
        return !CommUtils.nullToBlank(customStr).startsWith(CommConst.CONST_PLANITEM_NOEXPAND);
    }
	// 2018/06/22 EXPO在庫機能対応 WGCH BEGIN
	public void setStockInfo(List<Tran1__c> nw, List<Tran1__c> od, CommConst.TriggerMethod act) {
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'productstock__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.ProductOutStock__c.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(chkFieldsLst, mm)) {
			return ;
		}
		// 2019/09/15 Security Check BY zyz END
		// 在庫連携フラグにより、連動処理中止
		if(!CommConst.STOCKSYNC_ISACTIVE_FLG) return;
		// 該当出庫情報を格納する
		map<String,ProductOutStock__c> merageOutStackMap = new map<String,ProductOutStock__c>();

		// 対象商品IDを格納する
		set<id> productIdSet = new set<Id>();
		if (act == CommConst.TriggerMethod.IsInsert) {
			// 該当商品の数量は出庫の「+」値として、連動が必要
			for (Tran1__c tran : nw) {
				// 新規追加の商品IDにより、対象リスト設定する
				productIdSet.add(tran.Field7__c);
				merageSameProduct(merageOutStackMap, tran, true);
			}
			
		} else if (act == CommConst.TriggerMethod.IsUpdate) {
			// 商品変更の場合、
			// 変更前の商品の数量は出庫の「-」値として、連動が必要
			// 変更前の商品の数量は出庫の「+」値として、連動が必要
			for(Integer i = 0; i < nw.size(); i++){
				Tran1__c nwItem = nw[i];
				Tran1__c odItem = od[i];
				// 参照商品を変更されない　AND　商品数量を変更されない
				if ((nwItem.Field7__c == odItem.Field7__c) && 
					// 2018/12/15 販売単価对应 WGCH BEGIN
					(CommUtils.nullToZero(nwItem.Tankanonetax__c) == CommUtils.nullToZero(odItem.Tankanonetax__c)) &&
					// 2018/12/15 販売単価对应 WGCH END
					(CommUtils.nullToZero(nwItem.Field40__c) == CommUtils.nullToZero(odItem.Field40__c))) continue;
				// 対象商品IDを格納する
				productIdSet.add(nwItem.Field7__c);
				productIdSet.add(odItem.Field7__c);
				// 商品変更される場合 OR 数量変更される場合、変更前の在庫は「-1」を返却、新た数量は「＋」に設定する
				merageSameProduct(merageOutStackMap, nwItem, true);
				merageSameProduct(merageOutStackMap, odItem, false);
			}
			
		} else if (act == CommConst.TriggerMethod.IsDelete) {
			// 該当商品の数量は出庫の「-」値として、連動が必要
			for (Tran1__c tran : od) {
				// 新規追加の商品IDにより、対象リスト設定する
				productIdSet.add(tran.Field7__c);
				merageSameProduct(merageOutStackMap, tran, false);
			}
		}
		// 処理対象がない場合、中止する
		if (productIdSet.isEmpty()) return;
		// 該当商品の商品在庫情報データをチェックする
		StockChangeHelpUtils help = new StockChangeHelpUtils();
		map<id,id> stockRelMap = help.getProdcutStockById(productIdSet);
		// 連携対象リストを作成する
		List<ProductOutStock__c> insLst = new List<ProductOutStock__c>();
		for (ProductOutStock__c outStock: merageOutStackMap.values()) {
			// 在庫値変更相殺場合、出庫へ連携しない
			if (outStock.ProductNumber__c == 0) continue;
			Id parentId = stockRelMap.get(outStock.AccountMasterRef__c);
			outStock.ProductStock__c = parentId;
			insLst.add(outStock);
		}
		if (!insLst.isEmpty()) insert insLst;
	}
	// 同じキーの商品の数量をマージする
	private void merageSameProduct(map<String,ProductOutStock__c> pMap, Tran1__c tran, Boolean isPlus) {
		String key = getKey(tran);
		if (!pMap.containsKey(key)) {
			pMap.put(key, 
				new ProductOutStock__c(
					AccountMasterRef__c = tran.Field7__c, //商品
					ProductNumber__c = ((isPlus ? 1 : -1) * CommUtils.nullToZero(tran.Field40__c)),//数量
					OutStockDate__c = tran.RsvSalesDateCal__c
					// 2018/12/15 販売単価对应 WGCH BEGIN
					//, AccountAcountRef__c = tran.Field1__c // レシートＮｏ．
					, Tankanonetax__c = CommUtils.nullToZero(tran.Tankanonetax__c) // $単価(税抜)
					// 2018/12/15 販売単価对应 WGCH END
					));
		} else { 
			// 数量加算する
			ProductOutStock__c outStock = pMap.get(key);
			outStock.ProductNumber__c +=  ((isPlus ? 1 : -1) * CommUtils.nullToZero(tran.Field40__c));
		}
	}
	// 商品ID_売上日_販売単価（税抜)でキーを返却する
	private string getKey(Tran1__c tran) {
		// 2018/12/15 販売単価对应 WGCH BEGIN
		// return (tran.Field7__c + '_' + tran.RsvSalesDateCal__c);
		return (tran.Field7__c + '_' + tran.RsvSalesDateCal__c + '_' + CommUtils.nullToZero(tran.Tankanonetax__c));
		// 2018/12/15 販売単価对应 WGCH END
	}
	// 2018/06/22 EXPO在庫機能対応 WGCH END
	// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH BEGIN
	public void compareSalesdayCalInfo(List<Tran1__c> nw, List<Tran1__c> od, CommConst.TriggerMethod act) {
		// 获取管理员信息
		CommLogicProcess.AccountAdminInfo accAdminItem = CommLogicProcess.getAccountAdminInfo();
		// 获取锁定日期设定
		CommLogicProcess.ComDay comDayItem = new CommLogicProcess.ComDay();
		if(comDayItem.setComDay()){
			// 該当会計明細の関連の会計の予約データ存在　＆＆　部屋情報を設定されている場合、会計明細に反映を行う
			Set<Id> accAcountIdSet = new Set<Id>();
			// 新数据
			List<Tran1__c> nwLst = null;
			// 旧数据
			List<Tran1__c> odLst = null;
			// 新規場合
			if(act == CommConst.TriggerMethod.IsInsert){
				nwLst = nw;
				odLst = od;
			}
			// 更新作業場合
			else if(act == CommConst.TriggerMethod.IsUpdate){
				nwLst = nw;
				odLst = od;
			}
			// 削除作業場合
			else if (act == CommConst.TriggerMethod.IsDelete ) {
				nwLst = od;
				odLst = od;
			}
			// 会计ID设定
			for (Tran1__c tran : nwLst) accAcountIdSet.add(tran.Field1__c);
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
				Tran1__c tran = nwLst[i];
				// 设定Error成功跳出不可以变更PDF
				if(accErrorMap.containsKey(tran.Field1__c) && accErrorMap.get(tran.Field1__c)){
					tran.addError(Label.MSG_006_0459);
					continue;
				}
			}
		}
	}
	// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH END
}