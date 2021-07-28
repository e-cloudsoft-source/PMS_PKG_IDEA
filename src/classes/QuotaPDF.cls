/*
 * 機能名     : 見積書PDF
 * ファイル名 : QuotaPDF.cls
 *
 *  VERSION    DATE        BY          CHANGE/COMMENT
 * ----------------------------------------------------------------
 *  1.00       2018/10/24  ZY         Create
 *             2019/04/30  zyz        増税仮対応
 *             2019/09/30  zyz        見積書で印刷した際に、商品名が折り返し出力できるように改善対応
 *             2020/06/30  zyz        見積書のレイアウトは請求書のレイアウトに統一に改善対応
 */
public with sharing class QuotaPDF {

    private quota__c quota;
    private final Integer MAX_SHOW_DETAIL_ROWS = 27;
    private Integer pointlen{get; private set;} // 小数桁数情報格納
    public String currencyMark{get; private set;}   // 通貨MARK
    public String currencyUnit{get; private set;}   // 通貨単位
    public Boolean isForeignCurrency{get; private set;} // 外貨するがどうかチェックする
    public String taxEnglishLabel{get; private set;}    // 内消費税英語表示文言
    public String shopcd{get; private set;} // 2015/08/14 見積書は印刷の店舗コード
    // 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
    private Boolean isAccountProdNmReturnFlg{get{ return CommConst.ACCOUNT_PRODNM_FLG;}}
    private transient map<String,List<String>> proNameMap = new map<String, List<String>>();
    // 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
    // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
    public Boolean RespectFlg{get; set;}
    // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
    // 2020/06/30 見積書のレイアウトは請求書のレイアウトに統一に改善対応 BY zyz BEGIN
    // true:总金额位置显示在左上角；false:总金额显示在右下角的原位置
    public Boolean allAmountShowFlg{get{ return CommConst.LEAD_BOOKING_LAYOUT_FLG;}}
    private Boolean commentShowFlg{get;set;}
    // 2020/06/30 見積書のレイアウトは請求書のレイアウトに統一に改善対応 BY zyz END
    // 2020/06/30 増税仮BUG fix  BY zyz BEGIN
    // 超过100笔数据报错，for循环内检索sql。原bug对应：LeadPDF.cls-[2019/05/31 増税仮BUG FIX]
    public static CommLogicProcess.TaxIncMstInfo info{get{ if(info == null) info = CommLogicProcess.getTaxIncMstInfo(); return info;}}
    // 2020/06/30 増税仮BUG fix BY zyz END
    public Boolean stampIsShowFlg{get{
        // 予約の設定値を取得する
        Boolean defaultFlg = CommDefine__c.getOrgDefaults().BookingReportStampIsShowFlg__c;
        if (quota != null) {
            if (CommUtils.isBlank(quota.StampIsShowDiv__c)) return defaultFlg;
            else return (CommUtils.nullToBlank(quota.StampIsShowDiv__c) != '0' );
        } else return defaultFlg;
    }}
    // 2016/01/12 自動改行制御機能追加 BEGIN
    public Boolean isCommentAutoBreakFlg{get{return CommDefine__c.getOrgDefaults().BillReportCommentAutoBreakFlg__c;}}
    // 2016/01/12 自動改行制御機能追加 END
    public String controllerId;
    public QuotaPDF(ApexPages.StandardController controller){
    	controllerId = controller.getId();
    	 // Ver1.02 2014/07/29 外貨表示対応追加 BEGIN
        String currencyInf = UserInfo.getDefaultCurrency();         // ログインユーザーの組織通貨を取得する
        if (CommUtils.isBlank(currencyInf)) currencyInf = 'JPY';    // 組織通貨設定がNULLの場合、通貨JPY(日本円)に設定する
        pointlen = CommUtils.getPointLen(currencyInf);              // 通貨をにより、小数点桁数を取得する
        // 画面通貨のMARK設定する
        currencyMark = CommUtils.getCurrencyMark(currencyInf);
        currencyUnit = CommUtils.getCurrencyUnit(currencyInf);
        // 2018/06/08 レシート印刷機能言語選択する WGCH BEGIN
        // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
        // quota = [select id, Name, StampIsShowDiv__c, QuotationName__c,LeadPdfShopCode__c, LeadReceiptDate__c, QuotaName__c, QuotaStatus__c, ExpirationDate__c,LeadRef__r.LeadPdfShopCode__c,LeadRef__r.Relcontact__r.name, LeadRef__r.EntryTime__c ,QuotationComment__c,QuotaDescription__c,MainQuotaFlg__c,Language__c from quota__c where id = : controllerId][0];
        // 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH BEGIN
        // quota = [select id, Name, StampIsShowDiv__c, QuotationName__c,LeadPdfShopCode__c, LeadReceiptDate__c, QuotaName__c, QuotaStatus__c, ExpirationDate__c,LeadRef__r.LeadPdfShopCode__c,LeadRef__r.Relcontact__r.name, LeadRef__r.EntryTime__c ,QuotationComment__c,QuotaDescription__c,MainQuotaFlg__c,Language__c,RespectLst__c from quota__c where id = : controllerId][0];
        quota = [select id, Name, StampIsShowDiv__c, QuotationName__c,LeadPdfShopCode__c, LeadReceiptDate__c, QuotaName__c, QuotaStatus__c, ExpirationDate__c,LeadRef__r.LeadPdfShopCode__c,LeadRef__r.Relcontact__r.name, LeadRef__r.EntryTime__c ,QuotationComment__c,QuotaDescription__c,MainQuotaFlg__c,Language__c,RespectLst__c,LeadRef__r.ShopCodeCal__c from quota__c where id = : controllerId][0];
        // 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH END
        RespectFlg = CommConst.RESPECT_ISSHOW_FLG;
        if(CommUtils.isBlank(quota.RespectLst__c) || !RespectFlg) quota.RespectLst__c = '様';
        // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
        // isForeignCurrency = CommUtils.isForeignCurrency(currencyInf);
        isForeignCurrency = CommUtils.isForeignCurrency(CommUtils.isBlank(quota.Language__c) ? currencyInf : quota.Language__c);
        // 2018/06/08 レシート印刷機能言語選択する WGCH END
        // Ver1.02 2014/07/29 外貨表示対応追加 END
        //query '予約' current page
        // 2015/01/26 ハンコ表示・非表示制御機能追加
        // 2015/12/03 換行 Fix BEGIN
        // 2016/01/12 自動改行制御機能追加 BEGIN
        if (isCommentAutoBreakFlg) {
        	quota.QuotationComment__c = CommRepUtils.getPdfMaxShowStringNew(quota.QuotationComment__c,6,24);
        }
        // 2016/01/12 自動改行制御機能追加 END
        // 2015/12/03 換行 Fix END
        // 2020/06/30 見積書のレイアウトは請求書のレイアウトに統一に改善対応 BY zyz BEGIN
        commentShowFlg = true;
        if(!CommUtils.isBlank(quota.QuotationComment__c)) commentShowFlg = false;
        // 2020/06/30 見積書のレイアウトは請求書のレイアウトに統一に改善対応 BY zyz END
        // Ver1.01 Edit Begin
        quota.LeadReceiptDate__c = ( quota.LeadReceiptDate__c == null ? Date.today() : quota.LeadReceiptDate__c);
        // Ver1.01 Edit End
        // 2015/08/14 見積書に個別指定の店舗の場合 BEGIN
        shopcd = CommUtils.isBlank(quota.LeadPdfShopCode__c) ? CommUtils.nullToBlank(quota.LeadRef__r.LeadPdfShopCode__c) : quota.LeadPdfShopCode__c;
        if (!CommUtils.isBlank(shopcd)) {
            // 見積書は指定店舗で出力の場合、現在のユーザーは店舗コードは複数店舗兼務じやない場合、ログインのデイフォル店舗コードで優先
            UserUtil.UserShopInfo usrInf = UserUtil.CurrentUserInfo;
            if (!usrInf.isShopCodePlex) {
                shopcd = usrInf.defaultShopCode;
                // 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH BEGIN
                // 获取店铺默认设定Code
                shopcd = ShopInfoUtil.getShopDefCd(shopcd, quota.LeadRef__r.ShopCodeCal__c, usrInf.defaultShopCode);
                // 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH END
            }
        } else {
            shopcd = UserUtil.CurrentUser.ShopCode__c;
            // 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH BEGIN
            // 获取店铺默认设定Code
            shopcd = ShopInfoUtil.getShopDefCd(shopcd, quota.LeadRef__r.ShopCodeCal__c, UserUtil.CurrentUser.ShopCode__c);
            // 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH END
        }
        // 2015/08/14 見積書に個別指定の店舗の場合 END
        // 到着日の当日の消費税率を取得する
        // 2014/03/04 消費税設定値は見積明細の設定により、取得する
        //Decimal taxRate = CommUtils.nullToZero(CommUtils.getTaxRate(lead.EntryTime__c.date()));
        Decimal taxRate = 0;
        List<QuotaItem__c> taxItems = [   select TaxRate__c from QuotaItem__c
                                                where QuotaRef__c = :controllerId and Accountoutside__c = 1
                                                And InvoiceNoShowFlg__c = false
                                                And TaxRate__c > 0 limit 1];
        if (!taxItems.isEmpty()) taxRate = taxItems[0].TaxRate__c;
        // 2015/06/19 支払種別から関連の支払メディアに変更情報を取得する
        // 2015/08/14 見積書に個別指定の店舗の場合 BEGIN
        Map<String, String> paymentTypeToMediaLabMap = (new BillSimpleHelp(shopcd)).getPaymentTypeToMediaLabMap();
        // 2015/08/14 見積書に個別指定の店舗の場合 END
		// 2017/02/28  一括見積書PDF出力機能対応  begin by wx
        //query '見積明細' current page
        List<BookItem> bookItemLst = new List<BookItem>();
		// 2017/02/28  一括見積書PDF出力機能対応  end by wx
        // 2014/08/01 小数点桁数統一管理ため、小数点桁数引き渡しで処理追加
        //sumInfo = new TotalInfo(taxRate);
        sumInfo = new TotalInfo(taxRate, pointlen);
        // 金額計算共通クラス
        //CommUtils.ProductInfo proc = new CommUtils.ProductInfo();
        // 外貨の小数点対応するため、修正する
		// 2016/03/31 サビース料金は明細として、請求書に表示の対応 BEGIN
		gServiceOuputFlg = ShopInfoUtil.isShowServiceCharge(shopCd);
		// 2016/03/31 サビース料金は明細として、請求書に表示の対応 END
		// 2016/04/08 サビース料金は明細として、請求書に表示の対応[サービス料表示モード２] BEGIN
		String serviceOutputDiv = ShopInfoUtil.getShowServiceChargeMode(shopCd);
		gIsServieModeOuter = serviceOutputDiv == ShopInfoUtil.SERVICE_CHARGE_MODE_OUTER;
		// 2016/04/08 サビース料金は明細として、請求書に表示の対応[サービス料表示モード２] END
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		gIsServieModeInner = serviceOutputDiv == ShopInfoUtil.SERVICE_CHARGE_MODE_INNER;
		// 2019/07/30 軽減税率機能対応 WGCH END
		// 2017/07/20 サビース料税別区分 zyz BEGIN
		gserviceNoTaxFlg = ShopInfoUtil.isServiceChargeIsNoTax(shopCd);
		// 2017/07/20 サビース料税別区分 zyz END
		// 2017/02/28  一括見積書PDF出力機能対応  begin by wx
		map<string,QuotaItem__c> sortEstInfMap = new map<string, QuotaItem__c>();
		// 2017/02/28  一括見積書PDF出力機能対応  end by wx
		// 過去の合計計算不具合修正 BEGIN
        //CommUtils.ProductInfo proc = new CommUtils.ProductInfo(CommUtils.nullToIntZero(lead.UnitPriceDefKb__c),pointlen);
        List<QuotaItem__c> quitems = [select id, name, X2_1__c, Tankanonetax__c, Amount__c,TaxRate__c, UnitPriceDefKbCal__c,
                        ActionType__c,PaymentType__c,
						// 2016/12/09 見積明細利用日機能対応 BEGIN zyz
                        refBooking__r.EntryTime__c,UseDate__c,refBooking__r.Departure__c,
						// 2016/12/09 見積明細利用日機能対応 END zyz
						// 2018/06/08 レシート印刷機能言語選択する WGCH BEGIN
						refAccountMaster__r.ProductEnName__c,
						// 2018/06/08 レシート印刷機能言語選択する WGCH END
                        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
			PlanBrkInfo__c,
			// 2019/07/30 軽減税率機能対応 WGCH END
                        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
                        OptionPlanKey__c,
                        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
                        Total__c, ServiceRate__c, SpecialTax__c,GoukeinoneTax__c,UnitPrice__c, ProductName__c,SpTotal__c,rowNo__c
                        ,PlanDetailSyncInfo__c
                        ,(select UnitPrice__c,PlanDetailSyncInfo__c from QuotaItemRef__r where (TaxRate__c = null OR TaxRate__c = 0) And ParentBookingItemRef__r.ActionType__c = :CommConst.PROD_ACTION_TYPE_PL)
                        from QuotaItem__c
                        where QuotaRef__c = :controllerId and Accountoutside__c = 1 
						// 2017/02/28  一括見積書PDF出力機能対応  end by wx
                        // 2017/12/13 見積明細非表示機能対応 WGCH BEGIN
                        And InvoiceNoShowFlg__c = false
                        // 2017/12/13 見積明細非表示機能対応 WGCH END 
                        order by UseDate__c, rowNo__c, Name];
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
        // 格納用変数クリアする
        BillSimpleHelp help = new BillSimpleHelp(shopcd);
        // 支払種別ー＞支払メデイア名変換情報取得
        Map<String, String> PAYMENT_MATCH_MAP = help.getPaymentTypeToMediaLabMap();
        map<string,CommLogicProcess.HotelTaxDefineInfo> hotelTaxMap = CommLogicProcess.getHotelTaxDefInstance();
        // 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
        planNoTaxUnitPriceMap = new Map<String, Decimal>();
        // 2019/10/02 PlanHeader算法切换对应 WGCH END
        if(isReducedTaxFlg){
            // 初始化
            reducedTaxInit();
            pBrkTranItemMap = new Map<String, List<BookItem>>();
            pBrkProMap = new Map<String, CommUtils.ProductInfo>();
            planHeaderMap = new Map<String, CommUtils.ProductInfo>();
            gIsServieModeInner = serviceOutputDiv == ShopInfoUtil.SERVICE_CHARGE_MODE_INNER; // サービス料表示モード1
	    	List<QuotaItem__c> detailItem = new List<QuotaItem__c>();
	    	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
	        Set<String> planEstIdSet = new Set<String>();
	    	List<QuotaItem__c> nwquitems = new List<QuotaItem__c>();
	    	Map<String, String> planHeaderKeyMap = new Map<String, String>();
	    	Map<String, Decimal> planHeaderNumMap = new Map<String, Decimal>();
	    	Map<String, Decimal> planHeaderTaxMap = new Map<String, Decimal>();
	    	if(CommConst.OPTION_MODE == CommConst.OPTION_MODE_ON){
		    	for(QuotaItem__c sobj : quitems){
		    		if(!CommUtils.isBlank(sobj.OptionPlanKey__c) ){
		    			if(!planHeaderNumMap.containsKey(sobj.OptionPlanKey__c)){
		    				planEstIdSet.add(sobj.Id);
		    				nwquitems.add(sobj);
		    				planHeaderKeyMap.put(sobj.Id, sobj.OptionPlanKey__c);
		    				planHeaderNumMap.put(sobj.OptionPlanKey__c, 0);
		    				planHeaderTaxMap.put(sobj.OptionPlanKey__c, 0);
		    			}
		    			Decimal amountSum = CommUtils.nullToZero(sobj.Amount__c) + planHeaderNumMap.get(sobj.OptionPlanKey__c);
		    			planHeaderNumMap.put(sobj.OptionPlanKey__c, amountSum);
		    			Decimal specialTaxSum = CommUtils.nullToZero(sobj.SpecialTax__c) + planHeaderTaxMap.get(sobj.OptionPlanKey__c);
		    			planHeaderTaxMap.put(sobj.OptionPlanKey__c, specialTaxSum);
		    		} else {
		    			planEstIdSet.add(sobj.Id);
		    			nwquitems.add(sobj);
		    		}
		    	}
		    	quitems = nwquitems;
	    	}
	    	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
            for (QuotaItem__c nw  : quitems) {
            	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
            	if(!planEstIdSet.isEmpty() && !planEstIdSet.contains(nw.Id)) continue;
            	Decimal wkQty = null;
            	if(planHeaderKeyMap.containsKey(nw.Id)){
            		String planHeaderNumKey = planHeaderKeyMap.get(nw.Id);
            		nw.Amount__c = CommUtils.nullToZero(planHeaderNumMap.get(planHeaderNumKey));
            		nw.SpecialTax__c = CommUtils.nullToZero(planHeaderTaxMap.get(planHeaderNumKey));
            		wkQty = nw.Amount__c;
            	}
            	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
                if(!CommUtils.isBlank(nw.PlanBrkInfo__c)){
                    List<List<String>> brkInfoAllLst = CommLogicProcess.getPlanBrkInfoLst(CommUtils.nullToBlank(nw.PlanBrkInfo__c));
                    // 設定内容取得
                    String syncInfo = CommUtils.nullToBlank(nw.PlanDetailSyncInfo__c);
                    List<String> syncLst = syncInfo.split(';');
                    Map<String,String> orgInfoMap = new Map<String,String>();
                    for (String sync : syncLst) {
                        String[] infos = sync.split(':');
                        // 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH BEGIN
                        // String key = infos[2] + '_' + infos[1];
                        // orgInfoMap.put(key,infos[3]);
                        if(infos.size() >= 3){
							// 2019/09/15 worktile 4189 bug fix by zy BEGIN
                        	// String key = infos[2] + '_' + infos[1];
							// 2019/11/30 金額が少数点ある場合、Invalid integer不具合改修 by zy BEGIN
							// String key = infos[2] + '_' + CommUtils.nullToIntZero((CommUtils.nullToZero(infos[1])));
							String key = infos[2] + '_' + Commutils.nullToBlank(CommUtils.paddingLeftZero(CommUtils.nullToZero(infos[1]),0)).replaceAll(',','') ;
							// 2019/11/30 金額が少数点ある場合、Invalid integer不具合改修 by zy END
							// 2019/09/15 worktile 4189 bug fix by zy END
                        	orgInfoMap.put(key,infos[3]);
                        }
                        // 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH END
                    }
                    integer idx = 0;
                    // 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
					if(planBrkToHeaderCalFlg){
	                    for(List<String> brkInfoLst : brkInfoAllLst){
	                        if(brkInfoLst.size() < 8) continue;
	                        // brkInfoLst下标含义:[0]=>单价,[1]=>消费税,[2]=>サービ料,[3]=>数量,[4]=>特别税,[5]=>单价定义区分,[6]=>商品ID,[7]=>商品处理种别
	                        Decimal unitPrice = CommUtils.nullToZero(brkInfoLst[0]); // 单价
	                        Decimal tax = CommUtils.nullToZero(brkInfoLst[1]); // 消费税
	                        Decimal serviceRate = CommUtils.nullToZero(brkInfoLst[2]); // サービ料
	                        Decimal qty = CommUtils.nullToZero(brkInfoLst[3]); // 数量
	                        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
	                        if(wkQty != null) qty = wkQty;
	                        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
	                        Decimal specialTax = CommUtils.nullToZero(brkInfoLst[4]); // 特别税
	                        String unitPriceKbn = CommUtils.nullToBlank(brkInfoLst[5]); // 单价定义区分
	                        String productId = CommUtils.nullToBlank(brkInfoLst[6]); // 商品ID
	                        String actionType = CommUtils.nullToBlank(brkInfoLst[7]); // 商品处理种别
	                        String spcd = CommUtils.nullToBlank(shopcd);
	                        QuotaItem__c cloneItem = new QuotaItem__c(id = QuotaItem__c.sObjectType.getDescribe().getKeyPrefix() + CommUtils.nullToBlank(nw.id).subString(3,14) + '' +  idx);
							cloneItem.UnitPrice__c = unitPrice;
	                        cloneItem.ActionType__c = actionType;
	                        cloneItem.TaxRate__c = tax;
	                        cloneItem.ServiceRate__c = serviceRate;
	                        cloneItem.Amount__c = qty;
	                        cloneItem.SpecialTax__c = specialTax;
	                        // 合成明细Key
	                        String key = nw.id;
	                        CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullTOIntZero(unitPriceKbn));
	                        CommLogicProcess.HotelTaxInfo hotelTaxItem = CommLogicProcess.getHotelTaxInfo(spcd, actionType, unitPrice, qty, tax, serviceRate, priceInfo, hotelTaxMap);
	                        // 重置最新的PriceInfo
	                        priceInfo = hotelTaxItem.priceInfo;
	                        // planHeader 数据集合
	                        if(!planHeaderMap.containsKey(key)) planHeaderMap.put(key, new CommUtils.ProductInfo(CommUtils.nullTOIntZero(unitPriceKbn)));
	                        CommUtils.ProductInfo headerPriceInfo = planHeaderMap.get(key);
	                        // planHeader 数据合计
	                        headerPriceInfo.getAddPriceInfo(priceInfo);
	                        // BRK行—INFO赋值处理
	                        // BRK-INFO
	                        // 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
	                        // BookItem item = new BookItem(cloneItem, 0);
	                        BookItem item = new BookItem(cloneItem, 0, false);
	                        // 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
							// 2019/11/30 金額が少数点ある場合、Invalid integer不具合改修 by zy BEGIN
							// String nameKey = productId + '_' + CommUtils.nullToBlank(CommUtils.nullToIntZero(unitPrice));
	                        String nameKey = productId + '_' + CommUtils.nullToBlank(CommUtils.paddingLeftZero(CommUtils.nullToZero(unitPrice),0)).replaceAll(',','');
							// 2019/11/30 金額が少数点ある場合、Invalid integer不具合改修 by zy END
	                        item.productName = CommUtils.nullTOBlank(orgInfoMap.get(nameKey));
	                        // 最终单价重置
		            		item.sobj.UnitPrice__c = priceInfo.unitPriceTax;
	                        // 最终消费税重置
	                        item.taxUnitPrice = priceInfo.priceTax;
	                        // BRK行—合计值-赋值
		            		item.sobj.SpTotal__c = item.unitPrice * qty;
							// 明细对应的priceInfo
							pBrkProMap.put(item.sobj.Id, priceInfo);
	                        if(!pBrkTranItemMap.containsKey(key)) pBrkTranItemMap.put(key, new List<BookItem>());
	                        pBrkTranItemMap.get(key).add(item);
							idx++;
	                    }
					} else {
						Decimal hasTaxUnitPrice = 0;
						Decimal noTaxUnitPrice = 0;
	                 	for(List<String> brkInfoLst : brkInfoAllLst){
	                        if(brkInfoLst.size() < 8) continue;
	                        // brkInfoLst下标含义:[0]=>单价,[1]=>消费税,[2]=>サービ料,[3]=>数量,[4]=>特别税,[5]=>单价定义区分,[6]=>商品ID,[7]=>商品处理种别
	                        Decimal unitPrice = CommUtils.nullToZero(brkInfoLst[0]); // 单价
	                        Decimal tax = CommUtils.nullToZero(brkInfoLst[1]); // 消费税
	                        Decimal serviceRate = CommUtils.nullToZero(brkInfoLst[2]); // サービ料
	                        Decimal qty = CommUtils.nullToZero(brkInfoLst[3]); // 数量
	                        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
	                        if(wkQty != null) qty = wkQty;
	                        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
	                        Decimal specialTax = CommUtils.nullToZero(brkInfoLst[4]); // 特别税
	                        String unitPriceKbn = CommUtils.nullToBlank(brkInfoLst[5]); // 单价定义区分
	                        String productId = CommUtils.nullToBlank(brkInfoLst[6]); // 商品ID
	                        String actionType = CommUtils.nullToBlank(brkInfoLst[7]); // 商品处理种别
	                        String spcd = CommUtils.nullToBlank(shopcd);
	                        if(tax > 0) hasTaxUnitPrice += CommUtils.nullToZero(unitPrice);
							else if(tax == 0) noTaxUnitPrice += CommUtils.nullToZero(unitPrice);
							/*
	                        QuotaItem__c cloneItem = new QuotaItem__c(id = QuotaItem__c.sObjectType.getDescribe().getKeyPrefix() + CommUtils.nullToBlank(nw.id).subString(3,14) + '' +  idx);
							cloneItem.UnitPrice__c = unitPrice;
	                        cloneItem.ActionType__c = actionType;
	                        cloneItem.TaxRate__c = tax;
	                        cloneItem.ServiceRate__c = serviceRate;
	                        cloneItem.Amount__c = qty;
	                        cloneItem.SpecialTax__c = specialTax;
	                        // 合成明细Key
	                        String key = nw.id;
	                        CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullTOIntZero(unitPriceKbn));
	                        CommLogicProcess.HotelTaxInfo hotelTaxItem = CommLogicProcess.getHotelTaxInfo(spcd, actionType, unitPrice, qty, (tax > 0 ? nw.TaxRate__c : 0), nw.ServiceRate__c, priceInfo, hotelTaxMap);
	                        // 重置最新的PriceInfo
	                        priceInfo = hotelTaxItem.priceInfo;
	                        // planHeader 数据集合
	                        if(!planHeaderMap.containsKey(key)) planHeaderMap.put(key, new CommUtils.ProductInfo(CommUtils.nullTOIntZero(unitPriceKbn)));
	                        CommUtils.ProductInfo headerPriceInfo = planHeaderMap.get(key);
	                        // planHeader 数据合计
	                        headerPriceInfo.getAddPriceInfo(priceInfo);
	                        // BRK行—INFO赋值处理
	                        // BRK-INFO
	                        BookItem item = new BookItem(cloneItem, 0);
	                        String nameKey = productId + '_' + CommUtils.nullToBlank(CommUtils.nullToIntZero(unitPrice));
	                        item.productName = CommUtils.nullTOBlank(orgInfoMap.get(nameKey));
	                        // 最终单价重置
		            		item.sobj.UnitPrice__c = priceInfo.unitPriceTax;
	                        // 最终消费税重置
	                        item.taxUnitPrice = priceInfo.priceTax;
	                        // BRK行—合计值-赋值
		            		item.sobj.SpTotal__c = item.unitPrice * qty;
							// 明细对应的priceInfo
							pBrkProMap.put(item.sobj.Id, priceInfo);
	                        if(!pBrkTranItemMap.containsKey(key)) pBrkTranItemMap.put(key, new List<BookItem>());
	                        pBrkTranItemMap.get(key).add(item);
							idx++;
							*/
	                    }
	                    CommUtils.ProductInfo planPriceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(nw.UnitPriceDefKbCal__c));
						// 当前行含税单价计算处理
						planPriceInfo.process(hasTaxUnitPrice, CommUtils.nullToZero(nw.Amount__c), CommUtils.nullToZero(nw.TaxRate__c), CommUtils.nullToZero(nw.ServiceRate__c));
						// planHeader 数据集合
						if(!planHeaderMap.containsKey(nw.Id)) planHeaderMap.put(nw.Id, new CommUtils.ProductInfo(CommUtils.nullToIntZero(nw.UnitPriceDefKbCal__c)));
						CommUtils.ProductInfo headerPriceInfo = planHeaderMap.get(nw.Id);
						// planHeader 数据合计
						headerPriceInfo.getAddPriceInfo(planPriceInfo);
						// 当前行不含税单价计算处理
						planNoTaxUnitPriceMap.put(nw.Id, noTaxUnitPrice);
						// if(noTaxUnitPrice > 0){
							// 当前行不含税单价计算处理
							// planPriceInfo.process(noTaxUnitPrice, CommUtils.nullToZero(nw.Amount__c), 0, CommUtils.nullToZero(nw.ServiceRate__c));
							// planHeader 数据合计
							// headerPriceInfo.getAddPriceInfo(planPriceInfo);
						//}
	                 }
                }
            }
        }
        // 2019/07/30 軽減税率機能対応 WGCH END
        // 見積明細数据的MAP
        map<String,list<QuotaItem__c>> EstimateListMap = new map<String,list<QuotaItem__c>>();
		String EstimateIdStr = '';
        for (QuotaItem__c booking : quitems) {
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			// 集计值引
			if( isReducedTaxFlg && (booking != null && (PAYMENT_MATCH_MAP.get(booking.PaymentType__c) == CommConst.MEDIA_TYPE_12) )) amoutIncDiscontAll = CommUtils.nullToZero(amoutIncDiscontAll) + CommUtils.nullToZero(booking.SpTotal__c);
			// 2019/07/30 軽減税率機能対応 WGCH END
        	// 予約インデックス 的值
        	EstimateIdStr = CommUtils.nullToBlank(booking.refBooking__r.LeadIndexRef__c);
        	String keyGroup = '';
        	// 予約インデックス  + 分割NO 做成的key
        	String keyStr = EstimateIdStr;
        	if (!EstimateListMap.containsKey(keyStr)) EstimateListMap.put(keyStr, new list<QuotaItem__c>());
        	EstimateListMap.get(keyStr).add(booking);
        }
        integer idx = 0;
        // 過去の合計計算不具合修正 END
		for(QuotaItem__c s: quitems) {
            // 2018/06/08 レシート印刷機能言語選択する WGCH BEGIN
            if(isForeignCurrency && !CommUtils.isBlank(s.refAccountMaster__r.ProductEnName__c)) 
            	s.ProductName__c = s.refAccountMaster__r.ProductEnName__c;
            // 2018/06/08 レシート印刷機能言語選択する WGCH END
            	// Sort用キーワードを作成する　
            	sortEstInfMap.put(getSortKey(s) + '_' + idx,s);
            	idx ++;
            }
            // SORT処理を行う　
            List<String> sortList = new List<String>(sortEstInfMap.keySet());
            //sortList.sort();
            for (String key : sortList) {
            	QuotaItem__c s = sortEstInfMap.get(key);
            // 2017/02/28  一括見積書PDF出力機能対応  End by wx
                        // 2016/12/09 見積明細利用日機能対応 END zyz	
            // Ver4.54       2014/08/05  E-CLOUD     過去の合計計算不具合修正        
            CommUtils.ProductInfo proc = new CommUtils.ProductInfo(CommUtils.nullToIntZero(s.UnitPriceDefKbCal__c),pointlen);
            // 2013/01/13 商品名の表示転換
            s.ProductName__c = (CommUtils.isBlank(s.ProductName__c) ? s.X2_1__c : s.ProductName__c);
            // 数量小数点対応
            // 合計金額から宿泊税をは外す[表示要合計金額 = 合計金額ー宿泊税]
            s.SpTotal__c = CommUtils.nullToZero(s.Total__c) - CommUtils.nullToZero(s.SpecialTax__c);
            // 2015/10/27 プラン明細に非課税明細情報を取得する BEGIN
            // 2015/11/25 数量は０の場合、不具合対応 BEGIN
            Decimal unitPrice = 0;
				// 2019/07/30 軽減税率機能対応 WGCH BEGIN
				Decimal unitPriceEnd = 0;
				Decimal taxUnitPrice = 0;
				Decimal unitPriceExcServiceEnd = 0;
				Decimal unitPriceIncServiceEnd = 0;
				// 2019/07/30 軽減税率機能対応 WGCH END
            // 非課税明細が含める場合
            Decimal noTaxUnitPriceSum = 0;
			// 2016/03/31 サビース料金は明細として、請求書に表示の対応 BEGIN
			Decimal noServiceUnitPrice = 0;
			// 2016/03/31 サビース料金は明細として、請求書に表示の対応 END
            // 元の単価から、税抜金額を外して、税込み金額を計算する
            Decimal incTaxUnitPrice = CommUtils.nullToZero(s.UnitPrice__c) - noTaxUnitPriceSum;
            proc.process(incTaxUnitPrice, Commutils.nullToZero(s.Amount__c) , s.TaxRate__c, s.ServiceRate__c);
            if (s.UseDate__c == null) s.UseDate__c = quota.LeadRef__r.EntryTime__c.date();
				// 2019/07/30 軽減税率機能対応 WGCH BEGIN
				if (isReducedTaxFlg) {
            	if(planHeaderMap != null && planHeaderMap.containsKey(s.Id)) {
            		proc = planHeaderMap.get(s.Id);
            	}
            	// 税抜き金額[税抜、サビース料込]	
            	unitPriceEnd = proc.unitPriceTax;
            	// 消费税金额
            	taxUnitPrice = proc.priceTax;
            	if(gServiceOuputFlg){
            		// サービス料表示モード1
            		if(gIsServieModeInner){
            			// 防止重复集计
            			// 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH BEGIN
            			// if(s.ActionType__c != CommConst.PROD_ACTION_TYPE_PL){
            			// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
            			if(s.ActionType__c != CommConst.PROD_ACTION_TYPE_PL || (pBrkTranItemMap != null && !pBrkTranItemMap.containsKey(s.Id)) || !planBrkToHeaderCalFlg){
            			// 2019/10/02 PlanHeader算法切换对应 WGCH END
            			// 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH END
            				serviceAmountEnd += proc.priceService;
            				serviceTaxAmountEnd += proc.priceService - proc.priceServiceExcTax;
            			}
            			unitPriceExcServiceEnd += proc.unitPriceExcService;
            			unitPriceIncServiceEnd += proc.unitPriceIncService;
            		}
            		// サービス料表示モード２
            		// 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH BEGIN
            		// if(gIsServieModeOuter && s.ActionType__c != CommConst.PROD_ACTION_TYPE_PL){
            		// 2019/09/27 ServiceAmountBUG修正 WGCH BEGIN
            		// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
            		if(gIsServieModeOuter && (s.ActionType__c != CommConst.PROD_ACTION_TYPE_PL || (pBrkTranItemMap != null && !pBrkTranItemMap.containsKey(s.Id)) || !planBrkToHeaderCalFlg)){
            		// 2019/10/02 PlanHeader算法切换对应 WGCH END
            		// 2019/09/27 ServiceAmountBUG修正 WGCH END
            		// 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH END
            			// 該当明細はサービス料の場合
            			if (CommConst.PROD_ACTION_TYPE_SR == s.ActionType__c) {
            				if (gserviceNoTaxFlg) serviceAmountEnd += proc.priceExcTax;
            				else serviceAmountEnd += proc.priceIncTax;
            			} else {
            				if (gserviceNoTaxFlg) serviceAmountEnd += proc.priceServiceExcTax;
            				else serviceAmountEnd += proc.priceService;
            			}
            		}
            	}
            }
            // 2019/07/30 軽減税率機能対応 WGCH END
            s.UnitPrice__c = proc.unitPriceTax;
			// サビース料金は明細として、請求書に表示の対応[サービス料表示モード２] BEGIN
			if (gIsServieModeOuter) {
        		// 該当明細はサービス料の場合
        		if (CommConst.PROD_ACTION_TYPE_SR == s.ActionType__c) {
                    // 2017/07/20 サビース料税別区分 zyz BEGIN
                    if (gserviceNoTaxFlg) serviceAmount += proc.priceExcTax;
                    else 
                    // 2017/07/20 サビース料税別区分 zyz END
        			serviceAmount += proc.priceIncTax;
        		} else {
                    // 2017/07/20 サビース料税別区分 zyz BEGIN
                    if (gserviceNoTaxFlg) serviceAmount += proc.priceServiceExcTax;
                    else 
                    // 2017/07/20 サビース料税別区分 zyz END
        			serviceAmount += proc.priceService;
        		}
        	}
			// サビース料金は明細として、請求書に表示の対応[サービス料表示モード２] END
			// 2016/03/31 サビース料金は明細として、請求書に表示の対応 BEGIN
			noServiceUnitPrice = proc.unitPriceIncTax;
			// 2016/03/31 サビース料金は明細として、請求書に表示の対応 END
            Decimal priceIncTax = proc.priceIncTax; // 非課税明細金額を抜いて、計算した税込金額
            if (noTaxUnitPriceSum > 0) {
                proc.process(noTaxUnitPriceSum, Commutils.nullToZero(s.Amount__c) , 0, s.ServiceRate__c);
                s.UnitPrice__c += proc.unitPriceTax;
				// 2018/12/15 内消費税Bug修正 WGCH BEGIN
				// sumInfo.noTaxCalTotal += proc.priceIncTax;
				// 遗留bug修正,问题原因是, Plan本身就是不含税, 这时会多累加这份钱
				if(Commutils.nullToZero(s.TaxRate__c) > 0) sumInfo.noTaxCalTotal += proc.priceIncTax;
				// 2018/12/15 内消費税Bug修正 WGCH END
				// 2016/03/31 サビース料金は明細として、請求書に表示の対応 BEGIN
				noServiceUnitPrice += proc.unitPriceIncTax;
				// 2016/03/31 サビース料金は明細として、請求書に表示の対応 END
				// サビース料金は明細として、請求書に表示の対応[サービス料表示モード２] BEGIN
				if (gIsServieModeOuter) {
                    // 2017/07/20 サビース料税別区分 zyz BEGIN
                    if (gserviceNoTaxFlg) serviceAmount += proc.priceServiceExcTax;
                    else 
                    // 2017/07/20 サビース料税別区分 zyz END
	        		serviceAmount += proc.priceService;
	        	}
				// サビース料金は明細として、請求書に表示の対応[サービス料表示モード２] END
            }
            // 2015/11/25 数量は０の場合、不具合対応 END
            // 2015/10/27 プラン明細に非課税明細情報を取得する END
            // 2016/03/31 サビース料金は明細として、請求書に表示の対応 BEGIN
            if (gServiceOuputFlg && s.ServiceRate__c > 0) {
            	if (serviceOutputDiv == ShopInfoUtil.SERVICE_CHARGE_MODE_INNER) {
					unitPrice = noServiceUnitPrice;
					Decimal amount = Commutils.nullToZero(s.Amount__c);
					// サビース料なしの単価を取得する
					s.UnitPrice__c = unitPrice;
					s.SpTotal__c = CommUtils.RoundProcess(unitPrice * amount, pointlen);
            	}
            }
            // 2016/03/31 サビース料金は明細として、請求書に表示の対応 END
            // 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
            // BookItem newItem = new BookItem(s, bookItemLst.size());
            BookItem newItem = new BookItem(s, bookItemLst.size(),false);
            accountsName(CommUtils.nullToBLank(s.ProductName__c),newItem);
            // 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
            // 2019/07/30 軽減税率機能対応 WGCH BEGIN
            if (isReducedTaxFlg) {
            	// 最终单价赋值
            	newItem.sobj.UnitPrice__c = unitPriceEnd;
            	// 最终合计值赋值
            	newItem.sobj.SpTotal__c = unitPriceEnd * Commutils.nullToZero(s.Amount__c);
            	// 最终消费税赋值
            	newItem.taxUnitPrice = taxUnitPrice;
            	// noTaxUnitPriceSum => 当前plan 明细里的非课税合计金额 【如果当前不是plan 或 plan明细里没有 非课税商品  它就=0】
            	// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
            	// if(s.ActionType__c != CommConst.PROD_ACTION_TYPE_PL) addDetailToMapFun(newItem, noTaxUnitPriceSum);
            	if(s.ActionType__c != CommConst.PROD_ACTION_TYPE_PL || !planBrkToHeaderCalFlg){
            		addDetailToMapFun(newItem, 0);
            		if(planNoTaxUnitPriceMap.containsKey(s.Id)) noTaxUnitPriceSum = planNoTaxUnitPriceMap.get(s.Id);
            		proc.process(noTaxUnitPriceSum, Commutils.nullToZero(s.Amount__c) , 0, s.ServiceRate__c);
            		newItem.sobj.UnitPrice__c += proc.unitPriceTax;
            		// BRK行—合计值-赋值
            		newItem.sobj.SpTotal__c += proc.unitPriceTax * Commutils.nullToZero(s.Amount__c);
            		// サービス料表示モード1
            		if(gIsServieModeInner){
            			serviceAmountEnd += proc.priceService;
            			serviceTaxAmountEnd += proc.priceService - proc.priceServiceExcTax;
            			newItem.sobj.UnitPrice__c -= proc.unitPriceIncService;
            			newItem.taxUnitPrice -= proc.unitPriceIncService - proc.unitPriceExcService;
            		}
            		// サービス料表示モード２
            		if(gIsServieModeOuter){
            			// 該当明細はサービス料の場合
            			if (CommConst.PROD_ACTION_TYPE_SR == s.ActionType__c) {
            				if (gserviceNoTaxFlg) serviceAmountEnd += proc.priceExcTax;
            				else serviceAmountEnd += proc.priceIncTax;
            			} else {
            				if (gserviceNoTaxFlg) serviceAmountEnd += proc.priceServiceExcTax;
            				else serviceAmountEnd += proc.priceService;
            			}
            		}
            		// 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
            		// addDetailToMapFun(new BookItem(new QuotaItem__c(), newItem.rowNo), (proc.unitPriceTax * Commutils.nullToZero(s.Amount__c)));
            		addDetailToMapFun(new BookItem(new QuotaItem__c(), newItem.rowNo, false), (proc.unitPriceTax * Commutils.nullToZero(s.Amount__c)));
            		// 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
            	}
            	// 2019/10/02 PlanHeader算法切换对应 WGCH END
            	// 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
            	// else addDetailToMapFun(new BookItem(new QuotaItem__c(), newItem.rowNo), CommUtils.nullToZero(s.SpecialTax__c));
            	else addDetailToMapFun(new BookItem(new QuotaItem__c(), newItem.rowNo, false), CommUtils.nullToZero(s.SpecialTax__c));
            	// 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
            	// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
            	if(planBrkToHeaderCalFlg && pBrkTranItemMap != null && pBrkTranItemMap.containsKey(s.Id)) {
            	// 2019/10/02 PlanHeader算法切换对应 WGCH END
            		for(BookItem brkItem : pBrkTranItemMap.get(s.Id)){
            			// 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
            			accountsName(CommUtils.nullToBLank(brkItem.productName),brkItem);
            			// 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
            			addDetailToMapFun(brkItem, -(brkItem.specialTax));
            			if(gServiceOuputFlg && pBrkProMap.containsKey(brkItem.sobj.Id)){
            				CommUtils.ProductInfo bPriceInfo = pBrkProMap.get(brkItem.sobj.Id);
            				// サービス料表示モード1
            				if(gIsServieModeInner){
            					serviceAmountEnd += bPriceInfo.priceService;
            					serviceTaxAmountEnd += bPriceInfo.priceService - bPriceInfo.priceServiceExcTax;
            					brkItem.sobj.UnitPrice__c -= bPriceInfo.unitPriceIncService;
            					brkItem.taxUnitPrice -= bPriceInfo.unitPriceIncService - bPriceInfo.unitPriceExcService;
            					// BRK行—合计值-赋值
            					brkItem.sobj.SpTotal__c = brkItem.unitPrice * Commutils.nullToZero(s.Amount__c);
            				}
            				// サービス料表示モード２
            				if(gIsServieModeOuter){
            					// 該当明細はサービス料の場合
            					if (CommConst.PROD_ACTION_TYPE_SR == s.ActionType__c) {
            						if (gserviceNoTaxFlg) serviceAmountEnd += bPriceInfo.priceExcTax;
            						else serviceAmountEnd += bPriceInfo.priceIncTax;
            					} else {
            						if (gserviceNoTaxFlg) serviceAmountEnd += bPriceInfo.priceServiceExcTax;
            						else serviceAmountEnd += bPriceInfo.priceService;
            					}
            				}
            			}
            		}
            	}
            	// 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH BEGIN
            	// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
            	else if(planBrkToHeaderCalFlg && s.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) addDetailToMapFun(newItem, noTaxUnitPriceSum);
            	// 2019/10/02 PlanHeader算法切换对应 WGCH END
            	// サービス料表示モード1
            	if(gIsServieModeInner){
            		newItem.sobj.UnitPrice__c -= unitPriceIncServiceEnd;
            		newItem.taxUnitPrice -= unitPriceIncServiceEnd - unitPriceExcServiceEnd;
            		// 最终合计值赋值
            		newItem.sobj.SpTotal__c = newItem.unitPrice * Commutils.nullToZero(s.Amount__c);
            	}
            	// 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH END
            }
            // 2019/07/30 軽減税率機能対応 WGCH END
            bookItemLst.add(newItem);
            sumInfo.add(newItem, paymentTypeToMediaLabMap);
            // 2019/07/30 軽減税率機能対応 WGCH BEGIN
            if(isPlanBrkShowFlg && pBrkTranItemMap != null && pBrkTranItemMap.containsKey(s.Id)){
            	for(BookItem pItem : pBrkTranItemMap.get(s.Id)){
            		pItem.rowNo = bookItemLst.size() + 1;
            		pItem.pBrkDNFlg = true;
            		bookItemLst.add(pItem);
            	}
            }
            // 2019/07/30 軽減税率機能対応 WGCH END
            // 2016/12/08 見積明細利用日機能対応 BEGIN zyz
            Decimal locSpecialTax = CommUtils.nullToZero(s.SpecialTax__c);
            if (locSpecialTax > 0) {
	            QuotaItem__c item = new QuotaItem__c(
	               // 2018/06/08 レシート印刷機能言語選択する WGCH BEGIN
	               X2_1__c = (isForeignCurrency == true ? 'Accommodation Tax' : '宿泊税'),
	               ProductName__c = (isForeignCurrency == true ? 'Accommodation Tax' : '宿泊税'),
	               // 2018/06/08 レシート印刷機能言語選択する WGCH END
	               Amount__c = 1,
	               SpTotal__c = locSpecialTax,     // 宿泊税総金額表示するため、仮に設定を行う
	               UnitPrice__c = locSpecialTax,
	               UseDate__c = newItem.sobj.UseDate__c
	            );
	            // 2019/07/30 軽減税率機能対応 WGCH BEGIN
	            // bookItemLst.add(new BookItem(item, bookItemLst.size()));
	            // 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
	            // bookItemLst.add(new BookItem(item, isReducedTaxFlg ? rowNoEnd - 1 : bookItemLst.size()));
	            bookItemLst.add(new BookItem(item, isReducedTaxFlg ? rowNoEnd - 1 : bookItemLst.size(), false));
	            // 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
	            // 2019/07/30 軽減税率機能対応 WGCH END
            }
            // 2016/12/08 見積明細利用日機能対応 END zyz
        }
        
		// 2017/02/28  一括見積書PDF出力機能対応  begin by wx	
        // 2016/03/31 サビース料金は明細として、見積書に表示の対応 BEGIN
		//if (gServiceOuputFlg && serviceOutputDiv == ShopInfoUtil.SERVICE_CHARGE_MODE_INNER) setServiceDetailInfo(sumInfo);
        if (gServiceOuputFlg && serviceOutputDiv == ShopInfoUtil.SERVICE_CHARGE_MODE_INNER) setServiceDetailInfo(bookItemLst,sumInfo);
        // 2016/03/31 サビース料金は明細として、見積書に表示の対応 END
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
    	if (isReducedTaxFlg && taxRowDataMap != null) processSumInfo();
    	// 2019/07/30 軽減税率機能対応 WGCH END
        processPagging(bookItemLst);
		// 2017/02/28  一括見積書PDF出力機能対応  end by wx
        // 外貨の場合、内税英語文言表示対応
        if (isForeignCurrency) {
            // 2014/07/30 内消費税表示文言取得
        // 2015/08/14 見積書に個別指定の店舗の場合 BEGIN
            //String shopCode = UserUtil.CurrentUser.ShopCode__c;
            taxEnglishLabel = ShopInfoUtil.getTaxEnglishLabel(shopcd);
        // 2015/08/14 見積書に個別指定の店舗の場合 END
        }
    }
    // 2018/04/19 WGCH END
	// 2017/02/28  一括見積書PDF出力機能対応  begin by wx
	private string getSortKey (QuotaItem__c est) {
		Date useDate = est.UseDate__c;
		if(useDate == null) useDate = system.today();
		String userDateStr = DateTime.newInstance(useDate.Year(),useDate.month(),useDate.day()).format('yyyyMMdd') + '_';
		userDateStr += CommUtils.paddingLeftZero(CommUtils.nullToZero(est.RowNo__c),4) + '_' + est.Name;
		return userDateStr;
	}
	public set<id> getRealLeadIds(Lead__c pLead) {
		set<Id> leadIds = new set<Id>();
		Id leadIndexId = pLead.LeadIndexRef__c;
		Id subIndexId = pLead.LeadIndexSubId__c;
    	Decimal leadGroupNo = pLead.RoomGroupNo__c;     	
		// 関連予約情報を検査する　
		for (Lead__c lead : [select id from Lead__c where LeadIndexRef__c = :leadIndexId And LeadIndexSubId__c = :subIndexId And RoomGroupNo__c = :leadGroupNo And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
								Order By LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c, EntryTime__c]) {
			leadIds.add(lead.Id);
		}
		return leadIds;
	}
	// 2017/02/28  一括見積書PDF出力機能対応  end by wx
	public quota__c getQuota(){
        return quota;
    }
    //get 'お客様'
    public string getCustomer(){
        return CommUtils.isBlank(quota.QuotationName__c) ? quota.LeadRef__r.Relcontact__r.name : quota.QuotationName__c;
    }
    // 小数点表示対応するため、書式設定Methodを追加する
    public String getNumberFormat() {
        return pointlen > 0 ? ('##,##0.' + '0'.repeat(pointlen) ) : '##,###';
    }
    /**
    * 統計情報情報を維持する
    **/
    public TotalInfo sumInfo{get;private set;}
    public class TotalInfo {
        public TotalInfo(Decimal p_taxRate, Integer p_pointLen) {
            amoutUsedPriceIncTax = 0;
            amoutQuotePriceIncTax = 0;
            //amoutPriceExcTax = 0;
            //amoutServiceIncTax = 0;
            amoutSpecialIncTax = 0;
            amoutPriceForTax = 0;
            taxRate = p_taxRate / 100;
            pointLen = p_pointLen;
            // 支払情報
            payedConpon = 0;
            payedDiscount = 0;
            payedPriceOther = 0;
            // 非課税商品金額
            noTaxCalTotal = 0;
		    // 2019/04/30 増税仮対応 BY zyz BEGIN
		    taxIncMstTaxprice = 0;
		    // 2019/04/30 増税仮対応 BY zyz EDN
        }
        // 小数点桁数
        private Integer pointLen;       // 2014/08/01 Add
        // 消費税率
        private Decimal taxRate;
        // 総金額（税込：消費税計算対象金額）
        private Decimal amoutPriceForTax;
	    // 2019/04/30 増税仮対応 BY zyz BEGIN
	    private Decimal taxIncMstTaxprice;
	    // 2019/04/30 増税仮対応 BY zyz EDN
        // ご利用金額(税込)
        public Decimal amoutUsedPriceIncTax{get;private set;}
        // 総金額（税込）[見積金額]
        public Decimal amoutQuotePriceIncTax{get{
            Decimal locAmoutPriceIncTax = amoutUsedPriceIncTax;
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
            return locAmoutPriceIncTax - payedPriceOther;
        } private set;}
        // 総支払金額[クーポン AND 割引]ー>支払金額は総金額を超える場合、返金なし、見積もり金額なし
        public Decimal payedConpon{get;set;}
        public Decimal payedDiscount{get;set;}
        // 総支払金額[クーポン AND 割引以外の金額]
        public Decimal payedPriceOther{get;set;}
        // 総金額（税抜）
        //public Decimal amoutPriceExcTax{get;set;}
        // サービス料（税込）
        //public Decimal amoutServiceIncTax{get;set;}
        // 特別税（宿泊税）
        public Decimal amoutSpecialIncTax{get;set;}
        // プランの非課税明細金額合計値
        public Decimal noTaxCalTotal{get;set;}
        // 消費税:総金額（税込）-特別税 /
        public Decimal amoutTax{get{
            // 2018/12/15 内消費税Bug修正 WGCH BEGIN
            // 消費税率を取得する
            // Decimal locAmoutPriceIncTax = amoutPriceForTax - payedDiscount - noTaxCalTotal;
            Decimal locAmoutPriceIncTax = amoutPriceForTax - payedDiscount - noTaxCalTotal;
            // 2018/12/15 内消費税Bug修正 WGCH END
            if (locAmoutPriceIncTax < 0) locAmoutPriceIncTax = 0;
            // 2019/04/30 増税仮対応 BY zyz BEGIN
            // return CommUtils.RoundProcess(locAmoutPriceIncTax / (1 + taxRate) * taxRate, pointLen);
            return CommUtils.RoundProcess(locAmoutPriceIncTax / (1 + taxRate) * taxRate + taxIncMstTaxprice, pointLen);
            // 2019/04/30 増税仮対応 BY zyz END
        }}
        // 2019/04/30 増税仮対応 BY zyz BEGIN
        public String taxIncMstId{get{
			// 2020/06/30 増税仮BUG fix  BY zyz BEGIN
			// CommLogicProcess.TaxIncMstInfo info = CommLogicProcess.getTaxIncMstInfo();
			// 2020/06/30 増税仮BUG fix  BY zyz END
			// 增税商品的Id
			return !CommUtils.isBlank(info.taxIncMstId) ? info.taxIncMstId : null;
        }}
        // 2019/04/30 増税仮対応 BY zyz END
        public void add(BookItem item, Map<String, String> paymentTypeToMediaLabMap) {
            // 明細は支払　OR　前受け金の場合、合計を行う
            if (item.sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_AR  ||
                item.sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PY){
                String mediaNm = paymentTypeToMediaLabMap.get(item.sobj.PaymentType__c);
                if (CommUtils.isBlank(mediaNm)) mediaNm = CommConst.MEDIA_TYPE_01;
                String mediaCd = CommConst.getMediaCodeByMediaName(mediaNm);
                if (mediaCd == CommConst.MEDIA_TYPE_CD_11) {
                    payedConpon += CommUtils.nullToZero(item.sobj.Total__c);
                } else if ( mediaCd == CommConst.MEDIA_TYPE_CD_12) {
                    payedDiscount += CommUtils.nullToZero(item.sobj.Total__c);
                } else {
                    payedPriceOther += CommUtils.nullToZero(item.sobj.Total__c);
                }
            } else {
            	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
            	//　合計金額（税込）
                // amoutUsedPriceIncTax += CommUtils.nullToZero(item.sobj.Total__c);
            	if(isReducedTaxFlg && (CommConst.OPTION_MODE == CommConst.OPTION_MODE_ON)){
            		amoutUsedPriceIncTax += CommUtils.nullToZero(item.sobj.SpTotal__c) + CommUtils.nullToZero(item.sobj.SpecialTax__c);
            	} else amoutUsedPriceIncTax += CommUtils.nullToZero(item.sobj.Total__c);
            	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
                
            }
            // 宿泊税
            amoutSpecialIncTax += CommUtils.nullToZero(item.sobj.SpecialTax__c);
            // 消費税計算用金額合計 = 合計金額（税込） - 宿泊税
            if (CommUtils.nullToZero(item.sobj.TaxRate__c) > 0) {
                // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
                // 消費税計算用金額の合計:金額-特別税
                // amoutPriceForTax += CommUtils.nullToZero(item.sobj.Total__c) - CommUtils.nullToZero(item.sobj.SpecialTax__c);
            	if(isReducedTaxFlg && (CommConst.OPTION_MODE == CommConst.OPTION_MODE_ON)){
            		amoutPriceForTax += CommUtils.nullToZero(item.sobj.SpTotal__c);
            	} else amoutPriceForTax += CommUtils.nullToZero(item.sobj.Total__c) - CommUtils.nullToZero(item.sobj.SpecialTax__c);
            	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
            }
            // 2019/04/30 増税仮対応 BY zyz BEGIN
            // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
            // if(taxIncMstId == item.sobj.refAccountMaster__c  && taxIncMstId != null)  taxIncMstTaxprice += CommUtils.nullToZero(item.sobj.Total__c);
            if(taxIncMstId == item.sobj.refAccountMaster__c  && taxIncMstId != null){
            	if(isReducedTaxFlg && (CommConst.OPTION_MODE == CommConst.OPTION_MODE_ON)){
            		taxIncMstTaxprice += CommUtils.nullToZero(item.sobj.SpTotal__c) + CommUtils.nullToZero(item.sobj.SpecialTax__c);
            	} else taxIncMstTaxprice += CommUtils.nullToZero(item.sobj.Total__c);
            }
            // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
            // 2019/04/30 増税仮対応 BY zyz END
        }
    }
    /**
    * 2016/03/31 サビース料金は明細として、見積書に表示の対応
    **/
    // 2017/02/28  一括見積書PDF出力機能対応  begin by wx
    //private void setServiceDetailInfo(TotalInfo sumInfo) {
    private void setServiceDetailInfo(List<BookItem> bookItemLst,TotalInfo sumInfo) {
    // 2017/02/28  一括見積書PDF出力機能対応  end by wx
    	// サビース料情報
    	Decimal noServiceAmount = 0;
    	// サビース料抜き合計金額
    	for (BookItem item : bookItemLst) {
    		if (item.isPayItem) continue;
    		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
    		if (item.pBrkDNFlg) continue;
    		// 2019/07/30 軽減税率機能対応 WGCH END
    		noServiceAmount += item.sobj.SpTotal__c;
    	}
    	// sumInfo.amoutUsedPriceIncTax：総金額
    	Decimal serviceRate = sumInfo.amoutUsedPriceIncTax - noServiceAmount;
    	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
    	if(isReducedTaxFlg) serviceRate = serviceAmountEnd;
    	// 2019/07/30 軽減税率機能対応 WGCH END

    	if (serviceRate > 0) {
            // 明細にサビース料情報を追加表示する
            BookItem serviceItem = new BookItem(new QuotaItem__c(
                       ProductName__c = (isForeignCurrency == true ? 'Service Charge' : 'サービス料'),
                       SpTotal__c = serviceRate,
                       UnitPrice__c = serviceRate,
                       Amount__c = 1),
                       // 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
                       // bookItemLst.size());
                       bookItemLst.size(), false);
                       // 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
			// 2016/12/08 見積明細利用日機能対応 BEGIN zyz
            // 利用日は前行目の利用日で設定を行う
            if (bookItemLst.size() > 0) {
            	BookItem preItem = bookItemLst[bookItemLst.size()-1];
            	serviceItem.sobj.UseDate__c = preItem.sobj.UseDate__c;
            }
            // 2016/12/08 見積明細利用日機能対応 END zyz
            // 2019/07/30 軽減税率機能対応 WGCH BEGIN
            if(isReducedTaxFlg){
            	serviceItem.rowNo = rowNoEnd;
            	serviceItem.taxUnitPrice = serviceTaxAmountEnd;
            	serviceItem.isServieFlg = true;
            }
            // 2019/07/30 軽減税率機能対応 WGCH END
            bookItemLst.add(serviceItem);
        }
    }
    // サビース料金は明細として、請求書に表示の対応[サービス料表示モード２] BEGIN
    public Boolean gServiceOuputFlg{get; private set;}
    public Boolean gIsServieModeOuter{get; private set;}
    // 2017/07/20 サビース料税別区分 zyz BEGIN
    public Boolean gserviceNoTaxFlg{get; private set;}
    // 2017/07/20 サビース料税別区分 zyz END
	private Decimal serviceAmount = 0;
	public Decimal getServiceAmount(){
		if (gIsServieModeOuter) {
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			if(isReducedTaxFlg) return serviceAmountEnd;
			// 2019/07/30 軽減税率機能対応 WGCH END
			return serviceAmount;
		} else return null;
	}
	// サビース料金は明細として、請求書に表示の対応[サービス料表示モード２] END
	// 2017/02/28  一括見積書PDF出力機能対応  begin by wx
	private void processPagging(List<BookItem> bookItemLst) {
		// 改ページ処理機能初期化
		allPageList = new List<OnePage>();
		Integer breakNum = MAX_SHOW_DETAIL_ROWS;
		// 2020/06/30 見積書のレイアウトは請求書のレイアウトに統一に改善対応 BY zyz BEGIN
		if(allAmountShowFlg && commentShowFlg) breakNum += 2;
		// 2020/06/30 見積書のレイアウトは請求書のレイアウトに統一に改善対応 BY zyz END
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		// 根据合计板块的行数 与 总行数合并
		if(isReducedTaxFlg){
			// 2019/10/30 消費税対象、値引行非表示の機能機能対応 WGCH BEGIN
			/*
			breakNum += 1; // 原有消费税行
			if(taxRowDataMap != null){
				breakNum -= taxRowDataMap.keySet().Size(); // 消费税对象行
				// 合计行
				breakNum -= 1;
			}
			// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
			if(disRowDataLst != null) breakNum -= disRowDataLst.Size() + 1;
			// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
			if((disRowData.disUnitPriceSum + disRowData.disTaxAmountSum ) != 0) breakNum -= 1;
			*/
			// 获取轻减税率后最终多出来的行数
			Integer rowBreakNumEnd = CommLogicProcess.getRowBreakNumEnd(comSum);
			// 2020/06/30 見積書のレイアウトは請求書のレイアウトに統一に改善対応 BY zyz BEGIN
			// rowBreakNumEnd等于-2为无明细或者是明细的明细消费税不存在的情况
			// breakNum -= rowBreakNumEnd;
			if((rowBreakNumEnd > -2 && !allAmountShowFlg) || (rowBreakNumEnd > 0 && allAmountShowFlg)) breakNum -= rowBreakNumEnd;
			// 2020/06/30 見積書のレイアウトは請求書のレイアウトに統一に改善対応 BY zyz END
			// 2019/10/30 消費税対象、値引行非表示の機能機能対応 WGCH END
		}
		rowNoEnd = 1;
		// 2019/07/30 軽減税率機能対応 WGCH END
		// 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
		Integer lineNum = 0;	// 记录最后一页计算空白格
		Integer linesNum = 0;	// 计算增加行数值
		if (isAccountProdNmReturnFlg) breakNum +=3;		// 行追加功能生效后，追加三行
		// 2019/09/90 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
		for (Integer index =0; index < bookItemLst.size(); index++) {
			// 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
			lineNum += CommUtils.nullToZero(bookItemLst[index].proNum);
			linesNum += CommUtils.nullToZero(bookItemLst[index].proNum);
			// 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			if(isReducedTaxFlg){
				BookItem book = bookItemLst[index];
				book.rowNo = rowNoEnd;
				if(!book.pBrkDNFlg) rowNoEnd ++;
			}
			// 2019/07/30 軽減税率機能対応 WGCH END
			// 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
			// 改ページ計算
			// Integer breakLine = index - (allPageList.isEmpty() ? 0 : 1) * breakNum - (allPageList.size() > 1 ? allPageList.size() -1 : 0 ) * breakNum;
			Integer breakLine = index - (allPageList.isEmpty() ? 0 : 1) * (breakNum -linesNum) - (allPageList.size() > 1 ? allPageList.size() -1 : 0 ) * breakNum;
			// 改ページする場合
			// if (breakLine == 0) {
			if(breakLine >= 0){
				lineNum = CommUtils.nullToZero(bookItemLst[index].proNum);
				if(index != 0 && CommUtils.nullToZero(bookItemLst[index].proNum) != 0)linesNum += CommUtils.nullToZero(bookItemLst[index].proNum)-breakLine;
				// 补全每页的空白行
				/**/
				if(allPageList.size() > 0){
					OnePage onePgblank = allPageList[allPageList.size() - 1];
					for (integer i=0; i < (lineNum -breakLine); i++) {
					    onePgblank.addItem(new BookItem(new QuotaItem__c(), null, true));
					}
				}
				// 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
				OnePage onePg = new OnePage();
				onePg.addItem(bookItemLst[index]);
				allPageList.add(onePg);
				// ページ数を設定する
				onePg.currPages = allPageList.size();
				// 2019/07/30 軽減税率機能対応 WGCH BEGIN
				onePg.disRowData = disRowData;
				onePg.sumRowData = sumRowData;
				onePg.taxRowDataLst = taxRowDataLst;
				// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
				onePg.disRowDataLst = disRowDataLst;
				// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
				// 2019/07/30 軽減税率機能対応 WGCH END
			} else {
				OnePage onePg = allPageList[allPageList.size() - 1];
				onePg.addItem(bookItemLst[index]);
				// 2019/07/30 軽減税率機能対応 WGCH BEGIN
				onePg.disRowData = disRowData;
				onePg.sumRowData = sumRowData;
				onePg.taxRowDataLst = taxRowDataLst;
				// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
				onePg.disRowDataLst = disRowDataLst;
				// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
				// 2019/07/30 軽減税率機能対応 WGCH END
			}
		}
		// 全部データは一ページ場合、空白行を追加する
		Integer dumyLen = 0;
		OnePage dumyPage = null;
		if (allPageList.isEmpty()) {
            dumyLen = breakNum;
            dumyPage = new OnePage();
            // 2019/07/30 軽減税率機能対応 WGCH BEGIN
            dumyPage.disRowData = disRowData;
            dumyPage.sumRowData = sumRowData;
            dumyPage.taxRowDataLst = taxRowDataLst;
            // 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
            dumyPage.disRowDataLst = disRowDataLst;
            // 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
            // 2019/07/30 軽減税率機能対応 WGCH END
            allPageList.add(dumyPage);
		}
		Integer lastIndex = allPageList.size() - 1;
		// 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
		// dumyLen = breakNum - allPageList[lastIndex].onePageList.size();
		dumyLen = breakNum - allPageList[lastIndex].onePageList.size() - lineNum;
		// 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
		dumyPage = allPageList[lastIndex];
        for (integer i=0; i < dumyLen; i++) {
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			// 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
			// dumyPage.onePageList.add(new BookItem(new QuotaItem__c(), isReducedTaxFlg ? (rowNoEnd - 1 + i) : (bookItemLst.size()+i)));
			dumyPage.onePageList.add(new BookItem(new QuotaItem__c(), isReducedTaxFlg ? (rowNoEnd - 1 + i) : (bookItemLst.size()+i), false));
			// 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
			// 2019/07/30 軽減税率機能対応 WGCH END
        }
	}
	// PDFページ毎の明細情報を格納用
	public List<OnePage> allPageList{get; private set;}
	public class OnePage {
		// startRsIndex：データ開始行目
		public OnePage () {
			onePageList = new List<BookItem>();
			currPages = 1;
		}
		// ページ内に追加するITEM
		public void addItem(BookItem item) {
			onePageList.add(item);
		}
		// 現在表示してページ数
		public Integer currPages{get;set;}
		public Boolean isFirstPage{get{
		  return currPages == 1;
		}}
		// １ページ表示用データを格納
		public List<BookItem> onePageList{get; private set;}
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		// 2019/10/30 軽減税率割合モード機能対応 WGCH BEGIN
		public CommLogicProcess.DisRowData disRowData {get;set;}
		public CommLogicProcess.SumAmountRowData sumRowData {get;set;}
		public List<CommLogicProcess.TaxRowData> taxRowDataLst {get;set;}
		// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
		public List<CommLogicProcess.DisRowData> disRowDataLst {get;set;}
		// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
		// 2019/10/30 軽減税率割合モード機能対応 WGCH END
		// 2019/07/30 軽減税率機能対応 WGCH END
	}
	// 2017/02/28  一括見積書PDF出力機能対応  end by wx
    public class BookItem {
		// 2016/12/27 見積明細利用日機能対応 BEGIN zyz
		public String productName{get;private set;}
		// 2016/12/27 見積明細利用日機能対応 END zyz
		//public String usedDate{get; private set;}
		// 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
        public BookItem(QuotaItem__c s, Integer no ,Boolean isBlankFlg) {
        // 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
            sobj = s;
            // 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
            // rowNo = no+1;
            if(no != null)rowNo = no+1;
            blankFlg = isBlankFlg;
            // 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
            // 前受金　|| 支払メディア
            isPayItem = (s.ActionType__c == CommConst.PROD_ACTION_TYPE_AR  || s.ActionType__c == CommConst.PROD_ACTION_TYPE_PY);
			// 2016/12/08 見積明細利用日機能対応 BEGIN zyz
			if(s.UseDate__c == null && s.refBooking__r != null){
				sobj.UseDate__c = s.refBooking__r.EntryTime__c.date();
				// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH BEGIN
				// if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI) {
				if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI && !CommConst.BOOKEST_USERDATE_FLG) {
				// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH END
		    		sobj.UseDate__c = s.refBooking__r.Departure__c.date();
		    	}
			}
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			// 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
			// Integer NameLong = 36;
			// if(isReducedTaxFlg) NameLong = 32;
			// productName = CommRepUtils.getPdfMaxShowStringNew(s.ProductName__c,1,36);
			// productName = CommRepUtils.getPdfMaxShowStringNew(s.ProductName__c,1,NameLong);
			productName = s.ProductName__c;
			proNum = 0;
			// 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
			// 2019/07/30 軽減税率機能対応 WGCH END
			// 2016/12/08 見積明細利用日機能対応 END zyz
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			// 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH BEGIN
			// planFlg = isPlanBrkShowFlg && (sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PL);
			planFlg = isPlanBrkShowFlg && (sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) && pBrkTranItemMap != null && pBrkTranItemMap.containsKey(sobj.Id);
			// 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH END
			isServieFlg = pBrkDNFlg = false;
			taxUnitPrice = 0;
			// 2019/07/30 軽減税率機能対応 WGCH END
        }
        public QuotaItem__c sobj{get; private set;}
        public Integer rowNo{get; private set;}
        public Boolean isPayItem{get; private set;} // 概要行目は支払明細確認フラグ：TRUEの場合、支払メディア情報
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
        public Boolean planFlg{get; private set;}
        public Boolean pBrkDNFlg{get; private set;}
        public Decimal unitPrice{get{ return CommUtils.nullToZero(sobj.UnitPrice__c);} private set;}
        public Boolean isServieFlg{get; private set;}        // サービス料行Flg
        public Decimal taxUnitPrice{get; private set;}
        public Decimal taxRate{get{ return CommUtils.nullToZero(sobj.TaxRate__c) / 100;} private set;}
        public Decimal serviceRate{get{ return CommUtils.nullToZero(sobj.ServiceRate__c) / 100;} private set;}
        public Decimal quantity{get{ return CommUtils.nullToZero(sobj.Amount__c);} private set;}
        public Boolean isPaymentInfo{get{ return isPayItem;} private set;}
        public Decimal specialTax{get{ return CommUtils.nullToZero(sobj.SpecialTax__c);} private set;}
        // 2019/07/30 軽減税率機能対応 WGCH END
        // 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
        // 商品占用行数
        public Integer proNum{get; private set;}
        // 改行後の文字列情報を格納する
        public List<String> produceNms{get; private set;}
        public Boolean blankFlg{get; private set;}
        // 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
    }
    // 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
    private void accountsName(String accName,BookItem item) {
 		integer splitCodeNum = 36;
 		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
 		if(isReducedTaxFlg) splitCodeNum -= 4;
 		// 2019/07/30 軽減税率機能対応 WGCH END
        if ( accName.length() > splitCodeNum) {
        	// 商品名截取多行显示
        	if (isAccountProdNmReturnFlg) {
        	 	if (!proNameMap.containsKey(accName)) {
        	 		List<String> retArr = CommRepUtils.getPdfMaxShowStringNews(accName,MAX_SHOW_DETAIL_ROWS,splitCodeNum,true);
        	 		proNameMap.put(accName,retArr);
        	 	}
        	 	item.produceNms = proNameMap.get(accName);
        	 	item.proNum = (item.produceNms.isEmpty() ? 0 : (item.produceNms.size() -1));
        	} else {
        		// 商品名截取一行显示
        	 	//item.productName = accName.left(splitCodeNum);
        	 	item.productName = CommRepUtils.getPdfMaxShowStringNew(accName,1,splitCodeNum);
        	}
        }
    }
    // 2019/09/30 見積書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
	// 各税率の金額合計（税抜）と消費税合計情報を格納する
	// 合計のセクションに、割引ある場合、割引関連の消費税を計算する、画面に表示する
	// 該当金額と一覧の金額とわせて、最後の合計行に金額を表示する（税抜き合計＋消費税合計）、最後利用金額合計
	private Boolean gIsServieModeInner; // サービス料表示モード1
	private Decimal taxUnitPriceAll; // 消费税合计值
	private Decimal amoutIncDiscontAll;
	private Decimal amoutAllMoneyEnd = 0;
	private Decimal serviceAmountEnd = 0;
	private Decimal serviceTaxAmountEnd = 0;
	private Integer rowNoEnd = 1;
	// 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH BEGIN
	private static Map<String, List<BookItem>> pBrkTranItemMap;
	// 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH END
	private Map<String, CommUtils.ProductInfo> pBrkProMap;
	private Map<String, CommUtils.ProductInfo> planHeaderMap;
	// 小数部分桁数取得する
	private static final Integer gPointLen = CommUtils.getPointLen();
	public static boolean isReducedTaxFlg{get{ return CommConst.REDUCED_TAXRATE_FLG;} private set;}
	public static boolean isPlanBrkShowFlg{get{ return CommConst.REDUCED_PDF_PLAN_BRK_SHOW_FLG;} private set;}
	// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
	public Map<String, Decimal> planNoTaxUnitPriceMap;
	public static boolean planBrkToHeaderCalFlg{get{ return CommConst.PLAN_BRKTOHEADER_CAL_FLG;} private set;}
	// 2019/10/02 PlanHeader算法切换对应 WGCH END
	private Decimal getAmoutIncDiscont(){ return CommUtils.nullToZero(amoutIncDiscontAll); }
	public String getTaxNumberFormat() { return CommBaseCtrl.getTaxNumberFormat();}
	public String getCurrencySybmol(){ return CommBaseCtrl.getCurrencySybmol();}
	// 2019/10/30 軽減税率割合モード機能対応 WGCH BEGIN
	// 対象行Lst
	public List<CommLogicProcess.TaxRowData> taxRowDataLst {get;set;}
	// 対象行Map <消費税レート,該当消費税関連の金額合計>
	private map<Decimal, CommLogicProcess.TaxRowData> taxRowDataMap;
	// 値引行
	public CommLogicProcess.DisRowData disRowData {get;set;}
	// 値引行Lst
	public List<CommLogicProcess.DisRowData> disRowDataLst {get;set;}
	// 合计行
	public CommLogicProcess.SumAmountRowData sumRowData {get;set;}
	
	private void reducedTaxInit(){
		serviceAmountEnd = serviceTaxAmountEnd = taxUnitPriceAll = 0;
		rowNoEnd = 1;
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
	private void addDetailToMapFun(BookItem tranItem,Decimal noTaxUnitPriceSum) {
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
	public List<TaxRowData> taxRowDataLst{get; set;}
	// map<消費税レート,該当消費税関連の金額合計>
	private map<Decimal, TaxRowData> taxRowDataMap;
	public class TaxRowData {
		public TaxRowData() {
			taxRate = amountExcTax = amountIncTax = taxAmount = 0;
			isNoTaxPrice = isDiscountTax = true;
		}
		public Decimal taxRate{get{return (CommUtils.nullToZero(taxRate));}set;}	// 消費税率
		public Decimal amountExcTax{get;set;}	// 税抜きの合計金額
		public Decimal amountIncTax{get;set;}	// 税込きの合計金額
		public Decimal taxAmount{get;set;}		// 該当行目の消費税合計
		public Boolean isNoTaxPrice{get;set;}	// 非課税金額
		public Boolean isDiscountTax{get;set;}	// 割引
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
		public Decimal taxRate{get;set;}//値引き行目の税率情報を格納する
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
		public Decimal taxAmount{get;set;}	// 該当行目の消費税合計
		public Decimal amountExcTax{get;set;} // 合计税拔
		public Decimal amountIncTax{get;set;} // 合计税込
		public Decimal priceAmountSum{get;set;}
	}
	*/
	// 2019/10/30 軽減税率割合モード機能対応 WGCH END
	// 2019/07/30 軽減税率機能対応 WGCH END
}