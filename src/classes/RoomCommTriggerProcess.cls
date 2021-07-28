/*********************************************
* 部屋の関連トリガー処理を行う
* 201/11/22 在庫連携データ自動作成機能
**/
public with sharing class RoomCommTriggerProcess {
    public void syncRoomInfoToLeads(Room__c[] newList, Room__c[] oldList, CommConst.TriggerMethod action) {
    	// 部屋の部屋タイプを変更される際に、予約を連動更新する処理を行う
    	// Map<部屋ID、部屋タイプID>
    	Map<Id, Id> roomToRoomTypeMap = new Map<Id, Id>();
		for (integer i = 0 ; i < newList.size() ; i++) {
			Room__c nw = newList[i];
			Room__c od = oldList[i];
    		if (nw.TypeRoomRef__c != od.TypeRoomRef__c ) {
    			// 未来日の予約に対して、該当部屋にリンクされている場合、部屋タイプは自動連動更新を行う
    			roomToRoomTypeMap.put(nw.Id, nw.TypeRoomRef__c);
    		}
    	}
    	if (roomToRoomTypeMap.isEmpty()) return;
    	// 該当部屋に関連の有効予約（到着日は今日からの未来日）の部屋タイプは該当部屋の最新部屋タイプが一致しない場合、予約情報を自動更新を行う
		set<Id> roomToRoomTypeSet = roomToRoomTypeMap.keyset();
		Integer leadCancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
		Date todayDt = Date.today();
		// 2018/12/20 BugFix Wsq BEGN
		String strTodayDt = CommUtils.dateToYYYYMMDD(todayDt);
		// 2018/12/20 BugFix Wsq END
		Boolean isFixedFlg = DataFixManagerUtils.getInstance().LeadFixed__c;
		// 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
		Boolean isFixedFlg1 = DataFixManagerUtils.getInstance().LeadFixed1__c;
		Integer intTodayDt = CommUtils.nullToIntZero(strTodayDt);
		// 2020/08/30 部屋状態管理インデックス機能対応 WGCH END
		//List<Lead__c> leadLst = [select Rroom__c, refTypeOfRooms__c from Lead__c where Rroom__c = :roomToRoomTypeMap.keySet()
		String queryStr = 'select Rroom__c, refTypeOfRooms__c from Lead__c where Rroom__c = :roomToRoomTypeSet And CancelBool__c != :leadCancelFlg ';
				// 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
				// queryStr+= (isFixedFlg ? ' And EntryDateKey__c >= :strTodayDt ' :' And DAY_ONLY(convertTimezone(EntryTime__c)) >= :todayDt ');
				if(isFixedFlg1) queryStr += ' And EntryDateIntKey__c >= :intTodayDt ';
				else if(isFixedFlg) queryStr += ' And EntryDateKey__c >= :strTodayDt ';
				else queryStr += ' And DAY_ONLY(convertTimezone(EntryTime__c)) >= :todayDt ';
				// 2020/08/30 部屋状態管理インデックス機能対応 WGCH END
		List<Lead__c> leadLst = DataBase.query(queryStr);
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'reftypeofrooms__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.Lead__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
			return ;
		}
		// 2019/09/15 Security Check BY zyz END
		// 更新対象リスト
		List<Lead__c> updateLst = new List<Lead__c>();
		for(Lead__c lead : leadLst){
			if(lead.refTypeOfRooms__c != roomToRoomTypeMap.get(lead.Rroom__c)){
				lead.refTypeOfRooms__c = roomToRoomTypeMap.get(lead.Rroom__c);
				updateLst.add(lead);
			}
		}
		if (!updateLst.isEmpty()) update updateLst;
    }
}