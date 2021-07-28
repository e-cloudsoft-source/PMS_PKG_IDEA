/*****************
* Freeeの連携処理
* 2015/10/14 Freeeの連携CSV出力機能の追加
* 2015/11/09 仕入情報は出力機能の追加
* 2015/12/03 CSV出力の場合、勘定科目名を出力すると、後ろからN文字を削除して、出力機能の追加
* 2015/12/04 カード手数料明細は内訳機能に出力機能の追加
* 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加
* 2015/12/10 仕入オブジェクトの種別の貸方の勘定科目指定できる様に機能対応
* 2015/03/08 販売手数料は内訳として、出力機能の対応
* 2016/03/10 借方の仮払消費税の会計科目出力機能の追加
* 2016/03/19 販売手数料の仕訳出力の場合、支払メデイアチェック外す、休日前のチェックロジックを追加する
* 2016/03/21 手数料カテゴリ１は抽出条件に追加、手数料の仕訳出力の場合、手数料支払のチェックは外す
* 2016/03/23 親関係の手数料は同時に定義されている場合、子取引先の手数料は優先で利用する
* 2016/04/21 販売手数料は内訳出力場合、手数料支払＝FALSE制御条件追加
* 2016/07/07 販売手数料とカード手数料は仕訳に出力なし、仕訳オブジェクトに情報を格納する
* 2016/09/07 支払情報の補助科目「金券種別、カード種別」出力を行う
* 2016/09/23 仕訳Rollup機能追加対応[入出金、売上]単位にRollup、仕入は単独Rollup(Rollupする・しないのはXMLのパラメータにより切替可能,デフォルト値：Rollupしない)
* 2016/10/07 仕訳Rollup機能、伝票NO設定不正の不具合修正
* 2016/10/11 支払情報の補助科目「売掛種別」
* 2016/11/21 出力金額の小数点対応できる改善
* 2016/12/13 摘要項目の後ろに請求先を表示追加対応
* 2016/12/14 漢字にカンマを含めている改善対応
* 2017/03/09 バッチ終了通知メールに支払いメディアが設定されていない、設定金額は合せないの会計データへのリンクを追加
* 2017/08/03 サビース料金額は個別行に出力できるように改善対応
* 2018/02/22 摘要欄の出力内容はカスタマイズできるように改善対応
* 2018/10/23 FREEERU出力機能改善(補助科目の出力)
* 2018/11/05 仕訳明細は税込・税抜出力選択できるように改善対応
* 2018/11/26 出金先追加に従って、出金の補助科目内容の出力内容を改善対応
* 2018/11/26 FREEE/FREEERU出力機能、入出金科目、仕入種別科目のまま明細出力できるように改善対応
* 2019/09/20 
*	仕訳明細出力する際、消費税8%と10%に行が分ける出力する対応
*	入出金消費税項目が存在場合、入出金消費税も出力する対応
* 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する
* 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応
* 2020/01/21 税額を貸方税額、借方税額に出力した際に小数点以下問題対応
* 2020/01/21 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う）
* 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）
*****************/
public with sharing class FreeeSyncCsvTemplateCtrl {
	// 2015/10/14 Freeeの連携CSV出力機能の追加 BEGIN
	//private final String csvHeaderStr = Label.INF_0004 + '\n';//'Ver,伝票日付,伝票番号,計算区分,仕訳区分,管理会計仕訳区分,借方部門コード,借方科目コード,借方科目名,借方補助コード,借方補助名,借方税区分,借方金額,借方消費税額,貸方部門コード,貸方科目コード,貸方科目名,貸方補助コード,貸方補助名,貸方税区分,貸方金額,貸方消費税額,数字1,数字2,摘要,入力プログラム区分,配賦税計算モード,配賦元集計開始日,配賦元集計終了日,配賦基準番号,配賦元部門コード,配賦元科目コード,配賦元補助コード,配賦元金額\n';
	private static final String pcaSyncCtrlCode = CommDefine__c.getOrgDefaults().AccountSoftSyncCsvType__c;
	private static final String CSV_OUTPUT_MODE_PCA = '1';
	private static final String CSV_OUTPUT_MODE_FREEE = '2';
	private static final Boolean isCsvOutModeFreee = (pcaSyncCtrlCode == CSV_OUTPUT_MODE_FREEE);
	public static final Boolean isCsvOupModePca = (pcaSyncCtrlCode == CSV_OUTPUT_MODE_PCA);
	private static final String csvHeaderStr = (isCsvOutModeFreee ? Label.INF_0005 : Label.INF_0004) + '\n';
	public boolean csvOutputIsFreeLayout{get{return isCsvOutModeFreee;}}
	// 2015/10/14 Freeeの連携CSV出力機能の追加 END
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
	// 2015/12/03 CSV出力の場合 XML定義共通化
	private ConvertXmlConfig gccInfo; 
	// 2015/12/04 カード手数料明細は内訳機能に出力機能の追加
	private final Integer gPointLen = CommUtils.getPointLen();
	// 2016/07/07 BEGIN
	private final String gShopId;
	private final String CONST_EVENTSRC_AGT = 'AGT販売手数料_FREEE';
	private final String CONST_EVENTSRC_CARD = 'CARD手数料_FREEE';
	// 2016/07/07 END
	// 2016/09/23 仕訳Rollup機能追加対応 BEGIN
	private Map<String, KanjoKamoku__c> gKanjoKamokuMstMap;
	private Integer gInitStartNo;
	// 2016/09/23 仕訳Rollup機能追加対応 END
	// ログ情報格納用
	public String msgStr{get; private set;}
	/**
	* 店舗別売上日単位のPCA連携情報を作成する
	**/
	public FreeeSyncCsvTemplateCtrl (String rsvAccId, String shopCode) {
		gRsvAccoutId = rsvAccId;
		gShopCode = shopCode;
		// 2016/07/07 BEGIN
		Map<String,ShopInformation__c> shopMap = ShopInfoUtil.getShopInfoMap();
		gShopId = (shopMap.containsKey(gShopCode) ? shopMap.get(gShopCode).Id : null);
		// 2016/07/07 END
		// 2017/03/09 バッチ終了通知メールに支払いメディアが設定されていない、設定金額は合せないの会計データへのリンクを追加 BEGIN
		msgStr = '';
		// 2017/03/09 バッチ終了通知メールに支払いメディアが設定されていない、設定金額は合せないの会計データへのリンクを追加 END
	}

	// *************************
	// CSV出力のテンプレート定義情報
	// *************************
	// 2015/10/14 Freeeの連携CSV出力機能の追加 BEGIN
	//private static final String CONST_CSVDATA_TEMPLATE='$$_Ver_$$,$$_伝票日付_$$,$$_伝票番号_$$,0,1,0,$$_借方部門コード_$$,$$_借方科目コード_$$,,$$_借方補助コード_$$,,$$_借方税区分_$$,$$_借方金額_$$,$$_借方消費税額_$$,'
	//												  +'$$_貸方部門コード_$$,$$_貸方科目コード_$$,,$$_貸方補助コード_$$,,$$_貸方税区分_$$,$$_貸方金額_$$,$$_貸方消費税額_$$,,,$$_摘要_$$,$$_入力プログラム区分_$$,,,,,,,,\n';
	private String CONST_CSVDATA_TEMPLATE= isCsvOutModeFreee 
														? ('$$_[表題行]_$$,$$_伝票日付_$$,$$_伝票番号_$$,$$_借方科目コード_$$,$$_借方補助コード_$$,$$_借方部門コード_$$,$$_借方税区分_$$,$$_借方金額_$$,$$_借方消費税額_$$,$$_貸方科目コード_$$,'
													  		+'$$_貸方補助コード_$$,$$_貸方部門コード_$$,$$_貸方税区分_$$,$$_貸方金額_$$,$$_貸方消費税額_$$,$$_摘要_$$\n')	
														: ('$$_Ver_$$,$$_伝票日付_$$,$$_伝票番号_$$,0,1,0,$$_借方部門コード_$$,$$_借方科目コード_$$,,$$_借方補助コード_$$,,$$_借方税区分_$$,$$_借方金額_$$,$$_借方消費税額_$$,'
													  		+'$$_貸方部門コード_$$,$$_貸方科目コード_$$,,$$_貸方補助コード_$$,,$$_貸方税区分_$$,$$_貸方金額_$$,$$_貸方消費税額_$$,,,$$_摘要_$$,$$_入力プログラム区分_$$,,,,,,,,\n');
	
	// 2015/10/14 Freeeの連携CSV出力機能の追加 END
	//氏名											  
	// 2016/12/13 摘要項目の後ろに請求先を表示追加対応 BEGIN
	//private static final String CONST_CSVDATA_COMMENT_TEMPLATE = '$$_COMMENTLAB_$$： $$_ROOMNO_$$   　'+Label.CONST_050_0004+'： $$_GUESTNAME_$$';
	private static final String CONST_CSVDATA_COMMENT_TEMPLATE = '$$_COMMENTLAB_$$： $$_ROOMNO_$$   　'+Label.CONST_050_0004+'： $$_GUESTNAME_$$ $$_ACCOUNTNAME_$$';
	// 2016/12/13 摘要項目の後ろに請求先を表示追加対応 END
	// 2019/12/30 FREEEAPI连携機能 WGCH BEGIN
	public Boolean isFreeePostFlg = false;
	// Key: 日付_店铺Code_云票No, Val: 对应的会计Id
	public Map<String, String> csvAccIdMap;
	public String generalCsvContent(Boolean isFreeePostFlg) {
		csvAccIdMap = new Map<String, String>();
		this.isFreeePostFlg = isFreeePostFlg;
		return generalCsvContent();
	}
	// 2019/12/30 FREEEAPI连携機能 WGCH END
	// *************************
	// CSV出力処理関数
	// テスト結果：10000件の場合、摘要：250文字：送信可能、10MB
	//          14000件の場合、摘要：50文字：送信可能、5MB
	// *************************
	public String generalCsvContent() {
		
		// 店舗別XML定義情報取得する
		ConvertXmlConfig ccInfo = getConvertXml(gShopCode); 
		// 2019/12/30 FREEEAPI连携機能 WGCH BEGIN
		if(isFreeePostFlg){
			ccInfo.isOutTaxToSameLine = false;
		}
		// 2019/12/30 FREEEAPI连携機能 WGCH END
		// 2015/12/03 CSV出力の場合 XML定義共通化
		gccInfo = ccInfo;
		// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
		isOutServiceFlg = ccInfo.isOutputService;
		// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
		// 指定店舗コードと売上IDで,指定日のPCA売上情報を抽出する
		// 関連の会計科目情報取得、格納する
		Set<String> seqNoSet = new Set<String>();
		// 利用必要の会計科目情報を一括取得
		if (!CommUtils.isBlank(ccInfo.taxKanjoCode)) seqNoSet.add(ccInfo.taxKanjoCode);
		// 2016/03/10 借方の仮払消費税の会計科目出力機能の追加 BEGIN
		if (!CommUtils.isBlank(ccInfo.taxPayKanjoCode)) seqNoSet.add(ccInfo.taxPayKanjoCode);
		// 2019/09/20 多税率機能対応 WSQ BEGIN
		for (String code : ccInfo.taxKanjoMap.values()) {seqNoSet.add(code);}
		for (String code : ccInfo.taxPayKanjoMap.values()) {seqNoSet.add(code);}
		for (String code : ccInfo.serviceRkanjoMap.values()) {seqNoSet.add(code);}
		// 2019/09/20 多税率機能対応 WSQ END
		// 2016/03/10 借方の仮払消費税の会計科目出力機能の追加 END
		if (!CommUtils.isBlank(ccInfo.advpayLKanjoCode)) seqNoSet.add(ccInfo.advpayLKanjoCode);
		if (!CommUtils.isBlank(ccInfo.advpayRKanjoCode)) seqNoSet.add(ccInfo.advpayRKanjoCode);
		if (!CommUtils.isBlank(ccInfo.refundRkanjoCode)) seqNoSet.add(ccInfo.refundRkanjoCode);
		// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
		if (!CommUtils.isBlank(ccInfo.serviceRkanjoCode)) seqNoSet.add(ccInfo.serviceRkanjoCode);
		// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
		for (String seqNo : ccInfo.cashInputInMap.values()) seqNoSet.add(seqNo);
		for (String seqNo : ccInfo.cashInputOuMap.values()) seqNoSet.add(seqNo);
		for (String seqNo : ccInfo.cashOutputInMap.values()) seqNoSet.add(seqNo);
		for (String seqNo : ccInfo.cashOutputOuMap.values()) seqNoSet.add(seqNo);
		// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応 WSQ BEGIN
		for (Map<Decimal,String> items :ccInfo.cashInputInRateKbnMap.values()) {
			for (String seqNo : items.values()) seqNoSet.add(seqNo);
		}
		for (Map<Decimal,String> items :ccInfo.cashInputOuRateKbnMap.values()) {
			for (String seqNo : items.values()) seqNoSet.add(seqNo);
		}
		for (Map<Decimal,String> items :ccInfo.cashOutputInRateKbnMap.values()) {
			for (String seqNo : items.values()) seqNoSet.add(seqNo);
		}
		for (Map<Decimal,String> items :ccInfo.cashOutputOuRateKbnMap.values()) {
			for (String seqNo : items.values()) seqNoSet.add(seqNo);
		}
		// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応 WSQ END
		// Media種別関連の会計科目情報
		for (String seqNo : ccInfo.mediaCardMap.values()) seqNoSet.add(seqNo);
		for (String seqNo : ccInfo.mediaKinkenMap.values()) seqNoSet.add(seqNo);
		// 2015/11/09 仕入情報は出力機能の追加 BEGIN
		for (String seqNo : ccInfo.purchaseInMap.values()) seqNoSet.add(seqNo);
		// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応 WSQ BEGIN
		for (Map<Decimal,String> items :ccInfo.purchaseInRateKbnMap.values()) {
			for (String seqNo : items.values()) seqNoSet.add(seqNo);
		}
		for (Map<Decimal,String> items :ccInfo.purchaseOutOfTypeRateKbnMap.values()) {
			for (String seqNo : items.values()) seqNoSet.add(seqNo);
		}
		// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応 WSQ END
		// 2015/12/10 仕入オブジェクトの種別の貸方の勘定科目指定できる様に機能対応 BEGIN
		for (String seqNo : ccInfo.purchaseOutOfTypeMap.values()) seqNoSet.add(seqNo);
		// 2015/12/10 仕入オブジェクトの種別の貸方の勘定科目指定できる様に機能対応 END
		for (String seqNo : ccInfo.purchaseOutMap.values()) seqNoSet.add(seqNo);
		// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応 WSQ BEGIN
		for (Map<Decimal,String> items :ccInfo.purchaseOutRateKbnMap.values()) {
			for (String seqNo : items.values()) seqNoSet.add(seqNo);
		}
		// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応 WSQ END
		// 2015/11/09 仕入情報は出力機能の追加 END
		// 2015/12/07 内訳出力用勘定科目の定義情報 BEGIN
		if (!CommUtils.isBlank(ccInfo.cardTesuryoSeqNo)) seqNoSet.add(ccInfo.cardTesuryoSeqNo);
		// 2015/12/07 内訳出力用勘定科目の定義情報 END
		// 販売手数料は内訳として、出力機能の対応 BEGIN
		if (!CommUtils.isBlank(ccInfo.agtTesuryoSeqNo)) seqNoSet.add(ccInfo.agtTesuryoSeqNo);
		// 販売手数料は内訳として、出力機能の対応 END
		// 2016/07/21 カード手数料・販売手数料は別行目に出力機能制御追加　BEGIN
		if (!CommUtils.isBlank(ccInfo.cardTesuryoRightSeqNo)) seqNoSet.add(ccInfo.cardTesuryoRightSeqNo);
		if (!CommUtils.isBlank(ccInfo.agtTesuryoRightSeqNo)) seqNoSet.add(ccInfo.agtTesuryoRightSeqNo);
		// 2016/07/21 カード手数料・販売手数料は別行目に出力機能制御追加　END
		// 2020/01/21 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う）WSQ BEGIN
		if (!CommUtils.isBlank(ccInfo.apLeftKanjoSeqNo)) seqNoSet.add(ccInfo.apLeftKanjoSeqNo);
		if (!CommUtils.isBlank(ccInfo.dpLeftKanjoSeqNo)) seqNoSet.add(ccInfo.dpLeftKanjoSeqNo);
		if (!CommUtils.isBlank(ccInfo.acKanjoSeqNo)) seqNoSet.add(ccInfo.acKanjoSeqNo);
		// 2020/01/21 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う）WSQ END
		// 2020/09/15 連泊の支払を入れた際の挙動修正2 WSQ BEGIN
		if (!CommUtils.isBlank(ccInfo.apRightKanjoSeqNo)) seqNoSet.add(ccInfo.apRightKanjoSeqNo);
		// 2020/09/15 連泊の支払を入れた際の挙動修正2 WSQ END
		// 会計科目基本情報を取得する
		Map<String, KanjoKamoku__c> kanjoKamokuMstMap = new Map<String, KanjoKamoku__c>();
		if (!seqNoSet.isEmpty()) {
			for (KanjoKamoku__c mst : [select id, Name, Kanjocode__c, KanjocodeCode__c, KanjoHojocode__c,KanjoHojoname__c,DebitTaxKbn__c, CreditTaxKbn__c from KanjoKamoku__c where Kanjocode__c in :seqNoSet]) {
				kanjoKamokuMstMap.put(mst.Kanjocode__c, mst);
			}
		}
		// 2016/09/23 仕訳Rollup機能追加対応 BEGIN
		gKanjoKamokuMstMap = kanjoKamokuMstMap;
		gInitStartNo = ccInfo.startno;
		// 2016/09/23 仕訳Rollup機能追加対応 END
		// 2015/11/13 会計科目名と補助科目名を出力できる対応 BEGIN
		if (isCsvOutModeFreee && !ccInfo.isCodeLayout) {
			CONST_CSVDATA_TEMPLATE = '$$_[表題行]_$$,$$_伝票日付_$$,$$_伝票番号_$$,$$_借方科目_$$,$$_借方補助_$$,$$_借方部門コード_$$,$$_借方税区分_$$,$$_借方金額_$$,$$_借方消費税額_$$,$$_貸方科目_$$,'
									+'$$_貸方補助_$$,$$_貸方部門コード_$$,$$_貸方税区分_$$,$$_貸方金額_$$,$$_貸方消費税額_$$,$$_摘要_$$\n';
		}
		// 2015/11/13 会計科目名と補助科目名を出力できる対応 END
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
		// ----------------------
		// 仕入の仕訳情報の作成(2015/11/09 仕入情報は出力機能の追加)
		// ----------------------
		csvBody += generalPurchaseCsvInfo(ccInfo, kanjoKamokuMstMap);
		
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
						+ 'relaccount__r.Account.Name, '
						+ 'relaccount__r.Name, '
						// 販売手数料は内訳として、出力機能の対応 BEGIN
						+ 'Relreserve__r.ReservedType__c, '
						+ 'Relreserve__r.Field2__c, '
						+ 'Relreserve__r.Relcontact__r.AccountId, '
						+ 'Relreserve__r.SalesOfficeInfoRef__c, '
						// 2018/02/22 摘要欄の出力内容はカスタマイズできるように改善対応 WGCH BEGIN
						+ 'Relreserve__r.SalesOfficeInfoRef__r.ParentId, ';
						for(String api : xmlFieldsMap.keySet()){
							if(leadApiSet.contains(api)) continue;
							querySQL+= api + ' ,';
						}
		 				// 会計明細
		 				querySQL+= '(Select GoukeinoneTax__c ,Field41__c,Accountoutside__c '+			// 利用金額（税込）と利用金額（税抜き）
						// 2018/02/22 摘要欄の出力内容はカスタマイズできるように改善対応 WGCH END
		 				// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
		 				    ' ,Field20__c,TaxRate__c,ServiceRate__c,Field21__c,UnitPriceDefKbCal__c'+
		 				// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
		 					' ,Field7__r.KanjoKamokuRef__r.KanjocodeCode__c '+
		 					' ,Field7__r.KanjoKamokuRef__r.Name '+
		 					' ,Field7__r.KanjoKamokuRef__r.KanjoHojocode__c '+
		 					' ,Field7__r.KanjoKamokuRef__r.KanjoHojoname__c '+
		 					' ,Field7__r.KanjoKamokuRef__r.DebitTaxKbn__c '+
		 					' ,Field7__r.KanjoKamokuRef__r.CreditTaxKbn__c '+
							// 販売手数料は内訳として、出力機能の対応 BEGIN
		 					' ,ParentTran1Ref__c,ParentTran1Ref__r.ActionType__c '+
		 					' From TranAccount__r '+
		 					// 商品種別はプランのBreakDown項目と普通の会計明細
		 					' where ActionType__c != :PROD_ACTION_TYPE_PL And ActionType__c != :PROD_ACTION_TYPE_AR  ' +
		 					//' And Accountoutside__c = 1 ' +
		 					// 請求書非表示は対象外
		 					//' And InvoiceNoShowFlg__c = false ' +
		 					// 有効な明細　OR　親が存在 AND　親は有効な明細
		 					// 2017/05/33 非表示の明細データでも出力対象に変更する BEGIN
		 					//' And ( ( InvoiceNoShowFlg__c = false And ParentTran1Ref__c = null And Accountoutside__c = 1) OR (ParentTran1Ref__c != null And ParentTran1Ref__r.Accountoutside__c = 1 And ParentTran1Ref__r.InvoiceNoShowFlg__c = false) ) ';
		 					' And ( ( ParentTran1Ref__c = null And Accountoutside__c = 1) OR (ParentTran1Ref__c != null And ParentTran1Ref__r.Accountoutside__c = 1 ) ) ';
		 					// 2017/05/33 非表示の明細データでも出力対象に変更する END
// 2015/12/04 利用金額は０の場合、明細情報を出力なし機能対応　BEGIN
		 		if (!pCcInfo.isOutputPriceZero)	querySQL+=' And GoukeinoneTax__c != 0 ';
				querySQL+=' order by rowNo__c,name),'
// 2015/12/04 利用金額は０の場合、明細情報を出力なし機能対応　END
		 					// 会計支払[Field2__c:メディア種別]
		 				+ '(Select Field2__c, Field3__c, CardTypeLst__c, PayProductName__c,CouponTypeLst__c, Field20__c, Field19__c,OutSideAccount__c ' +
		 					' ,PayProductRef__r.KanjoKamokuRef__r.KanjoHojocode__c '+
		 					' ,PayProductRef__r.KanjoKamokuRef__r.Name '+
		 					' ,PayProductRef__r.KanjoKamokuRef__r.KanjocodeCode__c '+
		 					' ,PayProductRef__r.KanjoKamokuRef__r.KanjoHojoname__c '+
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
										ConvertXmlConfig pCcInfo) {
		// 該当会計関連のCSV情報
		String oneAccCsv = '';
		// 最大LOOPサイズを取得する
		Integer ttendSize   = ttends.size();
		Integer tranSize	= trans.size();
		Integer maxLoopSize = ttendSize > tranSize ? ttendSize : tranSize;
		//Integer taxOuputLineNum = tranSize;	// 消費税出力行目[会計明細の次の行目から出力する]
		// 2019/09/20 多税率機能対応 WSQ BEGIN
		//Decimal amountIncTax = 0;	// 税込み合計金額
		//Decimal amountNoTax  = 0;	// 税抜き合計金額
		// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
		//Decimal amountServiceNoTax = 0;         // サビース料税抜き合計金額
		// map<税率，該当税率の合計金額>
		map<decimal,decimal> amountIncTaxMap = new map<decimal,decimal>(); 	// 税込み合計金額
		// map<税率，該当税率の合計金額>
		map<decimal,decimal> amountNoTaxMap = new map<decimal,decimal>(); 	// 税抜き合計金額
		// map<税率，該当税率の サビース金額>
		map<decimal,decimal> amountServiceNoTaxMap = new map<decimal,decimal>(); 	// サビース料税抜き合計金額
		// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ BEGIN
		// サビース料の消費税が出力必要場合 #9199
		map<decimal,decimal> amountServiceTaxMap = new map<decimal,decimal>(); 	// サビース料の消費税情報
		// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ END
		// 2019/09/20 多税率機能対応 WSQ END
		// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END

		for (Integer i = 0; i < maxLoopSize; i++) {
			// CSVの左側の支払情報を作成する
			// １行目のCSV出力情報初期化設定[1会計単位]
			String csvLine = csvTemplate;
			// 2016/12/13 摘要項目の後ろに請求先を表示追加対応 BEGIN
			String wkAccountName = '';
			// 2016/12/13 摘要項目の後ろに請求先を表示追加対応 END
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
				// 2016/09/07 支払情報の補助科目「金券種別、カード種別」出力を行う BEGIN
				if (accMst.KanjoKamokuRef__r != null && CommUtils.isBlank(accMst.KanjoKamokuRef__r.KanjoHojoname__c)) {
					KanjoKamoku__c kanjoKamokuWk = accMst.KanjoKamokuRef__r.clone(false,true);
					if (ttend.Field2__c == CommConst.MEDIA_TYPE_CD_02) {
						// 補助科目はカード種別項目から出力する
						kanjoKamokuWk.KanjoHojoname__c = CommUtils.nullToBlank(ttend.CardTypeLst__c);
					} else if (ttend.Field2__c == CommConst.MEDIA_TYPE_CD_11 || ttend.Field2__c == CommConst.MEDIA_TYPE_CD_12) {
						// 補助科目は金券種別項目から出力する
						kanjoKamokuWk.KanjoHojoname__c = CommUtils.nullToBlank(ttend.CouponTypeLst__c);
					}
					accMst.KanjoKamokuRef__r = kanjoKamokuWk;
				} 
				// 2016/09/07 支払情報の補助科目「金券種別、カード種別」出力を行う END
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
					// 2016/09/07 支払情報の補助科目「金券種別、カード種別」出力を行う BEGIN
					KanjoKamoku__c kanjoKamokuWk = accMst.KanjoKamokuRef__r.clone(false,true);
					// 請求先の企業コードが存在する場合、該当企業コードを補助科目コードに設定する
					if (!CommUtils.isBlank(acc.relaccount__r.Account.ID__c)) {
						kanjoKamokuWk.KanjoHojocode__c = CommUtils.nullToBlank(acc.relaccount__r.Account.ID__c);
						kanjoKamokuWk.KanjoHojoname__c = CommUtils.nullToBlank(acc.relaccount__r.Account.Name);
					}
					if (CommUtils.isBlank(kanjoKamokuWk.KanjoHojoname__c) && !Commutils.isBlank(acc.relaccount__r.Account.Name)) {
						// 補助科目はカード種別項目から出力する
						kanjoKamokuWk.KanjoHojoname__c = CommUtils.nullToBlank(acc.relaccount__r.Account.Name);
					}
					// 2016/10/11 支払情報の補助科目「売掛種別」BEGIN
					if (CommUtils.isBlank(kanjoKamokuWk.KanjoHojoname__c)) {
						// 補助科目はカード種別項目から出力する
						kanjoKamokuWk.KanjoHojoname__c = CommUtils.nullToBlank(acc.relaccount__r.Name);
					}
					// 2016/10/11 支払情報の補助科目「売掛種別」END
					accMst.KanjoKamokuRef__r = kanjoKamokuWk;
					// 2016/09/07 支払情報の補助科目「金券種別、カード種別」出力を行う END
					//accMst.KanjoKamokuRef__r.KanjoHojocode__c = CommUtils.nullToBlank(acc.relaccount__r.Account.ID__c);
				} 
				// 2016/12/13 摘要項目の後ろに請求先を表示追加対応 BEGIN
				if (ttend.Field2__c == CommConst.MEDIA_TYPE_CD_03) {
					wkAccountName = getMemoAccountNameToCsv(acc.relaccount__r);
				}
				// 2016/12/13 摘要項目の後ろに請求先を表示追加対応 END
				Decimal paymentAmount = Commutils.nullToZero(ttend.Field19__c);
				// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
				paymentAmount = formatOuputNumber(paymentAmount);
				// 2016/11/21 出力金額の小数点対応できる改善 END
				// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 BEGIN
				String debittaxkbn = CommUtils.nullToBlank(accMst.KanjoKamokuRef__r.DebitTaxKbn__c);
				if (!CommUtils.isBlank(pCcInfo.notaxkbn)) debittaxkbn = pCcInfo.notaxkbn;
				// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 END
				csvLine = csvLine
					.Replace('$$_借方科目コード_$$'	, CommUtils.nullToBlank(accMst.KanjoKamokuRef__r.KanjocodeCode__c))
					//.Replace('$$_借方科目_$$'			, CommUtils.nullToBlank(accMst.KanjoKamokuRef__r.Name))
					// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
					//.Replace('$$_借方科目_$$'			, processFilter(CommUtils.nullToBlank(accMst.KanjoKamokuRef__r.Name)))
					.Replace('$$_借方科目_$$'			, processEscapeKanji(processFilter(CommUtils.nullToBlank(accMst.KanjoKamokuRef__r.Name))))
					// 2016/12/14 漢字にカンマを含めている改善対応 END
					.Replace('$$_借方補助コード_$$'	, CommUtils.nullToBlank(accMst.KanjoKamokuRef__r.KanjoHojocode__c))
					// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
					//.Replace('$$_借方補助_$$'			, CommUtils.nullToBlank(accMst.KanjoKamokuRef__r.KanjoHojoname__c))
					.Replace('$$_借方補助_$$'			, processEscapeKanji(CommUtils.nullToBlank(accMst.KanjoKamokuRef__r.KanjoHojoname__c)))
					// 2016/12/14 漢字にカンマを含めている改善対応 END
					// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 BEGIN
					//.Replace('$$_借方税区分_$$'		, CommUtils.nullToBlank(accMst.KanjoKamokuRef__r.DebitTaxKbn__c))
					.Replace('$$_借方税区分_$$'		, debittaxkbn)
					// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 END
					// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
					//.Replace('$$_借方金額_$$'			, String.valueOf(paymentAmount.intValue()));
					.Replace('$$_借方金額_$$'			, String.valueOf(paymentAmount));
					// 2016/11/21 出力金額の小数点対応できる改善 END
// 2016/09/23 仕訳Rollup機能追加対応 BEGIN
setupRollupInfo(acc.frs__r.Name,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ BEGIN
				//processFilter(CommUtils.nullToBlank(accMst.KanjoKamokuRef__r.Name)),
				accMst.KanjoKamokuRef__r,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ END
				pCcInfo.debdepartcode,
				debittaxkbn,
				// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
				//String.valueOf(paymentAmount.intValue()),
				String.valueOf(paymentAmount),
				// 2016/11/21 出力金額の小数点対応できる改善 END
				pCcInfo.debconsumptax,
				ROLLUP_TYPE.SALES_L);
// 2016/09/23 仕訳Rollup機能追加対応 END					
			} else {
				csvLine = csvLine
						.Replace('$$_借方科目コード_$$'	,'')
						.Replace('$$_借方科目_$$'			,'')
						.Replace('$$_借方補助コード_$$'	,'')
						.Replace('$$_借方補助_$$'			,'')
						.Replace('$$_借方税区分_$$'		,'')
						.Replace('$$_借方金額_$$'			,'');
			}
			// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
			String lineTaxRateStr = '0';
			// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
			// 貸方側の会計明細情報を出力する
			if (i < tranSize) {
				Tran1__c tran = trans[i];
				Decimal tanknotax = CommUtils.nullToZero(tran.GoukeinoneTax__c);
				// 2018/11/05 仕訳明細は税込・税抜出力選択できるように改善対応 WSQ BEGIN
				if (pCcInfo.isIncTaxFlg) tanknotax = formatOuputNumber(CommUtils.nullToZero(tran.Field41__c));
				// 2018/11/05 仕訳明細は税込・税抜出力選択できるように改善対応 WSQ END
				// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
                // サビース料税抜きと売上金額（税抜き）を計算する
                List<Decimal> wkLocTanNoTax = calServiceAmount(tanknotax, tran);
                tanknotax = wkLocTanNoTax[0];
                // 2019/09/20 多税率機能対応 WSQ BEGIN
                //amountServiceNoTax += wkLocTanNoTax[1];
                decimal taxrate = CommUtils.nullToZero(tran.TaxRate__c); // 消費税率
			 	// XMLに複数率を定義されない場合、消費税、サビース料は合計格納
			 	if (pCcInfo.taxKanjoMap.isEmpty()) taxrate = CONST_SUM_TAX_RATE;
			 	if (!amountServiceNoTaxMap.containskey(taxrate)) amountServiceNoTaxMap.put(taxrate, wkLocTanNoTax[1]);
			 	else amountServiceNoTaxMap.put(taxrate, (amountServiceNoTaxMap.get(taxrate) + wkLocTanNoTax[1]));
                // 2019/09/20 多税率機能対応 WSQ END
			 	// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ BEGIN
				// サビース料の消費税が出力必要場合 #9199
				if (!pCcInfo.isIncTaxFlg && pCcInfo.isOutTaxToSameLine) {
			 		if (!amountServiceTaxMap.containskey(taxrate)) amountServiceTaxMap.put(taxrate, wkLocTanNoTax[2]);
			 		else amountServiceTaxMap.put(taxrate, (amountServiceTaxMap.get(taxrate) + wkLocTanNoTax[2]));
				}
				// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
			 	// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
			 	//lineTaxRateStr = String.valueOf(formatOuputNumber(CommUtils.nullToZero(tran.Field41__c) - tanknotax));
			 	lineTaxRateStr = String.valueOf(formatOuputNumber(CommUtils.nullToZero(tran.Field41__c) - tanknotax - wkLocTanNoTax[1] - wkLocTanNoTax[2]));
				// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ END
			 	// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
				// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
				tanknotax = formatOuputNumber(tanknotax);
				// 2016/11/21 出力金額の小数点対応できる改善 END
				csvLine = csvLine
						.Replace('$$_貸方科目コード_$$'	, CommUtils.nullToBlank(tran.Field7__r.KanjoKamokuRef__r.KanjocodeCode__c))
						//.Replace('$$_貸方科目_$$'			, CommUtils.nullToBlank(tran.Field7__r.KanjoKamokuRef__r.Name))
						// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
						//.Replace('$$_貸方科目_$$'			, processFilter(CommUtils.nullToBlank(tran.Field7__r.KanjoKamokuRef__r.Name)))
						.Replace('$$_貸方科目_$$'			, processEscapeKanji(processFilter(CommUtils.nullToBlank(tran.Field7__r.KanjoKamokuRef__r.Name))))
						// 2016/12/14 漢字にカンマを含めている改善対応 END
						.Replace('$$_貸方補助コード_$$'	, CommUtils.nullToBlank(tran.Field7__r.KanjoKamokuRef__r.KanjoHojocode__c))
						// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
						//.Replace('$$_貸方補助_$$'			, CommUtils.nullToBlank(tran.Field7__r.KanjoKamokuRef__r.KanjoHojoname__c))
						.Replace('$$_貸方補助_$$'			, processEscapeKanji(CommUtils.nullToBlank(tran.Field7__r.KanjoKamokuRef__r.KanjoHojoname__c)))
						// 2016/12/14 漢字にカンマを含めている改善対応 END
						.Replace('$$_貸方税区分_$$'		, CommUtils.nullToBlank(tran.Field7__r.KanjoKamokuRef__r.CreditTaxKbn__c))
					 	// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
					 	//.Replace('$$_貸方金額_$$'			, String.valueOf(tanknotax.intValue()));
					 	.Replace('$$_貸方金額_$$'			, String.valueOf(tanknotax));
					 	// 2016/11/21 出力金額の小数点対応できる改善 END
				// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
				if (pCcInfo.isOutTaxToSameLine) {
					csvLine = csvLine.Replace('$$_貸方消費税額_$$'		, lineTaxRateStr);
				}
				// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
// 2016/09/23 仕訳Rollup機能追加対応 BEGIN
setupRollupInfo(acc.frs__r.Name,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ BEGIN
				//processFilter(CommUtils.nullToBlank(tran.Field7__r.KanjoKamokuRef__r.Name)),
				tran.Field7__r.KanjoKamokuRef__r,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ END
				pCcInfo.credepartcode,
				CommUtils.nullToBlank(tran.Field7__r.KanjoKamokuRef__r.CreditTaxKbn__c),
				// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
				//String.valueOf(tanknotax.intValue()),
				String.valueOf(tanknotax),
				// 2016/11/21 出力金額の小数点対応できる改善 END
				// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
				//pCcInfo.creconsumptax,
				(pCcInfo.isOutTaxToSameLine ? lineTaxRateStr : pCcInfo.creconsumptax),
				// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
				ROLLUP_TYPE.SALES_R);
// 2016/09/23 仕訳Rollup機能追加対応 END				 	
				// 2019/09/20 多税率機能対応 WSQ BEGIN			 	
			 	// 実際利用金額
			 	//amountIncTax += CommUtils.nullToZero(tran.Field41__c);
			 	// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
			 	//amountNoTax  += CommUtils.nullToZero(tran.GoukeinoneTax__c);
			 	//amountNoTax  += tanknotax;
			 	if (!amountIncTaxMap.containskey(taxrate)) amountIncTaxMap.put(taxrate, CommUtils.nullToZero(tran.Field41__c));
			 	else amountIncTaxMap.put(taxrate, (amountIncTaxMap.get(taxrate) + CommUtils.nullToZero(tran.Field41__c)));
			 	if (!amountNoTaxMap.containskey(taxrate)) amountNoTaxMap.put(taxrate, tanknotax);
			 	else amountNoTaxMap.put(taxrate, (amountNoTaxMap.get(taxrate) + tanknotax));
			 	// 2019/09/20 多税率機能対応 WSQ END
			 	// 2016/11/21 出力金額の小数点対応できる改善 END
            // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
            /*
			} else {
				// 消費税出力行目は残りままが必要
				if (i != taxOuputLineNum) {
					csvLine = csvLine
						.Replace('$$_貸方科目コード_$$'	, '')
						.Replace('$$_貸方科目_$$'			, '')
						.Replace('$$_貸方補助コード_$$'	, '')
						.Replace('$$_貸方補助_$$'			, '')
						.Replace('$$_貸方税区分_$$'		, '')
						.Replace('$$_貸方金額_$$'			, '');
				}*/
			}
			// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
			// 2016/12/13 摘要項目の後ろに請求先を表示追加対応 BEGIN
			csvLine = addAccountInfToCsv(csvLine, wkAccountName);
			// 2016/12/13 摘要項目の後ろに請求先を表示追加対応 END
			oneAccCsv += csvLine;
		} // for (Integer i = 0; i < maxLoopSize; i++)
// 2019/09/20 多税率機能対応 WSQ BEGIN
list<decimal> taxratelst = new list<decimal>();
for (decimal key : amountIncTaxMap.keyset()) {taxratelst.add(formattax(key));}
taxratelst.sort();
for (decimal taxrate : taxratelst) {
	decimal amountServiceNoTax = amountServiceNoTaxMap.get(taxrate);//サビース料金
 	// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ BEGIN
	// サビース料の消費税が出力必要場合 #9199
	decimal amountServiceTax = amountServiceTaxMap.get(taxrate);//サビース料金の消費税
	// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ END
	if (pCcInfo.serviceRkanjoMap.containsKey(taxrate)) pCcInfo.serviceRkanjoCode = pCcInfo.serviceRkanjoMap.get(taxrate);//サビース勘定科目
// 2019/09/20 多税率機能対応 WSQ END
        // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
	    // サビース料個別出力の場合、サビース料（税抜き）情報はCSVへ反映を行う
	    if (isOutServiceFlg && amountServiceNoTax > 0) {
	        // サビース料勘定科目情報を取得する
	        KanjoKamoku__c serviceKankoMst = null;
	        if (pKanjoKamokuMstMap.containsKey(pCcInfo.serviceRkanjoCode)) serviceKankoMst = pKanjoKamokuMstMap.get(pCcInfo.serviceRkanjoCode).clone(false,true);
	        if (serviceKankoMst == null) serviceKankoMst = new KanjoKamoku__c();
	        if (ttendSize > tranSize) {
	            // 指定行目のCSV情報を取得、該当CSV情報を入替えする
	            // 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ BEGIN
		    // サビース料の消費税が出力必要場合 #9199
	            oneAccCsv = getTaxCsvLine(oneAccCsv, amountServiceNoTax, serviceKankoMst, acc, false, true,amountServiceTax);
	            // 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ END
	        } else {
	            // 右側の行目は多い場合、新規行目を出力追加する
		    // 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ BEGIN
		    // サビース料の消費税が出力必要場合 #9199
	            oneAccCsv += getTaxCsvLine(addAccountInfToCsv(csvTemplate,''), amountServiceNoTax, serviceKankoMst, acc, true, true,amountServiceTax);
	            // 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ END
	        }
	        // 右の明細行を一行追加を行う
	        tranSize++;
	    }
// 2019/09/20 多税率機能対応 WSQ BEGIN
}

for (decimal taxrate : taxratelst) {
	decimal amountIncTax = amountIncTaxMap.get(taxrate);//税込み金額
	decimal amountNoTax = amountNoTaxMap.get(taxrate);//税抜金額
	decimal amountServiceNoTax = amountServiceNoTaxMap.get(taxrate);//サビース料金
 	// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ BEGIN
	// サビース料の消費税が出力必要場合 #9199
	decimal amountServiceTax = amountServiceTaxMap.get(taxrate);//サビース料金の消費税
	// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ END
	if (pCcInfo.taxKanjoMap.containskey(taxrate)) pCcInfo.taxKanjoCode = pCcInfo.taxKanjoMap.get(taxrate);
// 2019/09/20 多税率機能対応 WSQ END
        // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
		// 消費税情報はCSVへ反映する
		KanjoKamoku__c kankoMst = pKanjoKamokuMstMap.get(pCcInfo.taxKanjoCode);
		if (kankoMst == null) kankoMst = new KanjoKamoku__c();
		// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
		//Decimal taxPayAmount = amountIncTax - amountNoTax;
		// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ BEGIN
		//Decimal taxPayAmount = amountIncTax - amountNoTax - amountServiceNoTax;
		Decimal taxPayAmount = amountIncTax - amountNoTax - amountServiceNoTax - CommUtils.nullToZero(amountServiceTax);
		// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ END
		// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN				
		// 消費税は該当行目に表示するため、個別消費税出力が不要になる　
		if (pCcInfo.isOutTaxToSameLine) {
			taxPayAmount = 0;
			oneAccCsv = oneAccCsv.Replace('$$_貸方消費税額_$$'		, '0');
		}
		// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
		// 消費税情報出力を行う
        if (taxPayAmount > 0) {
			// 支払情報行数 > 会計明細行数の場合、会計明細の次の行に設定を行う
			if (ttendSize > tranSize) {
				// 既存の情報から入り替えする
				// 2016/09/23 仕訳Rollup機能追加対応 BEGIN
				//oneAccCsv = getTaxCsvLine(oneAccCsv, taxPayAmount, kankoMst);
				// 2016/12/13 BUGFIX 消費税金額がない場合、無条件な空文字列を戻る不具合改修 BEGIN
				oneAccCsv = getTaxCsvLine(oneAccCsv, taxPayAmount, kankoMst, acc, false, true);
				// 2016/12/13 BUGFIX 消費税金額がない場合、無条件な空文字列を戻る不具合改修 END
				// 2016/09/23 仕訳Rollup機能追加対応 END
			} else {
				// 新行目に消費税情報を作成する
				// 2016/09/23 仕訳Rollup機能追加対応 BEGIN
				//oneAccCsv += getTaxCsvLine(csvTemplate, taxPayAmount, kankoMst);
				// 2016/12/13 BUGFIX 消費税金額がない場合、無条件な空文字列を戻る不具合改修 BEGIN
				oneAccCsv += getTaxCsvLine(addAccountInfToCsv(csvTemplate,''), taxPayAmount, kankoMst, acc, true, true);
				// 2016/12/13 BUGFIX 消費税金額がない場合、無条件な空文字列を戻る不具合改修 END
				// 2016/09/23 仕訳Rollup機能追加対応 END
			}
	        // 右の明細行を一行追加を行う
	        tranSize++;
        }
// 2019/09/20 多税率機能対応 WSQ BEGIN
}        
// 2019/09/20 多税率機能対応 WSQ END
        // 残り部分は全部クリアを行う
        KanjoKamoku__c clearKankoMst = new KanjoKamoku__c();
        oneAccCsv = getTaxCsvLine(oneAccCsv, 0, clearKankoMst, acc, false);
        // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
		return oneAccCsv;
	}
	// 2015/12/04 カード手数料明細は内訳機能に出力機能の追加 BEGIN
	// 手数料計算を行う
	private list<decimal> tesuryoProcess(ConvertXmlConfig pCcInfo,
										Ttend__c ttend, 
										//Tran1__c ttran,
										map<Id,List<ChargeInfo__c>> pTesuryoInfMap,
										map<String, KanjoKamoku__c> pKanjoKamokuMstMap) {
//System.debug(logginglevel.INFO, 'pTesuryoInfMap:::' + pTesuryoInfMap);
//System.debug(logginglevel.INFO, 'pCcInfo.isOutputUtiwake:::' + pCcInfo.isOutputUtiwake);
//System.debug(logginglevel.INFO, 'ttend:::' + ttend);
		list<Decimal> cardRate = null;
		// 内訳出力しない場合、処理中止
		if (!pCcInfo.isOutputUtiwake || pTesuryoInfMap.isEmpty()) return cardRate;
		// カード手数料の勘定科目の設定の確認
		if (CommUtils.isBlank(pCcInfo.cardTesuryoSeqNo) || !pKanjoKamokuMstMap.containsKey(pCcInfo.cardTesuryoSeqNo)) return cardRate;
		// 会計明細、会計支払に対して、手数料処理を行う
		//List<PaymentDetail__c> tesuryoTtendLst = new list<PaymentDetail__c>();
		// 支払明細
		//for (PaymentDetail__c pay : ttends) {
		// 契約会社情報のID
		Id cardComapnyId = null;
		if (ttend != null) {
			// 契約会社情報のID
			cardComapnyId = ttend.PayProductRef__r.CardAccountRef__c;
//System.debug(logginglevel.INFO, '*******************');
//System.debug(logginglevel.INFO, 'cardComapnyId:::' + cardComapnyId);
			// 該当カードの手数料定義情報が存在する場合
			if (cardComapnyId != null && pTesuryoInfMap.containsKey(cardComapnyId)) {
//System.debug(logginglevel.INFO, 'pTesuryoInfMap.containsKey('+cardComapnyId+'):::' + pTesuryoInfMap.containsKey(cardComapnyId));
				// 利用金額から、手数料計算を行う
				Decimal usedAmount = CommUtils.nullToZero(ttend.Field20__c);
				// 2016/03/22 利用金額は０円の場合、カード手数料を出力しない
				if (usedAmount == 0) return cardRate;
				// 手数料情報
				ChargeInfo__c chargeInfo = pTesuryoInfMap.get(cardComapnyId)[0];
				// 手数料レート
				Decimal tesuRate = CommUtils.nullToZero(chargeInfo.SalesRate__c) / 100;
				String tesuRoundType = CommUtils.nullToBlank(chargeInfo.AccountRef__r.RoundType__c);
//System.debug(logginglevel.INFO, 'usedAmount::' + usedAmount);
//System.debug(logginglevel.INFO, 'tesuRate::' + tesuRate);
//System.debug(logginglevel.INFO, 'tesuRoundType::' + tesuRoundType);
				// 利用金額、手数料率、
				// 2016/07/07 BEGIN
				cardRate = new list<decimal>();
				cardRate.add(tesuryoCalProcess(usedAmount,tesuRate,tesuRoundType));
				cardRate.add(usedAmount);
				cardRate.add(CommUtils.nullToZero(chargeInfo.SalesRate__c));
				// 2016/07/07 END
//System.debug(logginglevel.INFO, 'cardRate::' + cardRate);
			}
		}
		return cardRate;
	}
	// 手数料計算
	private Decimal tesuryoCalProcess(Decimal usedAmount, Decimal tesuRate, String strRoundType) {
		if (tesuRate == 0) return 0;
		// 端数処理区分
		System.RoundingMode roundType = CommUtils.pointRoundMode();
		if (!CommUtils.isBlank(strRoundType)) {
			roundType = CommUtils.pointRoundMode(strRoundType);
		}
		// 手数料を計算する
		Decimal salesRate = CommUtils.RoundProcess(usedAmount * tesuRate, gPointLen, roundType);
		return salesRate;
	}
	// 手数料により、出力情報を作成する[カード手数料]
	private Classification__c createVirTesuryoPayDetail(AccountAcount__c acc ,
														PaymentDetail__c ttendPay, 
														list<Decimal> pCardRates,
														ConvertXmlConfig pCcInfo,
														Map<String, KanjoKamoku__c> pKanjoKamokuMstMap,
														Integer startNo,
														String csvTemplate,
														List<string> cardAndSalesLines) {
		// 2016/07/07 BEGIN
		decimal pCardRate = pCardRates[0];
		if (pCardRate <= 0) return null;
		// 2016/07/07 END
		// 手数料明細情報は出力リストに追加する
		PaymentDetail__c tesuryoPay = new PaymentDetail__c(
			DepositAmount__c = pCardRate,		// 預かり金額
			UsedAmount__c = pCardRate,			// 利用金額
			AccountAcountRef__c = ttendPay.AccountAcountRef__c,	// 会計情報
			PaymentInfoRef__c = ttendPay.PaymentInfoRef__c,		// 支払情報
			id = ttendPay.Id
		);
		/*
		// 支払情報をCLONEする
		PaymentInfo__c payInfo = new PaymentInfo__c();
		*/
		AccountMaster__c virAccMst = new AccountMaster__c();
		if (ttendPay.PaymentInfoRef__r.TTendRef__c != null) {
			// 会計支払から手数料明細情報を作成する
			//TTend__c tesuryoTtend = ttendPay.PaymentInfoRef__r.TTendRef__r.clone(true,true);
			virAccMst = ttendPay.PaymentInfoRef__r.TTendRef__r.PayProductRef__r.clone(true,true);
			//tesuryoTtend.PayProductRef__r = virAccMst;
			//payInfo.TTendRef__c = tesuryoTtend.Id;
			//payInfo.TTendRef__r = tesuryoTtend;
		}
		else if (ttendPay.PaymentInfoRef__r.Tran1Ref__c != null) {
			// 予約金から手数料明細情報を作成する
			//Tran1__c tesuryoTran = ttendPay.PaymentInfoRef__r.Tran1Ref__r.clone(true,true);
			virAccMst = ttendPay.PaymentInfoRef__r.Tran1Ref__r.Field7__r.clone(true,true);
			//tesuryoTran.Field7__r = virAccMst;
			//payInfo.Tran1Ref__c = tesuryoTran.Id;
			//payInfo.Tran1Ref__r = tesuryoTran;
		}
		/*
		// カード契約会社情報のクリア
		virAccMst.CardAccountRef__c = null;
		// 元の勘定科目情報
		KanjoKamoku__c virKankoMst = virAccMst.KanjoKamokuRef__r;
		// 勘定科目の再設定を行う
		// 2016/03/21 カード手数料会計科目は間違った設定の場合、ExceptionErrorを回避する BEGIN
		*/
		KanjoKamoku__c cardTesuryoKankoMst = null;
		if ( pKanjoKamokuMstMap.containsKey(pCcInfo.cardTesuryoSeqNo) ) cardTesuryoKankoMst = pKanjoKamokuMstMap.get(pCcInfo.cardTesuryoSeqNo).clone(true,true);
		else cardTesuryoKankoMst = new KanjoKamoku__c();
		// 2016/03/21 カード手数料会計科目は間違った設定の場合、ExceptionErrorを回避する END
		// 補助科目コードが未設定の場合、
		// 元の補助科目情報を設定する
		if (CommUtils.isBLank(cardTesuryoKankoMst.KanjoHojocode__c)) cardTesuryoKankoMst.KanjoHojocode__c = CommUtils.nullToBlank(virAccMst.CardAccountRef__r.Name);
		if (CommUtils.isBLank(cardTesuryoKankoMst.KanjoHojoname__c)) cardTesuryoKankoMst.KanjoHojoname__c = CommUtils.nullToBlank(virAccMst.CardAccountRef__r.Name);
		// 税区分XMLに設定されていると、該当税区分文言はCSVに出力を行う
		if (!CommUtils.isBlank(pCcInfo.cardTesuryoTaxKbn)) cardTesuryoKankoMst.DebitTaxKbn__c = pCcInfo.cardTesuryoTaxKbn;
		/*
		virAccMst.KanjoKamokuRef__r = cardTesuryoKankoMst;
		// 支払明細の再設定
		tesuryoPay.PaymentInfoRef__r = payInfo;
		*/
//System.debug(logginglevel.INFO, 'tesuryoPay.PaymentInfoRef__r:::' + tesuryoPay.PaymentInfoRef__r);
//System.debug(logginglevel.INFO, 'tesuryoPay.PaymentInfoRef__r.TTendRef__r:::' + tesuryoPay.PaymentInfoRef__r.TTendRef__r);
//System.debug(logginglevel.INFO, 'tesuryoPay.PaymentInfoRef__r.TTendRef__r.PayProductRef__r:::' + tesuryoPay.PaymentInfoRef__r.TTendRef__r.PayProductRef__r);
//System.debug(logginglevel.INFO, 'tesuryoPay.PaymentInfoRef__r.Tran1Ref__r:::' + tesuryoPay.PaymentInfoRef__r.Tran1Ref__r);
//System.debug(logginglevel.INFO, 'tesuryoPay.PaymentInfoRef__r.Tran1Ref__r.Field7__r:::' + tesuryoPay.PaymentInfoRef__r.Tran1Ref__r.Field7__r);
//System.debug(logginglevel.INFO, 'tesuryoPay:::' + tesuryoPay);
		KanjoKamoku__c cardTesuryoKankoMstRight = pKanjoKamokuMstMap.get(pCcInfo.cardTesuryoRightSeqNo);
		if (cardTesuryoKankoMstRight == null) cardTesuryoKankoMstRight = new KanjoKamoku__c();
		// 税区分XMLに設定されていると、該当税区分文言はCSVに出力を行う
		if (!CommUtils.isBlank(pCcInfo.cardTesuryoRightTaxKbn)) cardTesuryoKankoMstRight.CreditTaxKbn__c = pCcInfo.cardTesuryoRightTaxKbn;
		/*return tesuryoPay;*/
		// 2016.07.25 CSVファイルに出力しないへ変更（日本から仕様要望）
		//String csvLine = generalVirTesuryoCsvInfo(acc,tesuryoPay,csvTemplate,startNo,cardTesuryoKankoMst,cardTesuryoKankoMstRight);
		//cardAndSalesLines.add(csvLine);
		// 2016/07/07 BEGIN
		String memoStr = '部屋：' + CommUtils.nullToBlank(acc.Relreserve__r.Rroom__r.Name) + ' ' +
						 '氏名：' + CommUtils.nullToBlank(acc.Relreserve__r.Relcontact__r.Name);	 
		
		String agtId = ttendPay.PaymentInfoRef__r.TTendRef__r.PayProductRef__r.CardAccountRef__c;
		if (Commutils.isBLank(agtId)) agtId = ttendPay.PaymentInfoRef__r.Tran1Ref__r.Field7__r.CardAccountRef__c;
		String debittaxkbn = CommUtils.nullToBlank(cardTesuryoKankoMst.DebitTaxKbn__c);
        //if (!CommUtils.isBlank(pCcInfo.notaxkbn)) debittaxkbn = pCcInfo.notaxkbn;
        String creditTaxKbn = CommUtils.nullToBlank(cardTesuryoKankoMstRight.CreditTaxKbn__c);
		Classification__c clsif = new Classification__c(
			RsvAccountRef__c = acc.frs__c,			// 売上
			AccountAcountRef__c = acc.Id,			// 会計
			SalesDotCom__c = agtId,					// AGT（取引先）
			DebitRef__c = cardTesuryoKankoMst.Id,					// 借方科目
			DebitName__c =  cardTesuryoKankoMst.Name,				// 借方勘定科目
			DebitSubName__c = cardTesuryoKankoMst.KanjoHojoname__c,	// 借方勘定科目
			DebitDepartment__c = pCcInfo.debdepartcode,				// 借方部門
			DebitTaxKbn__c = debittaxkbn,							// 借方税区分
			DebitTaxAmount__c = CommUtils.nullToZero(pCcInfo.debconsumptax),// 借方税額
			//CreditName__c = gConfig.agtSalesRateConf.OuKamoku,
			Voucher__c = CommUtils.stringToDate(gRsvName),			// 日付
			SlipNo__c = String.valueOf(startNo),					// 伝票No.
			BookingName__c = acc.Relreserve__c,						// ご予約
			Description__c = memoStr,
			SalesAmount__c = pCardRate,								// 取引金額
			SalesOrgAmount__c = pCardRates[1],						// 計算元金額
			SalesRate__c = pCardRates[2],							// 手数料レート
			ShopInfoRef__c = gShopId,
			EventSource__c = CONST_EVENTSRC_CARD,
			// 貸方出力情報
			CreditRef__c = cardTesuryoKankoMstRight.Id,
			CreditName__c = cardTesuryoKankoMstRight.Name,
			CreditSubName__c = cardTesuryoKankoMstRight.KanjoHojoname__c,
			CreditDepartment__c = pCcInfo.credepartcode,
			CreditTaxKbn__c = creditTaxKbn
		);
		return clsif;
		// 2016/07/07 END
	}
	// 2016/07/21 カード手数料・販売手数料は別行目に出力機能制御追加　BEGIN
	/* 2016/09/23 仕訳Rollup機能追加対応
	private String generalVirTesuryoCsvInfo (AccountAcount__c acc , PaymentDetail__c ttendPay, String CsvTemplate ,Integer startNo, KanjoKamoku__c kankoMstL, KanjoKamoku__c kankoMstR) {

		// カード手数料は出力明細CSV情報を作成する
		String csv = '';
		String SingAccCsvTemplate = getSingAccCsvTemplate(acc, startNo, CsvTemplate, false);
		String paymentAmount = String.valueOf(math.abs(CommUtils.nullToIntZero(ttendPay.DepositAmount__c)));
		String debittaxkbn = CommUtils.nullToBlank(kankoMstL.DebitTaxKbn__c);
		String credittaxkbn = CommUtils.nullToBlank(kankoMstR.CreditTaxKbn__c);
		csv = SingAccCsvTemplate
				.Replace('$$_借方科目コード_$$'	,CommUtils.nullToBlank(kankoMstL.KanjocodeCode__c))
				//.Replace('$$_借方科目_$$'			,CommUtils.nullToBlank(kankoMstL.Name))
				.Replace('$$_借方科目_$$'			,processFilter(CommUtils.nullToBlank(kankoMstL.Name)))
				.Replace('$$_借方補助コード_$$'	,CommUtils.nullToBlank(kankoMstL.KanjoHojocode__c))
				.Replace('$$_借方補助_$$'			,CommUtils.nullToBlank(kankoMstL.KanjoHojoname__c))
				// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 BEGIN
				//.Replace('$$_借方税区分_$$'		,CommUtils.nullToBlank(kankoMstL.CreditTaxKbn__c))
				.Replace('$$_借方税区分_$$'		,debittaxkbn)
				// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 END
				.Replace('$$_借方金額_$$'			,paymentAmount)
				// 消費税情報を設定する
				.Replace('$$_貸方科目コード_$$'	,CommUtils.nullToBlank(kankoMstR.KanjocodeCode__c))
				//.Replace('$$_貸方科目_$$'			,CommUtils.nullToBlank(kankoMstR.Name))
				.Replace('$$_貸方科目_$$'			,processFilter(CommUtils.nullToBlank(kankoMstR.Name)))
				.Replace('$$_貸方補助コード_$$'	,CommUtils.nullToBlank(kankoMstR.KanjoHojocode__c))
				.Replace('$$_貸方補助_$$'			,CommUtils.nullToBlank(kankoMstR.KanjoHojoname__c))
				// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 BEGIN
				//.Replace('$$_貸方税区分_$$'		,CommUtils.nullToBlank(kankoMstR.CreditTaxKbn__c))
				.Replace('$$_貸方税区分_$$'		,credittaxkbn)
				// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 END
				.Replace('$$_貸方金額_$$'			,paymentAmount);	
		
		return csv;
		
	}*/
	// 2016/07/21 カード手数料・販売手数料は別行目に出力機能制御追加　END
	// 2015/12/04 カード手数料明細は内訳機能に出力機能の追加 END
	// 2015/03/08 販売手数料は内訳として、出力機能の対応 BEGIN
	private Classification__c createVirAgtTesuryoPayDetail(AccountAcount__c acc ,
														PaymentDetail__c ttendPay, 
														list<Decimal> pAgtRates,
														ConvertXmlConfig pCcInfo,
														Map<String, KanjoKamoku__c> pKanjoKamokuMstMap,
														ChargeInfo__c pChargeInfo,
														Integer startNo,
														String csvTemplate,
														List<string> cardAndSalesLines) {
		// 2016/07/07 BEGIN
		decimal pAgtRate = pAgtRates[0];
		if (pAgtRate <= 0) return null;
		// 2016/07/07 END
		// 手数料明細情報は出力リストに追加する
		PaymentDetail__c tesuryoPay = new PaymentDetail__c(
			DepositAmount__c = pAgtRate,		// 預かり金額
			UsedAmount__c = pAgtRate,			// 利用金額
			AccountAcountRef__c = ttendPay.AccountAcountRef__c,	// 会計情報
			PaymentInfoRef__c = ttendPay.PaymentInfoRef__c,		// 支払情報
			id = ttendPay.Id
		);
//System.debug(loggingLevel.INFO, 'pCcInfo.agtTesuryoSeqNo:::' + pCcInfo.agtTesuryoSeqNo);
//System.debug(loggingLevel.INFO, 'tesuryoPay:::' + tesuryoPay);
//System.debug(loggingLevel.INFO, 'pKanjoKamokuMstMap:::' + pKanjoKamokuMstMap);
		// 支払情報をCLONEする
		//PaymentInfo__c payInfo = new PaymentInfo__c();
		AccountMaster__c virAccMst = new AccountMaster__c();
		if (ttendPay.PaymentInfoRef__r.TTendRef__c != null) {
			// 会計支払から手数料明細情報を作成する
			//TTend__c tesuryoTtend = ttendPay.PaymentInfoRef__r.TTendRef__r.clone(true,true);
//System.debug(logginglevel.INFO, 'tesuryoTtend='+tesuryoTtend);
//System.debug(logginglevel.INFO, 'TESURY CLONE1='+tesuryoTtend.PayProductRef__r);
			//AccountMaster__c cloneAccMst = ttend.PayProductRef__r;
			virAccMst = ttendPay.PaymentInfoRef__r.TTendRef__r.PayProductRef__r.clone(true,true);
			//tesuryoTtend.PayProductRef__r = virAccMst;
			//payInfo.TTendRef__c = tesuryoTtend.Id;
			//payInfo.TTendRef__r = tesuryoTtend;
		}
		else if (ttendPay.PaymentInfoRef__r.Tran1Ref__c != null) {
			// 予約金から手数料明細情報を作成する
			//payInfo.Tran1Ref__c = ttendPay.PaymentInfoRef__r.Tran1Ref__c;
			//Tran1__c tesuryoTran = ttendPay.PaymentInfoRef__r.Tran1Ref__r.clone(true,true);
			virAccMst = ttendPay.PaymentInfoRef__r.Tran1Ref__r.Field7__r.clone(true,true);
			//tesuryoTran.Field7__r = virAccMst;
			//payInfo.Tran1Ref__c = tesuryoTran.Id;
			//payInfo.Tran1Ref__r = tesuryoTran;
			// 勘定科目情報設定する
//System.debug(logginglevel.INFO, 'TESURY CLONE2='+tesuryoTran.Field7__r);
		}
		// カード契約会社情報のクリア
		//virAccMst.CardAccountRef__c = null;
		// 元の勘定科目情報
		//KanjoKamoku__c virKankoMst = virAccMst.KanjoKamokuRef__r;
		// 勘定科目の再設定を行う
		// 2016/03/21 カード手数料会計科目は間違った設定の場合、ExceptionErrorを回避する BEGIN
		KanjoKamoku__c agtTesuryoKankoMst = null;
		if (pKanjoKamokuMstMap.containsKey(pCcInfo.agtTesuryoSeqNo)) agtTesuryoKankoMst = pKanjoKamokuMstMap.get(pCcInfo.agtTesuryoSeqNo).clone(true,true);
		else agtTesuryoKankoMst = new KanjoKamoku__c();
		// 2016/03/21 カード手数料会計科目は間違った設定の場合、ExceptionErrorを回避する END
		// 税区分XMLに設定されていると、該当税区分文言はCSVに出力を行う
		if (!CommUtils.isBlank(pCcInfo.agtTesuryoTaxKbn)) agtTesuryoKankoMst.DebitTaxKbn__c = pCcInfo.agtTesuryoTaxKbn;
		// 補助科目コードが未設定の場合、手数料関連の取引先名を設定する
		// 元の補助科目情報を設定する
		if (CommUtils.isBLank(agtTesuryoKankoMst.KanjoHojocode__c)) agtTesuryoKankoMst.KanjoHojocode__c = CommUtils.nullToBlank(pChargeInfo.AccountRef__r.Name);
		if (CommUtils.isBLank(agtTesuryoKankoMst.KanjoHojoname__c)) agtTesuryoKankoMst.KanjoHojoname__c = CommUtils.nullToBlank(pChargeInfo.AccountRef__r.Name);
		//virAccMst.KanjoKamokuRef__r = agtTesuryoKankoMst;
		// 支払明細の再設定
		//tesuryoPay.PaymentInfoRef__r = payInfo;
		
		// 貸方勘定科目情報
		KanjoKamoku__c agtTesuryoKankoMstRight = pKanjoKamokuMstMap.get(pCcInfo.agtTesuryoRightSeqNo);
		if (agtTesuryoKankoMstRight == null) agtTesuryoKankoMstRight = new KanjoKamoku__c();
		// 税区分XMLに設定されていると、該当税区分文言はCSVに出力を行う
		if (!CommUtils.isBlank(pCcInfo.agtTesuryoTaxKbn)) agtTesuryoKankoMstRight.CreditTaxKbn__c = pCcInfo.agtTesuryoTaxKbn;
		// 2016.07.25 CSVファイルに出力しないへ変更（日本から仕様要望）
		//String csvLine = generalVirTesuryoCsvInfo(acc,tesuryoPay,csvTemplate,startNo,agtTesuryoKankoMst,agtTesuryoKankoMstRight);		//System.debug(loggingLevel.INFO, 'AGT-CSV-LINE:'+csvLine);
		//cardAndSalesLines.add(csvLine);
		/*return tesuryoPay;*/
		// 2016/07/07 BEGIN
		String memoStr = '部屋：' + CommUtils.nullToBlank(acc.Relreserve__r.Rroom__r.Name) + ' ' +
						 '氏名：' + CommUtils.nullToBlank(acc.Relreserve__r.Relcontact__r.Name);	
		// 手数料に紐付取引先のID 
		String agtId = pChargeInfo.AccountRef__c;
		String debittaxkbn = CommUtils.nullToBlank(agtTesuryoKankoMst.DebitTaxKbn__c);
        String creditTaxKbn = CommUtils.nullToBlank(agtTesuryoKankoMstRight.CreditTaxKbn__c);
		Classification__c clsif = new Classification__c(
			RsvAccountRef__c = acc.frs__c,			// 売上
			AccountAcountRef__c = acc.Id,			// 会計
			SalesDotCom__c = agtId,					// AGT（取引先）
			DebitRef__c = agtTesuryoKankoMst.Id,					// 借方科目
			DebitName__c =  agtTesuryoKankoMst.Name,				// 借方勘定科目
			DebitSubName__c = agtTesuryoKankoMst.KanjoHojoname__c,	// 借方勘定科目
			DebitDepartment__c = pCcInfo.debdepartcode,				// 借方部門
			DebitTaxKbn__c = debittaxkbn,							// 借方税区分
			DebitTaxAmount__c = CommUtils.nullToZero(pCcInfo.debconsumptax),// 借方税額
			//CreditName__c = gConfig.agtSalesRateConf.OuKamoku,
			Voucher__c = CommUtils.stringToDate(gRsvName),			// 日付
			SlipNo__c = String.valueOf(startNo),					// 伝票No.
			BookingName__c = acc.Relreserve__c,						// ご予約
			Description__c = memoStr,
			SalesAmount__c = pAgtRate,								// 取引金額
			SalesOrgAmount__c = pAgtRates[1],						// 計算元金額
			SalesRate__c = pAgtRates[2],							// 手数料レート
			ShopInfoRef__c = gShopId,
			EventSource__c = CONST_EVENTSRC_AGT,
			// 貸方出力情報
			CreditRef__c = agtTesuryoKankoMstRight.Id,
			CreditName__c = agtTesuryoKankoMstRight.Name,
			CreditSubName__c = agtTesuryoKankoMstRight.KanjoHojoname__c,
			CreditDepartment__c = pCcInfo.credepartcode,
			CreditTaxKbn__c = creditTaxKbn
		);
		return clsif;
		// 2016/07/07 END
	}
	// 2015/03/08 販売手数料は内訳として、出力機能の対応 END
	// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
	private String getTaxCsvLine(String csvTemplate, Decimal taxAmount, KanjoKamoku__c kankoMst, AccountAcount__c acc, Boolean newLine) {
	    return getTaxCsvLine(csvTemplate, taxAmount, kankoMst, acc, newLine, false);
	}
	/**
	* 消費税行目のCSV情報を取得する
	**/
	private String getTaxCsvLine(String csvTemplate, Decimal taxAmount, KanjoKamoku__c kankoMst, AccountAcount__c acc, Boolean newLine, Boolean isRepFirst) {
		return getTaxCsvLine(csvTemplate, taxAmount, kankoMst, acc, newLine, isRepFirst, null);
	}
	private String getTaxCsvLine(String csvTemplate, Decimal taxAmount, KanjoKamoku__c kankoMst, AccountAcount__c acc, Boolean newLine, Boolean isRepFirst, Decimal serviceTax) {
	// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END  
		// 2015/12/07 消費税０円の場合、出力を行わない BEGIN
		// 2016/12/13 BUGFIX 消費税金額がない場合、無条件な空文字列を戻る不具合改修 BEGIN
		//if (taxAmount == 0) return '';
		if (taxAmount == 0 && newLine) return '';
		// 2016/12/13 BUGFIX 消費税金額がない場合、無条件な空文字列を戻る不具合改修 END
		// 2015/12/07 消費税０円の場合、出力を行わない END
		// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
		taxAmount = formatOuputNumber(taxAmount);
		// 2016/11/21 出力金額の小数点対応できる改善 END
		String csv = csvTemplate
					.Replace('$$_借方科目コード_$$'	,'')
					.Replace('$$_借方科目_$$'			,'')
					.Replace('$$_借方補助コード_$$'	,'')
					.Replace('$$_借方補助_$$'			,'')
					.Replace('$$_借方税区分_$$'		,'')
					.Replace('$$_借方金額_$$'			,'0');
		// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ BEGIN
		// サビース料の消費税が出力必要場合 #9199
		if (serviceTax != null && serviceTax > 0) {
			system.debug(LoggingLevel.info, 'csv[mid]['+serviceTax+']=='+csv);
			csv = csv.ReplaceFirst('\\$\\$_貸方消費税額_\\$\\$'	, String.valueOf(serviceTax));
		}
		// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ END
		if (isRepFirst) {
		    csv = csv
                    // 消費税情報を設定する
                    .ReplaceFirst('\\$\\$_貸方科目コード_\\$\\$'   , CommUtils.nullToBlank(kankoMst.KanjocodeCode__c))
                    //.Replace('$$_貸方科目_$$'         , CommUtils.nullToBlank(kankoMst.Name))
                    // 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
                    //.Replace('$$_貸方科目_$$'         , processFilter(CommUtils.nullToBlank(kankoMst.Name)))
                    .ReplaceFirst('\\$\\$_貸方科目_\\$\\$'           , processEscapeKanji(processFilter(CommUtils.nullToBlank(kankoMst.Name))))
                    // 2016/12/14 漢字にカンマを含めている改善対応 END
                    .ReplaceFirst('\\$\\$_貸方補助コード_\\$\\$'   , CommUtils.nullToBlank(kankoMst.KanjoHojocode__c))
                    // 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
                    //.Replace('$$_貸方補助_$$'         , CommUtils.nullToBlank(kankoMst.KanjoHojoname__c))
                    .ReplaceFirst('\\$\\$_貸方補助_\\$\\$'           , processEscapeKanji(CommUtils.nullToBlank(kankoMst.KanjoHojoname__c)))
                    // 2016/12/14 漢字にカンマを含めている改善対応 END
                    .ReplaceFirst('\\$\\$_貸方税区分_\\$\\$'      , CommUtils.nullToBlank(kankoMst.CreditTaxKbn__c))
                    // 2016/11/21 出力金額の小数点対応できる改善 BEGIN
                    //.Replace('$$_貸方金額_$$'     , String.valueOf(taxAmount.intValue()));
                    .ReplaceFirst('\\$\\$_貸方金額_\\$\\$'       , String.valueOf(taxAmount));
		} else {
		    csv = csv
					// 消費税情報を設定する
					.Replace('$$_貸方科目コード_$$'	, CommUtils.nullToBlank(kankoMst.KanjocodeCode__c))
					//.Replace('$$_貸方科目_$$'			, CommUtils.nullToBlank(kankoMst.Name))
					// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
					//.Replace('$$_貸方科目_$$'			, processFilter(CommUtils.nullToBlank(kankoMst.Name)))
					.Replace('$$_貸方科目_$$'			, processEscapeKanji(processFilter(CommUtils.nullToBlank(kankoMst.Name))))
					// 2016/12/14 漢字にカンマを含めている改善対応 END
					.Replace('$$_貸方補助コード_$$'	, CommUtils.nullToBlank(kankoMst.KanjoHojocode__c))
					// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
					//.Replace('$$_貸方補助_$$'			, CommUtils.nullToBlank(kankoMst.KanjoHojoname__c))
					.Replace('$$_貸方補助_$$'			, processEscapeKanji(CommUtils.nullToBlank(kankoMst.KanjoHojoname__c)))
					// 2016/12/14 漢字にカンマを含めている改善対応 END
					.Replace('$$_貸方税区分_$$'		, CommUtils.nullToBlank(kankoMst.CreditTaxKbn__c))
					// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
					//.Replace('$$_貸方金額_$$'		, String.valueOf(taxAmount.intValue()));
					.Replace('$$_貸方金額_$$'		, String.valueOf(taxAmount));
		}
					// 2016/11/21 出力金額の小数点対応できる改善 END
// 2016/09/23 仕訳Rollup機能追加対応 BEGIN
setupRollupInfo(acc.frs__r.Name,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ BEGIN
				//processFilter(CommUtils.nullToBlank(kankoMst.Name)),
				kankoMst,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ END
				gccInfo.credepartcode,
				CommUtils.nullToBlank(kankoMst.CreditTaxKbn__c),
				// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
				//String.valueOf(taxAmount.intValue()),
				String.valueOf(taxAmount),
				// 2016/11/21 出力金額の小数点対応できる改善 END
				// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ BEGIN
				(serviceTax != null && serviceTax > 0) ? String.valueOf(serviceTax) : gccInfo.creconsumptax,
				//gccInfo.creconsumptax,
				// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ END
				ROLLUP_TYPE.SALES_R);
// 2016/09/23 仕訳Rollup機能追加対応 END
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
										.Replace('$$_COMMENTLAB_$$' , (isDespoistFlg == true ? Label.CONST_050_0005 : Label.CONST_050_0006))
										.Replace('$$_ROOMNO_$$'		, (isDespoistFlg == true ? CommUtils.nullToBlank(acc.Relreserve__r.No__c) : roomNo))
										.Replace('$$_GUESTNAME_$$'	, contactName);
			// 2018/02/22 摘要欄の出力内容はカスタマイズできるように改善対応 WGCH BEGIN
			if(!xmlFieldsMap.isEmpty()) simpleCommnt = getXmlMemoStr(acc);
			// 2018/02/22 摘要欄の出力内容はカスタマイズできるように改善対応 WGCH END
			String SingAccCsvTemplate = CsvTemplate
										// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
										//.Replace('$$_摘要_$$'		, simpleCommnt)
										.Replace('$$_摘要_$$'		, processEscapeKanji(simpleCommnt))
										// 2016/12/14 漢字にカンマを含めている改善対応 END
										.Replace('$$_伝票番号_$$'		, String.valueOf(startNo));
			return SingAccCsvTemplate;
	}
	
	// 2016/12/13 摘要項目の後ろに請求先を表示追加対応 BEGIN
	// 売掛の請求先名は摘要に追加する
	private String addAccountInfToCsv(String csv, String accountName) {
		accountName = processEscapeKanji(accountName);
		return csv.Replace('$$_ACCOUNTNAME_$$',CommUtils.nullToBlank(accountName));
	}
	private String getMemoAccountNameToCsv(Contact c) {
	    if (c == null || c.Account == null) return '';
		if (!CommUtils.isBlank(c.Account.Name)) return ' '+CommUtils.nullToBlank(c.Account.Name);
		//else return CommUtils.nullToBlank(c.Name);
		return '';
	}
	// 2016/12/13 摘要項目の後ろに請求先を表示追加対応 END
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
								// 2015/10/14 Freeeの連携CSV出力機能の追加 BEGIN
								.Replace('$$_[表題行]_$$'			, '[明細行]')
								// 2015/10/14 Freeeの連携CSV出力機能の追加 END
								.Replace('$$_Ver_$$'			, pCcInfo.ver)
								.Replace('$$_伝票日付_$$'			, accs[0].frs__r.Name)
								.Replace('$$_借方部門コード_$$'	, pCcInfo.debdepartcode)
								.Replace('$$_借方消費税額_$$'		, pCcInfo.debconsumptax)
								.Replace('$$_貸方部門コード_$$'	, pCcInfo.credepartcode)
								// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
								//.Replace('$$_貸方消費税額_$$'		, pCcInfo.creconsumptax)
								// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
								.Replace('$$_入力プログラム区分_$$'	, pCcInfo.inputprogramkbn);
		// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
		if (!pCcInfo.isOutTaxToSameLine) CsvTemplate = CsvTemplate.Replace('$$_貸方消費税額_$$'		, pCcInfo.creconsumptax);
		// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
		Integer startNo = pCcInfo.startno;

		Set<Id> leadIdxIdsSet = new Set<Id>();
		Set<Id> accIdsSet = new Set<Id>();
		// 2015/12/04 カード手数料明細は内訳機能に出力機能の追加 BEGIN
		Set<Id> tesusyoAccIdsSet = new Set<Id>();
		map<Id,List<ChargeInfo__c>> tesuryoInfMap = new map<Id, List<ChargeInfo__c>>();
		// 2015/12/04 カード手数料明細は内訳機能に出力機能の追加 END
		// 2015/12/21 販売手数料対象情報を取得する BEGIN
		// map<会計ID、list<取引先ID>>
		map<Id,list<Id>> agtTesuryoAccIdMap = new map<Id,list<Id>>();
		// map<会計ID、手数料定義情報>
		map<Id,ChargeInfo__c> agtTesuryoInfMap = new map<Id, ChargeInfo__c>();
		// 2015/12/21 販売手数料対象情報を取得する END
		// 2016/07/07 BEGIN
		list<Classification__c> insClassificationLst = new list<Classification__c>();
		// 2016/07/07 END
		for (AccountAcount__c acc : accs) {
			// 処理対象会計
			accIdsSet.add(acc.Id);
			// 2015/12/21 販売手数料対象情報を取得する BEGIN
			// お客様にリンクする取引先のID情報を格納する
			if (acc.Relreserve__r.Relcontact__r.AccountId != null) {
				agtTesuryoAccIdMap.put(acc.Id, new list<id>{acc.Relreserve__r.Relcontact__r.AccountId});
			} else if (acc.Relreserve__r.SalesOfficeInfoRef__c != null) {
				// 旅行会社　OR　旅行会社の親会計のID情報を格納
				agtTesuryoAccIdMap.put(acc.Id, new list<id>{acc.Relreserve__r.SalesOfficeInfoRef__c});
				if (acc.Relreserve__r.SalesOfficeInfoRef__r.ParentId != null) {
					agtTesuryoAccIdMap.get(acc.Id).add(acc.Relreserve__r.SalesOfficeInfoRef__r.ParentId);
				}
			}
			// 2015/12/21 販売手数料対象情報を取得する END
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
										,PaymentInfoRef__r.TTendRef__r.PayProductRef__r.KanjoKamokuRef__r.Name				// 会計科目
										,PaymentInfoRef__r.TTendRef__r.PayProductRef__r.KanjoKamokuRef__r.KanjoHojocode__c	// 補助科目コード
										,PaymentInfoRef__r.TTendRef__r.PayProductRef__r.KanjoKamokuRef__r.KanjoHojoname__c	// 補助科目
										,PaymentInfoRef__r.TTendRef__r.PayProductRef__r.KanjoKamokuRef__r.DebitTaxKbn__c
										,PaymentInfoRef__r.TTendRef__r.PayProductRef__r.KanjoKamokuRef__r.CreditTaxKbn__c
										,PaymentInfoRef__r.TTendRef__r.PayProductRef__r.CardAccountRef__c					// カード契約会社[2015/12/04 ADD]
										,PaymentInfoRef__r.TTendRef__r.PayProductRef__r.CardAccountRef__r.Name				// カード契約会社[2015/12/04 ADD]
										,PaymentInfoRef__r.TTendRef__r.CardTypeLst__c
										,PaymentInfoRef__r.TTendRef__r.CouponTypeLst__c
										// 2020/01/21 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う） WSQ BEGIN
										,PaymentInfoRef__r.ImgDataFlg__c
										// 2020/01/21 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う） WSQ END
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
										,PaymentInfoRef__r.Tran1Ref__r.Field7__c
										,PaymentInfoRef__r.Tran1Ref__r.Field7__r.KanjoKamokuRef__r.Kanjocode__c
		 								,PaymentInfoRef__r.Tran1Ref__r.Field7__r.KanjoKamokuRef__r.KanjocodeCode__c			// 会計科目コード
		 								,PaymentInfoRef__r.Tran1Ref__r.Field7__r.KanjoKamokuRef__r.Name						// 会計科目
		 								,PaymentInfoRef__r.Tran1Ref__r.Field7__r.KanjoKamokuRef__r.KanjoHojocode__c			// 補助科目コード
		 								,PaymentInfoRef__r.Tran1Ref__r.Field7__r.KanjoKamokuRef__r.KanjoHojoname__c			// 補助科目
		 								,PaymentInfoRef__r.Tran1Ref__r.Field7__r.KanjoKamokuRef__r.DebitTaxKbn__c
		 								,PaymentInfoRef__r.Tran1Ref__r.Field7__r.KanjoKamokuRef__r.CreditTaxKbn__c
		 								,PaymentInfoRef__r.Tran1Ref__r.Field7__r.CardAccountRef__c							// カード契約会社[2015/12/04 ADD]
		 								,PaymentInfoRef__r.Tran1Ref__r.Field7__r.CardAccountRef__r.Name						// カード契約会社[2015/12/04 ADD]
		 								,PaymentInfoRef__r.PaymentType__c
										// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ BEGIN
		 								,PaymentInfoRef__r.OffsetMoney__c
										// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ END
										from PaymentDetail__c where AccountAcountRef__c in :accIdsSet 
										// 前受付金は先に表示[前受付金の場合、TTendRef__cはNULL]
										Order By AccountAcountRef__c, PaymentInfoRef__r.TTendRef__c NULLS last, Name ]) {
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
			// 2015/12/04 カード手数料明細は内訳機能に出力機能の追加(手数料取得の契約会社ID) BEGIN
			if (pay.PaymentInfoRef__r.TTendRef__r.PayProductRef__r.CardAccountRef__c != null) {
				tesusyoAccIdsSet.add(pay.PaymentInfoRef__r.TTendRef__r.PayProductRef__r.CardAccountRef__c);
			} else if (pay.PaymentInfoRef__r.Tran1Ref__r.Field7__r.CardAccountRef__c != null) {
				tesusyoAccIdsSet.add(pay.PaymentInfoRef__r.Tran1Ref__r.Field7__r.CardAccountRef__c);
			}
			// 2015/12/04 カード手数料明細は内訳機能に出力機能の追加(手数料取得の契約会社ID) END
		}
		// 2015/12/04 カード手数料明細は内訳機能に出力機能の追加 BEGIN
		if (!tesusyoAccIdsSet.isEmpty()) {
			// 2016/03/21 手数料カテゴリ１は抽出条件に追加
			for (ChargeInfo__c chargeItem : [select id,PayChargeFlg__c,SalesRate__c,AccountRef__c,AccountRef__r.RoundType__c from ChargeInfo__c where AccountRef__c in :tesusyoAccIdsSet And SalesRate__c > 0 And CategoryMain__c = :AccountingSyncBatchHelp.TESURYO_DIV_CARD ]) {
				// 手数料支払TRUEのみの場合、関連FILTER対応する
				// 2016/04/21 販売手数料は内訳出力場合、手数料支払＝FALSE制御条件追加 BEGIN
				//if (pCcInfo.cardTesuryoTrueOnly && chargeItem.PayChargeFlg__c != true) continue; 
				if (pCcInfo.cardTesuryoTrueOnly != null && (pCcInfo.cardTesuryoTrueOnly != chargeItem.PayChargeFlg__c)) continue;
				// 2016/04/21 販売手数料は内訳出力場合、手数料支払＝FALSE制御条件追加 END
				Id accId = chargeItem.AccountRef__c;
				if (!tesuryoInfMap.containsKey(accId)) tesuryoInfMap.put(accId, new List<ChargeInfo__c>());
				tesuryoInfMap.get(accId).add(chargeItem);
			}
		}
		// 2015/12/04 カード手数料明細は内訳機能に出力機能の追加 END
		// 2015/12/21 販売手数料情報を仕訳情報に追加する BEGIN
		// 販売手数料定義情報の取得を行う
		//AccountingSyncBatchHelp accSyncHelp = null;
		if (!agtTesuryoAccIdMap.isEmpty()) {
			//accSyncHelp = new AccountingSyncBatchHelp(gShopCode);
			agtTesuryoInfMap = calSalesAgtTesuryoInfo(pCcInfo, agtTesuryoAccIdMap);
		}
		// 2015/12/21 販売手数料情報を仕訳情報に追加する END
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
										pCcInfo);
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
// 2019/09/20 多税率機能対応 WSQ BEGIN
				//Decimal amountIncTax = 0;	// 税込み合計金額
				//Decimal amountNoTax  = 0;	// 税抜き合計金額
				// 消費税列の情報は最後に新規行目追加を行う標識フラグ
				// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
				//Boolean isAddTaxInNewLine = true;
				//Decimal amountServiceNoTax = 0;         // サビース料税抜き合計金額
				// map<税率，該当税率の合計金額>
				map<decimal,decimal> amountIncTaxMap = new map<decimal,decimal>(); 	// 税込み合計金額
				// map<税率，該当税率の合計金額>
				map<decimal,decimal> amountNoTaxMap = new map<decimal,decimal>(); 	// 税抜き合計金額
				// map<税率，該当税率の サビース金額>
				map<decimal,decimal> amountServiceNoTaxMap = new map<decimal,decimal>(); 	// サビース料税抜き合計金額
				// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ BEGIN
				// サビース料の消費税が出力必要場合 #9199
				map<decimal,decimal> amountServiceTaxMap = new map<decimal,decimal>(); 	// サビース料の消費税情報
				// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ END
// 2019/09/20 多税率機能対応 WSQ END
                Integer ttendOutSize = 0;            // 会計支払明細の最大行数
                Integer trandOutSize = 0;            // 会計明細の最大行数
                Integer currRowIdx = 0;                 // 現在処理の行目番号
				// 該当会計の消費税行表記済フラグ
				//Integer tranIsEmptyLineNo = 0;
				// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
				String SingAccCsvTemplate = getSingAccCsvTemplate(acc, startNo, CsvTemplate, false);
				
				// 販売手数料は内訳として、出力機能の対応 BEGIN
				// agtTesuryoInfMap
				// 2016/07/07 BEGIN
				//PaymentDetail__c agtTesuryoTtend = null;
				// 販売手数料金額を格納する
				list<Decimal> agetSalesRate = null;
				// 2016/07/07 END
				// 2016/04/21 販売手数料は内訳出力場合、手数料支払＝FALSE制御条件追加 BEGIN
				//if (agtTesuryoInfMap.containsKey(acc.Id)) {
				ChargeInfo__c chargeInfo = agtTesuryoInfMap.get(acc.Id);
				// 販売手数料の手数料支払＝FALSEのみ、販売手数料（内訳）は出力する
				//if (chargeInfo != null && !chargeInfo.PayChargeFlg__c) {
				// 2016/04/21 販売手数料は内訳出力場合、手数料支払＝FALSE制御条件追加 END
				if (agtTesuryoInfMap.containsKey(acc.Id)) {
					// 会計明細（プランBreakdown項目の金額から合計金額を加算して、販売手数料金額を計算する）
					Decimal planSummary = 0;
					for (Tran1__c tran : trans) {
						// 親存在 && 親関連の処理種別はプラン場合、該当金額を合計する
						if (tran.ParentTran1Ref__c != null &&
							tran.ParentTran1Ref__r.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) {
							planSummary += tran.Field41__c;
						}
					}

					// 合計金額が存在
					if (planSummary > 0) {
						// 手数料情報
						// 2016/04/21 販売手数料は内訳出力場合、手数料支払＝FALSE制御条件追加 BEGIN
						//ChargeInfo__c chargeInfo = agtTesuryoInfMap.get(acc.Id);
						// 2016/04/21 販売手数料は内訳出力場合、手数料支払＝FALSE制御条件追加 END
						// 手数料レート
						Decimal tesuRate = CommUtils.nullToZero(chargeInfo.SalesRate__c) / 100;
						// 端数処理区分
						String tesuRoundType = CommUtils.nullToBlank(chargeInfo.AccountRef__r.RoundType__c);
						// 該当販売手数料を計算を行う
						// 2016/07/07 BEGIN
						agetSalesRate = new list<decimal>();
						agetSalesRate.add(tesuryoCalProcess(planSummary,tesuRate,tesuRoundType));
						agetSalesRate.add(planSummary);
						agetSalesRate.add(CommUtils.nullToZero(chargeInfo.SalesRate__c));
						// 2016/07/07 END
					}
					/* 2016/07/11 DELETE
					if (CommUtils.nullToZero(agetSalesRate) != 0) {
						// 支払メデイア情報から金額を抜きする
						// 支払メデイアのリストを取得して、最大支払金額を取得する
						for (PaymentDetail__c ttendPay : ttends) {
							// 会計支払以外の場合
							if (ttendPay.PaymentInfoRef__r.TTendRef__c == null && ttendPay.PaymentInfoRef__r.Tran1Ref__c == null)  continue;
							// 会計支払　かつ　該当支払情報のメデイア情報は指定反映をチェックする
							// 2016/03/19 販売手数料の仕訳出力の場合 BEGIN
							//if (!gccInfo.agtMediaTypeSet.isEmpty()) {
							//if (!gccInfo.agtMediaTypeSet.contains(ttendPay.PaymentInfoRef__r.TTendRef__r.Field2__c)) continue;
							//}
							// 2016/03/19 販売手数料の仕訳出力の場合 END
							// 販売手数料は売掛金/クポーンにより、大く金の場合、対象外
							Decimal usedAmount = CommUtils.nullToZero(ttendPay.UsedAmount__c);
							if (usedAmount < agetSalesRate) continue;
							// 販売手数料金額は自動計算先を設定する
							if (agtTesuryoTtend == null) agtTesuryoTtend = ttendPay;
							else {
								// 一番大き支払金額の支払メデイアに処理対象を設定する
								if (agtTesuryoTtend.UsedAmount__c <  usedAmount) {
									agtTesuryoTtend = ttendPay;
								}
							}
							
						}
					}*/
				}
				// 販売手数料は内訳として、出力機能の対応 END
				// 2016/07/21 カード手数料・販売手数料は別行目に出力機能制御追加　BEGIN
				// 販売手数料とカード手数料出力明細情報を配列に格納する
				list<string> cardAndSalesLines = new List<string>();
				// 2016/07/21 カード手数料・販売手数料は別行目に出力機能制御追加　END
// 2017/03/09 バッチ終了通知メールに支払いメディアが設定されていない、設定金額は合せないの会計データへのリンクを追加 BEGIN
Decimal leftAmount = 0;
Decimal rightAmount = 0;
// 2017/03/09 バッチ終了通知メールに支払いメディアが設定されていない、設定金額は合せないの会計データへのリンクを追加 END
				// 支払情報と会計明細両方共出力完了の場合、該当会計のCSV出力完了
				while (true) {			
				    // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
				    currRowIdx++;
				    // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
					Ttend__c ttend = null;
					Tran1__c ttran = null;	// 前受付金の残金の場合、自動作成の支払情報格納用変数[会計明細]
					// 2016/12/13 摘要項目の後ろに請求先を表示追加対応 BEGIN
					String wkAccountName = '';
					// 2016/12/13 摘要項目の後ろに請求先を表示追加対応 END
					// 支払情報を取得する
					PaymentDetail__c ttendPay = null;
					if (ttends.isEmpty()) ttendPay = new PaymentDetail__c();
					else ttendPay = ttends[0];
					
					// 会計支払明細情報が存在する場合
					if (ttendPay.Id != null) {
// 2020/01/21 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う） WSQ BEGIN
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
// 2020/01/21 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う） WSQ END
						// 処理済の場合、配列は外すので、常に残りの列から第一目の支払情報を取得する
						// 前受付金以外の支払情報の場合
						if (ttendPay.PaymentInfoRef__r.TTendRef__c != null) {
							// 会計支払から支払情報を取得、該当支払関連の会計科目情報を取得する
							ttend = ttendPay.PaymentInfoRef__r.TTendRef__r;
							// 支払金額は支払情報から取得、設定する
							ttend.Field19__c = String.valueof(ttendPay.DepositAmount__c);	// 預かり金額
							ttend.Field20__c = String.valueof(ttendPay.UsedAmount__c);		// 利用金額
							ttend.Field21__c = String.valueof(ttendPay.RemainingMoney__c);	// 釣銭（差額）金額
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
// 2020/01/21 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う） WSQ BEGIN
}
// 2020/01/21 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う） WSQ END
						// 注意：支払メデイアは売掛金の場合、補助科目に、会計関連の取引先のID__C項目のコード取得して、設定する
						// 関連の商品情報が存在する場合、関連の支払情報の会計科目設定情報により、CSVへ出力する
						// 支払情報に対して、関連の支払商品がなかったの場合、XML設定情報により、関連の会計商品情報を取得する
						// 2020/01/21 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う） WSQ BEGIN
						//if (ttend.PayProductRef__c == null) {
						if(ttend.PayProductRef__c == null && !gccInfo.isUseDayOutMode){
						// 2020/01/21 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う） WSQ END
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
						if (ttendAccMst != null) ttendAccMst = ttendAccMst.clone(false,true);
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
									ttendAccMst.KanjoKamokuRef__r.KanjoHojoname__c = CommUtils.nullToBlank(acc.relaccount__r.Account.Name);
								}
							}
						}
						// 2016/09/07 支払情報の補助科目「金券種別、カード種別」出力を行う BEGIN
						if (ttendAccMst != null) {
							if (ttendAccMst.KanjoKamokuRef__r != null && CommUtils.isBlank(ttendAccMst.KanjoKamokuRef__r.KanjoHojoname__c)) {
								if (ttend.Field2__c == CommConst.MEDIA_TYPE_CD_02) {
									// 補助科目はカード種別項目から出力する
									ttendAccMst.KanjoKamokuRef__r.KanjoHojoname__c = Commutils.nullToBlank(ttend.CardTypeLst__c);
								} else if (ttend.Field2__c == CommConst.MEDIA_TYPE_CD_11 || ttend.Field2__c == CommConst.MEDIA_TYPE_CD_12) {
									// 補助科目は金券種別項目から出力する
									ttendAccMst.KanjoKamokuRef__r.KanjoHojoname__c = Commutils.nullToBlank(ttend.CouponTypeLst__c);
								} else if (ttend.Field2__c == CommConst.MEDIA_TYPE_CD_03 && !CommUtils.isBlank(acc.relaccount__r.Account.Name)) {
									// 補助科目は請求先名を出力する　
									ttendAccMst.KanjoKamokuRef__r.KanjoHojoname__c = Commutils.nullToBlank(acc.relaccount__r.Account.Name);
								}
								// 2016/10/11 支払情報の補助科目「売掛種別」BEGIN
								if (ttend.Field2__c == CommConst.MEDIA_TYPE_CD_03 && CommUtils.isBlank(ttendAccMst.KanjoKamokuRef__r.KanjoHojoname__c)) {
									// 補助科目はカード種別項目から出力する
									ttendAccMst.KanjoKamokuRef__r.KanjoHojoname__c = CommUtils.nullToBlank(acc.relaccount__r.Name);
								}
								// 2016/10/11 支払情報の補助科目「売掛種別」END
							} 
							ttend.PayProductRef__r = ttendAccMst;
						}
						// 2016/09/07 支払情報の補助科目「金券種別、カード種別」出力を行う END
						/* 2016/01/25 一時CLOSE、2016/01/29 Release予定
						// カード支払の売掛金の場合、カード契約情報から補助科目を取得する
						if (ttend.Field2__c == CommConst.MEDIA_TYPE_CD_02 && ttendAccMst.KanjoKamokuRef__r != null) {
							if (ttendAccMst.CardAccountRef__c != null) {
								if (CommUtils.isBlank(ttendAccMst.KanjoKamokuRef__r.KanjoHojocode__c)) {
									ttendAccMst.KanjoKamokuRef__r.KanjoHojocode__c = CommUtils.nullToBlank(ttendAccMst.CardAccountRef__r.Name);
								}
								if (CommUtils.isBlank(ttendAccMst.KanjoKamokuRef__r.KanjoHojoname__c)) {
									ttendAccMst.KanjoKamokuRef__r.KanjoHojoname__c = CommUtils.nullToBlank(ttendAccMst.CardAccountRef__r.Name);
								}
							}
						}*/
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
								// 2020/01/21 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う） WSQ BEGIN
								if (pCcInfo.isUseDayOutMode) {
									// 2020/09/15 連泊の支払を入れた際の挙動修正2 WSQ BEGIN
									// 架空データの場合、売掛金で出力、実際データの場合、前受金を出力する
									kankoMst = pKanjoKamokuMstMap.get(pCcInfo.apRightKanjoSeqNo);
									// 2020/09/15 連泊の支払を入れた際の挙動修正2 WSQ END
								}
								// 2020/01/21 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う） WSQ END
								if (kankoMst == null) kankoMst = new KanjoKamoku__c();
								// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 BEGIN
								kankoMst = kankoMst.clone(false,true);
								if (!CommUtils.isBlank(pCcInfo.notaxkbn)) kankoMst.CreditTaxKbn__c = pCcInfo.notaxkbn;
								// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 END
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
					// 2016/12/13 摘要項目の後ろに請求先を表示追加対応 BEGIN
					if (ttend.Field2__c == CommConst.MEDIA_TYPE_CD_03) {
						wkAccountName = getMemoAccountNameToCsv(acc.relaccount__r);
					}
					// 2016/12/13 摘要項目の後ろに請求先を表示追加対応 END
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
					
					// CSVの左側の支払情報を作成する
					// １行目のCSV出力情報初期化設定[1会計単位]
					String csvLine = SingAccCsvTemplate;
					// CSV出力を行う【預かり金額】
					Decimal paymentAmount = Commutils.nullToZero(ttend.Field19__c);
					// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
					paymentAmount = formatOuputNumber(paymentAmount);
					// 2016/11/21 出力金額の小数点対応できる改善 END
// 2015/12/04 カード手数料明細は内訳機能に出力機能の追加 BEGIN
// 実際の利用金額から手数料を計算を行う
// 2016/07/07 BEGIN
list<Decimal> cardRate = tesuryoProcess(pCcInfo,ttend,tesuryoInfMap,pKanjoKamokuMstMap);
//System.debug(loggingLevel.INFO, 'cardRate:::'+cardRate);
// 2016/07/07 販売手数料とカード手数料は内訳出力対象外になる
//if (cardRate != null) {
	// 金額計算を行う
	//paymentAmount = paymentAmount - cardRate;
//}
// 2015/12/04 カード手数料明細は内訳機能に出力機能の追加 END
// 販売手数料は内訳として、出力機能の対応 BEGIN
// 2016/07/07 販売手数料とカード手数料は内訳出力対象外になる
//if (agtTesuryoTtend != null && agetSalesRate != null && agtTesuryoTtend.id == ttendPay.Id) {
	//paymentAmount = paymentAmount - agetSalesRate;
//}
// 販売手数料は内訳として、出力機能の対応 END
// 2016/07/07 END
					// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 BEGIN
					String debittaxkbn = CommUtils.nullToBlank(ttend.PayProductRef__r.KanjoKamokuRef__r.DebitTaxKbn__c);
					if (!CommUtils.isBlank(pCcInfo.notaxkbn) && ttend.PayProductRef__c != null) debittaxkbn = pCcInfo.notaxkbn;
					// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 END
					csvLine = csvLine
						.Replace('$$_借方科目コード_$$'	, CommUtils.nullToBlank(ttend.PayProductRef__r.KanjoKamokuRef__r.KanjocodeCode__c))
						//.Replace('$$_借方科目_$$'			, CommUtils.nullToBlank(ttend.PayProductRef__r.KanjoKamokuRef__r.Name))
						// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
						//.Replace('$$_借方科目_$$'			, processFilter(CommUtils.nullToBlank(ttend.PayProductRef__r.KanjoKamokuRef__r.Name)))
						.Replace('$$_借方科目_$$'			, processEscapeKanji(processFilter(CommUtils.nullToBlank(ttend.PayProductRef__r.KanjoKamokuRef__r.Name))))
						// 2016/12/14 漢字にカンマを含めている改善対応 END
						.Replace('$$_借方補助コード_$$'	, CommUtils.nullToBlank(ttend.PayProductRef__r.KanjoKamokuRef__r.KanjoHojocode__c))
						// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
						//.Replace('$$_借方補助_$$'			, CommUtils.nullToBlank(ttend.PayProductRef__r.KanjoKamokuRef__r.KanjoHojoname__c))
						.Replace('$$_借方補助_$$'			, processEscapeKanji(CommUtils.nullToBlank(ttend.PayProductRef__r.KanjoKamokuRef__r.KanjoHojoname__c)))
						// 2016/12/14 漢字にカンマを含めている改善対応 END
						// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 BEGIN
						//.Replace('$$_借方税区分_$$'		, CommUtils.nullToBlank(ttend.PayProductRef__r.KanjoKamokuRef__r.DebitTaxKbn__c))
						.Replace('$$_借方税区分_$$'		, debittaxkbn)
						// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 END
						// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
						//.Replace('$$_借方金額_$$'			, String.valueOf(paymentAmount.intValue()));
						.Replace('$$_借方金額_$$'			, String.valueOf(paymentAmount));
						// 2016/11/21 出力金額の小数点対応できる改善 END
// 2017/03/09 バッチ終了通知メールに支払いメディアが設定されていない、設定金額は合せないの会計データへのリンクを追加 BEGIN
leftAmount += paymentAmount;
// 2017/03/09 バッチ終了通知メールに支払いメディアが設定されていない、設定金額は合せないの会計データへのリンクを追加 END
// 2016/09/23 仕訳Rollup機能追加対応 BEGIN
setupRollupInfo(accs[0].frs__r.Name,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ BEGIN
				//processFilter(CommUtils.nullToBlank(ttend.PayProductRef__r.KanjoKamokuRef__r.Name)),
				ttend.PayProductRef__r.KanjoKamokuRef__r,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ END
				pCcInfo.debdepartcode,
				debittaxkbn,
				// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
				//String.valueOf(paymentAmount.intValue()),
				String.valueOf(paymentAmount),
				// 2016/11/21 出力金額の小数点対応できる改善 END
				pCcInfo.debconsumptax,
				ROLLUP_TYPE.SALES_L);	
// 2016/09/23 仕訳Rollup機能追加対応 END		
					// 右側のCSV出力情報を取得する
                    // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
					//if (tranIsEmptyLineNo != 1) {	// tranIsEmptyLineNo == 1 の場合、交換文字列処理なし、後で交換を行う
					// 会計明細は実際存在する場合、該当明細情報はそのまま出力を行う
					if (!transIsEmpty) {
				    // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
						csvLine = csvLine
							.Replace('$$_貸方科目コード_$$'	, CommUtils.nullToBlank(ttran.Field7__r.KanjoKamokuRef__r.KanjocodeCode__c))
							//.Replace('$$_貸方科目_$$'			, CommUtils.nullToBlank(ttran.Field7__r.KanjoKamokuRef__r.Name))
							// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
							//.Replace('$$_貸方科目_$$'			, processFilter(CommUtils.nullToBlank(ttran.Field7__r.KanjoKamokuRef__r.Name)))		
							.Replace('$$_貸方科目_$$'			, processEscapeKanji(processFilter(CommUtils.nullToBlank(ttran.Field7__r.KanjoKamokuRef__r.Name))))
							// 2016/12/14 漢字にカンマを含めている改善対応 END					
							.Replace('$$_貸方補助コード_$$'	, CommUtils.nullToBlank(ttran.Field7__r.KanjoKamokuRef__r.KanjoHojocode__c))
							// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
							//.Replace('$$_貸方補助_$$'			, CommUtils.nullToBlank(ttran.Field7__r.KanjoKamokuRef__r.KanjoHojoname__c))
							.Replace('$$_貸方補助_$$'			, processEscapeKanji(CommUtils.nullToBlank(ttran.Field7__r.KanjoKamokuRef__r.KanjoHojoname__c)))
							// 2016/12/14 漢字にカンマを含めている改善対応 END
							.Replace('$$_貸方税区分_$$'		, CommUtils.nullToBlank(ttran.Field7__r.KanjoKamokuRef__r.CreditTaxKbn__c));
						String rightAmountStr = '';
						// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
						String lineTaxRateStr = '0';
						// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
						// 実際の会計明細の場合
						if (ttran.Id != null) {
							// 2016/09/23 仕訳Rollup機能追加対応 BEGIN
							// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
							// 2018/11/05 仕訳明細は税込・税抜出力選択できるように改善対応 WSQ BEGIN
							decimal locTanNoTax = formatOuputNumber(CommUtils.nullToZero(ttran.GoukeinoneTax__c));
							if (pCcInfo.isIncTaxFlg) locTanNoTax = formatOuputNumber(CommUtils.nullToZero(ttran.Field41__c));
							// 2018/11/05 仕訳明細は税込・税抜出力選択できるように改善対応 WSQ END
							// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN                						
							List<Decimal> wkLocTanNoTax = calServiceAmount(locTanNoTax, ttran);
							locTanNoTax = wkLocTanNoTax[0];
							// 2019/09/20 多税率機能対応 WSQ BEGIN
						 	//amountServiceNoTax += wkLocTanNoTax[1];
						 	decimal taxrate = CommUtils.nullToZero(ttran.TaxRate__c); // 消費税率
						 	// XMLに複数率を定義されない場合、消費税、サビース料は合計格納
						 	if (pCcInfo.taxKanjoMap.isEmpty()) taxrate = CONST_SUM_TAX_RATE;
						 	if (!amountServiceNoTaxMap.containskey(taxrate)) amountServiceNoTaxMap.put(taxrate, wkLocTanNoTax[1]);
						 	else amountServiceNoTaxMap.put(taxrate, (amountServiceNoTaxMap.get(taxrate) + wkLocTanNoTax[1]));
						 	// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ BEGIN
							// サビース料の消費税が出力必要場合 #9199
							if (!gccInfo.isIncTaxFlg && gccInfo.isOutTaxToSameLine) {
						 		if (!amountServiceTaxMap.containskey(taxrate)) amountServiceTaxMap.put(taxrate, wkLocTanNoTax[2]);
						 		else amountServiceTaxMap.put(taxrate, (amountServiceTaxMap.get(taxrate) + wkLocTanNoTax[2]));
							}
							// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ END
						 	// 2019/09/20 多税率機能対応 WSQ END
							// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
							//rightAmountStr = String.valueOf(CommUtils.nullToZero(ttran.GoukeinoneTax__c).intValue());
							rightAmountStr = String.valueOf(locTanNoTax);
							// 2016/11/21 出力金額の小数点対応できる改善 END
						 	//csvLine = csvLine
						 	//	.Replace('$$_貸方金額_$$'			, String.valueOf(CommUtils.nullToZero(ttran.GoukeinoneTax__c).intValue()));
						 	// 2016/09/23 仕訳Rollup機能追加対応 END
						 	// 実際利用金額	
						 	// 2019/09/20 多税率機能対応 WSQ BEGIN
						 	//amountIncTax += CommUtils.nullToZero(ttran.Field41__c);
			 				if (!amountIncTaxMap.containskey(taxrate)) amountIncTaxMap.put(taxrate, CommUtils.nullToZero(ttran.Field41__c));
			 				else amountIncTaxMap.put(taxrate, (amountIncTaxMap.get(taxrate) + CommUtils.nullToZero(ttran.Field41__c)));
						 	// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
						 	//amountNoTax  += CommUtils.nullToZero(ttran.GoukeinoneTax__c);
						 	//amountNoTax  += locTanNoTax;
			 				if (!amountNoTaxMap.containskey(taxrate)) amountNoTaxMap.put(taxrate, locTanNoTax);
			 				else amountNoTaxMap.put(taxrate, (amountNoTaxMap.get(taxrate) + locTanNoTax));
						 	// 2019/09/20 多税率機能対応 WSQ END
						 	// 2016/11/21 出力金額の小数点対応できる改善 END
						 	// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
						 	// 2020/01/21 税額を貸方税額、借方税額に出力した際に小数点以下問題対応 WSQ BEGIN
						 	// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ BEGIN
							// サビース料の消費税が出力必要場合 #9199
							lineTaxRateStr = String.valueOf(formatOuputNumber(CommUtils.nullToZero(ttran.Field41__c) - locTanNoTax - wkLocTanNoTax[1] - wkLocTanNoTax[2]));
							// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ END
						 	// 2020/01/21 税額を貸方税額、借方税額に出力した際に小数点以下問題対応 WSQ END
						 	// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
						} 
						// 表示ため仮作成の会計明細
						else {
							// 2016/09/23 仕訳Rollup機能追加対応 BEGIN
							// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
							//rightAmountStr = String.valueOf(CommUtils.nullToZero(ttran.Field23__c).intValue());
							rightAmountStr = String.valueOf(formatOuputNumber(CommUtils.nullToZero(ttran.Field23__c)));
							// 2016/11/21 出力金額の小数点対応できる改善 END
						 	//csvLine = csvLine
						 	//	.Replace('$$_貸方金額_$$'			, String.valueOf(CommUtils.nullToZero(ttran.Field23__c).intValue()));
							// 2016/09/23 仕訳Rollup機能追加対応 END
						}
// 2016/09/23 仕訳Rollup機能追加対応 BEGIN
						csvLine = csvLine
						 		.Replace('$$_貸方金額_$$'			, rightAmountStr);
						// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
						if (pCcInfo.isOutTaxToSameLine) {
							csvLine = csvLine.Replace('$$_貸方消費税額_$$'		, lineTaxRateStr);
						}
						// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
						 		
// 2017/03/09 バッチ終了通知メールに支払いメディアが設定されていない、設定金額は合せないの会計データへのリンクを追加 BEGIN
rightAmount += CommUtils.nullToZero(rightAmountStr);
// 2017/03/09 バッチ終了通知メールに支払いメディアが設定されていない、設定金額は合せないの会計データへのリンクを追加 END

setupRollupInfo(accs[0].frs__r.Name,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ BEGIN
				//processFilter(CommUtils.nullToBlank(ttran.Field7__r.KanjoKamokuRef__r.Name)),
				ttran.Field7__r.KanjoKamokuRef__r,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ END
				pCcInfo.credepartcode,
				CommUtils.nullToBlank(ttran.Field7__r.KanjoKamokuRef__r.CreditTaxKbn__c),
				rightAmountStr,
				// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
				//pCcInfo.creconsumptax,
				(pCcInfo.isOutTaxToSameLine ? lineTaxRateStr : pCcInfo.creconsumptax),
				// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
				ROLLUP_TYPE.SALES_R);
// 2016/09/23 仕訳Rollup機能追加対応 END
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

					// 2016/12/13 摘要項目の後ろに請求先を表示追加対応 BEGIN
					csvLine = addAccountInfToCsv(csvLine, wkAccountName);
					// 2016/12/13 摘要項目の後ろに請求先を表示追加対応 END
					oneAccCsv += csvLine;
// 2015/12/04 カード手数料明細は内訳機能に出力機能の追加 BEGIN					
// 手数料情報の作成
if (cardRate != null) {
	// 2016/07/07 販売手数料とカード手数料は内訳出力対象外になる BEGIN
	//PaymentDetail__c tesuryoPay = createVirTesuryoPayDetail(ttendPay, cardRate,pCcInfo,pKanjoKamokuMstMap);
	Classification__c cardNewItem = createVirTesuryoPayDetail(acc, ttendPay, cardRate,pCcInfo,pKanjoKamokuMstMap, startNo, CsvTemplate,cardAndSalesLines);
	if (cardNewItem != null) insClassificationLst.add(cardNewItem);
	cardRate = null;
	//if (ttends.isEmpty()) ttends.add(tesuryoPay);
	//else ttends.add(0,tesuryoPay);
	// 2016/07/07 販売手数料とカード手数料は内訳出力対象外になる END
}
// 2015/12/04 カード手数料明細は内訳機能に出力機能の追加 END
// 販売手数料は内訳として、出力機能の対応 BEGIN
//if (agtTesuryoTtend != null && agetSalesRate != null && agtTesuryoTtend.id == ttendPay.Id) {
if (agetSalesRate != null ) {
	// 2016/04/21 販売手数料は内訳出力場合、手数料支払＝FALSE制御条件追加 BEGIN
	//ChargeInfo__c chargeInfo = agtTesuryoInfMap.get(acc.Id);
	// 2016/04/21 販売手数料は内訳出力場合、手数料支払＝FALSE制御条件追加 END
	// 2016/07/07 販売手数料とカード手数料は内訳出力対象外になる BEGIN
	//PaymentDetail__c agtTesuryoPay = createVirAgtTesuryoPayDetail(ttendPay, agetSalesRate,pCcInfo,pKanjoKamokuMstMap,chargeInfo);
	Classification__c agtNewItem = createVirAgtTesuryoPayDetail(acc, ttendPay, agetSalesRate,pCcInfo,pKanjoKamokuMstMap,chargeInfo, startNo, CsvTemplate,cardAndSalesLines);
	if (agtNewItem != null) insClassificationLst.add(agtNewItem);
	agetSalesRate = null;
	//if (ttends.isEmpty()) ttends.add(agtTesuryoPay);
	//else ttends.add(0,agtTesuryoPay);
	//agtTesuryoTtend = null;
	// 2016/07/07 販売手数料とカード手数料は内訳出力対象外になる END
}
// 販売手数料は内訳として、出力機能の対応 END
					// 該当会計関連のPCAのCSV情報を全部出力済
					if (ttends.isEmpty() && trans.isEmpty()) break;


//if (i > 40) break;
				} // End while (true) [1会計のPCA連携CSV内容出力済]
// 2019/09/20 多税率機能対応 WSQ BEGIN
list<decimal> taxratelst = new list<decimal>();
for (decimal key : amountIncTaxMap.keyset()) {taxratelst.add(formattax(key));}
taxratelst.sort();//並び順設定
for (decimal taxrate : taxratelst) {
	decimal amountServiceNoTax = amountServiceNoTaxMap.get(taxrate);//サビース料金
 	// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ BEGIN
	// サビース料の消費税が出力必要場合 #9199
	decimal amountServiceTax = amountServiceTaxMap.get(taxrate);//サビース料金の消費税
	// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ END
	if (pCcInfo.serviceRkanjoMap.containsKey(taxrate)) pCcInfo.serviceRkanjoCode = pCcInfo.serviceRkanjoMap.get(taxrate);//サビース勘定科目
// 2019/09/20 多税率機能対応 WSQ END
				// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
				// サビース料個別出力の場合、サビース料（税抜き）情報はCSVへ反映を行う
				if (isOutServiceFlg && amountServiceNoTax > 0) {
                    // サビース料合計値を加算する　
                    // 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ BEGIN
                    // サビース料の消費税が出力必要場合 #9199
                    rightAmount += amountServiceNoTax + CommUtils.nullToZero(amountServiceTax);
		    // 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ END
				    // サビース料勘定科目情報を取得する
				    KanjoKamoku__c serviceKankoMst = null;
				    if (pKanjoKamokuMstMap.containsKey(pCcInfo.serviceRkanjoCode)) serviceKankoMst = pKanjoKamokuMstMap.get(pCcInfo.serviceRkanjoCode).clone(false,true);
				    if (serviceKankoMst == null) serviceKankoMst = new KanjoKamoku__c();
				    // 左の空欄は右の方により、多い場合、右側にREPLACE
                    if (ttendOutSize > trandOutSize) {
				        // 指定行目のCSV情報を取得、該当CSV情報を入替えする
					// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ BEGIN
					// サビース料の消費税が出力必要場合 #9199
				        oneAccCsv = getTaxCsvLine(oneAccCsv, amountServiceNoTax, serviceKankoMst, acc, false, true, amountServiceTax);
					// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ END
				    } else {
				        // 右側の行目は多い場合、新規行目を出力追加する
					// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ BEGIN
					// サビース料の消費税が出力必要場合 #9199
				        oneAccCsv += getTaxCsvLine(addAccountInfToCsv(SingAccCsvTemplate,''), amountServiceNoTax, serviceKankoMst, acc, true, true, amountServiceTax);
					// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ END
				    }
                    // 右側出力行目は１行増える
                    trandOutSize++;
				}
// 2019/09/20 多税率機能対応 WSQ BEGIN
}
// 2019/09/20 多税率機能対応 WSQ END
				// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
				// 消費税情報はCSVへ反映する
				// 2018/05/02 NullPoint Error BugFix BEGIN
				//KanjoKamoku__c kankoMst = pKanjoKamokuMstMap.get(pCcInfo.taxKanjoCode).clone(false,true);
				//if (kankoMst == null) kankoMst = new KanjoKamoku__c();
// 2019/09/20 多税率機能対応 WSQ BEGIN
for (decimal taxrate : taxratelst) {
	decimal amountIncTax = amountIncTaxMap.get(taxrate);//税込み金額
	decimal amountNoTax = amountNoTaxMap.get(taxrate);//税抜金額
	decimal amountServiceNoTax = amountServiceNoTaxMap.get(taxrate);//サビース料金
 	// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ BEGIN
	// サビース料の消費税が出力必要場合 #9199
	decimal amountServiceTax = amountServiceTaxMap.get(taxrate);//サビース料金の消費税
	// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ END
	if (pCcInfo.taxKanjoMap.containsKey(taxrate)) pCcInfo.taxKanjoCode = pCcInfo.taxKanjoMap.get(taxrate);
// 2019/09/20 多税率機能対応 WSQ END
				KanjoKamoku__c kankoMst = pKanjoKamokuMstMap.containsKey(pCcInfo.taxKanjoCode) 
										? pKanjoKamokuMstMap.get(pCcInfo.taxKanjoCode).clone(false,true)
										: new KanjoKamoku__c();
				// 2018/05/02 NullPoint Error BugFix END
				// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
				//Decimal taxPayAmount = amountIncTax - amountNoTax;
 				// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ BEGIN
				// サビース料の消費税が出力必要場合 #9199
				//Decimal taxPayAmount = amountIncTax - amountNoTax - amountServiceNoTax;
				Decimal taxPayAmount = amountIncTax - amountNoTax - amountServiceNoTax - CommUtils.nullToZero(amountServiceTax);
				// 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ END
				// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
// 2017/03/09 バッチ終了通知メールに支払いメディアが設定されていない、設定金額は合せないの会計データへのリンクを追加 BEGIN
rightAmount += CommUtils.nullToZero(taxPayAmount);
// 2017/03/09 バッチ終了通知メールに支払いメディアが設定されていない、設定金額は合せないの会計データへのリンクを追加 END
				// 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
				//if (!isAddTaxInNewLine) {

// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN				
// 消費税は該当行目に表示するため、個別消費税出力が不要になる　
if (pCcInfo.isOutTaxToSameLine) {
	taxPayAmount = 0;
	oneAccCsv = oneAccCsv.Replace('$$_貸方消費税額_$$'		, '0');
}
// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END

				if (taxPayAmount > 0) {
					if (ttendOutSize > trandOutSize) {
                // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
						// 既存の情報から入り替えする
						// 2016/09/23 仕訳Rollup機能追加対応 BEGIN
						// oneAccCsv = getTaxCsvLine(oneAccCsv, taxPayAmount, kankoMst);
						// 2016/12/13 BUGFIX 消費税金額がない場合、無条件な空文字列を戻る不具合改修 BEGIN
						oneAccCsv = getTaxCsvLine(oneAccCsv, taxPayAmount, kankoMst, acc, false, true);
						// 2016/12/13 BUGFIX 消費税金額がない場合、無条件な空文字列を戻る不具合改修 END
						// 2016/09/23 仕訳Rollup機能追加対応 END
					} else {
						// 新行目に消費税情報を作成する
						// 2016/09/23 仕訳Rollup機能追加対応 BEGIN
						// oneAccCsv += getTaxCsvLine(SingAccCsvTemplate, taxPayAmount, kankoMst);
						// 2016/12/13 摘要項目の後ろに請求先を表示追加対応 BEGIN
						//oneAccCsv += getTaxCsvLine(SingAccCsvTemplate, taxPayAmount, kankoMst, acc);
						// 2016/12/13 BUGFIX 消費税金額がない場合、無条件な空文字列を戻る不具合改修 BEGIN
						oneAccCsv += getTaxCsvLine(addAccountInfToCsv(SingAccCsvTemplate,''), taxPayAmount, kankoMst, acc, true, true);
						// 2016/12/13 BUGFIX 消費税金額がない場合、無条件な空文字列を戻る不具合改修 END
						// 2016/12/13 摘要項目の後ろに請求先を表示追加対応 END
						// 2016/09/23 仕訳Rollup機能追加対応 END
					}
                    // 右側出力行目は１行増える
                    trandOutSize++;
				}
// 2019/09/20 多税率機能対応 WSQ BEGIN
}//for (decimal taxrate : taxratelst) {
// 2019/09/20 多税率機能対応 WSQ END
				// 残り部分は全部クリアを行う
				KanjoKamoku__c clearKankoMst = new KanjoKamoku__c();
				oneAccCsv = getTaxCsvLine(oneAccCsv, 0, clearKankoMst, acc, false);
				// 該当会計のCSV情報をマージする
				csvBody += oneAccCsv;
				// 2016/07/21 カード手数料・販売手数料は別行目に出力機能制御追加　BEGIN
				// 販売手数料とカード手数料明細情報を出力する
				if (!cardAndSalesLines.isEmpty()) {
					for (String wkLine : cardAndSalesLines) {
						csvBody += wkLine;
					}
				}
				// 2016/07/21 カード手数料・販売手数料は別行目に出力機能制御追加　END
// 2017/03/09 バッチ終了通知メールに支払いメディアが設定されていない、設定金額は合せないの会計データへのリンクを追加 BEGIN
// 2019/12/30 FREEEAPI连携機能 WGCH BEGIN
if(csvAccIdMap != null){
	// 日付_店铺Code_云票No
	String key = gRsvName + '_' + gShopCode + '_' + startNo;
	csvAccIdMap.put(key, acc.Id);
}
// 2019/12/30 FREEEAPI连携機能 WGCH END
warningCheck(leftAmount,rightAmount,startNo, acc.Id);
// 2017/03/09 バッチ終了通知メールに支払いメディアが設定されていない、設定金額は合せないの会計データへのリンクを追加 END
			} // End(新会計の明細出力済み)


			// 次の会計番号を計算する
			startNo++;
		}
		// 2016/07/11 販売手数料とカード手数料は内訳出力対象外になる BEGIN
    	// クリア
		String deleteQuery = 'select id from Classification__c where RsvAccountRef__c =:gRsvAccoutId  And (EventSource__c = :CONST_EVENTSRC_AGT OR EventSource__c = :CONST_EVENTSRC_CARD) ';
    	if (!CommUtils.isBlank(gShopCode)) deleteQuery+= ' And ShopInfoRef__r.ShopCode__c = :gShopCode for update ';
    	List<Sobject> existRsList = DataBase.query(deleteQuery);
    	if (!existRsList.isEmpty()) delete existRsList;
	    if (!insClassificationLst.isEmpty()) {
	    	// 新規追加
			insert insClassificationLst;
		}
		// 2016/07/11 販売手数料とカード手数料は内訳出力対象外になる END
		pCcInfo.startno = startNo;	// 伝票番号の再設定を行う
		return csvBody;
	}
	/**
	* 販売手数料定義情報から販売手数料の計算処理を行う
	* PARAM: map<会計,取引先ID> 
	* RETURN: 指定の会計IDに、関連の販売手数料金額を格納する
	**/
	private map<id,ChargeInfo__c> calSalesAgtTesuryoInfo(ConvertXmlConfig pCcInfo,
														map<Id,list<Id>> agtTesuryoAccIdMap) {

		// 会計情報の販売手数料情報の格納
		// map<会計ID,販売手数料値>
		map<id,ChargeInfo__c> accChargeInfoMap = new map<id, ChargeInfo__c>();
		// 2016/03/23 親関係の手数料は同時に定義されている場合、子取引先の手数料は優先で利用する BEGIN
		// 会計に関連の旅行会社、親旅行会社両方とも手数料を定義されている場合、個旅行会社の手数料は優先で利用するため、該当変数に、指定の会計ー＞関連のmap<子旅行会社ID->手数料,親旅行会社ID→手数料＞情報可能
		// map<会計ID,map<取引先ID、手数料定義>>
		map<id, map<id, ChargeInfo__c>> agtTesuryoSaleToAccMap = new map<Id, map<id, ChargeInfo__c>>();
		// 2016/03/23 親関係の手数料は同時に定義されている場合、子取引先の手数料は優先で利用する END
		// 内訳出力しない場合、処理中止
		if (!pCcInfo.isOutputUtiwake || agtTesuryoAccIdMap.isEmpty()) return accChargeInfoMap;
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
			String querySQL = 'select id,Field53__c,frs__c,'
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
					List<AccountAcount__c> chargeQueryAccLst = DataBase.query(query);
System.debug(logginglevel.INFO, 'chargeQueryAccLst:::' + chargeQueryAccLst);
					// 会計関連の手数料情報を格納する
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
						
						if (agtTesuryoAccIdMap.containsKey(acc.Id)) {
							// 2016/03/23 親関係の手数料は同時に定義されている場合、子取引先の手数料は優先で利用する BEGIN
							// 各会計に関連の複数手数料情報を格納変数初期化
							if (!agtTesuryoSaleToAccMap.containsKey(acc.id)) agtTesuryoSaleToAccMap.put(acc.Id, new map<id, ChargeInfo__c>());
							// 2016/03/23 親関係の手数料は同時に定義されている場合、子取引先の手数料は優先で利用する END
							// 手数料支払制御不要　OR　（手数料支払制御あり　AND　手数料支払＝TRUE）
							// 2016/04/21 販売手数料は内訳出力場合、手数料支払＝FALSE制御条件追加 BEGIN
							//if (pCcInfo.agtTesuryoTrueOnly != true || (pCcInfo.agtTesuryoTrueOnly && chargeInf.PayChargeFlg__c)) {
							if (pCcInfo.agtTesuryoTrueOnly == null || (pCcInfo.agtTesuryoTrueOnly == chargeInf.PayChargeFlg__c)) {
							// 2016/04/21 販売手数料は内訳出力場合、手数料支払＝FALSE制御条件追加 END
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
					if(!chargeInfoLst.isEmpty()) {
						// 2016/04/21 販売手数料は内訳出力場合、手数料支払＝FALSE制御条件追加 BEGIN
						//if (pCcInfo.agtTesuryoTrueOnly != true || 
						//	(pCcInfo.agtTesuryoTrueOnly && chargeInfoLst[0].PayChargeFlg__c)) {
						if (pCcInfo.agtTesuryoTrueOnly == null || pCcInfo.agtTesuryoTrueOnly == chargeInfoLst[0].PayChargeFlg__c) {
						// 2016/04/21 販売手数料は内訳出力場合、手数料支払＝FALSE制御条件追加 END
							accChargeInfoMap.put(accId, chargeInfoLst[0]);
						}
					}
					//  該当会計の販売手数料レートを設定済
					break;	
				}
			}
		} // for (Id accId : accIdsSet)
//System.debug(loggingLevel.INFO,'accChargeInfoMap[all]:' + accChargeInfoMap);
		return accChargeInfoMap;
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
		// 2016/12/13 摘要項目の後ろに請求先を表示追加対応 BEGIN
		SingAccCsvTemplate = addAccountInfToCsv(SingAccCsvTemplate, '');
		// 2016/12/13 摘要項目の後ろに請求先を表示追加対応 END
		String paymentAmount = String.valueOf(math.abs(CommUtils.nullToIntZero(ttendPay.DepositAmount__c)));
		// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 BEGIN
		String debittaxkbn = CommUtils.nullToBlank(kankoMstL.CreditTaxKbn__c);
		String credittaxkbn = CommUtils.nullToBlank(kankoMstR.CreditTaxKbn__c);
		if (!CommUtils.isBlank(gccInfo.notaxkbn)) {
			debittaxkbn = gccInfo.notaxkbn;
			credittaxkbn = gccInfo.notaxkbn;
		}
		// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 END	
		csv = SingAccCsvTemplate
				.Replace('$$_借方科目コード_$$'	,CommUtils.nullToBlank(kankoMstL.KanjocodeCode__c))
				//.Replace('$$_借方科目_$$'			,CommUtils.nullToBlank(kankoMstL.Name))
				// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
				//.Replace('$$_借方科目_$$'			,processFilter(CommUtils.nullToBlank(kankoMstL.Name)))
				.Replace('$$_借方科目_$$'			,processEscapeKanji(processFilter(CommUtils.nullToBlank(kankoMstL.Name))))
				// 2016/12/14 漢字にカンマを含めている改善対応 END
				.Replace('$$_借方補助コード_$$'	,CommUtils.nullToBlank(kankoMstL.KanjoHojocode__c))
				// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
				//.Replace('$$_借方補助_$$'			,CommUtils.nullToBlank(kankoMstL.KanjoHojoname__c))
				.Replace('$$_借方補助_$$'			,processEscapeKanji(CommUtils.nullToBlank(kankoMstL.KanjoHojoname__c)))
				// 2016/12/14 漢字にカンマを含めている改善対応 END
				// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 BEGIN
				//.Replace('$$_借方税区分_$$'		,CommUtils.nullToBlank(kankoMstL.CreditTaxKbn__c))
				.Replace('$$_借方税区分_$$'		,debittaxkbn)
				// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 END
				.Replace('$$_借方金額_$$'			,paymentAmount)
				// 消費税情報を設定する
				.Replace('$$_貸方科目コード_$$'	,CommUtils.nullToBlank(kankoMstR.KanjocodeCode__c))
				//.Replace('$$_貸方科目_$$'			,CommUtils.nullToBlank(kankoMstR.Name))
				// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
				//.Replace('$$_貸方科目_$$'			,processFilter(CommUtils.nullToBlank(kankoMstR.Name)))
				.Replace('$$_貸方科目_$$'			,processEscapeKanji(processFilter(CommUtils.nullToBlank(kankoMstR.Name))))
				// 2016/12/14 漢字にカンマを含めている改善対応 END
				.Replace('$$_貸方補助コード_$$'	,CommUtils.nullToBlank(kankoMstR.KanjoHojocode__c))
				// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
				//.Replace('$$_貸方補助_$$'			,CommUtils.nullToBlank(kankoMstR.KanjoHojoname__c))
				.Replace('$$_貸方補助_$$'			,processEscapeKanji(CommUtils.nullToBlank(kankoMstR.KanjoHojoname__c)))
				// 2016/12/14 漢字にカンマを含めている改善対応 END
				// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 BEGIN
				//.Replace('$$_貸方税区分_$$'		,CommUtils.nullToBlank(kankoMstR.CreditTaxKbn__c))
				.Replace('$$_貸方税区分_$$'		,credittaxkbn)
				// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 END
				.Replace('$$_貸方金額_$$'			,paymentAmount);
		// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
		if (gccInfo.isOutTaxToSameLine) csv = csv.Replace('$$_貸方消費税額_$$'		, '0');
		// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
// 2016/09/23 仕訳Rollup機能追加対応 BEGIN	
setupRollupInfo(acc.frs__r.Name,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ BEGIN
				//processFilter(CommUtils.nullToBlank(kankoMstL.Name)),
				kankoMstL,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ END
				gccInfo.debdepartcode,
				debittaxkbn,
				paymentAmount,
				gccInfo.debconsumptax,
				ROLLUP_TYPE.SALES_L);
									
setupRollupInfo(acc.frs__r.Name,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ BEGIN
				//processFilter(CommUtils.nullToBlank(kankoMstR.Name)),
				kankoMstR,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ END
				gccInfo.credepartcode,
				credittaxkbn,
				paymentAmount,
				gccInfo.creconsumptax,
				ROLLUP_TYPE.SALES_R);
// 2016/09/23 仕訳Rollup機能追加対応 END	
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
		else kankoMstL = kankoMstL.clone(false,false);
		// 貸方会計科目コード:
		//.PayProductRef__r.KanjoKamokuRef__r.KanjocodeCode__c
		Ttend__c ttend = ttendPay.PaymentInfoRef__r.TTendRef__r;
		Tran1__c tran1 = ttendPay.PaymentInfoRef__r.Tran1Ref__r;
		KanjoKamoku__c kankoMstR = ( ttend != null ? ttend.PayProductRef__r.KanjoKamokuRef__r : tran1.Field7__r.KanjoKamokuRef__r);
		if (kankoMstR == null) kankoMstR = new KanjoKamoku__c();
		else kankoMstR = kankoMstR.clone(false,false);
		
		String SingAccCsvTemplate = getSingAccCsvTemplate(acc, startNo, CsvTemplate, true);
		// 2016/12/13 摘要項目の後ろに請求先を表示追加対応 BEGIN
		SingAccCsvTemplate = addAccountInfToCsv(SingAccCsvTemplate, '');
		// 2016/12/13 摘要項目の後ろに請求先を表示追加対応 END
		String paymentAmount = String.valueOf(CommUtils.nullToIntZero(ttendPay.DepositAmount__c));
		// 支払情報は売掛金の場合
		if ( ttend != null && ttend.Field2__c == CommConst.MEDIA_TYPE_CD_03 ) {
			// 現在の会計科目は前受金「リスト残」の場合、下記処理を行わない
			if (kankoMstL.Kanjocode__c != kankoMstAr.Kanjocode__c) {
				// 請求先の企業コードが存在する場合、該当企業コードを補助科目コードに設定する
				if (!CommUtils.isBlank(acc.relaccount__r.Account.ID__c)) {
					kankoMstL.KanjoHojocode__c = CommUtils.nullToBlank(acc.relaccount__r.Account.ID__c);
					kankoMstL.KanjoHojoname__c = CommUtils.nullToBlank(acc.relaccount__r.Account.Name);
				}
				// 2016/10/11 支払情報の補助科目「売掛種別」BEGIN
				if (CommUtils.isBlank(kankoMstL.KanjoHojoname__c) && !Commutils.isBlank(acc.relaccount__r.Account.Name)) {
					// 補助科目はカード種別項目から出力する
					kankoMstL.KanjoHojoname__c = CommUtils.nullToBlank(acc.relaccount__r.Account.Name);
				}
				if (CommUtils.isBlank(kankoMstL.KanjoHojoname__c)) {
					// 補助科目はカード種別項目から出力する
					kankoMstL.KanjoHojoname__c = CommUtils.nullToBlank(acc.relaccount__r.Name);
				}
				// 2016/10/11 支払情報の補助科目「売掛種別」END
			}
			if (kankoMstR.Kanjocode__c != kankoMstAr.Kanjocode__c) {
				// 請求先の企業コードが存在する場合、該当企業コードを補助科目コードに設定する
				if (!CommUtils.isBlank(acc.relaccount__r.Account.ID__c)) {
					kankoMstR.KanjoHojocode__c = CommUtils.nullToBlank(acc.relaccount__r.Account.ID__c);
					kankoMstR.KanjoHojoname__c = CommUtils.nullToBlank(acc.relaccount__r.Account.Name);
				}
				// 2016/10/11 支払情報の補助科目「売掛種別」BEGIN
				if (CommUtils.isBlank(kankoMstR.KanjoHojoname__c) && !Commutils.isBlank(acc.relaccount__r.Account.Name)) {
					// 補助科目はカード種別項目から出力する
					kankoMstR.KanjoHojoname__c = CommUtils.nullToBlank(acc.relaccount__r.Account.Name);
				}
				if (CommUtils.isBlank(kankoMstR.KanjoHojoname__c)) {
					// 補助科目はカード種別項目から出力する
					kankoMstR.KanjoHojoname__c = CommUtils.nullToBlank(acc.relaccount__r.Name);
				}
				// 2016/10/11 支払情報の補助科目「売掛種別」END
			}
		}
		
		String csv = '';
		if (isFirst) {
		// CSV出力内容を整合する
			// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 BEGIN
			String debittaxkbn = CommUtils.nullToBlank(kankoMstR.CreditTaxKbn__c);
			String credittaxkbn = CommUtils.nullToBlank(kankoMstL.CreditTaxKbn__c);
			if (!CommUtils.isBlank(gccInfo.notaxkbn)) {
				debittaxkbn = gccInfo.notaxkbn;
				credittaxkbn = gccInfo.notaxkbn;
			}
			// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 END
			csv = SingAccCsvTemplate
					.Replace('$$_借方科目コード_$$'	,CommUtils.nullToBlank(kankoMstR.KanjocodeCode__c))
					//.Replace('$$_借方科目_$$'			,CommUtils.nullToBlank(kankoMstR.Name))
					// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
					//.Replace('$$_借方科目_$$'			,processFilter(CommUtils.nullToBlank(kankoMstR.Name)))
					.Replace('$$_借方科目_$$'			,processEscapeKanji(processFilter(CommUtils.nullToBlank(kankoMstR.Name))))
					// 2016/12/14 漢字にカンマを含めている改善対応 END
					.Replace('$$_借方補助コード_$$'	,CommUtils.nullToBlank(kankoMstR.KanjoHojocode__c))
					// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
					//.Replace('$$_借方補助_$$'			,CommUtils.nullToBlank(kankoMstR.KanjoHojoname__c))
					.Replace('$$_借方補助_$$'			,processEscapeKanji(CommUtils.nullToBlank(kankoMstR.KanjoHojoname__c)))
					// 2016/12/14 漢字にカンマを含めている改善対応 END
					// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 BEGIN
					//.Replace('$$_借方税区分_$$'		,CommUtils.nullToBlank(kankoMstR.CreditTaxKbn__c))
					.Replace('$$_借方税区分_$$'		,debittaxkbn)
					// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 END
					.Replace('$$_借方金額_$$'			,paymentAmount)
					// 消費税情報を設定する
					.Replace('$$_貸方科目コード_$$'	,CommUtils.nullToBlank(kankoMstL.KanjocodeCode__c))
					//.Replace('$$_貸方科目_$$'			,CommUtils.nullToBlank(kankoMstL.Name))
					// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
					//.Replace('$$_貸方科目_$$'			,processFilter(CommUtils.nullToBlank(kankoMstL.Name)))	
					.Replace('$$_貸方科目_$$'			,processEscapeKanji(processFilter(CommUtils.nullToBlank(kankoMstL.Name))))
					// 2016/12/14 漢字にカンマを含めている改善対応 END		
					.Replace('$$_貸方補助コード_$$'	,CommUtils.nullToBlank(kankoMstL.KanjoHojocode__c))
					// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
					//.Replace('$$_貸方補助_$$'			,CommUtils.nullToBlank(kankoMstL.KanjoHojoname__c))
					.Replace('$$_貸方補助_$$'			,processEscapeKanji(CommUtils.nullToBlank(kankoMstL.KanjoHojoname__c)))
					// 2016/12/14 漢字にカンマを含めている改善対応 END
					// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 BEGIN
					//.Replace('$$_貸方税区分_$$'		,CommUtils.nullToBlank(kankoMstL.CreditTaxKbn__c))
					.Replace('$$_貸方税区分_$$'		,credittaxkbn)
					// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 END
					.Replace('$$_貸方金額_$$'			,paymentAmount);
// 2016/09/23 仕訳Rollup機能追加対応 BEGIN
setupRollupInfo(acc.frs__r.Name,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ BEGIN
				//processFilter(CommUtils.nullToBlank(kankoMstR.Name)),
				kankoMstR,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ END
				gCcInfo.debdepartcode,
				debittaxkbn,
				paymentAmount,
				gCcInfo.debconsumptax,
				ROLLUP_TYPE.SALES_L);
									
setupRollupInfo(acc.frs__r.Name,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ BEGIN
				//processFilter(CommUtils.nullToBlank(kankoMstL.Name)),
				kankoMstL,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ END
				gCcInfo.credepartcode,
				credittaxkbn,
				paymentAmount,
				gCcInfo.creconsumptax,
				ROLLUP_TYPE.SALES_R);
// 2016/09/23 仕訳Rollup機能追加対応 END
		} else {
		// CSV出力内容を整合する
			// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 BEGIN
			String debittaxkbn = CommUtils.nullToBlank(kankoMstL.CreditTaxKbn__c);
			String credittaxkbn = CommUtils.nullToBlank(kankoMstR.CreditTaxKbn__c);
			if (!CommUtils.isBlank(gccInfo.notaxkbn)) {
				debittaxkbn = gccInfo.notaxkbn;
				credittaxkbn = gccInfo.notaxkbn;
			}
			// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 END
			csv = SingAccCsvTemplate
					.Replace('$$_借方科目コード_$$'	,CommUtils.nullToBlank(kankoMstL.KanjocodeCode__c))
					//.Replace('$$_借方科目_$$'			,CommUtils.nullToBlank(kankoMstL.Name))
					// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
					//.Replace('$$_借方科目_$$'			,processFilter(CommUtils.nullToBlank(kankoMstL.Name)))
					.Replace('$$_借方科目_$$'			,processEscapeKanji(processFilter(CommUtils.nullToBlank(kankoMstL.Name))))
					// 2016/12/14 漢字にカンマを含めている改善対応 END
					.Replace('$$_借方補助コード_$$'	,CommUtils.nullToBlank(kankoMstL.KanjoHojocode__c))
					// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
					//.Replace('$$_借方補助_$$'			,CommUtils.nullToBlank(kankoMstL.KanjoHojoname__c))
					.Replace('$$_借方補助_$$'			,processEscapeKanji(CommUtils.nullToBlank(kankoMstL.KanjoHojoname__c)))
					// 2016/12/14 漢字にカンマを含めている改善対応 END
					// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 BEGIN
					//.Replace('$$_借方税区分_$$'		,CommUtils.nullToBlank(kankoMstL.CreditTaxKbn__c))
					.Replace('$$_借方税区分_$$'		,debittaxkbn)
					// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 END
					.Replace('$$_借方金額_$$'			,paymentAmount)
					// 消費税情報を設定する
					.Replace('$$_貸方科目コード_$$'	,CommUtils.nullToBlank(kankoMstR.KanjocodeCode__c))
					//.Replace('$$_貸方科目_$$'			,CommUtils.nullToBlank(kankoMstR.Name))
					// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
					//.Replace('$$_貸方科目_$$'			,processFilter(CommUtils.nullToBlank(kankoMstR.Name)))
					.Replace('$$_貸方科目_$$'			,processEscapeKanji(processFilter(CommUtils.nullToBlank(kankoMstR.Name))))
					// 2016/12/14 漢字にカンマを含めている改善対応 END
					.Replace('$$_貸方補助コード_$$'	,CommUtils.nullToBlank(kankoMstR.KanjoHojocode__c))
					// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
					//.Replace('$$_貸方補助_$$'			,CommUtils.nullToBlank(kankoMstR.KanjoHojoname__c))
					.Replace('$$_貸方補助_$$'			,processEscapeKanji(CommUtils.nullToBlank(kankoMstR.KanjoHojoname__c)))
					// 2016/12/14 漢字にカンマを含めている改善対応 END
					// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 BEGIN
					//.Replace('$$_貸方税区分_$$'		,CommUtils.nullToBlank(kankoMstR.CreditTaxKbn__c))
					.Replace('$$_貸方税区分_$$'		,credittaxkbn)
					// 2015/12/07 売上の仕訳の借税区分と仕入の借税区分は指定の税区分情報を出力機能の追加 END
					.Replace('$$_貸方金額_$$'			,paymentAmount);
// 2016/09/23 仕訳Rollup機能追加対応 BEGIN
setupRollupInfo(acc.frs__r.Name,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ BEGIN
				//processFilter(CommUtils.nullToBlank(kankoMstL.Name)),
				kankoMstL,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ END
				gCcInfo.debdepartcode,
				debittaxkbn,
				paymentAmount,
				gCcInfo.debconsumptax,
				ROLLUP_TYPE.SALES_L);
									
setupRollupInfo(acc.frs__r.Name,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ BEGIN
				//processFilter(CommUtils.nullToBlank(kankoMstR.Name)),
				kankoMstR,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ END
				gCcInfo.credepartcode,
				credittaxkbn,
				paymentAmount,
				gCcInfo.creconsumptax,
				ROLLUP_TYPE.SALES_R);
									
		}
// 2016/09/23 仕訳Rollup機能追加対応 END
		return csv;
	}

	/**
	* 入出金CSV出力情報作成
	**/
	private String generalDepPayCsvInfo(ConvertXmlConfig ccInfo,Map<String, KanjoKamoku__c> kanjoKamokuMstMap ) {
		// XMLに入力、出金の設定情報がなかったの場合、該当機能は実施対象外
		// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応 WSQ BEGIN
		//if (ccInfo.cashInputInMap.isEmpty() && ccInfo.cashOutputInMap.isEmpty()) return '';
		if (ccInfo.cashInputInMap.isEmpty() && ccInfo.cashOutputInMap.isEmpty() && ccInfo.cashInputInRateKbnMap.isEmpty() && ccInfo.cashOutputInRateKbnMap.isEmpty()) return '';
		// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応 WSQ END
		// 入金情報
		// 2019/05/15 現金入出の「取引先」項目追加 BY zyz BEGIN
		// String depositQuery = 'select name,Kamoku__c,depositamount__c,deposititem__c,ShopCode__c,Reldeposit__r.Name,deposit__c,deposit__r.Name from deposit__c where Reldeposit__c = :gRsvAccoutId ';
		String depositQuery = 'select TaxRate__c,depositamountExc__c,name,Kamoku__c,depositamount__c,deposititem__c,ShopCode__c,Reldeposit__r.Name,deposit__c,deposit__r.Name,AccountRef__c,AccountRef__r.Name from deposit__c where Reldeposit__c = :gRsvAccoutId ';
		// 2019/05/15 現金入出の「取引先」項目追加 BY zyz END
		if(!CommUtils.isBlank(gShopCode)){
		 	depositQuery += ' And ShopInfoRef__r.ShopCode__c = :gShopCode ';
		}
		depositQuery += ' Order By Name ';
		// 2017/12/14 入金・出金別々出力する・出力しない切替できるように改善対応 BEGIN
		//List<deposit__c> deposits = DataBase.query(depositQuery);
		List<deposit__c> deposits = new List<deposit__c>();
		if (!ccInfo.cashInputInMap.isEmpty()) {
		    deposits = DataBase.query(depositQuery);
		}
		// 2017/12/14 入金・出金別々出力する・出力しない切替できるように改善対応 END
		//  出金情報
		// 2019/05/15 現金入出の「取引先」項目追加 BY zyz BEGIN
		// String paymentQuery = 'select name,Pkamoku__c,Pamount__c,Pitem__c,ShopCode__c,Relpayment__r.Name,PaymentRef__r.Name from Paymentslip__c where Relpayment__c = :gRsvAccoutId ';
		String paymentQuery = 'select TaxRate__c,PamountExc__c,name,Pkamoku__c,Pamount__c,Pitem__c,ShopCode__c,Relpayment__r.Name,PaymentRef__r.Name,AccountRef__c,AccountRef__r.Name from Paymentslip__c where Relpayment__c = :gRsvAccoutId ';
		// 2019/05/15 現金入出の「取引先」項目追加 BY zyz END
		if(!CommUtils.isBlank(gShopCode)){
		 	paymentQuery += ' And ShopInfoRef__r.ShopCode__c = :gShopCode ';
		}
		paymentQuery += ' Order By Name ';
		// 2017/12/14 入金・出金別々出力する・出力しない切替できるように改善対応 BEGIN
		//List<Paymentslip__c> paymentSlips = DataBase.query(paymentQuery);
        List<Paymentslip__c> paymentSlips = new List<Paymentslip__c>();
        if (!ccInfo.cashOutputInMap.isEmpty()) {
            paymentSlips = DataBase.query(paymentQuery);
        }
		// 2017/12/14 入金・出金別々出力する・出力しない切替できるように改善対応 END
		// 一行CSV出力のテンプレート
		String SingCsvTemplate = CONST_CSVDATA_TEMPLATE
							// 2015/10/14 Freeeの連携CSV出力機能の追加 BEGIN
							.Replace('$$_[表題行]_$$'			, '[明細行]')
							// 2015/10/14 Freeeの連携CSV出力機能の追加 END
							.Replace('$$_Ver_$$' 			, ccInfo.ver)
							.Replace('$$_借方部門コード_$$'	, ccInfo.debdepartcode)
							// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
							//.Replace('$$_借方消費税額_$$'		, ccInfo.debconsumptax)
							// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
							.Replace('$$_貸方部門コード_$$'	, ccInfo.credepartcode)
							// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
							//.Replace('$$_貸方消費税額_$$'		, ccInfo.creconsumptax)
							// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
							.Replace('$$_入力プログラム区分_$$'	, ccInfo.inputprogramkbn);
		// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
		if (!gccInfo.isOutTaxToSameLine) {
			SingCsvTemplate = SingCsvTemplate.Replace('$$_借方消費税額_$$'		, ccInfo.debconsumptax)
								.Replace('$$_貸方消費税額_$$'		, ccInfo.creconsumptax);
		}
		// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
		String csvBody = '';
		// 2019/09/20 多税率機能対応 WSQ BEGIN
		CaseConfig cashConfig = new CaseConfig(gShopCode);
		Integer pointLen = CommUtils.getPointLen();
		// 入金、出金明細の消費税を定義される場合、
		// 2019/09/20 多税率機能対応 WSQ END
		for (deposit__c deposit : deposits) {


			String kanjoIn = ccInfo.cashInputInMap.get(deposit.Kamoku__c);
			String kanjoOu = ccInfo.cashInputOuMap.get(deposit.Kamoku__c);
			// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応 WSQ BEGIN
			decimal taxRate = CommUtils.nullToZero(deposit.TaxRate__c);
			if (ccInfo.cashInputInRateKbnMap.containsKey(deposit.Kamoku__c)) {
				map<Decimal,String> cashInputInRateKbnMapItem = ccInfo.cashInputInRateKbnMap.get(deposit.Kamoku__c);
				if (cashInputInRateKbnMapItem.containsKey(taxrate))  kanjoIn = cashInputInRateKbnMapItem.get(taxrate);
			}
			if (ccInfo.cashInputOuRateKbnMap.containsKey(deposit.Kamoku__c)) {
				map<Decimal,String> cashInputOuRateKbnMapItem = ccInfo.cashInputOuRateKbnMap.get(deposit.Kamoku__c);
				if (cashInputOuRateKbnMapItem.containsKey(taxrate))  kanjoOu = cashInputOuRateKbnMapItem.get(taxrate);
			}
			// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応 WSQ END
			KanjoKamoku__c kanjoInOb = kanjoKamokuMstMap.get(kanjoIn);
			if (kanjoInOb == null) kanjoInOb = new KanjoKamoku__c();
			KanjoKamoku__c kanjoOuOb = kanjoKamokuMstMap.get(kanjoOu);
			if (kanjoOuOb == null) kanjoOuOb = new KanjoKamoku__c();
			// 補助科目情報設定
			// 2019/05/15 現金入出の「取引先」項目追加 BY zyz BEGIN
			// if (CommUtils.isBlank(kanjoOuOb.KanjoHojocode__c) && !CommUtils.isBlank(deposit.deposit__r.Name)) {
			if (CommUtils.isBlank(kanjoOuOb.KanjoHojocode__c) && (!CommUtils.isBlank(deposit.deposit__r.Name) || (!CommUtils.isBlank(deposit.AccountRef__r.Name) && ccInfo.isCashInputAccount))) {
			// 2019/05/15 現金入出の「取引先」項目追加 BY zyz END
				kanjoOuOb = kanjoOuOb.clone(false,false);
				// 2019/05/15 現金入出の「取引先」項目追加 BY zyz BEGIN
				String auxiliaryStr =  CommUtils.nullToBlank(deposit.deposit__r.Name);
				if(!CommUtils.isBlank(deposit.AccountRef__r.Name) && ccInfo.isCashInputAccount){
					auxiliaryStr = CommUtils.nullToBlank(deposit.AccountRef__r.Name);
				}
				// kanjoOuOb.KanjoHojocode__c = CommUtils.nullToBlank(deposit.deposit__r.Name);	// 補助科目コード
				// kanjoOuOb.KanjoHojoname__c = CommUtils.nullToBlank(deposit.deposit__r.Name);	// 補助科目名
				kanjoOuOb.KanjoHojocode__c = auxiliaryStr;	// 補助科目コード
				kanjoOuOb.KanjoHojoname__c = auxiliaryStr;	// 補助科目名
				// 2019/05/15 現金入出の「取引先」項目追加 BY zyz END
			}
			// 2018/11/26 FREEE/FREEERU出力機能、入出金科目、仕入種別科目のまま明細出力できるように改善対応 WSQ BEGIN
			if (ccInfo.isCashInputOuByKamoku && isCsvOutModeFreee) {
				kanjoInOb = kanjoInOb.clone(false,false);
				kanjoInOb.Name = CommUtils.nullToBlank(deposit.Kamoku__c);	// 入力の科目で科目として出力を行う
				kanjoInOb.KanjoHojoname__c = '';
			}
			// 2018/11/26 FREEE/FREEERU出力機能、入出金科目、仕入種別科目のまま明細出力できるように改善対応 WSQ END
			Decimal payAmount = Commutils.nullToZero(deposit.depositamount__c);
			// 2019/09/20 多税率機能対応 WSQ BEGIN
			decimal noTaxPayAmount = payAmount,incTaxPayAmount = payAmount;
			// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
			//decimal taxRate = CommUtils.nullToZero(deposit.TaxRate__c);
			// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
			// 消費税設定ある場合、消費税により、税込金額と税抜金額を計算する
			if (cashConfig.depismulititax && taxRate > 0) {
				// DBに格納している金額は税込場合
				noTaxPayAmount = CommUtils.nullToZero(deposit.depositamountExc__c);
				/*
				if (cashConfig.depOrgIsIncTax) {
					noTaxPayAmount = CommUtils.CalExcTaxPrice(payAmount, taxRate, pointLen);
				} else {
					incTaxPayAmount = CommUtils.CalIncTaxPrice(payAmount, taxRate, pointLen);
				}*/
			}
			// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
			// 仕入明細は税込金額から出力、しない切替フラグは税込金額に切り替え場合、
			if (ccInfo.isIncTaxFlg) noTaxPayAmount = incTaxPayAmount;
			// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
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
			// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
			payAmount = formatOuputNumber(payAmount);
			// 2016/11/21 出力金額の小数点対応できる改善 END
			// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
			//csvBody += SingCsvTemplate
			String csvLine = SingCsvTemplate
			// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
							.Replace('$$_伝票番号_$$'			, String.valueOf(ccInfo.startno))
							.Replace('$$_伝票日付_$$' 		, deposit.Reldeposit__r.Name)
							.Replace('$$_借方科目コード_$$' 	, CommUtils.nullToBlank(kanjoInOb.KanjocodeCode__c))
							//.Replace('$$_借方科目_$$' 		, CommUtils.nullToBlank(kanjoInOb.Name))
							// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
							//.Replace('$$_借方科目_$$' 		, processFilter(CommUtils.nullToBlank(kanjoInOb.Name)))
							.Replace('$$_借方科目_$$' 		, processEscapeKanji(processFilter(CommUtils.nullToBlank(kanjoInOb.Name))))
							// 2016/12/14 漢字にカンマを含めている改善対応 END
							.Replace('$$_借方補助コード_$$' 	, CommUtils.nullToBlank(kanjoInOb.KanjoHojocode__c))
							// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
							//.Replace('$$_借方補助_$$' 		, CommUtils.nullToBlank(kanjoInOb.KanjoHojoname__c))
							.Replace('$$_借方補助_$$' 		, processEscapeKanji(CommUtils.nullToBlank(kanjoInOb.KanjoHojoname__c)))
							// 2016/12/14 漢字にカンマを含めている改善対応 END
							.Replace('$$_借方税区分_$$' 		, CommUtils.nullToBlank(kanjoInOb.DebitTaxKbn__c))
							// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
							//.Replace('$$_借方金額_$$' 		, String.valueOf(payAmount.intValue()))
							// 2019/09/20 多税率機能対応 WSQ BEGIN
							//.Replace('$$_借方金額_$$' 		, String.valueOf(payAmount))
							.Replace('$$_借方金額_$$' 		, String.valueOf(incTaxPayAmount))
							// 2019/09/20 多税率機能対応 WSQ END
							// 2016/11/21 出力金額の小数点対応できる改善 END
							.Replace('$$_貸方科目コード_$$' 	, CommUtils.nullToBlank(kanjoOuOb.KanjocodeCode__c))
							//.Replace('$$_貸方科目_$$' 		, CommUtils.nullToBlank(kanjoOuOb.Name))
							// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
							//.Replace('$$_貸方科目_$$' 		, processFilter(CommUtils.nullToBlank(kanjoOuOb.Name)))
							.Replace('$$_貸方科目_$$' 		, processEscapeKanji(processFilter(CommUtils.nullToBlank(kanjoOuOb.Name))))
							// 2016/12/14 漢字にカンマを含めている改善対応 END
							.Replace('$$_貸方補助コード_$$' 	, CommUtils.nullToBlank(kanjoOuOb.KanjoHojocode__c))
							// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
							//.Replace('$$_貸方補助_$$' 		, CommUtils.nullToBlank(kanjoOuOb.KanjoHojoname__c))
							.Replace('$$_貸方補助_$$' 		, processEscapeKanji(CommUtils.nullToBlank(kanjoOuOb.KanjoHojoname__c)))
							// 2016/12/14 漢字にカンマを含めている改善対応 END
							.Replace('$$_貸方税区分_$$' 		, CommUtils.nullToBlank(kanjoOuOb.CreditTaxKbn__c))
							// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
							//.Replace('$$_貸方金額_$$' 		, String.valueOf(payAmount.intValue()))
							// 2019/09/20 多税率機能対応 WSQ BEGIN
							//.Replace('$$_貸方金額_$$' 		, String.valueOf(payAmount))
							.Replace('$$_貸方金額_$$' 		, String.valueOf(noTaxPayAmount))
							// 2019/09/20 多税率機能対応 WSQ END
							// 2016/11/21 出力金額の小数点対応できる改善 END
							// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
							//.Replace('$$_摘要_$$' 			, CommUtils.nullToBlank(deposit.deposititem__c));
							.Replace('$$_摘要_$$' 			, processEscapeKanji(CommUtils.nullToBlank(deposit.deposititem__c)));
							// 2016/12/14 漢字にカンマを含めている改善対応 END
							// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
							if (gccInfo.isOutTaxToSameLine) {
								csvLine = csvLine.Replace('$$_借方消費税額_$$'		, ccInfo.debconsumptax)
												.Replace('$$_貸方消費税額_$$'		, String.valueOf(taxAmount));
							}
							csvBody += csvLine;
							// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
// 2016/09/23 仕訳Rollup機能追加対応 BEGIN
setupRollupInfo(deposit.Reldeposit__r.Name,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ BEGIN
				//processFilter(CommUtils.nullToBlank(kanjoInOb.Name)),
				kanjoInOb,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ END
				ccInfo.debdepartcode,
				CommUtils.nullToBlank(kanjoInOb.DebitTaxKbn__c),
				// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
				//String.valueOf(payAmount.intValue()),
				// 2019/09/20 多税率機能対応 WSQ BEGIN
				//String.valueOf(payAmount),
				String.valueOf(incTaxPayAmount),
				// 2019/09/20 多税率機能対応 WSQ END
				// 2016/11/21 出力金額の小数点対応できる改善 END
				ccInfo.debconsumptax,
				ROLLUP_TYPE.SALES_L);

setupRollupInfo(deposit.Reldeposit__r.Name,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ BEGIN
				//processFilter(CommUtils.nullToBlank(kanjoOuOb.Name)),
				kanjoOuOb,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ END
				ccInfo.credepartcode,
				CommUtils.nullToBlank(kanjoOuOb.CreditTaxKbn__c),
				// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
				//String.valueOf(payAmount.intValue()),
				// 2019/09/20 多税率機能対応 WSQ BEGIN
				//String.valueOf(payAmount),
				String.valueOf(noTaxPayAmount),
				// 2019/09/20 多税率機能対応 WSQ END
				// 2016/11/21 出力金額の小数点対応できる改善 END
				// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
				// ##5182 費税が０にリセットする
				//ccInfo.creconsumptax,
				String.valueOf(taxAmount),
				// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
				ROLLUP_TYPE.SALES_R);
// 2016/09/23 仕訳Rollup機能追加対応 END		
			// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
			// ##5182 費税が０にリセットする
			if (gccInfo.isOutTaxToSameLine) taxAmount = 0;	
			// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
			// 2019/09/20 多税率機能対応 WSQ BEGIN
			if (taxAmount != 0) {
				String kanjoCode = ccInfo.taxKanjoMap.containskey(taxrate) ? ccInfo.taxKanjoMap.get(taxrate) : ccInfo.taxKanjoCode;
				KanjoKamoku__c taxKankoMst = kanjoKamokuMstMap.get(kanjoCode);
				if (taxKankoMst == null) taxKankoMst = new KanjoKamoku__c();
				csvBody += SingCsvTemplate
						.Replace('$$_伝票番号_$$'			, String.valueOf(ccInfo.startno))
						.Replace('$$_伝票日付_$$' 		, deposit.Reldeposit__r.Name)
						.Replace('$$_借方科目コード_$$' 	, '')
						.Replace('$$_借方科目_$$' 		, '')
						.Replace('$$_借方補助コード_$$' 	, '')
						.Replace('$$_借方補助_$$' 		, '')
						.Replace('$$_借方税区分_$$' 		, '')
						.Replace('$$_借方金額_$$' 		, '')
						.Replace('$$_貸方科目コード_$$' 	, CommUtils.nullToBlank(taxKankoMst.KanjocodeCode__c))
						.Replace('$$_貸方科目_$$' 		, processEscapeKanji(processFilter(CommUtils.nullToBlank(taxKankoMst.Name))))
						.Replace('$$_貸方補助コード_$$' 	, CommUtils.nullToBlank(taxKankoMst.KanjoHojocode__c))
						.Replace('$$_貸方補助_$$' 		, processEscapeKanji(CommUtils.nullToBlank(taxKankoMst.KanjoHojoname__c)))
						.Replace('$$_貸方税区分_$$' 		, CommUtils.nullToBlank(taxKankoMst.CreditTaxKbn__c))
						.Replace('$$_貸方金額_$$' 		, String.valueOf(taxAmount))
						.Replace('$$_摘要_$$' 			, processEscapeKanji(CommUtils.nullToBlank(deposit.deposititem__c)));
						
// 2016/09/23 仕訳Rollup機能追加対応 BEGIN
setupRollupInfo(deposit.Reldeposit__r.Name,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ BEGIN
				//processFilter(CommUtils.nullToBlank(kanjoOuOb.Name)),
				taxKankoMst,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ END
				ccInfo.credepartcode,
				CommUtils.nullToBlank(taxKankoMst.CreditTaxKbn__c),
				// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
				//String.valueOf(payAmount.intValue()),
				String.valueOf(taxAmount),
				// 2016/11/21 出力金額の小数点対応できる改善 END
				ccInfo.creconsumptax,
				ROLLUP_TYPE.SALES_R);
			}
			// 2019/09/20 多税率機能対応 WSQ END
			// 伝票番号設定する
			ccInfo.startno++;
		}
		

		for (Paymentslip__c payMent : paymentSlips) {

			String kanjoIn = ccInfo.cashOutputInMap.get(payMent.Pkamoku__c);
			String kanjoOu = ccInfo.cashOutputOuMap.get(payMent.Pkamoku__c);
			// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応 WSQ BEGIN
			decimal taxRate = CommUtils.nullToZero(payMent.TaxRate__c);
			if (ccInfo.cashOutputInRateKbnMap.containsKey(payMent.Pkamoku__c)) {
				//kanjoOu = pCcInfo.purchaseOutRateKbnMap.get(item.KamokuLst__c);
				map<Decimal,String> cashOutputInRateKbnMapItem = ccInfo.cashOutputInRateKbnMap.get(payMent.Pkamoku__c);
				if (cashOutputInRateKbnMapItem.containsKey(taxrate))  kanjoIn = cashOutputInRateKbnMapItem.get(taxrate);
			}
			if (ccInfo.cashOutputOuRateKbnMap.containsKey(payMent.Pkamoku__c)) {
				//kanjoOu = pCcInfo.purchaseOutRateKbnMap.get(item.KamokuLst__c);
				map<Decimal,String> cashOutputOuRateKbnMapItem = ccInfo.cashOutputOuRateKbnMap.get(payMent.Pkamoku__c);
				if (cashOutputOuRateKbnMapItem.containsKey(taxrate))  kanjoOu = cashOutputOuRateKbnMapItem.get(taxrate);
			}
			// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応 WSQ END
			KanjoKamoku__c kanjoInOb = kanjoKamokuMstMap.get(kanjoIn);
			if (kanjoInOb == null) kanjoInOb = new KanjoKamoku__c();
			KanjoKamoku__c kanjoOuOb = kanjoKamokuMstMap.get(kanjoOu);
			if (kanjoOuOb == null) kanjoOuOb = new KanjoKamoku__c();
			// 2018/11/26 出金先追加に従って、出金の補助科目内容の出力内容を改善対応 WSQ BEGIN
			// 補助科目情報設定
			// 2019/05/15 現金入出の「取引先」項目追加 BY zyz BEGIN
			// if (CommUtils.isBlank(kanjoOuOb.KanjoHojocode__c) && !CommUtils.isBlank(payMent.PaymentRef__r.Name)) {
			if (CommUtils.isBlank(kanjoOuOb.KanjoHojocode__c) && (!CommUtils.isBlank(payMent.PaymentRef__r.Name) || (!CommUtils.isBlank(payMent.AccountRef__r.Name) && ccInfo.isCashOutputAccount))) {
			// 2019/05/15 現金入出の「取引先」項目追加 BY zyz END
				kanjoOuOb = kanjoOuOb.clone(false,false);
				// 2019/05/15 現金入出の「取引先」項目追加 BY zyz BEGIN
				String auxiliaryStr =  CommUtils.nullToBlank(payMent.PaymentRef__r.Name);
				if(!CommUtils.isBlank(payMent.AccountRef__r.Name) && ccInfo.isCashOutputAccount){
					auxiliaryStr = CommUtils.nullToBlank(payMent.AccountRef__r.Name);
				}
				// kanjoOuOb.KanjoHojocode__c = CommUtils.nullToBlank(payMent.PaymentRef__r.Name);	// 補助科目コード
				// kanjoOuOb.KanjoHojoname__c = CommUtils.nullToBlank(payMent.PaymentRef__r.Name);	// 補助科目名
				kanjoOuOb.KanjoHojocode__c = auxiliaryStr;	// 補助科目コード
				kanjoOuOb.KanjoHojoname__c = auxiliaryStr;	// 補助科目名
				// 2019/05/15 現金入出の「取引先」項目追加 BY zyz END
			}
			// 2018/11/26 出金先追加に従って、出金の補助科目内容の出力内容を改善対応 WSQ END
			// 2018/11/26 FREEE/FREEERU出力機能、入出金科目、仕入種別科目のまま明細出力できるように改善対応 WSQ BEGIN
			if (ccInfo.isCashOutputOuByKamoku && isCsvOutModeFreee) {
				kanjoInOb = kanjoInOb.clone(false,false);
				kanjoInOb.Name = CommUtils.nullToBlank(payMent.Pkamoku__c);	// 入力の科目で科目として出力を行う
				kanjoInOb.KanjoHojoname__c = '';
			}
			// 2018/11/26 FREEE/FREEERU出力機能、入出金科目、仕入種別科目のまま明細出力できるように改善対応 WSQ END
			Decimal payAmount = Commutils.nullToZero(payMent.Pamount__c);
			// 2019/09/20 多税率機能対応 WSQ BEGIN
			decimal noTaxPayAmount= payAmount, incTaxPayAmount = payAmount;
			// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
			//decimal taxRate = CommUtils.nullToZero(payMent.TaxRate__c);
			// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
			// 消費税設定ある場合、消費税により、税込金額と税抜金額を計算する
			if (cashConfig.payismulititax && taxRate > 0) {
				// DBに格納している金額は税込場合
				noTaxPayAmount = CommUtils.nullToZero(payMent.PamountExc__c);
				/*
				if (cashConfig.payOrgIsIncTax) {
					noTaxPayAmount = CommUtils.CalExcTaxPrice(payAmount, taxRate, pointLen);
				} else {
					incTaxPayAmount = CommUtils.CalIncTaxPrice(payAmount, taxRate, pointLen);
				}*/
			}
			// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
			// 仕入明細は税込金額から出力、しない切替フラグは税込金額に切り替え場合、
			if (ccInfo.isIncTaxFlg) noTaxPayAmount = incTaxPayAmount;
			// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
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
			// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
			payAmount = formatOuputNumber(payAmount);
			// 2016/11/21 出力金額の小数点対応できる改善 END
			// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
			//csvBody += SingCsvTemplate
			String csvLine = SingCsvTemplate
			// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
							.Replace('$$_伝票日付_$$' 		, payMent.Relpayment__r.Name)
							.Replace('$$_伝票番号_$$'			, String.valueOf(ccInfo.startno))
							.Replace('$$_借方科目コード_$$' 	, CommUtils.nullToBlank(kanjoInOb.KanjocodeCode__c))
							//.Replace('$$_借方科目_$$' 		, CommUtils.nullToBlank(kanjoInOb.Name))
							// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
							//.Replace('$$_借方科目_$$' 		, processFilter(CommUtils.nullToBlank(kanjoInOb.Name)))
							.Replace('$$_借方科目_$$' 		, processEscapeKanji(processFilter(CommUtils.nullToBlank(kanjoInOb.Name))))
							// 2016/12/14 漢字にカンマを含めている改善対応 END
							.Replace('$$_借方補助コード_$$' 	, CommUtils.nullToBlank(kanjoInOb.KanjoHojocode__c))
							// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
							//.Replace('$$_借方補助_$$' 		, CommUtils.nullToBlank(kanjoInOb.KanjoHojoname__c))
							.Replace('$$_借方補助_$$' 		, processEscapeKanji(CommUtils.nullToBlank(kanjoInOb.KanjoHojoname__c)))
							// 2016/12/14 漢字にカンマを含めている改善対応 END
							.Replace('$$_借方税区分_$$' 		, CommUtils.nullToBlank(kanjoInOb.DebitTaxKbn__c))
							// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
							//.Replace('$$_借方金額_$$' 		, String.valueOf(payAmount.intValue()))
							// 2019/09/20 多税率機能対応 WSQ BEGIN
							//.Replace('$$_借方金額_$$' 		, String.valueOf(payAmount))
							.Replace('$$_借方金額_$$' 		, String.valueOf(noTaxPayAmount))
							// 2019/09/20 多税率機能対応 WSQ END
							// 2016/11/21 出力金額の小数点対応できる改善 END
							.Replace('$$_貸方科目コード_$$' 	, CommUtils.nullToBlank(kanjoOuOb.KanjocodeCode__c))
							//.Replace('$$_貸方科目_$$' 		, CommUtils.nullToBlank(kanjoOuOb.Name))
							// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
							//.Replace('$$_貸方科目_$$' 		, processFilter(CommUtils.nullToBlank(kanjoOuOb.Name)))
							.Replace('$$_貸方科目_$$' 		, processEscapeKanji(processFilter(CommUtils.nullToBlank(kanjoOuOb.Name))))
							// 2016/12/14 漢字にカンマを含めている改善対応 END
							.Replace('$$_貸方補助コード_$$'	, CommUtils.nullToBlank(kanjoOuOb.KanjoHojocode__c))
							// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
							//.Replace('$$_貸方補助_$$'			, CommUtils.nullToBlank(kanjoOuOb.KanjoHojoname__c))
							.Replace('$$_貸方補助_$$'			, processEscapeKanji(CommUtils.nullToBlank(kanjoOuOb.KanjoHojoname__c)))
							// 2016/12/14 漢字にカンマを含めている改善対応 END
							.Replace('$$_貸方税区分_$$' 		, CommUtils.nullToBlank(kanjoOuOb.CreditTaxKbn__c))
							// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
							//.Replace('$$_貸方金額_$$' 		, String.valueOf(payAmount.intValue()))
							// 2019/09/20 多税率機能対応 WSQ BEGIN
							//.Replace('$$_貸方金額_$$' 		, String.valueOf(payAmount))
							.Replace('$$_貸方金額_$$' 		, String.valueOf(incTaxPayAmount))
							// 2019/09/20 多税率機能対応 WSQ END
							// 2016/11/21 出力金額の小数点対応できる改善 END
							// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
							//.Replace('$$_摘要_$$' 			, CommUtils.nullToBlank(payMent.Pitem__c));
							.Replace('$$_摘要_$$' 			, processEscapeKanji(CommUtils.nullToBlank(payMent.Pitem__c)));
							// 2016/12/14 漢字にカンマを含めている改善対応 END
							// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
							if (gccInfo.isOutTaxToSameLine) {
								csvLine = csvLine.Replace('$$_借方消費税額_$$'		, String.valueOf(taxAmount))
												.Replace('$$_貸方消費税額_$$'		, ccInfo.creconsumptax);
							}
							csvBody += csvLine;
							// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
// 2016/09/23 仕訳Rollup機能追加対応 BEGIN
setupRollupInfo(payMent.Relpayment__r.Name,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ BEGIN
				//processFilter(CommUtils.nullToBlank(kanjoInOb.Name)),
				kanjoInOb,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ END
				ccInfo.debdepartcode,
				CommUtils.nullToBlank(kanjoInOb.DebitTaxKbn__c),
				// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
				//String.valueOf(payAmount.intValue()),
				// 2019/09/20 多税率機能対応 WSQ BEGIN
				//String.valueOf(payAmount),
				String.valueOf(noTaxPayAmount),
				// 2019/09/20 多税率機能対応 WSQ END
				// 2016/11/21 出力金額の小数点対応できる改善 END
				// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
				// ##5182 費税が０にリセットする
				//ccInfo.debconsumptax,
				String.valueOf(taxAmount),
				// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
				ROLLUP_TYPE.SALES_L);

setupRollupInfo(payMent.Relpayment__r.Name,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ BEGIN
				//processFilter(CommUtils.nullToBlank(kanjoOuOb.Name)),
				kanjoOuOb,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ END
				ccInfo.credepartcode,
				CommUtils.nullToBlank(kanjoOuOb.CreditTaxKbn__c),
				// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
				//String.valueOf(payAmount.intValue()),
				// 2019/09/20 多税率機能対応 WSQ BEGIN
				//String.valueOf(payAmount),
				String.valueOf(incTaxPayAmount),
				// 2019/09/20 多税率機能対応 WSQ END
				// 2016/11/21 出力金額の小数点対応できる改善 END
				ccInfo.creconsumptax,
				ROLLUP_TYPE.SALES_R);
// 2016/09/23 仕訳Rollup機能追加対応 END			
			// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
			// ##5182 費税が０にリセットする
			if (gccInfo.isOutTaxToSameLine) taxAmount = 0;	
			// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END			
			// 2019/09/20 多税率機能対応 WSQ BEGIN
			if (taxAmount != 0) {
				// 会計科目
				String kanjoCode = ccInfo.taxPayKanjoMap.containskey(taxrate) ? ccInfo.taxPayKanjoMap.get(taxrate) : ccInfo.taxPayKanjoCode;
				KanjoKamoku__c taxKankoMst = kanjoKamokuMstMap.get(kanjoCode);
				if (taxKankoMst == null) taxKankoMst = new KanjoKamoku__c();
				
				csvBody += SingCsvTemplate
						.Replace('$$_伝票日付_$$' 		, payMent.Relpayment__r.Name)
						.Replace('$$_伝票番号_$$'			, String.valueOf(ccInfo.startno))
						.Replace('$$_借方科目コード_$$' 	, CommUtils.nullToBlank(taxKankoMst.KanjocodeCode__c))
						.Replace('$$_借方科目_$$' 		, processEscapeKanji(processFilter(CommUtils.nullToBlank(taxKankoMst.Name))))
						.Replace('$$_借方補助コード_$$' 	, CommUtils.nullToBlank(taxKankoMst.KanjoHojocode__c))
						.Replace('$$_借方補助_$$' 		, processEscapeKanji(CommUtils.nullToBlank(taxKankoMst.KanjoHojoname__c)))
						.Replace('$$_借方税区分_$$' 		, CommUtils.nullToBlank(taxKankoMst.DebitTaxKbn__c))
						.Replace('$$_借方金額_$$' 		, String.valueOf(taxAmount))
						.Replace('$$_貸方科目コード_$$' 	, '')
						.Replace('$$_貸方科目_$$' 		, '')
						.Replace('$$_貸方補助コード_$$'	, '')
						.Replace('$$_貸方補助_$$'			, '')
						.Replace('$$_貸方税区分_$$' 		, '')
						.Replace('$$_貸方金額_$$' 		, '')
						.Replace('$$_摘要_$$' 			, processEscapeKanji(CommUtils.nullToBlank(payMent.Pitem__c)));
// 2016/09/23 仕訳Rollup機能追加対応 BEGIN
setupRollupInfo(payMent.Relpayment__r.Name,
				taxKankoMst,
				ccInfo.debdepartcode,
				CommUtils.nullToBlank(taxKankoMst.DebitTaxKbn__c),
				String.valueOf(taxAmount),
				ccInfo.debconsumptax,
				ROLLUP_TYPE.SALES_L);
			}
			// 伝票番号設定する
			ccInfo.startno++;
		}
		return csvBody;
	}
	

	/**
	* 仕入の仕訳出力情報作成
	**/
	private String generalPurchaseCsvInfo(ConvertXmlConfig pCcInfo,Map<String, KanjoKamoku__c> pKanjoKamokuMstMap ) {
		// XMLに入力、設定情報がなかったの場合、該当機能は実施対象外
		// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応 WSQ BEGIN
		//if (pCcInfo.purchaseInMap.isEmpty() && pCcInfo.purchaseOutMap.isEmpty()) return ''; 
		if (pCcInfo.purchaseInMap.isEmpty() && pCcInfo.purchaseOutMap.isEmpty() && pCcInfo.purchaseOutRateKbnMap.isEmpty() && pCcInfo.purchaseInRateKbnMap.isEmpty() && pCcInfo.purchaseOutOfTypeRateKbnMap.isEmpty()) return ''; 
		// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応 WSQ END
		// 手数料項目の「種別」設定内容を取得する
		AccountingSyncBatchHelp accSyncHelp = new AccountingSyncBatchHelp(gShopCode);
		// 当日に仕入情報を取得する
		// 仕入情報
		// 2018/10/10 摘要欄の出力内容に改善対応 zyz BEGIN
		//String purchaseQuery = 'select NoTaxFlg__c,Denpyoukei__c, KamokuLst__c, Memo__c, DenpyoukeiIncTax__c, Field1__c, Id, JinyaRevenue__c, Name, Purchasesource__c,Purchasesource__r.name,Purchasesource__r.ID__c ,Purchasesource__r.RoundType__c,PurchaseType__c, JinyaRevenue__r.Name from Purchase__c where Purchasesource__c != null And JinyaRevenue__c = :gRsvAccoutId ';
		Set<String> purApiSet = new Set<String>{'notaxflg__c','denpyoukei__c','kamokulst__c','memo__c','denpyoukeiinctax__c','field1__c','id','jinyarevenue__c','name','purchasesource__c','purchasesource__r.name','purchasesource__r.id__c','purchasesource__r.roundtype__c','purchasetype__c','jinyarevenue__r.name'};
		String purSQL = '';
		for(String api : xmlPurFieldsMap.keySet()){
			if(purApiSet.contains(api)) continue;
			purSQL+= api + ' ,';
		}
		String purchaseQuery = 'select TaxRateCal__c,NoTaxFlg__c,Denpyoukei__c, KamokuLst__c, Memo__c, DenpyoukeiIncTax__c, Field1__c, Id, JinyaRevenue__c, Name, Purchasesource__c,Purchasesource__r.name,Purchasesource__r.ID__c ,Purchasesource__r.RoundType__c,PurchaseType__c, ';
		if(!CommUtils.isBlank(purSQL)) purchaseQuery += purSQL;
		purchaseQuery += ' JinyaRevenue__r.Name from Purchase__c where Purchasesource__c != null And JinyaRevenue__c = :gRsvAccoutId ';
		// 2018/10/10 摘要欄の出力内容に改善対応 zyz END
		if(!CommUtils.isBlank(gShopCode)){
		 	purchaseQuery += ' And ShopInfoRef__r.ShopCode__c = :gShopCode ';
		}
		/* 2016/03/21 手数料の仕訳出力の場合、手数料支払のチェックは外す BEGIN
		// 定数料の種別設定を取得する
		set<String> chargeTypeSet = new set<string>();
		if (accSyncHelp.agtSalesRateConf != null && !CommUtils.isBlank(accSyncHelp.agtSalesRateConf.InTypeName)) chargeTypeSet.add(accSyncHelp.agtSalesRateConf.InTypeName);
		if (accSyncHelp.cardSalesRateConf!= null && !CommUtils.isBlank(accSyncHelp.cardSalesRateConf.InTypeName)) chargeTypeSet.add(accSyncHelp.cardSalesRateConf.InTypeName);
		*/
		/*
		if (!chargeTypeLst.isempty()) {
			purchaseQuery += ' And ( (PurchaseType__c in :chargeTypeLst And Purchasesource__r.PayChargeFlg__c = true ) or PurchaseType__c not in :chargeTypeLst )';
		}*/
		purchaseQuery += ' Order By Name ';
		// 手数料の場合、「買掛手数料バッチから作成のデータに対して、」
		List<Purchase__c> purchaseItems = DataBase.query(purchaseQuery);
		/* 2016/03/21 手数料の仕訳出力の場合、手数料支払のチェックは外す BEGIN
		// 手数数料対象に対して、関連の手数料出力する・なしで判断を行う
		set<id> chargeAccIds = new set<id>();
		for (Purchase__c pur : purchaseItems) {
			if (chargeTypeSet.contains(pur.PurchaseType__c)) {
				// 該当仕入先の手数料情報を取得対象になる
				chargeAccIds.add(pur.Purchasesource__c);
			}
		}
		map<id,ChargeInfo__c> chargeInfMap = AccountingSyncBatchHelp.getChargeInfoByAccount(new list<id>(chargeAccIds));
		*/
		// 消費税情報はCSVへ反映する
		// 2019/09/20 多税率機能対応 WSQ BEGIN
		// 2016/03/10 借方の仮払消費税の会計科目出力機能の追加 BEGIN
		//KanjoKamoku__c taxKankoMst = pKanjoKamokuMstMap.get(pCcInfo.taxPayKanjoCode);
		// 2016/03/10 借方の仮払消費税の会計科目出力機能の追加 END
		//if (taxKankoMst == null) taxKankoMst = new KanjoKamoku__c();
		// 2019/09/20 多税率機能対応 WSQ END
		// 一行CSV出力のテンプレート
		String SingCsvTemplate = CONST_CSVDATA_TEMPLATE
							.Replace('$$_[表題行]_$$'			, '[明細行]')		// Freeeの連携CSV出力機能専用
							.Replace('$$_Ver_$$' 			, pCcInfo.ver)
							.Replace('$$_借方部門コード_$$'	, pCcInfo.debdepartcode)
							// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
							//.Replace('$$_借方消費税額_$$'		, pCcInfo.debconsumptax)
							// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
							.Replace('$$_貸方部門コード_$$'	, pCcInfo.credepartcode)
							.Replace('$$_貸方消費税額_$$'		, pCcInfo.creconsumptax)
							.Replace('$$_入力プログラム区分_$$'	, pCcInfo.inputprogramkbn);
		// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
		if (!gccInfo.isOutTaxToSameLine) {
			SingCsvTemplate = SingCsvTemplate.Replace('$$_借方消費税額_$$'		, gCcInfo.debconsumptax);
		}
		// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
		String csvBody = '';
		for (Purchase__c item : purchaseItems) {
			/* 2016/03/21 手数料の仕訳出力の場合、手数料支払のチェックは外す BEGIN
			// 手数料の場合、出力対象チェックを行う
			if (chargeTypeSet.contains(item.PurchaseType__c)) {
				if (!chargeInfMap.containsKey(item.Purchasesource__c) ||
					chargeInfMap.get(item.Purchasesource__c).PayChargeFlg__c != true)
				// 手数料　かつ　手数料支払　なし場合、出力対象外になる
				continue;
			}
			*/
			// 2019/09/20 多税率機能対応 WSQ BEGIN
			decimal taxrate = formattax((item.NoTaxFlg__c) ? 0 : CommUtils.nullToZero(item.TaxRateCal__c));
			// XMLに複数率を定義されない場合、消費税、サビース料は合計格納
			// #5171 BugFix WSQ BEGIN
		 	if (!pCcInfo.taxPayKanjoMap.isEmpty() && pCcInfo.taxPayKanjoMap.containskey(taxrate)) {
		 		pCcInfo.taxPayKanjoCode = pCcInfo.taxPayKanjoMap.get(taxrate);
		 	}
		 	//if (pCcInfo.taxPayKanjoMap.isEmpty()) taxrate = CONST_SUM_TAX_RATE;
			//if (pCcInfo.taxPayKanjoMap.containskey(taxrate)) pCcInfo.taxPayKanjoCode = pCcInfo.taxPayKanjoMap.get(taxrate);
			// #5171 BugFix WSQ END
			KanjoKamoku__c taxKankoMst = pKanjoKamokuMstMap.get(pCcInfo.taxPayKanjoCode);
			if (taxKankoMst == null) taxKankoMst = new KanjoKamoku__c();
			// 2019/09/20 多税率機能対応 WSQ END
			String kanjoIn = pCcInfo.purchaseInMap.get(item.PurchaseType__c);
			String kanjoOu = pCcInfo.purchaseOutMap.get(item.KamokuLst__c);	// TODO:該当項目はNULLの場合、
			// 2015/12/10 仕入オブジェクトの種別の貸方の勘定科目指定できる様に機能対応 BEGIN
			// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応 WSQ BEGIN
			// P_KAMOKU->KANJOCODEが消費税別定義される場合
			if (pCcInfo.purchaseOutRateKbnMap.containsKey(item.KamokuLst__c)) {
				//kanjoOu = pCcInfo.purchaseOutRateKbnMap.get(item.KamokuLst__c);
				map<Decimal,String> purchaseOutRateKbnMapItem = pCcInfo.purchaseOutRateKbnMap.get(item.KamokuLst__c);
				if (purchaseOutRateKbnMapItem.containsKey(taxrate))  kanjoOu = purchaseOutRateKbnMapItem.get(taxrate);
			}
			// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応 WSQ END
			// P_TYPEタグに貸方の勘定科目を定義されている場合
			if (pCcInfo.purchaseOutOfTypeMap.containsKey(item.PurchaseType__c)) {
				kanjoOu = pCcInfo.purchaseOutOfTypeMap.get(item.PurchaseType__c);
			}
			// 2015/12/10 仕入オブジェクトの種別の貸方の勘定科目指定できる様に機能対応 END
			// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応 WSQ BEGIN
			// P_TYPEタグに消費税率を定義されている
			// P_TYPE->KANJOCODE消費率定義場合
			if (pCcInfo.purchaseInRateKbnMap.containsKey(item.PurchaseType__c)) {
				map<Decimal,String> purchaseInRateKbnMapItem = pCcInfo.purchaseInRateKbnMap.get(item.PurchaseType__c);
				if (purchaseInRateKbnMapItem.containsKey(taxrate))  kanjoIn = purchaseInRateKbnMapItem.get(taxrate);
			}
			// P_TYPE->KANJOCODE_R消費率定義場合
			if (pCcInfo.purchaseOutOfTypeRateKbnMap.containsKey(item.PurchaseType__c)) {
				map<Decimal,String> purchaseOutOfTypeRateKbnMapItem = pCcInfo.purchaseOutOfTypeRateKbnMap.get(item.PurchaseType__c);
				if (purchaseOutOfTypeRateKbnMapItem.containsKey(taxrate))  kanjoOu = purchaseOutOfTypeRateKbnMapItem.get(taxrate);
			}
			// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応 WSQ END
			KanjoKamoku__c kanjoInOb = pKanjoKamokuMstMap.get(kanjoIn);
			if (kanjoInOb == null) kanjoInOb = new KanjoKamoku__c();
			KanjoKamoku__c kanjoOuOb = pKanjoKamokuMstMap.get(kanjoOu);
			if (kanjoOuOb == null) kanjoOuOb = new KanjoKamoku__c();
			// 2018/11/26 FREEE/FREEERU出力機能、入出金科目、仕入種別科目のまま明細出力できるように改善対応 WSQ BEGIN
			if (pCcInfo.isPurchaseOuByKamoku && isCsvOutModeFreee) {
				kanjoInOb = kanjoInOb.clone(false,false);
				kanjoInOb.Name = CommUtils.nullToBlank(item.PurchaseType__c);	// 入力の科目で科目として出力を行う
				kanjoInOb.KanjoHojocode__c = '';
				kanjoInOb.KanjoHojoname__c = '';
				kanjoOuOb = kanjoOuOb.clone(false,false);
				kanjoOuOb.Name = CommUtils.nullToBlank(item.KamokuLst__c);	// 入力の科目で科目として出力を行う
				kanjoOuOb.KanjoHojocode__c = '';
				kanjoOuOb.KanjoHojoname__c = '';
			}
			// 2018/11/26 FREEE/FREEERU出力機能、入出金科目、仕入種別科目のまま明細出力できるように改善対応 WSQ END
			kanjoOuOb = kanjoOuOb.clone(false,true);
			if (CommUtils.isBlank(kanjoOuOb.KanjoHojocode__c)) {
				// 仕入先の名で補助科目コード
				kanjoOuOb.KanjoHojocode__c = item.Purchasesource__r.ID__c;
				// 仕入先の名で補助科目名
				kanjoOuOb.KanjoHojoname__c = item.Purchasesource__r.name;
			}
			Decimal inPayAmount = Commutils.nullToZero(item.Denpyoukei__c);	// TODO　金額出力内容確認用
			Decimal outPayAmount = Commutils.nullToZero(item.DenpyoukeiIncTax__c);	// TODO　金額出力内容確認用
			// 2018/11/05 仕訳明細は税込・税抜出力選択できるように改善対応 WSQ BEGIN
			if (pCcInfo.isIncTaxFlg) inPayAmount = outPayAmount;
			// 2018/11/05 仕訳明細は税込・税抜出力選択できるように改善対応 WSQ END
//System.debug(logginglevel.INFO, 'inPayAmount;bef;' + inPayAmount);	
//System.debug(logginglevel.INFO, 'outPayAmount;bef;' + outPayAmount);
			// 小数金額四捨五入設定する
			System.RoundingMode roundType = CommUtils.pointRoundMode(CommBaseCtrl.getRoundType());	// システム標準端数処理区分
			if (!CommUtils.isBLank(item.Purchasesource__r.RoundType__c)) {
				roundType = CommUtils.pointRoundMode(item.Purchasesource__r.RoundType__c);
			}
			// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
			//inPayAmount = CommUtils.RoundProcess(inPayAmount, CommUtils.getTaxPointLen(), roundType);
			//outPayAmount = CommUtils.RoundProcess(outPayAmount, CommUtils.getTaxPointLen(), roundType);
			inPayAmount = CommUtils.RoundProcess(inPayAmount, CommUtils.getPointLen(), roundType);
			outPayAmount = CommUtils.RoundProcess(outPayAmount, CommUtils.getPointLen(), roundType);
			inPayAmount = formatOuputNumber(inPayAmount);
			outPayAmount = formatOuputNumber(outPayAmount);
			// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
//System.debug(logginglevel.INFO, 'inPayAmount;;' + inPayAmount);	
//System.debug(logginglevel.INFO, 'outPayAmount;;' + outPayAmount);	
//System.debug(logginglevel.INFO, 'inPayAmount;;' + String.valueOf(inPayAmount.intValue()));	
//System.debug(logginglevel.INFO, 'outPayAmount;;' + String.valueOf(outPayAmount.intValue()));
			// 2015/12/07 仕入の税対象外の場合、借税区分は指定の税区分情報を出力機能の追加 BEGIN
			String debittaxkbn = CommUtils.nullToBlank(kanjoInOb.DebitTaxKbn__c);
			String credittaxkbn = CommUtils.nullToBlank(kanjoOuOb.CreditTaxKbn__c);
			if (!CommUtils.isBlank(pCcInfo.notaxkbn)) credittaxkbn = pCcInfo.notaxkbn;
			// 税対象外の場合、非課税科目を出力する
			if (item.NoTaxFlg__c == true && !CommUtils.isBlank(pCcInfo.notaxkbn)) {
				debittaxkbn = pCcInfo.notaxkbn;
			}
			// 2016/07/26 仕入オブジェクトの種別の貸方の勘定科目の税区分指定できるように対応 BEGIN
			if (pCcInfo.purchaseInTaxKbnMap.containsKey(item.PurchaseType__c)) {
				debittaxkbn = pCcInfo.purchaseInTaxKbnMap.get(item.PurchaseType__c);
			}
			if (pCcInfo.purchaseOutTaxKbnMap.containsKey(item.PurchaseType__c)) {
				credittaxkbn = pCcInfo.purchaseOutTaxKbnMap.get(item.PurchaseType__c);
			}
			// 2016/07/26 仕入オブジェクトの種別の貸方の勘定科目の税区分指定できるように対応 END
//System.debug(logginglevel.INFO, 'pCcInfo.notaxkbn::' + pCcInfo.notaxkbn);	
			// 2015/12/07 仕入の税対象外の場合、借税区分は指定の税区分情報を出力機能の追加 END
			// 2018/10/10 摘要欄の出力内容に改善対応 zyz BEGIN
			String memoStr = CommUtils.nullToBlank(getXmlPurMemoStr(item));
			// XML定义为空，默认设定仕入摘要
			if(xmlPurFieldsMap.isEmpty()) memoStr = item.Memo__c;
			// 2018/10/10 摘要欄の出力内容に改善対応 zyz END
			csvBody += SingCsvTemplate
							.Replace('$$_伝票番号_$$'			, String.valueOf(pCcInfo.startno))
							.Replace('$$_伝票日付_$$' 		, item.JinyaRevenue__r.Name)
							.Replace('$$_借方科目コード_$$' 	, CommUtils.nullToBlank(kanjoInOb.KanjocodeCode__c))
							//.Replace('$$_借方科目_$$' 		, CommUtils.nullToBlank(kanjoInOb.Name))
							// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
							//.Replace('$$_借方科目_$$' 		, processFilter(CommUtils.nullToBlank(kanjoInOb.Name)))
							.Replace('$$_借方科目_$$' 		, processEscapeKanji(processFilter(CommUtils.nullToBlank(kanjoInOb.Name))))
							// 2016/12/14 漢字にカンマを含めている改善対応 END
							.Replace('$$_借方補助コード_$$' 	, CommUtils.nullToBlank(kanjoInOb.KanjoHojocode__c))
							// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
							//.Replace('$$_借方補助_$$' 		, CommUtils.nullToBlank(kanjoInOb.KanjoHojoname__c))
							.Replace('$$_借方補助_$$' 		, processEscapeKanji(CommUtils.nullToBlank(kanjoInOb.KanjoHojoname__c)))
							// 2016/12/14 漢字にカンマを含めている改善対応 END
							// 2015/12/07 仕入の税対象外の場合、借税区分は指定の税区分情報を出力機能の追加 BEGIN
							//.Replace('$$_借方税区分_$$' 		, CommUtils.nullToBlank(kanjoInOb.DebitTaxKbn__c))
							.Replace('$$_借方税区分_$$' 		, debittaxkbn)
							// 2015/12/07 仕入の税対象外の場合、借税区分は指定の税区分情報を出力機能の追加 END
							// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
							//.Replace('$$_借方金額_$$' 		, String.valueOf(inPayAmount.intValue()))
							.Replace('$$_借方金額_$$' 		, String.valueOf(inPayAmount))
							// 2016/11/21 出力金額の小数点対応できる改善 END
							.Replace('$$_貸方科目コード_$$' 	, CommUtils.nullToBlank(kanjoOuOb.KanjocodeCode__c))
							//.Replace('$$_貸方科目_$$' 		, CommUtils.nullToBlank(kanjoOuOb.Name))
							// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
							//.Replace('$$_貸方科目_$$' 		, processFilter(CommUtils.nullToBlank(kanjoOuOb.Name)))
							.Replace('$$_貸方科目_$$' 		, processEscapeKanji(processFilter(CommUtils.nullToBlank(kanjoOuOb.Name))))
							// 2016/12/14 漢字にカンマを含めている改善対応 END
							.Replace('$$_貸方補助コード_$$' 	, CommUtils.nullToBlank(kanjoOuOb.KanjoHojocode__c))
							// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
							//.Replace('$$_貸方補助_$$' 		, CommUtils.nullToBlank(kanjoOuOb.KanjoHojoname__c))
							.Replace('$$_貸方補助_$$' 		, processEscapeKanji(CommUtils.nullToBlank(kanjoOuOb.KanjoHojoname__c)))
							// 2016/12/14 漢字にカンマを含めている改善対応 END
							// 2015/12/07 仕入の税対象外の場合、借税区分は指定の税区分情報を出力機能の追加 BEGIN
							//.Replace('$$_貸方税区分_$$' 		, CommUtils.nullToBlank(kanjoOuOb.CreditTaxKbn__c))
							.Replace('$$_貸方税区分_$$' 		, credittaxkbn)
							// 2015/12/07 仕入の税対象外の場合、借税区分は指定の税区分情報を出力機能の追加 END
							// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
							//.Replace('$$_貸方金額_$$' 		, String.valueOf(outPayAmount.intValue()))
							.Replace('$$_貸方金額_$$' 		, String.valueOf(outPayAmount))
							// 2016/11/21 出力金額の小数点対応できる改善 END
							// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
							//.Replace('$$_摘要_$$' 			, clearMemoBreakLine(CommUtils.nullToBlank(item.Memo__c)));
							// 2018/10/10 摘要欄の出力内容に改善対応 zyz BEGIN
							//.Replace('$$_摘要_$$' 			, processEscapeKanji(clearMemoBreakLine(CommUtils.nullToBlank(item.Memo__c))));
							.Replace('$$_摘要_$$' 			, processEscapeKanji(clearMemoBreakLine(CommUtils.nullToBlank(memoStr))));
							// 2018/10/10 摘要欄の出力内容に改善対応 zyz END
							// 2016/12/14 漢字にカンマを含めている改善対応 END
			// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
			String strTaxPayAmount = pCcInfo.debconsumptax;
			if (gccInfo.isOutTaxToSameLine) {
				// 新行目に消費税情報を作成する
				Decimal taxPayAmount = outPayAmount - inPayAmount;
				// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
				taxPayAmount = formatOuputNumber(taxPayAmount);
				strTaxPayAmount = String.valueOf(taxPayAmount);
				csvBody = csvBody.Replace('$$_借方消費税額_$$'		, strTaxPayAmount);
			}
			// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
// 2016/09/23 仕訳Rollup機能追加対応 BEGIN
setupRollupInfo(item.JinyaRevenue__r.Name,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ BEGIN
				//processFilter(CommUtils.nullToBlank(kanjoInOb.Name)),
				kanjoInOb,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ END
				pCcInfo.debdepartcode,
				debittaxkbn,
				// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
				//String.valueOf(inPayAmount.intValue()),
				String.valueOf(inPayAmount),
				// 2016/11/21 出力金額の小数点対応できる改善 END
				// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
				//pCcInfo.debconsumptax,
				strTaxPayAmount,
				// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
				ROLLUP_TYPE.PUR_L);

setupRollupInfo(item.JinyaRevenue__r.Name,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ BEGIN
				//processFilter(CommUtils.nullToBlank(kanjoOuOb.Name)),
				kanjoOuOb,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ END
				pCcInfo.credepartcode,
				credittaxkbn,
				// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
				//String.valueOf(outPayAmount.intValue()),
				String.valueOf(outPayAmount),
				// 2016/11/21 出力金額の小数点対応できる改善 END
				pCcInfo.creconsumptax,
				ROLLUP_TYPE.PUR_R);
// 2016/09/23 仕訳Rollup機能追加対応 END					
			// 新行目に消費税情報を作成する
			Decimal taxPayAmount = outPayAmount - inPayAmount;
			// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
			// 借方税額設定される場合、消費税は別行目を出力しない
			if (gccInfo.isOutTaxToSameLine) taxPayAmount = 0;
			// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
			// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
			taxPayAmount = formatOuputNumber(taxPayAmount);
			// 2016/11/21 出力金額の小数点対応できる改善 END
			if (taxPayAmount != 0) {
				csvBody += SingCsvTemplate
					.Replace('$$_伝票番号_$$'			, String.valueOf(pCcInfo.startno))
					.Replace('$$_伝票日付_$$' 		, item.JinyaRevenue__r.Name)
					// 消費税情報を設定する
					.Replace('$$_借方科目コード_$$'	, CommUtils.nullToBlank(taxKankoMst.KanjocodeCode__c))
					//.Replace('$$_借方科目_$$'			, CommUtils.nullToBlank(taxKankoMst.Name))
					// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
					//.Replace('$$_借方科目_$$'			, processFilter(CommUtils.nullToBlank(taxKankoMst.Name)))
					.Replace('$$_借方科目_$$'			, processEscapeKanji(processFilter(CommUtils.nullToBlank(taxKankoMst.Name))))	
					// 2016/12/14 漢字にカンマを含めている改善対応 END	
					.Replace('$$_借方補助コード_$$'	, CommUtils.nullToBlank(taxKankoMst.KanjoHojocode__c))
					// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
					//.Replace('$$_借方補助_$$'			, CommUtils.nullToBlank(taxKankoMst.KanjoHojoname__c))
					.Replace('$$_借方補助_$$'			, processEscapeKanji(CommUtils.nullToBlank(taxKankoMst.KanjoHojoname__c)))
					// 2016/12/14 漢字にカンマを含めている改善対応 END
					.Replace('$$_借方税区分_$$'		, CommUtils.nullToBlank(taxKankoMst.CreditTaxKbn__c))
					// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
					//.Replace('$$_借方金額_$$'			, String.valueOf(taxPayAmount.intValue()))
					.Replace('$$_借方金額_$$'			, String.valueOf(taxPayAmount))
					// 2016/11/21 出力金額の小数点対応できる改善 END
					.Replace('$$_貸方科目コード_$$'	, '')
					.Replace('$$_貸方科目_$$'			, '')
					.Replace('$$_貸方補助コード_$$'	, '')
					.Replace('$$_貸方補助_$$'			, '')
					.Replace('$$_貸方税区分_$$'		, '')
					.Replace('$$_貸方金額_$$'			, '0')
					// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
					//.Replace('$$_摘要_$$' 			, clearMemoBreakLine(CommUtils.nullToBlank(item.Memo__c)));
					// 2018/10/10 摘要欄の出力内容に改善対応 zyz BEGIN
					//.Replace('$$_摘要_$$' 			, processEscapeKanji(clearMemoBreakLine(CommUtils.nullToBlank(item.Memo__c))));
					.Replace('$$_摘要_$$' 			, processEscapeKanji(clearMemoBreakLine(CommUtils.nullToBlank(memoStr))));
					// 2018/10/10 摘要欄の出力内容に改善対応 zyz END
					// 2016/12/14 漢字にカンマを含めている改善対応 END
// 2016/09/23 仕訳Rollup機能追加対応 BEGIN
setupRollupInfo(item.JinyaRevenue__r.Name,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ BEGIN
				//processFilter(CommUtils.nullToBlank(taxKankoMst.Name)),
				taxKankoMst,
				// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ END
				pCcInfo.debdepartcode,
				CommUtils.nullToBlank(taxKankoMst.CreditTaxKbn__c),
				// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
				//String.valueOf(taxPayAmount.intValue()),
				String.valueOf(taxPayAmount),
				// 2016/11/21 出力金額の小数点対応できる改善 END
				pCcInfo.debconsumptax,
				ROLLUP_TYPE.PUR_L);	
// 2016/09/23 仕訳Rollup機能追加対応 END				
			}
			// 伝票番号設定する
			pCcInfo.startno++;
		}
		return csvBody;
	}
	private String clearMemoBreakLine(String s) {
		s = s.replace('\r\n', ' ');
		s = s.replace('\n', ' ');
		s = s.replace('\r', ' ');
		return s;
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
			if (!gccInfo.isOutputPriceZero && CommUtils.nullToZero(tran.GoukeinoneTax__c) == 0) continue;
			
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
			/*
system.debug(loggingLevel.info, 'pay begin='+pay);
			// 残金存在場合
			for (PaymentInfo__c nextPay : rsLst) {
				// 相殺後残金存在場合、相殺処理を行う
				if (nextPay.RemainingMoney3__c <= 0) continue;
				// 相殺可能金額を取得する
				decimal sousatuAmount =  (keijyoAmount > nextPay.RemainingMoney3__c ? nextPay.RemainingMoney3__c : keijyoAmount);
				// 相殺金額を設定する　
				pay.OffsetMoney__c = sousatuAmount;
				// 相殺金額を減算して、残金をリセットする
				nextPay.RemainingMoney3__c = (nextPay.RemainingMoney3__c - sousatuAmount);
				nextPay.RemainingMoney2__c = nextPay.RemainingMoney3__c;
				nextPay.OffsetMoney__c = sousatuAmount;
				// 相殺金額を合計する
				sumsousatuAmout += sousatuAmount;
				// 売掛金存在
				keijyoAmount = pay.DepositAmount__c - sousatuAmount;
				if (keijyoAmount <= 0) break;
			}
system.debug(loggingLevel.info, 'pay end='+pay);
			*/
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
	// 2016/09/23 仕訳Rollup機能追加対応[入出金、売上]単位にRollup、仕入は単独Rollup BEGIN
	map<string,RollupItem> salesLeftRollupMap = new map<string, RollupItem>();
	map<string,RollupItem> salesRightRollupMap = new map<string, RollupItem>();
	map<string,RollupItem> purLeftRollupMap = new map<string, RollupItem>();
	map<string,RollupItem> purRightRollupMap = new map<string, RollupItem>();
	enum ROLLUP_TYPE{SALES_L,SALES_R,PUR_L,PUR_R}
	// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ BEGIN
	private static final String CONST_HOJYOKAMOKU_KEY = '__';
	//private void setupRollupInfo(String psd, String pKamoku, String pDepart, String pTaxKbn, String pAmount, String pTaxAmount, ROLLUP_TYPE rType) {
	private void setupRollupInfo(String psd, KanjoKamoku__c poKamoku, String pDepart, String pTaxKbn, String pAmount, String pTaxAmount, ROLLUP_TYPE rType) {
		if (poKamoku == null) poKamoku = new KanjoKamoku__c();
		String pKamoku = processFilter(CommUtils.nullToBlank(poKamoku.Name));//科目名
		if (gccInfo.rollupSubKamokuFlg && !CommUtils.isBlank(pKamoku)) {
			String subKamoku = CommUtils.nullToBlank(poKamoku.KanjoHojoname__c);//補助科目名
			pKamoku += CONST_HOJYOKAMOKU_KEY +  subKamoku;
		}
	// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ END
		// 空白内容は除外処理
		if (CommUtils.isBlank(pKamoku) && CommUtils.nullToZero(pAmount) == 0) return;
		if (rType == ROLLUP_TYPE.SALES_L) {
			if (!salesLeftRollupMap.containskey(pKamoku)) {
				salesLeftRollupMap.put(pKamoku, new RollupItem(psd,pKamoku,pDepart,pTaxKbn,pAmount,pTaxAmount));
			} else {
				RollupItem wkItem = salesLeftRollupMap.get(pKamoku);
				wkItem.amount = CommUtils.nullToZero(pAmount) + wkItem.amount;
				// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
				if (gccInfo.isOutTaxToSameLine ) {
					wkItem.taxAmount = String.valueOf(CommUtils.nullToZero(pTaxAmount) + CommUtils.nullToZero(wkItem.taxAmount));
				}
				// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
			}
		} else if (rType == ROLLUP_TYPE.SALES_R) {
			if (!salesRightRollupMap.containskey(pKamoku)) {
				salesRightRollupMap.put(pKamoku, new RollupItem(psd,pKamoku,pDepart,pTaxKbn,pAmount,pTaxAmount));
			} else {
				RollupItem wkItem = salesRightRollupMap.get(pKamoku);
				wkItem.amount = CommUtils.nullToZero(pAmount) + wkItem.amount;
				// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
				if (gccInfo.isOutTaxToSameLine ) {
					wkItem.taxAmount = String.valueOf(CommUtils.nullToZero(pTaxAmount) + CommUtils.nullToZero(wkItem.taxAmount));
				}
				// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
			}
		} else if (rType == ROLLUP_TYPE.PUR_L) {
			if (!purLeftRollupMap.containskey(pKamoku)) {
				purLeftRollupMap.put(pKamoku, new RollupItem(psd,pKamoku,pDepart,pTaxKbn,pAmount,pTaxAmount));
			} else {
				RollupItem wkItem = purLeftRollupMap.get(pKamoku);
				wkItem.amount = CommUtils.nullToZero(pAmount) + wkItem.amount;
				// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
				if (gccInfo.isOutTaxToSameLine ) {
					wkItem.taxAmount = String.valueOf(CommUtils.nullToZero(pTaxAmount) + CommUtils.nullToZero(wkItem.taxAmount));
				}
				// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
			}	
		} else if (rType == ROLLUP_TYPE.PUR_R) {
			if (!purRightRollupMap.containskey(pKamoku)) {
				purRightRollupMap.put(pKamoku, new RollupItem(psd,pKamoku,pDepart,pTaxKbn,pAmount,pTaxAmount));
			} else {
				RollupItem wkItem = purRightRollupMap.get(pKamoku);
				wkItem.amount = CommUtils.nullToZero(pAmount) + wkItem.amount;
			}	
		}
	}
	public String generalRollupCsvContent() {
		if (!gccInfo.isOutputRollUp) return '';
		String csvLine = '';
		String csvBody = '';
		gccInfo.startno = gInitStartNo;
		// 一行CSV出力のテンプレート
		String CsvTemplateStr = CONST_CSVDATA_TEMPLATE
								.Replace('$$_[表題行]_$$'			, '[明細行]')
								.Replace('$$_借方部門コード_$$'	, gCcInfo.debdepartcode)
								// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
								//.Replace('$$_借方消費税額_$$'		, gCcInfo.debconsumptax)
								// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
								.Replace('$$_貸方部門コード_$$'	, gCcInfo.credepartcode)
								// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
								//.Replace('$$_貸方消費税額_$$'		, gCcInfo.creconsumptax)
								// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
								.Replace('$$_摘要_$$'	, '');
		// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
		if (!gccInfo.isOutTaxToSameLine ) {
			CsvTemplateStr = CsvTemplateStr.Replace('$$_借方消費税額_$$'		, gCcInfo.debconsumptax)
											.Replace('$$_貸方消費税額_$$'		, gCcInfo.creconsumptax);
		}
		// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
		list<RollupItem> salesLeftRollupList = salesLeftRollupMap.values();
		list<RollupItem> salesRightRollupList = salesRightRollupMap.values();
		list<RollupItem> purLeftRollupList = purLeftRollupMap.values();
		list<RollupItem> purRightRollupList = purRightRollupMap.values();
		String salesDate = '';
		if (!salesLeftRollupList.isEmpty()) salesDate = salesLeftRollupList[0].salesDate;
		else if (!salesRightRollupList.isEmpty()) salesDate = salesRightRollupList[0].salesDate;
		else if (!purLeftRollupList.isEmpty()) salesDate = purLeftRollupList[0].salesDate;
		else if (!purRightRollupList.isEmpty()) salesDate = purRightRollupList[0].salesDate;
		if (CommUtils.isBlank(salesDate)) return csvBody;
		// 現金入出/売上ROLLUP結果明細出力の最大サイズ
		Integer maxLenSales = salesLeftRollupList.size() > salesRightRollupList.size()  ? salesLeftRollupList.size() : salesRightRollupList.size();

		for (Integer i = 0; i < maxLenSales; i++) {	
			csvLine = CsvTemplateStr
					.Replace('$$_伝票番号_$$'			, CommUtils.nullToBlank(gccInfo.startno))
					.Replace('$$_伝票日付_$$' 		, CommUtils.nullToBlank(salesDate));
			// 2016/10/07 仕訳Rollup機能、伝票NO設定不正の不具合修正 BEGIN
			//gccInfo.startno++;
			// 2016/10/07 仕訳Rollup機能、伝票NO設定不正の不具合修正 END
			// 借方情報の支払情報を出力する
			if (i < salesLeftRollupList.size()) {
				csvLine = csvLine
					// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
					//.Replace('$$_借方科目_$$'			, CommUtils.nullToBlank(salesLeftRollupList[i].kanjyoKamoku))
					.Replace('$$_借方科目_$$'			, processEscapeKanji(CommUtils.nullToBlank(salesLeftRollupList[i].kanjyoKamoku)))
					// 2016/12/14 漢字にカンマを含めている改善対応 END
					// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ BEGIN
					//.Replace('$$_借方補助_$$'			, '')
					.Replace('$$_借方補助_$$'			, processEscapeKanji(CommUtils.nullToBlank(salesLeftRollupList[i].hojyoKamoku)))
					// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ END
					.Replace('$$_借方税区分_$$'		, CommUtils.nullToBlank(salesLeftRollupList[i].taxKbn))
					.Replace('$$_借方金額_$$'			, CommUtils.nullToBlank(salesLeftRollupList[i].amount));
				 	// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
				 	if (gccInfo.isOutTaxToSameLine ) {
				 		csvLine = csvLine.Replace('$$_借方消費税額_$$'		,CommUtils.nullToBlank(salesLeftRollupList[i].taxAmount));
				 	}
				 	// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
			} else {
				csvLine = csvLine
						.Replace('$$_借方科目_$$'		, '')
						.Replace('$$_借方補助_$$'			, '')
						.Replace('$$_借方税区分_$$'		, '')
						.Replace('$$_借方金額_$$'			, '');
					 	// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
					 	if (gccInfo.isOutTaxToSameLine ) {
					 		csvLine = csvLine.Replace('$$_借方消費税額_$$'		, '');
					 	}
					 	// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
			}
			// 貸方側の会計明細情報を出力する
			if (i < salesRightRollupList.size()) {
				csvLine = csvLine
						// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
						//.Replace('$$_貸方科目_$$'			, CommUtils.nullToBlank(salesRightRollupList[i].kanjyoKamoku))
						.Replace('$$_貸方科目_$$'			, processEscapeKanji(CommUtils.nullToBlank(salesRightRollupList[i].kanjyoKamoku)))
						// 2016/12/14 漢字にカンマを含めている改善対応 END
						// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ BEGIN
						//.Replace('$$_貸方補助_$$'			, '')
						.Replace('$$_貸方補助_$$'			, processEscapeKanji(CommUtils.nullToBlank(salesRightRollupList[i].hojyoKamoku)))
						// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ END
						.Replace('$$_貸方税区分_$$'		, CommUtils.nullToBlank(salesRightRollupList[i].taxKbn))
					 	.Replace('$$_貸方金額_$$'			, CommUtils.nullToBlank(salesRightRollupList[i].amount));
					 	// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
					 	if (gccInfo.isOutTaxToSameLine ) {
					 		csvLine = csvLine.Replace('$$_貸方消費税額_$$'		, CommUtils.nullToBlank(salesRightRollupList[i].taxAmount));
					 	}
					 	// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
			} else {
				// 消費税出力行目は残りままが必要
				csvLine = csvLine
					.Replace('$$_貸方科目_$$'			, '')
					.Replace('$$_貸方補助_$$'			, '')
					.Replace('$$_貸方税区分_$$'		, '')
					.Replace('$$_貸方金額_$$'			, '');
					// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
					if (gccInfo.isOutTaxToSameLine ) {
						csvLine = csvLine.Replace('$$_貸方消費税額_$$'			, '');
					}
					// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
			}
			csvBody += csvLine;
		}
		// 2016/10/07 仕訳Rollup機能、伝票NO設定不正の不具合修正 BEGIN
		if (maxLenSales > 0) gccInfo.startno++;
		// 2016/10/07 仕訳Rollup機能、伝票NO設定不正の不具合修正 END
		if (gccInfo.isOutputRollUpPur) {
			Integer maxLenPur = purLeftRollupList.size() > purRightRollupList.size()  ? purLeftRollupList.size() : purRightRollupList.size();
//System.debug(Logginglevel.INFO, 'maxLenPur:::' + maxLenPur);
//System.debug(Logginglevel.INFO, 'purLeftRollupList.size():::' +purLeftRollupList.size());
//System.debug(Logginglevel.INFO, 'purRightRollupList.size():::' + purRightRollupList.size());
			for (Integer i = 0; i < maxLenPur; i++) {
				csvLine = CsvTemplateStr
						.Replace('$$_伝票番号_$$'			, CommUtils.nullToBlank(gccInfo.startno))
						.Replace('$$_伝票日付_$$' 		, CommUtils.nullToBlank(salesDate));
				// 2016/10/07 仕訳Rollup機能、伝票NO設定不正の不具合修正 BEGIN
				//gccInfo.startno++;
				// 2016/10/07 仕訳Rollup機能、伝票NO設定不正の不具合修正 END
				// 借方情報の支払情報を出力する
				if (i < purLeftRollupList.size()) {
					csvLine = csvLine
						// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
						//.Replace('$$_借方科目_$$'			, CommUtils.nullToBlank(purLeftRollupList[i].kanjyoKamoku))
						.Replace('$$_借方科目_$$'			, processEscapeKanji(CommUtils.nullToBlank(purLeftRollupList[i].kanjyoKamoku)))
						// 2016/12/14 漢字にカンマを含めている改善対応 END
						// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ BEGIN
						//.Replace('$$_借方補助_$$'			, '')
						.Replace('$$_借方補助_$$'			, processEscapeKanji(CommUtils.nullToBlank(purLeftRollupList[i].hojyoKamoku)))
						// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ END
						.Replace('$$_借方税区分_$$'		, CommUtils.nullToBlank(purLeftRollupList[i].taxKbn))
						.Replace('$$_借方金額_$$'			, CommUtils.nullToBlank(purLeftRollupList[i].amount));
					 	// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
					 	if (gccInfo.isOutTaxToSameLine ) {
					 		csvLine = csvLine.Replace('$$_借方消費税額_$$'		, CommUtils.nullToBlank(purLeftRollupList[i].taxAmount));
					 	}
					 	// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
				} else {
					csvLine = csvLine
							.Replace('$$_借方科目_$$'		, '')
							.Replace('$$_借方補助_$$'			, '')
							.Replace('$$_借方税区分_$$'		, '')
							.Replace('$$_借方金額_$$'			, '');
						 	// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
						 	if (gccInfo.isOutTaxToSameLine ) {
						 		csvLine = csvLine.Replace('$$_借方消費税額_$$'		, '');
						 	}
						 	// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
				}
				// 貸方側の会計明細情報を出力する
				if (i < purRightRollupList.size()) {
					csvLine = csvLine
							// 2016/12/14 漢字にカンマを含めている改善対応 BEGIN
							//.Replace('$$_貸方科目_$$'			, CommUtils.nullToBlank(purRightRollupList[i].kanjyoKamoku))
							.Replace('$$_貸方科目_$$'			, processEscapeKanji(CommUtils.nullToBlank(purRightRollupList[i].kanjyoKamoku)))
							// 2016/12/14 漢字にカンマを含めている改善対応 END
							// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ BEGIN
							//.Replace('$$_貸方補助_$$'			, '')
							.Replace('$$_貸方補助_$$'			, processEscapeKanji(CommUtils.nullToBlank(purRightRollupList[i].hojyoKamoku)))
							// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ END
							.Replace('$$_貸方税区分_$$'		, CommUtils.nullToBlank(purRightRollupList[i].taxKbn))
						 	.Replace('$$_貸方金額_$$'			, CommUtils.nullToBlank(purRightRollupList[i].amount));
						 	// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
						 	if (gccInfo.isOutTaxToSameLine ) {
						 		csvLine = csvLine.Replace('$$_貸方消費税額_$$'		, gCcInfo.creconsumptax);
						 	}
						 	// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
				} else {
					// 消費税出力行目は残りままが必要
					csvLine = csvLine
						.Replace('$$_貸方科目_$$'			, '')
						.Replace('$$_貸方補助_$$'			, '')
						.Replace('$$_貸方税区分_$$'		, '')
						.Replace('$$_貸方金額_$$'			, '');
					 	// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
					 	if (gccInfo.isOutTaxToSameLine ) {
					 		csvLine = csvLine.Replace('$$_貸方消費税額_$$'		, '');
					 	}
					 	// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
				}
				csvBody += csvLine;
			}
		} else {
			// ----------------------
			// 仕入の仕訳情報の作成(2015/11/09 仕入情報は出力機能の追加)
			// ----------------------
			csvBody += generalPurchaseCsvInfo(gccInfo, gKanjoKamokuMstMap);
		}
		// Header追加
		if (!CommUtils.isBlank(csvBody) && isAppendCsvHeaderFlg) csvBody = (Label.INF_0005 + '\n') + csvBody;
		return csvBody;
	}
	class RollupItem {
		public RollupItem () {
			amount = 0;
		}
		public RollupItem (String k1, String k2, String k3, String k4, String k5, String k6) {
			salesDate = k1;kanjyoKamoku = k2;department =k3;taxKbn = k4;amount=CommUtils.nullToZero(k5);taxAmount=k6;
			// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ BEGIN
			if (kanjyoKamoku.contains(CONST_HOJYOKAMOKU_KEY)) {
				List<String> codeValue = kanjyoKamoku.split(CONST_HOJYOKAMOKU_KEY);
				kanjyoKamoku = codeValue[0];
				if (codeValue.size() > 1) hojyoKamoku = codeValue[1];
			}
			// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ END
		}
		public String salesDate{get;set;}	// 日付
		public String kanjyoKamoku{get;set;}// 科目
		public String department{get;set;}	// 部門
		public String taxKbn{get;set;}		// 税区分
		public Decimal amount{get;set;}		// 金額
		public String taxAmount{get;set;}	// 税額
		// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ BEGIN
		public String hojyoKamoku{get;set;}//補助科目
		// 2018/10/23 FREEERU出力機能改善(補助科目の出力) WSQ END
	}
	// 2016/09/23 仕訳Rollup機能追加対応[入出金、売上]単位にRollup、仕入は単独Rollup END
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
		Dom.XmlNode nodePurchase =  shopRoot.getChildElement('PURCHASE', null);
		
   	 	if (nodePca != null) {
   	 		// 2015/11/13 Freeeの場合、レイアウト制御フラグ ADD
			Dom.XmlNode layoutField =  nodePca.getChildElement('FREEE_LAYOUT', null);
			if (layoutField != null) xmlConfig.layoutKbn = CommUtils.nullToBlank(layoutField.getText());
			// 2015/12/03  CSV出力の場合、勘定科目名を出力すると、後ろからN文字を削除して、出力機能の追加
			Dom.XmlNode processFilterField =  nodePca.getChildElement('PROCESS_FILTER', null);
			if (processFilterField != null) {
				Dom.XmlNode kanjyoNameNLastCharDelField =  processFilterField.getChildElement('KANJYONAME_NLASTCHAR_DEL', null);
				if (kanjyoNameNLastCharDelField != null) {
					xmlConfig.filterKanjyoNmLastCharDelKey = CommUtils.nullToIntZero(kanjyoNameNLastCharDelField.getText());
				}
			}
			// 2015/12/04 売上の仕訳情報に、内訳情報出力する・しない制御フラグ
			Dom.XmlNode utiWakeField =  nodePca.getChildElement('UTIWAKE_OUTPUT', null);
			if (utiWakeField != null) {
				Dom.XmlNode utiWakeIsOutField =  utiWakeField.getChildElement('ISOUPUT', null);
				if (utiWakeIsOutField != null) xmlConfig.isOutputUtiwake = Boolean.valueOf(CommUtils.nullToBlank(utiWakeIsOutField.getText()));
				Dom.XmlNode utiWakeCardField =  utiWakeField.getChildElement('CARD_TESURYO', null);
				if (utiWakeCardField != null) {
					Dom.XmlNode cardTesuryoTrueOnlyField =  utiWakeCardField.getChildElement('PAYCHARGEFLG_REQUIRE', null);
					// 2016/04/21 販売手数料は内訳出力場合、手数料支払＝FALSE制御条件追加 BEGIN
					if (cardTesuryoTrueOnlyField != null) {
						string cardTesuryoTrueOnlyFieldStr = CommUtils.nullToBlank(cardTesuryoTrueOnlyField.getText());
						if (CommUtils.isBlank(cardTesuryoTrueOnlyFieldStr)) xmlConfig.cardTesuryoTrueOnly = null;
						else xmlConfig.cardTesuryoTrueOnly = Boolean.valueOf(cardTesuryoTrueOnlyFieldStr);
					}
					// 2016/04/21 販売手数料は内訳出力場合、手数料支払＝FALSE制御条件追加 END
					Dom.XmlNode cardTesuryoField = utiWakeCardField.getChildElement('KANJOCODE', null);
					if (cardTesuryoField != null) xmlConfig.cardTesuryoSeqNo = CommUtils.nullToBlank(cardTesuryoField.getText());
					// 2016/07/21 カード手数料・販売手数料は別行目に出力機能制御追加　BEGIN
					Dom.XmlNode cardTesuryoRightField = utiWakeCardField.getChildElement('KANJOCODE_R', null);
					if (cardTesuryoRightField != null) xmlConfig.cardTesuryoRightSeqNo = CommUtils.nullToBlank(cardTesuryoRightField.getText());
					
					Dom.XmlNode cardTesuryoTaxKbnField = utiWakeCardField.getChildElement('KANJOCODE_TAXKBN', null);
					if (cardTesuryoTaxKbnField != null) xmlConfig.cardTesuryoTaxKbn = CommUtils.nullToBlank(cardTesuryoTaxKbnField.getText());
					Dom.XmlNode cardTesuryoRightTaxKbnField = utiWakeCardField.getChildElement('KANJOCODE_R_TAXKBN', null);
					if (cardTesuryoRightTaxKbnField != null) xmlConfig.cardTesuryoRightTaxKbn = CommUtils.nullToBlank(cardTesuryoRightTaxKbnField.getText());
					// 2016/07/21 カード手数料・販売手数料は別行目に出力機能制御追加　END
				}
				// 2015/03/08 販売手数料は内訳として、出力機能の対応 BEGIN				
				Dom.XmlNode utiWakeAgtField =  utiWakeField.getChildElement('AGT_TESURYO', null);
				if (utiWakeAgtField != null) {
					Dom.XmlNode agtTesuryoTrueOnlyField =  utiWakeAgtField.getChildElement('PAYCHARGEFLG_REQUIRE', null);
					// 2016/04/21 販売手数料は内訳出力場合、手数料支払＝FALSE制御条件追加 BEGIN
					if (agtTesuryoTrueOnlyField != null) {
						string agtTesuryoTrueOnlyStr = CommUtils.nullToBlank(agtTesuryoTrueOnlyField.getText());
						if (CommUtils.isBlank(agtTesuryoTrueOnlyStr)) xmlConfig.agtTesuryoTrueOnly = null;
						else xmlConfig.agtTesuryoTrueOnly = Boolean.valueOf(agtTesuryoTrueOnlyStr);
					}
					// 2016/04/21 販売手数料は内訳出力場合、手数料支払＝FALSE制御条件追加 END
					Dom.XmlNode agtTesuryoField = utiWakeAgtField.getChildElement('KANJOCODE', null);
					if (agtTesuryoField != null) xmlConfig.agtTesuryoSeqNo = CommUtils.nullToBlank(agtTesuryoField.getText());
					// 2016/07/21 カード手数料・販売手数料は別行目に出力機能制御追加　BEGIN
					Dom.XmlNode agtTesuryoRightField = utiWakeAgtField.getChildElement('KANJOCODE_R', null);
					if (agtTesuryoRightField != null) xmlConfig.agtTesuryoRightSeqNo = CommUtils.nullToBlank(agtTesuryoRightField.getText());
					
					Dom.XmlNode agtTesuryoTaxKbnField = utiWakeAgtField.getChildElement('KANJOCODE_TAXKBN', null);
					if (agtTesuryoTaxKbnField != null) xmlConfig.agtTesuryoTaxKbn = CommUtils.nullToBlank(agtTesuryoTaxKbnField.getText());
					Dom.XmlNode agtTesuryoRightTaxKbnField = utiWakeAgtField.getChildElement('KANJOCODE_R_TAXKBN', null);
					if (agtTesuryoRightTaxKbnField != null) xmlConfig.agtTesuryoRightTaxKbn = CommUtils.nullToBlank(agtTesuryoRightTaxKbnField.getText());
						
					// 2016/07/21 カード手数料・販売手数料は別行目に出力機能制御追加　END
					Dom.XmlNode agtTesuryoMediaTypeField = utiWakeAgtField.getChildElement('MEDIA_TYPE', null);
					if (agtTesuryoMediaTypeField != null) {
						list<String> mediaTypes = CommUtils.nullToBlank(agtTesuryoMediaTypeField.getText()).split(',');
						for (String s : mediaTypes) {
							if (CommUtils.isBlank(s)) continue;
							xmlConfig.agtMediaTypeSet.add(s);
						}
					}
				}
				// 2015/03/08 販売手数料は内訳として、出力機能の対応 END
			}
			Dom.XmlNode priceZeroField =  nodePca.getChildElement('PRICEZERO_OUTPUT', null);
			if (priceZeroField != null) {
				xmlConfig.isOutputPriceZero = Boolean.valueOf(CommUtils.nullToBlank(priceZeroField.getText()));
			}
			// 2016/09/23 仕訳Rollup機能追加対応 BEGIN
			Dom.XmlNode rollUpField =  nodePca.getChildElement('ROLLUP_OUTPUT', null);
			if (rollUpField != null) {
				xmlConfig.isOutputRollUp = Boolean.valueOf(CommUtils.nullToBlank(rollUpField.getText()));
			}
			Dom.XmlNode rollUpPurField =  nodePca.getChildElement('ROLLUP_PUR_OUTPUT', null);
			if (rollUpPurField != null) {
				xmlConfig.isOutputRollUpPur = Boolean.valueOf(CommUtils.nullToBlank(rollUpPurField.getText()));
			}
			// 2016/09/23 仕訳Rollup機能追加対応 END
			// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
			Dom.XmlNode pointProcessField =  nodePca.getChildElement('POINT_PROCESS', null);
			if (pointProcessField != null) {
				xmlConfig.pointProcess = Boolean.valueOf(CommUtils.nullToBlank(pointProcessField.getText()));
			}
			// 2016/11/21 出力金額の小数点対応できる改善 END
			// 2015/12/04 自動仕訳の借り方税区分の変更対応
			Dom.XmlNode taxKbnField =  nodePca.getChildElement('TAX_KBN', null);
			if (taxKbnField != null) {
				for (Dom.XmlNode taxKbnItemNode : taxKbnField.getChildElements() ) {
					TaxKbnInfo taxInf = new TaxKbnInfo(taxKbnItemNode);
					if (!Commutils.isBLank(taxInf.kanjyoKamokuSeq)) {
						xmlConfig.taxKbnConfigMap.put(taxInf.kanjyoKamokuSeq,taxInf);
					}
				}
			}
			
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
   	 			// 2015/12/07 FREEE借税区分情報格納
   	 			Dom.XmlNode notaxkbnField = nodePacField.getChildElement('NOTAXKBN', null);
   	 			if (notaxkbnField != null) {
   	 				xmlConfig.notaxkbn = CommUtils.nullToBlank(notaxkbnField.getText()).deleteWhitespace();
   	 			}
   	 		}
   	 		// 2019/09/20 多税率機能対応 WSQ BEGIN
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
   	 		// 2016/03/10 借方の仮払消費税の会計科目出力機能の追加 END
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
                	// 2019/09/20 多税率機能対応 WSQ BEGIN
                    //Dom.XmlNode kanjocodeRField = nodePcaServiceR.getChildElement('KANJOCODE', null);
                    //xmlConfig.serviceRkanjoCode = CommUtils.nullToBlank(kanjocodeRField.getText()).deleteWhitespace();
		   	 		for (Dom.XmlNode m1 : nodePcaServiceR.getChildElements() ) {
		   	 		    if (m1.getName() == 'KANJOCODE') {
		   	 		    	xmlConfig.serviceRkanjoCode = CommUtils.nullToBlank(m1.getText()).deleteWhitespace();
		   	 		    	string strRate = m1.getAttribute('RATE', null);
		   	 		    	if (!CommUtils.isBlank(strRate)) xmlConfig.serviceRkanjoMap.put(formattax(CommUtils.nullToZero(strRate)),xmlConfig.serviceRkanjoCode);
		   	 		    }
		   	 		}
		   	 		// 2019/09/20 多税率機能対応 WSQ END
                }
            }
            // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
			// 2018/10/23 FREEERU出力機能改善(補助科目の出力) BEGIN
			Dom.XmlNode rollupSubKamokuField =  nodePca.getChildElement('ROLLUP_SUBKAMOKU_OUTPUT', null);
			if (rollupSubKamokuField != null) {
				xmlConfig.rollupSubKamokuFlg = Boolean.valueOf(CommUtils.nullToBlank(rollupSubKamokuField.getText()));
			}
			// 2018/10/23 FREEERU出力機能改善(補助科目の出力) END
			// 2018/11/05 仕訳明細は税込・税抜出力選択できるように改善対応 WSQ BEGIN
			Dom.XmlNode isIncTaxFlgField =  nodePca.getChildElement('ISINCTAXFLG', null);
			if (isIncTaxFlgField != null) {
				xmlConfig.isIncTaxFlg = Boolean.valueOf(CommUtils.nullToBlank(isIncTaxFlgField.getText()));
			}
			// 2018/11/05 仕訳明細は税込・税抜出力選択できるように改善対応 WSQ END
			// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
			Dom.XmlNode taxcolOutputField =  nodePca.getChildElement('TAX_SAMELINE_OUTPUT', null);
			if (taxcolOutputField != null) {
				xmlConfig.isOutTaxToSameLine = Boolean.valueOf(CommUtils.nullToBlank(taxcolOutputField.getText()));
			}
			// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
			// 2020/01/21 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う）WSQ BEGIN
			Dom.XmlNode pcaNewModeField =  nodePca.getChildElement('PCA_NEWMODE', null);
			if (pcaNewModeField != null) {
				Dom.XmlNode activeField = pcaNewModeField.getChildElement('ACTIVE', null);
				xmlConfig.isUseDayOutMode = Boolean.valueOf(CommUtils.nullToBlank(activeField.getText()));
				if (xmlConfig.isUseDayOutMode) {
					Dom.XmlNode apLeftKanjoSeqNoField = pcaNewModeField.getChildElement('AP_KANJOSEQ_L', null);
					if (apLeftKanjoSeqNoField != null) xmlConfig.apLeftKanjoSeqNo = CommUtils.nullToBlank(apLeftKanjoSeqNoField.getText());
					Dom.XmlNode dpLeftKanjoSeqNoField = pcaNewModeField.getChildElement('DP_KANJOSEQ_L', null);
					if (dpLeftKanjoSeqNoField != null) xmlConfig.dpLeftKanjoSeqNo = CommUtils.nullToBlank(dpLeftKanjoSeqNoField.getText());
					Dom.XmlNode acKanjoSeqNoField = pcaNewModeField.getChildElement('AC_KANJOSEQ_R', null);
					if (acKanjoSeqNoField != null) xmlConfig.acKanjoSeqNo = CommUtils.nullToBlank(acKanjoSeqNoField.getText());
					// 2020/09/15 連泊の支払を入れた際の挙動修正2 WSQ BEGIN
					Dom.XmlNode apRightKanjoSeqNoField = pcaNewModeField.getChildElement('AP_KANJOSEQ_R', null);
					if (apRightKanjoSeqNoField != null) xmlConfig.apRightKanjoSeqNo = CommUtils.nullToBlank(apRightKanjoSeqNoField.getText());
					// 2020/09/15 連泊の支払を入れた際の挙動修正2 WSQ END
				}
			}
			// 2020/01/21 freee連携時、連泊の支払を入れた際の挙動修正（利用日により、仕訳明細出力を行う）WSQ END
   	 	}

   	 	if (nodeCash != null) {
   	 	    Dom.XmlNode nodeCashInput = nodeCash.getChildElement('CASH_INPUT', null);
   	 	    if (nodeCashInput != null) {
   	 	    	// 2018/11/26 FREEE/FREEERU出力機能、入出金科目、仕入種別科目のまま明細出力できるように改善対応 WSQ BEGIN
   	 	    	string kamokuOutFlgStr = nodeCashInput.getAttribute('KAMOKUOUT', null);
   	 	    	if (!CommUtils.isBlank(kamokuOutFlgStr)) xmlConfig.isCashInputOuByKamoku = Boolean.valueOf(CommUtils.nullToBlank(kamokuOutFlgStr));
   	 	    	// 2018/11/26 FREEE/FREEERU出力機能、入出金科目、仕入種別科目のまま明細出力できるように改善対応 WSQ END
   	 	    	// 2019/05/15 現金入出の「取引先」項目追加 BY zyz BEGIN
   	 	    	string accountInFlgStr = nodeCashInput.getAttribute('HOJYO_ACCOUNT', null);
   	 	    	if (!CommUtils.isBlank(accountInFlgStr)) xmlConfig.isCashInputAccount = Boolean.valueOf(CommUtils.nullToBlank(accountInFlgStr));
   	 	    	// 2019/05/15 現金入出の「取引先」項目追加 BY zyz END
   	 	    	// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応　WSQ BEGIN
   	 	    	for (Dom.XmlNode c1:nodeCashInput.getChildElements() ) {
   	 	    		// 入金の左側勘定科目コード
   	 	    		Dom.XmlNode p1tField = c1.getChildElement('KEMOKU', null);
   	 	    		if (p1tField == null) continue;
   	 	    		String c1k = CommUtils.nullToBlank(p1tField.getText());
   	 	    		for (Dom.XmlNode pe : c1.getChildElements() ) {
						String tagName = pe.getName();
						// 左の勘定科目
						if (tagName == 'I_KANJOCODE') {
							// 勘定科目コード
							String p1K = CommUtils.nullToBlank(pe.getText()).deleteWhitespace();
							// 消費税
							string strRate = pe.getAttribute('RATE', null);
							// 消費税定義されている場合
							if (!CommUtils.isBlank(strRate)) {
								if (!xmlConfig.cashInputInRateKbnMap.containsKey(c1k)) xmlConfig.cashInputInRateKbnMap.put(c1k, new map<Decimal,String>());
								xmlConfig.cashInputInRateKbnMap.get(c1k).put(formattax(CommUtils.nullToZero(strRate)),p1K);
							} else {
								xmlConfig.cashInputInMap.put(c1k, p1K);
							}
						} 
						// 右の勘定科目
						else if (tagName == 'O_KANJOCODE') {
							// 勘定科目コード
							String p1K = CommUtils.nullToBlank(pe.getText()).deleteWhitespace();
							// 消費税
							string strRate = pe.getAttribute('RATE', null);
							// 消費税定義されている場合
							if (!CommUtils.isBlank(strRate)) {
								if (!xmlConfig.cashInputOuRateKbnMap.containsKey(c1k)) xmlConfig.cashInputOuRateKbnMap.put(c1k, new map<Decimal,String>());
								xmlConfig.cashInputOuRateKbnMap.get(c1k).put(formattax(CommUtils.nullToZero(strRate)),p1K);
							} else {
								xmlConfig.cashInputOuMap.put(c1k, p1K);
							}
						}
   	 	    		}
   	 	    	}// END 
				/*   	 	    	
   	 	    	for (Dom.XmlNode c1:nodeCashInput.getChildElements() ) {
   	 	    		String c1k = CommUtils.nullToBlank(c1.getChildElement('KEMOKU', null).getText());
   	 	    		String c1i = CommUtils.nullToBlank(c1.getChildElement('I_KANJOCODE', null).getText()).deleteWhitespace();
   	 	    		String c1o = CommUtils.nullToBlank(c1.getChildElement('O_KANJOCODE', null).getText()).deleteWhitespace();
   	 	    		xmlConfig.cashInputInMap.put(c1k, c1i);
   	 	    		xmlConfig.cashInputOuMap.put(c1k, c1o);
   	 	    	}*/
   	 	    	// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応　WSQ END
   	 	    }
   	 	    Dom.XmlNode nodeCashOutput = nodeCash.getChildElement('CASH_OUTPUT', null);
   	 	    if (nodeCashOutput != null) {
   	 	    	// 2018/11/26 FREEE/FREEERU出力機能、入出金科目、仕入種別科目のまま明細出力できるように改善対応 WSQ BEGIN
   	 	    	string kamokuOutFlgStr = nodeCashOutput.getAttribute('KAMOKUOUT', null);
   	 	    	if (!CommUtils.isBlank(kamokuOutFlgStr)) xmlConfig.isCashOutputOuByKamoku = Boolean.valueOf(CommUtils.nullToBlank(kamokuOutFlgStr));
   	 	    	// 2018/11/26 FREEE/FREEERU出力機能、入出金科目、仕入種別科目のまま明細出力できるように改善対応 WSQ END
   	 	    	// 2019/05/15 現金入出の「取引先」項目追加 BY zyz BEGIN
   	 	    	string accountOutFlgStr = nodeCashOutput.getAttribute('HOJYO_ACCOUNT', null);
   	 	    	if (!CommUtils.isBlank(accountOutFlgStr)) xmlConfig.isCashOutputAccount = Boolean.valueOf(CommUtils.nullToBlank(accountOutFlgStr));
   	 	    	// 2019/05/15 現金入出の「取引先」項目追加 BY zyz END
   	 	    	// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応　WSQ BEGIN
   	 	    	for (Dom.XmlNode c2:nodeCashOutput.getChildElements() ) {
   	 	    		// 入金の左側勘定科目コード
   	 	    		Dom.XmlNode p1tField = c2.getChildElement('KEMOKU', null);
   	 	    		if (p1tField == null) continue;
   	 	    		String c2k = CommUtils.nullToBlank(p1tField.getText());
   	 	    		for (Dom.XmlNode pe : c2.getChildElements() ) {
						String tagName = pe.getName();
						// 左の勘定科目
						if (tagName == 'I_KANJOCODE') {
							// 勘定科目コード
							String p1K = CommUtils.nullToBlank(pe.getText()).deleteWhitespace();
							// 消費税
							string strRate = pe.getAttribute('RATE', null);
							// 消費税定義されている場合
							if (!CommUtils.isBlank(strRate)) {
								if (!xmlConfig.cashOutputInRateKbnMap.containsKey(c2k)) xmlConfig.cashOutputInRateKbnMap.put(c2k, new map<Decimal,String>());
								xmlConfig.cashOutputInRateKbnMap.get(c2k).put(formattax(CommUtils.nullToZero(strRate)),p1K);
							} else {
								xmlConfig.cashOutputInMap.put(c2k, p1K);
							}
						} 
						// 右の勘定科目
						else if (tagName == 'O_KANJOCODE') {
							// 勘定科目コード
							String p1K = CommUtils.nullToBlank(pe.getText()).deleteWhitespace();
							// 消費税
							string strRate = pe.getAttribute('RATE', null);
							// 消費税定義されている場合
							if (!CommUtils.isBlank(strRate)) {
								if (!xmlConfig.cashOutputOuRateKbnMap.containsKey(c2k)) xmlConfig.cashOutputOuRateKbnMap.put(c2k, new map<Decimal,String>());
								xmlConfig.cashOutputOuRateKbnMap.get(c2k).put(formattax(CommUtils.nullToZero(strRate)),p1K);
							} else {
								xmlConfig.cashOutputOuMap.put(c2k, p1K);
							}
						}
   	 	    		}
   	 	    	}// END 
   	 	    	/*
   	 	    	for (Dom.XmlNode c2:nodeCashOutput.getChildElements() ) {
   	 	    		String c2k = CommUtils.nullToBlank(c2.getChildElement('KEMOKU', null).getText());
   	 	    		String c2i = CommUtils.nullToBlank(c2.getChildElement('I_KANJOCODE', null).getText()).deleteWhitespace();
   	 	    		String c2o = CommUtils.nullToBlank(c2.getChildElement('O_KANJOCODE', null).getText()).deleteWhitespace();
   	 	    		xmlConfig.cashOutputInMap.put(c2k, c2i);
   	 	    		xmlConfig.cashOutputOuMap.put(c2k, c2o);
   	 	    	}
   	 	    	*/
   	 	    	// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応　WSQ END
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
   	 	// 2015/11/13 会計科目名と補助科目名を出力できる対応 BEGIN
   	 	if (nodePurchase != null) {
			// 2018/11/26 FREEE/FREEERU出力機能、入出金科目、仕入種別科目のまま明細出力できるように改善対応 WSQ BEGIN
			string kamokuOutFlgStr = nodePurchase.getAttribute('KAMOKUOUT', null);
			if (!CommUtils.isBlank(kamokuOutFlgStr)) xmlConfig.isPurchaseOuByKamoku = Boolean.valueOf(CommUtils.nullToBlank(kamokuOutFlgStr));
			// 2018/11/26 FREEE/FREEERU出力機能、入出金科目、仕入種別科目のまま明細出力できるように改善対応 WSQ END
   	 		// 種別：借方
   	 	    Dom.XmlNode purchaseInput = nodePurchase.getChildElement('P_TYPE', null);
   	 	    if (purchaseInput != null) {
   	 	    	for (Dom.XmlNode c1:purchaseInput.getChildElements() ) {
   	 	    		// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応　WSQ BEGIN
   	 	    		Dom.XmlNode p1tField = c1.getChildElement('TYPENAME', null);
   	 	    		if (p1tField == null) continue;
   	 	    		String p1t = CommUtils.nullToBlank(p1tField.getText());
   	 	    		// <CONVERT> の子項目を取得する
					for (Dom.XmlNode pe : c1.getChildElements() ) {
						String tagName = pe.getName();
						// 左の勘定科目
						if (tagName == 'KANJOCODE') {
							// 種別
							String p1K = CommUtils.nullToBlank(pe.getText()).deleteWhitespace();
							// 消費税
							string strRate = pe.getAttribute('RATE', null);
							// 消費税定義されている場合
							if (!CommUtils.isBlank(strRate)) {
								if (!xmlConfig.purchaseInRateKbnMap.containsKey(p1t)) xmlConfig.purchaseInRateKbnMap.put(p1t, new map<Decimal,String>());
								xmlConfig.purchaseInRateKbnMap.get(p1t).put(formattax(CommUtils.nullToZero(strRate)),p1K);
							} else {
								xmlConfig.purchaseInMap.put(p1t, p1K);
							}
						// 右の勘定科目
						} else if (tagName == 'KANJOCODE_R') {
							// 右側の勘定科目コード
	   	 	    			String p1R = CommUtils.nullToBlank(pe.getText());
							// 消費税
							string strRate = pe.getAttribute('RATE', null);
							// 消費税定義されている場合
							if (!CommUtils.isBlank(strRate)) {
								if (!xmlConfig.purchaseOutOfTypeRateKbnMap.containsKey(p1t)) xmlConfig.purchaseOutOfTypeRateKbnMap.put(p1t, new map<Decimal,String>());
								xmlConfig.purchaseOutOfTypeRateKbnMap.get(p1t).put(formattax(CommUtils.nullToZero(strRate)),p1R);
							} else {
								if (!CommUtils.isBlank(p1R)) xmlConfig.purchaseOutOfTypeMap.put(p1t, p1R);
							}
						}
					}
   	 	    		/*
   	 	    		Dom.XmlNode p1tField = c1.getChildElement('TYPENAME', null);
   	 	    		Dom.XmlNode p1KField = c1.getChildElement('KANJOCODE', null);
   	 	    		if (p1tField == null || p1KField == null) continue;
   	 	    		String p1t = CommUtils.nullToBlank(p1tField.getText());
   	 	    		String p1K = CommUtils.nullToBlank(p1KField.getText()).deleteWhitespace();
   	 	    		xmlConfig.purchaseInMap.put(p1t, p1K);
   	 	    		// 2015/12/10 仕入オブジェクトの種別の貸方の勘定科目指定できる様に機能対応 BEGIN
   	 	    		// 種別に紐付くの貸方の勘定科目定義情報
   	 	    		Dom.XmlNode p1RField = c1.getChildElement('KANJOCODE_R', null);
   	 	    		if (p1RField != null) {
	   	 	    		String p1R = CommUtils.nullToBlank(p1RField.getText());
	   	 	    		if (!CommUtils.isBlank(p1R)) xmlConfig.purchaseOutOfTypeMap.put(p1t, p1R);
   	 	    		}
					// 2015/12/10 仕入オブジェクトの種別の貸方の勘定科目指定できる様に機能対応 END
					// 2016/07/26 仕入オブジェクトの種別の貸方の勘定科目の税区分指定できるように対応 BEGIN
					Dom.XmlNode p1tTaxKbnField = c1.getChildElement('KANJOCODE_TAXKBN', null);
					Dom.XmlNode p1RTaxKbnField = c1.getChildElement('KANJOCODE_TAXKBN_R', null);
					if (p1tTaxKbnField != null) {
						String p1tTaxKbn = CommUtils.nullToBlank(p1tTaxKbnField.getText());
						xmlConfig.purchaseInTaxKbnMap.put(p1t, p1tTaxKbn);
					}
					if (p1RTaxKbnField != null) {
						String p1RTaxKbn = CommUtils.nullToBlank(p1RTaxKbnField.getText());
						xmlConfig.purchaseOutTaxKbnMap.put(p1t, p1RTaxKbn);
					}
					// 2016/07/26 仕入オブジェクトの種別の貸方の勘定科目の税区分指定できるように対応 END
					*/
				// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応 WSQ END
   	 	    	}
   	 	    }
   	 		// 科目：貸方
   	 	    Dom.XmlNode purchaseOutput = nodePurchase.getChildElement('P_KAMOKU', null);
   	 	    if (purchaseOutput != null) {
   	 	    	for (Dom.XmlNode c1:purchaseOutput.getChildElements() ) {
   	 	    		// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応　WSQ BEGIN
   	 	    		Dom.XmlNode p1tField = c1.getChildElement('TYPENAME', null);
   	 	    		if (p1tField == null) continue;
   	 	    		String p1t = CommUtils.nullToBlank(p1tField.getText());
   	 	    		// <CONVERT> の子項目を取得する
					for (Dom.XmlNode pe : c1.getChildElements() ) {
						String tagName = pe.getName();
						// 左の勘定科目
						if (tagName == 'KANJOCODE') {
							// 種別
							String p1K = CommUtils.nullToBlank(pe.getText()).deleteWhitespace();
							// 消費税
							string strRate = pe.getAttribute('RATE', null);
							// 消費税定義されている場合
							if (!CommUtils.isBlank(strRate)) {
								if (!xmlConfig.purchaseOutRateKbnMap.containsKey(p1t)) xmlConfig.purchaseOutRateKbnMap.put(p1t, new map<Decimal,String>());
								xmlConfig.purchaseOutRateKbnMap.get(p1t).put(formattax(CommUtils.nullToZero(strRate)),p1K);
							} else {
								xmlConfig.purchaseOutMap.put(p1t, p1K);
							}
						}
					}
   	 	    		/*
   	 	    		String p1t = CommUtils.nullToBlank(c1.getChildElement('TYPENAME', null).getText());
   	 	    		String p1K = CommUtils.nullToBlank(c1.getChildElement('KANJOCODE', null).getText()).deleteWhitespace();
   	 	    		xmlConfig.purchaseOutMap.put(p1t, p1K);
   	 	    		*/
   	 	    		// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応　WSQ END
   	 	    	}
   	 	    }
   	 	}
		// 2015/11/13 会計科目名と補助科目名を出力できる対応 END
		// 2018/02/22 摘要欄の出力内容はカスタマイズできるように改善対応 WGCH BEGIN
		xmlFieldsMap = new Map<String, String>();
		Dom.XmlNode nodeFields =  shopRoot.getChildElement('MEMO_CUSTOM', null);
		if(nodeFields != null){
			String wkDelimiterStr = nodeFields.getAttribute('DELIMITER', null);
			if(wkDelimiterStr != null) delimiterStr = wkDelimiterStr;
			List<String> fieldsSplits = CommUtils.nullToBlank(nodeFields.getText()).deleteWhitespace().split(',');
			// XMLに定義された表示項目リスト取得、処理を行う
			for (String item : fieldsSplits) {
				String[] keySplits = item.split(':');
				if(keySplits.size() == 2 && !CommUtils.isBlank(keySplits[0])){
					String key = 'relreserve__r.' + CommUtils.nullToBlank(keySplits[0]).toLowerCase();
					String lab = CommUtils.nullToBlank(keySplits[1]);
					xmlFieldsMap.put(key,lab);
				}
			}
		}
		// 2018/02/22 摘要欄の出力内容はカスタマイズできるように改善対応 WGCH END
		// 2018/10/10 摘要欄の出力内容に改善対応 zyz BEGIN
		xmlPurFieldsMap = new Map<String, String>();
		Dom.XmlNode memoFields =  shopRoot.getChildElement('MEMO_PURCHASE', null);
		if(memoFields != null){
			String wkDelimiterStr = memoFields.getAttribute('DELIMITER', null);
			if(wkDelimiterStr != null) purdelimiterStr = wkDelimiterStr;
			List<String> fieldsSplits = CommUtils.nullToBlank(memoFields.getText()).deleteWhitespace().split(',');
			// XMLに定義された表示項目リスト取得、処理を行う
			for (String item : fieldsSplits) {
				String[] keySplits = item.split(':');
				if(keySplits.size() == 2 && !CommUtils.isBlank(keySplits[0])){
					String key = CommUtils.nullToBlank(keySplits[0]).toLowerCase();
					String lab = CommUtils.nullToBlank(keySplits[1]);
					xmlPurFieldsMap.put(key,lab);
				}
			}
		}
		// 2018/10/10 摘要欄の出力内容に改善対応 zyz END
		// 関連の支払メデイア情報取得する
   	 	BillSimpleHelp help = new BillSimpleHelp(shopCode);
   	 	xmlConfig.mediaProductCdMap = help.getMediaLabToAccMstMap();
   	 	
   	 	return xmlConfig;
    }
    // 2018/02/22 摘要欄の出力内容はカスタマイズできるように改善対応 WGCH BEGIN
    private Map<String, String> xmlFieldsMap;
    private static final String RELATION_KEY = '__r.';
    private String delimiterStr = ' 　';
    private Set<String> leadApiSet = new Set<String>{'relreserve__r.leadindexref__c','relreserve__r.leadindexsubid__c','relreserve__r.roomgroupno__c','relaccount__r.account.id__c','relreserve__r.no__c','relreserve__r.rroom__r.name','relreserve__r.relcontact__r.name','relaccount__r.account.name','relaccount__r.name','relreserve__r.reservedtype__c','relreserve__r.field2__c','relreserve__r.relcontact__r.accountid','relreserve__r.salesofficeinforef__c','relreserve__r.salesofficeinforef__r.parentid'};
    private String getXmlMemoStr(AccountAcount__c acc){
    	String xmlMemoStr = '';
		for(String leadApi : xmlFieldsMap.keySet()){
			xmlMemoStr += xmlFieldsMap.get(leadApi) +'： ' + CommUtils.nullToBlank( getValueByApi(acc, leadApi) ) + delimiterStr;
		}
		xmlMemoStr = xmlMemoStr.removeEnd(delimiterStr);
		return xmlMemoStr;
    }
    // 2018/10/10 摘要欄の出力内容に改善対応 zyz BEGIN
    private Map<String, String> xmlPurFieldsMap;
    private String purdelimiterStr = ' 　';
    private String getXmlPurMemoStr(Purchase__c pur){
    	String xmlMemoStr = '';
		for(String purApi : xmlPurFieldsMap.keySet()){
			if(!purApi.contains('__r.')){
				xmlMemoStr += xmlPurFieldsMap.get(purApi) +'： ' + CommUtils.nullToBlank( pur.get(purApi) ) + purdelimiterStr;
			}else {xmlMemoStr += xmlPurFieldsMap.get(purApi) +'： ' + CommUtils.nullToBlank( getValueByApi(pur, purApi) ) + purdelimiterStr;}
		}
		xmlMemoStr = xmlMemoStr.removeEnd(purdelimiterStr);
		return xmlMemoStr;
    }
    // 2018/10/10 摘要欄の出力内容に改善対応 zyz END
    // 参照字段对应
    private static Object getValueByApi(Sobject s ,String field) {
        if (s == null) return '';
        String apiField = field.trim();
        // Jsonにアサインするキー: ssss__r.aaa__r.xxxx -> ssss__r_aaa__r_xxxx
        // 2017/06/06 XMLのAPI定義小文字、大文字区別されない対応 BEGIN
        if (apiField.containsIgnoreCase(RELATION_KEY)) {
            // aaa__r.xxxx
            Integer startPt = apiField.indexOfIgnoreCase(RELATION_KEY) + RELATION_KEY.length();
            String refFieldNm = apiField.substring(startPt);
            // 一階層のSOBJECT名
            // ssss__r
            String refSobjNm = apiField.substringBefore('.');
            // 二階層のSOBJECT[aaa__r.xxxx]
            if (refFieldNm.containsIgnoreCase(RELATION_KEY)) {
                // 一階層のSOBJECT取得する[ssss__r]
                Sobject refSobj = s.getSObject(refSobjNm);
                if (refSobj == null) {
                    return null;
                }
                // 二階層の参照関係存在する場合、二階層以上は対応しません
                Integer twoStartPt = refFieldNm.indexOfIgnoreCase(RELATION_KEY) + RELATION_KEY.length();
                String twoRefFieldNm = refFieldNm.substring(twoStartPt);
                // Sobject Name [aaa__r]
                String twoRefSobjNm = refFieldNm.substringBefore('.');
                // Two Level Field
                Sobject twoRefSobj = refSobj.getSObject(twoRefSobjNm);
                // JSONに情報を書込する
                if (twoRefSobj == null) return null;
                else {
                    Object val = twoRefSobj.get(twoRefFieldNm);
                    return val;
                }
            } else {
                Sobject refSobj = s.getSObject(refSobjNm);
                if (refSobj == null) return null;
                else {
                    Object val = refSobj.get(refFieldNm);
                    return val;
                }
            }
        } else {
            Object val = s.get(apiField);
            return val;
        }
    }
    // 2018/02/22 摘要欄の出力内容はカスタマイズできるように改善対応 WGCH END
	// 2015/12/03  CSV出力の場合、勘定科目名を出力すると、後ろからN文字を削除して、出力機能の追加
	private String processFilter(String s) {
		if (gccInfo.filterKanjyoNmLastCharDelKey <= 0) return s;
		else {
			if (s.length() > gccInfo.filterKanjyoNmLastCharDelKey) return s.mid(0, s.length() - gccInfo.filterKanjyoNmLastCharDelKey);
			else return s;
		}
	}
	
	private string processEscapeKanji(String s) {
		return CommUtils.nullToBlank(s).escapeCsv();
	}
	/**
	* 店舗別CSV出力転換情報格納クラス
	**/
	public class ConvertXmlConfig {
		// 2015/11/13 Freeeの場合、レイアウト制御フラグ ADD
		public String CONST_LAYOUT_CODE{get{return '1';}}
		public Boolean isCodeLayout{get{return CommUtils.isBlank(layoutKbn) || layoutKbn == CONST_LAYOUT_CODE;}}
		
		public ConvertXmlConfig() {
			cashInputInMap = new Map<String, String>();
			cashInputOuMap = new Map<String, String>();
			cashOutputInMap = new Map<String, String>();
			cashOutputOuMap = new Map<String, String>();
			// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
			// 入金関連情報格納	
			cashInputInRateKbnMap = new Map<String, map<Decimal, String>>();
			cashInputOuRateKbnMap = new Map<String, map<Decimal, String>>();
			cashOutputInRateKbnMap = new Map<String, map<Decimal, String>>();
			cashOutputOuRateKbnMap = new Map<String, map<Decimal, String>>();
			// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
			mediaProductCdMap = new Map<String, AccountMaster__c>();
			mediaCardMap = new Map<String, String>();
			mediaKinkenMap = new Map<String, String>();
			// 2015/11/09 ADD
			purchaseInMap = new Map<String, String>();
			// 2015/12/10 仕入オブジェクトの種別の貸方の勘定科目指定できる様に機能対応 BEGIN
			purchaseOutOfTypeMap = new map<String, String>();
			// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応 WSQ BEGIN
			// map<消費税率、勘定科目コード>
			purchaseInRateKbnMap = new Map<String, map<Decimal, String>>();
			purchaseOutOfTypeRateKbnMap = new Map<String, map<Decimal, String>>();
			// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応 WSQ END
			// 2015/12/10 仕入オブジェクトの種別の貸方の勘定科目指定できる様に機能対応 END
			// 2016/07/26 仕入オブジェクトの種別の貸方の勘定科目の税区分指定できるように対応 BEGIN
			purchaseInTaxKbnMap = new Map<String, String>();
			purchaseOutTaxKbnMap = new Map<String, String>();
			// 2016/07/26 仕入オブジェクトの種別の貸方の勘定科目の税区分指定できるように対応 END
			purchaseOutMap= new Map<String, String>();
			// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応 WSQ BEGIN
			// P_KAMOKUのCONVERTー＞KANJOCODEー＞RATE定義の場合、該当消費税関連の勘定科目
			// Map<P_KAMOKUー＞CONVERTー＞TYPENAME, map<消費税, 勘定科目コード>
			purchaseOutRateKbnMap = new Map<String, map<Decimal, String>>();
			// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応 WSQ END
			// 2015/11/13 ADD
			layoutKbn = CONST_LAYOUT_CODE;
			// 2015/12/03
			filterKanjyoNmLastCharDelKey = 0;
			// 2015/12/04
			taxKbnConfigMap = new map<String, TaxKbnInfo>();
			isOutputUtiwake = false;
			cardTesuryoTrueOnly = false;
			isOutputPriceZero = false;
			// 2016/09/23 仕訳Rollup機能追加対応 BEGIN
			isOutputRollUp = true;
			isOutputRollUpPur = false;
			// 2016/09/23 仕訳Rollup機能追加対応 END
			// 販売手数料は内訳として、出力機能の対応 BEGIN
			agtTesuryoTrueOnly = false;
			agtMediaTypeSet = new set<String>();
			// 販売手数料は内訳として、出力機能の対応 END
			// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
			pointProcess = true;
			// 2016/11/21 出力金額の小数点対応できる改善 END
			// 2018/10/23 FREEERU出力機能改善(補助科目の出力) BEGIN
			rollupSubKamokuFlg = false;
			// 2018/10/23 FREEERU出力機能改善(補助科目の出力) END
			// 2018/11/05 仕訳明細は税込・税抜出力選択できるように改善対応 WSQ BEGIN
			isIncTaxFlg = false;//明細は税込み・税抜き出力切り替えフラグ
			// 2018/11/05 仕訳明細は税込・税抜出力選択できるように改善対応 WSQ END
			// 2018/11/26 FREEE/FREEERU出力機能、入出金科目、仕入種別科目のまま明細出力できるように改善対応 WSQ BEGIN
			isCashInputOuByKamoku = false;
			isCashOutputOuByKamoku = false;
			isPurchaseOuByKamoku = false;
			// 2018/11/26 FREEE/FREEERU出力機能、入出金科目、仕入種別科目のまま明細出力できるように改善対応 WSQ END
			// 2019/05/15 現金入出の「取引先」項目追加 BY zyz BEGIN
			isCashInputAccount = false;
			isCashOutputAccount = false;
			// 2019/05/15 現金入出の「取引先」項目追加 BY zyz END
			// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
			isOutTaxToSameLine = false;
			// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
			// 2020/01/21 freee連携時、連泊の支払を入れた際の挙動修正 WSQ BEGIN
			isUseDayOutMode = false;
			// 2020/01/21 freee連携時、連泊の支払を入れた際の挙動修正 WSQ END
		}
		// 店鋪コード
		public String shopCode{get;set;}
		// 2015/11/13 Freee連携レイアウト切替できる制御フラグ
		public String layoutKbn{get;set;}
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
		// 2015/12/07 FREEE借税区分情報格納
		public String notaxkbn{get;set;}
		// TAX
		public String taxKanjoCode{get;set;}
		// 2016/03/10 借方の仮払消費税の会計科目出力機能の追加 BEGIN
		public String taxPayKanjoCode{get;set;}
		// 2016/03/10 借方の仮払消費税の会計科目出力機能の追加 END
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
		// 入金PCA連携用定義情報格納
		public Map<String, String> cashInputInMap{get;set;}
		public Map<String, String> cashInputOuMap{get;set;}
		// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
		public Map<String, map<Decimal, String>> cashInputInRateKbnMap{get;set;}
		public Map<String, map<Decimal, String>> cashInputOuRateKbnMap{get;set;}
		// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
		// 出金PCA連携用定義情報格納
		public Map<String, String> cashOutputInMap{get;set;}
		public Map<String, String> cashOutputOuMap{get;set;}
		// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
		public Map<String, map<Decimal, String>> cashOutputInRateKbnMap{get;set;}
		public Map<String, map<Decimal, String>> cashOutputOuRateKbnMap{get;set;}
		// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
		// 支払メディアにより、支払商品を紐付けない場合、対応の会計商品コード情報可能
		public Map<String, AccountMaster__c> mediaProductCdMap{get;set;}
		// カード種別と金券種別
		public Map<String, String> mediaCardMap{get;set;}
		public Map<String, String> mediaKinkenMap{get;set;}
		// 2015/11/09 仕入種別・科目のマッピング情報の格納
		public Map<String, String> purchaseInMap{get;set;}
		// 2015/12/10 仕入オブジェクトの種別の貸方の勘定科目指定できる様に機能対応 BEGIN
		// 仕入の種別に関連の貸方側の勘定科目情報の格納、種別の勘定科目情報を指定すると、仕入の科目の選択値は無視する、直接種別に定義した貸方の勘定科目情報を出力する
		public Map<String, String> purchaseOutOfTypeMap{get;set;}	
		// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応 WSQ BEGIN
		public Map<String, map<Decimal, String>> purchaseInRateKbnMap{get;set;}
		public Map<String, map<Decimal, String>> purchaseOutOfTypeRateKbnMap{get;set;}
		// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応 WSQ END
		// 2015/12/10 仕入オブジェクトの種別の貸方の勘定科目指定できる様に機能対応 END
		// 2016/07/26 仕入オブジェクトの種別の貸方の勘定科目の税区分指定できるように対応 BEGIN
		public Map<String, String> purchaseInTaxKbnMap{get; private set;}
		public Map<String, String> purchaseOutTaxKbnMap{get; private set;}
		// 2016/07/26 仕入オブジェクトの種別の貸方の勘定科目の税区分指定できるように対応 END
		public Map<String, String> purchaseOutMap{get;set;}
		// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応 WSQ BEGIN
		public Map<String, map<Decimal, String>> purchaseOutRateKbnMap{get;set;}
		// 2019/11/22 仕入明細消費税率により会計科目切り替え機能対応 WSQ END
		// 2015/12/03  CSV出力の場合、勘定科目名を出力すると、後ろからN文字を削除して、出力機能の追加
		public Integer filterKanjyoNmLastCharDelKey{get; set;}
		// 2015/12/04 勘定科目税区分個別対応の勘定科目情報を格納
		public Map<String, TaxKbnInfo> taxKbnConfigMap{get;set;}
		// 2015/12/04 カード手数料出力するがどうか制御フラグを取得する
		public Boolean isOutputUtiwake{get; set;}
		// 2016/03/14 カード手数料/販売手数料は内訳出力場合、手数料の「手数料支払」TRUEが必要がどうか制御
		public Boolean cardTesuryoTrueOnly{get;set;}	//
		public String cardTesuryoSeqNo{get; set;}		// 借方勘定科目SEQ
		public String cardTesuryoRightSeqNo{get; set;}	// 貸方勘定科目SEQ
		public String cardTesuryoTaxKbn{get;set;}		// 借方税区分
		public String cardTesuryoRightTaxKbn{get;set;}	// 貸方税区分
		// 2016/03/08 販売手数料は内訳として、出力機能の対応 BEGIN
		public Boolean agtTesuryoTrueOnly{get;set;}		// 
		public String agtTesuryoSeqNo{get;set;}			// 借方勘定科目SEQ
		public String agtTesuryoRightSeqNo{get;set;}	// 貸方勘定科目SEQ
		public String agtTesuryoTaxKbn{get;set;}		// 借方税区分
		public String agtTesuryoRightTaxKbn{get;set;}	// 貸方税区分
		public Set<String> agtMediaTypeSet{get;set;}
		// 2016/03/08 販売手数料は内訳として、出力機能の対応 END
		// 2015/12/04 会計明細は０の場合、出力する・なし制御フラグ
		public Boolean isOutputPriceZero{get; set;}
		// 2016/09/23 仕訳Rollup機能追加対応 BEGIN
		public Boolean isOutputRollUp{get; set;}
		public Boolean isOutputRollUpPur{get; set;}
		// 2016/09/23 仕訳Rollup機能追加対応 END
		// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
		public boolean pointProcess{get;set;}
		// 2016/11/21 出力金額の小数点対応できる改善 END
		// 2018/10/23 FREEERU出力機能改善(補助科目の出力) BEGIN
		public Boolean rollupSubKamokuFlg{get;set;}
		// 2018/10/23 FREEERU出力機能改善(補助科目の出力) END
		// 2018/11/05 仕訳明細は税込・税抜出力選択できるように改善対応 WSQ BEGIN
		public Boolean isIncTaxFlg{get;set;}//明細は税込み・税抜き出力切り替えフラグ
		// 2018/11/05 仕訳明細は税込・税抜出力選択できるように改善対応 WSQ END
		// 2018/11/26 FREEE/FREEERU出力機能、入出金科目、仕入種別科目のまま明細出力できるように改善対応 WSQ BEGIN
		public Boolean isCashInputOuByKamoku{get;set;}// 入金明細出力の際に、画面に設定の科目でそのまま明細に出力を行う
		public Boolean isCashOutputOuByKamoku{get;set;}// 出金明細出力の際に、画面に設定の科目でそのまま明細に出力を行う
		public Boolean isPurchaseOuByKamoku{get;set;}// 仕入明細出力の際に、画面に設定の種別、科目でそのまま明細に出力を行う
		// 2018/11/26 FREEE/FREEERU出力機能、入出金科目、仕入種別科目のまま明細出力できるように改善対応 WSQ END
		// 2019/05/15 現金入出の「取引先」項目追加 BY zyz BEGIN
		public Boolean isCashInputAccount{get;set;}
		public Boolean isCashOutputAccount{get;set;}
		// 2019/05/15 現金入出の「取引先」項目追加 BY zyz END
		// 2019/09/20 多税率機能対応 WSQ BEGIN
		// 仕訳明細出力する際、消費税8%と10%に行が分ける出力する対応
		// 入出金消費税項目が存在場合、入出金消費税も出力する対応
		public map<decimal,string> taxKanjoMap = new map<decimal, string>();	// 仮受消費税
		public map<decimal,string> taxPayKanjoMap = new map<decimal, string>();	// 仮払消費税
		public map<decimal,string> serviceRkanjoMap = new map<decimal, string>();	// 仮払消費税
		// 2019/09/20 多税率機能対応 WSQ END
		// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ BEGIN
		public Boolean isOutTaxToSameLine{get;set;}//該当行目の税金は「」
		// 2019/11/01 税込出力の際、借方税額に”0”の設定値ではなく、その売上の税額を出力する WSQ END
		// 2020/01/21 freee連携時、連泊の支払を入れた際の挙動修正 WSQ BEGIN
		// 仕訳明細出力は利用日と合わせて出力する・しない切り替えフラグ（デフォルト：ON）
		public Boolean isUseDayOutMode{get;set;}
		public String apLeftKanjoSeqNo{get; set;}		// 借方勘定科目SEQ
		public String dpLeftKanjoSeqNo{get; set;}		// 借方勘定科目SEQ
		public String acKanjoSeqNo{get; set;}		// 貸方勘定科目SEQ
		// 2020/01/21 freee連携時、連泊の支払を入れた際の挙動修正 WSQ END
		// 2020/09/15 連泊の支払を入れた際の挙動修正2 WSQ BEGIN
		public String apRightKanjoSeqNo{get; set;}
		// 2020/09/15 連泊の支払を入れた際の挙動修正2 WSQ END
	}
	
	class TaxKbnInfo {
		public TaxKbnInfo (Dom.XmlNode taxKbnNode) {
			Dom.XmlNode kanjoCodeNode = taxKbnNode.getChildElement('KANJOCODE', null);
			if (kanjoCodeNode != null) kanjyoKamokuSeq = CommUtils.nullToBlank(kanjoCodeNode.getText());			
			Dom.XmlNode debTaxKbnNode = taxKbnNode.getChildElement('DEBTAXKBN', null);
			if (debTaxKbnNode != null) debTaxKbn = CommUtils.nullToBlank(debTaxKbnNode.getText());
			Dom.XmlNode creTaxKbnNode = taxKbnNode.getChildElement('CRETAXKBN', null);
			if (creTaxKbnNode != null) creTaxKbn = CommUtils.nullToBlank(creTaxKbnNode.getText());
		}
		public string kanjyoKamokuSeq{get; private set;}
		public string debTaxKbn{get;private set;}
		public string creTaxKbn{get;private set;}
	}
	// 2016/11/21 出力金額の小数点対応できる改善 BEGIN
	private Decimal formatOuputNumber(Decimal num) {
		Boolean isPointProcessType = gccInfo.pointProcess;
		Decimal locNum = 0;
		if (!isPointProcessType) {
			locNum = num.intValue();
		} else {
			locNum = CommUtils.RoundProcess(num, gPointLen);
			if (gPointLen == 0) locNum = locNum.intValue();
		}
		return locNum;
	}
	// 2016/11/21 出力金額の小数点対応できる改善 END
	// 2017/03/09 バッチ終了通知メールに支払いメディアが設定されていない、設定金額は合せないの会計データへのリンクを追加 BEGIN
	private void warningCheck(Decimal leftAmount, Decimal rightAmount, Integer startNo, Id accId) {
		if (leftAmount != rightAmount) {
			msgStr += Label.CONST_046_0031 +'【'+startNo+'】'+ Label.CONST_046_0032 +'(https://login.salesforce.com/'+accId+')\n';
		}
	}
	// 2017/03/09 バッチ終了通知メールに支払いメディアが設定されていない、設定金額は合せないの会計データへのリンクを追加 END
	
    // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 BEGIN
    // サビース料出力する・しないフラグ
    private Boolean isOutServiceFlg = false;
    // 指定の会計明細情報により、サビース料は個別出力の場合、税抜き（サビース料抜き、
    // ret[0]:本体金額
    // ret[1]:サビース料金額
    // ret[2]:サビース料税金
    private List<Decimal> calServiceAmount(Decimal pGoukeinoneTax, Tran1__c tran) {
        List<Decimal> ret = new List<Decimal>{pGoukeinoneTax,0,0};
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
        // 2018/11/05 仕訳明細は税込・税抜出力選択できるように改善対応 WSQ BEGIN
        if (gccInfo.isIncTaxFlg) serviceNoTax = priceInfo.priceService;
        // 2018/11/05 仕訳明細は税込・税抜出力選択できるように改善対応 WSQ END
System.debug(loggingLevel.info, 'priceInfo='+priceInfo);
        if (pGoukeinoneTax > serviceNoTax) {
            ret[0] = pGoukeinoneTax - serviceNoTax;
            ret[1] = serviceNoTax;
	    // 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ BEGIN
	    // サビース料の消費税が出力必要場合 #9199
            // 同じ行目に料金＆税金別々出力場合
            if (!gccInfo.isIncTaxFlg && gccInfo.isOutTaxToSameLine) {
            	ret[2] = priceInfo.priceService - priceInfo.priceServiceExcTax;
            }
	    // 2020/09/15 連泊の支払を入れた際の挙動修正2（1支払明細は2行明細 (売掛金、前受金)分けて出力できること）WSQ END
        }
        return ret;
    }
    // 2017/08/03 サビース料金額は個別行に出力できるように改善対応 END
	// 2019/09/20 多税率機能対応 WSQ BEGIN
	private static decimal formattax(decimal tax) {
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
	// 2019/09/20 多税率機能対応 WSQ END
}