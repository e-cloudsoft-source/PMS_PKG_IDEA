global with sharing class DataFixBatchForAccountTaxRate implements Database.Batchable<sObject>, Database.Stateful, Schedulable{
	private static final String CONST_BATCH_STATUS = '1';
	public String querySQL = ' Select Id, BatchProcessStatusDiv__c From AccountAcount__c ';
	public String whereSQL = ' Where (SumTax__c = null or SumTax__c = 0) ';
	public String orderBySQL = ' Order by LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c ';
	public String salesDtStr = CommUtils.dateToYYYYMMDD(Date.newInstance(2019,10,1));
	// スケジュールインスタンス関数
	global DataFixBatchForAccountTaxRate () {}
	global DataFixBatchForAccountTaxRate (Date pSalesdate) {
		if(pSalesdate != null) salesDtStr = CommUtils.dateToYYYYMMDD(pSalesdate);
	}
	
	// ***********************************
	// スケジュール処理開始
	// ***********************************
	public void execute(SchedulableContext SC) {
		DataFixBatchForAccountTaxRate batch = new DataFixBatchForAccountTaxRate();
		DataBase.executeBatch(batch, 1);
	}
	// ***********************************
	// バッチ処理開始
	// ***********************************
	public Database.QueryLocator start(Database.BatchableContext BC){
		String Query = querySQL + whereSQL + ' frs__r.Name >=: salesDtStr ' + orderBySQL;
		return Database.getQueryLocator(querySQL);
	}
	// ***********************************
	// バッチロジック処理開始
	// ***********************************
	public void execute(Database.BatchableContext BC, List<AccountAcount__c> accLst){
		if(accLst.isEmpty()) return;
		List<AccountAcount__c> upAccLst = new List<AccountAcount__c>();
		for(AccountAcount__c acc : accLst){
			ApexPages.StandardController contrl = new ApexPages.StandardController(acc);
			// 画面起動
			BillSimpleInputCtrl ctrl = new BillSimpleInputCtrl(contrl);
			ctrl.batchExcuteFlag = true;
			ctrl.initAction();
			// 更新数据
			if(ctrl.oPage.isIns) ctrl.insertData();
			else if(ctrl.oPage.isUpd) ctrl.upsertData();
			acc.BatchProcessStatusDiv__c = CONST_BATCH_STATUS;
			upAccLst.add(acc);
		}
		if(!upAccLst.isEmpty()) update upAccLst;
	}
	// ***********************************
	// バッチ終了処理開始
	// ***********************************
	public void finish(Database.BatchableContext BC){}
}