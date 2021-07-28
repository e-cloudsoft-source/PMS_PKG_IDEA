public with sharing class ExpoUserActivationCtrl {
	public String password{get; set;}
	public List<ExpoUser__c> expoUserLst{get; set;}
	public ExpoUserActivationCtrl(){
		password = '';
		expoUserLst = new List<ExpoUser__c>();
	}
	public Pagereference initAct(){
		Pagereference pg = ApexPages.currentPage();
		if(!pg.getParameters().containsKey('tokenKey')) return Page.ExpoLogin;
		String tokenKey = CommUtils.nullToBlank(pg.getParameters().get('tokenKey')); // tokenid
		if(CommUtils.isBlank(tokenKey)) return Page.ExpoLogin;
		expoUserLst = [Select Id, PassWord__c, ActivationFlg__c From ExpoUser__c Where TokenId__c =: tokenKey And (ChangePasswordFlg__c = true or ActivationFlg__c = false) And IsActive__c = true];
		if(expoUserLst.isEmpty()) return Page.ExpoLogin;
		return null;
	}
	public Pagereference updateData(){
		for(ExpoUser__c s : expoUserLst){
			s.PassWord__c = password;
			s.ActivationFlg__c = true;
			s.ChangePasswordFlg__c = false;
		}
		if(!expoUserLst.isEmpty()) update expoUserLst;
		return Page.ExpoLogin;
	}
	// 2018/10/06 システムロゴ情報を取得する WSQ BEGIN
	public String getLogoUrl() {
		return ExpoNoAuthHelp.getLogoUrl();
	}
	// 2018/10/06 システムロゴ情報を取得する WSQ END
}