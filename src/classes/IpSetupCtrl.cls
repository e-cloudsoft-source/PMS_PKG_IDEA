/*********************************************
* オーダーシスタムのip設定画面
* ipad の　ip 対応
*********************************************/
public with sharing class IpSetupCtrl {
	public String localIp{get;set;}
	//返回url
	private string backUrl;
	// 2018/03/07 Security Check BEGIN
	public String getBackUrl(){return backUrl;}
	// 2018/03/07 Security Check END
	private Map<String,String> paramMap;
    public IpSetupCtrl(){
    	backUrl = '';
    	//userInf = UserUtil.CurrentUserInfo;
    }
    //
    public void initAction(){
    	// 戻るページ維持する
        paramMap = Apexpages.currentPage().getParameters(); 
    	backUrl = paramMap.get('back');
    }
    // 2018/03/07 Security Check BEGIN
    /*
    //跳转
    public Pagereference redirectOrder(){
    	if (CommUtils.isBlank(localIp)) {
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'IPアドレスを入力してください。'));
    		return null;
    	}
    	// ページ遷移前のチェックを行う
        Map<String,String> param = new Map<String,String>();
        param.put('localIp',localIp);
//system.debug(logginglevel.info,'back:::' + backUrl);
        if(!CommUtils.isBlank(backUrl)){
			PageReference customPage = new PageReference( backUrl);
			customPage.getParameters().putAll(param);
			customPage.setRedirect(true);
			return customPage;
        }
		return null;
    }*/
    // 2018/03/07 Security Check END
}