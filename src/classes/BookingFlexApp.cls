/**********************
* 予約システム
* １画面に予約データ登録、修正を行う
* 2015/11/02 故障部屋アサイン対象外ロジック追加
* 2016/04/06 ご予約情報はキャンセルから復活すると、予約インデックスSUBは修正不可から修正可能変更対応
* 2016/08/18 ネット取り込みから予約情報に対して、小部屋の特記事項をなしに対応する
* 2016/11/10 最近参照した予約インデックス情報一覧を取得する
***********************/
public with sharing class BookingFlexApp {

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
	// 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
    public Integer gStaysNums{get;private set;}
    // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
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
    public static String getTaxNumberFormat() { 
    	return  CommUtils.getTaxNumberFormat();
    }
    public String getCurrencySybmol() {
    	return CommBaseCtrl.getCurrencySybmol();
    }
    private static Set<String> leadIdxFieldsSet;
    // 会計種別：プラン
	public String ACTTYPE_PLAN{get{return CommConst.PROD_ACTION_TYPE_PL;}}	// プラン
	public String ACTTYPE_PAY{get{return CommConst.PROD_ACTION_TYPE_PY;}}	// 支払
	public String ACTTYPE_AR {get{return CommConst.PROD_ACTION_TYPE_AR;}}	// 前受金
	// 支払種別
	public String ACTTYPE_PAY_DIS_RATE{get{return CommConst.PROD_PAY_TYPE_DIS_RATE;}}	// 割引
	public String ACTTYPE_PAY_DIS_PRICE{get{return CommConst.PROD_PAY_TYPE_DIS_PRICE;}}	// 値引
	public String ACTTYPE_PAY_ADD_RATE{get{return CommConst.PROD_PAY_TYPE_ADD_RATE;}}	// 割増
	// 返金キー情報格納用
	public String refundItemString{get{return JSON.serialize(BillSimpleHelp.getRefundItemStr());}}
	public Map<String,String> cookieMsg{get;private set;}
	//　多店舗コード
	public String branchNm{get;private set;}
	// 2017/12/25 親部屋機能処理　by　zy BEGIN
	//public boolean isOyaInputFlag{get;set;}
	// 2017/12/25 親部屋機能処理　by　zy END
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
    // 新規予約コピー元（初期値をなくなる問題回避ため）情報を格納する
    private Lead__c cloneNewLead;
    // 2017/01/09 予約タイプの全部予約変更　by zy BEGIN
    private boolean hadReservedTypeFlag;
    // 2017/01/09 予約タイプの全部予約変更　by zy END
    // 2017/03/14 一括キャンセル機能の対応　by　zy BEGIN
    private boolean hadReservedStatusFlag;
    // 2017/03/14 一括キャンセル機能の対応　by　zy END
    // 2017/01/09 行追加　by zy BEGIN
    public Integer defInputLines{get{
    	return CommUtils.nullToIntZero(CommConst.APPOTION_DETAIL_DEF_INPUTLINES) == 0 
    													? 5 
    									: CommUtils.nullToIntZero(CommConst.APPOTION_DETAIL_DEF_INPUTLINES);
    }}
    // 2017/01/09 行追加　by zy END
    // 2017/01/12 日帰りの日帰デフォルト滞在時間数 by zy BEGIN
    public Integer defStayHours{get{return CommConst.DEF_DAYUSE_STAY_HOURS; }}
    // 2017/01/12 日帰りの日帰デフォルト滞在時間数 by zy END
	// クラスインスタンス化
    public BookingFlexApp(ApexPages.StandardController controller) {
    	// Ctrl Set
        ctrl = controller;
        // 2017/01/09 予約タイプの全部予約変更　by zy BEGIN
        hadReservedTypeFlag = false;
        // 2017/01/09 予約タイプの全部予約変更　by zy END
        // 2017/03/14 一括キャンセル機能の対応　by　zy BEGIN
        hadReservedStatusFlag = false;
        // 2017/03/14 一括キャンセル機能の対応　by　zy END
		// 2019/11/15 一括予約画面での項目編集を親部屋以外にも反映してほしい by zy BEGIN
		saveSubIndxFlg = false;
		// 2019/11/15 一括予約画面での項目編集を親部屋以外にも反映してほしい by zy END
		// 宿泊レコードタイプIDを取得する
		bookRecTypeId = CommLogicProcess.getLeadBookingRecType();
		cloneNewLead = (Lead__c)Lead__c.sObjectType.newSObject(bookRecTypeId, true);
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
	    //2016/12/27 CTI contactid 対応　by　ZY　BEGIN
	    Contact c = new Contact();
		String contactId = Apexpages.currentpage().getparameters().get('contactid');
		if(!CommUtils.isBlank(contactId)){
			Apexpages.currentpage().getparameters().remove('contactid');
			String querySQL =  CommSqlUtils.generateQueryString('Contact',new string[]{'Account.Name'});
			querySQL += ' where id =: contactId';
        	List<Contact> contList = Database.query(querySQL);
        	//[select id, name, ,AccountId, LastName , FirstName, Name1__c,KanaName1__c, Katakana__c, Phone, ApplicantName__c,ApplicantPhone__c, Memo1__c,Memo2__c, Memo3__c from Contact where id =: contactId];
        	if(contList!= null && contList.size() >0){
        		c = contList.get(0);
        	}
        	contactName = c.name;
        	//newLead.Relcontact__r = c;
        }
	    // 初期化設定を行う
	    //initFormValue();
		initFormValue(c);
		//2016/12/27 CTI contactid 対応　by　ZY　END
        // 部屋タイプ
        setRoomTypeLst();
        //レイアウト変更機能初期化
        initLayoutDocument();
        // 支払方法リスト初期化する
        paymentTypeLst = new List<Selectoption>();
        Schema.DescribeFieldResult fieldResult = Lead__c.Field315__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple) {
            paymentTypeLst.add(new SelectOption(f.getValue(),f.getLabel()));
        }
        //2016/12/27 CTI contactid 対応　by　ZY　BEGIN
        /*
		newLead = new Lead__c(ReservedDate__c=system.now());//RecordTypeId = bookRecTypeId
		*/
		//2016/12/27 CTI contactid 対応　by　ZY　END
		oldLead = new Lead__c();
		//2016/12/27 CTI contactid 対応　by　ZY　BEGIN
		/*
		 // チェックイン時刻、チェックアウト時刻
        newLead.Field4__c = CommConst.DEF_CHECKIN_TIME;
        newLead.Field3__c = CommConst.DEF_CHECKOT_TIME;
        // 予約レコードタイプを設定する
        newLead.RecordTypeId = CommLogicProcess.getLeadBookingRecType();
        */
        //2016/12/27 CTI contactid 対応　by　ZY　END
        //2017/01/18 予約インデックス項目レーアウト作成する　by zy BEGIN
        //getSection();
        //2017/01/18 予約インデックス項目レーアウト作成する　by zy END
        String leadId = Apexpages.currentpage().getparameters().get('leadId');
        if (!CommUtils.isBlank(leadId)){
        	// 予約親と予約明細両方共対応する
        	List<Lead__c> leadLst = [select id, name, LeadIndexRef__c, LeadIndexRef__r.Name from Lead__c where id = :leadId];
        	if(!leadLst.isEmpty()){
        		searchLabel = leadLst[0].LeadIndexRef__r.Name;
	    		searchLeadIdxId = leadLst[0].LeadIndexRef__c;
	    		queryExistLeadByLeadIndexId();
        	}
        }else  if (ctrl.getId() != null){
        	// 予約親と予約明細両方共対応する
        	List<LeadIndex__c> leadIndexLst = [select id, name, ParentLeadIndxRef__c, ParentLeadIndxRef__r.Name from LeadIndex__c where id = :ctrl.getId()];
        	//予約インデックス情報を見つかりません。
        	if (leadIndexLst.isEmpty()) throw new CommException(Label.MSG_001_0066);
        	if (leadIndexLst[0].ParentLeadIndxRef__c != null){ 
        		leadBaseInf.leadNo = leadIndexLst[0].ParentLeadIndxRef__r.Name;
        		searchLabel = leadIndexLst[0].ParentLeadIndxRef__r.Name;
	    		searchLeadIdxId = leadIndexLst[0].ParentLeadIndxRef__c;
        	} else {
        		leadBaseInf.leadNo = leadIndexLst[0].Name;
        		searchLabel = leadBaseInf.leadNo;
	    		searchLeadIdxId = leadIndexLst[0].id;
        	}
        	
	    	queryExistLeadByLeadIndexId();
        	//this.refreshExistLeadInfo();
        }
        
        //2017/01/18 予約インデックス項目レーアウト作成する　by zy BEGIN
        getSection(curLayoutId);
        //関連の予約情報を取得する
		refreshWinLead();
		// section自动展开
		sectionExpandProcess();
        //2017/01/18 予約インデックス項目レーアウト作成する　by zy END
        String cookieNamePrix = '_BookingFlexApp_cookie_';
        cookieMsg = new Map<String,String>();
        for(String cookieNm : new List<String>{'roomIndicatorPageframe','timeTablePageframe','yadotyouPageframe','chatPage','mapPageframe','recentRefFrame','estframe'}){
        	Cookie messageCoo = ApexPages.currentPage().getCookies().get(cookieNamePrix + cookieNm + '_message');
        	if(messageCoo != null){
				String message = messageCoo.getValue();
				cookieMsg.put(cookieNm,message);
        	} else
        		cookieMsg.put(cookieNm,'');
        	
        }
        // 2017/04/06 source整理 by zy BEGIN
        //editOrNewFlag = false;
        // 2017/04/06 source整理 by zy END
        cloneFlag = false;
        loadRecentRefLeadIndex();
        //2017/04/25 项目优化 by zy BEGIN
        isChgConFlag = false;
        //2017/04/25 项目优化 by zy END
    }
    /* 2017/01/18 方法废弃 by zy
	public void init(){
		
        searchLabel = null;
        loadRecentRefLeadIndex();
        contactName = null;
        // 予約レコードタイプを設定する
        initFormValue();
	}
	*/
	// 2016/12/30 親SUBのフラグ追加　by　zy  BEGIN
	private String parentSubId;
	// 2016/12/30 親SUBのフラグ追加　by　zy  END
	public PageReference redirectInit(){
		//Id leadIndexId = leadBaseInf.s.Id;
		
		// ページ遷移前のチェックを行う
        Map<String,String> paramMap = new Map<String,String>();
        //paramMap.put('id',leadIndexId);
        //paramMap.put('retURL','/apex/BookingFlexApp?id=' + leadBaseInf.s.Id);
		PageReference customPage = new PageReference(  '/apex/BookingFlexApp');
		customPage.getParameters().putAll(paramMap);
		customPage.setRedirect(true);

		return customPage;
	}
	// レイアウト By zy BEGIN
	public List<Selectoption> layoutLst{get;set;}
	public String curLayoutId{get;set;}
	// ユーザデフォルトのレイアウトNO
	private String userDefLayoutNo;
	/**
	* レイアウト変更機能初期化
	*/
	private void initLayoutDocument(){

		// ユーザに定義しているレイアウトNO情報を設定する
		String userLayouts = CommUtils.nullToBlank(UserUtil.CurrentUser.BookingFlexAppLayoutNo__c);
		Set<String> userLayoutSet = new Set<String>();
		String mainLayout = ':';
		curLayoutId = '';
		if (!CommUtils.isBlank(userLayouts)) {
			for (String layoutCode : userLayouts.split(',')) {
				// デフォルトレイアウトNo存在チェック
				if(layoutCode.contains(mainLayout)) {
					layoutCode = layoutCode.subStringBefore(mainLayout);
					curLayoutId = layoutCode;
				} else if (CommUtils.isBlank(curLayoutId)) {// 初期値未設定の場合、一番目の設定コードはデフォルトコードで設定
					curLayoutId = layoutCode;
				}
				userLayoutSet.add(layoutCode);
			}
			// ユーザのデフォルトNOを設定する
			userDefLayoutNo = curLayoutId;
		}
		String defNamePrix = 'BookingFlexAppLayoutDefine';
		// 複数レイアウト定義情報を取得する
    	List<Dom.XmlNode> layoutRoots = CommXmlUtils.getAllTopXmlNode(defNamePrix);
    	// Layoutタグのレイアウト定義が存在する・しない判断を行う
		boolean newVersionFLag = false;
		// レイアウトのリスト初期化する
		//system.debug(logginglevel.info,'userLayoutSet:::' + userLayoutSet);
        layoutLst = new List<Selectoption>();
        SelectOption defaultLayout = null;
		for (Dom.XmlNode node : layoutRoots) {
			String nodeName = node.getName();
//system.debug(logginglevel.info,'nodeName:::' + nodeName);
			if (nodeName == 'LAYOUT') {
				newVersionFLag = true;
				Dom.XmlNode layoutNode = node.getChildElement('LAYOUTLABEL',null);
				Dom.XmlNode codeNode = node.getChildElement('LAYOUTCODE',null);
				String layoutLabel = layoutNode.getText();
				String layoutCode = codeNode.getText();
				//2017/01/12 layout 空 not empty by zy BEGIN
				if(userLayoutSet.contains(layoutCode) || userLayoutSet.isEmpty()){
				//2017/01/12 layout 空 not empty by zy END
					layoutLst.add(new SelectOption(layoutCode,layoutLabel));
				}
				if (defaultLayout == null) {
					defaultLayout = new SelectOption(layoutCode,layoutLabel);
				}
			}
		}
		//　指定のレイアウトコードはユーザのレイアウト定義範囲外の場合、一番目のレイアウトを表示する
		if (defaultLayout != null && layoutLst.isEmpty()) {
			layoutLst.add(defaultLayout);
			curLayoutId = defaultLayout.getValue();
		}
		// デフォルトのレイアウトをなかった場合、一番目のレイアウトを表示する
		if (CommUtils.isBlank(curLayoutId) && !layoutLst.isEmpty()) {
			curLayoutId = layoutLst[0].getValue();
		}
	}
	// レイアウト By zy END
	/**
	* コピー機能、情報表示処理
	* 画面の基本情報から、明細セクションを再取得、表示を行う
	**/
	public void preCopyAction() {
		// 明細セクション情報を取得、その場合、明細のIDをクリアして、予約インデックスIDもクリアする
		refreshExistLeadInfo();
		Set<Id> bookingId = new Set<Id>();
		List<BookingRow> rowLst = new List<BookingRow>();
		// 2019/11/15 一括予約のコピー時にアサインされている部屋もコピーしてほしい、アサイン部屋もコピーしないと手間が増えてしまいます。by zy BEGIN
		Map<String,List<RequestInfo>> roomIdLstMap = new Map<String,List<RequestInfo>>();
		if (cloneRoomExitModeFlg) {
			Id baseIdxId = leadBaseInf.s.Id;
			Map<String,LeadItem> subMap = new Map<String,LeadItem>();
			for (LeadItem item : oLeadLst) {
				subMap.put(item.orgSobj.id,item);
			}
			Set<String> groupKeySet = new Set<String>();
			for (Lead__c lead : [select id,rroom__c,rroom__r.name,LeadIndexSubId__c,LeadIndexRef__c,RoomGroupNo__c,Field276__c,refTypeOfRooms__r.name from lead__c where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG and LeadIndexSubId__c= :subMap.keySet()  and LeadIndexRef__c = :baseIdxId order by LeadIndexSubId__c, RoomGroupNo__c, EntryTime__c]) {
				String key = lead.LeadIndexRef__c + '_' + lead.LeadIndexSubId__c + '_' + lead.RoomGroupNo__c;
				if (groupKeySet.contains(key)) continue;
				groupKeySet.add(key);
				if (!roomIdLstMap.containskEy(lead.LeadIndexSubId__c)) roomIdLstMap.put(lead.LeadIndexSubId__c,new List<RequestInfo>());
				RequestInfo info = new RequestInfo();
				LeadItem item = subMap.get(lead.LeadIndexSubId__c);
				info.id = lead.rroom__c;
				info.nm = lead.rroom__r.name;
				// 2019/11/15 一括予約画面の部屋直接選択 by zy BEGIN
				if (Commconst.BOOKING_FLEX_SEL_ROOM_FLG && !CommUtils.isBlank(lead.refTypeOfRooms__r.name)) {
					info.nm += '(' + lead.refTypeOfRooms__r.name + ')';
					info.lock = false;
				} else
				// 2019/11/15 一括予約画面の部屋直接選択 by zy END
				info.lock = lead.Field276__c;
				info.styp = 'lead';
				roomIdLstMap.get(lead.LeadIndexSubId__c).add(info);
			}
		}
		// 2019/11/15 一括予約のコピー時にアサインされている部屋もコピーしてほしい、アサイン部屋もコピーしないと手間が増えてしまいます。by zy END
		for (LeadItem item : oLeadLst) {
			// 2019/11/15 一括予約のコピー時にアサインされている部屋もコピーしてほしい、アサイン部屋もコピーしないと手間が増えてしまいます。by zy BEGIN
			String orgSubId = item.orgSobj.id;
			// 2019/11/15 一括予約のコピー時にアサインされている部屋もコピーしてほしい、アサイン部屋もコピーしないと手間が増えてしまいます。by zy END
			item.orgSobj.id = null;
			item.isReadOnly = false;
			if(!item.bookingLst.isEmpty()){
				for (BookingDetail detail : item.bookingLst) {
					for ( BookingRow row : detail.bRows) {
						row.b.id = null;
					}
				}
			}
			// 2019/11/15 一括予約のコピー時にアサインされている部屋もコピーしてほしい、アサイン部屋もコピーしないと手間が増えてしまいます。by zy BEGIN
			if (roomIdLstMap.containskey(orgSubId)) {
				List<RequestInfo> infos = roomIdLstMap.get(orgSubId);
				if (CommUtils.isBlank(item.roomInfoJson)) item.roomInfoJson = JSON.serialize(infos);
			}
			// 2019/11/15 一括予約のコピー時にアサインされている部屋もコピーしてほしい、アサイン部屋もコピーしないと手間が増えてしまいます。by zy END
			// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy BEGIN
			// コピーの場合ロック解除
			item.isLockFlag = false;
			// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy END
		}
		
		leadbaseinf.l = newLead;
		isEditPage=false;
		newLead.name = leadbaseinf.s.LeadName__c;
		newLead.Field298__c = null;
		cloneFlag = true;
		// 画面セクションは全部展開を行う　
		sectionExpandProcess();
	}
	//2016/12/27 CTI contactid 対応　by　ZY　BEGIN
	private void initFormValue(){
		initFormValue(new Contact()); 
	}
	//2016/12/27 CTI contactid 対応　by　ZY　END
    /**
    *　画面設定情報のクリア設定
    **/
    //2016/12/27 CTI contactid 対応　by　ZY　BEGIN
	/*
	private void initFormValue() {
		Contact c = new Contact();
		String contactId = Apexpages.currentpage().getparameters().get('contactid');
		
		if(!CommUtils.isBlank(contactId)){
        	List<Contact> contList = [select id, name, Account.Name,AccountId, LastName , FirstName, Name1__c,KanaName1__c, Katakana__c, Phone, ApplicantName__c,ApplicantPhone__c, Memo1__c,Memo2__c, Memo3__c from Contact where id =: contactId];
        	if(contList!= null && contList.size() >0){
        		c = contList.get(0);
        	}
        }
        newLead = new Lead__c(RecordTypeId = bookRecTypeId,ReservedDate__c = System.now());
	*/
	//2016/12/27 CTI contactid 対応　by　ZY　END
	private void initFormValue(Contact c) {
		//2016/12/27 CTI contactid 対応　by　ZY　BEGIN
		newLead = new Lead__c(RecordTypeId = bookRecTypeId,ReservedDate__c = System.now());
		// 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
		// チェックイン時刻、チェックアウト時刻
        //newLead.Field4__c = CommConst.DEF_CHECKIN_TIME;
        //newLead.Field3__c = CommConst.DEF_CHECKOT_TIME;
        newLead.Field4__c = JS_DEFCHKIN_DT;
        newLead.Field3__c = JS_DEFCHKOT_DT;
		// 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
        newContact = c;
        if (newContact.id != null) cloneNewLead.name = newContact.name;
        //2016/12/27 CTI contactid 対応　by　ZY　END
        // 予約初期化
        leadBaseInf = new LeadBaseInfo(new LeadIndex__c(LeadName__c = (c.Name!=null) ?c.Name : ''),
        	newLead,
        	c);
        // 明細情報の初期化する
        setLeadSubLst(null);
        // 宿泊者名簿
        //oGuestLst = new List<ContactItem>();
        // プラン初期情報設定
        //oPlanInfo = new PlanInfoItem();
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
	**//*
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
	}*/
	public boolean saveFlag{get;set;}
	// 2017/04/06 source整理 by zy BEGIN
	//public boolean leadUpdFlag{get;set;}
	// 2017/04/06 source整理 by zy END
	public boolean cloneFlag{get;set;}
	// 2017/04/06 source整理 by zy BEGIN
	//public boolean editOrNewFlag{get;set;}
	// 2017/04/06 source整理 by zy END
	/*
	* コピー機能　予約登録ポタン対応
	*/
	public void cloneLeadAction(){
		cloneFlag = true;
		leadBaseInf.s.id=null;
		newLead.id=null;
		
		for (LeadItem item : oLeadLst) {
			Item.s.id = null;
		}
		// 予約情報登録処理
		createLeadInfo();
	}
	
	// SUBINDEX単位の見積明細更新、新規、キャンセル
	private Map<Id,Map<Date,List<BookingEstimateItem__c>>> getUiInputEstItemsBySubIndexMap(List<LeadIndex__c> subInxLst) {
		// JSONの情報を更新情報へ変換
		List<Map<Date,List<BookingEstimateItem__c>>> subDateBookingLst = new List<Map<Date,List<BookingEstimateItem__c>>>();
		///if(!CommUtils.isBlank(detailMessage)){
			//subDateBookingLst = getDetailMap(detailMessage);
		//}
//system.debug(logginglevel.info,'subDateBookingLst:::' + subDateBookingLst);
		// 画面に登録の明細の関連の見積明細情報
		Map<Id,Map<Date,List<BookingEstimateItem__c>>> subIdxBookingMap = new Map<Id,Map<Date,List<BookingEstimateItem__c>>>();
		for (integer i = 0; i < subInxLst.size() ; i++){
			LeadIndex__c leadIndex = subInxLst[i];
			if ( i < subDateBookingLst.size() && leadIndex.id != null)
				subIdxBookingMap.put(leadIndex.id,subDateBookingLst[i]);
		}
		return subIdxBookingMap;
	}
	/*
	public void updBookingItem(List<LeadIndex__c> subInxLst, Map<Id,Map<Date,List<BookingEstimateItem__c>>> subIdxBookingMap){
		Set<Id> subIdSet = new Set<Id>();
		for (LeadIndex__c subIdx : subInxLst) {
			subIdSet.add(subIdx.Id);
		}
		Id baseIdxId = leadBaseInf.s.Id;
		// 既存の予約情報を取得する
		Map<Id,List<Lead__c>> subLeadMap = new Map<Id,List<Lead__c>>();
		for (Lead__c l : [select id,EntryTime__c,LeadIndexSubId__c from Lead__c where LeadIndexSubId__c = :subIdSet and LeadIndexRef__c = :baseIdxId order by LeadIndexSubId__c, RoomGroupNo__c, EntryTime__c]) {
			if(!subLeadMap.containsKey(l.LeadIndexSubId__c)) subLeadMap.put(l.LeadIndexSubId__c,new List<Lead__c>());
			subLeadMap.get(l.LeadIndexSubId__c).add(l);
		}
system.debug(logginglevel.info,'subLeadMap::' + subLeadMap);
		Map<Id,List<BookingEstimateItem__c>> updItemsMap = new Map<Id,List<BookingEstimateItem__c>>();
		Set<Id> hadRowSet = new Set<Id>();
		List<BookingEstimateItem__c> bookingEstLst = new List<BookingEstimateItem__c>();
		List<Id> exitLst = new List<Id>();
		List<BookingEstimateItem__c> updItems = new List<BookingEstimateItem__c>();
		map<Id,Id> leadIdMap = new Map<Id,Id>();
		for (LeadIndex__c sub : subInxLst) {

			if(subLeadMap.containsKey(sub.id) && subIdxBookingMap.containsKey(sub.id)){
				List<Lead__c> orgLeadLst = subLeadMap.get(sub.id); 
				Map<Date,List<BookingEstimateItem__c>> dateToBookingMap = subIdxBookingMap.get(sub.id);
system.debug(logginglevel.info,'dateToBookingMap::' + dateToBookingMap);
				for (lead__c l : orgLeadLst){ 
					//leadUpdFlag 有更改的则需要修改lead
					if(dateToBookingMap.containsKey(l.EntryTime__c.date())){
						//集めと分割
						for (BookingEstimateItem__c b : dateToBookingMap.get(l.EntryTime__c.date())) {
							// 合計金額は全部NULLに設定して、トリガーに最自動計算を行う
        					b.SpTotal__c = null;
							if(b.id == null) b.refBooking__c = l.id;
							else if(cloneFlag) {
								exitLst.add(b.id);
							}
							updItems.add(b);
						}
						//1房间
						dateToBookingMap.remove(l.EntryTime__c.date());
					}
				}
			}
		}
	}
	*/
	/*
	* チェック予約項目のレーアウトのセクションの展開判定
	*/
	private void sectionExpandProcess(){
		// 2017/01/19 全てセクションを自動展開フラグ[新規、コピーの場合、全てセクションを展開]
		Boolean allSectionExpandFlg = CommUtils.isBlank(leadbaseinf.s.id) || cloneFlag;
		Col titleCol = new Col();
		// 取得小写信息
		Map<String, Schema.DescribeFieldResult> modelDeafaultValuesMap = CommSqlUtils.getAllFieldLst(Lead__c.sObjectType,false,true);
		// ページは複数の縦のセクション情報設定
		for (MessageTbl tbl : tblLst) {
			List<Integer> arrLst = new List<Integer>();
			integer idx = 0;
			List<List<Section>> sectionGroup = new List<List<Section>>(); 
			//List<boolean> explanFlagLst = new List<Boolean>();
			// セクション展開判断フラグ:TRUE→セクション展開しない、FALSE：セクション展開する
			//boolean noExplanFlag = true;
			// 該当縦の各セクションの情報を設定する
			for (Section sec : tbl.secLst) {
				// セクション展開判断フラグ:TRUE→セクション展開しない、FALSE：セクション展開する(デフォルト値：非展開)
				sec.explanFlag = true;
//System.debug(loggingLevel.info, 'sec.titel=['+sec.title+']');
				// 2017/01/19 全てセクションを自動展開フラグ BEGIN
				if (allSectionExpandFlg || sec.alwaysExplanFlg) {
					// 該当セクションは展開フラグに設定する
					sec.explanFlag = false;
					continue;
				}
//System.debug(loggingLevel.info, 'sec.explanFlag[1]=['+sec.explanFlag+']');
				// 2017/01/19 全てセクションを自動展開フラグ END
				//if(noExplanFlag) {
				// 該当セクションの各行の項目設定内容をチェックする
				for (Col col : sec.colLst){
					// 該当行に設定の項目リストは設定内容をチェックする
					for (BookingField b : col.fieldLst) {
						String fieldName = b.fieldName.toLowerCase();
						if (!CommUtils.isBlank(fieldName) && fieldName != '$_blank_$'){
							if (b.isContactFlag){
								if(newContact.get(fieldName) != null && newContact.get(fieldName) != false){
									// 該当セクションを展開する	
									sec.explanFlag = false;
									break;
								}
							}else if (newLead.get(fieldName) != null && modelDeafaultValuesMap.containsKey(fieldName)){
								//oldLead.get(fieldName) != newLead.get(fieldName) && 
								Schema.DescribeFieldResult dr = modelDeafaultValuesMap.get(fieldName);	
								if (dr.getType() == DisplayType.Boolean && newLead.get(dr.getName()) == false) continue;
								// 該当セクションを展開する	
								sec.explanFlag = false;
								break;
							}
						}
					}
					// 該当展開の場合、処理なし
					if (!sec.explanFlag) break;
				}
//System.debug(loggingLevel.info, 'sec.explanFlag[2]=['+sec.explanFlag+']');
				if(CommUtils.isBlank(sec.title)){ 
					if (sectionGroup.size() > 0) {
						sectionGroup[sectionGroup.size()-1].add(sec);
					}
				}else {
					sectionGroup.add(new List<Section>());
					sectionGroup[sectionGroup.size()-1].add(sec);
				}
			}
			// TITLEありのセクションの展開する、しないコントロール
			//for (integer i = 0 ; i < sectionGroup.size() ; i++){
			for (List<Section> locSecList : sectionGroup) {
				// デフォルト展開なし
				Boolean isAllExpandFlg = false;
				for (Section sec : locSecList) {
					// 該当セクションを展開する場合
					if (!sec.explanFlag) {
						isAllExpandFlg = true;
						break;
					}
				}
				if (isAllExpandFlg) {
					for (Section sec : locSecList) {
						// 該当列のセクションは全部展開に設定を行う
						sec.explanFlag = !isAllExpandFlg;
					}
				}
			}	
		}
	}
	//2016/12/29 予約カスタム項目差異　by　zy　BEGIN
	private Lead__c difLead;
	private boolean checkDifLead(){
		difLead = new Lead__c();
		// 2017/12/25 親部屋子部屋更新項目カスタム設定　by　zy BEGIN
		diffFieldSet = new Set<String>();
		// 2017/12/25 親部屋子部屋更新項目カスタム設定　by　zy END
		//既存LOGIC排除する
		set<String> excludeSet = new Set<String>{'relcontact__c','name','field315__c','field2__c','segment__c','rroom__c'};
		boolean checkFlag = false;
		Map<String, Schema.DescribeFieldResult> modelDeafaultValuesMap = CommSqlUtils.getAllFieldLst(Lead__c.sObjectType,false,true);
		for (String fieldName : leadCustomFieldLst){
			fieldName = fieldName.deleteWhiteSpace();
			if(excludeSet.contains(fieldName.toLowerCase())) continue;
			// 不可变更字段不处理
			if(!modelDeafaultValuesMap.containsKey(fieldName.toLowerCase())) continue;
			Schema.DescribeFieldResult dr = modelDeafaultValuesMap.get(fieldName.toLowerCase());
			if (!dr.isUpdateable()) continue;
			if(oldLead.get(fieldName) != newLead.get(fieldName)){
				difLead.put(fieldName,newLead.get(fieldName));
				// 2017/12/25 親部屋子部屋更新項目カスタム設定　by　zy BEGIN
				if (checkSet.contains(fieldName.toLowerCase())) diffFieldSet.add(fieldName);
				// 2017/12/25 親部屋子部屋更新項目カスタム設定　by　zy END
				checkFlag = true;
			}
		}
		return checkFlag;
	}
	//2016/12/29 予約カスタム項目差異　by　zy　END
	/*
	private List<Map<Date,List<BookingEstimateItem__c>>> getDetailMap(String message){
		List<Map<Date,List<BookingEstimateItem__c>>> bLst = new List<Map<Date,List<BookingEstimateItem__c>>>();
		system.debug(logginglevel.info,'message:::' + message);
		String[] leadArr = message.split('¥n');
		system.debug(logginglevel.info,'leadArr:::' + leadArr);
		//leadindex
		for (String leadMessage : leadArr) {
			Map<Date,List<BookingEstimateItem__c>> detailMap = new Map<Date,List<BookingEstimateItem__c>>();
			if(!CommUtils.isBlank(leadMessage)){
				String[] leadLst = leadMessage.split('\\|');
				system.debug(logginglevel.info,'leadLst:::' + leadLst);
				//subleadindex
				for (integer i = 0 ; i < leadLst.size() ; i++) {
					String rowMessage = leadLst[i];
					String[] dtLst = rowMessage.split('#');
					system.debug(logginglevel.info,'dtLst:::' + dtLst);
					String headIdx = dtLst[0];
					//date
					for(integer j = 1 ; j < dtLst.size() ; j++){
						String dateMessage = dtLst[j];
						String[] detailMessage = dateMessage.split('_');
						String dtStr = detailMessage[0];
						Date dt = CommUtils.stringToDate(dtStr);
						//bookingItem
						List<BookingEstimateItem__c> itemLst = new List<BookingEstimateItem__c>();
						for(integer dtIdx = 1 ; dtIdx < detailMessage.size() ; dtIdx++) {
							String bookingItemDetal = detailMessage[dtIdx];
							String[] bookingItemMesage = bookingItemDetal.split('\\$');
							system.debug(logginglevel.info,'bookingItemMesage:::' + bookingItemMesage);
							if(bookingItemMesage.size() > 2){
								BookingEstimateItem__c  b = new BookingEstimateItem__c(
					               	refAccountMaster__c = bookingItemMesage[0],
					               	UnitPrice__c = CommUtils.nullToIntZero(bookingItemMesage[1]),
					               	Amount__c = CommUtils.nullToZero(bookingItemMesage[2]) );
					            if(bookingItemMesage.size() > 3 && !CommUtils.isBlank(bookingItemMesage[3])){
					            	b.PlanDetailSyncInfo__c = bookingItemMesage[3];
					            }
					            if(bookingItemMesage.size() > 4 &&!CommUtils.isBlank(bookingItemMesage[4]) && bookingItemMesage[4] != null && !cloneFlag) {
					            	b.id = bookingItemMesage[4];
					            }
								itemLst.add(b);
							}
						}
						detailMap.put(dt,itemLst);
						system.debug(logginglevel.info,'detailMap:::' + detailMap);
					}
				}
			}
			bLst.add(detailMap);
		}
		system.debug(logginglevel.info,'bLst:::' + bLst);
		return bLst;
	}*/
	/**
	* 顧客情報最新取得を行う
	**/
	// SOQL顧客情報項目定義
	@remoteAction
	// 2019/04/30 一括予約画面、新規予約画面と一括予約画面のカスタマイズ上でお客様に紐づく取引先の項目 by zy BEGIN
	public static object refreshContcatInfo(String contactId, String contactName,String fieldString) {
	// 2019/04/30 一括予約画面、新規予約画面と一括予約画面のカスタマイズ上でお客様に紐づく取引先の項目 by zy END
		Contact contact = new Contact();
		if (CommUtils.isBlank(fieldString)) return contact;
		// 2019/04/30 一括予約画面、新規予約画面と一括予約画面のカスタマイズ上でお客様に紐づく取引先の項目 by zy BEGIN
		// お客様全部字段集合
		map<String, Schema.DescribeFieldResult> modelContactDeafaultValuesMap = CommSqlUtils.getAllFieldLst(schema.Contact.sObjectType,true,true);
		// 参照対象集合
		Map<String,String> fieldMap = new Map<String,String>();
		// 字段フィルター
		for (String fieldName : fieldString.split(',')) {
			// 字段名小文字変更
			String lowerField = fieldName.toLowerCase();
			// 字段あり
			if (modelContactDeafaultValuesMap.containsKey(lowerField)) {
				// 字段情報取得
				Schema.DescribeFieldResult dr = modelContactDeafaultValuesMap.get(lowerField);
				// カスタム設定字段　参照タイプ
				if (dr.getType() == DisplayType.REFERENCE) {
					// 参照名
					String refranceNm = dr.getRelationshipName();
					// 参照の表示名
					String refFieldName = refranceNm + '.' + 'name';
					// カスタム設定字段集合追加
					fieldMap.put(refranceNm,refFieldName);
				}
			}
		}
		if (!fieldMap.isEmpty()) fieldString += String.join(fieldMap.values(), ',');
		// 2019/04/30 一括予約画面、新規予約画面と一括予約画面のカスタマイズ上でお客様に紐づく取引先の項目 by zy END
		String query = 'select ' + fieldString;
		query = query.removeEnd(',');
		String whereStr = ' from Contact where id = \'' + CommUtils.escStr(contactId) + '\' ';
		whereStr += ' And Name = \'' + CommUtils.escStr(contactName) + '\' limit 1';
//system.debug(logginglevel.info,'query:::' + query);
		List<Contact> contactLst = Database.query(query + whereStr);
		if (contactLst.isEmpty()) {
			return contact;
		} else {
			contact = contactLst[0];
			// 2019/04/30 一括予約画面、新規予約画面と一括予約画面のカスタマイズ上でお客様に紐づく取引先の項目 by zy BEGIN
			// 参照字段あり
			if (!fieldMap.isEmpty()) {
				// 反回内容
				Map<String,object> result = new Map<String,object>();
				// お客様字段設定
				for (String fieldName : fieldString.split(',')) {
					// 字段名小文字変更
					String lowerField = fieldName.toLowerCase();
					// 字段あり
					if (modelContactDeafaultValuesMap.containsKey(lowerField)) {
						Schema.DescribeFieldResult dr = modelContactDeafaultValuesMap.get(lowerField);
						// 参照タイプ
						if (dr.getType() == DisplayType.REFERENCE) {
							// 参照名
							String refranceNm = dr.getRelationshipName();
							Sobject newSobject = contact.getsobject(refranceNm);
							if (newSobject != null) result.put(dr.getName(),new Map<String,Object>{'id' => contact.get(dr.getName()),'name'=> newSobject.get('name')});
						} else result.put(dr.getName(),contact.get(dr.getName()));
					}
				}
				return result;
			}
			// 2019/04/30 一括予約画面、新規予約画面と一括予約画面のカスタマイズ上でお客様に紐づく取引先の項目 by zy END
			return contact;
		}
	}
	// SOQL予約取得項目定義
	//2017/01/18 予約インデックス項目レーアウト作成する　by zy BEGIN
	private final String queryLeadIndexStr = 'Select EventSource__c,Comment__c, Payment__c, Channel__c, Segment__c, ContactNameCal__c,contactRef__r.Katakana__c, contactRef__r.Id, contactRef__r.Memo6__c, contactRef__r.Memo5__c, contactRef__r.Memo4__c, contactRef__r.Memo3__c, contactRef__r.Memo2__c, contactRef__r.Memo1__c, contactRef__r.KanaName2__c, contactRef__r.KanaName1__c, contactRef__r.Name2__c, contactRef__r.Name1__c, contactRef__r.Phone, contactRef__r.Name, contactRef__r.Account.Name, contactRef__r.AccountId, contactRef__r.ApplicantName__c,contactRef__r.ApplicantPhone__c, contactRef__c, Rooms__c, Nights__c, Name, LeadNo__c, EntryTime__c, EntryDate__c, DepartureTime__c, DepartureDate__c,LeadName__c,BookingFlexAppLayoutNo__c From LeadIndex__c ';
	//2017/01/18 予約インデックス項目レーアウト作成する　by zy END
	// SOQL顧客情報項目定義
	//private static final String queryContStr = 'Select Id, Phone, Name1__c, Name, Memo6__c, Memo5__c, Memo4__c, Memo3__c, Memo2__c, Memo1__c, Katakana__c, KanaName2__c, KanaName1__c,Account.Name,ApplicantName__c,ApplicantPhone__c From Contact ';

	// **************************
	// 部屋タイプ一覧を取得する
	// 部屋の最大格納人数取得、JS化する
	// **************************
	public List<Selectoption> roomTypeLst{get; private set;}
	public String roomTypeScript{get; private set;}
	private void setRoomTypeLst() {
		roomTypeLst = new List<Selectoption>();
		roomTypeScript = '';
		String shopCode = Apexpages.currentpage().getparameters().get('spcd');
		if(CommUtils.isBlank(shopCode)) shopCode = UserUtil.CurrentUser.ShopCode__c;
		// 2016/12/27 多店舗区分機能追加　by　zy BEGIN
		branchNm = shopCode;
		// 2016/12/27 多店舗区分機能追加　by　zy END
		// 2013/07/30 支店機能対応
        //for (TypeOfRooms__c roomType: [select id, Name, MaxNumber__c from TypeOfRooms__c where ActionType__c = :CommConst.ROOMTYPE_NORMAL order by Seq__c limit 200]) {
		// 2019/01/30 部屋タイプを選ぶ際、ユーザは複数店舗 by zy BEGIN
		// 2019/01/30 JINYABUG-1367 by zy BEGIN
		List<String> shopCodes = getShopCodeRooms(shopCode);
		// 2019/01/30 JINYABUG-1367 by zy END
		//List<TypeOfRooms__c> roomTypeLstRs = (new CommLogicProcess()).getTypeOfRooms(shopCode);
		List<TypeOfRooms__c> roomTypeLstRs = (new CommLogicProcess()).getTypeOfRooms(shopCodes);
		// JINYABUG-1351 BUG FIX by zy BEGIN
		// 多店舗フラグ
		boolean moreShopFlag = false;
		String spcd = null;
		for (TypeOfRooms__c roomType: roomTypeLstRs) {
			String typShop = CommUtils.nullToblank(roomType.ShopInfoRef__r.ShopCode__c);
			// 多店舗の場合
			if (spcd != null && spcd != typShop) {
				moreShopFlag = true;
				break;
			}
			if (spcd == null) spcd = typShop;
		}
		// JINYABUG-1351 BUG FIX by zy END
		// 2019/01/30 部屋タイプを選ぶ際、ユーザは複数店舗 by zy END
		for (TypeOfRooms__c roomType: roomTypeLstRs) {
			// 2019/01/30 部屋タイプを選ぶ際、ユーザは複数店舗 by zy BEGIN
			// JINYABUG-1351 BUG FIX by zy BEGIN
			String pShopCode = CommUtils.nullToblank(roomType.ShopInfoRef__r.ShopCode__c);
			String spcdPrefix = moreShopFlag && !CommUtils.isBlank(pShopCode) && bookingFlexSpcdFlag ? '(' + pShopCode + ')' : '';
            roomTypeLst.add(new Selectoption(roomType.Id, roomType.name + spcdPrefix));
            // JINYABUG-1351 BUG FIX by zy END
            // 2019/01/30 部屋タイプを選ぶ際、ユーザは複数店舗 by zy END
            roomTypeScript += '"' + roomType.Id + '" : ' + CommUtils.nullToZero(roomType.MaxNumber__c) + ',';
        }
        roomTypeScript = '{' + roomTypeScript.substringBeforeLast(',') + '}';
	}
	/**
	* 予約データ作成前の事前チェック
	**/
	private boolean preCreateInfo() {
//System.debug(logginglevel.info,'preCreateInfo:::');
		Boolean isHaveValidateFlg = false;
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
        	isHaveValidateFlg = true;
		}
		if (!isHaveValidateFlg) {
			//2017/03/09 一括予約について。予約キャンセル処理後に特記を入力できるように改善対応 By zy BEGIN
			if (!leadIsCancel(newLead.ReservedStatus__c)) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '有効な明細情報を登録してください.'));
			else update newLead;
			//2017/03/09 一括予約について。予約キャンセル処理後に特記を入力できるように改善対応 By zy END
		}
		return (!Apexpages.hasMessages(ApexPages.Severity.ERROR));
	}
	//2017/03/09 一括予約について。予約キャンセル処理後に特記を入力できるように改善対応 By zy BEGIN
	public static boolean leadIsCancel(String status) {
		return (status == CommConst.LEAD_ST_NOSHOW || status == CommConst.LEAD_ST_CANCEL || status == CommConst.LEAD_ST_DELETE);
	}
	//2017/03/09 一括予約について。予約キャンセル処理後に特記を入力できるように改善対応 By zy END
	/**
	* 予約データの作成
	* 「予約登録」ボタンをクリックして、予約基本（予約インデックス）、予約明細（予約インデックスSUB）、予約、顧客様、取引先データを登録する
	**/
	public void createLeadInfo() {
		// 事前処理を行う
		if (!preCreateInfo()) return;
		
		Savepoint sp = Database.setSavepoint();
		// 2017/03/14 一括キャンセル機能の対応　by　zy BEGIN
		boolean isCancelAllLeadFlag = false;
		// 2017/03/14 一括キャンセル機能の対応　by　zy END
		try {
			//2017/04/25 项目优化 by zy BEGIN
			if (isChgConFlag) {
				upsertContact();
				isChgConFlag = false;
			}
			//2017/04/25 项目优化 by zy END
		// 新規登録と更新を行う「判断条件は？」
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
		List<LeadIndex__c> subIndexLst = new List<LeadIndex__c>();
		if (CommUtils.isBlank(newLead.Name)) newLead.Name = newContact.name;
		leadBaseInf.s.LeadName__c = newLead.Name;
		//2017/01/18 予約インデックス項目レーアウト作成する　by zy BEGIN
		leadBaseInf.s.BookingFlexAppLayoutNo__c = curLayoutId;
		//2017/01/18 予約インデックス項目レーアウト作成する　by zy END
		// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy BEGIN
		roomJsons = new List<String>();
		// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy END
		// 2019/10/15 .ルームインジケータで1室押さえ、それから一括予約で部屋を増やした場合、親部屋の「●」が動的に付与されません。自動化をお願いします by zy BEGIN
		// 親明細Id
		String orgMainParId = null;
		// 既存の親明細、部屋変更フラグ
		boolean hadParRoomChg = false;
		// 依存インデックスの集合
		map<String,LeadItem> updLeadItemMap = new map<String,LeadItem>();
		// 2019/10/15 .ルームインジケータで1室押さえ、それから一括予約で部屋を増やした場合、親部屋の「●」が動的に付与されません。自動化をお願いします by zy END
		// 予約基本新規登録する場合
		if (leadBaseInf.s.Id == null) {
			// 新規登録を行う[予約チャネル/セグメント]設定を行う
			leadBaseInf.s.contactRef__c = newLead.Relcontact__c;
			leadBaseInf.s.Channel__c = newLead.Field2__c;
			leadBaseInf.s.Segment__c = newLead.Segment__c;
			leadBaseInf.s.Payment__c = newLead.Field315__c;
			// 基本情報を新規登録する
			insert leadBaseInf.s;
			//2016/12/30 親SUB判定　by zy BEGIN
			boolean hadParentFlag = false;
			//2016/12/30 親SUB判定　by zy END
			// 予約明細（予約インデックスSUB）新規情報を設定する
			for (LeadItem item : oLeadLst) {
				// 無効な予約明細情報の場合、処理スキップ
				if (!item.isValidate()) {
					subIndexLst.add(new LeadIndex__c());
					continue;
				}
				//2016/12/30 親SUB判定　by zy BEGIN
				if (item.s.ParentFlg__c) hadParentFlag = true;
				//2016/12/30 親SUB判定　by zy END
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
				// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy BEGIN
				roomJsons.add(item.roomInfoJson);
				// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy END
				indexSubLst.add(subIndex);
				subIndexLst.add(subIndex);
			}
			//2016/12/30 親SUB判定　by zy BEGIN
			if (!hadParentFlag) {
				indexSubLst[0].ParentFlg__c = true;
			}
			//2016/12/30 親SUB判定　by zy END
			// 新規登録した予約データのNameを取得する
			LeadIndex__c index = [select id, name from LeadIndex__c where id = :leadBaseInf.s.Id];
			leadBaseInf.leadNo = index.Name;
			// 検索条件項目を設定する
			searchLabel = leadBaseInf.leadNo;
			searchLeadIdxId = index.Id;
		} 
		// 予約番号にて、予約データが既に登録場合、
		else {
			// 予約基本情報を更新を行う[予約チャネル/セグメント]設定を行う
			// 注：予約チャネル/セグメントは変更されるでも、予約データへ連動更新を行わない
            leadBaseInf.s.Channel__c = newLead.Field2__c;
            leadBaseInf.s.Segment__c = newLead.Segment__c;
            // 予約情報を更新を行う
			update leadBaseInf.s;
			// 2017/12/25 親部屋子部屋更新項目カスタム設定　by　zy BEGIN
			isCancelAllLeadFlag = refreshDetailLeads(isCancelAllLeadFlag);
			/*
			boolean reservedTypeFlag = false;
				//2016/12/29 予約カスタム項目差異　by　zy　BEGIN
				boolean isDiffLead = checkDifLead();
				if ( isDiffLead ) {
					id parSubId;
					for (LeadItem item : oLeadLst ) {
						if(item.s.ParentFlg__c){
							parSubId = item.s.id;
							break;
						}
						
					}
					if (parSubId != null){
						List<Lead__c> mainLst = new List<Lead__c>();
						Decimal orgRoomGroupNo = null;
						for (Lead__c mainLead : [select id,RoomGroupNo__c from Lead__c where LeadIndexRef__c = :leadBaseInf.s.Id And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG and LeadIndexSubId__c = :parSubId Order By RoomGroupNo__c, EntryTime__c]){
							if (orgRoomGroupNo == null) orgRoomGroupNo = mainLead.RoomGroupNo__c;
							if (orgRoomGroupNo != mainLead.RoomGroupNo__c) break;
							difLead.id = mainLead.id;
							mainLead = difLead.clone(true,true);
							mainLst.add(mainLead);
						}
						if (!mainLst.isEmpty()) {
							update mainLst;
						}
					}
					if (hadReservedTypeFlag) reservedTypeFlag = difLead.ReservedType__c != null;
				}
				// 2017/03/14 一括キャンセル機能の対応　by　zy BEGIN
				boolean isStatusChgFlag = hadReservedStatusFlag && newLead.ReservedStatus__c != oldLead.ReservedStatus__c;
				// 2017/05/26 予約ステータスは無効がどうか判断条件変更 BEGIN
				//isCancelAllLeadFlag = isStatusChgFlag  && newLead.ReservedStatus__c == CommConst.LEAD_ST_CANCEL;
				isCancelAllLeadFlag = isStatusChgFlag  && (
					newLead.ReservedStatus__c == CommConst.LEAD_ST_CANCEL ||
					newLead.ReservedStatus__c == CommConst.LEAD_ST_NOSHOW ||
    	       		newLead.ReservedStatus__c == CommConst.LEAD_ST_DELETE );
				// 2017/05/26 予約ステータスは無効がどうか判断条件変更 END
				// 2017/03/14 一括キャンセル機能の対応　by　zy END
				//2016/12/29 予約カスタム項目差異　by　zy　END
				// 予約名変更される場合、関連予約名は全部自動変更を行う
				if (newLead.Relcontact__c != leadbaseInf.orgContactId ||
					newLead.Name != leadBaseInf.orgLeadName ||
					newLead.Field315__c != leadBaseInf.orgPaymentType ||
					newLead.Field2__c != leadBaseInf.orgChannel ||
					newLead.Segment__c != leadBaseInf.orgSegment ||
					// 2017/01/09 予約タイプの全部予約変更　by zy BEGIN
					reservedTypeFlag ||
					// 2017/01/09 予約タイプの全部予約変更　by zy END
					// 2017/03/14 一括キャンセル機能の対応　by　zy BEGIN
					isStatusChgFlag
					// 2017/03/14 一括キャンセル機能の対応　by　zy END
					//CommUtils.nullToBlank(leadBaseInf.s.Comment__c) != CommUtils.nullToBlank(leadBaseInf.orgComment) 
				) {
					List<Lead__c> existLeads = [select id , name from Lead__c where LeadIndexRef__c = :leadBaseInf.s.Id And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG];
					for (Lead__c lead : existLeads) {
						if (newLead.Relcontact__c != leadbaseInf.orgContactId)
						lead.Relcontact__c = newLead.Relcontact__c;
						if (newLead.Name != leadBaseInf.orgLeadName)
						lead.name = lead.Name.replace(leadBaseInf.orgLeadName, convertLeadName(newLead.Name));
						if (newLead.Field315__c  != leadBaseInf.orgPaymentType)
						lead.Field315__c = newLead.Field315__c;
						if (newLead.Field2__c  != leadBaseInf.orgChannel)
						lead.Field2__c = newLead.Field2__c;
						if (newLead.Segment__c != leadBaseInf.orgSegment)
						lead.Segment__c = newLead.Segment__c;
						// 2017/01/09 予約タイプの全部予約変更　by zy BEGIN
						if (reservedTypeFlag) lead.ReservedType__c = newLead.ReservedType__c;
						// 2017/01/09 予約タイプの全部予約変更　by zy END
						// 2017/03/14 一括キャンセル機能の対応　by　zy BEGIN
						if (isStatusChgFlag) lead.ReservedStatus__c = newLead.ReservedStatus__c;
						// 2017/03/14 一括キャンセル機能の対応　by　zy END
						// 2014/01/08 一時対象外にする
						//if (CommUtils.nullToBlank(leadBaseInf.s.Comment__c) != CommUtils.nullToBlank(leadBaseInf.orgComment)) 
						//lead.Comment3__c = leadBaseInf.s.Comment__c;
					}
					update existLeads;
				}
			*/
			// 2017/12/25 親部屋子部屋更新項目カスタム設定　by　zy END
			// 予約明細（予約インデックス（SUB)）更新される情報格納
			List<LeadItem> changeItemList = new List<LeadItem>();
			// 2016/04/06 ご予約情報はキャンセルから復活する BEGIN
			List<LeadIndex__c> statusOnlyChangeSubIdxLst = new List<LeadIndex__c>();
			// 2016/04/06 ご予約情報はキャンセルから復活する END
			//2016/12/30 親SUB判定　by zy BEGIN
			boolean hadParentFlag = false;
			//2016/12/30 親SUB判定　by zy END
			//2017/04/26 親部屋　by zy BEGIN
			Integer firstIndex = -1;
			//2017/04/26 親部屋　by zy END
			// 2019/11/15 一括予約画面の部屋直接選択 by zy BEGIN
			List<LeadItem> leadList = new List<LeadItem>();
			// 2019/11/15 一括予約画面の部屋直接選択 by zy END
			// 予約明細詳細処理
            for (LeadItem item : oLeadLst) {
            	// キャンセル対象データ
            	if (item.isDelete()) {
            	   subIndexLst.add(item.s);
            	   delSubLst.add(item.s);
            	   continue;
            	}
            	// 無効なデータ場合、処理対象外
                if (!item.isValidate()){ 
                	subIndexLst.add(new LeadIndex__c());
                	continue;
                }
                //2017/04/26 親部屋　by zy BEGIN
                if (firstIndex == -1) firstIndex = subIndexLst.size();
                //2017/04/26 親部屋　by zy END
                //2016/12/30 親SUB判定　by zy BEGIN
				// 2019/10/15 .ルームインジケータで1室押さえ、それから一括予約で部屋を増やした場合、親部屋の「●」が動的に付与されません。自動化をお願いします by zy BEGIN
				if (item.s.ParentFlg__c) {
					hadParentFlag = true;
					orgMainParId = item.s.id;
					hadParRoomChg = item.isChgRooms();
				}
				// 2019/10/15 .ルームインジケータで1室押さえ、それから一括予約で部屋を増やした場合、親部屋の「●」が動的に付与されません。自動化をお願いします by zy END
				//2016/12/30 親SUB判定　by zy END
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
		        	subIndexLst.add(item.s);
					// 2019/10/15 .ルームインジケータで1室押さえ、それから一括予約で部屋を増やした場合、親部屋の「●」が動的に付与されません。自動化をお願いします by zy BEGIN
					// 既存インデックス対応の明細
					updLeadItemMap.put(item.s.id,item);
					// 2019/10/15 .ルームインジケータで1室押さえ、それから一括予約で部屋を増やした場合、親部屋の「●」が動的に付与されません。自動化をお願いします by zy END
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
					// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy BEGIN
					roomJsons.add(item.roomInfoJson);
					// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy END
	                indexSubLst.add(subIndex);
	                subIndexLst.add(subIndex);
                }              
            }
            //2016/12/30 親SUB判定　by zy BEGIN
			if (!hadParentFlag) {
				//2017/04/26 親部屋　by zy BEGIN
				// 2017/06/22 数组下标越界bug fix by zy BEGIN
				// 2019/10/15 .ルームインジケータで1室押さえ、それから一括予約で部屋を増やした場合、親部屋の「●」が動的に付与されません。自動化をお願いします by zy BEGIN
				if (firstIndex != -1) {
					// 2017/06/22 数组下标越界bug fix by zy END
					subIndexLst[firstIndex].ParentFlg__c = true;
					//2017/04/26 親部屋　by zy END
					orgMainParId = subIndexLst[firstIndex].id;
					if (updLeadItemMap.containsKey(orgMainParId)) hadParRoomChg = updLeadItemMap.get(orgMainParId).isChgRooms();
				}
				// 2019/10/15 .ルームインジケータで1室押さえ、それから一括予約で部屋を増やした場合、親部屋の「●」が動的に付与されません。自動化をお願いします by zy END
			}
			// 2019/10/15 .ルームインジケータで1室押さえ、それから一括予約で部屋を増やした場合、親部屋の「●」が動的に付与されません。自動化をお願いします by zy BEGIN
			// 新規追加明細の場合、既存親明細変更の場合、チェック親明細の部屋数変更
			if (!changeItemList.isEmpty() && hadParRoomChg) orgMainParId = null;
			// 2019/10/15 .ルームインジケータで1室押さえ、それから一括予約で部屋を増やした場合、親部屋の「●」が動的に付与されません。自動化をお願いします by zy END
			//2016/12/30 親SUB判定　by zy END
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
			//2017/06/21 親部屋の選択機能追加　by　zy BEGIN
			String mainParentSubId = '';
			for (LeadIndex__c subIndex :indexSubLst) {
				if(subIndex.ParentFlg__c) mainParentSubId = subIndex.id;
			}
			if (!CommUtils.isBlank(mainParentSubId)) chgParentFlagBySubId(mainParentSubId);
			//2017/06/21 親部屋の選択機能追加　by　zy END
			// 2019/10/15 .ルームインジケータで1室押さえ、それから一括予約で部屋を増やした場合、親部屋の「●」が動的に付与されません。自動化をお願いします by zy BEGIN
			// 新規明細の場合
			else if (!CommUtils.isBlank(orgMainParId)) {
				List<lead__c> updLeads = new List<lead__c>();
				
				for (Lead__c lead : [select id,name from lead__c where LeadIndexSubId__c =:orgMainParId and RoomGroupNo__c = 0]) {
					if (!lead.name.startsWith(LEAD_NAME_PREFIX)) {
						lead.Name = LEAD_NAME_PREFIX + lead.Name;
						updLeads.add(lead);
					}
				}
				if (!updLeads.isEmpty()) update updLeads;
			}
			// 2019/10/15 .ルームインジケータで1室押さえ、それから一括予約で部屋を増やした場合、親部屋の「●」が動的に付与されません。自動化をお願いします by zy END
		}
//system.debug(logginglevel.info,'subIndexLst:::' + subIndexLst);
		// 画面から入力した見積明細情報
		Map<Id,Map<Date,List<BookingEstimateItem__c>>> uiInputEstItemsBySubIndexMap = getUiInputEstItemsBySubIndexMap(subIndexLst);
//System.debug(logginglevel.info,'uiInputEstItemsBySubIndexMap:::' + uiInputEstItemsBySubIndexMap);
		if (!indexSubLst.isEmpty()) {
			// 予約データ展開、新規作成を行う
			autoGenerLeadInfo(indexSubLst,uiInputEstItemsBySubIndexMap);
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
			saveFlag = false;
			// 2017/05/04 自施設の予約や会計しか変更できないように権限管理機能 BEGIN
			//Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getStackTraceString()));
			String errMsg = e.getMessage();
            if(!CommUtils.isFieldValidationMessage(errMsg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
//system.debug(logginglevel.info,'e:::' + e.getStackTraceString());
			// 2017/05/04 自施設の予約や会計しか変更できないように権限管理機能 END
			return;
		}
		// 2017/03/14 一括キャンセル機能の対応　by　zy BEGIN
		if (isCancelAllLeadFlag) refreshExistLeadInfo();
		// 最新予約情報を取得、更新を行う
		//对于明细被全部取消以外的数据进行处理
		else { 
			queryExistLeadByLeadIndexId();
			// 2017/03/14 一括キャンセル機能の対応　by　zy END
			// 最新の予約情報を再取得する
			refreshWinLead();
		}
		//2016/11/15 section自动展开
		sectionExpandProcess();
	}
	private void upsertContact(){
//system.debug(logginglevel.info,'newLead.Relcontact__c:::|' + newLead.Relcontact__c + '|');
		String contactId = CommUtils.nullToBlank(newLead.Relcontact__c);
		//2017/03/09 一画面に、お客様の名前を変更（違う人に入れ替え）したところ、お客様情報を違う更新される不具合改修 by zy BEGIN
		Contact updConct = new Contact();
		//2017/03/09 一画面に、お客様の名前を変更（違う人に入れ替え）したところ、お客様情報を違う更新される不具合改修 by zy END
//system.debug(logginglevel.info,'contactId:::' + contactId + '|');
		// 顧客情報を新規・更新を行う 直接选择客户 没有新规入力项目
        if(!CommUtils.isBlank(contactId)) {
        	//2017/03/09 一画面に、お客様の名前を変更（違う人に入れ替え）したところ、お客様情報を違う更新される不具合改修 by zy BEGIN
        	updConct.id = contactId;
        	//2017/03/09 一画面に、お客様の名前を変更（違う人に入れ替え）したところ、お客様情報を違う更新される不具合改修 by zy END
        	newContact.Id = newLead.Relcontact__c;
//system.debug(logginglevel.info,'newContact:::|' + newContact + '|');
        }else{
        	String[] names = CommUtils.splitName(contactName);
    		//2017/03/09 一画面に、お客様の名前を変更（違う人に入れ替え）したところ、お客様情報を違う更新される不具合改修 by zy BEGIN
			updConct.LastName = names[0];
			updConct.FirstName = names[1];
			//newContact.LastName = names[0];
    		//newContact.FirstName = names[1];
			//2017/03/09 一画面に、お客様の名前を変更（違う人に入れ替え）したところ、お客様情報を違う更新される不具合改修 by zy END
//system.debug(logginglevel.info,'newContact:::' + newContact);
    	}
    	// 2016/10/19 お客様重複管理機能対応 BEGIN
    	//upsert newContact;
    	//2017/03/09 一画面に、お客様の名前を変更（違う人に入れ替え）したところ、お客様情報を違う更新される不具合改修 by zy BEGIN
    	map<String, Schema.DescribeFieldResult> modelContactDeafaultValuesMap = CommSqlUtils.getAllFieldLst(Contact.sObjectType,true,true);
    	for (String contactStr :planString.split(',')){
    		if(modelContactDeafaultValuesMap.containsKey(contactStr.toLowerCase())){
    			updConct.put(contactStr,newContact.get(contactStr));
    		}
    	}
    	//newContact = (new CommLogicProcess()).upsertDuplicateErrorProcess(newContact);
    	newContact = (new CommLogicProcess()).upsertDuplicateErrorProcess(updConct);
    	//2017/03/09 一画面に、お客様の名前を変更（違う人に入れ替え）したところ、お客様情報を違う更新される不具合改修 by zy END
    	//定义的字段更新后，有未设定在xml中的字段需要用到，从数据库里重新读取客户
    	//2017/03/14 お客様の既存フェルダー取得する　by　zy BEGIN
		String conId = newContact.id;
		if(!CommUtils.isBlank(conId)){
			String contactQuery = CommSqlUtils.generateQueryString('Contact');
			contactQuery += ' where id=:conId';
			List<Contact> contactResult = Database.query(contactQuery);
			newContact = contactResult[0];
		}
		if (leadBaseInf.s.contactRef__c != newContact.id) leadBaseInf.s.contactRef__c = newContact.id;
		//2017/03/14 お客様の既存フェルダー取得する　by　zy END
    	//2017/03/09 顧客情報bug fix by zy BEGIN
    	// 2016/10/19 お客様重複管理機能対応 END
    	newLead.Relcontact__c = newContact.Id;
    	isChgConFlag = false;
	}
	/**
	* 予約データの自動更新機能
	* Descript：画面登録したSubIndex（更新）
	**/
	private void autoUpdateLeadInfo(List<LeadItem> p_subLst) {

		// SubIndex未設定のケースに対して、問題あり、部屋タイプ未設定のケース
        // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
        //String defCheckInTime = CommConst.DEF_CHECKIN_TIME;
        //String defCheckOtTime = CommConst.DEF_CHECKOT_TIME;
        String defCheckInTime = JS_DEFCHKIN_DT;
        String defCheckOtTime = JS_DEFCHKOT_DT;
        // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
        // 部屋数０から１以上に変更する TODO
        // 予約新規として、予約処理作成を行う
        //2017/06/26 見積もり明細の価格対応　by　zy　BEGIN
        Set<String> planIds = new Set<String>();
        Set<String> accIds = new Set<String>();
        //2017/06/26 見積もり明細の価格対応　by　zy　END
		// 既存のSUBINDEXデータのID SET
		Set<Id> subIdxIdSet = new Set<Id>();
		for (LeadItem item : p_subLst) { 
            // 有効なSUBINDEXデータを格納する
            subIdxIdSet.add(item.s.Id);
            //2017/06/26 見積もり明細の価格対応　by　zy　BEGIN
            if (item.s.PlanRef__c != null) {
            	planIds.add(item.s.PlanRef__c);
            } 
            if (item.s.AccountMasterRef__c != null){
            	accIds.add(item.s.AccountMasterRef__c);
            }
            if (item.orgSobj.PlanRef__c != null) {
            	planIds.add(item.orgSobj.PlanRef__c);
            } 
            if (item.orgSobj.AccountMasterRef__c != null){
            	accIds.add(item.orgSobj.AccountMasterRef__c);
            }
            //2017/06/26 見積もり明細の価格対応　by　zy　END
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
			//2017/06/26 見積もり明細の価格対応　by　zy　BEGIN
			planIds.add(lead.field310__c);
			//2017/06/26 見積もり明細の価格対応　by　zy　END
		}
		//2017/06/26 見積もり明細の価格対応　by　zy　BEGIN
		Map<String,ProductInfo> planToAccount = planToAccountMaster(planIds,accIds);
		//2017/06/26 見積もり明細の価格対応　by　zy　END
		// 新規、変更する予約データ情報を格納する
		List<Lead__c> updLeadLst = new List<Lead__c>();
		// 変更された予約明細（予約インデックス（SUB）
		List<LeadIndex__c> updSubIdxLst = new List<LeadIndex__c>();
		// 期間延長の予約データ、部屋既にアサインする倍、延長する期間に既に重複アサインする部屋が存在がどう、チェック用配列
//		Set<Id> chgTermRoomIdSet = new Set<Id>();
		// <IndexSub/<GroupNo/<開始日/終了日>>>
//		Map<Id, Map<Integer,List<Date>>> chgTermLeadMap = new Map<Id, Map<Integer,List<Date>>>();
		Set<Id> chgTypeSubIdxIdSet = new Set<Id>();
		//2017/01/10 プラン→商品明細　by　zy BEGIN
		//2017/06/26 見積もり明細の価格対応　by　zy　BEGIN
		//Map<String,String> orgSubAccMap = new Map<String,String>();
		Map<String,Set<String>> orgSubAccMap = new Map<String,Set<String>>();
		//2017/06/26 見積もり明細の価格対応　by　zy　END
		List<LeadIndex__c> subIdxLst = new List<LeadIndex__c>();
		//2017/07/04 防止重复list 转 map型 by zy BEGIN
		List<Lead__c> updLst = new List<Lead__c>();
		Map<String,Lead__c> updMap = new Map<String,Lead__c>();
		//2017/07/04 防止重复list 转 map型 by zy END
		//2017/01/10 プラン→商品明細　by　zy END
		//2017/06/26 見積もり明細の価格対応　by　zy　BEGIN
		List<LeadIndex__c> chgPriceSubLst = new List<LeadIndex__c>();
		//2017/06/26 見積もり明細の価格対応　by　zy　END
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
						//单独更改人数时，plan重新对应
						if (CommConst.APPOTION_LEAD_STAYPERSIONS_SYNCTO_ESTITEM_FLG) { 
							processDelAccount(orgSubAccMap,lead,subIdxitem,planToAccount);
							processCurItemPlan (lead,subIdxitem.s , planToAccount,true);
							//2017/07/04 防止重复list 转 map型 by zy BEGIN
							updMap.put(lead.id,lead);
							//updLst.add(lead);
							//2017/07/04 防止重复list 转 map型 by zy END
						}
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
			//2017/01/10 プラン→商品明細　by　zy BEGIN
			//商品変更の場合
			//2017/06/26 見積もり明細の価格対応　by　zy　BEGIN
			if (subIdxitem.isChgAcc()||subIdxitem.isChgPrice()) {
				ProductInfo p = getPordInfo(subIdxitem.s,planToAccount);
				subIdxitem.s.PlanRef__c = null;
				if (p != null && p.acc != null) {
					subIdxitem.s.AccountMasterRef__c = p.acc.id;
				}
				//2017/06/26 見積もり明細の価格対応　by　zy　END
				//List<id> BookingLeadIds = new List<id>();
				for (Integer groupNo : oneGroupLeadMap.keySet()) {
					// 同じ部屋の予約データリストを取得する(同じ部屋N泊の予約データ)
					List<Lead__c> updLeads = oneGroupLeadMap.get(groupNo);
					for (Lead__c lead : updLeads) {
						//2017/06/26 見積もり明細の価格対応　by　zy　BEGIN
						processDelAccount(orgSubAccMap,lead,subIdxitem,planToAccount);
						processCurItemPlan (lead,subIdxitem.s , planToAccount,true);
						//2017/06/26 見積もり明細の価格対応　by　zy　END
						subIdxLst.add(subIdxitem.s);
						//2017/07/04 防止重复list 转 map型 by zy BEGIN
						updMap.put(lead.id,lead);
						//updLst.add(lead);
						//2017/07/04 防止重复list 转 map型 by zy END
					}
				}
			}
			//2017/01/10 プラン→商品明細　by　zy END
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
	             //2017/02/04 期间变更其他信息不变改正 by zy BEGIN
	            //期间宽度没有变更只是日期变更，只更改
	            Integer orgNums = CommUtils.nullToZero(subIdxitem.orgSobj.Nights__c).intValue();
	             //2017/02/04 期间变更其他信息不变改正 by zy END
	            // 宿泊開始日と宿泊出発日の取得
	            Date defaultDate = nw.EntryDate__c;
	            String startTime = CommUtils.isBlank(nw.EntryTime__c) ? defCheckInTime : nw.EntryTime__c;
	            String endTime = CommUtils.isBlank(nw.DepartureTime__c) ? defCheckOtTime : nw.DepartureTime__c;
	            Time startTm = CommUtils.stringToTime(startTime);
	            Time endTm = CommUtils.stringToTime(endTime);
	            /* 2013/01/21 */
		        Datetime defCheInDt = Datetime.newInstance(defaultDate, startTm);
		        Datetime defCheOutDt = Datetime.newInstance(defaultDate.addDays(staysNums > 0 ? 1 : 0), endTm);
		        //2017/02/04 期间变更其他信息不变改正 by zy BEGIN
	            if (staysNums == orgNums) {
	                for (Integer groupNo : oneGroupLeadMap.keySet()) {
						// 同じ部屋の予約データリストを取得する(同じ部屋N泊の予約データ)
						List<Lead__c> updLeads = oneGroupLeadMap.get(groupNo);
						for (Integer i = 0; i < updLeads.size() ; i++) {
							// 到着日と出発日
			                updLeads[i].EntryTime__c = DateTime.newInstance(defCheInDt.addDays(i).date(), startTm);
			                updLeads[i].Departure__c = DateTime.newInstance(defCheOutDt.addDays(i).date(), endTm);
		            		updLeads[i].Field4__c = startTime;
			                updLeads[i].Field3__c = endTime;
						}
					}
	            } else {
					//2017/02/04 期间变更其他信息不变改正 by zy END
					// 日帰りの個別処理
					staysNums = staysNums == 0 ? 1 : staysNums;
					// 開始日
					//Date startDt = subIdxitem.s.EntryDate__c;
					//2017/06/26 見積もり明細の価格対応　by　zy　BEGIN
					boolean isPlanFlag = false;
					//2017/06/26 見積もり明細の価格対応　by　zy　END
					// 設定済予約データの期間延長する
					for (Integer groupNo : oneGroupLeadMap.keySet()) {
						// 同じ部屋の予約データリストを取得する(同じ部屋N泊の予約データ)
						List<Lead__c> nightsLeads = oneGroupLeadMap.get(groupNo);		
						// 元データの連泊日数計算を行う
						Integer orgStaysNums = nightsLeads.size();
						// 変更前の予約名
						String orgLeadName = nightsLeads[nightsLeads.size()-1].Name;
						String leadNamePrefix = orgLeadName.startsWith(LEAD_NAME_PREFIX) ? LEAD_NAME_PREFIX : '';
					
						// 2014/01/08 一時対象外にする
						//if (CommUtils.nullToBlank(leadBaseInf.s.Comment__c) != CommUtils.nullToBlank(leadBaseInf.orgComment)) 
						//lead.Comment3__c = leadBaseInf.s.Comment__c;
					
						// 泊期間延長の場合
						if (orgStaysNums < staysNums) {
							// 期間変更に従って、延長された日付の部屋は再割当てする事が必要
							Lead__c cloneLead = nightsLeads[nightsLeads.size()-1].clone(false,true);
							cloneLead.refTypeOfRooms__c = nw.RoomTypeRef__c;
							// 2020/02/28 一括予約画面 延泊した際、アサイン済みの部屋は自動で延泊分もアサインされるように by zy BEGIN
							if (!isChgNitghtCopyRoomFlg) cloneLead.Rroom__c = null;
							// 2020/02/28 一括予約画面 延泊した際、アサイン済みの部屋は自動で延泊分もアサインされるように by zy END
							// 2017/12/29 JINYABUG-229 対応　by　zy BEGIN
							// 部屋変更不可
							cloneLead.Field276__c = false;
							// 2017/12/29 JINYABUG-229 対応　by　zy END
							// 受付日
							cloneLead.ReservedDate__c = System.now();
							// 受付者
							cloneLead.ReservedContact__c = UserInfo.getName();
							// 2013/11/30 部屋変更不可のクリア
							cloneLead.Field276__c = false;
							// 2014/08/27 単価定義区分機能対応
							cloneLead.UnitPriceDefKb__c = cloneLead.UnitPriceDefKbCal__c;
							//2017/06/26 見積もり明細の価格対応　by　zy　BEGIN
							// 判定の予約データのプラン、会計商品
							processCurItemPlan (cloneLead,subIdxitem.s , planToAccount,false);
							if (cloneLead.field310__c != null) {
								isPlanFlag= true;
							}
							//2017/06/26 見積もり明細の価格対応　by　zy　END
							// 新規の予約データを自動設定、作成を行う
							// コピー元は同じ部屋の最後の予約データの設定情報
							for (Integer i = orgStaysNums; i < staysNums; i++) {
								Lead__c lead = cloneLead.clone(false,true);
								// 新規データを追加する
								nightsLeads.add(lead);
								//2017/06/26 見積もり明細の価格対応　by　zy　BEGIN
								if (!isPlanFlag)
								//2017/06/26 見積もり明細の価格対応　by　zy　END
								updLst.add(lead);
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
							Lead__c lead = nightsLeads[i];
							
							//extLead.EntryTime__c = DateTime.newInstance(startDt.addDays(i), extLead.EntryTime__c.Time());
							//extLead.Departure__c = DateTime.newInstance(startDt.addDays(i+1), extLead.Departure__c.Time());
							if (newLead.Relcontact__c != leadbaseInf.orgContactId)
								lead.Relcontact__c = newLead.Relcontact__c;
							if (newLead.Name != leadBaseInf.orgLeadName)
								lead.name = newLead.Name.replace(leadBaseInf.orgLeadName, convertLeadName(newLead.Name));
							//泊目
								//2017/02/04 期间变更其他信息不变改正 by zy BEGIN
								//if (nw.Nights__c > 1) lead.name = leadNamePrefix + String.valueOf(nw.Nights__c) + '-' + (i+1) + Label.CONST_001_0067 + nw.LeadName__c;
								//else lead.name = leadNamePrefix + nw.LeadName__c;
								if (nw.Nights__c > 1) lead.name = changeLeadName(lead.name,false,CommUtils.nullToIntZero(nw.Nights__c),i);
								else lead.name = changeLeadName(lead.name,false,CommUtils.nullToIntZero(nw.Nights__c),i);
								//2017/02/04 期间变更其他信息不变改正 by zy END
							// 到着日と出発日
							lead.EntryTime__c = DateTime.newInstance(defCheInDt.addDays(i).date(), startTm);
							lead.Departure__c = DateTime.newInstance(defCheOutDt.addDays(i).date(), endTm);
							//newLead.Field4__c = startTime;
							//newLead.Field3__c = endTime;
							if (CommUtils.isBlank(newLead.Field4__c)) lead.Field4__c = startTime;
							if (CommUtils.isBlank(newLead.Field3__c)) lead.Field3__c = endTime;
						}
					}
	    		//2017/02/04 期间变更其他信息不变改正 by zy BEGIN
	            }
	           //2017/02/04 期间变更其他信息不变改正 by zy END
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
//2017/06/26 見積もり明細の価格対応　by　zy　BEGIN
					boolean isPlanFlag = false;
//2017/06/26 見積もり明細の価格対応　by　zy　END
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
						//2017/06/26 見積もり明細の価格対応　by　zy　BEGIN
						// 判定の予約データのプラン、会計商品
						processCurItemPlan (lead,subIdxitem.s , planToAccount,false);
						if (lead.field310__c != null) {
							isPlanFlag= true;
						}
						//2017/06/26 見積もり明細の価格対応　by　zy　END
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
						//2017/06/26 見積もり明細の価格対応　by　zy　BEGIN
						if (!isPlanFlag)
						//2017/06/26 見積もり明細の価格対応　by　zy　END
						updLst.addAll(newLeads);
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
				// 2019/10/15 .ルームインジケータで1室押さえ、それから一括予約で部屋を増やした場合、親部屋の「●」が動的に付与されません。自動化をお願いします by zy BEGIN
				boolean mainRoomFlg = subIdxitem.s.ParentFlg__c;
				if (mainRoomFlg) {
					// 最後の部屋からCOPY
					List<Lead__c> nightsLeads = oneGroupLeadMap.get(0);
					for (Lead__c lead : nightsLeads) {
						if (!lead.name.contains(LEAD_NAME_PREFIX)) lead.name = LEAD_NAME_PREFIX + lead.name;
						// 2019/12/30 一括予約上で部屋数を変更すると親部屋に付いていた黒丸が消えます。 by zy BEGIN
						else if (bookingRooms <= 1 || (p_subLst.size() <= 1 && bookingRooms <= 1) ) lead.name = lead.name.replace(LEAD_NAME_PREFIX,'');
						// 2019/12/30 一括予約上で部屋数を変更すると親部屋に付いていた黒丸が消えます。 by zy END
					}
				}
				// 2019/10/15 .ルームインジケータで1室押さえ、それから一括予約で部屋を増やした場合、親部屋の「●」が動的に付与されません。自動化をお願いします by zy END 
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
			// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy BEGIN
			List<RequestInfo> roomsLst = CommUtils.isBlank(subIdxitem.roomInfoJson) ? 
							new List<RequestInfo>() :
								 (List<RequestInfo>)JSON.deserialize(subIdxitem.roomInfoJson, List<RequestInfo>.class);
			Integer rowNo = 0;
			// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy END
			for (List<Lead__c> leads : oneGroupLeadMap.values()) {
				// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy BEGIN
				if (!roomsLst.isEmpty() && rowNo < roomsLst.size()) {
					RequestInfo info = roomsLst[rowNo];
					for (Lead__c lead : leads) {
						String roomId = CommUtils.isBlank(info.id) ? null : info.id;
						// 2019/01/30 BUG FIX 部屋変更不可の場合、変更部屋可能 by zy BEGIN
						boolean roomChange = false;
						if (lead.Rroom__c != roomId) {
							lead.Rroom__c = roomId;
							roomChange = true;
						}
						// 2019/01/30 BUG FIX 部屋変更不可の場合、変更部屋可能 by zy END
						boolean lockFlag = Boolean.valueOf(CommUtils.nullToBlank(info.lock));
						if (lead.Field276__c != lockFlag) lead.Field276__c = lockFlag;
						// 2019/01/30 BUG FIX 部屋変更不可の場合、変更部屋可能 by zy BEGIN
						// 既存予約の場合
						if (roomChange && !CommUtils.isBlank(lead.id) && lead.Field276__c) 
							lead.RoomUpdFlg__c = !lead.RoomUpdFlg__c;
						// 2019/01/30 BUG FIX 部屋変更不可の場合、変更部屋可能 by zy END
					}
					rowNo++;
					// 2019/11/15 一括予約画面の部屋直接選択 by zy BEGIN
					updLeadLst.addAll(leads);
					// 2019/11/15 一括予約画面の部屋直接選択 by zy END
				}
				// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy END
				// 2019/11/15 一括予約画面の部屋直接選択 by zy BEGIN
				else updLeadLst.addAll(leads);
				// 2019/11/15 一括予約画面の部屋直接選択 by zy END
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
		//2017/07/04 防止重复list 转 map型 by zy BEGIN
		//updlist 专门存储扩展的没有id部分的予約リスト
		// updMap 针对于既存的数据存在需要修改值的时候防止重复调用而修改
		if (!updMap.isEmpty()) updLst.addAll(updMap.values());
		//2017/07/04 防止重复list 转 map型 by zy END
		//2017/01/10 プラン→商品明細　by　zy BEGIN
		updateEstemBooking(updSubIdxLst,updLst,orgSubAccMap,planToAccount);
		//2017/01/10 プラン→商品明細　by　zy END
	}
	/**
	* 予約データの新規自動作成機能
	* Descript：画面登録したSubIndex（新規）
	**/
	private void autoGenerLeadInfo(List<LeadIndex__c> subIndexLst, Map<Id,Map<Date,List<BookingEstimateItem__c>>> uiInputEstItemsBySubIndexMap) {
        // 該当明細に見積明細が存在する。しないチェックする
        map<Id,Boolean> isHaveUiEstItemsMap = new map<Id, Boolean>();
        for (Id subIdx : uiInputEstItemsBySubIndexMap.keySet()) {
        	Boolean isHaveUiEstItems = false;
        	Map<Date,List<BookingEstimateItem__c>> uiEstMap = uiInputEstItemsBySubIndexMap.get(subIdx);
        	for (List<BookingEstimateItem__c> estLst : uiEstMap.values()) {
        		if (!estLst.isEmpty()) {
        			isHaveUiEstItems = true;
        			break;
        		}
        	}
	        isHaveUiEstItemsMap.put(subIdx, isHaveUiEstItems);
        }
        // 予約データを作成する[After Insert]
        List<Lead__c> newLeadLst = new List<Lead__c>();
        // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
       // チェックイン時刻、チェックアウト時刻
        ShopInfoUtil.ShopLeadInfo shopInfo = ShopInfoUtil.getShopDefInfo(UserUtil.CurrentUser.ShopCode__c);
        //String defCheckInTime = CommConst.DEF_CHECKIN_TIME;
        //String defCheckOtTime = CommConst.DEF_CHECKOT_TIME;
        String defCheckInTime = shopInfo.defCheckInTimeStr;
        String defCheckOtTime = shopInfo.defCheckOtTimeStr;
        // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
        List<LeadIndex__c> hadProdSubLst = new List<LeadIndex__c>();
        // 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy BEGIN
        Integer rowno = 0;
        // 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy END
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
			// 2017/01/09 予約タイプの全部予約変更　by zy BEGIN
			if (hadReservedTypeFlag) cloneNewLead.ReservedType__c = newLead.ReservedType__c;
			// 2017/01/09 予約タイプの全部予約変更　by zy END
			// 2017/03/14 一括キャンセル機能の対応　by　zy BEGIN
			if (!hadReservedStatusFlag)  newLead.ReservedStatus__c = cloneNewLead.ReservedStatus__c;
			else if (newLead.ReservedStatus__c != null) cloneNewLead.ReservedStatus__c = newLead.ReservedStatus__c;
			// 2017/03/14 一括キャンセル機能の対応　by　zy END
			if (nw.AccountMasterRef__c != null)  hadProdSubLst.add(nw);
			// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy BEGIN
			String roomJSON = '';
			if (rowno < roomJsons.size()) roomJSON = roomJsons.get(rowno);
			List<RequestInfo> roomsLst = CommUtils.isBlank(roomJSON) ? new List<RequestInfo>() : (List<RequestInfo>)JSON.deserialize(roomJSON, List<RequestInfo>.class);
			// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy END
            // 泊数にて、予約データを分ける
            for(Integer i = 0; i < staysNums; i ++){
            	// 部屋数単位で、１日１部屋単位に、予約データを作成する
                for(Integer j = 0; j < bookingRooms; j ++ ){
                	Lead__c colLead;
                    boolean mainRoomFlg = j == 0 && nw.ParentFlg__c;
 
               		if(mainRoomFlg){
               			colLead = newLead.clone(false,true);
               		} else  {
               			colLead = cloneNewLead.clone(false,true);
               		}	        	  
               		colLead.RoomGroupNo__c = j;
	                // TODO:予約名の設定ルールは再検討が必要[予約データ名の再検討が必要]
	                //泊目
	                if (nw.Nights__c > 1) colLead.name = String.valueOf(nw.Nights__c) + '-' + (i+1) + Label.CONST_001_0067 + nw.LeadName__c;
	                else colLead.name = nw.LeadName__c;
		            if (mainRoomFlg && (subIndexLst.size() > 1 || (subIndexLst.size() == 1 && bookingRooms > 1))) colLead.name = LEAD_NAME_PREFIX + colLead.name;
	                // 部屋人数 - 予約人数
	                colLead.StayPersons__c = nw.StayPersons__c;
	                // 到着日と出発日
	                colLead.EntryTime__c = defCheInDt.addDays(i);
	                colLead.Departure__c = defCheOutDt.addDays(i);
	//              newLead.Field4__c = CommUtils.isBlank(nw.EntryTime__c) ? '15:00' : nw.EntryTime__c;
	//              newLead.Field3__c = CommUtils.isBlank(nw.DepartureTime__c) ? '10:00' : nw.DepartureTime__c;
	                colLead.Field4__c = CommUtils.isBlank(nw.EntryTime__c) ? defCheckInTime : nw.EntryTime__c;
	                colLead.Field3__c = CommUtils.isBlank(nw.DepartureTime__c) ? defCheckOtTime : nw.DepartureTime__c;
	                // 画面の明細の見積明細存在するがどうかチェックする[該当明細に見積明細がなかった場合、プラン情報で設定する]
	                if (!isHaveUiEstItemsMap.containsKey(nw.Id) || !isHaveUiEstItemsMap.get(nw.Id)) {
	                	// プラン情報
	                	colLead.Field310__c = nw.PlanRef__c;
	                	colLead.PlanDetailSyncInfo__c = nw.PlanDetailSyncInfo__c;
	                } else {
	                	// プラン連動しない項目を設定する
	                	colLead.Field310__c = null;
	                	colLead.PlanDetailSyncInfo__c = CommConst.CONST_PLANITEM_NOEXPAND;
	                }
	                // LeadIndex設定する
	                colLead.LeadIndexRef__c = nw.ParentLeadIndxRef__c;
	                colLead.refTypeOfRooms__c = nw.RoomTypeRef__c;
	                // SUB　INDEX関連IDを設定する
	                colLead.LeadIndexSubId__c = nw.Id;
	                // 2016/12/30 親SUBのフラグ追加　by　zy  BEGIN
	                // E/B
			        colLead.ExtraBedChk__c = nw.ExtraBedChk__c;
					// 予約受付者
					colLead.ReservedContact__c = newLead.ReservedContact__c;
					if(CommUtils.isBlank(colLead.ReservedContact__c)) colLead.ReservedContact__c = UserInfo.getName();
					// 特記事項
						//colLead.Comment3__c = newLead.Comment3__c;
					// 支払方法
					colLead.Field315__c = newLead.Field315__c;
					 // 受付日
	                colLead.ReservedDate__c = newLead.ReservedDate__c;
	                // 宿泊レコードタイプの設定
	                colLead.RecordTypeId = bookRecTypeId;
	                // 顧客
	                colLead.Relcontact__c = newLead.Relcontact__c;
					 // 予約チャネル
	                colLead.Field2__c = newLead.Field2__c;
	                // セグメント
	                colLead.Segment__c = newLead.Segment__c;
					// 2016/12/30 親SUBのフラグ追加　by　zy  END
					// 2017/12/25 親部屋子部屋更新項目カスタム設定　by　zy BEGIN
					// 2019/11/15 一括予約画面での項目編集を親部屋以外にも反映してほしい by zy BEGIN
					// if (!checkSet.isEmpty()) {
					if (!checkSet.isEmpty() && ((saveSubIndxFlg && nw.ParentFlg__c) || !saveSubIndxFlg)) {
					// 2019/11/15 一括予約画面での項目編集を親部屋以外にも反映してほしい by zy END
						for (String fieldName : checkSet) {
							colLead.put(fieldName,newLead.get(fieldName));
						}
					}
					// 2017/12/25 親部屋子部屋更新項目カスタム設定　by　zy END
					// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy BEGIN
					if(!roomsLst.isEmpty() && j < roomsLst.size()){
						String roomId = roomsLst[j].id;
						colLead.Rroom__c = CommUtils.isBlank(roomId) ? null : roomId;
						colLead.Field276__c = Boolean.valueOf(CommUtils.nullToBlank(roomsLst[j].lock));
					}
					// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy END
					// 2014/06/20 個別設定情報をコピーする
                    newLeadLst.add(colLead.clone(false,true));
                }
            }
            // 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy BEGIN
            rowno++;
            // 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy END
		}
        // 予約データの新規登録
        if (!newLeadLst.isEmpty()) insert newLeadLst;
        newLead = newLeadLst[0];
        //2017/01/10 プラン→商品明細　by　zy BEGIN
        if (!hadProdSubLst.isEmpty()) updateEstemBooking(hadProdSubLst,newLeadLst);
        //2017/01/10 プラン→商品明細　by　zy END
        //checkMessage();
        saveFlag = true;
	}
	//2017/01/10 プラン→商品明細　by　zy BEGIN
	private void updateEstemBooking(List<LeadIndex__c> subIdx,List<Lead__c> insLst){
		updateEstemBooking(subIdx,insLst,new Map<String,Set<String>>(),new Map<String,ProductInfo> ());
	}
	private void updateEstemBooking(List<LeadIndex__c> subIdx,List<Lead__c> insLst,Map<String,Set<String>> orgSubMap,Map<String,ProductInfo> planToAccount){
		//2017/06/26 見積もり明細の価格対応　by　zy　BEGIN
		Map<String,List<BookingEstimateItem__c>> exitBookingEst = new Map<String,List<BookingEstimateItem__c>>();
		//2017/06/26 見積もり明細の価格対応　by　zy　END
		//既存変更前のデータ削除する
		if (!orgSubMap.isEmpty()){
			List<Id> exitLeadLst = new List<Id>();
			for (Lead__c l : insLst) {
				exitLeadLst.add(l.id);
			}
			//2017/06/26 見積もり明細の価格対応　by　zy　BEGIN
			Set<String> accountIds = new set<String>();
			for (String leadId : orgSubMap.keySet()) {
				accountIds.addAll(orgSubMap.get(leadId));
			}
			//List<BookingEstimateItem__c> delItems = new List<BookingEstimateItem__c>();
			for( BookingEstimateItem__c book : [select id,refAccountMaster__c,refBooking__c,PlanRefreshFlg__c from BookingEstimateItem__c 
													where refBooking__c = :exitLeadLst and refAccountMaster__c= :accountIds
															and ParentBookingItemRef__c = null order by rowNo__c]){
				String searchKey = book.refBooking__c;
				if (!exitBookingEst.containsKey(searchKey)) exitBookingEst.put(searchKey,new List<BookingEstimateItem__c>());
				exitBookingEst.get(searchKey).add(book);
				/*
				if(orgSubMap.containsKey(book.refBooking__c) && orgSubMap.get(book.refBooking__c).contains(book.refAccountMaster__c)) {
					delItems.add(book);
				}*/
				//2017/06/26 見積もり明細の価格対応　by　zy　END
			}
			//2017/06/26 見積もり明細の価格対応　by　zy　BEGIN
			//delete delItems;
			//2017/06/26 見積もり明細の価格対応　by　zy　END
		}
		//新規変更後のデータを作成
		Map<String,AccountMaster__c> subAccMap = new Map<String,AccountMaster__c>();
		Map<String,String> subIdToAccMap = new Map<String,String>();
		List<BookingEstimateItem__c> insBookingLst = new List<BookingEstimateItem__c>();
		Map<String,LeadIndex__c> subIndexMap = new Map<String,LeadIndex__c>();
		for (LeadIndex__c leadIdx : subIdx) {
			//2017/06/26 見積もり明細の価格対応　by　zy　BEGIN
			if (!CommUtils.isBlank(leadIdx.AccountMasterRef__c)) 
			//2017/06/26 見積もり明細の価格対応　by　zy　END
				subIdToAccMap.put(leadIdx.id,leadIdx.AccountMasterRef__c);
			else if (!CommUtils.isBlank(leadIdx.PlanRef__c)) {
				ProductInfo p = planToAccount.get(leadIdx.PlanRef__c);
				if (p != null) {
					subIdToAccMap.put(leadIdx.id,p.acc.id);
				}
			//无商品处理
			} else subIdToAccMap.put(leadIdx.id,null);
			subIndexMap.put(leadIdx.id,leadIdx);
		}
		if (!subIdToAccMap.isEmpty()) {
			for (AccountMaster__c acc : [select id,name,field5__c,actionType__c from AccountMaster__c where id = :subIdToAccMap.values()]) {
				subAccMap.put(acc.id,acc);
			}
			//2017/06/26 見積もり明細の価格対応　by　zy　BEGIN
			List<BookingEstimateItem__c> delItems = new List<BookingEstimateItem__c>();
			//2017/06/26 見積もり明細の価格対応　by　zy　END
//system.debug(logginglevel.info,'insLst:::' + insLst);
//system.debug(logginglevel.info,'exitBookingEst::::' + exitBookingEst);
			for (Lead__c l : insLst) {
				String searchKey = l.id;
				if (subIdToAccMap.containsKey(l.LeadIndexSubId__c)) {
					String accId = subIdToAccMap.get(l.LeadIndexSubId__c);
					//商品变更成无商品的时候
					if (CommUtils.isBlank(accId)) {
						if (exitBookingEst.containsKey(searchKey)) delItems.addAll(exitBookingEst.get(searchKey));
						continue;
					}
					if (!subAccMap.containsKey(accId)) continue;
					LeadIndex__c subIndex = subIndexMap.get(l.LeadIndexSubId__c);
					AccountMaster__c acc = subAccMap.get(accId);
					//2017/06/26 見積もり明細の価格対応　by　zy　BEGIN
					BookingEstimateItem__c  b = new BookingEstimateItem__c(refBooking__c = l.id);
					//2017/07/05 多見積もり明細が削除できない　by zy BEGIN
					List<BookingEstimateItem__c> chgItemLst = new List<BookingEstimateItem__c>();
					//2017/07/05 多見積もり明細が削除できない　by zy END
					if (exitBookingEst.containsKey(searchKey)) {
						//2017/07/05 多見積もり明細が削除できない　by zy BEGIN
						//不进行删除，讲所有关联商品价格更改掉，
						//此处既存的見積もり明細不会带有上次的商品，因为更改商品交给予約のfield310进行判断
						List<BookingEstimateItem__c> itemLst = exitBookingEst.get(searchKey);
						for (BookingEstimateItem__c item : itemLst) {
							//相同商品
							//if (item.refAccountMaster__c == acc.id) {
							item.ProductName__c = acc.Name;
							//トリガー中
							item.PlanRefreshFlg__c = !item.PlanRefreshFlg__c;
							if (CommConst.APPOTION_LEAD_STAYPERSIONS_SYNCTO_ESTITEM_FLG) item.Amount__c = l.StayPersons__c;
		               		item.refAccountMaster__c = acc.id;
		               		item.PlanDetailSyncInfo__c = subIndex.PlanDetailSyncInfo__c;
			                item.SpTotal__c = null;
			               	item.UnitPrice__c = CommUtils.nullToZero(subIndex.SalesPrice__c);
			               	//２０１７・０７・０５　商品種別追加　by　zy　BEGIN
			               	item.ActionType__c = acc.ActionType__c;
			               	//２０１７・０７・０５　商品種別追加　by　zy　END
		               		chgItemLst.add(item);
							//} 
						}
						/*
						//获取第一个
						b = exitBookingEst.get(searchKey)[0];
						//将第一个删除
						exitBookingEst.get(searchKey).remove(0);
						if (!exitBookingEst.get(searchKey).isEmpty()) delItems.addAll(exitBookingEst.get(searchKey));
						b.PlanRefreshFlg__c = !b.PlanRefreshFlg__c;
						b.ProductName__c = acc.Name;
					//2017/07/05 既存の予約データは人数変更カスタム設定制御、新規データは制御ない　by　zy BEGIN
						if (CommConst.APPOTION_LEAD_STAYPERSIONS_SYNCTO_ESTITEM_FLG) 
	               		b.Amount__c = l.StayPersons__c;
	               		*/
	               		//2017/07/05 多見積もり明細が削除できない　by zy END
					} 
					//2017/07/05 多見積もり明細が削除できない　by zy BEGIN
					//新規の場合
					if (chgItemLst.isEmpty()) {
						// 2017/07/05 人数０の場合、見積もり明細作成できない　by zy BEGIN
						// 2018/01/26 予約人數が０の場合、登録の明細は見積明細へ反映できない by zy BEGIN
						//if (l.StayPersons__c == 0 ) continue;
						// 2018/01/26 予約人數が０の場合、登録の明細は見積明細へ反映できない by zy END
						// 2017/07/05 人数０の場合、見積もり明細作成できない　by zy END
						b.ProductName__c = acc.Name;
						b.Amount__c = l.StayPersons__c;
						//2017/07/05 既存の予約データは人数変更カスタム設定制御、新規データは制御ない　by　zy END
						b.refAccountMaster__c = acc.id;
						b.PlanDetailSyncInfo__c = subIndex.PlanDetailSyncInfo__c;
		                b.SpTotal__c = null;
		               	//2017/06/26 見積もり明細の価格対応　by　zy　END
						//2017/01/18 価格の小数点のbug fix by zy BEGIN
		               	b.UnitPrice__c = CommUtils.nullToZero(subIndex.SalesPrice__c);
		               	//2017/01/18 価格の小数点のbug fix by zy END
		               	//２０１７・０７・０５　商品種別追加　by　zy　BEGIN
		               	b.ActionType__c = acc.ActionType__c;
		               	//２０１７・０７・０５　商品種別追加　by　zy　END
						insBookingLst.add(b);
					// 既存データ
					} else {
						insBookingLst.addAll(chgItemLst);
					}
					//2017/07/05 多見積もり明細が削除できない　by zy END
				//新規予約の場合、見積もり明細はご存じない
				} 
				/*
				else if (exitBookingEst.containsKey(searchKey)){
					delItems.addAll(exitBookingEst.get(searchKey));
				}*/
			}
			//2017/06/26 見積もり明細の価格対応　by　zy　BEGIN
			if (!delItems.isEmpty()) delete delItems;
			//2017/06/26 見積もり明細の価格対応　by　zy　END
		}
		//2017/06/26 見積もり明細の価格対応　by　zy　END
		// 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
		insBookingLst.addAll(CommLogicProcess.getBathTaxBookEstLst(insLst, insBookingLst));
		// 2020/07/30 入湯税の自動入力機能について改善 WGCH END
		//2017/06/26 見積もり明細の価格対応　by　zy　BEGIN
		//if (!insBookingLst.isEmpty()) insert insBookingLst;
		if (!insBookingLst.isEmpty()) upsert insBookingLst;
		//2017/06/26 見積もり明細の価格対応　by　zy　END
	}
	//2017/01/10 プラン→商品明細　by　zy END
// *************** [予約名変換機能] ***********************
// 2018/04/09 予約名●対応　by　ZY BEGIN
private String convertLeadName (String orgLeadName) {
	return convertLeadName(orgLeadName,false);
}
private String convertLeadName (String orgLeadName,boolean chkPrefixFlag) {
// 2018/04/09 予約名●対応　by　ZY END
	// 予約名切替用キー
	//泊目
	String repRegExpKey1 = LEAD_NAME_PREFIX + '([0-9]+-[0-9]+'+ Label.CONST_008_0110 +')';
	//泊目
	String repRegExpKey2 = '([0-9]+-[0-9]+'+ Label.CONST_008_0110 +')';
	String repRegKey = '';
	
	// 元予約データ名は：999-999泊目+予約名　方式　OR　代表部屋標識+999-999泊目+予約名
	// 上記方式の場合、直接Replace方式で名前再設定を行う
	// 元予約名は 代表部屋標識+予約名の場合、999-999泊目に入り替えする, 予約名の場合、直接 999-999泊目方式に設定する
	String regexpResult1 = orgLeadName.replaceFirst(repRegExpKey1, repRegKey);
	//String regexpResult2 = orgLeadName.replaceFirst(repRegExpKey2, repRegKey);
	String newLeadName = regexpResult1.replaceFirst(repRegExpKey2, repRegKey);
	// 2018/04/09 予約名●対応　by　ZY BEGIN
	// 更新未成功或者仍然含有●
	if (chkPrefixFlag && orgLeadName == newLeadName && newLeadName.startsWith(LEAD_NAME_PREFIX)) {
		// 把所有的●変え空
		newLeadName = newLeadName.replaceFirst(LEAD_NAME_PREFIX,'');
	}
	// 2018/04/09 予約名●対応　by　ZY END
	return newLeadName;
}
public void cancelClonInfo(){
	//leadBaseInf.s.id =  leadBaseInf.orgLeadIndexId;
	// CLONEフラグキャンセルする
	cloneFlag = false;
	// 最新予約情報を取得、更新を行う
	refreshExistLeadInfo();
	// 最新の予約情報を再取得する
	refreshWinLead();
	// 最新取得の情報に対して、Section自動閉めるがどうか処理を行う
	sectionExpandProcess();
}
// *************** 検索機能 ******************* BEGIN
public string searchLabel{get;set;}
public string searchLeadIdxId{get;set;}
// 検索と最新参照からの編集を該当機能を呼び出す
public void queryExistLeadByLeadIndexIdByEdit() {
	//2017/07/23 31.一画面のF5/Commadn+Rで画面Refreshできるように改善対応 by zy BEGIN
	// 保留克隆状态
	boolean prvCloneFlag = cloneFlag;
	//2017/07/23 31.一画面のF5/Commadn+Rで画面Refreshできるように改善対応 by zy END
	// 予約インデックス情報を取得する
	queryExistLeadByLeadIndexId();
	// 該当データのレイアウト情報を取得する
	String leadIdxLayoutNo = CommUtils.nullToBlank(leadBaseInf.s.BookingFlexAppLayoutNo__c);
	// 最新のレイアウトNoを設定する
	curLayoutId = getSection(leadIdxLayoutNo);
	// 最新の予約情報を再取得する
	refreshWinLead();
	// 最新取得の情報に対して、Section自動閉めるがどうか処理を行う
	sectionExpandProcess();
	//2017/07/23 31.一画面のF5/Commadn+Rで画面Refreshできるように改善対応 by zy BEGIN
	// 如果刷新之前是克隆状态，则回归克隆状态
	if ( prvCloneFlag ) {
		preCopyAction();
	}
	//2017/07/23 31.一画面のF5/Commadn+Rで画面Refreshできるように改善対応 by zy END
}
// 画面から切替NOを指定する場合
public void changeLayoutNo() {
	//　指定のレイアウトNOへ切替する
	getSection(curLayoutId);
	// 最新の予約情報を再取得する
	refreshWinLead();
	// 最新取得の情報に対して、Section自動閉めるがどうか処理を行う
	sectionExpandProcess();
}

private void queryExistLeadByLeadIndexId () {
	// 予約親と予約明細両方共対応する
	String whereStr = 'where id = :searchLeadIdxId limit 1';
	List<LeadIndex__c> ldIndexLst = Database.query(queryLeadIndexStr + whereStr);
	//予約インデックス情報を見つかりません。
	if (ldIndexLst.isEmpty()) throw new CommException(Label.MSG_001_0066);
	// データが存在する場合[基本情報を設定する]
	//2016/12/29 予約初期化処理 by Zy begin
	newLead = new Lead__c(
        	  RecordTypeId = bookRecTypeId,
        	  Field2__c = ldIndexLst[0].Channel__c,
        	  Segment__c = ldIndexLst[0].Segment__c,
        	  RelContact__c = ldIndexLst[0].contactRef__r.Id);
    leadBaseInf = new LeadBaseInfo(ldIndexLst[0],
        	newLead,
        	ldIndexLst[0].contactRef__r );
	// 過去日付判断チェックを行う
	//if (ldIndexLst[0].EntryDate__c < Date.today()) isOldDayFlg = true;
    // 取得する
    setLeadSubLst(leadBaseInf.s.Id);
    
    // チェックインボタン表示制御
    if (ldIndexLst[0].EntryDate__c <= Date.today() &&
    	ldIndexLst[0].DepartureDate__c >= Date.today() ) {
		isCanCheckinFlg = isHaveNoCheckinData(ldIndexLst[0].Id);
	} else {
		isCanCheckinFlg = false;
	}
	//2016/12/29 予約初期化処理 by Zy END
	
	//2017/01/12 new lead refresh by zy BEGIN
	//refreshWinLead();
	//2017/01/12 new lead refresh by zy END
	
 	saveFlag = true;
	cloneFlag = false;
	// 2016/11/21 新規予約　チェックイン　エラー修正　
	//checkMessage();
}
//2017/01/12 new lead refresh by zy BEGIN
//主部屋の予約ダーたを作成
private void refreshWinLead(){
	//2017/01/19 切换的时候默认值设定 by zy BEGIN
	if (CommUtils.isBlank(searchLeadIdxId)) { 
		newLead = cloneNewLead.clone(false,true);
		newLead.ReservedDate__c = System.now();
		// 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
		// チェックイン時刻、チェックアウト時刻
        //newLead.Field4__c = CommConst.DEF_CHECKIN_TIME;
        //newLead.Field3__c = CommConst.DEF_CHECKOT_TIME;
        newLead.Field4__c = JS_DEFCHKIN_DT;
        newLead.Field3__c = JS_DEFCHKOT_DT;
        // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
         if (leadBaseInf.c.id != null) newLead.relcontact__c = leadBaseInf.c.id;
		return;
	}
	//2017/01/19 切换的时候默认值设定 by zy END
	Integer leadCancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
	Set<String> excludeSet = new Set<String>{'Relcontact__r.name'};
	String queryStr = 'select Relcontact__r.name ';
	if (!leadCustomFieldLst.isEmpty()){
		for (String fieldName : leadCustomFieldLst) {
			if (!excludeSet.contains(fieldName))
				queryStr += ',' + fieldName;
		}
	}
	//String leadQueryStr = CommSqlUtils.generateQueryString('Lead__c',new String[]{'Relcontact__r.name'}) +
	String leadQueryStr = queryStr + ' from Lead__c ' + 
                            ' Where CancelBool__c != :leadCancelFlg ' +
                            ' And LeadIndexRef__c = :searchLeadIdxId '+
                            // 2016/12/30 親SUBのフラグ追加　by　zy  BEGIN
                            ' And LeadIndexSubId__c = :parentSubId' + 
                            // 2016/12/30 親SUBのフラグ追加　by　zy  END
                            ' Order by LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c, EntryTime__c limit 1';
	List<Lead__c> existLeads = Database.query(leadQueryStr);
	//2016/12/29 予約初期化処理 by Zy begin
	if(!existLeads.isEmpty()){
		newLead = existLeads[0];
		//若存在nead的情况下用leadindex leadname
		
		if(leadBaseInf.s != null && !CommUtils.isBlank(leadBaseInf.s.LeadName__c))        
	    	newLead.name = leadBaseInf.s.LeadName__c;
		// 編集画面
        isEditPage = true;
       //2016/12/30 親sub設定 by Zy begin
	} 
	//else isEditPage = false;
		//2016/12/30 親sub設定 by Zy END
	//2016/12/29 予約初期化処理 by Zy END
	String contactQuery = CommSqlUtils.generateQueryString('Contact');
	String contactId = newLead.RelContact__c;
	if(!CommUtils.isBlank(contactId)){
		contactQuery += ' where id=:contactId';
		List<Contact> contactResult = Database.query(contactQuery);
		newContact = contactResult[0];
	}
	contactName = newContact.name;
	// 予約情報の最新情報はコピー格納する
	oldLead = newLead.clone(true,true);
}
//2017/01/12 new lead refresh by zy END
// *************** 検索機能 ******************* END
	//会計ポタンの関連フラグ
	//2017/01/10 会計ポタン　の追加　by zy BEGIN
	public Boolean hadAccFlag{get;set;}
	private final static String CONST_BILLSIMLEINPUT = '/apex/BillSimpleInput';
	//2017/01/10 会計ポタン　の追加　by zy END
    // 宿泊者名簿

	// 支払方式
    public List<Selectoption> paymentTypeLst{get; private set;}
    public String leadJson{get;set;}
    // 予約INDEX明細（SUB）設定を行う
	private void setLeadSubLst(String leadIdxId) {
		// 2019/11/15 一括予約のコピー時にアサインされている部屋もコピーしてほしい、アサイン部屋もコピーしないと手間が増えてしまいます。by zy BEGIN
		selRoomModeFlg = Commconst.BOOKING_FLEX_SEL_ROOM_FLG;
		initReleatSet();
		// 2019/11/15 一括予約のコピー時にアサインされている部屋もコピーしてほしい、アサイン部屋もコピーしないと手間が増えてしまいます。by zy END
		// 格納用配列初期化
		oLeadLst = new List<LeadItem>();
		// 2016/12/30 親SUBのフラグ追加　by　zy  BEGIN
		parentSubId = '';
		// 2016/12/30 親SUBのフラグ追加　by　zy  END
		// 2017/12/25 親部屋機能処理　by　zy BEGIN
		// 2016/12/30 親SUBのフラグ追加　by　zy  BEGIN
		//isOyaInputFlag = true;
		// 2016/12/30 親SUBのフラグ追加　by　zy  END
		//String tempParentSubId = '';
		// 2017/12/25 親部屋機能処理　by　zy END
		// 予約インデックスID
		if (leadIdxId != null) {
			// 2017/04/06 キャンセルの予約データは改修する　by　zy BEGN
			Map<Id,List<Lead__c>> subLeadsMap= new Map<Id,List<Lead__c>>();
			Set<Id> leadSet = new Set<Id>();
			String strRoomDelegatePrefix = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomDelegatePrefix__c);
			// 2017/12/25 親部屋機能処理　by　zy BEGIN
			Set<String> mainLeadNameSet = new Set<String>();
			// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy BEGIN
			Set<String> hadLockSet = new Set<String>();
			// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy END
			for (Lead__c lead : [select id,EntryTime__c,LeadIndexSubId__c,name,RoomGroupNo__c,LeadIndexRef__c,rroom__c,Rroom__r.name,Field276__c from Lead__c where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
			// 2017/12/25 親部屋機能処理　by　zy END							
										And LeadIndexRef__c = :leadIdxId order by LeadIndexSubId__c, RoomGroupNo__c, EntryTime__c]){
				if(!subLeadsMap.containsKey(lead.LeadIndexSubId__c))
						subLeadsMap.put(lead.LeadIndexSubId__c,new List<Lead__c>());
				subLeadsMap.get(lead.LeadIndexSubId__c).add(lead);
				leadSet.add(lead.id);	
				// 2017/12/25 親部屋機能処理　by　zy BEGIN
				/*
				if (isOyaInputFlag){
					if(lead.name.contains(strRoomDelegatePrefix)){
						isOyaInputFlag = false;
						parentSubId = lead.LeadIndexSubId__c;
					}
				}
				*/	
				// 2017/12/25 親部屋機能処理　by　zy END
				// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy BEGIN
				if (lead.Field276__c && !CommUtils.isBlank(lead.LeadIndexSubId__c)) 
					hadLockSet.add(lead.LeadIndexSubId__c);
				// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy END
			}
			// 2017/03/29 親部屋キャンセルの予約データbug fix by zy END
			//予約インデックスSUB
	        List<LeadIndex__c> indexSub = [
	        								select name, LeadName__c, SalesPrice__c, PlanRef__c, Nights__c, DepartureDate__c, EntryDate__c, RoomTypeRef__c
	        											, Rooms__c, ParentLeadIndxRef__c,StayPersons__c,ExtraBedChk__c 
	        											, EntryTime__c ,DepartureTime__c,PlanDetailSyncInfo__c
	        											, StatusLst__c 
	        											// 2016/12/30 親SUBのフラグ追加　by　zy 
	        											, ParentFlg__c
	        											//2017/01/10 プラン→商品明細　by　zy BEGIN
	        											, PlanRef__r.name, AccountMasterRef__c,AccountMasterRef__r.name,AccountMasterRef__r.ActionType__c
	        											//2017/01/10 プラン→商品明細　by　zy END
	        								from LeadIndex__c 
	        								//親部屋キャンセルの予約データbug fix by zy BEGIN
	        								where id = :subLeadsMap.keySet()  order by name];
	        								//where ParentLeadIndxRef__c = :leadIdxId  order by name];
	        								//親部屋キャンセルの予約データbug fix by zy END
			Set<Id> subIndexIdSet = new Set<Id>();
			//Set<Id> planIdSet = new Set<Id>();
			Map<Id, Id> subIdxPlanMap = new Map<Id, Id>();
			boolean hadChkFlag = false;
			for (LeadIndex__c item : indexSub) {
				if (item.PlanRef__c != null && CommUtils.nullToZero(item.SalesPrice__c) == 0) {
					// PlanId存在、売価非存在場合、該当データに関連付く予約見積り明細のプラン商品の単価値を取得、画面に表示を行う
					//subIndexIdSet.add(item.Id);
					//planIdSet.add(item.PlanRef__c);
					subIdxPlanMap.put(item.Id, item.PlanRef__c);
				}
				// 2017/12/25 親部屋機能処理　by　zy BEGIN
				/*
				// 2016/12/30 親SUBのフラグ追加　by　zy  BEGIN
				if ( !hadChkFlag && item.ParentFlg__c) {
					isOyaInputFlag = false;
					// 2017/06/21　親部屋選別機能追加　by　zy　BEGIN 
					if (item.ParentLeadIndxRef__c != leadIdxId) {
						tempParentSubId = item.id;
					} else {
						hadChkFlag = true;
						parentSubId = item.id;
					}
					// 2017/06/21　親部屋選別機能追加　by　zy　END 
				}
				// 2016/12/30 親SUBのフラグ追加　by　zy  END
				*/
				// 2017/12/25 親部屋機能処理　by　zy END
				subIndexIdSet.add(item.Id);
			}
			// 2017/01/10 查找有会计数据的予约数据  by zh BEGIN
			//2017/01/10 会計ポタン　の追加　by zy BEGIN
			hadAccFlag = isExistVoidAccountInfo(leadIdxId,null);
			//2017/01/10 会計ポタン　の追加　by zy END
			// 2017/01/10 查找有会计数据的予约数据  by zh END
//System.debug(logginglevel.info,':::: subIndexIdSet ::::' + subIndexIdSet);
//System.debug(logginglevel.info,':::: leadIdxId ::::' + leadIdxId);			
//System.debug(logginglevel.info,':::: CommConst.LEAD_ST_CANCEL_FLG ::::' + CommConst.LEAD_ST_CANCEL_FLG);		
			// 各SUBINDEXに、有効な予約データ存在チェックする
			Set<Id> subIdxHaveLeadSet = new Set<Id>();
			/* 2017/09/14 性能問題改善対応 BEGIN
			for (AggregateResult r : [	select LeadIndexSubId__c subId,id leadId from Lead__c 
										where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
										And LeadIndexSubId__c = :subIndexIdSet
										And LeadIndexRef__c = :leadIdxId
										Group By LeadIndexSubId__c,id]) {
				// 該当予約インデックスSUBに関連付くの有効な予約データは存在する場合
				subIdxHaveLeadSet.add((Id)r.get('subId'));
			}*/
			List<sObject> results = [   select LeadIndexSubId__c subId from Lead__c 
                                        where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
                                        And LeadIndexSubId__c = :subIndexIdSet
                                        And LeadIndexRef__c = :leadIdxId
                                        Group By LeadIndexSubId__c];
            for(sObject r : results ) {
                // 該当予約インデックスSUBに関連付くの有効な予約データは存在する場合
                subIdxHaveLeadSet.add((Id)r.get('subId'));
            }   
            // 2017/09/14 性能問題改善対応 END                  
			/* 2017/04/06 キャンセルの予約データは改修する　by　zy BEGN
			Map<Id,List<Lead__c>> subLeadsMap= new Map<Id,List<Lead__c>>();
			Set<Id> leadSet = new Set<Id>();
			String strRoomDelegatePrefix = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomDelegatePrefix__c);
			for (Lead__c lead : [select id,EntryTime__c,LeadIndexSubId__c,name from Lead__c where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
										And LeadIndexSubId__c = :subIndexIdSet
										And LeadIndexRef__c = :leadIdxId order by LeadIndexSubId__c, RoomGroupNo__c, EntryTime__c]){
				if(!subLeadsMap.containsKey(lead.LeadIndexSubId__c))
						subLeadsMap.put(lead.LeadIndexSubId__c,new List<Lead__c>());
				subLeadsMap.get(lead.LeadIndexSubId__c).add(lead);
				leadSet.add(lead.id);
				// 2016/12/30 親SUBのフラグ追加　by　zy  BEGIN
				if (isOyaInputFlag){
					if(lead.name.contains(strRoomDelegatePrefix)){
						isOyaInputFlag = false;
						parentSubId = lead.LeadIndexSubId__c;
					}
				}
				// 2016/12/30 親SUBのフラグ追加　by　zy  END				
			} 2017/04/06 キャンセルの予約データは改修する　by　zy END*/
			// 各SUBINDEXに、チェックインデータあり・なし判断処理を行う
			Map<Id, Integer> checkInStatusMap = new Map<Id, Integer>();
			/* 2017/09/14 性能問題改善対応
			for (AggregateResult r : [	select LeadIndexSubId__c subId, count(Id) checkinNums from Lead__c 
										where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG And Field298__c != null 
										And LeadIndexSubId__c = :subIdxHaveLeadSet
										And LeadIndexRef__c = :leadIdxId
										Group By LeadIndexSubId__c]) {
				// SubIndexの予約データのチェックインステータス判別
				checkInStatusMap.put((Id)r.get('subId'), (Integer)r.get('checkinNums'));
			}*/
			List<sObject> results2 = [  select LeadIndexSubId__c subId, count(Id) checkinNums from Lead__c 
                                        where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG And Field298__c != null 
                                        And LeadIndexSubId__c = :subIdxHaveLeadSet
                                        And LeadIndexRef__c = :leadIdxId
                                        Group By LeadIndexSubId__c];
			for(sObject r : results2 ) {
			    // SubIndexの予約データのチェックインステータス判別
                checkInStatusMap.put((Id)r.get('subId'), (Integer)r.get('checkinNums'));
			}
			// 2017/09/14 性能問題改善対応 END
			// プランから会計商品(プラン)IDを取得する
			// プランID / 会計商品(プラン)ID
	        Map<Id, Id> planProdMap = new Map<Id, Id>();
            /* 2017/09/14 性能問題改善対応
	        for (AggregateResult r : [select PlanRef__c planRef, min(PlanProdcut__c) planProdId
	        	from PlanDetail__c where PlanRef__c in :subIdxPlanMap.values() and PlanProdcut__c != null group by PlanRef__c]) {
	        	planProdMap.put((Id)r.get('planRef'), (Id)r.get('planProdId'));
	        }
            */
            if (!subIdxPlanMap.isEmpty()) {
	            List<sObject> results3 = [select PlanRef__c planRef, min(PlanProdcut__c) planProdId
	                from PlanDetail__c where PlanRef__c in :subIdxPlanMap.values() and PlanProdcut__c != null group by PlanRef__c];
	            for(sObject r : results3 ) {
	                planProdMap.put((Id)r.get('planRef'), (Id)r.get('planProdId'));
                }
            }
			// プランIDから、会計商品のIDを取得する、該当商品IDで、見積り明細の商品情報を比較して、単価を取得する
			// 見積り明細：会計商品　＝　会計商品（プラン）　AND　
			Map<Id, Decimal> salesPriceMap = new Map<Id, Decimal>();
			if (!subIdxPlanMap.isEmpty()) {
			    /* 2017/09/14 性能問題改善対応
				for (AggregateResult r : [select refBooking__r.LeadIndexSubId__c subIdxId, max(UnitPrice__c) price from BookingEstimateItem__c
					 where refBooking__r.LeadIndexSubId__c in :subIdxPlanMap.keySet() And refAccountMaster__r.ActionType__c = 'プラン'
					 And refAccountMaster__c in :planProdMap.values()
				 	 group by refBooking__r.LeadIndexSubId__c ]) {
					salesPriceMap.put((Id)r.get('subIdxId'), (Decimal)r.get('price'));
				}*/
                List<sObject> results4 = [select refBooking__r.LeadIndexSubId__c subIdxId, max(UnitPrice__c) price from BookingEstimateItem__c
                     where refBooking__r.LeadIndexSubId__c in :subIdxPlanMap.keySet() And refAccountMaster__r.ActionType__c = :CommConst.PROD_ACTION_TYPE_PL
                     And refAccountMaster__c in :planProdMap.values()
                     group by refBooking__r.LeadIndexSubId__c ];
                for(sObject r : results4 ) {
                    salesPriceMap.put((Id)r.get('subIdxId'), (Decimal)r.get('price'));
                }
			}
			/*
			Map<Id,List<BookingEstimateItem__c>> subItemsMap = new Map<Id,List<BookingEstimateItem__c>>();
			
			for (BookingEstimateItem__c b : [select amount__c ,unitprice__c , id ,refAccountMaster__c,refAccountMaster__r.name,refBooking__c,ActionType__c,PaymentType__c,UnitPriceDefKb__c,
														   PlanDetailSyncInfo__c ,refBooking__r.LeadIndexSubId__c,refBooking__r.EntryTime__c,SpTotal__c,SpecialTax__c,Total__c,GoukeinoneTax__c,
														   TaxRate__c,ServiceRate__c
													from BookingEstimateItem__c 
													where refBooking__c = :leadSet and ParentBookingItemRef__c = null Order By RowNo__c,Name]) {
					if(!subItemsMap.containsKey(b.refBooking__r.LeadIndexSubId__c))
						subItemsMap.put(b.refBooking__r.LeadIndexSubId__c,new List<BookingEstimateItem__c>());
					subItemsMap.get(b.refBooking__r.LeadIndexSubId__c).add(b);
			}*/
//System.debug(':::: salesPriceMap ::::' + salesPriceMap);
//System.debug(logginglevel.info,':::: indexSub ::::' + indexSub);
//System.debug(logginglevel.info,':::: subIdxHaveLeadSet ::::' + subIdxHaveLeadSet);
			// 2017/12/25 親部屋機能処理　by　zy BEGIN
			// 親予約インデックス区分
			indexSub = getParentSubId(indexSub,leadIdxId,mainLeadNameSet);
			// 2017/12/25 親部屋機能処理　by　zy END
			for (LeadIndex__c item : indexSub) {
				// ダミの明細情報(有効な予約データがない)は表示対象外
				if (!subIdxHaveLeadSet.contains(item.Id)) continue;
				// プランの売価情報を設定する
				if (item.PlanRef__c != null && CommUtils.nullToZero(item.SalesPrice__c) == 0) {
					item.SalesPrice__c = salesPriceMap.get(item.Id);
				}
				// 2017/12/25 親部屋機能処理　by　zy BEGIN
				/*
				// 2017/12/25 親部屋機能処理　by　zy END
				// 2016/12/30 親SUBのフラグ追加　by　zy  BEGIN
				if (!CommUtils.isBlank(item.id)){
					if (isOyaInputFlag){
						parentSubId = item.id;
						isOyaInputFlag = false;
					}
					//if ( !isOyaInputFlag && parentSubId == item.id && !item.ParentFlg__c){
					// 2017/06/21　親部屋選別機能追加　by　zy　BEGIN 
					if ((!CommUtils.isBlank(parentSubId) && parentSubId == item.id) 
						|| ( !CommUtils.isBlank(tempParentSubId) && tempParentSubId == item.id ) ) item.ParentFlg__c = true;
					// 2017/06/21　親部屋選別機能追加　by　zy　END 
					else item.ParentFlg__c = false;
				// 2017/12/25 親部屋機能処理　by　zy BEGIN
				}*/
				// 2017/12/25 親部屋機能処理　by　zy BEGIN
				// 2016/12/30 親SUBのフラグ追加　by　zy  END
				LeadItem leadItem = new LeadItem(item, oLeadLst.size());
				// 2017/06/21　親部屋選別機能追加　by　zy　BEGIN 
				if (!CommUtils.isBlank(parentSubId) && parentSubId == item.id) leadItem.s.ParentFlg__c = true;
				else leadItem.s.ParentFlg__c = false;
				// 2017/06/21　親部屋選別機能追加　by　zy　END 
				//System.debug(logginglevel.info,':::: leadItem ::::' + leadItem);
				//System.debug(logginglevel.info,':::: subLeadsMap ::::' + subLeadsMap);
				//if(subLeadsMap.containsKey(item.Id))
				//leadItem.setLeadLst(subLeadsMap.get(item.Id),subItemsMap.get(item.Id));
				// 2019/11/15 一括予約画面の部屋直接選択 by zy BEGIN
				if (selRoomModeFlg) {
					//LeadItem orgLeadItem = leadItem;
					List<Lead__c> leads = subLeadsMap.get(item.Id);
					if (!leads.isEmpty()) leadItem.roomName = leads[0].rroom__r.name;
					if (leadItem.s.Rooms__c > 1) selRoomModeFlg = false;				
				} 
				// else 
				// 2019/11/15 一括予約画面の部屋直接選択 by zy END
				// 表示の明細情報を格納する
				oLeadLst.add(leadItem);
				//2017/01/10 会計ポタン　の追加　by zy BEGIN
				if (hadAccFlag) {
					if (leadItem.isParentFlag) {
						parId = leadItem.s.id;
						psub = leadItem.s.id + ',';
					} else psub += leadItem.s.id + ',';
				}
				//2017/01/10 会計ポタン　の追加　by zy END
				// 既にチェックイン場合、Readonly設定する
				if (checkInStatusMap.containsKey(item.id) && checkInStatusMap.get(item.Id) > 0) {
					oLeadLst[oLeadLst.size()-1].isReadOnly = true;
					// チェックインありフラグ設定
					isExistCheckIn = true;
				}
				// 2016/04/06 ご予約情報はキャンセルから復活する BEGIN
				oLeadLst[oLeadLst.size()-1].isCancel = false;
				// 2016/04/06 ご予約情報はキャンセルから復活する END
				// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy BEGIN
				leadItem.isLockFlag = hadLockSet.contains(item.id);
				// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy END
			}
		}
    	//2017/01/10 行追加　by　zy BEGIN
		// Dumy Data AutoSetup
		// 2017/01/16 统一行追加功能改修 by wsq BEGIN
		//Integer dumyDataLen = oLeadLst.size() >= defInputLines ? 5 : (defInputLines - oLeadLst.size());
		Integer dumyDataLen = defInputLines - Math.Mod(oLeadLst.size(), defInputLines);
		// 2017/01/16 统一行追加功能改修 by wsq END
		addSubIdxItem(dumyDataLen);
		/*
		for (Integer i = 0; i < dumyDataLen; i++) {
			oLeadLst.add(new LeadItem(new LeadIndex__c(EntryTime__c='', DepartureTime__c=''), oLeadLst.size()));
		}*/
		//2017/01/10 行追加　by　zy END
		//system.debug(logginglevel.info,'oLeadLst:::' + oLeadLst);
        // 宿泊者名簿
        //oGuestLst = new List<ContactItem>();
        // プラン初期情報設定
        //oPlanInfo = new PlanInfoItem();
        //若存在nead的情况下用leadindex leadname
		if(leadBaseInf.s != null && !CommUtils.isBlank(leadBaseInf.s.LeadName__c))        
        newLead.name = leadBaseInf.s.LeadName__c;
	}

	/**
	* プラン明細情報表示情報
	*
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
	*/
	public String parId{set;get;}
	public String psub{get;set;}
	public PageReference redirectChkIn(){
		Id leadIndexId = leadBaseInf.s.Id;
		List<String> psubLst = new List<String>();
		if(!CommUtils.isBlank(psub))
			psubLst = psub.split(',');
		List<Lead__c> checkinLst = new List<Lead__c>();
		for(Lead__c lead : [select Field298__c from Lead__c where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 
								               // And DAY_ONLY(convertTimezone(EntryTime__c)) = :todayDt
								                And Field298__c = null 
								                And LeadIndexSubId__c = :psubLst
								                And LeadIndexRef__c = :leadIndexId ]) {
			  lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
			  checkinLst.add(lead);
		}
		try {
			if (!checkinLst.isEmpty()) update checkinLst;
		} catch (Exception e) {
			String errMsg = e.getMessage();
            if(!CommUtils.isFieldValidationMessage(errMsg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
            return null;
		}
		// 2017/05/04 自施設の予約や会計しか変更できないように権限管理機能 END
		// 2017/06/29 チャックインのデータは会計保存エラー処理する　by　zy BEGIN
		for (LeadItem item : oLeadLst) {
			if(item.s.ParentFlg__c){
				parId = item.s.id;
			}
		}
		// 2017/06/29 チャックインのデータは会計保存エラー処理する　by　zy END
		// ページ遷移前のチェックを行う
        Map<String,String> paramMap = new Map<String,String>();
        paramMap.put('p01_psub',psub);
        paramMap.put('p01_parid',parId);
        paramMap.put('retURL','/apex/BookingFlexApp?id=' + leadBaseInf.s.Id);
		PageReference customPage = new PageReference( CONST_BILLSIMLEINPUT);
		customPage.getParameters().putAll(paramMap);
		customPage.setRedirect(true);

		return customPage;
	}
	//2017/01/10 会計ポタン　の追加　by zy BEGIN
	public PageReference redirectKaikei(){
		// ページ遷移前のチェックを行う
        Map<String,String> paramMap = new Map<String,String>();
        paramMap.put('p01_psub',psub);
        paramMap.put('p01_parid',parId);
        // 画面にチェックBOXを指定する場合、指定のSUBINDEXの関連のご予約の会計情報が存在する・しないをチェックする
        List<String> subIndexLst = CommUtils.nullToBlank(psub).split(',');
    	if (!isExistVoidAccountInfo(leadBaseInf.s.Id, subIndexLst)) {
    		String errMsg = '関連会計情報を見つかりませんため、会計画面へ遷移できません。';
    		Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
    		return null;
    	}
        paramMap.put('retURL','/apex/BookingFlexApp?id=' + leadBaseInf.s.Id);
		PageReference customPage = new PageReference( CONST_BILLSIMLEINPUT);
		customPage.getParameters().putAll(paramMap);
		customPage.setRedirect(true);

		return customPage;
	}
	// 指定の予約インデックス明細「省略可能」
	private Boolean isExistVoidAccountInfo(Id leadIndexId, List<String> psubIdLst) {
		// 指定の予約インデックスは未登録の場合、
		if (CommUtils.isBlank(leadIndexId)) return false;
		// 指定の予約インデックスから有効な会計情報が存在チェックを行う
		String voidFlg = CommConst.ACC_TRADE_NORMAL;
		String checkQuery = 'select id from AccountAcount__c where frs__c !=  null And Relreserve__r.LeadIndexRef__c = :leadIndexId And Field39__c = :voidFlg ';
		if (psubIdLst != null && !psubIdLst.isEmpty()) checkQuery += ' And Relreserve__r.LeadIndexSubId__c = :psubIdLst ';
		checkQuery += ' limit 1 ';
//System.debug(loggingLevel.info, 'checkQuery='+checkQuery);
//System.debug(loggingLevel.info, 'leadIndexId='+leadIndexId);
//System.debug(loggingLevel.info, 'psubIdLst='+psubIdLst);
		List<AccountAcount__c> accountRsLst = DataBase.Query(checkQuery);
		return (accountRsLst.size() > 0);
	}
	//2017/01/10 会計ポタン　の追加　by zy END
	/**
	* 当日分の予約データのチェックイン
	**/
	/*
	public void bulkCheckIn() {
		
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
		if (!checkinLst.isEmpty()) update checkinLst;
		// 最新情報を再取得、設定を行う
		refreshExistLeadInfo();
	}
	*/
    /*
    * IndexSubよて、プラン情報/宿泊者名簿情報を取得、設定を行う
    * actionFunction
    * Case1: 既に予約あり、宿泊者名簿情報なし
    * Case2: 既存予約あり、宿泊者名簿情報あり、グループNO一致しない（実際の予約により、増える、下げる）
    *//*
    public void expandGuestLst() {
    	// 設定の行番号にて、関連の情報を取得、表示を行う
    	oGuestLst = new List<ContactItem>();
    	// プラン明細も初期化する
    	oPlanInfo = new PlanInfoItem();

        if (CommUtils.isBlank(indexSubId)) return;
        
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
	                //item.customKana = sub.contactRef__r.Name;
	                //item.customName = sub.contactRef__r.Name1__c;
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
    }*/
	/**
	* キャンセル処理
	**/
	public void cancelSubDetail() {
		// 指定SUBINDEX明細の予約情報をキャンセルする
Savepoint sp = Database.setSavepoint();   	
try {
		List<String> psubLst = psub.split(',');
		list<LeadIndex__c> cancelLeadIndexSub = [select id,StatusLst__c from LeadIndex__c where id in :psubLst];
		for (LeadIndex__c ldSub : cancelLeadIndexSub) {
			ldSub.StatusLst__c = CommConst.LEAD_ST_CANCEL;
			//2016/12/30 キャンセルのSUBインデックスの親フラグのfalse by zy BEGIN
			ldSub.ParentFlg__c = false;
			//2016/12/30 キャンセルのSUBインデックスの親フラグのfalse by zy END
		}
		list<Lead__c> cancelLeads = [select id, ReservedStatus__c from Lead__c where LeadIndexSubId__c in :psubLst];
		for (Lead__c lead : cancelLeads) {
			lead.ReservedStatus__c = CommConst.LEAD_ST_CANCEL;
			//2017/03/09 一括予約について。予約キャンセル処理後に特記を入力できるように改善対応 By zy BEGIN
			if (lead.id == newLead.id) newLead.ReservedStatus__c = CommConst.LEAD_ST_CANCEL;
			//2017/03/09 一括予約について。予約キャンセル処理後に特記を入力できるように改善対応 By zy END
		}
		if (!cancelLeadIndexSub.isEmpty()) update cancelLeadIndexSub;
		if (!cancelLeads.isEmpty()) update cancelLeads;
		//2016/12/27 予約インデックス下無SUBの場合　画面に初期化 By zy BEGIN
		refreshExistLeadInfo();
		//queryExistLeadByLeadIndexId();
		//2016/12/27 予約インデックス下無SUBの場合　画面に初期化 By zy END
} catch (Exception e) {
	String errMsg = e.getMessage();
	if(!CommUtils.isFieldValidationMessage(errMsg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
	DataBase.rollback(sp);
}
	}
    /**
    * 宿泊名簿登録・更新を行う
    **/
/*
    public void createGuestInfo() {

Savepoint sp = Database.setSavepoint();   	
try {
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
*/
//2017/01/10 行追加　by　zy BEGIN	
	public void addSubIdxItem(){
		addSubIdxItem(null);
	}
	private void addSubIdxItem(Integer dumyDataLen) {
		integer addLength = dumyDataLen == null ? defInputLines : dumyDataLen;
		for (Integer i = 0; i < addLength; i++) {
			oLeadLst.add(new LeadItem(new LeadIndex__c(EntryTime__c='', DepartureTime__c=''), oLeadLst.size()));
		}
	}
//2017/01/10 行追加　by　zy END
//2017/01/10 プラン→商品明細　by　zy BEGIN
	// プランの標準売価を取得する
	@remoteAction
	public static SObject[] getPlanInfos(String planId,String prodId) {
//System.debug('getPlanInfo:planId::::' + planId);
		if (!CommUtils.isBlank(prodId)) {
			List<AccountMaster__c> accLst = [select id, Field5__c  from AccountMaster__c where id  = :prodId];
			Plan__c p  = new Plan__c();
			if (!accLst.isEmpty()) p.Price__c = accLst[0].Field5__c;
			return new List<Sobject>{p};
		}
		return [select id, Price__c from Plan__c where id  = :planId];
	}
	// 商品コードにより、会計商品情報を取得する
	@remoteAction
	public static List<ProductItemUtils.ProductItem> getProductItemInfo(String prodCode) {
		//return ProductItemUtils.getArrayProdcutItemByCode(prodCode);
		return ProductItemUtils.getArrayProdcutItemByCode(prodCode, false, true);
	}
//2017/01/10 プラン→商品明細　by　zy END
	// プランの標準売価を取得する
	@remoteAction
	public static SObject[] getPlanInfo(String planId) {
//System.debug('getPlanInfo:planId::::' + planId);
		return [select id, Price__c from Plan__c where id  = :planId];
	}

    // 部屋存在チェックを行う
    /* 2017/01/19 該当機能削除 WSQ
    @remoteAction
    public static SObject[] getIdleRoom(String roomTypId, String startDt, String endDt, String roomNoFilter) {
System.debug('roomTypId::::' + roomTypId);
System.debug('startDt::::' + startDt);
System.debug('endDt::::' + endDt);
System.debug('roomNoFilter::::' + roomNoFilter);
        // 予約データは期間と部屋タイプにて、部屋在庫データを検索して、アサインできる部屋をチェックする
        Id bookingRecTypeId = CommLogicProcess.getLeadBookingRecType();
        */
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
        /*
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
    }*/
	// プラン明細情報を取得する
	@remoteAction
	public static List<ProductItemUtils.PlanDetail> getPlanDetailListById(String planId) {
		//return ProductItemUtils.getPlanDetailList(planId);
		// プランIDより、プラン明細一覧を取得する
		List<ProductItemUtils.PlanDetail> rsLst = new List<ProductItemUtils.PlanDetail>();
		List<PlanDetail__c> pdLst = [select AccountMasterRef__c,AccountMasterRef__r.name, Price__c,AccountMasterRef__r.ActionType__c from PlanDetail__c where PlanRef__c = :planId];
		if (!pdLst.isEmpty()){
	        for (PlanDetail__c pd : pdLst) {
	            ProductItemUtils.PlanDetail item = new ProductItemUtils.PlanDetail();
	            item.prodName = CommUtils.nullToBlank(pd.AccountMasterRef__r.name);
	            item.prodPrice = CommUtils.nullToZero(pd.Price__c).format();
	            item.actionType = CommUtils.nullToBlank(pd.AccountMasterRef__r.ActionType__c);
	            item.sobjId = pd.Id;
	            item.prodId = pd.AccountMasterRef__c;
	            rsLst.add(item);
	        }
        } else {
        	for (PlanDetail__c pd : [select AccountMasterRef__r.name,AccountMasterRef__c,AccountMasterRef__r.ActionType__c, Price__c,TaxRate__c from PlanDetail__c where PlanProdcut__c = :planId]) {
                ProductItemUtils.PlanDetail item = new ProductItemUtils.PlanDetail();
                item.prodName = CommUtils.nullToBlank(pd.AccountMasterRef__r.name);
                item.prodPrice = CommUtils.nullToZero(pd.Price__c).format();
                item.sobjId = pd.Id;
                item.prodId = pd.AccountMasterRef__c;
                item.actionType = pd.AccountMasterRef__r.ActionType__c;
                //item.prodTaxRate = CommUtils.nullToZero(pd.TaxRate__c);
                rsLst.add(item);
	        }
        }
        
        return rsLst;
	}
	// 商品コードにより、会計商品情報を取得する
	@remoteAction
	public static List<ProductItemUtils.ProductItem> getArrayProductItemInfo(String prodCode) {
		//return ProductItemUtils.getArrayProdcutItemByCode(prodCode);
		return ProductItemUtils.getArrayProdcutItemByCode(prodCode, true, true);
	}
	public String cookieMessage{get;set;}
	public void setCookieInf () {
		if(!CommUtils.isBlank(cookieMessage)){
			List<Cookie> cookies =  new List<Cookie>();
			for (String coo : cookieMessage.split(',')) {
				if(!CommUtils.isBlank(coo)){
					String[] cooMsg = coo.split('\\$');
					// 画面最後利用する画面モードはCookiesに維持する
					Cookie wineCookieShopInfo = new Cookie('_BookingFlexApp_cookie_' + cooMsg[0] + '_message', cooMsg[1] , null, -1, true);
					cookies.add(wineCookieShopInfo);
				}
			}
			
			ApexPages.currentPage().setCookies(cookies);
		}
    }
	private List<Section> secLst;
	public Lead__c newLead{get;set;}
	public Contact newContact{get;set;}
	private Lead__c oldLead{get;set;}
	public Map<String,Boolean> requiredMap{get;set;}
	public String colorStr{get;set;}
	//2016/12/30 予約カスタム項目set by zy BEGIN
	public List<String> leadCustomFieldLst;
	//2016/12/30 予約カスタム項目set by zy BEGIN
	private string getSection(String layoutNo){
		secLst = new List<Section>();
		requiredMap = new Map<String,Boolean>();
		//List<Document> existDocs = [select body, name from Document where Name like :filedName order by CreatedDate];
		//if (existDocs.isEmpty()) return;
    	//Blob xmlBody = existDocs[0].Body;
    	//String strXmlBody = xmlBody.toString();
		//Dom.Document doc = new Dom.Document();
		//doc.load(strXmlBody);
		//Dom.XMLNode root = doc.getRootElement();
		String findLayoutNo = '';
		Dom.XmlNode uerDefLayoutNode = null;
		Dom.XmlNode shopDefNode = null;
		Dom.XmlNode layoutFirstNode = null;
		// 2017/12/25 親部屋子部屋更新項目カスタム設定　by　zy BEGIN
		Map<String, Schema.DescribeFieldResult> modelDeafaultValuesMap1 = CommSqlUtils.getAllFieldLst(Lead__c.sObjectType,false,true);
		// 2017/12/25 親部屋子部屋更新項目カスタム設定　by　zy END
		try {
			tblLst = new List<MessageTbl>();
			planFieldNameSet = new Set<String>();
			leadCustomFieldLst = new List<String>();
			//レイアウトの自設定の機能　By zy BEGIN
			String defNamePrix = 'BookingFlexAppLayoutDefine';
			List<Document> sr = [select body, name from Document where DeveloperName = :defNamePrix];
	    	if (sr.isEmpty()) throw New CommException('Config Xml(' + defNamePrix +') File Not Found!!!');
	    	Blob xmlBody = sr[0].Body;
	    	String strXmlBody = xmlBody.toString();
	    	Dom.Document doc = new Dom.Document();
			doc.load(strXmlBody);
	    	Dom.XmlNode rootNode = doc.getRootElement();
	    	Dom.XmlNode targetNode = null;
	    	for (Dom.XmlNode node : rootNode.getChildElements()) {
	    		String nodeName = node.getName();
	    		if ( nodeName == 'LAYOUT') {
	    			Dom.XmlNode codeNode = node.getChildElement('LAYOUTCODE',null);
	    			if (codeNode != null) {
	    				String xmlLayoutNo = CommUtils.nullToBlank(codeNode.getText());
	    				if(xmlLayoutNo == layoutNo){
	    					targetNode = node;
	    					findLayoutNo = layoutNo;
	    					break;
	    				} else if (userDefLayoutNo == xmlLayoutNo) {
	    					uerDefLayoutNode = node;
	    				}
	    				// レイアウト定義が存在すると、該当NODEはデフォルトNODE
	    				if (layoutFirstNode == null) layoutFirstNode = node;
	    			}
	    		} else if ( nodeName == 'SHOP') {
	    			if (shopDefNode == null) shopDefNode = node;
	    		}
	    	}
	    	if (targetNode == null) {
	    		if (uerDefLayoutNode != null) {
	    			Dom.XmlNode codeNodeField = uerDefLayoutNode.getChildElement('LAYOUTCODE',null);
	    			findLayoutNo = CommUtils.nullToBlank(codeNodeField.getText());
	    			targetNode = uerDefLayoutNode;	
	    		} else if (layoutFirstNode != null) {
	    			Dom.XmlNode codeNodeField = layoutFirstNode.getChildElement('LAYOUTCODE',null);
	    			findLayoutNo = CommUtils.nullToBlank(codeNodeField.getText());
	    			targetNode = layoutFirstNode;
	    		} else if (shopDefNode != null) {
	    			targetNode = shopDefNode;
	    		} else {
	    			throw new CommException('レイアウト定義情報を見つかりません、管理者に連絡ください。');
	    		}
	    	}
	    	//レイアウトの自設定の機能　By zy END
//system.debug(logginglevel.info,'targetNode:::' + targetNode);
			Set<String> noReqSet = new Set<String>();
			integer maxLine = 15;
			// 2017/12/25 親部屋子部屋更新項目カスタム設定　by　zy BEGIN
			checkSet = new Set<String>();
			// 重复过滤
			set<String> exitSet = new set<String>();
			// 2017/12/25 親部屋子部屋更新項目カスタム設定　by　zy END
			for (Dom.XMLNode d : targetNode.getChildElements()) {
				if(d.getName() == 'FIELDS'){
					for (Dom.XMLNode dom : d.getChildElements()) {
						Section s = new Section(dom,exitSet);
						exitSet.addAll(s.exitSet);
						if(!s.colLst.isEmpty()) secLst.add(s);
					}
				}else if(d.getName() == 'REQUIREDFIELDS'){
					String reqStr = CommUtils.nullToBlank(d.getText());
					if(!CommUtils.isBlank(reqStr)) noReqSet.addAll(reqStr.deleteWhitespace().split(','));
				}else if(d.getName() == 'COLOR'){
					colorStr = CommUtils.nullToBlank(d.getText());
				}else if (d.getName() == 'CHGMAXLINE'){
					Integer intRow = CommUtils.nullToIntZero(d.getText());
					if( intRow > 0) maxLine = intRow;
				}
				// 2017/12/25 親部屋子部屋更新項目カスタム設定　by　zy BEGIN
				 else if ( d.getName() == 'SYNCFIELDS') {
					String fieldNames = CommUtils.nullToBlank(d.getText()).deleteWhitespace();
					if (!CommUtils.isBlank(fieldNames)) {
						List<String> fieldLst = fieldNames.toLowerCase().trim().split(',');
						for (String fieldName : fieldLst) {
							if (modelDeafaultValuesMap1.containsKey(fieldName)) {
								Schema.DescribeFieldResult dr = modelDeafaultValuesMap1.get(fieldName);
								// 可变更数据
								if (dr.isUpdateable()) checkSet.add(dr.getLocalName().toLowerCase());
							}
						}
					}
					// 2019/11/15 一括予約画面での項目編集を親部屋以外にも反映してほしい by zy BEGIN
					String subFlg = d.getAttribute('SUB',null);
					if (!CommUtils.isBlank(subFlg)) saveSubIndxFlg = boolean.valueOf(CommUtils.nullToBlank(subFlg));
					// 2019/11/15 一括予約画面での項目編集を親部屋以外にも反映してほしい by zy END
				}
				// 2017/12/25 親部屋子部屋更新項目カスタム設定　by　zy END
			}
			//system.debug(logginglevel.info,'noReqSet:::' + noReqSet);
			integer curLine = maxLine;
			tblLst = new List<MessageTbl>();
			MessageTbl curTbl = new MessageTbl();
			Section oneSec = null;
			planString = '';
			Map<String, Schema.DescribeFieldResult> modelDeafaultValuesMap = CommSqlUtils.getAllFieldLst(Lead__c.sObjectType,false);
			for (Section s : secLst) {
				// 縦側は最大表示行までかつ次のセクションのタイトルが存在する場合、画面の右に表示する
				if (curLine < 0 && !CommUtils.isBLank(s.title)){
					curLine = maxLine;
					tblLst.add(curTbl);
					curTbl = new MessageTbl();
				}
				curTbl.add(s,modelDeafaultValuesMap,noReqSet);
				//curTbl.titleLst.add(s.title);
				//if(s.colnum > 1){
				if(s.colLst != null && s.colLst.size() > 0) curLine -= s.colLst[0].fieldLst.size();
			}
			// 2019/03/08 リッチテキストエリアツール変更 by zy BEGIN
			// お客様全部字段集合
			Map<String, Schema.DescribeFieldResult> contactMap = CommSqlUtils.getAllFieldLst(Contact.sObjectType,false,true);
			// 2019/03/08 リッチテキストエリアツール変更 by zy END
			//１セクション作成
			if(!curTbl.secLst.isEmpty()) tblLst.add(curTbl);
			//予約のお客様の項目関連Set
			if(!planFieldNameSet.isEmpty()){
				for (String fieldName : planFieldNameSet){
					// 2019/03/08 リッチテキストエリアツール変更 by zy BEGIN
					// お客様字段チェック
					if (!contactMap.containsKey(fieldName.toLowerCase())) continue;
					// 2019/03/08 リッチテキストエリアツール変更 by zy END
					planString += fieldName + ',';
				} 
			}
			// 2019/03/08 リッチテキストエリアツール変更 by zy BEGIN
			// Map<String, Schema.DescribeFieldResult> contactMap = CommSqlUtils.getAllFieldLst(Contact.sObjectType,false,true);
			// 2019/03/08 リッチテキストエリアツール変更 by zy BEGIN
			//2016/12/30 予約カスタム項目差異　by　zy　BEGIN
			for (MessageTbl tbl : tblLst) {
				for (Section sec : tbl.secLst) {
					for (Col col : sec.colLst){
						for (BookingField b : col.fieldLst) {
							String fieldName = b.fieldName;
							if (!CommUtils.isBlank(fieldName) && fieldName != '$_blank_$'){
								// 2019/03/08 リッチテキストエリアツール変更 by zy BEGIN
								Schema.DescribeFieldResult dr = null;
								// 2019/03/08 リッチテキストエリアツール変更 by zy END
								if (!b.isContactFlag){
									// 2017/12/27 無効予約項目処理　by　zy BEGIN
									if (!modelDeafaultValuesMap1.containsKey(fieldName.toLowerCase())) b.fieldName = '$_blank_$';
									else 
									// 2017/12/27 無効予約項目処理　by　zy END
									leadCustomFieldLst.add(b.fieldName);
									// 2019/03/08 リッチテキストエリアツール変更 by zy BEGIN
									dr = modelDeafaultValuesMap1.get(fieldName.toLowerCase());
									// 2019/03/08 リッチテキストエリアツール変更 by zy END
								} 
								// 2017/12/27 無効予約項目処理　by　zy BEGIN
								else {
									if (!contactMap.containsKey(fieldName.toLowerCase())) b.fieldName = '$_blank_$';
									// 2019/03/08 リッチテキストエリアツール変更 by zy BEGIN
									dr = contactMap.get(fieldName.toLowerCase());
									// 2019/03/08 リッチテキストエリアツール変更 by zy END
								}
								// 2017/12/27 無効予約項目処理　by　zy END
								// 2019/03/08 リッチテキストエリアツール変更 by zy BEGIN
								// リッチテキストエリア特殊対応
								if (dr != null && dr.getType() == Schema.DisplayType.TEXTAREA && dr.isHtmlFormatted()) {
									// リッチテキストエリアフラグ
									b.isRichTextAreaFlag = true;
								}
								// 2019/03/08 リッチテキストエリアツール変更 by zy END
							}
						}
					}
				}
			}
			// 2017/01/09 予約タイプの全部予約変更　by zy BEGIN
			Set<String> leadSet = new Set<String>();
			leadCustomFieldLst = new List<String>(new Set<String>(leadCustomFieldLst));
			leadSet.addAll(leadCustomFieldLst);
			if (leadSet.contains('ReservedType__c')) hadReservedTypeFlag = true;
			// 2017/01/09 予約タイプの全部予約変更　by zy END
			// 2017/03/14 一括キャンセル機能の対応　by　zy BEGIN
			if (leadSet.contains('ReservedStatus__c')) hadReservedStatusFlag = true;
			// 2017/03/14 一括キャンセル機能の対応　by　zy END
		} catch (Exception e){
			system.debug(logginglevel.info,'e:::' + e.getStackTraceString());
		}
		return findLayoutNo;
	}
	public List<MessageTbl> tblLst{get;set;}
	public class MessageTbl{
		public List<Section> secLst{get;set;}
		public MessageTbl(){
			//titleLst = new List<String>();
			secLst = new List<Section>();
		}
		public void add(Section s , Map<String, Schema.DescribeFieldResult> modelDeafaultValuesMap,Set<String> norequiredSet){
			for (Col col : s.colLst){
				for (BookingField bfield : col.fieldLst) {
					String fieldName = bfield.fieldName;
					if (norequiredSet.contains(fieldName)) {
						bfield.isRequiredFlag = true;
					}
					if (modelDeafaultValuesMap.containsKey(fieldName)){
						Schema.DescribeFieldResult dr = modelDeafaultValuesMap.get(fieldName);
						if(dr.getLength() > 2048 && dr.getType() == DisplayType.TEXTAREA){
							bfield.isLongTextareaflag = true;
						}
					}
				}
			}
			secLst.add(s);
		}
	}
	private static Set<String> planFieldNameSet;
	public String planString{get;set;}
	public class Section{
		public Integer colnum{get;set;}
		public String title{get;set;}
		public List<Col> colLst{get;set;}
		public boolean explanFlag{get;set;}
		// XMLから直接該当セクション常に展開する
		public boolean alwaysExplanFlg{get;set;}
		public Set<String> exitSet;
		//public Section(){}
		public Section(Dom.XMLNode d,Set<String> hadExitSet){
			String attrCol = d.getAttribute('COLNUM',null);
			colnum = CommUtils.nullToIntZero(attrCol);
			exitSet = new Set<String>();
			//2017/01/18 宽度设定模式切换by zy BEGIN
			if (colnum == 1) colnum = 0;
			//2017/01/18 宽度设定模式切换by zy END
			title = CommUtils.nullToBlank(d.getAttribute('TITLE',null));
			// 2017/01/19 セクションの常い展開する設定フラグを追加する
			explanFlag = false;
			alwaysExplanFlg = Boolean.valueOf(CommUtils.nullToBlank(d.getAttribute('EXPAND',null)));
			String content = CommUtils.nullToBlank(d.getText());
			colLst = new List<Col>();
			if (!CommUtils.isBlank(content)){
				//system.debug(logginglevel.info,'content:::' + content);
				List<String> fieldLst = content.split(',');
				if (fieldLst.size() > 0){
					integer idx = colnum;
					if (idx == 0){
						idx = 1;
					} 
					Col col = new Col();
					Integer checkindex = idx;
					for (String field : fieldLst) {
						field = CommUtils.nullToBlank(field);
						if (CommUtils.isBlank(field)) continue;
						// 去重处理
						// bug 4638 fix by zy BEGIN
						if (field != '$_blank_$' && hadExitSet.contains(field) && !exitSet.contains(field)) continue;
						// bug 4638 fix by zy END
						else exitSet.add(field);
						if (checkindex == idx ) checkindex = 0;
						if (colLst.size() < (checkindex + 1)) {
							colLst.add(new Col());
						}
						integer beforeIdx = colLst[checkindex].fieldLst.size() - 1;
						//if(beforeIdx >=0)
						if(beforeIdx >= 0 && colLst[checkindex].fieldLst[beforeIdx].fieldName == '$_blank_$'){
							colLst[checkindex].fieldLst[beforeIdx] = new BookingField(field);
						}else
							colLst[checkindex].add(field);
						checkindex ++;
					}
				}
			}
		}
	}
	public class Col{
		public List<BookingField> fieldLst{get;set;}
		public boolean explanFlag{get;set;}
		public Col(){
			fieldLst = new List<BookingField>();
		}
		public void add(String fieldName){
			fieldLst.add(new BookingField(fieldName));
		}
	}
	public class BookingField{
		public String fieldName{get;set;}
		public boolean isRequiredFlag{get;set;}
		public boolean isLongTextareaflag{get;set;}
		public boolean isContactFlag{get;set;}
		public boolean isContactRefFlag{get;set;}
		// 2019/03/08 リッチテキストエリアツール変更 by zy BEGIN
		// リッチテキストエリアフラグ
		public boolean isRichTextAreaFlag{get;set;}
		// 2019/03/08 リッチテキストエリアツール変更 by zy END
		//2017/01/12 １項目宽度自设定　by　zy BEGIN
		public String orgName;
		public BookingField(String name){
			fieldName = CommUtils.nullToBlank(name);
			orgName = name;
		//2017/01/12 １項目宽度自设定　by　zy END
			isContactFlag = false;
			isContactRefFlag = false;
			if (name.contains('Relcontact__r')) {
				isContactFlag = true;	
				fieldName =	fieldName.subStringAfter('__r.');
				planFieldNameSet.add(fieldName);
			}
			if(fieldName.contains('Relcontact__c'))
				isContactRefFlag = true;
			//system.debug(logginglevel.info,'name:::' + name);
			isRequiredFlag = false;
			isLongTextareaflag = false;
			// 2019/03/08 リッチテキストエリアツール変更 by zy BEGIN
			isRichTextAreaFlag = false;
			// 2019/03/08 リッチテキストエリアツール変更 by zy END
		}
	}
	/*
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
	*/

    // IndexSub
    //public String indexSubNo{get;set;}
    public String indexSubId{get;set;}
    public String indexSubNo{get;set;}
    public String indexSubRType{get;set;}
    public String indexSubStrDt{get;set;}
    public String indexSubEndDt{get;set;}
	// 宿泊名簿
	//public List<ContactItem> oGuestLst{get; private set;}
	/*
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
	}*/


	// 予約明細一覧[予約インデックスSUB]
	public List<LeadItem> oLeadLst{get; private set;}
	public class BookingDetail{
		public String dtDate{get;set;}
		public Integer rowidx{get;set;}
		public List<BookingRow> bRows{get;set;}
	}
	public class BookingRow{
		public Integer rowNo{get;set;}
		public Integer leadNo{get;set;}
		public BookingEstimateItem__c b{get;set;}
		// サービス料金(税込)
		public Decimal servicePriceIncTax{get;set;}
		// 特別料金
		public Decimal specialTax{get;set;}
		// 単価
		public String unitPrice{get;set{
			unitPrice = value;
			b.UnitPrice__c = CommUtils.nullToZero(unitPrice);
		}}
		// 数量
		public String prodNums{get;set{
			prodNums = value;
			b.Amount__c = CommUtils.nullToZero(prodNums);
			}}
		// 会計明細単位の合計金額（税抜）
		public Decimal amoutExcTax{get; set;}
		// 会計明細単位の合計金額（税込）[商品売価*数量  + サービス料　+ 特別税]
        public Decimal amoutIncTax{get; set{
        	amoutIncTax = value;
        	if (value !=null && value != b.SpTotal__c) b.SpTotal__c = value;}}
		public boolean isProduct{get{return (b.ActionType__c == CommConst.PROD_ACTION_TYPE_PL ? true : false);} set;}
		public BookingRow(){
			b = new BookingEstimateItem__c();
		}
	}
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
    	   rowIdx = size;
    	   nights = String.valueOf(ps.Nights__c);
    	   rooms = String.valueOf(ps.Rooms__c);
    	   persons = String.valueOf(ps.StayPersons__c);
    	   bookingLst = new List<BookingDetail>();
    	   // 2016/12/30 親SUBのフラグ追加　by　zy  BEGIN
    	   isParentFlag = s.ParentFlg__c;
//		   if(size == 0 && s.id !=null) isParentFlag = true;
		   // 2016/12/30 親SUBのフラグ追加　by　zy  END
		   // 2017/01/10 商品フラグ by zy BEGIN
		   isProductFlag = s.AccountMasterRef__c != null;
		   if (isProductFlag) productName = s.AccountMasterRef__r.name;
		   else productName = s.PlanRef__r.name;
		   isPlanFlag = !isProductFlag || s.AccountMasterRef__r.ActionType__c == CommConst.PROD_ACTION_TYPE_PL;
		   // 2017/01/10 商品フラグ by zy END
		   sobjId = isProductFlag ? s.AccountMasterRef__c : s.PlanRef__c;
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
    	public List<Lead__c> leadLst{get;private set;}
    	public List<BookingDetail> bookingLst{get;set;}
    	public boolean isParentFlag{get;set;}
    	// 2017/01/10 商品フラグ by zy
    	public boolean isProductFlag{get;set;}
    	// 2017/01/10 商品フラグ by zy BEGIN
    	public boolean isPlanFlag{get;set;}
    	// 2017/01/10 商品フラグ by zy END
    	public String sobjId{get;set;}
    	public String productName{get;set;}
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
    		Set<String> fieldSet = new Set<String>{'PlanDetailSyncInfo__c','PlanRef__c','AccountMasterRef__c'};
    		//2017/07/04 namespaceの場合対応　by zy BEGIN
    		String namespace = CommConst.APPOTION_NAMESPACE;
    		//2017/07/04 namespaceの場合対応　by zy END
    		for (String key : leadIdxFieldsSet) {
				//2017/07/04 namespaceの場合対応　by zy BEGIN
				String api = key;			
				if(!CommUtils.isBlank(nameSpace) && api.startsWith(nameSpace)) api = api.substringAfter(nameSpace);
    			//2017/01/18 データ変更 nullとblank 対応　by zy BEGIN
    			if (fieldSet.contains(api)) {
    				if (CommUtils.nullToblank(orgSobj.get(api)) != CommUtils.nullToblank(s.get(api))) {
    			//2017/07/04 namespaceの場合対応　by zy END
    					return true;
    				}
    			} else if ( orgSobj.get(key) != s.get(key)) {
    				return true;
    			}
    			//2017/01/18 データ変更 nullとblank 対応　by zy END
    		}
    		// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy BEGIN
    		if (!CommUtils.isBlank(roomInfoJson)) return true;
    		// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy END
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
			//2017/01/18 データ変更 nullとblank 対応　by zy BEGIN
			return (CommUtils.nullToblank(orgSobj.PlanRef__c) !=  CommUtils.nullToblank(s.PlanRef__c));
			//2017/01/18 データ変更 nullとblank 対応　by zy END
		}
		// 商品変更判断ロジック
		public boolean isChgAcc() {
			//2017/01/18 データ変更 nullとblank 対応　by zy BEGIN
			return (CommUtils.nullToblank(orgSobj.AccountMasterRef__c) !=  CommUtils.nullToblank(s.AccountMasterRef__c));
			//2017/01/18 データ変更 nullとblank 対応　by zy END
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
        public integer rowIdx{get;set;}
        //2017/06/26 見積もり明細の価格変更対応　by　zy　BEGIN
        public Boolean isChgPrice(){
        	//null to blank 比较出错
        	return CommUtils.nullToZero(s.SalesPrice__c) != CommUtils.nullToZero(orgSobj.SalesPrice__c) || 
        					CommUtils.nullToBlank(s.PlanDetailSyncInfo__c) != CommUtils.nullToBlank(orgSobj.PlanDetailSyncInfo__c);
        }
        //2017/06/26 見積もり明細の価格変更対応　by　zy　END
        // 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy BEGIN
        public String roomInfoJson{get;set;}
        public boolean isLockFlag{get;set;}
        // 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy END
		// 2019/11/15 一括予約画面の部屋直接選択 by zy BEGIN
		public String roomName{get;set;}
		// 2019/11/15 一括予約画面の部屋直接選択 by zy END
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
    		orgLeadIndexId = s.id;
    	}
    	public LeadIndex__c s{get; private set;}
    	public Lead__c l{get; private set;}
    	public Contact c{get; private set;}
		public Id orgLeadIndexId{get;set;}
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
    @remoteAction
    public static List<ProductItemUtils.ProductItem> getArrayProductDetailItemInfo(String prodCode) {
        // 検索SQL取得
		String queryStr = CommSqlUtils.generateQueryString('AccountMaster__c',new String[]{'(Select AccountMasterRef__c, Price__c, TaxRate__c ,AccountMasterRef__r.ActionType__c From PlanProdcutRef__r where TaxRate__c = 0 or TaxRate__c = null)'});
		//queryStr += ' Where BasePlanFlg__c = false And IsClosed__c != true And ActionType__c != \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_NO) + '\' And Field3__c like \'' + CommUtils.escStr(prodCd) + '%\'';
		queryStr += ' Where IsClosed__c != true And ActionType__c != \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_NO) + '\' And ( Field3__c like \'' + CommUtils.escStr(prodCode) + '%\' OR Name like \'' + CommUtils.escStr(prodCode) + '%\') ' ;
		
		queryStr += ' order by Field4__c,OP__c, Field3__c ';
		//queryStr += ' limit 1000 '; 
		// 商品情報を検索を行う
		List<AccountMaster__c> accMstLst = Database.query(queryStr);
		if (accMstLst.isEmpty()) {
			return new List<ProductItemUtils.ProductItem>();
		}
		Set<Id> accIdSet = new Set<Id>();
		for (AccountMaster__c ac : accMstLst) {
			accIdSet.add(ac.id);
		} 
		set<Id> hadRoomFlagSet = new Set<id>();
		for (PlanDetail__c detail : [Select AccountMasterRef__c, Price__c, TaxRate__c,PlanProdcut__c,AccountMasterRef__r.ActionType__c From PlanDetail__c  where  PlanProdcut__c = :accIdSet]){
        	AccountMaster__c acc = new AccountMaster__c(ActionType__c = detail.AccountMasterRef__r.ActionType__c);
        	if (RackRateUtils.isRoomRateProduct(acc)){
        		if (CommUtils.nullToZero(detail.Price__c) == 0){
        			if (!hadRoomFlagSet.contains(detail.PlanProdcut__c))
        				hadRoomFlagSet.add(detail.PlanProdcut__c);
        		}
        	}
        }
		List<ProductItemUtils.ProductItem> items = new List<ProductItemUtils.ProductItem>();
		for (AccountMaster__c ac : accMstLst) {
			ProductItemUtils.ProductItem p = new ProductItemUtils.ProductItem(ac);
			if (hadRoomFlagSet.contains(ac.id)) p.hadRoomFlag = true;
			items.add(p);
		}
        
//system.debug(logginglevel.info,'items:::' + items);
        return items;
    }
    @remoteAction
    public static List<ProductItemUtils.ProductItem> getArrayProductItemInfoNoPlan(String prodCode) {
        return ProductItemUtils.getArrayProdcutItemByCode(prodCode, true);
    }
    /**
    * planId : プランID
    * tierPrice　: tier 
    * rateFLagStr : true 室料設定、false 自動计算
    **/
    @RemoteAction
    public static List<PlanDetail> getAccountMstLstByPlan(String bookingItemId,String prodId) {
        // 会計IDが存在する場合、既に登録された登録情報から情報を展開する
        // 会計IDが非存在場合、
        List<PlanDetail> rsLst = new List<PlanDetail>();
        //TODO tier price get
        Integer tierPriceDec = 0;
        if(!CommUtils.isBlank(bookingItemId)) {
            for (BookingEstimateItem__c tr : [select refAccountMaster__c,refAccountMaster__r.ActionType__c, ProductName__c, UnitPrice__c,TaxRate__c from BookingEstimateItem__c where ParentBookingItemRef__c = :bookingItemId]) {
                PlanDetail item = new PlanDetail();
                AccountMaster__c acc = new AccountMaster__c(ActionType__c = tr.refAccountMaster__r.ActionType__c);
	            Decimal roomPrice = tr.UnitPrice__c;
	            if (tierPriceDec > 0 ){
		            if (RackRateUtils.isRoomRateProduct(acc)){
		                if (roomPrice == 0) 
		                    roomPrice = tierPriceDec;
		            }
	            }
                item.prodName = CommUtils.nullToBlank(tr.ProductName__c);
               	item.prodPrice = CommUtils.deleteRightZero(CommUtils.nullToZero(roomPrice).format(), CommUtils.getPointLen());
                item.sobjId = tr.Id;
                item.prodId = tr.refAccountMaster__c;
                item.actionType = tr.refAccountMaster__r.ActionType__c;
                item.prodTaxRate = CommUtils.nullToZero(tr.TaxRate__c);
                rsLst.add(item);
            }
		} else {
			for (PlanDetail__c pd : [select AccountMasterRef__c, AccountMasterRef__r.name, AccountMasterRef__r.ActionType__c,Price__c,TaxRate__c from PlanDetail__c where PlanProdcut__c = :prodId]) {
                PlanDetail item = new PlanDetail();
                AccountMaster__c acc = new AccountMaster__c(ActionType__c = pd.AccountMasterRef__r.ActionType__c);
                Decimal roomPrice = pd.Price__c;
                if (tierPriceDec > 0 ){
		            if (RackRateUtils.isRoomRateProduct(acc)){
		                if ( roomPrice == 0) 
		                    roomPrice = tierPriceDec;
		            }
	            }
                item.prodName = CommUtils.nullToBlank(pd.AccountMasterRef__r.name);
                item.prodPrice = CommUtils.deleteRightZero(CommUtils.nullToZero(roomPrice).format(), CommUtils.getPointLen());
                item.sobjId = pd.Id;
                item.planId = pd.Id;
                item.prodId = pd.AccountMasterRef__c;
                item.actionType = pd.AccountMasterRef__r.ActionType__c;
                item.prodTaxRate = CommUtils.nullToZero(pd.TaxRate__c);
                rsLst.add(item);
	        }
		}
        
        return rsLst;
    }
    
	// プラン明細情報を維持する
	public class PlanDetail {
		public String prodName;
		public String prodPrice;
		public String sobjId;
		public String actionType;
		// 2015/10/05プラン明細課税、非課税混雑対応するため、消費税情報を取得、格納する
		public Decimal prodTaxRate;
		public String prodId;
		public String planId;
	}
    //2016/11/04 お客様メッセージ自動設定　BEGIN
    public String contactName{get;set;}	// return leadBaseInf.contactName;
    
    // 2016/11/10 最近参照した予約インデックス情報一覧を取得する
    public List<LeadIndex__c> recRefLeadIndexs{get; private set;}
    public void loadRecentRefLeadIndex() {
    	// お客様名、到着日、予約インデックス名
		//recRefLeadIndexs = [select id, name, EntryDate__c, contactRef__c, LeadName__c from LeadIndex__c where ParentLeadIndxRef__c = null order by LastReferencedDate desc nulls last,Name desc limit 10 ];
		recRefLeadIndexs = [select id, name, EntryDate__c, contactRef__c, LeadName__c from LeadIndex__c where ParentLeadIndxRef__c = null order by LastModifiedDate desc limit 10 ];
    }
    //予約名は変更機能
    private String changeLeadName(String orgLeadName , boolean isFirst, Integer newNights, Integer leadIndex){
		String newLeadName = '';
		//String orgLeadName = leads[0].Name;
			// 予約名切替用キー
		//泊目
		String repRegExpKey1 = LEAD_NAME_PREFIX + '([0-9]+-[0-9]+'+ Label.CONST_008_0110 +')';
		//泊目
		String repRegExpKey2 = '([0-9]+-[0-9]+'+ Label.CONST_008_0110 +')';
		String repRegKey = String.valueOf(DateTime.now().getTime())+Crypto.getRandomLong();

		// 元予約データ名は：999-999泊目+予約名　方式　OR　代表部屋標識+999-999泊目+予約名
		// 上記方式の場合、直接Replace方式で名前再設定を行う
		// 元予約名は 代表部屋標識+予約名の場合、999-999泊目に入り替えする, 予約名の場合、直接 999-999泊目方式に設定する
		String regexpResult1 = orgLeadName.replaceFirst(repRegExpKey1, repRegKey);
		String regexpResult2 = orgLeadName.replaceFirst(repRegExpKey2, repRegKey);
		// 泊目書式場合
		if (regexpResult1 != orgLeadName || regexpResult2 != orgLeadName) {
			//泊目
			String newName = '';
			if (newNights > 1) {
				newName =  newNights + '-' + (leadIndex+1) + Label.CONST_008_0110 +' ';
			}
			newLeadName = orgLeadName.replaceFirst(repRegExpKey2, newName);
			//}
		}else if (orgLeadName.contains(LEAD_NAME_PREFIX)) {
			// 予約名を設定する
			if (newNights > 1) {
				//泊目
				String newName =  LEAD_NAME_PREFIX  + newNights + '-' + (leadIndex+1) + Label.CONST_008_0110 + ' ';
				newLeadName = orgLeadName.replaceFirst(LEAD_NAME_PREFIX, newName);
			}else{
				newLeadName = orgLeadName;
			}
		}else{
			// 予約名を設定する
			if (newNights > 1) {
				//泊目
				String newName = + newNights + '-' + (leadIndex+1) + Label.CONST_008_0110 + ' ';
				if (!orgLeadName.contains(LEAD_NAME_PREFIX)) newLeadName = newName + orgLeadName;
				else  newLeadName = orgLeadName.replaceFirst(LEAD_NAME_PREFIX, newName);
			}else
			newLeadName = orgLeadName;
		}
		//超过长度判断
		if (newLeadName.length() > 80) newLeadName = newLeadName.subString(0,80);
		return newLeadName;
	}
	//2017/04/04 親部屋のfix by zy END
	public boolean isChgConFlag{get;set;}
	//2017/06/21 親部屋の選択機能追加　by　zy BEGIN
	public String mainSubId{get;set;}
	//外部用親部屋変更
	public void changeParentInfo(){
		// 2018/06/06 編集権限チェックできる対応 BEGIN
		Savepoint sp = Database.setSavepoint();
		try {
		// 2018/06/06 編集権限チェックできる対応 END
			chgParentFlagBySubId(mainSubId);
			// 2019/10/15 .ルームインジケータで1室押さえ、それから一括予約で部屋を増やした場合、親部屋の「●」が動的に付与されません。自動化をお願いします by zy BEGIN
			// 親明細の予約名変更
			chgParSubLeadName(leadBaseInf.s.Id,mainSubId);
			// 2019/10/15 .ルームインジケータで1室押さえ、それから一括予約で部屋を増やした場合、親部屋の「●」が動的に付与されません。自動化をお願いします by zy END
		// 2018/06/06 編集権限チェックできる対応 BEGIN
		} catch (Exception e) {
			DataBase.rollback(sp);
			String errMsg = e.getMessage();
			if(!CommUtils.isFieldValidationMessage(errMsg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
		}
		// 2018/06/06 編集権限チェックできる対応 END
		queryExistLeadByLeadIndexId();
		// 最新の予約情報を再取得する
		refreshWinLead();
		//2016/11/15 section自动展开
		sectionExpandProcess();
	}
	//内部用親部屋変更
	private void chgParentFlagBySubId(String mainSubId){
		// 他予約インデックスのデータ更新　BEGIN
		List<LeadIndex__c> otherParentSubLst = new List<LeadIndex__c>();
		for (LeadItem item : oLeadLst) {
       		if (item.s.Id != null && item.s.ParentLeadIndxRef__c != leadBaseInf.s.Id) {
       			item.s.ParentLeadIndxRef__c = leadBaseInf.s.Id;
       			item.s.ParentFlg__c = item.s.id != mainSubId;
       			otherParentSubLst.add(item.s);
       		}
       	}
       	if (!otherParentSubLst.isEmpty()) update otherParentSubLst;
       	// 他予約インデックスのデータ更新　END
       	
		List<LeadIndex__c> idxSubLst = [select name, SalesPrice__c, PlanRef__c, Nights__c, DepartureDate__c, EntryDate__c, RoomTypeRef__c, Rooms__c, ParentLeadIndxRef__c,StayPersons__c,ExtraBedChk__c from LeadIndex__c 
        	where ParentLeadIndxRef__c = :leadBaseInf.s.Id or id = :mainSubId order by name];
       	for (LeadIndex__c subIndex : idxSubLst) {
       		if (mainSubId == subIndex.id ) {
       			subIndex.ParentFlg__c = true;
       		} else {
       			subIndex.ParentFlg__c = false;
       		}
       		if (subIndex.ParentLeadIndxRef__c != leadBaseInf.s.Id) subIndex.ParentLeadIndxRef__c = leadBaseInf.s.Id;
       	}
       	update idxSubLst;
	}
	//2017/06/21 親部屋の選択機能追加　by　zy END
	//2017/06/26 見積もり明細の価格変更対応　by　zy　BEGIN
	class ProductInfo{
		public String actionType;
		public AccountMaster__c acc;
		public Plan__c plan;
		public ProductInfo(AccountMaster__c master , Plan__c curPlan){
			acc = master;
			if (acc.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) {
				plan = curPlan;
			}
			actionType = acc.ActionType__c;
		}
	}
	private Map<String,ProductInfo> planToAccountMaster(Set<String> planIds,Set<String> accMasterIds){
		Map<String,ProductInfo> planToAccMap = new Map<String,ProductInfo>();
		Map<String,Plan__c> planNoMap = new Map<String,Plan__c>();
		for ( Plan__c plan : [select id, Price__c,PlanNo__c from Plan__c where id  = :planIds]){
			planNoMap.put('P' + plan.PlanNo__c,plan);
		}
		Map<String,String> accountMasterToPlanMap = new Map<String,String>();
		for (AccountMaster__c master : [select id,Field3__c,ActionType__c from AccountMaster__c where (Field3__c = :planNoMap.keySet() and ActionType__c =:CommConst.PROD_ACTION_TYPE_PL) or id = :accMasterIds]){
			// プランと商品
			if( planNoMap.containsKey(master.Field3__c)) {
				ProductInfo p  = new ProductInfo(master,planNoMap.get(master.Field3__c));
				planToAccMap.put(p.acc.id,p);
				if (p.plan != null) planToAccMap.put(p.plan.id,p);
			} else {
				ProductInfo p  = new ProductInfo(master,null);
				planToAccMap.put(p.acc.id,p);
				if (master.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) {
					accountMasterToPlanMap.put(master.Field3__c.replace('P',''),master.id);
				}
			}
		}
		if (!accountMasterToPlanMap.isEmpty()) {
			for ( Plan__c plan : [select id, Price__c,PlanNo__c from Plan__c where PlanNo__c  = :accountMasterToPlanMap.keySet()]){
				if ( accountMasterToPlanMap.containsKey(plan.PlanNo__c)) {
					String prodId = accountMasterToPlanMap.get(plan.PlanNo__c);
					if(planToAccMap.containsKey(prodId)){
						ProductInfo p = planToAccMap.get(prodId);
						p.plan = plan;
						planToAccMap.put(plan.id,p);
					}
				}
				
			}
		}
		return planToAccMap;
	}
	private void processDelAccount(Map<String,set<String>> orgSubAccMap,Lead__c lead,LeadItem subIdxitem,Map<String,ProductInfo> planToAccount){
		if (!orgSubAccMap.containsKey(lead.id)) orgSubAccMap.put(lead.id,new Set<String>());
		//既存データの会計商品
		if (subIdxitem.orgSobj.AccountMasterRef__c != null) {
			ProductInfo p = planToAccount.get(subIdxitem.orgSobj.AccountMasterRef__c);
			if (p != null) orgSubAccMap.get(lead.id).add(p.acc.id);
		}
		//既存データのプラン
		if (subIdxitem.orgSobj.PlanRef__c != null) {
			ProductInfo p = planToAccount.get(subIdxitem.orgSobj.PlanRef__c);
			if (p != null) orgSubAccMap.get(lead.id).add(p.acc.id);
		}
		//新規データの会計商品
		if (subIdxitem.s.AccountMasterRef__c != null) {
			ProductInfo p = planToAccount.get(subIdxitem.s.AccountMasterRef__c);
			if (p != null)
				orgSubAccMap.get(lead.id).add(p.acc.id);
		}
		//新規データのプラン
		if (subIdxitem.s.PlanRef__c != null) {
			ProductInfo p = planToAccount.get(subIdxitem.s.PlanRef__c);
			if (p != null)
				orgSubAccMap.get(lead.id).add(p.acc.id);
		}
		//既存の予約のプラン
		if (lead.field310__c != null) {
			ProductInfo p = planToAccount.get(lead.field310__c);
			if (p != null)
				orgSubAccMap.get(lead.id).add(p.acc.id);
		}
	}
	private ProductInfo getPordInfo(LeadIndex__c subItem, Map<String,ProductInfo> planToAccount) {
		ProductInfo p = null;
		if (!CommUtils.isBlank(subItem.AccountMasterRef__c))  p = planToAccount.get(subItem.AccountMasterRef__c);
		if (!CommUtils.isBlank(subItem.PlanRef__c))  p = planToAccount.get(subItem.PlanRef__c);
		return p;
	}
	private void processCurItemPlan(Lead__c lead,LeadIndex__c subItem, Map<String,ProductInfo> planToAccount,boolean isExitFlag){
		ProductInfo p = getPordInfo(subItem,planToAccount);
		if (p != null) {
			if (p.actionType == CommConst.PROD_ACTION_TYPE_PL)	{
				//2017/07/05 多見積もり明細削除できない　by zy BEGIN
				//后开发的逻辑中已经完全控制住了逻辑，所以此处不需要其他动作，将310设上就行
				//如果field310上没有plan的场合 属于多見積もり模式，不重复设置310上
				if (lead.Field310__c != null) {
				//2017/07/05 多見積もり明細削除できない　by zy END
					lead.Field310__c = p.plan.id;
					lead.PlanDetailSyncInfo__c = subItem.PlanDetailSyncInfo__c;
				//2017/07/05 多見積もり明細削除できない　by zy BEGIN
				}
				//2017/07/05 多見積もり明細削除できない　by zy END
			} else {
				lead.Field310__c = null;
			}
			/*
			if (isExitFlag) {
				lead.PlanDetailSyncInfo__c = CommConst.CONST_PLANITEM_NOEXPAND;
				//添加此flag后,trigger将不进行自动变更，后续处理中会进行見積もり明細対応
				// 此处针对变更商品或价格时，数据被多次添加的问题进行回避
				lead.planSycnFlag__c = !lead.planSycnFlag__c;
			}*/
		}
	}
	//2017/06/26 見積もり明細の価格変更対応　by　zy　END
	// 2017/12/25 親部屋子部屋更新項目カスタム設定　by　zy BEGIN
	private set<string> diffFieldSet;
	private set<String> checkSet;
	private boolean refreshDetailLeads(boolean isCancelAllLeadFlag){
		boolean reservedTypeFlag = false;
		//2016/12/29 予約カスタム項目差異　by　zy　BEGIN
		boolean isDiffLead = checkDifLead();
		// 2019/11/15 一括予約画面での項目編集を親部屋以外にも反映してほしい by zy BEGIN
		id parSubId;
		// 2019/11/15 一括予約画面での項目編集を親部屋以外にも反映してほしい by zy END
		if ( isDiffLead ) {
			// id parSubId;
			for (LeadItem item : oLeadLst ) {
				if(item.s.ParentFlg__c){
					parSubId = item.s.id;
					break;
				}
			}
			if (parSubId != null){
				List<Lead__c> mainLst = new List<Lead__c>();
				Decimal orgRoomGroupNo = null;
				for (Lead__c mainLead : [select id,RoomGroupNo__c from Lead__c where LeadIndexRef__c = :leadBaseInf.s.Id And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG and LeadIndexSubId__c = :parSubId Order By RoomGroupNo__c, EntryTime__c]){
					if (orgRoomGroupNo == null) orgRoomGroupNo = mainLead.RoomGroupNo__c;
					if (orgRoomGroupNo != mainLead.RoomGroupNo__c) break;
					difLead.id = mainLead.id;
					mainLead = difLead.clone(true,true);
					mainLst.add(mainLead);
				}
				if (!mainLst.isEmpty()) {
					update mainLst;
				}
			}
			if (hadReservedTypeFlag) reservedTypeFlag = difLead.ReservedType__c != null;
		}
		// 2017/03/14 一括キャンセル機能の対応　by　zy BEGIN
		boolean isStatusChgFlag = hadReservedStatusFlag && newLead.ReservedStatus__c != oldLead.ReservedStatus__c;
		// 2017/05/26 予約ステータスは無効がどうか判断条件変更 BEGIN
		//isCancelAllLeadFlag = isStatusChgFlag  && newLead.ReservedStatus__c == CommConst.LEAD_ST_CANCEL;
		isCancelAllLeadFlag = isStatusChgFlag  && (
			newLead.ReservedStatus__c == CommConst.LEAD_ST_CANCEL ||
			newLead.ReservedStatus__c == CommConst.LEAD_ST_NOSHOW ||
       		newLead.ReservedStatus__c == CommConst.LEAD_ST_DELETE );
		// 2017/03/14 一括キャンセル機能の対応　by　zy END
		//2016/12/29 予約カスタム項目差異　by　zy　END
		// 予約名変更される場合、関連予約名は全部自動変更を行う
		if (
			// 2017/12/28 予約変更対応　by　zy　BEGIN
			// 更新对比关系，以前没有主予約与leadindex进行比较
			// 现在变更为判断主予約是否有变化
			/*
			newLead.Relcontact__c != leadbaseInf.orgContactId ||
			newLead.Name != leadBaseInf.orgLeadName ||
			newLead.Field315__c != leadBaseInf.orgPaymentType ||
			newLead.Field2__c != leadBaseInf.orgChannel ||
			newLead.Segment__c != leadBaseInf.orgSegment ||
			*/
			newLead.Relcontact__c != oldLead.Relcontact__c ||
			newLead.Name != oldLead.Name ||
			newLead.Field315__c != oldLead.Field315__c ||
			newLead.Field2__c != oldLead.Field2__c ||
			newLead.Segment__c != oldLead.Segment__c ||
			// 2017/12/28 予約変更対応　by　zy　END
			// 2017/01/09 予約タイプの全部予約変更　by zy BEGIN
			reservedTypeFlag ||
			// 2017/01/09 予約タイプの全部予約変更　by zy END
			// 2017/03/14 一括キャンセル機能の対応　by　zy BEGIN
			isStatusChgFlag
			// 2017/03/14 一括キャンセル機能の対応　by　zy END
			//CommUtils.nullToBlank(leadBaseInf.s.Comment__c) != CommUtils.nullToBlank(leadBaseInf.orgComment) 
			|| !diffFieldSet.isEmpty()
		) {
			// 2019/11/15 一括予約画面での項目編集を親部屋以外にも反映してほしい by zy BEGIN
			List<Lead__c> existLeads = [select id , name,Relcontact__c,LeadIndexSubId__c from Lead__c where LeadIndexRef__c = :leadBaseInf.s.Id And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG];
			// 2019/11/15 一括予約画面での項目編集を親部屋以外にも反映してほしい by zy END
			for (Lead__c lead : existLeads) {
				// 2017/12/25 親部屋子部屋更新項目カスタム設定　by　zy BEGIN
				//if (newLead.Relcontact__c != leadbaseInf.orgContactId)
				if (newLead.Relcontact__c != oldLead.Relcontact__c)
				lead.Relcontact__c = newLead.Relcontact__c;
				//if (newLead.Name != leadBaseInf.orgLeadName)
				if (newLead.Name != oldLead.Name) {
				// 如果有原来的则替换原来的
				//lead.name = lead.Name.replace(leadBaseInf.orgLeadName, convertLeadName(newLead.Name));
					// 2018/04/09 予約名●対応　by　ZY BEGIN
					if (lead.Name.contains(leadBaseInf.orgLeadName)) lead.name = lead.Name.replace(leadBaseInf.orgLeadName, convertLeadName(newLead.Name));
					else lead.name = lead.Name.replace(convertLeadName(lead.Name,true), convertLeadName(newLead.Name));
					// 2018/04/09 予約名●対応　by　ZY BEGIN
				}
				// 2017/12/25 親部屋子部屋更新項目カスタム設定　by　zy END
				// 2017/12/28 予約変更対応　by　zy　BEGIN
				//if (newLead.Field315__c  != leadBaseInf.orgPaymentType)
				if (newLead.Field315__c != oldLead.Field315__c)
				// 2017/12/28 予約変更対応　by　zy　END
				lead.Field315__c = newLead.Field315__c;
				// 2017/12/28 予約変更対応　by　zy　BEGIN
				//if (newLead.Field2__c  != leadBaseInf.orgChannel)
				if (newLead.Field2__c != oldLead.Field2__c)
				// 2017/12/28 予約変更対応　by　zy　END
				lead.Field2__c = newLead.Field2__c;
				// 2017/12/28 予約変更対応　by　zy　BEGIN
				//if (newLead.Segment__c != leadBaseInf.orgSegment)
				if (newLead.Segment__c != oldLead.Segment__c)
				// 2017/12/28 予約変更対応　by　zy　END
				lead.Segment__c = newLead.Segment__c;
				// 2017/01/09 予約タイプの全部予約変更　by zy BEGIN
				if (reservedTypeFlag) lead.ReservedType__c = newLead.ReservedType__c;
				// 2017/01/09 予約タイプの全部予約変更　by zy END
				// 2017/03/14 一括キャンセル機能の対応　by　zy BEGIN
				if (isStatusChgFlag) lead.ReservedStatus__c = newLead.ReservedStatus__c;
				// 2017/03/14 一括キャンセル機能の対応　by　zy END
				// 2014/01/08 一時対象外にする
				//if (CommUtils.nullToBlank(leadBaseInf.s.Comment__c) != CommUtils.nullToBlank(leadBaseInf.orgComment)) 
				//lead.Comment3__c = leadBaseInf.s.Comment__c;
				// 2019/11/15 一括予約画面での項目編集を親部屋以外にも反映してほしい by zy BEGIN
				if (!diffFieldSet.isEmpty() && ((saveSubIndxFlg && parSubId == lead.LeadIndexSubId__c) || !saveSubIndxFlg)) {
				// 2019/11/15 一括予約画面での項目編集を親部屋以外にも反映してほしい by zy END	
					for (String fieldName : diffFieldSet) {
						lead.put(fieldName,newLead.get(fieldName));
					}
 				}
			}
			update existLeads;
		}
		return isCancelAllLeadFlag;
	}
	// 2017/12/25 親部屋子部屋更新項目カスタム設定　by　zy END
	// 2017/12/25 部屋自動割り当て機能追加　by　zy BEGIN
	 // 部屋表示順フラグ定数定義
    private static final String ROOM_SORT_NAME_DIV = '1';
    private static final String ROOM_SORT_DIV = CommDefine__c.getOrgDefaults().RoomSortDiv__c == null ? ROOM_SORT_NAME_DIV : CommDefine__c.getOrgDefaults().RoomSortDiv__c;
	private static List<Room__c> getRoomLstByType(Set<Id> typeIdSet,String shopCode,Date begDt,Date endDt){
		return getRoomLstByType(typeIdSet,shopCode,begDt,endDt,null,true);
	}
	private static List<Room__c> getRoomLstByType(Set<Id> typeIdSet,String shopCode,Date begDt,Date endDt,String roomId,boolean filterBadRoom){
		String QueryHeader = 'select id,name,TypeRoomRef__c from room__c ';
		 // 各部屋のステータス取得する
	    String queryWhere = ' where UseOfRoom__c = \'' + String.escapeSingleQuotes(CommConst.ROOM_UseOfType_Guest) + '\' ';
		if (!CommUtils.isBlank(roomId)) queryWhere = 'where id = :roomId';
		else {
	        // 2015/09/01 多店舗機能対応 BEGIN
	        // 2019/01/30 部屋タイプを選ぶ際、ユーザは複数店舗 by zy BEGIN
			if (!CommUtils.isBlank(shopCode) && !bookingFlexSpcdFlag) {
			// 2019/01/30 部屋タイプを選ぶ際、ユーザは複数店舗 by zy END
	            queryWhere+= ' And ShopInfoRef__r.ShopCode__c = \'' + String.escapeSingleQuotes(shopCode) + '\'';
	        }else if (UserUtil.CurrentUserInfo.isShopCodePlex) {
	            Set<String> shopSt = UserUtil.CurrentUserInfo.shopSt;
	            queryWhere+= ' And ShopInfoRef__r.ShopCode__c in :shopSt';
	        }
			// 2015/09/01 多店舗機能対応 END
	        queryWhere+= ' And TypeRoomRef__c = :typeIdSet';
		}
        // 2013/05/22 部屋並べ替え機能修正
        String queryOrder = ' Order By AREA__c asc, Floor__c asc, ';
        if (ROOM_SORT_DIV == ROOM_SORT_NAME_DIV) {
        	queryOrder += ' Seq__c asc ';
        } else {
        	queryOrder += ' DisplayNo__c asc ';
        }
        String queryStr = QueryHeader + queryWhere + queryOrder;
        
        Set<Id> existRoomIdSet = new Set<Id>();
		// 部屋リストを取得する
		List<Room__c> canUseRoomList = new List<Room__c>();
		// 上記ROOMに既に使い済みの部屋リストを取得する
        List<Id> recTypeLst = RoomIndicatorInfo.getLeadBookingRecTypeLst();
        // 各部屋情報を取得する
        for (Room__c s: Database.query(queryStr)) {
        	existRoomIdSet.add(s.Id);
			canUseRoomList.add(s);
        }
         // 故障部屋状態を取得する
        RoomStatusManager roomStatus = new RoomStatusManager();
        Set<Id> badRoomSet = new Set<Id>();
        if (filterBadRoom) badRoomSet = roomStatus.queryBadRoomSet(begDt,endDt);
        // 有効な予約データ、一日一部屋で処理するため、重複することは処理対象外
        Set<Id> roomIdExistLeadSet = new Set<Id>();
        // 既に予約データに入る場合、該当部屋は選択対象外になる
        for (AggregateResult lead :  [
        	select Rroom__c roomId from Lead__c
        	where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 
        		And RecordTypeId in :recTypeLst
                And DAY_ONLY(convertTimezone(EntryTime__c)) >= :begDt
                And DAY_ONLY(convertTimezone(EntryTime__c)) <= :endDt
                //And refTypeOfRooms__c = :roomTypeId 
                And Rroom__c in :existRoomIdSet
                Group By Rroom__c]) {
        	roomIdExistLeadSet.add((Id)lead.get('roomId'));
        }
        List<Room__c> canAssignLst = new List<Room__c>();
        for (Room__c room : canUseRoomList) {
        	if (!roomIdExistLeadSet.contains(room.Id) && !badRoomSet.contains(room.Id)) canAssignLst.add(room);
        }
        return canAssignLst;
	}
	@remoteaction
	public static List<RequestInfo> refreshCanAssign(String request){
		RequestInfo req = (RequestInfo)JSON.deserialize(request,RequestInfo.class);
		Date begDt = CommUtils.stringtoDate(req.ci);
		Date endDt = CommUtils.stringtoDate(req.co);
		String shopCode = req.spcd;
		// 2019/07/31 20190729.01.一括予約の空部屋リスト表示不正の確認 by zy BEGIN
		String typeId = req.tid;
		List<RequestInfo> reqs = getRoomRequestInfo(shopCode,begDt,endDt,typeId,req.it,req.ot);
		// List<RequestInfo> reqs = getRoomRequestInfo(shopCode,begDt,endDt);
		// 2019/07/31 20190729.01.一括予約の空部屋リスト表示不正の確認 by zy END
		// 2019/11/15 一括予約画面の部屋直接選択 by zy BEGIN
		// List<RequestInfo> leadReqs = getRoomAssignJson(req.sid,req.ldxid);
		List<RequestInfo> leadReqs = getRoomAssignJson(req.sid,req.ldxid,req.lid);
		// 2019/11/15 一括予約画面の部屋直接選択 by zy END
		reqs.addAll(leadReqs);
		return reqs;
	}
	@remoteaction 
	public static List<RequestInfo> lockRoom(String request) {
		RequestInfo req = (RequestInfo)JSON.deserialize(request,RequestInfo.class);
		List<RequestInfo> res = new  List<RequestInfo>();
		String leadid = req.lid;
		if (!CommUtils.isBlank(leadid)) {
			List<Lead__c> leads = [select LeadIndexSubId__c,LeadIndexRef__c,RoomGroupNo__c,Field276__c from lead__c where id = :leadid];
			if (!leads.isEmpty()) {
				Lead__c updLead = leads[0];
				List<Lead__c> leadLst = new List<Lead__c>();
				// 同じ予約
				for ( Lead__c curLead : [select id,rroom__c from lead__c where LeadIndexSubId__c= :updLead.LeadIndexSubId__c and RoomGroupNo__c = :updLead.RoomGroupNo__c and LeadIndexRef__c = :updLead.LeadIndexRef__c and CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG ]) {
					curLead.Field276__c = req.lock;
					leadLst.add(curLead);
				}
				if (!leadLst.isEmpty()) update leadLst;
				return getRoomAssignJson(updLead.LeadIndexSubId__c,updLead.LeadIndexRef__c);
			}
		}
		return res;
	}
	private static final String g_DateFormat = CommBaseCtrl.getDateFormat();
	@remoteaction
	public static List<RequestInfo> saveLeadRoom(String request){
		RequestInfo req = (RequestInfo)JSON.deserialize(request,RequestInfo.class);
		String roomid = null;
		if (!CommUtils.isBlank(req.id)) roomid = req.id;
		String leadId = req.lid;
		String shopCode = req.spcd;
		Date begDt = null;
		Date endDt = null;
		// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy BEGIN
		String leadPrefix = Lead__c.sObjectType.getDescribe().getKeyPrefix();
		boolean kariLeadFlag = !leadId.startsWith(leadPrefix);
		// 新規仮予約
		if (kariLeadFlag) {
			begDt = CommUtils.stringtoDate(req.ci);
			endDt = CommUtils.stringtoDate(req.co);
		}
		// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy END
		Set<Id> typeSet = new Set<Id>();
		List<Lead__c> leads = [select id,LeadIndexSubId__c,RoomGroupNo__c,rroom__c,LeadIndexRef__c from lead__c where id= :leadId];
		List<RequestInfo> reqs = new List<RequestInfo>();
		String toLeadId = null;
		if (!leads.isEmpty()) {
			Lead__c lead = leads[0];
			String subId = lead.LeadIndexSubId__c;
			List<LeadIndex__c> indexLst = [select id,DepartureDate__c,EntryDate__c from leadindex__c where id=:subId];
			if (!indexLst.isEmpty()) {
				endDt = indexLst[0].DepartureDate__c;
				begDt = indexLst[0].EntryDate__c;
			}
			List<Lead__c> chkLeads = [select id,rroom__c,EntryTime__c,rroom__r.name,Field276__c from lead__c 
			                          where LeadIndexSubId__c= :subId and RoomGroupNo__c = :lead.RoomGroupNo__c and LeadIndexRef__c = :lead.LeadIndexRef__c and CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
			                          order by EntryTime__c];
			List<Lead__c> leadLst = new List<Lead__c>();
			Savepoint sp = Database.setSavepoint();
			try {
				// 自己房间就不判断了
				if (lead.rroom__c != roomid ) {
					RoomIndicatorInfo.MsgItem msgItem = null;
					if (!CommUtils.isBlank(roomid)) msgItem = RoomIndicatorInfo.preUpdateMemoryRoomLeadMap(lead.rroom__c ,lead.id,roomid, null, begDt.format(), chkLeads, null, true);
//System.debug(loggingLevel.info, 'msgItem='+msgItem);	
					if (msgItem == null || msgItem.isEmptyMsg || req.direct ) {
						// 同じ予約
						for ( Lead__c curLead : chkLeads) {
							if (roomid == null) curLead.rroom__c = null;
							else {
								curLead.rroom__c = roomid;
							}
							leadLst.add(curLead);
						}
						if (!leadLst.isEmpty()) update leadLst;
					} else {
						RequestInfo reqest = new RequestInfo();
						if (!CommUtils.isBlank(msgItem.errMsg)) {
							reqest.message = msgItem.errMsg;
							reqest.styp = 'error';
						} else {
							reqest.message = msgItem.infMsg;
							reqest.styp = 'warn';
						}
						reqest.id = lead.rroom__c;
						reqs.add(reqest);
					}
				}
			} catch(Exception e) {
				Database.rollback(sp);
				throw New CommException(CommUtils.getFieldValidationMessage(e.getMessage()));
			}
			// 房间变更后需要更新页面信息
			reqs.addAll(getRoomAssignJson(subId,lead.LeadIndexRef__c));
		// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy BEGIN
		} else if (kariLeadFlag) {
			if (!req.direct && !CommUtils.isBlank(roomid)) {
				List<RequestInfo> results = preUpdateMemoryRoomLeadMap(new List<RequestInfo>{req});
				if (!results.isEmpty()) reqs.addAll(results);
				else {
					req.styp = 'lead';
					reqs.add(req);
				}
			} else {
				req.styp = 'lead';
				reqs.add(req);
			}
		// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy END
		}
		reqs.addAll(getRoomRequestInfo(shopCode,begDt,endDt));
        return reqs;
	}
	// 获取subindex明細用JSON信息
	// 2019/11/15 一括予約画面の部屋直接選択 by zy BEGIN
	private static List<RequestInfo> getRoomAssignJson(String subId,String leadindex) {
		return getRoomAssignJson(subId,leadindex,null);
	}
	private static List<RequestInfo> getRoomAssignJson(String subId,String leadindex,String leadId) {
	// 2019/11/15 一括予約画面の部屋直接選択 by zy END
		List<RequestInfo> reqs = new List<RequestInfo>();
		Set<String> keySet = new Set<String>();
		// 2019/07/15 予約登録ボタンを押すと全く関係ない日付の予約情報により、アサイン注意の警告文が表示されます by zy BEGIN
		List<LeadIndex__c> subs = [select EntryDate__c,DepartureDate__c from LeadIndex__c where id = :subId];
		String ciDate = '';
		String coDate = '';
		if (!subs.isEmpty()) {
			ciDate = subs[0].EntryDate__c.format();
			coDate = subs[0].DepartureDate__c.format();
		}
		// 2019/07/15 予約登録ボタンを押すと全く関係ない日付の予約情報により、アサイン注意の警告文が表示されます by zy END
		// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy BEGIN
		for (Lead__c curLead : [select id,EntryTime__c,LeadIndexSubId__c,name,RoomGroupNo__c,LeadIndexRef__c,rroom__c,Rroom__r.name,Field276__c,refTypeOfRooms__c,Field4__c,Field3__c 
												// 2019/11/15 一括予約画面の部屋直接選択 by zy BEGIN
												,refTypeOfRooms__r.name
												// 2019/11/15 一括予約画面の部屋直接選択 by zy END
												from lead__c 
		// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy END
												where LeadIndexSubId__c= :subId 
													and CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 
													and LeadIndexRef__c = :leadindex order by EntryTime__c]) {
			// 2019/11/15 一括予約画面の部屋直接選択 by zy BEGIN
			if (!CommUtils.isBlank(leadId) && leadId != curLead.id) continue;
			// 2019/11/15 一括予約画面の部屋直接選択 by zy END
			String dtKey =	CommUtils.nullToBlank(curLead.LeadIndexRef__c) 
				+ '_' +	CommUtils.nullToBlank(curLead.LeadIndexSubId__c) 
				+ '_' +	CommUtils.nullToZero(curLead.RoomGroupNo__c);
			if (!keySet.contains(dtKey)) {
				// 2019/07/15 予約登録ボタンを押すと全く関係ない日付の予約情報により、アサイン注意の警告文が表示されます by zy BEGIN
				RequestInfo req = new RequestInfo(curLead);
				req.ci = ciDate;
				req.co = coDate;
				// 2019/11/15 一括予約画面の部屋直接選択 by zy BEGIN
				if (Commconst.BOOKING_FLEX_SEL_ROOM_FLG) {
					if(!CommUtils.isBlank(curLead.refTypeOfRooms__r.name)) req.nm += '(' + curLead.refTypeOfRooms__r.name + ')';
				}
				// 2019/11/15 一括予約画面の部屋直接選択 by zy END
				reqs.add(req);
				// 2019/07/15 予約登録ボタンを押すと全く関係ない日付の予約情報により、アサイン注意の警告文が表示されます by zy END
				keySet.add(dtKey);
			}
		}
		return reqs;
	}
	// 获取可分配房间
	private static List<RequestInfo> getRoomRequestInfo (String shopCode,Date begDt,Date endDt) {
	// 2019/07/31 20190729.01.一括予約の空部屋リスト表示不正の確認 by zy BEGIN	
		return getRoomRequestInfo(shopCode,begDt,endDt,null,null,null);
	}
	// 获取可分配房间
	private static List<RequestInfo> getRoomRequestInfo (String shopCode,Date begDt,Date endDt,String typeId,String it,String ot) {
	// 2019/07/31 20190729.01.一括予約の空部屋リスト表示不正の確認 by zy END	
		set<id> typeIdSet = new set<id>();
		// 2019/01/30 部屋タイプを選ぶ際、ユーザは複数店舗 by zy BEGIN
		List<String> shopCodes = getShopCodeRooms(shopCode);
		//List<TypeOfRooms__c> roomTypeLstRs = (new CommLogicProcess()).getTypeOfRooms(shopCode);
		List<TypeOfRooms__c> roomTypeLstRs = (new CommLogicProcess()).getTypeOfRooms(shopCodes);
		// 2019/01/30 部屋タイプを選ぶ際、ユーザは複数店舗 by zy END
		// 2019/07/31 20190729.01.一括予約の空部屋リスト表示不正の確認 by zy BEGIN
		// 2019/11/15 一括予約画面の部屋直接選択 by zy BEGIN
		boolean isHadType = CommUtils.isBlank(typeId);
		if (isHadType) {
		// 2019/11/15 一括予約画面の部屋直接選択 by zy END
		for (TypeOfRooms__c roomType: roomTypeLstRs) {
            typeIdSet.add(roomType.Id);
        }
		} else typeIdSet.add(typeId);
		Datetime startDt = CommUtils.convertDatetime(begDt,CommUtils.nullToBlank(it));
        Datetime endTime = CommUtils.convertDatetime(endDt,CommUtils.nullToBlank(ot));
		List<Room__c> roomLst = getRoomLstByType(shopCode,startDt,endTime,typeIdSet);
		// getRoomLstByType(typeIdSet,shopCode,begDt,endDt);
		// 2019/07/31 20190729.01.一括予約の空部屋リスト表示不正の確認 by zy END
        List<RequestInfo> reqs = new List<RequestInfo>();
        if (!roomLst.isEmpty()) {
	        for (Room__c room : roomLst) {
	        	RequestInfo res = new RequestInfo();
	        	res.tid = room.TypeRoomRef__c;
	        	res.id = room.id;
	        	res.nm = room.name;
				// 2019/11/15 一括予約画面の部屋直接選択 by zy BEGIN
				if (isHadType) res.nm += '(' + room.TypeRoomRef__r.name + ')';
				// 2019/11/15 一括予約画面の部屋直接選択 by zy BEGIN
	        	reqs.add(res);
	        }
        }
        return reqs;
	}
	private String getRoomStockKey(Id rommTypeId, Date dt) {
		if (rommTypeId == null) return DateTime.newInstance(dt,Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd HH:mm:ss');
		else return rommTypeId + '_' + DateTime.newInstance(dt,Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd HH:mm:ss');
	}
	// 2017/12/25 部屋自動割り当て機能追加　by　zy END
	// 2017/12/25 親部屋機能処理　by　zy BEGIN
	// 主房间予約更新
	private List<Leadindex__c> getParentSubId(List<LeadIndex__c> indexSub,String leadIdxId,Set<String> mainLeadNameSet) {
		String mainId = null;
		List<Leadindex__c> subLst = new List<Leadindex__c>();
		List<Leadindex__c> otherLst = new List<Leadindex__c>();
		List<Id> subMaintLst = new List<Id>();
		List<Id> otherMainLst = new List<Id>();
		for (LeadIndex__c leadIdx : indexSub) {
			Id leadIndexId = leadIdx.id;
			// 親予約インデックスの明細
			if ( leadIdx.ParentLeadIndxRef__c == leadIdxId ) {
				subLst.add(leadIdx);
				if (leadIdx.ParentFlg__c) {
					mainId = leadIndexId;
					continue;
				}
				if (mainLeadNameSet.contains(leadIndexId)) subMaintLst.add(leadIndexId);
			// 別々の予約インデックス
			} else {
				if (mainLeadNameSet.contains(leadIndexId)) otherMainLst.add(leadIndexId);
				otherLst.add(leadIdx);
			}
		}
		// index排序
		//List<Leadindex__c> sortLst = new List<Leadindex__c>();
		//sortLst.addAll(subLst);
		//sortLst.addAll(otherLst);
		//indexSub = sortLst;
		// 親明細設定
		// 不含主房间的情况下
		if (CommUtils.isBlank(mainId)) {
			// 含有符号的
			if (!subMaintLst.isEmpty()) parentSubId = subMaintLst[0];
			else if (!subLst.isEmpty()) parentSubId =  subLst[0].id;
			else if (!otherMainLst.isEmpty()) parentSubId =  otherMainLst[0]; 
			else if (!otherLst.isEmpty()) parentSubId =  otherLst[0].id;
		} else parentSubId = mainId;
		return indexSub;
	}
	class RequestInfo{
		// C/I日付
		String ci;
		// C/O日付
		String co;
		// 部屋タイプid
		String tid;
		// 部屋id
		String id; 
		// 部屋名
		String nm;
		// 予約 id
		String lid;
		// SUBインデックスid
		String sid;
		String spcd;
		String styp;
		String ldxid;
		String message;
		boolean lock;
		// 直接保存还是进行errorcheck
		boolean direct;
		// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy BEGIN
		Date begDt;
		Date endDt;
		String rowNo;
		String it; // チェックインタイム
		String ot; // チェック
		// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy END
		public RequestInfo(){}
		public RequestInfo(lead__c lead) {
			// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy BEGIN
			id = CommUtils.nullToBlank(lead.rroom__c);
			sid = CommUtils.nullToBlank(lead.LeadIndexSubId__c);
			tid = CommUtils.nullToBlank(lead.refTypeOfRooms__c);
			// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy END
			nm = lead.rroom__r.name;
			lid = lead.id;
			styp = 'lead';
			lock = lead.Field276__c;
		}
	}
	// 2017/12/25 親部屋機能処理　by　zy END
	// 2018/10/25 複数作成の操作方法が、マニュアルがなくても操作方法がわかると良いかと感じました。 by cxw BEGIN
	public Integer getQuotaItemNum(){
		String id = newLead.id;
		Integer cnt = 1;
		if(id != null){
			try{
				String sql = 'select count() from Quota__c where LeadRef__c =:id';
				cnt += Database.countQuery(sql);
			}catch(Exception e){}
		}
		return cnt;
	}
	// 2018/10/25 複数作成の操作方法が、マニュアルがなくても操作方法がわかると良いかと感じました。 by cxw END
	// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy BEGIN
	private List<String> roomJsons;
	@remoteaction
	public static object remoteCenter(String dataType,String request){
		// 予約データ事前チェック
		if (dataType == 'preUpdateLead') return preUpdateLead(request);
		return null;
	}
	// 予約データ事前チェック
	private static object preUpdateLead(String request){
		List<RequestInfo> roomsLst = CommUtils.isBlank(request) ? 
							new List<RequestInfo>() :
								 (List<RequestInfo>)JSON.deserialize(request, List<RequestInfo>.class);
		if (roomsLst.isEmpty()) return roomsLst;
		// 予約データ事前チェック
		List<RequestInfo> results = preUpdateMemoryRoomLeadMap(roomsLst);
		return results;
	}
	private static final Boolean leadQueryRecTypeFlg = (CommDefine__c.getOrgDefaults().RoomIndicatorQueryLimitFlg__c == null ? false : CommDefine__c.getOrgDefaults().RoomIndicatorQueryLimitFlg__c);
	private static List<RequestInfo> preUpdateMemoryRoomLeadMap(List<RequestInfo> reqs) {
		List<RequestInfo> results = new List<RequestInfo>();
		List<Id> recTypeLst = RoomIndicatorInfo.getLeadBookingRecTypeLst();
		// 予約に部屋アサインを行う
		// 選択した予約関連の予約データはLeadIndexSubの関連一括予約を一括アサインする
		// リードを検索して、該当リードに部屋アサインを行う
		// 移動元側予約データに部屋BLOCKのデータ有り・なしチェックを行う
		// 該当部屋はすでに予約されているがどうか、チェックを行う
		// アサインする部屋はすでに予約にアサインされているがどうか、チェックを行う
		// 2018/02/06 予約検索条件はレコードタイプ外す改善対応 BEGIN
		Integer cancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
		Date beginDate;
		Date endDate;
		Map<Id,List<RequestInfo>> roomReq = new Map<Id,List<RequestInfo>>();
		//　連泊取得する
		for (RequestInfo req : reqs) {
			// 未割当部屋
			if (CommUtils.isBlank(req.id)) continue;
			req.begDt = CommUtils.isBlank(req.ci) ? system.today() : CommUtils.stringtoDate(req.ci);
			req.endDt = CommUtils.isBlank(req.co) ? system.today() : CommUtils.stringtoDate(req.co);
			if (beginDate == null || beginDate > req.begDt) beginDate = req.begDt;
			if (endDate == null || endDate < req.endDt) endDate = req.endDt;
			if (!roomReq.containsKey(req.id)) roomReq.put(req.id,new List<RequestInfo>());
			roomReq.get(req.id).add(req);
		}
		Set<Id> roomIds = roomReq.keySet();
		// 故障部屋チェック
		List<RoomsStatus__c> rooms = (new RoomStatusManager()).queryBadRoomList(beginDate,endDate,roomIds);
		String message = '';
    	for (RoomsStatus__c roomStatus : rooms) {
    		if (!roomReq.containsKey(roomStatus.RoomRef__c)) continue;
    		if (CommUtils.isBlank(roomStatus.BeginTime__c)) roomStatus.BeginTime__c = RoomStatusManager.DEF_START_TIME;
   			if (CommUtils.isBlank(roomStatus.OverTime__c)) roomStatus.OverTime__c = RoomStatusManager.DEF_END_TIME;
            Datetime badBeginTm = CommUtils.convertDatetime(roomStatus.StatusBeginDate__c,roomStatus.BeginTime__c);
            Datetime badEndTm = CommUtils.convertDatetime(roomStatus.StatusEndDate__c,roomStatus.OverTime__c);
    		List<RequestInfo> roomReqs = roomReq.get(roomStatus.RoomRef__c);
        	List<RequestInfo> lastReqs = new List<RequestInfo>();
    		for (integer i = 0 ; i < roomReqs.size() ; i++) {
    			RequestInfo req = roomReqs[i];
    			Datetime startDt = CommUtils.convertDatetime(req.begDt,req.it);
    			Datetime endDt = CommUtils.convertDatetime(req.endDt,req.ot);
    			// 故障データ管理時間
    			if (startDt >= badEndTm || endDt <= badBeginTm) lastReqs.add(req);
    			else {
    				req.message = '明細行[' + req.rowNo + ']'+ (Label.MSG_002_0376 + roomStatus.StatusBeginDate__c.format() + Label.MSG_002_0377 +'['+roomStatus.RoomRef__r.name+']'+ Label.MSG_002_0378) +'\n';
        			req.styp = 'error';
        			results.add(req);
    			}
    		}
    		if (lastReqs.isEmpty()) roomReq.remove(roomStatus.RoomRef__c);
    		else roomReq.put(roomStatus.RoomRef__c,lastReqs);
    	}
    	// 
    	if (!results.isEmpty()) return results; 
        String existLeadQuery = 'Select Id,Name,Rroom__r.Name,EntryTime__c,Field276__c,LeadIndexSubId__c,field4__c,Departure__c,field3__c From Lead__c '
                            + 'Where CancelBool__c != :cancelFlg '
                            + 'And DAY_ONLY(convertTimezone(EntryTime__c)) >= :beginDate '
                            + 'And DAY_ONLY(convertTimezone(EntryTime__c)) <= :endDate '
                            + 'And Rroom__c = :roomIds ';
        if (leadQueryRecTypeFlg == false ) {
            existLeadQuery += 'And RecordTypeId in :recTypeLst ';
        }
        existLeadQuery += ' Order By EntryTime__c';
        List<Lead__c> existLeadLst = DataBase.query(existLeadQuery);
        // 予約フィルター
        if (!existLeadLst.isEmpty()) {
        	for (Lead__c l : existLeadLst) {
        		if (!roomReq.containsKey(l.Rroom__c)) continue;
        		List<RequestInfo> roomReqs = roomReq.get(l.Rroom__c);
        		List<RequestInfo> lastReqs = new List<RequestInfo>();
        		for (integer i = 0 ; i < roomReqs.size() ; i++) {
        			RequestInfo req = roomReqs[i];
        			// 相同subindex下不进行警告
        			if ((!CommUtils.isBlank(req.sid) && req.sid == l.LeadIndexSubId__c)) continue;
					// 2019/07/31 20190729.01.一括予約の空部屋リスト表示不正の確認 by zy BEGIN
					Datetime startDt = CommUtils.convertDatetime(req.begDt,req.it);
    				Datetime endDt = CommUtils.convertDatetime(req.endDt,req.ot);
					Datetime leadDt = CommUtils.convertDatetime(l.EntryTime__c.date(),l.field4__c);
					Datetime leadEndDt = CommUtils.convertDatetime(l.Departure__c.date(),l.field3__c);
        			if (!(leadDt > endDt || leadEndDt < startDt)){
					// if (l.EntryTime__c.date() >= req.begDt && l.EntryTime__c.date() <= req.endDt) {
					// 2019/07/31 20190729.01.一括予約の空部屋リスト表示不正の確認 by zy END
	        			req.message = '明細行[' + req.rowNo + ']'+ Label.MSG_008_0113.replace('XXXXXX',l.Rroom__r.Name) +'\n';
	        			req.message += l.Name + ' ['+l.EntryTime__c.format(g_DateFormat)+']\n';
	        			req.styp = 'warn';
	        			results.add(req);
	        		} else lastReqs.add(req);
        		}
        		if (lastReqs.isEmpty()) roomReq.remove(l.Rroom__c);
        		else roomReq.put(l.Rroom__c,lastReqs);
        	}
        }
		return results;
	}
	// 2019/01/30 一画面、部屋タイプ　部屋の選択 by zy END
	// 2019/01/30 部屋タイプを選ぶ際、ユーザは複数店舗 by zy BEGIN
	private static final Boolean bookingFlexSpcdFlag = (CommDefine__c.getOrgDefaults().BookingFlexShopsFlag__c == null ? false : CommDefine__c.getOrgDefaults().BookingFlexShopsFlag__c);
	private static List<String> getShopCodeRooms(String shopCode){
		List<String> shopCodes = bookingFlexSpcdFlag ? UserUtil.CurrentUserInfo.shops : 
									CommUtils.isBlank(shopCode) ? new List<String>() : new List<String>{shopCode};
		return shopCodes;
	}
	// 2019/01/30 部屋タイプを選ぶ際、ユーザは複数店舗 by zy END
	// 2019/07/31 20190729.01.一括予約の空部屋リスト表示不正の確認 by zy BEGIN
	private static List<Room__c> getRoomLstByType(String shopCode,Datetime startDt,Datetime endDt,Set<Id> typeIdSet) {
		List<Room__c> results = new List<Room__c>();
		List<Id> recTypeLst = RoomIndicatorInfo.getLeadBookingRecTypeLst();
		// 予約に部屋アサインを行う
		// 選択した予約関連の予約データはLeadIndexSubの関連一括予約を一括アサインする
		// リードを検索して、該当リードに部屋アサインを行う
		// 移動元側予約データに部屋BLOCKのデータ有り・なしチェックを行う
		// 該当部屋はすでに予約されているがどうか、チェックを行う
		// アサインする部屋はすでに予約にアサインされているがどうか、チェックを行う
		// 2018/02/06 予約検索条件はレコードタイプ外す改善対応 BEGIN
		Integer cancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
		Date beginDate = startDt.date();
		Date endDate = endDt.date();
		String QueryHeader = 'select id,name,TypeRoomRef__c,TypeRoomRef__r.name from room__c ';
		 // 各部屋のステータス取得する
	    String queryWhere = ' where UseOfRoom__c = \'' + String.escapeSingleQuotes(CommConst.ROOM_UseOfType_Guest) + '\' ';
		// 2019/01/30 部屋タイプを選ぶ際、ユーザは複数店舗 by zy BEGIN
		if (!CommUtils.isBlank(shopCode) && !bookingFlexSpcdFlag) {
		// 2019/01/30 部屋タイプを選ぶ際、ユーザは複数店舗 by zy END
			queryWhere+= ' And ShopInfoRef__r.ShopCode__c = \'' + String.escapeSingleQuotes(shopCode) + '\'';
		}else if (UserUtil.CurrentUserInfo.isShopCodePlex) {
			Set<String> shopSt = UserUtil.CurrentUserInfo.shopSt;
			queryWhere+= ' And ShopInfoRef__r.ShopCode__c in :shopSt';
		}
		// 2019/11/15 一括予約画面の部屋直接選択 by zy BEGIN
		if(!typeIdSet.isEmpty()) queryWhere+= ' And TypeRoomRef__c = :typeIdSet';
		// 2019/11/15 一括予約画面の部屋直接選択 by zy END
        // 2013/05/22 部屋並べ替え機能修正
        String queryOrder = ' Order By AREA__c asc, Floor__c asc, ';
        if (ROOM_SORT_DIV == ROOM_SORT_NAME_DIV) {
        	queryOrder += ' Seq__c asc ';
        } else {
        	queryOrder += ' DisplayNo__c asc ';
        }
        String queryStr = QueryHeader + queryWhere + queryOrder;
		// 部屋リストを取得する
		Map<Id,Room__c> canUseRoomMap = new Map<Id,Room__c>();
        // 各部屋情報を取得する
        for (Room__c s: Database.query(queryStr)) {
			canUseRoomMap.put(s.id,s);
        }
		// 故障部屋チェック
		List<RoomsStatus__c> rooms = (new RoomStatusManager()).queryBadRoomList(beginDate,endDate,canUseRoomMap.keySet());
    	for (RoomsStatus__c roomStatus : rooms) {
    		if (CommUtils.isBlank(roomStatus.BeginTime__c)) roomStatus.BeginTime__c = RoomStatusManager.DEF_START_TIME;
   			if (CommUtils.isBlank(roomStatus.OverTime__c)) roomStatus.OverTime__c = RoomStatusManager.DEF_END_TIME;
            Datetime badBeginTm = CommUtils.convertDatetime(roomStatus.StatusBeginDate__c,roomStatus.BeginTime__c);
            Datetime badEndTm = CommUtils.convertDatetime(roomStatus.StatusEndDate__c,roomStatus.OverTime__c);
    		// 故障データ管理時間
			if (!(startDt >= badEndTm || endDt <= badBeginTm)) canUseRoomMap.remove(roomStatus.RoomRef__c);
    	}
    	// 
    	if (canUseRoomMap.isEmpty()) return results; 
		Set<Id> existRoomIdSet = canUseRoomMap.keySet();
        String existLeadQuery = 'Select Id,Name,Rroom__r.Name,EntryTime__c,Departure__c,Field4__c,Field3__c,Field276__c,LeadIndexSubId__c From Lead__c '
                            + 'Where CancelBool__c != :cancelFlg '
                            + 'And DAY_ONLY(convertTimezone(EntryTime__c)) >= :beginDate '
                            + 'And DAY_ONLY(convertTimezone(EntryTime__c)) <= :endDate '
                            + 'And Rroom__c = :existRoomIdSet ';
        if (leadQueryRecTypeFlg == false ) {
            existLeadQuery += 'And RecordTypeId in :recTypeLst ';
        }
        existLeadQuery += ' Order By EntryTime__c';
        List<Lead__c> existLeadLst = DataBase.query(existLeadQuery);
        // 予約フィルター
        if (!existLeadLst.isEmpty()) {
        	for (Lead__c l : existLeadLst) {
        		if (!canUseRoomMap.containsKey(l.Rroom__c)) continue;
				Datetime leadDt = CommUtils.convertDatetime(l.EntryTime__c.date(),l.field4__c);
				Datetime departDt = CommUtils.convertDatetime(l.Departure__c.date(),l.Field3__c);
				if (!(leadDt >= endDt || departDt <= startDt)) canUseRoomMap.remove(l.Rroom__c);
        	}
        }
		return canUseRoomMap.values();
	}
	// 2019/07/31 20190729.01.一括予約の空部屋リスト表示不正の確認 by zy END
	// 2019/10/15 .ルームインジケータで1室押さえ、それから一括予約で部屋を増やした場合、親部屋の「●」が動的に付与されません。自動化をお願いします by zy BEGIN
	// 親明細の予約名変更
	private void chgParSubLeadName(String parId,String subId){
		// 予約名●チェック
		String namePrefix = LEAD_NAME_PREFIX + '%';
		// 保存リスト
		List<Lead__c> updLeads = new List<Lead__c>();
		for (Lead__c lead : [Select id,name,LeadIndexSubId__c,RoomGroupNo__c from lead__c where LeadIndexRef__c = :parId and CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG  and (name like :namePrefix or (LeadIndexSubId__c =:subId and RoomGroupNo__c = 0))]){
			if (lead.LeadIndexSubId__c != mainSubId && lead.name.startswith(LEAD_NAME_PREFIX)){
				lead.name = lead.name.replace(LEAD_NAME_PREFIX,'');
				updLeads.add(lead);
			} else if(lead.LeadIndexSubId__c == mainSubId && lead.RoomGroupNo__c == 0 && !lead.name.startswith(LEAD_NAME_PREFIX)) {
				lead.Name = LEAD_NAME_PREFIX + lead.Name;
				updLeads.add(lead);
			}
		}
		if (!updLeads.isEmpty()){ 
			DataFixManagerUtils.stopTranTriggger();
			update updLeads;
			DataFixManagerUtils.begTranTriggger();
		}
	}
	// 2019/10/15 .ルームインジケータで1室押さえ、それから一括予約で部屋を増やした場合、親部屋の「●」が動的に付与されません。自動化をお願いします by zy END
	// 2019/11/15 一括予約画面での項目編集を親部屋以外にも反映してほしい by zy BEGIN
	private boolean saveSubIndxFlg;
	// 2019/11/15 一括予約画面での項目編集を親部屋以外にも反映してほしい by zy END
	// 2019/11/15 一括予約画面の部屋直接選択 by zy BEGIN
	public boolean selRoomModeFlg{get;set;}
	// 2019/11/15 一括予約画面の部屋直接選択 by zy END
	// 2019/11/15 一括予約のコピー時にアサインされている部屋もコピーしてほしい、アサイン部屋もコピーしないと手間が増えてしまいます。by zy BEGIN
	public boolean cloneRoomExitModeFlg{get;set;}
	private void initReleatSet(){
		String defNamePrix = 'BookingFlexAppLayoutDefine';
		cloneRoomExitModeFlg = false;
		// 2020/02/28 一括予約画面 延泊した際、アサイン済みの部屋は自動で延泊分もアサインされるように by zy BEGIN
		isChgNitghtCopyRoomFlg = true;
		// 2020/02/28 一括予約画面 延泊した際、アサイン済みの部屋は自動で延泊分もアサインされるように by zy END
		// 複数レイアウト定義情報を取得する
		Dom.XMLNode targetNode = CommXmlUtils.parseXmlDoc(defNamePrix,branchNm);
		if (targetNode != null) {
			Dom.XMLNode exitNode = targetNode.getChildElement('CLONEROOMEXIT',null);
			if (exitNode != null) {
				cloneRoomExitModeFlg = boolean.valueof(CommUtils.nullToBlank(exitNode.getText()));
			}
			// 2020/02/28 一括予約画面 延泊した際、アサイン済みの部屋は自動で延泊分もアサインされるように by zy BEGIN
			Dom.XMLNode chgRoomNode = targetNode.getChildElement('CHGNOTCOPYROOM',null);
			if (chgRoomNode != null){
				String copyRoomFlg = chgRoomNode.getText();
				if (!CommUtils.isBlank(copyRoomFlg))
					isChgNitghtCopyRoomFlg  = boolean.valueOf(CommUtils.nullToBlank(copyRoomFlg));
			}
			// 2020/02/28 一括予約画面 延泊した際、アサイン済みの部屋は自動で延泊分もアサインされるように by zy END
		}
	}
	// 2019/11/15 一括予約のコピー時にアサインされている部屋もコピーしてほしい、アサイン部屋もコピーしないと手間が増えてしまいます。by zy END
	// 2020/02/28 一括予約画面 延泊した際、アサイン済みの部屋は自動で延泊分もアサインされるように by zy BEGIN
	private boolean isChgNitghtCopyRoomFlg;
	// 2020/02/28 一括予約画面 延泊した際、アサイン済みの部屋は自動で延泊分もアサインされるように by zy END
}