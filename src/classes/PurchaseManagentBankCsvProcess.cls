/**
* 振込データ出力機能対応
* 2015/11/23 振込手数料計算処理ロジックを対応する
* 2015.12.17 指定ボタンの条件により、仕入情報を取得機能の改善
* 2016/03/22 手数料の仕訳出力の場合、手数料支払のチェックは外す
**/
public without sharing class PurchaseManagentBankCsvProcess {
	// 処理用パラメータ
	private final List<Id> gAccountIds;
	private final String gShopCode;
	private final Date gStDate;
	private final Date gEdDate;
	private final Date gFurikomiDate;
	private final Boolean gIsShowHeader;
	private final AccountingSyncBatchHelp gConfig;
	private final String gFilterStr;
	private final Integer gPointLen = CommUtils.getPointLen();
	private final String BLANK_STR = '';
	private final String BLANK_INT = '0';
	private final String CRLF = '\r\n';
	private final String SalesLoginUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/';
	
	private final map<string, integer> headerFieldLenMap = new map<String, Integer>
			{
			'$$_データ区分_$$'=>1,
			'$$_種別コード_$$'=>2,
			'$$_コード区分_$$'=>1,
			'$$_委託者コード_$$'=>10,
			'$$_委託者名_$$'=>40,
			'$$_取組日_$$'=>4,
			'$$_仕向金融機関番号_$$'=>4,
			'$$_仕向金融機関名_$$'=>15,
			'$$_仕向支店番号_$$'=>3,
			'$$_仕向支店名_$$'=>15,
			'$$_預金種目(依頼人)_$$'=>1,
			'$$_口座番号(依頼人)_$$'=>7,
			'$$_ダミー_$$'=>17
			};
	private final map<string, integer> dataFieldLenMap = new map<String, Integer>
			{
			'$$_データ区分_$$'=>1,
			'$$_被仕向金融機関番号_$$'=>4,
			'$$_被仕向金融機関名_$$'=>15,
			'$$_被仕向支店番号_$$'=>3,
			'$$_被仕向支店名_$$'=>15,
			'$$_手形交換所番号_$$'=>4,
			'$$_預金種目_$$'=>1,
			'$$_口座番号_$$'=>7,
			'$$_受取人名_$$'=>30,
			'$$_振込金額_$$'=>10,
			'$$_新規コード_$$'=>1,
			'$$_顧客コード1_$$'=>10,
			'$$_顧客コード2_$$'=>10,
			'$$_EDI情報_$$'=>20,
			'$$_振込区分_$$'=>1,
			'$$_識別表示_$$'=>1,
			'$$_ダミー_$$'=>7,
			'$$_支払金額_$$'=>10,
			'$$_先方負担手数料_$$'=>10,
			'$$_振込手数料_$$'=>10
			};
	private final map<string, integer> trailerFieldLenMap = new map<String, Integer>
			{
			'$$_データ区分_$$'=>1,
			'$$_合計件数_$$'=>6,
			'$$_合計金額_$$'=>12,
			'$$_ダミー_$$'=>101
			};
	private final map<string, integer> ednFieldLenMap = new map<String, Integer>
			{
			'$$_データ区分_$$'=>1,
			'$$_ダミー_$$'=>119
			};
	// 処理単位のログ記述する
	public CommLogUtils log{get;private set;} 
	// 初期化
	// pFilterStr:検索条件指定
	public PurchaseManagentBankCsvProcess(List<Id> accountIds, String shopCode, Date stDate, Date edDate,Date furikomiDt ,AccountingSyncBatchHelp config, Boolean isShowHeader, String pFilterStr) {
		// 指定仕入、指定店舗の利用金額（合計）を表示する
		gAccountIds = accountIds;
		gShopCode = shopCode;
		gStDate = stDate;
		gEdDate = edDate;
		gFurikomiDate = furikomiDt;
		gConfig = config;
		gIsShowHeader = isShowHeader;
		gFilterStr = pFilterStr;
		log = new CommLogUtils('PurchaseManagentBankCsvProcess', true);
	}

	// 銀行振り込みCSVのHeaderとデータのCSV情報を作成する
	public ResultInfo generalBankImportCsv(Boolean isFirstLoop) {
		log.write_method_start('generalBankImportCsv');
		// 処理結果格納用情報
		ResultInfo retRs = new ResultInfo();
		if (gAccountIds == null || gAccountIds.isEmpty()) return retRs;
		// 口座定義情報
		AccountingSyncBatchHelp.FunctionBankNoInfo purSetInfo = gConfig.purSettlementKouzaInfo;
		// 取引先入金口座定義情報
		AccountingSyncBatchHelp.FunctionBankNoInfo purReciveInfo = gConfig.purReciveKouzaInfo;
		// Header情報を作成が必要の場合
		AccountingSyncBatchHelp.BankTeleGramHeader headerInfo = gConfig.bankTeleGramHeaderInf;
		// 口座情報を取得する
		//List<ShopAccountInfo__c> orgAccInfLst = [select BankNumber__c,BankName__c,BankAccountNo__c,BankBranchNumber__c,BankBranchName__c,BankNameKana__c,BankBranchNameKana__c,RequestUserName__c,RequestUserCode__c,DepositsType__c from ShopAccountInfo__c where Seq__c = :purSetInfo.kozaSeq];
		// 口座情報を取得する[2015/11/22 口座番号項目から取得を行う]
		List<ShopAccountInfo__c> orgAccInfLst = [select BankNumber__c,BankName__c,BankAccountNo__c,BankBranchNumber__c,BankBranchName__c,BankNameKana__c,BankBranchNameKana__c,RequestUserName__c,RequestUserCode__c,DepositsType__c from ShopAccountInfo__c where Name = :purSetInfo.kozaName];
		if (orgAccInfLst.isEmpty()) {
			if (isFirstLoop) {
				log.write_error('店舗コード：'+gShopCode + 'の店舗口座情報('+CommUtils.nullToBlank(purSetInfo.descript)+')が見つかりません。処理中止');
			}
			return retRs;
		}
		// ***************** 手数料定義情報を取得する ***************** 
		/* 2016/03/22 手数料の仕訳出力の場合、手数料支払のチェックは外す BEGIN
		// 処理取引先の定数料定義情報を取得、定数料の仕入データの場合、該当定義情報を見て、出力するがどうか判断を行う
		map<id,ChargeInfo__c> chargeInfMap = AccountingSyncBatchHelp.getChargeInfoByAccount(gAccountIds);
		*/
		// 仕入先集計用クラス
		String queryStr = 'Select Purchasesource__c pruKey, PurchaseType__c pruType ,sum(DenpyoukeiIncTax__c) denpyoukeiSum  From Purchase__c where Purchasesource__c =:gAccountIds  And (Field1__c >= :gStDate and Field1__c <= :gEdDate) ';
		if (!CommUtils.isBlank(gShopCode)) queryStr += ' And ShopInfoRef__r.ShopCode__c = :gShopCode ';
		// 2015.12.17 指定ボタンの条件により、仕入情報を取得機能の改善 BEGIN
		//if (!CommUtils.isBlank(gConfig.queryPlusFilter)) queryStr += ' And ' +gConfig.queryPlusFilter;
		String queryPlusFilter = gConfig.queryPlusFilter;
		if (!CommUtils.isBlank(gFilterStr)) queryPlusFilter = gFilterStr;
		if (!CommUtils.isBlank(queryPlusFilter)) queryStr += ' And ' +queryPlusFilter;
		// 2015.12.17 指定ボタンの条件により、仕入情報を取得機能の改善 END
		/*
		List<String> chargeTypeLst = new list<string>();
		if (!CommUtils.isBlank(gConfig.agtSalesRateConf.InTypeName)) chargeTypeLst.add(gConfig.agtSalesRateConf.InTypeName);
		if (!CommUtils.isBlank(gConfig.cardSalesRateConf.InTypeName)) chargeTypeLst.add(gConfig.cardSalesRateConf.InTypeName);
		if (!chargeTypeLst.isempty()) {
			queryStr += ' And ( (PurchaseType__c in :chargeTypeLst And Purchasesource__r.PayChargeFlg__c = true ) or PurchaseType__c not in :chargeTypeLst )';
		}*/
		set<string> chargeTypeSet = new set<string>();
		if (gConfig.agtSalesRateConf != null && !CommUtils.isBlank(gConfig.agtSalesRateConf.InTypeName)) chargeTypeSet.add(CommUtils.nullToBlank(gConfig.agtSalesRateConf.InTypeName));
		if (gConfig.cardSalesRateConf != null && !CommUtils.isBlank(gConfig.cardSalesRateConf.InTypeName)) chargeTypeSet.add(CommUtils.nullToBlank(gConfig.cardSalesRateConf.InTypeName));
		
		queryStr += ' Group By Purchasesource__c, PurchaseType__c ';
       	// 仕入別の振り込み金額を格納する
		map<id, decimal> accountAmountInfMap = new map<id, decimal>();
		set<id> chargeErrAccountIdSet = new set<id>();
		string chargeErrMseeage  = '';
		// 合計金額を計算
       	for (AggregateResult rs : DataBase.query(queryStr)) {
       		Id accoundId = CommUtils.nullToBlank((Id)rs.get('pruKey'));
       		Decimal furikomiAmount = (Decimal)rs.get('denpyoukeiSum');
       		String purType = Commutils.nullToBlank(rs.get('pruType'));
       		/* 2016/03/22 手数料の仕訳出力の場合、手数料支払のチェックは外す BEGIN
       		// 処理種別により、手数料の場合、手数料支払するがどうか判断を行う、支払ないと、振り込み金額計算外
       		if (chargeTypeSet.contains(purType)) {
       			// 手数料は未定義の場合
       			if (!chargeInfMap.containsKey(accoundId)) {
	       			// 存在して、手数料支払なし場合、対象外
	       			if (!chargeErrAccountIdSet.contains(accoundId)) {
	       				chargeErrMseeage += '該当取引先に手数料情報を未定義するため、手数料計算対象外になる:'+ SalesLoginUrl + accoundId + '\n';
	       				chargeErrAccountIdSet.add(accoundId);
	       				continue;
	       			}
       			} else if (chargeInfMap.get(accoundId).PayChargeFlg__c != true) {
       				// 手数料支払なしの場合、合計対象外
       				continue;
       			}
       		}*/
       		if (!accountAmountInfMap.containsKey(accoundId)) accountAmountInfMap.put(accoundId, furikomiAmount);
       		else accountAmountInfMap.put(accoundId, accountAmountInfMap.get(accoundId) + furikomiAmount);
       	}
		// HeaderのCSV情報を作成する
		String csv = '';

		// 自社支払口座情報
		ShopAccountInfo__c orgAccInf = orgAccInfLst[0];
		// 口座情報は設定不足の場合
		if (isFirstLoop) {
			// 振込指定日
			String furikomiMMDD = DateTime.newInstance(gFurikomiDate.year(),gFurikomiDate.month(),gFurikomiDate.day()).format('MMdd');
			// 口座情報を確認する
			if (CommUtils.isBlank(orgAccInf.BankNumber__c) ||			// 金融機関番号
				CommUtils.isBlank(orgAccInf.BankBranchNumber__c) ||		// 支店番号
				CommUtils.isBlank(orgAccInf.DepositsType__c) ||			// 預金種目
				CommUtils.isBlank(orgAccInf.BankAccountNo__c) ||		// 口座番号
				CommUtils.isBlank(orgAccInf.RequestUserName__c)) 		// 名義人
			{
				log.write_error('店舗コード：'+gShopCode + 'の口座情報[金融機関番号,支店番号,]の設定が不足:'+ SalesLoginUrl + orgAccInf.Id);
			}
			// CSVの文字列を差し替え処理を行う
			String headerTemplate = headerInfo.filedLayout+CRLF;
			if (gIsShowHeader && !CommUtils.isBLank(headerInfo.messageHeader)) csv +=  headerInfo.messageHeader+CRLF;
			// 2015/11/19 EDIT ヘーダ出力の場合、銀行名と支店名は漢字を出力する BEGIN
			String bankName = rightPad(CommStringUtils.zenkakuToHankaku(orgAccInf.BankNameKana__c)
										, headerFieldLenMap.get('$$_仕向金融機関名_$$'));
			String branchBankName = rightPad(CommStringUtils.zenkakuToHankaku(orgAccInf.BankBranchNameKana__c)
										, headerFieldLenMap.get('$$_仕向支店名_$$'));
			if (gIsShowHeader) {
				bankName = rightPad(CommUtils.nullToBlank(orgAccInf.BankName__c), CommUtils.nullToBlank(orgAccInf.BankName__c).length());
				branchBankName = rightPad(CommUtils.nullToBlank(orgAccInf.BankBranchName__c),CommUtils.nullToBlank(orgAccInf.BankBranchName__c).length());
			}
			// 2015/11/19 EDIT ヘーダ出力の場合、銀行名と支店名は漢字を出力する END
			csv += headerTemplate
					.Replace('$$_データ区分_$$',			leftNumPad(headerInfo.dataKbn		, headerFieldLenMap.get('$$_データ区分_$$')))
					.Replace('$$_種別コード_$$',			leftNumPad(purSetInfo.transType		, headerFieldLenMap.get('$$_種別コード_$$')))
					.Replace('$$_コード区分_$$',			leftNumPad(BLANK_INT				, headerFieldLenMap.get('$$_コード区分_$$')))
					.Replace('$$_委託者コード_$$',			leftNumPad(CommUtils.nullToBlank(orgAccInf.RequestUserCode__c)			
																							, headerFieldLenMap.get('$$_委託者コード_$$')))
					.Replace('$$_委託者名_$$',			rightPad(CommStringUtils.zenkakuToHankaku(orgAccInf.RequestUserName__c)
																							, headerFieldLenMap.get('$$_委託者名_$$')))
					.Replace('$$_取組日_$$',				leftNumPad(furikomiMMDD				, headerFieldLenMap.get('$$_取組日_$$')))
					.Replace('$$_仕向金融機関番号_$$',		leftNumPad(CommUtils.nullToBlank(orgAccInf.BankNumber__c)	
																							, headerFieldLenMap.get('$$_仕向金融機関番号_$$')))
					// 2015/11/19 EDIT ヘーダ出力の場合、銀行名と支店名は漢字を出力する BEGIN
					//.Replace('$$_仕向金融機関名_$$',		rightPad(CommStringUtils.zenkakuToHankaku(orgAccInf.BankNameKana__c)
					//																		, headerFieldLenMap.get('$$_仕向金融機関名_$$')))
					.Replace('$$_仕向金融機関名_$$',		bankName)
					// 2015/11/19 EDIT ヘーダ出力の場合、銀行名と支店名は漢字を出力する END
					.Replace('$$_仕向支店番号_$$',			leftNumPad(CommUtils.nullToBlank(orgAccInf.BankBranchNumber__c)	
																							, headerFieldLenMap.get('$$_仕向支店番号_$$')))
					// 2015/11/19 EDIT ヘーダ出力の場合、銀行名と支店名は漢字を出力する BEGIN
					//.Replace('$$_仕向支店名_$$',			rightPad(CommStringUtils.zenkakuToHankaku(orgAccInf.BankBranchNameKana__c)
					//																		, headerFieldLenMap.get('$$_仕向支店名_$$')))
					.Replace('$$_仕向支店名_$$',			branchBankName)
					// 2015/11/19 EDIT ヘーダ出力の場合、銀行名と支店名は漢字を出力する END
					.Replace('$$_預金種目(依頼人)_$$',		leftNumPad(getDepositsTypeCode(orgAccInf.DepositsType__c)	
																							, headerFieldLenMap.get('$$_預金種目(依頼人)_$$')))
					.Replace('$$_口座番号(依頼人)_$$',		leftNumPad(CommUtils.nullToBlank(orgAccInf.BankAccountNo__c)
																							, headerFieldLenMap.get('$$_口座番号(依頼人)_$$')))
					.Replace('$$_ダミー_$$',				rightPad(BLANK_STR					, headerFieldLenMap.get('$$_ダミー_$$')));

		}

		// データ部設定情報を取得する
		AccountingSyncBatchHelp.BankTeleGramData dataInfo = gConfig.bankTeleGramDataInf;
		// 関連の仕入先の口座設定情報を確認する
		//map<id, Account> accountInfMap = new map<Id, Account>([select BankNumber__c,BankNameKana__c,BankAccountNo__c,BankBranchNumber__c,BankBranchNameKana__c,RegisteredHolderKana__c,DepositsType__c,TransferChargeKbn__c from Account where id in :gAccountIds]);
		// 関連の仕入先の口座設定情報を確認する map<取引先ID、map<口座種別、店舗情報>>
		map<id, map<String, ShopAccountInfo__c>> accReciveAccMap = new map<id, map<String,ShopAccountInfo__c>>();
		List<ShopAccountInfo__c> reciveAccounts = [select AccountRef__c,BankNumber__c,BankName__c,BankAccountNo__c,BankBranchNumber__c,BankBranchName__c,
															BankNameKana__c,BankBranchNameKana__c,RequestUserName__c,AccountTypeLst__c,DepositsType__c,
															TransferChargeKbn__c
													from ShopAccountInfo__c where AccountRef__c = :gAccountIds and StatusLst__c != '無効'];
		for (ShopAccountInfo__c shopAcc : reciveAccounts) {
			// 取引先情報定義
			Id accId = shopAcc.AccountRef__c;
			if (!accReciveAccMap.containsKey(shopAcc.AccountRef__c)) {
				accReciveAccMap.put(accId, new map<string, ShopAccountInfo__c>());
			}
			accReciveAccMap.get(accId).put(shopAcc.AccountTypeLst__c, shopAcc);
		}
		// データ明細のHeader情報出力
		if (isFirstLoop) {
			if (gIsShowHeader && !CommUtils.isBLank(dataInfo.messageHeader)) csv +=  dataInfo.messageHeader+CRLF;
		}
		String dataTemplate = dataInfo.filedLayout+CRLF;
		dataTemplate = dataTemplate
						.Replace('$$_データ区分_$$',			leftNumPad(dataInfo.dataKbn	, dataFieldLenMap.get('$$_データ区分_$$')))
						.Replace('$$_手形交換所番号_$$',		leftNumPad(BLANK_INT		, dataFieldLenMap.get('$$_手形交換所番号_$$')))
						.Replace('$$_新規コード_$$',			leftNumPad(BLANK_INT		, dataFieldLenMap.get('$$_新規コード_$$')))
						.Replace('$$_顧客コード1_$$',			rightPad(BLANK_STR			, dataFieldLenMap.get('$$_顧客コード1_$$')))
						.Replace('$$_顧客コード2_$$',			rightPad(BLANK_STR			, dataFieldLenMap.get('$$_顧客コード2_$$')))
						//.Replace('$$_EDI情報_$$',			rightPad(BLANK_STR			, dataFieldLenMap.get('$$_EDI情報_$$')))
						.Replace('$$_EDI情報_$$',			BLANK_STR)
						// 2015/11/19 EDIT 振込指定区分パラメータ化 BEGIN
						.Replace('$$_振込区分_$$',			leftNumPad(dataInfo.furikomiKbn
						// 2015/11/19 EDIT 振込指定区分パラメータ化 END		
																						, dataFieldLenMap.get('$$_振込区分_$$')))	// 7:電信振込
						.Replace('$$_識別表示_$$',			rightPad((dataInfo.isEdi ? 'Y':'')
																						, dataFieldLenMap.get('$$_識別表示_$$')))
						.Replace('$$_ダミー_$$',				rightPad(BLANK_STR			, dataFieldLenMap.get('$$_ダミー_$$')));
		// プラス情報は出力しない場合
		if (!gIsShowHeader) {
			dataTemplate = dataTemplate
						.Replace('$$_支払金額_$$',			BLANK_STR)
						.Replace('$$_先方負担手数料_$$',		BLANK_STR)
						.Replace('$$_振込手数料_$$',			BLANK_STR);
		}
		// 振り込み手数料を計算を行う
		for (Id accId : gAccountIds) {
			// 該当仕入先は削除される場合
			if (!accReciveAccMap.containsKey(accId)) {
				log.write_error('仕入先の口座情報が未定義、出力対象外にある:' + SalesLoginUrl + accId);
				continue;
			}
			// 口座情報を取得する
			ShopAccountInfo__c sendAcc = null;
			map<string, ShopAccountInfo__c> accountInfMaps = accReciveAccMap.get(accId);
			if (accountInfMaps.size() == 1) sendAcc = accountInfMaps.values()[0];
			else {
				if (purReciveInfo == null) {
					log.write_error('「口座種別」チェック用タグの定義情報から見つかりません(XML定義情報確認ください)、出力対象外になる:' + SalesLoginUrl + accId);
					continue;
				} else {
					if (accountInfMaps.containsKey(purReciveInfo.kozaType)) {
						sendAcc = accountInfMaps.get(purReciveInfo.kozaType);
					} else {
						log.write_error('「口座種別」は「'+purReciveInfo.kozaType+'」の口座定義情報を見つかりません、出力対象外になる:' + SalesLoginUrl + accId);
						continue;
					}
				}
			}
			// 仕入先情報
			//Account sendAcc = accountInfMap.get(accId);
			// 口座情報を確認する
			if (CommUtils.isBlank(sendAcc.BankNumber__c) ||				// 金融機関番号
				CommUtils.isBlank(sendAcc.BankBranchNumber__c) ||		// 支店番号
				CommUtils.isBlank(sendAcc.DepositsType__c) ||			// 預金種目
				CommUtils.isBlank(sendAcc.BankAccountNo__c) ||			// 口座番号
				CommUtils.isBlank(sendAcc.RequestUserName__c) ||		// 名義人
				CommUtils.isBlank(sendAcc.TransferChargeKbn__c)			// 手数料負担区分
				) {
				log.write_error('仕入先口座情報の設定が不足するため、出力対象外になる:' + SalesLoginUrl + sendAcc.Id);
				continue;
			}
			// 該当仕入先は集計対象外の場合
			if (!accountAmountInfMap.containsKey(accId)) { continue; }
			
			// 支払金額
			Decimal usedAmount = accountAmountInfMap.get(accId);	// $$_支払金額_$$
			// 振込金額・振り込み手数料、先方負担手数料設定
			String[] rsStrArr = generalChargeInfo(dataTemplate, orgAccInf, sendAcc, usedAmount);
			String locDataTemplate = rsStrArr[0];
			Decimal furikomiAmount = CommUtils.nullToZero(rsStrArr[1]);
			// 2015/11/19 EDIT ヘーダ出力の場合、銀行名と支店名は漢字を出力する BEGIN
			String bankName 		= rightPad(CommStringUtils.zenkakuToHankaku(sendAcc.BankNameKana__c)
															, dataFieldLenMap.get('$$_被仕向金融機関名_$$'));
			String branchBankName 	= rightPad(CommStringUtils.zenkakuToHankaku(sendAcc.BankBranchNameKana__c)
															, dataFieldLenMap.get('$$_被仕向支店名_$$'));
			if (gIsShowHeader) {
				bankName = rightPad(CommUtils.nullToBlank(sendAcc.BankName__c),CommUtils.nullToBlank(sendAcc.BankName__c).length());
				branchBankName = rightPad(CommUtils.nullToBlank(sendAcc.BankBranchName__c),CommUtils.nullToBlank(sendAcc.BankBranchName__c).length());
			}
			// 2015/11/19 EDIT ヘーダ出力の場合、銀行名と支店名は漢字を出力する END
			csv += locDataTemplate
					.Replace('$$_被仕向金融機関番号_$$',	leftNumPad(CommUtils.nullToBlank(sendAcc.BankNumber__c)
															, dataFieldLenMap.get('$$_被仕向金融機関番号_$$')))
					// 2015/11/19 EDIT ヘーダ出力の場合、銀行名と支店名は漢字を出力する BEGIN
					//.Replace('$$_被仕向金融機関名_$$',		rightPad(CommStringUtils.zenkakuToHankaku(sendAcc.BankNameKana__c)
					//										, dataFieldLenMap.get('$$_被仕向金融機関名_$$')))
					.Replace('$$_被仕向金融機関名_$$',		bankName)
					// 2015/11/19 EDIT ヘーダ出力の場合、銀行名と支店名は漢字を出力する END
					.Replace('$$_被仕向支店番号_$$',		leftNumPad(CommUtils.nullToBlank(sendAcc.BankBranchNumber__c)
															, dataFieldLenMap.get('$$_被仕向支店番号_$$')))
					// 2015/11/19 EDIT ヘーダ出力の場合、銀行名と支店名は漢字を出力する BEGIN
					//.Replace('$$_被仕向支店名_$$',			rightPad(CommStringUtils.zenkakuToHankaku(sendAcc.BankBranchNameKana__c)
					//										, dataFieldLenMap.get('$$_被仕向支店名_$$')))
					.Replace('$$_被仕向支店名_$$',			branchBankName)
					// 2015/11/19 EDIT ヘーダ出力の場合、銀行名と支店名は漢字を出力する END
					.Replace('$$_預金種目_$$',			leftNumPad(getDepositsTypeCode(sendAcc.DepositsType__c)		
															, dataFieldLenMap.get('$$_預金種目_$$')))
					.Replace('$$_口座番号_$$',			leftNumPad(CommUtils.nullToBlank(sendAcc.BankAccountNo__c)
															, dataFieldLenMap.get('$$_口座番号_$$')))
					.Replace('$$_受取人名_$$',			rightPad(CommStringUtils.zenkakuToHankaku(sendAcc.RequestUserName__c)		
															, dataFieldLenMap.get('$$_受取人名_$$')));
			// 出力件数
			retRs.rsNums++;
       		// 合計金額を加算する
       		retRs.rsAmount += furikomiAmount;
		}
		//retRs.rsNums = accountAmountInfMap.size();
		retRs.csvBody = csv;
		log.write_method_end();
		return retRs;
	}
	// 振込手数料計算ロジック対応
	private Decimal calChargeRate(Decimal usedAmount,ShopAccountInfo__c orgAccInf, ShopAccountInfo__c guest) {
		// 振込金額計算チエックロジック定義情報の取得
		AccountingSyncBatchHelp.BankTransRate brankTransRateInf = gConfig.brankTransRateInf;
		// 振込手数料計算結果の保存
		Decimal chargeRate = 0;
		if (orgAccInf.BankNumber__c == guest.BankNumber__c) {
			if (orgAccInf.BankBranchNumber__c == guest.BankBranchNumber__c) {
				for (AccountingSyncBatchHelp.BankTranRateItem rateItem: brankTransRateInf.sameBankAndBranch) {
					if (rateItem.minAmount <= usedAmount && (rateItem.maxAmount == null || rateItem.maxAmount >= usedAmount)) {
						chargeRate = rateItem.transRate;
						break;
					}
				}
			} 
			// 違う支店の場合
			else {
				for (AccountingSyncBatchHelp.BankTranRateItem rateItem: brankTransRateInf.sameBankAndDiffBranch) {
					if (rateItem.minAmount <= usedAmount && (rateItem.maxAmount == null || rateItem.maxAmount >= usedAmount)) {
						chargeRate = rateItem.transRate;
						break;
					}
				}
			}
		} 
		// 違う銀行の場合
		else {
			for (AccountingSyncBatchHelp.BankTranRateItem rateItem: brankTransRateInf.diffBank) {
				if (rateItem.minAmount <= usedAmount && (rateItem.maxAmount == null || rateItem.maxAmount >= usedAmount)) {
					chargeRate = rateItem.transRate;
					break;
				}
			}
		}
		return chargeRate;
	}
	// 振込金額、支払金額計算ロジックを対応する
	private string[] generalChargeInfo (String csvBody, ShopAccountInfo__c orgAccInf, ShopAccountInfo__c guest, Decimal usedAmount) {
		String[] rsInfo = new String[2];
		//AccountingSyncBatchHelp gConfig
		
		// 手数料比較情報設定不足の場合
		if (CommUtils.isBlank(orgAccInf.BankNumber__c) ||
			CommUtils.isBlank(orgAccInf.BankBranchNumber__c) ||
			CommUtils.isBlank(guest.BankNumber__c) ||
			CommUtils.isBlank(guest.BankBranchNumber__c) ||
			CommUtils.isBlank(guest.TransferChargeKbn__c)) {
				rsInfo[0] = csvBody
							.Replace('$$_支払金額_$$'			,leftNumPad(BLANK_INT, dataFieldLenMap.get('$$_支払金額_$$')))
							.Replace('$$_先方負担手数料_$$'	,leftNumPad(BLANK_INT, dataFieldLenMap.get('$$_先方負担手数料_$$')))
							.Replace('$$_振込金額_$$'			,leftNumPad(BLANK_INT, dataFieldLenMap.get('$$_振込金額_$$')))
							.Replace('$$_振込手数料_$$'		,leftNumPad(BLANK_INT, dataFieldLenMap.get('$$_振込手数料_$$')));
				rsInfo[1] = '0';
				return rsInfo;
		}
		// 手数料の初期計算を行う
		Decimal chargeRate = calChargeRate(usedAmount,orgAccInf,guest);

		// 振り込み金額
		Decimal payAmount = 0;
		Decimal guestChargeRate = 0;
		// 負担先により、振込金額計算
		if (guest.TransferChargeKbn__c == '先方負担') {
			// 振込金額
			payAmount = usedAmount - chargeRate;
			// 先方負担手数料
			guestChargeRate = chargeRate;
			// 先方負担の場合、計算後の振り込み金額から手数料を再計算を行う
			// その引きした金額は手数料から再計算を行う、
			Decimal reCalChargeRate = calChargeRate(payAmount,orgAccInf, guest);
			if (reCalChargeRate != guestChargeRate) {
				// 実際の振込手数料を調整後の金額を設定する
				//guestChargeRate = reCalChargeRate;
				chargeRate = reCalChargeRate;	// 振り込み手数料を再設定を行う
			}
			rsInfo[0] = csvBody
					.Replace('$$_先方負担手数料_$$',leftNumPad(CommUtils.nullToBLank(gPointLen == 0 ? guestChargeRate.intValue() : guestChargeRate )		
															, dataFieldLenMap.get('$$_先方負担手数料_$$')))
					.Replace('$$_振込金額_$$',	leftNumPad(CommUtils.nullToBLank(gPointLen == 0 ? payAmount.intValue() : payAmount )		
															, dataFieldLenMap.get('$$_振込金額_$$')));
			rsInfo[1] = String.valueOf(payAmount);
		} else {
			// 自社負担の場合
			// 先方負担手数料
			guestChargeRate = 0;
			// 振込手数料が自社負担の場合は、請求金額(ロールアップした金額)をそのまま設定する
			payAmount = usedAmount;
			rsInfo[0] = csvBody
					.Replace('$$_先方負担手数料_$$',leftNumPad(CommUtils.nullToBLank(gPointLen == 0 ? guestChargeRate.intValue() : guestChargeRate )		
															, dataFieldLenMap.get('$$_先方負担手数料_$$')))
					.Replace('$$_振込金額_$$',	 leftNumPad(CommUtils.nullToBLank(gPointLen == 0 ? payAmount.intValue() : payAmount )		
															, dataFieldLenMap.get('$$_振込金額_$$')));
			rsInfo[1] = String.valueOf(payAmount);
		}
		
		rsInfo[0] = rsInfo[0]
					.Replace('$$_支払金額_$$',	leftNumPad(CommUtils.nullToBLank(gPointLen == 0 ? usedAmount.intValue() : usedAmount )		
															, dataFieldLenMap.get('$$_支払金額_$$')))
					.Replace('$$_振込手数料_$$',	leftNumPad(CommUtils.nullToBLank(gPointLen == 0 ? chargeRate.intValue() : chargeRate )		
															, dataFieldLenMap.get('$$_振込手数料_$$')));
		return rsInfo;
	}

	
	public String generalBankImportCsvEnd(Integer rsNums, Decimal sumAmout) {
		log.write_method_start('generalBankImportCsvEnd');
		String csv = '';
		AccountingSyncBatchHelp.BankTeleGramTrailer trailerInfo = gConfig.bankTeleGramTrailerInf;
		AccountingSyncBatchHelp.BankTeleGramEnd endInfo = gConfig.bankTeleGramEndInf;

		if (gIsShowHeader && !CommUtils.isBLank(trailerInfo.messageHeader)) csv +=  trailerInfo.messageHeader+CRLF;
		String trailerTemplate = trailerInfo.filedLayout+CRLF;
		csv += trailerTemplate
				.Replace('$$_データ区分_$$',			leftNumPad(trailerInfo.dataKbn	
																	, trailerFieldLenMap.get('$$_データ区分_$$')))
				.Replace('$$_合計件数_$$',			leftNumPad(CommUtils.nullToBlank(rsNums)	
																	, trailerFieldLenMap.get('$$_合計件数_$$')))
				.Replace('$$_合計金額_$$',			leftNumPad(CommUtils.nullToBlank(gPointLen == 0 ? sumAmout.intValue() : sumAmout )	
																	, trailerFieldLenMap.get('$$_合計金額_$$')))
				.Replace('$$_ダミー_$$',				rightPad(BLANK_STR				
																	, trailerFieldLenMap.get('$$_ダミー_$$')));
		if (gIsShowHeader && !CommUtils.isBLank(endInfo.messageHeader)) csv +=  endInfo.messageHeader+CRLF;
		String endTemplate = endInfo.filedLayout+CRLF;
		csv += endTemplate
				.Replace('$$_データ区分_$$',			rightPad(endInfo.dataKbn	, ednFieldLenMap.get('$$_データ区分_$$')))
				.Replace('$$_ダミー_$$',				rightPad(BLANK_STR			, ednFieldLenMap.get('$$_ダミー_$$')));
		log.write_method_end();
		return csv;
	}
	
	public class ResultInfo {
		public ResultInfo() {
			rsNums = 0;
			rsAmount = 0;
			csvBody = '';
			outputAccIdSet = new set<id>();
		}
		public integer rsNums{get; private set;}
		public Decimal rsAmount{get; private set;}
		public string csvBody{get; private set;}
		public set<id> outputAccIdSet{get; private set;}	// 今回処理されている仕入先のIDを格納する
	}
	
	private string rightPad(String s, Integer len) {
		s = CommUtils.nullToBlank(s);
		if (s.length() > len) return s.mid(0,len) + (gIsShowHeader ? ',' :'');
		return s.rightPad(len) + (gIsShowHeader ? ',' :'');
	}
	
	private string leftNumPad(String s, Integer len) {
		s = CommUtils.nullToBlank(s);
		if (s.length() > len) return s.mid(0,len) + (gIsShowHeader ? ',' :'');
		if (CommUtils.isBlank(s)) s = BLANK_INT;
		return CommUtils.paddingLeftZero(s, len) + (gIsShowHeader ? ',' :'');
	}
	private string getDepositsTypeCode(String s) {
		if (s == '普通') return '1';
		else if (s == '当座') return '2';
		else if (s == '貯蓄') return '4';
		else return '9';
	}

}