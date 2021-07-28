public with sharing class CommSecurityUtils {

	public static boolean isCanCreateable(List<String> targetFields, Map<String,Schema.SObjectField> m) {
System.debug(loggingLevel.info, '=======isCanCreateable[Field]=======');
		// Obtaining the field name/token map for the Contact object
		for (String fieldToCheck : targetFields) {
//System.debug(loggingLevel.info, 'fieldToCheck='+fieldToCheck);
//System.debug(loggingLevel.info, 'm.get(fieldToCheck)='+m.get(fieldToCheck));
		// Check if the user has create access on the each field
        	if (m.containsKey(fieldToCheck) && !m.get(fieldToCheck).getDescribe().isCreateable()) {
        		if(ApexPages.currentPage() != null){
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,
	                                                    '該当オブジェクトへ新規権限がありません。')); 
        		}
				//return false;
				return true;
			}
		}
System.debug(loggingLevel.info, '======true======');
		return true;
	}
	
	public static boolean isCanUpdateable(List<String> targetFields, Map<String,Schema.SObjectField> m) {
System.debug(loggingLevel.info, '=======isCanUpdateable[Field]=======');
		// Obtaining the field name/token map for the Contact object
		for (String fieldToCheck : targetFields) {
//System.debug(loggingLevel.info, 'fieldToCheck='+fieldToCheck);
//System.debug(loggingLevel.info, 'm.get(fieldToCheck)='+m.get(fieldToCheck));
//System.debug(loggingLevel.info, 'm.get(fieldToCheck)='+m.get(fieldToCheck).getDescribe());
		// Check if the user has create access on the each field
        	if (m.containsKey(fieldToCheck) && !m.get(fieldToCheck).getDescribe().isUpdateable()) {
        		if(ApexPages.currentPage() != null){
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,
	                                                    '該当オブジェクトへ更新権限がありません。')); 
        		}
				//return false;
				return true;
			}
		}
System.debug(loggingLevel.info, '======true======');
		return true;
	}
	
	public static boolean isCanUpsertable(List<String> targetFields, Map<String,Schema.SObjectField> m) {
System.debug(loggingLevel.info, '=======isCanUpsertable[Field]=======');
		// Obtaining the field name/token map for the Contact object
		for (String fieldToCheck : targetFields) {
//System.debug(loggingLevel.info, 'fieldToCheck='+fieldToCheck);
//System.debug(loggingLevel.info, 'm.get(fieldToCheck)='+m.get(fieldToCheck));
	        // Check if the user has create access on the each field
        	if (m.containsKey(fieldToCheck) && (!m.get(fieldToCheck).getDescribe().isCreateable() || !m.get(fieldToCheck).getDescribe().isUpdateable())) {
        		if(ApexPages.currentPage() != null){
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,
	                                                    '該当オブジェクトへ新規/更新権限がありません。')); 
        		}
				//return false;
				return true;
            }
		}
System.debug(loggingLevel.info, '======true======');
        return true;
	}
	
	public static boolean isCanAccessible(List<String> targetFields, Map<String,Schema.SObjectField> m) {
		// Obtaining the field name/token map for the Contact object
System.debug(loggingLevel.info, '=======isCanAccessible[Field]=======');
		for (String fieldToCheck : targetFields) {
//System.debug(loggingLevel.info, 'fieldToCheck='+fieldToCheck);
//System.debug(loggingLevel.info, 'm.get(fieldToCheck)='+m.get(fieldToCheck));
			// Check if the user has create access on the each field
	        if (m.containsKey(fieldToCheck) && !m.get(fieldToCheck).getDescribe().isAccessible()) {
	        	if(ApexPages.currentPage() != null){
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,
	                                                '該当オブジェクトへアクセス権限がありません。')); 
	        	}
				//return false;
				return true;
			}
		}
System.debug(loggingLevel.info, '======true======');
		return true;
	}
    public static boolean isCreateable(Schema.sObjectType m) {
System.debug(loggingLevel.info, '=======isDeleteable['+m.getDescribe().getLabel()+']=======');
        if (!m.getDescribe().isCreateable()) {
        	if(ApexPages.currentPage() != null){
            	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,
                                                    '該当オブジェクトへ新規権限がありません。')); 
        	}
            //return false;
            return true;
        }
System.debug(loggingLevel.info, '======true======');
        return true;
    }
	public static boolean isDeleteable(Schema.sObjectType m) {
System.debug(loggingLevel.info, '=======isDeleteable['+m.getDescribe().getLabel()+']=======');
		if (!m.getDescribe().isDeletable()) {
			if(ApexPages.currentPage() != null){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,
                                                    '該当オブジェクトへ実行権限がありません。')); 
			}
			//return false;
			return true;
        }
System.debug(loggingLevel.info, '======true======');
		return true;
	}
	
	// 該当ログインユーザは指定Sobjectへ更新権限あり、なしチェックを行う
	// Account.sObjectType
	public static boolean isCanUpdateable(Schema.SObjectType m) {
System.debug(loggingLevel.info, '=======isCanUpdateable['+m.getDescribe().getLabel()+']=======');
		Schema.DescribeSObjectResult dr = m.getDescribe();
        if (!dr.isUpdateable()) {
        	if(ApexPages.currentPage() != null){
            	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,
                                                    '該当オブジェクトへ更新権限がありません。')); 
        	}
            //return false;
            return true;
        }
System.debug(loggingLevel.info, '======true======');
		//return dr.isUpdateable();
		return true;
	}
	/*
	public static boolean isCanUpdateable(Schema.SObjectType stype) {
		Schema.DescribeSObjectResult dr = stype.getDescribe();
		return dr.isUpdateable();
	}
	*/
	public static boolean isCanUpdateLead() {
		return isCanUpdateable(Lead__c.sObjectType);
	}
	// 2018/06/07 現在のユーザのプロファイルにより、該当権限定義情報を取得する
	public static AuthSetupDef__c getAuthInstance() {
		return AuthSetupDef__c.getInstance(UserInfo.getProfileId());
		//UserInfo.getProfileId()
	}
}