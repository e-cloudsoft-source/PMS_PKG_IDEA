public with sharing class CommXmlUtils {
	public static Dom.XmlNode parseXmlDoc(String docName, String pShopCode) {
		return encodeParseXmlDoc(docName,pShopCode,null);
	}
	public static Dom.XmlNode encodeParseXmlDoc(String docName, String pShopCode,String[] encodeXmlTagName) {
		// Parse Document File Namec 
		if (CommUtils.isBlank(docName)) throw New CommException('Config Xml(' + docName +') File Not Found!!!');
   		// 拡張予約項目を定義する
    	List<Document> sr = [select body, name from Document where DeveloperName = :docName];
    	if (sr.isEmpty()) throw New CommException('Config Xml(' + docName +') File Not Found!!!');
    	
    	Blob xmlBody = sr[0].Body;
    	String strXmlBody = xmlBody.toString();
    	if(encodeXmlTagName != null && encodeXmlTagName.size() > 0){
    		strXmlBody = parseXmlDocReplace(strXmlBody,encodeXmlTagName);
    	}
    	Dom.XmlNode targetNode, firstNode = null;
		Dom.Document doc = new Dom.Document();
		doc.load(strXmlBody);
		Dom.XmlNode root = doc.getRootElement();
		for(Dom.XMLNode shop : root.getChildElements()) {
			// 各店舗情報はＸＭＬから取得する
			Dom.XmlNode shopcode =  shop.getChildElement('SHOPCODE', null);
			//2017/04/27 commit by zy BEGIN
			if (shopcode == null) continue;
			//2017/04/27 commit by zy END
			// 店舗コードを取得する
			String strShopCode = CommUtils.nullToBlank(shopcode.getText());
			if (firstNode == null) firstNode = shop;
			// ログインユーザの店舗コードと一致する場合
			if (strShopCode == pShopCode) {
				targetNode = shop;
				break;
			}
		}
		// 目標店舗情報を取得する、店舗コード未設定する場合、一番目の店舗情報で設定する
		targetNode = targetNode == null ? firstNode : targetNode;
		if (targetNode == null) throw New CommException('Config Xml(' + docName +') File Parse Faied!!!');
		return targetNode;
	}
	/**
	* メール取り込み機能テンプレート情報を取得用（SHOPのタグなし）
	**/
	public static Dom.XmlNode encodeParseXmlNoShopCodeNodeDoc(String docName, String[] encodeXmlTagName) {
		// Parse Document File Namec 
		if (CommUtils.isBlank(docName)) throw New CommException('Config Xml(' + docName +') File Not Found!!!');
   		// 拡張予約項目を定義する
    	List<Document> sr = [select body, name from Document where DeveloperName = :docName];
    	if (sr.isEmpty()) throw New CommException('Config Xml(' + docName +') File Not Found!!!');
    	
    	Blob xmlBody = sr[0].Body;
    	String strXmlBody = xmlBody.toString();
    	if(encodeXmlTagName != null && encodeXmlTagName.size() > 0){
    		strXmlBody = parseXmlDocReplace(strXmlBody,encodeXmlTagName);
    	}
    	Dom.XmlNode firstNode = null;
		Dom.Document doc = new Dom.Document();
		doc.load(strXmlBody);
		Dom.XmlNode root = doc.getRootElement();
		if (root == null) throw New CommException('Config Xml(' + docName +') File Parse Faied!!!');
		return root;
	}
	/**
	* 全て店舗設定情報を一括取得、戻る
	**/
	public static List<Dom.XmlNode> getAllTopXmlNode(String docName) {
		return getAllTopXmlNode(docName, null);
	}
	/**
	* 全て店舗設定情報を一括取得、戻る
	**/
	public static List<Dom.XmlNode> getAllTopXmlNode(String docName,String[] tagName) {
		// Parse Document File Namec 
		if (CommUtils.isBlank(docName)) throw New CommException('Config Xml(' + docName +') File Not Found!!!');
   		// 拡張予約項目を定義する
    	List<Document> sr = [select body, name from Document where DeveloperName = :docName];
    	if (sr.isEmpty()) throw New CommException('Config Xml(' + docName +') File Not Found!!!');
    	map<String,Dom.XmlNode> nodesMap = new map<String,Dom.XmlNode>();
    	
    	Blob xmlBody = sr[0].Body;
    	String strXmlBody = xmlBody.toString();
    	Dom.XmlNode targetNode, firstNode = null;
		Dom.Document doc = new Dom.Document();
		if (tagName == null || tagName.isEmpty()) {
			doc.load(strXmlBody);
		} else {
			doc.load(parseXmlDocReplace(strXmlBody,tagName));
		}
		Dom.XmlNode root = doc.getRootElement();
		return root.getChildElements();
	}
	public static String parseXmlDocReplace(String strXmlBody,String[] tagName){
		// Parse Document File Namec 
    	// 2019/10/30 オーダーエントリー画面で、「部屋」から予約一覧を呼び出す際、当日にご予約がないお部屋は前日のご予約が表示されたままになってしまいます。 by zy BEGIN
    	String changXmlStr = '';
		if (tagName.size() > 2) {
			for (integer i = 0 ; i < tagName.size() ; i++) {
				String begTar = tagName[i];
				String endTar = null;
				i++;
    			integer index = 0;
				if (i < tagName.size()) endTar = tagName[i];
				for(String content : strXmlBody.split(begTar)){
					if(index == 0 ){	
						changXmlStr = content;
					}else{
						List<String> splitContentChild = content.split(endTar);
						for(integer j = 0 ; j < splitContentChild.size() ; j++){
							String splitContent = splitContentChild[j].trim();
							if (CommUtils.isBlank(splitContent)) continue;
							if (j == 0)
								changXmlStr += begTar + splitContent.escapeXml() + endTar;
							else 
								changXmlStr += splitContent;
						}
					}
					index++;
				}
				strXmlBody = changXmlStr;
			}
			return changXmlStr;
		} 
		integer index = 0;
		// 2019/10/30 オーダーエントリー画面で、「部屋」から予約一覧を呼び出す際、当日にご予約がないお部屋は前日のご予約が表示されたままになってしまいます。 by zy END
    	for(String content : strXmlBody.split(tagName[0])){
    		if(index == 0 ){	
    			changXmlStr = content;
    		}else{
    			List<String> splitContentChild = content.split(tagName[1]);
    			for(integer i = 0 ; i < splitContentChild.size() ; i++){
    				if(i == 0){
    					changXmlStr += tagName[0] + splitContentChild[i].trim().escapeXml() + tagName[1];
    				}else{
    					changXmlStr += splitContentChild[i];
    				}
    			}
    		}
    		index++;
    	}
		return changXmlStr;		
	}
	// XMLタグ内容を取得する 2018/04/09 ADD
	public static string getChildElementByName(Dom.XMLNode parentNode,String elementName){
        if (parentNode == null) return null;
        Dom.XMLNode childrenNode = parentNode.getChildElement(elementName, null);
        return getChildElementValue(childrenNode);
	}
	public static String getChildElementValue(Dom.XMLNode childNode) {
        if (childNode == null) return null;
        return CommUtils.nullToBlank(childNode.getText());
	}
    // 2019/04/11 指定店舗、指定タグ間のXMLを返却する
	/**
	* 指定店舗、指定タグ間のXML文字を返却する　
	* docName XMLドキュメント
	* tagName タグ名[BEGIN/END]必ず２パラメータが必要
	* pShopCode 店舗コード、該当コードで見つからない場合、始める設定XMLを取得する　
	**/
	public static Dom.XmlNode getTagBetweenXml(String docName,String[] tagName, String pShopCode) {
		// Parse Document File Namec 
		if (CommUtils.isBlank(docName)) throw New CommException('Config Xml(' + docName +') File Not Found!!!');
   		// 拡張予約項目を定義する
    	List<Document> sr = [select body, name from Document where DeveloperName = :docName];
    	if (sr.isEmpty()) throw New CommException('Config Xml(' + docName +') File Not Found!!!');
    	if (tagName == null || tagName.size() != 2) throw New CommException('parameter is validate');
    	
    	Blob xmlBody = sr[0].Body;
    	String strXmlBody = xmlBody.toString();
    	String retXml = '';
 		// 店舗コード設定により、店舗情報が存在場合、該当店舗コードの定義を検索
 		// 店舗コードがNULL場合、順番で第一
 		if (pShopCode == null) {
 			// 第一の設定情報を取得する
 			retXml =CommUtils.nullToBlank(strXmlBody.substringBetween(tagName[0],tagName[1]));
 		} else {
 			pShopCode = CommUtils.nullToBlank(pShopCode);
 			// 店舗コードにより、探す
 			String sKey = '<SHOPCODE>'+pShopCode+'</SHOPCODE>';
 			// 指定店舗情報が個別定義されている場合
 			Integer pos = strXmlBody.indexOf(sKey) ;
 			if (pos >= 0) {
 				String wkXml = strXmlBody.subString(pos);
 				retXml = CommUtils.nullToBlank(wkXml.substringBetween(tagName[0],tagName[1]));
 			} else {
 				retXml = CommUtils.nullToBlank(strXmlBody.substringBetween(tagName[0],tagName[1]));
 			}
 		}
 		Dom.Document doc = new Dom.Document();
 		doc.load(tagName[0]+retXml+tagName[1]);
		return doc.getRootElement();
	}
}