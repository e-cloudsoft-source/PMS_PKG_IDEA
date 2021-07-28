trigger ProductStockCommTrigger on ProductStock__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    // before insert
    if(Trigger.isInsert && Trigger.isBefore){
    	(new ProductStockTriggerProcess()).autoSetupProductStock(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
    }
    // before update
    else if(Trigger.isUpdate && Trigger.isBefore){
    	(new ProductStockTriggerProcess()).autoSetupProductStock(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
	}
}