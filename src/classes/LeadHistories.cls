public with sharing class LeadHistories {
	// Meta情報
	private static Schema.DescribeSObjectResult objectDescription;
    private static Map<String, Schema.SObjectField> sobjectFieldMap;

	// URLから引き渡し予約IDの配列変数
	private List<Id> leadIds;
	// 画面に表示する情報格納用
	public List<Id> exitHisLeads{get; private set;}
	public Map<Id, LeadHistoryItem> resultMap{get; private set;}
	
	static {
		// 予約Meta定義情報
		objectDescription = Lead__c.getSObjectType().getDescribe();
		// 予約の項目の関連定義情報
		sobjectFieldMap = objectDescription.fields.getMap();
	}
	public LeadHistories() {
		// 指定のURLの予約IDを取得、設定を行う
		String leadIdStr = System.currentPageReference().getParameters().get('leadIds');
		leadIds = CommUtils.isBlank(leadIdStr) ? new List<Id>() :leadIdStr.split(',');
	}
	public LeadHistories(List<Id> pLeadIds) {
		leadIds = pLeadIds;
	}
	// バッチPDF抽出機能の変更履歴抽出条件の開始時間
	private DateTime beginTime;
	// バッチPDF抽出機能の変更履歴抽出条件の終了時間
	private DateTime endTime;
	// 変更履歴抽出の場合、Createデータチェック用
	public static final String CREATE_FIELD = 'created';
	// 2017/05/15 バッチPDF抽出機能指定時間の変更履歴情報を取得する BEGIN
	public LeadHistories(List<Id> pLeadIds,DateTime pBeginTime,DateTime pEndTime) {
		leadIds = pLeadIds;
		beginTime = pBeginTime;
		endTime = pEndTime;
	}
	// 2017/05/15 バッチPDF抽出機能指定時間の変更履歴情報を取得する END
	public void init() {
        getObjectHistory(leadIds);
	}
	/**
	* 引き渡し予約履歴情報を初期化処理を行う
	**/
	//public static list<ObjectHistoryLine> formatHistoryMessage(List<Lead__History> historySl)
	private Map<Id, LeadHistoryItem> formatHistoryMessage(List<Lead__History> historySl) {
		 Map<Id, LeadHistoryItem> rsMap = new Map<Id, LeadHistoryItem>();
		 
		 for(Lead__History item : historySl){
		 	// 出力内容をFilter処理を行う
        	if(checkHisIdInfo(item)) {
        		Id leadId = item.ParentId;
        		// 履歴情報
	        	ObjectHistoryLine oneHisInfo = new ObjectHistoryLine(item);
				// 検索結果はMAPに格納する
				if (!rsMap.containsKey(leadId)) {
					//rsMap.put(leadId, new List<ObjectHistoryLine>());
					//LeadHistoryItem clsItem = new LeadHistoryItem();
					rsMap.put(leadId, new LeadHistoryItem());
				}
				rsMap.get(leadId).addItem(oneHisInfo);
        	}
         }

         return rsMap;
	}
	
	private void getObjectHistory(List<Id> pLeadIds) {
		
		// 予約履歴が存在する予約情報を集める
		exitHisLeads = new List<Id>();
		
		if(leadIds.isEmpty()) {
			resultMap = new Map<Id, LeadHistoryItem>();
			return;
		}
        // 該当予約関連の変更履歴情報を確認する
        // 2017/05/15 バッチPDF抽出機能指定時間の変更履歴情報を取得する BEGIN
		List<Lead__History> historySl = null;
		if (beginTime != null && endTime != null) {
			historySl = [Select ParentId,Parent.Name, OldValue, NewValue, Field, CreatedDate,CreatedById,CreatedBy.Name From Lead__History 
										where ParentId in :leadIds
										And CreatedDate < :endTime And CreatedDate >=: beginTime
										order by ParentId, CreatedDate desc];	
		} else {
			historySl = [Select ParentId,Parent.Name, OldValue, NewValue, Field, CreatedDate,CreatedById,CreatedBy.Name From Lead__History 
										where  Field != 'created'
										//And CreatedDate = TODAY 
										And ParentId in :leadIds
										order by ParentId, CreatedDate desc];
		}
		// 出力情報を書式化する
		resultMap = formatHistoryMessage(historySl);
		
		
        for(Id leadId : leadIds) {
        	if(resultMap.containsKey(leadId)) exitHisLeads.add(leadId);
        }
    } 
       
    // 変更履歴の情報が参照IDの場合、画面に表示対象外
    private boolean checkHisIdInfo(Lead__History history) {
    	// 2017/05/15 バッチPDF抽出機能指定時間の変更履歴情報を取得する BEGIN
    	if (history.field == CREATE_FIELD) return true;
    	// 2017/05/15 バッチPDF抽出機能指定時間の変更履歴情報を取得する END
    	//Schema.DescribeSObjectResult objDescription = Lead__c.getSObjectType().getDescribe();
    	Schema.DescribeFieldResult sobjResutlt = sobjectFieldMap.get(history.field).getDescribe();
    	DisplayType valueType = sobjResutlt.getType();
    	// 参照項目の場合、表示対象外になる
    	if(valueType == DisplayType.Reference)
    	{
    		SObjectType referenceObj = sobjResutlt.getReferenceTo()[0];
    		// 参照しているSobjectのKeyPrefix（３桁）
    		String objKeyPrefix = referenceObj.getDescribe().getKeyPrefix();
    		// 変更値の文字列は「KeyPrefix」で開始の場合、該当行目の情報は画面に非表示する
    		if((history.NewValue != null && string.valueOf(history.NewValue).startsWith(objKeyPrefix)) || (history.OldValue !=null &&string.valueOf(history.OldValue).startsWith(objKeyPrefix)))
    		// 該当対象内容は出力対象外になる
    		return false;
    	}
    	return true;
    }

    public class LeadHistoryItem {
    	public list<ObjectHistoryLine> histories{get; set;}
    	public Id leadId{get;private set;}
    	public String leadName{get;private set;}
    	public LeadHistoryItem()
    	{
    		histories = new List<ObjectHistoryLine>();
    		//histories = pHistories;
    		//leadId = histories[0].s.ParentId;
    		//leadName = histories[0].s.Parent.Name;
    	}
    	public void addItem(ObjectHistoryLine lineItem) {
    		if(histories.isEmpty()) {
    			leadId = lineItem.s.ParentId;
    			leadName = lineItem.s.Parent.Name;
    		}
    		histories.add(lineItem);
    	}
    }
    public class ObjectHistoryLine {
		
        public String theDate {get; set;}		// 変更日付
        public String who {get; set;}			// 変更者名
        public Id userId {get; set;} 			// 変更者ID
        public String action {get; set;}		// 変更内容
        public Lead__History s{get; private set;}
        //public String leadName{get; private set;}	// 予約名
        
        public ObjectHistoryLine(Lead__History pHistory)
        {
        	s = pHistory;
            // Set the Date and who performed the action
            theDate = datetime.valueof(s.CreatedDate).format();
            userId = String.valueOf(s.CreatedById);
            who = String.valueOf(s.CreatedBy.Name);
            //leadName = String.valueOf(s.Parent.Name);
            setActionInfo(s);
        }
        
        private void setActionInfo (Lead__History ps) {
    		// 2017/05/15 バッチPDF抽出機能指定時間の変更履歴情報を取得する BEGIN
    		if (ps.Field == CREATE_FIELD) return;
    		// 2017/05/15 バッチPDF抽出機能指定時間の変更履歴情報を取得する END
	        // Get the field label
	        //String fieldLabel = String.valueOf(sobjectFieldMap.get(ps.Field).getDescribe().getLabel());
    		Schema.DescribeFieldResult sobjResutlt = sobjectFieldMap.get(ps.Field).getDescribe();
    		String fieldLabel = sobjResutlt.getLabel();
    		DisplayType valueType = sobjResutlt.getType();
    		
    		String oldText = null;
    		String newText = null;
    		
    		if (ps.OldValue != null) {
				if(valueType == DisplayType.Date) 
					oldText = Date.valueOf(ps.OldValue).format();
				else if (valueType == DisplayType.DateTime) 
					oldText = DateTime.valueOf(ps.OldValue).format();
				else 
					oldText = String.valueOf(ps.OldValue);
    		}
    		if (ps.NewValue != null) {
				if(valueType == DisplayType.Date) 
					newText = Date.valueOf(ps.NewValue).format();
				else if (valueType == DisplayType.DateTime) 
					newText = DateTime.valueOf(ps.NewValue).format();
				else 
					newText = String.valueOf(ps.NewValue);
    		}
    		
	        // Set the Action value
	        if (oldText != null && newText == null) { // when deleting a value from a field
				// Format the Date and if there's an error, catch it and re
				//の
				//は削除されました。
	           	action = fieldLabel + ' '+ Label.CONST_041_0029 +' ' + CommUtils.nullToBlank(oldText) + ' '+ Label.CONST_041_0030;
			}
			else {  // all other scenarios
				if (!CommUtils.isBlank(newText)){
					//から
					String addMsg = CommUtils.isBlank(oldText) ? '' : ' '+ Label.CONST_041_0031 +' ';
					//は
					//に変更されました。
	                action = fieldLabel + ' '+ Label.CONST_041_0032 +' ' + CommUtils.nullToBlank(oldText) + addMsg + CommUtils.nullToBlank(newText) + ' '+ Label.CONST_041_0033;
	            }
	            else {
	            	//が変更されました。
	                action = fieldLabel + ' '+ Label.CONST_041_0034;
	            }
			}
        }
    }
}