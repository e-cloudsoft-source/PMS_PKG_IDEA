/*****************
* PCA連携処理
* 入金・出金関連のCSV出力
* 会計関連の詳細情報をCSV出力
* 2015/03/04 1泊N部屋の場合、出力のPCA明細の問題対応
*            掛計の場合、［カード」「金券種別」設定のケース対応
* 2015/03/11 金額の小数点外す対応
* 2015/06/24 返金、予約金機能対応（予約金：バッチから日付と一致する支払情報あり、会計明細なしのデータは予約金として、登録を行う
*            返金機能の場合、明細の種類は返金場合、返金情報は一行で出力を行う
*			 利用日モード機能も対応
* 2015/07/17 バッチの実施順番により、後ろのPCAを実施後、前日の日付のバッチを再実施の場合、予約金の判断不具合の修正
* 2016/01/18 Chatterグループへ送信、借方金額は貸方金額と合わない場合、WARNING情報を出力する
* 2017/08/03 サビース料金額は個別行に出力できるように改善対応
* 2019/03/15 特別税金額は個別行に出力できるように改善対応
*****************/
public with sharing class PcaSyncCsvTemplateCtrl {
	
	private final String csvHeaderStr = Label.INF_0004 + '\n';//'Ver,伝票日付,伝票番号,計算区分,仕訳区分,管理会計仕訳区分,借方部門コード,借方科目コード,借方科目名,借方補助コード,借方補助名,借方税区分,借方金額,借方消費税額,貸方部門コード,貸方科目コード,貸方科目名,貸方補助コード,貸方補助名,貸方税区分,貸方金額,貸方消費税額,数字1,数字2,摘要,入力プログラム区分,配賦税計算モード,配賦元集計開始日,配賦元集計終了日,配賦基準番号,配賦元部門コード,配賦元科目コード,配賦元補助コード,配賦元金額\n';
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
	// 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH BEGIN
	// 特別税出力する・しないフラグ
	private Boolean isOutSpecialTaxFlg = false;
	private Map<String, Decimal> pSpecialTaxMap_0; // Map<planId, plan明细的特别税>
	private Map<String, Decimal> pSpecialTaxMap_1; // Map<planId, plan明细的特别税>
	private Map<String, Decimal> pSpecialTaxMap_2; // Map<planId, plan明细的特别税>
	private Map<String, Decimal> pSpecialTaxMap_3; // Map<planId, plan明细的特别税>
	// 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH END
	// 定数
	public final String PAY_TYPE_DESPOIST = '予約金';
	public final String PAY_TYPE_REFUND = '返金';
	public final String PAY_TYPE_NORMAL = '普通';
	// ログ情報格納用
	public String msgStr{get; private set;}
	/**
	* 店舗別売上日単位のPCA連携情報を作成する
	**/
	public PcaSyncCsvTemplateCtrl (String rsvAccId, String shopCode) {
		gRsvAccoutId = rsvAccId;
		gShopCode = shopCode;
		msgStr = '';
	}

	// *************************
	// CSV出力のテンプレート定義情報
	// *************************
	private static final String CONST_CSVDATA_TEMPLATE='$$_Ver_$$,$$_伝票日付_$$,$$_伝票番号_$$,0,1,0,$$_借方部門コード_$$,$$_借方科目コード_$$,,$$_借方補助コード_$$,,$$_借方税区分_$$,$$_借方金額_$$,$$_借方消費税額_$$,'
													  +'$$_貸方部門コード_$$,$$_貸方科目コード_$$,,$$_貸方補助コード_$$,,$$_貸方税区分_$$,$$_貸方金額_$$,$$_貸方消費税額_$$,,,$$_摘要_$$,$$_入力プログラム区分_$$,,,,,,,,\n';
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
        // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
        isOutServiceFlg = ccInfo.isOutputService;
        // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
        // 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH BEGIN
        isOutSpecialTaxFlg = ccInfo.isOutputSpecialTax; // 特別税出力行功能开关
        // 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH END
		// 指定店舗コードと売上IDで,指定日のPCA売上情報を抽出する
		// 関連の会計科目情報取得、格納する
		Set<String> seqNoSet = new Set<String>();
		// 利用必要の会計科目情報を一括取得
		if (!CommUtils.isBlank(ccInfo.taxKanjoCode)) seqNoSet.add(ccInfo.taxKanjoCode);
		if (!CommUtils.isBlank(ccInfo.advpayLKanjoCode)) seqNoSet.add(ccInfo.advpayLKanjoCode);
		if (!CommUtils.isBlank(ccInfo.advpayRKanjoCode)) seqNoSet.add(ccInfo.advpayRKanjoCode);
		if (!CommUtils.isBlank(ccInfo.refundRkanjoCode)) seqNoSet.add(ccInfo.refundRkanjoCode);
        // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
        if (!CommUtils.isBlank(ccInfo.serviceRkanjoCode)) seqNoSet.add(ccInfo.serviceRkanjoCode);
        // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
        // 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH BEGIN
        if (!CommUtils.isBlank(ccInfo.specialTaxRkanjoCode)) seqNoSet.add(ccInfo.specialTaxRkanjoCode);
        // 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH END
		for (String seqNo : ccInfo.cashInputInMap.values()) seqNoSet.add(seqNo);
		for (String seqNo : ccInfo.cashInputOuMap.values()) seqNoSet.add(seqNo);
		for (String seqNo : ccInfo.cashOutputInMap.values()) seqNoSet.add(seqNo);
		for (String seqNo : ccInfo.cashOutputOuMap.values()) seqNoSet.add(seqNo);
		// Media種別関連の会計科目情報
		for (String seqNo : ccInfo.mediaCardMap.values()) seqNoSet.add(seqNo);
		for (String seqNo : ccInfo.mediaKinkenMap.values()) seqNoSet.add(seqNo);
		// 会計科目基本情報を取得する
		Map<String, KanjoKamoku__c> kanjoKamokuMstMap = new Map<String, KanjoKamoku__c>();
		if (!seqNoSet.isEmpty()) {
			for (KanjoKamoku__c mst : [select id, Name, Kanjocode__c, KanjocodeCode__c, KanjoHojocode__c,DebitTaxKbn__c, CreditTaxKbn__c from KanjoKamoku__c where Kanjocode__c in :seqNoSet]) {
				kanjoKamokuMstMap.put(mst.Kanjocode__c, mst);
			}
		}

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
		return (isAppendCsvHeaderFlg == true ? (csvHeaderStr + csvBody): csvBody);
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
                            // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
                            ' ,Field20__c,TaxRate__c,ServiceRate__c,Field21__c,UnitPriceDefKbCal__c'+
                            // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
                            // 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH BEGIN
                            ' ,ActionType__c,SpecialTax__c,ParentTran1Ref__c ' +
                            // 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH END
		 					' ,Field7__r.KanjoKamokuRef__r.KanjocodeCode__c '+
		 					' ,Field7__r.KanjoKamokuRef__r.KanjoHojocode__c '+
		 					' ,Field7__r.KanjoKamokuRef__r.DebitTaxKbn__c '+
		 					' ,Field7__r.KanjoKamokuRef__r.CreditTaxKbn__c '+
		 					' From TranAccount__r '+
		 					// 商品種別はプランのBreakDown項目と普通の会計明細
		 					' where ActionType__c != :PROD_ACTION_TYPE_PL And ActionType__c != :PROD_ACTION_TYPE_AR  ' +
		 					//' And Accountoutside__c = 1 ' +
		 					// 請求書非表示は対象外
		 					//' And InvoiceNoShowFlg__c = false ' +
		 					// 有効な明細　OR　親が存在 AND　親は有効な明細
		 					' And ( ( InvoiceNoShowFlg__c = false And ParentTran1Ref__c = null And Accountoutside__c = 1) OR (ParentTran1Ref__c != null And ParentTran1Ref__r.Accountoutside__c = 1 And ParentTran1Ref__r.InvoiceNoShowFlg__c = false) ) ' +
		 					' order by rowNo__c,name),'
		 					// 会計支払[Field2__c:メディア種別]
		 				+ '(Select Field2__c, Field3__c, CardTypeLst__c, PayProductName__c,CouponTypeLst__c, Field20__c, Field19__c,OutSideAccount__c ' +
		 					' ,PayProductRef__r.KanjoKamokuRef__r.KanjoHojocode__c '+
		 					' ,PayProductRef__r.KanjoKamokuRef__r.KanjocodeCode__c '+
		 					' ,PayProductRef__r.KanjoKamokuRef__r.DebitTaxKbn__c '+
		 					' ,PayProductRef__r.KanjoKamokuRef__r.CreditTaxKbn__c  '+
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
		// 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH BEGIN
		Set<String> planIdSet = new Set<String>(); // plan展开明细内，含有处理种别为室料的planId
		// 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH END
		for (AccountAcount__c acc : accs) {
			// 会計明細がなかったの場合、該当会計はPCA抽出対象外になる
//			if (acc.TranAccount__r.isEmpty()) continue;
			// 会計明細情報取得する
			List<Tran1__c> trans = acc.TranAccount__r;
			// 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH BEGIN
			for(Tran1__c tran : trans){
				// プラン明細　かつ　明細の商品タイプは室料場合
				String planId = tran.ParentTran1Ref__c;
				if(!CommUtils.isBlank(planId) && RackRateUtils.isRoomRateProduct(tran.ActionType__c)){
					planIdSet.add(planId); // 有效的planId
				}
			}
			// 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH END
			// 会計支払情報取得する
			List<TTend__c> ttends = acc.TranTotalfromPay__r;
			if (trans.isEmpty() && ttends.isEmpty()) continue;	// 空な会計情報は対象外になる
			accTargets.add(acc);
		}
		// 処理対象なし
		if (accTargets.isEmpty()) return '';
		// 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH BEGIN
		if(!planIdSet.isEmpty()){
			pSpecialTaxMap_0 = new Map<String, Decimal>(); // Map<planId, plan明细的特别税>
			pSpecialTaxMap_1 = new Map<String, Decimal>(); // Map<planId, plan明细的特别税>
			pSpecialTaxMap_2 = new Map<String, Decimal>(); // Map<planId, plan明细的特别税>
			pSpecialTaxMap_3 = new Map<String, Decimal>(); // Map<planId, plan明细的特别税>
			// 会計明細
			List<Tran1__c> pTrans = [Select Id, Field1__c, SpecialTax__c From Tran1__c Where Id in: planIdSet];
			for(Tran1__c tran : pTrans){
				Decimal specialTax = CommUtils.nullToZero(tran.SpecialTax__c);
				// plan为key合计
				if(pSpecialTaxMap_0.containsKey(tran.Id)) specialTax += CommUtils.nullToZero(pSpecialTaxMap_0.get(tran.Id));
				pSpecialTaxMap_0.put(tran.Id, specialTax);
			}
			pSpecialTaxMap_1 = pSpecialTaxMap_0.clone();
			pSpecialTaxMap_2 = pSpecialTaxMap_0.clone();
			pSpecialTaxMap_3 = pSpecialTaxMap_0.clone();
		}
		// 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH END
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
		//Integer taxOuputLineNum = tranSize;	// 消費税出力行目[会計明細の次の行目から出力する]
		Decimal amountIncTax = 0;	// 税込み合計金額
		Decimal amountNoTax  = 0;	// 税抜き合計金額
		// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
		Decimal amountServiceNoTax = 0;         // サビース料税抜き合計金額
		// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
		// 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH BEGIN
		Decimal specialTax = 0;
		// 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH END
// 2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする BEGIN
Integer leftAmount = 0, rightAmount = 0;
// 2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする END
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
					.Replace('$$_借方科目コード_$$'	, CommUtils.nullToBlank(accMst.KanjoKamokuRef__r.KanjocodeCode__c))
					.Replace('$$_借方補助コード_$$'	, CommUtils.nullToBlank(accMst.KanjoKamokuRef__r.KanjoHojocode__c))
					.Replace('$$_借方税区分_$$'		, CommUtils.nullToBlank(accMst.KanjoKamokuRef__r.DebitTaxKbn__c))
					.Replace('$$_借方金額_$$'			, String.valueOf(paymentAmount.intValue()));
// 2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする BEGIN
leftAmount += CommUtils.nullToIntZero(paymentAmount);
// 2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする END
			} else {
				csvLine = csvLine
						.Replace('$$_借方科目コード_$$'	,'')
						.Replace('$$_借方補助コード_$$'	,'')
						.Replace('$$_借方税区分_$$'	,'')
						.Replace('$$_借方金額_$$'	,'');
			}
			// 貸方側の会計明細情報を出力する
			if (i < tranSize) {
				Tran1__c tran = trans[i];
				Decimal tanknotax = CommUtils.nullToZero(tran.GoukeinoneTax__c);
				// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
                // サビース料税抜きと売上金額（税抜き）を計算する
                List<Decimal> wkLocTanNoTax = calServiceAmount(tanknotax, tran);
                tanknotax = wkLocTanNoTax[0];
                amountServiceNoTax += wkLocTanNoTax[1];
				// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
				// 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH BEGIN
				if(isOutSpecialTaxFlg){
					// 集计普通会计明细
					if(tran.ParentTran1Ref__c == null) specialTax += CommUtils.nullToZero(tran.SpecialTax__c);
				}
				// 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH END
				csvLine = csvLine
						.Replace('$$_貸方科目コード_$$'	, CommUtils.nullToBlank(tran.Field7__r.KanjoKamokuRef__r.KanjocodeCode__c))
						.Replace('$$_貸方補助コード_$$'	, CommUtils.nullToBlank(tran.Field7__r.KanjoKamokuRef__r.KanjoHojocode__c))
						.Replace('$$_貸方税区分_$$'		, CommUtils.nullToBlank(tran.Field7__r.KanjoKamokuRef__r.CreditTaxKbn__c))
					 	.Replace('$$_貸方金額_$$'			, String.valueOf(tanknotax.intValue()));
			 	
			 	// 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH BEGIN
			 	// 実際利用金額
			 	// amountIncTax += CommUtils.nullToZero(tran.Field41__c);
			 	// 处理planBreakDown項目商品种别为室料的明细, 进行合計金額（税込:サービス込）等的处理
			 	// wkAmountIncTax[0] => 合計金額（税込:サービス込）包含特别税【不符合以上条件的返回默认值:CommUtils.nullToZero(tran.Field41__c)】
			 	// wkAmountIncTax[1] => 该明细处理后的特别税【不符合以上条件的返回默认值: 0】
			 	List<Decimal> wkAmountIncTax = getAmountIncTax(CommUtils.nullToZero(tran.Field41__c), tran, 0);
			 	amountIncTax += wkAmountIncTax[0];
			 	specialTax += wkAmountIncTax[1];
			 	// 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH END
			 	// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
			 	//amountNoTax  += CommUtils.nullToZero(tran.GoukeinoneTax__c);
			 	amountNoTax  += tanknotax;
			 	// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
// 2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする BEGIN
rightAmount += CommUtils.nullToIntZero(tanknotax);
// 2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする END
            // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
            /*
			} else {
				// 消費税出力行目は残りままが必要
				if (i != taxOuputLineNum) {
					csvLine = csvLine
						.Replace('$$_貸方科目コード_$$'	, '')
						.Replace('$$_貸方補助コード_$$'	, '')
						.Replace('$$_貸方税区分_$$'	, '')
						.Replace('$$_貸方金額_$$'	, '');
				}*/
			// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
			}
			oneAccCsv += csvLine;
		} // for (Integer i = 0; i < maxLoopSize; i++)
        // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
	    // サビース料個別出力の場合、サビース料（税抜き）情報はCSVへ反映を行う
	    if (isOutServiceFlg && amountServiceNoTax > 0) {
	        // サビース料合計値を加算する　
	        rightAmount += CommUtils.nullToIntZero(amountServiceNoTax);
	        // サビース料勘定科目情報を取得する
	        KanjoKamoku__c serviceKankoMst = null;
	        if (pKanjoKamokuMstMap.containsKey(pCcInfo.serviceRkanjoCode)) serviceKankoMst = pKanjoKamokuMstMap.get(pCcInfo.serviceRkanjoCode).clone(false,true);
	        if (serviceKankoMst == null) serviceKankoMst = new KanjoKamoku__c();
	        if (ttendSize > tranSize) {
	            // 指定行目のCSV情報を取得、該当CSV情報を入替えする
	            oneAccCsv = getTaxCsvLine(oneAccCsv, amountServiceNoTax, serviceKankoMst, true);
	        } else {
	            // 右側の行目は多い場合、新規行目を出力追加する
	            oneAccCsv += getTaxCsvLine(csvTemplate, amountServiceNoTax, serviceKankoMst, true);
	        }
	        // 右の明細行を一行追加を行う
	        tranSize++;
	    }
        // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
        // 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH BEGIN
        if(isOutSpecialTaxFlg && specialTax > 0){
        	// 特別税合計値を加算する　
	        rightAmount += CommUtils.nullToIntZero(specialTax);
	        // 特別税勘定科目情報を取得する
	        KanjoKamoku__c specialTaxKankoMst = null;
	        if (pKanjoKamokuMstMap.containsKey(pCcInfo.specialTaxRkanjoCode)) specialTaxKankoMst = pKanjoKamokuMstMap.get(pCcInfo.specialTaxRkanjoCode).clone(false,true);
	        if (specialTaxKankoMst == null) specialTaxKankoMst = new KanjoKamoku__c();
	        if (ttendSize > tranSize) {
	            // 指定行目のCSV情報を取得、該当CSV情報を入替えする
	            oneAccCsv = getTaxCsvLine(oneAccCsv, specialTax, specialTaxKankoMst, true);
	        } else {
	            // 右側の行目は多い場合、新規行目を出力追加する
	            oneAccCsv += getTaxCsvLine(csvTemplate, specialTax, specialTaxKankoMst, true);
	        }
	        // 右の明細行を一行追加を行う
	        tranSize++;
        }
        // 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH END
		// 消費税情報はCSVへ反映する
		KanjoKamoku__c kankoMst = pKanjoKamokuMstMap.get(pCcInfo.taxKanjoCode);
		if (kankoMst == null) kankoMst = new KanjoKamoku__c();
		// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
		//Decimal taxPayAmount = amountIncTax - amountNoTax;
		Decimal taxPayAmount = amountIncTax - amountNoTax - amountServiceNoTax;
		// 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH BEGIN
		if(isOutSpecialTaxFlg) taxPayAmount -= specialTax;
		// 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH END
		// 消費税情報出力を行う
        if (taxPayAmount > 0) {
			// 支払情報行数 > 会計明細行数の場合、会計明細の次の行に設定を行う
			if (ttendSize > tranSize) {
				// 既存の情報から入り替えする
				oneAccCsv = getTaxCsvLine(oneAccCsv, taxPayAmount, kankoMst);
			} else {
				// 新行目に消費税情報を作成する
				oneAccCsv += getTaxCsvLine(csvTemplate, taxPayAmount, kankoMst);
			}
        }
        // 残り部分は全部クリアを行う
        KanjoKamoku__c clearKankoMst = new KanjoKamoku__c();
        oneAccCsv = getTaxCsvLine(oneAccCsv, 0, clearKankoMst);
        // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
// 2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする BEGIN
rightAmount += CommUtils.nullToIntZero(taxPayAmount);
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
	// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
	private String getTaxCsvLine(String csvTemplate, Decimal taxAmount, KanjoKamoku__c kankoMst) {
	    return getTaxCsvLine(csvTemplate, taxAmount, kankoMst, false);
	}
	// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
	private String getTaxCsvLine(String csvTemplate, Decimal taxAmount, KanjoKamoku__c kankoMst, Boolean isRepFirst) {
		String csv = csvTemplate
					.Replace('$$_借方科目コード_$$'	,'')
					.Replace('$$_借方補助コード_$$'	,'')
					.Replace('$$_借方税区分_$$'	,'')
					.Replace('$$_借方金額_$$'	,'0');
	   // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
	   if (isRepFirst) {
           csv = csv
                    // 消費税情報を設定する
                    .ReplaceFirst('\\$\\$_貸方科目コード_\\$\\$'  , CommUtils.nullToBlank(kankoMst.KanjocodeCode__c))
                    .ReplaceFirst('\\$\\$_貸方補助コード_\\$\\$'  , CommUtils.nullToBlank(kankoMst.KanjoHojocode__c))
                    .ReplaceFirst('\\$\\$_貸方税区分_\\$\\$'     , CommUtils.nullToBlank(kankoMst.CreditTaxKbn__c))
                    .ReplaceFirst('\\$\\$_貸方金額_\\$\\$'      , String.valueOf(taxAmount.intValue()));      
	   } else {
	       csv = csv
					// 消費税情報を設定する
					.Replace('$$_貸方科目コード_$$'	, CommUtils.nullToBlank(kankoMst.KanjocodeCode__c))
					.Replace('$$_貸方補助コード_$$'	, CommUtils.nullToBlank(kankoMst.KanjoHojocode__c))
					.Replace('$$_貸方税区分_$$'		, CommUtils.nullToBlank(kankoMst.CreditTaxKbn__c))
					.Replace('$$_貸方金額_$$'		, String.valueOf(taxAmount.intValue()));
	   }
		// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
		return csv;
	}
	
	private String getSingAccCsvTemplate(AccountAcount__c acc, Integer startNo, String CsvTemplate, Boolean isDespoistFlg) {
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
			String SingAccCsvTemplate = CsvTemplate
										.Replace('$$_摘要_$$'		, simpleCommnt)
										.Replace('$$_伝票番号_$$'		, String.valueOf(startNo));
			return SingAccCsvTemplate;
	}
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
								.Replace('$$_Ver_$$'			, pCcInfo.ver)
								.Replace('$$_伝票日付_$$'			, accs[0].frs__r.Name)
								.Replace('$$_借方部門コード_$$'	, pCcInfo.debdepartcode)
								.Replace('$$_借方消費税額_$$'		, pCcInfo.debconsumptax)
								.Replace('$$_貸方部門コード_$$'	, pCcInfo.credepartcode)
								.Replace('$$_貸方消費税額_$$'		, pCcInfo.creconsumptax)
								.Replace('$$_入力プログラム区分_$$'	, pCcInfo.inputprogramkbn);
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
										,PaymentInfoRef__r.TTendRef__r.CardTypeLst__c
										,PaymentInfoRef__r.TTendRef__r.CouponTypeLst__c
										,PaymentInfoRef__r.Tran1Ref__c					// 会計明細
										,PaymentInfoRef__r.Tran1Ref__r.Field41__c		// 利用金額（税込み）
										,PaymentInfoRef__r.Tran1Ref__r.Field40__c		// 数量
										,PaymentInfoRef__r.Tran1Ref__r.GoukeinoneTax__c	// $合計金額（税抜）
                                        // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
                                        ,PaymentInfoRef__r.Tran1Ref__r.Field20__c
                                        ,PaymentInfoRef__r.Tran1Ref__r.TaxRate__c
                                        ,PaymentInfoRef__r.Tran1Ref__r.ServiceRate__c
                                        ,PaymentInfoRef__r.Tran1Ref__r.Field21__c
                                        ,PaymentInfoRef__r.Tran1Ref__r.UnitPriceDefKbCal__c
                                        // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
                                        // 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH BEGIN
                                        ,PaymentInfoRef__r.Tran1Ref__r.ActionType__c
                                        ,PaymentInfoRef__r.Tran1Ref__r.SpecialTax__c
                                        ,PaymentInfoRef__r.Tran1Ref__r.ParentTran1Ref__c
                                        // 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH END
										,PaymentInfoRef__r.Tran1Ref__r.Field7__c
										,PaymentInfoRef__r.Tran1Ref__r.Field7__r.KanjoKamokuRef__r.Kanjocode__c
		 								,PaymentInfoRef__r.Tran1Ref__r.Field7__r.KanjoKamokuRef__r.KanjocodeCode__c			// 会計科目コード
		 								,PaymentInfoRef__r.Tran1Ref__r.Field7__r.KanjoKamokuRef__r.KanjoHojocode__c			// 補助科目コード
		 								,PaymentInfoRef__r.Tran1Ref__r.Field7__r.KanjoKamokuRef__r.DebitTaxKbn__c
		 								,PaymentInfoRef__r.Tran1Ref__r.Field7__r.KanjoKamokuRef__r.CreditTaxKbn__c
		 								,PaymentInfoRef__r.PaymentType__c
										from PaymentDetail__c where AccountAcountRef__c in :accIdsSet 
										// 前受付金は先に表示[前受付金の場合、TTendRef__cはNULL]
										Order By AccountAcountRef__c, PaymentInfoRef__r.TTendRef__c, Name]) {
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
				//Integer taxOuputLineNum = tranSize;	// 消費税出力行目[会計明細の次の行目から出力する]
				Decimal amountIncTax = 0;	// 税込み合計金額
				Decimal amountNoTax  = 0;	// 税抜き合計金額
				// 消費税列の情報は最後に新規行目追加を行う標識フラグ
				// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
				//Boolean isAddTaxInNewLine = true;
				Decimal amountServiceNoTax = 0;         // サビース料税抜き合計金額
                Integer ttendOutSize = 0;            // 会計支払明細の最大行数
                Integer trandOutSize = 0;            // 会計明細の最大行数
                Integer currRowIdx = 0;                 // 現在処理の行目番号
				// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
				// 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH BEGIN
				Decimal specialTax = 0;
				// 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH END
				// 該当会計の消費税行表記済フラグ
				//Integer tranIsEmptyLineNo = 0;
				String SingAccCsvTemplate = getSingAccCsvTemplate(acc, startNo, CsvTemplate, false);
//2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする BEGIN
Integer leftAmount = 0, rightAmount = 0;
//2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする END
				// 支払情報と会計明細両方共出力完了の場合、該当会計のCSV出力完了
				while (true) {
				    // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
				    currRowIdx++;
				    // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
					Ttend__c ttend = null;
					Tran1__c ttran = null;	// 前受付金の残金の場合、自動作成の支払情報格納用変数
					
					// 支払情報を取得する
					PaymentDetail__c ttendPay = null;
					if (ttends.isEmpty()) ttendPay = new PaymentDetail__c();
					else ttendPay = ttends[0];
					
					// 会計支払明細情報が存在する場合
					if (ttendPay.Id != null) {
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
						// 注意：支払メデイアは売掛金の場合、補助科目に、会計関連の取引先のID__C項目のコード取得して、設定する
						// 関連の商品情報が存在する場合、関連の支払情報の会計科目設定情報により、CSVへ出力する
						// 支払情報に対して、関連の支払商品がなかったの場合、XML設定情報により、関連の会計商品情報を取得する
						if (ttend.PayProductRef__c == null) {
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
							if (ttendAccMst.KanjoKamokuRef__r.Kanjocode__c != kankoMst.Kanjocode__c) {
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
                        // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
                        ttendOutSize++;
                        // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
					} // if (ttendPay.Id != null)
					else {
						ttend = new Ttend__c();
					}
					
					// 利用明細
					// 会計支払で自動作成の架空会計明細がない場合
					Boolean transIsEmpty = false;   // 会計明細全部出力済みフラグ：TRUE：出力済み
					if (ttran == null) {
						if (trans.isEmpty()) {
						    ttran = new Tran1__c();
						    transIsEmpty = true;
						}
						else ttran = trans[0];
						//if (trans.isEmpty()) tranIsEmptyLineNo++;	// 会計明細は全部出力後、関連の行NOを計算する
					}
					// 該当行目の支払情報を出力する
					// 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH BEGIN
					if(isOutSpecialTaxFlg){
						// 集计普通会计明细
						if(ttran.ParentTran1Ref__c == null) specialTax += CommUtils.nullToZero(ttran.SpecialTax__c);
					}
					// 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH END
					// CSVの左側の支払情報を作成する
					// １行目のCSV出力情報初期化設定[1会計単位]
					String csvLine = SingAccCsvTemplate;
					// CSV出力を行う【預かり金額】
					Decimal paymentAmount = Commutils.nullToZero(ttend.Field19__c);
					
					csvLine = csvLine
						.Replace('$$_借方科目コード_$$'	, CommUtils.nullToBlank(ttend.PayProductRef__r.KanjoKamokuRef__r.KanjocodeCode__c))
						.Replace('$$_借方補助コード_$$'	, CommUtils.nullToBlank(ttend.PayProductRef__r.KanjoKamokuRef__r.KanjoHojocode__c))
						.Replace('$$_借方税区分_$$'		, CommUtils.nullToBlank(ttend.PayProductRef__r.KanjoKamokuRef__r.DebitTaxKbn__c))
						.Replace('$$_借方金額_$$'			, String.valueOf(paymentAmount.intValue()));
					
					// 右側のCSV出力情報を取得する
					// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
					//if (tranIsEmptyLineNo != 1) {	// tranIsEmptyLineNo == 1 の場合、交換文字列処理なし、後で交換を行う
					if (!transIsEmpty) {
				    // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
						csvLine = csvLine
							.Replace('$$_貸方科目コード_$$'	, CommUtils.nullToBlank(ttran.Field7__r.KanjoKamokuRef__r.KanjocodeCode__c))
							.Replace('$$_貸方補助コード_$$'	, CommUtils.nullToBlank(ttran.Field7__r.KanjoKamokuRef__r.KanjoHojocode__c))
							.Replace('$$_貸方税区分_$$'		, CommUtils.nullToBlank(ttran.Field7__r.KanjoKamokuRef__r.CreditTaxKbn__c));
						// 実際の会計明細の場合
						if (ttran.Id != null) {
						    // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
						 	//csvLine = csvLine
						 	//	.Replace('$$_貸方金額_$$'			, String.valueOf(CommUtils.nullToZero(ttran.GoukeinoneTax__c).intValue()));
						 	decimal locTanNoTax = CommUtils.nullToZero(ttran.GoukeinoneTax__c);
						 	// サビース料税抜きと売上金額（税抜き）を計算する
                            List<Decimal> wkLocTanNoTax = calServiceAmount(locTanNoTax, ttran);
                            locTanNoTax = wkLocTanNoTax[0];
                            amountServiceNoTax += wkLocTanNoTax[1];
                            csvLine = csvLine
                              .Replace('$$_貸方金額_$$'           , String.valueOf(CommUtils.nullToZero(locTanNoTax).intValue()));
						 	// 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH BEGIN
						 	// 実際利用金額	
						 	// amountIncTax += CommUtils.nullToZero(ttran.Field41__c);
						 	// 处理planBreakDown項目商品种别为室料的明细, 进行合計金額（税込:サービス込）等的处理
						 	// wkAmountIncTax[0] => 合計金額（税込:サービス込）包含特别税【不符合以上条件的返回默认值:CommUtils.nullToZero(tran.Field41__c)】
						 	// wkAmountIncTax[1] => 该明细处理后的特别税【不符合以上条件的返回默认值: 0】
						 	List<Decimal> wkAmountIncTax = getAmountIncTax(CommUtils.nullToZero(ttran.Field41__c), ttran, 0);
						 	amountIncTax += wkAmountIncTax[0];
						 	specialTax += wkAmountIncTax[1];
						 	// 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH END
						 	//amountNoTax  += CommUtils.nullToZero(ttran.GoukeinoneTax__c);
						 	amountNoTax  += locTanNoTax;
						 	
// 2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする BEGIN
//rightAmount += CommUtils.nullToIntZero(ttran.GoukeinoneTax__c);
                            rightAmount += CommUtils.nullToIntZero(locTanNoTax);
// 2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする END
                            // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
						} 
						// 表示ため仮作成の会計明細
						else {
						 	csvLine = csvLine
						 		.Replace('$$_貸方金額_$$'			, String.valueOf(CommUtils.nullToZero(ttran.Field23__c).intValue()));
// 2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする BEGIN
rightAmount += CommUtils.nullToIntZero(ttran.Field23__c);
// 2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする END
						}
					// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
					/*
					} else {
						// 該当行目に消費税情報を出力する
						isAddTaxInNewLine = false;
						*/
					   trandOutSize++;
					// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
					}
					// 
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
                // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
                // サビース料個別出力の場合、サビース料（税抜き）情報はCSVへ反映を行う
                if (isOutServiceFlg && amountServiceNoTax > 0) {
                    // サビース料合計値を加算する　
                    rightAmount += CommUtils.nullToIntZero(amountServiceNoTax);
                    // サビース料勘定科目情報を取得する
                    KanjoKamoku__c serviceKankoMst = null;
                    if (pKanjoKamokuMstMap.containsKey(pCcInfo.serviceRkanjoCode)) serviceKankoMst = pKanjoKamokuMstMap.get(pCcInfo.serviceRkanjoCode).clone(false,true);
                    if (serviceKankoMst == null) serviceKankoMst = new KanjoKamoku__c();
                    if (ttendOutSize > trandOutSize) {
                        // 指定行目のCSV情報を取得、該当CSV情報を入替えする
                        oneAccCsv = getTaxCsvLine(oneAccCsv, amountServiceNoTax, serviceKankoMst, true);
                    } else {
                        // 右側の行目は多い場合、新規行目を出力追加する
                        oneAccCsv += getTaxCsvLine(SingAccCsvTemplate, amountServiceNoTax, serviceKankoMst, true);
                    }
                    // 右側出力行目は１行増える
                    trandOutSize++;
                }
                // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
                // 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH BEGIN
                // 特別税個別出力の場情報はCSVへ反映を行う
                if (isOutSpecialTaxFlg && specialTax > 0) {
                	// 特別税合計値を加算する
                	rightAmount += CommUtils.nullToIntZero(specialTax);
                	// 特別税勘定科目情報を取得する
                	KanjoKamoku__c specialTaxKankoMst = null;
                	if (pKanjoKamokuMstMap.containsKey(pCcInfo.specialTaxRkanjoCode)) specialTaxKankoMst = pKanjoKamokuMstMap.get(pCcInfo.specialTaxRkanjoCode).clone(false,true);
                	if (specialTaxKankoMst == null) specialTaxKankoMst = new KanjoKamoku__c();
                	if (ttendOutSize > trandOutSize) {
                		// 指定行目のCSV情報を取得、該当CSV情報を入替えする
                		oneAccCsv = getTaxCsvLine(oneAccCsv, specialTax, specialTaxKankoMst, true);
                	} else {
                		// 右側の行目は多い場合、新規行目を出力追加する
                		oneAccCsv += getTaxCsvLine(SingAccCsvTemplate, specialTax, specialTaxKankoMst, true);
                	}
                	// 右側出力行目は１行増える
                	trandOutSize++;
                }
                // 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH END
				// 消費税情報はCSVへ反映する
				// 2018/05/02 NullPoint Error BugFix Beging
				//KanjoKamoku__c kankoMst = pKanjoKamokuMstMap.get(pCcInfo.taxKanjoCode).clone(false,true);
				//if (kankoMst == null) kankoMst = new KanjoKamoku__c();
				KanjoKamoku__c kankoMst = pKanjoKamokuMstMap.containsKey(pCcInfo.taxKanjoCode) 
										? pKanjoKamokuMstMap.get(pCcInfo.taxKanjoCode).clone(false,true)
										: new KanjoKamoku__c();
				// 2018/05/02 NullPoint Error BugFix End
				// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
				//Decimal taxPayAmount = amountIncTax - amountNoTax;
				Decimal taxPayAmount = amountIncTax - amountNoTax - amountServiceNoTax;
				// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
				// 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH BEGIN
				if(isOutSpecialTaxFlg) taxPayAmount -= specialTax;
				// 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH END
// 2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする BEGIN
rightAmount += CommUtils.nullToIntZero(taxPayAmount);
// 2016/01/18 左の借方金額は右側の金額と合わない場合、チェックする END
				// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
				//if (!isAddTaxInNewLine) {
				if (taxPayAmount > 0) {
					if (ttendOutSize > trandOutSize) {
					// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
						// 既存の情報から入り替えする
						oneAccCsv = getTaxCsvLine(oneAccCsv, taxPayAmount, kankoMst, true);
					} else {
						// 新行目に消費税情報を作成する
						oneAccCsv += getTaxCsvLine(SingAccCsvTemplate, taxPayAmount, kankoMst, true);
					}
				}
				// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
                // 残り部分は全部クリアを行う
                KanjoKamoku__c clearKankoMst = new KanjoKamoku__c();
                oneAccCsv = getTaxCsvLine(oneAccCsv, 0, clearKankoMst);
                // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
				// 該当会計のCSV情報をマージする
				csvBody += oneAccCsv;
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
		// 返金の左会計科目は　前受金「リスト残」で出力する
		String csv = '';
		String SingAccCsvTemplate = getSingAccCsvTemplate(acc, startNo, CsvTemplate, false);
		String paymentAmount = String.valueOf(math.abs(CommUtils.nullToIntZero(ttendPay.DepositAmount__c)));
		
		csv = SingAccCsvTemplate
				.Replace('$$_借方科目コード_$$'	,CommUtils.nullToBlank(kankoMstL.KanjocodeCode__c))
				.Replace('$$_借方補助コード_$$'	,CommUtils.nullToBlank(kankoMstL.KanjoHojocode__c))
				.Replace('$$_借方税区分_$$'		,CommUtils.nullToBlank(kankoMstL.CreditTaxKbn__c))
				.Replace('$$_借方金額_$$'			,paymentAmount)
				// 消費税情報を設定する
				.Replace('$$_貸方科目コード_$$'	,CommUtils.nullToBlank(kankoMstR.KanjocodeCode__c))
				.Replace('$$_貸方補助コード_$$'	,CommUtils.nullToBlank(kankoMstR.KanjoHojocode__c))
				.Replace('$$_貸方税区分_$$'		,CommUtils.nullToBlank(kankoMstR.CreditTaxKbn__c))
				.Replace('$$_貸方金額_$$'			,paymentAmount);	
		
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
					.Replace('$$_借方科目コード_$$'	,CommUtils.nullToBlank(kankoMstR.KanjocodeCode__c))
					.Replace('$$_借方補助コード_$$'	,CommUtils.nullToBlank(kankoMstR.KanjoHojocode__c))
					.Replace('$$_借方税区分_$$'		,CommUtils.nullToBlank(kankoMstR.CreditTaxKbn__c))
					.Replace('$$_借方金額_$$'			,paymentAmount)
					// 消費税情報を設定する
					.Replace('$$_貸方科目コード_$$'	,CommUtils.nullToBlank(kankoMstL.KanjocodeCode__c))
					.Replace('$$_貸方補助コード_$$'	,CommUtils.nullToBlank(kankoMstL.KanjoHojocode__c))
					.Replace('$$_貸方税区分_$$'		,CommUtils.nullToBlank(kankoMstL.CreditTaxKbn__c))
					.Replace('$$_貸方金額_$$'			,paymentAmount);	
		} else {
		// CSV出力内容を整合する
			csv = SingAccCsvTemplate
					.Replace('$$_借方科目コード_$$'	,CommUtils.nullToBlank(kankoMstL.KanjocodeCode__c))
					.Replace('$$_借方補助コード_$$'	,CommUtils.nullToBlank(kankoMstL.KanjoHojocode__c))
					.Replace('$$_借方税区分_$$'		,CommUtils.nullToBlank(kankoMstL.CreditTaxKbn__c))
					.Replace('$$_借方金額_$$'			,paymentAmount)
					// 消費税情報を設定する
					.Replace('$$_貸方科目コード_$$'	,CommUtils.nullToBlank(kankoMstR.KanjocodeCode__c))
					.Replace('$$_貸方補助コード_$$'	,CommUtils.nullToBlank(kankoMstR.KanjoHojocode__c))
					.Replace('$$_貸方税区分_$$'		,CommUtils.nullToBlank(kankoMstR.CreditTaxKbn__c))
					.Replace('$$_貸方金額_$$'			,paymentAmount);
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
		String depositQuery = 'select name,Kamoku__c,depositamount__c,deposititem__c,ShopCode__c,Reldeposit__r.Name from deposit__c where Reldeposit__c = :gRsvAccoutId ';
		if(!CommUtils.isBlank(gShopCode)){
		 	depositQuery += ' And ShopInfoRef__r.ShopCode__c = :gShopCode ';
		}
		List<deposit__c> deposits = DataBase.query(depositQuery);
		//  出金情報
		String paymentQuery = 'select name,Pkamoku__c,Pamount__c,Pitem__c,ShopCode__c,Relpayment__r.Name from Paymentslip__c where Relpayment__c = :gRsvAccoutId ';
		if(!CommUtils.isBlank(gShopCode)){
		 	paymentQuery += ' And ShopInfoRef__r.ShopCode__c = :gShopCode ';
		}
		List<Paymentslip__c> paymentSlips = DataBase.query(paymentQuery);
		// 一行CSV出力のテンプレート
		String SingCsvTemplate = CONST_CSVDATA_TEMPLATE
							.Replace('$$_Ver_$$' 			, ccInfo.ver)
							.Replace('$$_借方部門コード_$$'	, ccInfo.debdepartcode)
							.Replace('$$_借方消費税額_$$'		, ccInfo.debconsumptax)
							.Replace('$$_貸方部門コード_$$'	, ccInfo.credepartcode)
							.Replace('$$_貸方消費税額_$$'		, ccInfo.creconsumptax)
							.Replace('$$_入力プログラム区分_$$'	, ccInfo.inputprogramkbn);
		String csvBody = '';
		
		for (deposit__c deposit : deposits) {


			String kanjoIn = ccInfo.cashInputInMap.get(deposit.Kamoku__c);
			String kanjoOu = ccInfo.cashInputOuMap.get(deposit.Kamoku__c);
			KanjoKamoku__c kanjoInOb = kanjoKamokuMstMap.get(kanjoIn);
			if (kanjoInOb == null) kanjoInOb = new KanjoKamoku__c();
			KanjoKamoku__c kanjoOuOb = kanjoKamokuMstMap.get(kanjoOu);
			if (kanjoOuOb == null) kanjoOuOb = new KanjoKamoku__c();
			
			Decimal payAmount = Commutils.nullToZero(deposit.depositamount__c);
			
			csvBody += SingCsvTemplate
							.Replace('$$_伝票番号_$$'			, String.valueOf(ccInfo.startno))
							.Replace('$$_伝票日付_$$' 		, deposit.Reldeposit__r.Name)
							.Replace('$$_借方科目コード_$$' 	, CommUtils.nullToBlank(kanjoInOb.KanjocodeCode__c))
							.Replace('$$_借方補助コード_$$' 	, CommUtils.nullToBlank(kanjoInOb.KanjoHojocode__c))
							.Replace('$$_借方税区分_$$' 		, CommUtils.nullToBlank(kanjoInOb.DebitTaxKbn__c))
							.Replace('$$_借方金額_$$' 		, String.valueOf(payAmount.intValue()))
							.Replace('$$_貸方科目コード_$$' 	, CommUtils.nullToBlank(kanjoOuOb.KanjocodeCode__c))
							.Replace('$$_貸方補助コード_$$' 	, CommUtils.nullToBlank(kanjoOuOb.KanjoHojocode__c))
							.Replace('$$_貸方税区分_$$' 		, CommUtils.nullToBlank(kanjoOuOb.CreditTaxKbn__c))
							.Replace('$$_貸方金額_$$' 		, String.valueOf(payAmount.intValue()))
							.Replace('$$_摘要_$$' 			, CommUtils.nullToBlank(deposit.deposititem__c));
			// 伝票番号設定する
			ccInfo.startno++;
		}
		

		for (Paymentslip__c payMent : paymentSlips) {

			String kanjoIn = ccInfo.cashOutputInMap.get(payMent.Pkamoku__c);
			String kanjoOu = ccInfo.cashOutputOuMap.get(payMent.Pkamoku__c);
			KanjoKamoku__c kanjoInOb = kanjoKamokuMstMap.get(kanjoIn);
			if (kanjoInOb == null) kanjoInOb = new KanjoKamoku__c();
			KanjoKamoku__c kanjoOuOb = kanjoKamokuMstMap.get(kanjoOu);
			if (kanjoOuOb == null) kanjoOuOb = new KanjoKamoku__c();
			
			Decimal payAmount = Commutils.nullToZero(payMent.Pamount__c);
			
			csvBody += SingCsvTemplate
							.Replace('$$_伝票日付_$$' 		, payMent.Relpayment__r.Name)
							.Replace('$$_伝票番号_$$'			, String.valueOf(ccInfo.startno))
							.Replace('$$_借方科目コード_$$' 	, CommUtils.nullToBlank(kanjoInOb.KanjocodeCode__c))
							.Replace('$$_借方補助コード_$$' 	, CommUtils.nullToBlank(kanjoInOb.KanjoHojocode__c))
							.Replace('$$_借方税区分_$$' 		, CommUtils.nullToBlank(kanjoInOb.DebitTaxKbn__c))
							.Replace('$$_借方金額_$$' 		, String.valueOf(payAmount.intValue()))
							.Replace('$$_貸方科目コード_$$' 	, CommUtils.nullToBlank(kanjoOuOb.KanjocodeCode__c))
							.Replace('$$_貸方補助コード_$$'	, CommUtils.nullToBlank(kanjoOuOb.KanjoHojocode__c))
							.Replace('$$_貸方税区分_$$' 		, CommUtils.nullToBlank(kanjoOuOb.CreditTaxKbn__c))
							.Replace('$$_貸方金額_$$' 		, String.valueOf(payAmount.intValue()))
							.Replace('$$_摘要_$$' 			, CommUtils.nullToBlank(payMent.Pitem__c));
			// 伝票番号設定する
			ccInfo.startno++;
		}
		return csvBody;
	}
	
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
				// 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH BEGIN
				// ,DepositAmount__c		= CommUtils.nullToZero(tran.Field41__c)
				,DepositAmount__c		= getAmountIncTax(CommUtils.nullToZero(tran.Field41__c), tran, 1)[0]
				// 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH END
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
					// 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH BEGIN
					// 該当会計の利用総金額を合計する
					// usedAmount += tran.Field41__c;
					usedAmount += getAmountIncTax(CommUtils.nullToZero(tran.Field41__c), tran, 2)[0];
					// 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH END
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
					// 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH BEGIN
					// 該当会計の利用総金額を合計する
					// usedAmount += tran.Field41__c;
					usedAmount += getAmountIncTax(CommUtils.nullToZero(tran.Field41__c), tran, 3)[0];
					// 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH END
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
    /**
	* PCA連携定義情報のParse
	**/
	private ConvertXmlConfig getConvertXml(String shopCode){

		ConvertXmlConfig xmlConfig = new ConvertXmlConfig();
		// XML NAME
        String docName = 'SyncFieldConvertConfig';
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
   	 			xmlConfig.ver = CommUtils.nullToBlank(verField.getText()).deleteWhitespace();
   	 			Dom.XmlNode startnoField = nodePacField.getChildElement('STARTNO', null);
   	 			xmlConfig.startno = CommUtils.nullToIntZero(startnoField.getText().deleteWhitespace());
   	 			Dom.XmlNode calculationkbnField = nodePacField.getChildElement('CALCULATIONKBN', null);
   	 			xmlConfig.calculationkbn = CommUtils.nullToBlank(calculationkbnField.getText()).deleteWhitespace();
   	 			Dom.XmlNode journalkbnField = nodePacField.getChildElement('JOURNALKBN', null);
   	 			xmlConfig.journalkbn = CommUtils.nullToBlank(journalkbnField.getText()).deleteWhitespace();
   	 			Dom.XmlNode manageaccjoukbnField = nodePacField.getChildElement('MANAGEACCJOUKBN', null);
   	 			xmlConfig.manageaccjoukbn = CommUtils.nullToBlank(manageaccjoukbnField.getText()).deleteWhitespace();
   	 			Dom.XmlNode debdepartcodeField = nodePacField.getChildElement('DEBDEPARTCODE', null);
   	 			xmlConfig.debdepartcode = CommUtils.nullToBlank(debdepartcodeField.getText()).deleteWhitespace();
   	 			Dom.XmlNode debconsumptaxField = nodePacField.getChildElement('DEBCONSUMPTAX', null);
   	 			xmlConfig.debconsumptax = CommUtils.nullToBlank(debconsumptaxField.getText()).deleteWhitespace();
   	 			Dom.XmlNode credepartcodeField = nodePacField.getChildElement('CREDEPARTCODE', null);
   	 			xmlConfig.credepartcode = CommUtils.nullToBlank(credepartcodeField.getText()).deleteWhitespace();
   	 			Dom.XmlNode creconsumptaxField = nodePacField.getChildElement('CRECONSUMPTAX', null);
   	 			xmlConfig.creconsumptax = CommUtils.nullToBlank(creconsumptaxField.getText()).deleteWhitespace();
   	 			Dom.XmlNode inputprogramkbnField = nodePacField.getChildElement('INPUTPROGRAMKBN', null);
   	 			xmlConfig.inputprogramkbn = CommUtils.nullToBlank(inputprogramkbnField.getText()).deleteWhitespace();
   	 		}
   	 		Dom.XmlNode nodePcaTax = nodePca.getChildElement('PCA_TAX', null);
   	 		if (nodePcaTax != null) {
   	 		    Dom.XmlNode kanjocodeField = nodePcaTax.getChildElement('KANJOCODE', null);
   	 		    xmlConfig.taxKanjoCode = CommUtils.nullToBlank(kanjocodeField.getText()).deleteWhitespace();
   	 		}
   	 		Dom.XmlNode nodePcaadvpayL = nodePca.getChildElement('PCA_ADVPAY_L', null);
   	 		if (nodePcaadvpayL != null) {
   	 		    Dom.XmlNode kanjocodeLField = nodePcaadvpayL.getChildElement('KANJOCODE', null);
   	 		    xmlConfig.advpayLKanjoCode = CommUtils.nullToBlank(kanjocodeLField.getText()).deleteWhitespace();
   	 		}
   	 		Dom.XmlNode nodePcaadvpayR = nodePca.getChildElement('PCA_ADVPAY_R', null);
   	 		if (nodePcaadvpayR != null) {
   	 		    Dom.XmlNode kanjocodeRField = nodePcaadvpayR.getChildElement('KANJOCODE', null);
   	 		    xmlConfig.advpayRKanjoCode = CommUtils.nullToBlank(kanjocodeRField.getText()).deleteWhitespace();
   	 		}
   	 		// 2015/07/09 返金：右側の会計科目
   	 		Dom.XmlNode nodePcaRefundR = nodePca.getChildElement('PCA_REFUND_R', null);
   	 		if (nodePcaRefundR != null) {
   	 		    Dom.XmlNode kanjocodeRField = nodePcaRefundR.getChildElement('KANJOCODE', null);
   	 		    xmlConfig.refundRkanjoCode = CommUtils.nullToBlank(kanjocodeRField.getText()).deleteWhitespace();
   	 		}
            // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
            // サビース料は個別出力する、しないフラグ
            xmlConfig.isOutputService = false;      
            Dom.XmlNode serviceOutputField =  nodePca.getChildElement('SERVICE_OUTPUT', null);
            if (serviceOutputField != null) {
                xmlConfig.isOutputService = Boolean.valueOf(CommUtils.nullToBlank(serviceOutputField.getText()));
            }
            // サビース料個別出力の場合、関連の勘定科目コードを設定する
            if (xmlConfig.isOutputService) {
                Dom.XmlNode nodePcaServiceR = nodePca.getChildElement('PCA_SERVICE_R', null);
                if (nodePcaServiceR != null) {
                    Dom.XmlNode kanjocodeRField = nodePcaServiceR.getChildElement('KANJOCODE', null);
                    xmlConfig.serviceRkanjoCode = CommUtils.nullToBlank(kanjocodeRField.getText()).deleteWhitespace();
                }
            }
            // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
            // 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH BEGIN
            xmlConfig.isOutputSpecialTax = false;
            Dom.XmlNode specialTaxOutputField =  nodePca.getChildElement('SPECIALTAX_OUTPUT', null);
            if (specialTaxOutputField != null) {
                xmlConfig.isOutputSpecialTax = Boolean.valueOf(CommUtils.nullToBlank(specialTaxOutputField.getText()));
            }
            // 特別税個別出力の場合、関連の勘定科目コードを設定する
            if (xmlConfig.isOutputSpecialTax) {
                Dom.XmlNode nodePcaSpecialTaxR = nodePca.getChildElement('PCA_SPECIALTAX_R', null);
                if (nodePcaSpecialTaxR != null) {
                    Dom.XmlNode kanjocodeRField = nodePcaSpecialTaxR.getChildElement('KANJOCODE', null);
                    xmlConfig.specialTaxRkanjoCode = CommUtils.nullToBlank(kanjocodeRField.getText()).deleteWhitespace();
                }
            }
            // 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH END
   	 	}

   	 	if (nodeCash != null) {
   	 	    Dom.XmlNode nodeCashInput = nodeCash.getChildElement('CASH_INPUT', null);
   	 	    if (nodeCashInput != null) {
   	 	    	for (Dom.XmlNode c1:nodeCashInput.getChildElements() ) {
   	 	    		String c1k = CommUtils.nullToBlank(c1.getChildElement('KEMOKU', null).getText()).deleteWhitespace();
   	 	    		String c1i = CommUtils.nullToBlank(c1.getChildElement('I_KANJOCODE', null).getText()).deleteWhitespace();
   	 	    		String c1o = CommUtils.nullToBlank(c1.getChildElement('O_KANJOCODE', null).getText()).deleteWhitespace();
   	 	    		xmlConfig.cashInputInMap.put(c1k, c1i);
   	 	    		xmlConfig.cashInputOuMap.put(c1k, c1o);
   	 	    	}
   	 	    }
   	 	    Dom.XmlNode nodeCashOutput = nodeCash.getChildElement('CASH_OUTPUT', null);
   	 	    if (nodeCashOutput != null) {
   	 	    	for (Dom.XmlNode c2:nodeCashOutput.getChildElements() ) {
   	 	    		String c2k = CommUtils.nullToBlank(c2.getChildElement('KEMOKU', null).getText()).deleteWhitespace();
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
						String m1cc = CommUtils.nullToBlank(convert.getChildElement('CARDNAME', null).getText()).deleteWhitespace();
	 	 				String m1ck = CommUtils.nullToBlank(convert.getChildElement('KANJOCODE', null).getText()).deleteWhitespace();
				    	xmlConfig.mediaCardMap.put(m1cc, m1ck);
					}
				} else if (m1.getName() == 'KINKEN') {
					// COVERT情報
					for (Dom.XmlNode convert:m1.getChildElements() ) {
					    String m1kk = CommUtils.nullToBlank(convert.getChildElement('KINKENNAME', null).getText()).deleteWhitespace();
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
        // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
        // サビース料勘定科目のSEQコード
        public String serviceRkanjoCode{get;set;}
        // サビース料出力する・しないフラグ
        public Boolean isOutputService{get; private set;}
        // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
        // 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH BEGIN
        // 特別税勘定科目のSEQコード
        public String specialTaxRkanjoCode{get;set;}
        // 特別税出力する・しないフラグ
        public Boolean isOutputSpecialTax{get; private set;}
        // 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH END
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
	}
    // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
    // サビース料出力する・しないフラグ
    private Boolean isOutServiceFlg = false;
    // 指定の会計明細情報により、サビース料は個別出力の場合、税抜き（サビース料抜き、
    private List<Decimal> calServiceAmount(Decimal pGoukeinoneTax, Tran1__c tran) {
        List<Decimal> ret = new List<Decimal>{pGoukeinoneTax,0};
        if (!isOutServiceFlg) return ret;
        // 該当商品はサビース料なし場合、処理中止
        if (tran.ServiceRate__c == 0) return ret;
        // サビース料計算を行う
        CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(tran.UnitPriceDefKbCal__c));
        Decimal unitPrice = CommUtils.nullToZero(tran.Field20__c);
        Decimal qty = CommUtils.nullToZero(tran.Field21__c);
        priceInfo.process( unitPrice, qty, tran.TaxRate__c, tran.ServiceRate__c);
        // サビース料存在する場合、サビース料税抜き金額を取得する
        Decimal serviceNoTax = priceInfo.priceServiceExcTax;
        if (pGoukeinoneTax > serviceNoTax) {
            ret[0] = pGoukeinoneTax - serviceNoTax;
            ret[1] = serviceNoTax;
        }
        return ret;
    }
    // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
    // 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH BEGIN
    private List<Decimal> getAmountIncTax(Decimal amountIncTax, Tran1__c tran, Decimal mode) {
    	List<Decimal> wkAmountIncTax = new List<Decimal>{amountIncTax,0}; // [0] => Field41__c, [0] => 特别税: 不满足处理条件的默认设成0
    	// 利用地址共存原理
    	Map<String, Decimal> specialTaxMap;
    	if(mode == 0) specialTaxMap = pSpecialTaxMap_0;
    	else if(mode == 1) specialTaxMap = pSpecialTaxMap_1;
    	else if(mode == 2) specialTaxMap = pSpecialTaxMap_2;
    	else if(mode == 3) specialTaxMap = pSpecialTaxMap_3;
    	// 只处理plan内, 商品处理种别是室料的会计明细
    	if (specialTaxMap == null)  return wkAmountIncTax;
    	// ps: 不是室料商品的不重新计算
    	if(!specialTaxMap.containsKey(tran.ParentTran1Ref__c)) return wkAmountIncTax;
    	// 合計金額（税込:サービス込）的处理
    	CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(tran.UnitPriceDefKbCal__c));
    	Decimal unitPrice = CommUtils.nullToZero(tran.Field20__c); // 单价
    	Decimal qty = CommUtils.nullToZero(tran.Field21__c); // 数量
    	priceInfo.process( unitPrice, qty, tran.TaxRate__c, tran.ServiceRate__c); // サービス料 
    	wkAmountIncTax[1] = specialTaxMap.get(tran.ParentTran1Ref__c); // 该明细对应的planHead的特别税
    	// 合計金額（税込:サービス込）
    	wkAmountIncTax[0] = priceInfo.priceIncTax + wkAmountIncTax[1];
    	// 一个plan只处理一次合计金額--处理完之后置成0
    	specialTaxMap.put(tran.ParentTran1Ref__c, 0);
    	return wkAmountIncTax;
    }
    // 2019/03/15 特別税金額は個別行に出力できるように改善対応 WGCH END
}