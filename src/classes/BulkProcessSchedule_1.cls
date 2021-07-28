/*
* バッチ処理自動起動スケジュール
* バッチ起動日付により、処理日の予約データは自動チェックインを行う
* バッチ日の売上処理自動会計を行う
*/
public with sharing class BulkProcessSchedule_1 implements Schedulable {
   public void execute(SchedulableContext SC) {
      
      BulkProcessBatch batch = new BulkProcessBatch();
      // システム日と処理日の差異日数
      Integer days = CommDefine__c.getOrgDefaults().Schedule1DeviationDays__c == null ? 0 : CommDefine__c.getOrgDefaults().Schedule1DeviationDays__c.intValue();
      String strTodate = (Date.today().addDays(days)).format();
      batch.scheduleStart(strTodate);
   }

}