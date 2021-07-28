/*
 * @Author: persistent systems ltd.
 * @Date: August 8, 2014
 * @Description: DOMを使って構文解析XMLのためのユーティリティクラスです。.
 */

public with sharing class DomXmlUtil {

	/* このメソッドは、画面タグのXMLノードを返します。 */
	public static DOM.XMLNode getXMLNodeByName(String xmlFileName, String screenName){
		// ドキュメントフォルダからXMLドキュメントを検索
		List<Document> docs = [select id, name, body from Document where name =: xmlFileName];
		
		if(!docs.isEmpty()){ 
			String xmlBody = docs[0].body.toString(); 
			DOM.Document xmlDOC = new DOM.Document();
	
			//DOM.Documentオブジェクト内のXML文字列をロード
			xmlDOC.load(xmlBody);
	
			// ルート要素を取得します（スクリーン）
			DOM.XMLNode rootElement = xmlDOC.getRootElement();
			// スクリーン名を持つ<画面>要素を検索します。
			for(DOM.XMLNode xmlnodeobj : xmlDOC.getRootElement().getChildElements()){
				if(xmlnodeobj.getAttribute('name', '') != null && xmlnodeobj.getAttribute('name', '')== screenName){
					return xmlnodeobj;
				}
			}
		}
		return null;
	}
	
	/*画面内に保持幅と画面のサイズを取得します. */
	public static Integer[] getSizing(DOM.XMLNode screenNode){
		Integer[] sizing = new List<Integer>{0,0};
		for(DOM.XMLNode chldNode : screenNode.getChildElements()){
			//幅を取得
			if(chldNode.getText() != null && chldNode.getName() == 'width'){
				sizing[0] = Integer.valueOf(chldNode.getText());
			}
			// 高さを取得
			if(chldNode.getText()!= null && chldNode.getName() == 'height'){
				sizing[1] = Integer.valueOf(chldNode.getText());
			}
		}
					
		return sizing;
	}
	
	/*この方法は、画面用のフィールドノードが返されます。*/
	public static DOM.XMLNode getFieldsNode(DOM.XMLNode screenNode){
		for(DOM.XMLNode chldNode : screenNode.getChildElements()){
			if(chldNode.getName() == 'fields' ){
				return chldNode;
			}
		}
		return null;
	}
}