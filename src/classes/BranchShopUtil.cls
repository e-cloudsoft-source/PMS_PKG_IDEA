/**
* 支店関連設定、取得情報を処理する
**/
public with sharing class BranchShopUtil {
	/* 2014/08/28 未使用になる、ShopInfoUtilに変更する
	public BranchShopUtil() {
		setInitBranShopLst();
	}
	
    // 支店選択リスト
    public List<SelectOption> branchShopLst{get; private set;}
    public String branchShopNm{get; set;}
    public Boolean isShowShop{get{return !branchShopLst.isEmpty();}}
    private void setInitBranShopLst() {
    	branchShopLst = new List<SelectOption>();
        for (ShopInformation__c shop : [select id, name,ShopCode__c from ShopInformation__c order by Seq__c limit 5000]) {
 //		for (ShopInformation__c shop : [select id, name,ShopCode__c from ShopInformation__c where id = null order by Seq__c]) {
        	branchShopLst.add(new SelectOption(shop.ShopCode__c, shop.name));
        }
        if (!branchShopLst.isEmpty()) {
        	// 顧客に設定する支店で初期値に設定する[2013/06/30]
        	String locShopCode = UserUtil.CurrentUser.ShopCode__c;
        	for (SelectOption s : branchShopLst) {
        		if (s.getValue() == locShopCode) branchShopNm = locShopCode;
        	}
        }
    }*/
}