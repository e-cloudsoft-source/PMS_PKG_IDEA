public with sharing class ExpoLoginCtrl {
	public String username{get; set;}
	public String password{get; set;}
	public PageReference actionLogin(){
		// 必填项Chk
		if(CommUtils.isBlank(username) || CommUtils.isBlank(password)){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'ユーザ名とパスワードを確認してください。それでもログインできない場合は、システム管理者にお問い合わせください。'));
			return null;
		}
		// ユーザ存在チェック
		ExpoUser__c user = getUserInfo();
		// ユーザ存在場合
		if (user != null) {
			// 新規SESSION情報を取得する
			String sessionId = ExpoHelperUtil.generateNewSessionId();
			// SESSIONキーはDBとCOOKIEへ保存する
		   	PageReference page = Page.ExpoHome;
			sessionId = ExpoHelperUtil.writeSessionId(user.Id, sessionId);
			Map<String,String> paramMap = new map<String,String>();
			paramMap.put('sid',sessionId);
			page.getParameters().putAll(paramMap);
			// ホームページへ遷移する
			page.setRedirect(true);
			// ページ遷移する
			return page;
		} else {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'ユーザ名とパスワードを確認してください。それでもログインできない場合は、システム管理者にお問い合わせください。'));
			return null;
		}
	}
	// ユーザ情報存在チェックを行う
	private ExpoUser__c getUserInfo(){
		// 2021/05/31 EXPOログイン機能改修（EXPOユーザ情報アクセス問題回避　WSQ BEGIN
		/*
		List<ExpoUser__c> users = [Select Id, UserName__c, Name, password__c FROM ExpoUser__c WHERE UserName__c =: username And IsActive__c = true And ActivationFlg__c = true];
		if (!users.isEmpty()) {
			ExpoUser__c aUser = users[0];
			if (aUser.password__c != null && aUser.password__c.equals(password)) {
				return aUser;
			}
		}
		return null;
		*/
		return ExpoHelperUtil.getUserInfo(username, password);
		// 2021/05/31 EXPOログイン機能改修（EXPOユーザ情報アクセス問題回避　WSQ END
	}
	// 2018/10/06 システムロゴ情報を取得する WSQ BEGIN
	public String getLogoUrl() {
		return ExpoNoAuthHelp.getLogoUrl();
	}
	// 2018/10/06 システムロゴ情報を取得する WSQ END
}