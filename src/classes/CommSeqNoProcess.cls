public without sharing class CommSeqNoProcess {
    // 番号４桁まで設定する
    private static final Integer SeriesNumLen = 4;
	// 最後4桁を取得する
	private String formatNumber(String key) {
        // 後ろ４桁番号を取得する
        Integer maxLen = key.length();
        Integer startIndex = maxLen - SeriesNumLen;

        String autoNum = key;
        if (startIndex > 0) {
           autoNum = key.substring(startIndex, maxLen); 
        }
        return autoNum;
	}
	// 2017/01/25 店舗ごとの会計権限機能対応 BEGIN
	/*
	public Map<Id, String> getSeqNumbers(List<Sobject> sobjList) {
		return this.getSeqNumbers(sobjList, true);
	}*/
	// 2017/01/25 店舗ごとの会計権限機能対応 END
	/**
	* 各データの受付番号を采番を行う
	* setFullNoFlg true:日付 - 採番番号で設定を行う
	**/
	// 2017/01/25 店舗ごとの会計権限機能対応 BEGIN
	//public Map<Id, String> getSeqNumbers(List<Sobject> sobjList, Boolean setFullNoFlg) {
	public Map<Integer, String> getSeqNumbers(map<Integer,Sobject> sobjList, Boolean setFullNoFlg) {
	// 2017/01/25 店舗ごとの会計権限機能対応 END
//	public void getSeqNumbers(List<Sobject> sobjList) {
        // 入力チェックを行う
        if (sobjList == null || sobjList.isEmpty()) return null;
        // 2017/01/25 店舗ごとの会計権限機能対応 BEGIN
        //Sobject s = sobjList[0];
        Sobject s = sobjList.values()[0];
        // 2017/01/25 店舗ごとの会計権限機能対応 END
        // 未対応機能場合
        if ( s.getSObjectType()!= AccountAcount__c.sObjectType ) {
        	//機能処理対象外になりました。
            throw new CommException(Label.MSG_012_0419);	
        }
        
        // 自動采番オブジェクトリスト
        List<AutoSeqNumber__c> insList = new List<AutoSeqNumber__c>();
        // 2017/01/25 店舗ごとの会計権限機能対応 BEGIN
        /*
        // 会計場合
        if (s.getSObjectType()== AccountAcount__c.sObjectType) {
            for (Sobject sobj: sobjList) {
                AccountAcount__c acc = (AccountAcount__c)sobj;
                insList.add(
                	// SeqNumberPrifix__c: 営業日付
					new AutoSeqNumber__c(
                       SeqNumberPrifix__c=acc.Field141__c + '-',
                       RefSobjectId__c = acc.Id));
            }
        }
        */
        // Acc Trigger Index -> SeqNumber
        Map<Integer, AutoSeqNumber__c> seqNoMap = new Map<Integer, AutoSeqNumber__c>();
        for (Integer idx: sobjList.keySet()) {
        	AccountAcount__c acc =  (AccountAcount__c)(sobjList.get(idx));
        	AutoSeqNumber__c newSeqItem = new AutoSeqNumber__c(SeqNumberPrifix__c=acc.Field141__c + '-');
            seqNoMap.put(idx, newSeqItem);
			insList.add(newSeqItem);
        }
        // 2017/01/25 店舗ごとの会計権限機能対応 END
        if (insList.isEmpty()) return null;
        // データ更新する場合、シリアル値保留で、受付番号を更新を行う
        // ID　と　受付番号
        // 2017/01/25 店舗ごとの会計権限機能対応 BEGIN
        //Map<Id, String> updSobjMap = new Map<Id, String>();
        Map<Integer, String> updSobjMap = new Map<Integer, String>();
        // 2017/01/25 店舗ごとの会計権限機能対応 END
        /*
        if (partUpdFlg) {
        	Map<Id, String> oldNameMap = new Map<Id, String>();
        	for (Sobject sobj: sobjList) {
        	   oldNameMap.put(sobj.Id, String.valueOf(sobj.get('name')));
        	}
        	for (AutoSeqNumber__c item: insList) {
        		if (!oldNameMap.containsKey(item.RefSobjectId__c)) continue;
        		String oldName = oldNameMap.get(item.RefSobjectId__c);
        		String oldSeriesNums = oldName.substring(oldName.length()-SeriesNumLen);
        		updSobjMap.put(item.RefSobjectId__c, item.SeqNumberPrifix__c + oldSeriesNums);
        	}
        	return updSobjMap;
        }*/
        Savepoint sp = Database.setSavepoint();
        try {
        // 複数データの番号を采番を行う
        List<Database.Saveresult> insRs = Database.insert(insList);
        // SobjetId -> AutoNum Id
        // 2017/01/25 店舗ごとの会計権限機能対応 BEGIN
        //Map<String, Id> sobjIdMap = new Map<String, Id>();
        // 2017/01/25 店舗ごとの会計権限機能対応 END
        Set<Id> rsIdSet = new Set<Id>();
        for (AutoSeqNumber__c rs : insList) {
        	// 2017/01/25 店舗ごとの会計権限機能対応 BEGIN
            //sobjIdMap.put(rs.RefSobjectId__c, rs.Id);
            // 2017/01/25 店舗ごとの会計権限機能対応 END
            rsIdSet.add(rs.Id);
        }
        Map<Id,AutoSeqNumber__c> rsAutoNumMap = new Map<Id,AutoSeqNumber__c>([select id, name,SeqNumberPrifix__c from AutoSeqNumber__c where id in :rsIdSet]);
        // 2017/01/25 店舗ごとの会計権限機能対応 BEGIN
        /*
        for (Sobject rs: sobjList) {
            Id autoNumId = sobjIdMap.get(rs.Id);
            AutoSeqNumber__c autoSobj = rsAutoNumMap.get(autoNumId);
            //rs.put('Field145__c', autoSobj.SeqNumberPrifix__c + formatNumber(autoSobj.name));
            updSobjMap.put(rs.Id, 
            	setFullNoFlg == true ? autoSobj.SeqNumberPrifix__c + formatNumber(autoSobj.name) : formatNumber(autoSobj.name));
        }*/
        for (Integer idx : seqNoMap.keySet()) {
        	Id seqId = seqNoMap.get(idx).Id;
        	AutoSeqNumber__c autoSobj = rsAutoNumMap.get(seqId);
        	updSobjMap.put(idx, setFullNoFlg == true ? autoSobj.SeqNumberPrifix__c + formatNumber(autoSobj.name) : formatNumber(autoSobj.name));
        }
        // 2017/01/25 店舗ごとの会計権限機能対応 BEGIN
        } finally {
        	Database.rollback(sp);
        }
        return updSobjMap;
	}
}