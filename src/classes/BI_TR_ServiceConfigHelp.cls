/***************************
* TR処理機能共通ヘルプクラス
* 2016/01/29 リアル（旅行会社）に対して、在庫更新要求を発行する・しない制御パラメータを追加
* 2016/03/22 お客様情報解析用情報の格納
* 2016/05/12 事前決済区分と登録の支払商品情報マッピング
* 2016/06/10 子供料金プラン取り込み機能対応
* 2017/02/21 お子様プランの料金PRICE機能追加 
* 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応
* 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応
* 2017/07/20 改善要望：ねっぱんクーポンと、ポイントを別で取込
* 2018/12/30 TR予約変更通知の際に、部屋タイプを自動変更できるように改善対応
* 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応
* 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する
* 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善
* 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善
* 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加
****************************/
public with sharing class BI_TR_ServiceConfigHelp {
	//public enum ProcessingType{TL,TA,TR,JR}
	
	private static final BI_TR_ServiceConfigHelp instance = new BI_TR_ServiceConfigHelp();
	// TR連動機能設定ファイル名
	private static final String XmlConfigName = 'TRServiceConfigXml';
	private String defaultShopCode = null;
	private BI_TR_ServiceConfigHelp() {
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
		// 2017/07/20  改善要望：ねっぱんクーポンと、ポイントを別で取込  by zh BEGIN
		//mapPointConfig = new map<String ,map<String, PAYMENT_CONVERT>>();
		mapPointConfig = new map<String ,map<String, List<PAYMENT_CONVERT>>>();
		// 2017/07/20  改善要望：ねっぱんクーポンと、ポイントを別で取込  by zh END
		// 2018/12/30 TRポイント取り込み改善対応 WSQ BEGIN
		xmlProdNameToEstItem = false;
		// 2018/12/30 TRポイント取り込み改善対応 WSQ END
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
    // 2017/07/20  改善要望：ねっぱんクーポンと、ポイントを別で取込  by zh BEGIN
    //private map<String, map<string,PAYMENT_CONVERT>> mapPointConfig;
    private map<String, map<string,List<PAYMENT_CONVERT>>> mapPointConfig;
    // 2017/07/20  改善要望：ねっぱんクーポンと、ポイントを別で取込  by zh END
	// 2018/12/30 TRポイント取り込み改善対応 WSQ BEGIN
	public boolean xmlProdNameToEstItem{get; private set;}
	// 2018/12/30 TRポイント取り込み改善対応 WSQ END
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
		return instance.mapAppConfig.containsKey(shopCd);
	}
	// XMLに定義情報存在チェツク、SHOPタグ定義情報がない場合、TL連携機能を起動しません
	public static Boolean tlSyncIsOpen() {
		return (instance.mapAppConfig.size() > 0);
	}
	// ****************************************
	// TR連携処理、共通定義パラメータ情報を取得する
	// ****************************************
	public static COMMCONFIG getCommConfig () {
		return instance.commConfig;
	}
	// ****************************************
	// TR連携処理、各店舗個別定義必要情報取得する
	// shopCd : 店舗コード
	// return : 該当店舗の定義情報を戻る
	// exception: 該当店舗コードはXMLに未定義されている場合、エラー戻る
	// ****************************************
	public static APPCONFIG getAppConfig(String pShopCd) {
    	// 指定の店舗コードの定義値は未定義の場合、デフォルト店舗設定値を取得する
    	String shopCd = !instance.mapAppConfig.containsKey(pShopCd) ? instance.defaultShopCode : pShopCd;
        if (instance.mapAppConfig.containsKey(shopCd)) {
            return instance.mapAppConfig.get(shopCd);
        } else {
            throw new CommException('指定の店舗コードの定義情報を見つかりません。['+pShopCd+']');
        }
    }
	// ****************************************
	// TR連携処理、エラー処理情報の格納
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
	// TR連携処理、エラー処理情報の格納
	// shopCd : 店舗コード
	// return : 該当店舗の定義情報を戻る
	// exception: 該当店舗コードはXMLに未定義されている場合、エラー戻る
	public static ACCOUNTCONFIG getAccountConfig(String shopCd) {
		if (instance.mapAccConfig.containsKey(shopCd)) {
			return instance.mapAccConfig.get(shopCd);
        } else {
        	//指定の店舗コードの定義情報を見つかりません。
            throw new CommException(Label.MSG_038_0023 + '['+shopCd+']');
        }
    }

	// ****************************************
	// TR連携処理、AGTのパッケージコードにより、SFのプランNO情報を取得する
	// shopCd:			店舗コード
	// agtCode : 		AGTコード
	// packageCode:		AGT側に定義しているパッケージコード
	// return : 		該当AGTパッケージコードからSF側のプランコード値を戻る
	//						該当戻る値はNULLの場合、AGTのパッケージコードはSF側のプランコードとリンクしません
	// exception: 		該当店舗コードはXMLに未定義されている場合、エラー戻る
	public static String getSfPlanNoByAgtPlanInfo(String shopCd, String agtCode, String packageCode) {
		if (instance.mapPlanConvertAgt2SfMap.containsKey(shopCd)) {
			// AGT 存在チェック
			map<String, map<String,String>> agtConvertMap = instance.mapPlanConvertAgt2SfMap.get(shopCd);
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
			String agtName = CommUtils.nullToBlank(agtNode.getAttribute('AGTCODE',null));
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
	
	// 共通定義情報の格納
	public class COMMCONFIG { 
		public COMMCONFIG(Dom.XmlNode node){
			// TRと店舗マッピング定義情報
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
            
            //DEBUG MODE NODE
			Dom.XmlNode isDebugField = node.getChildElement('ISDEBUG', null);
			bIsDebug = (isDebugField == null) ? false : Boolean.valueOf(CommUtils.nullToBlank(isDebugField.getText()));
            
            // XXミリ秒以内すると、予約インデックスと同時に作成される予約情報（2015/12/14)
			mLeadTimeLimit = 60000;	// １分以内
			Dom.XmlNode mLeadTimeLimitField = node.getChildElement('TARGET_LEAD_TIMELIMIT', null);
			if (mLeadTimeLimitField != null) mLeadTimeLimit = CommUtils.nullToIntZero(mLeadTimeLimitField.getText());
		}
		public Boolean bIsDebug{get;private set;}		// DEBUGモード制御フラグ
		public Integer mLeadTimeLimit{get;set;}			// 予約データの予約番号&&発生源なしの場合、TL電文から作成の予約識別用TIMESTAM
		public Map<String,String> shopNameMatchMap{get;private set;}
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
		Dom.XmlNode personRateCalFields = configNode.getChildElement('PERSONRATECAL', null);
                // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh BEGIN
                Dom.XmlNode chgdtRoomClearField = configNode.getChildElement('CHGDT_ROOMCLR', null);
                // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh END
                //Dom.XmlNode realStockReqSyncFields = configNode.getChildElement('RELA_STOCK_REQ_SYNC', null);
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
                /*chanelFromCompany = true;
                Dom.XmlNode chanelFromCompanyField = configNode.getChildElement('COMPANYTOCHANEL', null);
                if (chanelFromCompanyField != null) chanelFromCompany = Boolean.valueOf(CommUtils.nullToBlank(chanelFromCompanyField.getText()));
                */
                // 2016/08/04 予約チャネルの設定元の制御フラグ END
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
                // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh BEGIN
		        chgdtRoomClearFlag = false;
    			if (chgdtRoomClearField != null){
    				String chgStr = CommUtils.nullToBlank(chgdtRoomClearField.getText());
    				if(!CommUtils.isBlank(chgStr))
    					chgdtRoomClearFlag = Boolean.valueOf(chgStr);
    			}
		        // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh END
      			// 2018/12/30 TR予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh BEGIN
      			chgRoomTypeFlag = false;
    			if (chgRoomTypeField != null){
    				String chgTypeStr = CommUtils.nullToBlank(chgRoomTypeField.getText());
    				if(!CommUtils.isBlank(chgTypeStr)) chgRoomTypeFlag = Boolean.valueOf(chgTypeStr);
    			}
      			// 2018/12/30 TR予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh END
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
    		}
		}
		//public String systemId{get;set;}
		//public String userId{get;set;}
		//public String password{get;set;}	
		public boolean ucactisSync{get;set;}
        public String roomSortKey{get;set;}
        public boolean roomAutoAssignFlag{get;set;}
        public Map<String,Object> fieldMap{get;set;}
        // 2016/08/04 予約チャネルの設定元の制御フラグ；TRUE:旅行会社名で設定(デフォルト値)、FALSE:旅行営業所で設定
        //public boolean chanelFromCompany{get;private set;}
        public boolean presonRateAutoCal{get;set;}
        private String taxServiceKbn{get;private set;}
        public Boolean isSFTaxServiceKbn{get{return taxServiceKbn != '2';}} // 税サ区分はSalesforceの単価区分は依存する
        // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh BEGIN
        public boolean chgdtRoomClearFlag{get;set;}
        // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh END
        // 2018/12/30 TR予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh BEGIN
        public boolean chgRoomTypeFlag{get;set;}
        // 2018/12/30 TR予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh END
        // 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応 by zh BEGIN
        public boolean payMeaidToLastDayFlag{get;set;}
        // 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応 by zh END
        // 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ BEGIN
        public boolean contactAlwaysNew{get;set;}
        // 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ END
        // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ BEGIN
        public boolean modifyEstItemsFlag{get;set;}
        // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ END
	// 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 WSQ BEGIN
        public boolean romanToKanaFlag{get;set;}
        // 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 WSQ END
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
    
	// 2016/05/05 バッチログ記録共通機能 END
	// 2016/05/12 事前決済区分と登録の支払商品情報マッピング　BEGIN
	// ****************************************
	// TR連携処理、エラー処理情報の格納
	// shopCd : 店舗コード
	// return : 該当店舗の定義情報を戻る
	// exception: 該当店舗コードはXMLに未定義されている場合、エラー戻る
	// 2017/07/20  改善要望：ねっぱんクーポンと、ポイントを別で取込  by zh BEGIN
	//public static map<String, PAYMENT_CONVERT> getPointConfig(String shopCd) {
	public static map<String, List<PAYMENT_CONVERT>> getPointConfig(String shopCd) {
	// 2017/07/20  改善要望：ねっぱんクーポンと、ポイントを別で取込  by zh END
		if (instance.mapPointConfig.containsKey(shopCd)) {
			return instance.mapPointConfig.get(shopCd);
        } else {
		//指定の店舗コードの定義情報を見つかりません。
            throw new CommException(Label.MSG_038_0023 + '['+shopCd+']');
        }
    }
	public static map<String, PAYMENT_CONVERT> getPaymentConfig(String shopCd) {
		if (instance.mapPaymentConfig.containsKey(shopCd)) {
			return instance.mapPaymentConfig.get(shopCd);
        } else {
			//指定の店舗コードの定義情報を見つかりません。
            throw new CommException(Label.MSG_038_0023 + '['+shopCd+']');
        }
    }
    // 2017/07/20  改善要望：ねっぱんクーポンと、ポイントを別で取込  by zh BEGIN
    //private map<String, PAYMENT_CONVERT> parsePointInfo(Dom.XmlNode shopNode) {
    	//map<string, PAYMENT_CONVERT> paymentInfoMap = new map<string, PAYMENT_CONVERT>();
    private map<String, List<PAYMENT_CONVERT>> parsePointInfo(Dom.XmlNode shopNode) {
        map<string, List<PAYMENT_CONVERT>> paymentInfoMap = new map<string, List<PAYMENT_CONVERT>>();
    // 2017/07/20  改善要望：ねっぱんクーポンと、ポイントを別で取込  by zh 
		Dom.XmlNode paymentNode = shopNode.getChildElement('PAYMENT_CONVERTS', null);    		   		
		if (paymentNode != null) {
			// 2018/12/30 TRポイント取り込み改善対応 WSQ BEGIN
			String strXmlProdNameToEstItem = CommUtils.nullToBlank(paymentNode.getAttribute('POINT_XMLNAME',null));
			if (!CommUtils.isBlank(strXmlProdNameToEstItem)) xmlProdNameToEstItem = Boolean.valueOf(strXmlProdNameToEstItem);
			// 2018/12/30 TRポイント取り込み改善対応 WSQ END
			for (Dom.XmlNode nodeTag : paymentNode.getChildElements()) {
				if (nodeTag.getName() != 'POINT_CONVERT') continue;
				PAYMENT_CONVERT pointCls = new PAYMENT_CONVERT(nodeTag);
				// 2017/07/20  改善要望：ねっぱんクーポンと、ポイントを別で取込  by zh BEGIN
				//paymentInfoMap.put(pointCls.getkey(), pointCls);
				String key = pointCls.getkey();
				if (!paymentInfoMap.containsKey(key)) paymentInfoMap.put(key, new List<PAYMENT_CONVERT>());
				paymentInfoMap.get(key).add(pointCls);
				// 2017/07/20  改善要望：ねっぱんクーポンと、ポイントを別で取込  by zh END
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
			// 2017/07/20  改善要望：ねっぱんクーポンと、ポイントを別で取込  by zh BEGIN
			filterKeyLst = new List<String>();
			// 2017/07/20  改善要望：ねっぱんクーポンと、ポイントを別で取込  by zh END
			paymentKbn = CommUtils.nullToBlank(nodePayment.getAttribute('PAYKBN',null));
			//payMediaCode = CommUtils.nullToBlank(nodePayment.getAttribute('MEDIACODE',null));
			Dom.XmlNode convertField = nodePayment.getChildElement('CONVERT', null);
			if (convertField != null) {
				agtCode = CommUtils.nullToBlank(convertField.getAttribute('AGTCODE',null));
				// 2017/07/20  改善要望：ねっぱんクーポンと、ポイントを別で取込  by zh BEGIN
				String keywords = CommUtils.nullToBlank(convertField.getAttribute('KEYWORD',null));
				if (!CommUtils.isBlank(keyWords)) filterKeyLst.addAll(keyWords.split(','));
				// 2017/07/20  改善要望：ねっぱんクーポンと、ポイントを別で取込  by zh END
				payProdCode = CommUtils.nullToBlank(convertField.getText());
			}
		}
		public String paymentKbn{get;set;}	// 事前支払区分
		public String payProdCode{get;set;}	// 登録する会計商品
		public String agtCode{get;set;}		// AGTコード
		// 2017/07/20  改善要望：ねっぱんクーポンと、ポイントを別で取込  by zh BEGIN
		public list<String> filterKeyLst{get;set;}	    //pointName keyword
		// 2017/07/20  改善要望：ねっぱんクーポンと、ポイントを別で取込  by zh END
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
		if (instance.preCardPaymentWordConfig.containsKey(shopCd)) {
			return instance.preCardPaymentWordConfig.get(shopCd);
        } else {
            throw new CommException('指定の店舗コードの定義情報を見つかりません。['+shopCd+']');
        }
    }
	public static set<string> getCreditPaymentConvertConfig(String shopCd) {
		if (instance.preCreditPaymentWordConfig.containsKey(shopCd)) {
			return instance.preCreditPaymentWordConfig.get(shopCd);
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
		if (instance.mapChildPlanConvertConfig.containsKey(shopCd)) {
			return instance.mapChildPlanConvertConfig.get(shopCd);
        } else {
            throw new CommException('指定の店舗コードの定義情報を見つかりません。['+shopCd+']');
        }
    }
    // 2017/02/21 お子様プランの料金PRICE機能追加 by zh BEGIN
    public static map<String,String> getChildPlanPriceConvertConfig(String shopCd) {
		if (instance.mapChildPlanPriceConvertConfig.containsKey(shopCd)) {
			return instance.mapChildPlanPriceConvertConfig.get(shopCd);
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
		if (instance.mapAgtToChanelConfig.containsKey(shopCd)) {
			return instance.mapAgtToChanelConfig.get(shopCd);
        } else {
            throw new CommException('指定の店舗コードの定義情報を見つかりません。['+shopCd+']');
        }
    }
	// 2016/07/10 予約チャネル名の変換機能追加対応 END
	public static String getkey(string companyCode, string bookingNumber){
		return CommUtils.nullToBlank(companyCode) + '_' + CommUtils.nullToBlank(bookingNumber);
	}
	// 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
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
	
	// 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
	// 2018/12/30 TRポイント取り込み改善対応 WSQ BEGIN
	public static BI_TR_ServiceConfigHelp getInstance() {
		return instance;
	}
	// 2018/12/30 TRポイント取り込み改善対応 WSQ END
}