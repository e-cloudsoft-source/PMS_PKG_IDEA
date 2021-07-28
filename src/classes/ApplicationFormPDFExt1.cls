/**
* 予約確認書
* 予約確認書処理ロジックを追加
* 2015/07/08 明細に支払情報を追加に従って、合計値、明細表示対応
* 2015/11/15 予約確認書（レイアウト５）を新規追加する
* 2016/01/28 コメント内容は自動改行
* 2016/02/03 予約確認書（レイアウト２）の「食数」項目を外すと「泊数は０」のとき、泊数と部屋数の内容は空白で出力する
* 2016/03/25 予約情報「HEADER」取得元は「予約インデックスから取得」から起動している予約からお客様情報を取得する
* 2016/10/26 支払情報はクポーン、割引合計値の減算とき、入湯税金額含めない不具合修正
* 2019/04/30 増税仮対応
* 2019/07/30 軽減税率機能対応
* 2020/06/30 予約確認書の集計対象がカスタマイズできるように改善対応
* 2021/07/30 予約確認書のカスタマイズ
**/
public with sharing class ApplicationFormPDFExt1 extends CommBaseCtrl{
	// 予約ID
	private final Id leadId;
	// 店舗コード
	private String shopCode;
	// レイアウトコード
	private static String layoutCode;
	private static final String layoutType2A4 = '2';
	private static final String layoutType3B5 = '3';
	private static final String layoutType4A4 = '4';
	private static final String layoutType5A4 = '5';
	// 2021/07/30 #JP10785 by zy BEGIN
	private static final String layoutType6 = '6'; // 予約確認書のカスタマイズモード
	// 2021/07/30 #JP10785 by zy END
	// 予約確認書XML定義情報
	public transient XmlConfigInfo oXmlInfo{get; private set;}
	// 引き渡すコメント情報
	// 2016/01/28 コメント内容は自動改行 BEGIN
	public transient String pComment{get; private set;}
	public transient lead__c outLeadInf{get; private set;}
	public Boolean isCommentAutoBreakFlg{get{return CommDefine__c.getOrgDefaults().BillReportCommentAutoBreakFlg__c;}}
	// 2019/03/31 日帰り時刻を表記 BY zyz BEGIN
	public Boolean isApplicationFormTimeFlg{get{return CommConst.APPOTION_APPLICATIONFORMTIME_FLG;}}
	// 2019/03/31 日帰り時刻を表記 BY zyz END
	// 2019/03/31 部屋タイプにより、店舗情報を出力対応（パラメータで切り替え可能） BY zyz BEGIN
	private Boolean isApplicationFormShopLogoFlg{get{return CommConst.APPOTION_APPLICATIONFORMSHOPLOGO_FLG;}}
	// 2019/03/31 部屋タイプにより、店舗情報を出力対応（パラメータで切り替え可能） BY zyz END
	// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
	public static String mrStr{get;set;}
	public Boolean RespectFlg{get;set;}
	// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
	
	// 2016/01/28 コメント内容は自動改行 BEGIN
	// 消費税率：取得の予約データの初め見積明細の消費税＞０の税を利用して、設定する
	public transient Decimal taxRate{get; private set;}
    // 集計情報を統計
	public transient SummaryInfo summaryInf{get;private set;}
	// 画面表示情報を格納変数
	public transient List<OnePageInfo> allPageList{get; private set;}
	// 画面の「小計」項目の数値は表示・非表示制御
	public Boolean isShowAmountVal{get; private set;}
	// 部屋番号列を表示・非表示制御
	public Boolean isShowRoomFlg{get; private set;}
	// 2019/05/31 増税仮BUG FIX WGCH BEGIN
	public static CommLogicProcess.TaxIncMstInfo info{get{ if(info == null) info = CommLogicProcess.getTaxIncMstInfo(); return info;}}
	// 2019/05/31 増税仮BUG FIX WGCH END
    // 2021/07/30 #JP10785 by zy BEGIN
    public ApplicationFormPDFExt1(){}
    // 2021/07/30 #JP10785 by zy END
	// ******************************
	// 予約画面　OR　宿帳　から画面を開く
	// ******************************
	public ApplicationFormPDFExt1(ApexPages.StandardController controller){
		// 予約IDを取得、設定を行う
		leadId = ApexPages.currentPage().getParameters().get('id');
		// 店舗コード
		shopCode = CommUtils.nullTobLank(ApexPages.currentPage().getParameters().get('shopcd'));
		// 2019/03/31 部屋タイプにより、店舗情報を出力対応（パラメータで切り替え可能） BY zyz BEGIN
		if(CommUtils.isBLank(shopCode)){
			shopCode = getTypeOfRoom();
		}
		/*
		if (CommUtils.isBLank(shopCode)) {
		shopCode = UserUtil.CurrentUser.ShopCode__c;
		}
		*/
		// 2019/03/31 部屋タイプにより、店舗情報を出力対応（パラメータで切り替え可能） BY zyz END
		// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
		RespectFlg = CommConst.RESPECT_ISSHOW_FLG;
		mrStr = '';
		if(RespectFlg) mrStr = CommUtils.nullToBlank(ApexPages.currentPage().getParameters().get('mr'));
		// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
		// レイアウトコード
		layoutCode = ApexPages.currentPage().getParameters().get('lc');
		if (CommUtils.isBLank(layoutCode)) layoutCode = layoutType2A4;
        // 2015/07/29 部屋番号項目情報を表示／非表示制御
		isShowRoomFlg = ApexPages.currentPage().getParameters().containsKey('showroom');
	}
	/**
	* PDF出力情報を取得、設定を行う
	**/
	public void initPdf() {
		// XML定義情報を取得する
		String xmlConfigName = 'ApplicationFormPdfConfig';
		oXmlInfo = new XmlConfigInfo(CommXmlUtils.parseXmlDoc(xmlConfigName, shopCode));
		// 2021/07/30 #JP10785 by zy BEGIN
		if(layoutCode == layoutType6) {
			pageformat = oXmlInfo.pageformat;
		}
		// 引き渡す情報を取得する
		paraMap = ApexPages.currentPage().getParameters();
		// 2021/07/30 #JP10785 by zy END
		String commentKey = 'comment';
		// 2015/12/03 換行 Fix BEGIN
		// 2016/01/28 コメント内容は自動改行 BEGIN
		// コメント自動改行制御 = TRUEの場合、指定の文字数により、自動改行を行う
		if (isCommentAutoBreakFlg) {
			if (paraMap.containsKey(commentKey)) {
				if(layoutCode == layoutType2A4) pComment = CommUtils.nullToBlank(CommRepUtils.getPdfMaxShowStringNew(paraMap.get(commentKey),4,40));
				// if(layoutCode == layoutType3B5) pComment = CommUtils.nullToBlank(CommRepUtils.getPdfMaxShowStringNew(paraMap.get(commentKey),4,20));
				if(layoutCode == layoutType4A4) pComment = CommUtils.nullToBlank(CommRepUtils.getPdfMaxShowStringNew(paraMap.get(commentKey),9,40));
				if(layoutCode == layoutType5A4) pComment = CommUtils.nullToBlank(CommRepUtils.getPdfMaxShowStringNew(paraMap.get(commentKey),4,40));
				// 2021/07/30 #JP10785 by zy BEGIN
                if(layoutCode == layoutType6) {
                	pComment = CommUtils.nullToBlank(CommRepUtils.getPdfMaxShowStringNew(paraMap.get(commentKey),4,40));
                }
				// 2021/07/30 #JP10785 by zy END
			} else {
				// pComment = CommUtils.nullToBlank(CommRepUtils.getPdfMaxShowStringNew(oXmlInfo.bComment,4,20)).trim();
				if(layoutCode == layoutType2A4) pComment = CommUtils.nullToBlank(CommRepUtils.getPdfMaxShowStringNew(oXmlInfo.bComment,4,40));
				// if(layoutCode == layoutType3B5) pComment = CommUtils.nullToBlank(CommRepUtils.getPdfMaxShowStringNew(oXmlInfo.bComment,4,20));
				if(layoutCode == layoutType4A4) pComment = CommUtils.nullToBlank(CommRepUtils.getPdfMaxShowStringNew(oXmlInfo.bComment,9,40));
				if(layoutCode == layoutType5A4) pComment = CommUtils.nullToBlank(CommRepUtils.getPdfMaxShowStringNew(oXmlInfo.bComment,4,40));
			}
		} else {
			outLeadInf = new Lead__c();
			if (paraMap.containsKey(commentKey)) {
				outLeadInf.QuotationComment__c = CommUtils.nullToBlank(paraMap.get(commentKey));
			} else {
				outLeadInf.QuotationComment__c = CommUtils.nullToBlank(oXmlInfo.bComment);
			}
		}
		// 2016/01/28 コメント内容は自動改行 END
		// 2015/12/03 換行 Fix END
		// 2021/07/30 #JP10785 by zy BEGIN
		if(layoutCode == layoutType6) {
			leadFieldSet = new Set<String>();
	        if (!CommUtils.isBlank(oXmlInfo.customizeHtml)) {
	        	Set<String> exitSet = new Set<String>(String.join(new List<String>(nuplicateSet),',').toLowerCase().split(','));
	            excludeSet = new Set<String>(String.join(new List<String>(excludeSet),',').toLowerCase().split(','));
	            try{
	                // 拆分 _$$ 
	                String[] lst = oXmlInfo.customizeHtml.split('_\\$\\$');
	                for(String s : lst){
	                    // 拆分 $$_
	                    String[] lit = s.split('\\$\\$_');
	                    if (lit.size() >= 2) {
	                        if (leadFieldSet.contains(lit[1])) {
	                            continue;
	                        }
	                        if (excludeSet.contains(CommUtils.nullTOBlank(lit[1]).toLowerCase())) {
	                            continue;
	                        }
	                        leadFieldSet.add(lit[1]);
	                        if (!exitSet.contains(CommUtils.nullTOBlank(lit[1]).toLowerCase())) {
	                        	// 2021/07/30 #13756 bug fixed by zy BEGIN
	                            nuplicateSet.add(lit[1]);
	                            // 2021/07/30 #13756 bug fixed by zy END
	                        }
	                    }
	                }
	            } catch(Exception e){}
	        }
	        customeStyleStr = oXmlInfo.customeStyleStr;
    	}
		// 2021/07/30 #JP10785 by zy END
		try{
			// 予約情報を取得する
			queryLeadInfo(leadId);
		} catch(Exception e){

		}
		
	}
	/**
	* PDF情報を取得を行う
	* leadId : 画面から取得した予約ID
	**/
    private void queryLeadInfo(String leadId) {
		// 小数点定義情報
		Integer pointlen = CommUtils.getPointLen();
        // 2021/07/30 #JP10785 by zy BEGIN
        List<Lead__c> leadInfLst = new List<Lead__c>();
        if(layoutCode == layoutType6) {
        	// 該当予約情報により、同じ予約インデックスIDの関連有効な予約情報を全部取得する
	        String leadQuery = 'select ' + String.join(new List<String>(nuplicateSet), ',') + ' from Lead__c where Id = :leadId And CancelBool__c != ' + CommConst.LEAD_ST_CANCEL_FLG;
	        leadInfLst = database.query(leadQuery);
        } else {
        	leadInfLst = [select id, LeadIndexRef__c, LeadIndexSubId__c,RoomGroupNo__c, EntryTime__c,
										Field348__c,			//乗 り 物
										ReservedContact__c,		//受 付 担 当
										ReservedDate__c,		//受 付 日
										Field4__c,				//到 着 時 間
										LastModifiedBy.Name,	// 最終更新者
										
										Relcontact__c,
										Relcontact__r.Name,
										
										Relcontact__r.MailingPostalCode,
										Relcontact__r.MailingStreet, 
										Relcontact__r.MailingState,
										Relcontact__r.MailingCountry,
										Relcontact__r.MailingCity,
										// 連絡電話番号
										Relcontact__r.Phone,
										Relcontact__r.Phone2__c, 
										Relcontact__r.MobilePhone,
										Relcontact__r.HomePhone,
										// Fax
										Relcontact__r.Fax,
										Relcontact__r.Fax2__c,
										// 予約インデックス情報
										LeadIndexRef__r.Name,	//　予約番号
										LeadIndexRef__r.contactRef__r.Name,	//　お客様名
										// 2019/03/31 日帰り時刻を表記 BY zyz BEGIN
										Field3__c,			// 出発時刻
										Departure__c,		// 出発日
										// 2019/03/31 日帰り時刻を表記 BY zyz END
										// ご利用日時
										LeadIndexRef__r.EntryDate__c,
										LeadIndexRef__r.DepartureDate__c
									from Lead__c 
									where Id = :leadId And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG  ];
        }
		// 2021/07/30 #JP10785 by zy END
		// 既存有効な予約データが見つからない場合
		if (leadInfLst.isEmpty()) {
			//該当予約データが見つかりません。
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_002_0080));
			return;
		}
		// 消費税率初期値設定を行う
		taxRate = 0;
		// 入力情報により、関連の予約情報を一括変更を行う
		// 泊数、最後の出発日変更対応を行う
		// 同じグループNO、同じSUBINDEXの予約データは連動更新を行う[同じ予約インデックス、同じ予約インデックスSUB、]
		// 2020/06/30 予約確認書の集計対象がカスタマイズできるように改善対応 BY zyz BEGIN
		/*
		List<Lead__c> leads = [select id, Name, LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c
			from Lead__c 
			where LeadIndexRef__c = :leadInfLst[0].LeadIndexRef__c 
			And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 
			Order By EntryTime__c ] ;
			*/
		Integer cancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
		String leadIndexId = leadInfLst[0].LeadIndexRef__c;
		String queryLeadStr = ' select id, Name, LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c from Lead__c ' +
								' where LeadIndexRef__c = :leadIndexId And CancelBool__c != :cancelFlg ';
		if(!CommUtils.isBlank(oXmlInfo.bfLeadWhere)) queryLeadStr += ' and ( ' +oXmlInfo.bfLeadWhere +' ) ';
		queryLeadStr += ' Order By EntryTime__c ';
		List<Lead__c> leads = DataBase.query(queryLeadStr);
		// 既存有効な予約データが見つからない場合
		if (leads.isEmpty()) {
			//該当予約データが見つかりません。
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_002_0080));
			return;
		}
		// 2020/06/30 予約確認書の集計対象がカスタマイズできるように改善対応 BY zyz END
		// 有効な予約ID情報を格納する
		Set<Id> allValLeadIds = new set<Id>();
		// 初日の予約情報を取得する【予約インデックス+'_'+予約インデックスSUB+'_'+グループNO】
		Set<String> firstLeadIdSet = new Set<String>();
		Set<Id> targetLeadIds = new Set<Id>();
		for (Lead__c lead : leads) {
			// 全部関連の予約ID情報を格納する
			allValLeadIds.add(lead.Id);
			// 初日のみ予約情報
			String key = lead.LeadIndexRef__c + '_' + CommUtils.nullToBlank(lead.LeadIndexSubId__c) + '_' + CommUtils.nullToBlank(lead.RoomGroupNo__c);
			if (firstLeadIdSet.contains(key)) continue;
			firstLeadIdSet.add(key);
			targetLeadIds.add(lead.Id);
		}
    	// 2013/01/11 EDIT  Rroom__r.Rnumber__c -> Rroom__r.Name
		List<Lead__c> rsLeads = [  Select Id, Name, 
								Rroom__r.Name, Relcontact__c, Relcontact__r.Name,
								LeadIndexSubId__c, LeadIndexRef__c, RoomGroupNo__c,
								EntryTime__c, Departure__c,
								Morimongn__c,			// 食数
								StayPersons__c, Mans__c, Femails__c,ChildFA__c,Childs__c,ChildC__c,ChildD__c,ChildE__c,ChildF__c, //  人數
								//Field348__c,			//乗 り 物
								//ReservedContact__c,		//受 付 担 当
								//ReservedDate__c,		//受 付 日
								//Field4__c,				//到 着 時 間
								refTypeOfRooms__r.Name	// 部屋タイプ
								//LastModifiedBy.Name		// 最終更新者
								/*
								Relcontact__r.MailingPostalCode,
								Relcontact__r.MailingStreet, 
								Relcontact__r.MailingState,
								Relcontact__r.MailingCountry,
								Relcontact__r.MailingCity,
								// 連絡電話番号
								Relcontact__r.Phone,
								Relcontact__r.Phone2__c, 
								Relcontact__r.MobilePhone,
								Relcontact__r.HomePhone,
								// Fax
								Relcontact__r.Fax,
								Relcontact__r.Fax2__c,
								// 予約インデックス情報
								LeadIndexRef__r.Name	//　予約番号
								LeadIndexRef__r.LeadName__c,	// 予約名
								LeadIndexRef__r.contactRef__r.Name,	//　お客様名
								// ご利用日時
								LeadIndexRef__r.EntryDate__c,LeadIndexRef__r.DepartureDate__c,
								
								// ご住所
								LeadIndexRef__r.contactRef__r.MailingPostalCode,
								LeadIndexRef__r.contactRef__r.MailingStreet,
								LeadIndexRef__r.contactRef__r.MailingState,
								LeadIndexRef__r.contactRef__r.MailingCountry,
								LeadIndexRef__r.contactRef__r.MailingCity,
								// 連絡電話番号
								LeadIndexRef__r.contactRef__r.Phone,
								LeadIndexRef__r.contactRef__r.Phone2__c,
								LeadIndexRef__r.contactRef__r.MobilePhone,
								LeadIndexRef__r.contactRef__r.HomePhone,
								LeadIndexRef__r.contactRef__r.Fax,		//fax
								LeadIndexRef__r.contactRef__r.Fax2__c	//fax2
								*/
                                From Lead__c where Id in :targetLeadIds];
                                
        // 2015/07/08 支払種別から関連の支払メディアに変更情報を取得する
        Map<String, String> paymentTypeToMediaLabMap = new Map<String, String>();
        // 関連の予約の明細情報を取得
        List<BookingEstimateItem__c> estItems = new List<BookingEstimateItem__c>();
        // 2018/01/24 予約確認書の明細欄に日付を表示したい zyz BEGIN
        map<string,BookingEstimateItem__c> sortEstInfMap = new map<string, BookingEstimateItem__c>();
        // 2018/01/24 予約確認書の明細欄に日付を表示したい zyz END
        // 明細表示行数は０の場合、明細非表示する
        if (oXmlInfo.bMaxRows > 0) {
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			if(!isReducedTaxFlg){
				estItems = [
							Select id, name, X2_1__c, Tankanonetax__c, Amount__c,TaxRate__c, UnitPriceDefKbCal__c,Total__c, 
	                        			SpecialTax__c,GoukeinoneTax__c,UnitPrice__c, ProductName__c,SpTotal__c ,ServiceRate__c,
	                        			// 2018/01/15 予約確認書の明細欄に日付を表示したい zyz BEGIN
	                        			UseDate__c,RowNo__c,
	                        			// 2018/01/15 予約確認書の明細欄に日付を表示したい zyz END
	                        			refAccountMaster__r.Field3__c,ActionType__c,PaymentType__c,refBooking__r.EntryTime__c,refBooking__r.Rroom__r.Name
	                        			// 2018/11/29 BugFix [会計の売上計上日設定区分]が２の場合、SObject row was retrieved via SOQL without querying the requested field: ps__Lead__c.ps__Departure__c不具合修正 WSQ BEGIN
	                        			,refBooking__r.Departure__c
	                        			// 2018/11/29 BugFix [会計の売上計上日設定区分]が２の場合、SObject row was retrieved via SOQL without querying the requested field: ps__Lead__c.ps__Departure__c不具合修正 WSQ END
	                        			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
	                        			// ,(select UnitPrice__c from ParentBookingItemRef__r where (TaxRate__c = null OR TaxRate__c = 0) And ParentBookingItemRef__r.ActionType__c = :CommConst.PROD_ACTION_TYPE_PL)
	                        			,(select UnitPrice__c, TaxRate__c, ActionType__c, InvoiceNoShowFlg__c from ParentBookingItemRef__r where (TaxRate__c = null OR TaxRate__c = 0) And ParentBookingItemRef__r.ActionType__c = :CommConst.PROD_ACTION_TYPE_PL)
	                        			// 2019/07/30 軽減税率機能対応 WGCH END
	                        From BookingEstimateItem__c
							Where Accountoutside__c = 1 
								And refBooking__c in :allValLeadIds 
							// 2017/12/13 見積明細非表示機能対応 WGCH BEGIN
							And InvoiceNoShowFlg__c = false
							// 2017/12/13 見積明細非表示機能対応 WGCH END
							// 2018/01/15 予約確認書の明細欄に日付を表示したい zyz BEGIN
	                        Order By refBooking__r.EntryTime__c ,RowNo__c, Name
	                        // 2018/01/15 予約確認書の明細欄に日付を表示したい zyz END
							];
				// 2018/01/24 予約確認書の明細欄に日付を表示したい zyz BEGIN
				for(BookingEstimateItem__c s : estItems){
					sortEstInfMap.put(getSortKey(s),s);
				}
			} else {
				String PROD_ACTION_TYPE_PL = CommConst.PROD_ACTION_TYPE_PL;
				String queryStr = ' Select id, name, X2_1__c, Tankanonetax__c, Amount__c, TaxRate__c, UnitPriceDefKbCal__c, Total__c, SpecialTax__c, GoukeinoneTax__c, UnitPrice__c, ProductName__c, SpTotal__c , ServiceRate__c, UseDate__c, RowNo__c, refAccountMaster__r.Field3__c, ActionType__c, PaymentType__c, refBooking__r.EntryTime__c, refBooking__r.Rroom__r.Name, AccountOutside__c, ParentBookingItemRef__c, ' +
								  ' refBooking__r.Departure__c, ' +
								  // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
								  ' OptionPlanKey__c, ' +
								  // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
								  ' ParentBookingItemRef__r.TaxRate__c,ParentBookingItemRef__r.ActionType__c, ParentBookingItemRef__r.InvoiceNoShowFlg__c, ParentBookingItemRef__r.UnitPrice__c ' +
								  ' From BookingEstimateItem__c Where refBooking__c in :allValLeadIds And InvoiceNoShowFlg__c = false ' ;
				queryStr += ' Order By refBooking__r.EntryTime__c ,RowNo__c, Name ' ;
				estItems = DataBase.query(queryStr);
				// 2019/10/30 軽減税率割合モード機能対応 WGCH BEGIN
				/*
				// 值引行 金额合计 计算 初始化
				disRowData = new DisAmountRowData();
				// 合计值 金额合计 计算 初始化
				sumRowData = new SumAmountRowData();
				pBrkTranItemMap = new Map<String, List<BookItem>>();
				planHeaderMap = new Map<String, CommUtils.ProductInfo>();
				// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
				disRowDataMap = new Map<Decimal, DisAmountRowData>();
				// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
				*/
				reducedTaxInit();
				// 2019/10/30 軽減税率割合モード機能対応 WGCH END
				// 格納用変数クリアする
				// BillSimpleHelp help = new BillSimpleHelp(shopCode);
				// 支払種別ー＞支払メデイア名変換情報取得
				// Map<String, String> PAYMENT_MATCH_MAP = help.getPaymentTypeToMediaLabMap();
				map<string,CommLogicProcess.HotelTaxDefineInfo> hotelTaxMap = CommLogicProcess.getHotelTaxDefInstance();
				// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
				Map<String, PlanTaxBrkInfo> pBrkInfoMap = new Map<String, PlanTaxBrkInfo>();
				// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
				CommLogicProcess.OptionPlanInfo optionItem = null;
				if(isReducedTaxFlg && CommConst.OPTION_MODE == CommConst.OPTION_MODE_ON){
					optionItem = CommLogicProcess.getOptionPlanInfo(estItems);
				}
				// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
				if(!planBrkToHeaderCalFlg){
					for (BookingEstimateItem__c sobj : estItems) {
						// 合成明细Key
						String key = sobj.ParentBookingItemRef__c;
						if(CommUtils.isBlank(key)) continue;
						// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
						// 2020/05/29 bug fixed 6445 WGCH BEGIN
						if(optionItem != null){
							if(!optionItem.planEstIdSet.isEmpty() && !optionItem.planEstIdSet.contains(key)) continue;
							if(optionItem.planHeaderKeyMap.containsKey(key)){
								String planHeaderNumKey = optionItem.planHeaderKeyMap.get(key);
								sobj.Amount__c = CommUtils.nullToZero(optionItem.planHeaderNumMap.get(planHeaderNumKey));
							}
						}
						// 2020/05/29 bug fixed 6445 WGCH END
						// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
						if(!pBrkInfoMap.containsKey(key)) pBrkInfoMap.put(key, new PlanTaxBrkInfo());
						PlanTaxBrkInfo p = pBrkInfoMap.get(key);
						if(CommUtils.nullToZero(sobj.TaxRate__c) > 0) p.hasTaxUnitPrice += CommUtils.nullToZero(sobj.UnitPrice__c);
						else if(CommUtils.nullToZero(sobj.TaxRate__c) == 0) p.noTaxUnitPrice += CommUtils.nullToZero(sobj.UnitPrice__c);
						// Plan对应—BRKLst 初始化
						if(!pBrkTranItemMap.containsKey(key)) pBrkTranItemMap.put(key, new List<BookItem>());
					}
					for (BookingEstimateItem__c sobj : estItems) {
						if(pBrkInfoMap.containsKey(sobj.Id)){
							PlanTaxBrkInfo p = pBrkInfoMap.get(sobj.Id);
							Decimal hasTaxUnitPrice = p.hasTaxUnitPrice;
							Decimal noTaxUnitPrice = p.noTaxUnitPrice;
							// 2020/05/29 bug fixed 6451 WGCH BEGIN
							String key = sobj.Id;
							if(optionItem != null){
								if(!optionItem.planEstIdSet.isEmpty() && !optionItem.planEstIdSet.contains(key)) continue;
								if(optionItem.planHeaderKeyMap.containsKey(key)){
									String planHeaderNumKey = optionItem.planHeaderKeyMap.get(key);
									sobj.Amount__c = CommUtils.nullToZero(optionItem.planHeaderNumMap.get(planHeaderNumKey));
								}
							}
							// 2020/05/29 bug fixed 6451 WGCH END
							// 数量
							Decimal qty = CommUtils.nullToZero(sobj.Amount__c);
							CommUtils.ProductInfo planPriceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(sobj.UnitPriceDefKbCal__c));
							// 当前行含税单价计算处理
							planPriceInfo.process(hasTaxUnitPrice, CommUtils.nullToZero(sobj.Amount__c), CommUtils.nullToZero(sobj.TaxRate__c), CommUtils.nullToZero(sobj.ServiceRate__c));
							// planHeader 数据集合
							if(!planHeaderMap.containsKey(sobj.Id)) planHeaderMap.put(sobj.Id, new CommUtils.ProductInfo(CommUtils.nullToIntZero(sobj.UnitPriceDefKbCal__c)));
							CommUtils.ProductInfo headerPriceInfo = planHeaderMap.get(sobj.Id);
							// planHeader 数据合计
							headerPriceInfo.getAddPriceInfo(planPriceInfo);
							// BRK行—单价
							// Decimal unitPrice = planPriceInfo.unitPriceTax;
							// BRK行—消费税
							//Decimal taxUnitPrice = planPriceInfo.priceTax;
							// BRK行—单价-赋值
							//sobj.UnitPrice__c = unitPrice;
							// BRK行—合计值-赋值
							//sobj.SpTotal__c = unitPrice * qty + CommUtils.nullToZero(sobj.SpecialTax__c);
							// BRK行—数据
							BookItem item = new BookItem(sobj, 0);
							item.unitPrice = planPriceInfo.unitPriceTax;
							item.taxRate = CommUtils.nullToZero(sobj.TaxRate__c) / 100;
							item.quantity = qty;
							item.taxUnitPrice = planPriceInfo.priceTax;
							// 课税处理
							// 合计板块数据集计处理
							addDetailToMapFun(item, 0);
							if(noTaxUnitPrice > 0){
								// 当前行不含税单价计算处理
								planPriceInfo.process(noTaxUnitPrice, CommUtils.nullToZero(sobj.Amount__c), 0, CommUtils.nullToZero(sobj.ServiceRate__c));
								// planHeader 数据合计
								headerPriceInfo.getAddPriceInfo(planPriceInfo);
								BookItem noTaxItem = new BookItem(new BookingEstimateItem__c(), 0);
								noTaxItem.unitPrice = planPriceInfo.unitPriceTax;
								noTaxItem.taxRate = 0;
								noTaxItem.quantity = qty;
								noTaxItem.taxUnitPrice = 0;
								addDetailToMapFun(noTaxItem, CommUtils.nullToZero(planPriceInfo.unitPriceTax) * qty);
							}
							//item.s.UnitPrice__c = CommUtils.nullToZero(item.unitPrice) + CommUtils.nullToZero(planPriceInfo.unitPriceTax);
							//item.s.SpTotal__c = item.s.UnitPrice__c * qty + CommUtils.nullToZero(sobj.SpecialTax__c);
							//item.unitPrice += planPriceInfo.unitPriceTax;
							//item.amount += planPriceInfo.unitPriceTax * qty;
							// 非课税处理
							// 合计板块数据集计处理
							// addDetailToMapFun(new BookItem(new BookingEstimateItem__c(), 0), CommUtils.nullToZero(planPriceInfo.unitPriceTax) * qty);
						}
					}
				}
				// 2019/10/02 PlanHeader算法切换对应 WGCH END
				for (BookingEstimateItem__c sobj : estItems) {
					// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
					if(!planBrkToHeaderCalFlg) continue;
					// 2019/10/02 PlanHeader算法切换对应 WGCH END
					// 集计值引
					// if(PAYMENT_MATCH_MAP.get(sobj.PaymentType__c) == CommConst.MEDIA_TYPE_12 ) amoutIncDiscontAll = CommUtils.nullToZero(amoutIncDiscontAll) + CommUtils.nullToZero(sobj.SpTotal__c);
					// 合成明细Key
					String key = sobj.ParentBookingItemRef__c;
					if(CommUtils.isBlank(key)) continue;
					if(sobj.ParentBookingItemRef__r.InvoiceNoShowFlg__c == true) continue;
					// 2020/05/29 bug fixed 6451 WGCH BEGIN
					if(optionItem != null){
						if(!optionItem.planEstIdSet.isEmpty() && !optionItem.planEstIdSet.contains(key)) continue;
						if(optionItem.planHeaderKeyMap.containsKey(key)){
							String planHeaderNumKey = optionItem.planHeaderKeyMap.get(key);
							sobj.Amount__c = CommUtils.nullToZero(optionItem.planHeaderNumMap.get(planHeaderNumKey));
						}
					}
					// 2020/05/29 bug fixed 6451 WGCH END
					// 数量
					Decimal qty = CommUtils.nullToZero(sobj.Amount__c);
					CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(sobj.UnitPriceDefKbCal__c));
					// 元の単価から、税抜金額を外して、税込み金額を計算する
					CommLogicProcess.HotelTaxInfo hotelTaxItem = CommLogicProcess.getHotelTaxInfo(CommUtils.nullToBlank(shopCode), CommUtils.nullToBlank(sobj.ActionType__c), CommUtils.nullToZero(sobj.UnitPrice__c), qty, sobj.TaxRate__c, sobj.ServiceRate__c, priceInfo, hotelTaxMap);
					// 重置最新的PriceInfo
					priceInfo = hotelTaxItem.priceInfo;
					// planHeader 数据集合
					if(!planHeaderMap.containsKey(key)) planHeaderMap.put(key, new CommUtils.ProductInfo(CommUtils.nullToIntZero(sobj.UnitPriceDefKbCal__c)));
					CommUtils.ProductInfo headerPriceInfo = planHeaderMap.get(key);
					// planHeader 数据合计
					headerPriceInfo.getAddPriceInfo(priceInfo);
					// BRK行—INFO赋值处理
					// BRK行—单价
					Decimal unitPrice = priceInfo.unitPriceTax;
					// BRK行—消费税
					Decimal taxUnitPrice = priceInfo.priceTax;
					// BRK行—单价-赋值
					sobj.UnitPrice__c = unitPrice;
					// BRK行—合计值-赋值
					sobj.SpTotal__c = unitPrice * qty + CommUtils.nullToZero(sobj.SpecialTax__c);
					// BRK行—数据
					BookItem item = new BookItem(sobj, 0);
					item.unitPrice = unitPrice;
					item.amount = unitPrice * qty;
					// BRK行—消费税-赋值
					item.taxUnitPrice = taxUnitPrice;
					// 合计板块数据集计处理
					addDetailToMapFun(item, -(item.specialTax));
					// Plan对应—BRKLst
					if(!pBrkTranItemMap.containsKey(key)) pBrkTranItemMap.put(key, new List<BookItem>());
					pBrkTranItemMap.get(key).add(item);
				}
				// 集计所有的明细金额
				for (BookingEstimateItem__c sobj : estItems) {
					if(!CommUtils.isBlank(sobj.ParentBookingItemRef__c)) continue;
					// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
					if(optionItem != null){
						if(!optionItem.planEstIdSet.isEmpty() && !optionItem.planEstIdSet.contains(sobj.Id)) continue;
						if(optionItem.planHeaderKeyMap.containsKey(sobj.Id)){
		        			String planHeaderNumKey = optionItem.planHeaderKeyMap.get(sobj.Id);
		        			sobj.Amount__c = CommUtils.nullToZero(optionItem.planHeaderNumMap.get(planHeaderNumKey));
		        			sobj.SpecialTax__c = CommUtils.nullToZero(optionItem.planHeaderTaxMap.get(planHeaderNumKey));
						}
					}
					// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
					if(sobj.Accountoutside__c == 1) sortEstInfMap.put(getSortKey(sobj),sobj);
				}
			}
			// 2019/07/30 軽減税率機能対応 WGCH END
            List<String> sortList = new List<String>(sortEstInfMap.keySet());
            sortList.sort();
            estItems = new List<BookingEstimateItem__c>();
            for (String key : sortList){
            	estItems.add(sortEstInfMap.get(key));
            }
			// 2018/01/24 予約確認書の明細欄に日付を表示したい zyz END
			// 2015/07/08 支払種別から関連の支払メディアに変更情報を取得する
			paymentTypeToMediaLabMap = (new BillSimpleHelp(UserUtil.CurrentUser.ShopCode__c)).getPaymentTypeToMediaLabMap();
        }
		
        
        // 予約インデックス情報
        // 予約名
        // 発行日（システム日）
        // ご住所/連絡電話番号
        // 予約番号（予約インデックスの予約番号）
        // 利用日時（予約インデックスの開始日と終了日）
        // 泊数（予約インデックスの泊数
        // 部屋数：
        // 食数??
        // 宿泊人數（全ての予約情報から集計を行う

        // 集計情報
        summaryInf = new SummaryInfo(oXmlInfo.bBathProdCdLst);
        // ページ毎情報格納用変数
        OnePageInfo onePage = null;
        // 既存の明細情報を格納する
        List<BookItem> dsList = new List<BookItem>();
        // ページ毎に情報を設定する
        for (BookingEstimateItem__c estItem : estItems) {
        	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
        	// 数量
        	Decimal qty = CommUtils.nullToZero(estItem.Amount__c);
        	Decimal unitPrice = 0;
        	Decimal taxUnitPrice = 0;
    		if(isReducedTaxFlg && estItem.ActionType__c != CommConst.PROD_ACTION_TYPE_AR && estItem.ActionType__c != CommConst.PROD_ACTION_TYPE_PY){
    			map<string,CommLogicProcess.HotelTaxDefineInfo> hotelTaxMap = CommLogicProcess.getHotelTaxDefInstance();
    			CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(estItem.UnitPriceDefKbCal__c));
    			// 元の単価から、税抜金額を外して、税込み金額を計算する
    			CommLogicProcess.HotelTaxInfo hotelTaxItem = CommLogicProcess.getHotelTaxInfo(CommUtils.nullToBlank(shopCode), CommUtils.nullToBlank(estItem.ActionType__c), CommUtils.nullToZero(estItem.UnitPrice__c), qty, estItem.TaxRate__c, estItem.ServiceRate__c, priceInfo, hotelTaxMap);
    			priceInfo = hotelTaxItem.priceInfo;
    			if(planHeaderMap != null && planHeaderMap.containsKey(estItem.Id)) {
    				priceInfo = planHeaderMap.get(estItem.Id);
    			}
    			unitPrice = priceInfo.unitPriceTax;
    			taxUnitPrice = priceInfo.priceTax;
    		}
    		// 2019/07/30 軽減税率機能対応 WGCH END
    		// クラス化
    		BookItem detailItem = new BookItem(estItem, pointlen);
    		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
    		if(isReducedTaxFlg && estItem.ActionType__c != CommConst.PROD_ACTION_TYPE_AR && estItem.ActionType__c != CommConst.PROD_ACTION_TYPE_PY){
    			detailItem.s.UnitPrice__c = unitPrice;
    			detailItem.s.SpTotal__c = unitPrice * qty + CommUtils.nullToZero(detailItem.s.SpecialTax__c);
    			detailItem.unitPrice = unitPrice;
    			detailItem.amount= unitPrice * qty;
    			detailItem.taxUnitPrice = taxUnitPrice;
    		}
    		// 2019/07/30 軽減税率機能対応 WGCH END
    		// 合計値集計処理
    		summaryInf.addItem(detailItem, paymentTypeToMediaLabMap);
    		// 入湯税商品の場合、表示対象外
    		if (summaryInf.isBathProd(detailItem.productCd)) {
    			// 件数合計
    			continue;
    		}
    		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
    		if(isReducedTaxFlg){
    			// noTaxUnitPriceSum => 当前plan 明细里的非课税合计金额 【如果当前不是plan 或 plan明细里没有 非课税商品  它就=0】
		    	if(estItem.ActionType__c != CommConst.PROD_ACTION_TYPE_PL) addDetailToMapFun(detailItem, 0);
		    	else addDetailToMapFun(new BookItem(new BookingEstimateItem__c(), pointlen), CommUtils.nullToZero(estItem.SpecialTax__c));
		    	// 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH BEGIN
		    	if(estItem.ActionType__c == CommConst.PROD_ACTION_TYPE_PL && pBrkTranItemMap != null && !pBrkTranItemMap.containsKey(estItem.Id)) addDetailToMapFun(detailItem, 0);
		    	// 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH END
    		}
    		// 2019/07/30 軽減税率機能対応 WGCH END
    		// 2021/07/30 #JP10785 by zy BEGIN
    		if(layoutCode == layoutType6) {
    			summaryInf.totalAmount += qty;
    		}
    		// 2021/07/30 #JP10785 by zy END
			// 消費税率設定を行う
			if (taxRate == 0 && estItem.TaxRate__c > 0) taxRate = estItem.TaxRate__c;
			// 改ページ用情報格納
			dsList.add(detailItem);
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			if(isPlanBrkShowFlg && pBrkTranItemMap != null && pBrkTranItemMap.containsKey(estItem.Id)){
				for(BookItem pItem : pBrkTranItemMap.get(estItem.Id)){
					pItem.pBrkDNFlg = true;
					dsList.add(pItem);
				}
			}
			// 2019/07/30 軽減税率機能対応 WGCH END
        }

        // 特別税が存在する場合、特別税は明細に追加する
        if (summaryInf.amoutSpecialIncTax > 0 ) {
			// 宿泊税情報
            BookingEstimateItem__c item = new BookingEstimateItem__c(
               X2_1__c = '宿泊税',
               ProductName__c = '宿泊税',
               Amount__c = 1,
               SpTotal__c = summaryInf.amoutSpecialIncTax,     // 宿泊税総金額表示するため、仮に設定を行う
               UnitPrice__c = summaryInf.amoutSpecialIncTax
            );
            BookItem detailItem = new BookItem(item, pointlen);
	    	// 合計値集計処理
    		summaryInf.addItem(detailItem, paymentTypeToMediaLabMap);
            dsList.add(detailItem);
        }
        // 消費税率は０の場合、Default値再設定を行う
        if (taxRate == 0) taxRate = CommUtils.getTaxRate(leadInfLst[0].EntryTime__c.date());
        // 小計項目値表示・非表示制御（表示の明細件数は０の場合、非表示する)
        isShowAmountVal = (dsList.size() > 0);
 		// 消費税金額を計算する
 		//summaryInf.amoutTax = CommUtils.RoundProcess(summaryInf.amoutPriceForTax / (1 + taxRate / 100) * (taxRate / 100), pointLen); 
        summaryInf.amoutTax = calAmoutTax(summaryInf.amoutPriceForTax, summaryInf.payedDiscount, taxRate, pointLen);
        // Header情報を設定する
        HeaderInfo locHeader = new HeaderInfo(rsLeads, oXmlInfo, leadInfLst[0]);
        // Footer情報を設定する　
        ReportLogo__c repCommInfo = CommRepUtils.getReportTitleInfo(shopCode);
        FooterInfo locFooter = new FooterInfo(repCommInfo, shopCode);
        // 表示情報格納
        allPageList = new List<OnePageInfo>();
        // 改ページ数を計算する
        Integer cntRsNum = 0;
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
        if (isReducedTaxFlg && taxRowDataMap != null){
        	processSumInfo();
        	summaryInf.amoutTax = sumRowData.taxAmount;
        }
        // 根据合计板块的行数 与 总行数合并]
        /*
        if(isReducedTaxFlg){
        	oXmlInfo.bMaxRows += 1; // 原有消费税行
			if(taxRowDataMap != null){
				oXmlInfo.bMaxRows -= taxRowDataMap.keySet().Size(); // 消费税对象行
			}
			if((disRowData.disUnitPriceSum + disRowData.disTaxAmountSum ) != 0) oXmlInfo.bMaxRows -= 1;
			if((sumRowData.amountExcTax + sumRowData.taxAmount) != 0) oXmlInfo.bMaxRows -= 1;
        }
        */
        // 2019/07/30 軽減税率機能対応 WGCH END
		// 2021/07/30 #JP10785 by zy BEGIN
        String customizeHtml = oXmlInfo.customizeHtml;
        sobjectMap = new Map<String,Map<String, Schema.DescribeFieldResult>>();
        if (!CommUtils.isBlank(customizeHtml)) {
             for(String api : leadFieldSet){
                // 获取定义字段对应值
                String valueStr = '';
                if (api == 'LastModifiedBy.Name') {
                    valueStr = leadInfLst[0].LastModifiedBy.Name;
                } else {
                  valueStr  = getFieldValue(leadInfLst[0],api);
                }
                // 替换显示的值
                customizeHtml = customizeHtml.Replace(getHtmlApiStr(api) ,valueStr);
            }
            // 予約人数
            String personNumberStr = paraMap.containsKey('pnum') ? paraMap.get('pnum') : Commutils.nullToBlank(CommUtils.nullToIntZero(locHeader.stayPeoples));
            // 大人人数
            String adultNumberStr = paraMap.containsKey('adnum') ? paraMap.get('adnum') : Commutils.nullToBlank(CommUtils.nullToIntZero(locHeader.adult));
            // 子供人数
            String childNumberStr = paraMap.containsKey('cnum') ? paraMap.get('cnum') : Commutils.nullToBlank(CommUtils.nullToIntZero(locHeader.stayChildren));
            // 部屋数
            String roomNumberStr = paraMap.containsKey('rnum') ? paraMap.get('rnum') : Commutils.nullToBlank(CommUtils.nullToIntZero(locHeader.usedRooms));
            // 宿泊数
            String nightNumberStr = paraMap.containsKey('nights') ? paraMap.get('nights') : Commutils.nullToBlank(CommUtils.nullToIntZero(locHeader.stayDays));
            customizeHtml = customizeHtml.replace(getHtmlApiStr(personNumber),personNumberStr)
                        .replace(getHtmlApiStr(adultNumber),adultNumberStr)
                        .replace(getHtmlApiStr(childNumber),childNumberStr)
                        .replace(getHtmlApiStr(roomNumber),roomNumberStr)
                        .replace(getHtmlApiStr(nightNumber),nightNumberStr)
                        // 2021/07/31 #13838 bug fixed by zy BEGIN
                        .replace(getHtmlApiStr(shopName),Commutils.nullTOBlank(locFooter.shopName))
                        .replace(getHtmlApiStr(shopPostNo),Commutils.nullTOBlank(locFooter.PostNo))
                        .replace(getHtmlApiStr(shopAddress),Commutils.nullTOBlank(locFooter.Address))
                        .replace(getHtmlApiStr(shopPhone),Commutils.nullTOBlank(locFooter.Phone))
                        .replace(getHtmlApiStr(shopFax),Commutils.nullTOBlank(locFooter.Fax))
                        .replace(getHtmlApiStr(shopEmail),Commutils.nullTOBlank(locFooter.Email))
                        .replace(getHtmlApiStr(shopWebSite),Commutils.nullTOBlank(locFooter.WebSite))
                        // 2021/07/31 #13838 bug fixed by zy END
                        // 2021/07/31 #13860 bug fixed by zy BEGIN
                        .replace(getHtmlApiStr(comment),commentHtml)
                        // 2021/07/31 #13860 bug fixed by zy END
                        .replace(getHtmlApiStr(systemDate),system.now().format(CONST_DATEFORMAT))
                        .replace(getHtmlApiStr(honorific),Commutils.nullTOBlank(mrStr));
        }
        String beforeHtml = customizeHtml.substringBefore('<ESTIMATETABLE');
        String afterHtml = customizeHtml.substringAfter('</ESTIMATETABLE>');
        String bookingEstHtml = customizeHtml.replace(beforeHtml, '').replace(afterHtml, '');
        Dom.Document estDoc = new Dom.Document();
        String otherAttr = '';
        if (!CommUtils.isBLank(bookingEstHtml)) {
             estDoc.load(bookingEstHtml);
            Dom.XmlNode estNode = estDoc.getRootElement();
            integer rowNumInt = null;
            if (estNode != null) {
                for (integer i = 0 ; i < estNode.getAttributeCount() ; i++) {
                    String key = estNode.getAttributeKeyAt(i);
                    if (key == 'rownum') {
                        rowNumInt = Commutils.nullToIntZero(CommUtils.nullTOBlank(estNode.getAttribute(key, null)));
                        if (rowNumInt != null) {
                            oXmlInfo.bMaxRows = rowNumInt;
                        }
                    } else if (key == 'colsize') {
                        String colGroupStr = CommUtils.nullTOBlank(estNode.getAttribute('colsize', null));
                        if (!CommUtils.isBlank(colGroupStr)) {
                            estColGroupStr = '';
                            for (String col : colGroupStr.split(',')){
                                estColGroupStr += '<col width="' + col + '" />';
                            }
                        }
                    } else {
                        String val = estNode.getAttribute(key,null);
                        otherAttr += ' '+ key + '="' + val + '"';
                    }
                }
            }
        }
		// 2021/07/30 #JP10785 by zy END
        // 改ページ処理を行う
        for (BookItem detailItem : dsList) {
			// 新規ページの場合
        	if (Math.mod(cntRsNum , oXmlInfo.bMaxRows) == 0) {
        		onePage = new OnePageInfo(locHeader, locFooter);
        		allPageList.add(onePage);
        		onePage.currPages = allPageList.size();
        		cntRsNum = 0;
        	}
        	onePage.addDetail(detailItem);
        	cntRsNum++;
        }
        // 取得明細情報
        if (allPageList.isEmpty()) {
        	OnePageInfo empPage = new OnePageInfo(locHeader, locFooter);
        	allPageList.add(empPage);
        }
        // 最後ページの変数を取得する
        OnePageInfo lastPage = allPageList[allPageList.size()-1];
        // 明細情報は最大行数により、足りない場合、ダミ明細情報を作成する
        Integer defaultMaxRow = oXmlInfo.bMaxRows;
        if (defaultMaxRow <= 0) defaultMaxRow = 12;
        Integer dumyLines = defaultMaxRow - lastPage.details.size();
        for (Integer i =0; i < dumyLines; i++) {
        	lastPage.addDetail(new BookItem(new BookingEstimateItem__c(), pointlen));
        }
        // 2021/07/30 #JP10785 by zy BEGIN
        if(layoutCode == layoutType6) {
        	for (integer i = 0 ; i < allPageList.size(); i++) {
	            OnePageInfo currentPage = allPageList[i];
	            currentPage.pageColumns.addAll(convertCommentPage(beforeHtml,'COMMENT'));
	            currentPage.pageColumns.add(new pageColumn(createDetailHtml(currentPage,otherAttr)));
	            currentPage.pageColumns.addAll(convertCommentPage(afterHtml,'COMMENT'));
	        }
        }
		// 2021/07/30 #JP10785 by zy END
    }
	// 消費税を計算を行う
	private Decimal calAmoutTax(Decimal pAmoutPriceForTax,Decimal pPayedDiscount , Decimal pTaxRate, Integer pointLen) {
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		if(isReducedTaxFlg) return taxUnitPriceAll;
		// 2019/07/30 軽減税率機能対応 WGCH END
  		Decimal locAmoutPriceIncTax = pAmoutPriceForTax - pPayedDiscount;
  		Decimal locTaxRate = pTaxRate / 100;
    	if (locAmoutPriceIncTax < 0) locAmoutPriceIncTax = 0;
    	return CommUtils.RoundProcess(locAmoutPriceIncTax / (1 + locTaxRate) * locTaxRate, pointLen);
	}
	// ページ毎に表示、格納用変数
	public class OnePageInfo {
		public OnePageInfo(HeaderInfo pHeader, FooterInfo pFooter) {
			header = pHeader;
			footer = pFooter;
			details = new List<BookItem>();
			currPages = 1;
	    	// 2021/07/30 #JP10785 by zy BEGIN
            customizeHtml = '';
            pageColumns = new List<PageColumn>();
	    	// 2021/07/30 #JP10785 by zy END
		}
		public HeaderInfo header{get; private set;}
		public List<BookItem> details{get; private set;}
		public void addDetail(BookItem item) {
			details.add(item);
		}
		public FooterInfo footer{get; private set;}
		// 現在表示してページ数
		public Integer currPages{get;set;}
		public Boolean isFirstPage{get{
		  return currPages == 1;
		}}
		// 2021/07/30 #JP10785 by zy BEGIN
        public List<PageColumn> pageColumns{get;private set;}
        public String customizeHtml{get;private set;}
		// 2021/07/30 #JP10785 by zy END
	}
	// 画面表示情報を格納用クラス
	public class HeaderInfo {
		public HeaderInfo(List<Lead__c> pLeads, XmlConfigInfo pXmlInfo, Lead__c firstLead) {
			// 2016/03/25 起動予約からお客様情報を取得する BEGIN
			// 予約インデックス設定の情報により、Headerに情報を表示する
			//Lead__c firstLead = pLeads[0];
			//customName = firstLead.LeadIndexRef__r.LeadName__c;
			customName = firstLead.Relcontact__r.Name;
			// 2016/03/25 起動予約からお客様情報を取得する END
			issueDate = System.now().format('yyyy.MM.dd');
			
			// 2016/03/25 起動予約からお客様情報を取得する BEGIN
			//postNo = CommUtils.nullToBlank(firstLead.LeadIndexRef__r.contactRef__r.MailingPostalCode);
			postNo = CommUtils.nullToBlank(firstLead.Relcontact__r.MailingPostalCode);
			// 2016/03/25 起動予約からお客様情報を取得する END
			// 2015/12/23 住所情報変更 BEGIN
			// 2016/03/25 起動予約からお客様情報を取得する BEGIN
			//String addCountryInfo = CommUtils.nullToBlank(firstLead.LeadIndexRef__r.contactRef__r.MailingCountry);
			String addCountryInfo = CommUtils.nullToBlank(firstLead.Relcontact__r.MailingCountry);
			// 2016/03/25 起動予約からお客様情報を取得する END
			if (layoutCode == layoutType5A4) addCountryInfo = '';
			//address = CommUtils.nullToBlank(firstLead.LeadIndexRef__r.contactRef__r.MailingCountry)
			// 2015/12/23 住所情報変更 END
			address = addCountryInfo
					// 2016/03/25 起動予約からお客様情報を取得する BEGIN
					//+ CommUtils.nullToBlank(firstLead.LeadIndexRef__r.contactRef__r.MailingState) 
					//+ CommUtils.nullToBlank(firstLead.LeadIndexRef__r.contactRef__r.MailingCity)
					//+ CommUtils.nullToBlank(firstLead.LeadIndexRef__r.contactRef__r.MailingStreet);
					+ CommUtils.nullToBlank(firstLead.Relcontact__r.MailingState) 
					+ CommUtils.nullToBlank(firstLead.Relcontact__r.MailingCity)
					+ CommUtils.nullToBlank(firstLead.Relcontact__r.MailingStreet);
					// 2016/03/25 起動予約からお客様情報を取得する END
			if (layoutCode == layoutType5A4) {
				address = CommUtils.nullToBlank(CommRepUtils.getPdfMaxShowStringNew(address,3,12));
			}
			// 電話：電話＞自宅電話＞携帯
			// 2016/03/25 起動予約からお客様情報を取得する BEGIN
			//String phoneStr = firstLead.LeadIndexRef__r.contactRef__r.Phone == null
			//					? firstLead.LeadIndexRef__r.contactRef__r.HomePhone 
			//					: firstLead.LeadIndexRef__r.contactRef__r.Phone;
			//phone = CommUtils.isBlank(phoneStr) ? firstLead.LeadIndexRef__r.contactRef__r.MobilePhone : phoneStr;
			String phoneStr = firstLead.Relcontact__r.Phone == null
								? firstLead.Relcontact__r.HomePhone 
								: firstLead.Relcontact__r.Phone;
			phone = CommUtils.isBlank(phoneStr) ? firstLead.Relcontact__r.MobilePhone : phoneStr;
			// 2016/03/25 起動予約からお客様情報を取得する END
			leadNo = firstLead.LeadIndexRef__r.Name;
	        // ご利用日時
	        if (firstLead.LeadIndexRef__r.EntryDate__c != null) {
	        	Date entryDt = firstLead.LeadIndexRef__r.EntryDate__c;
	        	entryDate = (DateTime.newInstance(entryDt.year(), entryDt.month(), entryDt.day())).format('yyyy年MM月dd日');
	        } else {
	        	entryDate = '';
	        }
	        // 出発日
	        if (firstLead.LeadIndexRef__r.DepartureDate__c != null) {
	        	Date depDt = firstLead.LeadIndexRef__r.DepartureDate__c;
	        	departureDate = (DateTime.newInstance(depDt.year(), depDt.month(), depDt.day())).format('yyyy年MM月dd日');
	        } else {
	        	departureDate = '';
	        }
	        // 泊数計算
	        if (!CommUtils.isBlank(entryDate) && !CommUtils.isBlank(departureDate)) {
	        	Date entryDt = firstLead.LeadIndexRef__r.EntryDate__c;
	        	Date depDt = firstLead.LeadIndexRef__r.DepartureDate__c;
	        	stayDays = entryDt.daysBetween(depDt);
	        }
	        // 合計値集計を行う
	        usedRooms  = 0;
	        dinnerNums = 0;
	        stayPeoples = stayMale = stayFemale = stayChildren = stayChildrenA = stayChildrenB = stayChild = tourConductor = 0;
	        // 利用予定の部屋名
	        roomNos = new List<String>();
	        Set<String> roomNameFilterSet = new Set<String>();

	        //部屋
	        // 2015/11/16 錦水館専用表示項目 BEGIN
			rmInfoItem = new List<RoomInfoItem>();
			Map<String, Integer> roomNmMap = new Map<String, Integer>();
			// 2015/11/16 錦水館専用表示項目 END
			// 予約インデックス情報から設定情報を取得する
			for (Lead__c lead : pLeads) {
				// 2015/11/16 錦水館専用表示項目 BEGIN
				if (!CommUtils.isBLank(lead.refTypeOfRooms__r.Name)) {
					if (roomNmMap.containsKey(lead.refTypeOfRooms__r.Name)) {
						roomNmMap.put(lead.refTypeOfRooms__r.Name, roomNmMap.get(lead.refTypeOfRooms__r.Name) + 1);
					}else {
						roomNmMap.put(lead.refTypeOfRooms__r.Name, 1);
					}
				}
				// 2015/11/16 錦水館専用表示項目 END
				// 利用部屋名
				if (lead.Rroom__c != null && !roomNameFilterSet.contains(lead.Rroom__r.Name)) {
					if(pXmlInfo.bMaxRooms > roomNos.size()) roomNos.add(lead.Rroom__r.Name);
					roomNameFilterSet.add(lead.Rroom__r.Name);
				}
				// 部屋数合計
				usedRooms ++;
				// 食数
				dinnerNums += CommUtils.nullToZero(lead.Morimongn__c);
				// 宿泊人數
				stayMale += CommUtils.nullToZero(lead.Mans__c);
				stayFemale += CommUtils.nullToZero(lead.Femails__c);
				stayChildren += CommUtils.nullToZero(lead.ChildFA__c) 
							+ CommUtils.nullToZero(lead.Childs__c) 
							+ CommUtils.nullToZero(lead.ChildC__c) 
							+ CommUtils.nullToZero(lead.ChildD__c)
							+ CommUtils.nullToZero(lead.ChildE__c) 
							+ CommUtils.nullToZero(lead.ChildF__c);
				// 2015/11/16 錦水館専用表示項目 BEGIN
				//子供A
				stayChildrenA += CommUtils.nullToZero(lead.ChildFA__c);
				//子供B
				stayChildrenB += CommUtils.nullToZero(lead.Childs__c);
				//幼児
				stayChild += CommUtils.nullToZero(lead.ChildC__c)
							+ CommUtils.nullToZero(lead.ChildD__c)
							+ CommUtils.nullToZero(lead.ChildE__c)
							+ CommUtils.nullToZero(lead.ChildF__c);
				// 2015/11/16 錦水館専用表示項目 END
			}
			// 2015/11/16 錦水館専用表示項目 BEGIN
			for (String w:roomNmMap.keySet() ) {
				if(rmInfoItem.size() >= 3) break;
				rmInfoItem.add(new RoomInfoItem(w, String.valueOf(roomNmMap.get(w))));
			}
			if (rmInfoItem.size() < 3) {
				Integer ris = 3 - rmInfoItem.size();
			    for (Integer i = 0; i < ris; i++ ) {
			    	rmInfoItem.add(new RoomInfoItem('', ''));
			    }
			}
			// 2015/11/16 錦水館専用表示項目 END
			// 総人數集計する
			stayPeoples = stayMale + stayFemale + stayChildren;
			
			// 2015/11/16 錦水館専用表示項目 BEGIN
			//作成日
			creatDate = System.now().format('yy/MM/dd HH:mm:ss');
			//Fax
			// 2016/03/25 起動予約からお客様情報を取得する BEGIN
			//fax = firstLead.LeadIndexRef__r.contactRef__r.Fax == null
			//					? firstLead.LeadIndexRef__r.contactRef__r.Fax2__c
			//					: firstLead.LeadIndexRef__r.contactRef__r.Fax;
			fax = firstLead.Relcontact__r.Fax == null
								? firstLead.Relcontact__r.Fax2__c
								: firstLead.Relcontact__r.Fax;
			// 2016/03/25 起動予約からお客様情報を取得する END
			// 利用日
			entryDateYobi = entryDate + '(' +CommUtils.getYobi(firstLead.LeadIndexRef__r.EntryDate__c) + ')';
			//大人人數
			adult = stayMale + stayFemale;
			//受 付 日
			if (firstLead.ReservedDate__c != null) {
				String rDate = firstLead.ReservedDate__c.format('yyyy年MM月dd日 ');
				reservedDate = rDate + '(' + CommUtils.getYobi(firstLead.ReservedDate__c.date())  + ')';
			}
			//受 付 担 当
			resContact = CommUtils.isBlank(firstLead.ReservedContact__c) 
							? firstLead.LastModifiedBy.Name
							: firstLead.ReservedContact__c;
			//到 着 時 間
			DateTime arrivalDtTime = firstLead.EntryTime__c;
			if (!CommUtils.isBlank(firstLead.Field4__c)) {
				Time arrTime = CommUtils.stringToTime(firstLead.Field4__c);
				arrivalDtTime = DateTime.newInstance(arrivalDtTime.date(), arrTime);
			}
			arrivalTime = arrivalDtTime.format('HH時mm分');
			// 2019/03/31 日帰り時刻を表記 BY zyz BEGIN
			DateTime departureDtTime = firstLead.Departure__c;
			if (!CommUtils.isBlank(firstLead.Field3__c)) {
				Time arrTime = CommUtils.stringToTime(firstLead.Field3__c);
				departureDtTime = DateTime.newInstance(departureDtTime.date(), arrTime);
			}
			departureTime = departureDtTime.format('HH時mm分');
			// 2019/03/31 日帰り時刻を表記 BY zyz END
			//乗 り 物
			muRiProducts = firstLead.Field348__c;
			// お客様名
			if (layoutCode == layoutType5A4) {
				// 2016/03/25 起動予約からお客様情報を取得する BEGIN
				//customName = firstLead.LeadIndexRef__r.contactRef__r.Name;
				// 2016/03/25 起動予約からお客様情報を取得する END
				receiptTitle = CommLogicProcess.getPrintReceiptTitle(customName);
				//2015/12/12 お客様Name項目 BEGIN
				customName = CommUtils.nullToBlank(CommRepUtils.getPdfMaxShowStringNew(customName,2,14));
				//2015/12/12 お客様Name項目 END
			}
			
			// 2015/11/16 錦水館専用表示項目 END
		}
		//public Lead__c leadInf{get; private set;}
		public String customName {get; private set;}	// お客様名(予約インデックスから)
		public String issueDate{get; private set;}	// 発行日[VF直接表示?]
		public String postNo{get;private set;}		// ご住所：郵便番号
		public String address{get;private set;}		// ご住所：住所情報
		public String phone{get;private set;}		// 連絡電話番号
		public String leadNo{get; private set;}		// 予約番号（予約インデックス名）
		public String entryDate{get; set;}			// ご利用日時（FROM）
		public String departureDate{get;set;}		// ご利用日時（TO）
		public Integer stayDays{get; private set;}	// 宿泊日数   (TO-FROM)
		public Integer usedRooms{get; private set;}	// 部屋利用数	(集計により)
		public Decimal dinnerNums{get; private set;}	// 食数
		public Decimal stayPeoples{get; private set;}	// 宿泊人數
		public Decimal stayMale{get; private set;}		// 男性
		public Decimal stayFemale{get; private set;}	// 女性
		public Decimal stayChildren{get; private set;}	// 子供
		public List<String> roomNos{get; private set;}	// 部屋番号リスト
		// 2015/11/16 錦水館専用表示項目 BEGIN
		public String creatDate{get; private set;}		// 作成日
		public String fax{get;private set;}				// Fax
		public String entryDateYobi{get; set;}			// 利用日
		public Decimal adult{get; private set;}			// 大人人數
		public Decimal stayChildrenA{get; private set;}	// 子供A人數
		public Decimal stayChildrenB{get; private set;}	// 子供B人數
		public Decimal stayChild{get; private set;}		// 幼児人數
		public Decimal tourConductor{get; private set;}	//ﾄﾞﾗｲﾊﾞｰ･ｶﾞｲﾄﾞ･添乗員
		public String reservedDate{get; private set;}		// 受 付 日
		public String resContact{get;private set;}		//受 付 担 当
		public String arrivalTime{get;private set;}		//到 着 時 間
		public String muRiProducts{get;private set;}	//乗 り 物
		public List<RoomInfoItem> rmInfoItem{get; private set;}
		public String receiptTitle{get; private set;}
		// 2015/11/16 錦水館専用表示項目 END
		// 2019/03/31 日帰り時刻を表記 BY zyz BEGIN
		public String departureTime{get; private set;} 	// 出 発 時 間 HH時mm分
		// 2019/03/31 日帰り時刻を表記 BY zyz END

	}
	// 2015/11/16 改正 BEGIN
	public class RoomInfoItem {
		public RoomInfoItem(String s,String i ) {
			roomNmList = s;
			roomNumList = i;
		}
		public String roomNmList{get; private set;}
		public String roomNumList{get; private set;}
	}
	// 2015/11/16 改正 END

	// PDF詳細情報格納用
	public class BookItem {
		public BookItem(BookingEstimateItem__c s, Integer pointlen) {
			if (s.Id != null || !CommUtils.isBLank(s.ProductName__c)) {
				// 会計商品コード
				productCd = s.refAccountMaster__r.Field3__c;
				// 商品目最大表示のサイズを取得する【B5】サイズの場合、最大48桁商品名文字を表示する
				Integer maxLen = ( layoutCode == layoutType3B5 ) ? 48 : 56;
				// 2019/07/30 軽減税率機能対応 WGCH BEGIN
				if(isReducedTaxFlg) maxLen -= 4;
				// 2019/07/30 軽減税率機能対応 WGCH END
				// 会計商品名
				productNm = (CommUtils.isBlank(s.ProductName__c) ? s.X2_1__c : s.ProductName__c);
				productNm = CommRepUtils.getPdfMaxShowString(productNm, maxLen);
	            // Ver4.54       2014/08/05  E-CLOUD     過去の合計計算不具合修正           
	            CommUtils.ProductInfo proc = new CommUtils.ProductInfo(CommUtils.nullToIntZero(s.UnitPriceDefKbCal__c),pointlen);
	            // 単価（サービス料込、税込）計算を行う
	            //proc.process(s.UnitPrice__c, 1, s.TaxRate__c, s.ServiceRate__c);
	           	//unitPrice = proc.unitPriceTax;
				// 2015/10/27 プラン明細に非課税明細情報を取得する BEGIN
				// 2015/11/25 数量は０の場合、不具合対応 BEGIN
				// 非課税明細が含める場合
				Decimal noTaxUnitPriceSum = 0;
				for (BookingEstimateItem__c subItem : s.ParentBookingItemRef__r) {
					noTaxUnitPriceSum += CommUtils.nullToZero(subItem.UnitPrice__c);
				}
				// 2019/07/30 PLAN非课税BUG修正 WGCH BEGIN
				noTaxUnitPriceSumEnd = noTaxUnitPriceSum * Commutils.nullToZero(s.Amount__c);
				// 2019/07/30 PLAN非课税BUG修正 WGCH END
				// 元の単価から、税抜金額を外して、税込み金額を計算する
				Decimal incTaxUnitPrice = CommUtils.nullToZero(s.UnitPrice__c) - noTaxUnitPriceSum;
				proc.process(incTaxUnitPrice, Commutils.nullToZero(s.Amount__c) , s.TaxRate__c, s.ServiceRate__c);
				s.UnitPrice__c = proc.unitPriceTax;
				Decimal priceIncTax = proc.priceIncTax;	// 非課税明細金額を抜いて、計算した税込金額
				if (noTaxUnitPriceSum > 0) {
					proc.process(noTaxUnitPriceSum, Commutils.nullToZero(s.Amount__c) , 0, s.ServiceRate__c);
					s.UnitPrice__c += proc.unitPriceTax;
				}
				// 2015/11/25 数量は０の場合、不具合対応 END
				// 2015/10/27 プラン明細に非課税明細情報を取得する END
	           	unitPrice = CommUtils.nullToZero(s.UnitPrice__c);
	           	unitNums = CommUtils.nullToZero(s.Amount__c);
	            // 合計金額から宿泊税をは外す[表示要合計金額 = 合計金額ー宿泊税]
	            amount = CommUtils.nullToZero(s.SpTotal__c) - CommUtils.nullToZero(s.SpecialTax__c);
	            // 前受金　|| 支払メディア
    			isPayItem = (s.ActionType__c == CommConst.PROD_ACTION_TYPE_AR  || s.ActionType__c == CommConst.PROD_ACTION_TYPE_PY);
    			// 2018/01/15 予約確認書の明細欄に日付を表示したい zyz BEGIN
    			/*
    			// 2015/11/16 改正[錦水館専用情報] BEGIN
    			// 利用日
    			if (s.refBooking__r.EntryTime__c != null) {
    				usedDate = DateTime.valueOf(s.refBooking__r.EntryTime__c).format('yy/MM/dd');
    			}
    			// 2015/11/16 改正[錦水館専用情報] END
    			*/
    			useDate = s.UseDate__c;
    			if(s.UseDate__c == null && s.refBooking__r != null){
    				useDate = s.refBooking__r.EntryTime__c.date();
    				// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH BEGIN
    				// if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI) {
    				if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI && !CommConst.BOOKEST_USERDATE_FLG) {
    				// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH END
    					useDate = s.UseDate__c = s.refBooking__r.Departure__c.date();
    				}
    			}
    			// 2018/01/15 予約確認書の明細欄に日付を表示したい zyz END
			} else {
				productCd = '';
				productNm = '';
				unitPrice = null;
				unitNums = null;
				amount = 0;
				isPayItem = false;
			}
			this.s = s;
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			// 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH BEGIN
			// planFlg = isPlanBrkShowFlg && (s.ActionType__c == CommConst.PROD_ACTION_TYPE_PL);
			planFlg = isPlanBrkShowFlg && (s.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) && pBrkTranItemMap != null && pBrkTranItemMap.containsKey(s.Id);
			// 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH END
			pBrkDNFlg = false;
			taxUnitPrice = 0;
			// 2019/07/30 軽減税率機能対応 WGCH END
		}
		public BookingEstimateItem__c s{get; private set;}
		public String productCd{get; private set;}
		public String productNm{get; private set;}
		public Decimal unitPrice{get; private set;}
		public Decimal unitNums {get; private set;}
		public Decimal amount	{get; private set;}
		public Boolean isNoShow   {get{ return ( (unitPrice == null || unitPrice == 0) &&
												(unitNums == null || unitNums == 0) );}}
		public Boolean isPayItem{get; private set;}	// 概要行目は支払明細確認フラグ：TRUEの場合、支払メディア情報

		// 2018/01/15 予約確認書の明細欄に日付を表示したい zyz BEGIN
		//public String usedDate{get; private set;}		//日 付
		public Date useDate{get; private set;}
		// 2018/01/15 予約確認書の明細欄に日付を表示したい zyz END
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		public Decimal noTaxUnitPriceSumEnd{get; private set;}
		public Boolean planFlg{get; private set;}
		public Boolean pBrkDNFlg{get; private set;}
		public Decimal taxUnitPrice{get; private set;}
		public Decimal taxRate{get{ return CommUtils.nullToZero(s.TaxRate__c) / 100;} private set;}
		public Decimal serviceRate{get{ return CommUtils.nullToZero(s.ServiceRate__c) / 100;} private set;}
		public Decimal quantity{get{ return CommUtils.nullToZero(s.Amount__c);} private set;}
		public Boolean isPaymentInfo{get{ return isPayItem;} private set;}
		public Decimal specialTax{get{ return CommUtils.nullToZero(s.SpecialTax__c);} private set;}
		// 2019/07/30 軽減税率機能対応 WGCH END
	}
	// 明細合計金額情報を格納する
	public class SummaryInfo {
		// 小計(明細合計)
		public Decimal amoutPrice{get; private set;}
    	// 小計(明細合計) - 支払済金額
    	public Decimal amoutQuotePriceIncTax{get{
    		// 2016/10/26 支払情報はクポーン、割引合計値の減算とき、入湯税金額含めない不具合修正
    		Decimal locAmoutPriceIncTax = amoutPrice + bathProd.amount;
    		if (payedDiscount > 0) {
	    		if (locAmoutPriceIncTax >= payedDiscount) {
	    			locAmoutPriceIncTax = locAmoutPriceIncTax - payedDiscount;
	    		} else {
	    			locAmoutPriceIncTax = 0;
	    		}
    		}
    		if (locAmoutPriceIncTax > 0) {
	    		if (locAmoutPriceIncTax >= payedConpon) {
	    			locAmoutPriceIncTax = locAmoutPriceIncTax - payedConpon;
	    		} else {
	    			locAmoutPriceIncTax = 0;
	    		}
    		}
    		// 2016/10/26 支払情報はクポーン、割引合計値の減算とき、入湯税金額含めない不具合修正
    		return locAmoutPriceIncTax - bathProd.amount - payedPriceOther;
    	} private set;}
		// 税金
		public Decimal amoutTax {get; set;}
		//2019/04/30 増税仮対応 BY zyz BEGIN
		// 增税
		public String amoutIncMstTaxName {get; set;}
		public Decimal amoutIncMstTax {get; set;}
		//2019/04/30 増税仮対応 BY zyz END
		// 入湯税
		public BookItem bathProd{get; private set;}
		// 特別税
		public Decimal amoutSpecialIncTax{get; set;}
		// 入湯税の商品コード情報を格納
		private Set<String> bathProdCdSet = null;
        // 総金額（税込：消費税計算用対象金額）
        private Decimal amoutPriceForTax;
    	// 2015/07/08 総支払金額[クーポン AND 割引]ー>支払金額は総金額を超える場合、返金なし、見積もり金額なし
    	public Decimal payedConpon{get;set;}
    	public Decimal payedDiscount{get;set;}
    	// 総支払金額[クーポン AND 割引以外の金額]
    	public Decimal payedPriceOther{get;set;}
    	// 2021/07/30 #JP10785 by zy BEGIN
    	public Decimal totalAmount;
    	// 2021/07/30 #JP10785 by zy END
		public SummaryInfo (List<String> bathProdCdLst) {
			if (bathProdCdLst != null) bathProdCdSet = new Set<String>(bathProdCdLst);
			bathProd = new BookItem(new BookingEstimateItem__c(), -1);
			bathProd.unitPrice = bathProd.unitNums = 0;
			amoutTax = amoutPrice = amoutPriceForTax = amoutSpecialIncTax = 0;
			// 2019/04/30 増税仮対応 BY zyz BEGIN
			amoutIncMstTax = 0;
			amoutIncMstTaxName = '';
			// 2019/04/30 増税仮対応 BY zyz END
			payedConpon = payedDiscount = payedPriceOther = 0;	// 支払金額を初期化する
			// 2021/07/30 #JP10785 by zy BEGIN
			if(layoutCode == layoutType6) {
				totalAmount = 0;
			}
			// 2021/07/30 #JP10785 by zy END
		}
		public void addItem(BookItem ps, Map<String, String> paymentTypeToMediaLabMap) {
        // 2019/04/30 増税仮対応 BY zyz BEGIN
        // 2019/05/31 増税仮BUG FIX WGCH BEGIN
		// CommLogicProcess.TaxIncMstInfo info = CommLogicProcess.getTaxIncMstInfo();
		// 2019/05/31 増税仮BUG FIX WGCH END
		// 增税商品的Id
		String taxIncMstcode = !CommUtils.isBlank(info.taxIncMstCode) ? info.taxIncMstCode : '';
		if (taxIncMstcode == ps.productCd && !CommUtils.isBlank(taxIncMstcode)) {
			amoutIncMstTaxName = ps.productNm ;
			amoutIncMstTax += ps.amount;
		}
        // 2019/04/30 増税仮対応 BY zyz END
			// 入湯税の場合
			if (isBathProd(ps.productCd)) {
				bathProd.productNm = '入湯税';
				bathProd.unitPrice = ps.unitPrice;
				bathProd.unitNums += ps.unitNums;
				bathProd.amount = bathProd.unitPrice * bathProd.unitNums;
			} else {
				// 明細は支払　OR　前受け金の場合、合計を行う
				if (ps.s.ActionType__c == CommConst.PROD_ACTION_TYPE_AR  ||
					ps.s.ActionType__c == CommConst.PROD_ACTION_TYPE_PY){
					String mediaNm = paymentTypeToMediaLabMap.get(ps.s.PaymentType__c);
					if (CommUtils.isBlank(mediaNm)) mediaNm = CommConst.MEDIA_TYPE_01;
					String mediaCd = CommConst.getMediaCodeByMediaName(mediaNm);
					if (mediaCd == CommConst.MEDIA_TYPE_CD_11) {
						payedConpon += CommUtils.nullToZero(ps.s.Total__c);
					} else if ( mediaCd == CommConst.MEDIA_TYPE_CD_12) {
						payedDiscount += CommUtils.nullToZero(ps.s.Total__c);
					} else {
						payedPriceOther += CommUtils.nullToZero(ps.s.Total__c);
					}
				} else {
					// 普通商品の場合[消費税]
					// 消費税率は０以上の場合、金額合計値
					amoutSpecialIncTax += CommUtils.nullToZero(ps.s.SpecialTax__c);
					// 消費税計算用金額合計 = 合計金額（税込） - 宿泊税
		            if (CommUtils.nullToZero(ps.s.TaxRate__c) > 0) {
		                // 消費税計算用金額の合計:金額-特別税
		                amoutPriceForTax += ps.amount;
		                // 2019/07/30 PLAN非课税BUG修正 WGCH BEGIN
		                amoutPriceForTax -= CommUtils.nullToZero(ps.noTaxUnitPriceSumEnd);
		                // 2019/07/30 PLAN非课税BUG修正 WGCH END
		            }
		            amoutPrice += ps.amount;
				}	            
			}
		}
		// 入湯税商品がどうか確認用
		public Boolean isBathProd(String prodCd) {
			return (bathProdCdSet != null && bathProdCdSet.contains(prodCd));
		}
	}
	// Footerの施設情報を格納する
	public class FooterInfo {
		public FooterInfo(ReportLogo__c pRep, String pShopCode) {
			reportInfo = pRep;
			
			if (pRep.ShopInfoRef__c != null && !CommUtils.isBlank(pShopCode)) {
				// 店舗設定情報から取得、画面情報を表示する
				WebSite = pRep.ShopInfoRef__r.WebSite__c;
				PostNo = pRep.ShopInfoRef__r.Post__c;
				shopName = pRep.ShopInfoRef__r.Name;
				Address = pRep.ShopInfoRef__r.Address__c;
				Phone = pRep.ShopInfoRef__r.Phone__c;
				Fax = pRep.ShopInfoRef__r.Fax__c;
				Email = pRep.ShopInfoRef__r.Email__c;
			} else {
				Organization orgDetails = [SELECT Id, Name, PostalCode, State,City,Street,Phone,Fax  FROM Organization WHERE Id = :UserInfo.getOrganizationId()];
				// 組織情報から設定する
				WebSite = '';
				PostNo = CommUtils.nullToBlank(orgDetails.PostalCode);
				shopName = orgDetails.Name;
				Address = CommUtils.nullToBlank(orgDetails.State) + CommUtils.nullToBlank(orgDetails.City) + CommUtils.nullToBlank(orgDetails.Street);
				Phone = CommUtils.nullToBlank(orgDetails.Phone);
				Fax = CommUtils.nullToBlank(orgDetails.fax);
			}
		}
		public ReportLogo__c reportInfo{get; private set;}
		public String WebSite{get; private set;}
		public String PostNo {get; private set;}
		public String shopName{get;private set;}
		public String Address{get;private set;}
		public String Phone{get;private set;}
		public String Fax{get;private set;}
		public String Email{get;private set;}
	}

    // XML設定情報により、設定情報を取得する
    public class XmlConfigInfo {
    	// XML初期情報読み込む
    	public XmlConfigInfo(Dom.XmlNode shopNode) {

    		Dom.XmlNode shopcodeField =  shopNode.getChildElement('SHOPCODE', null);
    		Dom.XmlNode headerNode = shopNode.getChildElement('HEADER', null);
    		Dom.XmlNode bodyNode = shopNode.getChildElement('BODY', null);
    		Dom.XmlNode footerNode = shopNode.getChildElement('FOOTER', null);
    		// 2018/01/15 予約確認書の明細欄に日付を表示したい zyz BEGIN
			Dom.XmlNode useDateField = shopNode.getChildElement('SHOWUSEDATE', null);
			Dom.XmlNode taxRateField = shopNode.getChildElement('TAXRATELABEL', null);
    		useDateFlg = false;
    		taxNumLabel = '税金';
			if (useDateField != null) useDateFlg = Boolean.valueof(CommUtils.nullToBlank(useDateField.getText()));
			if (taxRateField != null){
				String taxNumStr = CommUtils.nullToBlank(taxRateField.getText());
				if (!CommUtils.isBlank(taxNumStr)) taxNumLabel = taxNumStr;
			}
    		// 2018/01/15 予約確認書の明細欄に日付を表示したいzyz END
    		// 2018/05/08 予約確認書に部屋タイプが表記されてい zyz BEGIN
    		Dom.XmlNode roomTypeField = shopNode.getChildElement('SHOWROOMTYPE', null);
    		roomTypeFlg = false;
    		if (roomTypeField != null) roomTypeFlg = Boolean.valueof(CommUtils.nullToBlank(roomTypeField.getText()));
    		// 2018/05/08 予約確認書に部屋タイプが表記されてい zyz END
    		// 2020/06/30 予約確認書の集計対象がカスタマイズできるように改善対応 BY zyz BEGIN
    		bfLeadWhere = '';
    		Dom.XmlNode leadFilterField = shopNode.getChildElement('LEADFILTER', null);
    		if (leadFilterField != null) bfLeadWhere = CommUtils.nullToBlank(leadFilterField.getText());
    		// 2020/06/30 予約確認書の集計対象がカスタマイズできるように改善対応 BY zyz END
    		// Title設定情報
    		if (headerNode != null) {
    			Dom.XmlNode hTitleKanjiField = headerNode.getChildElement('TITLE_KANJI', null);
    			Dom.XmlNode hTitleEnglishField = headerNode.getChildElement('TILTE_ENGLISH', null);
    			// 150126 L
    			Dom.XmlNode hTitleCommentField = headerNode.getChildElement('TITLE_COMMENT', null);
    			if (hTitleKanjiField != null) hTitleKanji = !CommUtils.isBlank(hTitleKanjiField.getText()) ? hTitleKanjiField.getText() : 'ご	予	約	確	認	書';
    			if (hTitleEnglishField != null) hTitleEnglish = !CommUtils.isBlank(hTitleEnglishField.getText()) ? hTitleEnglishField.getText() : 'JINYA RESERVATION CONFIRMATION';
    			// 150126 L
    			if (hTitleCommentField != null) hTitleComment = !CommUtils.isBlank(hTitleCommentField.getText().trim()) ? hTitleCommentField.getText().trim() : '';
    			else hTitleComment = 'この度はご予約承り誠にありがとうございます。<br/>ご予約内容を下記の通り承りました。 ご確認くださいませ。';
    			/*// 2015/11/16 改正 BEGIN
    			if (layoutCode == layoutType5A4) {
    				Dom.XmlNode hTitleLayoutField = headerNode.getChildElement('TITLE_LAYOUT_KIN', null);
					if (hTitleLayoutField != null) {
						// 店舗設定情報の取得
	    				shopXmlInfoList = new List<shopInfoitem>();
	    				for (Dom.XmlNode childrenNode:hTitleLayoutField.getChildElements() ) {
	    					String tagName = childrenNode.getName();
	    					if (tagName == 'LAYOUT') {
								shopXmlInfoList.add(new shopInfoitem(childrenNode));
	    					} else if (tagName == 'TITLE_LOGO_PATH') {
	    						// TOPページのロゴパス
	    						shopTopPageLogoUrl = CommUtils.nullToBlank(childrenNode.getText());
	    					}
	    				}
					}
    			}
    			// 2015/11/16 改正 END
    			*/
    		}
    		bBathProdCdLst = new List<String>();
    		// Body設定情報
    		// 2018/05/08 予約確認書に部屋タイプが表記されてい zyz BEGIN
    		bMaxRows = 12;
    		// 2018/05/08 予約確認書に部屋タイプが表記されてい zyz END
    		if (bodyNode != null) {
				Dom.XmlNode bMaxRowsField = bodyNode.getChildElement('MAX_ROWS', null);
				Dom.XmlNode bMaxRoomsField = bodyNode.getChildElement('MAX_SHOWROOMS', null);
    			Dom.XmlNode bBathField = bodyNode.getChildElement('BATHTAX', null);
    			Dom.XmlNode bCancelRuleField = bodyNode.getChildElement('CANCEL_RULE', null);
    			Dom.XmlNode bCommentField = bodyNode.getChildElement('COMMENT', null);
    			if (bMaxRowsField != null) bMaxRows = CommUtils.nullToIntZero(bMaxRowsField.getText());
    			if (bMaxRoomsField != null) bMaxRooms = CommUtils.nullToIntZero(bMaxRoomsField.getText());
				if (bBathField != null) {
					Dom.XmlNode[] bathProductCds = bBathField.getChildElements();
					for (Dom.XmlNode bathProductCdField : bathProductCds) {
						String productCd = CommUtils.nullToBlank(bathProductCdField.getText());
						bBathProdCdLst.add(productCd);
					}
				}
    			if (bCancelRuleField != null) bCancelRule = !CommUtils.isBlank(bCancelRuleField.getText()) ? bCancelRuleField.getText() : 'キャンセルされる場合<br/>規定により宿泊料金に対し前日20%・当日80%・不泊100%のキャンセル料を申し受けます。';
    			if (bCommentField != null) bComment = CommUtils.nullToBlank(bCommentField.getText());
    		}
			Dom.XmlNode bFieldLabelNode = bodyNode.getChildElement('FIELD_LABEL', null);
    		if (bFieldLabelNode != null) {
    		    Dom.XmlNode bfLeadnameField = bFieldLabelNode.getChildElement('LEAD_NAME', null);
    		    Dom.XmlNode bfIssuedateField = bFieldLabelNode.getChildElement('ISSUE_DATE', null);
    		    Dom.XmlNode bfAddressField = bFieldLabelNode.getChildElement('ADDRESS', null);
    		    Dom.XmlNode bfAhoneField = bFieldLabelNode.getChildElement('PHONE', null);
    		    Dom.XmlNode bfLeadnoField = bFieldLabelNode.getChildElement('LEAD_NO', null);
    		    Dom.XmlNode bfUseddateField = bFieldLabelNode.getChildElement('USED_DATE', null);
    		    Dom.XmlNode bfUsedinfoField = bFieldLabelNode.getChildElement('USED_INFO', null);
    		    Dom.XmlNode bfUsedpaxcountField = bFieldLabelNode.getChildElement('USED_PAXCOUNT', null);
				bfLeadname = (bfLeadnameField == null || CommUtils.isBlank(bfLeadnameField.getText().trim()) ? 'ご予約名' : bfLeadnameField.getText());
				bfIssuedate = (bfIssuedateField == null || CommUtils.isBlank(bfIssuedateField.getText().trim()) ? '発行日' : bfIssuedateField.getText());
				bfAddress = (bfAddressField == null || CommUtils.isBlank(bfAddressField.getText().trim()) ? 'ご住所' : bfAddressField.getText());
				bfAhone = (bfAhoneField == null || CommUtils.isBlank(bfAhoneField.getText().trim()) ? '連絡電話番号' : bfAhoneField.getText());
				bfLeadno = (bfLeadnoField == null || CommUtils.isBlank(bfLeadnoField.getText().trim()) ? '予約番号' : bfLeadnoField.getText());
				bfUseddate = (bfUseddateField == null || CommUtils.isBlank(bfUseddateField.getText().trim()) ? 'ご利用日時' : bfUseddateField.getText());
				bfUsedinfo = (bfUsedinfoField == null || CommUtils.isBlank(bfUsedinfoField.getText().trim()) ? 'ご宿泊日数/部屋数' : bfUsedinfoField.getText());
				bfUsedpaxcount = (bfUsedpaxcountField == null || CommUtils.isBlank(bfUsedpaxcountField.getText().trim()) ? 'ご宿泊人数' : bfUsedpaxcountField.getText());
    		}else{
    			bfLeadname = 'ご予約名';
    			bfIssuedate = '発行日';
    			bfAddress = 'ご住所';
    			bfAhone = '連絡電話番号';
    			bfLeadno = '予約番号';
    			bfUseddate = 'ご利用日時';
    			bfUsedinfo = 'ご宿泊日数/部屋数';
    			bfUsedpaxcount = 'ご宿泊人数';
    		}
	    	// 2021/07/30 #JP10785 by zy BEGIN
            customizeHtml = '';
            customeStyleStr = '';
            if(layoutCode == layoutType6) {
	            String marginLeft = '0';
	            String marginTop = '0';
	            Dom.XmlNode defFields = shopNode.getChildElement('RESVCARD', null);
	            if (defFields != null ) {
	                Dom.XmlNode cardSize = defFields.getChildElement('PAGESIZE', null);
	                if(cardSize != null){
	                	Boolean cardFlg = true;
	                	String verticalStr = CommUtils.nullToBlank(cardSize.getAttribute('VERTICAL',null));
	                	if (!CommUtils.isBlank(verticalStr)) {
	                		cardFlg = boolean.valueOf(verticalStr);
	                	}
	                    if (!cardFlg) pageformat = ReportXmlParserHelper.getPdfPagePaperSizeTraverse(CommUtils.nullToBlank(cardSize.getText()),!cardFlg);
	                    else pageformat = ReportXmlParserHelper.getPdfPagePaperSize(CommUtils.nullToBlank(cardSize.getText()));
	                    String marginLeftStr = cardSize.getAttribute('MARGINVERTICAL',null);
	                    if (!CommUtils.isBLank(marginLeftStr)) {
	                        marginLeft = marginLeftStr;
	                    }
	                    String marginTopStr = cardSize.getAttribute('MARGINHORIZONTAL',null);
	                    if (!CommUtils.isBLank(marginTopStr)) {
	                        marginTop = marginTopStr;
	                    }
	                }
	                Dom.XmlNode rowsNode = defFields.getChildElement('BODY', null);
	                if(rowsNode != null){
	                    customizeHtml = ReportXmlParserHelper.convertNewXmlTagToString(rowsNode);
	                }
	                Dom.XmlNode styleNode = defFields.getChildElement('STYLE', null);
	                if(styleNode != null){
	                    customeStyleStr = CommUtils.nullToBlank(styleNode.getText());
	                }
	                customeStyleStr = '@page{margin:' + marginLeft + ' ' +marginTop + '}' + customeStyleStr;
	            }
	        }
	    	// 2021/07/30 #JP10785 by zy END
    	}
    	public String shopCode{get; private set;}
    	public String hTitleKanji{get; private set;}
    	public String hTitleEnglish{get; private set;}
		// 150126 L
		public String hTitleComment{get; private set;}
		public String bfLeadname{get; private set;}
		public String bfIssuedate{get; private set;}
		public String bfAddress{get; private set;}
		public String bfAhone{get; private set;}
		public String bfLeadno{get; private set;}
		public String bfUseddate{get; private set;}
		public String bfUsedinfo{get; private set;}
		public String bfUsedpaxcount{get; private set;}
		public String bProductCdFlg{get; private set;}
    	public Integer bMaxRows{get; private set;}
    	public Integer bMaxRooms{get; private set;}	// 最大表示の部屋数
    	public List<String> bBathProdCdLst{get; private set;}
    	public String bCancelRule{get; private set;}
    	public String bComment{get; private set;}
    	// 2018/01/15 予約確認書の明細欄に日付を表示したい zyz BEGIN
    	public Boolean useDateFlg{get; private set;}
    	public String taxNumLabel{get; private set;}
    	// 2018/01/15 予約確認書の明細欄に日付を表示したい zyz END
    	// 2018/05/08 予約確認書に部屋タイプが表記されてい zyz BEGIN
    	public Boolean roomTypeFlg{get; private set;}
    	// 2018/05/08 予約確認書に部屋タイプが表記されてい zyz END
    	// 2020/06/30 予約確認書の集計対象がカスタマイズできるように改善対応 BY zyz BEGIN
    	public String bfLeadWhere{get; private set;}
    	// 2020/06/30 予約確認書の集計対象がカスタマイズできるように改善対応 BY zyz END
		/*// 2015/11/16 改正 BEGIN
		public String shopTopPageLogoUrl{get; private set;}
		public List<shopInfoitem> shopXmlInfoList{get; private set;}
		// 2015/11/16 改正 END
		*/
		// 2021/07/30 #JP10785 by zy BEGIN
        public String customizeHtml; // HTML設定内容
        public String pageformat; // ページサイズ
        public String customeStyleStr; // カスタムSTYLE
		// 2021/07/30 #JP10785 by zy END
    }
    /*// 2015/11/16 改正[錦水館専用情報] BEGIN
    public class shopInfoitem{
    	public shopInfoitem(Dom.XmlNode shopTitleNode){
			if (shopTitleNode != null) {
				Dom.XmlNode shopnameField = shopTitleNode.getChildElement('LAYOUT_SHOPNAME', null);
				if (shopnameField != null) shopname = CommUtils.nullToBlank(shopnameField.getText());
				Dom.XmlNode shoppostField = shopTitleNode.getChildElement('LAYOUT_POST', null);
				if (shoppostField != null) shoppost = CommUtils.nullToBlank(shoppostField.getText());
				Dom.XmlNode shopaddrField = shopTitleNode.getChildElement('LAYOUT_ADD', null);
				if (shopaddrField != null) shopaddr = CommUtils.nullToBlank(shopaddrField.getText());
				Dom.XmlNode shoptelpField = shopTitleNode.getChildElement('LAYOUT_PHONE', null);
				if (shoptelpField != null) shoptelp = CommUtils.nullToBlank(shoptelpField.getText());
				Dom.XmlNode shopfreeField = shopTitleNode.getChildElement('LAYOUT_FREEDIAL', null);
				if (shopfreeField != null) shopfree = CommUtils.nullToBlank(shopfreeField.getText());
			}
    	}
    	public string shopname{get;private set;}
    	public string shoppost{get;private set;}
    	public string shopaddr{get;private set;}
    	public string shoptelp{get;private set;}
    	public string shopfree{get;private set;}
    }
    public ReportLogo__c getReportLogo() {
    	return CommRepUtils.getReportTitleInfo();
    }
    // 2015/11/16 改正[錦水館専用情報] END
    */
    // 2018/01/24 予約確認書の明細欄に日付を表示したい zyz BEGIN
	private string getSortKey (BookingEstimateItem__c est) {
		Date useDate = est.UseDate__c;
		if(useDate == null){
			useDate = est.refBooking__r.EntryTime__c.date();
			// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH BEGIN
			// if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI) {
			if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI && !CommConst.BOOKEST_USERDATE_FLG) {
			// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH END
		    	useDate = est.refBooking__r.Departure__c.date();
			}
		}
		String userDateStr = DateTime.newInstance(useDate.Year(),useDate.month(),useDate.day()).format('yyyyMMdd') + '_';
		String entryDtStr =  est.refBooking__r.EntryTime__c.format('yyyyMMdd');
		userDateStr += entryDtStr + '_'; 
		userDateStr += CommUtils.paddingLeftZero(CommUtils.nullToZero(est.RowNo__c),4) + '_' + est.Name;
		return userDateStr;
	}
	// 2018/01/24 予約確認書の明細欄に日付を表示したい zyz END
    // 2019/03/31 部屋タイプにより、店舗情報を出力対応（パラメータで切り替え可能） BY zyz BEGIN
    private String getTypeOfRoom(){
    	String spcd='';
    	// 控制开关
    	if(isApplicationFormShopLogoFlg) {
	    	list<Lead__c> leadTypeLst = [select Id, refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c from Lead__c where Id = :leadId And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG];
	    	if (!leadTypeLst.isEmpty()) {
	    		// 取得店铺code的顺序： 部屋タイプ
	    		if(!CommUtils.isBlank(leadTypeLst[0].refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c)){
	    			// 参照部屋タイプ取得店铺code 
	    			spcd = leadTypeLst[0].refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c;
	    		} 
	    	}
    	}
	if (CommUtils.isBLank(spcd)) {
		// 参照user取得店铺code
		spcd = UserUtil.CurrentUser.ShopCode__c;
	}
    	return spcd;
    }
    // 2019/03/31 部屋タイプにより、店舗情報を出力対応（パラメータで切り替え可能） BY zyz END
	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
	// 各税率の金額合計（税抜）と消費税合計情報を格納する
	// 合計のセクションに、割引ある場合、割引関連の消費税を計算する、画面に表示する
	// 該当金額と一覧の金額とわせて、最後の合計行に金額を表示する（税抜き合計＋消費税合計）、最後利用金額合計
	private Decimal taxUnitPriceAll; // 消费税合计值
	// private Decimal amoutIncDiscontAll;
	private Decimal amoutAllMoneyEnd = 0;
	// 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH BEGIN
	private static Map<String, List<BookItem>> pBrkTranItemMap;
	// 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH END
	private Map<String, CommUtils.ProductInfo> planHeaderMap;
	// 小数部分桁数取得する
	private static final Integer gPointLen = CommUtils.getPointLen();
	private Decimal getAmoutIncDiscont(){ return CommUtils.nullToZero(summaryInf.payedDiscount); }
	public static boolean isReducedTaxFlg{get{ return CommConst.REDUCED_TAXRATE_FLG;} private set;}
	public static boolean isPlanBrkShowFlg{get{ return CommConst.REDUCED_PDF_PLAN_BRK_SHOW_FLG;} private set;}
	// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
	public static boolean planBrkToHeaderCalFlg{get{ return CommConst.PLAN_BRKTOHEADER_CAL_FLG;} private set;}
	public class PlanTaxBrkInfo{
		public PlanTaxBrkInfo(){
			hasTaxUnitPrice = noTaxUnitPrice = 0;
		}
		public Decimal hasTaxUnitPrice;
		public Decimal noTaxUnitPrice;
	}
	// 2019/10/02 PlanHeader算法切换对应 WGCH END
	// 2019/10/30 軽減税率割合モード機能対応 WGCH BEGIN
	// 対象行Lst
	private List<CommLogicProcess.TaxRowData> taxRowDataLst;
	// 対象行Map <消費税レート,該当消費税関連の金額合計>
	private map<Decimal, CommLogicProcess.TaxRowData> taxRowDataMap;
	// 値引行
	public CommLogicProcess.DisRowData disRowData {get;set;}
	// 値引行Lst
	public List<CommLogicProcess.DisRowData> disRowDataLst {get;set;}
	// 合计行
	public CommLogicProcess.SumAmountRowData sumRowData {get;set;}
	
	private void reducedTaxInit(){
		taxUnitPriceAll = 0;
		pBrkTranItemMap = new Map<String, List<BookItem>>();
		planHeaderMap = new Map<String, CommUtils.ProductInfo>();
		// 值引行 金额合计 计算 初始化
		disRowData = new CommLogicProcess.DisRowData();
		// 合计值 金额合计 计算 初始化
		sumRowData = new CommLogicProcess.SumAmountRowData();
		// 消费税板块
		taxRowDataMap = new map<Decimal, CommLogicProcess.TaxRowData>();
		// 2019/10/30 軽減税率割合モード機能対応 WGCH BEGIN
		comSum = new CommLogicProcess.SumRowInfo();
		// 2019/10/30 軽減税率割合モード機能対応 WGCH END
	}
	public CommLogicProcess.SumRowInfo comSum{get;set;}
	private void addDetailToMapFun(BookItem tranItem, Decimal noTaxUnitPriceSum) {
		if (tranItem.isPaymentInfo) return;
		/*
		// 每笔会计商品 合計税込
		Decimal priceAmount = CommUtils.RoundProcess(CommUtils.nullToZero(tranItem.unitPrice) * CommUtils.nullToZero(tranItem.quantity), gPointLen);
		// 每笔会计商品 合計消費税
		Decimal taxAmount = CommUtils.RoundProcess(CommUtils.nullToZero(tranItem.taxUnitPrice) * CommUtils.nullToZero(tranItem.quantity), gPointLen);
		taxUnitPriceAll = CommUtils.nullToZero(taxUnitPriceAll) + taxAmount;
		// 每笔会计商品 的 特别税
		Decimal specialTax = tranItem.specialTax;
		if((priceAmount + specialTax + taxAmount) == 0 && CommUtils.nullToZero(noTaxUnitPriceSum) == 0) return;
		// 合计行 会计商品 税拔金额的合计值:
		sumRowData.amountExcTax += priceAmount - taxAmount; // 特别税单独行显示: 所以加到合计税拔里
		// 合计行 会计商品 税込金额的合计值:
		sumRowData.amountIncTax += priceAmount;
		// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
		if(CommUtils.nullToZero(tranItem.taxRate) != 0) sumRowData.priceAmountSum += priceAmount;
		// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
		// 合计行 会计商品 消费税金额的合计值:=> 
		sumRowData.taxAmount += taxAmount;
		Decimal taxRate = CommUtils.nullToZero(tranItem.taxRate);
		taxRate = taxRate == 0 ? 0 : taxRate.setScale(4);
		if (taxRowDataMap == null) taxRowDataMap = new map<Decimal, TaxRowData>();
		if (!taxRowDataMap.containsKey(taxRate)) taxRowDataMap.put(taxRate, new TaxRowData());
		// Plan明细里  含有非课税 
		if(CommUtils.nullToZero(noTaxUnitPriceSum) != 0  || specialTax > 0){
			// Plan明细里 含有非课税 并且 Map key没有0的情况
			Decimal noTaxKey = 0;
			if(!taxRowDataMap.containsKey(noTaxKey)) taxRowDataMap.put(noTaxKey, new TaxRowData());
			taxRowDataMap.get(noTaxKey).amountExcTax += noTaxUnitPriceSum + specialTax;
			// 集计处理
			sumRowData.amountExcTax += noTaxUnitPriceSum + specialTax;
			sumRowData.amountIncTax += noTaxUnitPriceSum + specialTax;
			// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
			// sumRowData.priceAmountSum += noTaxUnitPriceSum + specialTax;
			// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
		}
		TaxRowData taxRow = taxRowDataMap.get(taxRate);
		// 消费税
		taxRow.taxRate = taxRate;
		taxRow.amountExcTax += priceAmount - taxAmount;
		taxRow.amountIncTax += priceAmount;
		// 当前税率   的 消费税合计值
		taxRow.taxAmount += taxAmount;
		*/
		CommLogicProcess.ItemData item = new CommLogicProcess.ItemData();
		item.quantity = tranItem.quantity; // 明细-数量
		item.unitPrice = tranItem.unitPrice; // 明细-单价
		item.taxUnitPrice = tranItem.taxUnitPrice; // 明细-消費税
		item.specialTax = tranItem.specialTax; // 明细-特别税
		item.taxRate = tranItem.taxRate; // 明细-特别税
		CommLogicProcess.addDetailToMapFun(item, noTaxUnitPriceSum, comSum);
	}
	// 値引 比率计算 + 详细设值
	private void processSumInfo() {
		/*
		Decimal ratioSum = 1;
		disRowData.disUnitPriceSum = getAmoutIncDiscont(); // 値引 合计值 获取
		// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
		disRowDataLst = new List<DisAmountRowData>();
		// 值引处理
		// 值引金额 > 课税商品合计金额 Flg
		Boolean disMaxFlg = disRowData.disUnitPriceSum >= sumRowData.priceAmountSum;
		// 当值引金额 > 课税商品合计金额 时, 金额置换, 防止负值
		if(disMaxFlg) disRowData.disUnitPriceSum = sumRowData.priceAmountSum;
		// 最终有效的值引金额
		Decimal disEnd = disRowData.disUnitPriceSum;
		Decimal disSumEnd = disRowData.disUnitPriceSum;
		// 初始化
		disRowData.disUnitPriceSum = 0;
		// 占最大比例的key
		Decimal larger = 0;
		// Key: 最大比例, Val: 消费税
		Map<Decimal, Decimal> disTaxMaxMap = new Map<Decimal, Decimal>();
		// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
		// 並び順で最小税からMAX税を設定する
		taxRowDataLst = new List<TaxRowData>();
		List<Decimal> taxRateLst = new List<Decimal>(taxRowDataMap.keySet());
		taxRateLst.sort();
		for (Decimal taxRate : taxRateLst) {
			TaxRowData taxRow = taxRowDataMap.get(taxRate);
			** 值引【税込】= 值引【税拔】 + 值引【总消费税金额】
			** keyDiscountRatio =>: 構成比率 = 每笔  合計税抜  / W：GrandTota
			-------------传入的值引为--值引【税拔】------------------------------------
			** (値引【税抜】 * 構成比率 * 当前消费税).小数点处理【跟着共同定义走】 = 当前值引的消费税金额
			** 把每笔值引消费税金额 累加 = 值引【总消费税金额】
			-------------传入的值引为--值引【税込】------------------------------------
			** (値引【税込】 / (1 + 構成比率1 * 当前消费税1 + 構成比率2 * 当前消费税2 + ....)).小数点处理【跟着共同定义走】 = 值引【税抜】
			** 值引【税込】 - 值引【税抜】 = 值引【总消费税金额】
			**
			// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
			if(taxRate != 0){
				// 税抜 比率
				// Decimal keyDiscountRatio = sumRowData.amountIncTax == 0 ? 0 : taxRow.amountIncTax / sumRowData.amountIncTax;
				Decimal keyDiscountRatio = sumRowData.priceAmountSum == 0 ? 0 : taxRow.amountIncTax / sumRowData.priceAmountSum;
				larger = math.max(keyDiscountRatio, larger);
				// 集计占比例最大的税种别
				disTaxMaxMap.put(larger, taxRate);
				// 值引行Info
				DisAmountRowData disItem = new DisAmountRowData();
				disItem.taxRate = taxRate;
				// 值引拔
				disItem.disUnitPriceSum = CommUtils.RoundProcess((disMaxFlg ? taxRow.amountExcTax : ((disEnd * keyDiscountRatio) / (1+taxRate))), gPointLen);
				// 值引税
				disItem.disTaxAmountSum = CommUtils.RoundProcess((disMaxFlg ? taxRow.taxAmount : ((disEnd * keyDiscountRatio) - disItem.disUnitPriceSum)), gPointLen);
				// 値引 合计值 税拔
				disRowData.disUnitPriceSum += disItem.disUnitPriceSum;
				// 値引き合計行目の金額を計算する（該当金額は税率混在の金額を合計する
				disRowData.disTaxAmountSum += disItem.disTaxAmountSum;
				// 最终差值
				disSumEnd -= (disItem.disUnitPriceSum + disItem.disTaxAmountSum);
				// 值引行集计
				disRowDataLst.add(disItem);
				// 值引行集计
				disRowDataMap.put(taxRate, disItem);
				// 当前構成比率 * 当前消费税
				ratioSum += keyDiscountRatio * taxRate;
			}
			// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
			taxRowDataLst.add(taxRow);//消費税リスト情報を格納する
		}
		// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
		// 値引き明細行目合計値は値引き合計金額と一致しない場合、差分金額は値引行目の税抜列の最大行目に金額を差分設定する
		if(!disMaxFlg && disTaxMaxMap.containsKey(larger) && disSumEnd != 0){
			Decimal taxRate = disTaxMaxMap.get(larger);
			DisAmountRowData disItem = disRowDataMap.get(taxRate);
			// 差值找平
			disItem.disUnitPriceSum += disSumEnd;
			// 总差值找平
			disRowData.disUnitPriceSum += disSumEnd;
		}
		*
		// 値引き合計行目の金額を計算する（該当金額は税率混在の金額を合計する
		// 值引【总消费税金额】= 值引【税込】 - 值引【税抜(discountAllInfo.discountAmountAll/ratioSum)】
		disRowData.disTaxAmountSum = CommUtils.RoundProcess(disRowData.disUnitPriceSum - (disRowData.disUnitPriceSum / ratioSum), gPointLen);
		// 値引 合计值 税拔
		disRowData.disUnitPriceSum -= disRowData.disTaxAmountSum;
		*
		// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
		// 割引後の消費税 = 合計消費税 - 合計 値引金額に対する消費税額
		sumRowData.taxAmount -= disRowData.disTaxAmountSum;
		sumRowData.amountExcTax -= disRowData.disUnitPriceSum;
		// 最终税込
		amoutAllMoneyEnd = sumRowData.amountExcTax + sumRowData.taxAmount;
		// 负值处理(値引き消費税がマイナスの場合)
		if(sumRowData.taxAmount < 0){
			// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
			Decimal taxRate = disTaxMaxMap.get(larger);
			DisAmountRowData disItem = disRowDataMap.get(taxRate);
			// 差值找平
			disItem.disUnitPriceSum -= sumRowData.taxAmount;
			disItem.disTaxAmountSum += sumRowData.taxAmount;
			// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
			disRowData.disUnitPriceSum -= sumRowData.taxAmount;
			disRowData.disTaxAmountSum += sumRowData.taxAmount;
			sumRowData.amountExcTax += sumRowData.taxAmount;
			sumRowData.taxAmount -= sumRowData.taxAmount;
		}
		*/
		CommLogicProcess.processSumInfo(getAmoutIncDiscont(), comSum);
		taxUnitPriceAll = comSum.taxUnitPriceAll;
		// 対象行Lst
		taxRowDataLst = comSum.taxRowDataLst;
		// 值引行
		disRowData = comSum.disRowData;
		// 值引行Lst
		disRowDataLst = comSum.disRowDataLst;
		// 合计行
		sumRowData = comSum.sumRowData;
	}
	/*
	public List<TaxRowData> taxRowDataLst{get;set;}
	// map<消費税レート,該当消費税関連の金額合計>
	private map<Decimal, TaxRowData> taxRowDataMap;
	public class TaxRowData {
		public TaxRowData() {
			taxRate = amountExcTax = amountIncTax = taxAmount = 0;
			//isNoTaxPrice = isDiscountTax = false;
			isNoTaxPrice = isDiscountTax = true;
		}
		public Decimal taxRate{get{return (CommUtils.nullToZero(taxRate));}set;}	// 消費税率
		public Decimal amountExcTax{get;set;}	 	 // 税抜きの合計金額
		public Decimal amountIncTax{get;set;}	 	 // 税込きの合計金額
		public Decimal taxAmount{get;set;}		   // 該当行目の消費税合計
		public Boolean isNoTaxPrice{get;set;}		// 非課税金額
		public Boolean isDiscountTax{get;set;}	   // 割引
	}
	// 値引行
	public DisAmountRowData disRowData {get;set;}
	public class DisAmountRowData {
		public DisAmountRowData(){
			// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
			taxRate = 0;
			// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
			disTaxAmountSum = disUnitPriceSum = 0;
		}
		// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
		public Decimal taxRate{get;set;}
		// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
		public Decimal disTaxAmountSum{get;set;}		   // 該当行目の消費税合計
		public Decimal disUnitPriceSum{get;set;}
	}
	// 合计行
	public SumAmountRowData sumRowData {get;set;}
	public class SumAmountRowData {
		public SumAmountRowData(){
			taxAmount = amountExcTax = amountIncTax = priceAmountSum = 0;
		}
		public Decimal taxAmount{get;set;}		   // 該当行目の消費税合計
		public Decimal amountExcTax{get;set;}
		public Decimal amountIncTax{get;set;}		
		public Decimal priceAmountSum{get;set;}
	}
	*/
	// 2019/10/30 軽減税率割合モード機能対応 WGCH END
	// 2019/07/30 軽減税率機能対応 WGCH END
	// 2021/07/30 #JP10785 by zy BEGIN
	// 引き渡す情報を取得する
    private Map<String, String> paraMap;
    // カスタムSTYLE
    public String customeStyleStr{get;set;}
    // 增税商品的Id
    public static String oTaxIncMstCode;
	// 予約確認書XML定義情報
	// ページの印刷サイズ（ich単位）
    public String pageformat{get; private set;} 
    // 予約確認書XML定義字段集合
    private Set<String> leadFieldSet;
    // 参照特殊字
    private String refPrix = '__r.';
    // 参照特殊字
    private String refNamePrix = '__r';
    // 通常特殊字
    private String commPrix = '__c';
    // 字段特殊字
    private String pointPrix = '.';
    // 予約確認書既存字段集合
    private Set<String> nuplicateSet = new set<String>{'id','LeadIndexRef__c','LeadIndexSubId__c,RoomGroupNo__c',
                                        'EntryTime__c','Field348__c','ReservedContact__c','ReservedDate__c',
                                        'Field4__c','LastModifiedBy.Name','Relcontact__c','Relcontact__r.Name',
                                        'Relcontact__r.MailingPostalCode','Relcontact__r.MailingStreet',
                                        'Relcontact__r.MailingState','Relcontact__r.MailingCountry',
                                        'Relcontact__r.MailingCity','Relcontact__r.Phone','Relcontact__r.Phone2__c',
                                        'Relcontact__r.MobilePhone','Relcontact__r.HomePhone','Relcontact__r.Fax',
                                        'Relcontact__r.Fax2__c','LeadIndexRef__r.Name',
                                        'LeadIndexRef__r.contactRef__r.Name','Field3__c','Departure__c',
                                        'LeadIndexRef__r.EntryDate__c','LeadIndexRef__r.DepartureDate__c'};
    // 予約人数
    private static final String personNumber = 'PersonNumber';
    // 大人人数
    private static final String adultNumber = 'AdultNumber';
    // 子供人数
    private static final String childNumber = 'ChildNumber';
    // 部屋数
    private static final String roomNumber = 'RoomNumber';
    // 宿泊数
    private static final String nightNumber = 'NightNumber';
    private static final String shopPostNo = 'ShopPostNo';
    private static final String shopName = 'ShopName';
    private static final String shopAddress = 'ShopAddress';
    private static final String shopPhone = 'ShopPhone';
    private static final String shopFax = 'ShopFax';
    private static final String shopEmail = 'ShopEmail';
    private static final String shopWebSite = 'ShopWebSite';
    private static final String honorific = 'Honorific';
    private static final String comment = 'Comment';
    // シスタム日付
    private static final String systemDate = 'SystemDate';
    private static final String CONST_DATEFORMAT = 'yyyy/MM/dd';
    private static final String commentHtml = '<COMMENT></COMMENT>';
    // 特殊字段名
    private Set<String> excludeSet = new Set<String>{personNumber,adultNumber,childNumber,roomNumber,nightNumber,shopPostNo,shopName,shopAddress,shopPhone,shopFax,shopEmail,shopWebSite,honorific,comment,systemDate};
    // 見積明細HTML中にHEADのHTML
    private String detailHeadHtml = '<tr class="headRow"><td>利用日</td><td>部屋タイプ</td><td>内容</td><td>数</td><td style="border-right:none;">金額</td></tr>';
    // 見積明細HTML中に空白のHTML
    private String balnkHtml = '<tr class="blankRow"><td></td><td></td><td></td><td></td><td style="border-right:none;"></td></tr>';
    // 見積明細HTML中に明細のHTML
    private String detailContentHtml = '<tr class="detailRow"><td>_date_</td><td>_roomtype_</td><td>_content_</td><td class="numClass">_cnt_</td><td class="numClass" style="border-right:none;">_price_</td></tr>';
    // 見積明細HTML中にFOOTのHTML
    private String footContentHtml = '<tr class="lastRow"><td>合計</td><td></td><td></td><td class="numClass">_cnt_</td><td class="numClass" style="border-right:none;">_price_</td></tr>';
    // 列の横幅設定
    private String estColGroupStr;
    // SOBJECTの字段集合
    private Map<String,Map<String, Schema.DescribeFieldResult>> sobjectMap;
    // 見積明細のHTMLを作成機能
    private String createDetailHtml(OnePageInfo curPage , String otherAttr) {
        String html = '<table class="estItemClass" _otherAttr_>'.replace('_otherAttr_',CommUtils.nullTOBlank(otherAttr));
        if (!CommUtils.isBlank(estColGroupStr)) {
            html += estColGroupStr;
        }
        html += detailHeadHtml;
        integer lastIdx = curPage.details.size() - 1;
        for (integer i = 0 ; i < curPage.details.size() ; i++ ){
            BookItem item = curPage.details[i];
            if (i == lastIdx) {
                html += footContentHtml.replace('_price_',OrderServiceHelp.currency(summaryInf.amoutPrice))
                                    .replace('_cnt_',CommUtils.nullToBlank(CommUtils.nullToIntZero(summaryInf.totalAmount)));
                continue;
            }
            if (item == null || item.s.id == null) {
                html += balnkHtml;
                continue;
            }
            String userDateStr = item.useDate == null ? '' : DateTime.newInstance(item.useDate.Year(),item.useDate.month(),item.useDate.day()).format('yyyy/MM/dd');
            String roomName = '';
            if (item.s.refBooking__r != null && item.s.refBooking__r.Rroom__r != null){
                roomName = item.s.refBooking__r.Rroom__r.Name;
            }
            html += detailContentHtml.replace('_date_',userDateStr)
                    .replace('_roomtype_', roomName)
                    .replace('_content_',item.productNm)
                    .replace('_cnt_',CommUtils.nullToBlank(Commutils.nullToIntZero(item.unitNums)))
                    .replace('_price_',OrderServiceHelp.currency(CommUtils.nullToZero(item.amount)));
        }
        html += '</table>';
        return html;
    }
    // HTML用API名
    private String getHtmlApiStr(String api){
    	return '$$_' + api + '_$$';
    }
    // Sobjectの値で字段の名を取得
    private String getFieldValue(Lead__c lead,String apiName){
        String typeName = Lead__c.sObjectType.getDescribe().getLabel(),result; 
        String customField = apiName.toLowerCase();
        if (!sobjectMap.containsKey(typeName)) {
            if (!sobjectMap.containsKey(typeName)) {
                sobjectMap.put(typeName,CommSqlUtils.getAllFieldLst(Lead__c.sObjectType,false,true));
            }
        }
        Map<String, Schema.DescribeFieldResult> valuesMap = sobjectMap.get(typeName);
        boolean isRefFlg = customField.contains(refPrix);
        boolean isPointFlg = customField.contains(pointPrix);
        if (isRefFlg || isPointFlg) {
            String refName = customField.substringBefore(isPointFlg ? pointPrix : refPrix);
            String curFieldName = refName.replace(refNamePrix,commPrix);
            String fieldName = customField.substringAfter(isPointFlg ? pointPrix : refPrix);
            if (valuesMap.containsKey(curFieldName)) {
                Schema.DescribeFieldResult dr = valuesMap.get(curFieldName);
                Schema.sObjectType refType = dr.getReferenceTo()[0];
                typeName = refType.getDescribe().getLabel();
                if (!sobjectMap.containsKey(typeName)) {
                    sobjectMap.put(typeName,CommSqlUtils.getAllFieldLst(refType,false,true));
                }
                Map<String, Schema.DescribeFieldResult> curValuesMap = sobjectMap.get(typeName);
                if (curValuesMap.containsKey(fieldName)) {
                    Schema.DescribeFieldResult refDr = curValuesMap.get(fieldName);
                    Sobject refSobj = lead.getSobject(dr.getRelationshipName());
                    // ２０１７/10/12 アレルギー更新 by zy BEGIN
                    result = getObjectStrVal(refSobj.get(fieldName),refDr.getType());
                    // ２０１７/10/12 アレルギー更新 by zy END
                }
            }
        } else {
            if (valuesMap.containsKey(customField)) {
                Schema.DescribeFieldResult dr = valuesMap.get(customField);
                result = getObjectStrVal(lead.get(customField),dr.getType());
            }
        }
        return result;
    }
    // Sobjectのフォーマット文字列値を取得します
    private String getObjectStrVal(object value ,Schema.DisplayType fieldType){
        String fieldVal;
        if(fieldType == Schema.DisplayType.DATE && value != null) {
            Date val = (Date)value;
            fieldVal = DateTime.newInstance(val.year(),val.month(),val.day()).format(CommBaseCtrl.getDateFormat());
        }
        else if(fieldType == Schema.DisplayType.TIME && value != null) {
            Time val = (Time)value;
            if (val != null) {
                DateTime ft = DateTime.newInstance(Date.today(), val);
                fieldVal = ft.format(CommBaseCtrl.getTimeFormat());
            }
        }
        else if(fieldType == Schema.DisplayType.DATETIME &&  value != null) {
            fieldVal = ((Datetime)value).format(CommBaseCtrl.getDateTimeFormat());
        }
        else if(fieldType == Schema.DisplayType.TEXTAREA &&  value != null) {
            list<String> splitAreasLst = CommUtils.nullToBLank(value).split('\n');
            String splitVal= '';
            for(String str : splitAreasLst){
                if(!CommUtils.isBlank(str)){
                    // 2019/12/10 空白格不作为换行处理 BY zyz BEGIN
                    splitVal += str + '<br/>';
                    // 2019/12/10 空白格不作为换行处理 BY zyz END
                }
            }
            splitVal = splitVal.removeEnd('<br/>');
            fieldVal = splitVal;
        } else {
            fieldVal = CommUtils.nullTOBlank(value);
        }
        return fieldVal;
    }
    // 関連の予約を取得
    public String getLeadindexByLeads(String leadId,String shopCode){
        String leadQuery = 'select ' + String.join(new List<String>(nuplicateSet), ',') + ' from Lead__c where Id = :leadId And CancelBool__c != ' + CommConst.LEAD_ST_CANCEL_FLG;
        List<Lead__c> leadInfLst = database.query(leadQuery);
        if (leadInfLst.isEmpty()) {
            return null;
        }
        // XML定義情報を取得する
        String xmlConfigName = 'ApplicationFormPdfConfig';
        oXmlInfo = new XmlConfigInfo(CommXmlUtils.parseXmlDoc(xmlConfigName, shopCode));
        Integer cancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
        String leadIndexId = leadInfLst[0].LeadIndexRef__c;
        String queryLeadStr = ' select id, Name, LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c from Lead__c ' 
        						+ ' where LeadIndexRef__c = :leadIndexId And CancelBool__c != :cancelFlg ';
        if(!CommUtils.isBlank(oXmlInfo.bfLeadWhere)) queryLeadStr += ' and ( ' +oXmlInfo.bfLeadWhere +' ) ';
        List<Lead__c> leads = DataBase.query(queryLeadStr);
        if (leads.isEmpty()) {
            return null;
        }
        // 有効な予約ID情報を格納する
        Set<Id> allValLeadIds = new set<Id>();
        // 初日の予約情報を取得する【予約インデックス+'_'+予約インデックスSUB+'_'+グループNO】
        Set<String> firstLeadIdSet = new Set<String>();
        Set<Id> targetLeadIds = new Set<Id>();
        for (Lead__c lead : leads) {
            // 全部関連の予約ID情報を格納する
            allValLeadIds.add(lead.Id);
            // 初日のみ予約情報
            String key = lead.LeadIndexRef__c + '_' + CommUtils.nullToBlank(lead.LeadIndexSubId__c) + '_' + CommUtils.nullToBlank(lead.RoomGroupNo__c);
            if (firstLeadIdSet.contains(key)) continue;
            firstLeadIdSet.add(key);
            targetLeadIds.add(lead.Id);
        }
        // 2013/01/11 EDIT  Rroom__r.Rnumber__c -> Rroom__r.Name
        List<Lead__c> rsLeads = [  Select Id, Name, 
                                Rroom__r.Name, Relcontact__c, Relcontact__r.Name,
                                LeadIndexSubId__c, LeadIndexRef__c, RoomGroupNo__c,
                                EntryTime__c, Departure__c,
                                Morimongn__c,           // 食数
                                StayPersons__c, Mans__c, Femails__c,ChildFA__c,Childs__c,ChildC__c,ChildD__c,ChildE__c,ChildF__c, //  人數
                                refTypeOfRooms__r.Name  // 部屋タイプ
                                From Lead__c where Id in :targetLeadIds];
        HeaderInfo locHeader = new HeaderInfo(rsLeads, oXmlInfo, leadInfLst[0]);
       	Map<String,String> resultMap = new Map<String,String>{
            PersonNumber => Commutils.nullToBlank(CommUtils.nullToIntZero(locHeader.stayPeoples)),
            adultNumber => Commutils.nullToBlank(CommUtils.nullToIntZero(locHeader.adult)),
            childNumber => Commutils.nullToBlank(CommUtils.nullToIntZero(locHeader.stayChildren)),
            roomNumber => Commutils.nullToBlank(CommUtils.nullToIntZero(locHeader.usedRooms)),
            nightNumber => Commutils.nullToBlank(CommUtils.nullToIntZero(locHeader.stayDays))
        };
        String result = JSON.serialize(resultMap);
        return result;
    }
    // 指定TAG名分割html機能
    private List<PageColumn> convertCommentPage(String html,String tagName){
    	// 分割後でhtml元素リスト
        List<PageColumn> columns = new List<PageColumn>();
        // 開始TAG
        String befTag = '<' + tagName;
        // 終了TAG
        String endTag = '</' + tagName + '>';
        // 開始HTML
        String beforeHtml = html.substringBefore(befTag);
        // 終了TAG
        String afterHtml = html.substringAfter(endTag);
        // 指定TAGーHTML
        String content = html.replace(beforeHtml, '').replace(afterHtml, '');
        // TAG前にHTML元素を作成する
        if (!CommUtils.isBlank(beforeHtml)) {
            columns.add(new PageColumn(beforeHtml));
        }
        // TAGのHTML元素を作成する
        if (!CommUtils.isBlank(content)) {
            Dom.Document estDoc = new Dom.Document();
            estDoc.load(content);
            Dom.XmlNode estNode = estDoc.getRootElement();
            String style = null;
            String label = null;
            if (estNode != null) {
                style = CommUtils.nullTOBlank(estNode.getAttribute('style', null));
                label = CommUtils.nullTOBlank(estNode.getAttribute('label', null));
            }
            columns.add(new PageColumn(style,label));
        }
        // TAG後にHTML元素を作成する
        if (!CommUtils.isBlank(afterHtml)) {
            columns.add(new PageColumn(afterHtml));
        }
        return columns;
    }
    // 画面カスタム元素
    public Class PageColumn{
    	// html元素フラグ
        public boolean isHtml{get;set;}
        // STYLE設定
        public String styleStr{get;set;}
        // ラベル字段
        public String labelHtml{get;set;}
        // コメント内容
        public String content{get;set;}
        // コメントフラグ
        public boolean isComment{get;set;}
        // 初期化
        public PageColumn(String html){
            isHtml = true;
            content = html;
        }
        // コメントの初期化
        public PageColumn(String style,String label){
            isHtml = false;
            styleStr = style;
            labelHtml = label;
            isComment = true;
        }
    }
    // 2021/07/30 #JP10785 by zy END
}