public with sharing class CancelRuleDefineUtil {
  
	private static final CancelRuleDefineUtil instance = new CancelRuleDefineUtil();
	
	private Map<String, List<CancelRuleDefine__c>> mapCancelRuleDef;
	private string defaultShopCode;
	// 店舗単位で勤怠情報を取得する
	public static List<CancelRuleDefine__c> getCancelRuleDefineByShopCode(String shopCd) {
	    if (instance.mapCancelRuleDef.containsKey(shopCd)) {
	        return instance.mapCancelRuleDef.get(shopCd);
	    } else if (instance.defaultShopCode != null) {
	       	return instance.mapCancelRuleDef.get(instance.defaultShopCode);
	    } else {
	    	return new List<CancelRuleDefine__c>();
	    }
	}
	
	private CancelRuleDefineUtil() {
		
    	mapCancelRuleDef = new Map<String, List<CancelRuleDefine__c>>();
    	List<CancelRuleDefine__c> wkd = CancelRuleDefine__c.getall().values();
    	for (CancelRuleDefine__c df : wkd) {
    		String shopCode = CommUtils.nullToBlank(df.shopCode__c);
    		if (defaultShopCode == null) defaultShopCode = shopCode;
    		if (!mapCancelRuleDef.containsKey(shopCode)) mapCancelRuleDef.put(shopCode, new List<CancelRuleDefine__c>());
    		mapCancelRuleDef.get(shopCode).add(df);
    	}
	}  
}