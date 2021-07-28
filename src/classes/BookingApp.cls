/**********************
* 予約システム
* １画面に予約データ登録、修正を行う
* 2015/11/02 故障部屋アサイン対象外ロジック追加
* 2016/04/06 ご予約情報はキャンセルから復活すると、予約インデックスSUBは修正不可から修正可能変更対応
* 2016/08/18 ネット取り込みから予約情報に対して、小部屋の特記事項をなしに対応する
***********************/
public with sharing class BookingApp {

	// 宿泊者明細設定画面
    private ApexPages.StandardController ctrl;
    // 画面ステータス
    public Boolean isEditPage{get;set;}
	// 予約番号のFilterWhere
	public String autoComLeadNoFilter{get{return ' StatusLst__c != \'' + CommUtils.escStr(CommConst.LEAD_ST_CANCEL) + '\' And  ParentLeadIndxRef__c = null ';}}
	// 宿泊レコードタイプID
	private Id bookRecTypeId;
	// 到着時刻の初期値
	public String JS_DEFCHKIN_DT{get; private set;}
	// 出発時刻の初期値
	public String JS_DEFCHKOT_DT{get; private set;}
	// 画面制御フラグ「過去日付フラグ」
	public Boolean isOldDayFlg{get; private set;}
	// 画面制御フラグ「チェックイン操作可フラグ」
	public Boolean isCanCheckinFlg{get; private set;}
	// 画面制御フラグ「チェックインデータ存在状態」
	public Boolean isExistCheckIn{get; private set;}
    // E/B機能存在するかどうか標識用
    public Boolean isHaveEbInfo{get; private set;}
    // 2016/04/06 ご予約情報はキャンセルから復活する BEGIN
    private static String DEF_STATUS_VALUE{get;private set;}
	// 2016/04/06 ご予約情報はキャンセルから復活する END
	// 2013/08/16 予約名
	private static final String LEAD_NAME_PREFIX = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomDelegatePrefix__c);
	// 2013/08/26 画面入力項目制御コード
	public String pageSwitchCode{get{
		return CommUtils.isBlank(CommDefine__c.getOrgDefaults().BookingAppSwitchCode__c) ? '1' : CommDefine__c.getOrgDefaults().BookingAppSwitchCode__c;
	}}
    // 2014/01/15 特記事項表示・非表示制御対応
    public Boolean commentIsShow{get{
    	return CommDefine__c.getOrgDefaults().BookingAppIsShowComment__c == null ? false : CommDefine__c.getOrgDefaults().BookingAppIsShowComment__c;
    }}
    // 2014/09/30 金額小数点対応
    public String getNumberFormat() {
    	return CommUtils.getNumberFormat();
    }
    private static Set<String> leadIdxFieldsSet;
    // 2017/01/18 行追加　by zy BEGIN
    public Integer defInputLines{get{
    	return CommUtils.nullToIntZero(CommConst.APPOTION_DETAIL_DEF_INPUTLINES) == 0 
    													? 5 
    									: CommUtils.nullToIntZero(CommConst.APPOTION_DETAIL_DEF_INPUTLINES);
    }}
    // 2017/01/18 行追加　by zy END
    // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
    public Integer gStaysNums{get;private set;}
    // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
    static {
    	//Schema.DescribeSObjectResult idx = Schema.SObjectType.LeadIndex__c; 
    	Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.LeadIndex__c.fields.getMap();
		leadIdxFieldsSet = new Set<String>();
		for(Schema.SObjectField sfield : fieldMap.Values()) {
			schema.describefieldresult dfield = sfield.getDescribe();
			if (dfield.isCreateable()) leadIdxFieldsSet.add(dfield.getName());
		}
		// 2016/04/06 ご予約情報はキャンセルから復活する BEGIN
    	DEF_STATUS_VALUE = '';
		Schema.DescribeFieldResult f = Schema.SObjectType.LeadIndex__c.fields.StatusLst__c;
		List<Schema.PicklistEntry> plist = f.getPicklistValues();
		for (Schema.PicklistEntry p : plist) {
		  if (p.isActive() && p.isDefaultValue()) { 
		  	DEF_STATUS_VALUE = p.getValue(); 
		  }
		}
		// 2016/04/06 ご予約情報はキャンセルから復活する END
    }
	// 2016/10/17 一画面機能対応（遷移）
	public PageReference initSwitchPage() {
		// 一画面有効の場合
		// 2019/11/15 一括予約画面の部屋直接選択 by zy BEGIN
		if (pageSwitchCode == '3' || pageSwitchCode == '4') {
		// 2019/11/15 一括予約画面の部屋直接選択 by zy END
			Map<String,String> paramMap = ApexPages.currentPage().getParameters();
			PageReference customPage = new PageReference('/apex/BookingFlexApp');
			customPage.getParameters().putAll(paramMap);
			customPage.setRedirect(true);
			return customPage;
		}
		return null;
	}

	// クラスインスタンス化
    public BookingApp(ApexPages.StandardController controller) {
    	// Ctrl Set
        ctrl = controller;
		// 宿泊レコードタイプIDを取得する
		bookRecTypeId = CommLogicProcess.getLeadBookingRecType();
		// 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
		// 時刻初期値取得、設定する
		//JS_DEFCHKIN_DT = CommConst.DEF_CHECKIN_TIME;
		//JS_DEFCHKOT_DT = CommConst.DEF_CHECKOT_TIME;
		String branchShopNm = UserUtil.CurrentUser.ShopCode__c;
		ShopInfoUtil.ShopLeadInfo shopInfo = ShopInfoUtil.getShopDefInfo(branchShopNm);
		JS_DEFCHKIN_DT = shopInfo.defCheckInTimeStr;
		JS_DEFCHKOT_DT = shopInfo.defCheckOtTimeStr;
		gStaysNums = shopInfo.defStayNums;
		// 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
	    // アプリのE/B機能起動がどうかフラグを設定する
	    isHaveEbInfo = CommConst.APPOPTION_ISUSR_EB;
		// 初期化設定を行う
		initFormValue();
        // 部屋タイプ
        setRoomTypeLst();
        // 支払方法リスト初期化する
        paymentTypeLst = new List<Selectoption>();
        Schema.DescribeFieldResult fieldResult = Lead__c.Field315__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple) {
            paymentTypeLst.add(new SelectOption(f.getValue(),f.getLabel()));
        }
        if (ctrl.getId() == null) {
			// 予約明細データを取得する
	        setLeadSubLst(null);
        } else {
        	// 予約親と予約明細両方共対応する
        	List<LeadIndex__c> leadIndexLst = [select id, name, ParentLeadIndxRef__c, ParentLeadIndxRef__r.Name from LeadIndex__c where id = :ctrl.getId()];
        	//予約インデックス情報を見つかりません。
        	if (leadIndexLst.isEmpty()) throw new CommException(Label.MSG_001_0066);
        	if (leadIndexLst[0].ParentLeadIndxRef__c != null) leadBaseInf.leadNo = leadIndexLst[0].ParentLeadIndxRef__r.Name;
        	else leadBaseInf.leadNo = leadIndexLst[0].Name;
        	this.refreshExistLeadInfo();
        }
    }

    /**
    *　画面設定情報のクリア設定
    **/
	private void initFormValue() {
		Contact c = new Contact();
		String contactId = Apexpages.currentpage().getparameters().get('contactid');
		
		if(contactId!= null && contactId!=''){
        	List<Contact> contList = [select id, name, Account.Name,AccountId, LastName , FirstName, Name1__c,KanaName1__c, Katakana__c, Phone, ApplicantName__c,ApplicantPhone__c, Memo1__c,Memo2__c, Memo3__c from Contact where id =: contactId];
        	if(contList!= null && contList.size() >0){
        		c = contList.get(0);
        	}
        }
        
        // 予約初期化
        leadBaseInf = new LeadBaseInfo(new LeadIndex__c(LeadName__c = (c.Name!=null) ?c.Name : ''),
        	new Lead__c(RecordTypeId = bookRecTypeId),
        	c);
        // 明細情報の初期化する
        setLeadSubLst(null);
        // 宿泊者名簿
        oGuestLst = new List<ContactItem>();
        // プラン初期情報設定
        oPlanInfo = new PlanInfoItem();
        // 新規ステータス
        isEditPage = false;
        // 過去日付フラグ
        isOldDayFlg = false;
        // チェックインフラグ
        isCanCheckinFlg = false;
        isExistCheckIn = false;
	}

    /*
	* 画面設定情報にて、既存の予約情報と明細情報を取得、画面に表示する　
	*/
	public void refreshExistLeadInfo() {
		// 予約番号にて、予約情報を取得する　
		// 予約番号はNULLの場合、画面初期化を行う
		if (CommUtils.isBlank(leadBaseInf.leadNo)) {
			// 画面クリア処理を行う
			initFormValue();
			return;
		}
		// 予約番号は設定する場合、既存予約情報を取得する
        String whereStr = ' where  StatusLst__c != \'' + CommUtils.escStr(CommConst.LEAD_ST_CANCEL) + '\' And name = \'' + CommUtils.escStr(leadBaseInf.leadNo) + '\' limit 1';
//System.debug('SQL:::' + queryLeadIndexStr + whereStr);
        List<LeadIndex__c> ldIndexLst = Database.query(queryLeadIndexStr + whereStr);
        if (ldIndexLst.isEmpty()) {
            // 予約データが未存在する場合、画面クリアして、処理中止
            initFormValue();
            return;
        }
        // データが存在する場合[基本情報を設定する]
        leadBaseInf = new LeadBaseInfo(ldIndexLst[0],
	        	new Lead__c(
	        	  RecordTypeId = bookRecTypeId,
	        	  Field2__c = ldIndexLst[0].Channel__c,
	        	  Segment__c = ldIndexLst[0].Segment__c),
	        	ldIndexLst[0].contactRef__r );
		// 過去日付判断チェックを行う
		if (ldIndexLst[0].EntryDate__c < Date.today()) isOldDayFlg = true;
		
        // 予約明細データを設定する[予約SUBINDEX管理データ]
        //oLeadLst = new List<LeadItem>();
        //List<LeadIndex__c> idxSubLst = [select name, SalesPrice__c, PlanRef__c, Nights__c, DepartureDate__c, EntryDate__c, RoomTypeRef__c, Rooms__c, ParentLeadIndxRef__c,StayPersons__c,ExtraBedChk__c from LeadIndex__c 
        //	where ParentLeadIndxRef__c = :leadBaseInf.s.Id order by name];
        // 取得する
        setLeadSubLst(leadBaseInf.s.Id);

		// 編集画面
        isEditPage = true;
        
        // チェックインボタン表示制御
        if (ldIndexLst[0].EntryDate__c <= Date.today() &&
        	ldIndexLst[0].DepartureDate__c >= Date.today() ) {
    		isCanCheckinFlg = isHaveNoCheckinData(ldIndexLst[0].Id);
    	} else {
    		isCanCheckinFlg = false;
    	}
    	// チェックイン存在チェック
    	// TODO:SUBINDEXに、既にチェックインデータあり場合、Readonlyに変更する
    	//isExistCheckIn = isHaveCheckinData(ldIndexLst[0].Id);
	}
	
	/**
	* 当日に、未チェックインデータが存在する場合、チェックインボタンを表示する
	**/
	private Boolean isHaveNoCheckinData(Id leadIdxId) {
		Date todayDt = Date.today();
		Integer noCheckInLen = [select count() from Lead__c
        	where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 
                And DAY_ONLY(convertTimezone(EntryTime__c)) = :todayDt
                And Field298__c = null And LeadIndexRef__c = :leadIdxId limit 1];
         return (noCheckInLen > 0);
	}
	/**
	* 該当予約データに対して、既にチェックインデータ存在チェックを行う
	**//*
	private Boolean isHaveCheckinData(Id leadIndxId) {
		Integer checkInLen = [select count() from Lead__c 
			where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 
			And Field298__c = :CommConst.LEAD_GUEST_ST_CI 
			And LeadIndexRef__c = :leadIndxId limit 1];
		return (checkInLen > 0);
	}*/

	/**
	* 顧客情報最新取得を行う
	**/
	public void refreshContcatInfo() {
		if (CommUtils.isBlank(leadBaseInf.s.contactRef__c)) {
			leadBaseInf.setContact(new Contact());
			return;
		}
		// 予約番号は設定する場合、既存予約情報を取得する
		else {
			String whereStr = ' where id = \'' + CommUtils.escStr(leadBaseInf.s.contactRef__c) + '\' ';
			whereStr += ' And Name = \'' + CommUtils.escStr(leadBaseInf.contactName) + '\' limit 1';

//System.debug('SQL:::' + queryContStr + whereStr);
			List<Contact> contactLst = Database.query(queryContStr + whereStr);
			if (contactLst.isEmpty()) {
				leadBaseInf.setContact(new Contact());
				return;
			} else {
				// 既存の顧客情報を画面へ設定する
				leadBaseInf.setContact(contactLst[0]);
				// 該当顧客の予約データが存在する場合「当日」、予約データも取得する
			}
		}
	}
	/**
	* 顧客情報最新取得を行う
	**/
	// SOQL顧客情報項目定義
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
	// お客様情報格納クラス
	public class ContactInfo {
		public ContactInfo(Contact c){
			KanjiName = CommUtils.nullToBlank(c.Name1__c);
			KanaName = CommUtils.nullToBlank(c.KanaName1__c);
			KatakanaName = CommUtils.nullToBlank(c.Katakana__c);
			phone = CommUtils.nullToBlank(c.Phone);
			accountName = c.Account != null ? c.Account.Name : '';
			ApplicantName = CommUtils.nullToBlank(c.ApplicantName__c);
			ApplicantPhone = CommUtils.nullToBlank(c.ApplicantPhone__c);
			Memo1 = CommUtils.nullToBlank(c.Memo1__c);
			Memo2 = CommUtils.nullToBlank(c.Memo2__c);
			Memo3 = CommUtils.nullToBlank(c.Memo3__c);
		}
		public String KanjiName{get;set;}	// 名称１
		public String KanaName{get;set;}	// カタカナ
		public String KatakanaName{get;set;} //ひらがな、
		public String phone{get;set;}		// Phone
		public String accountName{get;set;}	// 取引先名(団体名)
		public String ApplicantName{get;set;}	// 申込者
		public String ApplicantPhone{get;set;}	// 申込者電話
		public String Memo1{get;set;}			// 客室情報
		public String Memo2{get;set;}			// 付帯情報
		public String Memo3{get;set;}			// 支払情報
	}
	
	// SOQL予約取得項目定義
	private final String queryLeadIndexStr = 'Select EventSource__c,Comment__c, Payment__c, Channel__c, Segment__c, ContactNameCal__c,contactRef__r.Katakana__c, contactRef__r.Id, contactRef__r.Memo6__c, contactRef__r.Memo5__c, contactRef__r.Memo4__c, contactRef__r.Memo3__c, contactRef__r.Memo2__c, contactRef__r.Memo1__c, contactRef__r.KanaName2__c, contactRef__r.KanaName1__c, contactRef__r.Name2__c, contactRef__r.Name1__c, contactRef__r.Phone, contactRef__r.Name, contactRef__r.Account.Name, contactRef__r.AccountId, contactRef__r.ApplicantName__c,contactRef__r.ApplicantPhone__c, contactRef__c, Rooms__c, Nights__c, Name, LeadNo__c, EntryTime__c, EntryDate__c, DepartureTime__c, DepartureDate__c,LeadName__c From LeadIndex__c ';
	// SOQL顧客情報項目定義
	private static final String queryContStr = 'Select Id, Phone, Name1__c, Name, Memo6__c, Memo5__c, Memo4__c, Memo3__c, Memo2__c, Memo1__c, Katakana__c, KanaName2__c, KanaName1__c,Account.Name,ApplicantName__c,ApplicantPhone__c From Contact ';

	// **************************
	// 部屋タイプ一覧を取得する
	// 部屋の最大格納人数取得、JS化する
	// **************************
	public List<Selectoption> roomTypeLst{get; private set;}
	public String roomTypeScript{get; private set;}
	private void setRoomTypeLst() {
		roomTypeLst = new List<Selectoption>();
		roomTypeScript = '';
		// 2013/07/30 支店機能対応
        //for (TypeOfRooms__c roomType: [select id, Name, MaxNumber__c from TypeOfRooms__c where ActionType__c = :CommConst.ROOMTYPE_NORMAL order by Seq__c limit 200]) {
		List<TypeOfRooms__c> roomTypeLstRs = (new CommLogicProcess()).getTypeOfRooms(UserUtil.CurrentUser.ShopCode__c);
		for (TypeOfRooms__c roomType: roomTypeLstRs) {
            roomTypeLst.add(new Selectoption(roomType.Id, roomType.name));
            roomTypeScript += '"' + roomType.Id + '" : ' + CommUtils.nullToZero(roomType.MaxNumber__c) + ',';
        }
        roomTypeScript = '{' + roomTypeScript.substringBeforeLast(',') + '}';
	}

    /**
    * 顧客情報の自動登録
    **/
    private void upsertContact() {
    	// 顧客情報の新規作成
    	//if (leadBaseInf.c.Id == null) leadBaseInf.c.LastName = leadBaseInf.contactName;
    	if (leadBaseInf.c.Id == null) {
    		String[] names = CommUtils.splitName(leadBaseInf.contactName);
    		leadBaseInf.c.LastName = names[0];
    		leadBaseInf.c.FirstName = names[1];
    	}
    	// 2018/03/07 Security Check BEGIN
    	List<String> chkFieldsLst = new List<String>{'accoutname'};
    	Map<String,Schema.SObjectField> mm = Schema.SObjectType.Account.fields.getMap();
    	if (!CommSecurityUtils.isCanCreateable(chkFieldsLst, mm)) {
    		return ;
    	}
    	// 2018/03/07 Security Check END
    	// 団体名の新規/更新処理を行う
		if (!CommUtils.isBlank(leadBaseInf.accoutName)) {
			// 団体名を変わるどうかチェックする
			if (leadBaseInf.c.Account.Name != leadBaseInf.accoutName) {
				// 既存する顧客情報を探す
			    List<Account> existAcc = [select id from Account where name = :leadBaseInf.accoutName limit 1];
			    if (existAcc.isEmpty()) {
			    	Account nwAcc = new Account(Name = leadBaseInf.accoutName);
			    	insert nwAcc;
			    	leadBaseInf.c.AccountId = nwAcc.Id;
			    } else {
			    	leadBaseInf.c.AccountId = existAcc[0].Id;
			    }
			}
		} else {
			// 空白になる場合
			// 2014/12/17 BugFix No.540 Begin 空白の団体名の場合、元の取引先に触らないで処理を行う
			//leadBaseInf.c.AccountId = null;
			// 2014/12/17 BugFix No.540 End
		}

//System.debug('leadBaseInf.c::::' + leadBaseInf.c);
    	//upsert leadBaseInf.c;
    	leadBaseInf.c = (new CommLogicProcess()).upsertDuplicateErrorProcess(leadBaseInf.c);
    	leadBaseInf.setContact(leadBaseInf.c);
    }

	/**
	* 予約データ作成前の事前チェック
	**/
	private boolean preCreateInfo() {
		// 必須チェック
		if (leadBaseInf.s.EntryDate__c == null ||
			leadBaseInf.s.DepartureDate__c == null ||
			// 既存顧客様非存在 && 新規顧客様の名がない場合
			(CommUtils.isBlank(leadBaseInf.s.contactRef__c) && CommUtils.isBlank(leadBaseInf.contactName) )||
			CommUtils.isBlank(leadBaseInf.s.LeadName__c) ||
			CommUtils.isBlank(leadBaseInf.l.Field2__c) ||
			(
			CommUtils.isBlank(leadBaseInf.l.Segment__c) &&
			pageSwitchCode != '2'
			)) {
			//必須項目を入力してください。
			Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_001_0063));
			return false;
		}
		if (!CommUtils.isBlank(leadBaseInf.s.contactRef__c)) leadBaseInf.c.Id = leadBaseInf.s.contactRef__c;
		// 日帰りの場合、到着時刻と出発時刻順番チェックを行う
		for (LeadItem item : oLeadLst) {
			// 無効な予約明細情報の場合、処理スキップ
			if (!item.isValidate()) continue;
			// Data Format[全角：→半角：に変更処理]
			item.s.EntryTime__c = Commutils.nullToBlank(item.s.EntryTime__c).replace('：',':');
			item.s.DepartureTime__c = Commutils.nullToBlank(item.s.DepartureTime__c).replace('：',':');
        	if (item.isChgData()) {
        		if (Commutils.isBlank(item.s.EntryTime__c)) item.s.EntryTime__c = JS_DEFCHKIN_DT;
        		if (Commutils.isBlank(item.s.DepartureTime__c)) item.s.DepartureTime__c = JS_DEFCHKOT_DT;
	            // 日帰りの場合、時刻チェックを行う
	            if (item.s.EntryDate__c == item.s.DepartureDate__c &&
	            	CommUtils.nullToZero(item.s.EntryTime__c.replace(':','')) >= 
	            	CommUtils.nullToZero(item.s.DepartureTime__c.replace(':','')) ) {	            
	            	//明細情報XXXXXX行目の出発時刻には到着時刻以降の時刻を指定して下さい
	            	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_001_0064.replace('XXXXXX',String.valueOf(item.rowNo))));
	            }
        	}
		}
		return (!Apexpages.hasMessages(ApexPages.Severity.ERROR));
	}

	/**
	* 予約データの作成
	* 「予約登録」ボタンをクリックして、予約基本（予約インデックス）、予約明細（予約インデックスSUB）、予約、顧客様、取引先データを登録する
	**/
	public void createLeadInfo() {
		// 事前処理を行う
		if (!preCreateInfo()) return;
		
		Savepoint sp = Database.setSavepoint();
		try {
        // 顧客情報を新規・更新を行う
        upsertContact();
		// 新規登録と更新を行う「判断条件は？」
		// 2018/03/07 Security Check BEGIN
		List<String> chkFieldsLst = new List<String>{'statuslst__c','contactref__c','segment__c','payment__c','parentleadindxref__c',//'id'
														'leadname__c','channel__c','comment__c','salesprice__c','salesprice__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.LeadIndex__c.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(chkFieldsLst, mm)) {
			return ;
		}
		List<String> chkFieldUPsLst = new List<String>{'statuslst__c','leadname__c','salesprice__c'};
		Map<String,Schema.SObjectField> m = Schema.SObjectType.LeadIndex__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(chkFieldUPsLst, m)) {
			return ;
		}
		// 2018/03/07 Security Check END
		// SubIndex新規
		List<LeadIndex__c> indexSubLst = new List<LeadIndex__c>();
		// SubIndex削除
		List<LeadIndex__c> delSubLst = new List<LeadIndex__c>();
		
		// GuestRoom情報の入り替え<Old SubIndex Id/New SubIndex Id>
		Map<Id, Integer> subIdRepMap = new Map<Id, Integer>();
		Map<Integer, LeadIndex__c> newSubIdRepMap = new Map<Integer, LeadIndex__c>();
		// 2014/04/16 INSERTエラーのRollback後、ID既存問題の回避
		if (!CommUtils.isBlank(leadBaseInf.s.Id)) {
			List<LeadIndex__c> existRs = [select id, name from LeadIndex__c where id = :leadBaseInf.s.Id];
			if (existRs.isEmpty()) leadBaseInf.s.Id = null;
		}
		// 予約基本新規登録する場合
		if (leadBaseInf.s.Id == null) {
			// 新規登録を行う[予約チャネル/セグメント]設定を行う
			leadBaseInf.s.Channel__c = leadBaseInf.l.Field2__c;
			leadBaseInf.s.Segment__c = leadBaseInf.l.Segment__c;
			// 基本情報を新規登録する
			insert leadBaseInf.s;
			
			// 予約明細（予約インデックスSUB）新規情報を設定する
			for (LeadItem item : oLeadLst) {
				// 無効な予約明細情報の場合、処理スキップ
				if (!item.isValidate()) continue;
				// 予約明細情報設定
				LeadIndex__c subIndex = item.s;
				subIndex.contactRef__c = leadBaseInf.s.contactRef__c;
                subIndex.Channel__c = leadBaseInf.s.Channel__c;
                subIndex.Segment__c = leadBaseInf.s.Segment__c;
				subIndex.ParentLeadIndxRef__c = leadBaseInf.s.Id;
				// 2013/11/26 到着時刻と出発時刻は明細単位で設定する
				//subIndex.EntryTime__c = leadBaseInf.s.EntryTime__c;
				//subIndex.DepartureTime__c = leadBaseInf.s.DepartureTime__c;
				subIndex.LeadName__c = leadBaseInf.s.LeadName__c;
				subIndex.Comment__c = leadBaseInf.s.Comment__c;
				subIndex.Payment__c = leadBaseInf.s.Payment__c;
				indexSubLst.add(subIndex);
			}

			// 新規登録した予約データのNameを取得する
			LeadIndex__c index = [select id, name from LeadIndex__c where id = :leadBaseInf.s.Id];
			leadBaseInf.leadNo = index.Name;
		} 
		// 予約番号にて、予約データが既に登録場合、
		else {
			// 予約基本情報を更新を行う[予約チャネル/セグメント]設定を行う
			// 注：予約チャネル/セグメントは変更されるでも、予約データへ連動更新を行わない
            leadBaseInf.s.Channel__c = leadBaseInf.l.Field2__c;
            leadBaseInf.s.Segment__c = leadBaseInf.l.Segment__c;
            // 予約情報を更新を行う
			update leadBaseInf.s;
			// 予約名変更される場合、関連予約名は全部自動変更を行う
			if (leadBaseInf.c.Id != leadbaseInf.orgContactId ||
				leadBaseInf.s.LeadName__c!= leadBaseInf.orgLeadName ||
				leadBaseInf.s.Payment__c != leadBaseInf.orgPaymentType ||
				leadBaseInf.s.Channel__c != leadBaseInf.orgChannel ||
				leadBaseInf.s.Segment__c != leadBaseInf.orgSegment //||
				//CommUtils.nullToBlank(leadBaseInf.s.Comment__c) != CommUtils.nullToBlank(leadBaseInf.orgComment) 
				) {
				List<Lead__c> existLeads = [select id , name from Lead__c where LeadIndexRef__c = :leadBaseInf.s.Id And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG];
				for (Lead__c lead : existLeads) {
					if (leadBaseInf.c.Id != leadbaseInf.orgContactId)
					lead.Relcontact__c = leadBaseInf.c.Id;
					if (leadBaseInf.s.LeadName__c != leadBaseInf.orgLeadName)
					lead.name = lead.Name.replace(leadBaseInf.orgLeadName, leadBaseInf.s.LeadName__c);
					if (leadBaseInf.s.Payment__c  != leadBaseInf.orgPaymentType)
					lead.Field315__c = leadBaseInf.s.Payment__c;
					if (leadBaseInf.s.Channel__c  != leadBaseInf.orgChannel)
					lead.Field2__c = leadBaseInf.s.Channel__c;
					if (leadBaseInf.s.Segment__c != leadBaseInf.orgSegment)
					lead.Segment__c = leadBaseInf.s.Segment__c;
					// 2014/01/08 一時対象外にする
					//if (CommUtils.nullToBlank(leadBaseInf.s.Comment__c) != CommUtils.nullToBlank(leadBaseInf.orgComment)) 
					//lead.Comment3__c = leadBaseInf.s.Comment__c;
				}
				update existLeads;
			}
			
			// 予約明細（予約インデックス（SUB)）更新される情報格納
			List<LeadItem> changeItemList = new List<LeadItem>();
			// 2016/04/06 ご予約情報はキャンセルから復活する BEGIN
			List<LeadIndex__c> statusOnlyChangeSubIdxLst = new List<LeadIndex__c>();
			// 2016/04/06 ご予約情報はキャンセルから復活する END
			// 予約明細詳細処理
            for (LeadItem item : oLeadLst) {
            	// キャンセル対象データ
            	if (item.isDelete()) {
            	   delSubLst.add(item.s);
            	   continue;
            	}
            	// 無効なデータ場合、処理対象外
                if (!item.isValidate()) continue;
                
                // 予約明細（予約インデックス（SUB)）新規、更新関連処理
                if (item.s.Id != null) {
                	// 更新登録
                	item.s.LeadName__c = leadBaseInf.s.LeadName__c;

		        	// 該当データは変更あり場合、更新処理を行う
		        	if (item.isChgData()) {
			            // 有効なSUBINDEXデータを格納する
			            changeItemList.add(item);
		        	}
		        	// 2016/04/06 ご予約情報はキャンセルから復活する BEGIN
		        	else if (item.isChgStatus()) {
		        		item.s.StatusLst__c = item.getStatus();
		        		statusOnlyChangeSubIdxLst.add(item.s);
		        	}
		        	// 2016/04/06 ご予約情報はキャンセルから復活する END
                } else {
	                // 新規登録
	                LeadIndex__c subIndex = item.s;
					subIndex.contactRef__c = leadBaseInf.s.contactRef__c;
	                subIndex.Channel__c = leadBaseInf.s.Channel__c;
	                subIndex.Segment__c = leadBaseInf.s.Segment__c;
					subIndex.ParentLeadIndxRef__c = leadBaseInf.s.Id;
					// 2013/11/26 到着時刻と出発時刻は明細単位で設定する
					//subIndex.EntryTime__c = leadBaseInf.s.EntryTime__c;
					//subIndex.DepartureTime__c = leadBaseInf.s.DepartureTime__c;
					subIndex.LeadName__c = leadBaseInf.s.LeadName__c;
					// 2016/08/18 ネット取り込みから予約情報に対して、小部屋の特記事項をなしに対応する BEGIN
					//subIndex.Comment__c = leadBaseInf.s.Comment__c;
					// 2016/08/18 ネット取り込みから予約情報に対して、小部屋の特記事項をなしに対応する END
					subIndex.Payment__c = leadBaseInf.s.Payment__c;
	                indexSubLst.add(subIndex);
                }              
            }
			// 予約明細と予約明細に関連づくの予約データを更新する		
			if (!changeItemList.isEmpty()) autoUpdateLeadInfo(changeItemList);
			// 2016/04/06 ご予約情報はキャンセルから復活する BEGIN
			if(!statusOnlyChangeSubIdxLst.isEmpty()) update statusOnlyChangeSubIdxLst;
			// 2016/04/06 ご予約情報はキャンセルから復活する END
		} // End If (leadBaseInf.s.Id == null)
		
		// IndexのIDガミ存在する場合、登録を行う
		// 予約明細データの登録、関連の予約データも自動登録を行う
		if (!indexSubLst.isEmpty()) {
			// 予約明細新規登録
			insert indexSubLst;
			// 予約データ展開、新規作成を行う
			autoGenerLeadInfo(indexSubLst);
		}
		/*
		Set<Id> roomIdSet = new Set<Id>();
		// GuestRoom関連の再設定を行う
		if (!subIdRepMap.isEmpty()) {

			// BookingGuest__c
			List<BookingGuest__c> bookingGuestLst = [select id, IndexSubRef__c, RoomRef__c from BookingGuest__c where IndexSubRef__c in :subIdRepMap.keySet()];
			for (BookingGuest__c bkGuest : bookingGuestLst) {
    				Integer rowNum = subIdRepMap.get(bkGuest.IndexSubRef__c);
    				bkGuest.IndexSubRef__c = newSubIdRepMap.get(rowNum).Id;
    				// 既にアサイン済みの部屋は予約期間内既にアサインされているかどうか、チェック用
    				if (bkGuest.RoomRef__c != null) roomIdSet.add(bkGuest.RoomRef__c);
    				
			}
			// 部屋アサインチェックを行う
			if (!roomIdSet.isEmpty()) {
	    		Date sdt = leadBaseInf.s.EntryDate__c;
	    		Date edt =  leadBaseInf.s.DepartureDate__c;	
				Integer checkRs = [select count() from Lead__c 
											where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 
								            And DAY_ONLY(convertTimezone(EntryTime__c)) >= :sdt
								            And DAY_ONLY(convertTimezone(EntryTime__c)) < :edt
								            And Rroom__c in :roomIdSet 
								            And LeadIndexSubId__c NOT IN :subIdRepMap.keySet()];
				if (checkRs > 0) {
					Database.rollback(sp);
					Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '宿泊期間に、同じ部屋で重複予約存在するため、予約登録失敗しました。'));
					return;
				}
				
			}
			update bookingGuestLst;
System.debug('bookingGuestLst:::' + bookingGuestLst);
		}*/

		// 予約明細削除
		// 2014/09/24 予約明細削除を行わない、ステータスは通常からキャンセルに変更する
		//if (!delSubLst.isEmpty()) delete delSubLst;
		if (!delSubLst.isEmpty()) {
			for (LeadIndex__c subIdx : delSubLst) {
				// キャンセルに更新を行う
				subIdx.StatusLst__c = CommConst.LEAD_ST_CANCEL;
			}
			update delSubLst;
		}
		} catch (Exception e) {
			DataBase.rollback(sp);
			// 2017/05/04 自施設の予約や会計しか変更できないように権限管理機能 BEGIN
			//Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
			String errMsg = e.getMessage();
            if(!CommUtils.isFieldValidationMessage(errMsg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
			// 2017/05/04 自施設の予約や会計しか変更できないように権限管理機能 END
			return;
		}
		// 最新予約情報を取得、更新を行う
		refreshExistLeadInfo();
	}
	
	/**
	* 予約データの自動更新機能
	* Descript：画面登録したSubIndex（更新）
	**/
	private void autoUpdateLeadInfo(List<LeadItem> p_subLst) {
		// 2018/03/07 Security Check BEGIN
		List<String> chkFieldsLst = new List<String>{'statuslst__c','leadname__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.LeadIndex__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(chkFieldsLst, mm)) {
			return ;
		}
		// 2018/03/07 Security Check END
		// SubIndex未設定のケースに対して、問題あり、部屋タイプ未設定のケース
		// 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
        //String defCheckInTime = CommConst.DEF_CHECKIN_TIME;
        //String defCheckOtTime = CommConst.DEF_CHECKOT_TIME;
        String defCheckInTime = JS_DEFCHKIN_DT;
        String defCheckOtTime = JS_DEFCHKOT_DT;
        // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
        // 部屋数０から１以上に変更する TODO
        // 予約新規として、予約処理作成を行う
        
		// 既存のSUBINDEXデータのID SET
		Set<Id> subIdxIdSet = new Set<Id>();
		for (LeadItem item : p_subLst) { 
            // 有効なSUBINDEXデータを格納する
            subIdxIdSet.add(item.s.Id);
		}
		
		// 更新するありの予約データを格納する
		// 更新対象フラグ<IndexSubId, Map<GroupNo, List<予約データ>>
		Map<Id, Map<Integer, List<Lead__c>>> subIndexMap = new Map<Id, Map<Integer, List<Lead__c>>>();
		// 既存の予約データ対象取得
		Id baseIdxId = leadBaseInf.s.Id;
		// 予約明細と同じ、同じグループの予約情報を格納する
		Integer locLCanelFlg = CommConst.LEAD_ST_CANCEL_FLG;
		String leadQueryStr = CommSqlUtils.generateQueryString('Lead__c');
		leadQueryStr += ' where LeadIndexRef__c = :baseIdxId And LeadIndexSubId__c = :subIdxIdSet ';
		leadQueryStr += ' And CancelBool__c != : locLCanelFlg ';
		leadQueryStr += ' Order By LeadIndexSubId__c, RoomGroupNo__c, EntryTime__c ';
		// 既存の予約データを取得する
		// SUBINDEX---GROUPNO---予約リスト
		// 2016/05/27 直接画面からN部屋は直接キャンセル　OR　N泊から途中にキャンセルする場合、実際の泊数対応
		map<Id, set<integer>> groupNoToIndexMatchMap = new map<id,set<integer>>();
		for (Lead__c lead : Database.query(leadQueryStr)) {	
			if (!subIndexMap.containsKey(lead.LeadIndexSubId__c)) subIndexMap.put(lead.LeadIndexSubId__c, new Map<Integer, List<Lead__c>>());
			// 2016/05/27 直接画面からN部屋は直接キャンセル　OR　N泊から途中にキャンセルする場合、実際の泊数対応
			if (!groupNoToIndexMatchMap.containsKey(lead.LeadIndexSubId__c)) groupNoToIndexMatchMap.put(lead.LeadIndexSubId__c, new set<integer>());
			Map<Integer, List<Lead__c>> oneGroupLeadMap = subIndexMap.get(lead.LeadIndexSubId__c);
			// 2016/05/27 直接画面からN部屋は直接キャンセル　OR　N泊から途中にキャンセルする場合、実際の泊数対応 BEGIN
			Integer wkGroupNo = lead.RoomGroupNo__c.intValue();
			set<Integer> groupNoToIndexMatchSet = groupNoToIndexMatchMap.get(lead.LeadIndexSubId__c);
			Integer groupNo = groupNoToIndexMatchSet.contains(wkGroupNo) ? groupNoToIndexMatchSet.size() - 1 : groupNoToIndexMatchSet.size();
			groupNoToIndexMatchSet.add(wkGroupNo);
			// 2016/05/27 直接画面からN部屋は直接キャンセル　OR　N泊から途中にキャンセルする場合、実際の泊数対応 END
			if (!oneGroupLeadMap.containsKey(groupNo)) oneGroupLeadMap.put(groupNo, new List<Lead__c>());
			oneGroupLeadMap.get(groupNo).add(lead);
		}
		
		// 新規、変更する予約データ情報を格納する
		List<Lead__c> updLeadLst = new List<Lead__c>();
		// 変更された予約明細（予約インデックス（SUB）
		List<LeadIndex__c> updSubIdxLst = new List<LeadIndex__c>();
		// 期間延長の予約データ、部屋既にアサインする倍、延長する期間に既に重複アサインする部屋が存在がどう、チェック用配列
//		Set<Id> chgTermRoomIdSet = new Set<Id>();
		// <IndexSub/<GroupNo/<開始日/終了日>>>
//		Map<Id, Map<Integer,List<Date>>> chgTermLeadMap = new Map<Id, Map<Integer,List<Date>>>();
		Set<Id> chgTypeSubIdxIdSet = new Set<Id>();
		// 変更に従って、予約連動処理更新
		for (LeadItem subIdxitem : p_subLst) {
			// 処理対象外
			if (!subIdxIdSet.contains(subIdxitem.s.Id)) continue;
			
			// SUBINDEX関連の予約データMAPを取得する
			Map<Integer, List<Lead__c>> oneGroupLeadMap = subIndexMap.get(subIdxitem.s.Id);
			// 該当SUBINDEXの関連付く予約データが未存在する場合、処理SKIP(2013/09/10)
			if (oneGroupLeadMap == null) continue;
			
			// 予約明細取得
			LeadIndex__c nw = subIdxitem.s;
			// 2016/04/06 ご予約情報はキャンセルから復活する BEGIN
			nw.StatusLst__c = subIdxitem.getStatus();
			// 2016/04/06 ご予約情報はキャンセルから復活する END
            // 部屋数の取得
            Integer bookingRooms = CommUtils.nullToZero(nw.Rooms__c).intValue();
            // 予約明細更新リストへ格納する
            updSubIdxLst.add(nw);
            
            // ********************************
            // 連動変更処理機能
            // ********************************
			// 部屋タイプ変更に従って、既に設定済みの部屋はクリアを行う
			// TODO:注意事項があり:既にアサイン済みの部屋は全部自動クリア
			if (subIdxitem.isChgType()) {
				for (Integer groupNo : oneGroupLeadMap.keySet()) {
					// 同じ部屋の予約データリストを取得する(同じ部屋N泊の予約データ)
					List<Lead__c> nightsLeads = oneGroupLeadMap.get(groupNo);
					for (Lead__c lead : nightsLeads) {
						if (lead.Field276__c) {
							// 部屋変更不可する場合、部屋タイプ変更対象外にする
							continue;
						}
						lead.refTypeOfRooms__c = nw.RoomTypeRef__c;
						lead.Rroom__c = null;
					}
				}
				// 部屋タイプ変更に従って、宿泊者名簿の既にアサイン済みの部屋はクリアする
				chgTypeSubIdxIdSet.add(nw.Id);
			}
			// 出発時刻と到着時刻を変更する場合
			if (subIdxItem.isChgTime()) {
				for (Integer groupNo : oneGroupLeadMap.keySet()) {
					// 同じ部屋の予約データリストを取得する(同じ部屋N泊の予約データ)
					List<Lead__c> updLeads = oneGroupLeadMap.get(groupNo);
					for (Lead__c lead : updLeads) {
						lead.Field4__c = nw.EntryTime__c;
						lead.Field3__c = nw.DepartureTime__c;
					}
				}
			}
			// 人数変更の場合
			if (subIdxitem.isChgPersons()) {
				for (Integer groupNo : oneGroupLeadMap.keySet()) {
					// 同じ部屋の予約データリストを取得する(同じ部屋N泊の予約データ)
					List<Lead__c> updLeads = oneGroupLeadMap.get(groupNo);
					for (Lead__c lead : updLeads) {
						lead.StayPersons__c = nw.StayPersons__c;
					}
				}	
			}
			// プラン変更の場合
			if (subIdxitem.isChgPlan()) {
				for (Integer groupNo : oneGroupLeadMap.keySet()) {
					// 同じ部屋の予約データリストを取得する(同じ部屋N泊の予約データ)
					List<Lead__c> updLeads = oneGroupLeadMap.get(groupNo);
					for (Lead__c lead : updLeads) {
						lead.Field310__c = nw.PlanRef__c;
					}
				}
			}
			// E/B変更の場合
			if (subIdxitem.isChgEb()) {
				for (Integer groupNo : oneGroupLeadMap.keySet()) {
					// 同じ部屋の予約データリストを取得する(同じ部屋N泊の予約データ)
					List<Lead__c> updLeads = oneGroupLeadMap.get(groupNo);
					for (Lead__c lead : updLeads) {
						lead.ExtraBedChk__c = nw.ExtraBedChk__c;
					}
				}
			}
			// 期間設定変更あり場合
			if (subIdxitem.isChgTerm()) {

				// **********************************
				// 予約インデックス（SUB)
				// **********************************
	           // 宿泊数0場合、一日分の宿泊で計算を行う[当日チェックイン、当日チェックアウト対応]
	            Integer staysNums = CommUtils.nullToZero(nw.Nights__c).intValue();
	            
	            // 宿泊開始日と宿泊出発日の取得
	            Date defaultDate = nw.EntryDate__c;
	            String startTime = CommUtils.isBlank(nw.EntryTime__c) ? defCheckInTime : nw.EntryTime__c;
	            String endTime = CommUtils.isBlank(nw.DepartureTime__c) ? defCheckOtTime : nw.DepartureTime__c;
	            /* 2013/01/21 */
		        Datetime defCheInDt = Datetime.newInstance(defaultDate, CommUtils.stringToTime(startTime));
		        Datetime defCheOutDt = Datetime.newInstance(defaultDate.addDays(staysNums > 0 ? 1 : 0), CommUtils.stringToTime(endTime));
				// 日帰りの個別処理
				staysNums = staysNums == 0 ? 1 : staysNums;
				// 開始日
				//Date startDt = subIdxitem.s.EntryDate__c;

    			// 設定済予約データの期間延長する
    			for (Integer groupNo : oneGroupLeadMap.keySet()) {
    				// 同じ部屋の予約データリストを取得する(同じ部屋N泊の予約データ)
    				List<Lead__c> nightsLeads = oneGroupLeadMap.get(groupNo);
//System.debug('org nightsLeads:::' + nightsLeads);		
    				// 元データの連泊日数計算を行う
    				Integer orgStaysNums = nightsLeads.size();
    				// 変更前の予約名
    				String orgLeadName = nightsLeads[nightsLeads.size()-1].Name;
    				String leadNamePrefix = orgLeadName.startsWith(LEAD_NAME_PREFIX) ? LEAD_NAME_PREFIX : '';
    				// 泊期間延長の場合
					if (orgStaysNums < staysNums) {
						// 期間変更に従って、延長された日付の部屋は再割当てする事が必要
						Lead__c cloneLead = nightsLeads[nightsLeads.size()-1].clone(false,true);
						cloneLead.refTypeOfRooms__c = nw.RoomTypeRef__c;
						cloneLead.Rroom__c = null;
						// 受付日
						cloneLead.ReservedDate__c = System.now();
						// 受付者
						cloneLead.ReservedContact__c = UserInfo.getName();
						// 2013/11/30 部屋変更不可のクリア
						cloneLead.Field276__c = false;
						// 2014/08/27 単価定義区分機能対応
						cloneLead.UnitPriceDefKb__c = cloneLead.UnitPriceDefKbCal__c;
						// 新規の予約データを自動設定、作成を行う
						// コピー元は同じ部屋の最後の予約データの設定情報
						for (Integer i = orgStaysNums; i < staysNums; i++) {
							Lead__c lead = cloneLead.clone(false,true);
							// 新規データを追加する
							nightsLeads.add(lead);
						}
						// 新変更期間は連泊２日以上の場合、延長期間は重複チェック
						/* 該当機能フ外す
						if (staysNums > 1) {
							// 延期前に、最後の予約データの部屋はアサインされている場合
							// この部屋は延長期間に、重複アサインするがどうか、チェックを行う
							Id roomId = nightsLeads[nightsLeads.size()-1].Rroom__c;
							if (roomId != null) chgTermRoomIdSet.add(roomId);
							// 予約明細（予約インデックスSUB）情報可能する
							if (!chgTermLeadMap.containsKey(nw.Id)) chgTermLeadMap.put(nw.Id, new Map<Integer, List<Date>>());
							Map<Integer, List<Date>> subIdxChgInfMap = chgTermLeadMap.get(nw.Id);
							if (!subIdxChgInfMap.containsKey(groupNo)) subIdxChgInfMap.put(groupNo, new List<Date>());
							// 変更期間設定する[到着日延長期間設定]
							Date endEntryDate = subIdxitem.s.EntryDate__c.addDays(orgStaysNums);
							Date endDepartDate = subIdxitem.s.EntryDate__c.addDays(staysNums-1);
							subIdxChgInfMap.get(groupNo).add(endEntryDate);
							subIdxChgInfMap.get(groupNo).add(endDepartDate);
						}
System.debug('chgTermLeadMap::::' + chgTermLeadMap); 
						*/
					} 
					// 期間短縮の場合
					else if (orgStaysNums > staysNums) {
						// 期間外の予約データは全部キャンセル処理を行う
						for (Integer i = staysNums; i < orgStaysNums; i++) {
							nightsLeads[i].ReservedStatus__c = CommConst.LEAD_ST_CANCEL;
						}
					}
					// 連泊期間の予約データを変更を行う
					// 予約名の再定義、期間の再変更を行う
    				for(Integer i=0; i < staysNums; i++) {
    					
    					// 既存の予約データ更新を行う
    					Lead__c newLead = nightsLeads[i];
    					
    					//extLead.EntryTime__c = DateTime.newInstance(startDt.addDays(i), extLead.EntryTime__c.Time());
    					//extLead.Departure__c = DateTime.newInstance(startDt.addDays(i+1), extLead.Departure__c.Time());
    					//泊目
		                if (nw.Nights__c > 1) newLead.name = leadNamePrefix + String.valueOf(nw.Nights__c) + '-' + (i+1) + Label.CONST_001_0067 + nw.LeadName__c;
		                else newLead.name = leadNamePrefix + nw.LeadName__c;

		                // 到着日と出発日
		                newLead.EntryTime__c = DateTime.newInstance(defCheInDt.addDays(i).date(), newLead.EntryTime__c.time());
		                newLead.Departure__c = DateTime.newInstance(defCheOutDt.addDays(i).date(), newLead.Departure__c.time());
		                //newLead.Field4__c = startTime;
		                //newLead.Field3__c = endTime;
                		if (CommUtils.isBlank(newLead.Field4__c)) newLead.Field4__c = startTime;
		                if (CommUtils.isBlank(newLead.Field3__c)) newLead.Field3__c = endTime;
    				}
    			}
			}
//System.debug('subIdxitem.isChgRooms::' + subIdxitem.isChgRooms());
//System.debug('orgSobj:' + subIdxitem.orgSobj.Rooms__c);
//System.debug('newSobj:' + subIdxitem.s.Rooms__c);
			// 部屋数変更する場合
			if (subIdxitem.isChgRooms()) {
				// 部屋数変更に従って、部屋GROUPNO関連の自動増える、減らす処理を行う
				Integer maxGroupNo = oneGroupLeadMap.size();
//system.debug('maxGroupNo:::' + maxGroupNo);
				// 部屋数増える場合
				if (bookingRooms > maxGroupNo) {
					// 最後の部屋からCOPY
					List<Lead__c> nightsLeads = oneGroupLeadMap.get(maxGroupNo-1);
					// コピー用部屋情報を定義
					List<Lead__c> cloneLeads = nightsLeads.deepClone(false,true);
//system.debug('nightsLeads:::' + nightsLeads);
					for (Lead__c lead : cloneLeads) {
						// 2014/08/27 単価定義区分機能対応
						lead.UnitPriceDefKb__c = lead.UnitPriceDefKbCal__c;
						// 受付日
						lead.ReservedDate__c = System.now();
						// 受付者
						lead.ReservedContact__c = UserInfo.getName();
						// 新部屋の部屋タイプ設定、
						lead.refTypeOfRooms__c = nw.RoomTypeRef__c;
						// 部屋は未割り当てるに設定する
						lead.Rroom__c = null;
						// 2013/11/06 お客様のステータスはＮＵＬＬに設定する
						lead.Field298__c = null;
						// 2013/11/30 部屋変更不可のクリア
						lead.Field276__c = false;
						// 予約名の再設定
						if (lead.Name.startsWith(LEAD_NAME_PREFIX)) lead.Name = lead.Name.replaceFirst(LEAD_NAME_PREFIX,'');
					}
					// 新室の情報を追加する
					for (Integer i = maxGroupNo; i < bookingRooms; i++) {
//system.debug(':::['+i+']:::');
						// 新室情報をコピーする
						List<Lead__c> newLeads = cloneLeads.deepClone(false,true);
						// グループNO設定
						for (Lead__c lead : newLeads) lead.RoomGroupNo__c = i;
						// 新規データを追加する
						oneGroupLeadMap.put(i, newLeads);
					}
				} else if (bookingRooms < maxGroupNo) {
//System.debug('------------------');
//System.debug('--------bookingRooms----------'+bookingRooms);
//System.debug('--------maxGroupNo----------'+maxGroupNo);

					// 要らない部屋予約情報はキャンセルする
					for (Integer i = bookingRooms; i < maxGroupNo; i++) {
//System.debug('---------['+i+']---------');
						List<Lead__c> nightsLeads = oneGroupLeadMap.get(i);
						for (Lead__c lead : nightsLeads) lead.ReservedStatus__c = CommConst.LEAD_ST_CANCEL;
					}
				}
			}
			/* 2014/04/29 DELETE
			// 関連予約の部屋タイプ　｜｜　プランを更新を行う
			for (Integer groupNo : oneGroupLeadMap.keySet()) {
				// 同じ部屋の予約データリストを取得する(同じ部屋N泊の予約データ)
				List<Lead__c> nightsLeads = oneGroupLeadMap.get(groupNo);
				for (Lead__c lead : nightsLeads) {
					lead.StayPersons__c = nw.StayPersons__c;
					lead.ExtraBedChk__c = nw.ExtraBedChk__c;
					lead.Field310__c = nw.PlanRef__c;
				}
			}*/
			
			for (List<Lead__c> leads : oneGroupLeadMap.values()) {
				updLeadLst.addAll(leads);
			}
		}
		// 宿泊者名簿の部屋情報をクリアする
		if (!chgTypeSubIdxIdSet.isEmpty()) {
			// 部屋情報を設定済みの情報
			List<BookingGuest__c> updBookingGuest = [select id, RoomRef__c from BookingGuest__c where IndexSubRef__c in :chgTypeSubIdxIdSet and RoomRef__c != null];
			for (BookingGuest__c guest : updBookingGuest) {
				guest.RoomRef__c = null;
			}
			if (!updBookingGuest.isEmpty()) update updBookingGuest;
		}
		// 更新処理を行う
		update updSubIdxLst;
		upsert updLeadLst;
	}
	/**
	* 予約データの新規自動作成機能
	* Descript：画面登録したSubIndex（新規）
	**/
	private void autoGenerLeadInfo(List<LeadIndex__c> subIndexLst) {
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'reserveddate__c','field310__c','reftypeofrooms__c','field3__c','field4__c','relcontact__c','name','plandetailsyncinfo__c',
														'staypersons__c','reservedcontact__c','roomgroupno__c','segment__c','field2__c','leadindexsubid__c','leadindexref__c',
														'recordtypeid','extrabedchk__c','entrytime__c','departure__c','comment3__c','field315__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.Lead__c.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(chkFieldsLst, mm)) {
			return ;
		}
		// 2019/09/15 Security Check BY zyz END
		// 宿泊レコードタイプ
		//Id bookRecTypeId = CommLogicProcess.getLeadBookingRecType();
        // 予約データを作成する[After Insert]
        List<Lead__c> newLeadLst = new List<Lead__c>();
        // 2013/01/21 ADD
        // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
        // チェックイン時刻、チェックアウト時刻
        //String defCheckInTime = CommConst.DEF_CHECKIN_TIME;
        //String defCheckOtTime = CommConst.DEF_CHECKOT_TIME;
        String defCheckInTime = JS_DEFCHKIN_DT;
        String defCheckOtTime = JS_DEFCHKOT_DT;
        // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
		for (LeadIndex__c nw : subIndexLst) {
           // 宿泊数0場合、一日分の宿泊で計算を行う[当日チェックイン、当日チェックアウト対応]
            Decimal staysNums = CommUtils.nullToZero(nw.Nights__c);
            // 宿泊開始日と宿泊出発日の取得
            Date defaultDate = nw.EntryDate__c;
            
            String startTime = CommUtils.isBlank(nw.EntryTime__c) ? defCheckInTime : nw.EntryTime__c;
            String endTime = CommUtils.isBlank(nw.DepartureTime__c) ? defCheckOtTime : nw.DepartureTime__c;
            /* 2013/01/21 */
	        Datetime defCheInDt = Datetime.newInstance(defaultDate, CommUtils.stringToTime(startTime));
	        Datetime defCheOutDt = Datetime.newInstance(defaultDate.addDays(staysNums > 0 ? 1 : 0), CommUtils.stringToTime(endTime));
//            Date defCheOutDt = nw.DepartureDate__c;
			// 0泊数対応
			staysNums = staysNums == 0 ? 1 : staysNums;
            // 部屋数の取得
            Decimal bookingRooms = CommUtils.nullToZero(nw.Rooms__c);
			// 予約名
			//String leadName = CommUtils.isBlank(nw.LeadName__c) ? leadBaseInf.contactName : nw.LeadName__c;
            // 泊数にて、予約データを分ける
            for(Integer i = 0; i < staysNums; i ++){
                Lead__c newLead = new Lead__c();
                // TODO:予約名の設定ルールは再検討が必要[予約データ名の再検討が必要]
                //泊目
                if (nw.Nights__c > 1) newLead.name = String.valueOf(nw.Nights__c) + '-' + (i+1) + Label.CONST_001_0067 + nw.LeadName__c;
                else newLead.name = nw.LeadName__c;
                // 部屋人数 - 予約人数
                newLead.StayPersons__c = nw.StayPersons__c;
                // 到着日と出発日
                newLead.EntryTime__c = defCheInDt.addDays(i);
                newLead.Departure__c = defCheOutDt.addDays(i);
//                newLead.Field4__c = CommUtils.isBlank(nw.EntryTime__c) ? '15:00' : nw.EntryTime__c;
//                newLead.Field3__c = CommUtils.isBlank(nw.DepartureTime__c) ? '10:00' : nw.DepartureTime__c;
                newLead.Field4__c = CommUtils.isBlank(nw.EntryTime__c) ? defCheckInTime : nw.EntryTime__c;
                newLead.Field3__c = CommUtils.isBlank(nw.DepartureTime__c) ? defCheckOtTime : nw.DepartureTime__c;
                // 部屋タイプ
                newLead.refTypeOfRooms__c = nw.RoomTypeRef__c;
                // プラン情報
                newLead.Field310__c = nw.PlanRef__c;
                // 受付日
                newLead.ReservedDate__c = System.now();
                // 宿泊レコードタイプの設定
                newLead.RecordTypeId = bookRecTypeId;
                // 顧客
                newLead.Relcontact__c = nw.contactRef__c;
                // LeadIndex設定する
                newLead.LeadIndexRef__c = nw.ParentLeadIndxRef__c;
                // SUB　INDEX関連IDを設定する
                newLead.LeadIndexSubId__c = nw.Id;
                // 予約チャネル
                newLead.Field2__c = nw.Channel__c;
                // セグメント
                newLead.Segment__c = nw.Segment__c;
                // E/B
                newLead.ExtraBedChk__c = nw.ExtraBedChk__c;
//System.debug('nw.LeadIndexRef__r.contactRef__c::::' + nw.LeadIndexRef__r.contactRef__c);
				// 予約受付者
				newLead.ReservedContact__c = UserInfo.getName();
				// 特記事項
				newLead.Comment3__c = nw.Comment__c;
				// 支払方法
				newLead.Field315__c = nw.Payment__c;
				// 2014/06/20 個別設定情報をコピーする
				newLead.PlanDetailSyncInfo__c = nw.PlanDetailSyncInfo__c;
                // 部屋数単位で、１日１部屋単位に、予約データを作成する
                for(Integer j = 0; j < bookingRooms; j ++ ){
                    newLead.RoomGroupNo__c = j;
                    newLeadLst.add(newLead.clone(false, true));
                }
//                System.debug('newLeadLst::::'+newLeadLst);

            }
		}
        // 予約データの新規登録
        if (!newLeadLst.isEmpty()) insert newLeadLst;
	}

    // 宿泊者名簿

	// 支払方式
    public List<Selectoption> paymentTypeLst{get; private set;}
    // 予約INDEX明細（SUB）設定を行う
	private void setLeadSubLst(String leadIdxId) {
		// 格納用配列初期化
		oLeadLst = new List<LeadItem>();
		// 予約インデックスID
		if (leadIdxId != null) {
			//予約インデックスSUB
	        List<LeadIndex__c> indexSub = [
	        								select name, LeadName__c, SalesPrice__c, PlanRef__c, Nights__c, DepartureDate__c, EntryDate__c, RoomTypeRef__c
	        											, Rooms__c, ParentLeadIndxRef__c,StayPersons__c,ExtraBedChk__c 
	        											, EntryTime__c ,DepartureTime__c,PlanDetailSyncInfo__c
	        											, StatusLst__c
	        								from LeadIndex__c 
	        								where ParentLeadIndxRef__c = :leadIdxId order by name];
			Set<Id> subIndexIdSet = new Set<Id>();
			//Set<Id> planIdSet = new Set<Id>();
			Map<Id, Id> subIdxPlanMap = new Map<Id, Id>();
			for (LeadIndex__c item : indexSub) {
				if (item.PlanRef__c != null && CommUtils.nullToZero(item.SalesPrice__c) == 0) {
					// PlanId存在、売価非存在場合、該当データに関連付く予約見積り明細のプラン商品の単価値を取得、画面に表示を行う
					//subIndexIdSet.add(item.Id);
					//planIdSet.add(item.PlanRef__c);
					subIdxPlanMap.put(item.Id, item.PlanRef__c);
				}
				subIndexIdSet.add(item.Id);
			}

			// 各SUBINDEXに、有効な予約データ存在チェックする
			Set<Id> subIdxHaveLeadSet = new Set<Id>();
			for (AggregateResult r : [	select LeadIndexSubId__c subId from Lead__c 
										where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
										And LeadIndexSubId__c = :subIndexIdSet
										And LeadIndexRef__c = :leadIdxId
										Group By LeadIndexSubId__c]) {
				// 該当予約インデックスSUBに関連付くの有効な予約データは存在する場合
				subIdxHaveLeadSet.add((Id)r.get('subId'));
			}

			// 各SUBINDEXに、チェックインデータあり・なし判断処理を行う
			Map<Id, Integer> checkInStatusMap = new Map<Id, Integer>();
			for (AggregateResult r : [	select LeadIndexSubId__c subId, count(Id) checkinNums from Lead__c 
										where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG And Field298__c != null 
										And LeadIndexSubId__c = :subIdxHaveLeadSet
										And LeadIndexRef__c = :leadIdxId
										Group By LeadIndexSubId__c]) {
				// SubIndexの予約データのチェックインステータス判別
				checkInStatusMap.put((Id)r.get('subId'), (Integer)r.get('checkinNums'));
			}
			
			// プランから会計商品(プラン)IDを取得する
			// プランID / 会計商品(プラン)ID
	        Map<Id, Id> planProdMap = new Map<Id, Id>();
	        for (AggregateResult r : [select PlanRef__c planRef, min(PlanProdcut__c) planProdId
	        	from PlanDetail__c where PlanRef__c in :subIdxPlanMap.values() and PlanProdcut__c != null group by PlanRef__c]) {
	        	planProdMap.put((Id)r.get('planRef'), (Id)r.get('planProdId'));
	        }

			// プランIDから、会計商品のIDを取得する、該当商品IDで、見積り明細の商品情報を比較して、単価を取得する
			// 見積り明細：会計商品　＝　会計商品（プラン）　AND　
			Map<Id, Decimal> salesPriceMap = new Map<Id, Decimal>();
			if (!subIdxPlanMap.isEmpty()) {
				for (AggregateResult r : [select refBooking__r.LeadIndexSubId__c subIdxId, max(UnitPrice__c) price from BookingEstimateItem__c
					 where refBooking__r.LeadIndexSubId__c in :subIdxPlanMap.keySet() And refAccountMaster__r.ActionType__c = 'プラン'
					 And refAccountMaster__c in :planProdMap.values()
				 	 group by refBooking__r.LeadIndexSubId__c ]) {
					salesPriceMap.put((Id)r.get('subIdxId'), (Decimal)r.get('price'));
				}
			}
//System.debug(':::: salesPriceMap ::::' + salesPriceMap);
			for (LeadIndex__c item : indexSub) {
				// ダミの明細情報(有効な予約データがない)は表示対象外
				if (!subIdxHaveLeadSet.contains(item.Id)) continue;
				// プランの売価情報を設定する
				if (item.PlanRef__c != null && CommUtils.nullToZero(item.SalesPrice__c) == 0) {
					item.SalesPrice__c = salesPriceMap.get(item.Id);
				}
				// 表示の明細情報を格納する
				oLeadLst.add(new LeadItem(item, oLeadLst.size()));
				// 既にチェックイン場合、Readonly設定する
				if (checkInStatusMap.containsKey(item.id) && checkInStatusMap.get(item.Id) > 0) {
					oLeadLst[oLeadLst.size()-1].isReadOnly = true;
					// チェックインありフラグ設定
					isExistCheckIn = true;
				}
				// 2016/04/06 ご予約情報はキャンセルから復活する BEGIN
				oLeadLst[oLeadLst.size()-1].isCancel = false;
				// 2016/04/06 ご予約情報はキャンセルから復活する END
			}
		}

		// Dumy Data AutoSetup
		// 2017/01/18 行追加共通化　by zy BEGIN
		//Integer dumyDataLen = 15 - oLeadLst.size();
		Integer defRowsLen = 15;
		Integer dumyDataLen = 0;
		if (oLeadLst.size() >= defRowsLen) {
			Integer newInitLen = oLeadLst.size() - defRowsLen;
			dumyDataLen = defInputLines - Math.Mod(newInitLen, defInputLines);
		} else {
			dumyDataLen = defRowsLen - oLeadLst.size();
		}
		addSubIdxItem(dumyDataLen);
		// 2017/01/18 行追加共通化　by zy END

        // 宿泊者名簿
        oGuestLst = new List<ContactItem>();
        // プラン初期情報設定
        oPlanInfo = new PlanInfoItem();
	}

	/**
	* プラン明細情報表示情報
	**/
	private void refreshPlanLst(LeadIndex__c sub) {
		String planId = sub.PlanRef__c;
		// 明細情報を取得して、料金計算、表示を行う
		if (CommUtils.isBlank(planId)) return;

		oPlanInfo = new PlanInfoItem();
		// 予約明細の泊数　＊　部屋数取得する
		Decimal nights = CommUtils.nullToZero(sub.Nights__c) == 0 ? 1 : CommUtils.nullToZero(sub.Nights__c);
		Decimal baseNum = nights * CommUtils.nullToZero(sub.Rooms__c);
		Decimal planPrice = sub.SalesPrice__c;
		// プラン明細情報を取得、設定を行う
		for ( PlanDetail__c sobj : [select Name, PlanRef__c, AccountMasterRef__c, AccountMasterRef__r.Name ,TaxRate__c,
									AccountMasterRef__r.ActionType__c, // 商品処理種別
									PlanRef__r.Price__c,
		                            AccountMasterRef__r.Field5__c, JmstRef__c, ServiceRate__c, Price__c, ProductNumber__c, PlanProdcut__c
									from PlanDetail__c where PlanRef__c = :planId]) {
			oPlanInfo.addPlan(sobj);
			if (planPrice == null) planPrice = sobj.PlanRef__r.Price__c;
			//planPrice = sobj.PlanRef__r.Price__c;
		}
		// 人数と泊数と部屋にて、関連情報を再計算を行う
		// 室料合計: 泊数 * 部屋 * 単日の室料
		oPlanInfo.roomPrice = oPlanInfo.roomPrice * baseNum;
		// 朝食合計: 泊数 * 部屋 * 単日の朝食
		oPlanInfo.breakfastPrice = oPlanInfo.breakfastPrice * baseNum;
		oPlanInfo.breakfastCnt = baseNum;
		// 夕食合計: 泊数 * 部屋 * 単日の夕食
		oPlanInfo.dinnerPrice = oPlanInfo.dinnerPrice * baseNum;
		oPlanInfo.dinnerCnt = baseNum;
		// その他合計
		oPlanInfo.otherPrice = oPlanInfo.otherPrice * baseNum;
		// 総合計
		oPlanInfo.totalPrice = CommUtils.nullToZero(planPrice) * baseNum;
		// 人数合計:部屋数 * 部屋人数
		oPlanInfo.totalPeople = CommUtils.nullToZero(sub.StayPersons__c) * CommUtils.nullToZero(sub.Rooms__c);

	}
	/**
	* 当日分の予約データのチェックイン
	**/
	public void bulkCheckIn() {
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'field298__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.Lead__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(chkFieldsLst, mm)) {
			return ;
		}
		// 2019/09/15 Security Check BY zyz END
		// 当日予約データの存在チェックを行う
		Date todayDt = Date.today();
		Id leadIndexId = leadBaseInf.s.Id;
		List<Lead__c> checkinLst = new List<Lead__c>();
		for(Lead__c lead : [select Field298__c from Lead__c where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 
								                And DAY_ONLY(convertTimezone(EntryTime__c)) = :todayDt
								                And Field298__c = null 
								                // 2016/04/13 条件制限を外す BEGIN
								                //And Rroom__c = null
								                // 2016/04/13 条件制限を外す END
								                And LeadIndexRef__c = :leadIndexId ]) {
			  lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
			  checkinLst.add(lead);
		}
		// 2017/05/04 自施設の予約や会計しか変更できないように権限管理機能 BEGIN
		//if (!checkinLst.isEmpty()) update checkinLst;
		try {
			if (!checkinLst.isEmpty()) update checkinLst;
		} catch (Exception e) {
			String errMsg = e.getMessage();
            if(!CommUtils.isFieldValidationMessage(errMsg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
		}
		// 2017/05/04 自施設の予約や会計しか変更できないように権限管理機能 END
		// 最新情報を再取得、設定を行う
		refreshExistLeadInfo();
	}
    /*
    * IndexSubよて、プラン情報/宿泊者名簿情報を取得、設定を行う
    * actionFunction
    * Case1: 既に予約あり、宿泊者名簿情報なし
    * Case2: 既存予約あり、宿泊者名簿情報あり、グループNO一致しない（実際の予約により、増える、下げる）
    */
    public void expandGuestLst() {
    	// 設定の行番号にて、関連の情報を取得、表示を行う
    	oGuestLst = new List<ContactItem>();
    	// プラン明細も初期化する
    	oPlanInfo = new PlanInfoItem();

        if (CommUtils.isBlank(indexSubId)) return;
        // 2019/09/15 Security Check BY zyz BEGIN
        if (!CommSecurityUtils.isDeleteable(BookingGuest__c.getSObjectType())) {
        	return;
        }
        // 2019/09/15 Security Check BY zyz END
        // 関連の処理情報を取得して、表示を行う
        // 設定するIndexSub情報にて、宿泊名簿一覧情報を設定を行う
        List<LeadIndex__c> expIndexSub = [select id, name, RoomTypeRef__c,
            RoomTypeRef__r.Name,contactRef__r.KanaName1__c,Nights__c,
            contactRef__r.Name, contactRef__r.Name1__c, PlanRef__c,
            StayPersons__c,Rooms__c, SalesPrice__c, EntryDate__c,ParentLeadIndxRef__c
            from LeadIndex__c where id = :indexSubId];
        if (expIndexSub.isEmpty()) {
            // TODO:エラーメッセージ設定が必要です
            return;
        }
        // 画面から引き渡し予約インデックスSUBのIDにより　予約インデックスSUB情報を取得する
        LeadIndex__c sub = expIndexSub[0];

    	// プラン情報を表示する[画面右上側のプラン集計情報を設定する]
    	refreshPlanLst(sub);

		// 予約データに既存しているグループNO
        //Set<Decimal> existGroupNoSet = new Set<Decimal>();
        Map<Decimal, Lead__c> groupRoomMap = new Map<Decimal, Lead__c>();
        // 関連の予約データは宿泊名簿にMATCHする
        // 既存の予約情報を取得する[同じ予約インデックス、予約インデックスSBUの予約情報]
        for(Lead__c lead: [select id, name, RoomGroupNo__c, Rroom__c,Rroom__r.Name, refTypeOfRooms__c, refTypeOfRooms__r.Name
        	from Lead__c where LeadIndexSubId__c = :sub.id 
        	And LeadIndexRef__c = :sub.ParentLeadIndxRef__c
        	And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 
        	//And DAY_ONLY(convertTimezone(EntryTime__c)) = :sub.EntryDate__c
        	Order By RoomGroupNo__c asc, EntryTime__c desc]) {
        	
        	//existGroupNoSet.add(lead.RoomGroupNo__c);
        	// グループNOに関連設定された部屋情報を格納する[]
        	if (!groupRoomMap.containsKey(lead.RoomGroupNo__c)) groupRoomMap.put(lead.RoomGroupNo__c, lead);
        	else {
        		// 部屋情報を未設定する場合、最新の予約部屋情報を設定する
        		if (groupRoomMap.get(lead.RoomGroupNo__c).Rroom__c == null && lead.Rroom__c != null) groupRoomMap.put(lead.RoomGroupNo__c, lead);
        	}
        }
//System.debug(LoggingLevel.ERROR, groupRoomMap);
        // 該当Lead数は宿泊名簿の代表者数と
        //oGuestLst = new List<ContactItem>();
		// 宿泊者名簿存在グループNO
		Map<Decimal,List<ContactItem>> existGuestGpNoMap = new Map<Decimal,List<ContactItem>>();
        // 既存の宿泊名簿の情報を取得する
        //List<BookingGuest__c> exitGuestLst = [select id, name, GuestName__c, Sex__c, DelegateFlg__c, LeadIndexSubRef__c
        //    from BookingGuest__c where LeadIndexSubRef__c = :indexSubId Order by GuestAutoNo__c asc];
        for (BookingGuest__c s : [  select id, name, GuestName__c, Sex__c, DelegateFlg__c, IndexSubRef__c, RoomGroupNo__c,
        							RoomRef__c, RoomRef__r.Name,RoomRef__r.TypeRoomRef__c,RoomRef__r.TypeRoomRef__r.Name
                                    from BookingGuest__c where IndexSubRef__c = :indexSubId And RoomGroupNo__c in :groupRoomMap.keySet()
                                    Order by GuestAutoNo__c asc]) {

            // 既存の宿泊名簿情報を格納する
            ContactItem item = new ContactItem(s);
            // 既存の宿泊者名簿の部屋情報は予約情報と一致しない場合、予約情報から再設定を行う
            Lead__c lead = groupRoomMap.get(s.RoomGroupNo__c);
            //if (s.RoomRef__c != lead.Rroom__c) {
            if (lead != null) {
            	s.RoomRef__c = lead.Rroom__c;
            	item.roomId = s.RoomRef__c;
            	item.roomNo = lead.Rroom__r.Name;
            	item.roomType = lead.refTypeOfRooms__r.Name;
            	item.roomTypeId = lead.refTypeOfRooms__c;
            }
            // 2013/08/22 部屋既に設定する場合、部屋の情報を設定する
            if(CommUtils.isBlank(item.roomType)) item.roomType = sub.RoomTypeRef__r.Name;
            if(CommUtils.isBlank(item.roomTypeId)) item.roomTypeId = sub.RoomTypeRef__c;
            //item.s.LeadIndexSubRef__c = sub.Id;

            //oGuestLst.add(item);
            // 既存の宿泊者名簿のグループNOセット
            if (!existGuestGpNoMap.containsKey(s.RoomGroupNo__c)) existGuestGpNoMap.put(s.RoomGroupNo__c, new List<ContactItem>());
            (existGuestGpNoMap.get(s.RoomGroupNo__c)).add(item);
        }
        // 既になくなるの宿泊者名簿情報を削除する[宿泊者名簿が存在、同じグループNOの予約データが非存在の場合、該当宿泊者名簿を削除する]
        if (!existGuestGpNoMap.isEmpty()) delete [select id from BookingGuest__c where IndexSubRef__c = :indexSubId And RoomGroupNo__c not in :existGuestGpNoMap.keySet()];
//System.debug(LoggingLevel.ERROR, existGuestGpNoMap);
        // 自動宿泊者名簿データの初期データを登録する
        // 部屋数　* 人数 で名簿データを作成する
        //if (oGuestLst.isEmpty()) {
        //if (existGuestGpNoMap.size() != sub.Rooms__c) {
        	// 初期化設定を行う
	        //for (Integer i= 0 ; i < sub.Rooms__c; i++) {
	        for (Decimal i : groupRoomMap.keySet()) {
	        	// 部屋グループNOチェック
	        	if (existGuestGpNoMap.containsKey(i)) {
//System.debug(LoggingLevel.ERROR, 'existGuestGpNoMap.get(i):' + existGuestGpNoMap.get(i));
	        		// 既存の宿泊者名簿は表示の配列に入ります
	        		oGuestLst.addAll(existGuestGpNoMap.get(i));
	        		continue;
	        	}
	        	Id roomId = null;
	        	String roomNo = null;
	        	Id roomTypeId = sub.RoomTypeRef__c;
	        	String roomTypeNm = sub.RoomTypeRef__r.Name;
	        	// 予約存在、宿泊者名簿が未存在する場合
	        	if (groupRoomMap.containsKey(i)) {
//System.debug(LoggingLevel.ERROR, 'groupRoomMap.get(i):' + groupRoomMap.get(i));
	        		Lead__c lead = groupRoomMap.get(i);
	            	roomId = lead.Rroom__c;
	            	roomNo = lead.Rroom__r.Name;
	            	roomTypeNm = lead.refTypeOfRooms__r.Name;
	            	roomTypeId = lead.refTypeOfRooms__c;
	        	}
	        	for (Integer j= 0; j< sub.StayPersons__c; j++) {
	                ContactItem item = new ContactItem(new BookingGuest__c());
	                if ( j == 0) item.s.DelegateFlg__c = true;
	                item.customKana = sub.contactRef__r.Name;
	                item.customName = sub.contactRef__r.Name1__c;
	                item.roomType = roomTypeNm;
	                item.roomTypeId = roomTypeId;
	                item.roomNo = roomNo;
	                item.roomId = roomId;
	                item.s.RoomRef__c = roomId;
	                item.s.IndexSubRef__c = sub.Id;
	                item.s.RoomGroupNo__c = i;
//System.debug(LoggingLevel.ERROR, 'groupRoomMap.ContactItem(i)(j):' +item);
	                oGuestLst.add(item);
	        	}
	        }
        //}
    }

    /**
    * 宿泊名簿登録・更新を行う
    **/
    public void createGuestInfo() {

Savepoint sp = Database.setSavepoint();   	
try {
        // 2018/03/07 Security Check BEGIN
        List<String> chkFieldsLst = new List<String>{'contactref__c','roomgroupno__c','indexsubref__c','roomref__c','delegateflg__c'};//'id'
        Map<String,Schema.SObjectField> mm = Schema.SObjectType.OrderEntryInfo__c.fields.getMap();
        if (!CommSecurityUtils.isCanCreateable(chkFieldsLst, mm)) {
        	return ;
        }
        // 2018/03/07 Security Check END
        // 2019/09/15 Security Check BY zyz BEGIN
        List<String> chkFieldLst = new List<String>{'reftypeofrooms__c','rroom__c','field298__c'};
        Map<String,Schema.SObjectField> m = Schema.SObjectType.Lead__c.fields.getMap();
        if (!CommSecurityUtils.isCanUpdateable(chkFieldLst, m)) {
        	return ;
        }
        // 2019/09/15 Security Check BY zyz END
        // 既存の宿泊名簿情報を削除する
        // 有効なん名簿情報を登録する
        List<BookingGuest__c> upertLst = new List<BookingGuest__c>();
        // グループNO単位で、設定情報を格納する
		Map<Decimal, BookingGuest__c> groupNoMap = new Map<Decimal,BookingGuest__c>();
		// 登録した宿泊者名簿データをチェツク、設定を行う
        for (ContactItem con : oGuestLst) {
            // 名簿の部屋番号を設定されている場合、関連の予約データの部屋情報を全部設定を行う
            if(con.isValidate) {
            	con.s.ContactRef__c = leadBaseInf.c.Id;
            	con.s.Id = null;
            	upertLst.add(con.s);
            	// 代表者の部屋情報を設定する
            	if (con.s.DelegateFlg__c && !groupNoMap.containsKey(con.s.RoomGroupNo__c)) {
	            	// GroupNo Set
	            	groupNoMap.put(con.s.RoomGroupNo__c, con.s);
            	}
            }
        }
//System.debug('groupNoMap:::' + groupNoMap);
		// 処理データが未存在する場合、処理中止
		if (upertLst.isEmpty()) return;
		// DBに既存の宿泊者名簿データを削除する
		// 2018/03/07 Security Check BEGIN
		if (!CommSecurityUtils.isDeleteable(BookingGuest__c.getSObjectType())) {
			return;
		}
		// 2018/03/07 Security Check END
		delete [select id ,RoomGroupNo__c from BookingGuest__c where IndexSubRef__c = :indexSubId Order By GuestAutoNo__c ];
//System.debug('upertLst:::' + upertLst);
        insert upertLst;
		
        if (!groupNoMap.isEmpty()) {
	        // 関連の予約データの部屋情報を連動更新を行う
	        // 同じSUBINDEX、同じグループNOの予約データを取得、更新を行う
	        Id subIndexId = upertLst[0].IndexSubRef__c;
        	// 既存の予約データを取得する
	        List<Lead__c> updLeadLst = new List<Lead__c>();
	        for (Lead__c l : [select id , name , LeadIndexSubId__c, RoomGroupNo__c from Lead__c where
	        					CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG And
	                            LeadIndexSubId__c = :subIndexId and RoomGroupNo__c in :groupNoMap.keySet()]) {
	            if (groupNoMap.containsKey(l.RoomGroupNo__c)) {
		            // 予約データを取得して、関連の部屋番号を設定する
	            	l.Rroom__c = groupNoMap.get(l.RoomGroupNo__c).RoomRef__c;
	            	// 部屋タイプを再設定お行う
	            	if (l.Rroom__c != null) l.refTypeOfRooms__c = null;
	            	updLeadLst.add(l);
	            }
	        }
	        if (!updLeadLst.isEmpty()) update updLeadLst;
        }
} catch (Exception e) {
	// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 BEGIN
	String errMsg = e.getMessage();
	if(!CommUtils.isFieldValidationMessage(errMsg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
	// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 END
	DataBase.rollback(sp);
}
//System.debug('oGuestLst::::' + oGuestLst);
    }

	// 2014/10/27 予約INDEX　SUB情報を登録する
	public void addSubIdxItem() {
		// 2017/01/18 行追加共通化　by zy BEGIN
		//oLeadLst.add(new LeadItem(new LeadIndex__c(EntryTime__c='', DepartureTime__c=''), oLeadLst.size()));
		addSubIdxItem(null);
		// 2017/01/18 行追加共通化　by zy END
	}
	// 2017/01/18 行追加共通化　by zy BEGIN
	public void addSubIdxItem(Integer dumyDataLen) {
		integer addLength = dumyDataLen == null ? defInputLines : dumyDataLen;
		for (Integer i = 0; i < addLength; i++) {
			oLeadLst.add(new LeadItem(new LeadIndex__c(EntryTime__c='', DepartureTime__c=''), oLeadLst.size()));
		}
	}
	// 2017/01/18 行追加共通化　by zy BEGIN
	
	// プランの標準売価を取得する
	@remoteAction
	public static SObject[] getPlanInfo(String planId) {
//System.debug('getPlanInfo:planId::::' + planId);
		return [select id, Price__c from Plan__c where id  = :planId];
	}

    // 部屋存在チェックを行う
    @remoteAction
    public static SObject[] getIdleRoom(String roomTypId, String startDt, String endDt, String roomNoFilter) {
System.debug('roomTypId::::' + roomTypId);
System.debug('startDt::::' + startDt);
System.debug('endDt::::' + endDt);
System.debug('roomNoFilter::::' + roomNoFilter);
        // 予約データは期間と部屋タイプにて、部屋在庫データを検索して、アサインできる部屋をチェックする
        Id bookingRecTypeId = CommLogicProcess.getLeadBookingRecType();
        // 該当部屋タイプに含めの部屋一覧を取得する
        // 既に予約データに入る場合、該当部屋は選択対象外になる
        /*
        List<Lead__c> existLeadLst = [select id,Rroom__c from Lead__c
        	where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG And RecordTypeId = :bookingRecTypeId
                And DAY_ONLY(convertTimezone(EntryTime__c)) >= :Date.parse(startDt)
                And DAY_ONLY(convertTimezone(EntryTime__c)) < :Date.parse(endDt)
                And refTypeOfRooms__c = :roomTypId And Rroom__c != null];
        Set<Id> roomIdSet = new Set<Id>();
        for (Lead__c lead : existLeadLst) {
        	roomIdSet.add(lead.Rroom__c);
        }*/
        Set<Id> roomIdSet = new Set<Id>();
        for (AggregateResult lead :  [select Rroom__c roomId from Lead__c
            where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG And RecordTypeId = :bookingRecTypeId
                And DAY_ONLY(convertTimezone(EntryTime__c)) >= :Date.parse(startDt)
                And DAY_ONLY(convertTimezone(EntryTime__c)) < :Date.parse(endDt)
                And refTypeOfRooms__c = :roomTypId And Rroom__c != null
                Group By Rroom__c]) {
            roomIdSet.add((Id)lead.get('roomId'));
        }
        // 障害部屋TODO
        List<Room__c> roomLst = new List<Room__c>();
        String queryStr = 'select id, name from Room__c where TypeRoomRef__c = :roomTypId And Id not in :roomIdSet And UseOfRoom__c != \'' + String.escapeSingleQuotes(CommConst.ROOM_UseOfType_Fiction) + '\' ';
        if (!CommUtils.isBlank(roomNoFilter)) queryStr += ' And Name like \'%' + String.escapeSingleQuotes(roomNoFilter) + '%\'';
//        queryStr += ' Order By Seq__c limit 20';
		queryStr += ' Order By Seq__c ';

//System.debug('queryStr::::' + queryStr);

        //Integer maxRoomLst = 20;
        for (Room__c rm  : DataBase.query(queryStr)) {
        	//if (roomIdSet.contains(rm.Id)) continue;
        	//if (roomLst.size() > maxRoomLst) break;
        	roomLst.add(rm);
        }
        return roomLst;
    }
	// プラン明細情報を取得する
	@remoteAction
	public static List<ProductItemUtils.PlanDetail> getPlanDetailListById(String planId) {
		return ProductItemUtils.getPlanDetailList(planId);
	}
	// 商品コードにより、会計商品情報を取得する
	@remoteAction
	public static List<ProductItemUtils.ProductItem> getArrayProductItemInfo(String prodCode) {
		//return ProductItemUtils.getArrayProdcutItemByCode(prodCode);
		return ProductItemUtils.getArrayProdcutItemByCode(prodCode, true, true);
	}
	
	// プラン明細情報格納する
	public PlanInfoItem oPlanInfo{ get; private set;}

	public class PlanInfoItem {
		public PlanInfoItem() {
			roomPrice = breakfastPrice = dinnerPrice = otherPrice = totalPrice = 0;
		}
		public void addPlan(PlanDetail__c planInf) {
			// プラン明細情報にて、情報関連統計を行う
			String procType = planInf.AccountMasterRef__r.ActionType__c;
			if (procType == '室料') {
				roomPrice += CommUtils.nullToZero(planInf.Price__c);
			} else if (procType == '朝食') {
				breakfastPrice += CommUtils.nullToZero(planInf.Price__c);
			} else if (procType == '夕食') {
				dinnerPrice += CommUtils.nullToZero(planInf.Price__c);
			} else {// その他
				otherPrice += CommUtils.nullToZero(planInf.Price__c);
			}
			// 合計統計
			//totalPrice += CommUtils.nullToZero(planInf.Price__c);
			// プラン売価[同じプランので、売価は重複存在する]
			//planPrice = CommUtils.nullToZero(planPrice);
		}
		// プランの売価
		//private Decimal planPrice;
		// 室料合計
		public Decimal roomPrice{get;set;}
		// 朝食
		public Decimal breakfastPrice{get;set;}
		// 夕食
		public Decimal dinnerPrice{get;set;}
		// その他
		public Decimal otherPrice{get;set;}
		// 総合計
		public Decimal totalPrice{get;set;}
		// 朝食の合計
		public Decimal breakfastCnt{get;set;}
		// 夕食の合計
		public Decimal dinnerCnt{get;set;}
		// 総人数
		public Decimal totalPeople{get;set;}
	}


    // IndexSub
    //public String indexSubNo{get;set;}
    public String indexSubId{get;set;}
    public String indexSubNo{get;set;}
    public String indexSubRType{get;set;}
    public String indexSubStrDt{get;set;}
    public String indexSubEndDt{get;set;}
	// 宿泊名簿
	public List<ContactItem> oGuestLst{get; private set;}
	public class ContactItem {
		public ContactItem(BookingGuest__c pGuset) {
			//isDelegateFlg = false;
			s = pGuset;
			customKana = s.Name;
			customName = s.GuestName__c;
			isDelegateFlg = s.DelegateFlg__c;
            isCancel = false;
			roomType = s.RoomRef__r.TypeRoomRef__r.Name;
			roomTypeId = s.RoomRef__r.TypeRoomRef__c;
			roomId = s.RoomRef__c;
			roomNo = (s.RoomRef__c != null ? s.RoomRef__r.Name : '');
		}
		public BookingGuest__c s{get; private set;}
		// 代表者
		public Boolean isDelegateFlg{get;set;}
		// キャンセル
		public Boolean isCancel{get;set;}
		// 予約SUBデータのNO番号
		//public String indexSubNo {get;set;}
		// 宿泊者名（カナ）
		public String customKana {get;set{
		   customKana = value;
		   s.name = value;
		}}
		// 宿泊者名（漢字）
		public String customName {get;set{
            customName = value;
            s.GuestName__c = value;
		}}
		// TYP
		public String roomType{get;set;}
		// 部屋
		public String roomNo{get;set;}
		// 部屋ID　
		public String roomId{get;set{
		  roomId = value;
		  s.RoomRef__c = CommUtils.isBlank(roomId) ? null : roomId;
		}}
		// 部屋タイプID
		public String roomTypeId{get;set;}
        // 有効性チェック
		public boolean isValidate{get{
			return (!CommUtils.isBlank(customKana) || !CommUtils.isBlank(customName));
		}}
	}


	// 予約明細一覧[予約インデックスSUB]
	public List<LeadItem> oLeadLst{get; private set;}
    public class LeadItem {
    	public LeadItem(LeadIndex__c ps, Integer size) {
    	   s = ps;
    	   orgSobj = s.clone(true,true);
    	   //isCancel = false;
    	   isCancel = s.StatusLst__c == CommConst.LEAD_ST_CANCEL ? true : false;
// 2016/04/06 ご予約情報はキャンセルから復活する BEGIN 	   	  	  
    	   //isReadOnly = isCancel || false;
// 2016/04/06 ご予約情報はキャンセルから復活する END	   
    	   rowNo = size + 1;
    	   nights = String.valueOf(ps.Nights__c);
    	   rooms = String.valueOf(ps.Rooms__c);
    	   persons = String.valueOf(ps.StayPersons__c);
//    	   if (s.id != null) isRead = true;
    		// LeadIndex基本情報設定
    		/*
    		orgEntryDt = s.EntryDate__c;
    		orgDepDt = s.DepartureDate__c;
    		orgNights = s.Nights__c; 
    		// 元部屋、人数を格納する
    		orgRooms = rooms;
    		orgPersons = persons;
    		orgPlanId = s.PlanRef__c;
    		*/
    	}
    	public LeadIndex__c s{get; private set;}
    	public LeadIndex__c orgSobj{get; private set;}
    	// 有効性データチェック
    	public Boolean isValidate() {
    		// C/I And 泊数　And C/O TYP / 売価
    		//return !CommUtils.isBlank(s.DepartureDate__c)
    		return
    		(isCancel != true &&
    		s.EntryDate__c != null && s.DepartureDate__c != null &&
    		s.Nights__c != null && s.RoomTypeRef__c != null &&
    		!CommUtils.isBlank(rooms) && CommUtils.nullToZero(rooms) > 0);
    		//return true;
    	}
    	
    	// SubIndexデータ変更された場合
    	public boolean isChgData() {
    		//return isChgTerm() || isChgRooms() || isChgPersons() || isChgPaln();
    		for (String key : leadIdxFieldsSet) {
    			if (orgSobj.get(key) != s.get(key)) return true;
    		}
    		return false;
    	}
    	// 予約時刻を変更する場合
    	public boolean isChgTime() {
    		return (s.EntryTime__c != orgSobj.EntryTime__c || s.DepartureTime__c != orgSobj.DepartureTime__c);
    	}
		// 予約期間変換するがどうか、
		public boolean isChgTerm() {
			if (s.EntryDate__c != orgSobj.EntryDate__c ||
				s.DepartureDate__c != orgSobj.DepartureDate__c ||
				s.Nights__c != orgSobj.Nights__c) {
					return true;
			}
			return false;
		}
		// 室数変更判断ロジック
		public boolean isChgRooms() {
			return (orgSobj.Rooms__c != s.Rooms__c);
		}
		// 人数変更判断ロジック
		public boolean isChgPersons() {
			return (orgSobj.StayPersons__c != s.StayPersons__c);
		}
		// プラン変更判断ロジック
		public boolean isChgPlan() {
			return (orgSobj.PlanRef__c !=  s.PlanRef__c);
		}
		// 部屋タイプ変更ロジック
		public boolean isChgType() {
			return (orgSobj.RoomTypeRef__c !=  s.RoomTypeRef__c);
		}
		// E/B変更ロジック
		public boolean isChgEb() {
			return (orgSobj.ExtraBedChk__c !=  s.ExtraBedChk__c);
		}
		// 2016/04/06 ご予約情報はキャンセルから復活する BEGIN
		// 状態変更
		public Boolean isChgStatus() {
			return (orgSobj.StatusLst__c !=  s.StatusLst__c);
		}
		public String getStatus() {
			return isCancel ? CommConst.LEAD_ST_CANCEL : DEF_STATUS_VALUE;
		}
		// 2016/04/06 ご予約情報はキャンセルから復活する END
		// **********************
		// 元設定情報
		// **********************
		/*
    	// 到着日
    	public Date orgEntryDt{get; private set;} 
    	// 出発日
    	public Date orgDepDt{get; private set;}
    	// 宿泊日数
    	public Decimal orgNights{get; private set;}
    	// 室数
    	public String orgRooms{get;private set;}
    	// 人数
    	public String orgPersons{get; private set;}
    	// プラン
    	public String orgPlanId{get; private set;}
    	*/
    	// 削除対象フラグ
    	public Boolean isDelete() {
    		return isCancel && s.Id != null;
    	}
    	// RowIndex
    	public Integer rowNo{get; set;}
    	public Boolean isCancel{get;set;}
    	// 泊
    	public String nights{get; set{
    		nights = value;
    		s.Nights__c = CommUtils.nullToZero(value);}}
        // 人
        public String persons{get; set{
            persons = value;
            s.StayPersons__c = CommUtils.nullToZero(value);
        }}
        // 室
        public String rooms{get; set{
            rooms = value;
            s.Rooms__c = CommUtils.nullToZero(value);
        }}
        // DIS
        public String discount{get ;set;}
        // 売価[画面表示要・DB反映と関係なし、情報維持するだけ]
        public String salescnt{get{
            return s.SalesPrice__c == null ? '' : s.SalesPrice__c.format();
        }set{
        	salescnt = value;
            if (CommUtils.isBlank(salescnt)) s.SalesPrice__c = null;
            else s.SalesPrice__c = Decimal.valueOf(salescnt.replaceAll(',',''));
        }}
        // DS[autoComplete?][TODO:仕様確認要]
        public String dsField{get; set;}
        // E/B
        //public Boolean isRequireEb{get; set;}
        // 既にチェックインデータあり場合、予約SUBINDEXは更新不可になる
        public Boolean isReadOnly{get; set;}
    }

    // 予約統一管理用Indexテーブル
    //public LeadIndex__c leadInfoIdx{get; set;}
    public LeadBaseInfo leadBaseInf{get; set;}
    public class LeadBaseInfo {
    	public LeadBaseInfo(LeadIndex__c pIndex, Lead__c pLead, Contact pContact) {
    		s = pIndex;
    		l = pLead;
    		c = (pContact == null ? new Contact() : pContact);
    		leadNo = s.Name;
    		contactName = c != null ? c.Name : '';
    		accoutName = (c != null && c.Account != null) ? c.Account.Name : '';
    		// LeadIndex基本情報設定
    		orgEntryDt = s.EntryDate__c;
    		orgDepDt = s.DepartureDate__c;
    		orgNights = s.Nights__c;
    		// 元予約名情報を格納する
    		if (CommUtils.isBlank(s.LeadName__c)) s.LeadName__c = s.ContactNameCal__c;
    		orgLeadName = s.LeadName__c;
    		orgPaymentType = s.Payment__c;
    		orgChannel = s.Channel__c;
    		orgSegment = s.Segment__c;
    		orgComment = s.Comment__c;
    		orgContactId = (c != null ? c.Id : '');
    	}
    	public LeadIndex__c s{get; private set;}
    	public Lead__c l{get; private set;}
    	public Contact c{get; private set;}

    	public void setContact(Contact pContact ) {
            c = pContact;
            s.contactRef__c = c.Id;
        	accoutName = c.Account != null ? c.Account.Name : '';
        }
		// 予約期間変換するがどうか、
		public boolean isChgTerm() {
			if (s.EntryDate__c != orgEntryDt ||
				s.DepartureDate__c != orgDepDt ||
				s.Nights__c != orgNights) {
					return true;
			}
			return false;
		}
    	// 予約Index番号
    	public String leadNo{get; set;}
    	// 予約名
    	public String orgLeadName{get; set;}
    	// お客様ID
    	public String orgContactId{get; set;}
    	// 部屋番号
    	public String roomNo{get; set;}
    	// 到着日
    	public Date orgEntryDt{get; private set;} 
    	// 出発日
    	public Date orgDepDt{get; private set;}
    	// 宿泊日数
    	public Decimal orgNights{get; private set;}
    	// 顧客名
    	public String contactName{get; set;}
        // 顧客名(カナ)
        public String kanaName{get; set;}
        // 顧客名(漢字)
        public String fullName{get ; set;}
        // TEL:電話
        public String phone{get; set;}
        // 会社名（団体）：取引先の自動作成と設定を行う
        public String accoutName{get; set;}
        // 客室情報：メモー１に設定
        public String memo1{get; set;}
        // 付帯情報：メモー２に設定
        public String memo2{get; set;}
        // 支払情報：メモー３に設定
        public String memo3{get; set;}
        
        // 2013/09/10 変更元項目
        // 支払方法
        public String orgPaymentType{get; set;}
        public String orgChannel{get; set;}
        public String orgSegment{get; set;}
        public String orgComment{get; set;}
    }
    
/**
*2015-11-18 
*テストクラスBookingAppTestに移行する

	@isTest(SeeAllData=false)
	static void testCase1() {
    	Test.startTest();
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
		
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	Test.stopTest();
    	// Idで最新情報を取得する
    	String idxName = [select LeadIndexRef__r.Name from Lead__c where id = :leadInfo.Id].LeadIndexRef__r.Name;
    	List<LeadIndex__c> leadIdxLst = [select id from LeadIndex__c where name = :idxName];
    	ApexPages.StandardController contrl = new ApexPages.StandardController(leadIdxLst[0]);
    	BookingApp app = new BookingApp(contrl);
    	app.leadBaseInf.leadNo = idxName;
    	app.refreshExistLeadInfo();
        // 顧客情報を更新を行う
        app.refreshContcatInfo();

 		app.leadBaseInf.contactName = 'UNAME' + Crypto.getRandomLong();
 		app.leadBaseInf.l.Field2__c = '本社';
 		app.leadBaseInf.l.Segment__c = 'CARD';
        app.leadBaseInf.accoutName = 'ACC-NEW' + CommUtils.getRandom(10);

 		app.createLeadInfo();

 		// SubIndex登録を行う
 		//LeadItem item = new LeadItem();
 		app.indexSubId = app.oLeadLst[0].s.Id;
 		app.expandGuestLst();
 		System.assertNotEquals(app.indexSubId, null);
	}
	// 宿泊者名簿関連テスト
	// P1:連泊の予約があり、部屋はすでにアサイン済み、宿泊者名簿が未存在する場合、明細情報をクリックすると、後ろから、部屋アサインありの部屋が宿泊者名簿に表示する
	@isTest(SeeAllData=false)
	static void testCase2() {
		// 予約データの明細情報を変更して、再登録する
    	Test.startTest();
    	Contact guest = TestCommon.createContact();
		TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
		
		// 新規登録
		LeadIndex__c sobj = new LeadIndex__c();
    	ApexPages.StandardController contrl = new ApexPages.StandardController(sobj);
    	BookingApp app = new BookingApp(contrl);
    	
		app.leadBaseInf.s.EntryDate__c = Date.today();
		app.leadBaseInf.s.EntryTime__c = '16:00';
		app.leadBaseInf.s.Nights__c = 3;
		app.leadBaseInf.s.DepartureDate__c = app.leadBaseInf.s.EntryDate__c.addDays(3);
		app.leadBaseInf.s.DepartureTime__c = '10:30';
        // 顧客情報を更新を行う
        app.refreshContcatInfo();

 		app.leadBaseInf.contactName = 'UNAME' + Crypto.getRandomLong();
 		app.leadBaseInf.l.Field2__c = '本社';
 		app.leadBaseInf.l.Segment__c = 'CARD';
        app.leadBaseInf.accoutName = 'ACC-NEW' + CommUtils.getRandom(10);
		app.leadBaseInf.s.contactRef__c = guest.Id;
		app.leadBaseInf.s.LeadName__c = 'テストケースの予約名';
		app.leadBaseInf.s.Comment__c = 'Comment_'+ CommUtils.getRandom(10);
		
		LeadItem subItem = app.oLeadLst[0];
		subItem.s.EntryDate__c = app.leadBaseInf.s.EntryDate__c;
		subItem.nights = '3';
		subItem.s.DepartureDate__c = app.leadBaseInf.s.DepartureDate__c;
		subItem.s.RoomTypeRef__c = typeOfRoom.Id;
		subItem.persons = String.valueOf(1);
		subItem.rooms = String.valueOf(2);
		
 		app.createLeadInfo();
		Test.stopTest();
System.assertNotEquals(app.leadBaseInf.leadNo, null, app.leadBaseInf.leadNo);
		app.leadBaseInf.s.LeadName__c = 'テストケースの予約名2';
		app.leadBaseInf.s.Payment__c = '現金';
		app.leadBaseInf.s.Comment__c = 'Comment2_'+ CommUtils.getRandom(10);
		
		subItem = app.oLeadLst[0];
		subItem.s.EntryDate__c = app.leadBaseInf.s.EntryDate__c;
		subItem.nights = '2';
		subItem.s.DepartureDate__c = subItem.s.EntryDate__c.addDays(2);
		subItem.s.RoomTypeRef__c = typeOfRoom.Id;
		subItem.persons = String.valueOf(2);
		subItem.rooms = String.valueOf(1);
		app.createLeadInfo();
		
		// 顧客様のリスト設定する
		app.indexSubId = subItem.s.Id;
		app.expandGuestLst();
		
		app.bulkCheckIn();
	}
	// 明細情報に関連付くの予約データは全部無効になると、該当明細情報は非表示する
	// キャンセルなど予約データから有効な予約データに変更すると、該当明細情報は再表示する
	@isTest(SeeAllData=false)
	static void testCase3() {
		// 予約データの明細情報を変更して、再登録する
    	Test.startTest();
    	Contact guest = TestCommon.createContact();
		TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
		
		// 新規登録
		LeadIndex__c sobj = new LeadIndex__c();
    	ApexPages.StandardController contrl = new ApexPages.StandardController(sobj);
    	BookingApp app = new BookingApp(contrl);
    	
		app.leadBaseInf.s.EntryDate__c = Date.today();
		app.leadBaseInf.s.EntryTime__c = '16:00';
		app.leadBaseInf.s.Nights__c = 1;
		app.leadBaseInf.s.DepartureDate__c = app.leadBaseInf.s.EntryDate__c.addDays(app.leadBaseInf.s.Nights__c.intValue());
		app.leadBaseInf.s.DepartureTime__c = '10:30';
        // 顧客情報を更新を行う
        app.refreshContcatInfo();

 		app.leadBaseInf.contactName = 'UNAME' + Crypto.getRandomLong();
 		app.leadBaseInf.l.Field2__c = '本社';
 		app.leadBaseInf.l.Segment__c = 'CARD';
        app.leadBaseInf.accoutName = 'ACC-NEW' + CommUtils.getRandom(10);
		app.leadBaseInf.s.contactRef__c = guest.Id;
		app.leadBaseInf.s.LeadName__c = 'テストケースの予約名';
		app.leadBaseInf.s.Comment__c = 'Comment_'+ CommUtils.getRandom(10);
		
		LeadItem subItem = app.oLeadLst[0];
		subItem.s.EntryDate__c = app.leadBaseInf.s.EntryDate__c;
		subItem.nights = String.valueOf(app.leadBaseInf.s.Nights__c);
		subItem.s.DepartureDate__c = app.leadBaseInf.s.DepartureDate__c;
		subItem.s.RoomTypeRef__c = typeOfRoom.Id;
		subItem.persons = String.valueOf(1);
		subItem.rooms = String.valueOf(1);
		// １件予約データを作成する
 		app.createLeadInfo();
		Test.stopTest();
		// 予約データをキャンセルすると、明細情報は非表示になる
		List<Lead__c> updLead = [select Id, LeadIndexRef__c, ReservedStatus__c from lead__c];
		System.assertEquals(updLead.size(), 1);
		updLead[0].ReservedStatus__c = CommConst.LEAD_ST_CANCEL;
		update updLead;
//System.debug(logginglevel.ERROR,'BBBBB:'+updLead);
		// 最新データを取得する
		app.refreshExistLeadInfo();
		// 明細情報第一番目を取得する
		subItem = app.oLeadLst[0];
//System.debug(logginglevel.ERROR,'AAAAA:'+app.leadBaseInf.leadNo);
		System.assertEquals(subItem.s.Id, null);
		
		// 予約回復する
		updLead[0].ReservedStatus__c = CommConst.LEAD_ST_CHECKED;
		update updLead;
		// 最新データを取得する
		app.refreshExistLeadInfo();
		// 明細情報第一番目を取得する
		subItem = app.oLeadLst[0];
//System.debug(logginglevel.ERROR,'AAAAA:'+app.leadBaseInf.leadNo);
		System.assertNotEquals(subItem.s.Id, null);
//System.debug(logginglevel.ERROR,'guest:'+guest);
		// お客様情報を新規作成
		Contact newGuest = TestCommon.createContact();
		newGuest = [select id, name from contact where id = :newGuest.Id];
		app.leadBaseInf.s.contactRef__c = newGuest.Id;
		app.leadBaseInf.contactName = newGuest.Name;
		app.refreshContcatInfo();
		app.createLeadInfo();
		updLead = [select Id, Relcontact__c from lead__c limit 1];
		System.assertEquals(updLead[0].Relcontact__c, newGuest.id, newGuest);
	}

	@isTest(SeeAllData=false)
	static void testCase4() {
		// 予約データの明細情報を変更して、再登録する
    	Test.startTest();
    	Contact guest = TestCommon.createContact();
    	String guestName = guest.LastName + ' ' + guest.FirstName;
		TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
		// 新規登録
		LeadIndex__c sobj = new LeadIndex__c();
    	ApexPages.StandardController contrl = new ApexPages.StandardController(sobj);
    	BookingApp app = new BookingApp(contrl);
    	BookingApp.ContactInfo contactInf = BookingApp.refreshContcatInfo(guest.Id, guestName);
    	System.assertEquals(contactInf.KanjiName, CommUtils.nullToBlank(guest.Name1__c), contactInf);
    	System.assertEquals(contactInf.KanaName, CommUtils.nullToBlank(guest.KanaName1__c), contactInf);
    	System.assertEquals(contactInf.KatakanaName, CommUtils.nullToBlank(guest.Katakana__c), contactInf);
    	System.assertEquals(contactInf.phone, CommUtils.nullToBlank(guest.Phone), contactInf);
    	//System.assertEquals(contactInf.accountName, CommUtils.nullToBlank(guest.Account.Name), contactInf);
    	System.assertEquals(contactInf.ApplicantName, CommUtils.nullToBlank(guest.ApplicantName__c), contactInf);
    	System.assertEquals(contactInf.ApplicantPhone, CommUtils.nullToBlank(guest.ApplicantPhone__c), contactInf);
    	System.assertEquals(contactInf.Memo1, CommUtils.nullToBlank(guest.Memo1__c), contactInf);
    	System.assertEquals(contactInf.Memo2, CommUtils.nullToBlank(guest.Memo2__c), contactInf);
    	System.assertEquals(contactInf.Memo3, CommUtils.nullToBlank(guest.Memo3__c), contactInf);
	}
*/
}