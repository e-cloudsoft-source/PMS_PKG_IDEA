/**
* メール連携：外から連携する予約情報はSFへ連携する
* TA-手間いらず予約取込機能
* 2016/05/01 INIT
* 2016/06/10 子供料金プラン取り込み機能対応
* 2016/06/17 取り込みの見積明細の順番は調整対応（プランは一番上、その後、会計商品コード順昇順)
* 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応
* 2017/09/01 最大文字数をこえない問題回避対応
**/
public with sharing class EmailMessageToLeadSync {

    // 中継アプリの名
    private static final String APPNAME = 'EMAIL';//CommConst.BI_PROCESS_TYPE.TL.name(); 
    // 会計商品の商品コード作成する場合、前方数字：例：Pxxxxコードで自動採番を行う
    private static final String PLAN_PRD_PREX_NUM = 'P';
    // Default チェックアウト時間 
    // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
    //private static final Time defaultCheckinTime = CommConst.defCheckInTime;
    //private static final Time defaultCheckoutTime = CommConst.defCheckOtTime;
    //private static final String defaultCheckInTimeStr = (DateTime.newInstance(Date.today(), defaultCheckinTime)).format('HH:mm');
    //private static final String defaultCheckoutTimeStr = (DateTime.newInstance(Date.today(), defaultCheckoutTime)).format('HH:mm');
    private static Time defaultCheckinTime;
    private static Time defaultCheckoutTime;
    private static String defaultCheckInTimeStr;
    private static String defaultCheckoutTimeStr;
    // 2013/12/10 日帰到着時刻初期値
    //private static final String defaultDayUseCheckInTime = CommConst.DEF_DAYUSE_CHECKIN_TIME;
    private static String defaultDayUseCheckInTime;
    private static String defaultDayUseCheckOtTime;
    // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
    // 2014/11/20 店舗別プラン設定機能判断フラグ 
    private static final Boolean isPlanOfShopFlg = CommConst.APPOTION_BI_SHOPPLAN_FLG;
    // 2015/07/22 部屋自動割り当て
    private static Boolean autoAssingRoomFlg { get{ return CommDefine__c.getOrgDefaults().AdvancesReceivedChk__c; }}
    // 2015/10/01 店舗コード
    private String shopCd;
    // ログ出力機能
    public CommLogUtils mLogUtils{get; private set;}
    // 入湯税会計商品情報格納用
    private AccountMaster__c nyuuTouAcc;
    // サビース料会計商品情報格納用
    private AccountMaster__c serviceAcc;
    // 調整可能のプラン明細情報の格納
    private planDetailInfo planDetailInf;
    // 2015/12/11 予約取込機能改善（変更、キャンセル） BEGIN
    private Integer LEAD_CREATE_TIME_DIFF_INT = 60000;
    private String bookingDataId;
    // 2015/12/11 予約取込機能改善（変更、キャンセル） END
    // 2016/01/07 予約キャンセルの場合、キャンセル内容は本文メールに反映を行う BEGIN
    private static final Integer commentLength = Lead__c.Comment3__c.getDescribe().getLength();
    private static final Integer emailLength = Lead__c.email__c.getDescribe().getLength();
    // 2016/01/07 予約キャンセルの場合、キャンセル内容は本文メールに反映を行う END
    // 2017/09/01 最大文字数をこえない問題回避対応 BEGIN
    private static final Integer indexCommentLength = LeadIndex__c.Comment__c.getDescribe().getLength();
    // 2017/09/01 最大文字数をこえない問題回避対応 END
    public Map<String,Map<String,String>> defaultValueMap;
    /**
    * インスタント化
    **/
    public EmailMessageToLeadSync(EmailMessageToLeadProcess emailProcess) {
        mLogUtils = new CommLogUtils('EmailMessageToLeadSync',true);
        defaultValueMap = emailProcess.customerFieldMap;
    }
    /*
    * 外部から予約データ連携機能
    */
    public BI_EMAIL_SyncResult upsertEmail2LeadInfo(BI_EMAIL_SyncInfo bookingInfo,String shopCode) {
         // 2017/02/24 Field Security Check BEGIN
 		List<String> chkFields = new List<String>{'TravelAgencyBookingInsDateTime__c','StatusLst__c','DataClassification__c'};
 		Map<String,Schema.SObjectField> m = Schema.SObjectType.LeadIndex__c.fields.getMap();
 		if (!CommSecurityUtils.isCanUpdateable(chkFields, m)) {
 			return null;
 		}
 		// 2017/02/24 Field Security Check End
        mLogUtils.write_method_start('upsertEmail2LeadInfo');
        // 店舗コード
        shopCd = shopCode;
        // 変更、キャンセルする場合、予約取込するがどうか判断用フラグ:TRUEの場合、取込みを行う
        Boolean ucIsSyncFlg = EmailMessageToLeadHelp.getAppConfig(shopCd).ucactisSync;
        // 2015/12/11 予約取込機能改善（変更、キャンセル） BEGIN
        LEAD_CREATE_TIME_DIFF_INT = EmailMessageToLeadHelp.getCommConfig().mLeadTimeLimit;
        bookingDataId = APPNAME + '_' + bookingInfo.DataID;
        // 2015/12/11 予約取込機能改善（変更、キャンセル） END
        // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
        ShopInfoUtil.ShopLeadInfo shopInfo = ShopInfoUtil.getShopDefInfo(shopCd);
        defaultCheckinTime = shopInfo.defCheckInTime;
        defaultCheckoutTime = shopInfo.defCheckOtTime;
        defaultCheckInTimeStr = shopInfo.defCheckInTimeStr;
        defaultCheckoutTimeStr = shopInfo.defCheckOtTimeStr;
        defaultDayUseCheckInTime = shopInfo.defDayUseCheckInTimeStr;
        defaultDayUseCheckOtTime = shopInfo.defDayUseCheckOtTimeStr;
        // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
        // 既存の予約情報を格納する
        List<Lead__c> orgLeadLst = new List<Lead__c>();
        // 予約情報を更新を行う
System.debug(logginglevel.INFO,bookingInfo);
        BI_EMAIL_SyncResult rs = new BI_EMAIL_SyncResult();
        // DB操作を行う
  		Savepoint sp = Database.setSavepoint();
       	try {
	        // 変更、キャンセル連携処理の場合
	        if (bookingInfo.dmlAction == BI_EMAIL_DmlAction.UPD ||
	            bookingInfo.dmlAction == BI_EMAIL_DmlAction.CANCEL) {
	            // 予約管理ID[新たな予約グループが発生したときに新規発番]
	            String DataID = bookingInfo.DataID;
	            if(CommUtils.isBlank(DataID)){
	                rs.result = BI_EMAIL_Result.NG;
	                mLogUtils.write_method_end();
	                return rs;
	            }
	            mLogUtils.write_log('DataID::' + DataID);
	            // 既存の予約インデックス情報を取得する
	            List<LeadIndex__c> rslst = getExistLeadIndexByDataId(bookingInfo);
	            // 既存の予約情報がない場合
	            if (rslst.isEmpty()) {
	                // 変更の場合、新規作成を行う
	                if (bookingInfo.dmlAction == BI_EMAIL_DmlAction.UPD) {
	                    // 元の予約インデックスは何も処理を行わない
	                    mLogUtils.write_log('DataIDと一致するご予約情報はSalesforceからみつかりません。元のデータが更新対象外になる');
	                    
	                } 
	                // 次の変更後の新規処理を行う
	                else if (bookingInfo.dmlAction == BI_EMAIL_DmlAction.CANCEL) {
	                    mLogUtils.write_log('DataIDと一致するご予約情報はSalesforceからみつかりません。元のデータがキャンセル対象外になる');
	                    // 予約インデックスのみ作成して、XMLを格納する
	                    // DataIDが非存在する場合、単に該当XMLはSalesforceにアップロードを行う
	                    LeadIndex__c dumyIndex = new LeadIndex__c(ID__c = DataID,EventSource__c = bookingInfo.DataFrom,StatusLst__c = CommConst.LEAD_ST_CANCEL,APPNAME__c = APPNAME);
	                    insert dumyIndex;
	                    mLogUtils.write_log('該当キャンセルXMLファイルは下記予約インデックス['+dumyIndex.Id+'にアップロード済');
	                    rs.sfdcId = dumyIndex.Id;
	                    // キャンセルの場合、新規の予約インデックスデータのみ作成して、XMLを格納する
	                    rs.result = BI_EMAIL_Result.OK;
	                    mLogUtils.write_method_end();
	                    return rs;
	                }
	            } 
	            // 既存の予約関連情報が存在する場合
	            else {
	                // 変更時刻を設定する
	                LeadIndex__c leadIndex = rslst[0];
	                // 変更時刻情報を設定を行う
	                if (bookingInfo.dmlAction == BI_EMAIL_DmlAction.UPD) {
	                    leadIndex.TravelAgencyBookingUpdDateTime__c = DateTime.newInstance(bookingInfo.TravelAgencyBookingDate, bookingInfo.TravelAgencyBookingTime !=null?bookingInfo.TravelAgencyBookingTime: Time.newInstance(0,0,0,0) );
	                }
	                if (bookingInfo.dmlAction == BI_EMAIL_DmlAction.CANCEL) {
	                    leadIndex.TravelAgencyBookingDelDateTime__c = DateTime.newInstance(bookingInfo.TravelAgencyBookingDate != null ? bookingInfo.TravelAgencyBookingDate : system.today(), bookingInfo.TravelAgencyBookingTime !=null?bookingInfo.TravelAgencyBookingTime: Time.newInstance(0,0,0,0));
	                }
	                // 予約インデックスのデータ種別に更新を行う
	                leadIndex.DataClassification__c = bookingInfo.dmlAction.name();
	                // 変更、キャンセル連動対応の場合、予約インストールのステータスも取消を行う
	                if (ucIsSyncFlg && bookingInfo.dmlAction == BI_EMAIL_DmlAction.CANCEL) {
	                    leadIndex.StatusLst__c = CommConst.LEAD_ST_CANCEL;
	                }
	                update leadIndex;
	                // 変更、キャンセル情報を取込ない制御の場合
	                if (!ucIsSyncFlg) {
	                    mLogUtils.write_log('変更、キャンセルするため、予約取込処理対象外になる');
	                    rs.sfdcId = rslst[0].Id;
	                    rs.result = BI_EMAIL_Result.OK;
	                    mLogUtils.write_method_end();
	                    return rs;
	                }
	                // 既存の予約インデックス、予約インデックスSUB,予約情報へ変更、キャンセル処理を行う
	                // 既存の予約インデックスと関連の予約インスタントSUB情報を取得する
	                Set<Id> subLeadIds = new Set<Id>();
	                for(LeadIndex__c subIndex : [select id from LeadIndex__c where ParentLeadIndxRef__c =:leadIndex.id]){
	                    subLeadIds.add(subIndex.id);
	                }
	                // 予約はキャンセルされる場合
	                if (bookingInfo.dmlAction == BI_EMAIL_DmlAction.CANCEL) {
	        			// メール本文[7XXXXX]
	        			BI_EMAIL_RisaplBasic risaplBasic = bookingInfo.risaplsinformation.risaplsCommonInformation.risaplBasic;
	                	// 同じ予約インデックスを所属する予約情報は全部キャンセルを行う
		                //orgLeadLst = [  select id, ReservedStatus__c,Comment3__c,EventSource__c,email__c
		                orgLeadLst = [  select id, ReservedStatus__c,Comment3__c,RoomGroupNo__c,EntryTime__c,LeadIndexSubId__c,LeadIndexRef__c
	                							,email__c,Relcontact__c,Field2__c,EventSource__c,BookingDataID__c,Departure__c,CreatedDate 
	                							,Nights__c,PlanSycnFlag__c,LeadIndexRef__r.LeadName__c,Name,refTypeOfRooms__c,Rroom__c
		                                from Lead__c 
		                                where (LeadIndexRef__c = :leadIndex.id or LeadIndexSubId__c = :subLeadIds)
		                                And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG ];
		                
		                List<Lead__c> emailUpdLeadLst = filterTLImportData(orgLeadLst,bookingInfo,leadIndex,subLeadIds);
		                for (Lead__c orgLead : emailUpdLeadLst) {
		                	orgLead.email__c = CommLogUtils.removeOverLogString(risaplBasic.TelegramData + '\n' + CommUtils.nullToBlank(orgLead.email__c),emailLength);
		                }
	                } else if (bookingInfo.dmlAction == BI_EMAIL_DmlAction.UPD) {
		                 // 既存予約変更、キャンセル処理する場合、既存の予約情報を一回キャンセルを更新する
		                orgLeadLst = [  select id, ReservedStatus__c,Comment3__c,RoomGroupNo__c,EntryTime__c,LeadIndexSubId__c,LeadIndexRef__c
	                							,email__c,Relcontact__c,Field2__c,EventSource__c,BookingDataID__c,Departure__c,CreatedDate 
	                							,Nights__c,PlanSycnFlag__c,LeadIndexRef__r.LeadName__c,Name,refTypeOfRooms__c,Rroom__c
	                							,Field348__c
		                                from Lead__c 
		                                // 同じ予約インデックスに所属する　OR　
		                                where ((LeadIndexRef__c = :leadIndex.id or BookingDataID__c = :bookingDataId)
		                                		OR
		                                		(LeadIndexSubId__c = :subLeadIds and LeadIndexSubId__c != null))
		                                    And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 
		                                   // and LeadIndexSubId__c = :subLeadIds
		                                   // and LeadIndexSubId__c != null 
		                                // 同じ部屋、泊数順番で既存予約情報を取得する
		                                order by LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c,EntryTime__c];
		                	// 予約変更の場合、電文から作成の予約情報のみ変更処理を行う、その以外の予約情報は処理対象外になる
							orgLeadLst = filterTLImportData(orgLeadLst,bookingInfo,leadIndex,subLeadIds);
					}
	                //mLogUtils.write_log('orgLeadLst::' + orgLeadLst.size());
	                // アクセス権限制限するため、キャンセル処理する場合、削除から更新に変更する
	                for (Lead__c lead : orgLeadLst) {
	                    // 2015/10/15 Ver15.71以後、予約変更処理ロジック対応するため、下記設定ロジックを変更する BEGIN
	                    String cancelMessage = '<br/>' + System.now().format('yyyy/MM/dd HH:mm:ss:SSS')+' ';
	                    if (bookingInfo.dmlAction == BI_EMAIL_DmlAction.CANCEL) {
	                        cancelMessage += 'キャンセル対応';
	                        lead.EventSource__c = APPNAME + '_' + bookingInfo.DataID + '_' + DateTime.now().getTime();
	                        lead.ReservedStatus__c = CommConst.LEAD_ST_CANCEL;
	                    } else if (bookingInfo.dmlAction == BI_EMAIL_DmlAction.UPD) {
	                        cancelMessage += '予約変更対応';
	                    }
	                    // 2015/10/15 Ver15.71以後、予約変更処理ロジック対応するため、下記設定ロジックを変更する END
                        // 2017/09/01 最大文字数をこえない問題回避対応 BEGIN
	                    //lead.Comment3__c = CommUtils.nullToBlank(lead.Comment3__c) + cancelMessage;
	                    lead.Comment3__c = CommLogUtils.removeOverLogString(CommUtils.nullToBlank(lead.Comment3__c) + cancelMessage, commentLength);
	                    // 2017/09/01 最大文字数をこえない問題回避対応 END
	                }
	                // 2015/10/15 Ver15.71以後、予約変更処理ロジック対応するため、キャンセルのみ場合、既存予約情報をキャンセルする
	                if (bookingInfo.dmlAction == BI_EMAIL_DmlAction.CANCEL) {
                        // 2017/05/04 店舗ごとの予約・会計権限機能対応 BEGIN
					    CommLogicProcess logic = new CommLogicProcess();
						// 自動キャンセルされるデータのフラグはチェック対象外に設定する
						logic.preventShopAuthCheckSetup(orgLeadLst);
						// 2017/05/04 店舗ごとの予約・会計権限機能対応 END
	                    // 既存予約情報をキャンセル処理
	                    if (!orgLeadLst.isEmpty()) update orgLeadLst;
                        // 2017/05/04 店舗ごとの予約・会計権限機能対応 BEGIN
					  	logic.restoreShopAuthCheckSetup(orgLeadLst, true);
	  					// 2017/05/04 店舗ごとの予約・会計権限機能対応 END
	                    mLogUtils.write_log('既存予約情報('+orgLeadLst.size()+'件)をキャンセル済');
	                    // 処理結果を戻る
	                    rs.sfdcId = rslst[0].Id;
	                    rs.result = BI_EMAIL_Result.OK;
	                    mLogUtils.write_method_end();
	                    return rs;
	                }
	            }
	        }
	        // 2016/06/02 新規予約情報を重複取り込み回避対応（同じ予約番号が存在すると、新規取り込みなし、XMLのみコピーする） BEGIN
			else if(bookingInfo.dmlAction == BI_EMAIL_DmlAction.INS ){
	            String DataID = bookingInfo.DataID;
	            if(CommUtils.isBlank(DataID)){
	                rs.result = BI_EMAIL_Result.NG;
	                mLogUtils.write_method_end();
	                return rs;
	            }
if (!EmailMessageToLeadHelp.getCommConfig().bIsDebug) {
				List<LeadIndex__c> rslst = getExistLeadIndexByDataId(bookingInfo);
				if (!rslst.isEmpty()) {
	                if(bookingInfo.dmlAction == BI_EMAIL_DmlAction.INS){
	                	mLogUtils.write_log('該当データID[' + DataID + ']SalesforceID[' + rslst[0].Id + ']の予約情報は既に取込済ため、重複取込できません。');
	                    rs.sfdcId = rslst[0].Id;
	                    rs.result = BI_EMAIL_Result.OK;
	                    mLogUtils.write_method_end();
	                    return rs;
	                }
	        	 }
}
			}
	        // 2016/06/02 新規予約情報を重複取り込み回避対応（同じ予約番号が存在すると、新規取り込みなし、XMLのみコピーする） END
	        // 旅行会社情報の新規・更新を行う
	        List<Account> traveCompany = upsertTravelInfo(bookingInfo);
	        // 団体代表者の情報は顧客へ登録する
	        Contact pkuser = upsertContact(bookingInfo,orgLeadLst.isEmpty() ? null : orgLeadLst[0]);
	        // 予約インデックスオブジェクト
	        LeadIndex__c leadIndex = upsertLeadIndex(bookingInfo, pkuser, traveCompany);
	        // 予約データを作成する　
	        upsertTL2Lead(bookingInfo, leadIndex, pkuser, traveCompany,shopCode,orgLeadLst);
	        // 処理結果設定を行う
	        rs.sfdcId = leadIndex.Id;
	        rs.result = BI_EMAIL_Result.OK;
        } catch (CommException ex) {
            System.debug(ex.getMessage());
            rs.result = BI_EMAIL_Result.NG;
            rs.message = ex.getMessage();
            mLogUtils.write_error(ex.getMessage());
            Database.rollback(sp);
        } catch (Exception e) {
            mLogUtils.write_error(e.getMessage());
            rs.result = BI_EMAIL_Result.NG;
            rs.message = e.getMessage();
            Database.rollback(sp);
        }
        mLogUtils.write_method_end();
        return rs;
    }
    // 既存予約INDEX情報を取得する
    private List<LeadIndex__c> getExistLeadIndexByDataId(BI_EMAIL_SyncInfo bookingInfo) {
    	mLogUtils.write_method_start('getExistLeadIndexByDataId');
    	mLogUtils.write_log('bookingInfo.DataFrom:'+bookingInfo.DataFrom);
    	mLogUtils.write_log('bookingInfo.DataID:'+bookingInfo.DataID);
    	mLogUtils.write_method_end();
        return [select id,EntryDate__c,CreatedDate from LeadIndex__c where ID__c = :bookingInfo.DataID And EventSource__c = :bookingInfo.DataFrom And (APPNAME__c = :APPNAME OR APPNAME__c = null ) and StatusLst__c != :CommConst.LEAD_ST_CANCEL order by CreatedDate desc limit 1];
    }
    /**
    * 予約基本情報
    **/
    private LeadIndex__c upsertLeadIndex(BI_EMAIL_SyncInfo bookingInfo, Contact pkuser, List<Account> TraveCompany) {
         // 2017/02/24 Field Security Check BEGIN
 		List<String> chkFields = new List<String>{'TravelAgencyBookingInsDateTime__c','Comment__c','LeadName__c','Channel__c',
 												'LeadName__c','Channel__c','Rooms__c','contactRef__c','Nights__c','DepartureTime__c','Payment__c','TotalAccommodationCharge__c',
 												'MemberUserGendar__c','MemberUserDateOfBirth__c','MemberUserType__c','MemberUserID__c','MemberUserDep__c','MemberUserCorp__c','MemberUserAddr__c','MemberUserZip__c',
 												'MemberUserMailAddr__c','MemberUserTel__c','MemberUsePoint__c','MemberAddPoint__c','MemberUserKana__c','MemberUserName__c','DepartureDate__c','EntryTime__c','EntryDate__c',
 												'TravelLeadNo__c','ID__c','EventSource__c','DataClassification__c','APPNAME__c'};// 'MailSendComplete__c','MemberUserEmergencyPhoneNumber__c ',
		Map<String,Schema.SObjectField> m = Schema.SObjectType.LeadIndex__c.fields.getMap();
 		if (!CommSecurityUtils.isCanUpsertable(chkFields, m)) {
 			return null;
 		}
 		// 2017/02/24 Field Security Check End
        mLogUtils.write_method_start('upsertLeadIndex');
        List<LeadIndex__c> rslst = getExistLeadIndexByDataId(bookingInfo);
        boolean updFlag = bookingInfo.dmlAction == BI_EMAIL_DmlAction.UPD;
        // 初期化処理を行う
        LeadIndex__c leadIndex = (LeadIndex__c)getNewObjectByName(LeadIndex__c.sObjectType, null);//new LeadIndex__c();
        if(updFlag && !rslst.isEmpty()){
            leadIndex = rslst[0];
        }
        if(updFlag || bookingInfo.dmlAction == BI_EMAIL_DmlAction.INS) {
        	mLogUtils.write_log('updFlag:: ' + updFlag);
            // 新規データ作成を行う
            DateTime checkInDt = (bookingInfo.CheckInTime == null ? null : DateTime.newInstance(bookingInfo.CheckInDate, bookingInfo.CheckInTime));
            BI_EMAIL_Member member = bookingInfo.risaplsinformation.risaplsCommonInformation.member;
            // 2015/09/10 ADD BEGIN
            leadIndex.APPNAME__c = APPNAME;
            // 2015/09/10 ADD END
            leadIndex.DataClassification__c = bookingInfo.dmlAction.name();
            leadIndex.EventSource__c = bookingInfo.DataFrom;
            leadIndex.ID__c = bookingInfo.DataID;
            leadIndex.TravelLeadNo__c = bookingInfo.TravelAgencyBookingNumber;  // 2013/12/27 ADD
            leadIndex.EntryDate__c = bookingInfo.CheckInDate;
            leadIndex.EntryTime__c = checkInDt == null ? (bookingInfo.Nights == 0 ? defaultDayUseCheckInTime : defaultCheckInTimeStr) : checkInDt.format('HH:mm');
            leadIndex.DepartureDate__c = bookingInfo.CheckOutDate == null ? (bookingInfo.CheckInDate.addDays(bookingInfo.Nights)) : bookingInfo.CheckOutDate;
            // 2014/02/25 補足情報を追加する BEGIN
            if(member != null){
                leadIndex.MemberUserName__c = member.UserName;
                leadIndex.MemberUserKana__c = member.UserKana;
                leadIndex.MemberAddPoint__c = member.UserGivingPoints;
                leadIndex.MemberUsePoint__c = member.UserUsePoints;
                leadIndex.MemberUserTel__c = member.UserTel;    // 会員電話番号 
                leadIndex.MemberUserMailAddr__c = member.UserMailAddr;  // 会員Email 
                leadIndex.MemberUserZip__c = member.UserZip;    // 会員郵便番号 
                leadIndex.MemberUserAddr__c = member.UserAddr;  // 会員住所 
                leadIndex.MemberUserCorp__c = member.UserCorp;  // 会員会社 
                leadIndex.MemberUserDep__c = member.UserDep;    // 会員所属部署 
                leadIndex.MemberUserID__c = member.UserID;  // 会員番号 
                leadIndex.MemberUserType__c = member.UserType;  // 会員種別
                leadIndex.MemberUserDateOfBirth__c = member.UserDateOfBirth;    // 会員生年月日
                leadIndex.MemberUserGendar__c = (member.UserGendar == '0' 
                                                ? '男性' 
                                                : (member.UserGendar == '1' 
                                                    ? '女性' 
                                                    : (member.UserGendar == '2' ? '不明' : '' )));    // 会員性別 
                leadIndex.MemberUserEmergencyPhoneNumber__c = member.UserEmergencyPhoneNumber;  // 会員緊急連絡先番号(携帯等)
            }
            leadIndex.TotalAccommodationCharge__c = String.valueOf(bookingInfo.TotalAccommodationCharge);
            leadIndex.Payment__c = getLocalPaymentInfo(bookingInfo.Payment);
            // 2014/02/25 補足情報を追加する END
            // チェックアウト時間はDefault値設定を行う
            leadIndex.DepartureTime__c =    (   bookingInfo.CheckOutTime == null
                                                                    ? (bookingInfo.Nights == 0 
                                                                        // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
                                                                        //? (DateTime.newInstance(Date.today(), CommUtils.stringToTime(leadIndex.EntryTime__c).addHours(CommConst.DEF_DAYUSE_STAY_HOURS))).format('HH:mm') 
                                                                        ? ( (bookingInfo.CheckOutTime == null && bookingInfo.CheckInTime == null) 
                                                                           ? defaultDayUseCheckOtTime
                                                                           : (DateTime.newInstance(Date.today(), CommUtils.stringToTime(leadIndex.EntryTime__c).addHours(CommConst.DEF_DAYUSE_STAY_HOURS))).format('HH:mm') 
                                                                           )
                                                                        // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
                                                                        : defaultCheckoutTimeStr) 
                                                                    : (DateTime.newInstance(bookingInfo.CheckOutDate, bookingInfo.CheckOutTime)).format('HH:mm')
                                                                );
            leadIndex.Nights__c = bookingInfo.Nights;
            // 2012/12/23 ADD
            if(CommUtils.isBlank(leadIndex.contactRef__c)) leadIndex.contactRef__c = pkuser.Id;
            leadIndex.Rooms__c = (bookingInfo.TotalRoomCount == null || bookingInfo.TotalRoomCount == 0) ?
                                bookingInfo.roomAndGuestLst.size() : bookingInfo.TotalRoomCount;
            // 2013/07/16 ADD 予約チャネルに設定を行う
            // 2016/01/28 ネットからの取込時に予約チャネルに旅行会社名で設定する BEGIN
            //leadIndex.Channel__c = TraveCompany.size() > 1 ? TraveCompany[1].Name : TraveCompany[0].Name;
            leadIndex.Channel__c = TraveCompany.size() > 0 ? TraveCompany[0].Name : null;
            // 2016/01/28 ネットからの取込時に予約チャネルに旅行会社名で設定する END
            // 2013/08/16 予約名追加
            leadIndex.LeadName__c = CommUtils.isBlank(bookingInfo.GuestOrGroupNameKanjiName) ? bookingInfo.GuestOrGroupNameSingleByte : bookingInfo.GuestOrGroupNameKanjiName;
            // 2013/09/10 特記事項設定追加
            // 2017/09/01 最大文字数をこえない問題回避対応 BEGIN
            //leadIndex.Comment__c = bookingInfo.OtherServiceInformation;
            leadIndex.Comment__c = CommLogUtils.removeOverLogString(bookingInfo.OtherServiceInformation, indexCommentLength);
            // 2017/09/01 最大文字数をこえない問題回避対応 END
            leadIndex.TravelAgencyBookingInsDateTime__c = DateTime.newInstance(bookingInfo.TravelAgencyBookingDate, bookingInfo.TravelAgencyBookingTime !=null?bookingInfo.TravelAgencyBookingTime: Time.newInstance(0,0,0,0));
            upsert leadIndex;
        }
        mLogUtils.write_log('leadIndex:: ' + leadIndex.id);
        mLogUtils.write_method_end();
        return leadIndex;
    }
    /**
    * プラン情報を設定する
    * 2013/06/22 プラン未設定のケース場合
    **/
    private Plan__c upsertPlan(BI_EMAIL_SyncInfo bookingInfo, List<Account> TraveCompany) {
     	// 2017/02/24 Field Security Check BEGIN by wx
 		List<String> insChkFields = new List<String>{'client__c','PackageCode__c','name','ShopInfoRef__c'};
 		Map<String,Schema.SObjectField> insm = Schema.SObjectType.Plan__c.fields.getMap();
 		if (!CommSecurityUtils.isCanCreateable(insChkFields, insm)) {
 			return null;
 		}
 		// 2017/02/24 Field Security Check End by wx
        mLogUtils.write_method_start('upsertPlan');
        
        Plan__c rsPlan = null;
        // プランのPackageCode/プラン名は両方とも存在する場合、処理対象です
        if (CommUtils.isBlank(bookingInfo.PackagePlanName) &&
            CommUtils.isBlank(bookingInfo.PackagePlanCode)) { 
            mLogUtils.write_method_end();
            return rsPlan; 
        }
        
        // 同じプラン名情報を検索する
        List<Plan__c> existPlanLst = new List<Plan__c>();
        // プラン名が存在する場合とプランコード
        String packageCode = CommUtils.nullToBlank(bookingInfo.PackagePlanCode);
        String packageName = CommUtils.nullToBlank(bookingInfo.PackagePlanName);
mLogUtils.write_log('packageCode='+packageCode);
mLogUtils.write_log('packageName='+packageName);
        String agtId = TraveCompany[0].Id;
        String shopCode = shopCd;
        // パッケージコードが存在する場合、パッケージからSFのプラン変換ルールをチエックする
        if (!CommUtils.isBlank(packageCode)) {
            String planNo = EmailMessageToLeadHelp.getSfPlanNoByAgtPlanInfo(shopCd,bookingInfo.SalesOfficeCompanyCode,packageCode);
            // 該当パッケージコードからSF側のプランNOが設定されている場合
            if(planNo != null){
                mLogUtils.write_log('AGTパッケージコード「'+packageCode+'」からPlanNo「'+planNo+'」に変換済');
                List<Plan__c> planLst = [select Id, name,PlanNo__c,ShopInfoRef__c,client__c,Price__c,ServiceRate__c,JmstRef__r.TaxRate__c from Plan__c where IsClosed__c != true and PlanNo__c = :planNo limit 1];
                if(!planLst.isEmpty()) return planLst[0];
            }
        }
        
        // 店舗情報格納する
        Map<String, ShopInformation__c> shopInfoMap = new Map<String, ShopInformation__c>(); 
        /* 2014.11.18 プラン検索ロジック変更、店舗検索機能を追加 */
        String queryHeader = ' select Id, name,PlanNo__c,ServiceRate__c,JmstRef__r.TaxRate__c,Price__c  from Plan__c ';
        String queryLimit = ' limit 1 ';
        // 2014/07/16 非公開プランは検索対象外に対応
        //String whereStr = ' Where (';
        String whereStr = ' Where IsClosed__c != true And (';
        // 店舗別単位でプラン設定する場合、店舗コードとプランのPackageCodeは合わせる確認が必要です
        if (isPlanOfShopFlg) {
            shopInfoMap = ShopInfoUtil.getShopInfoMap();
            if (!CommUtils.isBlank(packageCode)) {
            	whereStr += ' PackageCode__c != null And PackageCode__c = :packageCode And ShopInfoRef__r.ShopCode__c = :shopCode ';
            } else if (!CommUtils.isBlank(packageName)) {
            	whereStr += ' Name = :packageName And ShopInfoRef__r.ShopCode__c = :shopCode ';
            }
            if (!CommUtils.isBlank(shopCode)) whereStr += ' And ShopInfoRef__c != null ';
        } else {
            if (!CommUtils.isBlank(packageCode)) {
                whereStr += ' PackageCode__c = :packageCode ';
            }
            if (!CommUtils.isBlank(packageName)) {
                if (!CommUtils.isBlank(packageCode)) { whereStr += ' Or '; }
                whereStr += ' name = :packageName ';
            }
        }
        whereStr += ')';
        String whereStr2 = '';
        if (!CommUtils.isBlank(agtId)) {
            // AGT情報がXMLに設定されている場合、AGT条件に入れて、検索を行う
            whereStr2 = ' And client__c = :agtId ';
            existPlanLst = DataBase.query(queryHeader + whereStr + whereStr2 + queryLimit);
        }
        if (existPlanLst.isEmpty()) {
            existPlanLst = DataBase.query(queryHeader + whereStr + queryLimit);
        }
        // Plan非存在する場合：新規作成
        if (existPlanLst == null || existPlanLst.isEmpty()) {
            rsPlan = new Plan__c();
            //rsPlan.ShopInfoRef__c = shopId;   // 2014/11/18 店舗設定機能を追加
            rsPlan.ShopInfoRef__c = shopInfoMap.containsKey(shopCode) ? shopInfoMap.get(shopCode).Id : null;
            rsPlan.name = packageName.length() > 80 ?packageName.subString(0,80) : packageName;
            rsPlan.PackageCode__c = bookingInfo.PackagePlanCode;
            rsPlan.client__c = agtId;
            insert rsPlan;
            // 新規作成のプラン情報を再取得する
            rsPlan = [select Id, name,PlanNo__c,ServiceRate__c,JmstRef__r.TaxRate__c  from Plan__c where id = :rsPlan.id];
        }  else {
            rsPlan = existPlanLst[0];
        }
        //mLogUtils.write_log('rsPlan:' + rsPlan );
        mLogUtils.write_method_end();
        return rsPlan;
    }
    // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
    public static String OPTION_MODE{get{ return CommConst.OPTION_MODE;}}
    public static ProductItemUtils.LeadInfoSync ldInfo;
    // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
    /**
	* プランの関連プラン明細情報を自動取得を行う
	**/
    private void setPlanDetailPlusInfo(Plan__c plan) {
    	// プラン明細情報を格納する
    	planDetailInf = new planDetailInfo();
    	// プラン情報なし
    	if (plan == null) return;
    	mLogUtils.write_method_start('setPlanDetailPlusInfo');
    	// 該当プランのプラン明細情報を取得する
    	Id planId = plan.Id;
    	// 固定取得の項目情報
    	String fixQueryFields = 'Id,Price__c,ServiceRate__c,TaxRate__c,AccountMasterRef__c,AccountMasterRef__r.ActionType__c';
    	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
    	// 2020/05/29 bug fixed 6440 WGCH BEGIN
        fixQueryFields += ', AccountMasterRef__r.Name, Amount__c, OptionAccMstFLG__c ';
        // 2020/05/29 bug fixed 6440 WGCH END
        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
    	Set<String> queryFieldsSet = new Set<String>();
    	queryFieldsSet.addAll(fixQueryFields.split(','));
        String queryStr = 'select ';
    	// Query Field List取得する
    	for(string fieldApi : queryFieldsSet) {
    		queryStr += fieldApi + ',';
    	}
    	queryStr = queryStr.removeEnd(',');
    	queryStr = queryStr + ' From PlanDetail__c where PlanRef__c = :planId order by name ';
    	//mLogUtils.write_log('プラン明細取得' + queryStr);
		// 指定のプラン明細情報を取得する
    	List<PlanDetail__c> orgPdList = DataBase.query(queryStr);
    	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
        // 2020/05/29 bug fixed 6453 WGCH BEGIN
        if(CommConst.REDUCED_TAXRATE_FLG && OPTION_MODE == CommConst.OPTION_MODE_ON){
        // 2020/05/29 bug fixed 6453 WGCH END
        	ProductItemUtils.PlanOrgPdInfo inf = ProductItemUtils.getPlanOrgPdInfo(orgPdList, ldInfo);
        	orgPdList = inf.orgPdList;
        	ldInfo = inf.ldInfo;
        } else{
        	// OPTION关闭情况要把OPTION金额补上
        	ProductItemUtils.getNewPlanData(orgPdList, plan);
        }
        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
    	mLogUtils.write_log('プラン明細取得件数:' + orgPdList.size());
		// 2019/09/15 軽減税率機能対応 WGCH BEGIN
		// planDetailInf.init(orgPdList);
		planDetailInf.init(orgPdList, plan);
		// 2019/09/15 軽減税率機能対応 WGCH END
		
    	mLogUtils.write_method_end();
    }
	
	class planDetailInfo {
		public planDetailInfo() {
			orgPlanDetailList = new List<PlanDetail__c>();
			// 室料商品リスト
			priceRoomPdList = new list<PlanDetail__c>();
			// 調整不可の明細の合計値を格納する[室料以外の設定されている金額]
			priceNotChangeSumVal = 0;
			// 非課税金額合計値を格納する
			priceNoTaxSumVal = 0;
			// 非課税対象リストを格納する
			noTaxPdList = new List<PlanDetail__c>();
			// 2019/09/15 軽減税率機能対応 WGCH BEGIN
			curnPayPriceEnd = 0;
			priceNoTaxSumValEnd = 0;
			priceNoRoomPdSumValEnd = 0;
			// 2019/09/15 軽減税率機能対応 WGCH END
		}
		// 2019/09/15 軽減税率機能対応 WGCH BEGIN
		public void init(List<PlanDetail__c> orgPdList) {
			init(orgPdList, null);
		}
		// 2019/09/15 軽減税率機能対応 WGCH END
		//, EmailMessageToLeadHelp.BOOKINGCONFIG bookingConfig
		// 2019/09/15 軽減税率機能対応 WGCH BEGIN
		// public void init(List<PlanDetail__c> orgPdList) {
		public void init(List<PlanDetail__c> orgPdList, Plan__c plan) {
		// 2019/09/15 軽減税率機能対応 WGCH END
			// 元のプラン明細情報を格納する
			// 2019/09/15 軽減税率機能対応 WGCH BEGIN
			// orgPlanDetailList = orgPdList.clone();
			if(!isReducedTaxFlg) orgPlanDetailList = orgPdList.clone();
			else if(isReducedTaxFlg && plan != null) {
				for (Integer i = 0; i < orgPdList.size(); i++) {
					PlanDetail__c pd = orgPdList[i];
					if(!isRoomRateItem(pd.AccountMasterRef__r)) {
						// SF => XML 单价转换
						priceNoRoomPdSumValEnd += CommUtils.convertPriceByTaxKbn(  CommUtils.nullToZero(pd.Price__c),
																		CommUtils.nullToZero(pd.TaxRate__c),
																		CommUtils.nullToZero(pd.ServiceRate__c),
																		CommConst.APPOPTION_UTP_DEF_KB,
																		taxSericeFeeEnd);
					}
					// 带Id克隆
					orgPlanDetailList.add(pd.clone(true, true));
					// 原非課税商品明細金額
					if (CommUtils.nullToZero(pd.taxRate__c) == 0) priceNoTaxSumVal += CommUtils.nullToZero(pd.Price__c);
					// 单价置换
					pd.Price__c = convertPriceByHeaderPrice(pd, plan);
	    			if (CommUtils.nullToZero(pd.taxRate__c) == 0) priceNoTaxSumValEnd += CommUtils.nullToZero(pd.Price__c);
	    			else curnPayPriceEnd += CommUtils.nullToZero(pd.Price__c);
				}
			}
			// 2019/09/15 軽減税率機能対応 WGCH END
			
	    	// 非課税明細は対象外になる
	    	for (Integer i = 0; i < orgPdList.size(); i++) {
	    		if (CommUtils.nullToZero(orgPdList[i].taxRate__c) == 0) {
	    			noTaxPdList.add(orgPdList[i]);
	    			// 2019/09/15 軽減税率機能対応 WGCH BEGIN
	    			// priceNoTaxSumVal += CommUtils.nullToZero(orgPdList[i].Price__c);
	    			if(!isReducedTaxFlg) priceNoTaxSumVal += CommUtils.nullToZero(orgPdList[i].Price__c);
	    			// 2019/09/15 軽減税率機能対応 WGCH END
	    			orgPdList.remove(i);
	    		}
	    	}
			// 室料の明細の場合、室料リストに格納する　
	    	for (Integer i = 0; i < orgPdList.size(); i++) {
	    		if (isRoomRateItem(orgPdList[i].AccountMasterRef__r)) {
	    			priceRoomPdList.add(orgPdList[i]);
	    			orgPdList.remove(i);
	    		}
	    	}
	        // 残りプラン明細は存在する場合、OTHER情報になる
	        for (Integer i = 0; i < orgPdList.size(); i++) {
	        	// 既に設定されている金額は合計する　
	        	priceNotChangeSumVal += CommUtils.nullToZero(orgPdList[i].Price__c);
	        }
		}
		// 元のプランのプラン明細情報を格納する
		public List<PlanDetail__c> orgPlanDetailList{get; private set;}
		// 明細情報存在の場合
		public Boolean isHavePdData{get{return !orgPlanDetailList.isEmpty();}}
		// 非課税商品明細金額合計値
		public Decimal priceNoTaxSumVal{get; private set;}
		// 非課税明細情報を格納する
		public List<PlanDetail__c> noTaxPdList{get; private set;}
		// 室料明細リスト
		public List<PlanDetail__c> priceRoomPdList{get;set;}
		// 室料明細リストCLONE対象リストを取得する
		public List<PlanDetail__c> getClonePriceRoomPdList() {
			List<PlanDetail__c> cloneList = new List<PlanDetail__c>();
			for (PlanDetail__c pd : priceRoomPdList) {
				cloneList.add(pd.clone(true,true));
			}
			return cloneList;
		}
		// 調整不可の明細の合計値
		public Decimal priceNotChangeSumVal{get; private set;}
		// 2019/09/15 軽減税率機能対応 WGCH BEGIN
		// 非課税以外商品明細金額合計値
		public Decimal curnPayPriceEnd{get; private set;}
		// 转换后非課税商品明細金額合計値
		public Decimal priceNoTaxSumValEnd{get; private set;}
		// 室料明細リスト対象リスト商品明細金額合計値
		public Decimal priceNoRoomPdSumValEnd{get; private set;}
		// 2019/09/15 軽減税率機能対応 WGCH END
	}
	// 2019/09/15 軽減税率機能対応 WGCH BEGIN
	public static Decimal convertPriceByHeaderPrice(PlanDetail__c pd, Plan__c plan){
		Decimal pdPrice = CommUtils.nullToZero(pd.Price__c); // plan明细单价
		Decimal pdTaxRate = CommUtils.nullToZero(pd.taxRate__c); // plan明细消费税
		Decimal pdServiceRate = CommUtils.nullToZero(pd.ServiceRate__c); // plan明细サビース料
		Decimal pTaxRate = CommUtils.nullToZero(plan.JmstRef__r.TaxRate__c); // plan明细消费税
		Decimal pServiceRate = CommUtils.nullToZero(plan.ServiceRate__c); // plan明细サビース料
		// 单价转换 = 明细单价 * ( ((1 + Header消费税 / 100) * (1 + Headerサビース料 / 100)) / ((1 + 明细消费税 / 100) *  (1 + 明细サビース料 / 100)) )
		Decimal pdPriceEnd = pdPrice * ( ((1 + pdTaxRate / 100) * (1 + pdServiceRate / 100)) / ( (1 + pTaxRate / 100) * (1 + pServiceRate / 100)) );
		return CommUtils.RoundProcess(pdPriceEnd, CommUtils.getPointLen(), RoundingMode.CEILING);
	}
	// 室料金额 SF => XML
	public Decimal setPriceRoomPdSumVal(PlanDetailInfo planDetailInf, map<Id, PlanDetail__c> changePdMap){
		Decimal diffUnitSubEnd = 0;
		Boolean isRoomRateFlg = true;
		// 明細設定情報を作成する
		for (PlanDetail__c pd : planDetailInf.orgPlanDetailList) {
			PlanDetail__c changePd = changePdMap.get(pd.id);
			if (changePd == null) changePd = pd;
			// 該当明細は室料の場合、残りの残料金は残部自動設定を行う
			if (isRoomRateItem(changePd.AccountMasterRef__r) && isRoomRateFlg) {
				Decimal priceRoomSum = orgEstUnitPriceEnd - planDetailInf.priceNoRoomPdSumValEnd;
				// XML => SF 单价转换
				Decimal priceRoomPdSumVal = CommUtils.convertPriceByTaxKbn( priceRoomSum,
																		CommUtils.nullToZero(changePd.TaxRate__c),
																		CommUtils.nullToZero(changePd.ServiceRate__c),
																		taxSericeFeeEnd,
																		CommConst.APPOPTION_UTP_DEF_KB);
				// 差值配平处理
				Decimal diffSum = priceRoomSum - setPriceRoomPdSumDiffVal(changePd, priceRoomPdSumVal, 0);
				if(diffSum < 0){
					diffUnitSubEnd = -1;
					diffSum = priceRoomSum - setPriceRoomPdSumDiffVal(changePd, priceRoomPdSumVal, diffUnitSubEnd);
					if(diffSum != 0){
						diffUnitSubEnd = -0.5;
						diffSum = priceRoomSum - setPriceRoomPdSumDiffVal(changePd, priceRoomPdSumVal, diffUnitSubEnd);
					}
				} else {
					diffUnitSubEnd = 1;
					diffSum = priceRoomSum - setPriceRoomPdSumDiffVal(changePd, priceRoomPdSumVal, diffUnitSubEnd);
					if(diffSum != 0){
						diffUnitSubEnd = 0.5;
						diffSum = priceRoomSum - setPriceRoomPdSumDiffVal(changePd, priceRoomPdSumVal, diffUnitSubEnd);
					}
				}
				if(isRoomRateFlg) diffUnitSubEnd = changePd.Price__c;
				isRoomRateFlg = false; // 自动设定到第一个室料上
			}
		}
		return diffUnitSubEnd;
	}
	// 室料金额 SF => XML 反算验证处理
	public Decimal setPriceRoomPdSumDiffVal(PlanDetail__c changePd, Decimal priceRoomPdSumVal, Decimal diffSum){
		// 小数桁を再調整を行う
		changePd.Price__c = checkIfHadScale( priceRoomPdSumVal,
											CommUtils.nullToZero(changePd.TaxRate__c),
											CommUtils.nullToZero(changePd.ServiceRate__c),
											CommConst.APPOPTION_UTP_DEF_KB);
		// SF => XML 单价转换
		Decimal priceRoomPdSumValEnd = CommUtils.convertPriceByTaxKbn( changePd.Price__c,
																CommUtils.nullToZero(changePd.TaxRate__c),
																CommUtils.nullToZero(changePd.ServiceRate__c),
																CommConst.APPOPTION_UTP_DEF_KB,
																taxSericeFeeEnd);
		return priceRoomPdSumValEnd;
	}
	public static Decimal orgEstUnitPriceEnd{get{ return CommUtils.nullToZero(orgEstUnitPriceEnd);}}
	public static Integer taxSericeFeeEnd{get{ return CommUtils.nullToIntZero(taxSericeFeeEnd);}}
	// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
	// public static boolean isReducedTaxFlg{get{ return CommConst.REDUCED_TAXRATE_FLG;}}
	public static boolean isReducedTaxFlg{get{ return CommConst.REDUCED_TAXRATE_FLG && CommConst.PLAN_BRKTOHEADER_CAL_FLG;}}
	// 2019/10/02 PlanHeader算法切换对应 WGCH END
	// 2019/09/15 軽減税率機能対応 WGCH END
    /**
    * 予約情報を登録する
    */
    private void upsertTL2Lead(BI_EMAIL_SyncInfo bookingInfo, LeadIndex__c leadIndex, Contact pkuser, List<Account> TraveCompany,String shopCode,List<Lead__c> oldLeadLst) {
         // 2017/02/24 Field Security Check BEGIN
 		List<String> chkFields = new List<String>{'Field310__c','RecordTypeId','Name','Rroom__c','Relcontact__c',
 												'Field348__c','EntryTime__c','refTypeOfRooms__c','EventSource__c','ReservedDate__c','RoomGroupNo__c','LeadIndexSubId__c',
 												'LeadIndexRef__c','Comment3__c','PlanSycnFlag__c','BookingDataID__c','SettlementDiv__c','Field354__c','email__c','Field4__c',
 												'Field3__c','Departure__c','Field2__c','UnitPriceDefKb__c','SalesOfficeInfoRef__c','Field315__c','ChildC__c','Childs__c','ChildFA__c',
 												'Femails__c','Mans__c','StayPersons__c','BridalDantaikei__c','ChildD__c'};
 		Map<String,Schema.SObjectField> m = Schema.SObjectType.Lead__c.fields.getMap();
 		if (!CommSecurityUtils.isCanUpsertable(chkFields, m)) {
 			return;
 		}
 		// 2017/02/24 Field Security Check End
        mLogUtils.write_method_start('upsertTL2Lead');

        // 部屋自動割り振り機能
        boolean autoAssingRoomflag = EmailMessageToLeadHelp.getAppConfig(shopCd).roomAutoAssignFlag;
        // 税区分設定
        Integer taxSericeFee = CommUtils.nullToIntZero(bookingInfo.TaxServiceFee);
        // 2019/09/15 軽減税率機能対応 WGCH BEGIN
        taxSericeFeeEnd = taxSericeFee;
        // 2019/09/15 軽減税率機能対応 WGCH END
        
        // プラン情報を取得、作成する
        // プラン情報がNULLの場合、見積明細に直接室料を設定する
        Plan__c curPlan = upsertPlan(bookingInfo, TraveCompany);
        // プラン明細情報を取得する
        setPlanDetailPlusInfo(curPlan);
        mLogUtils.write_log('プラン情報::' + curPlan);
        
        // 部屋タイプID情報を取得する
        Set<String> roomTypeCdSet = new Set<String>();
        // 2013/02/26 部屋タイプ名情報を格納する
        Set<String> roomTypeNmSet = new Set<String>();
        // 部屋タイプコードは再取得を行う
        for (BI_EMAIL_RoomAndGuestInfo roomAndGuest: bookingInfo.roomAndGuestLst) {
            roomTypeCdSet.add(roomAndGuest.room.RoomTypeCode);
            // 2013/02/26 部屋タイプ名：部屋ID情報を格納する
            if (!CommUtils.isBlank(roomAndGuest.room.RoomTypeName)) roomTypeNmSet.add(roomAndGuest.room.RoomTypeName);
        }
        
        // 部屋タイプMAP情報設定する
        Map<String,Id> roomTypeMap = new Map<String, Id>();
        // 2013/02/26 部屋タイプ名情報を格納する
        Map<String,Id> roomTypeNmMap = new Map<String, Id>();
        // UPDATE 2015/09/15　店舗区分 :新追加 ShopInfoRef__c　
        for (TypeOfRooms__c roomType: [select id, RoomTypeName__c, RoomTypeCode__c from TypeOfRooms__c where ShopInfoRef__r.ShopCode__c = :shopCode and  (RoomTypeCode__c in :roomTypeCdSet Or RoomTypeName__c in :roomTypeNmSet)]) {
            roomTypeMap.put(roomType.RoomTypeCode__c, roomType.Id);
            // 2013/02/26 部屋タイプ名：部屋ID情報を格納する
            if (!CommUtils.isBlank(roomType.RoomTypeName__c)) roomTypeNmMap.put(roomType.RoomTypeName__c, roomType.Id);
        }
        mLogUtils.write_log('roomTypeMap :: ' + roomTypeMap.keySet());
        // 2015/07/22  部屋タイプが存在　かつ　対応部屋タイプに対して、１部屋のみの場合、該当部屋は自動的に予約にアサインする BEGIN
        Map<Id, id> oneTypeToRoomMap = new Map<Id, Id>();
        // 自動割り当てフラグはTRUEのみ、該当関連取得を行う
        if (autoAssingRoomFlg) {
            for ( TypeOfRooms__c r : [Select id, (Select Id From TypeRoomRef__r limit 2) From TypeOfRooms__c where id in :roomTypeMap.values()] ) {
                if (r.TypeRoomRef__r != null && r.TypeRoomRef__r.size() == 1) {
                    oneTypeToRoomMap.put( r.Id, r.TypeRoomRef__r[0].Id );
                }
            }
        }

        // 部屋タイプにより、自動割り振りできる部屋情報を戻る
        // 2015/10/30 故障部屋は自動割当て機能に追加対応 BEGIN
        //map<Id, List<Room__c>> canAssignRoomMap = new map<Id, List<Room__c>>();
        map<Integer, Room__c> canAssignRoomMap = new map<Integer, Room__c>();
        if (autoAssingRoomflag) {
            canAssignRoomMap = getCanAssignRoom(leadIndex,roomTypeMap,roomTypeNmMap,autoAssingRoomflag,bookingInfo);
        }
        // 2015/10/30 故障部屋は自動割当て機能に追加対応 END
        // 宿泊レコードタイプ
        String bookingRcTypeId = CommLogicProcess.getLeadBookingRecType();
        // チェックイン日付・日時[基本宿泊情報から]
//system.debug('leadIndex:::' + leadIndex);
        DateTime checkInFirstDayDt = DateTime.newInstance(leadIndex.EntryDate__c,
            bookingInfo.CheckInTime == null ? defaultCheckinTime : bookingInfo.CheckInTime);
        // 最後日のチェックアウト日付・日時[基本宿泊情報から][出発日設定を行う]
        DateTime checkOutLastDayDt = DateTime.newInstance(leadIndex.DepartureDate__c, 
            bookingInfo.CheckOutTime == null ? defaultCheckoutTime : bookingInfo.CheckOutTime);
        // メール本文[7XXXXX]
        BI_EMAIL_RisaplBasic risaplBasic = bookingInfo.risaplsinformation.risaplsCommonInformation.risaplBasic;
        // 2013.05.29 ADD パタン６確認する（連泊、１室、１部屋タイプ）
        // 2013.07.10 ADD 同じ日付のデータ数：部屋数　　部屋利用日の範囲は泊数設定
        // 定義した総泊数からLOOPして、その後、部屋数LOOPする
        Integer nights = bookingInfo.Nights;            // 総宿泊数
        if (nights == 0) nights = 1;
        Integer rooms = bookingInfo.TotalRoomCount;     // 総部屋数
        // 2013/07/05 予約名自動設定対応、団体名または代表者氏名 漢字ー＞団体名または代表者氏名(半角)
        //String leadName = CommUtils.isBlank(bookingInfo.GuestOrGroupNameKanjiName) ? bookingInfo.GuestOrGroupNameSingleByte : bookingInfo.GuestOrGroupNameKanjiName;
        String leadName = leadIndex.LeadName__c;
        // 複数件予約データを作成する 
        List<Lead__c> insLeadLst = new List<Lead__c>();
        // 2013/07/16 記号機能対応 BEGIN
        // N rooms N nightsのとき、特記事項をその日は、一つにする対応と同様に、親部屋マーク（一文字記号）をカスタム設定のパラメータとして、定義、この定義されたマークを予約名の文字列先頭に付加する、
        // また、人数とプランも一つの予約データのみに取り込み、他の予約データは、人数ゼロ、プランなし、と設定する
        String strRoomDelegatePrefix = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomDelegatePrefix__c);
        // N部屋N泊数標識フラグ
        // 2013/07/16 記号機能対応 End
        // 複数予約日ー＞複数部屋タイプから　１部屋タイプ１日予約データを作成する
        Map<String,List<BookingEstimateItem__c>> roomToItemsMap = new Map<String,List<BookingEstimateItem__c>>();
        Map<String,Integer> roomToItemMap = new Map<String,Integer>();

        // 見積明細に明細登録用会計商品
        nyuuTouAcc = getNyuuTouAcc();           // [入湯税商品定義情報を取得する]
        serviceAcc = getServiceAcc();           // [サビース料商品定義情報を取得する]
        AccountMaster__c commshitulyouAcc = null;   // プラン関連の会計商品情報格納   
        // 消費税情報を取得する   
        JMST__c taxRateMst = CommLogicProcess.getTaxRateInfo();
        // XMLに指定のXMLが存在する場合、プラン関連の会計商品（プラン）情報を取得する
        if(curPlan != null){
            // 指定のプラン情報により、関連の会計商品を捜す
            String productCd = PLAN_PRD_PREX_NUM + curPlan.PlanNo__c;
            List<AccountMaster__c> accounts = [select id,Name,jmstRef__r.TaxRate__c,ServiceRate__c from AccountMaster__c where Field3__c = :productCd];
            // 関連の会計商品が存在する場合
            if(!accounts.isEmpty()){
                commshitulyouAcc = accounts[0];
            }
            // 関連の会計商品が非存在する場合、回答プラン関連の会計商品を自動作成を行う
            else{
                commshitulyouAcc = new AccountMaster__c(
                                Name = curPlan.Name,
                                Field3__c = productCd,
                                jmstRef__c = taxRateMst.id,
                                jmstRef__r = taxRateMst,
                                ServiceRate__c = curPlan.ServiceRate__c,
                                ActionType__c = CommConst.PROD_ACTION_TYPE_PL
                            );
                insert commshitulyouAcc;
            }
            // 該当プランの明細情報を取得する
            //List<PlanDetail__c> planDetail = [select Price__c,ServiceRate__c,TaxRate__c,AccountMasterRef__c,AccountMasterRef__r.ActionType__c from PlanRef__r where PlanRef__c = :curPlan.id];
        }
        // プラン関連の会計商品が非存在する場合、室料商品を取得する
        if (commshitulyouAcc == null) {
            commshitulyouAcc = getShiTuLyouAcc();   // [室料商品定義情報を取得する]
        }
        // 見積明細に登録する会計商品
        mLogUtils.write_log('会計商品：' +commshitulyouAcc);
        // 税区分
        mLogUtils.write_log('税区分：' + bookingInfo.TaxServiceFee);
        
        Boolean isUpdateFlag = bookingInfo.dmlAction == BI_EMAIL_DmlAction.UPD;
        // 予約情報にプラン存在するがどうかチエックを行う、プランが存在すると、１部屋の総利用金額は該当プランに設定を行う
        // プラン情報はXMLに未定義すると、室料の会計商品で、総金額は室料の金額に設定を行う
        BookingEstimateItem__c cloneItem = null;
        if (commshitulyouAcc.Id != null) {
        	cloneItem = new BookingEstimateItem__c(
                        refAccountMaster__c = commshitulyouAcc.id,
                        refAccountMaster__r = commshitulyouAcc,
                        //UnitPriceDefKb__c = bookingInfo.TaxServiceFee,
                        TaxRate__c = taxRateMst.TaxRate__c);
	        if(curPlan != null) {
	            //item.PlanDetailSyncInfo__c = curPlan.id;
	            cloneItem.Field3__c = PLAN_PRD_PREX_NUM + curPlan.PlanNo__c;
                // 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応 by zh BEGIN
                boolean plannameToEstflag = EmailMessageToLeadHelp.isSfPlanNmToEstProdNm(shopCd);
System.debug(LoggingLevel.INFO,'見積明細名はプラン目に変更::::' + plannameToEstflag);
                if(plannameToEstflag){
                	cloneItem.ProductName__c = curPlan.Name;
                } else {
                	cloneItem.ProductName__c = CommUtils.isBlank(bookingInfo.PackagePlanName)
	                                        ? curPlan.Name
	                                        : bookingInfo.PackagePlanName;
                }
                // 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応 by zh END
	            cloneItem.ActionType__c = CommConst.PROD_ACTION_TYPE_PL;
	        }
   		}
        //mLogUtils.write_log('見積もり明細取り込完了::roomToItemsMap::' + roomToItemsMap.keySet());
        //mLogUtils.write_log('roomToItemMap::' + roomToItemMap.keySet());
        if(bookingInfo.TravelAgencyBookingTime == null) bookingInfo.TravelAgencyBookingTime = Time.newInstance(0,0,0,0);
        Map<Integer,List<BookingEstimateItem__c>> roomMaps = new Map<Integer,List<BookingEstimateItem__c>>();
        Map<String,Object> autoSetupfieldMap = EmailMessageToLeadHelp.getAppConfig(shopCd).fieldMap;
        Map<String, Schema.DescribeFieldResult> finalFieldMap = CommUtils.getFieldMetaData(Lead__c.getSObjectType().getDescribe(),autoSetupfieldMap.keySet());
        boolean isRoomRateFlg = bookingInfo.RoomRateOrPersonalRate == 'PersonalRate' ? false : true;
mLogUtils.write_log('予約情報新規、変更処理開始');
        //予約　グループのマッピングを作成
        Map<Integer,List<Lead__c>> groupLeadMap = new Map<Integer,List<Lead__c>>();
        Lead__c beforeLead = null;
        integer roomIndex = 0;
        // 既存予約情報はグループ化する
        for(Lead__c lead : oldLeadLst){
        	// 別の部屋の予約情報を切り替えする場合
            if(beforeLead != null){
                if(beforeLead.LeadIndexSubId__c != lead.LeadIndexSubId__c || beforeLead.RoomGroupNo__c != lead.RoomGroupNo__c){
                    roomIndex ++;
                }
            }
            beforeLead = lead;
            if(!groupLeadMap.containsKey(roomIndex)){
                groupLeadMap.put(roomIndex,new List<Lead__c>());
            }
            groupLeadMap.get(roomIndex).add(lead);
        }
        Map<String,Id> lastRoomMap = new Map<String,Id>();
        Set<String> userOrgLeadSet = new Set<String>();
        Set<Id> updateOrgLeadIdSet = new Set<Id>();
        // 2016/01/07 予約キャンセルの場合、キャンセル内容は本文メールに反映を行う BEGIN
        //integer commentLength = Lead__c.Comment3__c.getDescribe().getLength();
        //integer emailLength = Lead__c.email__c.getDescribe().getLength();
        // 2016/01/07 予約キャンセルの場合、キャンセル内容は本文メールに反映を行う END
        // 日単位情報
        for(Integer i = 0; i < nights; i ++){
            // １部屋タイプから複数日予約データを作成する
            /*
            // 複数日から１日単位に作成する
            Integer staysNums = roomAndGuest.roomRateLst.size();
            if (isParten6Flg) staysNums = nights;
            */
            // 部屋単位情報
            for(Integer j = 0; j < rooms; j ++){
                // データ取得INDEX
                Integer idx = i * rooms + j;
                //　到着日
                //Date checkInDate = (isParten6Flg ? bookingInfo.roomAndGuestLst[i].roomRateLst[0].RoomDate : roomAndGuest.roomRateLst[i].RoomDate);
                //if (isParten6Flg) roomAndGuest = bookingInfo.roomAndGuestLst[i];
                
                BI_EMAIL_RoomAndGuestInfo roomAndGuest = bookingInfo.roomAndGuestLst[idx];
                // 部屋利用日（到着日)
                Date checkInDate = roomAndGuest.roomRateLst[0].RoomDate;
//system.debug(logginglevel.info,'roomAndGuest.roomRateLst[0]:::' + roomAndGuest.roomRateLst[0]);
                // 新規予約データ作成
                
                Lead__c newLead = (Lead__c)getNewObjectByName(Lead__c.sObjectType, null);	//new Lead__c();
//system.debug(logginglevel.info,'newLead:::' + newLead);
                // 変更前の予約泊数
                Integer orgLeadNights = null;
                Lead__c orgLead = null;
                if(isUpdateFlag){
                    if(groupLeadMap.containsKey(j)){
                        List<Lead__c> oLeadLst = groupLeadMap.get(j);
                        // 既存の予約の泊数情報を取得する
                        orgLeadNights = oLeadLst.size();
                        if(oLeadLst.size() - 1 >= i){
                        	orgLead = oLeadLst.get(i).clone(true,true);
                            newLead = oLeadLst.get(i);
                            userOrgLeadSet.add(j + '_' + i);
                            updateOrgLeadIdSet.add(orgLead.Id);
                        }else if(oLeadLst.size() > 0){
                            newLead.LeadIndexSubId__c = oLeadLst[0].LeadIndexSubId__c;
                        }
                    }
                }
                // 既存の予約情報が存在する場合
                boolean isHadLeadId = (orgLead != null);
                // お客様情報
                newLead.Relcontact__c = newLead.Relcontact__c == null ? pkuser.id : newLead.Relcontact__c;
                
                // 2013/07/16 記号機能対応 BEGIN
                // 親部屋マーク標識用の文字は予約名の文字列先頭に付加
            	// プラン情報         
            	newLead.Field310__c = curPlan == null ? null : curPlan.Id;
            	// 予約名情報を格納する
                if(isHadLeadId){
                	// 予約名の個別処理
                	String orgLeadName = '';
                	String newLeadName = '';
                	// 既存の予約名はそのまま残り
                	if (orgLeadNights != null && orgLeadNights > 1) orgLeadName = String.valueOf(orgLeadNights) + '-' + (i+1) + '泊目 ' + orgLead.LeadIndexRef__r.LeadName__c;
                	else orgLeadName = orgLead.LeadIndexRef__r.LeadName__c;
	                if (nights > 1) newLeadName += String.valueOf(nights) + '-' + (i+1) + '泊目 ' + leadName;  //bookingInfo.GuestOrGroupNameKanjiName;
	                else newLeadName += leadName; //bookingInfo.GuestOrGroupNameKanjiName;
                	// 既存の予約名をReplaceする
                	newLead.name = newLead.name.replace(orgLeadName, newLeadName);
                	if (rooms > 1 && j == 0 
                		&& !CommUtils.isBlank(strRoomDelegatePrefix) 
                		&& !newLead.name.startsWith(strRoomDelegatePrefix)) {
                		newLead.name = strRoomDelegatePrefix + newLead.name;
                	}
                } else {
            		newLead.name = (rooms > 1 && j == 0 ? strRoomDelegatePrefix : '');
            		// 2013/07/16 記号機能対応 END
	                // 予約データ名設定を行う
	                if (nights > 1) newLead.name += String.valueOf(nights) + '-' + (i+1) + '泊目 ' + leadName;  //bookingInfo.GuestOrGroupNameKanjiName;
	                else newLead.name += leadName; //bookingInfo.GuestOrGroupNameKanjiName;
                }
                // レコードタイプ：宿泊タイプ
                newLead.RecordTypeId = bookingRcTypeId;

                // 予約受付日
                // 2013/06/19 予約受付日の受付時間設定ミス、不具合修正、時間項目を設定する
                newLead.ReservedDate__c = DateTime.newInstance(bookingInfo.TravelAgencyBookingDate, bookingInfo.TravelAgencyBookingTime);
                // 支払方法 ----------------BEGIN----------------------
                // 2014/04/25 支払方法設定共通化
                newLead.Field315__c = getLocalPaymentInfo(bookingInfo.Payment);
                // 支払方法 -----------------END-----------------------
                // 予約ステータス[Deafult:確認中]
                //newLead.ReservedStatus__c =
                // First Dayの場合
                if (i == 0) {
                    // チェックイン日
                    // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
                    //newLead.EntryTime__c = checkInFirstDayDt;
                    // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
                    // チェックイン時間
                    newLead.Field4__c = (bookingInfo.CheckInTime == null 
                        // DayUserの場合の時刻情報
                        ?  (bookingInfo.Nights == 0 ? defaultDayUseCheckInTime : defaultCheckInTimeStr)
                        :  (DateTime.newInstance(Date.today(), bookingInfo.CheckInTime)).format('HH:mm') );
                    
                    // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
                    newLead.EntryTime__c = DateTime.newInstance(checkInFirstDayDt.date(), CommUtils.stringToTime(newLead.Field4__c));
                    // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
                        
                } else {
                    // チェックイン日
                    newLead.EntryTime__c = DateTime.newInstance(checkInDate, defaultCheckinTime);
                    // チェックイン時間
                    newLead.Field4__c = defaultCheckInTimeStr;
                }
                //2016/03/02 ---------BEGIN----------------
                //予約取込のXMLのタグ：入込方法（Transportaion）存在すると、該当項目内容はご予約の「交通手段」項目へ設定する
                if(CommUtils.isBlank(newLead.Field348__c)) newLead.Field348__c = CommUtils.nullToBlank(bookingInfo.Transportaion);
                //2016/03/02 ----------END-----------------

                // 最後日の場合
                if (i == nights - 1) {
                    // チェックアウト日
                  //  newLead.Departure__c = checkOutLastDayDt;
                    
                    // チェックアウト時間
                    newLead.Field3__c = (bookingInfo.CheckOutTime == null 
                        // DayUserの場合の時刻情報
                        ? (bookingInfo.Nights == 0 
                                // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
                                //? (DateTime.newInstance(Date.today(), CommUtils.stringToTime(newLead.Field4__c).addHours(CommConst.DEF_DAYUSE_STAY_HOURS))).format('HH:mm')
                                ? ((bookingInfo.CheckOutTime == null && bookingInfo.CheckInTime == null)
                                    ? defaultDayUseCheckOtTime
                                    : (DateTime.newInstance(Date.today(), CommUtils.stringToTime(newLead.Field4__c).addHours(CommConst.DEF_DAYUSE_STAY_HOURS))).format('HH:mm')
                                )
                                // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
                                : defaultCheckoutTimeStr)
                        : (DateTime.newInstance(Date.today(), bookingInfo.CheckOutTime)).format('HH:mm') );
                      // チェックアウト日
                      newLead.Departure__c = DateTime.newInstance(checkOutLastDayDt.date(), CommUtils.stringToTime(newLead.Field3__c));
                } else {
                    // チェックアウト日
                    newLead.Departure__c = DateTime.newInstance(checkInDate.addDays(1), defaultCheckoutTime);
                    // チェックアウト時間
                    newLead.Field3__c = defaultCheckoutTimeStr;
                }
                // 2013/06/09 宿泊人数は未設定する場合、自動Default値を設定する
                Integer calRoomPaxCount =  CommUtils.nullToZero(roomAndGuest.room.RoomPaxMaleCount) + 
                                           CommUtils.nullToZero(roomAndGuest.room.RoomPaxFemaleCount) + 
                                           CommUtils.nullToZero(roomAndGuest.room.RoomChildA70Count) +
                                           CommUtils.nullToZero(roomAndGuest.room.RoomChildB50Count) +
                                           CommUtils.nullToZero(roomAndGuest.room.RoomChildC30Count) +
                                           CommUtils.nullToZero(roomAndGuest.room.RoomChildDNoneCount);
                String warningMsg = '';
                if (roomAndGuest.room.PerRoomPaxCount == null || roomAndGuest.room.PerRoomPaxCount == 0) {
                    // XMLの中に、未設定する場合、自動的にSFの初期値で自動設定を行う「非設定する場合、自動設定を行う」
                    if (calRoomPaxCount > 0) {
                        // 1室利用人数
                        newLead.StayPersons__c = calRoomPaxCount;
                    } else {
                        // 該当ケースする場合、注意事項に自動内容追加を行う
                        warningMsg = '<font color="red">サイトコントローラからの予約データのなかに、予約人数がありませんでしたので、デフォルト値(仮の値)を設定させていただきました、つきましては、ご予約者の方へご確認していただきまして、本予約データの予約人数を手動にて変更ください。</font><br/>';
                    }
                } else {
                    // 1室利用人数
                    newLead.StayPersons__c = roomAndGuest.room.PerRoomPaxCount;
                }

                // 大人人員(男性)
                newLead.Mans__c = roomAndGuest.room.RoomPaxMaleCount;
                // 大人人員(女性)
                newLead.Femails__c = roomAndGuest.room.RoomPaxFemaleCount;
                // 子供A人数
                newLead.ChildFA__c = roomAndGuest.room.RoomChildA70Count;
                // 子供B人数
                newLead.Childs__c = roomAndGuest.room.RoomChildB50Count;
                // 子供C人数
                newLead.ChildC__c = roomAndGuest.room.RoomChildC30Count;
                // 子供D人数
                newLead.ChildD__c = roomAndGuest.room.RoomChildDNoneCount;
                //　予約インデックスID
                newLead.LeadIndexRef__c = leadIndex.Id;
                //if (newLead.LeadIndexRef__c == null) newLead.LeadIndexRef__c = leadIndex.Id;
				// 料理補足
           	    newLead.Field354__c = bookingInfo.MealCondition;
                // 事前決済区分
                newLead.SettlementDiv__c = CommUtils.nullToBlank(bookingInfo.risaplsinformation.agentNativeInformation.extendmytrip.SettlementDiv);
                // 予約番号
                newLead.BookingDataID__c = bookingDataId;
                // プラン自動展開対象外フラグ設定
                newLead.PlanSycnFlag__c = newLead.PlanSycnFlag__c == null ? true : !newLead.PlanSycnFlag__c;
                // 2015/12/11 予約取込機能改善（変更、キャンセル） END
                // 特記事項設定[一泊で2部屋以上の自動とりこみ予約のときは、特記事項を一つのみとする]
                //if (j == 0) {
                if(isHadLeadId){
					String commentMessage = newLead.Comment3__c + '<br/>' + warningMsg + bookingInfo.OtherServiceInformation;
					newLead.Comment3__c = CommLogUtils.removeOverLogString(commentMessage,commentLength);
					// メール本文
					newLead.email__c = CommLogUtils.removeOverLogString(risaplBasic.TelegramData + '\n' + CommUtils.nullToBlank(newLead.email__c),emailLength);
					// 2016/10/18 既存の予約情報の部屋は割当済すると、該当部屋タイプと情報は変更なしで対応する BEGIN
					//newLead.Rroom__c = null;
					// 2016/10/18 既存の予約情報の部屋は割当済すると、該当部屋タイプと情報は変更なしで対応する END
					// 2013/06/25 ADD 旅行会社名から予約チャネルに設定する
					// 2016/01/28 ネットからの取込時に予約チャネルに旅行会社名で設定する BEGIN
					//if(CommUtils.isBlank(newLead.Field2__c)) newLead.Field2__c = TraveCompany.size() > 1 ? TraveCompany[1].Name : TraveCompany[0].Name;
					if(CommUtils.isBlank(newLead.Field2__c)) newLead.Field2__c = TraveCompany.size() > 0 ? TraveCompany[0].Name : null;
					// 2016/01/28 ネットからの取込時に予約チャネルに旅行会社名で設定する END
                }else{
                     // 2017/09/01 最大文字数をこえない問題回避対応 BEGIN
                     //newLead.Comment3__c = warningMsg + bookingInfo.OtherServiceInformation;
                     newLead.Comment3__c = CommLogUtils.removeOverLogString(warningMsg + bookingInfo.OtherServiceInformation,commentLength);
                     //newLead.email__c = risaplBasic.TelegramData;
                     newLead.email__c = CommLogUtils.removeOverLogString(risaplBasic.TelegramData,emailLength);
                     // 2017/09/01 最大文字数をこえない問題回避対応 END
                     // 2013/06/25 ADD 旅行会社名から予約チャネルに設定する
                     // 2016/01/28 ネットからの取込時に予約チャネルに旅行会社名で設定する BEGIN
                	 //newLead.Field2__c = TraveCompany.size() > 1 ? TraveCompany[1].Name : TraveCompany[0].Name;
                	 newLead.Field2__c = TraveCompany.size() > 0 ? TraveCompany[0].Name : null;
                	 // 2016/01/28 ネットからの取込時に予約チャネルに旅行会社名で設定する END
                }
                
				// 部屋タイプID
                newLead.refTypeOfRooms__c = roomTypeMap.get(roomAndGuest.room.RoomTypeCode);
                // 2013/02/26 部屋タイプ名：部屋ID情報を格納する
                if (newLead.refTypeOfRooms__c == null ) newLead.refTypeOfRooms__c = roomTypeNmMap.get(roomAndGuest.room.RoomTypeName);
                // 部屋タイプを自動されている場合
                if (newLead.refTypeOfRooms__c != null){
					if(isHadLeadId){
						// 2016/10/18 既存の予約情報の部屋は割当済すると、該当部屋タイプと情報は変更なしで対応する BEGIN
						/*
						// 到着日変更　OR　部屋タイプ変更なしの場合、既にアサイン済部屋はそのまま残り
						if (orgLead.EntryTime__c.date() == newLead.EntryTime__c.date() &&
							orgLead.refTypeOfRooms__c == newLead.refTypeOfRooms__c) {
							newLead.Rroom__c = orgLead.Rroom__c;
						}*/
						// 2016/10/18 既存の予約情報の部屋は割当済すると、該当部屋タイプと情報は変更なしで対応する END
					}
					if (newLead.Rroom__c == null) {
	                    // 部屋自動割り振り機能
	                    if (autoAssingRoomflag) {
							// 2015/10/30 故障部屋は自動割当て機能に追加対応 BEGIN
	                    	/*
	                        String key = j + '_' + newLead.refTypeOfRooms__c;
	                        // 0泊　既存部屋自動割り振
	                        if(lastRoomMap.containsKey(key)) newLead.Rroom__c = lastRoomMap.get(key);
	                        else if (canAssignRoomMap.containsKey(newLead.refTypeOfRooms__c)) {
	                            List<Room__c> canUseRoomLst = canAssignRoomMap.get(newLead.refTypeOfRooms__c);
	                            if (!canUseRoomLst.isEmpty()) {
	                                // 部屋は順次に自動割り振りする
	                                newLead.Rroom__c = canUseRoomLst[0].Id;
	                                canUseRoomLst.remove(0);
	                                lastRoomMap.put(key, newLead.Rroom__c);
	                            }
	                        }*/
	                        if (canAssignRoomMap.containsKey(idx)) {
	                        	newLead.Rroom__c = canAssignRoomMap.get(idx).Id;
	                        }
							// 2015/10/30 故障部屋は自動割当て機能に追加対応 END
	                    }
	                    // 1部屋自動アサイン機能
	                    // 部屋タイプが存在　かつ　対応部屋タイプに対して、１部屋のみの場合、該当部屋は自動的に予約にアサインする BEGIN
	                    else if (oneTypeToRoomMap.containsKey(newLead.refTypeOfRooms__c)) {
	                        newLead.Rroom__c = oneTypeToRoomMap.get(newLead.refTypeOfRooms__c);
	                    }
	                    // 部屋タイプが存在　かつ　対応部屋タイプに対して、１部屋のみの場合、該当部屋は自動的に予約にアサインする END
                    }
                }
                // 旧予約情報を更新する場合、見積明細は変更対象外
                // 新規予約のみ、見積明細を作成する
                if (!isHadLeadId) {
                	//見積もり明細取得
                	roomMaps.put(idx,setEachRoomBookingEstimeteItems(cloneItem,roomAndGuest,taxSericeFee,isRoomRateFlg,curPlan));
                } else {
                	roomMaps.put(idx, new List<BookingEstimateItem__c>());
                }
                //}
                // 2013/07/16 記号機能対応 BEGIN
                // 予約データは親部屋に集めるの場合
                //else 
                if (j > 0 && CommConst.APPOTION_LEADSPLIT_DIV_CODE == CommConst.APPOTION_LEADSPLIT_DIV_CODE_UNION){
                    Integer roomIdx = i * rooms;
                    insLeadLst[roomIdx].StayPersons__c += CommUtils.nullToZero(newLead.StayPersons__c);   
					if (roomMaps.containsKey(idx)) {
                    roomMaps.get(roomIdx).addAll(roomMaps.get(idx));
                    roomMaps.remove(idx);
					}
                    // 代表部屋以外のデータ
                    newLead.StayPersons__c = 0;
                    // 大人人員(男性)
                    insLeadLst[roomIdx].Mans__c += CommUtils.nullToZero(newLead.Mans__c); 
                    newLead.Mans__c = 0;
                    // 大人人員(女性)
                    insLeadLst[roomIdx].Femails__c += CommUtils.nullToZero(newLead.Femails__c); 
                    newLead.Femails__c = 0;
                    // 子供A人数
                    insLeadLst[roomIdx].ChildFA__c += CommUtils.nullToZero(newLead.ChildFA__c); 
                    newLead.ChildFA__c = 0;
                    // 子供B人数
                    insLeadLst[roomIdx].Childs__c += CommUtils.nullToZero(newLead.Childs__c); 
                    newLead.Childs__c = 0;
                    // 子供C人数
                    insLeadLst[roomIdx].ChildC__c += CommUtils.nullToZero(newLead.ChildC__c); 
                    newLead.ChildC__c = 0;
                    // 子供D人数
                    insLeadLst[roomIdx].ChildD__c += CommUtils.nullToZero(newLead.ChildD__c); 
                    newLead.ChildD__c = 0;
                    // プラン情報 <- NULL
                    newLead.Field310__c = null;
                    // コメント
                    newLead.Comment3__c = null;
                }
                // 2013/07/16 記号機能対応 END
                // 旅行会社関連参照情報設定
                newLead.SalesOfficeInfoRef__c = TraveCompany.size() > 1 ? TraveCompany[1].Id : TraveCompany[0].Id;
                // 2012/12/23  Add
                newLead.RoomGroupNo__c = j;//roomNoIdx;
		// 2015/10/30 故障部屋は自動割当て機能に追加対応 BEGIN
                newLead.EventSource__c = APPNAME + '_' + bookingInfo.DataID + '_' + DateTime.now().getTime();
                // 2015/10/30 故障部屋は自動割当て機能に追加対応 END
		// 単価定義区分の設定する
                newLead.UnitPriceDefKb__c = String.valueOf(CommConst.APPOPTION_UTP_DEF_KB);
                //bookingInfo.TaxServiceFee;
                for(String fieldName : finalFieldMap.keySet()){
                    Schema.DescribeFieldResult describeField = finalFieldMap.get(fieldName);
//mLogUtils.write_log('更新内容[' + fieldName + ']::' + describeField.isCreateable() );
//mLogUtils.write_log('更新内容[' + fieldName + ']::' + newLead.get(fieldName));
                    if(newLead.get(fieldName) == null && describeField.isCreateable()){
                    	// デイフォル値を自動設定を行う
                        newLead.put(fieldName,CommUtils.ConvByFielType(autoSetupfieldMap.get(fieldName), describeField.getType()));
                    	//mLogUtils.write_log('更新内容[' + fieldName + ']:1:' + fieldMap.get(fieldName) );
                        mLogUtils.write_log('項目値自動設定[' + fieldName + ']:1:' + newLead.get(fieldName) );
                    }
                }
                insLeadLst.add(newLead);
            }
        }
        // 見積り金額設定を行う「一件のみ設定する」
        insLeadLst[0].BridalDantaikei__c = bookingInfo.TotalAccommodationCharge;
        //update モード
        List<Lead__c> updLeadLst = new List<Lead__c>();
        for(integer key : groupLeadMap.keySet()){
            List<Lead__c> childLst = groupLeadMap.get(key);
            if(childLst != null){
                for(integer i = 0 ; i < childLst.size(); i++){
                    String setKey = key + '_' + i;
                    if(!userOrgLeadSet.contains(setKey)){
                        childLst.get(i).ReservedStatus__c = CommConst.LEAD_ST_CANCEL;
                        updLeadLst.add(childLst.get(i));
                    }
                }
            }
        }
        // 2017/05/04 店舗ごとの予約・会計権限機能対応 BEGIN
		CommLogicProcess logic = new CommLogicProcess();
		// 自動キャンセルされるデータのフラグはチェック対象外に設定する
		logic.preventShopAuthCheckSetup(updLeadLst);
		// 新規登録・変更対象データはチェック対象外に設定する
		logic.preventShopAuthCheckSetup(insLeadLst);
		// 2017/05/04 店舗ごとの予約・会計権限機能対応 END
        // 電文から作成の予約に対して、変更後の予約情報の泊数対象外の予約はキャンセルに更新を行う
        update updLeadLst;
        // 2012/12/22 WSQ ADD
        // SUBINDEX自動作成
        // 2017/05/04 店舗ごとの予約・会計権限機能対応 BEGIN
        //CommLogicProcess logic = new CommLogicProcess();
        // 2017/05/04 店舗ごとの予約・会計権限機能対応 END
        logic.autoCreateIndexSub(insLeadLst);
        upsert insLeadLst;
        List<BookingEstimateItem__c> lastInsItems = new List<BookingEstimateItem__c>();
        List<Id> leadIds = new List<Id>();
        for(integer i = 0; i < insLeadLst.size(); i++){
            Lead__c insLead = insLeadLst[i];
            if(roomMaps.containsKey(i)){
                // X泊Y部屋の見積明細情報の予約IDを自動設定を行う
                List<BookingEstimateItem__c> insLst = roomMaps.get(i);
                for(BookingEstimateItem__c bookingItem : insLst){
                    bookingItem.refBooking__c = insLead.id;
                    lastInsItems.add(bookingItem);
                }
            }
            // 新規予約の場合
            if (!updateOrgLeadIdSet.contains(insLead.id))
            	leadIds.add(insLead.id);
        }
        // 2017/04/13 Sobject Security Check BEGIN
		if (CommSecurityUtils.isDeleteable(BookingEstimateItem__c.getSObjectType())) {
		// 2017/04/13 Sobject Security Check END	
        // ご予約のプラン項目から自動作成の見積明細を全部削除する
        delete [select id,name from BookingEstimateItem__c where refBooking__c =:leadIds and ParentBookingItemRef__c = null];
        delete [select id,name from BookingEstimateItem__c where refBooking__c = :leadIds ];
		// 2016/06/17 取り込みの見積明細の順番は調整対応
		// 2017/04/13 Sobject Security Check BEGIN
		}
		// 2017/04/13 Sobject Security Check END
		//if(!lastInsItems.isEmpty()){
        //    insert lastInsItems;
        //}
		// 変更の場合、支払情報は更新を行わない
		if (updateOrgLeadIdSet.isEmpty()) {
	        //見積もり明細　オプション作成する
	        // 2017/08/15 option数据根据单价定义区分计算 fix BEGIN
	        //lastInsItems.addAll(upsertBookingEstimeteItemsByEach(bookingInfo,insLeadLst[0]));
	        lastInsItems.addAll(upsertBookingEstimeteItemsByEach(bookingInfo,insLeadLst[0],taxSericeFee));
	        // 2017/08/15 option数据根据单价定义区分计算 fix END
	        //見積もり明細：支払い作成「ポイント・支払い」
	        lastInsItems.addAll(upsertPaymentBookingExtimeItem(insLeadLst[0],bookingInfo));
		}
		// 2016/06/09 取り込みの見積明細の順番は調整対応 BEGIN
		(new CommLogicProcess()).sync2wayEstRowNoSetup(insLeadLst, lastInsItems);
		// 2016/06/09 取り込みの見積明細の順番は調整対応 END 
        // 2017/05/04 店舗ごとの予約・会計権限機能対応 BEGIN
		List<Lead__c> restoreLeads = new List<Lead__c>();
		restoreLeads.addAll(updLeadLst);
		restoreLeads.addAll(insLeadLst);
		logic.restoreShopAuthCheckSetup(restoreLeads, true);
		// 2017/05/04 店舗ごとの予約・会計権限機能対応 END
        mLogUtils.write_method_end();
    }

    // プラン明細に室料するがどうか判断ロジック
    private static Boolean isRoomRateItem(AccountMaster__c acc) {
        return RackRateUtils.isRoomRateProduct(acc);
    }
    
    // ポイント、売掛金、カードなど事前支払情報は見積明細に反映を行う
    private List<BookingEstimateItem__c> upsertPaymentBookingExtimeItem(Lead__c lead,BI_EMAIL_SyncInfo bookingInfo){
        mLogUtils.write_method_start('upsertPaymentBookingExtimeItem');
        BI_EMAIL_Risaplsinformation risaplsinformation = bookingInfo.risaplsinformation;
        // 合計宿泊料金(総額)
        Decimal totalPrice = bookingInfo.TotalAccommodationCharge;
        BI_EMAIL_BasicRate basicRate = risaplsinformation.risaplsCommonInformation.basicRate;
        BI_EMAIL_Member member = risaplsinformation.risaplsCommonInformation.member;
        BillSimpleHelp help = new BillSimpleHelp(shopCd);
        // ポイント合計金額格納
        Decimal pointAmount = 0;
        // 新規追加プランデータ存在する場合
        List<BookingEstimateItem__c> insLst = new List<BookingEstimateItem__c>();
        // ポイント支払情報格納する
        List<BookingEstimateItem__c> pointLst = new List<BookingEstimateItem__c>();
 		 mLogUtils.write_log(' basicRate:' +  basicRate);
        if(basicRate != null) {
        	// 2016/03/28 じゃらんAGTのポイントとクーポンをそれそのまま取り込み対応 BEGIN
            set<string> pointNmSet = new set<string>();
           
            for (EmailMessageToLeadSync.BI_EMAIL_PointsDiscountInfo pointsInfo : basicRate.pointsDiscountLst) {
                if(pointsInfo.PointsDiscount <= 0) continue;
                pointNmSet.add(pointsInfo.PointsDiscountName);
            }
            // map<ポイント名,会計商品（支払）
            map<string, AccountMaster__c> pointAccMap = new map<string, AccountMaster__c> (); 
            if (!pointNmSet.isEmpty()) {
            	for (AccountMaster__c acc : [ Select Id, Name, Field3__c, PaymentType__c From AccountMaster__c where name in :pointNmSet]) {
            		pointAccMap.put(acc.Name, acc);
            	}
            }
            /// 2016/03/28 じゃらんAGTのポイントとクーポンをそれそのまま取り込み対応 END
            for (EmailMessageToLeadSync.BI_EMAIL_PointsDiscountInfo pointsInfo : basicRate.pointsDiscountLst) {
                //BI_EMAIL_PointsDiscountInfo pointsInfo = basicRate.pointsDiscountLst.get(i);
                if(pointsInfo.PointsDiscount <= 0) continue;
                mLogUtils.write_log('BASIC POINT::' + pointsInfo);
                // 2016/03/28 じゃらんAGTのポイントとクーポンをそれそのまま取り込み対応 BEGIN
                //pointLst.add(new BookingEstimateItem__c (
                BookingEstimateItem__c est = new BookingEstimateItem__c (
                 // 2016/03/28 じゃらんAGTのポイントとクーポンをそれそのまま取り込み対応 END
                  refBooking__c = lead.id,
                  ProductName__c = pointsInfo.PointsDiscountName,
                  UnitPrice__c = pointsInfo.PointsDiscount,
                  Amount__c = 1
                // 2016/03/28 じゃらんAGTのポイントとクーポンをそれそのまま取り込み対応 BEGIN
                );
               
                if (pointAccMap.containsKey(pointsInfo.PointsDiscountName)) {
                	AccountMaster__c pointAcc = pointAccMap.get(pointsInfo.PointsDiscountName);
                    est.refAccountMaster__c = pointAcc.Id;
                    est.refAccountMaster__r = pointAcc;
                }
                pointLst.add(est);
                // 2016/03/28 じゃらんAGTのポイントとクーポンをそれそのまま取り込み対応 END
                
                pointAmount += pointsInfo.PointsDiscount;
            }
        }
        // basicRateにポイント支払情報が未設定する場合   
        if(member != null && pointLst.isEmpty()){
            Decimal UserUsePoints = CommUtils.nullToZero(member.UserUsePoints);
            if(UserUsePoints > 0){
                mLogUtils.write_log('MEMBER POINT::' + UserUsePoints);
                pointLst.add(new BookingEstimateItem__c (
                  refBooking__c = lead.id,
                  UnitPrice__c = UserUsePoints,
                  Amount__c = 1
                ));
                pointAmount += UserUsePoints;
            }
        }
// 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う BEGIN
		String settlementDiv = null;
		if (risaplsinformation.agentNativeInformation != null && risaplsinformation.agentNativeInformation.extendmytrip != null) {
			Integer intSettlementDiv = risaplsinformation.agentNativeInformation.extendmytrip.SettlementDiv;
			if (intSettlementDiv != null && intSettlementDiv != 0) settlementDiv = Commutils.nullToBlank(intSettlementDiv);
		}
		String agtCode = CommUtils.nullToBlank(bookingInfo.SalesOfficeCompanyCode);
		list<string> equalKeyLst = getEqualsKeyLst(settlementDiv, agtCode);
 		map<string, AccountMaster__c> payProductIdMap = new map<String, AccountMaster__c>();
 		map<String, EmailMessageToLeadHelp.PAYMENT_CONVERT> paymentConfigMap = EmailMessageToLeadHelp.getPaymentConfig(shopCd);
 		map<String, EmailMessageToLeadHelp.PAYMENT_CONVERT> pointConfigMap = EmailMessageToLeadHelp.getPointConfig(shopCd);
    	list<string> productCdlst = new list<string>();
    	for (EmailMessageToLeadHelp.PAYMENT_CONVERT parserPay : paymentConfigMap.values()) {
    		productCdlst.add(parserPay.payProdCode);
    	}
    	for (EmailMessageToLeadHelp.PAYMENT_CONVERT parserPay : pointConfigMap.values()) {
    		productCdlst.add(parserPay.payProdCode);
    	}
    	if (!productCdlst.isEmpty()) {
    		payProductIdMap = EmailMessageToLeadHelp.getPaymentProductId(productCdlst);
    	}
// 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う END
        // ポイント支払情報が存在する場合
        if (pointAmount>0) {
            // ポイント支払メデイア情報を取得する
            AccountMaster__c pointAcc = help.getMediaLabToAccMstMap().get(help.getPaymentTypeToMediaLabMap().get(CommConst.PROD_PAY_TYPE_DIS_PRICE));
            if (pointAcc != null) {
                for (BookingEstimateItem__c est : pointLst) {
                	// 2016/03/28 じゃらんAGTのポイントとクーポンをそれそのまま取り込み対応 BEGIN
                	if (est.refAccountMaster__c != null) continue;
                	// 2016/03/28 じゃらんAGTのポイントとクーポンをそれそのまま取り込み対応 END
// 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う BEGIN
                	AccountMaster__c covertAcc = null;
                	for (String key : equalKeyLst) {
mLogUtils.write_log('割引MATCH:' + KEY + '=' + pointConfigMap.containsKey(key));
                		if (pointConfigMap.containsKey(key)) {
                			EmailMessageToLeadHelp.PAYMENT_CONVERT convertInf = pointConfigMap.get(key);
                			covertAcc = payProductIdMap.get(convertInf.payProdCode);
                			break;
                		}
                	}
                	// 指定の割当
                    est.refAccountMaster__c = covertAcc == null ? pointAcc.Id : covertAcc.Id;
                    est.refAccountMaster__r = covertAcc == null ? pointAcc : covertAcc;
// 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う END
                }
            }
            if (!pointLst.isEmpty()) insLst.addAll(pointLst);
        }
        // 事前決済区分により、支払情報の作成
        if(risaplsinformation.agentNativeInformation != null){
            BI_EMAIL_Extendmytrip trip = risaplsinformation.agentNativeInformation.extendmytrip;
// 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う BEGIN
            AccountMaster__c commAcc = null;
    		for (String key : equalKeyLst) {
mLogUtils.write_log('事前決済MATCH:' + KEY + '=' + paymentConfigMap.containsKey(key));
        		if (paymentConfigMap.containsKey(key)) {
        			EmailMessageToLeadHelp.PAYMENT_CONVERT convertInf = paymentConfigMap.get(key);
					commAcc = payProductIdMap.get(convertInf.payProdCode);
					break;
        		}
        	} 
// 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う END
            // 事前決済区分「0」:指定なし、「1」:法人利用、「2」:カード決済ズミ、「3」:現地払い、 「4」:ツアー会社、「5」:一部精算、「6」:エージェント精算
            if(trip != null && trip.SettlementDiv != 0){
                // 「1」:法人利用 「4」:ツアー会社 「6」:エージェント精算 →　売掛金
                if(trip.SettlementDiv == 1 || trip.SettlementDiv == 4 || trip.SettlementDiv == 6){
// 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う
                    if (commAcc == null)
                    commAcc = help.getMediaLabToAccMstMap().get(CommConst.MEDIA_TYPE_03);
                }
                // 「2」:カード決済ズミ →カード
                else if ( trip.SettlementDiv == 2){
// 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う
                    if (commAcc == null)
                    commAcc = help.getMediaLabToAccMstMap().get(help.getPaymentTypeToMediaLabMap().get(CommConst.PROD_PAY_TYPE_CARD));
                }
            }
            mLogUtils.write_log('事前決済区分:['+trip.SettlementDiv+']' + commAcc);
            // 支払情報の作成
            if(commAcc != null){
                // 割引金額は総金額から外す
                totalPrice -= pointAmount;
                // 支払情報作成する
                insLst.add(new BookingEstimateItem__c (
                    refAccountMaster__c = commAcc.id,
                    refBooking__c = lead.id,
                    Amount__c = 1,
                    UnitPrice__c = totalPrice
                ));
            }
        }
        // 割引、支払情報を新規作成する
        //if(!insLst.isEmpty()) insert insLst;
        mLogUtils.write_method_end();
        return insLst;
    }
    private list<String> getEqualsKeyLst (String settlementDiv, String agtCode) {
    	List<String> equalKeyLst = new List<String>{
    		CommUtils.nullToBlank(settlementDiv) + '_' + CommUtils.nullToBlank(agtCode),
    		CommUtils.nullToBlank(settlementDiv) + '_',
    		'_' + CommUtils.nullToBlank(agtCode),
    		'_'
    	};
    	set<string> filterSet = new set<String>();
    	for (Integer i =0; i < equalKeyLst.size(); i++) {
    		if (filterSet.contains(equalKeyLst[i])) equalKeyLst.remove(i);
    		filterSet.add(equalKeyLst[i]);
    	}
    	return equalKeyLst;
    }
    
    // 指定部屋、指定日の見積明細情報を登録する
    // item:該当日の予約の見積明細作成元
    // 
    // 
    private List<BookingEstimateItem__c> setEachRoomBookingEstimeteItems(   BookingEstimateItem__c item, 
                                                                            BI_EMAIL_RoomAndGuestInfo roomAndGuest,
                                                                            Integer taxSericeFee,
                                                                            Boolean isRoomRateFlg,
                                                                            Plan__c curPlan){
        mLogUtils.write_method_start('setEachRoomBookingEstimeteItems');
mLogUtils.write_log('BookingEstimateItem__c:' + item);
mLogUtils.write_log('roomAndGuest:' + roomAndGuest);
mLogUtils.write_log('taxSericeFee:' + taxSericeFee);
mLogUtils.write_log('isRoomRateFlg:' + isRoomRateFlg);
mLogUtils.write_log('curPlan:' + curPlan);
        List<BI_EMAIL_RoomRateInfomation> roomRateLst = roomAndGuest.roomRateLst;
        List<BookingEstimateItem__c> detailLst = new List<BookingEstimateItem__c>();
        if (item == null) return detailLst;
        // 料金設定情報がありません
        if (roomRateLst.isEmpty()) return detailLst;
        // 人員単価金額で総計利用金額を計算を行う
        BI_EMAIL_RoomsInfo room = roomAndGuest.room;
        // 宿泊者タイプの総人数
        Integer roomPaxMalCount = room.RoomPaxMaleCount ;       // 男性人数
        integer roomPaxFemaleCount = room.RoomPaxFemaleCount;   // 女性人数
        integer roomChildACount = room.RoomChildA70Count;       // 子供A人数
        integer roomChildBCount = room.RoomChildB50Count;       // 子供B人数
        integer roomCHildCCount = room.RoomChildC30Count;       // 子供C人数
        integer roomChildDCount = room.RoomChildDNoneCount;     // 子供D人数
        Map<String,BookingEstimateItem__c> itemMap = new Map<String,BookingEstimateItem__c>();
        boolean lastRateFlag = roomRateLst.size() == 1;

        //mLogUtils.write_log('料金区分は室単位判別::' + isRoomRateFlg);
        // 室単価の場合、総利用料金はプラン/室料に設定を行う
        if (!isRoomRateFlg) {
            Integer roomRateLen = roomRateLst.size();
            // 同じ宿泊者タイプ違うの金額の場合、後ろから利用金額を１単位で合計を行う
            for (Integer i = (roomRateLen -1); i >= 0; i--) {
                BI_EMAIL_RoomRateInfomation roomRate = roomRateLst[i];
                if(i == 0) lastRateFlag = true;
                //mLogUtils.write_log('roomRate::' + roomRate);
                if(roomPaxMalCount > 0 && roomRate.PerPaxRate != null){
                    integer perAddAmount = 1;
                    BookingEstimateItem__c newItem = item.clone(false,true);
                    newItem.UnitPrice__c = roomRate.PerPaxRate;
                    String key = 'PaxMalCount_' + newItem.UnitPrice__c;
                    if(lastRateFlag) perAddAmount = roomPaxMalCount;
                    if(itemMap.containsKey(key))
                        itemMap.get(key).Amount__c += perAddAmount;
                    else {
                        newItem.Amount__c = perAddAmount;
                        itemMap.put(key,newItem);
                    }
                    roomPaxMalCount--;
                }
                if(roomPaxFemaleCount > 0 && roomRate.PerPaxRate != null){
                    integer perAddAmount = 1;
                    BookingEstimateItem__c newItem = item.clone(false,true);
                    newItem.UnitPrice__c = roomRate.PerPaxRate;
                    String key = 'PaxFemaleCount_' + newItem.UnitPrice__c;
                    if(lastRateFlag) perAddAmount = roomPaxFemaleCount;
                    if(itemMap.containsKey(key))
                        itemMap.get(key).Amount__c += perAddAmount;
                    else {
                        newItem.Amount__c = perAddAmount;
                        itemMap.put(key,newItem);
                    }
                    roomPaxFemaleCount--;
                }
                if(roomChildACount > 0 && roomRate.PerChildA70Rate != null){
                    integer perAddAmount = 1;
                    BookingEstimateItem__c newItem = item.clone(false,true);
                    newItem.UnitPrice__c = roomRate.PerChildA70Rate;
                    String key = 'ChildACount_' + newItem.UnitPrice__c;
                    if(lastRateFlag) perAddAmount = roomChildACount;
                    if(itemMap.containsKey(key))
                        itemMap.get(key).Amount__c += perAddAmount;
                    else {
                        newItem.Amount__c = perAddAmount;
                        itemMap.put(key,newItem);
                    }
                    roomChildACount--;
                }
                if(roomChildBCount > 0 && roomRate.PerChildB50Rate != null){
                    integer perAddAmount = 1;
                    BookingEstimateItem__c newItem = item.clone(false,true);
                    newItem.UnitPrice__c = roomRate.PerChildB50Rate;
                    String key = 'ChildBCount_' + newItem.UnitPrice__c;
                    if(lastRateFlag) perAddAmount = roomChildBCount;
                    if(itemMap.containsKey(key))
                        itemMap.get(key).Amount__c += perAddAmount;
                    else {
                        newItem.Amount__c = perAddAmount;
                        itemMap.put(key,newItem);
                    }
                    roomChildBCount--;
                }
                if(roomCHildCCount > 0 && roomRate.PerChildC30Rate != null){
                    integer perAddAmount = 1;
                    BookingEstimateItem__c newItem = item.clone(false,true);
                    newItem.UnitPrice__c = roomRate.PerChildC30Rate;
                    String key = 'CHildCCount_' + newItem.UnitPrice__c;
                    if(lastRateFlag) perAddAmount = roomCHildCCount;
                    if(itemMap.containsKey(key))
                        itemMap.get(key).Amount__c += perAddAmount;
                    else {
                        newItem.Amount__c = perAddAmount;
                        itemMap.put(key,newItem);
                    }
                    roomCHildCCount--;
                }
                if(roomChildDCount > 0 && roomRate.PerChildDRate != null){
                    integer perAddAmount = 1;
                    BookingEstimateItem__c newItem = item.clone(false,true);
                    newItem.UnitPrice__c = roomRate.PerChildDRate;
                    String key = 'ChildDCount_' + newItem.UnitPrice__c;
                    if(lastRateFlag) perAddAmount = roomChildDCount;
                    if(itemMap.containsKey(key))
                        itemMap.get(key).Amount__c += perAddAmount;
                    else {
                        newItem.Amount__c = perAddAmount;
                        itemMap.put(key,newItem);
                    }
                    roomChildDCount--;
                }
            }
            // 利用金額同じする場合、合流判定用マイプ
            Map<Decimal,BookingEstimateItem__c> itemPriceMap = new Map<Decimal,BookingEstimateItem__c>();
            //mLogUtils.write_log('itemMap:::' + itemMap);
            for(String key : itemMap.keySet()){
                BookingEstimateItem__c bookingItem = itemMap.get(key);
                Decimal orgUnitPrice = bookingItem.UnitPrice__c;
                if(!itemPriceMap.containsKey(orgUnitPrice)){
                    itemPriceMap.put(orgUnitPrice,bookingItem);
                    detailLst.add(bookingItem);
                }else{
                    BookingEstimateItem__c preBookingItem = itemPriceMap.get(orgUnitPrice);
                    preBookingItem.Amount__c += bookingItem.Amount__c;
                }
            }
        } 
        // 2015/12/14 RoomRateの場合、プラン室料自動設定機能を追加する BEGIN
        else if(isRoomRateFlg){
        	for(BI_EMAIL_RoomRateInfomation roomRate : roomRateLst){
                BookingEstimateItem__c newItem = item.clone(false,true);
                newItem.UnitPrice__c = roomRate.TotalPerRoomRate != null ? roomRate.TotalPerRoomRate : roomRate.PerPaxRate;
                newItem.Amount__c = 1;
                detailLst.add(newItem);
        	}
		}
		// 2015/12/14 RoomRateの場合、プラン室料自動設定機能を追加する END
//mLogUtils.write_log('detailLst：' + detailLst); 
        // 単価定義区分変換処理を行う
        for(BookingEstimateItem__c bookingItem : detailLst){
        	
            mLogUtils.write_log('利用金額「変更前」(区分'+taxSericeFee+')：' + bookingItem.UnitPrice__c);
            // Local変換前の利用金額を格納する
            Decimal orgEstUnitPrice = bookingItem.UnitPrice__c;
            // 2019/09/15 軽減税率機能対応 WGCH BEGIN
            orgEstUnitPriceEnd = orgEstUnitPrice;
            // 2019/09/15 軽減税率機能対応 WGCH END
            
            // 税区分変更をお行う「XMLに指定の税区分→SF側の税区分に変更」
            bookingItem.UnitPrice__c = CommUtils.convertPriceByTaxKbn(  orgEstUnitPrice,
                                                                        item.refAccountMaster__r.jmstRef__r.TaxRate__c,
                                                                        item.refAccountMaster__r.ServiceRate__c, 
                                                                        taxSericeFee, 
                                                                        CommConst.APPOPTION_UTP_DEF_KB);
            // 小数桁数の再確認
            bookingItem.UnitPrice__c = checkIfHadScale(bookingItem.UnitPrice__c, 
            										   item.refAccountMaster__r.jmstRef__r.TaxRate__c, 
													   item.refAccountMaster__r.ServiceRate__c,  
													   CommConst.APPOPTION_UTP_DEF_KB); 
            mLogUtils.write_log('利用金額「変更後」(区分'+CommConst.APPOPTION_UTP_DEF_KB+')：' + bookingItem.UnitPrice__c);
            // 2019/09/15 軽減税率機能対応 WGCH BEGIN
            Decimal estUnitPriceEnd = bookingItem.UnitPrice__c;
            // 2019/09/15 軽減税率機能対応 WGCH END

            // プラン明細の金額自動配分を行う[プランかつプラン明細存在の場合、配分処理を行う]
            if (planDetailInf.isHavePdData) {
                // 利用金額からSF側の単価定義区分と一致の利用金額を変換する
                // 変換後のSF側の利用金額
                Decimal curnPayPrice = bookingItem.UnitPrice__c;
                // SF側のプラン金額（単価）
                Decimal orgPlanPrice = curPlan.Price__c;
                // 非課税商品が存在する場合、利用金額は税込み、サビース料金計算後の金額を計算する
                if (planDetailInf.priceNoTaxSumVal > 0) {
                	mLogUtils.write_log('非課税商品あり：金額：' + planDetailInf.priceNoTaxSumVal);
                    // サビース料込合計金額を計算する[単価定義区分２に変更]
                    Decimal noTaxIncServiceSummary = CommUtils.convertPriceByTaxKbn(planDetailInf.priceNoTaxSumVal, 0, curPlan.ServiceRate__c, taxSericeFee, CommConst.APPOPTION_UTP_DEF_KB_OP2);
                    // XMLから利用金額により、サビース込、税込み金額を計算を行う[XMLの税区分から単価定義区分２に変更]
                    Decimal incTaxSerUnitPrice = CommUtils.convertPriceByTaxKbn(orgEstUnitPrice,
                                                                            item.refAccountMaster__r.jmstRef__r.TaxRate__c,
                                                                            item.refAccountMaster__r.ServiceRate__c, 
                                                                            taxSericeFee, 
                                                                            CommConst.APPOPTION_UTP_DEF_KB_OP2);
                    mLogUtils.write_log('利用金額はサ込、消費税込計算後金額：' + incTaxSerUnitPrice);
                    // 利用金額から非課税商品総金額を抜いて、SF側に定義の単価定義区分に変換を行う
                    curnPayPrice = CommUtils.convertPriceByTaxKbn(incTaxSerUnitPrice - noTaxIncServiceSummary,
                                                                            item.refAccountMaster__r.jmstRef__r.TaxRate__c,
                                                                            item.refAccountMaster__r.ServiceRate__c, 
                                                                            CommConst.APPOPTION_UTP_DEF_KB_OP2, 
                                                                            CommConst.APPOPTION_UTP_DEF_KB);
            		// 小数桁を再調整を行う
            		curnPayPrice = checkIfHadScale(curnPayPrice, 
            										   item.refAccountMaster__r.jmstRef__r.TaxRate__c, 
													   item.refAccountMaster__r.ServiceRate__c,  
													   CommConst.APPOPTION_UTP_DEF_KB); 
                    // プラン元金額から非課税金額を外す
                    orgPlanPrice = orgPlanPrice - planDetailInf.priceNoTaxSumVal;
                    // 2019/09/15 軽減税率機能対応 WGCH BEGIN
                    	// プラン元金額から非課税金額を外す
                    	if(isReducedTaxFlg){
                    		curnPayPrice = CommUtils.nullToZero(estUnitPriceEnd) - CommUtils.nullToZero(planDetailInf.priceNoTaxSumValEnd);
                    		orgPlanPrice = CommUtils.nullToZero(planDetailInf.curnPayPriceEnd);
                    	}
                    // 2019/09/15 軽減税率機能対応 WGCH END
                    
                    mLogUtils.write_log('元のプラン金額は調整後：' + orgPlanPrice);
                    mLogUtils.write_log('元の利用金額は調整後：' + curnPayPrice);
                }
                // 2019/09/15 軽減税率機能対応 WGCH BEGIN
                else if(isReducedTaxFlg){
                	curnPayPrice = CommUtils.nullToZero(estUnitPriceEnd) - CommUtils.nullToZero(planDetailInf.priceNoTaxSumValEnd);
                	orgPlanPrice = CommUtils.nullToZero(planDetailInf.curnPayPriceEnd);
                }
                // 2019/09/15 軽減税率機能対応 WGCH END
                // 課税商品の最小利用金額＞既存プランの利用金額の場合、該当プランのタイトルのみ作成する[見積明細は普通な商品として、登録を行う]
                // その後、注意事項に説明を追加する（TODO）
                //if (orgPlanPrice > curnPayPrice) {
                //mLogUtils.write_log('調整金額はプラン標準金額により少ない：プラン金額:' + orgPlanPrice + ' 支払金額:'+curnPayPrice);
                    //bookingItem.ActionType__c = CommConst.PROD_ACTION_TYPE_NR;
                  //  bookingItem.PlanDetailSyncInfo__c = CommConst.CONST_PLANITEM_NOEXPAND;
                //} else {
                    // プラン明細の金額自動配分を行う[課税商品明細のみ]
               	if (orgPlanPrice != curnPayPrice) bookingItem.PlanDetailSyncInfo__c = getPlanDetailSyncInfo(orgPlanPrice,curnPayPrice);
                //}
                mLogUtils.write_log('プラン明細個別設定情報 ：' + bookingItem.PlanDetailSyncInfo__c);
            }
        }
        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
        if(ldInfo != null){
        	detailLst = ProductItemUtils.getNwDetailLst(detailLst, ldInfo);
        }
        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
        for(BI_EMAIL_RoomRateInfomation roomRate : roomRateLst){
            // 室料の場合
            /* 2015/12/14 RoomRateの場合、プラン室料自動設定機能を追加する 場所移動
            if(isRoomRateFlg){
                BookingEstimateItem__c newItem = item.clone(false,true);
                newItem.UnitPrice__c = CommUtils.convertPriceByTaxKbn(  roomRate.TotalPerRoomRate != null ? roomRate.TotalPerRoomRate : roomRate.PerPaxRate,
                                                                        item.refAccountMaster__r.jmstRef__r.TaxRate__c,
                                                                        item.refAccountMaster__r.ServiceRate__c, 
                                                                        taxSericeFee, 
                                                                        CommConst.APPOPTION_UTP_DEF_KB);
                newItem.UnitPrice__c = checkIfHadScale(newItem.UnitPrice__c, 
            										   item.refAccountMaster__r.jmstRef__r.TaxRate__c, 
													   item.refAccountMaster__r.ServiceRate__c,  
													   CommConst.APPOPTION_UTP_DEF_KB); 
                newItem.Amount__c = 1;
                detailLst.add(newItem);
            }*/
            // 入湯税の場合
            if(roomRate.TotalRoomHotSpringTax > 0 && nyuuTouAcc.id != null && roomRate.TotalRoomHotSpringTax != null){
                Integer roomHotSpringCount = 1;
                Decimal unitPrice = roomRate.TotalRoomHotSpringTax;
                if(nyuuTouAcc.Field5__c != null && nyuuTouAcc.Field5__c != 0 ){
                    decimal resultCount = roomRate.TotalRoomHotSpringTax/nyuuTouAcc.Field5__c;
                    if(resultCount.stripTrailingZeros().scale() == 0 ){
                        roomHotSpringCount = integer.valueOf(resultCount);
                        unitPrice = nyuuTouAcc.Field5__c;
                    }
                }
                detailLst.add(new BookingEstimateItem__c(
                    refAccountMaster__c = nyuuTouAcc.id,
                    UnitPrice__c = CommUtils.convertPriceByTaxKbn(  unitPrice,
                                                                    nyuuTouAcc.TaxRateCal__c,
                                                                    nyuuTouAcc.ServiceRate__c, 
                                                                    taxSericeFee, 
                                                                    CommConst.APPOPTION_UTP_DEF_KB),
                    refAccountMaster__r = nyuuTouAcc,
                    Amount__c = roomHotSpringCount
                ));
            }
            // サビース料金場合
            if(roomRate.TotalPerRoomServiceFee > 0 && serviceAcc.id != null && roomRate.TotalPerRoomServiceFee != null){
                BookingEstimateItem__c newItem = 
                	new BookingEstimateItem__c(
	                    refAccountMaster__c = serviceAcc.id,
	                    refAccountMaster__r = serviceAcc,
	                    UnitPrice__c = CommUtils.convertPriceByTaxKbn(  roomRate.TotalPerRoomServiceFee,
	                                                                    serviceAcc.TaxRateCal__c,
	                                                                    serviceAcc.ServiceRate__c, 
	                                                                    taxSericeFee, 
	                                                                    CommConst.APPOPTION_UTP_DEF_KB),
	                    
	                    Amount__c = 1
	            	);
                newItem.UnitPrice__c = checkIfHadScale(newItem.UnitPrice__c, 
            										   serviceAcc.TaxRateCal__c,
													   serviceAcc.ServiceRate__c, 
													   CommConst.APPOPTION_UTP_DEF_KB); 
                detailLst.add(newItem);
            }
        }
        mLogUtils.write_method_end();
        return detailLst;
        
    }

    /*
    private BI_FILTER_STATUS filterDetailByConfig(AccountMaster__c acc){
        for(EmailMessageToLeadHelp.Item excludeItem : bookingConfig.excludeLst){
            if(!CommUtils.isBlank(excludeItem.fieldName)){
                for(String value : excludeItem.values){
//mLogUtils.write_log('excludeItem['+value+']：' + getFieldValue(acc,excludeItem.fieldName)); 
                    if(getFieldValue(acc,excludeItem.fieldName) == value) return BI_FILTER_STATUS.EXCLUDE;
                }
            }
        }
        for(EmailMessageToLeadHelp.Item includeItem : bookingConfig.includeLst){
            if(!CommUtils.isBlank(includeItem.fieldName)){
                for(String value : includeItem.values){
//mLogUtils.write_log('includeItem['+value+']：' + getFieldValue(acc,includeItem.fieldName)); 
                    if(getFieldValue(acc,includeItem.fieldName) == value) return BI_FILTER_STATUS.INCLUDE;
                }
            }
        }
        return BI_FILTER_STATUS.OTHER;
    }*/
    // プラン関連のプラン明細の単価定義情報の取得する
    // 設定書式：プラン明細ID:単価:会計商品ID:会計商品名;
    private String getPlanDetailSyncInfo(Decimal orgUnitPrice,Decimal curUnitPrice){
        mLogUtils.write_method_start('getPlanDetailSyncInfo');
        mLogUtils.write_log('プラン標準金額[非課税外す]：' + orgUnitPrice);
        mLogUtils.write_log('今回課税商品金額合計：' + curUnitPrice);
        // 残金額が存在する場合、自動配分　OR　配分なし
        //BI_BOOKING_MODE bookingMode = bookingConfig.mode == '1' ? BI_BOOKING_MODE.DEF : BI_BOOKING_MODE.STOP;
        // プラン明細金額調整明細情報を格納する
        String planDetailSyncInfo = '';
          
		// 明細単価の合計値はプランの利用金額差異が存在する場合、明細に自動配分する
        Decimal diffUnit = (curUnitPrice - orgUnitPrice);
        // 減算する場合、減算可能の金額と減算必要な金額をチェックする
        if (diffUnit < 0) {
        	Decimal canChangePrice = orgUnitPrice - planDetailInf.priceNotChangeSumVal;
        	// 減算可能の金額は調整減算必要の金額により、すぐない場合、調整不可で判断する、直接戻る
        	if (canChangePrice < diffUnit) {
        		mLogUtils.write_log('減算可能金額['+orgUnitPrice+']は減算必要な金額['+curUnitPrice+']により、すくないので、配分なし');
        		mLogUtils.write_method_end();
        		return CommConst.CONST_PLANITEM_NOEXPAND;
        	}
        	else {
        		// プラン調整可能金額を再設定を行う
        		orgUnitPrice = canChangePrice;
        	}
        }
        // -----------------------
        // 金額調整を行う
        // -----------------------
        List<PlanDetail__c> roomPdList = planDetailInf.getClonePriceRoomPdList();
        //List<PlanDetail__c> otherPdList = planDetailInf.getClonePriceCanChangeOthPdList();
        map<Id, PlanDetail__c> changePdMap = new map<Id,PlanDetail__c>();
        for (PlanDetail__c pd : roomPdList) {
        	changePdMap.put(pd.id, pd);
        } 
        //for (PlanDetail__c pd : otherPdList) {
        	//changePdMap.put(pd.id, pd);
        //}
//mLogUtils.write_log('roomPdList:' + roomPdList);
//mLogUtils.write_log('otherPdList:' + otherPdList);
//mLogUtils.write_log('changePdMap:' + changePdMap);
 		// 調整必要の差分金額
        Decimal diffUnitSum = diffUnit;
        // 室料明細が存在する場合、室料明細に金額調整を行う
        if (!roomPdList.isEmpty()) {
        	mLogUtils.write_log('室料明細調整前差分金額：' + diffUnit);
        	diffUnitSum = divisionPlanDetailUnitPrice(orgUnitPrice, roomPdList, diffUnit, false);
        	mLogUtils.write_log('室料明細調整後差分金額：' + diffUnitSum);
        }
        // 調整不可になる
        if (diffUnitSum != 0 ) return CommConst.CONST_PLANITEM_NOEXPAND;
        //&& bookingMode == BI_BOOKING_MODE.STOP
        // 調整可能の明細に優先順位で調整を行う
        /*
        if (diffUnitSum != 0 && !otherPdList.isEmpty()) {
            mLogUtils.write_log('比率で金額を自動配分前差分金額：' + diffUnitSum);
            // 順次配分
            diffUnitSum = divisionPlanDetailUnitPrice(orgUnitPrice, otherPdList, diffUnitSum, true);
            mLogUtils.write_log('比率で金額を自動配分後差分金額：' + diffUnitSum);
        }*/
        // 2019/09/15 軽減税率機能対応 WGCH BEGIN
        if(isReducedTaxFlg){
        	diffUnit = setPriceRoomPdSumVal(planDetailInf, changePdMap);
        }
        // 2019/09/15 軽減税率機能対応 WGCH END
        // 配分成功の場合
        if (diffUnitSum == 0) {
        	// 明細設定情報を作成する
        	for (PlanDetail__c pd : planDetailInf.orgPlanDetailList) {
        		PlanDetail__c changePd = changePdMap.get(pd.id);
        		if (changePd == null) changePd = pd;
        		planDetailSyncInfo += changePd.id + ':' + changePd.Price__c + ';';
        	}
        } else {
       		// 金額配分失敗場合、プラン明細自動作成なし
        	planDetailSyncInfo = CommConst.CONST_PLANITEM_NOEXPAND;
        }
        /*
        updEstItems.addAll(incTaxchildsLst);
        if (diffUnitSum != 0){
            // 調整差額は存在　かつ　無税商品が存在する場合
            if(!otherLst.isEmpty() && bookingMode == BI_BOOKING_MODE.DEF){
                // 無税商品を配分する
                diffUnitSum = divisionPlanDetailUnitPrice(orgUnitPrice, otherLst, diffUnitSum, false);
                if (diffUnitSum != 0) {
                    mLogUtils.write_log('順次配分2');
                    // 順次配分
                    diffUnitSum = divisionPlanDetailUnitPrice(orgUnitPrice, otherLst, diffUnitSum, true);
                }
                updEstItems.addAll(otherLst);
            }else{
                return CommConst.CONST_PLANITEM_NOEXPAND;
            }
        }
        mLogUtils.write_log('first diffUnitSum::' + diffUnitSum);
            
        if(!updEstItems.isEmpty()){
            for(PlanDetail__c detail : updEstItems){
                // 明細自動配分情報を作成する：プラン明細ID:配分金額
                if(detail != null) planDetailSyncInfo += detail.id + ':' + detail.Price__c + ';';
            }
        }*/
        
        mLogUtils.write_log('プランブレイク差分調整金額:' + diffUnit);
        mLogUtils.write_method_end();
        return planDetailSyncInfo;
    }
    // プラン明細に金額調整処理機能
    //
    //
    // autoSplitFlg:残り金額は自動配分するがどうか
    private Decimal divisionPlanDetailUnitPrice(Decimal orgUnitPrice, List<PlanDetail__c> pdList, Decimal orgDiffUnit, Boolean autoSplitFlg){
        mLogUtils.write_method_start('divisionPlanDetailUnitPrice');
        // 小数点区分
        Integer pointLen = CommUtils.getPointLen(); 
        //PlanDetail__c maxItem = null;
        Decimal diffUnitSum = orgDiffUnit ;
       	if (autoSplitFlg) {
       		orgUnitPrice = 0;
       		// 自動配分対象の合計値から比率に配分する
			for (PlanDetail__c pd : pdList) {
				orgUnitPrice += pd.Price__c;
			}
       	}
        // 明細に金額を反映を行う
        for (PlanDetail__c pd : pdList) {
        	// 調整必要な金額がない場合、処理中止
            if (diffUnitSum == 0) break;
            // 増額処理の場合
            if (orgDiffUnit > 0) {
                // 該当明細は室料の場合、残りの残料金は残部自動設定を行う
                if (isRoomRateItem(pd.AccountMasterRef__r)) {
                    // 差分金額は全部室料に設定する
                    pd.Price__c += diffUnitSum;
                    diffUnitSum = 0;
                    break;
                } 
                /*
                else {
                	// 室料以外の場合、比率で自動配分を行う[小数は切り捨て]
	                Decimal addUnitPriceRate = orgUnitPrice == 0 
	                					? CommUtils.RoundProcess(1 / pdList.size() * orgDiffUnit , pointLen, RoundingMode.FLOOR)
	                					: CommUtils.RoundProcess(pd.Price__c / orgUnitPrice * orgDiffUnit , pointLen, RoundingMode.FLOOR);
	                // 比率に加算する
	                pd.Price__c += addUnitPriceRate;
	                // 既に調整金額を設定する
	                diffUnitSum -= addUnitPriceRate;
                }*/
               
            }
            // 差分額は減額の場合
            else {
                mLogUtils.write_log('差分額は減額');
                // 該当明細は室料の場合、残りの残料金は残部自動設定を行う
                if (isRoomRateItem(pd.AccountMasterRef__r)) {
                    // 差分金額は全部室料に設定する
                    pd.Price__c += diffUnitSum;
                    // 室料に残部減算完了
                    if (pd.Price__c >= 0) {
                    	diffUnitSum = 0;
                    	break;
                    }
                    // 室料はたりない場合
                    else {
                    	diffUnitSum = pd.Price__c;
                    	pd.Price__c = 0;
                    }
                    continue;
                } 
                /*
                else {
                	// 室料以外の場合、比率で自動配分を行う[小数は切り捨て]
	                Decimal addUnitPriceRate = orgUnitPrice == 0 
	                							? CommUtils.RoundProcess(1 / pdList.size() * orgDiffUnit , pointLen, RoundingMode.CEILING)
	                							: CommUtils.RoundProcess(pd.Price__c / orgUnitPrice * orgDiffUnit , pointLen, RoundingMode.CEILING);
	                // 比率減算
	                pd.Price__c += addUnitPriceRate;
	                Decimal diffPrice = addUnitPriceRate;
	                //todo 负值改修
	                if(pd.Price__c < 0){
	                	diffPrice = pd.Price__c;
	                	pd.Price__c = 0;
	                } 
	                // 既に調整金額を設定する
	                diffUnitSum -= diffPrice;
                }
                */
            }
        }
        // 残金あり、自動配分の場合
        if (autoSplitFlg && diffUnitSum != 0) {
        	Decimal splitUnit = 1;
        	if (pointLen > 0) splitUnit = (diffUnitSum < 0 ? -1 : 1) * (1/10*pointLen);
        	Integer maxLen = 0;	// Dead Loop
        	while (diffUnitSum != 0) {
        		if (maxLen > 10) break;
	        	for (PlanDetail__c pd : pdList) {
	        		// +1 / -1配分する　
	        		if (pd.Price__c + splitUnit < 0) continue;
	        		else {
	        			pd.Price__c += splitUnit;
	        			diffUnitSum -= splitUnit;
	        		}
	        	}
	        	maxLen++;
        	}
        }
        mLogUtils.write_method_end();
        return diffUnitSum;
    }
    /**
    * オプション商品情報は１番目部屋１泊目予約の見積明細に反映を行う
    **/
    // 2017/08/15 option数据根据单价定义区分计算 fix BEGIN
    //private List<BookingEstimateItem__c> upsertBookingEstimeteItemsByEach(BI_EMAIL_SyncInfo bookingInfo,Lead__c insLead){
    private List<BookingEstimateItem__c> upsertBookingEstimeteItemsByEach(BI_EMAIL_SyncInfo bookingInfo,Lead__c insLead, Integer taxSericeFee){
    // 2017/08/15 option数据根据单价定义区分计算 fix END
        mLogUtils.write_method_start('upsertBookingEstimeteItemsByEach');
		// オプション新規作成明細情報を格納する
        List<BookingEstimateItem__c> newOptList = new List<BookingEstimateItem__c>();
        if(bookingInfo.risaplsinformation.risaplsCommonInformation.option == null || bookingInfo.risaplsinformation.risaplsCommonInformation.option.isEmpty()) {
            mLogUtils.write_method_end();
            return newOptList;
        }
        mLogUtils.write_log('option::' + bookingInfo.risaplsinformation.risaplsCommonInformation.option);
        // オプション商品が存在する場合
        List<BI_EMAIL_Option> optionLst = bookingInfo.risaplsinformation.risaplsCommonInformation.option;
        // オプション商品コード　名を格納する
        set<String> prodCodeSet = new set<String>();
        set<String> prodNameSet = new set<String>();
        for(BI_EMAIL_Option option : optionLst){
            String productNm = option.Name;
            String productCode = option.OptionCode;
            if (!CommUtils.isBlank(productCode)) prodCodeSet.add(productCode);
            if (!CommUtils.isBlank(productNm)) prodNameSet.add(productNm);
        }
        // コードと名は全部NULLの場合、処理対象外
        if(prodCodeSet.isEmpty() && prodNameSet.isEmpty()) return newOptList;
        // コード　OR　名前で既存会計商品から情報を取得する
        // 2017/08/09 オプション商品検索の場合、非表示商品は対象外になる BEGIN
        //List<AccountMaster__c> accs = [select id,name,Field3__c,jmstRef__r.TaxRate__c,ServiceRate__c from AccountMaster__c where Field3__c = :prodCodeSet or Name = :prodNameSet];
        List<AccountMaster__c> accs = [select id,name,Field3__c,jmstRef__r.TaxRate__c,ServiceRate__c from AccountMaster__c where (Field3__c = :prodCodeSet or Name = :prodNameSet) And ActionType__c != :CommConst.PROD_ACTION_TYPE_NO];
        // 2017/08/09 オプション商品検索の場合、非表示商品は対象外になる END
        // 関連会計商品が非存在する場合、処理中止
        if (accs.isEmpty()) return newOptList;
        //　既存会計商品情報を格納する
        map<String, AccountMaster__c> existAccNameMap = new map<String, AccountMaster__c>();
        map<String, AccountMaster__c> existAccCodeMap = new map<String, AccountMaster__c>();
        for (AccountMaster__c acc : accs) {
            existAccNameMap.put(acc.Name, acc);
            existAccCodeMap.put(acc.Field3__c, acc);
        }
       
        // オプション情報は見積明細に反映を行う[１泊目予約に格納]
        for(BI_EMAIL_Option option : optionLst) {
            String productNm = option.Name;
            String productCode = option.OptionCode;
            AccountMaster__c existAcc = null;
            // 同じコードの商品が存在する場合　
            if (existAccCodeMap.containsKey(productCode)) {
                existAcc = existAccCodeMap.get(productCode);
            } else if (existAccNameMap.containsKey(productNm)) {
                existAcc = existAccNameMap.get(productNm);
            }
            if (existAcc == null) continue;
            // 数量と利用金額を取得する
            Integer productCount = option.OptionCount;
            Integer unitPriceOptionRate = option.OptionRate;
            // 新規作成対象リスト
            // 2017/08/15 option数据根据单价定义区分计算 fix BEGIN
            //newOptList.add(
                //new BookingEstimateItem__c (
             BookingEstimateItem__c bookingItem = new BookingEstimateItem__c (
                        refAccountMaster__c = existAcc.id,
                        refAccountMaster__r = existAcc,
                        Amount__c = productCount,
                        UnitPrice__c = unitPriceOptionRate,
                        ProductName__c = existAcc.Name,
                        refBooking__c = insLead.id
                //));
            );
            // 税区分変更をお行う「XMLに指定の税区分→SF側の税区分に変更」
            bookingItem.UnitPrice__c = CommUtils.convertPriceByTaxKbn(  unitPriceOptionRate,
                                                                        existAcc.jmstRef__r.TaxRate__c,
                                                                        existAcc.ServiceRate__c, 
                                                                        taxSericeFee, 
                                                                        CommConst.APPOPTION_UTP_DEF_KB);
            // 小数桁数の再確認
            bookingItem.UnitPrice__c = checkIfHadScale(bookingItem.UnitPrice__c, 
                                                                        existAcc.jmstRef__r.TaxRate__c,
                                                                        existAcc.ServiceRate__c, 
                                                                        CommConst.APPOPTION_UTP_DEF_KB); 
            newOptList.add(bookingItem); 
            // 2017/08/15 option数据根据单价定义区分计算 fix END
        }
        //if (!newOptList.isEmpty()) insert newOptList;
        mLogUtils.write_method_end();
    	return newOptList;
    }
    
    /**
    * 代表者として、取引先責任者作成する
    **/
    private Contact upsertContact(BI_EMAIL_SyncInfo bookingInfo ,Lead__c firstLead) {
        mLogUtils.write_method_start('upsertContact');
        // 2013.07.12 ADD 申込者と申込電話は予約に設定する
        // 予約者情報
        BI_EMAIL_Member member = bookingInfo.risaplsinformation.risaplsCommonInformation.member;
        String applicantName = member != null ? member.UserName : null;     // 申込者
        String applicantPhone = member != null ? member.UserTel : null;     // 申込者電話
        // 代表者情報
        BI_EMAIL_RisaplBasic risaplBasic = bookingInfo.risaplsinformation.risaplsCommonInformation.risaplBasic;
        // 代表者電話番号
        String phoneNumber = risaplBasic.PhoneNumber;
        // 顧客様名
        //Contact existContact
        String contactNameKana = bookingInfo.GuestOrGroupNameSingleByte;
        String contactNameKanji = bookingInfo.GuestOrGroupNameKanjiName;
        String contactNameKataKana = bookingInfo.GuestOrGroupNameDoubleByte;
        String contactName = CommUtils.isBlank(bookingInfo.GuestOrGroupNameKanjiName) ? bookingInfo.GuestOrGroupNameSingleByte : bookingInfo.GuestOrGroupNameKanjiName;
        String[] contactNameArr = CommUtils.splitName(contactName);
        String lastName = contactNameArr[0];
        String firstName = (contactNameArr.size() > 1 ? contactNameArr[1] : '');
        // 2016/03/30 お客様のFristNameは「_」の場合、外す改善対応 BEGIN
        if (firstName == '_' || firstName == '!') firstName = '';
        // 2016/03/30 お客様のFristNameは「_」の場合、外す改善対応 END
        String fullName = (lastName + ' ' + firstName).trim();
        // 顧客様名と顧客様電話番号で、既存データ存在チェックを行う
        List<Contact> existCList = null;
        if(bookingInfo.dmlAction == BI_EMAIL_DmlAction.UPD && firstLead != null){
        	String contactId = firstLead.Relcontact__c;
        	existCList = [select LastName,FirstName,Name1__c,KanaName1__c,Katakana__c,Phone,Email,MailingPostalCode,MailingStreet,
        							ApplicantName__c,ApplicantPhone__c,Birthdate,MobilePhone from Contact where id = :contactId];
            if(!existCList.isEmpty()) {
            	return existCList[0];
            }
        }
        // 既存顧客様情報を探す
        phoneNumber = CommUtils.convTelphoneNumber(phoneNumber);
        // 2017/12/14 SOSLキーチェック追加対応 BEGIN
        //if (!CommUtils.isBlank(phoneNumber)) {
        if (CommUtils.isValidateSoslKey(phoneNumber)) {
        // 2017/12/14 SOSLキーチェック追加対応 END
            mLogUtils.write_log('phoneNumber:' + phoneNumber );
            //String exitQueryStr = ' Select id,ApplicantName__c,ApplicantPhone__c From contact where ( KanaName1__c = :contactNameKana OR Name = :fullName ';
            String soslQuery = 'FIND :phoneNumber IN PHONE FIELDS RETURNING CONTACT (id, name where Name = :fullName ';
            if (!CommUtils.isBlank(contactNameKana)) soslQuery += ' OR KanaName1__c =:contactNameKana ';
            if (!CommUtils.isBlank(contactNameKanji)) soslQuery += ' OR Name1__c = :contactNameKanji ';
            if (!CommUtils.isBlank(contactNameKataKana)) soslQuery += ' OR Katakana__c = :contactNameKataKana ';
            soslQuery += ' limit 1) ';
            List<List<Sobject>> existRs = search.query(soslQuery);
            existCList = existRs[0];
            mLogUtils.write_log('既存お客様:' + existCList );
        }
        if (existCList != null && !existCList.isEmpty()) {
            existCList[0].ApplicantName__c = applicantName;
            existCList[0].ApplicantPhone__c = applicantPhone;
			existCList[0] = (Contact)getNewObjectByName(Contact.sObjectType,  existCList[0]);
	    	update existCList[0];
            mLogUtils.write_method_end();
            return existCList[0];
        }
        // 非存在する場合（あり得ない）
        //throw new CommException('代表者情報の詳細情報を未設定するため、確認必要があり');
        // 代表者は顧客新規作成を行う
        Contact newContact = (Contact)getNewObjectByName(Contact.sObjectType, null);
        
        //new Contact(
        // 2013/07/17 団体名または代表者氏名 漢字優先で設定、空白場合、団体名または代表者氏名(半角)に設定する
        // 団体名または代表者氏名(半角)
       	newContact.LastName =  lastName;
        newContact.FirstName = firstName;
        // 団体名または代表者氏名 漢字
        newContact.Name1__c = bookingInfo.GuestOrGroupNameKanjiName;
        // 2013/07/17 団体名または代表者氏名(半角)に設定する
        // 団体名または代表者氏名よみがな(全角)
        //KanaName1__c = bookingInfo.GuestOrGroupNameDoubleByte,
        newContact.KanaName1__c = bookingInfo.GuestOrGroupNameSingleByte;
        // ひらがな ←　団体名または代表者氏名よみがな(全角)
        newContact.Katakana__c = bookingInfo.GuestOrGroupNameDoubleByte;
        // 電話
        //newContact.Phone = risaplBasic.PhoneNumber;
        newContact.Phone = CommUtils.isBlank(phoneNumber) ? null : risaplBasic.PhoneNumber;
        // メール
        newContact.Email = risaplBasic.Email;
        // 郵便番号
        newContact.MailingPostalCode = risaplBasic.PostalCode;
        // 住所
        // 2016/05/10 住所分割と電話番号は取込値はそのまま BEGIN
        //MailingStreet = risaplBasic.Address,
        // 2016/05/10 住所分割と電話番号は取込値はそのまま END
        // 申込者
        newContact.ApplicantName__c = applicantName;
        // 申込者電話番号
        newContact.ApplicantPhone__c = applicantPhone;
        /*
        // 2016/03/28 誕生日と携帯電話情報解析と取込 BEGIN
        // 誕生日
        newContact.Birthdate = birthDay;
        // 携帯
        newContact.MobilePhone = moibelPhone;
        // 2016/03/28 誕生日と携帯電話情報解析と取込 END
        */
        //);
        // 2016/05/10 住所分割と電話番号は取込値はそのまま BEGIN
        if (!CommUtils.isBlank(risaplBasic.Address)) {
			List<String> addressLst = CommUtils.parseJapanAddress(risaplBasic.Address);
			mLogUtils.write_log('addressLst'+addressLst);
        	if (addressLst.size() == 3) {
        		newContact.MailingState = addressLst[0];
        		newContact.MailingCity = addressLst[1];
        		newContact.MailingStreet = addressLst[2];
        	} else {
        		newContact.MailingStreet = addressLst[0];
        	}
        }
//system.debug('newContact:::' + newContact);
        // 2016/05/10 住所分割と電話番号は取込値はそのまま END
        //2016/05/24  お客様重複チェック対応 BEGIN
        //insert newContact;
        newContact = (new CommLogicProcess()).upsertDuplicateErrorProcess(newContact, mLogUtils);
        // 2016/05/24 お客様重複チェック対応 END
        mLogUtils.write_log('お客様新規作成::' + newContact.id);
        mLogUtils.write_method_end();
        return newContact;

    }
    

    /*
     * 旅行会社情報はSFへ登録を行う
     * 会社・営業所が存在する場合、営業所も一緒に戻る
     */
    private List<Account> upsertTravelInfo (BI_EMAIL_SyncInfo bookingInfo) {
     	// 2017/02/24 Field Security Check BEGIN by wx
 		List<String> insChkFields = new List<String>{'AccountId','phone','LastName'};
 		Map<String,Schema.SObjectField> insm = Schema.SObjectType.Contact.fields.getMap();
 		if (!CommSecurityUtils.isCanCreateable(insChkFields, insm)) {
 			return null;
 		}
 		List<String> insChkFieldsLst = new List<String>{'Phone','ParentId','AccountType__c','Name','SalesOfficeCompanyCodeEmail__c'}; // ,'SalesOfficeCodeEmail__c'
 		Map<String,Schema.SObjectField> insmm = Schema.SObjectType.Account.fields.getMap();
 		if (!CommSecurityUtils.isCanCreateable(insChkFieldsLst, insmm)) {
 			return null;
 		}
 		// 2017/02/24 Field Security Check End by wx
        mLogUtils.write_method_start('upsertTravelInfo');
        // 旅行会社名と同じ取引先が存在するかどうかチェックを行う
        Account travelCompany = null;
        // 旅行会社存在する場合
        if (!CommUtils.isBlank(bookingInfo.SalesOfficeCompanyCode) ) {
            // UPDATE 2015/09/15　支店区分 : SalesOfficeCompanyCode　-- > SalesOfficeCompanyCodeTL__c
            //                             Name = XXXX 条件は外す　
            List<Account> travelCompanyLst = [select id , name from Account
                where AccountType__c = :CommConst.ACCOUNT_TYPE_TRAVEL
                and SalesOfficeCompanyCodeEmail__c = :bookingInfo.SalesOfficeCompanyCode 
                // 2016/02/01 旅行会社（営業所）の取得方式変更（「営業所コード」と「取引先ID」で合わせて取得する）BEGIN
                //and SalesOfficeCompanyType__c != null   // 旅行会社分類設定されている    
                // 2016/02/01 旅行会社（営業所）の取得方式変更（「営業所コード」と「取引先ID」で合わせて取得する）END
                limit 1];
            //and SalesOfficeCompanyCode__c = :bookingInfo.SalesOfficeCompanyCode
            // 存在なければ、取引先を新規作成する
            if (travelCompanyLst.isEmpty()) {
				// 2016/07/12 自動設定 by zy begin
				//travelCompany = new Account();
				travelCompany = (Account)getNewObjectByName(Account.sObjectType, null);
				// 2016/07/12 自動設定 by zy end
				travelCompany.Name = bookingInfo.SalesOfficeCompanyName;
				//travelCompany.SalesOfficeCompanyCode__c = bookingInfo.SalesOfficeCompanyCode;
  				travelCompany.AccountType__c = CommConst.ACCOUNT_TYPE_TRAVEL;
				travelCompany.SalesOfficeCompanyCodeEmail__c = bookingInfo.SalesOfficeCompanyCode;
				insert travelCompany;
            } else {
                travelCompany = travelCompanyLst[0];
            }
            mLogUtils.write_log('旅行会社AGT['+(travelCompanyLst.isEmpty() ? '新規':'既存')+']' + travelCompany);
        }

        Account traveOffice = null;
        // 2016/02/01 旅行会社（営業所）の取得方式変更（「営業所コード」と「取引先ID」で合わせて取得する）BEGIN
		if (!CommUtils.isBlank(bookingInfo.SalesOfficeCode)) {
			// 取引先IDと営業所コードで存在チェックを行う
			List<Account> traveOfficeLst = [select id , name, ParentId,SalesOfficeCodeTL__c from Account
				where AccountType__c = :CommConst.ACCOUNT_TYPE_TRAVEL
				and ParentId = :travelCompany.Id
				and	SalesOfficeCodeEmail__c = :bookingInfo.SalesOfficeCode
				limit 1];
			if (!traveOfficeLst.isEmpty()) {
				traveOffice = traveOfficeLst[0];
				mLogUtils.write_log('旅行会社-支店既存取得::' + traveOffice.id);
			}
		}
		// 2016/02/01 旅行会社（営業所）の取得方式変更（「営業所コード」と「取引先ID」で合わせて取得する）END
        // 旅行会社営業所情報が存在する場合
        if (traveOffice == null &&
        	!CommUtils.isBlank(bookingInfo.SalesOfficeCode) &&
            !CommUtils.isBlank(bookingInfo.SalesOfficeName) ) {
            // 旅行会社営業所情報を新規作成を行う
            // 2016/07/12 自動設定 by zy begin
            traveOffice = (Account)getNewObjectByName(Account.sObjectType, null); 
            //new Account();
            // 2016/07/12 自動設定 by zy end
            traveOffice.Name = bookingInfo.SalesOfficeName;
            traveOffice.AccountType__c = CommConst.ACCOUNT_TYPE_TRAVEL;
            traveOffice.SalesOfficeCodeEmail__c = bookingInfo.SalesOfficeCode;
            traveOffice.ParentId = (travelCompany != null ? travelCompany.Id : null);
            traveOffice.Phone = bookingInfo.SalesOfficePhoneNumber;
            insert traveOffice;
            mLogUtils.write_log('旅行会社-支店新規作成::' + traveOffice.id);
        }
        // 担当者->取引先責任者に設定を行う
        // 取引担当者が存在する場合、担当者として、登録する
        if ((travelCompany != null || traveOffice != null) &&
            !CommUtils.isBlank(bookingInfo.SalesOfficePersonInCharge) &&
            !CommUtils.isBlank(bookingInfo.SalesOfficePhoneNumber) ) {
            // 同じ氏名と電話の担当者存在チェックを行う
            List<Contact> contactLst = [select id, name from Contact where LastName = :bookingInfo.SalesOfficePersonInCharge and phone = :bookingInfo.SalesOfficePhoneNumber];
            if (contactLst.isEmpty()) {
                Contact newContact = new Contact();
                newContact.LastName = bookingInfo.SalesOfficePersonInCharge;
                newContact.phone = bookingInfo.SalesOfficePhoneNumber;
                newContact.AccountId = (traveOffice == null ? travelCompany.Id : traveOffice.Id);
                insert newContact;
                mLogUtils.write_log('旅行会社関連担当者情報作成::'+newContact.Id);
            }
        }
        List<Account> rsAccountLst = new List<Account>();
        if (travelCompany != null) rsAccountLst.add(travelCompany);
        if (traveOffice != null) rsAccountLst.add(traveOffice);
        mLogUtils.write_method_end();
        return rsAccountLst;
        //return (traveOffice == null ? travelCompany: traveOffice);
    }

    // 支払方法転換
    private string getLocalPaymentInfo (String mediaType) {
        String ttendType = null;
        if (mediaType == 'Cach'|| mediaType == 'Cash') ttendType = CommConst.MEDIA_TYPE_CD_01;
        else if (mediaType == 'CreditCard') ttendType = CommConst.MEDIA_TYPE_CD_02;
        //else if (mediaType == '売掛') ttendType = CommConst.MEDIA_TYPE_CD_03;
        else if (mediaType == 'Coupon') ttendType = CommConst.MEDIA_TYPE_CD_11;
        // 支払方法設定
        String mediaTypeName = CommConst.getPaymentTypeLabelByKey(ttendType);
        return (mediaTypeName == null ? mediaType : mediaTypeName);
    }
    private AccountMaster__c getShiTuLyouAcc(){
        List<AccountMaster__c> shituLyoAccs = ProductItemUtils.getRoomRateProduct(CommConst.APPOPTION_ROOMPRICE_PRODNAME);
        if(shituLyoAccs.isEmpty()) return new AccountMaster__c();
        else return shituLyoAccs[0]; 
    }
    // サビース料商品
    private AccountMaster__c getServiceAcc(){
        String accountCd = EmailMessageToLeadHelp.getAccountConfig(shopCd).serviceCd;
        if (CommUtils.isBlank(accountCd)) return new AccountMaster__c();
        List<AccountMaster__c> acc = [select Name,Id,TaxRateCal__c,ServiceRate__c  from AccountMaster__c where Field3__c = :accountCd  limit 1];
        if(acc.isEmpty()) return new AccountMaster__c();
        return acc[0];
    }
    // 入湯税商品
    private AccountMaster__c getNyuuTouAcc(){
        String accountCd = EmailMessageToLeadHelp.getAccountConfig(shopCd).nyuuTouCd;
        if (CommUtils.isBlank(accountCd)) return new AccountMaster__c();
        List<AccountMaster__c> acc = [select Name,Id,Field5__c,TaxRateCal__c,ServiceRate__c  from AccountMaster__c where Field3__c = :accountCd  limit 1];
        if(acc.isEmpty()) return new AccountMaster__c();
        return acc[0];
    }
    private String setUpdateContent(LeadIndex__c leadIndex , BI_EMAIL_SyncInfo bookingInfo){
        List<Attachment> rsAtt = [select Name,Body,ParentId from attachment where parentId = :leadIndex.Id order by CreatedDate desc]; 
        //rsAtt[0];
        //bookingInfo.
        //BI_EMAIL_SyncInfo.
        return '';
    }
    // 自動割り振りできる部屋リスト情報を取得する
    private map<Integer,Room__c> getCanAssignRoom(LeadIndex__c leadIndex, Map<String,Id> roomTypeMap, Map<String,Id> roomTypeNmMap, boolean autoAssingRoomflag, BI_EMAIL_SyncInfo bookingInfo){
    
            mLogUtils.write_method_start('getCanAssignRoom');
            
            map<Id, Id> targetRoomIdTypeMap = new map<Id, Id>();
            map<Id, List<Room__c>> wkCanAssignRoomMap = new map<Id, List<Room__c>>();
            map<Integer,Room__c> resultMap = new map<Integer, Room__c>();
            // 自動割り振りの順次でアサイン対象部屋情報を取得する
		    List<Id> roomTypeIdLst = roomTypeMap.values();
            String sortField = EmailMessageToLeadHelp.getAppConfig(shopCd).roomSortKey;
            String queryHead = 'select id,Name,TypeRoomRef__c from Room__c ';
            String queryWhere = ' where UseOfRoom__c = \'' + String.escapeSingleQuotes(CommConst.ROOM_UseOfType_Guest) + '\'' +
                                ' And TypeRoomRef__c in :roomTypeIdLst ';
            String queryOrder = ' Order By priority__c ' + sortField + ' NULLS LAST ';
            String queryString = queryHead + queryWhere + queryOrder;
            //mLogUtils.write_log('queryString::' + queryString);
			// 今回XMLに指定の部屋タイプに関連の部屋定義情報を取得する
            for (Room__c room : DataBase.query(queryString)) {
                // 部屋　と　部屋タイプマッピング情報を格納する
                targetRoomIdTypeMap.put(room.Id, room.TypeRoomRef__c);
                // 部屋単位の部屋情報を格納する
                if (!wkCanAssignRoomMap.containsKey(room.TypeRoomRef__c)) {
                    wkCanAssignRoomMap.put(room.TypeRoomRef__c, new List<Room__c>());
                }
                wkCanAssignRoomMap.get(room.TypeRoomRef__c).add(room);
            }
            // 有効な予約データ、一日一部屋で処理するため、重複することは処理対象外
            Set<Id> usedRoomIdSet = new Set<Id>();
            // 既に予約データに入る場合、該当部屋は選択対象外になる
            for (AggregateResult lead :  [
                select Rroom__c roomId from Lead__c
                where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
                    And DAY_ONLY(convertTimezone(EntryTime__c)) >= :leadIndex.EntryDate__c
                    And DAY_ONLY(convertTimezone(EntryTime__c)) <= :leadIndex.DepartureDate__c 
                    And Rroom__c in :targetRoomIdTypeMap.keySet()
                    And LeadIndexRef__c != :leadIndex.Id
                    Group By Rroom__c]) {
                usedRoomIdSet.add((Id)lead.get('roomId'));
            }
//mLogUtils.write_log('roomTypeIdLst::' + roomTypeIdLst);
//mLogUtils.write_log('wkCanAssignRoomMap::' + wkCanAssignRoomMap);
//mLogUtils.write_log('usedRoomIdSet::' + usedRoomIdSet);
			// 存在の部屋情報から予約データに利用している部屋は自動アサイン対象外になる
			// map<部屋タイプID,部屋リスト>
            map<Id, List<Room__c>> canAssignRoomMap = new map<Id, List<Room__c>>();
            for (Id roomTypeId : wkCanAssignRoomMap.keySet()) {
                List<Room__c> targetRoomLst = wkCanAssignRoomMap.get(roomTypeId);
                for (Room__c room : targetRoomLst) {
                    // 既に使っている部屋の場合、対象外になる
                    if (usedRoomIdSet.contains(room.Id)) continue;
                    if (!canAssignRoomMap.containskey(roomTypeId)) canAssignRoomMap.put(roomTypeId, new List<Room__c>());
                    canAssignRoomMap.get(roomTypeId).add(room);
                }
            }
            // アサインできる部屋はない場合、チェック処理中止
            if(canAssignRoomMap.isEmpty()) return resultMap;
//mLogUtils.write_log('canAssignRoomMap::' + canAssignRoomMap);
            // 2015/10/31 故障部屋チエックロジックを追加対応 BEGIN
            // 同じ部屋、利用日により、同じ部屋は連続の日付はリストに入る
            // 開始日　〜　終了日期間日を取得する
	        Integer nights = bookingInfo.Nights;            // 総宿泊数
	        if (nights == 0) nights = 1;
	        Integer rooms = bookingInfo.TotalRoomCount;     // 総部屋数
			// 部屋→部屋タイプリスト→map<部屋タイプコード、関連の日付>
			//List<List<map<string,list<Date>>>> roomTypeList = new List<List<map<string,list<Date>>>>(); 
			//map<Integer, list<date>> roomTypeDateLinkMap = new map<Integer, list<date>>();
			
			// 部屋単位に、宿泊期間内の部屋タイプリスト一覧情報を格納する
			map<Integer, list<string>> tmpRoomTypeListMap = new map<Integer, list<string>>();
			// 宿泊期間情報を格納する、1部屋A：1/1,1/2,1/3日は同じ部屋タイプすると、0,1,2は同じリストを格納する<1, <1/1,1/2,1/3>, 2,<1/1,1/2,1/3>>...
			map<Integer, list<date>> roomTypeDateLinkByIdxMap = new map<Integer, list<date>>();
            BI_EMAIL_RoomAndGuestInfo[] roomAndGuest = bookingInfo.roomAndGuestLst;
			// XMLの宿泊部屋単位情報
        	for(Integer j = 0; j < rooms; j ++){
        		list<string> oneRoomRoomTypes = new list<string>();
        		tmpRoomTypeListMap.put(j, oneRoomRoomTypes);
        		// 1部屋N日単位情報
	        	for(Integer i = 0; i < nights; i ++){
	        		// 情報を取得IDEXを定義する
	        		Integer idx = i * rooms + j;
	        		// 部屋タイプリスト情報を格納する
	        		String roomTypeCd = roomAndGuest[idx].room.RoomTypeCode;
	        		// メール取り込みの場合、部屋タイプのみ引き渡し可能性があります
	        		if (CommUtils.isBlank(roomTypeCd)) roomTypeCd = roomAndGuest[idx].room.RoomTypeName;
	        		// 部屋利用日（到着日)
                	Date stayDate = roomAndGuest[idx].roomRateLst[0].RoomDate;
					if (oneRoomRoomTypes.isEmpty()) {
						oneRoomRoomTypes.add(roomTypeCd);
						list<date> newitems = new list<date>{stayDate};
						roomTypeDateLinkByIdxMap.put(idx, newitems);
					} else {
						// 前回の部屋タイプを取得して、
						string preRoomTypeCd = oneRoomRoomTypes[oneRoomRoomTypes.size()-1];
						// 泊期間に、部屋タイプ変更の場合
						if (preRoomTypeCd != roomTypeCd) {
							oneRoomRoomTypes.add(roomTypeCd);
							list<date> newitems = new list<date>{stayDate};
							roomTypeDateLinkByIdxMap.put(idx, newitems);
						} else {
							// 日付を連続に設定を行う
							list<date> preitems = roomTypeDateLinkByIdxMap.get((i-1) * rooms + j);
							preitems.add(stayDate);
							roomTypeDateLinkByIdxMap.put(idx, preitems);
						}
					}
	        	}
        	}
//mLogUtils.write_log('tmpRoomTypeListMap::' + tmpRoomTypeListMap);
//mLogUtils.write_log('roomTypeDateLinkByIdxMap::' + roomTypeDateLinkByIdxMap);
        	// 2015/10/31 故障部屋チエックロジックを追加対応 END
        	set<id> isAutoAssignRoomtSet = new set<Id>();
        	for (list<Room__c> canAssRooms : canAssignRoomMap.values()) {
        		for (Room__c canAssRoom : canAssRooms) {
        			isAutoAssignRoomtSet.add(canAssRoom.id);
        		}
        	}
            RoomStatusManager roomStatusManger = new RoomStatusManager();
	    	// 指定期間ないの故障部屋リストを取得する
	    	List<RoomsStatus__c> roomsStatus = roomStatusManger.queryBadRoomList(leadIndex.EntryDate__c,leadIndex.DepartureDate__c ,isAutoAssignRoomtSet);
	    	// 指定部屋の故障ありの日付情報を格納する
	    	Map<id,List<RoomsStatus__c>> badRoomStatusMap = new Map<id,List<RoomsStatus__c>>();
	    	//Map<Id, String> roomNameMap = new map<Id, String>();
	    	for(RoomsStatus__c roomStatus : roomsStatus){
	    		if(!badRoomStatusMap.containsKey(roomStatus.RoomRef__c)){
	    			badRoomStatusMap.put(roomStatus.RoomRef__c,new List<RoomsStatus__c>());
	    		}
	    		badRoomStatusMap.get(roomStatus.RoomRef__c).add(roomStatus);
	    	}
	    	
	    	// 部屋単位
			for(Integer j = 0; j < rooms; j ++){
        		// 日単位情報
	        	for(Integer i = 0; i < nights; i ++){
					// 情報を取得IDEXを定義する
	        		Integer idx = i * rooms + j;
	        		// 部屋タイプリスト情報を格納する
	        		String roomTypeCd = roomAndGuest[idx].room.RoomTypeCode;
	        		Id roomTypeId = roomTypeMap.get(roomTypeCd);
	        		// メール取り込みは部屋タイプ名のみ存在する場合
	        		if (CommUtils.isBlank(roomTypeCd)) {
	        			String roomTypeName = roomAndGuest[idx].room.RoomTypeName;
	        			if (roomTypeNmMap.containsKey(roomTypeName)) roomTypeId = roomTypeNmMap.get(roomTypeName);
	        		}
//mLogUtils.write_log('roomTypeId::' + roomTypeId);
//mLogUtils.write_log('roomTypeCd::' + roomTypeCd);
//mLogUtils.write_log('RoomTypeName::' + roomAndGuest[idx].room.RoomTypeName);
	        		if (roomTypeId == null) continue;
	        		// 部屋タイプ関連の部屋リストを取得する
	        		List<Room__c> locCanAssingRoomList = canAssignRoomMap.get(roomTypeId);
	        		if (locCanAssingRoomList == null || locCanAssingRoomList.isEmpty()) continue;
    				// 該当部屋は故障チェックの期間情報を取得する
    				list<date> assingRangeDates = roomTypeDateLinkByIdxMap.get(idx);
    				// 連続期間ない場合、処理対象外
    				if (assingRangeDates == null || assingRangeDates.isEmpty()) continue;
    				// 同部屋タイプ連泊の期間日付の開始と終了日付を取得する
    				Date startDt = assingRangeDates[0];
    				Date endDt = assingRangeDates[assingRangeDates.size()-1];
	        		// 該当部屋は指定期間に、故障あり、なしチエックを行う
	        		Room__c targetRoom = null;
	        		for (Room__c room : locCanAssingRoomList) {
	        			// 該当部屋は指定期間に、故障がない場合
	        			if (!badRoomStatusMap.containsKey(room.Id)) {
	        				targetRoom = room;
	        				break;
	        			} else {
	        				// 故障部屋情報リストを取得する
	        				List<RoomsStatus__c> badInfoLst = badRoomStatusMap.get(room.Id);	        				
	        				Boolean nextRoomFlg = false;
	        				// 宿泊期間に故障情報が存在する場合、該当部屋は自動割当て対象外になる
	        				for (RoomsStatus__c roomStatus : badInfoLst) {
	        					if (roomStatus.StatusBeginDate__c <= endDt &&
	        						roomStatus.StatusEndDate__c >= startDt) {
	        						nextRoomFlg = true;
	        						break;
	        					}
	        				}
	        				// 故障部屋の場合、次の部屋を移動する
	        				if (nextRoomFlg) continue;
	        				// 有効な部屋の場合、処理完了
	        				targetRoom = room;
	        				break;
	        			}
	        		}
	        		// 該当期間にアサインできる部屋が存在する場合
        			if (targetRoom != null) {
    					// 該当期間に、該当部屋は再利用できない様に制御設定を行う
        				RoomsStatus__c virBadRoom = new RoomsStatus__c();
        				virBadRoom.StatusBeginDate__c = startDt;
        				virBadRoom.StatusEndDate__c = endDt;
        				if (!badRoomStatusMap.containsKey(targetRoom.Id)) badRoomStatusMap.put(targetRoom.Id, new List<RoomsStatus__c>());
        				badRoomStatusMap.get(targetRoom.Id).add(virBadRoom);
	    				// 該当部屋はアサイン期間OKの場合、部屋情報は該当IDXに設定を行う
	    				resultMap.put(idx, targetRoom);
	    				// 連続の期間が存在する場合、同じ部屋は同じ部屋タイプにアサインする
	    				integer betweenLength = startDt.daysBetween(endDt);
	    				// 連泊期間内の同じ部屋を割当てする設定を行う「次の泊から」
	    				for (integer cKey = 1; cKey <= betweenLength; cKey++) {
							integer plusIdx = i + cKey;
	    					integer key = plusIdx * rooms + j;
	    					resultMap.put(key, targetRoom);
	    				}
	    				i += betweenLength;
        			}	
	        	}
			}
			
            mLogUtils.write_method_end();
            return resultMap;
    }

	// 小数桁数はシステム定義により、長い場合、単数処理後の処理値は検証する
	private Decimal checkIfHadScale(Decimal orgPrice,Decimal taxRate,Decimal serviceRate,Integer kbn){
		// システム小数点の長さ
        Integer pointLen = CommUtils.getPointLen(); 
        // 変換値の小数点桁数
        Integer pricePointLen = orgPrice.stripTrailingZeros().scale();
        // システム予想の小数桁数により、長小数点をもっている場合
        if(pricePointLen > pointLen){
        	// 指定区分でサ込、税込金額を取得する
        	CommUtils.ProductInfo pro =  new CommUtils.ProductInfo(kbn);
        	pro.process(orgPrice,1,taxRate,serviceRate);
        	Decimal orgIncTaxServicePrice = pro.unitPriceTax;
        	
 			// 指定小数まで切上げで変換する
        	Decimal roundPrice = CommUtils.RoundProcess(orgPrice, pointLen, RoundingMode.CEILING);
        	pro.process(roundPrice,1,taxRate,serviceRate);
        	if (pro.unitPriceTax == orgIncTaxServicePrice) return roundPrice;
        	
        	// 指定小数まで切り捨てで変換する
        	roundPrice = CommUtils.RoundProcess(orgPrice, pointLen, RoundingMode.FLOOR);
        	pro.process(roundPrice,1,taxRate,serviceRate);
        	if (pro.unitPriceTax == orgIncTaxServicePrice) return roundPrice;
        }
        return orgPrice;
	}

	/**
	* 予約処理対象予約情報のリストを取得する
	* 1.同じ予約インデックスに所属する予約情報を取得する
	* 2.取得の予約情報の「予約番号」内容は「予約インデックス」と一致すると、該当予約情報は処理対象予約データ
	* 3.予約番号存在　かつ　該当予約番号は予約インデックスと一致しない場合、処理対象外(予約)
	**/
	private List<Lead__c> filterTLImportData(List<Lead__c> orgLst , BI_EMAIL_SyncInfo bookingInfo,LeadIndex__c leadIndex, Set<Id> pSubLeadIds){
		mLogUtils.write_method_start('filterTLImportData');
		// 予約番号比較用: TL_99999999
		String dataId = bookingDataId;
		// TL電文経由で作成の予約情報を格納する
		List<Lead__c> filterLst = new List<Lead__c>();
		// 予約インデックスの作成時間を取得する
		// TODO：予約情報を新規作成後、予約変更電文で泊数変更など、新作成された予約情報も処理対象が必要、該当対応が必要です
		long createTimeLon = leadIndex.CreatedDate.getTime();

		//boolean isHadBookingData = false;
		Set<Id> filterIdSet = new Set<Id>();
		// 予約番号情報を登録データが存在する場合
		for(Lead__c lead : orgLst){
			// 予約に予約番号を登録されている　かつ　該当予約番号は予約インデックスと登録の番号が一致（Tl_予約インデックス.ID)
			if(!CommUtils.isBlank(lead.BookingDataID__c) && lead.BookingDataID__c == dataId){
				filterLst.add(lead);
				filterIdSet.add(lead.id);
			}
		}
		// 予約番号を登録されている予約情報がない場合
		if(filterLst.isEmpty()){
			for(Lead__c lead : orgLst){
				// 予約インデックスSUBのIDをチェックが必要
				if (!pSubLeadIds.contains(lead.LeadIndexSubId__c)) continue;
				//mLogUtils.write_log('lead.EventSource__c::' + lead.EventSource__c);
				// 予約の発生源情報を登録　かつ　TL経由で作成の予約情報場合
				if(!CommUtils.isBlank(lead.EventSource__c) && lead.EventSource__c.contains(APPNAME)){
					filterLst.add(lead);
					filterIdSet.add(lead.id);
				}
			}
		}
		// 予約情報予約番号登録なし　OR　TL発生源も登録なしの予約情報に対して、
		if(filterLst.isEmpty()){
			for(Lead__c lead : orgLst){
				// 予約インデックスSUBのIDをチェックが必要
				if (!pSubLeadIds.contains(lead.LeadIndexSubId__c)) continue;
				long leadLong = lead.CreatedDate.getTime();
				if( (leadLong-createTimeLon) <= LEAD_CREATE_TIME_DIFF_INT){
					filterLst.add(lead);
					filterIdSet.add(lead.id);
				}
			}
		}
		if(!filterIdSet.isEmpty()){
			for(Lead__c lead : orgLst){
				if(!filterIdSet.contains(lead.id)){
					mLogUtils.write_log('関連更新対象外予約ID='+lead.id);
				}
			}
		}
		mLogUtils.write_method_end();
		return filterLst;
	}
	private sobject getNewObjectByName(SObjectType objectType, Sobject obj){
		mLogUtils.write_method_start('getNewObjectByName');
		Schema.DescribeSObjectResult s = objectType.getDescribe();
		if(obj == null) obj = objectType.newSObject();
		String typeName = s.getLocalName();
		Map<String, Schema.DescribeFieldResult> fieldsDefMap = CommSqlUtils.getAllFieldLst(objectType,true);
		mLogUtils.write_log('defaultValueMap='+defaultValueMap);
		// 追加設定項目を取得、設定する
		if(defaultValueMap != null && defaultValueMap.containsKey(typeName)){
			// 自動設定の項目と関連の設定値
			Map<String,String> autuoSetupFieldMap = defaultValueMap.get(typeName);
			// 編集可能の項目リスト
			for(String fieldName : autuoSetupFieldMap.keySet()){
				// 該当項目は編集可能　かつ　指定の項目は空白の場合
				if(fieldsDefMap.containsKey(fieldName) && CommUtils.isBlank(CommUtils.nullToblank(obj.get(fieldName)))){
					Schema.DescribeFieldResult f = fieldsDefMap.get(fieldName);
					obj.put(fieldName,CommUtils.ConvByFielType(autuoSetupFieldMap.get(fieldName), f.getType()));
				}
			}
		}
		mLogUtils.write_method_end();
		return obj;
	}
    public class BI_EMAIL_SyncInfo {
        // 情報区分 TransactionType
        public String DataFrom;
        //public String DataClassification;
        public BI_EMAIL_DmlAction dmlAction;
        public String DataClassification;         // データ区分
        public String DataID;                     // 外部キー：予約管理ID（一意制御あり）
        public Date SystemDate;                   // 使わない
        public Time SystimTime;                   // 使わない
        // 宿泊施設側情報
        public String AccommodationName;          // 使わない
        public String AccommodationCode;          // 使わない
        public String AccommodationArea;  //宿泊地区名
        public String ChainName;  //チェーンホテル名        
        public String AccommodationPersonInCharge;  //宿泊施設担当者名      
        public String AccommodationEmail;  //宿泊施設担当者Email       
        public String AccommodationPhoneNumber;  //宿泊施設電話番号     
        
        // 2015/08/07 TL2WAY対応するため、項目追加 BEGIN
        public List<BI_EMAIL_BankInfo> bankLst;    //振込銀行情報
        // 2015/08/07 TL2WAY対応するため、項目追加 END
        
        public String AccommodationCPUAddress;  //宿泊施設宛先指定  
        
        //  旅行会社情報 : SalesOfficeInformation
        public String SalesOfficeCompanyCode;     // XMLに該当項目がないので、常にNULLで初期化されれている
        public String SalesOfficeCompanyName;
        public String SalesOfficeName;
        public String SalesOfficeCode;
        public String SalesOfficePersonInCharge;
        public String SalesOfficeEmail;
        public String SalesOfficePhoneNumber;
        //// 住所
        public String SalesOfficeStateProvidence;
        public String SalesOfficeCityName;
        public String SalesOfficeAddressLine;
        public String SalesOfficeStreetNumber;
        public String SalesOfficePostalCode;
        
        // 2015/08/07 TL2WAY対応するため、項目追加 BEGIN
        public String SalesOfficeRegisteredCategory;                //旅行会社登録種別
        public String SalesOfficeLicenseNumber;             //旅行会社登録番号
        public String SalesOfficeRegisteredPrefecture;              //旅行会社登録行政庁
        public String SalesOfficeCPUAddress;                //旅行会社宛先指定
        public String RetailerCompanyName;              //販売代理店会社名
        public String RetailerOfficeName;               //販売代理店営業所名
        public String RetailerOfficeCode;               //販売代理店営業所コード
        public String RetailerPersonInCharge;               //販売代理店担当者名
        public String RetailerEmail;                //販売代理店担当者Email
        public String RetailerPhoneNumber;              //販売代理店電話番号
        public String RetailerStateProvidence;              //販売代理店住所都道府県
        public String RetailerCityName;             //販売代理店住所区市名
        public String RetailerAddressLine;              //販売代理店住所町村名
        public String RetailerStreetNumber;             //販売代理店住所番地名
        public String RetailerPostalCode;               //販売代理店住所郵便番号
        public String RetailerRegisteredCategory;               //販売代理店登録種別
        public String RetailerLicenseNumber ;           //販売代理店登録番号
        public String RetailerRegisteredPrefecture;             //販売代理店登録行政庁
        // 2015/08/07 TL2WAY対応するため、項目追加 END
        
        // 基本宿泊情報: BasicInformation
        public String TravelAgencyBookingNumber;      // 使わない
        public Date TravelAgencyBookingDate;
        public Time TravelAgencyBookingTime;
        public String TravelAgencyReportNumber;
        
        //// 団体名または代表者氏名(半角)->必須
        public String GuestOrGroupNameSingleByte;
        public String GuestOrGroupNameDoubleByte;
        public String GuestOrGroupNameKanjiName;
        public Date CheckInDate;
        public Time CheckInTime;
        public Date CheckOutDate;
        public Time CheckOutTime;
        public Integer Nights;
        public String Transportaion;
        ////利用客室合計数
        public Integer TotalRoomCount;
        ////お客様総合計人数
        public Integer GrandTotalPaxCount;
        public Integer TotalPaxMaleCount;
        public Integer TotalPaxFemaleCount;
        public Integer TotalChildA70Count;
        public Integer TotalChildB50Count;
        public Integer TotalChildC30Count;
        public Integer TotalChildDNoneCount;
        public String PackagePlanName;
        public String PackagePlanCode;
        public String PackagePlanContent;
        ////食事条件:TODO　名から実際のあ約タイプに変換する
        public String MealCondition;
        ////食事有無情報
        public String SpecificMealCondition;
        ////食事個所情報
        public String MealPlace;                  // 非使用
        // 電文(予約詳細： 一日ごとの大人子供人数の内訳、料金詳細などを出力する。 予約詳細情報は最初の情報が「ZZ」で始まり「,ZZ」で区切られる。)
        public String SpecialServiceRequest;
        // 備考
        public String OtherServiceInformation;
        // 詳細情報有無
        public String FollowUpInformation;        // 非使用
        
        // 2015/08/07 TL2WAY対応するため、項目追加 BEGIN
        public String AccommodationConfirmationNumber;              //宿泊個所予約番号
        public String GroupNameWelcomeBoard;                //団体名(ウェルカムボード用)
        public Integer CoachCount;              //入込バス台数
        public String CoachCompany;             //入込バス会社名
        public Integer TotalChildOtherCount;                //子供その他人数合計
        public Integer TotalTourConductorCount;             //添乗員人数合計
        public Integer TotalCoachDriverCount;               //バスドライバー人数合計
        public Integer TotalGuideCount;             //バスガイド人数合計
        public String TypeOfGroup;              //参加形態
        public String Status;               //予約ステータス
        public String PackageType;              //企画商品区分
        public String BanquetRoom;              //宴会場利用
        public String ModificationType;             //変更点区分
        public String ModificationPoint;                //変更ポイント説明
        public String CancellationNumber;               //宿泊施設取消番号
        public String PreviousPlace ;           //前泊地
        public String PreviousAccommodationName;                //前泊宿泊施設名       
        // 2015/08/07 TL2WAY対応するため、項目追加 END
          
        // BasicRateInformation
        public String RoomRateOrPersonalRate;
        public String TaxServiceFee;
        public String Payment;
        public Integer BareNetRate;
        public String CreditCardAuthority;
        public String CreditCardNumber;
        // 合計宿泊料金(総額)
        public Decimal TotalAccommodationCharge;
        public Decimal TotalAccommodationHotSpringTax;
        public Decimal TotalAccommodationServiceFee;
        public Decimal TotalAccommodationOtherFee;
        public Decimal CommissionPercentage;
        
        // 2015/08/07 TL2WAY対応するため、項目追加 BEGIN
        public List<BI_EMAIL_CouponInfo> CouponLst;        //クーポン明細
        public Integer CancellationCharge;              //前広取消に対する取消料情報
        public Date ExpireDate;             //クレジットカード有効期限
        public String CardHolderName;               //クレジットカード保有者氏名
        public Integer TotalAccommodationConsumptionTax;                //合計宿泊料金消費税
        public Integer TotalAccommodationHotelTax;              //合計宿泊料金ホテル税他
        public Integer TotalAccommodationBreakfastFee;              //合計朝食料金
        public Integer TotalAccommodationCommissionAmount;              //合計手数料総額
        public Integer TotalAccommodationCommissionConsumptionTax;              //合計手数料消費税総額
        public Integer TotalAccommodationChargeAfterCheckIn;                //宿泊当日変更後の宿泊料金(総額)
        public Integer TotalBalanceAfterCheckIn;                //宿泊当日変更後の宿泊料金(差額)
        public Integer TotalAccommodationConsumptionAfterCheckIn;               //宿泊当日変更後の手数料消費税
        public Integer CancellationChargeAfterCheckIn;              //宿泊当日取消に対する取消料情報
        public Integer MembershipFee;               //定率会費
        public Integer AdjustmentFee;               //精算調整額
        // 2015/08/07 TL2WAY対応するため、項目追加 END
        
        // 個々の部屋とお客様情報<1:N>
        public List<BI_EMAIL_RoomAndGuestInfo> roomAndGuestLst;
        // 7-1
        public BI_EMAIL_Risaplsinformation risaplsinformation;
        public BI_EMAIL_SyncInfo(){
        	risaplsinformation = new BI_EMAIL_Risaplsinformation();
        }

    }
    // 2015/08/07 TL2WAY対応するため、項目追加 BEGIN
    public class BI_EMAIL_BankInfo {
        public String BankName;         //振込銀行名
        public String BankAccountNumber;            //口座番号
        public String BankBranchName;           //振込銀行支店名
        public String BankAccountClassification;            //振込銀行口座種別
        public String BankAccountName;          //口座名
    }
    public class BI_EMAIL_CouponInfo {
        public Decimal CouponAmount;            //クーポン券面額
        public String CouponType;           //クーポン種類
        public String CouponNumber;         //クーポン番号
        public Date CouponIssueDate;            //クーポン発行日
    }
    // 2015/08/07 TL2WAY対応するため、項目追加 END
    
    
    // １部屋利用情報(1:1)
    public class BI_EMAIL_RoomAndGuestInfo {
        public BI_EMAIL_RoomsInfo room;
        //public List<Date> roomDateLst;
        public List<BI_EMAIL_RoomRateInfomation> roomRateLst;
        public List<BI_EMAIL_GuestInfo> guestLst;
    }
    // 1部屋の部屋料金情報(1:N){連泊}
    public class BI_EMAIL_RoomRateInfomation {
        public Date RoomDate;
        public Decimal PerPaxRate;
        public Decimal PerChildA70Rate;
        public Decimal PerChildB50Rate;
        public Decimal PerChildC30Rate;
        public Decimal PerChildDRate;
        public Decimal TotalPerRoomRate;
        public Decimal TotalRoomHotSpringTax;
        public Decimal TotalPerRoomServiceFee;
        
        // 2015/08/07 TL2WAY対応するため、項目追加 BEGIN
        public Decimal PerChildOtherRate;       //子供その他一人料金 
        public Decimal PerChildOtherRate2;      //子供その他2一人料金    
        public Decimal TotalPerRoomConsumptionTax;      //1室あたり宿泊料金消費税合計    
        public Decimal TotalPerRoomHotelTax;        //1室あたり宿泊料金ホテル税他合計  
        public Decimal TotalPerRoomBreakfastFee;        //1室あたり朝食料金合計   
        public Decimal TotalPerRoomOtherFee;        //1室あたりその他料金合計  
        public Decimal TotalPerRoomCommissionAmount;        //1室あたり手数料総額    
        public Decimal TotalPerRoomCommissionConsumptionTax;        //1室あたり手数料消費税額  
        public Decimal PerMaleRate;             //大人(男)一人料金
        public Decimal PerFemaleRate;               //大人(女)一人料金
        public Decimal RoomRatePaxMaleCount;            //大人人員（男性）
        public Decimal RoomRatePaxFemaleCount;              //大人人員（女性）
        public Decimal RoomRateChildA70Count;               //子供A人数
        public Decimal RoomRateChildB50Count;               //子供B人数
        public Decimal RoomRateChildC30Count;               //子供C人数
        public Decimal RoomRateChildDNoneCount;             //子供D人数
        public String RoomRatePaxMaleRequest;               //大人（男性）リクエスト
        public String RoomRatePaxFemaleRequest  ;           //大人（女性）リクエスト
        public String RoomRateChildA70Request;              //子供Aリクエスト
        public String RoomRateChildB50Request;              //子供Bリクエスト
        public String RoomRateChildC30Request;              //子供Cリクエスト
        public String RoomRateChildDNoneRequest;            //子供Dリクエスト
        // 2015/08/07 TL2WAY対応するため、項目追加 END     
    }
    // 部屋情報
    public class BI_EMAIL_RoomsInfo{
        public String RoomTypeCode;         //部屋タイプコード
        public String RoomTypeName;         //部屋タイプ名
        public String RoomCategory;         //部屋カテゴリー
        public String ViewType;         //部屋眺望
        public String SmokingOrNonSmoking;          //喫煙/禁煙
        public Integer PerRoomPaxCount;         //1室利用人数
        public Integer RoomPaxMaleCount;        //大人人員(男性)
        public Integer RoomPaxFemaleCount;          //大人人員(女性)
        public Integer RoomChildA70Count;           //子供A人数
        public Integer RoomChildB50Count;           //子供B人数
        public Integer RoomChildC30Count;           //子供C人数
        public Integer RoomChildDNoneCount;         //子供D人数
        public String Facilities;             // その他設備：複数存在場合、[,]連結して、設定を行う
        public String AssignedRoomNumber;       //部屋割り後客室名/番号
        public String RoomSpecialRequest;     // 客室に対する特別リクエスト：複数存在場合、[,]連結して、設定を行う
        
        // 2015/08/07 TL2WAY対応するため、項目追加 BEGIN
        public Integer RoomChildOtherCount;     //子供その他人数
        public Integer RoomChildOtherCount2;             //子供その他人数2
        public String RoomByRoomStatus;     //部屋毎予約ステイタス
        public String RoomByRoomConfirmationNumber;     //部屋毎予約番号   
        public String RoomPaxMaleRequest;             //大人人員(男性)備考
        public String RoomPaxFemaleRequest;             //大人人員(女性)備考
        public String RoomChildA70Request;             //子供A備考
        public String RoomChildB50Request;             //子供B備考
        public String RoomChildC30Request;             //子供C備考
        public String RoomChildDNoneRequest;             //子供D備考
        public String RoomChildOtherRequest;             //子供その他備考
        public String RoomChildOtherRequest2;             //子供その他備考2
        public String RoomTypeAgent;             //在庫引落先旅行会社ID
        public String RoomFrame;             //枠
        public String NetRmTypeGroupCode;             //ネット室タイプグループコード
        public String PlanGroupCode;             //プラングループコード
        public String RepresentativePersonName;             //代表者名
        // 2015/08/07 TL2WAY対応するため、項目追加 END
    }
    // 顧客情報
    public class BI_EMAIL_GuestInfo {
        public String GuestNameSingleByte;
        public String GuestSurName;
        public String GuestKanjiName;
        public String GuestGender;                // お客様男女区分
        public String GuestPhoneNumber;
        public Integer GuestAge;
        public Date GuestDateOfBirth;
        public String GuestEmergencyPhoneNumber;  // お客様緊急連絡先
        public String GuestEmail;                 // お客様Email
        public String GuestStateProvidence;       // お客様住所都道府県
        
        // 2015/08/07 TL2WAY対応するため、項目追加 BEGIN
        public String GuestGivenName;   //お客様氏名全角ふりがな(名)
        public String GuestMiddleName;  //お客様氏名半角英字(ミドルネーム)
        public String GuestNamePrefix;  //お客様肩書き
        public String GuestType;           //お客様人員区分
        public String GuestShubetsu;           //お客様種別
        public String GuestCountry;        //お客様国籍
        public String GuestCityName;           //お客様住所区市名
        public String GuestAddressLine;        //お客様住所町村名
        public String GuestStreetNumber;           //お客様住所番地名
        public String GuestPostalCode;         //お客様住所郵便番号
        public String GuestBuildingName;           //お客様住所ビル・部屋名
        public String GuestFFPCarrier;         //お客様FFPキャリア
        public String GuestFFPNumber;          //お客様FFPNo.
        public String GuestCoachNumber;        //お客様バス号車番号
        public String SpecialInformation;          //お客様特記情報
        // 2015/08/07 TL2WAY対応するため、項目追加 END
    }
    // リザプリ情報[07]
    public class BI_EMAIL_Risaplsinformation {
        // 07-01
        public BI_EMAIL_RisaplsCommonInformation risaplsCommonInformation;     // リザプリ共通情報
        
        // 2015/08/07 TL2WAY対応するため、項目追加 BEGIN
        public BI_EMAIL_AgentNativeInformation agentNativeInformation;     // リザプリ共通情報
        // 2015/08/07 TL2WAY対応するため、項目追加 END
        public BI_EMAIL_Risaplsinformation(){
        	risaplsCommonInformation = new BI_EMAIL_RisaplsCommonInformation();
        	agentNativeInformation = new BI_EMAIL_AgentNativeInformation();
        }
    }
    // リザプリ共通情報[07-01]
    public class BI_EMAIL_RisaplsCommonInformation {
        public BI_EMAIL_RisaplBasic risaplBasic;                                           // 予約基本情報
        public BI_EMAIL_Member member;     // [07-01-05]
        
        // 2015/08/07 TL2WAY対応するため、項目追加 BEGIN
        public BI_EMAIL_Allotment allotment;       //予約情報      
        public List<BI_EMAIL_Option> option;       //オプション情報
        public List<BI_EMAIL_RoomAndRoomRateInformation> roomAndRoomRateInformationLst;        //個々の部屋と部屋料金情報  
        public List<BI_EMAIL_BlockReport> blockReportLst;      //提供室数、残室   
        public BI_EMAIL_OtherInfo otherInfo;       //その他情報 
        public BI_EMAIL_BasicRate basicRate;       //基本料金情報                
        // 2015/08/07 TL2WAY対応するため、項目追加 END
    }
    // 予約基本情報[07-01-01]
    public class BI_EMAIL_RisaplBasic {
        public String SalesOfficeCompanyCode;       // 旅行会社コード
        public String TelegramDiv;          //電文種別
        public String RisaplsDataID;            //リザプリデータID·
        public String RisaplsTelegramNumber;            //リザプリ電文ID
        public String TelegramData;                 // リザプリ電文
        public String PhoneNumber;      //  団体または代表者番号 String
        public String Email;        //  団体または代表者Email String
        public String PostalCode;       //  団体または代表者郵便番号 String
        public String Address;      //  団体または代表者住所 String
        public String TotalPaxManCount;     //  大人人数 Integer
        public String BranchFaxNumber;      //  旅行会社営業所FAX番号 String
        public String Version;      //  TravelXML(シーナッツXML)バージョン String
        public String RepresentativeMiddleName;     //  代表者ミドルネーム String
        public String RepresentativePhoneType;      //  代表者連絡先種別 String
        public String RepresentativeAge;        //  代表者年齢 String
        public String RepresentativeCellularPhone;      //  代表者携帯電話 String
        public String RepresentativeOfficialPhone;      //  代表者勤務先電話番号 String
        public String RepresentativeGeneration;     //  代表者年代 String
        public String RepresentativeGendar;     //  代表者男女区分 Integer
        public String RepresentativeCorp;             //代表者会社
        public String RepresentativeDep;              //代表者所属部署
        public String RepresentativeOccupation;           //代表者ご職業
        public String RepresentativePost;             //代表者役職
        public String RepresentativeOfficeAddr;           //代表者勤務先住所
        public String RepresentativeOfficeFAX;            //代表者勤務先FAX番号
        public String RepresentativeID;           //代表者会員番号
        public String RepresentativeType;             //代表者会員種別
        public String RepresentativeDateOfBirth;              //代表者生年月日
        public String RepresentativeMailMagazineFromAccommodation;            //宿泊施設からのメ ルマ ガ受 信希 望( 宿泊者)
        public String AccommodationId;      //  施設ID String
    }
    
    // 2015/08/07 TL2WAY対応するため、項目追加 BEGIN
    public class BI_EMAIL_Allotment {
        public Integer AssignDiv;            //部屋割区分
        public Integer GenderDiv;            //男女区分
        public Integer HandleDiv;            //取扱区分
        public Integer RsvUserDiv;           //予約者情報区分
        public Integer UseDiv;           //利用区分
    }
    
    public class BI_EMAIL_Option {
        public Date OptionDate;             //オプション利用年月日
        public String Name;             //オプション名称
        public String NameRequest;          //オプション名備考
        public Integer OptionCount;             //オプション個数
        public Integer OptionRate;          //オプション料金単価
        public String OptionCode;           //オプションコード
    }
    
    public class BI_EMAIL_RoomAndRoomRateInformation {
        public BI_EMAIL_RoomsInfo room;
        public List<BI_EMAIL_RoomRateInfomation> roomRateLst;
        public List<BI_EMAIL_GuestInfo> guestLst;
    }   
    
    public class BI_EMAIL_GuestInformation {
        public String GuestNameSingleByte;          //お客様氏名半角カタカナ英字(姓名)
        public String GuestSurName;             //お客様氏名全角ふりがな(姓)
        public String GuestGivenName;           //お客様氏名全角ふりがな(名)
        public String GuestMiddleName;          //お客様氏名半角英字(ミドルネーム)
        public String GuestNamePrefix;          //お客様肩書き
        public String GuestKanjiName;           //お客様氏名全角漢字(姓名)
        public String GuestGender;          //お客様男女区分
        public Integer GuestAge;            //お客様年齢
        public Date GuestDateOfBirth;           //お客様生年月日
        public String GuestType;            //お客様人員区分
        public String GuestShubetsu;            //お客様種別
        public String GuestPhoneNumber;             //お客様電話番号
        public String GuestEmergencyPhoneNumber;            //お客様緊急連絡先
        public String GuestEmail;           //お客様Email
        public String GuestCountry;             //お客様国籍
        public String GuestStateProvidence;             //お客様住所都道府県
        public String GuestCityName;            //お客様住所区市名
        public String GuestAddressLine;             //お客様住所町村名
        public String GuestStreetNumber;            //お客様住所番地名
        public String GuestPostalCode;          //お客様住所郵便番号
        public String GuestBuildingName;            //お客様住所ビル・部屋名
        public String GuestFFPCarrier;          //お客様FFPキャリア
        public String GuestFFPNumber;           //お客様FFPNo.
        public String GuestCoachNumber;             //お客様バス号車番号
        public String SpecialInformation;           //お客様特記情報
    }
    
    public class BI_EMAIL_BlockReport {
        public String RoomTypeCode;             //部屋タイプコード
        public String InquiryDate;              //照会日
        public Integer TotalRoomsBlock;             //提供室数
        public Integer TotalRoomsNotYetSold;                //残室数
    }
    
    public class BI_EMAIL_OtherInfo {
        public String Reference;              //通信欄
        public String GuestRequest;           //お客様からの要望
        public String AdditionalInformation;              //予約補足情報
        public List<BI_EMAIL_QuestionAndAnswerInfo> questionAndAnswerLst;            //宿泊者への質問と回答リスト
    }
    
    public class BI_EMAIL_QuestionAndAnswerInfo {
        public String QuestionToGuest;         //宿泊者への質問
        public String AnswerToHotel;           //宿泊者からの回答       
    }
    
    public class BI_EMAIL_BasicRate {
        public Integer TotalAccomodationServiceCharge;               //合計宿泊料金に対するサービス料
        public List<BI_EMAIL_PointsDiscountInfo> pointsDiscountLst;                 //ポイント割引・補助金情報
        public List<BI_EMAIL_DepositInfo> depositLst;               //デポジット情報
    }
    
    public class BI_EMAIL_PointsDiscountInfo {
        public Integer PointsDiv;                //ポイント割引・補助金区分
        public String PointsDiscountName;                //ポイント割引・補助金名称
        public Integer PointsDiscount;               //ポイント割引・補助金額
    }
    
    public class BI_EMAIL_DepositInfo {        
        public Integer DepositAmount;         //デポジット額
    }
    
    public class BI_EMAIL_AgentNativeInformation{
        public BI_EMAIL_Extend extend;         //独自情報1
        public BI_EMAIL_Extendmytrip extendmytrip;         //独自情報2
        public BI_EMAIL_AgentNativeInformation(){
        	extend = new BI_EMAIL_Extend();
        	extendmytrip = new BI_EMAIL_Extendmytrip();
        }
    }
    
    public class BI_EMAIL_Extend{
        public String PointDiv;            //ポイント区分
        public String PointName;               //ポイント名称・補助金名称
        public Decimal Points;             //ポイント割引金額・補助金額
        public Integer TotalAccommodationDecleasePoints;               //割引後の総額
        public Integer TotalAccommodationConsumptionTax;               //割引後の総額に対する、消費税額
        public Integer AmountClaimed;              //宿泊者請求額
        public String Pamphlet;            //パンフレット利用フラグ
        public String FromHotelQuestion;               //宿泊施設への質問事項
        public String ToHotelAnswer;               //宿泊施設からの回答
        public String AgentComment;            //じゃらんnetから宿泊施設へのコメント
    }
    
    public class BI_EMAIL_Extendmytrip{
        public String VIPCode;                //VIPコード
        public String GetPoint;               //付与ポイント
        public String UsePoint;               //充当ポイント
        public String ChargeEquation;                 //宿泊料金計算式
        public String ReceiveDateTime;                //受付日
        public String CancelDateTime;                 //キャンセル受付日
        public String Answer1;                //質問への回答1
        public String Answer2;                //質問への回答2
        public String Answer3;                //質問への回答3
        public String Answer4;                //質問への回答4
        public String Answer5;                //質問への回答5
        public String AgoRsvNumber;               //変更前予約番号
        public String FromRsvNumber;                  //変更後予約番号
        public String TodayReserve;               //当日予約
        public String RoomSelect;                 //室タイプ選択
        public String Reference;                  //通信欄
        public Integer TotalMaleCount;                //合計男性人数
        public Integer TotalFemaleCount;                  //合計女性人数
        public Integer SettlementDiv;                 //事前決済区分
        public String CancellationCharge;                 //事前決済に対するキャンセル料金
        public String CancellationNotice;                 //取消料補足説明事項
    }
    // 2015/08/07 TL2WAY対応するため、項目追加 END
    
    
    
    // 予約者・会員情報[07-01-05]
    public class BI_EMAIL_Member {
        public String UserName; //  予約者・会員名漢字 
        public String UserKana; //  予約者・会員名カタカナ 
        public String UserTel;  //  予約者・会員電話番号 
        public String UserMailAddr; //  予約者・会員Email 
        public String UserZip;  //  予約者・会員郵便番号 
        public String UserAddr; //  予約者・会員住所 
        public String UserCorp; //  予約者・会員会社 
        public String UserDep;  //  予約者・会員所属部署 
        public String UserID;   //  予約者・会員番号 
        public String UserGivingPoints; //  付与ポイント 
        public String UserUsePoints;    //  使用ポイント 
        public String UserType; //  会員種別 
        public String UserDateOfBirth;  //  予約者生年月日 
        public String UserGendar;   //  予約者性別 
        public String UserEmergencyPhoneNumber; //  予約者緊急連絡先番号(携帯等) 
        public String UserOfficePhone;  //  予約者勤務先電話番号 
        public String UserCorpID;   //  予約者・会員会社コード 
        public String UserCorpKana; //  予約者・会員会社名カナ 
        public String MemberOfficePostalCode;   //  予約者・会員勤務先郵便番号 
        
        // 2015/08/07 TL2WAY対応するため、項目追加 BEGIN
        public String UserOccupation;                   //予約者ご職業
        public String UserMailMagazineFromAccommodation;                //宿泊施設からのメルマガ受信希望(予約
        public String UserMiddleName;                   //予約者ミドルネーム
        public String UserPost;                 //予約者役職
        public String UserOfficeAddr;                   //予約者勤務先住所
        public String UserOfficeFAX ;               //予約者勤務先FAX番号
        public String UserTotalPoint;                   //累計ポイント
        // 2015/08/07 TL2WAY対応するため、項目追加 END
        
    }

    public class BI_EMAIL_SyncResult {
        // 処理結果
        public BI_EMAIL_Result result;
        public Id sfdcId;
        public String message;
        public Id sfdcJobId;
        public Id sfdcDocumentParentId;
    }
    // 戻る結果：処理成功、処理失敗、処理中。
    public enum BI_EMAIL_Result{OK, NG, WAIT}
    // INS:新規 / UPD:更新 / 削除：キャンセル
    public enum BI_EMAIL_DmlAction{INS, UPD, CANCEL, CONFIRM, TEJIMA, ISSUE, OTHER }
    //public enum BI_FILTER_STATUS{EXCLUDE,INCLUDE,OTHER}
    //public enum BI_BOOKING_MODE{DEF,STOP}
}