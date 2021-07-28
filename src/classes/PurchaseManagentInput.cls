/**
* 仕入入力画面
* 2015/11/16 取引のID値により、仕入先情報を処理する　
* 2015/12/08 仕入振込データ出力は多パタン機能対応
* 2016/03/25 添付ファイル表示機能の対応
* 2016/04/21 課税対象外自動設定機能対応
* 2016/08/15 Salesforceからアップロードファイルを仕入VFから参照できる機能対応
* 2017/07/07 検索結果にFilter機能の追加
**/
public with sharing class PurchaseManagentInput extends CommBaseCtrl{

	public InputForm input{get; private set;}
	//public UserUtil.UserShopInfo userInf;
	public Decimal commTaxRate{get;set;}
	// 指定情報日の入力情報一覧情報を取得する
	public List<ItemInfo> purchaseList 	{get; private set;}
	// 店舗情報選択リスト情報を格納する
	public List<SelectOption> shopOpts  {get; private set;}
	//public List<SelectOption> batchStatusOpts  {get; private set;}

	public Date fromDt{get;set;}
	public Date toDate{get;set;}
	// すでに入金済み金額
	public Decimal depAmount{get; private set;}
	//public String useDate{get;set;}

	public ItemInfo inpData{get; private set;}	// データ登録情報格納用
	private Map<String,ShopInformation__c> shopInfoMap;
	public Integer editRowIdx{get;set;}			// 編集行目インデックス
	public String currentShopCode{get;set;}		// 指定の店舗コード
	// 2015/12/08 仕入振込データ出力は多パタン機能対応 BEGIN
	//public String batchShopCode{get;set;}		// バッチ起動指定の店舗コード
	//public String currentBatchStatus{get;set;}	// バッチ起動後のステータス
	// 2015/12/08 仕入振込データ出力は多パタン機能対応 END
	public Integer currentSize{get;set;}
    //private List<Id> newInsRsIdLst;					// 最新データIDを格納用リスト
    private integer pageSize = 50;	// １ペジにレコード数
    private final static Integer maxQueryNums = 10000;	// 最大１００００件以上レコードが存在すると、処理中止する
	// 2016/01/20 LOCALのプロファイル名を取得する BEGIN
	public Integer canShowMaxRsNum{get{return maxQueryNums;}}
	// 2016/01/20 LOCALのプロファイル名を取得する END
    // 改ページ機能対応
    //public PaginationUtil pageCtrl{get; set;}
    // 2016/08/15 Salesforceからアップロードファイルを仕入VFから参照できる機能対応	BEGIN
    private static final String fileDownloadUrl = '/';
	// 2016/08/15 Salesforceからアップロードファイルを仕入VFから参照できる機能対応	END
    public integer roundMode{get;set;}		// 端数処理区分
    private List<Id> orgPurIdLst;
    // 画面レポートボタン表示用情報格納
    //public List<ButtonItem> plusBtns{get; private set;}
    // 2015/12/11 Fix BEGIN
    public List<SelectOption> reportBtnOption{get; private set;}
    // 2015/12/11 Fix END
    public String typeTokamokuJson{get;set;}
    // 2015/12/08 仕入振込データ出力は多パタン機能対応 BEGIN
	public List<AccountingSyncBatchHelp.FilterBtn> filterBtnLst{get;set;}
	public List<PopwinInfo> popWinInfoLst{get;set;}
	public integer currentRowIdx{get;set;}
	// 2015/12/08 仕入振込データ出力は多パタン機能対応 END
	// 2016/01/19 LOCALのプロファイル名を取得する BEGIN
	public String profileNm{get; private set;}
	// 2016/01/19 LOCALのプロファイル名を取得する END
	// 2018/05/24 仕入画面で入庫処理を行う機能対応 WGCH BEGIN
	// 共通定義控制
	public Boolean purchaseFlg{get{return CommConst.PURCHASE_DETAIL_FLG;}}
	// 行數定義
	private static final Integer LIST_INPUT_DEF_ROWS = ( CommUtils.nullToIntZero(CommConst.APPOTION_DETAIL_DEF_INPUTLINES) == 0 
													? 10 
													: CommUtils.nullToIntZero(CommConst.APPOTION_DETAIL_DEF_INPUTLINES) );
	// 2018/05/24 仕入画面で入庫処理を行う機能対応 WGCH END
    // 初期化処理
	public PurchaseManagentInput() {
		//2018/05/24 仕入画面で入庫処理を行う機能対応 WGCH BEGIN
		purDetailLst = new list<PurDetailItem>();
		PurchaseDetailLst = new list<PurchaseDetail__c>();
		initPurDetailItem();
		//2018/05/24 仕入画面で入庫処理を行う機能対応 WGCH END
		// 既存表示用明細情報リストに格納
		purchaseList = new List<ItemInfo>();
		// 新規追加項目情報の格納（検索ボタンすると、情報リセットする）
		//newInsRsIdLst = new List<Id>();
		//messageCount = 0;
		// ユーザー所属する店舗情報コードを取得する
		currentShopCode = UserUtil.CurrentUser.ShopCode__c;
		// 2015/12/08 仕入振込データ出力は多パタン機能対応 BEGIN
		//batchShopCode = currentShopCode;
		// 2015/12/08 仕入振込データ出力は多パタン機能対応 END
		// 入力項目初期化する
		UserUtil.UserShopInfo userInf = UserUtil.CurrentUserInfo;
		// データ保存情報変数初期化
		inpData = new ItemInfo();
		// 勘定項目リスト初期化する
		shopOpts = ShopInfoUtil.getBranchShopLst(userInf.shops);
		// 店舗情報MAPを取得する
		shopInfoMap = ShopInfoUtil.getShopInfoMap(userInf.shops);
		fromDt = DateTime.now().date();
		toDate = fromDt;
		// 入力項目初期化する
		input = new InputForm();
		// 消費税情報
		// 2019/09/15 11.10月以降の仕入れ入力について税率が10%の商品と8%の商品入力をすることになると思うのですが、どうやって入力するのでしょうか by zy BEGIN
		/*
		JMST__c jmst = CommLogicProcess.getTaxRateInfo();
		commTaxRate = jmst.taxRate__c;
		*/
		initTaxList();
		// 2019/09/15 11.10月以降の仕入れ入力について税率が10%の商品と8%の商品入力をすることになると思うのですが、どうやって入力するのでしょうか by zy END
		// 2016/01/19 LOCALのプロファイル名を取得する BEGIN
		profileNm = CommLogicProcess.getLoginUserProfile().name;
		// 2016/01/19 LOCALのプロファイル名を取得する END
		// 開始インデックスID
		//startIndex = 0;
		// 終了インデックスID
		//endIndex = 0;
		// 現在インデックス
		//currentStartIdx = 0;
		// 共通定義情報の読み込み処理する
		AccountingSyncBatchHelp  help = new AccountingSyncBatchHelp(currentShopCode);
		//roundMode = CommUtils.getRoundTypeKbnByRoundMode(help.roundMode);
		roundMode = getRoundType();
		// 関連のレポートIDを取得する
		// 2016/04/21 課税対象外自動設定機能対応 BEGIN
		initPhashTypeKamokuInfo();
		// 2016/04/21 課税対象外自動設定機能対応 END
		//plusBtns = new list<ButtonItem>();
		// 2015/12/11 Fix BEGIN
		reportBtnOption = new List<SelectOption>();
		// 2015/12/11 Fix END
		if (help.purchaseRepBtns != null) {
			Set<String> repNames = new set<String>();
			for (AccountingSyncBatchHelp.ButtonItem btnItem : help.purchaseRepBtns) {
				if (!CommUtils.isBlank(btnItem.buttonLinkRepNm)) repNames.add(btnItem.buttonLinkRepNm);
			}
			List<Report> rptDepLst = [Select Id, Name From Report where Name = :repNames];
			map<string, id> rptNamesMap = new map<string,id>();
			for (Report rep : rptDepLst) { rptNamesMap.put(rep.Name, rep.Id); }
			for (AccountingSyncBatchHelp.ButtonItem item : help.purchaseRepBtns) {
				string repNm = item.buttonLinkRepNm;
				// REPORTのNAMEは非定義する場合、コメントラインとして、出力を行う
				if (CommUtils.isBlank(repNm)) {
					reportBtnOption.add(new SelectOption('', item.buttonLabel));
					continue;
				}
				if (rptNamesMap.containsKey(repNm)) {
					//plusBtns.add(new ButtonItem(rptNamesMap.get(repNm), item.buttonLabel));
					// 2015/12/11 Fix BEGIN
					reportBtnOption.add(new SelectOption(rptNamesMap.get(repNm), '　' +item.buttonLabel));
					// 2015/12/11 Fix END
				}
			}
		}
		typeTokamokuJson = help.typeTokamokuJson;
		// 2015/12/08 仕入振込データ出力は多パタン機能対応 BEGIN
		filterBtnLst = new List<AccountingSyncBatchHelp.FilterBtn>();
		if(help.filterBtnLst != null) filterBtnLst = help.filterBtnLst;
		popWinInfoLst = new List<PopwinInfo>();
		currentRowIdx = 0;
		// 2015/12/08 仕入振込データ出力は多パタン機能対応 END
		// 2017/07/07 検索結果にFilter機能の追加 WGCH BEGIN
		// 初始化
		getInitFilterDt();
		// 2017/07/07 検索結果にFilter機能の追加 WGCH END
	}
	// 2017/06/27 仕入SF1改善対応 BEGIN
	public PurchaseManagentInput(boolean isSf1) {}
	// 2017/06/27 仕入SF1改善対応 END
	public class ButtonItem {
		public ButtonItem(string val, string lab) {
			Label = lab;
			Value = val;
		}
		public string Label{get;private set;}
		public string Value{get;private set;}
	}
	// ***************
	// 初期化
	// ***************
	public void init() {
		// 最新情報を取得する
		queryDetailLst(true);
		initInput();
		// 2018/05/24 仕入画面で入庫処理を行う機能対応 WGCH BEGIN
		getColnumJson();
		// 2018/05/24 仕入画面で入庫処理を行う機能対応 WGCH END
	}
	private void initInput(){
	// 2015/12/08 仕入振込データ出力は多パタン機能対応 BEGIN
		for(AccountingSyncBatchHelp.FilterBtn btn : filterBtnLst){
			PopwinInfo popwinInfo = new PopwinInfo(currentShopCode); 
			String cookieName = CommUtils.isBlank( btn.cookieName) ? btn.btnLabel : btn.cookieName; 
			String cookieNamePrix = '_PurchaseManageInput_cookie_popwin_' + cookieName;
			Cookie shopCode = ApexPages.currentPage().getCookies().get(cookieNamePrix + '_batchShopCode');
			Cookie batchStatus = ApexPages.currentPage().getCookies().get(cookieNamePrix +'_currentBatchStatus');
			Cookie queryDt = ApexPages.currentPage().getCookies().get(cookieNamePrix +'_queryDate');
			Cookie startDt = ApexPages.currentPage().getCookies().get(cookieNamePrix +'_startDate');
			Cookie endDate = ApexPages.currentPage().getCookies().get(cookieNamePrix +'_endDate');
			Cookie batchFlag = ApexPages.currentPage().getCookies().get(cookieNamePrix +'_batchFlag');
			popwinInfo.filterBtn = btn;
			if(shopCode != null){
				String shopCodeVal = shopCode.getValue();
				// 店舗情報MAPを取得する
				if(!shopInfoMap.containsKey(shopCodeVal)) shopCodeVal = UserUtil.CurrentUser.ShopCode__c;
				popwinInfo.batchShopCode = shopCodeVal;
			}
			if(batchStatus != null)
				popwinInfo.currentBatchStatus = batchStatus.getValue();
			if(queryDt != null)
				popwinInfo.queryInput.Checkinday__c = CommUtils.stringToDate(queryDt.getValue());
			if(startDt != null)
				popwinInfo.batchFromDateInput.Checkinday__c = CommUtils.stringToDate(startDt.getValue());
			if(endDate != null)
				popwinInfo.batchToDateInput.Checkinday__c = CommUtils.stringToDate(endDate.getValue());
			
			if(batchFlag != null)
				popwinInfo.isBatchFlag = CommUtils.isBlank(batchFlag.getValue()) ? false : Boolean.valueOf(batchFlag.getValue());
			popwinInfo.prefixName = cookieName;
			popwinInfo.rowIdx = popWinInfoLst.size();
			popWinInfoLst.add(popwinInfo);
		}
	// 2015/12/08 仕入振込データ出力は多パタン機能対応 END
	}
    /*
     * 機能： 改ページ：最初ページ
     */
    public void firstPage(){
        pageCtrl.firstPage();
  		convertDataToList(pageCtrl.records);
    }
    /*
     * 機能： 改ページ：最後ページ
     */
    public void lastPage(){
        pageCtrl.lastPage();
        convertDataToList(pageCtrl.records);
    }
    /*
     * 機能： 改ページ：前ページ
     */
    public void previousPage(){
        pageCtrl.previousPage();
        convertDataToList(pageCtrl.records);
    }
    /*
     * 機能： 改ページ：次のページ
     */
    public void nextPage(){
        pageCtrl.nextPage();
        convertDataToList(pageCtrl.records);
    }
    public void chgPageSize(){
    	pageSize = currentSize;
    	//System.debug(logginglevel.info,'pageSize::: '+  pageSize);
    	// 2017/07/07 検索結果にFilter機能の追加 WGCH BEGIN
    	//dataSearch();
    	filterDataSerch();
    	// 2017/07/07 検索結果にFilter機能の追加 WGCH END
    	//firstPage();
    	//convertDataToList(pageCtrl.records);

    }
	// *********************
	// データ新規・更新処理を行う
	// *********************
	public void dataUpsert() {
		// 2017/07/07 検索結果にFilter機能の追加 WGCH BEGIN
		// 初始化
		filter.sqlFlg = true;
		// 2017/07/07 検索結果にFilter機能の追加 WGCH END
		Boolean isInsert = false;
		try {
			// 2018/03/07 Security Check BEGIN
			List<String> insChkFields = new List<String>{'JinyaRevenue__c','ShopInfoRef__c',
														'PsalesproductRef__c','Purchasesource__c'}; //,'Id','JinyaRevenue__r','ShopInfoRef__r'
			Map<String,Schema.SObjectField> insm = Schema.SObjectType.Purchase__c.fields.getMap();
			if (!CommSecurityUtils.isCanCreateable(insChkFields, insm)) {
				return;
			}
			// 2018/03/07 Security Check END
			// 有効性チェック
			ItemInfo item = inpData;
			// 編集対象情報のインデックスにより、編集情報IDを取得する
			item.pur.Id = purchaseList[editRowIdx].pur.Id;
			// 店舗コードから店舗のIDを取得する
			// 関連の参照関係を再取得、設定を行う
			Purchase__c pur = item.pur;
			// 指定の仕入日により、仕入日の売上参照情報を更新する
			RsvAccount__c curRsvAccount = CommLogicProcess.getRsvAccountInf(item.salesDt);
			/*
			if(CommUtils.isBlank(pur.Purchasesource__c) && !CommUtils.isBlank(item.purchasesourceName)){
				List<Account> accs = [Select name,id from Account where name = :item.purchasesourceName];
				if(!accs.isEmpty()){
					if(accs.size() > 1){
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CommUtils.getFieldValidationMessage('仕入先:複数の項目が見つかりました。アイコンをクリックして検索結果を絞り込んでください。')));
						return;
					}
					pur.Purchasesource__c = accs[0].id;
				}else{
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CommUtils.getFieldValidationMessage('仕入先:項目')));
					return;
				}
			}*/
			AccountInf info = checkAccount(pur.Purchasesource__c,item.purchasesourceName);
			if(!CommUtils.isBlank(info.errorMsg)){
				//仕入先
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CommUtils.getFieldValidationMessage(Label.MSG_040_0088 + ':' + info.errorMsg)));
				return;
			}else if(CommUtils.isBlank(info.acc.id)){
				//仕入先:値を入力してください
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CommUtils.getFieldValidationMessage(Label.MSG_040_0089)));
				return;
			}
			pur.Purchasesource__c = info.acc.id;
			//System.debug(logginglevel.info,'pur:::' + pur);
			if(CommUtils.isBlank(pur.PsalesproductRef__c) && !CommUtils.isBlank(item.productNm)){
				List<AccountMaster__c> accs = [Select name,id from AccountMaster__c where name = :item.productNm];
				if(!accs.isEmpty()){
					if(accs.size() > 1){
						//会計商品:複数の項目が見つかりました。アイコンをクリックして検索結果を絞り込んでください。
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CommUtils.getFieldValidationMessage(Label.MSG_040_0090)));
						return;
					}
					pur.PsalesproductRef__c = accs[0].id;
				}
			}
			if(!CommUtils.isBlank(item.shopCode)){
				// 最新の店舗コードにより、店舗IDを再設定を行う
				ShopInformation__c shop = ShopInfoUtil.getShop(item.shopCode);
				pur.ShopInfoRef__c = shop.id;
				pur.ShopInfoRef__r = shop;
			}
			pur.JinyaRevenue__c = curRsvAccount.id;
			pur.JinyaRevenue__r = curRsvAccount;
			// 新規の場合、
			if (item.isPurInsert()) {
				insert pur;
				isInsert = true;
				CookieInf cookInf = new CookieInf(pur);
				setCookieInf(cookInf);
			}
			// 更新の場合
			else {
				// 店舗情報の参照IDを設定する
				//item.isReadOnly = true;
				// 更新処理を行う
				// 2018/03/07 Security Check BEGIN
				if (CommSecurityUtils.isCanUpdateable(Purchase__c.getSObjectType())) {
				// 2018/03/07 Security Check END
				upsert item.pur;
				// 2018/03/07 Security Check BEGIN
				}
				// 2018/03/07 Security Check END
			}
		} catch(Exception e) {
			// エラー処理情報出力する
			// 2020/03/31 会計ロック機能 by zy BEGIN
			if (!e.getMessage().contains(Label.MSG_006_0459))
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CommUtils.getFieldValidationMessage(e.getMessage())));
			// 2020/03/31 会計ロック機能 by zy END
			return;
		}
		// 入力情報のクリアする
		inpData = new ItemInfo();
		// 最新情報の取得する（指定ページ番号により、１ページの表示用情報を取得、表示を行う）
		queryDetailLst(!isInsert);
	}
	// *****************
	// 検索処理機能
	// *****************
	public void dataSearch(){
	    // 2017/07/07 検索結果にFilter機能の追加 WGCH BEGIN
	    // 初始化
	    getInitFilterDt();
	    // 2017/07/07 検索結果にFilter機能の追加 WGCH END
		// 最新情報を検索する
		queryDetailLst(true);
	}
	// 2017/07/07 検索結果にFilter機能の追加 WGCH BEGIN
    // *****************
    // FILTERの検索処理機能
    // *****************
    public void filterDataSerch() {
        // 最新情報を検索する
        queryDetailLst(true); 
    }
    // 2017/07/07 検索結果にFilter機能の追加 WGCH END
	// *****************
	// 店舗情報を切り替えする
	// *****************
	/*
	public void refreshBranShop() {
		// 店舗切替すると、最新明細情報を検索する
		queryDetailLst(true);
	}*/
	// 指定行目情報を編集モードに変更する
	public void historyEdit() {
		// 入力行目はReadonlyする
		sobjectDataRollback(editRowIdx);
		// 指定行目情報は編集モードに変更
		purchaseList[editRowIdx].isReadOnly = false;
		// 2018/05/24 仕入画面で入庫処理を行う機能対応 WGCH BEGIN
		Id DetailId= purchaseList[editRowIdx].pur.id;
		list<PurchaseDetail__c> Detaillst =[select id,PurchaseRef__c from PurchaseDetail__c where PurchaseRef__c =: DetailId];
		if(!Detaillst.isEmpty()) purchaseList[editRowIdx].isDenpyoukeiflg = true;
		// 2018/10/29 新規仕入れ明細並べ不正修正 by zy BEGIN
		PurDetailInfo purInfo = getPurDetailInfo(new List<String>{purchaseList[editRowIdx].pur.id},false);
		// 2018/10/29 新規仕入れ明細並べ不正修正 by zy END
		purDetailLst = purInfo.purDetailAllLst;
		if (purDetailLst.size() < LIST_INPUT_DEF_ROWS) {
			Integer appendRsSize = LIST_INPUT_DEF_ROWS - PurchaseDetailLst.size();
			// 2行目まで設定を行う
			for (Integer i = 0; i < appendRsSize; i++) {
				purDetailLst.add(new PurDetailItem(new PurchaseDetail__c(), purDetailLst.size(), null));
			}
		}
		//2018/05/24 仕入画面で入庫処理を行う機能対応 WGCH END
		//purchaseList[editRowIdx].isDelete = false;
		// 2016/03/25 添付ファイル表示機能の対応 BEGIN
		// 最新のファイル名をアップロードファイル情報を取得する
		set<id> purIdSet = new set<id>();
		for (ItemInfo item : purchaseList ) {
			if (item.pur.id == null) continue;
			purIdSet.add(item.pur.id);
		}
		if (!purIdSet.isEmpty()) {
			map<id, attachment> fileMap = new map<id, attachment>();
			// 2016/08/15 Salesforceからアップロードファイルを仕入VFから参照できる機能対応	BEGIN
			for (Purchase__c pur : [select id, (Select Id, Name,LastModifiedDate From Attachments order by LastModifiedDate desc limit 1)  from Purchase__c where id in :purIdSet]) {
			// 2016/08/15 Salesforceからアップロードファイルを仕入VFから参照できる機能対応	END
				if (!pur.Attachments.isEmpty()) {
					attachment file = pur.Attachments[0];
					fileMap.put(pur.id, file);
				}
			}
			for (ItemInfo item : purchaseList ) {
				if (item.pur.id == null) continue;
				if (fileMap.containsKey(item.pur.id)) {
					attachment file = fileMap.get(item.pur.id);
					item.fileId = file.Id;
					item.fileNm = file.Name;
					// 2016/08/15 Salesforceからアップロードファイルを仕入VFから参照できる機能対応	BEGIN
					item.fileLastModifyDt = file.LastModifiedDate;
					// 2016/08/15 Salesforceからアップロードファイルを仕入VFから参照できる機能対応	END
				}
			}
			// 2016/08/15 Salesforceからアップロードファイルを仕入VFから参照できる機能対応	BEGIN
			linkRelContentDoc(purchaseList);
			// 2016/08/15 Salesforceからアップロードファイルを仕入VFから参照できる機能対応	END
		}
		// 2016/03/25 添付ファイル表示機能の対応 END
	}
	// 2016/08/15 Salesforceからアップロードファイルを仕入VFから参照できる機能対応	BEGIN
	public void linkRelContentDoc(List<ItemInfo> locPurchaseList) {
		set<id> purIdSet = new set<id>();
		for (ItemInfo item : locPurchaseList ) {
			if (item.pur.id == null) continue;
			purIdSet.add(item.pur.id);
		}
		if (purIdSet.isEmpty()) return;
		// 仕入ID→Documentの情報
		list<ContentDocumentLink> docLinks = [select ContentDocumentId, LinkedEntityId,ShareType from ContentDocumentLink where LinkedEntityId in :purIdSet for update];
		// map<リンクドキュメンID,仕入ID>
		map<id,id> docIdToPurIdMap = new map<id, id>();
		for (ContentDocumentLink docLink : docLinks) {
			docIdToPurIdMap.put(docLink.ContentDocumentId, docLink.LinkedEntityId);
		}
		// 組織の全てユーザに対して、ファイル参照可能に変更設定
		Id orgId = UserInfo.getOrganizationId();
		list<ContentDocumentLink> allOrgViewLink = [select ContentDocumentId, LinkedEntityId,ShareType from ContentDocumentLink where LinkedEntityId = :orgId and ContentDocumentId in :docIdToPurIdMap.keySet() for update];
		set<id> orgExistDocIdSet = new set<id>();
		for (ContentDocumentLink orgLink : allOrgViewLink) {
			orgExistDocIdSet.add(orgLink.ContentDocumentId);
		}
		list<ContentDocumentLink> insOrgLink = new list<ContentDocumentLink>();
		for (ContentDocumentLink docLink : docLinks) {
			if (!orgExistDocIdSet.contains(docLink.ContentDocumentId)) {
				insOrgLink.add(new ContentDocumentLink(
													LinkedEntityId = orgId, 
									            	ContentDocumentId=docLink.ContentDocumentId, 
									            	ShareType = 'V', 
									            	Visibility = 'AllUsers'));
			}
		}
		if (!insOrgLink.isEmpty()) insert insOrgLink;
		// map<仕入ID,ドキュメンID>
		map<id, ContentDocument> purLinkDocMap = new map<id, ContentDocument>();
		if (!docIdToPurIdMap.isEmpty()) {
			// 関連のドキュメン情報を取得する
			list<ContentDocument> linkDocs =[Select id,title,LastModifiedDate//(Select Id,ContentModifiedDate From ContentVersions where IsLatest = true Order by ContentModifiedDate desc limit 1) 
												From ContentDocument where id in :docIdToPurIdMap.keySet()
												Order By LastModifiedDate desc];
			//list<ContentVersion> linkDocs = [select id,Title,ContentModifiedDate,ContentDocumentId from ContentVersion where ContentDocumentId in :docIdToPurIdMap.keySet() And IsLatest = true Order by ContentModifiedDate desc];
			for (ContentDocument doc : linkDocs) {
				// 仕入ID
				Id purId = docIdToPurIdMap.get(doc.Id);
				// 該当仕入に既に最新のドキュメンを取得の場合、次のファイルは格納対象外
				if (purLinkDocMap.containsKey(purId)) continue;
				purLinkDocMap.put(purId, doc);
			}
		}
		for (ItemInfo item : locPurchaseList ) {
			if (item.pur.id == null) continue;
			ContentDocument docFile = purLinkDocMap.get(item.pur.id);
			if (docFile == null) continue;
			//list<ContentVersion> docVerFiles = docFile.ContentVersions;
			//if (docVerFiles.isEmpty()) continue;
			if (item.fileLastModifyDt != null && docFile != null) {
				if (item.fileLastModifyDt <= docFile.LastModifiedDate) {
					item.fileId = docFile.Id;
					item.fileNm = docFile.Title;
					item.fileUrl = fileDownloadUrl;
				}
			} else if (docFile != null) {
				item.fileId = docFile.Id;
				item.fileNm = docFile.Title;	
				item.fileUrl = fileDownloadUrl;
			}
		}
	}
	// 2016/08/15 Salesforceからアップロードファイルを仕入VFから参照できる機能対応	END
	// データ編集のRollback処理
	private void sobjectDataRollback(Integer existIdx) {
		for (ItemInfo item : purchaseList ) {
			// RollBack除外行
			if (item.rowIdx == existIdx) continue;
			item.isReadOnly = true;
			item.rollBackValue();
		}
	}
	// 指定行目は登録内容はRollbackする
	public void dataRollBack() {
		sobjectDataRollback(null);
		if (purchaseList.size() > 1) {
			purchaseList[0].isReadOnly = false;
		}
		//queryDetailLst(true);
	}
	// 削除対象IDリスト
	public String deleteRowIdxs{get; set;}
	// 削除処理を行う
	public void deleteData() {
		// 削除対象IDリスト取得する
		List<String> deleteRows = deleteRowIdxs.split(',');
		set<String> deleteIdsSet = new set<String>();
		// 削除処理を行う
		if (!deleteRows.isEmpty()) {
			deleteIdsSet.addAll(deleteRows);
			// 2018/03/07 Security Check BEGIN
			if (CommSecurityUtils.isDeleteable(Purchase__c.getSObjectType())) {
			// 2018/03/07 Security Check END
			delete [select id from Purchase__c where id in :deleteIdsSet];
			// 2018/05/24 仕入画面で入庫処理を行う機能対応 WGCH BEGIN
			delete [select id,PurchaseRef__c from PurchaseDetail__c where PurchaseRef__c in :deleteIdsSet];
			// 2018/05/24 仕入画面で入庫処理を行う機能対応 WGCH END
			// 2018/03/07 Security Check BEGIN
			}
			// 2018/03/07 Security Check END
			/*
			// 削除したIDは新規情報IDのリストから外す
			List<Id> locRepNewInsLst = new List<Id>();
			for (Id nwId : newInsRsIdLst) {
				if (!deleteIdsSet.contains(nwId)) {
					locRepNewInsLst.add(nwId);
				}
			}
			newInsRsIdLst.clear();
			// 削除済の最新情報IDをリストに格納する
			newInsRsIdLst.addAll(locRepNewInsLst);*/
		}
		// 最新情報を取得する
		queryDetailLst(true);
		// 2017/07/07 検索結果にFilter機能の追加 WGCH BEGIN
		deleteRowIdxs = '';
		// 2017/07/07 検索結果にFilter機能の追加 WGCH END
	}

	// *****************
	// バッチ実施処理を行う
	// *****************
	public void batchExceute(){
	// 2015/12/08 仕入振込データ出力は多パタン機能対応 BEGIN
		PopWinInfo winInfo = new PopWinInfo(currentShopCode);
		if(popWinInfoLst.size() > currentRowIdx){
			winInfo = popWinInfoLst[currentRowIdx];
		}
//system.debug(logginglevel.info,'currentRowIdx::' + currentRowIdx);
		if(winInfo != null){	
			// 買掛決済バッチを起動する
			if (winInfo.batchFromDateInput.Checkinday__c == null ||
				winInfo.batchToDateInput.Checkinday__c == null) {
				//仕入日開始日と終了日を入力してください.
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_040_0091));
				return;
			}
//system.debug(logginglevel.info,'filter::' + winInfo.filterBtn.filter);
			setPopInf(winInfo);
			// 起動条件：指定店舗コード、仕入開始日、仕入終了日、状態、振込指定日
			BulkProcessBankImportCsvBatch batch = new BulkProcessBankImportCsvBatch(winInfo.batchShopCode, winInfo.batchFromDateInput.Checkinday__c, winInfo.batchToDateInput.Checkinday__c,winInfo.currentBatchStatus,winInfo.queryInput.Checkinday__c,winInfo.isBatchFlag,winInfo.filterBtn.filter);
			// バッチサイズ：１０を指定する  
			ID batchprocessid = Database.executeBatch(batch,10);
			// 該当JOB処理状態をチェックする
			List<AsyncApexJob> apexJob = [select Status, TotalJobItems,ExtendedStatus
								from AsyncApexJob where id=:batchprocessid limit 1];
			if(!apexJob.isEmpty()){
				if(apexJob[0].status == 'Failed'){
					//バッチ起動エラーが発生しました.
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_040_0092 + CommUtils.nullToBlank(apexJob[0].ExtendedStatus)));
				}
			}
		}
		// 2015/12/08 仕入振込データ出力は多パタン機能対応 END
	}
	// *****************
	// 最新情報を検索する
	// *****************
	// 改ページ機能対応
    public PaginationUtil pageCtrl{get; private set;}
	//private ApexPages.StandardSetController ssc{get; private set;}
	private void queryDetailLst(boolean searchFlag){
		// 表示情報用変数リストを初期化する
		purchaseList = new List<ItemInfo>();
		// 合計金額(税込)を格納する
		depAmount = 0;
		// 入金情報リストを取得する
		// 2016/08/15 Salesforceからアップロードファイルを仕入VFから参照できる機能対応	BEGIN
		// 2017/07/07 検索結果にFilter機能の追加 WGCH BEGIN
		//String queryHeader = 'select id, Name, StatusLst__c, KamokuLst__c,ShopInfoRef__c,ShopInfoRef__r.ShopCode__c, PsalesproductRef__c,PsalesproductRef__r.name,Purchasesource__r.RoundType__c ,DenpyoukeiIncTax__c,Denpyoukei__c,Purchasesource__c,JinyaRevenue__c,JinyaRevenue__r.Salesday__c,Field1__c,PurchaseType__c,Memo__c,NoTaxFlg__c,(Select Id, Name,LastModifiedDate From Attachments order by LastModifiedDate desc limit 1)  from Purchase__c where JinyaRevenue__c != null ';
		// 2019/06/30 20190616.001.仕入画面、Apex heap size too largeエラーの対応 by zy BEGIN
		// String queryHeader = 'select id, Name, StatusLst__c, KamokuLst__c,ShopInfoRef__c,ShopInfoRef__r.ShopCode__c,PsalesproductRef__c,PsalesproductRef__r.name,Purchasesource__r.Name,Purchasesource__r.RoundType__c ,DenpyoukeiIncTax__c,Denpyoukei__c,Purchasesource__c,JinyaRevenue__c,JinyaRevenue__r.Salesday__c,JinyaRevenue__r.Name,Field1__c,PurchaseType__c,Memo__c,NoTaxFlg__c,(Select Id, Name,LastModifiedDate From Attachments order by LastModifiedDate desc limit 1)  from Purchase__c where JinyaRevenue__c != null ';
		String queryHeader = 'select id, Name, (Select Id, Name,LastModifiedDate From Attachments order by LastModifiedDate desc limit 1)  from Purchase__c where JinyaRevenue__c != null ';
		// 2019/06/30 20190616.001.仕入画面、Apex heap size too largeエラーの対応 by zy END
		// 2017/07/07 検索結果にFilter機能の追加 WGCH END
    	// 2016/08/15 Salesforceからアップロードファイルを仕入VFから参照できる機能対応	END
    	String groupHeader = 'select sum(DenpyoukeiIncTax__c) amount from Purchase__c where JinyaRevenue__c != null ';
    	// 新規情報IDが存在する場合、新規情報IDで検索を行う、改ページ情報設定する
    	String queryStr = '';
    	String groupStr = '';
    	// 新規情報で検索を行う
    	//if (!searchFlag) {
    	//	String contionStr = ' And Id in :newInsRsIdLst Order By LastModifiedDate desc limit :maxQueryNums ';
    	//	queryStr = queryHeader + contionStr;
    	//	groupStr = groupHeader + ' and id in :newInsRsIdLst ';
    	//} else {
	    	// 画面指定の条件により、既存情報を取得する
			String contionStr = '';
			// 2017/07/07 検索結果にFilter機能の追加 WGCH BEGIN
			set<String> purchaseTypeSet = new set<String>();
			set<String> kamokuLstSet = new set<String>();
			set<String> field1Set = new set<String>();
			set<String> purchasesourceSet = new set<String>();
			String filterSqlWhere = '';
			Decimal denpyoukeiAmount;
			Decimal denpyoukeiIncTaxAmount;
			if(!CommUtils.isBlank(filter.filterDataJson)){
				Map<String,List<String>> filterMap = (Map<String,List<String>>)JSON.deserializeStrict( filter.filterDataJson, Map<String,List<String>>.class);
				
				// 種別 => 过滤数据集Get => PurchaseType__c
				if (filterMap.containsKey('PurchaseType__c')){
					purchaseTypeSet.addAll(filterMap.get('PurchaseType__c'));
				}
				// 科目 => 过滤数据集Get => KamokuLst__c
				if (filterMap.containsKey('KamokuLst__c')){
					kamokuLstSet.addAll(filterMap.get('KamokuLst__c'));
				}
				// 仕入日 => 过滤数据集Get => Field1__c
				if (filterMap.containsKey('Field1__c')){
					field1Set.addAll(filterMap.get('Field1__c'));
					set<String> replaceSet = new set<String>();
					// 转成有效的数据格式
					for(String t : field1Set){
						if(CommUtils.isBlank(t)) continue;
						Date field1 = Date.parse(t);
						DateTime wkField1 = DateTime.newInstance(field1.year(),field1.month(),field1.day());
						replaceSet.add(wkField1.format('yyyyMMdd'));
					}
					field1Set = replaceSet;
				}
				// 仕入先 => 过滤数据集Get => Purchasesource__c
				if (filterMap.containsKey('Purchasesource__r.Name')){
					purchasesourceSet.addAll(filterMap.get('Purchasesource__r.Name'));
				}
				// 金額(税抜) => 过滤数据集Get => Denpyoukei__c
				if (filterMap.containsKey('Denpyoukei__c')){
					List<String> amountLst = filterMap.get('Denpyoukei__c');
					denpyoukeiAmount = CommUtils.nullToZero(amountLst[0]);
					// EQ  => [查询值==输入值]
					if (amountLst[1] == FILTERTYPE.EQ.name())
						filterSqlWhere += ' and Denpyoukei__c =: denpyoukeiAmount ';
					// NEQ => [查询值!=输入值]
					if (amountLst[1] == FILTERTYPE.NEQ.name())
						filterSqlWhere += ' and Denpyoukei__c !=: denpyoukeiAmount ';
					// GTE => [查询值>=输入值]
					if (amountLst[1] == FILTERTYPE.GTE.name())
						filterSqlWhere += ' and Denpyoukei__c >=: denpyoukeiAmount ';
					// GT  => [查询值> 输入值]
					if (amountLst[1] == FILTERTYPE.GT.name())
						filterSqlWhere += ' and Denpyoukei__c > : denpyoukeiAmount ';
					// LTE => [查询值<=输入值]
					if (amountLst[1] == FILTERTYPE.LTE.name())
						filterSqlWhere += ' and Denpyoukei__c <=: denpyoukeiAmount ';
					// LT  => [查询值< 输入值]
					if (amountLst[1] == FILTERTYPE.LT.name())
						filterSqlWhere += ' and Denpyoukei__c < : denpyoukeiAmount ';
				}
				// 金額(税込) => 过滤数据集Get => Denpyoukei__c
				if (filterMap.containsKey('DenpyoukeiIncTax__c')){
					List<String> amountLst = filterMap.get('DenpyoukeiIncTax__c');
					denpyoukeiIncTaxAmount = CommUtils.nullToZero(amountLst[0]);
					// EQ  => [查询值==输入值]
					if (amountLst[1] == FILTERTYPE.EQ.name())
						filterSqlWhere += ' and DenpyoukeiIncTax__c =: denpyoukeiIncTaxAmount ';
					// NEQ => [查询值!=输入值]
					if (amountLst[1] == FILTERTYPE.NEQ.name())
						filterSqlWhere += ' and DenpyoukeiIncTax__c !=: denpyoukeiIncTaxAmount ';
					// GTE => [查询值>=输入值]
					if (amountLst[1] == FILTERTYPE.GTE.name())
						filterSqlWhere += ' and DenpyoukeiIncTax__c >=: denpyoukeiIncTaxAmount ';
					// GT  => [查询值> 输入值]
					if (amountLst[1] == FILTERTYPE.GT.name())
						filterSqlWhere += ' and DenpyoukeiIncTax__c > : denpyoukeiIncTaxAmount ';
					// LTE => [查询值<=输入值]
					if (amountLst[1] == FILTERTYPE.LTE.name())
						filterSqlWhere += ' and DenpyoukeiIncTax__c <=: denpyoukeiIncTaxAmount ';
					// LT  => [查询值< 输入值]
					if (amountLst[1] == FILTERTYPE.LT.name())
						filterSqlWhere += ' and DenpyoukeiIncTax__c < : denpyoukeiIncTaxAmount ';
				}
				if(!purchaseTypeSet.isEmpty())
					filterSqlWhere += ' and PurchaseType__c in: purchaseTypeSet ';
				if(!kamokuLstSet.isEmpty())
					filterSqlWhere += ' and KamokuLst__c in: kamokuLstSet ';
				if(!field1Set.isEmpty())
					filterSqlWhere += ' and JinyaRevenue__r.Name in: field1Set ';
				if(!purchasesourceSet.isEmpty())
					filterSqlWhere += ' and Purchasesource__c in: purchasesourceSet ';
			}
			// 2017/07/07 検索結果にFilter機能の追加 WGCH END
			if (!CommUtils.isBlank(currentShopCode)) contionStr += ' and ShopInfoRef__r.ShopCode__c = :currentShopCode ';
	        // 仕入日開始期間FROMーTO
	        if(input.fromDateInput != null ){
	        	Date fromDate = input.fromDateInput.Checkinday__c;
	        	contionStr += ' and JinyaRevenue__r.Salesday__c >= :fromDate ';
	        }
	        if ( input.toDateInput != null) {
	        	Date toDate = input.toDateInput.Checkinday__c;
	        	contionStr += ' and JinyaRevenue__r.Salesday__c <= :toDate ';
	        }
	        // 仕入先条件
	        // 該当仕入のID項目を設定されていると、ID項目として、検索を行う
	        if(input.pur.Purchasesource__c != null){
	        	Id purChaseSource = input.pur.Purchasesource__c;
	        	contionStr += ' and Purchasesource__c = :purChaseSource ';
	        }
	    	// 残りレコード情報数を移動して、取得を行う
	    	// 最大１００００件まで検索、設定を行う
	        String orderStr = ' Order By Field1__c asc, Name desc limit :maxQueryNums ';
	        if (!searchFlag) orderStr = ' Order By LastModifiedDate desc limit :maxQueryNums ';
	        //pageCtrl = new PaginationUtil(oProductLst , 100);
	        // 2017/07/07 検索結果にFilter機能の追加 WGCH BEGIN
	        queryStr = queryHeader + contionStr + filterSqlWhere + orderStr;
	        groupStr = groupHeader + contionStr + filterSqlWhere;
	        // 2017/07/07 検索結果にFilter機能の追加 WGCH END
    	//}
//System.debug(loggingLevel.INFO, 'SQL1:::' + queryStr);
//System.debug(loggingLevel.INFO, 'SQL2:::' + groupStr);
		ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(Database.getQueryLocator(queryStr));
		pageCtrl = new PaginationUtil(ssc, pageSize);
		// 2017/07/07 検索結果にFilter機能の追加 WGCH BEGIN
		if(filter.sqlFlg){
			// 准备新Header数据源
			String sqlStr = 'Select Id Id,ShopInfoRef__r.ShopCode__c shopCode,PurchaseType__c PurchaseType__c,KamokuLst__c KamokuLst__c,Purchasesource__c Purchasesource__c,Field1__c Field1__c,JinyaRevenue__c JinyaRevenue__c,JinyaRevenue__r.Salesday__c JinyaSalesday,Purchasesource__r.Name PurchasesourceName from Purchase__c Where JinyaRevenue__c != null '
							+ contionStr
							+ ' group by Id,ShopInfoRef__r.ShopCode__c,PurchaseType__c,KamokuLst__c,Purchasesource__c,Field1__c,JinyaRevenue__c,JinyaRevenue__r.Salesday__c,Purchasesource__r.Name';
			List<AggregateResult> purchaseLst = DataBase.query(sqlStr);
			if(purchaseLst.size() > 0) filter.getFilterDataSource(purchaseLst);
		}
		// 2017/07/07 検索結果にFilter機能の追加 WGCH END
		// 指定のサイズとページを定義する
		convertDataToList(pageCtrl.records);
		// 合計金額を計算を行う
		Integer rsCount = 0;
		for (AggregateResult rs : DataBase.query(groupStr)) {
			depAmount += CommUtils.nullToZero(rs.get('amount'));
		}
		// 新規登録すると、新規登録情報のみ表示する.レコード数は10000
	}
	private void convertDataToList(List<Sobject> dataRs) {
		purchaseList.clear();
		//　1空白行を自動追加
		addDepInpLineAct();
		// 2019/06/30 20190616.001.仕入画面、Apex heap size too largeエラーの対応 by zy BEGIN
		// String queryHeader = '';
		// 2019/07/30 指定並べ順の更新 by zy BEGIN
		List<Id> purIdSet = new List<Id>();
		for (sObject s : dataRs) {
			purIdSet.add(s.Id);
		}
		// 2019/09/15 11.10月以降の仕入れ入力について税率が10%の商品と8%の商品入力をすることになると思うのですが、どうやって入力するのでしょうか by zy BEGIN
		Map<String,Purchase__c> purLst = new Map<String,Purchase__c>([select id, Name, StatusLst__c, KamokuLst__c,ShopInfoRef__c,ShopInfoRef__r.ShopCode__c,PsalesproductRef__c,PsalesproductRef__r.name,Purchasesource__r.Name,Purchasesource__r.RoundType__c ,DenpyoukeiIncTax__c,Denpyoukei__c,Purchasesource__c,JinyaRevenue__c,JinyaRevenue__r.Salesday__c,JinyaRevenue__r.Name,Field1__c,PurchaseType__c,Memo__c,NoTaxFlg__c,TaxRateCal__c,TaxRate__c,(Select Id, Name,LastModifiedDate From Attachments order by LastModifiedDate desc limit 1)  
		// 2019/09/15 11.10月以降の仕入れ入力について税率が10%の商品と8%の商品入力をすることになると思うのですが、どうやって入力するのでしょうか by zy END
			from Purchase__c where JinyaRevenue__c != null and id = :purIdSet]);
		for (String sId : purIdSet) {
			purchaseList.add(new ItemInfo((Purchase__c)purLst.get(sId), purchaseList.size(), null));
		}
		// 2019/07/30 指定並べ順の更新 by zy END
		// 2019/06/30 20190616.001.仕入画面、Apex heap size too largeエラーの対応 by zy END
		// JSON情報を作成する
		map<string,string> accPointKbnMap =new map<string, string>();
		for (ItemInfo item : purchaseList) {
			Id accId = item.pur.Purchasesource__c;
			if (accId == null) continue;
			if (accPointKbnMap.containsKey(accId)) continue;
			// 端末処理区分の転換設定
			if (!CommUtils.isBLank(item.pur.Purchasesource__r.RoundType__c)) {
				String roundType = Commutils.nullToBlank(item.pur.Purchasesource__r.RoundType__c);
				accPointKbnMap.put(CommUtils.nullToBlank(accId).mid(0,15),
					Commutils.nullToBlank(
						Commutils.getRoundTypeKbnByRoundMode(
							Commutils.pointRoundMode(roundType))));
			}
		}
		// 2016/08/15 Salesforceからアップロードファイルを仕入VFから参照できる機能対応	BEGIN
		linkRelContentDoc(purchaseList);
		// 2016/08/15 Salesforceからアップロードファイルを仕入VFから参照できる機能対応	END
		accPointKbnJson = JSON.serialize(accPointKbnMap);
	}
	// 各取引先の端数処理区分情報をJSONに格納する
	public string accPointKbnJson{get; private set;}
	// *****************
	// 新規登録一行目を追加「仕入」
	// *****************
	private void addDepInpLineAct() {
		Purchase__c purchase = new Purchase__c();
		// Cookieからレイアウトモードを取得する

	   	CookieInf cookInf = getCookieInf();
	   	if(cookInf.purcase != null){
	   		purchase = cookInf.purcase;
	   	}
		// 新規入力行目を作成する
		purchaseList.add(new ItemInfo(purchase, purchaseList.size(),currentShopCode));
	}
	// **************** COOKIE ***************
	// 2015/09/15 前回選択値を記憶する BEGIN
    private CookieInf getCookieInf () {
    	Purchase__c purcase = new Purchase__c();
    	Cookie purchaseCookie = ApexPages.currentPage().getCookies().get('_PurchaseManageInput_cookie_purchase');
    	if(purchaseCookie != null){
    		//System.debug(logginglevel.info,'Purchase__c::::' + purchaseCookie.getValue());
    		purcase = (Purchase__c)JSON.deserialize(purchaseCookie.getValue(), Purchase__c.class);
    		purcase.id = null;

    	}
    	Cookie purchaseMemoCookie = ApexPages.currentPage().getCookies().get('_PurchaseManageInput_cookie_purchase_memo');
    	if(purchaseMemoCookie != null){
    		purcase.Memo__c = purchaseMemoCookie.getValue();
    	}
    	purcase.ShopInfoRef__c = null;
    	/*
		Cookie purchaseCookieStatus = ApexPages.currentPage().getCookies().get('_PurchaseManageInput_cookie_purchase.StatusLst__c');
		Cookie purchaseCookieKamoku = ApexPages.currentPage().getCookies().get('_PurchaseManageInput_cookie_purchase.KamokuLst__c');
		Cookie purchaseCookiePsalesproduct = ApexPages.currentPage().getCookies().get('_PurchaseManageInput_cookie_purchase.PsalesproductRef__c');
		Cookie purchaseCookieDenpyoukeiIncTax = ApexPages.currentPage().getCookies().get('_PurchaseManageInput_cookie_purchase.DenpyoukeiIncTax__c');
		Cookie purchaseCookieDenpyoukei = ApexPages.currentPage().getCookies().get('_PurchaseManageInput_cookie_purchase.Denpyoukei__c');
		Cookie purchaseCookiePurchasesource = ApexPages.currentPage().getCookies().get('_PurchaseManageInput_cookie_purchase.Purchasesource__c');
		Cookie purchaseCookieJinyaRevenue = ApexPages.currentPage().getCookies().get('_PurchaseManageInput_cookie_purchase.JinyaRevenue__c');
		Cookie purchaseCookiePurchaseType = ApexPages.currentPage().getCookies().get('_PurchaseManageInput_cookie_purchase.PurchaseType__c');
		Cookie purchaseCookieMemo = ApexPages.currentPage().getCookies().get('_PurchaseManageInput_cookie_purchase.Memo__c');
		Cookie purchaseCookieShopInfo = ApexPages.currentPage().getCookies().get('_PurchaseManageInput_cookie_purchase.ShopInfoRef__c');
		if(purchaseCookieStatus != null) purcase.StatusLst__c = purchaseCookieStatus.getValue();
		if(purchaseCookieKamoku != null) purcase.KamokuLst__c = purchaseCookieKamoku.getValue();
		if(purchaseCookiePsalesproduct != null) purcase.PsalesproductRef__c = purchaseCookiePsalesproduct.getValue();
		if(purchaseCookieDenpyoukeiIncTax != null) purcase.DenpyoukeiIncTax__c = Decimal.valueOf(purchaseCookieDenpyoukeiIncTax.getValue());
		if(purchaseCookieDenpyoukei != null) purcase.Denpyoukei__c = Decimal.valueOf(purchaseCookieDenpyoukei.getValue());
		if(purchaseCookiePurchasesource != null) purcase.Purchasesource__c = purchaseCookiePurchasesource.getValue();
		if(purchaseCookieJinyaRevenue != null) purcase.JinyaRevenue__c = purchaseCookieJinyaRevenue.getValue();
		if(purchaseCookiePurchaseType != null) purcase.PurchaseType__c = purchaseCookiePurchaseType.getValue();
		if(purchaseCookieMemo != null) purcase.Memo__c = purchaseCookieMemo.getValue();
		if(purchaseCookieShopInfo != null) purcase.ShopInfoRef__c = purchaseCookieShopInfo.getValue();
		*/
		CookieInf inf = new CookieInf(purcase);
        return inf;
    }
    private void setCookieInf (CookieInf inf) {
    	String memo = CommUtils.nullToBlank( inf.purcase.Memo__c);
    	inf.purcase.Memo__c = '';
    	 // 予定表情報のＪＳＯＮを作成する
        String purString = JSON.serialize(inf.purcase);
		// 画面最後利用する画面モードはCookiesに維持する
		/*
		Cookie purchaseCookieStatus = new Cookie('_PurchaseManageInput_cookie_purchase.StatusLst__c', inf.purcase.StatusLst__c, null, -1, true);
		Cookie purchaseCookieKamoku = new Cookie('_PurchaseManageInput_cookie_purchase.KamokuLst__c', inf.purcase.KamokuLst__c, null, -1, true);
		Cookie purchaseCookiePsalesproduct = new Cookie('_PurchaseManageInput_cookie_purchase.PsalesproductRef__c', inf.purcase.PsalesproductRef__c, null, -1, true);
		Cookie purchaseCookieDenpyoukeiIncTax = new Cookie('_PurchaseManageInput_cookie_purchase.DenpyoukeiIncTax__c', String.valueOf(inf.purcase.DenpyoukeiIncTax__c), null, -1, true);
		Cookie purchaseCookieDenpyoukei = new Cookie('_PurchaseManageInput_cookie_purchase.Denpyoukei__c', String.valueOf(inf.purcase.Denpyoukei__c), null, -1, true);
		Cookie purchaseCookiePurchasesource = new Cookie('_PurchaseManageInput_cookie_purchase.Purchasesource__c', inf.purcase.Purchasesource__c, null, -1, true);
		Cookie purchaseCookieJinyaRevenue = new Cookie('_PurchaseManageInput_cookie_purchase.JinyaRevenue__c', inf.purcase.JinyaRevenue__c, null, -1, true);
		Cookie purchaseCookiePurchaseType = new Cookie('_PurchaseManageInput_cookie_purchase.PurchaseType__c', inf.purcase.PurchaseType__c, null, -1, true);
		Cookie purchaseCookieMemo = new Cookie('_PurchaseManageInput_cookie_purchase.Memo__c', inf.purcase.Memo__c, null, -1, true);
		Cookie purchaseCookieShopInfo = new Cookie('_PurchaseManageInput_cookie_purchase.ShopInfoRef__c', inf.purcase.ShopInfoRef__c, null, -1, true);
		*/
		Cookie purchaseCookieShopInfo = new Cookie('_PurchaseManageInput_cookie_purchase', purString , null, -1, true);
		Cookie purchaseCookieMemoInfo = new Cookie('_PurchaseManageInput_cookie_purchase_memo', memo.mid(0,255) , null, -1, true);
		ApexPages.currentPage().setCookies(new Cookie[]{purchaseCookieShopInfo,purchaseCookieMemoInfo});
														/*
														purchaseCookieStatus
														,purchaseCookieKamoku,purchaseCookiePsalesproduct
														,purchaseCookieDenpyoukeiIncTax,purchaseCookieDenpyoukei
														,purchaseCookiePurchasesource,purchaseCookieJinyaRevenue
														,purchaseCookiePurchaseType,purchaseCookieMemo,purchaseCookieShopInfo});
														*/
    }
    // 2015/12/08 仕入振込データ出力は多パタン機能対応 BEGIN
    private void setPopInf(PopWinInfo winInfo){
    	String startDt = winInfo.batchFromDateInput.Checkinday__c.format();
    	String endDate = winInfo.batchToDateInput.Checkinday__c.format();
    	String queryDt = winInfo.queryInput.Checkinday__c.format();
    	String batch = String.valueOf(winInfo.isBatchFlag);
    	String cookieName = CommUtils.isBlank( winInfo.filterBtn.cookieName) ? winInfo.filterBtn.btnLabel : winInfo.filterBtn.cookieName; 
		String cookieNamePrix = '_PurchaseManageInput_cookie_popwin_' + cookieName;
    	Cookie shopCode = new Cookie(cookieNamePrix + '_batchShopCode', winInfo.batchShopCode , null, -1, true);
    	Cookie batchStatus = new Cookie(cookieNamePrix + '_currentBatchStatus', winInfo.currentBatchStatus , null, -1, true);
    	Cookie queryDtCoo = new Cookie(cookieNamePrix + '_queryDate', queryDt , null, -1, true);
    	Cookie startDtCoo = new Cookie(cookieNamePrix + '_startDate', startDt , null, -1, true);
    	Cookie endDateCoo = new Cookie(cookieNamePrix + '_endDate', endDate , null, -1, true);
    	Cookie batchFlagCoo = new Cookie(cookieNamePrix + '_batchFlag', batch , null, -1, true);
    	ApexPages.currentPage().setCookies(new Cookie[]{shopCode,batchStatus,queryDtCoo,startDtCoo,endDateCoo,batchFlagCoo});
    }
    // 2015/12/08 仕入振込データ出力は多パタン機能対応 END
    @remoteAction
    public static AccountInf getAccount(String accountId,String accountNm){
    	AccountInf info = new AccountInf();
    	List<Account> accounts = [Select name,Id ,RoundType__c from Account where id = :accountId or name = :accountNm limit 3];
    	RoundingMode roundMode = CommUtils.pointRoundMode();
    	info = checkAccount(accountId,accountNm);
    	// 2017/06/28 既存不具合改修 BEGIN
    	//if(CommUtils.isBlank(info.errorMsg))
    	//info.acc.RoundType__c = String.valueOf(CommUtils.getRoundTypeKbnByRoundMode(roundMode));
    	if(CommUtils.isBlank(info.errorMsg)) {
    	    if(!CommUtils.isBlank(info.acc.RoundType__c)) {
    	        roundMode = CommUtils.pointRoundMode(info.acc.RoundType__c);
    	    }
    	    info.acc.RoundType__c = CommUtils.nullToBlank(CommUtils.getRoundTypeKbnByRoundMode(roundMode));
    	}
    	// 2017/06/28 既存不具合改修 END
    		
    	return info;
    }
    private static AccountInf checkAccount(String accId,String accNm){
    	List<Account> accounts = [Select name,Id ,RoundType__c from Account where id = :accId or name = :accNm limit 3];
    	List<Account> checkLst = new List<Account>();
    	AccountInf info = new AccountInf();
    	if(!accounts.isEmpty()){
    		for(Account acc : accounts){
	    		if(!CommUtils.isBlank(accId) && acc.id == Id.valueOf(accId)){
	    			if(!CommUtils.isBlank(accNm) && accNm == acc.name){
	    				info.acc = acc;
	    				return info;
	    			}
	    		}else if(acc.name == accNm) checkLst.add(acc);
	    	}
    	}
    	if(checkLst.size() == 1){
    		info.acc = checkLst[0];
    	}else if(checkLst.size() > 1)
    		//複数の項目が見つかりました。アイコンをクリックして検索結果を絞り込んでください。
    		info.errorMsg = Label.MSG_040_0093;
    	else if(!CommUtils.isBlank(accNm))
    		//該当するデータがありません。
    		info.errorMsg = Label.MSG_040_0094;
    	return info;
    }
    public class AccountInf{
    	public Account acc;
    	public String errorMsg;
    	public AccountInf(){
    		acc = new Account();
    		errorMsg = '';
    	}
    }
    public class CookieInf {
    	public Purchase__c purcase{get; set;}
    	public CookieInf(){}
    	public CookieInf(Purchase__c pur) {
    		purcase = pur;
    	}
    }
	public class InputForm {
		public Purchase__c 	pur{get; private set;}
		public BookingTimeTable__c fromDateInput{get; private set;}
		public BookingTimeTable__c toDateInput{get; private set;}
		public boolean isGroupFlag{get;set;}
		public InputForm () {
			pur = new Purchase__c();
			fromDateInput = new BookingTimeTable__c(Checkinday__c = Date.today());
			toDateInput = new BookingTimeTable__c(Checkinday__c = Date.today());
			isGroupFlag = false;
		}
	}
	public class ItemInfo {
		public ItemInfo() {
			pur = new Purchase__c();
			pRoundType = CommUtils.pointRoundMode(CommBaseCtrl.getRoundType());
			salesDt = system.today();
		}
		public ItemInfo(Purchase__c pDep, Integer pRowIdx,String pShopCode) {
			// 2018/05/24 仕入画面で入庫処理を行う機能対応 WGCH BEGIN
			isDenpyoukeiflg = false;
			// 2018/05/24 仕入画面で入庫処理を行う機能対応 WGCH END
			pur = pDep;
			pRoundType = CommUtils.pointRoundMode(CommBaseCtrl.getRoundType());
			if (pur.id != null) {
				// 読み込み専用
				isReadOnly = true;
				// 既存情報を格納する
				cloneObj = pur.clone(true, true);
				// 仕入日設定を行う
				salesDate = new BookingTimeTable__c(Checkinday__c = pur.Field1__c);
				//
				processNo = pur.Name;
			} else {
				isReadOnly = false;
				salesDate = new BookingTimeTable__c(Checkinday__c = Date.today());
//System.debug(logginglevel.info,'----Salesday__c' + pur.JinyaRevenue__r);
				if(pur.JinyaRevenue__r.name != null){
				 	salesDate.Checkinday__c = CommUtils.stringToDate(pur.JinyaRevenue__r.name);
				}
				if(pur.ShopInfoRef__c == null) pur.ShopInfoRef__r = new ShopInformation__c(ShopCode__c = pShopCode) ;

			}

			if (!CommUtils.isBLank(pur.Purchasesource__r.RoundType__c)) {
				pRoundType = CommUtils.pointRoundMode(pur.Purchasesource__r.RoundType__c);
			}
			denpyokei = denpyokeiIncTax = 0;
			if(pur.Denpyoukei__c != null && pur.Denpyoukei__c != 0)
				denpyokei = CommUtils.RoundProcess(pur.Denpyoukei__c, CommUtils.getTaxPointLen(), pRoundType);
			if(pur.DenpyoukeiIncTax__c != null && pur.DenpyoukeiIncTax__c != 0)
				denpyokeiIncTax = CommUtils.RoundProcess(pur.DenpyoukeiIncTax__c, CommUtils.getTaxPointLen(), pRoundType);
			rowIdx = pRowIdx;
			// 2016/03/25 添付ファイル表示機能の対応 BEGIN
			List<Attachment> files = pDep.Attachments;
			if (!files.isEmpty()) {
				fileId = files[0].Id;
				fileNm = files[0].Name;
				// 2016/08/15 Salesforceからアップロードファイルを仕入VFから参照できる機能対応	BEGIN
				fileLastModifyDt = files[0].LastModifiedDate;
				// 2016/08/15 Salesforceからアップロードファイルを仕入VFから参照できる機能対応	END
			}
			// 2016/03/25 添付ファイル表示機能の対応 END
			// 2019/09/15 11.10月以降の仕入れ入力について税率が10%の商品と8%の商品入力をすることになると思うのですが、どうやって入力するのでしょうか by zy BEGIN
			if (pDep.TaxRate__c != null) rateTax = CommUtils.nullToBlank(CommUtils.numberFormat(pDep.TaxRate__c));
			else rateTax = CommUtils.nullToBlank(CommUtils.numberFormat(pDep.TaxRateCal__c));
			// 2019/09/15 11.10月以降の仕入れ入力について税率が10%の商品と8%の商品入力をすることになると思うのですが、どうやって入力するのでしょうか by zy END
		}

		public void rollBackValue() {
			if (cloneObj != null && cloneObj.Id != null) pur = cloneObj.clone(true, true);
		}
		public Boolean isPurInsert () {
			return (pur != null && pur.Id == null);
		}
		// 登録用情報の格納
		public Purchase__c pur{get; set;}
		public BookingTimeTable__c salesDate{get;set;}
		public Date salesDt{get;set;}
		public String processNo{get; private set;}
		//public String createDate{get; private set;}
		//public String createUser{get; private set;}

		public Boolean isReadOnly{get; set;}
		// 2018/05/24 仕入画面で入庫処理を行う機能対応 WGCH BEGIN
		public Boolean isDenpyoukeiflg{get; set;}
		// 2018/05/24 仕入画面で入庫処理を行う機能対応 WGCH END
		public Integer rowIdx{get; private set;}
		public String purchasesourceName{get;set;}
		public String productNm{get;set;}
		//public Boolean isDelete{get; set;}	//
		public String shopCode{get;set;}	// 指定店舗コード
		// 小数金額四捨五入設定する
		private System.RoundingMode pRoundType;	// システム標準端数処理区分
		// Clone Object
		private Purchase__c cloneObj;
		//
		public decimal denpyokei{get;set;}
		public decimal denpyokeiIncTax{get;set;}
		// 2016/03/25 添付ファイル表示機能の対応 BEGIN
		public String fileId{get; set;}
		public String fileNm{get; set;}
		// 2016/03/25 添付ファイル表示機能の対応 END
		// 2016/08/15 Salesforceからアップロードファイルを仕入VFから参照できる機能対応	BEGIN
		public String fileUrl{get; set;}
		public DateTime fileLastModifyDt{get; set;}
		// 2016/08/15 Salesforceからアップロードファイルを仕入VFから参照できる機能対応	END
		// 2019/09/15 11.10月以降の仕入れ入力について税率が10%の商品と8%の商品入力をすることになると思うのですが、どうやって入力するのでしょうか by zy BEGIN
		public String rateTax{get;set;}
		// 2019/09/15 11.10月以降の仕入れ入力について税率が10%の商品と8%の商品入力をすることになると思うのですが、どうやって入力するのでしょうか by zy END
	}
	// 2015/12/08 仕入振込データ出力は多パタン機能対応 BEGIN
	public class PopwinInfo{
		public BookingTimeTable__c batchFromDateInput{get; private set;}
		public BookingTimeTable__c batchToDateInput{get; private set;}
		public BookingTimeTable__c queryInput{get;set;}
		public integer rowIdx{get;set;}
		public boolean isBatchFlag{get;set;}
		public String batchShopCode{get;set;}		// バッチ起動指定の店舗コード
		public String currentBatchStatus{get;set;}	// バッチ起動後のステータス
		public String prefixName{get;set;}
		public AccountingSyncBatchHelp.FilterBtn filterBtn{get;set;}
		public PopwinInfo(String shopCode){
			batchShopCode = shopCode; 
			filterBtn = new AccountingSyncBatchHelp.FilterBtn();
			batchFromDateInput = new BookingTimeTable__c(Checkinday__c = Date.today());
			batchToDateInput = new BookingTimeTable__c(Checkinday__c = Date.today());
			queryInput = new BookingTimeTable__c(Checkinday__c = Date.today());
		}
	}
	// 2015/12/08 仕入振込データ出力は多パタン機能対応 END
	// 2016/04/21 課税対象外自動設定機能対応 BEGIN
	public void initPhashTypeKamokuInfo() {
		// XML NAME
        String docName = 'SyncFieldConvertConfig';
        List<Dom.XmlNode> topNodeXmlList = CommXmlUtils.getAllTopXmlNode(docName);
        
        // 会計科目SEQ＃情報を格納する
        // map<shopcode, map<種別名,会計科目SEQ>>
   	 	map<string, map<string,string>> shopTypenameToSeqMap = new map<string, map<string,string>>();
   	 	// 店舗別の非課税判断キーワード格納
   	 	//map<string, string> shopNoTaxKbnKeyMap = new map<string, string>();
   	 	map<string, set<string>> shopNoTaxKbnKeyMap = new map<string, set<string>>();
   	 	// 店舗別の非課税種別リストを格納する
   	 	map<string, list<string>> xmlShopNotaxTypeMap = new map<string, list<string>>();
   	 	map<string, list<string>> xmlShopNotaxTypeRightMap = new map<string, list<string>>();
        // 全て店舗のて定義情報を取得する
        for (Dom.XmlNode shopRoot : topNodeXmlList) {
			// 店舗コード
	   	 	Dom.XmlNode shopCodeField =  shopRoot.getChildElement('SHOPCODE', null);
			String shopcode = CommUtils.nullToBlank(shopCodeField.getText());
        	// Frist定義情報はデフォルト定義情報
        	if (xmlDefaultSetShopCode == null) xmlDefaultSetShopCode = shopcode;
        	// 各店舗に格納情報の初期化
			xmlShopNotaxTypeMap.put(shopcode, new list<string>());
			xmlShopNotaxTypeRightMap.put(shopcode, new list<string>());
			shopNoTaxKbnKeyMap.put(shopcode, new set<string>{'非課税'});
			shopTypenameToSeqMap.put(shopcode, new map<string, string>());
			
			// 仕入種別科目関連の会計科目定義情報
			Dom.XmlNode nodePurchase =  shopRoot.getChildElement('PURCHASE', null);
	   	 	if (nodePurchase != null) {
	   	 		// 種別：借方
	   	 	    Dom.XmlNode purchaseInput = nodePurchase.getChildElement('P_TYPE', null);
	   	 	    if (purchaseInput != null) {
	   	 	    	// 非課税判断キーワード
	   	 	    	String noTaxKbnKey = CommUtils.nullToBlank(purchaseInput.getAttribute('NOTAXKBN_KEY',null));
	   	 	    	if (!CommUtils.isBlank(noTaxKbnKey)) {
	   	 	    		set<string> noTaxKbnKeySet = shopNoTaxKbnKeyMap.get(shopcode);
	   	 	    		noTaxKbnKeySet.clear();
	   	 	    		list<string> noTaxKbnKeyLst = noTaxKbnKey.split(',');
	   	 	    		for (String key : noTaxKbnKeyLst) {
	   	 	    			noTaxKbnKeySet.add(CommUtils.nullToBlank(key));
	   	 	    		}
	   	 	    	}
	   	 	    	for (Dom.XmlNode c1:purchaseInput.getChildElements() ) {
	   	 	    		Dom.XmlNode p1tField = c1.getChildElement('TYPENAME', null);
	   	 	    		Dom.XmlNode p1KField = c1.getChildElement('KANJOCODE', null);
	   	 	    		if (p1tField == null || p1KField == null) continue;
	   	 	    		String p1t = CommUtils.nullToBlank(p1tField.getText());
	   	 	    		String p1K = CommUtils.nullToBlank(p1KField.getText()).deleteWhitespace();
	   	 	    		// 店舗単位に種別と会計科目のSEQマッピング定義情報
	   	 	    		map<string, string> typeToSeqMap = shopTypenameToSeqMap.get(shopcode);
	   	 	    		typeToSeqMap.put(p1t,p1K);
	   	 	    		// 該当SEQ対応の店舗コード
	   	 	    		//kanjoSeqToshopCodeMap.get(shopcode).add(p1K);
	   	 	    	}
	   	 	    }
	   	 		//2016/07/15   科目   wgch BEGIN
	   	 		// 仕入の科目項目の会計科目のマッピング 
	   	 		Dom.XmlNode purchaseKamoku = nodePurchase.getChildElement('P_KAMOKU', null);
				if (purchaseKamoku != null) {
	   	 	    	for (Dom.XmlNode c1:purchaseKamoku.getChildElements() ) {
	   	 	    		Dom.XmlNode p1tField = c1.getChildElement('TYPENAME', null);
	   	 	    		Dom.XmlNode p1KField = c1.getChildElement('KANJOCODE', null);
	   	 	    		if (p1tField == null || p1KField == null) continue;
	   	 	    		String p1t = CommUtils.nullToBlank(p1tField.getText());
	   	 	    		String p1K = CommUtils.nullToBlank(p1KField.getText()).deleteWhitespace();
	   	 	    		// 店舗単位に種別と会計科目のSEQマッピング定義情報
	   	 	    		map<string, string> typeToSeqMap = shopTypenameToSeqMap.get(shopcode);
	   	 	    		typeToSeqMap.put(p1t,p1K);
	   	 	    		// 該当SEQ対応の店舗コード
	   	 	    		//kanjoSeqToshopCodeMap.get(shopcode).add(p1K);
	   	 	    	 }
				}
				//2016/07/15   科目   wgch END
	   	 	}
        }
	   	 	// 会計科目定義情報が存在する場合
   	 	    if (!shopTypenameToSeqMap.isEmpty()) {
   	 	    	// 全て定義している会計科目SEQ情報を取得する
   	 	    	set<string> kanjoSeqSet = new set<string>();//new set<string>(typenameToLanjoSeqMap.values());
   	 	    	for (map<string, string> typeToSeqMap : shopTypenameToSeqMap.values()) {
   	 	    		kanjoSeqSet.addAll(typeToSeqMap.values());
   	 	    	}
   	 	    	// 会計科目情報を格納用map<科目科目SEQ, 会計科目>
   	 	    	map<string, KanjoKamoku__c> kanjokamokuMap = new map<string, KanjoKamoku__c>();
   	 	    	// 会計科目マスタから定義情報を取得する
   	 	    	list<KanjoKamoku__c> kanjoKamokuLst = [select id, Kanjocode__c, DebitTaxKbn__c, CreditTaxKbn__c from KanjoKamoku__c where Kanjocode__c in :kanjoSeqSet ];
   	 	    	for (KanjoKamoku__c kanjoInf : kanjoKamokuLst) {
   	 	    		// 会計科目定義情報をSEQ#単位で格納する
   	 	    		kanjokamokuMap.put(kanjoInf.Kanjocode__c, kanjoInf);
   	 	    	}
   	 	    	// 各店舗の非課税対象種別情報を設定する
   	 	    	for (String shopcode : shopTypenameToSeqMap.keySet()) {
   	 	    		map<string, string> typeToSeqMap = shopTypenameToSeqMap.get(shopcode);
   	 	    		// 該当店舗の非課税判別キーワードを取得する
   	 	    		//String noTaxKbnKey = shopNoTaxKbnKeyMap.get(shopcode);
   	 	    		set<string> noTaxKbnKey = shopNoTaxKbnKeyMap.get(shopcode);
   	 	    		// 該当店舗の種別→会計科目関連情報を設定する
   	 	    		for (string typename : typeToSeqMap.keySet()) {
   	 	    			// 会計科目のSEQ情報を取得
   	 	    			String kanjoSeq = typeToSeqMap.get(typename);
   	 	    			// 該当SEQにより、会計会計定義情報を取得
   	 	    			if (kanjokamokuMap.containsKey(kanjoSeq)) {
   	 	    				// 会計科目情報を取得
   	 	    				KanjoKamoku__c kanjoInf = kanjokamokuMap.get(kanjoSeq);
   	 	    				//if (kanjoInf.DebitTaxKbn__c != noTaxKbnKey) continue;
   	 	    				if (noTaxKbnKey.contains(kanjoInf.DebitTaxKbn__c)) {
   	 	    					// 該当店舗に関連の非課税種別定義情報を格納する
   	 	    					xmlShopNotaxTypeMap.get(shopcode).add(typename);
   	 	    				}
   	 	    				if (noTaxKbnKey.contains(kanjoInf.CreditTaxKbn__c)) {
   	 	    					xmlShopNotaxTypeRightMap.get(shopcode).add(typename);
   	 	    				}
   	 	    			}
   	 	    		}
   	 	    	}
   	 	    }
   	 	    if (!xmlShopNotaxTypeMap.isEmpty()) xmlShopNotaxTypeMapJson = JSON.serialize(xmlShopNotaxTypeMap);
   	 	    if (!xmlShopNotaxTypeRightMap.isEmpty()) xmlShopNotaxTypeRightMapJson = JSON.serialize(xmlShopNotaxTypeRightMap);
	}
	public string xmlShopNotaxTypeMapJson{get; private set;}
	public string xmlShopNotaxTypeRightMapJson{get; private set;}
	public string xmlDefaultSetShopCode{get; private set;}
	// 2016/04/21 課税対象外自動設定機能対応 END
	// 2017/07/07 検索結果にFilter機能の追加 WGCH BEGIN
	private void getInitFilterDt(){
		// 数据源重置
		filter = new FilterDataSource();
	}	
	public class FilterDataSource{
		public FilterDataSource(){
			sqlFlg = true;
			filterDataJson = '';
			purchaseTypeData = depKamokuData = salesDateData = purchaseSourceData = JSON.serialize(new List<Map<String,String>>());
			
			// 種別数据集
			purchaseTypeLst = new List<Map<String,String>>();
			// 科目数据集
			depKamokuLst = new List<Map<String,String>>();
			// 仕入日数据集
			salesDateLst = new List<Map<String,String>>();
			// 仕入先数据集
			purchaseSourceLst = new List<Map<String,String>>();
			
			// 種別 => 过滤Set
			purchaseTypeSet = new Set<String>();
			// 科目 => 过滤Set
			depKamokuSet = new Set<String>();
			// 仕入日 => 过滤Set
			salesDateSet = new Set<String>();
			// 仕入先 => 过滤Set
			purchaseSourceSet = new Set<String>();
		}
		private void getFilterDataSource(List<AggregateResult> purchaseLst){
			sqlFlg = false;
			for(AggregateResult aggRes : purchaseLst){
				if(aggRes.get('Id') != null){
					// 種別 => 数据
					String purchaseTypeStr = CommUtils.nullToBlank(aggRes.get('PurchaseType__c'));
					// 科目 => 数据
					String depKamokuStr = CommUtils.nullToBlank(aggRes.get('KamokuLst__c'));
					// 仕入日 => 数据
					Date field1 = CommUtils.objectToDate(aggRes.get('Field1__c'));
					String salesDateStr = CommUtils.nullToBlank(field1 == null ? '' : field1.format());
					// 仕入先 => 数据
					String purchaseSourceStr = CommUtils.nullToBlank(aggRes.get('PurchasesourceName'));
					// 仕入先Id => 数据
					String purchaseSourceIdStr = CommUtils.nullToBlank(aggRes.get('Purchasesource__c'));
					// 種別 => 插入有效数据 => 过滤重复值
					if(!purchaseTypeSet.contains(purchaseTypeStr) && !CommUtils.isBlank(purchaseTypeStr)){
						// 種別 => 插入到过滤Set中
						purchaseTypeSet.add(purchaseTypeStr);
						// 種別 => 数据集Lst
						purchaseTypeLst.add(new Map<String,String>{'purchaseType' => purchaseTypeStr});
					}
					// 科目 => 插入有效数据 => 过滤重复值
					if(!depKamokuSet.contains(depKamokuStr) && !CommUtils.isBlank(depKamokuStr)){
						// 科目 => 插入到过滤Set中
						depKamokuSet.add(depKamokuStr);
						// 科目 => 数据集Lst
						depKamokuLst.add(new Map<String,String>{'depKamoku' => depKamokuStr});
					}
					// 仕入日 => 插入有效数据 => 过滤重复值
					if(!salesDateSet.contains(salesDateStr) && !CommUtils.isBlank(salesDateStr)){
						// 仕入日 => 插入到过滤Set中
						salesDateSet.add(salesDateStr);
						// 仕入日 => 数据集Lst
						salesDateLst.add(new Map<String,String>{'SalesDate' => salesDateStr});
					}
					// 仕入先 => 插入有效数据 => 过滤重复值
					if(!purchaseSourceSet.contains(purchaseSourceIdStr) && !CommUtils.isBlank(purchaseSourceIdStr)){
						// 仕入先 => 插入到过滤Set中
						purchaseSourceSet.add(purchaseSourceIdStr);
						// 仕入先 => 数据集Lst
						purchaseSourceLst.add(new Map<String,String>{'purchaseSource' => purchaseSourceStr,'purchaseSourceId' => purchaseSourceIdStr});
					}
				}
			}
			// 種別 插入有效数据 => Json
			purchaseTypeData = JSON.serialize(purchaseTypeLst);
			// 科目 插入有效数据 => Json
			depKamokuData = JSON.serialize(depKamokuLst);
			// 仕入日 插入有效数据 => Json
			salesDateData = JSON.serialize(salesDateLst);
			// 仕入先 插入有效数据 => Json
			purchaseSourceData = JSON.serialize(purchaseSourceLst);
		}
		// 種別数据集
		public List<Map<String,String>> purchaseTypeLst{get;set;}
		// 科目数据集
		public List<Map<String,String>> depKamokuLst{get;set;}
		// 仕入日数据集
		public List<Map<String,String>> salesDateLst{get;set;}
		// 仕入先数据集
		public List<Map<String,String>> purchaseSourceLst{get;set;}
		
		// 種別 => 过滤Set
		public Set<String> purchaseTypeSet{get;set;}
		// 科目 => 过滤Set
		public Set<String> depKamokuSet{get;set;}
		// 仕入日 => 过滤Set
		public Set<String> salesDateSet{get;set;}
		// 仕入先 => 过滤Set
		public Set<String> purchaseSourceSet{get;set;}
		
		// 種別数据集 sobject => PurchaseType__c
		public String purchaseTypeData{get;set;}
		// 科目数据集 sobject => KamokuLst__c
		public String depKamokuData{get;set;}
		// 仕入日数据集 sobject => Field1__c
		public String salesDateData{get;set;}
		// 仕入先数据集 sobject => Purchasesource__c
		public String purchaseSourceData{get;set;}
		// 过滤条件  => 数据集合
		public String filterDataJson{get;set;}
		// 查询FLG
		public Boolean sqlFlg{get;set;}
	}
	// 数据集 in the class 变量
	public FilterDataSource filter{get;set;}
	// 过滤条件类型
	/*
	** EQ  => [查询值==输入值]
	** NEQ => [查询值!=输入值]
	** GTE => [查询值>=输入值]
	** GT  => [查询值> 输入值]
	** LTE => [查询值<=输入值]
	** LT  => [查询值< 输入值]
	*/
	private enum FILTERTYPE{EQ,NEQ,GTE,GT,LTE,LT}
	// 2017/07/07 検索結果にFilter機能の追加 WGCH END
	//2018/05/24 仕入画面で入庫処理を行う機能対応 WGCH BEGIN
	public String colnumJson{get; private set;} // Grid列Info
	public String colnumGroupJson{get; private set;} // 分组Field
	public list<PurchaseDetail__c> PurchaseDetailLst{get;set;}
	public PurchaseDetail__c PurchaseDetailStr{get;set;}
	public List<PurDetailItem> purDetailLst{get;set;}
	public list<PurDetailItem> oldBookLst{get;set;}
	public Map<String, List<PurDetailItem>> purInfoMap{get;set;}
	public PurDetailItem BookEstData{get; set;}
	// 计算行数
	public void initPurDetailItem(){
		///*
		//getBookLst(purDetailId);
		purDetailLst = new list<PurDetailItem>(); 
		PurchaseDetailLst = new list<PurchaseDetail__c>();
		if (purDetailLst.size() < LIST_INPUT_DEF_ROWS) {
			Integer appendRsSize = LIST_INPUT_DEF_ROWS - PurchaseDetailLst.size();
			// 2行目まで設定を行う
			for (Integer i = 0; i < appendRsSize; i++) {
				purDetailLst.add(new PurDetailItem(new PurchaseDetail__c(), purDetailLst.size(), null));
			}
		}
		//*/
	}
	// り明細行目追加
	public Pagereference addPurDetailItem() {
		Map<Integer, PurDetailItem> locSortMap = new Map<Integer, PurDetailItem>();
		for (PurDetailItem item : purDetailLst) {
			// 画面表示順により、ソートを行う
			locSortMap.put(CommUtils.nullToIntZero(item.indexRow),item);
		}
		List<Integer> sortKeyLst = new List<Integer>();
		sortKeyLst.addAll(locSortMap.keySet());
		sortKeyLst.sort();
		
		purDetailLst.clear();
		// RowIndex再設定する BEGIN
		for (Integer key : sortKeyLst) {
			PurDetailItem orgItem = locSortMap.get(key);
			orgItem.indexRow = purDetailLst.size();
			purDetailLst.add(orgItem);
		}
		for (Integer i = 0; i < LIST_INPUT_DEF_ROWS; i++) {
			// 見積の場合
			purDetailLst.add(new PurDetailItem(new PurchaseDetail__c(), purDetailLst.size(), null));
		}
		return null;
	}
	@RemoteAction
    public static void savePurchaseDetail(List<String> purDetailJsonLst, List<String> delPurDetailLst){
		// 2019/09/15 Security Check BY zyz BEGIN
		if (!CommSecurityUtils.isDeleteable(PurchaseDetail__c.getSObjectType())) {
			return;
		}
		// 2019/09/15 Security Check BY zyz END
		//if(CommUtils.isBlank(purId)) return;
		if(!delPurDetailLst.isEmpty()) delete [select id from PurchaseDetail__c where Id In: delPurDetailLst]; // todo:到时候联动删除在库自动联动
		Set<String> accMasterIdSet = new Set<String>();
		Map<String, String> proStockMap = new Map<String, String>();
		Map<String, PurchaseDetail__c> purDetailMap = new Map<String, PurchaseDetail__c>();
		for(String jsonItem : purDetailJsonLst){
			PurDetailItem req = (PurDetailItem)JSON.deserialize(jsonItem, PurDetailItem.class);
			system.debug(logginglevel.info,'req :='+req);
			String key = CommUtils.nullToBlank(req.accMasterId) + '_' + CommUtils.nullToIntZero(req.indexRow);
            // 2018/12/30 仕入明细保存对应不正 BY zyz BEGIN
            // if(CommUtils.isBlank(key)) continue;
            if(CommUtils.isBlank(req.accMasterId)) continue;
            // 2018/12/30 仕入明细保存对应不正 BY zyz END
			proStockMap.put(req.accMasterId, '');
			PurchaseDetail__c purDetailItem = new PurchaseDetail__c();
			if(!CommUtils.isBlank(req.purDetailId)) purDetailItem.Id = req.purDetailId; // 仕入明細Id
            // 2018/12/30 仕入明细保存对应不正 BY zyz BEGIN
            // else purDetailItem.PurchaseRef__c = purId; // 仕入Id
            else purDetailItem.PurchaseRef__c = req.purId; // 仕入Id
            // 2018/12/30 仕入明细保存对应不正 BY zyz END
			purDetailItem.AccountMasterRef__c = req.accMasterId; // 商品Id
			purDetailItem.ProductStockRef__c = null; // 在库信息
			purDetailItem.CostPrice__c = req.accMasterPrice; // 原価
			purDetailItem.ProductNumber__c = req.accMasterNum; // 商品数量
			purDetailItem.NoTaxDefKbFlg__c = req.accMasterFlg; // 税区分
			purDetailItem.CostDenpyoukei__c = req.accMasterNoTax; // 計(税抜)
			purDetailItem.CostDenpyoukeiIncTax__c = req.accMasterIncTax; // 計(税込)
			// 2019/09/15 11.10月以降の仕入れ入力について税率が10%の商品と8%の商品入力をすることになると思うのですが、どうやって入力するのでしょうか by zy BEGIN
			purDetailItem.TaxRate__c = CommUtils.nullToZero(req.accMasterRate);
			// 2019/09/15 11.10月以降の仕入れ入力について税率が10%の商品と8%の商品入力をすることになると思うのですが、どうやって入力するのでしょうか by zy END
			if(!CommUtils.isBlank(req.putProStockDate)) purDetailItem.InStockDate__c = req.putProStockDate;// 入庫日
			if(!CommUtils.isBlank(req.purDetailId)) purDetailItem.Id = req.purDetailId; // 仕入明細Id
			purDetailMap.put(key, purDetailItem);
		}
		// 查出已存在的在库信息
		List<ProductStock__c> stockLst = [Select Id, LogicQtyOfStock__c, ProductRef__c From ProductStock__c Where ProductRef__c in: proStockMap.keySet() for update];
		for(ProductStock__c stock : stockLst){ // put存在的商品对应的在库
			proStockMap.put(stock.ProductRef__c, stock.id);
		}
		List<ProductStock__c> newStockLst = new List<ProductStock__c>();
		for(String key : proStockMap.keySet()){ // 插入新商品对应的在库
			if(CommUtils.isBlank(proStockMap.get(key))) newStockLst.add(new ProductStock__c(ProductRef__c = key));
		}
		if(!newStockLst.isEmpty()) insert newStockLst;
		for(ProductStock__c stock : newStockLst){ // 追加新的商品对应的在库
			proStockMap.put(stock.ProductRef__c, stock.id);
		}
		for(String key : purDetailMap.keySet()){ // 仕入明细,参照最新的商品在库Id
			PurchaseDetail__c purDetail = purDetailMap.get(key);
			if(proStockMap.containsKey(purDetail.AccountMasterRef__c) && !CommUtils.isBlank(proStockMap.get(purDetail.AccountMasterRef__c))) purDetail.ProductStockRef__c = proStockMap.get(purDetail.AccountMasterRef__c);
		}
		if(!purDetailMap.isEmpty()) upsert purDetailMap.values();
	}
	@remoteAction
	public static List<ProductItemUtils.ProductItem> getArrayProductItemInfo(String prodCode) {
		// 2015/07/07 プラン明細設定画面に支払情報を選べれない様に変更対応
		return ProductItemUtils.getArrayProdcutItemByCode(prodCode, true, true);
	}
	// 2018/08/08 BEGIN
	@remoteAction
	public static PurDetailInfo getPurDetailInfo(String purSourceId,String PurchaseId){
	// 2018/08/08 END
		if(CommUtils.isBlank(purSourceId)) return  new PurDetailInfo();
		List<String> purIdLst = new List<String>();
	   	for(Purchase__c pur : [Select Id From Purchase__c Where Purchasesource__c =: CommUtils.nullToBlank(purSourceId)]){
	   		// 2018/08/08 BEGIN
	   		if(!CommUtils.isBlank(PurchaseId)){
	   			if(pur.Id == PurchaseId) continue;
	   		}
	   		// 2018/08/08 END
	   		purIdLst.add(pur.Id);
	   	}
		// 获取PurDetailInfo
		// 2018/10/29 新規仕入れ明細並べ不正修正 by zy BEGIN
		return getPurDetailInfo(purIdLst,true);
		// 2018/10/29 新規仕入れ明細並べ不正修正 by zy END
	}
	// PurDetailInfo处理
	private static PurDetailInfo getPurDetailInfo(List<String> purIdLst,boolean remoteFlag){
		PurDetailInfo purInfo = new PurDetailInfo();
		// 2018/10/29 新規仕入れ明細並べ不正修正 by zy BEGIN
		// 2019/09/15 11.10月以降の仕入れ入力について税率が10%の商品と8%の商品入力をすることになると思うのですが、どうやって入力するのでしょうか by zy BEGIN
		String querySQL = 'Select Id, Name, AccountMasterRef__c, AccountMasterRef__r.Name,AccountMasterRef__r.TaxRateCal__c, CostPrice__c, ProductNumber__c, PurchaseRef__c, PurchaseRef__r.Name, PurchaseRef__r.Field1__c, ProductStockRef__c, NoTaxDefKbFlg__c, CostDenpyoukei__c, CostDenpyoukeiIncTax__c, InStockDate__c,TaxRateCal__c From PurchaseDetail__c Where PurchaseRef__c in: purIdLst ';
		// 2019/09/15 11.10月以降の仕入れ入力について税率が10%の商品と8%の商品入力をすることになると思うのですが、どうやって入力するのでしょうか by zy END
		if (remoteFlag) querySQL += 'Order By  LastModifiedDate asc, AccountMasterRef__r.Name';
		else querySQL += 'Order By Name asc';
		//List<PurchaseDetail__c> wkPurDetailLst = [Select Id, Name, AccountMasterRef__c, AccountMasterRef__r.Name, CostPrice__c, ProductNumber__c, PurchaseRef__c, PurchaseRef__r.Name, PurchaseRef__r.Field1__c, ProductStockRef__c, NoTaxDefKbFlg__c, CostDenpyoukei__c, CostDenpyoukeiIncTax__c, InStockDate__c /*, TaxType__c*/ From PurchaseDetail__c Where PurchaseRef__c in: purIdLst Order By  LastModifiedDate asc, AccountMasterRef__r.Name];
		List<PurchaseDetail__c> wkPurDetailLst = database.query(querySQL);
		// 2018/10/29 新規仕入れ明細並べ不正修正 by zy END
		if(wkPurDetailLst.isEmpty()) return purInfo;
		Set<String> accMasterIdSet = new Set<String>(); // 过滤重复商品Set
		for(Integer i = 0; i < wkPurDetailLst.size(); i++){
			PurchaseDetail__c purDetail = wkPurDetailLst[i];
			// 所有数据
			purInfo.purDetailAllLst.add(new PurDetailItem(purDetail, i, purInfo.purInfoMap));
			// 过滤重复商品
			if(accMasterIdSet.contains(purDetail.AccountMasterRef__c)) continue;
			accMasterIdSet.add(purDetail.AccountMasterRef__c);
			// 会计商品去重后的数据
			purInfo.purDetailItemLst.add(new PurDetailItem(purDetail, i, null));
		}
		return purInfo;
	}
	// 获取所有列Info
	private void getColnumJson(){
		JSONGenerator gen = JSON.createGenerator(false);
    	gen.writeStartArray();
    	gen.writeStartObject();
    	gen.writeStringField('field', 'checkFun');
    	gen.writeStringField('headerTemplate', '設定');
	// 2019/09/15 11.10月以降の仕入れ入力について税率が10%の商品と8%の商品入力をすることになると思うのですが、どうやって入力するのでしょうか by zy BEGIN
    	gen.writeStringField('template', '<input type="button" class="k-button" title="設定" value="設定" id="#= purDetailId#" purId="#= purId#" tax="#=accMasterRate#" rowIndex="#= indexRow#" onclick="setPurInfoFun(this, 0)"/>');
    	// 2019/09/15 11.10月以降の仕入れ入力について税率が10%の商品と8%の商品入力をすることになると思うのですが、どうやって入力するのでしょうか by zy END
    	gen.writebooleanField('filterable', false);
    	gen.writebooleanField('sortable', false);
    	gen.writeEndObject();
    	gen.writeStartObject();
		gen.writeStringField('field', 'accMasterNm');
		gen.writeStringField('title', '商品');
		gen.writeStringField('template', '<span accMasterId="#= accMasterId#" id="accMasterId">#= accMasterNm#</span>');
		//gen.writeStringField('template', '<span accMasterId="#= accMasterNm#" id="accMasterId">#= accMasterNm#</span>');
		gen.writeEndObject();
		gen.writeStartObject();
		gen.writeStringField('field', 'accMasterPrice');
		gen.writeStringField('title', '原価');
		gen.writeStringField('template', '<span id="accMasterPrice">#= accMasterPrice#</span>');
		gen.writeEndObject();
    	gen.writeEndArray();
    	colnumJson = gen.getAsString(); // 设置获取所有列Info
    	// 获取groupjson
    	getColnumGroupJson();
	}
	// 获取groupjson
	private void getColnumGroupJson(){
		JSONGenerator gen = JSON.createGenerator(false);
    	gen.writeStartArray();
    	gen.writeStartObject();
    	gen.writeStringField('field', 'purId');
    	gen.writeEndObject();
        gen.writeEndArray();
        colnumGroupJson = gen.getAsString();
	}
	// 仕入明細Info
	public class PurDetailInfo{
		public PurDetailInfo(){
			purInfoMap = new Map<String, String>();
			purDetailItemLst = new List<PurDetailItem>();
			purDetailAllLst = new List<PurDetailItem>();
		}
		public Map<String, String> purInfoMap;
		public List<PurDetailItem> purDetailItemLst;
		public List<PurDetailItem> purDetailAllLst;
	}
	// 仕入明細Item
	public class PurDetailItem{
		public PurDetailItem(PurchaseDetail__c purDetail, Integer purIndex, Map<String, String> purInfoMap){
			indexRow = purIndex; // 明細Index
			accMasterId = CommUtils.nullToBlank(purDetail.AccountMasterRef__c); // 商品Id
			accMasterNm = CommUtils.nullToBlank(purDetail.AccountMasterRef__r.Name); // 商品名
			accMasterPrice = CommUtils.nullToZero(purDetail.CostPrice__c); // 原価
			accMasterNum = CommUtils.nullToZero(purDetail.ProductNumber__c); // 数量
			accMasterFlg = purDetail.NoTaxDefKbFlg__c; // 税区分
			accMasterNoTax = CommUtils.nullToZero(purDetail.CostDenpyoukei__c);// 金額(税抜)
			accMasterIncTax = CommUtils.nullToZero(purDetail.CostDenpyoukeiIncTax__c);// 金額(税込)
			purDetailId = CommUtils.nullToBlank(purDetail.Id); // 仕入明細Id
			purId = CommUtils.nullToBlank(purDetail.PurchaseRef__c); // 仕入Id
			purNm = CommUtils.nullToBlank(purDetail.PurchaseRef__r.Name); // 仕入名
			Date salesDate = purDetail.PurchaseRef__r.Field1__c; // 仕入日
			if(salesDate != null ) {
				purNm += ' ( '+ salesDate.format() +' ) ';
			}
			if(purInfoMap != null) purInfoMap.put(purId, purNm);
			putProStockId = CommUtils.nullToBlank(purDetail.ProductStockRef__c); // 仕入明細在库Id
			// 2019/09/15 11.10月以降の仕入れ入力について税率が10%の商品と8%の商品入力をすることになると思うのですが、どうやって入力するのでしょうか by zy BEGIN
			accMasterRate = CommUtils.nullToZero(purDetail.TaxRateCal__c);
			// 2019/09/15 11.10月以降の仕入れ入力について税率が10%の商品と8%の商品入力をすることになると思うのですが、どうやって入力するのでしょうか by zy END
		}
		public Integer indexRow{get;set;} // 明細Index
		public String accMasterId{get;set;} // 商品Id
		public String accMasterNm{get;set;} // 商品名
		public Decimal accMasterPrice{get;set;} // 原価
		public Decimal accMasterNum{get;set;} // 数量
		public Boolean accMasterFlg{get;set;} // 税区分
		public Decimal accMasterNoTax{get;set;}// 金額(税抜)
		public Decimal accMasterIncTax{get;set;}// 金額(税込)
		
		public String purDetailId{get;set;} // 仕入明細Id
		public String purId{get;set;} // 仕入Id
		public String purNm{get;set;} // 仕入名
		public String putProStockId{get;set;} // 仕入明細在库Id
		public String putProStockDate; // 入庫日
		// 2019/09/15 11.10月以降の仕入れ入力について税率が10%の商品と8%の商品入力をすることになると思うのですが、どうやって入力するのでしょうか by zy BEGIN
		public Decimal accMasterRate{get;set;} // 消費税
		// 2019/09/15 11.10月以降の仕入れ入力について税率が10%の商品と8%の商品入力をすることになると思うのですが、どうやって入力するのでしょうか by zy END
	}
	public List<SelectOption> getPicklistLst(String pickApi){
		List<SelectOption> options = new List<SelectOption>(); 
		Schema.SObjectType sObjType = (Schema.SObjectType) Schema.getGlobalDescribe().get('PurchaseDetail__c');
		if(sObjType != null){
			Map<String, Schema.SObjectField> fieldmap = sObjType.getDescribe().fields.getMap();
			Schema.SObjectField f = (Schema.SObjectField) fieldmap.get(pickApi);
			if(f != null) {
				Schema.DescribeFieldResult r = f.getDescribe();
				// *****以下を追記*****/
				if (r.getType() == Schema.DisplayType.Picklist) {
					for(Schema.PicklistEntry rep : r.getPicklistValues()) {
						options.add(new SelectOption(rep.getValue(), rep.getValue())); 
					}
				}
			}
		}
		return options;
	}
	// 2018/05/24 仕入画面で入庫処理を行う機能対応 WGCH END
	// 2018/10/03 SCANER機能新規 by zy BEGIN
	private OrderServiceHelp.PrintInfo curPrintInfo;
	// 印刷送信アドレス
	public transient String prinUrl{get;set;}
	// 設備IP
	public String localIp{get;set;}
	public void initDevice(){
		// 2018/06/12 SCANER機能新規 by zy BEGIN
		refreshPrintBaseInfo();
		// 2018/06/12 SCANER機能新規 by zy END
	}
	// 刷新打印机信息
	public void refreshPrintBaseInfo(){
		OrderServiceHelp.setInstance(currentShopCode);
		curPrintInfo = OrderServiceHelp.getPrintByIp(localIp,currentShopCode,OrderServiceHelp.LayoutType.ACCOUNT);
		OrderServiceHelp.Device d = OrderServiceHelp.getDeviceMap().get(localIp);
		boolean scanerFlag = false;
		if (d != null) scanerFlag = d.scanerFlag;
		if (curPrintInfo != null && scanerFlag) {
			prinUrl = curPrintInfo.prinUrl;
		}
	}
	@remoteAction
	public static void savePrintLodToDb(String action){
		String curLog = system.now().format('yyyy-MM-dd HH:mm:ss SSS') + '*************仕入SCANERBEGIN********************\n';
		User u = UserUtil.CurrentUser;
		curLog += 'ユーザ：' + u.name + '（' + u.id +'）\n';
		curLog += action + '\n';
		curLog += system.now().format('yyyy-MM-dd HH:mm:ss SSS') + '*************仕入SCANEREND  ********************\n';
		CommLogUtils.saveLogToDb(curLog,CommLogUtils.LogType.POS,new List<String>{'cmimg','newsmsg','qrurl'});
	}
	@remoteAction
	public static List<ProductItemUtils.ProductItem> getProductItemInfo(String prodCode) {
		return ProductItemUtils.getArrayProdcutItemByCode(prodCode);
	}
	// 2018/10/03 SCANER機能新規 by zy END
	// 2018/10/29 09.商品関連情報の取得方式は改善要（商品情報を表示速度完全するため） by zy BEGIN
	@remoteaction
	public static object getProductViewInfo(){
		List<String> notInActLst = new List<String>{CommConst.PROD_ACTION_TYPE_NO,CommConst.PROD_ACTION_TYPE_AR,CommConst.PROD_ACTION_TYPE_PY};
    	String queryStr = 'select id,field3__c';
		queryStr += ' From AccountMaster__c where ActionType__c != :notInActLst and field3__c != null ' ;
		queryStr += ' order by ' + CommConst.PROD_SORT_KEY;
		Set<String> prodCodeSet = new Set<String>();
		for (AccountMaster__c acc : Database.query(queryStr)) {
			prodCodeSet.add(acc.field3__c);
		}
		// 商品コード関連の商品情報を取得する
		Map<String, ProductItemUtils.ProductItem>  prodMaps = ProductItemUtils.getMapProductItemByCodes(prodCodeSet, false);
		return prodMaps.values();
	}
	// 2018/10/29 09.商品関連情報の取得方式は改善要（商品情報を表示速度完全するため） by zy END
	// 2019/09/15 11.10月以降の仕入れ入力について税率が10%の商品と8%の商品入力をすることになると思うのですが、どうやって入力するのでしょうか by zy BEGIN
	public List<System.SelectOption> taxOpts{get;set;}
	private void initTaxList(){
		taxOpts = new List<System.SelectOption>();
		List<JMST__c> jmts = [select id,TaxRate__c,Name from JMST__c where TaxRate__c > 0 order by TaxRate__c desc];
		Set<String> commTaxSet = new Set<String>();
		if (!jmts.isEmpty()) {
			for (JMST__c jmt : jmts) {
				String rateStr = CommUtils.nullToBlank(CommUtils.numberFormat(jmt.TaxRate__c));
				if (!commTaxSet.contains(rateStr)) {
					taxOpts.add(new SelectOption(rateStr,rateStr));
					commTaxSet.add(rateStr);
				}
			}
			commTaxRate = jmts[0].TaxRate__c;
		} else {
			JMST__c jmst = CommLogicProcess.getTaxRateInfo();
			commTaxRate = jmst.taxRate__c;
		}
	}
	// 2019/09/15 11.10月以降の仕入れ入力について税率が10%の商品と8%の商品入力をすることになると思うのですが、どうやって入力するのでしょうか by zy END
}