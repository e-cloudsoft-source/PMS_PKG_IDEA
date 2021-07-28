/**
* 日次処理：振込データ出力機能
* 2015.11.11 INIT
* 2015.11.23 振込金額処理結果内容改善
* 2015.12.07 仕入抽出条件指定可能機能対応
* 2015.12.17 指定ボタンの条件により、仕入情報を取得機能の改善
**/
public with sharing class BulkProcessBankImportCsvBatch implements Database.Batchable<sObject>, Database.Stateful {
	// 処理店舗コード
	public final String gShopCode;
	// 処理開始日
	public final Date gStDate;
	// 処理終了日
	public final Date gEdDate;
	// ステータス
	public final String gStatus;
	// 振込手数料
	public final Date gFurikomiDate;
	// ヘーダ表示する・なし制御
	public final Boolean gIsShowHeader;
	// XML定義情報
	private final AccountingSyncBatchHelp gSyncHelp;
	// バッチ処理のSEQNO
	public final String batchProcessJobNo;					
	// スケジュールで該当Methodを呼び出する
	public BulkProcessBankImportCsvBatch(){}
	// 既に処理済に仕入先IDを情報を格納する
	private set<id> processedAccountIdSet;
	// 出力のCSV情報を格納する
	private String gCsvBody;
	// 仕入先の処理件数う
	private Integer gCsvLines;
	// 振込総金額
	private Decimal gCsvAmount;
	// 処理対象仕入データ
	private final String Query = 'select id,Purchasesource__c from Purchase__c where Field1__c <= :gEdDate and Field1__c >= :gStDate And Purchasesource__c != null And (DenpyoukeiIncTax__c != null And DenpyoukeiIncTax__c != 0)  ';
	// 処理単位のログ記述する
	private string errMsgDetail = '';
	// SecurityKey
	private final static String securityCode = 'PMS_JINYACONNECT_BANK_KEY_2015';
	// 2015.12.07 仕入抽出条件指定可能機能対応
	private final String gFilterStr;
	// 初期化する
	public BulkProcessBankImportCsvBatch (String pShopCode, Date psdate, Date pedate, String pstatus, Date pFurikomiDate,Boolean pIsShowHeader, String pFilterStr) {
		gShopCode = pShopCode;
		gStDate = psdate;
		gEdDate = pedate;
		gStatus = pstatus;
		gFurikomiDate = pFurikomiDate;
		gIsShowHeader = pIsShowHeader;
		batchProcessJobNo = 'BANK_' + System.now().format('yyyyMMddHHmmss');
		processedAccountIdSet = new set<Id>();
		gCsvBody = '';
		gCsvLines = 0;
		gCsvAmount = 0;
		gSyncHelp = new AccountingSyncBatchHelp(gShopCode);
		// 2015.12.07 仕入抽出条件指定可能機能対応 BEGIN
		gFilterStr = pFilterStr;
		// 2015.12.07 仕入抽出条件指定可能機能対応 END
	}
	// ***********************************
	// スケジュール処理開始
	// ***********************************
	/*
	public void execute(SchedulableContext SC) {
		// スケジュールを起動する
		BulkProcessBankImportCsvBatch batch = new BulkProcessBankImportCsvBatch(gShopCode, gStDate, gEdDate, gStatus, gFurikomiDate,gIsShowHeader);
		// バッチ処理設定
		DataBase.executeBatch(batch,10);
	}*/
	// ***********************************
	// バッチ処理開始
	// ***********************************
	public Database.QueryLocator start(Database.BatchableContext BC){
		String plusFilterStr = CommUtils.nullToBlank(gSyncHelp.queryPlusFilter);
		// 2015.12.07 仕入抽出条件指定可能機能対応 BEGIN
		if (!CommUtils.isBlank(gFilterStr)) plusFilterStr = gFilterStr;
		// 2015.12.07 仕入抽出条件指定可能機能対応 END
		String queryStr = Query;
		if (!CommUtils.isBlank(gShopCode)) queryStr += ' And shopInfoRef__r.ShopCode__c = :gShopCode ';
		if (!CommUtils.isBlank(plusFilterStr)) queryStr += ' And ' +plusFilterStr;
		queryStr += ' order by Purchasesource__c';
		return Database.getQueryLocator(queryStr);
	}
	// ***********************************
	// バッチロジック処理開始
	// ***********************************
	public void execute(Database.BatchableContext BC, List<Purchase__c> scope){
		// 処理対象仕入先
		List<Id> accountIds = new List<Id>();
		Boolean isFirstLoop = processedAccountIdSet.isEmpty();
		// 支店コードを取得する
		for (Purchase__c pur : scope) {
			if (processedAccountIdSet.contains(pur.Purchasesource__c)) continue;
			processedAccountIdSet.add(pur.Purchasesource__c);	
			accountIds.add(pur.Purchasesource__c);
		}
		if (accountIds.isEmpty()) return;
		//String errMsg = '';
		try {
			PurchaseManagentBankCsvProcess proc = new PurchaseManagentBankCsvProcess(accountIds,gShopCode,gStDate,gEdDate,gFurikomiDate,new AccountingSyncBatchHelp(gShopCode),gIsShowHeader,gFilterStr); 
			PurchaseManagentBankCsvProcess.ResultInfo retRs = proc.generalBankImportCsv(isFirstLoop);
			gCsvLines+= retRs.rsNums;
			gCsvAmount += retRs.rsAmount;
			gCsvBody += retRs.csvBody;
			// 関連処理済みの仕入先情報を追加
			processedAccountIdSet.addAll(retRs.outputAccIdSet);
			// ログを記録する
			if (proc.log.isHaveError()) errMsgDetail += '\n' +proc.log.getAllError();
		} catch (Exception e) {
			errMsgDetail += '\n' + e.getmessage();
		}
	}
	// ***********************************
	// バッチ終了処理開始
	// ***********************************
	public void finish(Database.BatchableContext BC){

		// 最後のFOOTER電文を作成する
		AccountingSyncBatchHelp config = null;
		try {
			config = new AccountingSyncBatchHelp(gShopCode);
			// Header情報が存在する場合
			if (!CommUtils.isBlank(gCsvBody)) {
				// FOOTER CSV GENERAL
				PurchaseManagentBankCsvProcess proc = new PurchaseManagentBankCsvProcess(null,gShopCode,gStDate,gEdDate,gFurikomiDate,config,gIsShowHeader,gFilterStr); 
				gCsvBody += proc.generalBankImportCsvEnd(gCsvLines,gCsvAmount);
				// ログを記録する
				if (proc.log.isHaveError()) errMsgDetail += '\n' +proc.log.getAllError();
			}
		} catch (Exception e) {
			errMsgDetail += '\n' +e.getmessage();
		}
		CommLogUtils log = new CommLogUtils('BulkProcessBankImportCsvBatch', true);
		log.write_method_start('処理結果：');
		// 処理情報を記録する
		log.write_log('【状態：'+gStatus+'】');
		log.write_log('【振込指定日：'+DateTime.newInstance(gFurikomiDate.year(),gFurikomiDate.month(),gFurikomiDate.day()).format('yyyy/MM/dd')+'】');
		log.write_log('【取引名：'+System.now().format('MM/dd')+'作成分】');
		//log.write_log('仕入先['+processedAccountIdSet.size()+']件中に');
		// 2015/11/17 指摘により、出力文言を変更する
		log.write_log('【明細出力件数：'+gCsvLines+'件】');
		//log.write_log('失敗:['+(processedAccountIdSet.size()-gCsvLines)+']件');
		if (!CommUtils.isBLank(errMsgDetail)) {
			log.write_log('【処理詳細:】');
			log.write_log(errMsgDetail);
		}
		// 連携結果履歴に記録する
		// メール通知先のメールアドバイスを取得、設定する
		// 新規作成を行う
		CooperationResult__c newCoop = new CooperationResult__c(
			FunctionType__c = AccountingSyncBatchHelp.COOP_STATUS_PURCHASE_BANKIMP,
			ErrorCount__c = log.isHaveError() ? 1 : 0,
			ErrorContent__c = CommLogUtils.removeOverLogString(log.getAllError(),255),
			MailSendComplete__c = false,
			ShopCode__c = gShopCode,
			ProcessLog__c =  log.getAllLog()
		);
		// メールアドバイス設定する
		setSendMailAddress(newCoop,config);
		insert newCoop;
		// CSVファイルを作成する
		if (!CommUtils.isBlank(gCsvBody)) {
			Map<String,ShopInformation__c> shopMap = ShopInfoUtil.getShopInfoMap();
			ShopInformation__c shop = shopMap.get(gShopCode);
			if (shop == null) shop = new ShopInformation__c();
			createFileToSyncFloder(gCsvBody, shop);
		}
		log.write_method_end();
	}
	
	/**
	* フォルダに連携結果を保存する
	**/
	private void createFileToSyncFloder(String csvBody, ShopInformation__c shop) {
		// 2017/02/24 Field Security Check BEGIN by wx
		List<String> insChkFields = new List<String>{'Description','FolderId','Name','body','DeveloperName'};
		Map<String,Schema.SObjectField> insm = Schema.SObjectType.Document.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(insChkFields, insm)) {
			return;
		}
		// 2017/02/24 Field Security Check End by wx
		// ファイル格納のフォルダを取得する
		List<Folder> fs = [select id from Folder where DeveloperName = 'SyncFiles'];
		String fileName = batchProcessJobNo
						+ ( CommUtils.isBlank(shop.ShopCode__c) ? '' : '_' + ( shop.ShopCode__c + '(' +shop.Name  + ')') ) 
						+ (gIsShowHeader != true ? '.txt' : '.csv');	
        // CSVファイルをアップロードする
        Document newDoc = new Document(
        	DeveloperName = batchProcessJobNo + (CommUtils.isBlank(shop.ShopCode__c) ? '' : '_' + shop.ShopCode__c),
        	//連携結果_
        	Description = Label.CONST_040_0095 + batchProcessJobNo,
        	FolderId = fs[0].Id,
        	Name = fileName,
        	ContentType = (gIsShowHeader != true ? 'text/plain' : 'text/csv'),
        	type = (gIsShowHeader != true ? 'txt' : 'csv'),
        	body = Blob.valueOf(csvBody)
        );
        insert newDoc; 
	}
	/**
	* メール通知先のアドレス宛を設定する
	**/
	private void setSendMailAddress(CooperationResult__c coop, AccountingSyncBatchHelp config) {
		if (config == null || config.sendMailAddr.isEmpty()) return;
		// メール送信
		coop.MailSendAddress1__c = config.sendMailAddr[0];
		if (config.sendMailAddr.size() > 1) coop.MailSendAddress2__c = config.sendMailAddr[1];
		if (config.sendMailAddr.size() > 2) coop.MailSendAddress3__c = config.sendMailAddr[2];
		if (config.sendMailAddr.size() > 3) coop.MailSendAddress4__c = config.sendMailAddr[3];
		if (config.sendMailAddr.size() > 4) coop.MailSendAddress5__c = config.sendMailAddr[4];
	}
}