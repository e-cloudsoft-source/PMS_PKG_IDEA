/*********************************************
* 勤務休憩管理の関連トリガー処理を行う
* 1: 休憩時刻の設定
* 2: 休憩時間の計算
* 2015/03/25 15分単位、勤怠時間計算ロジック対応
**/
public with sharing class RestTimeManagementTriggerProcess {
	public void autoSetupRestTimeManagement(RestTimeManagement__c[] newList, RestTimeManagement__c[] oldList, CommConst.TriggerMethod action){
		//システム管理者には制限がなく全部修正可能
		Profile profileItem = [select Id ,Name from Profile where Id = :userInfo.getProfileId()];
		for (Integer i = 0; i < newList.size(); i++) {
			RestTimeManagement__c nw = newList[i];
			RestTimeManagement__c od = oldList[i];
			String oldStatus = '';
            // 2015/03/25 15分単位 BEGIN
            //List<TimeManagement__c> timeManageList = [select Id,Status__c,WorkerRef__c,FromTMUpdatePage__c from TimeManagement__c where Id = :nw.WorkTimeInfo__c];
            List<TimeManagement__c> timeManageList = [select Id,Status__c,WorkerRef__c,FromTMUpdatePage__c,WorkerRef__r.RestTimeUnit__c,WorkerRef__r.RestCalMethodType__c,WorkerRef__r.OutRestTimeUnit__c,WorkerRef__r.OutRestCalMethodType__c,WorkerRef__r.ShopCode__c, WorkBeginTime__c from TimeManagement__c where Id = :nw.WorkTimeInfo__c];
            // 2015/03/25 15分単位 END
			if(isChanged(nw,od)){
				if(!nw.FromTMUpdatePage__c){
					if(profileItem.Name != System.Label.MSG_1016){
						if(timeManageList[0].Status__c == System.Label.MSG_1015 || timeManageList[0].Status__c == System.Label.MSG_1017 || timeManageList[0].Status__c == System.Label.MSG_1018){
							nw.addError(System.Label.MSG_1020);
						}
						//承認者が自分の場合、エラーを出します
						if(timeManageList[0].Status__c == System.Label.MSG_1019 && isMyselfApprovaled(timeManageList[0].Id) ){
							nw.addError(System.Label.MSG_1021);
						}
					}
				}
			}else{
				continue;
			}
			//外出時刻
			if (nw.OutingTime__c != null && nw.OutingTimeHM__c != null && (nw.OutingTime__c != od.OutingTime__c || nw.OutingTimeHM__c != od.OutingTimeHM__c)){
				nw.OutingTime__c = datetime.valueOf(nw.OutingTime__c.format('yyyy-MM-dd') + ' ' + nw.OutingTimeHM__c + ':00');
			}
			//入室時刻
			if (nw.EnteringTime__c != null && nw.EnteringTimeHM__c != null && (nw.EnteringTime__c != od.EnteringTime__c || nw.EnteringTimeHM__c != od.EnteringTimeHM__c)){
				nw.EnteringTime__c = datetime.valueOf(nw.EnteringTime__c.format('yyyy-MM-dd') + ' ' + nw.EnteringTimeHM__c + ':00');
			}
			//休憩時間を計算
			if(nw.OutingTime__c != null && nw.EnteringTime__c != null){
                // 2015/03/25 15分単位 BEGIN
                /*
				List<User> userList = [select Id,
				                          RestTimeUnit__c,
            							  RestCalMethodType__c,
            							  OutRestTimeUnit__c,
            							  OutRestCalMethodType__c 
            						from User where Id = :timeManageList[0].WorkerRef__c];
				Datetime EnteringTime = datetime.valueOf(nw.EnteringTime__c.format('yyyy-MM-dd') + ' ' + nw.EnteringTime__c.hour() + ':' + TimeManagementTriggerProcess.timeFormat(nw.EnteringTime__c.minute(),userList[0].RestCalMethodType__c,userList[0].RestTimeUnit__c) + ':00');
				Datetime OutingTime = datetime.valueOf(nw.OutingTime__c.format('yyyy-MM-dd') + ' ' + nw.OutingTime__c.hour() + ':' + TimeManagementTriggerProcess.timeFormat(nw.OutingTime__c.minute(),userList[0].OutRestCalMethodType__c,userList[0].OutRestTimeUnit__c) + ':00');
				nw.RestMinuteSum__c = Decimal.valueOf(Math.abs(EnteringTime.getTime() - OutingTime.getTime())).divide((1000*60), 0, System.RoundingMode.DOWN);
                */
                User worker = timeManageList[0].WorkerRef__r;
                Integer decRestTime = (Decimal.valueOf(Math.abs(nw.EnteringTime__c.getTime() - nw.OutingTime__c.getTime())).divide((1000*60), 0, System.RoundingMode.DOWN)).intValue();
                // 休憩時間は単位で計算して、残値が存在する場合、１単位の時間を加算する
                nw.RestMinuteSum__c = TimeManagementTriggerProcess.timeFormat(decRestTime, System.Label.MSG_1023, timeManageList[0].WorkerRef__r.RestTimeUnit__c);
                // 店舗コード情報を取得する
                String shopCd = CommUtils.nullToBlank(timeManageList[0].WorkerRef__r.shopCode__c);
                // 勤怠時間数（分単位)
                WorkTimeDefine__c wkTimeDef = WorkTimeDefineUtil.getWkDefineByShopCode(shopCd);
                nw.LateNightRestTime__c = 
                                TimeManagementTriggerProcess.lateNightRestTimeCal(
                                    timeManageList[0].WorkBeginTime__c == null ? null : timeManageList[0].WorkBeginTime__c.date(),  // 勤務開始日
                                    wkTimeDef.LateNightStartTime__c,
                                    wkTimeDef.LateNightEndTime__c,
                                    nw.OutingTime__c,
                                    nw.EnteringTime__c,
                                    worker.RestTimeUnit__c
                                );
                // 2015/03/25 15分単位 END
			}
		}
	}
	//時間単位で計算 
	/*
	public Integer timeFormat(Integer iTimeMinute,String sCalMethodType,String sTimeUnit){
		Integer retVal = 0;
		if(iTimeMinute <= 0) return 0;
		//Integer iMod60 = Math.mod(iTimeSum, 60);
		Integer iMod60 = iTimeMinute;
		if(String.isEmpty(sTimeUnit)) return iTimeMinute;
		if(sCalMethodType == System.Label.MSG_1022){
			retVal = iMod60 - Math.mod(iMod60,Integer.valueOf(sTimeUnit.replace('分','')));
		}else if(sCalMethodType == System.Label.MSG_1023){
			if(sTimeUnit == '1分'){
				retVal = iMod60;
			}else{
				if(Math.mod(iMod60,Integer.valueOf(sTimeUnit.replace('分',''))) == 0){
					retVal = iMod60;
				}else{
					retVal = iMod60 - Math.mod(iMod60,Integer.valueOf(sTimeUnit.replace('分',''))) + Integer.valueOf(sTimeUnit.replace('分',''));
				}
			}
		}else if(sCalMethodType == System.Label.MSG_1024){
			Integer iMod1 = Math.mod(iMod60,Integer.valueOf(sTimeUnit.replace('分','')));
			Integer iMod2 = Integer.valueOf(sTimeUnit.replace('分',''))/2;
			Decimal iDecimal1 = Decimal.valueOf(sTimeUnit.replace('分',''));
			Decimal iDecimal2 = iDecimal1.divide(2, 2);
			if(iMod1 == 0){
				retVal = iMod60;
			}else{
				if(iMod1 >= iDecimal2){
					retVal = iMod60 - Math.mod(iMod60,Integer.valueOf(sTimeUnit.replace('分',''))) + Integer.valueOf(sTimeUnit.replace('分',''));
				}else{
					retVal = iMod60 - Math.mod(iMod60,Integer.valueOf(sTimeUnit.replace('分','')));
				}
			}
		}else{
			retVal = iMod60;
		}
		//retVal = iTimeSum - iMod60 + retVal;
		return retVal; 
	}
	*/
	//時間を修正したかどうかの判断
	private Boolean isChanged(RestTimeManagement__c nwItem,RestTimeManagement__c odItem){
		String strCheckCol = 'OutingTime__c,OutingTimeHM__c,EnteringTime__c,EnteringTimeHM__c,RestMinuteSum__c';
		for(String strKey : strCheckCol.split(',')){
			if(nwItem.get(strKey) != odItem.get(strKey)) return true;
		}
		return false;
	}
	//承認者には自分がかどうかの判断
	private Boolean isMyselfApprovaled(Id recordId){
		List<ProcessInstanceStep> workStepList = [SELECT Id ,
													 StepStatus,
													 ActorId,
													 CreatedDate
                                              FROM ProcessInstanceStep
                                              WHERE ProcessInstance.TargetObjectID =:recordId
                                              AND ProcessInstance.Status = 'Approved'
                                              AND (StepStatus = 'Started' OR StepStatus = 'Approved')];
    	if(!workStepList.isEmpty()){
    		DateTime startTime = null;
    		DateTime approvaledTime = null;
    		Id startUserId = null;
    		Id approvaledUserId = null;
    		//承認者が自分であるかどうかを判断する
    		for(ProcessInstanceStep item : workStepList){
    			if(item.StepStatus == 'Started'){
    				if(startTime == null || startTime <= item.CreatedDate){
    					startTime = item.CreatedDate;
    					startUserId = item.ActorId;
    				}
    			}
    			if(item.StepStatus == 'Approved'){
    				if(approvaledTime == null || approvaledTime <= item.CreatedDate){
    					approvaledTime = item.CreatedDate;
    					approvaledUserId = item.ActorId;
    				}
    			}
    		}
    		//自分が承認した場合、エラーを出します
    		if(approvaledUserId != null && startUserId != null && startUserId == approvaledUserId){
    			return true;
    		}
    	}
    	return false;
	}
}