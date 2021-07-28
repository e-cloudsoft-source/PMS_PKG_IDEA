/**
* 消費税増税処理対応バッチ[既存会計商品の単価を更新する]
* 2014/04/01の単価区分は２の場合、会計商品の単価はは５％元から８％に更新する
* 2019/08/12消費税は8%から10%に変更対応
**/
public with sharing class SalesPrice8UpdaterChouman  implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

	public String Query;					// 検索SOQL
	
	// 増税開始の日付を定義する
	//private static final Date CONST_TAXRATE_CHGDATE = Date.newInstance(2014,4,1); 
	// 2019/08/12消費税は8%から10%に変更対応 WSQ BEGIN
	//private static final String CONST_BATCH_STATUS = '1';	// 2014/04/01 ５％ー＞８％へ増税処理済みフラグ
	//private static final Decimal CONST_OLD_TAXRATE = 5;
	//private static final Decimal CONST_NEW_TAXRATE = 8;
	private static final String CONST_BATCH_STATUS = '2';	// 2019/08/12消費税は8%から10%へ増税処理済みフラグ
	private static final Decimal CONST_OLD_TAXRATE = 8;
	private static final Decimal CONST_NEW_TAXRATE = 10;
	// 2019/08/12消費税は8%から10%に変更対応 WSQ END
	private static final String CONST_SF_BASEURL = 'https://login.salesforce.com';

	// 処理成功件数と失敗件数統計する
	private Integer IsOKCounts;
	private Integer IsNgCounts;
	private String errorMessage;
	// スケジュール定義者
	private Id scheduleCreatedById;
	
	// スケジュールインスタンス関数
	public SalesPrice8UpdaterChouman () {}
	// バッチ起動インスタンス関数
	public SalesPrice8UpdaterChouman (Id userId) {
		// 単価処理区分
		Integer CONST_UNITPRICE_KBN = CommDefine__c.getInstance().UnitPriceDefKb__c == null 
										? 1 
										: CommDefine__c.getInstance().UnitPriceDefKb__c.intValue();
		// 会計商品情報の単価は＞０＆＆該当商品の消費税率は＞０の場合
		Query = ' Select Id, Name, Field5__c,jmstRef__r.TaxRate__c,ServiceRate__c from AccountMaster__c where Field5__c > 0 And jmstRef__r.TaxRate__c > 0 And BatchProcessStatusDiv__c != :CONST_BATCH_STATUS ';
System.debug(LoggingLevel.INFO, 'CONST_UNITPRICE_KBN::'+CONST_UNITPRICE_KBN);
		// 商品単価区分は【２】の場合、消費税により、単価再計算、設定を行う
		// 2019/08/12消費税は8%から10%に変更対応 WSQ BEGIN
		// 商品単価区分は【１】【２】の場合、消費税により、単価再計算、設定を行う
		//if (CONST_UNITPRICE_KBN != CommConst.APPOPTION_UTP_DEF_KB_OP2) {
		if (CONST_UNITPRICE_KBN != CommConst.APPOPTION_UTP_DEF_KB_OP2 && CONST_UNITPRICE_KBN != CommConst.APPOPTION_UTP_DEF_KB_OP1) {
		// 2019/08/12消費税は8%から10%に変更対応 WSQ END
			Query += ' And ID = null ';		// 単価定義区分は２以外の場合、処理対象外になる
		}
System.debug(loggingLevel.INFO, Database.query(Query));
		
		IsOKCounts = 0;
		IsNgCounts = 0;
		errorMessage = '';
		scheduleCreatedById = userId;
		// 5% -> 8%処理を行う
		updateTaxRateMst();
	}
	// ***********************************
	// 消費税５％ー＞８％変更ロジック対応する　
	// ***********************************	
	private void updateTaxRateMst () {
		// 2018/03/07 Security Check BEGIN
		List<String> chkFields = new List<String>{'TaxRate__c'};
		Map<String,Schema.SObjectField> m = Schema.SObjectType.JMST__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(chkFields, m)) {
			return;
		}
		// 2018/03/07 Security Check END
		// 商品税５％のデータを探す、存在すると、更新を行う
		//Decimal fiveRate = 5;
		List<JMST__c> taxRates = [Select Id, TaxRate__c From JMST__c where TaxRate__c > 0 Order By CreatedDate asc limit 1];
		if (!taxRates.isEmpty()) {
			// 消費税設定率は５の場合、８％へ更新を行う
			if (taxRates[0].TaxRate__c == CONST_OLD_TAXRATE) {
				// 消費税
				taxRates[0].TaxRate__c = CONST_NEW_TAXRATE;
				update taxRates;
			}
		}
	}
	// ***********************************
	// スケジュール処理開始
	// ***********************************
   public void execute(SchedulableContext SC) {
   	  // スケジュール定義情報を取得して、スケジュール定義者へバッチ処理結果を送信する
   	  CronTrigger cron = [Select CreatedById From CronTrigger Where Id = :SC.getTriggerId() ];
      SalesPrice8UpdaterChouman batch = new SalesPrice8UpdaterChouman(cron.CreatedById);
      DataBase.executeBatch(batch);
   }
	// ***********************************
	// バッチ処理開始
	// ***********************************
	public Database.QueryLocator start(Database.BatchableContext BC){
System.debug(LoggingLevel.INFO, 'Query:::'+Query);		
    	return Database.getQueryLocator(Query);
	}

	/**
	* 情報集計
	**/
	public void execute(Database.BatchableContext BC, List<AccountMaster__c> scope){
		// 2018/03/07 Security Check BEGIN
		List<String> chkFields = new List<String>{'Field5__c','BatchProcessStatusDiv__c'};
		Map<String,Schema.SObjectField> m = Schema.SObjectType.AccountMaster__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(chkFields, m)) {
			return;
		}
		// 2018/03/07 Security Check END
		// #合計金額　＝　単価（税込）　＊　数量　＋　(単価（税込）　＊　数量) * サビース料金(%)　＋ 特別税　
    	//CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo();
    	// 更新
		List<AccountMaster__c> updLst = new List<AccountMaster__c>();
		// 更新対象予約見積明細情報を取得、更新内容を設定する
		for (AccountMaster__c subItem : scope) {
			// 単価再計算を行う(税抜き)[2桁まで保留する]
			Decimal noTaxPrice = CommUtils.CalExcTaxPrice(CommUtils.nullToZero(subItem.Field5__c),CONST_OLD_TAXRATE,2);
			// 税込み再計算を行う
			Decimal TaxPrice = CommUtils.CalIncTaxPrice(noTaxPrice, CONST_NEW_TAXRATE, 0);
			// 単価再定義を行う
			subItem.Field5__c = TaxPrice;
			subItem.BatchProcessStatusDiv__c = CONST_BATCH_STATUS;
			updLst.add(subItem);
		}
		if (!updLst.isEmpty()) {
			try {
				Database.SaveResult[] results = Database.update(updLst,false);
				if (results != null){
					Integer idx = 0;
					for (Database.SaveResult result : results) {
						if (!result.isSuccess()) {
							// エラー件数統計
							IsNgCounts++;
							Database.Error[] errs = result.getErrors();
							for(Database.Error err : errs) {
								errorMessage += '\nエラー発生：' + updLst[idx].Name + '('+err.getStatusCode() + ' - ' + err.getMessage()+')'+ '\n';
								errorMessage += CONST_SF_BASEURL + '/'+updLst[idx].Id;
							}	
						} else {
							// 成功件数統計
							IsOKCounts++;
						}
						idx++;
					}
				}
			} catch (Exception e) {
				System.debug(e.getTypeName() + ' - ' + e.getCause() + ': ' + e.getMessage());
			}
		}
	}
	/**
	* 処理終了
	**/
	public void finish(Database.BatchableContext BC){
		//　スケジュール定義者のメールで送付する
		User setupUser = [select email from User where id = :scheduleCreatedById];
		String mailAdds = setupUser.email;
		if (CommUtils.isBlank(mailAdds)) return;

		
		// メール情報を設定する
		String mailBodyStr = '処理結果詳細';
		mailBodyStr += '\n更新成功件数：' + IsOKCounts + '(件)';
		mailBodyStr += '\n更新失敗件数：' + IsNgCounts + '(件)';
		
		// 区分２以外の場合、処理対象外
		Integer CONST_UNITPRICE_KBN = CommDefine__c.getInstance().UnitPriceDefKb__c == null 
										? 1 
										: CommDefine__c.getInstance().UnitPriceDefKb__c.intValue();
		// 2019/08/12消費税は8%から10%に変更対応 WSQ BEGIN
		//if (CONST_UNITPRICE_KBN == CommConst.APPOPTION_UTP_DEF_KB_OP2) {
		if (CONST_UNITPRICE_KBN == CommConst.APPOPTION_UTP_DEF_KB_OP2 || CONST_UNITPRICE_KBN == CommConst.APPOPTION_UTP_DEF_KB_OP1) {
		// 2019/08/12消費税は8%から10%に変更対応 WSQ END
			// 未更新件数を統計する[消費金額>０　AND　消費率＞０]
			AggregateResult rsAvg = [Select count(id) cnt from AccountMaster__c where Field5__c > 0 And jmstRef__r.TaxRate__c > 0 And BatchProcessStatusDiv__c != :CONST_BATCH_STATUS ];
			Integer noUpdateRsNum = Integer.valueOf(rsAvg.get('cnt'));
			mailBodyStr += '\n未更新対象件数：' + (noUpdateRsNum - IsNgCounts) + '(件)';
			if (noUpdateRsNum != IsNgCounts ) {
				mailBodyStr += '\n未更新対象データが存在するため、データを確認の上て、バッチを再実施してください。';
			}
		}
		
		mailBodyStr += errorMessage;
		
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = new String[]{mailAdds};
		mail.setToAddresses(toAddresses);
		mail.setSubject('[SalesPrice8UpdaterChouman]バッチ処理結果の通知');
		mail.setPlainTextBody(mailBodyStr);
		// テストクラスの場合、実施しない
		if(!Test.isRunningTest())
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	}
/**
*2015-11-18 
*テストクラスSalesPrice8UpdaterChoumanTestに移行する
	@isTest(SeeAllData=false)
	static void testCase1() {
		// ２０１４・０３・３０開始４連泊予約情報を設定する
		//Date startDt = Date.newInstance(2014,3,30);
		//Date changeDate = Date.newInstance(2014,4,1);
    	// 予約情報を作成する(4連泊予約情報を作成する)
    	// カスタム設定情報を区分２に設定をおこなう
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	// 単価処理区分は２の場合
    	comDef.UnitPriceDefKb__c = CommConst.APPOPTION_UTP_DEF_KB_OP2;
    	update comDef;
    	// 会計商品作成を行う
    	List<AccountMaster__c> prods = TestCommon.createProductMst(4);
    	// 単価再定義
    	prods[0].Field5__c = 1050;
    	prods[1].Field5__c = 10500;
    	prods[2].Field5__c = 105000;
    	prods[2].jmstRef__c = null;
    	prods[3].Field5__c = 0;
    	update prods;
    	Map<Id, Decimal> equalPriceMap = new Map<Id, Decimal>();
    	equalPriceMap.put(prods[0].Id, 1080);
    	equalPriceMap.put(prods[1].Id, 10800);
    	equalPriceMap.put(prods[2].Id, 105000);
    	equalPriceMap.put(prods[3].Id, 0);
    	
 		Test.startTest();
		SalesPrice8UpdaterChouman m = new SalesPrice8UpdaterChouman();
		DateTime nowTime = DateTime.now().addSeconds(10);
		// 起動ＣＲＯＮを設定する
		String timeStr = nowTime.format('yyyyMMddHHmmss');
		String yy = timeStr.substring(0,4);
		String mm = timeStr.substring(4,6);
		String dd = timeStr.substring(6,8);
		String hh = timeStr.substring(8,10);
		String ms = timeStr.substring(10,12);
		String ss = timeStr.substring(12,14);
		String sch = ss + ' ' +
		       ms + ' ' +
		       hh + ' ' +
		       dd + ' ' +
		       mm + ' ' +
		       ' ? ' + yy;
		String jobName = DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, sch, m);
		// 単価再定義処理を行う
		SalesPrice8UpdaterChouman batch = new SalesPrice8UpdaterChouman(UserInfo.getUserId());
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		// 商品金額確認を行う
		List<AccountMaster__c> newProds = [select Id, Field5__c from AccountMaster__c where id in :equalPriceMap.keySet() limit 100];
		System.assertEquals(newProds.size(), 4, newProds);
		for (AccountMaster__c acc : newProds) {
			System.assertEquals(acc.Field5__c, equalPriceMap.get(acc.Id));
		}	
	}
	@isTest(SeeAllData=false)
	static void testCase2() {
		// ２０１４・０３・３０開始４連泊予約情報を設定する
		//Date startDt = Date.newInstance(2014,3,30);
		//Date changeDate = Date.newInstance(2014,4,1);
    	// 予約情報を作成する(4連泊予約情報を作成する)
    	// カスタム設定情報を区分２に設定をおこなう
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	// 単価処理区分は２の場合
    	comDef.UnitPriceDefKb__c = CommConst.APPOPTION_UTP_DEF_KB_OP3;
    	update comDef;
    	// 会計商品作成を行う
    	List<AccountMaster__c> prods = TestCommon.createProductMst(4);
    	// 単価再定義
    	prods[0].Field5__c = 1050;
    	prods[1].Field5__c = 10500;
    	prods[2].Field5__c = 105000;
    	prods[3].Field5__c = 0;
    	update prods;
    	Map<Id, Decimal> equalPriceMap = new Map<Id, Decimal>();
    	equalPriceMap.put(prods[0].Id, 1050);
    	equalPriceMap.put(prods[1].Id, 10500);
    	equalPriceMap.put(prods[2].Id, 105000);
    	equalPriceMap.put(prods[3].Id, 0);
    	
 		Test.startTest();
		SalesPrice8UpdaterChouman m = new SalesPrice8UpdaterChouman();
		DateTime nowTime = DateTime.now().addSeconds(10);
		// 起動ＣＲＯＮを設定する
		String timeStr = nowTime.format('yyyyMMddHHmmss');
		String yy = timeStr.substring(0,4);
		String mm = timeStr.substring(4,6);
		String dd = timeStr.substring(6,8);
		String hh = timeStr.substring(8,10);
		String ms = timeStr.substring(10,12);
		String ss = timeStr.substring(12,14);
		String sch = ss + ' ' +
		       ms + ' ' +
		       hh + ' ' +
		       dd + ' ' +
		       mm + ' ' +
		       ' ? ' + yy;
		String jobName = DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, sch, m);
		// 単価再定義処理を行う
		SalesPrice8UpdaterChouman batch = new SalesPrice8UpdaterChouman(UserInfo.getUserId());
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		// 商品金額確認を行う
		List<AccountMaster__c> newProds = [select Id, Field5__c from AccountMaster__c where id in :equalPriceMap.keySet() limit 100];
		System.assertEquals(newProds.size(), 4, newProds);
		for (AccountMaster__c acc : newProds) {
			System.assertEquals(acc.Field5__c, equalPriceMap.get(acc.Id));
		}	
	} 
*/
}