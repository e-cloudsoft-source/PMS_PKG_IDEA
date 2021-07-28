@RestResource(urlMapping='/liquid/V1/*')
global with sharing class WS_LiquidKeyService {
    // /liquid/V1/getbookinginfo?searchkey=0000115884
    @HttpGet 
    global static ResponeRs doGet() {
        GetBookingInfoRS ret = new GetBookingInfoRS();
        // 指定のXMLからParseして、予約情報を取り込みを行う
        RestRequest req = RestContext.request;
        // サービス名を取得する
        try {
	        String serviceName = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
	        if (serviceName == 'getbookinginfo') {
	            String searchKey = req.params.get('searchkey');
	            ret = getbookinginfo(searchKey);
//System.debug(loggingLevel.info, 'ret：：：：：：：：='+ret);
	        }
        } catch (Exception e) {
            ret.CommonResponse = new WS_ResultInfo('E9999','システムエラーが発生しました');
            system.debug(logginglevel.error, e.getStackTraceString());
        }
        ResponeRs rep = new ResponeRs();
        rep.GetBookingInfoRS = ret;
        return rep;
    }
    @TestVisible
    private static GetBookingInfoRS getbookinginfo(String searchKey) {
        GetBookingInfoRS ret = new GetBookingInfoRS();
        // 引き渡すパラメータ情報を取得する
        //String searchKey = RestContext.request.params.get('searchkey');
        if (CommUtils.isBlank(searchKey)) {
            ret.CommonResponse = new WS_ResultInfo('E0002','予約確認用キーを設定ください');
            return ret;
        }

        // 予約情報を検索する　
        // 予約番号　OR　お客様の電話番号でヒントした当日の予約情報を返却する
        Lead__c rsLead = null;
        Date totdayDt = Date.today();
        //String leadNoKey ='I\\_____\\_'+searchKey;//予約インデックス番号
        String travNoKey = searchKey;//予約番号
        List<Lead__c> leads = [select id, LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c from Lead__c
            where DAY_ONLY(convertTimezone(EntryTime__c)) = :totdayDt And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
            And LeadIndexRef__r.TravelLeadNo__c = :travNoKey
            order by LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c
            limit 1
        ];
        // 直接番号で予約情報をヒントできない場合、電話番号で検索する
        if (leads.isEmpty()) {
            /* 2018/02/27 お客様から指示して、削除する
	        leads = [select id, LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c from Lead__c
	            where DAY_ONLY(convertTimezone(EntryTime__c)) = :totdayDt And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
	            And LeadIndexRef__r.Name Like :leadNoKey
	            order by LeadIndexRef__c desc, LeadIndexSubId__c, RoomGroupNo__c
	            limit 1
	        ];
	        // 予約インデックスの番号（NAME)で見つからない場合
            if (leads.isEmpty()) {
            */
            // お客様の電話番号で当日の予約情報をヒントする　
            String soslQuery = 'FIND :searchKey IN PHONE FIELDS RETURNING CONTACT(Id,name)';
            List<List<Sobject>> existRs = search.query(soslQuery);
            List<Contact> contacts = existRs[0];
            map<Id, Contact> contactMap = new map<Id, Contact>();
            for (Contact c : contacts) {
                contactMap.put(c.Id, c);
            }
            // 該当お客様に紐付け予約情報リストを取得する
            if (!contactMap.isEmpty()) {
	            // 該当お客様経由で予約情報を検索する
	            leads = [select id, LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c from Lead__c
	                where DAY_ONLY(convertTimezone(EntryTime__c)) = :totdayDt And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
	                And Relcontact__c in :contactMap.keySet()
	                order by LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c
	                limit 1
	            ];
	            if (!leads.isEmpty()) {
	                rsLead = leads[0];
	            }
            }
            /*
            } else {
                rsLead = leads[0];
            }*/
        } else {
            rsLead = leads[0];
        }

        // 予約情報
        if (rsLead == null) {
            ret.CommonResponse = new WS_ResultInfo('E0001',E0001_MSG);
            return ret;  
        }
        // 取得の予約情報により、連泊情報を取得する
        Id leadIdxId = rsLead.LeadIndexRef__c;
        String leadSubIdxId = rsLead.LeadIndexSubId__c;
        Decimal groupNo = rsLead.RoomGroupNo__c;
        // 取得の予約関連情報で返却情報を設定する
        List<Lead__c> rsLeads = [select EntryTime__c,Departure__c,Rroom__r.Name, StayPersons__c
            from Lead__c
            where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
            And LeadIndexRef__c = :leadIdxId And LeadIndexSubId__c = :leadSubIdxId And RoomGroupNo__c = :groupNo Order By EntryTime__c];
        if (rsLeads.isEmpty()) {
            ret.CommonResponse = new WS_ResultInfo('E0001',E0001_MSG);
            return ret;   
        } else {
	        // 到着日は当日、予約番号　Or　お客様の電話番号と一致する場合、予約情報を検索する
	        ret.BookingInfo.room_numer = CommUtils.nullToBlank(rsLeads[0].Rroom__r.Name);
	        ret.BookingInfo.reserved_from = rsLeads[0].EntryTime__c.format('yyyy-MM-dd HH:mm') + ':00';
	        ret.BookingInfo.reserved_to = rsLeads[rsLeads.size()-1].Departure__c.format('yyyy-MM-dd HH:mm') + ':00';
	        ret.BookingInfo.guest_number = CommUtils.nullToIntZero(rsLeads[0].StayPersons__c);            
        }
        return ret;
     }
    private static final String E0001_MSG = '予約情報を確認できません';
    global class ResponeRs {
        GetBookingInfoRS GetBookingInfoRS{get;set;}
    }
    @TestVisible
    class GetBookingInfoRS {
        public GetBookingInfoRS() {
            CommonResponse = new WS_ResultInfo();
            BookingInfo = new InBookingInfo();
        }
        WS_ResultInfo CommonResponse{get;set;}
        InBookingInfo BookingInfo{get;set;}
    }
    class InBookingInfo {
        String room_numer{get;set;}
        String reserved_from{get;set;}
        String reserved_to{get;set;}
        Integer guest_number{get;set;}
    }
    
}