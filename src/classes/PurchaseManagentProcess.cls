/**
* 買掛手数料計算ロジック、該当ロジックにより、販売手数料、カード利用料は集計する
* 手数料定義情報を取得場所変更を行う
* 2015/12/07 返金情報は手数料計算対象外に設定する
* 2016/03/11 販売手数料は複数定義ロジック判断機能対応
* 2016/03/21 休前日の判断ロジック機能対応
* 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジックの追加
* 2016/07/13 キャンセル料金は別合計して、手数料を計算する
* 2016/07/20 販売手数料抽出条件は売上日からｰ>ご予約チェックアウト日に変更する
* 2016/07/21 キャンセル料金の計算対象はご予約見積明細から取得、計算を行う
* 2017/06/08 AGTごと、ご予約キャンセル料の販売手数料を計算する・しないを切替できるように改善対応
**/
public with sharing class PurchaseManagentProcess {

	public CommLogUtils log{get; private set;}
	
	//public BookingTimeTable__c cond_processdt{get;private set;}
	private final String SalesLoginUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/';
	//
	private final AccountingSyncBatchHelp gConfig;
	// 売上ID
	private final String gRsvAccoutId;
	// 2016/07/07 販売手数料とカード手数料は内訳出力対象外になる BEGIN
	private final Date gSaleDate;
	// 2016/07/07 販売手数料とカード手数料は内訳出力対象外になる END
	// 店舗コード
	private final String gShopCode;
	//
	private final String gShopId;
	// ポイントLEN
	private final Integer gPointLen = CommUtils.getPointLen();
	//
	private final Decimal gTaxRate;
	
	private final String CONST_EVENTSRC_AGT = 'AGT販売手数料';
	private final String CONST_EVENTSRC_CARD = 'CARD手数料';
	// 2016/07/07 販売手数料とカード手数料は内訳出力対象外になる BEGIN
	private final String CONST_MEMO_AGT = '販売手数料';
	private final String CONST_MEMO_CARD = 'カード手数料';
	private final String CONST_CALKBN_ACC = '会計単位';
	private final String CONST_CALKBN_MONTH = '月単位';
	private final String CONST_CALKBN_MONTH_ENDDAY = '月末';
	private final String CONST_CHARGE_TYPE_NORMAL = '手数料';
	private final String CONST_CHARGE_TYPE_PREPAY = '事前決済';
	private final String CONST_CHARGE_TYPE_CANCEL = 'キャンセル料';
	// 2016/07/07 販売手数料とカード手数料は内訳出力対象外になる END
	// UI画面から呼出する？
	/*
	public PurchaseManagentProcess (){
		cond_processdt = new BookingTimeTable__c(Checkinday__c = Date.today());
		setInitBranShopLst();
	}*/
	// バッチスケジュールから呼出する
	// 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジックの追加
	//public PurchaseManagentProcess(String rsvAccId, String shopCode, AccountingSyncBatchHelp config) {
	public PurchaseManagentProcess(Date salesDate, String shopCode, AccountingSyncBatchHelp config) {
		
		//gRsvAccoutId = rsvAccId;
		gSaleDate = salesDate;
		// スケジュール実施開始日
		RsvAccount__c rsv = CommLogicProcess.getRsvAccountInf(gSaleDate);
		gRsvAccoutId = rsv.Id;
		
		gShopCode = shopCode;
		gConfig = config;
		//gShopMap = ShopInfoUtil.getShopInfoMap();
		Map<String,ShopInformation__c> shopMap = ShopInfoUtil.getShopInfoMap();
		gShopId = (shopMap.containsKey(gShopCode) ? shopMap.get(gShopCode).Id : null);
		
		JMST__c taxMst = CommLogicProcess.getTaxRateInfo();
		gTaxRate = CommUtils.nullToZero(taxMst.TaxRate__c);
		
		log = new CommLogUtils('PurchaseManagentProcess', true);
	}

    public ResultInfo clearExistDate() {
    	// 処理結果情報を格納する
		ResultInfo retRs = new ResultInfo();
    	// 2019/09/15 Security Check BY zyz BEGIN
    	if (!CommSecurityUtils.isDeleteable(Purchase__c.getSObjectType())) {
    		return retRs;
    	}
    	if (!CommSecurityUtils.isDeleteable(Classification__c.getSObjectType())) {
    		return retRs;
    	}
    	// 2019/09/15 Security Check BY zyz END
		// Log Clear
		log.clear();
		log.write_method_start('既存仕入情報削除（販売手数料、カード手数料）');
    	// 同じ売上、同じ店舗、同じ発生源の既存情報を削除する
    	String deleteQuery = 'select id from Purchase__c where JinyaRevenue__c =:gRsvAccoutId  And (EventSource__c = :CONST_EVENTSRC_AGT OR EventSource__c = :CONST_EVENTSRC_CARD) ';
    	if (!CommUtils.isBlank(gShopCode)) deleteQuery+= ' And ShopInfoRef__r.ShopCode__c = :gShopCode for update ';
    	//DataBase.delete();
    	List<Sobject> existRsList = DataBase.query(deleteQuery);
		// 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジックの追加 BEGIN
    	if (!existRsList.isEmpty()) delete existRsList;
    	// 仕訳に格納している
		deleteQuery = 'select id from Classification__c where RsvAccountRef__c =:gRsvAccoutId  And (EventSource__c = :CONST_EVENTSRC_AGT OR EventSource__c = :CONST_EVENTSRC_CARD) ';
    	if (!CommUtils.isBlank(gShopCode)) deleteQuery+= ' And ShopInfoRef__r.ShopCode__c = :gShopCode for update ';
    	List<Sobject> existRsList2 = DataBase.query(deleteQuery);
    	if (!existRsList2.isEmpty()) delete existRsList2;
		// 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジックの追加 END
		// 処理情報を記録する
		retRs.rsNums = existRsList.size();
		log.write_method_end();
		return retRs;
    }
    
	// 指定の期間の売上関連のネットAGTの販売手数料情報を集計する
	public ResultInfo generalNetAgtSalesRate() {
		// 処理結果情報を格納する
		ResultInfo retRs = new ResultInfo();
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'salesorgamount__c','salesamount__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.Classification__c.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(chkFieldsLst, mm)) {
			return retRs;
		}
		// 2019/09/15 Security Check BY zyz END
		// Log Clear
		log.clear();
		log.write_method_start('AGTの販売手数料情報集計');
		// 指定の売上日単位で、ネットAGTの
		// 旅行会社項目あり、かつ　該当取引先　OR　親の取引先は　「NULL　OR　旅行会社」の場合、旅行会社として、認識する
		// 会計明細のプラン項目　かつ　
		// VOIDフラグ
		String accVoidVal = CommConst.ACC_TRADE_VOID;
		String actTypePlan = CommConst.PROD_ACTION_TYPE_PL;
		Integer cancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
		// 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジックの追加 BEGIN
		// キャンセル料金の会計商品コード
		set<string> cancelProductCdSet = gConfig.agtSalesRateConf.cancelProductCdSet;
		// 事前決済情報
		map<string,decimal> prePaymentInfoMap = gConfig.agtSalesRateConf.prePaymentInfoMap;
		map<string,string> relPrePaymentInfoMap = gConfig.agtSalesRateConf.relPrePaymentInfoMap;
		set<string> prePaymentChkSet = new set<string>();
		// 事前決済商品情報を格納する
		if (!prePaymentInfoMap.isEmpty()) prePaymentChkSet.addAll(prePaymentInfoMap.keySet());
		if (!relPrePaymentInfoMap.isEmpty()) prePaymentChkSet.addAll(relPrePaymentInfoMap.keySet());
System.debug(loggingLevel.INFO, 'cancelProductCdSet:::' + cancelProductCdSet);
System.debug(loggingLevel.INFO, 'prePaymentInfoMap:::' + prePaymentInfoMap);
		// 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジックの追加 END
		// 指定の販売先
		String querySQL = 'select id,Field53__c,frs__c,'
						+ 'Relreserve__r.SalesOfficeInfoRef__c, '
						+ 'Relreserve__r.SalesOfficeInfoRef__r.Name, '
						+ 'Relreserve__r.SalesOfficeInfoRef__r.ParentId, '
						+ 'Relreserve__r.Relcontact__r.AccountId, '
						//+ 'Relreserve__r.SalesOfficeInfoRef__r.parentid, '
						//+ 'Relreserve__r.SalesOfficeInfoRef__r.AgtSaleRate__c, '
						//+ 'Relreserve__r.SalesOfficeInfoRef__r.parent.AgtSaleRate__c, '
						+ 'Relreserve__r.SalesOfficeInfoRef__r.RoundType__c, '
						// 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジックの追加 BEGIN
						+ 'Relreserve__r.SalesOfficeInfoRef__r.ChargeCalKbnLst__c, '
						+ 'Relreserve__r.SalesOfficeInfoRef__r.ChargeCalDateLst__c, '
						+ 'Relreserve__r.Rroom__r.Name, '
						+ 'Relreserve__r.Relcontact__r.Name, '
						+ '(select '
						+ 'Field7__r.Field3__c, '
						+ 'Field5__c ,'
						+ 'Field23__c '
						+ 'From TranAccount__r '
						+ 'where (ActionType__c = :actTypePlan '
						+ (!cancelProductCdSet.isempty() ? ' Or Field7__r.Field3__c in :cancelProductCdSet ' : '')
						+ ' ) And Field41__c > 0 '
						+ '), '
						+ '(Select '
						+ ' Field28__c, Field29__c, PayProductRef__r.Field3__c From TranTotalfromPay__r Where Field29__c > 0 '//返金対象外
						+ (!prePaymentChkSet.isempty() ? ' And PayProductRef__r.Field3__c in :prePaymentChkSet ' : '')
						+ ')'
						+ 'from AccountAcount__c ';
		// Where Condition
		// 2016/03/11 販売手数料は複数定義ロジック判断機能対応 BEGIN
		//String queryWhere = 'where Field39__c != :accVoidVal And frs__c = :gRsvAccoutId and Relreserve__r.SalesOfficeInfoRef__c != null And Field53__c != null ';
		String queryWhere = 'where Field39__c != :accVoidVal And frs__c = :gRsvAccoutId And Field53__c != null ';
		// 請求先　OR　旅行会社は存在場合、
		//queryWhere += ' And (Relreserve__r.SalesOfficeInfoRef__c != null OR Relreserve__r.Relcontact__r.AccountId != null ) ';
		queryWhere += ' And Relreserve__r.SalesOfficeInfoRef__c != null ';
		queryWhere += ' And Relreserve__r.CancelBool__c != :cancelFlg ';
		// 2016/03/11 販売手数料は複数定義ロジック判断機能対応 END
		// 手数料支払
//		queryWhere += ' and Relreserve__r.SalesOfficeInfoRef__r.PayChargeFlg__c = true ';
		// 指定の店舗情報が存在すると、個別の店舗
		if(!CommUtils.isBlank(gShopCode)) queryWhere += ' And ShopCode__c = :gShopCode ';
		// 旅行会社種別追加制御がある場合
		if (!Commutils.isBlank(gConfig.agtSalesRateConf.dataFilterStr)) queryWhere += gConfig.agtSalesRateConf.dataFilterStr;
		// 会計済み会計関連の予約の取引先ID一覧を取得する
		// ********************[定数料定義情報を見える]********************
		
		set<id> locAccIdsSet = new set<id>();
		/* 2016/03/11 DELETE
		String queryQuery = 'select id,Relreserve__r.SalesOfficeInfoRef__c from AccountAcount__c ' + queryWhere;
		for (AccountAcount__c acc : DataBase.query(queryQuery)) {
			locAccIdsSet.add(acc.Relreserve__r.SalesOfficeInfoRef__c);
		}*/
		// 2016/03/11 販売手数料は複数定義ロジック判断機能対応 BEGIN
		// map<会計ID、list<取引先ID>>
		map<Id,list<Id>> agtTesuryoAccIdMap = new map<Id,list<Id>>();
		// map<会計ID、手数料定義情報>
		map<Id,ChargeInfo__c> agtTesuryoInfMap = new map<Id, ChargeInfo__c>();
		
		String queryAllStr = querySQL + queryWhere;
System.debug(loggingLevel.INFO, 'queryAllStr::' + queryAllStr);
		List<AccountAcount__c> accs = DataBase.query(queryAllStr);
		// 会計関連の取引先情報を取得する
		for (AccountAcount__c acc : accs) {
			// プラン明細対象が非存在場合、処理対象外
			if (acc.TranAccount__r.isEmpty()) continue;
			// お客様にリンクする取引先のID情報を格納する
			//if (acc.Relreserve__r.Relcontact__r.AccountId != null) {
			//	agtTesuryoAccIdMap.put(acc.Id, new list<id>{acc.Relreserve__r.Relcontact__r.AccountId});
			//} else 
			if (acc.Relreserve__r.SalesOfficeInfoRef__c != null) {
				// 旅行会社　OR　旅行会社の親会計のID情報を格納
				agtTesuryoAccIdMap.put(acc.Id, new list<id>{acc.Relreserve__r.SalesOfficeInfoRef__c});
				if (acc.Relreserve__r.SalesOfficeInfoRef__r.ParentId != null) {
					agtTesuryoAccIdMap.get(acc.Id).add(acc.Relreserve__r.SalesOfficeInfoRef__r.ParentId);
				}
			}
		}
		// 販売手数料計算の取引先情報が存在する場合
		if (!agtTesuryoAccIdMap.isEmpty()) {
			// 会計単位の販売レートを取得する
			agtTesuryoInfMap = calSalesAgtTesuryoInfo(agtTesuryoAccIdMap);
		} 
		//else {return retRs;}
		/*  DELETE
		map<id, ChargeInfo__c> chargeInfomap = AccountingSyncBatchHelp.getChargeInfoByAccount(new List<Id>(locAccIdsSet));
		// 手数料設定情報見ながら、関連の会計データの販売手数料を計算を行う
		set<id> outputAccIds = new set<id>();
		for (ChargeInfo__c  chargeInfo : chargeInfomap.values()) {
			if (chargeInfo.PayChargeFlg__c) outputAccIds.add(chargeInfo.AccountRef__c);
		}*/
		// ********************[定数料定義情報を見える]********************
		/*  DELETE
		// 定数料定義情報がない場合、処理中止
		if (outputAccIds.isEmpty()) return retRs;
		// 計算対象は条件に入れる
		queryWhere += ' And Relreserve__r.SalesOfficeInfoRef__c in :outputAccIds ';
		// 並び順：会計名
		queryWhere += ' Order By Name';	
		// 検索情報
		String queryStr = querySQL + queryWhere;
		// 処理対象外旅行会社IDを格納する
		Set<Id> noTargetSet = new Set<Id>();
		*/
		// 仕入データの新規作成
		List<Purchase__c> insertPurLst = new List<Purchase__c>();
		// 仕訳データの新規作成
		List<Classification__c> insertClassLst = new list<Classification__c>();
		boolean noTaxFlg = gConfig.agtSalesRateConf.noTaxTargetFlg;
		// 日単位の利用明細[AGT]単位
		// 2016/07/21 キャンセル料金の計算対象はご予約見積明細から取得、計算を行う END
		for (AccountAcount__c acc : accs) {
			// プラン明細対象が非存在場合、処理対象外
			// 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジックの追加 BEGIN
			//if (acc.TranAccount__r.isEmpty()) continue;
//System.debug(loggingLevel.INFO, 'prePaymentChkSet:::' + prePaymentChkSet);
//System.debug(loggingLevel.INFO, 'acc.TranTotalfromPay__r:::' + acc.TranTotalfromPay__r);
//System.debug(loggingLevel.INFO, 'acc.TranAccount__r:::' + acc.TranAccount__r);
//System.debug(loggingLevel.INFO, 'agtTesuryoInfMap:::' + agtTesuryoInfMap);
			// プラン明細　OR　キャンセル明細　OR　事前決済情報は全部非存在の場合、処理対象外になる
			if ((!prePaymentChkSet.isEmpty() && acc.TranTotalfromPay__r.isEmpty()) && acc.TranAccount__r.isEmpty()) continue;
//System.debug(loggingLevel.INFO, '------- step1-----'+acc.Id);
			// 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジックの追加 END
			/*  DELETE
			// AGT ID
			Id agtId = acc.Relreserve__r.SalesOfficeInfoRef__c;
			//String agtName = acc.Relreserve__r.SalesOfficeInfoRef__r.Name;
			// 販売手数料
			Decimal rate = CommUtils.nullToZero(chargeInfomap.get(acc.Relreserve__r.SalesOfficeInfoRef__c).SalesRate__c) / 100;
			*/
			if (!agtTesuryoInfMap.containsKey(acc.Id)) continue;
			// 手数料情報
			ChargeInfo__c chargeInfo = agtTesuryoInfMap.get(acc.Id);
			// 手数料レート
			Decimal rate = CommUtils.nullToZero(chargeInfo.SalesRate__c) / 100;
			// AGT ID
			Id agtId = chargeInfo.AccountRef__c;
//System.debug(loggingLevel.INFO, 'chargeInfo:::' + chargeInfo);
			// 手数料はNULLの場合、該当AGTの手数料は未設定ため、処理SKIP、エラーメッセージはメール本文に追加する
			if (rate == 0) {
				// 販売定数料なし、次の処理を行う
				continue;
				/*
				if (!noTargetSet.contains(agtId)) {
					// 該当予約に関連付く旅行会社情報の「エージェント販売手数料」を未設定するため、定数料計算対象外になる
					log.write_error('旅行会社の「エージェント販売手数料」を未設定するため、手数料計算対象外になる:' + SalesLoginUrl + acc.Relreserve__r.SalesOfficeInfoRef__c);	
					// ２回以上エラー情報を表示しない様に回避対応
					noTargetSet.add(agtId);
				}*/
			} else {
				// 端数処理区分
				System.RoundingMode roundType = CommUtils.pointRoundMode();
				// 2016/03/11 販売手数料は複数定義ロジック判断機能対応 BEGIN
				//if (acc.Relreserve__r.SalesOfficeInfoRef__r.RoundType__c != null) {
				//	roundType = CommUtils.pointRoundMode(acc.Relreserve__r.SalesOfficeInfoRef__r.RoundType__c);
				//}
				if(!CommUtils.isBlank(chargeInfo.AccountRef__r.RoundType__c)) {
					roundType = CommUtils.pointRoundMode(chargeInfo.AccountRef__r.RoundType__c);
				}
				// 2016/03/11 販売手数料は複数定義ロジック判断機能対応 END
				// 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジックの追加 BEGIN
				// 事前決済利用金額合計する
				map<string, decimal> prePaymentSumMap = new map<string, decimal>();
				// 該当会計支払情報に、事前決済支払情報が存在するがどうか情報を格納する
				// TODO：多数の事前決済情報は会計明細に同時に設定がないの全体条件
				Boolean isIncludePrePayFlg = false;
				for (Ttend__c tend : acc.TranTotalfromPay__r) {
					String keyCode = tend.PayProductRef__r.Field3__c;
					if (CommUtils.isBlank(keyCode)) continue;
					if (prePaymentInfoMap.containsKey(keyCode)) {
						isIncludePrePayFlg = true;
						break;
					}
				}
				for (Ttend__c tend : acc.TranTotalfromPay__r) {
					String keyCode = tend.PayProductRef__r.Field3__c;
					if (CommUtils.isBlank(keyCode)) continue;
					// 該当会計商品コードは事前決済関連の会計支払商品がどうか、例：一休事前決済の場合、一休ポイントも支払手数料計算対象です
					if (!prePaymentInfoMap.containsKey(keyCode)) {
						// 事前決済明細は会計支払に存在　かつ　該当商品コードは事前決済関連の会計商品の場合
						if (isIncludePrePayFlg && relPrePaymentInfoMap.containsKey(keyCode)) {
							// 事前決済の商品コードに転換する（集計するため）
							keyCode = relPrePaymentInfoMap.get(keyCode);
						} else { continue; }
					}
					if (!prePaymentSumMap.containsKey(keyCode)) prePaymentSumMap.put(keyCode, 0);
					prePaymentSumMap.put(keyCode, (prePaymentSumMap.get(keyCode) + CommUtils.nullToZero(tend.Field29__c)));
				}

				Decimal cancelAmount = 0;
				// 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジックの追加 END
				// 会計内部に利用金額を合計する
				Decimal usedAmount = 0;
				// // 2016/07/21 キャンセル料金の計算対象はご予約見積明細から取得、計算を行う BEGIN
				// ご予約側の見積明細設定情報を取得する
				List<Tran1__c> tranLst = acc.TranAccount__r;

				//for (Tran1__c tran : acc.TranAccount__r) {
				for (Tran1__c tran : tranLst) {
				// 2016/07/21 キャンセル料金の計算対象はご予約見積明細から取得、計算を行う END
					// 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジックの追加 BEGIN
					// 現地追加のプランが存在する・しない対応
					String locProductName = CommUtils.nullToBlank(tran.Field5__c);
					// 現地払いの商品は対象外になる
					Boolean targetOutFlg = false;
					for (String noExistKey : gConfig.agtSalesRateConf.targetOutKeywordSet) {
						if (locProductName.contains(noExistKey)) {
							targetOutFlg = true;
							break;
						}
					}
					if (targetOutFlg) continue;
					// 会計商品コードはキャンセル料金の明細に対して、別行に対して、確認する
					String locProductCode = CommUtils.nullToBlank(tran.Field7__r.Field3__c);
					if (cancelProductCdSet.contains(locProductCode)) {
						// キャンセル料金は別明細として、格納する場合
						cancelAmount += CommUtils.nullToZero(tran.Field23__c);
						continue;
					}
					// 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジックの追加 END
					// 利用金額
					usedAmount += CommUtils.nullToZero(tran.Field23__c);
				}
				// キャンセル料金明細、会計明細格納の場合、集計対象外
				if (usedAmount == 0) continue;
				// 手数料を計算する
				Decimal salesRate = CommUtils.RoundProcess(usedAmount * rate, gPointLen, roundType);
				Decimal noTaxSalesRate = noTaxFlg ? salesRate : CommUtils.RoundProcess(salesRate / (1+ gTaxRate/100),gPointLen, roundType);
				// 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジックの追加 BEGIN
				// 月単位の場合、仕訳オブジェクトに格納を行う
				Account accInfo = chargeInfo.AccountRef__r;
				String chargeCalKbn = CommUtils.nullToBlank(accInfo.ChargeCalKbnLst__c);
				if (CommUtils.isBlank(chargeCalKbn) || chargeCalKbn == CONST_CALKBN_ACC) {
				// 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジックの追加 END
					// 仕入情報を作成する
					Purchase__c pru = new Purchase__c(
						// 
						PurchaseType__c = gConfig.agtSalesRateConf.InTypeName,	// 種別
						KamokuLst__c = gConfig.agtSalesRateConf.OuKamoku,		// 科目
						JinyaRevenue__c = gRsvAccoutId,			// 売上
						DenpyoukeiIncTax__c = salesRate,		// 税込金額
						Denpyoukei__c =  noTaxSalesRate,
						ShopInfoRef__c = gShopId,
						Purchasesource__c = agtId,				// 仕入先
						AccountRef__c = acc.Id,
						Memo__c = CONST_MEMO_AGT,
						AccountTimeStamp__c = getDateTimeByStr(acc.Field53__c),
						EventSource__c = CONST_EVENTSRC_AGT,
						NoTaxFlg__c = noTaxFlg
					);
					if (salesRate > 0) insertPurLst.add(pru);
					// キャンセル料金が存在する場合
					if (cancelAmount > 0) {
						Decimal cancelSalesRate = CommUtils.RoundProcess(cancelAmount * rate, gPointLen, roundType);
						Decimal cancelNoTaxSalesRate = noTaxFlg ? cancelSalesRate : CommUtils.RoundProcess(cancelSalesRate / (1+ gTaxRate/100),gPointLen, roundType);
						Purchase__c cancelPru = new Purchase__c(
							// 
							PurchaseType__c = gConfig.agtSalesRateConf.InTypeName,	// 種別
							KamokuLst__c = gConfig.agtSalesRateConf.OuKamoku,		// 科目
							JinyaRevenue__c = gRsvAccoutId,			// 売上
							DenpyoukeiIncTax__c = cancelSalesRate,	// 税込金額
							Denpyoukei__c =  cancelNoTaxSalesRate,
							ShopInfoRef__c = gShopId,
							Purchasesource__c = agtId,				// 仕入先
							AccountRef__c = acc.Id,
							Memo__c = CONST_MEMO_AGT + ' 「キャンセル料」',
							AccountTimeStamp__c = getDateTimeByStr(acc.Field53__c),
							EventSource__c = CONST_EVENTSRC_AGT,
							NoTaxFlg__c = noTaxFlg
						);
						if (cancelSalesRate > 0) insertPurLst.add(cancelPru);
					}
					// 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジックの追加 BEGIN
					for (String keyCode : prePaymentSumMap.keySet()) {
						// 支払商品コード単位の合計値から手数料を取得、格納する
						Decimal preRate = prePaymentInfoMap.get(keyCode) / 100;
						// 利用金額を取得する
						Decimal preUsedAmount = prePaymentSumMap.get(keyCode);
						// 手数料金額を計算を行う
						Decimal preSalesRate = CommUtils.RoundProcess(preUsedAmount * preRate, gPointLen, roundType);
						Decimal preNoTaxSalesRate = noTaxFlg ? preSalesRate : CommUtils.RoundProcess(preSalesRate / (1+ gTaxRate/100),gPointLen, roundType);
						// 仕入情報を作成する
						Purchase__c prePru = new Purchase__c(
							// 
							PurchaseType__c = gConfig.agtSalesRateConf.InTypeName,	// 種別
							KamokuLst__c = gConfig.agtSalesRateConf.OuKamoku,		// 科目
							JinyaRevenue__c = gRsvAccoutId,			// 売上
							DenpyoukeiIncTax__c = preSalesRate,		// 税込金額
							Denpyoukei__c =  preNoTaxSalesRate,
							ShopInfoRef__c = gShopId,
							Purchasesource__c = agtId,				// 仕入先
							AccountRef__c = acc.Id,
							Memo__c = CONST_MEMO_AGT + ' 「事前決済」',
							AccountTimeStamp__c = getDateTimeByStr(acc.Field53__c),
							EventSource__c = CONST_EVENTSRC_AGT,
							NoTaxFlg__c = noTaxFlg
						);
						if (preSalesRate > 0) insertPurLst.add(prePru);
					}
				
				} else if (chargeCalKbn == CONST_CALKBN_MONTH) {
					String memoStr = '部屋：' + CommUtils.nullToBlank(acc.Relreserve__r.Rroom__r.Name) + ' ' +
									 '氏名：' + CommUtils.nullToBlank(acc.Relreserve__r.Relcontact__r.Name);	 
					// 仕訳オブジェクトに該当手数料情報を設定する
					Classification__c clsif = new Classification__c(
						RsvAccountRef__c = gRsvAccoutId,		// 売上
						AccountAcountRef__c = acc.Id,			// 会計
						SalesDotCom__c = agtId,					// AGT（取引先）
						DebitName__c = gConfig.agtSalesRateConf.InTypeName,
						CreditName__c = gConfig.agtSalesRateConf.OuKamoku,
						Description__c = memoStr,
						SalesAmount__c = salesRate,
						SalesOrgAmount__c = usedAmount,
						ShopInfoRef__c = gShopId,
						SalesRate__c = CommUtils.nullToZero(chargeInfo.SalesRate__c),
						BookingName__c = acc.Relreserve__c,
						EventSource__c = CONST_EVENTSRC_AGT,
						ChargeTypeLst__c = CONST_CHARGE_TYPE_NORMAL
					);
					if (salesRate > 0) insertClassLst.add(clsif);
					// キャンセル料金が存在する場合
					if (cancelAmount > 0) {
						Decimal cancelSalesRate = CommUtils.RoundProcess(cancelAmount * rate, gPointLen, roundType);
						// 仕訳オブジェクトに該当手数料情報を設定する
						Classification__c cancelClsif = new Classification__c(
							RsvAccountRef__c = gRsvAccoutId,			// 売上
							AccountAcountRef__c = acc.Id,			// 会計
							SalesDotCom__c = agtId,					// AGT（取引先）
							DebitName__c = gConfig.agtSalesRateConf.InTypeName,
							CreditName__c = gConfig.agtSalesRateConf.OuKamoku,
							Description__c = memoStr + ' 「キャンセル料」',
							SalesAmount__c = cancelSalesRate,
							SalesOrgAmount__c = cancelAmount,
							ShopInfoRef__c = gShopId,
							SalesRate__c = CommUtils.nullToZero(chargeInfo.SalesRate__c),
							BookingName__c = acc.Relreserve__c,
							EventSource__c = CONST_EVENTSRC_AGT,
							ChargeTypeLst__c = CONST_CHARGE_TYPE_CANCEL
						);
						if (cancelSalesRate > 0) insertClassLst.add(cancelClsif);
					}
					for (String keyCode : prePaymentSumMap.keySet()) {
						// 支払商品コード単位の合計値から手数料を取得、格納する
						Decimal preOrgRate = prePaymentInfoMap.get(keyCode);
						Decimal preRate = preOrgRate / 100;
						// 利用金額を取得する
						Decimal preUsedAmount = prePaymentSumMap.get(keyCode);
						// 手数料金額を計算を行う
						Decimal preSalesRate = CommUtils.RoundProcess(preUsedAmount * preRate, gPointLen, roundType);
						// 仕入情報を作成する
						Classification__c preClsif = new Classification__c(
							RsvAccountRef__c = gRsvAccoutId,		// 売上
							AccountAcountRef__c = acc.Id,			// 会計
							SalesDotCom__c = agtId,					// AGT（取引先）
							DebitName__c = gConfig.agtSalesRateConf.InTypeName,
							CreditName__c = gConfig.agtSalesRateConf.OuKamoku,
							Description__c = memoStr + ' 「事前決済」',
							SalesAmount__c = preSalesRate,
							SalesOrgAmount__c = preUsedAmount,
							ShopInfoRef__c = gShopId,
							SalesRate__c = preOrgRate,
							BookingName__c = acc.Relreserve__c,
							EventSource__c = CONST_EVENTSRC_AGT,
							ChargeTypeLst__c = CONST_CHARGE_TYPE_PREPAY
						);
						if (preSalesRate > 0) insertClassLst.add(preClsif);
					}
				}
				// 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジックの追加 END
			}
		}
		// キャンセル予約ｎ販賣手数料を計算する
		generalCancelLeadSalesRateInfo(insertPurLst,insertClassLst);
		
		if (!insertPurLst.isEmpty()) insert insertPurLst;
		// 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジックの追加 BEGIN
		if (!insertClassLst.isEmpty()) insert insertClassLst;
		// 月単位の販売手数料を計算して、仕入データを作成する
		list<Purchase__c> totalPurLst = generalSalesRateFromTotal(CONST_EVENTSRC_AGT);
		if (!totalPurLst.isEmpty()) insert totalPurLst;
		// 処理情報を記録する
		//retRs.rsNums = insertPurLst.size();
		retRs.rsNums = insertPurLst.size() + totalPurLst.size();
		// 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジックの追加 END
		log.write_method_end();
		return retRs;
	}
	// 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジックの追加 BEGIN
	// キャンセルされた予約に対して、キャンセルルール適応する場合、該当予約見積明細の販賣手数料も計算対象になる
	private void generalCancelLeadSalesRateInfo (List<Purchase__c> insertPurLst, List<Classification__c> insertClassLst) {
		// 処理日から到着日は同じ日付のキャンセルされた予約情報を取得する
		// 取得の予約情報の項目変更履歴情報を捜す、キャンセルされる時間をみって、最後のキャンセル時間は到着日の間に日数差から
		// 販賣手数料計算対象するがどうか確認する
		// 販賣手数料の％により、見積明細の金額を合計して、販賣手数料を計算を行う
		// キャンセル料会計商品コード
		List<CancelRuleDefine__c> cancelRuleLst = CancelRuleDefineUtil.getCancelRuleDefineByShopCode(gShopCode);
		if (cancelRuleLst.isEmpty()) return;
		// キャンセルフラグ
		Integer cancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
		String actTypePlan = CommConst.PROD_ACTION_TYPE_PL;
		// キャンセル商品コード
		set<string> cancelProductCdSet = gConfig.agtSalesRateConf.cancelProductCdSet;
		// グループ単位の予約情報は配列に格納する
		String cancelFieldKey = (CommConst.APPOTION_NAMESPACE + 'ReservedStatus__c');
		// 到着日は処理日と同じのキャンセルの予約情報を取得する
		String queryDataStr = 'select id, LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c,EntryTime__c';
		queryDataStr += ',(select id from BookingEstimateItemFgKu__r where ParentBookingItemRef__c = null';
		queryDataStr += ' And (ActionType__c = :actTypePlan Or refAccountMaster__r.Field3__c in :cancelProductCdSet))';
		queryDataStr += ',(Select CreatedDate, ParentId, NewValue From Histories Where field = :cancelFieldKey order by CreatedDate desc)';
		queryDataStr += ' from Lead__c Where CancelBool__c = :cancelFlg And SalesOfficeInfoRef__c != null ';
		// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH BEGIN
		// if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI) {
		if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI && !CommConst.BOOKEST_USERDATE_FLG) {
		// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH END
			queryDataStr += ' And DAY_ONLY(convertTimezone(EntryTime__c)) = :gSaleDate ';
		} else {
			queryDataStr += ' And DAY_ONLY(convertTimezone(Departure__c)) = :gSaleDate ';
		}
		if(!CommUtils.isBlank(gShopCode)) queryDataStr += ' And refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c = :gShopCode ';
		// 対象予約情報を取得する
		map<id, lead__c> accIdToLeadInfMap = new map<id, lead__c>();
		for (Lead__c lead : DataBase.query(queryDataStr)) {
			accIdToLeadInfMap.put(lead.Id, lead);
		}
		if (accIdToLeadInfMap.isEmpty()) return;
		// キャンセル予約ID情報を格納する
		set<id> cancelLeadIdSet = accIdToLeadInfMap.keySet();
		// ------------------------------------------------
		// 該当キャンセルされたご予約の項目変更履歴から情報を取得する
		// ------------------------------------------------
		// 該当キーワードを含めすると、キャンセル時間を取得する
		set<string> cancelKeySet = new set<string>{CommConst.LEAD_ST_NOSHOW,CommConst.LEAD_ST_CANCEL};
		// map<予約ID、該当予約の変更履歴[キャンセルのタイミング]>
		map<id,Lead__History> cancelHistoryInfoMap = new map<id, Lead__History>();
		for (lead__c lead : accIdToLeadInfMap.values()) {
			// 該当変更履歴に、キャンセルされる場合、キャンセルルールチェックを行う
			for (Lead__History history : lead.Histories) {
				// キャンセルステータスに変更あり、キャンセルルール適応対象
				if (cancelKeySet.contains(CommUtils.nullToBlank(history.newValue))) {
					if (!cancelHistoryInfoMap.containsKey(history.ParentId)) cancelHistoryInfoMap.put(history.ParentId, history);
				}
			}
		}
if (Test.isRunningTest()) {
	for (lead__c lead : accIdToLeadInfMap.values()) {
		cancelHistoryInfoMap.put(lead.Id, new Lead__History(ParentId = lead.Id,Field = 'ReservedStatus__c'));
	}
}
		// キャンセル履歴に該当予約情報がない場合「項目履歴に予約ステータス項目をチェックしないため」
		if (cancelHistoryInfoMap.isEmpty()) return;
		// 該当会計関連の連泊の予約情報を再取得する
		set<id> leadIndexIdSet = new set<id>();
		set<id> leadIndexSubIdSet = new set<id>();
		set<decimal> groupNoSet = new set<decimal>();
		// ------------------------------------------------
		// 該当予約のキャンセル日の時間により、キャンセルルール適応がどうかチェックする
		// ------------------------------------------------
		// キャンセルルール情報を取得する
		// map<予約ID,キャンセルレート>
		map<Id, decimal> wkCancelRuleTargetMap = new map<id, decimal>();
		// 予約情報のキャンセルルールから販賣手数料計算対象がどうか判断する
		for (Id leadId : cancelHistoryInfoMap.keyset()) {
			// 変更履歴情報
			Lead__History history = cancelHistoryInfoMap.get(leadId);
			// 予約情報
			Lead__c lead = accIdToLeadInfMap.get(leadId);
			// 見積明細が非存在の場合、処理対象外
			if (lead.BookingEstimateItemFgKu__r.isEmpty()) continue;
			// 到着日とキャンセル日情報を取得する　
			Date cancelDate = (history.CreatedDate != null ? history.CreatedDate.date() : null);
if (Test.isRunningTest()) cancelDate = date.today();
			Date entryDate = lead.EntryTime__c.date();
			// キャンセル日から到着日まで日数差を計算する
			Decimal cancelRate = getCancelRateInfo(cancelDate, entryDate);
			if (cancelRate != 0)  wkCancelRuleTargetMap.put(leadId,cancelRate);
			// 該当予約関連関連キャンセルルールを適応の場合、連泊分取得用情報を設定する
			if (wkCancelRuleTargetMap.containsKey(leadId)) {
				leadIndexIdSet.add(lead.LeadIndexRef__c);
				leadIndexSubIdSet.add(lead.LeadIndexSubId__c);
				groupNoSet.add(lead.RoomGroupNo__c);
			}
		}
		// キャンセルルール適応あり場合
		if (wkCancelRuleTargetMap.isEmpty()) return;
		// ------------------------------------------------
		// 1部屋N泊の予約情報を取得する
		// ------------------------------------------------
		map<string,list<lead__c>> groupLeadsMap = new map<string, list<lead__c>>();
		set<string> wkValidateLeadSet = new set<string>();	//有効な予約情報が存在しているグループキーを格納する
		for (Lead__c lead : [select id,LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c,CancelBool__c,SalesOfficeInfoRef__c, SalesOfficeInfoRef__r.ParentId,
								Relcontact__r.Name,Rroom__r.Name,EntryTime__c,
								(Select id,ActionType__c,ProductName__c,refAccountMaster__r.Field3__c,Total__c  From BookingEstimateItemFgKu__r 
								 where ParentBookingItemRef__c = null
								 And (ActionType__c = :CommConst.PROD_ACTION_TYPE_PL Or refAccountMaster__r.Field3__c in :cancelProductCdSet)
								),
								(Select CreatedDate, ParentId, NewValue From Histories Where field = :cancelFieldKey order by CreatedDate desc)
								from Lead__c 
								where
								LeadIndexRef__c in :leadIndexIdSet and
								LeadIndexSubId__c in :leadIndexSubIdSet and
								RoomGroupNo__c in :groupNoSet
								Order By LeadIndexRef__c, LeadIndexSubId__c,RoomGroupNo__c,EntryTime__c
								]) {
			String sampeGroupKey = getKeyOfSameGroupLead(lead.LeadIndexRef__c,lead.LeadIndexSubId__c,lead.RoomGroupNo__c);
			// 予約ステータスは有効な予約情報が存在する場合、対象外
			// キャンセルされた予約は一括キャンセルされない場合、該当１連の予約はキャンセル料金計算対象外
			if (lead.CancelBool__c != CommConst.LEAD_ST_CANCEL_FLG) {
				wkValidateLeadSet.add(sampeGroupKey);
				continue;
			}
			// 該当グループは既に有効な予約情報が存在する場合、処理対象外
			if (wkValidateLeadSet.contains(sampeGroupKey)) continue;
			// 該当予約情報は有効な場合、キャンセル料金計算対象外
			if (!groupLeadsMap.containsKey(sampeGroupKey)) groupLeadsMap.put(sampeGroupKey, new list<lead__c>());
			groupLeadsMap.get(sampeGroupKey).add(lead);
		}
		// N泊の初日分の場合のみ、一括キャンセルされた１部屋N泊のキャンセル料金を計算する
		// ------------------------------------------------
		// 関連の旅行会社関連の手数料情報を取得する
		// ------------------------------------------------
		// 該当予約関連の取引先ID情報[初日の予約ID、販賣手数料]
		map<Id,list<Id>> agtTesuryoAccIdMap = new map<Id,list<Id>>();
		// 予約関連の取引先情報を取得する
		for (Id leadId : wkCancelRuleTargetMap.keySet()) {
			// 関連の予約情報を取得する
			Lead__c lead = accIdToLeadInfMap.get(leadId);
			// TODO:連泊の一括キャンセル対象、再対応？
			// 該当予約情報は計算対象がどうかチェックする
			String sampeGroupKey = getKeyOfSameGroupLead(lead.LeadIndexRef__c,lead.LeadIndexSubId__c,lead.RoomGroupNo__c);
			if (!groupLeadsMap.containsKey(sampeGroupKey)) {
				wkCancelRuleTargetMap.remove(leadId);
				continue;
			}
			// 該当予約はN泊の初日の予約情報がどうか
			Lead__c firstDataLead = groupLeadsMap.get(sampeGroupKey)[0];
			if (firstDataLead.Id != leadId) {
				wkCancelRuleTargetMap.remove(leadId);
				continue;
			}
			// 旅行会社　OR　旅行会社の親会計のID情報を格納
			agtTesuryoAccIdMap.put(firstDataLead.Id, new list<id>{firstDataLead.SalesOfficeInfoRef__c});
			if (firstDataLead.SalesOfficeInfoRef__r.ParentId != null) {
				agtTesuryoAccIdMap.get(firstDataLead.Id).add(firstDataLead.SalesOfficeInfoRef__r.ParentId);
			}
		}
		// 取引先単位に販賣手数料の定義情報を取得する
		map<Id,ChargeInfo__c> agtTesuryoInfMap = new map<Id, ChargeInfo__c>();
		// 販売手数料計算の取引先情報が存在する場合
		if (!agtTesuryoAccIdMap.isEmpty()) {
			// 予約単位の販売レートを取得する
			agtTesuryoInfMap = calCancelLeadSalesAgtTesuryoInfo(agtTesuryoAccIdMap);
		} 
		// 販賣手数料非課税設定
		boolean noTaxFlg = gConfig.agtSalesRateConf.noTaxTargetFlg;
		// 初日レートでキャンセル料金計算モード
		boolean isFirstDayRateFlg = (CommConst.DEF_CANCEL_CALKBN == CommConst.DEF_CANCEL_CALKBN_FIRST);
		// 処理対象グループ情報を格納する　
		map<string,list<Classification__c>> wkDataSaveMap = new map<string, list<Classification__c>>();
		// 処理対象予約情報を計算する
		for (Id leadId : wkCancelRuleTargetMap.keySet()) {
			// 関連の予約情報を取得する
			Lead__c currLead = accIdToLeadInfMap.get(leadId);
			String sampeGroupKey = getKeyOfSameGroupLead(currLead.LeadIndexRef__c,currLead.LeadIndexSubId__c,currLead.RoomGroupNo__c);
			// 初日のご予約情報を取得する
			if (!groupLeadsMap.containsKey(sampeGroupKey)) continue;
			List<Lead__c> relLeadsLst = groupLeadsMap.get(sampeGroupKey);
			// 連泊の初日の予約ID
			Lead__c firstDataLead = relLeadsLst[0];
			Id firstLeadId = firstDataLead.Id;
			// 該当ご予約は販賣手数料は計算対象外の場合
			if (!agtTesuryoInfMap.containsKey(firstLeadId)) continue;
			// 手数料情報
			ChargeInfo__c chargeInfo = agtTesuryoInfMap.get(firstLeadId);
			// 手数料レート
			Decimal rate = CommUtils.nullToZero(chargeInfo.SalesRate__c);
			if (rate <= 0) continue;
			// 取引先情報
			Account accInfo = chargeInfo.AccountRef__r;
			// AGTID
			Id agtId = chargeInfo.AccountRef__c;
			// 手数料集計区分
			String chargeCalKbn = CommUtils.nullToBlank(accInfo.ChargeCalKbnLst__c);
			// 該当予約関連のキャンセル料金合計とプラン明細合計金額
			Decimal usedAmount = 0;
			Decimal cancelAmount = 0;
			// 初日のキャンセルレート
			Decimal firstDateCancelRate = null;
			// N泊合計して、キャンセルレート＊販賣手数料　手数料を計算する　OR　宿泊日単位からキャンセル料金＊販賣手数料　手数料計算を行う
			
			for (Lead__c lead : relLeadsLst) {
				Decimal subUsedAmount = 0;
				Decimal subCancelAmount = 0;
				// キャンセル履歴からキャンセルルールを計算する
				// 見積明細が非存在の場合、処理対象外
				if (lead.BookingEstimateItemFgKu__r.isEmpty()) continue;
				// 該当変更履歴に、キャンセルされる場合、キャンセルルールチェックを行う
				Lead__History history = null;
				for (Lead__History historyItem : lead.Histories) {
					// キャンセルステータスに変更あり、キャンセルルール適応対象
					if (cancelKeySet.contains(CommUtils.nullToBlank(historyItem.newValue))) {
						history = historyItem;
					}
				}
if (Test.isRunningTest()) history = new Lead__History(ParentId = lead.Id,Field = 'ReservedStatus__c');
//System.debug(logginglevel.INFO, 'history:::' + history);
//System.debug(logginglevel.INFO, 'lead:::' + lead);
//System.debug(logginglevel.INFO, 'lead.Histories:::' + lead.Histories);
				if (history == null) continue;
				
				// 到着日とキャンセル日情報を取得する　
				Date cancelDate = (history.CreatedDate != null ? history.CreatedDate.date() : null);
if (Test.isRunningTest()) cancelDate = Date.today();
				Date entryDate = lead.EntryTime__c.date();
				// キャンセル料金レートを取得する
				Decimal cancelRate = getCancelRateInfo(cancelDate, entryDate);
				// 初日のキャンセル率から連泊の販賣手数料を計算する場合、各予約情報に、キャンセルレートを計算する
				if (CommUtils.nullToZero(firstDateCancelRate) > 0 && isFirstDayRateFlg) cancelRate = firstDateCancelRate;
				// キャンセル料金計算対象外の場合、次の予約を計算を行う
//System.debug(logginglevel.INFO, 'cancelRate:[S]::' + cancelRate);
				if (cancelRate == 0) continue;
				// 初日のキャンセル率を設定する
				if (firstDateCancelRate == null) firstDateCancelRate = cancelRate;
//System.debug(logginglevel.INFO, 'cancelRate:[E]::' + cancelRate);
				// 見積明細情報を取得する
				for (BookingEstimateItem__c est : lead.BookingEstimateItemFgKu__r) {
					String locProductName = est.ProductName__c;
					// プラン現地追加の場合、合計対象外になる
					Boolean isNoTargetFlg = false;
					for (String noTargetKey : gConfig.agtSalesRateConf.targetOutKeywordSet) {
						if (locProductName.contains(noTargetKey)) {
							isNoTargetFlg = true;
							break;
						}
					}
					if (isNoTargetFlg) continue;
					// キャンセルとプラン金額を合計して、仕入　OR　仕訳に該当情報を格納する
					// 会計商品コードはキャンセル料金の明細に対して、別行に対して、確認する
					String locProductCode = CommUtils.nullToBlank(est.refAccountMaster__r.Field3__c);
					if (cancelProductCdSet.contains(locProductCode)) {
						// キャンセル料金は別明細として、格納する場合
						subCancelAmount += CommUtils.nullToZero(est.Total__c);
						continue;
					}
					// 利用金額
					subUsedAmount += CommUtils.nullToZero(est.Total__c);
				}
//System.debug(logginglevel.INFO, 'subUsedAmount:[S]::' + subUsedAmount);
				// キャンセル料金のみ存在の場合、処理対象外
				if (subUsedAmount == 0) continue;
				//2017/06/08 AGTごと、ご予約キャンセル料の販売手数料を計算する・しないを切替できるように改善対応 BEGIN
				if (chargeInfo.AccountRef__r.CancelChargeCalFlg__c) continue;
				//2017/06/08 AGTごと、ご予約キャンセル料の販売手数料を計算する・しないを切替できるように改善対応 END
				// キャンセルレートから計算元の
				// TODO 売上日は到着日の場合、と　売上日は出力日の場合
				// 仮に仕訳オブジェクト情報に格納する
				String memoStr = '部屋：' + CommUtils.nullToBlank(lead.Rroom__r.Name) + ' ' +
								 '氏名：' + CommUtils.nullToBlank(lead.Relcontact__r.Name) + ' 「キャンセル販賣手数料」' ;
				Classification__c item = new Classification__c(
					RsvAccountRef__c = gRsvAccoutId,		// 売上
					//AccountAcountRef__c = acc.Id,			// 会計
					SalesDotCom__c = agtId,					// AGT（取引先）
					SalesDotCom__r = accInfo,				// 取引先情報を格納する
					DebitName__c = gConfig.agtSalesRateConf.InTypeName,
					CreditName__c = gConfig.agtSalesRateConf.OuKamoku,
					Description__c = memoStr,
					//SalesAmount__c = salesRate,				// 
					PurchaseDay__c = lead.EntryTime__c.date(),
					SalesOrgAmount__c = subUsedAmount,			// 計算元金額を格納する
					CancelRate__c = cancelRate,					// キャンセル率
					ShopInfoRef__c = gShopId,
					SalesRate__c = CommUtils.nullToZero(rate),	// 手数料レート
					BookingName__c = lead.Id,
					EventSource__c = CONST_EVENTSRC_AGT,
					ChargeTypeLst__c = CONST_CHARGE_TYPE_NORMAL
				);
				if (!wkDataSaveMap.containsKey(sampeGroupKey)) wkDataSaveMap.put(sampeGroupKey, new list<Classification__c>());
				wkDataSaveMap.get(sampeGroupKey).add(item);
			}
		}
		for (String key : wkDataSaveMap.keyset()) {
			// 取引先情報ヲ取得する
			list<Classification__c> wktargetLst = wkDataSaveMap.get(key);
			Classification__c firstInfo = wktargetLst[0];
			Account agtInfo = firstInfo.SalesDotCom__r;
			String chargeCalKbn = CommUtils.nullToBlank(agtInfo.ChargeCalKbnLst__c);
			// 合流して、一括データ加算する場合 [連泊の場合]
			if (isFirstDayRateFlg && wktargetLst.size() > 1 && chargeCalKbn == CONST_CALKBN_MONTH) {
				Classification__c newItem = firstInfo.clone(false,true);
				newItem.SalesOrgAmount__c = 0;
				for (Classification__c item : wktargetLst) {
					newItem.SalesOrgAmount__c  += item.SalesOrgAmount__c;
				}
				wktargetLst.clear();
				wktargetLst.add(newItem);
			}
		}
//System.debug(logginglevel.INFO, 'wkDataSaveMap:::' + wkDataSaveMap);
		// 端数処理区分
		System.RoundingMode roundType = CommUtils.pointRoundMode();
		// 計算元金額からキャンセル
		for (String key : wkDataSaveMap.keyset()) {
			// 取引先情報ヲ取得する
			list<Classification__c> wktargetLst = wkDataSaveMap.get(key);
			Classification__c firstInfo = wktargetLst[0];
			Account agtInfo = firstInfo.SalesDotCom__r;
			String chargeCalKbn = CommUtils.nullToBlank(agtInfo.ChargeCalKbnLst__c);
			if(!CommUtils.isBlank(agtInfo.RoundType__c)) {
				roundType = CommUtils.pointRoundMode(agtInfo.RoundType__c);
			}
			if (CommUtils.isBlank(chargeCalKbn) || chargeCalKbn == CONST_CALKBN_ACC) {
				Decimal wkSalesAmount = 0;
				Decimal wkNoTaxSalesAmount = 0;
				// 仕入に情報を設定する
				for (Classification__c clsInf : wktargetLst) {
					// キャンセルレートからキャンセル後の金額を計算する
					Decimal usedAmount = CommUtils.nullToZero(clsInf.SalesOrgAmount__c);
					Decimal cancelRate = CommUtils.nullToZero(clsInf.CancelRate__c) / 100;
					Decimal salesRate = CommUtils.nullToZero(clsInf.SalesRate__c) / 100;
					// キャンセル後の金額から販賣手数料を計算する
					Decimal cancelAmount = CommUtils.RoundProcess(usedAmount * cancelRate, gPointLen, roundType);
					Decimal salesAmount = CommUtils.RoundProcess(cancelAmount * salesRate, gPointLen, roundType);
					Decimal noTaxSalesRate = (noTaxFlg ? salesAmount : CommUtils.RoundProcess(salesAmount / (1+ gTaxRate/100),gPointLen, roundType));
					wkSalesAmount += salesAmount;
					wkNoTaxSalesAmount += noTaxSalesRate;
				}
				Purchase__c pur = new Purchase__c(
					// 
					PurchaseType__c = gConfig.agtSalesRateConf.InTypeName,	// 種別
					KamokuLst__c = gConfig.agtSalesRateConf.OuKamoku,		// 科目
					JinyaRevenue__c = gRsvAccoutId,			// 売上
					DenpyoukeiIncTax__c = wkSalesAmount,	// 税込金額
					Denpyoukei__c =  wkNoTaxSalesAmount,
					ShopInfoRef__c = gShopId,
					Purchasesource__c = agtInfo.Id,			// 仕入先
					//AccountRef__c = acc.Id,
					LeadRef__c = firstInfo.BookingName__c,
					Memo__c = CONST_MEMO_AGT,
					//AccountTimeStamp__c = getDateTimeByStr(acc.Field53__c),
					EventSource__c = CONST_EVENTSRC_AGT,
					NoTaxFlg__c = noTaxFlg
				);
				if (wkSalesAmount > 0) insertPurLst.add(pur);
			} else {
				// 仕訳に情報を設定する
				for (Classification__c clsInf : wktargetLst) {
					// キャンセルレートからキャンセル後の金額を計算する
					Decimal usedAmount = CommUtils.nullToZero(clsInf.SalesOrgAmount__c);
					Decimal cancelRate = CommUtils.nullToZero(clsInf.CancelRate__c) / 100;
					Decimal salesRate = CommUtils.nullToZero(clsInf.SalesRate__c) / 100;
					// キャンセル後の金額から販賣手数料を計算する
					Decimal cancelAmount = CommUtils.RoundProcess(usedAmount * cancelRate, gPointLen, roundType);
					Decimal salesAmount = CommUtils.RoundProcess(cancelAmount * salesRate, gPointLen, roundType);
					// 仕訳情報を設定する
					clsInf.SalesAmount__c = salesAmount;
					clsInf.SalesOrgAmount__c = cancelAmount;
					insertClassLst.add(clsInf);
				}
			}
		}
	}
	private Decimal getCancelRateInfo (date cancelDate, date entryDate) {
		// キャンセル日から到着日まで日数差を計算する
		Integer betweenDay = cancelDate.daysBetween(entryDate);
		// 翌日に該当予約情報を手動キャンセルする場合
		if (betweenDay == -1 ) betweenDay = 0;
// TODO[]　マナスでも、処理対象になる
		List<CancelRuleDefine__c> cancelRuleLst = CancelRuleDefineUtil.getCancelRuleDefineByShopCode(gShopCode);
		// 計算した日数差はキャンセルルールに適応するがどうかチェックする
		for (CancelRuleDefine__c cancelRule : cancelRuleLst) {
			if (cancelRule.RuleBefDayNums__c == betweenDay) {
				return CommUtils.nullToZero(cancelRule.CancelRate__c);
			}
		}
		return 0;
	}
	private static String getKeyOfSameGroupLead(Id leadIdxId, Id leadSubIdx, Decimal groupNo) {
		return 	  CommUtils.nullToBlank(leadIdxId) 
				+ '_' 
				+ CommUtils.nullToBlank(leadSubIdx) 
				+ '_' 
				+ CommUtils.nullToBlank(groupNo);
	}
	/**
	* 販売手数料定義情報から販売手数料の計算処理を行う
	* RETURN: 指定の予約IDに、関連の販売手数料レートを格納する
	**/
	private map<id,ChargeInfo__c> calCancelLeadSalesAgtTesuryoInfo(map<Id,list<Id>> agtTesuryoAccIdMap) {

		// 会計IDの配列
		set<id> leadIdsSet = agtTesuryoAccIdMap.keySet();
		// 手数料取得予定の取引先IDの配列を取得する
		set<id> agtTesuryoAccIdSet = new set<Id>();
		for (Id leadId : leadIdsSet) {
			for (Id accountId : agtTesuryoAccIdMap.get(leadId)) {
				// 該当会計に関連の取引先ID
				agtTesuryoAccIdSet.add(accountId);
			}
		}
		// 会計情報の販売手数料情報の格納
		// map<会計ID,販売手数料値>
		map<id,ChargeInfo__c> accChargeInfoMap = new map<id, ChargeInfo__c>();
		// 2016/03/23 親関係の手数料は同時に定義されている場合、子取引先の手数料は優先で利用する BEGIN
		// 会計に関連の旅行会社、親旅行会社両方とも手数料を定義されている場合、個旅行会社の手数料は優先で利用するため、該当変数に、指定の会計ー＞関連のmap<子旅行会社ID->手数料,親旅行会社ID→手数料＞情報可能
		// map<会計ID,map<取引先ID、手数料定義>>
		map<id, map<id, ChargeInfo__c>> agtTesuryoSaleToAccMap = new map<Id, map<id, ChargeInfo__c>>();
		// 2016/03/23 親関係の手数料は同時に定義されている場合、子取引先の手数料は優先で利用する END
		// 指定の取引先IDから関連の手数料定義情報を取得する
		// map<取引先ID, list<販売手数料情報>>
		// 2016/03/21 手数料カテゴリ１は抽出条件に追加
		map<id, List<ChargeInfo__c>> chargeInfoMap = AccountingSyncBatchHelp.getChargeInfosByAccount(agtTesuryoAccIdSet, new set<string>{AccountingSyncBatchHelp.TESURYO_DIV_AGT});		
		// 複数の手数料の取引先関連情報を格納する
		map<id, list<ChargeInfo__c>> chargeInfoQueryMap = new map<id, list<ChargeInfo__c>>();
		for (Id accountId : chargeInfoMap.keySet()) {
			// 該当取引先の手数料は複数定義情報が存在する場合、複数定義料関連の判別ロジックを取得する、
			// 該当手数料関連の判別ロジックはXMLに未定義する場合、Defaultは一番目の定義料定義情報を取得、設定する
			if (chargeInfoMap.get(accountId).size() > 1) {
				// 該当取引先関連の販売手数料リスト情報を取得する
				chargeInfoQueryMap.put(accountId, chargeInfoMap.get(accountId));
			}
		}
		// 取引先ー＞複数手数料定義の場合、XMLに指定の判断ロジックにより、会計に紐付く（ご予約経由で）取引先
		if (!chargeInfoQueryMap.isEmpty()) {
			// 手数料項目の「種別」設定内容を取得する
			AccountingSyncBatchHelp accSyncHelp = new AccountingSyncBatchHelp(gShopCode,true);
			// 取引先関連の手数料判断ロジック定義情報を取得する「XML」から
			map<String,AccountingSyncBatchHelp.ChargeLogic> xmlLogicMap = accSyncHelp.agtSalesRateConf.chargeLogicMap;
			// 2016/03/21 休日前関連チェックロジックの対応 BEGIN
			CalendarExtend extCal = new CalendarExtend(true);
			Map<Date, String> locHolidayMap = extCal.holidayMap;
			Set<Date> locHolidaySet = locHolidayMap.keySet();
			// 2016/03/21 休日前関連チェックロジックの対応 END
			// 指定会計のプランの販売金額集計を行う
			//String accVoidVal = CommConst.ACC_TRADE_VOID;
			//String actTypePlan = CommConst.PROD_ACTION_TYPE_PL;
			// 指定の販売先
			String querySQL = 'select id,'
							// 2016/03/21 休日前関連チェックロジックの対応
							+ 'EntryTime__c, '
							+ 'SalesOfficeInfoRef__c, '
							+ 'SalesOfficeInfoRef__r.ParentId '
							+ 'from Lead__c where id in :leadIdsSet '
							+ ' And (SalesOfficeInfoRef__c = :accountId Or SalesOfficeInfoRef__r.ParentId = :accountId)  ';
			// 販売先のカテゴリ判断ロジックにより、会計情報の手数料情報を取得する
			// お客様→取引先情報が存在すると、該当取引先関連の販売手数料を取得、チェックする
			for (Id leadId : chargeInfoQueryMap.keySet()) {
				// 該当予約関連の手数料リスト情報
				List<ChargeInfo__c> chargeNoLst = chargeInfoQueryMap.get(leadId);
				// 該当取引先に定義されている手数料情報リスト
				// 支払手数料フラグはTRUE/FALSEに関して、判断ロジックにより、対象の会計に対して、
				// 支払手数料フラグにより、手数料計算対象、しないを制御する
				// 判断ロジック対象外（判断ロジックはXMLに未定義　OR　一つ手数料情報のみ）に対して、直接手数料定義情報を見る、判断する
				for (ChargeInfo__c chargeInf : chargeNoLst) {
					// 手数料定義のNo名
					String chargeNo = chargeInf.Name;
					// 指定のXML条件を取得して、関連の会計情報を取得する
					AccountingSyncBatchHelp.ChargeLogic chargeLogicCls = xmlLogicMap.get(chargeNo);
					// 該当指定の手数料NOはXMLに未定義する場合、該当会計の販売手数料は手数料定義情報の一番目の手数料を使う
					if (chargeLogicCls == null) continue;
					// 会計定義の情報ため、該当ロジックから予約の検索条件へ転換を行う
					String leadLogicStr = chargeLogicCls.logicStr.replace('Relreserve__r.','');
					// 検索条件を作成する
					String query = querySQL + ' And ' + leadLogicStr;
System.debug(logginglevel.INFO, 'query:::' + query);
					// 該当複数の判断ロジックから手数料情報を取得する
					// 2018/03/07 Security Check BEGIN
					//List<Lead__c> chargeQueryAccLst = DataBase.query(query);
					List<Lead__c> chargeQueryAccLst = DataBase.query(String.escapeSingleQuotes(query));
					// 2018/03/07 Security Check END
//System.debug(logginglevel.INFO, 'chargeQueryAccLst:::' + chargeQueryAccLst);
					// 会計関連の手数料情報を格納する[判断ロジック対象内の会計に対して、支払フラグはFALSEの場合、自動的に、手数料０を設定する]
					for (Lead__c lead : chargeQueryAccLst) {
						
						// 2016/03/21 休前日判断ロジックを追加する BEGIN
						if (chargeLogicCls.befHolidayCheck != null) {
//System.debug(logginglevel.INFO, 'chargeLogicCls.befHolidayCheck:::' + chargeLogicCls.befHolidayCheck);
							// 到着日を取得する
							Date checkInDate = lead.EntryTime__c.date();
//System.debug(logginglevel.INFO, 'checkInDate:::' + checkInDate);
							// 該当営業日は休日前するがどうか、チェックする
							Boolean isBefHoliday = AccountingSyncBatchHelp.isBefHoliday(accSyncHelp.agtSalesRateConf, checkInDate, locHolidaySet);
//System.debug(logginglevel.INFO, 'isBefHoliday:::' + isBefHoliday);
							// 抽出条件は、該当予約の到着日は休日前の場合 || 抽出条件は、該当予約の到着日は休日前以外の場合
							if ((chargeLogicCls.befHolidayCheck && !isBefHoliday)
								||
								(!chargeLogicCls.befHolidayCheck && isBefHoliday)) {
								continue;
							} 
						}
//System.debug(logginglevel.INFO, 'agtTesuryoAccIdMap.containsKey(acc.Id):::' + agtTesuryoAccIdMap.containsKey(acc.Id));
						// 2016/03/21 休前日判断ロジックを追加する END
						
						// 抽出した会計は対象会計　かつ　該当会計の販売手数料の支払フラグはTRUEの場合、手数料情報を該当会計に設定する
						if (agtTesuryoAccIdMap.containsKey(lead.Id)) {
							// 2016/03/23 親関係の手数料は同時に定義されている場合、子取引先の手数料は優先で利用する BEGIN
							// 各会計に関連の複数手数料情報を格納変数初期化
							if (!agtTesuryoSaleToAccMap.containsKey(lead.id)) agtTesuryoSaleToAccMap.put(lead.Id, new map<id, ChargeInfo__c>());
							// 2016/03/23 親関係の手数料は同時に定義されている場合、子取引先の手数料は優先で利用する END
							// 支払フラグ＝TRUEの場合、該当会計は手数料計算対象
							if (chargeInf.PayChargeFlg__c) {
								// 2016/03/23 親関係の手数料は同時に定義されている場合、子取引先の手数料は優先で利用する BEGIN
								//accChargeInfoMap.put(acc.id, chargeInf);
								agtTesuryoSaleToAccMap.get(lead.id).put(chargeInf.AccountRef__c, chargeInf);
								// 2016/03/23 親関係の手数料は同時に定義されている場合、子取引先の手数料は優先で利用する END
							} else {
								// 支払フラグ＝FALSEの場合、該当会計の手数料計算対象外
								ChargeInfo__c cloneChargeInf = chargeInf.clone(false,true);
								cloneChargeInf.SalesRate__c = 0;
								// 2016/03/23 親関係の手数料は同時に定義されている場合、子取引先の手数料は優先で利用する BEGIN
								//accChargeInfoMap.put(acc.id, cloneChargeInf);
								agtTesuryoSaleToAccMap.get(lead.id).put(chargeInf.AccountRef__c, cloneChargeInf);
								// 2016/03/23 親関係の手数料は同時に定義されている場合、子取引先の手数料は優先で利用する END
							}
						}
					}
				}
			}
//System.debug(loggingLevel.INFO,'accChargeInfoMap[muliti]:' + accChargeInfoMap);
		} // END if (!chargeInfoQueryMap.isEmpty())
		// 2016/03/23 親関係の手数料は同時に定義されている場合、子取引先の手数料は優先で利用する BEGIN
		// 親関係の手数料により、各会計に手数料定義情報を設定する
		for (Id leadId : leadIdsSet) {
			// 該当会計関連の手数料が存在する場合
			if (agtTesuryoSaleToAccMap.containsKey(leadId)) {
				map<id, ChargeInfo__c> accountIdChargemap = agtTesuryoSaleToAccMap.get(leadId);
				// 該当会計関連の取引先配列を取得する
				for (Id accountId : agtTesuryoAccIdMap.get(leadId)) {
					// 該当会計の手数料は既に設定済の場合、次の設定が不要
					if (accountIdChargemap.containsKey(accountId)) {
						accChargeInfoMap.put(leadId, accountIdChargemap.get(accountId));
						break;
					}
				}
			}
		}
		// 2016/03/23 親関係の手数料は同時に定義されている場合、子取引先の手数料は優先で利用する END
		// 会計単位の販売手数料提示情報を取得する
		for (Id leadId : leadIdsSet) {
			// 該当会計の手数料は既に設定済[複数判断ロジックから判定済]
			if (accChargeInfoMap.containsKey(leadId)) continue;
			// 該当会計の関連の取引先IDの手数料は未定義の場合、処理SKIP
			list<Id> accountIdLst = agtTesuryoAccIdMap.get(leadId);
			if (accountIdLst == null) continue;
			// 該当会計の関連の取引先IDから関連の販売手数料を取得する
			for (Id accountId : accountIdLst) {
				// 該当会計関連の取引先の手数料定義情報が存在する場合　かつ　
				if (chargeInfoMap.containsKey(accountId)) {
					// 複数の販売手数料の場合、TODO[Defaultの手数料を取得、設定する]
					List<ChargeInfo__c> chargeInfoLst = chargeInfoMap.get(accountId);
					// 該当会計の手数料支払＝TRUEかつ関連の手数料を定義されている場合、手数料レートを設定する
					if(!chargeInfoLst.isEmpty() && chargeInfoLst[0].PayChargeFlg__c) accChargeInfoMap.put(leadId, chargeInfoLst[0]);
					//  該当会計の販売手数料レートを設定済
					break;	
				}
			}
		} // for (Id accId : accIdsSet)
//System.debug(loggingLevel.INFO,'accChargeInfoMap[all]:' + accChargeInfoMap);
		return accChargeInfoMap;
	}
	// 
	// 合計値から販売手数料/カード手数料を取得、仕入にインサートする
	// 明細データの取得期間のは該当予約の出発日は該当処理日
	private list<Purchase__c> generalSalesRateFromTotal(String kbn) {
		
		// 仕入データの新規作成
		List<Purchase__c> insertPurLst = new List<Purchase__c>();
		// 指定期間の会計情報の取引先一覧を取得する、その後、該当取引先の設定により、合計？明細単位で切替して
		// 合計の取引先に対して、集計日をチェックして、該当処理日は集計日の場合、該当取引先から指摘期間の利用料金合計して、手数料を計算を行う
		// 該当利用日から一ヶ月間の会計に関連の旅行会社情報を取得する
		//Date beginDate = gSaleDate.addMonths(-1);
		Integer currMaxDay = Date.daysInMonth(gSaleDate.year(),gSaleDate.month());
		Integer currDayNum = gSaleDate.day();
		// 月末の場合
		Boolean isEndProcessDay = (currMaxDay == currDayNum);
		Date firstDate = Date.newinstance(gSaleDate.year(),gSaleDate.month(),1);
		// 前月の最終日
		Date preMonth = firstDate.addDays(-1);
		// 最大日数:
		Integer preMaxDays = Date.daysInMonth(preMonth.year(),preMonth.month());
		// 処理日の日数と前月の日数を比較して、
		if (preMaxDays >= currDayNum) {
			// 今月の
			firstDate = Date.newinstance(preMonth.year(),preMonth.month(), currDayNum);
		} else {
			// 前月の最後日
			firstDate = Date.newinstance(preMonth.year(),preMonth.month(), preMaxDays);
		}
		// 売上日はチェックイン日一致する場合、抽出条件の日付は１日前に変更が必要
		Date endDate = gSaleDate;
//System.debug(loggingLevel.INFO, 'firstDate='+firstDate);
//System.debug(loggingLevel.INFO, 'endDate='+endDate);
		// 売上日はチェックイン日の場合
		//Boolean isSalesDateCiFlg = CommConst.APPOTION_ACC_SALESDATE_DIV_CODE == CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI;
		//if (isSalesDateCiFlg) {
		//	firstDate = firstDate.addDays(-1);
		//	endDate = endDate.addDays(-1);
		//}
		// 指定期間の仕訳情報を抽出する
		String fromStr = Datetime.newInstance(firstDate.year(),firstDate.month(),firstDate.day()).format('yyyyMMdd');
		String endStr = Datetime.newInstance(endDate.year(),endDate.month(),endDate.day()).format('yyyyMMdd');
		//List<Classification__c> tesuryoLst = [select ]
		String queryHeader = CommSqlUtils.generateQueryString('Classification__c', new string[]{'SalesDotCom__r.ChargeCalDateLst__c','SalesDotCom__r.RoundType__c','RsvAccountRef__r.Salesday__c','BookingName__r.Departure__c'});
		String querySql = queryHeader + ' Where RsvAccountRef__r.Name >= :fromStr And RsvAccountRef__r.Name <= :endStr  ';
		querySql += ' And EventSource__c = :kbn And (SalesDotCom__r.ChargeCalDateLst__c != null And SalesDotCom__r.ChargeCalKbnLst__c = :CONST_CALKBN_MONTH ) ';
		querySql += ' And BookingName__c != null ';
		if(!CommUtils.isBlank(gShopCode)) querySql += ' And ShopInfoRef__r.ShopCode__c = :gShopCode ';
System.debug(loggingLevel.INFO, 'generalSalesRateFromTotal sql='+querySql);
System.debug(loggingLevel.INFO, 'fromStr='+fromStr);
System.debug(loggingLevel.INFO, 'endStr='+endStr);
System.debug(loggingLevel.INFO, 'kbn='+kbn);
		//List<Classification__c> tesuryoLst = DataBase.query(querySql);
		map<id, Account> targetAccInfMap = new map<id, Account>();
		//map<id, Decimal> targetUseAmountMap = new map<id, decimal>();
		// map<取引先ID,map<rate,金額>>
		map<id, map<string,map<decimal, decimal>>> targetRateAndAmountMap = new map<id, map<string,map<decimal, decimal>>>();
		// データ取得、取引先定義情報を分類する　
		List<Classification__c> classInfLst = DataBase.query(querySql);
		// 関連の取引先情報を格納する
		for (Classification__c clsInf : classInfLst) {
			Id accId = clsInf.SalesDotCom__c;
			if (!targetAccInfMap.containsKey(accId)) targetAccInfMap.put(accId, clsInf.SalesDotCom__r);
		}
		map<id, list<date>> accountDateRangeMap = new map<Id, list<date>>();
		// 各取引先のデータ取得対象空間
		for (Account acc : targetAccInfMap.values()) {
			// 指定期間の取引先の手数料集計日は今回処理対象するがどうチェックする
			String claDataKbn = acc.ChargeCalDateLst__c;
			// 指定日の場合、指定の日付は現在月の日付により、大きく場合、月末の日付に認識する
			if (claDataKbn != CONST_CALKBN_MONTH_ENDDAY) {
				integer targetDayNum = CommUtils.nullToIntZero(claDataKbn);
				// 指定の日付は今月の月末の日付により、大きく場合、処理日は今月の最後の日付の場合
				if (targetDayNum > currMaxDay && isEndProcessDay) claDataKbn = CONST_CALKBN_MONTH_ENDDAY;
			}
			// 月末の場合、
			if (claDataKbn == CONST_CALKBN_MONTH_ENDDAY) {
				// 処理日は月末以外の場合
				if (!isEndProcessDay) continue;
			} 
			// 固定の日付を指定の場合、該当日付は処理日の日付と一致すると、出力対象になる
			else {
				integer targetDayNum = CommUtils.nullToIntZero(claDataKbn);
				if (currDayNum != targetDayNum) continue;
			}
			// 該当取引先のチェック期間を設定する
			String wkClaDataKbn = acc.ChargeCalDateLst__c;
			// 月末の集計の場合、
			Date wkBegDate = null;
			Date wkEndDate = null;
			if (wkClaDataKbn == CONST_CALKBN_MONTH_ENDDAY) {
				// チェック期間日付は今月の月末まで、前月の月末の翌日
				wkEndDate = Date.newinstance(gSaleDate.year(),gSaleDate.month(),currMaxDay);
				// 今月の１日
				wkBegDate = Date.newinstance(gSaleDate.year(),gSaleDate.month(),1);
			} else {
				Integer targetDayNum = CommUtils.nullToIntZero(wkClaDataKbn);
				// 処理日は月末　かつ　定義の集計日は今月の最大日により、大きく日付
				if (claDataKbn == CONST_CALKBN_MONTH_ENDDAY) {
					if (preMaxDays > targetDayNum) wkBegDate = Date.newInstance(preMonth.year(),preMonth.month(),targetDayNum).addDays(1);
					else wkBegDate = Date.newInstance(preMonth.year(),preMonth.month(),preMaxDays).addDays(1);
					wkEndDate = gSaleDate;
				} else {
					// 処理日は集計日と一致する場合
					wkBegDate = Date.newinstance(preMonth.year(),preMonth.month(),targetDayNum).addDays(1);
					wkEndDate = gSaleDate;
				}
			}
			/*
			// チェックイン日は売上日の場合
			if (isSalesDateCiFlg) {
				wkBegDate = wkBegDate.addDays(-1);
				wkEndDate = wkEndDate.addDays(-1);
			}*/
			accountDateRangeMap.put(acc.Id, new list<date>());
			list<date> wkDateLst = accountDateRangeMap.get(acc.Id);
			wkDateLst.add(wkBegDate);
			wkDateLst.add(wkEndDate);
		}
		// 期間範囲の取引先
		for (Classification__c cls : classInfLst) {
			// 処理対象の場合
			Id accId = cls.SalesDotCom__c;
			if (!accountDateRangeMap.containsKey(accId)) continue;
			// データ期間チェックする
			list<date> rangeChkDate = accountDateRangeMap.get(accId);
			// 該当予約の出発日は処理対象範囲の場合、該当手数料情報を抽出して、合計する
			Date salesDate = cls.BookingName__r.Departure__c.date();
//System.debug(loggingLevel.INFO, 'salesDate='+salesDate);
//System.debug(loggingLevel.INFO, 'rangeChkDate='+rangeChkDate);
			if (rangeChkDate[0] > salesDate || salesDate > rangeChkDate[1]) continue;
//System.debug(loggingLevel.INFO, 'RANGE='+salesDate);
			// 合計処理
			if (!targetAccInfMap.containsKey(accId)) targetAccInfMap.put(accId, cls.SalesDotCom__r);
			if (!targetRateAndAmountMap.containsKey(accId)) targetRateAndAmountMap.put(accId, new map<string,map<decimal,decimal>>());
			map<string,map<decimal,decimal>> typeRateAndAmontMap = targetRateAndAmountMap.get(accId);
			String charegeType = cls.ChargeTypeLst__c;
			if (!typeRateAndAmontMap.containsKey(charegeType)) typeRateAndAmontMap.put(charegeType, new map<decimal,decimal>());
			//targetUseAmountMap.put(accId, (targetUseAmountMap.get(accId) + CommUtils.nullToZero(cls.SalesOrgAmount__c)));
			Decimal salesRate = CommUtils.nullToZero(cls.SalesRate__c);
			map<decimal, decimal> rateAndAmountMap = typeRateAndAmontMap.get(charegeType);
			if (!rateAndAmountMap.containsKey(salesRate)) rateAndAmountMap.put(salesRate, 0);
			rateAndAmountMap.put(salesRate, (rateAndAmountMap.get(salesRate) + CommUtils.nullToZero(cls.SalesOrgAmount__c)));
		}
//System.debug(loggingLevel.INFO, 'rateAndAmountMap='+targetRateAndAmountMap);
		// 集計した情報から手数料情報を計算して、仕入にインサートする
		for (Id accId : targetRateAndAmountMap.keySet()) {
//System.debug(loggingLevel.INFO, 'accId='+accId);
			map<string,map<decimal, decimal>> typeRateAndAmountMap = targetRateAndAmountMap.get(accId);
			// 共通合計情報
			Decimal salesRateSum = 0;
			Decimal noTaxSalesRateSum = 0;
			
			String inTypeName = gConfig.agtSalesRateConf.InTypeName;
			String ouTypeName = gConfig.agtSalesRateConf.OuKamoku;
			boolean noTaxFlg = gConfig.agtSalesRateConf.noTaxTargetFlg;
			String memoStr = CONST_MEMO_AGT;
			if (kbn == CONST_EVENTSRC_CARD) {
				inTypeName = gConfig.cardSalesRateConf.InTypeName;
				ouTypeName = gConfig.cardSalesRateConf.OuKamoku;
				noTaxFlg = gConfig.cardSalesRateConf.noTaxTargetFlg;			
				memoStr = CONST_MEMO_CARD;
			}
			for (String typeKbn : typeRateAndAmountMap.keySet()) {
				map<decimal,decimal> rateAndAmountMap = typeRateAndAmountMap.get(typeKbn);
//System.debug(loggingLevel.INFO, 'rateAndAmountMap='+rateAndAmountMap);
				for (Decimal rate : rateAndAmountMap.keySet()) {
					Decimal usedAmount = rateAndAmountMap.get(rate);
					Decimal cardRate = rate / 100;
					Account accInf = targetAccInfMap.get(accId);
					// 端数処理区分
					System.RoundingMode roundType = CommUtils.pointRoundMode();
					if (!CommUtils.isBlank(accInf.RoundType__c)) {
						roundType = CommUtils.pointRoundMode(accInf.RoundType__c);
					}
					// 手数料を計算する
					Decimal salesRate = CommUtils.RoundProcess(usedAmount * cardRate, gPointLen, roundType);
					Decimal noTaxSalesRate = (noTaxFlg ? salesRate : CommUtils.RoundProcess(salesRate / (1+ gTaxRate/100),gPointLen, roundType));
					salesRateSum += salesRate;
					noTaxSalesRateSum += noTaxSalesRate;
				}
			}
			// 仕入情報を作成する
			Purchase__c pru = new Purchase__c(
				// 
				PurchaseType__c = inTypeName,	// 種別
				KamokuLst__c = ouTypeName,		// 科目
				JinyaRevenue__c = gRsvAccoutId,			// 売上
				DenpyoukeiIncTax__c = salesRateSum,		// 税込金額
				Denpyoukei__c =  noTaxSalesRateSum,		// 税抜金額
				ShopInfoRef__c = gShopId,
				Purchasesource__c = accId,		// 仕入先
				//AccountRef__c = acc.Id,
				NoTaxFlg__c = noTaxFlg,
				Memo__c = memoStr,
				//AccountTimeStamp__c = getDateTimeByStr(acc.Field53__c),
				AccountTimeStamp__c = System.now(),
				EventSource__c = kbn
			);
			insertPurLst.add(pru);
		}
		return insertPurLst;
	}
	// 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジックの追加 END
	
	/**
	* 販売手数料定義情報から販売手数料の計算処理を行う
	* RETURN: 指定の会計IDに、関連の販売手数料レートを格納する
	**/
	private map<id,ChargeInfo__c> calSalesAgtTesuryoInfo(map<Id,list<Id>> agtTesuryoAccIdMap) {

		// 会計IDの配列
		set<id> accIdsSet = agtTesuryoAccIdMap.keySet();
		// 手数料取得予定の取引先IDの配列を取得する
		set<id> agtTesuryoAccIdSet = new set<Id>();
		for (Id accId : accIdsSet) {
			for (Id accountId : agtTesuryoAccIdMap.get(accId)) {
				// 該当会計に関連の取引先ID
				agtTesuryoAccIdSet.add(accountId);
			}
		}
		// 会計情報の販売手数料情報の格納
		// map<会計ID,販売手数料値>
		map<id,ChargeInfo__c> accChargeInfoMap = new map<id, ChargeInfo__c>();
		// 2016/03/23 親関係の手数料は同時に定義されている場合、子取引先の手数料は優先で利用する BEGIN
		// 会計に関連の旅行会社、親旅行会社両方とも手数料を定義されている場合、個旅行会社の手数料は優先で利用するため、該当変数に、指定の会計ー＞関連のmap<子旅行会社ID->手数料,親旅行会社ID→手数料＞情報可能
		// map<会計ID,map<取引先ID、手数料定義>>
		map<id, map<id, ChargeInfo__c>> agtTesuryoSaleToAccMap = new map<Id, map<id, ChargeInfo__c>>();
		// 2016/03/23 親関係の手数料は同時に定義されている場合、子取引先の手数料は優先で利用する END
		// 指定の取引先IDから関連の手数料定義情報を取得する
		// map<取引先ID, list<販売手数料情報>>
		// 2016/03/21 手数料カテゴリ１は抽出条件に追加
		map<id, List<ChargeInfo__c>> chargeInfoMap = AccountingSyncBatchHelp.getChargeInfosByAccount(agtTesuryoAccIdSet, new set<string>{AccountingSyncBatchHelp.TESURYO_DIV_AGT});		
		// 複数の手数料の取引先関連情報を格納する
		map<id, list<ChargeInfo__c>> chargeInfoQueryMap = new map<id, list<ChargeInfo__c>>();
		for (Id accountId : chargeInfoMap.keySet()) {
			// 該当取引先の手数料は複数定義情報が存在する場合、複数定義料関連の判別ロジックを取得する、
			// 該当手数料関連の判別ロジックはXMLに未定義する場合、Defaultは一番目の定義料定義情報を取得、設定する
			if (chargeInfoMap.get(accountId).size() > 1) {
				// 該当取引先関連の販売手数料リスト情報を取得する
				chargeInfoQueryMap.put(accountId, chargeInfoMap.get(accountId));
			}
		}
		// 取引先ー＞複数手数料定義の場合、XMLに指定の判断ロジックにより、会計に紐付く（ご予約経由で）取引先
		if (!chargeInfoQueryMap.isEmpty()) {
			// 手数料項目の「種別」設定内容を取得する
			AccountingSyncBatchHelp accSyncHelp = new AccountingSyncBatchHelp(gShopCode,true);
			// 取引先関連の手数料判断ロジック定義情報を取得する「XML」から
			map<String,AccountingSyncBatchHelp.ChargeLogic> xmlLogicMap = accSyncHelp.agtSalesRateConf.chargeLogicMap;
			// 2016/03/21 休日前関連チェックロジックの対応 BEGIN
			CalendarExtend extCal = new CalendarExtend(true);
			Map<Date, String> locHolidayMap = extCal.holidayMap;
			Set<Date> locHolidaySet = locHolidayMap.keySet();
			// 2016/03/21 休日前関連チェックロジックの対応 END
			// 指定会計のプランの販売金額集計を行う
			//String accVoidVal = CommConst.ACC_TRADE_VOID;
			//String actTypePlan = CommConst.PROD_ACTION_TYPE_PL;
			// 指定の販売先
			String querySQL = 'select id,'
							// 2016/03/21 休日前関連チェックロジックの対応
							+ 'Relreserve__r.EntryTime__c, '
							+ 'Relreserve__r.Relcontact__r.AccountId, '
							+ 'Relreserve__r.SalesOfficeInfoRef__c, '
							+ 'Relreserve__r.SalesOfficeInfoRef__r.ParentId '
							+ 'from AccountAcount__c where id in :accIdsSet '
							+ ' And ('
							+ ' Relreserve__r.Relcontact__r.AccountId = :accountId ' 
								+ ' Or (Relreserve__r.Relcontact__r.AccountId = null'
									+ ' And (Relreserve__r.SalesOfficeInfoRef__c = :accountId Or Relreserve__r.SalesOfficeInfoRef__r.ParentId = :accountId))  '
							+ ')';
			// 販売先のカテゴリ判断ロジックにより、会計情報の手数料情報を取得する
			// お客様→取引先情報が存在すると、該当取引先関連の販売手数料を取得、チェックする
			for (Id accountId : chargeInfoQueryMap.keySet()) {
				List<ChargeInfo__c> chargeNoLst = chargeInfoQueryMap.get(accountId);
				// 該当取引先に定義されている手数料情報リスト
				// 支払手数料フラグはTRUE/FALSEに関して、判断ロジックにより、対象の会計に対して、
				// 支払手数料フラグにより、手数料計算対象、しないを制御する
				// 判断ロジック対象外（判断ロジックはXMLに未定義　OR　一つ手数料情報のみ）に対して、直接手数料定義情報を見る、判断する
				for (ChargeInfo__c chargeInf : chargeNoLst) {
					// 手数料定義のNo名
					String chargeNo = chargeInf.Name;
					// 指定のXML条件を取得して、関連の会計情報を取得する
					AccountingSyncBatchHelp.ChargeLogic chargeLogicCls = xmlLogicMap.get(chargeNo);
					// 該当指定の手数料NOはXMLに未定義する場合、該当会計の販売手数料は手数料定義情報の一番目の手数料を使う
					if (chargeLogicCls == null) continue;
					String query = querySQL + ' And ' + chargeLogicCls.logicStr;
System.debug(logginglevel.INFO, 'query:::' + query);
					// 該当複数の判断ロジックから手数料情報を取得する
					// 2018/03/07 Security Check BEGIN
					//List<AccountAcount__c> chargeQueryAccLst = DataBase.query(query);
					List<AccountAcount__c> chargeQueryAccLst = DataBase.query(String.escapeSingleQuotes(query));
					// 2018/03/07 Security Check END
//System.debug(logginglevel.INFO, 'chargeQueryAccLst:::' + chargeQueryAccLst);
					// 会計関連の手数料情報を格納する[判断ロジック対象内の会計に対して、支払フラグはFALSEの場合、自動的に、手数料０を設定する]
					for (AccountAcount__c acc : chargeQueryAccLst) {
						
						// 2016/03/21 休前日判断ロジックを追加する BEGIN
						if (chargeLogicCls.befHolidayCheck != null) {
//System.debug(logginglevel.INFO, 'chargeLogicCls.befHolidayCheck:::' + chargeLogicCls.befHolidayCheck);
							// 到着日を取得する
							Date checkInDate = acc.Relreserve__r.EntryTime__c.date();
//System.debug(logginglevel.INFO, 'checkInDate:::' + checkInDate);
							// 該当営業日は休日前するがどうか、チェックする
							Boolean isBefHoliday = AccountingSyncBatchHelp.isBefHoliday(accSyncHelp.agtSalesRateConf, checkInDate, locHolidaySet);
//System.debug(logginglevel.INFO, 'isBefHoliday:::' + isBefHoliday);
							// 抽出条件は、該当予約の到着日は休日前の場合 || 抽出条件は、該当予約の到着日は休日前以外の場合
							if ((chargeLogicCls.befHolidayCheck && !isBefHoliday)
								||
								(!chargeLogicCls.befHolidayCheck && isBefHoliday)) {
								continue;
							} 
						}
//System.debug(logginglevel.INFO, 'agtTesuryoAccIdMap.containsKey(acc.Id):::' + agtTesuryoAccIdMap.containsKey(acc.Id));
						// 2016/03/21 休前日判断ロジックを追加する END
						
						// 抽出した会計は対象会計　かつ　該当会計の販売手数料の支払フラグはTRUEの場合、手数料情報を該当会計に設定する
						if (agtTesuryoAccIdMap.containsKey(acc.Id)) {
							// 2016/03/23 親関係の手数料は同時に定義されている場合、子取引先の手数料は優先で利用する BEGIN
							// 各会計に関連の複数手数料情報を格納変数初期化
							if (!agtTesuryoSaleToAccMap.containsKey(acc.id)) agtTesuryoSaleToAccMap.put(acc.Id, new map<id, ChargeInfo__c>());
							// 2016/03/23 親関係の手数料は同時に定義されている場合、子取引先の手数料は優先で利用する END
							// 支払フラグ＝TRUEの場合、該当会計は手数料計算対象
							if (chargeInf.PayChargeFlg__c) {
								// 2016/03/23 親関係の手数料は同時に定義されている場合、子取引先の手数料は優先で利用する BEGIN
								//accChargeInfoMap.put(acc.id, chargeInf);
								agtTesuryoSaleToAccMap.get(acc.id).put(chargeInf.AccountRef__c, chargeInf);
								// 2016/03/23 親関係の手数料は同時に定義されている場合、子取引先の手数料は優先で利用する END
							} else {
								// 支払フラグ＝FALSEの場合、該当会計の手数料計算対象外
								ChargeInfo__c cloneChargeInf = chargeInf.clone(false,true);
								cloneChargeInf.SalesRate__c = 0;
								// 2016/03/23 親関係の手数料は同時に定義されている場合、子取引先の手数料は優先で利用する BEGIN
								//accChargeInfoMap.put(acc.id, cloneChargeInf);
								agtTesuryoSaleToAccMap.get(acc.id).put(chargeInf.AccountRef__c, cloneChargeInf);
								// 2016/03/23 親関係の手数料は同時に定義されている場合、子取引先の手数料は優先で利用する END
							}
						}
					}
				}
			}
//System.debug(loggingLevel.INFO,'accChargeInfoMap[muliti]:' + accChargeInfoMap);
		} // END if (!chargeInfoQueryMap.isEmpty())
		// 2016/03/23 親関係の手数料は同時に定義されている場合、子取引先の手数料は優先で利用する BEGIN
		// 親関係の手数料により、各会計に手数料定義情報を設定する
		for (Id accId : accIdsSet) {
			// 該当会計関連の手数料が存在する場合
			if (agtTesuryoSaleToAccMap.containsKey(accId)) {
				map<id, ChargeInfo__c> accountIdChargemap = agtTesuryoSaleToAccMap.get(accId);
				// 該当会計関連の取引先配列を取得する
				for (Id accountId : agtTesuryoAccIdMap.get(accId)) {
					// 該当会計の手数料は既に設定済の場合、次の設定が不要
					if (accountIdChargemap.containsKey(accountId)) {
						accChargeInfoMap.put(accId, accountIdChargemap.get(accountId));
						break;
					}
				}
			}
		}
		// 2016/03/23 親関係の手数料は同時に定義されている場合、子取引先の手数料は優先で利用する END
		// 会計単位の販売手数料提示情報を取得する
		for (Id accId : accIdsSet) {
			// 該当会計の手数料は既に設定済[複数判断ロジックから判定済]
			if (accChargeInfoMap.containsKey(accId)) continue;
			// 該当会計の関連の取引先IDの手数料は未定義の場合、処理SKIP
			list<Id> accountIdLst = agtTesuryoAccIdMap.get(accId);
			if (accountIdLst == null) continue;
			// 該当会計の関連の取引先IDから関連の販売手数料を取得する
			for (Id accountId : accountIdLst) {
				// 該当会計関連の取引先の手数料定義情報が存在する場合　かつ　
				if (chargeInfoMap.containsKey(accountId)) {
					// 複数の販売手数料の場合、TODO[Defaultの手数料を取得、設定する]
					List<ChargeInfo__c> chargeInfoLst = chargeInfoMap.get(accountId);
					// 該当会計の手数料支払＝TRUEかつ関連の手数料を定義されている場合、手数料レートを設定する
					if(!chargeInfoLst.isEmpty() && chargeInfoLst[0].PayChargeFlg__c) accChargeInfoMap.put(accId, chargeInfoLst[0]);
					//  該当会計の販売手数料レートを設定済
					break;	
				}
			}
		} // for (Id accId : accIdsSet)
//System.debug(loggingLevel.INFO,'accChargeInfoMap[all]:' + accChargeInfoMap);
		return accChargeInfoMap;
	}

	
	// 指定店舗　AND　売上日で、関連のカード支払情報を取得する
	public ResultInfo generalCardSalesRate() {
		// 処理結果情報を格納する
		ResultInfo retRs = new ResultInfo();
		// Log Clear
		log.clear();
		log.write_method_start('カード手数料情報集計');
		// 指定日の会計情報をカードで利用金額を取得する
		String accVoidVal = CommConst.ACC_TRADE_VOID;
		String mediaTypeCdCard= CommConst.MEDIA_TYPE_CD_02;
		String querySQL = 'select id,Field53__c,frs__c,Relreserve__c,'
						+ '( '
						+ 'Select Field2__c, Field29__c, '
						+ 'PayProductRef__c, '
						+ 'PayProductRef__r.CardAccountRef__c, '
						+ 'PayProductRef__r.CardAccountRef__r.Name, '
						//+ 'PayProductRef__r.CardAccountRef__r.CardSalesRate__c, '
						+ 'PayProductRef__r.CardAccountRef__r.ChargeCalKbnLst__c, '
						+ 'PayProductRef__r.CardAccountRef__r.RoundType__c '
						+ 'From TranTotalfromPay__r '
						+ 'where Field2__c = :mediaTypeCdCard '
						// 2015/12/07 返金情報は手数料計算対象外に設定する BEGIN
						+ ' And Field29__c > 0 '
						//+ 'And Field29__c != 0 '
						// 2015/12/07 返金情報は手数料計算対象外に設定する END
						//+ 'And PayProductRef__r.CardAccountRef__r.PayChargeFlg__c = true '
						+ ') '
						+ 'from AccountAcount__c ';
		// Where Condition
		String queryWhere = 'where Field39__c != :accVoidVal And frs__c = :gRsvAccoutId And Field53__c != null ';//!VOID && 会計時間存在
		// 指定の店舗情報が存在すると、個別の店舗
		if(!CommUtils.isBlank(gShopCode)) queryWhere += ' And ShopCode__c = :gShopCode ';
		// 並び順：会計名
		queryWhere += ' Order By Name';	
		// 検索した結果情報を格納する
		List<Purchase__c> insertPurLst = new List<Purchase__c>();
		// 仕訳データの新規作成
		List<Classification__c> insertClassLst = new list<Classification__c>();
		// 日単位の利用明細[AGT]単位
		map<id, list<id>> noPayProductMap = new map<id, list<id>>();
		String queryStr = querySQL + queryWhere;
		// ********************[手数料定義情報を取得]********************
		set<id> locAccIdsSet = new set<Id>();
		list<AccountAcount__c> existAccRs = DataBase.query(queryStr);
		for (AccountAcount__c acc : existAccRs) {
			for (TTend__c ttend : acc.TranTotalfromPay__r) {
				if (ttend.PayProductRef__r.CardAccountRef__c != null) locAccIdsSet.add(ttend.PayProductRef__r.CardAccountRef__c);
			}
		}
		// 手数料定義情報
		// 2016/03/21 手数料カテゴリ１は抽出条件に追加
		//map<id, ChargeInfo__c> chargeInfomap = AccountingSyncBatchHelp.getChargeInfoByAccount(new List<Id>(locAccIdsSet));
		map<id, ChargeInfo__c> chargeInfomap = AccountingSyncBatchHelp.getChargeInfoByAccount(new List<Id>(locAccIdsSet), new set<string>{AccountingSyncBatchHelp.TESURYO_DIV_CARD});
		// ********************[手数料定義情報を取得]********************
		// 重複の提示を回避するため、既にアラトの取引先IDを格納する
		set<id> warngingAccIdSet = new Set<Id>();
		
		//for (AccountAcount__c acc : DataBase.query(queryStr)) {
		for (AccountAcount__c acc : existAccRs) {
			if (acc.TranTotalfromPay__r.isEmpty()) continue;

			map<id, Decimal> cardCompanyMap = new map<id, decimal>();
			map<id, Decimal> cardCompanyRateMap = new map<id, decimal>();
			map<id, String> cardCompanyNameMap = new map<id, string>();
			map<id, Account> cardCompanyInfoMap = new map<id, Account>();
			// 会計内部に利用金額を合計する
			//Decimal usedAmount = 0;
			for (TTend__c ttend : acc.TranTotalfromPay__r) {
				// 該当カード支払は支払商品がない場合
				if (ttend.PayProductRef__c == null) {
					// todo
					log.write_error('該当会計支払の「支払商品」項目を未設定するため、手数料計算対象外になる:' + SalesLoginUrl + ttend.Id);	
					continue;
				}
				// 該当支払商品のカード契約会社がない場合
				if (ttend.PayProductRef__r.CardAccountRef__c == null) {
					log.write_error('該当会計支払の支払商品の「カード契約会社」項目を未設定するため、手数料計算対象外になる:' + SalesLoginUrl + ttend.PayProductRef__c);	
					continue;
				}
				//Decimal rate = CommUtils.nullToZero(ttend.PayProductRef__r.CardAccountRef__r.CardSalesRate__c);
				if (!chargeInfomap.containsKey(ttend.PayProductRef__r.CardAccountRef__c)) {
					if (!warngingAccIdSet.contains(ttend.PayProductRef__r.CardAccountRef__c)) {
						log.write_error('手数料定義情報が見つかりません、手数料計算対象外になる:' + SalesLoginUrl + ttend.PayProductRef__r.CardAccountRef__c);	
						warngingAccIdSet.add(ttend.PayProductRef__r.CardAccountRef__c);
					}
					continue;
				}
				ChargeInfo__c chargeInfo = chargeInfomap.get(ttend.PayProductRef__r.CardAccountRef__c);
				Decimal rate = CommUtils.nullToZero(chargeInfo.SalesRate__c);
				// 手数料レート０　OR　手数料支払なしの場合、処理SKIPする「WARNなし」
				if (rate == 0 || chargeInfo.PayChargeFlg__c != true) {
					continue;
				}
				// カード利用金額　[会計支払の利用金額]
				Decimal usedAmount = Commutils.nullToZero(ttend.Field29__c);
				// 2015/12/07 返金情報は手数料計算対象外に設定する BEGIN
				if (usedAmount == 0) continue;
				// 2015/12/07 返金情報は手数料計算対象外に設定する END
				// カード会社情報のIDを格納する
				Id carCompanyId = ttend.PayProductRef__r.CardAccountRef__c;
				if (!cardCompanyMap.containsKey(carCompanyId)) cardCompanyMap.put(carCompanyId, usedAmount);
				else cardCompanyMap.put(carCompanyId, cardCompanyMap.get(carCompanyId) + usedAmount);
				
				cardCompanyRateMap.put(carCompanyId, rate);
				cardCompanyNameMap.put(carCompanyId, CommUtils.nullToBlank(ttend.PayProductRef__r.CardAccountRef__r.Name));
				
				// カード会社情報可能
				cardCompanyInfoMap.put(carCompanyId, ttend.PayProductRef__r.CardAccountRef__r);
			}
			boolean noTaxFlg = gConfig.cardSalesRateConf.noTaxTargetFlg;
			// 各カード会社の利用手数料を計算を行う
			for (Id cardCompnayId : cardCompanyMap.keySet()) {
				Decimal usedAmount = cardCompanyMap.get(cardCompnayId);
				Decimal cardRate = cardCompanyRateMap.get(cardCompnayId) / 100;
				
				Account accInfo = cardCompanyInfoMap.get(cardCompnayId);
				// 端数処理区分
				System.RoundingMode roundType = CommUtils.pointRoundMode();
				if (cardCompanyInfoMap.get(cardCompnayId).RoundType__c != null) {
					roundType = CommUtils.pointRoundMode(cardCompanyInfoMap.get(cardCompnayId).RoundType__c);
				}
				// 手数料を計算する
				Decimal salesRate = CommUtils.RoundProcess(usedAmount * cardRate, gPointLen, roundType);
				Decimal noTaxSalesRate = noTaxFlg ? salesRate : CommUtils.RoundProcess(salesRate / (1+ gTaxRate/100),gPointLen, roundType);
				// 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジックの追加 BEGIN
				if (salesRate == 0) continue;
 				// 月単位の場合、仕訳オブジェクトに格納を行う
				String chargeCalKbn = CommUtils.nullToBlank(accInfo.ChargeCalKbnLst__c);
				if (CommUtils.isBlank(chargeCalKbn) || chargeCalKbn == CONST_CALKBN_ACC) {
					// 仕入情報を作成する
					Purchase__c pru = new Purchase__c(
						// 
						PurchaseType__c = gConfig.cardSalesRateConf.InTypeName,	// 種別
						KamokuLst__c = gConfig.cardSalesRateConf.OuKamoku,		// 科目
						JinyaRevenue__c = gRsvAccoutId,			// 売上
						DenpyoukeiIncTax__c = salesRate,		// 税込金額
						Denpyoukei__c =  noTaxSalesRate,
						ShopInfoRef__c = gShopId,
						Purchasesource__c = cardCompnayId,		// 仕入先
						AccountRef__c = acc.Id,
						Memo__c = CONST_MEMO_CARD,
						AccountTimeStamp__c = getDateTimeByStr(acc.Field53__c),
						EventSource__c = CONST_EVENTSRC_CARD,
						NoTaxFlg__c = noTaxFlg
					);
					insertPurLst.add(pru);
				} else if (chargeCalKbn == CONST_CALKBN_MONTH) {
					// 仕訳オブジェクトに該当手数料情報を設定する
					Classification__c clsif = new Classification__c(
						RsvAccountRef__c = gRsvAccoutId,			// 売上
						AccountAcountRef__c = acc.Id,			// 会計
						SalesDotCom__c = cardCompnayId,			// AGT（取引先）
						DebitDepartment__c = gConfig.cardSalesRateConf.InTypeName,
						CreditName__c = gConfig.cardSalesRateConf.OuKamoku,
						SalesAmount__c = salesRate,
						SalesOrgAmount__c = usedAmount,
						SalesRate__c = cardCompanyRateMap.get(cardCompnayId),
						BookingName__c = acc.Relreserve__c,
						ShopInfoRef__c = gShopId,
						EventSource__c = CONST_EVENTSRC_CARD,
						ChargeTypeLst__c = CONST_CHARGE_TYPE_NORMAL
					);
					insertClassLst.add(clsif);
				}
				// 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジックの追加 END
			}
		}
		if (!insertPurLst.isEmpty()) insert insertPurLst;	
		// 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジックの追加 BEGIN
		if (!insertClassLst.isEmpty()) insert insertClassLst;
		// 月単位のカード手数料を計算して、仕入データを作成する
		list<Purchase__c> totalPurLst = generalSalesRateFromTotal(CONST_EVENTSRC_CARD);
		if (!totalPurLst.isEmpty()) insert totalPurLst;
		// 処理情報を記録する
		//retRs.rsNums = insertPurLst.size();
		retRs.rsNums = insertPurLst.size() + totalPurLst.size();
		// 2016/07/06 販売手数料とカード手数料の合計値から手数料を計算ロジックの追加 END
		log.write_method_end();
		return retRs;
	}
	private DateTime getDateTimeByStr(String s) {
		if (CommUtils.isBlank(s) || s.length() != 14) return null;
		// 20151111131414
		integer year = Integer.valueOf(s.substring(0,4));
		integer month = Integer.valueOf(s.substring(4,6));
		integer day = Integer.valueOf(s.substring(6,8));
		integer hh = Integer.valueOf(s.substring(8,10));
		integer mm = Integer.valueOf(s.substring(10,12));
		integer ss = Integer.valueOf(s.substring(12,14));
		return DateTime.newInstance(year, month, day, hh, mm, ss);
	}
	// 処理結果格納
	public class ResultInfo {
		public ResultInfo() {
			rsNums = 0;
			rsAmount = 0;
			csvBody = '';
		}
		public integer rsNums{get; private set;}
		public Decimal rsAmount{get; private set;}
		public string csvBody{get; private set;}
	}
}