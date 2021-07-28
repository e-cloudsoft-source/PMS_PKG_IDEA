/*********************************************
* CashRollupBook
* 2014/11/03 現金合わせ機能
* 2014/11/11 現金合わせレポートリンク機能を追加する
* 2015/09/01 多店舗機能対応
* 2016/04/28 現金合せいレポートリンク先変更できる機能対応
* 2016/06/10 現金合せ「売上金額」集計ロジック変更対応（新会計：＄預かり金額合計、旧会計：＄支払金額合計）
* 2016/07/15 トランスレーション対応
* 2016/07/29 初期値自動設定機能対応
* 2017/06/08 現金合せ論理値自動更新できるように改善対応
* 2017/06/22 現金合わせPOS別集計できる機能対応
*********************************************/
public with sharing class CashRollupBook extends CommBaseCtrl{
	public boolean isCanUpdateLead{get{return CommSecurityUtils.isCanUpdateable(CashVerification__c.sObjectType);}}
	//public CashVerification__c newCash{get; set;}
	private final String QueryHeader;
	// レポートID
	public Id reportId		{get; private set;}
	public String reportNm	{get; private set;}
	// 2016/07/15 トランスレーション対応 BEGIN
	Map<String, Schema.SObjectField> fieldMap;
	// 2016/07/15 トランスレーション対応 END
	// 2017/06/08 現金合せ論理値自動更新できるように改善対応 BEGIN
	public String rsvId{get; private set;}
	// 2017/06/08 現金合せ論理値自動更新できるように改善対応 END
	// 2017/07/07 ポースリストの「その他」項目追加　by　zy BEGIN
	// 特殊value，当日売上金中含有pos列表以外的pos值，列表中添加
	public String otherPosValue{get {return '$$999$$';}}
	// pos列表
	public String allPosStr{get;private set;}
	// 2017/07/07 ポースリストの「その他」項目追加　by　zy END
	public CashRollupBook() {
		// 2016/07/15 トランスレーション対応 BEGIN
		fieldMap = Schema.SObjectType.CashVerification__c.fields.getMap();
		// 2016/07/15 トランスレーション対応 END
		// 店舗リスト情報を設定する
		setInitBranShopLst();
		// 売上計上日
		dateInput = new BookingTimeTable__c(Checkinday__c = Date.today());
		// 売上情報を取得する
		// 検索Object項目文字列を取得する
		QueryHeader = 'Select LastModifiedBy.Name, ' + CommSqlUtils.generateAllFieldsString('CashVerification__c');
		// 店舗初期化設定
		branchShopNm = UserUtil.CurrentUser.ShopCode__c;
		// 2016/04/28 現金合せいレポートリンク先変更できる機能対応 BEGIN
		String linkRepName = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().CaseRollupBookRepNm__c);
		if (CommUtils.isBlank(linkRepName)) linkRepName = '現金合せ履歴';
		// 入金・出金ID
		//List<Report> rptLst = [Select Id, Name From Report where DeveloperName = 'CaseRollupBookConfirmRep'];
		List<Report> rptLst = [Select Id, Name From Report where Name = :linkRepName limit 1];
		// 2016/04/28 現金合せいレポートリンク先変更できる機能対応 END
		if (!rptLst.isEmpty()) {
			reportId = rptLst[0].Id;
			reportNm = rptLst[0].Name;
		}
		// 2017/07/07 ポースリストの「その他」項目追加　by　zy BEGIN
		allPosStr = '';
		// 2017/07/07 ポースリストの「その他」項目追加　by　zy END
	}

	public void init() {
		// 2017/06/23 device config by zy BEGIN
		initDeviceProcess();
		initPosNo();
		// 現金情報 
		reloadXmlInf(branchShopNm);
		// 釣銭機の機能
		if (isChangeFlag) loadChangeInf(branchShopNm);
		// 2016/07/15 トランスレーション対応 by wx end
		// 2017/06/23 device config by zy END
		// 2017/06/08 現金合せ論理値自動更新できるように改善対応 BEGIN
		//queryInfo();
		queryInfo(null);
		// 2017/06/08 現金合せ論理値自動更新できるように改善対応 END
	}
	// 現金情報を格納する
	public void saveCashInfo () {
		// 2017/02/21 Field Security Check BEGIN
		List<String> chkFields = new List<String>{'SearchKey__c','CashAmountAct__c','CasePayment__c','Casedeposit__c','CashSales__c','CashAmountLogic__c'};
		Map<String,Schema.SObjectField> m = Schema.SObjectType.CashVerification__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFields, m)) {
			return;
		}
		// 2017/02/21 Field Security Check End
		// newCash = new CashVerification__c();
		CashVerification__c newCash = cashInfo.cash;
		// 2017/06/23 device config by zy BEGIN
		// 2017/07/07 ポースリストの「その他」項目追加　by　zy BEGIN
		// autoRefreshLogicInfo方法最后一个参数变成组合字符
		String searchNo = CommUtils.nullToBlank(curPos) + ':' + allPosStr;
		// 2017/06/08 現金合せ論理値自動更新できるように改善対応 BEGIN
		CashBookInfo newsCashBookInfo = autoRefreshLogicInfo(rsvId,branchShopNm,searchNo);
		// 2017/07/07 ポースリストの「その他」項目追加　by　zy END
		// 2017/06/23 device config by zy END
		/*
		newCash.CashAmountLogic__c = cashInfo.cashLogicAmount;
		newCash.CashSales__c = cashInfo.salesAmount;
		newCash.CaseDeposit__c = cashInfo.despAmount;
		newCash.CasePayment__c = cashInfo.payAmount;
		*/
		newCash.CashSales__c = newsCashBookInfo.salesAmount;
		newCash.CaseDeposit__c = newsCashBookInfo.despAmount;
		newCash.CasePayment__c = newsCashBookInfo.payAmount;
		newCash.CashAmountLogic__c = CommUtils.nullToZero(newCash.ReserveFund__c) + newsCashBookInfo.salesAmount + newsCashBookInfo.despAmount - newsCashBookInfo.payAmount;
		// 2017/06/08 現金合せ論理値自動更新できるように改善対応 END
		// 現金有高[現物] 変更→機械有高＋手許有高[現物]	
		// 保存开关，或者隐藏保存的开关关闭的时候
		newCash.CashAmountAct__c = cashInfo.cashActAmount;
		if (isEditKikaiFlag || isSaveFlag) newCash.CashAmountAct__c = CommUtils.nullToZero(cashInfo.cashActAmount) + CommUtils.nullToZero(cashInfo.cashMachAmount);
		// 更新キー：
		// 2017/06/22 機械有高可入力機能追加　by　zy　BEGIN
		//newCash.SearchKey__c = CommUtils.nullToBlank(newCash.RsvAccountRef__r.Name) + '_' + CommUtils.nullToBlank(branchShopNm);
		newCash.SearchKey__c = CommUtils.nullToBlank(newCash.RsvAccountRef__r.Name) + '_' + CommUtils.nullToBlank(branchShopNm);
		// posNo. 不为空 为了不影响不用pos的数据
		if ( !CommUtils.isBlank(curPos))  newCash.SearchKey__c += '_' + CommUtils.nullToBlank(curPos);
		newCash.POSNo__c = curPos;
		// 2017/07/11 POSリストの「All」場合、保存可能　by　zy BEGIN
		// all pos 的时候 可以保存，如果id存在就把id去掉
		if (!posLst.isEmpty() && CommUtils.isBlank(curPos)) {
			newCash.id = null;
		}
		// 2017/07/11 POSリストの「All」場合、保存可能　by　zy END
		// 2017/06/22 機械有高可入力機能追加　by　zy　END
		try {
			upsert newCash SearchKey__c;
		} catch (Exception e) {
			new ApexPages.Message(ApexPages.Severity.ERROR, CommUtils.getFieldValidationMessage(e.getMessage()));
			return;
		}
		// 2017/06/08 現金合せ論理値自動更新できるように改善対応 BEGIN
		//queryInfo();
		queryInfo(newsCashBookInfo);
		// 2017/06/08 現金合せ論理値自動更新できるように改善対応 END
 	}
 	// 2017/06/08 現金合せ論理値自動更新できるように改善対応 BEGIN
	//private void queryInfo () {
	private void queryInfo (CashBookInfo newsCashBookInfo) {
	// 2017/06/08 現金合せ論理値自動更新できるように改善対応 END
		// 2017/06/23 device config by zy BEGIN
		//initDeviceProcess();
		// 2017/06/23 device config by zy END
		// 2016/07/15 トランスレーション対応 by wx begin
		// 現金情報 
		//reloadXmlInf(branchShopNm);
		// 2016/07/15 トランスレーション対応 by wx end
		// 2017/06/23 device config by zy BEGIN
		//2017/03/17 お釣りプリンター機能　by zy BEGIN
		//loadChangeInf(branchShopNm);
		//2017/03/17 お釣りプリンター機能　by zy BEGIN
		// 2017/06/23 device config by zy END
		// 指定日と店舗コードにより、検索情報を取得する
		Date salesDate = dateInput.Checkinday__c = (dateInput.Checkinday__c == null ? Date.today() : dateInput.Checkinday__c);
		// 指定日の売上情報を取得する
		RsvAccount__c rsv = CommLogicProcess.getRsvAccountInf(salesDate);
		// 2017/06/08 現金合せ論理値自動更新できるように改善対応 BEGIN
		//Id rsvId = rsv.Id;
		rsvId = rsv.Id;
		// 2017/06/08 現金合せ論理値自動更新できるように改善対応 END
		// 店舗コード
		String queryStr = QueryHeader + ',RsvAccountRef__r.Name From CashVerification__c Where RsvAccountRef__c = :rsvId ';
		// 2015/09/01 多店舗機能対応 BEGIN
		// 店舗あり　かつ　ALL店舗の場合、保存機能がありませんが、各店舗の情報を全部抽出する[店舗条件、検索キーを指定なし、該当売上計上日により、検索する]
		// 店舗指定の場合、指定条件で検索を行う
		if (!CommUtils.isBlank(branchShopNm)) {
            queryStr += ' And ShopInfoRef__r.ShopCode__c = :branchShopNm ';
        }else if (userInf.isShopCodePlex) {
            Set<String> shopSt = userInf.shopSt;
            queryStr += ' And ShopInfoRef__r.ShopCode__c = :shopSt ';
        }
		// 2017/02/28 店舗なしの場合、取得条件の対応 BEGIN
		// 店舗なしの場合
		else if (CommUtils.isBlank(branchShopNm) && branchShopLst.isEmpty()) {
			String searchkey = CommUtils.nullToBlank(rsv.Name) + '_';
			//2017/07/01 レビュー更新する　by　zy　BEGIN
			//TODO 多posno 改条件 like 前缀
			// all pos下不进行模糊查询
			// POSNOリストが存在場合、ALLのキーとPOSNOのキー情報を取得する
			if (!posLst.isEmpty()) {
				// 2017/07/02 無店舗下検索対応　by　zy BEGIN
				// 2017/11/29 検索キーを変更する、LIKE 20171203_\_% -> 20171203_% 変更する
				queryStr += ' And searchkey__c like \'' + String.escapeSingleQuotes(searchkey) + '%\' ';
				// 2017/07/02 無店舗下検索対応　by　zy END
			} else queryStr += ' And searchkey__c = \'' + String.escapeSingleQuotes(searchkey) + '\' ';
			//2017/07/01 レビュー更新する　by　zy　END
		} 
		// 2017/02/28 店舗なしの場合、取得条件の対応 END
		//2017/06/19 POS選択リストの初期化　by　zy　BEGIN
		if(!CommUtils.isBlank(curPos)) {
			// 2017/07/07 ポースリストの「その他」項目追加　by　zy BEGIN
			//posno为「その他」
			//if (curPos == otherPosValue) {
				//Set<String> posSet = getPosSet();
				//String searchkey = CommUtils.nullToBlank(rsv.Name) + '_' + branchShopNm;
				//查找pos列表以外的数据
        		//queryStr += ' And POSNo__c not in :posSet ';
        		//queryStr += ' And searchkey__c like \'' + String.escapeSingleQuotes(searchkey) + '\\_%\' ';
        	//} else  queryStr += ' And POSNo__c = :curPos ';
        	queryStr += ' And POSNo__c = :curPos ';
        	// 2017/07/07 ポースリストの「その他」項目追加　by　zy END
        }
        // 2015/09/01 多店舗機能対応 END
        //2017/06/19 POS選択リストの初期化　by　zy　END
        // 2017/07/11 POSリストの「All」場合、保存可能　by　zy BEGIN
		// 现行機能のAll-POS保存可能追加
		// 在All-POSの場合、判断All-POSのデータ是否存在，如果存在则只处理allpos的数据
		// 如果不存在则进行原来的操作
		List<CashVerification__c> allPosLst = new List<CashVerification__c>();
		if (!posLst.isEmpty() && CommUtils.isBlank(curPos)) {
			//因为添加开关所以需要跳过此处,因为pos列表功能基于device所以不能没有的
			if (device != null && device.isAllPosCanSaveFlag){
				//查找为空的 数据
				String queryWhere = ' And POSNo__c = :curPos ';
				allPosLst = Database.query(queryStr + queryWhere);
			}
		}
		// 2017/07/11 POSリストの「All」場合、保存可能　by　zy END
		queryStr += ' order by LastModifiedDate desc ';
//System.debug(loggingLevel.info, 'queryStr='+queryStr);	
		// 既存情報を取得する
		List<CashVerification__c> cashLst = DataBase.query(queryStr);
// 2017/07/11 POSリストの「All」場合、保存可能　by　zy BEGIN
		if (!allPosLst.isEmpty()) cashLst = allPosLst;
// 2017/07/11 POSリストの「All」場合、保存可能　by　zy END
		ShopInformation__c shop = shopInfoMap.get(branchShopNm);
		CashVerification__c sItem = null;
		if (cashLst.isEmpty()) {
			Decimal preReserveFund = null;
			sItem = new CashVerification__c(
				RsvAccountRef__r = rsv,
				RsvAccountRef__c = rsvId,
				ReserveFund__c   = preReserveFund,
				ShopInfoRef__c   =  (shop == null ? null : shop.Id) );
				// 2016/07/29 初期値自動設定機能対応 by zh BEGIN
				// ALL店舗の場合、該当初期値設定を行わない：理由→初期値のは、該当店舗の実際入力前に、手間いからず、　ALLの場合、実際の集計値を区別するため、初期値は集計に入りません
				if (branchShopLst.isEmpty() || (branchShopLst.size() > 0 && !CommUtils.isBlank(branchShopNm))) {
					Map<String, String> fieldsDefMap = CommSqlUtils.getCustomeFieldLst(CashVerification__c.sObjectType,true);
					for(String fieldName : defaultValueConvertMap.keySet()){
						// 2017/06/20 pos別の準備金処理する　by　zy BEGIN
						//if(fieldsDefMap.containsKey(fieldName)) sItem.put(fieldName,defaultValueConvertMap.get(fieldName));
						String foreinKey = fieldName;
						Decimal otherAmount = 0;
						//posあり
						if (!CommUtils.isBlank(curPos)) {
							foreinKey = CommUtils.nullToBlank(curPos) + '_' + fieldName;
							otherAmount = defaultPosConvertMap.get(foreinKey);
						//all pos / 
						} else {
							//2017/07/01 レビュー更新する　by　zy　BEGIN
							//TODO 严格区分
							//POSリストの「all」の場合集計不要
							/*
							if (!posLst.isEmpty()) {
								for (SelectOption sec : posLst){
									foreinKey = CommUtils.nullToBlank(sec.getValue()) + '_' + fieldName;
									otherAmount += CommUtils.nullToZero(defaultPosConvertMap.get(foreinKey));
								}
								// 「POS」 allの場合　DEFAULT值設定
								if (otherAmount == 0 && CommUtils.isBlank(curPos)) {
									otherAmount = defaultValueConvertMap.get(fieldName);
								}
							//不存在pos机列表
							} else  
							*/
							otherAmount = defaultValueConvertMap.get(fieldName);
							//2017/07/01 レビュー更新する　by　zy　END
						}
						if(fieldsDefMap.containsKey(fieldName)) sItem.put(fieldName,otherAmount);
						// 2017/06/20 pos別の準備金処理する　by　zy END
					}
				}
				// 2016/07/29 初期値自動設定機能対応 by zh END
		} else {
			// 店舗リストの「all」場合　POS「All」、POSリスト集計区分
			if (CommUtils.isBlank(branchShopNm) && !branchShopLst.isEmpty()) {
				//过滤allpos和其他pos的区分
				cashLst = filterAllPosOrEach(cashLst);
			}
			// 合計処理を行う
			for (CashVerification__c cash : cashLst) {
				if (sItem == null) { 
					sItem = cash;
					continue;
				}
				// 2016/07/15 トランスレーション対応  by wx begin
				Sobject wkCash = (Sobject)cash;
				Sobject wkItem = (Sobject)sItem;
				// 枚数合計
				for (PRICE defInf : inputInf) {
					Integer ItemNums = CommUtils.nullToIntZero(wkItem.get(defInf.apiName));
					Integer CashNums = CommUtils.nullToIntZero(wkCash.get(defInf.apiName));
					wkItem.put(defInf.apiName, (ItemNums+CashNums));
				}
				//2017/07/01 レビュー更新する　by　zy　BEGIN
				//TODO 機械有高
				for (PRICE defInf : inputMachineInf) {
					Integer ItemNums = CommUtils.nullToIntZero(wkItem.get(defInf.apiName));
					Integer CashNums = CommUtils.nullToIntZero(wkCash.get(defInf.apiName));
					wkItem.put(defInf.apiName, (ItemNums+CashNums));
				}
				//2017/07/01 レビュー更新する　by　zy　END
				/*
				// 枚数合計
				sItem.TenThousandCashNums__c = CommUtils.nullToZero(sItem.TenThousandCashNums__c) + CommUtils.nullToZero(cash.TenThousandCashNums__c);
				sItem.FiveThousandCashNums__c = CommUtils.nullToZero(sItem.FiveThousandCashNums__c) + CommUtils.nullToZero(cash.FiveThousandCashNums__c);
				sItem.TwoThousandCashNums__c = CommUtils.nullToZero(sItem.TwoThousandCashNums__c) + CommUtils.nullToZero(cash.TwoThousandCashNums__c);
				sItem.OneThousandCashNums__c = CommUtils.nullToZero(sItem.OneThousandCashNums__c) + CommUtils.nullToZero(cash.OneThousandCashNums__c);
				sItem.FiveHundredCashNums__c = CommUtils.nullToZero(sItem.FiveHundredCashNums__c) + CommUtils.nullToZero(cash.FiveHundredCashNums__c);
				sItem.OneHundredCashNums__c = CommUtils.nullToZero(sItem.OneHundredCashNums__c) + CommUtils.nullToZero(cash.OneHundredCashNums__c);
				sItem.FiftyCashNums__c = CommUtils.nullToZero(sItem.FiftyCashNums__c) + CommUtils.nullToZero(cash.FiftyCashNums__c);
				sItem.TenCashNums__c = CommUtils.nullToZero(sItem.TenCashNums__c) + CommUtils.nullToZero(cash.TenCashNums__c);
				sItem.FiveCashNums__c = CommUtils.nullToZero(sItem.FiveCashNums__c) + CommUtils.nullToZero(cash.FiveCashNums__c);
				sItem.OneCashNums__c = CommUtils.nullToZero(sItem.OneCashNums__c) + CommUtils.nullToZero(cash.OneCashNums__c);
				*/
				// 2016/07/15 トランスレーション対応  by wx end
				// 準備金
				sItem.ReserveFund__c = CommUtils.nullToZero(sItem.ReserveFund__c) + CommUtils.nullToZero(cash.ReserveFund__c);
			}
			// 2017/07/11 POSリストの「All」場合、保存可能　by　zy BEGIN
			// 存在posリストの場合、Allの場合、Allのデータあり
			if (!posLst.isEmpty() && CommUtils.isBlank(curPos) && allPosLst.isEmpty()) {
				sItem.id = null;
			}
			// 2017/07/11 POSリストの「All」場合、保存可能　by　zy END
		}
		// 表示情報情報
		// 2017/07/01 device config by zy BEGIN
		cashInfo = new CashBookInfo(sItem,inputInf,inputMachineInf);
		// 2017/08/31 页面抓图機能　by zyz BEGIN
        initExistAttFils(cashInfo.cash.Id);
		// 2017/08/31 页面抓图機能　by zyz END
		// 2017/07/01 device config by zy END
		// 2017/06/08 現金合せ論理値自動更新できるように改善対応 BEGIN
		if (newsCashBookInfo == null) {
		// 2017/06/08 現金合せ論理値自動更新できるように改善対応 END
		//　当日の売上金
		calRsvSalesInfo(rsvId, branchShopNm);
		// 入金
		calDespoitInfo(rsvId, branchShopNm);
		// 出金
		calPaymentInfo(rsvId, branchShopNm);
		// 2017/06/08 現金合せ論理値自動更新できるように改善対応 BEGIN
		} else {
			cashInfo.salesAmount = newsCashBookInfo.salesAmount;
			cashInfo.despAmount = newsCashBookInfo.despAmount;
			cashInfo.payAmount = newsCashBookInfo.payAmount;
		}
		// 2017/06/08 現金合せ論理値自動更新できるように改善対応 END
	}
	
	// 2017/06/08 現金合せ論理値自動更新できるように改善対応 BEGIN
	// 2017/07/01 device config by zy END
	public CashRollupBook(String rsvId, String branchShopNm,String posNo) {
	// 2017/07/01 device config by zy END
		// 格納情報を初期化する
		cashInfo = new CashBookInfo();
		// ユーザー情報初期化する
		userInf = UserUtil.CurrentUserInfo;
		// 2017/07/07 ポースリストの「その他」項目追加　by　zy BEGIN
		String[] posMesLst = CommUtils.nullToBlank(posNo).split(':');
		if (posMesLst != null && !posMesLst.isEmpty()) {
			curPos = posMesLst[0];
       	 	allPosStr = posMesLst[1];
		}
       
		// 2017/07/01 device config by zy BEGIN
		//curPos = posNo;
		// 2017/07/01 device config by zy END
		// 2017/07/07 ポースリストの「その他」項目追加　by　zy END
		//　当日の売上金
		calRsvSalesInfo(rsvId, branchShopNm);
		// 入金
		calDespoitInfo(rsvId, branchShopNm);
		// 出金
		calPaymentInfo(rsvId, branchShopNm);	
	}
	@remoteAction
	public static CashBookInfo autoRefreshLogicInfo(String rsvId, String shopCode,String posNo)  {
		// 初期化する
		// 2017/07/01 device config by zy BEGIN
		CashRollupBook cashRollupCtrl = new CashRollupBook(rsvId, shopCode,posNo);
		// 2017/07/01 device config by zy END
		return cashRollupCtrl.cashInfo;
	}
	
	// 2017/06/08 現金合せ論理値自動更新できるように改善対応 END
	//　指定の売上と店舗コードにより、売上関連金額を計算を行う
	private void calRsvSalesInfo(String rsvId, String shopCode) {
		
		// 指定の売上IDと店舗コードで、支払現金情報を取得する
		// 指定の現金情報を取得する
    	Map<String, Decimal> ttendInfoMap = new Map<String, Decimal>();
    	String medialabel = TTend__c.Field2__c.getDescribe().getName();
    	String cashCode = CommConst.MEDIA_TYPE_CD_01;
    	// 2016/06/10 現金合せ「売上金額」集計ロジック変更対応 BEGIN
    	// 会計単位でグループする
    	// 2017/07/07 ポースリストの「その他」項目追加　by　zy BEGIN
    	String ttendQuery = ' select sum(Field28__c) reciveAmount, sum(Field29__c) realAmount , Field1__r.IsNewLayout__c IsNewLayout , POSNo__c POSNo from TTend__c where RelAccount__c = :rsvId And OutSideAccount__c = 1 And Field2__c = :cashCode And (Field28__c <> 0 or Field29__c <> 0 ) ';
    	// 2017/07/07 ポースリストの「その他」項目追加　by　zy END
    	if (!CommUtils.isBlank(shopCode)) ttendQuery += ' And Field1__r.ShopCode__c = :shopCode ';
		else if (userInf.isShopCodePlex) {
            Set<String> shopSt = userInf.shopSt;
            ttendQuery += ' And Field1__r.ShopCode__c = :shopSt ';
        }
        //2017/06/19 POS選択リストの初期化　by　zy　BEGIN
        if(!CommUtils.isBlank(curPos)) {
        	// 2017/07/07 ポースリストの「その他」項目追加　by　zy BEGIN
        	// 如果posno指定为「その他」の場合
        	if (otherPosValue.equalsIgnoreCase(curPos)) {
        		Set<String> posSet = getPosSet();
        		ttendQuery += ' And POSNo__c not in :posSet ';
        	} else  ttendQuery += ' And POSNo__c = :curPos ';
        	// 2017/07/07 ポースリストの「その他」項目追加　by　zy END
        }
        // 2017/07/07 ポースリストの「その他」項目追加　by　zy BEGIN
        //2017/06/19 POS選択リストの初期化　by　zy　END
        ttendQuery += ' Group by Field1__r.IsNewLayout__c ,POSNo__c';
		// 2017/07/07 ポースリストの「その他」項目追加　by　zy END
		List<AggregateResult> rsAvgs = DataBase.query(ttendQuery);
		if (!rsAvgs.isEmpty()) {
			// 売上の現金情報を取得する
			for (AggregateResult rsAvg : rsAvgs) {
				Boolean newLayout = (Boolean) rsAvg.get('IsNewLayout');
				// 2017/02/27 売上現金の集計値は預かり金額から支払金額に変更（新規会計の場合）BEGIN
				//if (newLayout) {
				//	cashInfo.salesAmount += CommUtils.nullToZero(rsAvg.get('reciveAmount'));
				//} else {
				cashInfo.salesAmount += CommUtils.nullToZero(rsAvg.get('realAmount'));
				//}
			}
		}
    	/*
    	String ttendQuery = ' select sum(Field29__c) amountIncTax , Field2__c from TTend__c where RelAccount__c = :rsvId And OutSideAccount__c = 1 And Field2__c = :cashCode And Field29__c <> 0 ';
    	if (!CommUtils.isBlank(shopCode)) ttendQuery += ' And Field1__r.ShopCode__c = :shopCode ';
    	// 2015/09/01 多店舗機能対応 BEGIN
	else if (userInf.isShopCodePlex) {
            Set<String> shopSt = userInf.shopSt;
            ttendQuery += ' And Field1__r.ShopCode__c = :shopSt ';
        }
	// 2015/09/01 多店舗機能対応 END
    	ttendQuery += ' Group by Field2__c ';
//System.debug(LoggingLevel.INFO, 'ttendQuery::' + ttendQuery);
		List<AggregateResult> rsAvgs = DataBase.query(ttendQuery);
		if (!rsAvgs.isEmpty()) {
			// 売上の現金情報を取得する
			AggregateResult rsAvg = rsAvgs[0];
			cashInfo.salesAmount = CommUtils.nullToZero(rsAvg.get('amountIncTax'));
		}
		// 新会計レイアウトの場合、下記集計を追加する
		if (BillInputSwitchCtrl.isNewAccountLayout()) {
			// 予約金など、事前入金情報の金額を集計する
	    	ttendQuery = ' select sum(Field28__c) amountIncTax , Field2__c from TTend__c where RelAccount__c = :rsvId And OutSideAccount__c = 1 And Field2__c = :cashCode And Field28__c <> 0 And Field29__c = 0 ';
	    	if (!CommUtils.isBlank(shopCode)) ttendQuery += ' And Field1__r.ShopCode__c = :shopCode ';
	    	// 2015/09/01 多店舗機能対応 BEGIN
		else if (userInf.isShopCodePlex) {
	            Set<String> shopSt = userInf.shopSt;
	            ttendQuery += ' And Field1__r.ShopCode__c = :shopSt ';
	        }
		// 2015/09/01 多店舗機能対応 END
	    	ttendQuery += ' Group by Field2__c ';
			rsAvgs = DataBase.query(ttendQuery);
			if (!rsAvgs.isEmpty()) {
				// 売上の現金情報を取得する
				AggregateResult rsAvg = rsAvgs[0];
				cashInfo.salesAmount += CommUtils.nullToZero(rsAvg.get('amountIncTax'));
			}
		}*/
		// 2016/06/10 現金合せ「売上金額」集計ロジック変更対応 END
	}
	// 指定日の入金金額を集計
	private void calDespoitInfo(String rsvId, String shopCode) {
		// 2017/07/13 POS管理入出金显示问题修改 by zy BEGIN
		// 已POS为管理的情况下 可以集计的范围之只能有All，その他
		// 其他posno看到的入出金数据均为0
		if (!CommUtils.isBlank(curPos) && curPos != otherPosValue) {
			cashInfo.despAmount	 = 0;
			return ;
		}
		// 2017/07/13 POS管理入出金显示问题修改 by zy END
		String despQuery = ' Select sum(depositamount__c) amountIncTax from deposit__c where Reldeposit__c = :rsvId ';
		if (!CommUtils.isBlank(shopCode)) despQuery += ' And ShopInfoRef__r.ShopCode__c = :shopCode ';
		// 2015/09/01 多店舗機能対応 BEGIN
		else if (userInf.isShopCodePlex) {
            Set<String> shopSt = userInf.shopSt;
            despQuery += ' And ShopInfoRef__r.ShopCode__c = :shopSt ';
        }
		// 2015/09/01 多店舗機能対応 END
//System.debug(LoggingLevel.INFO, 'despQuery::' + despQuery);
		List<AggregateResult> rsAvgs = DataBase.query(despQuery);
		if (!rsAvgs.isEmpty()) {
			// 入金現金情報を取得する
			AggregateResult rsAvg = rsAvgs[0];
			cashInfo.despAmount	 = CommUtils.nullToZero(rsAvg.get('amountIncTax'));
		}
	}
	// 指定日の出金金額を集計
	private void calPaymentInfo(String rsvId, String shopCode) {
		// 2017/07/13 POS管理入出金显示问题修改 by zy BEGIN
		// 已POS为管理的情况下 可以集计的范围之只能有All，その他
		// 其他posno看到的入出金数据均为0
		if (!CommUtils.isBlank(curPos) && curPos != otherPosValue) {
			cashInfo.payAmount	 = 0;
			return ;
		}
		// 2017/07/13 POS管理入出金显示问题修改 by zy END
		String payQuery = ' Select sum(Pamount__c) amountIncTax from Paymentslip__c where Relpayment__c = :rsvId ';
		if (!CommUtils.isBlank(shopCode)) payQuery += ' And ShopInfoRef__r.ShopCode__c = :shopCode ';
		// 2015/09/01 多店舗機能対応 BEGIN
		else if (userInf.isShopCodePlex) {
            Set<String> shopSt = userInf.shopSt;
            payQuery += ' And ShopInfoRef__r.ShopCode__c = :shopSt ';
        }
		// 2015/09/01 多店舗機能対応 END
//System.debug(LoggingLevel.INFO, 'payQuery::' + payQuery);
		List<AggregateResult> rsAvgs = DataBase.query(payQuery);
		if (!rsAvgs.isEmpty()) {
			// 入金現金情報を取得する
			AggregateResult rsAvg = rsAvgs[0];
			cashInfo.payAmount = CommUtils.nullToZero(rsAvg.get('amountIncTax'));
		}
	}
	// 2016/07/15 トランスレーション対応  by wx begin
	public List<PRICE> inputInf{get; private set;}
	// 2017/08/09 リジェクト部の保存可能追加　by　zy BEGIN
	//画面表示、保存可能、機械有高集計不能
	public List<LABEL> labelInf{get; private set;}
	// 2017/08/09 リジェクト部の保存可能追加　by　zy END
	public void reloadXmlInf(String pShopCode){
		// 変数初期化
		// 現金合わせる入力項目の定義情報を格納する
		inputInf = new List<PRICE>();	
		defaultValueConvertMap = new map<String,Decimal>();
		//2017/06/19 pos別の準備金処理する　by　zy BEGIN
		defaultPosConvertMap = new Map<String,Decimal>();
		//2017/06/19 pos別の準備金処理する　by　zy END
		// 2017/06/22 機械有高可入力機能追加　by　zy　BEGIN
		inputMachineInf = new List<PRICE>();
		// 2017/06/22 機械有高可入力機能追加　by　zy　END
		// 2017/08/09 リジェクト部の保存可能追加　by　zy BEGIN
		labelInf = new List<LABEL>();
		// 2017/08/09 リジェクト部の保存可能追加　by　zy END
		try {
			// 現金合わせ定義情報の取得
        	Dom.XmlNode shopElement =  CommXmlUtils.parseXmlDoc('CashRollupBookSetting', pShopCode);
			// 現金合わせ単位定義情報と初期値設定Node情報を取得する
		    for(Dom.XmlNode modeNode : shopElement.getChildElements()){
				if(modeNode.getName() ==  'PRICE'){
	  				PRICE p = new PRICE(modeNode);
	  				p.elementId = 'priceCustome_' + inputInf.size();
	  				if (!fieldMap.containsKey(p.apiName)) continue;
	  				inputInf.add(p);
  				// 2017/06/22 機械有高可入力機能追加　by　zy　BEGIN
  				} else if (modeNode.getName() ==  'MPRICE') {
  					//TODO 兼容、xml更改
  					PRICE p = new PRICE(modeNode);
					p.elementId = 'priceMachine_' + inputMachineInf.size();
					if (!fieldMap.containsKey(p.apiName)) continue;
					inputMachineInf.add(p);
				// 2017/08/09 リジェクト部の保存可能追加　by　zy BEGIN
  				} else if ( modeNode.getName() ==  'MLABEL' ) {
  					LABEL l  = new LABEL(modeNode);
  					l.elementId = 'labelMachine_' + labelInf.size();
  					labelInf.add(l);
  				// 2017/08/09 リジェクト部の保存可能追加　by　zy END
  				}
  				// 2017/06/22 機械有高可入力機能追加　by　zy　END
  				// 2016/07/29 初期値自動設定機能対応 by zh BEGIN
				if(modeNode.getName() ==  'INIT_CONFIG'){
					for (Dom.XmlNode nodeTag : modeNode.getChildElements()) {
						String apiName = CommUtils.nullToBlank(nodeTag.getAttribute('ApiName',null));
						String strInitVal = CommUtils.nullToBlank(nodeTag.getText());
						if (CommUtils.isBlank(apiName) || CommUtils.isBlank(strInitVal)) continue;
						//pos別の準備金処理する　by　zy BEGIN
						String posNo = nodeTag.getAttribute('PRINTNO',null);
						if (!CommUtils.isBlank(posNo)) {
							apiName = CommUtils.nullToBlank(posNo) + '_' + apiName;
							defaultPosConvertMap.put(apiName,CommUtils.nullToZero(strInitVal));
						} else
						//pos別の準備金処理する　by　zy END
						defaultValueConvertMap.put(apiName, CommUtils.nullToZero(strInitVal));
					}
					//System.debug(LoggingLevel.INFO, 'defaultValueConvertMap::' + defaultValueConvertMap);
  				}
  				// 2016/07/29 初期値自動設定機能対応 by zh END
			}
		} catch (CommException e) {}
		if (inputInf.isEmpty()) {
			string defCurrencySybmol = CommBaseCtrl.getCurrencySybmol();
    		inputInf.add(new PRICE('万',defCurrencySybmol,'TenThousandCashNums__c',10000,0));
    		inputInf.add(new PRICE('5千',defCurrencySybmol,'FiveThousandCashNums__c',5000,1));
    		inputInf.add(new PRICE('2千',defCurrencySybmol,'TwoThousandCashNums__c',2000,2));
    		inputInf.add(new PRICE('千',defCurrencySybmol,'OneThousandCashNums__c',1000,3));
    		inputInf.add(new PRICE('500',defCurrencySybmol,'FiveHundredCashNums__c',500,4));
    		inputInf.add(new PRICE('100',defCurrencySybmol,'OneHundredCashNums__c',100,5));
    		inputInf.add(new PRICE('50',defCurrencySybmol,'FiftyCashNums__c',50,6));
    		inputInf.add(new PRICE('10',defCurrencySybmol,'TenCashNums__c',10,7));
    		inputInf.add(new PRICE('5',defCurrencySybmol,'FiveCashNums__c',5,8));
    		inputInf.add(new PRICE('1',defCurrencySybmol,'OneCashNums__c',1,9));
		}
		// 2017/06/22 機械有高可入力機能追加　by　zy　BEGIN
		if(inputMachineInf.isEmpty()){
			string defCurrencySybmol = CommBaseCtrl.getCurrencySybmol();
			inputMachineInf.add(new PRICE('万',defCurrencySybmol,'TenThousandMachNums__c',10000,10));
    		inputMachineInf.add(new PRICE('5千',defCurrencySybmol,'FiveThousandMachNums__c',5000,11));
    		inputMachineInf.add(new PRICE('2千',defCurrencySybmol,'TwoThousandMachNums__c',2000,12));
    		inputMachineInf.add(new PRICE('千',defCurrencySybmol,'OneThousandMachNums__c',1000,13));
    		inputMachineInf.add(new PRICE('500',defCurrencySybmol,'FiveHundredMachNums__c',500,14));
    		inputMachineInf.add(new PRICE('100',defCurrencySybmol,'OneHundredMachNums__c',100,15));
    		inputMachineInf.add(new PRICE('50',defCurrencySybmol,'FiftyMachNums__c',50,16));
    		inputMachineInf.add(new PRICE('10',defCurrencySybmol,'TenMachNums__c',10,17));
    		inputMachineInf.add(new PRICE('5',defCurrencySybmol,'FiveMachNums__c',5,18));
    		inputMachineInf.add(new PRICE('1',defCurrencySybmol,'OneMachNums__c',1,19));
		}
		if (labelInf.isEmpty()){
			//紙幣在上，硬貨在下
			labelInf.add(new LABEL('紙幣リジェクト件数','','紙幣リジェクト件数','1'));
			labelInf.add(new LABEL('硬貨リジェクト件数','','硬貨リジェクト件数','0'));
		}
		
	}
	//2017/03/17 お釣りプリンター機能　by zy BEGIN
	public String chargeJson{get;set;}
	public Boolean changeSwitch{get;set;}
	private void loadChangeInf(String pShopCode){
		ChangeMachineHelp help = new ChangeMachineHelp(pShopCode,true);
		//2017/07/01 レビュー更新する　by　zy　BEGIN
		//changeSwitch = false;
		//2017/07/01 レビュー更新する　by　zy　END
		Map<String,String> changeMap = help.getPriceMap();
		//2017/07/01 レビュー更新する　by　zy　BEGIN
		for (PRICE p : inputMachineInf) {
		//2017/07/01 レビュー更新する　by　zy　END
			if (changeMap.containsKey(p.apiName))
				p.changeName = changeMap.get(p.apiName);
		}
		// 2017/08/09 リジェクト部の保存可能追加　by　zy BEGIN
		for (LABEL l : labelInf ) {
			if (changeMap.containsKey(l.apiName))
				l.changeName = changeMap.get(l.apiName);
		}
		// 2017/08/09 リジェクト部の保存可能追加　by　zy END
		chargeJson = help.getIpMapJson(ChangeMachineHelp.PAGETYPE_CASH);
		if (!CommUtils.isBlank(chargeJson)) changeSwitch = true;
	}
	//2017/03/17 お釣りプリンター機能　by zy END
	// 初期値情報格納用
	private map<String,Decimal> defaultValueConvertMap;	
	// 2016/07/15 トランスレーション対応 by wx end	
	public CashBookInfo cashInfo{get; set;}
	public class CashBookInfo {
		public CashVerification__c cash{get; private set;}
		// 2016/07/15 トランスレーション対応 by wx begin
		// 2017/07/01 device config by zy BEGIN
		//public CashBookInfo(CashVerification__c ps, List<PRICE> priceDefLst) {
		public CashBookInfo(CashVerification__c ps, List<PRICE> priceDefLst,List<PRICE> machDefLst) {
		// 2017/07/01 device config by zy END
			cash = ps;
			salesAmount = despAmount = payAmount = 0;
			sobject wkCash = (sobject)ps;
			cashActAmount = 0;
			for (PRICE defInf : priceDefLst) {
				
				decimal num = CommUtils.nullToZero(wkCash.get(defInf.apiName));
				decimal unitPrice = CommUtils.nullToZero(defInf.percount);
				cashActAmount += num * unitPrice;
			}
			// 2017/07/01 device config by zy BEGIN
			cashMachAmount = 0;
			for (PRICE defInf : machDefLst) {
				decimal num = CommUtils.nullToZero(wkCash.get(defInf.apiName));
				decimal unitPrice = CommUtils.nullToZero(defInf.percount);
				cashMachAmount += num * unitPrice;
			}
			// 2017/07/01 device config by zy END
		}
		// 2017/06/08 現金合せ論理値自動更新できるように改善対応 BEGIN
		public CashBookInfo () {salesAmount = despAmount = payAmount = 0;}
		// 2017/06/08 現金合せ論理値自動更新できるように改善対応 END
		public Decimal cashActAmount{get;set;}
		// 2016/07/15 トランスレーション対応 by wx end
		// 実績現金有高合計: 実績存在の現金枚数
		public Decimal cashLogicAmount{get{
			return (CommUtils.nullToZero(cash.ReserveFund__c) + salesAmount + despAmount - payAmount);
		}}	// 論理現金有高合計: 売上＋入金＋準備金ー出金＝現金有高
		public Decimal salesAmount{get;set;}	// 売上金額
		public Decimal despAmount {get;set;}	// 入金
		public Decimal payAmount  {get;set;}	// 出金
		
		public Decimal diffAmount {get{
			// 2017/07/01 device config by zy BEGIN
			return(cashActAmount + cashMachAmount - cashLogicAmount);
			// 2017/07/01 device config by zy END
		}}  // 差額
		// 2017/07/01 device config by zy BEGIN
		public Decimal cashMachAmount{get;set;}
		// 2017/07/01 device config by zy END
		
	}
	
	// 検索条件
	public BookingTimeTable__c dateInput{get; set;}
    // 支店選択リスト
    public List<SelectOption> branchShopLst{get; private set;}
    private Map<String,ShopInformation__c> shopInfoMap;
    public String branchShopNm{get; set;}
    public UserUtil.UserShopInfo userInf;
    private void setInitBranShopLst() {
    	userInf = UserUtil.CurrentUserInfo;
        branchShopLst = ShopInfoUtil.getBranchShopLst(userInf.shops);
        shopInfoMap   = ShopInfoUtil.getShopInfoMap(userInf.shops);
        if (!branchShopLst.isEmpty()) {
        	// 顧客に設定する支店で初期値に設定する[2013/06/30]
        	String locShopCode = UserUtil.CurrentUser.ShopCode__c;
        	for (SelectOption s : branchShopLst) {
        		if (s.getValue() == locShopCode) branchShopNm = locShopCode;
        	}
        }
    }
    
    // 支店コードにより、支店関連の情報を取得する
    public void refreshBranShop() {
    	branchShopNm = branchShopNm;
    	// 2017/06/23 device config by zy BEGIN
		initDeviceProcess();
		//既存設備のIP，POSNO取得
		initExitLocalIp();
		initPosNo();
		// 現金情報 
		reloadXmlInf(branchShopNm);
		// 釣銭機の機能
		if (isChangeFlag) loadChangeInf(branchShopNm);
		// 2016/07/15 トランスレーション対応 by wx end
		// 2017/06/23 device config by zy END
    	// 2017/06/08 現金合せ論理値自動更新できるように改善対応 BEGIN
    	//queryInfo();
    	queryInfo(null);
    	// 2017/06/08 現金合せ論理値自動更新できるように改善対応 END
    }
	// 2016/07/15 トランスレーション対応 by wx begin 
	public class PRICE{
		public PRICE(String l,String c,String a,Decimal p,Integer size){
			label = l;
			crrency = c;
			percount = p;
			apiName = a;
			elementId = 'priceCustome_' + size;
			//2017/03/17 お釣りプリンター機能　by zy BEGIN
			changeName = '';
			//2017/03/17 お釣りプリンター機能　by zy END
		}
		public PRICE(Dom.XmlNode priceNode){		
			//Dom.XmlNode priceNode = shopNode.getChildElement('PRICE', null); 
			if (priceNode != null) {
				Dom.XmlNode labelField = priceNode.getChildElement('label', null);
				Dom.XmlNode crrencyField = priceNode.getChildElement('crrency', null);
				Dom.XmlNode apiNameField = priceNode.getChildElement('apiName', null);
				Dom.XmlNode percountField = priceNode.getChildElement('percount', null);    			
				if (labelField != null) label = CommUtils.nullToBlank(labelField.getText());
				if (crrencyField != null) {
					crrency = CommUtils.nullToBlank(crrencyField.getText());
				} else {
					crrency = CommBaseCtrl.getCurrencySybmol();
				}
				if (apiNameField != null) apiName = CommUtils.nullToBlank(apiNameField.getText());
				if (percountField != null) percount = CommUtils.nullToZero(percountField.getText());
			}
		}
		// 货币名	
		public String label{get;set;}
		// 货币符号
		public String crrency{get;set;}	
		//货币值
		public Decimal percount{get;set;}
		// 字段名
		public String apiName{get;set;}
		// html用ID	
		public String elementId{get;set;}
		//2017/03/17 お釣りプリンター機能　by zy BEGIN
		public String changeName{get;set;}
		//2017/03/17 お釣りプリンター機能　by zy END
	}
		// 2016/07/15 トランスレーション対応 by wx end 
	// 2017/06/23 device config by zy BEGIN
	// 2017/06/20 pos別の準備金処理する　by　zy BEGIN
	public void refreshPosNo(){
		// actionfunction更新xml信息，需要重新读取xml
		OrderServiceHelp.setInstance(branchShopNm);
		initPosNo();
		// 現金情報 
		reloadXmlInf(branchShopNm);
		// 釣銭機の機能
		if (isChangeFlag) loadChangeInf(branchShopNm);
		//TODO edit的场合可入力情况考虑
		queryInfo(null);
	}
	private void initPosNo() {
		//如果device没有配置的情况下 零钱机应该默认打开
		//内部判断零件及是否启用
		isChangeFlag = false;
		isEditKikaiFlag = false;
		// 默认非保存模式下，默认写入数据库字段
		// isSaveFlag = false;
		isSaveFlag = true;
		//2017/07/01 レビュー更新する　by　zy　BEGIN
		//外部用零钱机打开flg
		changeSwitch = false;
		/*
		//如果是「その他」情况下不进行切换
		if (curPos == otherPosValue) {
			return;
		}*/
		//2017/07/01 レビュー更新する　by　zy　END
		if (device != null) {
			DeviceConfigHelp.FuncLst func = device.getFuncLstByCurPos(curPos,DeviceConfigHelp.DeviceType.CASH);
			isEditKikaiFlag = func.isEditKikaiFlag;
			isChangeFlag = func.changePrintFlag;
			//必须edit为flase的时候才出现
			isSaveFlag = func.isSaveFlag && !isEditKikaiFlag;
		//没有device配置的时候 关闭釣銭機
		}
		/*
		 else {
			isChangeFlag = false;
		}
system.debug(logginglevel.info,'device2::::' + device);
*/
		// all posの場合
		if (CommUtils.isBlank(curPos) && !posLst.isEmpty()) {
			// all的时候不进行关闭，因allpos情况可保存
			// 所以此处需要修改
			//isEditKikaiFlag = false;
			//如果pos单独设置了零钱机的打开方式，则ALL下不显示，如果是统一设定则显示
			//if (device != null && !device.cashFuncMap.isEmpty()) {
				//isChangeFlag = false;
			//}
		} else {
			OrderServiceHelp.PrintInfo print = OrderServiceHelp.getPrintInfoByPrintNo(curPos);
			//变更POS打印机信息
			refreshPosInfoByPrintNo(print);
		}
		isEditSaveFlag =  (!branchShopLst.isEmpty() && CommUtils.isBlank(branchShopNm)) || 
								//(CommUtils.isBlank(curPos) && !posLst.isEmpty()) || 
									!isCanUpdateLead;
		// 2017/07/11 POSリストの「all」場合、保存可能 追加　by　zy　BEGIN
		if (device != null && !device.isAllPosCanSaveFlag) isEditSaveFlag = isEditSaveFlag || (CommUtils.isBlank(curPos) && !posLst.isEmpty()) ;
		// 2017/07/11 POSリストの「all」場合、保存可能 追加　by　zy　END
//system.debug(logginglevel.info,'isChangeFlag::::' + isChangeFlag);		
	}
	// 2017/06/22 機械有高可入力機能追加　by　zy　BEGIN
	public List<PRICE> inputMachineInf{get; private set;}
	// 2017/06/22 機械有高可入力機能追加　by　zy　END
	private boolean isChangeFlag;
	public boolean isEditKikaiFlag{get;set;}
	//2017/07/01 レビュー更新する　by　zy　BEGIN
	// 保存按钮显示flag
	public boolean isEditSaveFlag{get;set;}
	public boolean isSaveFlag{get;set;}
	private DeviceConfigHelp.DeviceInfo device; 
	//2017/07/01 レビュー更新する　by　zy　END
	private void initDeviceProcess(){
		//変数初期化
		posLst = new List<SelectOption>();
		// ALL店舗対応
		//TODO 无店铺对应，单独pos切换对应
		boolean AllShopFlag = !branchShopLst.isEmpty() && CommUtils.isBlank(branchShopNm);
		if (!AllShopFlag) {
			//店舗切り換える
			device = DeviceConfigHelp.getDevice(branchShopNm);
//system.debug(logginglevel.info,'device1::::' + device);
			// オーダーエンドリの機能開く
			//POS選択リストの初期化
			posLst = DeviceConfigHelp.getPosLst(branchShopNm,DeviceConfigHelp.DeviceType.CASH);
		}
		// 2017/07/07 ポースリストの「その他」項目追加　by　zy BEGIN
		//列表中已存在的posno
		//pos列表以外的数据整合
		//获取posSet
		allPosStr =  '';
		for (SelectOption sec : posLst) {
			allPosStr += sec.getValue() + ',';
		}
		// 2017/07/07 ポースリストの「その他」項目追加　by　zy END
	}
	// 2017/06/23 device config by zy END
	// 2017/06/08 オーダーエンドリの機能追加 by zy BEGIN
	public String localIp{get;set;}
	//2017/07/01 レビュー更新する　by　zy　BEGIN
	transient public String requestJson{get;set;}
	//2017/07/01 レビュー更新する　by　zy　END
	//页面初始化结束后会通过ip获取打印信息（保持只执行一次）
	public void loadOrderInf(){
		requestJson = '';
		//店舗別のオーダー設定取得する
		OrderServiceHelp.PrintInfo print = getPrintInfo(branchShopNm,localIp);
		//更改当前pos信息
		if (print != null) { 
			curPos = print.printNo;
			refreshPosNo();
		// 2017/07/12 查不到的ip算做その他項目　by　zy BEGIN
		} else {
			curPos = otherPosValue;
			refreshPosNo();
		}
		// 2017/07/12 查不到的ip算做その他項目　by　zy END
	}
	private OrderServiceHelp.PrintInfo getPrintInfo(String spcd,String localIp){
		//店舗別のオーダー初期化する
		OrderServiceHelp.setInstance(spcd);
		// 更改为account区分
		return OrderServiceHelp.getPrintByIp(localIp,spcd,OrderServiceHelp.LayoutType.ACCOUNT);
	}
	//根据print信息，进行设备变更
	private void refreshPosInfoByPrintNo(OrderServiceHelp.PrintInfo print){
		// 判定本地IPと設備IP同じ場合
		if(print != null){
			//boolean localDevice = print.deviceUrl== localIp;
			PrintInfo r = new PrintInfo();
			r.content = OrderServiceHelp.getPrintJsons(print,new List<Tran1__c>(),new List<OrderServiceHelp.LayoutType>{OrderServiceHelp.LayoutType.DOOROPEN}, new Map<Id,List<FoodDetail__c>>(), new AccountAcount__c(),null);
			r.print = print.prinUrl;
			r.status = print.statusUrl;
			// 2017/06/12 印刷のメーセッジ追加　by　zy BEGIN
			//r.printMessage = '印刷機：' + CommUtils.nullToBlank(print.printNo);
			r.printTitle = '';
			//opendoorボタン表示
			//通过ip取到的print
			OrderServiceHelp.PrintInfo ipGetPrint = OrderServiceHelp.getPrintByIp(localIp,branchShopNm,OrderServiceHelp.LayoutType.ACCOUNT);
			String curIpPrintno = '';
			if (ipGetPrint != null) curIpPrintno = ipGetPrint.printNo;
			// 如果没有poslst 不需要opendoor
			// 并且pos机的与现在选择的printno相同
			r.localDevice = (!posLst.isEmpty() && curPos == curIpPrintno);
			// 2017/06/12 印刷のメーセッジ追加　by　zy END
			requestJson = JSON.serialize(r);
		}
	}
	class PrintInfo{
		String print;
		String status;
		String content;
		// 2017/06/12 印刷のメーセッジ追加　by　zy BEGIN
		boolean localDevice;
		String printMessage;
		String printTitle;
		// 2017/06/12 印刷のメーセッジ追加　by　zy END
	}
	// 2017/06/08 オーダーエンドリの機能追加 by zy END
	//2017/06/19 POS選択リストの初期化　by　zy　BEGIN
	// 支店選択リスト
    public List<SelectOption> posLst{get; private set;}
    // pos机准备金
    private Map<String,Decimal> defaultPosConvertMap;
    public String curPos{get;set;}
	//2017/06/19 POS選択リストの初期化　by　zy　END
	private void initExitLocalIp(){
		curPos = '';
		if (!posLst.isEmpty()) {
			OrderServiceHelp.PrintInfo print = getPrintInfo(branchShopNm,localIp);
			//更改当前pos信息
			if (print != null) { 
				curPos = CommUtils.nullToBlank(print.printNo);
			// 2017/07/12 查不到的ip算做その他項目　by　zy BEGIN
			// all店铺pos 改为all
			} else if (!branchShopLst.isEmpty() && CommUtils.isBlank(branchShopNm)){
				curPos = '';
			// 无店铺或者all店铺以外的数据进行处理
			} else {
				curPos = otherPosValue;
			}
			// 2017/07/12 查不到的ip算做その他項目　by　zy END
		}
	}
	// 2017/07/07 ポースリストの「その他」項目追加　by　zy BEGIN
	private Set<String> getPosSet(){
		Set<String> posSet = new Set<String>();
		if (!CommUtils.isBlank(allPosStr)) return posSet = new Set<String>(allPosStr.split(','));
		return posSet;
	}
	// 2017/07/07 ポースリストの「その他」項目追加　by　zy END
	private List<CashVerification__c> filterAllPosOrEach(List<CashVerification__c> cashLst) {
		// all店铺下，区分各个shop中的現金データ
		Map<String,List<CashVerification__c>> cashShopMap = new Map<String,List<CashVerification__c>>();
		List<CashVerification__c> filterLst = new List<CashVerification__c>();
		Set<String> hadShopDataSet = new Set<String>();
		for (CashVerification__c cash : cashLst){
			if(!cashShopMap.containsKey(cash.ShopInfoRef__c)) cashShopMap.put(cash.ShopInfoRef__c,new List<CashVerification__c>());
			// 如果posno字段为空则说明此店铺下有all数据
			if (CommUtils.isBlank(cash.POSNo__c)) {
				// 如果存在allpos的数据直接进入结果集不需要进行后续处理
				filterLst.add(cash);
				// 将已经处理过的店铺进行保存，此集合外的 说明没有all店铺数据，仍要用集计的数据
				hadShopDataSet.add(cash.ShopInfoRef__c);
				//找到allpos的数据则可以跳过，以免重复集计
				continue;	
			}
			cashShopMap.get(cash.ShopInfoRef__c).add(cash);
		}
		// pos店铺下没有all数据的进行处理
		for (String key : cashShopMap.keySet()) {
			//不在集合中，说明此店铺下没有allpos的集计数据
			if (!hadShopDataSet.contains(key)) {
				filterLst.addAll(cashShopMap.get(key));
			}
		}
		return filterLst;
	}
	// 2017/08/09 リジェクト部の保存可能追加　by　zy BEGIN
	//画面表示用クラス
	class LABEL{
		public LABEL(Dom.XmlNode priceNode){		
			if (priceNode != null) {
				Dom.XmlNode labelField = priceNode.getChildElement('label', null);
				Dom.XmlNode apiNameField = priceNode.getChildElement('apiName', null);
				Dom.XmlNode changeField = priceNode.getChildElement('change', null);
				if (labelField != null) label = CommUtils.nullToBlank(labelField.getText());
				if (apiNameField != null) apiName = CommUtils.nullToBlank(apiNameField.getText());
				if (changeField != null) changeName = CommUtils.nullToBlank(changeField.getText());
			}
		}
		public LABEL(String labelStr,String name,String chgName,String eleId){
			label = labelStr;
			apiName = null;
			changeName = chgName;
			elementId = 'labelMachine_' + eleId;
		}
		// 货币名	
		public String label{get;set;}
		// 字段名
		public String apiName{get;set;}
		// html用ID	
		public String elementId{get;set;}
		//2017/03/17 お釣りプリンター機能　by zy BEGIN
		public String changeName{get;set;}
		//2017/03/17 お釣りプリンター機能　by zy END
	}
	// 2017/08/09 リジェクト部の保存可能追加　by　zy BEGIN
	// 2017/07/26 4）ログ情報はDBに記載する by zy BEGIN
	@remoteAction
	public static void savePrintLodToDb(String action){
		String curLog = system.now().format('yyyy-MM-dd HH:mm:ss SSS') + '*************現金合わせBEGIN********************\n';
		User u = UserUtil.CurrentUser;
		curLog += 'ユーザ：' + u.name + '（' + u.id +'）\n';
		curLog += action + '\n';
		curLog += system.now().format('yyyy-MM-dd HH:mm:ss SSS') + '*************現金合わせEND  ********************\n';
		CommLogUtils.saveLogToDb(curLog,CommLogUtils.LogType.POS,new List<String>());
	}
	// 2017/07/26 4）ログ情報はDBに記載する by zy END
	// 2017/08/31 页面抓图機能　by zyz BEGIN
    public List<SelectOption> attaList{get;private set;}    // 截图存放
    public String hostName{get{return CommUtils.getHostNameUrl();}}     // File Download Url
	private void initExistAttFils (String cashId) {
        // 添付ファイル
        attaList = new List<SelectOption>();
        if (CommUtils.isBlank(cashId)) return;
        // ALL店舗の場合、表示しない
        if (CommUtils.isBlank(branchShopNm) && branchShopLst.size() > 0) return;
        // 既存ファイルを検索する
        List<Attachment> attachments = [select Id, Name from Attachment where ParentId = :cashId order by CreatedDate desc];
        // 下拉列表显示数据
        if(!attachments.isEmpty()){
            for(Attachment atta : attachments){
                attaList.add(new SelectOption(atta.Id,atta.Name));
            }
        }
	}
	@remoteAction
	public static List<Option> refreshCanvasInfo(Id cashId, String png, String shopName)  {
		// 2018/03/07 Security Check BEGIN
		List<OPTION> rsLst = new List<OPTION>();
		List<String> chkFieldsLst = new List<String>{'body','contenttype','name','parentid'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.Attachment.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(chkFieldsLst, mm)) {
			return rsLst;
		}
		// 2018/03/07 Security Check END
		Attachment attachment = new  Attachment();
		String preFixKey = CommUtils.isBlank(shopName) ? '' : shopName + '_';
		if (!CommUtils.isBlank(cashId) && !CommUtils.isBlank(png)){
			list<String> pngs = png.split(',');
			CashVerification__c cashVerification = [select id,name,LastModifiedBy.Name from CashVerification__c where id=:cashId];
			attachment.ParentId = cashVerification.id;
			attachment.Name = preFixKey + DateTime.now().format('yyyyMMddHHmmssSSS')+'_'+cashVerification.LastModifiedBy.Name;
			attachment.ContentType = 'image/jpeg';
			attachment.Body = EncodingUtil.base64Decode(pngs[1]);
			insert attachment;
		}
        List<Attachment> existAtts = [select Id, Name from Attachment where ParentId = :cashId order by CreatedDate desc];
        // 2018/03/07 Security Check BEGIN
        //List<OPTION> rsLst = new List<OPTION>();
        // 2018/03/07 Security Check END
        for (Attachment att : existAtts) {
            rsLst.add(new OPTION(att.Id, att.Name));
        }
        return rsLst;
	}
	private class OPTION {
	    public OPTION(String pv, String pl) {
	        this.v = pv;
	        this.l = pl;
	    }
	    public string v{get;set;}
	    public string l{get;set;}
	}
	// 2017/08/31 页面抓图機能　by zyz END

}