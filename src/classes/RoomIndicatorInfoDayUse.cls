public with sharing class RoomIndicatorInfoDayUse {
    // 遷移先からパラメータ情報を格納する
    private static Map<String,String> paramMap;
    public List<LeadInfo> leadInfos{get; private set;}  
    public String topLeadId	{get;set;}
    public String roomId	{get;set;}
	// 初期化処理
    public void init(){
        // 表示情報を初期化する
        leadInfos = new List<LeadInfo>();
        // 戻るページ維持する
        paramMap = Apexpages.currentPage().getParameters();
        roomId = paramMap.get('roomId');	// 部屋ID
        topLeadId = paramMap.get('topLeadId');	// 画面部屋に指定した予約ID
        // データ抽出日
        Date todayDt = (String.isEmpty(paramMap.get('queryDate'))) ? Date.today() : Date.parse(paramMap.get('queryDate'));
        // 部屋タイプの予約RecordType
        List<Id> recTypeLst = RoomIndicatorInfo.getLeadBookingRecTypeLst();
        // 処理日関連の日付
        Date searchDt = RoomIndicatorInfo.getProcessDate(todayDt, Boolean.valueOf(paramMap.get('checkflag')));
        // 部屋IDに所属する予約情報リストを取得する
        List<Lead__c> roomLeads = [	Select id, name, LeadIndexSubId__c, LeadIndexRef__c, Field298__c, Field2__c, Field310__c, Field3__c, Field4__c,
        							Comment3__c, StayPersons__c, Rroom__r.Name, Relcontact__r.name,LeadIndexRef__r.Name, Field310__r.Name,EntryTime__c,
        							Departure__c
        							From Lead__c
									Where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG        // 有効な予約データ
                                        And RecordTypeId in :recTypeLst                         // 基本、宿泊のレコードタイプ予約データ
                                        And DAY_ONLY(convertTimezone(EntryTime__c)) = :searchDt // 到着日は指定日と一致する
                                        And Rroom__c = :roomId                             		// 部屋設定場合
                                     Order By Field4Cal__c asc 
        							];
        // 2018/04/04 DAYUSEデータは既に存在しない場合、処理中止BugFix zy
        if (roomLeads.isEmpty()) return;
		// SubIndex明細情報を取得する
      	String queryStr = ' Select Id, ParentLeadIndxRef__c, DepartureDate__c, EntryDate__c, Nights__c From LeadIndex__c ';
		String whereStr = ' Where ';
		for (Lead__c lead : roomLeads) {
			whereStr += ' ( '
					 +  ' ParentLeadIndxRef__c = \'' + String.escapeSingleQuotes(lead.LeadIndexRef__c) + '\''
// 2014/09/22 予約インデクスSUBが未設定する場合、検索条件対象外になる
					 //+  ' And Id = \'' + String.escapeSingleQuotes(lead.LeadIndexSubId__c) + '\''
					 +  (CommUtils.isBlank(lead.LeadIndexSubId__c) 
					 		? ''
					 		: ' And Id = \'' + String.escapeSingleQuotes(lead.LeadIndexSubId__c) + '\'' 
					 	)
//					 +  ' And RoomGroupNo__c = ' + lead.RoomGroupNo__c 
					 +  ' ) ';
			whereStr += ' OR ';
		}
		queryStr += whereStr.trim().removeEnd('OR');
		// 各予約の明細情報を取得する
		Map<String, LeadIndex__c> subIdxMap = new Map<String, LeadIndex__c>();
		for (LeadIndex__c subIdx : DataBase.query(queryStr)) {
			String key = subIdx.ParentLeadIndxRef__c + '_' + subIdx.Id;
			subIdxMap.put(key, subIdx);
		}
		// 出力情報を取得する
		for (Lead__c lead : roomLeads) {
			LeadInfo item = new LeadInfo(lead);
			item.checkinTime = lead.Field4__c;
			item.checkoutTime= lead.Field3__c;
			// SubIndex情報から補足情報を設定する
			String key = lead.LeadIndexRef__c + '_' + lead.LeadIndexSubId__c;
			if (subIdxMap.containsKey(key)) {
				LeadIndex__c subIdx = subIdxMap.get(key);
				item.checkinDate = DateTime.newInstance(subIdx.EntryDate__c.year(), subIdx.EntryDate__c.month(), subIdx.EntryDate__c.day()).format(CommBaseCtrl.getDateFormat());
				item.checkoutDate= DateTime.newInstance(subIdx.DepartureDate__c.year(), subIdx.DepartureDate__c.month(), subIdx.DepartureDate__c.day()).format(CommBaseCtrl.getDateFormat());
				item.nights = CommUtils.nullToIntZero(subIdx.Nights__c);
			}
			leadInfos.add(item);
		}
    }
    
    // 画面に表示する予約情報
    public class LeadInfo{   
        public LeadInfo(Lead__c lead){
            checkoutTime = lead.Field3__c;
            checkinTime = lead.Field4__c;
            s = lead;
            startTime = lead.EntryTime__c.format('yyyyMMdd') + lead.Field4__c;
            endTime = lead.Departure__c.format('yyyyMMdd') + lead.Field3__c;
        }
        //public String roomId{get;set;}
        public String checkoutTime{get;set;}
        public String checkoutDate{get;set;}
        public String checkinTime{get;set;}
        public String checkinDate{get;set;}
        public String startTime{get;set;}
        public String endTime{get;set;}
        public Integer nights{get;set;}
        // LeadInfo
        public Lead__c s{get;set;}
    }
}