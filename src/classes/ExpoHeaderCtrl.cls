/*----------------------------------------------------------------------------
 * ヘッダー
*----------------------------------------------------------------------------*/
public with sharing class ExpoHeaderCtrl{
    // 
    public void logout() {
        if (!CommUtils.isBlank(currentUser.Id)) ExpoHelperUtil.removeSessionId(currentUser.Id);
    }
    public ExpoUser__c currentUser {get; set{
        if(currentUser == null) {
            currentUser = new ExpoUser__c();
        } else {
            currentUser = value;
        }
    }}
    public String url{
        get{ return ApexPages.currentPage().getUrl(); }set;
    }
    
    public String currentUserNm{get{ return CommUtils.nullToBlank(currentUser.Name); }set;}
    public String currentUserId{get{return CommUtils.nullToBlank(currentUser.Id); }set;}
    
    
    public ReportLogo__c getSpcdLog() {
        return ExpoNoAuthHelp.getReportTitleInfo(currentUser.ShopCode__c);
    }
    
}