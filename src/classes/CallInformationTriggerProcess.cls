public with sharing class CallInformationTriggerProcess {


	/******************
	* メール送信の場合、自動的に指定のChatterグループへエラー情報をポストする
	******************/
	public void autoPostMessageToChatterGroup(Call_information__c[] newLst, Call_information__c[] oldLst, CommConst.TriggerMethod action){
	    // 2017/06/26 お客様がチェックアウトしたタイミングで音声通知機能 zyz BEGIN
		// 車通知先のチャターグループ名を取得する
		//List<String> chatterGroupNamesLst = CommConst.GetChatterGroupNameByCode(CommConst.Call_ChatterGroupNameType);
		set<String> chatterGroupNamesCarSet = new set<string>(CommConst.GetChatterGroupNameByCode(CommConst.Call_ChatterGroupNameType));
		// チェックアウト通知先のチャターグループ名を取得する
		set<String> chatterGroupNamesCoSet = new set<string>(CommConst.GetChatterGroupNameByCode(CommConst.CO_ChatterGroupNameType));
		// 2019/10/15 チェックイン時に自動音声で通知 BY zyz BEGIN
		// チェックイン通知先のチャターグループ名を取得する
		set<String> chatterGroupNamesCiSet = new set<string>(CommConst.GetChatterGroupNameByCode(CommConst.CI_ChatterGroupNameType));
		// if (chatterGroupNamesCarSet.isEmpty() && chatterGroupNamesCoSet.isEmpty()) return;
		if (chatterGroupNamesCarSet.isEmpty() && chatterGroupNamesCoSet.isEmpty() && chatterGroupNamesCiSet.isEmpty()) return;
		// 2019/10/15 チェックイン時に自動音声で通知 BY zyz END
		// 2017/06/26 お客様がチェックアウトしたタイミングで音声通知機能 zyz END
		// メール送信フラグはTRUEに設定されている場合、自動Chatterへポストを行う
		if (CommConst.TriggerMethod.IsInsert == action ||
			CommConst.TriggerMethod.IsUpdate == action) {
		 	Integer len = newLst.size();

		 	List<Call_information__c> tlTargetLst = new List<Call_information__c>();
		 	// 2017/06/26 お客様がチェックアウトしたタイミングで音声通知機能 zyz BEGIN
		 	List<Call_information__c> coTargetLst = new List<Call_information__c>();
		 	// 2017/06/26 お客様がチェックアウトしたタイミングで音声通知機能 zyz END
		 	for (Integer i = 0; i < len; i++) {
		 		Call_information__c call = newLst[i];
		 		// 種類は「CAR」の場合、 かつ　「Contact OR Account」存在の場合、処理対象
		 		if (call.CallType__c == CallInformationSync.CarNoKey &&
		 			( call.Contact__c != null || call.Account__c != null)) {
		 			// Chatterグループへポスト対象
	 				tlTargetLst.add(newLst[i]);
		 		}
		 		// 2017/06/26 お客様がチェックアウトしたタイミングで音声通知機能 zyz BEGIN
		 		if(call.CallType__c == LeadTriggerProcess.CoKey){
		 			coTargetLst.add(newLst[i]);
		 		}
		 		// 2017/06/26 お客様がチェックアウトしたタイミングで音声通知機能 zyz END
		 		// 2019/10/15 チェックイン時に自動音声で通知 BY zyz BEGIN
		 		if(call.CallType__c == LeadTriggerProcess.CiKey){
		 			coTargetLst.add(newLst[i]);
		 		}
		 		// 2019/10/15 チェックイン時に自動音声で通知 BY zyz END
		 	}
		 	// TL処理の対象
		 	// 2017/06/26 お客様がチェックアウトしたタイミングで音声通知機能 zyz BEGIN
		 	if (tlTargetLst.isEmpty() && coTargetLst.isEmpty()) return;
		 	//if (tlTargetLst.isEmpty()) return;
		 	// エラー通知先のチャターグループ名を取得する
			//List<CollaborationGroup> chatterGroups = [select Id, Name from CollaborationGroup where name = :chatterGroupNamesLst and isarchived = false];
			// 2019/10/15 チェックイン時に自動音声で通知 BY zyz BEGIN
		 	// List<CollaborationGroup> chatterGroups = [select Id, Name from CollaborationGroup where (name = :chatterGroupNamesCarSet or name = :chatterGroupNamesCoSet ) and isarchived = false];
			List<CollaborationGroup> chatterGroups = [select Id, Name from CollaborationGroup where (name = :chatterGroupNamesCarSet or name = :chatterGroupNamesCoSet or name = :chatterGroupNamesCiSet ) and isarchived = false];
			// 2019/10/15 チェックイン時に自動音声で通知 BY zyz END
			List<CollaborationGroup> carChatterGroups = new list<CollaborationGroup>();  // 車通知用グループ
			List<CollaborationGroup> coChatterGroups = new list<CollaborationGroup>();   // チェックアウト通知用グループ
			// 2019/10/15 チェックイン時に自動音声で通知 BY zyz BEGIN
			List<CollaborationGroup> ciChatterGroups = new list<CollaborationGroup>();   // チェックイン通知用グループ
			// 2019/10/15 チェックイン時に自動音声で通知 BY zyz END
			for (CollaborationGroup gp : chatterGroups) {
			    if (chatterGroupNamesCarSet.contains(gp.name)) carChatterGroups.add(gp);
			    if (chatterGroupNamesCoSet.contains(gp.name)) coChatterGroups.add(gp);
			    // 2019/10/15 チェックイン時に自動音声で通知 BY zyz BEGIN
			    if (chatterGroupNamesCiSet.contains(gp.name)) ciChatterGroups.add(gp);
			    // 2019/10/15 チェックイン時に自動音声で通知 BY zyz END
			}
            // チェックアウト通知チャターへポストフラグ
            if (!CommConst.NOTIFY_CO_IS_CHATTERPOST) coChatterGroups.clear();
            // 2019/10/15 チェックイン時に自動音声で通知 BY zyz BEGIN
            // チェックイン通知チャターへポストフラグ
            if (!CommConst.NOTIFY_CI_IS_CHATTERPOST) ciChatterGroups.clear();
            // 2019/10/15 チェックイン時に自動音声で通知 BY zyz END
		 	// 2017/06/26 お客様がチェックアウトしたタイミングで音声通知機能 zyz END
        	if (chatterGroups.isEmpty()) return;
        	List<FeedItem> feedItems = new List<FeedItem>();
        	String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
			// 2017/04/24 RECAIUS機能統合対応 BEGIN
			Boolean isSimpleMsgFlg = CommConst.ChatterGroupSimpleMsgFlg;
			// 2017/04/24 RECAIUS機能統合対応 END
        	for (Call_information__c call : tlTargetLst) {
        		String strName = CommUtils.nullToBlank(call.Contact__c != null ? call.Contact_Name__c : call.Company_Name__c);
        		// 2017/04/24 RECAIUS機能統合対応 BEGIN
        		if (isSimpleMsgFlg) strName = CommUtils.nullToBlank(call.Contact__c != null ? (CommUtils.isBlank(call.Contact_KatakanaCal__c) ? call.Contact_Name__c : call.Contact_KatakanaCal__c) : call.Company_Name__c);
        		//if(call.No_of_Matching_Customers__c > 1) strName += '('+call.No_of_Matching_Customers__c+')';
        		if(!isSimpleMsgFlg && call.No_of_Matching_Customers__c > 1) strName += '('+call.No_of_Matching_Customers__c+')';
        		// 2017/04/24 RECAIUS機能統合対応 END
        		//様
        		String title = strName + ' '+ Label.CONST_038_0038;
        		// 2017/12/07 車ナンバーの通知メッセージは自由にカスタマイズできるように改善対応 zyz BEGIN
        		String bodyMessage;
        		if(!CommUtils.isBlank(call.DT4__c)){
        			bodyMessage = CommUtils.nullToBlank(call.DT4__c);
        		}else {
	        	// 2017/12/07 車ナンバーの通知メッセージは自由にカスタマイズできるように改善対応 zyz END
	        		//様、ご到着されましたので、ご案内ください
	        		bodyMessage = strName + ' ' + Label.CONST_038_0039;
	        		// 2017/04/24 RECAIUS機能統合対応 BEGIN
	        		if (isSimpleMsgFlg) bodyMessage = strName + ' ' + Label.MSG_045_0002;
	        		// 2017/04/24 RECAIUS機能統合対応 END
        		// 2017/12/07 車ナンバーの通知メッセージは自由にカスタマイズできるように改善対応 zyz BEGIN
        		}
        		// 2017/12/07 車ナンバーの通知メッセージは自由にカスタマイズできるように改善対応 zyz END
        		Id linkId = call.Contact__c != null ? call.Contact__c : call.Account__c;
        		String linkUrl = baseUrl+'/' +linkId;
        		// 2017/06/26 お客様がチェックアウトしたタイミングで音声通知機能 zyz BEGIN
        		//for (CollaborationGroup gp : chatterGroups) {
        		for (CollaborationGroup gp : carChatterGroups) {
    		    // 2017/06/26 お客様がチェックアウトしたタイミングで音声通知機能 zyz END
        			feedItems.add(sendMessageToChatter(gp.Id, title, bodyMessage, linkUrl, isSimpleMsgFlg));
        		}
        	}
        	// 2017/06/26 お客様がチェックアウトしたタイミングで音声通知機能 zyz BEGIN
        	for (Call_information__c call : coTargetLst) {
        		String strName = CommUtils.nullToBlank(call.NAM__c);
        		//XXXX号室チェックアウトした
        		String bodyMessage = strName;
        		// 2019/10/15 チェックイン時に自動音声で通知 BY zyz BEGIN
        		String strType = CommUtils.nullToBlank(call.CallType__c);
        		if(strType == LeadTriggerProcess.CoKey) {
        		for (CollaborationGroup gp : coChatterGroups) {
        			feedItems.add(sendMessageToChatter(gp.Id, null, bodyMessage, null, true));
	        		}
        		}else if(strType == LeadTriggerProcess.CiKey){
	        		for (CollaborationGroup gp : ciChatterGroups) {
	        			feedItems.add(sendMessageToChatter(gp.Id, null, bodyMessage, null, true));
	        		}
        		}
        		// 2019/10/15 チェックイン時に自動音声で通知 BY zyz END
        	}
        	// 2017/06/26 お客様がチェックアウトしたタイミングで音声通知機能 zyz END
        	if (!feedItems.isEmpty()) insert feedItems;
		}
	}

	private FeedItem sendMessageToChatter(Id chatterGroupId, String tilte, String bodyMessage, String linkUrl, Boolean isSimpleMsgFlg) {
		FeedItem post = new FeedItem();
		// 2017/04/24 RECAIUS機能統合対応 BEGIN
		if (isSimpleMsgFlg) {
			post.Type = 'TextPost';
			//post.title = tilte;
		    post.Body = bodyMessage;
		    post.ParentId = chatterGroupId;
		} else {
		// 2017/04/24 RECAIUS機能統合対応 EMD
			post.Type = 'LinkPost';
			post.title = tilte;
		    post.Body = bodyMessage;
		    post.ParentId = chatterGroupId;
		    post.LinkUrl = linkUrl;
		// 2017/04/24 RECAIUS機能統合対応 BEGIN
		}
		// 2017/04/24 RECAIUS機能統合対応 END
	    return post;
	}
}