/**********************************
* 宴会場予約管理画面
* 2012/07/31 初版作成
* 2012/09/01 作業開始時間：9時から5時に変更する
* 2012/09/30 会場おさえ：ステータス追加の対応
* 2013/07/29 支店機能追加
* 2013/10/17 顧客入力項目追加対応
* 2013/11/28 時刻設定すると、表示対象外になる、エラーメッセージは画面に戻る
* 2014/03/12 予約情報の出発時刻は朝の５時を超える場合、５時まで表示対応
* 2014/04/08 タイムテーブルに到着時刻は０時以後、到着時刻は５時まで設定されている場合、警告エラー追加
* 2014/07/03 タイムテーブルは０時～５時間に予約登録と表示機能対応
***********************************/
public with sharing class BookingTimeTable {
	public boolean isCanUpdateLead{get{return CommSecurityUtils.isCanUpdateLead();}}
	public List<Room__c>      room{get;private set;}                                   	/* Room data    */
//	public List<Lead__c>      booking;													/* Booking data */
	public Lead__c            bookingform {get; set;}									/* For creating new Booking Data*/
	public string             contactName {get; set;}
	public Contact 			  newContact{get;set;}										/* 新規入力お客様情報を格納する */
//	public Lead__c            pbookingform;												/* Previous Booking Form Data for Checkking Duplication */
//	public string             linkid {get; set;}										/* Created Booking Record Id */
//	public string             linkname {get; set;}										/* Created Booking Record Name */
	public List<integer>      hours;													/* Hours of Columns */
//	public integer            starthour {get; set; }									/* Hour of Start Column */
//	public integer            endhour {get; set; }										/* Hour of End Column */

	private DateTime   beginBusinessTime;
	private DateTime   endBusinessTime;
	//public String beginBusinessHm{get; private set;}
	//public String endBusinessHm{get; private set;}
	private Map<String, String> timeColorMap;
	public Map<String, String> timeTipsMap{get;private set;}
	// 時間設定アリアに情報を維持する
	public Map<Id, OneRoomAssingInfo> roomBookingMap{get;private set;}
	private static final String ROOM_TYPE_PTY = CommConst.ROOM_UseOfType_PTY;
	private static final Integer CONST_BUSNIESS_TIME = 5;
	private static String todayBenginTime = '05:00';
	// 到着日
	@TestVisible private date               cdate;
    // 当日のDataId
    private final String bookingTimeTbId;
    // 当日のタイムテーブル情報
    public final BookingTimeTable__c currSobj{get; private set;}
    // エラーメッセージ
    public String showInfoError{get;set;}	// 時刻順番設定不正チエック
    public String showInfoError2{get; set;}	// 朝０時〜朝５まで設定されている場合、警告情報を格納する
	
	public BookingTimeTable(ApexPages.StandardController stdController){
		// タイムテーブルのID
		bookingTimeTbId = stdController.getId();
		// 到着日情報を取得する
		currSobj = [select Id, Name, Checkinday__c from BookingTimeTable__c where Id = :stdController.getId() limit 1];
		cdate = currSobj.Checkinday__c;
		// 宴会ルーム情報を取得する
		room = [select Id, Name, UseOfRoom__c, Seq__c from Room__c where UseOfRoom__c =: ROOM_TYPE_PTY order by Seq__c];

        // 入りフォーム情報を初期化する
        initBookingFormInfo();

        // 営業開始時間から営業終了時間設定を行う
        beginBusinessTime = DateTime.newInstance(cdate,Time.newInstance(CONST_BUSNIESS_TIME, 0, 0, 0));
        endBusinessTime = beginBusinessTime.addHours(24);

        // 既にアサイン済み時間を画面に表示するの設定
        refreshTimePanel();
	}
	// 初期化処理
    public BookingTimeTable() {
        // 初期化選択条件
        selectDate = new BookingTimeTable__c();

		// 2013/07/29 支店機能追加
		setInitBranShopLst();
		
    	// 当日の情報を表示する
    	cdate = Date.today();
        // 宴会ルーム情報を取得する
        //room = [select Id, Name, UseOfRoom__c, Seq__c from Room__c where UseOfRoom__c =: ROOM_TYPE_PTY order by Seq__c];
		setShowRooms();
		
		// 各タイムランの定義情報を取得する
		timeColorMap = new Map<String, String>();
		timeTipsMap = new Map<String, String>();
		for (BookingTimeTable__c bkTime : [select id, TimeLineComment__c, TimeLst__c, Color__c from BookingTimeTable__c Where TimeLst__c != null And Color__c != null order by TimeLst__c asc] ) {
			timeColorMap.put(bkTime.TimeLst__c, bkTime.Color__c);
			timeTipsMap.put(bkTime.TimeLst__c, CommUtils.nullToBlank(bkTime.TimeLineComment__c));
		}
		
        // 入りフォーム情報を初期化する
        initBookingFormInfo();

        // 日付関連項目を一括設定する
        setDateField(cdate);
        
		// 表示用時間帯設定[最後に処理ください]
		setTimeLineHtml();
    }
	// 画面に表示する部屋リストを設定する
	private void setShowRooms () {
        String roomQuery = ' select Id, Name, UseOfRoom__c, Seq__c from Room__c where UseOfRoom__c =: ROOM_TYPE_PTY  ';
        if (!CommUtils.isBlank(branchShopNm)) roomQuery+= ' And ShopInfoRef__r.ShopCode__c = :branchShopNm ';
		roomQuery += ' order by Seq__c ';
		room = DataBase.query(roomQuery);
	}
   	// -------------------------------------------
   	// 各店舗の表示する項目情報を取得、格納を行う
    // -------------------------------------------
    private static final String LeadConstFields  = 'Name,Relcontact__c,EntryTime__c,Field4__c,Departure__c,Field3__c,Rroom__c,StayPersons__c,SeminarOrderFlg__c,Field310__c,Field2__c';
   	private Component.Apex.pageBlockSection parseFieldsXml(String pShopCode) {
   		
   		Component.Apex.pageBlockSection psection = new Component.Apex.pageBlockSection();
   		psection.columns = 1;
   		// 拡張予約項目を定義する
   		//String[] extendFields = new String[]{};
    	// ログインユーザーの店舗コードが存在チェックを行う
    	List<Document> sr = [select body, name from Document where DeveloperName = 'BookingTimeLeadInputExtendFieldsXml'];
    	if (sr.isEmpty()) return psection;
    	Blob xmlBody = sr[0].Body;
    	String strXmlBody = xmlBody.toString();
    	
    	Dom.XmlNode targetNode, firstNode = null;
		Dom.Document doc = new Dom.Document();
		doc.load(strXmlBody);
		Dom.XMLNode root = doc.getRootElement();
		for(Dom.XMLNode shop : root.getChildElements()) {
			// 各店舗情報はＸＭＬから取得する
			Dom.XmlNode shopcode =  shop.getChildElement('SHOPCODE', null);
			// 店舗コードを取得する
			String strShopCode = CommUtils.nullToBlank(shopcode.getText());
			if (firstNode == null) firstNode = shop;
			// ログインユーザの店舗コードと一致する場合
			if (strShopCode == pShopCode) {
				targetNode = shop;
				break;
			}
		}
		// 目標店舗情報を取得する、店舗コード未設定する場合、一番目の店舗情報で設定する
		targetNode = targetNode == null ? firstNode : targetNode;
		if (targetNode == null) return psection;
		
		// 画面に既存の予約項目重複処理
		List<String> constFieldsList = LeadConstFields.deleteWhitespace().split(',');
		Set<String> dupliateSet = new Set<String>(constFieldsList);
		// 店舗情報はＸＭＬから取得する
		Dom.XmlNode shopFields =  targetNode.getChildElement('FIELDS', null);
		String strFields = (shopFields == null ? '' : CommUtils.nullToBlank(shopFields.getText()).deleteWhitespace());
		List<String> fieldsSplits = strFields.split(',');
		// 重複する項目は無くす
		List<String> extendFieldsLst = new List<String>();
		// 予約に固定使用する項目APIから無くす
		for (String extendField : fieldsSplits) {
			if (CommUtils.isBlank(extendField)) continue;
			if (!dupliateSet.contains(extendField) ) extendFieldsLst.add(extendField);
		}
		for (String fieldKey : extendFieldsLst) {
			Component.Apex.InputField inputField = new Component.Apex.InputField();
			inputField.expressions.value = '{!bookingform.'+fieldKey+'}';
			psection.childComponents.add(inputField);
		}	
		return psection;
   	}
   	
    // ボタン「翌日」の処理
    public void toNext(){
        cdate = cdate.addDays(1);
        setDateField(cdate);
        refreshTimePanel();
    }
    // ボタン「翌週」の処理
    public void toNextWeek(){
        cdate = cdate.addDays(7);
        setDateField(cdate);
        refreshTimePanel();
    }
    public void toToday() {
    	cdate = Date.today();
    	setDateField(cdate);
    	refreshTimePanel();
    }
    // ボタン「前週」の処理
	public void toPrevWeek() {
		cdate = cdate.addDays(-7);
		setDateField(cdate);
		refreshTimePanel();
	}
    // ボタン「前日」の処理
    public void toPrev(){
        cdate = cdate.addDays(-1);
        setDateField(cdate);
        refreshTimePanel();
    }
    public BookingTimeTable__c selectDate{get; private set;}
    // 年/月/日を選択する場合
    public void gotoDate() {
        cdate = selectDate.Checkinday__c;
        setDateField(cdate);
        refreshTimePanel();
    }
    // 支店選択リスト変更の場合、関連の支店所属する部屋を取得、情報を表示する
    public void refreshBranchShopInfo() {
    	// 表示用部屋リストを取得する
		this.setShowRooms();
		// 最新情報を取得する
		this.gotoDate();
    }
    
    // 業務ロジック関連日付設定を行う
    private void setDateField(Date currDate) {
    	// 検索条件：日付連動設定
    	selectDate.Checkinday__c = currDate;
        // 営業開始時間から営業終了時間設定を行う
        beginBusinessTime = DateTime.newInstance(currDate,Time.newInstance(CONST_BUSNIESS_TIME, 0, 0, 0));
        endBusinessTime = beginBusinessTime.addHours(24);
    }

	// 部屋一覧を取得する
	public List<Room__c> getRoom(){												/* Get Room data */
		return room;
	}

	// 最新時間設定表示を最新化を行う
	public void refreshTimePanel() {

		roomBookingMap = new Map<Id, OneRoomAssingInfo>();
        // 親子関係情報設定を行う
        RoomMapInfo roomMapInf = genRoomRelationMap();
        Map<Id, List<Lead__c>> roomRelMap = new Map<Id, List<Lead__c>>();
System.debug('roomMapInf::' + roomMapInf);

		for (Room__c r: room) {
			roomBookingMap.put(r.Id, new OneRoomAssingInfo(beginBusinessTime, endBusinessTime, roomBookingMap.size(), timeColorMap));
		}
		// 取得するデータの正確性チェックを行う
		showInfoError = '';
		showInfoError2 = '';
		// 既に登録済みの時間を取得する
		Set<Id> leadIdSet = new Set<Id>();
		Date startDate = cdate;
		Date endDate = cdate.addDays(1);
        List<Lead__c> booking = [select Id, Name, Relcontact__c, Rroom__c, Rroom__r.Name, Rroom__r.Seq__c, StayPersons__c,
                    EntryTime__c,Departure__c,ReservedStatus__c,
                    Field310__c, Field2__c, Field4__c, Field3__c, Field363__c
                    from Lead__c
                    where 
                    //where ReservationDate__c = :cdate
                    DAY_ONLY(convertTimezone(EntryTime__c)) <= :endDate
               		and DAY_ONLY(convertTimezone(Departure__c)) >= :startDate
                    and CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG         // キャンセルデータは対象外
                    and Rroom__c != null and Rroom__r.UseOfRoom__c =: ROOM_TYPE_PTY order by Rroom__r.Seq__c];
        for (Lead__c lead: booking) {
        	DateTime startDtime = getGobalCalTimeDate(lead.EntryTime__c, lead.Field4__c);
        	DateTime endDtime = getGobalCalTimeDate(lead.Departure__c, lead.Field3__c);
        	String startTime = startDtime.format('HH:mm');
        	String endTime = endDtime.format('HH:mm');
        	//---------- TODAY---------||||||||||||TOMOROOW||||||||
        	// ---------05:00----------00:00---------05:00
        	// --- P1---|   当日の５時までに出発の予約データ
        	if (endDtime.date() == cdate && endTime <= todayBenginTime ) continue;
        	//---------- TODAY---------||||||||||||TOMOROOW||||||||
    		// ---------05:00----------00:00---------05:00------------
    		// 翌日の５時以後の宴会場データ　                    ---- p2 ----
        	if(cdate < startDtime.date() && startTime >= todayBenginTime ) continue;
        	// 日帰り AND 時刻逆設定不正の場合
        	if (startDtime >= endDtime) {
    			// 到着時刻と出発設定不正ため、該当予約データは表示対象外になる、下記リンクを
    			//Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '<a href="/' + lead.Id + ' target="blank" >'+lead.Name+'</a>の到着時刻と出発時刻の設定が行不正ので、修正してください'));
    			showInfoError +=  '&nbsp;&nbsp;【<a href="/' + lead.Id + '/e" target="_blank" >'+lead.Name+'</a>】<br/>';
    			continue;
        	}
        	// 到着時刻は０時以後、出発時刻は５時以前の場合、警告エラーを表示する
        	/* 2014/07/03 タイムテーブルは０時～５時間に予約登録と表示機能対応
		String startTime = startDtime.format('HH:mm');
        	String endTime = endDtime.format('HH:mm');
        	if (startTime >= '00:00' && startTime < '05:00' && endTime <= '05:00') {
    			showInfoError2 +=  '&nbsp;&nbsp;【<a href="/' + lead.Id + '/e" target="_blank" >'+lead.Name+'</a>】<br/>';
    			continue;
        	}*/
        	/*
        	// 日帰り AND 時刻設定不正の場合
        	if (lead.EntryTime__c.date() == lead.Departure__c.date()) {
        		if (CommUtils.nullToZero(lead.Field4__c.replace(':','')) >= 
        			CommUtils.nullToZero(lead.Field3__c.replace(':',''))) {
        			// 到着時刻と出発設定不正ため、該当予約データは表示対象外になる、下記リンクを
        			//Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '<a href="/' + lead.Id + ' target="blank" >'+lead.Name+'</a>の到着時刻と出発時刻の設定が行不正ので、修正してください'));
        			showInfoError +=  '&nbsp;&nbsp;【<a href="/' + lead.Id + '/e" target="_blank" >'+lead.Name+'</a>】<br/>';
        			continue;
        		}
        	}*/
        	// 存在する場合
        	if (roomBookingMap.containsKey(lead.Rroom__c)) {
                OneRoomAssingInfo roomAss = roomBookingMap.get(lead.Rroom__c);
                roomAss.assingLeadInfo(lead);
        	} else {
        		OneRoomAssingInfo roomAss = new OneRoomAssingInfo(beginBusinessTime, endBusinessTime, roomBookingMap.size(), timeColorMap);
        		roomAss.assingLeadInfo(lead);
        		roomBookingMap.put(lead.Rroom__c, roomAss);
        	}
        	leadIdSet.add(lead.Id);

        	// 連動部屋の予約情報を取得する
        	// 連動部屋場合 2013/02/12 BEGIN
        	/*
        	if (roomMapInf.isRelationRoom(lead.Rroom__c)) {
        		//
        		if (!roomRelMap.containsKey(lead.Rroom__c)) {
        			roomRelMap.put(lead.Rroom__c, new List<Lead__c>());
        		}
        		roomRelMap.get(lead.Rroom__c).add(lead);
        	}
        	*/
        }

        // 連動部屋処理対象あり場合
        if (!roomMapInf.isEmpty()) {
//System.debug('roomMapInf:::' + roomMapInf);
            //for (Id roomId : roomBookingMap.keySet()) {
            	// 連動関係なしの部屋場合、処理対象外になる
            	//if (!roomMapInf.isRelationRoom(roomId)) continue;
            	// 該当部屋の設定情報を取得して、関連の部屋へコピーを行う
            	//OneRoomAssingInfo oneRoom = roomBookingMap.get(roomId);
            	roomMapInf.cloneLeadByRelRoom(roomBookingMap);
                //oneRoom.assingAccountInfo(leadAccRefMap);
                
            //}

        }

        // 20121003 ADD 会計情報を取得する
        // 顧客ID/会計ID
        Map<Id, Id> leadAccRefMap = new Map<Id, Id>();
        // １予約->1会計（基本：1->N存在可能性があり（操作ルール違反）も対応：最新作成の会計は使用する）
        for (AccountAcount__c acc : [select id, relaccount__c from AccountAcount__c where Relreserve__c in :leadIdSet And relaccount__c != null order by LastModifiedDate desc ]) {
            if (leadAccRefMap.containsKey(acc.relaccount__c)) continue;
            leadAccRefMap.put(acc.relaccount__c, acc.id);
        }

        // 会計情報は各InnerClassに引き渡す
        if (!leadAccRefMap.isEmpty()) {
	        for (OneRoomAssingInfo oneRoom : roomBookingMap.values()) {
	        	oneRoom.assingAccountInfo(leadAccRefMap);
	        }
        }
	}

	/**
	* 顧客情報最新取得を行う
	**/
	// SOQL顧客情報項目定義
	private static final String queryContStr = 'Select Id, Phone, Name1__c, Name, Memo6__c, Memo5__c, Memo4__c, Memo3__c, Memo2__c, Memo1__c, Katakana__c, KanaName2__c, KanaName1__c,Account.Name,ApplicantName__c,ApplicantPhone__c From Contact ';
	@remoteAction
	public static ContactInfo refreshContcatInfo(String contactId, String contactName) {
		String whereStr = ' where id = \'' + CommUtils.escStr(contactId) + '\' ';
		whereStr += ' And Name = \'' + CommUtils.escStr(contactName) + '\' limit 1';
		List<Contact> contactLst = Database.query(queryContStr + whereStr);
		if (contactLst.isEmpty()) {
			return new ContactInfo(new Contact());
		} else {
			return new ContactInfo(contactLst[0]);
		}
	}
	public class ContactInfo {
		public ContactInfo(Contact c){
			KanaName = CommUtils.nullToBlank(c.KanaName1__c);
			KatakanaName = CommUtils.nullToBlank(c.Katakana__c);
			phone = CommUtils.nullToBlank(c.Phone);
		}
		public String KanaName{get;set;}	// カタカナ
		public String KatakanaName{get;set;} //ひらがな、
		public String phone{get;set;}		// Phone
	}
	// プラン明細情報を取得する
	@remoteAction
	public static List<ProductItemUtils.PlanDetail> getPlanDetailListById(String planId) {
		return ProductItemUtils.getPlanDetailList(planId);
	}
	// 商品コードにより、会計商品情報を取得する
	@remoteAction
	public static List<ProductItemUtils.ProductItem> getArrayProductItemInfo(String prodCode) {
		return ProductItemUtils.getArrayProdcutItemByCode(prodCode, true);
	}
	
	/**
	* 予約情報拡張設定項目作成する
	**/
	//private String[] extendFields = new String[]{};
	//private transient Component.Apex.pageBlockSection psection;
	public Component.Apex.pageBlockSection getInputExtendFields () {
		// 拡張情報を取得する
		Component.Apex.pageBlockSection psection = parseFieldsXml(branchShopNm);
		return psection;
	}
    // ***************************
  	// 予約を保存する
  	// 設定情報にて、予約、予約インデックス情報を新規登録する
  	// ***************************
  	// データ登録の事前チェック
  	private Boolean preBookingCreate() {
  		// 処理に必須な項目が未入力の場合、処理を中止する
  		// お客様/予約名/予約チャネル
  		if((CommUtils.isBlank(bookingform.Relcontact__c) && CommUtils.isBlank(contactName) ) ||
  			CommUtils.isBlank(bookingform.Name) ||
  			CommUtils.isBlank(bookingform.Rroom__c) ||
  			bookingform.StayPersons__c == null) {
  			//必須項目を入力してください。
  			Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_005_0069));
  			return false;
  		}
  		
  		/*
  		// 日帰りの場合、到着日と出発日の時刻チェックを行う
  		if (staysNums == 0) {
  			// 2013/09/16 TIME:[H:M]書式対応ため、下記処理を追加する
  			Time startTime = CommUtils.stringToTime(newLead.Field4__c);
  			Time endTime = CommUtils.stringToTime(newLead.Field3__c);
  			//if (newLead.Field4__c >= newLead.Field3__c) {
  			if (startTime >= endTime) {
  				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '出発時刻には到着時刻以降の時刻を指定して下さい'));
  				return false;
  			}
  		}
  		// Defautl値設定
  		if (staysNums == null) staysNums = 0;*/
  		if (!CommUtils.isBlank(bookingform.Relcontact__c)) newContact.Id = bookingform.Relcontact__c;
  		return true;
  	}

	public List<Integer> getHours(){													/* List of Hours */
		hours = new List<Integer>();
		for (Datetime dt = beginBusinessTime; dt < endBusinessTime;) {
            hours.add(dt.hour());
            dt = dt.addHours(1);
		}
		return hours;
	}
	
	/**
	* Time Line Table Header Html Generator
	* Created Date: 2013/04/04 
	* Modify Date:  2013/04/19 <td><tr>作成方法はＶＦに移動する
	**/
	public List<String> headerTimeList{get;set;}
	public Map<String, Integer> tdColspanInfoMap {get;set;}
	public void setTimeLineHtml() {
		headerTimeList = new List<String>();
		tdColspanInfoMap = new Map<String, Integer>();
		
		for (Datetime dt = beginBusinessTime; dt < endBusinessTime;) {
            
            String hhmm  = dt.format('HH:mm');
            if (timeTipsMap.containsKey(hhmm)) {
            	// 次の１０分のTIME LINE定義できません.
            	dt = dt.addMinutes(10);
            	tdColspanInfoMap.put(hhmm, 2);
            }
            else {
            	//timeTipsMap.put(hhmm, '');
            	tdColspanInfoMap.put(hhmm, 1);
            }
            headerTimeList.add(hhmm);
            
            dt = dt.addMinutes(10);
		}
	}
	/**************************
	* 予約データ作成処理
	***************************/
	public Boolean bookingCreateOK{get;set;}
	public PageReference bookingCreate() {												/* Save New Booking Record */
		// 事前チェックを行う
		if (!preBookingCreate()) return null;
		
		// 2017/02/24 Field Security Check BEGIN by wx
		List<String> insChkFields = new List<String>{'Field356__c','Field357__c','ReservedStatus__c','Departure__c',
													'EntryTime__c','Field3__c','Field4__c','Relcontact__c','ReservedType__c',
													'RecordTypeId','ReservedDate__c','StayPersons__c'};
		Map<String,Schema.SObjectField> insm = Schema.SObjectType.Lead__c.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(insChkFields, insm)) {
			return null;
		}
		// 2017/02/24 Field Security Check End by wx
        try{
        	
	  		// 2013/10/17お客様情報を自動登録機能追加する
	  		upsertContact();
  		
            // yyyy-mm-dd hh:mm
            String s = bookingform.Field4__c + ':00';
            String e = bookingform.Field3__c + ':00';

            bookingform.Field4__c = bookingform.Field4__c.subString(11,16);
            bookingform.Field3__c = bookingform.Field3__c.subString(11,16);

            bookingform.EntryTime__c = DateTime.valueOf(s);//datetime.newInstance(cdate,time.newInstance(Integer.valueOf(beginHH),Integer.valueOf(beginMM),0,0));
            bookingform.Departure__c = DateTime.valueOf(e);//datetime.newInstance(cdate,time.newInstance(Integer.valueOf(endHH),Integer.valueOf(endMM),0,0));
			// 予約ステータス初期値設定[確定]
			bookingform.ReservedStatus__c = CommConst.LEAD_ST_CHECKED;
			// 予約確認の方
			bookingform.Field357__c = UserInfo.getName();
			// 予約確認済み
			bookingform.Field356__c = true;
            insert bookingform;
        } catch (Exception e) {
			ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'An error has occured. Please check the object or try again later');
			ApexPages.addMessage(errormsg);
//System.debug(LoggingLevel.ERROR,'Create Error:' + e.getMessage());
			bookingCreateOK = false;
			return null;
        }

        // 入りフォーム情報を初期化する
		initBookingFormInfo();
		// 2012/09/12 Add
		setDateField(cdate);
        // 最新表示情報を作成する
		refreshTimePanel();
  		// 2013/06/24 ADD BEGIN
  		// Data Create OK
  		bookingCreateOK = true;
  		
		return null;
	}
  	// お客様情報新規登録・更新を行う
    private void upsertContact() {
    	// 2017/02/21 Field Security Check BEGIN
		List<String> chkFields = new List<String>{'FirstName','LastName'};//,'Id'
		Map<String,Schema.SObjectField> m = Schema.SObjectType.Contact.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFields, m)) {
			return;
		}
		// 2017/02/21 Field Security Check End
    	// 顧客情報の新規作成
    	if (newContact.Id == null) {
    		String[] names = CommUtils.splitName(contactName);
    		newContact.LastName = names[0];
    		newContact.FirstName = names[1];
    	}
    	upsert newContact;
    	bookingform.Relcontact__c = newContact.Id;
    }
    
	private void initBookingFormInfo() {
        bookingform = new Lead__c();
        newContact = new Contact();
        contactName = '';
        bookingform.ReservedDate__c = datetime.now();
        bookingform.RecordTypeId = CommLogicProcess.getLeadEnkaiRecType();
        //bookingform.StayPersons__c = 2;
        bookingform.StayPersons__c = CommConst.getBookingPeopleDef();
        //宴会
        bookingform.ReservedType__c = Label.CONST_005_0077;
	}

	/**
	* 親子部屋関係構築
	**/
	private RoomMapInfo genRoomRelationMap() {

		Map<Id, Set<Id>> roomRelMap = new Map<Id, Set<Id>>();
        // 子部屋を全部取得する
//        for(Room__c item : [select Id, ParentRoomRef__c from Room__c where ParentRoomRef__c != null and UseOfRoom__c =: CommConst.ROOM_UseOfType_PTY]) {
        String roomQuery = ' select Id, ParentRoomRef__c from Room__c where ParentRoomRef__c != null and UseOfRoom__c =: ROOM_TYPE_PTY  ';
        if (!CommUtils.isBlank(branchShopNm)) roomQuery+= ' And ShopInfoRef__r.ShopCode__c = :branchShopNm ';
//System.debug('genRoomRelationMap.roomQuery:::' + roomQuery);
//System.debug('branchShopNm:::' + branchShopNm);
		for(Room__c item : DataBase.query(roomQuery)) {
		
            String pKey = item.ParentRoomRef__c;
            if (!roomRelMap.containsKey(pKey)) {
            	roomRelMap.put(pKey, new Set<Id>());
            }
            roomRelMap.get(pKey).add(item.Id);
        }
        return new RoomMapInfo(roomRelMap, beginBusinessTime, endBusinessTime);
	}

    /**
    * 部屋関連情報を格納する
    **/
    public class RoomMapInfo {
    	// Map<ParentRoomId/ChildRoomSet>
    	private Map<Id, Set<Id>> parentMap;
    	// Map<ChildRoomId/ParentRoomId>
    	private Map<Id, Id> childMap;
    	// 関係ありの部屋IDは全部SETに格納する
    	private Set<Id> idSet;
        // 営業開始時間と終了時間
        private DateTime beginBusinessTime;
        private DateTime endBusinessTime;
    	
    	// 初期化
    	public RoomMapInfo(Map<Id, Set<Id>> rMap, DateTime pBeginBusinessTime, DateTime pEndBusinessTime) {
    		// 関連関係あるのIDはSetに格納する
    		idSet = new Set<Id>();
    		isEmptyFlg = true;
    		if (rMap == null || rMap.isEmpty())  return;
    		
    		// データ存在場合
    		isEmptyFlg = false;
    		// ID格納を行う
    		idSet.addAll(rMap.keySet());
    		for (Set<Id> cIdSet : rMap.values()) {
    			idSet.addAll(cIdSet);
    		}
    		parentMap = rMap;
    		// ChildRoom情報
    		childMap = new Map<Id, Id>();
    		for (Id pId : rMap.keySet()) {
    			for (Id cId : rMap.get(pId)) childMap.put(cId, pId);
    		}
    		
    		beginBusinessTime = pBeginBusinessTime;
    		endBusinessTime = pEndBusinessTime;
    	}

    	// 関係あり部屋なしフラグ
    	private boolean isEmptyFlg;
    	public boolean isEmpty() { return isEmptyFlg;}

    	// 親部屋IDにて、子部屋配列を戻る
    	public Set<Id> getChildId(Id parentId) {
            return parentMap.get(parentId);
    	}
    	// 処理対象チェックを行う
    	public Boolean isRelationRoom(Id roomId) {
            return (idSet.contains(roomId));
    	}

    	// 時間帯１０分単位の期間計算
    	private set<Integer> getAssignedTimeIdxSet(DateTime beginTime, DateTime endTime) {
    		// Minute Unit
    		Integer startIdx = ((beginTime.getTime() - beginBusinessTime.getTime()) / 1000 / 60 / 10).intValue();
    		Integer endIdx = ((endTime.getTime() - beginBusinessTime.getTime()) / 1000 / 60 / 10).intValue();
    		Set<Integer> assFlgSet = new Set<Integer>();
    		while ( startIdx <= endIdx) {
    			assFlgSet.add(startIdx);
    			startIdx++;
    		}
//System.debug('assFlgSet:::::' + assFlgSet);
    		return assFlgSet;
    	}
    	
    	//private Map<Id, List<Boolean>> pRoomTimeMap
    	// 連動の部屋情報にて、関連部屋の情報を自動コピーを行う
    	public void cloneLeadByRelRoom(Map<Id, OneRoomAssingInfo> pRoomMap) {
    		// 親部屋から、子部屋へコピーを行う
    		Map<Id, Set<Integer>> parentRoomFlgMap = new Map<Id, Set<Integer>>();
    		// 10単位で、時間アサインされるがどうか標識する
//System.debug('pRoomMap:[1]:::' + pRoomMap);
    		for (Id parentRoomId : parentMap.keySet()) {
    			// 親部屋
    			OneRoomAssingInfo selfRoom = pRoomMap.get(parentRoomId);
    			parentRoomFlgMap.put(parentRoomId, new Set<Integer>());
    			List<Lead__c> leadLst = selfRoom.getExistLeadLst();
    			// お部屋リストを取得する
    			List<Lead__c> cloneLeadLst = new List<Lead__c>();
    			for (Lead__c lead : leadLst) {
    				if (lead.Id == null) continue;
    				cloneLeadLst.add(lead.clone(false,true));
    			}
    			// 親の予約データから子部屋へコピーを行う
    			for (Id childId : parentMap.get(parentRoomId)) {
	    			// 親の格納している予約データリストを取得する
	    			OneRoomAssingInfo oneRoom = pRoomMap.get(childId);
					for (Lead__c lead : cloneLeadLst) {
						oneRoom.assingLeadInfo(lead);
					}
    			}
    		}
//System.debug('pRoomMap::[2]::' + pRoomMap);
    		// 子部屋から親部屋に予約データをコピーする
    		// 子部屋の時間段重複存在するため、Mergeする
    		for (Id childRoomId : childMap.keySet()) {
    			// 子の部屋情報
				OneRoomAssingInfo selfRoom = pRoomMap.get(childRoomId);
//System.debug('-----child----'+selfRoom);
				List<Lead__c> leadLst = selfRoom.getExistLeadLst();
    			// お部屋リストを取得する
    			List<Lead__c> cloneLeadLst = new List<Lead__c>();
    			for (Lead__c lead : leadLst) {
    				if (lead.Id == null) continue;
//System.debug('------------ time asset[1] ------------' + lead.EntryTime__c);
//System.debug('------------ time asset[1] ------------' + lead.Departure__c);
    				Set<Integer> timeAssSet = getAssignedTimeIdxSet(lead.EntryTime__c, lead.Departure__c);
//System.debug('------------ time asset[2] ------------' + timeAssSet);
    				parentRoomFlgMap.get(childMap.get(childRoomId)).addAll(timeAssSet);
    			}
    		}
    		
    		for (String key : parentRoomFlgMap.keySet()) {
    			Set<Integer> simChildSet = parentRoomFlgMap.get(key);
    			if (simChildSet.isEmpty()) continue;
    			List<Integer> simChildLst = new List<Integer>(simChildSet);
    			simChildLst.sort();
    			
				List<Lead__c> showOnlyLeadLst = new List<Lead__c>();
				Boolean switchFlg = true;
    			for (Integer i = 0 ; i < (simChildLst.size()) ; i++) {
    				Integer curIdx = simChildLst[i];
    				if (switchFlg) {
    					DateTime beginTime = beginBusinessTime.addMinutes(curIdx * 10);
    					Lead__c newLead = new Lead__c(EntryTime__c = beginTime, Field4__c = beginTime.format('HH:mm'));
    					showOnlyLeadLst.add(newLead);
    				} else if ( i == simChildLst.size() - 1) {
    					Lead__c newLead = showOnlyLeadLst[showOnlyLeadLst.size()-1];
    					newLead.Departure__c = beginBusinessTime.addMinutes(curIdx * 10);
    					newLead.Field3__c = newLead.Departure__c.format('HH:mm');
    					break;
    				}
    				Integer nextIdx = simChildLst[i+1];
    				if (nextIdx - curIdx == 1) {
    					switchFlg = false;
    					continue;
    				}
    				// Diffent Value > 1 Thne End Time
    				Lead__c newLead = showOnlyLeadLst[showOnlyLeadLst.size()-1];
    				newLead.Departure__c = beginBusinessTime.addMinutes(curIdx * 10);
    				newLead.Field3__c = newLead.Departure__c.format('HH:mm');
    				switchFlg = true;
    			}
//System.debug('showOnlyLeadLst::::' + showOnlyLeadLst);
    			OneRoomAssingInfo oneRoom = pRoomMap.get(key);
				for (Lead__c lead : showOnlyLeadLst) {
					oneRoom.assingLeadInfo(lead);
				}
    		}
    	}
    }

	// orgDateTime: DateTime: hmTime→HH:mm
	public static DateTime getGobalCalTimeDate(DateTime orgDateTime, String hmTime) {
	    Integer hh = (hmTime.length() == 4 ? Integer.valueOf(hmTime.substring(0,1)) : Integer.valueOf(hmTime.substring(0,2)));
	    Integer mm = (hmTime.length() == 4 ? Integer.valueOf(hmTime.substring(2,4)) : Integer.valueOf(hmTime.substring(3,5)));
	    if (hh >= 24) { hh = hh - 24; orgDateTime = orgDateTime.addDays(1);}
	    return DateTime.newInstance(orgDateTime.date(), Time.newInstance(hh, mm, 0, 0));
	}
	
	// １部屋24時間アサイン情報
	public class OneRoomAssingInfo {
		// 部屋名
		//public String roomName{get;set;}

		//List<TimeAssignInfo> timeAssingList {get; private set;}
		// 2012/09/12 Status Color Class Add
		// 確認中
		private final String STATUS_CHECKING_STYLE_CLS = 'comfirmStatus';
		// 確認
		private final String STATUS_CHECKED_STYLE_CLS = 'comfirmedStatus';
		// 仮予約
		private final String STATUS_CHECKING_TENTAIVE_CLS = 'tmpBookinged';
		// 会場おさえ
		private final String STATUS_PARTYROOM_BOOKING_CLS = 'partyroomBook';
        // 予約開始時間と終了時間
        private Map<DateTime, DateTime> assingedTimeMap;
        private Map<DateTime, Lead__c> assingedLeadMap;
        private Map<Id, Id> assingedAccMap;

        // 営業開始時間と終了時間
        private DateTime beginBusinessTime;
        private DateTime endBusinessTime;
        //private Room__c roomInfo;
        private Integer rowIndex;
		// 2013/03/31 ADD COLOR MAP
		private Map<String, String> colorMap;
		
		public OneRoomAssingInfo(DateTime pBeginBusinessTime, DateTime pEndBusinessTime, Integer pRowIndex, Map<String, String> pColorMap) {
			beginBusinessTime = pBeginBusinessTime;
			endBusinessTime = pEndBusinessTime;
			assingedTimeMap = new Map<DateTime, DateTime>();
			assingedLeadMap = new Map<DateTime, Lead__c>();
			assingedAccMap = new Map<Id, Id>();
			//roomInfo = pRoomInfo;
			rowIndex = pRowIndex;
			// 2013/03/31 ADD
			colorMap = pColorMap;
		}
		// 初期化を行う
		public void assingLeadInfo(Lead__c pLead) {
			if (pLead.EntryTime__c != null && pLead.Departure__c != null) {
				// 2014/03/14 BEGIN EDIT
				/*
				DateTime beginTimeKey = pLead.EntryTime__c < beginBusinessTime ? beginBusinessTime : pLead.EntryTime__c;

				beginTimeKey = getCalTimeDate(beginTimeKey, pLead.Field4__c);
				DateTime endTimeKey = pLead.Departure__c > endBusinessTime ? endBusinessTime : pLead.Departure__c;
                endTimeKey = getCalTimeDate(endTimeKey, pLead.Field3__c);
                */
				DateTime beginTimeKey = getCalTimeDate(pLead.EntryTime__c, pLead.Field4__c);
				beginTimeKey = beginTimeKey < beginBusinessTime ? beginBusinessTime : beginTimeKey;
                DateTime endTimeKey = getCalTimeDate(pLead.Departure__c, pLead.Field3__c);
                endTimeKey = endTimeKey > endBusinessTime ? endBusinessTime : endTimeKey;
                // 2014/03/14 END EDIT
                // 2013/02/14 ADD BEGIN
                pLead.EntryTime__c = beginTimeKey;
                pLead.Departure__c = endTimeKey;
                // 2013/02/14 ADD END
System.debug(LoggingLevel.INFO, 'beginTimeKey:::' + beginTimeKey);
System.debug(LoggingLevel.INFO, 'endTimeKey:::' + endTimeKey);
if (pLead.EntryTime__c.date() >  pLead.Departure__c.date() && beginTimeKey >= endTimeKey  ) {
	//時刻設定不正:
	throw new CommException(Label.CONST_005_0078 + 'beginTimeKey['+beginTimeKey.format('yyyy/MM/dd HH:mm')+']:::endTimeKey['+endTimeKey.format('yyyy/MM/dd HH:mm')+']:::pLead['+pLead+']');
}
				assingedTimeMap.put(
				    beginTimeKey,
                    endTimeKey);
                assingedLeadMap.put(
                	beginTimeKey,
                	pLead);
			}
		}
		// 20121003: ADD 会計情報を設定する
		public void assingAccountInfo(Map<Id, Id> pAccMap) {
			assingedAccMap = pAccMap;
		}
		public List<Lead__c> getExistLeadLst() {
			return assingedLeadMap.values();
		}
		// orgDateTime: DateTime: hmTime→HH:mm
		private DateTime getCalTimeDate(DateTime orgDateTime, String hmTime) {
			/*
            Integer hh = (hmTime.length() == 4 ? Integer.valueOf(hmTime.substring(0,1)) : Integer.valueOf(hmTime.substring(0,2)));
            Integer mm = (hmTime.length() == 4 ? Integer.valueOf(hmTime.substring(2,4)) : Integer.valueOf(hmTime.substring(3,5)));
            if (hh >= 24) { hh = hh - 24; orgDateTime = orgDateTime.addDays(1);}
            return DateTime.newInstance(orgDateTime.date(), Time.newInstance(hh, mm, 0, 0));
            */
            return BookingTimeTable.getGobalCalTimeDate(orgDateTime, hmTime);
		}
		public String tdHtml{get{
			// 時間SORTする
            String tdStr = '';
            for (Datetime dt = beginBusinessTime; dt < endBusinessTime;) {
            	// 既に予約済み場合
            	String hhmm = dt.format('HH:mm') ;
            	String color = '';
            	if (colorMap.containsKey(hhmm)) color = colorMap.get(hhmm);
            	// 共通情報
            	tdStr +='<td rowIndex="' + rowIndex + '" colTime = "' + dt.format('yyyy-MM-dd HH:mm') ;
            	tdStr +='" style="border-right:dotted 1px #CCC; width: 9px; height: 30px;border-top:solid 1px #777;';
            	if (dt.minute() == 0) tdStr += ' border-left:solid 2px ' + (String.isEmpty(color) ? '#BBB' : color) + ';"';
            	else tdStr += (String.isEmpty(color) ? '' : ' border-left:solid 2px ' + color + ';') + '"';

            	if (assingedTimeMap.containsKey(dt)) {
            		DateTime endTime = assingedTimeMap.get(dt);
            		Long intst = dt.getTime();
            		Long inted = endTime.getTime();
            		// 10分単位数
            		Long diffMinutes = (inted - intst) / 1000 / 60 / 10;
            		// 予約情報を維持する
            		Lead__c plead = assingedLeadMap.get(dt);
            		// Div Class add
            		String styleCls = '';
            		// 2013/02/14 ADD Lead Id Is Null -> 会場おさえ
//System.debug('plead::::' + plead);
            		if (plead.Id == null) {
            			// 会場おさえ
            			styleCls = STATUS_PARTYROOM_BOOKING_CLS;
            		} else if (plead.ReservedStatus__c == CommConst.LEAD_ST_CANDEL_WAIT) {
            			// [キャンセルまち]
            			styleCls = STATUS_CHECKING_STYLE_CLS;
            		} else if (plead.ReservedStatus__c == CommConst.LEAD_ST_CHECKED) {
            			// 確認
            			styleCls = STATUS_CHECKED_STYLE_CLS;
            		} else if (plead.ReservedStatus__c == CommConst.LEAD_ST_TENTAIVE) {
            			// 仮予約
            			styleCls = STATUS_CHECKING_TENTAIVE_CLS;
            		} else if (plead.ReservedStatus__c == CommConst.LEAD_ST_ENKAIBOOK) {
            			// 会場おさえ
            			styleCls = STATUS_PARTYROOM_BOOKING_CLS;
            		}
            		tdStr += ' class="ui-selected ' + styleCls + '" colspan="' + diffMinutes + '" ';
                    // 会計データが存在する場合
                    String accDivHtml = '';
                    if (plead.Id != null && assingedAccMap.containskey(plead.Relcontact__c)) {
                    	//会計
                    	accDivHtml += '<div style="float:right"><a href="javascript:void(0);" onclick="window.open(\'/'+ assingedAccMap.get(plead.Relcontact__c) + '\')" ><img src="/img/icon/bank32.png" class="imgstyle" title='+Label.CONST_005_0079+' /></a></div> ';
                    }
					String containDiv = '<div class="timeAssignedTd"  style="width: 100%">';
					String linkUrl = '';
					if (plead.Id != null) linkUrl = '<a target="_blank" onclick="window.open(\'/' + plead.id + '\')" href="javascript:void(0);" id="' +plead.id+ '" onblur="LookupHoverDetail.getHover(\'' +plead.id+  '\').hide();" onfocus="LookupHoverDetail.getHover(\'' + plead.id + '\', \'/' + plead.id +  '/m?retURL=%2F'+ plead.id + '&isAjaxRequest=1\').show();" onmouseout="LookupHoverDetail.getHover(\''+ plead.id + '\').hide();" onmouseover="LookupHoverDetail.getHover(\''+ plead.id + '\', \'/'+ plead.id + '/m?retURL=%2F'+ plead.id + '&isAjaxRequest=1\').show();">' + plead.name + '</a>';
					tdStr +='> ' + containDiv +linkUrl+ accDivHtml + ' </div></td>';
            		// 次の処理を行う
            		dt = endTime;
            	}
            	// 空白場合
            	else {
            		// 時間は0分場合
            		//if (dt.minute() == 0) tdStr += ' class="oneHourPanel" ';
            		//else tdStr += ' class="oneHourPanel" ';
            		tdStr += ' class="oneHourPanel" ';
	                // 10分単位、TD作成する、既に予約済み場合、TDはcolspanに変更する
	                dt = dt.addMinutes(10);

	                tdStr +='> &nbsp; </td>';
            	}
            	//colIndex++;
            	//tdStr +='> &nbsp; </td>';
            }
            return tdStr;
		}}
	}

    // 支店選択リスト[支店機能追加]
    public List<SelectOption> branchShopLst{get; private set;}
    public String branchShopNm{get; set;}
    private void setInitBranShopLst() {
    	branchShopLst = new List<SelectOption>();
        for (ShopInformation__c shop : [select id, name,ShopCode__c from ShopInformation__c order by Seq__c limit 5000]) {
        	branchShopLst.add(new SelectOption(shop.ShopCode__c, shop.name));
        }
        if (!branchShopLst.isEmpty()) {
        	// 顧客に設定する支店で初期値に設定する[2013/06/30]
        	String locShopCode = UserUtil.CurrentUser.ShopCode__c;
        	for (SelectOption s : branchShopLst) {
        		if (s.getValue() == locShopCode) branchShopNm = locShopCode;
        	}
        }
    }

}