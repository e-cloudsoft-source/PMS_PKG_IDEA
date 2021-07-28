trigger ProductOutStockCommTrigger on ProductOutStock__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    // 個別実施制限機能追加する
    if (DataFixManagerUtils.tranTriggerIsStop()) return;
    // after insert
    if(Trigger.isInsert && Trigger.isAfter){
    	ProductOutStockTriggerProcess outStock = new ProductOutStockTriggerProcess();
    	outStock.setStockInfo(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
    }
}