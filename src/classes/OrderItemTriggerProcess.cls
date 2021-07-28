/**
* 注文明細共通トリガー
* 新規注文が発生する場合、EXPO在庫とNOEXPO在庫連動を行う
**/
public with sharing class OrderItemTriggerProcess {
	// 注文明細により、在庫情報へ情報同期処理を行う
	// 注：該当注文明細は変更、削除は処理対象外と予想しております、原因は注文変更できない、必ずキャンセルして、新た注文が必要です
	// そのため、注文明細変更、データ直接削除することがありません
	public void setStockInfo(List<OrderItem__c> nw, List<OrderItem__c> od, CommConst.TriggerMethod act) {
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'productnumber__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.ProductOutStock__c.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(chkFieldsLst, mm)) {
			return ;
		}
		// 2019/09/15 Security Check BY zyz END
		// 在庫管理機能は無効の場合、連動処理中止
		if(!CommConst.STOCKSYNC_ISACTIVE_FLG) return;
		// 同じ商品・同じ受注日「OrderDateCal__c：注文データのCreateDate日」の商品合計値は出庫オブジェクトに反映する
		// 該当商品はEXPO商品の場合（Expo組織情報ID != null)、会計商品の「	Expo在庫数」項目へ反映を行う
		// EXPO商品：出庫情報に反映用：map<商品_注文日,出庫情報>
		map<string, ProductOutStock__c> outQtyOfStockMap = new map<string, ProductOutStock__c>();
		// NOEXPO商品:map<商品ID,変動数量値>
		map<string, decimal> noExpoQtyOfStockMap = new map<string, decimal>();
		// 新規の場合
		if (act == CommConst.TriggerMethod.IsInsert) {
			for (OrderItem__c item : nw) {
				// EXPO商品の場合
				if (CommUtils.isBlank(item.ExpoOrgInfoRefCal__c)) {
					// 商品出庫情報を作成する
					// KEYを設定する
					String key = getMergeKey(item);
					if (!outQtyOfStockMap.containsKey(key)) {
						ProductOutStock__c nwItem = new ProductOutStock__c(
							AccountMasterRef__c = item.AccountMasterRef__c,
							OutStockDate__c = CommUtils.dateToYYYYMMDD(item.OrderDateCal__c),
							ProductNumber__c = CommUtils.nullToZero(item.Qty__c)
							// 2018/12/15 販売単価对应 WGCH BEGIN
							//, OrderRef__c = item.RefParOrder__c // 注文
							, Tankanonetax__c = CommUtils.nullToZero(item.PriceNoTax__c) // 単価金額（税抜）
							// 2018/12/15 販売単価对应 WGCH END
						);
						outQtyOfStockMap.put(key, nwItem);
					
					} else {
						// マップ既存のクラスから数量加算する
						ProductOutStock__c nwItem = outQtyOfStockMap.get(key);
						nwItem.ProductNumber__c += CommUtils.nullToZero(item.Qty__c);
						outQtyOfStockMap.put(key, nwItem);
					}
				}
				// NOEXPO商品の場合
				else {
					String key = CommUtils.nullToBlank(item.AccountMasterRef__c);
					if (!noExpoQtyOfStockMap.containsKey(key)) noExpoQtyOfStockMap.put(key, CommUtils.nullToZero(item.Qty__c));
					else noExpoQtyOfStockMap.put(key, (noExpoQtyOfStockMap.get(key) + CommUtils.nullToZero(item.Qty__c)));
				}
			}
		} 
//System.debug(loggingLevel.info, 'outQtyOfStockMap='+outQtyOfStockMap);
//System.debug(loggingLevel.info, 'noExpoQtyOfStockMap='+noExpoQtyOfStockMap);
		// 処理対象データがない場合、処理中止
		if (outQtyOfStockMap.isEmpty() && noExpoQtyOfStockMap.isEmpty()) return;
		// EXPO商品出庫情報へ連携する　
		if (!outQtyOfStockMap.isEmpty()) {
			// 出庫情報に情報新規追加する
			// 該当日の商品の在庫情報リストを取得する
			list<ProductOutStock__c> insOutStockLst = outQtyOfStockMap.values();
			set<id> prodIds = new set<id>();
			for (ProductOutStock__c outstock : insOutStockLst) {
				prodIds.add(outstock.AccountMasterRef__c);
			}
			// 会計商品在庫情報のIDを取得、自動作成処理を行う
			StockChangeHelpUtils help = new StockChangeHelpUtils();
			// 商品在庫の親IDを取得する
			// map<商品ID、商品在庫ID>
			map<id,id> parentIdMap = help.getProdcutStockById(prodIds);
			for (ProductOutStock__c outstock : insOutStockLst) {
				outstock.ProductStock__c = parentIdMap.get(outstock.AccountMasterRef__c);
			}
//System.debug(loggingLevel.info, 'insOutStockLst='+insOutStockLst);
			insert insOutStockLst;
		}
		// NOEXPO商品は会計商品の在庫数を連動する
		if (!noExpoQtyOfStockMap.isEmpty()) {
			// 該当商品の在庫情報を減算する
			list<AccountMaster__c> expoAcclist = [select id, ExpoStockCount__c from AccountMaster__c where id in :noExpoQtyOfStockMap.keyset() for update];
			for (AccountMaster__c acc : expoAcclist) {
				acc.ExpoStockCount__c = CommUtils.nullToZero(acc.ExpoStockCount__c) - noExpoQtyOfStockMap.get(acc.Id);
			}
//System.debug(loggingLevel.info, 'expoAcclist='+expoAcclist);
			update expoAcclist;
		}
	}
	
	private string getMergeKey(OrderItem__c item) {
		// 2018/12/15 販売単価对应 WGCH BEGIN
		// 商品ID_受注日_単価金額（税抜）
		// return item.AccountMasterRef__c + '_' + CommUtils.dateToYYYYMMDD(item.OrderDateCal__c);
		return item.AccountMasterRef__c + '_' + CommUtils.dateToYYYYMMDD(item.OrderDateCal__c) + '_' + CommUtils.nullToZero(item.PriceNoTax__c);
		// 2018/12/15 販売単価对应 WGCH BEGIN
	}
}