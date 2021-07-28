public with sharing class ExpoUserTriggerProcess {
	public ExpoUserTriggerProcess(){}
	public void checkExpoUserInfo(ExpoUser__c[] newList, ExpoUser__c[] oldList, CommConst.TriggerMethod action){
		if(Trigger.isInsert && Trigger.isBefore){
			for(ExpoUser__c newUser : newList){
				newUser.TokenId__c = CommUtils.getGUID();
			}
		}
	}
}