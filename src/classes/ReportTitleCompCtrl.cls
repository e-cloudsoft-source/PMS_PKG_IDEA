public with sharing class ReportTitleCompCtrl {
    public String billRTshopCd {get; set{
    	if(CommUtils.isBlank(value)) {
    		billRTshopCd = UserUtil.CurrentUser.ShopCode__c;
    	} else {
    		billRTshopCd = value;
    	}
    }}
	public 	ReportTitleCompCtrl() {}
	// 支店判別フラグ
	public Boolean isBranchShop{get{return (CommUtils.isBlank(billRTshopCd) ? false : true);} private set;}
	// 2017/09/25 ビル一括印刷機能対応 BEGIN
	public ReportLogo__c reportInfo {get{
		if (reportInfo == null) {
			return CommRepUtils.getReportTitleInfo(billRTshopCd);
		} else {
			return reportInfo;
		}
	}set;}
	
	// レポート関連情報
    //public ReportLogo__c reportInfo {
    //	get{return CommRepUtils.getReportTitleInfo(billRTshopCd);}
    //}
    // 2017/09/25 ビル一括印刷機能対応 END
}