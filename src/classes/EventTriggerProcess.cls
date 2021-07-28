/**
* 活動関連対応バッチ
* 2017/08/28
**/
public with sharing class EventTriggerProcess {

    // 関連先は取込先の場合、該当取込先変更に従って、子取込先情報を連動更新を行う
    public void updRelationAcccounts(Event[] newList, Event[] oldList, CommConst.TriggerMethod action){
        AccountMulitiSelectorCtrl ctrl = new AccountMulitiSelectorCtrl();
        ctrl.updRelationAccount(newList,oldList,action);
    }
    // 2019/05/31 008.行動からご予約の自動生成機能で、ご予約生成後に行動を変更（日時など）を変えた時にご予約は変更されないようです。by zy BEGIN
    // 最大天数チェック
    private Integer maxMiuteLen = 14 * 24 * 60;
    // 2019/05/31 008.行動からご予約の自動生成機能で、ご予約生成後に行動を変更（日時など）を変えた時にご予約は変更されないようです。by zy END
    // 
    public void updAutoUpdDatetime(Event[] newList, Event[] oldList, CommConst.TriggerMethod action){
       // 2019/05/31 008.行動からご予約の自動生成機能で、ご予約生成後に行動を変更（日時など）を変えた時にご予約は変更されないようです。by zy BEGIN
       // 最大天数チェック
       // Integer maxMiuteLen = 14 * 24 * 60;
       // 2019/05/31 008.行動からご予約の自動生成機能で、ご予約生成後に行動を変更（日時など）を変えた時にご予約は変更されないようです。by zy END
       // 2019/03/15 変更履歴機能追加 by CXW BEGIN
       Map<Id,Event> eventMap = new Map<Id,Event>();
       // 2019/03/15 変更履歴機能追加 by CXW END
       for (Integer i = 0 ; i < newList.size() ;i++) {
       		if (oldList.size() > i) {
       			Event oldEvent = oldList[i];
       			Event newEvent = newList[i];
       			if (oldEvent != null) {
       				// 标准页面操作
       				if (oldEvent.CustomEventFlag__c == newEvent.CustomEventFlag__c){
                integer durMinutes = null;
       					Datetime endDt = newEvent.EndDateTime;
       					// 正常場合
						    if (newEvent.ActivityDateTime != null) {
                  // 时间段整体移动
                  endDt = newEvent.ActivityDateTime.addMinutes(newEvent.DurationInMinutes);
						    //終日行動
						    } else {
                  Datetime activeDate = CommUtils.convertDatetime(newEvent.ActivityDate, '00:00');
                  //
                  endDt = activeDate.addMinutes(newEvent.DurationInMinutes);
						    }
                // 2019/05/31 008.行動からご予約の自動生成機能で、ご予約生成後に行動を変更（日時など）を変えた時にご予約は変更されないようです。by zy BEGIN
						    newEvent.EndDateTime__c = null;
                // 2019/05/31 008.行動からご予約の自動生成機能で、ご予約生成後に行動を変更（日時など）を変えた時にご予約は変更されないようです。by zy END
	       			// マルチタスクとプロジェックト動作
       				} else {
       					// 開始時刻変更の場合、終了日時自動変更
						// レピータの以外
						integer durMinutes = null;
						// 正常場合
						if (newEvent.ActivityDateTime != null) {
							// 開始と終了変更の場合
							if (newEvent.EndDateTime__c != null) {
								durMinutes = CommUtils.nullToIntZero((newEvent.EndDateTime__c.getTime() - newEvent.ActivityDateTime.getTime())/ (60 *1000));
							// 时间段整体移动
							} else if (oldEvent.EndDateTime__c != null) {
								durMinutes = CommUtils.nullToIntZero((oldEvent.EndDateTime__c.getTime() - oldEvent.ActivityDateTime.getTime())/ (60 *1000));
								newEvent.EndDateTime__c = newEvent.ActivityDateTime.addMinutes(durMinutes);
							}
						//終日行動
						} else if (newEvent.ActivityDate != null){
							// 開始と終了変更の場合
							if (newEvent.EndDateTime__c != null) {
								durMinutes = CommUtils.nullToIntZero((newEvent.EndDateTime__c.getTime() - newEvent.startdatetime.getTime())/ (60 *1000));
							// 时间段整体移动
							} else {
								newEvent.EndDateTime__c = newEvent.startdatetime.addMinutes(newEvent.DurationInMinutes);
							}
						}
						if (durMinutes != null) {
              // 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy BEGIN
              if (durMinutes > maxMiuteLen) {
                newEvent.DurationInMinutes = maxMiuteLen;
                newEvent.EndDateTime = newEvent.startdatetime.addMinutes(newEvent.DurationInMinutes);
              } else {
                newEvent.DurationInMinutes = durMinutes;
                newEvent.EndDateTime = newEvent.startdatetime.addMinutes(newEvent.DurationInMinutes);
              }
              // 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy END
						}
						//終日行動->正常行動
						if (newEvent.IsAllDayEvent) {
							// 終日行動解除
							newEvent.IsAllDayEvent = false;
							// 時間必要
							newEvent.ActivityDateTime = newEvent.startdatetime;
						}
       				}
       			}
       			// 2019/03/15 変更履歴機能追加 by CXW BEGIN
	       		if (newEvent.ProjectFlag__c) eventMap.put(newEvent.id,newEvent);
	       		// 2019/03/15 変更履歴機能追加 by CXW END
       		}
       }
       // 2019/03/15 変更履歴機能追加 by CXW BEGIN
       // 2019/09/15 Security Check BY zyz BEGIN
       List<String> chkFieldsLst = new List<String>{'userref__c','title__c','startdt__c','enddt__c','comment__c'};
       Map<String,Schema.SObjectField> mm = Schema.SObjectType.ProjectDetail__c.fields.getMap();
       if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
       	return ;
       }
       // 2019/09/15 Security Check BY zyz END
       if (!eventMap.isEmpty()) {
   			List<ProjectDetail__c> upds = new List<ProjectDetail__c>();
        // 2020/10/31 担当者を複数設定できるように by zy BEGIN
        Map<String,ProjectDetail__c> userKeySet = new Map<String,ProjectDetail__c>();
   			for (ProjectDetail__c pd : [select id,Title__c,StartDt__c,Comment__c,EndDt__c,UserRef__c,taskId__c,userRefs__c from ProjectDetail__c where TaskId__c in :eventMap.keySet()]) {
        // 2020/10/31 担当者を複数設定できるように by zy END
   				Event newEvent = eventMap.get(pd.taskId__c);
   				boolean isUpdFlag = false;
   				if (newEvent.subject != pd.Title__c) {
   					pd.Title__c = newEvent.subject;
   					isUpdFlag = true;
   				}
   				if (newEvent.startdatetime != pd.StartDt__c) {
   					pd.StartDt__c = newEvent.startdatetime;
   					isUpdFlag = true;
   				}
          // 2020/10/30 8701 bug fixed by zy BEGIN
          Datetime endDate = newEvent.EndDateTime__c == null ? newEvent.EndDateTime : newEvent.EndDateTime__c;
   				if (endDate != pd.EndDt__c) {
   					pd.EndDt__c = endDate;
   					isUpdFlag = true;
   				}
          // 2020/10/30 8701 bug fixed by zy END
   				if (newEvent.OwnerId != pd.UserRef__c) {
   					pd.UserRef__c = newEvent.OwnerId;
   					isUpdFlag = true;
   				}
   				if (newEvent.Description != pd.Comment__c) {
   					pd.Comment__c = newEvent.Description;
   					isUpdFlag = true;
   				}
				  // 2020/10/31 担当者を複数設定できるように by zy BEGIN
   				if (isUpdFlag) {
             if (!CommUtils.isBlank(pd.userRefs__c)) {
              for (String userId : CommUtils.nulltoBlank(pd.UserRefs__c).split(',')){
                if (CommUtils.isBLank(userId)) continue;
                userKeySet.put(String.join(new List<String>{userId,pd.id},'_'),pd);
              }
            }
            upds.add(pd);
          }
          // 2020/10/31 担当者を複数設定できるように by zy END
   			}
   			if (!upds.isEmpty()) update upds;
        // 2020/10/31 担当者を複数設定できるように by zy BEGIN
        if (!userKeySet.isEmpty()) {
          List<Event> evts = new List<Event>();
          // 関連複数担当者行動取得
          for (event evt : [select id,subject,startdatetime,EndDateTime,EndDateTime__c,Description,MutliUserDetail__c,OwnerId,CustomEventFlag__c from event where MutliUserDetail__c in :userKeySet.keySet()]){
            // 関連複数担当者
            if (userKeySet.containsKey(evt.MutliUserDetail__c)) {
              ProjectDetail__c pd = userKeySet.get(evt.MutliUserDetail__c);
              // 件名
              evt.subject = pd.Title__c;
              // 開始
              evt.startdatetime = pd.StartDt__c;
              // 終了
              evt.EndDateTime__c = pd.EndDt__c;
              // 終了
              evt.EndDateTime = CommUtils.eventSafeEndDateTm(pd.StartDt__c,pd.EndDt__c);
              // メモ
              evt.Description = pd.Comment__c;
              // 更新可能
              evt.CustomEventFlag__c = !evt.CustomEventFlag__c;
              evts.add(evt);
            }
          }
          if (!evts.isEMpty()) update evts;
        }
        // 2020/10/31 担当者を複数設定できるように by zy END
   		}
    }
    // 2019/03/15 変更履歴機能追加 by CXW END
    // 2019/04/15 改善要望：活動から予約の作成 by zy BEGIN
    // 新規関連関係
    public void insertRelationRoom(Event[] newList, Event[] oldList, CommConst.TriggerMethod action){
      // 2019/09/15 Security Check BY zyz BEGIN
      List<String> chkFieldsLst = new List<String>{'field3__c','recordtypeid','rroom__c','relcontact__c','staypersons__c','reserveddate__c','name',
      												'field4__c','eventid__c','eventflg__c','entrytime__c','departure__c','comment3__c'};
      Map<String,Schema.SObjectField> mm = Schema.SObjectType.Lead__c.fields.getMap();
      if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
      	return ;
      }
      // 2019/09/15 Security Check BY zyz END
      // でファルトお客様
      Contact contact = CommLogicProcess.getOrInsertTempContact();
      String recordType = CommLogicProcess.getLeadBookingRecType();
      List<Lead__c> leads = new List<Lead__c>();
      Map<Id,Event> leadMap = new Map<Id,Event>();
      // 関連予約取得
      for (integer i = 0 ; i < newList.size() ; i++) {
        Event oldEvent = oldList != null ? oldList[i] : null;
        Event newEvent = newList[i];
        // 2019/05/31 008.行動からご予約の自動生成機能で、ご予約生成後に行動を変更（日時など）を変えた時にご予約は変更されないようです。by zy BEGIN
        // if (newEvent.RoomRef__c != null && newEvent.whoId == null) newEvent.addError('お部屋設定の場合、任命先設定必要です');
        // 2019/05/31 008.行動からご予約の自動生成機能で、ご予約生成後に行動を変更（日時など）を変えた時にご予約は変更されないようです。by zy END
        // 関連変更
        if (newEvent.RoomRef__c != null && !newEvent.lockflag__c){
          leads.add(converEventToLead(newEvent,recordType));
        // 予約からの場合
        } else if (newEvent.lockflag__c && newEvent.leadRef__c != null) {
          // 予約対応関係作成
          leadMap.put(newEvent.leadRef__c,newEvent);
        }
      }
      // 関連予約作成
      if (!leads.isEmpty()) {
       List<Database.UpsertResult> subRs = Database.upsert(leads,false);
       for(Integer index = 0; index < subRs.size(); index++) {
          if(!subRs[index].isSuccess()) {
              newList[index].addError(CommUtils.getFieldValidationMessage(subRs[index].getErrors()[0].getMessage()));
          }
        }
      }
      // 2019/09/15 Security Check BY zyz BEGIN
      List<String> chksobFieldsLst = new List<String>{'eventid__c'};
      Map<String,Schema.SObjectField> insm = Schema.SObjectType.Lead__c.fields.getMap();
      if (!CommSecurityUtils.isCanUpsertable(chksobFieldsLst, insm)) {
      	return ;
      }
      // 2019/09/15 Security Check BY zyz END
      // 予約対応関係あり
      if (!leadMap.isEmpty()) {
        // 行動ID設定
        List<Lead__c> updLeads = new LIst<Lead__c>();
        for (Lead__c lead : [select id,eventId__c from lead__c where id =:leadMap.keySet()]){
          // 指定の予約の行動ID未設定
          if (CommUtils.isBlank(lead.eventId__c)) {
            Event evt = leadMap.get(lead.id);
            lead.EventId__c = evt.id;
            updLeads.add(lead);
          }
        }
        if(!updLeads.isEmpty()) update updLeads;
      }
    }
    // 関連予約指定場所設定
    public void updRelationRoom(Event[] newList, Event[] oldList, CommConst.TriggerMethod action){
      // 部屋設定行動
      Set<Id> eventSet = new Set<Id>();
      List<Lead__c> leads = new List<Lead__c>();
      // 2019/09/15 Security Check BY zyz BEGIN
      List<String> chkinFieldLst = new List<String>{'field3__c','recordtypeid','rroom__c','relcontact__c','staypersons__c','reserveddate__c','name','field4__c',
      												'eventid__c','eventflg__c','entrytime__c','departure__c','comment3__c'};
      Map<String,Schema.SObjectField> insmm = Schema.SObjectType.Lead__c.fields.getMap();
      if (!CommSecurityUtils.isCanUpsertable(chkinFieldLst, insmm)) {
      	return ;
      }
      // 2019/09/15 Security Check BY zyz END
      String recordType = CommLogicProcess.getLeadBookingRecType();
      // 2019/05/31 008.行動からご予約の自動生成機能で、ご予約生成後に行動を変更（日時など）を変えた時にご予約は変更されないようです。by zy BEGIN
      // 予約集合
      Map<String,Event> leadMap = new Map<String,Event>();
      // 2019/05/31 008.行動からご予約の自動生成機能で、ご予約生成後に行動を変更（日時など）を変えた時にご予約は変更されないようです。by zy END
      // 関連予約取得
      for (integer i = 0 ; i < newList.size() ; i++) {
        Event oldEvent = oldList != null ? oldList[i] : null;
        Event newEvent = newList[i];
        // 2019/05/31 008.行動からご予約の自動生成機能で、ご予約生成後に行動を変更（日時など）を変えた時にご予約は変更されないようです。by zy BEGIN
        // if (newEvent.RoomRef__c != null && newEvent.whoId == null) newEvent.addError('お部屋設定の場合、任命先設定必要です');
        // 2019/05/31 008.行動からご予約の自動生成機能で、ご予約生成後に行動を変更（日時など）を変えた時にご予約は変更されないようです。by zy END
        // 関連変更
        boolean isChangeFlag = oldEvent == null || oldEvent.RoomRef__c != newEvent.RoomRef__c;
        // 部屋変更の場合
        if (isChangeFlag){
          // 2019/05/31 008.行動からご予約の自動生成機能で、ご予約生成後に行動を変更（日時など）を変えた時にご予約は変更されないようです。by zy BEGIN
          // 予約存在
          //if (!CommUtils.isBlank(newEvent.leadRef__c)) leads.add(new lead__c(id = newEvent.leadRef__c,Rroom__c = newEvent.RoomRef__c,eventId__c = newEvent.id));
          // 予約不存在
          if (CommUtils.isBlank(newEvent.leadRef__c)) leads.add(converEventToLead(newEvent,recordType));
				}
        // 予約存在
        if (!CommUtils.isBlank(newEvent.leadRef__c)) {
          leadMap.put(newEvent.leadRef__c,newEvent);
        }
      }
      if (!leadMap.isEmpty()) {
        // 行動の予約取得
        for (Lead__c lead : [select id,name,entryTime__c,field4__c,Departure__c,field3__c,Rroom__c,relcontact__c from Lead__c where id=:leadMap.keySet()]){
          // 行動あり
          if (leadMap.containsKey(lead.id)) {
            // 該当行動
            Event evt = leadMap.get(lead.id);
            // 関連予約字段チェック
            Lead__c updLead = checkUpdLead(evt,lead);
            if (updLead != null) leads.add(updLead);
          }
        }
      }
      // 2019/05/31 008.行動からご予約の自動生成機能で、ご予約生成後に行動を変更（日時など）を変えた時にご予約は変更されないようです。by zy END
      // 関連予約作成
      if (!leads.isEmpty()) upsert leads;
    }
    // 関連予約削除機能
    public void delRelationLead(Event[] newList, Event[] oldList, CommConst.TriggerMethod action){
      // 2019/09/15 Security Check BY zyz BEGIN
      List<String> chkFieldsLst = new List<String>{'eventid__c','eventflg__c','reservedstatus__c'};
      Map<String,Schema.SObjectField> mm = Schema.SObjectType.Lead__c.fields.getMap();
      if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
      	return ;
      }
      // 2019/09/15 Security Check BY zyz END
      List<Lead__c> delLeads = new List<Lead__c>();
      Set<id> leadSet = new Set<Id>();
      for (integer i = 0; i < oldList.size() ; i++) {
        Event nw = oldList[i];
        if (!CommUtils.isBlank(nw.leadRef__c)) leadSet.add(nw.leadRef__c);
      }
      if (!leadSet.isEmpty()) {
        for(Lead__c lead : [select id,ReservedStatus__c from lead__c where id = :leadSet]) {
          if (lead.ReservedStatus__c != CommConst.LEAD_ST_CANCEL) {
            lead.ReservedStatus__c = CommConst.LEAD_ST_CANCEL;
          }
          lead.EventId__c = null;
          lead.EventFlg__c = false;
          delLeads.add(lead);
      }
      if (!delLeads.isEmpty()) update delLeads;
      }
    }
    private Lead__c converEventToLead(Event newEvent,String recordType){
      lead__c lead = new Lead__c();
      lead.relcontact__c = newEvent.WhoId;
      // contact.id;
      lead.ReservedDate__c = system.now();
      // 予約のレコードタイプ
      lead.RecordTypeId = recordType;
      lead.eventId__c = newEvent.id;
      lead.entryTime__c = newEvent.StartDateTime;
      lead.field4__c = newEvent.StartDateTime.format('HH:mm');
      lead.Departure__c = newEvent.EndDateTime;
      lead.field3__c = newEvent.EndDateTime.format('HH:mm');
      lead.name = newEvent.Subject;
      lead.Comment3__c = newEvent.Description;
      lead.StayPersons__c = CommConst.getBookingPeopleDef();
      // 行動作成
      lead.EventFlg__c = true;
      lead.Rroom__c = newEvent.RoomRef__c;
      return lead;
    }
  // 2019/04/15 改善要望：活動から予約の作成 by zy END
  // 2019/05/31 008.行動からご予約の自動生成機能で、ご予約生成後に行動を変更（日時など）を変えた時にご予約は変更されないようです。by zy BEGIN
  // お客様IDの
  private String contactPreFix = Contact.sObjectType.getDescribe().getKeyPrefix();
  // チェック行動対応予約字段一致
  private Lead__c checkUpdLead(Event evt,Lead__c newLead){
    // 結果予約
    Lead__c lead = null;
    // 部屋チェック
    if (evt.RoomRef__c != newLead.Rroom__c) {
      // 初期化
      if (lead == null) lead = new Lead__c(id = newLead.id);
      // 部屋設定
      lead.Rroom__c = evt.RoomRef__c;
    }
    // 開始 
    Datetime startDt = CommUtils.convertDatetime(newLead.entryTime__c.date(), newLead.field4__c);
    // 終了
    Datetime endDt = CommUtils.convertDatetime(newLead.Departure__c.date(), newLead.field3__c);
    // 開始時間と到着日チェック
    if (evt.StartDateTime != startDt) {
      // 初期化
      if (lead == null) lead = new Lead__c(id = newLead.id);
      // 到着日設定
      lead.entryTime__c = evt.StartDateTime;
      // 到着時間設定
      lead.Field4__c = evt.StartDateTime.format('HH:mm');
    }
    // 終了時間と出発日チェック
    if (evt.EndDateTime != endDt) {
      // 初期化
      if (lead == null) lead = new Lead__c(id = newLead.id);
      // 出発日設定
      lead.Departure__c = evt.EndDateTime;
      // 出発時間設定
      lead.field3__c = evt.EndDateTime.format('HH:mm');
    }
    // 件名と予約名チェック
    if (evt.Subject != newLead.name) {
      // 初期化
      if (lead == null) lead = new Lead__c(id = newLead.id);
      // 予約名設定
      lead.name = evt.Subject;
    }
    // お客様チェック
    if (evt.WhoId != newLead.relcontact__c && CommUtils.nullToBlank(evt.WhoId).startsWith(contactPreFix)) {
      // 初期化
      if (lead == null) lead = new Lead__c(id = newLead.id);
      // お客様設定
      lead.relcontact__c = evt.WhoId;
    }
    return lead;
  }
  // 2019/05/31 008.行動からご予約の自動生成機能で、ご予約生成後に行動を変更（日時など）を変えた時にご予約は変更されないようです。by zy END
  // 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy BEGIN
  // 超出14日のタスク処理
  public void updateChildEvent(Event[] newList, Event[] oldList, CommConst.TriggerMethod action){
    // 2019/09/15 Security Check BY zyz BEGIN
    List<String> chkFieldsLst = new List<String>{'lockflag__c','enddatetime__c','enddatetime','durationinminutes','activitydatetime','startdatetime',
    											'eventindex__c'};
    Map<String,Schema.SObjectField> mm = Schema.SObjectType.Event.fields.getMap();
    if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
    	return ;
    }
    // 2019/09/15 Security Check BY zyz END
    // 変更行動リスト
    List<Event> chgEvents = new List<Event>();
    // 同じ行動インデクス集合
    Map<String,Event> sameKeyEvts = new Map<String,Event>();
    // トリガー既存行動集合
    Set<String> useEvent = new Set<String>();
    // 同じ行動インデクス時間以外の変更集合
    Map<String,Event> updKeyEvt = new Map<String,Event>();
    // 行動新規の場合
    if(action == CommConst.TriggerMethod.IsInsert) {
      // 最新状態処理
      for (Integer i = 0 ; i < newList.size() ;i++) {
        // 更新後
        Event newEvent = newList[i];
        if (newEvent.EndDateTime__c != null) {
          // 変更時間範囲
          integer durMinutes = CommUtils.nullToIntZero((newEvent.EndDateTime__c.getTime() - newEvent.startdatetime.getTime())/ (60 *1000));
          if (durMinutes != null) {
            // 超出の場合
            if (durMinutes > maxMiuteLen) {
              // 14日設定
              newEvent.DurationInMinutes = maxMiuteLen;
              newEvent.EndDateTime = newEvent.startdatetime.addMinutes(newEvent.DurationInMinutes);
              // 自動作成のkey設定
              if (CommUtils.isBlank(newEvent.EventIndex__c)) chgEvents.add(newEvent);
            } else {
              // 未超出行動時間設定                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
              newEvent.DurationInMinutes = durMinutes;
              newEvent.EndDateTime = newEvent.startdatetime.addMinutes(newEvent.DurationInMinutes);
            }
          }
        }
      }
    } else if (action == CommConst.TriggerMethod.IsUpdate) {
      // 最新状態処理
      for (Integer i = 0 ; i < newList.size() ;i++) {
        // 更新後
        Event newEvent = newList[i];
        // 更新前
        Event oldEvent = oldList[i];
        // 新規の場合以外、変更の場合、自動作成データロック
        if (oldEvent != null && oldEvent.LockFlag__c != newEvent.LockFlag__c) continue;
        // 2020/10/31 担当者を複数設定できるように by zy BEGIN
        // // 标准页面変更不能
      	if (oldEvent != null && oldEvent.CustomEventFlag__c == newEvent.CustomEventFlag__c && newEvent.MutliUserDetail__c != null) 
            newEvent.addError('プロジェクト管理画面に変更してください');
      	// 2020/10/31 担当者を複数設定できるように by zy END
        // エラーメッセージ
        String taskMessage = newEvent.ProjectFlag__c ? 
                              '該当活動が直接編集できません、下記「<a target="_blank" href=\'' + '/apex/ps__StaffGantt?eventindex=' + newEvent.EventIndex__c + '\'>編集</a>」リンクをクリックして、プロジェクト画面でデータを更新してください。'
                              :'該当活動が直接編集できません、下記「<a target="_blank" href=\'' + '/apex/ps__StaffTask?owner=' + newEvent.OwnerId + '&dt=' + newEvent.StartDateTime.format('yyyyMMdd') + '\'>編集</a>」リンクをクリックして、マルチタスク画面でデータを更新してください。';  
        // 標準画面変更ロック、指定タスクチェック
        // タスク、プロジェクト画面変更の場合
        if (newEvent.EventIndex__c != null) {
          // タスク、プロジェクト画面変更の場合
          if (checkChgEventField(newEvent,oldEvent) &&  oldEvent.CustomEventFlag__c != newEvent.CustomEventFlag__c) {
            // 該当行動以外指定
            if (newEvent.id != null) useEvent.add(newEvent.id);
            // 同じ行動key
            sameKeyEvts.put(newEvent.EventIndex__c,newEvent);
          } else if (checkCanChgEventFeild(newEvent,oldEvent)) {
            // 該当行動以外指定
            if (newEvent.id != null) useEvent.add(newEvent.id);
            // 同じ行動key
            updKeyEvt.put(newEvent.EventIndex__c,newEvent);
          }
          // 変更の場合、不能更新の字段チェック
          else if (oldEvent == null 
              || checkChgEventField(newEvent,oldEvent)) {
            newEvent.addError(taskMessage, false);

          }
        } else if (newEvent.EndDateTime__c != null) {
          // 変更時間範囲
          integer durMinutes = CommUtils.nullToIntZero((newEvent.EndDateTime__c.getTime() - newEvent.startdatetime.getTime())/ (60 *1000));
          if (durMinutes != null) {
            // 超出の場合
            if (durMinutes > maxMiuteLen) {
              // 14日設定
              newEvent.DurationInMinutes = maxMiuteLen;
              newEvent.EndDateTime = newEvent.startdatetime.addMinutes(newEvent.DurationInMinutes);
              // 自動作成のkey設定
              if (CommUtils.isBlank(newEvent.EventIndex__c)) chgEvents.add(newEvent);
            } else {
              // 未超出行動時間設定                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
              newEvent.DurationInMinutes = durMinutes;
              newEvent.EndDateTime = newEvent.startdatetime.addMinutes(newEvent.DurationInMinutes);
            }
          }
        }
      }
    }
    // 新規あり
    if (!chgEvents.isEmpty()) {
      // 作成連結行動
      List<Event> insertEvts = new List<Event>();
      for (Event evt : chgEvents) {
        // 該当合計時間
        integer durMinutes = CommUtils.nullToIntZero((evt.EndDateTime__c.getTime() - evt.startdatetime.getTime())/ (60 *1000));
        // 超出14日の場合、鍵作成
        evt.EventIndex__c = CommUtils.getGUID();
        // 合計時間、同じ行動作成
        List<Event> nexEvts = changeSameEvent(evt,durMinutes);
        insertEvts.addAll(nexEvts);
      }
      // 新規行動
      if (!insertEvts.isEmpty()) insert insertEvts;
    }
    // 2019/09/15 Security Check BY zyz BEGIN
    if (!CommSecurityUtils.isDeleteable(Event.getSObjectType())) {
    	return;
    }
    // 2019/09/15 Security Check BY zyz END
    // 同じ行動keyあり
    if (!sameKeyEvts.isEmpty()) {
      // 同じ行動集合
      Map<String,List<Event>> sameKeyMap = new Map<String,List<Event>>();
      // 同じ行動keyと「トリガーの行動除外」
      for (Event evt : [select id,Subject ,Location,IsAllDayEvent,Description,WhatId,WhoId,StartDateTime,ActivityDateTime,EndDateTime,EndDateTime__c,LockFlag__c,DurationInMinutes,EventIndex__c,OwnerId from event where EventIndex__c = :sameKeyEvts.keySet() and id != :useEvent order by StartDateTime]){
        // 同じ行動集合作成
        if (!sameKeyMap.containsKey(evt.EventIndex__c)) sameKeyMap.put(evt.EventIndex__c,new List<event>());
        sameKeyMap.get(evt.EventIndex__c).add(evt);
      }
      // 削除のリスト
      List<Event> delEvt = new List<Event>();
      // 更新のリスト
      List<Event> updEvnt = new List<Event>();
      // 同じ行動keyチェック
      for (String eventIndex : sameKeyEvts.keySet()) {
        // 同じ行動取得
        List<Event> evts = new List<Event>();
        if (sameKeyMap.containsKey(eventIndex)) evts = sameKeyMap.get(eventIndex);
        // トリガー処理対象取得
        Event orgEvent = sameKeyEvts.get(eventIndex);
        // 変更元合計時間「マルチタスク、プロジェクタ管理ページ変更」
        integer totalMinutes = CommUtils.nullToIntZero((orgEvent.EndDateTime__c.getTime() - orgEvent.startdatetime.getTime())/ (60 *1000));
        // 合計時間下、自動作成行動リスト
        List<Event> newEvents = changeSameEvent(orgEvent,totalMinutes);
        // その他行動あり
        if(!newEvents.isEmpty()) {
          // 新規リストチェック
          for (integer i = 0 ; i < newEvents.size();i++) {
            // 自動作成行動
            Event evt = newEvents[i];
            // タスク存在の場合
            if (!evts.isEmpty()) {
              // 該当行動、時間変更
              Event orgEvt = evts[0];
              if (checkChgEventField(evt,orgEvt) || checkCanChgEventFeild(evt,orgEvt)){
                evt.id = orgEvt.id;
                evt.LockFlag__c = !orgEvt.LockFlag__c;
                evt.EndDateTime__c = null;
                // 削除不要
                evts.remove(0);
              }
            }
            // 更新、新規行動追加
            updEvnt.add(evt);
          }
        }
        // 既存の行動、変更後未含む、タスク削除
        if (!evts.isEmpty()) delEvt.addAll(evts);
        // 自動作成の行動なしの場合、同じ行動keyクリア
        if (newEvents.isEmpty()) sameKeyEvts.get(eventIndex).EventIndex__c = null;
      }
      // データ処理
      if (!updEvnt.isEMpty()) upsert updEvnt;
      if (!delEvt.isEmpty()) delete delEvt;
    }
    // 2019/09/15 Security Check BY zyz BEGIN
    List<String> chkFieldsTypeLst = new List<String>{'lockflag__c','whoid','whatid','location','description','ownerid','subject'};
    Map<String,Schema.SObjectField> mms = Schema.SObjectType.Event.fields.getMap();
    if (!CommSecurityUtils.isCanUpdateable(chkFieldsTypeLst, mms)) {
    	return ;
    }
    // 2019/09/15 Security Check BY zyz END
    if (!updKeyEvt.isEmpty()) {
      List<Event> chgEvt = new List<Event>();
      // 同じ行動keyと「トリガーの行動除外」
      for (Event newEvent : [select id,Subject ,eventIndex__c,Location,IsAllDayEvent,Description,WhatId,WhoId,LockFlag__c,OwnerId from event where EventIndex__c = :updKeyEvt.keySet() and id != :useEvent order by StartDateTime]){
        Event oldEvent = updKeyEvt.get(newEvent.eventIndex__c);
        if (newEvent.Subject != oldEvent.Subject) newEvent.Subject = oldEvent.Subject;
        if (newEvent.OwnerId != oldEvent.OwnerId) newEvent.OwnerId = oldEvent.OwnerId;
        if (newEvent.Description != oldEvent.Description) newEvent.Description = oldEvent.Description;
        if (newEvent.Location != oldEvent.Location) newEvent.Location = oldEvent.Location;
        if (newEvent.WhatId != oldEvent.WhatId) newEvent.WhatId = oldEvent.WhatId;
        if (newEvent.WhoId != oldEvent.WhoId) newEvent.WhoId = oldEvent.WhoId;
        newEvent.LockFlag__c = !newEvent.LockFlag__c;
        chgEvt.add(newEvent);
      }
      if (!chgEvt.isEmpty()) update chgEvt;
    }
  }
  // 合計時間下、自動作成行動リスト
  private List<Event> changeSameEvent(Event evt,Integer totalMinutes){
    // 該当行動本番時間範囲
    Integer selfMinute = CommUtils.nullToIntZero((evt.EndDateTime.getTime() - evt.startdatetime.getTime())/ (60 *1000));
    // 剰余の時間
    totalMinutes = totalMinutes - selfMinute;
    // 作成リスト
    List<Event> evts = new List<Event>();
    // 剰余の時間あり
    while(totalMinutes > 0) {
      // コピー元行動
      Event newEvt = evt.clone(false,false);
      // 開始時間設定
      newEvt.startdatetime = evt.EndDateTime;
      // 行動時間
      newEvt.ActivityDateTime = newEvt.startdatetime;
      // 剰余時間計算
      integer nextMinute = getNextTime(totalMinutes);
      totalMinutes -= nextMinute;
      // 時間設定
      newEvt.DurationInMinutes = nextMinute;
      // 終了時間
      newEvt.EndDateTime = newEvt.startdatetime.addMinutes(newEvt.DurationInMinutes);
      newEvt.EndDateTime__c = null;
      // 2020/10/31 担当者を複数設定できるように by zy BEGIN
      newEvt.ProjectFlag__c = false;
      newEvt.MutliUserDetail__c = null;
      // 2020/10/31 担当者を複数設定できるように by zy END
      evts.add(newEvt);
      // 時間保持用
      evt = newEvt.clone(false,false);
    }
    return evts;
  }
  private boolean checkChgEventField(Event newEvent,Event oldEvent){
    return (newEvent.EndDateTime != oldEvent.EndDateTime
        || newEvent.StartDateTime != oldEvent.StartDateTime
        || newEvent.DurationInMinutes != oldEvent.DurationInMinutes
        || newEvent.IsAllDayEvent != oldEvent.IsAllDayEvent
        // 2021/02/30 bug fixed by zy BEGIN
        || newEvent.EndDateTime__c != oldEvent.EndDateTime__c
        // 2021/02/30 bug fixed by zy END
    );
  }
  private boolean checkCanChgEventFeild(Event newEvent,Event oldEvent){
    return (newEvent.OwnerId != oldEvent.OwnerId
        || newEvent.Subject != oldEvent.Subject
        || newEvent.Description != oldEvent.Description
        || newEvent.Location != oldEvent.Location
        || newEvent.WhatId != oldEvent.WhatId
        || newEvent.WhoId != oldEvent.WhoId);
  }
  // 剰余時間計算
  private integer getNextTime(Integer nextMinute){
    // 超出時間チェック、超出14日、設定14日
    if (nextMinute > maxMiuteLen) return maxMiuteLen;
    else return nextMinute;
  }
  // 2019/06/14 003.プロジェクト管理上の日程が、個人のスケジュールに反映されません by zy END
}