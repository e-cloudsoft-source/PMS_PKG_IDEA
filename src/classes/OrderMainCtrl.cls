/**
* オーダーシスタムのクラス
* 2017/07/26 4）ログ情報はDBに記載する
* 2019/03/28 オーダーエントリー改善 レシート番号連続
* 2019/03/28 オーダーエントリー改善レシート再出力機能
* 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。
**/
public with sharing class OrderMainCtrl {
	//public String inShopCode{get; set;}	// 支店コード
	public List<ButtonTab> buttonsLstTab{get;set;}
	transient public String oProdMapsJson{get;private set;}	//商品リスト
	transient public Map<String, String> buttonsIconMap{get; private set;}
	public String LogoIcon{get; private set;}
	// 画面利用する店舗コード情報[支払情報、会計商品選べるコンポネット表示の支店コード]
	//2017/07/05 多店舗対応選択リスト　by　zy　BEGIN
	//public String oShopCode{get;private set;}
	public String oShopCode{get; set;}
	//2017/07/05 多店舗対応選択リスト　by　zy　END
	public String curreny{get{return CommBaseCtrl.getCurrencySybmol();}}
	// 小数部分桁数取得する
	private static final Integer gPointLen = CommUtils.getPointLen();
	public String localIp{get;set;} 	//Device IP
	public String roomId{get;set;}		//Device map room id 
	public List<TabClass> tabLst{get;set;}
	private static CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo();
	public String ReturnValue{get;set;}
	public Integer autoStemp{get;set;}
//2017/02/22 source整理 by zy BEGIN
	//public long beginStmp{get;set;}
//2017/02/22 source整理 by zy END
	private Map<Integer,String> kbnMap = new Map<Integer,String>{1 => Label.MSG_060_0019 ,2 => Label.MSG_060_0020,3 => Label.MSG_060_0021,4 => Label.MSG_060_0022};
	public String kbnLabel{get;set;}
//2017/02/22 source整理 by zy BEGIN
	//private ShopInformation__c shop;
//2017/02/22 source整理 by zy END
	public String currentLanguage{get;set;}
	public Map<String,String> currentLanguageLabelMap{get;set;}
	public String selectStmp{get;set;}
	public String orderMessage {get;set;}
	public String siteUrl {get;set;}
	// 定義している商品コード
	private	Set<String> prodCodeSet;
//2017/02/22 source整理 by zy BEGIN
/*
	public String prinUrl{get;set;}
	public String statusUrl{get;set;}
	public String repiceLayout{get;set;}
	public String curPno {get;set;}
	public String curRoomName{get;set;}
	public String shopNm{get;private set;}
	public String shopAdd{get;private set;}
	public String shopPhone{get;private set;}
*/
//2017/02/22 source整理 by zy END
	//2017/02/13 new Layout by zy BEGIN
	//private map<String,PrintInfo> printInfoMap;
	//room seq to print info
	//private map<String,String> roomToPrintMap;
//2017/02/22 source整理 by zy BEGIN
	//public OrderServiceHelp.PrintInfo curPrintInfo{get;set;}
	//private OrderServiceHelp.PrintPara curPara;
//2017/02/22 source整理 by zy END
	//2017/02/13 new Layout by zy END
	public List<ProductInfo> exitProdLst;
	//2017/01/10 demo mode by zy BEGIN
	public String demoDate{get;set;}
	//2017/01/10 demo mode by zy END
	//2017/07/05 多店舗対応選択リスト　by　zy　BEGIN
	public List<SelectOption> shopCodeLst{get;set;}
	//2017/07/05 多店舗対応選択リスト　by　zy　END
	private String filterShopCode(String shopCd) {
	    if (shopCodeLst == null || shopCodeLst.isEmpty()) return '';
	    String eqlSpCd = CommUtils.nullToBlank(shopCd);
	    for (SelectOption opt : shopCodeLst) {
	        if (opt.getValue() == eqlSpCd) {
	            return eqlSpCd;
	        }
	    }
	    return '';
	}
	//2017/02/22 ipad侧対応　by zy BEGIN
	public OrderMainCtrl(){ 
		Map<String,String> paramMap = Apexpages.currentPage().getParameters(); 
		siteUrl = Site.getDomain() + ':' + Site.getBaseUrl() + ':' + Site.getBaseInsecureUrl() + ':' + Site.getBaseCustomUrl();
		if (paramMap.containsKey('localIp')) localIp = paramMap.get('localIp');
        // 外部SITE利用するがどうかフラグ
        isDomainFlag = Site.getDomain() == null;
        //2017/07/05 多店舗対応選択リスト　by　zy　BEGIN
        //shopCodeLst = ShopInfoUtil.getBranchShopLst();
        shopCodeLst = new List<SelectOption>();
        if (isDomainFlag) {
	        set<string> shopCdRangSet = UserUtil.CurrentUserInfo.shopSt;
	        List<SelectOption> wkShopCodeLst = ShopInfoUtil.getBranchShopLst();
	        for (SelectOption opt: wkShopCodeLst) {
	            if (!shopCdRangSet.contains(opt.getValue())) continue;
	            shopCodeLst.add(opt);
	        }
        }
        //2017/07/05 多店舗対応選択リスト　by　zy　END
        
		//2017/04/20 多店舗機能対応　by　zy BEGIN
		oShopCode = CommUtils.nullToBlank(paramMap.get('spcd'));
   		
		if ( isDomainFlag && CommUtils.isBLank(oShopCode)) {
			//2017/07/05 多店舗対応選択リスト　by　zy　BEGIN
			String shopCode = getCookieInfValue (COOKIE_SHOPCODE);
			// Cookieの店舗コードは対象外の場合、店舗コードが空欄になる
			shopCode = filterShopCode(shopCode);
			if (CommUtils.isBlank(shopCode)) 
				// 2020/03/31 オーダーエントリー画面を開こうとすると、添付画像のエラーが表示されます。 by zy BEGIN
				// oShopCode = UserUtil.CurrentUser.ShopCode__c;
				oShopCode = UserUtil.CurrentUserInfo.defaultShopCode;
				// 2020/03/31 オーダーエントリー画面を開こうとすると、添付画像のエラーが表示されます。 by zy END
			else 
				oShopCode = shopCode;
			//2017/07/05 多店舗対応選択リスト　by　zy　END
		}
		OrderServiceHelp.setInstance(oShopCode);
		// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy BEGIN
		initLocAndLayout();
		// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy END
		// 2020/02/15 初期画面を「テーブル選択画面」にする by zy BEGIN
		roomPageOpenFlg = OrderServiceHelp.getRoomPageOpenFlg();
		// 2020/02/15 初期画面を「テーブル選択画面」にする by zy END
		// 2020/02/15 予約が入っていないテーブルも選択可能に by zy BEGIN 
		//複数部屋選択フラグ
		multiRoomFlg = OrderServiceHelp.getMultiRoomFlg();
		// 2020/02/15 予約が入っていないテーブルも選択可能に by zy END 
		//2017/04/20 多店舗機能対応　by　zy END
		simpleWidth = OrderServiceHelp.getSimpleWidth();
		fontSize = OrderServiceHelp.getFontSize();
		//2017/05/26 印刷レーアウト選択する by zy BEGIN
		curSequenceInfo = '';
		//2017/05/26 印刷レーアウト選択する by zy END
		// 2019/01/15 オーダーエントリー改善（メニューサイズ自動調整）by cxw BEGIN
		menuZoomFlag = OrderServiceHelp.getMenuZoomFlag();
		//2019/02/15 オーダーエントリー改善（文字サイズをカスタマイズとレイアウト自由カスタマイズ機能） by cxw BEGIN
		roomZoomFlag = OrderServiceHelp.getRoomZoomFlag();
		//2019/02/15 オーダーエントリー改善（文字サイズをカスタマイズとレイアウト自由カスタマイズ機能） by cxw END
		mobileFlag = OrderServiceHelp.getMobileFlag();
		// 2019/01/15 オーダーエントリー改善（メニューサイズ自動調整）by cxw END
		// 2020/02/15 会計の簡易レイアウトを変更 by zy BEGIN
		Schema.DescribeFieldResult fieldResult = Tran1__c.CookMemo__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		cookDescOpts = new List<System.SelectOption>();
        for( Schema.PicklistEntry f : ple) {
            cookDescOpts.add(new SelectOption(f.getValue(),f.getLabel()));
        }
		// 2020/02/15 会計の簡易レイアウトを変更 by zy END
		// 2020/06/30 オーダエンドリーでの金額入力 by zy BEGIN
		isPriceInputFlg = false;
		// 2020/06/30 オーダエンドリーでの金額入力 by zy END
	}
	//2017/02/22 ipad侧対応　by zy END
	//初期化
	public Pagereference initAction() {
		if (CommBaseCtrl.getLocalIsJapanese()) currentLanguage = 'ja';
		else currentLanguage = 'en';
//2017/02/22 source整理 by zy BEGIN
		//repiceLayout = '';
//2017/02/22 source整理 by zy END
		//2017/01/10 demo mode by zy BEGIN
		demoDate = '';
		//2017/01/10 demo mode by zy END
		//2017/02/13 new Layout by zy BEGIN
//2017/02/22 source整理 by zy BEGIN
		//curPrintInfo = new OrderServiceHelp.PrintInfo();
//2017/02/22 source整理 by zy END
		//printInfoMap = new map<String,PrintInfo>();
		//roomToPrintMap = new map<String,String>();
		//2017/02/13 new Layout by zy END
		currentLanguageLabelMap = new Map<String,String>{'ja' => 'MSG_060_0018','en' => 'MSG_060_0017'};
		// 2019/01/30 JINYABUG-1347 BUG FIX by zy BEGIN
		// 言語保持
		Map<String,String> paramMap = Apexpages.currentPage().getParameters(); 
		if (paramMap.containsKey('lang')){
			String lang = CommUtils.nullToBlank(paramMap.get('lang'));
			if (currentLanguageLabelMap.containsKey(lang))
			currentLanguage = lang;
		}
		// 2019/01/30 JINYABUG-1347 BUG FIX by zy END
		orderMessage = '';
		selectStmp = '';
//2017/02/22 source整理 by zy BEGIN
		//prinUrl = 'ws://localhost:9999/printer';
		//statusUrl = 'ws://localhost:9999/status';
//2017/02/22 source整理 by zy END
		prodCodeSet = new Set<String>();
		// 店舗コード情報設定を行う
        //oShopCode = '';
		//getLayoutTagInfo(oShopCode);
		readDocumentProperties(false);
		//OrderMainCtrlHelp help = new OrderMainCtrlHelp();
		//system.debug(logginglevel.info,'shop:::' + shop);
		//system.debug(logginglevel.info,'oShopCode:::' + oShopCode);
//2017/02/22 source整理 by zy BEGIN
		/*
		try{
			List<ShopInformation__c> shops = [SELECT 
	                Id
	                , Name
	                , Phone__c
	                , Address__c
	                , ShopCode__c
	                , Post__c
	            FROM
	                ShopInformation__c
	            where   ShopCode__c = :oShopCode ];
	        if(!shops.isEmpty())
        		shop = shops[0];
        	else 
        		shop = defaultShopMessage();
        }catch(Exception e){
        	shop = defaultShopMessage();
        }
        shopNm = shop.Name;
        shopAdd = shop.Address__c;
        shopPhone = shop.Phone__c;
        */
//2017/02/22 source整理 by zy END
		loadData();
		ReturnValue = '';  
   		kbnLabel = kbnMap.get(CommConst.APPOPTION_UTP_DEF_KB);
   		//2017/04/20 bug fix by zy BEGIN
   		mainRoomMap = new Map<Id,Roominf>();
   		//2017/04/20 bug fix by zy END
   		//2017/04/18 staff側　部屋機能　by　zy BEGIN
   		modeType = MODETYPE_COMMON;
		if (isDomainFlag) {
			//loadTodayOrCurRooms(true);
			
			String cookLayout = getCookieInfValue (COOKIE_LAYOUT_NAME);
			// 2020/02/15 会計の簡易レイアウトを変更 by zy BEGIN
			if (cookLayout == MODETYPE_COMMON || cookLayout == MODETYPE_SIMPLE || cookLayout == MODETYPE_SIMPLE_UP) {
				modeType = cookLayout;
			}
			// 2020/02/15 会計の簡易レイアウトを変更 by zy END
		} 
		// 2017/09/11 印刷リスト機能　by　zy　BEGIN
		//　検索日付設定
		queryDate = CommUtils.isBlank(demoDate) ? System.today().format() : demoDate;
		// 2017/09/11 印刷リスト機能　by　zy　END
//system.debug(logginglevel.info,'modeType::::' + modeType);
		//2017/04/18 staff側　部屋機能　by　zy END
		return null;
	}
	//2017/04/18 staff側　部屋機能　by　zy BEGIN
	public Map<Id,Roominf> mainRoomMap{get;set;}
	public String modeType{get;set;}
	//2017/04/20 bug fix by zy BEGIN
	public String curRoomJson{get;set;}
	//2017/04/20 bug fix by zy END
	public String curUserInfo{get;set;}
	//2017/07/05 多店舗対応選択リスト　by　zy　BEGIN
	public String curShopName{get;private set;}
	//2017/07/05 多店舗対応選択リスト　by　zy　END
	public transient String roomJson{get;set;}
	public Boolean isDomainFlag{get;set;}
	private final static String MODETYPE_COMMON = 'COMMON';
	private final static String MODETYPE_SIMPLE = 'SIMPLE';
	private final static String COOKIE_ROOMID_NAME = '_OrderMain_Cookie_RoomId';
	private final static String COOKIE_LAYOUT_NAME = '_OrderMain_Cookie_Layout';
	//2017/07/05 多店舗対応選択リスト　by　zy　BEGIN
	private final static String COOKIE_SHOPCODE = '_OrderMain_Cookie_ShopCode';
	//2017/07/05 多店舗対応選択リスト　by　zy　END
	private String orgRoomId;
	// 2016/02/04 前回選択値を記憶する BEGIN
    private String getCookieInfValue (String cookieName) {
		Cookie statucModeCookie;
		String retVal = '';
		statucModeCookie = ApexPages.currentPage().getCookies().get(cookieName);
//system.debug(logginglevel.info,'statucModeCookie::::' +  ApexPages.currentPage().getCookies());
        if (statucModeCookie != null) retVal = statucModeCookie.getValue();
        return retVal;
    }
    private void setCookieInf (String cookieName,String value) {
		// 画面最後利用する画面モードはCookiesに維持する
		Cookie statucModeCookie = new Cookie(cookieName, value, null, -1, true);
		ApexPages.currentPage().setCookies(new Cookie[]{statucModeCookie});
//system.debug(logginglevel.info,'statucModeCookie::::' +  ApexPages.currentPage().getCookies());
    }
    // 2017/09/27 コレクションサイズ 最大サイズを超えエラー修正　by　zy BEGIN
    // 2017/10/14 部屋の予約別の機能追加　by　zy　BEGIN
    //public List<List<Id>> floatRoomLst{get;set;}
    public FloatRowInfo floatRoomLst{get;set;}
    // 2017/10/14 部屋の予約別の機能追加　by　zy　END
    // 2017/09/27 コレクションサイズ 最大サイズを超えエラー修正　by　zy END
	private void loadTodayOrCurRooms(boolean isToday){
		//2017/05/26 無予約の部屋データ作成機能追加　by zy BEGIN
		//部屋タイプリスト
		roomTypeOpts = new List<SelOption>();
		//2017/05/26 無予約の部屋データ作成機能追加　by zy END
		//OrderEntryLayoutCd__c 图片区分
		//Set<Id> roomIds = new Set<Id>();
		Map<String,Lead__c> roomToLeadMap = new Map<String,Lead__c>();
		if (isToday) {
			/*
			String spcd = UserUtil.CurrentUser.ShopCode__c;
			//2017/04/20 多店舗機能対応　by　zy BEGIN
			if (oShopCode != null) {
				spcd = oShopCode;
			}
			//2017/04/20 多店舗機能対応　by　zy END
			curUserInfo = CommUtils.nullToBlank(UserInfo.getLastName()) + ' ' + CommUtils.nullToBlank(UserInfo.getFirstName());
			if (!CommUtils.isBlank(UserUtil.CurrentUser.EmployeeCode__c)) {
				curUserInfo += '(' + UserUtil.CurrentUser.EmployeeCode__c + ')';
			}
			//2017/04/20 bug fix by zy BEGIN
			String formatStr = 'yyyy/MM/dd HH:mm:ss';
			String curDtStr = curTime.format(formatStr);
			//2017/04/21 开始日期提前两天 by zy BEGIN
			Date begDate = curDt.addDays(-1);
			//2017/04/21 开始日期提前两天 by zy END
			//2017/04/20 bug fix by zy BEGIN
			Map<String,List<Lead__c>> leadSizeMap = new Map<String,List<Lead__c>>();
			List<Lead__c> leadLst = OrderServiceHelp.queryLeadList(curDt,begDate,spcd);
			for (integer i = 0 ; i < leadLst.size() ; i++) {
				Lead__c upd = leadLst[i];
				// 同じ予約ＩＮＤＥＸ、予約ＩＮＤＥＸＳＵＢ、グループＮＯの場合、同じ予約連泊情報を認識する
				String dtKey =	CommUtils.nullToBlank(upd.LeadIndexRef__c) 
						+ '_' +	CommUtils.nullToBlank(upd.LeadIndexSubId__c) 
						+ '_' +	CommUtils.nullToZero(upd.RoomGroupNo__c);
				if (!leadSizeMap.containsKey(dtKey)){
					leadSizeMap.put(dtKey,new List<Lead__c>{upd});
				} else {
					List<Lead__c> updLeadLst = leadSizeMap.get(dtKey);
					//2017/06/13 checkin部屋表示する　by　zy BEGIN
					//連泊の場合
					if (updLeadLst.size() > 0 ) {
						if (upd.Field298__c != null) {
							upd.field4__c = leadSizeMap.get(dtKey)[updLeadLst.size() - 1].field3__c;
						//未来日はチェックインしないの場合、前日の予約表示する
						} else {
							leadSizeMap.get(dtKey)[updLeadLst.size() - 1].field3__c = upd.field4__c;
						}
					}
					//2017/06/13 checkin部屋表示する　by　zy END
					leadSizeMap.get(dtKey).add(upd);
				}
			}
//2017/06/13 checkin部屋表示する　by　zy BEGIN
			List<Lead__c> chkLeads = new List<Lead__c>();
//2017/06/13 checkin部屋表示する　by　zy END
			for ( Lead__c lead : leadLst) {
//2017/06/13 checkin部屋表示する　by　zy BEGIN
				if (lead.Field298__c == null) continue;
//2017/06/13 checkin部屋表示する　by　zy END
				//2017/04/20 bug fix by zy BEGIN
				//是否在时间段内
				if (processLeadTime(lead, curDtStr, formatStr)) {
					roomIds.add(lead.Rroom__c);		
					roomToLeadMap.put(lead.Rroom__c,lead);
//2017/06/13 checkin部屋表示する　by　zy BEGIN
				}  else {
					chkLeads.add(lead);
				}
//2017/06/13 checkin部屋表示する　by　zy END
				//2017/04/20 bug fix by zy END
			}
//2017/06/13 checkin部屋表示する　by　zy BEGIN
			//时间段内没有未来时间找预约显示
			for (Lead__c lead : chkLeads) {
				//既存データは判定しない
				if (roomToLeadMap.containsKey(lead.Rroom__c)) continue;
				//未来日のチュックインのデータを取得する
				Datetime beginTime = Datetime.newInstance(lead.EntryTime__c.date(),CommUtils.stringtoTime(lead.field4__c));
				Datetime endTime = Datetime.newInstance(lead.Departure__c.date(),CommUtils.stringtoTime(lead.field3__c));
				if (beginTime.format(formatStr) > curDtStr ) {
					roomIds.add(lead.Rroom__c);		
					roomToLeadMap.put(lead.Rroom__c,lead);
		        }
			}
//2017/06/13 checkin部屋表示する　by　zy END
*/
			/*
			//2017/04/18 staff側　部屋機能　by　zy BEGIN
			//cookie中无数据的时候读取xml中ip的房间
			if (!CommUtils.isBlank(roomId)) {
				roomIds.add(roomId);
			}
			//2017/04/18 staff側　部屋機能　by　zy END
			*/
		} else {
			Datetime curTime = system.now();
			boolean demoFlag = false;
			if (!CommUtils.isBlank(demoDate)) { 
				curTime = Datetime.newInstance(CommUtils.stringtoDate(demoDate), curTime.time());
				demoFlag = true;
			}
			Date curDt = curTime.date();
			try{
				Lead__c lead = getCurLeadId(roomId,curTime.getTime(),demoFlag);
				roomToLeadMap.put(lead.Rroom__c,lead);
				//roomIds.add(lead.Rroom__c);	
			} catch(exception e) {
				if (!CommUtils.isBlank(roomId)){
					roomToLeadMap.put(roomId,null);	
					//roomIds.add(roomId);
				}
//system.debug(logginglevel.info,'e::::' + e.getStackTraceString());
			}
		}
		//2017/05/26 無予約の部屋データ作成機能追加　by zy BEGIN
		refreshRoomMessage(roomToLeadMap);
		/*
		floatRoomLst = new List<Id>();
		//2017/04/20 Security Fix　by　zy BEGIN
		for (Room__c r : OrderServiceHelp.getRoomLst(roomIds)) {
			mainRoomMap.put(r.id,new Roominf(r,roomToLeadMap.get(r.id)));
			floatRoomLst.add(r.id);
		}
		//2017/04/20 Security Fix　by　zy END
		*/
		//2017/05/26 無予約の部屋データ作成機能追加　by zy END
	}
	//2017/05/26 無予約の部屋データ作成機能追加　by zy BEGIN
	//刷新部屋信息
	private void refreshRoomMessage(Map<String,Lead__c> roomToLeadMap){
		// 2017/10/14 部屋の予約別の機能追加　by　zy　BEGIN
		//floatRoomLst = new List<List<RoomInfo>>();
		floatRoomLst = new FloatRowInfo();
		// 2017/10/14 部屋の予約別の機能追加　by　zy　END
		//获取店铺下所有部屋
		List<Room__c> roomLst = new List<Room__c>();
		Map<String,AccountAcount__c> acountMap = new Map<String,AccountAcount__c>();
		//过滤预约set order中已经済み的数据
		Set<String> leadSet = new Set<String>();
		Set<String> acountSet = new Set<String>();
		Map<String , OrderEntryInfo__c> roomOrderMap = new Map<String , OrderEntryInfo__c>();
		Datetime curTime = system.now();
		boolean demoFlag = false;
		// 2017/09/11 印刷リスト機能　by　zy　BEGIN
		/*
		// 日期变更
		if (!CommUtils.isBlank(queryDate)) {
system.debug(logginglevel.info,'queryDate:::' + queryDate);
//system.debug(logginglevel.info,'queryDate:::' + Date.parse(queryDate));
system.debug(logginglevel.info,'CommUtils.stringtoDate(queryDate):::' + CommUtils.objectToDate(queryDate));
			curTime = Datetime.newInstance(CommUtils.objectToDate(queryDate), curTime.time());
		}*/
		// 2017/09/11 印刷リスト機能　by　zy　END
		if (!CommUtils.isBlank(demoDate)) { 
			curTime = Datetime.newInstance(CommUtils.stringtoDate(demoDate), curTime.time());
			demoFlag = true;
		}
		Date curDt = curTime.date();
		// 2017/10/14 部屋の予約別の機能追加　by　zy　BEGIN
		Map<String,List<Id>> roomToLstMap = new Map<String,List<Id>>();
		// 2017/10/14 部屋の予約別の機能追加　by　zy　END
		// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy BEGIN
		Set<String> cookDoneLeadSet = new Set<String>();
		// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy END
		//内部网站时获取当前店铺下所有房间列表并通过房间下的预约数据查到相应的会计数据
		if (isDomainFlag) {
			roomLst = OrderServiceHelp.getRoomLst(oShopCode);
			// 2020/03/31 オーダーエントリー画面を開こうとすると、添付画像のエラーが表示されます。 by zy BEGIN
			// String spcd = UserUtil.CurrentUser.ShopCode__c;
			String spcd = UserUtil.CurrentUserInfo.defaultShopCode;
			// 2020/03/31 オーダーエントリー画面を開こうとすると、添付画像のエラーが表示されます。 by zy END
			curShopName = '';
			//2017/04/20 多店舗機能対応　by　zy BEGIN
			if (oShopCode != null) {
				spcd = oShopCode;
			}
			//2017/07/05 多店舗対応選択リスト　by　zy　BEGIN
			if (!CommUtils.isBlank(oShopCode) && shopCodeLst != null) {
				//ShopInformation__c shop = ShopInfoUtil.getShop(oShopCode);
				for (SelectOption opt : shopCodeLst) {
			         if (opt.getvalue() == oShopCode) {
			             curShopName =  opt.getLabel();
			             break;
			         }
				}
			}
			//2017/07/05 多店舗対応選択リスト　by　zy　END
			//2017/04/20 多店舗機能対応　by　zy END
			curUserInfo = CommUtils.nullToBlank(UserInfo.getLastName()) + ' ' + CommUtils.nullToBlank(UserInfo.getFirstName());
			if (!CommUtils.isBlank(UserUtil.CurrentUser.EmployeeCode__c)) {
				curUserInfo += '(' + UserUtil.CurrentUser.EmployeeCode__c + ')';
			}
			// 2017/09/27 コレクションサイズ 最大サイズを超えエラー修正　by　zy BEGIN
			Integer collectionSize = 1000;
			List<Id> curIds = new List<Id>();
			for (Room__c room : roomLst) {
				// 2017/10/14 部屋の予約別の機能追加　by　zy　BEGIN
				//String roomId = room.id;
				// 2017/10/14 部屋の予約別の機能追加　by　zy　END
				//会計済みのメーセッジ改修　by　zy BEGIN
				if (curIds.size() >= collectionSize ) {
					// 2017/10/14 部屋の予約別の機能追加　by　zy　BEGIN
					//floatRoomLst.add(curIds);
					floatRoomLst.add(new OneRowInfo(curIds));
					// 2017/10/14 部屋の予約別の機能追加　by　zy　END
					curIds = new List<Id>();
				}
				// 2017/10/14 部屋の予約別の機能追加　by　zy　BEGIN
				//curIds.add(roomId);
				curIds.add(room.id);
				// 2017/10/14 部屋の予約別の機能追加　by　zy　END
				//会計済みのメーセッジ改修　by　zy END
			}
			// 2017/10/14 部屋の予約別の機能追加　by　zy　BEGIN
			//if ( !curIds.isEmpty() ) floatRoomLst.add(curIds);
			if ( !curIds.isEmpty() ) floatRoomLst.add(new OneRowInfo(curIds));
			// 2017/10/14 部屋の予約別の機能追加　by　zy　END
			// 2017/09/27 コレクションサイズ 最大サイズを超えエラー修正　by　zy END
			//当日房间中order信息
			// 2017/10/14 部屋の予約別の機能追加　by　zy　BEGIN
			//for (OrderEntryInfo__c orderInfo : OrderServiceHelp.queryOrderEntrys(floatRoomLst,curDt)) {
			// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy BEGIN
			boolean orderFlg = OrderServiceHelp.getCookDoneFlg();
			// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy END
			for (OrderEntryInfo__c orderInfo : OrderServiceHelp.queryOrderEntrys(floatRoomLst.getRoomIds(),curDt)) {
			// 2017/10/14 部屋の予約別の機能追加　by　zy　END	
				//会計中の場合
				if (OrderServiceHelp.ORDER_STATUS_ACCOUNT_ING == orderInfo.OrderStatus__c) {
					// 2017/10/14 部屋の予約別の機能追加　by　zy　BEGIN
					//roomOrderMap.put(orderInfo.RoomRef__c,orderInfo);
					String searchKey = CommUtils.nullToBlank(orderInfo.RoomRef__c) + '_' + CommUtils.nullToBlank(orderInfo.LeadRef__c);
					roomOrderMap.put(searchKey,orderInfo);
					// 2017/10/14 部屋の予約別の機能追加　by　zy　END
					// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy BEGIN
					if (orderFlg && orderInfo.CookDoneFlg__c) cookDoneLeadSet.add(orderInfo.leadRef__c);
					// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy END
				//会計済みの場合	
				} else {
					//オーダーのデータ予約あり
					if (orderInfo.LeadRef__c != null) {
						leadSet.add(orderInfo.LeadRef__c);
					}
					//
					if (orderInfo.AccountRef__c != null) {
						acountSet.add(orderInfo.AccountRef__c);
					}
				}
			}
			//2017/04/20 bug fix by zy BEGIN
			String formatStr = 'yyyy/MM/dd HH:mm:ss';
			String curDtStr = curTime.format(formatStr);
			//2017/04/21 开始日期提前两天 by zy BEGIN
			Date begDate = curDt.addDays(-1);
			//2017/04/21 开始日期提前两天 by zy END
			//2017/04/20 bug fix by zy BEGIN
			Map<String,List<Lead__c>> leadSizeMap = new Map<String,List<Lead__c>>();
			// 2019/10/30 オーダーエントリー画面で、「部屋」から予約一覧を呼び出す際、当日にご予約がないお部屋は前日のご予約が表示されたままになってしまいます。 by zy BEGIN
			List<String> leadQuery = OrderServiceHelp.getLeadSqlWhere();
			List<Lead__c> leadLst = OrderServiceHelp.queryLeadList(curDt,begDate,spcd,leadQuery);
			// 2019/10/30 オーダーエントリー画面で、「部屋」から予約一覧を呼び出す際、当日にご予約がないお部屋は前日のご予約が表示されたままになってしまいます。 by zy END
			for (integer i = 0 ; i < leadLst.size() ; i++) {
				Lead__c upd = leadLst[i];
				// 同じ予約ＩＮＤＥＸ、予約ＩＮＤＥＸＳＵＢ、グループＮＯの場合、同じ予約連泊情報を認識する
				String dtKey =	CommUtils.nullToBlank(upd.LeadIndexRef__c) 
						+ '_' +	CommUtils.nullToBlank(upd.LeadIndexSubId__c) 
						+ '_' +	CommUtils.nullToZero(upd.RoomGroupNo__c);
				if (!leadSizeMap.containsKey(dtKey)){
					leadSizeMap.put(dtKey,new List<Lead__c>{upd});
				} else {
					List<Lead__c> updLeadLst = leadSizeMap.get(dtKey);
					//2017/06/13 checkin部屋表示する　by　zy BEGIN
					//連泊の場合
					if (updLeadLst.size() > 0 ) {
						if (upd.Field298__c != null) {
							upd.field4__c = leadSizeMap.get(dtKey)[updLeadLst.size() - 1].field3__c;
						//未来日はチェックインしないの場合、前日の予約表示する
						} else {
							leadSizeMap.get(dtKey)[updLeadLst.size() - 1].field3__c = upd.field4__c;
						}
					}
					//2017/06/13 checkin部屋表示する　by　zy END
					leadSizeMap.get(dtKey).add(upd);
				}
			}
//2017/06/13 checkin部屋表示する　by　zy BEGIN
			List<Lead__c> chkLeads = new List<Lead__c>();
//2017/06/13 checkin部屋表示する　by　zy END
			// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy BEGIN
			String[] timeArr = Commutils.nullToBlank(curType).split('~');
			datetime startDt = null;
			datetime endDt = null;
			if (timeArr.size() > 1) {
				String startTm = timeArr[0];
				String endTm = timeArr[1];
				startDt = Commutils.convertDatetime(curDt,startTm);
				endDt = Commutils.convertDatetime(curDt,endTm);
			}
			// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy END
			for ( Lead__c lead : leadLst) {
//2017/06/13 checkin部屋表示する　by　zy BEGIN
				// 2019/10/30 オーダーエントリー画面で、「部屋」から予約一覧を呼び出す際、当日にご予約がないお部屋は前日のご予約が表示されたままになってしまいます。 by zy BEGIN
				if (leadQuery != null && !leadQuery.isEmpty()) {
					// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy BEGIN
					if (startDt != null && endDt != null && !processCookTime(lead,startDt,endDt)) continue;
					// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy END
					// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy BEGIN
					if (cookDoneLeadSet.contains(lead.id)) chkLeads.add(lead);
					else 
					// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy END
					if (!roomToLeadMap.containsKey(lead.Rroom__c)) roomToLeadMap.put(lead.Rroom__c,lead);
					else chkLeads.add(lead);
					continue;
				}
				// 2019/10/30 オーダーエントリー画面で、「部屋」から予約一覧を呼び出す際、当日にご予約がないお部屋は前日のご予約が表示されたままになってしまいます。 by zy END
				// 2017/08/17 客户需求未checkin的数据也可以显示出来
				if (lead.Field298__c == null) continue;
//2017/06/13 checkin部屋表示する　by　zy END
//2017/06/15 オーダー済みのデータ by zy BEGIN
				if (leadSet.contains(lead.id)) continue;
//2017/06/15 オーダー済みのデータ by zy END
				//取得中前两天的数据进行过滤
				if (lead.Departure__c.date() <= begDate) continue;
				// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy BEGIN
				if (startDt != null && endDt != null) {
					if (processCookTime(lead,startDt,endDt)) chkLeads.add(lead);
					continue;
				}
				// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy END
				//2017/04/20 bug fix by zy BEGIN
				//是否在时间段内
				if (processLeadTime(lead, curDtStr, formatStr)) {
					//roomIds.add(lead.Rroom__c);		
					// 2017/10/14 部屋の予約別の機能追加　by　zy　BEGIN
					//roomToLeadMap.put(lead.Rroom__c,lead);
					// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy BEGIN
					if (cookDoneLeadSet.contains(lead.id)) chkLeads.add(lead);
					else 
					// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy END
					if (!roomToLeadMap.containsKey(lead.Rroom__c)) roomToLeadMap.put(lead.Rroom__c,lead);
					else chkLeads.add(lead);
					// 2017/10/14 部屋の予約別の機能追加　by　zy　END
//2017/06/13 checkin部屋表示する　by　zy BEGIN
				}  else {
					chkLeads.add(lead);
				}
//2017/06/13 checkin部屋表示する　by　zy END
				//2017/04/20 bug fix by zy END
			}
//2017/06/13 checkin部屋表示する　by　zy BEGIN
			List<Id> leadIds = new List<Id>();
			// アサインなしの部屋の予約
			Map<Id,Lead__c> noAssignLeadMap = new Map<Id,Lead__c>(); 
			//时间段内没有未来时间找预约显示
			for (Lead__c lead : chkLeads) {
				// 2017/10/14 部屋の予約別の機能追加　by　zy　BEGIN
				/*
				if (roomToLeadMap.containsKey(lead.Rroom__c)) {
					//未来日のチュックインのデータを取得する
					Datetime beginTime = Datetime.newInstance(lead.EntryTime__c.date(),CommUtils.stringtoTime(lead.field4__c));
					Datetime endTime = Datetime.newInstance(lead.Departure__c.date(),CommUtils.stringtoTime(lead.field3__c));
					roomToLeadMap.put(lead.id,lead);
					if (!roomToLstMap.containsKey(lead.Rroom__c)) roomToLstMap.put(lead.Rroom__c,new List<Id>());
					roomToLstMap.get(lead.Rroom__c).add(lead.id);
					floatRoomLst.setChildLeadByRoomId(lead.Rroom__c,lead.id);
					
				} else roomToLeadMap.put(lead.Rroom__c,lead);
				*/
				// 当前时间以后的数据才显示
				//if (beginTime.format(formatStr) > curDtStr) {
					//roomIds.add(lead.Rroom__c);		
					
		        //}
		        if (!roomToLeadMap.containsKey(lead.Rroom__c)) noAssignLeadMap.put(lead.Rroom__c,null);
				Lead__c orgLead = null;
				// 未割り当て予約の部屋設定
				if (noAssignLeadMap.containsKey(lead.Rroom__c)) {
					orgLead = noAssignLeadMap.get(lead.Rroom__c);
					// 存在
					// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy BEGIN
					if (!cookDoneLeadSet.contains(lead.id)) {
						noAssignLeadMap.put(lead.Rroom__c,lead);
						roomToLeadMap.put(lead.Rroom__c,lead);
					}
					// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy END
				} else orgLead = lead;
				// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy BEGIN
				//if (orgLead != null) {
				if (orgLead != null || cookDoneLeadSet.contains(lead.id)) {
					floatRoomLst.setChildLeadByRoomId(lead.Rroom__c,lead.id);
					if (!roomToLstMap.containsKey(lead.Rroom__c)) roomToLstMap.put(lead.Rroom__c,new List<Id>());
					roomToLstMap.get(lead.Rroom__c).add(lead.id);
				}
				// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy END
		        roomToLeadMap.put(lead.id,lead);
		        leadIds.add(lead.id);
		        // 2017/10/14 部屋の予約別の機能追加　by　zy　END
			}
//2017/06/13 checkin部屋表示する　by　zy END
			for (Room__c room : roomLst) {
				String roomId = room.id;
				if (roomToLeadMap.containsKey(roomId)) {
					leadIds.add(roomToLeadMap.get(roomId).id);
				}
			}
			acountMap = OrderServiceHelp.getAcounts(leadIds);
		//如果外部链接时房间id不为空
		} else if (!CommUtils.isBlank(roomId)){
			roomLst = OrderServiceHelp.getRoomLst(new set<Id>{roomId});
		}
		Set<Id> typeSet = new Set<Id>();
		//添加所有部屋タイプ
		roomTypeOpts.add(new SelOption('All',''));
		if (isDomainFlag) {
			//部屋タイプリストと部屋リスト作成する
			for (Room__c r : roomLst) {
				Lead__c lead = null;
				AccountAcount__c acc = null;
				OrderEntryInfo__c orderInfo = null;
				if (roomToLeadMap.containsKey(r.id)) lead = roomToLeadMap.get(r.id);
				// 2017/10/14 部屋の予約別の機能追加　by　zy　BEGIN
				String roomLeadId = '';
				if (lead != null && acountMap.containsKey(lead.id)) {
					acc = acountMap.get(lead.id);
					roomLeadId = lead.id;
				}
				String searchKey  = r.id + '_' + CommUtils.nullToBlank(roomLeadId);
				if (roomOrderMap.containsKey(searchKey)) orderInfo = roomOrderMap.get(searchKey);
				// 2017/10/14 部屋の予約別の機能追加　by　zy　END
				if (acc != null && acountSet.contains(acc.id)) acc = null;
				// 2017/06/14 同一房间不同预约，会计数据、订单时间显示异常bug修理 by zy BEGIN
				//if (orderInfo != null && lead != null && orderInfo.LeadRef__c != lead.id) lead = null;
				if (orderInfo != null && lead != null && orderInfo.LeadRef__c != lead.id) orderInfo = null;
				// 2017/06/14 同一房间不同预约，会计数据、订单时间显示异常bug修理 by zy END
				// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy BEGIN
				if (lead != null && cookDoneLeadSet.contains(lead.id)) mainRoomMap.put(r.id,new Roominf(r,null,null,null));
				else mainRoomMap.put(r.id,new Roominf(r,lead,acc,orderInfo));
				// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy END
				if (!typeSet.contains(r.TypeRoomRef__c)){
					typeSet.add(r.TypeRoomRef__c);
					roomTypeOpts.add(new SelOption(r.TypeRoomRef__r.name,r.TypeRoomRef__c));
				}
				// 2017/10/14 部屋の予約別の機能追加　by　zy　BEGIN
				if (roomToLstMap.containsKey(r.id)) {
					for (Id leadId : roomToLstMap.get(r.id)) {
						acc = null;
						lead = null;
						orderInfo = null;
						if (roomToLeadMap.containsKey(leadId)) lead = roomToLeadMap.get(leadId);
						if (lead != null && acountMap.containsKey(lead.id)) acc = acountMap.get(lead.id);
						searchKey = lead.Rroom__c + '_' + lead.id;
						if (roomOrderMap.containsKey(searchKey)) orderInfo = roomOrderMap.get(searchKey);
						Roominf inf = new Roominf(r,lead,acc,orderInfo);
						inf.moreLeadFlag = true;
						mainRoomMap.put(leadId,inf);
					}
				}
				// 2017/10/14 部屋の予約別の機能追加　by　zy　END
				//
			}
				// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy BEGIN
			if (iframeMode) jsonMainRoom = JSON.serialize(mainRoomMap);
				// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy EBD
			//予約データなし、会計ありの部屋処理する
			/*
			for (OrderEntryInfo__c orderInfo : OrderServiceHelp.queryOrderEntrys(floatRoomLst,queryDate)) {
				if (mainRoomMap.containsKey(orderInfo.RoomRef__c)) {
					mainRoomMap.get(orderInfo.RoomRef__c).setOrder(orderInfo);
				}
			}*/
		} else {
			// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy BEGIN
			if (roomToLeadMap.containsKey(roomId) && roomToLeadMap.get(roomId) != null)
				acountMap = OrderServiceHelp.getAcounts(new List<Id>{roomToLeadMap.get(roomId).id});
			// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy END
			//部屋タイプリストと部屋リスト作成する
			for (Room__c r : roomLst) {
				Lead__c lead = null;
				AccountAcount__c acc = null;
				if (roomToLeadMap.containsKey(r.id)) lead = roomToLeadMap.get(r.id);
				if (lead != null && acountMap.containsKey(lead.id)) acc = acountMap.get(lead.id);
				mainRoomMap.put(r.id,new Roominf(r,lead,acc,null));
				// 2017/09/27 コレクションサイズ 最大サイズを超えエラー修正　by　zy BEGIN
				// 2017/10/14 部屋の予約別の機能追加　by　zy　BEGIN
				//floatRoomLst.add(new List<Id>{r.id});
				floatRoomLst.add(new OneRowInfo(new List<Id>{r.id}));
				// 2017/10/14 部屋の予約別の機能追加　by　zy　END
				// 2017/09/27 コレクションサイズ 最大サイズを超えエラー修正　by　zy END
			}
		}
	}
	//2017/05/26 無予約の部屋データ作成機能追加　by zy END
	private void chgRoom(){
		if (!isDomainFlag) {
			loadTodayOrCurRooms(false);
			orgRoomId = '';
		}
		// 没有主房间id的时候清空房间信息
		curRoomJson = '';
//system.debug(logginglevel.info,'roomId:::' + roomId);
		if (!CommUtils.isBlank(roomId) && mainRoomMap.containsKey(roomId)) {
			mainRoomMap.get(roomId).curClass = 'mainRoom';
			//2017/04/20 bug fix by zy BEGIN
			Roominf curRoom = mainRoomMap.get(roomId);
			// 2017/10/14 部屋の予約別の機能追加　by　zy　BEGIN
			// 如果同一房间含有多lead
			if (!CommUtils.isBlank(roomLeadId) && mainRoomMap.containsKey(roomLeadId)) {
				curRoom = mainRoomMap.get(roomLeadId);
			}
			// 2017/10/14 部屋の予約別の機能追加　by　zy　END
			// 2020/02/15 会計の簡易レイアウトを変更 by zy BEGIN
// system.debug(logginglevel.info,'roomLeadId::::' + roomLeadId);
			if (curRoom != null && !CommUtils.isBlank(roomId) && !CommUtils.isBlank(roomLeadId)) 
				curRoom.orderCnt = OrderServiceHelp.getOrderEntryCnt(curRoom.roomId,curRoom.leadId);
			// 2020/02/15 会計の簡易レイアウトを変更 by zy END
			//2017/04/20 bug fix by zy END
			curRoomJson = JSON.serialize(curRoom);
		}
		if (!CommUtils.isBlank(orgRoomId) && mainRoomMap.containsKey(orgRoomId)) {
			mainRoomMap.get(orgRoomId).curClass = '';
//system.debug(logginglevel.info,'mainRoomMap.get(orgRoomId):::' + mainRoomMap.get(orgRoomId));
		}
		orgRoomId = roomId;
	}
	public void changelayout(){
		setCookieInf(COOKIE_LAYOUT_NAME,modeType);
		loadData();
		orgRoomId = '';
	}
	public void changeCurrentRoom () {
		setCookieInf(COOKIE_ROOMID_NAME,roomId);
		chgRoom();
	}
	private static final Integer ROOM_INFO_MAX_SIZE = CommDefine__c.getOrgDefaults().RoomIndicatorInfoMaxLength__c == null ? 4 : (CommDefine__c.getOrgDefaults().RoomIndicatorInfoMaxLength__c.intValue() < 4 ? 4 : CommDefine__c.getOrgDefaults().RoomIndicatorInfoMaxLength__c.intValue());
	public Integer roomDivWidth {get{
		return ROOM_INFO_MAX_SIZE * 20;
	}}
	public class Roominf {
		public Room__c room;
		public String roomNm{get;private set;}
		public String roomId{get;private set;}
		public String curClass{get;private set;}
		public String contactNm{get;private set;}
		public String enterTime{get;private set;}
		public String Floor{get;set;}
		public String area{get;set;}
		public String leadName{get;set;}
		//2017/04/20 機能追加 by zy BEGIN
		public String leadIndex{get;set;}
		public boolean noLeadFlag{get;set;}
		public String errorMesage;
		//2017/05/26 無予約の部屋データ作成機能追加　by zy BEGIN
		public String roomType{get;set;}
		public String typeName{get;set;}
		public String leadId{get;set;}
		public OrderEntryInfo__c sobj;
		public String accId{get;set;}
		public String orderId{get;set;}
		public boolean hadAccFlag{get;set;}
		public String entryTime{get;set;}
		public boolean oneDayFlag{get;set;}
		public String iconType{get;set;}
		//2017/05/26 無予約の部屋データ作成機能追加　by zy END
		//2017/04/20 機能追加 by zy END
		// 2017/10/14 部屋の予約別の機能追加　by　zy　BEGIN
		// 多予約対応
		public boolean moreLeadFlag{get;set;}
		// 2017/10/14 部屋の予約別の機能追加　by　zy　END
		// 2019/12/30 予約の入っていないお部屋のページが開かないようになっているほうが、入力ミスが起きにくく、時間短縮になる、チェックアウト済の部屋はグレーになって、それ以上オーダーエントリーからは追加入力できなくする by zy BEGIN
		public boolean ofg{get;set;} // チェックアウトフラグ
		// 2019/12/30 予約の入っていないお部屋のページが開かないようになっているほうが、入力ミスが起きにくく、時間短縮になる、チェックアウト済の部屋はグレーになって、それ以上オーダーエントリーからは追加入力できなくする by zy END
		// 2020/02/15 会計の簡易レイアウトを変更 by zy BEGIN
		public Integer orderCnt{get;set;}
		// 2020/02/15 会計の簡易レイアウトを変更 by zy END
		public Roominf(Room__c r,Lead__c lead,AccountAcount__c acount,OrderEntryInfo__c info) {
			room = r;
			roomNm = r.name;
			Floor = r.Floor__c;
			area = r.area__c;
			roomId = r.id;
			//2017/05/26 無予約の部屋データ作成機能追加　by zy BEGIN
			roomType = r.TypeRoomRef__c;
			typeName = r.TypeRoomRef__r.name;
			hadAccFlag = false;
			iconType = '';
			//2017/05/26 無予約の部屋データ作成機能追加　by zy END
			noLeadFlag = true;
			entryTime = '';
			oneDayFlag = true;
			// 2017/10/14 部屋の予約別の機能追加　by　zy　BEGIN
			moreLeadFlag = false;
			// 2017/10/14 部屋の予約別の機能追加　by　zy　END
			// 2019/12/30 予約の入っていないお部屋のページが開かないようになっているほうが、入力ミスが起きにくく、時間短縮になる、チェックアウト済の部屋はグレーになって、それ以上オーダーエントリーからは追加入力できなくする by zy BEGIN
			ofg = false;
			// 2019/12/30 予約の入っていないお部屋のページが開かないようになっているほうが、入力ミスが起きにくく、時間短縮になる、チェックアウト済の部屋はグレーになって、それ以上オーダーエントリーからは追加入力できなくする by zy END
			if (lead != null) {
				contactNm = lead.RelContact__r.name;
				enterTime = lead.EntryTime__c.date().format() + ' ' + lead.field4__c;
				entryTime =  lead.field4__c + '〜';
				leadName = lead.name;
				//2017/04/20 機能追加 by zy BEGIN
				leadIndex = lead.LeadIndexRef__c;
				//2017/04/20 機能追加 by zy END
				noLeadFlag = false;
				//2017/05/26 無予約の部屋データ作成機能追加　by zy BEGIN
				leadId = lead.id;
				//2017/05/26 無予約の部屋データ作成機能追加　by zy END
				//2017/06/13 checin数据不显示问题对应，时钟显示的数据改为checkin的数据by zy BEGIN
				//时间没到则显示始终
				//if (lead.field4__c > system.now().format('HH:mm')) 
				//else iconType = 'account';
				iconType = 'account';
				if (lead.StayNightCal__c > 0) oneDayFlag = false;
				// 2019/12/30 予約の入っていないお部屋のページが開かないようになっているほうが、入力ミスが起きにくく、時間短縮になる、チェックアウト済の部屋はグレーになって、それ以上オーダーエントリーからは追加入力できなくする by zy BEGIN
				ofg = lead.Field298__c == CommConst.LEAD_GUEST_ST_CO;
				// 2019/12/30 予約の入っていないお部屋のページが開かないようになっているほうが、入力ミスが起きにくく、時間短縮になる、チェックアウト済の部屋はグレーになって、それ以上オーダーエントリーからは追加入力できなくする by zy END
			}
			if ( acount != null) {
				accId = acount.id;
				hadAccFlag = true;
				iconType = 'account';
			}
			if ( info != null) {
				sobj = info;
				orderId = info.id;
				accId = info.AccountRef__c;
				hadAccFlag = true;
				if (!CommUtils.isBlank(info.OrderTime__c)){
					entryTime = CommUtils.nullToBlank(info.OrderTime__c) + '〜';
				}
				if (CommUtils.isBlank(leadId) && info.LeadRef__c != null) {
					contactNm = info.LeadRef__r.RelContact__r.name;
					leadIndex = info.LeadRef__r.LeadIndexRef__c;
					leadName = info.LeadRef__r.name;
				}
				iconType = 'account';
			}
		}
		/*
		//2017/05/26 無予約の部屋データ作成機能追加　by zy BEGIN
		public void setOrder (OrderEntryInfo__c info) {
			if(OrderServiceHelp.ORDER_STATUS_ACCOUNT_ING == info.OrderStatus__c ){
				sobj = info;
				orderId = info.id;
				//会计信息不同
				accId = info.AccountRef__c;
				leadId = info.leadRef__c;
				hadAccFlag = true;
				if (!CommUtils.isBlank(info.OrderTime__c)){
					entryTime = CommUtils.nullToBlank(info.OrderTime__c) + '〜';
				}
				iconType = 'account';
			//会計済みと予約ありの場合	
			} else if ((!CommUtils.isBlank(leadId) && leadId == info.leadRef__c) || (!CommUtils.isBlank(accId) && info.AccountRef__c == accId)) {
				hadAccFlag = false;
				noLeadFlag = true;
				entryTime = '';
				contactNm = '';
				enterTime = '';
				leadName = '';
				leadIndex = '';
				leadId = '';
				iconType = '';
				accId ='';
			}
			
		}*/
		//2017/05/26 無予約の部屋データ作成機能追加　by zy END
	}
	//2017/04/18 staff側　部屋機能　by　zy END
	/*
	//organization default set
	private ShopInformation__c defaultShopMessage(){
		Organization orgDetails = [SELECT Id, Name, PostalCode, State,City,Street,Phone,Fax  FROM Organization WHERE Id = :UserInfo.getOrganizationId()];
		// 組織情報から設定する
		String PostNo = CommUtils.nullToBlank(orgDetails.PostalCode);
		String shopName = orgDetails.Name;
		String Address = CommUtils.nullToBlank(orgDetails.State) + CommUtils.nullToBlank(orgDetails.City) + CommUtils.nullToBlank(orgDetails.Street);
		String Phone = CommUtils.nullToBlank(orgDetails.Phone);
		return new ShopInformation__c(Phone__c = Phone,Address__c = Address,Name = shopName,Post__c=PostNo);
	}*/
	//英語
	public void changeEnLanguage(){
		currentLanguage = 'en';
		loadData();
	}
	//日本語
	public void changeJpLanguage(){
		currentLanguage = 'ja';
		loadData();
	}
	//loading ip to process message
	public void initFun(){
		//2017/02/13 new Layout by zy BEGIN
		Set<Decimal> roomSet = OrderServiceHelp.getRoomSetByIp(localIp);
		if (roomSet != null){
			/*
			if (deviceMap.containsKey(localIp)) {
				Set<Decimal> roomSet = deviceMap.get(localIp);
			*/
			if (!roomSet.isEmpty()){
				//Decimal roomReq = CommUtils.nullToZero(roomReqStr);
				// 2017/05/31 部屋の店舗別区分　by zy BEGIN
				// 2020/02/28 SITE機能対応　by zy BEGIN
				List<Room__c> roomLst = OrderServiceHelp.getRoomsBySeq(isDomainFlag,oShopCode,roomSet);
				/*
				List<Room__c> roomLst = new List<Room__c>();
				if (isDomainFlag) {
					roomLst = [select id,name from Room__c where seq__c = :roomSet and ShopInfoRef__r.ShopCode__c = :oShopCode];
				} else {
					roomLst = [select id,name from Room__c where seq__c = 13621];
				}
				*/
				// 2020/02/28 SITE機能対応　by zy END
				// 2017/05/31 部屋の店舗別区分　by zy END
				if (roomLst.isEmpty()){
					roomId = '';
//2017/02/22 source整理 by zy BEGIN
					//curRoomName = '';
//2017/02/22 source整理 by zy END
				} else{
					roomId = roomLst[0].id;
//2017/02/22 source整理 by zy BEGIN
					//curRoomName = roomLst[0].name;
//2017/02/22 source整理 by zy END
				}
				//String printName = roomToPrintMap.get(localIp);
	//system.debug(LoggingLevel.info,'roomToPrintMap:::' + roomToPrintMap);
	//system.debug(LoggingLevel.info,'printInfoMap:::' + printInfoMap);
//2017/02/22 source整理 by zy BEGIN
				/*
				curPrintInfo = OrderServiceHelp.getPrintByIp(localIp);
				curPrintInfo.par.telno = shop.Phone__c;
				curPrintInfo.par.address = shop.Address__c;
				curPrintInfo.par.postno = shop.Post__c;
				curPrintInfo.par.company = shop.Name;
				*/
//2017/02/22 source整理 by zy END
				/*
				if (printInfoMap.containsKey(printName) ){
					curPrintInfo = printInfoMap.get(printName);
				} */
			}
		}
		// 2017/09/11 印刷リスト機能　by　zy　BEGIN
		// 初期化
		hadDeviceFlag = false;
		// 2017/09/11 印刷リスト機能　by　zy　END
		//内侧場合
		if ( isDomainFlag ) {
			// 未选择roomid 读取cookie中room信息
			//if (CommUtils.isBlank(roomId)) {
			String cokieRoomId = getCookieInfValue (COOKIE_ROOMID_NAME);
			if (!CommUtils.isBlank(cokieRoomId)) roomId = cokieRoomId;
			// 2017/09/11 印刷リスト機能　by　zy　BEGIN
			OrderServiceHelp.PrintInfo printInfo= OrderServiceHelp.getPrintByIp(localIp,oShopCode,OrderServiceHelp.LayoutType.ORDER);
			hadDeviceFlag = printInfo != null;
			// 2017/09/11 印刷リスト機能　by　zy　END
			//}
			orgRoomId = '';
			//2017/04/20 bug fix by zy BEGIN
	   		mainRoomMap = new Map<Id,Roominf>();
	   		//2017/04/20 bug fix by zy END
			loadTodayOrCurRooms(true);
		}
		chgRoom();
/* //2017/02/22 source整理 by zy BEGIN
		prinUrl = curPrintInfo.prinUrl;
		statusUrl = curPrintInfo.statusUrl;
		//curPrintInfo.printWs + '://' + curPrintInfo.statusUrl + '/status';
		repiceLayout = curPrintInfo.repiceLayout;
		curPno = curPrintInfo.posNo;
//2017/02/22 source整理 by zy END */
		//2017/02/13 new Layout by zy END
		// 2019/02/15 オーダーエントリー画面のボタン表示内容を端末ごとに変更したい by zy BEGIN
		afterInitProds();
		// 2019/02/15 オーダーエントリー画面のボタン表示内容を端末ごとに変更したい by zy END
	}
	//商品リスト取得
	private void loadData(){
		Map<String,AccountMaster__c> itemMaps = new Map<String,AccountMaster__c>();
		// 検索SQL取得
		// 2017/10/24 多印刷メッセージ放出機能追加 by zy BEGIN
		//String queryStr = CommSqlUtils.generateQueryString('AccountMaster__c',new String[]{'(Select AccountMasterRef__c, Price__c, TaxRate__c From PlanProdcutRef__r  where TaxRate__c = 0 or TaxRate__c = null)'});
		// 2020/03/31 会計１０００件以上対応 by zy BEGIN
		// String queryStr = CommSqlUtils.generateQueryString('AccountMaster__c',new String[]{'(Select AccountMasterRef__c, Price__c, TaxRate__c From PlanProdcutRef__r  where TaxRate__c = 0 or TaxRate__c = null)','GPChange__r.Field1__c','DPChange__r.Field1__c','OP__r.OPcode1__c','Field4__r.Field1__c'});
		String queryStr = 'select id,Field3__c,GPChange__r.Field1__c,DPChange__r.Field1__c,Field4__r.Field1__c,OP__r.OPcode1__c,TaxRateCal__c,ServiceRate__c,ProductEnName__c,BigImage__c,Descript__c,Field5__c,TankaIncTaxCal__c,SalesnoneTax__c, (Select AccountMasterRef__c, Price__c, TaxRate__c From PlanProdcutRef__r  where TaxRate__c = 0 or TaxRate__c = null) from AccountMaster__c';
		// 2020/03/31 会計１０００件以上対応 by zy END
		// 2017/10/24 多印刷メッセージ放出機能追加 by zy END
		queryStr += ' Where IsClosed__c != true And ActionType__c != \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_NO) + '\' And Field3__c in :prodCodeSet ' ;
		//if (noPlan) queryStr += ' And ActionType__c != \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_PL) + '\'';
		queryStr += ' order by Field4__c,OP__c, Field3__c ';
		// 検索結果格納
		// 2020/02/28 SITE機能対応　by zy BEGIN
		// for (AccountMaster__c ac : Database.query(queryStr)) {
		for (AccountMaster__c ac : OrderServiceHelp.getAccountMasterByProdSet(queryStr,prodCodeSet)) {
		// 2020/02/28 SITE機能対応　by zy END	
			itemMaps.put(ac.Field3__c, ac);
		}
		exitProdLst = new List<ProductInfo>();
		// 2017/10/24 多印刷メッセージ放出機能追加 by zy BEGIN
		OrderServiceHelp.DeviceFilter deviceFilter = OrderServiceHelp.getDeviceFilter();
//system.debug(logginglevel.info,'currentLanguage::::' + currentLanguage);
		// 2017/10/24 多印刷メッセージ放出機能追加 by zy END
		for (ButtonTab tab : buttonsLstTab) {
			for ( OneRowPros one : tab.rowButtons ){
				for (ProductInfo p : one.products) {
					if (itemMaps.containsKey(p.prodCode)){
						AccountMaster__c acc = itemMaps.get(p.prodCode);
						//2017/05/26 商品の多い印刷設備対応　by zy BEGIN
						p.posName = tab.pntName;
						//2017/05/26 商品の多い印刷設備対応　by zy END
						// 2017/10/24 多印刷メッセージ放出機能追加 by zy BEGIN
						String posNo = '';
						if (deviceFilter != null) posNo = deviceFilter.filter(acc);
						if (!CommUtils.isBlank(posNo)) p.posName = posNo;
						// 2017/10/24 多印刷メッセージ放出機能追加 by zy END
						exitProdLst.add(p);
						p.processed(acc,exitProdLst.size(),tab.label,currentLanguage);
					}
				}
			}
		}
		//default icon
		if (CommUtils.isBlank(LogoIcon)){
			List<Document> sr = [select id,body, name from Document where DeveloperName = 'Jinyalogo'];
			if (!sr.isEmpty()){
				LogoIcon = '/servlet/servlet.FileDownload?file=' +  sr[0].id;
				//CommUtils.nullToBlank(sr[0].body);
			}
		}
		// 各ボタン関連の会計商品情報をJSON化
		oProdMapsJson = JSON.serialize(exitProdLst);
		// 2019/02/15 オーダーエントリー画面のボタン表示内容を端末ごとに変更したい by zy BEGIN
		afterInitProds();
		// 2019/02/15 オーダーエントリー画面のボタン表示内容を端末ごとに変更したい by zy END
		// 2020/06/30 オーダエンドリーでの金額入力 by zy BEGIN
		isPriceInputFlg = OrderServiceHelp.getOrderPriceInputFlg();
		// 2020/06/30 オーダエンドリーでの金額入力 by zy END
	}
	//予約取得
	//2017/01/17 demo mode by zy BEGIN
	private static Lead__c getCurLeadId(Id roomId,long curTimestemp,boolean demoFlag) {
	//2017/01/17 demo mode by zy END
		Lead__c lead = null;
		String error = '';
		Datetime curDt = Datetime.newInstance(curTimestemp); // timeStmp
		String formatStr = 'yyyy/MM/dd HH:mm:ss';
		Date curDtDate = curDt.date();
		String curDtStr = curDt.format(formatStr);
		error += '0' + curTimestemp;
		//system.debug(logginglevel.info,'curTimestemp:::' + curTimestemp);
		//system.debug(logginglevel.info,'curTimestemp:::' + curDt.format('yyyy/MM/dd HH:ss'));
		//2017/01/17 demo mode by zy BEGIN
		//2017/02/13 new layout by zy BEGIN
		//2017/04/12 Security Fix　by　zy BEGIN
		List<Lead__c> leadLst = OrderServiceHelp.queryLeadList(roomId,curDtDate);
		/*
		[select id,Rroom__c,EntryTime__c,Departure__c,field3__c,field4__c,LeadIndexSubId__c,LeadIndexRef__c,RoomGroupNo__c,CreatedDate,Field354__c,Rroom__r.name,RelContact__r.name from Lead__c 
											where DAY_ONLY(convertTimezone(EntryTime__c)) <= : curDtDate  and DAY_ONLY(convertTimezone(Departure__c)) >= : curDtDate  and Rroom__c =:roomId and CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG  
											order by EntryTime__c ];
		*/
		//2017/04/12 Security Fix　by　zy END
		//2017/02/13 new layout by zy END
		//2017/01/17 demo mode by zy END
		if (leadLst.isEmpty()) {
			throw new CommException('ご予約情報を見つからないため、注文失敗になりました！' );
		}
		//system.debug(logginglevel.info,'leadLst:::' + leadLst);
		long difLong = null;
		Id leadId = null;
		Map<String,List<Lead__c>> leadSizeMap = new Map<String,List<Lead__c>>();
		for (integer i = 0 ; i < leadLst.size() ; i++) {
			Lead__c upd = leadLst[i];
			// 同じ予約ＩＮＤＥＸ、予約ＩＮＤＥＸＳＵＢ、グループＮＯの場合、同じ予約連泊情報を認識する
			String dtKey =	CommUtils.nullToBlank(upd.LeadIndexRef__c) 
					+ '_' +	CommUtils.nullToBlank(upd.LeadIndexSubId__c) 
					+ '_' +	CommUtils.nullToZero(upd.RoomGroupNo__c);
			if (!leadSizeMap.containsKey(dtKey)){
				leadSizeMap.put(dtKey,new List<Lead__c>{upd});
			} else {
				List<Lead__c> updLeadLst = leadSizeMap.get(dtKey);
				leadSizeMap.get(dtKey)[updLeadLst.size() - 1].field3__c = upd.field4__c;
				leadSizeMap.get(dtKey).add(upd);
			}
		}
		//2017/01/18 最后作成予約取得 by zy BEGIN
		Lead__c lastLead = null;
		//2017/01/18 最后作成予約取得 by zy END
		//最近时间取得
		for (Lead__c l : leadLst) {
			//Datetime beginTime = Datetime.newInstance(l.EntryTime__c.date(),CommUtils.stringtoTime(l.field4__c));
			//Datetime endTime = Datetime.newInstance(l.Departure__c.date(),CommUtils.stringtoTime(l.field3__c));
//System.debug(logginglevel.info, 'beginTime='+beginTime.format('yyyy/MM/dd HH:ss'));
//System.debug(logginglevel.info, 'endTime='+endTime.format('yyyy/MM/dd HH:ss'));
//System.debug(logginglevel.info, 'curDt='+curDt.format('yyyy/MM/dd HH:ss'));
			//if (beginTime.format(formatStr) <= curDtStr && curDtStr <= endTime.format(formatStr)) {
			if (processLeadTime(l, curDtStr, formatStr)) {
				//2017/01/18 多房间check by zy BEGIN
				if (lead != null && l.LeadIndexSubId__c != lead.LeadIndexSubId__c && l.RoomGroupNo__c != lead.RoomGroupNo__c){
				//2017/01/18 多房间check by zy END
					//2017/01/17 demo mode by zy BEGIN
					if(!demoFlag) throw new CommException('ご予約情報の時間帯が重なるため、注文失敗になりました！');
					//2017/01/17 demo mode by zy END
				}
				//2017/01/17 demo mode by zy BEGIN
				if(!demoFlag) lead = l;
				else {
					// DEMOモードの場合、初期化設定
					// 既存のDEMOの予約は複数存在、かつ該当予約の作成日は最新の場合、該当予約はデモー予約データとして使う
					if (lead == null || l.CreatedDate.format(formatStr) > lead.CreatedDate.format(formatStr)) lead = l;
				}
				//2017/01/17 demo mode by zy END
			}
			//2017/01/18 最后作成予約取得 by zy END
			// Orderの時間範囲外、到着日はDEMOの日付と一致かつ最新の作成日の予約をリンクする
//System.debug(loggingLevel.info, 'demoFlag='+demoFlag);
//System.debug(loggingLevel.info, 'curDt='+curDtDate.format());
//System.debug(loggingLevel.info, 'l.EntryTime__c.date='+l.EntryTime__c.date().format());
			if (demoFlag && curDtDate == l.EntryTime__c.date()) {
				if ( lastLead == null || lastLead.CreatedDate < l.CreatedDate) lastLead = l;
			}
			//2017/01/18 最后作成予約取得 by zy END
		}
//System.debug(loggingLevel.info, 'lastLead='+lastLead);
//System.debug(loggingLevel.info, 'lastLead[1]='+lead);
		//2017/01/18 最后作成予約取得 by zy BEGIN
		// ORDERの時間範囲内は予約情報がなかった場合、到着日はDEMOの日付と一休すると、該当予約の会計にORDERする
		if (demoFlag && lead == null) {
			lead = lastLead;
		}
		//2017/01/18 最后作成予約取得 by zy END
		if (lead == null){
			throw new CommException('ご予約情報を見つからないため、注文失敗になりました！' );
		}
//System.debug(loggingLevel.info, 'lastLead[2]='+lead);
		return lead;
	}
	/**
	*	Order 作成する
	**/
	@remoteAction
	// 2018/02/07 オーダーエントリー画面の英語対応 by zy BEGIN
	public static ProcessResult processOrder(String orderMessage,String roomId,String demoDate,String localIp,String spcd,boolean isEnLanguage){
	//2017/01/10 demo mode by zy BEGIN
	//2017/04/20 多店舗機能対応　by　zy BEGIN
	// public static ProcessResult processOrder(String orderMessage,String roomId,String demoDate,String localIp,String spcd){
	//2017/04/20 多店舗機能対応　by　zy END
	// 2018/02/07 オーダーエントリー画面の英語対応 by zy END
	//public static ProcessResult processOrder(String orderMessage,String roomId){
		// 2020/04/30 会計の簡易レイアウトを変更 by zy BEGIN
		prodInfoMap = new Map<String,ProdInfo>();
		// 2020/04/30 会計の簡易レイアウトを変更 by zy END
		Datetime curDt = system.now();
		//2017/01/17 demo mode by zy BEGIN
		boolean demoflag = false;
		if (!CommUtils.isBlank(demoDate)) { 
			demoflag = true;
			curDt = Datetime.newInstance(CommUtils.stringtoDate(demoDate), curDt.time());
		}
		//2017/01/17 demo mode by zy END
		//2017/01/10 demo mode by zy END
		long curTimestmp = curDt.getTime();
		ProcessResult r = new ProcessResult();
		List<Result> results = new List<Result>();
		// DB操作を行う
		Savepoint sp = Database.setSavepoint();
		Map<String, Object> m = new Map<String, Object>();
		try{
			if (!CommUtils.isBlank(orderMessage)){
				Map<String,String> prodCntMap = new Map<String,String>();
				// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy BEGIN
				Map<String,String> prodPosMap = new Map<String,String>();
				// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy END
				List<String> roomIds = new List<String>();
				for (String productMessage : orderMessage.split(',')){
					String[] prodArr = productMessage.split(':');
					prodCntMap.put(prodArr[0],prodArr[1]);
					roomIds.add(prodArr[0]);
					// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy BEGIN
					if (prodArr.size() > 2)
						prodPosMap.put(prodArr[0],CommUtils.nullTOBlank(prodArr[2]));
					else 
						prodPosMap.put(prodArr[0],'');
					// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy END
				}
				if (CommUtils.isBlank(roomId))
					throw new CommException('無効なディバイスため、注文をできません、スタッフへ連絡してください!');
				//2017/01/17 demo mode by zy BEGIN
				Lead__c lead = getCurLeadId(roomId,curTimestmp,demoflag);
				//2017/01/17 demo mode by zy END
//system.debug(logginglevel.info,'lead:::' + lead);
				r.leadIndexId = lead.LeadIndexRef__c;
				//2017/02/13 new Layout by zy BEGIN
				// 2017/09/25　会計済みの項目
				// 2020/02/28 SITE機能対応　by zy BEGIN
				// List<AccountAcount__c> accLst = [select id,frs__c,TaxRate__c,name,Field53__c from AccountAcount__c where Relreserve__c = :lead.id];
				List<AccountAcount__c> accLst = OrderServiceHelp.getAccountsByLeadId(lead.id);
				// 2020/02/28 SITE機能対応　by zy END
				// 2017/09/25　会計済みの項目
				//2017/02/13 new Layout by zy END
				if (accLst.isEmpty()) {
					throw new CommException('ご予約関連の会計情報を見つからないため、注文失敗になりました！');
				}
				AccountAcount__c curAcc = accLst[0];
				Id accId = curAcc.id;
				Id relAccId = curAcc.frs__c;
				if (!prodCntMap.isEmpty()){
			        //2017/04/20 多店舗機能対応　by　zy BEGIN
			        OrderServiceHelp.setInstance(spcd);
			        //2017/04/20 多店舗機能対応　by　zy END
			        Map<String,Object> resultMap = new Map<String,Object>{'allergie' => CommUtils.nullToBlank(lead.Field354__c),'orderno'=> curAcc.Name,'orderplace'=> lead.Rroom__r.name,'custname' => CommUtils.nullToBlank(lead.RelContact__r.name)};
			        /*
			        // 2017/09/18 印刷フィルター「アレルギー」カスタム設定機能by zy BEGIN
			        Map<Id,Map<String,Object>> customMap = OrderServiceHelp.getAllCustomMap(new List<Id>{lead.id},null);
			        if (customMap != null && !customMap.isEmpty()) { 
			        	if (customMap.containsKey(lead.id)) {
			        		Map<String,Object> curMap = customMap.get(lead.id);
			        		for (String paraName : curMap.keySet()) {
			        			resultMap.put(paraName,CommUtils.nullToBlank(curMap.get(paraName)));
			        		}
			        	}
			        }
			        // 2017/09/18 印刷フィルター「アレルギー」カスタム設定機能by zy END
			        */
//2017/02/22 source整理 by zy BEGIN
					//2017/04/28 empno layout追加　by　zy BEGIN
					OrderServiceHelp.PrintInfo printInfo= OrderServiceHelp.getPrintByIp(localIp,spcd,OrderServiceHelp.LayoutType.ORDER);
					//OrderServiceHelp.PrintInfo printInfo= OrderServiceHelp.getPrintByIp(localIp);
					//2017/04/28 empno layout追加　by　zy END
					//2017/03/02 無効なディバイス対応　by　zy　BEGIN
					if (printInfo == null) {
						throw new CommException('無効なディバイスため、注文をできません、スタッフへ連絡してください!' );
					} 
					//2017/03/02 無効なディバイス対応　by　zy　END
					 // 2017/09/18 印刷フィルター「アレルギー」カスタム設定機能by zy BEGIN
			        Map<Id,Map<String,Object>> customMap = OrderServiceHelp.getAllCustomMap(new List<Id>{lead.id},null,printInfo.headStanFlag);
			        if (customMap != null && !customMap.isEmpty()) { 
			        	if (customMap.containsKey(lead.id)) {
			        		Map<String,Object> curMap = customMap.get(lead.id);
			        		for (String paraName : curMap.keySet()) {
			        			resultMap.put(paraName,CommUtils.nullToBlank(curMap.get(paraName)));
			        		}
			        	}
			        }
			        // 2017/09/18 印刷フィルター「アレルギー」カスタム設定機能by zy END
					List<Tran1__c> tranLst = new List<Tran1__c>();
					Map<Id,List<FoodDetail__c>> planDetailMap = new Map<Id,List<FoodDetail__c>>();
					Map<Id,AccountMaster__c> accountMap = new Map<Id,AccountMaster__c>();
					//2017/02/13 new layout by zy BEGIN
					// 2018/02/07 オーダーエントリー画面の英語対応 by zy BEGIN
					// 2020/02/28 SITE機能対応　by zy BEGIN
					// for ( AccountMaster__c acc : [select id , Name,Field5__c , TaxRateCal__c , ProductEnName__c , ServiceRate__c , PaymentType__c , jmstRef__c, Field3__c, SpecialTax__c,ActionType__c, (Select BreakName__c, AccountMasterRef__c From ProdFoodDetailRef__r order by OrderNo__c) from AccountMaster__c where id =: prodCntMap.keySet()]){
					for ( AccountMaster__c acc : OrderServiceHelp.getAccountMasterByAccSets(prodCntMap.keySet())){
					// 2020/02/28 SITE機能対応　by zy END	
					// 2018/02/07 オーダーエントリー画面の英語対応 by zy END
					//2017/02/13 new layout by zy END	
						//2017/02/13 new layout by zy BEGIN
						for (FoodDetail__c pd : acc.ProdFoodDetailRef__r){
							if (!planDetailMap.containsKey(pd.AccountMasterRef__c))  planDetailMap.put(pd.AccountMasterRef__c,new List<FoodDetail__c>());
							planDetailMap.get(pd.AccountMasterRef__c).add(pd);
						}
						//2017/02/13 new layout by zy END
						if (!accountMap.containsKey(acc.id)) accountMap.put(acc.id,acc);
					}
					// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy BEGIN
					OrderServiceHelp.Device device = OrderServiceHelp.getDeviceMap().get(localIp);
					String deviceNo = '';
					if (device != null) deviceNo = device.posNo;
					// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy END
					for (String accountId : roomIds) {
						if (!accountMap.containsKey(accountId)) continue;
						AccountMaster__c acc = accountMap.get(accountId);
						String qty = prodCntMap.get(acc.id);
//system.debug(logginglevel.info,'acc:::' + acc);
//system.debug(logginglevel.info,'acc.Field5__c:::' + acc.Field5__c);
//system.debug(logginglevel.info,'qty:::' + qty);
						decimal unitPrice = CommUtils.nullToZero(acc.Field5__c);
						//Decimal totalInc = CommUtils.convertPriceToIncTax(acc.Field5__c,CommUtils.nullToZero(acc.TaxRateCal__c)/100,CommUtils.nullToZero(acc.ServiceRate__c)/100,gPointLen) ;
						priceInfo.process(unitPrice, CommUtils.nullToIntZero(qty) , acc.TaxRateCal__c, acc.ServiceRate__c);
						Tran1__c tran = new Tran1__c(
							Field7__c = acc.id // 商品コード
							//2017/05/26 会計商品の商品処理種別不正のエラー修正　by zy BEIGN
							,ActionType__c = acc.ActionType__c	// 商品処理種別
							//2017/05/26 会計商品の商品処理種別不正のエラー修正　by zy END
							,PaymentType__c = acc.PaymentType__c // ;支払種別
							,Field20__c = CommUtils.nullToBlank(unitPrice)	// 単価 ←　預かり金額
							,Field23__c = CommUtils.nullToBlank(priceInfo.priceIncTax)	// 合計金額 ←　預かり金額
							,Field21__c = qty			// 数量１固定
							// 2018/02/07 オーダーエントリー画面の英語対応 by zy BEGIN
							,Field5__c = isEnLanguage && !CommUtils.isBlank(acc.ProductEnName__c) ? acc.ProductEnName__c : acc.Name
							// 2018/02/07 オーダーエントリー画面の英語対応 by zy END
							,TaxRate__c = acc.TaxRateCal__c		// 消費税
							,ServiceRate__c = acc.ServiceRate__c				// サビース料
							,SpecialTax__c = 0					// 特別税
							,UseDate__c = date.today()			// 利用日
							,RelAccount__c = relAccId
							,Field1__c = accId
							,Field6__c = roomId
							,Field9__c = curDt.format('HHmm')
							// 処理種別１
							,Field3__c = '1'
							// 処理種別２
							,Field4__c = '1'
							// 残数量
							,Field22__c = qty
							// POSNo.
							,POSNo__c = CommUtils.getPosNoByComdefine()
							// 消費税　種別(消費税＝０の場合、非課税/)
							,Field27__c = (acc.TaxRateCal__c == 0 ? '2' : '1')
							// 2017/10/30 オーダー区分　by　zy BEGIN
							,OrderTime__c = curDt
							// 2017/10/30 オーダー区分　by　zy END
							// 2017/01/18 設定なし WSQ EDIT BEGIN 
							//,RowNo__c = 999
							// 2017/01/18 設定なし WSQ EDIT END
							// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy BEGIN
							//端末別の番号
							,DeviceNo__c = CommUtils.nullToBlank(deviceNo)
							// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy END
						);
						tranLst.add(tran);
					}
					
					//2017/02/13 new layout by zy BEGIN
					/*
					for (FoodDetail__c pd : [select AccountMasterSubRef__r.name,AccountMasterSubRef__r.ActionType__c, AccountMasterRef__c from FoodDetail__c where AccountMasterRef__c = :prodCntMap.keySet()]) {
						if (!planDetailMap.containsKey(pd.AccountMasterRef__c))  planDetailMap.put(pd.AccountMasterRef__c,new List<FoodDetail__c>());
						planDetailMap.get(pd.AccountMasterRef__c).add(pd);
			        }
			        */
//2017/02/22 source整理 by zy END
					//2017/02/13 new layout by zy END
					if (!tranLst.isEmpty()) {
						// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy BEGIN
						// 元会計明細
						List<Tran1__c> orgTrans = tranLst.clone();
						if (OrderServiceHelp.getTransMergeFlg()) tranLst = refreshOrderInfo(tranLst,prodCntMap.keySet(),accId);
						//insert tranLst;
						// 2020/02/28 SITE機能対応　by zy BEGIN
						// upsert tranLst;
						OrderServiceHelp.upsertTrans(tranLst);
						// 2020/02/28 SITE機能対応　by zy END
						for (integer i = 0 ; i < tranLst.size(); i++) {
							orgTrans[i].id = tranLst[i].id;
							results.add(new Result(orgTrans[i]));
						}
						// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy BEGIN
						tranLst = orgTrans;
						// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy END
						/*
						for ( Tran1__c tran : tranLst) {
							results.add(new Result(tran));
						}*/
						// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy END
						// 2017/09/25　会計済みの項目　by zy BEGIN
						if (CommUtils.isBlank(curAcc.Field53__c)) OrderServiceHelp.updateAccountOver(curAcc.id);
						// 2017/09/25　会計済みの項目　by zy END
						//2017/02/13 new layout by zy BEGIN
						//2017/02/22 source整理 by zy BEGIN
						r.printInfo = OrderServiceHelp.getPrintJson(printInfo,tranLst,false,OrderServiceHelp.LayoutType.ORDER, planDetailMap,curAcc,resultMap);
						//2017/02/22 source整理 by zy END		
						// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy BEGIN
						// Map<String,String> prodPosMap = new Map<String,String>();
						OrderServiceHelp.LayoutType layType = OrderServiceHelp.LayoutType.ORDER;
						r.curTimeStmp = curTimestmp;
						if (!tranLst.isEmpty()) results = makePrintInfos(r,printInfo,tranLst,prodPosMap,curAcc,resultMap,planDetailMap,layType,roomId);
						if (!CommUtils.isBlank(roomId)) OrderServiceHelp.insertOrderInfo(roomId,curAcc.id,curDt,lead.id,lead.Rroom__r.ShopInfoRef__r.Shopcode__c);
						// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy END
						//2017/02/13 new layout by zy END
					}
//2017/02/22 source整理 by zy BEGIN
					r.printUrl = printInfo.prinUrl;
					r.statusUrl = printInfo.statusUrl;
//2017/02/22 source整理 by zy END
// 2017/07/31 会計ID「ログ、履歴」用　バグ改修by zy BEGIN
					r.accId = accId;
// 2017/07/31 会計ID「ログ、履歴」用　バグ改修by zy END
				}
			}
		} catch(exception e) {
			Database.rollback(sp);
			// 2020/03/31 会計ロック機能 by zy BEGIN
			// r.error = e.getmessage();
			r.error = convertValidationMsg(e.getmessage());
			// 2020/03/31 会計ロック機能 by zy END
			// '無効なディバイスため、注文をできません、スタッフへ連絡してください'; 
			system.debug(logginglevel.info,e.getStackTraceString());
		}
		r.curTimeStmp = system.now().getTime();
		r.prodObj = results;
		return r;
	}
	@remoteAction
	/*
	* 会計明細のキャンセル
	*/
	public static String cancelTran(String tranId,String spcd){
		String error = '';
		// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy BEGIN
		RequsetInfo req = (RequsetInfo)JSON.deserialize(spcd, RequsetInfo.class);
		spcd = req.shopCd;
		Integer minusQty = 0;
		String orderId = req.orderId;
		// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy END
		// 2017/09/26 会計明細削除する　by　zy BEGIN
		OrderServiceHelp.setInstance(spcd);
		boolean deleteFlag = OrderServiceHelp.getDeleteFlag();
		// 2017/09/26 会計明細削除する　by　zy END
		// 2020/03/31 会計ロック機能 by zy BEGIN
		// DB操作を行う
		Savepoint sp = Database.setSavepoint();
		// 2020/03/31 会計ロック機能 by zy END
		try{
			// 2019/09/15 Security Check BY zyz BEGIN
			List<String> chkFieldsLst = new List<String>{'field23__c','field21__c','trans__c'};
			Map<String,Schema.SObjectField> mm = Schema.SObjectType.Tran1__c.fields.getMap();
			if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
				return '' ;
			}
			if (!CommSecurityUtils.isDeleteable(Tran1__c.getSObjectType())) {
				return '';
			}
			// 2019/09/15 Security Check BY zyz END
			// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy BEGIN
			// 2020/06/30 オーダエンドリーでの金額入力 by zy BEGIN
			List<Tran1__c> tranLst = [select id,Field21__c,Field23__c,Field7__c,Field7__r.Field5__c,Field7__r.TaxRateCal__c,Field7__r.ServiceRate__c,Field20__c from Tran1__c where id = :tranId];
			// 2020/06/30 オーダエンドリーでの金額入力 by zy END
			// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy END
			if (!tranLst.isEmpty()){
				// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy BEGIN
				Tran1__c tran = tranLst[0];
				if (!CommUtils.isBlank(orderId)) {
					List<OrderEntryInfo__c> orders = [select id,trans__c from OrderEntryInfo__c where id = :orderid];
					if (!orders.isEmpty()){
						OrderEntryInfo__c info = orders[0];
						List<String> trans = info.Trans__c.split(',');
						List<String> newInfos = new List<String>();
						for (String tranInfo : trans) {
							String[] infos = tranInfo.split(':');
							String orderTranId = infos[0];
							if (tranId == orderTranId) {
								if (infos.size() > 1) minusQty = CommUtils.nullToIntZero(infos[1]);
								else if (infos.size() == 1) tranInfo += ':' + tran.Field21__c; 
								tranInfo += ':delete'; 
							}
							newInfos.add(tranInfo);
						}
						info.Trans__c = String.join(newInfos, ',');
						update info;
					}
				}
				if (minusQty > 0) {
					// 会計価格取得
					Decimal qty = CommUtils.nullToIntZero(tran.Field21__c);
					Decimal lastQty = qty - minusQty;
					if (lastQty > 0) {
						tran = changeCntTrans(CommUtils.nullToIntZero(lastQty),tran,tran);
						update tran;
						return error;
					}
				}
				// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy END
				if (deleteFlag) delete tranLst[0];
				else {
					tranLst[0].Field21__c = '0';
					tranLst[0].InvoiceNoShowFlg__c = true;
					tranLst[0].Field23__c = '0';	// 合計金額 ←　預かり金額
					tranLst[0].Field22__c = '0';
					update tranLst[0];
				}
			}
		}catch(Exception e){
			// 2020/03/31 会計ロック機能 by zy BEGIN
			// error = e.getmessage();
			Database.rollback(sp);
			error = convertValidationMsg(e.getmessage());
			// 2020/03/31 会計ロック機能 by zy END
			
		}
		return error;
	}
	@remoteAction
	//2017/01/10 demo mode by zy BEGIN
	public static ProcessResult getBeginStmp(String roomId,String demoDate){
	//public static ProcessResult getBeginStmp(String roomId){
		ProcessResult result = new ProcessResult();
		Datetime curDt = system.now();
		//2017/01/17 demo mode by zy BEGIN
		boolean demoFlag = false;
		if (!CommUtils.isBlank(demoDate)) { 
			curDt = Datetime.newInstance(CommUtils.stringtoDate(demoDate), curDt.time());
			demoFlag = true;
		}
		//2017/01/17 demo mode by zy END
		long nowTime = curDt.getTime();
		//2017/01/10 demo mode by zy END
		try{
			//2017/01/17 demo mode by zy BEGIN
			Lead__c lead = getCurLeadId(roomId,nowTime,demoFlag);
			//2017/01/17 demo mode by zy END
			result.leadIndexId = lead.LeadIndexRef__c;
		}catch(Exception e){
			// 2020/03/31 会計ロック機能 by zy BEGIN
			// result.error = e.getmessage();
			result.error = convertValidationMsg(e.getmessage());
			// 2020/03/31 会計ロック機能 by zy END
		}
		result.curTimeStmp = system.now().getTime();
		//Datetime beginStmp = Datetime.newInstance(lead.EntryTime__c.date(), CommUtils.stringToTime(lead.field4__c));
		//return CommUtils.nullToBlank(beginStmp.getTime());
		return result;
	}
	/*
	private static String encode(String para) {
        return EncodingUtil.urlEncode(para, 'UTF-8');
    }*/
	//2017/02/13 new layout by zy BEGIN
    private Map<String,Set<Decimal>> deviceMap;
    //2017/02/13 new layout by zy END
	/**
	* XML定義情報を取得する
	* onlyLayoutFlg: レイアウトタグ情報のみ取得する （TRUE：LAYOUTのみ）
	*/
	private void readDocumentProperties(Boolean onlyLayoutFlg) {
		tabLst = new List<TabClass>();

		// タブに表示するボタン情報
		buttonsLstTab = new List<ButtonTab>();
		buttonsIconMap = new Map<String, String>();
		//2017/02/13 new layout by zy BEGIN
		autoStemp = OrderServiceHelp.getAutoStamp();
		//
		/*
		deviceMap = new Map<String,Set<Decimal>>();
		// 処理ターゲットのNODEを取得する
		Dom.XmlNode targetNode = CommXmlUtils.encodeParseXmlDoc('OrderProductConfig', inShopCode,new String[]{'<LOGOIMG>','</LOGOIMG>'});
		// 表示するボタン情報を配列に格納する
		List<Dom.XmlNode> buttonTabs = new List<Dom.XmlNode>();
		
		// ボタン定義情報を取得する
		for(Dom.XMLNode xmlNode : targetNode.getChildElements()) {
			// タグ名
			String attributeName = xmlNode.getName();
			
			if(attributeName.equalsIgnoreCase('SHOPCODE')){
				oShopCode = CommUtils.nullToBlank(xmlNode.getText());
				continue;	// 店舗情報のタグ
			}
			// 個別ボタン設定情報を取得、設定する
			if(attributeName.equalsIgnoreCase('BUTTONTAB')){
				buttonTabs.add(xmlNode);
				continue;
			}else if(attributeName.equalsIgnoreCase('PRINTCONFIG')){
				PrintInfo p = new PrintInfo(xmlNode);
				if (CommUtils.isBlank(curPrintInfo.prinUrl)) curPrintInfo = p;
				if (!printInfoMap.containsKey(p.printName))
					printInfoMap.put(p.printName,p);
			}else if(attributeName.equalsIgnoreCase('LOGOIMG')){
				LogoIcon = xmlNode.getText();
			}else if(attributeName.equalsIgnoreCase('CANCELTIMERANGE')){
				autoStemp = CommUtils.nullToIntZero(xmlNode.getText());
			}else if (attributeName.equalsIgnoreCase('DEVICECONFIG')) {
				for ( Dom.XMLNode node : xmlNode.getChildElements()){
					String printName = '';
					String localStr = '';
					String roomNodeStr = '';
					Dom.XMLNode localNode = node.getChildElement('LOCAL',null); 
					Dom.XMLNode roomNode = node.getChildElement('ROOMSEQ',null);
					Dom.XMLNode printNode = node.getChildElement('PRINTER',null);
					//ip地址
					if (localNode != null) localStr = CommUtils.nullToBlank(localNode.getText());
					//房间编号
					if (roomNode != null) roomNodeStr = CommUtils.nullToBlank(roomNode.getText());
					//打印机名
					if (printNode != null) printName = CommUtils.nullToBlank(printNode.getText());
					Set<Decimal> roomSet = new Set<Decimal>();
					system.debug(logginglevel.info,'roomNodeStr:::' + roomNodeStr);
					if (!CommUtils.isBlank(roomNodeStr)) {
						for (String roomSeq : roomNodeStr.split(',')) {
							if(!CommUtils.isBlank(roomSeq)) {
								system.debug(logginglevel.info,'roomNodeStr:::' + roomNodeStr);
								roomSet.add(CommUtils.nullToZero(roomSeq));
							}
						}
						
					}
					deviceMap.put(localStr,roomSet);
					//roomToPrintMap.put(roomNodeStr,printName);
					roomToPrintMap.put(localStr,printName);
				}
			//2017/01/10 demo mode by zy BEGIN
			} else if (attributeName.equalsIgnoreCase('DEMODATE')) {
				demoDate = CommUtils.nullToBlank(xmlNode.getText());
			}
			//2017/01/10 demo mode by zy END
		}
		*/
		
		demoDate = OrderServiceHelp.getDemoDate();
		//2017/02/13 new layout by zy END
		// ボタン単位のチギ情報を取得する
		//List<ButtonTab> tabs = new List<ButtonTab>();
		boolean checkFlag = true;
		// ボタン設定情報を格納する
		//2017/02/13 new layout by zy BEGIN
		for(Dom.XMLNode tabButtonsNode : OrderServiceHelp.getButtonTabs()){
		//2017/02/13 new layout by zy END
			// タブ格納変数情報を初期化する
			ButtonTab oneTab = new ButtonTab();
			List<ProductInfo> products = new List<ProductInfo>();
			// ボタン定義情報を取得する
			for(Dom.XMLNode xmlNode : tabButtonsNode.getChildElements()) {
				String attributeName = xmlNode.getName();
				// 該当グループのタブ名を取得する
				if(attributeName.equalsIgnoreCase('TABLABEL')){
					oneTab.label = CommUtils.nullToBlank(xmlNode.getText());
					//2017/05/26 商品の多い印刷設備対応　by zy BEGIN
					oneTab.pntName = tabButtonsNode.getAttribute('PRINTER', null);
					//2017/05/26 商品の多い印刷設備対応　by zy END
					// 2019/02/15 オーダーエントリー画面のボタン表示内容を端末ごとに変更したい by zy BEGIN
					TabClass tab = new TabClass(oneTab.label,checkFlag);
					String posNo = tabButtonsNode.getAttribute('POSNO',null);
					if (!CommUtils.isBlank(posNo)) tab.posSet.addAll(posNo.split(','));
					tabLst.add(tab);
					//tabLst.add(new TabClass(oneTab.label,checkFlag));
					checkFlag = false;
					// 2019/02/15 オーダーエントリー画面のボタン表示内容を端末ごとに変更したい by zy END
					continue;
				}
				// 2020/02/15 会計商品のリストを多層構造化 by zy BEGIN
				if (attributeName.equalsIgnoreCase('BUTTONSUBTAB')) {
					String groupName = CommUtils.nullToBlank(xmlNode.getAttribute('LABEL',null));
					for (Dom.XMLNode prodNode : xmlNode.getChildElements()) {
						String nodeName = prodNode.getName();
						if (nodeName.equalsIgnoreCase('PRODUCT')) {
							ProductInfo product = processProd(prodNode);
							product.groupName = groupName;
							products.add(product);
						}
					}
				}
				// 2020/02/15 会計商品のリストを多層構造化 by zy END
				if(attributeName.equalsIgnoreCase('PRODUCT')) {
					// 2020/02/15 会計商品のリストを多層構造化 by zy BEGIN
					ProductInfo product = processProd(xmlNode);
					products.add(product);
					/*
					// 新規ボタン情報を取得する
					ProductInfo product = new ProductInfo();
					products.add(product);
					String strIsBlankBtn = CommUtils.nullToBlank(xmlNode.getAttribute('ISBLANK', null));
					product.isBlankBtn = CommUtils.isBlank(strIsBlankBtn) ? false  : Boolean.valueOf(strIsBlankBtn);
					if (product.isBlankBtn) continue;	// 空白ボタンの場合、次の処理を飛ばす
					
					// ボタン定義情報を取得する
					// 2017/10/24 商品XML設定機能追加　by　zy　BEGIN
					Dom.XmlNode btnLabelField = xmlNode.getChildElement('LABEL',null);		// ボタン表示名
					Dom.XmlNode btnNameField = xmlNode.getChildElement('NAME',null);
					// 2017/10/24 商品XML設定機能追加　by　zy　END
					Dom.XmlNode btnProdField = xmlNode.getChildElement('PRODCODE',null);	// ボタン関連の商品コード
					Dom.XmlNode btnIconField = xmlNode.getChildElement('ICONURL',null);		// ボタンに表示する画像のURL
					Dom.XmlNode btnCodeField = xmlNode.getChildElement('CODE',null);		// ボタン関連の商品コード
					// 2017/10/24 商品XML設定機能追加　by　zy　BEGIN
					if (btnNameField != null) {
						product.Name = CommUtils.nullToBlank(btnNameField.getText());
					}
					// 2017/10/24 商品XML設定機能追加　by　zy　END
					if (btnLabelField != null) {
						product.Name = CommUtils.nullToBlank(btnLabelField.getText());
					}
					if (btnProdField != null) {
						product.prodCode = CommUtils.nullToBlank(btnProdField.getText());
						prodCodeSet.add(product.prodCode);
					}
					if (btnCodeField != null) {
						product.prodCode = CommUtils.nullToBlank(btnCodeField.getText());
						prodCodeSet.add(product.prodCode);
					}
					if (btnIconField != null) {
						product.image = CommUtils.nullToBlank(btnIconField.getText());
					}*/
					// 2020/02/15 会計商品のリストを多層構造化 by zy END
				} // ボタン定義情報格納済
			}

			// 該当グループにボタンの場所を一回設定する
			// 可能済のボタン数
			
			Integer btnsCount = 0;
			// 商品コードにより、商品関連情報を格納する
			//OneRowButtons oneRow = null;
			OneRowPros oneRow = null;
			for (ProductInfo produ : products) {
				// ボタンは商品コード単位で、設定情報を格納する
				if(!CommUtils.isBlank(produ.prodCode)) buttonsIconMap.put(produ.prodCode, produ.image);
				// １行の会計商品情報を格納する
				
				if (btnsCount == 0) {
					//oneRow = new OneRowButtons();
					oneRow = new OneRowPros();
					oneTab.addOneRowButtons(oneRow);
				}
				oneRow.addProduct(produ);
				btnsCount++;
			}
			/**/
			buttonsLstTab.add(oneTab);
			
//System.debug(logginglevel.error, 'buttonsLstTab:::'+buttonsLstTab); 
		}
//System.debug(logginglevel.error, 'oProdMapsJson:::'+oProdMapsJson); 
	}
	/*
	public static Map<String, ProductInfo> getMapProductItemByCodes(Set<String> prodCdSet, Boolean noPlan) {
		// 検索SQL取得
		String queryStr = CommSqlUtils.generateQueryString('AccountMaster__c',new String[]{'(Select AccountMasterRef__c, Price__c, TaxRate__c From PlanProdcutRef__r  where TaxRate__c = 0 or TaxRate__c = null)'});
		queryStr += ' Where IsClosed__c != true And ActionType__c != \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_NO) + '\' And Field3__c in :prodCdSet ' ;
		if (noPlan) queryStr += ' And ActionType__c != \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_PL) + '\'';
		queryStr += ' order by Field4__c,OP__c, Field3__c ';
		// 検索結果格納
		Map<String, ProductInfo> itemMaps = new Map<String, ProductInfo>();
		for (AccountMaster__c ac : Database.query(queryStr)) {
			itemMaps.put(ac.Field3__c, new ProductInfo(ac));
		}
		return itemMaps;
	}*/
	public Class TabClass{
		public String tabName{get;set;}
		public String tabDisStr{get;set;}
		public boolean isCurClass{get;set;}
		public TabClass(String name,Boolean disFlag){
			tabName = name;
			isCurClass = false;
			if(disFlag){
				//tabDisStr = 'true';
				isCurClass = true;
			}
			//else tabDisStr = 'none';
			// 2019/02/15 オーダーエントリー画面のボタン表示内容を端末ごとに変更したい by zy BEGIN
			posSet = new Set<String>();
			// 2019/02/15 オーダーエントリー画面のボタン表示内容を端末ごとに変更したい by zy END
		}
		// 2019/02/15 オーダーエントリー画面のボタン表示内容を端末ごとに変更したい by zy BEGIN
		// 表示グループ設定
		public Set<String> posSet;
		// 2019/02/15 オーダーエントリー画面のボタン表示内容を端末ごとに変更したい by zy END
	}
	public class ButtonTab {
		public ButtonTab(){
			//rowButtons = new List<OneRowButtons>(); 
			rowButtons = new List<OneRowPros>();
		}
		public String label	{get;set;}
		//2017/05/26 商品の多い印刷設備対応　by zy BEGIN
		public String pntName;
		//2017/05/26 商品の多い印刷設備対応　by zy END
		//public List<OneRowButtons> rowButtons {get; private set;}
		public List<OneRowPros> rowButtons {get; private set;}
		public void addOneRowButtons(OneRowPros pOneRowButtons) {
			rowButtons.add(pOneRowButtons);
		}
	}
	/*
	* js用商品対象
	*/
	public class ProductInfo {
		public ProductInfo () {
			isBlankBtn = false;
			isNotFound = false;
			// 2020/02/15 会計商品のリストを多層構造化 by zy BEGIN
			groupName = '';
			// 2020/02/15 会計商品のリストを多層構造化 by zy END
		}
		public ProductInfo (AccountMaster__c acc) {
			//id = acc.Id;
			name = acc.Name;
			price = CommUtils.nullToZero(acc.Field5__c);
			image = acc.BigImage__c;
			// 2020/02/15 会計商品のリストを多層構造化 by zy BEGIN
			groupName = '';
			// 2020/02/15 会計商品のリストを多層構造化 by zy END
		}
		// 2018/02/07 オーダーエントリー画面の英語対応 by zy BEGIN
		public void processed(AccountMaster__c acc,Integer size,String tabName,String lang){
		//public void processed(AccountMaster__c acc,Integer size,String tabName){
		// 2018/02/07 オーダーエントリー画面の英語対応 by zy END
			prodId = acc.Id;
			// 2017/10/24 商品XML設定機能追加　by　zy　BEGIN
			// XML商品名・会計商品の商品名 設定
			// 初期化
			if (CommUtils.isBlank(orgName)) orgName = CommUtils.isBlank(name) ? acc.Name : name;
			// 英語対応 
			if ((lang.equals('en')) && !CommUtils.isBlank(acc.ProductEnName__c)) name = acc.ProductEnName__c;
			else name = orgName;
			// 2017/10/24 商品XML設定機能追加　by　zy　END
			// 2020/06/30 オーダエンドリーでの金額入力 by zy BEGIN
			chgPrice = price = CommUtils.nullToZero(acc.Field5__c);
			// 2020/06/30 オーダエンドリーでの金額入力 by zy END
			// 2020/03/31 会計１０００件以上対応 by zy BEGIN
			//priceInfo.process(price, 1 , acc.TaxRateCal__c, acc.ServiceRate__c);
			// priceInc = priceInfo.unitPriceTax;
			priceInc = acc.TankaIncTaxCal__c;
			// 2020/03/31 会計１０００件以上対応 by zy END
			if(CommUtils.isBlank(image) && !CommUtils.isBlank(acc.BigImage__c)){
				image = acc.BigImage__c.subStringAfter('src="');
				image = image.substringBefore('"');
				isSourceFlag = true;
			}
			// default 画像
			if(CommUtils.isBlank(image)) image = '/resource/' + CommConst.APPOTION_NAMESPACE + 'OrderLib/css/images/noImage.jpg';
			infoContent = acc.Descript__c;
			category = tabName;
			// 2020/03/31 会計１０００件以上対応 by zy BEGIN
			// tax = priceInfo.unitPriceIncTax - priceInfo.unitPriceExcTax;
			tax = acc.TankaIncTaxCal__c - acc.SalesnoneTax__c;
			// 2020/03/31 会計１０００件以上対応 by zy END
			// 2020/06/30 オーダエンドリーでの金額入力 by zy BEGIN
			// サービス料
			serv = acc.ServiceRate__c;
			// 税
			taxcal = acc.TaxRateCal__c;
			// 2020/06/30 オーダエンドリーでの金額入力 by zy END
			id = size;
		}
		public Integer id ;
		public String tranId;
		public String prodId;
		public String name 	;
		public Decimal price ;
		public Decimal priceInc;
		public Decimal totalInc;
		public decimal tax;
		public String image ;
		public String category  ;
		public String infoContent  ;
		public String featured ;
		public String prodCode ;
		public Boolean isBlankBtn ;
		public boolean isSourceFlag;
		public Boolean isNotFound ;
		//2017/05/26 商品の多い印刷設備対応　by zy BEGIN
		public String posName;
		//2017/05/26 商品の多い印刷設備対応　by zy END
		// XML商品名・会計商品の商品名
		public String orgName;
		// 2020/02/15 会計商品のリストを多層構造化 by zy BEGIN
		public String groupName;
		// 2020/02/15 会計商品のリストを多層構造化 by zy END
		// 2020/06/30 オーダエンドリーでの金額入力 by zy BEGIN
		public Decimal chgPrice; // 変更前単価
		// サービス料
		public decimal serv;	 
		// 税
		public decimal taxcal;
		// 2020/06/30 オーダエンドリーでの金額入力 by zy END
	}
	/*
	* remoteaction return result
	*/
	public class ProcessResult{
		public List<Result> prodObj;
		String leadIndexId;
		String error;
		//2017/02/13 new layout by zy BEGIN
		// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy BEGIN
		public String printInfo;
		// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy END
		//2017/02/22 source整理 by zy BEGIN
		String printUrl;
		String statusUrl;
		//2017/05/26 商品の多い印刷設備対応　by zy BEGIN
		List<ProcessResult> child;
		//2017/05/26 商品の多い印刷設備対応　by zy END
		//2017/02/22 source整理 by zy END
		//2017/02/13 new layout by zy END
		//2017/05/26 無予約の部屋データ作成機能追加　by zy BEGIN
		String accId;
		//2017/05/26 無予約の部屋データ作成機能追加　by zy END
		long curTimeStmp;
		// 2017/09/11 印刷リスト機能　by　zy　BEGIN
		List<Object> prints;
		OrderServiceHelp.PrintInfo print;
		// 2017/09/11 印刷リスト機能　by　zy　END
		// 2017/10/24 多印刷メッセージ放出機能追加 by zy BEGIN
		Map<String,OrderServiceHelp.PrintInfo> posMap; //POS番号→印刷対応
		// 2017/10/24 多印刷メッセージ放出機能追加 by zy END
		// 2019/03/28 オーダーエントリー改善レシート再出力機能 by zy BEGIN
		List<String> prodIds;	//
		List<String> tranIds;
		// 2020/02/15 会計の簡易レイアウトを変更 by zy BEGIN
		List<String> cooks;
		String roomId;
		String leadId;
		// 2020/02/15 会計の簡易レイアウトを変更 by zy END
		// 2019/03/28 オーダーエントリー改善レシート再出力機能 by zy END
		ProcessResult(){
			error = '';
			leadIndexId = '';
			//2017/02/13 new layout by zy BEGIN
			printInfo = '';
			//2017/02/13 new layout by zy END
			prodObj = new List<Result>();
			//2017/05/26 商品の多い印刷設備対応　by zy BEGIN
			child = new List<ProcessResult>();
			//2017/05/26 商品の多い印刷設備対応　by zy END
		}
	}
	public class Result{
		Integer qty;
		Decimal price;
		Decimal totalInc;
		Decimal totalExc;
		Id prodId;
		String tranId;
		//2017/02/13 new layout by zy BEGIN
		String name;
		//2017/02/13 new layout by zy END
		// 2017/10/24 多印刷メッセージ放出機能追加 by zy BEGIN
		String orderTime;   // オーダー時刻
		String posNo;	  // POS番号
		// 2017/10/30 オーダー区分　by　zy BEGIN
		String orderMinute;
		// 2017/10/30 オーダー区分　by　zy END
		boolean isDelete; // 削除フラグ
		// 2017/10/24 多印刷メッセージ放出機能追加 by zy END
		// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy BEGIN
		String orderId;
		// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy END
		Result(Tran1__c tran){
			qty = CommUtils.nullToIntZero(tran.Field21__c);
			totalInc = CommUtils.nullToZero(tran.Field23__c);
			prodId = tran.Field7__c;
			tranId = tran.id;
			// 2017/10/30 オーダー区分　by　zy BEGIN
			orderMinute = '';
			// 2017/10/30 オーダー区分　by　zy END
		}
	}
	public class OneRowPros {
		public OneRowPros () {
			products = new List<ProductInfo>();
		}
		public List<ProductInfo> products{get; private set;}
		public void addProduct(ProductInfo pro) {
			products.add(pro);
		}
	}
	//2017/04/20 機能追加 by zy BEGIN
	private static boolean processLeadTime(Lead__c lead,String curDtStr,String formatStr){
		// 2019/11/30 エラー修正　by zy BEGIN
		if (CommUtils.isBlank(lead.field4__c)) lead.field4__c = CommConst.DEF_CHECKIN_TIME;
		if (CommUtils.isBlank(lead.field3__c)) lead.field3__c = CommConst.DEF_CHECKOT_TIME;
		// 2019/11/30 エラー修正　by zy END
		Datetime beginTime = Datetime.newInstance(lead.EntryTime__c.date(),CommUtils.stringtoTime(lead.field4__c));
		Datetime endTime = Datetime.newInstance(lead.Departure__c.date(),CommUtils.stringtoTime(lead.field3__c));
		if (beginTime.format(formatStr) <= curDtStr && curDtStr <= endTime.format(formatStr)) {
			return true;
        }
		return false;
	}
	public void refreshRoomLst(){
		//2017/04/20 bug fix by zy BEGIN
   		mainRoomMap = new Map<Id,Roominf>();
   		//2017/04/20 bug fix by zy END
		loadTodayOrCurRooms(true);
		orgRoomId = '';
		chgRoom();
		// 2019/06/30 レイアウトカスタマイズ機能が必要場合、レイアウトをカスタマイズ用VF作成が必要そうです、 by zy BEGIN
		jsonMainRoom = JSON.serialize(mainRoomMap);
		// 2019/06/30 レイアウトカスタマイズ機能が必要場合、レイアウトをカスタマイズ用VF作成が必要そうです、 by zy END
	}
	// 2019/06/30 レイアウトカスタマイズ機能が必要場合、レイアウトをカスタマイズ用VF作成が必要そうです、 by zy BEGIN
	public String jsonFloatRoom{get; set;}
	// 2019/06/30 レイアウトカスタマイズ機能が必要場合、レイアウトをカスタマイズ用VF作成が必要そうです、 by zy END
	public String simpleWidth{get;set;}
	public String fontSize{get;set;}
	//2017/04/20 機能追加 by zy END
	//2017/05/26 無予約の部屋データ作成機能追加　by zy BEGIN
	//部屋タイプリスト
    public List<SelOption> roomTypeOpts{get;set;}
	public String curSequenceInfo{get;set;}
	//交互用内部类
	class RequsetInfo{
		String sequene;
		String accId;
		String leadId;
		String orderId;
		//2017/06/15 機能改修　by　zy　BEGIN
		String roomId;
		//2017/06/15 機能改修　by　zy　END
		List<ProdInfo> prods;
		List<TranInfo> trans;
		String comment;
		// 2017/09/11 印刷リスト機能　by　zy　BEGIN
		// デバイスアドレス
		String localIp;
		// 店舗コード
		String shopCd;
		// 検索日付
		String queryDate;
		//　処理種別
		String processType;
		// 2017/09/11 印刷リスト機能　by　zy　END
		// 2018/02/07 オーダーエントリー画面の英語対応 by zy BEGIN
		String language;
		// 2018/02/07 オーダーエントリー画面の英語対応 by zy END
		// 2019/03/28 オーダーエントリー改善レシート再出力機能 by zy BEGIN
		List<String> orderIds;
		// 会計のみ
		boolean accFlg;
		String orderSort;
		String order;
		String printName;
		// 2019/03/28 オーダーエントリー改善レシート再出力機能 by zy END
		// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy BEGIN
		Integer qty;
		// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy END
	}
	//商品内部类
	class ProdInfo{
		String qty;
		String prodId;
		String pos;
		// 2020/02/15 会計の簡易レイアウトを変更 by zy BEGIN
		String cookRow;
		String cookDesc;
		// 2020/02/15 会計の簡易レイアウトを変更 by zy END
		// 2020/06/30 オーダエンドリーでの金額入力 by zy BEGIN
		decimal price;
		// 2020/06/30 オーダエンドリーでの金額入力 by zy END
	}
	//部屋タイプの選択項目
	class SelOption{
		public String name{get;set;}
		public String id{get;set;}
		SelOption(String typeName, String typeId){
			name = typeName;
			id = typeId;
		}
	}
	//2017/05/26 無予約の部屋データ作成機能追加　by zy BEGIN
	transient public String reqJson{get;set;}
	//订单内部处理
	public void processOrderDomain() {
		//传入字符串
		RequsetInfo req = (RequsetInfo)JSON.deserializeStrict( reqJson, RequsetInfo.class);
		//回传response
		ProcessResult r = new ProcessResult();
		//处理时间
		Datetime curDt = system.now();
		//でもモード
		boolean demoflag = false;
		if (!CommUtils.isBlank(demoDate)) { 
			demoflag = true;
			curDt = Datetime.newInstance(CommUtils.stringtoDate(demoDate), curDt.time());
		}
		long curTimestmp = curDt.getTime();
		List<Result> results = new List<Result>();
		// DB操作を行う
		Savepoint sp = Database.setSavepoint();
		try{
			//会计
			List<AccountAcount__c> accLst = new List<AccountAcount__c>();
			List<String> prodIds = new List<String>();
			Map<String,String> prodCntMap = new Map<String,String>();
			Map<String,String> prodPosMap = new Map<String,String>();
			// 2020/02/15 会計の簡易レイアウトを変更 by zy BEGIN
			prodInfoMap = new Map<String,ProdInfo>();
			// 2020/02/15 会計の簡易レイアウトを変更 by zy END
			//商品リスト作成する
			if (!req.prods.isEmpty()) {
				for (ProdInfo prod : req.prods){
					prodCntMap.put(prod.prodId,prod.qty);
					prodIds.add(prod.prodId);
					prodPosMap.put(prod.prodId,prod.pos);
					// 2020/02/15 会計の簡易レイアウトを変更 by zy BEGIN
					prodInfoMap.put(prod.prodId,prod);
					// 2020/02/15 会計の簡易レイアウトを変更 by zy END
				}
			}
			Lead__c lead = null;
			String leadId = req.leadId;
			//因为xml不能序列化，所以每次需要重新读取xml
			OrderServiceHelp.setInstance(oShopCode);
			// 2020/04/30 現状の仕様ですと部屋付けをしてもあくまで「選択したテーブルの会計」に注文した商品が入力される形となりますが、実際に行いたかったのは「部屋付け先の客室の会計」に注文した商品が入力されるという挙動です。 by zy BEGIN
			boolean isParLeadFlg = false;
			// 2020/04/30 現状の仕様ですと部屋付けをしてもあくまで「選択したテーブルの会計」に注文した商品が入力される形となりますが、実際に行いたかったのは「部屋付け先の客室の会計」に注文した商品が入力されるという挙動です。 by zy END
			//如果没有房间
			if (!CommUtils.isBlank(roomId)) {
				//房间里予約データ
				try{
					if (!CommUtils.isBlank(leadId)) {
						List<Lead__c> leads = OrderServiceHelp.queryLeadList(leadId);
						if (!leads.isEmpty()) lead = leads[0];
						// 2020/04/30 現状の仕様ですと部屋付けをしてもあくまで「選択したテーブルの会計」に注文した商品が入力される形となりますが、実際に行いたかったのは「部屋付け先の客室の会計」に注文した商品が入力されるという挙動です。 by zy BEGIN
						// 機能有効と小部屋の場合
						if (OrderServiceHelp.getOrderItemToMaseterFlg() && lead.ParentLeadId__c != null) {
							leads = OrderServiceHelp.queryLeadList(lead.ParentLeadId__c);
							if (!leads.isEmpty()) {
								lead = leads[0];
								// 6202 bug fix by zy BEGIN
								leadId = lead.id;
								// 6202 bug fix by zy END
								roomId = lead.Rroom__c;
								roomLeadId = lead.id;
								isParLeadFlg = true;
							}
						}
						// 2020/04/30 現状の仕様ですと部屋付けをしてもあくまで「選択したテーブルの会計」に注文した商品が入力される形となりますが、実際に行いたかったのは「部屋付け先の客室の会計」に注文した商品が入力されるという挙動です。 by zy END
					}
				} catch(exception e){
					
				}
				// 2020/04/30 現状の仕様ですと部屋付けをしてもあくまで「選択したテーブルの会計」に注文した商品が入力される形となりますが、実際に行いたかったのは「部屋付け先の客室の会計」に注文した商品が入力されるという挙動です。 by zy BEGIN
				if (!isParLeadFlg && !CommUtils.isBlank(req.accId)) {
				// 2020/04/30 現状の仕様ですと部屋付けをしてもあくまで「選択したテーブルの会計」に注文した商品が入力される形となりますが、実際に行いたかったのは「部屋付け先の客室の会計」に注文した商品が入力されるという挙動です。 by zy END
					// 2017/09/25　会計済みの項目
					accLst = [select id,frs__c,TaxRate__c,name,Field145__c,Field53__c from AccountAcount__c where id = :req.accId];
					// 2017/09/25　会計済みの項目
				}
				if (lead != null){
					r.leadIndexId = lead.LeadIndexRef__c;
					if (accLst.isEmpty()){
						// 2017/01/04 チェックイン済の会計データを直接に削除されるとき、Field53項目を見つからない不具合改修　by　zy　BEGIN
						// accLst = [select id,frs__c,TaxRate__c,name,Field145__c from AccountAcount__c where Relreserve__c = :lead.id];
						accLst = [select id,frs__c,TaxRate__c,name,Field145__c,Field53__c from AccountAcount__c where Relreserve__c = :lead.id];
						// 2017/01/04 チェックイン済の会計データを直接に削除されるとき、Field53項目を見つからない不具合改修　by　zy　END
						if (accLst.isEmpty()) {
							throw new CommException('ご予約関連の会計情報を見つからないため、注文失敗になりました！');
						}
					}
				}
			}
			AccountAcount__c curAcc;
			if (!prodCntMap.isEmpty()){
				String relAccId = '';
				//会計データ
				String accId = '';
				if (!accLst.isEmpty()){
					curAcc = accLst[0];
					relAccId = curAcc.frs__c;
					accId = curAcc.id;
				}
				//2017/05/29 印刷取得する by zy BEGIN
		        //打印信息
		        OrderServiceHelp.LayoutType layType = OrderServiceHelp.LayoutType.ORDER;
				// IP無効確認
				OrderServiceHelp.PrintInfo printInfo = initAndGetPrintInfo(req,layType);
				if (!CommUtils.isBlank(req.sequene)) {
					if ( req.sequene == '2') {
						layType = OrderServiceHelp.LayoutType.ORDER;
					} else if ( req.sequene == '1') {
						layType = OrderServiceHelp.LayoutType.ACCOUNT;
					}
				}
				//2017/05/29 印刷取得する by zy END
				// 2018/03/07 Security Check BEGIN
				// 2019/09/15 Security Check BY zyz BEGIN
				List<String> chkFieldsLst = new List<String>{'relaccount__c','field6__c','field1__c','field23__c','field21__c'};
				// 2019/09/15 Security Check BY zyz END
				Map<String,Schema.SObjectField> mm = Schema.SObjectType.Tran1__c.fields.getMap();
				// 2019/09/15 Security Check BY zyz BEGIN
				if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
				// 2019/09/15 Security Check BY zyz END
					return ;
				}
				// 2018/03/07 Security Check END
				//2017/05/29 選択するの商品明細->会計明細対応 by zy BEGIN
				List<Tran1__c> tranLst = new List<Tran1__c>();
				Map<Id,List<FoodDetail__c>> planDetailMap = new Map<Id,List<FoodDetail__c>>();
				// 2017/10/24 多印刷メッセージ放出機能追加 by zy BEGIN
				/*
				tranLst = prodsToTrans(prodCntMap,prodIds,relAccId,accId,curDt,printInfo.posNo,planDetailMap);
				*/
				// IP指定設備情報取得
				OrderServiceHelp.Device device = OrderServiceHelp.getDeviceMap().get(localIp);
				// 該当Ipの設備POS取得
				String deviceNo = '';
				if (device != null) deviceNo = device.posNo;
				tranLst = prodsToTrans(prodCntMap,prodIds,relAccId,accId,curDt,printInfo.posNo,planDetailMap,deviceNo);
				// 2017/10/24 多印刷メッセージ放出機能追加 by zy END
				//2017/05/29 選択するの商品明細->会計明細対応 by zy END
				List<Tran1__c> tran1Lst = new List<Tran1__c> ();
				//不存在会计id
				if (curAcc == null) {
					//ApexPages.StandardController contrl = new ApexPages.StandardController(new AccountAcount__c());
					// 2017/07/10 ログ出力機能を追加する BEGIN
					BillInput_Ctrl bill = OrderServiceHelp.upsertBillData(curDt.date(),tranLst,roomId,oShopCode,localIp);
					//BillInput_Ctrl bill = OrderServiceHelp.upsertBillData(curDt.date(),tranLst,roomId,oShopCode);
					// 2017/07/10 ログ出力機能を追加する END
					for (integer i = 0 ; i < bill.oTranSobjLst.size() ; i++ ) {
						tran1Lst.add(bill.oTranSobjLst[i].sobj);
					}
					curAcc = bill.oAcountSobj;
					// 2019/03/28 オーダーエントリー改善レシート再出力機能 by zy BEGIN
					curAcc.ShopCode__c = oShopCode;
					// 2019/03/28 オーダーエントリー改善レシート再出力機能 by zy END
//system.debug(logginglevel.info,'bill.oAcountSobj:::' + bill.oAcountSobj);
				} else {
					// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy BEGIN
					// insert tranLst;
					//tran1Lst = tranLst;
					// 元会計明細
					List<Tran1__c> orgTrans = tranLst.clone();
					// 保存用明細、会計明細のオーダー情報内容刷新
					if (OrderServiceHelp.getTransMergeFlg()) tranLst = refreshOrderInfo(tranLst,new Set<String>(prodIds),accId);
					// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy END
					// 既存会計、新規明細あり
					upsert tranLst;
					for (integer i = 0 ; i < tranLst.size(); i++) {
						orgTrans[i].id = tranLst[i].id;
					}
					// 印刷内容保持、数量変更bug fix
					tran1Lst = orgTrans;
					// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy END
					// 2017/09/25　会計済みの項目　by zy BEGIN
					if (CommUtils.isBlank(curAcc.Field53__c)) OrderServiceHelp.updateAccountOver(curAcc.id);
					// 2017/09/25　会計済みの項目　by zy END
				}
				// 該当予約の注文状態設定
				if (!CommUtils.isBlank(roomId)) OrderServiceHelp.insertOrderInfo(roomId,curAcc.id,curDt,leadId,oShopCode);
//2017/02/22 source整理 by zy END
				//2017/02/13 new layout by zy END
				//后补信息
		        Map<String,Object> resultMap = new Map<String,Object>();
		        if (lead != null) {
		        	resultMap = new Map<String,Object>{'allergie' => CommUtils.nullToBlank(lead.Field354__c),'orderno'=> curAcc.Name,'orderplace'=> lead.Rroom__r.name,'custname' => CommUtils.nullToBlank(lead.RelContact__r.name)};
		        	 // 2017/09/18 印刷フィルター「アレルギー」カスタム設定機能by zy BEGIN
			        Map<Id,Map<String,Object>> customMap = OrderServiceHelp.getAllCustomMap(new List<Id>{lead.id},null,printInfo.headStanFlag);
// system.debug(logginglevel.info,'customMap:::' + customMap);
			        if (customMap != null && !customMap.isEmpty()) { 
			        	if (customMap.containsKey(lead.id)) {
			        		Map<String,Object> curMap = customMap.get(lead.id);
			        		for (String paraName : curMap.keySet()) {
			        			resultMap.put(paraName,CommUtils.nullToBlank(curMap.get(paraName)));
			        		}
			        	}
			        }
			        // 2017/09/18 印刷フィルター「アレルギー」カスタム設定機能by zy END
		        }
				// 2019/03/28 オーダーエントリー改善レシート再出力機能 by zy BEG
				r.curTimeStmp = curTimestmp;
				// 2020/02/15 会計の簡易レイアウトを変更 by zy BEGIN
				r.leadId = leadId;
				// 2020/02/15 会計の簡易レイアウトを変更 by zy END
				if (!tran1Lst.isEmpty()) results = makePrintInfos(r,printInfo,tran1Lst,prodPosMap,curAcc,resultMap,planDetailMap,layType,roomId);
				// 2019/03/28 オーダーエントリー改善レシート再出力機能 by zy END
			}
			// 2019/05/31 JINYABUG-1746 bug fix by zy BEGIN
			if (curAcc != null) r.accId = curAcc.id;
			// 2019/05/31 JINYABUG-1746 bug fix by zy END
		} catch(exception e) {
			Database.rollback(sp);
			// 2020/03/31 会計ロック機能 by zy BEGIN
			// r.error = e.getmessage();
			r.error = convertValidationMsg(e.getmessage());
			// 2020/03/31 会計ロック機能 by zy END
			// '無効なディバイスため、注文をできません、スタッフへ連絡してください'; 
//system.debug(logginglevel.info,e.getStackTraceString());
		}
		r.curTimeStmp = system.now().getTime();
		r.prodObj = results;
		reqJson = JSON.serialize(r);
		//return r;
		if (CommUtils.isBlank(roomId)) {
			orgRoomId = roomId;
			setCookieInf(COOKIE_ROOMID_NAME,roomId);
		}
		//if (!CommUtils.isBlank(roomId))
		refreshRoomLst();
			
			
		//}
	}
	//印刷設備の初期化
	private OrderServiceHelp.PrintInfo initAndGetPrintInfo(RequsetInfo req,OrderServiceHelp.LayoutType layType){
        //打印信息
		OrderServiceHelp.PrintInfo printInfo = null;
		printInfo = OrderServiceHelp.getPrintByIp(localIp,oShopCode,layType);
		//2017/03/02 無効なディバイス対応　by　zy　BEGIN
		if (printInfo == null) {
			throw new CommException('無効なディバイスため、注文をできません、スタッフへ連絡してください!' );//localIp + 
		} 
		return printInfo;
	}
	/**
	*　商品替え会計明細
	**/
	// 2017/10/24 多印刷メッセージ放出機能追加 by zy BEGIN
	//private List<Tran1__c> prodsToTrans(Map<String,String> prodCntMap,List<String> prodIds,String relAccId,String accId,Datetime curDt,String posNo,Map<Id,List<FoodDetail__c>> planDetailMap){
	private List<Tran1__c> prodsToTrans(Map<String,String> prodCntMap,List<String> prodIds,String relAccId,String accId,Datetime curDt,String posNo,Map<Id,List<FoodDetail__c>> planDetailMap,String deviceNo){
	// 2017/10/24 多印刷メッセージ放出機能追加 by zy END	
		List<Tran1__c> tranLst = new List<Tran1__c>();
		Map<Id,AccountMaster__c> accountMap = new Map<Id,AccountMaster__c>();
		//2017/02/13 new layout by zy BEGIN
		// 2018/02/07 オーダーエントリー画面の英語対応 by zy BEGIN
		for ( AccountMaster__c acc : [select id , Name, ProductEnName__c, Field5__c , TaxRateCal__c , ServiceRate__c , PaymentType__c , jmstRef__c, Field3__c, SpecialTax__c,ActionType__c, (Select BreakName__c, AccountMasterRef__c From ProdFoodDetailRef__r order by OrderNo__c) from AccountMaster__c where id =: prodCntMap.keySet()]){
		// 2018/02/07 オーダーエントリー画面の英語対応 by zy END
		//2017/02/13 new layout by zy END	
			//2017/02/13 new layout by zy BEGIN
			for (FoodDetail__c pd : acc.ProdFoodDetailRef__r){
				if (!planDetailMap.containsKey(pd.AccountMasterRef__c))  planDetailMap.put(pd.AccountMasterRef__c,new List<FoodDetail__c>());
				planDetailMap.get(pd.AccountMasterRef__c).add(pd);
			}
			//2017/02/13 new layout by zy END
			if (!accountMap.containsKey(acc.id)) accountMap.put(acc.id,acc);
		}
		for (String accountId : prodIds) {
			if (!accountMap.containsKey(accountId)) continue;
			AccountMaster__c acc = accountMap.get(accountId);
			String qty = prodCntMap.get(acc.id);
			decimal unitPrice = CommUtils.nullToZero(acc.Field5__c);
			// 2020/06/30 オーダエンドリーでの金額入力 by zy BEGIN
			// 変更の商品単価の取得
			if (prodInfoMap.containskey(acc.id)) {
				ProdInfo prod = prodInfoMap.get(acc.id);
				unitPrice = prod.price;
			}
			// 2020/06/30 オーダエンドリーでの金額入力 by zy END
			//Decimal totalInc = CommUtils.convertPriceToIncTax(acc.Field5__c,CommUtils.nullToZero(acc.TaxRateCal__c)/100,CommUtils.nullToZero(acc.ServiceRate__c)/100,gPointLen) ;
			priceInfo.process(unitPrice, CommUtils.nullToIntZero(qty) , acc.TaxRateCal__c, acc.ServiceRate__c);
			Tran1__c tran = new Tran1__c(
				Field7__c = acc.id // 商品コード
				,ActionType__c = acc.ActionType__c	// 商品処理種別
				,PaymentType__c = acc.PaymentType__c // ;支払種別
				,Field20__c = CommUtils.nullToBlank(unitPrice)	// 単価 ←　預かり金額
				,Field23__c = CommUtils.nullToBlank(priceInfo.priceIncTax)	// 合計金額 ←　預かり金額
				,Field21__c = qty			// 数量１固定
				// 2018/02/07 オーダーエントリー画面の英語対応 by zy BEGIN
				,Field5__c = currentLanguage.equals('en') && !CommUtils.isBlank(acc.ProductEnName__c) ? acc.ProductEnName__c : acc.Name
				// 2018/02/07 オーダーエントリー画面の英語対応 by zy END
				,TaxRate__c = acc.TaxRateCal__c		// 消費税
				,ServiceRate__c = acc.ServiceRate__c				// サビース料
				,SpecialTax__c = 0					// 特別税
				,UseDate__c = date.today()			// 利用日
				,Field9__c = curDt.format('HHmm')
				// 処理種別１
				,Field3__c = '1'
				// 処理種別２
				,Field4__c = '1'
				// 残数量
				,Field22__c = qty
				// POSNo.
				,POSNo__c = posNo
				// 消費税　種別(消費税＝０の場合、非課税/)
				,Field27__c = (acc.TaxRateCal__c == 0 ? '2' : '1')
				// 2017/01/18 設定なし WSQ EDIT BEGIN 
				//,RowNo__c = 999
				// 2017/01/18 設定なし WSQ EDIT END
				// 2017/10/24 端末履歴共用機能追加 by zy BEGIN
				//端末別の番号
				,DeviceNo__c = CommUtils.nullToBlank(deviceNo)
				// 2017/10/30 オーダー区分　by　zy BEGIN
				,OrderTime__c = curDt
				// 2017/10/30 オーダー区分　by　zy END
				// 2017/10/24 端末履歴共用機能追加 by zy END
			);
			if (!CommUtils.isBlank(relAccId)) tran.RelAccount__c = relAccId;
			if (!CommUtils.isBlank(accId)) tran.Field1__c = accId;
			//2017/05/29 部屋テーブルＮｏ．の追加する　by zy BEGIN
			if (!CommUtils.isBlank(roomId)) tran.Field6__c = roomId;
			//2017/05/29 部屋テーブルＮｏ．の追加する　by zy end
			tranLst.add(tran);
		}
		return tranLst;
	}
	//取得印刷メーセッジ
	// 2017/09/11 印刷リスト機能　by　zy　BEGIN
	private static List<Result> makePrintInfos(ProcessResult r , OrderServiceHelp.PrintInfo printInfo , List<Tran1__c> tran1Lst,Map<String,String> prodPosMap,
	// 2017/09/11 印刷リスト機能　by　zy　END
									AccountAcount__c curAcc,Map<String,Object> resultMap,Map<Id,List<FoodDetail__c>> planDetailMap,
										// 2019/03/28 オーダーエントリー改善レシート再出力機能 by zy BEGIN
										OrderServiceHelp.LayoutType layType
										,String roomId
										){
										// 2019/03/28 オーダーエントリー改善レシート再出力機能 by zy END
		List<Result> results = new List<Result>();
		// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けない by zy BEGIN
		long orderTime = r.curTimeStmp;
		// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けない by zy END
		//多印刷任務判定フラグ
		boolean morePrintFlag = false;
		Map<String,List<Tran1__c>> posInfoMap = new Map<String,List<Tran1__c>>();
		for ( Tran1__c tran : tran1Lst) {
			if(prodPosMap.containsKey(tran.Field7__c)){
				String posName = prodPosMap.get(tran.Field7__c);
				if (!CommUtils.isBlank(posName)) morePrintFlag = true;
				else posName = printInfo.printName;
				if (!posInfoMap.containsKey(posName)) posInfoMap.put(posName,new List<Tran1__c>());
				posInfoMap.get(posName).add(tran);
			}
			results.add(new Result(tran));
		}
		// 2017/10/24 多印刷メッセージ放出機能追加 by zy BEGIN
		OrderServiceHelp.PrintInfo info = null;
		// 2017/10/24 多印刷メッセージ放出機能追加 by zy END
		if (morePrintFlag){
			for (String posName :posInfoMap.keySet()) {
				// 2017/10/24 多印刷メッセージ放出機能追加 by zy BEGIN
				/*
				OrderServiceHelp.PrintInfo info = null;
				*/
				// 2017/10/24 多印刷メッセージ放出機能追加 by zy END
				if (CommUtils.isBlank(posName)) info = printInfo;
				else info = OrderServiceHelp.getPrintByPosName(posName);
				if (info != null){
					// 用ip默认posno設定
					info.posno = printInfo.posno;
					if (posInfoMap.containsKey(posName)) {
						ProcessResult res = new ProcessResult();
						res.printUrl = info.prinUrl;
						res.statusUrl = info.statusUrl;
						res.printInfo = OrderServiceHelp.getPrintJson(info,posInfoMap.get(posName),false,layType, planDetailMap,curAcc,resultMap);
						// 2019/03/28 オーダーエントリー改善レシート再出力機能 by zy BEGIN
						res.curTimeStmp = r.curTimeStmp;
						convertTranProds(posInfoMap.get(posName),res);
						res.print = info;
						// 2019/03/28 オーダーエントリー改善レシート再出力機能 by zy END
						// 2020/02/15 会計の簡易レイアウトを変更 by zy BEGIN
						res.leadId = r.leadId;
						// 2020/02/15 会計の簡易レイアウトを変更 by zy END
						r.child.add(res);
					} else {
						r.error = Label.MSG_060_0053;
					}
				}
			}
			// 2019/03/28 オーダーエントリー改善レシート再出力機能 by zy BEGIN
			// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けない by zy BEGIN
			// insertPrintInfo(r.child,curAcc.id,roomId);
			insertPrintInfo(r.child,curAcc.id,roomId,orderTime);
			// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けない by zy END
			// 2019/03/28 オーダーエントリー改善レシート再出力機能 by zy END
		} else {
//2017/02/13 new layout by zy BEGIN
//2017/02/22 source整理 by zy BEGIN
			r.printInfo = OrderServiceHelp.getPrintJson(printInfo,tran1Lst,false,layType, planDetailMap,curAcc,resultMap);
//2017/02/22 source整理 by zy END
//2017/02/13 new layout by zy END
			// 2019/03/28 オーダーエントリー改善レシート再出力機能 by zy BEGIN
			convertTranProds(tran1Lst,r);
			// 2019/03/28 オーダーエントリー改善レシート再出力機能 by zy END
		}
//2017/02/22 source整理 by zy BEGIN
		r.printUrl = printInfo.prinUrl;
		r.statusUrl = printInfo.statusUrl;
		// 2019/03/28 オーダーエントリー改善レシート再出力機能 by zy BEGIN
		r.print = printInfo;
		// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けない by zy BEGIN
		// if (!morePrintFlag) insertPrintInfo(new List<ProcessResult>{r},curAcc.id,roomId);
		if (!morePrintFlag) insertPrintInfo(new List<ProcessResult>{r},curAcc.id,roomId,orderTime);
		// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けない by zy END
		// 2019/03/28 オーダーエントリー改善レシート再出力機能 by zy END
		return results;
	}
	//会計済みのボタンを押す
	public void accountDomain(){
		//传入字符串
		// 機能改修　by　zy　BEGIN
		//RequsetInfo req = (RequsetInfo)JSON.deserializeStrict( reqJson, RequsetInfo.class);
		List<RequsetInfo> reqs = (List<RequsetInfo>)JSON.deserializeStrict( reqJson, List<RequsetInfo>.class);
		List<String> orderIds = new List<String>();
		List<OrderEntryInfo__c> orderInfos = new List<OrderEntryInfo__c>();
		//处理时间
		Datetime curDt = system.now();
		//でもモード
		boolean demoflag = false;
		if (!CommUtils.isBlank(demoDate)) { 
			demoflag = true;
			curDt = Datetime.newInstance(CommUtils.stringtoDate(demoDate), curDt.time());
		}
		Date curDate = curDt.date();
		for (RequsetInfo req : reqs) {
			if (CommUtils.isBlank(req.orderId)) {
				orderInfos.add(new OrderEntryInfo__c(OrderStatus__c = OrderServiceHelp.ORDER_STATUS_ACCOUNT_END, SearchDate__c = curDate, 
													RoomRef__c = req.roomId,
													AccountRef__c = req.accId,LeadRef__c = req.leadId));
			} else {
				orderIds.add(req.orderId);
			}
			
		}
		if (!orderIds.isEmpty()){
			OrderServiceHelp.endOrderInfo(orderIds);
		}
		if (!orderInfos.isEmpty()) {
//system.debug(logginglevel.info,'orderInfos:::' + orderInfos);
			OrderServiceHelp.insertOrderInfos(orderInfos,oShopCode);
		}
		// 機能改修　by　zy　END
		refreshRoomLst();
	}
	//2017/05/26 無予約の部屋データ作成機能追加　by zy END
	class TranInfo {
		String id;
		String name;
		String qty;
		String img;
		String price;
		String prodId;
		String status;
		public TranInfo(Tran1__c t){
			id = t.Id;
			status = '';
			name = t.Field5__c;
			qty = t.Field21__c;
			img = '';
			price = t.Field23__c;
			prodId = t.Field7__c;
			/*
			if (t.OrderStatus__c) {
				status = 'end';
			}*/
		}
	}
	//2017/05/27 会計画面追加 by zy END
	//2017/07/05 多店舗対応選択リスト　by　zy　BEGIN
	public void chgShopCodeFun(){
		curRoomJson = '';
		curUserInfo = '';
		orgRoomId = '';
		roomId = '';
		//cookie储存
		setCookieInf(COOKIE_SHOPCODE,oShopCode);
		//切换店铺更新 去掉cookie
		setCookieInf(COOKIE_ROOMID_NAME,'');
		//店舗変更
		OrderServiceHelp.setInstance(oShopCode);
		// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy BEGIN
		initLocAndLayout();
		// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy END
		prodCodeSet = new Set<String>();
		readDocumentProperties(false);
		loadData();
		//initFun();
	}
	//2017/07/05 多店舗対応選択リスト　by　zy　END
	// 2017/07/26 4）ログ情報はDBに記載する by zy BEGIN
	@remoteAction
	public static void savePrintLodToDb(String action){
		// 2017/09/11 印刷リスト機能　by　zy　BEGIN
		String curLog = system.now().format('yyyy-MM-dd HH:mm:ss SSS') + '*************オーダー印刷BEGIN******************\n';
		// 2017/09/11 印刷リスト機能　by　zy　END
		User u = UserUtil.CurrentUser;
		curLog += 'ユーザ：' + u.name + '（' + u.id +'）\n';
		curLog += action + '\n';
		// 2017/09/11 印刷リスト機能　by　zy　BEGIN
		curLog += system.now().format('yyyy-MM-dd HH:mm:ss SSS') + '*************オーダー印刷END  ******************\n';
		// 2017/09/11 印刷リスト機能　by　zy　END
		CommLogUtils.saveLogToDb(curLog,CommLogUtils.LogType.POS);
	}
	// 2017/07/26 4）ログ情報はDBに記載する by zy END
	// 2017/09/11 印刷リスト機能　by　zy　BEGIN
	public String queryDate{get;set;} // 選択日付
   	// 印刷設備「あり」と「なし」フラグ
    public boolean hadDeviceFlag{get;set;}
	@remoteaction
	public static ProcessResult getOneDayCook(String reqJson){
		//传入字符串
		RequsetInfo req = (RequsetInfo)JSON.deserializeStrict( reqJson, RequsetInfo.class);
		String spcd = req.shopCd;
		String orderId = req.orderId;
		String localIp = req.localIp;
		String queryDate = req.queryDate;
		String processType = req.processType;
		Date queryDt = CommUtils.stringtoDate(queryDate);
		// オーダーエンドリメッセージ設定
		OrderServiceHelp.setInstance(spcd);
		OrderServiceHelp.PrintInfo printInfo= OrderServiceHelp.getPrintByIp(localIp,spcd,OrderServiceHelp.LayoutType.ORDER);
		//回传response
		ProcessResult r = new ProcessResult();
		// 获取配置打印信息
		if (printInfo != null) {
			List<Object> res = new List<Object>();
			K_ScheduleCookingHelper bat = new K_ScheduleCookingHelper(queryDt,spcd);
			// 2018/02/07 オーダーエントリー画面の英語対応 by zy BEGIN
			bat.isEnLanguage = req.language == 'en';
			// 2018/02/07 オーダーエントリー画面の英語対応 by zy END
			if (processType == 'mitumori') {
				res = bat.queryEstLead(printInfo);
			} else {
				res = bat.queryFoodInfo(printInfo);
			}
			// 2017/10/24 多印刷メッセージ放出機能追加 by zy BEGIN
			Map<String,OrderServiceHelp.PrintInfo> connectMap = new Map<String,OrderServiceHelp.PrintInfo>();
			for ( Object info : res){
				OrderServiceHelp.BulkPrintUIInfo uiInfo = (OrderServiceHelp.BulkPrintUIInfo)info;
				if (uiInfo == null ) continue;
				for ( String posNo : uiInfo.printInfos.keySet()) {
					if (CommUtils.isBlank(posNo)) posNo = printInfo.printName;
					if (!connectMap.containsKey(posNo)) {
						OrderServiceHelp.PrintInfo posInfo = OrderServiceHelp.getPrintByPosName(posNo);
						if (posInfo != null) connectMap.put(posNo,posInfo);
					}
				}
			}
			r.posMap = connectMap;
			// 2017/10/24 多印刷メッセージ放出機能追加 by zy END
			r.prints = res;
			// 印刷設備BASEメッセージ設定
			r.printUrl = printInfo.prinUrl;
			r.statusUrl = printInfo.statusUrl;
			r.print = printInfo;
		} else {
			r.error = Label.MSG_060_0053;
		}
		return r;
	}
	// 2017/10/14 部屋の予約別の機能追加　by　zy　BEGIN
	public transient String roomLeadId{get;set;}
	// 房间列表
	public class FloatRowInfo{
		public List<OneRowInfo> rowInfs{get;set;}
		public FloatRowInfo(){
			rowInfs = new List<OneRowInfo>();
		}
		public void add(OneRowInfo row){
			rowInfs.add(row);
		}
		public void processLead(Map<Id,List<Id>> leadMap){
			for (OneRowInfo row : rowInfs) {
				for (RoomInfo roomInfo : row.infos) {
					if (leadMap.containsKey(roomInfo.roomId)) {
						roomInfo.add(leadMap.get(roomInfo.roomId));
					}
				}
			}
		}
		public List<List<Id>> getRoomIds(){
			List<List<Id>> roomLst = new List<List<Id>>();
			for (OneRowInfo row : rowInfs) {
				roomLst.add(new List<Id>(row.rooms));
			}
			return roomLst;
		}
		public void setChildLeadByRoomId(Id roomId,Id leadId){
			for (OneRowInfo row : rowInfs) {
				if(row.rooms.contains(roomId)) {
					row.getRoomRow(roomId).add(leadId);
				}
			}
		} 
	}
	// 房间集合
	public class OneRowInfo{
		public List<RoomInfo> infos{get;set;}
		public Set<Id> rooms;
		public OneRowInfo (List<Id> roomIds) {
			infos = new List<RoomInfo>();
			for (Id roomId : roomIds) {
				infos.add(new RoomInfo(roomId));
			}
			rooms = new Set<Id>(roomIds);
		}
		public RoomInfo getRoomRow(Id roomId){
			RoomInfo row = null;
			for (RoomInfo info : infos) {
				if (info.roomId == roomId) row = info;
			}
			return row;
		}
	}
	// 房间信息
	public class RoomInfo{
		public List<Id> childs;
		public Id roomId;
		public RoomInfo(Id curId){
			roomId = curId;
			childs = new List<Id>();
		}
		public void add(Id leadId) {
			childs.add(leadId);
		}
		public void add(List<Id> leads){
			childs = leads;
		}
		public List<Id> allIds{
			get{
				List<Id> ids = new List<Id>();
				ids.add(roomId);
				if (!childs.isEmpty()) ids.addAll(childs);
				return ids;
			}
		}
	}
	// 2017/10/14 部屋の予約別の機能追加　by　zy　END
	// 2017/10/24 端末履歴共用機能追加 by zy BEGIN
	@remoteAction
	public static ProcessResult getTransDetail(String reqJson){
		//传入字符串
		RequsetInfo req = (RequsetInfo)JSON.deserializeStrict( reqJson, RequsetInfo.class);
		String accId = req.accId;
		//回传response
		ProcessResult r = new ProcessResult();
		if (!CommUtils.isBlank(accId)) {
			/*
			boolean deleteFlag = OrderServiceHelp.getDeleteFlag();*/
			// 被删除的id集合
			Set<Id> delSet = new Set<Id>();
			/*
			if (deleteFlag) {
				String transObjName = Tran1__c.sObjectType.getDescribe().getName();
				// delete message 
				Database.GetDeletedResult getDelRes = Database.getDeleted(transObjName,Datetime.now().adddays(-1),Datetime.now().addDays(1));
				for (Database.DeletedRecord delRec : getDelRes.getDeletedRecords()) {
					delSet.add(delRec.getId());
				}
			}*/
			// 2020/06/30 6926 bug fixed by zy BEGIN
			// 2020/02/28 SITE機能対応　by zy BEGIN
			// List<Tran1__c> tranLst = [select POSNo__c,Field9__c,Field21__c,Field23__c,Field7__c,Field50__c,UseDate__c,DeviceNo__c,InvoiceNoShowFlg__c,CreatedDate,OrderTime__c,IsDeleted,Field20__c from Tran1__c where Field1__c = :accId and Field9__c != null order by CreatedDate all rows];
			List<Tran1__c> tranLst = OrderServiceHelp.getTransByAccoutId(accId);
			// 2020/02/28 SITE機能対応　by zy END
			// 2020/06/30 6926 bug fixed by zy END
			r.prodObj = new List<Result>();
			// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy BEGIN
			Map<String,Tran1__c> transMap = new Map<String,Tran1__c>();
			for (Tran1__c tran : tranLst) {
				transMap.put(tran.id,tran);
			}
			tranLst = new List<Tran1__c>();
			// 2020/02/28 SITE機能対応　by zy BEGIN
			// for (OrderEntryInfo__c info : [select AccountRef__c, Id, LeadRef__c, Name, OrderStatus__c, OrderTime__c, PrintInfo__c, RoomRef__c, Trans__c,OrderTimeStmp__c from OrderEntryInfo__c where AccountRef__c =:accId and OrderStatus__c='印刷情報' order by OrderTime__c asc]){
			for (OrderEntryInfo__c info : OrderServiceHelp.getOrderEntrysByAccId(accId)){
			// 2020/02/28 SITE機能対応　by zy END
				for (String tranInfo : Commutils.nullToblank(info.trans__c).split(',')) {
					String[] infos = tranInfo.split(':'); 
					String tranId = infos[0];
					if (transMap.containsKey(tranId)) {
						String qty = null;
						Boolean deleteFlg = false;
						if (infos.size() > 1) qty = infos[1];
						if (infos.size() > 2) deleteFlg = true;
						Tran1__c tran = transMap.get(tranId).clone(true,true);
						if (!CommUtils.isBlank(qty)) {
							Integer cnt = Commutils.nullToIntZero(tran.Field21__c);
							Decimal eachPrice = CommUtils.nullToZero(tran.Field23__c);
							if (cnt > 0) eachPrice = CommUtils.nullToZero(tran.Field23__c)/cnt;
							// 会計明細存在、刷新オーダー情報内容
							tran.Field21__c = qty;
							tran.OrderTime__c = Datetime.newInstance(Long.valueOf(info.OrderTimeStmp__c));
							tran.Field23__c = Commutils.nullTOBlank(eachPrice*CommUtils.nullToIntZero(qty));
							tran.InvoiceNoShowFlg__c = deleteFlg;
							tran.id = tranId;
						}
						// オーダーId設定
						tran.Field49__c = info.id;
						tranLst.add(tran);
					}
				}
			}
			// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy END
			List<Result> tranRes = changeTranToInfo(tranLst,delSet);
			if (!tranRes.isEmpty()) r.prodObj.addAll(tranRes);
		}
		r.curTimeStmp = system.now().getTime();
		return r;
	}
	// 2017/10/24 端末履歴共用機能追加 by zy END
	// 2017/10/24 多印刷メッセージ放出機能追加 by zy BEGIN
	private static List<Result> changeTranToInfo(List<Tran1__c> tranLst,Set<Id> delSet){
		List<Result> results = new List<Result>();
		for ( Tran1__c tran : tranLst) {
			Result detail = new Result(tran);
			// 新データ
			if ( tran.OrderTime__c != null ) {
				detail.orderTime = tran.OrderTime__c.format('yyyy/MM/dd HH:mm');
				// 设定下单时间区分
				detail.orderMinute = tran.OrderTime__c.format('ss');
			// 既存データ
			} else {
				String orderTime = '00:00';
				String curTime = CommUtils.nullToBlank(tran.Field9__c);
				if ( !CommUtils.isBlank(curTime) ) {
					orderTime = curTime.subString(0,2) + ':' + curTime.subString(2);
				}
				detail.orderTime = DateTime.newInstance(tran.UseDate__c, CommUtils.stringToTime(orderTime)).format('yyyy/MM/dd HH:mm');
				// 设定下单时间区分
				detail.orderMinute = tran.CreatedDate.format('ss');
			}
			detail.posNo = CommUtils.nullToBlank(tran.DeviceNo__c);
			boolean isDelete = delSet.contains(tran.id);
			detail.isDelete = tran.IsDeleted || tran.InvoiceNoShowFlg__c;
			// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy BEGIN
			detail.orderId = tran.Field49__c;
			// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy END
			// 2020/06/30 6519 bug fix by zy BEGIN
			// 会計明細の単価設定，用于履歴「再び注文」機能表示単価
			detail.price = CommUtils.nullToZero(tran.Field20__c);
			// 2020/06/30 6519 bug fix by zy END
			results.add(detail);
		}
		return results;
	}
	// 2017/10/24 多印刷メッセージ放出機能追加 by zy END
	// 2019/01/15 オーダーエントリー改善（メニューサイズ自動調整）by cxw BEGIN
	public String menuZoomFlag{get;set;}
	// 2019/02/15 オーダーエントリー改善（文字サイズをカスタマイズとレイアウト自由カスタマイズ機能） by cxw BEGIN
	public Map<string, string> roomZoomFlag{get; set;}
	// 2019/02/15 オーダーエントリー改善（文字サイズをカスタマイズとレイアウト自由カスタマイズ機能） by cxw END
	public boolean mobileFlag{get;set;}
	// 2019/01/15 オーダーエントリー改善（メニューサイズ自動調整）by cxw END
	// 2019/02/15 オーダーエントリー画面のボタン表示内容を端末ごとに変更したい by zy BEGIN
	private void afterInitProds(){
		// IP有効
		if (!CommUtils.isBlank(localIp)) {
			OrderServiceHelp.Device device = OrderServiceHelp.getDeviceMap().get(localIp);
			String deviceNo = device != null ? CommUtils.nullToBlank(device.posNo) : '';
			//　機能チェック
			for (TabClass tab : tabLst) {
				if (tab.posSet.isEmpty()) tab.tabDisStr = 'true';
				else 
					tab.tabDisStr = (!CommUtils.isBlank(deviceNo) && tab.posSet.contains(deviceNo)) ? 'true' : 'none';
			}
		}
	}
	// 2019/02/15 オーダーエントリー画面のボタン表示内容を端末ごとに変更したい by zy END
	// 2019/03/28 オーダーエントリー改善レシート再出力機能 by zy BEGIN
	/**
	*	Order 作成する
	**/
	@remoteAction
	public static object remoteCenter (String remoteType,String req) {
		// 印刷履歴取得
		if (remoteType == 'printHistory') return printHistory(req);
		else if (remoteType == 'rePrintOrder') return rePrintOrder(req);
		// 2020/02/15 予約が入っていないテーブルも選択可能に by zy BEGIN 
		else if (remoteType == 'createLeadByRooms') return createLeadByRooms(req);
		// 2020/02/15 予約が入っていないテーブルも選択可能に by zy END
		// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy BEGIN
		else if (remoteType == 'getCuurentLeads') return getCuurentLeads(req);
		// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy END
		return null;
	}
	// 印刷履歴取得
	private static object printHistory(String request){
		// 該当ユーザー取得
		String userId = UserUtil.CurrentUserInfo.u.id;
		RequsetInfo req = (RequsetInfo)JSON.deserialize(request, RequsetInfo.class);
		// 検索日
		Date queryDt = CommUtils.stringToDate(req.queryDate);
		if (queryDt == null) queryDt = system.today();
		// 店舗コード
		String spcd = req.shopCd;
		// 会計のみ
		boolean isAccountFlag = req.accFlg;
		// 並べ順
		String orderSort = CommUtils.nullToBlank(req.orderSort);
		String orderStr = CommUtils.nullToBlank(req.order);
		// 印刷店舗別初期化
		OrderServiceHelp.setInstance(spcd);
		// 反回結果
		List<Map<String,object>> resultMap = new List<Map<String,object>>();
		// 印刷情報取得
		List<OrderEntryInfo__c> orders = OrderServiceHelp.queryPrintOrderinfo(userId,queryDt,orderSort,orderStr,isAccountFlag);
		// 注文指定会計明細
		Map<String,string> transOrderMap = new Map<String,string>();
		// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy BEGIN
		Map<String,String> orderTranCntMap = new Map<String,String>();
		Set<String> tranSet = new Set<String>();
		// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy END
		// 注文と会計明細対応関係作成
		for (OrderEntryInfo__c orderInfo : orders) {
			// 会計明細作成
			Set<String> trans = new Set<String>(CommUtils.nullToblank(orderInfo.trans__c).split(','));
			for (String tranId : trans) {
				// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy BEGIN
				//transOrderMap.put(tranId,orderInfo.id);
				String[] infos = tranId.split(':');
				String orgId = infos[0];
				tranSet.add(orgId);
				// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy END
			}
		}
		// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy BEGIN
		if (!tranSet.isEmpty()) {
		//if (!transOrderMap.isEmpty()) {
			// 注文対応会計明細内容作成
			Map<String,List<Map<String,String>>> orderTranMap = new Map<String,List<Map<String,String>>>();
			Map<String,Tran1__c> tranMap = new Map<String,Tran1__c>();
			// 2020/06/30 6519 bug fix by zy BEGIN
			for (Tran1__c tran : [select Field7__c,id,Field21__c,Field39__c,Field23__c,Field7__r.Field5__c,Field7__r.TaxRateCal__c,Field7__r.ServiceRate__c,Field20__c  from Tran1__c where id = :tranSet]){
			// 2020/06/30 6519 bug fix by zy END	
				tranMap.put(tran.id,tran);
			}
			// 注文と会計明細対応関係作成
			for (OrderEntryInfo__c orderInfo : orders) {
				// 会計明細作成
				List<String> trans = CommUtils.nullToblank(orderInfo.trans__c).split(',');
				for (String tranId : trans) {
					// オーダー指定会計明細取得
					String[] infos = tranId.split(':');
					// 会計明細
					String orgId = infos[0];
					// オーダーId
					String orderId = orderInfo.id;
					// 指定会計明細不存在
					if (!tranMap.containsKey(orgId)) continue;
					// 会計明細削除
					if (infos.size() > 2) continue;
					// 対応会計取得
					Tran1__c tran = tranMap.get(orgId);
					// 履歴明細作成
					if (!orderTranMap.containsKey(orderId)) orderTranMap.put(orderId,new List<Map<String,String>>());
					// 数量情報あり
					if (infos.size() > 1) {
						// 数量変更後、金額刷新
						Tran1__c newTran = tran.clone();
						String qty = infos[1];
						tran = changeCntTrans(CommUtils.nullToIntZero(qty),newTran,tran);
					}
					// 処理内容作成
					orderTranMap.get(orderId).add(new Map<String,String>{'id' => tran.Field7__c, 'cnt' => tran.Field21__c,'total' => tran.Field23__c,'price' => CommUtils.nullToBlank(CommUtils.nullToZero(tran.Field39__c))});
				}
				/*
				String orderId = transOrderMap.get(tran.id);
				if (!CommUtils.isBlank(orderId)) {
					if (!orderTranMap.containsKey(orderId)) orderTranMap.put(orderId,new List<Map<String,String>>());
					orderTranMap.get(orderId).add(new Map<String,String>{'id' => tran.Field7__c, 'cnt' => tran.Field21__c,'total' => tran.Field23__c,'price' => CommUtils.nullToBlank(CommUtils.nullToZero(tran.Field39__c))});
				}
				}*/
				// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy END
			}
			// 会計の場合
			if (isAccountFlag) {
				// 会計注文関係作成
				Set<String> accOrderSet = new Set<String>();
				// 注文の会計商品
				Map<String,List<Map<String,String>>> prodsMap = new Map<String,List<Map<String,String>>>();
				// 注文
				Map<String,List<String>> orderMap = new Map<String,List<String>>();
				// 指定会計注文
				Map<String,OrderEntryInfo__c> entryMap = new Map<String,OrderEntryInfo__c>();
				// 指定会計印刷情報
				Map<String,Set<String>> printMap = new Map<String,Set<String>>();
				for (OrderEntryInfo__c orderInfo : orders) {
					// 注文の会計なし
					if (!orderTranMap.containsKey(orderInfo.id)) continue;
					// 注文の会計商品作成
					if (!prodsMap.containsKey(orderInfo.AccountRef__c))	
						prodsMap.put(orderInfo.AccountRef__c,new List<Map<String,String>>());
					prodsMap.get(orderInfo.AccountRef__c).addAll(orderTranMap.get(orderInfo.id));
					// 注文内容作成
					if (!orderMap.containsKey(orderInfo.AccountRef__c)) orderMap.put(orderInfo.AccountRef__c,new List<String>());
					orderMap.get(orderInfo.AccountRef__c).add(orderInfo.id);
					if (!entryMap.containsKey(orderInfo.AccountRef__c)) entryMap.put(orderInfo.AccountRef__c,orderInfo);
					accOrderSet.add(orderInfo.AccountRef__c);
					// 指定会計印刷情報
					if (!printMap.containsKey(orderInfo.AccountRef__c)) printMap.put(orderInfo.AccountRef__c,new Set<String>());
					printMap.get(orderInfo.AccountRef__c).add(orderInfo.PrintInfo__c);
				}
				for (String accId : accOrderSet) {
					if (orders.isEmpty()) continue;
					OrderEntryInfo__c baseInfo = entryMap.get(accId);
					// 明細作成
					Map<String,Object> result = convertOrderInfo(queryDt,baseInfo);
					// 会計
					result.put('id',accId);
					// 会計の会計商品
					result.put('prods',prodsMap.get(accId));
					// 注文
					result.put('orderIds',orderMap.get(accId));
					// 注文
					result.put('prints',new List<String>(printMap.get(accId)));
					resultMap.add(result);
				}
			} else {
				for (OrderEntryInfo__c orderInfo : orders) {
					// 注文の会計なし
					if (!orderTranMap.containsKey(orderInfo.id)) continue;
					// 明細作成
					Map<String,Object> result = convertOrderInfo(queryDt,orderInfo);
					// 会計
					result.put('id',orderInfo.id);
					// 会計の会計商品
					result.put('prods',orderTranMap.get(orderInfo.id));
					// 注文
					result.put('orderIds',new List<String>{orderInfo.id});
					// 印刷名
					result.put('prints',new List<String>{orderInfo.PrintInfo__c});
					OrderServiceHelp.PrintInfo printInfo = OrderServiceHelp.getPrintByPosName(orderInfo.PrintInfo__c);
					String posNo = '';
					if (printInfo != null) posNo = CommUtils.nullToblank(printInfo.posno);
					// 印刷名
					result.put('posNo',posNo);
					resultMap.add(result);
				}
			}	
		}
		return resultMap;
	}
	// 印刷情報作成
	// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けない by zy BEGIN
	private static void insertPrintInfo(List<ProcessResult> rs,String accId,String roomId,long curTimeStmp) {
	// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けない by zy END	
		List<OrderEntryInfo__c> printInfos = new List<OrderEntryInfo__c>();
		// 該当情報あり
		if (!rs.isEmpty()) {
			// 印刷内容作成
			for (ProcessResult pr : rs) {
				OrderEntryInfo__c p = new OrderEntryInfo__c();
				p.PrintInfo__c = CommUtils.nullToblank(pr.print.printName);
				p.SearchDate__c = system.today();
				p.AccountRef__c = accId;
				p.OrderStatus__c = OrderServiceHelp.ORDER_STATUS_PRINT_INFO;
				p.Trans__c = String.join(pr.tranIds,',');
				// 2020/02/15 会計の簡易レイアウトを変更 by zy BEGIN
				p.CookInfo__c = String.join(pr.cooks,',');
				if (!CommUtils.isBlank(pr.leadId))
					p.LeadRef__c = CommUtils.nullToBlank(pr.leadId);
				// 2020/02/15 会計の簡易レイアウトを変更 by zy END
				p.OrderTime__c = Datetime.newInstance(pr.curTimeStmp).format('HH:mm') ;
				// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けない by zy BEGIN
				p.OrderTimeStmp__c = CommUtils.nullToblank(curTimeStmp);
				// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けない by zy END
				if (!CommUtils.isBlank(roomId))p.RoomRef__c = roomId;
				printInfos.add(p);			
			}
		}
		// 印刷情報作成
		OrderServiceHelp.insertPrintOrderinfo(printInfos);
		// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy BEGIN
		if (Site.getDomain() != null) {
			List<CooperationResult__c> res = new List<CooperationResult__c>();
			for (OrderEntryInfo__c p : printInfos) {
				res.add(new CooperationResult__c(
					AccountAcountRef__c = accId,
					FunctionType__c = 'レーシト印刷',
					ManageID__c = p.id,
					Status__c = '予約取込待ち'
				));
			}
			// 2020/02/28 SITE機能対応　by zy BEGIN
			if (!res.isEmpty()) OrderServiceHelp.insertCooperationResultInfo(res);
			// 2020/02/28 SITE機能対応　by zy END
		}
		// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy END
	}
	// 会計商品Id集合
	private static void convertTranProds(List<tran1__c> trans,ProcessResult r) {
		List<String> prodsArr = new List<String>();
		List<String> transArr = new List<String>();
		// 2020/02/15 会計の簡易レイアウトを変更 by zy BEGIN
		List<String> cooksArr = new List<String>();
		// 2020/02/15 会計の簡易レイアウトを変更 by zy END
		for (tran1__c tran : trans) {
			prodsArr.add(tran.Field7__c);
			// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy BEGIN
			transArr.add(tran.id + ':' + tran.Field21__c);
			// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy END
			// 2020/02/15 会計の簡易レイアウトを変更 by zy BEGIN
			if (prodInfoMap.containsKey(tran.Field7__c)){
				ProdInfo prod = prodInfoMap.get(tran.Field7__c);
				String message = tran.id + ':' + tran.Field21__c + ':' + CommUtils.nullToIntZero(prod.cookRow) + ':' + CommUtils.nullToBlank(prod.cookDesc);
				cooksArr.add(message);
			}
			// 2020/02/15 会計の簡易レイアウトを変更 by zy END
		}
		r.prodIds = prodsArr;
		r.tranIds = transArr;
		// 2020/02/15 会計の簡易レイアウトを変更 by zy BEGIN
		r.cooks = cooksArr;
		// 2020/02/15 会計の簡易レイアウトを変更 by zy END
	}
	// 照会指定日情報を格納する
	public BookingTimeTable__c timeTable{get;set;}
	// 再印刷機能
	private static ProcessResult rePrintOrder(String request){
		//　印刷情報
		ProcessResult r = new ProcessResult();
		// 画面情報取得
		RequsetInfo req = (RequsetInfo)JSON.deserialize(request, RequsetInfo.class);
		// 指定会計情報取得
		List<AccountAcount__c> accLst = [select id,frs__c,TaxRate__c,name,Field145__c,Relreserve__r.Rroom__r.name,Field53__c,Relreserve__r.Field354__c,Relreserve__c,Relreserve__r.RelContact__r.name from AccountAcount__c where id = :req.accId];
		Set<String> prodSet = new Set<String>();
		if (!accLst.isEmpty()){
			AccountAcount__c curAcc = accLst[0];
			Id accId = curAcc.id;
			Id relAccId = curAcc.frs__c;
			// 指定注文
			Set<String> orderIds = new Set<String>();
			orderIds.addAll(req.orderIds);
			// 会計明細集合
			Set<String> transSet = new Set<String>();
			List<OrderEntryInfo__c> orders = OrderServiceHelp.queryEntrysByIds(orderIds);
			for (OrderEntryInfo__c order : orders) {
				// 会計明細作成
				// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けない by zy BEGIN
				for (String infos : CommUtils.nullToblank(order.trans__c).split(',')) {
					String[] transInfo = infos.split(':');
					if (transInfo.size() > 2) continue;
					transSet.add(transInfo[0]);
				}
				// 会計明細作成
				//Set<String> tranIdSet = new Set<String>(CommUtils.nullToblank(order.trans__c).split(','));
				//transSet.addAll(tranIdSet);
				// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けない by zy END
			}
			List<Tran1__c> tranLst = [select POSNo__c,Field5__c,Field9__c,Field21__c,
									TaxRate__c,ActionType__c,ServiceRate__c,Field20__c,Field23__c,
										Field7__c,Field50__c,UseDate__c,DeviceNo__c,InvoiceNoShowFlg__c,
											CreatedDate,OrderTime__c,IsDeleted 
											// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けない by zy BEGIN
											,Field7__r.Field5__c,Field7__r.TaxRateCal__c,Field7__r.ServiceRate__c
											// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けない by zy END
											from Tran1__c 
											where id = :transSet and InvoiceNoShowFlg__c = false order by CreatedDate];
			// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けない by zy BEGIN
			Map<String,Tran1__c> tranMap = new Map<String,Tran1__c>();
			for (Tran1__c tran : tranLst) tranMap.put(tran.id,tran);
			List<Tran1__c> newTranLst = new List<Tran1__c>();
			for (OrderEntryInfo__c order : orders) {
				for (String infos : CommUtils.nullToblank(order.trans__c).split(',')) {
					String[] transInfo = infos.split(':');
					if (transInfo.size() > 2) continue;
					String tranId = transInfo[0];
					if (!tranMap.containsKey(tranId)) continue;
					Tran1__c tran = tranMap.get(tranId);
					Tran1__c newTran = tran.clone(true,true);
					if (transInfo.size() > 1) newTran = changeCntTrans(CommUtils.nullToIntZero(transInfo[1]),newTran,tran);
					newTran.OrderTime__c = Datetime.newInstance(Long.valueOf(order.OrderTimeStmp__c));
					newTranLst.add(newTran);
				}
			}
			tranLst = newTranLst;
			// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けない by zy END
			Map<String,List<Tran1__c>> timeTrans = new Map<String,List<Tran1__c>>();
			for ( Tran1__c tran : tranLst) {
				String orderTime = '00:00';
				// 新データ
				if ( tran.OrderTime__c != null ) orderTime = tran.OrderTime__c.format('yyyy/MM/dd HH:mm');
				// 既存データ
				else {
					String curTime = CommUtils.nullToBlank(tran.Field9__c);
					if ( !CommUtils.isBlank(curTime) ) {
						orderTime = curTime.subString(0,2) + ':' + curTime.subString(2);
					}
					orderTime = DateTime.newInstance(tran.UseDate__c, CommUtils.stringToTime(orderTime)).format('yyyy/MM/dd HH:mm');
				}
				prodSet.add(tran.Field7__c);
				if (!timeTrans.containsKey(orderTime)) timeTrans.put(orderTime,new List<tran1__c>());
				timeTrans.get(orderTime).add(tran);
			}
			if (!timeTrans.isEmpty()){
				//2017/04/20 多店舗機能対応　by　zy BEGIN
				OrderServiceHelp.setInstance(req.shopCd);
				//2017/04/20 多店舗機能対応　by　zy END
				Map<String,Object> resultMap = new Map<String,Object>{'allergie' => CommUtils.nullToBlank(curAcc.Relreserve__r.Field354__c),'orderno'=> curAcc.Name,'orderplace'=> CommUtils.nullToBlank(curAcc.Relreserve__r.Rroom__r.name),'custname' => CommUtils.nullToBlank(curAcc.Relreserve__r.RelContact__r.name)};
				OrderServiceHelp.PrintInfo printInfo = OrderServiceHelp.getPrintByPosName(req.printName);
				if (printInfo == null) {
					throw new CommException('無効なディバイスため、注文をできません、スタッフへ連絡してください!' );
				} 
				if (curAcc.Relreserve__c != null) {
					// 印刷フィルター「アレルギー」カスタム設定機能
					Map<Id,Map<String,Object>> customMap = OrderServiceHelp.getAllCustomMap(new List<Id>{curAcc.Relreserve__c},null,printInfo.headStanFlag);
					if (customMap != null && !customMap.isEmpty()) { 
						if (customMap.containsKey(curAcc.Relreserve__c)) {
							Map<String,Object> curMap = customMap.get(curAcc.Relreserve__c);
							for (String paraName : curMap.keySet()) {
								resultMap.put(paraName,CommUtils.nullToBlank(curMap.get(paraName)));
							}
						}
					}
				}
				// 2017/09/18 印刷フィルター「アレルギー」カスタム設定機能by zy END
				Map<Id,List<FoodDetail__c>> planDetailMap = new Map<Id,List<FoodDetail__c>>();
				Map<Id,AccountMaster__c> accountMap = new Map<Id,AccountMaster__c>();
				if (!timeTrans.isEmpty()) {
					//打印信息
			        OrderServiceHelp.LayoutType layType = OrderServiceHelp.LayoutType.ACCOUNT;
					// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy BEGIN
					if (req.processType == OrderServiceHelp.LayoutType.ORDER.name()) layType =  OrderServiceHelp.LayoutType.ORDER;
					// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy END	
					r.printInfo = OrderServiceHelp.getPrintJson(printInfo,tranLst,false,layType, planDetailMap,curAcc,resultMap);
				}
				r.printUrl = printInfo.prinUrl;
				r.statusUrl = printInfo.statusUrl;
				r.accId = accId;
			}
		}
		return r;
	}
	private static Map<String,Object> convertOrderInfo(Date queryDt,OrderEntryInfo__c orderInfo){
		Map<String,Object> result = new Map<String,Object>();
		String orderTime = '00:00';
		if (!CommUtils.isBlank(orderInfo.OrderTime__c)) orderTime = orderInfo.OrderTime__c;
		// 会計
		result.put('accId',orderInfo.accountRef__c);
		// 印刷時間
		result.put('time',Datetime.newInstance(queryDt, CommUtils.stringtoTime(orderTime)).gettime());
		// 会計
		String info = CommUtils.nullToBlank(orderInfo.PrintInfo__c).unescapeHtml4();
		if (CommUtils.isBlank(info)) result.put('info','{}');
		else result.put('info',info);
		// 部屋名
		result.put('room',CommUtils.nullToBlank(orderInfo.RoomRef__r.name));
		// 上様
		String contactName = Label.CONST_012_0414;
		if (!CommUtils.isBlank(orderInfo.accountRef__r.relreserve__r.relcontact__r.name))
			contactName = CommUtils.nullToBlank(orderInfo.accountRef__r.relreserve__r.relcontact__r.name);
		// お客様名
		result.put('contact',contactName);
		return result;
	}
	// 2019/03/28 オーダーエントリー改善レシート再出力機能 by zy END
	// 会計明細のオーダー情報内容刷新
	public static List<Tran1__c> refreshOrderInfo(List<Tran1__c> trans,Set<String> accMasterIds,String accountId){
		// 結果リスト
		List<Tran1__c> result = new List<Tran1__c>();
		// 会計商品の会計明細集合
		Map<String,Tran1__c> tranMap = new Map<String,Tran1__c>();
		// 指定会計下、指定会計商品会計明細取得
		// 2020/04/30 会計に追加されない同じテストを別の予約、これも同じように会計商品の会計が作成されない。 by zy BEGIN
		// 2020/06/30 オーダエンドリーでの金額入力 by zy BEGIN
		// 2020/02/28 SITE機能対応　by zy BEGIN
		List<Tran1__c> sameTrans = OrderServiceHelp.getTransByAccountMasterAndAccId(accountId,accMasterIds);
		/*
		List<Tran1__c> sameTrans = [select id,Field1__c,Field21__c,Field23__c,Field7__c,Field7__r.Field5__c,Field7__r.TaxRateCal__c,Field7__r.ServiceRate__c,OrderTimeStmp__c,OrderTime__c,Field20__c from Tran1__c where Field1__c = :accountId and Field7__c = :accMasterIds and InvoiceNoShowFlg__c = false 
		// 2020/06/30 オーダエンドリーでの金額入力 by zy END
									and ParentTran1Ref__c = null
									order by orderTime__c asc];
		*/
		// 2020/02/28 SITE機能対応　by zy END
		// 2020/04/30 会計に追加されない同じテストを別の予約、これも同じように会計商品の会計が作成されない。 by zy END
		// 集合作成
		// 2020/06/30 オーダエンドリーでの金額入力 by zy BEGIN
		for (Tran1__c tran : sameTrans) {
			// 2020/02/28 SITE機能対応　by zy BEGIN
			if (!prodInfoMap.containsKey(tran.Field7__c)) continue;
			// 2020/02/28 SITE機能対応　by zy END
			// 同じ単価の明細指定
			if (prodInfoMap.get(tran.Field7__c).price == CommUtils.nullToZero(tran.Field20__c)){
				tranMap.put(tran.Field7__c,tran);
			}
		}
		// 2020/06/30 オーダエンドリーでの金額入力 by zy END
		// 画面新規会計明細フィルター
		for (Tran1__c tran1 : trans) {
			Tran1__c tran = tran1.clone(false,false);
			// 既存会計明細
			Tran1__c exitTran = tranMap.get(tran.Field7__c);
			// 会計明細不存在
			if (exitTran == null) {
				// 結果追加
				result.add(tran);
				continue;
			}
			// 会計明細存在、刷新オーダー情報内容
			Integer qty = Commutils.nullToIntZero(tran.Field21__c) + Commutils.nullToIntZero(exitTran.Field21__c);
			tran = changeCntTrans(qty,tran,exitTran);
			tran.id = exitTran.id;
			// 結果追加
			result.add(tran);
		}
		return result;
	}
	// 数量変更後、合計金額自動計算
	private static Tran1__c changeCntTrans(Integer qty,Tran1__c tran,Tran1__c orgTran){
		// 2020/06/30 オーダエンドリーでの金額入力 by zy BEGIN
		// 該当単価
		decimal unitPrice = CommUtils.nullToZero(orgTran.Field20__c);
		if (unitPrice == null) unitPrice = CommUtils.nullToZero(orgTran.Field7__r.Field5__c);
		// 2020/06/30 オーダエンドリーでの金額入力 by zy END
		// 合計金額計算
		priceInfo.process(unitPrice, qty , orgTran.Field7__r.TaxRateCal__c, orgTran.Field7__r.ServiceRate__c);
		// 会計明細存在、刷新オーダー情報内容
		tran.Field21__c = CommUtils.nullToBlank(qty);
		tran.Field23__c = CommUtils.nullToBlank(priceInfo.priceIncTax);
		return tran;
	}
	// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy END
	// 2019/06/30 レイアウトカスタマイズ機能が必要場合、レイアウトをカスタマイズ用VF作成が必要そうです by zy BEGIN
	// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy BEGIN
	public Boolean iframeMode {get {
		return deslayoutOpts.size() > 0 ? true : !CommUtils.isBlank(DesignLayoutCtrl.getDefLayoutList(oShopCode));
	} set;}
	// デフォルトレイアウトId
	public String curLayoutId{get;set;}
	//　場所Id
	public String selLocationId{get;set;}
	public String selLocLayoutId{get;set;}
	//　場所Id
	public List<System.SelectOption> deslayoutOpts{get;set;}
	private void initLocAndLayout(){
		// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy BEGIN
		deslayoutOpts = OrderServiceHelp.getLayoutOpts(oShopCode,false);
		CurlayoutId = OrderServiceHelp.getFirstLayoutId();
		// 2020/08/15 オーダーエントリーの部屋レイアウトですが、画面を開いたタイミングでは、各予約の到着時刻・出発時刻に関わらず全ての予約が表示されてしまうようです。 by zy BEGIN
		curType = OrderServiceHelp.getDefLayoutCurtype();
		// 2020/08/15 オーダーエントリーの部屋レイアウトですが、画面を開いたタイミングでは、各予約の到着時刻・出発時刻に関わらず全ての予約が表示されてしまうようです。 by zy END
		selLocationId = '';
		selLocLayoutId = '';
		// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy END
		// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy BEGIN
		selLeadRoomFlg = OrderServiceHelp.getSelLeadRoomFlg();
		// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy END
	}
	//　
	public String curType{get;set;}
	// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy END
	public String jsonMainRoom{get; set;}
	private boolean processCookTime(Lead__c lead,Datetime startDt,Datetime endDt) {
		// 2019/11/30 エラー修正　by zy BEGIN
		if (CommUtils.isBlank(lead.field4__c)) lead.field4__c = CommConst.DEF_CHECKIN_TIME;
		if (CommUtils.isBlank(lead.field3__c)) lead.field3__c = CommConst.DEF_CHECKOT_TIME;
		// 2019/11/30 エラー修正　by zy END
		Datetime beginTime = Datetime.newInstance(lead.EntryTime__c.date(),CommUtils.stringtoTime(lead.field4__c));
		Datetime endTime = Datetime.newInstance(lead.Departure__c.date(),CommUtils.stringtoTime(lead.field3__c));

		// 到着日或者出发日，在当前时间段里就可以显示
		if ((beginTime >= startDt && beginTime <= endDt)
			|| (endTime >= startDt && endTime <= endDt)
		) {
			return true;
		}
		return false;
	}
	// 2019/06/30 レイアウトカスタマイズ機能が必要場合、レイアウトをカスタマイズ用VF作成が必要そうです by zy END
	// 2020/02/15 会計の簡易レイアウトを変更 by zy BEGIN
	private static Map<String,ProdInfo> prodInfoMap;
	public List<System.SelectOption> cookDescOpts{get;set;}
	public String bottomHt{get{return '18em';}set;}
	// 2020/02/15 会計の簡易レイアウトを変更 by zy END
	// 2020/02/15 予約が入っていないテーブルも選択可能に by zy BEGIN 
	public boolean multiRoomFlg{get;set;} //複数部屋選択フラグ
	private static object createLeadByRooms(String request){
		RequsetInfo req = (RequsetInfo)JSON.deserialize(request, RequsetInfo.class);
		String oShopCode = req.shopCd;
		List<String> roomIds = req.orderIds;
		OrderServiceHelp.setInstance(oShopCode);
		// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy BEGIN
		Map<String,OrderserviceHelp.LeadINfo> leadMap = OrderServiceHelp.getLeadMap();
		// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy BEGIN
		String leadId = req.leadId;
		// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy END
		Set<Id> roomIdSet = new Set<Id>();
		for (String roomId : roomIds) roomIdSet.add(roomId);
		List<Room__c> roomLst = OrderServiceHelp.getRoomLst(roomIdSet);
		Map<String,Room__c> roomMap = new Map<String,Room__c>();
		String blankKey = 'BLANK';
		for (Room__c r : roomLst) roomMap.put(r.id,r);
		roomLst = new List<Room__c>();
		for (String rid : roomIds) {
			if (roomMap.containsKey(rid)) roomLst.add(roomMap.get(rid));
		}
		List<Lead__c> newLeads = new List<Lead__c>();
		Map<String, Schema.DescribeFieldResult> leadValuesMaps = CommSqlUtils.getAllFieldLst(Lead__c.sObjectType,false,true);
		Date todayDt = system.today();
		Datetime currentTm = system.now();
		Datetime departTm = currentTm.addHours(CommConst.DEF_DAYUSE_STAY_HOURS);
		Lead__c newLead = new Lead__c();
    	// 予約のレコードタイプ
    	newLead.RecordTypeId = CommLogicProcess.getLeadBookingRecType();
		newLead.RoomGroupNo__c = 0;
		newLead.EntryTime__c = currentTm;
		newLead.Departure__c = departTm;
		newLead.Field4__c = currentTm.format('HH:mm');
		newLead.Field3__c = departTm.format('HH:mm');
		newLead.ReservedDate__c = currentTm;
		// 現在時間＋デフォルト時間→明日
		boolean isDefaultOneDay = currentTm.date().daysBetween(departTm.date()) > 0;
		// 初期値設定する
		// 会計側に人數が存在する場合、優先に会計人數を表示する
		newLead.StayPersons__c = CommConst.getBookingMansDef() + CommConst.getBookingFemailsDef() + CommConst.getBookingChildrenDef();
		Contact con = CommLogicProcess.getOrInsertTempContact();
		newLead.relcontact__c = con.id;
		ProcessResult pr = new ProcessResult();
		// 2020/04/30 現状の仕様ですと部屋付けをしてもあくまで「選択したテーブルの会計」に注文した商品が入力される形となりますが、実際に行いたかったのは「部屋付け先の客室の会計」に注文した商品が入力されるという挙動です。 by zy BEGIN
		pr.roomId = roomIds[0];
		OrderServiceHelp.Leadinfo exitInfo = leadMap.get('');
		// 2020/04/30 現状の仕様ですと部屋付けをしてもあくまで「選択したテーブルの会計」に注文した商品が入力される形となりますが、実際に行いたかったのは「部屋付け先の客室の会計」に注文した商品が入力されるという挙動です。 by zy END
		// DB操作を行う
		Savepoint sp = Database.setSavepoint();
		// 時間設定の集合
		Set<String> exitTimeSet = new Set<String> {'field3__c','field4__c'};
		boolean isTimeChg = false;
		try{
			// 2020/04/30  １部屋だけ選択するとCREATEINFOを定義していても予約が作成されず今まで通りの挙動になる by zy BEGIN
			// エラーチェック
			// 2020/04/30 6231 bug fix by zy BEGIN
			preUpdateOrderMain(req);
			// 2020/04/30 6231 bug fix by zy END
			// 2020/04/30  １部屋だけ選択するとCREATEINFOを定義していても予約が作成されず今まで通りの挙動になる by zy END
			// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy BEGIN
			List<Lead__c> leads = new List<Lead__c>();
			if (!CommUtils.isBlank(leadId)) {
				OrderServiceHelp.Leadinfo info = leadMap.get(blankKey);
				Set<String> cloneLst = new Set<String>();
				if (!info.cloneSet.isEmpty()) cloneLst = info.cloneSet;
				String leadQuery = 'Select ';
				Set<String> querySet = new Set<String>(cloneLst);
				if (!cloneLst.contains('id')) querySet.add('id');
				if (!cloneLst.contains('leadindexref__c')) querySet.add('leadindexref__c');
				if (!cloneLst.contains('leadindexsubid__c')) querySet.add('leadindexsubid__c');
				if (!cloneLst.contains('roomgroupno__c')) querySet.add('roomgroupno__c');
				if (!cloneLst.contains('entrytime__c')) querySet.add('entrytime__c');
				leadQuery += String.join(new List<String>(querySet),',');
				leadQuery += ' from Lead__c where id=:leadId';
				leads = Database.query(leadQuery);
			}
			// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy END
			for (Room__c r : roomLst) {
				// 2020/04/30 現状の仕様ですと部屋付けをしてもあくまで「選択したテーブルの会計」に注文した商品が入力される形となりますが、実際に行いたかったのは「部屋付け先の客室の会計」に注文した商品が入力されるという挙動です。 by zy BEGIN
				//OrderServiceHelp.Leadinfo info = leadMap.get('');
				OrderServiceHelp.Leadinfo info = exitInfo;
				String roomTypeSeq = CommUtils.nullToBlank(r.TypeRoomRef__r.Seq__c);
				if (leadMap.containsKey(roomTypeSeq)) info = leadMap.get(roomTypeSeq);
				// 2020/04/30 現状の仕様ですと部屋付けをしてもあくまで「選択したテーブルの会計」に注文した商品が入力される形となりますが、実際に行いたかったのは「部屋付け先の客室の会計」に注文した商品が入力されるという挙動です。 by zy END
				// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy BEGIN
				// コピー用設定
				if (!CommUtils.isBlank(leadId)) info = leadMap.get(blankKey);
				// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy END
				Lead__c cloneLead = newLead.clone(false,false);
				cloneLead.name = r.name;
				cloneLead.Rroom__c = r.id;
				cloneLead.refTypeOfRooms__c = r.TypeRoomRef__c;
				// 指定字段情報あり
				if (info != null) {
					// 作成泊数指定
					// 指定時間未超出１日
					if (!isDefaultOneDay) cloneLead.Departure__c = cloneLead.EntryTime__c.addDays(info.night);
					for (String field : info.fieldValueMap.keySet()){
						String apiKey = field.toLowerCase();
						// 時間設定の場合
						if (!isTimeChg) isTimeChg = exitTimeSet.contains(apiKey);
						if (leadValuesMaps.containsKey(apiKey)) {
							String apiVal = info.fieldValueMap.get(field);
							// 处理字段类型
							Schema.DescribeFieldResult dr = leadValuesMaps.get(apiKey);
							if(!CommUtils.isBlank(apiVal)) cloneLead.put(apiKey,CommUtils.ConvByFielType(apiVal,dr.getType(),true));
						}
					}
					// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy BEGIN
					if (!leads.isEmpty()) {
						Lead__c parLead = leads[0];
						//　同じ予約インデックス指定
						cloneLead.LeadIndexRef__c = leads[0].LeadIndexRef__c;
						// 小部屋フラグ設定
						cloneLead.ParentLeadId__c = leadId; 
						// コピー字段設定
						for (String field : info.cloneSet) {
							if (leadValuesMaps.containsKey(field.toLowerCase())) cloneLead.put(field,parLead.get(field));
						}
					}
					// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy END
					// 特殊処理
					// 5621 fix by zy BEGIN
					cloneLead.EntryTime__c = CommUtils.convertDatetime(cloneLead.EntryTime__c.Date(),cloneLead.field4__c);
					cloneLead.Departure__c = CommUtils.convertDatetime(cloneLead.Departure__c.Date(),cloneLead.field3__c);
					// 特殊エラー処理
					// 如果指定的到着时间和出发时间出现不合法的现象，则重新设定出发时间
					if (cloneLead.EntryTime__c > cloneLead.Departure__c) cloneLead.Departure__c  = cloneLead.EntryTime__c.addHours(CommConst.DEF_DAYUSE_STAY_HOURS);
					// 時間関連の字段更新
					if (isTimeChg) {
						cloneLead.Field4__c = cloneLead.EntryTime__c.format('HH:mm');
						cloneLead.Field3__c = cloneLead.Departure__c.format('HH:mm');
					}
					
				}
				// 5621 fix by zy BEGIN
				newLeads.add(cloneLead);
			}
			newLead = newLeads[0];
			// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy BEGIN
			if (!CommUtils.isBlank(leadId)) {
				if (!leads.isEmpty()) {
					Lead__c parLead = leads[0];
					LeadIndex__c mainSub = null;
					// 親SUB設定
					for (LeadIndex__c leadIdx : [select id from leadIndex__c where ParentLeadIndxRef__c = :parlead.LeadIndexRef__c and ParentFlg__c = true]) {
						mainSub = leadIdx;
					}
					// 該当インデックス親フラグ未設定の場合
					if (mainSub == null || mainSub.id == parlead.leadindexsubid__c) {
						Date entryDt = parLead.EntryTime__c.date();
						List<Lead__c> updLeads = new List<Lead__c>();
						for (Lead__c lead : [select id,Name from lead__c where LeadIndexRef__c = :parLead.LeadIndexRef__c and DAY_ONLY(convertTimezone(EntryTime__c)) >= :entryDt and leadindexsubid__c = :parlead.leadindexsubid__c and roomgroupno__c = :parLead.roomgroupno__c]){
							// 做成小部屋后，原予约数据的名称追加マーク
							String newLeadName = lead.Name;
							if (!newLeadName.startsWith(LEAD_NAME_PREFIX)) {
								newLeadName = LEAD_NAME_PREFIX + ' ' +newLeadName;
								lead.Name = newLeadName;
								updLeads.add(lead);
							}
						}
						if (!updLeads.isEmpty()) update updLeads;
						// 親部屋フラグ設定
						if (mainSub == null) update new leadIndex__c(id = parlead.leadindexsubid__c , ParentFlg__c = true);
					}
				}
			} else {
			// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy END
			// 予約インデックス情報を作成する 2012/08/23 ADD BEGIN
			LeadIndex__c newLeadIndex = new LeadIndex__c();
			//　到着日
			newLeadIndex.EntryDate__c = newLead.EntryTime__c.date();
			//　到着時刻
			newLeadIndex.EntryTime__c = newLead.field4__c;
			//　出発日
			newLeadIndex.DepartureDate__c = newLead.Departure__c.date();
			//　出発時刻
			newLeadIndex.DepartureTime__c = newLead.field3__c;
			//　お客様
			newLeadIndex.contactRef__c = newLead.Relcontact__c;
			//　発生源
			newLeadIndex.EventSource__c = 'FromUI';
			//　宿泊数
			newLeadIndex.Nights__c = newLeadIndex.EntryDate__c.daysbetween(newLeadIndex.DepartureDate__c);
			//　部屋数
			newLeadIndex.Rooms__c = roomLst.size();
			//　予約名
			newLeadIndex.LeadName__c = newLead.name;
			// 予約チャネル
			newLeadIndex.Channel__c = newLead.Field2__c;
			// セグメント
			newLeadIndex.Segment__c = newLead.Segment__c;
			// 支払方法
			newLeadIndex.Payment__c = newLead.Field315__c;
			// 特記事項
			newLeadIndex.Comment__c = newLead.Comment3__c;
			insert newLeadIndex;
			// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy BEGIN
				for (Lead__c lead : newLeads) lead.LeadIndexRef__c = newLeadIndex.id;
			}
			// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy END
			// 小部屋数据插入
			if(!newLeads.isEmpty()) {
				// 数据追加IndexSubId
				CommLogicProcess logic = new CommLogicProcess();
				logic.autoCreateRoomIndexSub(newLeads);
				// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy BEGIN
				// bug fix 6193 by zy BEGIN
				if (newLeads.size() > 1 && CommUtils.isBlank(leadId)) newLeads[0].name = LEAD_NAME_PREFIX + newLeads[0].name;
				// bug fix 6193 by zy END
				// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy END
				// 数据插入
				insert newLeads;
			}
			// 2020/04/30  複数部屋だと問題なく予約が作成される by zy BEGIN
			if (CommUtils.isBlank(leadId) || !OrderServiceHelp.getOrderItemToMaseterFlg()){
			// 2020/04/30  複数部屋だと問題なく予約が作成される by zy END
				// 予約チェックイン
				newLeads[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
				update newLeads[0];
				// その他の予約「小部屋」リンク第一予約
				List<Lead__c> childLeads = new List<Lead__c>();
				for (integer i = 1;i < newLeads.size() ; i++) {
					Lead__c lead = newLeads[i];
					lead.ParentLeadId__c = newLeads[0].id;
					childLeads.add(lead);
				}
				if (!childLeads.isEmpty()) update childLeads;
			// 2020/04/30  複数部屋だと問題なく予約が作成される by zy BEGIN
			}
			// 2020/04/30 現状の仕様ですと部屋付けをしてもあくまで「選択したテーブルの会計」に注文した商品が入力される形となりますが、実際に行いたかったのは「部屋付け先の客室の会計」に注文した商品が入力されるという挙動です。 by zy BEGIN
			String exitLeadId = !CommUtils.isBlank(leadId) && OrderServiceHelp.getOrderItemToMaseterFlg() ? leadId: newLeads[0].id ;
			// 2020/04/30 現状の仕様ですと部屋付けをしてもあくまで「選択したテーブルの会計」に注文した商品が入力される形となりますが、実際に行いたかったのは「部屋付け先の客室の会計」に注文した商品が入力されるという挙動です。 by zy END
			// 既存お客様情報設定
			List<Lead__c> exiteLeads = [select id,Rroom__c,EntryTime__c,Departure__c,field3__c,field4__c,LeadIndexSubId__c,LeadIndexRef__c,RoomGroupNo__c,CreatedDate,Field354__c,Rroom__r.name,RelContact__r.name,Name,StayNightCal__c,No__c,Rroom__r.ShopInfoRef__r.Shopcode__c,Field298__c from lead__c where id = :exitLeadId];
			// 2020/04/30  複数部屋だと問題なく予約が作成される by zy END
			pr.roomId = exiteLeads[0].Rroom__c;
			pr.leadId = exiteLeads[0].id;
			newLeads[0].RelContact__r = exiteLeads[0].RelContact__r;
			// 2020/04/30 現状の仕様ですと部屋付けをしてもあくまで「選択したテーブルの会計」に注文した商品が入力される形となりますが、実際に行いたかったのは「部屋付け先の客室の会計」に注文した商品が入力されるという挙動です。 by zy BEGIN
			if (!CommUtils.isBlank(leadId)) roomLst = OrderServiceHelp.getRoomLst(new Set<Id>{exiteLeads[0].Rroom__c});
			// 2020/04/30 現状の仕様ですと部屋付けをしてもあくまで「選択したテーブルの会計」に注文した商品が入力される形となりますが、実際に行いたかったのは「部屋付け先の客室の会計」に注文した商品が入力されるという挙動です。 by zy END
			pr.printInfo = JSON.serialize(new  Roominf(roomLst[0], exiteLeads[0],null,null));
		} catch(exception e) {
			Database.rollback(sp);
			// 2020/03/31 会計ロック機能 by zy BEGIN
			// pr.error = e.getmessage();
			pr.error = convertValidationMsg(e.getmessage());
			// 2020/03/31 会計ロック機能 by zy END
		}
		return pr;
	}
	// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy BEGIN
	private static object getCuurentLeads(String request){
		RequsetInfo req = (RequsetInfo)JSON.deserialize(request, RequsetInfo.class);
		Date curDt = CommUtils.stringToDate(req.queryDate);
		String spcd = req.shopCd;
		Integer status = CommConst.LEAD_ST_CANCEL_FLG;
		String querySQL = 'select id,Rroom__c,EntryTime__c,Departure__c,field3__c,field4__c,LeadIndexSubId__c,LeadIndexRef__c,RoomGroupNo__c,CreatedDate,Field354__c,Rroom__r.name,RelContact__r.name,Name,Field298__c,Rroom__r.ShopInfoRef__r.Shopcode__c,StayNightCal__c from Lead__c '
		+ ' where DAY_ONLY(convertTimezone(EntryTime__c)) = : curDt and CancelBool__c != :status  '
		+ ' and refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c =:spcd and ParentLeadId__c = null order by Rroom__r.name';
		List<Lead__c> leadLst = Database.query(querySQL);
		LIst<Map<String,object>> result = new LIst<Map<String,object>>();
		for (Lead__c lead : leadLst) {
			// 未割当部屋対応
			String roomName = Commutils.isBLank(lead.Rroom__r.name) ? '＊'  : lead.Rroom__r.name;
			result.add(new Map<String,Object>{'name' => roomName+ '(' + lead.relcontact__r.name + ')','id' => lead.id});
		}
		return result;
	}
	public boolean selLeadRoomFlg{get;set;}
	// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy END
	// 2013/08/16 予約名
	private static final String LEAD_NAME_PREFIX = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomDelegatePrefix__c);
	// 2020/02/15 予約が入っていないテーブルも選択可能に by zy END 
	// 2020/02/15 会計の簡易レイアウトを変更 by zy BEGIN
	// レイアウト「注文」
	private final static string MODETYPE_SIMPLE_UP = 'SIMPLE_UP';
	// 2020/02/15 会計の簡易レイアウトを変更 by zy END
	// 2020/02/15 初期画面を「テーブル選択画面」にする by zy BEGIN
	public boolean roomPageOpenFlg{get;set;} // 部屋リスト画面初期表示非表示
	// 2020/02/15 初期画面を「テーブル選択画面」にする by zy END
	// 2020/02/15 会計商品のリストを多層構造化 by zy BEGIN
	private ProductInfo processProd(Dom.xmlNode xmlNode){
		// 新規ボタン情報を取得する
		ProductInfo product = new ProductInfo();
		String strIsBlankBtn = CommUtils.nullToBlank(xmlNode.getAttribute('ISBLANK', null));
		product.isBlankBtn = CommUtils.isBlank(strIsBlankBtn) ? false  : Boolean.valueOf(strIsBlankBtn);
		if (product.isBlankBtn) return product;	// 空白ボタンの場合、次の処理を飛ばす
		// ボタン定義情報を取得する
		// 2017/10/24 商品XML設定機能追加　by　zy　BEGIN
		Dom.XmlNode btnLabelField = xmlNode.getChildElement('LABEL',null);		// ボタン表示名
		Dom.XmlNode btnNameField = xmlNode.getChildElement('NAME',null);
		// 2017/10/24 商品XML設定機能追加　by　zy　END
		Dom.XmlNode btnProdField = xmlNode.getChildElement('PRODCODE',null);	// ボタン関連の商品コード
		Dom.XmlNode btnIconField = xmlNode.getChildElement('ICONURL',null);		// ボタンに表示する画像のURL
		Dom.XmlNode btnCodeField = xmlNode.getChildElement('CODE',null);		// ボタン関連の商品コード
		// 2017/10/24 商品XML設定機能追加　by　zy　BEGIN
		if (btnNameField != null) {
			product.Name = CommUtils.nullToBlank(btnNameField.getText());
		}
		// 2017/10/24 商品XML設定機能追加　by　zy　END
		if (btnLabelField != null) {
			product.Name = CommUtils.nullToBlank(btnLabelField.getText());
		}
		if (btnProdField != null) {
			product.prodCode = CommUtils.nullToBlank(btnProdField.getText());
			prodCodeSet.add(product.prodCode);
		}
		if (btnCodeField != null) {
			product.prodCode = CommUtils.nullToBlank(btnCodeField.getText());
			prodCodeSet.add(product.prodCode);
		}
		if (btnIconField != null) {
			product.image = CommUtils.nullToBlank(btnIconField.getText());
		}
		return product;
	}
	// 2020/02/15 会計商品のリストを多層構造化 by zy END
	// 2020/03/31 会計ロック機能 by zy BEGIN
	private static String convertValidationMsg(String msg){
		msg = CommUtils.getFieldValidationMessage(msg);
		if (msg.contains(Label.MSG_006_0459)) return Label.MSG_006_0459;
		return msg;
	}
	// 2020/03/31 会計ロック機能 by zy END
	// 2020/04/30  複数部屋だと問題なく予約が作成される by zy BEGIN
	private static void preUpdateOrderMain(RequsetInfo req){
		String leadId = req.leadId;
		String accId = req.accId;
		String localIp = req.localIp;
		String oShopCode = req.shopCd;
		//打印信息
		OrderServiceHelp.LayoutType layType = OrderServiceHelp.LayoutType.ORDER;
		//打印信息
		OrderServiceHelp.PrintInfo printInfo = null;
		printInfo = OrderServiceHelp.getPrintByIp(localIp,oShopCode,layType);
		//2017/03/02 無効なディバイス対応　by　zy　BEGIN
		if (printInfo == null) {
			throw new CommException('無効なディバイスため、注文をできません、スタッフへ連絡してください!' );//localIp + 
		}
		// 2020/04/30 6231 bug fix by zy BEGIN
		if (!CommUtils.isBlank(leadId)) {
		// 2020/04/30 6231 bug fix by zy END
			List<AccountAcount__c> accLst = [select id,frs__c,TaxRate__c,name,Field145__c,Field53__c from AccountAcount__c where Relreserve__c = :leadId];
			if (accLst.isEmpty()) {
				throw new CommException('ご予約関連の会計情報を見つからないため、注文失敗になりました！');
			}
		}
	}
	// 2020/04/30  複数部屋だと問題なく予約が作成される by zy END
	// 2020/06/30 オーダエンドリーでの金額入力 by zy BEGIN
	public boolean isPriceInputFlg{get;set;}
	// 2020/06/30 オーダエンドリーでの金額入力 by zy END
}