public abstract with sharing class ExpoCommBaseCtrl {
	
	public boolean hasSession {get; set;}
	// ログインユーザ情報
	public ExpoUser__c currentUser {get; set;}
	// 該当サビースセッション
	public String sessionId{get;set;}

	// CookieName
	//public String getSessionName{get{ return 'apex__' + ExpoCommonConst.AuthCookieId;}set;}
	// ログイン状態をチェックする
	public PageReference checkLogin() {
		String reqSid = ApexPages.currentPage().getParameters().get('sid');
		if (!CommUtils.isBlank(reqSid)) sessionId = reqSid;//+'&t='+CommUtils.getRandom(6);
		if (!checkUserByCookie()) {
			return Page.ExpoLogin;
		} else return null;
	}
	
	private Boolean checkUserByCookie() {
		hasSession = false;
		currentUser = null;
		//String currentSessionId = null;
		try {
			// 2019/09/15 Security Check BY zyz BEGIN
			List<String> chkFieldsLst = new List<String>{'expiredt__c'};
			Map<String,Schema.SObjectField> mm = Schema.SObjectType.ExpoSession__c.fields.getMap();
			if (!CommSecurityUtils.isCanUpdateable(chkFieldsLst, mm)) {
				return false;
			}
			// 2019/09/15 Security Check BY zyz END
			//String cookieValue = aCookie.getValue();
			if (!CommUtils.isBlank(sessionId)) {
				List<ExpoSession__c> sessions = [SELECT Id, ExpoUserRef__c, ExpireDT__c, SessionId__c FROM ExpoSession__c WHERE SessionId__c = :sessionId];
				if (!sessions.isEmpty()) {
					ExpoSession__c session = sessions[0];
					if (session.ExpireDT__c >= DateTime.now()) {
						List<ExpoUser__c> users = [SELECT Id, Name, UserName__c, Email__c, Fax__c, Phone__c, ShopCode__c, ExpoOrgInfoRef__c, ExpoOrgInfoRef__r.Name FROM ExpoUser__c WHERE Id = :session.ExpoUserRef__c];
						if (users.size() == 1) {
							currentUser = users[0];
							hasSession = true;
							//expoHelper.writeSessionIdToCookie(session.SessionId__c);
							session.ExpireDT__c = DateTime.now().addMinutes(ExpoCommonConst.AuthReleaseTime);
							update session;
						}
					}
				}
			}
		} catch (Exception ex) {
			ApexPages.addMessages(ex);
		}
		return hasSession;
	}
	//　サイト区分
	public boolean isFromSite{get{ return isFromSite();}private set;}
	// サイトからアクセス場合
	public static Boolean isFromSite() {
 		return (Site.getDomain() != null);
	}
}