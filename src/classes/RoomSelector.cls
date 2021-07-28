/*****************************
* 部屋選択画面
******************************/
public with sharing class RoomSelector {

    public List<Room__c> roomLst{get;set;}
    // 部屋タイプID
    private String pRoomTypeId{get;set;}
    // 部屋アサイン済みは対象外フラグ
    private Date pAssingDate{get;set;}
    private Date pAssingEndDate{get;set;}
    private Set<Id> pRoomIdSet{get; set;}
    // 検索条件
    public String c_roomNm{get; set;}
    public void init() {
    	// 前ページから引渡部屋タイプID
    	pRoomTypeId = ApexPages.currentPage().getParameters().get('pidx');
    	// 前ページから引渡アサイン日付
    	String assingDt = ApexPages.currentPage().getParameters().get('pdt');
    	pAssingDate = CommUtils.stringToDate(assingDt);
    	assingDt = ApexPages.currentPage().getParameters().get('pde');
    	pAssingEndDate = CommUtils.stringToDate(assingDt);
    	pRoomIdSet = new Set<Id>();
        // 部屋一覧を検索を行う
        this.queryInfo();
    }
    private static final String QueryHeader = 'select id, name ,Rnumber__c, CapacityHaku__c, Capacity__c, Field10__c, X3H__c, X3Hyoru__c, Field7__c, LAN__c From Room__c';
    private static final String OrderByStr = ' Order by Seq__c limit 200 ';
    public void queryInfo () {
        // 該当日に予約データがないデータだけ、画面を表示する？
        String queryStr = QueryHeader + getWhereStr() + OrderByStr;
        roomLst = Database.query(queryStr);
        // 予約日の日付をチェックする:次のVERSION
    }
    private String getWhereStr() {
        String whereStr = ' where TypeRoomRef__c = :pRoomTypeId ';
        if (!CommUtils.isBlank(c_roomNm)) {
           whereStr += ' AND name Like \'%' + CommUtils.escStr(c_roomNm) + '%\'';
        }
        // 該当日付が存在する場合、表示する部屋は非アサイン条件が必要
        // 2013/10/28 部屋割り当て可能チェックを行う
        if (pAssingDate != null && pAssingEndDate != null) {
        	pRoomIdSet.clear();
        	pAssingEndDate = (pAssingDate < pAssingEndDate ? pAssingEndDate.addDays(-1) : pAssingEndDate);
        	//Id bookingRecTypeId = CommLogicProcess.getLeadBookingRecType();
        	List<Id> bookingRecTypeId = RoomIndicatorInfo.getLeadBookingRecTypeLst();
	        for(AggregateResult r : [select Rroom__c roomNo from Lead__c
	        	where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG And RecordTypeId = :bookingRecTypeId
	                And DAY_ONLY(convertTimezone(EntryTime__c)) >= :pAssingDate
	                And DAY_ONLY(convertTimezone(EntryTime__c)) <= :pAssingEndDate
	                And refTypeOfRooms__c = :pRoomTypeId And Rroom__c != null Group by Rroom__c]) {
				pRoomIdSet.add((ID)r.get('roomNo'));
            }
            if (!pRoomIdSet.isEmpty()) whereStr += ' AND id not in :pRoomIdSet ';
        }
        return whereStr;
    }

}