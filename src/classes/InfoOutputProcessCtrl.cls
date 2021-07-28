/*********************************************
* CSV情報を取得機能対応
* 2015/12/04 INIT
**/
public with sharing class InfoOutputProcessCtrl {

	public static final String PrefixKey = 'KOUZA_';
	private final String ProcessJobNo;
	private final String SalesLoginUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/';
	
	private final String KouzaCsvTemplate = '$$_番号_$$,$$_金融機関番号_$$,$$_支店番号_$$,$$_預金種目_$$,$$_口座番号_$$,$$_取引先名_$$,$$_金融機関名_$$,$$_金融機関名カナ_$$,$$_支店名_$$,$$_支店名カナ_$$,$$_名義人_$$,$$_振込手数料負担先_$$,$$_委託者コード_$$,$$_口座種別_$$,$$_ステータス_$$,$$_URL_$$\n';
	private list<id> kouzaIdLst;
	public InfoOutputProcessCtrl() {
		ProcessJobNo = System.now().format('yyyyMMddHHmmss');
	}
	/**
	* 口座情報一覧を取得する
	**/
	public PageReference generalKouzaInfo() {
		// パラメータから引き渡す口座IDの場合、口座情報取得条件に該当限定条件を追加する
		kouzaIdLst = new List<String>();
		String conId = ApexPages.currentPage().getParameters().get('rIds'); 
		if (!Commutils.isBlank(conId)) {
			for(String str : conId.split(',')) {
	    		kouzaIdLst.add(str);
			}
		}
		RecordType rt = [SELECT Id,Name FROM RecordType WHERE DeveloperName='CompanyRecordType' LIMIT 1];
		
		String queryStr = 'Select Id,recordTypeId,name,BankNumber__c,BankBranchNumber__c,BankNameKana__c,BankBranchNameKana__c,AccountTypeLst__c,DepositsType__c,BankAccountNo__c,ShopInfoRef__c,ShopInfoRef__r.Name,AccountRef__c,AccountRef__r.Name,BankName__c,BankBranchName__c,RequestUserName__c,TransferChargeKbn__c,RequestUserCode__c,StatusLst__c from ShopAccountInfo__c';
		if (!kouzaIdLst.isEmpty()) {
			queryStr += ' Where id in :kouzaIdLst ';
		}
		queryStr += ' Order By RecordTypeId, ShopInfoRef__r.Name,AccountRef__r.Name Limit 10000 ';
		String csvBody = Label.MSG_051_0001+'\n';
		for (ShopAccountInfo__c kouza : DataBase.query(queryStr)) {
			String accountName = CommUtils.nullToBlank(kouza.AccountRef__r.Name);
			if (rt.Id == kouza.recordTypeId) {
				accountName = CommUtils.nullToBlank(kouza.ShopInfoRef__r.Name);
			}
			String oneLineCsv = KouzaCsvTemplate
								.Replace('$$_番号_$$'		, CommUtils.nullToBlank(kouza.Name))
								.Replace('$$_金融機関番号_$$'	, CommUtils.nullToBlank(kouza.BankNumber__c))
								.Replace('$$_支店番号_$$'		, CommUtils.nullToBlank(kouza.BankBranchNumber__c))
								.Replace('$$_預金種目_$$'		, CommUtils.nullToBlank(kouza.DepositsType__c))
								.Replace('$$_口座番号_$$'		, CommUtils.nullToBlank(kouza.BankAccountNo__c))
								.Replace('$$_取引先名_$$'		, accountName)
								.Replace('$$_金融機関名_$$'	, CommUtils.nullToBlank(kouza.BankName__c))
								.Replace('$$_金融機関名カナ_$$', CommUtils.nullToBlank(kouza.BankNameKana__c))
								.Replace('$$_支店名_$$'		, CommUtils.nullToBlank(kouza.BankBranchName__c))
								.Replace('$$_支店名カナ_$$'	, CommUtils.nullToBlank(kouza.BankBranchNameKana__c))
								.Replace('$$_名義人_$$'		, CommUtils.nullToBlank(kouza.RequestUserName__c))
								.Replace('$$_振込手数料負担先_$$'	, CommUtils.nullToBlank(kouza.TransferChargeKbn__c))
								.Replace('$$_委託者コード_$$'	, CommUtils.nullToBlank(kouza.RequestUserCode__c))
								.Replace('$$_口座種別_$$'		, CommUtils.nullToBlank(kouza.AccountTypeLst__c))
								.Replace('$$_ステータス_$$'	, CommUtils.nullToBlank(kouza.StatusLst__c))
								.Replace('$$_URL_$$'		, SalesLoginUrl + kouza.id);
			csvBody += oneLineCsv;
		}
		//  ユーザー所属店舗情報を取得する
		String shopCode = UserUtil.CurrentUserInfo.defaultShopCode;
		ShopInformation__c shop = new ShopInformation__c();
		if (!CommUtils.isBlank(shopCode)) {
			shop = ShopInfoUtil.getShop(shopCode);
		}
		Document newDoc = createFileToSyncFloder(csvBody, shop);
		Pagereference page = new Pagereference('/apex/PcaSyncCsvDownload?rid=' + newDoc.id);
		return page;
	}
	/**
	* フォルダに連携結果を保存する
	**/
	private Document createFileToSyncFloder(String csvBody, ShopInformation__c shop) {
		// 2017/02/23 Field Security Check BEGIN by wx
		List<String> insChkFields = new List<String>{'Description','FolderId','Name','ContentType','type','body','DeveloperName'};
		Map<String,Schema.SObjectField> insm = Schema.SObjectType.Document.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(insChkFields, insm)) {
			return null;
		}
		// 2017/02/23 Field Security Check End by wx
		// 添附ファイル名				
		String fileName = PrefixKey + ProcessJobNo
						+ ( CommUtils.isBlank(shop.ShopCode__c) ? '' : '_' + ( shop.ShopCode__c + '(' +shop.Name  + ')') ) 
						+ '.csv';	
		// ファイル格納のフォルダを取得する
		List<Folder> fs = [select id from Folder where DeveloperName = 'SyncFiles' limit 1];
        // CSVファイルをアップロードする
        Document newDoc = new Document(
        	DeveloperName = PrefixKey+ ProcessJobNo + (CommUtils.isBlank(shop.ShopCode__c) ? '' : '_' + shop.ShopCode__c),
        	//口座情報出力_
        	Description = Label.CONST_040_0103 +PrefixKey +System.now().format('yyyyMMddHHmmss'),
        	FolderId = fs[0].Id,
        	Name = fileName,
        	ContentType = 'text/csv',
        	type = 'csv',
        	body = Blob.valueOf(csvBody)
        );
        insert newDoc;
        return newDoc;
	}
}