/****
* 会計編集商品選べる機能対応(New Menu)
* 2014.12.22 EC-SOFT INIT
*****/
public with sharing class BillSimplePaymentCtrl {
	
	public String inShopCode{get; set;}	// 支店コード
	transient public PageLayout layoutInfo{get; private set;}
	transient public List<ButtonTab> buttonsLstTab{get;set;}
	transient public String oProdMapsJson{get; private set;}
	transient public Map<String, String> buttonsIconMap{get; private set;}
	public String getButtonsIconMapJson(){ return JSON.serialize(buttonsIconMap); }
	/**
	* XML定義情報取得、表示を行う
	* 必ず画面初期表示の場合、一番上に該当MethodをVFから呼び出すするが必要  
	**/
    public String getInitXmlDefineInfo () {
    	// 初期化
    	readDocumentProperties(false);
    	return '';
    }
    /**
    * XMLタグ：LAYOUT設定情報取得する
    */
    public PageLayout getLayoutTagInfo(String ShopCode) {
    	// レイアウトタグのみ（会計CTRL利用する)
    	readDocumentProperties(false);
    	return layoutInfo;
    }
	/**
	* XML定義情報を取得する
	* onlyLayoutFlg: レイアウトタグ情報のみ取得する （TRUE：LAYOUTのみ）
	*/
	private void readDocumentProperties(Boolean onlyLayoutFlg) {

		// ボタンレイアウト情報を初期化する
		layoutInfo = new PageLayout();
		// タブに表示するボタン情報
		buttonsLstTab = new List<ButtonTab>();
		buttonsIconMap = new Map<String, String>();
		// 処理ターゲットのNODEを取得する
		Dom.XmlNode targetNode = CommXmlUtils.parseXmlDoc('BillSimplePaymentConfig', inShopCode);
		// 表示するボタン情報を配列に格納する
		List<Dom.XmlNode> buttonTabs = new List<Dom.XmlNode>();
		// ボタン定義情報を取得する
		for(Dom.XMLNode xmlNode : targetNode.getChildElements()) {
			// タグ名
			String attributeName = xmlNode.getName();
			
			if(attributeName.equalsIgnoreCase('SHOPCODE')) continue;	// 店舗情報のタグ
			// レイアウト定義情報の場合
			if(attributeName.equalsIgnoreCase('LAYOUT')) {	
				// 一行最大列数
				Dom.XmlNode maxColsField =  xmlNode.getChildElement('MAXCOLS', null);
				if (maxColsField != null) {
					// レイアウトに列数定義情報を取得する
					String nodeVal = maxColsField.getText();
					// 一行目に含めのボタン数
					layoutInfo.colNums = CommUtils.nullToIntZero(nodeVal);
				}
				// ボタンの共通STYLE確認
				Dom.XmlNode btnStyleField =  xmlNode.getChildElement('BTNSTYLE', null);
				if (btnStyleField != null) {
					// レイアウトに列数定義情報を取得する
					String nodeVal = btnStyleField.getText();
					layoutInfo.btnStyle = CommUtils.nullToBlank(nodeVal);
				}
				// tableの共通STYLE確認[横幅]
				Dom.XmlNode tableWidthField =  xmlNode.getChildElement('TABLEWIDTH', null);
				if (tableWidthField != null) {
					// レイアウトに列数定義情報を取得する
					String widthVal = tableWidthField.getText();
					layoutInfo.tableWidth = CommUtils.nullToBlank(widthVal) ;
				}
				// tableの共通STYLE確認[高さ]
				Dom.XmlNode buttonLstPageHeightField =  xmlNode.getChildElement('TABLEHEIGHT', null);
				if (buttonLstPageHeightField != null) {
					// レイアウトに列数定義情報を取得する
					String heightVal = buttonLstPageHeightField.getText();
					layoutInfo.tableHeight = CommUtils.nullToBlank(heightVal) ;
				}
				continue;
			}
			// 個別ボタン設定情報を取得、設定する
			if(attributeName.equalsIgnoreCase('BUTTONTAB')){
				buttonTabs.add(xmlNode);
				continue;
			}
		}
		
		// ボタン単位のチギ情報を取得する
		//List<ButtonTab> tabs = new List<ButtonTab>();
		// 定義している商品コード
		Set<String> prodCodeSet = new Set<String>();
		// ボタン設定情報を格納する
		for(Dom.XMLNode tabButtonsNode : buttonTabs){
			// タブ格納変数情報を初期化する
			ButtonTab oneTab = new ButtonTab();
			List<Button> buttons = new List<Button>();
			// ボタン定義情報を取得する
			for(Dom.XMLNode xmlNode : tabButtonsNode.getChildElements()) {
				String attributeName = xmlNode.getName();
				// 該当グループのタブ名を取得する
				if(attributeName.equalsIgnoreCase('TABLABEL')){
					oneTab.label = CommUtils.nullToBlank(xmlNode.getText());
					continue;
				}
				// 個別ボタン設定情報を取得、設定する
				if(attributeName.equalsIgnoreCase('BUTTON')) {
					// 新規ボタン情報を取得する
					Button btn = new Button();
					buttons.add(btn);
					String strIsBlankBtn = CommUtils.nullToBlank(xmlNode.getAttribute('ISBLANK', null));
					btn.isBlankBtn = CommUtils.isBlank(strIsBlankBtn) ? false  : Boolean.valueOf(strIsBlankBtn);
					if (btn.isBlankBtn) continue;	// 空白ボタンの場合、次の処理を飛ばす
					
					// ボタン定義情報を取得する
					Dom.XmlNode btnLabelField = xmlNode.getChildElement('LABEL',null);		// ボタン表示名
					Dom.XmlNode btnProdField = xmlNode.getChildElement('PRODCODE',null);	// ボタン関連の商品コード
					Dom.XmlNode btnIconField = xmlNode.getChildElement('ICONURL',null);		// ボタンに表示する画像のURL
					
					if (btnLabelField != null) {
						btn.lable = CommUtils.nullToBlank(btnLabelField.getText());
					}
					if (btnProdField != null) {
						btn.prodCode = CommUtils.nullToBlank(btnProdField.getText());
						prodCodeSet.add(btn.prodCode);
					}
					if (btnIconField != null) {
						btn.iconUrl = CommUtils.nullToBlank(btnIconField.getText());
					}
				} // ボタン定義情報格納済
			}

			// 該当グループにボタンの場所を一回設定する
			// 可能済のボタン数
			Integer btnsCount = 0;
			// 商品コードにより、商品関連情報を格納する
			OneRowButtons oneRow = null;
			for (Button btn : buttons) {
				// ボタンは商品コード単位で、設定情報を格納する
				if(!CommUtils.isBlank(btn.prodCode)) buttonsIconMap.put(btn.prodCode, btn.iconUrl);
				// １行の会計商品情報を格納する
				if (Math.mod(btnsCount , layoutInfo.colNums) == 0) {
					oneRow = new OneRowButtons();
					oneTab.addOneRowButtons(oneRow);
				}
				oneRow.addButton(btn);
				btnsCount++;
			}
			buttonsLstTab.add(oneTab);
		}
		
		// 商品コード関連の商品情報を取得する
		Map<String, ProductItemUtils.ProductItem>  prodMaps = ProductItemUtils.getMapProductItemByCodes(prodCodeSet, false);
		exitProdLst = new List<Product>();
		// XMLから定義して無効な商品を外す
		for (ButtonTab buttonTab : buttonsLstTab) {
			for (OneRowButtons oneRow : buttonTab.rowButtons) {
				for (Button btn : oneRow.buttons) {
					// 該当商品コードは無効なコードの場合、該当ボタンを無効に設定する
					btn.isNotFound = !prodMaps.containsKey(btn.prodCode);
					Product p = new Product(prodMaps.get(btn.prodCode),btn.iconUrl);
					exitProdLst.add(p);
				}
			}
		}
		// 各ボタン関連の会計商品情報をJSON化
		oProdMapsJson = JSON.serialize(prodMaps);
	}
	public List<Product> exitProdLst;
	public class PageLayout {
		public PageLayout () {
			colNums = 3;
			tableWidth = '450' ;
			tableHeight = '260' ;
		}
		public Integer colNums{get; set{
			colNums = value > 0 ? value : 3;
		}}	// 1行N列情報を格納する
		public String btnStyle{get; set;}	// ボタンスタイル
		public String tableWidth{get;private set;}
		public String tableHeight{get;private set;}
	}
	public class ButtonTab {
		public ButtonTab(){
			rowButtons = new List<OneRowButtons>(); 
		}
		public String label			{get;set;}
		public List<OneRowButtons> rowButtons {get; private set;}
		public void addOneRowButtons(OneRowButtons pOneRowButtons) {
			rowButtons.add(pOneRowButtons);
		}
	}
	public class OneRowButtons {
		public OneRowButtons () {
			buttons = new List<Button>();
		}
		public List<Button> buttons{get; private set;}
		public void addButton(Button btn) {
			buttons.add(btn);
		}
	}
	// 会計支払ボタン情報格納
	public class Button {
		public Button () {
			isBlankBtn = false;
			isNotFound = false;
		}
		public String lable	   {get; set;}	// ボタン表示のラベル名[英語版の場合、英語に設定する]
		public String prodCode {get; set;}	// 関連の商品コード
		public String iconUrl  {get; set;}	// ボタン関連のICONのURL
		public Boolean isBlankBtn {get;set;}
		public Boolean isNotFound {get;set;}
	}
	
	public class Product{
		Product(ProductItemUtils.ProductItem item,String url){
			productItem = item;
			iconUrl = url;
		}
		public ProductItemUtils.ProductItem productItem;
		public String iconUrl;
	}

}