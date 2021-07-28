/**
* 2017/09/04 ルームインジケータ画面から会計書一括印刷機能対応
* 2017/10/18 チェックアウト機能対応
* 2017/11/08 33/34不显示领收书表示的check
* 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善
* 2019/03/28 請求書一括印刷機能対応
**/
public with sharing class AccountPdfBulkPrintCtrl extends CommBaseCtrl{
	// 前ページから引き渡す情報を格納する
	private final Map<String,String> paramMap;
	public AccountPdfBulkPrintCtrl(){
		paramMap = ApexPages.currentPage().getParameters();
	}
	// ページ遷移対象チェック
	private static final Map<String, String> pageMap;
	static {
		pageMap = new Map<String,String>{
			// 2017/11/08 33/34不显示领收书表示的chec WGCH BEGIN
			'36'=>'AccountPDF_36',
			'35'=>'AccountPDF_35',
			'34'=>'AccountPDF_34',
			'33'=>'AccountPDF_33',
			'24'=>'AccountPDF_24',
			'23'=>'AccountPDF_23',
			'15'=>'AccountPDF_15',
			'14'=>'AccountPDF_14',
			'13'=>'AccountPDF_13',
			'12'=>'AccountPDF_12',
			'11'=>'AccountPDF_11',
			'10'=>'AccountPDF_10',
			'9'=>'AccountPDF_9',
			'8'=>'AccountPDF_8',
			'7'=>'AccountPDF_7',
			'6'=>'AccountPDF_6',
			'4'=>'AccountPDF_4',
			'3'=>'AccountPDF_3',
			// hotel-continental　会社会計書PDF専用ページ
			'2'=>'AccountPDF_1',
			// JINYA会社DefaultPDF専用ページ
			'1'=>'AccountPDF'};
			// 2017/11/08 33/34不显示领收书表示的chec WGCH END
	}
	// 2017/11/08 33/34不显示领收书表示的chec WGCH BEGIN
	public boolean accPrnShowBtnFlg{get; private set;}
	// 2017/11/08 33/34不显示领收书表示的chec WGCH END
	// 2019/04/30 請求書の送付表新規作成 BY zyz BEGIN
	public Boolean billLetterFlg{get{ return CommConst.Bill_LETTER_FLG;}}
	// 2019/04/30 請求書の送付表新規作成 BY zyz END
	// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
	public Boolean RespectFlg{get{return CommConst.RESPECT_ISSHOW_FLG;}}
	public List<Selectoption> mrTypeLst{get; private set;}
	public String mrStr{get; set;}
	// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
	/**
	* 一括会計情報を表示する
	**/
	public PageReference init() {
	    // 初期化
		urlStr = '';
		// 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH BEGIN
		// 2017/12/21 通过user记录设定 WGCH BEGIN
		noAccTran1Flg = noField151Flg = true;	
		// DBから設定情報を取得する
		map<string,string> userConfigMap = UserConfigCompCtrl.getKrepConfig(userId, '');
		String configSwapFlgKey = UserConfigCompCtrl.KREP_SUBTYPE.NOACCFLG.name();
		String configSwapFlgVal = '';
		if (userConfigMap.containsKey(configSwapFlgKey)) configSwapFlgVal = CommUtils.nullToBlank(userConfigMap.get(configSwapFlgKey));
		List<String> colSwapLst = configSwapFlgVal.split(',');
		for (String colSwapDef : colSwapLst) {
			List<String> defInf = colSwapDef.split(':');
			if (defInf.size() < 2) continue;
			String noAccFlg = defInf[0];
			if(noAccFlg == CONST_NOACCTRAN1FLG) noAccTran1Flg = Boolean.valueOf(defInf[1]);
			if(noAccFlg == CONST_NOFIELD151FLG) noField151Flg = Boolean.valueOf(defInf[1]);
		}
		// 2017/12/21 通过user记录设定 WGCH END
		// 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH END
		// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
		mrTypeLst = new List<Selectoption>();
		Schema.DescribeFieldResult fieldResult = AccountAcount__c.RespectLst__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
	   	for( Schema.PicklistEntry f : ple) {
	   	   if(f.isDefaultValue()) mrStr = f.getLabel(); 
           mrTypeLst.add(new SelectOption(f.getValue(),f.getLabel()));
	   	}
	   	// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
		selectDate = new BookingTimeTable__c();
		// 获取数据集
		return getAccountPdfDs();
	}
	// 年/月/日を選択する場合
	public void gotoDate() {
		// 获取数据集
		getAccountPdfDs();
	}
	// 2017/10/18 チェックアウト機能対応 BEGIN
	// 取子数据
	/**
	* accIdStr   => 所有子数据 accId字符串
	* checkedStr => 所有子数据 checked的状态
	**/
	@remoteAction
	// public static String getAccPrintItemInfo(String accIdStr,String checkedStr){
	public static String getAccPrintItemInfo(String accIdStr,String checkedStr,String queryDt){
	// 2017/10/18 チェックアウト機能対応 END
		// 详细数据AccId
		if(CommUtils.isBlank(accIdStr)) return JSON.serialize(new List<AccPrintItemInfo>());
		// 子数据 accIdLst
		set<String> accIdSet = new set<String>();
		for(String accId : accIdStr.split(',')){
			accIdSet.add(accId);
		}
		String accQueryWhere = ' Where Id in: accIdSet ';
		String accQueryOrder = ' Order By frs__r.Name, Name ';
		String accQueryStr = accQueryHeader + accQueryWhere + accQueryOrder;
		// 会计Id为Key 子数据集Map
		Map<String,AccPrintItemInfo> accInfoMap = new Map<String,AccPrintItemInfo>();
		// 子数据集
		List<AccPrintItemInfo> accPrintItemLst = new List<AccPrintItemInfo>();
		List<AccountAcount__c> accs = DataBase.query(accQueryStr);
		for(AccountAcount__c acc : accs){
			// 把数据转成InTheClass
			// 2017/10/18 チェックアウト機能対応 BEGIN
			// AccPrintItemInfo accPrintItem = new AccPrintItemInfo(acc,Boolean.valueOf(checkedStr));
			AccPrintItemInfo accPrintItem = new AccPrintItemInfo(acc,Boolean.valueOf(checkedStr),queryDt);
			// 2017/10/18 チェックアウト機能対応 END
			accPrintItemLst.add(accPrintItem);
		}
        // 会計データ関連の明細件数
        Map<Id, Integer> detailRsMap = new Map<Id, Integer>();
        AggregateResult[] detailRs = [select Field1__c accId, count(Id) childrenCnt from Tran1__c where Field1__c in :accIdSet and ParentTran1Ref__c = null Group By Field1__c];
        for (AggregateResult rs : detailRs) {
            detailRsMap.put((Id)rs.get('accId'), (Integer)rs.get('childrenCnt'));
        }
        for (AccPrintItemInfo item : accPrintItemLst) {
            //if (detailRsMap.containsKey(item.s.Id)) item.childrens = detailRsMap.get(item.s.Id);
            if (detailRsMap.containsKey(item.accId)) item.accSize = detailRsMap.get(item.accId);
        }
        
		return JSON.serialize(accPrintItemLst);
	}
	// 2017/10/18 チェックアウト機能対応 BEGIN
	// 一括チェックアウト機能が有効の場合、関連N部屋は該当日に存在するがどう
	// 一回チェックアウト機能が有効の場合、関聯の予約情報を一括チェックアウト処理を行う
	// 該当部屋のみチェックアウト処理を行う
	@RemoteAction
	public static string[] checkoutAction(String leadIdStr) {
		// Lead数据 ldIdLst
		set<String> ldIdSet = new set<String>();
		List<String> ldIdLst = leadIdStr.split(',');
		String ldIdStr = '';
		for(Integer i = 0; i < ldIdLst.Size(); i++){
			if(i > 20) ldIdStr += ldIdLst[i] + ',';
			else ldIdSet.add(ldIdLst[i]);
		}
		ldIdStr.removeEnd(',');
		String[] result = new List<String>{'',''};
		// 指定の予約IDからチェックアウトステータス変更を行う
		Savepoint sp = Database.setSavepoint();
		try {
			// 該当予約と同じ日付の予約情報を全部チェックアウトする
			// 該当会計に関連の予約情報を取得する、N部屋情報存在　かつ　該当部屋もチェックアウト日の場合、ビル一括印刷画面を起動して、一括チェックアウト指示画面を表示する
			Integer LEAD_ST_CANCEL_FLG = CommConst.LEAD_ST_CANCEL_FLG; // キャンセルまち
			String LEAD_GUEST_ST_CO = CommConst.LEAD_GUEST_ST_CO; // チェックアウト完
			// 関連予約情報は順番で部屋単位で取得する
			String targetLeadQuery = 'Select Id,Name, LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c, EntryTime__c, Departure__c, Rroom__c, Rroom__r.Name,Relcontact__c,Relcontact__r.Name,checkoutdate__c From Lead__c ' +
			                         'Where CancelBool__c !=: LEAD_ST_CANCEL_FLG And Field298__c !=: LEAD_GUEST_ST_CO And Field298__c != null And Id in:ldIdSet '; //And LeadIndexRef__c = :leadIdxId
			// 同じ部屋、到着日順で情報取得する
			targetLeadQuery += ' Order By LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c, EntryTime__c';
			List<Lead__c> targetLeads = DataBase.query(targetLeadQuery);
			List<Lead__c> newLeadLst = new List<Lead__c>();
			for(Lead__c updLead : targetLeads){
				updLead.Field298__c = LEAD_GUEST_ST_CO;
				newLeadLst.add(updLead);
			}
			if(!newLeadLst.isEmpty()){
				update newLeadLst;
				// 2017/12/19 該当部屋の清掃データを作成する[画面に指定日にて、清掃管理データを作成する] WGCH BEGIN
				(new RoomStatusManager()).createNoCleanRooms(Date.today(), newLeadLst);
				// 2017/12/19 該当部屋の清掃データを作成する[画面に指定日にて、清掃管理データを作成する] WGCH END
			}
			result[0] = ldIdStr;
		} catch (Exception e) {
			Database.rollback(sp);
			throw New CommException(CommUtils.getFieldValidationMessage(e.getMessage()));
		}
		return result;
	}
	// 2017/10/18 チェックアウト機能対応 END
	// 会計書出力
	public PageReference redirect(String bulkIdStr) {
		// 去除Url里不用参数
		// 2017/10/18 チェックアウト機能対応 BEGIN
		paramMap.remove('qdt');
		paramMap.remove('ldx');
		paramMap.remove('fp');
		// 2017/10/18 チェックアウト機能対応 END
		// ビル一括処理フラグを設定する
		paramMap.put('bp','1');
		// システムの施設コード定義取得
		// EDIT
		String facilityCode = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().FacilityCode__c);
		// 店舗コード
		// 多店舗機能対応
		Map<String, String> locParMap = ApexPages.currentPage().getParameters();
		String shopCode = locParMap.get('shopcd');
		if (CommUtils.isBlank(shopCode)) shopCode = UserUtil.CurrentUser.ShopCode__c;
		if (!CommUtils.isBlank(shopCode)) {
			ShopInformation__c shop = ShopInfoUtil.getShop(shopCode);
			if (!CommUtils.isBlank(shop.FacilityCode__c)) {
				facilityCode = shop.FacilityCode__c;
				// 指定指定の施設コードは次の画面に引き渡す
				paramMap.put('fc',facilityCode);
			}
		}
		// 2017/11/08 33/34不显示领收书表示的chec WGCH BEGIN
		accPrnShowBtnFlg = (facilityCode == '33' || facilityCode == '34');
		// 2017/11/08 33/34不显示领收书表示的chec WGCH END
		String pageName = pageMap.get(facilityCode) == null ? '/apex/AccountPDF_33' : '/apex/' + pageMap.get(facilityCode);
		PageReference customPage = new PageReference( pageName );
		customPage.getParameters().putAll(paramMap);
		customPage.setRedirect(true);
		// 2019/03/28 請求書一括印刷機能対応 WGCH BEGIN
		// TODO: 老板说请求书功能追加上之后就不自动跳转了
		/*
		if(!CommUtils.isBlank(bulkIdStr)){
			customPage.getParameters().put('bulkid', bulkIdStr);
			// 会計書の領収書欄を表示する・しない選択できる制御フラグ
			if(CommConst.APPOTION_RECEIPT_ISSHOW_FLG) customPage.getParameters().put('noreceipt', '1');
			return customPage;
		}
		// 获取最终的Url
		else urlStr = customPage.getUrl();
		*/
		// 2019/05/15 自动跳转页面修正 WGCH BEGIN
		if(!CommUtils.isBlank(bulkIdStr) && fpFlg){
			customPage.getParameters().put('bulkid', bulkIdStr);
			// 会計書の領収書欄を表示する・しない選択できる制御フラグ
			if(CommConst.APPOTION_RECEIPT_ISSHOW_FLG) customPage.getParameters().put('noreceipt', '1');
			return customPage;
		}
		// 2019/05/15 自动跳转页面修正 WGCH END
		urlStr = customPage.getUrl();
		// 2019/03/28 請求書一括印刷機能対応 WGCH END
		return null;
	}
	// 2019/03/28 請求書一括印刷機能対応 WGCH BEGIN
	public String billUrlStr{get;set;}                           // 请求书open Url
	// 発行日付
	public String acountdateStr{get{
		return DateTime.now().format(getDateFormat());
	}}
	// ハンコ表示
	public Boolean billStampIsShowFlg{get{return CommConst.Bill_STAMPISSHOW_FLG;} set;}
	// コメント
	public String billComment{get; set;}
	// 請求書のコメント欄を毎回手打ちし自動
	public List<SelectOption> commentOpts{get; set;}
	// 口座情報
	public String fixedMsg{get; set;}
	public List<SelectOption> fixedMsgOpts{get; set;}
	// 請求書出力
	public PageReference redirectBillPlugin(String bulkIdStr, String shopcd) {
		String pageName = '/apex/BillPDF';
		// システムの施設コード定義取得
		PageReference customPage = new PageReference(pageName);
		customPage.getParameters().put('shopcd', shopcd);
		customPage.setRedirect(true);
		billUrlStr = customPage.getUrl();
		return null;
	}
	// 2019/03/28 請求書一括印刷機能対応 WGCH END
	
	public String urlStr{get;set;}                           // open Url
	//private String bulkid;                                 // 一括会計のID
	//public String accountReceipt{get;set;}                 // open 領収書表示状态
	public transient List<List<AccPrintInfo>> accPrintAllLst{get;set;} // 主数据集
	public BookingTimeTable__c selectDate{get; private set;} // 出発日
	public String roomSizeLab{get; private set;}            // 房间数
	// 2017/10/18 チェックアウト機能対応 BEGIN
	public boolean fpFlg{get; private set;} // 标识会计页面进来的参数
	public Boolean coAndShowAccountWinFlg{get{return CommDefine__c.getOrgDefaults().CoAndShowAccountWin__c;}} // チェックアウト+会計書作成フラグ
	// 2017/10/18 チェックアウト機能対応 END
	// 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH BEGIN
	public static boolean noAccTran1Flg{get;set;} // 明细数FLG
	public static boolean noField151Flg{get;set;} // ご利用金額(税込)FLG
	// 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH END
	// 2017/12/21 通过user记录设定 WGCH BEGIN
	public static String CONST_NOACCTRAN1FLG{get{ return 'NOACCTRAN1FLG';}}
	public static String CONST_NOFIELD151FLG{get{ return 'NOFIELD151FLG';}}
	public String userId{get{ return UserInfo.getUserId();} private set;} // UserId
	// 2017/12/21 通过user记录设定 WGCH END
	public Integer groupSize{get{return CommConst.APPOTION_PDF_PRINT_MAXROOMS;}}                 // 多少为一组的设定值
	public Boolean accountReceiptOptIsShow{get{return CommConst.APPOTION_RECEIPT_ISSHOW_FLG;}} // 会計書の領収書欄を表示する・しない選択できる制御フラグ
	private static final Integer LEAD_ST_CANCEL_FLG = CommConst.LEAD_ST_CANCEL_FLG; // キャンセルまち
	private static final String ACC_TRADE_VOID = CommConst.ACC_TRADE_VOID;          // 取引種別 => ＶＯＩＤ
	private static final String ROOM_SORT_NAME_DIV = '1';    // 部屋表示順フラグ定数定義
	private static final String ROOM_SORT_DIV = CommDefine__c.getOrgDefaults().RoomSortDiv__c == null ? ROOM_SORT_NAME_DIV : CommDefine__c.getOrgDefaults().RoomSortDiv__c;
	
	private static final String accQueryHeader = ' Select id, name , Field147__c, Field151__c, relaccount__c, Relreserve__c, ContactName__c, Field148__c, Field149__c, AccountedFlgCal__c,'+
	                                             ' Relreserve__r.EntryTime__c, Relreserve__r.Rroom__r.Name, Relreserve__r.refTypeOfRooms__r.Name, frs__r.Salesday__c, Field57__c, Field53__c,'+
	                                             ' Field39__c, relaccount__r.Name, Relreserve__r.Name, Relreserve__r.Departure__c,ShopCode__c,'+
	                                             ' Relreserve__r.LeadIndexRef__c, Relreserve__r.LeadIndexSubId__c, Relreserve__r.RoomGroupNo__c From AccountAcount__c ';
	
	//private static final String constAccQueryOrder = ' Order By Relreserve__r.Rroom__r.AREA__c asc, Relreserve__r.Rroom__r.Floor__c asc';
	
	// 一括印刷対象データを取得する
	public PageReference getAccountPdfDs(){
		// ******************* 引き渡パラメータ情報を取得する ************** //
		if(selectDate.Checkinday__c == null){
			// 2017/10/18 チェックアウト機能対応 BEGIN
			String ldQueryDt = CommUtils.nullToBlank(paramMap.get('qdt'));
			// 2017/10/18 チェックアウト機能対応 END
			// 出発日
			selectDate.Checkinday__c = CommUtils.isBlank(ldQueryDt) ? Date.today() : CommUtils.stringToDate(ldQueryDt);
		}
		// データ抽出日
		Date queryDt = selectDate.Checkinday__c;
		// 店舗コード
		String shopcd = CommUtils.nullToBlank(paramMap.get('shopcd'));
		// 有効な予約データ && 出発日は週間の範囲で予約データを取得する
		String ldQueryWhere = ' Where CancelBool__c !=: LEAD_ST_CANCEL_FLG And DAY_ONLY(convertTimezone(Departure__c)) =: queryDt ';
		// 2017/10/18 チェックアウト機能対応 BEGIN
		/*
		// 店舗コードが存在すると、部屋タイプ関連制限を掛ける
		if (!CommUtils.isBlank(shopcd)) ldQueryWhere += ' And refTypeOfRooms__c in (select id from TypeOfRooms__c where ShopInfoRef__r.ShopCode__c =: shopcd) ';
		*/
		String leadIndexId = CommUtils.nullToBlank(paramMap.get('ldx'));
		fpFlg = paramMap.containsKey('fp');
		if(!CommUtils.isBlank(leadIndexId)) ldQueryWhere += ' And LeadIndexRef__c =: leadIndexId ';
		else {
			// 店舗コードが存在すると、部屋タイプ関連制限を掛ける
			if (!CommUtils.isBlank(shopcd)) ldQueryWhere += ' And refTypeOfRooms__c in (select id from TypeOfRooms__c where ShopInfoRef__r.ShopCode__c =: shopcd) ';
		}
		// 2017/10/18 チェックアウト機能対応 END
		// 関連予約情報を取得する
		String ldQueryStr = ' Select Id, LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c From Lead__c ' + ldQueryWhere;
		// 存放所有 有效的IndexId
		Set<Id> ldIndexIdSet = new Set<Id>();
		Set<Id> ldIndexSubIdSet = new Set<Id>();
		Set<Decimal> ldGroupNoSet = new Set<Decimal>();
		for(Lead__c lead : DataBase.query(ldQueryStr)){
		    ldIndexIdSet.add(lead.LeadIndexRef__c);
			ldIndexSubIdSet.add(lead.LeadIndexSubId__c);
			ldGroupNoSet.add(lead.RoomGroupNo__c);
		}
		// oneRoom => Departure—Max
		List<String> keySortList = new List<String>();
		map<String, List<Lead__c>> leadsMap = new map<String, List<Lead__c>>();
		set<id> roomIds = new set<Id>();
		// 部屋からONEROOMキー情報格納
		map<id, List<String>> roomIdtoKeyMap = new map<Id, List<String>>();
		// 関連予約情報は順番で部屋単位で取得する
		String targetLeadQuery = 'Select Id,Name, LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c, EntryTime__c, Departure__c, Rroom__c, Rroom__r.Name,Relcontact__c,Relcontact__r.Name From Lead__c '+
		                         'Where CancelBool__c !=: LEAD_ST_CANCEL_FLG And LeadIndexRef__c in :ldIndexIdSet And LeadIndexSubId__c in: ldIndexSubIdSet And RoomGroupNo__c in :ldGroupNoSet ';
		// 同じ部屋、到着日順で情報取得する
		targetLeadQuery += ' Order By LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c, EntryTime__c';
		List<Lead__c> targetLeads = DataBase.query(targetLeadQuery);
		for(Lead__c lead : targetLeads) {
			// ONEROOMの識別キー
			String key = lead.LeadIndexRef__c + '_' + lead.LeadIndexSubId__c + '_' + lead.RoomGroupNo__c;
			if(!leadsMap.containsKey(key)) {
			    leadsMap.put(key, new list<lead__c>());
			    keySortList.add(key);
			}
			leadsMap.get(key).add(lead);
			
		}
		// Remove不满足条件的预约IndexId
		for(String key : leadsMap.keySet()) {
		    // 該当部屋の最終出発日は画面指定の日付情報と違うと、該当部屋の予約情報は処理対象外になる
		    List<Lead__c> wkleads = leadsMap.get(key);
		    // 対象外の場合、処理を行わない
			if(queryDt != wkleads[wkleads.size()-1].Departure__c.date()) {
			    // 処理対象外になる
			    leadsMap.remove(key);
			    continue;
			}
            // 初日の部屋ID情報を取得する
            Id roomId = wkleads[0].Rroom__c;
            if (roomId != null) {       
                roomIds.add(roomId);
                if (!roomIdtoKeyMap.containsKey(roomId)) roomIdtoKeyMap.put(roomId, new List<string>());
                roomIdtoKeyMap.get(roomId).add(key);
            }
		}
		// 部屋表示順番を取得する
		List<Id> roomSortIdsLst = new List<Id>();
		if (!roomIds.isEmpty()) { 
		    String queryStr = 'select id from Room__c Where id in :roomIds ';
            String queryOrder = ' Order By AREA__c asc, Floor__c asc, ';
	        if (ROOM_SORT_DIV == ROOM_SORT_NAME_DIV) {
	            queryOrder += ' Seq__c asc ';
	        } else {
	            queryOrder += ' DisplayNo__c asc ';
	        }
	        List<Room__c> rooms = DataBase.query(queryStr+queryOrder);
	        for (Room__c room : rooms) {
	            roomSortIdsLst.add(room.Id);
	        }
		}
		// ******************* 会计情報を取得する ************** //
        set<id> targetLeadIds = new set<id>();
        for (String key : leadsMap.keyset()) {
            List<Lead__c> wkleads = leadsMap.get(key);
            for (Lead__c lead : wkleads) {
                targetLeadIds.add(lead.Id);
            }
        }
		// 按顺序集合
		List<String> containsKeyLst = new List<String>();
		// 根据Key Map集合
		Map<String, List<AccountAcount__c>> oneRoomAccLstMap = new Map<String, List<AccountAcount__c>>();
		// 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH BEGIN
		// 集计每房间里对应的会计IdSet
		Map<String, Set<String>> oneRoomAccIdMap = new Map<String, Set<String>>();
		// 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH END
		// 対象会計情報を格納する
        if (!targetLeadIds.isEmpty()) {
	        // 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH BEGIN
	        String accQueryStr = 'select id, Name, Field57__c, Relreserve__r.Departure__c, Relreserve__r.LeadIndexRef__c, Relreserve__r.LeadIndexSubId__c, Relreserve__r.RoomGroupNo__c,AccountedFlgCal__c,Field151__c from AccountAcount__c';
	        // 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH END
	        String accQueryWhere = ' Where Relreserve__c in: targetLeadIds And Field39__c != :ACC_TRADE_VOID ';
	        String accQueryOrder = ' ORDER BY Relreserve__r.LeadIndexRef__c, Relreserve__r.LeadIndexSubId__c, Relreserve__r.RoomGroupNo__c, Relreserve__r.EntryTime__c ';
	        accQueryStr += accQueryWhere + accQueryOrder;
	        List<AccountAcount__c> accs = DataBase.query(accQueryStr);
	        // 対象会計情報を取得する
			for(AccountAcount__c acc : accs){
				// 会计数据分组集计等处理
				String key = acc.Relreserve__r.LeadIndexRef__c + '_' + acc.Relreserve__r.LeadIndexSubId__c + '_' + acc.Relreserve__r.RoomGroupNo__c;
				// 纪录Key/部屋単位情報を格納する
				if(!oneRoomAccLstMap.containsKey(key)){
					oneRoomAccLstMap.put(key, new List<AccountAcount__c>());
					// 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH BEGIN
					oneRoomAccIdMap.put(key, new Set<String>());
					// 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH END
					containsKeyLst.add(key);
				}
				// 初始化Map
				oneRoomAccLstMap.get(key).add(acc);
				// 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH BEGIN
				oneRoomAccIdMap.get(key).add(acc.Id);
				// 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH END
			}
			// 会計データの最終日は期間外の場合、も出力対象外になる
			for (String key : oneRoomAccLstMap.keySet()) {
			    List<AccountAcount__c> wkAccs = oneRoomAccLstMap.get(key);
			    AccountAcount__c lastAcc = wkAccs[wkAccs.size()-1];
	            // 対象外の場合、処理を行わない
	            if(queryDt != lastAcc.Relreserve__r.Departure__c.date()) {
	                // 処理対象外になる
	                oneRoomAccLstMap.remove(key);
	                // 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH BEGIN
	                // 去掉无效的房间数据
	                oneRoomAccIdMap.remove(key);
	                // 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH END
	                leadsMap.remove(key);
	                continue;
	            }
			}
        }
        // 出力対象変数リストを初期化する
        accPrintAllLst = new List<List<AccPrintInfo>>();
        List<AccPrintInfo> onesetLst = new List<AccPrintInfo>();
        // 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH BEGIN
        // 合并所有的有效会计IdSet
        Set<String> accIdAllSet = new Set<String>();
        for(Set<String> accIdSet : oneRoomAccIdMap.values()){
        	accIdAllSet.addAll(accIdSet);
        }
        // 会計データ関連の明細件数
        Map<Id, Integer> detailRsMap = new Map<Id, Integer>();
        AggregateResult[] detailRs = [select Field1__c accId, count(Id) childrenCnt from Tran1__c where Field1__c in :accIdAllSet and ParentTran1Ref__c = null Group By Field1__c];
        for (AggregateResult rs : detailRs) {
            // 每笔会计对应的明细输
            detailRsMap.put((Id)rs.get('accId'), (Integer)rs.get('childrenCnt'));
        }
        // 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH END
        // 対象部屋の順番を取得する、該当部屋順番で、予約情報を取得して、関連
        for (Id roomId : roomSortIdsLst) {
            // 部屋からキーを取得する
            List<String> keys = roomIdtoKeyMap.get(roomId);
            for (String key : keys) {
	            if (!leadsMap.containsKey(key)) continue;
	            // 該当キー関連の予約情報と会計情報を取得する
	            List<Lead__c> relLeads = leadsMap.get(key);
	            // 関連会計情報を取得する
	            List<AccountAcount__c> relAccs = oneRoomAccLstMap.get(key);
	            // 会計ないと、処理対象外
	            if (relAccs == null) continue;
	            // 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH BEGIN
	            AccPrintInfo oneRoomInf = new AccPrintInfo(relLeads, relAccs, detailRsMap);
	            // 明细数map里不包含这个会计 => 并且 页面明细数FLG【ture】 就跳到下次循环
	            if(noAccTran1Flg && oneRoomInf.accTran1Size == 0) continue;
	            // ご利用金額(税込)FLG【true】 && ご利用金額(税込)为0  就跳到下次循环
	            if(noField151Flg && oneRoomInf.field151 == '0') continue;
	            // 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH END
	            // 関連のキーを抜きる
	            if (Math.mod(onesetLst.size(),1000) == 0) {
	                onesetLst = new List<AccPrintInfo>();
	                accPrintAllLst.add(onesetLst);
	            }
	            // ONEROOMの情報を設定する
	            // 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH BEGIN
	            /*
	            AccPrintInfo oneRoomInf = new AccPrintInfo(relLeads, relAccs);
	            */
	            // 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH END
	            onesetLst.add(oneRoomInf);
	            // 処理済みの情報は外す
	            leadsMap.remove(key);
	            oneRoomAccLstMap.remove(key);
            }
        }
        // 続いて情報格納用
        // 部屋未設定の予約に対して、設定を行う
        if (!leadsMap.isEmpty()) {
            List<AccPrintInfo> sec2List = new List<AccPrintInfo>();
            for (String key : keySortList) {
               if (leadsMap.containsKey(key)) {
                    // 該当キー関連の予約情報と会計情報を取得する
                    List<Lead__c> relLeads = leadsMap.get(key);
                    // 関連会計情報を取得する
                    List<AccountAcount__c> relAccs = oneRoomAccLstMap.get(key);
                    // 会計ないと、処理対象外
                    if (relAccs == null) continue;
                    // 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH BEGIN
                    AccPrintInfo oneRoomInf = new AccPrintInfo(relLeads, relAccs, detailRsMap);
                    // 明细数map里不包含这个会计 => 并且 页面明细数FLG【ture】 就跳到下次循环
                    if(noAccTran1Flg && oneRoomInf.accTran1Size == 0) continue;
                    // ご利用金額(税込)FLG【true】 && ご利用金額(税込)为0  就跳到下次循环
                    if(noField151Flg && oneRoomInf.field151 == '0') continue;
                    // 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH END
                    if (Math.mod(sec2List.size(),1000) == 0) {
                        sec2List = new List<AccPrintInfo>();
                        accPrintAllLst.add(sec2List);
                    }
		            // 出力対象格納する
                    // 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH BEGIN
                    /*
                    AccPrintInfo oneRoomInf = new AccPrintInfo(relLeads, relAccs);
                    */
                    // 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH END
                    sec2List.add(oneRoomInf);
               } 
            }
        }
        // 全体件数を集計する　
        Integer sumCnt = 0;
        String bulkIdStr = '';
        Boolean jumpPgFlg = roomIdtoKeyMap.size() == 1 && fpFlg;
        for (List<AccPrintInfo> onePageList : accPrintAllLst) {
            sumCnt += onePageList.size();
            if(jumpPgFlg) {
            	// 2019/05/15 BUGFIX 複数ページの場合、ID列の作成不正の不具合改修 WSQ BEGIN
            	//for(AccPrintInfo accItem : onePageList) bulkIdStr += accItem.bulkIdStr;
            	for(AccPrintInfo accItem : onePageList) bulkIdStr += CommUtils.isBlank(bulkIdStr) ? accItem.bulkIdStr : (','+accItem.bulkIdStr);
            	// 2019/05/15 BUGFIX 複数ページの場合、ID列の作成不正の不具合改修 WSQ END
            }
        }
        roomSizeLab = CommUtils.LabelReplace(Label.MSG_006_0410, CommUtils.nullToBlank(sumCnt));
        // 2019/03/28 請求書一括印刷機能対応 WGCH BEGIN
        // コメン取得
        CommentHelperCompCtrl commHelp = new CommentHelperCompCtrl();
        commHelp.isBillComment = true;
        commentOpts = commHelp.commOptionlst;
        billComment = '';
        // 当只有一个选项的处理
        if (commentOpts.size() == 1) billComment = commentOpts[0].getValue();
        // 口座情報
        UserUtil.FixedMessageInfo fmInfo = UserUtil.getFixedMsgInfo(shopcd);
        fixedMsg = fmInfo.fixedMsg;
        fixedMsgOpts = fmInfo.fixedMsgOpts;
        redirectBillPlugin(bulkIdStr, shopcd);
        // 2019/03/28 請求書一括印刷機能対応 WGCH END
		// Url
		return redirect(bulkIdStr);
	}
	/**
	** Tr行主数据结构
	**/
	public class AccPrintInfo{
	    // ONEROOM関連の会計と予約情報を格納する
		// 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH BEGIN
		public AccPrintInfo(List<Lead__c> relLeads, List<AccountAcount__c> accLst,Map<Id, Integer> detailRsMap){
		// 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH END
			// 一括対象
			isChecked = true;
			// 第一笔会计
			AccountAcount__c acc = null;
			// 到着日/出発日 最大値と最小値を設定する
			Lead__c firstLead = relLeads[0];
			Date entryDt = relLeads[0].EntryTime__c.date();
			Date deparDt = relLeads[relLeads.size()-1].Departure__c.date();
			// 2017/10/18 チェックアウト機能対応 BEGIN
			// 当前Tr行所有AccId
			bulkIdStr = ldIdStr =  '';
			// 2017/10/18 チェックアウト機能対応 END
			// 会計済みフラグ
			accountedFlgCal = null;
			
			if (accLst == null) {
			    accLst = new List<AccountAcount__c>();
			    acc = new AccountAcount__c();
			} else {
			    acc = accLst[0];
			}
			// 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH BEGIN
			Integer accTran1Size = 0;
			Decimal field151Int = 0;
			// 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH END
			// 2018/05/28 英文版bug修正 WGCH BEGIN
			// 通貨定義情報格納
			String currencyInf = UserInfo.getDefaultCurrency();
			Boolean isJPYFlg = (CommUtils.isBlank(CurrencyInf) || CurrencyInf == 'JPY');
			// 2018/05/28 英文版bug修正 WGCH END
			for(AccountAcount__c curAcc : accLst){
				// 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH BEGIN
				// 明细数map里包含这个会计 => 集计此放假的总明细数
				if(detailRsMap.containsKey(curAcc.Id)) accTran1Size += detailRsMap.get(curAcc.Id);
				// 合计此房间的ご利用金額(税込)
				field151Int += isJPYFlg ? CommUtils.nullToIntZero(curAcc.Field151__c) : CommUtils.nullToZero(curAcc.Field151__c);
				// 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH END
				// 所有的accId
				bulkIdStr += curAcc.Id + ',';
				// 2017/10/18 チェックアウト機能対応 BEGIN
				// 所有的LeadId
				if(deparDt == curAcc.Relreserve__r.Departure__c.date()) ldIdStr += curAcc.Relreserve__r.Id + ',';
				// 2017/10/18 チェックアウト機能対応 END
				// 会計済みは未会計の場合、該当フラグを記憶する
				if(curAcc.AccountedFlgCal__c.contains('unresolved')) accountedFlgCal = curAcc.AccountedFlgCal__c;
			}
			// 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH BEGIN
			field151 = field151Int.format();
			// 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH END
			bulkIdStr = bulkIdStr.removeEnd(',');
			// 2017/10/18 チェックアウト機能対応 BEGIN
			ldIdStr = ldIdStr.removeEnd(',');
			// 2017/10/18 チェックアウト機能対応 END
			// 到着日
			entryTime = CommUtils.nullToBlank(entryDt == null ? '' : entryDt.format());
			// 出発日
			departure = CommUtils.nullToBlank(deparDt == null ? '' : deparDt.format());
			// 泊数
			stayNightCal = entryDt.daysBetween(deparDt);
			// Account#
			accId = CommUtils.nullToBlank(acc.Id);
			accName = CommUtils.nullToBlank(acc.Name);
			// お客様
			relaccount = CommUtils.nullToBlank(firstLead.Relcontact__c);
			relaccountName = CommUtils.nullToBlank(firstLead.Relcontact__r.Name);
			// ご予約
			relreserve = CommUtils.nullToBlank(firstLead.Id);
			relreserveName = CommUtils.nullToBlank(firstLead.Name);
			// お部屋
			room = CommUtils.nullToBlank(firstLead.Rroom__c);
			roomName = CommUtils.nullToBlank(firstLead.Rroom__r.Name);
			// 会計済 
			if (accountedFlgCal == null) accountedFlgCal = CommUtils.nullToBlank(acc.AccountedFlgCal__c);
			// 会計人数
			field57 = CommUtils.nullToBlank(acc.Field57__c);
			// 明細件数
			accSize = accLst.Size();
			// accLst
			// this.accLst = accLst;
		}
		// 一括対象
		public Boolean isChecked{get; set;}
		// Account#
		public String accId{get; set;}
		public String accName{get; set;}
		// お客様
		public String relaccount{get; set;}
		public String relaccountName{get; set;}
		// ご予約
		public String relreserve{get; set;}
		public String relreserveName{get; set;}
		// お部屋
		public String room{get; set;}
		public String roomName{get; set;}
		// 到着日
		public String entryTime{get; set;}
		// 出発日
		public String departure{get; set;}
		// 泊数
		public Decimal stayNightCal{get; set;}
		// 会計済
		public String accountedFlgCal{get; set;}
		// 会計人数
		public String field57{get; set;}
		// 明細件数
		public Integer accSize{get; set;}
		// 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH BEGIN
		// 明細数
		public Integer accTran1Size{get; set;}
		// ご利用金額(税込)
		public String field151{get;set;}
		// 2017/11/30 ビル一括印刷で印刷不要な会計やすいため改善 WGCH END	
		// 当前Tr行所有AccId
		public String bulkIdStr{get; set;}
		// 2017/10/18 チェックアウト機能対応 BEGIN
		// 当前Tr行所有LdId
		public String ldIdStr{get; set;}
		// 2017/10/18 チェックアウト機能対応 END
		// accLst
		// public List<AccountAcount__c> accLst{get;set;}
	}
	/**
	** Tr行子数据结构
	**/
	public class AccPrintItemInfo{
		// 2017/10/18 チェックアウト機能対応 BEGIN
		// public AccPrintItemInfo(AccountAcount__c acc,Boolean checkedFlg){
		public AccPrintItemInfo(AccountAcount__c acc,Boolean checkedFlg,String queryDt){
		// 2017/10/18 チェックアウト機能対応 END
			// 一括対象
			isChecked = checkedFlg;
			// Account#
			accId = CommUtils.nullToBlank(acc.Id);
			accName = CommUtils.nullToBlank(acc.Name);
			// お客様
			relaccount = CommUtils.nullToBlank(acc.relaccount__c);
			relaccountName = CommUtils.nullToBlank(acc.relaccount__r.Name);
			// ご予約
			// 2017/10/18 チェックアウト機能対応 BEGIN
			Date qDt = CommUtils.isBlank(queryDt) ? Date.today() : CommUtils.stringToDate(queryDt);
			// 出発日Str
			String departureStr = CommUtils.nullToBlank(acc.Relreserve__r.Departure__c == null ? '' : acc.Relreserve__r.Departure__c.date().format());
			ldId = queryDt == departureStr ? CommUtils.nullToBlank(acc.Relreserve__r.Id) : '';
			// 2017/10/18 チェックアウト機能対応 END
			relreserve = CommUtils.nullToBlank(acc.Relreserve__c);
			relreserveName = CommUtils.nullToBlank(acc.Relreserve__r.Name);
			// 到着日
			entryTime = CommUtils.nullToBlank(acc.Relreserve__r.EntryTime__c == null ? '' : acc.Relreserve__r.EntryTime__c.date().format());
			// お部屋
			roomName = CommUtils.nullToBlank(acc.Relreserve__r.Rroom__r.Name);
			// 売上計上日
			frsSalesday = CommUtils.nullToBlank(acc.frs__r.Salesday__c == null ? '' : acc.frs__r.Salesday__c.format());
			// 会計日時
			field148 = CommUtils.nullToBlank(acc.Field148__c == null ? '' : acc.Field148__c.format());
			if(CommUtils.nullToBlank(acc.Field149__c).length() > 1 ) field148 += '　' + CommUtils.nullToBlank(acc.Field149__c);
			// 明細数
			accSize = 0;
			// 会計済 
			accountedFlgCal = CommUtils.nullToBlank(acc.AccountedFlgCal__c);
			// ご利用金額(税込)
			field151 = acc.Field151__c == null ? '0': acc.Field151__c.format();
			// acc
			// this.acc =acc;
			
		}
		// 一括対象
		public Boolean isChecked{get; set;}
		// Account#
		public String accId{get; set;}
		public String accName{get; set;}
		// お客様
		public String relaccount{get; set;}
		public String relaccountName{get; set;}
		// ご予約
		// 2017/10/18 チェックアウト機能対応 BEGIN
		public String ldId{get; set;}
		// 2017/10/18 チェックアウト機能対応 END
		public String relreserve{get; set;}
		public String relreserveName{get; set;}
		// 到着日
		public String entryTime{get; set;}
		// お部屋
		public String roomName{get; set;}
		// 売上計上日
		public String frsSalesday{get; set;}
		// 会計日時
		public String field148{get; set;}
		// 明細数
		public Integer accSize{get; set;}
		// 会計済
		public String accountedFlgCal{get; set;}
		// ご利用金額(税込)
		public String field151{get; set;}
		// acc
		// public AccountAcount__c acc{get;set;}
	}
}