/**
* 商品出庫共通トリガー
* 
**/
public with sharing class ProductOutStockTriggerProcess {
	// 商品の加工品が存在する場合、関連の加工品連携処理を行う
	// 注意１LEVELまで対応する
	public void setStockInfo(List<ProductOutStock__c> nw, List<ProductOutStock__c> od, CommConst.TriggerMethod act) {
		Set<String> productSet = new Set<String>(); // 商品ID SET
		// 2018/12/15 販売単価对应 WGCH BEGIN
		// Set<String> outStockDtSet = new Set<String>(); // 売上日 SET
		Map<String, ProductOutStock__c> outStockMap = new Map<String, ProductOutStock__c>(); // KEY MAP
		// 2018/12/15 販売単価对应 WGCH END
		Map<String, Decimal> qtyOfStockMap = new Map<String, Decimal>(); // 商品ID + '_' + 売上日  => 最终变更的数量
		Map<String, Decimal> processedProductMap = new Map<String, Decimal>(); // 原材料商品ID => 最终变更的数量
		if(act == CommConst.TriggerMethod.IsInsert){ // 新規作業場合
			for(Integer i = 0; i < nw.size(); i++){
				ProductOutStock__c nwItem = nw[i];
				if(CommUtils.isBlank(nwItem.AccountMasterRef__c)) continue;
				// 2018/12/15 販売単価对应 WGCH BEGIN
				// String key = nwItem.AccountMasterRef__c + '_' + nwItem.OutStockDate__c; // 合成Key
				String key = getKey(nwItem); // 合成Key
				// 2018/12/15 販売単価对应 WGCH END
				qtyOfStockMap.put(key, CommUtils.nullToZero(nwItem.ProductNumber__c));
				productSet.add(nwItem.AccountMasterRef__c); // 获取商品ID ADD
				// 2018/12/15 販売単価对应 WGCH BEGIN
				// outStockDtSet.add(nwItem.OutStockDate__c); // 获取売上日 ADD
				if(!outStockMap.containsKey(getKeyEnd(nwItem))) outStockMap.put(getKeyEnd(nwItem), nwItem);
				// 2018/12/15 販売単価对应 WGCH END
				// 存在旧数据时处理
				if(od == null || od.isEmpty()) continue;
				ProductOutStock__c odItem = od[i];
				qtyOfStockMap.put(key, (CommUtils.nullToZero(nwItem.ProductNumber__c) - CommUtils.nullToZero(odItem.ProductNumber__c))); // 重置该商品对应的数量
			}
		}
		// 処理中止
		if (productSet.isEmpty()) return;
		// 2018/12/15 販売単価对应 WGCH BEGIN
		Map<String, ProcessedProduct__c> processedProductDataMap = new Map<String, ProcessedProduct__c>();
		// 查出加工品
		// List<ProcessedProduct__c> processedProductLst = [Select Id, ProductRef__c, ItemProdcutRef__c, Usage__c From ProcessedProduct__c Where ProductRef__c in: productSet And ItemProdcutRef__c != null and Usage__c > 0];
		List<ProcessedProduct__c> processedProductLst = [Select Id, ProductRef__c, ItemProdcutRef__c, Usage__c, ItemProdcutRef__r.SalesnoneTax__c From ProcessedProduct__c Where ProductRef__c in: productSet And ItemProdcutRef__c != null and Usage__c > 0];
		// 2018/12/15 販売単価对应 WGCH END
		// 処理中止
		if (processedProductLst.isEmpty()) return;
		Set<Id> processedProductSet = new Set<Id>(); // 原材料商品ID
		for(ProcessedProduct__c product : processedProductLst){
			// 2018/12/15 販売単価对应 WGCH BEGIN
			/*
			for(String outStockDt : outStockDtSet){
				String key = product.ProductRef__c + '_' + outStockDt; // 合成完成商品Key
				String itemKey = product.ItemProdcutRef__c + '_' + outStockDt; // 合成原材料商品Key
			*/
			// 集计原材料,对应的数据集
			processedProductDataMap.put(product.ItemProdcutRef__c, product);
			for(String outStockKey : outStockMap.keySet()){
				String key = product.ProductRef__c + '_' + outStockKey; // 合成完成商品Key
				String itemKey = product.ItemProdcutRef__c + '_' + outStockKey; // 合成原材料商品Key
			// 2018/12/15 販売単価对应 WGCH END
				if(!qtyOfStockMap.containsKey(key)) continue;
				if(!processedProductMap.containsKey(itemKey)) processedProductMap.put(itemKey, 0); // 为了处理重复商品
				Decimal wkUsage = processedProductMap.get(itemKey) + CommUtils.nullToZero(product.Usage__c) * qtyOfStockMap.get(key); // 算出此原材料一共用的数量;
				processedProductMap.put(itemKey, wkUsage); // 原材料商品,数量集计
				processedProductSet.add(product.ItemProdcutRef__c); 
			}
		}
		// 会計商品在庫情報のIDを取得、自動作成処理を行う
		StockChangeHelpUtils help = new StockChangeHelpUtils();
		// 商品在庫の親IDを取得する
		// map<商品ID、商品在庫ID>
		map<id,id> parentIdMap = help.getProdcutStockById(processedProductSet);
		// 加工品の在庫情報を自動登録する
		List<ProductOutStock__c> newProOutStockLst = new List<ProductOutStock__c>(); // 出库商品信息
		for(Id productId : parentIdMap.keySet()){ // 遍历当前的所有在库
			// 2018/12/15 販売単価对应 WGCH BEGIN
			/*
			for(String outStockDt : outStockDtSet){
				String outStockDtKey = productId + '_' + outStockDt;
				if(!processedProductMap.containsKey(outStockDtKey) || CommUtils.nullToIntZero(processedProductMap.get(outStockDtKey)) == 0) continue;
			*/
			ProcessedProduct__c processedProduct = processedProductDataMap.get(productId); // 获取原材料信息
			for(String outStockKey : outStockMap.keySet()){
				ProductOutStock__c outStock = outStockMap.get(outStockKey); // 获取主出库
				String itemKey = productId + '_' + outStockKey; // 合成完成商品Key
				// 2018/12/29 BugFix 数量は小数点の場合不具合対応 WSQ BEGNIN
				if(!processedProductMap.containsKey(itemKey) || CommUtils.nullToZero(processedProductMap.get(itemKey)) == 0) continue;
				//if(!processedProductMap.containsKey(itemKey) || CommUtils.nullToIntZero(processedProductMap.get(itemKey)) == 0) continue;
				// 2018/12/29 BugFix 数量は小数点の場合不具合対応 WSQ END
			// 2018/12/15 販売単価对应 WGCH END
				newProOutStockLst.add(new ProductOutStock__c(
											ProductStock__c = parentIdMap.get(productId),
											AccountMasterRef__c = productId,
											// 2018/12/15 販売単価对应 WGCH BEGIN
											// ProductNumber__c = processedProductMap.get(outStockDtKey),
											// OutStockDate__c = CommUtils.nullToBlank(outStockDt)
											ProductNumber__c = processedProductMap.get(itemKey)
											, OutStockDate__c = CommUtils.nullToBlank(outStock.OutStockDate__c)
											//, AccountAcountRef__c = outStock.AccountAcountRef__c
											, Tankanonetax__c = processedProduct == null ? 0 : CommUtils.nullToZero(processedProduct.ItemProdcutRef__r.SalesnoneTax__c)
											// 2018/12/15 販売単価对应 WGCH END
											));
			}
			
		}
		if(!newProOutStockLst.isEmpty()) {
			DataFixManagerUtils.stopTranTriggger();
			insert newProOutStockLst;
			DataFixManagerUtils.begTranTriggger();
		}
	}
	// 2018/12/15 販売単価对应 WGCH BEGIN
	// 商品ID_売上日_販売単価（税抜)でキーを返却する
	private String getKey(ProductOutStock__c outStock) {
		return (outStock.AccountMasterRef__c + '_' + getKeyEnd(outStock));
	}
	// 売上日_販売単価（税抜)でキーを返却する
	private String getKeyEnd(ProductOutStock__c outStock) {
		return (outStock.OutStockDate__c + '_' + CommUtils.nullToZero(outStock.Tankanonetax__c));
	}
	// 2018/12/15 販売単価对应 WGCH END
}