/*********************************************
* 連携結果の関連トリガー処理を行う
* 2015/10/09: Chatterへポスト処理機能の追加
**/
public with sharing class CooperationResultTriggerProcess {
	

	/******************
	* メール送信の場合、自動的に指定のChatterグループへエラー情報をポストする
	******************/
	public void autoPostMessageToChatterGroup(CooperationResult__c[] newLst, CooperationResult__c[] oldLst, CommConst.TriggerMethod action){
		// メール送信フラグはTRUEに設定されている場合、自動Chatterへポストを行う
		if (CommConst.TriggerMethod.IsUpdate == action) {
		 	Integer len = newLst.size();
		 	//String PROCESS_TYPE_TL = TL_ServiceConfigHelp.ProcessingType.TL.name();
		 	List<CooperationResult__c> tlTargetLst = new List<CooperationResult__c>();
		 	for (Integer i = 0; i < len; i++) {
		 		if (newLst[i].MailSendComplete__c != oldLst[i].MailSendComplete__c &&
		 			newLst[i].MailSendComplete__c == true) {
		 			if (newLst[i].ProcessingType__c == CommConst.SYNC_PROCESS_TYPE_TL||
		 				newLst[i].ProcessingType__c == CommConst.SYNC_PROCESS_TYPE_TA||
		 				newLst[i].ProcessingType__c == CommConst.SYNC_PROCESS_TYPE_TR||
		 				newLst[i].ProcessingType__c == CommConst.SYNC_PROCESS_TYPE_JR) {
		 				//newLst[i].FunctionType__c == CommConst.COOP_FUNTYPE_EMAIL) {
			 			// Chatterグループへポスト対象
		 				tlTargetLst.add(newLst[i]);
		 			}
		 		}
		 	}
		 	// TL処理の対象
		 	if (tlTargetLst.isEmpty()) return;
		 	
		 	// 2017/08/24 同じエラーは重複送信しないように回避対応 BEGIN
		 	// 種別により、各種類の最終エラーチェック用情報を作成する
		 	Boolean tlLeadsCoop = false, tlStockCoop = false, taLeadsCoop = false, taStockCoop = false;
		 	for (CooperationResult__c coop : tlTargetLst) {
		 	    if (coop.ProcessingType__c == CommConst.SYNC_PROCESS_TYPE_TL) {
		 	        /*
		 	        if (coop.FunctionType__c == CommConst.COOP_FUNTYPE_LEADIMP) {
			 	        if (!tlLeadsCoop)  {
			 	            TL_ServiceConfigHelp.isLeadDupErrorMsgCheck(CommUtils.nullToBlank(coop.ErrorContent__c), true);
			 	            tlLeadsCoop = true;
			 	        }	
		 	        } else */
		 	        if (coop.FunctionType__c == CommConst.COOP_FUNTYPE_STOCK) {
	                    if (!tlStockCoop)  {
	                        TL_ServiceConfigHelp.isStockDupErrorMsgCheck(CommUtils.nullToBlank(coop.ErrorContent__c), true);
	                        tlStockCoop = true;
	                    }
		 	        }
                } else if (coop.ProcessingType__c == CommConst.SYNC_PROCESS_TYPE_TA) {
                    /*
                    if (coop.FunctionType__c == CommConst.COOP_FUNTYPE_LEADIMP) {
	                    if (!taLeadsCoop)  {
	                        TA_ServiceConfigHelp.isLeadDupErrorMsgCheck(CommUtils.nullToBlank(coop.ErrorContent__c), true);
	                        taLeadsCoop = true;
	                    } 
                    } else */
                    if (coop.FunctionType__c == CommConst.COOP_FUNTYPE_STOCK) {
	                    if (!taStockCoop)  {
	                        TA_ServiceConfigHelp.isStockDupErrorMsgCheck(CommUtils.nullToBlank(coop.ErrorContent__c), true);
	                        taStockCoop = true;
	                    }
                    }
                }
		 	}
		 	//if (taCoop != null) TL_ServiceConfigHelp.isStockDupErrorMsgCheck(CommUtils.nullToBlank(taCoop.ErrorContent__c));
		 	// 2017/08/24 同じエラーは重複送信しないように回避対応 END
		 	// エラー通知先のチャターグループ名を取得する
		 	//String chatterGroupNames = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().ChatterGroupName__c);
		 	//if (CommUtils.isBlank(chatterGroupNames)) return;
//System.debug(loggingLevel.INFO, 'tlCommConfig.strChatterGroupNms::' + chatterGroupNames);
			//List<String> chatterGroupNamesLst = chatterGroupNames.split(',');
			List<String> chatterGroupNamesLst = CommConst.GetChatterGroupNameByCode(CommConst.Coop_ChatterGroupNameType);
			List<CollaborationGroup> chatterGroups = [select Id, Name from CollaborationGroup where name = :chatterGroupNamesLst and isarchived = false];
        	if (chatterGroups.isEmpty()) return;
        	List<FeedItem> feedItems = new List<FeedItem>();
        	String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();

        	String functionTypeStock = CommConst.COOP_FUNTYPE_STOCK;
        	for (CooperationResult__c coop : tlTargetLst) {
        		String title = (coop.FunctionType__c == functionTypeStock)
        		//XX在庫連携バッチ処理詳細へ
        							? Label.CONST_012_0489.replace('XX',coop.ProcessingType__c) +'\n'
        		//XX予約取込バッチ処理詳細へ
        							: Label.CONST_012_0490.replace('XX',coop.ProcessingType__c) +'\n';
        		String bodyMessage = (coop.FunctionType__c == functionTypeStock)
        		//XX在庫連携バッチ処理エラーが発生しましたのでお知らせいたします。
        							? Label.CONST_012_0491.replace('XX',coop.ProcessingType__c) + ' \n\n'
        		//XX予約取込バッチ処理エラーが発生しましたのでお知らせいたします。
        							//: Label.CONST_012_0492 +'\n\n';
        							: Label.CONST_012_0492.replace('XX',coop.ProcessingType__c) +'\n\n';
        		//エラー内容：
        		bodyMessage += Label.CONST_012_0493 + CommUtils.nullToBlank(coop.ErrorContent__c) + '\n\n';
        		//bodyMessage += '詳細URL：'+baseUrl+'/' + coop.Id + '\n\n';
        		String linkUrl = baseUrl+'/' + coop.Id;
        		for (CollaborationGroup gp : chatterGroups) {
        			feedItems.add(sendMessageToChatter(gp.Id, title, bodyMessage, linkUrl));
        		}
        	}
        	if (!feedItems.isEmpty()) insert feedItems;
		}
	}
	
	private FeedItem sendMessageToChatter(Id chatterGroupId, String tilte, String bodyMessage, String linkUrl) {
		FeedItem post = new FeedItem();
		post.Type = 'LinkPost';
		post.title = tilte;
        post.Body = bodyMessage;
        post.ParentId = chatterGroupId;
        post.LinkUrl = linkUrl;
        return post;
	}
}