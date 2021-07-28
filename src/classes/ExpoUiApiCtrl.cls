public with sharing class ExpoUiApiCtrl extends ExpoCommBaseCtrl{
    public String userid{get;set;}
    public String orgid{get{return UserInfo.getOrganizationId().substring(0,15);}}
    public String suborgId{get;set;}
    public Boolean isMobile { get; set; }
    public String apiEndPoint{get{return ExpoHelperUtil.EXPO_ENDPOINTURL;}}
    public String imgEndPoint{get{return ExpoHelperUtil.EXPO_IMGENDPOINTURL;}}
    public String domainUrl{get{return ExpoHelperUtil.EXPO_SITEDOMAIN;}}
    public Boolean isSandbox{get;private set;}
    public ExpoUiApiCtrl(){
        isMobile = (UserInfo.getUiTheme() == 'Theme4t');
    }
    public Boolean isFromSite{get{ return isFromSite();} set;}
    public PageReference initAct() {
        // *****************************
        // 共通処理呼び出す
        // *****************************
        // ユーザ情報チェックする
        if (isFromSite) {
            PageReference pg = checkLogin();
            if (pg != null) return pg;
            suborgId = currentUser.ExpoOrgInfoRef__c;
            userid = UserInfo.getOrganizationId().substring(0,15) + '-' + CommUtils.nullToBlank(currentUser.Id).substring(0,15);
        } else {
            userid = UserInfo.getOrganizationId().substring(0,15) + '-' + Userinfo.getUserId().substring(0,15);
        }
        return null;
    }
    public void initOrgInfoAct() {
        // *****************************
        // 組織情報を呼び出す
        // *****************************
        isSandbox = false;
        List<Organization> orgInfoList = [SELECT Id, IsSandbox  FROM Organization limit 1];
        if (!orgInfoList.isEmpty()) {
			Organization curOrgInfo = orgInfoList[0];
			isSandbox = (curOrgInfo.IsSandbox);
		}
    }
}