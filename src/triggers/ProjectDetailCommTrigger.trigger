trigger ProjectDetailCommTrigger on ProjectDetail__c (before update, after update,before insert,after insert) {
    /*
    if(Trigger.isUpdate && Trigger.isAfter) {
    	new ProjectDetailCommTriggerProcess().diffInFromChatter(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
    }else if(Trigger.isInsert && Trigger.isAfter) {
    	new ProjectDetailCommTriggerProcess().diffInFromChatter(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
    }*/
    if(Trigger.isUpdate && Trigger.isBefore) {
    	new ProjectDetailCommTriggerProcess().proejctDetailChg(trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
    }else if(Trigger.isInsert && Trigger.isBefore) {
    	new ProjectDetailCommTriggerProcess().proejctDetailChg(trigger.new, Trigger.old, CommConst.TriggerMethod.isInsert);

    }
}