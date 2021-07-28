/***************************
* 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応
****************************/
public with sharing class EmailMessageToLeadHelp {
   
    private static final EmailMessageToLeadHelp instance = new EmailMessageToLeadHelp();
    private static final String XmlConfigName = 'EmailImportServiceConfig';
    private String defaultShopCode = null;
    /* 2017/06/21 不要な処理ロジックため、削除する
    // AGT定義情報変更、追加対応
    public void writeAgtInfoToXml(List<AgtInfo> agtInfo) {
        // 存在チェックを行う、重複存在するがどうかチェックを行う
        String addMsg = '';
        Document doc = [
            select name,body from Document where DeveloperName=:XmlConfigName  order by createddate desc limit 1];
        String xmlDoc = doc.body.toString();
        for(AgtInfo info : agtInfo ){
            addMsg += '\t\t\t<AGT NMKEY='+'\"'+  info.agtNm +'\"'+' template='+ '\"'+info.emailTemplate+'\"' +'>'+ info.agtCd +'</AGT>';                
        }
        xmlDoc = xmlDoc.replace('</AGTS>', (addMsg + '\n</AGTS>'));                     
        doc.body = blob.valueOf(xmlDoc);
        update doc;         
    }*/
    
    //public enum ProcessingType{TL,TA,TR,JR}
    // INIT初期化
    private EmailMessageToLeadHelp() {
        // XML LOADINGから定義情報を格納する
        mapAppConfig = new map<String, APPCONFIG>();
        // 自動設定の会計商品（入湯税トサービス料会計商品コード）
        mapAccConfig = new map<String, ACCOUNTCONFIG>();
        // PLANコード変換表 map<店舗コード, map<AGT名,map<agtのPacakgeコード，sfのプランNo）
        mapPlanConvertAgt2SfMap = new map<String, map<String, map<string, string>>>(); 
        // 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応 by zh BEGIN
        mapPlanConvertAgt2SfNameFlgMap = new map<String, Boolean>();
        // 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応 by zh END
        // お客様情報解析用情報の格納
        //mapContactConfig = new map<String, list<CONTACT_INFO_PARSE>>();
        // 事前決済区分と登録の支払商品情報マッピング
        mapPaymentConfig = new map<String ,map<String, PAYMENT_CONVERT>>();
        // ポイント割引の支払商品情報マッピング
        mapPointConfig = new map<String ,map<String, PAYMENT_CONVERT>>();
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
                if (defaultShopCode == null) defaultShopCode = strShopCode;
                mapAppConfig.put(strShopCode, new APPCONFIG(node));
                mapAccConfig.put(strShopCode, new ACCOUNTCONFIG(node));
                mapPlanConvertAgt2SfMap.put(strShopCode, parsePlanConvertParse(strShopCode, node));
                //mapContactConfig.put(strShopCode, parseContactInfo(node));
                mapPaymentConfig.put(strShopCode, parsePaymentInfo(node));
                mapPointConfig.put(strShopCode, parsePointInfo(node));
            }
            
        }
    }
    
    private map<String, APPCONFIG> mapAppConfig;
    private map<String, ACCOUNTCONFIG> mapAccConfig;
    //private map<String, List<CONTACT_INFO_PARSE>> mapContactConfig;
    // 2016/05/12 事前決済区分と登録の支払商品情報マッピング
    private map<String, map<string,PAYMENT_CONVERT>> mapPaymentConfig;
    private map<String, map<string,PAYMENT_CONVERT>> mapPointConfig;
    private COMMCONFIG commConfig;
    // AGT単位のプランコードはSF側のプランNOと変換情報の格納
    private map<String, map<String,map<String, String>>> mapPlanConvertAgt2SfMap;
    // 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応 by zh BEGIN
    private map<String, Boolean> mapPlanConvertAgt2SfNameFlgMap;
    // 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応 by zh END
 
    // 該当店舗コードはTLサイトコントローラと契約済がどうかチェックを行う
    // XMLの中に、該当店舗コードを定義されていると、契約済として、判断する
    public static Boolean isContractShop(String shopCd) {
        return instance.mapAppConfig.containsKey(shopCd);
    }
    // XMLに定義情報存在チェツク、SHOPタグ定義情報がない場合、TL連携機能を起動しません
    public static Boolean tlSyncIsOpen() {
        return (instance.mapAppConfig.size() > 0);
    }
    // ****************************************
    // TL2WAY連携処理、共通定義パラメータ情報を取得する
    // ****************************************
    public static COMMCONFIG getCommConfig () {
        return instance.commConfig;
    }
    // ****************************************
    // TL2WAY連携処理、各店舗個別定義必要情報取得する
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
    public static ACCOUNTCONFIG getAccountConfig(String pShopCd) {
    	// 指定の店舗コードの定義値は未定義の場合、デフォルト店舗設定値を取得する
    	String shopCd = !instance.mapAccConfig.containsKey(pShopCd) ? instance.defaultShopCode : pShopCd;
        if (instance.mapAccConfig.containsKey(shopCd)) {
            return instance.mapAccConfig.get(shopCd);
        } else {
            throw new CommException('指定の店舗コードの定義情報を見つかりません。['+pShopCd+']');
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
    // shopCd:          店舗コード
    // agtCode :        AGTコード
    // packageCode:     AGT側に定義しているパッケージコード
    // return :         該当AGTパッケージコードからSF側のプランコード値を戻る
    //                      該当戻る値はNULLの場合、AGTのパッケージコードはSF側のプランコードとリンクしません
    // exception:       該当店舗コードはXMLに未定義されている場合、エラー戻る
    public static String getSfPlanNoByAgtPlanInfo(String pShopCd, String agtCode, String packageCode) {
		// 指定の店舗コードの定義値は未定義の場合、デフォルト店舗設定値を取得する
    	String shopCd = !instance.mapPlanConvertAgt2SfMap.containsKey(pShopCd) ? instance.defaultShopCode : pShopCd;
        if (instance.mapPlanConvertAgt2SfMap.containsKey(shopCd)) {
            // AGT 存在チェック
            map<String, map<String,String>> agtConvertMap = instance.mapPlanConvertAgt2SfMap.get(shopCd);
            // AGTCODE->マッピング定義情報
            if (agtConvertMap.containsKey(agtCode)) {
                map<string, String> planConvertmap = agtConvertMap.get(agtCode);
                // 該当パッケージコードからプランNOを戻る
                return planConvertmap.get(packageCode);
            }
        }
        return null;
    }
    //private map<String, Account> agtInfoMaps;
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
            Dom.XmlNode leadImpIntervalField = node.getChildElement('LEADINTERVAL', null);
            Dom.XmlNode leadDeleteValField = node.getChildElement('LEADDELETEVAL', null);
            
            mLeadImportInterval = (leadImpIntervalField == null) ? 0 :CommUtils.nullToIntZero(leadImpIntervalField.getText());
            mLeadDeleteVal = (leadDeleteValField == null) ? 0 : CommUtils.nullToIntZero(leadDeleteValField.getText());
            // 最小３０秒単位
            if (mLeadImportInterval <= 30) mLeadImportInterval = 30;
            if (mLeadDeleteVal == null) mLeadDeleteVal = -14;
                
            //DEBUG MODE NODE
            Dom.XmlNode isDebugField = node.getChildElement('ISDEBUG', null);
            bIsDebug = (isDebugField == null) ? false : Boolean.valueOf(CommUtils.nullToBlank(isDebugField.getText()));
            // XXミリ秒以内すると、予約インデックスと同時に作成される予約情報（2015/12/14)
            mLeadTimeLimit = 60000; // １分以内
            Dom.XmlNode mLeadTimeLimitField = node.getChildElement('TARGET_LEAD_TIMELIMIT', null);
            if (mLeadTimeLimitField != null) mLeadTimeLimit = CommUtils.nullToIntZero(mLeadTimeLimitField.getText());
            
            restoreStartDate = null;
            Dom.XmlNode restoreStartDateFields = node.getChildElement('STOCK_RESTORE_START_DATE', null);
            if (restoreStartDateFields != null) restoreStartDate = CommUtils.stringToDate(restoreStartDateFields.getText());
        
            // 連携のAGT対象定義情報
            Dom.XmlNode agtNodeRoot =  node.getChildElement('AGTS', null);
            agtLst = new list<AgtInfo>();
            if (agtNodeRoot != null) {
                for (Dom.XMLNode agtNode : agtNodeRoot.getChildElements()) {
                    AgtInfo agtInf = new AgtInfo(agtNode);
                    if (!CommUtils.isBlank(agtInf.agtNm) && !CommUtils.isBlank(agtInf.agtCd) && !CommUtils.isBlank(agtInf.emailTemplate)) {
                        agtLst.add(agtInf);
                    }
                }
            }
            
            // メールと店舗マッピング定義情報
            mailMatchMap = new map<String, String>();
            Dom.XmlNode mailMatchNodeRoot =  node.getChildElement('MAIL_ADDRESS_MATCH', null);
            if (mailMatchNodeRoot != null) {
                for (Dom.XMLNode mailNode : mailMatchNodeRoot.getChildElements()) {
                    String mailAddress = CommUtils.nullToBlank(mailNode.getAttribute('MAILADDRESS',null));
                    String shopCode = CommUtils.nullToBlank(mailNode.getText());
                    if (!CommUtils.isBlank(mailAddress)) {
                        mailMatchMap.put(mailAddress,shopCode);
                    }
                }
            }
            
            // HTMLメールタンプレート
            htmlCommonTemplate = 'EmailTemplateForHtml';
            Dom.XmlNode htmlCommon =  node.getChildElement('HTML_COMMON', null);
            if (htmlCommon != null) {
                htmlCommonTemplate = htmlCommon.getText();
            }
            
        }
        public Boolean bIsDebug{get;private set;}       // DEBUGモード制御フラグ
        public Integer mLeadImportInterval{get;set;}    // 予約取込機能のスケジュールのINTERVAL秒数（秒単位）
        public Integer mLeadDeleteVal{get;set;}     // 予約取込履歴情報の削除日付数（日単位）
        public Integer mLeadTimeLimit{get;set;}         // 予約データの予約番号&&発生源なしの場合、TL電文から作成の予約識別用TIMESTAMP判別用ミリ秒
        public Date restoreStartDate{get;set;}          // バッチ再起動の場合、連携開始日付を指定する
        public List<AgtInfo> agtLst{get;private set;}   // 取込対象のAGT対象一覧
        public Map<String,String> mailMatchMap{get;private set;}
        public String htmlCommonTemplate{get;set;}
    }
    public class AgtInfo {
        public AgtInfo(Dom.XMLNode agtNode){
            if(agtNode != null) {
                agtNm = CommUtils.nullToBlank(agtNode.getAttribute('NMKEY',null));
                agtCd = CommUtils.nullToBlank(agtNode.getText());
                emailTemplate = CommUtils.nullToBlank(agtNode.getAttribute('template',null));
                extendTemplate = CommUtils.nullToBlank(agtNode.getAttribute('extendTemplate',null));
            }
        }
        public string agtNm{get;set;}
        public string agtCd{get;set;}
        public string emailTemplate{get;set;}
        public string extendTemplate{get;set;}// HTMLの解析テンプレート
    }
    
    public class APPCONFIG{
        public APPCONFIG(Dom.XmlNode shopNode){
            Dom.XmlNode configNode = shopNode.getChildElement('APPCONFIG', null);                       
            if (configNode != null) {
                Dom.XmlNode ucactisSyncField = configNode.getChildElement('UCACTISSYNC', null);
                Dom.XmlNode roomSortField = configNode.getChildElement('ROOMSORT', null);
                Dom.XmlNode roomAtuoAssignField = configNode.getChildElement('ROOMAUTOASSIGN', null);
                Dom.XmlNode leadAutoSetupFields = configNode.getChildElement('DEFAULTVALUES', null);
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
            }
        }
        public boolean ucactisSync{get;set;}
        public String roomSortKey{get;set;}
        public boolean roomAutoAssignFlag{get;set;}
        public Map<String,Object> fieldMap{get;set;}
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
    // 2016/03/22 お客様情報解析用情報の格納 END
    /*
    // 2016/05/05 バッチログ記録共通機能 BEGIN
    public static void writeLogToDb(String logMsg, string mangerId, boolean isInit) {
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
    }*/
    // 2016/05/05 バッチログ記録共通機能 END
    // 2016/05/12 事前決済区分と登録の支払商品情報マッピング　BEGIN
    // ****************************************
    // TL2WAY連携処理、エラー処理情報の格納
    // shopCd : 店舗コード
    // return : 該当店舗の定義情報を戻る
    // exception: 該当店舗コードはXMLに未定義されている場合、エラー戻る
    public static map<String, PAYMENT_CONVERT> getPointConfig(String pShopCd) {
    	// 指定の店舗コードの定義値は未定義の場合、デフォルト店舗設定値を取得する
    	String shopCd = !instance.mapPointConfig.containsKey(pShopCd) ? instance.defaultShopCode : pShopCd;
        if (instance.mapPointConfig.containsKey(shopCd)) {
            return instance.mapPointConfig.get(shopCd);
        } else {
            throw new CommException('指定の店舗コードの定義情報を見つかりません。['+pShopCd+']');
        }
    }
    public static map<String, PAYMENT_CONVERT> getPaymentConfig(String pShopCd) {
    	// 指定の店舗コードの定義値は未定義の場合、デフォルト店舗設定値を取得する
    	String shopCd = !instance.mapPaymentConfig.containsKey(pShopCd) ? instance.defaultShopCode : pShopCd;
        if (instance.mapPaymentConfig.containsKey(shopCd)) {
            return instance.mapPaymentConfig.get(shopCd);
        } else {
            throw new CommException('指定の店舗コードの定義情報を見つかりません。['+pShopCd+']');
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
        public String paymentKbn{get;set;}  // 事前支払区分
        public String payProdCode{get;set;} // 登録する会計商品
        public String agtCode{get;set;}     // AGTコード
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

}