trigger QuotaItemCommTrigger on QuotaItem__c (before insert, before update, after insert, after update) {
    // before insert
    if(Trigger.isInsert && Trigger.isBefore){
		(new QuotaItemTriggerProcess()).calSpecialTaxProc(trigger.new,trigger.old,CommConst.TriggerMethod.IsInsert);
    }
    // before insert
    else if(Trigger.isUpdate && Trigger.isBefore){
		(new QuotaItemTriggerProcess()).calSpecialTaxProc(trigger.new,trigger.old,CommConst.TriggerMethod.IsUpdate);
    }
}