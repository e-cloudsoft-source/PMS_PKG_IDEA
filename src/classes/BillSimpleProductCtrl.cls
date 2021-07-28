/*************************************
* 会計商品定義情報取得処理クラス
*
*************************************/
global with sharing class BillSimpleProductCtrl {
	transient public String jsonDs{get; private set;}
	// 2021/03/30 優化 by zy BEGIN
	transient private List<TabGroupInfo> oProdsLst;
	// 2021/03/30 優化 by zy END
	transient public String oProdMapsJson{get; private set;}
	// 2021/03/30 優化 by zy BEGIN
	transient public String oProdsLstJson{get; private set;}
	// 2021/03/30 優化 by zy END
	public String inShopCode{get; set;}	// 支店コード
	// 2021/03/30 優化 by zy BEGIN
	private static String ptableWd;
	private static String pTableHt;
	transient public String tableWidth{get{return ptableWd;}private set;}
	transient public String tableHeight{get{return pTableHt;}private set;}
	// 2021/03/30 優化 by zy END
	transient public String callBackFun{get;private set;}
	public void init(){
		 inShopCode = ApexPages.currentPage().getParameters().get('spcd');
		 callBackFun = ApexPages.currentPage().getParameters().get('callback');
	}
	
	/**
	* XML定義情報取得、表示を行う
	* 必ず画面初期表示の場合、一番上に該当MethodをVFから呼び出すするが必要  
	**/
    public String getInitXmlDefineInfo () {
    	// 初期化
    	initProduct();
    	return '';
    }
    
    // 画面に表示用情報を取得する
	private void initProduct() {
		// 2021/03/30 優化 by zy BEGIN
		ptableWd = '100%';
		pTableHt = '240px';
		// 2021/03/30 優化 by zy END
		List<TabGroupInfo> xmlProdDS = getXmlProductInfo(inShopCode);
		// 定義している商品情報の商品コードは商品マスタに有効存在チェックヲ行う
		Set<String> prodCodeSet = new Set<String>();
		for (TabGroupInfo tab : xmlProdDS) {
			for (ProductInfo prod : tab.prods) {
				prodCodeSet.add(prod.code);
			}
		}
		// 2021/03/30 優化 by zy BEGIN
		// 商品コード関連の商品情報を取得する
		// Map<String, ProductItemUtils.ProductItem>  prodMaps = ProductItemUtils.getMapProductItemByCodes(prodCodeSet, false);
		Map<String, AccountMaster__c>  prodMaps = new Map<String, AccountMaster__c>();
		for (AccountMaster__c acc : [select id,Field3__c,JanCode__c from AccountMaster__c where Field3__c in :prodCodeSet]){
			prodMaps.put(acc.Field3__c,acc);
		}
		// 2021/03/30 優化 by zy END
		// XMLから定義して無効な商品を外す
		for (TabGroupInfo tab : xmlProdDS) {
			for (Integer i =0; i < tab.prods.size() ; i++) {
				ProductInfo prod =  tab.prods[i];

				prod.sName = CommStringUtils.zenkakuToHankaku(prod.name);
				prod.code = CommStringUtils.zenkakuEisujiToHankakuEisuji(prod.code);
				if (!prodMaps.containsKey(prod.code)) {
					//tab.prods.remove(i);
					tab.prods[i].disabledFlg = true;
				// 2020/12/15 会計商品にJANコードを登録し、それをバーコードリーダーで読み取り、会計処理が行えるようにしたい by zy BEGIN
				} else {
					// 2021/03/30 優化 by zy BEGIN
					prod.janCode = prodMaps.get(prod.code).JanCode__c;
					// 2021/03/30 優化 by zy END
				}
				
				// 2020/12/15 会計商品にJANコードを登録し、それをバーコードリーダーで読み取り、会計処理が行えるようにしたい by zy END
			}
		}
		// 2021/03/30 優化 by zy BEGIN
		// oProdMapsJson = JSON.serialize(prodMaps);
		oProdsLstJson = JSON.serialize(xmlProdDS);
		// 2021/03/30 優化 by zy END
	}
	// 該当支店の商品定義情報
	private static List<TabGroupInfo> getXmlProductInfo(String pShopCode) {
		
		// SHOP ROOT ELEMENT INFO
		// 2021/03/30 優化 by zy BEGIN
		Dom.XmlNode targetNode = CommXmlUtils.parseXmlDoc('BillSimpleProductConfig', pShopCode);
		// 2021/03/30 優化 by zy END
		Map<String, ProductInfo> ProductInfoMap = new Map<String, ProductInfo>();
		// XMLに定義する商品情報を取得する
		List<TabGroupInfo> prodInfoLst = new List<TabGroupInfo>();
//System.debug(loggingLevel.INFO, 'shopCode:::' + inShopCode);		
//System.debug(loggingLevel.INFO, 'targetNode:::' + targetNode);
		// TABのNODEの情報を取得する
		Dom.XmlNode[] tabGroups =  targetNode.getChildElements();
		if (tabGroups != null) {
			for (Dom.XmlNode tabRoot : tabGroups) {
				// tableの共通STYLE確認
				if(tabRoot.getName().equalsIgnoreCase('TABLEWIDTH')){
					// 2021/03/30 優化 by zy BEGIN
					ptableWd = CommUtils.nullToBlank(tabRoot.getText()).deleteWhitespace();
					// 2021/03/30 優化 by zy END
					continue;
				}
				if(tabRoot.getName().equalsIgnoreCase('TABLEHEIGHT')){
					// 2021/03/30 優化 by zy BEGIN
					pTableHt = CommUtils.nullToBlank(tabRoot.getText()).deleteWhitespace();
					// 2021/03/30 優化 by zy END
					continue;
				}
				// TABGROUP以外の情報は処理対象外
				if (!tabRoot.getName().equalsIgnoreCase('TABGROUP')) continue;
//System.debug(loggingLevel.INFO, 'tabRoot:::' + tabRoot);
				// Tab Group Info
				TabGroupInfo tabItem = new TabGroupInfo();
				// 該当ボタンに定義されているタブ情報
				Dom.XmlNode[] tabChildrens =  tabRoot.getChildElements();
				for (Dom.XmlNode child : tabChildrens) {
					
					// タグ名を取得する
					String tagName = child.getName();
//System.debug(LoggingLevel.INFO, 'tagName:::' + tagName);
//System.debug(LoggingLevel.INFO, 'tagName.equalsIgnoreCase(PRODUCT):::' + tagName.equalsIgnoreCase('PRODUCT'));
					// 商品
					if (tagName.equalsIgnoreCase('PRODUCT')) {
						
						Dom.XmlNode prodCodeField  = child.getChildElement('CODE', null);
						if (prodCodeField == null) continue;
						String prodCode = CommUtils.nullToBlank(prodCodeField.getText()).deleteWhitespace();
						if (CommUtils.isBlank(prodCode)) continue;
						Dom.XmlNode prodNameField  = child.getChildElement('NAME', null);
						String prodName = '';
						if (prodNameField != null) prodName = CommUtils.nullToBlank(prodNameField.getText()).deleteWhitespace();
						ProductInfo prod = new ProductInfo(prodCode, prodName); 
						// 商品情報を追加する
						tabItem.addProduct(prod);
					} 
					// タブのラベル
					else if (tagName.equalsIgnoreCase('TABLABEL')) {
						
						tabItem.label = CommUtils.nullToBlank(child.getText()).deleteWhitespace();
						
					} 
					// ボタンレイアウト定義情報
					else if (tagName.equalsIgnoreCase('LAYOUT')) {
						//Dom.XmlNode labelMaxLenField  = child.getChildElement('BTNWORDLEN', null);
						Dom.XmlNode btnStyleField  = child.getChildElement('BTNSTYLE', null);
						//if (labelMaxLenField != null) tabItem.layoutMaxLen = CommUtils.nullToBlank(labelMaxLenField.getText()).deleteWhitespace();
						if (btnStyleField != null) tabItem.layoutBtnStyle = CommUtils.nullToBlank(btnStyleField.getText()).deleteWhitespace();
					}
					
				}
				// 1タブの定義情報を取得する
				prodInfoLst.add(tabItem);
			}
		}

		return prodInfoLst;
	}
	public class TabGroupInfo {
		public TabGroupInfo() {
			prods = new List<ProductInfo>();
			// Init Info 
			layoutBtnStyle = 'width:100px;';
		}
		public void addProduct(ProductInfo prod) {
			prods.add(prod);
		}
		public String label{get; set;}
		public String layoutBtnStyle{get; set;}
		public List<ProductInfo> prods{get; private set;}
	}
	public class ProductInfo {
		public ProductInfo (String pCode, String pName) {
			code = pCode;
			name = pName;
			tips = pName;
			disabledFlg = false;
		}
		public boolean disabledFlg{get;set;}
		public String code{get; set;}
		public String name{get; set;}
		public String sName{get; set;}
		public String tips{get; set;}
		// 2020/12/15 会計商品にJANコードを登録し、それをバーコードリーダーで読み取り、会計処理が行えるようにしたい by zy BEGIN
		public String janCode{get;set;}
		// 2020/12/15 会計商品にJANコードを登録し、それをバーコードリーダーで読み取り、会計処理が行えるようにしたい by zy END
	}
	// 2021/03/30 優化 by zy BEGIN
	@RemoteAction
    global static object remoteCenter(String type,String data){
    	if (type == 'getProdInfos') return getProdInfos(data);
    	return null;
    }
    public Class Info{
    	String spcd;
    	Set<String> prodSet;
    }
	public static object getProdInfos(String request){
    	Info info = (Info)JSON.deserialize(request, Info.class);
		String inShopCode = info.spcd;
		Set<String> prodSet = info.prodSet;
		if (prodSet == null || prodSet.isEmpty()) {
			prodSet = new Set<String>();
			List<TabGroupInfo> xmlProdDS = getXmlProductInfo(inShopCode);
			// 定義している商品情報の商品コードは商品マスタに有効存在チェックヲ行う
			for (TabGroupInfo tab : xmlProdDS) {
				for (ProductInfo prod : tab.prods) {
					prodSet.add(prod.code);
				}
			}
		}
		// 商品コード関連の商品情報を取得する
		Map<String, ProductItemUtils.ProductItem>  prodMaps = ProductItemUtils.getMapProductItemByCodes(prodSet, false);
		return prodMaps;
    }
    // 2021/03/30 優化 by zy END
}