/*********************************************
* 勤怠管理の関連トリガー処理を行う
* 1: 勤務時刻の設定
* 2: 勤務時間の計算
* 2015/03/25 15分単位、勤怠時間計算ロジック対応
* 2015/07/29 スタッフスケジュールに関連ID自動設定機能を追加
**/
public with sharing class TimeManagementTriggerProcess {
	public void autoSetupTimeManagement(TimeManagement__c[] newList, TimeManagement__c[] oldList, CommConst.TriggerMethod action){
		// 管理勤怠管理変数
		TimeManagement__c tmpOld = new TimeManagement__c();
		//システム管理者には制限がなく全部修正可能
		Profile profileItem = [select Id ,Name from Profile where Id = :userInfo.getProfileId()];
		for (Integer i = 0; i < newList.size(); i++) {
			TimeManagement__c nw = newList[i];
			TimeManagement__c od = oldList == null ? tmpOld : oldList[i];
			if(isChanged(nw,od)){
				if(profileItem.Name != System.Label.MSG_1016){
					if(nw.Status__c == System.Label.MSG_1015 || nw.Status__c == System.Label.MSG_1017 || nw.Status__c == System.Label.MSG_1018){
						nw.addError(System.Label.MSG_1020);
					}
					//承認者が自分の場合、エラーを出します
					if(od.Status__c == '承認済み' && isMyselfApprovaled(nw.Id)){
						nw.addError(System.Label.MSG_1021);
					}
				}
				if(nw.Status__c == System.Label.MSG_1019){
					setChatterMessage(nw);
				}
			}else{
				if(nw.RestMinuteSumAll__c != od.RestMinuteSumAll__c){
					//勤務時間の計算開始
					//Integer iMinuteSum = 0;
					//休憩総分数を再計算
                    // 2015/03/25 15分単位 BEGIN
                    //List<User> userList = getCurrentUserInfo(nw.WorkerRef__c);
                    List<User> userList = new List<User>{UserUtil.getUser(nw.WorkerRef__c)};
                    // 2015/03/25 15分単位 END
					if(!userList.isEmpty()){
						//iMinuteSum = getBeforeThreeTime(nw,userList[0]).intValue() + nw.RestMinuteSumAll__c.intValue();
						//nw.RestMinuteSumAll2__c = restTimeFormat(iMinuteSum,userList[0].RestCalMethodType__c,userList[0].RestTimeUnit__c);
						nw.RestMinuteSumAll2__c = getBeforeThreeTime(nw,userList[0]).intValue() + nw.RestMinuteSumAll__c.intValue();
						if(nw.WorkBeginTime__c != null && nw.WorkEndTime__c != null){
							// 出勤は０分の場合、次の計算単位に加算する昨日対応　(2015/01/07)
							DateTime tmpWorkBeginTime = nw.WorkBeginTime__c.addMinutes(1);
							Datetime workBeginTime = datetime.valueOf(tmpWorkBeginTime.format('yyyy-MM-dd') + ' ' + tmpWorkBeginTime.hour() + ':' + timeFormat(tmpWorkBeginTime.minute(),userList[0].BeginTimeCalMethodType__c,userList[0].BeginTimeUnit__c) + ':00');
							//Datetime workBeginTime = datetime.valueOf(nw.WorkBeginTime__c.format('yyyy-MM-dd') + ' ' + nw.WorkBeginTime__c.hour() + ':' + timeFormat(nw.WorkBeginTime__c.minute(),userList[0].BeginTimeCalMethodType__c,userList[0].BeginTimeUnit__c) + ':00');
							
							Datetime workEndTime = datetime.valueOf(nw.WorkEndTime__c.format('yyyy-MM-dd') + ' ' + nw.WorkEndTime__c.hour() + ':' + timeFormat(nw.WorkEndTime__c.minute(),userList[0].CalMethodType__c,userList[0].TimeUnit__c) + ':00');
                            // 2015/03/25 15分単位 BEGIN
                            if (workEndTime < workBeginTime) workEndTime = workBeginTime;
                            /*
							if(nw.RestMinuteSumAll2__c == 0){
								nw.MinuteSum__c = Decimal.valueOf(Math.abs(workEndTime.getTime() - workBeginTime.getTime())).divide((1000*60), 0, System.RoundingMode.DOWN);
							}else{
								nw.MinuteSum__c = Decimal.valueOf(Math.abs(workEndTime.getTime() - workBeginTime.getTime())).divide((1000*60), 0, System.RoundingMode.DOWN) - nw.RestMinuteSumAll2__c.intValue();
							}
                            */
                            nw.MinuteSum__c = Decimal.valueOf(Math.abs(workEndTime.getTime() - workBeginTime.getTime())).divide((1000*60), 0, System.RoundingMode.DOWN) - CommUtils.nullToZero(nw.RestMinuteSumAll2__c).intValue();
                            // 2015/03/25 15分単位 END
		                    // 2016/11/29  勤怠、作業時間が6時間以上でかつ外出、入室ボタンが押下されていないときは、無条件に休憩時間をマイナス1.0とするように改善対応 BEGIN
		                    Decimal restMinute = CommUtils.nullToZero(nw.RestMinuteSumAll2__c).intValue();
		                    // 2016/11/29 勤怠の時間は６時間は超えると条件変更を行う BEGIN
		                    if (restMinute == 0 && nw.MinuteSum__c > 360) {
		                    // 2016/11/29 勤怠の時間は６時間は超えると条件変更を行う END
		                    	if(userList[0].RestMinuteIsMinusFlg__c != true){
		                    		nw.MinuteSum__c = nw.MinuteSum__c - 60;
		                    	}  
		                    }
		                    // 2015/11/11  勤怠、作業時間が6時間以上でかつ外出、入室ボタンが押下されていないときは、無条件に休憩時間をマイナス1.0とするように改善対応 END
						}
						//Chatterメッセージの投稿
						if(nw.Status__c == System.Label.MSG_1019){
							setChatterMessage(nw);
						}
					}
				}
				continue;
			}
			// 時刻が変更場合、時間に設定します
			//出勤時刻
			if (nw.WorkBeginTime__c != null && nw.WorkBeginTimeHM__c != null && (nw.WorkBeginTime__c != od.WorkBeginTime__c || nw.WorkBeginTimeHM__c != od.WorkBeginTimeHM__c)){
				nw.WorkBeginTime__c = datetime.valueOf(nw.WorkBeginTime__c.format('yyyy-MM-dd') + ' ' + nw.WorkBeginTimeHM__c + ':00');
			}
			//退勤時刻
			if (nw.WorkEndTime__c != null && nw.WorkEndTimeHM__c != null && (nw.WorkEndTime__c != od.WorkEndTime__c || nw.WorkEndTimeHM__c != od.WorkEndTimeHM__c)){
				nw.WorkEndTime__c = datetime.valueOf(nw.WorkEndTime__c.format('yyyy-MM-dd') + ' ' + nw.WorkEndTimeHM__c + ':00');
			}
            //外出時刻
            if (nw.OutingTime__c != null && nw.OutingTimeHM__c != null && (nw.OutingTime__c != od.OutingTime__c || nw.OutingTimeHM__c != od.OutingTimeHM__c)){
                nw.OutingTime__c = datetime.valueOf(nw.OutingTime__c.format('yyyy-MM-dd') + ' ' + nw.OutingTimeHM__c + ':00');
            }
            //入室時刻
            if (nw.EnteringTime__c != null && nw.EnteringTimeHM__c != null && (nw.EnteringTime__c != od.EnteringTime__c || nw.EnteringTimeHM__c != od.EnteringTimeHM__c)){
                nw.EnteringTime__c = datetime.valueOf(nw.EnteringTime__c.format('yyyy-MM-dd') + ' ' + nw.EnteringTimeHM__c + ':00');
            }
            //外出２時刻
            if (nw.OutingTime2__c != null && nw.OutingTime2HM__c != null && (nw.OutingTime2__c != od.OutingTime2__c || nw.OutingTime2HM__c != od.OutingTime2HM__c)){
                nw.OutingTime2__c = datetime.valueOf(nw.OutingTime2__c.format('yyyy-MM-dd') + ' ' + nw.OutingTime2HM__c + ':00');
            }
            //入室２時刻
            if (nw.EnteringTime2__c != null && nw.EnteringTime2HM__c != null && (nw.EnteringTime2__c != od.EnteringTime2__c || nw.EnteringTime2HM__c != od.EnteringTime2HM__c)){
                nw.EnteringTime2__c = datetime.valueOf(nw.EnteringTime2__c.format('yyyy-MM-dd') + ' ' + nw.EnteringTime2HM__c + ':00');
            }
            //外出３時刻
            if (nw.OutingTime3__c != null && nw.OutingTime3HM__c != null && (nw.OutingTime3__c != od.OutingTime3__c || nw.OutingTime3HM__c != od.OutingTime3HM__c)){
                nw.OutingTime3__c = datetime.valueOf(nw.OutingTime3__c.format('yyyy-MM-dd') + ' ' + nw.OutingTime3HM__c + ':00');
            }
            //入室３時刻
            if (nw.EnteringTime3__c != null && nw.EnteringTime3HM__c != null && (nw.EnteringTime3__c != od.EnteringTime3__c || nw.EnteringTime3HM__c != od.EnteringTime3HM__c)){
                nw.EnteringTime3__c = datetime.valueOf(nw.EnteringTime3__c.format('yyyy-MM-dd') + ' ' + nw.EnteringTime3HM__c + ':00');
            }
			//勤務時間の計算開始
			Decimal iRestTime = 0;
			Integer iRestMinuteSum = 0;
			
            //総休憩時間分数を計算
            // 2015/03/25 15分単位 BEGIN
            //List<User> userList = getCurrentUserInfo(nw.WorkerRef__c);
            List<User> userList = new List<User>{UserUtil.getUser(nw.WorkerRef__c)};
            // 2015/03/25 15分単位 END
            if(!userList.isEmpty()){
            	//前３回の休憩時間を計算
	            iRestTime = getBeforeThreeTime(nw,userList[0]);
                // 2015/03/25 15分単位 BEGIN
	            //全部の休憩時間を計算
                nw.RestMinuteSumAll2__c = CommUtils.nullToZero(iRestTime).intValue() + CommUtils.nullToZero(nw.RestMinuteSumAll__c).intValue();
                /*
                //全部の休憩時間を計算
	            if(iRestTime != 0 || nw.RestMinuteSumAll__c != 0){
	            	iRestMinuteSum = iRestTime.intValue() + nw.RestMinuteSumAll__c.intValue();
	            	nw.RestMinuteSumAll2__c = iRestMinuteSum;
					//nw.RestMinuteSumAll2__c = restTimeFormat(iRestMinuteSum,userList[0].RestCalMethodType__c,userList[0].RestTimeUnit__c);
	            }
                */
                // 2015/03/25 15分単位 END
				if(nw.WorkBeginTime__c != null && nw.WorkEndTime__c != null){
					// 出勤は０分の場合、次の計算単位に加算する昨日対応　(2015/01/07)
					DateTime tmpWorkBeginTime = nw.WorkBeginTime__c.addMinutes(1);
					Datetime workBeginTime = datetime.valueOf(tmpWorkBeginTime.format('yyyy-MM-dd') + ' ' + tmpWorkBeginTime.hour() + ':' + timeFormat(tmpWorkBeginTime.minute(),userList[0].BeginTimeCalMethodType__c,userList[0].BeginTimeUnit__c) + ':00');
					//Datetime workBeginTime = datetime.valueOf(nw.WorkBeginTime__c.format('yyyy-MM-dd') + ' ' + nw.WorkBeginTime__c.hour() + ':' + timeFormat(nw.WorkBeginTime__c.minute(),userList[0].BeginTimeCalMethodType__c,userList[0].BeginTimeUnit__c) + ':00');
					Datetime workEndTime = datetime.valueOf(nw.WorkEndTime__c.format('yyyy-MM-dd') + ' ' + nw.WorkEndTime__c.hour() + ':' + timeFormat(nw.WorkEndTime__c.minute(),userList[0].CalMethodType__c,userList[0].TimeUnit__c) + ':00');
                    // 2015/03/25 15分単位 BEGIN
                    if (workEndTime < workBeginTime) workEndTime = workBeginTime;
					/*
					if(iRestMinuteSum == 0){
						nw.MinuteSum__c = Decimal.valueOf(Math.abs(workEndTime.getTime() - workBeginTime.getTime())).divide((1000*60), 0, System.RoundingMode.DOWN);
					}else{
						nw.MinuteSum__c = Decimal.valueOf(Math.abs(workEndTime.getTime() - workBeginTime.getTime())).divide((1000*60), 0, System.RoundingMode.DOWN) - nw.RestMinuteSumAll2__c.intValue();
					}
                    */
                    nw.MinuteSum__c = Decimal.valueOf(Math.abs(workEndTime.getTime() - workBeginTime.getTime())).divide((1000*60), 0, System.RoundingMode.DOWN) - CommUtils.nullToZero(nw.RestMinuteSumAll2__c).intValue();
                    // 2015/03/25 15分単位 END
                    // 2015/11/11  勤怠、作業時間が6時間以上でかつ外出、入室ボタンが押下されていないときは、無条件に休憩時間をマイナス1.0とするように改善対応 BEGIN
                    Decimal restMinute = CommUtils.nullToZero(nw.RestMinuteSumAll2__c).intValue();
                    // 2016/11/29 勤怠の時間は６時間は超えると条件変更を行う
                    //if(restMinute == 0 && nw.MinuteSum__c >= 360){
                    if (restMinute == 0 && nw.MinuteSum__c > 360) {
                    // 2015/12/17 勤怠計算ロジックに、６時以上すると、マイナス１時間を計算するの再対応 BEGIN
                    	if(userList[0].RestMinuteIsMinusFlg__c != true){
                    		nw.MinuteSum__c = nw.MinuteSum__c - 60;
                    	}  
                	// 2015/12/17 勤怠計算ロジックに、６時以上すると、マイナス１時間を計算するの再対応 END                 	
                    }
                    // 2015/11/11  勤怠、作業時間が6時間以上でかつ外出、入室ボタンが押下されていないときは、無条件に休憩時間をマイナス1.0とするように改善対応 END
				}
            }
    	}
	}
	private List<User> getCurrentUserInfo(Id userId){
		List<User> userList = [select Id,
            							  RestTimeUnit__c,
            							  RestCalMethodType__c,
            							  OutRestTimeUnit__c,
            							  OutRestCalMethodType__c,
            							  TimeUnit__c,
            							  CalMethodType__c,
            							  BeginTimeUnit__c,
            							  BeginTimeCalMethodType__c 
            						from User where Id = :userId];
        return userList;
	}
	//時間を修正したかどうかの判断
	private Boolean isChanged(TimeManagement__c nwItem,TimeManagement__c odItem){
		String strCheckCol = 'WorkBeginTime__c,WorkEndTime__c,WorkBeginTimeHM__c,WorkEndTimeHM__c,OutingTime__c,OutingTimeHM__c,EnteringTime__c,EnteringTimeHM__c,OutingTime2__c,OutingTime2HM__c,EnteringTime2__c,EnteringTime2HM__c,OutingTime3__c,OutingTime3HM__c,EnteringTime3__c,EnteringTime3HM__c';
		for(String strKey : strCheckCol.split(',')){
			if(nwItem.get(strKey) != odItem.get(strKey)) return true;
		}
		return false;
	}
	//時間単位で計算
	/*
	private Integer restTimeFormat(Integer iTimeSum,String sCalMethodType,String sTimeUnit){
		Integer retVal = 0;
		if(iTimeSum <= 0) return 0;
		Integer iMod60 = Math.mod(iTimeSum, 60);
		if(iMod60 == 0 || String.isEmpty(sTimeUnit)) return iTimeSum;
		if(sCalMethodType == System.Label.MSG_1022){
			retVal = iMod60 - Math.mod(iMod60,Integer.valueOf(sTimeUnit.replace('分','')));
		}else if(sCalMethodType == System.Label.MSG_1023){
			if(sTimeUnit == '1分'){
				retVal = iMod60;
			}else{
				retVal = iMod60 - Math.mod(iMod60,Integer.valueOf(sTimeUnit.replace('分',''))) + Integer.valueOf(sTimeUnit.replace('分',''));
			}
		}else if(sCalMethodType == System.Label.MSG_1024){
			Integer iMod1 = Math.mod(iMod60,Integer.valueOf(sTimeUnit.replace('分','')));
			Integer iMod2 = Integer.valueOf(sTimeUnit.replace('分',''))/2;
			if(iMod1 == 0){
				retVal = iMod60;
			}else{
				if(iMod1 >= iMod2){
					retVal = iMod60 - Math.mod(iMod60,Integer.valueOf(sTimeUnit.replace('分',''))) + Integer.valueOf(sTimeUnit.replace('分',''));
				}else{
					retVal = iMod60 - Math.mod(iMod60,Integer.valueOf(sTimeUnit.replace('分','')));
				}
			}
		}else{
			retVal = iMod60;
		}
		retVal = iTimeSum - iMod60 + retVal;
		return retVal; 
	}
	*/
	private Decimal getBeforeThreeTime(TimeManagement__c nwItem,User userItem){
		Decimal iRestTime = 0;
		//前３回の休憩時間を計算
        if(nwItem.OutingTime__c != null && nwItem.EnteringTime__c != null){
            // 2015/03/25 15分単位 BEGIN
            /*
            Datetime EnteringTime = datetime.valueOf(nwItem.EnteringTime__c.format('yyyy-MM-dd') + ' ' + nwItem.EnteringTime__c.hour() + ':' + timeFormat(nwItem.EnteringTime__c.minute(),userItem.RestCalMethodType__c,userItem.RestTimeUnit__c) + ':00');
			Datetime OutingTime = datetime.valueOf(nwItem.OutingTime__c.format('yyyy-MM-dd') + ' ' + nwItem.OutingTime__c.hour() + ':' + timeFormat(nwItem.OutingTime__c.minute(),userItem.OutRestCalMethodType__c,userItem.OutRestTimeUnit__c) + ':00');
					
            iRestTime = Decimal.valueOf(Math.abs(EnteringTime.getTime() - OutingTime.getTime())).divide((1000*60), 0, System.RoundingMode.DOWN);
            */
            Integer decRestTime = (Decimal.valueOf(Math.abs(nwItem.OutingTime__c.getTime() - nwItem.EnteringTime__c.getTime())).divide((1000*60), 0, System.RoundingMode.DOWN)).intValue();
            // 休憩時間は単位で計算して、残値が存在する場合、１単位の時間を加算する
            iRestTime = iRestTime + timeFormat(decRestTime, System.Label.MSG_1023, userItem.RestTimeUnit__c);
            // 2015/03/25 15分単位 END
        }
        if(nwItem.OutingTime2__c != null && nwItem.EnteringTime2__c != null){
            // 2015/03/25 15分単位 BEGIN
            /*
        	Datetime EnteringTime = datetime.valueOf(nwItem.EnteringTime2__c.format('yyyy-MM-dd') + ' ' + nwItem.EnteringTime2__c.hour() + ':' + timeFormat(nwItem.EnteringTime2__c.minute(),userItem.RestCalMethodType__c,userItem.RestTimeUnit__c) + ':00');
			Datetime OutingTime = datetime.valueOf(nwItem.OutingTime2__c.format('yyyy-MM-dd') + ' ' + nwItem.OutingTime2__c.hour() + ':' + timeFormat(nwItem.OutingTime2__c.minute(),userItem.OutRestCalMethodType__c,userItem.OutRestTimeUnit__c) + ':00');
			
            iRestTime = iRestTime + Decimal.valueOf(Math.abs(EnteringTime.getTime() - OutingTime.getTime())).divide((1000*60), 0, System.RoundingMode.DOWN);
            */
            Integer decRestTime = (Decimal.valueOf(Math.abs(nwItem.OutingTime2__c.getTime() - nwItem.EnteringTime2__c.getTime())).divide((1000*60), 0, System.RoundingMode.DOWN)).intValue();
            // 休憩時間は単位で計算して、残値が存在する場合、１単位の時間を加算する
            iRestTime = iRestTime + timeFormat(decRestTime, System.Label.MSG_1023, userItem.RestTimeUnit__c);
            // 2015/03/25 15分単位 END
        }
        if(nwItem.OutingTime3__c != null && nwItem.EnteringTime3__c != null){
            // 2015/03/25 15分単位 BEGIN
            /*
        	Datetime EnteringTime = datetime.valueOf(nwItem.EnteringTime3__c.format('yyyy-MM-dd') + ' ' + nwItem.EnteringTime3__c.hour() + ':' + timeFormat(nwItem.EnteringTime3__c.minute(),userItem.RestCalMethodType__c,userItem.RestTimeUnit__c) + ':00');
			Datetime OutingTime = datetime.valueOf(nwItem.OutingTime3__c.format('yyyy-MM-dd') + ' ' + nwItem.OutingTime3__c.hour() + ':' + timeFormat(nwItem.OutingTime3__c.minute(),userItem.OutRestCalMethodType__c,userItem.OutRestTimeUnit__c) + ':00');
			
            iRestTime = iRestTime + Decimal.valueOf(Math.abs(EnteringTime.getTime() - OutingTime.getTime())).divide((1000*60), 0, System.RoundingMode.DOWN);
            */
            Integer decRestTime = (Decimal.valueOf(Math.abs(nwItem.OutingTime3__c.getTime() - nwItem.EnteringTime3__c.getTime())).divide((1000*60), 0, System.RoundingMode.DOWN)).intValue();
            // 休憩時間は単位で計算して、残値が存在する場合、１単位の時間を加算する
            iRestTime = iRestTime + timeFormat(decRestTime, System.Label.MSG_1023, userItem.RestTimeUnit__c);
            // 2015/03/25 15分単位 END
        }
        return iRestTime;
	}
	//時間単位で計算 
	public static Integer timeFormat(Integer iTimeMinute,String sCalMethodType,String sTimeUnit){
		Integer retVal = 0;
		if(iTimeMinute <= 0) return 0;
		//Integer iMod60 = Math.mod(iTimeSum, 60);
		Integer iMod60 = iTimeMinute;
		if(String.isEmpty(sTimeUnit)) return iTimeMinute;
		if(sCalMethodType == System.Label.MSG_1022){		// 切り捨て
			retVal = iMod60 - Math.mod(iMod60,Integer.valueOf(sTimeUnit.replace('分','')));
		}else if(sCalMethodType == System.Label.MSG_1023){	// 切り上げ
			if(sTimeUnit == '1分'){
				retVal = iMod60;
			}else{
				if(Math.mod(iMod60,Integer.valueOf(sTimeUnit.replace('分',''))) == 0){
					retVal = iMod60;
				}else{
					retVal = iMod60 - Math.mod(iMod60,Integer.valueOf(sTimeUnit.replace('分',''))) + Integer.valueOf(sTimeUnit.replace('分',''));
				}
			}
		}else if(sCalMethodType == System.Label.MSG_1024){	// >四捨五入
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
	/* 2015/11/24 Chatterへポスト機能外す
	private String getApprovaledUserId(Id recordId){
		String approvaledUserId = '';
		List<ProcessInstanceStep> workStepList = [SELECT Id ,
													 StepStatus,
													 ActorId,
													 CreatedDate
                                              FROM ProcessInstanceStep
                                              WHERE ProcessInstance.TargetObjectID =:recordId
                                              AND ProcessInstance.Status = 'Approved'
                                              AND StepStatus = 'Approved'
                                              order by CreatedDate desc];
    	if(!workStepList.isEmpty()){
    		approvaledUserId = workStepList[0].ActorId;
    	}
    	return approvaledUserId;
	}*/
	private void setChatterMessage(TimeManagement__c nwItem){
		// 2015/11/24 Chatterへポスト機能外す
		return;
		/*
		String approvaledUserId = getApprovaledUserId(nwItem.Id);
		if(String.isEmpty(approvaledUserId)) return;*/
		/*
		ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
        messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = '勤怠情報の修正をお知らせします。\r\n';
        messageInput.messageSegments.add(textSegment);
        textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = '　　　　従業員名：' + nwItem.WorkerName__c + '\r\n';
        messageInput.messageSegments.add(textSegment);
        textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = '　　　　勤怠日：' + nwItem.WorkDay__c.format() + '\r\n';
        messageInput.messageSegments.add(textSegment);
        textSegment = new ConnectApi.TextSegmentInput();
        String strURL = URL.getSalesforceBaseUrl().toExternalForm() + '/' + nwItem.Id;
        textSegment.text = '詳しくは、 '+ strURL +' をご覧ください。';
        messageInput.messageSegments.add(textSegment);
        ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        input.body = messageInput;

		// PARAMETERS(communityId, feedType, subjectId, input,filebody);
        ConnectApi.ChatterFeeds.postFeedItem(null,ConnectApi.FeedType.Record,approvaledUserId,Input, null);
        */
        // 2015/11/24 Chatterへポスト機能外す
        /*
		FeedItem post = new FeedItem();
		post.Type = 'LinkPost';
		post.title = nwItem.WorkerName__c + 'によって、勤怠日：' + nwItem.WorkDay__c.format() +' の情報が修正されましたのでお知らせします。';
		post.ParentId = approvaledUserId; //eg. Installer
		post.LinkUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + nwItem.Id;
		insert post;*/
	}
    /**
    * 残業時間、深夜時間項目設定を行う
    **/
    public void autoSetupOverTime(TimeManagement__c[] newList){
        // 勤怠の登録者の所属する店舗コードを取得して、該当店舗コードに関連の設定情報を取得する
        //newList = [select WorkBeginTime__c,WorkEndTime__c,WorkBeginTimeHM__c,WorkEndTimeHM__c,OutingTime__c,OutingTimeHM__c,EnteringTime__c,EnteringTimeHM__c,OutingTime2__c,OutingTime2HM__c,EnteringTime2__c,EnteringTime2HM__c,OutingTime3__c,OutingTime3HM__c,EnteringTime3__c,EnteringTime3HM__c,OverTime__c From TimeManagement__c ];
        for (TimeManagement__c tm : newList) {
            User usr = UserUtil.getUser(tm.WorkerRef__c);
            String shopCd = CommUtils.nullToBlank(usr.shopCode__c);
            // 勤怠時間数（分単位)
            // 注意：MinuteSum__c　この項目の計算結果がおかしいです
            WorkTimeDefine__c wkTimeDef = WorkTimeDefineUtil.getWkDefineByShopCode(shopCd);
            // 残業時間計算を行う
            tm.OverTime__c = 0;
            if (tm.MinuteSum__c > wkTimeDef.DayOfRegularWorkTime__c ) {
                tm.OverTime__c = tm.MinuteSum__c - wkTimeDef.DayOfRegularWorkTime__c;
            }
            // 深夜の作業時間(休憩時間も含め)
            if (tm.WorkBeginTime__c != null && tm.WorkEndTime__c != null ) {
                tm.LateNightTime__c = 
                                lateNightWorkTimeCal(
                                    wkTimeDef.LateNightStartTime__c,
                                    wkTimeDef.LateNightEndTime__c,
                                    tm.WorkBeginTime__c,
                                    tm.WorkEndTime__c,
                                    usr.TimeUnit__c // 退勤の計算単位
                                );
            }
            tm.LateNightRestTime__c = 0;
            Date startDt = (tm.WorkBeginTime__c != null ? tm.WorkBeginTime__c.date() : null);
            // 深夜時間計算を行う
            if(tm.OutingTime__c != null && tm.EnteringTime__c != null){
                tm.LateNightRestTime__c += 
                                lateNightRestTimeCal(
                                    startDt,
                                    wkTimeDef.LateNightStartTime__c,
                                    wkTimeDef.LateNightEndTime__c,
                                    tm.OutingTime__c,
                                    tm.EnteringTime__c,
                                    usr.RestTimeUnit__c
                                );
            }
            if(tm.OutingTime2__c != null && tm.EnteringTime2__c != null){
                tm.LateNightRestTime__c += 
                                lateNightRestTimeCal(   
                                    startDt,
                                    wkTimeDef.LateNightStartTime__c,
                                    wkTimeDef.LateNightEndTime__c,
                                    tm.OutingTime2__c,
                                    tm.EnteringTime2__c,
                                    usr.RestTimeUnit__c
                                    );
            }
            if(tm.OutingTime3__c != null && tm.EnteringTime3__c != null){
                tm.LateNightRestTime__c += 
                                lateNightRestTimeCal(   
                                    startDt,
                                    wkTimeDef.LateNightStartTime__c,
                                    wkTimeDef.LateNightEndTime__c,
                                    tm.OutingTime3__c,
                                    tm.EnteringTime3__c,
                                    usr.RestTimeUnit__c
                                );
            }
        }
    }
    /** 出勤時間の間、深夜時間数を計算を行う */
    private Integer lateNightWorkTimeCal(String lateNightStartTime, String lateNightEndTime, DateTime workStartTime, DateTime workEndTime, String timeUnit) {
        return lateNightTimeCal(workStartTime.date(), lateNightStartTime, lateNightEndTime, workStartTime, workEndTime, timeUnit, Label.MSG_1022);
    }
    /** 深夜休憩時間計算を行う */
    public static Integer lateNightRestTimeCal(Date startDt , String lateNightStartTime, String lateNightEndTime, DateTime restStartTime, DateTime restEndTime, String restTimeUnit) {
        if (startDt == null) return 0;
        return lateNightTimeCal(startDt, lateNightStartTime, lateNightEndTime, restStartTime, restEndTime, restTimeUnit, Label.MSG_1023);
    }
    /**
    * 
    **/
    private static Integer lateNightTimeCal(Date startDt, String lateNightStartTime, String lateNightEndTime, DateTime restStartTime, DateTime restEndTime, String restTimeUnit, String calType) {
        // 深夜休憩時間を計算を行う
        String[] splitStartHm = lateNightStartTime.split(':');
        String[] splitEndHm = lateNightEndTime.split(':');
        DateTime lateBeginTime = DateTime.newInstance(startDt, Time.newInstance(Integer.valueOf(splitStartHm[0]), Integer.valueOf(splitStartHm[1]),0,0) );
        DateTime lateEndTime = DateTime.newInstance(startDt.addDays(1), Time.newInstance(Integer.valueOf(splitEndHm[0]), Integer.valueOf(splitEndHm[1]),0,0) );
	// 外出の時間は深夜の範囲の場合　OR　入室の時間は深夜の範囲の場合
        if  (restStartTime < lateEndTime && restEndTime > lateBeginTime ) {
            // 深夜休憩時間を格納する
            // 入室時間
            DateTime workEnterTime = restEndTime > lateEndTime ? lateEndTime : restEndTime;
            // 出室時間
            DateTime workOutTime   = restStartTime < lateBeginTime ? lateBeginTime : restStartTime;

            // 休憩時間を計算を行う
            Integer decLateRestTime = (Decimal.valueOf(Math.abs(workEnterTime.getTime() - workOutTime.getTime())).divide((1000*60), 0, System.RoundingMode.DOWN)).intValue();
            // 深夜休憩時間
            return (TimeManagementTriggerProcess.timeFormat(decLateRestTime, calType, restTimeUnit));
        }
        return 0;
    }
    // 労働基準参考資料：
    // http://www.roudou.net/ki_zangyo.htm
    
    /**
    * スタッフスケジュール参照関係に構築を行う
    * After Insert/After Update
    **/
    public void linkIdToStaffSchedule(TimeManagement__c[] newList, TimeManagement__c[] oldList, CommConst.TriggerMethod action){
    	// 2019/09/15 Security Check BY zyz BEGIN
    	List<String> chkFieldsLst = new List<String>{'timemanagementref__c'};
    	Map<String,Schema.SObjectField> mm = Schema.SObjectType.StaffSchedule__c.fields.getMap();
    	if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
    		return ;
    	}
    	// 2019/09/15 Security Check BY zyz END
    	Integer idx = 0;
    	map<String, TimeManagement__c> timeInfMap = new map<String, TimeManagement__c>();
    	for (TimeManagement__c tm : newList) {
    		if (tm.WorkDay__c == null) continue;
    		// 検索キー
    		String key = CommUtils.nullToBLank(tm.WorkerRef__c) + '_' + tm.WorkDay__c.format();
    		// 新規の場合、自動リンクする
    		if ( action == CommConst.TriggerMethod.IsInsert) {
    			timeInfMap.put(key, tm);
    		}
    		// 更新の場合、勤怠者と勤怠日にて、自動リンクを行う
    		else if ( action == CommConst.TriggerMethod.IsUpdate) {
				if (tm.WorkerRef__c != oldList[idx].WorkerRef__c ||
					tm.WorkDay__c != oldList[idx].WorkDay__c) {
					timeInfMap.put(key, tm);
				}
    		}
    		idx++;
    	}
    	if (timeInfMap.isEmpty()) return;
    	// 関連リンクを行う
    	List<StaffSchedule__c> staffSchedules = [select id, SearchKey__c from StaffSchedule__c where SearchKey__c in :timeInfMap.keySet()];
    	List<StaffSchedule__c> updLst = new List<StaffSchedule__c>();
    	for (StaffSchedule__c sf : staffSchedules) {
    		if (timeInfMap.containsKey(sf.SearchKey__c)) {
    			sf.TimeManagementRef__c = timeInfMap.get(sf.SearchKey__c).Id;
    			updLst.add(sf);	
    		}
    	}
    	if (!updLst.isEmpty()) update updLst;
    }
}