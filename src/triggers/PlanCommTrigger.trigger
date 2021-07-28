trigger PlanCommTrigger on Plan__c (after delete, after insert, after undelete,
after update, before delete, before insert, before update) {

    if(Trigger.isInsert && Trigger.isBefore){
    	// プランNO自動採番処理を行う
    	(new PlanTriggerProcess()).setPlanAutoNumber(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
    	// プラン名がNULLの場合、自動設定機能を含め
    	(new PlanTriggerProcess()).autoSetupPlanInfo(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
	    // 重複チェックを行う
	    // 2017/06/26 PlanNo重複問題対応 BEGIN
	    List<Plan__c> dupChkPlans = new list<Plan__c>();
	    for (Plan__c plan : trigger.new) {
	        if (!CommUtils.isBlank(plan.PlanNo__c)) dupChkPlans.add(plan);
	    }
    	//(new CommLogicProcess()).hasCandidateDuplicates(trigger.new, 
    	(new CommLogicProcess()).hasCandidateDuplicates(dupChkPlans, 
    	// 2017/06/26 PlanNo重複問題対応 END
    	   Plan__c.PlanNo__c.getDescribe().getName(),
    	   Plan__c.sObjectType.getDescribe().getName(),
    	   //値が重複しているため、登録できません。
    	   Plan__c.PlanNo__c.getDescribe().getLabel() + ' '+ Label.MSG_009_0043);
    }
    else if(Trigger.isUpdate && Trigger.isBefore) {
        // 2017/06/26 PlanNo重複問題対応 BEGIN
        // プランNO自動採番処理を行う
        (new PlanTriggerProcess()).setPlanAutoNumber(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
        // 2017/06/26 PlanNo重複問題対応 END
	    // 重複チェックを行う
    	(new CommLogicProcess()).hasCandidateDuplicates(trigger.new, 
    	   Plan__c.PlanNo__c.getDescribe().getName(),
    	   Plan__c.sObjectType.getDescribe().getName(),
    	   //値が重複しているため、登録できません。
    	   Plan__c.PlanNo__c.getDescribe().getLabel() + ' '+ Label.MSG_009_0043);	
    }
    else if(Trigger.isDelete && Trigger.isBefore){
    	(new PlanTriggerProcess()).autoDeletePlanDetail(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsDelete);
    
    }
    // after update
    else if(Trigger.isUpdate && Trigger.isAfter){
    	// プラン名など変更する場合、会計商品（プラン）連動更新を行う
    	// 2016/11/30 下記機能はプラン設定画面から既に対応済みため、下記機能は廃止 BEGIN
    	//(new PlanTriggerProcess()).autoSyncPlanInfoToProductMst(Trigger.new, Trigger.old, CommConst.TriggerMethod.IsUpdate);
    	// 2016/11/30 下記機能はプラン設定画面から既に対応済みため、下記機能は廃止 END
    }
}