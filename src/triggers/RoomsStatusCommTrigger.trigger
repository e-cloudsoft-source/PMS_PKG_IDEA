/**************************
* 部屋状態管理トリガー
**************************/
trigger RoomsStatusCommTrigger on RoomsStatus__c (after delete, after insert, after undelete, after update, before insert, before update) {
	// 2019/10/09 部屋状態管理インデックス機能対応 WSQ BEGIN
	if (DataFixManagerUtils.tranTriggerIsStop()) return;
	// 2019/10/09 部屋状態管理インデックス機能対応 WSQ END
    // 2018/03/22 故障部屋時刻機能追加　by　zy BEGIN
    if(Trigger.isInsert && Trigger.isBefore){
    	(new RoomsStatusTriggerProcess()).roomDateTimeCheck(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
    	(new RoomsStatusTriggerProcess()).roomDatetimeLeadChk(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
    }
    // before update
    else if(Trigger.isUpdate && Trigger.isBefore){
    	(new RoomsStatusTriggerProcess()).roomDateTimeCheck(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
    	(new RoomsStatusTriggerProcess()).roomDatetimeLeadChk(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
    }
    else if(Trigger.isUnDelete && Trigger.isBefore){
    	(new RoomsStatusTriggerProcess()).roomDateTimeCheck(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUnDelete);
    	(new RoomsStatusTriggerProcess()).roomDatetimeLeadChk(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUnDelete);
    }
    // 2018/03/22 故障部屋時刻機能追加　by　zy END
    // after insert
    if(Trigger.isInsert && Trigger.isAfter){
    	(new RoomsStatusTriggerProcess()).stockChangeSyncToDb(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
    }
    // after update
    else if(Trigger.isUpdate && Trigger.isAfter){
    	(new RoomsStatusTriggerProcess()).stockChangeSyncToDb(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
    }
     // after delete
    else if(Trigger.isDelete && Trigger.isAfter){
    	(new RoomsStatusTriggerProcess()).stockChangeSyncToDb(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsDelete);
    }
    // after undelete
    else if(Trigger.isUnDelete && Trigger.isAfter){
    	(new RoomsStatusTriggerProcess()).stockChangeSyncToDb(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUnDelete);
    }
}