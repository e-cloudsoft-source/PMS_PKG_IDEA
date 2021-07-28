trigger BookingGuestCommTrigger on BookingGuest__c (after delete, after insert, after undelete,
after update, before delete, before insert, before update) {
    // before insert
    if(Trigger.isInsert && Trigger.isBefore){}
    // after insert
    else if(Trigger.isInsert && Trigger.isAfter){
        //BookingGuestCommTriggerProcess handel = new BookingGuestCommTriggerProcess();
        //handel.assignRoomToLead(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
    }
    // before update
    else if(Trigger.isUpdate && Trigger.isBefore){}
    // after update
    else if(Trigger.isUpdate && Trigger.isAfter){
        //BookingGuestCommTriggerProcess handel = new BookingGuestCommTriggerProcess();
        //handel.assignRoomToLead(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
    }
    // before delete
    //else if(Trigger.isDelete && Trigger.isBefore){}
    // after delete
    //else if(Trigger.isDelete && Trigger.isAfter){}
    // after undelete
    //else if(Trigger.isUnDelete){}
}