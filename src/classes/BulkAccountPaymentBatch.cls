public with sharing class BulkAccountPaymentBatch implements Database.Batchable<AccountAcount__c>, Database.Stateful{
	public BatchVariableInfo bItem; // 全局变量Item
	// 会計人數自動設定機能封印
	private static final Boolean AccounntStayPersonsAutoSetupFlg = CommDefine__c.getOrgDefaults().AccounntStayPersonsAutoSetupFlg__c == null ? false : CommDefine__c.getOrgDefaults().AccounntStayPersonsAutoSetupFlg__c;
	public BulkAccountPaymentBatch(BulkLeadCheckInBatch.BatchVariableInfo bItem){
		this.bItem = new BatchVariableInfo(bItem);
	} 
	// ***********************************
	// バッチ処理開始
	// ***********************************
	public Iterable<AccountAcount__c> start(Database.BatchableContext BC){
		List<AccountAcount__c> accAcountLst = new List<AccountAcount__c>();
		String whereDate = '';
		if(bItem.checkInDate != null) {
			// 該当日の売上存在がどうかチェックを行う
			DateTime wkDt = DateTime.newInstance(bItem.checkInDate.year(), bItem.checkInDate.month(), bItem.checkInDate.day());
			whereDate = wkDt.format('yyyyMMdd');
		}
		Id rsvAccId = null;
		List<RsvAccount__c> existRsvAccLst = [select id from RsvAccount__c where name = :whereDate limit 1 for update];
		// 同じ日付の会計情報を一括取得して、取得する会計情報は処理を行う
		if (existRsvAccLst.isEmpty()) return accAcountLst;
		rsvAccId = existRsvAccLst[0].Id;
		// 処理する会計データの消費税率>0の数値を取得する、全部の会計データの消費税率はNULLの場合、会計関連の会計明細から設定を行う
		Decimal taxRate = 0;
		// 売上日の会計金額を計算を行う[5万件まで検索できるため:->BatchApexで処理を行う
		// 一括やります「会計支払データは複数存在の会計情報の再計算は要らないです→既に画面に会計済みのものです」
		// 支払情報は集計対象データが未存在する場合、該当会計は未会計計算状態
		// 未計算データだけ、自動会計計算を行う
		// 会計情報を取得する
		Map<Id, AccountAcount__c> accAcountMap = new Map<Id, AccountAcount__c>();
		// 2019/02/15 功能优化修正 WGCH BEGIN
		bItem.leadNightInfoMap = new Map<String, BulkLeadCheckInBatch.LeadNightInfo>();
		Set<String> leadIndexIdSet = new Set<String>(); // 预约IndexId集合
		Set<String> leadIndexSubIdSet = new Set<String>(); // 预约IndexSubId集合
		Set<Decimal> roomGroupNoSet = new Set<Decimal>(); // 预约RoomGroupNo集合
		Map<String, List<Lead__c>> oneRoomLeadMap = new Map<String, List<Lead__c>>();
		// 2019/02/15 功能优化修正 WGCH END
		// 2019/06/28 支払いメディアの対象の予約の一覧表示機能 WGCH BEGIN
		String ACC_TRADE_VOID = CommConst.ACC_TRADE_VOID; // 取引種別 => ＶＯＩＤ
		/*
		for(AccountAcount__c item: [
			Select relaccount__c, frs__c, comment__c, TeaTimeFlag__c, Target__c, TableNo__c, Seq__c, Relreserve__c,
				   PlanNo__c, POSNo__c, OutSideAccount__c, Field99__c, Field98__c, Field97__c, Field96__c, Field95__c,
				   Field94__c, Field93__c, Field92__c, Field91__c, Field90__c, Field89__c, Field88__c, Field87__c,
				   Field86__c, Field85__c, Field84__c, Field83__c, Field82__c, Field81__c, Field80__c, Field7__c,
				   Field79__c, Field78__c, Field77__c, Field76__c, Field75__c, Field74__c, Field73__c, Field72__c,
				   Field71__c, Field70__c, Field69__c, Field68__c, Field67__c, Field66__c, Field65__c, Field64__c,
				   Field63__c, Field62__c, Field61__c, Field60__c, Field59__c, Field58__c, Field57__c, Field56__c,
				   Field55__c, Field54__c, Field53__c, Field52__c, Field51__c, Field50__c, Field49__c, Field48__c,
				   Field45__c, Field44__c, Field43__c, Field42__c, Field40__c, Field39__c, Field159__c, Field158__c,
				   Field157__c, Field156__c, Field155__c, Field154__c, Field152__c, Field151__c, Field150__c,
				   Field149__c, Field148__c, Field147__c, Field146__c, Field145__c, Field143__c, Field142__c,
				   Field141__c, Field140__c, Field139__c, Field138__c, Field137__c, Field136__c, Field135__c,
				   Field134__c, Field133__c, Field132__c, Field131__c, Field130__c, Field129__c, Field128__c,
				   Field127__c, Field126__c, Field125__c, Field124__c, Field123__c, Field122__c, Field121__c,
				   Field120__c, Field119__c, Field118__c, Field117__c, Field116__c, Field115__c, Field114__c,
				   Field113__c, Field112__c, Field111__c, Field110__c, Field109__c, Field108__c, Field107__c,
				   Field106__c, Field105__c, Field104__c, Field103__c, Field102__c, Field101__c, Field100__c,
				   DivisionName__c, Name, SumSrvPriceIncTax__c, SumSrvPriceExcTax__c,AmoutSpecialPrice__c,UnitPriceDefKb__c,SalesdayCal__c,
				   LastModifiedDate, LastModifiedById, Id, CreatedDate, CreatedById,
				   // 2019/02/15 功能优化修正 WGCH BEGIN
				   Relreserve__r.LeadIndexRef__c,Relreserve__r.LeadIndexSubId__c,Relreserve__r.RoomGroupNo__c,
				   // 2019/02/15 功能优化修正 WGCH END
				   Relreserve__r.StayPersons__c,Relreserve__r.Rroom__r.Name,Relreserve__r.Rroom__c,TaxRate__c
			// 会計日時設定される場合、該当会計は自動バッチ処理対象外
			from AccountAcount__c where frs__c =: rsvAccId And Relreserve__r.RefTypeOfRooms__r.ShopInfoRef__r.ShopCode__c =: bItem.shopCode]) {
		*/
		String querySQL = ' Select relaccount__c, frs__c, comment__c, TeaTimeFlag__c, Target__c, TableNo__c, Seq__c, Relreserve__c,' +
				  ' PlanNo__c, POSNo__c, OutSideAccount__c, Field99__c, Field98__c, Field97__c, Field96__c, Field95__c,' +
				  ' Field94__c, Field93__c, Field92__c, Field91__c, Field90__c, Field89__c, Field88__c, Field87__c,' +
				  ' Field86__c, Field85__c, Field84__c, Field83__c, Field82__c, Field81__c, Field80__c, Field7__c,' +
				  ' Field79__c, Field78__c, Field77__c, Field76__c, Field75__c, Field74__c, Field73__c, Field72__c,' +
				  ' Field71__c, Field70__c, Field69__c, Field68__c, Field67__c, Field66__c, Field65__c, Field64__c,' +
				  ' Field63__c, Field62__c, Field61__c, Field60__c, Field59__c, Field58__c, Field57__c, Field56__c,' +
				  ' Field55__c, Field54__c, Field53__c, Field52__c, Field51__c, Field50__c, Field49__c, Field48__c,' +
				  ' Field45__c, Field44__c, Field43__c, Field42__c, Field40__c, Field39__c, Field159__c, Field158__c,' +
				  ' Field157__c, Field156__c, Field155__c, Field154__c, Field152__c, Field151__c, Field150__c,' +
				  ' Field149__c, Field148__c, Field147__c, Field146__c, Field145__c, Field143__c, Field142__c,' +
				  ' Field141__c, Field140__c, Field139__c, Field138__c, Field137__c, Field136__c, Field135__c,' +
				  ' Field134__c, Field133__c, Field132__c, Field131__c, Field130__c, Field129__c, Field128__c,' +
				  ' Field127__c, Field126__c, Field125__c, Field124__c, Field123__c, Field122__c, Field121__c,' +
				  ' Field120__c, Field119__c, Field118__c, Field117__c, Field116__c, Field115__c, Field114__c,' +
				  ' Field113__c, Field112__c, Field111__c, Field110__c, Field109__c, Field108__c, Field107__c,' +
				  ' Field106__c, Field105__c, Field104__c, Field103__c, Field102__c, Field101__c, Field100__c,' +
				  ' DivisionName__c, Name, SumSrvPriceIncTax__c, SumSrvPriceExcTax__c,AmoutSpecialPrice__c,UnitPriceDefKb__c,SalesdayCal__c,' +
				  ' LastModifiedDate, LastModifiedById, Id, CreatedDate, CreatedById,' +
				   // 2019/02/15 功能优化修正 WGCH BEGIN
				  ' Relreserve__r.LeadIndexRef__c,Relreserve__r.LeadIndexSubId__c,Relreserve__r.RoomGroupNo__c,' +
				   // 2019/02/15 功能优化修正 WGCH END
				  ' Relreserve__r.StayPersons__c,Relreserve__r.Rroom__r.Name,Relreserve__r.Rroom__c,TaxRate__c' +
			// 会計日時設定される場合、該当会計は自動バッチ処理対象外
			' from AccountAcount__c where Field39__c != :ACC_TRADE_VOID ';
		if(bItem.accIdSet == null){
			String shopCode = bItem.shopCode;
			querySQL += ' And frs__c =: rsvAccId And Relreserve__r.RefTypeOfRooms__r.ShopInfoRef__r.ShopCode__c =: shopCode';
		} else {
			Set<String> accIdSet = bItem.accIdSet;
			querySQL += ' And Id In: accIdSet ';
		}
		for(AccountAcount__c item : Database.query(querySQL)) {
		// 2019/06/28 支払いメディアの対象の予約の一覧表示機能 WGCH END
			// 2019/02/15 功能优化修正 WGCH BEGIN
			leadIndexIdSet.add(item.Relreserve__r.LeadIndexRef__c); // 预约IndexId集合
			leadIndexSubIdSet.add(item.Relreserve__r.LeadIndexSubId__c); // 预约IndexSubId集合
			roomGroupNoSet.add(item.Relreserve__r.RoomGroupNo__c); // 预约RoomGroupNo集合
			// 2019/02/15 功能优化修正 WGCH END
			accAcountLst.add(item);
			accAcountMap.put(item.Id, item);
			if (taxRate == 0) taxRate = CommUtils.nullToZero(item.TaxRate__c);
		}
		// 処理対象データがない場合、処理終了
		if (accAcountMap.isEmpty()) return accAcountLst;
		// 2019/02/15 功能优化修正 WGCH BEGIN
		// 获取同一房间的相关预约
		List<Lead__c> oneRoomLeadLst = [ Select Id, LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c From Lead__c 
														Where LeadIndexRef__c =: leadIndexIdSet
														And LeadIndexSubId__c =: leadIndexSubIdSet
														And RoomGroupNo__c =: roomGroupNoSet
														And CancelBool__c !=: CommConst.LEAD_ST_CANCEL_FLG 
														Order By EntryTime__c ];
		for(Lead__c leadItem : oneRoomLeadLst){
			// ONEROOMの識別キー
			String key = leadItem.LeadIndexRef__c + '_' + leadItem.LeadIndexSubId__c + '_' + leadItem.RoomGroupNo__c;
			if(!oneRoomLeadMap.containsKey(key)) oneRoomLeadMap.put(key, new List<lead__c>());
			oneRoomLeadMap.get(key).add(leadItem);
		}
		for(String key : oneRoomLeadMap.keySet()){
			List<Lead__c> wkOneRoomLeadLst = oneRoomLeadMap.get(key);
			for(Integer i = 0; i < wkOneRoomLeadLst.size(); i++){ // 泊数Info处理
				Lead__c oneRoomLead = wkOneRoomLeadLst[i];
				// 2019/05/15 最終泊の設定対応 WGCH BEGIN
				// BulkLeadCheckInBatch.LeadNightInfo leadNightItem = new BulkLeadCheckInBatch.LeadNightInfo(oneRoomLead, (i+1), (wkOneRoomLeadLst.size() > 1));
				// 当前是第几泊
				Integer leadNight = i+1;
				BulkLeadCheckInBatch.LeadNightInfo leadNightItem = new BulkLeadCheckInBatch.LeadNightInfo(oneRoomLead, leadNight, (wkOneRoomLeadLst.size() > 1), wkOneRoomLeadLst.size() == leadNight );
				// 2019/05/15 最終泊の設定対応 WGCH END
				bItem.leadNightInfoMap.put(oneRoomLead.Id, leadNightItem);
			}
		}
		// 2019/02/15 功能优化修正 WGCH END
		bItem.rsvAccId = rsvAccId; // 売上Id
		bItem.taxRate = taxRate; // 消费税
		bItem.accAcountMap = accAcountMap; // 会计数据集计
		return accAcountLst;
	}
	// ***********************************
	// バッチロジック処理開始
	// ***********************************
	public void execute(Database.BatchableContext BC, List<AccountAcount__c> accAcountLst){
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'sumsrvpriceexctax__c','sumtax__c','othershopeditcheckflg__c','sumsrvpriceinctax__c','field57__c',
													'field53__c','field141__c','field126__c','field116__c','field114__c','discount__c','amoutspecialprice__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.AccountAcount__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
			return ;
		}
		List<String> chkFieldLst = new List<String>{'field2__c','field3__c'};
		Map<String,Schema.SObjectField> m = Schema.SObjectType.TTend__c.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(chkFieldLst, m)) {
			return ;
		}
		// 2019/09/15 Security Check BY zyz END
		Decimal taxRate = bItem.taxRate;
		Set<Id> accAcountIdSet = new Set<Id>();
		for(AccountAcount__c accItem : accAcountLst){
			accAcountIdSet.add(accItem.Id);
		}
		// 会計支払情報を取得する
		Map<Id, List<TTend__c>> ttendMap = new Map<Id, List<TTend__c>>();
		// 会計支払データを取得[同じ売上、有効な会計に、会計支払情報を取得する]
		for(TTend__c item: [select Field19__c, Field20__c, Field21__c,Field1__c,OutSideAccount__c,Field2__c,Field1__r.Relreserve__r.Field315__c,PayProductRef__r.ActionType__c,Field23__c,Field28__c from TTend__c where RelAccount__c =: bItem.rsvAccId And Field1__c in: accAcountIdSet]) {
			if(!ttendMap.containsKey(item.Field1__c)) ttendMap.put(item.Field1__c, new List<TTend__c>());
			ttendMap.get(item.Field1__c).add(item);
		}
		// 会計明細情報を取得する
		Map<Id, List<Tran1__c>> tranMap = new Map<Id, List<Tran1__c>>();
		// 詳細仕様： 請求書非表示(InvoiceNoShowFlg__c) AND 前受付　AND　有効な会計ID　の場合、統計対象外になる
		//		単価(Field20__c)
		//		数量(Field40__c/Field21__c)
		//		消費税(TaxRate__c)
		//		サービス料(ServiceRate__c) xx%方式
		//		特別税(SpecialTax__c)
		//	Where	商品処理種別　!= 前受け金 AND 請求書非表示(InvoiceNoShowFlg__c) AND 売上ID一致　AND　会計IDは有効な会計ID
		//	下記処理詳細：　処理対象の会計明細を取得して、
		//	取得する会計明細の会計支払データ件数は1件以上が存在する場合、処理対象外→既に処理済みの会計情報
		//	会計情報単位で、会計明細Groupする
		//	2013/11/12 親会計明細情報は計算対象外に変更対応
		for (Tran1__c item : [select UnitPriceDefKbCal__c, Id, Field1__c, ActionType__c, InvoiceNoShowFlg__c, Field20__c, Field21__c, Field40__c, TaxRate__c, ServiceRate__c, SpecialTax__c from Tran1__c
			where RelAccount__c =: bItem.rsvAccId And InvoiceNoShowFlg__c != true And ActionType__c !=: CommConst.PROD_ACTION_TYPE_AR
			And ParentTran1Ref__c = null
			And Field1__c in: accAcountIdSet
			Order By Field1__c]) {
			// 存在している会計支払データは2件以上（2件含め）場合、再計算を行わない
			//if (ttendRsCntMap.containsKey(item.Field1__c) && ttendRsCntMap.get(item.Field1__c) > 1) continue;
			// 会計情報から消費税率は０の場合、明細から消費税率を取得する、設定を行う
			if (taxRate == 0) taxRate = CommUtils.nullToZero(item.TaxRate__c);
			// 会計単位で、金額計算を行う
			// 会計情報は既に設定されている場合
			if (tranMap.containsKey(item.Field1__c)) tranMap.get(item.Field1__c).add(item);
			else {
				List<Tran1__c> tranLst = new List<Tran1__c>();
				tranLst.add(item);
				tranMap.put(item.Field1__c, tranLst);
			}
		}
		// 金額計算を行う:計算方法は会計編集画面：必ず同じルールで計算ください、修正する場合、必ず両方連動ください:
		// TODO:税抜の計算方法は：　商品　＊　数量総税込から　税抜を計算する、元システムに（数式）、先に商品の税込金額を計算後、この金額と数量で税抜く金額を計算する
		// 消費税計算を行うため、消費税値は０以上の商品金額を税込み金額を合計して、合計値にて、消費税を計算を行う
		// 計算用消費税率取得：会計日の消費税率を取得する「日付は：画面指定日　又は　スケジュールの実施日」
		
		List<Tran1__c> insTranLst = new List<Tran1__c>();
		List<TTend__c> insTTendLst = new List<TTend__c>();
		// List<TTend__c> updTTend = new List<TTend__c>();
		List<AccountAcount__c> updAccAcount = new List<AccountAcount__c>();
		List<AccountAcountHistoryInfo> accHistoryInfoLst = new List<AccountAcountHistoryInfo>();
		// 2019/05/15 最終泊の設定対応 WGCH BEGIN
		Map<String, List<TTend__c>> insAccReceivableTTendMap = new Map<String, List<TTend__c>>();
		Map<String, List<Tran1__c>> insAccReceivableTranMap = new Map<String, List<Tran1__c>>();
		Map<String, List<TTend__c>> accReceivableTTendMap = new Map<String, List<TTend__c>>();
		Map<String, List<Tran1__c>> accReceivableTranMap = new Map<String, List<Tran1__c>>();
		// 获取多泊指定的支付信息
		BulkLeadCheckInBatch.PaymentInfo nNightPaymentItem = bItem.configXmlItem.nNightPaymentItem;
		// 获取关联的所有预约Id*除最终泊
		Set<String> leadAllLst = new Set<String>();
		for(String leadId : bItem.leadNightInfoMap.keySet()){
			BulkLeadCheckInBatch.LeadNightInfo leadNightItem = bItem.leadNightInfoMap.get(leadId);
			// 最终泊的不查询
			if(!leadNightItem.leadLastNightFlg) leadAllLst.add(leadId);
		}
		// 获取所有预约指定多泊支付商品对应的支付信息
		if(bItem.configXmlItem.lastNightPaymentFlg && !leadAllLst.isEmpty()){
			for(TTend__c item : [select Field28__c, PayProductRef__c, Field1__r.Relreserve__r.LeadIndexRef__c, Field1__r.Relreserve__r.LeadIndexSubId__c, Field1__r.Relreserve__r.RoomGroupNo__c from TTend__c where Field1__r.Relreserve__c in: leadAllLst]) {
				// ONEROOMの識別キー
				String key = item.Field1__r.Relreserve__r.LeadIndexRef__c + '_' + item.Field1__r.Relreserve__r.LeadIndexSubId__c + '_' + item.Field1__r.Relreserve__r.RoomGroupNo__c;
				if(!accReceivableTTendMap.containsKey(key)) accReceivableTTendMap.put(key, new List<TTend__c>());
				accReceivableTTendMap.get(key).add(item);
			}
			// 获取所有预约指定多泊支付商品对应的明细信息
			for (Tran1__c item : [select Field23__c, Field7__c, Field1__r.Relreserve__r.LeadIndexRef__c, Field1__r.Relreserve__r.LeadIndexSubId__c, Field1__r.Relreserve__r.RoomGroupNo__c from Tran1__c where Field1__r.Relreserve__c in: leadAllLst And InvoiceNoShowFlg__c != true And ActionType__c !=: CommConst.PROD_ACTION_TYPE_AR And ParentTran1Ref__c = null]) {
				// ONEROOMの識別キー
				String key = item.Field1__r.Relreserve__r.LeadIndexRef__c + '_' + item.Field1__r.Relreserve__r.LeadIndexSubId__c + '_' + item.Field1__r.Relreserve__r.RoomGroupNo__c;
				if(!accReceivableTranMap.containsKey(key)) accReceivableTranMap.put(key, new List<Tran1__c>());
				accReceivableTranMap.get(key).add(item);
			}
		}
		// 2019/05/15 最終泊の設定対応 WGCH END
		// 会計単位で、会計明細情報を統計する
		for (Id acountId : accAcountIdSet) {
			// 会計情報へ設定を行う
			AccountAcount__c oAcountSobj = bItem.accAcountMap.get(acountId);
			// 1日１会計情報の会計総額金額計算

			// 売上計4（税込）金額
			Decimal totalAmoutIncTax = 0;
			// 売上計3（税抜）金額
			Decimal totalAmoutExcTax = 0;
			// サービス料金(税込)
			Decimal totalAmoutSrvIncTax = 0;
			// サービス料金(税抜)
			Decimal totalAmoutSrvExcTax = 0;
			// 宿泊税
			Decimal totalAmoutSPTax = 0;
			// 消費税ありの商品税込金額
			Decimal amoutPriceIncTaxByTax = 0;
			// 金額計算共通
			// １会計:1会計支払：N会計明細
			List<Tran1__c> tranLst = tranMap.get(acountId);
			if(tranLst == null) tranLst = new List<Tran1__c>();
			for (Tran1__c tranItem : tranLst) {
				/*
				// 前受付金の商品する場合
				if (tranItem.ActionType__c == CommConst.PROD_ACTION_TYPE_AR) {
					// 返金の場合、返金の金額は利用金額と加算して、店舗から出るの資産値
					if (BillSimpleHelp.isRefundItem(tranItem.PaymentType__c)) {
						totalAmoutIncTax += Math.abs(CommUtils.nullToZero(tranItem.Field23__c));
					} else {
						// 支払済の前受金情報
						totalAmoutIncTax -= CommUtils.nullToZero(tranItem.Field23__c);
					}
				}
				*/
				// 金額計算を行う
				// 2014/08/06 単価定義区分に従って、過去見積もり明細金額変更あり不具合修正 BEGIN
				CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(tranItem.UnitPriceDefKbCal__c));
				// 2014/08/06 単価定義区分に従って、過去見積もり明細金額変更あり不具合修正 END
				// 単価と数量はNULLの場合、
				Decimal unitPrice = CommUtils.nullToZero(tranItem.Field20__c);	// <-税金含め単価です
				Decimal qty = CommUtils.nullToZero(tranItem.Field21__c);
				// 金額計算を行う
				priceInfo.process(unitPrice, qty, tranItem.TaxRate__c, tranItem.ServiceRate__c);
				// 合計金額(税抜)※※※※（１円未満切り上げ）※※※※[サビース料込(20130923)]
				Decimal amoutExcTax = priceInfo.priceExcTax;
				// サービス料金（税込）
				Decimal servicePriceIncTax = priceInfo.priceService;
				// 2012/10/30 宿泊税の処理追加を行う
				// 合計金額(税込)[合計金額（税込:サービス込）＋特別税]
				totalAmoutIncTax += priceInfo.priceIncTax + CommUtils.nullToZero(tranItem.SpecialTax__c);
				// ----------- 会計へ設定用情報 ----------
				// サービス料金(税込)
				totalAmoutSrvIncTax += servicePriceIncTax;
				// サービス料金(税抜)
				totalAmoutSrvExcTax += priceInfo.priceServiceExcTax;
				// 宿泊税[TODO]自動計算する場合、宿泊税の設定が必要
				totalAmoutSPTax += CommUtils.nullToZero(tranItem.SpecialTax__c);
				// 商品販売金額（税抜き）
				totalAmoutExcTax += amoutExcTax; //+ totalAmoutSrvExcTax;
				// 商品税値は＞０の場合、金額合計を行う
				if (tranItem.TaxRate__c > 0 ) amoutPriceIncTaxByTax += priceInfo.priceIncTax;
			} // End For
			// 会計支払へ該当統計金額を計算を行う
			List<TTend__c> ttendSobjLst = ttendMap.get(acountId);
			// 複数会計支払い情報を存在する場合、処理対象外
			// TTend__c ttendSobj = (ttendSobjLst != null && ttendSobjLst.size() > 0) ? ttendSobjLst[0] : null;
			if(ttendSobjLst != null){
				for(TTend__c ttend : ttendSobjLst){
					totalAmoutIncTax -= CommUtils.nullToZero(ttend.Field28__c);
					amoutPriceIncTaxByTax -= CommUtils.nullToZero(ttend.Field28__c);
				}
			}
			// 2019/05/15 最終泊の設定対応 WGCH BEGIN
			if(!bItem.leadNightInfoMap.containsKey(oAcountSobj.Relreserve__c)) continue;
			// 获取当前会计对应的预约信息
			BulkLeadCheckInBatch.LeadNightInfo leadNightItem = bItem.leadNightInfoMap.get(oAcountSobj.Relreserve__c);
			// ONEROOMの識別キー
			String key = oAcountSobj.Relreserve__r.LeadIndexRef__c + '_' + oAcountSobj.Relreserve__r.LeadIndexSubId__c + '_' + oAcountSobj.Relreserve__r.RoomGroupNo__c;
			// 当前预约如果是最终泊时处理
			if(leadNightItem.leadLastNightFlg){
				if(accReceivableTTendMap.containsKey(key)){
					for(TTend__c item : accReceivableTTendMap.get(key)) {
						// 除最终以外的相关支付商品金额处理
						if(item.PayProductRef__c != nNightPaymentItem.paymentId) totalAmoutIncTax -= CommUtils.nullToZero(item.Field28__c);
						else{
							// *********** 合計金額 **********
							// 預かり　金額[バッチ処理の自動計算する場合、預かり金額は０で設定する]
							item.Field19__c = String.valueOf(0);
							// 支払　金額
							item.Field20__c = String.valueOf(0);
							// メディア毎消費税額設定を行う
							item.Field25__c = String.valueOf(0);
							// 請求書非表示
							item.InvoiceNoShowFlg__c = true;
							if(!insAccReceivableTTendMap.containsKey(key)) insAccReceivableTTendMap.put(key, new List<TTend__c>());
							insAccReceivableTTendMap.get(key).add(item);
						}
					}
				}
				if(accReceivableTranMap.containsKey(key)){
					for(Tran1__c item : accReceivableTranMap.get(key)) {
						if(item.Field7__c != nNightPaymentItem.paymentId) totalAmoutIncTax += CommUtils.nullToZero(item.Field23__c);
						// 除最终以外的相关支付商品金额处理
						else {
							// 数量设成0
							item.Field21__c = String.valueOf(0);
							// 請求書非表示
							item.InvoiceNoShowFlg__c = true;
							if(!insAccReceivableTranMap.containsKey(key)) insAccReceivableTranMap.put(key, new List<Tran1__c>());
							insAccReceivableTranMap.get(key).add(item);
						}
					}
				}
			}
			// 2019/05/15 最終泊の設定対応 WGCH END
			if(totalAmoutIncTax <= 0) continue;
			// メディア毎消費税額計算を行う
			// 2014/07/02 USD機能対応
			Integer pointLen = CommUtils.getPointLen();
			Decimal mediaTaxPrice = (amoutPriceIncTaxByTax > 0 ? CommUtils.RoundProcess(amoutPriceIncTaxByTax / (1 + taxRate / 100) * (taxRate / 100), pointLen) : 0);
			// 2019/05/15 最終泊の設定対応 WGCH BEGIN
			// 支付方式获取处理
			// if(!bItem.leadNightInfoMap.containsKey(oAcountSobj.Relreserve__c)) continue;
			// BulkLeadCheckInBatch.LeadNightInfo leadNightItem = bItem.leadNightInfoMap.get(oAcountSobj.Relreserve__c);
			// 2019/05/15 最終泊の設定対応 WGCH END
			BulkLeadCheckInBatch.PaymentInfo paymentItem = leadNightItem.leadNightsFlg ? bItem.configXmlItem.nNightPaymentItem : bItem.configXmlItem.firstNightPaymentItem;
			// 2019/05/15 最終泊の設定対応 WGCH BEGIN
			// 当前会计对应的预约时最终泊数据时&&最终泊设定支付信息功能打开处理
			if(leadNightItem.leadNightsFlg && leadNightItem.leadLastNightFlg && bItem.configXmlItem.lastNightPaymentFlg){
				// 最终泊支付商品信息
				paymentItem = bItem.configXmlItem.lastNightPaymentItem;
			}
			// if(paymentItem.isInvalidFlg) continue;
			if(paymentItem.isInvalidFlg){
				insAccReceivableTTendMap.remove(key);
				insAccReceivableTranMap.remove(key);
				continue;
			}
			// 2019/05/15 最終泊の設定対応 WGCH END
			if(paymentItem.actionTp == CommConst.PROD_ACTION_TYPE_AR){
				// 前受金「返金」明細 有效の場合
				if(BillSimpleHelp.isRefundItem(paymentItem.paymentTp)) continue;
				Tran1__c tran = new Tran1__c(
					Field7__c = paymentItem.paymentId,				// 商品コード
					ActionType__c = CommConst.PROD_ACTION_TYPE_AR,	// 商品処理種別
					PaymentType__c = paymentItem.paymentTp,			// 支払種別
					Field20__c = String.valueOf(totalAmoutIncTax),	// 単価 ←　預かり金額
					Field23__c = String.valueOf(totalAmoutIncTax),	// 合計金額 ←　預かり金額
					Field21__c = '1',								// 数量１固定
					Field5__c = paymentItem.paymentNm,				// 商品名称（または券名称）
					TaxRate__c = null,								// 消費税
					ServiceRate__c = null,							// サビース料
					SpecialTax__c = 0,								// 特別税
					UseDate__c = oAcountSobj.SalesdayCal__c,		// 利用日	
					RelAccount__c = bItem.rsvAccId,					// 売上情報
					Field1__c = acountId,							// 会計情報
					UnitPriceDefKb__c = oAcountSobj.UnitPriceDefKb__c // 会計商品単価定義区分
				);
				insTranLst.add(tran);
			}
			/*
			// 該当会計関連の開始払い存在チェック
			if (ttendSobj != null){
					// *********** 合計金額 **********
					// 預かり　金額[バッチ処理の自動計算する場合、預かり金額は０で設定する]
					ttendSobj.Field19__c = String.valueOf(totalAmoutIncTax);
					// 支払　金額
					ttendSobj.Field20__c = String.valueOf(totalAmoutIncTax);
					// メディア毎消費税額設定を行う
					ttendSobj.Field25__c = String.valueOf(mediaTaxPrice);
					// 更新リスト設定
					updTTend.add(ttendSobj);
			} else {
			*/
			// 新規作成
			TTend__c ttendSobj = 
				new TTend__c(
				// *********** 初期値設定 **********
				Field4__c = '1',
				Field5__c = '1',
				POSNo__c = CommUtils.getPosNoByComdefine(),
				// 支払商品情報の自動設定
				PayProductRef__c = paymentItem.paymentId,
				PaymentType__c = paymentItem.paymentTp,
				PayProductName__c = paymentItem.paymentNm,
				// *********** 合計金額 **********
				// 預かり　金額[バッチ処理の自動計算する場合、預かり金額は０で設定する]
				Field19__c = String.valueOf(totalAmoutIncTax),
				// 支払　金額
				Field20__c = String.valueOf(totalAmoutIncTax),
				// メディア毎消費税額設定を行う
				Field25__c = String.valueOf(mediaTaxPrice),
				// *********** 参照関係設定 **********
				// 売上情報
				RelAccount__c = bItem.rsvAccId,
				// 会計情報
				Field1__c = acountId
			);
			/*
			}
			*/
			// 支払方法は現金で設定行う
			// 2019/11/30 メディア名称BUG修正 WGCH BEGIN
			/*
			String[] typeInfo = BillSimpleHelp.getMediaCodeByLeadMediaType(paymentItem.mediaType);
			ttendSobj.Field2__c = typeInfo[0];
			ttendSobj.Field3__c = typeInfo[1];
			*/
			ttendSobj.Field2__c = CommConst.getMediaCodeByMediaName(paymentItem.mediaType); // メディア名からメディアコードを取得処理
			ttendSobj.Field3__c = paymentItem.mediaType;
			// 2019/11/30 メディア名称BUG修正 WGCH END
			accHistoryInfoLst.add( new AccountAcountHistoryInfo(oAcountSobj, totalAmoutIncTax, paymentItem.paymentNm, paymentItem.actionTp, paymentItem.paymentTp, ttendSobj.Field3__c, ttendSobj.Field2__c) );
			insTTendLst.add(ttendSobj);
			// 値引・割引券の場合、メディア毎消費税額は自動０に設定する
			if(ttendSobj.Field2__c == CommConst.MEDIA_TYPE_CD_12) mediaTaxPrice = 0;
			
			// TODO $会計日付/$会計日時　設定必要
			// TODO：営業日付 ←　チェックイン日付で設定を行う　
			oAcountSobj.Field141__c = CommUtils.getBusinessDay();
			// 会計日時: TODO->原システム確認要
			oAcountSobj.Field53__c = DateTime.valueOf(String.valueOf(System.now())).format('yyyyMMddHHmmss');
			// 会計人数
			//2016/12/27 会計人數自動設定機能封印 BEGIN by zh
			if(AccounntStayPersonsAutoSetupFlg){
				oAcountSobj.Field57__c = String.valueOf(
											CommUtils.nullToZero(oAcountSobj.Field66__c) +
											CommUtils.nullToZero(oAcountSobj.Field67__c) +
											CommUtils.nullToZero(oAcountSobj.Field68__c));
			}
			//2016/12/27 会計人數自動設定機能封印 END by zh
			// 売上計4（税込）金額:Field116__c -> 値引き存在と関係なし、実際の商品の売上を合計で設定する
			oAcountSobj.Field116__c = String.valueOf(totalAmoutIncTax);
			// 売上計3（税抜）金額:Field114__c[商品販売の金額税抜き＋サービス料金税抜き] // TODO:該当内容はBillInput__Ctrl差異あり
			oAcountSobj.Field114__c = String.valueOf(totalAmoutExcTax);
			// サービス料金(税込)
			oAcountSobj.SumSrvPriceIncTax__c = totalAmoutSrvIncTax;
			// サービス料金(税抜)
			oAcountSobj.SumSrvPriceExcTax__c = totalAmoutSrvExcTax;
			// 宿泊税
			oAcountSobj.AmoutSpecialPrice__c = totalAmoutSPTax;
			// 割引金額（税込）
			oAcountSobj.Discount__c = (ttendSobj.Field2__c == CommConst.MEDIA_TYPE_CD_12 ? totalAmoutIncTax : 0);
			// Media消費税で会計の消費税項目に設定を行う
			oAcountSobj.sumTax__c = mediaTaxPrice;
			// 請求金額(TODO:請求金額は設定内容を再確認要)
			oAcountSobj.Field126__c = String.valueOf(totalAmoutIncTax);
			// 2017/01/25 店舗ごとの会計権限機能対応 BEGIN
			oAcountSobj.OtherShopEditCheckFlg__c = true;
			// 2017/01/25 店舗ごとの会計権限機能対応 END
			// 更新リストに格納する
			updAccAcount.add(oAcountSobj);
		} // End For
		try {
			if (!insTranLst.isEmpty()) insert insTranLst;
			if (!insTTendLst.isEmpty()) insert insTTendLst;
			if(!accHistoryInfoLst.isEmpty()) bItem.accHistoryInfoLst.addAll(accHistoryInfoLst); // 防止更新失败
			// if (!updTTend.isEmpty()) update updTTend;
			if (!updAccAcount.isEmpty()) update updAccAcount;
			// 2019/05/15 最終泊の設定対応 WGCH BEGIN
			if(!insAccReceivableTTendMap.isEmpty()){
				List<TTend__c> insAccReceivableTTendLst = new List<TTend__c>();
				for(List<TTend__c> wkAccReceivableTTendLst : insAccReceivableTTendMap.values()){
					insAccReceivableTTendLst.addAll(wkAccReceivableTTendLst);
				}
				update insAccReceivableTTendLst;
			}
			if(!insAccReceivableTranMap.isEmpty()){
				List<Tran1__c> insAccReceivableTranLst = new List<Tran1__c>();
				for(List<Tran1__c> wkAccReceivableTranLst : insAccReceivableTranMap.values()){
					insAccReceivableTranLst.addAll(wkAccReceivableTranLst);
				}
				update insAccReceivableTranLst;
			}
			// 2019/05/15 最終泊の設定対応 WGCH END
		} catch (Exception e) {}
	}
	// ***********************************
	// バッチ終了処理開始
	// ***********************************
	public void finish(Database.BatchableContext BC){
		sendMail();
	}
	private String getRestoreUrl(Id accId) {
		String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
		PageReference page = new PageReference('/' + accId);
		return (baseUrl + page.getUrl());
	}
	// Batch全局变量集合Info
	public class BatchVariableInfo{
		/*
		*  预约处理变量
		*/
		public String shopName; // 店铺名
		public String shopCode; // 店铺CODE
		public Date checkInDate; // 处理日(到着日)
		public Integer leadCheckInSize; // 已经checkIn的预约件数
		public Map<String, BulkLeadCheckInBatch.LeadNightInfo> leadNightInfoMap; // 当天的所有预约的数据集
		/*
		*  会计处理变量
		*/
		public Id rsvAccId; // 売上Id
		public Decimal taxRate; // 消费税
		public List<AccountAcountHistoryInfo> accHistoryInfoLst; // 会计变更明细
		public Map<Id, AccountAcount__c> accAcountMap;
		/*
		*  Xml配置变量
		*/
		public BulkLeadCheckInBatch.ConfigXmlInfo configXmlItem; // Xml配置数据集
		// 2019/06/28 支払いメディアの対象の予約の一覧表示機能 WGCH BEGIN
		public Set<String> accIdSet;
		// 2019/06/28 支払いメディアの対象の予約の一覧表示機能 WGCH END
		public BatchVariableInfo(BulkLeadCheckInBatch.BatchVariableInfo bItem){
			shopCode = bItem.shopCode;
			checkInDate = bItem.checkInDate;
			leadCheckInSize = bItem.leadCheckInSize;
			rsvAccId = bItem.rsvAccId;
			taxRate = bItem.TaxRate;
			accHistoryInfoLst = new List<AccountAcountHistoryInfo>();
			accAcountMap = bItem.accAcountMap;
			leadNightInfoMap = bItem.leadNightInfoMap;
			configXmlItem = bItem.configXmlItem;
			// 2019/06/28 支払いメディアの対象の予約の一覧表示機能 WGCH BEGIN
			accIdSet = bItem.accIdSet;
			// 2019/06/28 支払いメディアの対象の予約の一覧表示機能 WGCH END
		}
	}
	public class AccountAcountHistoryInfo{
		public AccountAcount__c acc;
		public Decimal totalAmoutIncTax; // 預かり　金額
		public String paymentNm; // 支払商品
		public String actionTp; // 商品処理種別
		public String paymentTp; // 支払種別
		public String mediaNm; // メディア名称
		public String mediaTp; // メディア種別
		public AccountAcountHistoryInfo(AccountAcount__c acc, Decimal totalAmoutIncTax, String paymentNm, String actionTp, String paymentTp, String mediaNm, String mediaTp){
			this.acc = acc;
			this.totalAmoutIncTax = CommUtils.nullToZero(totalAmoutIncTax);
			this.paymentNm = CommUtils.nullToBlank(paymentNm);
			this.actionTp = CommUtils.nullToBlank(actionTp);
			this.paymentTp = CommUtils.nullToBlank(paymentTp);
			this.mediaNm = CommUtils.nullToBlank(mediaNm);
			this.mediaTp = CommUtils.nullToBlank(mediaTp);
		}
	}
	// 処理結果の送信処理
	private void sendMail() {
		String mailAdds = CommDefine__c.getOrgDefaults().ScheduleResultMailAddress__c;
		if(CommUtils.isBlank(mailAdds)) return;
		// メール情報を設定する
		String currencyInf = UserInfo.getDefaultCurrency();			// ログインユーザーの組織通貨を取得する
		if(CommUtils.isBlank(currencyInf)) currencyInf = 'JPY';		// 組織通貨設定がNULLの場合、通貨JPY(日本円)に設定する
		Integer pointlen = CommUtils.getPointLen(currencyInf);		// 指定の通貨により、小数点桁数を取得する
		String body = '';
		for (AccountAcountHistoryInfo accItem : bItem.accHistoryInfoLst) {
			body += '会計：           ' + getRestoreUrl(accItem.acc.Id) + '\n';
			body += '支払明細：     ' + accItem.paymentTp + '[' + accItem.paymentNm +'] / ' + CommUtils.RoundProcess(accItem.totalAmoutIncTax, pointlen).format() + '\n\n';
		}
		String mailBodyStr = '処理日： ' + bItem.checkInDate.format();
		Map<String, ShopInformation__c> shopInfoMap = ShopInfoUtil.getShopInfoMap();
		// 店铺判断
		if(!shopInfoMap.isEmpty() && shopInfoMap.containsKey(bItem.shopCode)) bItem.shopName = CommUtils.nullToBlank(shopInfoMap.get(bItem.shopCode).Name);
		if(!CommUtils.isBlank(bItem.shopName)) mailBodyStr += '\n店舗： ' + bItem.shopName;
		if(bItem.configXmlItem.autoCheckInFlg) mailBodyStr += '\n\n自動チェックインされた予約件数：' + bItem.leadCheckInSize + '(件)';
		mailBodyStr += '\n\n支払情報を自動登録された会計件数：' + bItem.accHistoryInfoLst.size() +'(件)';
		if(!CommUtils.isBlank(body)) mailBodyStr += '\n処理明細：\n' + body.removeEnd('\n\n');
		mailBodyStr += '\n\nJinyaConnect Enterprise system R&D team.';
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = mailAdds.split(',');
		mail.setToAddresses(toAddresses);
		mail.setSubject('[支払いメディアの一括自動入力] バッチ処理結果の通知['+UserInfo.getOrganizationName()+']');
		mail.setPlainTextBody(mailBodyStr);
		// テストクラスの場合、実施しない
		if(!Test.isRunningTest()) {
			try {
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
			} catch(Exception e){}
		}
	}
}