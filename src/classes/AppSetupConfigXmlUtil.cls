/**
* Appのカスタム定義情報のオブジェクト化対応
* 2014/12/09 予約のステータスの色定義機能追加Parse
*/
public with sharing class AppSetupConfigXmlUtil {
	
	public static Dom.XmlNode parseXmlDoc(String pShopCode) {
		// Parse Document File Namec 
		String docName = 'AppSetupConfigXml';
   		return CommXmlUtils.parseXmlDoc(docName, pShopCode);
	}
	public static Map<String, Config> getLeadStatusColors(String pShopCode) {
		Dom.XmlNode targetNode = parseXmlDoc(pShopCode);
		// 設定情報
		Map<String, Config> leadStatusColorMap = new Map<String, Config>();
		// XML定義情報を取得する
		Dom.XmlNode colorStatus =  targetNode.getChildElement('LEADSTATUSCOLOR', null);
		Dom.XmlNode[] colors = colorStatus.getChildElements();
		for (Dom.XmlNode colorNode : colors) {
			Dom.XmlNode keyField =  colorNode.getChildElement('KEY', null);
			Dom.XmlNode ValField =  colorNode.getChildElement('COLOR', null);
			if (keyField == null || ValField == null) continue;
			String key = CommUtils.nullToBlank(keyField.getText()).trim();
			String color = CommUtils.nullToBlank(ValField.getText()).trim();
			leadStatusColorMap.put(key, new Config(key, color));
		}
		return leadStatusColorMap;
	}
	
	/**
	* 定義情報を格納する
	**/
	public class Config {
		public Config (String pKey, String pVal) {
			key = pKey;
			val = pVal;
		}
		public String key{get; set;}
		public String val{get; set;}
	}
}