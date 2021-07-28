/***************************
* WS処理機能共通ヘルプクラス
* 2016/01/29 リアル（旅行会社）に対して、在庫更新要求を発行する・しない制御パラメータを追加
* 2016/03/22 お客様情報解析用情報の格納
* 2016/05/12 事前決済区分と登録の支払商品情報マッピング
* 2016/06/10 子供料金プラン取り込み機能対応
* 2016/08/08 インターバル定義情報は最小90秒まで定義できる変更
* 2016/10/16 ネット取り込みエラーの場合、リトライ処理をする・しない制御処理追加
* 2017/02/21 お子様プランの料金PRICE機能追加 
* 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応
* 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応
* 2018/01/17 取引先責任者の重複ルールが有効しても、無効よう対応できる改善
* 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する
* 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善
* 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加
****************************/
public with sharing class WS_ServiceConfigHelp {
	
	public enum ProcessingType{TL,TA,TR,JR,WS}
	public static final Integer DEF_MIN_INTERVAL = 90;//最小90秒
	private static WS_ServiceConfigHelp instance = null;
	private static WS_ServiceConfigHelp getInstance() {
		if(instance == null) instance = new WS_ServiceConfigHelp();
		return instance;
	}
	// WS連動機能設定ファイル名
	private static final String XmlConfigName = 'WSServiceConfigXml';

	private WS_ServiceConfigHelp() {
		// XML LOADINGから定義情報を格納する
		mapAppConfig = new map<String, APPCONFIG>();
		//mapErrConfig = new map<String, ERRCONFIG>(); 
		mapAccConfig = new map<String, ACCOUNTCONFIG>();
        //mapBookingConfig = new map<String,BOOKINGCONFIG>();
		// PLANコード変換表 map<店舗コード, map<AGT名,map<agtのPacakgeコード，sfのプランNo）
		mapPlanConvertAgt2SfMap = new map<String, map<String, map<string, string>>>();
        // 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応 by zh BEGIN
        mapPlanConvertAgt2SfNameFlgMap = new map<String, Boolean>();
        // 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応 by zh END
		// 2016/03/22 お客様情報解析用情報の格納
		mapContactConfig = new map<String, list<CONTACT_INFO_PARSE>>();
		// 2016/05/12 事前決済区分と登録の支払商品情報マッピング
		mapPaymentConfig = new map<String ,map<String, PAYMENT_CONVERT>>();
		mapPointConfig = new map<String ,map<String, PAYMENT_CONVERT>>();
		// 2016/06/10 子供料金プラン取り込み機能対応 BEGIN
		mapChildPlanConvertConfig = new map<String, map<string, string>>(); 		
		// 2017/02/21 お子様プランの料金PRICE機能追加 by zh BEGIN
		mapChildPlanPriceConvertConfig = new map<String, map<string, string>>(); 
		// 2017/02/21 お子様プランの料金PRICE機能追加 by zh END
		// 2016/06/10 子供料金プラン取り込み機能対応 END
		// 2016/07/10 予約チャネル名の変換機能追加対応 BEGIN
		mapAgtToChanelConfig = new map<String, map<string, string>>(); 
		// 2016/07/10 予約チャネル名の変換機能追加対応 END
		// 2017/12/13 2.BookingAPIの通知メールのテンプレート定義の対応 by zy BEGIN
		mapEmailTemplateMap = new map<String, EmailTemp >();
		// 2017/12/13 2.BookingAPIの通知メールのテンプレート定義の対応 by zy END
		// 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ BEGIN
		mapChildPlanNameConvertConfig = new map<String, map<string, string>>(); 
		// 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ END
		// XMLに定義する全て情報を格納する
		List<Dom.XmlNode> topNodeXmlList = CommXmlUtils.getAllTopXmlNode(XmlConfigName,new List<String>{'<PASSWORD>','</PASSWORD>'});
		// XML NODE
		for (Dom.XmlNode node : topNodeXmlList) {
			// XML TAG
			string xmlTagName = node.getName();
			if(xmlTagName.equals('COMMON')){
				commConfig = new COMMCONFIG(node);
			} else if (xmlTagName.equals('SHOP')) {
				Dom.XmlNode shopcode =  node.getChildElement('SHOPCODE', null);
				String strShopCode = CommUtils.nullToBlank(shopcode.getText());
				mapAppConfig.put(strShopCode, new APPCONFIG(node));
				//mapErrConfig.put(strShopCode, new ERRCONFIG(node));
				mapAccConfig.put(strShopCode, new ACCOUNTCONFIG(node));
                //mapBookingConfig.put(strShopCode, new BOOKINGCONFIG(node));
				// AGT名単位のプラン変換処理情報の格納
				mapPlanConvertAgt2SfMap.put(strShopCode, parsePlanConvertParse(strShopCode, node));
				// 2016/03/22 お客様情報解析用情報の格納
				mapContactConfig.put(strShopCode, parseContactInfo(node));
				// 2016/05/12 事前決済区分と登録の支払商品情報マッピング
				mapPaymentConfig.put(strShopCode, parsePaymentInfo(node));
				mapPointConfig.put(strShopCode, parsePointInfo(node));
				// 2016/06/10 子供料金プラン取り込み機能対応 BEGIN
				// 2017/02/21 お子様プランの料金PRICE機能追加 by zh BEGIN
				//mapChildPlanConvertConfig.put(strShopCode, parseChildPlanConvert(node));
				map<string,map<string,string>> wkChildPlanConvertMap = parseChildPlanConvert(node);
				mapChildPlanConvertConfig.put(strShopCode, wkChildPlanConvertMap.get(DEF_CHILDPLAN_RATE));
				mapChildPlanPriceConvertConfig.put(strShopCode, wkChildPlanConvertMap.get(DEF_CHILDPLAN_PRICE));
				// 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ BEGIN
				mapChildPlanNameConvertConfig.put(strShopCode, wkChildPlanConvertMap.get(DEF_CHILDPLAN_NAMEONLY));
				// 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ END
				// 2017/02/21 お子様プランの料金PRICE機能追加 by zh END
				// 2016/06/10 子供料金プラン取り込み機能対応 END
				// 2016/07/10 予約チャネル名の変換機能追加対応 BEGIN
				mapAgtToChanelConfig.put(strShopCode, parseAGTToChanelConvert(node));
				// 2016/07/10 予約チャネル名の変換機能追加対応 END
				// 2017/12/13 2.BookingAPIの通知メールのテンプレート定義の対応 by zy BEGIN
				mapEmailTemplateMap.put(strShopCode,parseEmailTemplate(node));
				// 2017/12/13 2.BookingAPIの通知メールのテンプレート定義の対応 by zy END
			}
			
		}
		if (commConfig == null) commConfig = new COMMCONFIG();
	}
	
	private map<String, APPCONFIG> mapAppConfig;
	//private map<String, ERRCONFIG> mapErrConfig;
	private map<String, ACCOUNTCONFIG> mapAccConfig;
    //private map<String, BOOKINGCONFIG> mapBookingConfig;
    // 2016/03/22 お客様情報解析用情報の格納
    private map<String, List<CONTACT_INFO_PARSE>> mapContactConfig;
    // 2016/05/12 事前決済区分と登録の支払商品情報マッピング
    private map<String, map<string,PAYMENT_CONVERT>> mapPaymentConfig;
    private map<String, map<string,PAYMENT_CONVERT>> mapPointConfig;
    // 2016/07/10 予約チャネル名の変換機能追加対応
    private map<String, map<String,String>> mapAgtToChanelConfig;
	private COMMCONFIG commConfig;
	// AGT単位のプランコードはSF側のプランNOと変換情報の格納
	private map<String, map<String,map<String, String>>> mapPlanConvertAgt2SfMap;
    // 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応 by zh BEGIN
    private map<String, Boolean> mapPlanConvertAgt2SfNameFlgMap;
    // 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応 by zh END

	// 該当店舗コードはWSサイトコントローラと契約済がどうかチェックを行う
	// 2016/06/10 子供料金プラン取り込み機能対応 BEGIN
	private map<String, map<String,String>> mapChildPlanConvertConfig;	// 子供料金変換ルール情報格納
	// 2017/02/21 お子様プランの料金PRICE機能追加 by zh BEGIN
	private map<String, map<string,string>> mapChildPlanPriceConvertConfig;	
	// 2017/02/21 お子様プランの料金PRICE機能追加 by zh END
	// 2016/06/10 子供料金プラン取り込み機能対応 END
	// 2017/12/13 2.BookingAPIの通知メールのテンプレート定義の対応 by zy BEGIN
	private map<String, EmailTemp> mapEmailTemplateMap;
	// 2017/12/13 2.BookingAPIの通知メールのテンプレート定義の対応 by zy END
	// XMLの中に、該当店舗コードを定義されていると、契約済として、判断する
	/*
	public static Boolean isContractShop(String shopCd) {
		return getInstance().mapAppConfig.containsKey(shopCd);
	}
	// XMLに定義情報存在チェツク、SHOPタグ定義情報がない場合、WS連携機能を起動しません
	public static Boolean tlSyncIsOpen() {
		return (getInstance().mapAppConfig.size() > 0);
	}*/
	// ****************************************
	// WS連携処理、共通定義パラメータ情報を取得する
	// ****************************************
	public static COMMCONFIG getCommConfig () {
		return getInstance().commConfig;
	}
	// ****************************************
	// WS連携処理、共通定義パラメータ情報のみを取得する
	// ****************************************
	public static COMMCONFIG getCommConfigOnly() {
	    // 共通定義クラス
	    COMMCONFIG retCommConfig;
	    try {
	        // XMLに定義する全て情報を格納する
	        List<Dom.XmlNode> topNodeXmlList = CommXmlUtils.getAllTopXmlNode(XmlConfigName,new List<String>{'<PASSWORD>','</PASSWORD>'});
	        // XML NODE
	        for (Dom.XmlNode node : topNodeXmlList) {
	            // XML TAG
	            string xmlTagName = node.getName();
	            if(xmlTagName.equals('COMMON')){
	                retCommConfig = new COMMCONFIG(node);
	                break;
	            }
	        }
	    } catch (Exception e) {}
        if (retCommConfig == null) retCommConfig = new COMMCONFIG();
        return retCommConfig;
	}
	// ****************************************
	// WS連携処理、各店舗個別定義必要情報取得する
	// shopCd : 店舗コード
	// return : 該当店舗の定義情報を戻る
	// exception: 該当店舗コードはXMLに未定義されている場合、エラー戻る
	// ****************************************
	public static APPCONFIG getAppConfig(String shopCd) {
		if (getInstance().mapAppConfig.containsKey(shopCd)) {
			return getInstance().mapAppConfig.get(shopCd);
		} else {
			//指定の店舗コードの定義情報を見つかりません。
			throw new CommException(Label.MSG_038_0023 + '['+shopCd+']');
		}
		
	}
	// ****************************************
	// WS連携処理、エラー処理情報の格納
	// shopCd : 店舗コード
	// return : 該当店舗の定義情報を戻る
	// exception: 該当店舗コードはXMLに未定義されている場合、エラー戻る
	/*
	public static ERRCONFIG getErrConfig(String shopCd) {
		if (instance.mapErrConfig.containsKey(shopCd)) {
			return instance.mapErrConfig.get(shopCd);
		} else {
			throw new CommException('指定の店舗コードの定義情報を見つかりません。['+shopCd+']');
		}
	}*/
	
	// ****************************************
	// WS連携処理、エラー処理情報の格納
	// shopCd : 店舗コード
	// return : 該当店舗の定義情報を戻る
	// exception: 該当店舗コードはXMLに未定義されている場合、エラー戻る
	public static ACCOUNTCONFIG getAccountConfig(String shopCd) {
		if (getInstance().mapAccConfig.containsKey(shopCd)) {
			return getInstance().mapAccConfig.get(shopCd);
        } else {
        	//指定の店舗コードの定義情報を見つかりません。
            throw new CommException(Label.MSG_038_0023 + '['+shopCd+']');
        }
    }
    /*
    public static BOOKINGCONFIG getBookingConfig(String shopCd){
        if (instance.mapBookingConfig.containsKey(shopCd)) {
            return instance.mapBookingConfig.get(shopCd);
		} else {
			throw new CommException('指定の店舗コードの定義情報を見つかりません。['+shopCd+']');
		}
	}
	*/
	// ****************************************
	// WS連携処理、AGTのパッケージコードにより、SFのプランNO情報を取得する
	// shopCd:			店舗コード
	// agtCode : 		AGTコード
	// packageCode:		AGT側に定義しているパッケージコード
	// return : 		該当AGTパッケージコードからSF側のプランコード値を戻る
	//						該当戻る値はNULLの場合、AGTのパッケージコードはSF側のプランコードとリンクしません
	// exception: 		該当店舗コードはXMLに未定義されている場合、エラー戻る
	public static String getSfPlanNoByAgtPlanInfo(String shopCd, String agtCode, String packageCode) {
		if (getInstance().mapPlanConvertAgt2SfMap.containsKey(shopCd)) {
			// AGT 存在チェック
			map<String, map<String,String>> agtConvertMap = getInstance().mapPlanConvertAgt2SfMap.get(shopCd);
			if (getInstance().agtInfoMaps == null) {
				map<String, Account> locAgtInfoMaps = new map<String, Account>();
				for (Account acc : [select id, name, SalesOfficeCompanyCodeTL__c from Account where AccountType__c = :CommConst.ACCOUNT_TYPE_TRAVEL and SalesOfficeCompanyType__c != null And SalesOfficeCompanyCodeTL__c != null order by CreatedDate desc  ]) {
					if (!locAgtInfoMaps.containsKey(acc.SalesOfficeCompanyCodeTL__c)) locAgtInfoMaps.put(acc.SalesOfficeCompanyCodeTL__c, acc);
				}
				getInstance().agtInfoMaps = locAgtInfoMaps.clone();
			}
//System.debug(loggingLevel.INFO, 'instance.agtInfoMaps:::' + instance.agtInfoMaps);
			// コードから名を取得する
			if (getInstance().agtInfoMaps.containsKey(agtCode)) {
				String agtName = getInstance().agtInfoMaps.get(agtCode).Name;
				if (agtConvertMap.containsKey(agtName)) {
					map<string, String> planConvertmap = agtConvertMap.get(agtName);
					// 該当パッケージコードからプランNOを戻る
					return planConvertmap.get(packageCode);
				}
			}
		}
		return null;
	}
	private map<String, Account> agtInfoMaps;
	// AGTパッケージコードからSF側のプランNoのマッピング情報の解析	
	private map<string, map<String,String>> parsePlanConvertParse(String shopCd, Dom.XmlNode shopNode){
		map<string, map<string,string>> convertMap = new map<String, map<String,String>>();
		Dom.XmlNode planConvertNode = shopNode.getChildElement('PLANCODE_CONVERT', null);  
		if (planConvertNode == null) return convertMap;
		Dom.XmlNode[] agtNodes = planConvertNode.getChildElements(); 
		// 該当AGTのプラン変換情報を取得する
		for (Dom.XmlNode agtNode : agtNodes) {
			String agtName = CommUtils.nullToBlank(agtNode.getAttribute('NAME',null));
			if (CommUtils.isBlank(agtName)) continue;
			map<String, String> agtConvertMap = new map<String, String>();
			convertMap.put(agtName, agtConvertMap);
			Dom.XmlNode[] converts = agtNode.getChildElements(); 
			for (Dom.XmlNode convert : converts) {
				Dom.XmlNode agtPlanPackageCdField = convert.getChildElement('AGTPACKAGECODE', null);
    			Dom.XmlNode sfPlanNoField = convert.getChildElement('SFPLANNO', null);
    			String agtPlanPackageCdValue = null;
    			String sfPlanNoValue = null;
    			if(agtPlanPackageCdField != null) agtPlanPackageCdValue = CommUtils.nullToBlank(agtPlanPackageCdField.getText()).deleteWhitespace();
    			if(sfPlanNoField != null) sfPlanNoValue = CommUtils.nullToBlank(sfPlanNoField.getText());
    			if (CommUtils.isBlank(agtPlanPackageCdValue) || CommUtils.isBlank(sfPlanNoValue)) continue;
    			//if (!agtConvertMap.containsKey(sfPlanNoValue)) convertMap.put(sfPlanNoValue, new map<String,String>());
    			//convertMap.get(sfPlanNoValue).addAll(agtPlanPackageCdValue.split(','));
    			for (String agtPackageCd : agtPlanPackageCdValue.split(',')) {
    				agtConvertMap.put(agtPackageCd, sfPlanNoValue);
    			}
			}
		}
        // 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応 by zh BEGIN
        Boolean isSfPlanNmToEstProdNm = false;
        String strIsSfPlanNmToEstProdNm = CommUtils.nullToBlank(planConvertNode.getAttribute('ESTNAMEBYSF',null));
        if (!CommUtils.isBlank(strIsSfPlanNmToEstProdNm)) isSfPlanNmToEstProdNm = Boolean.valueOf(strIsSfPlanNmToEstProdNm);
        mapPlanConvertAgt2SfNameFlgMap.put(shopCd, isSfPlanNmToEstProdNm);
        // 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応 by zh END
		return convertMap;
	}
    // 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応 by zh BEGIN
    public static Boolean isSfPlanNmToEstProdNm(String shopCd) {
        if (instance.mapPlanConvertAgt2SfNameFlgMap.containsKey(shopCd)) {
            return instance.mapPlanConvertAgt2SfNameFlgMap.get(shopCd);
        }
        return false;
    }
    // 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応 by zh END

	// 2016/03/22 お客様情報解析用情報の格納 BEGIN
	// ****************************************
	// WS連携処理、エラー処理情報の格納
	// shopCd : 店舗コード
	// return : 該当店舗の定義情報を戻る
	// exception: 該当店舗コードはXMLに未定義されている場合、エラー戻る
	public static list<CONTACT_INFO_PARSE> getContactConfig(String shopCd) {
		if (getInstance().mapContactConfig.containsKey(shopCd)) {
			return getInstance().mapContactConfig.get(shopCd);
        } else {
        	//指定の店舗コードの定義情報を見つかりません。
            throw new CommException(Label.MSG_038_0023 + '['+shopCd+']');
        }
    }
	// 2016/03/22 お客様情報解析用情報の格納 END
	
	// 共通定義情報の格納
	public class COMMCONFIG { 
		public COMMCONFIG() {
			bIsDebug = false;
			mLeadTimeLimit = 60000;
			// 2017/12/28 メール本文の通知指定名　by　zy　BEGIN
			emailInsDevName = 'BookingApiSiteLeadFeedBackMailNotifyIns';
			emailUpdDevName = 'BookingApiSiteLeadFeedBackMailNotifyUpd';
			emailCanDevName = 'BookingApiSiteLeadFeedBackMailNotifyCancel';
			// 2017/12/28 メール本文の通知指定名　by　zy　END
		}
		public COMMCONFIG(Dom.XmlNode node){
			/*
			Dom.XmlNode stockIntervalField = node.getChildElement('STOCKINTERVAL', null);
			Dom.XmlNode leadImpIntervalField = node.getChildElement('LEADINTERVAL', null);
			Dom.XmlNode stockDeleteValField = node.getChildElement('STOCKDELETEVAL', null);
			Dom.XmlNode leadDeleteValField = node.getChildElement('LEADDELETEVAL', null);
			
			mStockInterval = (stockIntervalField == null) ? 60 : CommUtils.nullToIntZero(stockIntervalField.getText());
			mStockDeleteVal = (stockDeleteValField == null) ? -14 : CommUtils.nullToIntZero(stockDeleteValField.getText());
			mLeadImportInterval = (leadImpIntervalField == null) ? 60 :CommUtils.nullToIntZero(leadImpIntervalField.getText());
			mLeadDeleteVal = (leadDeleteValField == null) ? -14 : CommUtils.nullToIntZero(leadDeleteValField.getText());
			// 2016/08/08 インターバル定義情報は最小90秒まで定義できる変更 BEGIN
			// 最小３０秒単位
			//if (mStockInterval <= 30) mStockInterval = 30;
			//if (mLeadImportInterval <= 30) mLeadImportInterval = 30;
			if (mStockInterval <= DEF_MIN_INTERVAL) mStockInterval = DEF_MIN_INTERVAL;
			if (mLeadImportInterval <= DEF_MIN_INTERVAL) mLeadImportInterval = DEF_MIN_INTERVAL;
			// 2016/08/08 インターバル定義情報は最小90秒まで定義できる変更 END
			if (mStockDeleteVal == null) mStockDeleteVal = -14;
			if (mLeadDeleteVal == null) mLeadDeleteVal = -14;
			// SITE URL
			Dom.XmlNode serviceUrlField = node.getChildElement('SERVICE_URL', null);
			strServiceUrl = (serviceUrlField == null) ? 'https://test472.ws-lincoln.net' : CommUtils.nullToBlank(serviceUrlField.getText());
	    	*/
			//DEBUG MODE NODE
			Dom.XmlNode isDebugField = node.getChildElement('ISDEBUG', null);
			bIsDebug = (isDebugField == null) ? false : Boolean.valueOf(CommUtils.nullToBlank(isDebugField.getText()));
			// XXミリ秒以内すると、予約インデックスと同時に作成される予約情報（2015/12/14)
			mLeadTimeLimit = 60000;	// １分以内
			Dom.XmlNode mLeadTimeLimitField = node.getChildElement('TARGET_LEAD_TIMELIMIT', null);
			if (mLeadTimeLimitField != null) mLeadTimeLimit = CommUtils.nullToIntZero(mLeadTimeLimitField.getText());
			// 2017/12/28 メール本文の通知指定名　by　zy　BEGIN
			Dom.XmlNode notifyTempNode = node.getChildElement('NOFITY_TEMPLATE', null);
			emailInsDevName = 'BookingApiSiteLeadFeedBackMailNotifyIns';
			emailUpdDevName = 'BookingApiSiteLeadFeedBackMailNotifyUpd';
			emailCanDevName = 'BookingApiSiteLeadFeedBackMailNotifyCancel';
			if (notifyTempNode != null) {
				Dom.XmlNode insTempNode = notifyTempNode.getChildElement('INS_TEMPLATE_DEV_NAME', null);
				Dom.XmlNode updTempNode = notifyTempNode.getChildElement('UPD_TEMPLATE_DEV_NAME', null);
				Dom.XmlNode canTempNode = notifyTempNode.getChildElement('DEL_TEMPLATE_DEV_NAME', null);
				if (insTempNode != null && !CommUtils.isBlank(insTempNode.getText())) emailInsDevName = insTempNode.getText();
				if (updTempNode != null && !CommUtils.isBlank(updTempNode.getText())) emailUpdDevName = updTempNode.getText();
				if (canTempNode != null && !CommUtils.isBlank(canTempNode.getText())) emailCanDevName = canTempNode.getText();
			}
			// 2017/12/28 メール本文の通知指定名　by　zy　END
            /*
            // 処理日から在庫調整最大日数（デイフォル：180日まで）（2015/12/14)
            syncMaxDays = 180;
			Dom.XmlNode syncMaxDaysFields = node.getChildElement('STOCK_SYNC_MAX_DAYS', null);
			if (syncMaxDaysFields != null) syncMaxDays = CommUtils.nullToIntZero(syncMaxDaysFields.getText());
			
			bIsSyncOnlyNewFlg = true;
			Dom.XmlNode bIsSyncOnlyNewFlgFields = node.getChildElement('STOCK_SYNC_ONLY_NEW', null);
			if (bIsSyncOnlyNewFlgFields != null) bIsSyncOnlyNewFlg = Boolean.valueOf(bIsSyncOnlyNewFlgFields.getText());
		
			restoreStartDate = null;
			Dom.XmlNode restoreStartDateFields = node.getChildElement('STOCK_RESTORE_START_DATE', null);
			if (restoreStartDateFields != null) restoreStartDate = CommUtils.stringToDate(restoreStartDateFields.getText());
			*/
            // 2017/12/08 ログ出力ファイル数を読み込むできるように対応 BEGIN
            // 最大ログ出力数を取得する、０を設定すると、ログ出力しない
            logMaxFiles = 1000;
            Dom.XmlNode logMaxFilesField = node.getChildElement('MAXLOGFILES', null);
            if (logMaxFilesField != null){
                String logMaxFilesStr = CommUtils.nullToBlank(logMaxFilesField.getText());
                if(!CommUtils.isBlank(logMaxFilesStr)) logMaxFiles = CommUtils.nullToIntZero(logMaxFilesStr);
            }
            // 2017/12/08 ログ出力ファイル数を読み込むできるように対応 END
		}
		public Boolean bIsDebug{get;private set;}		// DEBUGモード制御フラグ
		/*
		public Integer mStockInterval{get;set;}			// 在庫連携情報のスケジュールのINTERVAL秒数（秒単位）
		public Integer mLeadImportInterval{get;set;}	// 予約取込機能のスケジュールのINTERVAL秒数（秒単位）
		public Integer mStockDeleteVal{get;set;}		// 在庫変更履歴情報の削除日付数（日単位）
		public Integer mLeadDeleteVal{get;set;}		// 予約取込履歴情報の削除日付数（日単位）
		public String strServiceUrl{get;set;}
		*/
		public Integer mLeadTimeLimit{get;set;}			// 予約データの予約番号&&発生源なしの場合、WS電文から作成の予約識別用TIMESTAMP判別用ミリ秒
		/*
        public Integer syncMaxDays{get;set;}			// 処理日から在庫調整最大日数（デイフォル：180日まで）（2015/12/14)
		public Boolean bIsSyncOnlyNewFlg{get;set;}		// バッチ起動後作成の在庫調整情報のみ連携する
		public Date restoreStartDate{get;set;}			// バッチ再起動の場合、連携開始日付を指定する
		*/
        // 2017/12/08 ログ出力ファイル数を読み込むできるように対応 BEGIN
        public integer logMaxFiles{get;set;}
        // 2017/12/08 ログ出力ファイル数を読み込むできるように対応 END
        // 2017/12/28 メール本文の通知指定名　by　zy　BEGIN
        public String emailInsDevName{get;set;}
        public String emailUpdDevName{get;set;}
        public String emailCanDevName{get;set;}
        // 2017/12/28 メール本文の通知指定名　by　zy　END
	}
	public class APPCONFIG{
		public APPCONFIG(Dom.XmlNode shopNode){
    		Dom.XmlNode configNode = shopNode.getChildElement('APPCONFIG', null);   		    		
    		if (configNode != null) {
    			/*
    			Dom.XmlNode systemIdField = configNode.getChildElement('SYSTEMID', null);
    			Dom.XmlNode userIdField = configNode.getChildElement('USERID', null);
    			Dom.XmlNode passwordField = configNode.getChildElement('PASSWORD', null);
    			*/
    			Dom.XmlNode ucactisSyncField = configNode.getChildElement('UCACTISSYNC', null);
    			// 2019/01/15 陣屋コネクトの「DM許可」アトリビュートに、「必要」「不要」を連携しているのですが、API連携する項目は下記であっていますでしょうか？ by cxw BEGIN
    			Dom.XmlNode isCoverFlgField = configNode.getChildElement('ISOVERWRITEFLG', null);
    			// 2019/01/15 陣屋コネクトの「DM許可」アトリビュートに、「必要」「不要」を連携しているのですが、API連携する項目は下記であっていますでしょうか？ by cxw END
                Dom.XmlNode roomSortField = configNode.getChildElement('ROOMSORT', null);
                Dom.XmlNode roomAtuoAssignField = configNode.getChildElement('ROOMAUTOASSIGN', null);
                Dom.XmlNode leadAutoSetupFields = configNode.getChildElement('DEFAULTVALUES', null);
                // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh BEGIN
                Dom.XmlNode chgdtRoomClearField = configNode.getChildElement('CHGDT_ROOMCLR', null);
                // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh END
                // 2018/01/17 取引先責任者の重複ルールが有効しても、無効よう対応できる改善 by zh BEGIN
                Dom.XmlNode dupInvalidField = configNode.getChildElement('DUPINVALIDFLG', null);
                // 2018/01/17 取引先責任者の重複ルールが有効しても、無効よう対応できる改善 by zh END
                // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ BEGIN
                Dom.XmlNode modifyEstItemsField = configNode.getChildElement('RESET_ESTITEMS', null);
                // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ END
                // 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 WSQ BEGIN
                Dom.XmlNode romanToKanaField = configNode.getChildElement('CHGROMANTOKANA', null);
                // 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 WSQ END       
                /*
                Dom.XmlNode realStockReqSyncFields = configNode.getChildElement('RELA_STOCK_REQ_SYNC', null);
    			if (systemIdField != null) systemId = CommUtils.nullToBlank(systemIdField.getText());
    			if (userIdField != null) userId = CommUtils.nullToBlank(userIdField.getText());
    			if (passwordField != null) password = CommUtils.nullToBlank(passwordField.getText());
    			*/
                // 予約項目デイフォル値自動設定情報の初期化
                // 2019/01/15 陣屋コネクトの「DM許可」アトリビュートに、「必要」「不要」を連携しているのですが、API連携する項目は下記であっていますでしょうか？ by cxw BEGIN
                isCoverFlg = true;
                if(isCoverFlgField != null) {
                	String flag = CommUtils.nullToBlank(isCoverFlgField.getText());
                	if(!CommUtils.isBlank(flag))
                		isCoverFlg = Boolean.valueOf(flag);
                }
                // 2019/01/15 陣屋コネクトの「DM許可」アトリビュートに、「必要」「不要」を連携しているのですが、API連携する項目は下記であっていますでしょうか？ by cxw END
                fieldMap = new Map<String,Object>();
                if (leadAutoSetupFields != null){
                    for(Dom.XmlNode fieldNode : leadAutoSetupFields.getChildElements()){
                        if(fieldNode.getName() == 'LEADFIELD'){
                            Dom.XmlNode fieldNameNode = fieldNode.getChildElement('APIFIELDNAME',null);
                            Dom.XmlNode fieldValueNode = fieldNode.getChildElement('APIFIELDVALUE',null);
                            if(fieldNameNode != null && fieldValueNode != null){
                                String fieldName = CommUtils.nullToBlank(fieldNameNode.getText());
                                String fieldValue = CommUtils.nullToBlank(fieldValueNode.getText());
                                if(!CommUtils.isBlank(fieldName) && !CommUtils.isBlank(fieldValue)) fieldMap.put(fieldName,fieldValue);
                            }
                        }
                    }
                }
    			ucactisSync = true;
    			if (ucactisSyncField != null){
    				String syncStr = CommUtils.nullToBlank(ucactisSyncField.getText());
    				if(!CommUtils.isBlank(syncStr))
    					ucactisSync = Boolean.valueOf(syncStr);
    			}
                roomSortKey = 'asc';
                if(roomSortField != null){
                    if(roomSortField.getText().equalsIgnoreCase('Desc'))
                        roomSortKey = 'desc';
                }
                roomAutoAssignFlag = false;
                if(roomAtuoAssignField != null){ 
                    roomAutoAssignFlag = Boolean.valueOf(CommUtils.nullToBlank(roomAtuoAssignField.getText()));
                }
                /*
    			// 2016/01/29 リアル（旅行会社）に対して、在庫更新要求を発行する・しない制御パラメータを追加 BEGIN
    			realStockReqSync = false;	  
                if (realStockReqSyncFields != null) {
                	realStockReqSync = Boolean.valueOf(CommUtils.nullToBlank(realStockReqSyncFields.getText()));
                }
                // 2016/01/29 リアル（旅行会社）に対して、在庫更新要求を発行する・しない制御パラメータを追加 END
                */
                // 2016/10/16 ネット取り込みエラーの場合、リトライ処理をする・しない制御処理追加 BEGIN
                retrySync = false;
                Dom.XmlNode retrySyncFields = configNode.getChildElement('RETRYSYNC', null);
                if (retrySyncFields != null) {
                	retrySync = Boolean.valueOf(CommUtils.nullToBlank(retrySyncFields.getText()));
                }
                // 2016/10/16 ネット取り込みエラーの場合、リトライ処理をする・しない制御処理追加 END
                // 2017/01/09 親部屋集める:メール本文 fix BEGIN by zh
				mailDivFlag = false;
				Dom.XmlNode mailDivField =  configNode.getChildElement('MAILDIVFLG', null);
                if(mailDivField != null){ 
                    mailDivFlag = Boolean.valueOf(CommUtils.nullToBlank(mailDivField.getText()));
                }
                // 2017/01/09 親部屋集める:メール本文 fix END by zh
                // 2017/02/07 男女区分取得 by zy BEGIN
                Dom.XmlNode genderDivField = configNode.getChildElement('GENDERDIVEXT', null);
                filter = new Filter();
                if (genderDivField != null) {
                	filter.load(genderDivField);
                }
                // 2017/02/07 男女区分取得 by zy END
                // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh BEGIN
		        chgdtRoomClearFlag = false;
    			if (chgdtRoomClearField != null){
    				String chgStr = CommUtils.nullToBlank(chgdtRoomClearField.getText());
    				if(!CommUtils.isBlank(chgStr))
    					chgdtRoomClearFlag = Boolean.valueOf(chgStr);
    			}
		        // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh END
		        
		        // 2018/01/17 取引先責任者の重複ルールが有効しても、無効よう対応できる改善 by zh BEGIN
                dupInvalidFlag = true;
                if(dupInvalidField != null){ 
                    dupInvalidFlag = Boolean.valueOf(CommUtils.nullToBlank(dupInvalidField.getText()));
                }
                // 2018/01/17 取引先責任者の重複ルールが有効しても、無効よう対応できる改善 by zh END
                // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ BEGIN
                modifyEstItemsFlag = false;
    			if (modifyEstItemsField != null){
    				String s = CommUtils.nullToBlank(modifyEstItemsField.getText());
    				if(!CommUtils.isBlank(s)) modifyEstItemsFlag = Boolean.valueOf(s);
    			} 
                // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ END
		        // 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 WSQ BEGIN
                romanToKanaFlag = false;
    			if (romanToKanaField != null){
    				String s = CommUtils.nullToBlank(romanToKanaField.getText());
    				if(!CommUtils.isBlank(s)) romanToKanaFlag = Boolean.valueOf(s);
    			} 
                // 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 WSQ END
		        
    		}
		}
		/*
		public String systemId{get;set;}
		public String userId{get;set;}
		public String password{get;set;}	
		*/
		public boolean ucactisSync{get;set;}
        public String roomSortKey{get;set;}
        public boolean roomAutoAssignFlag{get;set;}
        public Map<String,Object> fieldMap{get;set;}
        // 2016/01/29 リアル（旅行会社）に対して、在庫更新要求を発行する・しない制御パラメータを追加
        //public boolean realStockReqSync{get;set;}
        // 2016/10/16 ネット取り込みエラーの場合、リトライ処理をする・しない制御処理追加
        public boolean retrySync{get;private set;}
        public boolean mailDivFlag{get;set;}
        public Filter filter{get;set;}
        // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh BEGIN
        public boolean chgdtRoomClearFlag{get;set;}
        // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh END
        // 2018/01/17 取引先責任者の重複ルールが有効しても、無効よう対応できる改善 by zh BEGIN
        public boolean dupInvalidFlag{get;set;}
        // 2018/01/17 取引先責任者の重複ルールが有効しても、無効よう対応できる改善 by zh END
        // 2019/01/15 陣屋コネクトの「DM許可」アトリビュートに、「必要」「不要」を連携しているのですが、API連携する項目は下記であっていますでしょうか？ by cxw BEGIN
        public boolean isCoverFlg{get; set;}
        // 2019/01/15 陣屋コネクトの「DM許可」アトリビュートに、「必要」「不要」を連携しているのですが、API連携する項目は下記であっていますでしょうか？ by cxw END
        // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ BEGIN
        public boolean modifyEstItemsFlag{get;set;}
        // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ END
        // 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 WSQ BEGIN
        public boolean romanToKanaFlag{get;set;}
        // 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 WSQ END
	}
	
	/*
	public class ERRCONFIG{
		public ERRCONFIG(Dom.XmlNode shopNode){			
    		Dom.XmlNode errConfigNode = shopNode.getChildElement('ERRCONFIG', null);    		   		
    		if (errConfigNode != null) {
    			Dom.XmlNode maxConnectCountField = errConfigNode.getChildElement('MAX_CONNECT_COUNT', null);
    			Dom.XmlNode maxSendfinCountField = errConfigNode.getChildElement('MAX_SENDFIN_COUNT', null);
    			if (maxConnectCountField != null) maxConnectCount = CommUtils.nullToIntZero(maxConnectCountField.getText());
    			else maxConnectCount = 4;
    			if (maxSendfinCountField != null) maxSendfinCount = CommUtils.nullToIntZero(maxSendfinCountField.getText());
    			else maxSendfinCount = 4;
    		}    		
		}		
		public Integer maxConnectCount{get;set;}
		public Integer maxSendfinCount{get;set;}	
	}*/
	public class ACCOUNTCONFIG{
		public ACCOUNTCONFIG(Dom.XmlNode shopNode){			
    		Dom.XmlNode accConfigNode = shopNode.getChildElement('ACCOUNTCONFIG', null);    		   		
    		if (accConfigNode != null) {
    			Dom.XmlNode shiTulyouField = accConfigNode.getChildElement('SHITULYOUACCOUNT', null);
    			Dom.XmlNode nyuuTouField = accConfigNode.getChildElement('NYUUTOUACCOUNT', null);
    			Dom.XmlNode optionField = accConfigNode.getChildElement('OPTIONACCOUNT', null);
    			Dom.XmlNode serviceField = accConfigNode.getChildElement('SERVICEACCOUNT', null);
    			if (shiTulyouField != null) shituLyoCd = CommUtils.nullToBlank(shiTulyouField.getText());
    			if (nyuuTouField != null) nyuuTouCd = CommUtils.nullToBlank(nyuuTouField.getText());
    			if (optionField != null) optionCd = CommUtils.nullToBlank(optionField.getText());
    			if (serviceField != null) serviceCd = CommUtils.nullToBlank(serviceField.getText());
    		}    		
		}		
		public String shituLyoCd{get;set;}
		public String nyuuTouCd{get;set;}	
		public String optionCd{get;set;}	
		public String serviceCd{get;set;}	
	}
	/*
    public class BOOKINGCONFIG{
        public String mode{get;set;}
        public List<Item> includeLst{get;set;}
        public List<Item> excludeLst{get;set;}
        public BOOKINGCONFIG(Dom.XmlNode shopNode){
            Dom.XmlNode configNode = shopNode.getChildElement('BOOKINGCONFIG', null);   
            mode = '2';     
            includeLst = new List<Item>();
            excludeLst = new List<Item>();  
            if (configNode != null) {
                Dom.XmlNode modeField = configNode.getChildElement('MODE', null);
                Dom.XmlNode includeField = configNode.getChildElement('INCLUDE', null);
                Dom.XmlNode excludeField = configNode.getChildElement('EXCLUDE', null);
                if(modeField != null){
                    mode = modeField.getText();
                }
                if(includeField != null){
                    for(Dom.XmlNode childNode : includeField.getChildElements()){
                        if(childNode != null){
                            Dom.XmlNode fieldNameNode = childNode.getChildElement('FIELD', null);
                            Dom.XmlNode valuesNode = childNode.getChildElement('VALUES', null);
                            includeLst.add(new Item(fieldNameNode,valuesNode));
                        }
                    }
                }
                if(excludeField != null){
                    for(Dom.XmlNode childNode : excludeField.getChildElements()){
                        if(childNode != null){
                            Dom.XmlNode fieldNameNode = childNode.getChildElement('FIELD', null);
                            Dom.XmlNode valuesNode = childNode.getChildElement('VALUES', null);
                            excludeLst.add(new Item(fieldNameNode,valuesNode));
                        }
                    }
                }
            }
        }
    }
    public class Item{
        public String fieldName;
        public List<String> values;
        Item(Dom.XmlNode fieldNameNode,Dom.XmlNode valueNode){
            values = new List<String>();
            fieldName = '';
            if(fieldNameNode != null && !CommUtils.isBlank(fieldNameNode.getText())){
                fieldName = fieldNameNode.getText();
            }
            if(valueNode != null && !CommUtils.isBlank(valueNode.getText())){
                values = valueNode.getText().split(',');
            }
            
        }
    }
    */
    
    // 2016/03/22 お客様情報解析用情報の格納 BEGIN
    public list<CONTACT_INFO_PARSE> parseContactInfo(Dom.XmlNode shopNode) {
    	list<CONTACT_INFO_PARSE> parseLst = new list<CONTACT_INFO_PARSE>();
		Dom.XmlNode contactInfoNode = shopNode.getChildElement('CONTACT_INFO_PARSE', null);    		   		
		if (contactInfoNode != null) {
			for (Dom.XmlNode nodeContact : contactInfoNode.getChildElements()) {
				parseLst.add(new CONTACT_INFO_PARSE(nodeContact));
			}
		}
		return parseLst;
    }
    public class CONTACT_INFO_PARSE{
		public CONTACT_INFO_PARSE(Dom.XmlNode nodeContact){			
			// 初期値
			agtCodes = excludeVal = keyWordCd = formatCd = tofieldCd = '';
			
			Dom.XmlNode keyWordField = nodeContact.getChildElement('KEYWORD', null);
			Dom.XmlNode formatField = nodeContact.getChildElement('FORMAT', null);
			Dom.XmlNode tofieldField = nodeContact.getChildElement('TOFIELD', null);
			if (keyWordField != null) keyWordCd = CommUtils.nullToBlank(keyWordField.getText());
			if (formatField != null) formatCd = CommUtils.nullToBlank(formatField.getText());
			if (tofieldField != null) tofieldCd = CommUtils.nullToBlank(tofieldField.getText());
			agtCodes = CommUtils.nullToBlank(nodeContact.getAttribute('AGTCODE',null));
			Dom.XmlNode excludeValField = nodeContact.getChildElement('EXCLUDEVAL', null);
			if (excludeValField != null) excludeVal = CommUtils.nullToBlank(excludeValField.getText());
			Dom.XmlNode joinKeyField = nodeContact.getChildElement('JOIN_KEY', null);
			if (joinKeyField != null) joinKey = CommUtils.nullToBlank(joinKeyField.getText());
    		//system.debug(logginglevel.info,'-------------::::::::::::::::::::::::contactInfoNode----------' + contactInfoNode);  
    		// 2016/06/22 住所など読み込み拡張機能 BEGIN
			Dom.XmlNode endKeyField = nodeContact.getChildElement('ENDKEY', null);
			if (endKeyField != null) endKey = CommUtils.nullToBlank(endKeyField.getText());
			// 2016/06/22 住所など読み込み拡張機能 END
		}		
		public String keyWordCd{get;set;}
		public String formatCd{get;set;}	
		public String tofieldCd{get;set;}
		public String agtCodes{get;set;}
		public String excludeVal{get;set;}
		public String joinKey{get;set;}
		public String endKey{get;set;}
	}
	// 2016/03/22 お客様情報解析用情報の格納 END
	/*
	// 2016/05/05 バッチログ記録共通機能 BEGIN
	public static void writeLogToDb(String logMsg, string mangerId, boolean isInit) {

		// 2017/02/21 Field Security Check BEGIN
		List<String> chkFields = new List<String>{'ProcessingType__c','ManageID__c','ProcessLog__c','MailSendComplete__c','FunctionType__c'};
		Map<String,Schema.SObjectField> m = Schema.SObjectType.CooperationResult__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFields, m)) {
			return;
		}
		// 2017/02/21 Field Security Check End
		String SERVICE_KEY = 'WS';
		List<CooperationResult__c>  cooperResults = [Select Id,ProcessLog__c from CooperationResult__c where FunctionType__c=:CommConst.COOP_FUNTYPE_OPPLOG and ProcessingType__c = :SERVICE_KEY and ManageID__c = :mangerId order by LastmodifiedDate asc LIMIT 1];
		CooperationResult__c obj = cooperResults.isEmpty() ? new CooperationResult__c() : cooperResults[0];
		obj.ProcessingType__c = SERVICE_KEY;
		obj.ManageID__c = mangerId;
		obj.FunctionType__c = CommConst.COOP_FUNTYPE_OPPLOG;
		obj.MailSendComplete__c = false;
		if (isInit) obj.ProcessLog__c =  CommLogUtils.removeOverLogString(logMsg);
		else obj.ProcessLog__c = CommLogUtils.removeOverLogString(obj.ProcessLog__c + logMsg);
		upsert obj;
	}
	// 2016/05/05 バッチログ記録共通機能 END
	*/
	// 2016/05/12 事前決済区分と登録の支払商品情報マッピング　BEGIN
	// ****************************************
	// WS連携処理、エラー処理情報の格納
	// shopCd : 店舗コード
	// return : 該当店舗の定義情報を戻る
	// exception: 該当店舗コードはXMLに未定義されている場合、エラー戻る
	public static map<String, PAYMENT_CONVERT> getPointConfig(String shopCd) {
		if (getInstance().mapPointConfig.containsKey(shopCd)) {
			return getInstance().mapPointConfig.get(shopCd);
        } else {
		//指定の店舗コードの定義情報を見つかりません。
            throw new CommException(Label.MSG_038_0023 + '['+shopCd+']');
        }
    }
	public static map<String, PAYMENT_CONVERT> getPaymentConfig(String shopCd) {
		if (getInstance().mapPaymentConfig.containsKey(shopCd)) {
			return getInstance().mapPaymentConfig.get(shopCd);
        } else {
		//指定の店舗コードの定義情報を見つかりません。
            throw new CommException(Label.MSG_038_0023 + '['+shopCd+']');
        }
    }
    private map<String, PAYMENT_CONVERT> parsePointInfo(Dom.XmlNode shopNode) {
    	map<string, PAYMENT_CONVERT> paymentInfoMap = new map<string, PAYMENT_CONVERT>();
		Dom.XmlNode paymentNode = shopNode.getChildElement('PAYMENT_CONVERTS', null);    		   		
		if (paymentNode != null) {
			for (Dom.XmlNode nodeTag : paymentNode.getChildElements()) {
				if (nodeTag.getName() != 'POINT_CONVERT') continue;
				PAYMENT_CONVERT pointCls = new PAYMENT_CONVERT(nodeTag);
				paymentInfoMap.put(pointCls.getkey(), pointCls);
			}
		}
		return paymentInfoMap;
    }
    private map<String, PAYMENT_CONVERT> parsePaymentInfo(Dom.XmlNode shopNode) {
    	map<string, PAYMENT_CONVERT> paymentInfoMap = new map<string, PAYMENT_CONVERT>();
		Dom.XmlNode paymentNode = shopNode.getChildElement('PAYMENT_CONVERTS', null);    		   		
		if (paymentNode != null) {
			for (Dom.XmlNode nodeTag : paymentNode.getChildElements()) {
				if (nodeTag.getName() != 'PAYMENT_CONVERT') continue;
				PAYMENT_CONVERT paymentCls = new PAYMENT_CONVERT(nodeTag);
				paymentInfoMap.put(paymentCls.getkey(), paymentCls);
			}
		}
		return paymentInfoMap;
    }
	public class PAYMENT_CONVERT {
		public PAYMENT_CONVERT(Dom.XmlNode nodePayment){
			// 初期値
			paymentKbn = payProdCode = agtCode = '';
			paymentKbn = CommUtils.nullToBlank(nodePayment.getAttribute('PAYKBN',null));
			//payMediaCode = CommUtils.nullToBlank(nodePayment.getAttribute('MEDIACODE',null));
			Dom.XmlNode convertField = nodePayment.getChildElement('CONVERT', null);
			if (convertField != null) {
				agtCode = CommUtils.nullToBlank(convertField.getAttribute('AGTCODE',null));
				payProdCode = CommUtils.nullToBlank(convertField.getText());
			}
		}
		public String paymentKbn{get;set;}	// 事前支払区分
		public String payProdCode{get;set;}	// 登録する会計商品
		public String agtCode{get;set;}		// AGTコード
		/*
		public String getFullKey() {// 事前支払区分_AGTコード
			return CommUtils.nullToBlank(paymentKbn) + '_' + CommUtils.nullToBlank(agtCode);
		}
		public String getSortKey() {// AGTコード
			return CommUtils.nullToBlank(agtCode);
		}*/
		public String getkey() {
			return CommUtils.nullToBlank(paymentKbn) + '_' + CommUtils.nullToBlank(agtCode);
		}
	}
	public static map<string,AccountMaster__c> getPaymentProductId(List<String> productCds) {
		map<string,AccountMaster__c> prodcutMstMap = new map<string, AccountMaster__c>();
		if (!productCds.isEmpty()) {
			list<AccountMaster__c> payProductMstLst = [select id, Field3__c from AccountMaster__c where Field3__c in :productCds];
			
			for (AccountMaster__c acc : payProductMstLst) {
				prodcutMstMap.put(acc.Field3__c, acc);
			}
		}
		return prodcutMstMap;
	}
	// 2016/05/12 事前決済区分と登録の支払商品情報マッピング　END
    // 2016/06/10 子供料金プラン取り込み機能対応 BEGIN
    // 2017/02/21 お子様プランの料金PRICE機能追加 by zh BEGIN
    private static final String DEF_CHILDPLAN_RATE = 'RATE';
    private static final String DEF_CHILDPLAN_PRICE = 'PRICE';
    // 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ BEGIN
    private static final String DEF_CHILDPLAN_NAMEONLY = 'NAMEONLY';
    public static String getChildRateMatchKey(String rate) {
    	return (DEF_CHILDPLAN_RATE + '_' + rate);
    } 
    public static String getChildPriceMatchKey(String price) {
    	return (DEF_CHILDPLAN_PRICE + '_' + price);
    } 
    // 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ END
	//private map<String,String> parseChildPlanConvert(Dom.XmlNode shopNode) {
	private map<String,Map<String,String>> parseChildPlanConvert(Dom.XmlNode shopNode) {
		Map<String,Map<String,String>> childPlanMap = new Map<String,Map<String,String>>{};
		map<String,String> childPlanPriceConvertMap = new map<String,String>();
    	// 2017/02/21 お子様プランの料金PRICE機能追加 by zh END
		map<String,String> childPlanConvertMap = new map<String,String>();
		// 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ BEGIN
		map<String,String> childPlanNameConvertMap = new map<String,String>();
		// 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ END
    	
		Dom.XmlNode childPlanConvertNode = shopNode.getChildElement('CHILD_PLAN_CONVERT', null);    		   		
		if (childPlanConvertNode != null) {
			for (Dom.XmlNode nodeTag : childPlanConvertNode.getChildElements()) {
				String valueRate = CommUtils.nullToBlank(nodeTag.getAttribute('RATE',null));
				String prodCode = CommUtils.nullToBlank(nodeTag.getText());
				// 2017/02/21 お子様プランの料金PRICE機能追加 by zh BEGIN
				String valuePrice = CommUtils.nullToBlank(nodeTag.getAttribute('PRICE',null));
				// 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ BEGIN
				Boolean nameOnly = Boolean.valueOf(CommUtils.nullToBlank(nodeTag.getAttribute('NAMEONLY',null)));
system.debug(loggingLevel.info, 'nameOnly='+nameOnly);
				// 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ END
				//if (CommUtils.isBlank(valueRate) || CommUtils.isBlank(prodCode) || !CommUtils.isNumber(valueRate)) continue;
				if(!CommUtils.isBlank(prodCode)){
					if (!CommUtils.isBlank(valueRate) && CommUtils.isNumber(valueRate)){
						// 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ BEGIN
						if (nameOnly) childPlanNameConvertMap.put(getChildRateMatchKey(valueRate), prodCode);
						else
						// 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ END
						childPlanConvertMap.put(valueRate, prodCode);
					}
					if (!CommUtils.isBlank(valuePrice) && CommUtils.isNumber(valuePrice)){
						// 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ BEGIN
						if (nameOnly) childPlanNameConvertMap.put(getChildPriceMatchKey(valuePrice), prodCode);
						else
						// 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ END
						childPlanPriceConvertMap.put(valuePrice, prodCode);
					}
				}
				// 2017/02/21 お子様プランの料金PRICE機能追加 by zh END
			}
		}
		// 2017/02/21 お子様プランの料金PRICE機能追加 by zh BEGIN
		//return childPlanConvertMap;
		childPlanMap.put(DEF_CHILDPLAN_RATE,childPlanConvertMap);
		childPlanMap.put(DEF_CHILDPLAN_PRICE,childPlanPriceConvertMap);
System.debug(logginglevel.INFO,'childPlanMap' + childPlanMap);
		// 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ BEGIN
system.debug(loggingLevel.info, 'childPlanNameConvertMap='+childPlanNameConvertMap);
		childPlanMap.put(DEF_CHILDPLAN_NAMEONLY,childPlanNameConvertMap);
		// 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ END
		return childPlanMap;
		// 2017/02/21 お子様プランの料金PRICE機能追加 by zh END
	}
    public static map<String,String> getChildPlanConvertConfig(String shopCd) {
		if (getInstance().mapChildPlanConvertConfig.containsKey(shopCd)) {
			return getInstance().mapChildPlanConvertConfig.get(shopCd);
        } else {
            throw new CommException('指定の店舗コードの定義情報を見つかりません。['+shopCd+']');
        }
    }
    // 2017/02/21 お子様プランの料金PRICE機能追加 by zh BEGIN
    public static map<String,String> getChildPlanPriceConvertConfig(String shopCd) {
		if (getInstance().mapChildPlanPriceConvertConfig.containsKey(shopCd)) {
			return getInstance().mapChildPlanPriceConvertConfig.get(shopCd);
        } else {
            throw new CommException('指定の店舗コードの定義情報を見つかりません。['+shopCd+']');
        }
    }
    // 2017/02/21 お子様プランの料金PRICE機能追加 by zh END
    // 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ BEGIN
    private map<String, map<string,string>> mapChildPlanNameConvertConfig;	
    public static map<String,String> getChildPlanNameConvertConfig(String shopCd) {
		if (getInstance().mapChildPlanNameConvertConfig.containsKey(shopCd)) {
			return getInstance().mapChildPlanNameConvertConfig.get(shopCd);
        } else {
            throw new CommException('指定の店舗コードの定義情報を見つかりません。['+shopCd+']');
        }
    }
    // 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ END
    // 2016/06/10 子供料金プラン取り込み機能対応 END
	// 2016/07/10 予約チャネル名の変換機能追加対応 BEGIN
	private map<String,String> parseAGTToChanelConvert(Dom.XmlNode shopNode) {
    	map<String,String> childAGTMap = new map<String,String>();
		Dom.XmlNode childAGTNode = shopNode.getChildElement('CHANNEL_CONVERTS', null);    		   		
		if (childAGTNode != null) {
			for (Dom.XmlNode nodeTag : childAGTNode.getChildElements()) {
				String agtCode = CommUtils.nullToBlank(nodeTag.getAttribute('AGTCODE',null));
				String chanelStr = CommUtils.nullToBlank(nodeTag.getText());
				if (CommUtils.isBlank(agtCode) || CommUtils.isBlank(chanelStr)) continue;
				childAGTMap.put(agtCode, chanelStr);
			}
		}
		return childAGTMap;
	}
	public static map<String,String> getMapAgtToChanelConfig(String shopCd) {
		if (getInstance().mapAgtToChanelConfig.containsKey(shopCd)) {
			return getInstance().mapAgtToChanelConfig.get(shopCd);
        } else {
            throw new CommException('指定の店舗コードの定義情報を見つかりません。['+shopCd+']');
        }
    }
	// 2016/07/10 予約チャネル名の変換機能追加対応 END
	// 2017/02/07 男女区分取得 by zy BEGIN
	public Class Filter{
		List<String> beginLst;
		List<String> begin2Lst;
		List<String> endLst;
		List<String> filters;
		Filter () {
			beginLst = new List<String>{'人員総数：','人員総数:'};
			begin2Lst = new List<String>{'内訳：'};
			endLst = new List<String>{'\n'};
			filters = new List<String>{'(男)','(女)'};
		}
		public void load(Dom.xmlNode xmlNode) {
			beginLst = new List<String>();
			begin2Lst = new List<String>();
			endLst = new List<String>();
			filters = new List<String>();
			String begins = CommUtils.nullToBlank(xmlNode.getAttribute('BEG',null));
			String begins2 = CommUtils.nullToBlank(xmlNode.getAttribute('BEG2',null));
			String ends =   CommUtils.nullToBlank(xmlNode.getAttribute('END',null));
			String filterStr =  CommUtils.nullToBlank(xmlNode.getText());
			if(!CommUtils.isBlank(begins)) beginLst = begins.split(',');
			if(!CommUtils.isBlank(ends)) endLst = ends.split(',');
			if(!CommUtils.isBlank(filterStr)) filters = filterStr.split(',');
			if(!CommUtils.isBlank(begins2)) begin2Lst = begins2.split(',');
		}
		public boolean getResult(String content){
			String f_content = '';
			//首字符判断
			for (String b_Text : beginLst) {
				//传入内容与首字符匹配
				while(content.contains(b_Text)){
					//截取首字符后的内容
					content = content.subStringAfter(b_Text);
					f_content = content;
					//尾字符判断
					for (String e_Text : endLst) {
						//截取后的内容包含尾字符
						if (f_content.contains(e_Text)){
							//截取尾字符以前的内容
							f_content = f_content.subStringBefore(e_Text);
							content = content.subStringAfter(e_Text);
						}
					}
//system.debug(logginglevel.info,'f_content:::' + f_content);
					//首字符2判断
					if (!begin2Lst.isEmpty()){
						for (String b2_Text : begin2Lst) {
							//首字符2与截取内容匹配
							if (f_content.contains(b2_Text)){
								//判断字符中是否包含关键字
								for (String format : filters) {
									if (f_content.contains(format)) {
										return false;
									}
								}
							}
						}
					//存在关键字
					} else {
						//判断字符中是否包含关键字
						for (String format : filters) {
							if (f_content.contains(format)) {
								return false;
							}
						}
					}
				}
			}
			return true;
		}
	}
	// 2017/02/07 男女区分取得 by zy END
	public static set<String> genralUserID(Integer nums) {
		set<string> keyset = new set<string>();
		for (Integer i=0; i<nums; i++) {
			List<integer> guidASCIICode = new List<integer>();
			while (guidASCIICode.size() < 10)
			{
			    double rnd = Math.random();
			    integer alphanumeric = (integer)(rnd * 22);    //22 is range between
			                                                   //ascii 0 and F 
			    alphanumeric += 48;                            //shift random range up
			    if (alphanumeric < 58 || alphanumeric > 65) {  //filter out some chars
			        guidASCIICode.Add(alphanumeric);
			    }
			}
			String guid = String.fromCharArray( guidASCIICode ); //enjoy
			keyset.add(guid);
		}
		return keyset;
	}
	// 2017/12/13 2.BookingAPIの通知メールのテンプレート定義の対応 by zy END
	public class EmailTemp{
		public String head;
		public String detail;
		public String foot;
		public String format;
		public EmailTemp () {
			head = '';
			detail = '';
			format = '';
		}
	}
	public static EmailTemp getEmailTemp(String shopCd) {
		if (getInstance().mapEmailTemplateMap.containsKey(shopCd)) {
			return getInstance().mapEmailTemplateMap.get(shopCd);
        }
        return null;
    }
	private EmailTemp parseEmailTemplate(Dom.XmlNode shopNode) {
		Dom.xmlNode emailNode = shopNode.getChildElement('EMAIL', null);
		EmailTemp temp = new EmailTemp();
		if (emailNode != null) {
			Dom.XmlNode headNode = emailNode.getChildElement('HEAD', null); 
			Dom.XmlNode detailNode = emailNode.getChildElement('DETAIL', null); 
			Dom.XmlNode footNode = emailNode.getChildElement('FOOT', null); 
			if ( headNode != null ) temp.head = headNode.getText();
			if ( detailNode != null ) {
				temp.detail = detailNode.getText();
				temp.format = CommUtils.nullToBlank(detailNode.getAttribute('ROOMDATE_FORMAT',null));
			}
			if ( footNode != null ) temp.foot = footNode.getText();
		}
		return temp;
	}
	// 2017/12/13 2.BookingAPIの通知メールのテンプレート定義の対応 by zy END
}