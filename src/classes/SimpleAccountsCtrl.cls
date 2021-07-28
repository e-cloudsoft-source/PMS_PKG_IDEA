/*****************************
* 簡易会計機能
* 2014/03/07 会計データ作成のタイミング、消費税率設定を行う
* 2017/11/27 簡易会計の支払メディアをカスタマイズできるように改善
*****************************/
global with sharing class SimpleAccountsCtrl {
	// メデイア種別格納
	public List<Selectoption> mediaTypeOptionLst{get; private set;}
	// 会計商品
	public String productNm{get;set;}
	// 会計明細情報維持
	public Tran1__c otran{get;set;}
	// メデイア
	public String mediaType{get;set;}
	// 会計総金額
	public String totalPrice{get;set;}
	// 2017/02/22 弹出输入金额 begin by wx
	// 預かり金額
	public String paymentprice{get;set;}
	// device开关影响
	public boolean isShowPaymentFlag{get{return CommDefine__c.getOrgDefaults().SimpleAccountsPrintFlg__c && isPosFlag ;}}
	// 2017/02/22 弹出输入金额 end by wx 
	// 会計書ID
	public Transient String accountsId{get;private set;}
	// 売上日情報
	private RsvAccount__c rsvInfo;
	// 売上日入力用
	public String saleDate{get; set;}
	// カード種別
	public TTend__c oTtend{get; private set;}
	// 2014/08/29 登録する商品対象外フラグ情報
	public Map<Integer, Boolean> unSubmitInfMap{get; private set;}
	// 登録対象外フラグを格納する
	public String unSubmitFlgStr{get; set;}
	// 2014/09/09 小数点桁数
	private Integer pointlen{get; private set;}			// 小数桁数情報格納
	/*************************
	* 初期化
	**************************/
	public SimpleAccountsCtrl() {
		// メデイア種別リストを設定する
		//mediaTypeOptionLst = CommConst.getPayMentTypeOptLst();
		mediaTypeOptionLst = new List<Selectoption>();
		// 2017/11/27 簡易会計の支払メディアをカスタマイズできるように改善 WGCH BEGIN
		/*
		mediaTypeOptionLst.add(new SelectOption(CommConst.MEDIA_TYPE_CD_01,CommConst.MEDIA_TYPE_01));
		mediaTypeOptionLst.add(new SelectOption(CommConst.MEDIA_TYPE_CD_02,CommConst.MEDIA_TYPE_02));
		*/
		// 获取XML_Info
		List<Selectoption> wkMediaTypeOptionLst = getPaymentToPayMeidaXml();
		noCustomMediaTypeFlg = wkMediaTypeOptionLst.isEmpty();
		// カスタマイズXML情報がなかった場合
		if(noCustomMediaTypeFlg){
			mediaTypeOptionLst.add(new SelectOption(CommConst.MEDIA_TYPE_CD_01,CommConst.MEDIA_TYPE_01));
			mediaTypeOptionLst.add(new SelectOption(CommConst.MEDIA_TYPE_CD_02,CommConst.MEDIA_TYPE_02));
		} else {
		    mediaTypeOptionLst.addAll(wkMediaTypeOptionLst);
		}
		// 2017/11/27 簡易会計の支払メディアをカスタマイズできるように改善 WGCH END
		// 情報格納変数初期化
		saleDate = Datetime.now().format(CommBaseCtrl.getDateFormat());
		oTtend = new TTend__c();
		oTranLst = new List<Tran1__c>();
		clearInputForm();
		// 登録する商品対象外フラグ情報初期化
		unSubmitInfMap = new Map<Integer, Boolean>();
		pointlen = CommUtils.getPointLen(UserInfo.getDefaultCurrency());	// 指定の通貨により、小数点桁数を取得する
		//2017/02/23 demodate機能 by zy BEGIN
		isDemoFlag = false;
		//String demoDate = OrderServiceHelp.getSimpleDemoDate();
		//isDemoFlag = !CommUtils.isBlank(demoDate);
		//2017/02/23 demodate機能 by zy END
		// 2017/07/03 device fonig 機能追加　by　zy BEGIN
		initDeviceConfig();
		// 2017/07/03 device fonig 機能追加　by　zy END
	}
	//2017/02/23 demodate機能 by zy BEGIN
	public boolean isDemoFlag{get;set;}
	//2017/02/23 demodate機能 by zy END
	//2017/01/12 door by BEGIN
	public String prinUrl{get;set;}
	public String statusUrl{get;set;}
	public String printInfoJson{get;set;}
	// 2017/07/13 ソース変数統一 BEGIN
	//public static boolean openDoorFlag{get{return CommDefine__c.getOrgDefaults().SimpleAccountsPrintFlg__c;}}
	public boolean openDoorFlag{get{return isShowPaymentFlag;}}
	// 2017/07/13 ソース変更統一 END
	private OrderServiceHelp.PrintInfo curPrintInfo;
	public String localIp{get;set;}
	//2017/02/23 source整理 by zy BEGIN
	/*
	* 简易会计弹出
	
	private void loadDoorOpen(){
		if (curPrintInfo == null) {
			curPrintInfo = OrderServiceHelp.getPrintByIp(localIp);
			if (curPrintInfo != null) {
			//打印url
			prinUrl = curPrintInfo.prinUrl;
			//打印状态url
			statusUrl = curPrintInfo.statusUrl;
			//店铺情报取得
			ShopInformation__c shop = new ShopInformation__c();
			String oShopCode = UserUtil.CurrentUser.ShopCode__c;
			try{
				List<ShopInformation__c> shops = [SELECT 
		                Id
		                , Name
		                , Phone__c
		                , Address__c
		                , ShopCode__c
		                , TierDefault__c
		                , PeopleDefault__c
		                , EnglishTaxLabel__c	// 内消費税英語表示文言
		            FROM
		                ShopInformation__c
		            where   ShopCode__c = :oShopCode ];
		        if(!shops.isEmpty())
	        		shop = shops[0];
	        	else 
	        		shop = defaultShopMessage();
	        		
	        	if (!CommUtils.isBlank(oShopCode)) {
	        		shop = ShopInfoUtil.getShop(oShopCode);
	        	} else {
	        		shop = defaultShopMessage();
	        	}
	        }catch(Exception e){
	        	shop = defaultShopMessage();
	        }
			//打印内容初始化
			OrderServiceHelp.PrintPara curPrintPara = new OrderServiceHelp.PrintPara();
			curPrintPara.telno = CommUtils.nullToBLank(shop.Phone__c);
			curPrintPara.address = CommUtils.nullToBLank(shop.Address__c);
			curPrintPara.company = CommUtils.nullToBLank(shop.Name);
			curPrintPara.empno = CommUtils.nullToBLank(UserUtil.CurrentUser.EmployeeCode__c);
				curPrintPara.postno = CommUtils.nullToBLank(shop.Post__c);
			curPrintInfo.par = curPrintPara;
		}
	}
	}
	private ShopInformation__c defaultShopMessage(){
		Organization orgDetails = [SELECT Id, Name, PostalCode, State,City,Street,Phone,Fax  FROM Organization WHERE Id = :UserInfo.getOrganizationId()];
		// 組織情報から設定する
		String PostNo = CommUtils.nullToBlank(orgDetails.PostalCode);
		String shopName = orgDetails.Name;
		String Address = CommUtils.nullToBlank(orgDetails.State) + CommUtils.nullToBlank(orgDetails.City) + CommUtils.nullToBlank(orgDetails.Street);
		String Phone = CommUtils.nullToBlank(orgDetails.Phone);
		//return new ShopInformation__c(Phone__c = Phone,Address__c = Address + PostNo,Name = shopName);
		return new ShopInformation__c(Phone__c = Phone,Address__c = Address,Name = shopName,Post__c=PostNo);
	}
	*/
	//2017/02/23 source整理 by zy END
	//2017/01/12 door by END
	// 登録した会計商品明細一覧
	public List<Tran1__c> oTranLst{get; private set;}
	public void saveTranToMemory() {
		// 金額計算を行う
		// ********************
		// 支払金額の計算
		// ********************
		CommUtils.ProductInfo prodInfo = new CommUtils.ProductInfo();
		// 単価と数量はNULLの場合、
		Decimal unitPrice = CommUtils.nullToZero(otran.Field20__c);  	// <-単価
		Decimal qty = CommUtils.nullToZero(otran.Field21__c);			// <-数量
        prodInfo.process(unitPrice, qty, otran.TaxRate__c, otran.ServiceRate__c);
        // 特別税は０に設定する
        otran.SpecialTax__c = 0;
		// 支払総金額
		Decimal dTotalPrice = prodInfo.priceIncTax + CommUtils.nullToZero(otran.SpecialTax__c);
		otran.Field23__c = String.valueOf(dTotalPrice);
		// 商品名称（または券名称）
		otran.Field5__c = productNm;
		
		oTranLst.add(otran.clone(false,true));
		//totalPrice = (CommUtils.nullToZero(totalPrice) + dTotalPrice).format();
		totalPrice = String.valueOf(CommUtils.nullToZero(totalPrice) + dTotalPrice);
		// 2017/02/22 弹出输入金额  begin by wx		
		paymentprice = String.valueOf(CommUtils.nullToZero(paymentprice));
		// 2017/02/22 弹出输入金额  end by wx
		clearInputForm();
		
		// 新規商品を追加すると、該当商品の初期化設定を行う
		//unSubmitInfMap.put(oTranLst.size() - 1, false);
		setUnSubmitInfMap();
	}
    public String getNumberFormat() {
    	return pointlen > 0 ? ('##,##0.' + '0'.repeat(pointlen) ) : '##,###';
    }
	// 画面から指定する登録なし行目を取得する
	private void setUnSubmitInfMap() {
		// 初期化処理
		for (Integer i = 0; i < oTranLst.size() ; i++) {
			unSubmitInfMap.put(i, false);
		}
		// 新規追加の商品はCommit対象
		List<String> unSubmitLst = CommUtils.isBlank(unSubmitFlgStr) ? new List<String>() : unSubmitFlgStr.split(',');
		for (String rowNo : unSubmitLst) {
			unSubmitInfMap.put(Integer.valueOf(rowNo), true);
		}
	}
	
	/**
	* 入力FORMクリア
	**/
	private void clearInputForm() {
		otran = new Tran1__c();
		productNm = null;
	}
	
	/**
	* 処理する前のデータ準備
	**/
	private void preDataSetup(Id rsvAcountId, BillInput_Ctrl bill, Date salesDate) {
		// 初期化処理
		bill.initAction();
		
		// 会計基本情報を設定する
		AccountAcount__c accAount = bill.oAcountSobj;
		// 人数:Default 1
		accAount.Field66__c = '1';
		accAount.frs__c = rsvAcountId;
		// 売上計上日設定[2014/04/16] ADD
		accAount.SalesDate__c = salesDate;
		// 消費税情報設定
		//accAount.TaxRate__c = CommUtils.getTaxRate(salesDate);
		// 2014/08/25 現状の単価定義区分を設定する
		accAount.UnitPriceDefKb__c = String.valueOf(CommConst.APPOPTION_UTP_DEF_KB);
		// ********************
		// 支払金額の計算
		// ********************
		/*
		CommUtils.ProductInfo prodInfo = new CommUtils.ProductInfo();
		// 単価と数量はNULLの場合、
		Decimal unitPrice = CommUtils.nullToZero(otran.Field20__c);  // <-税金含め単価です
		Decimal qty = CommUtils.nullToZero(otran.Field21__c);
        prodInfo.process(unitPrice, qty, otran.TaxRate__c, otran.ServiceRate__c);
        // 特別税は０に設定する
        otran.SpecialTax__c = 0;
		// 支払総金額
		Decimal dTotalPrice = prodInfo.priceIncTax + CommUtils.nullToZero(otran.SpecialTax__c);
		*/
		// 支払総金額
		Decimal dTotalPrice = 0;
		for (Tran1__c tran : oTranLst) {
			dTotalPrice += CommUtils.nullToZero(tran.Field23__c);
		}
		// ********************
		// 会計支払情報
		// ********************
		TTend__c ttendSobj = new TTend__c(RelAccount__c = rsvAcountId);
		// 支払方法と金額を設定する
		// メディア種別
		// 2017/11/27 簡易会計の支払メディアをカスタマイズできるように改善 WGCH BEGIN
		/*
		ttendSobj.Field2__c = mediaType;
		// カード種別[2013/06/16]
		ttendSobj.CardTypeLst__c = oTtend.CardTypeLst__c;
		*/
		if(noCustomMediaTypeFlg){
			ttendSobj.Field2__c = mediaType;
			// カード種別[2013/06/16]
			ttendSobj.CardTypeLst__c = oTtend.CardTypeLst__c;
		} else {
			AccountMaster__c accMaster = locMstMap.get(mediaType);
			if(accMaster != null){
				String paymentCd = CommConst.getMediaCodeByMediaName(PAYMENT_MATCH_MAP.get(accMaster.PaymentType__c));
				ttendSobj.Field2__c = paymentCd;
				ttendSobj.PayProductRef__c = accMaster.Id;
				ttendSobj.PaymentType__c = accMaster.PaymentType__c;
				ttendSobj.PayProductName__c = accMaster.Name;
				if (paymentCd == CommConst.MEDIA_TYPE_CD_02) {
					// カード種別に反映する
					ttendSobj.CardTypeLst__c = accMaster.Name;
				} else if ( paymentCd == CommConst.MEDIA_TYPE_CD_11 ||
							paymentCd == CommConst.MEDIA_TYPE_CD_12) {
					// 金券種別
				    ttendSobj.CouponTypeLst__c = accMaster.Name;
				}
			}
		}
		// 2017/11/27 簡易会計の支払メディアをカスタマイズできるように改善 WGCH END
		// 支払金額取得
		String strTotalPrice = String.valueOf(dTotalPrice);
		// 預かり　金額
		ttendSobj.Field19__c = strTotalPrice;
		// 支払　金額
		ttendSobj.Field21__c = strTotalPrice;
		// 売上のID
		//ttendSobj.RelAccount__c = rsvAcountId;
		//
		ttendSobj.posNo__c = getPrintPos();
		// 処理リストへ追加する
		BillInput_Ctrl.TTendItem ttendItem = new BillInput_Ctrl.TTendItem(ttendSobj, 0);
		List<BillInput_Ctrl.TTendItem> ttendLst = bill.oTTendSobjLst;
		ttendLst.clear();
		ttendLst.add(ttendItem);
		
		// ********************
		// 会計明細情報
		// ********************
		setUnSubmitInfMap();
		
		List<BillInput_Ctrl.TranItem> tranLst = bill.oTranSobjLst;
		tranLst.clear();
		for (Integer i = 0; i < oTranLst.size(); i++) {
			// 登録対象外
			if (unSubmitInfMap.containsKey(i) && unSubmitInfMap.get(i)) continue; 
			//Tran1__c tranSobj = otran.clone(false,true); //new Tran1__c(RelAccount__c = rsvAcountId);
			oTranLst[i].RelAccount__c = rsvAcountId;
			// 処理リストへ追加する
			BillInput_Ctrl.TranItem tranItem = new BillInput_Ctrl.TranItem(oTranLst[i], 0);
			tranItem.productNm = oTranLst[i].Field5__c;
			tranLst.add(tranItem);	
		}
	}
	/**
	* 会計商品情報を取得
	**/
	@remoteAction
	global static ProductItemUtils.ProductItem getProductItemInfo(String prodCode) {
		return ProductItemUtils.getSingProdcutItemByCode(prodCode);
	}
	/**
	* 会計商品情報を取得
	* 会計商品（支払）は表示対象外
	**/
	@remoteAction
	global static List<ProductItemUtils.ProductItem> getArrayProductItemInfo(String prodCode) {
		return ProductItemUtils.getArrayProdcutItemByCode(prodCode, false, true);
	}
	/**
	* 簡易会計データ作成処理
	**/
	public void upsertData() {
		// 当日の売上存在チェックを行う
		//DateTime todayDt = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
		//String todayRsvName = todayDt.format('yyyyMMdd');
		// 2016/11/25 TIMEZON fix BEGIN by zh
		//Date procDate = (CommUtils.isBlank(saleDate) == true ? Date.today() : Date.parse(saleDate) );
		Date procDate = (CommUtils.isBlank(saleDate) == true ? Date.today() : CommUtils.stringToDate(saleDate) );
		// 2016/11/25 TIMEZON fix END by zh
		String todayRsvName = (DateTime.newInstance(procDate.year(), procDate.month(), procDate.day())).format('yyyyMMdd');
		List<RsvAccount__c> existRsvLst = [select id from RsvAccount__c where Name = :todayRsvName limit 1];
		// 非存在する場合、自動売上データを作成する
		/* 2014.10.17 売上データ作成タイミング改善
		if (existRsvLst.isEmpty()) {
			RsvAccount__c nw = new RsvAccount__c(name = todayRsvName) ;
			insert nw;
			existRsvLst.add(nw);
		}
		*/
		//2017/02/23 demodata機能 by zy BEGIN
		Savepoint sp = Database.setSavepoint();
		//2017/02/23 demodata機能 by zy BEGIN
		// 会計新規登録を行う
		ApexPages.StandardController contrl = new ApexPages.StandardController(new AccountAcount__c());
		// 戻るページ維持する
// 2017/07/10 ログ出力機能を追加する BEGIN
		Map<String,String> paramMap = Apexpages.currentPage().getParameters();
		paramMap.put('ip',localIp);
// 2017/07/10 ログ出力機能を追加する END
		BillInput_Ctrl bill = new BillInput_Ctrl(contrl);
		try {
			// 2017/11/27 簡易会計の支払メディアをカスタマイズできるように改善 WGCH BEGIN
			if(!noCustomMediaTypeFlg) bill.setCustomMediaTypeFlg();
			// 2017/11/27 簡易会計の支払メディアをカスタマイズできるように改善 WGCH END
			/* 2014.10.17 売上データ作成タイミング改善 */
			if (existRsvLst.isEmpty()) {
				RsvAccount__c nw = new RsvAccount__c(name = todayRsvName) ;
				upsert nw name;
				existRsvLst.add(nw);
			}
			// データ設定と統計
			preDataSetup(existRsvLst[0].Id, bill, procDate);
			//会計処理を登録する
			bill.upsertData();
			//2017/01/29 弹出判断 by zy BEGIN
			Datetime curDt = Datetime.newInstance(procDate,system.now().time());
			if (openDoorFlag){
				String demoDate = OrderServiceHelp.getSimpleDemoDate();
				isDemoFlag = !CommUtils.isBlank(demoDate);
				//简易会计弹出
				//2017/02/23 source整理 by zy BEGIN
				if (curPrintInfo == null) {
					//2017/04/18 DOOR OPEN指令区分　by　zy　BEGIN
					curPrintInfo = OrderServiceHelp.getPrintByIp(localIp,UserUtil.CurrentUser.ShopCode__c,OrderServiceHelp.LayoutType.SIMPLEACCOUNT);
					//2017/04/18 DOOR OPEN指令区分　by　zy　END
				}
				if (curPrintInfo != null) {
					prinUrl = curPrintInfo.prinUrl;
					statusUrl = curPrintInfo.statusUrl;
				}
				//loadDoorOpen();
				//2017/02/23 source整理 by zy END
				List<Tran1__c> transLst = new List<Tran1__c> ();
				for (integer i = 0 ; i < bill.oTranSobjLst.size() ; i++ ) {
					transLst.add(bill.oTranSobjLst[i].sobj);
				}
				//2017/02/22 預ｶﾘ金額処理　by　zy　BEGIN
				if (!CommUtils.isBlank(paymentprice) && paymentprice !='0'){
					String payName = CommConst.MEDIA_TYPE_01;
					Tran1__c ttanTran = new Tran1__c(ActionType__c = CommConst.PROD_ACTION_TYPE_PY,Field20__c = paymentprice,Field21__c = '1',field5__c = payName);
					transLst.add(ttanTran);
				} else {
					for (integer i = 0 ; i < bill.oTTendSobjLst.size() ; i++ ) {
						TTend__c t =  bill.oTTendSobjLst[i].sobj;
						//2017/05/26 印刷の支払いレーアウト追加　by zy BEGIN
						String payName = CommUtils.nullToBlank(t.CardTypeLst__c);
						if (CommUtils.isBlank(payName)) payName = CommUtils.nullToBlank(t.Field3__c);
						transLst.add(new Tran1__c (ActionType__c = CommConst.PROD_ACTION_TYPE_PY,Field20__c = t.Field20__c,Field21__c = '1',field5__c = payName));
						//2017/05/26 印刷の支払いレーアウト追加　by zy END
					}
				}
				//2017/02/22 預ｶﾘ金額処理　by　zy　END
				//2017/02/23 demodata機能 by zy BEGIN
				AccountAcount__c acc = [select Field145__c,id,TaxRate__c from AccountAcount__c where id = :bill.oAcountSobj.id];
				//2017/04/18 DOOR OPEN指令区分　by　zy　BEGIN
				//if (curPrintInfo != null) printInfoJson = OrderServiceHelp.getPrintJson(curPrintInfo,transLst,true,OrderServiceHelp.LayoutType.SIMPLEACCOUNT, new Map<Id,List<FoodDetail__c>>(), acc,null);
				//所在ip段存在配置的打印机
				if (curPrintInfo != null) {
					//2017/07/03 簡易会計posNo追加　by zy BEGIN
					//添加控制中有auroDoorOpen
					List<OrderServiceHelp.LayoutType> orderLayouts = new List<OrderServiceHelp.LayoutType>{OrderServiceHelp.LayoutType.SIMPLEACCOUNT};
					//如果dooropen为自动则存入
					if (autoDoorOpen) orderLayouts.add(OrderServiceHelp.LayoutType.DOOROPEN);
					// 関数パラメータ変更対応
					printInfoJson = OrderServiceHelp.getPrintJsons(curPrintInfo,transLst,orderLayouts, new Map<Id,List<FoodDetail__c>>(), acc,null);
					//2017/07/03 簡易会計posNo追加　by zy END
				}
				//2017/04/18 DOOR OPEN指令区分　by　zy　END
				//doorOpenInfoJson = outPrintJson(subTotal,dTotalTax,curDt,printDetailLst,doorOpenSeq);
				if (isDemoFlag) DataBase.rollback(sp);
				//2017/02/23 demodata機能 by zy END
			}
			//2017/01/29 弹出判断 by zy END
		} catch (Exception e) {
			System.debug(loggingLevel.Error, 'ERROR='+e.getStackTraceString());
			//会計情報を失敗しました。
			// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH BEGIN
			if (!e.getMessage().contains(Label.MSG_006_0459)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_034_0018 + e.getMessage()));
			// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH END
			//2017/02/23 demodata機能 by zy BEGIN
			DataBase.rollback(sp);
			//2017/02/23 demodata機能 by zy END
		}
		if (ApexPages.hasMessages(ApexPages.Severity.ERROR)) {
			return;
		}
		
		// 会計書ID設定を行う
		accountsId = bill.oAcountSobj.Id;
		// 画面クリアして、再登録準備を行う
		clearInputForm();
		oTranLst.clear();
		totalPrice = null;
		// 2017/02/22 弹出输入金额  begin by wx		
		paymentprice = null;
		// 2017/02/22 弹出输入金额  end by wx
		unSubmitFlgStr = null;
		unSubmitInfMap.clear();
	}
	//2017/07/03 簡易会計posNo追加　by zy BEGIN
	private DeviceConfigHelp.DeviceInfo deviceConfig;
	private boolean isPosFlag;
	private boolean autoDoorOpen;
	private void initDeviceConfig(){
		try{
			//店舗切り換える
			deviceConfig = DeviceConfigHelp.getDevice(UserUtil.CurrentUser.ShopCode__c);
		}catch(Exception e){}
		//初期化のポースNO
		chgDevConfig('');
	}
	private void chgDevConfig(String curPosNo){
		isPosFlag = false;
		//默认值应为true，因为原来默认都是自动打开的
		autoDoorOpen = true;
		if (deviceConfig != null) {
			DeviceConfigHelp.FuncLst simpleFunc = deviceConfig.getFuncLstByCurPos(curPosNo,DeviceConfigHelp.DeviceType.SIMPLEACCOUNT);
			isPosFlag = simpleFunc.orderPrintFlag;
			autoDoorOpen = simpleFunc.orderAutoDoorOpenFlag;
		}
	}
	private String getPrintPos(){
		String printNo = '';
		if (curPrintInfo == null) {
			OrderServiceHelp.setInstance(UserUtil.CurrentUser.ShopCode__c);
			curPrintInfo = OrderServiceHelp.getPrintByIp(localIp,UserUtil.CurrentUser.ShopCode__c,OrderServiceHelp.LayoutType.SIMPLEACCOUNT);		
		}
		if (curPrintInfo != null) {
			//根据ip再次判断posno
			chgDevConfig(CommUtils.nullToBlank(curPrintInfo.printNo));
			if (isPosFlag) {
				if (curPrintInfo != null) printNo = curPrintInfo.printNo;
			}
		}
		return printNo;
	}
	//2017/07/03 簡易会計posNo追加　by zy END
	/**
	* 単価・数量・消費税・サビース料、特別税
	**//*
	@RemoteAction
	global static String calTotalPrice (Decimal unitPrice, Decimal unitNums, Decimal taxRate, Decimal serviceRate, Decimal specialTax) {
		CommUtils.ProductInfo prodInfo = new CommUtils.ProductInfo();
		prodInfo.process(unitPrice, unitNums, taxRate, serviceRate);
		return String.valueOf(prodInfo.priceIncTax + specialTax);
	}*/
/**
*2015-11-18 
*テストクラスSimpleAccountsCtrlTestに移行する
	@isTest(SeeAllData=false)
	static void selfTest() {
		// 店舗は空白に設定する
		UserUtil.CurrentUser.ShopCode__c = null;
		update UserUtil.CurrentUser;
		
		// 商品作成する
		List<AccountMaster__c> prodList = TestCommon.createProductMst(1);
		// 
		SimpleAccountsCtrl ctrl = new SimpleAccountsCtrl();
		ctrl.mediaType = ctrl.mediaTypeOptionLst[1].getValue();
		ctrl.otran.Field20__c = '16000';
		ctrl.otran.Field21__c = '2';
		ctrl.otran.Field7__c = prodList[0].Id;
		ctrl.otran.ActionType__c = prodList[0].ActionType__c;
		ctrl.otran.TaxRate__c = prodList[0].TaxRateCal__c;
		ctrl.otran.ServiceRate__c = prodList[0].ServiceRate__c;
		ctrl.otran.SpecialTax__c = 200;
		ctrl.productNm = prodList[0].Name;
		
		ctrl.saveTranToMemory();
		
		ctrl.upsertData();
		
		// 自動売上、会計、会計支払い、会計明細の作成
		// 支払い明細の作成の確認
		List<Tran1__c> tranLst = [select id from Tran1__c where Field7__c = :prodList[0].Id];
		System.assert(!tranLst.isEmpty(), tranLst);
		
		// ログインユーザーの店舗コードが未設定する場合、会計に店舗情報を設定を行わない
		List<AccountAcount__c> accLst = [select id,ShopSeq__c,ShopCode__c,ShopName__c  from AccountAcount__c where id = :ctrl.accountsId];
		System.assertEquals(accLst[0].ShopSeq__c, null, accLst);
		System.assertEquals(accLst[0].ShopCode__c, null, accLst);
		System.assertEquals(accLst[0].ShopName__c, null, accLst);
	}
	
	@isTest(SeeAllData=false)
	static void testSimpleAccShopSetup() {
		ShopInformation__c shop = TestCommon.createShopInfo();
		// 店舗は空白に設定する
 		User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	loginUser.ShopCode__c = shop.ShopCode__c;
    	update loginUser;
		// 商品作成する
		List<AccountMaster__c> prodList = TestCommon.createProductMst(1);
		// 
		SimpleAccountsCtrl ctrl = new SimpleAccountsCtrl();
		ctrl.mediaType = ctrl.mediaTypeOptionLst[1].getValue();
		ctrl.otran.Field20__c = '16000';
		ctrl.otran.Field21__c = '2';
		ctrl.otran.Field7__c = prodList[0].Id;
		ctrl.otran.ActionType__c = prodList[0].ActionType__c;
		ctrl.otran.TaxRate__c = prodList[0].TaxRateCal__c;
		ctrl.otran.ServiceRate__c = prodList[0].ServiceRate__c;
		ctrl.otran.SpecialTax__c = 200;
		ctrl.productNm = prodList[0].Name;
		
		ctrl.saveTranToMemory();
		
		ctrl.upsertData();
		 
		// 自動売上、会計、会計支払い、会計明細の作成
		// 支払い明細の作成の確認
		List<Tran1__c> tranLst = [select id from Tran1__c where Field7__c = :prodList[0].Id];
		System.assert(!tranLst.isEmpty(), tranLst);
		
		
		// ログインユーザーの店舗コードが未設定する場合、会計に店舗情報を設定を行わない
		List<AccountAcount__c> accLst = [select id,ShopSeq__c,ShopCode__c,ShopName__c  from AccountAcount__c where id = :ctrl.accountsId];
		System.assertEquals(accLst[0].ShopSeq__c, shop.Seq__c, accLst);
		System.assertEquals(accLst[0].ShopCode__c, shop.ShopCode__c, accLst);
		System.assertEquals(accLst[0].ShopName__c, shop.Name, accLst);
	}
*/	
	// 2017/07/26 4）ログ情報はDBに記載する by zy BEGIN
	@remoteAction
	global static void savePrintLodToDb(String action){
		String curLog = system.now().format('yyyy-MM-dd HH:mm:ss SSS') + '*************簡易会計印刷BEGIN******************\n';
		User u = UserUtil.CurrentUser;
		curLog += 'ユーザ：' + u.name + '（' + u.id +'）\n';
		curLog += action + '\n';
		curLog += system.now().format('yyyy-MM-dd HH:mm:ss SSS') + '*************簡易会計印刷END  ******************\n';
		CommLogUtils.saveLogToDb(curLog,CommLogUtils.LogType.POS,new List<String>{'cmimg','newsmsg','qrurl'});
	}
	// 2017/07/26 4）ログ情報はDBに記載する by zy END
	// 2017/11/27 簡易会計の支払メディアをカスタマイズできるように改善 WGCH BEGIN
	public Boolean noCustomMediaTypeFlg{get;private set;}
	// カスタマイズ現金商品コードリスト情報を格納する
	public String jsonCaseProducts{get;private set;}
	// XMLの定義情報から取得する
	private Map<String, String> PAYMENT_MATCH_MAP = new Map<String, String>();
	// Map<会計商品コード・会計商品>
	private Map<String, AccountMaster__c> locMstMap = new Map<String, AccountMaster__c>();
	private List<Selectoption> getPaymentToPayMeidaXml(){
	    // カスタマイズ現金商品コードリスト情報を格納する
		List<String> caseProducts = new List<String>();
        // カスタマイズした支払メディアリスト情報を格納する
        List<Selectoption> rsMediaTypeOptionLst = new List<Selectoption>();
		try {

			// 会計商品コード＞メデイアー
			List<String> productCdLst = new List<String>();
			// 支払メディア情報格納する
			Map<String,String> locMediaProductMap = new Map<String, String>();
			// 店舗コード情報設定を行う
			String shopCode = UserUtil.CurrentUser.ShopCode__c;
			// 会計商品の支払種別から支払メデイア対応表XML分析処理
			// 格納用変数クリアする
			BillSimpleHelp help = new BillSimpleHelp(shopCode);
			PAYMENT_MATCH_MAP = help.getPaymentTypeToMediaLabMap();
			Dom.XmlNode targetNode = CommXmlUtils.parseXmlDoc('SimplePaymentConfig', shopCode);
			// 定義情報を読み込み
			for(Dom.XMLNode xmlNode : targetNode.getChildElements()) {
				// タグ名
				String attributeName = xmlNode.getName();
				if (attributeName.equalsIgnoreCase('SHOPCODE')) continue;	// 店舗情報のタグ
				if (attributeName.equalsIgnoreCase('BUTTONTAB')) {		// 会計支払メデイアー＞会計商品コード対応情報を取得する
					// Convert Field Info
					for(Dom.XMLNode convert : xmlNode.getChildElements()) {
						Dom.XMLNode mediaNmField = convert.getChildElement('LABEL', null);
						Dom.XMLNode produCdField = convert.getChildElement('PRODCODE', null);
						// タグ定義内容を未定義場合
						if (produCdField == null || mediaNmField == null ) continue;
						// トランスレーション対応
						String productCd = CommUtils.nullToBlank(produCdField.getText());
						String mediaLab = CommUtils.nullToBlank(mediaNmField.getText());
						// タグ内容を未定義場合
						if (CommUtils.isBlank(productCd) || CommUtils.isBlank(mediaLab)) continue;
						if(!locMediaProductMap.containsKey(productCd)){
							productCdLst.add(productCd);
							locMediaProductMap.put(productCd, mediaLab);
						}
					}				
				}
			}
			// 会計メデイア名ー＞会計商品コードから会計商品IDを取得する
			if (!locMediaProductMap.isEmpty()) {
			    // 商品処理種別:支払
			    set<string> actionTypes = new set<String>{CommConst.PROD_ACTION_TYPE_PY};
			    // 支払種別:
			    set<string> payTyps = new set<String>{CommConst.PROD_PAY_TYPE_CASH,
			                                          CommConst.PROD_PAY_TYPE_CARD,
			                                          CommConst.PROD_PAY_TYPE_URKK,
			                                          CommConst.PROD_PAY_TYPE_KUPO,
			                                          CommConst.PROD_PAY_TYPE_DIS_RATE,
			                                          CommConst.PROD_PAY_TYPE_DIS_PRICE,
			                                          CommConst.PROD_PAY_TYPE_YOYK
			                                         };
			    // 2018/04/11 支払メデイア種別はカスタマイズできるように対応 BEGIN
			    for(SelectOption custMd : BillSimpleHelp.getCustPayList()){
			    	payTyps.add(custMd.getLabel());
			    }
			    // 2018/04/11 支払メデイア種別はカスタマイズできるように対応 END
				List<AccountMaster__c> accMsts = [  Select Id, Name, Field3__c, PaymentType__c, ActionType__c
													From AccountMaster__c 
													Where Field3__c in: productCdLst And ActionType__c in :actionTypes And PaymentType__c in :payTyps];
				for (AccountMaster__c accMst : accMsts) {
				    // 該当会計商品の支払種別設定不正の場合
				    String payLabel = PAYMENT_MATCH_MAP.get(accMst.PaymentType__c);
					if(CommUtils.isBlank(payLabel)) continue;
					// 会計商品コード：会計商品
					locMstMap.put(accMst.Field3__c, accMst);
					// 支払メディア情報は現金コードの場合
					String payCode = CommConst.getMediaCodeByMediaName(payLabel);
					if (payCode == CommConst.MEDIA_TYPE_CD_01) caseProducts.add(accMst.Field3__c);
				}
				// XML定義からMediaの会計商品情報をMapに格納する
				for (String productCd : productCdLst) {
					if(!locMstMap.containsKey(productCd)) continue;
					String media = locMediaProductMap.get(productCd);
					rsMediaTypeOptionLst.add(new SelectOption(productCd,media));
				}
			}
		} catch(Exception e){} 
		jsonCaseProducts = JSON.serialize(caseProducts);
		return rsMediaTypeOptionLst;
	}
	// 2017/11/27 簡易会計の支払メディアをカスタマイズできるように改善 END
}