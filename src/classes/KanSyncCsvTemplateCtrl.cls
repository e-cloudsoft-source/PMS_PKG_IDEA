/**
* 勘定奉行連携CSV出力する
* 2016/09/16 INIT
* 2018/08/06 税込金額から消費税を計算する WSQ
* 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力)
* 2019/10/11 
*	仕訳明細出力する際、消費税8%と10%に行が分ける出力する対応
*	入出金消費税項目が存在場合、入出金消費税も出力する対応
* 2020/03/19 勘定奉行連携CSVの改善
* 2020/05/07 CSJS220（借方税率）、CSJS320（貸方税率）に小数点以下が出力された不具合改修
* 2020/11/02 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う）
* 2020/11/02 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）
**/
public with sharing class KanSyncCsvTemplateCtrl {
	
	//private final String csvHeaderStr = Label.INF_0006 + '\n';//'Ver,伝票日付,伝票番号,計算区分,仕訳区分,管理会計仕訳区分,借方部門コード,借方科目コード,借方科目名,借方補助コード,借方補助名,借方税区分,借方金額,借方消費税額,貸方部門コード,貸方科目コード,貸方科目名,貸方補助コード,貸方補助名,貸方税区分,貸方金額,貸方消費税額,数字1,数字2,摘要,入力プログラム区分,配賦税計算モード,配賦元集計開始日,配賦元集計終了日,配賦基準番号,配賦元部門コード,配賦元科目コード,配賦元補助コード,配賦元金額\n';
	// 売上ID
	private final String gRsvAccoutId;
	// 店舗コード
	private final String gShopCode;
	// 売上日
	private String gRsvName;
	// 前受付金チェック用変数
	private final String PROD_ACTION_TYPE_AR = CommConst.PROD_ACTION_TYPE_AR;
	// プラン
	private final String PROD_ACTION_TYPE_PL = CommConst.PROD_ACTION_TYPE_PL;
	// CsvHeaderはファイルに出力するがどうか判断用フラグ
	private final Boolean isAppendCsvHeaderFlg = CommDefine__c.getOrgDefaults().SchedulePcaCsvHeaderIsShowFlg__c == null
												? true : CommDefine__c.getOrgDefaults().SchedulePcaCsvHeaderIsShowFlg__c;
	// 文字サイズを集計する
	public Boolean isEmptyCsvBody{get; private set;}
	// 定数
	public final String PAY_TYPE_DESPOIST = '予約金';
	public final String PAY_TYPE_REFUND = '返金';
	public final String PAY_TYPE_NORMAL = '普通';
	public final String PAY_TYPE_APAY = '前受金';
	public final String PAY_TYPE_URKK = '売掛金';
	// ログ情報格納用
	public String msgStr{get; private set;}
	// 伝票区切種別済み[TRUEのみ、伝票区切は*を出力する、その以外の場合、スペースを出力する]
	private Id accId = null;
	private String getDenhyouDivMark(AccountAcount__c acc) {
		if (acc == null) return '*';
		else if (accId != acc.Id) {
			accId = acc.Id;
			return '*';
		}
		return '';
	}
	private String getDenhyouDateStr(String salesName) {
		// 8桁文字列(YYYYMMMDD)からYYYY/MM/DDに転換を行う
		if (CommUtils.isBlank(salesName) || salesName.length() != 8) return salesName;
		Date dt = CommUtils.stringToDate(salesName);
		return DateTime.newInstance(dt.year(),dt.month(),dt.day()).format('yyyy/MM/dd');
	}
	/**
	* 店舗別売上日単位のPCA連携情報を作成する
	**/
	public KanSyncCsvTemplateCtrl (String rsvAccId, String shopCode) {
		gRsvAccoutId = rsvAccId;
		gShopCode = shopCode;
		msgStr = '';
	}

	// *************************
	// CSV出力のテンプレート定義情報
	// *************************
	// 2018/08/06 税込金額から消費税を計算する BEGIN
	private static String CONST_CSVDATA_TEMPLATE='$$_伝票区切_$$,$$_伝票日付_$$,$$_伝票番号_$$,$$_借方部門コード_$$,$$_借方科目コード_$$,$$_借方補助コード_$$,$$_借方金額_$$,'
													  +'$$_貸方部門コード_$$,$$_貸方科目コード_$$,$$_貸方補助コード_$$,$$_貸方金額_$$,$$_摘要_$$\n';
	private static final String TaxCalType0 = '0';//消費税を計算しない 0.しない
	private static final String TaxCalType2 = '2';//消費税を自動計算する 2.税込金額から計算する
	// 2018/08/06 税込金額から消費税を計算する END
	//氏名
	private static final String CONST_CSVDATA_COMMENT_TEMPLATE = '$$_COMMENTLAB_$$： $$_ROOMNO_$$   　'+Label.CONST_046_0030+'： $$_GUESTNAME_$$';
	
	// *************************
	// CSV出力処理関数
	// テスト結果：10000件の場合、摘要：250文字：送信可能、10MB
	//          14000件の場合、摘要：50文字：送信可能、5MB
	// *************************
	public String generalCsvContent() {
		
		// 店舗別XML定義情報取得する
		ConvertXmlConfig ccInfo = getConvertXml(gShopCode); 
		// 2018/06/12 仕訳Rollup機能追加対応[入出金、売上]単位にRollup、仕入は単独Rollup BEGIN
		gccInfo = ccInfo;
		// 2018/06/12 仕訳Rollup機能追加対応[入出金、売上]単位にRollup、仕入は単独Rollup END
		// 指定店舗コードと売上IDで,指定日のPCA売上情報を抽出する
		// 関連の会計科目情報取得、格納する
		Set<String> seqNoSet = new Set<String>();
		// 利用必要の会計科目情報を一括取得
		// 2019/10/11 多税率機能対応 WSQ BEGIN
		for (String code : ccInfo.taxKanjoMap.values()) {seqNoSet.add(code);}
		for (String code : ccInfo.taxPayKanjoMap.values()) {seqNoSet.add(code);}
		if (!CommUtils.isBlank(ccInfo.taxPayKanjoCode)) seqNoSet.add(ccInfo.taxPayKanjoCode);
		// 2019/10/11 多税率機能対応 WSQ END
		if (!CommUtils.isBlank(ccInfo.taxKanjoCode)) seqNoSet.add(ccInfo.taxKanjoCode);
		if (!CommUtils.isBlank(ccInfo.advpayLKanjoCode)) seqNoSet.add(ccInfo.advpayLKanjoCode);
		if (!CommUtils.isBlank(ccInfo.advpayRKanjoCode)) seqNoSet.add(ccInfo.advpayRKanjoCode);
		if (!CommUtils.isBlank(ccInfo.refundRkanjoCode)) seqNoSet.add(ccInfo.refundRkanjoCode);
		for (String seqNo : ccInfo.cashInputInMap.values()) seqNoSet.add(seqNo);
		for (String seqNo : ccInfo.cashInputOuMap.values()) seqNoSet.add(seqNo);
		for (String seqNo : ccInfo.cashOutputInMap.values()) seqNoSet.add(seqNo);
		for (String seqNo : ccInfo.cashOutputOuMap.values()) seqNoSet.add(seqNo);
		// Media種別関連の会計科目情報
		for (String seqNo : ccInfo.mediaCardMap.values()) seqNoSet.add(seqNo);
		for (String seqNo : ccInfo.mediaKinkenMap.values()) seqNoSet.add(seqNo);
		// 2020/11/02 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う）WSQ BEGIN
		if (!CommUtils.isBlank(ccInfo.apLeftKanjoSeqNo)) seqNoSet.add(ccInfo.apLeftKanjoSeqNo);
		if (!CommUtils.isBlank(ccInfo.dpLeftKanjoSeqNo)) seqNoSet.add(ccInfo.dpLeftKanjoSeqNo);
		if (!CommUtils.isBlank(ccInfo.acKanjoSeqNo)) seqNoSet.add(ccInfo.acKanjoSeqNo);
		if (!CommUtils.isBlank(ccInfo.apRightKanjoSeqNo)) seqNoSet.add(ccInfo.apRightKanjoSeqNo);
		// 2020/11/02 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う）WSQ END
		// 会計科目基本情報を取得する
		Map<String, KanjoKamoku__c> kanjoKamokuMstMap = new Map<String, KanjoKamoku__c>();
		if (!seqNoSet.isEmpty()) {
			for (KanjoKamoku__c mst : [select id, Name, Kanjocode__c, KanjocodeCode__c, KanjoHojocode__c,DebitTaxKbn__c, CreditTaxKbn__c,DebitDepartCode__c,CreditDepartCode__c from KanjoKamoku__c where Kanjocode__c in :seqNoSet]) {
				kanjoKamokuMstMap.put(mst.Kanjocode__c, mst);
			}
		}
		// 2018/08/06 税込金額から消費税を計算する BEGIN
		if (gccInfo.isTaxAutoCalFlg) {
			CONST_CSVDATA_TEMPLATE = '$$_伝票区切_$$,$$_伝票日付_$$,$$_伝票番号_$$,$$_借方部門コード_$$,$$_借方科目コード_$$,$$_借方補助コード_$$,$$_借方金額_$$,'
													  +'$$_貸方部門コード_$$,$$_貸方科目コード_$$,$$_貸方補助コード_$$,$$_貸方金額_$$,$$_摘要_$$,$$_貸方消費税計算_$$\n';
		}
		// 2018/08/06 税込金額から消費税を計算する END
		// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
		if (gccInfo.isExtraMode) {
			CONST_CSVDATA_TEMPLATE = '$$_伝票区切_$$,$$_伝票日付_$$,$$_借方部門コード_$$,$$_借方科目コード_$$,$$_借方補助コード_$$,$$_借方金額_$$,$$_借方税区分_$$,$$_借方税率_$$,$$_借方軽減税率_$$,$$_借方摘要_$$,'
												           +'$$_貸方部門コード_$$,$$_貸方科目コード_$$,$$_貸方補助コード_$$,$$_貸方金額_$$,$$_貸方税区分_$$,$$_貸方税率_$$,$$_貸方軽減税率_$$,$$_貸方摘要_$$';
			// 2020.04.17. 1.9.勘定奉行連携CSVの改善（CSJS306列追加) WSQ BEGIN
			if (gccInfo.isTaxAutoCalFlg) CONST_CSVDATA_TEMPLATE += ',$$_貸方消費税計算_$$';	
			CONST_CSVDATA_TEMPLATE += '\n';
			// 2020.04.17. 1.9.勘定奉行連携CSVの改善（CSJS306列追加) WSQ END
		}
		// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
		// 2018/06/12 仕訳Rollup機能追加対応 BEGIN
		gKanjoKamokuMstMap = kanjoKamokuMstMap;
		gInitStartNo = ccInfo.startno;
		// 2018/06/12 仕訳Rollup機能追加対応 END
		// CsvBody情報作成開始
		String csvBody = '';
		// CSV情報追加する
		// ----------------------
		// 入金、出金情報
		// ----------------------
		csvBody += generalDepPayCsvInfo(ccInfo, kanjoKamokuMstMap);
		// ----------------------
		// 会計、会計支払、会計明細
		// ----------------------
		// 会計関連の予約インデックス情報から支払情報を取得する
		// 予約インデックスのIDがNULLの場合、簡易会計として、会計単位で対応する
		// 会計の会計支払と「支払情報」関連情報がなかったの場合、旧会計データとして、そのまま、会計支払情報はPCAそのまま連携する
		csvBody += generalBillCsvInfo(ccInfo, kanjoKamokuMstMap);
		// 明細存在チェックを行う
		isEmptyCsvBody = String.isBlank(csvBody);
		// CSVファイルを戻る
		// 2018/08/06 税込金額から消費税を計算する BEGIN
		//return (isAppendCsvHeaderFlg == true ? (csvHeaderStr + csvBody): csvBody);
		return (isAppendCsvHeaderFlg == true ? (getHeaderStr() + csvBody): csvBody);
		// 2018/08/06 税込金額から消費税を計算する END
	}
	/**
	* 会計関連のPCA連携情報作成を行う
	**/
	private String generalBillCsvInfo (ConvertXmlConfig pCcInfo, Map<String, KanjoKamoku__c> pKanjoKamokuMstMap) {
		// 処理日の関連会計情報を取得する
		// 会計処理モード：１　OR　２
		String billEditMode = CommDefine__c.getOrgDefaults().BillInputSwitchCode__c;
		// 旧会計モード
		Boolean isOldBillModeFlg = (billEditMode == BillInputSwitchCtrl.BILL_LAYOUT_CODE_2 ? false : true);
		// VOIDフラグ
		String accVoidVal = CommConst.ACC_TRADE_VOID;
		// 支払メデイアと会計商品（支払）MAPPING情報取得 Map<会計商品コード・会計商品>
		// 会計支払の支払商品がなかったの場合、該当定義情報により、関連の会計商品から会計科目情報を取得する
		Map<String, AccountMaster__c> mediaPayProdMap = pCcInfo.mediaProductCdMap;

		// 会計情報を取得、PCA連携情報を作成する
		// 指定の売上計上日から該当日付の売上明細を取得する「会計明細」
		String querySQL = 'Select Id,frs__r.Name,name,RoomName__c,SumTax__c,ContactName__c,ShopCode__c ,Relreserve__c,'
						+ 'Relreserve__r.LeadIndexRef__c, '
						+ 'Relreserve__r.LeadIndexSubId__c, '
						+ 'Relreserve__r.RoomGroupNo__c, '
						+ 'relaccount__r.Account.ID__c, '
						+ 'Relreserve__r.No__c, '
						+ 'Relreserve__r.Rroom__r.Name, '
						+ 'Relreserve__r.Relcontact__r.Name, '
		 					// 会計明細
		 				+ '(Select GoukeinoneTax__c ,Field41__c,Accountoutside__c '+			// 利用金額（税込）と利用金額（税抜き）
		 					' ,Field7__r.KanjoKamokuRef__r.KanjocodeCode__c '+
		 					' ,Field7__r.KanjoKamokuRef__r.KanjoHojocode__c '+
		 					' ,Field7__r.KanjoKamokuRef__r.DebitTaxKbn__c '+
		 					' ,Field7__r.KanjoKamokuRef__r.CreditTaxKbn__c '+
		 					// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
		 					' ,Field7__r.KanjoKamokuRef__r.DebitDepartCode__c '+
		 					' ,Field7__r.KanjoKamokuRef__r.CreditDepartCode__c '+
		 					// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
		 					// 2018/08/06 税込金額から消費税を計算する BEGIN
		 					' ,Field7__r.TaxRateCal__c '+
		 					' ,ParentTran1Ref__c,Field23__c,TaxRate__c '+
		 					// 2018/08/06 税込金額から消費税を計算する END
		 					' From TranAccount__r '+
		 					// 商品種別はプランのBreakDown項目と普通の会計明細
		 					' where ActionType__c != :PROD_ACTION_TYPE_PL And ActionType__c != :PROD_ACTION_TYPE_AR  ' +
		 					//' And Accountoutside__c = 1 ' +
		 					// 請求書非表示は対象外
		 					//' And InvoiceNoShowFlg__c = false ' +
		 					// 有効な明細　OR　親が存在 AND　親は有効な明細
		 					// 2018/06/12 仕訳Rollup機能追加対応 BEGIN
		 					//' And ( ( InvoiceNoShowFlg__c = false And ParentTran1Ref__c = null And Accountoutside__c = 1) OR (ParentTran1Ref__c != null And ParentTran1Ref__r.Accountoutside__c = 1 And ParentTran1Ref__r.InvoiceNoShowFlg__c = false) ) ' +
		 					(
		 						gccInfo.isNoshowOutFlg 
		 						? ' And ( ( ParentTran1Ref__c = null And Accountoutside__c = 1) OR (ParentTran1Ref__c != null And ParentTran1Ref__r.Accountoutside__c = 1 ) ) '
		 						: ' And ( ( InvoiceNoShowFlg__c = false And ParentTran1Ref__c = null And Accountoutside__c = 1) OR (ParentTran1Ref__c != null And ParentTran1Ref__r.Accountoutside__c = 1 And ParentTran1Ref__r.InvoiceNoShowFlg__c = false) ) '
		 					) +
		 					// 2018/06/12 仕訳Rollup機能追加対応 END
		 					' order by rowNo__c,name),'
		 					// 会計支払[Field2__c:メディア種別]
		 				+ '(Select Field2__c, Field3__c, CardTypeLst__c, PayProductName__c,CouponTypeLst__c, Field20__c, Field19__c,OutSideAccount__c ' +
		 					' ,PayProductRef__r.KanjoKamokuRef__r.KanjoHojocode__c '+
		 					' ,PayProductRef__r.KanjoKamokuRef__r.KanjocodeCode__c '+
		 					' ,PayProductRef__r.KanjoKamokuRef__r.DebitTaxKbn__c '+
		 					' ,PayProductRef__r.KanjoKamokuRef__r.CreditTaxKbn__c  '+
		 					// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
		 					' ,PayProductRef__r.KanjoKamokuRef__r.DebitDepartCode__c '+
		 					' ,PayProductRef__r.KanjoKamokuRef__r.CreditDepartCode__c '+
		 					// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
		 					//' From TranTotalfromPay__r where OutSideAccount__c = 1 order by name ) From AccountAcount__c ';
		 					' From TranTotalfromPay__r where (Field28__c != null AND Field28__c != 0) order by name ) From AccountAcount__c ';
		// 有効な会計情報 && 指定の売上日
		//String queryWhere = 'where OutSideAccount__c = 1 And frs__c = :gRsvAccoutId ';
		String queryWhere = 'where Field39__c != :accVoidVal And frs__c = :gRsvAccoutId ';
		//String queryWhere = 'where frs__c = :gRsvAccoutId ';
		// 指定の店舗情報が存在すると、個別の店舗
		if(!CommUtils.isBlank(gShopCode)) queryWhere += ' And ShopCode__c = :gShopCode ';
		// 並び順：会計名
		queryWhere += ' Order By frs__c, Name';		
//System.debug(Logginglevel.INFO, 'querySQL:::' + querySQL + queryWhere);
		List<AccountAcount__c> accs = Database.query(querySQL + queryWhere);
		List<AccountAcount__c> accTargets = new List<AccountAcount__c>();
		for (AccountAcount__c acc : accs) {
			// 会計明細がなかったの場合、該当会計はPCA抽出対象外になる
//			if (acc.TranAccount__r.isEmpty()) continue;
			// 会計明細情報取得する
			List<Tran1__c> trans = acc.TranAccount__r;
			// 会計支払情報取得する
			List<TTend__c> ttends = acc.TranTotalfromPay__r;
			if (trans.isEmpty() && ttends.isEmpty()) continue;	// 空な会計情報は対象外になる
			accTargets.add(acc);
		}
		// 処理対象なし
		if (accTargets.isEmpty()) return '';
		// 処理日（売上日）を設定する
		gRsvName = accTargets[0].frs__r.Name;
		// PCA連携用情報を自動設定を行う
		// 旧モードの場合、PCA連携情報準備
		if (isOldBillModeFlg) {
			preOldSyncPaymentInfo(accTargets);
		} 
		// 新モードの場合、PCA連携情報準備
		else {
			preSyncPaymentInfo(accTargets);
		}
		// 会計支払のCSV情報を格納する
		return generalNewBillCsvInfo(accTargets, pCcInfo, mediaPayProdMap ,pKanjoKamokuMstMap );		
	}

	
	/**
	* 旧会計編集ロジックの場合、PCA連携情報作成を行う
	**//* 封印
	private String generalOldBillCsvInfo (List<AccountAcount__c> accs, 
											ConvertXmlConfig pCcInfo, 
											Map<String, AccountMaster__c> pMediaPayProdMap,
											Map<String, KanjoKamoku__c> pKanjoKamokuMstMap) {
		String csvBody = '';
		if (accs.isEmpty()) return csvBody;
		
		String CsvTemplate = CONST_CSVDATA_TEMPLATE
								.Replace('$$_Ver_$$'			, pCcInfo.ver)
								.Replace('$$_伝票日付_$$'			, accs[0].frs__r.Name)
								.Replace('$$_借方部門コード_$$'	, pCcInfo.debdepartcode)
								.Replace('$$_借方消費税額_$$'		, pCcInfo.debconsumptax)
								.Replace('$$_貸方部門コード_$$'	, pCcInfo.credepartcode)
								.Replace('$$_貸方消費税額_$$'		, pCcInfo.creconsumptax)
								.Replace('$$_入力プログラム区分_$$'	, pCcInfo.inputprogramkbn);
		Integer startNo = pCcInfo.startno;
		// 該当店舗の該当売上日の全会計情報のPCA情報を出力する
		for (AccountAcount__c acc : accs){
			// 会計単位のPCA情報を取得する
			// 会計支払情報取得する
			List<TTend__c> ttends = acc.TranTotalfromPay__r;
			// 会計明細情報取得する
			List<Tran1__c> trans = acc.TranAccount__r;
			// 1会計の関連情報を出力する
			String oneAccCsv = '';
			// 摘要情報「部屋NOと宿泊者名」
			String simpleCommnt = CONST_CSVDATA_COMMENT_TEMPLATE
										.Replace('$$_ROOMNO_$$'		, CommUtils.nullToBlank(acc.RoomName__c))
										.Replace('$$_GUESTNAME_$$'	, CommUtils.nullToBlank(acc.ContactName__c));
			String SingAccCsvTemplate = CsvTemplate
										.Replace('$$_摘要_$$'		, simpleCommnt)
										.Replace('$$_伝票番号_$$'		, String.valueOf(startNo));
			// 次の会計番号を計算する
			startNo++;

			// 該当会計関連の支払情報を取得する
			csvBody += genOldOneAccAcountCsv(acc, ttends, trans, 
											SingAccCsvTemplate, 
											pMediaPayProdMap, 
											pKanjoKamokuMstMap, 
											pCcInfo);
		}
		return csvBody;
	}*/
	/**
	* １会計情報関連のCSV情報を出力する（旧会計モード）
	**/
	private String genOldOneAccAcountCsv(AccountAcount__c acc,
										List<TTend__c> ttends, 
										List<Tran1__c> trans, 
										String csvTemplate,
										Map<String, AccountMaster__c> pMediaPayProdMap,
										Map<String, KanjoKamoku__c> pKanjoKamokuMstMap,
										ConvertXmlConfig pCcInfo,
										Integer startNo) {
		// 該当会計関連のCSV情報
		String oneAccCsv = '';
		// 最大LOOPサイズを取得する
		Integer ttendSize   = ttends.size();
		Integer tranSize	= trans.size();
		Integer maxLoopSize = ttendSize > tranSize ? ttendSize : tranSize;
		Integer taxOuputLineNum = tranSize;	// 消費税出力行目[会計明細の次の行目から出力する]
		// 2019/09/20 多税率機能対応 WSQ BEGIN
		//Decimal amountIncTax = 0;	// 税込み合計金額
		//Decimal amountNoTax  = 0;	// 税抜き合計金額
		// map<税率，該当税率の合計金額>
		map<decimal,decimal> amountIncTaxMap = new map<decimal,decimal>(); 	// 税込み合計金額
		// map<税率，該当税率の合計金額>
		map<decimal,decimal> amountNoTaxMap = new map<decimal,decimal>(); 	// 税抜き合計金額
		// 2019/09/20 多税率機能対応 WSQ END
// 2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする BEGIN
Integer leftAmount = 0, rightAmount = 0;
// 2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする END
		// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
		String simpleComment = getSimpleComment(acc, startNo, csvTemplate, false);
		// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
		for (Integer i = 0; i < maxLoopSize; i++) {
			// CSVの左側の支払情報を作成する
			// １行目のCSV出力情報初期化設定[1会計単位]
			String csvLine = csvTemplate;
			// 借方情報の支払情報を出力する
			if (i < ttendSize) {
				
				TTend__c ttend = ttends[i];
				// 注意：支払メデイアは売掛金の場合、補助科目に、会計関連の取引先のID__C項目のコード取得して、設定する
				// 関連の商品情報が存在する場合、関連の支払情報の会計科目設定情報により、CSVへ出力する
				if (ttend.PayProductRef__c == null) {
					// カード種別と金券種別の設定情報により、会計科目情報を設定する
					// カード種別　OR　金券種別で会計科目情報を取得する場合、支払メデイアの関連会計科目は非設定する
					AccountMaster__c accMst = new AccountMaster__c();
					// カード種別の場合
					if (ttend.Field2__c == CommConst.MEDIA_TYPE_CD_02 && !CommUtils.isBlank(ttend.CardTypeLst__c)) {
						String seqNo = pCcInfo.mediaCardMap.get(ttend.CardTypeLst__c);
						if (!CommUtils.isBlank(seqNo) && pKanjoKamokuMstMap.containsKey(seqNo)) accMst.KanjoKamokuRef__r = pKanjoKamokuMstMap.get(seqNo);
					}
					// クポーン　OR　割引の場合
					else if ((ttend.Field2__c == CommConst.MEDIA_TYPE_CD_11 ||
							  ttend.Field2__c == CommConst.MEDIA_TYPE_CD_12) && !CommUtils.isBlank(ttend.CouponTypeLst__c)) {
						String seqNo = pCcInfo.mediaKinkenMap.get(ttend.CouponTypeLst__c);
						if (!CommUtils.isBlank(seqNo) && pKanjoKamokuMstMap.containsKey(seqNo)) accMst.KanjoKamokuRef__r = pKanjoKamokuMstMap.get(seqNo);
					}
					if (accMst.KanjoKamokuRef__r == null) {
					// 支払Mediaラベルから関連の会計商品を取得する
					//AccountMaster__c accMst = pMediaPayProdMap.get(ttend.Field3__c);
					//if (accMst == null) accMst = new AccountMaster__c();
						if (pMediaPayProdMap.containsKey(ttend.Field3__c)) accMst = pMediaPayProdMap.get(ttend.Field3__c);
					}
					ttend.PayProductRef__r = accMst.clone(false,true);
				} 
				// 関連の支払商品から会計科目情報を取得する
				AccountMaster__c accMst = ttend.PayProductRef__r;
				// 関連商品から左側の情報を会計科目情報を設定する

				// 支払メデイア種別は売掛金の場合、取引先からコード設定を行う
				//String kanjoHojocode = CommUtils.nullToBlank(accMst.KanjoKamokuRef__r.KanjoHojocode__c);
				if (ttend.Field2__c == CommConst.MEDIA_TYPE_CD_03 && accMst.KanjoKamokuRef__r != null) {
					// 掛計の場合、カード種別、金券種別項目を設定されている場合、該当カード種別と金券種別経由で会計科目情報を取得する
					// 該当関連の会計科目情報はなかった場合、取引先のID情報で補助科目情報を設定する
					/* 2015/03/12 掛計の処理ロジック変更を行う
					Boolean isAutoSetupFlg = false;
					if (!CommUtils.isBlank(ttend.CardTypeLst__c)) {
						String seqNo = pCcInfo.mediaCardMap.get(ttend.CardTypeLst__c);
						if (!CommUtils.isBlank(seqNo) && pKanjoKamokuMstMap.containsKey(seqNo)) {
							accMst.KanjoKamokuRef__r.KanjoHojocode__c = pKanjoKamokuMstMap.get(seqNo).KanjoHojocode__c;	
							isAutoSetupFlg = true;
						}
					} else if (!CommUtils.isBlank(ttend.CouponTypeLst__c)){
						String seqNo = pCcInfo.mediaKinkenMap.get(ttend.CouponTypeLst__c);
						if (!CommUtils.isBlank(seqNo) && pKanjoKamokuMstMap.containsKey(seqNo)) {
							accMst.KanjoKamokuRef__r.KanjoHojocode__c = pKanjoKamokuMstMap.get(seqNo).KanjoHojocode__c;
							isAutoSetupFlg = true;
						}
					}
					//　カード種別、金券種別項目設定なかった場合、取引先のID項目で補助科目情報を設定する
					if (!isAutoSetupFlg) {
						accMst.KanjoKamokuRef__r.KanjoHojocode__c = CommUtils.nullToBlank(acc.relaccount__r.Account.ID__c);
					}*/
					// 請求先の企業コードが存在する場合、該当企業コードを補助科目コードに設定する
					if (!CommUtils.isBlank(acc.relaccount__r.Account.ID__c)) {
						accMst.KanjoKamokuRef__r.KanjoHojocode__c = CommUtils.nullToBlank(acc.relaccount__r.Account.ID__c);
					}
					//accMst.KanjoKamokuRef__r.KanjoHojocode__c = CommUtils.nullToBlank(acc.relaccount__r.Account.ID__c);
				} 
				Decimal paymentAmount = Commutils.nullToZero(ttend.Field19__c);
				csvLine = csvLine
					.Replace('$$_伝票区切_$$'			, getDenhyouDivMark(acc))
					.Replace('$$_借方科目コード_$$'	, CommUtils.nullToBlank(accMst.KanjoKamokuRef__r.KanjocodeCode__c))
					.Replace('$$_借方補助コード_$$'	, CommUtils.nullToBlank(accMst.KanjoKamokuRef__r.KanjoHojocode__c))
					//.Replace('$$_借方税区分_$$'		, CommUtils.nullToBlank(accMst.KanjoKamokuRef__r.DebitTaxKbn__c))
					.Replace('$$_借方金額_$$'			, String.valueOf(paymentAmount.intValue()));
				// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
				if (pCcInfo.isExtraMode) {
					csvLine = csvLine
						.replace('$$_借方部門コード_$$'	,getDepartCode(CommUtils.nullToBlank(accMst.KanjoKamokuRef__r.DebitDepartCode__c), true))
						.replace('$$_借方税区分_$$'		,CommUtils.nullToBlank(accMst.KanjoKamokuRef__r.DebitTaxKbn__c))
						.replace('$$_借方税率_$$'			,'')
						.replace('$$_借方軽減税率_$$'		,'')
						.replace('$$_借方摘要_$$'			,simpleComment);
				}
				// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
// 2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする BEGIN
leftAmount += CommUtils.nullToIntZero(paymentAmount);
// 2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする END

// 2018/06/12 仕訳Rollup機能追加対応 BEGIN
setupRollupInfo(acc.frs__r.Name,
				// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) BEGIN
				//CommUtils.nullToBlank(accMst.KanjoKamokuRef__r.KanjocodeCode__c),
				accMst.KanjoKamokuRef__r,
				// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) END
				String.valueOf(paymentAmount),
				ROLLUP_TYPE.SALES_L);
// 2018/06/12 仕訳Rollup機能追加対応 END	

			} else {
				csvLine = csvLine
						.Replace('$$_伝票区切_$$'			,getDenhyouDivMark(acc))
						.Replace('$$_借方科目コード_$$'	,'')
						.Replace('$$_借方補助コード_$$'	,'')
						//.Replace('$$_借方税区分_$$'	,'')
						.Replace('$$_借方金額_$$'	,'');
				// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
				// 借方の情報項目を空欄を設定する
				if (pCcInfo.isExtraMode) {
					csvLine = csvLine
						.replace('$$_借方部門コード_$$'	,'')
						.replace('$$_借方税区分_$$'		,'')
						.replace('$$_借方税率_$$'			,'')
						.replace('$$_借方軽減税率_$$'		,'')
						.replace('$$_借方摘要_$$'			,'');
				}
				// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
			}
			// 貸方側の会計明細情報を出力する
// 2018/08/06 税込金額から消費税を計算する BEGIN
String taxCalType = TaxCalType0;
// 2018/08/06 税込金額から消費税を計算する END
			if (i < tranSize) {
				Tran1__c tran = trans[i];
				// 2019/09/20 多税率機能対応 WSQ BEGIN
				decimal taxrate = CommUtils.nullToZero(tran.TaxRate__c == null ? tran.Field7__r.TaxRateCal__c : tran.TaxRate__c); // 消費税率
				// 2019/09/20 多税率機能対応 WSQ END
				Decimal tanknotax = CommUtils.nullToZero(tran.GoukeinoneTax__c);
				// 2018/08/06 税込金額から消費税を計算する BEGIN
				if (gccInfo.isTaxAutoCalFlg) {
					tanknotax = CommUtils.nullToZero(tran.Field41__c);
				 	// 消費税が０場合、
				 	// 2019/09/20 多税率機能対応 WSQ BEGIN
				 	//Decimal taxRate = CommUtils.nullToZero(tran.Field7__r.TaxRateCal__c);
				 	// 2019/09/20 多税率機能対応 WSQ END
				 	if (taxRate > 0) taxCalType = TaxCalType2;
				}
				// 2018/08/06 税込金額から消費税を計算する END
				csvLine = csvLine
						.Replace('$$_貸方科目コード_$$'	, CommUtils.nullToBlank(tran.Field7__r.KanjoKamokuRef__r.KanjocodeCode__c))
						.Replace('$$_貸方補助コード_$$'	, CommUtils.nullToBlank(tran.Field7__r.KanjoKamokuRef__r.KanjoHojocode__c))
						//.Replace('$$_貸方税区分_$$'		, CommUtils.nullToBlank(tran.Field7__r.KanjoKamokuRef__r.CreditTaxKbn__c))
					 	.Replace('$$_貸方金額_$$'			, String.valueOf(tanknotax.intValue()));
			 	// 2019/09/20 多税率機能対応 WSQ BEGIN	
				// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
				if (pCcInfo.isExtraMode) {
					csvLine = csvLine
						.replace('$$_貸方部門コード_$$'	, getDepartCode(CommUtils.nullToBlank(tran.Field7__r.KanjoKamokuRef__r.CreditDepartCode__c), false))
						.replace('$$_貸方税区分_$$' 		, CommUtils.nullToBlank(tran.Field7__r.KanjoKamokuRef__r.CreditTaxKbn__c))
						.replace('$$_貸方税率_$$'			, CommUtils.nullToBlank(formatOuputTaxRate(taxrate)))
						.replace('$$_貸方軽減税率_$$'		, getReducedFlg(taxrate))
						.replace('$$_貸方摘要_$$'			, simpleComment);
				}
				// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
			 	// 実際利用金額
			 	//amountIncTax += CommUtils.nullToZero(tran.Field41__c);
			 	//amountNoTax  += CommUtils.nullToZero(tran.GoukeinoneTax__c);		 	
			 	if (!amountIncTaxMap.containskey(taxrate)) amountIncTaxMap.put(taxrate, CommUtils.nullToZero(tran.Field41__c));
			 	else amountIncTaxMap.put(taxrate, (amountIncTaxMap.get(taxrate) + CommUtils.nullToZero(tran.Field41__c)));
			 	if (!amountNoTaxMap.containskey(taxrate)) amountNoTaxMap.put(taxrate, CommUtils.nullToZero(tran.GoukeinoneTax__c));
			 	else amountNoTaxMap.put(taxrate, (amountNoTaxMap.get(taxrate) + CommUtils.nullToZero(tran.GoukeinoneTax__c)));
			 	// 2019/09/20 多税率機能対応 WSQ END
			 	// 2016/11/21 出力金額の小数点対応できる改善 END

// 2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする BEGIN
rightAmount += CommUtils.nullToIntZero(tanknotax);
// 2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする END
// 2018/06/12 仕訳Rollup機能追加対応 BEGIN
setupRollupInfo(acc.frs__r.Name,
				// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) BEGIN
				//CommUtils.nullToBlank(tran.Field7__r.KanjoKamokuRef__r.KanjocodeCode__c),
				tran.Field7__r.KanjoKamokuRef__r,
				// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) END
				String.valueOf(tanknotax),
				ROLLUP_TYPE.SALES_R);
// 2018/06/12 仕訳Rollup機能追加対応 END	
			} else {
				// 消費税出力行目は残りままが必要
				if (i != taxOuputLineNum) {
					csvLine = csvLine
						.Replace('$$_貸方科目コード_$$'	, '')
						.Replace('$$_貸方補助コード_$$'	, '')
						//.Replace('$$_貸方税区分_$$'	, '')
						.Replace('$$_貸方金額_$$'	, '');
					// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
					// 借方の情報項目を空欄を設定する
					if (pCcInfo.isExtraMode) {
						csvLine = csvLine
							.replace('$$_貸方部門コード_$$'	,'')
							.replace('$$_貸方税区分_$$'		,'')
							.replace('$$_貸方税率_$$'			,'')
							.replace('$$_貸方軽減税率_$$'		,'')
							.replace('$$_貸方摘要_$$'			,'');
					}
					// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
				}
			}
			// 2018/08/06 税込金額から消費税を計算する BEGIN
			csvLine = getTaxCalInfo(csvLine,taxCalType);
			// 2018/08/06 税込金額から消費税を計算する END
			oneAccCsv += csvLine;
		} // for (Integer i = 0; i < maxLoopSize; i++)
		
// 2019/09/20 多税率機能対応 WSQ BEGIN
list<decimal> taxratelst = new list<decimal>();
for (decimal key : amountIncTaxMap.keyset()) {taxratelst.add(formattax(key));}
taxratelst.sort();
for (decimal taxrate : taxratelst) {
		decimal amountIncTax = amountIncTaxMap.get(taxrate);//税込み金額
		decimal amountNoTax = amountNoTaxMap.get(taxrate);//税抜金額
// 2019/09/20 多税率機能対応 WSQ END
		// 消費税情報はCSVへ反映する
		KanjoKamoku__c kankoMst = pKanjoKamokuMstMap.get(pCcInfo.taxKanjoCode);
		if (kankoMst == null) kankoMst = new KanjoKamoku__c();
		Decimal taxPayAmount = amountIncTax - amountNoTax;
		// 支払情報行数 > 会計明細行数の場合、会計明細の次の行に設定を行う
		if (ttendSize > tranSize) {
			// 既存の情報から入り替えする[1行のみ消費税情報を入れる]
			// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
			if (pCcInfo.isExtraMode) oneAccCsv = replaceRightComment(oneAccCsv, simpleComment);
			// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
			oneAccCsv = getTaxCsvLine(oneAccCsv, taxPayAmount, kankoMst,false, true);
		} else {
			// 新行目に消費税情報を作成する
			// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
			if (pCcInfo.isExtraMode) csvTemplate = replaceRightComment(csvTemplate, simpleComment);
			// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
			oneAccCsv += getTaxCsvLine(csvTemplate, taxPayAmount, kankoMst, true, true);
		}
		// 消費税出力により、混在税率の場合、右の行数＋＋
		tranSize++;
// 2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする BEGIN
// 商品税行目は別行目を出力の場合、消費税自動計算が必要
if (!gccInfo.isTaxAutoCalFlg) rightAmount += CommUtils.nullToIntZero(taxPayAmount);
// 2019/09/20 多税率機能対応 WSQ BEGIN
		// 残り部分は全部クリアを行う
		KanjoKamoku__c clearKankoMst = new KanjoKamoku__c();
		oneAccCsv = getTaxCsvLine(oneAccCsv, taxPayAmount, kankoMst, false);
}   
// 2019/09/20 多税率機能対応 WSQ END
if (leftAmount != rightAmount) {
	//伝票番号
	//が同じ仕訳の借方金額と貸方金額が一致しません。
	msgStr += Label.CONST_046_0031 +'【'+startNo+'】'+ Label.CONST_046_0032 +'\n';
}
// 2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする END
		return oneAccCsv;
	}
	
	/**
	* 消費税行目のCSV情報を取得する
	**/
	private String getTaxCsvLine(String csvTemplate, Decimal taxAmount, KanjoKamoku__c kankoMst, boolean isNewLine) {
	    return getTaxCsvLine(csvTemplate, taxAmount, kankoMst, isNewLine, false);
	}
	/**
	* 消費税行目のCSV情報を取得する
	**/
	private String getTaxCsvLine(String csvTemplate, Decimal taxAmount, KanjoKamoku__c kankoMst, boolean isNewLine, Boolean isRepFirst) {
		// 2018/08/06 税込金額から消費税を計算する BEGIN
//System.debug(loggingLevel.info, 'csvTemplate='+csvTemplate);
		// 税込みから消費税金額計算場合、消費税行目出力が不要になる
		if (gccInfo.isTaxAutoCalFlg && isNewLine) return '';
		// 2018/08/06 税込金額から消費税を計算する END
		String csv = csvTemplate
					.Replace('$$_伝票区切_$$'			,'')// 固定な空白文字列を出力する
					.Replace('$$_借方科目コード_$$'	,'')
					.Replace('$$_借方補助コード_$$'	,'')
					//.Replace('$$_借方税区分_$$'	,'')
					.Replace('$$_借方金額_$$'	,'0');
		// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
		if (gccInfo.isExtraMode) {
			csv = csv
				.replace('$$_借方部門コード_$$'	,'')
				.replace('$$_借方税率_$$'			,'')
				.replace('$$_借方税区分_$$'		,'')
				.replace('$$_借方軽減税率_$$'		,'')
				.replace('$$_借方摘要_$$'			,'');
		}
		// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
		// 2018/08/06 税込金額から消費税を計算する BEGIN
		if (gccInfo.isTaxAutoCalFlg) {
			csv = csv
					// 消費税情報を設定する
					.Replace('$$_貸方科目コード_$$'	,'')
					.Replace('$$_貸方補助コード_$$'	,'')
					//.Replace('$$_貸方税区分_$$'		, CommUtils.nullToBlank(kankoMst.CreditTaxKbn__c))
					.Replace('$$_貸方金額_$$'			,'0');
			// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
			if (gccInfo.isExtraMode) {
				csv = csv
					// 消費税情報を設定する
					.Replace('$$_貸方部門コード_$$'	,'')
					.Replace('$$_貸方税区分_$$'		,'')
					.Replace('$$_貸方税率_$$'			,'')
					.Replace('$$_貸方軽減税率_$$'		,'')
					.Replace('$$_貸方摘要_$$'			,'');
			}
			// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
		} else {
			// 2019/09/20 多税率機能対応 WSQ BEGIN
			if (isRepFirst) {
				csv = csv
					// 消費税情報を設定する
					.ReplaceFirst('\\$\\$_貸方科目コード_\\$\\$'	, CommUtils.nullToBlank(kankoMst.KanjocodeCode__c))
					.ReplaceFirst('\\$\\$_貸方補助コード_\\$\\$'	, CommUtils.nullToBlank(kankoMst.KanjoHojocode__c))
					.ReplaceFirst('\\$\\$_貸方金額_\\$\\$'		, String.valueOf(taxAmount.intValue()));
				// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
				if (gccInfo.isExtraMode) {
					csv = csv
						// 消費税情報を設定する
						.ReplaceFirst('\\$\\$_貸方部門コード_\\$\\$'	, CommUtils.nullToBlank(kankoMst.CreditDepartCode__c))
						.ReplaceFirst('\\$\\$_貸方税区分_\\$\\$'		, CommUtils.nullToBlank(kankoMst.CreditTaxKbn__c))
						.ReplaceFirst('\\$\\$_貸方税率_\\$\\$'		, '')
						.ReplaceFirst('\\$\\$_貸方軽減税率_\\$\\$'		, '');
				}
				// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
			} else {
				csv = csv
					// 消費税情報を設定する
					.Replace('$$_貸方科目コード_$$'	, CommUtils.nullToBlank(kankoMst.KanjocodeCode__c))
					.Replace('$$_貸方補助コード_$$'	, CommUtils.nullToBlank(kankoMst.KanjoHojocode__c))
					//.Replace('$$_貸方税区分_$$'		, CommUtils.nullToBlank(kankoMst.CreditTaxKbn__c))
					.Replace('$$_貸方金額_$$'			, String.valueOf(taxAmount.intValue()));
				// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
				if (gccInfo.isExtraMode) {
					csv = csv
						// 消費税情報を設定する
						.Replace('$$_貸方部門コード_$$'	,getDepartCode(CommUtils.nullToBlank(kankoMst.CreditDepartCode__c), false))
						.Replace('$$_貸方税区分_$$'		,CommUtils.nullToBlank(kankoMst.CreditTaxKbn__c))
						.Replace('$$_貸方税率_$$'			,'')
						.Replace('$$_貸方軽減税率_$$'		,'');
				}
				// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
			}
			// 2019/09/20 多税率機能対応 WSQ END
// 2018/06/12 仕訳Rollup機能追加対応 BEGIN
String strTaxAmount = String.valueOf(taxAmount.intValue());
setupRollupInfo(gRsvName,
				// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) BEGIN
				//CommUtils.nullToBlank(kankoMst.KanjocodeCode__c),
				kankoMst,
				// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) END
				strTaxAmount,
				ROLLUP_TYPE.SALES_R);
// 2018/06/12 仕訳Rollup機能追加対応 END
		}
		return csv;
	}
	
	private String getSingAccCsvTemplate(AccountAcount__c acc, Integer startNo, String CsvTemplate, Boolean isDespoistFlg) {
			// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
			/*
			// 会計明細の
			// 摘要情報「部屋NOと宿泊者名」
			String roomNo = CommUtils.nullToBlank(acc.RoomName__c);
			if (roomNo != CommUtils.nullToBlank(acc.Relreserve__r.Rroom__r.Name)) roomNo = CommUtils.nullToBlank(acc.Relreserve__r.Rroom__r.Name) ;
			// お客情報の出力
			String contactName = CommUtils.nullToBlank(acc.ContactName__c).trim();
			if (CommUtils.isBlank(contactName)) contactName = CommUtils.nullToBlank(acc.Relreserve__r.Relcontact__r.Name);
			String simpleCommnt = CONST_CSVDATA_COMMENT_TEMPLATE
			//予約No
			//部屋No
										.Replace('$$_COMMENTLAB_$$' , (isDespoistFlg == true ? Label.CONST_046_0033 : Label.CONST_046_0034))
										.Replace('$$_ROOMNO_$$'		, (isDespoistFlg == true ? CommUtils.nullToBlank(acc.Relreserve__r.No__c) : roomNo))
										.Replace('$$_GUESTNAME_$$'	, contactName);
			*/
			String simpleCommnt = getSimpleComment(acc, startNo, CsvTemplate, isDespoistFlg);
			// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
			String SingAccCsvTemplate = CsvTemplate
										.Replace('$$_摘要_$$'		, simpleCommnt)
										.Replace('$$_伝票番号_$$'		, String.valueOf(startNo));
			return SingAccCsvTemplate;
	}
	// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
	// 会計の摘要取得処理
	private String getSimpleComment(AccountAcount__c acc, Integer startNo, String CsvTemplate, Boolean isDespoistFlg) {
			// 摘要情報「部屋NOと宿泊者名」
			String roomNo = CommUtils.nullToBlank(acc.RoomName__c);
			if (roomNo != CommUtils.nullToBlank(acc.Relreserve__r.Rroom__r.Name)) roomNo = CommUtils.nullToBlank(acc.Relreserve__r.Rroom__r.Name) ;
			// お客情報の出力
			String contactName = CommUtils.nullToBlank(acc.ContactName__c).trim();
			if (CommUtils.isBlank(contactName)) contactName = CommUtils.nullToBlank(acc.Relreserve__r.Relcontact__r.Name);
			String simpleCommnt = CONST_CSVDATA_COMMENT_TEMPLATE
					//予約No
					//部屋No
					.Replace('$$_COMMENTLAB_$$' , (isDespoistFlg == true ? Label.CONST_046_0033 : Label.CONST_046_0034))
					.Replace('$$_ROOMNO_$$'		, (isDespoistFlg == true ? CommUtils.nullToBlank(acc.Relreserve__r.No__c) : roomNo))
					.Replace('$$_GUESTNAME_$$'	, contactName);
			return simpleCommnt;
	}
	private String replaceRightComment(String orgs, String val) {
		return (orgs.replace('$$_貸方摘要_$$', val));
	}
	// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
	/**
	* 該当処理前に、出力の支払明細は事前に全部作成を行うが必要
	* 新会計編集ロジックの場合、PCA連携情報作成を行う
	* 2015/06/29 予約金、返金の個別出力機能を追加する
	**/
	private String generalNewBillCsvInfo (List<AccountAcount__c> accs, 
											ConvertXmlConfig pCcInfo, 
											Map<String, AccountMaster__c> pMediaPayProdMap,
											Map<String, KanjoKamoku__c> pKanjoKamokuMstMap) {

		String csvBody = '';
		if (accs.isEmpty()) return csvBody;
		
		String CsvTemplate = CONST_CSVDATA_TEMPLATE
								//.Replace('$$_伝票区切_$$'			, pCcInfo.ver)
								.Replace('$$_伝票日付_$$'			, getDenhyouDateStr(accs[0].frs__r.Name))
								// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
								//.Replace('$$_借方部門コード_$$'	, pCcInfo.debdepartcode)
								//.Replace('$$_借方消費税額_$$'		, pCcInfo.debconsumptax)
								//.Replace('$$_貸方部門コード_$$'	, pCcInfo.credepartcode);
								;
								// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
								//.Replace('$$_貸方消費税額_$$'		, pCcInfo.creconsumptax)
								//.Replace('$$_入力プログラム区分_$$'	, pCcInfo.inputprogramkbn);
		if (!pCcInfo.isExtraMode) {
			CsvTemplate = CsvTemplate
				.Replace('$$_借方部門コード_$$'	, pCcInfo.debdepartcode)
				.Replace('$$_貸方部門コード_$$'	, pCcInfo.credepartcode);
		}					
		// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
		Integer startNo = pCcInfo.startno;

		Set<Id> leadIdxIdsSet = new Set<Id>();
		Set<Id> accIdsSet = new Set<Id>();
		for (AccountAcount__c acc : accs) {
			// 処理対象会計
			accIdsSet.add(acc.Id);
		}
		// Map<会計ID,List<支払明細>>
		Map<Id, List<PaymentDetail__c>> payDetailMap = new Map<Id, List<PaymentDetail__c>>();
		// 予約金関連情報格納
		Map<Id, List<PaymentDetail__c>> despoistOnepayDetailMap = new Map<Id, List<PaymentDetail__c>>();	//	予約金情報のみ存在のケース
		Map<Id, List<PaymentDetail__c>> despoistSecpayDetailMap = new Map<Id, List<PaymentDetail__c>>();	//	チェックイン日から使うの予約金情報を格納する
		// 返金関連情報格納
		Map<Id, List<PaymentDetail__c>> refundDetailMap = new Map<Id, List<PaymentDetail__c>>();
		// 既存の支払情報を取得する
		for (PaymentDetail__c pay :[ select id,AccountAcountRef__c,RemainingMoney__c, DepositAmount__c, UsedAmount__c
										,PaymentInfoRef__r.ChildRenRsCount__c		// 明細件数
										//,PaymentInfoRef__r.RemainingMoney__c		// 残金
										,PaymentInfoRef__r.TTendRef__c				// 会計支払
										,PaymentInfoRef__r.TTendRef__r.Field2__c	// 支払メデイアコード
										,PaymentInfoRef__r.TTendRef__r.Field3__c
										,PaymentInfoRef__r.TTendRef__r.Field19__c
										,PaymentInfoRef__r.TTendRef__r.Field20__c
										,PaymentInfoRef__r.TTendRef__r.Field21__c
										,PaymentInfoRef__r.TTendRef__r.PayProductRef__c
										,PaymentInfoRef__r.TTendRef__r.PayProductRef__r.KanjoKamokuRef__r.Kanjocode__c
										,PaymentInfoRef__r.TTendRef__r.PayProductRef__r.KanjoKamokuRef__r.KanjocodeCode__c	// 会計科目コード
										,PaymentInfoRef__r.TTendRef__r.PayProductRef__r.KanjoKamokuRef__r.KanjoHojocode__c	// 補助科目コード
										,PaymentInfoRef__r.TTendRef__r.PayProductRef__r.KanjoKamokuRef__r.DebitTaxKbn__c
										,PaymentInfoRef__r.TTendRef__r.PayProductRef__r.KanjoKamokuRef__r.CreditTaxKbn__c
										// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
										,PaymentInfoRef__r.TTendRef__r.PayProductRef__r.KanjoKamokuRef__r.DebitDepartCode__c
		 								,PaymentInfoRef__r.TTendRef__r.PayProductRef__r.KanjoKamokuRef__r.CreditDepartCode__c
										,PaymentInfoRef__r.TTendRef__r.PayProductRef__r.TaxRateCal__c
										// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
										,PaymentInfoRef__r.TTendRef__r.CardTypeLst__c
										,PaymentInfoRef__r.TTendRef__r.CouponTypeLst__c
										// 2020/11/02 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う） WSQ BEGIN
										,PaymentInfoRef__r.ImgDataFlg__c
										// 2020/11/02 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う） WSQ END
										,PaymentInfoRef__r.Tran1Ref__c					// 会計明細
										,PaymentInfoRef__r.Tran1Ref__r.Field41__c		// 利用金額（税込み）
										,PaymentInfoRef__r.Tran1Ref__r.Field40__c		// 数量
										,PaymentInfoRef__r.Tran1Ref__r.GoukeinoneTax__c	// $合計金額（税抜）
										// 2019/09/20 多税率機能対応 WSQ BEGIN
										,PaymentInfoRef__r.Tran1Ref__r.TaxRate__c
										// 2019/09/20 多税率機能対応 WSQ END
										,PaymentInfoRef__r.Tran1Ref__r.Field7__c
										,PaymentInfoRef__r.Tran1Ref__r.Field7__r.KanjoKamokuRef__r.Kanjocode__c
		 								,PaymentInfoRef__r.Tran1Ref__r.Field7__r.KanjoKamokuRef__r.KanjocodeCode__c			// 会計科目コード
		 								,PaymentInfoRef__r.Tran1Ref__r.Field7__r.KanjoKamokuRef__r.KanjoHojocode__c			// 補助科目コード
		 								,PaymentInfoRef__r.Tran1Ref__r.Field7__r.KanjoKamokuRef__r.DebitTaxKbn__c
		 								,PaymentInfoRef__r.Tran1Ref__r.Field7__r.KanjoKamokuRef__r.CreditTaxKbn__c
		 								// 2018/08/06 税込金額から消費税を計算する BEGIN
		 								,PaymentInfoRef__r.Tran1Ref__r.Field7__r.TaxRateCal__c
		 								// 2018/08/06 税込金額から消費税を計算する END
										// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
										,PaymentInfoRef__r.Tran1Ref__r.Field7__r.KanjoKamokuRef__r.DebitDepartCode__c
		 								,PaymentInfoRef__r.Tran1Ref__r.Field7__r.KanjoKamokuRef__r.CreditDepartCode__c
										// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
		 								,PaymentInfoRef__r.PaymentType__c
										// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ BEGIN
		 								,PaymentInfoRef__r.OffsetMoney__c
										// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ END
										from PaymentDetail__c where AccountAcountRef__c in :accIdsSet 
										// 前受付金は先に表示[前受付金の場合、TTendRef__cはNULL]
										Order By AccountAcountRef__c, PaymentInfoRef__r.TTendRef__c NULLS last, Name]) {
			Id accId = pay.AccountAcountRef__c;
			
			// 予約金の場合
			if (pay.PaymentInfoRef__r.PaymentType__c == PAY_TYPE_DESPOIST) {
				// 該当明細は予約金として、PCAのCSVに出力を行う
				if (pay.PaymentInfoRef__r.ChildRenRsCount__c == 1) {
					if (!despoistOnepayDetailMap.containsKey(accId))  despoistOnepayDetailMap.put(accId, new List<PaymentDetail__c>());
					despoistOnepayDetailMap.get(accId).add(pay);
					continue;
				} 
				// チェックイン日以後の予約金を使う[一回目のみ、出力を行う、その以外は普通なリスト残として、利用する]
				else if(pay.PaymentInfoRef__r.ChildRenRsCount__c == 2) {
					if (!despoistSecpayDetailMap.containsKey(accId))  despoistSecpayDetailMap.put(accId, new List<PaymentDetail__c>());
					despoistSecpayDetailMap.get(accId).add(pay);
				}
			}
			// 返金情報の場合、支払情報を格納する
			else if (pay.PaymentInfoRef__r.PaymentType__c == PAY_TYPE_REFUND) {
				if (!refundDetailMap.containsKey(accId))  refundDetailMap.put(accId, new List<PaymentDetail__c>());
				refundDetailMap.get(accId).add(pay);
				continue;
			}
			if (!payDetailMap.containsKey(accId))  payDetailMap.put(accId, new List<PaymentDetail__c>());
			payDetailMap.get(accId).add(pay);
		}
		// 2018/08/06 税込金額から消費税を計算する BEGIN
		//if (gccInfo.isTaxAutoCalFlg) {
			// プラン明細は税抜きから税込みに変更の際に、差分金額を調整する
			map<id,list<Tran1__c>> planSubMap = new map<id, list<Tran1__c>>();
			for (AccountAcount__c acc : accs){
				// 該当会計明細リストを取得する
				List<Tran1__c> trans = acc.TranAccount__r;
				for (Tran1__c t : trans) {
					// 親の会計明細IDを取得する
					Id parentId = t.ParentTran1Ref__c;
					if (!CommUtils.isBlank(parentId)) {
						if (!planSubMap.containskey(parentId)) planSubMap.put(parentId, new list<Tran1__c>());
						planSubMap.get(parentId).add(t);
					}
				}
			}
			// 親のプラン情報を取得する
			if (!planSubMap.isEmpty()) {
				// 該当親の会計明細の税込金額を取得する
				List<Tran1__c> headerTrans = [select id,Field41__c from Tran1__c where id = :planSubMap.keyset()];
				for (Tran1__c h : headerTrans) {
					list<Tran1__c> subLst = planSubMap.get(h.Id);
					if (subLst == null) continue;
					// 該当プラン明細の税込金額の合計値は親会計明細の税込み金額差分処理を行う
					Decimal sumVal = 0;
					// 最大値
					Decimal maxVal = 0;
					// 最大値の会計明細オブジェクト
					Tran1__c maxTran = null;
					for (Tran1__c sub : subLst) {
						Decimal val = CommUtils.nullToZero(sub.Field41__c);
						if (val > maxVal) {
							maxVal = val;
							maxTran = sub;
						}
						sumVal += val;
					}
					// 最大明細データが存在する場合
					if (maxTran != null) {
						// 合計値と親会計明細の差分が存在する場合
						if (CommUtils.nullToZero(h.Field41__c) <> sumVal) {
							// 差分値は最大明細に反映を行う
							maxTran.Field23__c = CommUtils.nullToBlank(
								CommUtils.nullToZero(maxTran.Field23__c) 
								+ (CommUtils.nullToZero(h.Field41__c) - sumVal));
						}
					}
				}
			}
		//}
		// 2018/08/06 税込金額から消費税を計算する END
		// 該当店舗の該当売上日の全会計情報のPCA情報を出力する
		for (AccountAcount__c acc : accs){
			// 会計明細がなかったの場合、該当会計はPCA抽出対象外になる
			if (acc.TranAccount__r.isEmpty()) {
				// 予約金、返金のみ場合、続いて出力を行う
				// 以外の場合、出力を行わない
				if (!despoistOnepayDetailMap.containsKey(acc.Id) &&
					!refundDetailMap.containsKey(acc.Id)) {
					continue;
				}	
			}
			// 会計単位のPCA情報を取得する
			/*
			// 1会計の関連情報を出力する
			//String oneAccCsv = '';
			// 摘要情報「部屋NOと宿泊者名」
			String simpleCommnt = CONST_CSVDATA_COMMENT_TEMPLATE
										.Replace('$$_ROOMNO_$$'		, CommUtils.nullToBlank(acc.RoomName__c))
										.Replace('$$_GUESTNAME_$$'	, CommUtils.nullToBlank(acc.ContactName__c));
			String SingAccCsvTemplate = CsvTemplate
										.Replace('$$_摘要_$$'		, simpleCommnt)
										.Replace('$$_伝票番号_$$'		, String.valueOf(startNo));
			// 次の会計番号を計算する
			startNo++;
			*/
			// 会計単位の支払情報取得する
			// 該当会計の関連の支払明細情報存在チェック
			// 該当会計関連の支払明細情報をそのまま取得して、CSV作成を行う
			// 注意：予約インデックスがないの会計の場合、支払情報をそのまま使って、PCA情報に出力する
			// 簡易会計の支払情報の処理
			if (acc.Relreserve__c == null) {
				// 会計明細情報取得する
				List<Tran1__c> trans = acc.TranAccount__r;
				// 会計支払情報取得する
				List<TTend__c> ttends = acc.TranTotalfromPay__r;
				// 支払情報をそのまま出力する
				csvBody += genOldOneAccAcountCsv(acc, ttends, trans,
										//SingAccCsvTemplate,
										getSingAccCsvTemplate(acc, startNo, CsvTemplate, false),
										pMediaPayProdMap,
										pKanjoKamokuMstMap,
										pCcInfo,
										startNo);
				// 次の会計番号を計算する
				startNo++;
				continue;
			} else {
				
				// 予約金のみ情報が存在の場合、
				if( despoistOnepayDetailMap.containsKey(acc.Id)) {
					//List<PaymentDetail__c> despoistFirstLst =
					for (PaymentDetail__c ttendPay : despoistOnepayDetailMap.get(acc.Id)) {
						// 貸方会計科目コード:元の支払の会計科目
						csvBody += generalDepoistCsv(acc, ttendPay, CsvTemplate, startNo, pKanjoKamokuMstMap.get(pCcInfo.advpayLKanjoCode), true, pKanjoKamokuMstMap.get(pCcInfo.advpayLKanjoCode));
						// 次の会計番号を計算する
						startNo++;
					}
					// 該当会計処理は完了
					continue;
				}
				// 返金の行が存在する場合
				if (refundDetailMap.containsKey(acc.Id)) {
					//List<PaymentDetail__c> despoistFirstLst =
					for (PaymentDetail__c ttendPay : refundDetailMap.get(acc.Id)) {
						// 貸方会計科目コード:元の支払の会計科目
						csvBody += generalRefundCsv(acc, ttendPay, CsvTemplate, startNo, pKanjoKamokuMstMap.get(pCcInfo.advpayLKanjoCode),pKanjoKamokuMstMap.get(pCcInfo.refundRkanjoCode));
						// 次の会計番号を計算する
						startNo++;
					}
					// 該当会計に普通の支払情報がなかった場合、消費税出力なし
					if (acc.TranAccount__r.isEmpty()) {
						continue;
					}
				}
				
				// 予約金に対して、個別な処理が必要[会計明細の出力前に、１行目の予約金情報を出力する]
				if (despoistSecpayDetailMap.containsKey(acc.Id)) {
					//List<PaymentDetail__c> despoistFirstLst =
					for (PaymentDetail__c ttendPay : despoistSecpayDetailMap.get(acc.Id)) {
						// 貸方会計科目コード:元の支払の会計科目
						csvBody += generalDepoistCsv(acc, ttendPay, CsvTemplate, startNo, pKanjoKamokuMstMap.get(pCcInfo.advpayLKanjoCode), false, pKanjoKamokuMstMap.get(pCcInfo.advpayLKanjoCode));
						// 次の会計番号を計算する
						startNo++;
					}
				}
				// 会計所属する支払情報存在チェック
				// 残金が存在する場合
				// 支払明細から支払情報を取得する
				List<PaymentDetail__c> ttends = payDetailMap.get(acc.Id);
				// 会計支払情報取得、PCAのCSVファイルを作成する
				if (ttends == null) ttends = new List<PaymentDetail__c>();
				// 会計明細情報取得する
				List<Tran1__c> trans = acc.TranAccount__r;
				// 該当会計関連のCSV情報
				String oneAccCsv = '';
// 2019/09/20 多税率機能対応 WSQ BEGIN
				//Integer taxOuputLineNum = tranSize;	// 消費税出力行目[会計明細の次の行目から出力する]
				//Decimal amountIncTax = 0;	// 税込み合計金額
				//Decimal amountNoTax  = 0;	// 税抜き合計金額
				// 消費税列の情報は最後に新規行目追加を行う標識フラグ
				Boolean isAddTaxInNewLine = true;
				// map<税率，該当税率の合計金額>
				map<decimal,decimal> amountIncTaxMap = new map<decimal,decimal>(); 	// 税込み合計金額
				// map<税率，該当税率の合計金額>
				map<decimal,decimal> amountNoTaxMap = new map<decimal,decimal>(); 	// 税抜き合計金額
				Integer ttendOutSize = 0;            // 会計支払明細の最大行数
				Integer trandOutSize = 0;            // 会計明細の最大行数
// 2019/09/20 多税率機能対応 WSQ END
				// 該当会計の消費税行表記済フラグ
				Integer tranIsEmptyLineNo = 0;
				String SingAccCsvTemplate = getSingAccCsvTemplate(acc, startNo, CsvTemplate, false);
				// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
				String simpleComment = getSimpleComment(acc, startNo, CsvTemplate, false);
				// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
//2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする BEGIN
Integer leftAmount = 0, rightAmount = 0;
//2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする END
				// 支払情報と会計明細両方共出力完了の場合、該当会計のCSV出力完了
				while (true) {	
					Ttend__c ttend = null;
					Tran1__c ttran = null;	// 前受付金の残金の場合、自動作成の支払情報格納用変数[会計明細]
					
					// 支払情報を取得する
					PaymentDetail__c ttendPay = null;
					if (ttends.isEmpty()) ttendPay = new PaymentDetail__c();
					else ttendPay = ttends[0];
					
					// 会計支払明細情報が存在する場合
					if (ttendPay.Id != null) {
// 2020/11/02 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う） WSQ BEGIN
if(gccInfo.isUseDayOutMode){
	// 支払種別を取得する
	String payType = CommUtils.nullToBlank(ttendPay.PaymentInfoRef__r.PaymentType__c);
	Boolean isVarFlg = ttendPay.PaymentInfoRef__r.ImgDataFlg__c;
	ttend = ttendPay.PaymentInfoRef__r.TTendRef__r;
	if (ttend == null) ttend = new Ttend__c();
	ttend.Field19__c = String.valueof(ttendPay.DepositAmount__c);	// 預かり金額
	ttend.Field20__c = String.valueof(ttendPay.UsedAmount__c);		// 利用金額
	ttend.Field21__c = String.valueof(ttendPay.RemainingMoney__c);	// 釣銭（差額）金額
	if (isVarFlg) {
		KanjoKamoku__c kankoMst = null;
		// 2020/09/15 連泊の支払を入れた際の挙動修正2 WSQ BEGIN
		Boolean isUseDayOutMode2 = (ttendPay.PaymentInfoRef__r.OffsetMoney__c != null && ttendPay.PaymentInfoRef__r.OffsetMoney__c > 0);
		if (isUseDayOutMode2) {
				kankoMst = pKanjoKamokuMstMap.get(pCcInfo.acKanjoSeqNo);
				// Tranデータ自動作成
				// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 END
				AccountMaster__c virAccMst = new AccountMaster__c(
					KanjoKamokuRef__r = kankoMst
				);
				ttran = new Tran1__c(
					 Field23__c = String.valueOf(ttendPay.DepositAmount__c)	//GoukeinoneTax__c（$合計金額（税抜））は数式ので、Field23__c項目で残金情報を格納する
					,Field7__r = virAccMst
				);
				
				ttend = new Ttend__c();
		} else {
		// 2020/09/15 連泊の支払を入れた際の挙動修正2 WSQ END
		// 前受金の場合、借方の勘定科目を変換する
		if (payType == PAY_TYPE_APAY) {
			kankoMst = pKanjoKamokuMstMap.get(pCcInfo.apLeftKanjoSeqNo);
		} else if (payType == PAY_TYPE_URKK) {
			kankoMst = pKanjoKamokuMstMap.get(pCcInfo.dpLeftKanjoSeqNo);
			if (ttend.PayProductRef__c == null) ttend.Field2__c = CommConst.MEDIA_TYPE_CD_03;
		}
		if (kankoMst == null) kankoMst = new KanjoKamoku__c();
		if (ttend.PayProductRef__c == null) ttend.PayProductRef__r = new AccountMaster__c();
		AccountMaster__c cloneAccMst = ttend.PayProductRef__r;
		ttend.PayProductRef__r = cloneAccMst.clone(false,true);
		ttend.PayProductRef__r.KanjoKamokuRef__r = kankoMst.clone(false,true);
		// 2020/09/15 連泊の支払を入れた際の挙動修正2 WSQ BEGIN
		}
		// 2020/09/15 連泊の支払を入れた際の挙動修正2 WSQ END
	} 
	if (ttend.id == null) ttends.remove(0);
} else {
// 2020/11/02 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う） WSQ END
						// 処理済の場合、配列は外すので、常に残りの列から第一目の支払情報を取得する
						// 前受付金以外の支払情報の場合
						if (ttendPay.PaymentInfoRef__r.TTendRef__c != null) {
							// 会計支払から支払情報を取得、該当支払関連の会計科目情報を取得する
							ttend = ttendPay.PaymentInfoRef__r.TTendRef__r;
							// 支払金額は支払情報から取得、設定する
							ttend.Field19__c = String.valueof(ttendPay.DepositAmount__c);	// 預かり金額
							ttend.Field20__c = String.valueof(ttendPay.UsedAmount__c);		// 利用金額
							ttend.Field21__c = String.valueof(ttendPay.RemainingMoney__c);	// 利用金額
							// 予約金の場合、小明細件数２からチェック
							Integer checkChildRsCountMin = 1;
							if (ttendPay.PaymentInfoRef__r.PaymentType__c == PAY_TYPE_DESPOIST) checkChildRsCountMin = 2;
							// 翌日の前受付金の場合、左側の前受付金の会計科目情報を取得、設定する
							if (ttendPay.PaymentInfoRef__r.ChildRenRsCount__c > checkChildRsCountMin) {
								KanjoKamoku__c kankoMst = pKanjoKamokuMstMap.get(pCcInfo.advpayLKanjoCode);
								if (kankoMst == null) kankoMst = new KanjoKamoku__c();
								if (ttend.PayProductRef__c == null) ttend.PayProductRef__r = new AccountMaster__c();
								AccountMaster__c cloneAccMst = ttend.PayProductRef__r;
								ttend.PayProductRef__r = cloneAccMst.clone(false,true);
								ttend.PayProductRef__r.KanjoKamokuRef__r = kankoMst.clone(false,true);
							}
						} 
						// 前受付金の支払情報の場合
						else if (ttendPay.PaymentInfoRef__r.Tran1Ref__c != null) {
							// 前受付金会計明細から会計支払の書式に転換を行う
							ttend = new TTend__c(
								 // 支払商品設定を行う
								 PayProductRef__c = ttendPay.PaymentInfoRef__r.Tran1Ref__r.Field7__c
								,PayProductRef__r = ttendPay.PaymentInfoRef__r.Tran1Ref__r.Field7__r.clone(false,true)
								 // メデイア種別コード:前受付金識別用（範囲外のコード：-99）設定を行う
								//,Field2__c = PAYMENT_MEDIA_TYPE_AR
								,Field19__c = String.valueof(ttendPay.DepositAmount__c)		// 預かり金額
								,Field20__c = String.valueof(ttendPay.UsedAmount__c)		// 利用金額
								,Field21__c = String.valueof(ttendPay.RemainingMoney__c)
							);
							// 予約金の場合、小明細件数２からチェック
							Integer checkChildRsCountMin = 1;
							if (ttendPay.PaymentInfoRef__r.PaymentType__c == PAY_TYPE_DESPOIST) checkChildRsCountMin = 2;
							
							// 翌日の前受付金の場合、左側の前受付金の会計科目情報を取得、設定する
							if (ttendPay.PaymentInfoRef__r.ChildRenRsCount__c > checkChildRsCountMin) {
								KanjoKamoku__c kankoMst = pKanjoKamokuMstMap.get(pCcInfo.advpayLKanjoCode);
								if (kankoMst == null) kankoMst = new KanjoKamoku__c();
								if (ttend.PayProductRef__r == null) ttend.PayProductRef__r = new AccountMaster__c();
								AccountMaster__c cloneAccMst = ttend.PayProductRef__r;
								ttend.PayProductRef__r = cloneAccMst.clone(false,true);
								ttend.PayProductRef__r.KanjoKamokuRef__r = kankoMst.clone(false,true);
							}
							// 前受付金から自動作成の支払情報は処理対象配列から外す !!!
							ttends.remove(0);
						}
// 2020/11/02 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う） WSQ BEGIN
}
// 2020/11/02 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う） WSQ END				
						// 注意：支払メデイアは売掛金の場合、補助科目に、会計関連の取引先のID__C項目のコード取得して、設定する
						// 関連の商品情報が存在する場合、関連の支払情報の会計科目設定情報により、CSVへ出力する
						// 支払情報に対して、関連の支払商品がなかったの場合、XML設定情報により、関連の会計商品情報を取得する
						// 2020/11/02 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う） WSQ BEGIN
						//if (ttend.PayProductRef__c == null) {
						if(ttend.PayProductRef__c == null && !gccInfo.isUseDayOutMode){
						// 2020/11/02 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う） WSQ END
							// カード種別と金券種別の設定情報により、会計科目情報を設定する
							// カード種別　OR　金券種別で会計科目情報を取得する場合、支払メデイアの関連会計科目は非設定する
							// カード種別　OR　金券種別で会計科目情報を取得する場合、支払メデイアの関連会計科目は非設定する
							AccountMaster__c accMst = new AccountMaster__c();
							// カード種別の場合
							if (ttend.Field2__c == CommConst.MEDIA_TYPE_CD_02 && !CommUtils.isBlank(ttend.CardTypeLst__c)) {
								String seqNo = pCcInfo.mediaCardMap.get(ttend.CardTypeLst__c);
								if (!CommUtils.isBlank(seqNo) && pKanjoKamokuMstMap.containsKey(seqNo)) accMst.KanjoKamokuRef__r = pKanjoKamokuMstMap.get(seqNo);
							}
							// クポーン　OR　割引の場合
							else if ((ttend.Field2__c == CommConst.MEDIA_TYPE_CD_11 ||
									  ttend.Field2__c == CommConst.MEDIA_TYPE_CD_12) && !CommUtils.isBlank(ttend.CouponTypeLst__c)) {
								String seqNo = pCcInfo.mediaKinkenMap.get(ttend.CouponTypeLst__c);
								if (!CommUtils.isBlank(seqNo) && pKanjoKamokuMstMap.containsKey(seqNo)) accMst.KanjoKamokuRef__r = pKanjoKamokuMstMap.get(seqNo);
							} 
							if (accMst.KanjoKamokuRef__r == null) {
								if (pMediaPayProdMap.containsKey(ttend.Field3__c)) accMst = pMediaPayProdMap.get(ttend.Field3__c);
							}
							/*
							// 支払Mediaラベルから関連の会計商品を取得する
							AccountMaster__c accMst = pMediaPayProdMap.get(ttend.Field3__c);
							if (accMst == null) accMst = new AccountMaster__c();
							*/
							ttend.PayProductRef__r = accMst.clone(false,true);
						} 
						// 支払情報の関連の会計商品情報「借方」
						AccountMaster__c ttendAccMst = ttend.PayProductRef__r;
						// 支払メデイア種別は売掛金の場合、取引先からコード設定を行う
						//String kanjoHojocode = CommUtils.nullToBlank(ttendAccMst.KanjoKamokuRef__r.KanjoHojocode__c);
						if (ttend.Field2__c == CommConst.MEDIA_TYPE_CD_03 && ttendAccMst.KanjoKamokuRef__r != null) {
							// 掛計の場合、カード種別、金券種別項目を設定されている場合、該当カード種別と金券種別経由で会計科目情報を取得する
							// 該当関連の会計科目情報はなかった場合、取引先のID情報で補助科目情報を設定する
							/* 2015/03/12 掛計の処理ロジック変更を行う
							Boolean isAutoSetupFlg = false;
							if (!CommUtils.isBlank(ttend.CardTypeLst__c)) {
								String seqNo = pCcInfo.mediaCardMap.get(ttend.CardTypeLst__c);
								if (!CommUtils.isBlank(seqNo) && pKanjoKamokuMstMap.containsKey(seqNo)) {
									ttendAccMst.KanjoKamokuRef__r.KanjoHojocode__c = pKanjoKamokuMstMap.get(seqNo).KanjoHojocode__c;	
									isAutoSetupFlg = true;
								}
							} else if (!CommUtils.isBlank(ttend.CouponTypeLst__c)){
								String seqNo = pCcInfo.mediaKinkenMap.get(ttend.CouponTypeLst__c);
								if (!CommUtils.isBlank(seqNo) && pKanjoKamokuMstMap.containsKey(seqNo)) {
									ttendAccMst.KanjoKamokuRef__r.KanjoHojocode__c = pKanjoKamokuMstMap.get(seqNo).KanjoHojocode__c;
									isAutoSetupFlg = true;
								}
							}
							//　カード種別、金券種別項目設定なかった場合、取引先のID項目で補助科目情報を設定する
							if (!isAutoSetupFlg) {
								ttendAccMst.KanjoKamokuRef__r.KanjoHojocode__c = CommUtils.nullToBlank(acc.relaccount__r.Account.ID__c);
							}*/
							// 現在の会計科目は前受金「リスト残」の場合、下記処理を行わない
							KanjoKamoku__c kankoMst = pKanjoKamokuMstMap.get(pCcInfo.advpayLKanjoCode);
							if (kankoMst != null && ttendAccMst.KanjoKamokuRef__r.Kanjocode__c != kankoMst.Kanjocode__c) {
								// 請求先の企業コードが存在する場合、該当企業コードを補助科目コードに設定する
								if (!CommUtils.isBlank(acc.relaccount__r.Account.ID__c)) {
									ttendAccMst.KanjoKamokuRef__r.KanjoHojocode__c = CommUtils.nullToBlank(acc.relaccount__r.Account.ID__c);
								}
							}
						}
						/*
						// 関連商品から左側の情報を会計科目情報を設定する
						// 支払メデイア種別は売掛金の場合、取引先からコード設定を行う
						String kanjoHojocode = CommUtils.nullToBlank(accMst.KanjoKamokuRef__r.KanjoHojocode__c);
						if (ttend.Field2__c == CommConst.MEDIA_TYPE_CD_03) {
							kanjoHojocode = CommUtils.nullToBlank(acc.relaccount__r.Account.ID__c);
						} 
						// 前受付金の支払情報の場合
						else */
						
						// 右側の利用明細の処理
						// 左側の支払情報は前受付金の場合
						// 該当支払明細利用金額の残金は残り場合
//if (ttend.Field2__c == PAYMENT_MEDIA_TYPE_AR) {
							// 始めて前受付金は利用日の場合、左は商品そのまま使う、右側は残金あり、なしにより、
							// 残金ありの場合、右側XML設定の設定会計科目により、情報表示
							// 残金なしの場合、普通の会計明細商品情報を表示する
							// 翌日から前受付金の場合、左側はXMLの設定情報により、会計情報を表示、右側は残金あり、なしにより、
							// 残金ありの場合、右側XML設定の設定会計科目により、情報表示
							// 残金なしの場合、普通の会計明細商品情報を表示する
							// 初日するがどうかチェックを行う【明細件数は１件の場合、初日利用】
							// 利用金額は残金ありの場合、貸方に前受付（リストに残）情報を自動出力を行う
							if (ttendPay.RemainingMoney__c > 0) {
								// 右側に貸方情報を自動追加する(XML定義情報により)
								// 右の会計科目情報を取得する[XML定義する会計科目のSEQ＃により、会計科目マスタ情報を取得する]
								KanjoKamoku__c kankoMst = pKanjoKamokuMstMap.get(pCcInfo.advpayRKanjoCode);
								// 2020/11/02 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う） WSQ BEGIN
								if (pCcInfo.isUseDayOutMode) {
									// 架空データの場合、売掛金で出力、実際データの場合、前受金を出力する
									kankoMst = pKanjoKamokuMstMap.get(pCcInfo.apRightKanjoSeqNo);
								}
								// 2020/11/02 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う） WSQ END
								if (kankoMst == null) kankoMst = new KanjoKamoku__c();
								AccountMaster__c virAccMst = new AccountMaster__c(
									KanjoKamokuRef__r = kankoMst
								);
								ttran = new Tran1__c(
									 Field23__c = String.valueOf(ttendPay.RemainingMoney__c)	//GoukeinoneTax__c（$合計金額（税抜））は数式ので、Field23__c項目で残金情報を格納する
									,Field7__r = virAccMst
								);
							} // if (ttendPay.RemainingMoney__c > 0)
//						} // if (ttend.Field2__c == PAYMENT_MEDIA_TYPE_AR)
						// 2019/09/20 多税率機能対応 WSQ BEGIN
						ttendOutSize++;
						// 2019/09/20 多税率機能対応 WSQ END
					} // if (ttendPay.Id != null)
					else {
						ttend = new Ttend__c();
					}
					
					// 2019/09/20 多税率機能対応 WSQ BEGIN
					Boolean transIsEmpty = false;   // 会計明細全部出力済みフラグ：TRUE：出力済み
					// 2019/09/20 多税率機能対応 WSQ END
					// 利用明細
					if (ttran == null) {
						if (trans.isEmpty()) ttran = new Tran1__c();
						else ttran = trans[0];
						// 2019/09/20 多税率機能対応 WSQ BEGIN
						//if (trans.isEmpty()) tranIsEmptyLineNo++;	// 会計明細は全部出力後、関連の行NOを計算する
						if (trans.isEmpty()) transIsEmpty=true;	// 会計明細は全部出力後、関連の行NOを計算する
						// 2019/09/20 多税率機能対応 WSQ END
					}
					// 該当行目の支払情報を出力する
					
					// CSVの左側の支払情報を作成する
					// １行目のCSV出力情報初期化設定[1会計単位]
					String csvLine = SingAccCsvTemplate;
					// CSV出力を行う【預かり金額】
					Decimal paymentAmount = Commutils.nullToZero(ttend.Field19__c);
					
					csvLine = csvLine
						.Replace('$$_伝票区切_$$'			, getDenhyouDivMark(acc))
						.Replace('$$_借方科目コード_$$'	, CommUtils.nullToBlank(ttend.PayProductRef__r.KanjoKamokuRef__r.KanjocodeCode__c))
						.Replace('$$_借方補助コード_$$'	, CommUtils.nullToBlank(ttend.PayProductRef__r.KanjoKamokuRef__r.KanjoHojocode__c))
						//.Replace('$$_借方税区分_$$'		, CommUtils.nullToBlank(ttend.PayProductRef__r.KanjoKamokuRef__r.DebitTaxKbn__c))
						.Replace('$$_借方金額_$$'			, String.valueOf(paymentAmount.intValue()));
					// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
					if (pCcInfo.isExtraMode) {
						Decimal varTaxRate = formattax(ttend.PayProductRef__r.TaxRateCal__c);
						csvLine = csvLine
							.replace('$$_借方部門コード_$$'	, getDepartCode(CommUtils.nullToBlank(ttend.PayProductRef__r.KanjoKamokuRef__r.DebitDepartCode__c), true))
							.replace('$$_借方税区分_$$'		, CommUtils.nullToBlank(ttend.PayProductRef__r.KanjoKamokuRef__r.DebitTaxKbn__c))
							.replace('$$_借方税率_$$'			, CommUtils.nullToBlank(formatOuputTaxRate(varTaxRate)))
							.replace('$$_借方軽減税率_$$'		, getReducedFlg(varTaxRate))
							.replace('$$_借方摘要_$$'			, simpleComment);
					}
					// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
// 2018/06/12 仕訳Rollup機能追加対応 BEGIN
Decimal locAmount = 0;
// 2018/06/12 仕訳Rollup機能追加対応 END
// 2018/08/06 税込金額から消費税を計算する BEGIN
String taxCalType = TaxCalType0;
// 2018/08/06 税込金額から消費税を計算する END
					// 右側のCSV出力情報を取得する
					// 2019/09/20 多税率機能対応 WSQ BEGIN
					//if (tranIsEmptyLineNo != 1) {	// tranIsEmptyLineNo == 1 の場合、交換文字列処理なし、後で交換を行う
					if (!transIsEmpty) {	// tranIsEmptyLineNo == 1 の場合、交換文字列処理なし、後で交換を行う
						// 右側の出力行数を計算する
						trandOutSize++;
					// 2019/09/20 多税率機能対応 WSQ END	
						csvLine = csvLine
							.Replace('$$_貸方科目コード_$$'	, CommUtils.nullToBlank(ttran.Field7__r.KanjoKamokuRef__r.KanjocodeCode__c))
							.Replace('$$_貸方補助コード_$$'	, CommUtils.nullToBlank(ttran.Field7__r.KanjoKamokuRef__r.KanjoHojocode__c));
							//.Replace('$$_貸方税区分_$$'		, CommUtils.nullToBlank(ttran.Field7__r.KanjoKamokuRef__r.CreditTaxKbn__c));
						// 実際の会計明細の場合
						if (ttran.Id != null) {
							// 2018/08/06 税込金額から消費税を計算する BEGIN
							Decimal rAmount = (gccInfo.isTaxAutoCalFlg ? CommUtils.nullToZero(ttran.Field23__c) : CommUtils.nullToZero(ttran.GoukeinoneTax__c));
							// 2018/08/06 税込金額から消費税を計算する END
						 	csvLine = csvLine
						 	// 2018/08/06 税込金額から消費税を計算する BEGIN
						 		//.Replace('$$_貸方金額_$$'			, String.valueOf(CommUtils.nullToZero(ttran.GoukeinoneTax__c).intValue()));
						 		.Replace('$$_貸方金額_$$'			, String.valueOf(rAmount.intValue()));
						 	// 消費税が０場合、
						 	// 2019/09/20 多税率機能対応 WSQ BEGIN
						 	//Decimal taxRate = CommUtils.nullToZero(ttran.Field7__r.TaxRateCal__c);
						 	decimal taxrate = CommUtils.nullToZero(ttran.TaxRate__c == null ? ttran.Field7__r.TaxRateCal__c : ttran.TaxRate__c); // 消費税率
						 	// 2019/09/20 多税率機能対応 WSQ END
						 	if (taxRate > 0)  {
						 		taxCalType = TaxCalType2;
						 	}
					 		// 2018/08/06 税込金額から消費税を計算する END
						 	// 実際利用金額	
//System.debug(loggingLevel.info, 'CommUtils.nullToZero(ttran.Field23__c)='+CommUtils.nullToZero(ttran.Field23__c));
						 	// 2019/09/20 多税率機能対応 WSQ BEGIN
						 	//amountIncTax += CommUtils.nullToZero(ttran.Field23__c);
						 	//amountNoTax  += CommUtils.nullToZero(ttran.GoukeinoneTax__c);
			 				if (!amountIncTaxMap.containskey(taxrate)) amountIncTaxMap.put(taxrate, CommUtils.nullToZero(ttran.Field23__c));
			 				else amountIncTaxMap.put(taxrate, (amountIncTaxMap.get(taxrate) + CommUtils.nullToZero(ttran.Field23__c)));
			 				if (!amountNoTaxMap.containskey(taxrate)) amountNoTaxMap.put(taxrate, rAmount);
			 				else amountNoTaxMap.put(taxrate, (amountNoTaxMap.get(taxrate) + rAmount));
						 	// 2019/09/20 多税率機能対応 WSQ END
// 2018/06/12 仕訳Rollup機能追加対応 BEGIN
// 2019/09/20 多税率機能対応 WSQ BEGIN
//locAmount = CommUtils.nullToIntZero(ttran.GoukeinoneTax__c);
// 2018/08/06 税込金額から消費税を計算する BEGIN
//if (gccInfo.isTaxAutoCalFlg) locAmount = CommUtils.nullToIntZero(ttran.Field23__c);
locAmount = rAmount;
// 2018/08/06 税込金額から消費税を計算する END
// 2018/06/12 仕訳Rollup機能追加対応 END
// 2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする BEGIN
//rightAmount += CommUtils.nullToIntZero(ttran.GoukeinoneTax__c);
rightAmount += CommUtils.nullToIntZero(rAmount);
// 2019/09/20 多税率機能対応 WSQ END
// 2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする END
							// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
							if (pCcInfo.isExtraMode) {
								csvLine = csvLine
									.replace('$$_貸方部門コード_$$'	, getDepartCode(CommUtils.nullToBlank(ttran.Field7__r.KanjoKamokuRef__r.CreditDepartCode__c), false))
									.replace('$$_貸方税区分_$$' 		, CommUtils.nullToBlank(ttran.Field7__r.KanjoKamokuRef__r.CreditTaxKbn__c))
									.replace('$$_貸方税率_$$'			, CommUtils.nullToBlank(formatOuputTaxRate(taxrate)))
									.replace('$$_貸方軽減税率_$$'		, getReducedFlg(taxrate))
									.replace('$$_貸方摘要_$$'			, simpleComment);
							}
							// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
						} 
						// 表示ため仮作成の会計明細
						else {
						 	csvLine = csvLine
						 		.Replace('$$_貸方金額_$$'			, String.valueOf(CommUtils.nullToZero(ttran.Field23__c).intValue()));
							// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
							if (pCcInfo.isExtraMode) {
								csvLine = csvLine
									.replace('$$_貸方部門コード_$$'	, getDepartCode(CommUtils.nullToBlank(ttran.Field7__r.KanjoKamokuRef__r.CreditDepartCode__c), false))
									.replace('$$_貸方税区分_$$' 		, CommUtils.nullToBlank(ttran.Field7__r.KanjoKamokuRef__r.CreditTaxKbn__c))
									.replace('$$_貸方税率_$$'			, '')
									.replace('$$_貸方軽減税率_$$'		, '')
									.replace('$$_貸方摘要_$$'			, simpleComment);
							}
							// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
// 2018/06/12 仕訳Rollup機能追加対応 BEGIN
locAmount = CommUtils.nullToIntZero(ttran.Field23__c);
// 2018/06/12 仕訳Rollup機能追加対応 END
// 2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする BEGIN
rightAmount += CommUtils.nullToIntZero(ttran.Field23__c);
// 2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする END
						}
// 2019/09/20 多税率機能対応 WSQ BEGIN						
//					} else {
//						// 該当行目に消費税情報を出力する
//						isAddTaxInNewLine = false;
// 2019/09/20 多税率機能対応 WSQ END
					}
					// 2018/08/06 税込金額から消費税を計算する BEGIN
					csvLine = getTaxCalInfo(csvLine,taxCalType);
					// 2018/08/06 税込金額から消費税を計算する END
// 2018/06/12 仕訳Rollup機能追加対応 BEGIN
// 2020/11/02 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う） WSQ BEGIN
//if (!ttends.isEmpty())
// 2020/11/02 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う） WSQ END
setupRollupInfo(acc.frs__r.Name,
				// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) BEGIN
				//CommUtils.nullToBlank(ttend.PayProductRef__r.KanjoKamokuRef__r.KanjocodeCode__c),
				ttend.PayProductRef__r.KanjoKamokuRef__r,
				// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) END
				String.valueOf(paymentAmount.intValue()),
				ROLLUP_TYPE.SALES_L);
// 2020/11/02 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う） WSQ BEGIN
//if (!trans.isEmpty())
// 2020/11/02 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う） WSQ END
setupRollupInfo(acc.frs__r.Name,
				// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) BEGIN
				//CommUtils.nullToBlank(ttran.Field7__r.KanjoKamokuRef__r.KanjocodeCode__c),
				ttran.Field7__r.KanjoKamokuRef__r,
				// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) END
				String.valueOf(locAmount.intValue()),
// 2018/08/06 税込金額から消費税を計算する BEGIN
				//ROLLUP_TYPE.SALES_R);
				ROLLUP_TYPE.SALES_R,taxCalType);
// 2018/08/06 税込金額から消費税を計算する END
// 2018/06/12 仕訳Rollup機能追加対応 END	

					if (ttend.Id != null) ttends.remove(0);
					if (ttran.Id != null) trans.remove(0);
// 2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする BEGIN
leftAmount += CommUtils.nullToIntZero(paymentAmount);
// 2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする END
					oneAccCsv += csvLine;
					// 該当会計関連のPCAのCSV情報を全部出力済
					if (ttends.isEmpty() && trans.isEmpty()) break;
//if (i > 40) break;
				} // End while (true) [1会計のPCA連携CSV内容出力済]
// 2019/09/20 多税率機能対応 WSQ BEGIN
//system.debug(LoggingLevel.info, 'oneAccCsv='+oneAccCsv);
list<decimal> taxratelst = new list<decimal>();
for (decimal key : amountIncTaxMap.keyset()) {taxratelst.add(formattax(key));}
taxratelst.sort();//並び順設定
for (decimal taxrate : taxratelst) {
	decimal amountIncTax = amountIncTaxMap.get(taxrate);//税込み金額
	decimal amountNoTax = amountNoTaxMap.get(taxrate);//税抜金額
	if (pCcInfo.taxKanjoMap.containsKey(taxrate)) pCcInfo.taxKanjoCode = pCcInfo.taxKanjoMap.get(taxrate);
// 2019/09/20 多税率機能対応 WSQ END	
				// 消費税情報はCSVへ反映する
				KanjoKamoku__c wkKankoMst = pKanjoKamokuMstMap.get(pCcInfo.taxKanjoCode);
				if (wkKankoMst == null) wkKankoMst = new KanjoKamoku__c();
				KanjoKamoku__c kankoMst = wkKankoMst.clone(false,true);
				Decimal taxPayAmount = amountIncTax - amountNoTax;
//System.debug(loggingLevel.info, 'amountIncTax='+amountIncTax);
//System.debug(loggingLevel.info, 'amountNoTax='+amountNoTax);
//System.debug(loggingLevel.info, 'taxPayAmount='+taxPayAmount);
				
// 2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする BEGIN
rightAmount += CommUtils.nullToIntZero(taxPayAmount);
// 2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする END
// 2019/09/20 多税率機能対応 WSQ BEGIN
				if (taxPayAmount > 0) {
					if (ttendOutSize > trandOutSize) {
						// 既存の情報から入り替えする
						// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
						if (pCcInfo.isExtraMode) oneAccCsv = replaceRightComment(oneAccCsv, simpleComment);
						// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
						oneAccCsv = getTaxCsvLine(oneAccCsv, taxPayAmount, kankoMst,false,true);
					} else {
						// 新行目に消費税情報を作成する
						// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
						if (pCcInfo.isExtraMode) SingAccCsvTemplate = replaceRightComment(SingAccCsvTemplate,simpleComment);
						// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
						oneAccCsv += getTaxCsvLine(SingAccCsvTemplate, taxPayAmount, kankoMst,true,true);
					}
					// 右側出力行目は１行増える
					trandOutSize++;
				}
}//for (decimal taxrate : taxratelst) {
		// 残り部分は全部クリアを行う
		KanjoKamoku__c clearKankoMst = new KanjoKamoku__c();
		oneAccCsv = getTaxCsvLine(oneAccCsv, 0, clearKankoMst, false);
		// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
		//if (pCcInfo.isExtraMode) oneAccCsv = replaceRightComment(oneAccCsv,'');
		// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
		// 該当会計のCSV情報をマージする
		csvBody += oneAccCsv;
// 2019/09/20 多税率機能対応 WSQ END
// 2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする BEGIN			
if (leftAmount != rightAmount) {
	//伝票番号
	//が同じ仕訳の借方金額と貸方金額が一致しません。
	msgStr += Label.CONST_046_0031 +'【'+startNo+'】'+ Label.CONST_046_0032 +'\n';
}
// 2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする END
			}

			// 次の会計番号を計算する
			startNo++;
		}
		return csvBody;
	}

	/**
	* 返金情報出力する
	**/
	private String generalRefundCsv(AccountAcount__c acc , PaymentDetail__c ttendPay, String CsvTemplate ,Integer startNo, KanjoKamoku__c kankoMstL, KanjoKamoku__c kankoMstR) {
		// 2015/07/09 返金の右側の会計科目は商品から紐付くから固定の前受金「事前入金」に変更を行う
		//　返金の会計商品の会計科目情報を取得する
		if (kankoMstR == null) {
			kankoMstR = ttendPay.PaymentInfoRef__r.Tran1Ref__r.Field7__r.KanjoKamokuRef__r;
		}
		if (kankoMstR == null) kankoMstR = new KanjoKamoku__c();
		// 2018/06/12 仕訳Rollup機能追加対応 BEGIN
		if (kankoMstL == null) kankoMstL = new KanjoKamoku__c();
		// 2018/06/12 仕訳Rollup機能追加対応 END
		// 返金の左会計科目は　前受金「リスト残」で出力する
		String csv = '';
		String SingAccCsvTemplate = getSingAccCsvTemplate(acc, startNo, CsvTemplate, false);
		String paymentAmount = String.valueOf(math.abs(CommUtils.nullToIntZero(ttendPay.DepositAmount__c)));
		
		csv = SingAccCsvTemplate
				.Replace('$$_伝票区切_$$'			,getDenhyouDivMark(acc))
				.Replace('$$_借方科目コード_$$'	,CommUtils.nullToBlank(kankoMstL.KanjocodeCode__c))
				.Replace('$$_借方補助コード_$$'	,CommUtils.nullToBlank(kankoMstL.KanjoHojocode__c))
				//.Replace('$$_借方税区分_$$'		,CommUtils.nullToBlank(kankoMstL.CreditTaxKbn__c))
				.Replace('$$_借方金額_$$'			,paymentAmount)
				// 消費税情報を設定する
				.Replace('$$_貸方科目コード_$$'	,CommUtils.nullToBlank(kankoMstR.KanjocodeCode__c))
				.Replace('$$_貸方補助コード_$$'	,CommUtils.nullToBlank(kankoMstR.KanjoHojocode__c))
				//.Replace('$$_貸方税区分_$$'		,CommUtils.nullToBlank(kankoMstR.CreditTaxKbn__c))
				.Replace('$$_貸方金額_$$'			,paymentAmount);	
		// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
		if (gccInfo.isExtraMode) {
			String simpleComment = getSimpleComment(acc, startNo, SingAccCsvTemplate, false);
			csv = csv
					.replace('$$_借方部門コード_$$'	, getDepartCode(CommUtils.nullToBlank(kankoMstL.DebitDepartCode__c), true))
					.replace('$$_借方税区分_$$'		, CommUtils.nullToBlank(kankoMstL.DebitTaxKbn__c))
					.replace('$$_借方税率_$$'			, '')
					.replace('$$_借方軽減税率_$$'		, '')
					.replace('$$_借方摘要_$$'			, simpleComment)
					.replace('$$_貸方部門コード_$$'	, getDepartCode(CommUtils.nullToBlank(kankoMstR.CreditDepartCode__c), false))
					.replace('$$_貸方税区分_$$' 		, CommUtils.nullToBlank(kankoMstR.CreditTaxKbn__c))
					.replace('$$_貸方税率_$$'			, '')
					.replace('$$_貸方軽減税率_$$'		, '')
					.replace('$$_貸方摘要_$$'			, simpleComment)
					;
		}
		// 2018/08/06 税込金額から消費税を計算する BEGIN
		csv = getTaxCalInfo(csv, TaxCalType0);
		// 2018/08/06 税込金額から消費税を計算する END
			// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
// 2018/06/12 仕訳Rollup機能追加対応 BEGIN	
setupRollupInfo(acc.frs__r.Name,
				// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) BEGIN
				//CommUtils.nullToBlank(kankoMstL.KanjocodeCode__c),
				kankoMstL,
				// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) END
				paymentAmount,
				ROLLUP_TYPE.SALES_L);
								
setupRollupInfo(acc.frs__r.Name,
				// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) BEGIN
				//CommUtils.nullToBlank(kankoMstR.KanjocodeCode__c),
				kankoMstR,
				// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) END
				paymentAmount,
				ROLLUP_TYPE.SALES_R);
// 2018/06/12 仕訳Rollup機能追加対応 END	
		return csv;
	}
	/**
	* 一行目の会計情報を出力する(予約金)
	* acc:出力対象会計情報
	* ttendPay: 会計明細単位の支払明細情報
	* CsvTemplate: CSV出力情報
	* startNo:出力NO
	* kankoMstL:左側の会計科目情報
	* isFirst:入力日の場合、予約金のみ、出力を行う
	* リスト残の会計科目コード
	**/
	private String generalDepoistCsv(AccountAcount__c acc , PaymentDetail__c ttendPay, String CsvTemplate ,Integer startNo, KanjoKamoku__c kankoMstL, Boolean isFirst, KanjoKamoku__c kankoMstAr) {

		if (kankoMstL == null) kankoMstL = new KanjoKamoku__c();
		// 貸方会計科目コード:
		//.PayProductRef__r.KanjoKamokuRef__r.KanjocodeCode__c
		Ttend__c ttend = ttendPay.PaymentInfoRef__r.TTendRef__r;
		Tran1__c tran1 = ttendPay.PaymentInfoRef__r.Tran1Ref__r;
		KanjoKamoku__c kankoMstR = ( ttend != null ? ttend.PayProductRef__r.KanjoKamokuRef__r : tran1.Field7__r.KanjoKamokuRef__r);
		if (kankoMstR == null) kankoMstR = new KanjoKamoku__c();

		String SingAccCsvTemplate = getSingAccCsvTemplate(acc, startNo, CsvTemplate, true);
		
		String paymentAmount = String.valueOf(CommUtils.nullToIntZero(ttendPay.DepositAmount__c));
		// 支払情報は売掛金の場合
		if ( ttend != null && ttend.Field2__c == CommConst.MEDIA_TYPE_CD_03 ) {
			// 現在の会計科目は前受金「リスト残」の場合、下記処理を行わない
			if (kankoMstL.Kanjocode__c != kankoMstAr.Kanjocode__c) {
				// 請求先の企業コードが存在する場合、該当企業コードを補助科目コードに設定する
				if (!CommUtils.isBlank(acc.relaccount__r.Account.ID__c)) {
					kankoMstL.KanjoHojocode__c = CommUtils.nullToBlank(acc.relaccount__r.Account.ID__c);
				}
			}
			if (kankoMstR.Kanjocode__c != kankoMstAr.Kanjocode__c) {
				// 請求先の企業コードが存在する場合、該当企業コードを補助科目コードに設定する
				if (!CommUtils.isBlank(acc.relaccount__r.Account.ID__c)) {
					kankoMstR.KanjoHojocode__c = CommUtils.nullToBlank(acc.relaccount__r.Account.ID__c);
				}
			}
		}
							
		String csv = '';
		if (isFirst) {
		// CSV出力内容を整合する
			csv = SingAccCsvTemplate
					.Replace('$$_伝票区切_$$'			,getDenhyouDivMark(acc))
					.Replace('$$_借方科目コード_$$'	,CommUtils.nullToBlank(kankoMstR.KanjocodeCode__c))
					.Replace('$$_借方補助コード_$$'	,CommUtils.nullToBlank(kankoMstR.KanjoHojocode__c))
					//.Replace('$$_借方税区分_$$'		,CommUtils.nullToBlank(kankoMstR.CreditTaxKbn__c))
					.Replace('$$_借方金額_$$'			,paymentAmount)
					// 消費税情報を設定する
					.Replace('$$_貸方科目コード_$$'	,CommUtils.nullToBlank(kankoMstL.KanjocodeCode__c))
					.Replace('$$_貸方補助コード_$$'	,CommUtils.nullToBlank(kankoMstL.KanjoHojocode__c))
					//.Replace('$$_貸方税区分_$$'		,CommUtils.nullToBlank(kankoMstL.CreditTaxKbn__c))
					.Replace('$$_貸方金額_$$'			,paymentAmount);	
					
			// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
			if (gccInfo.isExtraMode) {
				String simpleComment = getSimpleComment(acc, startNo, SingAccCsvTemplate, false);
				csv = csv
						.replace('$$_借方部門コード_$$'	, getDepartCode(CommUtils.nullToBlank(kankoMstR.DebitDepartCode__c), true))
						.replace('$$_借方税区分_$$'		, CommUtils.nullToBlank(kankoMstR.DebitTaxKbn__c))
						.replace('$$_借方税率_$$'			, '')
						.replace('$$_借方軽減税率_$$'		, '')
						.replace('$$_借方摘要_$$'			, simpleComment)
						.replace('$$_貸方部門コード_$$'	, getDepartCode(CommUtils.nullToBlank(kankoMstL.CreditDepartCode__c), false))
						.replace('$$_貸方税区分_$$' 		, CommUtils.nullToBlank(kankoMstL.CreditTaxKbn__c))
						.replace('$$_貸方税率_$$'			, '')
						.replace('$$_貸方軽減税率_$$'		, '')
						.replace('$$_貸方摘要_$$'			, simpleComment)
						;
			}
			// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
			// 2018/08/06 税込金額から消費税を計算する BEGIN
			csv = getTaxCalInfo(csv, TaxCalType0);
			// 2018/08/06 税込金額から消費税を計算する END
// 2018/06/12 仕訳Rollup機能追加対応 BEGIN	
setupRollupInfo(acc.frs__r.Name,
				// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) BEGIN
				kankoMstR,
				// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) END
				paymentAmount,
				ROLLUP_TYPE.SALES_L);
									
setupRollupInfo(acc.frs__r.Name,
				// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) BEGIN
				//CommUtils.nullToBlank(kankoMstL.KanjocodeCode__c),
				kankoMstL,
				// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) END
				paymentAmount,
				ROLLUP_TYPE.SALES_R);
// 2018/06/12 仕訳Rollup機能追加対応 END	
		} else {
		// CSV出力内容を整合する
			csv = SingAccCsvTemplate
					.Replace('$$_伝票区切_$$'			,getDenhyouDivMark(acc))
					.Replace('$$_借方科目コード_$$'	,CommUtils.nullToBlank(kankoMstL.KanjocodeCode__c))
					.Replace('$$_借方補助コード_$$'	,CommUtils.nullToBlank(kankoMstL.KanjoHojocode__c))
					//.Replace('$$_借方税区分_$$'		,CommUtils.nullToBlank(kankoMstL.CreditTaxKbn__c))
					.Replace('$$_借方金額_$$'			,paymentAmount)
					// 消費税情報を設定する
					.Replace('$$_貸方科目コード_$$'	,CommUtils.nullToBlank(kankoMstR.KanjocodeCode__c))
					.Replace('$$_貸方補助コード_$$'	,CommUtils.nullToBlank(kankoMstR.KanjoHojocode__c))
					//.Replace('$$_貸方税区分_$$'		,CommUtils.nullToBlank(kankoMstR.CreditTaxKbn__c))
					.Replace('$$_貸方金額_$$'			,paymentAmount);
			// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
			if (gccInfo.isExtraMode) {
				csv = csv
						.replace('$$_借方部門コード_$$'	, getDepartCode(CommUtils.nullToBlank(kankoMstL.DebitDepartCode__c), true))
						.replace('$$_借方税区分_$$'		, CommUtils.nullToBlank(kankoMstL.DebitTaxKbn__c))
						.replace('$$_借方税率_$$'			, '')
						.replace('$$_借方軽減税率_$$'		, '')
						.replace('$$_借方摘要_$$'			, '')
						.replace('$$_貸方部門コード_$$'	, getDepartCode(CommUtils.nullToBlank(kankoMstR.CreditDepartCode__c), false))
						.replace('$$_貸方税区分_$$' 		, CommUtils.nullToBlank(kankoMstR.CreditTaxKbn__c))
						.replace('$$_貸方税率_$$'			, '')
						.replace('$$_貸方軽減税率_$$'		, '')
						.replace('$$_貸方摘要_$$'			, '')
						;
			}
			// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
// 2018/06/12 仕訳Rollup機能追加対応 BEGIN	
setupRollupInfo(acc.frs__r.Name,
				// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) BEGIN
				//CommUtils.nullToBlank(kankoMstL.KanjocodeCode__c),
				kankoMstL,
				// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) END
				paymentAmount,
				ROLLUP_TYPE.SALES_L);
								
setupRollupInfo(acc.frs__r.Name,
				// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) BEGIN
				//CommUtils.nullToBlank(kankoMstR.KanjocodeCode__c),
				kankoMstR,
				// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) END
				paymentAmount,
				ROLLUP_TYPE.SALES_R);
// 2018/06/12 仕訳Rollup機能追加対応 END	
		}

		return csv;
	}

	/**
	* 入出金CSV出力情報作成
	**/
	private String generalDepPayCsvInfo(ConvertXmlConfig ccInfo,Map<String, KanjoKamoku__c> kanjoKamokuMstMap ) {
		// XMLに入力、出金の設定情報がなかったの場合、該当機能は実施対象外
		if (ccInfo.cashInputInMap.isEmpty() && ccInfo.cashOutputInMap.isEmpty()) return '';
		// 入金情報
		String depositQuery = 'select TaxRate__c,depositamountExc__c,name,Kamoku__c,depositamount__c,deposititem__c,ShopCode__c,Reldeposit__r.Name from deposit__c where Reldeposit__c = :gRsvAccoutId ';
		if(!CommUtils.isBlank(gShopCode)){
		 	depositQuery += ' And ShopInfoRef__r.ShopCode__c = :gShopCode ';
		}
		List<deposit__c> deposits = DataBase.query(depositQuery);
		//  出金情報
		String paymentQuery = 'select TaxRate__c,PamountExc__c,name,Pkamoku__c,Pamount__c,Pitem__c,ShopCode__c,Relpayment__r.Name from Paymentslip__c where Relpayment__c = :gRsvAccoutId ';
		if(!CommUtils.isBlank(gShopCode)){
		 	paymentQuery += ' And ShopInfoRef__r.ShopCode__c = :gShopCode ';
		}
		List<Paymentslip__c> paymentSlips = DataBase.query(paymentQuery);
		// 一行CSV出力のテンプレート
		// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
		/*
		String SingCsvTemplate = CONST_CSVDATA_TEMPLATE
							//.Replace('$$_伝票区切_$$' 			, ccInfo.ver)
							.Replace('$$_借方部門コード_$$'	, ccInfo.debdepartcode)
							//.Replace('$$_借方消費税額_$$'		, ccInfo.debconsumptax)
							.Replace('$$_貸方部門コード_$$'	, ccInfo.credepartcode);
							//.Replace('$$_貸方消費税額_$$'		, ccInfo.creconsumptax)
							//.Replace('$$_入力プログラム区分_$$'	, ccInfo.inputprogramkbn);
							*/
		String SingCsvTemplate = CONST_CSVDATA_TEMPLATE;
		if (!ccInfo.isExtraMode) {
			SingCsvTemplate = SingCsvTemplate
				.Replace('$$_借方部門コード_$$'	, ccInfo.debdepartcode)
				.Replace('$$_貸方部門コード_$$'	, ccInfo.credepartcode);
		}
		// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
		// 2018/08/06 税込金額から消費税を計算する BEGIN
		SingCsvTemplate = getTaxCalInfo(SingCsvTemplate,TaxCalType0);
		// 2018/08/06 税込金額から消費税を計算する END
		String csvBody = '';
		// 2019/09/20 多税率機能対応 WSQ BEGIN
		CaseConfig cashConfig = new CaseConfig(gShopCode);
		Integer pointLen = CommUtils.getPointLen();
		// 入金、出金明細の消費税を定義される場合、
		// 2019/09/20 多税率機能対応 WSQ END
		for (deposit__c deposit : deposits) {


			String kanjoIn = ccInfo.cashInputInMap.get(deposit.Kamoku__c);
			String kanjoOu = ccInfo.cashInputOuMap.get(deposit.Kamoku__c);
			KanjoKamoku__c kanjoInOb = kanjoKamokuMstMap.get(kanjoIn);
			if (kanjoInOb == null) kanjoInOb = new KanjoKamoku__c();
			KanjoKamoku__c kanjoOuOb = kanjoKamokuMstMap.get(kanjoOu);
			if (kanjoOuOb == null) kanjoOuOb = new KanjoKamoku__c();
			
			Decimal payAmount = Commutils.nullToZero(deposit.depositamount__c);
			// 2019/09/20 多税率機能対応 WSQ BEGIN
			decimal noTaxPayAmount = payAmount,incTaxPayAmount = payAmount;
			decimal taxRate = CommUtils.nullToZero(deposit.TaxRate__c);
			// 消費税設定ある場合、消費税により、税込金額と税抜金額を計算する
			if (cashConfig.depismulititax && taxRate > 0) {
				// DBに格納している金額は税込場合
				noTaxPayAmount = CommUtils.nullToZero(deposit.depositamountExc__c);
			}
			// 消費税金額を計算する
			decimal taxAmount = (incTaxPayAmount - noTaxPayAmount);
			// 計算後の税抜金額は税込金額により大きく場合、０に戻る
			// 税抜金額は０場合でも、消費税出力不要
			if (taxAmount < 0 || noTaxPayAmount == 0) { 
				taxAmount = 0; 
				noTaxPayAmount = incTaxPayAmount = payAmount;
			}
			noTaxPayAmount = formatOuputNumber(noTaxPayAmount);//税抜
			incTaxPayAmount= formatOuputNumber(incTaxPayAmount);//税込
			taxAmount = formatOuputNumber(taxAmount);//消費税
			
			// 2019/09/20 多税率機能対応 WSQ END
			csvBody += SingCsvTemplate
							.Replace('$$_伝票区切_$$'			, getDenhyouDivMark(null))
							.Replace('$$_伝票番号_$$'			, String.valueOf(ccInfo.startno))
							.Replace('$$_伝票日付_$$' 		, getDenhyouDateStr(deposit.Reldeposit__r.Name))
							.Replace('$$_借方科目コード_$$' 	, CommUtils.nullToBlank(kanjoInOb.KanjocodeCode__c))
							.Replace('$$_借方補助コード_$$' 	, CommUtils.nullToBlank(kanjoInOb.KanjoHojocode__c))
							//.Replace('$$_借方税区分_$$' 		, CommUtils.nullToBlank(kanjoInOb.DebitTaxKbn__c))
							// 2019/09/20 多税率機能対応 WSQ BEGIN
							//.Replace('$$_借方金額_$$' 		, String.valueOf(payAmount.intValue()))
							.Replace('$$_借方金額_$$' 		, String.valueOf(incTaxPayAmount))
							// 2019/09/20 多税率機能対応 WSQ END
							.Replace('$$_貸方科目コード_$$' 	, CommUtils.nullToBlank(kanjoOuOb.KanjocodeCode__c))
							.Replace('$$_貸方補助コード_$$' 	, CommUtils.nullToBlank(kanjoOuOb.KanjoHojocode__c))
							//.Replace('$$_貸方税区分_$$' 		, CommUtils.nullToBlank(kanjoOuOb.CreditTaxKbn__c))
							// 2019/09/20 多税率機能対応 WSQ BEGIN
							//.Replace('$$_貸方金額_$$' 		, String.valueOf(payAmount.intValue()))
							.Replace('$$_貸方金額_$$' 		, String.valueOf(noTaxPayAmount))
							// 2019/09/20 多税率機能対応 WSQ END
							.Replace('$$_摘要_$$' 			, CommUtils.nullToBlank(deposit.deposititem__c));
			// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
			if (ccInfo.isExtraMode) {
				csvBody = csvBody
							.replace('$$_借方部門コード_$$'	, getDepartCode(CommUtils.nullToBlank(kanjoInOb.DebitDepartCode__c), true))
							.replace('$$_借方税区分_$$'		, CommUtils.nullToBlank(kanjoInOb.DebitTaxKbn__c))
							.replace('$$_借方税率_$$'			, '')
							.replace('$$_借方軽減税率_$$'		, '')
							.replace('$$_借方摘要_$$'			, CommUtils.nullToBlank(deposit.deposititem__c))
							.replace('$$_貸方部門コード_$$'	, getDepartCode(CommUtils.nullToBlank(kanjoOuOb.CreditDepartCode__c), false))
							.replace('$$_貸方税区分_$$' 		, CommUtils.nullToBlank(kanjoOuOb.CreditTaxKbn__c))
							.replace('$$_貸方税率_$$'			, CommUtils.nullToBlank(formatOuputTaxRate(taxRate)))
							.replace('$$_貸方軽減税率_$$'		, getReducedFlg(taxRate))
							.replace('$$_貸方摘要_$$'			, CommUtils.nullToBlank(deposit.deposititem__c))
							;
							//.replace('$$_貸方部門コード_$$'	, CommUtils.nullToBlank(kanjoInOb.CreditDepartCode__c))	.
			}
			// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
			// 2019/09/20 多税率機能対応 WSQ BEGIN
			if (taxAmount != 0) {
				String kanjoCode = ccInfo.taxKanjoMap.containskey(taxrate) ? ccInfo.taxKanjoMap.get(taxrate) : ccInfo.taxKanjoCode;
				KanjoKamoku__c taxKankoMst = kanjoKamokuMstMap.get(kanjoCode);
				if (taxKankoMst == null) taxKankoMst = new KanjoKamoku__c();
				csvBody += SingCsvTemplate
							.Replace('$$_伝票区切_$$'			, '')
							.Replace('$$_伝票番号_$$'			, String.valueOf(ccInfo.startno))
							.Replace('$$_伝票日付_$$' 		, getDenhyouDateStr(deposit.Reldeposit__r.Name))
							.Replace('$$_借方科目コード_$$' 	, '')
							.Replace('$$_借方補助コード_$$' 	, '')
							.Replace('$$_借方金額_$$' 		, '')
							.Replace('$$_貸方科目コード_$$' 	, CommUtils.nullToBlank(taxKankoMst.KanjocodeCode__c))
							.Replace('$$_貸方補助コード_$$' 	, CommUtils.nullToBlank(taxKankoMst.KanjoHojocode__c))
							.Replace('$$_貸方金額_$$' 		, String.valueOf(taxAmount))
							.Replace('$$_摘要_$$' 			, CommUtils.nullToBlank(deposit.deposititem__c));
			// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
			if (ccInfo.isExtraMode) {
				csvBody = csvBody
							.replace('$$_借方部門コード_$$'	, '')
							.replace('$$_借方税区分_$$'		, '')
							.replace('$$_借方税率_$$'			, '')
							.replace('$$_借方軽減税率_$$'		, '')
							.replace('$$_借方摘要_$$'			, '')
							.replace('$$_貸方部門コード_$$'	, getDepartCode(CommUtils.nullToBlank(taxKankoMst.CreditDepartCode__c), false))
							.replace('$$_貸方税区分_$$'		, CommUtils.nullToBlank(taxKankoMst.CreditTaxKbn__c))
							.replace('$$_貸方税率_$$'			, '')
							.replace('$$_貸方軽減税率_$$'		, '')
							.replace('$$_貸方摘要_$$'			, CommUtils.nullToBlank(deposit.deposititem__c))
							;
			}
			// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
						
// 右側に消費税値を追加する
setupRollupInfo(getDenhyouDateStr(deposit.Reldeposit__r.Name),
				taxKankoMst,
				String.valueOf(taxAmount),
				ROLLUP_TYPE.SALES_R);
			}
			// 2019/09/20 多税率機能対応 WSQ END
			
			// 伝票番号設定する
			ccInfo.startno++;
// 2018/06/12 仕訳Rollup機能追加対応 BEGIN	
setupRollupInfo(getDenhyouDateStr(deposit.Reldeposit__r.Name),
				// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) BEGIN
				//CommUtils.nullToBlank(kanjoInOb.KanjocodeCode__c),
				kanjoInOb,
				// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) END
				// 2019/09/20 多税率機能対応 WSQ BEGIN
				//String.valueOf(payAmount.intValue()),
				String.valueOf(incTaxPayAmount),
				// 2019/09/20 多税率機能対応 WSQ END
				ROLLUP_TYPE.SALES_L);
									
setupRollupInfo(getDenhyouDateStr(deposit.Reldeposit__r.Name),
				// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) BEGIN
				//CommUtils.nullToBlank(kanjoOuOb.KanjocodeCode__c),
				kanjoOuOb,
				// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) END
				// 2019/09/20 多税率機能対応 WSQ BEGIN
				//String.valueOf(payAmount.intValue()),
				String.valueOf(noTaxPayAmount),
				// 2019/09/20 多税率機能対応 WSQ END
				ROLLUP_TYPE.SALES_R);
// 2018/06/12 仕訳Rollup機能追加対応 END	
		}
		

		for (Paymentslip__c payMent : paymentSlips) {

			String kanjoIn = ccInfo.cashOutputInMap.get(payMent.Pkamoku__c);
			String kanjoOu = ccInfo.cashOutputOuMap.get(payMent.Pkamoku__c);
			KanjoKamoku__c kanjoInOb = kanjoKamokuMstMap.get(kanjoIn);
			if (kanjoInOb == null) kanjoInOb = new KanjoKamoku__c();
			KanjoKamoku__c kanjoOuOb = kanjoKamokuMstMap.get(kanjoOu);
			if (kanjoOuOb == null) kanjoOuOb = new KanjoKamoku__c();
			
			Decimal payAmount = Commutils.nullToZero(payMent.Pamount__c);
			// 2019/09/20 多税率機能対応 WSQ BEGIN
			decimal noTaxPayAmount= payAmount, incTaxPayAmount = payAmount;
			decimal taxRate = CommUtils.nullToZero(payMent.TaxRate__c);
			// 消費税設定ある場合、消費税により、税込金額と税抜金額を計算する
			if (cashConfig.payismulititax && taxRate > 0) {
				// DBに格納している金額は税込場合
				noTaxPayAmount = CommUtils.nullToZero(payMent.PamountExc__c);
			}
			// 消費税金額を計算する
			decimal taxAmount = (incTaxPayAmount - noTaxPayAmount);
			// 計算後の税抜金額は税込金額により大きく場合、０に戻る
			// 税抜金額は０場合でも、消費税出力不要
			if (taxAmount < 0 || noTaxPayAmount == 0) { 
				taxAmount = 0; 
				noTaxPayAmount = incTaxPayAmount = payAmount;
			}
			noTaxPayAmount = formatOuputNumber(noTaxPayAmount);
			incTaxPayAmount= formatOuputNumber(incTaxPayAmount);
			taxAmount = formatOuputNumber(taxAmount);
			// 2019/09/20 多税率機能対応 WSQ END
			csvBody += SingCsvTemplate
							.Replace('$$_伝票区切_$$'			, getDenhyouDivMark(null))
							.Replace('$$_伝票日付_$$' 		, getDenhyouDateStr(payMent.Relpayment__r.Name))
							.Replace('$$_伝票番号_$$'			, String.valueOf(ccInfo.startno))
							.Replace('$$_借方科目コード_$$' 	, CommUtils.nullToBlank(kanjoInOb.KanjocodeCode__c))
							.Replace('$$_借方補助コード_$$' 	, CommUtils.nullToBlank(kanjoInOb.KanjoHojocode__c))
							//.Replace('$$_借方税区分_$$' 		, CommUtils.nullToBlank(kanjoInOb.DebitTaxKbn__c))
							// 2019/09/20 多税率機能対応 WSQ BEGIN
							//.Replace('$$_借方金額_$$' 		, String.valueOf(payAmount.intValue()))
							.Replace('$$_借方金額_$$' 		, String.valueOf(noTaxPayAmount))
							// 2019/09/20 多税率機能対応 WSQ END
							.Replace('$$_貸方科目コード_$$' 	, CommUtils.nullToBlank(kanjoOuOb.KanjocodeCode__c))
							.Replace('$$_貸方補助コード_$$'	, CommUtils.nullToBlank(kanjoOuOb.KanjoHojocode__c))
							//.Replace('$$_貸方税区分_$$' 		, CommUtils.nullToBlank(kanjoOuOb.CreditTaxKbn__c))
							// 2019/09/20 多税率機能対応 WSQ BEGIN
							//.Replace('$$_貸方金額_$$' 		, String.valueOf(payAmount.intValue()))
							.Replace('$$_貸方金額_$$' 		, String.valueOf(incTaxPayAmount))
							// 2019/09/20 多税率機能対応 WSQ END
							.Replace('$$_摘要_$$' 			, CommUtils.nullToBlank(payMent.Pitem__c));
			// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
			if (ccInfo.isExtraMode) {
				csvBody = csvBody
							.replace('$$_借方部門コード_$$'	, getDepartCode(CommUtils.nullToBlank(kanjoInOb.DebitDepartCode__c), true))
							.replace('$$_借方税区分_$$'		, CommUtils.nullToBlank(kanjoInOb.DebitTaxKbn__c))
							.replace('$$_借方税率_$$'			, CommUtils.nullToBlank(formatOuputTaxRate(taxRate)))
							.replace('$$_借方軽減税率_$$'		, getReducedFlg(taxRate))
							.replace('$$_借方摘要_$$'			, CommUtils.nullToBlank(payMent.Pitem__c))
							.replace('$$_貸方部門コード_$$'	, getDepartCode(CommUtils.nullToBlank(kanjoOuOb.CreditDepartCode__c), false))
							.replace('$$_貸方税区分_$$' 		, CommUtils.nullToBlank(kanjoOuOb.CreditTaxKbn__c))
							.replace('$$_貸方税率_$$'			, '')
							.replace('$$_貸方軽減税率_$$'		, '')
							.replace('$$_貸方摘要_$$'			, CommUtils.nullToBlank(payMent.Pitem__c))
							;
			}
			// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
			// 2019/09/20 多税率機能対応 WSQ BEGIN
			if (taxAmount != 0) {
				// 会計科目
				String kanjoCode = ccInfo.taxPayKanjoMap.containskey(taxrate) ? ccInfo.taxPayKanjoMap.get(taxrate) : ccInfo.taxPayKanjoCode;
				KanjoKamoku__c taxKankoMst = kanjoKamokuMstMap.get(kanjoCode);
				if (taxKankoMst == null) taxKankoMst = new KanjoKamoku__c();
				
				csvBody += SingCsvTemplate
							.Replace('$$_伝票区切_$$'			, '')
							.Replace('$$_伝票日付_$$' 		, getDenhyouDateStr(payMent.Relpayment__r.Name))
							.Replace('$$_伝票番号_$$'			, String.valueOf(ccInfo.startno))
							.Replace('$$_借方科目コード_$$' 	, CommUtils.nullToBlank(taxKankoMst.KanjocodeCode__c))
							.Replace('$$_借方補助コード_$$' 	, CommUtils.nullToBlank(taxKankoMst.KanjoHojocode__c))
							.Replace('$$_借方金額_$$' 		, String.valueOf(taxAmount))
							.Replace('$$_貸方科目コード_$$' 	, '')
							.Replace('$$_貸方補助コード_$$'	, '')
							.Replace('$$_貸方金額_$$' 		, '')
							.Replace('$$_摘要_$$' 			, CommUtils.nullToBlank(payMent.Pitem__c));
			// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
			if (ccInfo.isExtraMode) {
				csvBody = csvBody
							.replace('$$_借方部門コード_$$'	, getDepartCode(CommUtils.nullToBlank(taxKankoMst.DebitDepartCode__c), true))
							.replace('$$_借方税区分_$$'		, CommUtils.nullToBlank(taxKankoMst.DebitTaxKbn__c))
							.replace('$$_借方税率_$$'			, '')
							.replace('$$_借方軽減税率_$$'		, '')
							.replace('$$_借方摘要_$$'			, CommUtils.nullToBlank(payMent.Pitem__c))
							.replace('$$_貸方部門コード_$$'	, '')
							.replace('$$_貸方税区分_$$'		, '')
							.replace('$$_貸方税率_$$'			, '')
							.replace('$$_貸方軽減税率_$$'		, '')
							.replace('$$_貸方摘要_$$'			, '')
							;
			}
			// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
// 2016/09/23 仕訳Rollup機能追加対応 BEGIN
setupRollupInfo(getDenhyouDateStr(payMent.Relpayment__r.Name),
				taxKankoMst,
				String.valueOf(taxAmount),
				ROLLUP_TYPE.SALES_L);
			}
			// 伝票番号設定する
			ccInfo.startno++;
// 2018/06/12 仕訳Rollup機能追加対応 BEGIN	
setupRollupInfo(getDenhyouDateStr(payMent.Relpayment__r.Name),
				// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) BEGIN
				//CommUtils.nullToBlank(kanjoInOb.KanjocodeCode__c),
				kanjoInOb,
				// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) END
				// 2019/09/20 多税率機能対応 WSQ BEGIN
				//String.valueOf(payAmount.intValue()),
				String.valueOf(noTaxPayAmount),
				// 2019/09/20 多税率機能対応 WSQ END
				ROLLUP_TYPE.SALES_L);
									
setupRollupInfo(getDenhyouDateStr(payMent.Relpayment__r.Name),
				// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) BEGIN
				//CommUtils.nullToBlank(kanjoOuOb.KanjocodeCode__c),
				kanjoOuOb,
				// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) END
				// 2019/09/20 多税率機能対応 WSQ BEGIN
				//String.valueOf(payAmount.intValue()),
				String.valueOf(incTaxPayAmount),
				// 2019/09/20 多税率機能対応 WSQ END
				ROLLUP_TYPE.SALES_R);
// 2018/06/12 仕訳Rollup機能追加対応 END	
		}
		return csvBody;
	}
	// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
	// 軽減税率かどうかを出力する。8%の取引の行には"1"、10%の取引の行には"0"10%の取引の行には"0"
	private static String getReducedFlg(Decimal taxRate) {
		if (taxRate == 0) return '';
		return (taxRate == 8 ? '1' : '0');
	}
	// 部門コード取得ロジック共通化
	private String getDepartCode(String s, Boolean leftFlg) {
		if (CommUtils.isBlank(s)) {
			return (leftFlg ? gccInfo.debdepartcode : gccInfo.credepartcode);
		} else return s;
	}
	// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
	/**
	* 旧会計から既存の支払情報を更新・追加を行う
	**/
	private void preOldSyncPaymentInfo (List<AccountAcount__c> accs) {
		// 引き渡し会計の関連情報の支払情報を全部取得を行う
		// 予約インデックスID　OR　（予約インデックス＝NULL AND 会計ID一致）
		Set<Id> leadIdxIdsSet = new Set<Id>();
		Set<Id> accIdsSet = new Set<Id>();
		for (AccountAcount__c acc : accs) {
			// Relreserve__c,Relreserve__r.LeadIndexRef__c
			if (acc.Relreserve__r.LeadIndexRef__c != null) leadIdxIdsSet.add(acc.Relreserve__r.LeadIndexRef__c);
			accIdsSet.add(acc.Id);
		}
		if (accIdsSet.isEmpty()) return;
		
		// 予約インデックスから既存の支払情報を取得する
		Map<String, PaymentInfo__c> relPaymentMap = new Map<String, PaymentInfo__c>();
		
		// 当日の売上日の関連の既存の【会計支払】情報を全部取得を行う
		List<TTend__c> ttends = [select Id, Name, Field19__c, Field20__c, Field2__c, Field1__c, 
									Field1__r.Relreserve__r.LeadIndexRef__c,
									Field1__r.Relreserve__r.LeadIndexSubId__c,
									Field1__r.Relreserve__r.RoomGroupNo__c			
				From TTend__c 
				where Field1__r.Relreserve__r.LeadIndexRef__c in :leadIdxIdsSet 
					And OutSideAccount__c = 1
					And Field1__c in : accIdsSet];
		for (TTend__c ttend : ttends) {
			// KEY:予約インデックスID_会計ID_会計支払ID_会計明細ID
			String key = 	ttend.Field1__r.Relreserve__r.LeadIndexRef__c 
						+ '_' + ttend.Field1__c
						+ '_' + ttend.Id
						+ '_';
			PaymentInfo__c tmpPaymentInfo = new PaymentInfo__c(
				 LeadIndexRef__c		= ttend.Field1__r.Relreserve__r.LeadIndexRef__c
				,AccountAcountRef__c	= ttend.Field1__c
				,TTendRef__c			= ttend.Id
				,DepositAmount__c		= CommUtils.nullToZero(ttend.Field20__c)	// 支払金額
				,MediaTypeCode__c		= ttend.Field2__c
			);
			tmpPaymentInfo.AccountAcountRef__r = ttend.Field1__r;
			tmpPaymentInfo.AccountAcountRef__r.Relreserve__r = ttend.Field1__r.Relreserve__r;
			relPaymentMap.put(key, tmpPaymentInfo);
		}
		// 「前受金」経由で「支払情報」作成を行う
		// 関連の会計支払と【会計明細】に設定されている【前受金】明細は支払情報に反映を行う
		List<Tran1__c> trans  = [select Id, Name, Field1__c,Field41__c,PaymentType__c,
									Field1__r.Relreserve__r.LeadIndexRef__c,
									Field1__r.Relreserve__r.LeadIndexSubId__c,
									Field1__r.Relreserve__r.RoomGroupNo__c
				From Tran1__c
				Where Field1__r.Relreserve__r.LeadIndexRef__c in :leadIdxIdsSet 
					And Accountoutside__c = 1
					And Field1__c in : accIdsSet
					And ActionType__c = :PROD_ACTION_TYPE_AR ];
		for (Tran1__c tran : trans) {
			String key = 	tran.Field1__r.Relreserve__r.LeadIndexRef__c 
						+ '_' + tran.Field1__c
						+ '_' 
						+ '_' + tran.Id;
			// 支払種別
			//String tranPaymentType = CommUtils.isBlank(tran.PaymentType__c) ? tran.Field7__r.PaymentType__c : tran.PaymentType__c;
			PaymentInfo__c tmpPaymentInfo = new PaymentInfo__c(
				 LeadIndexRef__c		= tran.Field1__r.Relreserve__r.LeadIndexRef__c
				,AccountAcountRef__c	= tran.Field1__c
				,Tran1Ref__c			= tran.Id
				,DepositAmount__c		= CommUtils.nullToZero(tran.Field41__c)
				//,MediaTypeCode__c		= ttend.Field2__c【前受付金の場合、非設定[支払情報自動設定の場合、割引、クポーン優先減算、その後、順番で減算する]】
			);
			tmpPaymentInfo.AccountAcountRef__r = tran.Field1__r;
			tmpPaymentInfo.AccountAcountRef__r.Relreserve__r = tran.Field1__r.Relreserve__r;
			relPaymentMap.put(key, tmpPaymentInfo);
		}

		// 当日分の既存の支払情報をクリアする
		delete [select id from PaymentDetail__c where AccountAcountRef__c in :accIdsSet];
		delete [select id from PaymentInfo__c where AccountAcountRef__c in :accIdsSet];
		
		// 既存の支払情報	
		Map<String, PaymentInfo__c> existPaymentMap = new Map<String, PaymentInfo__c>();
		// 支払情報に新規、更新を行う
		for(PaymentInfo__c pay : [
			Select id, Name,LeadIndexRef__c,AccountAcountRef__c,TTendRef__c,Tran1Ref__c,DepositAmount__c,ChildRenRsCount__c
			From PaymentInfo__c 
			where LeadIndexRef__c in :leadIdxIdsSet
			And ImgDataFlg__c = false				// 架空情報は対象外
			And (TTendRef__c != null Or Tran1Ref__c != null)]) {
			String key =	pay.LeadIndexRef__c 
						+ '_' + pay.AccountAcountRef__c
						+ '_' + CommUtils.nullToBlank(pay.TTendRef__c)
						+ '_' + CommUtils.nullToBlank(pay.Tran1Ref__c);
			// 既存の支払情報を格納する
			existPaymentMap.put(key, pay);	
		}
		// 関連の支払情報を再リンクする
		List<PaymentInfo__c> upsertPayInfos = new List<PaymentInfo__c>();
		//List<String> linkPayInfoKeys = new List<String>();	// 該当会計関連に前受付金が存在する場合、前受付金経由で支払する、前受付金が非存在する場合、そのまま支払情報に反映する
		List<PaymentInfo__c> linkPayInfos = new List<PaymentInfo__c>();
		// 当日に存在する会計支払情報と前受付金情報により、当日の支払情報作成を行う
		for (String key : relPaymentMap.keySet()) {
			if (existPaymentMap.containsKey(key)) {
				// 該当会計支払情報は既に支払情報に存在する場合
				PaymentInfo__c existPay = existPaymentMap.get(key);
				// ---------------------
				// 支払情報の更新処理（預かり金額は変更される場合、該当支払情報を更新を行う）
				// ---------------------
				if (existPay.DepositAmount__c != relPaymentMap.get(key).DepositAmount__c) {
					existPay.DepositAmount__c = relPaymentMap.get(key).DepositAmount__c;
					upsertPayInfos.add(existPay);
				}
			} else {
				// ---------------------
				// 支払情報の新規作成[当日の会計の関連の支払情報]
				// ---------------------
				// 現金・カードの場合、前受付金存在する場合、前受付金経由で支払する、
				// 前受付金がなかったの場合、該当支払情報はそのままPCA連携を行う
				PaymentInfo__c locPay = relPaymentMap.get(key);
				if (locPay.MediaTypeCode__c == CommConst.MEDIA_TYPE_CD_01 ||
					locPay.MediaTypeCode__c == CommConst.MEDIA_TYPE_CD_02 ) {
					//linkPayInfos.add(locPay);
					// 該当前受付金は支払情報に未作成の場合、新規作成を行う
					if (locPay.Id == null && locPay.Tran1Ref__c != null) upsertPayInfos.add(locPay);
					else linkPayInfos.add(locPay);
				} 
				// 現金・カード以外の場合、そのまま新規作成を行う
				else {
					upsertPayInfos.add(locPay);
				}
			}
		}
		if (!upsertPayInfos.isEmpty()) upsert upsertPayInfos;

		// 利用明細により、PCA連携用利用明細情報を作成する
		// Map<Id, List<PaymentInfo__c>>
		Map<String, List<PaymentInfo>> discountPayMap = new Map<String, List<PaymentInfo>>();
		Map<String, List<PaymentInfo>> coponPayMap = new Map<String, List<PaymentInfo>>();
		Map<String, List<PaymentInfo>> normalPayMap = new Map<String, List<PaymentInfo>>();
		//Map<Id, List<PaymentInfo__c>> arPayMap = new Map<Id, List<PaymentInfo__c>>();	// 前受付金で作成の支払情報
		//Map<Id, Decimal> arRemaindPayMoneyMap = new Map<Id, Decimal>();					// 前受付金の残金情報格納する
		Set<Id> arRemaindPayMoneySet = new Set<Id>();							// 前受付金の残金情報格納する
		// 当日の新規作成したの会計支払情報を含めて、支払金額ありの支払情報を取得する
		for(PaymentInfo__c pay : [
			select id, Name,LeadIndexRef__c,AccountAcountRef__c,TTendRef__c,Tran1Ref__c,DepositAmount__c,RemainingMoney__c,MediaTypeCode__c,ChildRenRsCount__c
			// 同じ予約インデックスID,SUBインデックスID、グループNO
			,AccountAcountRef__r.Relreserve__r.LeadIndexSubId__c
			,AccountAcountRef__r.Relreserve__r.RoomGroupNo__c
			,PaymentType__c
			From PaymentInfo__c 
			where LeadIndexRef__c in :leadIdxIdsSet
			And RemainingMoney__c > 0
			And (TTendRef__c != null Or Tran1Ref__c != null)
			]) {
			//
			//Id leadIdxId = pay.LeadIndexRef__c;
			// 予約インデックス_予約インデックスSUB_グループNOでキー保存
			String key = pay.LeadIndexRef__c 
						+ '_' 
						+ pay.AccountAcountRef__r.Relreserve__r.LeadIndexSubId__c 
						+ '_' 
						+ CommUtils.nullToBlank(pay.AccountAcountRef__r.Relreserve__r.RoomGroupNo__c);
			// 割引
			if (pay.MediaTypeCode__c == CommConst.MEDIA_TYPE_CD_12) {
				if (!discountPayMap.containsKey(key)) discountPayMap.put(key, new List<PaymentInfo>());
				discountPayMap.get(key).add(new PaymentInfo(pay));
			} else if (pay.MediaTypeCode__c == CommConst.MEDIA_TYPE_CD_11) {
				if (!coponPayMap.containsKey(key)) coponPayMap.put(key, new List<PaymentInfo>());
				coponPayMap.get(key).add(new PaymentInfo(pay));
			} else {
				// ========================
				// 残金ありの支払情報を格納する
				// ========================
				// 前受付金で作成の支払情報
				// 前受付金の支払情報が存在する場合、該当支払情報から減算する、以外の支払情報を減算対象外にする（例：売掛、予約金など）
				if (pay.Tran1Ref__c != null) {
					arRemaindPayMoneySet.add(pay.Id);
				}
				// 残金ありの支払情報[(当日以外の支払、かつ　該当支払情報の残金はまだ残りの場合) OR (当日で前受付金情報を格納する)
				//（前受付金　OR　事前一括支払済の場合）]
				if (!normalPayMap.containsKey(key)) normalPayMap.put(key, new List<PaymentInfo>());
				normalPayMap.get(key).add(new PaymentInfo(pay));
			}
		}
		
		// 支払情報「前受付金」から、会計支払情報の現金・カード情報減算を行う
		// 減算後、残りの会計支払情報は自動的にそのまま会計支払情報に新規作成を行う
		// 現金・カードの会計支払情報
		// 重複支払情報出力しないため、前受付金で支払可能の会計支払情報は「支払情報」へ反映しない機能対応
		//Integer linkCnt = 0;
		List<PaymentInfo__c> insLinkPayInfos = new List<PaymentInfo__c>();
		// 残金により、存在の現金・カードの支払情報を ［相殺］処理を行う
		// 現金・カードの支払情報を１件づつ処理を行う
		for (PaymentInfo__c pay : linkPayInfos) {
			// 予約インデックス_予約インデックスSUB_グループNOでキー保存
			String key = pay.LeadIndexRef__c 
						+ '_' 
						+ pay.AccountAcountRef__r.Relreserve__r.LeadIndexSubId__c 
						+ '_' 
						+ CommUtils.nullToBlank(pay.AccountAcountRef__r.Relreserve__r.RoomGroupNo__c);
			// 該当会計支払関連の残金ありの支払情報がなかった場合、該当会計支払から新規支払情報を作成する
			//if (!normalPayMap.containsKey(pay.LeadIndexRef__c)) {
			if (!normalPayMap.containsKey(key)) {
				insLinkPayInfos.add(pay);
				continue;
			}
			// *********************************************
			// 現金・カード関連の支払情報に、前受付金の支払情報が存在する場合
			// *********************************************
			//if (normalPayMap.containsKey(pay.LeadIndexRef__c)) {
				// 該当会計支払に格納の利用金額
				Decimal remaindPayMoney = pay.DepositAmount__c;
				//　残金ありの支払情報リストを取得する
				List<PaymentInfo> remaindMoneyPays = normalPayMap.get(key);
				// 残金ありの支払情報を取得する、この中に、前受付金経由で作成した支払情報のみ利用して、相殺対象の現金、カード支払情報を処理する
				for (PaymentInfo arPay : remaindMoneyPays) {
					// 残金有りの支払情報、種別は「前受付金」以外の場合、該当支払情報を使わない、前受付金のみ、相殺減算を行う
					if (!arRemaindPayMoneySet.contains(arPay.s.Id)) continue;
					// 該当会計支払の情報は全部前受付金残金経由で全部支払可能場合、該当会計支払は重複認識して、支払情報へ反映なし
					Decimal arRemaindPayMoney = arPay.remainingMoney;//CommUtils.nullToZero(arRemaindPayMoneyMap.get(arPay.Id));
					if (arRemaindPayMoney == 0) continue;

					// 利用金額は全部前受付金の残金で全部支払可能の場合、該当会計支払は重複情報と認識する
					if (remaindPayMoney <= arRemaindPayMoney) {	
						// 支払情報の残金は減算を行う
						//arRemaindPayMoneyMap.put(arPay.Id, arRemaindPayMoney - remaindPayMoney);
						arPay.remainingMoney = arRemaindPayMoney - remaindPayMoney;
						// 現在の会計支払情報の利用金額全部前受付金で利用するので、該当会計支払情報は支払情報作成しないため、残り金額０にせっていする
						remaindPayMoney = 0;
						// 次の支払情報は処理する
						break;
					} else {
						// 前受付金の金額は足りないの場合
						//arRemaindPayMoneyMap.put(arPay.Id, 0);
						arPay.remainingMoney = 0;
						// 該当会計支払に残り金額を計算する
						remaindPayMoney = remaindPayMoney - arRemaindPayMoney;
					}
				}
				// 会計支払に未支払金額は残りの場合、残り金額から支払情報を新規作成する
				if (remaindPayMoney > 0) {
					// 残り金額は支払情報を作成する
					pay.DepositAmount__c = remaindPayMoney;
					pay.ImgDataFlg__c = true;
					insLinkPayInfos.add(pay);
				}
			//}
		}
		// 支払情報を追加作成を行う
		if (!insLinkPayInfos.isEmpty()) insert insLinkPayInfos;

		// 新規作成の会計支払情報はMAPに格納を行う
		for (PaymentInfo__c pay : insLinkPayInfos) {
			//Id leadIdxId = pay.LeadIndexRef__c;
			// 予約インデックス_予約インデックスSUB_グループNOでキー保存
			String key = pay.LeadIndexRef__c 
						+ '_' 
						+ pay.AccountAcountRef__r.Relreserve__r.LeadIndexSubId__c 
						+ '_' 
						+ CommUtils.nullToBlank(pay.AccountAcountRef__r.Relreserve__r.RoomGroupNo__c);
			// 普通の支払情報
			if (!normalPayMap.containsKey(key)) normalPayMap.put(key, new List<PaymentInfo>());
			normalPayMap.get(key).add(new PaymentInfo(pay));
		}	

		// 支払明細作成を行う
		List<PaymentDetail__c> insertDetail = new List<PaymentDetail__c>();
		
		// 残金ありの支払情報の残金格納変数初期化設定
		for (List<PaymentInfo> rst : discountPayMap.values()) resetPayRemaindMonty(rst);
		for (List<PaymentInfo> rst : coponPayMap.values()) resetPayRemaindMonty(rst);
		for (List<PaymentInfo> rst : normalPayMap.values()) resetPayRemaindMonty(rst);
		
		// 関連支払情報を自動作成を行う
		for (AccountAcount__c acc : accs) {
			//Id leadIdxId = acc.Relreserve__r.LeadIndexRef__c;
			// 関連予約情報がなかった場合、次の処理を飛ばす
			if (acc.Relreserve__r.LeadIndexRef__c == null) continue;
			// 予約インデックス_予約インデックスSUB_グループNOでキー保存
			String key = acc.Relreserve__r.LeadIndexRef__c 
						+ '_' 
						+ acc.Relreserve__r.LeadIndexSubId__c 
						+ '_' 
						+ CommUtils.nullToBlank(acc.Relreserve__r.RoomGroupNo__c);
			// 会計明細から支払明細情報を自動作成を行う
			//if (leadIdxId != null) {
				// 関連の支払情報が存在チェック
				Decimal usedAmount = 0;
				// 会計支払場合存在チェック
				for (Tran1__c tran : acc.TranAccount__r) {
					// 該当会計の利用総金額を合計する
					usedAmount += tran.Field41__c;
				}

				// 該当会計の総利用金額を取得する
				Decimal remaindPayMoney = usedAmount;
				// 利用金額は０以上の場合
				if (remaindPayMoney > 0) {
					// 割引情報存在チェック
					List<PaymentInfo> disPayLst = discountPayMap.get(key);
					// 割引から支払情報存在する場合
					if (disPayLst != null) {
						remaindPayMoney = generalPaymentDetail(remaindPayMoney, acc, disPayLst, insertDetail);
					} // 割引情報から支払情報作成を行う
					if (remaindPayMoney > 0) {
						List<PaymentInfo> coponPayLst = coponPayMap.get(key);
						if (coponPayLst != null) {
							remaindPayMoney = generalPaymentDetail(remaindPayMoney, acc, coponPayLst, insertDetail);
						}
					} // クポーン関連支払明細情報作成
					if (remaindPayMoney > 0) {
						// 普通の支払情報を支払する
						List<PaymentInfo> norPayLst = normalPayMap.get(key);
						if (norPayLst != null) {
							remaindPayMoney = generalPaymentDetail(remaindPayMoney, acc, norPayLst, insertDetail);
						}
					} // 普通の支払情報から支払明細作成を行う
				}
			//}
		}
		if (!insertDetail.isEmpty()) insert insertDetail;
	}
	
	/**
	* 同じグループの予約情報判断用キー（同じ予約インデックス、予約インデックスSUB、グループNO
	**/
	private String getGroupNokey (Id leadIndexId, Id leadIndexSubId, Decimal groupNo) {
		// 予約インデックス_予約インデックスSUB_グループNOでキー保存
		String key = leadIndexId
					+ '_' 
					+ leadIndexSubId
					+ '_' 
					+ CommUtils.nullToBlank(groupNo);
		return key;
	}
	/**
	* 支払情報Matchするためキー列を作成する
	**/
	private String getPaymentKey (Id leadIndexId, Id accid, Id ttendId, Id tranId) {
		return leadIndexId + '_' + accid + '_' + CommUtils.nullToBlank(ttendId) + '_' + CommUtils.nullToBlank(tranId);
	}
	/**
	* 既存の支払情報を更新・追加を行う
	* 2015.06. 事前入金の場合、該当支払情報は支払情報に登録を行う
	* 2015.07.15 対象会計に紐付く同じグループの予約の関連の会計の支払情報を取得する
	**/
	private void preSyncPaymentInfo (List<AccountAcount__c> accs) {
		// 引き渡し会計の関連情報の支払情報を全部取得を行う
		// 予約インデックスID　OR　（予約インデックス＝NULL AND 会計ID一致）
		Set<Id> leadIdxIdsSet = new Set<Id>();
		Set<Id> accIdsSet = new Set<Id>();
		//Map<Id, AccountAcount__c> accsMap = new Map<Id, AccountAcount__c>();
		Map<String, Boolean> accsTranIsEmptyMap = new Map<String ,Boolean>();
		// 明細ありの会計情報を格納する<Key/Acc Id>
		Map<String, Id> accsTranIsExistMap = new Map<String ,Id>();
		//***********************************
		// 該当会計に関連の支払情報を取得するため、関連条件を格納する
		//***********************************
		Set<String> relFilterkeySet = new Set<String>();
		Set<Id> leadIndexIdSet = new Set<Id>();
		Set<Id> leadIndexSubIdSet = new Set<Id>();
		Set<Decimal> leadGroupNoSet = new Set<Decimal>();
		// 指定の処理日の会計情報から関連キーを作成する
		for (AccountAcount__c acc : accs) {
			// 処理日の会計情報を格納する
			accIdsSet.add(acc.Id);
			//accsMap.put(acc.Id, acc);
			
			if (acc.Relreserve__c == null) continue;
			// 該当会計と関連の予約インデックスID
			if (acc.Relreserve__r.LeadIndexRef__c != null) leadIdxIdsSet.add(acc.Relreserve__r.LeadIndexRef__c);
			
			// 関連の会計支払情報取得用キーを作成する
			String key = getGroupNokey( acc.Relreserve__r.LeadIndexRef__c, 
										acc.Relreserve__r.LeadIndexSubId__c, 
										acc.Relreserve__r.RoomGroupNo__c);
			if (!accsTranIsEmptyMap.containsKey(key)) accsTranIsEmptyMap.put(key, true);	// 明細なしはデイフォル値
			if (!acc.TranAccount__r.isEmpty()) {
				accsTranIsEmptyMap.put(key, false);
				accsTranIsExistMap.put(key, acc.Id);
			}
			relFilterkeySet.add(key);
			// 同じグループの検索条件を格納する
			if (acc.Relreserve__r.LeadIndexRef__c != null) leadIndexIdSet.add(acc.Relreserve__r.LeadIndexRef__c);
			if (acc.Relreserve__r.LeadIndexSubId__c != null) leadIndexSubIdSet.add(acc.Relreserve__r.LeadIndexSubId__c);
			if (acc.Relreserve__r.RoomGroupNo__c != null) leadGroupNoSet.add(acc.Relreserve__r.RoomGroupNo__c);
		}

		/***********************************
		* 上記会計に関連の予約金、後払い金額は全部取得する
		* 当日分の会計も含めする
		***********************************/
		// 関連の会計IDを格納する
		List<Id> relAccountIdsLst = new List<Id>();
		for (AccountAcount__c acc : [select id,Relreserve__r.LeadIndexRef__c ,Relreserve__r.LeadIndexSubId__c, Relreserve__r.RoomGroupNo__c
									,(	Select Field2__c, Field3__c, CardTypeLst__c, PayProductName__c,CouponTypeLst__c
										,Field20__c, Field19__c,OutSideAccount__c
		 								,PayProductRef__r.KanjoKamokuRef__r.KanjoHojocode__c
		 								,PayProductRef__r.KanjoKamokuRef__r.KanjocodeCode__c
		 								,PayProductRef__r.KanjoKamokuRef__r.DebitTaxKbn__c
		 								,PayProductRef__r.KanjoKamokuRef__r.CreditTaxKbn__c
		 								From TranTotalfromPay__r where (Field28__c != null AND Field28__c != 0) order by name 
		 							 ) 
									from AccountAcount__c 
									where 
											Relreserve__r.LeadIndexRef__c in :leadIndexIdSet
										And Relreserve__r.LeadIndexSubId__c in :leadIndexSubIdSet
										And Relreserve__r.RoomGroupNo__c in :leadGroupNoSet
										And Field39__c = :CommConst.ACC_TRADE_NORMAL // 正常な会計情報
									order By frs__r.Name
									]) {
			// 予約インデックス_予約インデックスSUB_グループNOでキー保存
			String key = getGroupNokey( acc.Relreserve__r.LeadIndexRef__c, 
										acc.Relreserve__r.LeadIndexSubId__c, 
										acc.Relreserve__r.RoomGroupNo__c);
			// 関係ないの会計は対象外になる
			if (!relFilterkeySet.contains(key)) continue;
			// 関連の全部の会計情報
			relAccountIdsLst.add(acc.id);
			// 関連会計情報も格納する
			//accsMap.put(acc.id, acc);
		}
		// 2020.01.21 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う） WSQ BEGIN
System.debug(loggingLevel.info,'gccInfo.isUseDayOutMode='+gccInfo.isUseDayOutMode);
		if(gccInfo.isUseDayOutMode){
			// 利用日により、出力データを事前処理を行う
			preSyncPaymentInfoByUseDate(relAccountIdsLst);
			return;
		}
		// 2020.01.21 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う） WSQ END
		//***********************************
		// 処理日「当日分」の関連の支払情報・支払明細情報をクリアする
		// 処理日以後の存在の支払明細もクリアを行う
		//***********************************
		// 現在の会計に紐付く支払明細は捜す、該当支払明細に紐付く支払情報の関連の売上日＞処理日の明細を削除する
		/*
		List<PaymentDetail__c> relPayDetails = [select id,PaymentInfoRef__c from PaymentDetail__c where AccountAcountRef__c in :accIdsSet];
		Set<Id> relPayIdsSet = new Set<Id>();
		for (PaymentDetail__c item : relPayDetails) { relPayIdsSet.add(item.PaymentInfoRef__c);}
		*/
		
		// 処理日の会計に関連の支払明細→支払情報→所属の支払明細は売上日＞処理日の明細は自動クリア（重複自動PCA出力するため）
		//delete [select id from PaymentDetail__c where PaymentInfoRef__c in :relPayIdsSet and AccountAcountRef__r.frs__r.Name > :gRsvName];
		// 同じ予約INDEXの支払明細に対して、関連の会計情報の売上計上日は未来日の場合、未来の支払明細として、クリアする
		delete [select id from PaymentDetail__c where PaymentInfoRef__r.LeadIndexRef__c in :leadIndexIdSet And  AccountAcountRef__r.frs__r.Name > :gRsvName];
		// 当自分の会計の会計明細を利用支払明細をクリアする[自分の会計を利用しる支払明細　OR　自分の会計支払で作成の支払情報に所属の支払明細の売上日は処理日が未来日の場合、削除する]
		delete [select id from PaymentDetail__c where AccountAcountRef__c in :accIdsSet or (PaymentInfoRef__r.AccountAcountRef__c in :accIdsSet And AccountAcountRef__r.frs__r.Name > :gRsvName)];
		// 当日分の既存の支払情報をクリアする[別日の支払情報はそのまま残り]
		delete [select id from PaymentInfo__c where AccountAcountRef__c in :accIdsSet and TTendRef__c = null and Tran1Ref__c = null];
		// 既存のゴミの支払情報
		List<PaymentInfo__c> errPayInfoLst = new List<PaymentInfo__c>();
		// 既存の支払情報	
		Map<String, PaymentInfo__c> existPaymentMap = new Map<String, PaymentInfo__c>();
		// 支払情報に新規、更新を行う
		for(PaymentInfo__c pay : [
			select id, Name,LeadIndexRef__c,AccountAcountRef__c,TTendRef__c,Tran1Ref__c,DepositAmount__c,ChildRenRsCount__c,PaymentType__c
			// 明細にリンクの会計
			,TTendRef__r.Field1__c
			,Tran1Ref__r.Field1__c
			// リンクの売上情報
			,AccountAcountRef__r.frs__r.Name
			// 関連グループ
			,AccountAcountRef__r.Relreserve__r.LeadIndexSubId__c
			,AccountAcountRef__r.Relreserve__r.RoomGroupNo__c
			From PaymentInfo__c 
			where 
			//LeadIndexRef__c in :leadIdxIdsSet
			AccountAcountRef__c in :relAccountIdsLst					// 関連の予約情報IDを格納する[同じ予約グループ]
			And (TTendRef__c != null Or Tran1Ref__c != null)]) {
				
			// 支払情報のリンクの会計と直接支払リンクの会計は一致しないと、ダミデータとして、削除対象になる
			if (pay.TTendRef__c != null && pay.TTendRef__r.Field1__c != pay.AccountAcountRef__c) {
				errPayInfoLst.add(pay);
				continue;
			} else if (pay.Tran1Ref__c != null && pay.Tran1Ref__r.Field1__c != pay.AccountAcountRef__c) {
				errPayInfoLst.add(pay);
				continue;
			}
			/*
			String key =	pay.LeadIndexRef__c 
						+ '_' + pay.AccountAcountRef__c
						+ '_' + CommUtils.nullToBlank(pay.TTendRef__c)
						+ '_' + CommUtils.nullToBlank(pay.Tran1Ref__c);*/
			String key = getPaymentKey(pay.LeadIndexRef__c, pay.AccountAcountRef__c, pay.TTendRef__c, pay.Tran1Ref__c);
			// 既存の支払情報を格納する
			existPaymentMap.put(key, pay);
		}
		// 設定エラーの支払情報をクリアする
		if (!errPayInfoLst.isEmpty()) delete errPayInfoLst;
		
		// 予約インデックスから既存の支払情報を取得する
		Map<String, PaymentInfo__c> relPaymentMap = new Map<String, PaymentInfo__c>();
		Map<Id, TTend__c> arRelTtendMap = new Map<Id, TTend__c>();
		// 関連の既存の【会計支払】情報を全部取得を行う
		List<TTend__c> ttends = [select Id, Name, Field19__c, Field2__c,Field20__c, Field1__c,Field29__c,
									Field1__r.Relreserve__r.LeadIndexRef__c,
									Field1__r.Relreserve__r.LeadIndexSubId__c,
									Field1__r.Relreserve__r.RoomGroupNo__c,
									Field1__r.CouponReturnFlg__c,
									Field1__r.frs__r.Name,
									PaymentType__c,
									RelAccount__c
				From TTend__c 
				where 
					Field1__c in :relAccountIdsLst
					//Field1__r.Relreserve__r.LeadIndexRef__c in :leadIdxIdsSet 
					//And Field1__c in : accIdsSet
					//And OutSideAccount__c = 1
					And (Field28__c != null AND Field28__c != 0)		// 預かり金額が存在
					// 会計支払商品はNULL　OR　該当会計支払商品の処理種別は「前受付金」以外の場合
					And (PayProductRef__c = null Or PayProductRef__r.ActionType__c != :PROD_ACTION_TYPE_AR)
				Order by Field1__r.frs__r.Name, RowNo__c, Name
		];

		for (TTend__c ttend : ttends) {
			/*
			// 前受金の場合、情報を格納して、次の処理を行う
			if (ttend.PayProductRef__r.ActionType__c == PROD_ACTION_TYPE_AR) {
				if (ttend.ArTranId__c != null) arRelTtendMap.put(ttend.ArTranId__c, ttend);
				continue;
			}*/
			Boolean isDespoist = false;
			/*
			String key = 	ttend.Field1__r.Relreserve__r.LeadIndexRef__c 
						+ '_' + ttend.Field1__c
						+ '_' + ttend.Id
						+ '_';*/
			String key = getPaymentKey(ttend.Field1__r.Relreserve__r.LeadIndexRef__c, ttend.Field1__c , ttend.Id, null);
			// 該当会計の支払明細のみ存在、関連の会計明細がなかった場合、予約金として、支払情報を登録を行う
			// 該当会計支払既存
			if (existPaymentMap.containsKey(key)) {
				// 該当会計支払の子明細数を取得
				PaymentInfo__c pay = existPaymentMap.get(key);
				// 子データがない場合
				if (pay.ChildRenRsCount__c == 0) {
					// 該当処理日に、同じグループの会計に、会計明細が存在するがどうチェックを行う
					String accKey = getGroupNokey( 	ttend.Field1__r.Relreserve__r.LeadIndexRef__c, 
													ttend.Field1__r.Relreserve__r.LeadIndexSubId__c, 
													ttend.Field1__r.Relreserve__r.RoomGroupNo__c);
					// 当日に処理する会計明細が非存在する
					if (accsTranIsEmptyMap.containsKey(accKey)) {
						if (accsTranIsEmptyMap.get(accKey)) {
							isDespoist = true;
						}
					}
				}
			} else {
				// 該当処理日に、同じグループの会計に、会計明細が存在するがどうチェックを行う
				String accKey = getGroupNokey( 	ttend.Field1__r.Relreserve__r.LeadIndexRef__c, 
												ttend.Field1__r.Relreserve__r.LeadIndexSubId__c, 
												ttend.Field1__r.Relreserve__r.RoomGroupNo__c);
				// 処理日に会計明細が非存在する場合、予約金として、支払情報を作成する
				if (accsTranIsEmptyMap.containsKey(accKey)) {
					if (accsTranIsEmptyMap.get(accKey)) {
						isDespoist = true;
					}
				}
			}

			Decimal payMentAmount = CommUtils.nullToZero(ttend.Field19__c);
			if (payMentAmount == 0) payMentAmount = CommUtils.nullToZero(ttend.Field20__c);	// 事前予約金の場合、該当支払情報は個別出力を行う

			// （クポーン　AND　クポーン返金なし）　OR　（割引）
			if(ttend.Field2__c == CommConst.MEDIA_TYPE_CD_12 || (ttend.Field2__c == CommConst.MEDIA_TYPE_CD_11 && !ttend.Field1__r.CouponReturnFlg__c)){
				// 予約金以外の場合、支払い金額で設定を行う
				if (!isDespoist) payMentAmount = CommUtils.nullToZero(ttend.Field20__c);
				//payMentAmount = CommUtils.nullToZero(ttend.Field20__c);
			}

			//relPaymentMap.put(key, new PaymentInfo__c(
			PaymentInfo__c tmpPaymentInfo = new PaymentInfo__c(
				 LeadIndexRef__c		= ttend.Field1__r.Relreserve__r.LeadIndexRef__c
				,AccountAcountRef__c	= ttend.Field1__c
				,TTendRef__c			= ttend.Id
				,DepositAmount__c		= payMentAmount	// 預かり金額
				,MediaTypeCode__c		= ttend.Field2__c
			);
			// 支払金額は０の場合、予約金として、情報設定を行う
			if (isDespoist) {
				tmpPaymentInfo.PaymentType__c = PAY_TYPE_DESPOIST;
			} else {
				// 現在の会計支払は当日に処理されている会計支払場合、タイプは普通に変更を行う
				if (ttend.RelAccount__c == Id.valueOf(gRsvAccoutId) || ttend.Field1__r.frs__r.Name > gRsvName) {
					tmpPaymentInfo.PaymentType__c = PAY_TYPE_NORMAL;
				}
			}
			tmpPaymentInfo.AccountAcountRef__r = ttend.Field1__r;
			tmpPaymentInfo.AccountAcountRef__r.Relreserve__r = ttend.Field1__r.Relreserve__r;
			relPaymentMap.put(key, tmpPaymentInfo);
		}
		// 関連の会計支払と【会計明細】に設定されている【前受金】明細は支払情報に反映を行う
		List<Tran1__c> trans  = [select Id, Name, Field1__c,Field41__c,PaymentType__c,
									RelAccount__c,
									Field1__r.frs__r.Name,
									Field1__r.Relreserve__r.LeadIndexRef__c,
									Field1__r.Relreserve__r.LeadIndexSubId__c,
									Field1__r.Relreserve__r.RoomGroupNo__c
				From Tran1__c
				Where 
					Field1__c in :relAccountIdsLst
					//Field1__r.Relreserve__r.LeadIndexRef__c in :leadIdxIdsSet 
					//And Field1__c in : accIdsSet
					And Accountoutside__c = 1
					And ActionType__c = :PROD_ACTION_TYPE_AR 
				Order by Field1__r.frs__r.Name, RowNo__c, Name
					];
		for (Tran1__c tran : trans) {

			/*
			String key = 	tran.Field1__r.Relreserve__r.LeadIndexRef__c 
						+ '_' + tran.Field1__c
						+ '_' 
						+ '_' + tran.Id;*/
			String key = getPaymentKey(tran.Field1__r.Relreserve__r.LeadIndexRef__c, tran.Field1__c , null, tran.Id);
			
			Boolean isDespoist = false;
			// 該当会計の支払明細のみ存在、関連の会計明細がなかった場合、予約金として、支払情報を登録を行う
			// 該当会計支払既存
			if (existPaymentMap.containsKey(key)) {
				// 該当会計支払の子明細数を取得
				PaymentInfo__c pay = existPaymentMap.get(key);
				// 子データがない場合
				if (pay.ChildRenRsCount__c == 0) {
					// 該当処理日に、同じグループの会計に、会計明細が存在するがどうチェックを行う
					String accKey = getGroupNokey( 	tran.Field1__r.Relreserve__r.LeadIndexRef__c, 
													tran.Field1__r.Relreserve__r.LeadIndexSubId__c, 
													tran.Field1__r.Relreserve__r.RoomGroupNo__c);
					// 関連会計が存在する場合
					if (accsTranIsEmptyMap.containsKey(accKey)) {
						if (accsTranIsEmptyMap.get(accKey)) {
							isDespoist = true;
						}
					}
				}
			} else {
				// 該当処理日に、同じグループの会計に、会計明細が存在するがどうチェックを行う
				String accKey = getGroupNokey( 	tran.Field1__r.Relreserve__r.LeadIndexRef__c, 
												tran.Field1__r.Relreserve__r.LeadIndexSubId__c, 
												tran.Field1__r.Relreserve__r.RoomGroupNo__c);
				// 関連会計が存在する場合
				if (accsTranIsEmptyMap.containsKey(accKey)) {
					if (accsTranIsEmptyMap.get(accKey)) {
						isDespoist = true;
					}
				}
			}
			//relPaymentMap.put(key, new PaymentInfo__c(
			PaymentInfo__c tmpPaymentInfo = new PaymentInfo__c(
				 LeadIndexRef__c		= tran.Field1__r.Relreserve__r.LeadIndexRef__c
				,AccountAcountRef__c	= tran.Field1__c
				,Tran1Ref__c			= tran.Id
				,DepositAmount__c		= CommUtils.nullToZero(tran.Field41__c)
				//,MediaTypeCode__c		= ttend.Field2__c【前受付金の場合、非設定[支払情報自動設定の場合、割引、クポーン優先減算、その後、順番で減算する]】
			);
			// 明細は返金するがどうかチェックを行う
			//Boolean isRefundFlg  = false;
			if (BillSimpleHelp.isRefundItem(tran.PaymentType__c)) {
				//isRefundFlg = true;
				tmpPaymentInfo.PaymentType__c = PAY_TYPE_REFUND;
			} 
			// 前受金は予約金として、登録する場合
			else if (isDespoist) {
				tmpPaymentInfo.PaymentType__c = PAY_TYPE_DESPOIST;
			} 
			// 当日の処理情報の場合、普通のフラグを設定する
			else {
				// 現在の会計支払は当日に処理されている会計支払場合、タイプは普通に変更を行う
				// 該当支払メデイアの売上日は未来日の場合、普通のタイプに変更を行う
				if (tran.RelAccount__c == Id.valueOf(gRsvAccoutId) || tran.Field1__r.frs__r.Name > gRsvName) {
					tmpPaymentInfo.PaymentType__c = PAY_TYPE_NORMAL;
				}
			}

			tmpPaymentInfo.AccountAcountRef__r = tran.Field1__r;
			tmpPaymentInfo.AccountAcountRef__r.Relreserve__r = tran.Field1__r.Relreserve__r;
			relPaymentMap.put(key, tmpPaymentInfo);
		}

		// 関連の支払情報を再リンクする
		List<PaymentInfo__c> upsertPayInfos = new List<PaymentInfo__c>();
		for (String key : relPaymentMap.keySet()) {
			// 該当支払情報は既に存在する場合
			if (existPaymentMap.containsKey(key)) {
				PaymentInfo__c existPay = existPaymentMap.get(key);
				// 今回処理の支払情報は予約金関連チェックを行う
				// 既存の支払情報の明細件数をチェックする
				// 既存の支払情報の預かり金額を変更されている場合、金額を更新を行う
				if (existPay.DepositAmount__c != relPaymentMap.get(key).DepositAmount__c ||
					(
					// Default：普通の自動設定がありますので、
					existPay.PaymentType__c != relPaymentMap.get(key).PaymentType__c &&
					!CommUtils.isBlank(relPaymentMap.get(key).PaymentType__c) 
					) ) {

					existPay.DepositAmount__c = relPaymentMap.get(key).DepositAmount__c;
					if (!CommUtils.isBlank(relPaymentMap.get(key).PaymentType__c)) {
						existPay.PaymentType__c = relPaymentMap.get(key).PaymentType__c;
					}
					upsertPayInfos.add(existPay);
				}
			} else {

				// 支払情報を新規作成を行う
				upsertPayInfos.add(relPaymentMap.get(key));
			}
		}
		// 支払情報を新規・更新を行う
		if (!upsertPayInfos.isEmpty()) upsert upsertPayInfos;

		// ********************************************
		// 会計明細から、PCA連携用利用明細情報を作成する
		// ********************************************
		// Map<Id, List<PaymentInfo__c>>
		Map<String, List<PaymentInfo>> discountPayMap = new Map<String, List<PaymentInfo>>();
		Map<String, List<PaymentInfo>> coponPayMap = new Map<String, List<PaymentInfo>>();
		Map<String, List<PaymentInfo>> normalPayMap = new Map<String, List<PaymentInfo>>();
		Map<String, List<PaymentInfo>> depositPayMap = new Map<String, List<PaymentInfo>>();	// 予約金支払情報を格納する
		Map<String, List<PaymentInfo>> refundPayMap = new Map<String, List<PaymentInfo>>();		// 返金支払情報を格納する
		
		// 当日分の支払情報に所属する支払IDを格納する
		map<Id, PaymentInfo__c> todaynoPayMap = new map<Id, PaymentInfo__c>();
		// 新規作成の支払明細を格納する
		List<PaymentDetail__c> insertDetail = new List<PaymentDetail__c>();
		// **************************
		// 既存の支払情報を取得する
		// 当日に支払情報により、新規作成の支払情報も含めて、関連の支払情報を全部取得を行う
		// **************************
		for(PaymentInfo__c pay : [
			select id, Name,LeadIndexRef__c,AccountAcountRef__c,TTendRef__c,Tran1Ref__c,DepositAmount__c,RemainingMoney__c,MediaTypeCode__c,ChildRenRsCount__c
			// 同じ予約インデックスID,SUBインデックスID、グループNO
			,AccountAcountRef__r.Relreserve__r.LeadIndexSubId__c
			,AccountAcountRef__r.Relreserve__r.RoomGroupNo__c
			,PaymentType__c
			// 会計支払
			,TTendRef__r.Field29__c
			,AccountAcountRef__r.frs__c
			From PaymentInfo__c 
			where //LeadIndexRef__c in :leadIdxIdsSet
				AccountAcountRef__c in :relAccountIdsLst					// 関連の予約情報IDを格納する[同じ予約グループ]
			And ( RemainingMoney__c > 0 OR PaymentType__c = :PAY_TYPE_REFUND)	// 残金あり　OR　返金の支払情報を取得する
			And (TTendRef__c != null Or Tran1Ref__c != null)
			order by AccountAcountRef__r.frs__r.Name, Name
			]) {
			// 売上日により、当日の支払情報を格納すうる
			if (pay.AccountAcountRef__r.frs__c == gRsvAccoutId) todaynoPayMap.put(pay.Id, pay);
			//
			//Id leadIdxId = pay.LeadIndexRef__c;
			// 予約インデックス_予約インデックスSUB_グループNOでキー保存
			/*
			String key = pay.LeadIndexRef__c 
						+ '_' 
						+ pay.AccountAcountRef__r.Relreserve__r.LeadIndexSubId__c 
						+ '_' 
						+ CommUtils.nullToBlank(pay.AccountAcountRef__r.Relreserve__r.RoomGroupNo__c);*/
			String key = getGroupNokey( pay.LeadIndexRef__c, 
										pay.AccountAcountRef__r.Relreserve__r.LeadIndexSubId__c, 
										pay.AccountAcountRef__r.Relreserve__r.RoomGroupNo__c);

			// 予約金の場合
			if (pay.PaymentType__c == PAY_TYPE_DESPOIST) {
				if (!depositPayMap.containsKey(key)) depositPayMap.put(key, new List<PaymentInfo>());
				depositPayMap.get(key).add(new PaymentInfo(pay));
			} 
			// 返金の支払明細
			else if (pay.PaymentType__c == PAY_TYPE_REFUND) {
				if (!refundPayMap.containsKey(key)) refundPayMap.put(key, new List<PaymentInfo>());
				refundPayMap.get(key).add(new PaymentInfo(pay));
				continue;
			}
			// 割引
			if (pay.MediaTypeCode__c == CommConst.MEDIA_TYPE_CD_12) {
				if (!discountPayMap.containsKey(key)) discountPayMap.put(key, new List<PaymentInfo>());
				discountPayMap.get(key).add(new PaymentInfo(pay));
			} else if (pay.MediaTypeCode__c == CommConst.MEDIA_TYPE_CD_11) {
				if (!coponPayMap.containsKey(key)) coponPayMap.put(key, new List<PaymentInfo>());
				coponPayMap.get(key).add(new PaymentInfo(pay));
			} else {
				if (!normalPayMap.containsKey(key)) normalPayMap.put(key, new List<PaymentInfo>());
				normalPayMap.get(key).add(new PaymentInfo(pay));
			}
		}
		// 新規作成の支払明細を格納する
		//List<PaymentDetail__c> insertDetail = new List<PaymentDetail__c>();
		// 残金ありの支払情報の残金格納変数初期化設定
		for (List<PaymentInfo> rst : discountPayMap.values()) resetPayRemaindMonty(rst);
		for (List<PaymentInfo> rst : coponPayMap.values()) resetPayRemaindMonty(rst);
		for (List<PaymentInfo> rst : normalPayMap.values()) resetPayRemaindMonty(rst);
		
//System.debug(loggingLevel.INFO, 'discountPayMap::' + discountPayMap);
//System.debug(loggingLevel.INFO, 'coponPayMap::' + coponPayMap);
//System.debug(loggingLevel.INFO, 'normalPayMap::' + normalPayMap);
//System.debug(loggingLevel.INFO, 'depositPayMap::' + depositPayMap);
//System.debug(loggingLevel.INFO, 'refundPayMap::' + refundPayMap);

		// 関連支払情報を自動作成を行う
		for (AccountAcount__c acc : accs) {
			//Id leadIdxId = acc.Relreserve__r.LeadIndexRef__c;
			// 会計明細から支払明細情報を自動作成を行う
			if (acc.Relreserve__r.LeadIndexRef__c == null) continue;
			// 予約インデックス_予約インデックスSUB_グループNOでキー保存
			/*
			String key = acc.Relreserve__r.LeadIndexRef__c 
						+ '_' 
						+ acc.Relreserve__r.LeadIndexSubId__c 
						+ '_' 
						+ CommUtils.nullToBlank(acc.Relreserve__r.RoomGroupNo__c);*/
			String key = getGroupNokey( acc.Relreserve__r.LeadIndexRef__c, 
										acc.Relreserve__r.LeadIndexSubId__c, 
										acc.Relreserve__r.RoomGroupNo__c);
			//if (leadIdxId != null) {
				// 関連の支払情報が存在チェック
				Decimal usedAmount = 0;
				// 会計明細情報がなかったの場合、次の処理を行う
				// 返金存在の場合
				if (refundPayMap.containsKey(key)) {
					for (PaymentInfo pay : refundPayMap.get(key)) {
						// 該当予約情報は既に明細は１件あり場合、該当明細は既に出力済ので、再出力用明細を作成を行わない
						if (pay.childRenRsCount == 0) {
							// 予約金は入金情報を作成する
							PaymentDetail__c newPay = new PaymentDetail__c(
								 PaymentInfoRef__c = pay.s.Id
								,AccountAcountRef__c = pay.s.AccountAcountRef__c
								,DepositAmount__c = pay.s.DepositAmount__c
								,UsedAmount__c = pay.s.DepositAmount__c
							);
							insertDetail.add(newPay);
							pay.childRenRsCount++;
						}
					}
				}
				
				// 予約金情報を出力する
				//if (acc.TranAccount__r.isEmpty()) {
				// 予約金が存在チェックを行う
				if (depositPayMap.containsKey(key)) {
					for (PaymentInfo pay : depositPayMap.get(key)) {
						// 該当支払情報は予約金するがどうか、チェックする
						//Boolean isDespoist = false;
						
						// 予約金単独な処理じゃない場合、次の支払情報を移動する
						//if (!isDespoist) continue;
						// 該当予約情報は既に明細は１件あり場合、該当明細は既に出力済ので、再出力用明細を作成を行わない
						if (pay.childRenRsCount == 0) {
							// 予約金は入金情報を作成する
							PaymentDetail__c newPay = new PaymentDetail__c(
								 PaymentInfoRef__c = pay.s.Id
								,AccountAcountRef__c = pay.s.AccountAcountRef__c
								,DepositAmount__c = pay.s.DepositAmount__c
								,UsedAmount__c = 0
							);
							insertDetail.add(newPay);
							pay.childRenRsCount++;
						} else {
							continue;
						}
					}
					//continue;
				}
				//}
				
				// 会計支払場合存在チェック
				for (Tran1__c tran : acc.TranAccount__r) {
					// 該当会計の利用総金額を合計する
					usedAmount += tran.Field41__c;
				}
				Decimal remaindPayMoney = usedAmount;

				// 利用金額は０以上の場合
				if (usedAmount > 0) {
					// 割引情報存在チェック
					List<PaymentInfo> disPayLst = discountPayMap.get(key);
					// 割引から支払情報存在する場合
					if (disPayLst != null) {
						remaindPayMoney = generalPaymentDetail(remaindPayMoney, acc, disPayLst, insertDetail);
					} // 割引情報から支払情報作成を行う
					if (remaindPayMoney > 0) {
						List<PaymentInfo> coponPayLst = coponPayMap.get(key);
						if (coponPayLst != null) {
							remaindPayMoney = generalPaymentDetail(remaindPayMoney, acc, coponPayLst, insertDetail);
						}
					} // クポーン関連支払明細情報作成
					if (remaindPayMoney > 0) {
						List<PaymentInfo> norPayLst = normalPayMap.get(key);
						if (norPayLst != null) {
							remaindPayMoney = generalPaymentDetail(remaindPayMoney, acc, norPayLst, insertDetail);
						}
					} // 普通の支払情報から支払明細作成を行う
				}
			//}
		}
		if (!insertDetail.isEmpty()) insert insertDetail;
		
		// 当日に支払メデイアは未利用されている場合、該当支払メデイアは前受金として、明細を作成する
		// 預かり金額は全額、利用金額は０円で明細作成を行う
		List<PaymentInfo__c> noPayItems = [select id,ChildRenRsCount__c
											 from PaymentInfo__c where id in :todaynoPayMap.keySet() and ChildRenRsCount__c > 0];
		for (PaymentInfo__c pay : noPayItems) {
			// 該当支払情報は既に利用されている場合
			if (todaynoPayMap.containsKey(pay.id)) todaynoPayMap.remove(pay.id);
		}
		// 支払明細を作成する[該当支払情報は未利用の場合]
		List<PaymentDetail__c> insertDetailPlus = new List<PaymentDetail__c>();
		for (PaymentInfo__c pay : todaynoPayMap.values()) {
			// 同じKEYに、会計明細存在の会計IDを探して、自動設定を行う
			String key = getGroupNokey( pay.LeadIndexRef__c, 
										pay.AccountAcountRef__r.Relreserve__r.LeadIndexSubId__c, 
										pay.AccountAcountRef__r.Relreserve__r.RoomGroupNo__c);
			// 当日に会計明細が存在する場合、
			if (accsTranIsExistMap.containsKey(key)) {
				// 予約金は入金情報を作成する
				PaymentDetail__c newPay = new PaymentDetail__c(
					 PaymentInfoRef__c = pay.Id
					,AccountAcountRef__c = accsTranIsExistMap.get(key)
					,DepositAmount__c = pay.DepositAmount__c
					,UsedAmount__c = 0
				);
				insertDetailPlus.add(newPay);
			}
		}
		if (!insertDetailPlus.isEmpty()) insert insertDetailPlus;
	}
	/*
	* 2020.01.21 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う）
	*/
	private void preSyncPaymentInfoByUseDate(List<Id> relAccountIdsLst) {
		// 
		// 会計IDにより、支払明細情報
		// map<groupkey, map<売上計上日名,会計支払リスト>
		map<string,map<string,list<TTend__c>>> payTtendMap = new map<string, map<string,list<TTend__c>>>();//会計支払
		map<string,list<string>> payTtendRsvMap = new map<string, list<string>>();//会計支払のキーと売上計上日名
		// 関連データを削除する
		delete [select id from PaymentInfo__c where AccountAcountRef__c	 in :relAccountIdsLst];
		
		// 関連の既存の【会計支払】情報を全部取得を行う
		List<TTend__c> ttends = [select Id, Name, Field19__c, Field2__c,Field20__c, Field1__c,Field29__c,Field21__c,
									Field1__r.Relreserve__r.LeadIndexRef__c,
									Field1__r.Relreserve__r.LeadIndexSubId__c,
									Field1__r.Relreserve__r.RoomGroupNo__c,
									Field1__r.CouponReturnFlg__c,
									Field1__r.frs__r.Name,
									PaymentType__c,
									RelAccount__c
				From TTend__c 
				where 
					Field1__c in :relAccountIdsLst
					And (Field28__c != null AND Field28__c != 0)		// 預かり金額が存在
					// 会計支払商品はNULL　OR　該当会計支払商品の処理種別は「前受付金」以外の場合
					//And (PayProductRef__c = null Or PayProductRef__r.ActionType__c != :PROD_ACTION_TYPE_AR)
				order by Field1__r.frs__r.Name, RowNo__c, Name//売上計上日順格納する
		];
		for (TTend__c ttend : ttends) {
			//String key = getPaymentKey(ttend.Field1__r.Relreserve__r.LeadIndexRef__c, ttend.Field1__c , ttend.Id, null);
			// 該当処理日に、同じグループの会計に、会計明細が存在するがどうチェックを行う
			String key = getGroupNokey( 	ttend.Field1__r.Relreserve__r.LeadIndexRef__c, 
											ttend.Field1__r.Relreserve__r.LeadIndexSubId__c, 
											ttend.Field1__r.Relreserve__r.RoomGroupNo__c);
			String rsvName = ttend.Field1__r.frs__r.Name;//売上計上日名
			if (!payTtendMap.containsKey(key)) payTtendMap.put(key, new map<string,list<TTend__c>>());
			if (!payTtendRsvMap.containsKey(key)) payTtendRsvMap.put(key, new list<string>());
			map<string,list<TTend__c>> wkTtendMap = payTtendMap.get(key);
			if (!wkTtendMap.containsKey(rsvName)) {
				wkTtendMap.put(rsvName, new list<TTend__c>());
				payTtendRsvMap.get(key).add(rsvName);//該当グループの売上計上日（昇順）格納する
			}
			wkTtendMap.get(rsvName).add(ttend);
		}
		// map<groupkey, map<売上計上日名,会計明細リスト>
		map<string,map<string,list<Tran1__c>>> useTtranMap = new map<string, map<string,list<Tran1__c>>>();//会計明細
		map<string,list<string>> useTtranRsvMap = new map<string, list<string>>();//会計明細のキーと売上計上日名
		// 関連の会計支払と【会計明細】に設定されている【前受金】明細は支払情報に反映を行う
		List<Tran1__c> trans  = [select Id, Name, Field1__c,Field41__c,PaymentType__c,GoukeinoneTax__c,
									RelAccount__c,
									Field1__r.frs__r.Name,
									Field1__r.Relreserve__r.LeadIndexRef__c,
									Field1__r.Relreserve__r.LeadIndexSubId__c,
									Field1__r.Relreserve__r.RoomGroupNo__c
				From Tran1__c
				Where 
					Field1__c in :relAccountIdsLst
					// 商品種別はプランのBreakDown項目と普通の会計明細
					and ( ActionType__c != :PROD_ACTION_TYPE_PL And ActionType__c != :PROD_ACTION_TYPE_AR )
		 			// 有効な明細　OR　親が存在 AND　親は有効な明細
		 			// 2017/05/33 非表示の明細データでも出力対象に変更する BEGIN
					and ( ( ParentTran1Ref__c = null And Accountoutside__c = 1) OR (ParentTran1Ref__c != null And ParentTran1Ref__r.Accountoutside__c = 1 ) )	
				order by Field1__r.frs__r.Name, RowNo__c, Name//売上計上日順格納する
		];
		for (Tran1__c tran : trans) {
			// 2015/12/04 利用金額は０の場合、明細情報を出力なし機能対応
			//if (!gccInfo.isOutputPriceZero && CommUtils.nullToZero(tran.GoukeinoneTax__c) == 0) continue;
			
			// 該当処理日に、同じグループの会計に、会計明細が存在するがどうチェックを行う
			String key = getGroupNokey( 	tran.Field1__r.Relreserve__r.LeadIndexRef__c, 
											tran.Field1__r.Relreserve__r.LeadIndexSubId__c, 
											tran.Field1__r.Relreserve__r.RoomGroupNo__c);
			String rsvName = tran.Field1__r.frs__r.Name;//売上計上日名
			if (!useTtranMap.containsKey(key)) useTtranMap.put(key, new map<string,list<Tran1__c>>());
			if (!useTtranRsvMap.containsKey(key)) useTtranRsvMap.put(key, new list<string>());
			map<string,list<Tran1__c>> wkTranMap = useTtranMap.get(key);
			if (!wkTranMap.containsKey(rsvName)) {
				wkTranMap.put(rsvName, new list<Tran1__c>());
				useTtranRsvMap.get(key).add(rsvName);//該当グループの売上計上日（昇順）格納する
			}
			wkTranMap.get(rsvName).add(tran);
		}
//system.debug(loggingLevel.info, 'payTtendMap='+payTtendMap);
//system.debug(loggingLevel.info, 'payTtendRsvMap='+payTtendRsvMap);
//system.debug(loggingLevel.info, 'useTtranMap='+useTtranMap);
//system.debug(loggingLevel.info, 'useTtranRsvMap='+useTtranRsvMap);
		list<PaymentInfo__c> createPaymentLst = new List<PaymentInfo__c>();
		// 会計明細により、支払明細を自動分割する　
		for (String groupKey : useTtranRsvMap.keyset()) {
			// 売上計上日リストを取得する
			list<string> rsvNameLst = useTtranRsvMap.get(groupKey);
//system.debug(loggingLevel.info, 'rsvNameLst='+rsvNameLst);
//system.debug(loggingLevel.info, 'groupKey='+groupKey);
			// 該当グループに、売上計上日別会計明細を取得する
			map<string,list<Tran1__c>> wkTranMap = useTtranMap.get(groupKey);
			// 該当グループの支払売上計上情報
			list<string> ttendRsvNameList = payTtendRsvMap.get(groupKey);
			if (ttendRsvNameList == null) ttendRsvNameList = new list<string>();
			map<string,list<TTend__c>> wkTtendMap = payTtendMap.get(groupKey);
			if (wkTtendMap == null) wkTtendMap = new map<string,list<TTend__c>>();
			
			list<PaymentInfo__c> payInfoLst = new list<PaymentInfo__c>();
			// 
			//for (String rsvName : rsvNameLst) {
			for (Integer i = 0; i<rsvNameLst.size(); i++) { 
				String preRsvName = (i == 0 ? '' : rsvNameLst[i-1]);
				String rsvName = rsvNameLst[i];
				list<Tran1__c> wkTrans = wkTranMap.get(rsvName);
//system.debug(loggingLevel.info, 'preRsvName[1]='+preRsvName);
//system.debug(loggingLevel.info, 'rsvName[1]='+rsvName);
//system.debug(loggingLevel.info, 'wkTrans[1]='+wkTrans);
				// 関連リストを格納する
				//payInfoLst.addAll(createPayInfo(rsvName, preRsvName, wkTrans, ttendRsvNameList, wkTtendMap, payInfoLst));
				list<PaymentInfo__c> wkpayInfoLst = createPayInfo(rsvName, preRsvName, wkTrans, ttendRsvNameList, wkTtendMap, payInfoLst);
//system.debug(loggingLevel.info, 'wkpayInfoLst='+wkpayInfoLst);
				payInfoLst.addAll(wkpayInfoLst);
//system.debug(loggingLevel.info, 'payInfoLst='+payInfoLst);
			}
			createPaymentLst.addAll(payInfoLst);
		}
		if (!createPaymentLst.isEmpty()) insert createPaymentLst;
		
		list<PaymentDetail__c> payDetailLst = new list<PaymentDetail__c>();
		for (PaymentInfo__c pay : createPaymentLst) {
			PaymentDetail__c payItem = new PaymentDetail__c(
				AccountAcountRef__c = pay.AccountAcountRef__c,
				PaymentInfoRef__c = pay.Id,
				DepositAmount__c = pay.DepositAmount__c,
				UsedAmount__c = (pay.DepositAmount__c - pay.RemainingMoney2__c)
			);
			payDetailLst.add(payItem);
		}
		if (!payDetailLst.isEmpty()) insert payDetailLst;
	}
	private list<PaymentInfo__c> createPayInfo(	String curRsvName, 
											   	String preRsvName,
												list<Tran1__c> wkTrans, 
												list<string> ttendRsvNameList,
												map<string,list<TTend__c>> wkTtendMap,
												list<PaymentInfo__c> payInfoLst) {
		//未支払金額
		Decimal remaindAmount = 0;
		// 該当会計関連の会計明細の利用金額を合計する
		for (Tran1__c ttran : wkTrans) remaindAmount += CommUtils.nullToZero(ttran.Field41__c);
system.debug(loggingLevel.info, '************************='+remaindAmount);
system.debug(loggingLevel.info, 'ttendRsvNameList='+ttendRsvNameList);
		list<PaymentInfo__c> rsLst = new list<PaymentInfo__c>();
		// 2020/09/15 連泊の支払を入れた際の挙動修正2 WSQ BEGIN
		// ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★　
		// 処理日は該当処理中の売上計上日以後の場合、続いて処理不要
		if (curRsvName.compareTo(gRsvName) > 0 ) return rsLst;
		// 該当部屋にN泊の売上計上日リスト
		// 2020/09/15 連泊の支払を入れた際の挙動修正2 WSQ END
		for (string rsv : ttendRsvNameList) {
			// 範囲内の会計支払の売上計上日を取得する
//system.debug(loggingLevel.info, 'rsv='+rsv);
//system.debug(loggingLevel.info, 'curRsvName='+curRsvName);
//system.debug(loggingLevel.info, 'preRsvName='+preRsvName);
//system.debug(loggingLevel.info, 'preRsvName.compareTo(rsv) < 0 && curRsvName.compareTo(rsv) >= 0='+(preRsvName.compareTo(rsv) < 0 && curRsvName.compareTo(rsv) >= 0));	
			if (preRsvName.compareTo(rsv) < 0 && curRsvName.compareTo(rsv) >= 0) {
				list<TTend__c> wktendLst = wkTtendMap.get(rsv);
				for (TTend__c ttend : wktendLst) {
					// 利用金額を計算する
					Decimal reciveAmount = Commutils.nullToZero(ttend.Field19__c);//預かり金額
					Decimal paymentAmount = Commutils.nullToZero(ttend.Field20__c);//支払　金額
					Decimal changeAmount = CommUtils.nullToZero(ttend.Field21__c );//釣銭（差額）金額
					String paymentType = PAY_TYPE_NORMAL;//通常
					// 該当支払明細の残金を計算する
					Decimal curRemaindAmount = (remaindAmount > paymentAmount ? 0 : (paymentAmount - remaindAmount));
					// 返金場合
					if (BillSimpleHelp.isRefundItem(ttend.PaymentType__c)) {
						curRemaindAmount = 0;
						paymentAmount = 0;
						paymentType = PAY_TYPE_REFUND;
					}
					PaymentInfo__c tmpPaymentInfo = new PaymentInfo__c(
						 LeadIndexRef__c		= ttend.Field1__r.Relreserve__r.LeadIndexRef__c
						,AccountAcountRef__c	= ttend.Field1__c
						,TTendRef__c			= ttend.Id
						,DepositAmount__c		= reciveAmount
						,MediaTypeCode__c		= ttend.Field2__c
						,RemainingMoney2__c		= (changeAmount > 0 ? changeAmount : curRemaindAmount)//未利用の残金
						,RemainingMoney3__c		= (changeAmount > 0 ? changeAmount : curRemaindAmount)//未利用の残金
						,PaymentType__c 		= paymentType
						,SalesDateStr__c		= rsv
					);
//system.debug(loggingLevel.info, 'remaindAmount='+remaindAmount);
//system.debug(loggingLevel.info, 'paymentAmount='+paymentAmount);
					rsLst.add(tmpPaymentInfo);
					// 0円以下の場合、未支払金額は０に設定する
					remaindAmount = remaindAmount - paymentAmount;
//system.debug(loggingLevel.info, 'remaindAmount='+remaindAmount);
					if (remaindAmount <= 0) remaindAmount = 0;
				}
			}
		}
		// 上記処理で未支払金額が存在場合、前日の支払リストに残金が存在チエックを行う
		// 2020/09/15 連泊の支払を入れた際の挙動修正2 WSQ BEGIN
		// 相殺された売掛金の合計金額を集計する
		Decimal urikakeAmout = 0;
		for (PaymentInfo__c pay : payInfoLst) {
			if(pay.SalesDateStr__c >= gRsvName) break;
			if(pay.ImgDataFlg__c != true || pay.MediaTypeCode__c != CommConst.MEDIA_TYPE_CD_03 ) continue;//売掛金以外の場合、処理不要
			// 売掛金額(未払金額)存在場合
			Decimal keijyoAmount = pay.DepositAmount__c - CommUtils.nullToZero(pay.OffsetMoney__c);
			if (keijyoAmount <= 0) continue;
			// 売掛金額合計する
			urikakeAmout += keijyoAmount;
		}
system.debug(loggingLevel.info, 'urikakeAmout='+urikakeAmout);
		// 借方の売掛明細を作成する　
		if (urikakeAmout > 0) {
			// 相殺できる金額を格納する
			decimal sumsousatuAmout = 0;
			// 残金存在場合
			for (PaymentInfo__c nextPay : rsLst) {
system.debug(loggingLevel.info, '[nextPay]begin='+nextPay);
				// 相殺後残金存在場合、相殺処理を行う
				if (nextPay.RemainingMoney3__c <= 0) continue;
				// 相殺可能金額を取得する
				decimal sousatuAmount = (urikakeAmout > nextPay.RemainingMoney3__c ? nextPay.RemainingMoney3__c : urikakeAmout);
				sumsousatuAmout += sousatuAmount;
				// 相殺金額を設定する　
				//pay.OffsetMoney__c = sousatuAmount;
				// 相殺金額を減算して、残金をリセットする
				nextPay.RemainingMoney3__c = (nextPay.RemainingMoney3__c - sousatuAmount);
				nextPay.RemainingMoney2__c = nextPay.RemainingMoney3__c;
				nextPay.OffsetMoney__c = sousatuAmount;
				// 相殺金額を合計する
				urikakeAmout -= sousatuAmount;
system.debug(loggingLevel.info, '[nextPay]end='+nextPay);
				// 売掛金非存在
				if (urikakeAmout <= 0) break;
			}
			// 売掛金相殺できる金額
			if (sumsousatuAmout > 0) {
				Tran1__c ttran = wkTrans[0];
				PaymentInfo__c tmpPaymentInfo = new PaymentInfo__c(
					 LeadIndexRef__c		= ttran.Field1__r.Relreserve__r.LeadIndexRef__c
					,AccountAcountRef__c	= ttran.Field1__c
					,TTendRef__c			= null
					,ImgDataFlg__c			= true
					,DepositAmount__c		= sumsousatuAmout	// 預かり金額[残金を格納]
					,MediaTypeCode__c		= CommConst.MEDIA_TYPE_CD_03
					,RemainingMoney2__c		= 0//未利用の残金
					,RemainingMoney3__c		= 0
					,OffsetMoney__c			= sumsousatuAmout
					,PaymentType__c 		= PAY_TYPE_URKK//売掛金
				);
				rsLst.add(tmpPaymentInfo);
			}
		}
		// 2020/09/15 連泊の支払を入れた際の挙動修正2 WSQ END
		if (remaindAmount > 0) {
//system.debug(loggingLevel.info, '■■■■■■■■■■[2][1]■■■■■■■■■■■■■'+remaindAmount);	
//system.debug(loggingLevel.info, '■■■■■■■■■■[2][2]■■■■■■■■■■■■■'+payInfoLst);	
			for (PaymentInfo__c pay : payInfoLst) {
				// 残金がない場合、処理SKIP
				if (pay.RemainingMoney3__c <= 0) continue;
				if (pay.ImgDataFlg__c) continue;
				// 残金が存在場合、該当残金で支払処理を行う
				Decimal paymentAmount = (remaindAmount > pay.RemainingMoney3__c ? pay.RemainingMoney3__c : remaindAmount);
				// 該当支払明細の残金を計算する
				Decimal curRemaindAmount = (remaindAmount > paymentAmount ? 0 : (paymentAmount - remaindAmount));
				// 計算用金額のリセット
				pay.RemainingMoney3__c = (remaindAmount > pay.RemainingMoney3__c ? 0 : (pay.RemainingMoney3__c - remaindAmount));
//system.debug(loggingLevel.info, '■■■■■■■■■■[2][0]■■■■■■■■■■■■■'+pay.RemainingMoney3__c);
//system.debug(loggingLevel.info, '■■■■■■■■■■[2][3]■■■■■■■■■■■■■'+paymentAmount);
//system.debug(loggingLevel.info, '■■■■■■■■■■[2][4]■■■■■■■■■■■■■'+curRemaindAmount);

				Tran1__c ttran = wkTrans[0];
				PaymentInfo__c tmpPaymentInfo = new PaymentInfo__c(
					 LeadIndexRef__c		= pay.LeadIndexRef__c
					,AccountAcountRef__c	= ttran.Field1__c
					,TTendRef__c			= pay.TTendRef__c
					,ImgDataFlg__c			= true
					,DepositAmount__c		= paymentAmount	// 預かり金額[残金を格納]
					,MediaTypeCode__c		= pay.MediaTypeCode__c
					,RemainingMoney2__c		= curRemaindAmount//未利用の残金
					,PaymentType__c 		= PAY_TYPE_APAY//前受金
					// 2020/09/15 連泊の支払を入れた際の挙動修正2 WSQ BEGIN
					,SalesDateStr__c		= ttran.Field1__r.frs__r.Name
					// 2020/09/15 連泊の支払を入れた際の挙動修正2 WSQ END
				);
				rsLst.add(tmpPaymentInfo);
				// 0円以下の場合、未支払金額は０に設定する
				remaindAmount = remaindAmount - paymentAmount;
				if (remaindAmount <= 0) {
					remaindAmount = 0;
					break;
				}
			}
		}// end if (remaindAmount > 0) 
		// 上記残金まだ存在場合、架空の売掛支払情報を出力する
		if (remaindAmount > 0) {
//system.debug(loggingLevel.info, '■■■■■■■■■■[3]■■■■■■■■■■■■■'+remaindAmount);	
			Tran1__c ttran = wkTrans[0];
			PaymentInfo__c tmpPaymentInfo = new PaymentInfo__c(
				 LeadIndexRef__c		= ttran.Field1__r.Relreserve__r.LeadIndexRef__c
				,AccountAcountRef__c	= ttran.Field1__c
				,TTendRef__c			= null
				,ImgDataFlg__c			= true
				,DepositAmount__c		= remaindAmount	// 預かり金額[残金を格納]
				,MediaTypeCode__c		= CommConst.MEDIA_TYPE_CD_03
				,RemainingMoney2__c		= 0//未利用の残金
				,PaymentType__c 		= PAY_TYPE_URKK//売掛金
				// 2020/09/15 連泊の支払を入れた際の挙動修正2 WSQ BEGIN
				,SalesDateStr__c		= ttran.Field1__r.frs__r.Name
				// 2020/09/15 連泊の支払を入れた際の挙動修正2 WSQ END
			);
			rsLst.add(tmpPaymentInfo);
		}
		return rsLst;
	}

	private Decimal generalPaymentDetail(Decimal remaindPayMoney
								, AccountAcount__c acc
								//, List<PaymentInfo__c> payLst
								, List<PaymentInfo> payLst
								, List<PaymentDetail__c> insLst) {
		//for (PaymentInfo__c pay : payLst) {
		for (PaymentInfo pay : payLst) {
			// 一部会計支払情報から作成した支払情報に対して、残金項目は再検索しないので、直接預かり金額で設定する
			Decimal payRemainingMoney = pay.remainingMoney;
			// 残金額は０の場合、次の支払情報で処理を行う
			if (payRemainingMoney == 0) continue;
			// 全額で支払する（利用金額＞該当支払残り金額
			if (remaindPayMoney >= payRemainingMoney) {
				// 該当支払情報は予約金の場合、個別な一行支払情報を作成する
				PaymentDetail__c newPay = new PaymentDetail__c(
					 PaymentInfoRef__c = pay.s.Id
					,AccountAcountRef__c = acc.id
					,DepositAmount__c = payRemainingMoney
					,UsedAmount__c = payRemainingMoney
				);
				insLst.add(newPay);
				pay.remainingMoney = 0;
				pay.childRenRsCount ++;
			} 
			// 残金額は未支払い金額は超える場合、お釣り存在場合
			else {
				// 予約金から支払場合、明細数＝１、普通の支払場合０の場合、預かり金額は全額支払
				Integer minRsCount = (pay.s.PaymentType__c == PAY_TYPE_DESPOIST ? 1 : 0);
				PaymentDetail__c newPay = new PaymentDetail__c(
					 PaymentInfoRef__c = pay.s.Id
					,AccountAcountRef__c = acc.id
					// 初日の場合、預かり金額は全額を設定する、翌日から作成の支払い情報は利用金額で設定を行う
					,DepositAmount__c = (pay.childRenRsCount == minRsCount ? payRemainingMoney : remaindPayMoney)
					,UsedAmount__c = remaindPayMoney
				);
				insLst.add(newPay);
				pay.remainingMoney = pay.remainingMoney - remaindPayMoney;
				pay.childRenRsCount ++;
			}
			// 残り未支払金額再計算を行う
			remaindPayMoney = remaindPayMoney - payRemainingMoney;
			// 値引き超える金額は返金しない設定
			if (remaindPayMoney <= 0) {
				remaindPayMoney = 0;
				break;
			}
		}
		return remaindPayMoney;
	}
	// 残金ありの支払情報の残金情報は初期化する
	private void resetPayRemaindMonty(List<PaymentInfo> resetLst) {
		for (PaymentInfo inf : resetLst) {
			inf.remainingMoney = CommUtils.nullToZero(inf.s.RemainingMoney__c == null ? inf.s.DepositAmount__c : inf.s.RemainingMoney__c);
		}
	}
	public class PaymentInfo {
		public Decimal remainingMoney{get;set;}		// 該当支払情報の残金情報を格納する
		public Decimal childRenRsCount{get;set;}	// 該当支払に含めの子支払明細件数
		public PaymentInfo__c s{get;set;}
		public PaymentInfo(PaymentInfo__c pPay) {
			s = pPay;
			childRenRsCount = CommUtils.nullToZero(s.ChildRenRsCount__c);
			remainingMoney = CommUtils.nullToZero(s.RemainingMoney__c == null ? s.DepositAmount__c : s.RemainingMoney__c);
		}
	}
	
	// 2018/06/12 仕訳Rollup機能追加対応[入出金、売上]単位にRollup、仕入は単独Rollup BEGIN
	map<string,RollupItem> salesLeftRollupMap = new map<string, RollupItem>();
	map<string,RollupItem> salesRightRollupMap = new map<string, RollupItem>();
	enum ROLLUP_TYPE{SALES_L,SALES_R}
	private Map<String, KanjoKamoku__c> gKanjoKamokuMstMap;
	private ConvertXmlConfig gccInfo; 
	private Integer gInitStartNo;
	// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) BEGIN
	private static final String CONST_HOJYOKAMOKU_KEY = '__';
	// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) END
	// Rollup情報設定する
	// 2018/08/06 税込金額から消費税を計算する BEGIN
	private void setupRollupInfo(String psd, KanjoKamoku__c pKamoku, String pAmount, ROLLUP_TYPE rType) {
		setupRollupInfo(psd,pKamoku,pAmount,rType,TaxCalType0);
	}
	private void setupRollupInfo(String psd, KanjoKamoku__c poKamoku, String pAmount, ROLLUP_TYPE rType, String taxCalType) {
	// 2018/08/06 税込金額から消費税を計算する END
		// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) BEGIN
		if (poKamoku == null) poKamoku = new KanjoKamoku__c();
		String pKamoku = CommUtils.nullToBlank(poKamoku.KanjocodeCode__c);//科目コード
		if (gccInfo.rollupSubKamokuFlg && !CommUtils.isBlank(pKamoku)) {
			String subKamoku = CommUtils.nullToBlank(poKamoku.KanjoHojocode__c);//補助科目コード
			pKamoku += CONST_HOJYOKAMOKU_KEY +  subKamoku;
		}
		// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) END
//System.debug(LoggingLevel.info, 'psd='+psd);
//System.debug(LoggingLevel.info, 'pKamoku='+pKamoku);
//System.debug(LoggingLevel.info, 'pAmount='+pAmount);
//System.debug(LoggingLevel.info, 'rType='+rType.Name());
		// 空白内容は除外処理
		if (CommUtils.isBlank(pKamoku) && CommUtils.nullToZero(pAmount) == 0) return;
		if (rType == ROLLUP_TYPE.SALES_L) {
			if (!salesLeftRollupMap.containskey(pKamoku)) {
				salesLeftRollupMap.put(pKamoku, new RollupItem(psd,pKamoku,pAmount));
				// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
				salesLeftRollupMap.get(pKamoku).kmst = poKamoku;
				// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
			} else {
				RollupItem wkItem = salesLeftRollupMap.get(pKamoku);
				wkItem.amount = CommUtils.nullToZero(pAmount) + wkItem.amount;
			}
		} else if (rType == ROLLUP_TYPE.SALES_R) {
			if (!salesRightRollupMap.containskey(pKamoku)) {
				// 2018/08/06 税込金額から消費税を計算する BEGIN
				RollupItem wkItem = new RollupItem(psd,pKamoku,pAmount);
				wkItem.taxCalType = taxCalType;
				salesRightRollupMap.put(pKamoku, wkItem);
				//salesRightRollupMap.put(pKamoku, new RollupItem(psd,pKamoku,pAmount));
				// 2018/08/06 税込金額から消費税を計算する END
				// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
				salesRightRollupMap.get(pKamoku).kmst = poKamoku;
				// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
			} else {
				RollupItem wkItem = salesRightRollupMap.get(pKamoku);
				wkItem.amount = CommUtils.nullToZero(pAmount) + wkItem.amount;
			}
		}
//System.debug(LoggingLevel.info, 'salesLeftRollupMap='+salesLeftRollupMap);
//System.debug(LoggingLevel.info, 'salesRightRollupMap='+salesRightRollupMap);
	}
	
	// Rollup明細CSV情報を作成する
	public String generalRollupCsvContent() {
		if (!gccInfo.isOutputRollUp) return '';
		String csvLine = '';
		String csvBody = '';
		gccInfo.startno = gInitStartNo;
		// 一行CSV出力のテンプレート
		String CsvTemplateStr = CONST_CSVDATA_TEMPLATE
							// 2018/08/06 税込金額から消費税を計算する BEGIN
							//.Replace('$$_伝票区切_$$' 		, '')
							// 2018/08/06 税込金額から消費税を計算する END
							// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
							//.Replace('$$_借方部門コード_$$'	, gccInfo.debdepartcode)
							//.Replace('$$_貸方部門コード_$$'	, gccInfo.credepartcode)
							// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
							// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) BEGIN
							//.Replace('$$_摘要_$$'	, '');
							.Replace('$$_摘要_$$'	, gccInfo.rollupComment);
							// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) END
		// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
		if (!gccInfo.isExtraMode) {
			CsvTemplateStr = CsvTemplateStr
				.Replace('$$_借方部門コード_$$'	, gccInfo.debdepartcode)
				.Replace('$$_貸方部門コード_$$'	, gccInfo.credepartcode);
		}	
		// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
		list<RollupItem> salesLeftRollupList = salesLeftRollupMap.values();
		list<RollupItem> salesRightRollupList = salesRightRollupMap.values();
		// 伝票日付
		String salesDate = '';
		if (!salesLeftRollupList.isEmpty()) salesDate = salesLeftRollupList[0].salesDate;
		else if (!salesRightRollupList.isEmpty()) salesDate = salesRightRollupList[0].salesDate;
		if (CommUtils.isBlank(salesDate)) return csvBody;
		// 現金入出/売上ROLLUP結果明細出力の最大サイズ
		Integer maxLenSales = salesLeftRollupList.size() > salesRightRollupList.size()  ? salesLeftRollupList.size() : salesRightRollupList.size();
		// 2018/08/08 日付表示不具合改修(yyyyMMdd->yyyy/MM/dd)
		salesDate = getDenhyouDateStr(salesDate);
		Integer startNo = gccInfo.startno;
		if (gccInfo.rollupBegDt != null) {
			// 該当日付
			Date procDate = CommUtils.stringToDate(salesDate);
			Integer diffDays = gccInfo.rollupBegDt.daysBetween(procDate);
			if (diffDays > 0) startNo+= diffDays;
			//System.debug(loggingLevel.info, 'diffDays='+diffDays);
			//System.debug(loggingLevel.info, 'procDate='+procDate);
			//System.debug(loggingLevel.info, 'gccInfo.rollupBegDt='+gccInfo.rollupBegDt);
		}
		for (Integer i = 0; i < maxLenSales; i++) {	
			csvLine = CsvTemplateStr
					.Replace('$$_伝票番号_$$'			, CommUtils.nullToBlank(startNo))
					.Replace('$$_伝票日付_$$' 		, CommUtils.nullToBlank(salesDate));
			// 2018/08/06 税込金額から消費税を計算する BEGIN
			csvLine = csvLine.Replace('$$_伝票区切_$$' , (i == 0 ? getDenhyouDivMark(null) : ''));
			// 2018/08/06 税込金額から消費税を計算する END
			// 借方情報の支払情報を出力する
			if (i < salesLeftRollupList.size()) {
				csvLine = csvLine
					.Replace('$$_借方科目コード_$$'	, CommUtils.nullToBlank(salesLeftRollupList[i].kanjyoKamoku))
					// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) BEGIN
					//.Replace('$$_借方補助コード_$$'	, '')
					.Replace('$$_借方補助コード_$$'	, CommUtils.nullToBlank(salesLeftRollupList[i].hojyoKamoku))
					// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) BEGIN
					.Replace('$$_借方金額_$$'			, CommUtils.nullToBlank(salesLeftRollupList[i].amount));
					// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
					if (gccInfo.isExtraMode) {
						KanjoKamoku__c kmst = salesLeftRollupList[i].kmst;
						csvLine = csvLine
									.replace('$$_借方部門コード_$$'	, getDepartCode(CommUtils.nullToBlank(kmst.DebitDepartCode__c), true))
									.replace('$$_借方税区分_$$'		, CommUtils.nullToBlank(kmst.DebitTaxKbn__c))
									.replace('$$_借方税率_$$'			, '')
									.replace('$$_借方軽減税率_$$'		, '')
									.replace('$$_借方摘要_$$'			, gccInfo.rollupComment);
					}
					// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
			} else {
				csvLine = csvLine
					.Replace('$$_借方科目コード_$$'	, '')
					.Replace('$$_借方補助コード_$$'	, '')
					.Replace('$$_借方金額_$$'			, '');
					// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
					if (gccInfo.isExtraMode) {
						csvLine = csvLine
								.replace('$$_借方部門コード_$$'	, '')
								.replace('$$_借方税区分_$$'		, '')
								.replace('$$_借方税率_$$'			, '')
								.replace('$$_借方軽減税率_$$'		, '')
								.replace('$$_借方摘要_$$'			, '');
					}
					// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
			}
			// 貸方側の会計明細情報を出力する
			if (i < salesRightRollupList.size()) {
				csvLine = csvLine
					.Replace('$$_貸方科目コード_$$'	, CommUtils.nullToBlank(salesRightRollupList[i].kanjyoKamoku))
					// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) BEGIN
					//.Replace('$$_貸方補助コード_$$'	, '')
					.Replace('$$_貸方補助コード_$$'	, CommUtils.nullToBlank(salesRightRollupList[i].hojyoKamoku))
					// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) END
					.Replace('$$_貸方金額_$$'			, CommUtils.nullToBlank(salesRightRollupList[i].amount));
					// 2018/08/06 税込金額から消費税を計算する BEGIN
					csvLine = getTaxCalInfo(csvLine, salesRightRollupList[i].taxCalType);
					// 2018/08/06 税込金額から消費税を計算する END
					// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
					if (gccInfo.isExtraMode) {
						KanjoKamoku__c kmst = salesRightRollupList[i].kmst;
						csvLine = csvLine
									.replace('$$_貸方部門コード_$$'	, getDepartCode(CommUtils.nullToBlank(kmst.CreditDepartCode__c), false))
									.replace('$$_貸方税区分_$$'		, CommUtils.nullToBlank(kmst.CreditTaxKbn__c))
									.replace('$$_貸方税率_$$'			, '')
									.replace('$$_貸方軽減税率_$$'		, '')
									.replace('$$_貸方摘要_$$'			, gccInfo.rollupComment);
					}
					// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
			} else {
				// 消費税出力行目は残りままが必要
				csvLine = csvLine
					.Replace('$$_貸方科目コード_$$'	, '')
					.Replace('$$_貸方補助コード_$$'	, '')
					.Replace('$$_貸方金額_$$'			, '');
					// 2018/08/06 税込金額から消費税を計算する BEGIN
					csvLine = getTaxCalInfo(csvLine, '');
					// 2018/08/06 税込金額から消費税を計算する END
					// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
					if (gccInfo.isExtraMode) {
						csvLine = csvLine
								.replace('$$_貸方部門コード_$$'	, '')
								.replace('$$_貸方税区分_$$'		, '')
								.replace('$$_貸方税率_$$'			, '')
								.replace('$$_貸方軽減税率_$$'		, '')
								.replace('$$_貸方摘要_$$'			, '');
					}
					// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
			}
			csvBody += csvLine;
		}
		// 2016/10/07 仕訳Rollup機能、伝票NO設定不正の不具合修正 BEGIN
		if (maxLenSales > 0) gccInfo.startno++;
		// 2016/10/07 仕訳Rollup機能、伝票NO設定不正の不具合修正 END
		/*
		if (gccInfo.isOutputRollUpPur) {
			Integer maxLenPur = purLeftRollupList.size() > purRightRollupList.size()  ? purLeftRollupList.size() : purRightRollupList.size();
			for (Integer i = 0; i < maxLenPur; i++) {
				csvLine = CsvTemplateStr
					.Replace('$$_伝票番号_$$'			, CommUtils.nullToBlank(gccInfo.startno))
					.Replace('$$_伝票日付_$$' 		, CommUtils.nullToBlank(salesDate));
				// 借方情報の支払情報を出力する
				if (i < purLeftRollupList.size()) {
					csvLine = csvLine
						.Replace('$$_借方科目コード_$$'	, CommUtils.nullToBlank(purLeftRollupList[i].kanjyoKamoku))
						.Replace('$$_借方補助コード_$$'	, '')
						.Replace('$$_借方金額_$$'			, CommUtils.nullToBlank(purLeftRollupList[i].amount));
				} else {
					csvLine = csvLine
						.Replace('$$_借方科目コード_$$'	, '')
						.Replace('$$_借方補助コード_$$'	, '')
						.Replace('$$_借方金額_$$'			, '');
				}
				// 貸方側の会計明細情報を出力する
				if (i < purRightRollupList.size()) {
					csvLine = csvLine
						.Replace('$$_貸方科目コード_$$'	, CommUtils.nullToBlank(purRightRollupList[i].kanjyoKamoku))
						.Replace('$$_貸方補助コート_$$'	, '')
						.Replace('$$_貸方金額_$$'			, CommUtils.nullToBlank(purRightRollupList[i].amount));
				} else {
					// 消費税出力行目は残りままが必要
					csvLine = csvLine
						.Replace('$$_貸方科目コード_$$'	, '')
						.Replace('$$_貸方補助コート_$$'	, '')
						.Replace('$$_貸方金額_$$'			, '');
				}
				csvBody += csvLine;
			}
		} else {
			// ----------------------
			// 仕入の仕訳情報の作成(2015/11/09 仕入情報は出力機能の追加)
			// ----------------------
			//csvBody += generalPurchaseCsvInfo(gccInfo, gKanjoKamokuMstMap);
		}*/
		// Header追加
		// 2018/08/06 税込金額から消費税を計算する BEGIN
		//if (!CommUtils.isBlank(csvBody) && isAppendCsvHeaderFlg) csvBody = (Label.INF_0006 + '\n') + csvBody;
		if (!CommUtils.isBlank(csvBody) && isAppendCsvHeaderFlg) csvBody = getHeaderStr() + csvBody;
		// 2018/08/06 税込金額から消費税を計算する END
		return csvBody;
	}
	class RollupItem {
		public RollupItem () {
			amount = 0;
			// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
			kmst = new KanjoKamoku__c();
			// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
		}
		public RollupItem (String k1, String k2, String k5) {
			salesDate = k1;kanjyoKamoku = k2;
			// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) BEGIN
			if (kanjyoKamoku.contains(CONST_HOJYOKAMOKU_KEY)) {
				List<String> codeValue = kanjyoKamoku.split(CONST_HOJYOKAMOKU_KEY);
				kanjyoKamoku = codeValue[0];
				if (codeValue.size() > 1) hojyoKamoku = codeValue[1];
			}
			// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) END
			//department =k3;taxKbn = k4;
			amount=CommUtils.nullToZero(k5);
			//taxAmount=k6;
			// 2018/08/06 税込金額から消費税を計算する BEGIN
			taxCalType = TaxCalType0;
			// 2018/08/06 税込金額から消費税を計算する END
			// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
			kmst = new KanjoKamoku__c();
			// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
		}
		public String salesDate{get;set;}	// 日付
		public String kanjyoKamoku{get;set;}// 科目
		//public String department{get;set;}	// 部門
		//public String taxKbn{get;set;}		// 税区分
		public Decimal amount{get;set;}		// 金額
		//public String taxAmount{get;set;}	// 税額
		// 2018/08/06 税込金額から消費税を計算する BEGIN
		public String taxCalType{get;set;}	// 消費税の計算方式
		// 2018/08/06 税込金額から消費税を計算する END
		public String hojyoKamoku{get;set;}//補助科目
		// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
		public KanjoKamoku__c kmst{get; set;}
		// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
	}
	// 2018/06/12 仕訳Rollup機能追加対応[入出金、売上]単位にRollup、仕入は単独Rollup END
	
    /**
	* PCA連携定義情報のParse
	**/
	private ConvertXmlConfig getConvertXml(String shopCode){

		ConvertXmlConfig xmlConfig = new ConvertXmlConfig();
		// XML NAME
        String docName = 'KanSyncFieldConvertConfig';
		// Root Target 
		Dom.XmlNode shopRoot = CommXmlUtils.parseXmlDoc(docName, shopCode);

		// 店舗コード
   	 	Dom.XmlNode shopCodeField =  shopRoot.getChildElement('SHOPCODE', null);
		xmlConfig.shopCode = CommUtils.nullToBlank(shopCodeField.getText());

   	 	Dom.XmlNode nodePca =  shopRoot.getChildElement('PCA', null);
   	 	Dom.XmlNode nodeCash =  shopRoot.getChildElement('CASH', null);
   	 	Dom.XmlNode nodeMedia =  shopRoot.getChildElement('MEDIA', null);
   	 	//Dom.XmlNode nodePaymeida =  shopRoot.getChildElement('PAYMEIDA', null);

   	 	if (nodePca != null) {
   	 		Dom.XmlNode nodePacField = nodePca.getChildElement('PCA_FIELD', null);
   	 		if (nodePacField != null) {
   	 			Dom.XmlNode verField = nodePacField.getChildElement('VER', null);
   	 			if (verField != null) xmlConfig.ver = CommUtils.nullToBlank(verField.getText()).deleteWhitespace();
   	 			Dom.XmlNode startnoField = nodePacField.getChildElement('STARTNO', null);
   	 			if (startnoField != null) xmlConfig.startno = CommUtils.nullToIntZero(startnoField.getText().deleteWhitespace());
   	 			Dom.XmlNode calculationkbnField = nodePacField.getChildElement('CALCULATIONKBN', null);
   	 			if (calculationkbnField != null) xmlConfig.calculationkbn = CommUtils.nullToBlank(calculationkbnField.getText()).deleteWhitespace();
   	 			Dom.XmlNode journalkbnField = nodePacField.getChildElement('JOURNALKBN', null);
   	 			if (journalkbnField != null) xmlConfig.journalkbn = CommUtils.nullToBlank(journalkbnField.getText()).deleteWhitespace();
   	 			Dom.XmlNode manageaccjoukbnField = nodePacField.getChildElement('MANAGEACCJOUKBN', null);
   	 			if (manageaccjoukbnField != null) xmlConfig.manageaccjoukbn = CommUtils.nullToBlank(manageaccjoukbnField.getText()).deleteWhitespace();
   	 			Dom.XmlNode debdepartcodeField = nodePacField.getChildElement('DEBDEPARTCODE', null);
   	 			if (debdepartcodeField != null) xmlConfig.debdepartcode = CommUtils.nullToBlank(debdepartcodeField.getText()).deleteWhitespace();
   	 			Dom.XmlNode debconsumptaxField = nodePacField.getChildElement('DEBCONSUMPTAX', null);
   	 			if (debconsumptaxField != null) xmlConfig.debconsumptax = CommUtils.nullToBlank(debconsumptaxField.getText()).deleteWhitespace();
   	 			Dom.XmlNode credepartcodeField = nodePacField.getChildElement('CREDEPARTCODE', null);
   	 			if (credepartcodeField != null) xmlConfig.credepartcode = CommUtils.nullToBlank(credepartcodeField.getText()).deleteWhitespace();
   	 			Dom.XmlNode creconsumptaxField = nodePacField.getChildElement('CRECONSUMPTAX', null);
   	 			if (creconsumptaxField != null) xmlConfig.creconsumptax = CommUtils.nullToBlank(creconsumptaxField.getText()).deleteWhitespace();
   	 			Dom.XmlNode inputprogramkbnField = nodePacField.getChildElement('INPUTPROGRAMKBN', null);
   	 			if (inputprogramkbnField != null) xmlConfig.inputprogramkbn = CommUtils.nullToBlank(inputprogramkbnField.getText()).deleteWhitespace();
   	 		}
			// 2019/09/20 多税率機能対応 WSQ BEGIN
   	 		/*
   	 		Dom.XmlNode nodePcaTax = nodePca.getChildElement('PCA_TAX', null);
   	 		if (nodePcaTax != null) {
   	 		    Dom.XmlNode kanjocodeField = nodePcaTax.getChildElement('KANJOCODE', null);
   	 		    if (kanjocodeField != null) xmlConfig.taxKanjoCode = CommUtils.nullToBlank(kanjocodeField.getText()).deleteWhitespace();
   	 		}*/
   	 		Dom.XmlNode nodePcaTax = nodePca.getChildElement('PCA_TAX', null);
   	 		if (nodePcaTax != null) {
   	 		    //Dom.XmlNode kanjocodeField = nodePcaTax.getChildElement('KANJOCODE', null);
   	 		    //xmlConfig.taxKanjoCode = CommUtils.nullToBlank(kanjocodeField.getText()).deleteWhitespace();
	   	 		for (Dom.XmlNode m1 : nodePcaTax.getChildElements() ) {
	   	 		    if (m1.getName() == 'KANJOCODE') {
	   	 		    	xmlConfig.taxKanjoCode = CommUtils.nullToBlank(m1.getText()).deleteWhitespace();
	   	 		    	string strRate = m1.getAttribute('RATE', null);
	   	 		    	if (!CommUtils.isBlank(strRate)) xmlConfig.taxKanjoMap.put(formattax(CommUtils.nullToZero(strRate)),xmlConfig.taxKanjoCode);
	   	 		    }
	   	 		}
   	 		}
   	 		// 2016/03/10 借方の仮払消費税の会計科目出力機能の追加 BEGIN
   	 		Dom.XmlNode nodePcaPayTax = nodePca.getChildElement('PCA_PYA_TAX', null);
   	 		if (nodePcaPayTax != null) {
   	 		    //Dom.XmlNode kanjocodeField = nodePcaPayTax.getChildElement('KANJOCODE', null);
   	 		    //xmlConfig.taxPayKanjoCode = CommUtils.nullToBlank(kanjocodeField.getText()).deleteWhitespace();
	   	 		for (Dom.XmlNode m1 : nodePcaPayTax.getChildElements() ) {
	   	 		    if (m1.getName() == 'KANJOCODE') {
	   	 		    	xmlConfig.taxPayKanjoCode = CommUtils.nullToBlank(m1.getText()).deleteWhitespace();
	   	 		    	string strRate = m1.getAttribute('RATE', null);
	   	 		    	if (!CommUtils.isBlank(strRate)) xmlConfig.taxPayKanjoMap.put(formattax(CommUtils.nullToZero(strRate)),xmlConfig.taxPayKanjoCode);
	   	 		    }
	   	 		}
   	 		}
   	 		// 2019/09/20 多税率機能対応 WSQ END
   	 		Dom.XmlNode nodePcaadvpayL = nodePca.getChildElement('PCA_ADVPAY_L', null);
   	 		if (nodePcaadvpayL != null) {
   	 		    Dom.XmlNode kanjocodeLField = nodePcaadvpayL.getChildElement('KANJOCODE', null);
   	 		    if (kanjocodeLField != null) xmlConfig.advpayLKanjoCode = CommUtils.nullToBlank(kanjocodeLField.getText()).deleteWhitespace();
   	 		}
   	 		Dom.XmlNode nodePcaadvpayR = nodePca.getChildElement('PCA_ADVPAY_R', null);
   	 		if (nodePcaadvpayR != null) {
   	 		    Dom.XmlNode kanjocodeRField = nodePcaadvpayR.getChildElement('KANJOCODE', null);
   	 		    if (kanjocodeRField != null) xmlConfig.advpayRKanjoCode = CommUtils.nullToBlank(kanjocodeRField.getText()).deleteWhitespace();
   	 		}
   	 		// 2015/07/09 返金：右側の会計科目
   	 		Dom.XmlNode nodePcaRefundR = nodePca.getChildElement('PCA_REFUND_R', null);
   	 		if (nodePcaRefundR != null) {
   	 		    Dom.XmlNode kanjocodeRField = nodePcaRefundR.getChildElement('KANJOCODE', null);
   	 		    if (kanjocodeRField != null) xmlConfig.refundRkanjoCode = CommUtils.nullToBlank(kanjocodeRField.getText()).deleteWhitespace();
   	 		}
			// 2018/06/12 仕訳Rollup機能追加対応 BEGIN
			Dom.XmlNode rollUpField =  nodePca.getChildElement('ROLLUP_OUTPUT', null);
			if (rollUpField != null) {
				String str = CommUtils.nullToBlank(rollUpField.getText());
				if (!CommUtils.isBlank(str)) xmlConfig.isOutputRollUp = Boolean.valueOf(str);
			}
			// 非表示の会計明細はCSVに出力する・しない制御フラグ
			Dom.XmlNode noshowField =  nodePca.getChildElement('NOSHOW_OUPTPUT', null);
			if (noshowField != null) {
				String str = CommUtils.nullToBlank(noshowField.getText());
				if (!CommUtils.isBlank(str)) xmlConfig.isNoshowOutFlg = Boolean.valueOf(str);
			}
			// 2018/06/12 仕訳Rollup機能追加対応 END
			// 2018/08/06 税込金額から消費税を計算する BEGIN
			Dom.XmlNode taxAutoCalField =  nodePca.getChildElement('TAX_AUTOCAL', null);
			if (taxAutoCalField != null) {
				xmlConfig.isTaxAutoCalFlg = Boolean.valueOf(CommUtils.nullToBlank(taxAutoCalField.getText()));
			}
			Dom.XmlNode rollupBegDtField =  nodePca.getChildElement('ROLLUP_BEGINDT', null);
			if (rollupBegDtField != null) {
				String str = CommUtils.nullToBlank(rollupBegDtField.getText());
				if (!CommUtils.isBlank(str)) {
					Date dt = CommUtils.stringToDate(str);
					if (dt != null) xmlConfig.rollupBegDt = dt;
				}
			}
			// 2018/08/06 税込金額から消費税を計算する END
			// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) BEGIN
			Dom.XmlNode rollupSubKamokuField =  nodePca.getChildElement('ROLLUP_SUBKAMOKU_OUTPUT', null);
			if (rollupSubKamokuField != null) {
				xmlConfig.rollupSubKamokuFlg = Boolean.valueOf(CommUtils.nullToBlank(rollupSubKamokuField.getText()));
			}
			Dom.XmlNode rollupCommentField =  nodePca.getChildElement('ROLLUP_COMMENT', null);
			if (rollupCommentField != null) {
				xmlConfig.rollupComment = CommUtils.nullToBlank(rollupCommentField.getText());
			}
			// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) END
			// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
			Dom.XmlNode outputModeField =  nodePca.getChildElement('OUTPUT_TYPE_MODE', null);
			if (outputModeField != null) {
				String strOtuType = CommUtils.nullToBlank(outputModeField.getText());
				xmlConfig.isExtraMode = (strOtuType == '2');
			}
			// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
			// 2020/11/02 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う）WSQ BEGIN
			Dom.XmlNode pcaNewModeField =  nodePca.getChildElement('PCA_NEWMODE', null);
			if (pcaNewModeField != null) {
				// 機能有効・無効
				Dom.XmlNode activeField = pcaNewModeField.getChildElement('ACTIVE', null);
				xmlConfig.isUseDayOutMode = Boolean.valueOf(CommUtils.nullToBlank(activeField.getText()));
				// 機能有効の場合、貸方、借方の勘定科目定義を取得する
				if (xmlConfig.isUseDayOutMode) {
					Dom.XmlNode apLeftKanjoSeqNoField = pcaNewModeField.getChildElement('AP_KANJOSEQ_L', null);
					if (apLeftKanjoSeqNoField != null) xmlConfig.apLeftKanjoSeqNo = CommUtils.nullToBlank(apLeftKanjoSeqNoField.getText());
					Dom.XmlNode dpLeftKanjoSeqNoField = pcaNewModeField.getChildElement('DP_KANJOSEQ_L', null);
					if (dpLeftKanjoSeqNoField != null) xmlConfig.dpLeftKanjoSeqNo = CommUtils.nullToBlank(dpLeftKanjoSeqNoField.getText());
					Dom.XmlNode acKanjoSeqNoField = pcaNewModeField.getChildElement('AC_KANJOSEQ_R', null);
					if (acKanjoSeqNoField != null) xmlConfig.acKanjoSeqNo = CommUtils.nullToBlank(acKanjoSeqNoField.getText());
					Dom.XmlNode apRightKanjoSeqNoField = pcaNewModeField.getChildElement('AP_KANJOSEQ_R', null);
					if (apRightKanjoSeqNoField != null) xmlConfig.apRightKanjoSeqNo = CommUtils.nullToBlank(apRightKanjoSeqNoField.getText());
				}
			}
			// 2020/11/02 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う）WSQ END
   	 	}

   	 	if (nodeCash != null) {
   	 	    Dom.XmlNode nodeCashInput = nodeCash.getChildElement('CASH_INPUT', null);
   	 	    if (nodeCashInput != null) {
   	 	    	for (Dom.XmlNode c1:nodeCashInput.getChildElements() ) {
   	 	    		String c1k = CommUtils.nullToBlank(c1.getChildElement('KEMOKU', null).getText());
   	 	    		String c1i = CommUtils.nullToBlank(c1.getChildElement('I_KANJOCODE', null).getText()).deleteWhitespace();
   	 	    		String c1o = CommUtils.nullToBlank(c1.getChildElement('O_KANJOCODE', null).getText()).deleteWhitespace();
   	 	    		xmlConfig.cashInputInMap.put(c1k, c1i);
   	 	    		xmlConfig.cashInputOuMap.put(c1k, c1o);
   	 	    	}
   	 	    }
   	 	    Dom.XmlNode nodeCashOutput = nodeCash.getChildElement('CASH_OUTPUT', null);
   	 	    if (nodeCashOutput != null) {
   	 	    	for (Dom.XmlNode c2:nodeCashOutput.getChildElements() ) {
   	 	    		String c2k = CommUtils.nullToBlank(c2.getChildElement('KEMOKU', null).getText());
   	 	    		String c2i = CommUtils.nullToBlank(c2.getChildElement('I_KANJOCODE', null).getText()).deleteWhitespace();
   	 	    		String c2o = CommUtils.nullToBlank(c2.getChildElement('O_KANJOCODE', null).getText()).deleteWhitespace();
   	 	    		xmlConfig.cashOutputInMap.put(c2k, c2i);
   	 	    		xmlConfig.cashOutputOuMap.put(c2k, c2o);
   	 	    	}
   	 	    }
   	 	}
   	 	// 支払メデイアにより、補助会計科目コードを取得する
   	 	if (nodeMedia != null) {
			for (Dom.XmlNode m1:nodeMedia.getChildElements() ) {
				if (m1.getName() == 'CARD') {
					// COVERT情報
					for (Dom.XmlNode convert:m1.getChildElements() ) {
						String m1cc = CommUtils.nullToBlank(convert.getChildElement('CARDNAME', null).getText());
	 	 				String m1ck = CommUtils.nullToBlank(convert.getChildElement('KANJOCODE', null).getText()).deleteWhitespace();
				    	xmlConfig.mediaCardMap.put(m1cc, m1ck);
					}
				} else if (m1.getName() == 'KINKEN') {
					// COVERT情報
					for (Dom.XmlNode convert:m1.getChildElements() ) {
					    String m1kk = CommUtils.nullToBlank(convert.getChildElement('KINKENNAME', null).getText());
		 	 			String m1kc = CommUtils.nullToBlank(convert.getChildElement('KANJOCODE', null).getText()).deleteWhitespace();
		 	 			xmlconfig.mediaKinkenMap.put(m1kk, m1kc);
					}
				}
   	 	    }
   	 	}
		// 関連の支払メデイア情報取得する
   	 	BillSimpleHelp help = new BillSimpleHelp(shopCode);
   	 	xmlConfig.mediaProductCdMap = help.getMediaLabToAccMstMap();
   	 	
   	 	return xmlConfig;
    }

	/**
	* 店舗別CSV出力転換情報格納クラス
	**/
	public class ConvertXmlConfig {
		public ConvertXmlConfig() {
			cashInputInMap = new Map<String, String>();
			cashInputOuMap = new Map<String, String>();
			cashOutputInMap = new Map<String, String>();
			cashOutputOuMap = new Map<String, String>();
			mediaProductCdMap = new Map<String, AccountMaster__c>();
			mediaCardMap = new Map<String, String>();
			mediaKinkenMap = new Map<String, String>();
			// 2018/06/12 仕訳Rollup機能追加対応 BEGIN
			isOutputRollUp = true;
			isNoshowOutFlg = true;
			// 2018/06/12 仕訳Rollup機能追加対応 END
			// 2018/08/06 税込金額から消費税を計算する BEGIN
			isTaxAutoCalFlg = false;
			rollupBegDt = null;
			// 2018/08/06 税込金額から消費税を計算する END
			// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) BEGIN
			rollupSubKamokuFlg = false;
			rollupComment = '';
			// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) END
			// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
			isExtraMode = false;
			// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
			// 2020/11/02 freee連携時、連泊の支払を入れた際の挙動修正 WSQ BEGIN
			isUseDayOutMode = false;
			// 2020/11/02 freee連携時、連泊の支払を入れた際の挙動修正 WSQ END
		}
		// 店鋪コード
		public String shopCode{get;set;}
		// Ver
		public String ver {get;set;}
		// 伝票番号
		public Integer startno {get;set;}
		// 計算区分
		public String calculationkbn {get;set;}
		// 仕訳区分
		public String journalkbn {get;set;}
		// 管理会計仕訳区分
		public String manageaccjoukbn {get;set;}
		// 借方部門コード
		public String debdepartcode {get;set;}
		// 借方消費税額
		public String debconsumptax {get;set;}
		// 貸方部門コード
		public String credepartcode {get;set;}
		// 貸方消費税額 
		public String creconsumptax {get;set;}
		// 入力プログラム区分
		public String inputprogramkbn {get;set;}

		// TAX
		public String taxKanjoCode{get;set;}
		// 前受付金左側用勘定項目のSEQコード
		public String advpayLKanjoCode{get;set;}
		// 前受付金右側用勘定項目のSEQコード
		public String advpayRKanjoCode{get;set;}
		// 返金右側用勘定科目のSEQコード　
		public String refundRkanjoCode{get;set;}
		// 入金PCA連携用定義情報格納
		public Map<String, String> cashInputInMap{get;set;}
		public Map<String, String> cashInputOuMap{get;set;}
		// 出金PCA連携用定義情報格納
		public Map<String, String> cashOutputInMap{get;set;}
		public Map<String, String> cashOutputOuMap{get;set;}
		// 支払メディアにより、支払商品を紐付けない場合、対応の会計商品コード情報可能
		public Map<String, AccountMaster__c> mediaProductCdMap{get;set;}
		// カード種別と金券種別
		public Map<String, String> mediaCardMap{get;set;}
		public Map<String, String> mediaKinkenMap{get;set;}
		// 2018/06/12 仕訳Rollup機能追加対応 BEGIN
		public Boolean isOutputRollUp{get; set;}
		public Boolean isNoshowOutFlg{get; set;}
		// 2018/06/12 仕訳Rollup機能追加対応 END
		// 2018/08/06 税込金額から消費税を計算する BEGIN
		public Boolean isTaxAutoCalFlg{get; set;}
		public Date rollupBegDt{get;set;}
		// 2018/08/06 税込金額から消費税を計算する END
		// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) BEGIN
		public Boolean rollupSubKamokuFlg{get;set;}
		public String rollupComment{get;set;}
		// 2018/08/21 KANRU出力機能改善(補助科目の出力/摘要欄に固定文言を出力) END
		// 2019/10/20 多税率機能対応 WSQ BEGIN
		// 仕訳明細出力する際、消費税8%と10%に行が分ける出力する対応
		// 入出金消費税項目が存在場合、入出金消費税も出力する対応
		public map<decimal,string> taxKanjoMap = new map<decimal, string>();	// 仮受消費税
		public map<decimal,string> taxPayKanjoMap = new map<decimal, string>();	// 仮払消費税
		// 借方の仮払消費税の会計科目出力機能の追加
		public String taxPayKanjoCode{get;set;}
		// 2019/09/20 多税率機能対応 WSQ END
		// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
		// CSJS200に会計科目の借方部門コードを出力する
		// CSJS203、CSJS220、CSJS222の追加
		// CSJS203：会計科目と紐づくため会計科目の借税区分をCSJS203に出力する。
		// CSJS220：税率の値、8%なら8、10%なら10、0%は空白か0を出力
		// CSJS222：軽減税率かどうかを出力する。8%の取引の行には"1"、10%の取引の行には"0"
		// CSJS221を追加し、摘要を出力する
		// CSJS300に会計科目の貸方部門コードを出力する
		// CSJS303、CSJS320、CSJS322の追加
		// CSJS303：会計科目と紐づくため会計科目の貸税区分をCSJS303に出力する。
		// CSJS320：税率の値、8%なら8、10%なら10、0%は空白か0を出力
		// CSJS322：軽減税率かどうかを出力する。8%の取引の行には"1"、10%の取引の行には"0"10%の取引の行には"0"
		// CSJS321を追加し、摘要を出力する
		public Boolean isExtraMode{get; private set;}
		// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
		// 2020/11/02 freee連携時、連泊の支払を入れた際の挙動修正 WSQ BEGIN
		// 仕訳明細出力は利用日と合わせて出力する・しない切り替えフラグ（デフォルト：ON）
		public Boolean isUseDayOutMode{get;set;}
		public String apLeftKanjoSeqNo{get; set;}		// 借方勘定科目SEQ
		public String dpLeftKanjoSeqNo{get; set;}		// 借方勘定科目SEQ
		public String acKanjoSeqNo{get; set;}		// 貸方勘定科目SEQ
		public String apRightKanjoSeqNo{get; set;}
		// 2020/01/21 freee連携時、連泊の支払を入れた際の挙動修正 WSQ END
	}
	// 2018/08/06 税込金額から消費税を計算する BEGIN
	private string getHeaderStr() {
		// 2020.04.17. 1.9.勘定奉行連携CSVの改善（CSJS306列追加) WSQ BEGIN
		/*
		// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
		if (gccInfo.isExtraMode) return Label.INF_0006_1 + '\n';
		// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
		*/
		String headerStr = Label.INF_0006;
		if (gccInfo.isExtraMode) headerStr = Label.INF_0006_1;
		// 2020.04.17. 1.9.勘定奉行連携CSVの改善（CSJS306列追加) WSQ END
		if (gccInfo.isTaxAutoCalFlg) headerStr += ',CSJS306';
		return headerStr + '\n';
	}
	private string getTaxCalInfo(String csvTemplate,String taxCalType) {
		return (csvTemplate.replace('$$_貸方消費税計算_$$',(gccInfo.isTaxAutoCalFlg ? taxCalType:'')));
	}
	// 2018/08/06 税込金額から消費税を計算する END
	// 2019/09/20 多税率機能対応 WSQ BEGIN
	private static decimal formattax(decimal tax) {
		// 2020/03/19 勘定奉行連携CSVの改善 WSQ BEGIN
		if (tax == null) tax = 0;
		// 2020/03/19 勘定奉行連携CSVの改善 WSQ END
		return tax.setscale(4);
	}
	// 現金入出のXML定義情報を取得する
	private class CaseConfig {
		public CaseConfig(String pspcd) {
			depismulititax = payismulititax = false;
			//depOrgIsIncTax = payOrgIsIncTax = true;
			// 現金入出の配置ファイルから定義情報を取得する
			try {
				String docName = 'CashManagentConfig';
				Dom.XmlNode shopRoot = CommXmlUtils.parseXmlDoc(docName, pspcd);
				// xml定义入金
				Dom.XmlNode depositNode = shopRoot.getChildElement('DEPOSIT', null);
				if(depositNode != null){
					Dom.XmlNode taxSelNode = depositNode.getChildElement('TAXSELECTFLG', null);
					if(taxSelNode != null){
						depismulititax = Boolean.valueOf(CommUtils.nullToBlank(taxSelNode.getText()));
					}
					/*
					Dom.XmlNode orgIsIncTaxNode = depositNode.getChildElement('ORGAMOUNTINCTAX', null);
					if(orgIsIncTaxNode != null){
						depOrgIsIncTax = Boolean.valueOf(CommUtils.nullToBlank(orgIsIncTaxNode.getText()));
					}*/
				}
				// xml定义出金
				Dom.XmlNode paymentslipNode = shopRoot.getChildElement('PAYMENTSLIP', null);
				if(paymentslipNode != null){
					Dom.XmlNode taxSelNode = paymentslipNode.getChildElement('TAXSELECTFLG', null);
					if(taxSelNode != null){
						payismulititax = Boolean.valueOf(CommUtils.nullToBlank(taxSelNode.getText()));
					}
					/*
					Dom.XmlNode orgIsIncTaxNode = paymentslipNode.getChildElement('ORGAMOUNTINCTAX', null);
					if(orgIsIncTaxNode != null){
						payOrgIsIncTax = Boolean.valueOf(CommUtils.nullToBlank(orgIsIncTaxNode.getText()));
					}*/
				}
			} catch (exception e){}
		}
		public boolean depismulititax{get;set;}//入金消費税ある
		public boolean payismulititax{get;set;}//出金消費税ある
		//public boolean depOrgIsIncTax{get;set;}//入力金額は税込含めるがどうかフラグ
		//public boolean payOrgIsIncTax{get;set;}//出金金額は税込含めるがどうかフラグ
	}
	private static final decimal CONST_SUM_TAX_RATE = formattax(-99999);
	// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
	private Decimal formatOuputNumber(Decimal num) {
		if (num == null) num = 0;
		if (intValPointLen == 0) return num.intValue();
		else return CommUtils.RoundProcess(num, intValPointLen);
		/*
		Boolean isPointProcessType = gccInfo.pointProcess;
		Decimal locNum = 0;
		if (!isPointProcessType) {
			locNum = num.intValue();
		} else {
			locNum = CommUtils.RoundProcess(num, gPointLen);
			if (gPointLen == 0) locNum = locNum.intValue();
		}
		return locNum;
		*/
		return num;
	}
	// 2016/11/21 出力金額の小数点対応できる改善 END
	// 2020/05/07 CSJS220（借方税率）、CSJS320（貸方税率）に小数点以下が出力された不具合改修 WSQ BEGIN
	private static final Integer intValPointLen = CommUtils.getPointLen();
	private static final Integer intTaxPointLen = CommUtils.getTaxPointLen();
	private Decimal formatOuputTaxRate(Decimal num) {
		if (num == null) num = 0;
		if (intTaxPointLen == 0) return num.intValue();
		else return CommUtils.RoundProcess(num, intTaxPointLen);
	}
	// 2020/05/07 CSJS220（借方税率）、CSJS320（貸方税率）に小数点以下が出力された不具合改修 WSQ END
	// 2019/09/20 多税率機能対応 WSQ END
}