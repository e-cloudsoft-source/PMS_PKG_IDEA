/*****************
* POS取込連携処理
* 会計関連の詳細情報を取込（会計、会計支払、会計明細）
* 2016/01/15 INIT
* 2016/02/15 POSNo登録対応
* 2016/04/20 親メニュー下に所属の明細も会計明細に取り込みする
* 2016/05/04 CSV先頭明細処理追加する
* 2019/10/08 軽減税率の会計明細の消費税とサビース料を自動設定を外すため、消費税自動設定追加対応
******************/
public with sharing class PosSyncCsvTemplateCtrl {

	private final String gPostNo = '0010';				// POSの端末NO
	private Date gSalesDate = null;						// 営業日付
	// 登録済の会計情報を格納する
	private map<String, AccountAcount__c> gAccNoMap;
	// 取引種別
	public static final String ACC_TRADE_BEGIN = '01';   // 開局
	// DP情報
	private final map<string,DP__c> dpMstMap;
	// GP情報
	private final map<string,GP__c> gpMstMap;
	// 会計商品コード<処理対象配列IDX,商品コード>
	private map<integer,string> accProdCodeMap;
	// 部屋情報<処理対象配列IDX,ターブルNo>
	private map<integer,string> roomcodeMap;	
	// インスタンス化
	public PosSyncCsvTemplateCtrl() {
		// DPマスタ情報を格納する
		dpMstMap = new map<string,DP__c>();
		// GPマスタ情報を格納する
		gpMstMap = new map<string,GP__c>();
		for (DP__c dp : [select id, Field1__c from DP__c where IsClosed__c != true]) {
			dpMstMap.put(dp.Field1__c, dp);
		}
		for (GP__c gp : [select id, Field1__c from GP__c where IsClosed__c != true]) {
			gpMstMap.put(gp.Field1__c, gp);
		}
		accProdCodeMap = new map<integer, string>();
		roomcodeMap = new map<integer, string>();
	}

	/**
	* 会計基本情報の登録（CSVから）
	**/
	public map<String, AccountAcount__c> generalAccount(String csv) {
		// 2018/03/07 Security Check BEGIN
		List<String> insChkFields = new List<String>{'frs__c','Relreserve__c','relaccount__c','Field150__c','Field68__c',
													'Field67__c','Field66__c','Field65__c','Field64__c','Field63__c','Field62__c',
													'field61__c','field60__c','Field59__c','Field58__c','Field57__c','Field56__c',
													'Field55__c','Field54__c','Field53__c','Field52__c','Field51__c','Field50__c',
													'Field49__c','Field48__c','Field45__c','Field44__c','Field43__c','Field42__c',
													'Field40__c','Field39__c','Field93__c','Field92__c','Field91__c','Field90__c',
													'Field89__c','Field88__c','Field87__c','Field86__c','Field85__c','Field84__c',
													'Field83__c','Field82__c','Field81__c','Field145__c','Field98__c','Field97__c',
													'Field96__c','Field95__c','Field139__c','Field138__c','Field137__c','Field136__c',
													'Field135__c','Field134__c','Field133__c','Field132__c','Field131__c','Field130__c',
													'Field129__c','Field128__c','Field127__c','Field126__c','Field125__c','Field124__c',
													'Field123__c','Field122__c','Field121__c','Field120__c','Field119__c','Field118__c',
													'Field117__c','Field116__c','Field115__c','Field114__c','Field113__c','Field112__c',
													'Field111__c','Field110__c','Field109__c','Field108__c','Field107__c','Field106__c',
													'Field105__c','Field104__c','Field103__c','Field102__c','Field101__c','Field100__c',
													'Field80__c','Field79__c','Field78__c','Field77__c','Field76__c','Field75__c',
													'Field74__c','Field7__c','Field73__c','Field72__c','Field71__c','Field70__c',
													'Field69__c','Field94__c','Field99__c'};// ,'frs__r'  
		Map<String,Schema.SObjectField> insm = Schema.SObjectType.AccountAcount__c.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(insChkFields, insm)) {
			return null;
		}
		// 2018/03/07 Security Check END
		// 部屋情報取得用変数をクリアする
		roomcodeMap.clear();
		// 会計情報格納用変数を初期化する
		List<AccountAcount__c> accLst = new List<AccountAcount__c>();
// 2016/05/04 CSV先頭明細処理追加する BEGIN
		//for (String csvLine : csv.split('\n')) {
		String[] csvLines = csv.split('\n');
		for (integer i =0; i < csvLines.size(); i++) {
			if (isHeader(i)) continue;
			//AccountAcount__c acc = parseCsvToAccountAct(csvLine,accLst.size());
			AccountAcount__c acc = parseCsvToAccountAct(csvLines[i],accLst.size());
// 2016/05/04 CSV先頭明細処理追加する END
			if (acc == null) continue;
			accLst.add(acc);
		}
		if (accLst.isEmpty()) return null;
		// 会計の営業日付を設定する
		if (gSalesDate == null && accLst.size()>0) {
			gSalesDate = dateTimeConTool(accLst[0].Field53__c).date();
		}
		// レシートNo単位の会計情報を格納する
		map<String, AccountAcount__c> rsAccNoMap = new map<String, AccountAcount__c>();
		for (AccountAcount__c acc  : accLst) {
			rsAccNoMap.put(acc.Field145__c, acc);
		}

		// 会計VOIDの相殺処理を行う
		list<AccountAcount__c> voidAccLst = new list<AccountAcount__c>();
		// VOID相殺の会計情報は今回処理の会計情報範囲外の場合、該当会計情報を格納して、
		for (Integer i=0; i < accLst.size(); i++) {
			// 該当会計はVOID情報の場合、関連の会計情報をVOIDを設定する、該当VOID情報はそのまま、VOIDされる会計の処理種別は「３０」に設定する
			AccountAcount__c acc = accLst[i];
			// 取引種別はVOIDの場合
			if (acc.Field39__c == CommConst.ACC_TRADE_VOID) {
				// 今回処理範囲内のVOID情報、ＶＯＩＤレシートＮｏ．情報から既存の会計はVOID設定する
				String orgVoidNo = acc.Field40__c;
				// 範囲内の会計情報を取得する
				if (rsAccNoMap.containsKey(orgVoidNo)) {
					AccountAcount__c voidAcc = rsAccNoMap.get(orgVoidNo);
					// VOID処理先のVOIDレシートNo＝VOID会計のレシートNo
					if (voidAcc.Field40__c == acc.Field145__c) {
						// 該当VOID先はVOID処理を行う
						voidAcc.Field39__c = CommConst.ACC_TRADE_VOID;
						// 次の処理を行う
						continue;
					}
				}
			}
			voidAccLst.add(acc);
		}
		/*
		// 該当範囲内の関連会計情報が無ければ、該当売上日から前日の会計情報を取得する
		if (!voidAccLst.isEmpty()) {
			set<String> targetAccNoSet = new set<String>();
			set<String> orgVoidAccNoSet = new set<String>();
			//map<String,AccountAcount__c> voidAccMqp = new map<String, AccountAcount__c>();
			for (AccountAcount__c voidAcc : voidAccLst) {
				// ＶＯＩＤレシートＮｏ．
				targetAccNoSet.add(voidAcc.Field40__c);
				// レシートＮｏ．
				orgVoidAccNoSet.add(voidAcc.Field145__c);
			}
			Date startDt = gSalesDate.addMonths(-3);
			String strStartDt = (DateTime.newInstance(startDt.year(),startDt.month(),startDt.day())).format('yyyyMMdd');
			String strEndDt = (DateTime.newInstance(gSalesDate.year(),gSalesDate.month(),gSalesDate.day())).format('yyyyMMdd');
			// 関連の会計情報を取得する
			List<AccountAcount__c> relAccLst = [select id, Field40__c, Field145__c from AccountAcount__c 
						where frs__r.Name <= :strEndDt And frs__r.Name >= :strStartDt
						And Field145__c != null And Field40__c != null
						And Field39__c = :CommConst.ACC_TRADE_NORMAL
						And Field40__c in :orgVoidAccNoSet And Field145__c in :targetAccNoSet Order By frs__r.Name  desc];
			map<string,list<AccountAcount__c>> existVoidTargetMap = new map<string, list<AccountAcount__c>>();
			for (AccountAcount__c acc : relAccLst) {
				String accNo = acc.Field145__c;
				if (!existVoidTargetMap.containsKey(accNo)) existVoidTargetMap.put(accNo, new list<AccountAcount__c>());
				existVoidTargetMap.get(accNo).add(acc);
			}
			
			list<AccountAcount__c> voidUpdAccLst = new list<AccountAcount__c>();
			for (AccountAcount__c voidAcc : voidAccLst) {
				String voidNo = voidAcc.Field40__c;
				if (existVoidTargetMap.containsKey(voidNo)) {
					list<AccountAcount__c> targetLst = existVoidTargetMap.get(voidNo);
					for (AccountAcount__c targetAcc : targetLst) {
						
						if (targetAcc.Field39__c != CommConst.ACC_TRADE_NORMAL) continue;
						//
						if (targetAcc.Field40__c == voidAcc.Field145__c) {
							// 相殺会計情報を記録する
							targetAcc.Field39__c = CommConst.ACC_TRADE_VOID;
							voidUpdAccLst.add(targetAcc);
						}
					}
				}
			}
			if (!voidUpdAccLst.isEmpty()) update voidUpdAccLst;
		}*/
		
		// 既存の売上情報を取得する
		RsvAccount__c rsv = CommLogicProcess.getRsvAccountInf(gSalesDate);

		// 部屋情報
		map<string,Room__c> roomMstMap = queryRoom(new set<string>(roomcodeMap.values()));
		set<id> roomIdsSet = new set<id>();
		for (Room__c room : roomMstMap.values()) {
			roomIdsSet.add(room.id);
		}
		map<id, list<Lead__c>> leadGroupMap = new map<id, list<Lead__c>>();
		// 部屋情報あり、到着日により、予約情報をリンク処理を行う
		for (Lead__c lead : [select id,Rroom__c,Relcontact__c from Lead__c 
								where DAY_ONLY(convertTimezone(EntryTime__c)) = :gSalesDate And Rroom__c in :roomIdsSet
								order by Rroom__c]) {
			id roomid = lead.Rroom__c;
			if (!leadGroupMap.containsKey(roomid)) leadGroupMap.put(roomid, new list<lead__c>());
			leadGroupMap.get(roomid).add(lead);
		}
		for (Integer i=0; i < accLst.size(); i++) {
			// 会計に売上参照設定
			accLst[i].frs__c = rsv.Id;
			accLst[i].frs__r = rsv;
			// 部屋参照設定
			if (roomcodeMap.containsKey(i)) {
				string roomcode = roomcodeMap.get(i);
				if (roomMstMap.containsKey(roomcode)) {
					accLst[i].Field150__c = roomMstMap.get(roomcode).Id;
					// 該当会計に関連の予約情報が存在する場合
					id roomId = accLst[i].Field150__c;
					if (leadGroupMap.containsKey(roomId)) {
						lead__c lead = leadGroupMap.get(roomId)[0];
						accLst[i].Relreserve__c = lead.Id;
						accLst[i].relaccount__c = lead.Relcontact__c;
					}
				}
			}
		}
		// 2017/05/04 店舗ごとの予約・会計権限機能対応 BEGIN
		CommLogicProcess logic = new CommLogicProcess();
		// 新規登録・変更対象データはチェック対象外に設定する
		logic.preventShopAuthCheckSetup(accLst);
		// 2017/05/04 店舗ごとの予約・会計権限機能対応 END
		// 会計情報の新規登録 
		insert accLst;
		// 登録済の会計情報を戻る
		return rsAccNoMap;
	}
	/**
	* 会計支払情報登録（CSVから）
	**/
	public void generalTtend(String csv, map<String, AccountAcount__c> rsAccNoMap) {
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> insChkFields = new List<String>{'UseDate__c','POSNo__c','Field9__c','Field7__c','Field6__c','Field5__c',
													'Field4__c','Field27__c','Field25__c','Field24__c','Field23__c','Field22__c',
													'Field21__c','Field20__c','Field19__c','Field18__c','Field17__c','Field16__c',
													'Field15__c','Field14__c','Field10__c','Field8__c','CouponTypeLst__c','Field2__c',
													'RelAccount__c','Field1__c','Field3__c','noneaccount__c','invoicenoshowflg__c','field38__c',
													'field37__c','field36__c','field35__c','field34__c','field33__c','field32__c','field31__c',
													'field30__c','field29__c','field28__c','field26__c','field13__c','field12__c','field11__c'};
		Map<String,Schema.SObjectField> insm = Schema.SObjectType.TTend__c.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(insChkFields, insm)) {
			return;
		}
		// 2019/09/15 Security Check BY zyz END
		List<TTend__c> ttendLst = new List<TTend__c>();
		gAccNoMap = rsAccNoMap;
		// 支払メデイア情報の初期化する
		BillSimpleHelp help = new BillSimpleHelp('');
		Map<String, AccountMaster__c> MEDIA_PRODUCTCD_MAP = help.getMediaLabToAccMstMap();
		
		// CSV情報の分析	
// 2016/05/04 CSV先頭明細処理追加する BEGIN
		//for (String csvLine : csv.split('\n')) {
		String[] csvLines = csv.split('\n');
		for (integer i =0; i < csvLines.size(); i++) {
			if (isHeader(i)) continue;
			//TTend__c ttend = parseCsvToTtend(csvLine,ttendLst.size());
			TTend__c ttend = parseCsvToTtend(csvLines[i],ttendLst.size());
// 2016/05/04 CSV先頭明細処理追加する END
			if (ttend == null) continue;
			ttendLst.add(ttend);
		}
		for (TTend__c ttend : ttendLst) {
			// Medialラベルにより、支払商品リンクを設定する
			String mediaNm = ttend.Field3__c;
			AccountMaster__c accMst = MEDIA_PRODUCTCD_MAP.get(mediaNm);
			if (accMst == null) accMst= new AccountMaster__c(Name = mediaNm);
			ttend.PayProductRef__c = accMst.Id;
			ttend.PayProductName__c = accMst.Name;
			ttend.PaymentType__c = accMst.PaymentType__c;
			//System.debug(loggingLevel.INFO, 'INSERT::' + ttend);
			Decimal chargePrice = CommUtils.nullToZero(ttend.Field21__c);
			if (chargePrice != 0) {
				ttend.Field19__c = ttend.Field20__c;    //預かり　金額
				ttend.Field21__c = '0';    				//釣銭（差額）金額
			}
		}
		insert ttendLst;
	}
	/**
	* 会計明細情報登録（CSVから）
	**/
	public void generalTrand(String csv, map<String, AccountAcount__c> rsAccNoMap) {
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'field7__c','field6__c','usedate__c','noneaccount__c','posno__c','invoicenoshowflg__c','field9__c','field8__c',
													'field5__c','field4__c','field3__c','field38__c','field37__c','field36__c','field35__c','field34__c','field33__c',
													'field32__c','field31__c','field30__c','field2__c','field29__c','field28__c','field27__c','field26__c','field25__c',
													'field24__c','field23__c','field22__c','field21__c','field20__c','field1__c','field19__c','field18__c','field17__c',
													'field16__c','field15__c','field14__c','field13__c','field12__c','field11__c','field10__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.Tran1__c.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(chkFieldsLst, mm)) {
			return ;
		}
		// 2019/09/15 Security Check BY zyz END
		// 会計商品と部屋情報を格納する
		accProdCodeMap.clear();
		roomcodeMap.clear();
		
		List<Tran1__c> trandLst = new List<Tran1__c>();
		gAccNoMap = rsAccNoMap;
		// 会計明細情報の分析
// 2016/05/04 CSV先頭明細処理追加する BEGIN
		//for (String csvLine : csv.split('\n')) {
		String[] csvLines = csv.split('\n');
		for (integer i =0; i < csvLines.size(); i++) {
			if (isHeader(i)) continue;
			//Tran1__c trand = parseCsvToTrand(csvLine,trandLst.size());
			Tran1__c trand = parseCsvToTrand(csvLines[i],trandLst.size());
// 2016/05/04 CSV先頭明細処理追加する END
			if (trand == null) continue;
			trandLst.add(trand);
		}
		List<Tran1__c> insertTranLst = new list<Tran1__c>();
		// テーブルNoのリンク
		if (!roomcodeMap.isEmpty()) {
			map<string,Room__c> roomMstMap = queryRoom(new set<string>(roomcodeMap.values()));
			for (integer idx : roomcodeMap.keySet()) {
				string roomcode = roomcodeMap.get(idx);
				if (roomMstMap.containsKey(roomcode)) {
					trandLst[idx].Field6__c = roomMstMap.get(roomcode).Id;
				}
			}
		}
		// 会計商品の登録
		if (!accProdCodeMap.isEmpty()) {
			// 単価定義区分の計算用
			CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo();
			map<string,AccountMaster__c> accMstMap = queryAccountMaster(new set<string>(accProdCodeMap.values()));
			for (Integer idx : accProdCodeMap.keySet()) {
				String accProdCode = accProdCodeMap.get(idx);
				if (accMstMap.containsKey(accProdCode)) {
					// 会計商品
					AccountMaster__c locAccMst = accMstMap.get(accProdCode);
					trandLst[idx].Field7__c = locAccMst.Id;
					// 2019/10/08 軽減税率の会計明細の消費税とサビース料を自動設定を外すため、消費税自動設定追加対応 WSQ BEGIN
					if (trandLst[idx].TaxRate__c == null) trandLst[idx].TaxRate__c = locAccMst.TaxRateCal__c;
					if (trandLst[idx].ServiceRate__c == null) trandLst[idx].ServiceRate__c = locAccMst.ServiceRate__c;
					// 2019/10/08 軽減税率の会計明細の消費税とサビース料を自動設定を外すため、消費税自動設定追加対応 WSQ END
					// 数量と残数量は違うの場合、残数量により、合計金額を再計算を行う　
					Decimal unitPrice = CommUtils.nullToZero(trandLst[idx].Field20__c);
					Decimal qtys = CommUtils.nullToZero(trandLst[idx].Field21__c);
					Decimal remaindNum = CommUtils.nullToZero(trandLst[idx].Field22__c);
					if (qtys != remaindNum) {
						priceInfo.process(unitPrice, remaindNum , locAccMst.TaxRateCal__c, locAccMst.ServiceRate__c);
						// 数量と合計金額を再設定する
						trandLst[idx].Field21__c = CommUtils.nullToBlank(remaindNum);
						trandLst[idx].Field23__c = CommUtils.nullToBlank(priceInfo.priceIncTax);
					}
					insertTranLst.add(trandLst[idx]);
					
				}
			}
		}
		if (!insertTranLst.isEmpty()) insert insertTranLst;
	}

	// CSVファイルは会計支払情報を格納する
	private TTend__c parseCsvToTtend(String csv, Integer idx) {
		String[] csvArr = csv.split(',');
		// レシートNoチェック
		String sheetNo = processTxtField(csvArr[0]);
		if(!gAccNoMap.containsKey(sheetNo)) return null;
		// 処理種別２は「通常」以外の場合、処理中止
		String processType2 = processTxtField(csvArr[4]);
		if (processType2 != '1') return null;
		// 初期化
		TTend__c tted   = new TTend__c(RelAccount__c = gAccNoMap.get(sheetNo).frs__c);

		String mediaCode = processTxtField(csvArr[1]);    //メディア種別
		String orgMediaLabel = processTxtField(csvArr[2]);//メディア名称
		String mediaLabe = CommConst.getPaymentTypeLabelByKey(mediaCode); //メディア名称
		// 支払Mediaは処理対象外の場合、

		tted.Field1__c  = gAccNoMap.get(sheetNo).Id;    //レシートＮｏ．（参照）
		tted.Field2__c  = mediaCode;    //メディア種別
		tted.Field3__c  = mediaLabe;    //メディア名称
		if (CommUtils.isBLank(tted.Field3__c)) tted.Field3__c = orgMediaLabel;
		tted.Field4__c  = processTxtField(csvArr[3]);    //処理　種別１
		tted.Field5__c  = processType2;    				 //処理　種別２
		tted.Field6__c  = processTxtField(csvArr[5]);    //明細　種別
		tted.Field7__c  = processTxtField(csvArr[6]);    //券種コード
		tted.Field8__c  = processTxtField(csvArr[7]);    //券名称
		tted.Field9__c  = processTxtField(csvArr[8]);    //発行店番
		tted.Field10__c = processTxtField(csvArr[9]);    //値引／割引種別
		tted.Field27__c = queryDp(csvArr[10]);    		 //対象ＤＰコード（参照）

		tted.Field14__c = processTxtField(csvArr[13]);    //値引／割引ステータス
		tted.Field15__c = processTxtField(csvArr[14]);    //値割引対象額
		tted.Field16__c = processNumField(csvArr[15]);    //単価
		tted.Field17__c = processNumField(csvArr[16]);    //枚数
		tted.Field18__c = processNumField(csvArr[17]);    //残枚数
		tted.Field19__c = processNumField(csvArr[18]);    //預かり　金額
		tted.Field20__c = processNumField(csvArr[19]);    //支払　金額
		tted.Field21__c = processNumField(csvArr[20]);    //釣銭（差額）金額
		tted.Field22__c = processTxtField(csvArr[21]);    //釣銭（差額）種別
		tted.Field23__c = processTxtField(csvArr[22]);    //企業コード
		tted.Field24__c = processTxtField(csvArr[23]);    //有効期限
		tted.Field25__c = processNumField(csvArr[24]);    //メディア毎消費税額
		// tted.CardTypeLst__c    //カード種別
		// tted.RowNo__c    //RowNo.
		tted.CouponTypeLst__c = tted.Field8__c;    		//金券種別
		tted.UseDate__c = CommUtils.stringToDate(gAccNoMap.get(sheetNo).frs__r.Name);	// 利用日
		tted.POSNo__c   = gPostNo;
		return tted;

	}
	/**
	* 会計明細分析、登録を行う
	**/
	private Tran1__c parseCsvToTrand(String csv, Integer idx) {
		
		String[] csvArr = csv.split(',');
		// レシートＮｏ．
		String sheetNo = processTxtField(csvArr[0]);
		if(!gAccNoMap.containsKey(sheetNo)) return null;
// 2016/04/20 親メニュー下に所属の明細も会計明細に取り込みする BEGIN
		// 親メニューが存在すると、該当明細は取込対処外
//		String parentMenu = processTxtField(csvArr[9]);
//		if (!CommUtils.isBlank(parentMenu)) return null;
// 2016/04/20 親メニュー下に所属の明細も会計明細に取り込みする END
		//処理種別２:1(通常),2(取消),3(取消)
		String processType2 = processTxtField(csvArr[3]);
		if (processType2 != '1') return null;
		//残数量は０の場合、登録対象外になる
		String strRemainNum = processTxtField(csvArr[21]);
		Decimal remaindNum = CommUtils.nullToZero(strRemainNum);
		if (remaindNum == 0) return null;
		
		// 該当INS行明細の商品コード情報を格納
		String accProdCode = processTxtField(csvArr[4]);	// 商品コード（参照）
		String roomCode = processTxtField(csvArr[7]);		// テーブルＮｏ．
		accProdCodeMap.put(idx,accProdCode);
		roomcodeMap.put(idx,roomCode);

		Tran1__c tran   = new Tran1__c(RelAccount__c = gAccNoMap.get(sheetNo).frs__c);
		tran.Field1__c  = gAccNoMap.get(sheetNo).Id;    //レシートＮｏ．(参照)
		tran.Field2__c  = processTxtField(csvArr[1]);    //商品種別
		tran.Field3__c  = processTxtField(csvArr[2]);    //処理種別１
		tran.Field4__c  = processType2;    //処理種別２
		//tran.Field7__c  = queryAccountMaster(csvArr[4]);    //商品コード（参照）
		tran.Field5__c  = processTxtField(csvArr[5]);    //商品名称（または券名称）
		tran.Field8__c  = processTxtField(csvArr[6]);    //伝票Ｎｏ．
		//tran.Field6__c  = queryRoom(csvArr[7]);    //テーブルＮｏ．
		tran.Field9__c  = processTxtField(csvArr[8]);     //オーダー時刻
		tran.Field10__c = null;                           //親メニューコード
		tran.Field11__c = processTxtField(csvArr[10]);    //親メニュー名称
		tran.Field12__c = processTxtField(csvArr[11]);    //自社コード
		tran.Field13__c = processTxtField(csvArr[12]);    //売上集計リンクコード
		tran.Field14__c = processTxtField(csvArr[13]);    //テイクアウトフラグ
		tran.Field15__c = processTxtField(csvArr[14]);    //奉仕料２（深夜料）フラグ
		tran.Field16__c = processTxtField(csvArr[15]);    //ＳＴ１
		tran.Field17__c = processTxtField(csvArr[16]);    //ＳＴ２
		tran.Field18__c = processTxtField(csvArr[17]);    //ＳＴ３
		tran.Field19__c = processTxtField(csvArr[18]);    //ＳＴ４
		tran.Field20__c = processNumField(csvArr[19]);    //単価
		tran.Field21__c = processNumField(csvArr[20]);    //数量
		tran.Field22__c = strRemainNum;    //残数量
		tran.Field23__c = processNumField(csvArr[22]);    //合計金額
		tran.Field24__c = processNumField(csvArr[23]);    //原単価
		tran.Field25__c = queryDp(csvArr[24]);    //リンクＤＰコード（参照）
		tran.Field26__c = queryGp(csvArr[25]);    //リンクＧＰコード
		tran.Field27__c = processTxtField(csvArr[26]);    //消費税　種別
		tran.Field28__c = processTxtField(csvArr[27]);    //正負フラグ
		tran.Field29__c = processTxtField(csvArr[28]);    //発行店番
		tran.Field30__c = processTxtField(csvArr[29]);    //階層／指示ステータス位置
		tran.Field31__c = processTxtField(csvArr[30]);    //指示ステータスＮｏ．
		tran.Field32__c = processTxtField(csvArr[31]);    //コメントＮｏ．
		tran.Field33__c = processTxtField(csvArr[32]);    //値割引点数
		tran.Field34__c = processTxtField(csvArr[33]);    //値割引金額
		tran.Field35__c = processTxtField(csvArr[34]);    //プロモ出数
		tran.Field36__c = processTxtField(csvArr[35]);    //キャンセルリンクシリアルＮｏ．
		tran.Field37__c = processTxtField(csvArr[36]);    //リンク値割引明細支払番号
		tran.Field38__c = processTxtField(csvArr[37]);    //奉仕料１フラグ
		//if (csvArr.size() > 39) tran.Field49__c = processTxtField(csvArr[39]);   //コメント
		tran.UseDate__c = CommUtils.stringToDate(gAccNoMap.get(sheetNo).frs__r.Name);	// 利用日
		tran.POSNo__c   = gPostNo;
// 2016/04/20 親メニュー下に所属の明細も会計明細に取り込みする BEGIN
		String parentMenu = processTxtField(csvArr[9]);
		if (!CommUtils.isBlank(parentMenu)) {
			tran.InvoiceNoShowFlg__c = true;
			tran.noneaccount__c = true;	// 集計対象外設定する
		}
// 2016/04/20 親メニュー下に所属の明細も会計明細に取り込みする END
		return tran;
	}
	// 2016/05/04 CSV先頭明細処理追加する BEGIN
	private boolean isHeader(integer lineNum) {
		return (lineNum < 2);
	}
	// 2016/05/04 CSV先頭明細処理追加する END
	/**
	* CSVから会計情報オブジェクトに格納する
	**/
	private AccountAcount__c parseCsvToAccountAct(String csvLine, Integer idx) {
		String[] csvArr = csvLine.split(',');
		// 取引先種別は０「売上」、３０「VOID」、３１「VOID取消」個別処理を行う
		String accType = csvArr[1];
		if (accType != CommConst.ACC_TRADE_NORMAL && 
			accType != CommConst.ACC_TRADE_VOID && 
			accType != ACC_TRADE_BEGIN) return null;
		// 開局の場合、開局の日付を取得する
		if (accType == ACC_TRADE_BEGIN) {
			gSalesDate = CommUtils.stringToDate(processTxtField(csvArr[163]));
			return null;
		}

		String roomCode = processTxtField(csvArr[9]);		// テーブルＮｏ．
		roomcodeMap.put(idx, (roomCode));

		AccountAcount__c acc = new AccountAcount__c();
		acc.Field145__c      = processTxtField(csvArr[0]);    //レシートＮｏ．
		acc.Field39__c       = accType;    //取引種別
		acc.Field40__c       = processTxtField(csvArr[2]);    //ＶＯＩＤレシートＮｏ．
//		acc.Field146__c      = queryWorker(csvArr[3]);    //扱者Ｎｏ．（参照）
		acc.Field42__c       = CommUtils.nullToZero(csvArr[4].trim());    //担当者Ｎｏ．
		acc.Field43__c       = CommUtils.nullToZero(csvArr[5].trim());    //元扱者Ｎｏ．
		acc.Field44__c       = CommUtils.nullToZero(csvArr[6].trim());    //元担当者Ｎｏ．
		acc.Field45__c       = processTxtField(csvArr[7]);    //会計種別
		acc.Field7__c        = processTxtField(csvArr[8]);    //伝票Ｎｏ．
//		acc.Field150__c      = queryRoom(csvArr[9]);    //テーブルＮｏ．（参照）
		acc.Field48__c       = CommUtils.nullToZero(csvArr[10].trim());    //伝票枝番
		acc.Field49__c       = processTxtField(csvArr[11]);    //伝票一連Ｎｏ．
		acc.Field50__c       = processTxtField(csvArr[12]);    //新規オーダー時刻
		acc.Field51__c       = processTxtField(csvArr[13]);    //追加オーダー時刻
		acc.Field52__c       = processTxtField(csvArr[14]);    //料理提供時刻
		acc.Field53__c       = processTxtField(csvArr[15]);    //会計日時
		acc.Field54__c       = processTxtField(csvArr[16]);    //組数
		acc.Field55__c       = processTxtField(csvArr[17]);    //ＰＯＳ入力人数
		acc.Field56__c       = processTxtField(csvArr[18]);    //オーダー人数
		acc.Field57__c       = processTxtField(csvArr[19]);    //会計人数
		acc.Field58__c       = processTxtField(csvArr[20]);    //フリー１集計コード
		acc.Field59__c       = processTxtField(csvArr[21]);    //フリー１集計名称

		acc.Field60__c       = processTxtField(csvArr[26]);    //レストラン売上客数
		acc.Field61__c       = processTxtField(csvArr[27]);    //店頭売上客数
		acc.Field62__c       = processTxtField(csvArr[28]);    //売上高客数
		acc.Field63__c       = processTxtField(csvArr[29]);    //収入計客数
		acc.Field64__c       = processTxtField(csvArr[30]);    //お通し人数
		acc.Field65__c       = processTxtField(csvArr[31]);    //控え番号（任意情報１）

		acc.Field66__c       = processTxtField(csvArr[35]);    //客層１
		acc.Field67__c       = processTxtField(csvArr[36]);    //客層２
		acc.Field68__c       = processTxtField(csvArr[37]);    //客層３
		acc.Field69__c       = processTxtField(csvArr[38]);    //客層４
		acc.Field70__c       = processTxtField(csvArr[39]);    //客層５
		acc.Field71__c       = dateTimeConTool(csvArr[40]);    //ディッシュアップ時間帯開始時間
		acc.Field72__c       = dateTimeConTool(csvArr[41]);    //ディッシュアップ時間帯終了時間
		acc.Field73__c       = processTxtField(csvArr[42]);    //アイテム総点数
		acc.Field74__c       = processTxtField(csvArr[43]);    //店内飲食合計1（内税抜き）金額
		acc.Field75__c       = processTxtField(csvArr[44]);    //店内飲食合計1（内税抜き）点数
		acc.Field76__c       = processTxtField(csvArr[45]);    //店内飲食合計2（内税込み）金額
		acc.Field77__c       = processTxtField(csvArr[46]);    //店内飲食合計2（内税込み）点数
		acc.Field78__c       = processTxtField(csvArr[47]);    //店内飲食外税対象金額
		acc.Field79__c       = processTxtField(csvArr[48]);    //店内飲食外税対象点数
		acc.Field80__c       = processTxtField(csvArr[49]);    //店内飲食内税対象（内税抜き）金額
		acc.Field81__c       = processTxtField(csvArr[50]);    //店内飲食内税対象（内税抜き）点数
		acc.Field82__c       = processTxtField(csvArr[51]);    //店内飲食内税対象（内税込み）金額
		acc.Field83__c       = processTxtField(csvArr[52]);    //店内飲食内税対象（内税込み）点数
		acc.Field84__c       = processTxtField(csvArr[53]);    //店内飲食非課税対象金額
		acc.Field85__c       = processTxtField(csvArr[54]);    //店内飲食非課税対象点数
		acc.Field86__c       = processTxtField(csvArr[55]);    //テイクアウト合計1（内税抜き）金額
		acc.Field87__c       = processTxtField(csvArr[56]);    //テイクアウト合計1（内税抜き）点数
		acc.Field88__c       = processTxtField(csvArr[57]);    //テイクアウト合計2（内税込み）金額
		acc.Field89__c       = processTxtField(csvArr[58]);    //テイクアウト合計2（内税込み）点数
		acc.Field90__c       = processTxtField(csvArr[59]);    //テイクアウト外税対象金額
		acc.Field91__c       = processTxtField(csvArr[60]);    //テイクアウト外税対象点数
		acc.Field92__c       = processTxtField(csvArr[61]);    //テイクアウト内税対象（内税抜き）金額
		acc.Field93__c       = processTxtField(csvArr[62]);    //テイクアウト内税対象（内税抜き）点数
		acc.Field94__c       = processTxtField(csvArr[63]);    //テイクアウト内税対象（内税込み）金額
		acc.Field95__c       = processTxtField(csvArr[64]);    //テイクアウト内税対象（内税込み）点数
		acc.Field96__c       = processTxtField(csvArr[65]);    //テイクアウト非課税対象金額
		acc.Field97__c       = processTxtField(csvArr[66]);    //テイクアウト非課税対象点数
		acc.Field98__c       = processTxtField(csvArr[67]);    //レストラン売上合計1（内税抜き）金額
		acc.Field99__c       = processTxtField(csvArr[68]);    //レストラン売上合計1（内税抜き）点数
		acc.Field100__c      = processTxtField(csvArr[69]);    //レストラン売上合計2（内税込み）金額
		acc.Field101__c      = processTxtField(csvArr[70]);    //レストラン売上合計2（内税込み）点数
		acc.Field102__c      = processTxtField(csvArr[71]);    //レストラン売上外税対象金額
		acc.Field103__c      = processTxtField(csvArr[72]);    //レストラン売上外税対象点数
		acc.Field104__c      = processTxtField(csvArr[73]);    //レストラン売上内税対象（内税抜き）金額
		acc.Field105__c      = processTxtField(csvArr[74]);    //レストラン売上内税対象（内税抜き）点数
		acc.Field106__c      = processTxtField(csvArr[75]);    //レストラン売上内税対象（内税込み）金額
		acc.Field107__c      = processTxtField(csvArr[76]);    //レストラン売上内税対象（内税込み）点数
		acc.Field108__c      = processTxtField(csvArr[77]);    //レストラン売上非課税対象金額
		acc.Field109__c      = processTxtField(csvArr[78]);    //レストラン売上非課税対象点数

		acc.Field110__c      = processTxtField(csvArr[104]);    // 売上計1（内税抜き）金額
		acc.Field111__c      = processTxtField(csvArr[105]);    // 売上計1（内税抜き）点数
		acc.Field112__c      = processTxtField(csvArr[106]);    // 売上計2（内税込み）金額
		acc.Field113__c      = processTxtField(csvArr[107]);    // 売上計2（内税込み）点数
		acc.Field114__c      = processTxtField(csvArr[108]);    // 売上計3（内税抜き）金額
		acc.Field115__c      = processTxtField(csvArr[109]);    // 売上計3（内税抜き）点数
		acc.Field116__c      = processTxtField(csvArr[110]);    // 売上計4（内税込み）金額
		acc.Field117__c      = processTxtField(csvArr[111]);    // 売上計4（内税込み）点数

		acc.Field118__c      = processTxtField(csvArr[118]);    //金券販売合計　金額
		acc.Field119__c      = processTxtField(csvArr[119]);    //金券販売合計　回数
		acc.Field120__c      = processTxtField(csvArr[120]);    //金券販売合計　枚数
		acc.Field121__c      = processTxtField(csvArr[121]);    //消費税（外）
		acc.Field122__c      = processTxtField(csvArr[122]);    //消費税（内）
		acc.Field123__c      = processTxtField(csvArr[123]);    //消費税（外）対象額
		acc.Field124__c      = processTxtField(csvArr[124]);    //消費税（内）対象額
		acc.Field125__c      = processTxtField(csvArr[125]);    //消費税非課税対象額
		acc.Field126__c      = processTxtField(csvArr[126]);    //請求金額

		acc.Field127__c      = processTxtField(csvArr[129]);    //課税１　種別
		acc.Field128__c      = processTxtField(csvArr[130]);    //課税１　税率
		acc.Field129__c      = processTxtField(csvArr[131]);    //課税２　種別
		acc.Field130__c      = processTxtField(csvArr[132]);    //課税２　税率
		acc.Field131__c      = processTxtField(csvArr[133]);    //課税３　種別
		acc.Field132__c      = processTxtField(csvArr[134]);    //課税３　税率

		acc.Field133__c      = CommUtils.nullToZero(csvArr[152].trim());    //レシートＮｏ．（ＦＲＯＭ）
		acc.Field134__c      = CommUtils.nullToZero(csvArr[153].trim());    //レシートＮｏ．（ＴＯ）
		acc.Field135__c      = processTxtField(csvArr[154]);    //今回未精算　組数
		acc.Field136__c      = processTxtField(csvArr[155]);    //今回未精算　金額
		acc.Field137__c      = processTxtField(csvArr[156]);    //釣銭準備金
		acc.Field138__c      = processTxtField(csvArr[157]);    //シフト精算／日計精算回数
		acc.Field139__c      = processTxtField(csvArr[158]);    //今回精算日時

		acc.Field141__c      = processTxtField(csvArr[163]);    //営業日付
		acc.Field142__c      = processTxtField(csvArr[164]);    //明細数（商品／監査）
		acc.Field143__c      = processTxtField(csvArr[165]);    //明細数（支払）
		// acc.relaccount__c    = processTxtField(csvArr[166]);    //お客様（参照）

		acc.POSNo__c    	 = gPostNo;
		return acc;
	}
	// 文字列に変換
	private String processTxtField(String s) {
		return CommUtils.nullToBlank(s);
	}
	// 数字に変換
	private String processNumField(String s) {
		return CommUtils.nullToBlank(CommUtils.nullToZero(s));
	}
	private Datetime dateTimeConTool(String s) {
		Datetime dt;
		if (s.length() != 14) return null;
		dt = Datetime.newInstance(Integer.valueOf(s.substring(0,4)), Integer.valueOf(s.substring(4,6)), Integer.valueOf(s.substring(6,8)),
									Integer.valueOf(s.substring(8,10)), Integer.valueOf(s.substring(10,12)), Integer.valueOf(s.substring(12,14)));
		return dt;
	}

	// 部屋情報の取得
	private map<string,Room__c> queryRoom(set<string> roomset) {
		//List<Room__c> roomList = new List<Room__c>();
		map<string,Room__c> existRsMap = new map<string, Room__c>();
		for (Room__c room : [select Id, Name from Room__c where Name = :roomset]) {
			existRsMap.put(room.Name, room);
		}
		return existRsMap;
	}

	// 会計商品
	private map<string,AccountMaster__c> queryAccountMaster(set<String> prodCdSet) {
		map<string,AccountMaster__c> existRsMap = new map<string, AccountMaster__c>();
		for (AccountMaster__c accMst : [select Id, Field3__c,TaxRateCal__c,ServiceRate__c from AccountMaster__c where Field3__c = :prodCdSet]) {
			existRsMap.put(accMst.Field3__c, accMst);
		}
		return existRsMap;
	}
	// DPマスタ
	private String queryDp(String s) {
		if (dpMstMap.containsKey(s)) return dpMstMap.get(s).Id;
		else return null;
	}
	// GPマスタ
	private String queryGp(String s) {
		if (gpMstMap.containsKey(s)) return gpMstMap.get(s).Id;
		else return null;
	}
}