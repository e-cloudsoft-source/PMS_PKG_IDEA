/*****************
* システム構築するため、関連のXML自動作成ツール
* 2015/03/09 会計メニューの商品選べるメニュー定義XML作成機能対応
* 2015/06/05 会計商品関連の情報は特殊符号が転換処理追加
*****************/
public with sharing class ApplicationUtilCtrl{

	// 商品メニューのXMLのテンプレート分を定義する
	private static final String XML_TEMPLATE_BILLPRODUCTCONFIG = '<?xml version="1.0" encoding="UTF-8"?>\n<ROOT>\n<SHOP>\n<SHOPCODE></SHOPCODE>\n<TABLEWIDTH>100%</TABLEWIDTH><TABLEHEIGHT>240px</TABLEHEIGHT>\n$$_TABGROUPS_$$\n</SHOP>\n</ROOT>';
    private static final String XML_TEMPLATE_BILLPRODUCTCONFIG_TABGROUP_TEMPLATE = '\n<TABGROUP>\n<TABLABEL>$$_TABLABEL_$$</TABLABEL>\n<LAYOUT>\n<BTNSTYLE>width:115px;height:30px</BTNSTYLE>\n</LAYOUT>\n$$_PRODUCTS_$$\n</TABGROUP>';
    private static final String XML_TEMPLATE_BILLPRODUCTCONFIG_PRODUCT_TEMPLATE = '<PRODUCT><CODE>$$_PRODUCT_CODE_$$</CODE><NAME>$$_PRODUCT_NAME_$$</NAME></PRODUCT>';

    // 会計商品情報を取得する用関連SQL定義
    private static final String SQL_QUERYFIELD01 ='Select Field4__r.Name,Field4__c, GPChange__c,GPChange__r.Name, DPChange__c,DPChange__r.Name, OP__c,OP__r.Name,Field3__c, Name From AccountMaster__c';
 	// タブグループ指定の項目はNULLの場合、タブ名は「その他」で指定する
 	//その他
 	private static final String XML_TEMPLATE_BILLPRODUCTCONFIG_TABNAME_OTHER = Label.CONST_012_0431;
    public String tabName		{get;set;}		// タブグループ種別
    public String sortTab		{get;set;}
    public String sortTabOrder	{get;set;}
    public String sortProd		{get;set;}		// 並び順項目
    public String sortProdOrder	{get;set;}		// 並び順

	// 自動作成の会計商品のメニュー情報を格納する
	//public transient String outProductXml{get; private set;}
	public transient Id targetDocId{get; private set;}
    // 自動作成のXMLファイル名
    //public String xmlFileName{get{return System.now().format('yyyyMMddHHmmss') + '_BillSimpleProductConfig.xml';}}
	public transient String downUrl{get; private set;}

    public ApplicationUtilCtrl(){
    	// 画面初期値設定を行う
        tabName = 'DPChange__c';
        sortTab = 'code';
        sortProd ='Field3__c';	// 商品コード
        sortTabOrder = 'asc';
        sortProdOrder = 'asc';

    }
	// XML作成のMethodを呼び出しする
    public String generalProdcutMenuXml(){

        String noShowFilter = CommConst.PROD_ACTION_TYPE_NO;	// 非表示
        String noPayFilter  = CommConst.PROD_ACTION_TYPE_PY;	// 支払
        String noPrePayFilter = CommConst.PROD_ACTION_TYPE_AR;	// 前受金
        // 会計商品は非公開　かつ　非表示以外の会計商品を取得する
        String whereStr = ' Where (ActionType__c != :noShowFilter And ActionType__c != :noPayFilter And ActionType__c != :noPrePayFilter) And IsClosed__c = false And Field3__c != null ';
        String orderStr =  ' order by '; //+ tabName  + ',' + sortField + ' ' + sortOrder;
        // 並び順のSQLを作成する
        if (tabName == 'DPChange__c') {
			// 2017/02/08 PortalSecurity 対応 zyz BEGIN
        	if (sortTab == 'code') orderStr += ' DPChange__r.Field1__c ' + String.escapeSingleQuotes(sortTabOrder);
        	else orderStr += ' DPChange__r.Name ' + String.escapeSingleQuotes(sortTabOrder);
			// 2017/02/08 PortalSecurity 対応 zyz END
        } else if (tabName == 'Field4__c') {
			// 2017/02/08 PortalSecurity 対応 zyz BEGIN
        	if (sortTab == 'code') orderStr += ' Field4__r.Field1__c ' + String.escapeSingleQuotes(sortTabOrder);
        	else orderStr += ' Field4__r.Name ' + String.escapeSingleQuotes(sortTabOrder);
			// 2017/02/08 PortalSecurity 対応 zyz END
        } else if (tabName == 'GPChange__c') {
			// 2017/02/08 PortalSecurity 対応 zyz BEGIN
        	if (sortTab == 'code') orderStr += ' GPChange__r.Field1__c ' + String.escapeSingleQuotes(sortTabOrder);
        	else orderStr += ' GPChange__r.Name ' + String.escapeSingleQuotes(sortTabOrder);
			// 2017/02/08 PortalSecurity 対応 zyz END
        } else if (tabName == 'OP__c') {
			// 2017/02/08 PortalSecurity 対応 zyz BEGIN
        	if (sortTab == 'code') orderStr += ' OP__r.OPcode1__c ' + String.escapeSingleQuotes(sortTabOrder);
        	else orderStr += ' OP__r.Name ' + String.escapeSingleQuotes(sortTabOrder);
			// 2017/02/08 PortalSecurity 対応 zyz END
        }
        String lastNullStr = ' NULLS LAST ';
		// 2017/02/08 PortalSecurity 対応 zyz BEGIN
        orderStr += lastNullStr + ',' + String.escapeSingleQuotes(sortProd) + ' '  +  String.escapeSingleQuotes(sortProdOrder);
		// 2017/02/08 PortalSecurity 対応 zyz END

        // タブグループ指定の項目のIDはNULLの場合、「その他」で定義する
        String queryStr = SQL_QUERYFIELD01 + whereStr + orderStr ;
        // 出力するXML情報を格納する
        //outProductXml = XML_TEMPLATE_BILLPRODUCTCONFIG;
        // タブグループ区分するため、ID情報格納用変数
        //Set<Id> tabGroupIdSet = new Set<Id>();
        List<Id> tabGroupIdList = new List<Id>();
        Map<Id, String> tabLabelMap = new Map<Id, String>();
        Map<Id, List<AccountMaster__c>> groupProductsMap = new Map<Id, List<AccountMaster__c>>();
		// 取得した会計商品情報をXMLへ反映を行う
		for (AccountMaster__c s : Database.query(queryStr)) {
            //Id key = tabName == 'OP__c' ? s.OP__c :(tabName == 'GPChange__c' ? s.GPChange__c : s.DPChange__c);
            Id key = s.OP__c;
            if (tabName == 'GPChange__c') key = s.GPChange__c;
            else if (tabName == 'DPChange__c') key = s.DPChange__c;
            else if (tabName == 'Field4__c') key = s.Field4__c;
            // グループ単位商品情報集める
            if (!groupProductsMap.containsKey(key)) {
            	// 格納の商品情報を格納する
            	groupProductsMap.put(key, new List<AccountMaster__c>());
            	// 表示順コントロールリスト
            	tabGroupIdList.add(key);

	            String tabLabel = s.OP__r.name;
	            if (tabName == 'GPChange__c') {
	            	tabLabel = s.GPChange__r.Name;
	            } else if (tabName == 'DPChange__c') {
	            	tabLabel = s.DPChange__r.Name;
	            } else if (tabName == 'Field4__c') {
	            	tabLabel = s.Field4__r.Name;
	            }
	            if (CommUtils.isBlank(key)) tabLabel = XML_TEMPLATE_BILLPRODUCTCONFIG_TABNAME_OTHER;
            	tabLabelMap.put(key, tabLabel.escapeXml());
            }
            groupProductsMap.get(key).add(s);
        }
        // グループの会計メニュー情報を格納する
        String tabGroupXml = '';
        for (Id key : tabGroupIdList) {
        	// 1グループの会計メニュー情報を格納する
        	String oneTabGroupXml = XML_TEMPLATE_BILLPRODUCTCONFIG_TABGROUP_TEMPLATE
        								.Replace('$$_TABLABEL_$$',tabLabelMap.get(key));
        	String productsXml = '';
        	for (AccountMaster__c s: groupProductsMap.get(key)) {
        		productsXml += '\n' + XML_TEMPLATE_BILLPRODUCTCONFIG_PRODUCT_TEMPLATE
            									.Replace('$$_PRODUCT_CODE_$$', s.Field3__c)
                								.Replace('$$_PRODUCT_NAME_$$', s.Name.escapeXml());
        	}
        	tabGroupXml += oneTabGroupXml.Replace('$$_PRODUCTS_$$', productsXml);
        }
		// 支店単位のXML情報を作成する
		String outProductXml = XML_TEMPLATE_BILLPRODUCTCONFIG.Replace('$$_TABGROUPS_$$', tabGroupXml);
        /*PageReference customPage = new PageReference('/apex/BillSimpleProductConfigXmlGen');
        customPage.setRedirect(false);
        return customPage;*/
        saveXmlToFloder(outProductXml);
        return null;
    }
    /**
    * XML情報により、ワークフォルダに格納する
    **/
	private void saveXmlToFloder(String xmlBodyStr) {
		// 2017/02/24 Field Security Check BEGIN by wx
		List<String> insChkFields = new List<String>{'Description','FolderId','Name','ContentType','type',
													'body','DeveloperName'};
		Map<String,Schema.SObjectField> insm = Schema.SObjectType.Document.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(insChkFields, insm)) {
			return;
		}
		// 2017/02/24 Field Security Check END by wx
		//System.debug(logginglevel.info,'Field Security Check:::[138-145]:::>>Pass');
		// ファイル格納のフォルダを取得する
		List<Folder> fs = [select id from Folder where DeveloperName = 'WorkFiles'];
		// TimeStamp
		String timeStamp = System.now().format('yyyyMMddHHmmss');
		String developerNm = 'BillSimpleProductConfigWork';
		//会計商品メニュー定義情報
		String fileName = Label.CONST_012_0432;
		// 関連のドキュメント存在チェックを行う
        List<Document> existDocs = [select id from Document where Name = :fileName And FolderId = :fs[0].Id];
        if (!existDocs.isEmpty()) {
			existDocs[0].body = Blob.valueOf(xmlBodyStr);
			update existDocs[0];
			targetDocId = existDocs[0].Id;
        } else {
	        // CSVファイルをアップロードする
	        Document newDoc = new Document(
	        	DeveloperName = developerNm + '_' + CommUtils.getRandom(10),
	        	//会計商品メニュー定義情報(自動作成)_
	        	Description = Label.CONST_012_0433 + timeStamp,
	        	FolderId = fs[0].Id,
	        	Name = fileName,
	        	ContentType = 'text/xml',
	        	type = 'xml',
	        	body = Blob.valueOf(xmlBodyStr)
	        );
        	insert newDoc;
        	targetDocId = newDoc.Id;
        }
        // 処理済の情報を更新する
		downUrl = '/servlet/servlet.FileDownload?file=' + targetDocId;
	}
}