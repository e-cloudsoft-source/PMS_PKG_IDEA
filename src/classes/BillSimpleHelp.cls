/**
* お客様から支払情報の格納、変更、削除、減算処理を行う
**/
public with sharing class BillSimpleHelp {
	// 該当会計明細は返金するがどうかチェックを行う
	public static Boolean isRefundItem(String paymentInf) {
		return (paymentInf == '現金返金' || paymentInf == 'カード返金');
	}
	public static String[] getRefundItemStr(){
		return new String[]{'現金返金','カード返金'};
	}
	// 予約から会計支払のメデイア変換ロジック対応
	public static String[] getMediaCodeByLeadMediaType(String typeName) {
		String[] typeInfo = new String[2];
		// 新規登録を行う
		String mediaType = typeName;
    	// 初期値設定を行う
		String ttendType = CommConst.MEDIA_TYPE_CD_01;
		if (mediaType == 'カード') ttendType = CommConst.MEDIA_TYPE_CD_02;
		else if (mediaType == '売掛') ttendType = CommConst.MEDIA_TYPE_CD_03;
		else if (mediaType == 'クーポン') ttendType = CommConst.MEDIA_TYPE_CD_11;
		typeInfo[0] = ttendType;
		typeInfo[1] = CommConst.getPaymentTypeLabelByKey(typeInfo[0]);
		return typeInfo;
	}

	// 該当部屋に含めの予約情報の初日チェックインの場合、含めの予約明細に、見積明細情報の中に、前受付金がなかったの場合、自動的に
	// 該当予約の会計支払情報に、支払金額を自動設定を行う
	// 1予約ー１会計ー１支払
	@future
	//public static void autoCalTTendInfo(List<Id> ttendIds) {
	public static void autoCalTTendInfo(List<Id> accIdsLst) {

		// 該当会計支払関連の会計→予約情報を取得する
		// 取得する予約情報の見積明細から、前受付金存在チェックを行う
		// 存在すると、自動会計支払金額の自動設定を行わない
		// 存在なかったの場合、自動総金額自動設定を行う
		// 支払情報関連の会計支払ー＞会計ー＞予約情報を取得する
		// 処理対象会計情報
		map<id, AccountAcount__c> leadAccMap = new map<id, AccountAcount__c>();
		List<AccountAcount__c > accs = [select id
								, frs__c
								, Relreserve__c
								, Relreserve__r.LeadIndexRef__c
								, Relreserve__r.LeadIndexSubId__c
								, Relreserve__r.RoomGroupNo__c
								, Relreserve__r.Field315__c
								, Relreserve__r.CouponTypeLst__c
								, (Select Field2__c, Field3__c, CardTypeLst__c, OutSideAccount__c From TranTotalfromPay__r)
								from AccountAcount__c
								where id in :accIdsLst for update
								];
		// 該当会計支払情報の
		Set<Id> leadIdxIdSet = new Set<Id>();
		Set<Id> leadSubIdxIdSet = new Set<Id>();
		Set<Decimal> leadGroupNoSet = new Set<Decimal>();
		Set<String> filterKeySet = new Set<String>();
		// 同じグループの会計情報を探す
		for (AccountAcount__c acc : accs) {
			leadIdxIdSet.add(acc.Relreserve__r.LeadIndexRef__c);
			leadSubIdxIdSet.add(acc.Relreserve__r.LeadIndexSubId__c);
			leadGroupNoSet.add(acc.Relreserve__r.RoomGroupNo__c);
			// 既存会計情報を格納する
			leadAccMap.put(acc.Relreserve__c,acc);
			// Key
			String key = 	  CommUtils.nullToBlank(acc.Relreserve__r.LeadIndexRef__c) 
							+ '_' 
							+ CommUtils.nullToBlank(acc.Relreserve__r.LeadIndexSubId__c)
							+ '_'
							+ CommUtils.nullToBlank(acc.Relreserve__r.RoomGroupNo__c);
			filterKeySet.add(key);
		}
		// 関連の予約情報を取得する
		Map<Id, String> keyMap = new Map<Id, String>();
		// 関連の予約情報を取得する
		List<Lead__c> leads = [select id, Name
			, LeadIndexRef__c ,LeadIndexSubId__c ,RoomGroupNo__c
			, EstimateTotal__c							// 見積合計(積み上げ)
			,(Select Id From BookingEstimateItemFgKu__r 
			  Where ActionType__c = :CommConst.PROD_ACTION_TYPE_AR OR ActionType__c = :CommConst.PROD_ACTION_TYPE_PY) // 前受金 || 支払　明細存在チェック
			from Lead__c
			where LeadIndexRef__c in :leadIdxIdSet
			And LeadIndexSubId__c in :leadSubIdxIdSet
			And RoomGroupNo__c in :leadGroupNoSet
			And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
			Order By LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c, EntryTime__c
		];
		// 引き渡し支払関連の予約情報は初日の予約情報の場合
		Map<String, List<Lead__c>> allLeadMap = new Map<String, List<Lead__c>>();
		for (Lead__c lead : leads) {
			String key = 	  CommUtils.nullToBlank(lead.LeadIndexRef__c) 
							+ '_' 
							+ CommUtils.nullToBlank(lead.LeadIndexSubId__c)
							+ '_'
							+ CommUtils.nullToBlank(lead.RoomGroupNo__c);
			if (!filterKeySet.contains(key)) continue;
			// 初日の予約情報
			if (!allLeadMap.containsKey(key)) allLeadMap.put(key, new List<Lead__c>());
			allLeadMap.get(key).add(lead);
			
			keyMap.put(lead.Id, key);
		}
		// 事前入金など、個別な新規会計を作成する場合、関連会計に支払情報存在チェツクを行う
		// 同じ予約に紐付くの会計が存在　かつ　支払情報が存在する場合、処理対象がになる
		Set<String> isHavePayMediaSet = new Set<String>();
		List<AccountAcount__c > relAccs = [select id
												, Relreserve__c
												, Relreserve__r.LeadIndexRef__c
												, Relreserve__r.LeadIndexSubId__c
												, Relreserve__r.RoomGroupNo__c
												, (Select id From TranTotalfromPay__r where OutSideAccount__c = 1 limit 1)
											from  AccountAcount__c
											where id not in :accIdsLst
											and Relreserve__c in :keyMap.keySet()];
		for (AccountAcount__c acc : relAccs) {
			if (!acc.TranTotalfromPay__r.isEmpty()) {
				// Key
				String key = 	  CommUtils.nullToBlank(acc.Relreserve__r.LeadIndexRef__c) 
								+ '_' 
								+ CommUtils.nullToBlank(acc.Relreserve__r.LeadIndexSubId__c)
								+ '_'
								+ CommUtils.nullToBlank(acc.Relreserve__r.RoomGroupNo__c);
				isHavePayMediaSet.add(key);
			}
		}
		
		List<TTend__c> updTtend = new List<TTend__c>();
		List<TTend__c> insTtend = new List<TTend__c>();
		// 2019/06/14 checkin后会计未保存的支付明细内的支付商品为空bug对应 BY zyz BEGIN
		Map<String, AccountMaster__c> mediaMasterMap = new Map<String, AccountMaster__c>();
		String oShopCode = '';
		BillSimpleHelp help = new BillSimpleHelp(oShopCode);
		mediaMasterMap = help.getMediaLabToAccMstMap();
		// 2019/06/14 checkin后会计未保存的支付明细内的支付商品为空bug对应 BY zyz END
		// 会計支払情報関連の予約情報を集計する
		for (Id leadId : leadAccMap.keySet()) {
			if (keyMap.containsKey(leadId)) {
				List<Lead__c> subLeads = allLeadMap.get(keyMap.get(leadId));
				// 支払の関連の予約は初日以外の場合、対象外
				if (subLeads[0].Id != leadId) continue;
				// 既に関連の会計情報に支払情報が存在すると、自動作成を行わない
				if (isHavePayMediaSet.contains(keyMap.get(leadId))) continue;
				// 関連予約の中に、前受付金存在チェック
				Boolean isExistArData = false;
				Decimal estTotalAmount = 0;
				for (Lead__c subLead : subLeads) {
					// 支払の見積明細が存在する場合
					if (!subLead.BookingEstimateItemFgKu__r.isEmpty()) {
						isExistArData = true;
						break;
					}
					estTotalAmount += CommUtils.nullToZero(subLead.EstimateTotal__c);
				}
				if (isExistArData) continue;
				// 2015/03/05 利用金額は０円の場合、支払情報作成を行わない
				if (estTotalAmount <= 0) continue;
				// 前受付金なし場合、見積合計金額は支払情報へ反映を行う
				AccountAcount__c acc = leadAccMap.get(leadId);
				if (acc.TranTotalfromPay__r.isEmpty()) {
					// 新規登録を行う
					String mediaType = acc.Relreserve__r.Field315__c;
		        	// 初期値設定を行う
					String[] typeInfo = getMediaCodeByLeadMediaType(mediaType);
					// 2019/06/14 checkin后会计未保存的支付明细内的支付商品为空bug对应 BY zyz BEGIN
					AccountMaster__c accMas = mediaMasterMap.get(typeInfo[1]);
					if(accMas == null) continue;
					// 2019/06/14 checkin后会计未保存的支付明细内的支付商品为空bug对应 BY zyz END
					// 2014/04/28 金券種別項目追加、予約から会計支払へコピー
		        	TTend__c item = new TTend__c(
		        	   RelAccount__c = acc.frs__c,
		        	   Field1__c = acc.id,
		        	   Field2__c = typeInfo[0],
		        	   Field3__c = typeInfo[1],
		        	   CouponTypeLst__c = acc.Relreserve__c == null ? null : acc.Relreserve__r.CouponTypeLst__c,
		        	   // --------- 初期値設定を行う ---------
		               Field4__c = '1',
		               Field5__c = '1',
		               POSNo__c = CommUtils.getPosNoByComdefine(),
		               Field19__c = String.valueOf(estTotalAmount),
		               Field20__c = String.valueOf(estTotalAmount),
		               Field21__c = '0'
		               // 2019/06/14 checkin后会计未保存的支付明细内的支付商品为空bug对应 BY zyz BEGIN
		               ,PayProductRef__c = accMas.Id
		               ,PaymentType__c = accMas.PaymentType__c
		               ,PayProductName__c =accMas.Name
		               // 2019/06/14 checkin后会计未保存的支付明细内的支付商品为空bug对应 BY zyz END
		        	   );
					insTtend.add(item);
				} else {
					List<TTend__c> targetTtend = acc.TranTotalfromPay__r;
					// 有効な支払情報は既に存在する場合、処理飛ばす
					if (targetTtend[0].OutSideAccount__c == 1) continue;
					
					targetTtend[0].Field19__c = String.valueOf(estTotalAmount);
					targetTtend[0].Field20__c = String.valueOf(estTotalAmount);
					targetTtend[0].Field21__c = '0';
					updTtend.add(targetTtend[0]);
				} // End if (acc.TranTotalfromPay__r.isEmpty()) {

			}
		}
		if (!updTtend.isEmpty()) update updTtend;
		if (!insTtend.isEmpty()) insert insTtend;
	}
	
	// Media情報関連の会計商品情報
	private Map<String, AccountMaster__c> mediaLabToAccMstMap;
	public Map<String, AccountMaster__c> getMediaLabToAccMstMap() {
		return mediaLabToAccMstMap;
	}
	// 支払種別ー＞支払メデイア名変換情報取得
	private Map<String, String> paymentTypeToMediaLabMap;
	public Map<String, String> getPaymentTypeToMediaLabMap () {
		return paymentTypeToMediaLabMap;
	}
	
	public BillSimpleHelp(String shopCode) {
		// 初期化処理
		mediaLabToAccMstMap = new Map<String, AccountMaster__c>();
		paymentTypeToMediaLabMap = new Map<String, String>();
		
		// メデイアー＞会計商品コード
		Map<String,String> locMediaProductMap = new Map<String, String>();
		// 'BillSimpleHelpConfig'
		Dom.XmlNode targetNode = CommXmlUtils.parseXmlDoc('BillSimpleHelpConfig', shopCode);
		// 定義情報を読み込み
		for(Dom.XMLNode xmlNode : targetNode.getChildElements()) {
			// タグ名
			String attributeName = xmlNode.getName();
			if (attributeName.equalsIgnoreCase('SHOPCODE')) continue;	// 店舗情報のタグ
			if (attributeName.equalsIgnoreCase('PAYMENT')) {			// 支払種別ー＞会計支払メデイア対応情報を取得する
				// Convert Field Info
				for(Dom.XMLNode convert : xmlNode.getChildElements()) {
					Dom.XMLNode payTypeField = convert.getChildElement('PAYTYPE', null);
					Dom.XMLNode mediaNmField = convert.getChildElement('MEIDALAB', null);
					if (payTypeField == null || mediaNmField == null ) continue;
					// 2016/07/01 トランスレーション対応 BEGIN
					String payType = CommUtils.nullToBlank(payTypeField.getText()).trim();
					String mediaNm = CommUtils.nullToBlank(mediaNmField.getText()).trim();
					// 2016/07/01 トランスレーション対応 END
					paymentTypeToMediaLabMap.put(payType, mediaNm);
				}
			}
			if (attributeName.equalsIgnoreCase('PAYMEIDA')) {			// 会計支払メデイアー＞会計商品コード対応情報を取得する
				// Convert Field Info
				for(Dom.XMLNode convert : xmlNode.getChildElements()) {
					Dom.XMLNode mediaNmField = convert.getChildElement('MEIDALAB', null);
					Dom.XMLNode produCdField = convert.getChildElement('PRODCODE', null);
					if (produCdField == null || mediaNmField == null ) continue;
					// 2016/07/01 トランスレーション対応 BEGIN
					String productCd = CommUtils.nullToBlank(produCdField.getText()).trim();
					String mediaLab = CommUtils.nullToBlank(mediaNmField.getText()).trim();
					// 2016/07/01 トランスレーション対応 END
					locMediaProductMap.put(mediaLab, productCd);
				}				
			}
		}
		// 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH BEGIN
		maxRows = 200;
		limitFlg = true;
		autoPrintFlg = true;
		accSkipTabShow = true;
		autoSaveLimit = 200;
		autoSaveMessage = '自動保存中...';
		/*
		Dom.XMLNode limitsField = targetNode.getChildElement('LIMITS',null);
		if (limitsField != null) {
			limitFlg = true;
			Dom.XMLNode maxRowsField = limitsField.getChildElement('MAXROWS', null);
			if(maxRowsField != null){
				String maxRowsStr = CommUtils.nullToBlank(maxRowsField.getText());
				if(!CommUtils.isBlank(maxRowsStr) && Pattern.matches('[0-9]*', maxRowsStr)){
					maxRows = CommUtils.nullToZero(maxRowsStr) < 1 ? 1 : CommUtils.nullToZero(maxRowsStr);
				}
			}
		}
		*/
		Dom.XMLNode autoSaveMessageField = targetNode.getChildElement('AUTOSAVEMESSAGE',null);
		if (autoSaveMessageField != null) {
			String messageStr = autoSaveMessageField.getText();
			if (!CommUtils.isBlank(messageStr)){
				autoSaveMessage = messageStr;
			}
			String autoSaveLimitStr = autoSaveMessageField.getAttribute('DETAIL_LIMIT', null);
			if (!CommUtils.isBlank(autoSaveLimitStr)) {
				autoSaveLimit = CommUtils.nullToIntZero(autoSaveLimitStr);
			}
		}
		Dom.XMLNode mergeTabField = targetNode.getChildElement('MERGETAB',null);
		if (mergeTabField != null) {
			String accSkipTabShowField = mergeTabField.getAttribute('ISSHOW', null);
			if(accSkipTabShowField != null){
				accSkipTabShow = Boolean.valueOf(CommUtils.nullToBlank(accSkipTabShowField));
			}
			String printField = mergeTabField.getAttribute('PRINT', null);
			if(printField != null){
				autoPrintFlg = Boolean.valueOf(CommUtils.nullToBlank(printField));
			}
			
			Dom.XMLNode accFilterField = mergeTabField.getChildElement('ACCOUNTFILTER', null);
			if(accFilterField != null){
				accXmlWhereStr = CommUtils.nullToBlank(accFilterField.getText());
			}
		}
		// 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH END
        // 2018/04/11 支払メデイア種別はカスタマイズできるように対応 BEGIN
        list<CustMediaInfo> extPays = BillSimpleHelp.getCustPayMediaList();
        for (CustMediaInfo s: extPays) {
            paymentTypeToMediaLabMap.put(s.mediaNm,s.mediaNm);
            locMediaProductMap.put(s.product,s.mediaNm);
        }
        // 2018/04/11 支払メデイア種別はカスタマイズできるように対応 END
		// 会計メデイア名ー＞会計商品コードから会計商品IDを取得する
		if (!locMediaProductMap.isEmpty()) {
			// Map<会計商品コード・会計商品>
			Map<String, AccountMaster__c> locMstMap = new Map<String, AccountMaster__c>();
			List<AccountMaster__c> accMsts = [  Select Id, Name, Field3__c, PaymentType__c 
												,KanjoKamokuRef__r.KanjocodeCode__c
												,KanjoKamokuRef__r.Name
												,KanjoKamokuRef__r.KanjoHojocode__c
												,KanjoKamokuRef__r.KanjoHojoname__c
												,KanjoKamokuRef__r.DebitTaxKbn__c
												,KanjoKamokuRef__r.CreditTaxKbn__c
												From AccountMaster__c Where Field3__c in :locMediaProductMap.values()];
			for (AccountMaster__c accMst : accMsts) {
				// 会計商品コード：会計商品
				locMstMap.put(accMst.Field3__c, accMst);
			}
			// XML定義からMediaの会計商品情報をMapに格納する
			for (String media : locMediaProductMap.keySet()) {
				String productCd = locMediaProductMap.get(media);
				if (locMstMap.containsKey(productCd)) {
					mediaLabToAccMstMap.put(media, locMstMap.get(productCd));	
				}
			}
		}
	}
	// 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH BEGIN
	// 优化开关
	public Boolean limitFlg;
	// 最大可入力行
	public Decimal maxRows;
	// XML自定义Where条件
	public String accXmlWhereStr;
	// TAB开关
	public Boolean accSkipTabShow;
	// レシートに自動印刷: TRUE: 有效(默认); FALSE: 无效;
	public Boolean autoPrintFlg;
	public String autoSaveMessage;
	public Integer autoSaveLimit;
	// 2021/02/28 会計画面上から確定した会計明細・支払を別の部屋の会計に移動する機能 WGCH END
	// 2018/04/11 支払メデイア種別はカスタマイズできるように対応 BEGIN
	private static map<String,CustMediaInfo> custPayCdMap = null;
	private static map<String,CustMediaInfo> custPayNmMap = null;
	private static list<CustMediaInfo> custPayLst = null;
    // 支払メデイアコードで支払メデイア名取得する
    public static String getMediaLabelByCode(String cd) {
        initCustPayInfo();
        return (custPayCdMap.containsKey(cd) ? custPayCdMap.get(cd).mediaNm : '');
    }
    // 支払メデイア名で支払メデイア名取得する
    public static String getMediaCodeByName(String nm) {
        initCustPayInfo();
        return (custPayNmMap.containsKey(nm) ? custPayNmMap.get(nm).mediaCd : ''); 
    }
    // 支払メデイアリスト返却「支払コード：支払名」
    public static list<SelectOption> getCustPayList() {
       initCustPayInfo();
       list<SelectOption> rs = new List<SelectOption>();
       for (CustMediaInfo c : custPayLst) {
            rs.add(new SelectOption(c.mediaCd, c.mediaNm));
       }
       return rs;
    }
    // カスタマイズの支払メデイアの配列情報を返却する
    private static list<CustMediaInfo> getCustPayMediaList() {
       initCustPayInfo();
       return custPayLst; 
    }
    // 関連情報を取得する
	private static void initCustPayInfo () {
       if (custPayCdMap == null || custPayNmMap == null) {
           custPayCdmap = new map<String,CustMediaInfo>();
           custPayNmMap = new map<String,CustMediaInfo>();
           custPayLst = new list<CustMediaInfo>();
           list<CustomPayMedia__mdt> custPayRsLst = [select developerName,masterlabel,PayProductCd__c from CustomPayMedia__mdt Order by SortNo__c];
           for (CustomPayMedia__mdt media : custPayRsLst) {
               CustMediaInfo item = new CustMediaInfo(media);
               custPayCdmap.put(item.mediaCd, item);
               custPayNmMap.put(item.mediaNm, item);
               custPayLst.add(item);
           }
       }
	}
	class CustMediaInfo {
	    CustMediaInfo(CustomPayMedia__mdt pay) {
	        mediaCd = pay.developerName;
	        mediaNm = pay.masterlabel;
	        product = pay.PayProductCd__c;
	    }
	    string mediaCd{get;set;}//支払メデイアコード
	    string mediaNm{get;set;}//支払メデイア名
	    string product{get;set;}//該当支払メデイア関連の会計商品
	}
	// 2018/04/11 支払メデイア種別はカスタマイズできるように対応 END
}