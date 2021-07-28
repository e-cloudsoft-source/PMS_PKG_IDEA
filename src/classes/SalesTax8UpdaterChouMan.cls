/**
* 消費税増税処理対応バッチ
* 2014/04/01の消費税率は８％に更新を行う
* 2014/02/05
* 2019/08/12消費税は8%から10%に変更対応
**/
public class SalesTax8UpdaterChouMan implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

	public final String Query;					// 検索SOQL
	
	// 増税開始の日付を定義する
	// 2019/08/12消費税は8%から10%に変更対応 WSQ BEGIN
	//private static final Date CONST_TAXRATE_CHGDATE = Date.newInstance(2014,4,1); 
	//private static final String CONST_BATCH_STATUS = '1';	// 2014/04/01 ５％ー＞８％へ増税処理済みフラグ
	//private static final Decimal CONST_OLD_TAXRATE = 5;
	//private static final Decimal CONST_NEW_TAXRATE = 8;
	private static final Date CONST_TAXRATE_RECDATE = Date.newInstance(2019,3,31);
	private static final Date CONST_TAXRATE_CHGDATE = Date.newInstance(2019,10,1);
	private static final String CONST_BATCH_STATUS = '2';	// 2014/04/01 ５％ー＞８％へ増税処理済みフラグ
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
	public SalesTax8UpdaterChouMan () {}
	// バッチ起動インスタンス関数
	public SalesTax8UpdaterChouMan (Id userId) {
		//Query = ' Select Id, (Select Id, Name, TaxRate__c, ParentBookingItemRef__c, BatchProcessStatusDiv__c From BookingEstimateItemFgKu__r where BatchProcessStatusDiv__c != :CONST_BATCH_STATUS And TaxRate__c > 0) From Lead__c Where DAY_ONLY(convertTimezone(EntryTime__c)) >= :CONST_TAXRATE_CHGDATE ';
		// 2019/08/12 消費税は8%から10%に変更対応 WGCH BEGIN
		// Query = ' Select Id, Name, TaxRate__c, UnitPrice__c, SpTotal__c, SpecialTax__c, ServiceRate__c, Amount__c, ParentBookingItemRef__c, BatchProcessStatusDiv__c from BookingEstimateItem__c where BatchProcessStatusDiv__c != :CONST_BATCH_STATUS And TaxRate__c > 0 And DAY_ONLY(convertTimezone(refBooking__r.EntryTime__c)) >= :CONST_TAXRATE_CHGDATE ';
		// 予約受付日「ReservedDate__c」> 2019.3.31
		//Query = ' Select Id, Name, TaxRate__c, UnitPrice__c, SpTotal__c, SpecialTax__c, ServiceRate__c, Amount__c, ParentBookingItemRef__c, BatchProcessStatusDiv__c, refAccountMaster__c, refBooking__c, UnitPriceDefKbCal__c from BookingEstimateItem__c where BatchProcessStatusDiv__c != :CONST_BATCH_STATUS And TaxRate__c > 0 And DAY_ONLY(convertTimezone(refBooking__r.EntryTime__c)) >= :CONST_TAXRATE_CHGDATE And DAY_ONLY(convertTimezone(refBooking__r.ReservedDate__c)) >: CONST_TAXRATE_RECDATE ';
		// 更新対象予約データを取得する
		// 予約受付日は2019/04/01以後　かつ　到着日は2019/10/10以後の予約データを取得する
		Query = ' select id from lead__c where DAY_ONLY(convertTimezone(EntryTime__c)) >= :CONST_TAXRATE_CHGDATE And DAY_ONLY(ReservedDate__c) >: CONST_TAXRATE_RECDATE';
		// 2019/08/12 消費税は8%から10%に変更対応 WGCH END
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
      SalesTax8UpdaterChouMan batch = new SalesTax8UpdaterChouMan(cron.CreatedById);
      DataBase.executeBatch(batch,50);
   }
	// ***********************************
	// バッチ処理開始
	// ***********************************
	public Database.QueryLocator start(Database.BatchableContext BC){
    	return Database.getQueryLocator(Query);
	}

	/**
	* 情報集計
	**/
	public void execute(Database.BatchableContext BC, List<Lead__c> leads){
		// 2018/03/07 Security Check BEGIN
		List<String> chkFields = new List<String>{'TaxRate__c','SpTotal__c','BatchProcessStatusDiv__c'};
		Map<String,Schema.SObjectField> m = Schema.SObjectType.BookingEstimateItem__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(chkFields, m)) {
			return;
		}
		// 2018/03/07 Security Check END	
		// 2019/08/12 消費税は8%から10%に変更対応 WGCH BEGIN
		// #合計金額　＝　単価（税込）　＊　数量　＋　(単価（税込）　＊　数量) * サビース料金(%)　＋ 特別税　
    	// CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo();
    	set<id> leadIds = new set<id>();
    	for(Lead__c item : leads)  leadIds.add(item.Id);
    	String estQuery = ' Select Id, Name, TaxRate__c, UnitPrice__c, SpTotal__c, SpecialTax__c, ServiceRate__c, Amount__c, ParentBookingItemRef__c, BatchProcessStatusDiv__c, refAccountMaster__c, refBooking__c, UnitPriceDefKbCal__c from BookingEstimateItem__c where BatchProcessStatusDiv__c != :CONST_BATCH_STATUS And TaxRate__c > 0 and refBooking__c in :leadIds ';
		// 2019/08/12 消費税は8%から10%に変更対応 WGCH BEGIN
		CommLogicProcess.TaxIncMstInfo taxIncMstItem = CommLogicProcess.getTaxIncMstInfo();
		// 自動増税商品が存在場合、該当商品が存在の明細を更新対象外
		Set<Id> noTargetLeadIdSet = new Set<Id>();
		if(!CommUtils.isBlank(taxIncMstItem.taxIncMstId)) {
			Id upd2rateId = taxIncMstItem.taxIncMstId;
			List<BookingEstimateItem__c> ests = [Select refBooking__c from BookingEstimateItem__c where  refAccountMaster__c = :upd2rateId];
			for (BookingEstimateItem__c est : ests) noTargetLeadIdSet.add(est.refBooking__c);
		}
		if (!noTargetLeadIdSet.isEmpty()) {
			estQuery += ' And refBooking__c not in :noTargetLeadIdSet ';
		}
    	List<BookingEstimateItem__c> scope = Database.query(estQuery);
    	// 2019/08/12 消費税は8%から10%に変更対応 WGCH END
    	
		List<BookingEstimateItem__c> updLst = new List<BookingEstimateItem__c>();

		// 预约对应的見積明細情報内含有增税商品的LeadId情報Set
		//Set<String> hasTaxIncMstLdIdSet = new Set<String>();
		// 预约对应的見積明細情報Map
		Map<String, List<BookingEstimateItem__c>> ldToBookEstMap = new Map<String, List<BookingEstimateItem__c>>();
		for (BookingEstimateItem__c subItem : scope) {
			// 预约Id
			String leadId = CommUtils.nullToBlank(subItem.refBooking__c);
			// 根据预约Id集计
			if(!ldToBookEstMap.containsKey(leadId)) ldToBookEstMap.put(leadId, new List<BookingEstimateItem__c>());
			ldToBookEstMap.get(leadId).add(subItem);
			// 存在增税商品的LeadId集计
System.debug(Logginglevel.info,'leadId='+leadId);
			//if(!CommUtils.isBlank(taxIncMstItem.taxIncMstId) && ( CommUtils.nullToBlank(taxIncMstItem.taxIncMstId) == CommUtils.nullToBlank(subItem.refAccountMaster__c) )) hasTaxIncMstLdIdSet.add(leadId);
		}
		// 对象外预约处理
		//for(String leadId : hasTaxIncMstLdIdSet){
		//	ldToBookEstMap.remove(leadId);
		//}
		// 最终处理对象集合Lst
		List<BookingEstimateItem__c> nwUpdLst = new List<BookingEstimateItem__c>();
		for(List<BookingEstimateItem__c> bookEstLst : ldToBookEstMap.values()){
			nwUpdLst.addAll(bookEstLst);
		}
		// 最终处理对象集合置换
		scope = nwUpdLst;
System.debug(Logginglevel.info,'scope='+scope);
		// 2019/08/12 消費税は8%から10%に変更対応 WGCH END
		// 更新対象予約見積明細情報を取得、更新内容を設定する
		for (BookingEstimateItem__c subItem : scope) {
			subItem.TaxRate__c = CONST_NEW_TAXRATE;
			subItem.BatchProcessStatusDiv__c = CONST_BATCH_STATUS;
			// 2019/08/12 消費税は8%から10%に変更対応 WGCH BEGIN
			CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(subItem.UnitPriceDefKbCal__c));
			// 2019/08/12 消費税は8%から10%に変更対応 WGCH END
			// 合計金額を計算する
			priceInfo.process(CommUtils.nullToZero(subItem.UnitPrice__c), 
								CommUtils.nullToZero(subItem.Amount__c), 
								subItem.TaxRate__c, 
								subItem.ServiceRate__c);
			// 合計金額＝サビース料込＋特別税
			subItem.SpTotal__c = priceInfo.priceIncTax + CommUtils.nullToZero(subItem.SpecialTax__c);
			updLst.add(subItem);
		}
System.debug(Logginglevel.info,'updLst='+updLst);
		if (!updLst.isEmpty()) {
			//DataFixManagerUtils.stopTranTriggger();
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
			//DataFixManagerUtils.begTranTriggger();
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
		
		// 未更新件数を統計する
		//AggregateResult rsAvg = [Select count(id) cnt from BookingEstimateItem__c where TaxRate__c != :CONST_NEW_TAXRATE And TaxRate__c > 0 And DAY_ONLY(convertTimezone(refBooking__r.EntryTime__c)) >= :CONST_TAXRATE_CHGDATE];
		//Integer noUpdateRsNum = Integer.valueOf(rsAvg.get('cnt'));
		
		// メール情報を設定する
		String mailBodyStr = '処理結果詳細';
		mailBodyStr += '\n更新成功件数：' + IsOKCounts + '(件)';
		mailBodyStr += '\n更新失敗件数：' + IsNgCounts + '(件)';
		//mailBodyStr += '\n未更新対象件数：' + (noUpdateRsNum - IsNgCounts) + '(件)';
		//if (noUpdateRsNum != IsNgCounts ) {
		//	mailBodyStr += '\n未更新対象データが存在するため、データを確認の上て、バッチを再実施してください。';
		//}
		mailBodyStr += errorMessage;
		
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = new String[]{mailAdds};
		mail.setToAddresses(toAddresses);
		mail.setSubject('[SalesTax8UpdaterChouMan] バッチ処理結果の通知');
		mail.setPlainTextBody(mailBodyStr);
		// テストクラスの場合、実施しない
		if(!Test.isRunningTest())
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	}
/**
*2015-11-18 
*テストクラスSalesTax8UpdaterChouManTestに移行する
	@isTest(SeeAllData=false)
	static void testCase1() {
		CommDefine__c comDef = TestCommon.createCommDefine();
		comDef.UnitPriceDefKb__c = 2;
		update comDef; 
		// ２０１４・０３・３０開始４連泊予約情報を設定する
		Date startDt = Date.newInstance(2014,3,30);
		Date changeDate = Date.newInstance(2014,4,1);
    	// 予約情報を作成する(4連泊予約情報を作成する)
    	List<Lead__c> leadInfos = TestCommon.createLead(startDt, 1, 4);
		// 見積もり明細情報を更新を行う（消費税マスタは５％のまま、更新する場合、2014/04/01以後の見積もり明細の消費税率は全部８％に変更されるの確認
		List<BookingEstimateItem__c> confirms = [select Id, TaxRate__c from BookingEstimateItem__c where TaxRate__c > 0];
		Integer oneDateDetails = confirms.size() / 4;
		Test.startTest();
		SalesTax8UpdaterChouMan m = new SalesTax8UpdaterChouMan();
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
		
		SalesTax8UpdaterChouMan batch = new SalesTax8UpdaterChouMan(UserInfo.getUserId());
		ID batchprocessid = Database.executeBatch(batch);
		Test.stopTest();
		// 処理結果確認を行う
		List<BookingEstimateItem__c> items = [select Id, TaxRate__c from BookingEstimateItem__c where DAY_ONLY(convertTimezone(refBooking__r.EntryTime__c)) >= :changeDate];
		// 全部明細件数を計算する
		System.assertEquals(items.size(), oneDateDetails * 2);
		for (BookingEstimateItem__c item : items) {
			system.assertEquals(item.TaxRate__c, 8, item);
		} 
	}
*/
}