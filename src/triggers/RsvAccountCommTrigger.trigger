trigger RsvAccountCommTrigger on RsvAccount__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
    // 2020/03/31 会計ロック機能 by zy BEGIN
    if((Trigger.isInsert || Trigger.isUpdate || Trigger.isDelete) && Trigger.isBefore){
        if (CommLogicProcess.lockCheck(trigger.new, Trigger.old)) return;
    }
    // 2020/03/31 会計ロック機能 by zy END
    // before insert
    if(Trigger.isInsert && Trigger.isBefore){
        // 2021/03/31 .売上重複問題の対応 by zy BEGIN
        for (RsvAccount__c rv : Trigger.new) {
            if (rv.Name.isNumeric()) {
                rv.SalesDateDupCheck__c  = CommUtils.nullToIntZero(rv.Name);
            }
        }
	    // 重複チェックを行う
    	// (new CommLogicProcess()).hasCandidateDuplicates(trigger.new, 
    	//    RsvAccount__c.name.getDescribe().getName(),
    	//    RsvAccount__c.sObjectType.getDescribe().getName());
        // 2021/03/31 .売上重複問題の対応 by zy END
    }
    // after insert
//    else if(Trigger.isInsert && Trigger.isAfter){}
    // before update
    else if(Trigger.isUpdate && Trigger.isBefore){
        // 2021/03/31 .売上重複問題の対応 by zy BEGIN
        for (RsvAccount__c rv : Trigger.new) {
            if (rv.Name.isNumeric()) {
                rv.SalesDateDupCheck__c  = CommUtils.nullToIntZero(rv.Name);
            }
        }
        // 重複チェックを行う
        // (new CommLogicProcess()).hasCandidateDuplicates(trigger.new,
        //    RsvAccount__c.name.getDescribe().getName(),
        //    RsvAccount__c.sObjectType.getDescribe().getName());
        // 2021/03/31 .売上重複問題の対応 by zy END
	}
//    else if(Trigger.isUpdate && Trigger.isAfter){}
    // before delete
//    else if(Trigger.isDelete && Trigger.isBefore){}
    // after delete
//    else if(Trigger.isDelete && Trigger.isAfter){}
    // after undelete
//    else if(Trigger.isUnDelete){}

}