public class WorkTimeDefineUtil {

	private static final WorkTimeDefineUtil instance = new WorkTimeDefineUtil();
	
	private Map<String, WorkTimeDefine__c> mapWorkTimeDef;
	private static WorkTimeDefine__c defWorkTimeInfo;
	// 店舗単位で勤怠情報を取得する
	public static WorkTimeDefine__c getWkDefineByShopCode(String shopCd) {
	    if (instance.mapWorkTimeDef.containsKey(shopCd)) {
	        return instance.mapWorkTimeDef.get(shopCd);
	    }
	    else if (defWorkTimeInfo != null){
	    	return defWorkTimeInfo.clone(false);
	    } else {
	        throw new CommException('Unable to locate shop info: ' + shopCd);
	    }
	}
	
	private WorkTimeDefineUtil() {
    	mapWorkTimeDef = new Map<String, WorkTimeDefine__c>();
    	List<WorkTimeDefine__c> wkd = WorkTimeDefine__c.getall().values();
    	WorkTimeDefine__c firstInfo = null;
    	defWorkTimeInfo = null;
    	for (WorkTimeDefine__c df : wkd) {
    		if (CommUtils.isBlank(df.shopCode__c) && defWorkTimeInfo == null) defWorkTimeInfo = df;
    		if (firstInfo == null) firstInfo = df;
    		mapWorkTimeDef.put(df.shopCode__c, df);
    	}
    	if (defWorkTimeInfo == null) defWorkTimeInfo = firstInfo;
	}
	
}