// 2020/10/31 8701 bug fixed by zy BEGIN
trigger EventCommTrigger on Event (after delete, after insert, after update, before update,before insert) {
// 2020/10/31 8701 bug fixed by zy END
    // after insert
    if(Trigger.isInsert && Trigger.isAfter){
    	EventTriggerProcess handel = new EventTriggerProcess();
    	handel.updRelationAcccounts(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
        // 2019/04/15 改善要望：活動から予約の作成 by zy BEGIN
        handel.insertRelationRoom(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
        // 2019/04/15 改善要望：活動から予約の作成 by zy END
    } 
    // 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy BEGIN
    else if(Trigger.isInsert && Trigger.isBefore){
        EventTriggerProcess handel = new EventTriggerProcess();
        // 2019/04/15 改善要望：活動から予約の作成 by zy BEGIN
        handel.updateChildEvent(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
        // 2019/04/15 改善要望：活動から予約の作成 by zy END
    }
    // 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy END
    // after update
    else if(Trigger.isUpdate && Trigger.isAfter){
    	EventTriggerProcess handel = new EventTriggerProcess();
    	handel.updRelationAcccounts(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
        // 2019/04/15 改善要望：活動から予約の作成 by zy BEGIN
        handel.updRelationRoom(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
        // 2019/04/15 改善要望：活動から予約の作成 by zy END
    }
     // before update
    else if(Trigger.isUpdate && Trigger.isBefore){
        EventTriggerProcess handel = new EventTriggerProcess();
        handel.updAutoUpdDatetime(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
	// 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy BEGIN
        handel.updateChildEvent(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
        // 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy END
    }
    // after delete
    else if(Trigger.isDelete && Trigger.isAfter){
    	EventTriggerProcess handel = new EventTriggerProcess();
    	handel.updRelationAcccounts(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsDelete);
        // 2019/04/15 改善要望：活動から予約の作成 by zy BEGIN
        handel.delRelationLead(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
        // 2019/04/15 改善要望：活動から予約の作成 by zy END
    }
}