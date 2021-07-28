public without sharing class CommNoAuthLimitUtil {
   
	/**
	* シフト画面から活動集計情報を取得機能「権限制御なし」
	* return:map<日付_ownerid,数量>
	**/
	/*
    public map<string,integer> getEventSummary(Date conStartDate, Date conEndDate,Set<Id> userIds) {
		Map<String, Integer> utMap = new Map<String, Integer>();
		List<AggregateResult> etResult = [	select count(ID) cnt, OwnerId, ActivityDate from Event 
									    	where OwnerId =:userIds and ActivityDate >= :conStartDate and ActivityDate <= :conEndDate
									    	group by OwnerId, ActivityDate];
		for (AggregateResult avg : etResult) {
	    		Object activityDate = avg.get('ActivityDate');
	    		String key = (activityDate == null ? '' : ((Date)activityDate).format()) +'_'+ CommUtils.nullToBlank(avg.get('OwnerId'));
	    		utMap.put(key, CommUtils.nullToIntZero(avg.get('cnt')));
		}
		return utMap;
    }
    public list<Event> getEventListByOwnerId(Id userId, Date dt) {
    	return [select Id, OwnerId, Subject, ActivityDate, Description, StartDateTime, EndDateTime, IsAllDayEvent from Event where OwnerId =:userId and ActivityDate =:dt];
    }
    */
    // IOT使うアイコンファイルを取得する
    public static map<string,string> getIotIconInfoMap(list<string> iotIconTitleList) {
    	List<ContentVersion> iotvers = [select id,ContentDocumentId, Title from ContentVersion where IsLatest = true And Title in :iotIconTitleList Order By CreatedDate Desc];
    	map<string,String> iotIconMaps = new map<string, String>();
    	for (ContentVersion ver : iotvers) {
    		string key = ver.Title;
    		String val = ver.ContentDocumentId + ':' + ver.Id;
    		if (!CommUtils.isBlank(key) && !CommUtils.isBlank(val) && !iotIconMaps.containsKey(key)) iotIconMaps.put(key,val);
    	}
    	return iotIconMaps;
    }
    // 2019/09/12 連携ファイルアクセス権限解除対応 BEGIN
    public static List<Folder> getFolderId(String folderApiNm) {
    	return [select Id from Folder where DeveloperName = :folderApiNm];
    }
    public static List<Document> getFiles(Id syncFolderId, Date locStartDt, Date locEndDt, String q) {
    	return DataBase.query(q);
    }
    // 2019/09/12 連携ファイルアクセス権限解除対応 END
}