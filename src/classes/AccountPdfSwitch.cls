/**
* 会計書表示ページ切り替え機能
* 施設コードにて、各会社専用ページに切り替えてする
* 2010/11/05 表示項目を追加、[会計済みチェックボックス、会計日時、明細数、会計済み
* 2014/07/25 開始期間と終了期間は予約インデクスの設定開始日と終了日で初期設定する
* 2014/10/06 会計書のレイアウトは店舗別で制御機能を追加
**/
public with sharing class AccountPdfSwitch extends CommBaseCtrl{

	private final String recordId;
	private final Map<String,String> paramMap;
	public AccountAcount__c curSObj{get; private set;}
	// 2019/10/30 会計書、請求書のマージ機能対応 WGCH BEGIN
	public String pageNm{get {return pageNm == null ? '' : pageNm;} set;}
	public String prinUrl{get {return prinUrl == null ? '' : prinUrl;} set;} // 印刷的URL
	public static String prinAccId{get {return prinAccId == null ? '' : prinAccId;} set;} // 印刷的Id
	public Boolean isPgPrin{get {return isPgPrin == null ? false : isPgPrin;} set;} // マージ页面点击印刷动作FLG
	public Boolean isBillFlg{get {return isBillFlg == null ? false : isBillFlg;} set;} // 请求书FLG
	public Boolean isRoomFlg{get {return isRoomFlg == null ? false : isRoomFlg;} set;} // 印刷房间别FLG
	public Boolean isAccAllFlg{get {return isAccAllFlg == null ? false : isAccAllFlg;} set;} // 全部会计, 不加LeadIndex条件FLG
	public Boolean isPdfMergeFlg{get{ return CommConst.ACCOUNT_PDFMERGE_FLG;} set;} // 会計書のマージ機能FLG
	public Integer groupSize{get{return CommConst.APPOTION_PDF_PRINT_MAXROOMS;}} // 多少为一组的设定值
	public Lead__c ldSObj{get; private set;}
	public static final String BLANKID = '000000000000000';
	public AccountPdfSwitch(){}
	public PageReference AccAcountsSelectorMergeInit() {
		// 会計書のマージ画面无効の場合
		if(!isPdfMergeFlg){
			Map<String,String> paramMap = ApexPages.currentPage().getParameters();
			PageReference customPage = new PageReference('/apex/AccountPdfBulkSelector');
			customPage.getParameters().putAll(paramMap);
			customPage.setRedirect(true);
			return customPage;
		}
		prinUrl = prinAccId = '';
		isPgPrin = isRoomFlg = isAccAllFlg = false;
		isBillFlg = paramMap.containsKey('bill');
		// 開始日と終了日初期値設定する
		if (curSObj.Relreserve__r.LeadIndexRef__c != null) {
			c_termSt = new TimeManagement__c(WorkDay__c=curSObj.Relreserve__r.LeadIndexRef__r.EntryDate__c);
			c_termEt = new TimeManagement__c(WorkDay__c=curSObj.Relreserve__r.LeadIndexRef__r.DepartureDate__c);
		} else {
			c_termEt = new TimeManagement__c(WorkDay__c=Date.today());
			c_termSt = new TimeManagement__c(WorkDay__c=c_termEt.WorkDay__c.addDays(-7));
		}
		// 全ページから開始日付と終了日付を設定する場合、該当パラメータで優先で日付に設定を行う
		Map<String, String> locParMap = ApexPages.currentPage().getParameters();
		if (locParMap.containsKey('psd')) {
			String strStartDt = locParMap.get('psd');
			if (!CommUtils.isBlank(strStartDt)) c_termSt.WorkDay__c = CommUtils.stringToDate(strStartDt);
		}
		if (locParMap.containsKey('ped')) {
			String strEndDt = locParMap.get('ped');
			if (!CommUtils.isBlank(strEndDt)) c_termEt.WorkDay__c= CommUtils.stringToDate(strEndDt);
		}
		queryAccAcountList();
		// 現在の画面を表示する
		return null;
	}
	@remoteAction
	public static void syncPdfToAtta(String openUrl, String pageName, String isBill){
		List<String> urlLst = EncodingUtil.urlDecode(CommUtils.nullToBlank(openUrl), 'UTF-8').split('\\?');
		if(urlLst.size() != 2) return;
		String paramStr = urlLst[1];
		String curSObjId = '';
		Map<String, String> paramMap = new Map<String, String>();
		for(String p : CommUtils.nullToBlank(paramStr).split('\\&')){
			List<String> paramLst = CommUtils.nullToBlank(p).split('\\=');
			if(paramLst.size() == 2) paramMap.put(CommUtils.nullToBlank(paramLst[0]), CommUtils.nullToBlank(paramLst[1]));
			else if (paramLst.size() == 1) paramMap.put(CommUtils.nullToBlank(paramLst[0]), '');
		}
		if(paramMap.containsKey('id')) curSObjId = paramMap.get('id');
		if(isBill == 'true'){
			// 请求书PDF
			if(PdfAutoSaveUtil.isRunAutoPdfFutureForBill()) PdfAutoSaveUtil.syncBillPdfToAtta(paramMap,curSObjId,pageName);
			// 会计PDF
		} else if(PdfAutoSaveUtil.isRunAutoPdfFutureForAccount()) PdfAutoSaveUtil.syncAccountPdfToAtta(paramMap,curSObjId, pageName);
	}
	@remoteAction
	public static String getAccountItemGridInfo(String isAccAllFlgStr, String relaccountId,String refAccountId, String leadIndexId, String fromDate, String toDate, String prinAccIdStr){
		AccountPdfSwitch accPdf = new AccountPdfSwitch();
		// 全会计检索Flg赋值
		accPdf.isAccAllFlg = Boolean.valueOf(isAccAllFlgStr);
		// 预约赋值
		accPdf.ldSObj = new Lead__c();
		refAccountId = CommUtils.nullToBlank(refAccountId);
		if(!CommUtils.isBlank(refAccountId) && refAccountId != BLANKID) accPdf.ldSObj.refAccount__c = refAccountId;
		leadIndexId = CommUtils.nullToBlank(leadIndexId);
		if(!CommUtils.isBlank(leadIndexId) && leadIndexId != BLANKID) accPdf.ldSObj.LeadIndexRef__c = leadIndexId;
		// 会计赋值
		accPdf.curSObj = new AccountAcount__c();
		accPdf.curSObj.Relreserve__r = accPdf.ldSObj;
		relaccountId = CommUtils.nullToBlank(relaccountId);
		if(!CommUtils.isBlank(relaccountId) && relaccountId != BLANKID) accPdf.curSObj.relaccount__c = relaccountId;
		// 日期范围赋值
		accPdf.c_termSt = new TimeManagement__c(WorkDay__c = CommUtils.stringToDate(fromDate));
		accPdf.c_termEt = new TimeManagement__c(WorkDay__c = CommUtils.stringToDate(toDate));
		prinAccId = prinAccIdStr;
		accPdf.queryAccAcountList();
		return accItemGridInfoJson;
	}
	public static String accItemGridInfoJson{get{ return (CommUtils.isBlank(accItemGridInfoJson) ? JSON.serialize(new List<AccountItemGridInfo>()) : accItemGridInfoJson);} set;}
	public class AccountItemGridInfo {
		public AccountItemGridInfo(AccountItemInfo acc) {
			// 一括対象
			isChecked = acc.isChecked;
			// Account#
			accId = CommUtils.nullToBlank(acc.s.Id);
			accNm = CommUtils.nullToBlank(acc.s.Name);
			// お客様
			countId = CommUtils.nullToBlank(acc.s.relaccount__c);
			countNm = CommUtils.nullToBlank(acc.s.relaccount__r.Name);
			// ご予約
			ldId = CommUtils.nullToBlank(acc.s.Relreserve__c);
			ldNm = CommUtils.nullToBlank(acc.s.Relreserve__r.Name);
			// 取引先
			refAccId = CommUtils.nullToBlank(acc.s.Relreserve__r.RefAccount__c);
			refAccNm = CommUtils.nullToBlank(acc.s.Relreserve__r.RefAccount__r.Name);
			// 到着日
			entryTime = CommUtils.nullToBlank(acc.s.Relreserve__r.EntryTime__c == null ? '' : acc.s.Relreserve__r.EntryTime__c.date().format());
			// お部屋
			roomNm = CommUtils.nullToBlank(acc.s.Relreserve__r.Rroom__r.Name);
			// 部屋タイプ
			typeOfRoomNm = CommUtils.nullToBlank(acc.s.Relreserve__r.refTypeOfRooms__r.Name);
			// 売上計上日
			salesday = CommUtils.nullToBlank(acc.s.frs__r.Salesday__c == null ? '' : acc.s.frs__r.Salesday__c.format());
			// 会計日時
			field148 = CommUtils.nullToBlank(acc.s.Field148__c == null ? '' : acc.s.Field148__c.format());
			if(CommUtils.nullToBlank(acc.s.Field149__c).length() > 1 ) field148 += '　' + CommUtils.nullToBlank(acc.s.Field149__c);
			// 明細数
			childrens = acc.childrens;
			// 会計済 
			accountedFlgCal = CommUtils.nullToBlank(acc.s.AccountedFlgCal__c);
			// 会計人数
			field57 = CommUtils.nullToBlank(acc.s.Field57__c);
			// ご利用金額(税込)
			field151 = acc.s.Field151__c == null ? '0': acc.s.Field151__c.format();
		}
		public Boolean isChecked{get; set;} // 一括対象
		public String accId{get; set;} // Account#Id
		public String accNm{get; set;} // Account#Name
		public String countId{get; set;} // お客様Id
		public String countNm{get; set;} // お客様Name
		public String ldId{get; set;} // ご予約Id
		public String ldNm{get; set;} // ご予約Name
		public String refAccId{get; set;} // 取引先Id
		public String refAccNm{get; set;} // 取引先Name
		public String entryTime{get; set;} // 到着日
		public String roomNm{get; set;} // お部屋
		public String typeOfRoomNm{get; set;} // 部屋タイプ
		public String salesday{get; set;} // 売上計上日
		public String field148{get; set;} // 会計日時
		public Integer childrens{get; set;} // 明細数
		public String accountedFlgCal{get; set;} // 会計済
		public String field57{get; set;} // 会計人数
		public String field151{get; set;} // ご利用金額(税込)
	}
	// 2019/10/30 会計書、請求書のマージ機能対応 WGCH END
	public AccountPdfSwitch(ApexPages.StandardController controller){
		paramMap = ApexPages.currentPage().getParameters();
		recordId = controller.getId();
		// 2019/10/30 会計書、請求書のマージ機能対応 WGCH BEGIN
		// curSObj = [select id, name, Relreserve__r.LeadIndexRef__r.EntryDate__c, Relreserve__r.LeadIndexRef__r.DepartureDate__c, Relreserve__r.LeadIndexRef__c,ContactName__c from AccountAcount__c where id = :recordId ];//Database.query(CommSqlUtils.generateQueryString('AccountAcount__c') + ' Where Id = \'' + recordId + '\'');
		// 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH BEGIN
		// curSObj = [select id, name, relaccount__c, Relreserve__r.LeadIndexRef__r.EntryDate__c, Relreserve__r.LeadIndexRef__r.DepartureDate__c, Relreserve__r.LeadIndexRef__c,ContactName__c, Relreserve__r.refAccount__c from AccountAcount__c where id = :recordId ];//Database.query(CommSqlUtils.generateQueryString('AccountAcount__c') + ' Where Id = \'' + recordId + '\'');
		curSObj = [select id, name, relaccount__c, Relreserve__r.LeadIndexRef__r.EntryDate__c, Relreserve__r.LeadIndexRef__r.DepartureDate__c, Relreserve__r.LeadIndexRef__c,ContactName__c, Relreserve__r.refAccount__c, Relreserve__c, ShopCode__c from AccountAcount__c where id = :recordId ];//Database.query(CommSqlUtils.generateQueryString('AccountAcount__c') + ' Where Id = \'' + recordId + '\'');
		String shopCode = paramMap.get('shopcd');
		if(CommUtils.isBlank(shopCode)){
			UserUtil.UserShopInfo userInf = UserUtil.CurrentUserInfo;
			// 获取店铺默认设定Code
			ApexPages.currentPage().getParameters().put('shopcd', ShopInfoUtil.getShopDefCd(shopCode, curSObj.ShopCode__c, userInf.defaultShopCode, (curSObj.Relreserve__c != null)));
		}
		// 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH END
		ldSObj = new Lead__c(refAccount__c = curSObj.Relreserve__r.refAccount__c);
		// 2019/10/30 会計書、請求書のマージ機能対応 WGCH END
	}
	private static final Map<String, String> pageMap;
	static {
		pageMap = new Map<String,String>{
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
	}
	//public Map<Id, Boolean> checkedFlgMap{get; private set;}
	public class AccountItemInfo {
		public AccountItemInfo(AccountAcount__c acc) {
			s = acc;
			isChecked = true;
			childrens = 0;
		}
		public AccountAcount__c s	{get; private set;}
		public Boolean isChecked	{get; set;}
		// 明細件数
		public Integer childrens{get; set;}
	}
	public PageReference redirect() {
        // ページ遷移前のチェックを行う
        List<AccountAcount__c> checkLst = new List<AccountAcount__c>();
        checkLst.add(curSObj);
        //if (!preDirectProcess(checkLst)) return null;
		// システムの施設コード定義取得
		// 2014/10/06 EDIT BEGIN
		String facilityCode = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().FacilityCode__c);
		// 店舗コード
		// 2015/10/28 多店舗機能対応 BEGIN
		Map<String, String> locParMap = ApexPages.currentPage().getParameters();
    	String shopCode = locParMap.get('shopcd');
    	// 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH BEGIN
    	// 2020/06/30 BUG-FIX-#6525 WGCH BEGIN
    	if(CommUtils.isBlank(shopCode)){
    		// 获取店铺默认设定Code
    		shopCode = ShopInfoUtil.getShopDefCd(shopCode, curSObj.ShopCode__c, UserUtil.CurrentUser.ShopCode__c, (curSObj.Relreserve__c != null));
		}
		// 2020/06/30 BUG-FIX-#6525 WGCH END
		// 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH END
    	if (CommUtils.isBlank(shopCode)) shopCode = UserUtil.CurrentUser.ShopCode__c;
    	// 2015/10/28 多店舗機能対応 END
		// String shopCode = UserUtil.CurrentUser.ShopCode__c;
		if (!CommUtils.isBlank(shopCode)) {
			ShopInformation__c shop = ShopInfoUtil.getShop(shopCode);
			if (!CommUtils.isBlank(shop.FacilityCode__c)) {
				facilityCode = shop.FacilityCode__c;
				// 指定指定の施設コードは次の画面に引き渡す
				paramMap.put('fc',facilityCode);
			}
		}
		// 2017/01/16 請求書/会計書PDFファイルを自動保存対応 BEGIN
		String pageName = pageMap.get(facilityCode) == null ? '/apex/AccountPDF' : '/apex/' + pageMap.get(facilityCode);
		// 2019/03/29 施設コードが非存在場合、デフォルト：１を設定する WSQ BEGIN
		if (!pageMap.containsKey(facilityCode)) paramMap.put('fc','1');
		// 2019/03/29 施設コードが非存在場合、デフォルト：１を設定する WSQ END
		// 2019/10/30 会計書、請求書のマージ機能対応 WGCH BEGIN
		// if (PdfAutoSaveUtil.isRunAutoPdfFutureForAccount()) PdfAutoSaveUtil.syncAccountPdfToAtta(paramMap,curSObj.Id,pageName);
		if(isPgPrin){
			pageNm = pageName;
			paramMap.remove('bulkid');
			if(isRoomFlg) paramMap.put('bp','1');
		} else if (PdfAutoSaveUtil.isRunAutoPdfFutureForAccount()) PdfAutoSaveUtil.syncAccountPdfToAtta(paramMap,curSObj.Id,pageName);
		// 2019/10/30 会計書、請求書のマージ機能対応 WGCH END
		//PageReference customPage = new PageReference( pageMap.get(facilityCode) == null ? '/apex/AccountPDF' : '/apex/' + pageMap.get(facilityCode) );
		PageReference customPage = new PageReference( pageName );
		// 2017/01/16 請求書/会計書PDFファイルを自動保存対応 END
		customPage.getParameters().putAll(paramMap);
		customPage.setRedirect(true);
		// 2019/10/30 会計書、請求書のマージ機能対応 WGCH BEGIN
		if(isPgPrin){
			prinUrl = customPage.getUrl();
			return null;
		}
		// 2019/10/30 会計書、請求書のマージ機能対応 WGCH END

        // 遷移直前前の関連処理
        aftDirectProcess(checkLst);

		return customPage;
	}
	/**
	* 一括会計情報を表示する
	**/
	//public String termStartDt{get; set;}
	//public String termEndDt{get; set;}
	public TimeManagement__c c_termSt{get; set;}
	public TimeManagement__c c_termEt{get; set;}
	//public String customTitle{get; set;}
	//public String redirectUrl{get; private set;}
	public PageReference AccAcountsSelectorInit() {

		// 開始日と終了日初期値設定する
		if (curSObj.Relreserve__r.LeadIndexRef__c != null) {
			c_termSt = new TimeManagement__c(WorkDay__c=curSObj.Relreserve__r.LeadIndexRef__r.EntryDate__c);
			c_termEt = new TimeManagement__c(WorkDay__c=curSObj.Relreserve__r.LeadIndexRef__r.DepartureDate__c);
		} else {
			c_termEt = new TimeManagement__c(WorkDay__c=Date.today());
			c_termSt = new TimeManagement__c(WorkDay__c=c_termEt.WorkDay__c.addDays(-7));
		}
		// 全ページから開始日付と終了日付を設定する場合、該当パラメータで優先で日付に設定を行う
		Map<String, String> locParMap = ApexPages.currentPage().getParameters();
		if (locParMap.containsKey('psd')) {
			String strStartDt = locParMap.get('psd');
			if (!CommUtils.isBlank(strStartDt)) c_termSt.WorkDay__c = CommUtils.stringToDate(strStartDt);
		}
		if (locParMap.containsKey('ped')) {
			String strEndDt = locParMap.get('ped');
			if (!CommUtils.isBlank(strEndDt)) c_termEt.WorkDay__c= CommUtils.stringToDate(strEndDt);
		}
		// 該当パラメータが存在する場合、会計情報一件の場合、自動的に会計書を表示する、複数件が存在する場合、該当一括画面を表示する
		String isAutoDirectFlg = locParMap.get('pat');
		
		//checkedFlgMap = new Map<Id, Boolean>();
		queryAccAcountList();
		
		// 画面自動切替処理機能を起動する場合、1件の場合、直接次の画面に遷移する、N件の場合、一括処理画面に起動して、表示する
		if (!CommUtils.isBlank(isAutoDirectFlg)) {
            // 2017/09/06 直接印刷するとき、泊数情報を再設定しないように改善対応 BEGIN
			//if (accAcountLst.size() <= 1) {
			if (validateAccNums <= 1) {
            // 2017/09/06 直接印刷するとき、泊数情報を再設定しないように改善対応 END
				// 請求書ページに遷移する
				if (isFromBillBulkPageFlg) return redirectBillPlugin();
				else return redirectPlugin();
			}
		}
		// 現在の画面を表示する
		return null;
	}
	// 2017/09/06 直接印刷するとき、泊数情報を再設定しないように改善対応 BEGIN
	// 実際の会計数(会計明細あり　OR　会計支払明細あり）
	private Integer validateAccNums;
	// 2017/09/06 直接印刷するとき、泊数情報を再設定しないように改善対応 END
	/**
	* 一括請求初期起動
	**/
	private Boolean isFromBillBulkPageFlg = false;
	public PageReference BillAcountsSelectorInit() {
		isFromBillBulkPageFlg = true;
		return AccAcountsSelectorInit();
	}

	//public List<AccountAcount__c> accAcountLst{get; private set;}
	public List<AccountItemInfo> accAcountLst{get; private set;}
	
	private boolean preQueryAccAcountList() {
		/*
		try {
			Date dt1 = Date.parse(termStartDt);
			Date dt2 = Date.parse(termEndDt);
		} catch (Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '有効な処理日を入力ください.'));
			return false;
		}*/
		return true;
	}
	public void queryAccAcountList() {
		// 事前チェックを行う
		if (!preQueryAccAcountList()) {
			return;
		}
		accAcountLst = new List<AccountItemInfo>();
		
		Date sDt = c_termSt.WorkDay__c == null ? Date.newInstance(1900,1,1) : c_termSt.WorkDay__c;
		Date eDt = c_termEt.WorkDay__c == null ? Date.newInstance(3000,1,1) : c_termEt.WorkDay__c;
		
		String startDt = (DateTime.newInstance(sDt.year(), sDt.month(), sDt.day())).format('yyyyMMdd'); //termStartDt.replaceAll('/','');
		String endDt = (DateTime.newInstance(eDt.year(), eDt.month(), eDt.day())).format('yyyyMMdd'); //termEndDt.replaceAll('/','');
		// 会計IDを格納する
		Set<Id> accIdSet = new Set<Id>();
		// 同じグループの会計情報を一括表示する[到着日順]
		// 2019/10/30 会計書、請求書のマージ機能対応 WGCH BEGIN
		/*
		List<AccountAcount__c> accRsLst = [select id, name , Field147__c, Field151__c, relaccount__c, Relreserve__c,ContactName__c,
			//Relreserve__r.EntryTime__c, (Select Id From AcountsRef__r)
			Field148__c, Field149__c, AccountedFlgCal__c,
			Relreserve__r.EntryTime__c,Relreserve__r.Rroom__r.Name,Relreserve__r.refTypeOfRooms__r.Name, frs__r.Salesday__c,Field57__c,Field53__c
			,(Select Id From TranAccount__r limit 1), (Select CreatedDate From TranTotalfromPay__r limit 1)
			From AccountAcount__c where Relreserve__r.LeadIndexRef__c = :curSObj.Relreserve__r.LeadIndexRef__c
			And frs__r.Name >= :startDt And frs__r.Name <= :endDt
			// 2015/04/29 VOIDされる会計情報を非表示する対応: 取引種別 != CommConst.ACC_TRADE_VOID
			And Field39__c != :CommConst.ACC_TRADE_VOID
			Order By frs__r.Name, Name limit 1000];
		*/
		String ACC_TRADE_VOID = CommConst.ACC_TRADE_VOID;
		String queryStr = ' select id, name , Field147__c, Field151__c, relaccount__c, Relreserve__c,ContactName__c,Field148__c, Field149__c, AccountedFlgCal__c,Relreserve__r.EntryTime__c,Relreserve__r.Rroom__r.Name,Relreserve__r.refTypeOfRooms__r.Name, frs__r.Salesday__c,Field57__c,Field53__c,relaccount__r.Name,Relreserve__r.Name,Relreserve__r.refAccount__c, Relreserve__r.refAccount__r.name,(Select Id From TranAccount__r limit 1), (Select CreatedDate From TranTotalfromPay__r limit 1) From AccountAcount__c ';
		String whereStr = ' where frs__r.Name >= :startDt And frs__r.Name <= :endDt And Field39__c != : ACC_TRADE_VOID ';
		Set<String> leadIndexIdSet = new Set<String>{curSObj.Relreserve__r.LeadIndexRef__c};
		if(!isPdfMergeFlg){
			whereStr += ' And Relreserve__r.LeadIndexRef__c in: leadIndexIdSet ';
		} else {
			if(!isAccAllFlg){
				whereStr += ' And Relreserve__r.LeadIndexRef__c in: leadIndexIdSet ';
			}
			String relAccountId = curSObj.relaccount__c;
			String refAccountId = ldSObj.refAccount__c;
			if(!CommUtils.isBlank(relAccountId)) whereStr += ' And relaccount__c =: relAccountId ';
			if(!CommUtils.isBlank(refAccountId)) whereStr += ' And Relreserve__r.refAccount__c =: refAccountId ';
			Set<String> prinAccIdSet = new Set<String>();
			for(String accId : prinAccId.split(',')){
				if(CommUtils.isBlank(accId)) continue;
				// isChecked默认是TRUE, 不用在设TRUE
				prinAccIdSet.add(CommUtils.nullToBlank(accId));
			}
			if(!prinAccIdSet.isEmpty()) whereStr += ' And Id Not In: prinAccIdSet ';
		}
		String orderStr = ' Order By frs__r.Name, Name limit 1000 ';
		List<AccountAcount__c> accRsLst = Database.query((queryStr + whereStr + orderStr));
		// 2019/10/30 会計書、請求書のマージ機能対応 WGCH END
		// 宛名先名設定を行う
		//if(!accAcountLst.isEmpty()) customTitle = accAcountLst[0].ContactName__c;
		// 2017/09/06 直接印刷するとき、泊数情報を再設定しないように改善対応 BEGIN
		validateAccNums = 0;
		// 2017/09/06 直接印刷するとき、泊数情報を再設定しないように改善対応 END
		// 会計済フラグ情報格納する
		//checkedFlgMap.clear();
		for (AccountAcount__c acc: accRsLst) {
			//Boolean checkedFlg = acc.AcountsRef__r.size() > 0 ? true : false;
			// 会計明細と支払明細全部０件の場合、表示対象外[2015/05/20]
			// 2017/09/06 直接印刷するとき、泊数情報を再設定しないように改善対応 BEGIN
			//if (acc.TranAccount__r.isEmpty() && acc.TranTotalfromPay__r.isEmpty()) continue;
			if (!acc.TranAccount__r.isEmpty() || !acc.TranTotalfromPay__r.isEmpty()) validateAccNums++;
			// 2017/09/06 直接印刷するとき、泊数情報を再設定しないように改善対応 END
			//checkedFlgMap.put(acc.Id, checkedFlg);
			accAcountLst.add(new AccountItemInfo(acc));
			// 会計ID格納
			accIdSet.add(acc.Id);
		}
		
		// 会計データ関連の明細件数
		Map<Id, Integer> detailRsMap = new Map<Id, Integer>();
		AggregateResult[] detailRs = [select Field1__c accId, count(Id) childrenCnt from Tran1__c where Field1__c in :accIdSet and ParentTran1Ref__c = null Group By Field1__c];
		for (AggregateResult rs : detailRs) {
			detailRsMap.put((Id)rs.get('accId'), (Integer)rs.get('childrenCnt'));
		}
		for (AccountItemInfo item : accAcountLst) {
			if (detailRsMap.containsKey(item.s.Id)) item.childrens = detailRsMap.get(item.s.Id);
		}
		// 2019/10/30 会計書、請求書のマージ機能対応 WGCH BEGIN
		if(isPdfMergeFlg){
			// remoteAction数据集合处理
			List<AccountItemGridInfo> accItemGridInfoLst = new List<AccountItemGridInfo>();
			for(AccountItemInfo accItem : accAcountLst){
				accItemGridInfoLst.add(new AccountItemGridInfo(accItem));
			}
			accItemGridInfoJson = JSON.serialize(accItemGridInfoLst);
		}
		// 2019/10/30 会計書、請求書のマージ機能対応 WGCH END
	}

	// ページ遷移前のチェックを行う
	private Boolean preDirectProcess(List<AccountItemInfo> checkAccLst) {
        // 会計書を出力まで、会計済のレコードが存在がどうかチェックを行う
        Boolean checkedItemFlg = false;
        for (AccountItemInfo item : checkAccLst) {
        	if (item.isChecked) {
        		checkedItemFlg = true;
        		break;
        	}
        }
        if (!checkedItemFlg) {
        	//会計データは1件以上選択してください。
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_006_0409));
            return false;
        }
        // 20120915 該当チェックはまずなくします：TODO
        /*
        Set<Id> accsIdSet = new Set<Id>();
        for (AccountAcount__c acc: checkAccLst) {
            accsIdSet.add(acc.Id);
        }
        List<AcountsHistory__c> hisLst = [select id from AcountsHistory__c where AcountsRef__c in :accsIdSet limit 1];
        if (!hisLst.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '既に会計済会計情報が存在するため、会計書の作成が失敗しました。'));
            return false;
        }*/
        return true;
	}
	// ページ遷移前のチェックを行う
	private Boolean aftDirectProcess(List<AccountAcount__c> checkAccLst) {
        // 会計書出力処理記録を行う
        //writePdfHistory(checkAccLst);
        return true;
	}
	// 会計書出力
	public PageReference redirectPlugin() {
		// ページ遷移前のチェックを行う
        if (!preDirectProcess(accAcountLst)) return null;
		// パラメータ設定を行う
		//Map<String,String> paramMap = ApexPages.currentPage().getParameters();
		// 表示する会計IDをパラメータに設定する
		Set<Id> accAcountIdSet = new Set<Id>();
		String bulkIdStr = '';
		//for (AccountAcount__c acc: accAcountLst) {
		for (AccountItemInfo acc: accAcountLst) {
			if(!acc.isChecked) continue;
			bulkIdStr += acc.s.Id + ',';
		}
		//paramMap.put('cuName',customTitle);
		paramMap.put('bulkid',bulkIdStr.substring(0,  bulkIdStr.length()-1));


        // 遷移直前前の関連処理
        //aftDirectProcess(accAcountLst);

		return this.redirect();
		//redirectUrl = page.getUrl();
		//return page;
	}
	// 請求書出力
	public PageReference redirectBillPlugin() {
		// 2017/01/16 請求書/会計書PDFファイルを自動保存対応 BEGIN
		if (accAcountLst != null) {
		// 2017/01/16 請求書/会計書PDFファイルを自動保存対応 END
			// ページ遷移前のチェックを行う
	        if (!preDirectProcess(accAcountLst)) return null;
			// パラメータ設定を行う
			// 表示する会計IDをパラメータに設定する
			Set<Id> accAcountIdSet = new Set<Id>();
			String bulkIdStr = '';
			for (AccountItemInfo acc: accAcountLst) {
				if(!acc.isChecked) continue;
				bulkIdStr += acc.s.Id + ',';
			}
			paramMap.put('bulkid',bulkIdStr.substring(0,  bulkIdStr.length()-1));
		// 2017/01/16 請求書/会計書PDFファイルを自動保存対応 BEGIN
		}
		String pageName = '/apex/BillPDF';
		// 2019/10/30 会計書、請求書のマージ機能対応 WGCH BEGIN
		// if (PdfAutoSaveUtil.isRunAutoPdfFutureForBill()) PdfAutoSaveUtil.syncBillPdfToAtta(paramMap,curSObj.Id,pageName);
		if(isPgPrin){
			pageNm = pageName;
			paramMap.remove('bulkid');
			if(isRoomFlg) paramMap.put('bp','1');
		} else if (PdfAutoSaveUtil.isRunAutoPdfFutureForBill()) PdfAutoSaveUtil.syncBillPdfToAtta(paramMap,curSObj.Id,pageName);
		// 2019/10/30 会計書、請求書のマージ機能対応 WGCH END
		
		// システムの施設コード定義取得
		//PageReference customPage = new PageReference('/apex/BillPDF');
		PageReference customPage = new PageReference(pageName);
		// 2017/01/16 請求書/会計書PDFファイルを自動保存対応 END
		customPage.getParameters().putAll(paramMap);
		customPage.setRedirect(true);
		// 2019/10/30 会計書、請求書のマージ機能対応 WGCH BEGIN
		if(isPgPrin){
			prinUrl = customPage.getUrl();
			return null;
		}
		// 2019/10/30 会計書、請求書のマージ機能対応 WGCH END
		return customPage;
	}
    /**
    * 会計書出力Actionの記録
    **//*
    private void writePdfHistory(List<AccountAcount__c> accLst) {
        // 会計出力Action記録する
        List<AcountsHistory__c> historyLst = new List<AcountsHistory__c>();
        for (AccountAcount__c acc: accLst) {
            historyLst.add(new AcountsHistory__c(Name = acc.Name, AcountsRef__c = acc.Id));
        }
        Database.upsert(historyLst, AcountsHistory__c.Name);
    }*/
}