/**
* 棚卸し同期バッチ機能2対応
* 該当バッチは【BulkStocktakingSyncBatch】経由で起動される
**/
public with sharing class BulkStocktakingLinkBatch implements Database.Batchable<Sobject>, Database.Stateful {
	// バッチ処理区分：INSTOCK 入力情報,OUSTOCK:出庫情報
	public enum BATCH_TYPE{INSTOCK,OUSTOCK}
	private String queryYmd;
	private BATCH_TYPE bType;
	// 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy BEGIN
	// 処理対象
	public Set<String> processIdSet;
	// 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy END
	// バッチインスタンス化
	// ymd:該当日付以前のデータの【集計対象外】フラグをONにする、書式：YYYYMMDD
	public BulkStocktakingLinkBatch(String ymd, BATCH_TYPE ptype) {
		queryYmd = ymd;
		bType = ptype;
	}

	// ***********************************
	// バッチ処理開始
	// ***********************************
	public Database.QueryLocator start(Database.BatchableContext BC){
		// 0件返却
		Date batchDate = CommUtils.stringtoDate(queryYmd);
		// 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy BEGIN
		// 該当締日以前の在庫データ
		// String qstr = 'select id,AccountMasterRef__c,StockDate__c from InventoryInfo__c where BatchDate__c = :batchDate';
		String qstr = 'select id,AccountMasterRef__c,StockDate__c from InventoryInfo__c where AccountMasterRef__c = :processIdSet';
		// 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy END
		return Database.getQueryLocator(qstr);
	}
	
	// ***********************************
	// バッチロジック処理開始
	// ***********************************
	public void execute(Database.BatchableContext BC, List<InventoryInfo__c> scope){
		Set<String> processIds = new set<String>();
		Map<String,String> invenDtMap = new Map<String,String>();
		Date maxDate = null;
		for (InventoryInfo__c inven : scope) {
			processIds.add(inven.AccountMasterRef__c);
			invenDtMap.put(inven.AccountMasterRef__c,dataToFormatString(inven.StockDate__c));
			// 棚卸日取得
			if (maxDate == null || maxDate < inven.StockDate__c) maxDate = inven.StockDate__c;
		}
		if (maxDate != null) queryYmd = dataToFormatString(maxDate);
		if (bType == BATCH_TYPE.INSTOCK) {
			String qstr = 'select id,AccountMasterRef__c,IsNotTarget__c,InStockDate__c from PurchaseDetail__c where InStockDate__c <= :queryYmd and IsNotTarget__c != true and AccountMasterRef__c in :processIds';
			List<PurchaseDetail__c> sobjects = Database.query(qstr);
			for (PurchaseDetail__c s : sobjects) {
				String accId = CommUtils.nullToBlank(s.AccountMasterRef__c);
				// 入庫日
				String dtStr = s.InStockDate__c;
				if (invenDtMap.containsKey(accId)) {
					String dtFormat = invenDtMap.get(accId);
					if (dtFormat >= dtStr) s.IsNotTarget__c = true;
				}
			}
			if (!sobjects.isEmpty()) update sobjects;
		}  else if (bType == BATCH_TYPE.OUSTOCK) {
			String qstr = 'select id,AccountMasterRef__c,IsNotTarget__c,OutStockDate__c from ProductOutStock__c where OutStockDate__c <= :queryYmd and IsNotTarget__c != true and AccountMasterRef__c in :processIds';
			List<ProductOutStock__c> sobjects = Database.query(qstr);
			for (ProductOutStock__c s : sobjects) {
				String accId = CommUtils.nullToBlank(s.AccountMasterRef__c);
				// 出庫日
				String dtStr = s.OutStockDate__c;
				if (invenDtMap.containsKey(accId)) {
					String dtFormat = invenDtMap.get(accId);
					// 2018/12/15 商品在庫、指定棚卸日以前のデータ対象外設定不能　by zy BEGIN
					if (dtFormat >= dtStr) s.IsNotTarget__c = true;
					// 2018/12/15 商品在庫、指定棚卸日以前のデータ対象外設定不能　by zy END
				}
			}
			if (!sobjects.isEmpty()) update sobjects;
		}
	}
	
	// ***********************************
	// バッチ終了処理開始
	// ***********************************
	public void finish(Database.BatchableContext BC){
		
	}
	private string dataToFormatString(Date curDt){
		if (curDt == null) return '';
		return (DateTime.newInstance(curDt.year(),curDt.month(),curDt.day())).format('yyyyMMdd');
	}
}