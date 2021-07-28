/**
* 店舗情報情報取得共通クラス
* Ver1.0 店舗情報取得
* Ver1.1 2014/07/30 支店別の消費税表示文言取得機能追加
* Ver1.2 2014/10/06 会計書のレイアウトは店舗別で制御機能を追加
* Ver1.3 2014/11/12 店舗共通情報に、選択リスト<店舗、店舗名>情報をを設定する
**/
global with sharing class ShopInfoUtil {

	public static List<SelectOption> getBranchShopLst() {
		return instance.branchShopLst;
	}
	public static List<SelectOption> getBranchShopLst(String[] shopCodes) {
		if (shopCodes == null || shopCodes.size() <=1 ) return getBranchShopLst();
		else {
			List<SelectOption> shopLst = new List<SelectOption>();
			Map<String,ShopInformation__c> shopMap = getShopInfoMap();
			for (String shopcd : shopCodes) {
				if (shopMap.containsKey(shopcd)) {
					shopLst.add(new SelectOption(shopMap.get(shopcd).ShopCode__c, shopMap.get(shopcd).name));
				}
			}
			return shopLst;
		}
	}
	public static Map<String,ShopInformation__c> getShopInfoMap() {
		return instance.mapShops;
	}
	public static Map<String,ShopInformation__c> getShopInfoMap(String[] shopCodes) {
		// 店舗設定なし　または　店舗コードは一つのみ設定される場合、全て店舗を参照できる意味で認識する
		// 上記処理の理由は複数店舗を兼務したい場合、店舗コードは２店舗以上を設定する、
		if (shopCodes == null || shopCodes.size() <=1 ) return getShopInfoMap();
		else {
			Map<String,ShopInformation__c> shopMap = getShopInfoMap();
			Map<String,ShopInformation__c> shopInfoMap = new Map<String,ShopInformation__c>();
			for (String shopcd : shopCodes) {
				if (shopMap.containsKey(shopcd)) {
					shopInfoMap.put(shopMap.get(shopcd).ShopCode__c, shopMap.get(shopcd));
				}
			}
			return shopInfoMap;
		}
	}
	// 店舗情報リストを戻る
	public static List<ShopInformation__c> getBranchShopInfLst() {
		return instance.branchShopInfLst;
	}
	public static List<ShopInformation__c> getBranchShopInfLst(String[] shopCodes) {
		if (shopCodes == null || shopCodes.size() <=1 ) return getBranchShopInfLst();
		else {
			List<ShopInformation__c> shopLst = new List<ShopInformation__c>();
			Map<String,ShopInformation__c> shopMap = getShopInfoMap();
			for (String shopcd : shopCodes) {
				if (shopMap.containsKey(shopcd)) {
					shopLst.add(shopMap.get(shopcd));
				}
			}
			return shopLst;
		}
	}
	// 店舗コード情報により、内消費税表示文言を取得する[Ver1.1]
	public static String getTaxEnglishLabel(String shopCode) {
		// 店舗コードが未設定　または　TAXの設定内容はNULLの場合、カスタム設定から取得する
		if (CommUtils.isBlank(shopCode)) {
			return CommConst.APPOTION_PDF_TAXENGLISH_LABEL;
		} else {
			// 支店対応情報が店舗情報に未設定の場合、OR　店舗コードにより、支店の消費税未設定
			if (!instance.mapShops.containsKey(shopCode) ||
				CommUtils.isBlank(instance.mapShops.get(shopCode).EnglishTaxLabel__c)) {
				return CommConst.APPOTION_PDF_TAXENGLISH_LABEL;
			} else {
				return instance.mapShops.get(shopCode).EnglishTaxLabel__c;
			}
		}
	}
	// 店舗コード情報により、会計書のサビース料表示、しない制御フラグを取得する BEGIN
	public static Boolean isShowServiceCharge(String shopCode) {
		String showServiceChargeMode = getShowServiceChargeMode(shopCode);
		return (showServiceChargeMode == SERVICE_CHARGE_MODE_INNER ||
				showServiceChargeMode == SERVICE_CHARGE_MODE_OUTER);
	}
	public static final String SERVICE_CHARGE_MODE_INNER = '1';	// 明細の最後行目に表示
	public static final String SERVICE_CHARGE_MODE_OUTER = '2';	// 内消費税右下に表示
	public static String getShowServiceChargeMode(String shopCode) {
		if (CommUtils.isBlank(shopCode)) {
			return (CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().AccountServiceChargeIsShow__c));
		} else {
			// 支店対応情報が店舗情報に未設定の場合、OR　店舗コードにより、支店の消費税未設定
			if (!instance.mapShops.containsKey(shopCode) ||
				CommUtils.isBlank(instance.mapShops.get(shopCode).ServiceChargeIsShow__c) ||
				CommUtils.nullToBlank(instance.mapShops.get(shopCode).ServiceChargeIsShow__c) == '0') {
				return (CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().AccountServiceChargeIsShow__c));
			} else {
				return (CommUtils.nullToBlank(instance.mapShops.get(shopCode).ServiceChargeIsShow__c));
			}
		}
	}
	// 店舗コード情報により、会計書のサビース料表示、しない制御フラグを取得する END
    // 2017/07/21 サービス料出力金額は税込み・税抜き制御フラグ BEGIN
    // 指定店舗にサービス料出力の場合、税込みするがどうか判断関数
    // TRUE:税抜き
    // FALSE:税込み
    public static Boolean isServiceChargeIsNoTax(String shopCode) {
        // 店舗定義あり場合
        String shopServiceMode = null;
        if (instance.mapShops.containsKey(shopCode)) {
            ShopInformation__c shop = getShop(shopCode);
            shopServiceMode = (CommUtils.nullToBlank(shop.ServiceChargeIsShow__c));
        }
        // 店舗定義が非存在の場合、共通定義により、返却する
        if (CommUtils.isBlank(shopServiceMode) || shopServiceMode == '0') {
            String serviceMode = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().AccountServiceChargeIsShow__c);
            if (serviceMode == SERVICE_CHARGE_MODE_OUTER) {
                return CommDefine__c.getOrgDefaults().AccountServiceChargeNoTaxFlg__c;
            }
        } else {
            String serviceMode = (CommUtils.nullToBlank(instance.mapShops.get(shopCode).ServiceChargeIsShow__c));
            if (serviceMode == SERVICE_CHARGE_MODE_OUTER) {
                return instance.mapShops.get(shopCode).AccountServiceChargeNoTaxFlg__c;
            }
        }
        return false;
    }
    // 2017/07/21 サービス料出力金額は税込み・税抜き制御フラグ END
	// 店舗コード情報により、ステータス関連の表示色設定情報を取得する
	public static Color getStatusColor(String shopCode) {
		// 店舗コードが未設定　または　指定の支店コードは店舗情報に未設定の場合、カスタム設定から取得する
		if (CommUtils.isBlank(shopCode) || !instance.mapShops.containsKey(shopCode)) {
			return new Color(new ShopInformation__c());
		} else {
			return new Color(instance.mapShops.get(shopCode));
		}
	}
	// ログインユーザの店舗コードにより、各店舗に設定されている施設コードを取得する
	webservice static String getShopFacilityCode(String userShopCode) {
		if (CommUtils.isBlank(userShopCode)) return CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().FacilityCode__c);
		// 店舗コードにより、各店舗の施設コードを取得する
		ShopInformation__c shop = ShopInfoUtil.getShop(userShopCode);
		if (!CommUtils.isBlank(shop.FacilityCode__c)) {
			return shop.FacilityCode__c;
		} else {
			return CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().FacilityCode__c);
		}
	}
	// ログインユーザーに多店舗兼務の場合、店舗選択店舗リストを戻る
	// List<String[Shopcd]:[ShopNm]>
	webservice static List<String> getCanSelectShopLst(String userId) {
		UserUtil.UserShopInfo usrInf = UserUtil.getUserInfo(userId);
		Map<String,ShopInformation__c> shopMap = getShopInfoMap();
		List<String> shopsLst = new List<String>();
		for (String shopcd : usrInf.shops) {
			if (shopMap.containsKey(shopcd)) {
				ShopInformation__c shop = shopMap.get(shopcd);
				shopsLst.add(shop.ShopCode__c + ':' + shop.Name);
			}
		}
		return shopsLst;
	}
	//Public Methods
	public static ShopInformation__c getShop(String shopCode) {
	    if (instance.mapShops.containsKey(shopCode)) {
	        return instance.mapShops.get(shopCode);
	    }
	    else {
	        throw new CommException('Unable to locate shop code: ' + shopCode);
	    }
	}
	private static final ShopInfoUtil instance = new ShopInfoUtil();
	private Map<String, ShopInformation__c> mapShops;
	private List<SelectOption> branchShopLst{get; private set;}
	private List<ShopInformation__c> branchShopInfLst{get; private set;}
	private ShopInfoUtil() {
	    //mapShops = new Map<Id, ShopInformation__c>(queryShops());
	    mapShops = new Map<String, ShopInformation__c>();
	    branchShopLst = new List<SelectOption>();
	    branchShopInfLst = new List<ShopInformation__c>();
	    for (ShopInformation__c shop : queryShops()) {
	    	mapShops.put(shop.ShopCode__c, shop);
	    	branchShopLst.add(new SelectOption(shop.ShopCode__c, shop.name));
	    	branchShopInfLst.add(shop);
	    }
	}
	//Private Methods
	private List<ShopInformation__c> queryShops() {
	    return [SELECT 
	                Id
	                , Name
	                , Phone__c
	                , Post__c
	                , Address__c
	                , ShopCode__c
	                , TierDefault__c
	                , PeopleDefault__c
	                , EnglishTaxLabel__c	// 内消費税英語表示文言
	                // 2014/08/29 色のカスタムマイズ情報を取得
	                //, ColorRSRoomVacancy__c	// 色_ルームインジケータ_空室
	                , ColorRSRoomAssigned__c	// 色_ルームインジケータ_割当済
	                // 2019/02/28 滞在・外出状態の管理 WGCH BEGIN
	                , ColorRSRoomOut__c	// 色_ルームインジケータ_外出
	                // 2019/02/28 滞在・外出状態の管理 WGCH END
	                , ColorRSRoomStay__c	// 色_ルームインジケータ_滞在
	                , ColorRSRoomChkOutDay__c	// 色_ルームインジケータ_出発予定
	                , ColorRSRoomChkOut__c	// 色_ルームインジケータ_出発
	                , ColorRSRoomBad__c		// 色_ルームインジケータ_故障
	                , ColorRSRoomNoClean__c	// 色_ルームインジケータ_未清掃
	                , FacilityCode__c		// 施設コード
	                // 2016/03/21 サビース料別表示制御フラグを取得する
	                , ServiceChargeIsShow__c	// サビース料別表示
	                // 2017/03/10 页面自动刷新功能  begin by wx 
	                , RoomScheduleTimerMinute__c  // タイムテーブルページ更新のインターバルタイマ
	                // 2017/03/10 页面自动刷新功能  end by wx
	                // 2017/07/21 サービス料出力金額は税込み・税抜き制御フラグ BEGIN
	                , AccountServiceChargeNoTaxFlg__c
	                // 2017/07/21 サービス料出力金額は税込み・税抜き制御フラグ END
	                // 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
	                , BathTaxAccMstRef__c
	                // 2020/07/30 入湯税の自動入力機能について改善 WGCH END
	                , Seq__c
	            FROM
	                ShopInformation__c
	            order by Seq__c    
	            Limit 5000];
	}
	/**
	* 各画面のステータスの色制御情報クラス
	**/
	public class Color {
		public Color(ShopInformation__c shop) {
			/*
			RS_RoomVacancy = 	CommUtils.isBlank(shop.ColorRSRoomVacancy__c) 
							?	CommDefine__c.getOrgDefaults().ColorRSRoomVacancy__c
							:	shop.ColorRSRoomVacancy__c;
			*/
			RS_RoomAssigned = 	CommUtils.isBlank(shop.ColorRSRoomAssigned__c) 
							?	CommDefine__c.getOrgDefaults().ColorRSRoomAssigned__c
							:	shop.ColorRSRoomAssigned__c;
			if (CommUtils.isBlank(RS_RoomAssigned)) RS_RoomAssigned = '#00ccff';
			// 2019/02/28 滞在・外出状態の管理 WGCH BEGIN
			RS_RoomOut = 	CommUtils.isBlank(shop.ColorRSRoomOut__c) 
							?	CommDefine__c.getOrgDefaults().ColorRSRoomOut__c
							:	shop.ColorRSRoomOut__c;
			if (CommUtils.isBlank(RS_RoomOut)) RS_RoomOut = '#CCCCCC';
			// 2019/02/28 滞在・外出状態の管理 WGCH END
			RS_RoomStay = 	CommUtils.isBlank(shop.ColorRSRoomStay__c) 
							?	CommDefine__c.getOrgDefaults().ColorRSRoomStay__c
							:	shop.ColorRSRoomStay__c;
			if (CommUtils.isBlank(RS_RoomStay)) RS_RoomStay = '#90EE90';		
			RS_RoomChkOutDay = 	CommUtils.isBlank(shop.ColorRSRoomChkOutDay__c) 
							?	CommDefine__c.getOrgDefaults().ColorRSRoomChkOutDay__c
							:	shop.ColorRSRoomChkOutDay__c;
			if (CommUtils.isBlank(RS_RoomChkOutDay)) RS_RoomChkOutDay = '#FDD017';			
			RS_RoomChkOut = 	CommUtils.isBlank(shop.ColorRSRoomChkOut__c) 
							?	CommDefine__c.getOrgDefaults().ColorRSRoomChkOut__c
							:	shop.ColorRSRoomChkOut__c;
			if (CommUtils.isBlank(RS_RoomChkOut)) RS_RoomChkOut = '#F75D59';			
			RS_RoomBad = 	CommUtils.isBlank(shop.ColorRSRoomBad__c) 
							?	CommDefine__c.getOrgDefaults().ColorRSRoomBad__c
							:	shop.ColorRSRoomBad__c;
			if (CommUtils.isBlank(RS_RoomBad)) RS_RoomBad = '#2554C7';
								
			RS_RoomNoClean = 	CommUtils.isBlank(shop.ColorRSRoomNoClean__c) 
							?	CommDefine__c.getOrgDefaults().ColorRSRoomNoClean__c
							:	shop.ColorRSRoomNoClean__c;
			if (CommUtils.isBlank(RS_RoomNoClean)) RS_RoomNoClean = '#B0C4DE';
		}
		//public String RS_RoomVacancy	{get; private set;}
		public String RS_RoomAssigned	{get; private set;}
		// 2019/02/28 滞在・外出状態の管理 WGCH BEGIN
		public String RS_RoomOut		{get; private set;}
		// 2019/02/28 滞在・外出状態の管理 WGCH BEGIN
		public String RS_RoomStay		{get; private set;}
		public String RS_RoomChkOutDay	{get; private set;}
		public String RS_RoomChkOut		{get; private set;}
		public String RS_RoomBad		{get; private set;}
		public String RS_RoomNoClean	{get; private set;}
	}
	
	/**
	*　店舗別泊数、到着時刻、出発時刻情報取得する
	**/
	public static ShopLeadInfo getShopDefInfo(String shopCd) {
	    // 共通定義により、指定の泊数、到着時刻[HH:MM]、出発時刻[HH:MM]情報を取得する
	    // 店舗コード1,店舗コード2:1,16:00,09:00;店舗コード3:0,12:00,14:00
	    String comDefLeadInfo = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().ShopLeadDefaultInfo__c);
	    return new ShopLeadInfo(comDefLeadInfo, CommUtils.nullToBlank(shopCd));
	}
	public class ShopLeadInfo {
	    public ShopLeadInfo(String comdefVal,String pSpcd) {
	        isDefaultFlg = true;
	        try {
		        if (!CommUtils.isBlank(comdefVal)) {
		            // 定義情報から取得、引き渡す店舗コードと比較して、定義存在する場合、該当定義情報により、設定する
		            List<String> shopDefLst = comdefVal.split(';');
		            for (String s : shopDefLst) {
		                // 店舗コード1,店舗コード2&泊数,到着時刻,出発時刻
		                List<String> ss = s.split('&');
		                // 定義値を取得する
		                if (ss.size () == 2) {
		                    // 店舗コード情報:店舗コード1,店舗コード2,店舗コード3
		                    List<String> shopcds = ss[0].split(',');
		                    // 店舗の予約情報
		                    List<String> leadDefs = ss[1].split(',');
		                    for (String spcd : shopcds) {
		                        // 店舗コードと一致する場合
		                        if (CommUtils.nullToBlank(spcd) == pSpcd) {
		                            // 該当店舗の設定情報をチェックする、条件を満足すると、設定値を設定する
		                            if (leadDefs.size() >= 3) {
		                                // 泊数、到着時刻、出発時刻を取得、クラス変数に設定する
		                                if (!CommUtils.isBlank(leadDefs[0]) && !CommUtils.isBlank(leadDefs[1]) && !CommUtils.isBlank(leadDefs[2])) {
		                                    // 泊数
	                                        defStayNums = CommUtils.nullToIntZero(leadDefs[0]);
		                                    defCheckInTime = CommUtils.objectToTime(leadDefs[1]);
		                                    defCheckOtTime = CommUtils.objectToTime(leadDefs[2]);
		                                    defCheckInTimeStr = leadDefs[1];
		                                    defCheckOtTimeStr = leadDefs[2];
		                                    isDefaultFlg = false;
		                                    break;
		                                }
		                            }
		                        }
		                    }
		                    if (!isDefaultFlg) break;
		                }
		            }
		        }
	        } catch (Exception e){}
	        if (isDefaultFlg) {
                defStayNums = 1;
                defCheckInTime = CommConst.defCheckInTime;
                defCheckOtTime = CommConst.defCheckOtTime; 
                defCheckInTimeStr = CommConst.DEF_CHECKIN_TIME;
		        defCheckOtTimeStr = CommConst.DEF_CHECKOT_TIME;
	        }
	        // デフォルト値が１泊以上場合、０の初期時刻と出発時刻を設定する
	        if (defStayNums == 0) {
	            defDayUseCheckInTimeStr = defCheckInTimeStr;
	            defDayUseCheckOtTimeStr = defCheckOtTimeStr;
	        } else {
	            defDayUseCheckInTimeStr = CommConst.DEF_DAYUSE_CHECKIN_TIME;
	            defDayUseCheckOtTimeStr = (DateTime.newInstance(Date.today(), CommUtils.stringToTime(defDayUseCheckInTimeStr)).addHours(CommConst.DEF_DAYUSE_STAY_HOURS)).format('HH:mm');
	        }
	    }
	    public Boolean isDefaultFlg{get;private set;}
	    public Integer defStayNums{get;private set;}               // デフォルト値泊数
	    public Time defCheckInTime{get;private set;}
	    public Time defCheckOtTime{get;private set;}
	    public string defCheckInTimeStr{get;private set;}          // 到着時刻
	    public string defCheckOtTimeStr{get;private set;}          // 出発時刻
	    public string defDayUseCheckInTimeStr{get; private set;}   // DAYUSEのデフォルト到着時刻
	    public string defDayUseCheckOtTimeStr{get; private set;}   // DAYUSEのデフォルト出発時刻
	}
	// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
	webservice static List<String> getAccSelect() {
		List<String> mrTypeLst = new List<String>();
		Schema.DescribeFieldResult fieldResult = AccountAcount__c.RespectLst__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
	   	for( Schema.PicklistEntry f : ple) {
	   		String labelVal = f.getLabel() +':'+ f.isDefaultValue();
	   		mrTypeLst.add(labelVal);
	   	}
	   	return mrTypeLst;
	}
	webservice static List<String> getLeadSelect() {
		List<String> mrTypeLst = new List<String>();
		Schema.DescribeFieldResult fieldResult = Lead__c.RespectLst__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
	   	for( Schema.PicklistEntry f : ple) {
	   		String labelVal = f.getLabel() +':'+ f.isDefaultValue();
	   		mrTypeLst.add(labelVal);
	   	}
	   	return mrTypeLst;
	}
    public static String RESPECT_DEFAULTVALUE{get{
    	List<Selectoption> mrTypeLst = new List<Selectoption>();
		Schema.DescribeFieldResult fieldResult = Lead__c.RespectLst__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		String DefaultVal = '';
	   	for( Schema.PicklistEntry f : ple) {
	   		if(f.isDefaultValue()) return f.getLabel();
	   	}
	   	return DefaultVal;
    }}
	// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
	// 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH BEGIN
	webservice static String shopDefCdSetMode{get{return CommConst.SHOP_DEFCODESET_MODE;}}
	public static String getShopDefCd(String shopCd, String ldShopCd, String userShopCd){
		return ShopInfoUtil.getShopDefCd(shopCd, ldShopCd, userShopCd, true);
	}
	webservice static String getShopDefCd(String shopCd, String ldShopCd, String userShopCd, Boolean isRefLeadFlg){
		// 予約の部屋タイプに紐づいた店舗ロゴ场合
		if(shopDefCdSetMode == CommConst.SHOP_DEFCODESET_MODE_1){
			if(isRefLeadFlg) shopCd = CommUtils.nullToBlank(ldShopCd);
		}
		// ユーザの所属店舗ロゴ场合
		else if(shopDefCdSetMode == CommConst.SHOP_DEFCODESET_MODE_2) shopCd = CommUtils.nullToBlank(userShopCd);
		return shopCd;
	}
	// 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH END
	// 2021/07/30 #JP10785 by zy BEGIN
	// ログインユーザーに多店舗兼務の場合、指定予約に全部関連予約を取得
	// List<Lead__c>
	webservice static String getLeadInfo(String leadId,String shopCode) {
		return (new ApplicationFormPDFExt1()).getLeadindexByLeads(leadId,shopCode);
	}
	// 2021/07/30 #JP10785 by zy END
}