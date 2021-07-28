public with sharing class LeadIndexCommTriggerProcess {

    // SubIndex新規作成の場合、予約データ「部屋/宿泊数単位」展開、新規作成する
    // 顧客名簿に、部屋設定する場合、該当部屋合わせて、宿泊日期間単位で、予約データを作成する
    public void expendLeadData(LeadIndex__c[] newLst, LeadIndex__c[] oldLst, CommConst.TriggerMethod action){
		// 予約インデクスSUBのステータスはキャンセルになる場合、関連処理を行う
		if (action == CommConst.TriggerMethod.IsUpdate) {
        	Set<Id> delIdSet = new Set<Id>();
        	
			Integer len = newLst.size();
			for (Integer i = 0; i < len; i++) {
				LeadIndex__c nw = newLst[i];
				LeadIndex__c od = oldLst[i];
				// ステータス変更　かつ　明細データはキャンセルされる　かつ　明細データのみ
				if (nw.StatusLst__c != od.StatusLst__c && 
					nw.StatusLst__c == CommConst.LEAD_ST_CANCEL &&
					nw.ParentLeadIndxRef__c != null) {
					delIdSet.add(nw.Id);
				}
			}
			if (delIdSet.isEmpty()) return;
        	/*
        	for (LeadIndex__c s : oldLst) {
        		delIdSet.add(s.Id);
            }*/
            deleteProcess(delIdSet);
        }
    }


    // SubIndexキャンセル処理場合
    private void deleteProcess(Set<Id> subIndexId) {
    	List<Lead__c> delLeadLst = [select id, ReservedStatus__c, Comment3__c from Lead__c where LeadIndexSubId__c in :subIndexId And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG];
    	// アクセス権限制限するため、キャンセル処理する場合、削除から更新に変更する
    	for (Lead__c lead : delLeadLst) {
            lead.ReservedStatus__c = CommConst.LEAD_ST_CANCEL;
            //キャンセル対応
            lead.Comment3__c = CommUtils.nullToBlank(lead.Comment3__c) + '\n' + System.now().format('yyyy/MM/dd HH:mm:ss:SSS') + ' '+ Label.CONST_002_0081;
    	}
    	//delete delLeadLst;
    	// 2018/03/07 Security Check BEGIN
    	if (!CommSecurityUtils.isDeleteable(BookingGuest__c.getSObjectType())) {
    		return;
    	}
    	// 2018/03/07 Security Check END 
    	// 宿泊名簿情報を削除する
    	delete [select id from BookingGuest__c where IndexSubRef__c in :subIndexId];
    	update delLeadLst;
    }
    // 2018/06/06 編集権限チェックできる対応 BEGIN
    public void autoSetupInfo(LeadIndex__c[] newList, LeadIndex__c[] oldList, CommConst.TriggerMethod action){
    	if (CommSecurityUtils.getAuthInstance().NoEditLead__c == true) {
    		//throw new CommException('該当権限がありません。');
    		newList[0].addError(Label.MSG_9105);
    		return;
    	}
    }
	// 2018/06/06 編集権限チェックできる対応 END
/**
*2015-11-18  
*テストクラスLeadIndexCommTriggerProcessTestに移行する
	@isTest
	static void testCase1() {
    	Test.startTest();
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	Test.stopTest();
    	Lead__c newLead = [select LeadIndexSubId__c from lead__c where id =:leadInfo.Id ];
    	List<LeadIndex__c> subIdxs = [select id,StatusLst__c from LeadIndex__c where Id = :newLead.LeadIndexSubId__c];
    	for (LeadIndex__c sub : subIdxs) {
    		sub.StatusLst__c = CommConst.LEAD_ST_CANCEL;
    	}
    	update subIdxs;
    	List<Lead__c> existLead = [select id from Lead__c where id = :leadInfo.Id And ReservedStatus__c = :CommConst.LEAD_ST_CANCEL];
    	// キャンセル処理を行う
    	System.assert(!existLead.isEmpty());
	}
*/
}