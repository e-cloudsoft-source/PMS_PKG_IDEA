public with sharing class UserTriggerProcess {
	/******************
	* ユーザの時間単位、端数処理を設定
	* 2017/02/24 復活されたユーザでもデフォルト値を現在の値で自動更新されることを対応する
	******************/
	//public void autoSetupUserTimeUnit(User[] newLst){
	public void autoSetupUserTimeUnit(User[] newLst, User[] oldLst, CommConst.TriggerMethod act){
		// 2017/02/24 復活されたユーザでもデフォルト値を現在の値で自動更新されることを対応する BEGIN
		List<User> targetLst = new List<User>();
		if (act == CommConst.TriggerMethod.IsInsert) {
			for (User userItem : newLst) {
				targetLst.add(userItem);	
			}
		} else if (act == CommConst.TriggerMethod.IsUpdate) {
			Integer maxLen = newLst.size();
			for (Integer i =0; i<maxLen; i++) {
				User nw = newLst[i];
				User od = oldLst[i];
				if (nw.IsActive != od.IsActive && nw.IsActive) {
					targetLst.add(nw);
				}
			}
		}
		if (targetLst.isEmpty()) return;
		//for (User userItem : newLst) {
		for (User userItem : targetLst) {
		// 2017/02/24 復活されたユーザでもデフォルト値を現在の値で自動更新されることを対応する END
			//出勤時間単位  30分
			userItem.BeginTimeUnit__c = CommDefine__c.getOrgDefaults().UserBeginTimeUnit__c;
			//出勤時間端数処理  切り上げ
			userItem.BeginTimeCalMethodType__c = CommDefine__c.getOrgDefaults().UserBeginTimeCalMethodType__c;
		    //退勤時間単位 30分
			userItem.TimeUnit__c = CommDefine__c.getOrgDefaults().UserTimeUnit__c;
			//退勤時間端数処理 切り捨て
			userItem.CalMethodType__c = CommDefine__c.getOrgDefaults().UserCalMethodType__c;
			//入室時間単位 30分
			userItem.RestTimeUnit__c = CommDefine__c.getOrgDefaults().UserRestTimeUnit__c;
			//入室時間端数処理 切り上げ
			userItem.RestCalMethodType__c = CommDefine__c.getOrgDefaults().UserRestCalMethodType__c;
			//外出時間単位 30分
			userItem.OutRestTimeUnit__c = CommDefine__c.getOrgDefaults().UserOutRestTimeUnit__c;
			//外出時間端数処理 切り捨て
			userItem.OutRestCalMethodType__c = CommDefine__c.getOrgDefaults().UserOutRestCalMethodType__c;
		}
	}
	/******************
	* ユーザ情報の店舗コードは複数定義を対応するため、
	******************/
	public void autoSetupDefaultShopCode(User[] newLst, User[] oldLst){
		for (Integer i = 0; i < newLst.size(); i++) {
			User nw = newLst[i];
			User od = oldLst == null ? null : oldLst[i];
			// 2019/02/28 デフォルト店舗コードの設定条件を変更する WSQ BEGIN
			//if (od == null || nw.ShopCode__c != od.ShopCode__c) {
			if (od == null || nw.ShopCode__c != od.ShopCode__c ||
				(CommUtils.isBlank(nw.DefaultShopCode__c) && !CommUtils.isBlank(nw.ShopCode__c))) {
			// 2019/02/28 デフォルト店舗コードの設定条件を変更する WSQ END
				UserUtil.UserShopInfo uInfo = new UserUtil.UserShopInfo(nw);
				nw.DefaultShopCode__c = uInfo.defaultShopCode;
			}
		}
	}
}