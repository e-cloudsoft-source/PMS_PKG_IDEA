/***************************
* JR処理機能共通ヘルプクラス
* 2016/01/29 リアル（旅行会社）に対して、在庫更新要求を発行する・しない制御パラメータを追加
* 2016/03/22 お客様情報解析用情報の格納
* 2016/05/12 事前決済区分と登録の支払商品情報マッピング
* 2016/06/10 子供料金プラン取り込み機能対応
* 2017/02/21 お子様プランの料金PRICE機能追加 
* 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応
* 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応
* 2018/04/09 JR2way機能追加対応
* 2018/08/10 TL->JR変換の紐付ける処理の対応
* 2018/09/03 JR2way最大連携期間定義できる
* 2018/12/30 JR予約変更通知の際に、部屋タイプを自動変更できるように改善対応
* 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応
* 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する
* 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善
* 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善
* 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加
* 2019/11/30 子供料金（RoomDateGuestList)取り込みできるように改善対応
****************************/
public with sharing class BI_JR_ServiceConfigHelp {
	
	public enum ProcessingType{TL,TA,TR,JR}
	// 2018/04/09 JR2way機能追加対応 BEGIN
	//private static final BI_JR_ServiceConfigHelp instance = new BI_JR_ServiceConfigHelp();
	// 2018/04/09 JR2way機能追加対応 END
	// JR2way連動機能設定ファイル名
	private static final String XmlConfigName = 'JRServiceConfigXml';
	// 2018/04/09 JR2way機能追加対応 BEGIN
	public static final Integer DEF_MIN_INTERVAL = 300;//最小5分[予約取り込み用]
	public static final Integer DEF_MIN_INTERVAL_STOCK = 300;//最小90秒「在庫調整バッチ」
	public static final Integer SYNC_RANGE_DAYS = 31;//1回在庫連携の最大日数
	private static BI_JR_ServiceConfigHelp instance = null;
	private static BI_JR_ServiceConfigHelp getInstance() {
		if(instance == null) instance = new BI_JR_ServiceConfigHelp();
		return instance;
	}
	// 2018/04/09 JR2way機能追加対応 END
	private String defaultShopCode = null;
	private BI_JR_ServiceConfigHelp() {
		// XML LOADINGから定義情報を格納する
		mapAppConfig = new map<String, APPCONFIG>();
		// サビース料と入湯税
		mapAccConfig = new map<String, ACCOUNTCONFIG>();
		// PLANコード変換表 map<店舗コード, map<AGT名,map<agtのPacakgeコード，sfのプランNo）
		mapPlanConvertAgt2SfMap = new map<String, map<String, map<string, string>>>(); 
        // 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応 by zh BEGIN
        mapPlanConvertAgt2SfNameFlgMap = new map<String, Boolean>();
        // 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応 by zh END
		// 事前決済区分と登録の支払商品情報マッピング
		mapPaymentConfig = new map<String ,map<String, PAYMENT_CONVERT>>();
		mapPointConfig = new map<String ,map<String, PAYMENT_CONVERT>>();
		// 支払方法文言変換ルール
		preCardPaymentWordConfig = new map<String, set<String>>();
		preCreditPaymentWordConfig = new map<String, set<String>>();
		// 子供料金プラン取り込み機能対応 BEGIN
		mapChildPlanConvertConfig = new map<String, map<string, string>>();
		// 2017/02/21 お子様プランの料金PRICE機能追加 by zh BEGIN
		mapChildPlanPriceConvertConfig = new map<String, map<string, string>>(); 
		// 2017/02/21 お子様プランの料金PRICE機能追加 by zh END
		// 子供料金プラン取り込み機能対応 END
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
				// 入湯税とサビース料
				mapAccConfig.put(strShopCode, new ACCOUNTCONFIG(node));
				// AGT名単位のプラン変換処理情報の格納
				mapPlanConvertAgt2SfMap.put(strShopCode, parsePlanConvertParse(strShopCode, node));
				// 事前決済区分と登録の支払商品情報マッピング
				mapPaymentConfig.put(strShopCode, parsePaymentInfo(node));
				mapPointConfig.put(strShopCode, parsePointInfo(node));
				preCardPaymentWordConfig.put(strShopCode, parsePaymentDefConvert(node, 'CRAD'));
				preCreditPaymentWordConfig.put(strShopCode,parsePaymentDefConvert(node, 'CREDIT'));
				// 子供料金プラン取り込み機能対応 BEGIN
				// 2017/02/21 お子様プランの料金PRICE機能追加 by zh BEGIN
				//mapChildPlanConvertConfig.put(strShopCode, parseChildPlanConvert(node));
				map<string,map<string,string>> wkChildPlanConvertMap = parseChildPlanConvert(node);
				mapChildPlanConvertConfig.put(strShopCode, wkChildPlanConvertMap.get(DEF_CHILDPLAN_RATE));
				mapChildPlanPriceConvertConfig.put(strShopCode, wkChildPlanConvertMap.get(DEF_CHILDPLAN_PRICE));
				// 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ BEGIN
				mapChildPlanNameConvertConfig.put(strShopCode, wkChildPlanConvertMap.get(DEF_CHILDPLAN_NAMEONLY));
				// 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ END
				// 2017/02/21 お子様プランの料金PRICE機能追加 by zh END
				// 子供料金プラン取り込み機能対応 END
				// 2016/07/10 予約チャネル名の変換機能追加対応 BEGIN
				mapAgtToChanelConfig.put(strShopCode, parseAGTToChanelConvert(node));
				// 2016/07/10 予約チャネル名の変換機能追加対応 END
			}
			
		}
	}
	
	private map<String, APPCONFIG> mapAppConfig;
	// 入湯税とサビース料
	private map<String, ACCOUNTCONFIG> mapAccConfig;
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
	// 支払方法文言変更ルール
	private map<String, set<String>> preCardPaymentWordConfig;		// 事前カード決済キーワード
	private map<String, set<String>> preCreditPaymentWordConfig;	// 売掛明細キーワード
	// 該当店舗コードはTLサイトコントローラと契約済がどうかチェックを行う
	// 2016/06/10 子供料金プラン取り込み機能対応 BEGIN
	private map<String, map<string,string>> mapChildPlanConvertConfig;	// 子供料金変換ルール情報格納
	// 2017/02/21 お子様プランの料金PRICE機能追加 by zh BEGIN
	private map<String, map<string,string>> mapChildPlanPriceConvertConfig;	
	// 2017/02/21 お子様プランの料金PRICE機能追加 by zh END
	// 2016/06/10 子供料金プラン取り込み機能対応 END
	// XMLの中に、該当店舗コードを定義されていると、契約済として、判断する
	public static Boolean isContractShop(String shopCd) {
		return getInstance().mapAppConfig.containsKey(shopCd);
	}
	// XMLに定義情報存在チェツク、SHOPタグ定義情報がない場合、TL連携機能を起動しません
	public static Boolean jrSyncIsOpen() {
		return (getInstance().mapAppConfig.size() > 0);
	}
	// ****************************************
	// JR2WAY連携処理、共通定義パラメータ情報を取得する
	// ****************************************
	public static COMMCONFIG getCommConfig () {
		return getInstance().commConfig;
	}
	// ****************************************
	// JR2WAY連携処理、各店舗個別定義必要情報取得する
	// shopCd : 店舗コード
	// return : 該当店舗の定義情報を戻る
	// exception: 該当店舗コードはXMLに未定義されている場合、エラー戻る
	// ****************************************
	public static APPCONFIG getAppConfig(String pShopCd) {
    	// 指定の店舗コードの定義値は未定義の場合、デフォルト店舗設定値を取得する
    	String shopCd = !getInstance().mapAppConfig.containsKey(pShopCd) ? getInstance().defaultShopCode : pShopCd;
        if (getInstance().mapAppConfig.containsKey(shopCd)) {
            return getInstance().mapAppConfig.get(shopCd);
        } else {
            throw new CommException('指定の店舗コードの定義情報を見つかりません。['+pShopCd+']');
        }
    }
	// ****************************************
	// JR2way連携処理、エラー処理情報の格納
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
	// JR2WAY連携処理、エラー処理情報の格納
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

	// ****************************************
	// JR2way連携処理、AGTのパッケージコードにより、SFのプランNO情報を取得する
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
        if (getInstance().mapPlanConvertAgt2SfNameFlgMap.containsKey(shopCd)) {
            return getInstance().mapPlanConvertAgt2SfNameFlgMap.get(shopCd);
        }
        return false;
    }
	// 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応 by zh END
	// 共通定義情報の格納
	public class COMMCONFIG { 
		public COMMCONFIG(Dom.XmlNode node){
			// JRと店舗マッピング定義情報
            shopNameMatchMap = new map<String, String>();
            Dom.XmlNode codeMatchNodeRoot =  node.getChildElement('SHOPCODE_MATCH', null);
            if (codeMatchNodeRoot != null) {
                for (Dom.XMLNode shopNode : codeMatchNodeRoot.getChildElements()) {
                    String xmlShopName = CommUtils.nullToBlank(shopNode.getAttribute('XMLSHOPNAME',null));
                    String sfdcShopCode = CommUtils.nullToBlank(shopNode.getText());
                    if (!CommUtils.isBlank(xmlShopName)) {
                        shopNameMatchMap.put(xmlShopName,sfdcShopCode);
                    }
                }
            }
            // 2018/04/09 JR2way機能追加対応 BEGIN
            Dom.XmlNode stockIntervalField = node.getChildElement('STOCKINTERVAL', null);
            Dom.XmlNode leadImpIntervalField = node.getChildElement('LEADINTERVAL', null);
            Dom.XmlNode stockDeleteValField = node.getChildElement('STOCKDELETEVAL', null);
            Dom.XmlNode leadDeleteValField = node.getChildElement('LEADDELETEVAL', null);
			
			mStockInterval = (stockIntervalField == null) ? 60 : CommUtils.nullToIntZero(stockIntervalField.getText());
			mStockDeleteVal = (stockDeleteValField == null) ? -14 : CommUtils.nullToIntZero(stockDeleteValField.getText());
			mLeadImportInterval = (leadImpIntervalField == null) ? 60 :CommUtils.nullToIntZero(leadImpIntervalField.getText());
			mLeadDeleteVal = (leadDeleteValField == null) ? -14 : CommUtils.nullToIntZero(leadDeleteValField.getText());
			// 2016/08/08 インターバル定義情報は最小90秒まで定義できる変更 BEGIN
			if (mStockInterval <= DEF_MIN_INTERVAL_STOCK) mStockInterval = DEF_MIN_INTERVAL_STOCK;
			if (mLeadImportInterval <= DEF_MIN_INTERVAL) mLeadImportInterval = DEF_MIN_INTERVAL;
			// 2016/08/08 インターバル定義情報は最小90秒まで定義できる変更 END
			if (mStockDeleteVal == null) mStockDeleteVal = -14;
			if (mLeadDeleteVal == null) mLeadDeleteVal = -14;
			// SITE URL
			Dom.XmlNode serviceUrlField = node.getChildElement('SERVICE_URL', null);
			serviceUrl = (serviceUrlField == null) ? 'http://devpms.raku-2.jp' : CommUtils.nullToBlank(serviceUrlField.getText());
			// 2018/04/09 JR2way機能追加対応 END
            //DEBUG MODE NODE
			Dom.XmlNode isDebugField = node.getChildElement('ISDEBUG', null);
			bIsDebug = (isDebugField == null) ? false : Boolean.valueOf(CommUtils.nullToBlank(isDebugField.getText()));
            
            // XXミリ秒以内すると、予約インデックスと同時に作成される予約情報（2015/12/14)
			mLeadTimeLimit = 60000;	// １分以内
			Dom.XmlNode mLeadTimeLimitField = node.getChildElement('TARGET_LEAD_TIMELIMIT', null);
			if (mLeadTimeLimitField != null) mLeadTimeLimit = CommUtils.nullToIntZero(mLeadTimeLimitField.getText());
			
			// 2018/09/03 JR2way最大連携期間定義できる BEGIN
			stockSyncMaxMonths = 13;//デフォルトは実施日から１３ヶ月の最終日まで連携する
			Dom.xmlNode mStockSyncMaxMonthsField = node.getChildElement('STOCK_SYNC_MAX_MONTHS', null);
			if (mStockSyncMaxMonthsField != null) {
				String stockSyncMaxMonthsStr = CommUtils.nullToBlank(mStockSyncMaxMonthsField.getText());
				if (!CommUtils.isBlank(stockSyncMaxMonthsStr)) stockSyncMaxMonths = CommUtils.nullToIntZero(stockSyncMaxMonthsStr);
			}
			// 2018/09/03 JR2way最大連携期間定義できる END
			// 2018/12/20 JRリクエスト間に間隔秒数定義パラメータ対応 WSQ BEGIN
			sleepTime = 1100;
			Dom.xmlNode sleepTimeField = node.getChildElement('STOCK_SYNC_REQ_SLEEP', null);
			if (sleepTimeField != null) {
				String sleepTimeStr = CommUtils.nullToBlank(sleepTimeField.getText());
				if (!CommUtils.isBlank(sleepTimeStr)) sleepTime = CommUtils.nullToIntZero(sleepTimeStr);
			}
			// 2018/12/20 JRリクエスト間に間隔秒数定義パラメータ対応 WSQ END
		}
		public Boolean bIsDebug{get;private set;}		// DEBUGモード制御フラグ
		public Integer mLeadTimeLimit{get;set;}			// 予約データの予約番号&&発生源なしの場合、TL電文から作成の予約識別用TIMESTAM
		public Map<String,String> shopNameMatchMap{get;private set;}
		// 2018/04/09 JR2way機能追加対応 BEGIN
		public Integer mStockInterval{get;set;}			// 在庫連携情報のスケジュールのINTERVAL秒数（秒単位）
		public Integer mLeadImportInterval{get;set;}	// 予約取込機能のスケジュールのINTERVAL秒数（秒単位）
		public Integer mStockDeleteVal{get;set;}		// 在庫変更履歴情報の削除日付数（日単位）
		public Integer mLeadDeleteVal{get;set;}		// 予約取込履歴情報の削除日付数（日単位）
		public String serviceUrl{get;set;}
		// 2018/04/09 JR2way機能追加対応 END
		
		// 2018/09/03 JR2way最大連携期間定義できる BEGIN
		public Integer /*STOCK_SYNC_MAX_MONTHS*/ stockSyncMaxMonths{get; set;}
		// 2018/09/03 JR2way最大連携期間定義できる END
		// 2018/12/20 JRリクエスト間に間隔秒数定義パラメータ対応 BEGIN
		public Integer sleepTime{get;set;}
		// 2018/12/20 JRリクエスト間に間隔秒数定義パラメータ対応 END
	}
	
	public class APPCONFIG{
		public APPCONFIG(Dom.XmlNode shopNode){
    		Dom.XmlNode configNode = shopNode.getChildElement('APPCONFIG', null);   		    		
    		if (configNode != null) {
    			//Dom.XmlNode systemIdField = configNode.getChildElement('SYSTEMID', null);
    			//Dom.XmlNode userIdField = configNode.getChildElement('USERID', null);
    			//Dom.XmlNode passwordField = configNode.getChildElement('PASSWORD', null);
    			Dom.XmlNode ucactisSyncField = configNode.getChildElement('UCACTISSYNC', null);
                Dom.XmlNode roomSortField = configNode.getChildElement('ROOMSORT', null);
                Dom.XmlNode roomAtuoAssignField = configNode.getChildElement('ROOMAUTOASSIGN', null);
                Dom.XmlNode leadAutoSetupFields = configNode.getChildElement('DEFAULTVALUES', null);
                // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh BEGIN
                Dom.XmlNode chgdtRoomClearField = configNode.getChildElement('CHGDT_ROOMCLR', null);
                // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh END
                // 2018/12/30 TR予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh BEGIN
                Dom.XmlNode chgRoomTypeField = configNode.getChildElement('CHGROOMTYPE', null);
                // 2018/12/30 TR予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh END
                //2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応  by zh BEGIN
                Dom.XmlNode payMeaidToLastDayField = configNode.getChildElement('PAYMEDIATOLASTDAY', null);
                //2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応  by zh END    
                // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ BEGIN
                Dom.XmlNode modifyEstItemsField = configNode.getChildElement('RESET_ESTITEMS', null);
                // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ END
                // 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 WSQ BEGIN
                Dom.XmlNode romanToKanaField = configNode.getChildElement('CHGROMANTOKANA', null);
                // 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 WSQ END     
                // 2019/11/30 子供料金（RoomDateGuestList)取り込みできるように改善対応 WSQ BEGIN
                Dom.XmlNode guestRateField = configNode.getChildElement('CHGGUESTRATE', null);
                // 2019/11/30 子供料金（RoomDateGuestList)取り込みできるように改善対応 WSQ END
                //Dom.XmlNode realStockReqSyncFields = configNode.getChildElement('RELA_STOCK_REQ_SYNC', null);
    			//if (systemIdField != null) systemId = CommUtils.nullToBlank(systemIdField.getText());
    			//if (userIdField != null) userId = CommUtils.nullToBlank(userIdField.getText());
    			//if (passwordField != null) password = CommUtils.nullToBlank(passwordField.getText());
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
    			// 2016/01/29 リアル（旅行会社）に対して、在庫更新要求を発行する・しない制御パラメータを追加 BEGIN
    			//realStockReqSync = false;	  
                //if (realStockReqSyncFields != null) {
                //	realStockReqSync = Boolean.valueOf(CommUtils.nullToBlank(realStockReqSyncFields.getText()));
                //}
                // 2016/01/29 リアル（旅行会社）に対して、在庫更新要求を発行する・しない制御パラメータを追加 END
                // 2016/08/04 予約チャネルの設定元の制御フラグ BEGIN
                chanelFromCompany = true;
                Dom.XmlNode chanelFromCompanyField = configNode.getChildElement('COMPANYTOCHANEL', null);
                if (chanelFromCompanyField != null) chanelFromCompany = Boolean.valueOf(CommUtils.nullToBlank(chanelFromCompanyField.getText()));
                // 2016/08/04 予約チャネルの設定元の制御フラグ END
                // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh BEGIN
		        chgdtRoomClearFlag = false;
    			if (chgdtRoomClearField != null){
    				String chgStr = CommUtils.nullToBlank(chgdtRoomClearField.getText());
    				if(!CommUtils.isBlank(chgStr))
    					chgdtRoomClearFlag = Boolean.valueOf(chgStr);
    			}
		        // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh END
		        
                // 2018/04/09 JR2way機能追加対応 BEGING
                // ネット取り込みエラーの場合、リトライ処理をする・しない制御処理追加
                retrySync = false;
                Dom.XmlNode retrySyncFields = configNode.getChildElement('RETRYSYNC', null);
                if (retrySyncFields != null) {
                    retrySync = Boolean.valueOf(CommUtils.nullToBlank(retrySyncFields.getText()));
                }
                // ログイン情報取得する  
                Dom.XmlNode userNameField = configNode.getChildElement('USERNAME', null);
                Dom.XmlNode hotelCodeField = configNode.getChildElement('HOTELCODE', null);
                Dom.XmlNode passwordField = configNode.getChildElement('HOTELPASSWORD', null);
                if (userNameField != null) userName = CommUtils.nullToBlank(userNameField.getText());
                if (hotelCodeField != null) hotelCode = CommUtils.nullToBlank(hotelCodeField.getText());
                if (passwordField != null) password = CommUtils.nullToBlank(passwordField.getText());
                // 2018/04/09 JR2way機能追加対応 END
                // 2018/08/10 TL->JR変換の紐付ける処理の対応 BEGIN
                tl2jrFlg = false;
                Dom.XmlNode tl2jrField = configNode.getChildElement('TL2JRRELFLG', null);
                if(tl2jrField != null){ 
                    tl2jrFlg = Boolean.valueOf(CommUtils.nullToBlank(tl2jrField.getText()));
                }
        		// 2018/08/10 TL->JR変換の紐付ける処理の対応 END
				// 2018/12/30 JR予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh BEGIN
                chgRoomTypeFlag = false;
				if (chgRoomTypeField != null){
					String chgTypeStr = CommUtils.nullToBlank(chgRoomTypeField.getText());
					if(!CommUtils.isBlank(chgTypeStr)) chgRoomTypeFlag = Boolean.valueOf(chgTypeStr);
				}
				// 2018/12/30 JR予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh END	
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
                // 2019/11/30 子供料金（RoomDateGuestList)取り込みできるように改善対応 WSQ BEGIN
                guestRateFlag = false;
    			if (guestRateField != null){
    				String s = CommUtils.nullToBlank(guestRateField.getText());
    				if(!CommUtils.isBlank(s)) guestRateFlag = Boolean.valueOf(s);
    			} 
                // 2019/11/30 子供料金（RoomDateGuestList)取り込みできるように改善対応 WSQ END
    		}
		}
		public String userName{get;set;}
		public String hotelCode{get;set;}
		public String password{get;set;}
		public boolean ucactisSync{get;set;}
        public String roomSortKey{get;set;}
        public boolean roomAutoAssignFlag{get;set;}
        public Map<String,Object> fieldMap{get;set;}
        // 2016/01/29 リアル（旅行会社）に対して、在庫更新要求を発行する・しない制御パラメータを追加
        //public boolean realStockReqSync{get;set;}
        // 2018/04/09 JR2way機能追加対応
        // ネット取り込みエラーの場合、リトライ処理をする・しない制御処理追加
        public boolean retrySync{get;private set;}
        // 2016/08/04 予約チャネルの設定元の制御フラグ；TRUE:旅行会社名で設定(デフォルト値)、FALSE:旅行営業所で設定
        public boolean chanelFromCompany{get;private set;}
        // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh BEGIN
        public boolean chgdtRoomClearFlag{get;set;}
        // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh END
        // 2018/08/10 TL->JR変換の紐付ける処理の対応 BEGIN
        public boolean tl2jrFlg{get;set;}
        // 2018/08/10 TL->JR変換の紐付ける処理の対応 END
        // 2018/12/30 JR予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh BEGIN
        public boolean chgRoomTypeFlag{get;set;}
        // 2018/12/30 JR予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh END
        // 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応 by zh BEGIN
        public boolean payMeaidToLastDayFlag{get;set;}
        // 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応 by zh END
        // 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ BEGIN
        public boolean contactAlwaysNew{get;set;}
        // 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ 
        // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ BEGIN
        public boolean modifyEstItemsFlag{get;set;}
        // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ END
        // 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 WSQ BEGIN
        public boolean romanToKanaFlag{get;set;}
        // 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 WSQ END
        // 2019/11/30 子供料金（RoomDateGuestList)取り込みできるように改善対応 WSQ BEGIN
        public boolean guestRateFlag{get;set;}
        // 2019/11/30 子供料金（RoomDateGuestList)取り込みできるように改善対応 WSQ END
	}
	

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
    
    // 2WAY用 BEGIN
    // 2016/05/05 バッチログ記録共通機能 BEGIN
	public static void writeLogToDb(String logMsg, string mangerId, boolean isInit) {
		// 2017/02/21 Field Security Check BEGIN
		List<String> chkFields = new List<String>{'ProcessingType__c','ManageID__c','ProcessLog__c','MailSendComplete__c','FunctionType__c'};
		Map<String,Schema.SObjectField> m = Schema.SObjectType.CooperationResult__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFields, m)) {
			return;
		}
		// 2017/02/21 Field Security Check End
		String SERVICE_KEY = 'JR';
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
	// 2WAY用 END
	// 2016/05/05 バッチログ記録共通機能 END
	// 2016/05/12 事前決済区分と登録の支払商品情報マッピング　BEGIN
	// ****************************************
	// JR2way連携処理、エラー処理情報の格納
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
	
    // 2018/04/09 JR2way機能追加対応 BEGIN
	// 2016/11/04 指定のバッチは既に実施されているがどうかチェックする BEGIN
	public static final String JR_LEAD_STATUS_MANAGERIDID = 'JR_LEAD_LOG_000000001';
	public static final String JR_STOCK_STATUS_MANAGERIDID = 'JR_STOCK_LOG_000000001';
	public static final String JR_STAUTS_STOP = 'STOP';
	// バッチ起動されるがどうチェックを行う[取り込み]
	public static boolean isLeadRuning(Id jobId) {
		set<string> targetClassNmSet = new set<String>{'JR_LeadSyncNotifyBatch','JR_LeadSyncXmlImportBatch','JR_LeadSyncProcessBatch','JR_LeadSyncNotifyBatchExtend'};
		return isDupStartCheck(targetClassNmSet, jobId, 'JR_LeadSyncNotifyBatch');
	}
	// バッチ起動されるがどうチェックを行う[在庫調整]
	public static boolean isStockRuning(Id jobId) {
		set<string> targetClassNmSet = new set<String>{'JR_StockAdjustmentBatch','JR_StockAdjustmentBatchExtend'};
		return isDupStartCheck(targetClassNmSet, jobId, 'JR_StockAdjustmentBatch');
	}
	// 予約取り込み処理は重複起動されるがどう
	public static boolean isLeadDupStartCheck (Id jobId) {
		list<CooperationResult__c> lockData = [select id from CooperationResult__c where ManageID__c = :JR_LEAD_STATUS_MANAGERIDID for update];
		return isLeadRuning(jobId);
	}
	public static boolean isStockDupStartCheck(Id jobId) {
		list<CooperationResult__c> lockData = [select id from CooperationResult__c where ManageID__c = :JR_STOCK_STATUS_MANAGERIDID for update];
		return isStockRuning(jobId);
	}
	// 該当IDで実施中バッチ存在チェックを行う
	private static boolean isDupStartCheck (set<string> targetClassNmSet, Id selfJobId, String cronName) {
		// 該当IDで実施中バッチ存在チェックを行う
		Integer jobs = [Select count() From AsyncApexJob Where ApexClass.Name = :targetClassNmSet and id != :selfJobId  and ( Status = 'Queued' or Status = 'Processing' or Status = 'Preparing' or Status = 'Holding')];  
		if (jobs > 0) return true;
		return false;
	}
	// For Lock Manager Data
	public static void insUpdLeadLockData() {
		writeLogToDb('', JR_LEAD_STATUS_MANAGERIDID, false);
	}
	public static void insUpdStockLockData() {
		writeLogToDb('', JR_STOCK_STATUS_MANAGERIDID, false);
	}
	// 2016/11/04 指定のバッチは既に実施されているがどうかチェックする END
	// 2016/12/14 STOPの濾過　Wgch BEGIN
	public static boolean isLeadBatchStopCheck () {
		list<CooperationResult__c> existRs = [select id from CooperationResult__c where ManageID__c = :JR_LEAD_STATUS_MANAGERIDID And JobProcessType__c = :JR_STAUTS_STOP for update];
		return (!existRs.isEmpty());
	}
	public static boolean isStockBatchStopCheck () {
		list<CooperationResult__c> existRs = [select id from CooperationResult__c where ManageID__c = :JR_STOCK_STATUS_MANAGERIDID And JobProcessType__c = :JR_STAUTS_STOP for update];
		return (!existRs.isEmpty());
	}
	private static void updBatchCtrlFlg(String jobManagerId, String processType) {
		List<CooperationResult__c> cooperLst = [Select Id,JobProcessType__c,ManageID__c From CooperationResult__c Where ManageID__c =:jobManagerId];
		for(CooperationResult__c cooper : cooperLst){
			cooper.JobProcessType__c = processType;
		}
		update cooperLst;	
	}
	// バッチ停止処理
	public static void stopLeadBatch() {
		updBatchCtrlFlg(JR_LEAD_STATUS_MANAGERIDID, JR_STAUTS_STOP);
		// 未来実施予定のスケジールも停止が必要、その場合、JOB停止処理が必要
		// 関連の未来のスケジールバッチをクリアする
		String scheduleNm = 'JR_LeadSyncNotifyBatch';
		relAbortJob(scheduleNm);
	}
	public static void stopStockBatch() {
		updBatchCtrlFlg(JR_STOCK_STATUS_MANAGERIDID, JR_STAUTS_STOP);
		// 未来実施予定のスケジールも停止が必要、その場合、JOB停止処理が必要
		// 関連の未来のスケジールバッチをクリアする
		String scheduleNm = 'JR_StockAdjustmentBatch';
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
	// バッチ再起動処理
	public static String startLeadBatch() {
		updBatchCtrlFlg(JR_LEAD_STATUS_MANAGERIDID, NULL);
		JR_LeadSyncNotifyBatch schedule = new JR_LeadSyncNotifyBatch();
		String jobName = 'JR_LeadSyncNotifyBatch' + DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, getScheduleRuleStr(), schedule);
		return jobId;
	}
	public static String startStockBatch() {
		updBatchCtrlFlg(JR_STOCK_STATUS_MANAGERIDID, NULL);
		JR_StockAdjustmentBatch schedule= new JR_StockAdjustmentBatch();
		String jobName = 'JR_StockAdjustmentBatch' + DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, getScheduleRuleStr(), schedule);
		return jobId;
	}
	// クリアバッチ停止フラグ
	public static void clearLeadBatchStopFlg() {
		updBatchCtrlFlg(JR_LEAD_STATUS_MANAGERIDID, NULL);
	}
	public static void clearStockBatchStopFlg() {
		updBatchCtrlFlg(JR_STOCK_STATUS_MANAGERIDID, NULL);
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
	// 2017/08/24 同じエラーは重複送信しないように回避対応 BEGIN
    public static final String JR_STOCK_DUPSEND_ID = 'JR_STOCK_LOG_000000002';
    public static boolean isStockDupErrorMsgCheck (String msg, Boolean isUpdFlg) {
       return processDupErrorMsg(JR_STOCK_DUPSEND_ID, msg, isUpdFlg);
    }
    private static Boolean processDupErrorMsg(String managerId, String msg, Boolean isUpdFlg) {
        DateTime nowDt = System.now();
        list<CooperationResult__c> existRs = [select id,ManageID__c,ErrorContent__c,LastModifiedDate from CooperationResult__c 
            where ManageID__c = :managerId And ProcessingType__c = :JR_ServiceCtrl.SERVICE_KEY];
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
                ProcessingType__c = JR_ServiceCtrl.SERVICE_KEY
            );
        }
        if (isUpdFlg) upsert chkRs CooperationResult__c.ManageID__c;
        return false;
    }
    // 2018/04/09 JR2way機能追加対応 END
}