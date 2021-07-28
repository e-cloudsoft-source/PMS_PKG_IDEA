/*
* 一括処理ロイック
* autoCheckInProcess : 自動チェックイン機能
* autoCalDayAmount : 指定日の会計情報を統計する
* 2013/10/30 処理前の事前チェック処理追加
*/
// 2016/11/25 TIMEZON fix BEGIN by zh
public with sharing class BulkProcessBatch extends CommBaseCtrl {
// 2016/11/25 TIMEZON fix END by zh
	// 集計対象外フラグ
	private static final Integer OutSideAccountFlg = 1;
	// １泊数N部屋は対象フラグ：TRUEの場合、自動チェックイン対象
	private static final Boolean BatchNroomsCheckInFlg = CommDefine__c.getOrgDefaults().BatchNroomsCheckInFlg__c == null ? true : CommDefine__c.getOrgDefaults().BatchNroomsCheckInFlg__c;
	// 会計支払情報の自動作成するがどう判断用[会計処理モード]（会計編集のレイアウトNo.は１の場合、会計支払情報自動昨英、２の場合、会計支払情報作成しない
	private static final Boolean isOldBillModeFlg = ( CommDefine__c.getOrgDefaults().BillInputSwitchCode__c == BillInputSwitchCtrl.BILL_LAYOUT_CODE_2 ? false : true);
	//2016/12/27 会計人數自動設定機能封印 BEGIN by zh
	private static final Boolean AccounntStayPersonsAutoSetupFlg = CommDefine__c.getOrgDefaults().AccounntStayPersonsAutoSetupFlg__c == null ? false : CommDefine__c.getOrgDefaults().AccounntStayPersonsAutoSetupFlg__c;
	//2016/12/27 会計人數自動設定機能封印 END by zh	
	public BulkProcessBatch() {
		//checkInDate = System.now().Format('yyyy/MM/dd');
		checkInDate = System.now().Format(CommBaseCtrl.getDateFormat());
		amoutDate = checkInDate;
		message = '';
		errMessage = '';
	}
	// スケジュール起動日で処理日を設定する
	private Boolean fromScheduleFlg = false;
	// スケジュールの入口
	public void scheduleStart(String strProceDate) {
		checkInDate = strProceDate;
		fromScheduleFlg = true;
		autoCheckInProcess();
	}
    /**
    * 2012/10/30 全データ処理MODE変数設定を行う
    */
    // 全データ処理を行う[支払方法は複数存在する会計データに対して、処理対象外]
    private Boolean isAllFlg = false;
    // 売上自動計算を続いて処理を行うフラグ
    public Boolean isContinueFlg {get; private set;}
    // 全予約データを処理する場合、ＶＦから該当Methodを呼び出しする
    public void setInitVar() {
    	isAllFlg = true;
    	isContinueFlg = false;
    }
    // システム時間を取得する[JS側からＳＦ通信正常判断用]
    public String getApexSystemTime() {
        return String.valueof(DateTime.now().getTime());
    }
    // 画面表示用メッセージ
    public String message{get;private set;}
    public String errMessage{get; private set;}
    /*
    private void clearInfo() {
    	isContinueFlg = false;
    	message = '';
    	errMessage = '以下の連泊予約、複数部屋予約について、初日のチェックイン処理が実行されていません、チェックイン処理を実行して、再度、バッチ処理を起動してください。';
    }*/
    private void addInfMessage(String msg) {
    	//バッチ処理
        message += '<br></br><span style="           font-weight: bold">'+Label.MSG_036_0037+'[INF]</span>: ' + msg;
    }
    private void addErrMessage(String msg) {
    	//バッチ処理
        message += '<br></br><span style="color: red;font-weight: bold">'+Label.MSG_036_0037+'[ERR]</span>: ' + msg;
    }
    private static final String BATCH_CONST_MSG1 = Label.MSG_0020;
    // 処理の予約データチェック情報を格納用
    private void addErrMessage2(String msg) {
    	if (!fromScheduleFlg) {
	    	if (CommUtils.isBlank(errMessage)) errMessage = '<br/>'+BATCH_CONST_MSG1+'<br/><br/>';
	    	errMessage += msg;
    	}
    }
    public Boolean isShowMessage{get{return !CommUtils.isBlank(message);}}
    public Boolean isShwoErrMessage{get{return !CommUtils.isBlank(errMessage);}}
   
	/**
	* 画面から予約IDにて、自動チェックインする
	**/
    @remoteAction
    public static String checkInLeadById(Id leadId) {
		List<Lead__c> leads = [select Field298__c,Rroom__c from Lead__c where id = :leadId And Field298__c = null];
		if (leads.isEmpty()) return '';
		if (CommUtils.isBlank(leads[0].Rroom__c)) {
			//該当予約データの部屋は未割り当てるため、自動チェックインができません。
			return Label.MSG_036_0038;
		}
		leads[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
		// 2017/05/04 店舗ごとの予約・会計権限機能対応 BEGIN
		CommLogicProcess logic = new CommLogicProcess();
		// 新規登録・変更対象データはチェック対象外に設定する
		logic.preventShopAuthCheckSetup(leads);
		// 2017/05/04 店舗ごとの予約・会計権限機能対応 END 
		update leads[0];
		// 2017/05/04 店舗ごとの予約・会計権限機能対応 BEGIN
		logic.restoreShopAuthCheckSetup(leads, true);
		// 2017/05/04 店舗ごとの予約・会計権限機能対応 END 
		return '';
    }
    /**
    * 2013/10/30 バッチ処理の事前チェック処理
    * 処理日の前日の予約データを見る
    * 前日の予約データがない場合、自動チェックイン対象外になる
    * 前日の予約データはあり場合、未チェックインする場合、警告エラー情報を表示する
    * 前日の予約データはあり場合、チェックインすると、該当予約データは自動チェックインを行う
    **/
	/**
	* 2012/08/14 WSQ ADD BEGIN
	* 指定日の予約情報を自動チェックインを行う　
	**/
	// 8桁日付入力項目
	public String checkInDate{get; set;}
//	public Boolean isShowCheckinMsg{get;set;}
	// 自動チェックイン処理日
	public void autoCheckInProcess() {
        // 処理日
		Date checkinDt = null;
		// 表示フラグクリアする
		this.clearMsgFlg();
		// 2016/11/25 TIMEZON fix BEGIN by zh
		//try {
			//checkinDt = Date.parse(checkInDate);
		checkinDt = CommUtils.stringToDate(checkInDate);
			
		//} catch (Exception e) {
		if (checkinDt == null) {
			//有効な処理日を入力ください.
			addErrMessage(Label.MSG_036_0039);
			return;
		}
		//}
		// 2016/11/25 TIMEZON fix END by zh
		
//		isShowCheckinMsg = true;

		// 自動チェックインリスト
		List<Lead__c> upLst = new List<Lead__c>();
		// 全データは処理対象モード場合
		if (isAllFlg) {
			// 宴会のレコードタイプ
			Id enkaiRecTypeId = CommLogicProcess.getLeadEnkaiRecType();
			
            for (Lead__c leadItem: [select Id, Field298__c from Lead__c
                where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG And DAY_ONLY(convertTimezone(EntryTime__c)) = :checkinDt
                //And (LeadIndexRef__r.Nights__c > 1 Or LeadIndexRef__r.Rooms__c > 1 ) And RecordTypeId = :bookingRecTypeId
                //And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
                // 2013/02/11 宴会場は自動チェックイン処理を行わない
                And RecordTypeId != :enkaiRecTypeId
                And Rroom__c != null And Field298__c = null]) {
                //And Field298__c != :CommConst.LEAD_GUEST_ST_CI And Field298__c != :CommConst.LEAD_GUEST_ST_CO]) {
                // チェックイン完了
                leadItem.Field298__c = CommConst.LEAD_GUEST_ST_CI;
                upLst.add(leadItem);
            }
		} else {
			// 宿泊のレコードタイプ
			Id bookingRecTypeId = CommLogicProcess.getLeadBookingRecType();
			// 前日の予約チェックイン情報を取得する[宴会データ]
			// 2012/10/10 取り消しデータは対象外にする
			// 2013/02/11 宴会場は自動チェックイン処理を行わない
			// 2013/10/30 処理対象する予約データの関連予約データはすでにチェックインするがどうかチェックを行う
			
			/*
			for (Lead__c leadItem: [select Id, Field298__c from Lead__c
				where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG And DAY_ONLY(convertTimezone(EntryTime__c)) = :checkinDt
				And RecordTypeId = :enkaiRecTypeId
				//And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
				And Field298__c != :CommConst.LEAD_GUEST_ST_CI And Field298__c != :CommConst.LEAD_GUEST_ST_CO]) {
				// チェックイン完了
				leadItem.Field298__c = CommConst.LEAD_GUEST_ST_CI;
				upLst.add(leadItem);
			}*/
			// チェックイン対象外 AND お客様ステータス != 'チェックイン完' AND お客様ステータス != 'チェックアウト完'
			// 2013/09/23 有効の予約データから予約インデックス、予約インデックスSUB情報を取得して、取得後、該当SUBインデックスの泊数と部屋数を取得、統計を行う
			Set<Id> leadIdxIdSet = new Set<Id>();
			Set<Id> leadIdxSubIdSet = new Set<Id>();
			// 処理対象予約データ情報を格納する
			List<Lead__c> rsLst = new List<Lead__c>();
			// N部屋に、一つはすでにチェックインすると、同じＳＵＢＩＮＤＥＸの部屋は自動チェックインを行う
			Set<Id> checkInedIdSet = new Set<Id>();
			// チェックイン対象リストを取得する
			// 予約データは有効　AND　到着日は画面指定日　AND　予約のレコードタイプは宿泊　AND　部屋アサイン済み　AND　予約ステータスは空白
			for (Lead__c leadItem: [	select Id, Field298__c,LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c 
													from Lead__c
													where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG And DAY_ONLY(convertTimezone(EntryTime__c)) = :checkinDt
													And RecordTypeId = :bookingRecTypeId
													//And Rroom__c != null And Field298__c = null]) {
													And Rroom__c != null ]) {
				// 既にチェックイン済みの部屋が存在する場合、同じ予約IndexSubの部屋も自動チェックイン可能
				if (!CommUtils.isBlank(leadItem.Field298__c)) {
					// 既にチェックイン済みの予約データは処理対象外になる
					checkInedIdSet.add(leadItem.LeadIndexSubId__c);
				} else {
					// 更新予約データ情報を格納する
					leadItem.Field298__c = CommConst.LEAD_GUEST_ST_CI;
					rsLst.add(leadItem);
					// 予約インデックス
					leadIdxIdSet.add(leadItem.LeadIndexRef__c);
					leadIdxSubIdSet.add(leadItem.LeadIndexSubId__c);
				}
			}
			// *******************************************
			// Ｎ部屋　ＯＲ　Ｎ泊の予約データは自動チェックイン対象になる（チェック条件が満足前提）
			// 予約データの関連付く予約インデックスSUBのID格納する
			Set<Id> targetIdSet = new Set<Id>();
			// 該当予約に関連付く予約インデックスSUBの部屋数と泊数を判断する
			String querySubIdx = ' select id,Nights__c,Rooms__c from LeadIndex__c ' +
								 ' where ParentLeadIndxRef__c in :leadIdxIdSet And Id in :leadIdxSubIdSet '+
								 ' And ( Nights__c > 1 ';
			if (BatchNroomsCheckInFlg) querySubIdx += ' OR Rooms__c > 1 ';
			querySubIdx += ' ) ';
			// N泊数　OR　N室数の明細情報のIDを格納する
			for (LeadIndex__c subIdx : DataBase.query(querySubIdx)) {
				targetIdSet.add(subIdx.Id);
			}
			
			//予約INDEX、SUBINDEX グループして、最小の到着日のチェックイン状況は確認する（前日分の予約データは存在　AND　チェックイン済みの場合、該当予約データは自動チェックイン対象
			// 前日の日付
			Date preDate = checkinDt.addDays(-1);
			// 前日の予約データが存在 && 既にチェックインの場合、
			List<Lead__c> preDayLeads = [
											select id,RoomGroupNo__c,LeadIndexSubId__c,Field298__c,Rroom__r.Name, Name
											from Lead__c 
											where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 
											And DAY_ONLY(convertTimezone(EntryTime__c)) = :preDate
											//And Rroom__c != null 
											And LeadIndexRef__c in :leadIdxIdSet
							 				And LeadIndexSubId__c in :targetIdSet];
			// 前日分の予約情報が存在がどうかチェックを行う
			Map<String, Lead__c> preLeadStatusMap = new Map<String, Lead__c>();
			for (Lead__c lead : preDayLeads) {
				// 同じＳＵＢＩＮＤＥＸ、同じグループ
				String key = lead.LeadIndexSubId__c + '_' + lead.RoomGroupNo__c;
				// 既にチェックインする場合
				if (!preLeadStatusMap.containsKey(key)) preLeadStatusMap.put(key,lead);
				else if (!CommUtils.isBlank(lead.Field298__c)) preLeadStatusMap.put(key, lead);
			}
			// エラーありの予約データ情報を格納する
			List<Lead__c> errLeadList = new List<Lead__c>();
			
			for (Lead__c lead : rsLst) {
				// 同じＳＵＢＩＮＤＥＸ、同じグループ
				String key = lead.LeadIndexSubId__c + '_' + lead.RoomGroupNo__c;
				// 前日分は予約データが未存在する場合、対象外の予約データ（初到着日の場合）
				if (!preLeadStatusMap.containsKey(key)) {
		      			// 今日に既にチェックイン済みの部屋が存在する場合(N部屋自動可能)
		      			if (BatchNroomsCheckInFlg) {
		      					// N部屋に既にチェックインあり存在する場合、この関連部屋も自動チェックインする
		      					if (checkInedIdSet.contains( lead.LeadIndexSubId__c)) {
		      						 upLst.add(lead);
		      					}
		      			} else continue;
				} else {
					// 予約データが存在、ステータスは未チェックインの場合、エラー
					Lead__c preLead = preLeadStatusMap.get(key);
					String status = preLead.Field298__c;
					// 前日の予約データは未チェックインの場合
					if (CommUtils.isBlank(status)) {
		      			//addErrMessage2('<span id="'+preLead.Id+'">チェックイン ' + preLead.Rroom__r.Name +' <a href="#" onclick="jsToCheckInFun(\''+ preLead.Id +'\')">'+preLead.Name+'</a><br/></span>');
						//errLeadIdSet.add(lead.Id);
						errLeadList.add(preLead);
					} else {
						// 前日の予約データは既にチェックイン場合
						if (targetIdSet.contains(lead.LeadIndexSubId__c)) upLst.add(lead);
					}
				}
			}
			//if (isShwoErrMessage) {
			if (!errLeadList.isEmpty()) {
				// メール送信を行う[スケジュールから起動する場合]
				if (fromScheduleFlg) {
					// TODO:メール送信
					sendMail(checkinDt, errLeadList);
				} else {
					for (Lead__c preLead : errLeadList) {
						//チェックイン
						addErrMessage2('<span id="'+preLead.Id+'">' + Label.MSG_036_0040 + CommUtils.nullToBlank(preLead.Rroom__r.Name) +' <a href="#" onclick="jsToCheckInFun(\''+ preLead.Id +'\')">'+preLead.Name+'</a><br/></span>');
					}
				}
				return;
			}
			// 連泊する場合　OR　複数部屋の予約データ
			/*
			for (Lead__c leadItem: [select Id, Field298__c from Lead__c
				where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG And DAY_ONLY(convertTimezone(EntryTime__c)) = :checkinDt
				And (LeadIndexRef__r.Nights__c > 1 Or LeadIndexRef__r.Rooms__c > 1 ) And RecordTypeId = :bookingRecTypeId
				//And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
				And Field298__c != :CommConst.LEAD_GUEST_ST_CI And Field298__c != :CommConst.LEAD_GUEST_ST_CO]) {
				// チェックイン完了
				leadItem.Field298__c = CommConst.LEAD_GUEST_ST_CI;
				upLst.add(leadItem);
			}*/
			/*
			for (Lead__c leadItem : rsLst) {
				if (targetIdSet.contains(leadItem.LeadIndexSubId__c)) upLst.add(leadItem);
			}*/
		}
		// 2017/05/04 店舗ごとの予約・会計権限機能対応 BEGIN
		CommLogicProcess logic = new CommLogicProcess();
		// 新規登録・変更対象データはチェック対象外に設定する
		logic.preventShopAuthCheckSetup(upLst);
		// 2017/05/04 店舗ごとの予約・会計権限機能対応 END
		// １件単位でデータコミットを行う
		Database.Saveresult[] rsLst = Database.update(upLst, false);
		Integer successRsCnt = 0;
		Integer failureRsCnt = 0;
		for (Database.Saveresult rs: rsLst) {
			// データ処理結果
			if (!rs.isSuccess()) {
				failureRsCnt ++;
				Database.Error err = rs.getErrors()[0];
				// 2017/05/04 店舗ごとの予約・会計権限機能対応 BEGIN
				String errMsg = CommUtils.getFieldValidationMessage(err.getMessage());
				//addErrMessage(err.getMessage());
				addErrMessage(errMsg);
				// 2017/05/04 店舗ごとの予約・会計権限機能対応 END
			} else {
				successRsCnt ++;
			}
		}
		//if (!rsLst.isEmpty()) {
		//ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
		//	'一括チェックイン処理：成功件数：' + String.valueOf(successRsCnt) + '(件)  ' + '失敗件数：' + String.valueOf(failureRsCnt) + '(件)  '));
		//ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'チェックイン処理済。'));
		//チェックイン処理済。
		addInfMessage(Label.MSG_036_0041);
		//}
		// 当日の売上自動計算を行う
		this.amoutDate = this.checkInDate;
		// 全処理以外モード場合、売上連結計算を行う
		if (!isAllFlg) {
			this.autoCalDayAmount();
		} else {
			isContinueFlg = true;
		}
	}
	
	// Apexでエラー情報を送信を行う
	private void sendMail(Date procDate, List<Lead__c> errLeadList) {
		//　ScheduleResultMailAddress__c
		String mailAdds = CommDefine__c.getOrgDefaults().ScheduleResultMailAddress__c;
		// メール情報を設定する
		String baseURL = 'https://login.salesforce.com';
		//処理日(
		//)のスケジュールバッチ処理する場合、エラーが発生しました
		String errLeadStr = Label.MSG_036_0012 +procDate.format()+ Label.MSG_036_0013 +'\n\n';
		//エラー内容：
		errLeadStr += Label.MSG_036_0014 +BATCH_CONST_MSG1+'\n\n';
		for(Lead__c lead : errLeadList) {
			errLeadStr += baseURL + '/' + lead.Id + '\n';
		}
		if (CommUtils.isBlank(mailAdds)) return;
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = mailAdds.split(',');
		mail.setToAddresses(toAddresses);
		//スケジュール処理エラーの通知
		mail.setSubject(Label.MSG_036_0015);
		mail.setPlainTextBody(errLeadStr);
//System.debug(LoggingLevel.INFO,'mail::::' + mail );
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	}
	
	/**
	* 2013/10/30 チェックイン処理機能追加
	* Paramenter: leadId
	**/
	/*
	public webservice static String checkInLeadById(Id leadId) {
		List<Lead__c> leads = [select Field298__c from Lead__c where id = :leadId And Field298__c = null];
		if (leads.isEmpty()) return '';
		leads[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
		update leads[0];
		return '';
	}*/
	
	// 2012/08/14 WSQ ADD END
	/**
	* 2012/08/23 WSQ ADD BEGIN
	* 指定日の会計情報を自動合計計算を行う　
	**/
	// 会計日格納 8桁日付入力項目(YYYY/MM/DD)
	public String amoutDate{get;set;}
//	public Boolean isShowCalDayAmoutMsg{get;set;}

	private void clearMsgFlg() {
//		isShowCalDayAmoutMsg = false;
//		isShowCheckinMsg = false;
//		calDayAmoutErrMsg = null;
//		calDayAmoutInfMsg = null;
		errMessage = '';
		message = '';
	}
	// 売上計算メッセージ設定
//	public String calDayAmoutErrMsg{get; set;}
//	public String calDayAmoutInfMsg{get; set;}
	public void autoCalDayAmount() {
		// 売上続いて処理フラグはFalseに戻る
		isContinueFlg = false;

		// 指定日の会計情報自動合計を行う
		Date amoutDt = null;
//		try {
			amoutDt = Date.parse(amoutDate);
//		} catch (Exception e) {
			//throw new CommException('有効な処理日を入力ください。');
			//ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '有効な処理日を入力ください.'));
//			calDayAmoutErrMsg = '有効な処理日を入力ください.';
//			return;
//		}
		// 表示フラグクリアする
//		this.clearMsgFlg();
//		isShowCalDayAmoutMsg = true;

        // 該当日の売上存在がどうかチェックを行う
        //String whereDate = amoutDate.replaceAll('/','');
        DateTime wkDt = DateTime.newInstance(amoutDt.year(),amoutDt.month(),amoutDt.day());
        String whereDate = wkDt.format('yyyyMMdd');
        Id rsvAccId = null;
        List<RsvAccount__c> existRsvAccLst = [select id from RsvAccount__c where name = :whereDate limit 1 for update];
		// 同じ日付の会計情報を一括取得して、取得する会計情報は処理を行う
        if (existRsvAccLst.isEmpty()) {
            //throw new CommException('該当売上日のデータが存在しません。');
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, '売上日('+amoutDate+')データがありません。'));
            //売上日
            //データがありません。
            addErrMessage(Label.MSG_036_0042 +'('+amoutDate+')' + Label.MSG_036_0043);
            //calDayAmoutErrMsg = '指定日の売上データが見つかりませんため、更新できせん。';
            return;
        }
        rsvAccId = existRsvAccLst[0].Id;
//System.debug('rsvAccId::::::::' + rsvAccId);
		// 2014/03/06 消費税率情報を格納する
		// 処理する会計データの消費税率>0の数値を取得する、全部の会計データの消費税率はNULLの場合、会計関連の会計明細から設定を行う
		Decimal taxRate = 0;
        // 売上日の会計金額を計算を行う[5万件まで検索できるため:->BatchApexで処理を行う
        // 一括やります「会計支払データは複数存在の会計情報の再計算は要らないです→既に画面に会計済みのものです」
        // 支払情報は集計対象データが未存在する場合、該当会計は未会計計算状態
        // 未計算データだけ、自動会計計算を行う
        // 会計情報を取得する
        Map<Id, AccountAcount__c> accAcountMap = new Map<Id, AccountAcount__c>();
        for(AccountAcount__c item: [
			Select relaccount__c, frs__c, comment__c, TeaTimeFlag__c, Target__c, TableNo__c, Seq__c, Relreserve__c,
			      PlanNo__c, POSNo__c, OutSideAccount__c, Field99__c, Field98__c, Field97__c, Field96__c, Field95__c,
			      Field94__c, Field93__c, Field92__c, Field91__c, Field90__c, Field89__c, Field88__c, Field87__c,
			      Field86__c, Field85__c, Field84__c, Field83__c, Field82__c, Field81__c, Field80__c, Field7__c,
			      Field79__c, Field78__c, Field77__c, Field76__c, Field75__c, Field74__c, Field73__c, Field72__c,
			      Field71__c, Field70__c, Field69__c, Field68__c, Field67__c, Field66__c, Field65__c, Field64__c,
			      Field63__c, Field62__c, Field61__c, Field60__c, Field59__c, Field58__c, Field57__c, Field56__c,
			      Field55__c, Field54__c, Field53__c, Field52__c, Field51__c, Field50__c, Field49__c, Field48__c,
			      Field45__c, Field44__c, Field43__c, Field42__c, Field40__c, Field39__c, Field159__c, Field158__c,
			      Field157__c, Field156__c, Field155__c, Field154__c, Field152__c, Field151__c, Field150__c,
			      Field149__c, Field148__c, Field147__c, Field146__c, Field145__c, Field143__c, Field142__c,
			      Field141__c, Field140__c, Field139__c, Field138__c, Field137__c, Field136__c, Field135__c,
			      Field134__c, Field133__c, Field132__c, Field131__c, Field130__c, Field129__c, Field128__c,
			      Field127__c, Field126__c, Field125__c, Field124__c, Field123__c, Field122__c, Field121__c,
			      Field120__c, Field119__c, Field118__c, Field117__c, Field116__c, Field115__c, Field114__c,
			      Field113__c, Field112__c, Field111__c, Field110__c, Field109__c, Field108__c, Field107__c,
			      Field106__c, Field105__c, Field104__c, Field103__c, Field102__c, Field101__c, Field100__c,
			      DivisionName__c, Name, SumSrvPriceIncTax__c, SumSrvPriceExcTax__c,AmoutSpecialPrice__c,
			      LastModifiedDate, LastModifiedById, Id, CreatedDate, CreatedById,
			      Relreserve__r.StayPersons__c,Relreserve__r.Rroom__r.Name,Relreserve__r.Rroom__c,TaxRate__c
			// 会計日時設定される場合、該当会計は自動バッチ処理対象外
			from AccountAcount__c where frs__c = :rsvAccId And Field53__c = null]) {
        	accAcountMap.put(item.Id, item);
        	if (taxRate == 0) taxRate = CommUtils.nullToZero(item.TaxRate__c);
        }
        // 処理対象データがない場合、処理終了
       	if (accAcountMap.isEmpty()) {
       		//売上計算処理済。
       		addInfMessage(Label.MSG_036_0044);
       		return;
       	}
       	
        // 会計支払情報を取得する
        Map<Id, List<TTend__c>> ttendMap = new Map<Id, List<TTend__c>>();
        // 会計支払データを取得[同じ売上、有効な会計に、会計支払情報を取得する]
        for(TTend__c item: [select Field19__c, Field20__c, Field21__c,Field1__c,OutSideAccount__c,Field2__c,Field1__r.Relreserve__r.Field315__c from TTend__c where RelAccount__c = :rsvAccId And Field1__c in :accAcountMap.keySet()]) {
        	if (!ttendMap.containsKey(item.Field1__c)) ttendMap.put(item.Field1__c, new List<TTend__c>());
        	ttendMap.get(item.Field1__c).add(item);
        }

        // 会計明細情報を取得する
        Map<Id, List<Tran1__c>> tranMap = new Map<Id, List<Tran1__c>>();
        // 詳細仕様： 請求書非表示(InvoiceNoShowFlg__c) AND 前受付　AND　有効な会計ID　の場合、統計対象外になる
        //          単価(Field20__c)
        //          数量(Field40__c/Field21__c)
        //          消費税(TaxRate__c)
        //          サービス料(ServiceRate__c) xx%方式
        //          特別税(SpecialTax__c)
        //  Where   商品処理種別　!= 前受け金 AND 請求書非表示(InvoiceNoShowFlg__c) AND 売上ID一致　AND　会計IDは有効な会計ID
        //  下記処理詳細：　処理対象の会計明細を取得して、
        //  取得する会計明細の会計支払データ件数は1件以上が存在する場合、処理対象外→既に処理済みの会計情報
        //  会計情報単位で、会計明細Groupする
        //  2013/11/12 親会計明細情報は計算対象外に変更対応
        for (Tran1__c item : [select UnitPriceDefKbCal__c, Id, Field1__c, ActionType__c, InvoiceNoShowFlg__c, Field20__c, Field21__c, Field40__c, TaxRate__c, ServiceRate__c, SpecialTax__c from Tran1__c
            where RelAccount__c = :rsvAccId And InvoiceNoShowFlg__c != true And ActionType__c != :CommConst.PROD_ACTION_TYPE_AR
            And ParentTran1Ref__c = null
            And Field1__c in :accAcountMap.keySet()
            Order By Field1__c]) {
            // 存在している会計支払データは2件以上（2件含め）場合、再計算を行わない
            //if (ttendRsCntMap.containsKey(item.Field1__c) && ttendRsCntMap.get(item.Field1__c) > 1) continue;
            // 会計情報から消費税率は０の場合、明細から消費税率を取得する、設定を行う
            if (taxRate == 0) taxRate = CommUtils.nullToZero(item.TaxRate__c);
        	// 会計単位で、金額計算を行う
        	// 会計情報は既に設定されている場合
        	if (tranMap.containsKey(item.Field1__c)) tranMap.get(item.Field1__c).add(item);
        	else {
        		List<Tran1__c> tranLst = new List<Tran1__c>();
        		tranLst.add(item);
        		tranMap.put(item.Field1__c, tranLst);
        	}
        }
        // 金額計算を行う:計算方法は会計編集画面：必ず同じルールで計算ください、修正する場合、必ず両方連動ください:
        // TODO:税抜の計算方法は：　商品　＊　数量総税込から　税抜を計算する、元システムに（数式）、先に商品の税込金額を計算後、この金額と数量で税抜く金額を計算する
		// 消費税計算を行うため、消費税値は０以上の商品金額を税込み金額を合計して、合計値にて、消費税を計算を行う
        // 計算用消費税率取得：会計日の消費税率を取得する「日付は：画面指定日　又は　スケジュールの実施日」
		//Decimal taxRate = CommUtils.getTaxRate(amoutDt);
		
        List<TTend__c> insTTend = new List<TTend__c>();
        List<TTend__c> updTTend = new List<TTend__c>();
        List<AccountAcount__c> updAccAcount = new List<AccountAcount__c>();
        // 会計単位で、会計明細情報を統計する
        for (Id acountId: tranMap.keyset()) {
        	// 1日１会計情報の会計総額金額計算

        	// 売上計4（税込）金額
            Decimal totalAmoutIncTax = 0;
        	// 売上計3（税抜）金額
        	Decimal totalAmoutExcTax = 0;
        	// サービス料金(税込)
        	Decimal totalAmoutSrvIncTax = 0;
        	// サービス料金(税抜)
        	Decimal totalAmoutSrvExcTax = 0;
        	// 宿泊税
        	Decimal totalAmoutSPTax = 0;
        	// 消費税ありの商品税込金額
        	Decimal amoutPriceIncTaxByTax = 0;
        	// 金額計算共通
        	// 2014/08/06   単価定義区分に従って、過去見積もり明細金額変更あり不具合修正 BEGIN
        	//CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo();
        	// 2014/08/06   単価定義区分に従って、過去見積もり明細金額変更あり不具合修正 END
        	// １会計:1会計支払：N会計明細
        	for (Tran1__c tranItem: tranMap.get(acountId)) {
        		// 金額計算を行う
        		// 2014/08/06   単価定義区分に従って、過去見積もり明細金額変更あり不具合修正 BEGIN
        		CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(tranItem.UnitPriceDefKbCal__c));
	            // 2014/08/06   単価定義区分に従って、過去見積もり明細金額変更あり不具合修正 END
	            // 単価と数量はNULLの場合、
	            Decimal unitPrice = CommUtils.nullToZero(tranItem.Field20__c);  // <-税金含め単価です
	            Decimal qty = CommUtils.nullToZero(tranItem.Field21__c);
/* 20121005修正を行う（商品単価多目意味機能対応） */
/*
	            // 合計金額(税込)
	            Decimal amoutIncTax = CommUtils.RoundProcess((unitPrice * qty), 0);
	            // 合計金額(税抜)※※※※（１円未満切り上げ）※※※※
	            Decimal amoutExcTax = CommUtils.CalExcTaxPrice(amoutIncTax, tranItem.TaxRate__c, 0, RoundingMode.CEILING);
	            // サービス料金（税込）
	            Decimal servicePriceIncTax = CommUtils.RoundProcess(amoutIncTax * (CommUtils.nullToZero(tranItem.ServiceRate__c) / 100), 0);
	            // 税込合計金額再計算を行う（商品合計金額＋サービス料金（税込）+特別税）
	            totalAmoutIncTax += amoutIncTax + servicePriceIncTax + tranItem.SpecialTax__c;*/
				// 金額計算を行う
				priceInfo.process(unitPrice , qty, tranItem.TaxRate__c, tranItem.ServiceRate__c);
	            // 合計金額(税抜)※※※※（１円未満切り上げ）※※※※[サビース料込(20130923)]
	            Decimal amoutExcTax = priceInfo.priceExcTax;
	            // サービス料金（税込）
	            Decimal servicePriceIncTax = priceInfo.priceService;
	            // 2012/10/30 宿泊税の処理追加を行う
	            /* 封印する
	            // 合計金額（税込:サービス込）
	            totalAmoutIncTax += priceInfo.priceIncTax;
	            // TODO:見積明細データは：直接DataloaderからIMP　OR　見積明細標準画面直接登録する場合、特別税の自動計算を行わない
	            // 設定されている商品は室料場合、宿泊税計算を行う
	            if (tranItem.ActionType__c == CommConst.PROD_ACTION_TYPE_RP) {
	                // 単価価額(税抜) + サビース料金(税抜)で計算結果を取得する[数量固定１で計算を行う]
	                Decimal roomPrice = priceInfo.unitPriceExcTax + priceInfo.unitPriceExcService;
	                // 特別税計算を行う
	                if (tranItem.SpecialTax__c == null) tranItem.SpecialTax__c = priceInfo.specialTaxCal(roomPrice) * qty;
	            }*/
	            // 合計金額(税込)[合計金額（税込:サービス込）＋特別税]
	            totalAmoutIncTax += priceInfo.priceIncTax + CommUtils.nullToZero(tranItem.SpecialTax__c);
	            // ----------- 会計へ設定用情報 ----------

	            // サービス料金(税込)
	            totalAmoutSrvIncTax += servicePriceIncTax;
	            // サービス料金(税抜)
	            totalAmoutSrvExcTax += priceInfo.priceServiceExcTax; //CommUtils.CalExcTaxPrice(servicePriceIncTax, tranItem.TaxRate__c, 0);
	            // 宿泊税[TODO]自動計算する場合、宿泊税の設定が必要
	            totalAmoutSPTax += CommUtils.nullToZero(tranItem.SpecialTax__c);
                // 商品販売金額（税抜き）
                totalAmoutExcTax += amoutExcTax; //+ totalAmoutSrvExcTax;
				// 商品税値は＞０の場合、金額合計を行う
				if (tranItem.TaxRate__c > 0 ) amoutPriceIncTaxByTax += priceInfo.priceIncTax;
        	} // End For
        	// 会計支払へ該当統計金額を計算を行う
        	List<TTend__c> ttendSobjLst = ttendMap.get(acountId);
        	// 複数会計支払い情報を存在する場合、処理対象外
        	//if (ttendSobjLst.size() > 1) continue;
        	TTend__c ttendSobj = (ttendSobjLst != null && ttendSobjLst.size() > 0) ? ttendSobjLst[0] : null;
        	// メディア毎消費税額計算を行う
        	// 2014/07/02 USD機能対応
            Integer pointLen = CommUtils.getPointLen();
        	//Decimal mediaTaxPrice = (amoutPriceIncTaxByTax > 0 ? CommUtils.RoundProcess(amoutPriceIncTaxByTax / (1 + taxRate / 100) * (taxRate / 100), 0) : 0);
        	Decimal mediaTaxPrice = (amoutPriceIncTaxByTax > 0 ? CommUtils.RoundProcess(amoutPriceIncTaxByTax / (1 + taxRate / 100) * (taxRate / 100), pointLen) : 0);

        	// 該当会計関連の開始払い存在チェック
        	if (ttendSobj != null){
//System.debug('--------- [STEP1] ----------');
//System.debug('ttendSobj:' + ttendSobj);
                    // *********** 合計金額 **********
                    // 預かり　金額[バッチ処理の自動計算する場合、預かり金額は０で設定する]
                    ttendSobj.Field19__c = String.valueOf(totalAmoutIncTax);
                    //ttendSobj.Field19__c = String.valueOf(0);
                    // 支払　金額
                    ttendSobj.Field20__c = String.valueOf(totalAmoutIncTax);
                    //ttendSobj.Field20__c = String.valueOf(0);
                    // メディア毎消費税額設定を行う
                    ttendSobj.Field25__c = String.valueOf(mediaTaxPrice);
                    //ttendSobj.Field25__c = String.valueOf(0);
                    // 更新リスト設定
                    updTTend.add(ttendSobj);
        	} else {
//System.debug('--------- [STEP2] ----------');
        		// 新規作成
        		ttendSobj = 
        			new TTend__c(
                    // *********** 初期値設定 **********
                    Field4__c = '1',
                    Field5__c = '1',
                    POSNo__c = CommUtils.getPosNoByComdefine(),
                    // 支払方法は現金で設定行う
                    Field2__c = CommConst.MEDIA_TYPE_CD_01,
                    Field3__c = CommConst.MEDIA_TYPE_01,
                    // *********** 合計金額 **********
                    // 預かり　金額[バッチ処理の自動計算する場合、預かり金額は０で設定する]
                    Field19__c = String.valueOf(totalAmoutIncTax),
                    //Field19__c = String.valueOf(0),
                    // 支払　金額
                    Field20__c = String.valueOf(totalAmoutIncTax),
                    //Field20__c = String.valueOf(0),
                    // メディア毎消費税額設定を行う
                    Field25__c = String.valueOf(mediaTaxPrice),
                    //Field25__c = String.valueOf(0),
                    // *********** 参照関係設定 **********
                    // 売上情報
                    RelAccount__c = rsvAccId,
                    // 会計情報
                    Field1__c = acountId
        		);
				String mediaType = ttendSobj.Field1__r.Relreserve__r.Field315__c;
	        	String[] typeInfo = BillSimpleHelp.getMediaCodeByLeadMediaType(mediaType);
	        	ttendSobj.Field2__c = typeInfo[0];
	        	ttendSobj.Field3__c = typeInfo[1];
	        	
        		insTTend.add(ttendSobj);
        	}
        	// 値引・割引券の場合、メディア毎消費税額は自動０に設定する
        	if(ttendSobj.Field2__c == CommConst.MEDIA_TYPE_CD_12) mediaTaxPrice = 0;
        	
        	// 会計情報へ設定を行う
        	AccountAcount__c oAcountSobj = accAcountMap.get(acountId);
        	// TODO $会計日付/$会計日時　設定必要
			// TODO：営業日付 ←　チェックイン日付で設定を行う　
			oAcountSobj.Field141__c = CommUtils.getBusinessDay();
			// 会計日時: TODO->原システム確認要
			oAcountSobj.Field53__c = DateTime.valueOf(String.valueOf(System.now())).format('yyyyMMddHHmmss');
			// 会計人数
			//2016/12/27 会計人數自動設定機能封印 BEGIN by zh
			if(AccounntStayPersonsAutoSetupFlg){
			oAcountSobj.Field57__c = String.valueOf(
										CommUtils.nullToZero(oAcountSobj.Field66__c) +
										CommUtils.nullToZero(oAcountSobj.Field67__c) +
										CommUtils.nullToZero(oAcountSobj.Field68__c));
			}
			//2016/12/27 会計人數自動設定機能封印 END by zh
	        // 売上計4（税込）金額:Field116__c  ->値引き存在と関係なし、実際の商品の売上を合計で設定する
	        oAcountSobj.Field116__c = String.valueOf(totalAmoutIncTax);
	        // 売上計3（税抜）金額:Field114__c[商品販売の金額税抜き＋サービス料金税抜き] // TODO:該当内容はBillInput__Ctrl差異あり
	        oAcountSobj.Field114__c = String.valueOf(totalAmoutExcTax);
	        // サービス料金(税込)
	        oAcountSobj.SumSrvPriceIncTax__c = totalAmoutSrvIncTax;
	        // サービス料金(税抜)
	        oAcountSobj.SumSrvPriceExcTax__c = totalAmoutSrvExcTax;
	        // 宿泊税
	        oAcountSobj.AmoutSpecialPrice__c = totalAmoutSPTax;
	        // 割引金額（税込）
	        oAcountSobj.Discount__c =
	           (ttendSobj.Field2__c == CommConst.MEDIA_TYPE_CD_12 ? totalAmoutIncTax : 0);
	        // Media消費税で会計の消費税項目に設定を行う
	        oAcountSobj.sumTax__c = mediaTaxPrice;
	        // 請求金額(TODO:請求金額は設定内容を再確認要)
	        oAcountSobj.Field126__c = String.valueOf(totalAmoutIncTax);
	        // 2017/01/25 店舗ごとの会計権限機能対応 BEGIN
	        oAcountSobj.OtherShopEditCheckFlg__c = true;
	        // 2017/01/25 店舗ごとの会計権限機能対応 END
			// 更新リストに格納する
	        updAccAcount.add(oAcountSobj);
        } // End For
        try {
/* 2015/02/09 バッチから支払情報自動作成を行わない対応*/
/* 2015/02/26 フラグにより、Layoutは１の場合、会計支払情報を作成する 
                         Layoutは２の場合、会計支払情報を作成しない */
            if (isOldBillModeFlg) {	
	        	if (!insTTend.isEmpty()) insert insTTend;
	        	if (!updTTend.isEmpty()) update updTTend;
            }
            
	        if (!updAccAcount.isEmpty()) update updAccAcount;
        } catch (Exception e) {
        	addErrMessage(e.getMessage());
        	return;
        }
        /**
        // 会計テーブル情報を更新を行う
        // 売上計4（税込）金額:Field116__c  ->値引き存在と関係なし、実際の商品の売上を合計で設定する
        oAcountSobj.Field116__c = String.valueOf(pTranFooter.amoutPriceIncTax);
        // 売上計3（税抜）金額:Field114__c
        oAcountSobj.Field114__c = String.valueOf(pTranFooter.amoutPriceExcTax);
        // サービス料金(税込)
        oAcountSobj.SumSrvPriceIncTax__c = pTranFooter.amoutServicePriceIncTax;
        // サービス料金(税抜)
        oAcountSobj.SumSrvPriceExcTax__c = pTranFooter.amoutServicePrice;
        // 宿泊税
        oAcountSobj.AmoutSpecialPrice__c = pTranFooter.amoutSpecialTax;
        // 割引金額（税込）
        oAcountSobj.Discount__c = pTttendFooter.amoutDiscountPrice;
        **/
		//ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
		//	'売上会計件数：' + String.valueOf(updAccAcount.size()) + '(件)  '));
		//calDayAmoutInfMsg = '処理会計件数：' + String.valueOf(updAccAcount.size()) + '(件)  ';
        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, '売上計算処理済。　　'));
        //売上計算処理済。
        addInfMessage(Label.MSG_036_0044);
	}
	// 2012/09/12 UpdateforSalesforcas処理追加
	public void UpdateforSalesforcast() {
		//documentExt doc = new documentExt();
		//doc.UpdateforSalesforcast();
		// 処理メッセージを初期化する
        message = '';
		// 売り上げ３が月分データを自動作成する
		// 当日から３ヶ月売上初期データを自動作成する
		DateTime cDate = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
		DateTime eDate = cDate.addDays(90);
		DateTime indexDate = cDate;
		Set<String> dateSet = new Set<String>();
		do {
			dateSet.add(indexDate.format('yyyyMMdd'));
			indexDate = indexDate.addDays(1);

		} while(indexDate < eDate);
		List<RsvAccount__c> rsvLst = [select id,name from RsvAccount__c where name in :dateSet];
		for (RsvAccount__c rsv: rsvLst) {
			// 既に存在データ、　SKIPする
			if (dateSet.contains(rsv.name)) dateSet.remove(rsv.name);
		}
		list<RsvAccount__c> insLst = new List<RsvAccount__c>();
		for (String strDate : dateSet) {
			RsvAccount__c newItem = new RsvAccount__c(name = strDate);
			insLst.add(newItem);
		}
		if (!insLst.isEmpty()) DataBase.upsert(insLst, RsvAccount__c.Name);
	}

}