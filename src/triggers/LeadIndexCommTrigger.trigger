trigger LeadIndexCommTrigger on LeadIndex__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
    // before insert
    if(Trigger.isInsert && Trigger.isBefore){
    	(new LeadIndexCommTriggerProcess()).autoSetupInfo(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
    }
    // after insert
    //else if(Trigger.isInsert && Trigger.isAfter){
        //LeadIndexCommTriggerProcess handel = new LeadIndexCommTriggerProcess();
        //handel.expendLeadData(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
    //}
    // before update
    else if(Trigger.isUpdate && Trigger.isBefore){
    	(new LeadIndexCommTriggerProcess()).autoSetupInfo(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
    }
    // after update
    else if(Trigger.isUpdate && Trigger.isAfter){
        LeadIndexCommTriggerProcess handel = new LeadIndexCommTriggerProcess();
        handel.expendLeadData(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
    }
    // before delete
    else if(Trigger.isDelete && Trigger.isBefore){
    	(new LeadIndexCommTriggerProcess()).autoSetupInfo(trigger.new, Trigger.old, CommConst.TriggerMethod.isDelete);
    }
    // after delete
    //else if(Trigger.isDelete && Trigger.isAfter){
    //    LeadIndexCommTriggerProcess handel = new LeadIndexCommTriggerProcess();
    //    handel.expendLeadData(trigger.new, Trigger.old, CommConst.TriggerMethod.IsDelete);
    //}
    // after undelete
    //else if(Trigger.isUnDelete){}
}