public with sharing class ExpoForgotpwdCtrl{
	public ExpoForgotpwdCtrl(){
		username = '';
		userNotExistFlg = false;
	}
	public String userName{get; set;}
	public Boolean userNotExistFlg{get; set;}
	// userNameCheck是否存在
	public void userNameCheck(){
		userNotExistFlg = ExpoHelperUtil.getThisUserNameInfo(userName).isEmpty();
	}
	public void updateData(){
		List<ExpoUser__c> expoUserLst = ExpoHelperUtil.getThisUserNameInfo(userName);
		for(ExpoUser__c s : expoUserLst){
			s.ChangePasswordFlg__c = true;
			s.PwdResetSendMalFlg__c = !s.PwdResetSendMalFlg__c;
		}
		if(!expoUserLst.isEmpty()){
			userNotExistFlg = true;
			update expoUserLst;
		} else userNotExistFlg = false;
	}
	// 2018/10/06 システムロゴ情報を取得する WSQ BEGIN
	public String getLogoUrl() {
		return ExpoNoAuthHelp.getLogoUrl();
	}
	// 2018/10/06 システムロゴ情報を取得する WSQ END
}