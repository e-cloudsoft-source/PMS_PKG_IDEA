/***************************
* TA2WAY処理機能共通ヘルプクラス
* 2016/03/22 お客様情報解析用情報の格納
* 2016/05/12 事前決済区分と登録の支払商品情報マッピング
* 2016/06/10 子供料金プラン取り込み機能対応
* 2016/08/08 インターバル定義情報は最小90秒まで定義できる変更
* 2016/09/16 ネット取り込みエラーの場合、リトライ処理をする・しない制御処理追加
* 2016/10/06 手間いらず側の在庫状態は手仕舞いの場合、連携する・しないのデフォルト値変更
* 2017/02/21 お子様プランの料金PRICE機能追加 
* 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応
* 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応
* 2017/08/02 料金の12%が事前払い
* 2018/12/30 TA予約変更通知の際に、部屋タイプを自動変更できるように改善対応
* 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善
* 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応
* 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する
* 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善
* 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善
* 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加
****************************/
public with sharing class TA_ServiceConfigHelp {
	public enum ProcessingType{TL,TA,TR,JR}
	public static final Integer DEF_MIN_INTERVAL = 90;//最小90秒
	private static TA_ServiceConfigHelp instance = new TA_ServiceConfigHelp();
	private static TA_ServiceConfigHelp getInstance() {
		if(instance == null) instance = new TA_ServiceConfigHelp();
		return instance;
	}
	// Ta2WAY連動機能設定ファイル名
	private static final String XmlConfigName = 'Ta2wayServiceConfigXml';

	private TA_ServiceConfigHelp() {
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
		//mapContactConfig = new map<String, list<CONTACT_INFO_PARSE>>();
		// 2016/05/12 事前決済区分と登録の支払商品情報マッピング
		// 2017/08/02 料金の12%が事前払い by zh BEGIN
		//mapPaymentConfig = new map<String ,map<String, PAYMENT_CONVERT>>();
		mapPaymentConfig = new map<String ,map<String, List<PAYMENT_CONVERT>>>();
		// 2017/08/02 料金の12%が事前払い by zh END
		// 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ BEGIN
		//mapPointConfig = new map<String ,map<String, PAYMENT_CONVERT>>();
		mapPointConfig = new map<String ,map<String, List<PAYMENT_CONVERT>>>();
		// 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ END
		// 支払方法文言変換ルール
		preCardPaymentWordConfig = new map<String, set<String>>();
		preCreditPaymentWordConfig = new map<String, set<String>>();
		// 2016/06/10 子供料金プラン取り込み機能対応 BEGIN
		mapChildPlanConvertConfig = new map<String, map<string, string>>(); 
		// 2017/02/21 お子様プランの料金PRICE機能追加 by zh BEGIN
		mapChildPlanPriceConvertConfig = new map<String, map<string, string>>(); 
		// 2017/02/21 お子様プランの料金PRICE機能追加 by zh END
		// 2016/06/10 子供料金プラン取り込み機能対応 END
		// 2016/07/10 予約チャネル名の変換機能追加対応 BEGIN
		mapAgtToChanelConfig = new map<String, map<string, string>>(); 
		// 2016/07/10 予約チャネル名の変換機能追加対応 END
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
				//mapContactConfig.put(strShopCode, parseContactInfo(node));
				// 2016/05/12 事前決済区分と登録の支払商品情報マッピング
				// 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ BEGIN
				// カスタマイズ分析用定義情報を取得する
				map<string, PARSEINFO> payParseDefMap = parsePayDefInfo(node);
				//mapPaymentConfig.put(strShopCode, parsePaymentInfo(node));
				mapPaymentConfig.put(strShopCode, parsePaymentInfo(node, payParseDefMap));
				//mapPointConfig.put(strShopCode, parsePointInfo(node));
				mapPointConfig.put(strShopCode, parsePointInfo(node, payParseDefMap));
				preCardPaymentWordConfig.put(strShopCode, parsePaymentDefConvert(node, 'CRAD'));
				preCreditPaymentWordConfig.put(strShopCode,parsePaymentDefConvert(node, 'CREDIT'));
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
			}
			
		}
	}
	
	private map<String, APPCONFIG> mapAppConfig;
	//private map<String, ERRCONFIG> mapErrConfig;
	private map<String, ACCOUNTCONFIG> mapAccConfig;
    //private map<String, BOOKINGCONFIG> mapBookingConfig;
    // 2016/03/22 お客様情報解析用情報の格納
    //private map<String, List<CONTACT_INFO_PARSE>> mapContactConfig;
    // 2016/05/12 事前決済区分と登録の支払商品情報マッピング
    // 2017/08/02 料金の12%が事前払い by zh BEGIN
    //private map<String, map<string,PAYMENT_CONVERT>> mapPaymentConfig;
    private map<String, map<string,List<PAYMENT_CONVERT>>> mapPaymentConfig;
    // 2017/08/02 料金の12%が事前払い by zh END
    // 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ BEGIN
    //private map<String, map<string,PAYMENT_CONVERT>> mapPointConfig;
    private map<String, map<string,List<PAYMENT_CONVERT>>> mapPointConfig;
	// 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ END
	private COMMCONFIG commConfig;
	// AGT単位のプランコードはSF側のプランNOと変換情報の格納
	private map<String, map<String,map<String, String>>> mapPlanConvertAgt2SfMap;
    // 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応 by zh BEGIN
    private map<String, Boolean> mapPlanConvertAgt2SfNameFlgMap;
    // 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応 by zh END
	// 支払方法文言変更ルール
	private map<String, set<String>> preCardPaymentWordConfig;		// 事前カード決済キーワード
	private map<String, set<String>> preCreditPaymentWordConfig;	// 売掛明細キーワード
	// 該当店舗コードはTaサイトコントローラと契約済がどうかチェックを行う
	// 2016/06/10 子供料金プラン取り込み機能対応 BEGIN
	private map<String, map<string,string>> mapChildPlanConvertConfig;	// 子供料金変換ルール情報格納
	// 2017/02/21 お子様プランの料金PRICE機能追加 by zh BEGIN
	private map<String, map<string,string>> mapChildPlanPriceConvertConfig;	
	// 2017/02/21 お子様プランの料金PRICE機能追加 by zh END
	// 2016/06/10 子供料金プラン取り込み機能対応 END
	// 2016/07/10 予約チャネル名の変換機能追加対応
	private map<String, map<String,String>> mapAgtToChanelConfig;
	// XMLの中に、該当店舗コードを定義されていると、契約済として、判断する
	public static Boolean isContractShop(String shopCd) {
		return getInstance().mapAppConfig.containsKey(shopCd);
	}
	// XMLに定義情報存在チェツク、SHOPタグ定義情報がない場合、Ta連携機能を起動しません
	public static Boolean taSyncIsOpen() {
		return (getInstance().mapAppConfig.size() > 0);
	}
	// ****************************************
	// Ta2WAY連携処理、共通定義パラメータ情報を取得する
	// ****************************************
	public static COMMCONFIG getCommConfig () {
		return getInstance().commConfig;
	}
	// ****************************************
	// Ta2WAY連携処理、各店舗個別定義必要情報取得する
	// shopCd : 店舗コード
	// return : 該当店舗の定義情報を戻る
	// exception: 該当店舗コードはXMLに未定義されている場合、エラー戻る
	// ****************************************
	public static APPCONFIG getAppConfig(String shopCd) {
		if (getInstance().mapAppConfig.containsKey(shopCd)) {
			return getInstance().mapAppConfig.get(shopCd);
		} else {
			throw new CommException('指定の店舗コードの定義情報を見つかりません。['+shopCd+']');
		}
		
	}
	// ****************************************
	// Ta2WAY連携処理、エラー処理情報の格納
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
	// Ta2WAY連携処理、エラー処理情報の格納
	// shopCd : 店舗コード
	// return : 該当店舗の定義情報を戻る
	// exception: 該当店舗コードはXMLに未定義されている場合、エラー戻る
	public static ACCOUNTCONFIG getAccountConfig(String shopCd) {
		if (getInstance().mapAccConfig.containsKey(shopCd)) {
			return getInstance().mapAccConfig.get(shopCd);
        } else {
            throw new CommException('指定の店舗コードの定義情報を見つかりません。['+shopCd+']');
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
	// Ta2WAY連携処理、AGTのパッケージコードにより、SFのプランNO情報を取得する
	// shopCd:			店舗コード
	// agtCode : 		AGTコード
	// packageCode:		AGT側に定義しているパッケージコード
	// return : 		該当AGTパッケージコードからSF側のプランコード値を戻る
	//						該当戻る値はNULLの場合、AGTのパッケージコードはSF側のプランコードとリンクしません
	// exception: 		該当店舗コードはXMLに未定義されている場合、エラー戻る
	public static String getSfPlanNoByAgtPlanInfo(String shopCd, String agtCode, String packageCode) {
		if (CommUtils.isBlank(agtCode) || CommUtils.isBlank(packageCode)) return null;
		if (getInstance().mapPlanConvertAgt2SfMap.containsKey(shopCd)) {
			// AGT 存在チェック
			map<String, map<String,String>> agtConvertMap = getInstance().mapPlanConvertAgt2SfMap.get(shopCd);
			/*
			if (instance.agtInfoMaps == null) {
				map<String, Account> locAgtInfoMaps = new map<String, Account>();
				for (Account acc : [select id, name, SalesOfficeCompanyCodeTA__c from Account where AccountType__c = :CommConst.ACCOUNT_TYPE_TRAVEL And SalesOfficeCompanyCodeTA__c != null order by CreatedDate desc  ]) {
					if (!locAgtInfoMaps.containsKey(acc.SalesOfficeCompanyCodeTA__c)) locAgtInfoMaps.put(acc.SalesOfficeCompanyCodeTA__c, acc);
				}
				instance.agtInfoMaps = locAgtInfoMaps.clone();
			}*/
//System.debug(loggingLevel.INFO, 'instance.agtInfoMaps:::' + instance.agtInfoMaps);
			// コードから名を取得する
			if (agtConvertMap != null && agtConvertMap.containsKey(agtCode)) {
				map<string, String> planConvertmap = agtConvertMap.get(agtCode);
				// 該当パッケージコードからプランNOを戻る
				return planConvertmap.get(packageCode);
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
			String agtCode = CommUtils.nullToBlank(agtNode.getAttribute('AGTCODE',null));
			if (CommUtils.isBlank(agtCode)) continue;
			map<String, String> agtConvertMap = new map<String, String>();
			convertMap.put(agtCode, agtConvertMap);
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
	// Ta2WAY連携処理、エラー処理情報の格納
	// shopCd : 店舗コード
	// return : 該当店舗の定義情報を戻る
	// exception: 該当店舗コードはXMLに未定義されている場合、エラー戻る
	/*
	public static list<CONTACT_INFO_PARSE> getContactConfig(String shopCd) {
		if (instance.mapContactConfig.containsKey(shopCd)) {
			return instance.mapContactConfig.get(shopCd);
        } else {
            throw new CommException('指定の店舗コードの定義情報を見つかりません。['+shopCd+']');
        }
    }*/
	// 2016/03/22 お客様情報解析用情報の格納 END
	
	// 共通定義情報の格納
	public class COMMCONFIG { 
		public COMMCONFIG(Dom.XmlNode node){
			Dom.XmlNode stockIntervalField = node.getChildElement('STOCKINTERVAL', null);
			Dom.XmlNode leadImpIntervalField = node.getChildElement('LEADINTERVAL', null);
			Dom.XmlNode stockDeleteValField = node.getChildElement('STOCKDELETEVAL', null);
			Dom.XmlNode leadDeleteValField = node.getChildElement('LEADDELETEVAL', null);
			
			mStockInterval = (stockIntervalField == null) ? 60 : CommUtils.nullToIntZero(stockIntervalField.getText());
			mStockDeleteVal = (stockDeleteValField == null) ? -60 : CommUtils.nullToIntZero(stockDeleteValField.getText());
			mLeadImportInterval = (leadImpIntervalField == null) ? 60 :CommUtils.nullToIntZero(leadImpIntervalField.getText());
			mLeadDeleteVal = (leadDeleteValField == null) ? -60 : CommUtils.nullToIntZero(leadDeleteValField.getText());
			// 2016/08/08 インターバル定義情報は最小90秒まで定義できる変更 BEGIN
			// 最小３０秒単位
			//if (mStockInterval <= 30) mStockInterval = 30;
			//if (mLeadImportInterval <= 30) mLeadImportInterval = 30;
			if (mStockInterval <= DEF_MIN_INTERVAL) mStockInterval = DEF_MIN_INTERVAL;
			if (mLeadImportInterval <= DEF_MIN_INTERVAL) mLeadImportInterval = DEF_MIN_INTERVAL;
			// 2016/08/08 インターバル定義情報は最小90秒まで定義できる変更 END
			if (mStockDeleteVal == null) mStockDeleteVal = -60;
			if (mLeadDeleteVal == null) mLeadDeleteVal = -60;
			// SITE URL(UP)
			Dom.XmlNode serviceUrlUpField = node.getChildElement('SERVICE_URL_UP', null);
			strServiceUpUrl = CommUtils.nullToBlank(serviceUrlUpField.getText());
			// SITE URL
			Dom.XmlNode serviceUrlField = node.getChildElement('SERVICE_URL', null);
			strServiceUrl = CommUtils.nullToBlank(serviceUrlField.getText());
	    		
			//DEBUG MODE NODE
			Dom.XmlNode isDebugField = node.getChildElement('ISDEBUG', null);
			bIsDebug = (isDebugField == null) ? false : Boolean.valueOf(CommUtils.nullToBlank(isDebugField.getText()));
			// XXミリ秒以内すると、予約インデックスと同時に作成される予約情報（2015/12/14)
			mLeadTimeLimit = 60000;	// １分以内
			Dom.XmlNode mLeadTimeLimitField = node.getChildElement('TARGET_LEAD_TIMELIMIT', null);
			if (mLeadTimeLimitField != null) mLeadTimeLimit = CommUtils.nullToIntZero(mLeadTimeLimitField.getText());
            
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
			
			// 2017/05/25 在庫調整連携方式変更対応 BEGIN
			bIsSf2TaSyncMode = true;
			Dom.XmlNode bIsSf2TaSyncModeFields = node.getChildElement('SYNC_SF2TA_MODE', null);
			if (bIsSf2TaSyncModeFields != null) bIsSf2TaSyncMode = Boolean.valueOf(bIsSf2TaSyncModeFields.getText());			
			// 2017/05/25 在庫調整連携方式変更対応 END
		}
		public Boolean bIsDebug{get;private set;}		// DEBUGモード制御フラグ
		public Integer mStockInterval{get;set;}			// 在庫連携情報のスケジュールのINTERVAL秒数（秒単位）
		public Integer mLeadImportInterval{get;set;}	// 予約取込機能のスケジュールのINTERVAL秒数（秒単位）
		public Integer mStockDeleteVal{get;set;}		// 在庫変更履歴情報の削除日付数（日単位）
		public Integer mLeadDeleteVal{get;set;}		// 予約取込履歴情報の削除日付数（日単位）
		public String strServiceUpUrl{get;set;}			// EndPoint UP
		public String strServiceUrl{get;set;}			// EndPoint Down
		public Integer mLeadTimeLimit{get;set;}			// 予約データの予約番号&&発生源なしの場合、Ta電文から作成の予約識別用TIMESTAMP判別用ミリ秒
        public Integer syncMaxDays{get;set;}			// 処理日から在庫調整最大日数（デイフォル：180日まで）（2015/12/14)
		public Boolean bIsSyncOnlyNewFlg{get;set;}		// バッチ起動後作成の在庫調整情報のみ連携する
		public Date restoreStartDate{get;set;}			// バッチ再起動の場合、連携開始日付を指定する
		// 2017/05/25 在庫調整連携方式変更対応 BEGIN
		public Boolean bIsSf2TaSyncMode{get;set;}		// SFの残室数からTA側へ常に連携を行うモード(TRUE:)
		// 2017/05/25 在庫調整連携方式変更対応 END
	}
	
	public class APPCONFIG{
		public APPCONFIG(Dom.XmlNode shopNode){
    		Dom.XmlNode configNode = shopNode.getChildElement('APPCONFIG', null);  		
    		if (configNode != null) {
    			Dom.XmlNode systemIdField = configNode.getChildElement('SYSTEMID', null);
    			Dom.XmlNode userIdField = configNode.getChildElement('USERID', null);
    			Dom.XmlNode passwordField = configNode.getChildElement('PASSWORD', null);
    			Dom.XmlNode ucactisSyncField = configNode.getChildElement('UCACTISSYNC', null);
                Dom.XmlNode roomSortField = configNode.getChildElement('ROOMSORT', null);
                Dom.XmlNode roomAtuoAssignField = configNode.getChildElement('ROOMAUTOASSIGN', null);
                Dom.XmlNode leadAutoSetupFields = configNode.getChildElement('DEFAULTVALUES', null);
                Dom.XmlNode salesCloseSyncFields = configNode.getChildElement('SALESCLOSESYNC', null);
                Dom.XmlNode personRateCalFields = configNode.getChildElement('PERSONRATECAL', null);
                // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh BEGIN
                Dom.XmlNode chgdtRoomClearField = configNode.getChildElement('CHGDT_ROOMCLR', null);
                // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh END
                // 2018/12/30 TA予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh BEGIN
                Dom.XmlNode chgRoomTypeField = configNode.getChildElement('CHGROOMTYPE', null);
                // 2018/12/30 TA予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh END
                // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ BEGIN
                Dom.XmlNode modifyEstItemsField = configNode.getChildElement('RESET_ESTITEMS', null);
                // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ END
                //2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応  by zh BEGIN
                Dom.XmlNode payMeaidToLastDayField = configNode.getChildElement('PAYMEDIATOLASTDAY', null);
                //2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応  by zh END     
                // 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 WSQ BEGIN
                Dom.XmlNode romanToKanaField = configNode.getChildElement('CHGROMANTOKANA', null);
                // 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 WSQ END 
    			if (systemIdField != null) systemId = CommUtils.nullToBlank(systemIdField.getText());
    			if (userIdField != null) userId = CommUtils.nullToBlank(userIdField.getText());
    			if (passwordField != null) password = CommUtils.nullToBlank(passwordField.getText());
                // 予約項目デイフォル値自動設定情報の初期化
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
    			// 手間いらず側の在庫状態は手仕舞いの場合、連携するがどうか制御
    			//2016/10/06 手間いらず側の在庫状態は手仕舞いの場合、連携する・しないのデフォルト値変更
    			//salesCloseSync = false;	  
    			salesCloseSync = true;
                if (salesCloseSyncFields != null) {
                	salesCloseSync = Boolean.valueOf(CommUtils.nullToBlank(salesCloseSyncFields.getText()));
                }
                // 室料から人単価金額を自動計算するがどうか
                presonRateAutoCal = true;
                if (personRateCalFields != null) {
                	presonRateAutoCal = Boolean.valueOf(CommUtils.nullToBlank(personRateCalFields.getText()));
                }
                // 税サ区分定義情報を取得する
                taxServiceKbn = '1';
                Dom.XmlNode taxServiceKbnFields = configNode.getChildElement('TAXSERVICEFEE', null);
                if (taxServiceKbnFields != null) {
                	taxServiceKbn = CommUtils.nullToBlank(taxServiceKbnFields.getText());
                }
                // 2016/08/04 予約チャネルの設定元の制御フラグ BEGIN
                chanelFromCompany = true;
                Dom.XmlNode chanelFromCompanyField = configNode.getChildElement('COMPANYTOCHANEL', null);
                if (chanelFromCompanyField != null) chanelFromCompany = Boolean.valueOf(CommUtils.nullToBlank(chanelFromCompanyField.getText()));
                // 2016/08/04 予約チャネルの設定元の制御フラグ END
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
                // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh BEGIN
		        chgdtRoomClearFlag = false;
    			if (chgdtRoomClearField != null){
    				String chgStr = CommUtils.nullToBlank(chgdtRoomClearField.getText());
    				if(!CommUtils.isBlank(chgStr))
    					chgdtRoomClearFlag = Boolean.valueOf(chgStr);
    			}
		        // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh END
      			// 2018/12/30 TA予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh BEGIN
                chgRoomTypeFlag = false;
    			if (chgRoomTypeField != null){
    				String chgTypeStr = CommUtils.nullToBlank(chgRoomTypeField.getText());
    				if(!CommUtils.isBlank(chgTypeStr)) chgRoomTypeFlag = Boolean.valueOf(chgTypeStr);
    			}
                // 2018/12/30 TA予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh END
                // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ BEGIN
                modifyEstItemsFlag = false;
    			if (modifyEstItemsField != null){
    				String s = CommUtils.nullToBlank(modifyEstItemsField.getText());
    				if(!CommUtils.isBlank(s)) modifyEstItemsFlag = Boolean.valueOf(s);
    			} 
                // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ END
                // 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応 by zh BEGIN
		        payMeaidToLastDayFlag = false;
		        if(payMeaidToLastDayField != null){ 
                    payMeaidToLastDayFlag = Boolean.valueOf(CommUtils.nullToBlank(payMeaidToLastDayField.getText()));
                }
		        // 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応 by zh END
		        // 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ BEGIN
		        contactAlwaysNew = false;
                Dom.XmlNode contactAlwaysNewField = configNode.getChildElement('CONTACT_ALWAYS_NEW', null);
    			if (contactAlwaysNewField != null){
    				String s = CommUtils.nullToBlank(contactAlwaysNewField.getText());
    				if(!CommUtils.isBlank(s)) contactAlwaysNew = Boolean.valueOf(s);
    			} 
		        // 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ END
		        // 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 WSQ BEGIN
                romanToKanaFlag = false;
    			if (romanToKanaField != null){
    				String s = CommUtils.nullToBlank(romanToKanaField.getText());
    				if(!CommUtils.isBlank(s)) romanToKanaFlag = Boolean.valueOf(s);
    			} 
                // 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 WSQ END
    		}
		}
		public String systemId{get;set;}
		public String userId{get;set;}
		public String password{get;set;}	
		public boolean ucactisSync{get;set;}
        public String roomSortKey{get;set;}
        public boolean roomAutoAssignFlag{get;set;}
        public Map<String,Object> fieldMap{get;set;}
        public boolean salesCloseSync{get;set;}
        public boolean presonRateAutoCal{get;set;}
        private String taxServiceKbn{get;private set;}
        public Boolean isSFTaxServiceKbn{get{return taxServiceKbn != '2';}} // 税サ区分はSalesforceの単価区分は依存する
        // 2016/08/04 予約チャネルの設定元の制御フラグ；TRUE:旅行会社名で設定(デフォルト値)、FALSE:旅行営業所で設定
        public boolean chanelFromCompany{get;private set;}
        // 2016/10/16 ネット取り込みエラーの場合、リトライ処理をする・しない制御処理追加
        public boolean retrySync{get;private set;}
        // 2017/01/09 親部屋集める:メール本文 fix BEGIN by zh
        public boolean mailDivFlag{get;set;}
        // 2017/01/09 親部屋集める:メール本文 fix END by zh
        // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh BEGIN
        public boolean chgdtRoomClearFlag{get;set;}
        // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh END
        // 2018/12/30 TA予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh BEGIN
        public boolean chgRoomTypeFlag{get;set;}
        // 2018/12/30 TA予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh END
        // 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応 by zh BEGIN
        public boolean payMeaidToLastDayFlag{get;set;}
        // 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応 by zh END
        // 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ BEGIN
        public boolean contactAlwaysNew{get;set;}
        // 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ EN
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
		}		
		public String keyWordCd{get;set;}
		public String formatCd{get;set;}	
		public String tofieldCd{get;set;}
		public String agtCodes{get;set;}
		public String excludeVal{get;set;}
		public String joinKey{get;set;}
	}
	// 2016/03/22 お客様情報解析用情報の格納 END*/
	// 2016/05/05 バッチログ記録共通機能 BEGIN
	public static void writeLogToDb(String logMsg, string mangerId, boolean isInit) {
		// 2018/03/07 Security Check BEGIN
		List<String> chkFields = new List<String>{'ProcessingType__c','ManageID__c','ProcessLog__c','FunctionType__c','MailSendComplete__c'};
		Map<String,Schema.SObjectField> m = Schema.SObjectType.CooperationResult__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFields, m)) {
			return;
		}
		// 2018/03/07 Security Check END
		String SERVICE_KEY = TA_ServiceCtrl.SERVICE_KEY;
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
	// 2016/05/12 事前決済区分と登録の支払商品情報マッピング　BEGIN
	// ****************************************
	// Ta2WAY連携処理、エラー処理情報の格納
	// shopCd : 店舗コード
	// return : 該当店舗の定義情報を戻る
	// exception: 該当店舗コードはXMLに未定義されている場合、エラー戻る
	// 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ BEGIN
	//public static map<String, PAYMENT_CONVERT> getPointConfig(String shopCd) {
	public static map<String, List<PAYMENT_CONVERT>> getPointConfig(String shopCd) {
	// 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ END
		if (getInstance().mapPointConfig.containsKey(shopCd)) {
			return getInstance().mapPointConfig.get(shopCd);
        } else {
            throw new CommException('指定の店舗コードの定義情報を見つかりません。['+shopCd+']');
        }
    }
	// 2017/08/02 料金の12%が事前払い by zh BEGIN
	//public static map<String, PAYMENT_CONVERT> getPaymentConfig(String shopCd) {
	public static map<String, List<PAYMENT_CONVERT>> getPaymentConfig(String shopCd) {
	// 2017/08/02 料金の12%が事前払い by zh END
		if (getInstance().mapPaymentConfig.containsKey(shopCd)) {
			return getInstance().mapPaymentConfig.get(shopCd);
        } else {
            throw new CommException('指定の店舗コードの定義情報を見つかりません。['+shopCd+']');
        }
    }
    // 2017/08/02 料金の12%が事前払い by zh BEGIN
	public class PARSEINFO {
		public PARSEINFO(Dom.XmlNode nodePARSEINFO){
			// 初期値
			name = CommUtils.nullToBlank(nodePARSEINFO.getAttribute('NAME',null));
			//Dom.XmlNode partagField = nodePARSEINFO.getChildElement('PAR_TAG', null);
			Dom.XmlNode parbegField = nodePARSEINFO.getChildElement('PAR_BEG', null);
			Dom.XmlNode formatField = nodePARSEINFO.getChildElement('FORMAT', null);
			Dom.XmlNode parendField = nodePARSEINFO.getChildElement('PAR_END', null);
			parbeg = new list<string>();
			format = new list<string>();
			parend = new list<string>();
			//if (partagField != null) partag = CommUtils.nullToBlank(partagField.getText());
			if (parbegField != null) parbeg = CommUtils.nullToBlank(parbegField.getText()).split(';');
			if (formatField != null) format = CommUtils.nullToBlank(formatField.getText()).split(';');
			if (parendField != null) parend = CommUtils.nullToBlank(parendField.getText()).split(';');
		}	
		// 指定文字列に対して、PARSE処理を行う
		public Decimal parsePayInfo(String s) {
		    if (CommUtils.isBlank(s)) return 0;
            for (String formatKey : format) {
                Pattern p=Pattern.compile(formatKey);
                //Matcher m=p.matcher(s); 
                for (String begKey : parbeg) {
                    if (!s.contains(begKey)) continue;
                    String wkBeg = s.subStringAfter(begKey);
                    for (String endKey : parend) {
                        if (!wkBeg.contains(endKey)) continue;
                        String wkEnd = wkBeg.subStringBefore(endKey);
                        Matcher m=p.matcher(wkEnd);  
		                if(m.find()){
		                    String strDeposite = m.group(1);
		                    return CommUtils.nullToZero(strDeposite);
		                }
                    }
                }              
            }
  		    return 0;
		}
		public String name{get;set;}
		public List<String> parbeg{get;set;}	
		public List<String> format{get;set;}
		public List<String> parend{get;set;}
	}
	// 2017/08/02 料金の12%が事前払い by zh END
    // 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ BEGIN
    /*
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
    }*/
    private map<String, List<PAYMENT_CONVERT>> parsePointInfo(Dom.XmlNode shopNode, map<string, PARSEINFO> depositMap) {
    	// 支払情報を取得用定義情報を格納する
    	map<string, List<PAYMENT_CONVERT>> paymentInfoMap = new map<string, List<PAYMENT_CONVERT>>();
		Dom.XmlNode paymentNode = shopNode.getChildElement('PAYMENT_CONVERTS', null);    		   		
		if (paymentNode != null) {
			for (Dom.XmlNode nodeTag : paymentNode.getChildElements()) {
				if (nodeTag.getName() != 'POINT_CONVERT') continue;
				PAYMENT_CONVERT pointCls = new PAYMENT_CONVERT(nodeTag);
				// 関連PARSE用PARSENO属性を定義される場合
				if (!CommUtils.isBlank(pointCls.parseTemplateNo) && 
					depositMap.containsKey(pointCls.parseTemplateNo)) {
                    pointCls.parseTemplate = depositMap.get(pointCls.parseTemplateNo);
System.debug(logginglevel.info,'paymentCls.parseTemplate：：：：：：：：：'+pointCls.parseTemplate);
                }
                // キーに関連解析情報を格納する
                String key = pointCls.getkey();
                if (!paymentInfoMap.containsKey(key)) {
                    paymentInfoMap.put(key, new List<PAYMENT_CONVERT>());
                }
                paymentInfoMap.get(key).add(pointCls);
			}
		}
		return paymentInfoMap;
    }
    // 2017/08/02 料金の12%が事前払い by zh BEGIN
	// カスタマイズの支払情報解析する
    private map<string, PARSEINFO> parsePayDefInfo(Dom.XmlNode shopNode) {
    	map<string, PARSEINFO> depositMap = new map<string, PARSEINFO>();
    	// 2017/08/02 料金の12%が事前払い by zh END
		Dom.XmlNode paymentNode = shopNode.getChildElement('PAYMENT_CONVERTS', null);    		   		
		if (paymentNode != null) {
            // 2017/08/02 料金の12%が事前払い by zh BEGIN
            for (Dom.XmlNode nodeTag : paymentNode.getChildElements()) {
                // 如果节点是PARSEINFO、解析PARSEINFO的内容、把name作为key、解析出来的内容放到map中
                if (nodeTag.getName() == 'PARSE_LOGIC_INFO'){
                    PARSEINFO parseInf = new PARSEINFO(nodeTag);
                    if (CommUtils.isBlank(parseInf.name)) continue;
                    depositMap.put(parseInf.name, parseInf);
                }
            }
		}
		return depositMap;
    }
    // 事前支払情報、事前決済情報を取得する
    // depositMap共通化、パラメータに追加
    //private map<String, List<PAYMENT_CONVERT>> parsePaymentInfo(Dom.XmlNode shopNode) {
    private map<String, List<PAYMENT_CONVERT>> parsePaymentInfo(Dom.XmlNode shopNode, map<string, PARSEINFO> depositMap) {
	// 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ END
    //private map<String, PAYMENT_CONVERT> parsePaymentInfo(Dom.XmlNode shopNode) {
    	//map<string, PAYMENT_CONVERT> paymentInfoMap = new map<string, PAYMENT_CONVERT>();
    	map<string, List<PAYMENT_CONVERT>> paymentInfoMap = new map<string, List<PAYMENT_CONVERT>>();
    	// 事前支払情報を分析定義情報を格納用
    	// 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ BEGIN
    	//map<string, PARSEINFO> depositMap = new map<string, PARSEINFO>();
    	// 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ END
    	// 2017/08/02 料金の12%が事前払い by zh END
		Dom.XmlNode paymentNode = shopNode.getChildElement('PAYMENT_CONVERTS', null);    		   		
		if (paymentNode != null) {
			// 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ BEGIN
			/*
            // 2017/08/02 料金の12%が事前払い by zh BEGIN
            for (Dom.XmlNode nodeTag : paymentNode.getChildElements()) {
                // 如果节点是PARSEINFO、解析PARSEINFO的内容、把name作为key、解析出来的内容放到map中
                if (nodeTag.getName() == 'PARSE_LOGIC_INFO'){
                    PARSEINFO parseInf = new PARSEINFO(nodeTag);
                    if (CommUtils.isBlank(parseInf.name)) continue;
                    depositMap.put(parseInf.name, parseInf);
System.debug(logginglevel.info,'depositMap：：：：：：：：：'+depositMap);
                }
            }
            // 2017/08/02 料金の12%が事前払い by zh END
            */
            // 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ END
			for (Dom.XmlNode nodeTag : paymentNode.getChildElements()) {
				if (nodeTag.getName() != 'PAYMENT_CONVERT') continue;
				PAYMENT_CONVERT paymentCls = new PAYMENT_CONVERT(nodeTag);
		// 2017/08/02 料金の12%が事前払い by zh BEGIN
				//paymentInfoMap.put(paymentCls.getkey(), paymentCls);
                // 支払定義情報に解析用テンプレートを格納する
                if (!CommUtils.isBlank(paymentCls.parseTemplateNo) && 
                     depositMap.containsKey(paymentCls.parseTemplateNo)) {
                    paymentCls.parseTemplate = depositMap.get(paymentCls.parseTemplateNo);
                }
                // キーに関連解析情報を格納する
                String key = paymentCls.getkey();
                if (!paymentInfoMap.containsKey(key)) {
                    paymentInfoMap.put(key, new List<PAYMENT_CONVERT>());
                }
                paymentInfoMap.get(key).add(paymentCls);
		// 2017/08/02 料金の12%が事前払い by zh END
			}
		}
		return paymentInfoMap;
    }
	public class PAYMENT_CONVERT {
		public PAYMENT_CONVERT(Dom.XmlNode nodePayment){
			// 初期値
			paymentKbn = payProdCode = agtCode = '';
			paymentKbn = CommUtils.nullToBlank(nodePayment.getAttribute('PAYKBN',null));
			// 2017/08/02 料金の12%が事前払い by zh BEGIN
			parseTemplate = null;
			parseTemplateNo = CommUtils.nullToBlank(nodePayment.getAttribute('PARSENO',null));
			// 2017/08/02 料金の12%が事前払い by zh END
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
		// 2017/08/02 料金の12%が事前払い by zh BEGIN
		public String parseTemplateNo{get; private set;}
		public PARSEINFO parseTemplate{get;set;}
		// 2017/08/02 料金の12%が事前払い by zh END
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
	private set<String> parsePaymentDefConvert(Dom.XmlNode shopNode,String childTagName) {
    	set<String> paymentConvertSet = new set<String>();
		Dom.XmlNode paymentDefNode = shopNode.getChildElement('PRE_PAYMENT_DEF', null);    		   		
		if (paymentDefNode != null) {
			for (Dom.XmlNode nodeTag : paymentDefNode.getChildElements()) {
				String nodeName = nodeTag.getName();
				if (nodeName == childTagName) {
					String keyWord = CommUtils.nullToBlank(nodeTag.getText());
					paymentConvertSet.addAll(keyWord.split(','));
				}
			}
		}
		return paymentConvertSet;
	}
	public static set<string> getCardPaymentConvertConfig(String shopCd) {
		if (getInstance().preCardPaymentWordConfig.containsKey(shopCd)) {
			return getInstance().preCardPaymentWordConfig.get(shopCd);
        } else {
            throw new CommException('指定の店舗コードの定義情報を見つかりません。['+shopCd+']');
        }
    }
	public static set<string> getCreditPaymentConvertConfig(String shopCd) {
		if (getInstance().preCreditPaymentWordConfig.containsKey(shopCd)) {
			return getInstance().preCreditPaymentWordConfig.get(shopCd);
        } else {
            throw new CommException('指定の店舗コードの定義情報を見つかりません。['+shopCd+']');
        }
    }
    
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
	
	// 2016/11/04 指定のバッチは既に実施されているがどうかチェックする BEGIN
	public static final String TA_LEAD_STATUS_MANAGERIDID = 'TA_LEAD_LOG_000000001';
	public static final String TA_STOCK_STATUS_MANAGERIDID = 'TA_STOCK_LOG_000000001';
	public static final String TA_STAUTS_STOP = 'STOP';
	// 予約取り込み処理は重複起動されるがどう
	public static boolean isLeadRuning(Id jobId) {
		set<string> targetClassNmSet = new set<String>{'TA_LeadSyncNotifyBatch','TA_LeadSyncXmlImportBatch','TA_LeadSyncProcessBatch','TA_LeadSyncNotifyBatchExtend'};
		return isDupStartCheck(targetClassNmSet, jobId, 'TA_LeadSyncNotifyBatch');
	}
	public static boolean isStockRuning(Id jobId) {
		set<string> targetClassNmSet = new set<String>{'TA_StockAdjustmentBatch','TA_StockAdjustmentBatchExtend'};
		return isDupStartCheck(targetClassNmSet, jobId, 'TA_StockAdjustmentBatch');
	}
	public static boolean isLeadDupStartCheck (Id jobId) {
		list<CooperationResult__c> lockData = [select id from CooperationResult__c where ManageID__c = :TA_LEAD_STATUS_MANAGERIDID for update];
		return isLeadRuning(jobId);
	}
	// 在庫調整処理は重複起動されるがどうチェック「スケジュールクラスはチェックなし」
	public static boolean isStockDupStartCheck(Id jobId) {
		list<CooperationResult__c> lockData = [select id from CooperationResult__c where ManageID__c = :TA_STOCK_STATUS_MANAGERIDID for update];
		return isStockRuning(jobId);
	}
	private static boolean isDupStartCheck (set<string> targetClassNmSet, Id selfJobId, string cronName) {
		// 業務処理バッチの対象クラス名を格納する
		//if (targetClassNmSet == null) targetClassNmSet = new set<String>{'TA_LeadSyncXmlImportBatch','TA_LeadSyncProcessBatch','TA_LeadSyncNotifyBatchExtend'};
		//if (cronName == null) cronName = 'TA_LeadSyncNotifyBatch';
		// 該当IDで実施中バッチ存在チェックを行う
		Integer jobs = [Select count() From AsyncApexJob Where ApexClass.Name = :targetClassNmSet and id != :selfJobId  and ( Status = 'Queued' or Status = 'Processing' or Status = 'Preparing' or Status = 'Holding')];  
		if (jobs > 0) return true;
		/*
		// スケジュールに既にスケジュールされるがどうチェックする
		String wkCronName = cronName + '%';
		Integer crons = [select count() from CronTrigger where State != 'DELETED' And CronJobDetail.Name like :wkCronName];
		if (crons > 0) return true;*/
		return false;
	}
	// For Lock Manager Data
	public static void insUpdLeadLockData() {
		writeLogToDb('', TA_LEAD_STATUS_MANAGERIDID, false);
	}
	public static void insUpdStockLockData() {
		writeLogToDb('', TA_STOCK_STATUS_MANAGERIDID, false);
	}
	// 2016/11/04 指定のバッチは既に実施されているがどうかチェックする END
	// 2016/12/14 STOPの濾過　Wgch BEGIN
	public static boolean isLeadBatchStopCheck () {
		list<CooperationResult__c> existRs = [select id from CooperationResult__c where ManageID__c = :TA_LEAD_STATUS_MANAGERIDID And JobProcessType__c =: TA_STAUTS_STOP for update];
		return (!existRs.isEmpty());
	}
	public static boolean isStockBatchStopCheck () {
		list<CooperationResult__c> existRs = [select id from CooperationResult__c where ManageID__c = :TA_STOCK_STATUS_MANAGERIDID And JobProcessType__c =: TA_STAUTS_STOP for update];
		return (!existRs.isEmpty());
	}
	public static void stopLeadBatch() {
		updBatchCtrlFlg(TA_LEAD_STATUS_MANAGERIDID, TA_STAUTS_STOP);
		// 関連の未来のスケジールバッチをクリアする
		String scheduleNm = 'TA_LeadSyncNotifyBatch';
		relAbortJob(scheduleNm);
	}
	public static void stopStockBatch() {
		updBatchCtrlFlg(TA_STOCK_STATUS_MANAGERIDID, TA_STAUTS_STOP);
		// 関連の未来のスケジールバッチをクリアする
		String scheduleNm = 'TA_StockAdjustmentBatch';
		relAbortJob(scheduleNm);
	}
	// スケジール済みクラスを中止する
	private static void relAbortJob(String jobName) {
		String cronJobNm = jobName + '%';
		List<CronTrigger> crons  = [SELECT Id,CronJobDetailId,State FROM CronTrigger WHERE State !=: 'DELETED' And CronJobDetail.Name like :cronJobNm];
		for (CronTrigger cron : crons) {
			try {
				System.abortJob(cron.Id);
			} catch (Exception e) {}
		}
		String scheduleNm = jobName;
		List<AsyncApexJob> apexJobs = [select id from AsyncApexJob where ApexClass.Name = :scheduleNm And status != 'Aborted' and status != 'Completed' And status != 'Failed' ];
		for (AsyncApexJob apexJob : apexJobs) {
			try {
				System.abortJob(apexJob.Id);
			} catch (Exception e) {}
		}
	}
	private static void updBatchCtrlFlg(String jobManagerId, String processType) {
		List<CooperationResult__c> cooperLst = [Select Id,JobProcessType__c,ManageID__c From CooperationResult__c Where ManageID__c =:jobManagerId];
		for(CooperationResult__c cooper : cooperLst){
			cooper.JobProcessType__c = processType;
		}
		update cooperLst;	
	}
	// スケジールを再起動する
	public static String startLeadBatch() {
		updBatchCtrlFlg(TA_LEAD_STATUS_MANAGERIDID, null);
		TA_LeadSyncNotifyBatch schedule = new TA_LeadSyncNotifyBatch();
		String jobName = 'TA_LeadSyncNotifyBatch' + DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, getScheduleRuleStr(), schedule);
		return jobId;
	}
	public static String startStockBatch() {
		updBatchCtrlFlg(TA_STOCK_STATUS_MANAGERIDID, null);
		TA_StockAdjustmentBatch schedule= new TA_StockAdjustmentBatch();
		String jobName = 'TA_StockAdjustmentBatch' + DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, getScheduleRuleStr(), schedule);
		return jobId;
	}
	// クリアバッチ停止フラグ
	public static void clearLeadBatchStopFlg() {
		updBatchCtrlFlg(TA_LEAD_STATUS_MANAGERIDID, NULL);
	}
	public static void clearStockBatchStopFlg() {
		updBatchCtrlFlg(TA_STOCK_STATUS_MANAGERIDID, NULL);
	}
	private static string getScheduleRuleStr() {
		// 該当バッチの最後実施の時刻を取得して、該当時刻から自動復旧連携を行う
		// 質問：１、復旧の場合、自動停止の間在庫連携が漏れになりました、そのため、自動連携を行う/在庫連携を行う
		// 該当スケジールの最後の実施済時間を取得する、該当時刻から連携を行う
		// 停止から時刻連携を行う
		DateTime nowTime = DateTime.now().addSeconds(30);
		// 起動ＣＲＯＮを設定する
		String timeStr = nowTime.format('yyyyMMddHHmmss');
		String yy = timeStr.substring(0,4);
		String mm = timeStr.substring(4,6);
		String dd = timeStr.substring(6,8);
		String hh = timeStr.substring(8,10);
		String ms = timeStr.substring(10,12);
		String ss = timeStr.substring(12,14);
		String sch = ss + ' ' +
		       ms + ' ' +
		       hh + ' ' +
		       dd + ' ' +
		       mm + ' ' +
		       ' ? ' + yy;
		return sch;
	}
	// 2016/12/14 STOPの濾過　Wgch END
    // 2017/08/24 同じエラーは重複送信しないように回避対応 BEGIN
    //public static final String TA_LEAD_DUPSEND_ID = 'TA_LEAD_LOG_000000002';
    public static final String TA_STOCK_DUPSEND_ID = 'TA_STOCK_LOG_000000002';

    //public static boolean isLeadDupErrorMsgCheck (String msg, Boolean isUpdFlg) {
    //    return processDupErrorMsg(TA_LEAD_DUPSEND_ID, msg, isUpdFlg); 
    //}
    public static boolean isStockDupErrorMsgCheck (String msg, Boolean isUpdFlg) {
       return processDupErrorMsg(TA_STOCK_DUPSEND_ID, msg, isUpdFlg);
    }
    private static Boolean processDupErrorMsg(String managerId, String msg, Boolean isUpdFlg) {
        DateTime nowDt = System.now();
        list<CooperationResult__c> existRs = [select id,ManageID__c,ErrorContent__c,LastModifiedDate from CooperationResult__c 
            where ManageID__c = :managerId And ProcessingType__c = :TA_ServiceCtrl.SERVICE_KEY];
        // 管理データが既に存在する場合
        CooperationResult__c chkRs = null;
        if (!existRs.isEmpty()) {
            chkRs = existRs[0];
            // 既存エラー情報は今回のエラー情報と一致 かつ　２４時間以内の場合、該当メッセージは重複メッセージで認識する
            if (chkRs.ErrorContent__c == msg) return true;
            chkRs.ErrorContent__c = msg;
        } else {
            chkRs = new CooperationResult__c(
                ErrorContent__c = msg,
                ManageID__c = managerId,
                FunctionType__c = CommConst.COOP_FUNTYPE_OPPLOG,
                ProcessingType__c = TA_ServiceCtrl.SERVICE_KEY
            );
        }
        if (isUpdFlg) upsert chkRs CooperationResult__c.ManageID__c;
        return false;
    }
    // 2017/08/24 同じエラーは重複送信しないように回避対応  END
}