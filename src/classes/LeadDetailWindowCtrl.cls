/**
* 2019/12/30 名前か電話番号のどちらかだけ一致するお客様がすでに存在する
**/
global with sharing class LeadDetailWindowCtrl {
	public String branchShopNm{get;set;}
	 // 本物の予約ID判別用キー
	public static final String leadPreFixKey{get; private set;}
    // 2013/10/12 DB更新処理標識フラグ
	public Boolean bookingCreateOK{get;set;}
	// 詳細画面情報維持
	public RoomInfo RoomDetail{get;set;}
	public String strLeadId{get;set;}
	public String groupLeadIds{get;set;}
	public boolean isGroupFlg{get;set;}
	public boolean isShowGroupConfirm{get; private set;}
	public boolean isShowGroupClConfirm{get; private set;}
	// 2019/07/15 多泊の場合、外出の場合、多泊の予約に同じ状態を更新する BY zyz BEGIN
	public boolean isShowGroupOIConfirm{get; private set;}
	// 2019/07/15 多泊の場合、外出の場合、多泊の予約に同じ状態を更新する BY zyz END
	// ご予約へ編集権限あり、なし
	public boolean isCanUpdateLead{get{return CommSecurityUtils.isCanUpdateLead();}}
	public boolean isShwoGroupCancelConfirm{get{return CommDefine__c.getOrgDefaults().RoomIndicatorGpClMsgIsShow__c;}}
	// 2017/01/05 予約のキャンセルボタンを表示する・しない対応 BEGIN by wx
	public boolean roomIndicatorIsShowLeadCancelBtn{get{return CommDefine__c.getOrgDefaults().RoomIndicatorIsShowLeadCancelBtn__c;}}
	// 2017/01/05 予約のキャンセルボタンを表示する・しない対応 END by wx
	//お客様の項目は更新フラグ
    public Boolean hadUpdContactFlag{get;set;} 
    // 変更情報格納用クラス
	public PopupWinInfo leadInfo{get; set;}
	// 画面にカスタムセクション
    public List<PageCustomeFieldHelper.SectionInfo> pageLst{get;set;}
    // 空白行高度
    public Boolean isLineHeightFlg{get;set;}
    //字段参照类型集合 
    private static final String blankString = '$_blank_$';
   	public Decimal widthPx{get; set;}
   	public String heightPx{get; set;}
    //详细画面用字段
    public String contactFields{get;set;}
    // 人数表示情報
    private static final String CONST_STAYPERSONS_ADULTS = '$_STAYPERSON_$'+ Label.CONST_008_0117 +'（'+ Label.CONST_008_0118 +'$_MANS_$ '+ Label.CONST_008_0119 +'$_FEMALE_$$_CHILDS_$）';
    private static final String CONST_STAYPERSONS_CHILDS = Label.CONST_008_0120 +'$_CHILDREN_$'+ Label.CONST_008_0117 +'（A:$_CHILDA_$, B:$_CHILDB_$, C:$_CHILDC_$, D:$_CHILDD_$$_CHILDE_$$_CHILDF_$）';
    // 2013/05/23 部屋表示サイズ調査対応
	private static final Integer ROOM_INFO_MAX_SIZE = CommDefine__c.getOrgDefaults().RoomIndicatorInfoMaxLength__c == null ? 4 : (CommDefine__c.getOrgDefaults().RoomIndicatorInfoMaxLength__c.intValue() < 4 ? 4 : CommDefine__c.getOrgDefaults().RoomIndicatorInfoMaxLength__c.intValue());
    //2013/07/22 部屋約名標識
	public static Integer ROOM_INFO_NAME_TYPE_GUESTNAME	{get{return 1;}}
	public static Integer ROOM_INFO_NAME_TYPE_LEADNAME	{get{return 2;}}
	private static final Integer ROOM_INFO_NAME_TYPE = CommDefine__c.getOrgDefaults().RoomIndicatorInfoNameType__c == null ? ROOM_INFO_NAME_TYPE_GUESTNAME : CommDefine__c.getOrgDefaults().RoomIndicatorInfoNameType__c.intValue();
	
	 // -------------------------------------------
   	// 予約新規登録機能対応開始
   	// 各店舗の表示する項目情報を取得、格納を行う
    // -------------------------------------------
    //private static final String LeadConstFields  = 'Name,Relcontact__c,refTypeOfRooms__c,EntryTime__c,Field4__c,Departure__c,Field3__c,StayPersons__c,SeminarOrderFlg__c,ExtraBedChk__c,Rroom__c,Field310__c,Field315__c,Field2__c,Segment__c,Comment3__c';
    private static final Set<String> queryDefFieldSet = new Set<String>{'Id','LeadIndexRef__c','Name','RecordType.Name','Relcontact__r.Name','Relcontact__c','nights','Field298__c','EntryTime__c','Departure__c','StayPersons__c','Field2__c','Field310__c','Rroom__c','Comment3__c'};
    private static final Set<String> leadQuerySet = new Set<String>{'Id','LeadIndexRef__c','Name','Relcontact__r.Name','Field298__c','StayPersons__c','Field2__c','Comment3__c','Rroom__r.Name','Relcontact__r.Id','Field310__r.Name','LeadIndexRef__r.Name','Field276__c','LeadIndexSubId__c','RoomGroupNo__c'};
    // 2017/08/17 ルームインジケータ画面に、縦セルに表示項目をカスタマイズできるように改善対応 WGCH BEGIN
    //　部屋枠に個別表示したい項目APIリスト情報を格納する
    public List<String> roomExtLeadFieldApiLst{get;private set;}
    // 2017/08/17 ルームインジケータ画面に、縦セルに表示項目をカスタマイズできるように改善対応 WGCH END
    public String mulitiCheckoutLabel{get;private set;}
    // 2019/02/28 滞在・外出状態の管理 WGCH BEGIN
    public String mulitiOutLabel{get;private set;}
    public String mulitiCheckinLabel{get;private set;}
    public Boolean outButtonShowFlg{get{return RoomIndicatorInfo.outButtonShowFlg;}}
    // 2019/02/28 滞在・外出状態の管理 WGCH END
    public Contact newContact{get;set;}
    // 延泊処理時の見積自動コピー機能対応
	private static final Boolean isCloneBookEstFlg = CommDefine__c.getOrgDefaults().RoomIndicatorEstIsCloneFlg__c;
	// 見積書の宛名
    // 会計種別：プラン
    public String ACTTYPE_PLAN{get{return CommConst.PROD_ACTION_TYPE_PL;}}
    public String ACTTYPE_PAY{get{return CommConst.PROD_ACTION_TYPE_PY;}}   // 支払
    public String ACTTYPE_AR {get{return CommConst.PROD_ACTION_TYPE_AR;}}   // 前受金
    // 2013/08/11 予約名
	private static final String LEAD_NAME_PREFIX = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomDelegatePrefix__c);
	// 2017/05/22 レジカードサイン機能 zyz 
	public Boolean isCashRegisterSignFlg{get{return CommDefine__c.getOrgDefaults().CashRegisterSign__c == null ? false :  CommDefine__c.getOrgDefaults().CashRegisterSign__c;}}
	/**
	* XML定義情報取得、表示を行う
	* 必ず画面初期表示の場合、一番上に該当MethodをVFから呼び出すするが必要  
	**/
    public String getInitXmlDefineInfo () {
    	// 初期化
    	refeshDomNode();
    	setMulitiCheckoutLabelFun();
    	leadInfo = new PopupWinInfo();
    	RoomDetail = new RoomInfo();
    	RoomDetail.leadDetail = new Lead__c(RecordTypeId = CommLogicProcess.getLeadBookingRecType());
    	newContact = new Contact();
    	isShowGroupConfirm = CommConst.APPOTION_CHECKIN_GROUPCONFIRM;
        isShowGroupClConfirm = CommConst.APPOTION_CHECKIN_GROUPCLCONFIRM;
        // 2019/07/15 多泊の場合、外出の場合、多泊の予約に同じ状態を更新する BY zyz BEGIN
        isShowGroupOIConfirm = CommConst.APPOTION_OUT_GROUPCONFIRM;
        // 2019/07/15 多泊の場合、外出の場合、多泊の予約に同じ状態を更新する BY zyz END
    	return '';
    }
    /**
	* 予約情報チャンジ処理を行う
	* 泊数変更機能対応
	**/
	public void chgSaveNightsInfo () {
		// クリックした予約ID
		String leadId = strLeadId; //leadInfo.leadId;
		// 最新の予約情報を取得する
		List<Lead__c> leadInfLst = [select id, LeadIndexRef__c, LeadIndexSubId__c,RoomGroupNo__c,
									refTypeOfRooms__c, StayPersons__c
									,ExtraBedChk__c,Field310__c
									from Lead__c 
									where Id = :leadId And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG  ];
		// 既存有効な予約データが見つからない場合
		if (leadInfLst.isEmpty()) {
			//該当予約データが見つかりません。
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_008_0103));
			return;
		}
		
		// 入力情報により、関連の予約情報を一括変更を行う
		// 泊数、最後の出発日変更対応を行う
		// 同じグループNO、同じSUBINDEXの予約データは連動更新を行う
		List<Lead__c> leads = [select id, Name,Rroom__c,UnitPriceDefKbCal__c,Relcontact__c,
				StayPersons__c,EntryTime__c,Departure__c,Field4__c,Field3__c,Comment3__c
			from Lead__c 
			where LeadIndexRef__c = :leadInfLst[0].LeadIndexRef__c 
			And LeadIndexSubId__c = :leadInfLst[0].LeadIndexSubId__c
			And RoomGroupNo__c = :leadInfLst[0].RoomGroupNo__c
			And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 
			Order By EntryTime__c ] ;
		// 到着時刻と出発時刻を変更される場合
		Boolean timeChangeFlg = false;
		for (Lead__c upd : leads) {
			if (upd.Field4__c != leadInfo.entryTime || upd.Field3__c != leadInfo.departureTime) {
				timeChangeFlg = true;
				upd.Field4__c = leadInfo.entryTime;
				upd.Field3__c = leadInfo.departureTime;
			}
		}
Savepoint sp = Database.setSavepoint();
try {
		// 2018/03/07 Security Check BEGIN
		List<String> chkFieldsLst = new List<String>{'name','reservedstatus__c','reserveddate__c','reservedcontact__c',
													'field276__c','entrytime__c','departure__c','field298__c','unitpricedefkb__c','field3__c','field4__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.Lead__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
			return ;
		}
		// 2018/03/07 Security Check END
		// 2018/03/07 Security Check BEGIN
		List<String> chkFieldLst = new List<String>{'staypersons__c','rooms__c','roomtyperef__c','planref__c',
													'parentleadindxref__c','nights__c','extrabedchk__c','entrydate__c','departuredate__c'};
		Map<String,Schema.SObjectField> mmm = Schema.SObjectType.LeadIndex__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFieldLst, mmm)) {
			return ;
		}
		// 2018/03/07 Security Check END
		//2016/11/25 お客様の項目の入力機能追加　BEGIN
		if(hadUpdContactFlag){
			newContact.id = leads[0].Relcontact__c;
			upsertCustomContact();
			bookingCreateOK = true;
		}
		//2016/11/25 お客様の項目の入力機能追加　END
		// 泊数の日付情報
		Date startDate = leads[0].EntryTime__c.date();
		Date endDate = leads[leads.size()-1].Departure__c.date();
		// XML___wgch 2016/11/16 特記事項 BEGIN
		String oldComment3 = leads[0].Comment3__c;
		String newComment3 = leadInfo.Comment3;
		// XML___wgch 2016/11/16 特記事項 END
		// 元泊数 / 新泊数
		Integer orgNights = startDate.daysBetween(endDate);
		Integer newNights = Commutils.nullToZero(leadInfo.nights).intValue();
		// 新予約人数/元予約人数
		Integer leadPeopleNum = Commutils.nullToZero(leadInfo.leadPeopleNum).intValue();
		Integer orgLeadPeopleNum = Commutils.nullToZero(leadInfo.orgLeadPeopleNum).intValue();
		// 変更なし[泊数・人数]
		//if (orgNights == newNights && leadPeopleNum == orgLeadPeopleNum && !timeChangeFlg) return;
		// XML___wgch 2016/11/16 特記事項 BEGIN 
		if (orgNights == newNights && leadPeopleNum == orgLeadPeopleNum && !timeChangeFlg && oldComment3 == newComment3) return;
		// XML___wgch 2016/11/16 特記事項 END
		// ------------------------------------------
		// SUBINDEX関連情報の自動設定対応
		// ------------------------------------------
		// SUBINDEXのID対応の実データが未存在する場合、下記処理を行う
		if (!CommUtils.isBlank(leadInfLst[0].LeadIndexSubId__c)) {
			List<LeadIndex__c> subIdxExistChkLst = [select id from LeadIndex__c where id = :leadInfLst[0].LeadIndexSubId__c];
			if (subIdxExistChkLst.isEmpty()) leadInfLst[0].LeadIndexSubId__c = null;
		}
		// SubIndex関連情報を取得、再設定を行う
		String subIdxId = leadInfLst[0].LeadIndexSubId__c == null ? leadInfLst[0].LeadIndexRef__c : leadInfLst[0].LeadIndexSubId__c;
		String subIdxQueryStr = CommSqlUtils.generateQueryString('LeadIndex__c');
		subIdxQueryStr += ' Where Id = :subIdxId ';
		List<LeadIndex__c> idxLsts = DataBase.query(subIdxQueryStr);
		// 部屋数は１以上の場合、
		// TODO:元SUBINDEXに、複数部屋は存在する場合、この一つの部屋の期間を調整する場合
		// 該当予約関連のSUBINDEXは自動新規作成を行う
		// 該当SUBINDEXだけ存在する場合、直接SUBINDEX新規・更新を行う
		LeadIndex__c subIdx = null;

		// SUBINDEXは未存在する場合、予約インデクスから自動コピー、設定を行う
		if (leadInfLst[0].LeadIndexSubId__c == null) {
			// INDEXからコピーして、SUBINDEXを作成する
			subIdx = idxLsts[0].clone(false,true);
			subIdx.ParentLeadIndxRef__c = idxLsts[0].Id;
			subIdx.RoomTypeRef__c = leadInfLst[0].refTypeOfRooms__c;
			subIdx.StayPersons__c = leadInfLst[0].StayPersons__c;
			subIdx.PlanRef__c = leadInfLst[0].Field310__c;
			subIdx.ExtraBedChk__c = leadInfLst[0].ExtraBedChk__c;
			subIdx.Rooms__c = 1;
		} else {
			// SUBINDEX情報を設定する
			if (idxLsts[0].Rooms__c > 1) {
				subIdx = idxLsts[0].clone(false,true);
				subIdx.Rooms__c = 1;
				subIdx.RoomTypeRef__c = leadInfLst[0].refTypeOfRooms__c;
				subIdx.StayPersons__c = leadInfLst[0].StayPersons__c;
				// 元SUBINDEXの部屋数はマナス１に計算する
				idxLsts[0].Rooms__c --;
				update idxLsts[0];
			} else {
				subIdx = idxLsts[0];
			}
		}

		// ------------------------------------------
		// 期間変更対応
		// ------------------------------------------
		// 日帰り場合、泊数０ですが、計算するため、１に自動転換する
		if (orgNights == 0 && newNights >= 1) {
			leads[0].Departure__c = leads[0].Departure__c.addDays(1);
			orgNights = 1;
		}
			
		// -------------------
		// 泊期間延長の場合
		// -------------------
		// 2017/12/18 延泊処理時の見積自動コピー機能対応 WGCH BEGIN
		List<BookingEstimateItem__c> cloneBookEstLst = null;
		Map<String,List<PlanDetail__c>> prodDetailMap = new Map<String,List<PlanDetail__c>>();
		// 2017/12/18 延泊処理時の見積自動コピー機能対応 WGCH END
		if (orgNights < newNights) {
			// 新規の予約データを自動設定、作成を行う
			// コピー元は同じ部屋の最後の予約データの設定情報
			// 最後の最新予約データん全項目を取得して、コピーを行う「全項目設定情報を取得する」
			String locLeadId = leads[leads.size()-1].Id;
			String leadQueryStr = CommSqlUtils.generateQueryString('Lead__c');
			leadQueryStr += ' Where id = :locLeadId ';
			Lead__c cloneLead = Database.query(leadQueryStr);
			// 2016/11/10 時刻再設定を行う BEGIN
			cloneLead.Field4__c = leads[leads.size()-1].Field4__c;
			cloneLead.Field3__c = leads[leads.size()-1].Field3__c;
			// 2016/11/10 時刻再設定を行う END
			// 2014/08/27 単価定義区分機能対応
			cloneLead.UnitPriceDefKb__c = cloneLead.UnitPriceDefKbCal__c;
			// 2017/12/18 延泊処理時の見積自動コピー機能対応 WGCH BEGIN
			if(isCloneBookEstFlg){
				// 取到最后一天的見積明細
				cloneBookEstLst= [select id, name, refBooking__c, ActionType__c,Amount__c,RowNo__c,
							refAccountMaster__c, refAccountMaster__r.Name, TaxRate__c, ServiceRate__c, SpecialTax__c, UnitPrice__c,
							// 2016/12/08 見積明細利用日機能対応 BEGIN zyz
							UseDate__c, refBooking__r.EntryTime__c, refBooking__r.Departure__c
							// 2016/12/08 見積明細利用日機能対応 END zyz
							,GoukeinoneTax__c, SpTotal__c, ProductName__c, PlanDetailSyncInfo__c
							// 2017/12/13 見積明細非表示機能対応 WGCH BEGIN
							,InvoiceNoShowFlg__c, NoShowRequestFlg__c
							// 2017/12/13 見積明細非表示機能対応 WGCH END
							from BookingEstimateItem__c where refBooking__c =: cloneLead.Id and ParentBookingItemRef__c = null and ActionType__c !=: ACTTYPE_PAY and ActionType__c !=: ACTTYPE_AR Order By RowNo__c,Name];
				Set<String> pAccMasterIdSet = new Set<String>();
				for(BookingEstimateItem__c bookEst : cloneBookEstLst){
					// 取 最后一天見積明細里 会计商品为Plan的会计商品Id
					if(bookEst.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) pAccMasterIdSet.add(bookEst.refAccountMaster__c);
				}
				// 取 最后一天見積明細里 会计商品为Plan的会计商品   的plan明细
				for (PlanDetail__c pd : [select AccountMasterRef__c, AccountMasterRef__r.name 
											,AccountMasterRef__r.ActionType__c,PlanProdcut__c, Price__c from PlanDetail__c where PlanProdcut__c in: pAccMasterIdSet]) {
					if (!prodDetailMap.containsKey(pd.PlanProdcut__c)) prodDetailMap.put(pd.PlanProdcut__c,new List<PlanDetail__c>());
					prodDetailMap.get(pd.PlanProdcut__c).add(pd);
				}
			}
			// 2017/12/18 延泊処理時の見積自動コピー機能対応 WGCH END
			// コピー元の予約データを取得、
			for (Integer i = orgNights; i < newNights; i++) {
				// コピー元の予約情報を取得する
				Lead__c lead = cloneLead.clone(false,true);
				// 受付日
				lead.ReservedDate__c = System.now();
				// 受付者
				lead.ReservedContact__c = UserInfo.getName();
				// お客様ステータス
				lead.Field298__c = null;
				// 2013/11/30 部屋変更不可のクリア
				lead.Field276__c = false;
				// 到着日、出発日設定を行う
				lead.EntryTime__c = leads[leads.size()-1].EntryTime__c.addDays(1);
				lead.Departure__c = leads[leads.size()-1].Departure__c.addDays(1);
				// 新規データを追加する
				leads.add(lead);
			}

			// 予約名
			String orgLeadName = cloneLead.Name;
			
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
				// 代表部屋標識+999-999泊目+予約名 && 999-999泊目+予約名
				// 予約名の再設定を行う
				for (Integer i = 0; i < newNights; i++ ) {
					// 予約名を設定する
					if (newNights > 1) {
						//泊目
						String newName = newNights + '-' + (i+1) + Label.CONST_008_0110 +' ';
						leads[i].Name = orgLeadName.replaceFirst(repRegExpKey2, newName);
					} else {
						leads[i].Name = orgLeadName.replaceFirst(repRegExpKey2, '');
					}
				}
			} else if (orgLeadName.startsWith(LEAD_NAME_PREFIX)) {
				// 代表部屋標識+予約名の場合
				for (Integer i = 0; i < newNights; i++ ) {
					// 予約名を設定する
					if (newNights > 1) {
						//泊目
						String newName = LEAD_NAME_PREFIX + newNights + '-' + (i+1) + Label.CONST_008_0110 +' ';
						leads[i].Name = orgLeadName.replaceFirst(LEAD_NAME_PREFIX, newName);
					}
				}
			} else {
				// 予約名の場合
				for (Integer i = 0; i < newNights; i++ ) {
					// 予約名を設定する
					if (newNights > 1) {
						//泊目
						leads[i].Name = newNights + '-' + (i+1) + Label.CONST_008_0110 +' ' + orgLeadName;
					}
				}
			}
		} 
		// -------------------
		// 期間短縮の場合
		// -------------------
		else if (orgNights > newNights) {
			
			// 泊数は０の場合、日帰りデータになりました
			if (newNights == 0) {
				// 日帰りの場合、出発日は当日になる
				leads[0].Departure__c = leads[0].EntryTime__c;
			} 
			
			Integer locNewNights = (newNights == 0 ? 1 : newNights);
//			System.debug('locNewNights-------------' + leads[0].Name);
			for(Integer i = 0 ; i < locNewNights ; i ++){
				if(newNights > 1){
					leads[i].Name = changeLeadName(leads[i].Name,false,newNights,i);
				}else{
					leads[0].Name = changeLeadName(leads[0].Name,true,newNights,0);
				}
//				System.debug('-------------' + leads[i].Name);
			}
			
			// 期間外の予約データは全部キャンセル処理を行う
			for (Integer i = locNewNights; i < orgNights; i++) {
				// 期間対象外の予約データはキャンセル更新
				leads[i].ReservedStatus__c = CommConst.LEAD_ST_CANCEL;
			}
			// 期間短縮後の部屋は「宿泊者名簿」に登録する部屋と照合する
			// 元宿泊期間は１泊以上場合、期間変更に従って、部屋変更すると、宿泊者名簿に反映連動を行う
			if (orgNights > 1 ) {
				Lead__c lead = leads[locNewNights-1];
				List<BookingGuest__c> updGuestList = [select RoomRef__c from BookingGuest__c 
					where IndexSubRef__c = :leadInfLst[0].LeadIndexSubId__c and RoomGroupNo__c = :leadInfLst[0].RoomGroupNo__c
					And RoomRef__c != :leads[locNewNights-1].Rroom__c];
				if (!updGuestList.isEmpty()) {
					for (BookingGuest__c bookGuest : updGuestList) {
						bookGuest.RoomRef__c = lead.Rroom__c;
					}
					update updGuestList;
				}
			}
		}
		
		// 営業処理日
		Date searchDt = getProcessDate(processDate, true);

		// 人数変更場合
		if (leadPeopleNum != orgLeadPeopleNum ) {
			// 処理日を取得して、該当処理日から変更を行う
			
			// 期間外の予約データは全部キャンセル処理を行う
			for (Lead__c lead : leads) {
				if (lead.EntryTime__c.date() < searchDt) continue;
				//for (Integer i = newNights; i < orgNights; i++) {
				lead.StayPersons__c = leadPeopleNum;
			}
			// 人数は再設定を行う
			subIdx.StayPersons__c = leadPeopleNum;
		}
		// SUBINDEXの
		subIdx.EntryDate__c = leads[0].EntryTime__c.Date();
		// 日帰り、N泊処理機能
		subIdx.DepartureDate__c = leads[newNights == 0 ? 0 : newNights-1].Departure__c.Date();
		subIdx.Nights__c = newNights;
		Database.UpsertResult subRs = Database.upsert(subIdx);
		if (subRs.isCreated()) {
			for (Lead__c lead : leads) {
				lead.LeadIndexSubId__c = subRs.getId();
				lead.RoomGroupNo__c = 0;
			}
		}
		// XML___wgch 2016/11/16 特記事項 BEGIN
		if(oldComment3 != newComment3){
			for (Lead__c lead : leads) {
				if(lead.EntryTime__c.date() >= searchDt){
					lead.Comment3__c = newComment3;
				}	
			}
		}
		// XML___wgch 2016/11/16 特記事項 END	
		// 予約情報更新処理を行う
		upsert leads;
		// 2017/12/18 延泊処理時の見積自動コピー機能対応 WGCH BEGIN
		if(isCloneBookEstFlg && orgNights < newNights && cloneBookEstLst != null){
			// 見積明細ID判断
			String BOOKING_SOBJ_KEY = BookingEstimateItem__c.sObjectType.getDescribe().getKeyPrefix();
			List<Lead__c> newLeadLst = new List<Lead__c>();
			// 取得 延长的新预约
			for (Integer i = orgNights; i < leads.size(); i++) {
				newLeadLst.add(leads[i]);
			}
			// 删除自动克隆过来的見積明細
			// 2018/03/07 Security Check BEGIN
			if (!CommSecurityUtils.isDeleteable(BookingEstimateItem__c.getSObjectType())) {
				return;
			}
			// 2018/03/07 Security Check END
			delete [select id from BookingEstimateItem__c where ParentBookingItemRef__c != null And refBooking__c in: newLeadLst];
			delete [select id from BookingEstimateItem__c where ParentBookingItemRef__c = null And refBooking__c in: newLeadLst];
			List<BookingEstimateItem__c> newBookEstLst = new List<BookingEstimateItem__c>();
			// 克隆新的見積明細
			for(Lead__c ld : newLeadLst){
				for(BookingEstimateItem__c bookEst : cloneBookEstLst){
					BookingEstimateItem__c newBookEst = bookEst.clone(false,true);
					// 克隆新的Plan見積明細
					if (prodDetailMap.containsKey(newBookEst.refAccountMaster__c) && newBookEst.PlanDetailSyncInfo__c != null) {
						List<PlanDetail__c> detailLst = prodDetailMap.get(newBookEst.refAccountMaster__c);
						String[] prods = newBookEst.PlanDetailSyncInfo__c.split(';');
						String syncPlan = '';
						// 重置新的Sync字段
						for (integer m = 0 ; m < prods.size() ; m++) {
							String message = prods[m];
							if (CommUtils.isBlank(message)) continue;
							String firstId = message.subStringBefore(':');
							// 見積明細ID判断
							if (!firstId.startsWith(BOOKING_SOBJ_KEY)) {
								syncPlan += message + ';';
								continue;
							}
							String lastMsg = message.subStringAfter(':');
							syncPlan += detailLst[m].id + ':' + lastMsg + ';';
						}
						// 新的Sync
						newBookEst.PlanDetailSyncInfo__c = syncPlan;
					}
					newBookEst.refBooking__c = ld.Id;
					newBookEst.UseDate__c = ld.EntryTime__c != null ? ld.EntryTime__c.Date() : null;
					newBookEstLst.add(newBookEst);
				}
			}
			// 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
	        newBookEstLst.addAll(CommLogicProcess.getBathTaxBookEstLst(newLeadLst, newBookEstLst));
			// 2020/07/30 入湯税の自動入力機能について改善 WGCH END
			if(!newBookEstLst.isEmpty()) upsert newBookEstLst;
		}
		// 2017/12/18 延泊処理時の見積自動コピー機能対応 WGCH END
		if (subRs.isCreated()) {
			// 関連新規作成したSUBINDEXの部屋は宿泊者名簿にコピーする
			List<Lead__c> existList = getOrgMoveLeadInfo(leads[leads.size()-1].Id, searchDt);
			createBookingGuest(existList[existList.size()-1]);
		}
} catch(Exception e) {
	// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 BEGIN
	String errMsg = e.getMessage();
	if(!CommUtils.isFieldValidationMessage(errMsg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
	// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 END
	DataBase.rollback(sp);
	bookingCreateOK = false;
	return;
}
		// 最新情報を取得して、画面に表示する
bookingCreateOK = true;
	}
	/**
	* カスタム設定のお客様の項目の入力更新する
	* 2016/11/25 by zy
	**/
	private void upsertCustomContact(){
		Contact updContact = new Contact(id = newContact.id);
		for(String fieldName : contactFields.split(',')) {
			if (!CommUtils.isBlank(fieldName))
				updContact.put(fieldName,newContact.get(fieldName));
		}
		// 2018/03/07 Security Check BEGIN
		if (CommSecurityUtils.isCanUpdateable(Contact.getSObjectType())) {
		// 2018/03/07 Security Check END
			update updContact;
		// 2018/03/07 Security Check BEGIN
		}
		// 2018/03/07 Security Check END
		hadUpdContactFlag = false;
	}
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
				
				if (isFirst) {
					newLeadName = orgLeadName.replaceFirst(repRegExpKey2, '');
					//System.debug('newLeadName1------' + newLeadName);
				}else{
					//泊目
					String newName = newNights + '-' + (leadIndex+1) + Label.CONST_008_0110 +' ';
					newLeadName = orgLeadName.replaceFirst(repRegExpKey2, newName);
					//System.debug('newLeadName2------' + newLeadName);
				}
			}else if (orgLeadName.startsWith(LEAD_NAME_PREFIX)) {
				// 予約名を設定する
				if (newNights > 1) {
					//泊目
					String newName = LEAD_NAME_PREFIX + newNights + '-' + (leadIndex+1) + Label.CONST_008_0110 + ' ';
					newLeadName = orgLeadName.replaceFirst(LEAD_NAME_PREFIX, newName);
					//System.debug('newLeadName3------' + newLeadName);
				}else{
					newLeadName = orgLeadName;
				}
			}else{
				newLeadName = orgLeadName;
			}
			return newLeadName;
	}
	// ******************************
	// 宿泊者名簿情報を作成する
	// ******************************
	private static void createBookingGuest(Lead__c lead) {
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'contactref__c','roomref__c','roomgroupno__c','indexsubref__c','guestname__c','name','delegateflg__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.BookingGuest__c.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(chkFieldsLst, mm)) {
			return ;
		}
		// 2019/09/15 Security Check BY zyz END
		List<LeadIndex__c> existSubIdx = [select id from LeadIndex__c where id = :lead.LeadIndexSubId__c];
		if (existSubIdx.isEmpty()) return;
		List<BookingGuest__c> insBookingGuestLst = new List<BookingGuest__c>();
		for (Integer j = 0 ; j<lead.StayPersons__c;j++) {
			BookingGuest__c item = new BookingGuest__c();
	        if ( j == 0) item.DelegateFlg__c = true;
	        item.Name = lead.Relcontact__r.Name;
	        item.GuestName__c = lead.Relcontact__r.Name1__c;
	        //item.roomType = lead.refTypeOfRooms__r.Name;
	        //item.roomTypeId = lead.refTypeOfRooms__c;
	        item.IndexSubRef__c = lead.LeadIndexSubId__c;
	        item.RoomGroupNo__c = lead.RoomGroupNo__c;
	        item.RoomRef__c = lead.Rroom__c;
	      	item.ContactRef__c = lead.Relcontact__c;
	      	
	        insBookingGuestLst.add(item);
		}
		if (!insBookingGuestLst.isEmpty()) insert insBookingGuestLst;	
	}
	// 予約キャンセル機能対応 BEGIN  
    public void leadCancel() {
    	bookingCreateOK = false;
    	if(strLeadId != ''){
    		Set<String> leadIds = new Set<String>();
	        // 団体一括チェックインを設定される場合
	        if(isGroupFlg){ 
	        	for(String leadId : groupLeadIds.split(',')){
	        		leadIds.add(leadId);
	        	}
	        } else{
	        	leadIds.add(strLeadId);
	        }
	        //List<Id> recTypeLst = getLeadBookingRecTypeLst();
	        // 昼12時過ぎすると、到着日は当日のデータを表示する、12時前の場合、到着日は前日のデータを表示する
	        Date searchDt = getProcessDate(processDate, true);
	        // 指定の予約IDにより、キャンセル日から以後の予約情報を全部キャンセルを行う
	        List<Lead__c> cancelOrgLeads = [select Id, LeadIndexRef__c,LeadIndexSubId__c,ReservedStatus__c,RoomGroupNo__c from Lead__c where Id = :leadIds];
	        // 関連の予約情報を取得機能
	        set<id> leadIndexIdSet = new set<id>();
	        set<id> leadIndexSubIdSet = new set<id>();
	        set<decimal> groupNoSet = new set<decimal>();
	       	for (Lead__c lead : cancelOrgLeads) {
	       		leadIndexIdSet.add(lead.LeadIndexRef__c);
	       		leadIndexSubIdSet.add(lead.LeadIndexSubId__c);
	       		groupNoSet.add(lead.RoomGroupNo__c);
	       	}									
	       	List<Lead__c> cancelLeads = [select id,ReservedStatus__c,LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c from lead__c 
								where LeadIndexRef__c in :leadIndexIdSet And LeadIndexSubId__c in :leadIndexSubIdSet And RoomGroupNo__c in :groupNoSet
								And DAY_ONLY(convertTimezone(EntryTime__c)) >= :searchDt
								// 有効な予約のみ関連更新を行う
								And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG for update];
			// map<leadindex_leadinexsub_groupno, list<lead__c>>
			map<String, list<Lead__c>> leadsInfoMap = new map<string, list<lead__c>>();
			map<Id, String> leadIdTokeyMap = new map<Id, String>();
			for (Lead__c lead : cancelLeads) {
				String key = getKeyOfSameGroupLead(lead);
				leadIdTokeyMap.put(lead.Id, key);
				if (!leadsInfoMap.containskey(key)) leadsInfoMap.put(key, new list<Lead__c>());
				leadsInfoMap.get(key).add(lead);
			}
			Set<Lead__c> cancelUpdLeads = new Set<Lead__c>();
			for (Lead__c lead : cancelOrgLeads) {
				if (!leadIdTokeyMap.containsKey(lead.Id)) continue;
				String key = leadIdTokeyMap.get(lead.id);
				if (leadsInfoMap.containsKey(key)) {
					cancelUpdLeads.addAll(leadsInfoMap.get(key));
				}
			}
        	for(Lead__c lead : cancelUpdLeads){
        		lead.ReservedStatus__c = CommConst.LEAD_ST_CANCEL;
        	}
			try{
				if (!cancelUpdLeads.isEmpty()) update new List<Lead__c>(cancelUpdLeads);
			}catch(Exception e){
				String errMsg = e.getMessage();
				if(!CommUtils.isFieldValidationMessage(errMsg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
				return;
			}
    	}else{
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'the leadId is null'));
			return;
    	}
        bookingCreateOK = true;
    }
    private String getKeyOfSameGroupLead(Lead__c lead) {
		return 	  CommUtils.nullToBlank(Lead.LeadIndexRef__c) 
				+ '_' 
				+ CommUtils.nullToBlank(lead.LeadIndexSubId__c) 
				+ '_' 
				+ CommUtils.nullToBlank(lead.RoomGroupNo__c);
	}
    // 処理日
	public Date processDate{get;set;}
    // 画面の部屋にて、該当予約情報をチェックインする
    public void checkInByRoom() {
    	if(strLeadId != ''){
    		Set<String> leadIds = new Set<String>();
	        // 団体一括チェックインを設定される場合
	        if(isGroupFlg)
	        { 
	        	for(String leadId : groupLeadIds.split(','))
	        	{
	        		leadIds.add(leadId);
	        	}
	        }else
	        {
	        	leadIds.add(strLeadId);
	        }
	        List<Id> recTypeLst = getLeadBookingRecTypeLst();
//system.debug(logginglevel.info,'processDate:::' + processDate);
	        // 昼12時過ぎすると、到着日は当日のデータを表示する、12時前の場合、到着日は前日のデータを表示する
	        Date searchDt = getProcessDate(processDate, true);
//system.debug(logginglevel.info,'searchDt:::' + searchDt);
//system.debug(logginglevel.info,'leadIds:::' + leadIds);
			// 選択した予約データ
			// 2018/03/07 Security Check BEGIN
			List<String> chkFieldsLst = new List<String>{'field298__c'};
			Map<String,Schema.SObjectField> mm = Schema.SObjectType.Lead__c.fields.getMap();
			if (!CommSecurityUtils.isCanUpdateable(chkFieldsLst, mm)) {
				return ;
			}
			// 2018/03/07 Security Check END
			List<Lead__c> checkInLead = [select Id, Field298__c, LeadIndexRef__c from Lead__c
				where Id = :leadIds And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
				And DAY_ONLY(convertTimezone(EntryTime__c)) = :searchDt
				And RecordTypeId in :recTypeLst
				And Field298__c = null for update];
			if(checkInLead.size() > 0){
					 if(isGroupFlg)
			        { 
			        	for(Lead__c lead : checkInLead)
			        	{
			        		lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
			        	}
			        }else
			        {
			        	checkInLead[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
			        }
				try{
//system.debug(logginglevel.info,'checkInLead::::' + checkInLead);
					update checkInLead;
				}catch(Exception e){
					// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 BEGIN
					String errMsg = e.getMessage();
					if(!CommUtils.isFieldValidationMessage(errMsg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
					bookingCreateOK = false;
					// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 END
					return;
				}

			}else{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'the lead Detail is not able to checkin'));
				return;
			}
    	}else{
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'the leadId is null'));
			return;
    	}
        bookingCreateOK = true;
    }
    // 画面の部屋にて、該当予約情報をチェックアウトする
    public void checkOutByRoom() {
    	if(strLeadId != ''){
    		// 宿泊のレコードタイプ
			//Id bookRecTypeId = CommLogicProcess.getLeadBookingRecType();
	        //Id baseRecTypeId = CommLogicProcess.getLeadBaseRecType();
	        //List<Id> recTypeLst = new List<Id>{bookRecTypeId, baseRecTypeId};
			List<Id> recTypeLst = getLeadBookingRecTypeLst();
	        // 昼12時過ぎすると、到着日は当日のデータを表示する、12時前の場合、到着日は前日のデータを表示する
	        Date searchDt = getProcessDate(processDate, true);
			// 一括チェックアウト処理を追加
			Set<String> leadIds = new Set<String>();
			// 2019/07/15 多泊の場合、外出の場合、多泊の予約に同じ状態を更新する BY zyz BEGIN
			// leadIds.add(strLeadId);
			// 団体一括チェックインを設定される場合
			if(isGroupFlg){ 
				for(String leadId : groupLeadIds.split(',')){
					leadIds.add(leadId);
				}
			}else{
				leadIds.add(strLeadId);
			}
			// 2019/07/15 多泊の場合、外出の場合、多泊の予約に同じ状態を更新する BY zyz END
			// 一括処理の場合
			if(isGroupFlg) {
				groupLeadIds = groupLeadIds.removeEnd(',');
				leadIds.addAll(groupLeadIds.split(','));
	        }
			List<Lead__c> checkInLead = [select Id, Field298__c,Rroom__c,checkoutdate__c from Lead__c
				//where Id = :strLeadId And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
				where Id = :leadIds And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
				And DAY_ONLY(convertTimezone(EntryTime__c)) = :searchDt
				And RecordTypeId in :recTypeLst
				And Rroom__c != null
				And Field298__c != null And Field298__c != :CommConst.LEAD_GUEST_ST_CO for update];
			if(checkInLead.size() > 0){
				for (Lead__c lead : checkInLead) {
					//checkInLead[0].Field298__c = CommConst.LEAD_GUEST_ST_CO;
					lead.Field298__c = CommConst.LEAD_GUEST_ST_CO;
				}
				Savepoint sp = Database.setSavepoint();
				try{
					update checkInLead;
					// 該当部屋の清掃データを作成する[画面に指定日にて、清掃管理データを作成する]
					// 2013/08/14 ADD
					// 2013/11/06 日付調整により、清掃データの日付修正する
					(new RoomStatusManager()).createNoCleanRooms(processDate, checkInLead);
				}catch(Exception e){
					// 登録ROLLBACK
					DataBase.rollback(sp);
					// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 BEGIN
					String errMsg = e.getMessage();
					if(!CommUtils.isFieldValidationMessage(errMsg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
					bookingCreateOK = false;
					// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 END
					return;
				}

			}else{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'the lead Detail is not able to checkout'));
				return;
			}
    	}else{
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'the leadId is null'));
			return;
    	}
		bookingCreateOK = true;
    }
	// 2019/02/28 滞在・外出状態の管理 WGCH BEGIN
	// 画面の部屋にて、該当予約情報を外出する
	public void outByRoom() {
		if(strLeadId != ''){
			List<Id> recTypeLst = getLeadBookingRecTypeLst();
			// 昼12時過ぎすると、到着日は当日のデータを表示する、12時前の場合、到着日は前日のデータを表示する
			Date searchDt = getProcessDate(processDate, true);
			// 一括チェックアウト処理を追加
			Set<String> leadIds = new Set<String>();
			leadIds.add(strLeadId);
			// 一括処理の場合
			if(isGroupFlg) {
				groupLeadIds = groupLeadIds.removeEnd(',');
				leadIds.addAll(groupLeadIds.split(','));
			}
			List<Lead__c> checkInLead = [select Id, Field298__c,Rroom__c,checkoutdate__c from Lead__c
				where Id = :leadIds And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
				And DAY_ONLY(convertTimezone(EntryTime__c)) = :searchDt
				And RecordTypeId in :recTypeLst
				And Rroom__c != null
				And Field298__c != null And Field298__c != :CommConst.LEAD_GUEST_ST_CO And Field298__c != :CommConst.LEAD_GUEST_ST_OUT for update];
			if(checkInLead.size() > 0){
				for (Lead__c lead : checkInLead) {
					lead.Field298__c = CommConst.LEAD_GUEST_ST_OUT;
				}
				Savepoint sp = Database.setSavepoint();
				try{
					update checkInLead;
				}catch(Exception e){
					// 登録ROLLBACK
					DataBase.rollback(sp);
					// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 BEGIN
					String errMsg = e.getMessage();
					if(!CommUtils.isFieldValidationMessage(errMsg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
					bookingCreateOK = false;
					// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 END
					return;
				}

			}else{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'the lead Detail is not able to out'));
				return;
			}
		}else{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'the leadId is null'));
			return;
		}
		bookingCreateOK = true;
	}
	// 画面の部屋にて、該当予約情報を戻るする
	public void returnByRoom() {
				if(strLeadId != ''){
			List<Id> recTypeLst = getLeadBookingRecTypeLst();
			// 昼12時過ぎすると、到着日は当日のデータを表示する、12時前の場合、到着日は前日のデータを表示する
			Date searchDt = getProcessDate(processDate, true);
			// 一括チェックアウト処理を追加
			Set<String> leadIds = new Set<String>();
			// 2019/07/15 多泊の場合、外出の場合、多泊の予約に同じ状態を更新する BY zyz BEGIN
			// leadIds.add(strLeadId);
			// 団体一括チェックインを設定される場合
			if(isGroupFlg){ 
				for(String leadId : groupLeadIds.split(',')){
					leadIds.add(leadId);
				}
			}else{
				leadIds.add(strLeadId);
			}
			// 2019/07/15 多泊の場合、外出の場合、多泊の予約に同じ状態を更新する BY zyz END
			// 一括処理の場合
			if(isGroupFlg) {
				groupLeadIds = groupLeadIds.removeEnd(',');
				leadIds.addAll(groupLeadIds.split(','));
			}
			List<Lead__c> checkInLead = [select Id, Field298__c,Rroom__c,checkoutdate__c from Lead__c
				where Id = :leadIds And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
				And DAY_ONLY(convertTimezone(EntryTime__c)) = :searchDt
				And RecordTypeId in :recTypeLst
				And Rroom__c != null
				And Field298__c != null And Field298__c != :CommConst.LEAD_GUEST_ST_CO And Field298__c != :CommConst.LEAD_GUEST_ST_CI for update];
			if(checkInLead.size() > 0){
				for (Lead__c lead : checkInLead) {
					lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
				}
				Savepoint sp = Database.setSavepoint();
				try{
					update checkInLead;
				}catch(Exception e){
					// 登録ROLLBACK
					DataBase.rollback(sp);
					// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 BEGIN
					String errMsg = e.getMessage();
					if(!CommUtils.isFieldValidationMessage(errMsg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
					bookingCreateOK = false;
					// 2015/10/28 項目有効チェックエラーは画面に再設定しない制御追加 END
					return;
				}

			}else{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'the lead Detail is not able to checkin'));
				return;
			}
		}else{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'the leadId is null'));
			return;
		}
		bookingCreateOK = true;
	}
	// 2019/02/28 滞在・外出状態の管理 WGCH END
    // 宿泊の対象データ表示機能
    public static List<Id> getLeadBookingRecTypeLst () {
		Id bookRecTypeId = CommLogicProcess.getLeadBookingRecType();
	    Id baseRecTypeId = CommLogicProcess.getLeadBaseRecType();
	    List<Id> recTypeLst = new List<Id>{bookRecTypeId, baseRecTypeId};
	    return recTypeLst;
    }
    /* 処理日 */
    public static Date getProcessDate (Date procDate, boolean pIsCheckInLayout) {
    	// 選択の日付は当日分の場合、切替時間により、表示を行う
    	// 選択の日付は翌日からの未来日の場合、選択日の日付はデータ抽出日付で判定する
    	/* 2013/08/23 変更戻すVer3.72->V3.69 */
    	if (procDate != Date.today()) return procDate;
    	// 当日のチェックインの情報を切り替えする場合、選択の日付で抽出条件日付でデータを表示する
    	else if (pIsCheckInLayout) return procDate;
    	//else return (System.now().format('HH:mm') < equalTime.format('HH:mm') ? procDate.addDays(-1) : procDate);
    	else return procDate.addDays(-1);
    	//return (System.now().format('HH:mm') < equalTime.format('HH:mm') ? procDate.addDays(-1) : procDate);
    }
     private void setMulitiCheckoutLabelFun() {
		Schema.DescribeFieldResult fieldResult = Lead__c.Field298__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
	   	for( Schema.PicklistEntry f : ple) {
	   		// 2019/02/28 滞在・外出状態の管理 WGCH BEGIN
	   		/*
	   		if (f.getValue() == CommConst.LEAD_GUEST_ST_CO) {
	   			mulitiCheckoutLabel = f.getLabel();
	   			break;
	   		}
	   		*/
	   		if (f.getValue() == CommConst.LEAD_GUEST_ST_CO) {
	   			mulitiCheckoutLabel = f.getLabel();
	   		} else if (f.getValue() == CommConst.LEAD_GUEST_ST_OUT) {
	   			mulitiOutLabel = f.getLabel();
	   		} else if (f.getValue() == CommConst.LEAD_GUEST_ST_CI) {
	   			mulitiCheckinLabel = f.getLabel();
	   		}
	   		// 2019/02/28 滞在・外出状態の管理 WGCH END
	   	}
    }
    
    private void refeshDomNode(){
    	leadFields = '';
	    // 列数定義タグ存在チェック[2016/07/06]
	    contactFields = '';
	    leadFieldsAllStr = '';
		widthPx = 550;
		heightPx = '400px';
		hadUpdContactFlag = false;
	    pageLst = new List<PageCustomeFieldHelper.SectionInfo>();
	    // 2017/08/17 ルームインジケータ画面に、縦セルに表示項目をカスタマイズできるように改善対応 WGCH BEGIN
	    roomExtLeadFieldApiLst = new List<String>();
	    // 2017/08/17 ルームインジケータ画面に、縦セルに表示項目をカスタマイズできるように改善対応 WGCH END
	    // 2016/08/01 店舗設定情報を取得する
		// 2020/02/28 ルームインジケータ、タイムテーブル改修対象画面 BY zyz BEGIN
		confirmChgFlg = false;
		// 2020/02/28 ルームインジケータ、タイムテーブル改修対象画面 BY zyz END
	    // 拡張予約項目を定義する
	    String xmlName = 'RoomIndicatorInfoLeadOutputExtendFieldsXml';
	    try{
		    Dom.XMLNode targetNode = CommXmlUtils.parseXmlDoc(xmlName,branchShopNm);
		    Dom.XmlNode disPlay =  targetNode.getChildElement('DISPLAY', null);
		    if(disPlay != null){
			    Dom.XmlNode width =  disPlay.getChildElement('WINDOWWIDTH', null);
				if (width != null) {
					String widthText = CommUtils.nullToBlank(width.getText()).deleteWhitespace();
					if (!CommUtils.isBlank(widthText) && Pattern.matches('[0-9]*', widthText))
					widthPx = CommUtils.nullToZero(widthText);
				}
				Dom.XmlNode height =  disPlay.getChildElement('WINDOWHEIGHT', null);
				if (height != null) {
					String heightText = CommUtils.nullToBlank(height.getText()).deleteWhitespace();
					if (!CommUtils.isBlank(heightText) && Pattern.matches('[0-9]*', heightText))
					heightPx = CommUtils.nullToIntZero(heightText) + 'px';
				}  
		    }
		    // 店舗情報はＸＭＬから取得する
		    Dom.XmlNode shopFields =  targetNode.getChildElement('FIELDS', null);
		    String strFields = (shopFields == null ? '' : CommUtils.nullToBlank(shopFields.getText()).deleteWhitespace());
		    Set<String> nowFieldSet = new Set<String>(queryDefFieldSet);
		    List<String> oneSectionPageStringLst = new List<String>();
		    //其他layout对应
		    for ( Dom.XmlNode c : shopFields.getChildElements()) {
		        if(c.getName() == 'SECTION'){
		            PageCustomeFieldHelper.SectionInfo p = new PageCustomeFieldHelper.SectionInfo();
		            p.title = c.getAttribute('TITLE',null);
		            p.columnsInt = CommUtils.nullToIntZero( c.getAttribute('COLNUM',null));
		            String childFields = CommUtils.nullToBlank(c.getText()).deleteWhitespace();
		            List<String> splitFields = childFields.split(',');
		            oneSectionPageStringLst = new List<String>();
		            for (String fieldName : splitFields) {
		            	// 去重
		                if (fieldName == blankString || !nowFieldSet.contains(fieldName)){  
		                    nowFieldSet.add(fieldName);
		                    oneSectionPageStringLst.add(fieldName);
		                }
		            }
		            p.add(oneSectionPageStringLst);
		            pageLst.add(p);
		        }
		    }
		    // 2017/08/17 ルームインジケータ画面に、縦セルに表示項目をカスタマイズできるように改善対応 WGCH BEGIN
		    Dom.XmlNode shopRoomInfExtFields =  targetNode.getChildElement('ROOMINFOEXT', null);
		    String roomExtFieldsStr = (shopRoomInfExtFields == null ? '' : CommUtils.nullToBlank(shopRoomInfExtFields.getText()).deleteWhitespace());
//System.debug(loggingLevel.info, 'roomExtFieldsStr===' + roomExtFieldsStr);
		    if(!CommUtils.isBlank(roomExtFieldsStr)) {
		    	List<String> roomExtFieldsLst = roomExtFieldsStr.split(',');
		    	for(String api : roomExtFieldsLst) { if(!CommUtils.isBlank(api)) roomExtLeadFieldApiLst.add( CommUtils.nullToBlank(api)); }
		    }
//System.debug(loggingLevel.info, 'roomExtLeadFieldApiLst===' + roomExtLeadFieldApiLst);
		    // 2017/08/17 ルームインジケータ画面に、縦セルに表示項目をカスタマイズできるように改善対応 WGCH END
			// 2020/02/28 ルームインジケータ、タイムテーブル改修対象画面 BY zyz BEGIN
			Dom.XmlNode confirmNode =  targetNode.getChildElement('CONFIRMCHANGE', null);
		    if(confirmNode != null ) 
				confirmChgFlg = boolean.valueOf(CommUtils.nullToBlank(confirmNode.getText()));
			// 2020/02/28 ルームインジケータ、タイムテーブル改修対象画面 BY zyz END
	    }catch (Exception e){}
	    if(pageLst.isEmpty()){
	    	PageCustomeFieldHelper.SectionInfo defaultPg = new PageCustomeFieldHelper.SectionInfo();
	    	defaultPg.columnsInt = 1;
	    	pageLst.add(defaultPg);
		}
		String mapFields = '';
		String refPrix = '__r.';
		String refNamePrix = '__r';
		String commPrix = '__c';
		Map<String,Map<String, Schema.DescribeFieldResult>> sobjectMap = new Map<String,Map<String, Schema.DescribeFieldResult>>();
		Map<String, Schema.DescribeFieldResult> modelDeafaultValuesMaps = CommSqlUtils.getAllFieldLst(Lead__c.sObjectType,false,true);
		// セクション LOOP
		for (PageCustomeFieldHelper.SectionInfo sec : pageLst) {
			//　項目LOOP
			for (String fieldName : sec.fieldLst) {
				PageCustomeFieldHelper.CusField cus = null;
				String customField = fieldName.toLowerCase();
				if (fieldName == blankString) {
					cus = new PageCustomeFieldHelper.CusField();
					cus.fieldType = 'blank';
				// 予約項目の設定	
				} else if (!leadQuerySet.contains(fieldName) && modelDeafaultValuesMaps.containsKey(customField)) {
					Schema.DescribeFieldResult dr = modelDeafaultValuesMaps.get(customField);
					cus = new PageCustomeFieldHelper.CusField( dr,false,null,null,'Lead__c');
					cus.fieldType = 'Lead__c';
					leadFields += cus.localName + ',';
					leadFieldsAllStr += cus.name + ',';
				} else if (customField.contains(refPrix)) {
					// 参照名取得する
					String refName = customField.substringBefore('.');
					String curFieldName = refName.replace(refNamePrix,commPrix);
					// 参照オブジェクト下項目名
					String refFieldName = customField.substringAfter(refPrix);
					// 参照項目ありの場合
					// 参照オブジェクト設定取得する
					if (modelDeafaultValuesMaps.containsKey(curFieldName)) {
						Schema.DescribeFieldResult dr = modelDeafaultValuesMaps.get(curFieldName);
						Schema.sObjectType refType = dr.getReferenceTo()[0];
						String typeName = refType.getDescribe().getLabel();
						if (refType.getDescribe().getName() != 'Contact') continue;
						if (!sobjectMap.containsKey(typeName)) sobjectMap.put(typeName,CommSqlUtils.getAllFieldLst(refType,false,true));
						Map<String, Schema.DescribeFieldResult> curValuesMap = sobjectMap.get(typeName);
						if (curValuesMap.containsKey(refFieldName)) {
							Schema.DescribeFieldResult refDr = curValuesMap.get(refFieldName);
							cus = new PageCustomeFieldHelper.CusField( refDr,false,null,null, refType.getDescribe().getName());
							cus.isRefFlag = true;
							cus.fieldType = refType.getDescribe().getName();
							contactFields += cus.localName + ',';
							leadFields += customField + ',';
						}
					}
				}
		    	// 参照項目追加する
		    	if (cus != null) sec.cusFields.add(cus);
			}
		}
	}
	public String leadFields{get;set;}
	public String getDateTimeFormatStr() {
        return CommBaseCtrl.getDateTimeFormat();
    }
    public String getDateFormatStr() {
        return CommBaseCtrl.getDateFormat();
    }	
	//全部予約字段名
    public String leadFieldsAllStr{get;set;}
	// 会計書の領収書欄を表示する・しない選択できる制御フラグ
	public static Boolean isAccountIdFlg{get{
		return CommDefine__c.getOrgDefaults().AccountRecipteIsShow__c == null ? false : CommDefine__c.getOrgDefaults().AccountRecipteIsShow__c;
	}}
	/**
	* 割り当て予約関連の予約データを取得する
	* 	①部屋未割り当てる予約取得する
	*	②部屋割り当てする場合、アサインする予定の期間に、予約データ存在チェック用予約取得する
	*   ③部屋割り当てする場合、該当移動する予約に関連の予約一覧を取得する
	**/
	private static List<Lead__c> getOrgMoveLeadInfo(String leadId, Date searchDt) {
		// 遷移元の予約関連情報取得
		Lead__c keyLead = [select Rroom__c, refTypeOfRooms__c, LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c from lead__c where id = :leadId];
		// 部屋アサイン対象期間予約リストを取得する
		List<Lead__c> updList = [select Rroom__c,refTypeOfRooms__c,refTypeOfRooms__r.Name,Rroom__r.Name,
										StayPersons__c, Relcontact__r.Name, Relcontact__r.Name1__c,Field276__c,
                                        EntryTime__c, Field4__c, Field3__c,
                                        Field298__c,LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c
                                        // 2016/02/17 ルームインジケータは部屋SWAPする場合、2wayの在庫調整を発行しない機能対応を行う BEGIN
                                        , StockAdjustTargetFlg__c
                                        // 2016/02/17 ルームインジケータは部屋SWAPする場合、2wayの在庫調整を発行しない機能対応を行う END
									from Lead__c 
									where LeadIndexSubId__c = :keyLead.LeadIndexSubId__c 
									And LeadIndexRef__c = :keyLead.LeadIndexRef__c
									And RoomGroupNo__c = :keyLead.RoomGroupNo__c
									//And Rroom__c = null
									And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 		// 有効な予約データ
									And DAY_ONLY(convertTimezone(EntryTime__c)) >= :searchDt Order By EntryTime__c asc ];
		return updList;
	}
	// 日付格式
    private static final String g_DateFormat = CommBaseCtrl.getDateFormat();
	private static final String QueryRoomInfoFields = 'Id,Name,Field298__c,EntryTime__c,Rroom__r.Name, Relcontact__r.Id, Relcontact__r.Name, Field310__r.Name, LeadIndexRef__r.Name,Field276__c,LeadIndexSubId__c,RoomGroupNo__c,LeadIndexRef__c,StayPersons__c,Field2__c,Comment3__c'.toLowerCase();
	@remoteaction
    global static PopupWinInfo getRoomInfoExt(String roomId, String leadId, String jsonField,String contactFields) {
    	if(String.escapeSingleQuotes(roomId) != '' && String.escapeSingleQuotes(leadId) != ''){
    		// 2014/11/27 指定オブジェクトの項目情報は
    		//2016/11/29 tolabel error fix by zy BEGIN
			map<String, Schema.DescribeFieldResult> modelDeafaultValuesMap = CommSqlUtils.getAllFieldLst(Lead__c.sObjectType,true,true);
			//2016/11/29 tolabel error fix by zy END
    	    set<string> filterFieldsSet = new set<string>(QueryRoomInfoFields.deleteWhitespace().split(','));
	    	filterFieldsSet.addAll(CommUtils.nulltoBlank(jsonField).toLowerCase().deleteWhitespace().split(','));
	    	String leadQueryFields = '';
	    	for (String key : filterFieldsSet) {
	    		if (CommUtils.isBlank(key)) continue;
	    		//2016/11/29 tolabel error fix by zy BEGIN
	    		if (modelDeafaultValuesMap.containsKey(key)){

	    			Schema.DescribeFieldResult dr = modelDeafaultValuesMap.get(key);
		    		if (dr.getType() == DisplayType.Picklist || dr.getType() == DisplayType.MultiPicklist){
		    			key = 'toLabel(' + dr.getName() + ')';

		    		}
	    		}
	    		//2016/11/29 tolabel error fix by zy END
	    		leadQueryFields += key + ',';
	    	}
	    	// 2019/12/30 名前か電話番号のどちらかだけ一致するお客様がすでに存在する BY zyz BEGIN
	    	// 顾客名字段/电话字段检索追加
	    	if (!leadQueryFields.toLowerCase().contains('relcontact__r.name')) leadQueryFields += 'Relcontact__r.Name,';
	    	if (!leadQueryFields.toLowerCase().contains('relcontact__r.phone')) leadQueryFields += 'Relcontact__r.Phone,';
	    	if (!leadQueryFields.toLowerCase().contains('rroom__r.shopinforef__r.shopcode__c')) leadQueryFields += 'Rroom__r.ShopInfoRef__r.ShopCode__c,';
	    	if (!leadQueryFields.toLowerCase().contains('reftypeofrooms__r.shopinforef__r.shopcode__c')) leadQueryFields += 'refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c,';	
	    	// 2019/12/30 名前か電話番号のどちらかだけ一致するお客様がすでに存在する BY zyz END
	    	leadQueryFields = leadQueryFields.removeEnd(',');
			String leadQueryStr = 'Select ' + leadQueryFields +' From Lead__c ';

			leadQueryStr += ' Where id = :leadId ';
			List<Lead__c> leadLst = Database.query(leadQueryStr);
			if (leadLst.isEmpty()) return null;
    	    Lead__c leadDetail = leadLst[0];					
    	    // 連泊情報を取得する
			List<Lead__c> leads = [ select id, EntryTime__c,Departure__c,Field4__c,Field3__c,Field298__c,Relcontact__c
		// XML___wgch 2016/11/16 END									
									from Lead__c 
									where LeadIndexRef__c = :leadDetail.LeadIndexRef__c 
									And LeadIndexSubId__c = :leadDetail.LeadIndexSubId__c
									And RoomGroupNo__c = :leadDetail.RoomGroupNo__c
									And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 
									Order By EntryTime__c] ;
	    	// 会計情報を取得する
	    	List<AccountAcount__c> acountAcountLst = [select id,Field53__c,AccountName__c,ContactName__c,AccountReceiptName__c,BillingCal__c,AccountProviso__c from AccountAcount__c where Relreserve__c = :leadId order by LastModifiedDate desc limit 1];
			// 2017/05/12 部屋詳細情報画面レジカード機能対応 zyz BEGIN
			List<Yadochou__c> yadoQueryStr=[select Id,Field1__c from Yadochou__c where Field1__r.id = :leadId ];
			// 2017/05/12 部屋詳細情報画面レジカード機能対応 zyz END
			// 予約データのSubIndex設定データが存在する場合、該当データの情報を取得する
			PopupWinInfo roomInfoDetail = new PopupWinInfo();
			// 2017/05/12 部屋詳細情報画面レジカード機能対応 zyz BEGIN
			if(!yadoQueryStr.isEmpty()){
				roomInfoDetail.yadoId = yadoQueryStr[0].Id;
			}
			// 2017/05/12 部屋詳細情報画面レジカード機能対応 zyz END
			// 予約番号
			roomInfoDetail.leadIndexNo = leadDetail.LeadIndexRef__r.Name;
			roomInfoDetail.leadIndexId = leadDetail.LeadIndexRef__c;
			// 予約名
			roomInfoDetail.leadId = leadDetail.Id;
			roomInfoDetail.leadName = leadDetail.Name;
			// お客様
			roomInfoDetail.customId = leadDetail.Relcontact__c;
			if (leadDetail.Relcontact__c != null) roomInfoDetail.customName = leadDetail.Relcontact__r.Name;
			// 2019/12/30 名前か電話番号のどちらかだけ一致するお客様がすでに存在する BY zyz BEGIN
			// 当前笔数据的店铺code获取
			String present_shopcode = CommUtils.isBlank(leadDetail.rroom__r.shopinforef__r.shopcode__c) ? CommUtils.nullToBlank(leadDetail.reftypeofrooms__r.shopinforef__r.shopcode__c) : CommUtils.nullToBlank(leadDetail.rroom__r.shopinforef__r.shopcode__c);
			// 获取重复的数据
			if (leadDetail.Relcontact__c != null) roomInfoDetail.conLst = RoomIndicatorInfo.getContactLst(leadDetail.Relcontact__r.Name,leadDetail.Relcontact__r.Phone,leadDetail.Relcontact__c,present_shopcode);
			// 2019/12/30 名前か電話番号のどちらかだけ一致するお客様がすでに存在する BY zyz END
			// お客様ステータス
			roomInfoDetail.customStatus = CommUtils.nullToBlank(leadDetail.Field298__c);
            // 到着日
            roomInfoDetail.entryDate =  leads[0].EntryTime__c.format(g_DateFormat);
            // 到着時刻
            roomInfoDetail.entryTime = leads[0].Field4__c;
            // 出発日
            roomInfoDetail.departureDate = leads[leads.size()-1].Departure__c.format(g_DateFormat);
            // 出発時刻
            roomInfoDetail.departureTime = leads[leads.size()-1].Field3__c;
			// 泊数
			roomInfoDetail.nights = leads[0].EntryTime__c.date().daysBetween(leads[leads.size()-1].Departure__c.date());
			roomInfoDetail.currentDate = leadDetail.EntryTime__c.format(g_DateFormat);
			// チェックインありフラグ設定
			roomInfoDetail.checkInFlg = false;
			for (Lead__c lead : leads) {
				if (CommUtils.nullToBlank(lead.Field298__c) == CommConst.LEAD_GUEST_ST_CI ||
					CommUtils.nullToBlank(lead.Field298__c) == CommConst.LEAD_GUEST_ST_OUT ||
					CommUtils.nullToBlank(lead.Field298__c) == CommConst.LEAD_GUEST_ST_BATH) {
					roomInfoDetail.checkInFlg = true;
					break;
				}
			}
			// 予約人数
			roomInfoDetail.leadPeopleNum = leadDetail.StayPersons__c;
			// 予約チャネル
			roomInfoDetail.leadChannel = leadDetail.Field2__c;
			// プラン
			roomInfoDetail.leadPlan = leadDetail.Field310__r.Name;
			// 部屋
			roomInfoDetail.leadRoom = leadDetail.Rroom__r.Name;
			roomInfoDetail.leadRoomId = leadDetail.Rroom__c;
			// 特記事項
			roomInfoDetail.leadMemo = leadDetail.Comment3__c;
			// 部屋ＢＬＯＣＫ
			roomInfoDetail.isBlocked = leadDetail.Field276__c;
			//roomInfoDetail.setLeadInfo(leadDetail);
			if (!acountAcountLst.isEmpty()) {
				roomInfoDetail.accountId = acountAcountLst[0].Id;
				// 2013/10/28 会計済制御内容を追加する（POPUP画面に「印刷」ボタン追加ため）
				// Blankの場合、未会計の状態、「印刷」ボタンを非表示する
				roomInfoDetail.isAccountedFlg = CommUtils.isBlank(acountAcountLst[0].Field53__c) ? false : true;
				if (roomInfoDetail.isAccountedFlg) {
					roomInfoDetail.openAccPdfUrl = '/apex/AccountPdfSwitch?id=' + roomInfoDetail.accountId;
					// 会計書宛名
					String param1 = CommUtils.isBlank(acountAcountLst[0].AccountName__c) ?
                                    CommUtils.nullToBlank(acountAcountLst[0].ContactName__c) : acountAcountLst[0].AccountName__c;
					// 請求書宛名
					String param2 = CommUtils.isBlank(acountAcountLst[0].AccountReceiptName__c) ?
                                    CommUtils.nullToBlank(acountAcountLst[0].BillingCal__c) : acountAcountLst[0].AccountReceiptName__c;
					// 領収書但し
					String param3 = CommUtils.nullToBlank(acountAcountLst[0].AccountProviso__c);
					roomInfoDetail.openAccPdfUrl += '&cuName=' + param1 + '&language=jp&recpName=' + param2 +
													'&accountProviso=' + param3;
					// 2017/09/06 直接印刷するとき、泊数情報を再設定しないように改善対応 BEGIN
					roomInfoDetail.openAccPdfUrl += '&prm=1';
					// 2017/09/06 直接印刷するとき、泊数情報を再設定しないように改善対応 END
				}
			}
			// XML___wgch 2016/11/16 BEGIN		
			roomInfoDetail.leadObj = leadDetail;
			// 2017/01/25 新規画面の項目自定義機能 by zy BEGIN
			String contactId = leads[0].Relcontact__c;
			roomInfoDetail.contactObj = queryContact(contactFields,contactId);
			// 2017/01/25 新規画面の項目自定義機能 by zy END
			// XML___wgch 2016/11/16 END		
			return roomInfoDetail;
    	}else {
    		//return null;
    		if (!CommUtils.isBlank(roomId)) {
    			Room__c  room = [select id, Name from Room__c where id = :roomId];
    			PopupWinInfo roomInfoDetail = new PopupWinInfo();
    			roomInfoDetail.leadRoom = room.Name;
    			roomInfoDetail.leadRoomId = room.Id;
    			return roomInfoDetail;
    		} else {
    			return null;
    		}
    	}
    }
    @remoteaction 
	global static RoomIndicatorInfo.MsgItem preChgSaveNightsInfo(String roomId, String fromLeadId, Integer orgNights, Integer newNights, String queryDt, Boolean showToday) {
    	return RoomIndicatorInfo.preChgSaveNightsInfo(roomId,fromLeadId,orgNights,newNights,queryDt,showToday);
    }
    /*
	* お客様のメッセージ取得する
	* contactFields:XML定義のお客様の項目
	* cId:お客様ID
	*/
	//共通化处理
	private static Contact queryContact(String contactFields,String cId){
		set<string> contactFieldsSet = new set<string>{'id','katakana__c','kananame1__c'};
		Contact c = new Contact();
		contactFieldsSet.addAll(Commutils.nullToBlank(contactFields).toLowerCase().deleteWhitespace().split(','));
		string contactQueryFields = '';
		//2016/11/29 tolabel error fix by zy BEGIN
		map<String, Schema.DescribeFieldResult> modelContactDeafaultValuesMap = CommSqlUtils.getAllFieldLst(Contact.sObjectType,true,true);
		//2016/11/29 tolabel error fix by zy END
		for (String key : contactFieldsSet) {
			if (CommUtils.isBlank(key)) continue;
			//2016/11/29 tolabel error fix by zy BEGIN
			if (modelContactDeafaultValuesMap.containsKey(key)){
				Schema.DescribeFieldResult dr = modelContactDeafaultValuesMap.get(key);
				if (dr.getType() == DisplayType.Picklist || dr.getType() == DisplayType.MultiPicklist){
	    			key = 'toLabel(' + dr.getName() + ')';
//system.debug(logginglevel.info,'key:::' + key);
	    		}
			}
			//2016/11/29 tolabel error fix by zy END
			contactQueryFields+= key + ',';
		}
		contactQueryFields = contactQueryFields.removeEnd(',');	
		String contactQuery = 'Select ' + contactQueryFields + ' From Contact';
		String contactId = cId;
		contactQuery += ' where id=:contactId';
		List<Contact> contactLst = Database.query(contactQuery);
		if(!contactLst.isEmpty()) c = contactLst[0];
		return c; 
	}
	 // 部屋ステータス照会情報
    global class PopupWinInfo {
    	// 予約名
    	public String leadId{get; set;}
    	public String leadName{get; set;}
    	// お客様
    	public String customId{get; set;}
    	public String customName{get; set;}
    	// お客様ステータス
    	public String customStatus{get; set;}
    	// 到着日
    	//public Date entryDate{get; set;}
    	public String entryDate{get; set;}
    	// 到着時刻
    	public String entryTime{get; set;}
    	// 出発日
    	//public Date departureDate{get; set;}
    	public String departureDate{get; set;}
    	// 出発時刻
    	public String departureTime{get; set;}
    	// 予約人数
    	public Decimal leadPeopleNum {get ;set;}
    	public Decimal orgLeadPeopleNum {get ;set;}
    	// 予約チャネル
    	public String leadChannel{get; set;}
    	// プラン
    	public String leadPlan{get; set;}
    	// 部屋
    	public String leadRoom{get; set;}
    	public String leadRoomId{get; set;}
    	// 特記事項
    	public String leadMemo{get; set;}
    	// 会計ID
    	public String accountId{get; set;}
    	// 2017/05/12 部屋詳細情報画面レジカード機能対応 zyz BEGIN
    	public String yadoId{get; set;}
    	// 2017/05/12 部屋詳細情報画面レジカード機能対応 zyz END
    	// 泊数
    	public Decimal nights{get;set;}
    	public Decimal orgNights{get;set;}
    	
    	// チェックインありフラグ
    	public Boolean checkInFlg{get;set;}
    	public String leadIndexNo{get;set;}
    	public String leadIndexId{get;set;}
    	// 会計済み標識フラグ
    	public Boolean isAccountedFlg{get;set;}
    	// 会計書開くURL情報を格納する
    	public String openAccPdfUrl{get;set;}
    	// 該当予約の部屋はＢＬＯＣＫされている
    	public Boolean isBlocked{get;set;}
		// XML___wgch 2016/11/16 BEGIN	
    	public Lead__c leadObj{get;set;}
    	public Contact contactObj{get;set;}
    	public String Comment3{get;set;}
    	public String currentDate{get;set;}
		// XML___wgch 2016/11/16 END
		// 2019/12/30 名前か電話番号のどちらかだけ一致するお客様がすでに存在する BY zyz BEGIN
		// 顾客名和电话重复的顾客数据
		public list<Contact> conLst{get;set;}
		// 2019/12/30 名前か電話番号のどちらかだけ一致するお客様がすでに存在する BY zyz END
		public PopupWinInfo() {
			leadObj = new Lead__c();
			contactObj = new Contact();
		}
    }
    // 部屋情報維持する
    global class RoomInfo {
    	private String roomNameType;
    	public String stayPersonHelp1{get; private set;}	// 大人
        // Leads count
        public Integer leadsCount {get;set;}
        // LeadInfo
    	public Lead__c leadDetail{get;set;}
        //top Lead Id
        public String hiddenLeadId{get;set;}
        // 2017/12/22 画面フィルター機能追加　by　zy　END
        public String filterClass{get;set;}
        // 2017/12/22 画面フィルター機能追加　by　zy　END
    }
    // 2018/05/01 ルームインジケータで予約をクリックして、『部屋詳細情報』が開きます。
    // その後、『予約名』や『お客様』にて、次の画面が開きます。次の画面に移動した際に、
    // そのタブは『部屋詳細情報』が開いたままの状態でキープされ続けているのですが、
    // この画面（『部屋詳細情報』のみ）を自動で閉じてもらうようにすることはできますでしょうか by zy BEGIN
    public boolean isAutoClassFlag{get { return CommDefine__c.getOrgDefaults().RoomIndicatorDetailWindowAutoCloseFlg__c == null ? false : CommDefine__c.getOrgDefaults().RoomIndicatorDetailWindowAutoCloseFlg__c;}set;}
	// 2018/05/01 ルームインジケータで予約をクリックして、『部屋詳細情報』が開きます。 by zy END
    // 2020/02/29 レジカードのロゴを出力した部屋の「店舗情報」対応 BY zyz BEGIN
    public String shopLst{get{ 
    	Boolean CashLogoFlg = CommConst.APPOTION_CARREGISTER_LOGO_FLG;
    	String shopLstStr ='';
    	if(CashLogoFlg) {
    		List<String> ShopInfoLst = ShopInfoUtil.getCanSelectShopLst(UserInfo.getUserId());
    		if(!ShopInfoLst.isEmpty() && ShopInfoLst.size() > 1) shopLstStr = JSON.serialize(ShopInfoLst);
    	}
    	return shopLstStr;
    }}
    // 2020/02/29 レジカードのロゴを出力した部屋の「店舗情報」対応 BY zyz END
	// 2020/02/28 ルームインジケータ、タイムテーブル改修対象画面 BY zyz BEGIN
	public boolean confirmChgFlg{get;set;}
	// 2020/02/28 ルームインジケータ、タイムテーブル改修対象画面 BY zyz END
}