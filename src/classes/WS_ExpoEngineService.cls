/**
* EXPO連携機能対応
* 2017/12/01 INIT
* 2018/03/20 5.10.注文見積情報取得改修、4.1.在庫取得、5.9.決済情報取得、6.1.推奨商品取得、7.1.Notification新規追加
* 2018/04/24 5.5.定期注文確定、5.7.定期注文キャンセル、5.8.定期注文履歴取得　新規追加
* 2018/09/12 EXPOのSITE機能対応
* 2018/11/08 EXPOからAWSのAPIを呼び出し機能対応
* 2018/12/15 EXPO機能追(3.4店舗情報取得)
* 2019/03/29 EXPO注文の際に、店舗定義なし（一つ店舗のみ）場合、注文通知を行わない不具合改修
* 2019/04/10 EXPOのHR機能対応（3.1. 商品情報取得）
* 2019/04/15 EXPOの10.1.稼働率分析情報を取得（稼働率・ADR・RevPer・客単価）
* 2019/06/13 Salesforce側商品削除により、AWS側連携する
* 2019/12/20 5.1.注文確定、5.4.注文履歴取得、5.5.定期注文確定、5.8.定期注文履歴取得　メモ欄情報追加
*/
@RestResource(urlMapping='/exposervice/V1/*')
global with sharing class WS_ExpoEngineService {
    // クラス処理
    @TestVisible private static CommLogUtils log;
    // 連携結果の「機能種別」キー
    private final static String FTYPE_EXPO = 'EXPO';
    // 一回取得データのサイズ情報
    @TestVisible private static Integer BAT_SIZE = 100;
    // 管理データの最大コントロール数値
    private static final Integer MANAGEID_SIZE = 1000;
    // 組織ID
    private final static String ORGID = UserInfo.getOrganizationId();
    // 2018/09/12 EXPOのSITE機能対応 BEGIN
    private static CommonRequest commReq;
    // 2018/09/12 EXPOのSITE機能対応 END
    @HttpPost   
    global static void doPost() {
        // ロゴ初期化処理
        log = new CommLogUtils('WS_ExpoEngineService,',true);
        // 指定のXMLからParseして、予約情報を取り込みを行う
        RestRequest req = RestContext.request;
        // サービス名を取得する
        String serviceName = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        Blob bodyString = req.requestBody;
        String reqXml = CommUtils.nullToBlank(bodyString.toString());
        // 3.1. 商品情報取得/3.2.個人情報取得/3.3.商品購入者一覧取得/3.4.店舗情報取得
        if (serviceName == SERVICE_NAME.getmasterinfo.name()) {
            RestContext.response.responseBody = Blob.valueOf(getmasterinfo(reqXml));
        } 
        // 4.1.在庫取得
        else if (serviceName == SERVICE_NAME.getproductstocklist.name()) {
            RestContext.response.responseBody = Blob.valueOf(getproductstocklist(reqXml));
        }
        //5.1.注文確定/5.3.注文キャンセル/5.4.注文履歴取得/5.9.決済情報取得/5.10.注文見積情報取得
        else if (serviceName == SERVICE_NAME.orderinfo.name()) {
            RestContext.response.responseBody = Blob.valueOf(getorderinfo(reqXml));
        } 
        // 6.1.推奨商品取得
        else if (serviceName == SERVICE_NAME.getlinkproductlist.name()) {
            RestContext.response.responseBody = Blob.valueOf(getlinkproductlist(reqXml));
        } 
        // 7.1.Notification
        else if (serviceName == SERVICE_NAME.notifyinfo.name()) {
            RestContext.response.responseBody = Blob.valueOf(notifyinfo(reqXml));
        } 
        // 8.1.問い合わせ送信
        else if (serviceName == SERVICE_NAME.caseinfo.name()) {
            RestContext.response.responseBody = Blob.valueOf(caseinfo(reqXml));
        }
        // 2019/04/15 EXPOの10.1.稼働率分析情報を取得（稼働率・ADR・RevPer・客単価） WSQ BEGIN
        // 10.1.稼働率分析情報を取得（稼働率・ADR・RevPer・客単価）
        else if (serviceName == SERVICE_NAME.analytics.name()) {
            RestContext.response.responseBody = Blob.valueOf(analytics(reqXml));
        }
        // 2019/04/15 EXPOの10.1.稼働率分析情報を取得（稼働率・ADR・RevPer・客単価） WSQ END
    }
    // ******************************
    // 3.商品情報取得
    // ******************************
    @TestVisible private static string getmasterinfo(String reqXml) {
        // 商品情報取得
        log.write_method_start('getmasterinfo');
        log.write_log('reqXml：'+reqXml);
        String retStr = '';
        try {
            // 取得のリクエストXMLを会席する
            Dom.Document doc = new Dom.Document();
            doc.load(reqXml);
            Dom.XMLNode rootNode = doc.getRootElement();

            // 共通条件を取得する
            commReq = new CommonRequest(rootNode.getChildElement('CommonRequest', null));
            // リクエスト情報解析する
            // 3.1.商品情報取得
            if (commReq.isGetProductMst()) {
                retStr = getProdMasterinfo(rootNode);
            } 
            // 3.2.個人情報取得
            else if (commReq.isGetUserInfonMst()) {
                retStr = getUserinfo(rootNode);
            } 
            // 3.3.商品購入者一覧取得
            else if (commReq.isGetAllBuyer()) {
                retStr = getAllBuyer(rootNode);
            }
            // 2018/12/15 EXPO機能追(3.4店舗情報取得)
            // 3.4.情報情報一覧取得
            else if (commReq.isGetShopInfo()) {
                retStr = getShopInfo(rootNode);
            }
        } catch (Exception e) {
            // エラー処理 
            WS_ResultInfo ret = new WS_ResultInfo('E9999',MSG_E9999);
            
	        String rsXmltemp = '<GetMasterInfoRS><CommonResponse>$$_CommonResponse_$$</CommonResponse></GetMasterInfoRS>';
	        retStr = rsXmltemp.replace('$$_CommonResponse_$$',ret.toXml());
	                        
            log.write_error(e.getStackTraceString());
            log.write_error(e.getMessage());
        }
        log.write_method_end();
        // 2017/12/06 性能改善 BEGIN
        CommLogUtils.saveLogToDb(log.getAllLog(),CommLogUtils.LogType.EXPO,1000);
        return retStr;
    }
    
    // ******************************
    // 4.在庫取得
    // ******************************
    @TestVisible private static string getproductstocklist(String reqXml) {
        // 商品情報取得
        log.write_method_start('getproductstocklist');
        log.write_log('reqXml：'+reqXml);
        String retStr = '';
        try {
            // 取得のリクエストXMLを会席する
            Dom.Document doc = new Dom.Document();
            doc.load(reqXml);
            Dom.XMLNode rootNode = doc.getRootElement();

            // 共通条件を取得する
            commReq = new CommonRequest(rootNode.getChildElement('CommonRequest', null));
            // リクエスト情報解析する
            // 4.1.在庫取得
            if (commReq.isGetProductStock()) {
                retStr = getProdStockinfo(rootNode);
            } 
           
        } catch (Exception e) {
            // エラー処理 
            WS_ResultInfo ret = new WS_ResultInfo('E9999',MSG_E9999);
            
	        String rsXmltemp = '<GetMasterInfoRS><CommonResponse>$$_CommonResponse_$$</CommonResponse></GetMasterInfoRS>';
	        retStr = rsXmltemp.replace('$$_CommonResponse_$$',ret.toXml());
	                        
            log.write_error(e.getStackTraceString());
            log.write_error(e.getMessage());
        }
        log.write_method_end();
        // 2017/12/06 性能改善 BEGIN
        CommLogUtils.saveLogToDb(log.getAllLog(),CommLogUtils.LogType.EXPO,1000);
        return retStr;
    }
    
/* 検証XML[SANDBOX]
    <GetMasterInfoRQ>
        <CommonRequest>
            <majorno>2</majorno>
            <minorno>1</minorno>
        </CommonRequest>
        <ExtractionCondition>
            <ProductCodes>00Dp00000000hip-6001,00Dp00000000hip-6002,00Dp00000000hip-6003</ProductCodes>
        </ExtractionCondition>
    </GetMasterInfoRQ>
*/
    /**
    * 4.1.在庫取得
    * /services/apexrest/ps/exposervice/V1/getproductstocklist
    **/
    @TestVisible private static string getProdStockinfo(Dom.XMLNode rootNode) {
    	// 処理結果情報を格納する
        WS_ResultInfo ret = new WS_ResultInfo();
        // パラメータ情報
        ProdStockReq req = null;
        // レスポンス情報
        String prodInfo = '';
    	
    	try {
            // 引き渡すパラメータ情報を解析する
            req = new ProdStockReq(rootNode); 
System.debug(loggingLevel.info, 'req='+req);
            // 有効チェック
            req.validata();
            // 抽出条件商品コードの商品情報を取得する
	        //List<String> reqProducts = req.ProductCodes;
	        List<String> prodList = new List<String>();
	        //List<AccountMaster__c> acc = new List<AccountMaster__c>();
	        if (!req.ProductCodes.isEmpty()) {
	            List<AccountMaster__c> acc = [select id, Field3__c, Name, SalesStatus__c, ShopInfoRef__r.ShopCode__c ,ExpoStockCount__c,
	            								(Select LogicQtyOfStock__c From StockProductRef__r)
	                                           from AccountMaster__c where Field3__c in:req.ProductCodes Order by Field3__c];
	            //商品情報在庫情報リスト
            	for (AccountMaster__c accitem : acc) {
                    MasterProdItem item = new MasterProdItem();
	                item.ProductCode = getExpoCode(accitem.Field3__c);
					item.ProductName = accitem.Name;
					// 2018/08/09 在庫情報を返却 BEGIN
		            if (commReq.isExpoSite()) item.SalStockCount = CommUtils.nullToBlank(CommUtils.nullToBlank(accitem.ExpoStockCount__c));
					else {
			            item.SalStockCount = CommUtils.nullToBlank(0);
						if (!accitem.StockProductRef__r.isEmpty()) {
							item.SalStockCount = CommUtils.nullToBlank(CommUtils.nullToBlank(accitem.StockProductRef__r[0].LogicQtyOfStock__c));
						}
					}
					// 2018/08/09 在庫情報を返却 END
					// 販売ステータス
					item.SalesStatus = CommUtils.nullToBlank(accitem.SalesStatus__c);
					if (item.SalesStatus == '販売中') item.SalesStatus = '1';
					else if(item.SalesStatus == '停止中') item.SalesStatus = '2';
					item.ShopCode = accitem.ShopInfoRef__r.ShopCode__c;	
	                prodList.add(item.toXml());
                }
	        }
            if (!prodList.isEmpty()) prodInfo = '<ProdStockList>'+String.join(prodList, '')+'</ProdStockList>';
        } catch (CommException ex) {
            // 予想以外の異常が発生する場合
            ret = new WS_ResultInfo('E0401',ex.getMessage());
        } catch (Exception e) {
            // 予想以外の異常が発生する場合
            ret = new WS_ResultInfo('E9999',MSG_E9999);
            log.write_error(e.getStackTraceString());
            log.write_error(e.getMessage());
        }
        // 返却テンプレートXML
        String rsXmltemp = '<GetProdStockListRS><CommonResponse>$$_CommonResponse_$$</CommonResponse>$$_ProdStockInfo_$$</GetProdStockListRS>';
        return rsXmltemp.replace('$$_CommonResponse_$$',ret.toXml())
                        .replace('$$_ProdStockInfo_$$',prodInfo);
    }
    
    class ProdStockReq {
        public ProdStockReq(Dom.XmlNode root) {
            ProductCodes = new List<String>();
            // 抽出条件
            Dom.XmlNode extrField = root.getChildElement('ExtractionCondition', null);
            if (extrField != null) {
                String wkProductCodes = getChildElementByName(extrField, 'ProductCodes');
                if (!CommUtils.isBlank(wkProductCodes)) {
                    for (String c : wkProductCodes.split(',')) {
                        if (CommUtils.isBlank(c)) continue;
                        String pd = convertProductCd(c);
                        if (!CommUtils.isBlank(pd)) ProductCodes.add(pd);
                    } 
                }
            }
        }
        // 引き渡すパラメータ商品コード情報
        List<String> ProductCodes{get;set;}
        public Boolean validata() {
            if (ProductCodes != null && (ProductCodes.size() > 100 || ProductCodes.isEmpty())){
                throw new CommException(MSG_E0001);
            }
            // 全部情報
            return true;
        }
    }
    
    class MasterProdItem {
        public String ProductCode{get;set;}//商品コード
		public String ProductName{get;set;}//商品品名
		public String SalStockCount{get;set;}//販売荷姿在庫数
		public String SalesStatus{get;set;}//販売状態
		public String ShopCode{get;set;}//店舗コード
        public String toXml() {
            String xml = '<ProdStockInfos>$_ProdStockInfos_$</ProdStockInfos>';
            String xmlBody = '';
            xmlBody+=joinTagXml('ProductCode',ProductCode);
			xmlBody+=joinTagXml('ProductName',ProductName);
			xmlBody+=joinTagXml('SalStockCount',SalStockCount);
			xmlBody+=joinTagXml('SalesStatus',SalesStatus);
			xmlBody+=joinTagXml('ShopCode',ShopCode);
            return xml.replace('$_ProdStockInfos_$',xmlBody);
        }
    }
    
    // ******************************
    // 5.注文
    // ******************************
    @TestVisible private static string getorderinfo(String reqXml) {
        // 注文処理機能
        log.write_method_start('getorderinfo');
        log.write_log('reqXml：'+reqXml);
        String retStr = '';
        try {
            // 取得のリクエストXMLを会席する
            Dom.Document doc = new Dom.Document();
            doc.load(reqXml);
            Dom.XMLNode rootNode = doc.getRootElement();
            // 共通条件を取得する
            commReq = new CommonRequest(rootNode.getChildElement('CommonRequest', null));
            // リクエスト情報解析する
            // 5.1.Restful API Interface 5.1  "注文確定"(orderinfo)
            if (commReq.isSetOrderInfo()) {
                retStr = setOrderinfo(rootNode);
            } 
            // 5.3.Restful API Interface 5.3  "注文キャンセル"(orderinfo)
            else if (commReq.isCancelOrderInfo()) {
                retStr = cancelOrderinfo(rootNode);
            }
            // 5.4 Restful API Interface 5.4  "注文履歴取得"(orderinfo)
            else if (commReq.isGetOrderHistory()) {
                retStr = getOrderHistory(rootNode,false);
            }
            // 2018/04/24 5.5.定期注文確定、5.7.定期注文キャンセル、5.8.定期注文履歴取得　新規追加 BEGIN
            // 5.5.Restful API Interface 5.5  "定期注文確定"(orderinfo)
            if (commReq.isRepSetOrderInfo()) {
                retStr = setOrderinfo(rootNode);
            } 
            // 5.7.Restful API Interface 5.7  "定期注文キャンセル"(orderinfo)
            else if (commReq.isRepCancelOrderInfo()) {
                retStr = cancelOrderinfo(rootNode);
            }
            // 5.8 Restful API Interface 5.8  "定期注文履歴取得"(orderinfo)
            else if (commReq.isRepGetOrderHistory()) {
                retStr = getOrderHistory(rootNode,true);
            }
            // 2018/04/24 5.5.定期注文確定、5.7.定期注文キャンセル、5.8.定期注文履歴取得　新規追加 END
            // 5.9.Restful API Interface 5.9  "決済情報取得"(orderinfo)
            else if (commReq.isGetPayInfo()) {
                retStr = getPayInfo(rootNode);
            }
            // 5.10.Restful API Interface 5.10  "注文見積情報取得"(orderinfo)
            else if (commReq.isGetOrderEstInfo()) {
                retStr = getOrderEstInfo(rootNode);
            }
        }
        catch (Exception e) {
            // エラー処理 
            WS_ResultInfo ret = new WS_ResultInfo('E9999',MSG_E9999);
            
            String rsXmltemp = '<GetMasterInfoRS><CommonResponse>$$_CommonResponse_$$</CommonResponse></GetMasterInfoRS>';
            retStr = rsXmltemp.replace('$$_CommonResponse_$$',ret.toXml());
                            
            log.write_error(e.getStackTraceString());
            log.write_error(e.getMessage());
        }
        log.write_method_end();
        // 2017/12/06 性能改善 BEGIN
        CommLogUtils.saveLogToDb(log.getAllLog(),CommLogUtils.LogType.EXPO,1000);
        return retStr;
    } 
    
    // ******************************
    // 6.1.推奨商品取得
    // ******************************
    @TestVisible private static string getlinkproductlist(String reqXml) {
    	log.write_method_start('getlinkproductlist');
        log.write_log('reqXml：'+reqXml);
        String retStr = '';
        try {
            // 取得のリクエストXMLを会席する
            Dom.Document doc = new Dom.Document();
            doc.load(reqXml);
            Dom.XMLNode rootNode = doc.getRootElement();

            // 共通条件を取得する
            commReq = new CommonRequest(rootNode.getChildElement('CommonRequest', null));
            // リクエスト情報解析する
            // 6.1.推奨商品取得
            if (commReq.isGetLinkProdInfo()) {
                retStr = getLinkProdInfo(rootNode);
            } 
        } catch (Exception e) {
            // エラー処理 
            WS_ResultInfo ret = new WS_ResultInfo('E9999',MSG_E9999);
            
            String rsXmltemp = '<GetLinkProductListRS><CommonResponse>$$_CommonResponse_$$</CommonResponse></GetLinkProductListRS>';
            retStr = rsXmltemp.replace('$$_CommonResponse_$$',ret.toXml());
                            
            log.write_error(e.getStackTraceString());
            log.write_error(e.getMessage());
        }
        log.write_method_end();
        // 2017/12/06 性能改善 BEGIN
        CommLogUtils.saveLogToDb(log.getAllLog(),CommLogUtils.LogType.EXPO,1000);
        return retStr;
    }
/*
    <GetLinkProductListRQ>
        <CommonRequest>
            <majorno>4</majorno>
            <minorno>1</minorno>
        </CommonRequest>
        <ExtractionCondition>
            <ProductCodes>00Dp00000000hip-6001,00Dp00000000hip-6002,00Dp00000000hip-6003</ProductCodes>
        </ExtractionCondition>
    </GetLinkProductListRQ>
*/
     /**
    * 6.1.推奨商品取得
    * /services/apexrest/ps/exposervice/V1/getlinkproductlist
    **/
    @TestVisible private static string getLinkProdInfo(Dom.XMLNode rootNode) {
    	// 処理結果情報を格納する
        WS_ResultInfo ret = new WS_ResultInfo();
        // パラメータ情報
        LinkProdReq req = null;
        // レスポンス情報
        String prodInfo = '';
        try {
            // 引き渡すパラメータ情報を解析する
            req = new LinkProdReq(rootNode); 
            // 有効チェック
            req.validata();
	        // 引き渡すパラメータ情報
	        MasterProdReq cvtReq = new MasterProdReq();
	        cvtReq.ProductCodes = req.ProductCodes;
	        // 引き渡す商品情報コードから商品を取得する
	        List<String> xmlRs = new List<String>();
	        if (!cvtReq.ProductCodes.isEmpty()) xmlRs = getProdMasterInfoComm(cvtReq, null);
	        // XML情報設定
            prodInfo = '<ProductList>'+String.join(xmlRs, '')+'</ProductList>';
        } catch (CommException ex) {
            // 予想以外の異常が発生する場合
            ret = new WS_ResultInfo('E0504',ex.getMessage());
        } catch (Exception e) {
            // 予想以外の異常が発生する場合
            ret = new WS_ResultInfo('E9999',MSG_E9999);
            log.write_error(e.getStackTraceString());
            log.write_error(e.getMessage());
        }
        // 返却テンプレートXML
        String rsXmltemp = '<GetLinkProductListRS><CommonResponse>$$_CommonResponse_$$</CommonResponse>$$_ProdInfo_$$</GetLinkProductListRS>';
        return rsXmltemp.replace('$$_CommonResponse_$$',ret.toXml())
                        .replace('$$_ProdInfo_$$',prodInfo);
    }
    
    class LinkProdReq {
        public LinkProdReq(Dom.XmlNode root) {
            ProductCodes = new List<String>();
            // 抽出条件
            Dom.XmlNode extrField = root.getChildElement('ExtractionCondition', null);
            if (extrField != null) {
                //UserId = getChildElementByName(extrField, 'UserId');
                String wkProductCodes = getChildElementByName(extrField, 'ProductCodes');
                if (!CommUtils.isBlank(wkProductCodes)) {
                    for (String c : wkProductCodes.split(',')) {
                        if (CommUtils.isBlank(c)) continue;
                        String[] sc = c.split('-');
                        if (sc.size() > 1) ProductCodes.add(sc[1]);
                    } 
                }
            }
        }
        String UserId{get;set;}
        List<String> ProductCodes{get;set;}
        //  有効性チェック
        public Boolean validata() {
            // 必須チェック
            /*
            if (CommUtils.isBlank(UserId)) {
                throw new CommException(MSG_E0001);
            }
            */
            return true;
        }
    }
    
    /**
    * 7.1.Notification
    **/
    @TestVisible private static string notifyinfo(String reqXml) {
        // 商品情報取得
        log.write_method_start('notifyinfo');
        log.write_log('reqXml：'+reqXml);
        String retStr = '';
        try {
            // 取得のリクエストXMLを会席する
            Dom.Document doc = new Dom.Document();
            doc.load(reqXml);
            Dom.XMLNode rootNode = doc.getRootElement();

            // 共通条件を取得する
            commReq = new CommonRequest(rootNode.getChildElement('CommonRequest', null));
            // リクエスト情報解析する
            // 7.1.Notification
            if (commReq.isSetNotifyInfo()) {
                retStr = setNotifyInfo(rootNode);
            } 
        } catch (Exception e) {
            // エラー処理 
            WS_ResultInfo ret = new WS_ResultInfo('E9999',MSG_E9999);
            
            String rsXmltemp = '<NotifyInfoRS><CommonResponse>$$_CommonResponse_$$</CommonResponse></NotifyInfoRS>';
            retStr = rsXmltemp.replace('$$_CommonResponse_$$',ret.toXml());
                            
            log.write_error(e.getStackTraceString());
            log.write_error(e.getMessage());
        }
        log.write_method_end();
        // 2017/12/06 性能改善 BEGIN
        CommLogUtils.saveLogToDb(log.getAllLog(),CommLogUtils.LogType.EXPO,1000);
        return retStr;
    }
/* 検証XML[SANDBOX]
    <NotifyInfoRQ>
        <CommonRequest>
            <majorno>5</majorno>
            <minorno>1</minorno>
        </CommonRequest>
        <NotifyInfo>
            <NofityTitle>商品販売開始しますか</NofityTitle>
            <NofityContent>期待した販売開始しました、ご案内させていただきます、URL：http://yahoo.co.jp</NofityContent>
            <NofityDateTime>20180312141618</NofityDateTime>
            <NotifyTargetUserId>00Dp00000000hip-00510000001wl0B</NotifyTargetUserId>
            <IsNotifyAll>0</IsNotifyAll>
        </NotifyInfo>
    </NotifyInfoRQ>   
*/
    /**
    * 7.1Chatterポスト情報
    * /services/apexrest/ps/exposervice/V1/notifyinfo
    **/
    @TestVisible private static string setNotifyInfo(Dom.XMLNode rootNode) {
    	// 処理結果情報を格納する
        WS_ResultInfo ret = new WS_ResultInfo();
        // 引き渡すパラメータ情報
        NotifyInfoReq req = null;
        // DB情報SAVEPOINT
        Savepoint sp = Database.setSavepoint();	
        try {
        	// 引き渡すパラメータを解析する
	        req = new NotifyInfoReq(rootNode);
            // 有効チェック
            req.validata();
            // EXPO通知ユーザ存在チェック
            string sfUserId = convertUserId(req.NotifyTargetUserId);
            // EXPOのサイトユーザの場合 BEGIN by zh
            if(commReq.isExpoSite()) {
            	String q = CommSqlUtils.generateQueryString('ExpoUser__c') + ' where Id = :sfUserId ';
            	List<ExpoUser__c> usrs = DataBase.query(q);
            	if (usrs.isEmpty()) {
	                ret = new WS_ResultInfo('E0003',MSG_E0003);
	            }else {
	            	String tmplate = 'タイトル：$_TITLE_$\n内容：$_CONTENT_$\n日時：$_TIME_$';
	                String body = tmplate
	                            .replace('$_TITLE_$',req.NofityTitle)
	                            .replace('$_CONTENT_$',req.NofityContent)
	                            .replace('$_TIME_$',req.NofityDateTime);
			        
			        System.debug(loggingLevel.info, 'body========'+body);
			        /*FeedItem post = new FeedItem();
			        post.Type = 'TextPost';
			        post.ParentId = usrs[0].Id; //eg. Installer
	                post.Body = body;
			        insert post;*/
            	}
            }else{
            List<User> users = [select id from user where id = :sfUserId];
            if (users.isEmpty()) {
                ret = new WS_ResultInfo('E0003',MSG_E0003);
            } else {
                String tmplate = 'タイトル：$_TITLE_$\n内容：$_CONTENT_$\n日時：$_TIME_$';
                String body = tmplate
                            .replace('$_TITLE_$',req.NofityTitle)
                            .replace('$_CONTENT_$',req.NofityContent)
                            .replace('$_TIME_$',req.NofityDateTime);
		        FeedItem post = new FeedItem();
		        post.Type = 'TextPost';
		        post.ParentId = users[0].Id; //eg. Installer
                post.Body = body;
		        insert post;
            }
            }
            // EXPOのサイトユーザの場合 END by zh
        }catch (CommException ex) {
            // 予想以外の異常が発生する場合
            ret = new WS_ResultInfo('E0701',ex.getMessage());
        } catch (Exception e) {
            // RollBackp
            DataBase.rollBack(sp);
            // 予想以外の異常が発生する場合
            ret = new WS_ResultInfo('E9999',MSG_E9999);
            System.debug(e.getMessage());
            log.write_error(e.getStackTraceString());
            log.write_error(e.getMessage());
        }
        // 処理結果作成する
        String rsXmltemp = '<NotifyInfoRS><CommonResponse>$$_CommonResponse_$$</CommonResponse></NotifyInfoRS>';
        return rsXmltemp.replace('$$_CommonResponse_$$',ret.toXml());
    }
    
    //**************************************************
    // 7.1.Notification
    //**************************************************
    class NotifyInfoReq {
        public NotifyInfoReq(Dom.XmlNode root) {
        	// 問い合わせ情報
            Dom.XmlNode notifyInfoField = root.getChildElement('NotifyInfo', null);
            if (notifyInfoField != null) {
				NofityTitle = getChildElementByName(notifyInfoField,'NofityTitle');
				NofityContent = getChildElementByName(notifyInfoField,'NofityContent');
				NofityDateTime = getChildElementByName(notifyInfoField,'NofityDateTime');
				NotifyTargetUserId = getChildElementByName(notifyInfoField,'NotifyTargetUserId');
				IsNotifyAll = getChildElementByName(notifyInfoField,'IsNotifyAll');
            }
            // YYYYMMDDHHMMSS
            if (!CommUtils.isBlank(NofityDateTime) && NofityDateTime.length() == 14) {
                String dateStr = NofityDateTime.substring(0,8);
                Date dt = CommUtils.stringToDate(dateStr);
                // HHMMSS
                String timeStr = NofityDateTime.substring(8);
                String hh = timeStr.substring(0,2);
                String mm = timeStr.substring(2,4);
                String ss = timeStr.substring(4,6);
                Time tm = Time.newInstance(Integer.valueof(hh), Integer.valueof(mm), Integer.valueof(ss), 0);
                Datetime formater = DateTime.newInstance(dt,tm);
                NofityDateTime = formater.format('yyyy-MM-dd HH:mm:ss');
            }
        }
        // 問い合わせ情報
        /*タイトル											
		詳細内容											
		日時											
		通知先ユーザID											
		ユーザ所属の店舗へ通知フラグ											
		*/
        String NofityTitle{get;set;}
		String NofityContent{get;set;}
		String NofityDateTime{get;set;}
		String NotifyTargetUserId{get;set;}
		String IsNotifyAll{get;set;}
        // 有効性チェックを行う
        public Boolean validata() {
            // 必須チェック
            if (CommUtils.isBlank(NofityTitle) ||
                CommUtils.isBlank(NofityContent) ||
                CommUtils.isBlank(NofityDateTime) ||
                CommUtils.isBlank(NotifyTargetUserId) ||
                CommUtils.isBlank(IsNotifyAll)) {
                throw new CommException(MSG_E0001 + ':' + this);
            }
            return true;
        }
    }
    
	/**検証用XML
	<GetMasterInfoRQ>
	    <CommonRequest>
	        <majorno>1</majorno>
	        <minorno>1</minorno>
	    </CommonRequest>
	    <ExtractionCondition>
	    </ExtractionCondition>
	</GetMasterInfoRQ>
	
	/services/apexrest/ps/exposervice/V1/getmasterinfo
	*/ 
    // 3.1.商品情報取得
    @TestVisible private static string getProdMasterinfo(Dom.XMLNode rootNode) {
        // 処理結果情報を格納する
        WS_ResultInfo ret = new WS_ResultInfo();
        // 検索結果集計情報
        XmlProductRest res = new XmlProductRest();   
        // 商品情報
        List<String> xmlRs = new List<String>();  
        // 引き渡すパラメータ情報
        MasterProdReq req = null;
        // DB情報SAVEPOINT
        Savepoint sp = Database.setSavepoint();
        try {
            // 引き渡すパラメータを解析する
	        req = new MasterProdReq(rootNode);
            // 有効チェック
            req.validata();
            // EXCEPTION TEST SAMPLE
            xmlRs = getProdMasterInfoComm(req, res);
	        // EXCEPTION TEST SAMPLE
	        //integer a = 10/0;
        } catch (Exception e) {
            // RollBackp
            DataBase.rollBack(sp);
            // 予想以外の異常が発生する場合
            ret = new WS_ResultInfo('E9999',MSG_E9999);
            // JOBIDが存在する場合、JOBIDを残る
            if (req != null && !CommUtils.isBlank(req.JobId)) res.JobId = req.JobId;
            // 返却結果情報をクリアする
            xmlRs.clear();
            log.write_error(e.getStackTraceString());
            log.write_error(e.getMessage());
        }
//log.write_log('ProductInfo='+String.join(xmlRs,''));
        // 処理結果作成する
        String rsXmltemp = '<GetMasterInfoRS><CommonResponse>$$_CommonResponse_$$</CommonResponse><ProductList>$$_ResultInfo_$$$$_ProductInfo_$$</ProductList></GetMasterInfoRS>';
        return rsXmltemp.replace('$$_CommonResponse_$$',ret.toXml())
                        .replace('$$_ResultInfo_$$',res.toXml())
                        .replace('$$_ProductInfo_$$',String.join(xmlRs,''));
    }
    // UI側に使える商品コード
    private static String getExpoCode(String s) {
        return (ORGID + '-' + s);
    }
    // UUIDにより、連携結果のデータをチェックする、最大100件LOOPING処理を行う
    private static Id getLastProdId (String uuid) {
        //
        String key = FTYPE_EXPO + uuid;
        List<CooperationResult__c> coops = [select id,ErrorContent__c From CooperationResult__c where ManageID__c = :key limit 1];
        if (!coops.isEmpty()) {
            return coops[0].ErrorContent__c;
        }
        return null;
    }
    // 今回検索した商品のIDを格納する
    private static void setLastProdId(String uuid, String lastProdId) {
        if (CommUtils.isBlank(uuid)) return;
        String key = FTYPE_EXPO + uuid;
        String functype = FTYPE_EXPO;
        CooperationResult__c coop = null;
        List<CooperationResult__c> coops = [select id From CooperationResult__c where FunctionType__c = :functype and ManageID__c = :key limit 1 for update];
        if (!coops.isEmpty()) {
            // 更新する
            coops[0].ErrorContent__c = lastProdId;
            update coops[0];
            return;
        }
        // 新規場合、最大情報格納チェック
        coops = [select id From CooperationResult__c where FunctionType__c = :functype order by LastModifiedDate asc];
        if (coops.size() >= MANAGEID_SIZE) {
            coop = coops[0];
            coop.ManageID__c = key;
            coop.ErrorContent__c = lastProdId;
            update coop;
            return;
        } else {
            // 新規場合
	        coop = new CooperationResult__c(
	            ManageID__c = key,
	            ErrorContent__c = lastProdId,
	            FunctionType__c = FTYPE_EXPO
	        );
	        upsert coop CooperationResult__c.ManageID__c;
        }
    }
    
    /**検証要XML
	<GetMasterInfoRQ>
	    <CommonRequest>
	        <majorno>1</majorno>
	        <minorno>2</minorno>
	    </CommonRequest>
	    <ExtractionCondition>
	        <UserId>00Dp00000000hip-00510000001wl0B</UserId>
	    </ExtractionCondition>
	</GetMasterInfoRQ>
    */
    /*
    * 3.2.個人情報取得API処理機能
    */
    @TestVisible private static string getUserinfo(Dom.XMLNode rootNode) {
        // 処理結果情報を格納する
        WS_ResultInfo ret = new WS_ResultInfo();
        // パラメータ情報
        MasterUserReq req = null;
        // User情報により、店舗情報とフラグ情報を取得する
        XmlUserInfo userinf = new XmlUserInfo();        
        try {
            // 引き渡すパラメータを解析する
            req = new MasterUserReq(rootNode);
            // 有効チェック
            req.validata();
            // 2018/09/12 EXPOのSITE機能対応 BEGIN
            // EXPOのサイトユーザの場合
            if(commReq.isExpoSite()) {
            	String usrId = req.sfUserId;
            	String q = CommSqlUtils.generateQueryString('ExpoUser__c') + ' where Id = :usrId ';
            	List<ExpoUser__c> usrs = DataBase.query(q);
	            if (usrs.isEmpty()) {
	                ret = new WS_ResultInfo('E0003',MSG_E0003);
	            } else {
	            	ExpoUser__c u = usrs[0];
	                // TODO DEMOデータ
		            userinf.IsManager = '1';
		            userinf.MemberType = '1';
		            // ユーザ関連情報を取得する
			        //UserUtil.UserShopInfo uinfo = UserUtil.getUserInfo(req.sfUserId);
			        // 2018/02/28 ユーザ氏名パラメータを返却する
			        userinf.UserName = u.Name;
			        userinf.UserId = req.uiUserId;
			        // 2018/10/07 注文情報送信機能の対応 WSQ BEGIN
			        userinf.UserEmail = u.Email__c;
			        // 2018/10/07 注文情報送信機能の対応 WSQ END
			        // 店舗関連情報取得する
			        String defShopCd = CommUtils.nullToBlank(u.ShopCode__c);
			        // 2018/09/12 EXPOのSITE機能対応 BEGIN
			        List<ShopInformation__c> shopInfo = [select shopcode__c, Name, Address__c,Post__c from ShopInformation__c where ExpoOrgInfoRef__c = :commReq.subOrgId and shopcode__c = :defShopCd limit 1];
			        // 2018/09/12 EXPOのSITE機能対応 BEGIN
			        if (!shopInfo.isEmpty()) {
			            ShopInformation__c shop = shopInfo[0];
			            userinf.ShopCode = CommUtils.nullToBlank(shop.ShopCode__c);
			            userinf.ShopName = CommUtils.nullToBlank(shop.Name);
			            userinf.ShopAddress = CommUtils.nullToBlank(shop.Address__c);
			            // 2018/10/07 注文情報送信機能の対応 WSQ BEGIN
			            userinf.ShopPostNo = CommUtils.nullToBlank(shop.Post__c);
			            // 2018/10/07 注文情報送信機能の対応 WSQ END
			        } else {
			            // 組織情報を返却する
			            List<ExpoOrgInfo__c> orgs = [select name,AddressCal__c,PostNo__c from ExpoOrgInfo__c where id = :commReq.subOrgId limit 1];
			            if (!orgs.isEmpty()) {
			                ExpoOrgInfo__c org = orgs[0];
			                userinf.ShopName = CommUtils.nullToBlank(org.Name);
			                // 2018/10/07 注文情報送信機能の対応 WSQ BEGIN
			                // userinf.ShopAddress =  CommUtils.nullToBlank(org.Address__c);
			                userinf.ShopPostNo = CommUtils.nullToBlank(org.PostNo__c);
			                userinf.ShopAddress =  CommUtils.nullToBlank(org.AddressCal__c);
			                // 2018/10/07 注文情報送信機能の対応 WSQ END
			            }
			        }
			        // **************************************************
			        // TODO
			        userinf.TransactionAmout = CommUtils.getRandom(7);
			        userinf.NeedAmoutToUp = CommUtils.nullToBlank(10000000- CommUtils.nullToZero(userinf.TransactionAmout));
			        userinf.SaveChargeAmount = String.valueof(Integer.valueOf(CommUtils.nullToZero(userinf.TransactionAmout) * (CommUtils.nullToZero(CommUtils.getRandom(1))/200)));
			        // **************************************************
	            }
            } else {
	    // 2018/09/12 EXPOのSITE機能対応 END
            // USER情報を検索する
            List<user> usrs = [select id from User Where Id = :req.sfUserId];
            if (usrs.isEmpty()) {
                ret = new WS_ResultInfo('E0003',MSG_E0003);
            } else {
                // TODO DEMOデータ
	            userinf.IsManager = '1';
	            userinf.MemberType = '1';
	            // ユーザ関連情報を取得する
		        UserUtil.UserShopInfo uinfo = UserUtil.getUserInfo(req.sfUserId);
		        // 2018/02/28 ユーザ氏名パラメータを返却する
		        userinf.UserName = uinfo.u.Name;
		        userinf.UserId =req.uiUserId;
		        // 2018/10/07 注文情報送信機能の対応 WSQ BEGIN
		        userinf.UserEmail = uinfo.u.Email;
		        // 2018/10/07 注文情報送信機能の対応 WSQ END
		        Map<String,ShopInformation__c> shopInfoMap = ShopInfoUtil.getShopInfoMap();
		        if (shopInfoMap.containsKey(uinfo.defaultShopCode)) {
		            ShopInformation__c shop = shopInfoMap.get(uinfo.defaultShopCode);
		            userinf.ShopCode = CommUtils.nullToBlank(shop.ShopCode__c);
		            userinf.ShopName = CommUtils.nullToBlank(shop.Name);
		            userinf.ShopAddress = CommUtils.nullToBlank(shop.Address__c);
		            // 2018/10/07 注文情報送信機能の対応 WSQ BEGIN
		            userinf.ShopPostNo = CommUtils.nullToBlank(shop.Post__c);
		            // 2018/10/07 注文情報送信機能の対応 WSQ END
		        } else {
		            // 組織情報を返却する
		            userinf.ShopName = UserInfo.getOrganizationName();
		            List<Organization> orgs = [select State, City, Street,PostalCode From Organization where id = :UserInfo.getOrganizationId() limit 1];
		            if (!orgs.isEmpty()) {
		                Organization org = orgs[0];
		                userinf.ShopAddress =  (CommUtils.nullToBlank(org.State) + CommUtils.nullToBlank(org.City) + CommUtils.nullToBlank(org.Street));
		            	// 2018/10/07 注文情報送信機能の対応 WSQ BEGIN
		            	userinf.ShopPostNo = CommUtils.nullToBlank(org.PostalCode);
		            	// 2018/10/07 注文情報送信機能の対応 WSQ END
		            }
		        }
		        // **************************************************
		        // TODO
		        userinf.TransactionAmout = CommUtils.getRandom(7);
		        userinf.NeedAmoutToUp = CommUtils.nullToBlank(10000000- CommUtils.nullToZero(userinf.TransactionAmout));
		        userinf.SaveChargeAmount = String.valueof(Integer.valueOf(CommUtils.nullToZero(userinf.TransactionAmout) * (CommUtils.nullToZero(CommUtils.getRandom(1))/200)));
		        // **************************************************
            }
	    // 2018/09/12 EXPOのSITE機能対応 BEGIN
            }
	    // 2018/09/12 EXPOのSITE機能対応 END
        }catch (CommException ex) {
            // 予想以外の異常が発生する場合
            ret = new WS_ResultInfo('E0504',ex.getMessage());
        }catch (Exception e) {
            // 予想以外の異常が発生する場合
            ret = new WS_ResultInfo('E9999',MSG_E9999);
            log.write_error(e.getStackTraceString());
            log.write_error(e.getMessage());
        }
        // 処理結果作成する    
        String rsXmltemp = '<GetMasterInfoRS><CommonResponse>$$_CommonResponse_$$</CommonResponse>$$_UserInfo_$$</GetMasterInfoRS>';
        return rsXmltemp.replace('$$_CommonResponse_$$',ret.toXml())
                        .replace('$$_UserInfo_$$',userinf.toXml());
    }

    /**検証要XML[PACKAGE環境]
    <GetMasterInfoRQ>
        <CommonRequest>
            <majorno>1</majorno>
            <minorno>3</minorno>
        </CommonRequest>
        <ExtractionCondition>
            <ProductCode>00Dd0000000dBJC-1105</ProductCode>
        </ExtractionCondition>
    </GetMasterInfoRQ>
    */
    /**
    * 3.3.商品購入者一覧取得
    * /services/apexrest/ps/exposervice/V1/getmasterinfo
    **/
    @TestVisible private static string getAllBuyer(Dom.XMLNode rootNode) {
        // 処理結果情報を格納する
        WS_ResultInfo ret = new WS_ResultInfo();
        // パラメータ情報
        MasterBuyerReq req = null;
        // レスポンス情報
        String buyerInfo = '';
        try {
            // 引き渡すパラメータ情報を解析する
            req = new MasterBuyerReq(rootNode); 
            // 有効チェック
            req.validata();
            // 指定の会計商品コードから最大１００件まで購入履歴情報を返却する
            List<AggregateResult> orderItemAvgs = [select RefParOrder__c orderId from OrderItem__c where AccountMasterRef__r.Field3__c = :req.sfProduct group by RefParOrder__c limit 100];
            set<Id> orderIds = new set<Id>();
            for (AggregateResult item : orderItemAvgs) {
                orderIds.add((ID)item.get('orderId'));
            }
            // データ存在する場合
            if (!orderIds.isEmpty()) {
                List<Order__c> orders = [select id, OrderUserId__c, CreatedDate from Order__c where id in:orderIds order by CreatedDate desc];
                List<String> buyerList = new List<String>();
                for (Order__c oitem : orders) {
                    MasterBuyerItem item = new MasterBuyerItem();
                    item.PurDate = oitem.CreatedDate.format('yyyyMMddHHmmss');
                    item.PurUserId = oitem.OrderUserId__c;
                    buyerList.add(item.toXml());
                }
                buyerInfo = '<PurUserHistoryList>'+String.join(buyerList, '')+'</PurUserHistoryList>';
            }
        } catch (CommException ex) {
            // 予想以外の異常が発生する場合
            ret = new WS_ResultInfo('E0504',ex.getMessage());
        } catch (Exception e) {
            // 予想以外の異常が発生する場合
            ret = new WS_ResultInfo('E9999',MSG_E9999);
            log.write_error(e.getStackTraceString());
            log.write_error(e.getMessage());
        }
        // 返却テンプレートXML
        String rsXmltemp = '<GetMasterInfoRS><CommonResponse>$$_CommonResponse_$$</CommonResponse>$$_BuyerInfo_$$</GetMasterInfoRS>';
        return rsXmltemp.replace('$$_CommonResponse_$$',ret.toXml())
                        .replace('$$_BuyerInfo_$$',buyerInfo);
    }
    // getShopInfo
    /**検証要XML[開発環境]
    <GetMasterInfoRQ>
        <CommonRequest>
            <majorno>1</majorno>
            <minorno>4</minorno>
			<suborgid>a23p0000000L7Kq</suborgid>
        </CommonRequest>
        <ExtractionCondition>
            <OrganizationId>00Dd0000000dBJC-1105</OrganizationId>
            <ShopCodes>01,02</ShopCodes>
        </ExtractionCondition>
    </GetMasterInfoRQ>
    */
    /**
    * 3.4.店舗情報一覧取得
    * /services/apexrest/ps/exposervice/V1/getmasterinfo
    **/
    @TestVisible private static string getShopInfo(Dom.XMLNode rootNode) {
        // 処理結果情報を格納する
        WS_ResultInfo ret = new WS_ResultInfo();
        // パラメータ情報
        MasterShopInfoReq req = null;
        // レスポンス情報
        String shopInfoXml = '';
        try {
            // 引き渡すパラメータ情報を解析する
            req = new MasterShopInfoReq(rootNode); 
            // 有効チェック
            req.validata(commReq.isExpoSite());
            List<String> shopItemLst = new List<String>();
            // 店舗とロゴ情報を取得する
            if (commReq.isExpoSite()) {
                
                // 指定店舗、該店舗のロゴファイルを返却する
                List<ShopInformation__c> rsShops = [
                    Select name,ShopCode__c, (Select Id From Attachments where name like 'LOGO%' order by LastModifiedDate desc limit 1) 
                    // 2019/03/29 店舗付属情報返却追加 WSQ BEGIN
                    ,WebSite__c,ExpoIsOpenBuyHistoryFlg__c
                    // 2019/03/29 店舗付属情報返却追加 WSQ END
                    // 2019/04/10 EXPOのHR機能対応（3.1. 商品情報取得） WSQ BEGIN
                    ,Phone__c,Email__c
                    // 2019/04/10 EXPOのHR機能対応（3.1. 商品情報取得） WSQ END
                    From ShopInformation__c where ShopCode__c in :req.shopcodes];
                map<id, id> shopLogoIdMap = new map<id,id>();
                for (ShopInformation__c sp : rsShops) {
                    if (!sp.Attachments.isEmpty()) {
                        shopLogoIdMap.put(sp.id, sp.Attachments[0].Id);
                        break;
                    }
                }
System.debug(logginglevel.info, 'shopLogoIdMap='+shopLogoIdMap);
                if (!shopLogoIdMap.isEmpty()) {
                    map<id, string> logomap =new map<id, string>();
                    // ロゴIDにより、ロゴ内容を取得する
                    list<attachment> logos = [select id, body,BodyLength from attachment where id in :shopLogoIdMap.values() and BodyLength > 0];
                    for (attachment doc : logos) {
System.debug(logginglevel.info, 'doc[1]='+doc);
//System.debug(logginglevel.info, 'doc[2].body.toString()='+doc.body.toString());
System.debug(logginglevel.info, 'doc[3]='+doc);
                    	logomap.put(doc.id, EncodingUtil.base64Encode(doc.body));
                    }
System.debug(logginglevel.info, 'logomap='+logomap);
                    for (ShopInformation__c sp : rsShops) {
                    	MasterShopInfoItem item = new MasterShopInfoItem();
                    	item.ShopCode = sp.ShopCode__c;
                    	item.ShopName = sp.name;
                    	// 2019/03/29 店舗付属情報返却追加 WSQ BEGIN
                    	item.ShopSiteUrl = sp.WebSite__c;
                    	item.IsOpenBuyHistoryFlg = sp.ExpoIsOpenBuyHistoryFlg__c;
                    	// 2019/03/29 店舗付属情報返却追加 WSQ END
                        // 2019/04/10 EXPOのHR機能対応（3.1. 商品情報取得） WSQ BEGIN
                        item.ShopPhone = sp.Phone__c;
                        item.ShopMail = sp.Email__c;
                        // 2019/04/10 EXPOのHR機能対応（3.1. 商品情報取得） WSQ END
                    	if (shopLogoIdMap.containsKey(sp.Id)) {
                    		id accId = shopLogoIdMap.get(sp.Id);
                    		if (logomap.containsKey(accId)) {
                    			item.ShopLogo = logomap.get(accId);
                    		}
                    	}
                    	shopItemLst.add(item.toXml());
                    }
System.debug(logginglevel.info, 'shopItemLst='+shopItemLst);
                }
            } else {
            	// 2019/03/29 EXPO注文の際に、店舗定義なし（一つ店舗のみ）場合、注文通知を行わない不具合改修 WSQ BEGIN
            	// ロゴ情報格納
            	List<ReportLogo__c> repLst = new List<ReportLogo__c>();
            	// 店舗コードを空白で引き渡す場合、デフォルトのロゴ情報を取得する
            	if (req.shopcodes.isEmpty()) {
            		ShopInformation__c orgShop = getOrgShopInfo();
            		ReportLogo__c repLogo = CommRepUtils.getReplogoInfoByTypeId(CommRepUtils.REP_TYPE.LOGO_00_SYSDEF);
            		repLogo.ShopInfoRef__r = orgShop;
            		repLst.add(repLogo);
            	} else {
            	// 2019/03/29 EXPO注文の際に、店舗定義なし（一つ店舗のみ）場合、注文通知を行わない不具合改修 WSQ END
					repLst =[select id, ReportLogo__c,
										ShopInfoRef__r.Name,
										ShopInfoRef__r.ShopCode__c
										// 2018/12/05 BUG修正 WGCH END
										// 2019/03/29 店舗付属情報返却追加 WSQ BEGIN
										,ShopInfoRef__r.WebSite__c
										,ShopInfoRef__r.ExpoIsOpenBuyHistoryFlg__c
										// 2019/03/29 店舗付属情報返却追加 WSQ END
					                    // 2019/04/10 EXPOのHR機能対応（3.1. 商品情報取得） WSQ BEGIN
					                    ,ShopInfoRef__r.Phone__c,ShopInfoRef__r.Email__c
					                    // 2019/04/10 EXPOのHR機能対応（3.1. 商品情報取得） WSQ END	
									from ReportLogo__c
									where ShopInfoRef__r.ShopCode__c in :req.shopcodes];
            	}
				for (ReportLogo__c rep : repLst) {
                	MasterShopInfoItem item = new MasterShopInfoItem();
                	item.ShopCode = rep.ShopInfoRef__r.ShopCode__c;
                	item.ShopName = rep.ShopInfoRef__r.name;
                	// 2019/03/29 店舗付属情報返却追加 WSQ BEGIN
                	item.ShopSiteUrl = rep.ShopInfoRef__r.WebSite__c;
                	item.IsOpenBuyHistoryFlg = rep.ShopInfoRef__r.ExpoIsOpenBuyHistoryFlg__c;
                	// 2019/03/29 店舗付属情報返却追加 WSQ END
                    // 2019/04/10 EXPOのHR機能対応（3.1. 商品情報取得） WSQ BEGIN
                    item.ShopPhone = rep.ShopInfoRef__r.Phone__c;
                    item.ShopMail = rep.ShopInfoRef__r.Email__c;
                    // 2019/04/10 EXPOのHR機能対応（3.1. 商品情報取得） WSQ END
                	item.ShopLogo = CommRepUtils.convertLogoToBase64(rep.ReportLogo__c,null);
                	shopItemLst.add(item.toXml());
				}
            }
            shopInfoXml = '<ShopInfoList>'+String.join(shopItemLst, '')+'</ShopInfoList>';
        } catch (CommException ex) {
            // 予想以外の異常が発生する場合
            ret = new WS_ResultInfo('E0304',ex.getMessage());
        } catch (Exception e) {
            // 予想以外の異常が発生する場合
System.debug(logginglevel.info, 'EXCEPTION[1]='+e.getMessage());
System.debug(logginglevel.info, 'EXCEPTION[2]='+e.getStackTraceString());

            ret = new WS_ResultInfo('E9999',MSG_E9999);
            log.write_error(e.getStackTraceString());
            log.write_error(e.getMessage());
        }
        
        // 返却テンプレートXML
        String rsXmltemp = '<GetMasterInfoRS><CommonResponse>$$_CommonResponse_$$</CommonResponse>$$_ShopInfo_$$</GetMasterInfoRS>';
        return rsXmltemp.replace('$$_CommonResponse_$$',ret.toXml())
                        .replace('$$_ShopInfo_$$',shopInfoXml);
    }

    class MasterShopInfoReq {
        public MasterShopInfoReq(Dom.XmlNode root) {
            // 抽出条件
            Dom.XmlNode extrField = root.getChildElement('ExtractionCondition', null);
            if (extrField != null) {
                organizationId = getChildElementByName(extrField, 'OrganizationId');
                shopcodes = new List<String>();
                String wkShopCodes = getChildElementByName(extrField, 'ShopCodes');
                if (!CommUtils.isBlank(wkShopCodes)) {
                    for (String c : wkShopCodes.split(',')) {
                        if (CommUtils.isBlank(c)) continue;
                        shopcodes.add(c);
                    } 
                }
            }
        }
        String organizationId{get;set;}//組織ID
        List<String> shopcodes{get;set;}//店舗コード
        public Boolean validata(Boolean isExpoSite) {
        	// 2019/03/29 isExpoSite(NoneExpoの場合)、店舗コードは必ず引き渡すが必要
            //if (CommUtils.isBlank(organizationId) || shopcodes.isEmpty()) {
            if (CommUtils.isBlank(organizationId) || (shopcodes.isEmpty() && isExpoSite)) {
                throw new CommException(MSG_E0001);
            }
            return true;
        }
    }
    class MasterShopInfoItem {
        public String ShopCode{get;set;}//店舗コード
        public String ShopName{get;set;}//店舗名
        public String ShopLogo{get;set;}//店舗ロゴ
        // 2019/03/29 店舗付属情報返却追加 WSQ BEGIN
        public String ShopSiteUrl{get;set;}//店舗WebSite
        public Boolean IsOpenBuyHistoryFlg{get;set;}//店舗購入履歴公開フラグ
        // 2019/03/29 店舗付属情報返却追加 WSQ END
        // 2019/04/10 EXPOのHR機能対応（3.1. 商品情報取得） WSQ BEGIN
        public String ShopPhone{get;set;}//店舗電話
        public String ShopMail{get;set;}//店舗メール
        // 2019/04/10 EXPOのHR機能対応（3.1. 商品情報取得） WSQ END
        public String toXml() {
            String xml = '<ShopInfo>$_ShopInfoBody_$</ShopInfo>';
            String xmlBody = '';
            xmlBody+=joinTagXml('ShopCode',ShopCode);
            xmlBody+=joinTagXml('ShopName',ShopName);
            xmlBody+=joinTagXml('ShopLogo',ShopLogo);
            // 2019/03/29 店舗付属情報返却追加 WSQ BEGIN
            xmlBody+=joinTagXml('ShopSiteUrl',ShopSiteUrl);
            xmlBody+=joinTagXml('IsOpenBuyHistoryFlg',((IsOpenBuyHistoryFlg == true) ? '1' : '0'));
            // 2019/03/29 店舗付属情報返却追加 WSQ 
            // 2019/04/10 EXPOのHR機能対応（3.1. 商品情報取得） WSQ BEGIN
            xmlBody+=joinTagXml('ShopPhone',ShopPhone);
            xmlBody+=joinTagXml('ShopMail',ShopMail);
            // 2019/04/10 EXPOのHR機能対応（3.1. 商品情報取得） WSQ END
            return xml.replace('$_ShopInfoBody_$',xmlBody);
        }
    }
    class MasterBuyerReq {
        public MasterBuyerReq(Dom.XmlNode root) {
            // 抽出条件
            Dom.XmlNode extrField = root.getChildElement('ExtractionCondition', null);
            if (extrField != null) {
                uiProduct = getChildElementByName(extrField, 'ProductCode');
                // UIの会計商品コード→SFの会計商品コードに変換する
                String[] wkProduct = uiProduct.split('-');
                sfProduct =  CommUtils.nullToBlank(wkProduct.size() > 1 ? wkProduct[1] : wkProduct[0]);
            }
        }
        String uiProduct{get;set;}
        String sfProduct{get;set;}
        public Boolean validata() {
            if (CommUtils.isBlank(uiProduct)) {
                throw new CommException(MSG_E0001);
            }
            return true;
        }
    }
    class MasterBuyerItem {
        public String PurDate{get;set;}//購入日時
        public String PurUserId{get;set;}//購入者ユーザID
        public String PurUserName{get;set;}//購入者ユーザ名[AWS経由で作成]
        public String PurShopCode{get;set;}//購入者店舗コード[AWS経由で作成]
        public String PurShopName{get;set;}//購入者店舗名[AWS経由で作成]
        public String toXml() {
            String xml = '<PurUserHistory>$_BuyerInfoBody_$</PurUserHistory>';
            String xmlBody = '';
            xmlBody+=joinTagXml('PurDate',PurDate);
            xmlBody+=joinTagXml('PurUserId',PurUserId);
            xmlBody+=joinTagXml('PurUserName',PurUserName,true);
            xmlBody+=joinTagXml('ShopCode',PurShopCode,true);
            xmlBody+=joinTagXml('ShopName',PurShopName,true);
            return xml.replace('$_BuyerInfoBody_$',xmlBody);
        }
    }

    private static List<String> getProdMasterInfoComm(MasterProdReq req, XmlProductRest res) {
        //integer a = 10/0;
        List<String> xmlRs = new List<String>();
        // 指定条件により、商品情報を取得する
        List<String> plusInfLst = new List<String>();
        plusInfLst.add('ExpoWorkerRef__r.LastName');
        plusInfLst.add('ExpoWorkerRef__r.FirstName');
        plusInfLst.add('ExpoWorkerRef__r.CompanyName');
        plusInfLst.add('ExpoWorkerRef__r.Title');
        plusInfLst.add('ShopInfoRef__r.Name');
        plusInfLst.add('ShopInfoRef__r.ShopCode__c');
        // 2018/01/09 商品属性情報を引き渡す対応 BEGIN
        plusInfLst.add('(Select Id,Name,Field5Cal__c From AccountMasterPropRef__r Order By Id)');
        // 2018/01/09 商品属性情報を引き渡す対応 END
        // 2018/01/11 商品手数料情報を引き渡す対応 BEGIN
        plusInfLst.add('(Select Id,Charge__c,MemberType__c From AccountMasterChargeRef__r Order By Name)');
        // 2018/01/11 商品手数料情報を引き渡す対応 END
        // 2018/08/09 在庫情報を返却 WSQ BEGIN
        plusInfLst.add('(Select LogicQtyOfStock__c From StockProductRef__r)');
        // 2018/08/09 在庫情報を返却 WSQ END
        // 検索の項目SQLを取得する
        String queryFieldstr = CommSqlUtils.generateQueryString('AccountMaster__c',plusInfLst);
        // ****** 検索条件設定 *******
        String queryWhere = ' Where IsClosed__c != true And DisplayDate__c != null ';  
        // JOBID存在するがどうかチェック、存在無ければ、新規UUIDを設定する、存在すると、該当UUIDから管理情報と該当管理IDを比較して、最後格納した商品IDを取得して、次の商品情報を返却する
        Id nextProdId = null;
        if (!CommUtils.isBlank(req.JobId)) {
            nextProdId = getLastProdId(req.JobId);
            if (!CommUtils.isBlank(nextProdId)) {
                queryWhere += ' And Id > :nextProdId ';
            }
        }
        // 2018/09/12 EXPOのSITE機能対応 BEGIN
        String subOrgId = commReq.subOrgId;
        if (commReq.isExpoSite()) {
        	queryWhere += ' And ExpoOrgInfoRef__c = :subOrgId ';
        }
        // 2018/09/12 EXPOのSITE機能対応 END
        // 指定商品コードの場合
        List<String> reqProducts = req.ProductCodes;
        if (!reqProducts.isEmpty()) queryWhere += ' And Field3__c in :reqProducts ';
        // カテゴリ
        String reqCategory = req.Category;
        if (!CommUtils.isBlank(reqCategory)) {
            queryWhere += ' And Category__c = :reqCategory ';
        }
        // SUBカテゴリ
        String reqCategorySub = req.CategorySub;
        if (!CommUtils.isBlank(reqCategorySub)) {
            queryWhere += ' And CategorySub__c = :reqCategorySub ';
        }
        // 商品価額FROM(単価税抜）
        Decimal priceFrom = null;
        if (!CommUtils.isBlank(req.PriceDurationFrom)) {
            priceFrom = CommUtils.nullToZero(req.PriceDurationFrom);
            queryWhere += ' And SalesnoneTax__c >= :priceFrom ';
        }                       
        // 商品価額TO(単価税抜）    
        Decimal priceTo = null;
        if (!CommUtils.isBlank(req.PriceDurationTo)) {
            priceTo = CommUtils.nullToZero(req.PriceDurationTo);
            queryWhere += ' And SalesnoneTax__c <= :priceTo ';
        }                                         
        // 商品出品日FROM(YYYYMMDD)  
        Date disFrom = null;
        if (!CommUtils.isBlank(req.DisplayDurationFrom)) {
            disFrom = CommUtils.stringToDate(req.DisplayDurationFrom);
            if (disFrom != null) queryWhere += ' And DisplayDate__c >= :disFrom ';
        }                     
        // 商品出品日TO(YYYYMMDD)   
        Date disTo = null;
        if (!CommUtils.isBlank(req.DisplayDurationTo)) {
            disTo = CommUtils.stringToDate(req.DisplayDurationTo);
            if (disTo != null) queryWhere += ' And DisplayDate__c <= :disTo ';
        }                                        
        // ****** 検索ORDER設定 *******
        String queryOrder = ' order by createddate,Id limit '+ (BAT_SIZE + 1);   
//System.debug(loggingLevel.info, 'SQL='+(queryFieldstr + queryWhere + queryOrder));
        // 検索処理を行う
        List<AccountMaster__c> rs = DataBase.query(queryFieldstr + queryWhere + queryOrder);
        // 100件以上が存在する場合
        if (res != null) {
            if (rs.size() > BAT_SIZE) {
                // 次のページに設定する
                res.NextPageProductCodes = getExpoCode(rs[BAT_SIZE].Field3__c);
            } else {
                res.NextPageProductCodes = null;
            }
            // JOBのIDを設定処理
            if (CommUtils.isBlank(req.JobId)) {
                // 新規JOBIDを発行する
                res.JobId = CommUtils.getGUID();
                // 管理データを作成する
            } else {
                res.JobId = req.JobId;
            }
            // 会計商品コードを指定される場合、JOBIDは返却なし
            if (!reqProducts.isEmpty()) {
                res.JobId = null;
            }
        }
        // 最大処理回数
        Integer loopsize = rs.size() > BAT_SIZE ? BAT_SIZE : rs.size();
        // 該当システムの単価定義区分により、税込金額を計算する
        // 2018/08/09 在庫情報を返却 WSQ BEGIN
        CommUtils.ProductInfo priceInfo = null;
        CommUtils.ProductInfo defPriceInfo = new CommUtils.ProductInfo();
        //CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo();
        // 2019/04/10 EXPOのHR機能対応 WSQ BEGIN
        set<id> hrAttrInfSet = new set<id>();
        set<id> hrWorkerId = new set<id>();//人材業者
        // 2019/04/10 EXPOのHR機能対応 WSQ END
        // 2018/08/09 在庫情報を返却 WSQ BEGIN
        Set<Id> expoOrgIdSet = new Set<Id>();
        for (Integer i = 0; i < loopsize; i++) {
            AccountMaster__c r = rs[i];
            if (!CommUtils.isBlank(r.ExpoOrgInfoRef__c)) expoOrgIdSet.add(r.ExpoOrgInfoRef__c);
            // 2019/04/10 EXPOのHR機能対応 WSQ BEGIN
            // 人材情報を設定されるバア、人材情報IDを格納する
            if (!CommUtils.isBlank(r.ExpoHrInfoRef__c)) hrAttrInfSet.add(r.ExpoHrInfoRef__c);   
            if (!CommUtils.isBlank(r.ExpoWorkerRef__c)) hrWorkerId.add(r.ExpoWorkerRef__c);
            // 2019/04/10 EXPOのHR機能対応 WSQ END
        }
	// 2019/04/10 EXPOのHR機能対応 WSQ BEGIN
        // 人材業者のIDにより、既存タスク情報を取得する「リクエストから1年間データを取得する」
		Date begDt = Date.today();
		Date endDt = begDt.addYears(1);
		map<id, list<String>> hrEventMap = new map<id, list<String>>();
		for (Event ev : [select id,OwnerId,Subject,StartDateTime,EndDateTime,EndDateTime__c from Event where OwnerId =:hrWorkerId 
			//and ActivityDate >= :begDt and ActivityDate <= :endDt
			and (EndDateTime__c >= :begDt or EndDateTime >= :begDt ) and StartDateTime <= :endDt
			]) {
			// 
			EventInfo event = new EventInfo();
			event.title = ev.Subject;
			event.begDt = ev.StartDateTime.format('yyyy-MM-dd');
            Datetime endDtime = ev.EndDateTime__c == null ? ev.EndDateTime : ev.EndDateTime__c;
			event.endDt = endDtime.format('yyyy-MM-dd');
			
			if (!hrEventMap.containsKey(ev.OwnerId)) hrEventMap.put(ev.OwnerId,new list<String>());
			hrEventMap.get(ev.OwnerId).add(JSON.serialize(event));
		}
//log.write_log('r.hrEventMap[1]：'+hrEventMap);
        // システム日から未来1年間のマルチタスク情報を取得する
        
        // 2019/04/10 EXPOのHR機能対応 WSQ BEGIN
        // 人材情報<人材情報id,人材情報>
        map<id,ExpoHrInfo__c> hrAttrInfMap = new map<id, ExpoHrInfo__c>();
        if (!hrAttrInfSet.isEmpty()) {
            String queryHrHeader = CommSqlUtils.generateQueryString('ExpoHrInfo__c');
            String queryHrStr = queryHrHeader + ' where id in:hrAttrInfSet ';
            List<ExpoHrInfo__c> rsLst = Database.query(queryHrStr);
            for (ExpoHrInfo__c hr : rsLst) hrAttrInfMap.put(hr.id, hr);
        }
        // 2019/04/10 EXPOのHR機能対応 WSQ END
        // 各組織の単価定義区分と端数処理区分を取得する
        // 該当組織の金額計算ツール初期化
        map<id, CommUtils.ProductInfo> processUtilMap = new map<Id, CommUtils.ProductInfo>();
        if (!expoOrgIdSet.isEmpty()) {
        	map<Id,ExpoOrgInfo__c> expoOrgMaps = new map<Id, ExpoOrgInfo__c>([select UnitPriceDefKb__c from ExpoOrgInfo__c where id =:expoOrgIdSet]);
        	for (ExpoOrgInfo__c e : expoOrgMaps.values()) {
        		// 単価定義区分 空白の場合、共通定義値により、自動設定する
        		if (CommUtils.isBlank(e.UnitPriceDefKb__c)) e.UnitPriceDefKb__c = CommUtils.nullToBlank(CommConst.APPOPTION_UTP_DEF_KB);
        	}
        	for (Id orgId : expoOrgMaps.keySet()) {
        		// 単価定義区分
        		Integer priceKbn = CommUtils.nullToIntZero(expoOrgMaps.get(orgId).UnitPriceDefKb__c);
        		CommUtils.ProductInfo wkPriceInfo = new CommUtils.ProductInfo(priceKbn);
        		processUtilMap.put(orgId, wkPriceInfo);
        	}
        }
        // 2018/08/09 在庫情報を返却 WSQ END
        // 2019/03/29 EXPO注文の際に、店舗定義なし（一つ店舗のみ）場合、注文通知を行わない不具合改修 WSQ BEGIN
        // EXPOの場合、店舗設定されているが調べる
        ShopInformation__c orgShop = getOrgShopInfo();
        // 2019/03/29 EXPO注文の際に、店舗定義なし（一つ店舗のみ）場合、注文通知を行わない不具合改修 WSQ END
        // 返却のXML情報を作成する
        for (Integer i = 0; i < loopsize; i++) {
            AccountMaster__c r = rs[i];
            // 2018/08/09 在庫情報を返却 WSQ BEGIN
            Id expoOrgId = r.ExpoOrgInfoRef__c;
            if (!CommUtils.isBlank(expoOrgId) && processUtilMap.containsKey(expoOrgId)) priceInfo = processUtilMap.get(expoOrgId);
            else priceInfo = defPriceInfo;
            // 2018/08/09 在庫情報を返却 WSQ END
            XmlProductInfo inf = new XmlProductInfo();
            inf.ProductCode = getExpoCode(r.Field3__c);    // 商品コード 
            inf.ProductName = r.Name;  // 商品名
            // 2018/01/09 商品属性情報を引き渡す対応 BEGIN
            //inf.ProductSubCode = r.ProductSubCode__c;  // サブ商品コード 
            for (AccountMasterProp__c prop : r.AccountMasterPropRef__r) {
                ProductSub sub = new ProductSub();
                sub.ProductSubCode = prop.id;
                sub.PropName = prop.name;
                // 単価計算する
                Decimal orgPrice = CommUtils.nullToZero(prop.Field5Cal__c);
                priceInfo.process(orgPrice, 1, (CommUtils.nullToZero(r.TaxRateCal__c) / 1), (CommUtils.nullToZero(r.ServiceRate__c) / 1));
                sub.Price = CommUtils.nullToBlank(priceInfo.priceIncTax);
                sub.PriceNoTax = CommUtils.nullToBlank(priceInfo.priceExcTax);
                // 在庫情報 !!!! DEMODATA !!!!
                sub.StockCount = CommUtils.nullToBlank(Integer.valueof(10/r.AccountMasterPropRef__r.size()));
                inf.ProductSubs.add(sub);
            }
            // 2018/01/09 商品属性情報を引き渡す対応 END
            // 単価金額（税込） 
            priceInfo.process(CommUtils.nullToZero(r.Field5__c), 1, (CommUtils.nullToZero(r.TaxRateCal__c) / 1), (CommUtils.nullToZero(r.ServiceRate__c) / 1));
            inf.Price = CommUtils.nullToBlank(priceInfo.priceIncTax);
//System.debug(loggingLevel.info, 'inf.Price='+inf.Price);
//System.debug(loggingLevel.info, 'inf.PriceNoTax='+(r.SalesnoneTax__c));
            // 単価金額（税抜）
            // 2018/01/09 商品属性情報を引き渡す対応 BEGIN
            //inf.PriceNoTax = CommUtils.nullToBlank(r.SalesnoneTax__c);
            inf.PriceNoTax = CommUtils.nullToBlank(priceInfo.unitPriceIncServiceExcTax);
            // 2018/01/09 商品属性情報を引き渡す対応 END
            // 商品簡易説明
            inf.SimpleDescription = r.SpDescription__c;
            // 商品説明
            inf.Description = r.Description__c;
            // 内容量
            inf.Content = r.Content__c;
            inf.Material=r.Material__c;// 原材料
            inf.Maker=r.Maker__c;//メーカー名
            inf.Origin=r.Origin__c;// 原産国名
            inf.BestDateInfo=r.BestDateInfo__c;// 賞味期限
            inf.SpecialMemo=r.SpecialMemo__c;// 注意事項
            if (r.DisplayDate__c != null) {
                inf.DisplayDate=getDateString(r.DisplayDate__c);// 出品日
            }
            inf.Category=r.Category__c;// カテゴリ
            inf.CategorySub=r.CategorySub__c;// カテゴリサブ
            //inf.PictureNo=r.PictureNo__c;// 商品画像番号
            //inf.PictureUrl=r.PictureUrl__c;// 商品画像URL
            inf.PurchaseMaxNum=CommUtils.nullToblank(r.PurchaseMaxNum__c);// 個人最大購買数量
            inf.Charge=CommUtils.nullToBlank(r.Charge__c);// 手数料
            // 2018/01/11 商品手数料情報を引き渡す対応 BEGIN
            for (AccountMasterCharge__c chg : r.AccountMasterChargeRef__r) {
                ChargeSub sub = new ChargeSub();
                sub.MemberType =  CommUtils.nullToBlank(chg.MemberType__c);// 会員種別
                sub.Charge = CommUtils.nullToBlank(chg.Charge__c);// 手数料%
                if (CommUtils.isBlank(sub.MemberType) || CommUtils.isBlank(sub.Charge)) continue;
                inf.ChargeSubs.add(sub);
            }
            // 2018/01/11 商品手数料情報を引き渡す対応 END
            // 店舗情報
            if (r.ShopInfoRef__c != null) {
                inf.ShopCode=r.ShopInfoRef__r.ShopCode__c;// 店舗コード
                inf.ShopName=r.ShopInfoRef__r.Name;// 店舗名
            }
            // 2019/03/29 EXPO注文の際に、店舗定義なし（一つ店舗のみ）場合、注文通知を行わない不具合改修 WSQ BEGIN
            else {
            	inf.ShopCode=orgShop.ShopCode__c;
            	inf.ShopName=orgShop.Name;
            }
            // 2019/03/29 EXPO注文の際に、店舗定義なし（一つ店舗のみ）場合、注文通知を行わない不具合改修 WSQ END
            inf.OrganizationId=ORGID;// 施設組織ID
            // 在庫情報 !!!! DEMODATA !!!!
            // DemoData作成
            // TODO
            // ==================================================================
            inf.StockCount='0';// 在庫情報
            // ==================================================================
            // 2018/08/09 在庫情報を返却 WSQ BEGIN
            // EXPO組織情報が存在する場合、NOEXPOの意味、会計商品の「EXPO在庫数」から返却する
            if (!CommUtils.isBlank(r.ExpoOrgInfoRef__c)) inf.StockCount = CommUtils.nullToBlank(CommUtils.nullToBlank(r.ExpoStockCount__c));
			else {
	            inf.StockCount = CommUtils.nullToBlank(0);
				if (!r.StockProductRef__r.isEmpty()) {
					inf.StockCount = CommUtils.nullToBlank(CommUtils.nullToBlank(r.StockProductRef__r[0].LogicQtyOfStock__c));
				}
			}
            // 2018/08/09 在庫情報を返却 WSQ END
            // カテゴリが人材、業者、陣屋コネクト場合、在庫固定1を返却する WSQ BEGIN
            // 人材などは在庫管理じゃなく、サビースため、在庫は１で、AWSのUI在庫数ある制限対応ため、固定１を返却する
            if (inf.Category == '人材' || inf.Category == '業者・サービス' || inf.Category == '陣屋コネクト') inf.StockCount = '1';
            // カテゴリが人材、業者、陣屋コネクト場合、在庫固定1を返却する WSQ END
            inf.StockUnit=r.StockUnit__c;// 販売単位
            inf.SalesStatus=(r.SalesStatus__c == '販売中' ? '1' : (r.SalesStatus__c == '停止中' ? '2' : ''));// 販売状態
            // 定期購入情報
            inf.RepeaterFlg=(r.RepeaterFlg__c ? '1':'');// 定期購入フラグ
            inf.DiscountType=(r.DiscountType__c == '値引' ? '1' : (r.DiscountType__c == '割引'  ? '2' : ''));// キャンペーン方式
            inf.DiscountPrice=CommUtils.nullToBlank(r.RepeatDiscountPrice__c);// 価格の値引き
            inf.DiscountRate=CommUtils.nullToBlank(r.RepeatDiscountRate__c);// 価格の割引（パーセンテージ）
            // 絞込み条件
            inf.LimitedFlg=(r.LimitedFlg__c ? '1':'');// 期間限定フラグ
            inf.ProductStatus= (r.ProductStatus__c == '中古' ? '1' : (r.ProductStatus__c == '新品' ? '0' : ''));// 商品状態（新品/中古）
            inf.OutsourceFlg=(r.OutsourceFlg__c ? '1':'');// 業務委託フラグ
            inf.GoodFlg=(r.GoodFlg__c ? '1':'');// おすすめフラグ
            // 2018/02/04 パラメータ追加対応
            inf.ExhibitType = r.ExhibitType__c;//出品区分
            inf.RentalFlg = (r.RentalFlg__c ? '1':'');// レンタルフラグ
            // 配送方法
            if (!CommUtils.isBlank(r.DeliveryType__c)) {
                String[] types = CommUtils.nullToBlank(r.DeliveryType__c).split(';');
                inf.DeliveryType= String.join(types,',');
            }
            // ***************** 人材情報 *****************
            inf.CompnayName=r.CompnayName__c;// 社名
            if (!CommUtils.isBlank(r.ExpoWorkerRef__c) && CommUtils.isBlank(inf.CompnayName)) {
                inf.CompnayName= CommUtils.nullToBlank(r.ExpoWorkerRef__r.CompanyName);
            }
            inf.StaffName=r.StaffName__c;// 名前
            if (!CommUtils.isBlank(r.ExpoWorkerRef__c) && CommUtils.isBlank(inf.StaffName)) {
                inf.StaffName= CommUtils.nullToBlank(r.ExpoWorkerRef__r.LastName) + ' ' + CommUtils.nullToBlank(r.ExpoWorkerRef__r.FirstName);
            }
            inf.WorkRole=r.WorkRole__c;// 役割
            if (!CommUtils.isBlank(r.ExpoWorkerRef__c) && CommUtils.isBlank(inf.WorkRole)) {
                inf.WorkRole= CommUtils.nullToBlank(r.ExpoWorkerRef__r.Title);
            }
            // 2019/04/10 EXPOのHR機能対応 WSQ BEGIN(一時廃止)
            //inf.Certificate=r.Certificate__c;// 免許、資格
            //inf.WorkCondition=r.WorkCondition__c;// 勤務条件
            //inf.WorkAddress=r.WorkAddress__c;// 勤務地
            //項目設定により、地域設定を行う
            //UI側引き渡す場合、市コードの前方２桁は削除、UI側に送付する
            if (!CommUtils.isBlank(r.ExpoAreaMstCode__c)) {
            	String[] sr = CommUtils.nullToBlank(r.ExpoAreaMstCode__c).split(';');
            	List<String> cvtLst = new List<String>();
            	for (String code : sr) {
            		list<String> cdArr = code.split('_');
            		if (cdArr.size() > 2) {
            			cdArr[2] = cdArr[2].substring(2);
            			cvtLst.add(String.join(cdArr,'_'));
            		} else {
            			cvtLst.add(code);
            		}
            	}
            	inf.WorkAddress = String.join(cvtLst,';');
            }
            inf.WorkContent=r.WorkContent__c;// 仕事内容
            //inf.WorkContract=r.WorkContract__c;// 契約条件
            //inf.WorkPayType=(r.WorkPayType__c == '日給' ? '1' : (r.WorkPayType__c == '時給' ? '0' : ''));// 給料の支払い方式フラグ（日給/時給）
            //inf.WorkMinTime=CommUtils.nullToBlank(r.WorkMinTime__c);// 労働時間下限（時単位）
            // 2019/04/10 EXPOのHR機能対応 WSQ END
            //inf.WorkContractFilter=r.WorkContractFilter__c;// 契約可能日と契約可能時間帯（複数）
            // DemoData作成
            // TODO
            // 2019/04/10 EXPOのHR機能対応 WSQ BEGIN(一時廃止)
            /*
            // ==================================================================
            Date dt = Date.today();
            for (Integer j =0; j< 3; j++) {
                String wokFilter = getDateString(dt.addMonths(j));
                inf.WorkContractFilterList.add(wokFilter + ',' + '09:00-18:00');
            }
            // ==================================================================
            // 契約書内容
            inf.WorkContractFile=r.WorkContractFile__c;// 契約書内容
            // 業者情報
            // 単価の単位（一式／月／日）
            if (!CommUtils.isBlank(r.WorkUnitPriceType__c)) {
                if (r.WorkUnitPriceType__c == '一式')    inf.WorkUnitPriceType = '1';
                else if (r.WorkUnitPriceType__c == '月') inf.WorkUnitPriceType = '2';
                else if (r.WorkUnitPriceType__c == '日') inf.WorkUnitPriceType = '3';
            }
            // 契約可能日（期間範囲）
            if (r.WorkContractStartDt__c != null && r.WorkContractStartEt__c != null) {
                String s = DateTime.newInstance(r.WorkContractStartDt__c.year(),r.WorkContractStartDt__c.month(),r.WorkContractStartDt__c.day()).format('yyyyMMdd');
                String e = DateTime.newInstance(r.WorkContractStartEt__c.year(),r.WorkContractStartEt__c.month(),r.WorkContractStartEt__c.day()).format('yyyyMMdd');                    
                inf.WorkCanContractRange = s + '-' + e;
            }
            inf.WorkContractMixTerm=CommUtils.nullToBlank(r.WorkContractMixTerm__c);// 最小契約期間（月単位）
            inf.WorkContractMaxTerm=CommUtils.nullToBlank(r.WorkContractMaxTerm__c);// 最大契約期間（月単位）
            */ 
            // 2019/04/10 EXPOのHR機能対応 WSQ END(一時廃止) 
            // 2019/04/10 EXPOのHR機能対応 WSQ BEGIN
            // 人材情報を設定する
            Id hrId = r.ExpoHrInfoRef__c;
            if (!CommUtils.isBlank(hrId) && hrAttrInfMap.containsKey(hrId)) {
                ExpoHrInfo__c hr = hrAttrInfMap.get(hrId);
                inf.DispatchScope = CommUtils.nullToBlank(hr.ExpoDispatchScopeLst__c); // 人材派遣期間
                inf.WeekWorkDays = CommUtils.nullToBlank(hr.ExpoWeekWorkDaysLst__c); // 人材勤務日数
                inf.DayWorkBeginTime = CommUtils.nullToBlank(hr.ExpoDayWorkBegTimeLst__c); // 人材始業時間
                inf.DayWorkEndTime = CommUtils.nullToBlank(hr.ExpoDayWorkEndTimeLst__c); // 人材終業時間
                inf.OvertimeWorkHour = CommUtils.nullToBlank(hr.ExpoOvertimeWorkHourLst__c); // 人材残業時間
                inf.OaSkills = CommUtils.nullToBlank(hr.ExpoOaSkillLst__c); // 人材OAスキル
                inf.EnglishSkills = CommUtils.nullToBlank(hr.ExpoEngSkillLst__c); // 人材英語スキル
                inf.OtherLanguagesSkills = CommUtils.nullToBlank(hr.ExpoOthLangSkillLst__c); // 人材その他語学スキル
                inf.AccountingSkills = CommUtils.nullToBlank(hr.ExpoAccSkillLst__c); // 人材経理スキル
                inf.LicenseQualification = CommUtils.nullToBlank(hr.ExpoLicSkillLst__c); // 人材免許・資格
                inf.OtherComplaints = CommUtils.nullToBlank(hr.ExpoHrOtherLst__c); // 人材こだわり条件その他
                inf.ExpoMinPay = CommUtils.nullToBlank(hr.ExpoMinPayLst__c); // 給料（下限）
                inf.ExpoMaxPay = CommUtils.nullToBlank(hr.ExpoMaxPayLst__c); // 給料（上限）
                inf.WorkPayType = CommUtils.nullToBlank(hr.WorkPayType__c);// 給料の支払い方式フラグ（日給/時給）
            }
//log.write_log('r.ExpoWorkerRef__c)：'+r.ExpoWorkerRef__c);
//log.write_log('r.hrEventMap：'+hrEventMap);
            if (!CommUtils.isBlank(r.ExpoWorkerRef__c) && hrEventMap.containsKey(r.ExpoWorkerRef__c)) {
            	// 作業時間情報をXMLタグに設定する
//log.write_log('r.hrEventMap[3]：'+hrEventMap.get(r.ExpoWorkerRef__c));
				list<String> events = hrEventMap.get(r.ExpoWorkerRef__c);
            	inf.WorkAssignEvents = '['+String.join(events,',')+']';
            }
            // 2019/04/10 EXPOのHR機能対応 WSQ END
            // 変更のXMLを作成する
            xmlRs.add(inf.toXml());
        }
        // 最後取得の商品ID情報を格納する
        //if (res.NextPageProductCodes != null) {
        if (res != null && res.NextPageProductCodes != null) {
           setLastProdId(res.JobId, rs[loopsize-1].Id);
        }
        return xmlRs;
    }
    /**
    * 5.1.注文確定
    **/
    /* 呼び出すサンプル
<OrderInfoRQ>
        <CommonRequest>
            <majorno>3</majorno>
            <minorno>1</minorno>
        </CommonRequest>
        <OrderInfoList>
            <UserId>00Dp00000000hip-00510000001wl0B</UserId>
            <OrderAmountIncTax>7787</OrderAmountIncTax>
            <OrderNo>12991000011012991</OrderNo>
            <OrderSetInfo>
                <ShopCode>01</ShopCode>
                <OrganizationId>00Dp00000000hipEAA</OrganizationId>
                <OrderSetInfoItem>
                    <ProductCode>00Dp00000000hipEAA-6001</ProductCode>
                    <ProductSubCode>a1Xp0000000YOidEAG</ProductSubCode>
                </OrderSetInfoItem>
            </OrderSetInfo>
        </OrderInfoList>
</OrderInfoRQ>
    */
    @TestVisible private static string setOrderinfo(Dom.XMLNode rootNode) {
        // 処理結果情報を格納する
        WS_ResultInfo ret = new WS_ResultInfo();
        // 返却結果を格納する
        List<String> xmlRs = new List<String>();
        // DB情報SAVEPOINT
        Savepoint sp = Database.setSavepoint();
        // 2018/05/01 梱包セット識別情報追加（DBへ反映しない、RELAY-SERVERやり取り用 BEGIN
        // Request結果情報を格納する
        String orderInfoStr = '';
        String orderInfoXml = '<OrderInfoList><OrderNo>$$_OrderNo_$$</OrderNo>$$_OrderSetInfo_$$</OrderInfoList>';
        String orderSetInfoXml = '<OrderSetInfo><OrderSetCode>$$_OrderSetCode_$$</OrderSetCode></OrderSetInfo>';
        // 2018/05/01 梱包セット識別情報追加（DBへ反映しない、RELAY-SERVERやり取り用 END
        try {
        	// 引き渡すパラメータを解析する
	        OrderInfoReq req = new OrderInfoReq(rootNode);
            // 有効チェック
            req.validata();
	        // 梱包情報リスト情報を取得する
        	list<OrderSetInfo> orderSetLst = req.OrderSetInfoList;
        	// ==========================
        	// 注文情報を格納する
        	// ==========================
        	Order__c newParOrder = new Order__c();
        	// 購入者ID設定
        	newParOrder.OrderUserId__c = CommUtils.nullToblank(req.UserId);//ユーザID
        	newParOrder.OrderAmountIncTax__c = CommUtils.nullToZero(req.OrderAmountIncTax);//合計金額											
        	newParOrder.OrderNo__c = CommUtils.nullToblank(req.OrderNo);//注文番号
        	newParOrder.ShippingType__c = req.ShippingType;    // 店舗別の商品発送方法
        	if (CommUtils.isBlank(req.OrderNo)) {
        	    throw new CommException('注文番号が見つかりません');
        	} else {
                // 注文番号重複チェック
                List<Order__c> existOrds = [select id from Order__c where OrderNo__c = :newParOrder.OrderNo__c];
                if (!existOrds.isEmpty()) {
                    throw new CommException('注文番号が重複になりました['+ newParOrder.OrderNo__c +']');
                }
        	}        	
        	// 2018/05/01 梱包セット識別情報追加（DBへ反映しない、RELAY-SERVERやり取り用 BEGIN
        	String orderSetInfoStr = '';
        	// 2018/05/01 梱包セット識別情報追加（DBへ反映しない、RELAY-SERVERやり取り用 END
            // ==========================
            // 梱包毎の注文情報を作成する
            // ==========================
            Set<String> spcdSet = new Set<String>();// 商品コード情報
            Set<String> spsubcdSet = new Set<String>();// 商品SUBコード情報
            Set<String> shopCdSet = new Set<String>();// 店舗コード情報
            // 梱包単位情報を取得する
            Boolean isHaveSubOrder = false;
            // 商品コード、サブ商品コード、店舗コード放到set集合里
            for (OrderSetInfo sub : req.OrderSetInfoList) {
             	// 店舗情報
             	String locShopCd = CommUtils.nullToblank(sub.ShopCode);
             	// 店舗コード集合
             	if (!CommUtils.isBlank(locShopCd)) shopCdSet.add(locShopCd);
             	// 商品情報を格納する
             	for (OrderSetInfoItem orderItem : sub.OrderSetInfoItemList) {
                    // 商品コード
                    if (CommUtils.isBlank(orderItem.ProductCode)) continue;
                    // 商品コード格納
             		spcdSet.add(orderItem.ProductCode);
             		// 商品属性情報
             		String locProdSubCode = CommUtils.nullToblank(orderItem.ProductSubCode);
             		// サブ商品コード集合
             		if (!CommUtils.isBlank(locProdSubCode)) spsubcdSet.add(locProdSubCode);
             		// 実際会計商品存在場合
             		isHaveSubOrder = true;
             	}
             	// 2018/05/01 梱包セット識別情報追加（DBへ反映しない、RELAY-SERVERやり取り用 BEGIN
             	orderSetInfoStr += orderSetInfoXml.replace('$$_OrderSetCode_$$',sub.OrderSetCode);
             	// 2018/05/01 梱包セット識別情報追加（DBへ反映しない、RELAY-SERVERやり取り用 END
            }
            // 2018/05/01 梱包セット識別情報追加（DBへ反映しない、RELAY-SERVERやり取り用 BEGIN
            orderInfoStr = orderInfoXml
            				.replace('$$_OrderNo_$$',req.OrderNo)
            				.replace('$$_OrderSetInfo_$$',orderSetInfoStr);
            // 2018/05/01 梱包セット識別情報追加（DBへ反映しない、RELAY-SERVERやり取り用 END
            // 実際会計商品が存在しない
            if (!isHaveSubOrder) {
                throw new CommException('注文明細対象情報が見つかりません');
            }
            //通过商品code取得商品Id
            Map<String,id> accCodeToIdMap = new Map<String,id>();
            if (!spcdSet.isEmpty()) {
	            for (AccountMaster__c acc : [select Id,Field3__c from AccountMaster__c where Field3__c =:spcdSet]){
	            	accCodeToIdMap.put(acc.Field3__c,acc.id);
	            }
            }
            //通过サブ商品コード取得商品属性情報
            Map<String,AccountMasterProp__c> accSubCodeToIdMap = new Map<String,AccountMasterProp__c>();
            if (!spsubcdSet.isEmpty()) {
	            for (AccountMasterProp__c mas : [select Id,AccountMasterRef__r.Field3__c from AccountMasterProp__c where Id =:spsubcdSet]){
	            	accSubCodeToIdMap.put(mas.Id,mas);
	            }
            }
            // 店舗情報を取得する
            Map<String,ShopInformation__c> shopCodeToIdMap = new Map<String,ShopInformation__c>();
            if (!shopCdSet.isEmpty()) {
	            for (ShopInformation__c shop : [select Id,ShopCode__c,Name,ExpoOrgInfoRef__c from ShopInformation__c where ShopCode__c =:shopCdSet]){
	            	shopCodeToIdMap.put(shop.ShopCode__c,shop);
	            }
            }
            // 梱包情報を取得する
            // チェック処理を行う
            for (OrderSetInfo sub : req.OrderSetInfoList) {
                // 梱包単位の商品情報存在チェック
                for (OrderSetInfoItem orderItem : sub.OrderSetInfoItemList) {
                    // 商品コード
                    if (CommUtils.isBlank(orderItem.ProductCode)) continue;
                    if (!accCodeToIdMap.containsKey(orderItem.ProductCode)) {
                        throw new CommException('指定の商品が非存在する['+getExpoCode(orderItem.ProductCode)+']');
                    }
                    // サブ商品コード
                    if (!CommUtils.isBlank(orderItem.ProductSubCode)) {
                        orderItem.ProductSubCode = Id.ValueOf(orderItem.ProductSubCode);
                        if (!accSubCodeToIdMap.containsKey(orderItem.ProductSubCode)) {
                            throw new CommException('指定のサブ商品コードが非存在する['+String.valueOf(orderItem.ProductSubCode)+']');
                        } else {
                            AccountMasterProp__c prop = accSubCodeToIdMap.get(orderItem.ProductSubCode);
                            String productCode = prop.AccountMasterRef__r.Field3__c;
                            if (productCode != orderItem.ProductCode) {
                                throw new CommException('商品コード['+getExpoCode(orderItem.ProductCode)+']のサブ商品コードが非存在する['+String.valueOf(orderItem.ProductSubCode)+']');
                            }
                        }
                    }
                }
            }
            // 梱包単位の注文情報を格納する
            List<OrderSubUpdInfo> subOrderList = new List<OrderSubUpdInfo>();
            // 梱包明細情報処理を行う
            for (OrderSetInfo sub : req.OrderSetInfoList) {
                // 梱包情報構造格納初期化
                OrderSubUpdInfo orderSub = new OrderSubUpdInfo();
            	// 梱包毎の注文情報を作成する
            	Order__c newSubOrder = new Order__c();
            	// 店舗情報参照関係に変更が必要
            	String shopCode = CommUtils.nullToblank(sub.ShopCode);
                if (shopCodeToIdMap.containsKey(shopCode)) {
                	// 2018/09/12 EXPOのSITE機能対応 BEGIN
            		newSubOrder.ShopInfoRef__c = shopCodeToIdMap.get(shopCode).Id;
            		newSubOrder.ExpoOrgInfoRef__c = shopCodeToIdMap.get(shopCode).ExpoOrgInfoRef__c;
            		// 2018/09/12 EXPOのSITE機能対応 END
            	}
            	// 注文SUB番号情報設定する
                newSubOrder.OrderNo__c = CommUtils.nullToblank(req.OrderNo) + '_' + (CommUtils.paddingLeftZero(CommUtils.nullToBlank(subOrderList.size()),4));//注文番号		
                newSubOrder.SetDeliveryCharge__c = CommUtils.nullToZero(sub.SetDeliveryCharge);//配送料											
                newSubOrder.SetDeliveryDate__c = CommUtils.stringToDate(sub.SetDeliveryDate);   // 配送希望日     
				newSubOrder.SetDeliveryTime__c = CommUtils.nullToblank(sub.SetDeliveryTime);    // 配送希望時刻  
				newSubOrder.DeliveryType__c = CommUtils.nullToblank(sub.SetDeliveryType);    // 配送方法    
				newSubOrder.SetDeliveryAddress__c = CommUtils.nullToblank(sub.SetDeliveryAddress);   // 配送住所    
				newSubOrder.SetOrderTitle__c = CommUtils.nullToblank(sub.SetOrderTitle);// 配送先宛名   
				newSubOrder.SetAmountTax__c = CommUtils.nullToZero(sub.SetAmountTax);   // 消費税
				newSubOrder.SetAmount__c = CommUtils.nullToZero(sub.SetAmount); // 梱包毎合計金額(税込)
				newSubOrder.PayType__c = CommUtils.nullToblank(sub.PayType);    // 決済方式    
				newSubOrder.PayDetail__c = CommUtils.nullToblank(sub.PayDetail);// 決済詳細情報  
				newSubOrder.OrderUserId__c = CommUtils.nullToblank(req.UserId);    
				newSubOrder.OrderAmountIncTax__c = CommUtils.nullToZero(sub.SetAmount); 
                // 発送方法
                newSubOrder.ShippingType__c = req.ShippingType;
                // 梱包情報リストを格納する
                orderSub.subOrder = newSubOrder;
                // 梱包内の注文明細情報を格納する
                for (OrderSetInfoItem orderItem : sub.OrderSetInfoItemList) {
                    // 注文明細情報を格納する
                	OrderItem__c newOrderTran = new OrderItem__c();
	            	String productCode = CommUtils.nullToblank(orderItem.ProductCode);
	            	String productSubCode = CommUtils.nullToblank(orderItem.ProductSubCode);
	            	// 会計商品
	            	if (accCodeToIdMap.containsKey(productCode)) {
	            		newOrderTran.AccountMasterRef__c = accCodeToIdMap.get(productCode);
	            	}
	            	// 商品属性情報
	            	if (accSubCodeToIdMap.containsKey(productSubCode)) {
	            		newOrderTran.AccountMasterPropRef__c = accSubCodeToIdMap.get(productSubCode).Id;
	            	}
	            	newOrderTran.StockUnit__c = CommUtils.nullToblank(orderItem.StockUnit);  // 単位 
				    newOrderTran.Qty__c = CommUtils.nullToblank(orderItem.Qty);// 数量 
				    newOrderTran.PriceNoTax__c = CommUtils.nullToZero(orderItem.PriceNoTax);   // 単価金額（税抜）   
				    newOrderTran.Charge__c = CommUtils.nullToZero(orderItem.Charge);   // 手数料
				    newOrderTran.StaffPriceFlg__c = (CommUtils.nullToblank(orderItem.StaffPriceFlg) == '1' ? '人材ではない' :(CommUtils.nullToblank(orderItem.StaffPriceFlg) == '2' ? '時給' : (CommUtils.nullToblank(orderItem.StaffPriceFlg) == '3' ? '日給' : '')));  // 人材単価フラグ 
				    newOrderTran.RepeaterFlg__c = CommUtils.nullToblank(orderItem.RepeaterFlg)== '1' ? true : false ;  // 定期購入フラグ 
				    newOrderTran.RepeaterPayType__c = (CommUtils.nullToblank(orderItem.RepeaterPayType)== '1'? '年払' :(CommUtils.nullToblank(orderItem.RepeaterPayType)== '2'? '月払' :''));   // 定期払い方式  
				    newOrderTran.WorkContractStartDate__c = CommUtils.stringToDate(orderItem.WorkContractStartDate);   // 契約開始日（契約系利用）    
				    newOrderTran.WorkContractFilter__c = CommUtils.nullToblank(orderItem.WorkContractFilter);  // 契約日と契約時間帯  
				    newOrderTran.WorkContractRange__c = CommUtils.nullToblank(orderItem.WorkContractRange); // 契約期間    
				    newOrderTran.WorkContractTerm__c = CommUtils.nullToZero(orderItem.WorkContractTerm);    // 期間 
				    newOrderTran.Amount__c = CommUtils.nullToZero(orderItem.Amount);   // 合計 
				    // 2019/12/20 5.1.注文確定、5.4.注文履歴取得、5.5.定期注文確定、5.8.定期注文履歴取得　メモ欄情報追加 WSQ BEGIN
				    newOrderTran.Memo__c = CommUtils.nullToBlank(orderItem.Memo);//メモ
				    // 2019/12/20 5.1.注文確定、5.4.注文履歴取得、5.5.定期注文確定、5.8.定期注文履歴取得　メモ欄情報追加 WSQ END
	            	// 該当梱包の商品明細情報をリストに格納する
	            	orderSub.items.add(newOrderTran);
                }
                // 該当梱包情報を格納する
                subOrderList.add(orderSub);
            }
            //生成注文数据
            insert newParOrder;
            //生成注文サブ数据
            List<Order__c> subInsOrderList = new List<Order__c>();
            // 注文明細情報を格納する
            List<OrderItem__c> orderInsItemsList = new List<OrderItem__c>();
            //注文明細关联注文、注文サブ
            for (OrderSubUpdInfo sub : subOrderList) {
                sub.subOrder.RefParOrder__c = newParOrder.Id;
                subInsOrderList.add(sub.subOrder);
            }
            if (!subInsOrderList.isEmpty()) {
                insert subInsOrderList;
	            for (OrderSubUpdInfo sub : subOrderList) {
	                //orderItemsList.add();
	                for (OrderItem__c item : sub.items) {
	                    item.RefParOrder__c = newParOrder.Id; 
	                    item.RefSubOrder__c = sub.subOrder.Id;
	                    orderInsItemsList.add(item);
	                }
	            }
            }
            //生成注文明細数据
            if (!orderInsItemsList.isEmpty()) insert orderInsItemsList;
        } catch (CommException ex) {
            // 予想以外の異常が発生する場合
            ret = new WS_ResultInfo('E0501',ex.getMessage());
        } catch (Exception e) {
        	// RollBackp
            DataBase.rollBack(sp);
            // 予想以外の異常が発生する場合
            ret = new WS_ResultInfo('E9999',MSG_E9999);
            log.write_error(e.getStackTraceString());
            log.write_error(e.getMessage());
        }
        // 処理結果作成する    
        // 2018/05/01 梱包セット識別情報追加（DBへ反映しない、RELAY-SERVERやり取り用 BEGIN
        String rsXmltemp = '<OrderInfoRS><CommonResponse>$$_CommonResponse_$$</CommonResponse>$$_OrderInfoList_$$</OrderInfoRS>';
        return rsXmltemp.replace('$$_CommonResponse_$$',ret.toXml())
        				.replace('$$_OrderInfoList_$$',orderInfoStr);
        // 2018/05/01 梱包セット識別情報追加（DBへ反映しない、RELAY-SERVERやり取り用 END
    }
    // 5.1.登録情報格納する
    class OrderSubUpdInfo {
        public OrderSubUpdInfo() {
            items = new List<OrderItem__c>();
        }
        Order__c subOrder{get;set;}
        List<OrderItem__c> items{get;set;}
    }
    
    /**
    * 5.3.注文キャンセル
    **/
/*
/services/apexrest/ps/exposervice/V1/orderinfo

<OrderInfoRQ>
    <CommonRequest>
        <majorno>3</majorno>
        <minorno>3</minorno>
    </CommonRequest>
    <OrderInfo>
        <OrderNo>12991000011012991</OrderNo>
        <Memo>返品</Memo>
    </OrderInfo>
</OrderInfoRQ>
*/
    @TestVisible private static string cancelOrderinfo(Dom.XMLNode rootNode) {
    	// 処理結果情報を格納する
        WS_ResultInfo ret = new WS_ResultInfo();
        CanOrderInfoReq req = null;
        CanOrderInfoRep rep = new CanOrderInfoRep();
        // 返却結果
        String repBodyXml = '';
        // 梱包単位の処理情報を格納する
        List<Order__c> subOrders = null;
        // DB情報SAVEPOINT
        Savepoint sp = Database.setSavepoint();
        try {
        	// 引き渡すパラメータを解析する
	        req = new CanOrderInfoReq(rootNode);
            // 引き渡すパラメータ有効性チェック
            req.validata();
            // キャンセルの注文番号を設定する
	        String orderNo = CommUtils.nullToblank(req.OrderNo);
     		//查找注文番号一致的数据、找到后cancel
            List<Order__c> orders = [select Id,OrderStatus__c,ExpoApiCancelFlg__c from Order__c where OrderNo__c =:orderNo];
            if (orders.isEmpty()) {
                throw new CommException('指定の注文番号が非存在する['+orderNo+']');
	        }
	        // 注文番号を格納する
	        rep.OrderNo = orderNo;
            // 注文情報を探す
	        subOrders = [select id, OrderStatus__c, ShopInfoRef__r.Name,ExpoApiCancelFlg__c from Order__c where RefParOrder__c in :orders];
	        List<Order__c> updOrders = new List<Order__c>();
	        updOrders.addAll(orders);
	        updOrders.addAll(subOrders);
	        for (Order__c orderitem : updOrders) {
	        	// 2018/12/19 EXPO機能（AWS側合わせて）、キャンセル不可整制御追加対応 WSQ BEGIN
                //orderitem.OrderStatus__c = 'キャンセル';
                orderitem.OrderStatus__c = CommConst.ORDER_STATUS_CANCEL;
                orderitem.ExpoApiCancelFlg__c = !orderitem.ExpoApiCancelFlg__c;
                // 2018/12/19 EXPO機能（AWS側合わせて）、キャンセル不可整制御追加対応 WSQ END
                orderitem.Memo__c = req.Memo;
	        }
	        update updOrders;
	        // 梱包処理結果を設定する
            for (Order__c sub : subOrders) {
                CanOrderSubInfoRep subRep = new CanOrderSubInfoRep();
                subRep.OrderStatus = true;
                subRep.ShopName = CommUtils.nullToblank(sub.ShopInfoRef__r.Name);
                rep.subList.add(subRep);
            }
        }
        catch (CommException ex) {
            // 予想以外の異常が発生する場合
            ret = new WS_ResultInfo('E0503',ex.getMessage());
        }
        catch (Exception e) {
             // RollBackp
            DataBase.rollBack(sp);       
            // 予想以外の異常が発生する場合
            ret = new WS_ResultInfo('E9999',MSG_E9999);
            log.write_error(e.getStackTraceString());
            log.write_error(e.getMessage());
System.debug(loggingLevel.info, e.getMessage());
System.debug(loggingLevel.info, e.getStackTraceString());
            // 梱包単位の処理結果を作成する
            if (subOrders != null) {
	            for (Order__c sub : subOrders) {
	                CanOrderSubInfoRep subRep = new CanOrderSubInfoRep();
	                subRep.OrderStatus = false;
	                subRep.ErrorCode = 'E0503';
	                subRep.ErrorMessage = e.getMessage();
	                subRep.ShopName = CommUtils.nullToblank(sub.ShopInfoRef__r.Name);
	                rep.subList.add(subRep);
	            }
            }
        }
        // 処理結果作成する    
        String rsXmltemp = '<OrderInfoRS><CommonResponse>$$_CommonResponse_$$</CommonResponse>$$_OrderInfo_$$</OrderInfoRS>';
        return rsXmltemp.replace('$$_CommonResponse_$$',ret.toXml())
                        .replace('$$_OrderInfo_$$',rep.toXml());
    }
    
    
    /**
    * 5.4.注文履歴取得
    **/
/*
/services/apexrest/ps/exposervice/V1/orderinfo

<OrderInfoRQ>
    <CommonRequest>
        <majorno>3</majorno>
        <minorno>4</minorno>
    </CommonRequest>
    <ExtractionCondition>
        <UserId>00Dp00000000hip-00510000001wl0B</UserId>
        <ProductCode>00Dd0000000dBJC-1105</ProductCode>
        <DurationFrom>20180101</DurationFrom>
        <DurationTo>20180501</DurationTo>
    </ExtractionCondition>
</OrderInfoRQ>
*/
    @TestVisible private static string getOrderHistory(Dom.XMLNode rootNode,Boolean repOnly) {
        // 処理結果情報を格納する
        WS_ResultInfo ret = new WS_ResultInfo();
        OrderHistoryReq req = null;
        String rsXmltemp = '<OrderInfoRS><CommonResponse>$$_CommonResponse_$$</CommonResponse>$$_OrderInfoList_$$</OrderInfoRS>';
        String orderXmls = '';
        try {
            // 引き渡すパラメータを解析する
            req = new OrderHistoryReq(rootNode);
            // 有効チェック
            req.validata();
            // SQLパラメータ情報を取得する
            String userId = req.uiUserId;
            String prodCd = req.sfProduct;
            Date startDt = req.durationFrom;
            Date endDt  = req.durationTo;
            // 2018/12/05 注文API5.4.リクエストパラメータ[注文No]を追加
            String orderNo = req.orderNo;
            // 指定のリクエスト条件により、注文情報を取得する
            String queryHead = 'select RefParOrder__c orderId from OrderItem__c ';
            String queryWhere = ' Where RefParOrder__r.OrderUserId__c = :userId ';
             // 2018/12/05 注文API5.4.リクエストパラメータ[注文No]を追加
            if (!CommUtils.isBlank(orderNo)) { 
                queryWhere = ' Where RefParOrder__r.OrderNo__c = :orderNo ';
                if (!CommUtils.isBlank(userId)) queryWhere += ' And RefParOrder__r.OrderUserId__c = :userId ';
            }
            String queryOrder = ' group by RefParOrder__c limit 100';
            if (startDt != null) queryWhere += ' And DAY_ONLY(convertTimezone(CreatedDate)) >= :startDt ';
            if (endDt != null) queryWhere += ' And DAY_ONLY(convertTimezone(CreatedDate)) <= :endDt ';
            if (!CommUtils.isBlank(prodCd)) queryWhere += ' And AccountMasterRef__r.Field3__c = :prodCd ';
            // 対象注文情報を取得する
            String queryStr  = queryHead + queryWhere + queryOrder;
            List<AggregateResult> orderItemAvgs = DataBase.query(queryStr);
            set<Id> orderIds = new set<Id>();
            for (AggregateResult item : orderItemAvgs) {
                orderIds.add((ID)item.get('orderId'));
            }
            // データ存在する場合
            if (!orderIds.isEmpty()) {
	            // 2019/03/29 EXPO注文の際に、店舗定義なし（一つ店舗のみ）場合、注文通知を行わない不具合改修 WSQ BEGIN
	            // EXPOの場合、店舗設定されているが調べる
	            ShopInformation__c orgShop = getOrgShopInfo();
	            // 2019/03/29 EXPO注文の際に、店舗定義なし（一つ店舗のみ）場合、注文通知を行わない不具合改修 WSQ END
                String orderXml = '';
                // 注文、注文サブ、注文明細情報を一括取得する
                List<Order__c> orders = [Select OrderStatus__c, OrderNo__c, CreatedDate, 
                    (Select Id, Name, DeliveryType__c, Memo__c, OrderAmountIncTax__c, OrderNo__c, OrderStatus__c, 
                        OrderUserId__c, PayDetail__c, PayType__c, RefParOrder__c, SetAmountTax__c, SetAmount__c, 
                        SetDeliveryAddress__c, SetDeliveryCharge__c, SetDeliveryDate__c, SetDeliveryTime__c, SetOrderTitle__c, 
                        SetRealDeliveryDate__c, ShippingType__c, 
                        ShopInfoRef__r.ShopCode__c,ShopInfoRef__r.Name
                     From RefParOrderIndx__r order By Name), 
                    (Select Id, Name, AccountMasterPropRef__c, AccountMasterRef__c, Amount__c, Charge__c, 
                        PriceNoTax__c, Qty__c, RefParOrder__c, RefSubOrder__c, RepeaterFlg__c, RepeaterPayType__c, 
                        StaffPriceFlg__c, StockUnit__c, WorkContractFilter__c, WorkContractRange__c, WorkContractStartDate__c, WorkContractTerm__c,
                        AccountMasterRef__r.Field3__c
                        // 2019/12/20 5.1.注文確定、5.4.注文履歴取得、5.5.定期注文確定、5.8.定期注文履歴取得　メモ欄情報追加 WSQ BEGIN
                        ,Memo__c
                        // 2019/12/20 5.1.注文確定、5.4.注文履歴取得、5.5.定期注文確定、5.8.定期注文履歴取得　メモ欄情報追加 WSQ END
                     From refParOrder__r order By Name) 
                    From Order__c Where Id in :orderIds order By CreatedDate desc];
                // 注文配列情報
                for (Order__c oitem : orders) {
                    // 2018/04/24 定期明細あるの注文明細を返却する対応 BEGIN
                    if (repOnly) {
                        Boolean isHaveRepDetail = false;
                        for (OrderItem__c item : oitem.refParOrder__r) {
                            if (item.RepeaterFlg__c) {
                                isHaveRepDetail = true;
                                break;   
                            }
                        }
                        if (!isHaveRepDetail) continue;
                    }
                    // 2019/03/29 EXPO注文の際に、店舗定義なし（一つ店舗のみ）場合、注文通知を行わない不具合改修 WSQ BEGIN
                    for (Order__c ordersub : oitem.RefParOrderIndx__r) {
                    	if (CommUtils.isBlank(ordersub.ShopInfoRef__r.Name)) {
                    		ordersub.ShopInfoRef__r = orgShop;
                    	}
                    }
                    // 2019/03/29 EXPO注文の際に、店舗定義なし（一つ店舗のみ）場合、注文通知を行わない不具合改修 WSQ END
                    // 2018/04/24 定期明細あるの注文明細を返却する対応 END
                    OrderHistoryRep rep = new OrderHistoryRep(oitem);
                    orderXmls += rep.toXml();
                }
                // 
                //if (!CommUtils.isBlank(orderXml)) orderXmls = '<OrderInfoList>'+orderXml+'</OrderInfoList>';
            }
        } catch (CommException ex) {
            // 予想以外の異常が発生する場合
            ret = new WS_ResultInfo('E0504',ex.getMessage());
        } catch (Exception e) {
            // 予想以外の異常が発生する場合
            ret = new WS_ResultInfo('E9999',MSG_E9999);
            log.write_error(e.getStackTraceString());
            log.write_error(e.getMessage());
        }
        // 処理結果作成する    
        return rsXmltemp.replace('$$_CommonResponse_$$',ret.toXml())
                        .replace('$$_OrderInfoList_$$',orderXmls);
    }
    class OrderHistoryReq {
        public OrderHistoryReq(Dom.XmlNode root) {
            // 抽出条件
            Dom.XmlNode extrField = root.getChildElement('ExtractionCondition', null);
            if (extrField != null) {
                uiUserId = getChildElementByName(extrField, 'UserId');
                sfProduct = convertProductCd(getChildElementByName(extrField, 'ProductCode'));
                String uiDurationFrom = getChildElementByName(extrField, 'DurationFrom');
                durationFrom = CommUtils.stringToDate(uiDurationFrom);
                String uiDurationTo = getChildElementByName(extrField, 'DurationTo');
                durationTo = CommUtils.stringToDate(uiDurationTo);
                // 2018/12/05 注文API5.4.リクエストパラメータ[注文No]を追加
                orderNo = getChildElementByName(extrField, 'OrderNo');
            }
        }
        String uiUserId{get;set;}//ユーザID
        String sfProduct{get;set;}
        Date durationFrom{get;set;}
        Date durationTo{get;set;}
        // 2018/12/05 注文API5.4.リクエストパラメータ[注文No]を追加
        String orderNo{get;set;}//注文No.
        public Boolean validata() {
            // 2018/12/05 注文API5.4.リクエストパラメータ[注文No]を追加
            // 必須チェック【userid or orderno】両方とも空白の場合
            //if (CommUtils.isBlank(uiUserId)) {
            if (CommUtils.isBlank(uiUserId) && CommUtils.isBlank(orderNo)) {
                throw new CommException(MSG_E0001);
            }
            return true;
        }
    }
    class OrderHistoryRep {
        OrderHistoryRep(Order__c oitem) {
            OrderNo = CommUtils.nullToBlank(oitem.OrderNo__c);
            OrderDateTime = oitem.createddate.format('yyyyMMddHHmmss');
            ordersubXml = '';
            map<id, list<OrderItem__c>> subItemsMap = new map<id, list<OrderItem__c>>();
            for (OrderItem__c orderItem : oitem.refParOrder__r) {
                Id subId = orderItem.RefSubOrder__c;
                if (!subItemsMap.containsKey(subId)) subItemsMap.put(subId, new List<OrderItem__c>());
                subItemsMap.get(subId).add(orderItem);
            }
            // 梱包情報を取得する
            for (Order__c ordersub : oitem.RefParOrderIndx__r) {
                // 該当梱包のXML情報を作成する
                Id ordersubId = ordersub.id; 
                OrderHistoryRepSub sub = new OrderHistoryRepSub(ordersub, subItemsMap.get(ordersubId));
                ordersubXml+= sub.toXml();
            }
        }
        String OrderNo{get;set;}
        String OrderDateTime{get;set;}
        String ordersubXml{get;private set;}//梱包のXML情報を格納する
        // XMLファイル出力する
        public String toXml() {
            String xmlTemp = '<OrderInfoList><OrderNo>$_OrderNo_$</OrderNo><OrderDateTime>$_OrderDateTime_$</OrderDateTime>$_OrderSetInfo_$</OrderInfoList>';
            return xmlTemp.replace('$_OrderNo_$',OrderNo)
                            .replace('$_OrderDateTime_$',OrderDateTime)
                            .replace('$_OrderSetInfo_$',ordersubXml);
        }
        
    }
    class OrderHistoryRepSub {
        public OrderHistoryRepSub(Order__c ordersub, List<OrderItem__c> subItems) {
            // 該当梱包に含めている商品明細のXML情報を格納する
            if (subItems == null) subItems = new List<OrderItem__c>();
            itemsXml = '';
            for (OrderItem__c item : subItems) {
                OrderItemHistoryRep it = new OrderItemHistoryRep(item, ordersub.OrderStatus__c);
                itemsXml += it.toXml();
            }
            // 店舗コード
            ShopCode = ordersub.ShopInfoRef__r.ShopCode__c;
            // 店舗名
            ShopName = ordersub.ShopInfoRef__r.Name;
            // 配送料
            SetDeliveryCharge = CommUtils.nullToBlank(ordersub.SetDeliveryCharge__c);
            // 実際配送日付
            if (ordersub.SetRealDeliveryDate__c != null) SetDeliveryDate = getDateString(ordersub.SetRealDeliveryDate__c);
            // TODO[DEMO、配送希望日で設定する]
            if (CommUtils.isBlank(SetDeliveryDate) && ordersub.SetDeliveryDate__c != null) SetDeliveryDate = getDateString(ordersub.SetDeliveryDate__c);
            // 配送希望時刻
            SetDeliveryTime = ordersub.SetDeliveryTime__c;
            // 配送方法
            SetDeliveryWay = ordersub.DeliveryType__c;
            // 配送住所
            SetDeliveryAddress = ordersub.SetDeliveryAddress__c;
            // 配送先宛名
            SetOrderTitle = ordersub.SetOrderTitle__c;
            // 消費税
            SetAmountTax = CommUtils.nullToBlank(ordersub.SetAmountTax__c);
            // 梱包毎合計金額(税込)
            SetAmount = CommUtils.nullToBlank(ordersub.SetAmount__c);
            // 決済方式
            PayType = ordersub.PayType__c;
            // 決済詳細情報
            PayDetail = ordersub.PayDetail__c;
        }
        String ShopCode{get;set;}//店舗コード
        String ShopName{get;set;}//店舗名
        String SetDeliveryCharge{get;set;}//配送料
        String SetDeliveryDate{get;set;}//実際配送日付
        String SetDeliveryTime{get;set;}//配送希望時刻
        String SetDeliveryWay{get;set;}//配送方法
        String SetDeliveryAddress{get;set;}//配送住所
        String SetOrderTitle{get;set;}//配送先宛名
        String SetAmountTax{get;set;}//消費税
        String SetAmount{get;set;}//梱包毎合計金額(税込)
        String PayType{get;set;}//決済方式
        String PayDetail{get;set;}//決済詳細情報
        String itemsXml{get;private set;}
        public String toXml() {
            
            String xml = '<OrderSetInfo>$_OrderSetInfo_$$_OrderSetInfoItem_$</OrderSetInfo>';
            String xmlBody = '';

            xmlBody+=joinTagXml('ShopCode',ShopCode);
            xmlBody+=joinTagXml('ShopName',ShopName);
            xmlBody+=joinTagXml('SetDeliveryCharge',SetDeliveryCharge);
            xmlBody+=joinTagXml('SetDeliveryDate',SetDeliveryDate);
            xmlBody+=joinTagXml('SetDeliveryTime',SetDeliveryTime);
            xmlBody+=joinTagXml('SetDeliveryWay',SetDeliveryWay);
            xmlBody+=joinTagXml('SetDeliveryAddress',SetDeliveryAddress);
            xmlBody+=joinTagXml('SetOrderTitle',SetOrderTitle);
            xmlBody+=joinTagXml('SetAmountTax',SetAmountTax);
            xmlBody+=joinTagXml('SetAmount',SetAmount);
            xmlBody+=joinTagXml('PayType',PayType);
            xmlBody+=joinTagXml('PayDetail',PayDetail);

            return xml.replace('$_OrderSetInfo_$',xmlBody)
                      .replace('$_OrderSetInfoItem_$',itemsXml);
        }
    }
    class OrderItemHistoryRep {
        public OrderItemHistoryRep (OrderItem__c item,String status) {
            ProductCode = item.AccountMasterRef__r.Field3__c;
            ProductSubCode = CommUtils.nullToBlank(item.AccountMasterPropRef__c);
            StockUnit = item.StockUnit__c;
            Qty = item.Qty__c;
            PriceNoTax = CommUtils.nullToBlank(item.PriceNoTax__c);
            Charge = CommUtils.nullToBlank(item.Charge__c);
            StaffPriceFlg = item.StaffPriceFlg__c == '人材ではない' ? '1' :item.StaffPriceFlg__c == '時給' ? '2' : item.StaffPriceFlg__c == '日給' ? '3' : '';  // 人材単価フラグ
            RepeaterFlg = item.RepeaterFlg__c == true ? '1' : '0' ;
            RepeaterPayType = item.RepeaterPayType__c == '年払'? '1' :item.RepeaterPayType__c== '月払'? '2' :'';
            if(item.WorkContractStartDate__c != null) WorkContractStartDate = getDateString(item.WorkContractStartDate__c);
            WorkContractFilter = item.WorkContractFilter__c;
            WorkContractRange = item.WorkContractRange__c;
            WorkContractTerm = CommUtils.nullToBlank(item.WorkContractTerm__c);
            Amount = CommUtils.nullToZero(item.Amount__c);
			// 2019/12/20 5.1.注文確定、5.4.注文履歴取得、5.5.定期注文確定、5.8.定期注文履歴取得　メモ欄情報追加 WSQ BEGIN
			Memo = CommUtils.nullToBlank(item.Memo__c);//メモ
		    // 2019/12/20 5.1.注文確定、5.4.注文履歴取得、5.5.定期注文確定、5.8.定期注文履歴取得　メモ欄情報追加 WSQ END
            OrderStatus = status;
        }
        String ProductCode{get;set;}//商品コード
        String ProductSubCode{get;set;}//サブ商品コード
        String StockUnit{get;set;}//単位
        String Qty{get;set;}//数量
        String PriceNoTax{get;set;}//単価（税抜）
        String Charge{get;set;}//手数料（税抜）
        String StaffPriceFlg{get;set;}//人材単価フラグ
        String RepeaterFlg{get;set;}//定期購入フラグ
        String RepeaterPayType{get;set;}//定期払い方式
        String WorkContractStartDate{get;set;}//契約開始日
        String WorkContractFilter{get;set;}//契約日と契約時間帯
        String WorkContractRange{get;set;}//契約期間
        String WorkContractTerm{get;set;}//期間
        Decimal Amount{get;set;}//金額（税抜）
        String OrderStatus{get;set;}//注文状態
        // 2019/12/20 5.1.注文確定、5.4.注文履歴取得、5.5.定期注文確定、5.8.定期注文履歴取得　メモ欄情報追加 WSQ BEGIN
        String Memo{get;set;}//メモ
        // 2019/12/20 5.1.注文確定、5.4.注文履歴取得、5.5.定期注文確定、5.8.定期注文履歴取得　メモ欄情報追加 WSQ END
        public String toXml() {
            
            String xml = '<OrderSetInfoItem>$_OrderSetInfoItem_$</OrderSetInfoItem>';
            String xmlBody = '';
            xmlBody+=joinTagXml('ProductCode',getExpoCode(ProductCode));
            xmlBody+=joinTagXml('ProductSubCode',ProductSubCode);
            xmlBody+=joinTagXml('StockUnit',StockUnit);
            xmlBody+=joinTagXml('Qty',Qty);
            xmlBody+=joinTagXml('PriceNoTax',PriceNoTax);
            xmlBody+=joinTagXml('Charge',Charge);
            xmlBody+=joinTagXml('StaffPriceFlg',StaffPriceFlg);
			xmlBody+=joinTagXml('RepeaterFlg',RepeaterFlg);
			xmlBody+=joinTagXml('RepeaterPayType',RepeaterPayType);
			xmlBody+=joinTagXml('WorkContractStartDate',WorkContractStartDate);
			xmlBody+=joinTagXml('WorkContractFilter',WorkContractFilter);
			xmlBody+=joinTagXml('WorkContractRange',WorkContractRange);
			xmlBody+=joinTagXml('WorkContractTerm',WorkContractTerm);
			xmlBody+=joinTagXml('Amount',CommUtils.nullToBlank(Amount));
            xmlBody+=joinTagXml('OrderStatus',OrderStatus);
            // 2019/12/20 5.1.注文確定、5.4.注文履歴取得、5.5.定期注文確定、5.8.定期注文履歴取得　メモ欄情報追加 WSQ BEGIN
            xmlBody+=joinTagXml('Memo',Memo);
            // 2019/12/20 5.1.注文確定、5.4.注文履歴取得、5.5.定期注文確定、5.8.定期注文履歴取得　メモ欄情報追加 WSQ END
            return xml.replace('$_OrderSetInfoItem_$',xmlBody);
        }
    }
    /*
    <OrderInfoRQ>
        <CommonRequest>
            <majorno>3</majorno>
            <minorno>9</minorno>
        </CommonRequest>
        <ExtractionCondition>
            <UserId>00Dp00000000hip-00510000001wl0B</UserId>
        </ExtractionCondition>
    </OrderInfoRQ>
    */
    /**
    * 5.9.決済情報取得
    * /services/apexrest/ps/exposervice/V1/orderinfo
    **/
    @TestVisible private static string getPayInfo(Dom.XMLNode rootNode) {
    	// 処理結果情報を格納する
        WS_ResultInfo ret = new WS_ResultInfo();
        // パラメータ情報
        PayInfoReq req = null;
        // レスポンス情報
        String payInfo = '';
        try {
            // 引き渡すパラメータ情報を解析する
            req = new PayInfoReq(rootNode); 
            // 有効チェック
            req.validata();
            //
            log.write_log('req：'+req);
            // EXPOのサイトユーザの場合 BEGIN by zh
            if(commReq.isExpoSite()) {
            	String usrId = req.sfUserId;
            	String q = CommSqlUtils.generateQueryString('ExpoUser__c') + ' where Id = :usrId ';
            	List<ExpoUser__c> usrs = DataBase.query(q);
            	if (usrs.isEmpty()) {
	                ret = new WS_ResultInfo('E0003',MSG_E0003);
	            }else {
	            	// 決済情報を返却する
	            	List<UserPayInfo__c> payLst = [select PayType__c, CardNo__c, PayDetail__c from UserPayInfo__c where ExpoUserInfoRef__c = :usrId and DeleteFlg__c = false];
	                List<String> payInfoList = new List<String>();
	                for (UserPayInfo__c pay : payLst) {
		                XmlPayInfo item = new XmlPayInfo();
		                item.PayType = pay.PayType__c;
		                item.PayDetail = pay.PayDetail__c;
		                if (item.PayType == 'カード') item.PayDetail = pay.CardNo__c;
		                payInfoList.add(item.toXml());
	                }
	                payInfo = '<PayInfoList>'+String.join(payInfoList, '')+'</PayInfoList>';
            	}
            }else{
	    // EXPOのサイトユーザの場合 END by zh
            // USER情報を検索する
            List<user> usrs = [select id from User Where Id = :req.sfUserId];
            if (usrs.isEmpty()) {
                ret = new WS_ResultInfo('E0003',MSG_E0003);
            } else {
            	// 決済情報を返却する
            	List<UserPayInfo__c> payLst = [select PayType__c, CardNo__c, PayDetail__c from UserPayInfo__c where UserRef__c = :req.sfUserId and DeleteFlg__c = false];
                List<String> payInfoList = new List<String>();
                for (UserPayInfo__c pay : payLst) {
	                XmlPayInfo item = new XmlPayInfo();
	                item.PayType = pay.PayType__c;
	                item.PayDetail = pay.PayDetail__c;
	                if (item.PayType == 'カード') item.PayDetail = pay.CardNo__c;
	                payInfoList.add(item.toXml());
                }
                payInfo = '<PayInfoList>'+String.join(payInfoList, '')+'</PayInfoList>';
            // EXPOのサイトユーザの場合 BEGIN by zh
            }
            // EXPOのサイトユーザの場合 END by zh
            }
        } catch (CommException ex) {
            // 予想以外の異常が発生する場合
            ret = new WS_ResultInfo('E0504',ex.getMessage());
        } catch (Exception e) {
            // 予想以外の異常が発生する場合
            ret = new WS_ResultInfo('E9999',MSG_E9999);
            log.write_error(e.getStackTraceString());
            log.write_error(e.getMessage());
        }
        // 返却テンプレートXML
        String rsXmltemp = '<OrderInfoRS><CommonResponse>$$_CommonResponse_$$</CommonResponse>$$_PayInfo_$$</OrderInfoRS>';
        return rsXmltemp.replace('$$_CommonResponse_$$',ret.toXml())
                        .replace('$$_PayInfo_$$',payInfo);
    
    }
    /**
    * 5.9.決済情報取得
    **/
    class PayInfoReq {
        public PayInfoReq(Dom.XmlNode root) {
            // 抽出条件
            Dom.XmlNode extrField = root.getChildElement('ExtractionCondition', null);
            if (extrField != null) {
                uiUserId = getChildElementByName(extrField, 'UserId');
                // UIのID→SFのIDに変換する
                //String[] wkUserId = uiUserId.split('-');
                sfUserId =  convertUserId(uiUserId);//CommUtils.nullToBlank(wkUserId.size() > 1 ? wkUserId[1] : wkUserId[0]);
            }
        }
        String uiUserId{get;set;}
        String sfUserId{get;set;}
        //  有効性チェック
        public Boolean validata() {
            // 必須チェック
            if (CommUtils.isBlank(uiUserId)) {
                throw new CommException(MSG_E0001);
            }
            return true;
        }
    }
    class XmlPayInfo {
        public String PayType{get;set;}//管理者フラグ
		public String PayDetail{get;set;}//会員種別
        public String toXml() {
            String xml = '<Payinfo>$_Payinfo_$</Payinfo>';
            String xmlBody = '';
            xmlBody+=joinTagXml('PayType',PayType);
            xmlBody+=joinTagXml('PayDetail',PayDetail);
            return xml.replace('$_Payinfo_$',xmlBody);
        }
    }
    /**
    * 5.10.注文見積情報取得
    **/
    @TestVisible private static string getOrderEstInfo(Dom.XMLNode rootNode) {
        // 処理結果情報を格納する
        WS_ResultInfo ret = new WS_ResultInfo();

        List<String> xmlRs = new List<String>();
        try {
            // 引き渡すパラメータを解析する
	        OrderEstInfoReq req = new OrderEstInfoReq(rootNode);
			// *******************************
			// 関連チェックする
			// *******************************
			// 商品の配達目的地情報を存在チェックを行う
			if (CommUtils.isBlank(req.destinationState)) {
			    throw new CommException(MSG_E0001 + ':'+req);
			}
            // 指定の商品コードが存在するチェックを行う
			// 商品コード情報を格納する
			Set<String> prodCodeSet = new set<String>();
			// 商品属性情報を格納する
			Set<String> prodSubCodeSet = new Set<String>();
			// 商品コード情報を取得する
			for (OrderEstInfo est : req.orderEstLst) {
			    // 注文商品コードを格納する
			    if (CommUtils.isBlank(est.ProductCode)) continue;
			    prodCodeSet.add(est.ProductCode);
            	// サブ商品コードを格納する
            	if (!CommUtils.isBlank(est.ProductSubCode)) prodSubCodeSet.add(est.ProductSubCode);
            }
            // 商品情報を取得する
            // 2018/02/04 利用できる決済方法追加 BEGIN
			//list<AccountMaster__c> products = [select id,name,ShippingDays__c,Field3__c,ShopInfoRef__r.ShopCode__c,ShopInfoRef__r.Name, TaxRateCal__c,ServiceRate__c
			list<AccountMaster__c> products = [select id,name,ShippingDays__c,Field3__c,ShopInfoRef__r.ShopCode__c,ShopInfoRef__r.Name,ShopInfoRef__r.Email__c, TaxRateCal__c,ServiceRate__c,PayType__c
			// 2018/02/04 利用できる決済方法追加 END
			                                   from AccountMaster__c where Field3__c =:prodCodeSet];
            //通过サブ商品コード取得商品属性情報
            Map<String,AccountMasterProp__c> accSubCodeToIdMap = new Map<String,AccountMasterProp__c>();
            if (!prodSubCodeSet.isEmpty()) {
                for (AccountMasterProp__c mas : [select Id,AccountMasterRef__r.Field3__c from AccountMasterProp__c where Id =:prodSubCodeSet]){
                    accSubCodeToIdMap.put(mas.Id,mas);
                }
            }
			// map<商品コード,商品情報>
			map<String,AccountMaster__c> productMap = new map<String,AccountMaster__c>();
			for (AccountMaster__c p : products) {
			    productMap.put(p.Field3__c, p);
			}
			// 引き渡す商品コードが存在する・しないチェックする
			for (OrderEstInfo est : req.orderEstLst) {
                // 注文商品コード
                if (!productMap.containskey(est.ProductCode)) {
                    throw new CommException('指定の商品が非存在する['+getExpoCode(est.ProductCode)+']');
                }
	            if (!CommUtils.isBlank(est.ProductSubCode)) {
	                est.ProductSubCode = Id.ValueOf(est.ProductSubCode);
	                if (!accSubCodeToIdMap.containsKey(est.ProductSubCode)) {
	                    throw new CommException('指定のサブ商品コードが非存在する['+String.valueOf(est.ProductSubCode)+']');
	                } else {
	                    AccountMasterProp__c prop = accSubCodeToIdMap.get(est.ProductSubCode);
	                    String productCode = prop.AccountMasterRef__r.Field3__c;
	                    if (productCode != est.ProductCode) {
	                        throw new CommException('商品コード['+getExpoCode(est.ProductCode)+']のサブ商品コードが非存在する['+String.valueOf(est.ProductSubCode)+']');
	                    }
	                }
	            }
			}
			// 梱包毎処理ルール、店舗別、発送日目安、発送方法、配送方法により、梱包処理する
			// 発送日目安が未設定の場合、別々に梱包になる
			// 発送方法が　1: 分割 (デフォルト) 、2: 一括　により、一括の場合、最大の発送目安日により、梱包する
			// 店舗別 ー＞ 配送方法：１ー＞商品別返却する
			//           配送方法：２ー＞発送日目安により、
			// 取得対象商品の店舗コードと名称情報を格納する
			// 2018/10/07 注文情報送信機能の対応 WSQ BEGIN
			// map<String,String> shopMap = new map<String,String>();
			map<String,ShopInformation__c> shopMap = new map<String,ShopInformation__c>();
			// 2018/10/07 注文情報送信機能の対応 WSQ END
            // 該当システムの単価定義区分により、税込金額を計算する
            // 税抜きから金額計算する
            CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommConst.APPOPTION_UTP_DEF_KB_OP3);
            // 変換後の商品情報を格納する
            List<OrderEstSetInfoItem> estList = new List<OrderEstSetInfoItem>();
            for (OrderEstInfo estInfo : req.orderEstLst) {
				// 商品コード未設定の場合、次の処理をSKIP
				if (CommUtils.isBlank(estInfo.ProductCode)) continue;
				// 商品マスタ情報を取得する
				AccountMaster__c r = productMap.get(estInfo.ProductCode);
				// 商品情報
				OrderEstSetInfoItem ordEstItem = new OrderEstSetInfoItem();
				ordEstItem.ShopCode = CommUtils.nullToblank(r.ShopInfoRef__r.ShopCode__c);
				ordEstItem.ProductCode = CommUtils.nullToblank(estInfo.ProductCode);
				ordEstItem.ProductSubCode = CommUtils.nullToblank(estInfo.ProductSubCode);
				ordEstItem.StockUnit= CommUtils.nullToblank(estInfo.StockUnit);
				ordEstItem.PriceNoTax= CommUtils.nullToblank(CommUtils.nullToZero(estInfo.PriceNoTax));
				ordEstItem.Qty= CommUtils.nullToblank(CommUtils.nullToZero(estInfo.Qty));
				ordEstItem.Charge = CommUtils.nullToblank(estInfo.Charge);
				ordEstItem.DeliveryType = CommUtils.nullToblank(estInfo.DeliveryType);
				// 2018/02/04 利用できる決済方法追加 BEGIN
				List<String> itemPayTypes = CommUtils.nullToblank(r.PayType__c).split(';');
				if (!itemPayTypes.isEmpty()) ordEstItem.PayType = String.join(itemPayTypes,',');
				// 2018/02/04 利用できる決済方法追加 END
				// 配送可能日目安
				if (r.ShippingDays__c != null) ordEstItem.DeliveryDate = CommUtils.nullToZero(r.ShippingDays__c);
				// else ordEstItem.DeliveryDate = -1;
				// 該当商品の配送料を計算する[配送料は税金個別計算しない、そのまま引き渡す]
				ordEstItem.DeliveryCharge = calDeliveryCharge(req.destinationState, ordEstItem.DeliveryType);
                // 金額（税抜）
                // XMLから引き渡さない場合、再度自動計算する
                if (CommUtils.isBlank(estInfo.Amount)) {
                    ordEstItem.Amount = (CommUtils.nullToZero(ordEstItem.PriceNoTax) * CommUtils.nullToZero(ordEstItem.Qty)) + CommUtils.nullToZero(ordEstItem.Charge);
                } 
                // 引き渡す場合、そのまま設定する
                else {
                    ordEstItem.Amount = CommUtils.nullToZero(estInfo.Amount);
                }
                // 商品の合計金額の消費税計算する
                priceInfo.process(ordEstItem.Amount, 1, (CommUtils.nullToZero(r.TaxRateCal__c) / 1), (CommUtils.nullToZero(r.ServiceRate__c) / 1));
                // 消費税金額
                Decimal taxRate = priceInfo.priceIncTax - priceInfo.priceExcTax;
                if (taxRate >= 0) ordEstItem.taxRate = taxRate; 
                // 2018/03/21 5.10見積明細返却値追加の対応 BEGIN
                ordEstItem.StaffPriceFlg = estInfo.StaffPriceFlg;
                ordEstItem.RepeaterFlg = estInfo.RepeaterFlg;
                ordEstItem.RepeaterPayType = estInfo.RepeaterPayType;
                ordEstItem.WorkContractStartDate = estInfo.WorkContractStartDate;
                ordEstItem.WorkContractFilter = estInfo.WorkContractFilter;
                ordEstItem.WorkContractRange = estInfo.WorkContractRange;
                ordEstItem.WorkContractTerm = estInfo.WorkContractTerm;
                // 2018/03/21 5.10見積明細返却値追加の対応 END
                // 配列に格納する
                estList.add(ordEstItem);
                // 店舗情報を格納する
                // 2018/10/07 注文情報送信機能の対応 WSQ BEGIN
                //shopMap.put(ordEstItem.ShopCode, CommUtils.nullToblank(r.ShopInfoRef__r.Name));
                // 会計商品の店舗がNULLの場合、処理対象外[WSQ 2018/11/20]
                if (r.ShopInfoRef__c != null) shopMap.put(ordEstItem.ShopCode, r.ShopInfoRef__r);
                // 2018/10/07 注文情報送信機能の対応 WSQ END
            }
            // 梱包処理を行う
            // 2019/03/29 EXPO注文の際に、店舗定義なし（一つ店舗のみ）場合、注文通知を行わない不具合改修 WSQ BEGIN
            // EXPOの場合、店舗設定されているが調べる
            ShopInformation__c orgShop = getOrgShopInfo();
            shopMap.put(orgShop.shopCode__c,orgShop);
            // 2019/03/29 EXPO注文の際に、店舗定義なし（一つ店舗のみ）場合、注文通知を行わない不具合改修 WSQ END
            // 店舗別分類する
            map<String, List<OrderEstSetInfoItem>> shopItemsMap = new map<String, List<OrderEstSetInfoItem>>();
            List<String> shopCodeLst = new List<String>();
            for (OrderEstSetInfoItem est : estList) {
                if (!shopItemsMap.containsKey(est.ShopCode)) {
                    shopItemsMap.put(est.ShopCode, new List<OrderEstSetInfoItem>());
                    shopCodeLst.add(est.ShopCode);
                }
                shopItemsMap.get(est.ShopCode).add(est);
            }
            // 2018/02/05 商品からできる全部支払方法を格納する Begin
            set<String> canPaySet = new set<String>();
	        Schema.DescribeFieldResult payField = AccountMaster__c.PayType__c.getDescribe();
	        List<Schema.PicklistEntry> ple = payField.getPicklistValues();
	        for( Schema.PicklistEntry f : ple) {
                canPaySet.add(f.getValue());
	        }
            // 2018/02/05 商品からできる全部支払方法を格納する End
            // 返却結果を格納する
            OrderEstInfoRep rep = new OrderEstInfoRep();
            // 発送方法が　1: 順次発送 (デフォルト) 、2: 一括発送　により、一括の場合、最大の発送目安日により、梱包する
            if (req.ShippingType == '1') {
                // 商品毎に商品情報を返却する
                for (String spcd : shopCodeLst) {
                    // 該当店舗の全て商品リストを取得する
                    List<OrderEstSetInfoItem> itemLst =  shopItemsMap.get(spcd);
                    // 1: 順次発送 商品毎に梱包として返却する
                    for (OrderEstSetInfoItem est : itemLst) {
	                    // 梱包単位情報を初期化する
	                    OrderEstSetInfo orderSub = new OrderEstSetInfo();
                        orderSub.ShopCode = est.ShopCode;
                        // 2018/10/07 注文情報送信機能の対応 WSQ BEGIN
	                    // orderSub.ShopName = shopMap.get(est.ShopCode);
                        if (shopMap.containsKey(est.ShopCode)) {
                        	orderSub.ShopName = shopMap.get(est.ShopCode).Name;
                        	orderSub.ShopMail = shopMap.get(est.ShopCode).Email__c;
                        }
                        // 2018/10/07 注文情報送信機能の対応 WSQ END
                        orderSub.OrganizationId = ORGID;
                        // 配送可能日目安
                        orderSub.SetDeliveryDate = CommUtils.nullToBlank(est.DeliveryDate);
                        // 配送料
                        orderSub.SetDeliveryCharge = CommUtils.nullToBlank(est.DeliveryCharge);
                        // 消費税
                        orderSub.SetAmountTax = CommUtils.nullToBlank(est.taxRate);
                        // 梱包毎合計金額(税込)
                        // 梱包内各商品の金額（税抜） + 配送料 + 消費税
                        Decimal calAmount = est.Amount + est.DeliveryCharge + est.taxRate;
                        orderSub.SetAmount = CommUtils.nullToBlank(calAmount);
                        // 商品情報を格納する
                        orderSub.OrderEstItems.add(est);
                        // 梱包情報を格納する
                        rep.ordEsts.add(orderSub);
                    }
                }
            } else {
                // 一括配送するので、最大の配送日は配送予定日
                // 店舗別一括配送
                for (String spcd : shopCodeLst) {
                    // 該当店舗の全て商品リストを取得する
                    List<OrderEstSetInfoItem> shopItemLst =  shopItemsMap.get(spcd);
                    // 配送方法により、分ける配送する
                    map<String, List<OrderEstSetInfoItem>> deliveryTypeMap = new map<String, List<OrderEstSetInfoItem>>();
                    for (OrderEstSetInfoItem est : shopItemLst) {
                        String detype = est.DeliveryType;
                        if (!deliveryTypeMap.containsKey(detype)) deliveryTypeMap.put(detype, new List<OrderEstSetInfoItem>());
                        deliveryTypeMap.get(detype).add(est);
                    }
                    // 配送方式により梱包分ける
                    for (String detype : deliveryTypeMap.keySet()) {
                        // 2018/02/05 商品からできる全部支払方法を格納する Begin
                        Set<String> clonePaySet = canPaySet.clone();
                        // 2018/02/05 商品からできる全部支払方法を格納する End
                        // 該当配送方式に含めている商品リスト
                        List<OrderEstSetInfoItem> itemLst = deliveryTypeMap.get(detype);
	                    // 梱包単位情報を初期化する
	                    OrderEstSetInfo orderSub = new OrderEstSetInfo();  
	                    // 配送可能目安日
	                    Decimal maxDeliveryDate = -1;
	                    // 配送料
	                    Decimal sumDeliveryCharge = 0;
	                    // 消費税
	                    Decimal sumAmountTax = 0;
	                    // 梱包毎合計金額(税込)
	                    Decimal sumAmount = 0;
	                    // 梱包毎合計金額(税込)
	                    // 2: 一括発送 商品毎に梱包として返却する
	                    for (OrderEstSetInfoItem est : itemLst) {
	                        // 2018/02/05 商品からできる全部支払方法を格納する Begin
	                        if (!clonePaySet.isEmpty()) {
	                           if (CommUtils.isBlank(est.PayType)) clonePaySet.clear();
	                           else {
	                               Set<String> locPaySet = new set<String>();
	                               for (String s: est.PayType.split(',')) {
	                                   s = CommUtils.nullToBlank(s);
	                                   locPaySet.add(s);
	                               }
	                               for (String s: clonePaySet) {
	                                   if (!locPaySet.contains(s)) clonePaySet.remove(s);
	                               }
	                           }
	                        }
	                        // 2018/02/05 商品からできる全部支払方法を格納する End
	                        // 配送可能の最大目安日
	                        if (est.DeliveryDate >= 0 && est.DeliveryDate > maxDeliveryDate) maxDeliveryDate = est.DeliveryDate;
	                        // 配送料
	                        //orderSub.SetDeliveryCharge = CommUtils.nullToBlank(est.DeliveryCharge);
	                        sumDeliveryCharge += est.DeliveryCharge;
	                        // 消費税
	                        //orderSub.SetAmountTax = CommUtils.nullToBlank(est.taxRate);
	                        sumAmountTax += est.taxRate;
	                        // 梱包毎合計金額(税込)
	                        // 梱包内各商品の金額（税抜） + 配送料 + 消費税
	                        Decimal calAmount = est.Amount + est.DeliveryCharge + est.taxRate;
	                        sumAmount += calAmount;
	                        // 商品情報を格納する
	                        orderSub.OrderEstItems.add(est);
	                    }
	                    // 店舗コード
	                    orderSub.ShopCode = itemLst[0].ShopCode;
	                    // 店舗名
	                    // 2018/10/07 注文情報送信機能の対応 WSQ BEGIN
	                    //orderSub.ShopName = shopMap.get(itemLst[0].ShopCode);
	                    String wkSpcd = itemLst[0].ShopCode;
//log.write_log('wkSpcd：'+wkSpcd);
//log.write_log('shopMap：'+shopMap);
                        if (shopMap.containsKey(wkSpcd)) {
//log.write_log('shopMap.get(wkSpcd)：'+shopMap.get(wkSpcd));
//log.write_log('orderSub：'+orderSub);
//log.write_log('shopMap.get(wkSpcd).Name：'+shopMap.get(wkSpcd).Name);
                        	orderSub.ShopName = shopMap.get(wkSpcd).Name;
                        	orderSub.ShopMail = shopMap.get(wkSpcd).Email__c;
                        }
	                    // 2018/10/07 注文情報送信機能の対応 WSQ END
	                    // 施設組織ID
	                    orderSub.OrganizationId = ORGID;
	                    // 配送可能日目安
	                    if (maxDeliveryDate >= 0) orderSub.SetDeliveryDate = CommUtils.nullToBlank(maxDeliveryDate);
	                    // 配送料
	                    orderSub.SetDeliveryCharge = CommUtils.nullToBlank(sumDeliveryCharge);
	                    // 消費税
	                    orderSub.SetAmountTax = CommUtils.nullToBlank(sumAmountTax);
	                    // 梱包毎合計金額(税込)
	                    orderSub.SetAmount = CommUtils.nullToBlank(sumAmount);
	                    // 2018/02/05 商品からできる全部支払方法を格納する Begin
	                    if (!clonePaySet.isEmpty()) {
	                        List<String> paylst = new List<String>(clonePaySet);
	                        orderSub.SetPayType = String.join(paylst,',');
	                    }
	                    // 2018/02/05 商品からできる全部支払方法を格納する End
	                    // 梱包情報を格納する
	                    rep.ordEsts.add(orderSub);
                    }
                }
            }
            // 変更のXMLを作成する
            xmlRs.add(rep.toXml()); 
        } 
        catch (CommException ex) {
            // 予想以外の異常が発生する場合
            ret = new WS_ResultInfo('E0510',ex.getMessage());
            // 返却結果情報をクリアする
            xmlRs.clear();
        }
        catch (Exception e) {
            log.write_error(e.getStackTraceString());
            log.write_error(e.getMessage());
            throw e;
        }
        // 処理結果作成する    
        String rsXmltemp = '<OrderInfoRS><CommonResponse>$$_CommonResponse_$$</CommonResponse><OrderEstInfo>$$_OrderEstInfo_$$</OrderEstInfo></OrderInfoRS>';
        return rsXmltemp.replace('$$_CommonResponse_$$',ret.toXml())
                        .replace('$$_OrderEstInfo_$$',String.join(xmlRs,''));
    }
    
    // 配送地と配送方法により、配送料を計算する
    // dest :配達着地の都道府県配送方法
    // dType:配送方法
    // TODO!!!!!!!!!!!!後に変更が必要
    private static Decimal calDeliveryCharge(String dest, String dType) {
        List<String> dests = CommUtils.parseJapanAddress(dest);
        if (dests.size() > 0) dest = dests[0];
        if (dType == '取りに行く') return 0;
        else if (dType == '宅配便') {
            if (dest == '北海道' || dest == '沖縄県') {
                return 1200;
            } else {
                return 1000;
            }
        }
        else if (dType == 'ルート配送') {
            if (dest == '北海道' || dest == '沖縄県') {
                return 800;
            } else {
                return 500;
            }
        }
        return 0; 
    }
    

    
    class XmlOrderInfoRest {
        public String OrderNo{get;set;}//注文番号
        public List<XmlOrdChildRest> XmlOrdChildRests{get;set;}
		public XmlOrderInfoRest(){
			XmlOrdChildRests = new List<XmlOrdChildRest>();
		}
        public String toXml() {
            XmlOrdChildRest XmlOrdChildRest = new XmlOrdChildRest();
            String xml = '<OrderNo>$_OrderNo_$</OrderNo>';
            /*String xmlBody = '';
            if (!XmlOrdChildRests.isEmpty()) {
            	for (XmlOrdChildRest child : XmlOrdChildRests) {
                   xmlBody+=child.toXml();
                }
            }*/
            return xml.replace('$_OrderNo_$',OrderNo);
            		  //.replace('$_OrderSetInfo_$',xmlBody);
        }
    }
    
    class XmlOrdChildRest {
		public String OrderStatus{get;set;}//状態
		public String ErrorCode{get;set;}//エラーコード
		public String ErrorMessage{get;set;}//エラー内容											
	 	public XmlOrdChildRest() {
	 	}
	 	public XmlOrdChildRest(String ordStatus, String errCode, String errMsg) {
	 		OrderStatus = ordStatus;
	 		ErrorCode = errCode;
	 		ErrorMessage = errMsg;
	 	}
        public String toXml() {
            String xml = '<OrderSetInfo>$_OrderSetInfo_$</OrderSetInfo>';
            String xmlBody = '';
            /*xmlBody+=joinTagXml('OrderStatus',OrderStatus);
            xmlBody+=joinTagXml('ErrorCode',ErrorCode);
            xmlBody+=joinTagXml('ErrorMessage',ErrorMessage);*/
            
	        if (!CommUtils.isBlank(OrderStatus))    xmlBody+= '<OrderStatus>'+OrderStatus.escapeXml() + '</OrderStatus>';
	 		if (!CommUtils.isBlank(ErrorCode)) xmlBody+= '<ErrorCode>'+ErrorCode.escapeXml()+'</ErrorCode>';
	 		if (!CommUtils.isBlank(ErrorMessage)) xmlBody+= '<ErrorMessage>'+ErrorMessage.escapeXml()+'</ErrorMessage>';
            return xml.replace('$_OrderSetInfo_$',xmlBody);
        }
    }
    // ********************************
    // 5.10  "注文見積情報取得"(orderinfo)
    // レスポンス情報格納する
    // 注文見積情報
    // ********************************
    class OrderEstInfoRep {
        //public String OrderAmountIncTax{get;set;}//合計金額
        public List<OrderEstSetInfo> ordEsts{get;set;}//梱包情報格納する
        public OrderEstInfoRep(){
        	ordEsts = new List<OrderEstSetInfo>();
        }
        public String toXml() {
            String xml = '$_OrderEstSetInfo_$';
            String xmlBody = '';
            String itemsBody = '';
            // 該当施設の全て注文金額
            Decimal allSumAmount = 0;
            for (OrderEstSetInfo est : ordEsts) {
               itemsBody+=est.toXml();
               allSumAmount += CommUtils.nullToZero(est.SetAmount);
            }
            // 合計金額 
            xmlBody+=joinTagXml('OrderAmountIncTax',CommUtils.nullToBlank(allSumAmount));
            // 梱包毎の注文見積情報
			xmlBody+=xml.replace('$_OrderEstSetInfo_$',itemsBody);
            return xmlBody;
        }
    }
    // ********************************
    // 5.10  "注文見積情報取得"(orderinfo)
    // レスポンス情報格納する
    // 注文見積情報
    //      梱包毎の注文見積情報
    // ********************************
    class OrderEstSetInfo{
    	public String ShopCode{get;set;}//店舗コード
		public String ShopName{get;set;}//店舗名
		// 2018/10/07 注文情報送信機能の対応 WSQ BEGIN
		public String ShopMail{get;set;}//店舗メール
		// 2018/10/07 注文情報送信機能の対応 WSQ END
		public String OrganizationId{get;set;}//施設組織ID
		public String SetDeliveryDate{get;set;}//配送可能日目安
		public String SetDeliveryCharge{get;set;}//配送料
		public String SetAmountTax{get;set;}//消費税
		public String SetAmount{get;set;}//梱包毎合計金額(税込)
		public String SetPayType{get;set;}//利用できる決済情報
		public List<OrderEstSetInfoItem> OrderEstItems{get;set;}//商品情報配列
		// 初期化処理
		public OrderEstSetInfo(){
			OrderEstItems = new List<OrderEstSetInfoItem>();
		}
		// XML出力作成
    	public String toXml() {
            String xmlTemplate = '<OrderEstSetInfo>$_OrderEstSetInfo_$$_OrderEstSetInfoItem_$</OrderEstSetInfo>';
            String xmlBody = '';
            String itemsBody = '';

            xmlBody+=joinTagXml('ShopCode',ShopCode);
            xmlBody+=joinTagXml('ShopName',ShopName);
            // 2018/10/07 注文情報送信機能の対応 WSQ BEGIN
            xmlBody+=joinTagXml('ShopMail',ShopMail);
            // 2018/10/07 注文情報送信機能の対応 WSQ END
            xmlBody+=joinTagXml('OrganizationId',OrganizationId);
            xmlBody+=joinTagXml('SetDeliveryDate',SetDeliveryDate);
            xmlBody+=joinTagXml('SetDeliveryCharge',SetDeliveryCharge);
            xmlBody+=joinTagXml('SetAmountTax',SetAmountTax);
            xmlBody+=joinTagXml('SetAmount',SetAmount);
            xmlBody+=joinTagXml('SetPayType',SetPayType,true);
            for (OrderEstSetInfoItem item : OrderEstItems) {
               itemsBody+=item.toXml();
            }
            return xmlTemplate.replace('$_OrderEstSetInfo_$',xmlBody)
            		          .replace('$_OrderEstSetInfoItem_$',itemsBody);
        }
    }
    // ********************************
    // 5.10  "注文見積情報取得"(orderinfo)
    // レスポンス情報格納する
    // 注文見積情報
    //      梱包毎の注文見積情報
    //          商品情報
    // ********************************
    class OrderEstSetInfoItem{
        public OrderEstSetInfoItem () {
            taxRate = 0;
            DeliveryCharge = 0;
        }
    	public String ProductCode{get;set;}//商品コード
		public String ProductSubCode{get;set;}//サブ商品コード
		public String StockUnit{get;set;}//単位
		public String PriceNoTax{get;set;}//単価（税抜）
		public String Qty{get;set;}//数量
		public String Charge{get;set;}//手数料（税抜）
		public String DeliveryType{get;set;}//配送方法
		public Decimal Amount{get;set;}//金額（税抜）
		public Decimal taxRate{get;set;} // 消費税金額
		public Decimal DeliveryCharge{get;set;}// 配送料（税抜）
		public String PayType{get;set;}//利用できる決済方法
		public String ShopCode{get;set;} // 店舗コード
		public Decimal DeliveryDate{get;set;}// 配送可能日目安
        // 2018/03/21 5.10見積明細返却値追加の対応 BEGIN
        public String StaffPriceFlg{get;set;}//１：人材ではない、２：時給、３、日給
        public String RepeaterFlg{get;set;}//「1」:定期
        public String RepeaterPayType{get;set;}//定期購入の支払方式（年払：1,月払:2) 
        public String WorkContractStartDate{get;set;}//契約開始日（YYYYMMDD)
        public String WorkContractFilter{get;set;}//契約可能日(YYYYMMDD)と契約可能時間帯(HH:MM-HH:MM)
        public String WorkContractRange{get;set;}//契約可能日（期間範囲）(YYYYMMDD-YYYYMMDD) 
        public String WorkContractTerm{get;set;}//契約期間
        // 2018/03/21 5.10見積明細返却値追加の対応 END
		public String toXml() {
			String xml = '<OrderEstSetInfoItem>$_OrderEstSetInfoItem_$</OrderEstSetInfoItem>';
            String xmlBody = '';
            xmlBody+=joinTagXml('ProductCode',getExpoCode(ProductCode));
			xmlBody+=joinTagXml('ProductSubCode',ProductSubCode);
			xmlBody+=joinTagXml('StockUnit',StockUnit);
			xmlBody+=joinTagXml('PriceNoTax',PriceNoTax);
			xmlBody+=joinTagXml('Qty',Qty);
			xmlBody+=joinTagXml('Charge',Charge);
			xmlBody+=joinTagXml('DeliveryType',DeliveryType);
			xmlBody+=joinTagXml('PayType',PayType);
			xmlBody+=joinTagXml('Amount',CommUtils.nullToBlank(Amount));
			// 2018/03/21 5.10見積明細返却値追加の対応 BEGIN
			xmlBody+=joinTagXml('StaffPriceFlg',StaffPriceFlg);
			xmlBody+=joinTagXml('RepeaterFlg',RepeaterFlg);
			xmlBody+=joinTagXml('RepeaterPayType',RepeaterPayType);
			xmlBody+=joinTagXml('WorkContractStartDate',WorkContractStartDate);
			xmlBody+=joinTagXml('WorkContractFilter',WorkContractFilter);
			xmlBody+=joinTagXml('WorkContractRange',WorkContractRange);
			xmlBody+=joinTagXml('WorkContractTerm',WorkContractTerm);
			// 2018/03/21 5.10見積明細返却値追加の対応 END
            return xml.replace('$_OrderEstSetInfoItem_$',xmlBody);
		}
    }
    
    // ********************************
    // 3.1.商品情報取得
    // ********************************
    class XmlProductRest {
        public String NextPageProductCodes{get;set;}
        public String JobId{get;set;}
        public String toXml() {
            String xml = '<ResultInfo>$_ResultInfo_$</ResultInfo>';
            String xmlBody = '';
            xmlBody+=joinTagXml('NextPageProductCodes',NextPageProductCodes);
            xmlBody+=joinTagXml('JobId',JobId);
            return xml.replace('$_ResultInfo_$',xmlBody);
        }
    }
    class XmlProductInfo {
        public XmlProductInfo() {
            WorkContractFilterList = new List<String>();
            // 2018/01/09 商品属性情報を引き渡す対応 BEGIN
            ProductSubs = new List<ProductSub>();
            // 2018/01/09 商品属性情報を引き渡す対応 END
            // 2018/01/11 商品手数料情報を引き渡す対応 BEGIN
            ChargeSubs = new List<ChargeSub>();
            // 2018/01/11 商品手数料情報を引き渡す対応 END
        }
    	public String ProductCode{get;set;}//商品コード
		public String ProductName{get;set;}//商品名
		// 2018/01/09 商品属性情報を引き渡す対応 BEGIN
		//public String ProductSubCode{get;set;}//サブ商品コード
		public List<ProductSub> ProductSubs{get;set;}
		// 2018/01/09 商品属性情報を引き渡す対応 END
		public String Price{get;set;}//単価金額（税込）
		public String PriceNoTax{get;set;}//単価金額（税抜）
		public String SimpleDescription{get;set;}//商品簡易説明
		public String Description{get;set;}//商品説明
		public String Content{get;set;}//内容量
		public String Material{get;set;}//原材料
		public String Maker{get;set;}//メーカー名
		public String Origin{get;set;}//原産国名
		public String BestDateInfo{get;set;}//賞味期限
		public String SpecialMemo{get;set;}//注意事項
		public String DisplayDate{get;set;}//出品日
		public String Category{get;set;}//カテゴリ
		public String CategorySub{get;set;}//カテゴリサブ
		// 2018/01/09 商品属性情報を引き渡す対応 BEGIN
		//public String PictureNo{get;set;}//商品画像番号
		//public String PictureUrl{get;set;}//商品画像URL
		// 2018/01/09 商品属性情報を引き渡す対応 END
		public String PurchaseMaxNum{get;set;}//個人最大購買数量
		public String Charge{get;set;}//手数料
		// 2018/01/11 商品手数料情報を引き渡す対応 BEGIN
        public List<ChargeSub> ChargeSubs{get;set;}
        // 2018/01/11 商品手数料情報を引き渡す対応 END
		public String ShopCode{get;set;}//店舗コード
		public String ShopName{get;set;}//店舗名
		public String OrganizationId{get;set;}//施設組織ID
		public String StockCount{get;set;}//在庫数
		public String StockUnit{get;set;}//単位
		public String SalesStatus{get;set;}//販売状態
		public String RepeaterFlg{get;set;}//定期購入フラグ
		public String DiscountType{get;set;}//キャンペーン方式
		public String DiscountPrice{get;set;}//価格の値引き
		public String DiscountRate{get;set;}//価格の割引（パーセンテージ）
		public String LimitedFlg{get;set;}//期間限定フラグ
		public String ProductStatus{get;set;}//商品状態（新品/中古）
		public String OutsourceFlg{get;set;}//業務委託フラグ
		public String GoodFlg{get;set;}//おすすめフラグ
		public String ExhibitType{get;set;}//出品区分
		public String RentalFlg{get;set;}//レンタルフラグ
		public String DeliveryType{get;set;}//配送方法
		public String CompnayName{get;set;}//社名
		public String StaffName{get;set;}//名前
		public String WorkRole{get;set;}//役割
		public String Certificate{get;set;}//免許、資格
		public String WorkCondition{get;set;}//勤務条件
		public String WorkAddress{get;set;}//勤務地
		public String WorkContent{get;set;}//仕事内容
		public String WorkContract{get;set;}//契約条件
		public String WorkPayType{get;set;}//給料の支払い方式フラグ（日給/時給）
		public String WorkMinTime{get;set;}//労働時間下限（時単位）
		private List<String> WorkContractFilterList{get;set;}//契約可能日と契約可能時間帯（複数）
		public String WorkContractFile{get;set;}//契約書内容
		public String WorkInfo{get;set;}//業者情報
		public String WorkUnitPriceType{get;set;}//単価の単位（一式／月／日）
		public String WorkCanContractRange{get;set;}//契約可能日（期間範囲）
		public String WorkContractMixTerm{get;set;}//最小契約期間（月単位）
		public String WorkContractMaxTerm{get;set;}//最大契約期間（月単位）
        // 2019/04/10 EXPOのHR機能対応 WSQ BEGIN
        public String AreaCode{get;set;}//人材所属地域
        public String DispatchScope {get;set;} // 人材派遣期間
        public String WeekWorkDays {get;set;} // 人材勤務日数
        public String DayWorkBeginTime {get;set;} // 人材始業時間
        public String DayWorkEndTime {get;set;} // 人材終業時間
        public String OvertimeWorkHour {get;set;} // 人材残業時間
        public String OaSkills {get;set;} // 人材OAスキル
        public String EnglishSkills {get;set;} // 人材英語スキル
        public String OtherLanguagesSkills {get;set;} // 人材その他語学スキル
        public String AccountingSkills {get;set;} // 人材経理スキル
        public String LicenseQualification {get;set;} // 人材免許・資格
        public String OtherComplaints {get;set;} // 人材こだわり条件その他
        public String ExpoMinPay {get;set;} // 給料（下限）
        public String ExpoMaxPay {get;set;} // 給料（上限）
        public String WorkAssignEvents{get;set;}//既に割当済みイベント情報
        // 2019/04/10 EXPOのHR機能対応 WSQ END

		public String toXml() {
            String xml = '<ProductInfo>$_ProductInfo_$</ProductInfo>';
            String xmlBody = '';
            xmlBody+=joinTagXml('ProductCode',ProductCode);
			xmlBody+=joinTagXml('ProductName',ProductName);
			// 2018/01/09 商品属性情報を引き渡す対応 BEGIN
			//xmlBody+=joinTagXml('ProductSubCode',ProductSubCode);
			if (!ProductSubs.isEmpty()) {
			    String sub = '';
	            for (ProductSub s : ProductSubs) {
	               sub+=s.toXml();
	            }
	            xmlBody+=joinTagXml('ProductSubInfo',sub);
			}
            // 2018/01/09 商品属性情報を引き渡す対応 END
			xmlBody+=joinTagXml('Price',Price);
			xmlBody+=joinTagXml('PriceNoTax',PriceNoTax);
			xmlBody+=joinTagXml('SimpleDescription',SimpleDescription);
			xmlBody+=joinTagXml('Description',Description);
			xmlBody+=joinTagXml('Content',Content);
			xmlBody+=joinTagXml('Material',Material);
			xmlBody+=joinTagXml('Maker',Maker);
			xmlBody+=joinTagXml('Origin',Origin);
			xmlBody+=joinTagXml('BestDateInfo',BestDateInfo);
			xmlBody+=joinTagXml('SpecialMemo',SpecialMemo);
			xmlBody+=joinTagXml('DisplayDate',DisplayDate);
			xmlBody+=joinTagXml('Category',Category);
			xmlBody+=joinTagXml('CategorySub',CategorySub);
			// 2018/01/09 商品属性情報を引き渡す対応 BEGIN
			xmlBody+=joinTagXml('PictureNo','',true);
			xmlBody+=joinTagXml('PictureUrl','',true);
			// 2018/01/09 商品属性情報を引き渡す対応 END
			xmlBody+=joinTagXml('PurchaseMaxNum',PurchaseMaxNum);
			xmlBody+=joinTagXml('Charge',Charge);
			// 2018/01/11 商品手数料情報を引き渡す対応 BEGIN
			if (!ChargeSubs.isEmpty()) {
			    String sub = '';
	            for (ChargeSub s : ChargeSubs) {
	               sub+=s.toXml();
	            }
	            xmlBody+=joinTagXml('ChargeInfo',sub);
			}
            // 2018/01/11 商品手数料情報を引き渡す対応 END
			xmlBody+=joinTagXml('ShopCode',ShopCode);
			xmlBody+=joinTagXml('ShopName',ShopName);
			xmlBody+=joinTagXml('OrganizationId',OrganizationId);
			xmlBody+=joinTagXml('StockCount',StockCount);
			xmlBody+=joinTagXml('StockUnit',StockUnit);
			xmlBody+=joinTagXml('SalesStatus',SalesStatus);
			xmlBody+=joinTagXml('RepeaterFlg',RepeaterFlg);
			xmlBody+=joinTagXml('DiscountType',DiscountType);
			xmlBody+=joinTagXml('DiscountPrice',DiscountPrice);
			xmlBody+=joinTagXml('DiscountRate',DiscountRate);
			xmlBody+=joinTagXml('LimitedFlg',LimitedFlg);
			xmlBody+=joinTagXml('ProductStatus',ProductStatus);
			xmlBody+=joinTagXml('OutsourceFlg',OutsourceFlg);
			xmlBody+=joinTagXml('GoodFlg',GoodFlg);
			// 2018/02/04 パラメータ追加対応
			xmlBody+=joinTagXml('ExhibitType',ExhibitType);
			xmlBody+=joinTagXml('RentalFlg',RentalFlg);
			
			xmlBody+=joinTagXml('DeliveryType',DeliveryType);
			xmlBody+=joinTagXml('CompnayName',CompnayName);
			xmlBody+=joinTagXml('StaffName',StaffName);
			xmlBody+=joinTagXml('WorkRole',WorkRole);
			xmlBody+=joinTagXml('Certificate',Certificate);
			xmlBody+=joinTagXml('WorkCondition',WorkCondition);
			xmlBody+=joinTagXml('WorkAddress',WorkAddress);
			xmlBody+=joinTagXml('WorkContent',WorkContent);
			xmlBody+=joinTagXml('WorkContract',WorkContract);
			xmlBody+=joinTagXml('WorkPayType',WorkPayType);
			xmlBody+=joinTagXml('WorkMinTime',WorkMinTime);
			for (String s : WorkContractFilterList) {
                xmlBody+=joinTagXml('WorkContractFilter',s);
			}
			xmlBody+=joinTagXml('WorkContractFile',WorkContractFile);
			xmlBody+=joinTagXml('WorkInfo',WorkInfo);
			xmlBody+=joinTagXml('WorkUnitPriceType',WorkUnitPriceType);
			xmlBody+=joinTagXml('WorkCanContractRange',WorkCanContractRange);
			xmlBody+=joinTagXml('WorkContractMixTerm',WorkContractMixTerm);
			xmlBody+=joinTagXml('WorkContractMaxTerm',WorkContractMaxTerm);
            // 2019/04/10 EXPOのHR機能対応 WSQ BEGIN
            xmlBody+=joinTagXml('AreaCode',AreaCode);// 地域コード
            xmlBody+=joinTagXml('DispatchScope',DispatchScope);// 人材派遣期間
            xmlBody+=joinTagXml('WeekWorkDays',WeekWorkDays);// 人材勤務日数
            xmlBody+=joinTagXml('DayWorkBeginTime',DayWorkBeginTime);// 人材始業時間
            xmlBody+=joinTagXml('DayWorkEndTime',DayWorkEndTime);// 人材終業時間
            xmlBody+=joinTagXml('OvertimeWorkHour',OvertimeWorkHour);// 人材残業時間
            xmlBody+=joinTagXml('OaSkills',OaSkills);// 人材OAスキル
            xmlBody+=joinTagXml('EnglishSkills',EnglishSkills);// 人材英語スキル
            xmlBody+=joinTagXml('OtherLanguagesSkills',OtherLanguagesSkills);// 人材その他語学スキル
            xmlBody+=joinTagXml('AccountingSkills',AccountingSkills);// 人材経理スキル
            xmlBody+=joinTagXml('LicenseQualification',LicenseQualification);// 人材免許・資格
            xmlBody+=joinTagXml('OtherComplaints',OtherComplaints);// 人材こだわり条件その他
            xmlBody+=joinTagXml('ExpoMinPay',ExpoMinPay);// 給料（下限）
            xmlBody+=joinTagXml('ExpoMaxPay',ExpoMaxPay);// 給料（上限）
            xmlBody+=joinTagXml('WorkAssignEvents',WorkAssignEvents);// 給料（上限）
            
            // 2019/04/10 EXPOのHR機能対応 WSQ END
            return xml.replace('$_ProductInfo_$',xmlBody);
        }
    }
    // 2018/01/09 商品属性情報を引き渡す対応 BEGIN
    // SUB商品情報を格納する
    class ProductSub {
        public String ProductSubCode{get;set;}// 商品コード
        public String PropName{get;set;}//属性名
        public String Price{get;set;}//単価（税み）
        public String PriceNoTax{get;set;}//単価（税抜）
        public String StockCount{get;set;}//在庫数
        public String toXml() {
            String xml = '<ProductSub>$_ProductSub_$</ProductSub>';
            String xmlBody = '';
            xmlBody+=joinTagXml('ProductSubCode',ProductSubCode);
            xmlBody+=joinTagXml('PropName',PropName);
            xmlBody+=joinTagXml('Price',Price);
            xmlBody+=joinTagXml('PriceNoTax',PriceNoTax);
            xmlBody+=joinTagXml('StockCount',StockCount);
            return xml.replace('$_ProductSub_$',xmlBody);
        }
    }
    // 2018/01/09 商品属性情報を引き渡す対応 END
    // 2018/01/11 商品手数料情報を引き渡す対応 BEGIN
    // Charge商品情報を格納する
    class ChargeSub {
        public String MemberType{get;set;}// 会員種別
        public String Charge{get;set;}// 手数料%
        public String toXml() {
            String xml = '<ChargeSub>$_ChargeSub_$</ChargeSub>';
            String xmlBody = '';
            xmlBody+=joinTagXml('MemberType',MemberType);
            xmlBody+=joinTagXml('Charge',Charge);
            return xml.replace('$_ChargeSub_$',xmlBody);
        }
    }
    // 2018/01/11 商品手数料情報を引き渡す対応 END
    // 個人情報格納用
    class XmlUserInfo {
        public String IsManager{get;set;}//管理者フラグ
		public String MemberType{get;set;}//会員種別
		public String ShopCode{get;set;}//店舗コード
		public String ShopName{get;set;}//店舗名
		public String ShopAddress{get;set;}//店舗住所
		public String UserName{get;set;}// ユーザ氏名
		public String UserId{get;set;}//ユーザID
		public String TransactionAmout{get;set;}// 年間取引額
		public String NeedAmoutToUp{get;set;}// 会員種別アップグレード用の取引額差額
		public String SaveChargeAmount{get;set;}// アップグレード後の手数料値下げ目安
		// 2018/10/07 注文情報送信機能の対応 WSQ BEGIN
		public String UserEmail{get;set;}//該当ユーザのメールアドレス
		public String ShopPostNo{get;set;}//該当ユーザは勤務の店舗の郵便番号
		// 2018/10/07 注文情報送信機能の対応 WSQ END
        public String toXml() {
            String xml = '<UserInfo>$_UserInfoBody_$</UserInfo>';
            String xmlBody = '';
            xmlBody+=joinTagXml('IsManager',IsManager);
            xmlBody+=joinTagXml('MemberType',MemberType);
            xmlBody+=joinTagXml('ShopCode',ShopCode);
            xmlBody+=joinTagXml('ShopName',ShopName);
            xmlBody+=joinTagXml('ShopAddress',ShopAddress);
            xmlBody+=joinTagXml('UserName',UserName);
            xmlBody+=joinTagXml('UserId',UserId);
            xmlBody+=joinTagXml('TransactionAmout',TransactionAmout);
            xmlBody+=joinTagXml('NeedAmoutToUp',NeedAmoutToUp);
            xmlBody+=joinTagXml('SaveChargeAmount',SaveChargeAmount);
            // 2018/10/07 注文情報送信機能の対応 WSQ BEGIN
            xmlBody+=joinTagXml('UserEmail',UserEmail);
            xmlBody+=joinTagXml('ShopPostNo',ShopPostNo);
            // 2018/10/07 注文情報送信機能の対応 WSQ END
            return xml.replace('$_UserInfoBody_$',xmlBody);
        }
    }
    //**************************************************
    // 0. 共通リクエスト情報
    //**************************************************
    class CommonRequest {
        // majornoキー
        String majorno{get;set;}
        // minornoキー
        String minorno{get;set;}
        // 2018/09/12 EXPOのSITE機能対応 BEGIN
        String subOrgId{get;set;}
        // 2018/09/12 EXPOのSITE機能対応 END
        CommonRequest(Dom.XmlNode comm) {
            if (comm == null) return;
            majorno = getChildElementByName(comm, 'majorno');
            minorno = getChildElementByName(comm, 'minorno');
            // 2018/09/12 EXPOのSITE機能対応 BEGIN
            subOrgId = getChildElementByName(comm, 'suborgid');
            // 2018/09/12 EXPOのSITE機能対応 END
        }
        // 2018/09/12 EXPOのSITE機能対応 BEGIN
        boolean isExpoSite() {
        	// TRUEの場合,EXPOサイトから呼び出す
        	return (!CommUtils.isBlank(subOrgId));
        }
        // 2018/09/12 EXPOのSITE機能対応 END
        // SUB機能確認[3.1.商品情報取得]
        boolean isGetProductMst() {
            return (majorno == '1' && minorno == '1');
        }
        // SUB機能確認[3.2.個人情報取得]
        boolean isGetUserInfonMst() {
            return (majorno == '1' && minorno == '2');
        }
        // SUB機能確認[3.3.商品購入者一覧取得]
        boolean isGetAllBuyer() {
            return (majorno == '1' && minorno == '3');
        }
        // 2018/12/15 EXPO機能追(3.4店舗情報取得)
        boolean isGetShopInfo() {
            return (majorno == '1' && minorno == '4');
        }
        // SUB機能確認[4.1.在庫取得]
        boolean isGetProductStock() {
            return (majorno == '2' && minorno == '1');
        }
        // SUB機能確認[5.1.注文確定]
        boolean isSetOrderInfo() {
            return (majorno == '3' && minorno == '1');
        }
        // SUB機能確認[5.3.注文キャンセル]
        boolean isCancelOrderInfo() {
            return (majorno == '3' && minorno == '3');
        }
        // SUB機能確認[5.4.注文履歴取得]
        boolean isGetOrderHistory() {
            return (majorno == '3' && minorno == '4');
        }
        // 2018/04/24 5.5.定期注文確定、5.7.定期注文キャンセル、5.8.定期注文履歴取得　新規追加 BEGIN
        // SUB機能確認[5.5.定期注文確定]
        boolean isRepSetOrderInfo() {
            return (majorno == '3' && minorno == '5');
        }
        // SUB機能確認[5.7.定期注文キャンセル]
        boolean isRepCancelOrderInfo() {
            return (majorno == '3' && minorno == '7');
        }
        // SUB機能確認[5.8.定期注文履歴取得]
        boolean isRepGetOrderHistory() {
            return (majorno == '3' && minorno == '8');
        }
        // 2018/04/24 5.5.定期注文確定、5.7.定期注文キャンセル、5.8.定期注文履歴取得　新規追加 END
        // SUB機能確認[5.9.決済情報取得]
        boolean isGetPayInfo(){
        	return (majorno == '3' && minorno == '9');
        }
        // SUB機能確認[5.10.注文見積情報取得]
        boolean isGetOrderEstInfo() {
            return (majorno == '3' && minorno == '10');
        }
        // SUB機能確認[6.1.推奨商品取得]
        boolean isGetLinkProdInfo(){
        	return (majorno == '4' && minorno == '1');
        }
        // SUB機能確認[7.1.Notification]
        boolean isSetNotifyInfo(){
        	return (majorno == '5' && minorno == '1');
        }
        // SUB機能確認[8.1.問い合わせ送信]
        boolean isSetCaseInfo() {
            return (majorno == '6' && minorno == '1');
        }
        // 2019/04/15 EXPOの10.1.稼働率分析情報を取得（稼働率・ADR・RevPer・客単価） WSQ BEGIN
        // SUB機能確認[10.1.稼働率分析情報を取得]
        boolean isSetAnalytics() {
            return (majorno == '8' && minorno == '1');
        }
        // 2019/04/15 EXPOの10.1.稼働率分析情報を取得（稼働率・ADR・RevPer・客単価） WSQ END
    }
    //**************************************************
    // 3.1.商品情報取得[引き渡す情報を受信する]
    //**************************************************
    class MasterProdReq {
        public MasterProdReq() {}
        public MasterProdReq(Dom.XmlNode root) {

            ProductCodes = new List<String>();
            // 抽出条件
            Dom.XmlNode extrField = root.getChildElement('ExtractionCondition', null);
            if (extrField != null) {
                Category = getChildElementByName(extrField, 'Category');
                CategorySub = getChildElementByName(extrField, 'CategorySub');
                PriceDurationFrom = getChildElementByName(extrField, 'PriceDurationFrom');
                PriceDurationTo = getChildElementByName(extrField, 'PriceDurationTo');
                DisplayDurationFrom = getChildElementByName(extrField, 'DisplayDurationFrom');
                DisplayDurationTo = getChildElementByName(extrField, 'DisplayDurationTo');
                //SearchKeys = getChildElementByName(extrField, 'SearchKeys');
                String wkProductCodes = getChildElementByName(extrField, 'ProductCodes');
                if (!CommUtils.isBlank(wkProductCodes)) {
                    for (String c : wkProductCodes.split(',')) {
                        if (CommUtils.isBlank(c)) continue;
                        String[] sc = c.split('-');
                        if (sc.size() > 1) ProductCodes.add(sc[1]);
                    } 
                }
                // JOBID
                JobId = getChildElementByName(extrField, 'JobId');
            }
            
        }
        // 抽出条件
        /*
    	カテゴリ                                            
		カテゴリサブ                                          
		商品価額FROM                                            
		商品価額TO                                          
		出品日FROM                                         
		出品日TO                                           
		検索キー                                            
		商品コード 
		*/
		String Category{get;set;}
		String CategorySub{get;set;}
		String PriceDurationFrom{get;set;}
		String PriceDurationTo{get;set;}
		String DisplayDurationFrom{get;set;}
		String DisplayDurationTo{get;set;}
		//String SearchKeys{get;set;}
		List<String> ProductCodes{get;set;}
		String JobId{get;set;}    // バッチ処理のジョブID
        // 有効性チェックを行う
        public Boolean validata() {
            return true;
        }
    }
    class MasterUserReq {
        public MasterUserReq(Dom.XmlNode root) {
            // 抽出条件
            Dom.XmlNode extrField = root.getChildElement('ExtractionCondition', null);
            if (extrField != null) {
                uiUserId = getChildElementByName(extrField, 'UserId');
                // UIのID→SFのIDに変換する
                String[] wkUserId = uiUserId.split('-');
                sfUserId =  CommUtils.nullToBlank(wkUserId.size() > 1 ? wkUserId[1] : wkUserId[0]);
            }
        }
        String uiUserId{get;set;}
        String sfUserId{get;set;}
        //  有効性チェック
        public Boolean validata() {
            // 必須チェック
            if (CommUtils.isBlank(uiUserId)) {
                throw new CommException(MSG_E0001);
            }
            return true;
        }
    }
    
    //**************************************************
    // 5.1.注文確定[引き渡す情報を受信する]
    //**************************************************
    class OrderInfoReq {
        public OrderInfoReq(Dom.XmlNode root) {
            // 梱包毎の注文情報を格納用配列
            OrderSetInfoList = new list<OrderSetInfo>();
            // 注文情報
            Dom.XmlNode orderInfoField = root.getChildElement('OrderInfoList', null);
            if (orderInfoField != null) {
                // 該当注文の詳細
                UserId = getChildElementByName(orderInfoField, 'UserId');// 購入者USERID
                OrderAmountIncTax = getChildElementByName(orderInfoField, 'OrderAmountIncTax');
                OrderNo = getChildElementByName(orderInfoField, 'OrderNo');//注文番号[AWS側に発行のパラメータ]
                ShippingType = getChildElementByName(orderInfoField, 'ShippingType');//発送方法、1: 順次配送 (デフォルト) 、2: 一括配送 
                // 梱包毎の注文数分繰り返し
                for (Dom.XmlNode ordSetNode : orderInfoField.getChildElements()) {
                    String nodeName = ordSetNode.getName();
                    if (nodeName != 'OrderSetInfo') continue;
                    // 梱包毎の注文情報の初期化
                    OrderSetInfo orderSetInfo = new OrderSetInfo();
                    // 2018/05/01 梱包セット識別情報追加（DBへ反映しない、RELAY-SERVERやり取り用 BEGIN
                    orderSetInfo.OrderSetCode = getChildElementByName(ordSetNode,'OrderSetCode');
                    // 2018/05/01 梱包セット識別情報追加（DBへ反映しない、RELAY-SERVERやり取り用 END
                    // 梱包毎の注文情報の共通部分
                    orderSetInfo.ShopCode = getChildElementByName(ordSetNode,'ShopCode');
                    orderSetInfo.ShopName = getChildElementByName(ordSetNode,'ShopName');
                    orderSetInfo.OrganizationId = getChildElementByName(ordSetNode,'OrganizationId');
                    orderSetInfo.SetDeliveryCharge = getChildElementByName(ordSetNode,'SetDeliveryCharge');
                    orderSetInfo.SetDeliveryDate = getChildElementByName(ordSetNode,'SetDeliveryDate');
                    orderSetInfo.SetDeliveryTime = getChildElementByName(ordSetNode,'SetDeliveryTime');
                    orderSetInfo.SetDeliveryType = getChildElementByName(ordSetNode,'SetDeliveryType');
                    orderSetInfo.SetDeliveryAddress = getChildElementByName(ordSetNode,'SetDeliveryAddress');
                    orderSetInfo.SetOrderTitle = getChildElementByName(ordSetNode,'SetOrderTitle');
                    orderSetInfo.SetAmountTax = getChildElementByName(ordSetNode,'SetAmountTax');
                    orderSetInfo.SetAmount = getChildElementByName(ordSetNode,'SetAmount');
                    orderSetInfo.PayType = getChildElementByName(ordSetNode,'PayType');
                    orderSetInfo.PayDetail = getChildElementByName(ordSetNode,'PayDetail');
                    // 該当梱包内容の商品情報リスト
	                for (Dom.XmlNode ordItemNode : ordSetNode.getChildElements()) {
	                    String ordItemNodeName = ordItemNode.getName();
	                    if(!ordItemNodeName.equalsIgnoreCase('OrderSetInfoItem')) continue;
	                    // 商品情報明細毎の引き渡す情報を格納する
                        OrderSetInfoItem orderInfoItem = new OrderSetInfoItem(); 
                        orderInfoItem.ProductCode = convertProductCd(getChildElementByName(ordItemNode,'ProductCode'));
                        orderInfoItem.ProductSubCode = getChildElementByName(ordItemNode,'ProductSubCode');
                        orderInfoItem.StockUnit = getChildElementByName(ordItemNode,'StockUnit');
                        orderInfoItem.Qty = getChildElementByName(ordItemNode,'Qty');
                        orderInfoItem.PriceNoTax = getChildElementByName(ordItemNode,'PriceNoTax');
                        orderInfoItem.Charge = getChildElementByName(ordItemNode,'Charge');
                        orderInfoItem.StaffPriceFlg = getChildElementByName(ordItemNode,'StaffPriceFlg');
                        orderInfoItem.RepeaterFlg = getChildElementByName(ordItemNode,'RepeaterFlg');
                        orderInfoItem.RepeaterPayType = getChildElementByName(ordItemNode,'RepeaterPayType');
                        orderInfoItem.WorkContractStartDate = getChildElementByName(ordItemNode,'WorkContractStartDate');
                        orderInfoItem.WorkContractFilter = getChildElementByName(ordItemNode,'WorkContractFilter');
                        orderInfoItem.WorkContractRange = getChildElementByName(ordItemNode,'WorkContractRange');
                        orderInfoItem.WorkContractTerm = getChildElementByName(ordItemNode,'WorkContractTerm');
                        orderInfoItem.Amount = getChildElementByName(ordItemNode,'Amount');
                        // 2019/12/20 5.1.注文確定、5.4.注文履歴取得、5.5.定期注文確定、5.8.定期注文履歴取得　メモ欄情報追加 WSQ BEGIN
                        orderInfoItem.Memo = getChildElementByName(ordItemNode,'Memo');
                        // 2019/12/20 5.1.注文確定、5.4.注文履歴取得、5.5.定期注文確定、5.8.定期注文履歴取得　メモ欄情報追加 WSQ END
                        orderSetInfo.OrderSetInfoItemList.add(orderInfoItem);
	                }
	                OrderSetInfoList.add(orderSetInfo);
                }
            }
        }
        // 抽出条件
		String UserId{get;set;} // 購入者ユーザーID（シート：コード体系参照）
		String OrderAmountIncTax{get;set;}  // 合計金額
		String OrderNo{get;set;}  // 注文番号 (AWSのRelayサーバー作成)
		String ShippingType{get;set;} // 店舗別の商品発送方法
		// 該当施設の該当注文の全て梱包情報リストを格納する
		list<OrderSetInfo> OrderSetInfoList{get;set;}
        //  有効性チェック
        public Boolean validata() {
            // 必須チェック
            if (CommUtils.isBlank(UserId)) {
                throw new CommException(MSG_E0001);
            }
            return true;
        }
    }
    // 梱包毎の注文情報
    class OrderSetInfo{
        public OrderSetInfo() {
            OrderSetInfoItemList = new List<OrderSetInfoItem>();
        }
    	/*
    	店舗コード											
		店舗名											
		施設組織ID											
		配送料											
		配送希望日											
		配送希望時刻											
		配送方法											
		配送住所											
		配送先宛名											
		消費税											
		梱包毎合計金額(税込)											
		決済方式											
		決済詳細情報*/
    	String ShopCode{get;set;}
		String ShopName{get;set;}
		String OrganizationId{get;set;}
		String SetDeliveryCharge{get;set;}
		String SetDeliveryDate{get;set;}
		String SetDeliveryTime{get;set;}
		String SetDeliveryType{get;set;}
		String SetDeliveryAddress{get;set;}
		String SetOrderTitle{get;set;}
		String SetAmountTax{get;set;}
		String SetAmount{get;set;}
		String PayType{get;set;}
		String PayDetail{get;set;}
		String OrderSetCode{get;set;}// 2018/05/01 梱包セット識別情報追加（DBへ反映しない、RELAY-SERVERやり取り用
		// 梱包毎の商品明細情報
		List<OrderSetInfoItem> OrderSetInfoItemList{get;set;}
    }
    // 商品情報
    class OrderSetInfoItem{
    	/*
    	商品コード											
		サブ商品コード											
		単位											
		数量											
		単価金額（税抜）											
		手数料	
		メモ(Memo 2019/12/20追加)										
		人材単価フラグ											
		定期購入フラグ											
		定期払い方式											
		契約開始日（契約系利用）											
		契約日と契約時間帯											
		契約期間											
		期間											
		合計											
		*/
		String ProductCode{get;set;}
		String ProductSubCode{get;set;}
		String StockUnit{get;set;}
		String Qty{get;set;}
		String PriceNoTax{get;set;}
		String Charge{get;set;}
		String Memo{get;set;} // 2019/12/20新規追加
		String StaffPriceFlg{get;set;}
		String RepeaterFlg{get;set;}
		String RepeaterPayType{get;set;}
		String WorkContractStartDate{get;set;}
		String WorkContractFilter{get;set;}
		String WorkContractRange{get;set;}
		String WorkContractTerm{get;set;}
		String Amount{get;set;}
    }
    //**************************************************
    // 5.3.注文キャンセル[引き渡す情報を受信する]
    //**************************************************
    class CanOrderInfoReq{
    	public CanOrderInfoReq(Dom.XmlNode root){
    		// 抽出条件
            Dom.XmlNode orderInfoField = root.getChildElement('OrderInfo', null);
            if (orderInfoField != null) {
                OrderNo = getChildElementByName(orderInfoField, 'OrderNo');
                Memo = getChildElementByName(orderInfoField, 'Memo');  
            }
    	}
    	String OrderNo{get;set;}
    	String Memo{get;set;}
    	// 
        public Boolean validata() {
            // オーダ番号存在チェック
            if (CommUtils.isBlank(OrderNo)) {
                throw new CommException(MSG_E0001 + ':'+this);
            }
            if (Memo.length() > 255) {
                throw new CommException(MSG_E0001 + ':'+this);
            }
            return true;
        }
    }
    class CanOrderInfoRep {
        public CanOrderInfoRep() {
            subList = new List<CanOrderSubInfoRep>();
        }
        String OrderNo{get;set;}
        List<CanOrderSubInfoRep> subList{get;set;}
        public String toXml() {
            String xml = '<OrderInfo>$_OrderInfo_$</OrderInfo>';
            String xmlBody = '';  
            xmlBody+=joinTagXml('OrderNo',OrderNo);
            for (CanOrderSubInfoRep sub : subList) {
                xmlBody+=sub.toXml();
            }
            return xml.replace('$_OrderInfo_$',xmlBody);
        }
    }
    class CanOrderSubInfoRep {
        Boolean OrderStatus{get;set;}
        String ErrorCode{get;set;}
        String ErrorMessage{get;set;}
        String ShopName{get;set;}
        public String toXml() {
            String xml = '<OrderSetInfo>$_OrderSetInfo_$</OrderSetInfo>';
            String xmlBody = '';
            String status = (OrderStatus == null || OrderStatus == false ? '0' : '1');
            xmlBody+=joinTagXml('OrderStatus',status);
            xmlBody+=joinTagXml('ErrorCode',ErrorCode);
            xmlBody+=joinTagXml('ErrorMessage',ErrorMessage);
            xmlBody+=joinTagXml('OrganizationId',ORGID);
            xmlBody+=joinTagXml('ShopName',shopName);
            return xml.replace('$_OrderSetInfo_$',xmlBody);
        }
    }
    //**************************************************
    // 5.10.注文見積情報取得[引き渡す情報を受信する]
    //**************************************************
    class OrderEstInfoReq {
        public OrderEstInfoReq(Dom.XmlNode root) {
            // 発送方法
            ShippingType = '2';
            // 注文見積情報格納する
            orderEstLst = new list<OrderEstInfo>();
            // 注文見積情報
            for (Dom.XmlNode node : root.getChildElements()) {
                String nodeName = node.getName();
            	if(nodeName.equalsIgnoreCase('OrderEstInfo')){
            	    // 注文見積明細単位情報格納
            		OrderEstInfo orderEstInfo = new OrderEstInfo();
        			orderEstInfo.ProductCode = convertProductCd(getChildElementByName(node,'ProductCode'));
        			// 商品コードが未存在場合、処理SKIP
        			if (CommUtils.isBlank(orderEstInfo.ProductCode)) continue;
					orderEstInfo.ProductSubCode = getChildElementByName(node,'ProductSubCode');
					orderEstInfo.StockUnit = getChildElementByName(node,'StockUnit');
					orderEstInfo.Qty = getChildElementByName(node,'Qty');
					orderEstInfo.PriceNoTax = getChildElementByName(node,'PriceNoTax');
					orderEstInfo.Charge = getChildElementByName(node,'Charge');
					orderEstInfo.DeliveryType = getChildElementByName(node,'DeliveryType');
					orderEstInfo.StaffPriceFlg = getChildElementByName(node,'StaffPriceFlg');
					orderEstInfo.RepeaterFlg = getChildElementByName(node,'RepeaterFlg');
					orderEstInfo.RepeaterPayType = getChildElementByName(node,'RepeaterPayType');
					orderEstInfo.WorkContractStartDate = getChildElementByName(node,'WorkContractStartDate');
					orderEstInfo.WorkContractFilter = getChildElementByName(node,'WorkContractFilter');
					orderEstInfo.WorkContractRange = getChildElementByName(node,'WorkContractRange');
					orderEstInfo.WorkContractTerm = getChildElementByName(node,'WorkContractTerm');
					orderEstInfo.Amount = getChildElementByName(node,'Amount');
        			orderEstLst.add(orderEstInfo);
            	} else if (nodeName.equalsIgnoreCase('ExtractionCondition')){
            	    String strShippingType = getChildElementByName(node,'ShippingType');
            	    if (strShippingType == '2') shippingType = strShippingType;
            	    // 配達着地の都道府県
            	    destinationState = getChildElementByName(node,'DestinationState');
            	}
            }
        }
        // 発送方法
        String shippingType{get;set;}
        // 発送目的地
        String destinationState{get;set;}
        // 注文見積情報格納する
		list<OrderEstInfo> orderEstLst{get;set;}
    }
    // 注文見積情報
    class OrderEstInfo{
     	// 抽出条件
        /*
	    商品コード											
		サブ商品コード											
		単位											
		数量											
		単価金額（税抜）											
		手数料											
		配送方法											
		人材単価フラグ											
		定期購入フラグ											
		定期払い方式											
		契約開始日（契約系利用）											
		契約日と契約時間帯											
		契約期間											
		期間											
		合計											
		*/
		String ProductCode{get;set;}
		String ProductSubCode{get;set;}
		String StockUnit{get;set;}
		String Qty{get;set;}
		String PriceNoTax{get;set;}
		String Charge{get;set;}
		String DeliveryType{get;set;}
		String StaffPriceFlg{get;set;}
		String RepeaterFlg{get;set;}
		String RepeaterPayType{get;set;}
		String WorkContractStartDate{get;set;}
		String WorkContractFilter{get;set;}
		String WorkContractRange{get;set;}
		String WorkContractTerm{get;set;}
		String Amount{get;set;}
    }
    
    /**
    * 8.1.問い合わせ送信
    **/
    @TestVisible private static string caseinfo(String reqXml) {
        // 商品情報取得
        log.write_method_start('setcaseinfo');
        log.write_log('reqXml：'+reqXml);
        String retStr = '';
        try {
            // 取得のリクエストXMLを会席する
            Dom.Document doc = new Dom.Document();
            doc.load(reqXml);
            Dom.XMLNode rootNode = doc.getRootElement();

            // 共通条件を取得する
            commReq = new CommonRequest(rootNode.getChildElement('CommonRequest', null));
            // リクエスト情報解析する
            // 8.1.問い合わせ送信
            if (commReq.isSetCaseInfo()) {
                retStr = setCaseInfo(rootNode);
            } 
        } catch (Exception e) {
            // エラー処理 
            WS_ResultInfo ret = new WS_ResultInfo('E9999',MSG_E9999);
            
            String rsXmltemp = '<CaseInfoRS><CommonResponse>$$_CommonResponse_$$</CommonResponse></CaseInfoRS>';
            retStr = rsXmltemp.replace('$$_CommonResponse_$$',ret.toXml());
                            
            log.write_error(e.getStackTraceString());
            log.write_error(e.getMessage());
        }
        log.write_method_end();
        // 2017/12/06 性能改善 BEGIN
        CommLogUtils.saveLogToDb(log.getAllLog(),CommLogUtils.LogType.EXPO,1000);
        return retStr;
    }
    /**検証要XML[PACKAGE環境]
    /services/apexrest/ps/exposervice/V1/caseinfo
    <CaseInfoRQ>
        <CommonRequest>
            <majorno>6</majorno>
            <minorno>1</minorno>
        </CommonRequest>
        <CaseInfo>
            <ProductCode>00Dd0000000dBJC-1105</ProductCode>
            <CaseTitle>商品在庫調達期間の確認</CaseTitle>
            <CaseContent>11/20日、該当商品は３００件注文しましたが、該当商品は４０件再調達が必要ですが、いつまで配達できますか</CaseContent>
            <CaseDateTime>20180223121421</CaseDateTime>
            <CaseOwnerUserId>00Dp00000000hip-00510000001wl0B</CaseOwnerUserId>
            <OrderNo></OrderNo>
            <CaseNo></CaseNo>
            <CaseOwnerShopName></CaseOwnerShopName>
            <CaseOwnerUserName></CaseOwnerUserName>
        </CaseInfo>
    </CaseInfoRQ>
    **/
    @TestVisible private static string setCaseInfo(Dom.XMLNode rootNode) {
    	// 処理結果情報を格納する
        WS_ResultInfo ret = new WS_ResultInfo();
        // 検索結果集計情報
        XmlCaseInfoRest res = new XmlCaseInfoRest();   
        // 引き渡すパラメータ情報
        CaseInfoReq req = null;
        // DB情報SAVEPOINT
        Savepoint sp = Database.setSavepoint();	
        try {
        	// 引き渡すパラメータを解析する
	        req = new CaseInfoReq(rootNode);
            // 有効チェック
            req.validata();
	        // ==========================
        	// 問い合わせ情報を格納する
        	// ==========================
        	CaseInfo__c newCase = new CaseInfo__c();
	        //通过商品code取得商品Id
            Map<String,id> accCodeToIdMap = new Map<String,id>();
            String productCode = CommUtils.nullToblank(req.ProductCode);
            for (AccountMaster__c acc : [select Id,Field3__c from AccountMaster__c where Field3__c =:productCode]){
            	accCodeToIdMap.put(acc.Field3__c,acc.id);
            }
            if (accCodeToIdMap.isEmpty()) {
                throw new CommException('該当商品情報が見つかりません:'+getExpoCode(productCode));
            }
	        //通过注文番号取得注文Id
	        Map<String,id> orderNoToIdMap = new Map<String,id>();
	        String orderNo = CommUtils.nullToblank(req.OrderNo);
	        if (!CommUtils.isBlank(orderNo)) {
	            for (Order__c acc : [select Id,OrderNo__c from Order__c where OrderNo__c =:orderNo limit 1]){
	            	orderNoToIdMap.put(acc.OrderNo__c,acc.id);
	            }
	            // TODO ERROR MESSAGE ALERT
	            if (orderNoToIdMap.isEmpty()) {
	                throw new CommException('注文番号が見つかりません:'+orderNo);
	            }
            }
	        //通过caseNo查询该問い合わせ情報是否存在
	        Map<String,id> casNoToIdMap = new Map<String,id>();
	        String caseNo = CommUtils.nullToblank(req.CaseNo);
	        if (!CommUtils.isBlank(caseNo)) {
	            for (CaseInfo__c cas : [select Id,Name from CaseInfo__c where Name =:caseNo]){
	            	casNoToIdMap.put(cas.Name,cas.id);
	            }
                // TODO ERROR MESSAGE ALERT
                if (casNoToIdMap.isEmpty()) {
                    throw new CommException('問い合わせ番号が見つかりません:'+caseNo);
                }
        	}
            // 新規問い合わせ情報を登録する
            newCase.AccountMasterRef__c = accCodeToIdMap.get(productCode);//商品コード
            newCase.CaseTitle__c = CommUtils.nullToblank(req.CaseTitle);//問い合わせタイトル
            newCase.CaseContent__c = CommUtils.nullToblank(req.CaseContent);//問い合わせ詳細内容
            newCase.CaseDateTime__c = stringToDateTime(req.CaseDateTime);//問い合わせ日時
            if (newCase.CaseDateTime__c == null) newCase.CaseDateTime__c = System.now();
System.debug(loggingLevel.info, 'newCase.CaseDateTime__c='+newCase.CaseDateTime__c);
            newCase.CaseUserId__c = CommUtils.nullToblank(req.CaseOwnerUserId);//問い合わせユーザID
            //newCase.CaseNo__c = caseNo;//注文番号
            if(orderNoToIdMap.containsKey(orderNo)) newCase.OrderRef__c = orderNoToIdMap.get(orderNo);//注文
        	if(casNoToIdMap.containsKey(caseNo)) newCase.ParCaseRef__c = casNoToIdMap.get(caseNo);//問い合わせ
        	// 問い合わせの店舗とユーザ名
        	newCase.CaseShopName__c = req.CaseOwnerShopName;
        	newCase.CaseUserName__c = req.CaseOwnerUserName;
        	//生成問い合わせ数据
        	insert newCase;
            //返回問い合わせケース番号
            if (CommUtils.isBlank(caseNo)) {
	            List<CaseInfo__c> newCas = [select name from CaseInfo__c where id = :newCase.Id];
	            res.CaseNo = newCas[0].Name;
            } else {
                res.CaseNo = caseNo;
            }
        } catch (CommException ex) {
            // 予想以外の異常が発生する場合
            ret = new WS_ResultInfo('E0801',ex.getMessage());
        } catch (Exception e) {
            // RollBackp
            DataBase.rollBack(sp);
            // 予想以外の異常が発生する場合
            ret = new WS_ResultInfo('E9999',MSG_E9999);
            System.debug(e.getMessage());
            log.write_error(e.getStackTraceString());
            log.write_error(e.getMessage());
        }
        // 処理結果作成する
        String rsXmltemp = '<CaseInfoRS><CommonResponse>$$_CommonResponse_$$</CommonResponse><CaseInfo>$$_CaseInfo_$$</CaseInfo></CaseInfoRS>';
        return rsXmltemp.replace('$$_CommonResponse_$$',ret.toXml())
                        .replace('$$_CaseInfo_$$',res.toXml());
    }
    
    //**************************************************
    // 8.1.問い合わせ送信[引き渡す情報を受信する]
    //**************************************************
    class CaseInfoReq {
        public CaseInfoReq(Dom.XmlNode root) {
        	// 問い合わせ情報
            Dom.XmlNode caseInfoField = root.getChildElement('CaseInfo', null);
            if (caseInfoField != null) {
            	ProductCode = convertProductCd(getChildElementByName(caseInfoField,'ProductCode'));
				CaseTitle = getChildElementByName(caseInfoField,'CaseTitle');
				CaseContent = getChildElementByName(caseInfoField,'CaseContent');
				CaseDateTime = getChildElementByName(caseInfoField,'CaseDateTime');
				CaseOwnerUserId = getChildElementByName(caseInfoField,'CaseOwnerUserId');
				OrderNo = getChildElementByName(caseInfoField,'OrderNo');
				CaseNo = getChildElementByName(caseInfoField,'CaseNo');
				CaseOwnerShopName = getChildElementByName(caseInfoField,'CaseOwnerShopName');
				CaseOwnerUserName = getChildElementByName(caseInfoField,'CaseOwnerUserName');
            }
        }
        // 問い合わせ情報
        /*商品コード											
		問い合わせタイトル											
		問い合わせ詳細内容											
		問い合わせ日時											
		問い合わせユーザID											
		注文番号											
		問い合わせケース番号											
		*/
        String ProductCode{get;set;}
		String CaseTitle{get;set;}
		String CaseContent{get;set;}
		String CaseDateTime{get;set;}
		String CaseOwnerUserId{get;set;}
		String OrderNo{get;set;}
		String CaseNo{get;set;}
		String CaseOwnerShopName{get;set;}
		string CaseOwnerUserName{get;set;}
        // 有効性チェックを行う
        public Boolean validata() {
            // 必須チェック
            if (CommUtils.isBlank(ProductCode) ||
                CommUtils.isBlank(CaseTitle) ||
                CommUtils.isBlank(CaseContent) ||
                CommUtils.isBlank(CaseDateTime) ||
                CommUtils.isBlank(CaseOwnerUserId)) {
                throw new CommException(MSG_E0001 + ':' + this);
            }
            return true;
        }
    }
    
    // ********************************
    // 8.1.問い合わせ送信
    // ********************************
    class XmlCaseInfoRest {
        public String CaseNo{get;set;}
        public String toXml() {
            String xml = '<CaseNo>$_CaseNo_$</CaseNo>';
            return xml.replace('$_CaseNo_$', CommUtils.nullToblank(CaseNo));
        }
    }
	
    // 商品情報取得 API / 個人情報取得 API
    // 2019/04/15 EXPOの10.1.稼働率分析情報を取得（稼働率・ADR・RevPer・客単価）/analytics追加
    enum SERVICE_NAME{getmasterinfo,getproductstocklist,orderinfo,getlinkproductlist,notifyinfo,caseinfo,analytics}
    // XMLタグ作成する
    private static String joinTagXml(String tagKey, String val) {
        return joinTagXml(tagKey, val, false);
    }
    private static String joinTagXml(String tagKey, String val, Boolean masttag) {
        return (CommUtils.isBlank(val) ? (masttag ? ('<'+tagKey+'></'+tagKey+'>') : '') : '<'+tagKey+'>'+val+'</'+tagKey+'>');
    }
    // 会計商品コード取得する
    private static String convertProductCd(String c) {
    	String[] sc = CommUtils.nullToBlank(c).split('-');
        if (sc.size() > 1) return sc[1];
        else return null;
    }
    // 会計商品コード取得する
    private static String convertUserId(String c) {
        String[] sc = CommUtils.nullToBlank(c).split('-');
        if (sc.size() > 1) return sc[1];
        else return null;
    }
    // XMLのNODE処理関数
    private static string getChildElementByName(Dom.XMLNode parentNode,String elementName){
        if (parentNode == null) return '';
        Dom.XMLNode childrenNode = parentNode.getChildElement(elementName, null);
        return getChildElementValue(childrenNode);
    }
    private static String getChildElementValue(Dom.XMLNode childNode) {
        if (childNode == null) return '';
        return CommUtils.nullToBlank(childNode.getText());
    }
    private static String getDateString(Date dt) {
        return (DateTime.newInstance(dt.year(),dt.month(),dt.day())).format('yyyyMMdd');
    }
    private static final String MSG_E0001 = '抽出条件設定不正';
    private static final String MSG_E0003 = '指定したユーザの組織情報を見つかりません。';
    private static final String MSG_E9999 = 'システムエラーが発生しました。';
    
    private static DateTime stringToDateTime(String str){
        if (CommUtils.isBlank(str) || str.length() != 14) return null;
    	String dt = str.substring(0, 8);
    	String tmHH = str.substring(8, 10);
    	String tmMM = str.substring(10, 12);
    	String tmSS = str.substring(12, 14);
//System.debug(loggingLevel.info, 'dt='+dt);	   
//System.debug(loggingLevel.info, 'tmHH='+tmHH);	
//System.debug(loggingLevel.info, 'tmMM='+tmMM);  
//System.debug(loggingLevel.info, 'tmSS='+tmSS);   
        try {  
	    	Date d = CommUtils.stringToDate(dt);
			Time t = Time.newInstance(Integer.valueOf(tmHH), Integer.valueOf(tmMM), Integer.valueOf(tmSS), 0);
			if (d != null && t != null) return DateTime.newInstance(d,t);
        } catch (Exception e) {}
		return null;
    }
    // 2018/11/08 EXPOからAWSのAPIを呼び出し機能対応 WSQ BEGIN
    /*
	<GetMasterInfoRS>
	    <ProductList>
	        <ProductInfo>
	            <ProductCode>00D5D0000004qLyUAI-75718516</ProductCode>
	        </ProductInfo>
	        <ProductInfo>
	            <ProductCode>00DO00000053ZNTMA2-EP0000001348</ProductCode>
	        </ProductInfo>
	    </ProductList>
	</GetMasterInfoRS>
	*/
    // 指定の商品コードのXML情報を返却する
    @future (callout=true)
    public static void syncSfProdInfoToAws(List<String> productCds, Boolean isDelFlg) {
    	// ENDPOINT未定義の場合、外部呼び出す機能無効
        if (CommUtils.isBlank(ExpoHelperUtil.EXPO_ENDPOINTURL)) return;
        // ロゴ初期化処理
        log = new CommLogUtils('WS_ExpoEngineService,',true);
        log.write_method_start('syncSfProdInfoToAws');
        // 指定の商品IDにより、関連情報を設定、内容を取得、APIを呼び出し
        // 最大２００件（TRIGGERから）会計商品情報XMLを取得する
        String prodXmlTemp = '<ProductInfo><ProductCode>$$_ProductCode_$$</ProductCode></ProductInfo>';
		String syncXmltemp = '<GetMasterInfoRS><ProductList>$$_ProductInfo_$$</ProductList></GetMasterInfoRS>';
        Integer loopsize = 100;
        Integer loopLen = (productCds.size() / loopsize + 1);
        for (integer i=0; i< loopLen; i++) {
        	Integer sidx = loopsize*i;
        	Integer eidx = loopsize*(i+1);
        	if (eidx > productCds.size()) eidx = productCds.size();
        	List<String> productsLst = new List<String>();
        	for (integer j=sidx; j<eidx;j++) {
        		productsLst.add(prodXmlTemp.replace('$$_ProductCode_$$',getExpoCode(productCds[j])));
        	}
			if (!productsLst.isEmpty()) {
				// AWS側へ送信する
				String syncXml = syncXmltemp.replace('$$_ProductInfo_$$',String.join(productsLst,''));
				log.write_log('syncXml：'+syncXml);
				// 2019/06/06 EXPO会計商品削除場合、関連情報はAWSへ通知を行う WSQ BEGIN
				String reqUrl = '/productManager/syncProduct';
				if (isDelFlg) reqUrl = '/productManager/deleteProduct';//商品削除する場合、AWS側に非表示の通知を行う
				//sendRequest(syncXml,'/productManager/syncProduct');
				sendRequest(syncXml,reqUrl);
				// 2019/06/06 EXPO会計商品削除場合、関連情報はAWSへ通知を行う WSQ END
			}
        }
        log.write_method_end();
        // 2017/12/06 性能改善 BEGIN
        CommLogUtils.saveLogToDb(log.getAllLog(),CommLogUtils.LogType.EXPO,1000);
    }
    // 注文状態を変更する場合、該当変更内容はAPI経由でAWSへ反映する
    /*
    <OrderInfoRS>
    <OrderInfoList>
        <OrderNo>111540571396488002BXA2</OrderNo>
        <OrderNo>111540571396488002BXA3</OrderNo>
    </OrderInfoList>
	</OrderInfoRS>
	*/
	@future (callout=true)
    public static void syncSfOrderInfoToAws(List<Id> orderIds) {
    	// ENDPOINT未定義の場合、外部呼び出す機能無効
        if (CommUtils.isBlank(ExpoHelperUtil.EXPO_ENDPOINTURL)) return;
        // ロゴ初期化処理
        log = new CommLogUtils('WS_ExpoEngineService,',true);
        log.write_method_start('syncSfOrderInfoToAws');
        // 指定の商品IDにより、関連情報を設定、内容を取得、APIを呼び出し
        // 最大２００件（TRIGGERから）会計商品情報XMLを取得する
        String itemTemp = '<SyncOrderNo>$$_OrderNo_$$</SyncOrderNo>';
		String syncTemp = '<OrderInfoRS><OrderInfoList>$$_OrderInfo_$$</OrderInfoList></OrderInfoRS>';
		// 注文番号により、注文を検索する
		List<Order__c> targetOrders = [select OrderNo__c,RefParOrder__c,RefParOrder__r.OrderNo__c from Order__c where id in :orderIds];
		set<string> orderNosSet = new set<string>();
		for (Order__c ord : targetOrders) {
			// 親注文の場合
			if (CommUtils.isBlank(ord.RefParOrder__c)) orderNosSet.add(ord.OrderNo__c);
			// SUB注文の場合
			else orderNosSet.add(ord.RefParOrder__r.OrderNo__c);
		}
		List<String> orderNos = new List<String>();
		orderNos.addAll(orderNosSet);
        Integer loopsize = 100;
        Integer loopLen = (orderNos.size() / loopsize + 1);
        for (integer i=0; i< loopLen; i++) {
        	Integer sidx = loopsize*i;
        	Integer eidx = loopsize*(i+1);
        	if (eidx > orderNos.size()) eidx = orderNos.size();
        	List<String> itemLst = new List<String>();
        	for (integer j=sidx; j<eidx;j++) {
        		itemLst.add(itemTemp.replace('$$_OrderNo_$$',orderNos[j]));
        	}
			if (!itemLst.isEmpty()) {
				// AWS側へ送信する
				String syncXml = syncTemp.replace('$$_OrderInfo_$$',String.join(itemLst,''));
				log.write_log('syncXml：'+syncXml);
				sendRequest(syncXml,'/orderManager/syncOrderInfo');
			}
        }
        log.write_method_end();
        // 2017/12/06 性能改善 BEGIN
        CommLogUtils.saveLogToDb(log.getAllLog(),CommLogUtils.LogType.EXPO,1000);
    }
    // 開発
	private static HTTPResponse sendRequest(String reqStr, String subUrl) {
    	// ENDPOINT未定義の場合、外部呼び出す機能無効
        if (CommUtils.isBlank(ExpoHelperUtil.EXPO_ENDPOINTURL)) return null;
		// リクエストURLを設定する
		String endpoint = ExpoHelperUtil.EXPO_ENDPOINTURL+'/'+subUrl;
		HttpRequest req = new HttpRequest();
		req.setHeader('Content-Type', 'application/xml');
		req.setBody(reqStr);
		req.setEndpoint(endpoint);
		req.setMethod('POST');
		req.setTimeout(120000);
		
		Http http = new Http();
		HTTPResponse res = http.send(req);
		return res;
	}
    // 2018/11/08 EXPOからAWSのAPIを呼び出し機能対応 WSQ BEGIN
    // 2019/03/29 EXPO注文の際に、店舗定義なし（一つ店舗のみ）場合、注文通知を行わない不具合改修 WSQ BEGIN
    private static ShopInformation__c getOrgShopInfo() {
        ShopInformation__c orgShop = new ShopInformation__c();
        // XML定義情報を取得する
        ExpoHelperUtil.OrganizationInfo org = ExpoHelperUtil.getOrganizationInfo();
        // 2019/04/10 EXPOのHR機能対応（3.1. 商品情報取得） WSQ BEGIN
        List<Organization> orgs = [select Phone,Name From Organization where id = :UserInfo.getOrganizationId() limit 1];
        Organization orgRs = (orgs.isEmpty()  ? new Organization() : orgs[0]);
        // 2019/04/10 EXPOのHR機能対応（3.1. 商品情報取得） WSQ END
        // 店舗基本情報を設定する
        orgShop.ShopCode__c = '';
        orgShop.Name = orgRs.Name;
        orgShop.WebSite__c = org.webSite;
        orgShop.email__c = org.email;
        orgShop.Phone__c = orgRs.phone;
        orgShop.ExpoIsOpenBuyHistoryFlg__c = org.isOpenBuyHistoryFlg;// 購入履歴情報公開する・しないフラグ
        return orgShop;
    }
    // 2019/03/29 EXPO注文の際に、店舗定義なし（一つ店舗のみ）場合、注文通知を行わない不具合改修 WSQ END
    // 2019/04/15 EXPOの10.1.稼働率分析情報を取得（稼働率・ADR・RevPer・客単価） WSQ BEGIN
    /**
    * 10.1.稼働率分析情報を取得
    **/
    /*
    /services/apexrest/ps/exposervice/V1/analytics
    
    <AnalyticsRQ>
        <CommonRequest>
            <majorno>8</majorno>
            <minorno>1</minorno>
        </CommonRequest>
        <ExtractionCondition>
            <ArrivalDateFrom>20180301</ArrivalDateFrom>
            <ArrivalDateTo>20200331</ArrivalDateTo>
        </ExtractionCondition>
    </AnalyticsRQ>
    */
    @TestVisible private static string analytics(String reqXml) {
        // 商品情報取得
        log.write_method_start('analytics');
        log.write_log('reqXml：'+reqXml);
        String retStr = '';
        try {
            // 取得のリクエストXMLを会席する
            Dom.Document doc = new Dom.Document();
            doc.load(reqXml);
            Dom.XMLNode rootNode = doc.getRootElement();

            // 共通条件を取得する
            commReq = new CommonRequest(rootNode.getChildElement('CommonRequest', null));
            // リクエスト情報解析する
            // 10.1.稼働率分析情報を取得
            if (commReq.isSetAnalytics()) {
                retStr = setAnalytics(rootNode);
            } 
        } catch (Exception e) {
            // エラー処理 
            WS_ResultInfo ret = new WS_ResultInfo('E9999',MSG_E9999);
            
            String rsXmltemp = '<AnalyticsRS><CommonResponse>$$_CommonResponse_$$</CommonResponse></AnalyticsRS>';
            retStr = rsXmltemp.replace('$$_CommonResponse_$$',ret.toXml());
                            
            log.write_error(e.getStackTraceString());
            log.write_error(e.getMessage());
        }
        log.write_method_end();
        // 2017/12/06 性能改善 BEGIN
        CommLogUtils.saveLogToDb(log.getAllLog(),CommLogUtils.LogType.EXPO,1000);
        return retStr;
    }
    // 施設客室数（PMSのパラメータ：施設客室数　設定値）
   	private final static Decimal CONST_MAXROOMS = (Test.isRunningTest()) ? 20 :CommUtils.nullToZero(CommDefine__c.getOrgDefaults().GuestRooms__c);
    @TestVisible private static string setAnalytics(Dom.XMLNode rootNode) {
        // 処理結果情報を格納する
        WS_ResultInfo ret = new WS_ResultInfo();
        // 検索結果集計情報
        XmlAnalyticsRest res = new XmlAnalyticsRest();   
        // 引き渡すパラメータ情報
        AnalyticsReq req = null;
        // DB情報SAVEPOINT
        //Savepoint sp = Database.setSavepoint();   
        try {
            // 引き渡すパラメータを解析する
            req = new AnalyticsReq(rootNode);
            // 有効チェック
            req.validata();
            // 集計情報を取得、到着日の開始、取得期間を集計する
            // 施設の客室数を設定する

            //res.MaxRooms = CommUtils.nullToZero(CommDefine__c.getOrgDefaults().GuestRooms__c);
            // 指定期間の予約情報を取得する
            // 検索のパラメータ値
            String betDtStr = req.ArrivalDateFrom;
            String endDtStr = req.ArrivalDateTo;
            Date begDt = req.ArrivalFromDt;
            Date endDt = req.ArrivalToDt;
            Integer cancelFlg = CommConst.LEAD_ST_CANCEL_FLG;//取消フラグ
            // 検索キー切り替え判断フラグ
            Boolean isFixedFlg = DataFixManagerUtils.getInstance().LeadFixed__c;
            // 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
            Boolean isFixedFlg1 = DataFixManagerUtils.getInstance().LeadFixed1__c;
            Integer betDtInt = CommUtils.nullToIntZero(betDtStr);
            Integer endDtInt = CommUtils.nullToIntZero(endDtStr);
            // 2020/08/30 部屋状態管理インデックス機能対応 WGCH END
            // 部屋、到着日、予約人数
            String sqlHeader = 'select id,EntryTime__c,StayPersons__c from lead__c ';
            String sqlWhere = 'where CancelBool__c != :cancelFlg ';
            // XMLにFILTER設定されているがどう、条件取得する
            ExpoHelperUtil.AnalyticsFilter analyFilter = ExpoHelperUtil.getAnalyticsFilter();
            if (!CommUtils.isBlank(analyFilter.leadFilter)) sqlWhere += ' And (' + analyFilter.leadFilter + ') ';
            // INDEX有効化有効の場合、該当検索キーで検索する
            // 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
            // if (isFixedFlg) sqlWhere += ' And (EntryDateKey__c >= :betDtStr and EntryDateKey__c <= :endDtStr) ';
            if(isFixedFlg1) sqlWhere += ' And (EntryDateIntKey__c >= :betDtInt and EntryDateIntKey__c <= :endDtInt) ';
            else if(isFixedFlg) sqlWhere += ' And (EntryDateKey__c >= :betDtStr and EntryDateKey__c <= :endDtStr) ';
            // 2020/08/30 部屋状態管理インデックス機能対応 WGCH END
            else sqlWhere += ' And (DAY_ONLY(convertTimezone(EntryTime__c)) >= :begDt and DAY_ONLY(convertTimezone(EntryTime__c)) <= :endDt) ';
            String sqlOrderBy =' order by EntryTime__c';
log.write_log('SQL1：'+(sqlHeader + sqlWhere + sqlOrderBy));
            List<Lead__c> targetLeads = DataBase.query(sqlHeader + sqlWhere + sqlOrderBy);
log.write_log('targetLeads：'+(targetLeads.size()));
log.write_log('begDt：'+(begDt));
log.write_log('endDt：'+(endDt));
            // 会計検索用予約IDを格納する
            set<id> leadIdSet = new set<Id>();
            // 1日の「予約人数合計、稼働室数を合計する」
            map<Date,AnalyticsItem> leadSumMap = new map<Date,AnalyticsItem>();
            for (Lead__c lead : targetLeads) {
                // 到着日
                Date entryDt = lead.EntryTime__c.date();
                if (!leadSumMap.containsKey(entryDt)) leadSumMap.put(entryDt, new AnalyticsItem());
                // 合計値集計する
                AnalyticsItem item =leadSumMap.get(entryDt);
                item.ArrivalDate = lead.EntryTime__c.format('yyyyMMdd');
                item.StayPeople += CommUtils.nullToZero(lead.StayPersons__c);//予約人数
                item.WorkRooms += 1;//稼働室数集計
                // 予約情報可能する
                leadIdSet.add(lead.Id);
            }
            // 該当予約により、会計明細合計金額を集計する
            if (!leadIdSet.isEmpty()) {
				String avgQuery = 'select sum(GoukeinoneTax__c) amount, DAY_ONLY(convertTimezone(Field1__r.Relreserve__r.EntryTime__c)) cidate from Tran1__c ';
				String avgWHere = ' where Field1__r.Relreserve__c in :leadIdSet and Field1__r.OutSideAccount__c = 1' ;
				if (!CommUtils.isBlank(analyFilter.accFilter)) avgWHere += ' And (' + analyFilter.accFilter + ') ';
				else avgWHere += ' And ActionType__c = \'室料\' ';
				String avgGroup = ' group by DAY_ONLY(convertTimezone(Field1__r.Relreserve__r.EntryTime__c))';
				List<AggregateResult> accAmountRs = Database.query(avgQuery + avgWHere + avgGroup);
log.write_log('SQL2：'+(avgQuery + avgWHere + avgGroup));
log.write_log('accAmountRs：'+(accAmountRs.size()));
		    	for (AggregateResult avg : accAmountRs) {
		    		Date ciDate = (Date)avg.get('cidate');
		    		Decimal amount = (Decimal)avg.get('amount');
		    		// 該当到着日に予約データが非存在場合、処理SKIP
					if (!leadSumMap.containsKey(ciDate)) continue;
					// 既存データを取得する
					AnalyticsItem item =leadSumMap.get(ciDate);
					item.Amount = amount;
		    	}
            }
            // 指定の検索期間からXML情報を作成する
log.write_log('leadSumMap：'+leadSumMap);
            Date wkDt = begDt;
            while (wkDt <= endDt) {
            	if (leadSumMap.containsKey(wkDt)) {
            		res.itemLst.add(leadSumMap.get(wkDt).toXml());
            	}
            	wkDt = wkDt.addDays(1);
            }
log.write_log('res：'+res);
        } catch (CommException ex) {
            // 予想以外の異常が発生する場合
            ret = new WS_ResultInfo('E1001',ex.getMessage());
        } catch (Exception e) {
            // 予想以外の異常が発生する場合
            ret = new WS_ResultInfo('E9999',MSG_E9999);
            System.debug(e.getMessage());
            log.write_error(e.getStackTraceString());
            log.write_error(e.getMessage());
        }
        // 処理結果作成する
        String rsXmltemp = '<AnalyticsRS><CommonResponse>$$_CommonResponse_$$</CommonResponse>$$_AnalyticsInfoLst_$$</AnalyticsRS>';
        return rsXmltemp.replace('$$_CommonResponse_$$',ret.toXml())
                        .replace('$$_AnalyticsInfoLst_$$',res.toXml());
    }
    
    //**************************************************
    // 10.1.稼働率分析情報を取得[引き渡す情報を受信する]
    //**************************************************
    class AnalyticsReq {
        public AnalyticsReq(Dom.XmlNode root) {
            // 抽出条件
            Dom.XmlNode extrField = root.getChildElement('ExtractionCondition', null);
            if (extrField != null) {
                ArrivalDateFrom = getChildElementByName(extrField, 'ArrivalDateFrom');
                ArrivalDateTo = getChildElementByName(extrField, 'ArrivalDateTo');
                ShopCode = getChildElementByName(extrField, 'ShopCode');
                if (!CommUtils.isBlank(ArrivalDateFrom)) ArrivalFromDt = CommUtils.stringToDate(ArrivalDateFrom);
                if (!CommUtils.isBlank(ArrivalDateTo)) ArrivalToDt = CommUtils.stringToDate(ArrivalDateTo);
            }
        }
        /*                                      
        到着日FROM                                         
        到着日TO                                           
        店舗コード                                                                                       
        */
        String ArrivalDateFrom{get;set;}
        String ArrivalDateTo{get;set;}
        String ShopCode{get;set;}
        Date ArrivalFromDt{get;set;}
        Date ArrivalToDt{get;set;}
        // 有効性チェックを行う
        public Boolean validata() {
            // 必須チェック
            if (CommUtils.isBlank(ArrivalDateFrom) ||
                CommUtils.isBlank(ArrivalDateTo) ) {
                throw new CommException(MSG_E0001 + ':' + this);
            }

            if (ArrivalFromDt == null || ArrivalDateTo == null) {
                throw new CommException(MSG_E0001 + ':' + this);
            } else if (ArrivalFromDt > ArrivalToDt) {
            	throw new CommException(MSG_E0001 + ':' + this);
            }
            return true;
        }
    }
    // 10.1.稼働率分析情報を取得情報返却用
    class XmlAnalyticsRest {
        public Decimal MaxRooms{get;set;}//最大客室数
        public List<String> itemLst{get;set;}//分析結果リスト
        public XmlAnalyticsRest() {
        	itemLst = new List<String>();
        	// 施設の客室数を設定する
        	MaxRooms = CONST_MAXROOMS;
        }
        public String toXml() {
            String xml = '<AnalyticsInfoLst><MaxRooms>$_MaxRooms_$</MaxRooms>$_AnalyticsInfo_$</AnalyticsInfoLst>';
            String xmlBody = '';
            // 施設客室数値を未設定場合、集計結果空欄返却
            if(MaxRooms == null || MaxRooms <= 0) return xmlBody;
            if(itemLst == null || itemLst.isEmpty()) return xmlBody;
            //最大客室数タグ値設定
            return (xml.replace('$_MaxRooms_$',CommUtils.nullToBlank(MaxRooms))
                    .replace('$_AnalyticsInfo_$',String.join(itemLst, '')));
            
        }
    }
    // １日分集計情報格納
    class AnalyticsItem {
        public String ArrivalDate{get;set;} // 到着日
        public Decimal StayPeople{get;set;} // 予約人数
        public Decimal WorkRooms{get;set;} // 稼働室数
        public Decimal OCC{get;set;} // 客室稼働率
        public Decimal AvgGuest{get;set;} // １室当りの平均客数
        public Decimal Amount{get;set;} // 合計金額
        public Decimal ADR{get;set;} // 平均客室単価
        public Decimal Revper{get;set;} // 販売可能な客室1室あたりの売上
        public Decimal AvgSpendPerUser{get;set;} // 客単価
        public AnalyticsItem () {
            StayPeople = 0;
            WorkRooms = 0;
            Amount = 0;
        }
        public String toXml() {
            String xml = '<AnalyticsInfo>$_AnalyticsInfo_$</AnalyticsInfo>';
            String xmlBody = '';
            if (CONST_MAXROOMS > 0) {
                xmlBody+=joinTagXml('ArrivalDate',ArrivalDate);
                xmlBody+=joinTagXml('StayPeople',CommUtils.nullToBlank(StayPeople));
                xmlBody+=joinTagXml('WorkRooms',CommUtils.nullToBlank(WorkRooms));
                OCC = CommUtils.RoundProcess((WorkRooms / CONST_MAXROOMS),3);//稼働室数/最大客室数
                xmlBody+=joinTagXml('OCC',CommUtils.nullToBlank(OCC));
                xmlBody+=joinTagXml('Amount',CommUtils.nullToBlank(CommUtils.RoundProcess(Amount,CommUtils.getPointLen())));
                AvgGuest = CommUtils.RoundProcess((StayPeople / WorkRooms),2);//予約人数/稼働室数   
                xmlBody+=joinTagXml('AvgGuest',CommUtils.nullToBlank(AvgGuest));
                ADR = CommUtils.RoundProcess((Amount / WorkRooms),CommUtils.getPointLen());//合計金額/稼働室数
                xmlBody+=joinTagXml('ADR',CommUtils.nullToBlank(aDr));
                Revper = CommUtils.RoundProcess((Amount / CONST_MAXROOMS),CommUtils.getPointLen());//合計金額/最大客室数
                xmlBody+=joinTagXml('Revper',CommUtils.nullToBlank(Revper));
                AvgSpendPerUser = (StayPeople == 0 ? 0 : CommUtils.RoundProcess((Amount / StayPeople),CommUtils.getPointLen()));//合計金額/予約人数
                xmlBody+=joinTagXml('AvgSpendPerUser',CommUtils.nullToBlank(AvgSpendPerUser));
            }
            return xml.replace('$_AnalyticsInfo_$',xmlBody);
        }
    }
    // 人材のタスクEVENT情報
    public class EventInfo {
    	public string title{get;set;}
    	public string begDt{get;set;}//yyyy-mm-dd
    	public string endDt{get;set;}//yyyy-mm-dd
    }
    // 2019/04/15 EXPOの10.1.稼働率分析情報を取得（稼働率・ADR・RevPer・客単価） WSQ END
}