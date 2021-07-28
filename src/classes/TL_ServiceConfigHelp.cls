/***************************
* TL2WAY処理機能共通ヘルプクラス
* 2016/01/29 リアル（旅行会社）に対して、在庫更新要求を発行する・しない制御パラメータを追加
* 2016/03/22 お客様情報解析用情報の格納
* 2016/05/12 事前決済区分と登録の支払商品情報マッピング
* 2016/06/10 子供料金プラン取り込み機能対応
* 2016/08/08 インターバル定義情報は最小90秒まで定義できる変更
* 2016/10/16 ネット取り込みエラーの場合、リトライ処理をする・しない制御処理追加
* 2017/02/21 お子様プランの料金PRICE機能追加 
* 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応
* 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応
* 2017/08/15 ネット取込(TL2way)機能、変更通知（２泊→１泊に変更）が来た際に、子部屋２日目の夕食レストランの席がキャンセルできるように改善対応
* 2017/08/24 同じエラーは重複送信しないように回避対応
* 2017/10/09 ポイント取込はうまくと、見積明細商品名称は会計商品名またはタグ値で切替設定できるよに改善対応
* 2018/07/19 TL取り込みの総計人数が不正改善対応
* 2018/10/16 TL2way予約変更通知の際に、部屋タイプを自動変更できるように改善対応
* 2018/12/15 TL2way会計人数制御改善(大人人数のみ予約人数に反映する)
* 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応
* 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する
* 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善
* 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善
* 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加
* 2020/09/15 OTAからの予約取り込み時に「楽天ポイント」と「楽天クーポン」が分かれて取り込みできる
****************************/
public with sharing class TL_ServiceConfigHelp {
	
	public enum ProcessingType{TL,TA,TR,JR}
	public static final Integer DEF_MIN_INTERVAL = 90;//最小90秒
	private static TL_ServiceConfigHelp instance = null;
	private static TL_ServiceConfigHelp getInstance() {
		if(instance == null) instance = new TL_ServiceConfigHelp();
		return instance;
	}
	// TL2WAY連動機能設定ファイル名
	private static final String XmlConfigName = 'Tl2wayServiceConfigXml';

	private TL_ServiceConfigHelp() {
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
			}
			
		}
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
	public static Boolean tlSyncIsOpen() {
		return (getInstance().mapAppConfig.size() > 0);
	}
	// ****************************************
	// TL2WAY連携処理、共通定義パラメータ情報を取得する
	// ****************************************
	public static COMMCONFIG getCommConfig () {
		return getInstance().commConfig;
	}
	// ****************************************
	// TL2WAY連携処理、各店舗個別定義必要情報取得する
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
	// TL2WAY連携処理、エラー処理情報の格納
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
	// TL2WAY連携処理、エラー処理情報の格納
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
	// TL2WAY連携処理、AGTのパッケージコードにより、SFのプランNO情報を取得する
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
	// TL2WAY連携処理、エラー処理情報の格納
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
		public COMMCONFIG(Dom.XmlNode node){
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
			strServiceUrl = (serviceUrlField == null) ? 'https://test472.tl-lincoln.net' : CommUtils.nullToBlank(serviceUrlField.getText());
	    		
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
		}
		public Boolean bIsDebug{get;private set;}		// DEBUGモード制御フラグ
		public Integer mStockInterval{get;set;}			// 在庫連携情報のスケジュールのINTERVAL秒数（秒単位）
		public Integer mLeadImportInterval{get;set;}	// 予約取込機能のスケジュールのINTERVAL秒数（秒単位）
		public Integer mStockDeleteVal{get;set;}		// 在庫変更履歴情報の削除日付数（日単位）
		public Integer mLeadDeleteVal{get;set;}		// 予約取込履歴情報の削除日付数（日単位）
		public String strServiceUrl{get;set;}
		public Integer mLeadTimeLimit{get;set;}			// 予約データの予約番号&&発生源なしの場合、TL電文から作成の予約識別用TIMESTAMP判別用ミリ秒
        public Integer syncMaxDays{get;set;}			// 処理日から在庫調整最大日数（デイフォル：180日まで）（2015/12/14)
		public Boolean bIsSyncOnlyNewFlg{get;set;}		// バッチ起動後作成の在庫調整情報のみ連携する
		public Date restoreStartDate{get;set;}			// バッチ再起動の場合、連携開始日付を指定する
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
                Dom.XmlNode realStockReqSyncFields = configNode.getChildElement('RELA_STOCK_REQ_SYNC', null);
                // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh BEGIN
                Dom.XmlNode chgdtRoomClearField = configNode.getChildElement('CHGDT_ROOMCLR', null);
                // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh END
                // 2017/10/09 ポイント取込はうまくと、見積明細商品名称は会計商品名またはタグ値で切替設定できるよに改善対応 by zh BEGIN
                Dom.XmlNode sfPointNmField = configNode.getChildElement('XMLPOINTNAMETOEST', null);
                // 2017/10/09 ポイント取込はうまくと、見積明細商品名称は会計商品名またはタグ値で切替設定できるよに改善対応 by zh END
                // 2018/10/16 TL2way予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh BEGIN
                Dom.XmlNode chgRoomTypeField = configNode.getChildElement('CHGROOMTYPE', null);
                // 2018/10/16 TL2way予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh END
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
    			// 2017/05/23 ご予約項目値自動設定機能改善 BEGIN
    			defFieldConLst = new list<ConditionInfo>();
    			// 2017/05/23 ご予約項目値自動設定機能改善 END
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
     	                        // 2017/05/23 ご予約項目値自動設定機能改善 BEGIN
     	                        if(CommUtils.isBlank(fieldName) || CommUtils.isBlank(fieldValue)) continue;
	                            // 該当条件を設定すると、新規予約を登録後に、検索して、条件と満足すると、指定の項目の指定のデータを自動設定する
	                            Dom.XmlNode conNode = fieldNode.getChildElement('COONDITION',null);
	                            // 値自動設定の検索条件を設定あり場合
	                            String conValue = (conNode != null ? CommUtils.nullToBlank(conNode.getText()) : null);
								// 条件指定の場合
								if (!CommUtils.isBlank(conValue)) {
									ConditionInfo con = new ConditionInfo();
									con.condtion = conValue;
									con.defFieldApi = fieldName;
									con.defFieldVal = fieldValue;
									defFieldConLst.add(con);
								} else
	                            // 2017/05/23 ご予約項目値自動設定機能改善 END
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
    			realStockReqSync = false;	  
                if (realStockReqSyncFields != null) {
                	realStockReqSync = Boolean.valueOf(CommUtils.nullToBlank(realStockReqSyncFields.getText()));
                }
                // 2016/01/29 リアル（旅行会社）に対して、在庫更新要求を発行する・しない制御パラメータを追加 END
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
                // 2018/05/09 指定AGTにより、男女不明の処理機能対応 BEGIN
                Dom.XmlNode genderDivFlgField = configNode.getChildElement('GENDERDIVFLG', null);
                if (genderDivFlgField != null) {
                	String agtcodes = CommUtils.nullToBlank(genderDivFlgField.getText());
                	if (!CommUtils.isBlank(agtcodes)) filter.agtcodes.addAll(agtcodes.split(','));
                }
                // 2018/05/09 指定AGTにより、男女不明の処理機能対応 END
                // 2017/08/15 ネット取込(TL2way)機能、変更通知（２泊→１泊に変更）が来た際に、子部屋２日目の夕食レストランの席がキャンセルできるように改善対応 BEGIN
                Dom.XmlNode childLeadFields = configNode.getChildElement('GENERAL_CHILD_LEAD', null);
                subRuleDefInf = new SubRuleDefInfo();
                if (childLeadFields != null){
                	for(Dom.XmlNode ruleNode : childLeadFields.getChildElements()){
                	    String ruleName = ruleNode.getName();
                		// 子部屋関連チェック用ルール情報を格納する
                		if(ruleName == 'CHILD_LINK_RULE'){
                		    subRuleDefInf.setSubLinkRules(ruleNode);
                		}
                	}
                }
                // 2017/08/15 ネット取込(TL2way)機能、変更通知（２泊→１泊に変更）が来た際に、子部屋２日目の夕食レストランの席がキャンセルできるように改善対応 END
                // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh BEGIN
		        chgdtRoomClearFlag = false;
    			if (chgdtRoomClearField != null){
    				String chgStr = CommUtils.nullToBlank(chgdtRoomClearField.getText());
    				if(!CommUtils.isBlank(chgStr))
    					chgdtRoomClearFlag = Boolean.valueOf(chgStr);
    			}
		        // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh END
		     	// 2017/08/07 在庫連携、指定条件により、SFの部屋タイプからTLの部屋タイプグループ名を変更できるように改善 by zh BEGIN
		     	stockConvertMap = new map<String, List<TL_ServiceConfigHelp.StockConvertInfo>>();
		        Dom.XmlNode stockConvertFields = configNode.getChildElement('STOCK_CONVERT_ROOMTYPECODE', null);
		        if (stockConvertFields != null){
//system.debug(logginglevel.info,'stockConvertFields----------' + stockConvertFields);
		        	stockConvertMap = stockConvertInfoParse(stockConvertFields);
		        }
				// 2017/08/07 在庫連携、指定条件により、SFの部屋タイプからTLの部屋タイプグループ名を変更できるように改善 by zh END	
			// 2017/10/09 ポイント取込はうまくと、見積明細商品名称は会計商品名またはタグ値で切替設定できるよに改善対応 by zh BEGIN
			sfPointNmFlag = false;
    			if (sfPointNmField != null){
    				String sfPointNmStr = CommUtils.nullToBlank(sfPointNmField.getText());
    				if(!CommUtils.isBlank(sfPointNmStr))
    					sfPointNmFlag = Boolean.valueOf(sfPointNmStr);
    			}	
    			// 2017/10/09 ポイント取込はうまくと、見積明細商品名称は会計商品名またはタグ値で切替設定できるよに改善対応 by zh END        
    			// 2018/07/19 TL取り込みの総計人数が不正改善対応 by zh BEGIN
    			paxCountCalFlag = false;
				Dom.XmlNode paxCountCalField =  configNode.getChildElement('PER_ROOM_PAXCOUNT_CAL', null);
                if(paxCountCalField != null){ 
                    paxCountCalFlag = Boolean.valueOf(CommUtils.nullToBlank(paxCountCalField.getText()));
                }
    			// 2018/07/19 TL取り込みの総計人数が不正改善対応 by zh END
        		// 2018/09/27 到着時刻は24時間以上でも、指定の時刻として取り込みできるように改善 WSQ BEGIN
				ciRepTime = null;
				Dom.XmlNode ciRepTimeField = configNode.getChildElement('MAX24REPTIME', null);
                if(ciRepTimeField != null){ 
                    ciRepTime = CommUtils.stringToTimeOrNull(ciRepTimeField.getText());
                }
      			// 2018/09/27 到着時刻は24時間以上でも、指定の時刻として取り込みできるように改善 WSQ END  
      			// 2018/10/16 TL2way予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh BEGIN
                chgRoomTypeFlag = false;
    			if (chgRoomTypeField != null){
    				String chgTypeStr = CommUtils.nullToBlank(chgRoomTypeField.getText());
    				if(!CommUtils.isBlank(chgTypeStr)) chgRoomTypeFlag = Boolean.valueOf(chgTypeStr);
    			}
                // 2018/10/16 TL2way予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh END
                // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ BEGIN
                modifyEstItemsFlag = false;
    			if (modifyEstItemsField != null){
    				String s = CommUtils.nullToBlank(modifyEstItemsField.getText());
    				if(!CommUtils.isBlank(s)) modifyEstItemsFlag = Boolean.valueOf(s);
    			} 
                // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ END
                // 2018/12/15 TL2way会計人数制御改善(大人人数のみ予約人数に反映する) by zh BEGIN
	            childSet = null;
	            Dom.XmlNode childFields =  configNode.getChildElement('CHILD_COUNT_CAL', null);
	            if (childFields != null) {
	            	childSet = new Set<String>();
	                String childFieldsDef = CommUtils.nullToBlank(childFields.getText()).deleteWhitespace().toLowerCase();
	                if (!CommUtils.isBlank(childFieldsDef)) childSet.addAll(childFieldsDef.split(','));
	            }
	            System.debug(loggingLevel.INFO, 'childSet:::' + childSet);
                // 2018/12/15 TL2way会計人数制御改善(大人人数のみ予約人数に反映する) by zh END
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
        // 2017/05/23 ご予約項目値自動設定機能改善 BEGIN
        public list<ConditionInfo> defFieldConLst{get;set;}
        // 2017/05/23 ご予約項目値自動設定機能改善 END
        // 2016/01/29 リアル（旅行会社）に対して、在庫更新要求を発行する・しない制御パラメータを追加
        public boolean realStockReqSync{get;set;}
        // 2016/10/16 ネット取り込みエラーの場合、リトライ処理をする・しない制御処理追加
        public boolean retrySync{get;private set;}
        // 2017/01/09 親部屋集める:メール本文 fix BEGIN by zh
        public boolean mailDivFlag{get;set;}
        public Filter filter{get;set;}
        // 2018/09/27 到着時刻は24時間以上でも、指定の時刻として取り込みできるように改善 WSQ BEGIN
        public Time ciRepTime{get;set;}
      	// 2018/09/27 到着時刻は24時間以上でも、指定の時刻として取り込みできるように改善 WSQ END
        // 2017/08/15 ネット取込(TL2way)機能、変更通知（２泊→１泊に変更）が来た際に、子部屋２日目の夕食レストランの席がキャンセルできるように改善対応 BEGIN
        public SubRuleDefInfo subRuleDefInf{get;private set;}
        // 2017/08/15 ネット取込(TL2way)機能、変更通知（２泊→１泊に変更）が来た際に、子部屋２日目の夕食レストランの席がキャンセルできるように改善対応 END
        // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh BEGIN
        public boolean chgdtRoomClearFlag{get;set;}
        // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh END
        // 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応 by zh BEGIN
        public boolean payMeaidToLastDayFlag{get;set;}
        // 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応 by zh END
        // 2017/08/07 在庫連携、指定条件により、SFの部屋タイプからTLの部屋タイプグループ名を変更できるように改善 by zh BEGIN
        public map<String, List<TL_ServiceConfigHelp.StockConvertInfo>> stockConvertMap{get;set;}
        Map<String,List<TL_ServiceConfigHelp.StockConvertInfo>> stockConvertInfoParse(Dom.XmlNode stockConvertFields){
			//convertRuleLst = new list<TL_ServiceConfigHelp.StockConvertInfo>();
			TL_ServiceConfigHelp.StockConvertInfo stockConvert = new TL_ServiceConfigHelp.StockConvertInfo();
			Map<String,List<TL_ServiceConfigHelp.StockConvertInfo>> convertInfoMap = new Map<String,List<TL_ServiceConfigHelp.StockConvertInfo>>();
			for(Dom.XmlNode ruleNode : stockConvertFields.getChildElements()){
	    		if(ruleNode.getName() == 'CONVERT_RULE'){
	    		    //TL_ServiceConfigHelp.StockConvertInfo convertRule;
	    		    String contioneVal = null;
	    		    //Map<String,String> wkCdToTlCdMap = new Map<String, String>();
	    		    List<TL_ServiceConfigHelp.StockConvertInfo> convertDefLst = new List<TL_ServiceConfigHelp.StockConvertInfo>();
	    			for(Dom.XmlNode node : ruleNode.getChildElements()){
	    				// 条件情報
	    				if(node.getName() == 'CONDITION'){
	    					contioneVal = CommUtils.nullToBlank(node.getText());
	    				} else if(node.getName() == 'CONVERT'){
	    				    TL_ServiceConfigHelp.StockConvertInfo convertRule = new TL_ServiceConfigHelp.StockConvertInfo();
	    					convertRule.sfRmtypecd = CommUtils.nullToBlank(node.getAttribute('SF_RMTYPECD',null));
							convertRule.tlRmtypeName = CommUtils.nullToBlank(node.getAttribute('TL_RMTYPENAME',null));
							convertDefLst.add(convertRule);
	    				}
	    			}
	    			// 条件を未設定の場合、対象外
	    			if (CommUtils.isBlank(contioneVal)) continue;
	    			for (TL_ServiceConfigHelp.StockConvertInfo convertRule : convertDefLst) {
	    			    convertRule.condition = contioneVal;
	    			    // 関連情報を未設定の場合、対象外
	    			    if (convertRule.isNotValidata()) continue;
	    			    String key = convertRule.sfRmtypecd;
	    			    if (!convertInfoMap.containsKey(key)) convertInfoMap.put(key, new List<TL_ServiceConfigHelp.StockConvertInfo>());
	    			    convertInfoMap.get(key).add(convertRule);
	    			}
	    		}
	    	}
	    	return convertInfoMap;
		}
        // 2017/08/07 在庫連携、指定条件により、SFの部屋タイプからTLの部屋タイプグループ名を変更できるように改善 by zh END
        // 2017/10/09 ポイント取込はうまくと、見積明細商品名称は会計商品名またはタグ値で切替設定できるよに改善対応 by zh BEGIN
        public boolean sfPointNmFlag{get;set;}
        // 2017/10/09 ポイント取込はうまくと、見積明細商品名称は会計商品名またはタグ値で切替設定できるよに改善対応 by zh END
        // 2018/07/19 TL取り込みの総計人数が不正改善対応 by zh BEGIN
        public boolean paxCountCalFlag{get;set;}
        // 2018/07/19 TL取り込みの総計人数が不正改善対応 by zh END
        // 2018/10/16 TL2way予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh BEGIN
        public boolean chgRoomTypeFlag{get;set;}
        // 2018/10/16 TL2way予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh END
        // 2018/12/15 TL2way会計人数制御改善(大人人数のみ予約人数に反映する) by zh BEGIN
        public Set<String> childSet{get;set;}
        // 2018/12/15 TL2way会計人数制御改善(大人人数のみ予約人数に反映する) by zh END
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
	// 2017/05/23 ご予約項目値自動設定機能改善 BEGIN
	public class ConditionInfo {
		public String condtion{get;set;}
		public String defFieldApi{get;set;}
		public Object defFieldVal{get;set;}
	}
	// 2017/05/23 ご予約項目値自動設定機能改善 END
	// 2017/08/07 在庫連携、指定条件により、SFの部屋タイプからTLの部屋タイプグループ名を変更できるように改善 by zh BEGIN
	public class StockConvertInfo {
		public String condition{get;set;}	
		public String sfRmtypecd{get;set;}	
		public String tlRmtypeName{get;set;}
		public Boolean isNotValidata(){
			return (CommUtils.isBlank(condition) 
				|| CommUtils.isBlank(sfRmtypecd) 
				|| CommUtils.isBlank(tlRmtypeName));
		}	
	}
	// 2017/08/07 在庫連携、指定条件により、SFの部屋タイプからTLの部屋タイプグループ名を変更できるように改善 by zh END
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

	// 2016/05/05 バッチログ記録共通機能 BEGIN
	public static void writeLogToDb(String logMsg, string mangerId, boolean isInit) {

		// 2017/02/21 Field Security Check BEGIN
		List<String> chkFields = new List<String>{'ProcessingType__c','ManageID__c','ProcessLog__c','MailSendComplete__c','FunctionType__c'};
		Map<String,Schema.SObjectField> m = Schema.SObjectType.CooperationResult__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFields, m)) {
			return;
		}
		// 2017/02/21 Field Security Check End
		String SERVICE_KEY = 'TL';
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
	// TL2WAY連携処理、エラー処理情報の格納
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
				// 2020/09/15 OTAからの予約取り込み時に「楽天ポイント」と「楽天クーポン」が分かれて取り込みできる WGCH BEGIN
				// paymentInfoMap.put(pointCls.getkey(), pointCls);
				String key = pointCls.getkey();
				paymentInfoMap.put(key, pointCls);
				// 根据pointName生成key对应的明细
				for(String pointName : CommUtils.nullToBlank(pointCls.pointName).split(',')){
					// 合成pointNameKey
					if(!CommUtils.isBlank(pointName)){
						String key2 = key + '_' + pointName;
						paymentInfoMap.put(key2, pointCls);
					}
				}
				// 2020/09/15 OTAからの予約取り込み時に「楽天ポイント」と「楽天クーポン」が分かれて取り込みできる WGCH END
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
			// 2020/09/15 OTAからの予約取り込み時に「楽天ポイント」と「楽天クーポン」が分かれて取り込みできる WSQ BEGIN
			pointName = '';
			// 2020/09/15 OTAからの予約取り込み時に「楽天ポイント」と「楽天クーポン」が分かれて取り込みできる WSQ END
			paymentKbn = CommUtils.nullToBlank(nodePayment.getAttribute('PAYKBN',null));
			//payMediaCode = CommUtils.nullToBlank(nodePayment.getAttribute('MEDIACODE',null));
			Dom.XmlNode convertField = nodePayment.getChildElement('CONVERT', null);
			if (convertField != null) {
				agtCode = CommUtils.nullToBlank(convertField.getAttribute('AGTCODE',null));
				payProdCode = CommUtils.nullToBlank(convertField.getText());
				// 2020/09/15 OTAからの予約取り込み時に「楽天ポイント」と「楽天クーポン」が分かれて取り込みできる WSQ BEGIN
				pointName = CommUtils.nullToBlank(convertField.getAttribute('POINTNAME',null));
				// 2020/09/15 OTAからの予約取り込み時に「楽天ポイント」と「楽天クーポン」が分かれて取り込みできる WSQ END
			}
		}
		public String paymentKbn{get;set;}	// 事前支払区分
		public String payProdCode{get;set;}	// 登録する会計商品
		public String agtCode{get;set;}		// AGTコード
		// 2020/09/15 OTAからの予約取り込み時に「楽天ポイント」と「楽天クーポン」が分かれて取り込みできる WSQ BEGIN
		public String pointName{get;set;}	// ポイント名前
		// 2020/09/15 OTAからの予約取り込み時に「楽天ポイント」と「楽天クーポン」が分かれて取り込みできる WSQ END
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
			// 2020/09/15 OTAからの予約取り込み時に「楽天ポイント」と「楽天クーポン」が分かれて取り込みできる WGCH BEGIN
			// list<AccountMaster__c> payProductMstLst = [select id, Field3__c from AccountMaster__c where Field3__c in :productCds];
			list<AccountMaster__c> payProductMstLst = [select id, Field3__c, Name from AccountMaster__c where Field3__c in :productCds];
			// 2020/09/15 OTAからの予約取り込み時に「楽天ポイント」と「楽天クーポン」が分かれて取り込みできる WGCH END
			
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
	public static final String TL_LEAD_STATUS_MANAGERIDID = 'TL_LEAD_LOG_000000001';
	public static final String TL_STOCK_STATUS_MANAGERIDID = 'TL_STOCK_LOG_000000001';
	public static final String TL_STAUTS_STOP = 'STOP';
	// バッチ起動されるがどうチェックを行う[取り込み]
	public static boolean isLeadRuning(Id jobId) {
		set<string> targetClassNmSet = new set<String>{'TL_LeadSyncNotifyBatch','TL_LeadSyncXmlImportBatch','TL_LeadSyncProcessBatch','TL_LeadSyncNotifyBatchExtend'};
		return isDupStartCheck(targetClassNmSet, jobId, 'TL_LeadSyncNotifyBatch');
	}
	// バッチ起動されるがどうチェックを行う[在庫調整]
	public static boolean isStockRuning(Id jobId) {
		set<string> targetClassNmSet = new set<String>{'TL_StockAdjustmentBatch','TL_StockAdjustmentBatchExtend'};
		return isDupStartCheck(targetClassNmSet, jobId, 'TL_StockAdjustmentBatch');
	}
	// 予約取り込み処理は重複起動されるがどう
	public static boolean isLeadDupStartCheck (Id jobId) {
		list<CooperationResult__c> lockData = [select id from CooperationResult__c where ManageID__c = :TL_LEAD_STATUS_MANAGERIDID for update];
		return isLeadRuning(jobId);
	}
	public static boolean isStockDupStartCheck(Id jobId) {
		list<CooperationResult__c> lockData = [select id from CooperationResult__c where ManageID__c = :TL_STOCK_STATUS_MANAGERIDID for update];
		return isStockRuning(jobId);
	}
	private static boolean isDupStartCheck (set<string> targetClassNmSet, Id selfJobId, String cronName) {
		// 業務処理バッチの対象クラス名を格納する
		//if (targetClassNmSet == null) targetClassNmSet = new set<String>{'TL_LeadSyncNotifyBatch','TL_LeadSyncXmlImportBatch','TL_LeadSyncProcessBatch','TL_LeadSyncNotifyBatchExtend'};
		//if (cronName == null) cronName = 'TL_LeadSyncNotifyBatch';
		// 該当IDで実施中バッチ存在チェックを行う
		Integer jobs = [Select count() From AsyncApexJob Where ApexClass.Name = :targetClassNmSet and id != :selfJobId  and ( Status = 'Queued' or Status = 'Processing' or Status = 'Preparing' or Status = 'Holding')];  
		if (jobs > 0) return true;
		/*
		// スケジュールに既にスケジュールされるがどうチェックする
		String wkCronName = cronName + '%';
//System.debug(loggingLevel.info, 'wkCronName='+wkCronName);		
		Integer crons = [select count() from CronTrigger where State != 'DELETED' And CronJobDetail.Name like :wkCronName];
//System.debug(loggingLevel.info, 'crons='+crons);			
		if (crons > 0) return true;
		*/
		return false;
	}
	// For Lock Manager Data
	public static void insUpdLeadLockData() {
		writeLogToDb('', TL_LEAD_STATUS_MANAGERIDID, false);
	}
	public static void insUpdStockLockData() {
		writeLogToDb('', TL_STOCK_STATUS_MANAGERIDID, false);
	}
	// 2016/11/04 指定のバッチは既に実施されているがどうかチェックする END
	// 2016/12/14 STOPの濾過　Wgch BEGIN
	public static boolean isLeadBatchStopCheck () {
		list<CooperationResult__c> existRs = [select id from CooperationResult__c where ManageID__c = :TL_LEAD_STATUS_MANAGERIDID And JobProcessType__c = :TL_STAUTS_STOP for update];
		return (!existRs.isEmpty());
	}
	public static boolean isStockBatchStopCheck () {
		list<CooperationResult__c> existRs = [select id from CooperationResult__c where ManageID__c = :TL_STOCK_STATUS_MANAGERIDID And JobProcessType__c = :TL_STAUTS_STOP for update];
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
		updBatchCtrlFlg(TL_LEAD_STATUS_MANAGERIDID, TL_STAUTS_STOP);
		// 未来実施予定のスケジールも停止が必要、その場合、JOB停止処理が必要
		// 関連の未来のスケジールバッチをクリアする
		String scheduleNm = 'TL_LeadSyncNotifyBatch';
		relAbortJob(scheduleNm);
	}
	public static void stopStockBatch() {
		updBatchCtrlFlg(TL_STOCK_STATUS_MANAGERIDID, TL_STAUTS_STOP);
		// 未来実施予定のスケジールも停止が必要、その場合、JOB停止処理が必要
		// 関連の未来のスケジールバッチをクリアする
		String scheduleNm = 'TL_StockAdjustmentBatch';
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
		updBatchCtrlFlg(TL_LEAD_STATUS_MANAGERIDID, NULL);
		TL_LeadSyncNotifyBatch schedule = new TL_LeadSyncNotifyBatch();
		String jobName = 'TL_LeadSyncNotifyBatch' + DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, getScheduleRuleStr(), schedule);
		return jobId;
	}
	public static String startStockBatch() {
		updBatchCtrlFlg(TL_STOCK_STATUS_MANAGERIDID, NULL);
		TL_StockAdjustmentBatch schedule= new TL_StockAdjustmentBatch();
		String jobName = 'TL_StockAdjustmentBatch' + DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, getScheduleRuleStr(), schedule);
		return jobId;
	}
	// クリアバッチ停止フラグ
	public static void clearLeadBatchStopFlg() {
		updBatchCtrlFlg(TL_LEAD_STATUS_MANAGERIDID, NULL);
	}
	public static void clearStockBatchStopFlg() {
		updBatchCtrlFlg(TL_STOCK_STATUS_MANAGERIDID, NULL);
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
	// 2017/02/07 男女区分取得 by zy BEGIN
	public Class Filter{
		List<String> beginLst;
		List<String> begin2Lst;
		List<String> endLst;
		List<String> filters;
		// 2018/05/09 指定AGTにより、男女不明の処理機能対応 BEGIN
		set<string> agtcodes;
		public Boolean isSpecAgtCode(string agt) {
			return agtcodes.contains(agt);
		}
		// 2018/05/09 指定AGTにより、男女不明の処理機能対応 END
		Filter () {
			beginLst = new List<String>{'人員総数：'};
			begin2Lst = new List<String>{'内訳：'};
			endLst = new List<String>{'\n'};
			// 2018/05/09 指定AGTにより、男女不明の処理機能対応 BEGIN
			//filters = new List<String>{'(男)','(女)'};
			filters = new List<String>{'(男)','(女)','男性','女性'};
			agtcodes = new set<string>();
			// 2018/05/09 指定AGTにより、男女不明の処理機能対応 END
		}
		public void load(Dom.xmlNode xmlNode) {
			beginLst = new List<String>();
			begin2Lst = new List<String>();
			endLst = new List<String>();
			filters = new List<String>();
			String begins = CommUtils.nullToBlank(xmlNode.getAttribute('BEG',null));
//system.debug(logginglevel.info,'begins:::' + begins);
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
	// 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
	// ご予約変更の場合、ご予約項目の変更履歴ありの項目に対して、ネット取り込み変更の場合、項目変更なし	
	public static map<id,set<string>> getLeadHisotryInfo(List<Lead__c> updLeads) {
		map<id, set<string>> resultMap = new map<id, set<string>>();
		if (updLeads.isEmpty()) return resultMap;
		List<DateTime> autoModifyDtLst = new List<DateTime>();
		Lead__c firstLead = updLeads[0];

		// 特記事項の内容をParseして、XML経由で変更時刻情報を取得する
		// 該当変更時刻記録がなかったの場合、変更履歴の項目は全部手動で変更されると認識する
		String comment = CommUtils.nullToBlank(firstLead.Comment3__c);
		Integer changePos = comment.indexOf(Label.CONST_038_0003);
		Integer dtLen = 24;
		Integer indexKeyLen = Label.CONST_038_0003.length();
		while (changePos > dtLen) {
			String timeStr = comment.substring(changePos-dtLen,changePos-1);
//System.debug(loggingLevel.info, 'timeStr==={'+timeStr+'}');
			String yy = timeStr.substring(0,4);
			String mm = timeStr.substring(5,7);
			String dd = timeStr.substring(8,10);
			String hh = timeStr.substring(11,13);
			String ms = timeStr.substring(14,16);
			String ss = timeStr.substring(17,19);
			if (CommUtils.isNumber(yy) && CommUtils.isNumber(mm) && CommUtils.isNumber(dd) &&
				CommUtils.isNumber(hh) && CommUtils.isNumber(ms) && CommUtils.isNumber(ss)) {
				DateTime modifyDt = DateTime.newInstance(
								CommUtils.nullToIntZero(yy),CommUtils.nullToIntZero(mm),CommUtils.nullToIntZero(dd),
								CommUtils.nullToIntZero(hh),CommUtils.nullToIntZero(ms),CommUtils.nullToIntZero(ss));		
				autoModifyDtLst.add(modifyDt);
				//break;
			}
			changePos = comment.indexOfIgnoreCase(Label.CONST_038_0003, changePos+indexKeyLen);
		}
		// 関連の予約IDリストを格納する
		list<Id> leadIds = new List<Id>();
		for (Lead__c lead : updLeads) { leadIds.add(lead.id); }
		// 既存変更履歴情報を取得する
		String ns = CommConst.APPOTION_NAMESPACE;
		LeadHistories hisUtil = new LeadHistories(leadIds);
		hisUtil.init();
		// 該当予約の変更履歴情報を格納する
		Map<Id, LeadHistories.LeadHistoryItem> hisResultMap = hisUtil.resultMap;
		for (LeadHistories.LeadHistoryItem item : hisResultMap.values()) {
			if (!resultMap.containskey(item.leadId)) resultMap.put(item.leadId, new set<string>());
			set<string> changeApiSet = resultMap.get(item.LeadId);
			for (LeadHistories.ObjectHistoryLine line : item.histories) {
//System.debug(loggingLevel.info, 'line==={'+line+'}');
				// 該当予約はXML経由で変更情報があり場合
//System.debug(loggingLevel.info, 'line.s.CreatedDate==={'+line.s.CreatedDate+'}');
				Boolean isBreakFlg = false;
				for (DateTime dt : autoModifyDtLst) {
					if (dt <= line.s.CreatedDate && line.s.CreatedDate <= dt.addMinutes(1)) {
						isBreakFlg = true;
						break;
					}
				}
				if (isBreakFlg) continue;
				//if (lastModifyDt != null && line.s.CreatedDate <= lastModifyDt) continue;
//System.debug(loggingLevel.info, 'line.s.Field==={'+line.s.Field+'}');
				String locApiNm = line.s.Field;
				if (!CommUtils.isBlank(ns) && locApiNm.startsWith(ns)) locApiNm = locApiNm.removeStartIgnoreCase(ns);
				changeApiSet.add(locApiNm.toLowerCase());
			}
		}
		return resultMap;
	}
	// 該当項目は更新する・しない制御：TRUE：更新できる
	public static boolean isSetupVal(Set<String> filterSet, String fieldApi) {
//System.debug(loggingLevel.info, ('APINAME['+fieldApi+']=' + !(filterSet.contains(fieldApi))));
		return !(filterSet.contains(fieldApi.toLowerCase()));
	}
	
	// 2017/05/09 ネット取り込み、予約変更機能改善 END
	// 2017/08/15 ネット取込(TL2way)機能、変更通知（２泊→１泊に変更）が来た際に、子部屋２日目の夕食レストランの席がキャンセルできるように改善対応 BEGIN
	public class SubRuleDefInfo {
	    public SubRuleDefInfo () {
	        subLinkRules = new List<String>();
	    }
	    // 
	    // 該当子部屋情報存在チェック判断用定義情報
	    public List<String> subLinkRules{get; private set;}
	    public void setSubLinkRules(Dom.XmlNode ruleNode) {
	        if (ruleNode != null){
                String ruleStr = CommUtils.nullToBlank(ruleNode.getText());
                if (!CommUtils.isBlank(ruleStr)) subLinkRules.add(ruleStr);
	        }
	    }
	}
	// 2017/08/15 ネット取込(TL2way)機能、変更通知（２泊→１泊に変更）が来た際に、子部屋２日目の夕食レストランの席がキャンセルできるように改善対応 END
	// 2017/08/24 同じエラーは重複送信しないように回避対応 BEGIN
    //public static final String TL_LEAD_DUPSEND_ID = 'TL_LEAD_LOG_000000002';
    public static final String TL_STOCK_DUPSEND_ID = 'TL_STOCK_LOG_000000002';

    //public static boolean isLeadDupErrorMsgCheck (String msg, Boolean isUpdFlg) {
    //    return processDupErrorMsg(TL_LEAD_DUPSEND_ID, msg, isUpdFlg); 
    //}
    public static boolean isStockDupErrorMsgCheck (String msg, Boolean isUpdFlg) {
       return processDupErrorMsg(TL_STOCK_DUPSEND_ID, msg, isUpdFlg);
    }
    private static Boolean processDupErrorMsg(String managerId, String msg, Boolean isUpdFlg) {
        DateTime nowDt = System.now();
        list<CooperationResult__c> existRs = [select id,ManageID__c,ErrorContent__c,LastModifiedDate from CooperationResult__c 
            where ManageID__c = :managerId And ProcessingType__c = :TL_ServiceCtrl.SERVICE_KEY];
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
                ProcessingType__c = TL_ServiceCtrl.SERVICE_KEY
            );
        }
        if (isUpdFlg) upsert chkRs CooperationResult__c.ManageID__c;
        return false;
    }
    // 2017/08/24 同じエラーは重複送信しないように回避対応  END
}