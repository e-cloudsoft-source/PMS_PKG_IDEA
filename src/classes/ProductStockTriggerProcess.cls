/**
* 会計商品在庫共通トリガー
* 既存注文に対して、キャンセルされる場合、EXPO在庫とNOEXPO在庫連動を行う
**/
public with sharing class ProductStockTriggerProcess {
	// 関連項目値の自動設定
	public void autoSetupProductStock(ProductStock__c[] newLst, ProductStock__c[] oldLst, CommConst.TriggerMethod action){
		if (CommConst.TriggerMethod.IsInsert == action || CommConst.TriggerMethod.IsUpdate == action) {
			for (ProductStock__c pro : newLst) {
				pro.ProductSfId__c = CommUtils.nullToBlank( pro.ProductRef__c );
			}
		}
	}
}