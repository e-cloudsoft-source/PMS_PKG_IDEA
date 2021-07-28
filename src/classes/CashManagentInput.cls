/*********************************************
* CashManagentInput
* 2014/10/10 現金入力管理機能初期作成
* 2014/11/03 店舗情報参照関係を追加する
* 2015/09/01 多店舗機能対応
* 2017/11/22 検索結果にFilter機能の追加
* 2019/07/15 現金入出に自由に幅を変更機能対応
* 2019/10/15 現金入出の項目の表示非表示を機能対応
*********************************************/
public with sharing class CashManagentInput extends CommBaseCtrl{
	// 2016/10/03 権限関連のチェック情報を追加
    public boolean isCanUpdateDep{get{return CommSecurityUtils.isCanUpdateable(deposit__c.sObjectType);}}//入金修正権限あり、なし
    public boolean isCanUpdatePay{get{return CommSecurityUtils.isCanUpdateable(Paymentslip__c.sObjectType);}}//出金修正権限あり、なし

	//public deposit__c deposit{
	public InputForm input{get; private set;}
	public ItemInfo inpData{get; private set;}	// データ登録情報格納用
	
	public static String CONST_PAGE_MODE_IN{get{ return 'IN';}}
	public static String CONST_PAGE_MODE_OU{get{ return 'OU';}}
	//public 
    private static final Integer LIST_INPUT_DEF_ROWS = CommUtils.nullToIntZero(CommConst.APPOTION_DETAIL_DEF_INPUTLINES);
	// 扱い者
	private Id dumyWorkId;
	// すでに入金済み金額
	public Decimal depAmount{get; private set;}
	public Decimal payAmount{get; private set;}
	// レポートID
	public Id depReportId		{get; private set;}
	public String depReportNm	{get; private set;}
	public Id payReportId		{get; private set;}
	public String payReportNm	{get; private set;}
	public UserUtil.UserShopInfo userInf;
	public CashManagentInput() {
		// ユーザー所属する店舗情報コードを取得する
		userShopCode = UserUtil.CurrentUser.ShopCode__c;
		// 入力項目初期化する
		input = new InputForm();
		input.depShopCode = userShopCode;
		input.payShopCode = userShopCode;
		// データ保存情報変数初期化
		inpData = new ItemInfo();
		// 明細情報格納変数初期化
		deposList = new List<ItemInfo>();
		paymentList = new List<ItemInfo>();
		userInf = UserUtil.CurrentUserInfo;
		// 勘定項目リスト初期化する
		shopOpts = ShopInfoUtil.getBranchShopLst(userInf.shops);
		// 店舗情報MAPを取得する
		shopInfoMap = ShopInfoUtil.getShopInfoMap(userInf.shops);
		
		// 画面から引き渡しページモードを指定する場合
		Map<String,String> parMap = ApexPages.currentPage().getParameters();
		String pMode = parMap.get('pm');	//ページモードを指定する場合
		if ( pMode == CONST_PAGE_MODE_IN || pMode == CONST_PAGE_MODE_OU) input.pageMode = pMode;
		// 入金・出金のレポートID
		List<Report> rptDepLst = [Select Id, Name From Report where DeveloperName = 'CaseDespConfirmRep'];
		List<Report> rptPayLst = [Select Id, Name From Report where DeveloperName = 'CasePayConfirmRep'];
		if (!rptDepLst.isEmpty()) {
			depReportId = rptDepLst[0].Id;
			depReportNm = rptDepLst[0].Name;
		}
		if (!rptPayLst.isEmpty()) {
			payReportId = rptPayLst[0].Id;
			payReportNm = rptPayLst[0].Name;
		}
	}
	
	public void init() {
		// 2019/09/22 現金入出にも消費税項目を追加、税率も選べるように（仕入と同じ仕様に） by zy BEGIN
		initTaxList();
		// 2019/07/15 現金入出に自由に幅を変更機能対応 BY zyz BEGIN
		getCashXml(userShopCode);
		// 2019/07/15 現金入出に自由に幅を変更機能対応 BY zyz END
		// 2019/09/22 現金入出にも消費税項目を追加、税率も選べるように（仕入と同じ仕様に） by zy END
		// 扱い者のダミ用関連情報を作成、取得処理を行う
		dumyWorkId = dummyWorker().Id;
		// 最新情報を取得する		
		queryDetailLst(null);
		// 2019/07/15 現金入出に自由に幅を変更機能対応 BY zyz BEGIN
		// 2019/09/22 現金入出にも消費税項目を追加、税率も選べるように（仕入と同じ仕様に） by zy BEGIN
		// getCashXml(userShopCode);
		// 2019/09/22 現金入出にも消費税項目を追加、税率も選べるように（仕入と同じ仕様に） by zy END
		// 2019/07/15 現金入出に自由に幅を変更機能対応 BY zyz END
	}
	// 2017/11/22 検索結果にFilter機能の追加 WGCH BEGIN
	// 最大表示するレード件数
	private static final Integer MAX_SHOW_RS = 330;
	// FilterDs
	public void filterDataSerch() {
		queryDetailLst(input.pageMode);
	}
	// 売上計上日変更の場合
	public void changeSalesDate() {
		// 初始化 入金
		if(input.pageMode == CONST_PAGE_MODE_IN) getDepInitFilterDs();
		// 初始化 出金
		else getPayInitFilterDs();
		queryDetailLst(input.pageMode);
	}
	/*
	// 店舗情報を切り替えする
	public void refreshBranShop() {
		queryDetailLst(input.pageMode);
	}
	*/
	// 2017/11/22 検索結果にFilter機能の追加 WGCH END
	// 新規登録一行目を追加「入金」
	private void addDepInpLineAct(Date salesDate) {
		if (!isCanUpdateDep) return;
		deposList.add(new ItemInfo(new deposit__c(ShopCode__c = input.depShopCode, SalesDate__c = salesDate), deposList.size())); 
		
	}
	// 新規登録一行目を追加「出金」
	private void addPayInpLineAct(Date salesDate) {
		if (!isCanUpdatePay) return;
		paymentList.add(new ItemInfo(new Paymentslip__c(ShopCode__c = input.payShopCode, SalesDate__c = salesDate), paymentList.size())); 
	}
	
	public Integer editRowIdx{get;set;}
	//public Boolean isReadonly {get;set;}
	// 指定行目情報を編集モードに変更する
	public void historyEdit() {
		// 
		sobjectDataRollback(editRowIdx);
		// 画面ページモードにより、
		if (input.pageMode == CONST_PAGE_MODE_IN) {
			deposList[editRowIdx].isReadOnly = false;
			deposList[editRowIdx].isDelete = false;
		} else if (input.pageMode == CONST_PAGE_MODE_OU) {
			paymentList[editRowIdx].isReadOnly = false;
			paymentList[editRowIdx].isDelete = false;
		}
	}
	
	// データ新規・更新処理を行う
	public void dataUpsert() {
		try {
			// 2017/02/21 Field Security Check BEGIN
			List<String> chkFields = new List<String>{'ShopInfoRef__c'};// ,'Id'
			Map<String,Schema.SObjectField> m = Schema.SObjectType.Paymentslip__c.fields.getMap();
			if (!CommSecurityUtils.isCanUpsertable(chkFields, m)) {
				return;
			}
			List<String> chkFieldsLst = new List<String>{'ShopInfoRef__c'};// ,'Id'
			Map<String,Schema.SObjectField> mm = Schema.SObjectType.Deposit__c.fields.getMap();
			if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
				return;
			}
			// 2017/02/21 Field Security Check End
			// 2017/02/23 Field Security Check BEGIN by wx
			if (!CommSecurityUtils.isCanCreateable(chkFields, m)) {
				return;
			}
			// 2017/02/23 Field Security Check End by wx
			if (input.pageMode == CONST_PAGE_MODE_IN) {	
				// 有効性チェック
				ItemInfo item = inpData;
				item.dep.Id = deposList[editRowIdx].dep.Id;
				if (!preCheckData(item)) return;
				// 店舗コードから店舗のIDを取得する
				ShopInformation__c shop = shopInfoMap.get(item.dep.ShopCode__c);
				// 新規の場合、
				if (item.isDepInsert()) {
					deposit__c dep = item.dep;
					// 店舗情報の参照IDを設定する
					dep.ShopInfoRef__c = (shop == null ? null : shop.Id);
					dep.Dperson__c = dumyWorkId;
					insert dep;
				} 
				// 更新の場合
				else {
					// 店舗情報の参照IDを設定する
					item.dep.ShopInfoRef__c = (shop == null ? null : shop.Id);
					item.isReadOnly = true;
					// 更新処理を行う
					upsert item.dep;
				}
			} else if (input.pageMode == CONST_PAGE_MODE_OU) {
				// 有効性チェック
				ItemInfo item = inpData;
				item.pay.Id = paymentList[editRowIdx].pay.Id;
				if (!preCheckData(item)) return;
				// 店舗コードから店舗のIDを取得する
				ShopInformation__c shop = shopInfoMap.get(item.pay.ShopCode__c);
				// 新規の場合、
				if (item.isPayInsert()) {
					Paymentslip__c pay = item.pay;
					// 店舗情報の参照IDを設定する
					pay.ShopInfoRef__c = (shop == null ? null : shop.Id);
					pay.Pperson__c = dumyWorkId;
					insert pay;
				} 
				// 更新の場合
				else {
					// 店舗情報の参照IDを設定する
					item.pay.ShopInfoRef__c = (shop == null ? null : shop.Id);
					item.isReadOnly = true;
					upsert item.pay;
				}
			}
		
		} catch(Exception e) {
			// 2017/11/22 検索結果にFilter機能の追加 WGCH BEGIN
			isShowErrorFlg = true;
			// 2017/11/22 検索結果にFilter機能の追加 WGCH END
			// 2020/03/31 会計ロック機能 by zy BEGIN
			if (!e.getMessage().contains(Label.MSG_006_0459))
			new ApexPages.Message(ApexPages.Severity.ERROR, CommUtils.getFieldValidationMessage(e.getMessage()));
			// 2020/03/31 会計ロック機能 by zy END
			return;
		}
		inpData = new ItemInfo();
		queryDetailLst(input.pageMode);
	}

	public String deleteRowIdxs{get; set;}
	// 削除処理を行う
	public void deleteData() {
		// 2019/09/15 Security Check BY zyz BEGIN
		if (!CommSecurityUtils.isDeleteable(Paymentslip__c.getSObjectType())) {
			return;
		}
		// 2019/09/15 Security Check BY zyz END
		List<String> deleteRows = deleteRowIdxs.split(',');
		List<Sobject> deleteItems = null;
		Set<Id> deleteIds = new Set<Id>();
		if (input.pageMode == CONST_PAGE_MODE_IN) {
			for (Integer i = 0 ; i < deleteRows.size() ; i++) {
				ItemInfo item = deposList[Integer.valueOf(deleteRows[i])];
				if (item.dep.Id != null) {
					//deleteItems.add(item.dep);
					deleteIds.add(item.dep.Id);
				}
			}
			// 削除対象を確認する
			if (!deleteIds.isEmpty()) deleteItems = [select id from deposit__c where id in :deleteIds for update];
		} else if (input.pageMode == CONST_PAGE_MODE_OU) {
			for (Integer i = 0 ; i < deleteRows.size() ; i++) {
				ItemInfo item = paymentList[Integer.valueOf(deleteRows[i])];
				if (item.pay.Id != null) {
					//deleteItems.add(item.pay);
					deleteIds.add(item.pay.Id);
				}
			}
			// 削除対象を確認する
			if (!deleteIds.isEmpty()) deleteItems = [select id from Paymentslip__c where id in :deleteIds for update];
		}
		// 削除対象を確認する
		if (deleteItems != null && !deleteItems.isEmpty()) delete deleteItems;
		// 最新情報を取得する
		queryDetailLst(input.pageMode);
	}
	
	private Boolean preCheckData(ItemInfo item) {
		// 出金
		if (input.pageMode == CONST_PAGE_MODE_IN) {
			if (!item.isDepReqiredValidate()) {
				// 2017/11/22 検索結果にFilter機能の追加 WGCH BEGIN
				isShowErrorFlg = true;
				// 2017/11/22 検索結果にFilter機能の追加 WGCH END
				//必須項目を入力してください。
				Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_040_0052));
				return false;
			}	
		} 
		// 入金
		else if (input.pageMode == CONST_PAGE_MODE_OU) {
			if (!item.isPayReqiredValidate()) {
				// 2017/11/22 検索結果にFilter機能の追加 WGCH BEGIN
				isShowErrorFlg = true;
				// 2017/11/22 検索結果にFilter機能の追加 WGCH END
				//必須項目を入力してください。
				Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_040_0052));
				return false;
			}
		}
		return true;
	}
	// データ編集のRollback処理
	public void sobjectDataRollback(Integer existIdx) {
		//existIdx = (existIdx == null ? -1 : existIdx);
		
		if (input.pageMode == CONST_PAGE_MODE_IN) {
			for (ItemInfo item : deposList ) {
				// RollBack除外行
				if (item.rowIdx == existIdx) continue;
				item.isReadOnly = true;
				item.rollBackValue();
			}
		} else if (input.pageMode == CONST_PAGE_MODE_OU) {
			for (ItemInfo item : paymentList ) {
				// RollBack除外行
				if (item.rowIdx == existIdx) continue;
				item.isReadOnly = true;
				item.rollBackValue();
			}
		}
		// 取り消しボタンの場合
		if (existIdx == null) {
			if (input.pageMode == CONST_PAGE_MODE_IN) {
				deposList[0].isReadOnly = false;
			} else if (input.pageMode == CONST_PAGE_MODE_OU) {
				paymentList[0].isReadOnly = false;
			}
		}
	}
	
	// 指定行目は登録内容はRollbackする
	public void dataRollBack() {
		sobjectDataRollback(null);
		//queryDetailLst(input.pageMode);
	}

	// 指定情報日の入力情報一覧情報を取得する
	public List<ItemInfo> deposList 	{get; private set;}
	public List<ItemInfo> paymentList	{get; private set;}
	// 店舗情報選択リスト情報を格納する
	public List<SelectOption> shopOpts  {get; private set;}
	public String userShopCode{get; set;}
	// 画面の店舗コードFilter条件
	//public String branchShopNm{get; set;}
	private Map<String,ShopInformation__c> shopInfoMap;
	
	// Default値は会計明細と同じ数値で使う
	private void queryDetailLst (String pageMode) {

//System.debug(Logginglevel.INFO, 'input.pageMode::' + input.pageMode);
//System.debug(Logginglevel.INFO, 'userShopCode::' + userShopCode);
		// 店舗別単位で入金情報を管理する
		// 2017/11/22 検索結果にFilter機能の追加 WGCH BEGIN
		isShowErrorFlg = false;
		// 2017/11/22 検索結果にFilter機能の追加 WGCH END
		if (input.pageMode == CONST_PAGE_MODE_IN || pageMode == null) {
			// 入金情報リストを取得する
			// 2017/11/22 検索結果にFilter機能の追加 WGCH BEGIN
			/*
			Date inputDate = input.depDateInput.Checkinday__c;
			if (inputDate == null) inputDate = Date.today();
			*/
			Date depFromDate = input.depFromDateInput.Checkinday__c;
			Date depToDate = input.depToDateInput.Checkinday__c;
			if (depFromDate == null) depFromDate = Date.today();
			if (depToDate == null) depToDate = Date.today();
			// 2017/11/22 検索結果にFilter機能の追加 WGCH END
			// 売上日名を変換する
			//String saleDate = DateTime.newInstance(inputDate.year(),inputDate.month(), inputDate.day()).format('yyyyMMdd');
			// 支店コード
			String shopCode = input.depShopCode;
			// 2019/07/15 現金入出に自由に幅を変更機能対応 BY zyz BEGIN
			if(pageMode != null) getCashXml(shopCode);
			// 2019/07/15 現金入出に自由に幅を変更機能対応 BY zyz END
//System.debug(Logginglevel.INFO, 'saleDate::' + saleDate);
//System.debug(Logginglevel.INFO, 'shopCode::' + shopCode);
			deposList.clear();
			//　1空白行を自動追加
			// 2017/11/22 検索結果にFilter機能の追加 WGCH BEGIN
			/*
			addDepInpLineAct(inputDate);
			*/
			addDepInpLineAct(depFromDate == depToDate ? depFromDate : Date.today());
			// 2017/11/22 検索結果にFilter機能の追加 WGCH END
			// 一行入力項目を用意する
			depAmount = 0;
			// 入金情報リストを取得する
			// 2017/11/22 検索結果にFilter機能の追加 WGCH BEGIN
			/*
			String queryStr = 'select id, Name, ShopInfoRef__c, ShopInfoRef__r.ShopCode__c,ShopCode__c, LastModifiedBy.Name, LastModifiedDate ,deposit__c,Kamoku__c,depositamount__c,deposititem__c,SalesDate__c,Reldeposit__c,Reldeposit__r.Salesday__c from deposit__c where SalesDate__c = :inputDate ';
			*/
			// 2019/05/15 現金入出の「取引先」項目追加 BY zyz BEGIN
			// String queryStr = 'select id, Name, ShopInfoRef__c, ShopInfoRef__r.ShopCode__c,ShopCode__c, LastModifiedBy.Name, LastModifiedDate ,deposit__c,Kamoku__c,depositamount__c,deposititem__c,SalesDate__c,Reldeposit__c,Reldeposit__r.Salesday__c,deposit__r.Name from deposit__c where SalesDate__c >= :depFromDate And SalesDate__c <= :depToDate ';
			// 2019/09/22 現金入出にも消費税項目を追加、税率も選べるように（仕入と同じ仕様に） by zy BEGIN
			String queryStr = 'select id, Name, ShopInfoRef__c, ShopInfoRef__r.ShopCode__c,ShopCode__c, LastModifiedBy.Name, LastModifiedDate ,deposit__c,Kamoku__c,depositamount__c,deposititem__c,SalesDate__c,Reldeposit__c,Reldeposit__r.Salesday__c,deposit__r.Name,AccountRef__c,AccountRef__r.Name,TaxRate__c,depositamountExc__c from deposit__c where SalesDate__c >= :depFromDate And SalesDate__c <= :depToDate ';
			// 2019/09/22 現金入出にも消費税項目を追加、税率も選べるように（仕入と同じ仕様に） by zy END
			// 2019/05/15 現金入出の「取引先」項目追加 BY zyz END
			// 2017/11/22 検索結果にFilter機能の追加 WGCH END
			if (!CommUtils.isBlank(shopCode)) queryStr += ' And ShopInfoRef__r.ShopCode__c = :shopCode ';
			// 2015/09/01 多店舗機能対応 BEGIN
			else if (userInf.isShopCodePlex) {
	            Set<String> shopSt = userInf.shopSt;
	            queryStr += ' And ShopInfoRef__r.ShopCode__c = :shopSt ';
	        }
			// 2015/09/01 多店舗機能対応 END
			// 2017/11/22 検索結果にFilter機能の追加 WGCH BEGIN
			/*
			queryStr += 'order by createdDate desc';
//System.debug(Logginglevel.INFO, 'DEP QUERY::' + queryStr);
			// 店舗情報
			//for (deposit__c dep : [select id, Name, ShopInfoRef__c, ShopCode__c, LastModifiedBy.Name, LastModifiedDate ,deposit__c,Kamoku__c,depositamount__c,deposititem__c,SalesDate__c,Reldeposit__c,Reldeposit__r.Salesday__c from deposit__c where SalesDate__c = :input.dateInput.Checkinday__c order by createdDate desc]) {
			for (deposit__c dep :  DataBase.query(queryStr)) {
				deposList.add(new ItemInfo(dep, deposList.size()));
				depAmount += CommUtils.nullToZero(dep.depositamount__c);
			}
			*/
			// 初始化
			if(depFilter == null) getDepInitFilterDs();
			set<String> createUserSet = new set<String>();
			set<String> kamokuSet = new set<String>();
			set<String> salesDateSet = new set<String>();
			set<String> depositIdSet = new set<String>();
			// 2019/05/15 現金入出の「取引先」項目追加 BY zyz BEGIN
			set<String> accountDepSet = new set<String>();
			// getFilterWhere(createUserSet, kamokuSet, salesDateSet, depositIdSet, depFilter, CONST_PAGE_MODE_IN);
			getFilterWhere(createUserSet, kamokuSet, salesDateSet, depositIdSet, accountDepSet, depFilter, CONST_PAGE_MODE_IN);
			// 2019/05/15 現金入出の「取引先」項目追加 BY zyz END
			queryStr += ' order by Reldeposit__r.Name  asc,createdDate desc';
			queryStr += ' limit ' + (MAX_SHOW_RS + 1);
			// 取得するデータはリストに反映する
			Integer cnt = 1;
			depFilter.isShowWarningFlg = false;
			for (deposit__c dep : DataBase.query(queryStr)) {
				if (cnt > MAX_SHOW_RS) {
					depFilter.isShowWarningFlg = true;
					//抽出対象データは最大件数(XXXXXX)を超えました。
					Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.MSG_040_0113.replace('XXXXXX',String.valueOf(MAX_SHOW_RS))));
					break;
				}
				ItemInfo depItem = new ItemInfo(dep, deposList.size());
				depFilter.getFilterDs(depItem, CONST_PAGE_MODE_IN);
				if(!CommUtils.isBlank(depFilter.filterDataJson)){
					// 扱者 => 过滤数据集
					if(createUserSet.size() > 0 && !createUserSet.contains(CommUtils.nullToBlank(depItem.createUser))) continue;
					// 科目 => 过滤数据集
					else if(kamokuSet.size() > 0 && !kamokuSet.contains(CommUtils.nullToBlank(depItem.dep.Kamoku__c))) continue;
					// 計上日 => 过滤数据集
					else if(salesDateSet.size() > 0 && !salesDateSet.contains(CommUtils.nullToBlank(depItem.dep.SalesDate__c.format()))) continue;
					// 入金先 => 过滤数据集
					else if(depositIdSet.size() > 0 && !depositIdSet.contains(CommUtils.nullToBlank(depItem.dep.deposit__c))) continue;
					// 2019/05/15 現金入出の「取引先」項目追加 BY zyz BEGIN
					// 入金先-取引先 => 过滤数据集
					else if(accountDepSet.size() > 0 && !accountDepSet.contains(CommUtils.nullToBlank(depItem.dep.AccountRef__c))) continue;
					// 2019/05/15 現金入出の「取引先」項目追加 BY zyz END
					else {
						deposList.add(depItem);
						depAmount += CommUtils.nullToZero(dep.depositamount__c);
						cnt++;
					}
				} else {
					deposList.add(depItem);
					depAmount += CommUtils.nullToZero(dep.depositamount__c);
					cnt++;
				}
			}
			// 2017/11/22 検索結果にFilter機能の追加 WGCH END
		}
		if (input.pageMode == CONST_PAGE_MODE_OU || pageMode == null) {
			// 入金情報リストを取得する
			// 2017/11/22 検索結果にFilter機能の追加 WGCH BEGIN
			/*
			Date inputDate = input.payDateInput.Checkinday__c;
			if (inputDate == null) inputDate = Date.today();
			*/
			Date payFromDate = input.payFromDateInput.Checkinday__c;
			Date payToDate = input.payToDateInput.Checkinday__c;
			if (payFromDate == null) payFromDate = Date.today();
			if (payToDate == null) payToDate = Date.today();
			// 2017/11/22 検索結果にFilter機能の追加 WGCH END
			// 売上日名を変換する
//			String saleDate = DateTime.newInstance(inputDate.year(),inputDate.month(), inputDate.day()).format('yyyyMMdd');
			// 支店コード
			String shopCode = input.payShopCode;
			// 2019/07/15 現金入出に自由に幅を変更機能対応 BY zyz BEGIN
			if(pageMode != null) getCashXml(shopCode);
			// 2019/07/15 現金入出に自由に幅を変更機能対応 BY zyz END
//System.debug(Logginglevel.INFO, 'saleDate::' + saleDate);
//System.debug(Logginglevel.INFO, 'shopCode::' + shopCode);
			paymentList.clear();
			//　1空白行を自動追加
			// 2017/11/22 検索結果にFilter機能の追加 WGCH BEGIN
			/*
			addPayInpLineAct(inputDate);
			*/
			addPayInpLineAct(payFromDate == payToDate ? payFromDate : Date.today());
			// 2017/11/22 検索結果にFilter機能の追加 WGCH END
			payAmount = 0;
			// 出金情報リストを取得する
			// 2017/11/22 検索結果にFilter機能の追加 WGCH BEGIN
			/*
			String queryStr = 'select id, Name, ShopInfoRef__c,ShopInfoRef__r.ShopCode__c,ShopCode__c, LastModifiedBy.Name, LastModifiedDate, Pkamoku__c,Pamount__c,Pitem__c,SalesDate__c,Relpayment__c,Relpayment__r.Salesday__c from Paymentslip__c where SalesDate__c = :inputDate ';
			*/
			// 2018/11/09 出金先項目の機能追加 zyz BEGIN
			// 2019/05/15 現金入出の「取引先」項目追加 BY zyz BEGIN
			// String queryStr = 'select id, Name, ShopInfoRef__c,ShopInfoRef__r.ShopCode__c,ShopCode__c, LastModifiedBy.Name, LastModifiedDate, Pkamoku__c,Pamount__c,Pitem__c,SalesDate__c,Relpayment__c,Relpayment__r.Salesday__c,PaymentRef__c,PaymentRef__r.Name from Paymentslip__c where SalesDate__c >= :payFromDate And SalesDate__c <= :payToDate ';
			// 2019/09/22 現金入出にも消費税項目を追加、税率も選べるように（仕入と同じ仕様に） by zy BEGIN
			String queryStr = 'select id, Name, ShopInfoRef__c,ShopInfoRef__r.ShopCode__c,ShopCode__c, LastModifiedBy.Name, LastModifiedDate, Pkamoku__c,Pamount__c,Pitem__c,SalesDate__c,Relpayment__c,Relpayment__r.Salesday__c,PaymentRef__c,PaymentRef__r.Name,AccountRef__c,AccountRef__r.Name,TaxRate__c,PamountExc__c from Paymentslip__c where SalesDate__c >= :payFromDate And SalesDate__c <= :payToDate ';
			// 2019/09/22 現金入出にも消費税項目を追加、税率も選べるように（仕入と同じ仕様に） by zy END
			// 2019/05/15 現金入出の「取引先」項目追加 BY zyz END
			// 2018/11/09 出金先項目の機能追加 zyz END
			// 2017/11/22 検索結果にFilter機能の追加 WGCH END
			if (!CommUtils.isBlank(shopCode)) queryStr += ' And ShopInfoRef__r.ShopCode__c = :shopCode ';
			// 2015/09/01 多店舗機能対応 BEGIN
			else if (userInf.isShopCodePlex) {
	            Set<String> shopSt = userInf.shopSt;
	            queryStr += ' And ShopInfoRef__r.ShopCode__c = :shopSt ';
	        }
			// 2015/09/01 多店舗機能対応 END
			// 2017/11/22 検索結果にFilter機能の追加 WGCH BEGIN
			/*
			queryStr += 'order by createdDate desc';
//System.debug(Logginglevel.INFO, 'PAY QUERY::' + queryStr);
			//for (Paymentslip__c pay : [select id, Name, ShopInfoRef__c, LastModifiedBy.Name, LastModifiedDate, Pkamoku__c,Pamount__c,Pitem__c,SalesDate__c,Relpayment__c,Relpayment__r.Salesday__c from Paymentslip__c where SalesDate__c = :input.dateInput.Checkinday__c order by createdDate desc]) {
			for (Paymentslip__c pay :  DataBase.query(queryStr)) {
				paymentList.add(new ItemInfo(pay, paymentList.size()));
				payAmount += CommUtils.nullToZero(pay.Pamount__c);
			}
			*/
			// 初始化
			if(payFilter == null) getPayInitFilterDs();
			set<String> createUserSet = new set<String>();
			set<String> kamokuSet = new set<String>();
			set<String> salesDateSet = new set<String>();
			// 2018/11/09 出金先項目の機能追加 zyz BEGIN
			set<String> paymentRefSet = new set<String>();
			// 2019/05/15 現金入出の「取引先」項目追加 BY zyz BEGIN
			set<String> accountPaySet = new set<String>();
			//getFilterWhere(createUserSet, kamokuSet, salesDateSet, new set<String>(), payFilter, CONST_PAGE_MODE_OU);
			// getFilterWhere(createUserSet, kamokuSet, salesDateSet, paymentRefSet, payFilter, CONST_PAGE_MODE_OU);
			getFilterWhere(createUserSet, kamokuSet, salesDateSet, paymentRefSet, accountPaySet, payFilter, CONST_PAGE_MODE_OU);
			// 2019/05/15 現金入出の「取引先」項目追加 BY zyz END
			// 2018/11/09 出金先項目の機能追加 zyz END
			// 2017/07/07 検索結果にFilter機能の追加 WGCH END
			queryStr += ' order by Relpayment__r.Name asc,createdDate desc';
			queryStr += ' limit ' + (MAX_SHOW_RS + 1);
			// 取得するデータはリストに反映する
			Integer cnt = 1;
			payFilter.isShowWarningFlg = false;
			for (Paymentslip__c pay :  DataBase.query(queryStr)) {
				if (cnt > MAX_SHOW_RS) {
					payFilter.isShowWarningFlg = true;
					//抽出対象データは最大件数(XXXXXX)を超えました。
					Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.MSG_040_0113.replace('XXXXXX',String.valueOf(MAX_SHOW_RS))));
					break;
				}
				ItemInfo payItem = new ItemInfo(pay, paymentList.size());
				payFilter.getFilterDs(payItem, CONST_PAGE_MODE_OU);
				if(!CommUtils.isBlank(payFilter.filterDataJson)){
					// 扱者 => 过滤数据集
					if(createUserSet.size() > 0 && !createUserSet.contains(CommUtils.nullToBlank(payItem.createUser))) continue;
					// 科目 => 过滤数据集
					else if(kamokuSet.size() > 0 && !kamokuSet.contains(CommUtils.nullToBlank(payItem.pay.Pkamoku__c))) continue;
					// 計上日 => 过滤数据集
					else if(salesDateSet.size() > 0 && !salesDateSet.contains(CommUtils.nullToBlank(payItem.pay.SalesDate__c.format()))) continue;
					// 2018/11/09 出金先項目の機能追加 zyz BEGIN
					// 出金先 => 过滤数据集
					else if(paymentRefSet.size() > 0 && !paymentRefSet.contains(CommUtils.nullToBlank(payItem.pay.PaymentRef__c))) continue;
					// 2018/11/09 出金先項目の機能追加 zyz END
					// 2019/05/15 現金入出の「取引先」項目追加 BY zyz BEGIN
					// 出金先-取引先 => 过滤数据集
					else if(accountPaySet.size() > 0 && !accountPaySet.contains(CommUtils.nullToBlank(payItem.pay.AccountRef__c))) continue;
					// 2019/05/15 現金入出の「取引先」項目追加 BY zyz END
					else {
						paymentList.add(payItem);
						payAmount += CommUtils.nullToZero(pay.Pamount__c);
						cnt++;
					}
				} else {
					paymentList.add(payItem);
					payAmount += CommUtils.nullToZero(pay.Pamount__c);
					cnt++;
				}
			}
			// 2017/11/22 検索結果にFilter機能の追加 WGCH END
		}
	}

	// 扱者情報は新規・取得を行う
	private Worker__c dummyWorker () {
		Decimal searchKey = Decimal.valueOf('-9999');
		List<Worker__c> workers = [select id, name from Worker__c where Field2__c = :searchKey And Field7__c = :searchKey];
		if (workers.isEmpty()) {
			Worker__c newWork = new Worker__c(
				Name = 'DummyWorker',
				Field2__c = searchKey,
				Field7__c = searchKey
			);
			insert newWork;
			return newWork;
		} else {
			return workers[0];
		}
	}

	
	public class ItemInfo {
		public ItemInfo() {
			dep = new deposit__c();
			pay = new Paymentslip__c();
		}
		public ItemInfo(deposit__c pDep, Integer pRowIdx) {
			dep = pDep;
			if (dep.ShopInfoRef__c != null) dep.ShopCode__c = dep.ShopInfoRef__r.ShopCode__c;
			isDelete = false;
			isReadOnly = false;
			rowIdx = pRowIdx;
			if (dep.id != null) {
				// 2016/11/25 TIMEZON fix BEGIN by zh
				//createDate = dep.LastModifiedDate.format(CommBaseCtrl.getDateTimeFormat());
				createDate = dep.LastModifiedDate.format();
				// 2016/11/25 TIMEZON fix END by zh
				createUser = dep.LastModifiedBy.Name;
				if (dep.SalesDate__c == null) dep.SalesDate__c = dep.Reldeposit__r.Salesday__c;
				isReadOnly = true;
				orgDep = dep.clone(true, true);
				processNo = dep.Name;
				// 2019/09/22 現金入出にも消費税項目を追加、税率も選べるように（仕入と同じ仕様に） by zy BEGIN
				rateTax = CommUtils.nullToBlank(CommUtils.numberFormat(CommUtils.nullToZero(dep.TaxRate__c)));
				if (dep.depositamountExc__c != null) denpyokei = dep.depositamountExc__c;
				else denpyokei = CommUtils.CalExcTaxPrice(dep.depositamount__c, Commutils.nullToIntZero(rateTax), CommUtils.getPointLen());
				denpyokeiIncTax = dep.depositamount__c;
				// 2019/09/22 現金入出にも消費税項目を追加、税率も選べるように（仕入と同じ仕様に） by zy END
			}
		}
		public ItemInfo(Paymentslip__c pPay, Integer pRowIdx) {
			pay = pPay;
			isReadOnly = false;
			isDelete = false;
			rowIdx = pRowIdx;
			if (pay.ShopInfoRef__c != null) pay.ShopCode__c = pay.ShopInfoRef__r.ShopCode__c;
			if (pay.id != null) {
				// 2016/11/25 TIMEZON fix BEGIN by zh
				//createDate = pay.LastModifiedDate.format(CommBaseCtrl.getDateTimeFormat());
				createDate = pay.LastModifiedDate.format();
				// 2016/11/25 TIMEZON fix END by zh
				createUser = pay.LastModifiedBy.Name;
				if (pay.SalesDate__c == null) pay.SalesDate__c = pay.Relpayment__r.Salesday__c;
				isReadOnly = true;
				orgPay = pay.clone(true,true);
				processNo = pay.Name;
				// 2019/09/22 現金入出にも消費税項目を追加、税率も選べるように（仕入と同じ仕様に） by zy BEGIN
				rateTax = CommUtils.nullToBlank(CommUtils.numberFormat(CommUtils.nullToZero(pPay.TaxRate__c)));
				if (pay.PamountExc__c != null) denpyokei = pay.PamountExc__c;
				else denpyokei = CommUtils.CalExcTaxPrice(pay.Pamount__c, Commutils.nullToIntZero(rateTax), CommUtils.getPointLen());
				denpyokeiIncTax = pay.Pamount__c;
				// 2019/09/22 現金入出にも消費税項目を追加、税率も選べるように（仕入と同じ仕様に） by zy END
			}
		}
		public void rollBackValue() {
			if (orgDep != null && orgDep.Id != null) dep = orgDep.clone(true, true);
			if (orgPay != null && orgPay.Id != null) pay = orgPay.clone(true, true);
		}
		public deposit__c dep{get; private set;}
		private deposit__c orgDep;
		public Paymentslip__c pay{get; private set;}
		private Paymentslip__c orgPay;
		public String processNo{get; private set;}
		public String createDate{get; private set;}
		public String createUser{get; private set;}
		public Boolean isReadOnly{get; set;}
		public Integer rowIdx{get; private set;}
		public Boolean isDelete{get; set;}
		// 2019/09/22 現金入出にも消費税項目を追加、税率も選べるように（仕入と同じ仕様に） by zy BEGIN
		public String rateTax{get;set;}
		public decimal denpyokei{get;set;}
		public decimal denpyokeiIncTax{get;set;}
		// 2019/09/22 現金入出にも消費税項目を追加、税率も選べるように（仕入と同じ仕様に） by zy END
		public Boolean isDepReqiredValidate() {
			// 売上計上日が設定 かつ　金額が入力の場合、有効
			return (dep.SalesDate__c != null && dep.depositamount__c != null);
		}
		public Boolean isPayReqiredValidate() {
			return (pay.SalesDate__c != null && pay.Pamount__c != null);
		}
		
		public Boolean isDepInsert () {
			return (dep != null && dep.Id == null);
		}
		public Boolean isPayInsert () {
			return (pay != null && pay.Id == null);
		}
	}

	public class InputForm {
		public deposit__c 	dep{get; private set;}
		public Paymentslip__c	pay{get; private set;}
		// 2017/11/22 検索結果にFilter機能の追加 WGCH BEGIN
		/*
		public BookingTimeTable__c depDateInput{get; private set;}
		public BookingTimeTable__c payDateInput{get; private set;}
		*/
		public BookingTimeTable__c depFromDateInput{get; private set;}
		public BookingTimeTable__c depToDateInput{get; private set;}
		public BookingTimeTable__c payFromDateInput{get; private set;}
		public BookingTimeTable__c payToDateInput{get; private set;}
		// 2017/11/22 検索結果にFilter機能の追加 WGCH END
		public String pageMode{get; set;}
		public String depShopCode{get;set;}
		public String payShopCode{get;set;}
		public InputForm () {
			dep = new deposit__c();
			pay = new Paymentslip__c();
			// 2017/11/22 検索結果にFilter機能の追加 WGCH BEGIN
			/*
			depDateInput = new BookingTimeTable__c(Checkinday__c = Date.today());
			payDateInput = new BookingTimeTable__c(Checkinday__c = Date.today());
			*/
			depFromDateInput = new BookingTimeTable__c(Checkinday__c = Date.today());
			depToDateInput = new BookingTimeTable__c(Checkinday__c = Date.today());
			payFromDateInput = new BookingTimeTable__c(Checkinday__c = Date.today());
			payToDateInput = new BookingTimeTable__c(Checkinday__c = Date.today());
			// 2017/11/22 検索結果にFilter機能の追加 WGCH END
			pageMode = CONST_PAGE_MODE_OU;	// 初期値は出金に設定する
			depShopCode = payShopCode = '';
		}
	}

	// 入金・出金関連処理
	// 指定の売上日により、売上参照関係を自動設定を行う
	public void depSalesInfoAutoSetup(List<deposit__c> nwLst, List<deposit__c> odLst, CommConst.TriggerMethod action) {
		Set<String> salesNameKey = new Set<String>();
		Map<Date, String> insRsvDataMap = new Map<Date, String>();
		if (action == CommConst.TriggerMethod.isInsert) {
			// 指定の売上日
			// 売上計上日を変更すると、売上情報を自動設定を行う
			for (Integer i =0; i<nwLst.size(); i++) {
				deposit__c nw = nwLst[i];
				if (nw.SalesDate__c != null) {
					String salesKey = DateTime.newInstance(nw.SalesDate__c.year(), nw.SalesDate__c.month(), nw.SalesDate__c.day()).format('yyyyMMdd');
					salesNameKey.add(salesKey);
					insRsvDataMap.put(nw.SalesDate__c, salesKey);
				}
			}
			// 指定日の売り上げ情報を取得、自動設定を行う
		} else if (action == CommConst.TriggerMethod.isUpdate) {
			
			// 売上計上日を変更すると、売上情報を自動設定を行う
			for (Integer i =0; i<nwLst.size(); i++) {
				deposit__c nw = nwLst[i];
				deposit__c od = odLst[i];
				if (nw.SalesDate__c != null && nw.SalesDate__c != od.SalesDate__c ) {
					String salesKey = DateTime.newInstance(nw.SalesDate__c.year(), nw.SalesDate__c.month(), nw.SalesDate__c.day()).format('yyyyMMdd');
					salesNameKey.add(salesKey);
					insRsvDataMap.put(nw.SalesDate__c, salesKey);
				}
			}
		}
		
		if (salesNameKey.isEmpty()) return;
		

		Map<Date, Id> salesIdMap = new Map<Date, Id>();
		// 指定の販売情報により、売上情報を取得する
		List<RsvAccount__c> existRsvLst = [select id,Salesday__c from RsvAccount__c where Name = :salesNameKey];
		for (RsvAccount__c rsv : existRsvLst) {
			salesIdMap.put(rsv.Salesday__c, rsv.Id);
			insRsvDataMap.remove(rsv.Salesday__c);
		}
		List<RsvAccount__c> insRsvDataLst = new List<RsvAccount__c>();
		for (String key : insRsvDataMap.values()) {
			RsvAccount__c updsertRsv = new RsvAccount__c(Name = key);
			insRsvDataLst.add(updsertRsv);
		}
		if (!insRsvDataLst.isEmpty()) {
			//　売上データが新規作成
			upsert insRsvDataLst  Name;
			for (RsvAccount__c rsv : insRsvDataLst) {
				Date salesDate = CommUtils.stringToDate(rsv.Name);
				salesIdMap.put(salesDate, rsv.Id);
				//System.debug(LoggingLevel.INFO,'rsv.Salesday__c:::' + rsv.Salesday__c );
			}
		}
		
		// 関連の売り上げIDを設定する
		for (deposit__c nw : nwLst) {
			nw.Reldeposit__c = salesIdMap.get(nw.SalesDate__c);
		}
		
	}
	public void paySalesInfoAutoSetup(List<Paymentslip__c> nwLst, List<Paymentslip__c> odLst, CommConst.TriggerMethod action) {
		Set<String> salesNameKey = new Set<String>();
		Map<Date, String> insRsvDataMap = new Map<Date, String>();
		if (action == CommConst.TriggerMethod.isInsert) {
			// 指定の売上日
			// 売上計上日を変更すると、売上情報を自動設定を行う
			for (Integer i =0; i<nwLst.size(); i++) {
				Paymentslip__c nw = nwLst[i];
				if (nw.SalesDate__c != null) {
					String salesKey = DateTime.newInstance(nw.SalesDate__c.year(), nw.SalesDate__c.month(), nw.SalesDate__c.day()).format('yyyyMMdd');
					salesNameKey.add(salesKey);
					insRsvDataMap.put(nw.SalesDate__c, salesKey);
				}
			}
			// 指定日の売り上げ情報を取得、自動設定を行う
		} else if (action == CommConst.TriggerMethod.isUpdate) {
			
			// 売上計上日を変更すると、売上情報を自動設定を行う
			for (Integer i =0; i<nwLst.size(); i++) {
				Paymentslip__c nw = nwLst[i];
				Paymentslip__c od = odLst[i];
				if (nw.SalesDate__c != null && nw.SalesDate__c != od.SalesDate__c ) {
					String salesKey = DateTime.newInstance(nw.SalesDate__c.year(), nw.SalesDate__c.month(), nw.SalesDate__c.day()).format('yyyyMMdd');
					salesNameKey.add(salesKey);
					insRsvDataMap.put(nw.SalesDate__c, salesKey);
				}
			}
		}
		
		if (salesNameKey.isEmpty()) return;
		
		Map<Date, Id> salesIdMap = new Map<Date, Id>();
		// 指定の販売情報により、売上情報を取得する
		List<RsvAccount__c> existRsvLst = [select id,Salesday__c from RsvAccount__c where Name = :salesNameKey];
		for (RsvAccount__c rsv : existRsvLst) {
			salesIdMap.put(rsv.Salesday__c, rsv.Id);
			insRsvDataMap.remove(rsv.Salesday__c);
		}

		List<RsvAccount__c> insRsvDataLst = new List<RsvAccount__c>();
		for (String key : insRsvDataMap.values()) {
			RsvAccount__c updsertRsv = new RsvAccount__c(Name = key);
			insRsvDataLst.add(updsertRsv);
		}

		if (!insRsvDataLst.isEmpty()) {
			//　売上データが新規作成
			upsert insRsvDataLst  Name;
			for (RsvAccount__c rsv : insRsvDataLst) {
				Date salesDate = CommUtils.stringToDate(rsv.Name);
				salesIdMap.put(salesDate, rsv.Id);
				//System.debug(LoggingLevel.INFO,'rsv.Salesday__c:::' + rsv.Salesday__c );
			}
		}
		// 関連の売り上げIDを設定する
		for (Paymentslip__c nw : nwLst) {
			nw.Relpayment__c = salesIdMap.get(nw.SalesDate__c);
		}
	}
	// 2017/11/22 検索結果にFilter機能の追加 WGCH BEGIN
	// 入金·数据集 in the class 变量
	public FilterDs depFilter{get;set;}
	// 出金·数据集 in the class 变量
	public FilterDs payFilter{get;set;}
	public Boolean isShowErrorFlg{get;set;}
	// 初始化 入金
	private void getDepInitFilterDs(){
		// 数据源重置
		depFilter = new FilterDs();
	}
	// 初始化 出金
	private void getPayInitFilterDs(){
		// 数据源重置
		payFilter = new FilterDs();
	}
	public class FilterDs{
		public FilterDs(){
			isShowWarningFlg = false;
			filterDataJson = '';
			// 2018/11/09 出金先項目の機能追加 zyz BEGIN
			// 2019/05/15 現金入出の「取引先」項目追加 BY zyz BEGIN
			// createUserDs = kamokuDs = salesDateDs = depositDs = paymentRefDs = JSON.serialize(new List<Map<String,String>>());
			createUserDs = kamokuDs = salesDateDs = depositDs = paymentRefDs = accountDepDs = accountPayDs = JSON.serialize(new List<Map<String,String>>());
			// 2019/05/15 現金入出の「取引先」項目追加 BY zyz END
			// 2018/11/09 出金先項目の機能追加 zyz END
			
			// 扱者数据集
			createUserLst = new List<Map<String,String>>();
			// 科目数据集
			kamokuLst = new List<Map<String,String>>();
			// 計上日数据集
			salesDateLst = new List<Map<String,String>>();
			// 入金先数据集
			depositLst = new List<Map<String,String>>();
			// 2018/11/09 出金先項目の機能追加 zyz BEGIN
			// 出金先数据集
			paymentRefLst = new List<Map<String,String>>();
			// 2018/11/09 出金先項目の機能追加 zyz END
			// 2019/05/15 現金入出の「取引先」項目追加 BY zyz BEGIN
			// 入金先取引先数据集
			accountDepLst = new List<Map<String,String>>();
			// 出金先取引先数据集
			accountPayLst = new List<Map<String,String>>();
			// 2019/05/15 現金入出の「取引先」項目追加 BY zyz END
			
			// 扱者 => 过滤Set
			createUserSet = new Set<String>();
			// 科目 => 过滤Set
			kamokuSet = new Set<String>();
			// 計上日 => 过滤Set
			salesDateSet = new Set<String>();
			// 入金先 => 过滤Set
			depositSet = new Set<String>();
			// 2018/11/09 出金先項目の機能追加 zyz BEGIN
			// 出金先 => 过滤Set
			paymentRefSet = new Set<String>();
			// 2018/11/09 出金先項目の機能追加 zyz END
			// 2019/05/15 現金入出の「取引先」項目追加 BY zyz BEGIN
			// 入金先-取引先 => 过滤Set
			accountDepSet = new Set<String>();
			// 出金先-取引先 => 过滤Set
			accountPaySet = new Set<String>();
			// 2019/05/15 現金入出の「取引先」項目追加 BY zyz END
			
		}
		// 入金  || 出金
		private void getFilterDs(ItemInfo item, String pageMode){
			// 扱者 => 数据
			String createUserStr = CommUtils.nullToBlank(item.createUser);
			// 科目 => 数据
			String kamokuStr = CommUtils.nullToBlank(pageMode == CONST_PAGE_MODE_IN ? item.dep.Kamoku__c : item.pay.Pkamoku__c);
			// 計上日 => 数据
			Date salesDate = CommUtils.objectToDate(pageMode == CONST_PAGE_MODE_IN ? item.dep.SalesDate__c : item.pay.SalesDate__c);
			String salesDateStr = CommUtils.nullToBlank(salesDate == null ? '' : salesDate.format());
			// 扱者 => 插入有效数据 => 过滤重复值
			if(!createUserSet.contains(createUserStr) && !CommUtils.isBlank(createUserStr)){
				// 扱者 => 插入到过滤Set中
				createUserSet.add(createUserStr);
				// 扱者 => 数据集Lst
				createUserLst.add(new Map<String,String>{'createUser' => createUserStr});
			}
			// 科目 => 插入有效数据 => 过滤重复值
			if(!kamokuSet.contains(kamokuStr) && !CommUtils.isBlank(kamokuStr)){
				// 科目 => 插入到过滤Set中
				kamokuSet.add(kamokuStr);
				// 科目 => 数据集Lst
				kamokuLst.add(new Map<String,String>{'kamoku' => kamokuStr});
			}
			// 計上日 => 插入有效数据 => 过滤重复值
			if(!salesDateSet.contains(salesDateStr) && !CommUtils.isBlank(salesDateStr)){
				// 計上日 => 插入到过滤Set中
				salesDateSet.add(salesDateStr);
				// 計上日 => 数据集Lst
				salesDateLst.add(new Map<String,String>{'salesDate' => salesDateStr});
			}
			// 扱者 插入有效数据 => Json
			createUserDs = JSON.serialize(createUserLst);
			// 科目 插入有效数据 => Json
			kamokuDs = JSON.serialize(kamokuLst);
			// 計上日 插入有效数据 => Json
			salesDateDs = JSON.serialize(salesDateLst);
			if(pageMode == CONST_PAGE_MODE_IN){
				// 入金先 => 数据
				String depositStr = CommUtils.nullToBlank(item.dep.deposit__r.Name);
				// 入金先Id => 数据
				String depositIdStr = CommUtils.nullToBlank(item.dep.deposit__c);
				// 入金先 => 插入有效数据 => 过滤重复值 // && !CommUtils.isBlank(depositIdStr) 空白处理
				if(!depositSet.contains(depositIdStr)){
					// 入金先 => 插入到过滤Set中
					depositSet.add(depositIdStr);
					// 入金先 => 数据集Lst
					depositLst.add(new Map<String,String>{'deposit' => depositStr,'depositId' => depositIdStr});
				}
				// 入金先 插入有效数据 => Json
				depositDs = JSON.serialize(depositLst);
				// 2019/05/15 現金入出の「取引先」項目追加 BY zyz BEGIN
				// 入金先-取引先 => 数据
				String accountDepStr = CommUtils.nullToBlank(item.dep.AccountRef__r.Name);
				// 入金先-取引先Id => 数据
				String accountDepIdStr = CommUtils.nullToBlank(item.dep.AccountRef__c);
				// 入金先-取引先 => 插入有效数据 => 过滤重复值 // && !CommUtils.isBlank(depositIdStr) 空白处理
				if(!accountDepSet.contains(accountDepIdStr)){
					// 入金先-取引先 => 插入到过滤Set中
					accountDepSet.add(accountDepIdStr);
					// 入金先-取引先 => 数据集Lst
					accountDepLst.add(new Map<String,String>{'accountDep' => accountDepStr,'accountDepId' => accountDepIdStr});
				}
				// 入金先-取引先 插入有效数据 => Json
				accountDepDs = JSON.serialize(accountDepLst);
				// 2019/05/15 現金入出の「取引先」項目追加 BY zyz END
			}
			// 2018/11/09 出金先項目の機能追加 zyz BEGIN
			if(pageMode == CONST_PAGE_MODE_OU){
				// 出金先 => 数据
				String paymentRefStr = CommUtils.nullToBlank(item.pay.PaymentRef__r.Name);
				// 出金先Id => 数据
				String paymentRefIdStr = CommUtils.nullToBlank(item.pay.PaymentRef__c);
				// 出金先 => 插入有效数据 => 过滤重复值
				if(!paymentRefSet.contains(paymentRefIdStr)){
					// 出金先 => 插入到过滤Set中
					paymentRefSet.add(paymentRefIdStr);
					// 出金先 => 数据集Lst
					paymentRefLst.add(new Map<String,String>{'paymentRef' => paymentRefStr,'paymentRefId' => paymentRefIdStr});
				}
				// 出金先 插入有效数据 => Json
				paymentRefDs = JSON.serialize(paymentRefLst);
				// 2019/05/15 現金入出の「取引先」項目追加 BY zyz BEGIN
				// 出金先-取引先 => 数据
				String accountPayStr = CommUtils.nullToBlank(item.pay.AccountRef__r.Name);
				// 出金先-取引先Id => 数据
				String accountPayIdStr = CommUtils.nullToBlank(item.pay.AccountRef__c);
				// 出金先-取引先 => 插入有效数据 => 过滤重复值
				if(!accountPaySet.contains(accountPayIdStr)){
					// 出金先-取引先 => 插入到过滤Set中
					accountPaySet.add(accountPayIdStr);
					// 出金先-取引先 => 数据集Lst
					accountPayLst.add(new Map<String,String>{'accountPay' => accountPayStr,'accountPayId' => accountPayIdStr});
				}
				// 出金先-取引先 插入有效数据 => Json
				accountPayDs = JSON.serialize(accountPayLst);
				// 2019/05/15 現金入出の「取引先」項目追加 BY zyz END
			}
			// 2018/11/09 出金先項目の機能追加 zyz END
		}
		// 扱者数据集
		public List<Map<String,String>> createUserLst{get;set;}
		// 科目数据集
		public List<Map<String,String>> kamokuLst{get;set;}
		// 計上日数据集
		public List<Map<String,String>> salesDateLst{get;set;}
		// 入金先数据集
		public List<Map<String,String>> depositLst{get;set;}
		// 2018/11/09 出金先項目の機能追加 zyz BEGIN
		// 出金先数据集
		public List<Map<String,String>> paymentRefLst{get;set;}
		// 2018/11/09 出金先項目の機能追加 zyz END
		// 2019/05/15 現金入出の「取引先」項目追加 BY zyz BEGIN
		// 入金先取引先数据集
		public List<Map<String,String>> accountDepLst{get;set;}
		// 出金先取引先数据集
		public List<Map<String,String>> accountPayLst{get;set;}
		// 2019/05/15 現金入出の「取引先」項目追加 BY zyz END
		
		// 扱者 => 过滤Set
		public Set<String> createUserSet{get;set;}
		// 科目 => 过滤Set
		public Set<String> kamokuSet{get;set;}
		// 計上日 => 过滤Set
		public Set<String> salesDateSet{get;set;}
		// 入金先 => 过滤Set
		public Set<String> depositSet{get;set;}
		// 2018/11/09 出金先項目の機能追加 zyz BEGIN
		// 出金先 => 过滤Set
		public Set<String> paymentRefSet{get;set;}
		// 2018/11/09 出金先項目の機能追加 zyz END
		// 2019/05/15 現金入出の「取引先」項目追加 BY zyz BEGIN
		// 入金先取引先 => 过滤Set
		public Set<String> accountDepSet{get;set;}
		// 出金先取引先 => 过滤Set
		public Set<String> accountPaySet{get;set;}
		// 2019/05/15 現金入出の「取引先」項目追加 BY zyz END
		
		// 扱者数据集
		public String createUserDs{get;set;}
		// 科目数据集
		public String kamokuDs{get;set;}
		// 計上日数据集
		public String salesDateDs{get;set;}
		// 入金先数据集
		public String depositDs{get;set;}
		// 2018/11/09 出金先項目の機能追加 zyz BEGIN
		// 出金先数据集
		public String paymentRefDs{get;set;}
		// 2018/11/09 出金先項目の機能追加 zyz END
		// 2019/05/15 現金入出の「取引先」項目追加 BY zyz BEGIN
		// 入金先取引先数据集
		public String accountDepDs{get;set;}
		// 出金先取引先数据集
		public String accountPayDs{get;set;}
		// 2019/05/15 現金入出の「取引先」項目追加 BY zyz END
		// 过滤条件  => 数据集合
		public String filterDataJson{get;set;}
		public Boolean isShowWarningFlg{get;set;}
	}
	// 2019/05/15 現金入出の「取引先」項目追加 BY zyz BEGIN
	// private void getFilterWhere(set<String> createUserSet, set<String> kamokuSet, set<String> salesDateSet, set<String> depositIdSet, FilterDs filter, String pageMode){
	private void getFilterWhere(set<String> createUserSet, set<String> kamokuSet, set<String> salesDateSet, set<String> depositIdSet, set<String> accountIdSet, FilterDs filter, String pageMode){
	// 2019/05/15 現金入出の「取引先」項目追加 BY zyz END
		if(!CommUtils.isBlank(filter.filterDataJson)){
			Map<String,List<String>> filterMap = (Map<String,List<String>>)JSON.deserializeStrict(filter.filterDataJson, Map<String, List<String>>.class);
			// 扱者 => 过滤数据集Get
			if (filterMap.containsKey('depCreateUser') && pageMode == CONST_PAGE_MODE_IN){
				createUserSet.addAll(filterMap.get('depCreateUser'));
			} else if(filterMap.containsKey('payCreateUser') && pageMode == CONST_PAGE_MODE_OU) createUserSet.addAll(filterMap.get('payCreateUser'));
			// 科目 => 过滤数据集Get
			if (filterMap.containsKey('depKamoku') && pageMode == CONST_PAGE_MODE_IN){
				kamokuSet.addAll(filterMap.get('depKamoku'));
			} else if(filterMap.containsKey('payKamoku') && pageMode == CONST_PAGE_MODE_OU) kamokuSet.addAll(filterMap.get('payKamoku'));
			// 計上日 => 过滤数据集Get
			if (filterMap.containsKey('depSalesDate') && pageMode == CONST_PAGE_MODE_IN){
				salesDateSet.addAll(filterMap.get('depSalesDate'));
			} else if(filterMap.containsKey('paySalesDate') && pageMode == CONST_PAGE_MODE_OU) salesDateSet.addAll(filterMap.get('paySalesDate'));
			// 入金先 => 过滤数据集Get
			if (filterMap.containsKey('depositId') && pageMode == CONST_PAGE_MODE_IN) depositIdSet.addAll(filterMap.get('depositId'));
			// 2018/11/09 出金先項目の機能追加 zyz BEGIN
			// 出金先 => 过滤数据集Get
			if (filterMap.containsKey('paymentRefId') && pageMode == CONST_PAGE_MODE_OU) depositIdSet.addAll(filterMap.get('paymentRefId'));
			// 2018/11/09 出金先項目の機能追加 zyz END
			// 2019/05/15 現金入出の「取引先」項目追加 BY zyz BEGIN
			// 入金先-取引先 => 过滤数据集Get
			if (filterMap.containsKey('accountDepId') && pageMode == CONST_PAGE_MODE_IN) accountIdSet.addAll(filterMap.get('accountDepId'));
			// 出金先-取引先 => 过滤数据集Get
			if (filterMap.containsKey('accountPayId') && pageMode == CONST_PAGE_MODE_OU) accountIdSet.addAll(filterMap.get('accountPayId'));
			// 2019/05/15 現金入出の「取引先」項目追加 BY zyz END
		}
	}
	// 2017/11/22 検索結果にFilter機能の追加 WGCH END
	//2019/05/15 現金入出の「取引先」項目追加 BY zyz BEGIN
	public Class AccountInfo{
	    String accid; 		// 取引先id
	    String accName;		// 取引先Name
	}
	@remoteAction
	public static AccountInfo getAccount(Id contactId) {
		list<Contact> contactlst = [select Id,Name,AccountId,Account.Name from Contact where Id =: contactId];
		AccountInfo accinfo = new AccountInfo();
		if (!contactlst.isEmpty()){
			for(Contact con : contactlst){
				accinfo.accid = con.AccountId;
				accinfo.accName = con.Account.Name;
			}
		}
		return accinfo;
	}
	//2019/05/15 現金入出の「取引先」項目追加 BY zyz END
	// 2019/07/15 現金入出に自由に幅を変更機能対応 BY zyz BEGIN
	private void getCashXml(String spcd){
		// 2019/09/22 現金入出にも消費税項目を追加、税率も選べるように（仕入と同じ仕様に） by zy BEGIN
		// 2019/10/15 現金入出の項目の表示非表示を機能対応 BY zyz BEGIN
		depMap = new map<String,String>{'削除'=>'36px','伝票#'=>'90px','扱者'=>'90px','入金日時'=>'90px','店舗'=>'15%','科目'=>'12%','計上日'=>'100px','入金先'=>'12%','取引先'=>'12%','摘要'=>'','消費税'=>'30px','金額'=>'120px','金額(税抜)' =>'120px','金額(税込)'=>'120px','アクション'=>'70px'};
		payMap = new map<String,String>{'削除'=>'36px','伝票#'=>'90px','扱者'=>'90px','出金日時'=>'90px','店舗'=>'15%','科目'=>'12%','計上日'=>'100px','出金先'=>'12%','取引先'=>'12%','摘要'=>'','消費税'=>'30px','金額'=>'120px','金額(税抜)' =>'120px','金額(税込)'=>'120px','アクション'=>'70px'};
		// 2019/10/15 現金入出の項目の表示非表示を機能対応 BY zyz END
		// 2019/09/22 現金入出にも消費税項目を追加、税率も選べるように（仕入と同じ仕様に） by zy END
		if(shopOpts.size() == 0){
			// 2019/09/22 現金入出にも消費税項目を追加、税率も選べるように（仕入と同じ仕様に） by zy BEGIN
			// 2019/10/15 現金入出の項目の表示非表示を機能対応 BY zyz BEGIN
			depMap = new map<String,String>{'削除'=>'36px','伝票#'=>'90px','扱者'=>'90px','入金日時'=>'90px','科目'=>'12%','計上日'=>'100px','入金先'=>'12%','取引先'=>'12%','摘要'=>'','消費税'=>'30px','金額'=>'120px','金額(税抜)' =>'120px','金額(税込)'=>'120px','アクション'=>'70px'};
			payMap = new map<String,String>{'削除'=>'36px','伝票#'=>'90px','扱者'=>'90px','出金日時'=>'90px','科目'=>'12%','計上日'=>'100px','出金先'=>'12%','取引先'=>'12%','摘要'=>'','消費税'=>'30px','金額'=>'120px','金額(税抜)' =>'120px','金額(税込)'=>'120px','アクション'=>'70px'};
			// 2019/10/15 現金入出の項目の表示非表示を機能対応 BY zyz END
			// 2019/09/22 現金入出にも消費税項目を追加、税率も選べるように（仕入と同じ仕様に） by zy END
		}
		// 2019/10/15 現金入出の項目の表示非表示を機能対応 BY zyz BEGIN
		depHideMap = new map<String,Boolean>{'入金先'=>true,'取引先'=>true};
		payHideMap = new map<String,Boolean>{'出金先'=>true,'取引先'=>true};
		// 2019/10/15 現金入出の項目の表示非表示を機能対応 BY zyz END
		String docName = 'CashManagentConfig';
		try{
			// 2019/09/22 現金入出にも消費税項目を追加、税率も選べるように（仕入と同じ仕様に） by zy BEGIN
			depositTaxFlg = false;
			paymentTaxFlg = false;
			// 2019/09/22 現金入出にも消費税項目を追加、税率も選べるように（仕入と同じ仕様に） by zy END
			Dom.XmlNode shopRoot = CommXmlUtils.parseXmlDoc(docName, spcd);
			// xml定义入金
			Dom.XmlNode depositNode = shopRoot.getChildElement('DEPOSIT', null);
			if(depositNode != null){
				Dom.XmlNode colnumSizeNode = depositNode.getChildElement('COLNUMSIZE', null);
				if(colnumSizeNode != null){
					String depositStr = CommUtils.nullToBlank(colnumSizeNode.getText());
					getDeposit(depositStr);
				}
				// 2019/09/22 現金入出にも消費税項目を追加、税率も選べるように（仕入と同じ仕様に） by zy BEGIN
				Dom.XmlNode taxSelNode = depositNode.getChildElement('TAXSELECTFLG', null);
				if(taxSelNode != null){
					String depositStr = CommUtils.nullToBlank(taxSelNode.getText());
					depositTaxFlg = boolean.valueOf(depositStr);
				}
				// 2019/09/22 現金入出にも消費税項目を追加、税率も選べるように（仕入と同じ仕様に） by zy END
				// 2019/10/15 現金入出の項目の表示非表示を機能対応 BY zyz BEGIN
				Dom.XmlNode colHideNode = depositNode.getChildElement('COLHIDE', null);
				if(colHideNode != null){
					String colHideStr = CommUtils.nullToBlank(colHideNode.getText());
					depHideMap.put(colHideStr,false);
				}
				// 2019/10/15 現金入出の項目の表示非表示を機能対応 BY zyz END
			}
			// xml定义出金
			Dom.XmlNode paymentslipNode = shopRoot.getChildElement('PAYMENTSLIP', null);
			if(paymentslipNode != null){
				Dom.XmlNode colnumSizeNode = paymentslipNode.getChildElement('COLNUMSIZE', null);
				if(colnumSizeNode != null){
					String paymentslipStr = CommUtils.nullToBlank(colnumSizeNode.getText());
					getPaymentslip(paymentslipStr);
				}
				// 2019/09/22 現金入出にも消費税項目を追加、税率も選べるように（仕入と同じ仕様に） by zy BEGIN
				Dom.XmlNode taxSelNode = paymentslipNode.getChildElement('TAXSELECTFLG', null);
				if(taxSelNode != null){
					String paymentslipStr = CommUtils.nullToBlank(taxSelNode.getText());
					paymentTaxFlg = boolean.valueOf(paymentslipStr);
				}
				// 2019/09/22 現金入出にも消費税項目を追加、税率も選べるように（仕入と同じ仕様に） by zy END
				// 2019/10/15 現金入出の項目の表示非表示を機能対応 BY zyz BEGIN
				Dom.XmlNode colHideNode = paymentslipNode.getChildElement('COLHIDE', null);
				if(colHideNode != null){
					String colHideStr = CommUtils.nullToBlank(colHideNode.getText());
					payHideMap.put(colHideStr,false);
				}
				// 2019/10/15 現金入出の項目の表示非表示を機能対応 BY zyz END
			}
		} catch (Exception e) {}
	}
	// dep:入金(使用不可)，pay:出金(使用不可)
	public map<String,String> depMap{get;set;}		// 入金宽度定义
	public map<String,String> payMap{get;set;}		// 出金宽度定义
	// 2019/10/15 現金入出の項目の表示非表示を機能対応 BY zyz BEGIN
	public map<String,Boolean> depHideMap{get;set;}		// 入金隐藏定义
	public map<String,Boolean> payHideMap{get;set;}		// 出金隐藏定义
	// 入金宽度定义设定
	private void getDeposit(String depStr){
		if(!CommUtils.isBlank(depStr)){
			list<String> depLst = depStr.split(',');
			for(String dep : depLst){
				if (CommUtils.isBlank(dep)) continue;
				String[] depSplit = dep.split(':');
				if (depSplit.size() < 2) continue;
				String key = CommUtils.nullToBlank(depSplit[0]);
				String widthStr = CommUtils.nullToBlank(depSplit[1]);
				if(CommUtils.isBlank(widthStr)) continue;
	        	depMap.put(key, widthStr);
			}
		}
	}
	// 出金宽度定义设定
	private void getPaymentslip(String payStr){
		if(!CommUtils.isBlank(payStr)){
			list<String> payLst = payStr.split(',');
			for(String pay : payLst){
				if (CommUtils.isBlank(pay)) continue;
				String[] paySplit = pay.split(':');
				if (paySplit.size() < 2) continue;
				String key = CommUtils.nullToBlank(paySplit[0]);
				String widthStr = CommUtils.nullToBlank(paySplit[1]);
				if(CommUtils.isBlank(widthStr)) continue;
	        	payMap.put(key, widthStr);
			}
		}
	}
	// 2019/10/15 現金入出の項目の表示非表示を機能対応 BY zyz END
	// 2019/07/15 現金入出に自由に幅を変更機能対応 BY zyz END
	// 2019/09/22 現金入出にも消費税項目を追加、税率も選べるように（仕入と同じ仕様に） by zy BEGIN
	public integer roundMode{get;set;}		// 端数処理区分
	public boolean depositTaxFlg{get;set;}
	public boolean paymentTaxFlg{get;set;}
	public List<System.SelectOption> taxOpts{get;set;}
	private void initTaxList(){
		taxOpts = new List<System.SelectOption>();
		roundMode = getRoundType();
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
			if (!commTaxSet.contains('0')) taxOpts.add(new SelectOption('0','0'));
		}
	}
	// 2019/09/22 現金入出にも消費税項目を追加、税率も選べるように（仕入と同じ仕様に） by zy END
}