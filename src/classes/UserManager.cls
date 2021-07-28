/****************
* ユーザー情報管理
* 2015/11/09 日またがりの処理で、朝9時に出勤して、夜中ゼロ時を過ぎてから退勤をクリックすると、各ボタン上のタイムスタンプが非表示→表示に変更
*            システム管理者　OR　承認済　の勤怠情報を直接標準画面から修正可能の対応
*****************/
global with sharing class UserManager {

    //public String getNowDateTime() { return System.now().format('yyyy/MM/dd HH:mm');}
    public String getNowDateTime() { return System.now().format();}
    public String validateBeginTime{set;get;}		// 出勤ボタンに表示のメッセージ
    public String validateEndTime{set;get;}			// 退勤ボタンに表示のメッセージ
    public String validateOutingTime{set;get;}		// 外出ボタンに表示のメッセージ
    public String validateEnteringTime{set;get;}	// 入室ボタンに表示のメッセージ
    public String currentStatus{get;set;}
    public String currentRecordId{get;set;}
    public String reportUrlPara{get;private set;}
    public String lastWorkDateId{get;set;}
    
    public Boolean isShowBeginBtnMsg{get;set;}
    public Boolean isShowEndBtnMsg{get;set;}
    //public Boolean isShowDataCheckMsg{get;set;}
    public String alertBeginBtnMsg{get;set;}
    public String alertEndBtnMsg{get;set;}
    public String alertInOutBtnMsg{get;set;}
    public String alertDataCheckMsg{get;set;}
    //public String ipAddress{get;set;}
    public Integer offsetX_EndBtn{get;set;}
    //public Integer offsetX_BeginBtn{get;set;}
    //public Integer lineHeight{get;set;}

	private Boolean isError = false;
	// ボタン色設定情報はXMLから取得する
	public StaffScheduleCtrl.WorkTimeButtonInfo workBtnInfo{get; private set;}
	
    public UserManager(){

    	refreshWorkStatus();
        //レポートIDを取得する
        // 2015/11/10 当月勤怠修正はチャットグループに遷移対応 BEGIN
        //List<Report> reportList = [select Id from Report where Name = :CommDefine__c.getOrgDefaults().PersonTMInfoReport__c limit 1];
        //if(!reportList.isEmpty()) reportUrlPara = String.valueOf(reportList[0].Id);
        reportUrlPara = '';
        List<String> chatterGroupNamesLst = CommConst.GetChatterGroupNameByCode(CommConst.Work_ChatterGroupNameType);
		if (!chatterGroupNamesLst.isEmpty()) {
			List<CollaborationGroup> chatterGroups = [select Id, Name from CollaborationGroup where name = :chatterGroupNamesLst];
        	if (!chatterGroups.isEmpty()){
        		reportUrlPara = chatterGroups[0].Id;
        	}
        }
        // 2015/11/10 当月勤怠修正はチャットグループに遷移対応 END
        //ipAddress = ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP');
        workBtnInfo = StaffScheduleCtrl.getWorkTimeButtonInfo(UserUtil.CurrentUser.ShopCode__c, null);
    }
    
    // ** 最新勤怠状態チェックを行う **/
    private void refreshWorkStatus() {
    	
    	isShowBeginBtnMsg = false;
    	isShowEndBtnMsg = true;
    	//isShowDataCheckMsg = true;
    	
    	alertBeginBtnMsg = '';
    	alertEndBtnMsg = System.Label.MSG_1005;
    	alertInOutBtnMsg = '';
    	alertDataCheckMsg = '';
    	lastWorkDateId = '';
    	currentRecordId = '';
    	offsetX_EndBtn = -8;
    	//offsetX_BeginBtn = 30;
    	//lineHeight = 1;
    	
        validateBeginTime = System.Label.MSG_1006;
        validateEndTime = System.Label.MSG_1007;
        validateOutingTime = System.Label.MSG_1008;
        validateEnteringTime = System.Label.MSG_1009;
        currentStatus = System.Label.MSG_1010;
        
        //reportUrlPara = '';
        DateTime nowDt = System.now();
        Date busDay = nowDt.date();
        //最新の勤務日の勤怠管理データが異常かどうか判断
        List<TimeManagement__c> lastWkTimeList = [select Id,WorkDay__c,WorkBeginTime__c,WorkEndTime__c,OutingTime__c,EnteringTime__c,OutingTime2__c,EnteringTime2__c,OutingTime3__c,EnteringTime3__c from TimeManagement__c where WorkerRef__c = :userInfo.getUserId() And WorkDay__c < :busDay order by WorkDay__c desc limit 1];
        String strErrorMsg = '';
        String msgType = '';
        if(!lastWkTimeList.isEmpty()){
        	if(lastWkTimeList[0].OutingTime3__c == null && lastWkTimeList[0].EnteringTime3__c != null) msgType = '4';
        	if(lastWkTimeList[0].OutingTime3__c != null && lastWkTimeList[0].EnteringTime3__c == null) msgType = '3';
        	if(lastWkTimeList[0].OutingTime2__c == null && lastWkTimeList[0].EnteringTime2__c != null) msgType = '4';
        	if(lastWkTimeList[0].OutingTime2__c != null && lastWkTimeList[0].EnteringTime2__c == null) msgType = '3';
        	if(lastWkTimeList[0].OutingTime__c == null && lastWkTimeList[0].EnteringTime__c != null) msgType = '4';
        	if(lastWkTimeList[0].OutingTime__c != null && lastWkTimeList[0].EnteringTime__c == null) msgType = '3';
        	if(lastWkTimeList[0].WorkBeginTime__c == null) msgType = '2';
        	if(lastWkTimeList[0].WorkEndTime__c == null) msgType = '1';
        	if(msgType == '4') strErrorMsg = System.Label.MSG_1011;
        	if(msgType == '3') strErrorMsg = System.Label.MSG_1012;
        	if(msgType == '2') strErrorMsg = System.Label.MSG_1026;
        	if(msgType == '1') strErrorMsg = System.Label.MSG_1027;
        	if(msgType != '') isError = true;
        	if(isError){
        		lastWorkDateId = lastWkTimeList[0].Id;
	        	//alertDataCheckMsg = '<a href="#" onClick="javascript:toDetailPage();return false;"><font color="FF0040">勤怠日：' + lastWkTimeList[0].WorkDay__c.format() + '</a></font><br/><h4>'+ System.Label.MSG_1011 + '</h4>';
	        	//勤怠日：
	        	//の情報に「XXXXXX」を
	        	//設定していないです。
	        	//alertDataCheckMsg = '<span style="font-size: 13px" class="smartPhoneBalloon"><a href="javascript:void(0)" onClick="javascript:toDetailPage();return false;"><font color="FF0040">'+ Label.MSG_001_0066 + lastWkTimeList[0].WorkDay__c.format() + '</a></font><br/><h4>の情報に「' + strErrorMsg + '」を<br/>設定していないです。</h4></span>';
	        	alertDataCheckMsg = '<span style="font-size: 13px" class="smartPhoneBalloon"><a href="javascript:void(0)" onClick="javascript:toDetailPage();return false;"><font color="FF0040">'+ Label.CONST_035_0153 + lastWkTimeList[0].WorkDay__c.format() + '</a></font><br/><h4>'+ Label.CONST_035_0154.replace('XXXXXX',strErrorMsg) +'<br/>'+ Label.CONST_035_0155 +'</h4></span>';
	        }else{
	        	alertDataCheckMsg = '';
	        }
        }
        if(isError) alertInOutBtnMsg = alertDataCheckMsg;
        
        List<TimeManagement__c> wkTimeLst = [select Id,
													WorkBeginTime__c,
													WorkEndTime__c,
													OutingTime__c,
													EnteringTime__c,
													OutingTime2__c,
													EnteringTime2__c,
													OutingTime3__c,
													EnteringTime3__c
											from TimeManagement__c where WorkerRef__c = :userInfo.getUserId() And WorkDay__c = :busDay limit 1];
        if(!wkTimeLst.isEmpty()){
        	isShowBeginBtnMsg = false;
        	//lineHeight = 3;
            //alertBeginBtnMsg = System.Label.MSG_1012;
            //offsetX_BeginBtn = 30;
        	isShowEndBtnMsg = false;
            alertEndBtnMsg = '';
            currentRecordId = wkTimeLst[0].Id;
            List<RestTimeManagement__c> restTimeList = [select Id,OutingTime__c,EnteringTime__c from RestTimeManagement__c where WorkTimeInfo__c = :currentRecordId order by CreatedDate desc limit 1 ];

            if(wkTimeLst[0].WorkBeginTime__c != null){
                validateBeginTime = validateBeginTime + ' ' + String.valueOf(wkTimeLst[0].WorkBeginTime__c).substring(8,16);
                currentStatus = System.Label.MSG_1013;
            }
            if(!restTimeList.isEmpty()){
                if(restTimeList[0].OutingTime__c != null){
                    validateOutingTime = validateOutingTime + ' ' + String.valueOf(restTimeList[0].OutingTime__c).substring(8,16);
                    currentStatus = System.Label.MSG_1014;
                }
                if(restTimeList[0].EnteringTime__c != null){
                    validateEnteringTime = validateEnteringTime + ' ' + String.valueOf(restTimeList[0].EnteringTime__c).substring(8,16);
                    currentStatus = System.Label.MSG_1013;
                }
            }else{
            	Integer i = 0;
            	if(wkTimeLst[0].OutingTime3__c != null){
            		i = 3;
		    		validateOutingTime = validateOutingTime + ' ' + String.valueOf(wkTimeLst[0].OutingTime3__c).substring(8,16);
					currentStatus = System.Label.MSG_1014;
					if(wkTimeLst[0].EnteringTime3__c == null) validateEnteringTime = System.Label.MSG_1009;
		    	}else if(wkTimeLst[0].OutingTime2__c != null){
		    		i = 2;
		    		validateOutingTime = validateOutingTime + ' ' + String.valueOf(wkTimeLst[0].OutingTime2__c).substring(8,16);
					currentStatus = System.Label.MSG_1014;
					if(wkTimeLst[0].EnteringTime2__c == null) validateEnteringTime = System.Label.MSG_1009;
		    	}else if(wkTimeLst[0].OutingTime__c != null){
		    		i = 1;
		    		validateOutingTime = validateOutingTime + ' ' + String.valueOf(wkTimeLst[0].OutingTime__c).substring(8,16);
					currentStatus = System.Label.MSG_1014;
					if(wkTimeLst[0].EnteringTime__c == null) validateEnteringTime = System.Label.MSG_1009;
		    	}
		    	if(wkTimeLst[0].EnteringTime3__c != null && i == 3){
		    		validateEnteringTime = validateEnteringTime + ' ' + String.valueOf(wkTimeLst[0].EnteringTime3__c).substring(8,16);
					currentStatus = System.Label.MSG_1013;
		    	}else if(wkTimeLst[0].EnteringTime2__c != null && i == 2){
		    		validateEnteringTime = validateEnteringTime + ' ' + String.valueOf(wkTimeLst[0].EnteringTime2__c).substring(8,16);
					currentStatus = System.Label.MSG_1013;
		    	}else if(wkTimeLst[0].EnteringTime__c != null && i == 1){
		    		validateEnteringTime = validateEnteringTime + ' ' + String.valueOf(wkTimeLst[0].EnteringTime__c).substring(8,16);
					currentStatus = System.Label.MSG_1013;
		    	}
            }
            if(wkTimeLst[0].WorkEndTime__c != null){
                validateEndTime = validateEndTime + ' ' + String.valueOf(wkTimeLst[0].WorkEndTime__c).substring(8,16);
                currentStatus = System.Label.MSG_1007;
            }
        }else{
			// 前日の勤怠情報が存在する場合[]
	        if(!lastWkTimeList.isEmpty()){
	        	// 前日の勤怠時間はまだ未退勤の場合、続いて、画面に勤怠情報を入力可能
	        	if (lastWkTimeList[0].WorkBeginTime__c != null && lastWkTimeList[0].WorkEndTime__c == null) {
		        	isError = false;	// エラー情報を非表示
		        	alertDataCheckMsg = alertInOutBtnMsg = alertEndBtnMsg = '';
	        		// 前日の勤怠時間を続けて処理を行う
	        		StrideWorkTimeShow(lastWkTimeList[0]);
	        	} else {
	        		// 前日の勤怠情報が存在する場合、当日の出勤ボタンに、前日の勤怠情報のステータスを表示する
		        	isShowBeginBtnMsg = false;
	        		alertInOutBtnMsg = System.Label.MSG_1005;
	        	}
	        } else {
	        	// 前日の勤怠情報がなし、かつ　今日の勤怠情報は未登録する場合、開始ボタンにメッセージを表示なし、
	        	alertInOutBtnMsg = System.Label.MSG_1005;
	        }
        }
    	if(!isShowBeginBtnMsg && isError){
    		alertBeginBtnMsg = alertDataCheckMsg;
    		//offsetX_BeginBtn = 30;
    	}
    	if(!isShowEndBtnMsg && isError){
    		alertEndBtnMsg = alertDataCheckMsg;
    		offsetX_EndBtn = -30;
    	}
    }

    // 出勤、退勤管理機能
    /**
    * 出勤、退勤管理機能
    * workType: 1 出勤 9　退勤  2 外出  3 入室
    **/
    /*  page js function 一時バックアップ
    function regiestWorkTime(eventType) {
        blockUi();
        // 勤怠登録を行う
        Visualforce.remoting.Manager.invokeAction(
            '{!$RemoteAction.UserManager.regiestWorkTime}',
            eventType,
            function(result, event){
                if (event.status) {
                    $("span[id$=':timerBlock']").text('打刻時刻：' + result);
                    unblockUi();
                } else if (event.type === 'exception') {
                    window.alert("データ登録異常発生するため、ボタンを再クリックください。");
                    unblockUi();
                }
            },
            {escape: true}
        );
    }
    */

    @RemoteAction
    global static String regiestWorkTime( Integer workType ) {
        return '';
        /*
        DateTime nowDt = System.now();
        Date busDay = nowDt.date();

        // 既存データ存在するかどうかチェックを行う
        List<TimeManagement__c> wkTimeLst = [select WorkBeginTime__c, WorkEndTime__c, OutingTime__c, EnteringTime__c, RecordTime__c
            from TimeManagement__c where WorkerRef__c = :userInfo.getUserId() And WorkDay__c = :busDay limit 1];

        TimeManagement__c wkTime = null;
        if (wkTimeLst.isEmpty()) {
            wkTime = new TimeManagement__c();
            wkTime.WorkDay__c = busDay;
            wkTime.WorkerRef__c = UserInfo.getUserId();
            wkTime.WorkerName__c = UserInfo.getName();
        } else {
            wkTime = wkTimeLst[0];
        }
        wkTime.RecordTime__c = System.now();
        // 出勤
        if (workType == 1) wkTime.WorkBeginTime__c = nowDt;
        // 外出
        else if (workType == 2) wkTime.OutingTime__c = nowDt;
        // 入室
        else if (workType == 3) wkTime.EnteringTime__c = nowDt;
        // 退勤
        else if (workType == 9) wkTime.WorkEndTime__c = nowDt;

        upsert wkTime;
        return nowDt.format('yyyy/MM/dd HH:mm');
        //エラーチェックのロジック、無効にしてください。
        if (wkTimeLst.isEmpty()) {
            //出勤
            if(workType == 1){
                wkTime = new TimeManagement__c();
                wkTime.WorkBeginTime__c = nowDt;
                wkTime.WorkDay__c = busDay;
                wkTime.WorkerRef__c = UserInfo.getUserId();
                wkTime.WorkerName__c = UserInfo.getName();
                wkTime.RecordTime__c = System.now();
                insert wkTime;
                return 'success';
            }else if(workType == 9){
                //前日勤務情報を取得する
                Date beforeBusDay = busDay.addDays(-1);
                List<TimeManagement__c> wkBeforeTimeLst = [select WorkBeginTime__c, WorkEndTime__c, OutingTime__c, EnteringTime__c, RecordTime__c
                from TimeManagement__c where WorkerRef__c = :userInfo.getUserId() And WorkDay__c = :beforeBusDay limit 1];
                if(!wkBeforeTimeLst.isEmpty()){
                    if(wkBeforeTimeLst[0].WorkEndTime__c == null){
                        //勤務時間が２４時間を超えた場合
                        wkBeforeTimeLst[0].WorkEndTime__c = nowDt;
                        wkBeforeTimeLst[0].RecordTime__c = System.now();
                        update wkBeforeTimeLst[0];
                        return 'success';
                    }
                }
            }
            return '今日はまだ出勤していません、出勤ボタンをクリックしてください。';
        }else{
            wkTime = wkTimeLst[0];
            if(workType == 1){
                //重複出勤打刻の場合
                return '今日は既に出勤しました。';
            }else if(workType == 9){
                if(wkTime.OutingTime__c != null && wkTime.EnteringTime__c == null) return '外出した後、まだ入室していないです、入室ボタンをクリックしてください。';
                //退勤(２回退勤することが出来ます)
                wkTime.WorkEndTime__c = nowDt;
            }else if(workType == 2){
                if(wkTime.WorkEndTime__c != null) return '退勤した上、外出することが出来ません。';
                //外出
                if(wkTime.OutingTime__c == null){
                    wkTime.OutingTime__c = nowDt;
                }else{
                    if(wkTime.EnteringTime__c == null) return '前回の入室をしていないため、今回の外出を出来ません。';
                    wkTime.OutingTime2__c = nowDt;
                }
            }else if(workType == 3){
                //入室
                if(wkTime.WorkEndTime__c != null) return '退勤した上、入室することが出来ません。';
                if(wkTime.OutingTime__c == null) return '外出していない上に、入室には出来ません。';
                if(wkTime.EnteringTime__c == null){
                    wkTime.EnteringTime__c = nowDt;
                }else{
                    if(wkTime.OutingTime2__c == null) return '前回の外出していない上に、今回の入室には出来ません。';
                    wkTime.EnteringTime2__c = nowDt;
                }
            }
            wkTime.RecordTime__c = System.now();
            update wkTime;
            return 'success';
        }
    */
    }

    /**
    * 出勤、退勤管理機能
    * workType: 1 出勤 9　退勤  2 外出  3 入室
    **/
    public void apexRegiestWorkTime(){
		// 2018/03/07 Security Check BEGIN
		List<String> chkFields = new List<String>{'Status__c','RecordTime__c','WorkEndTime__c','EnteringTime3__c','EnteringTime2__c',
												'OutingTime3__c','EnteringTime__c','OutingTime2__c','Outingtime__c','WorkBeginTime__c',
												'WorkerName__c','WorkerRef__c','WorkDay__c'};
		Map<String,Schema.SObjectField> m = Schema.SObjectType.TimeManagement__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(chkFields, m)) {
			return;
		}
		if (!CommSecurityUtils.isCanCreateable(chkFields, m)) {
			return;
		}
		// 2018/03/07 Security Check END 
        String workType = Apexpages.currentPage().getParameters().get('actionType');
        if(!String.isEmpty(workType)){
            if(isLockCheck())  return;
            DateTime nowDt = System.now();
            Date busDay = nowDt.date();
            String localFormatTime = String.valueOf(nowDt).substring(8,16);
            String oldStatus = '';
            // 既存データ存在するかどうかチェックを行う
            List<TimeManagement__c> wkTimeLst = [select Id,
                                                        Status__c,
														WorkBeginTime__c,
														WorkEndTime__c,
														OutingTime__c,
														EnteringTime__c,
														OutingTime2__c,
														EnteringTime2__c,
														OutingTime3__c,
														EnteringTime3__c,
														RecordTime__c
                                                from TimeManagement__c where WorkerRef__c = :userInfo.getUserId() And WorkDay__c = :busDay limit 1];

            TimeManagement__c wkTime = null;
            if (wkTimeLst.isEmpty()) {
            	// 当日の勤怠情報はまだない場合:画面から「入室、外出、退勤」
                if(workType == '9' || workType == '2' || workType == '3'){
                    //前日勤務情報を取得する
                    Date beforeBusDay = busDay.addDays(-1);
                    List<TimeManagement__c> wkBeforeTimeLst = [select Id,
				                                                        Status__c,
																		WorkBeginTime__c,
																		WorkEndTime__c,
																		OutingTime__c,
																		EnteringTime__c,
																		OutingTime2__c,
																		EnteringTime2__c,
																		OutingTime3__c,
																		EnteringTime3__c,
																		RecordTime__c
                    from TimeManagement__c where WorkerRef__c = :userInfo.getUserId() And WorkDay__c <= :beforeBusDay order by WorkDay__c desc limit 1];
                    if(!wkBeforeTimeLst.isEmpty()){
                    	// 前日の勤怠情報は未退勤の場合
                        if(wkBeforeTimeLst[0].WorkEndTime__c == null){
                            try{
                            	/*
                                oldStatus = wkBeforeTimeLst[0].Status__c;
                                //勤務時間が２４時間を超えた場合
                                wkBeforeTimeLst[0].WorkEndTime__c = nowDt;
                                wkBeforeTimeLst[0].RecordTime__c = System.now();
                                wkBeforeTimeLst[0].Status__c = '';
                                update wkBeforeTimeLst[0];
                                validateEndTime = validateEndTime + ' ' + String.valueOf(nowDt).substring(8,16);
                                currentStatus = System.Label.MSG_1007;
                                //
                                if(!String.isEmpty(oldStatus)){
                                    wkBeforeTimeLst[0].Status__c = oldStatus;
                                    update wkBeforeTimeLst[0];
                                }
                                return ;
                                */
	                        	Boolean isReturnFlg = StrideWorkTimeProcess(workType, wkBeforeTimeLst[0]);	
	                        	if (!isReturnFlg) {
	                        		// 前日の勤怠情報を退勤すると、当日の勤怠入力状態を切り替えする
						            if (workType == '9') {
						                // 最新出勤情報を取得する
						                // 2015/11/09 BugFix BEGIN
						                //refreshWorkStatus();
						                // 2015/11/09 BugFix END
						            }
	                        		return;
	                        	}
                            }catch(DMLException e){}
                        }
                    }
                }
                wkTime = new TimeManagement__c();
                wkTime.WorkDay__c = busDay;
                wkTime.WorkerRef__c = UserInfo.getUserId();
                wkTime.WorkerName__c = UserInfo.getName();
                // 2015/11/09 BugFix BEGIN
                wkTime.Status__c = System.Label.MSG_1015;
                // 2015/11/09 BugFix END
                insert wkTime;
            } else {
                wkTime = wkTimeLst[0];
            }
            currentRecordId = wkTime.Id;
            // 出勤
            if (workType == '1'){
            	isShowBeginBtnMsg = true;
            	//alertBeginBtnMsg = System.Label.MSG_1012;
            	//lineHeight = 3;
            	isShowEndBtnMsg = false;
            	if(isError){
            		alertInOutBtnMsg = alertDataCheckMsg;
            		alertEndBtnMsg = alertDataCheckMsg;
    				offsetX_EndBtn = -40;
            	}else{
            		alertInOutBtnMsg = '';
            		alertEndBtnMsg = '';
            	}
                if(wkTime.WorkBeginTime__c == null){
                    wkTime.WorkBeginTime__c = nowDt;
                    currentStatus = System.Label.MSG_1013;
                    validateBeginTime = System.Label.MSG_1006 + ' ' + String.valueOf(wkTime.WorkBeginTime__c).substring(8,16);
                }
            }
            // 外出
            else if (workType == '2'){
				if(wkTime.OutingTime__c == null){
					wkTime.OutingTime__c = nowDt;
					validateOutingTime = System.Label.MSG_1008 + ' ' + String.valueOf(wkTime.OutingTime__c).substring(8,16);
					validateEnteringTime = System.Label.MSG_1009;
					currentStatus = System.Label.MSG_1014;
				}else if(wkTime.OutingTime2__c == null && wkTime.EnteringTime__c != null){
					wkTime.OutingTime2__c = nowDt;
					validateOutingTime = System.Label.MSG_1008 + ' ' + String.valueOf(wkTime.OutingTime2__c).substring(8,16);
					validateEnteringTime = System.Label.MSG_1009;
					currentStatus = System.Label.MSG_1014;
				}else if(wkTime.OutingTime3__c == null && wkTime.EnteringTime2__c != null){
					wkTime.OutingTime3__c = nowDt;
					validateOutingTime = System.Label.MSG_1008 + ' ' + String.valueOf(wkTime.OutingTime3__c).substring(8,16);
					validateEnteringTime = System.Label.MSG_1009;
					currentStatus = System.Label.MSG_1014;
				}else if(wkTime.OutingTime3__c != null && wkTime.EnteringTime3__c != null){
					List<RestTimeManagement__c> restTimeList = [select Id from RestTimeManagement__c where WorkTimeInfo__c = :wkTime.Id and EnteringTime__c = null];
					if(restTimeList.isEmpty()){
						RestTimeManagement__c nwItem = new RestTimeManagement__c(
							WorkTimeInfo__c = wkTime.Id,
							OutingTime__c = nowDt
						);
						insert nwItem;
						validateOutingTime = System.Label.MSG_1008 + ' ' + String.valueOf(nowDt).substring(8,16);
						validateEnteringTime = System.Label.MSG_1009;
						currentStatus = System.Label.MSG_1014;
					}
					return;
				}
            }
            // 入室
            else if(workType == '3'){
				if(wkTime.EnteringTime__c == null && wkTime.OutingTime__c != null){
					wkTime.EnteringTime__c = nowDt;
					validateEnteringTime = System.Label.MSG_1009 + ' ' + String.valueOf(wkTime.EnteringTime__c).substring(8,16);
					currentStatus = System.Label.MSG_1013;
				}else if(wkTime.EnteringTime2__c == null && wkTime.OutingTime2__c != null){
					wkTime.EnteringTime2__c = nowDt;
					validateEnteringTime = System.Label.MSG_1009 + ' ' + String.valueOf(wkTime.EnteringTime2__c).substring(8,16);
					currentStatus = System.Label.MSG_1013;
				}else if(wkTime.EnteringTime3__c == null && wkTime.OutingTime3__c != null){
					wkTime.EnteringTime3__c = nowDt;
					validateEnteringTime = System.Label.MSG_1009 + ' ' + String.valueOf(wkTime.EnteringTime3__c).substring(8,16);
					currentStatus = System.Label.MSG_1013;
				}else if(wkTime.OutingTime3__c != null && wkTime.EnteringTime3__c != null){
					List<RestTimeManagement__c> restTimeList = [select Id,EnteringTime__c,FromTMUpdatePage__c from RestTimeManagement__c where WorkTimeInfo__c = :wkTime.Id and EnteringTime__c = null];
					if(!restTimeList.isEmpty()){
						restTimeList[0].EnteringTime__c = nowDt;
						restTimeList[0].FromTMUpdatePage__c = true;
						update restTimeList[0];
						validateEnteringTime = System.Label.MSG_1009 + ' ' + String.valueOf(nowDt).substring(8,16);
						currentStatus = System.Label.MSG_1013;
						restTimeList[0].FromTMUpdatePage__c = false;
						update restTimeList[0];
					}
					return;
				}
            }
            // 退勤
            else if (workType == '9'){
                if(wkTime.WorkEndTime__c == null){
                    wkTime.WorkEndTime__c = nowDt;
                    currentStatus = System.Label.MSG_1007;
                    validateEndTime = System.Label.MSG_1007 + ' ' + String.valueOf(wkTime.WorkEndTime__c).substring(8,16);
                }
            }
            try{
                wkTime.RecordTime__c = System.now();
                oldStatus = wkTime.Status__c;
                wkTime.Status__c = '';
                update wkTime;
                if(!String.isEmpty(oldStatus)){
                    wkTime.Status__c = oldStatus;
                    update wkTime;
                }
            }catch(DMLException e){}
            
            if (workType == '1' || workType == '9') {
                // 最新出勤情報を取得する
                refreshWorkStatus();
            }
        }
    }
    // ** 日またがり勤怠時間表示する   **/
    private boolean StrideWorkTimeShow(TimeManagement__c wkTime) {
 		
 		currentRecordId = wkTime.Id;
        // 関連の休憩時間の最後の勤怠情報を取得する
		List<RestTimeManagement__c> restTimeList = [select Id,OutingTime__c,EnteringTime__c 
													from RestTimeManagement__c where WorkTimeInfo__c = :currentRecordId order by CreatedDate desc limit 1 ];
            
		// 出勤時間は未設定する場合
        if(wkTime.WorkBeginTime__c != null){
            validateBeginTime = validateBeginTime + ' ' + String.valueOf(wkTime.WorkBeginTime__c).substring(8,16);
            currentStatus = System.Label.MSG_1013;
        }
        // 休憩の状態
        if(!restTimeList.isEmpty()){
            if(restTimeList[0].OutingTime__c != null){
                validateOutingTime = validateOutingTime + ' ' + String.valueOf(restTimeList[0].OutingTime__c).substring(8,16);
                currentStatus = System.Label.MSG_1014;
            }
            if(restTimeList[0].EnteringTime__c != null){
                validateEnteringTime = validateEnteringTime + ' ' + String.valueOf(restTimeList[0].EnteringTime__c).substring(8,16);
                currentStatus = System.Label.MSG_1013;
            }
        }else{
        	Integer i = 0;
        	if(wkTime.OutingTime3__c != null){
        		i = 3;
	    		validateOutingTime = validateOutingTime + ' ' + String.valueOf(wkTime.OutingTime3__c).substring(8,16);
				currentStatus = System.Label.MSG_1014;
				if(wkTime.EnteringTime3__c == null) validateEnteringTime = System.Label.MSG_1009;
	    	}else if(wkTime.OutingTime2__c != null){
	    		i = 2;
	    		validateOutingTime = validateOutingTime + ' ' + String.valueOf(wkTime.OutingTime2__c).substring(8,16);
				currentStatus = System.Label.MSG_1014;
				if(wkTime.EnteringTime2__c == null) validateEnteringTime = System.Label.MSG_1009;
	    	}else if(wkTime.OutingTime__c != null){
	    		i = 1;
	    		validateOutingTime = validateOutingTime + ' ' + String.valueOf(wkTime.OutingTime__c).substring(8,16);
				currentStatus = System.Label.MSG_1014;
				if(wkTime.EnteringTime__c == null) validateEnteringTime = System.Label.MSG_1009;
	    	}
	    	if(wkTime.EnteringTime3__c != null && i == 3){
	    		validateEnteringTime = validateEnteringTime + ' ' + String.valueOf(wkTime.EnteringTime3__c).substring(8,16);
				currentStatus = System.Label.MSG_1013;
	    	}else if(wkTime.EnteringTime2__c != null && i == 2){
	    		validateEnteringTime = validateEnteringTime + ' ' + String.valueOf(wkTime.EnteringTime2__c).substring(8,16);
				currentStatus = System.Label.MSG_1013;
	    	}else if(wkTime.EnteringTime__c != null && i == 1){
	    		validateEnteringTime = validateEnteringTime + ' ' + String.valueOf(wkTime.EnteringTime__c).substring(8,16);
				currentStatus = System.Label.MSG_1013;
	    	}
        }
    	return true;
    }
    // ** 日またがり勤怠時間処理を行う 
   	// Return: 次の処理を続けるがどう　TRUE：該当処理後、続いて後ろの処理を行う
    private boolean StrideWorkTimeProcess(String workType, TimeManagement__c wkTime) {
    	// 2018/03/07 Security Check BEGIN
		List<String> chkFields = new List<String>{'Status__c','RecordTime__c','WorkEndTime__c','EnteringTime3__c','EnteringTime2__c',
												'OutingTime3__c','EnteringTime__c','OutingTime2__c','Outingtime__c'};									
		Map<String,Schema.SObjectField> m = Schema.SObjectType.TimeManagement__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(chkFields, m)) {
			return null;
		}
		// 2018/03/07 Security Check END
    	// 外出、入室、退勤以外の場合、処理中止
    	if (workType != '2' && workType != '3' && workType != '9') return true;
    	
        DateTime nowDt = System.now();
        // 外出
        if (workType == '2'){
			if(wkTime.OutingTime__c == null){
				wkTime.OutingTime__c = nowDt;
				validateOutingTime = System.Label.MSG_1008 + ' ' + String.valueOf(wkTime.OutingTime__c).substring(8,16);
				validateEnteringTime = System.Label.MSG_1009;
				currentStatus = System.Label.MSG_1014;
			}else if(wkTime.OutingTime2__c == null && wkTime.EnteringTime__c != null){
				wkTime.OutingTime2__c = nowDt;
				validateOutingTime = System.Label.MSG_1008 + ' ' + String.valueOf(wkTime.OutingTime2__c).substring(8,16);
				validateEnteringTime = System.Label.MSG_1009;
				currentStatus = System.Label.MSG_1014;
			}else if(wkTime.OutingTime3__c == null && wkTime.EnteringTime2__c != null){
				wkTime.OutingTime3__c = nowDt;
				validateOutingTime = System.Label.MSG_1008 + ' ' + String.valueOf(wkTime.OutingTime3__c).substring(8,16);
				validateEnteringTime = System.Label.MSG_1009;
				currentStatus = System.Label.MSG_1014;
			}else if(wkTime.OutingTime3__c != null && wkTime.EnteringTime3__c != null){
				List<RestTimeManagement__c> restTimeList = [select Id from RestTimeManagement__c where WorkTimeInfo__c = :wkTime.Id and EnteringTime__c = null];
				if(restTimeList.isEmpty()){
					RestTimeManagement__c nwItem = new RestTimeManagement__c(
						WorkTimeInfo__c = wkTime.Id,
						OutingTime__c = nowDt
					);
					insert nwItem;
					validateOutingTime = System.Label.MSG_1008 + ' ' + String.valueOf(nowDt).substring(8,16);
					validateEnteringTime = System.Label.MSG_1009;
					currentStatus = System.Label.MSG_1014;
				}
				return false;
			}
        }
        // 入室
        else if(workType == '3'){
			if(wkTime.EnteringTime__c == null && wkTime.OutingTime__c != null){
				wkTime.EnteringTime__c = nowDt;
				validateEnteringTime = System.Label.MSG_1009 + ' ' + String.valueOf(wkTime.EnteringTime__c).substring(8,16);
				currentStatus = System.Label.MSG_1013;
			}else if(wkTime.EnteringTime2__c == null && wkTime.OutingTime2__c != null){
				wkTime.EnteringTime2__c = nowDt;
				validateEnteringTime = System.Label.MSG_1009 + ' ' + String.valueOf(wkTime.EnteringTime2__c).substring(8,16);
				currentStatus = System.Label.MSG_1013;
			}else if(wkTime.EnteringTime3__c == null && wkTime.OutingTime3__c != null){
				wkTime.EnteringTime3__c = nowDt;
				validateEnteringTime = System.Label.MSG_1009 + ' ' + String.valueOf(wkTime.EnteringTime3__c).substring(8,16);
				currentStatus = System.Label.MSG_1013;
			}else if(wkTime.OutingTime3__c != null && wkTime.EnteringTime3__c != null){
				List<RestTimeManagement__c> restTimeList = [select Id,EnteringTime__c,FromTMUpdatePage__c from RestTimeManagement__c where WorkTimeInfo__c = :wkTime.Id and EnteringTime__c = null];
				if(!restTimeList.isEmpty()){
					restTimeList[0].EnteringTime__c = nowDt;
					restTimeList[0].FromTMUpdatePage__c = true;
					update restTimeList[0];
					validateEnteringTime = System.Label.MSG_1009 + ' ' + String.valueOf(nowDt).substring(8,16);
					currentStatus = System.Label.MSG_1013;
					restTimeList[0].FromTMUpdatePage__c = false;
					update restTimeList[0];
				}
				return false;
			}
        }
        // 退勤
        else if (workType == '9'){
            if(wkTime.WorkEndTime__c == null){
                //勤務時間が２４時間を超えた場合
                wkTime.WorkEndTime__c = nowDt;
                wkTime.RecordTime__c = System.now();
                validateEndTime = validateEndTime + ' ' + String.valueOf(nowDt).substring(8,16);
                currentStatus = System.Label.MSG_1007;
            }
        }
        // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        // 勤怠管理の入力規則回避するため、先に元のステータスはクリアして、その後、回復する
        // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    String oldStatus = wkTime.Status__c;
	    //勤務時間が２４時間を超えた場合
	    wkTime.Status__c = '';
	    update wkTime;
	    if(!String.isEmpty(oldStatus)){
	        wkTime.Status__c = oldStatus;
	        update wkTime;
	    }
    	return false;
    }
    
    public void ViewReportProcess(){
    	// 2018/03/07 Security Check BEGIN
		List<String> chkFields = new List<String>{'Status__c'};
		Map<String,Schema.SObjectField> m = Schema.SObjectType.TimeManagement__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(chkFields, m)) {
			return;
		}
		// 2018/03/07 Security Check END
        //勤務情報ステータスの修正
        List<TimeManagement__c> wkTimeAllLst = [select Id,Status__c
                        from TimeManagement__c where WorkerRef__c = :userInfo.getUserId() And (Status__c = null OR Status__c = '')];
        List<TimeManagement__c> wkTimeUpdateLst = new List<TimeManagement__c>();
        for(TimeManagement__c item : wkTimeAllLst){
            item.Status__c = System.Label.MSG_1015;
            wkTimeUpdateLst.add(item);
        }
        if(!wkTimeUpdateLst.isEmpty()){
            try{
                update wkTimeUpdateLst;
            }catch(DMLException e){}
        }
    }
    public void BeforeApprovalProcess(){
    	// 2018/03/07 Security Check BEGIN
		List<String> chkFields = new List<String>{'Status__c'};
		Map<String,Schema.SObjectField> m = Schema.SObjectType.TimeManagement__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(chkFields, m)) {
			return;
		}
		// 2018/03/07 Security Check END
        List<TimeManagement__c> wkTimeLst = [select Id,Status__c from TimeManagement__c where Id=:currentRecordId limit 1];
        if(!wkTimeLst.isEmpty() && String.isEmpty(wkTimeLst[0].Status__c)){
            wkTimeLst[0].Status__c = System.Label.MSG_1015;
            try{
                update wkTimeLst;
            }catch(DMLException e){}
        }
    }
    private Boolean isLockCheck(){
        List<ProcessInstanceWorkitem> workItemList =
             [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectID =:currentRecordId AND ProcessInstance.Status = 'Pending'];
       if(!workItemList.isEmpty()){
            return true;
       }else{
            return false;
       }
    }
}