public with sharing class CashVerificationTriggerProcess {
   
   
   public void writeChangeInfoToHistory(CashVerification__c[] newLst, CashVerification__c[] oldLst, CommConst.TriggerMethod action){
   		/* 2016/05/13 共通化するため
 		List<ItemChangeHistory__c> syncTargetLst = new List<ItemChangeHistory__c>();
   		// 新規
   		if (action == CommConst.TriggerMethod.isInsert) {
   			for (CashVerification__c nw : newLst) {
   				syncTargetLst.add(genItemChangeHistory(nw, 'Created'));
   			}
   		} 
   		// 変更
   		else if (action == CommConst.TriggerMethod.isUpdate) {
   			Map<String, String> checkFieldMap = CommSqlUtils.getCustomeFieldLst('CashVerification__c',true);
   			Integer maxLen = newLst.size();
   			for (Integer i =0; i<maxLen; i++) {
   				CashVerification__c nw = newLst[i];
   				CashVerification__c od = oldLst[i];
   				String changeContent = '';
   				for (String fieldNm : checkFieldMap.keySet()) {
   					if (nw.get(fieldNm) != od.get(fieldNm)) {   						
   						changeContent += checkFieldMap.get(fieldNm) + ':'+ CommUtils.nullToBlank(od.get(fieldNm)) + '→' + CommUtils.nullToBlank(nw.get(fieldNm)) + '\n';
   					}
   				}
   				if (!CommUtils.isBlank(changeContent)) {
   					syncTargetLst.add(genItemChangeHistory(nw, changeContent));
   				}
   //	System.debug(loggingLevel.INFO, 'syncTargetLst::::::=====>>'+syncTargetLst);
   			}
   		}
   		if (syncTargetLst.isEmpty()) return;
   		// 変更情報は履歴オブジェクトに変更を行う
   		insert syncTargetLst;
   		*/
   		// 2017/02/27 自動連携など裏処理の場合、該当ログに記録を行わない BEGIN
   		/*
   		if (action == CommConst.TriggerMethod.isUpdate) {
   			List<CashVerification__c> nwLst = new List<CashVerification__c>();
   			List<CashVerification__c> odLst = new List<CashVerification__c>();
   			Integer maxLen = newLst.size();
   			for (Integer i =0; i<maxLen; i++) {
   				CashVerification__c nw = newLst[i];
   				CashVerification__c od = oldLst[i];
   				if (nw.AutoUpdateFlg__c != od.AutoUpdateFlg__c) continue;
   				nwLst.add(nw);
   				odLst.add(od);
   			}
   			if (!nwLst.isEmpty()) CommLogicProcess.writeChangeInfoToHistory(nwLst, odLst, action);
   		} else {
   			CommLogicProcess.writeChangeInfoToHistory(newLst, oldLst, action);
   		}*/
   		CommLogicProcess.writeChangeInfoToHistory(newLst, oldLst, action);
		// 2017/02/27 自動連携など裏処理の場合、該当ログに記録を行わない END
   } 
   /* 2016/05/13 共通化するため
   // 変更情報は履歴オブジェクトに変更を行う
   private ItemChangeHistory__c genItemChangeHistory(CashVerification__c obj, String changeStr) {
   		ItemChangeHistory__c newItem = new ItemChangeHistory__c();
   		newItem.CashVerificationRef__c = obj.Id;
   		newItem.ParentId__c = obj.Id;
   		newItem.LastModifiedBy__c = UserInfo.getLastName() + '  ' + UserInfo.getFirstName(); 
		newItem.LastModifiedTime__c = Datetime.now();
   		newItem.History__c = changeStr;
   		return newItem;
   }*/
}