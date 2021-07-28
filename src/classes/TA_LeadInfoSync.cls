/**
* バッチ連携：外から連携する予約情報はSFへ連携する
* TA-手間いらず予約取込機能
* 2016/06/02 新規予約情報を重複取り込み回避対応（同じ予約番号が存在すると、新規取り込みなし、XMLのみコピーする）
* 2016/06/10 子供料金プラン取り込み機能対応
* 2016/06/17 取り込みの税サ区分はSFDC側の単価定義区分を参照する対応
* 2016/06/17 取り込みの見積明細の順番は調整対応（プランは一番上、その後、会計商品コード順昇順)
* 2016/07/10 予約チャネル名の変換機能追加対応
* 2016/10/19 部屋タイプと部屋が1対1の場合は故障部屋を割当される不具合改修
* 2016/10/21 TA変更機能改善対応、予約変更の場合、予約名を上書きしない、到着日を変更すると、既に割当される部屋をクリア処理追加、項目値自動設定不具合改修
* 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修
* 2017/02/21 お子様プランの料金PRICE機能追加
* 2017/02/21 RoomRate部分为空、取込エラー不具合改修
* 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応
* 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応
* 2017/08/02 料金の12%が事前払い
* 2017/09/01 最大文字数をこえない問題回避対応
* 2018/07/09 [GuestOrGroupNameSingleByte、GuestOrGroupNameKanjiName]非存在の場合、取り込みできるように改善
* 2018/07/19 SalesforceIDが重複取り込対応
* 2018/12/30 TA予約変更通知の際に、部屋タイプを自動変更できるように改善対応
* 2019/03/15 (無料)小人0円が小人プランに紐付できるように改善対応
* 2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する
* 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善
* 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応
* 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する
* 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善
* 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善
* 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加
* 2020/07/30 入湯税の自動入力機能について改善
* 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善
**/
public with sharing class TA_LeadInfoSync {
 /// 中継アプリの名
    private static final String APPNAME = CommConst.BI_PROCESS_TYPE.TA.name(); 
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
    // 日帰到着時刻初期値
    //private static final String defaultDayUseCheckInTime = CommConst.DEF_DAYUSE_CHECKIN_TIME;
    private static String defaultDayUseCheckInTime;
    private static String defaultDayUseCheckOtTime;
    // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
    // 店舗別プラン設定機能判断フラグ
    private static final Boolean isPlanOfShopFlg = CommConst.APPOTION_BI_SHOPPLAN_FLG;
    // 部屋自動割り当て
    private static Boolean oneRoomAutoAssingRoomFlg { get{ return CommDefine__c.getOrgDefaults().AdvancesReceivedChk__c; }}
    // 店舗コード
    private String shopCd;
    // ログ出力機能
    public CommLogUtils mLogUtils{get; private set;}
    // 入湯税会計商品情報格納用
    private AccountMaster__c nyuuTouAcc;
    // サビース料会計商品情報格納用
    private AccountMaster__c serviceAcc;
    // 調整可能のプラン明細情報の格納
    private planDetailInfo gPlanDetailInf;
    // 予約取込機能改善（変更、キャンセル） BEGIN
    private Integer LEAD_CREATE_TIME_DIFF_INT = 60000;
    private String bookingDataId;
    // 予約取込機能改善（変更、キャンセル） END
    // 予約キャンセルの場合、キャンセル内容は本文メールに反映を行う
    private static final Integer commentLength = Lead__c.Comment3__c.getDescribe().getLength();
    private static final Integer emailLength = Lead__c.email__c.getDescribe().getLength();
    // 2017/09/01 最大文字数をこえない問題回避対応 BEGIN
    private static final Integer indexCommentLength = LeadIndex__c.Comment__c.getDescribe().getLength();
    // 2017/09/01 最大文字数をこえない問題回避対応 END
    // ネット取込する場合、XMLタグに、室料合計料金のみが存在場合、N人数に対して、室料/人数で計算できる場合、自動計算して、人数＊単価で明細に反映
    private boolean presonRateAutoCal = true;
    // 消費税情報
	private JMST__c taxRateMst;
	// 2018/07/19 SalesforceIDが重複取り込対応 BEGIN by zh
    private Boolean isDupNumberFlg = false;
    // 2018/07/19 SalesforceIDが重複取り込対応 END by zh
    /**
    * インスタント化
    **/
    public TA_LeadInfoSync() {
        mLogUtils = new CommLogUtils('TA_LeadInfoSync',true);
    }
    /*
    * 外部から予約データ連携機能 
    */
    public BI_TA_SyncResult upsertTALeadInfo(BI_TA_SyncInfo bookingInfo,String shopCode) {
        mLogUtils.write_method_start('upsertTALeadInfo');
        // 店舗コード
        shopCd = shopCode;
        // 変更、キャンセルする場合、予約取込するがどうか判断用フラグ:TRUEの場合、取込みを行う
        Boolean ucIsSyncFlg = TA_ServiceConfigHelp.getAppConfig(shopCd).ucactisSync;
        presonRateAutoCal = TA_ServiceConfigHelp.getAppConfig(shopCd).presonRateAutoCal;
        // 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 ZH BEGIN
        if (TA_ServiceConfigHelp.getAppConfig(shopCd).romanToKanaFlag) convertGuestInfo(bookingInfo);
        // 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 ZH END
        // 予約取込機能改善（変更、キャンセル） BEGIN
        LEAD_CREATE_TIME_DIFF_INT = TA_ServiceConfigHelp.getCommConfig().mLeadTimeLimit;
        bookingDataId = APPNAME + '_' + bookingInfo.DataID;
        // 予約取込機能改善（変更、キャンセル） END
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
        BI_TA_SyncResult rs = new BI_TA_SyncResult();
Savepoint sp = Database.setSavepoint();
try {
        // 変更、キャンセル連携処理の場合
        if (bookingInfo.dmlAction == BI_TA_DmlAction.UPD ||
            bookingInfo.dmlAction == BI_TA_DmlAction.CANCEL) {
            // 予約管理ID[新たな予約グループが発生したときに新規発番]
            String DataID = bookingInfo.DataID;
            if(CommUtils.isBlank(DataID)){
                rs.result = BI_TA_Result.NG;
                mLogUtils.write_method_end();
                return rs;
            }
            mLogUtils.write_log('DataID::' + DataID);
            // 既存の予約インデックス情報を取得する
            List<LeadIndex__c> rslst = getExistLeadIndexByDataId(bookingInfo);
            // 既存の予約情報がない場合
            if (rslst.isEmpty()) {
                // 変更の場合、新規作成を行う
                if (bookingInfo.dmlAction == BI_TA_DmlAction.UPD) {
                    // 元の予約インデックスは何も処理を行わない
                    mLogUtils.write_log('DataIDと一致するご予約情報はSalesforceからみつかりません。元のデータが更新対象外になる');
                } 
                // 次の変更後の新規処理を行う
                else if (bookingInfo.dmlAction == BI_TA_DmlAction.CANCEL) {
                    mLogUtils.write_log('DataIDと一致するご予約情報はSalesforceからみつかりません。元のデータがキャンセル対象外になる');
                    // 予約インデックスのみ作成して、XMLを格納する
                    // DataIDが非存在する場合、単に該当XMLはSalesforceにアップロードを行う
                    LeadIndex__c dumyIndex = new LeadIndex__c(ID__c = DataID,EventSource__c = bookingInfo.transactionType.DataFrom,StatusLst__c = CommConst.LEAD_ST_CANCEL,APPNAME__c = APPNAME);
                    insert dumyIndex;
                    mLogUtils.write_log('該当キャンセルXMLファイルは下記予約インデックス['+dumyIndex.Id+'にアップロード済');
                    rs.sfdcId = dumyIndex.Id;
                    // キャンセルの場合、新規の予約インデックスデータのみ作成して、XMLを格納する
                    rs.result = BI_TA_Result.OK;
                    mLogUtils.write_method_end();
                    return rs;
                }
            }
            // 既存の予約関連情報が存在する場合
            else {
                // 変更時刻を設定する
                LeadIndex__c leadIndex = rslst[0];
                // 変更時刻情報を設定を行う
                if (bookingInfo.dmlAction == BI_TA_DmlAction.UPD) {
                    leadIndex.TravelAgencyBookingUpdDateTime__c = DateTime.newInstance(bookingInfo.basic.TravelAgencyBookingDate, bookingInfo.basic.TravelAgencyBookingTime !=null?bookingInfo.basic.TravelAgencyBookingTime: Time.newInstance(0,0,0,0) );
                }
                if (bookingInfo.dmlAction == BI_TA_DmlAction.CANCEL) {
                    leadIndex.TravelAgencyBookingDelDateTime__c = DateTime.newInstance(bookingInfo.basic.TravelAgencyBookingDate, bookingInfo.basic.TravelAgencyBookingTime !=null?bookingInfo.basic.TravelAgencyBookingTime: Time.newInstance(0,0,0,0));
                }
                // 予約インデックスのデータ種別に更新を行う
                leadIndex.DataClassification__c = bookingInfo.dmlAction.name();
                // 変更、キャンセル連動対応の場合、予約インストールのステータスも取消を行う
                if (ucIsSyncFlg && bookingInfo.dmlAction == BI_TA_DmlAction.CANCEL) {
                    leadIndex.StatusLst__c = CommConst.LEAD_ST_CANCEL;
                }
                update leadIndex;
                // 変更、キャンセル情報を取込ない制御の場合
                if (!ucIsSyncFlg) {
                    mLogUtils.write_log('変更、キャンセルするため、予約取込処理対象外になる');
                    rs.sfdcId = rslst[0].Id;
                    rs.result = BI_TA_Result.OK;
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
                if (bookingInfo.dmlAction == BI_TA_DmlAction.CANCEL) {
                    // メール本文[7XXXXX]
                    //BI_TL_RisaplBasic risaplBasic = bookingInfo.risaplsinformation.risaplsCommonInformation.risaplBasic;
                    // 同じ予約インデックスを所属する予約情報は全部キャンセルを行う
                    //orgLeadLst = [  select id, ReservedStatus__c,Comment3__c,EventSource__c,email__c
                    orgLeadLst = [  select id, ReservedStatus__c,Comment3__c,RoomGroupNo__c,EntryTime__c,LeadIndexSubId__c,LeadIndexRef__c
                                            ,email__c,Relcontact__c,Field2__c,EventSource__c,BookingDataID__c,Departure__c,CreatedDate 
                                            ,Nights__c,PlanSycnFlag__c,LeadIndexRef__r.LeadName__c,Name,refTypeOfRooms__c,Rroom__c
                							// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ BEGIN
                							,RoomUpdFlg__c
                							// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ END
                                    from Lead__c 
                                    where (LeadIndexRef__c = :leadIndex.id or LeadIndexSubId__c = :subLeadIds)
                                    And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG ];
//mLogUtils.write_log('orgLeadLst：：：：'+orgLeadLst);                    
                    List<Lead__c> emailUpdLeadLst = filterTLImportData(orgLeadLst,bookingInfo,leadIndex,subLeadIds);
//mLogUtils.write_log('emailUpdLeadLst：：：：'+emailUpdLeadLst);  
                    for (Lead__c orgLead : emailUpdLeadLst) {
                    	// メール本番設定機能、メール内容を取得、設定を行う
						String emailMsg = mailArea(bookingInfo);
                        orgLead.email__c = CommLogUtils.removeOverLogString(emailMsg + '\n\n\n' + CommUtils.nullToBlank(orgLead.email__c),emailLength);
//mLogUtils.write_log('orgLead.email__c：：：：'+orgLead.email__c); 
                    } 
                }else if (bookingInfo.dmlAction == BI_TA_DmlAction.UPD) {
                    // 2018/07/19 SalesforceIDが重複取り込対応 BEGIN
                    // 複数予約番号が非存在場合
                    if (!isDupNumberFlg) {
                    // 2018/07/19 SalesforceIDが重複取り込対応 END
                     // 既存予約変更、キャンセル処理する場合、既存の予約情報を一回キャンセルを更新する
                    orgLeadLst = [  select id, ReservedStatus__c,Comment3__c,RoomGroupNo__c,EntryTime__c,LeadIndexSubId__c,LeadIndexRef__c
                                            ,email__c,Relcontact__c,Field2__c,EventSource__c,BookingDataID__c,Departure__c,CreatedDate 
                                            ,Nights__c,PlanSycnFlag__c,LeadIndexRef__r.LeadName__c,Name,refTypeOfRooms__c,Rroom__c
                                            ,Field348__c
                                            // TA予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh BEGIN
                                            ,Field276__c
                                            // TA予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh END
                							// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ BEGIN
                							,RoomUpdFlg__c
                							// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ END
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
                    	// 2018/07/19 SalesforceIDが重複取り込対応 BEGIN
                    } else {
                        // 既存予約変更、キャンセル処理する場合、既存の予約情報を一回キャンセルを更新する
                        orgLeadLst = [select id, ReservedStatus__c, Comment3__c, RoomGroupNo__c, EntryTime__c, LeadIndexSubId__c, LeadIndexRef__c, email__c, Relcontact__c, Field2__c, EventSource__c, BookingDataID__c, Departure__c, CreatedDate, Nights__c, PlanSycnFlag__c, LeadIndexRef__r.LeadName__c, Name, refTypeOfRooms__c, Rroom__c, Field348__c
                            // TA予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh BEGIN
                            ,Field276__c
                            // TA予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh END
							// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ BEGIN
							,RoomUpdFlg__c
							// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ END
                            from Lead__c
                            // 同じ予約インデックスに所属する　OR　
                            where LeadIndexRef__c =: leadIndex.id
                            And CancelBool__c !=: CommConst.LEAD_ST_CANCEL_FLG
                            // and LeadIndexSubId__c = :subLeadIds
                            // and LeadIndexSubId__c != null 
                            // 同じ部屋、泊数順番で既存予約情報を取得する
                            order by LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c, EntryTime__c
                        ];
                        // 予約変更の場合、電文から作成の予約情報のみ変更処理を行う、その以外の予約情報は処理対象外になる
                        orgLeadLst = filterTLImportData(orgLeadLst, bookingInfo, leadIndex, subLeadIds);
                    }
                    // 2018/07/19 SalesforceIDが重複取り込対応 END
                }
                mLogUtils.write_log('orgLeadLst::' + orgLeadLst.size());
                // 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ BEGIN
                boolean chgRoomTypeFlag = TA_ServiceConfigHelp.getAppConfig(shopCd).chgRoomTypeFlag;
                // 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ END
                // アクセス権限制限するため、キャンセル処理する場合、削除から更新に変更する
                for (Lead__c lead : orgLeadLst) {
                    // 予約変更処理ロジック対応するため、下記設定ロジックを変更する BEGIN
                    String cancelMessage = '<br/>' + System.now().format('yyyy/MM/dd HH:mm:ss:SSS')+' ';
                    if (bookingInfo.dmlAction == BI_TA_DmlAction.CANCEL) {
                        cancelMessage += 'キャンセル対応';
                        lead.EventSource__c = APPNAME + '_' + bookingInfo.DataID + '_' + DateTime.now().getTime();
                        lead.ReservedStatus__c = CommConst.LEAD_ST_CANCEL;
                    } else if (bookingInfo.dmlAction == BI_TA_DmlAction.UPD) {
                        cancelMessage += '予約変更対応';
                    }
                    // 予約変更処理ロジック対応するため、下記設定ロジックを変更する END
                    // 2017/09/01 最大文字数をこえない問題回避対応 BEGIN
                    //lead.Comment3__c = CommUtils.nullToBlank(lead.Comment3__c) + cancelMessage;
                    lead.Comment3__c = CommLogUtils.removeOverLogString(CommUtils.nullToBlank(lead.Comment3__c) + cancelMessage, commentLength);
                    // 2017/09/01 最大文字数をこえない問題回避対応 END
                    // 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ BEGIN
                    if (chgRoomTypeFlag) lead.RoomUpdFlg__c = !lead.RoomUpdFlg__c;
                    // 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ END
                }
                //予約変更処理ロジック対応するため、キャンセルのみ場合、既存予約情報をキャンセルする
                if (bookingInfo.dmlAction == BI_TA_DmlAction.CANCEL) {
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
                    rs.result = BI_TA_Result.OK;
                    mLogUtils.write_method_end();
                    return rs;
                }
            }
        }
        // 2016/06/02 新規予約情報を重複取り込み回避対応（同じ予約番号が存在すると、新規取り込みなし、XMLのみコピーする） BEGIN
        else if(bookingInfo.dmlAction == BI_TA_DmlAction.INS ){
            String DataID = bookingInfo.DataID;
            if(CommUtils.isBlank(DataID)){
                rs.result = BI_TA_Result.NG;
                mLogUtils.write_method_end();
                return rs;
            }
if (!TA_ServiceConfigHelp.getCommConfig().bIsDebug) {
            List<LeadIndex__c> rslst = getExistLeadIndexByDataId(bookingInfo);
            if (!rslst.isEmpty()) {
                if(bookingInfo.dmlAction == BI_TA_DmlAction.INS){
                    mLogUtils.write_log('該当データID[' + DataID + ']SalesforceID[' + rslst[0].Id + ']の予約情報は既に取込済ため、重複取込できません。');
                    rs.sfdcId = rslst[0].Id;
                    rs.result = BI_TA_Result.OK;
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
            //Contact pkuser = upsertContact(bookingInfo,orgLeadLst.isEmpty() ? null : orgLeadLst[0]);
            Contact pkuser = upsertContact(bookingInfo,orgLeadLst.isEmpty() ? null : orgLeadLst[0]);
            // 予約インデックスオブジェクト
            LeadIndex__c leadIndex = upsertLeadIndex(bookingInfo, pkuser, traveCompany);
            // 予約データを作成する　
            upsertTALead(bookingInfo, leadIndex, pkuser, traveCompany,shopCode,orgLeadLst);
//mLogUtils.write_log('===upsertTALead FINISH===');
            // 処理結果設定を行う
            rs.sfdcId = leadIndex.Id;
//mLogUtils.write_log('===upsertTALead leadIndex===' + leadIndex);
            rs.result = BI_TA_Result.OK;
        } catch (CommException ex) {
        	DataBase.rollback(sp);
            System.debug(ex.getMessage());
            rs.result = BI_TA_Result.NG;
            rs.message = ex.getMessage();
            mLogUtils.write_error(ex.getStackTraceString());
            //mLogUtils.write_method_end();
        } catch (Exception e) {
        	DataBase.rollback(sp);
            mLogUtils.write_error(e.getStackTraceString());
            rs.result = BI_TA_Result.NG;
            rs.message = e.getMessage();
            //mLogUtils.write_method_end();
        }
        mLogUtils.write_method_end();
//System.debug(loggingLevel.INFO, 'LOG='+mLogUtils.getAllLog());
        return rs;
    }
    // 既存予約INDEX情報を取得する
    private List<LeadIndex__c> getExistLeadIndexByDataId(BI_TA_SyncInfo bookingInfo) {
    	// 2018/07/19 SalesforceIDが重複取り込対応 BEGIN by zh
        //return [select id,EntryDate__c,CreatedDate,LeadName__c from LeadIndex__c where ID__c = :bookingInfo.DataID And EventSource__c = :bookingInfo.transactionType.DataFrom And (APPNAME__c = :APPNAME OR APPNAME__c = null ) and StatusLst__c != :CommConst.LEAD_ST_CANCEL order by CreatedDate desc limit 1];
    	List < LeadIndex__c > leadindexs = [select id,EntryDate__c,CreatedDate,LeadName__c 
	    	from LeadIndex__c 
	    	where ID__c = :bookingInfo.DataID 
	    	And EventSource__c = :bookingInfo.transactionType.DataFrom 
	    	And (APPNAME__c = :APPNAME OR APPNAME__c = null ) 
	    	and StatusLst__c != :CommConst.LEAD_ST_CANCEL 
	    	//order by CreatedDate desc limit 1
	        order by CreatedDate desc
        ];
        mLogUtils.write_log('既存予約インデックス件数：'+leadindexs.size());
        // 予約情報が重複存在する場合、既存関連の予約情報、AGT情報を判断する
	// 2018/09/19 SalesforceIDが重複取り込対応 BEGIN
        //Integer checkRsSize = (bookingInfo.dmlAction == BI_TA_DmlAction.INS ? 0 : 1);
	// 2018/09/19 SalesforceIDが重複取り込対応 END
    	isDupNumberFlg = false;
        // 2018/09/19 SalesforceIDが重複取り込対応 BEGIN
        //if (leadindexs.size() > checkRsSize) {
        if (!leadindexs.isEmpty()) {
        // 2018/09/19 SalesforceIDが重複取り込対応 END
        	// 予約番号が重複存在することが発生する
            isDupNumberFlg = true;
        	// チェック対象予約インデックス情報を格納用リスト
            List < LeadIndex__c > targetLeadIndex = new List < LeadIndex__c > ();
            map < id, LeadIndex__c > leadindexIds = new map < id, LeadIndex__c > ();
            for (LeadIndex__c leadIdx: leadindexs) leadindexIds.put(leadIdx.Id, leadIdx);
            String SalesOfficeCompanyCode = CommUtils.nullToBlank(bookingInfo.salesOffice.SalesOfficeCompanyCode);
            // 既存予約の「旅行会計コード」と「店舗コード」と「予約番号」でチェック、情報一致存在するとき、該当予約に所属の予約インデックス情報を更新を行う
            List < Lead__c > relLeads = [select id, LeadIndexRef__c from Lead__c
                where LeadIndexRef__c =: leadindexIds.keyset()
                // 予約旅行会計コードチェック
                And(SalesOfficeInfoRef__r.SalesOfficeCompanyCodeTA__c =: salesOfficeCompanyCode OR SalesOfficeInfoRef__r.Parent.SalesOfficeCompanyCodeTA__c =: salesOfficeCompanyCode)
                And refTypeOfRooms__c in (select id from TypeOfRooms__c where ShopInfoRef__r.ShopCode__c =: shopCd)
                //And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 
                limit 1
            ];
            // 関連情報が存在するとき
            if (!relLeads.isEmpty()) {
                targetLeadIndex.add(leadindexIds.get(relLeads[0].LeadIndexRef__c));
            }
            return targetLeadIndex;
        }else {
            return leadindexs;
        }
    	// 2018/07/19 SalesforceIDが重複取り込対応 END by zh
    }
    
    /**
    * 予約基本情報
    **/
    private LeadIndex__c upsertLeadIndex(BI_TA_SyncInfo bookingInfo, Contact pkuser, List<Account> TraveCompany) {
        mLogUtils.write_method_start('upsertLeadIndex');
        List<LeadIndex__c> rslst = getExistLeadIndexByDataId(bookingInfo);
        boolean updFlag = bookingInfo.dmlAction == BI_TA_DmlAction.UPD;
        // 初期化処理を行う
        LeadIndex__c leadIndex = new LeadIndex__c();
        if(updFlag && !rslst.isEmpty()){
            leadIndex = rslst[0];
        }
        // 2016/10/21 TL変更機能改善対応[予約変更の場合、予約名を上書きしない対応] BEGIN
        boolean updFlgIsInsert = updFlag && rslst.isEmpty();// 更新　かつ　更新元はなかった場合、該当フラグはTRUE
        // 2016/10/21 TL変更機能改善対応[予約変更の場合、予約名を上書きしない対応] END
        if(updFlag || bookingInfo.dmlAction == BI_TA_DmlAction.INS) {   
            // 新規データ作成を行う
            DateTime checkInDt = (bookingInfo.basic.CheckInTime == null ? null : DateTime.newInstance(bookingInfo.basic.CheckInDate, bookingInfo.basic.CheckInTime));
            BI_TA_Member member = bookingInfo.member;
//mLogUtils.write_log('member:: ' + member);
//mLogUtils.write_log('pkuser:: ' + pkuser);
            leadIndex.APPNAME__c = APPNAME;
            leadIndex.DataClassification__c = bookingInfo.dmlAction.name();
            leadIndex.EventSource__c = bookingInfo.transactionType.DataFrom;
            leadIndex.ID__c = bookingInfo.DataID;
            leadIndex.TravelLeadNo__c = bookingInfo.basic.TravelAgencyBookingNumber;  
//mLogUtils.write_log('leadIndex[1]:: ' + leadIndex);
            leadIndex.EntryDate__c = bookingInfo.basic.CheckInDate;
            leadIndex.EntryTime__c = checkInDt == null ? (bookingInfo.basic.Nights == 0 ? defaultDayUseCheckInTime : defaultCheckInTimeStr) : checkInDt.format('HH:mm');
            leadIndex.DepartureDate__c = bookingInfo.basic.CheckOutDate == null ? (bookingInfo.basic.CheckInDate.addDays(bookingInfo.basic.Nights)) : bookingInfo.basic.CheckOutDate;
//mLogUtils.write_log('leadIndex[2]:: ' + leadIndex);
            // 補足情報を追加する BEGIN
            if(member != null){
                leadIndex.MemberUserName__c = member.UserName;  //会員名漢字
                leadIndex.MemberUserKana__c = member.UserKana;  //会員名カタカナ
                leadIndex.MemberAddPoint__c = member.UserGivinPoints;   //付与ポイント
                leadIndex.MemberUsePoint__c = member.UserUsePoints;     //使用ポイント
                leadIndex.MemberUserTel__c = member.UserTel;    // 会員電話番号 
                leadIndex.MemberUserMailAddr__c = member.UserMailAddr;  // 会員Email 
                leadIndex.MemberUserZip__c = member.UserZip;    // 会員郵便番号 
                leadIndex.MemberUserAddr__c = member.UserAddr;  // 会員住所 
                leadIndex.MemberUserCorp__c = member.UserCorp;  // 会員会社 
            }
//mLogUtils.write_log('leadIndex[3]:: ' + leadIndex);  
            leadIndex.TotalAccommodationCharge__c = String.valueOf(bookingInfo.basicRate.TotalAccommodationCharge);
//mLogUtils.write_log('leadIndex[3-1]:: ');  
            leadIndex.Payment__c = getLocalPaymentInfo(bookingInfo.basicRate.Payment);
//mLogUtils.write_log('leadIndex[3-2]:: ');  
            // 補足情報を追加する END
            // チェックアウト時間はDefault値設定を行う
            leadIndex.DepartureTime__c = (bookingInfo.basic.Nights == 0 
                                                // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
                                                //                ? (DateTime.newInstance(Date.today(), CommUtils.stringToTime(leadIndex.EntryTime__c).addHours(CommConst.DEF_DAYUSE_STAY_HOURS))).format('HH:mm') : defaultCheckoutTimeStr); 
                                                ? ( (bookingInfo.basic.CheckInTime == null) 
                                                   ? defaultDayUseCheckOtTime
                                                   : (DateTime.newInstance(Date.today(), CommUtils.stringToTime(leadIndex.EntryTime__c).addHours(CommConst.DEF_DAYUSE_STAY_HOURS))).format('HH:mm') 
                                                   )
                                                : defaultCheckoutTimeStr);
                                                // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
//mLogUtils.write_log('leadIndex[3-3]:: ');  
            leadIndex.Nights__c = bookingInfo.basic.Nights;
//mLogUtils.write_log('leadIndex[3-4]:: ');  
            if(CommUtils.isBlank(leadIndex.contactRef__c)) leadIndex.contactRef__c = pkuser.Id;
//mLogUtils.write_log('leadIndex[3-5]:: ');  
            leadIndex.Rooms__c = bookingInfo.roomAndGuestLst.size();
//mLogUtils.write_log('leadIndex[4]:: ' + leadIndex);  
            // 予約チャネルに設定を行う
            // ネットからの取込時に予約チャネルに旅行会社名で設定する BEGIN
            // 2016/07/10 予約チャネル名の変換機能追加対応 BEGIN
            //leadIndex.Channel__c = TraveCompany.size() > 0 ? TraveCompany[0].Name : null;
            leadIndex.Channel__c = getChanelStr(bookingInfo,TraveCompany);
            // 2016/07/10 予約チャネル名の変換機能追加対応 END
            // ネットからの取込時に予約チャネルに旅行会社名で設定する END
            // 予約名追加
            // 2016/10/21 TA変更機能改善対応[予約変更の場合、予約名を上書きしない対応] BEGIN
            if (updFlgIsInsert || bookingInfo.dmlAction == BI_TA_DmlAction.INS)
            // 2016/10/21 TA変更機能改善対応[予約変更の場合、予約名を上書きしない対応] END
            leadIndex.LeadName__c = CommUtils.isBlank(bookingInfo.basic.GuestOrGroupNameKanjiName) ? bookingInfo.basic.GuestOrGroupNameSingleByte : bookingInfo.basic.GuestOrGroupNameKanjiName;
            // 特記事項設定追加
            // 2017/09/01 最大文字数をこえない問題回避対応 BEGIN
            //leadIndex.Comment__c = bookingInfo.basic.OtherServiceInformation;
            leadIndex.Comment__c = CommLogUtils.removeOverLogString(bookingInfo.basic.OtherServiceInformation, indexCommentLength);
            // 2017/09/01 最大文字数をこえない問題回避対応 END
            leadIndex.TravelAgencyBookingInsDateTime__c = DateTime.newInstance(bookingInfo.basic.TravelAgencyBookingDate, bookingInfo.basic.TravelAgencyBookingTime !=null?bookingInfo.basic.TravelAgencyBookingTime: Time.newInstance(0,0,0,0));
//mLogUtils.write_log('leadIndex[5]:: ' + leadIndex);  
            upsert leadIndex;
        }
        mLogUtils.write_log('予約インデックスID:: ' + leadIndex.id);
        mLogUtils.write_method_end();
        return leadIndex;
    }
    
    /**
    * プラン情報を設定する
    * プラン未設定のケース場合
    **/
    private Plan__c upsertPlan(BI_TA_SyncInfo bookingInfo, List<Account> TraveCompany) {
        mLogUtils.write_method_start('upsertPlan');
        Plan__c rsPlan = null;
        // プランのPackageCode/プラン名は両方とも存在する場合、処理対象です
        if (CommUtils.isBlank(bookingInfo.basic.PackagePlanName) &&
            CommUtils.isBlank(bookingInfo.basic.PackagePlanCode)) { 
            mLogUtils.write_method_end();
            return rsPlan; 
        }
        // 同じプラン名情報を検索する
        List<Plan__c> existPlanLst = new List<Plan__c>();
        // プラン名が存在する場合とプランコード
        String packageCode = CommUtils.nullToBlank(bookingInfo.basic.PackagePlanCode);
        String packageName = CommUtils.nullToBlank(bookingInfo.basic.PackagePlanName);
        String agtId = TraveCompany.size() > 0 ? TraveCompany[0].Id : null;
        String shopCode = shopCd;
        // パッケージコードが存在する場合、パッケージからSFのプラン変換ルールをチエックする
        if (!CommUtils.isBlank(packageCode)) {
            String planNo = TA_ServiceConfigHelp.getSfPlanNoByAgtPlanInfo(shopCd,bookingInfo.salesOffice.SalesOfficeCompanyCode,packageCode);
            // 該当パッケージコードからSF側のプランNOが設定されている場合
            if(planNo != null){
                mLogUtils.write_log('AGTパッケージコード「'+packageCode+'」からPlanNo「'+planNo+'」に変換済');
                // 2020/07/30 入湯税の自動入力機能について改善 ZH BEGIN
                //List<Plan__c> planLst = [select Id, name,PlanNo__c,ShopInfoRef__c,client__c,Price__c,ServiceRate__c,JmstRef__r.TaxRate__c from Plan__c where IsClosed__c != true and PlanNo__c = :planNo limit 1];
                List<Plan__c> planLst = [select Id, name,PlanNo__c,ShopInfoRef__c,client__c,Price__c,ServiceRate__c,JmstRef__r.TaxRate__c,BathTaxAccMstRef__c from Plan__c where IsClosed__c != true and PlanNo__c = :planNo limit 1];
                // 2020/07/30 入湯税の自動入力機能について改善 ZH END
                if(!planLst.isEmpty()) return planLst[0];
            }
        }
    
        // 店舗情報格納する
        Map<String, ShopInformation__c> shopInfoMap = new Map<String, ShopInformation__c>(); 
        /* プラン検索ロジック変更、店舗検索機能を追加 */
        // 2020/07/30 入湯税の自動入力機能について改善 ZH BEGIN
        //String queryHeader = ' select Id, name,PlanNo__c,ServiceRate__c,JmstRef__r.TaxRate__c,Price__c  from Plan__c ';
        String queryHeader = ' select Id, name,PlanNo__c,ServiceRate__c,JmstRef__r.TaxRate__c,Price__c,BathTaxAccMstRef__c  from Plan__c ';
        // 2020/07/30 入湯税の自動入力機能について改善 ZH END
        String queryLimit = ' limit 1 ';
        // 非公開プランは検索対象外に対応
        String whereStr = ' Where IsClosed__c != true And (';
        // 店舗別単位でプラン設定する場合、店舗コードとプランのPackageCodeは合わせる確認が必要です
        if (isPlanOfShopFlg) {
            shopInfoMap = ShopInfoUtil.getShopInfoMap();
            whereStr += ' PackageCode__c != null And PackageCode__c = :packageCode And ShopInfoRef__r.ShopCode__c = :shopCode ';
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
            rsPlan.PackageCode__c = packageCode;
            rsPlan.client__c = agtId;
            rsPlan.JmstRef__c = taxRateMst.Id;
            // 2020/07/30 入湯税の自動入力機能について改善 ZH BEGIN
            if(!isPlanOfShopFlg && shopInfoMap.isEmpty()) shopInfoMap = ShopInfoUtil.getShopInfoMap();
            // 设定有效的关联入汤税商品ID
            rsPlan.BathTaxAccMstRef__c = CommLogicProcess.getBathTaxAccMstRef(shopInfoMap.get(shopCode), shopCode);
            // 2020/07/30 入湯税の自動入力機能について改善 ZH END
            insert rsPlan;
            // 新規作成のプラン情報を再取得する
            // 2020/07/30 入湯税の自動入力機能について改善 ZH BEGIN
            //rsPlan = [select Id, name,PlanNo__c,ServiceRate__c,JmstRef__r.TaxRate__c  from Plan__c where id = :rsPlan.id];
            rsPlan = [select Id, name,PlanNo__c,ServiceRate__c,JmstRef__r.TaxRate__c,BathTaxAccMstRef__c  from Plan__c where id = :rsPlan.id];
            // 2020/07/30 入湯税の自動入力機能について改善 ZH END
        }  else {
            rsPlan = existPlanLst[0];
        }
mLogUtils.write_log('rsPlan:' + rsPlan );
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
        gPlanDetailInf = new planDetailInfo();
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
    	// gPlanDetailInf.init(orgPdList);
    	gPlanDetailInf.init(orgPdList, plan);
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
		//, TL_ServiceConfigHelp.BOOKINGCONFIG bookingConfig
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
    // 2016/06/10 子供料金プラン取り込み機能対応  BGEIN
    // Rateー＞会計商品
    private map<string, AccountMaster__c> childPlanAccMstMap = new map<string, AccountMaster__c>();
    // 2017/02/21 お子様プランの料金PRICE機能追加 by zh BEGIN
    private map<string, AccountMaster__c> childPlanPriceAccMstMap = new map<string, AccountMaster__c>();
    // 2017/02/21 お子様プランの料金PRICE機能追加 by zh END
    // 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ BEGIN
    private map<String,String> childPlanNameConvertMap = new map<String,String>();
    // 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ END
    // 商品コードー＞プラン
    private map<string, Plan__c> childPlanPlanMstMap = new map<string, Plan__c>();
    // 商品コードー＞プラン明細
    private map<string, planDetailInfo> childPlanDetailMap = new map<string, planDetailInfo>();
    // childPlanConfigMap:Rate -> PlanNo
    // 2017/02/21 お子様プランの料金PRICE機能追加 by zh BEGIN
    //private void setChildPlanInfo(map<string, string> childPlanConfigMap) {
    private void setChildPlanInfo(map<string, string> childPlanConfigMap , map<string, string> ChildPlanPriceConfigMap) {
        //if (childPlanConfigMap == null || childPlanConfigMap.isEmpty()) return;
        if (childPlanConfigMap.isEmpty() && ChildPlanPriceConfigMap.isEmpty()) return;
        // 2017/02/21 お子様プランの料金PRICE機能追加 by zh END
        // プラン関連情報を取得する
        mLogUtils.write_method_start('setChildPlanInfo');
        // 指定の条件で店舗別でプラン定義情報を取得する
        list<string> planNos = childPlanConfigMap.values();
        // 2017/02/21 お子様プランの料金PRICE機能追加 by zh BEGIN
        planNos.addAll(ChildPlanPriceConfigMap.values()); 
		// 2017/02/21 お子様プランの料金PRICE機能追加 by zh END
		// 2020/07/30 入湯税の自動入力機能について改善 ZH BEGIN
        //String queryHeader = ' select Id, name,PlanNo__c,ServiceRate__c,JmstRef__r.TaxRate__c,Price__c,ShopInfoRef__r.ShopCode__c,(Select Id,Price__c,ServiceRate__c,TaxRate__c,AccountMasterRef__c,AccountMasterRef__r.ActionType__c From PlanRef__r)  from Plan__c ';
        String queryHeader = ' select Id, name,PlanNo__c,ServiceRate__c,JmstRef__r.TaxRate__c,Price__c,ShopInfoRef__r.ShopCode__c,(Select Id,Price__c,ServiceRate__c,TaxRate__c,AccountMasterRef__c,AccountMasterRef__r.ActionType__c From PlanRef__r),BathTaxAccMstRef__c  from Plan__c ';
        // 2020/07/30 入湯税の自動入力機能について改善 ZH END
        // 非公開プランは検索対象外に対応
        String whereStr = ' Where PlanNo__c in :planNos And IsClosed__c != true ';
        List<Plan__c> childrenPlan = DataBase.query(queryHeader + whereStr);
        // PlanNo->会計商品
        map<string,AccountMaster__c> locPlanNoToAccMstMap = new map<string, AccountMaster__c>();
        // 会計商品コードー＞PlanNo
        map<string,string> locProductCdToPlanNoMap = new map<string,string>();
        // PlanNo->プラン明細
        map<string, planDetailInfo> locChildPlanDetailMap = new map<string, planDetailInfo>();
        // 子供料金プラン
        for (Plan__c plan : childrenPlan) {
            // プランNoー＞プラン
            planDetailInfo detailInfo = new planDetailInfo();
        	// 2019/09/15 軽減税率機能対応 WGCH BEGIN
        	// detailInfo.init(plan.PlanRef__r);
        	detailInfo.init(plan.PlanRef__r, plan);
        	// 2019/09/15 軽減税率機能対応 WGCH END
            locChildPlanDetailMap.put(plan.PlanNo__c, detailInfo);
            String productCode = PLAN_PRD_PREX_NUM + plan.PlanNo__c;
            locProductCdToPlanNoMap.put(productCode, plan.PlanNo__c);
            childPlanPlanMstMap.put(productCode, plan);
        }
        if (!locProductCdToPlanNoMap.isEmpty()) {
            // 関連の会計商品情報を取得する
            List<AccountMaster__c> accounts = [select id,Name,jmstRef__r.TaxRate__c,ServiceRate__c,Field3__c from AccountMaster__c where Field3__c = :locProductCdToPlanNoMap.keySet()]; 
            for (AccountMaster__c acc : accounts) {
                // 商品コード
                String productCd = acc.Field3__c;
                String planNo = locProductCdToPlanNoMap.get(productCd);
                // PlanNOー＞会計商品
                locPlanNoToAccMstMap.put(planNo, acc);
            }
        }
        // 
        for (string key : childPlanConfigMap.keySet()) {
            string planNo = childPlanConfigMap.get(key);
            // 該当プラン対応の会計商品が存在する場合、設定を行う
            if (locPlanNoToAccMstMap.containsKey(planNo)) {
                AccountMaster__c acc = locPlanNoToAccMstMap.get(planNo);
                childPlanAccMstMap.put(key, acc);
                //
                if (locChildPlanDetailMap.containsKey(planNo)) {
                    childPlanDetailMap.put(acc.Field3__c, locChildPlanDetailMap.get(planNo));
                }
            }
        }
        // 2017/02/21 お子様プランの料金PRICE機能追加 by zh BEGIN
        for (string key : ChildPlanPriceConfigMap.keySet()) {
        	string planPriNo = ChildPlanPriceConfigMap.get(key);
        	// 該当プラン対応の会計商品が存在する場合、設定を行う
        	if (locPlanNoToAccMstMap.containsKey(planPriNo)) {
        		AccountMaster__c acc = locPlanNoToAccMstMap.get(planPriNo);
        		childPlanPriceAccMstMap.put(key, acc);
        		if (locChildPlanDetailMap.containsKey(planPriNo)) {
        			childPlanDetailMap.put(acc.Field3__c, locChildPlanDetailMap.get(planPriNo));
        		}
        	}
        }
 	// 2017/02/21 お子様プランの料金PRICE機能追加 by zh END
mLogUtils.write_log('子供プラン会計商品:' + childPlanAccMstMap);
mLogUtils.write_log('子供プラン詳細:' + childPlanDetailMap);
        mLogUtils.write_method_end();

    }

    // お子様プラン自動設定
    private void matchChildrenPlan(BookingEstimateItem__c item, Decimal perPaxRate) {
        Decimal childrenPrice = item.UnitPrice__c;
        // 2017/02/21 お子様プランの料金PRICE機能追加 by zh BEGIN
		String strChildPrice = CommUtils.deleteRightZero(CommUtils.nullToBlank(childrenPrice));
		// 2017/02/21 お子様プランの料金PRICE機能追加 by zh END
        // 2019/03/15 (無料)小人0円が小人プランに紐付できるように改善対応 ZH BEGIN
        //if (childrenPrice <= 0 || perPaxRate <= 0) return;
        if (perPaxRate <= 0) return;
        // 2019/03/15 (無料)小人0円が小人プランに紐付できるように改善対応 ZH END
        // パーセント計算する:子供一人料金/大人一人料金
        Decimal calRate = childrenPrice / perPaxRate * 100;
        String strCalRate = CommUtils.deleteRightZero(CommUtils.nullToBlank(calRate));
mLogUtils.write_log('子供一人料金のパーセント:' + strCalRate);
mLogUtils.write_log('childPlanNameConvertMap:' + childPlanNameConvertMap);
		// 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ BEGIN
		String key1 = TA_ServiceConfigHelp.getChildRateMatchKey(strCalRate);
		String key2 = TA_ServiceConfigHelp.getChildPriceMatchKey(strChildPrice);
		if (childPlanNameConvertMap.containsKey(key1)) {
			item.ProductName__c = childPlanNameConvertMap.get(key1);
			return;
		} else if (childPlanNameConvertMap.containsKey(key2)) {
			item.ProductName__c = childPlanNameConvertMap.get(key2);
			return;
		}
		// 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ END
        if (childPlanAccMstMap.containsKey(strCalRate)) {
            AccountMaster__c accMst = childPlanAccMstMap.get(strCalRate);
            // 該当見積明細にプラン商品を再設定する
            item.refAccountMaster__c = accMst.id;
            item.refAccountMaster__r = accMst;
            item.Field3__c = accMst.Field3__c;
            item.ProductName__c = accMst.Name;
        // 2017/02/21 お子様プランの料金PRICE機能追加 by zh BEGIN
		}else if (childPlanPriceAccMstMap.containsKey(strChildPrice)){
			AccountMaster__c accMst = childPlanPriceAccMstMap.get(strChildPrice);
			// 該当見積明細にプラン商品を再設定する
			item.refAccountMaster__c = accMst.id;
            item.refAccountMaster__r = accMst;
            item.Field3__c = accMst.Field3__c;
            item.ProductName__c = accMst.Name;
		}
		// 2017/02/21 お子様プランの料金PRICE機能追加 by zh END
    }  
    // 2016/06/10 子供料金プラン取り込み機能対応 END
    /**
    * 予約情報を登録する
    */
    private void upsertTALead(BI_TA_SyncInfo bookingInfo, LeadIndex__c leadIndex, Contact pkuser, List<Account> TraveCompany,String shopCode,List<Lead__c> oldLeadLst) {
        mLogUtils.write_method_start('upsertTALead');
        // 部屋自動割り振り機能
        boolean autoAssingRoomflag = TA_ServiceConfigHelp.getAppConfig(shopCd).roomAutoAssignFlag;
mLogUtils.write_log('部屋自動割り振り::::' + autoAssingRoomflag);
        // 税区分設定
        Integer taxSericeFee = CommUtils.nullToIntZero(bookingInfo.basicRate.TaxServiceFee);
        // 2019/09/15 軽減税率機能対応 WGCH BEGIN
        taxSericeFeeEnd = taxSericeFee;
        // 2019/09/15 軽減税率機能対応 WGCH END
        // 2016/06/17 取り込みの税サ区分はSFDC側の単価定義区分を参照する対応 BEGIN
        boolean isSFTaxServiceKbn = TA_ServiceConfigHelp.getAppConfig(shopCd).isSFTaxServiceKbn;
        if (isSFTaxServiceKbn) {
        	taxSericeFee = CommConst.APPOPTION_UTP_DEF_KB;
        	mLogUtils.write_log('税区分はSFDC側の単価定義区分に参照する['+taxSericeFee+']');
        }
		// 2016/06/17 取り込みの税サ区分はSFDC側の単価定義区分を参照する対応 BEGIN
        // 消費税情報を取得する   
        taxRateMst = CommLogicProcess.getTaxRateInfo();
        // プラン情報を取得、作成する
        // プラン情報がNULLの場合、見積明細に直接室料を設定する
        Plan__c curPlan = upsertPlan(bookingInfo, TraveCompany);
        // プラン明細情報を取得する
        setPlanDetailPlusInfo(curPlan);
        mLogUtils.write_log('プラン情報::' + curPlan);
//System.debug(LoggingLevel.INFO, '-----------------emailMsg--------------------');
        String emailMsg = mailArea(bookingInfo);
        // 部屋タイプID情報を取得する
        Set<String> roomTypeCdSet = new Set<String>();   
        // 部屋タイプ名情報を格納する
        Set<String> roomTypeNmSet = new Set<String>();        
        // 部屋タイプコードは再取得を行う
        for (BI_TA_RoomAndGuestInfo roomAndGuest: bookingInfo.roomAndGuestLst) {
            roomTypeCdSet.add(roomAndGuest.roomI.RoomTypeCode);
            // 部屋タイプ名：部屋ID情報を格納する
            if (!CommUtils.isBlank(roomAndGuest.roomI.RoomTypeName)) roomTypeNmSet.add(roomAndGuest.roomI.RoomTypeName);
        }
        // 部屋タイプMAP情報設定する
        Map<String,Id> roomTypeMap = new Map<String, Id>();
        // 部屋タイプ名情報を格納する
        Map<String,Id> roomTypeNmMap = new Map<String, Id>();
        //  部屋タイプが存在　かつ　対応部屋タイプに対して、１部屋のみの場合、該当部屋は自動的に予約にアサインする BEGIN
        Map<Id, id> oneTypeToRoomMap = new Map<Id, Id>();
        // 店舗区分 :新追加 ShopInfoRef__c　
        // 2016/10/19 部屋タイプと部屋が1対1の場合は故障部屋を割当される不具合改修 BEGIN
        map<Integer, Room__c> oneRoomCanAssignRoomMap = new map<Integer, Room__c>();
        for (TypeOfRooms__c roomType: [select id, RoomTypeName__c, RoomTypeCode__c,(Select Id From TypeRoomRef__r limit 2) from TypeOfRooms__c where ShopInfoRef__r.ShopCode__c = :shopCode and  (RoomTypeCode__c in :roomTypeCdSet Or RoomTypeName__c in :roomTypeNmSet)]) {
            roomTypeMap.put(roomType.RoomTypeCode__c, roomType.Id);
            // 部屋タイプ名：部屋ID情報を格納する
            if (!CommUtils.isBlank(roomType.RoomTypeName__c)) roomTypeNmMap.put(roomType.RoomTypeName__c, roomType.Id);
	        // 自動割り当てフラグはTRUEのみ、該当関連取得を行う
	        if (oneRoomAutoAssingRoomFlg) {
	            if (roomType.TypeRoomRef__r != null && roomType.TypeRoomRef__r.size() == 1) {
	                oneTypeToRoomMap.put( roomType.Id, roomType.TypeRoomRef__r[0].Id );
	            }
	        }
        }
        // 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 BEGIN
        /*
        // 部屋タイプが存在する場合
        if (!oneTypeToRoomMap.isEmpty()) {
        	// 割当できる部屋情報を取得する　
        	oneRoomCanAssignRoomMap = getCanAssignRoom(leadIndex,roomTypeMap,oneRoomAutoAssingRoomFlg,bookingInfo);
        }
        */
        // 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 END
		// 2016/10/19 部屋タイプと部屋が1対1の場合は故障部屋を割当される不具合改修 END
        // 部屋タイプにより、自動割り振りできる部屋情報を戻る
        // 故障部屋は自動割当て機能に追加対応 BEGIN
        //map<Id, List<Room__c>> canAssignRoomMap = new map<Id, List<Room__c>>();
        map<Integer, Room__c> canAssignRoomMap = new map<Integer, Room__c>();
        if (autoAssingRoomflag) {
            canAssignRoomMap = getCanAssignRoom(leadIndex,roomTypeMap,autoAssingRoomflag,bookingInfo);
            mLogUtils.write_log('複数部屋自動割り当て対象 :: ' + canAssignRoomMap);
        }
        // 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 BEGIN
        // 部屋タイプが存在する場合
        else if (!oneTypeToRoomMap.isEmpty()) {
        	// 割当できる部屋情報を取得する　
        	oneRoomCanAssignRoomMap = getCanAssignRoom(leadIndex,roomTypeMap,oneRoomAutoAssingRoomFlg,bookingInfo);
        	mLogUtils.write_log('1VS1部屋自動割り当て対象 :: ' + oneRoomCanAssignRoomMap);
        }
        // 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 END
        // 故障部屋は自動割当て機能に追加対応 END
        // 宿泊レコードタイプ
        String bookingRcTypeId = CommLogicProcess.getLeadBookingRecType();
        // チェックイン日付・日時[基本宿泊情報から]
        DateTime checkInFirstDayDt = DateTime.newInstance(leadIndex.EntryDate__c,
        bookingInfo.basic.CheckInTime == null ? defaultCheckinTime : bookingInfo.basic.CheckInTime);
        // 最後日のチェックアウト日付・日時[基本宿泊情報から][出発日設定を行う]
        DateTime checkOutLastDayDt = DateTime.newInstance(leadIndex.DepartureDate__c, defaultCheckoutTime);
        // パタン６確認する（連泊、１室、１部屋タイプ）
        // 同じ日付のデータ数：部屋数　　部屋利用日の範囲は泊数設定
        // 定義した総泊数からLOOPして、その後、部屋数LOOPする
        Integer nights = bookingInfo.basic.Nights;            // 総宿泊数
        if (nights == 0) nights = 1;
        // 予約名自動設定対応、団体名または代表者氏名 漢字ー＞団体名または代表者氏名(半角)
        // 2018/07/09 [GuestOrGroupNameSingleByte、GuestOrGroupNameKanjiName]非存在の場合、取り込みできるように改善 BEGIN
        //String leadName = leadIndex.LeadName__c;
        String leadName = CommUtils.nullToBlank(leadIndex.LeadName__c);
        // 2018/07/09 [GuestOrGroupNameSingleByte、GuestOrGroupNameKanjiName]非存在の場合、取り込みできるように改善 END
        // Loop Index
        Integer roomNoIdx = 0;
        // 複数件予約データを作成する 
        List<Lead__c> insLeadLst = new List<Lead__c>();
        // 記号機能対応 BEGIN
        // N rooms N nightsのとき、特記事項をその日は、一つにする対応と同様に、親部屋マーク（一文字記号）をカスタム設定のパラメータとして、定義、この定義されたマークを予約名の文字列先頭に付加する、
        // また、人数とプランも一つの予約データのみに取り込み、他の予約データは、人数ゼロ、プランなし、と設定する
        String strRoomDelegatePrefix = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomDelegatePrefix__c);
        // N部屋N泊数標識フラグ
        // 記号機能対応 End
        // 複数予約日ー＞複数部屋タイプから　１部屋タイプ１日予約データを作成する
        Map<String,List<BookingEstimateItem__c>> roomToItemsMap = new Map<String,List<BookingEstimateItem__c>>();
        Map<String,Integer> roomToItemMap = new Map<String,Integer>();
        // 見積明細に明細登録用会計商品
        nyuuTouAcc = getNyuuTouAcc();           // [入湯税商品定義情報を取得する]
        serviceAcc = getServiceAcc();           // [サビース料商品定義情報を取得する]
        AccountMaster__c commshitulyouAcc = null;   // プラン関連の会計商品情報格納   

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
                // 2020/07/30 入湯税の自動入力機能について改善 ZH BEGIN
                // 该Plan存在参照入汤税商品, 该Plan的会计商品设定参照对应的Plan处理
                if(curPlan.BathTaxAccMstRef__c != null) commshitulyouAcc.PlanBathTaxAccMstRef__c = curPlan.Id;
                // 2020/07/30 入湯税の自動入力機能について改善 ZH END
                insert commshitulyouAcc;
            }
            // 2016/06/10 子供料金プラン取り込み機能対応 BGEIN
            // 2017/02/21 お子様プランの料金PRICE機能追加 by zh BEGIN
            //setChildPlanInfo(TA_ServiceConfigHelp.getChildPlanConvertConfig(shopCd));
            setChildPlanInfo(TA_ServiceConfigHelp.getChildPlanConvertConfig(shopCd),TA_ServiceConfigHelp.getChildPlanPriceConvertConfig(shopCd));
            // 2017/02/21 お子様プランの料金PRICE機能追加 by zh END
            // 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ BEGIN
        	// プラン設定情報を取得する
        	childPlanNameConvertMap = TA_ServiceConfigHelp.getChildPlanNameConvertConfig(shopCd);
        	// 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ END
            // 2016/06/10 子供料金プラン取り込み機能対応 END
        }
        // プラン関連の会計商品が非存在する場合、室料商品を取得する
        if (commshitulyouAcc == null) {
            commshitulyouAcc = getShiTuLyouAcc();   // [室料商品定義情報を取得する]
        }
        // 見積明細に登録する会計商品
        mLogUtils.write_log('会計商品：' +commshitulyouAcc);
        // 税区分
        mLogUtils.write_log('税区分：' + bookingInfo.basicRate.TaxServiceFee);
        // 処理区分
        Boolean isUpdateFlag = bookingInfo.dmlAction == BI_TA_DmlAction.UPD;
        // 予約情報にプラン存在するがどうかチエックを行う、プランが存在すると、１部屋の総利用金額は該当プランに設定を行う
        // プラン情報はXMLに未定義すると、室料の会計商品で、総金額は室料の金額に設定を行う
        BookingEstimateItem__c cloneItem = null;
        if (commshitulyouAcc.Id != null) {
            cloneItem = new BookingEstimateItem__c(
                        refAccountMaster__c = commshitulyouAcc.id,
                        refAccountMaster__r = commshitulyouAcc,
                        TaxRate__c = taxRateMst.TaxRate__c);
            if(curPlan != null) {
                //item.PlanDetailSyncInfo__c = curPlan.id;
                cloneItem.Field3__c = PLAN_PRD_PREX_NUM + curPlan.PlanNo__c;
                // 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応 by zh BEGIN
                boolean plannameToEstflag = TA_ServiceConfigHelp.isSfPlanNmToEstProdNm(shopCd);
mLogUtils.write_log('見積明細名はプラン目に変更::::' + plannameToEstflag);
                if(plannameToEstflag){
                	cloneItem.ProductName__c = curPlan.Name;
                } else {
                	cloneItem.ProductName__c = CommUtils.isBlank(bookingInfo.basic.PackagePlanName)
                                            ? curPlan.Name
                                            : bookingInfo.basic.PackagePlanName;
                }
                // 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応 by zh END
                cloneItem.ActionType__c = CommConst.PROD_ACTION_TYPE_PL;
            }
        }
        if(bookingInfo.basic.TravelAgencyBookingTime == null) bookingInfo.basic.TravelAgencyBookingTime = Time.newInstance(0,0,0,0);
        Map<Integer,List<BookingEstimateItem__c>> roomMaps = new Map<Integer,List<BookingEstimateItem__c>>();
        Map<String,Object> autoSetupfieldMap = TA_ServiceConfigHelp.getAppConfig(shopCd).fieldMap;
        Map<String, Schema.DescribeFieldResult> finalFieldMap = CommUtils.getFieldMetaData(Lead__c.getSObjectType().getDescribe(),autoSetupfieldMap.keySet());
        // 料金区分:部屋単価・人員単価
        boolean isRoomRateFlg = bookingInfo.basicRate.RoomRateOrPersonalRate == 'PersonalRate' ? false : true;
		mLogUtils.write_log('予約情報新規、変更処理開始');
        // 既存予約情報を格納する
        // map<部屋単位,該当部屋関連の予約情報>
        Map<Integer,List<Lead__c>> groupLeadMap = new Map<Integer,List<Lead__c>>();
        Lead__c beforeLead = null;
        integer roomIndex = 0;
        // 2018/12/30 部屋/部屋タイプ不正の場合、部屋と部屋タイプを再設定の改善対応 WSQ BEGIN
        map<id, id> orgLeadRoomAndTypeMap = new map<id, id>();
        // 2018/12/30 部屋/部屋タイプ不正の場合、部屋と部屋タイプを再設定の改善対応 WSQ END
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
            // 2018/12/30 部屋/部屋タイプ不正の場合、部屋と部屋タイプを再設定の改善対応 WSQ BEGIN
            if (lead.Rroom__c != null) orgLeadRoomAndTypeMap.put(lead.Rroom__c, lead.refTypeOfRooms__c);
            // 2018/12/30 部屋/部屋タイプ不正の場合、部屋と部屋タイプを再設定の改善対応 WSQ END
        }
        // 2018/12/30 部屋/部屋タイプ不正の場合、部屋と部屋タイプを再設定の改善対応 WSQ BEGIN
        map<id,id> errRoomToTypeIdMap = new map<Id, id>();
        if (!orgLeadRoomAndTypeMap.isEmpty()) {
        	// 既存予約の部屋IDにより、部屋と部屋タイプのマッピング定義を取得する
        	list<Room__c> wkrooms = [select id, TypeRoomRef__c from Room__c where id in:orgLeadRoomAndTypeMap.keyset()];
        	for (Room__c r : wkrooms) {
        		// 既存予約の部屋と部屋タイプが不一致の場合、
        		if (orgLeadRoomAndTypeMap.containsKey(r.Id) && orgLeadRoomAndTypeMap.get(r.id) != r.TypeRoomRef__c) {
        			errRoomToTypeIdMap.put(r.Id, r.TypeRoomRef__c);
        		}
        	}
        }
        // 2018/12/30 部屋/部屋タイプ不正の場合、部屋と部屋タイプを再設定の改善対応 WSQ END
        Map<String,Id> lastRoomMap = new Map<String,Id>();
        Set<String> userOrgLeadSet = new Set<String>();
        Set<Id> updateOrgLeadIdSet = new Set<Id>();
        // 2016/07/10 予約チャネル名の変換機能追加対応 BEGIN
        String chanelStr = getChanelStr(bookingInfo,TraveCompany);
        // 2016/07/10 予約チャネル名の変換機能追加対応 END
        // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ BEGIN
        // 既存予約の見積明細を上書きするがどう切り替え用フラグ
        Boolean isClearEstItemsFlag = TA_ServiceConfigHelp.getAppConfig(shopCd).modifyEstItemsFlag;
        // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ END
        //List<BI_TA_LeadToRoomInfo> leadToRoomLst = new List<BI_TA_LeadToRoomInfo>();
        // 総部屋数
        Integer rooms = bookingInfo.roomAndGuestLst.size();
//mLogUtils.write_log('予約部屋数：' + rooms);
		// 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応 by zh BEGIN
        // 支払明細はどの部屋どの泊にリンクすることINDEXを記録する
        Integer payMediaLinkPos = 0;
        if (TA_ServiceConfigHelp.getAppConfig(shopCd).payMeaidToLastDayFlag) payMediaLinkPos = (nights-1);
        // 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応 by zh END
        // 複数予約日ー＞複数部屋タイプから　１部屋タイプ１日予約データを作成する
        for(Integer j = 0; j < rooms; j ++){
            // 部屋とお客様リスト
            BI_TA_RoomAndGuestInfo roomAndGuest = bookingInfo.roomAndGuestLst[j];
            // １部屋タイプから複数日予約データを作成する
            // 複数日から１日単位に作成する
            // 2017/02/21 RoomRate部分为空、取込エラー FIX by zh BEGIN
            //Integer staysNums = roomAndGuest.roomRateLst.size();
            Integer staysNums = nights;
            if (!roomAndGuest.roomRateLst.isEmpty()) staysNums = roomAndGuest.roomRateLst.size();
            // 2017/02/21 RoomRate部分为空、取込エラー FIX by zh END
            
//mLogUtils.write_log('部屋単位の予約泊数：' + staysNums);
			// 異常データ個別処理
			if (roomAndGuest.roomRateLst.isEmpty() && nights == 1) {
				staysNums = 1;
				BI_TA_RoomRateInformation rateInfo = new BI_TA_RoomRateInformation();
				rateInfo.RoomDate = bookingInfo.basic.CheckInDate;
				roomAndGuest.roomRateLst.add(rateInfo);
			}
            // 日付単位情報
            for(Integer i = 0; i < staysNums; i ++){
                // データ取得INDEX
                Integer idx = j * staysNums + i;
                //　到着日
                // 2017/02/21 RoomRate部分为空、取込エラー FIX by zh BEGIN
                Date checkInDate;
                if (roomAndGuest.roomRateLst.size() > i) {
                	checkInDate = roomAndGuest.roomRateLst[i].RoomDate;
                	if (checkInDate == null) checkInDate = bookingInfo.basic.CheckInDate.adddays(i);
                } else {
                	checkInDate = bookingInfo.basic.CheckInDate.adddays(i);
                }
                // 2017/02/21 RoomRate部分为空、取込エラー FIX by zh END
                // 新規予約データ作成
                Lead__c newLead = new Lead__c();
                // 2016/10/21 TA変更機能改善対応、項目値自動設定不具合改修 BEGIN
                for(String fieldName : finalFieldMap.keySet()){
                    Schema.DescribeFieldResult describeField = finalFieldMap.get(fieldName);
                    if(describeField.isCreateable()){
                    	// デイフォル値を自動設定を行う
                        newLead.put(fieldName,CommUtils.ConvByFielType(autoSetupfieldMap.get(fieldName), describeField.getType()));
                    	//mLogUtils.write_log('更新内容[' + fieldName + ']:1:' + fieldMap.get(fieldName) );
                        mLogUtils.write_log('項目値自動設定[' + fieldName + ']:1:' + newLead.get(fieldName) );
                    }
                }
                // 2016/10/21 TA変更機能改善対応、項目値自動設定不具合改修 END
                // 変更前の予約泊数
                Integer orgLeadNights = null;
                Lead__c orgLead = null;
//mLogUtils.write_log('isUpdateFlag：' + isUpdateFlag);
                if(isUpdateFlag){
                	// 既存の予約情報
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
//mLogUtils.write_log('----------------部屋j：' + j);
//mLogUtils.write_log('----------------泊数i：' + i);
//mLogUtils.write_log('----------------idx：' + idx);
                // 既存の予約情報が存在する場合
                boolean isHadLeadId = (orgLead != null);
                // お客様情報
                newLead.Relcontact__c = newLead.Relcontact__c == null ? pkuser.id : newLead.Relcontact__c;
                // 2013/07/16 記号機能対応 BEGIN
                // 親部屋マーク標識用の文字は予約名の文字列先頭に付加
                // プラン情報         
                newLead.Field310__c = curPlan == null ? null : curPlan.Id;
//mLogUtils.write_log('予約情報が存在する場合:: '+isHadLeadId);
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
                    // 2018/07/09 [GuestOrGroupNameSingleByte、GuestOrGroupNameKanjiName]非存在の場合、取り込みできるように改善 BEGIN
                    //newLead.name = newLead.name.replace(orgLeadName, newLeadName);
                    if (!CommUtils.isBlank(newLeadName)) newLead.name = newLead.name.replace(orgLeadName, newLeadName);
                    // 2018/07/09 [GuestOrGroupNameSingleByte、GuestOrGroupNameKanjiName]非存在の場合、取り込みできるように改善 END
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
                newLead.ReservedDate__c = DateTime.newInstance(bookingInfo.basic.TravelAgencyBookingDate, bookingInfo.basic.TravelAgencyBookingTime);
                // 支払方法 ----------------BEGIN----------------------
                // 2014/04/25 支払方法設定共通化
                newLead.Field315__c = getLocalPaymentInfo(bookingInfo.basicRate.Payment);
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
                    newLead.Field4__c = (bookingInfo.basic.CheckInTime == null 
                        // DayUserの場合の時刻情報
                        ?  (bookingInfo.basic.Nights == 0 ? defaultDayUseCheckInTime : defaultCheckInTimeStr)
                        :  (DateTime.newInstance(Date.today(), bookingInfo.basic.CheckInTime)).format('HH:mm') );
                    // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
                    newLead.EntryTime__c = DateTime.newInstance(checkInFirstDayDt.date(), CommUtils.stringtotime(newLead.Field4__c));
                    // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
                } else {
                    // チェックイン日
                    newLead.EntryTime__c = DateTime.newInstance(checkInDate, defaultCheckinTime);
                    // チェックイン時間
                    newLead.Field4__c = defaultCheckInTimeStr;
                }
                //2016/03/02 ---------BEGIN----------------
                //予約取込のXMLのタグ：入込方法（Transportaion）存在すると、該当項目内容はご予約の「交通手段」項目へ設定する
                //if(CommUtils.isBlank(newLead.Field348__c)) newLead.Field348__c = CommUtils.nullToBlank(bookingInfo.Transportaion);
                //予約取込のXMLのタグ：部屋割り後客室名/番号（AssignedRoomNumber）存在すると、該当項目内容により
                
                //2016/03/02 ----------END-----------------

                // 最後日の場合
                if (i == nights - 1) {
                    // チェックアウト日
                  //  newLead.Departure__c = checkOutLastDayDt;
                    
                    // チェックアウト時間
                    // DayUserの場合の時刻情報
                    newLead.Field3__c = (bookingInfo.basic.Nights == 0 
                                // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
                                //? (DateTime.newInstance(Date.today(), CommUtils.stringToTime(newLead.Field4__c).addHours(CommConst.DEF_DAYUSE_STAY_HOURS))).format('HH:mm')
                                ? ((bookingInfo.basic.CheckInTime == null)
                                    ? defaultDayUseCheckOtTime
                                    : (DateTime.newInstance(Date.today(), CommUtils.stringToTime(newLead.Field4__c).addHours(CommConst.DEF_DAYUSE_STAY_HOURS))).format('HH:mm')
                                )
                                // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
                                : defaultCheckoutTimeStr);
                        
                      // チェックアウト日
                      newLead.Departure__c = DateTime.newInstance(checkOutLastDayDt.date(), CommUtils.stringToTime(newLead.Field3__c));
                } else {
                    // チェックアウト日
                    newLead.Departure__c = DateTime.newInstance(checkInDate.addDays(1), defaultCheckoutTime);
                    // チェックアウト時間
                    newLead.Field3__c = defaultCheckoutTimeStr;
                }
                // 2013/06/09 宿泊人数は未設定する場合、自動Default値を設定する
                Integer calRoomPaxCount =  CommUtils.nullToZero(roomAndGuest.roomI.RoomPaxMaleCount) + 
                                           CommUtils.nullToZero(roomAndGuest.roomI.RoomPaxFemaleCount) + 
                                           CommUtils.nullToZero(roomAndGuest.roomI.RoomChildA70Count) +
                                           CommUtils.nullToZero(roomAndGuest.roomI.RoomChildB50Count) +
                                           CommUtils.nullToZero(roomAndGuest.roomI.RoomChildC30Count) +
                                           CommUtils.nullToZero(roomAndGuest.roomI.RoomChildDNoneCount) +
                                           CommUtils.nullToZero(roomAndGuest.roomI.RoomChildOtherCount);
                String warningMsg = '';
                
                if (roomAndGuest.roomI.PerRoomPaxCount == null || roomAndGuest.roomI.PerRoomPaxCount == 0) {
                    // XMLの中に、未設定する場合、自動的にSFの初期値で自動設定を行う「非設定する場合、自動設定を行う」
                    if (calRoomPaxCount > 0) {
                        // 1室利用人数
                        newLead.StayPersons__c = calRoomPaxCount;
                    } else {
                        // 該当ケースする場合、注意事項に自動内容追加を行う
                        //warningMsg = '<font color="red">サイトコントローラからの予約データのなかに、予約人数がありませんでしたので、デフォルト値(仮の値)を設定させていただきました、つきましては、ご予約者の方へご確認していただきまして、本予約データの予約人数を手動にて変更ください。</font><br/>';
                    	// 2016/10/26 BEGIN
                        //予約人数がゼロで取り込まれましたので人数を変更してください。
                    	warningMsg = '<font color="red">'+ Label.MSG_038_0008 +'</font><br/>';
                    	newLead.StayPersons__c = 0;
                    	// 2016/10/26 END
                    }
                } else {
                    // 1室利用人数
                    newLead.StayPersons__c = roomAndGuest.roomI.PerRoomPaxCount;
                }
                // 大人人員(男性)
                newLead.Mans__c = roomAndGuest.roomI.RoomPaxMaleCount;
                // 大人人員(女性) 
                newLead.Femails__c = roomAndGuest.roomI.RoomPaxFemaleCount;
                // 子供A人数
                newLead.ChildFA__c = roomAndGuest.roomI.RoomChildA70Count;
                // 子供B人数
                newLead.Childs__c = roomAndGuest.roomI.RoomChildB50Count;
                // 子供C人数
                newLead.ChildC__c = roomAndGuest.roomI.RoomChildC30Count;
                // 子供D人数追加
                newLead.ChildD__c = roomAndGuest.roomI.RoomChildDNoneCount;
                // 子供E人数追加
                newLead.ChildE__c = roomAndGuest.roomI.RoomChildOtherCount;
                //　予約インデックスID
                newLead.LeadIndexRef__c = leadIndex.Id;
                // 事前決済区分
                //newLead.SettlementDiv__c = CommUtils.nullToBlank(bookingInfo.risaplsinformation.agentNativeInformation.extendmytrip.SettlementDiv);
                // 予約番号
                newLead.BookingDataID__c = bookingDataId;
                // プラン自動展開対象外フラグ設定
                newLead.PlanSycnFlag__c = newLead.PlanSycnFlag__c == null ? true : !newLead.PlanSycnFlag__c;
                // 2015/12/11 予約取込機能改善（変更、キャンセル） END
                // 特記事項設定[一泊で2部屋以上の自動とりこみ予約のときは、特記事項を一つのみとする]
                //if (j == 0) {
//mLogUtils.write_log('++++++++++++++++----------------isHadLeadId：' + isHadLeadId);
                if(isHadLeadId){
                    String commentMessage = newLead.Comment3__c + '<br/>' + warningMsg + bookingInfo.basic.OtherServiceInformation;
                    newLead.Comment3__c = CommLogUtils.removeOverLogString(commentMessage,commentLength);
                    // メール本文
                    //newLead.email__c = CommLogUtils.removeOverLogString(risaplBasic.TelegramData + '\n' + CommUtils.nullToBlank(newLead.email__c),emailLength);
                    //newLead.email__c = emailMsg;
                    newLead.email__c = CommLogUtils.removeOverLogString(emailMsg + '\n\n\n' + CommUtils.nullToBlank(newLead.email__c),emailLength);
                    // 2016/10/18 既存の予約情報の部屋は割当済すると、該当部屋タイプと情報は変更なしで対応する BEGIN
                    //newLead.Rroom__c = null;
                    // 2016/10/18 既存の予約情報の部屋は割当済すると、該当部屋タイプと情報は変更なしで対応する END
                    // 2013/06/25 ADD 旅行会社名から予約チャネルに設定する
                    // 2016/01/28 ネットからの取込時に予約チャネルに旅行会社名で設定する BEGIN
                    //if(CommUtils.isBlank(newLead.Field2__c)) newLead.Field2__c = TraveCompany.size() > 1 ? TraveCompany[1].Name : TraveCompany[0].Name;
                    // 2016/07/10 予約チャネル名の変換機能追加対応 BEGIN
                    //if(CommUtils.isBlank(newLead.Field2__c)) newLead.Field2__c = TraveCompany.size() > 0 ? TraveCompany[0].Name : null;
                    if(CommUtils.isBlank(newLead.Field2__c)) newLead.Field2__c = chanelStr;
        			// 2016/07/10 予約チャネル名の変換機能追加対応 END
                    // 2016/01/28 ネットからの取込時に予約チャネルに旅行会社名で設定する END
                }else{
                     // 2017/09/01 最大文字数をこえない問題回避対応 BEGIN
                     //newLead.Comment3__c = warningMsg + bookingInfo.basic.OtherServiceInformation;
                     newLead.Comment3__c = CommLogUtils.removeOverLogString(warningMsg + bookingInfo.basic.OtherServiceInformation,commentLength);
                     //newLead.email__c = risaplBasic.TelegramData;
                     //newLead.email__c = emailMsg;
                     newLead.email__c = CommLogUtils.removeOverLogString(emailMsg,emailLength);
                     // 2017/09/01 最大文字数をこえない問題回避対応 END
                     // 2013/06/25 ADD 旅行会社名から予約チャネルに設定する
                     // 2016/01/28 ネットからの取込時に予約チャネルに旅行会社名で設定する BEGIN
                     //newLead.Field2__c = TraveCompany.size() > 1 ? TraveCompany[1].Name : TraveCompany[0].Name;
                     // 2016/07/10 予約チャネル名の変換機能追加対応 BEGIN
                     //newLead.Field2__c = TraveCompany.size() > 0 ? TraveCompany[0].Name : null;
                     newLead.Field2__c = chanelStr;
                	 // 2016/07/10 予約チャネル名の変換機能追加対応 END
                     // 2016/01/28 ネットからの取込時に予約チャネルに旅行会社名で設定する END
                }
//mLogUtils.write_log('----------------isHadLeadId：false=================');
                // 部屋タイプID
                newLead.refTypeOfRooms__c = roomTypeMap.get(roomAndGuest.roomI.RoomTypeCode);
//mLogUtils.write_log('----------------部屋タイプ1=================');
                // 2013/02/26 部屋タイプ名：部屋ID情報を格納する
                if (newLead.refTypeOfRooms__c == null ) newLead.refTypeOfRooms__c = roomTypeNmMap.get(roomAndGuest.roomI.RoomTypeName);
//mLogUtils.write_log('----------------部屋タイプ2=================');
                // 2018/12/30 TA予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh BEGIN
                boolean chgRoomTypeFlag = TA_ServiceConfigHelp.getAppConfig(shopCd).chgRoomTypeFlag;
                // 2018/12/30 TA予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh END
                // 部屋タイプを自動されている場合                
                if (newLead.refTypeOfRooms__c != null){
                	// 既存データありの場合
                    if(isHadLeadId){
                        // 2016/10/18 既存の予約情報の部屋は割当済すると、該当部屋タイプと情報は変更なしで対応する BEGIN
						/*
                        // 到着日変更　OR　部屋タイプ変更なしの場合、既にアサイン済部屋はそのまま残り
                        if (orgLead.EntryTime__c.date() == newLead.EntryTime__c.date() &&
                            orgLead.refTypeOfRooms__c == newLead.refTypeOfRooms__c) {
                            newLead.Rroom__c = orgLead.Rroom__c;
						}*/
                        // 2016/10/18 既存の予約情報の部屋は割当済すると、該当部屋タイプと情報は変更なしで対応する END
                        // 2016/10/21 TA変更機能改善対応[到着日を変更すると、既に割当される部屋をクリアする] BEGIN
						if (orgLead.EntryTime__c.date() != newLead.EntryTime__c.date()) {
							// 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh BEGIN
							//newLead.Rroom__c = null;
							boolean chgdtRoomClearFlag = TA_ServiceConfigHelp.getAppConfig(shopCd).chgdtRoomClearFlag;
							// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ BEGIN
							//if(chgdtRoomClearFlag) newLead.Rroom__c = null;
							if(chgdtRoomClearFlag) {
								newLead.Rroom__c = null;
								newLead.Field276__c = false;
							}
							// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ END
							// 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh END
						}
						// 2016/10/21 TA変更機能改善対応[到着日を変更すると、既に割当される部屋をクリアする] END
						// 2018/12/30 TA予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh BEGIN
                        if(newLead.Rroom__c != null){
                        	// 部屋タイプを更新可能FLGはTRUE場合 AND 部屋変更不可フラグはFALSEの場合
                        	// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ BEGIN
                            //if(chgRoomTypeFlag && !orgLead.Field276__c){
                            if(chgRoomTypeFlag){
                            // 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ END
                            	// XMLの部屋タイプID
                            	Id newRoomTypeId = roomTypeMap.get(roomAndGuest.roomI.RoomTypeCode);
                            	// 部屋タイプ変更場合
                            	if ( newRoomTypeId != orgLead.refTypeOfRooms__c) {
                            		newLead.refTypeOfRooms__c = newRoomTypeId;
                            		newLead.Rroom__c = null;
                            		// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ BEGIN
                            		newLead.Field276__c = false;
                            		// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ END
                            	}
                            	// 部屋タイプ一致場合
                            	else {
                                	// 既存予約の部屋と部屋タイプ定義不一致の場合、ご予約の部屋タイプは部屋により訂正する
                                	if (errRoomToTypeIdMap.containsKey(newLead.Rroom__c)) {
                                		// 既に割当済の部屋の部屋タイプ（DB最新定義）とXMLの部屋タイプが不一致場合
                                		Id wkRoomTypeId = errRoomToTypeIdMap.get(newLead.Rroom__c);
                                		// 該当部屋の部屋タイプはXMLの部屋タイプが不一致場合、部屋はクリア処理を行う
                                		if (wkRoomTypeId != newRoomTypeId) {
                            				newLead.refTypeOfRooms__c = newRoomTypeId;
                            				newLead.Rroom__c = null;
                            				// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ BEGIN
                            				newLead.Field276__c = false;
                            				// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ END
                                		}
                                		//newLead.refTypeOfRooms__c = errRoomToTypeIdMap.get(newLead.Rroom__c);
                                	}
                                	// 2018/12/30 部屋/部屋タイプ不正の場合、部屋と部屋タイプを再設定の改善対応 WSQ END	
                            	}
                            }else{
                                newLead.refTypeOfRooms__c = orgLead.refTypeOfRooms__c;
                                // 既存予約の部屋と部屋タイプ定義不一致の場合、ご予約の部屋タイプは部屋により訂正する
                                if (errRoomToTypeIdMap.containsKey(newLead.Rroom__c)) newLead.refTypeOfRooms__c = errRoomToTypeIdMap.get(newLead.Rroom__c);
                                // 2018/12/30 部屋/部屋タイプ不正の場合、部屋と部屋タイプを再設定の改善対応 WSQ END
                    		}
		    			}
		    			// 2018/12/30 TA予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh END
                    }
                    /*if(newLead.Rroom__c == null){
                        if(!CommUtils.isBlank(roomAndGuest.room.AssignedRoomNumber) && nameToRoomMap.containsKey(roomAndGuest.room.AssignedRoomNumber)){
                            newLead.Rroom__c = nameToRoomMap.get(roomAndGuest.room.AssignedRoomNumber);
                        }
                    }*/
//mLogUtils.write_log('----------------部屋タイプ3=================');
                    if (newLead.Rroom__c == null) {
                        // 部屋自動割り振り機能
                        if (autoAssingRoomflag) {
                            // 2015/10/30 故障部屋は自動割当て機能に追加対応 BEGIN
                            
                           /* String key = j + '_' + newLead.refTypeOfRooms__c;
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
                            //if (canAssignRoomMap.containsKey(idx)) {
                            // 部屋割当可能の場合
                            if (canAssignRoomMap.containsKey(j)) {
                                newLead.Rroom__c = canAssignRoomMap.get(j).Id;
                                mLogUtils.write_log('複数部屋自動割り当て部屋 :: ' + newLead.Rroom__c);
//mLogUtils.write_log('----------------部屋自動割当================='+newLead.Rroom__c);
                            }
//mLogUtils.write_log('----------------部屋タイプ4=================');                            
                            // 2015/10/30 故障部屋は自動割当て機能に追加対応 END
                        }
                        // 1部屋自動アサイン機能
                        // 部屋タイプが存在　かつ　対応部屋タイプに対して、１部屋のみの場合、該当部屋は自動的に予約にアサインする BEGIN
                        // 2016/10/19 部屋タイプと部屋が1対1の場合は故障部屋を割当される不具合改修 BEGIN
                        //else if (oneTypeToRoomMap.containsKey(newLead.refTypeOfRooms__c)) {
                        else if (oneTypeToRoomMap.containsKey(newLead.refTypeOfRooms__c) && oneRoomCanAssignRoomMap.containsKey(j)) {
                        // 2016/10/19 部屋タイプと部屋が1対1の場合は故障部屋を割当される不具合改修 END
                            newLead.Rroom__c = oneTypeToRoomMap.get(newLead.refTypeOfRooms__c);
                            mLogUtils.write_log('1VS1部屋自動割り当て部屋 :: ' + newLead.Rroom__c);
//mLogUtils.write_log('----------------部屋自動割当【ONE　VS　ONE】================='+newLead.Rroom__c);
                        }
//mLogUtils.write_log('----------------部屋タイプ5=================');
                        // 部屋タイプが存在　かつ　対応部屋タイプに対して、１部屋のみの場合、該当部屋は自動的に予約にアサインする END
                    }
                }
                // 2016/10/21 TA変更機能改善対応[到着日を変更すると、既に割当される部屋をクリアする] BEGIN
                // 新規の部屋タイプはSF側に非存在　かつ　到着日へんこうされると、既存の予約の既に割り当てる部屋はクリアを行う
                else {
                    if(isHadLeadId){    
						if (orgLead.EntryTime__c.date() != newLead.EntryTime__c.date()) {
							// 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh BEGIN
							//newLead.Rroom__c = null;
							boolean chgdtRoomClearFlag = TA_ServiceConfigHelp.getAppConfig(shopCd).chgdtRoomClearFlag;
							// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ BEGIN
							//if(chgdtRoomClearFlag) newLead.Rroom__c = null;
							if(chgdtRoomClearFlag) {
								newLead.Rroom__c = null;
								newLead.Field276__c = false;
							}
							// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ END
							// 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh END
						}
                    }
                }
                // 2016/10/21 TA変更機能改善対応[到着日を変更すると、既に割当される部屋をクリアする] END
                // 旧予約情報を更新する場合、見積明細は変更対象外
                // 新規予約のみ、見積明細を作成する
                if (!isHadLeadId) {
                    //見積もり明細取得
                    // 該当泊の明細情報のみ、送付する
                    Date ciDate = bookingInfo.basic.CheckInDate.adddays(i);
                    roomMaps.put(idx,setEachRoomBookingEstimeteItems(cloneItem,roomAndGuest,taxSericeFee,isRoomRateFlg,curPlan,ciDate));
                } else {
                	// 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ BEGIN
                	if (isClearEstItemsFlag) roomMaps.put(idx,setEachRoomBookingEstimeteItems(cloneItem,roomAndGuest,taxSericeFee,isRoomRateFlg,curPlan,newLead.EntryTime__c.date()));
                	else
                	// 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ END
                    roomMaps.put(idx, new List<BookingEstimateItem__c>());
                }
//mLogUtils.write_log('----------------部屋タイプ6=================');
				// 2017/01/09 親部屋集める:メール本文 fix BEGIN by zh
        		boolean mailDivFlag = TA_ServiceConfigHelp.getAppConfig(shopCd).mailDivFlag;
        		// 2017/01/09 親部屋集める:メール本文 fix END by zh
				// 第一番目の部屋に予約情報を集める
                if (j > 0 && CommConst.APPOTION_LEADSPLIT_DIV_CODE == CommConst.APPOTION_LEADSPLIT_DIV_CODE_UNION){
                	// １番名の部屋の泊の予約情報に人数更新
                    Integer roomIdx = i;
//mLogUtils.write_log('----------------roomIdx=================' + roomIdx);
//mLogUtils.write_log('----------------insLeadLst[roomIdx].size=================' + insLeadLst[roomIdx]);
					// 2016/08/31 不具合修正、親部屋の人数は０の場合、人数正常な合計できない不具合修正 BEGIN
                    //insLeadLst[roomIdx].StayPersons__c += CommUtils.nullToZero(newLead.StayPersons__c);
                    insLeadLst[roomIdx].StayPersons__c = CommUtils.nullToZero(insLeadLst[roomIdx].StayPersons__c) + CommUtils.nullToZero(newLead.StayPersons__c); 
                    // 新規　かつ　WARNメッセージ存在　かつ　次の部屋の人数が存在する場合 かつ　部屋情報が集める場合
                    if (CommUtils.nullToZero(newLead.StayPersons__c) > 0 
                    	&& bookingInfo.dmlAction == BI_TA_DmlAction.INS 
                    	&& CommUtils.nullToBlank(insLeadLst[roomIdx].comment3__c).contains(Label.MSG_038_0008)) {
                    	insLeadLst[roomIdx].comment3__c = CommUtils.nullToBlank(insLeadLst[roomIdx].comment3__c).replace(Label.MSG_038_0008, '');
                    }
                    // 2016/08/31 不具合修正、親部屋の人数は０の場合、人数正常な合計できない不具合修正 END
//mLogUtils.write_log('----------------idx=================' + idx);
//mLogUtils.write_log('----------------roomMaps.containsKey(idx)=================' + roomMaps.containsKey(idx));
//mLogUtils.write_log('----------------roomMaps1=================' + roomMaps);
                    if (roomMaps.containsKey(idx)) {
						// １番名の部屋の予約の見積明細に、当前の見積明細情報をコピーする
//mLogUtils.write_log('----------------roomIdx=================' + roomIdx);						
//mLogUtils.write_log('----------------roomMaps.get(roomIdx)=================' + roomMaps.get(roomIdx));
                    	roomMaps.get(roomIdx).addAll(roomMaps.get(idx));

                    	roomMaps.remove(idx);
//mLogUtils.write_log('----------------roomMaps2=================' + roomMaps);
                    }
//mLogUtils.write_log('----------------部屋タイプ7=================');
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
                    // 子供E人数
                    insLeadLst[roomIdx].ChildE__c += CommUtils.nullToZero(newLead.ChildE__c); 
                    newLead.ChildE__c = 0;
                    // プラン情報 <- NULL
                    newLead.Field310__c = null;
                    // コメント
                    newLead.Comment3__c = null;
                    // 2017/01/09 親部屋集める:メール本文 fix BEGIN by zh
mLogUtils.write_log('mailDivFlag:::' + mailDivFlag);
                    if(mailDivFlag) newLead.email__c = null;
                    // 2017/01/09 親部屋集める:メール本文 fix END by zh
                }
//mLogUtils.write_log('----------------部屋タイプ8=================');
                // 旅行会社関連参照情報設定
                newLead.SalesOfficeInfoRef__c = TraveCompany.size() > 1 ? TraveCompany[1].Id : (TraveCompany.size() > 0 ? TraveCompany[0].Id : null);
                // 2012/12/23  Add
                newLead.RoomGroupNo__c = j;//roomNoIdx;
        // 2015/10/30 故障部屋は自動割当て機能に追加対応 BEGIN
                newLead.EventSource__c = APPNAME + '_' + bookingInfo.DataID + '_' + DateTime.now().getTime();
                // 2015/10/30 故障部屋は自動割当て機能に追加対応 END
        // 単価定義区分の設定する
                newLead.UnitPriceDefKb__c = String.valueOf(CommConst.APPOPTION_UTP_DEF_KB);
                //bookingInfo.TaxServiceFee;
//mLogUtils.write_log('----------------finalFieldMap.keySet()=================' + finalFieldMap.keySet());
                // 2016/10/21 TA変更機能改善対応、項目値自動設定不具合改修 BEGIN
                /*
                for(String fieldName : finalFieldMap.keySet()){
                    Schema.DescribeFieldResult describeField = finalFieldMap.get(fieldName);
//mLogUtils.write_log('更新内容[' + fieldName + ']::' + describeField.isCreateable() );
//mLogUtils.write_log('更新内容[' + fieldName + ']::' + newLead.get(fieldName));
                    if(newLead.get(fieldName) == null && describeField.isCreateable()){
//mLogUtils.write_log('----------------部屋タイプ13=================');
                        // デイフォル値を自動設定を行う
                        newLead.put(fieldName,CommUtils.ConvByFielType(autoSetupfieldMap.get(fieldName), describeField.getType()));
                        //mLogUtils.write_log('更新内容[' + fieldName + ']:1:' + fieldMap.get(fieldName) );
                        mLogUtils.write_log('項目値自動設定[' + fieldName + ']:1:' + newLead.get(fieldName) );
                    }
                }
                */
                // 2016/10/21 TA変更機能改善対応、項目値自動設定不具合改修 END
                insLeadLst.add(newLead);
            }
        }

//mLogUtils.write_log('insLeadLst:::' + insLeadLst);
        
        // 見積り金額設定を行う「一件のみ設定する」
        insLeadLst[0].BridalDantaikei__c = bookingInfo.basicRate.TotalAccommodationCharge;
        //update モード
        //if(isUpdateFlag) compareXmlDiff(insLeadLst[0],bookingInfo);
        List<Lead__c> updLeadLst = new List<Lead__c>();
//mLogUtils.write_log('userOrgLeadSet:::' + userOrgLeadSet);
		// 既存の予約情報対象外のデータはキャンセルする
        for(integer key : groupLeadMap.keySet()){
            List<Lead__c> childLst = groupLeadMap.get(key);
            if(childLst != null){
                for(integer i = 0 ; i < childLst.size(); i++){
                    String setKey = key + '_' + i;
                    if(!userOrgLeadSet.contains(setKey)){
//mLogUtils.write_log('setKey:::' + setKey);
						// 2016/10/07 在庫キャンセル処理対応(発生源)
						childLst.get(i).EventSource__c = APPNAME + '_' + bookingInfo.DataID + '_' + DateTime.now().getTime();
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
        if (!updLeadLst.isEmpty()) update updLeadLst;
        // SUBINDEX自動作成
        if (!insLeadLst.isEmpty()) {
        	// 2017/05/04 店舗ごとの予約・会計権限機能対応 BEGIN
	        //CommLogicProcess logic = new CommLogicProcess();
	        // 2017/05/04 店舗ごとの予約・会計権限機能対応 END
	        logic.autoCreateIndexSub(insLeadLst);
	        upsert insLeadLst;
        }
//mLogUtils.write_log('roomMaps:::' + roomMaps.size());
//for (Integer i = 0; i<roomMaps.size(); i++) {
//mLogUtils.write_log('i['+i+']' + roomMaps.get(i));
//}
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
            // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ BEGIN
            if (isClearEstItemsFlag) leadIds.add(insLead.id);
            else {
            // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ END
            // 新規予約の場合
            if (!updateOrgLeadIdSet.contains(insLead.id)) leadIds.add(insLead.id);
            // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ BEGIN
            }
            // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ END
        }
//mLogUtils.write_log('delete:before::'+insLeadLst);
        // ご予約のプラン項目から自動作成の見積明細を全部削除する
        delete [select id,name from BookingEstimateItem__c where refBooking__c =:leadIds and ParentBookingItemRef__c = null];
        delete [select id,name from BookingEstimateItem__c where refBooking__c = :leadIds ];
        // 変更の場合、支払情報は更新を行わない
        // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ BEGIN
        //if (updateOrgLeadIdSet.isEmpty()) {
        if (updateOrgLeadIdSet.isEmpty() || isClearEstItemsFlag) {
        // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ END
        	// 2016/06/17 取り込みの見積明細の順番は調整対応 BEGIN
            //見積もり明細：支払い作成「ポイント・支払い」
            // 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応 by zh BEGIN
	        //lastInsItems.addAll(upsertPaymentBookingExtimeItem(insLeadLst[0],bookingInfo));
	        // 異常ケースを回避対応      
	        if (payMediaLinkPos  >= insLeadLst.size()) payMediaLinkPos = 0;
	        lastInsItems.addAll(upsertPaymentBookingExtimeItem(insLeadLst[payMediaLinkPos],bookingInfo)); 
	        // 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応 by zh END
            // 2016/06/17 取り込みの見積明細の順番は調整対応 END
            //見積もり明細　オプション作成する
            //upsertBookingEstimeteItemsByEach(bookingInfo,insLeadLst[0]);
        }
        mLogUtils.write_log('sync2wayEstRowNoSetup Start');
        // 2020/07/30 入湯税の自動入力機能について改善 ZH BEGIN
		List<Lead__c> proLeadLst = new List<Lead__c>();
		proLeadLst.addAll(updLeadLst);
		proLeadLst.addAll(insLeadLst);
        lastInsItems.addAll(CommLogicProcess.getBathTaxBookEstLst(proLeadLst, lastInsItems, oldLeadLst));
        // 2020/07/30 入湯税の自動入力機能について改善 ZH END
		// 2016/06/09 取り込みの見積明細の順番は調整対応 BEGIN
		(new CommLogicProcess()).sync2wayEstRowNoSetup(insLeadLst, lastInsItems);
		// 2016/06/09 取り込みの見積明細の順番は調整対応 END 
		// 2017/05/04 店舗ごとの予約・会計権限機能対応 BEGIN
		List<Lead__c> restoreLeads = new List<Lead__c>();
		restoreLeads.addAll(updLeadLst);
		restoreLeads.addAll(insLeadLst);
		logic.restoreShopAuthCheckSetup(restoreLeads, true);
		// 2017/05/04 店舗ごとの予約・会計権限機能対応 END
		mLogUtils.write_log('sync2wayEstRowNoSetup End');
        mLogUtils.write_method_end();
    }
    
    // プラン明細に室料するがどうか判断ロジック
    private static Boolean isRoomRateItem(AccountMaster__c acc) {
        return RackRateUtils.isRoomRateProduct(acc);
    }
    
    // 2016/07/10 予約チャネル名の変換機能追加対応 BEGIN
	private string getChanelStr(BI_TA_SyncInfo bookingInfo, list<account> TraveCompany) {
        String agtCode = CommUtils.nullToBlank(bookingInfo.salesOffice.SalesOfficeCompanyCode);
        String chanelStr = TA_ServiceConfigHelp.getMapAgtToChanelConfig(shopCd).get(agtCode);
		if (CommUtils.isBlank(chanelStr)) chanelStr = (!TraveCompany.isEmpty() ? TraveCompany[0].Name : null);
		return chanelStr;
	}
	// 2016/07/10 予約チャネル名の変換機能追加対応 END
	
    // ポイント、売掛金、カードなど事前支払情報は見積明細に反映を行う
    private List<BookingEstimateItem__c> upsertPaymentBookingExtimeItem(Lead__c lead,BI_TA_SyncInfo bookingInfo){
        mLogUtils.write_method_start('upsertPaymentBookingExtimeItem');
        // 合計宿泊料金(総額)
        Decimal totalPrice = bookingInfo.basicRate.TotalAccommodationCharge;
        BI_TA_Member member = bookingInfo.member;
        BillSimpleHelp help = new BillSimpleHelp(shopCd);
        // ポイント合計金額格納
        Decimal pointAmount = 0;
        // 新規追加プランデータ存在する場合
        List<BookingEstimateItem__c> insLst = new List<BookingEstimateItem__c>();
        // ポイント支払情報格納する
        // 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ BEGIN
        //List<BookingEstimateItem__c> pointLst = new List<BookingEstimateItem__c>();   
        BookingEstimateItem__c pointEst = null;
        // 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ END 

// 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う BEGIN
		String settlementDiv = CommUtils.nullToBlank(bookingInfo.basicRate.Payment);
		String agtCode = CommUtils.nullToBlank(bookingInfo.salesOffice.SalesOfficeCompanyCode);
		list<string> equalKeyLst = getEqualsKeyLst(settlementDiv, agtCode);
 		map<string, AccountMaster__c> payProductIdMap = new map<String, AccountMaster__c>();
 		// 2017/08/02 料金の12%が事前払い BEGIN
 		//map<String, TA_ServiceConfigHelp.PAYMENT_CONVERT> paymentConfigMap = TA_ServiceConfigHelp.getPaymentConfig(shopCd);
 		map<String, List<TA_ServiceConfigHelp.PAYMENT_CONVERT>> paymentConfigMap = TA_ServiceConfigHelp.getPaymentConfig(shopCd);
 		// 2017/08/02 料金の12%が事前払い END
 		// 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ BEGIN
 		//map<String, TA_ServiceConfigHelp.PAYMENT_CONVERT> pointConfigMap = TA_ServiceConfigHelp.getPointConfig(shopCd);
 		map<String, List<TA_ServiceConfigHelp.PAYMENT_CONVERT>> pointConfigMap = TA_ServiceConfigHelp.getPointConfig(shopCd);
 		// 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ END
    	list<string> productCdlst = new list<string>();
    	// 2017/08/02 料金の12%が事前払い BEGIN
    	for (List<TA_ServiceConfigHelp.PAYMENT_CONVERT> parserPays : paymentConfigMap.values()) {
    	    for (TA_ServiceConfigHelp.PAYMENT_CONVERT parserPay : parserPays) {
    		  productCdlst.add(parserPay.payProdCode);
    	    }
    	}
    	// 2017/08/02 料金の12%が事前払い END
    	// 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ BEGIN
    	// PARSENO属性未指定の定義情報を格納する
        map<String, TA_ServiceConfigHelp.PAYMENT_CONVERT> noParsePointConfigMap = new map<String, TA_ServiceConfigHelp.PAYMENT_CONVERT>();
    	// 関連定義商品コードを取得する
    	for (List<TA_ServiceConfigHelp.PAYMENT_CONVERT> parserPoints : pointConfigMap.values()) {
			// 支払区分＆AGTコードにより、関連の定義支払商品マッピング情報
	    	for (TA_ServiceConfigHelp.PAYMENT_CONVERT parsePoint : parserPoints) {
	    		// 支払商品コードを配列に格納する
	    		productCdlst.add(parsePoint.payProdCode);
	    		// POSNO未定義の場合、該当定義情報を格納する
	    		if(parsePoint.parseTemplate == null) {
	    			// 該当XMLの支払区分＆AGTコード情報により、XML定義情報をマッピングする
	    			for (String key : equalKeyLst) {
						// XML定義情報と取り込みのXMLの定義情報をマッピングする、一致する場合
						if (key == parsePoint.getkey() && !noParsePointConfigMap.containsKey(key)) noParsePointConfigMap.put(key, parsePoint);
	    			}
	    		}
	    	}
    	}
    	// 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ END
    	if (!productCdlst.isEmpty()) {
    		payProductIdMap = TA_ServiceConfigHelp.getPaymentProductId(productCdlst);
    	}
// 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う END
  
        // ポイント支払情報が存在する場合
        // 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ BEGIN
        // basicRateにポイント支払情報が未設定する場合   
        //if(member != null && pointLst.isEmpty()){
        if(member != null && pointEst == null){
        // 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ END
            Decimal UserUsePoints = CommUtils.nullToZero(member.UserUsePoints);
mLogUtils.write_log('member.UserUsePoints:'+member.UserUsePoints);
            if(UserUsePoints > 0){
                mLogUtils.write_log('使用ポイント:' + UserUsePoints);
                // 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ BEGIN
                //pointLst.add(new BookingEstimateItem__c (
                pointEst = (new BookingEstimateItem__c (
                // 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ END
                  refBooking__c = lead.id,
                  UnitPrice__c = UserUsePoints,
                  Amount__c = 1
                ));
                pointAmount += UserUsePoints;
            }
        }
mLogUtils.write_log('pointAmount:'+pointAmount);

        if (pointAmount>0) {
        	// 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ BEGIN
        	AccountMaster__c wkCovertPointAcc = null;
        	Decimal caledPoint = 0;
        	// 一般情報タグにポイント数金額を分析用
        	String otherInfo = CommUtils.nullToBlank(bookingInfo.basic.OtherServiceInformation);
        	if (!CommUtils.isBlank(otherInfo)) {
        		otherInfo += '</OtherServiceInformation>';
	            for (String key : equalKeyLst) {
	                mLogUtils.write_log('ポイント定義情報MATCH:' + KEY + '=' + pointConfigMap.containsKey(key));
		            if (pointConfigMap.containsKey(key)) {
		            	// 該当決済区分、AGTCODEにより、定義情報を取得する
		                List<TA_ServiceConfigHelp.PAYMENT_CONVERT> convertInfs = pointConfigMap.get(key);
	                    for (TA_ServiceConfigHelp.PAYMENT_CONVERT convertInf : convertInfs) {
mLogUtils.write_log('point convertInf:'+convertInf); 
mLogUtils.write_log('depsion convertInf.parseTemplate:'+convertInf.parseTemplate); 
							//PARSEのテンプレートを未定義場合、該当商品コードで見積明細を作成する
							if(convertInf.parseTemplate != null) {
								// PARSE分実施する
			                    Decimal locPayInfo = convertInf.parseTemplate.parsePayInfo(otherInfo);
		                        mLogUtils.write_log('depsion locPayInfo:'+locPayInfo); 
			                    // 指定情報を見つかる場合
			                    if (locPayInfo > 0) {
			                        // 個別PARSE処理存在するがどう、存在の場合、処理を行う
			                        wkCovertPointAcc = payProductIdMap.get(convertInf.payProdCode);
			                        if (wkCovertPointAcc == null) continue;
					                BookingEstimateItem__c est = new BookingEstimateItem__c (
										refBooking__c = lead.id,
										UnitPrice__c = locPayInfo,
										Amount__c = 1,
										refAccountMaster__c = wkCovertPointAcc.Id,
										refAccountMaster__r = wkCovertPointAcc
					                );
			                        // 既に支払明細作成済みの金額を加算する
			                        caledPoint += locPayInfo;
					                insLst.add(est);
			                        //break;
			                    }
							}

		                } // End For
		                //if (wkCovertPointAcc != null) break;
		            }//end if (pointConfigMap.containsKey(key))
		        } // end for (String key : equalKeyLst)
        	}
        	// 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ END
// 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う BEGIN
			// 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ BEGIN
			if (pointAmount > caledPoint) {
			// 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ END
	        	AccountMaster__c covertAcc = null;
				for (String key : equalKeyLst) {
					// 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ BEGIN
					/*
					mLogUtils.write_log('割引MATCH:' + KEY + '=' + pointConfigMap.containsKey(key));
					if (pointConfigMap.containsKey(key)) {			
						TA_ServiceConfigHelp.PAYMENT_CONVERT convertInf = pointConfigMap.get(key);
						covertAcc = payProductIdMap.get(convertInf.payProdCode);
						break;
					}*/
					mLogUtils.write_log('割引MATCH:' + KEY + '=' + noParsePointConfigMap.containsKey(key));
					if (noParsePointConfigMap.containsKey(key)) {			
						TA_ServiceConfigHelp.PAYMENT_CONVERT convertInf = noParsePointConfigMap.get(key);
						covertAcc = payProductIdMap.get(convertInf.payProdCode);
						break;
					}
					// 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ END
				}
	// 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う END
	            // ポイント支払メデイア情報を取得する
	// 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う BEGIN
	            //AccountMaster__c pointAcc = help.getMediaLabToAccMstMap().get(help.getPaymentTypeToMediaLabMap().get(CommConst.PROD_PAY_TYPE_DIS_PRICE));
	            AccountMaster__c pointAcc = covertAcc != null ? covertAcc : help.getMediaLabToAccMstMap().get(help.getPaymentTypeToMediaLabMap().get(CommConst.PROD_PAY_TYPE_DIS_PRICE));
	// 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う END
	            if (pointAcc != null) {
	            	// 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ BEGIN
	            	/*
	                for (BookingEstimateItem__c est : pointLst) {
	                    est.refAccountMaster__c = pointAcc.Id;
	                    est.refAccountMaster__r = pointAcc;
	                }*/
	                if (pointEst != null) {
	                	pointEst.refAccountMaster__c = pointAcc.Id;
	                	pointEst.refAccountMaster__r = pointAcc;
	                	pointEst.UnitPrice__c = (pointAmount - caledPoint);
	                }
	                // 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ END
	            }
			// 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ BEGIN
	            //if (!pointLst.isEmpty()) insLst.addAll(pointLst);
	        	if (pointEst != null) insLst.add(pointEst);
			}
			// 2019/03/29 取込のポイントはそれぞれの支払商品ごとに取込できるように改善 WSQ END
        }   
        // 2017/08/02 料金の12%が事前払い BEGIN
        AccountMaster__c wkCovertPayAcc = null;
        String specialServiceRequest = CommUtils.nullToBlank(bookingInfo.basic.SpecialServiceRequest) + '</SpecialServiceRequest>';
        if (!CommUtils.isBlank(specialServiceRequest)) {
            for (String key : equalKeyLst) {
                mLogUtils.write_log('事前支払割引MATCH:' + KEY + '=' + paymentConfigMap.containsKey(key));
	            if (paymentConfigMap.containsKey(key)) { 
	                List<TA_ServiceConfigHelp.PAYMENT_CONVERT> convertInfs = paymentConfigMap.get(key);
                    for (TA_ServiceConfigHelp.PAYMENT_CONVERT convertInf : convertInfs) {
                        mLogUtils.write_log('depsion convertInf:'+convertInf); 
mLogUtils.write_log('depsion convertInf.parseTemplate:'+convertInf.parseTemplate); 
						//没有解析的模板、不进行处理
						if(convertInf.parseTemplate == null) continue;
	                    Decimal locPayInfo = convertInf.parseTemplate.parsePayInfo(specialServiceRequest);
                        mLogUtils.write_log('depsion locPayInfo:'+locPayInfo); 
	                    // 指定情報を見つかる場合
	                    if (locPayInfo > 0) {
	                        // 既に支払済金額
	                        pointAmount += locPayInfo;
	                        // 個別PARSE処理存在するがどう、存在の場合、処理を行う
	                        wkCovertPayAcc = payProductIdMap.get(convertInf.payProdCode);
	                        if (wkCovertPayAcc == null) continue;
			                BookingEstimateItem__c est = new BookingEstimateItem__c (
			                  refBooking__c = lead.id,
			                  UnitPrice__c = locPayInfo,
			                  Amount__c = 1,
	                          refAccountMaster__c = wkCovertPayAcc.Id,
	                          refAccountMaster__r = wkCovertPayAcc
			                );
			                insLst.add(est);
	                        break;
	                    }
	                } // End For
	                if (wkCovertPayAcc != null) break;
	            }
	        }
        }
        // 2017/08/02 料金の12%が事前払い END
        // 事前決済区分により、支払情報の作成
        if(!CommUtils.isBlank(settlementDiv)){
        	Integer SettlementDivCd = null;
			set<string> cardPaymentConvertSet = TA_ServiceConfigHelp.getCardPaymentConvertConfig(shopCd);
			if (cardPaymentConvertSet != null && cardPaymentConvertSet.contains(settlementDiv)) {
				SettlementDivCd = 2;
			}
			set<string> creditPaymentConvertSet = TA_ServiceConfigHelp.getCreditPaymentConvertConfig(shopCd);
			if (creditPaymentConvertSet != null && creditPaymentConvertSet.contains(settlementDiv)) {
				SettlementDivCd = 4;
			}
// 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う BEGIN
            AccountMaster__c commAcc = null;
    		for (String key : equalKeyLst) {
mLogUtils.write_log('事前決済MATCH:' + KEY + '=' + paymentConfigMap.containsKey(key));
        		if (paymentConfigMap.containsKey(key)) {
        		    // 2017/08/02 料金の12%が事前払い BEGIN
        			//TA_ServiceConfigHelp.PAYMENT_CONVERT convertInf = paymentConfigMap.get(key);
        			List<TA_ServiceConfigHelp.PAYMENT_CONVERT> convertInfs = paymentConfigMap.get(key);
        			for (TA_ServiceConfigHelp.PAYMENT_CONVERT convertInf : convertInfs) {
	        			// 解析定義情報が存在する場合、処理対象外になる
	        			if (!CommUtils.isBlank(convertInf.parseTemplateNo)) continue;
	        			// 条件満足する場合、該当商品コードは明細に出力する
						commAcc = payProductIdMap.get(convertInf.payProdCode);
						break;
        			}
        			if (commAcc != null) break;
        			// 2017/08/02 料金の12%が事前払い END
        		}
        	} 
// 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う END
            // TL側の定義参照用:事前決済区分「0」:指定なし、「1」:法人利用、「2」:カード決済ズミ、「3」:現地払い、 「4」:ツアー会社、「5」:一部精算、「6」:エージェント精算
            // 「1」:法人利用 「4」:ツアー会社  →　売掛金
			if(SettlementDivCd == 1 || SettlementDivCd == 4 ){
				if (commAcc == null)
				commAcc = help.getMediaLabToAccMstMap().get(CommConst.MEDIA_TYPE_03);
			}
            // 「2」:カード決済ズミ →カード
			else if ( SettlementDivCd == 2){
				if (commAcc == null)
				commAcc = help.getMediaLabToAccMstMap().get(help.getPaymentTypeToMediaLabMap().get(CommConst.PROD_PAY_TYPE_CARD));
			}

            mLogUtils.write_log('事前決済区分:['+settlementDiv+']' + commAcc);
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
        // 2016/06/17 取り込みの見積明細の順番は調整対応 BEGIN
        //if(!insLst.isEmpty()) insert insLst;
        mLogUtils.write_method_end();
        return insLst;
        // 2016/06/17 取り込みの見積明細の順番は調整対応 END
    }

// 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う BEGIN
    private list<String> getEqualsKeyLst (String settlementDiv, String agtCode) {
    	List<String> equalKeyLst = new List<String>{
    		CommUtils.nullToBlank(settlementDiv) + '_' + CommUtils.nullToBlank(agtCode),
    		CommUtils.nullToBlank(settlementDiv) + '_',
    		'_' + CommUtils.nullToBlank(agtCode),
    		'_'
    	};
		list<string> equalKeys = new list<string>();
    	set<string> filterSet = new set<String>();
    	for (Integer i =0; i < equalKeyLst.size(); i++) {
    		String key = equalKeyLst[i];
    		if (filterSet.contains(key)) continue;
    		filterSet.add(key);
    		equalKeys.add(key);
    	}
    	return equalKeys;
    }
// 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う END  
     
    // 指定部屋、指定日の見積明細情報を登録する
    // item:該当日の予約の見積明細作成元
    private List<BookingEstimateItem__c> setEachRoomBookingEstimeteItems(   BookingEstimateItem__c item, 
                                                                            BI_TA_RoomAndGuestInfo roomAndGuest,
                                                                            Integer taxSericeFee,
                                                                            Boolean isRoomRateFlg,
                                                                            Plan__c pCurPlan,
                                                                            Date usedDate){
mLogUtils.write_method_start('setEachRoomBookingEstimeteItems');
//mLogUtils.write_log('BookingEstimateItem__c:' + item);
//mLogUtils.write_log('roomAndGuest:' + roomAndGuest);
//mLogUtils.write_log('taxSericeFee:' + taxSericeFee);
//mLogUtils.write_log('isRoomRateFlg:' + isRoomRateFlg);
//mLogUtils.write_log('curPlan:' + curPlan);
//mLogUtils.write_log('usedDate:' + usedDate);
        List<BI_TA_RoomRateInformation> roomRateLst = roomAndGuest.roomRateLst;
        List<BookingEstimateItem__c> detailLst = new List<BookingEstimateItem__c>();
        if (item == null) return detailLst;
        // 料金設定情報がありません
        if (roomRateLst.isEmpty()) return detailLst;
        // 人員単価金額で総計利用金額を計算を行う
        BI_TA_RoomInformation room = roomAndGuest.roomI;
        // 宿泊者タイプの総人数
        Integer roomPaxCount = room.PerRoomPaxCount ;       	// 利用人数
        Integer roomPaxMalCount = room.RoomPaxMaleCount ;       // 男性人数
        integer roomPaxFemaleCount = room.RoomPaxFemaleCount;   // 女性人数
        integer roomChildACount = room.RoomChildA70Count;       // 子供A人数
        integer roomChildBCount = room.RoomChildB50Count;       // 子供B人数
        integer roomCHildCCount = room.RoomChildC30Count;       // 子供C人数
        integer roomChildDCount = room.RoomChildDNoneCount;     // 子供D人数
        integer roomChildOtherCount = room.RoomChildOtherCount;	// 子供その他人数
            
        Map<String,BookingEstimateItem__c> itemMap = new Map<String,BookingEstimateItem__c>();
        
mLogUtils.write_log('料金区分:' + (isRoomRateFlg ? '部屋単価' : '人員単価'));
		// 処理対象リストを取得する
		list<BI_TA_RoomRateInformation> currRoomRateLst = new list<BI_TA_RoomRateInformation>();
		for(BI_TA_RoomRateInformation roomRate : roomRateLst){
			if (roomRate.RoomDate != usedDate) continue;
			currRoomRateLst.add(roomRate);
		}
		
		boolean lastRateFlag = currRoomRateLst.size() == 1;
        // 室単価の場合、総利用料金はプラン/室料に設定を行う
        // 料金区分は人員単価の場合
        if (!isRoomRateFlg) {
        	// 部屋料金情報リストを取得する
            Integer roomRateLen = currRoomRateLst.size();
            // 同じ宿泊者タイプ違うの金額の場合、後ろから利用金額を１単位で合計を行う
            for (Integer i = (roomRateLen -1); i >= 0; i--) {
                BI_TA_RoomRateInformation roomRate = currRoomRateLst[i];
                // 泊の日のみ、明細取得、設定する
                if (roomRate.RoomDate != usedDate) continue;
                if(i == 0) lastRateFlag = true;
                // 大人一人料金~PerChildOtherRate全部未設定の場合、TotalPerRoomRate項目金額を使う
                if (CommUtils.nullToZero(roomRate.PerPaxRate) == 0 &&
                	CommUtils.nullToZero(roomRate.PerChildA70Rate) == 0 &&
                	CommUtils.nullToZero(roomRate.PerChildB50Rate) == 0 &&
                	CommUtils.nullToZero(roomRate.PerChildC30Rate) == 0 &&
                	CommUtils.nullToZero(roomRate.PerChildDRate) == 0 &&
                	CommUtils.nullToZero(roomRate.PerChildOtherRate) == 0 &&
                	CommUtils.nullToZero(roomRate.TotalPerRoomRate) != 0) {
mLogUtils.write_log('1室あたり宿泊料金合計から見積明細に設定:'+roomRate.TotalPerRoomRate);
                	// 見積明細作成
            		BookingEstimateItem__c newItem = getRoomEstimateItem(item, roomRate);
                	// 利用人数あり　かつ　男性　OR　女性　以外の設定人数がない場合、平均値計算を行う
                	if (roomPaxCount == (roomPaxMalCount + roomPaxFemaleCount) && roomPaxCount > 0) {
                		Decimal wkPrice = CommUtils.RoundProcess(roomRate.TotalPerRoomRate / roomPaxCount,CommUtils.getPointLen());
                		Decimal wkAmount = wkPrice * roomPaxCount;
                		if (wkAmount != roomRate.TotalPerRoomRate || !presonRateAutoCal) {
mLogUtils.write_log('宿泊料金合計 * 1 で設定');
	                		// 1部屋単位に設定する
							newItem.UnitPrice__c = roomRate.TotalPerRoomRate;
	        				newItem.Amount__c = 1;
                		} else {
mLogUtils.write_log('宿泊料金合計 / 人数 * 人数 で設定');
	                		// 人数は大人のみ場合。平均値計算を行う
							newItem.UnitPrice__c = wkPrice;
	        				newItem.Amount__c = roomPaxCount;
                		}
                	}
                	detailLst.add(newItem);
                	break;
                }
                // 2016/06/10 子供料金プラン取り込み機能対応 BEGIN
                // 大人料金
                Decimal perPaxRate = CommUtils.nullToZero(roomRate.PerPaxRate);
                // 2016/06/10 子供料金プラン取り込み機能対応 END
                // 男性の場合
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
                // 女性の場合
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
                // 子供A
                if(roomChildACount > 0 && roomRate.PerChildA70Rate != null){
                    integer perAddAmount = 1;
                    BookingEstimateItem__c newItem = item.clone(false,true);
                    newItem.UnitPrice__c = roomRate.PerChildA70Rate;
                    // 2016/06/10 子供料金プラン取り込み機能対応 BEGIN
                    matchChildrenPlan(newItem,perPaxRate);
                    // 2016/06/10 子供料金プラン取り込み機能対応 END
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
                // 子供B
                if(roomChildBCount > 0 && roomRate.PerChildB50Rate != null){
                    integer perAddAmount = 1;
                    BookingEstimateItem__c newItem = item.clone(false,true);
                    newItem.UnitPrice__c = roomRate.PerChildB50Rate;
                    // 2016/06/10 子供料金プラン取り込み機能対応 BEGIN
                    matchChildrenPlan(newItem,perPaxRate);
                    // 2016/06/10 子供料金プラン取り込み機能対応 END
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
                // 子供C
                if(roomCHildCCount > 0 && roomRate.PerChildC30Rate != null){
                    integer perAddAmount = 1;
                    BookingEstimateItem__c newItem = item.clone(false,true);
                    newItem.UnitPrice__c = roomRate.PerChildC30Rate;
                    // 2016/06/10 子供料金プラン取り込み機能対応 BEGIN
                    matchChildrenPlan(newItem,perPaxRate);
                    // 2016/06/10 子供料金プラン取り込み機能対応 END
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
                // 子供D
                if(roomChildDCount > 0 && roomRate.PerChildDRate != null){
                    integer perAddAmount = 1;
                    BookingEstimateItem__c newItem = item.clone(false,true);
                    newItem.UnitPrice__c = roomRate.PerChildDRate;
                    // 2016/06/10 子供料金プラン取り込み機能対応 BEGIN
                    matchChildrenPlan(newItem,perPaxRate);
                    // 2016/06/10 子供料金プラン取り込み機能対応 END
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
                // 子供E
                if(roomChildOtherCount > 0 && roomRate.PerChildOtherRate != null){
                    integer perAddAmount = 1;
                    BookingEstimateItem__c newItem = item.clone(false,true);
                    newItem.UnitPrice__c = roomRate.PerChildOtherRate;
                    // 2016/06/10 子供料金プラン取り込み機能対応 BEGIN
                    matchChildrenPlan(newItem,perPaxRate);
                    // 2016/06/10 子供料金プラン取り込み機能対応 END
                    String key = 'ChildECount_' + newItem.UnitPrice__c;
                    if(lastRateFlag) perAddAmount = roomChildOtherCount;
                    if(itemMap.containsKey(key))
                        itemMap.get(key).Amount__c += perAddAmount;
                    else {
                        newItem.Amount__c = perAddAmount;
                        itemMap.put(key,newItem);
                    }
                    roomChildOtherCount--;
                }
			}
			// 利用金額同じする場合、合流判定用マイプ
			Map<Decimal,BookingEstimateItem__c> itemPriceMap = new Map<Decimal,BookingEstimateItem__c>();
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
        // RoomRateの場合、プラン室料自動設定機能を追加する BEGIN
        else if(isRoomRateFlg){
            for(BI_TA_RoomRateInformation roomRate : currRoomRateLst){
            	/*
                BookingEstimateItem__c newItem = item.clone(false,true);
                newItem.UnitPrice__c = roomRate.TotalPerRoomRate != null ? roomRate.TotalPerRoomRate : roomRate.PerPaxRate;
mLogUtils.write_log('newItem.UnitPrice__c：' + newItem.UnitPrice__c); 
                newItem.Amount__c = 1;
                */
                detailLst.add(getRoomEstimateItem(item, roomRate));
            }
        }
        // RoomRateの場合、プラン室料自動設定機能を追加する END
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
            // 2016/06/10 子供料金プラン取り込み機能対応 BEGIN
            // 該当対応の会計商品コードを取得する、該当商品コード
            PlanDetailInfo locPlanDetailInf = gPlanDetailInf;
            Plan__c locCurPlan = pCurPlan;
            String locProductCode = bookingItem.Field3__c;
            if (childPlanPlanMstMap.containsKey(locProductCode)) {
                locCurPlan = childPlanPlanMstMap.get(locProductCode);
            }
            if (childPlanDetailMap.containsKey(locProductCode)) {
                locPlanDetailInf = childPlanDetailMap.get(locProductCode);
            }
            // 2016/06/10 子供料金プラン取り込み機能対応 END
            // プラン明細の金額自動配分を行う[プランかつプラン明細存在の場合、配分処理を行う]
        // 2016/06/10 子供料金プラン取り込み機能対応 BEGIN
            if (locPlanDetailInf.isHavePdData) {
                // 利用金額からSF側の単価定義区分と一致の利用金額を変換する
                // 変換後のSF側の利用金額
                Decimal curnPayPrice = bookingItem.UnitPrice__c;
                // SF側のプラン金額（単価）
                Decimal orgPlanPrice = locCurPlan.Price__c;
                // 非課税商品が存在する場合、利用金額は税込み、サビース料金計算後の金額を計算する
                if (locPlanDetailInf.priceNoTaxSumVal > 0) {
                    mLogUtils.write_log('非課税商品あり：金額：' + locPlanDetailInf.priceNoTaxSumVal);
                    // サビース料込合計金額を計算する[単価定義区分２に変更]
                    Decimal noTaxIncServiceSummary = CommUtils.convertPriceByTaxKbn(locPlanDetailInf.priceNoTaxSumVal, 0, locCurPlan.ServiceRate__c, taxSericeFee, CommConst.APPOPTION_UTP_DEF_KB_OP2);
        // 2016/06/10 子供料金プラン取り込み機能対応 END
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
            // 2016/06/10 子供料金プラン取り込み機能対応 BEGIN
                    //orgPlanPrice = orgPlanPrice - planDetailInf.priceNoTaxSumVal;
            orgPlanPrice = orgPlanPrice - locPlanDetailInf.priceNoTaxSumVal;
                    // 2016/06/10 子供料金プラン取り込み機能対応 END
                    // 2019/09/15 軽減税率機能対応 WGCH BEGIN
                    // プラン元金額から非課税金額を外す
                    if(isReducedTaxFlg){
                    	curnPayPrice = CommUtils.nullToZero(estUnitPriceEnd) - CommUtils.nullToZero(locPlanDetailInf.priceNoTaxSumValEnd);
                    	orgPlanPrice = CommUtils.nullToZero(locPlanDetailInf.curnPayPriceEnd);
                    }
                    // 2019/09/15 軽減税率機能対応 WGCH END
                    mLogUtils.write_log('元のプラン金額は調整後：' + orgPlanPrice);
                    mLogUtils.write_log('元の利用金額は調整後：' + curnPayPrice);
                }
                // 2019/09/15 軽減税率機能対応 WGCH BEGIN
                else if(isReducedTaxFlg){
                	curnPayPrice = CommUtils.nullToZero(estUnitPriceEnd) - CommUtils.nullToZero(locPlanDetailInf.priceNoTaxSumValEnd);
                	orgPlanPrice = CommUtils.nullToZero(locPlanDetailInf.curnPayPriceEnd);
                }
                // 2019/09/15 軽減税率機能対応 WGCH END
                if (orgPlanPrice != curnPayPrice) 
			// 2016/06/10 子供料金プラン取り込み機能対応  BGEIN
                    bookingItem.PlanDetailSyncInfo__c = getPlanDetailSyncInfo(orgPlanPrice,curnPayPrice,locPlanDetailInf);
                    // 2016/06/10 子供料金プラン取り込み機能対応  END
		    mLogUtils.write_log('プラン明細個別設定情報 ：' + bookingItem.PlanDetailSyncInfo__c);
            }
        }
        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
        if(ldInfo != null){
        	detailLst = ProductItemUtils.getNwDetailLst(detailLst, ldInfo);
        }
        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
        mLogUtils.write_method_end();
        return detailLst;                                                                        
    }
    // 室料単位の見積明細情報を設定する
    private BookingEstimateItem__c getRoomEstimateItem(BookingEstimateItem__c orgItem, BI_TA_RoomRateInformation roomRate) {
        BookingEstimateItem__c newItem = orgItem.clone(false,true);
        newItem.UnitPrice__c = roomRate.TotalPerRoomRate != null ? roomRate.TotalPerRoomRate : roomRate.PerPaxRate;
        newItem.Amount__c = 1;
        return newItem;
    }
    // プラン関連のプラン明細の単価定義情報の取得する
    // 設定書式：プラン明細ID:単価:会計商品ID:会計商品名;
    private String getPlanDetailSyncInfo(Decimal orgUnitPrice,Decimal curUnitPrice,PlanDetailInfo planDetailInf){
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
        // 調整可能の明細に優先順位で調整を行う
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
            }
        }
        // 残金あり、自動配分の場合
        if (autoSplitFlg && diffUnitSum != 0) {
            Decimal splitUnit = 1;
            if (pointLen > 0) splitUnit = (diffUnitSum < 0 ? -1 : 1) * (1/10*pointLen);
            Integer maxLen = 0; // Dead Loop
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
    
    // 顧客リスト情報を変数に格納する
    //private List<Contact> contactsLst;
    // お客様情報分析、設定する
    private Contact upsertContact(BI_TA_SyncInfo bookingInfo ,Lead__c firstLead) {
mLogUtils.write_method_start('upsertContact');
		String applicantName = bookingInfo.Member != null ? bookingInfo.Member.UserName : null;     // 申込者
        String applicantPhone = bookingInfo.Member != null ? bookingInfo.Member.UserTel : null;     // 申込者電話
        Contact curContact = null;
        // 宿泊者リスト初期化
        //contactsLst = new List<Contact>();
        // 代表者情報は取得取得処理を行う
        String primaryUsr = bookingInfo.basic.GuestOrGroupNameKanjiName;
        String primaryUsrKana = bookingInfo.basic.GuestOrGroupNameSingleByte;
        // ユーザー情報が未設定する場合、仮ユーザ情報を自動設定を行う
        if (CommUtils.isBlank(primaryUsr) && Commutils.isBlank(primaryUsrKana)) {
            return CommLogicProcess.getOrInsertTempContact();
        } 
        //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH BEGIN
        Boolean isChgExistUserFlg = false;
        //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH END
mLogUtils.write_log('primaryUsr=' + primaryUsr);
mLogUtils.write_log('primaryUsrKana=' + primaryUsrKana);
		// 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ BEGIN
        boolean conAlwaysNewFlg = TA_ServiceConfigHelp.getAppConfig(shopCd).contactAlwaysNew;
        // XMLタグがTRUEかつ新規予約の場合、お客様情報は常に新規作成する
        conAlwaysNewFlg = conAlwaysNewFlg && (bookingInfo.dmlAction == BI_TA_DmlAction.INS);
        // 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ END
        if(bookingInfo.dmlAction == BI_TA_DmlAction.UPD && firstLead != null){
        	String contactId = firstLead.Relcontact__c;
        	list<Contact> existCList = [select LastName,FirstName,Name1__c,KanaName1__c,Katakana__c,Phone,Email,MailingPostalCode,MailingStreet,
        	//2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH BEGIN
        	//Phone2__c抽出項目を追加する
        							ApplicantName__c,ApplicantPhone__c,Birthdate,MobilePhone,Phone2__c from Contact where id = :contactId];
        	//2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH END
            if(!existCList.isEmpty()) {
	    		/*
	    		// 2016/03/28 誕生日と携帯電話情報解析と取込 BEGIN
            	Boolean isChange = false;
				if(birthDay != null && existCList[0].Birthdate != birthDay){
					existCList[0].Birthdate = birthDay;
					isChange = true;
				}
				if(!CommUtils.isBlank(moibelPhone) && existCList[0].MobilePhone != moibelPhone){
					existCList[0].MobilePhone = moibelPhone;
					isChange = true;
				}
				if (isChange) update existCList[0];
				*/
            	// 2016/03/28 誕生日と携帯電話情報解析と取込 END
	            //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH BEGIN 
	            //return existCList[0];
	            // 該当データは変更通知の既存ユーザーありを識別する
	            isChgExistUserFlg = true;
	            //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH END
            }
        }
mLogUtils.write_log('upsertContact');
        // 団体名または代表者氏名 漢字
        Map<String, Contact> contactMap = new Map<String, Contact>();
        // 団体名または代表者氏名(半角)
        Map<String, Contact> kanaNmMap = new Map<String, Contact>();

        // 個々の部屋とお客様リスト
        for (BI_TA_RoomAndGuestInfo roomAndGuest: bookingInfo.roomAndGuestLst) {
        	// お客様情報リスト
            for (BI_TA_GuestInformation guest : roomAndGuest.guestInfoLst) {
                // お客様情報リスト
                String contactNm = guest.GuestKanjiName;
                String contactKana = guest.GuestNameSingleByte;
                // すでに存在している情報はSKIPする
                if (contactMap.containsKey(contactNm) || kanaNmMap.containsKey(contactKana)) continue;
                // 新規存在の顧客情報を設定する
                Contact contactItem = new Contact();
                String splitName = CommUtils.isBlank(contactNm) ? contactKana : contactNm;
                String[] contactNameArr = CommUtils.splitName(splitName);
                String lastName = contactNameArr[0];
                String firstName = (contactNameArr.size() > 1 ? contactNameArr[1] : null);
                contactItem.LastName = lastName;
                contactItem.FirstName = firstName;
                // 漢字
                contactItem.Name1__c = guest.GuestKanjiName;
                // カナ
                contactItem.KanaName1__c = guest.GuestNameSingleByte;
                // ひらがな
                contactItem.Katakana__c = guest.GuestSurName;
                // Phone
                //contactItem.Phone = guest.GuestPhoneNumber;
                String locPhone = CommUtils.convTelphoneNumber(guest.GuestPhoneNumber);
                if (!CommUtils.isBlank(locPhone)) contactItem.Phone = guest.GuestPhoneNumber;
                // 緊急連絡先
                //contactItem.Phone2__c = guest.GuestEmergencyPhoneNumber;
                locPhone = CommUtils.convTelphoneNumber(guest.GuestEmergencyPhoneNumber);
                if (!CommUtils.isBlank(locPhone)) contactItem.Phone2__c = guest.GuestEmergencyPhoneNumber;
                // お客様Email
                contactItem.Email = guest.GuestEmail;
                // お客様住所都道府県
                if (!CommUtils.isBlank(guest.GuestStateProvidence)) {
                	List<String> addressLst = CommUtils.parseJapanAddress(guest.GuestStateProvidence);
mLogUtils.write_log('住所解析結果：'+addressLst);
                	if (addressLst.size() == 3) {
                		contactItem.MailingState = addressLst[0];
                		contactItem.MailingCity = addressLst[1];
                		contactItem.MailingStreet = addressLst[2];
                	} else {
                		contactItem.MailingStreet = addressLst[0];
                	}
                }
                // お客様住所郵便番号
                contactItem.MailingPostalCode = guest.GuestPostalCode;
                // MAPに、顧客上はMAPに格納する
                if (!CommUtils.isBlank(contactNm)) contactMap.put(contactNm, contactItem);
                // MAPに、顧客KANAはMAPに格納する
                if (!CommUtils.isBlank(contactKana)) kanaNmMap.put(contactKana, contactItem);           
            }
        }
    
        String phoneNumber = null;
        // お客様情報リストから宿泊ユーザー詳細情報をある場合
        if (contactMap.containsKey(primaryUsr) || kanaNmMap.containskey(primaryUsrKana)) {
        	// お客様情報リストから設定情報を取得する
            curContact = contactMap.containsKey(primaryUsr) 
                        ? contactMap.get(primaryUsr)
                        : kanaNmMap.get(primaryUsrKana);
        } else if(bookingInfo.Member.UserName == primaryUsr || bookingInfo.Member.UserKana == primaryUsrKana) {
    		//phoneNumber = bookingInfo.Member.UserTel;
    		BI_TA_Member member = bookingInfo.Member;
			// お客様情報リスト
            String contactNm = member.UserName;
            String contactKana = member.UserKana;

			// 新規存在の顧客情報を設定する
			curContact = new Contact();
                
			String[] contactNameArr = CommUtils.splitName(CommUtils.isBlank(contactNm) ? 
															contactKana : contactNm );
			String lastName = contactNameArr[0];
			String firstName = (contactNameArr.size() > 1 ? contactNameArr[1] : null);
			curContact.LastName = lastName;
			curContact.FirstName = firstName;
	        // 漢字
	        curContact.Name1__c = contactNm;
	        // カナ
	        curContact.KanaName1__c = contactKana;
	        // Phone:予約者・会員電話番号
	        curContact.Phone = member.UserTel;
	        // お客様Email:予約者・会員Email
	        curContact.Email = member.UserMailAddr;
	        
	        // UserAddr
	        // お客様住所都道府県
	        if (!CommUtils.isBlank(member.UserAddr)) {
	        	List<String> addressLst = CommUtils.parseJapanAddress(member.UserAddr);
	        	if (addressLst.size() == 3) {
	        		curContact.MailingState = addressLst[0];
	        		curContact.MailingCity = addressLst[1];
	        		curContact.MailingStreet = addressLst[2];
	        	} else {
	        		curContact.MailingStreet = addressLst[0];
	        	}
	        }   
        }
        // お客様情報が存在する場合
        if (curContact != null) {
        	if (curContact.firstName == '_' || curContact.firstName == '!') curContact.firstName = '';
        	// 予約者は宿泊者と同じ人の場合、ZIP番号を設定する
            // POSTNOを設定する
            if(bookingInfo.Member.UserName == primaryUsr || bookingInfo.Member.UserKana == primaryUsrKana) {
        		// 予約者・会員郵便番号
	       		curContact.MailingPostalCode = bookingInfo.member.UserZip;
        	}
        	// 電話番号設定
        	phoneNumber = curContact.Phone;
        } else {
        	curContact = new CONTACT();
        	// 該当ユーザー情報は代表者に対して、新規ユーザーを作成する
        	String locPrimaryUsr = CommUtils.isBlank(primaryUsr) ? primaryUsrKana : primaryUsr;
			String[] contactNameArr = CommUtils.splitName(locPrimaryUsr);
            // 団体名または代表者氏名(半角)
            curContact.LastName =  contactNameArr[0];
            curContact.FirstName = (contactNameArr.size()>1?contactNameArr[1]:'');
            // 団体名または代表者氏名 漢字
            curContact.Name1__c = primaryUsr;
            // 団体名または代表者氏名よみがな(全角)
            curContact.KanaName1__c = primaryUsrKana;
            // ひらがな ←　団体名または代表者氏名よみがな(全角)
            curContact.Katakana__c = bookingInfo.basic.GuestOrGroupNameDoubleByte;
        }
        // 2016/05/25 お客様電文番号は[--]の場合、エラー回避
        phoneNumber = CommUtils.convTelphoneNumber(phoneNumber);
        // 電話番号と
        // 2017/12/14 SOSLキーチェック追加対応 BEGIN
        //if (!CommUtils.isBlank(phoneNumber)) {
        //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH BEGIN 
        list<Contact> existCList = null;
        String kajiname = CommUtils.nullToblank(bookingInfo.basic.GuestOrGroupNameKanjiName);
        String kanaName = CommUtils.nullToblank(bookingInfo.basic.GuestOrGroupNameSingleByte);
        String kanaKana = CommUtils.nullToblank(bookingInfo.basic.GuestOrGroupNameDoubleByte);
        // 変更通知以外の場合、関連お客様情報を検索する、変更の場合、再度検索が不要
	// 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ BEGIN
	if (!conAlwaysNewFlg) {
	// 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ END
        if (!isChgExistUserFlg) {
        //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH END 
	        if (CommUtils.isValidateSoslKey(phoneNumber)) {
	        // 2017/12/14 SOSLキーチェック追加対応 END
	            String fullName = (curContact.lastName + ' ' + CommUtils.nullToBlank(curContact.firstName)).trim();   
	            //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH END       
	            //String kajiname = CommUtils.nullToblank(bookingInfo.basic.GuestOrGroupNameKanjiName);
	            //String kanaName = CommUtils.nullToblank(bookingInfo.basic.GuestOrGroupNameSingleByte);
	            //String kanaKana = CommUtils.nullToblank(bookingInfo.basic.GuestOrGroupNameDoubleByte);
				// Name1__c,KanaName1__c,Katakana__c,Email,Phone,Phone2__c,MailingPostalCode 取得項目を追加する
	            String soslQuery = 'FIND :phoneNumber IN PHONE FIELDS RETURNING CONTACT (id, name,Name1__c,KanaName1__c,Katakana__c,Email,Phone,Phone2__c,MailingPostalCode where Name = :fullName ';
	            //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH END
	            if (!CommUtils.isBlank(kanaName)) soslQuery += ' OR KanaName1__c =:kanaName ';
	            if (!CommUtils.isBlank(kajiname)) soslQuery += ' OR Name1__c = :kajiname ';
	            if (!CommUtils.isBlank(kanaKana)) soslQuery += ' OR Katakana__c = :kanaKana ';
	            soslQuery += ' limit 1) ';
	            List<List<Sobject>> existRs = search.query(soslQuery);
            //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH BEGIN
	            //list<Contact> existCList = existRs[0]; 
	            existCList = existRs[0]; 
	        }
		}
        mLogUtils.write_log('既存お客様:' + existCList );
		if (existCList != null && !existCList.isEmpty()) {
            existCList[0].ApplicantName__c = applicantName;
            existCList[0].ApplicantPhone__c = applicantPhone;
            //mLogUtils.write_log('：：：：：：：：：：：：：：：：申込者:::::::::::::::::' );
            //2016/05/24  お客様重複チェック対応 BEGIN
            //update existCList[0];
            //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH BEGIN 
            if (CommUtils.isBlank(curContact.Name1__c)) curContact.Name1__c = kajiname;
            if (CommUtils.isBlank(curContact.KanaName1__c)) curContact.KanaName1__c = kanaName;
            if (CommUtils.isBlank(curContact.Katakana__c)) curContact.Katakana__c = kanaKana;
			
            // 団体名または代表者氏名 漢字
            if(CommUtils.isBlank(existCList[0].Name1__c) && !CommUtils.isBlank(curContact.Name1__c))
                existCList[0].Name1__c = curContact.Name1__c;
            // 団体名または代表者氏名よみがな(半角)
            if(CommUtils.isBlank(existCList[0].KanaName1__c) && !CommUtils.isBlank(curContact.KanaName1__c))
                existCList[0].KanaName1__c = curContact.KanaName1__c;
            // ひらがな ←　団体名または代表者氏名よみか゛な(全角)
            if(CommUtils.isBlank(existCList[0].Katakana__c) && !CommUtils.isBlank(curContact.Katakana__c))
                existCList[0].Katakana__c = curContact.Katakana__c;
            // メール
            if(CommUtils.isBlank(existCList[0].Email) && !CommUtils.isBlank(curContact.Email))
                existCList[0].Email = curContact.Email;
            // 郵便番号
            if(CommUtils.isBlank(existCList[0].MailingPostalCode) && !CommUtils.isBlank(curContact.MailingPostalCode))
                existCList[0].MailingPostalCode = curContact.MailingPostalCode;
            // Phone
            if(CommUtils.isBlank(existCList[0].Phone) && !CommUtils.isBlank(curContact.Phone))
                existCList[0].Phone = curContact.Phone;
            // 緊急連絡先
            if(CommUtils.isBlank(existCList[0].Phone2__c) && !CommUtils.isBlank(curContact.Phone2__c))
                existCList[0].Phone2__c = curContact.Phone2__c;
            //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH END 
            existCList[0] = (new CommLogicProcess()).upsertDuplicateErrorProcess(existCList[0], mLogUtils);
            //2016/05/24  お客様重複チェック対応 END
            mLogUtils.write_method_end();
            return existCList[0];     
		}  
	// 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ BEGIN
	}
	// 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ END  			
        if (curContact != null) {
        	// 申込者
            curContact.ApplicantName__c = applicantName;
            // 申込者電話番号
            curContact.ApplicantPhone__c = applicantPhone;
	        // 非存在する場合（あり得ない）
	        //2016/05/24  お客様重複チェック対応 BEGIN
	        //insert curContact;  
	        //mLogUtils.write_log('お客様新規作成::' + curContact.id);
	        // 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ BEGIN
			if (!conAlwaysNewFlg) {
			// 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ END
		        curContact = (new CommLogicProcess()).upsertDuplicateErrorProcess(curContact, mLogUtils);
			// 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ BEGIN
			} else {
				(new CommLogicProcess()).forceUpdate(curContact, mLogUtils);
			}
			// 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ END
	        // 2016/05/24 お客様重複チェック対応 END
        }     
        mLogUtils.write_method_end();
        return curContact;
    }
    
    /*
     * 旅行会社情報はSFへ登録を行う
     * 会社・営業所が存在する場合、営業所も一緒に戻る
     */
    private List<Account> upsertTravelInfo (BI_TA_SyncInfo bookingInfo) {
        mLogUtils.write_method_start('upsertTravelInfo');
        // 旅行会社名と同じ取引先が存在するかどうかチェックを行う
        Account travelCompany = null;
        // 旅行会社存在する場合
        if (!CommUtils.isBlank(bookingInfo.salesOffice.SalesOfficeCompanyCode) ) {
	        // 2016/07/14 取引先名はNULLの場合、取引先コードで名に設定する BEGIN
	        if (CommUtils.isBlank(bookingInfo.salesOffice.SalesOfficeCompanyName)) {
	        	bookingInfo.salesOffice.SalesOfficeCompanyName = bookingInfo.salesOffice.SalesOfficeCompanyCode;
	        }
	        // 2016/07/14 取引先名はNULLの場合、取引先コードで名に設定する END
            List<Account> travelCompanyLst = [select id , name from Account
                where AccountType__c = :CommConst.ACCOUNT_TYPE_TRAVEL
                and SalesOfficeCompanyCodeTA__c = :bookingInfo.salesOffice.SalesOfficeCompanyCode 
                limit 1];
            if (travelCompanyLst.isEmpty()) {
                    travelCompany = new Account();
                    travelCompany.Name = bookingInfo.salesOffice.SalesOfficeCompanyName;
                    //travelCompany.SalesOfficeCompanyCode__c = bookingInfo.salesOffice.SalesOfficeCompanyCode;
                    travelCompany.AccountType__c = CommConst.ACCOUNT_TYPE_TRAVEL;
                    travelCompany.SalesOfficeCompanyCodeTA__c = bookingInfo.salesOffice.SalesOfficeCompanyCode;
                    travelCompany.SalesOfficeCompanyCodeTAAPI__c = bookingInfo.salesOffice.SalesOfficeCompanyCode;
                    insert travelCompany;
            } else {
                travelCompany = travelCompanyLst[0];
            }           
            mLogUtils.write_log('旅行会社AGT['+(travelCompanyLst.isEmpty() ? '新規':'既存')+']' + travelCompany);
        }
       
        Account traveOffice = null;
        // 旅行会社（営業所）の取得方式変更（「営業所コード」と「取引先ID」で合わせて取得する）BEGIN
        if (!CommUtils.isBlank(bookingInfo.salesOffice.SalesOfficeCode)) {
            // 取引先IDと営業所コードで存在チェックを行う
            List<Account> traveOfficeLst = [select id , name, ParentId,SalesOfficeCodeTA__c from Account
                where AccountType__c = :CommConst.ACCOUNT_TYPE_TRAVEL
                and ParentId = :travelCompany.Id
                and SalesOfficeCodeTA__c = :bookingInfo.salesOffice.SalesOfficeCode
                limit 1];
            if (!traveOfficeLst.isEmpty()) {
                traveOffice = traveOfficeLst[0];
                mLogUtils.write_log('旅行会社-支店既存取得::' + traveOffice.id);
            }
        }
        // 旅行会社（営業所）の取得方式変更（「営業所コード」と「取引先ID」で合わせて取得する）END
        // 旅行会社営業所情報が存在する場合
        if (traveOffice == null &&
            !CommUtils.isBlank(bookingInfo.salesOffice.SalesOfficeCode) &&
            !CommUtils.isBlank(bookingInfo.salesOffice.SalesOfficeName) ) {
        	// 旅行会社営業所情報新規作成
            traveOffice = new Account();
            traveOffice.Name = bookingInfo.salesOffice.SalesOfficeName;
            traveOffice.AccountType__c = CommConst.ACCOUNT_TYPE_TRAVEL;
            //traveOffice.SalesOfficeCode__c = bookingInfo.salesOffice.SalesOfficeCode;
            // 旅行会社（営業所）の取得方式変更（「営業所コード」と「取引先ID」で合わせて取得する）BEGIN
            traveOffice.SalesOfficeCodeTA__c = bookingInfo.salesOffice.SalesOfficeCode;
            // 旅行会社（営業所）の取得方式変更（「営業所コード」と「取引先ID」で合わせて取得する）END
            traveOffice.ParentId = (travelCompany != null ? travelCompany.Id : null);
            traveOffice.Phone = bookingInfo.salesOffice.SalesOfficePhoneNumber;
            insert traveOffice;
            mLogUtils.write_log('旅行会社-支店新規作成::' + traveOffice.id);
        }

        // 担当者->取引先責任者に設定を行う
        // 取引担当者が存在する場合、担当者として、登録する
        if ((travelCompany != null || traveOffice != null) &&
            !CommUtils.isBlank(bookingInfo.salesOffice.SalesOfficePersonInCharge) &&
            !CommUtils.isBlank(bookingInfo.salesOffice.SalesOfficePhoneNumber) ) {
            // 同じ氏名と電話の担当者存在チェックを行う
            List<Contact> contactLst = [select id, name from Contact where LastName = :bookingInfo.salesOffice.SalesOfficePersonInCharge and phone = :bookingInfo.salesOffice.SalesOfficePhoneNumber];
            if (contactLst.isEmpty()) {
                Contact newContact = new Contact();
                newContact.LastName = bookingInfo.salesOffice.SalesOfficePersonInCharge;
                newContact.phone = bookingInfo.salesOffice.SalesOfficePhoneNumber;
                newContact.AccountId = (traveOffice == null ? travelCompany.Id : traveOffice.Id);
                //insert newContact;
                (new CommLogicProcess()).upsertDuplicateErrorProcess(newContact, mLogUtils);
                mLogUtils.write_log('旅行会社関連担当者情報作成::'+newContact.Id);
            }
        }
        List<Account> rsAccountLst = new List<Account>();  
        if (travelCompany != null) rsAccountLst.add(travelCompany);
        if (traveOffice != null) rsAccountLst.add(traveOffice);
        mLogUtils.write_method_end();  
        return rsAccountLst;    
    }
    
    // メール本文情報を設定する
    private String mailArea(BI_TA_SyncInfo bookingInfo){
    	mLogUtils.write_method_start('メール本文作成');
    	// メール本文情報を格納
        String mailString = '';
        // 代表者情報
        String roomMsg = '';
        // 宿泊者情報
        String guestMsg = '';

        // 団体名または代表者氏名 漢字
        set<String> contactFilterSet = new set<String>();
        // 団体名または代表者氏名(半角)
        set<String> kanaNmFilterSet = new set<String>();
		// 宿泊者情報リスト     
        for (BI_TA_RoomAndGuestInfo roomAndGuest: bookingInfo.roomAndGuestLst) {
        	// お客様情報リスト
            for (BI_TA_GuestInformation guest : roomAndGuest.guestInfoLst) {
            	guestMsg += '\n';    
                // お客様情報リスト
                String contactNm = guest.GuestKanjiName;
                String contactKana = guest.GuestNameSingleByte;
                
                if (contactFilterSet.contains(contactNm) || kanaNmFilterSet.contains(contactKana)) continue;
                if (!CommUtils.isBlank(contactNm)) contactFilterSet.add(contactNm);
                if (!CommUtils.isBlank(contactKana)) kanaNmFilterSet.add(contactKana);
                // 新規存在の顧客情報を設定する
                Contact contactItem = new Contact();
                String splitName = CommUtils.isBlank(contactNm) ? contactKana : contactNm;
                // 
            	guestMsg += splitName + ( CommUtils.isBlank(contactKana) ? '' : '(' + contactKana + ')' );
            	// メール
            	if (!CommUtils.isBlank(guest.GuestEmail)) guestMsg += '\nMail: ' + guest.GuestEmail;
           		// 住所情報
           		if (!CommUtils.isBlank(guest.GuestStateProvidence)) {
	                guestMsg += '\n住所: ';
	                if (!CommUtils.isBlank(guest.GuestPostalCode)) guestMsg += '(〒'+guest.GuestPostalCode+')';
	                guestMsg += guest.GuestStateProvidence;
           		}
	            // 電話番号、緊急連絡先、
	            guestMsg += '\n';
	            //if (!CommUtils.isBlank(c.gender__c)) guestMsg += ' 性別: ' + c.gender__c;
	            if (!CommUtils.isBlank(guest.GuestPhoneNumber)) guestMsg += ' 電話: ' + guest.GuestPhoneNumber;
	            if (!CommUtils.isBlank(guest.GuestEmergencyPhoneNumber)) guestMsg += ' 緊急連絡先: ' + guest.GuestEmergencyPhoneNumber;
            }
        }
        // XML部屋と料金情報を取得する
        for(BI_TA_RoomAndGuestInfo roomGuestInfo : bookingInfo.roomAndGuestLst){
            // RoomInformation[部屋タイプ定義情報]
            BI_TA_RoomInformation roomInfo = roomGuestInfo.roomI;
//mLogUtils.write_log('部屋設定料金情報を取得する::');            
            // 部屋設定料金情報を取得する
            for(BI_TA_RoomRateInformation roomRate : roomGuestInfo.roomRateLst){
                roomMsg += '\n';
                // 2017/02/21 RoomRate部分为空、取込エラー FIX by zh BEGIN
                /*roomMsg += (DateTime.newInstance(roomRate.RoomDate.year(), roomRate.RoomDate.month(), roomRate.RoomDate.day()).format('yyyy年MM月dd日'))  + 
	                            ' ' + roomInfo.RoomTypeCode + ( CommUtils.isBlank(roomInfo.RoomTypeName) ? ' ' : ' (' + roomInfo.RoomTypeName +') ') + 
	                            '@' + CommUtils.nullToBlank(roomRate.TotalPerRoomRate);*/
				if(roomRate.RoomDate != null){ 
	                roomMsg += (DateTime.newInstance(roomRate.RoomDate.year(), roomRate.RoomDate.month(), roomRate.RoomDate.day()).format('yyyy年MM月dd日')); 
				}
				roomMsg += ' ' + roomInfo.RoomTypeCode + ( CommUtils.isBlank(roomInfo.RoomTypeName) ? ' ' : ' (' + roomInfo.RoomTypeName +') ') + 
	                            '@' + CommUtils.nullToBlank(roomRate.TotalPerRoomRate);
                // 2017/02/21 RoomRate部分为空、取込エラー FIX by zh END	
                if(roomInfo.RoomPaxMaleCount > 0 ){
                    roomMsg += '\n大人（男） ' + roomInfo.RoomPaxMaleCount + '名';
                }
                if(roomInfo.RoomPaxFemaleCount > 0 ){
                    roomMsg += '\n大人（女） ' + roomInfo.RoomPaxFemaleCount + '名';
                }
                // 子供人数
                Integer childCount = CommUtils.nullToZero(roomInfo.RoomChildA70Count) + 
                                     CommUtils.nullToZero(roomInfo.RoomChildB50Count) +
                                     CommUtils.nullToZero(roomInfo.RoomChildC30Count) + 
                                     CommUtils.nullToZero(roomInfo.RoomChildDNoneCount) +
                                     CommUtils.nullToZero(roomInfo.RoomChildOtherCount);
                if(childCount > 0 ) roomMsg += '\n子供 　　　' + childCount + '名';
            }
        }
        //roomMsg += '\n\n 宿泊料金計: ¥' + bookingInfo.basicRate.TotalAccommodationCharge + '\n';
//mLogUtils.write_log('料金区分::');
        // 料金区分
        String payUnitString = bookingInfo.basicRate.RoomRateOrPersonalRate;
        if (!CommUtils.isBlank(bookingInfo.basicRate.RoomRateOrPersonalRate)) {
            if (bookingInfo.basicRate.RoomRateOrPersonalRate == 'RoomRate') payUnitString = '室単価';
            else if (bookingInfo.basicRate.RoomRateOrPersonalRate == 'PersonalRate') payUnitString = '人員単価';
        }
//mLogUtils.write_log('税サ区分::');
        // 税サ区分
        String taxKbnString = '';
        if (!CommUtils.isBlank(bookingInfo.basicRate.TaxServiceFee)) {
            Integer taxKbn = CommUtils.nullToIntZero(bookingInfo.basicRate.TaxServiceFee);
//System.debug(LoggingLevel.INFO, 'tax::::::::::::::::::::::::::::::::::::::::::::' + taxKbn);
            if 		(taxKbn == CommConst.APPOPTION_UTP_DEF_KB_OP2)	taxKbnString =   ' サ込税込';
            else if (taxKbn == CommConst.APPOPTION_UTP_DEF_KB_OP3) 	taxKbnString =   ' サ別税別';
            else if (taxKbn == CommConst.APPOPTION_UTP_DEF_KB_OP4)	taxKbnString =   ' サ込税別';
            else if (taxKbn == CommConst.APPOPTION_UTP_DEF_KB_OP1)	taxKbnString =   ' サ別税込';
        }
//mLogUtils.write_log('料金区分連携項目を追加::');
		// 2014/12/01 料金区分連携項目を追加
		roomMsg += '\n\n';
		roomMsg += '料金区分: ' + payUnitString + '\n';
		roomMsg += '税サ区分: ' + taxKbnString + '\n';
		roomMsg += '支払い方法: ' + getLocalPaymentInfo(bookingInfo.basicRate.Payment) + '\n';
		roomMsg += '宿泊料金計: ' + '¥' + bookingInfo.basicRate.TotalAccommodationCharge + '\n';
        if (bookingInfo.member != null ) {
            BI_TA_Member member = bookingInfo.member;
            roomMsg += '\n';
            if (!CommUtils.isBLank(member.UserGivinPoints)) roomMsg += '\n 【付与ポイント】： ' + member.UserGivinPoints;
            if (!CommUtils.isBLank(member.UserUsePoints)) roomMsg += '\n 【使用ポイント】： ' + member.UserUsePoints;
            if (member.AmountClaimed != null && member.AmountClaimed > 0) roomMsg += '\n 【宿泊者への請求額】： ¥' + member.AmountClaimed;
        }
        mailString +=   '予約通知： '+ bookingInfo.salesOffice.SalesOfficeCompanyName;
        mailString +=   '\n' + '予約番号： ' + bookingInfo.basic.TravelAgencyBookingNumber;
mLogUtils.write_log('施設情報::');        
        //-------------------施設情報----------------------
        if(!CommUtils.isBlank(bookingInfo.accommodation.AccommodationName))
        mailString +=   ' ' + bookingInfo.accommodation.AccommodationName +'様'+ ( CommUtils.isBlank(bookingInfo.accommodation.AccommodationCode) == true ? '' : '(' + bookingInfo.accommodation.AccommodationCode + ')' );
        
        mailString +=   '\n';
mLogUtils.write_log('宿泊者情報::');
        //-------------------宿泊者情報----------------------
        mailString +=   '\n' + '宿泊者情報：';
        mailString +=   guestMsg;
        
        mailString +=   '\n';
mLogUtils.write_log('予約者情報::');
		//-------------------予約者情報----------------------
		if (bookingInfo.member != null ) {
			BI_TA_Member member = bookingInfo.member;
			mailString += 	'\n' + '予約者情報：';
			if (!CommUtils.isBlank(member.UserName)) mailString += 	'\n' + member.UserName;
			if (!CommUtils.isBlank(member.UserKana)) mailString += 	'\n' + member.UserKana;
			if (!CommUtils.isBlank(member.UserCorp)) mailString += 	'\n' + '会社：'+member.UserCorp;
			if (!CommUtils.isBlank(member.UserTel)) mailString += 	'\n' + 'Tel：'+member.UserTel;
			if (!CommUtils.isBlank(member.UserMailAddr)) mailString += 	'\n' + 'Mail：'+member.UserMailAddr;
mLogUtils.write_log('予約者情報:[MAIL]:'+member.UserMailAddr);
mLogUtils.write_log('予約者情報:[ADDR]:'+member.UserAddr);
			if (!CommUtils.isBlank(member.UserAddr)) {
                mailString += '\n住所：';
                if (!CommUtils.isBlank(member.UserZip)) mailString += '(〒'+member.UserZip+')';
                mailString += member.UserAddr; 
            }
		}
        //-------------------プラン情報----------------------
        mailString +=   '\n';
        mailString +=   '\n' + 'プラン名：' + bookingInfo.basic.PackagePlanName + '(' + bookingInfo.basic.PackagePlanCode + ')' + '\n';
        Date ciDate = bookingInfo.basic.CheckInDate;
        mailString +=   '\n' + (DateTime.newInstance(ciDate.year(), ciDate.month(), ciDate.day())).format('yyyy年MM月dd日') + ' から' + bookingInfo.basic.Nights + '泊 ';

//System.debug(logginglevel.INFO, 'bookingInfo.basic.CheckInTime='+bookingInfo.basic.CheckInTime);
        if (bookingInfo.basic.CheckInTime != null)
		mailString +=	' チェックイン時間：' + CommUtils.nullToBlank((DateTime.newInstance(Date.today(), bookingInfo.basic.CheckInTime)).format('HH:mm'));
		//mailString += 	'\n' + '人員総数：' + bookingInfo.GrandTotalPaxCount
		//		   + 	'\n' + '客室総数：' + bookingInfo.TotalRoomCount;
		
		mailString += '\n';
		mailString += 	roomMsg
				   + '\n-------------------------------------------------';
		//-------------------ご確認事項----------------------	
        //mailString +=   '\n' + '\nご確認事項：';
		// 客室へリクエスト情報を作成する
		if (!CommUtils.isBlank(bookingInfo.basic.OtherServiceInformation)) {
			mailString += '\n' + bookingInfo.basic.OtherServiceInformation;
		}
		if (!CommUtils.isBlank(bookingInfo.basic.SpecialServiceRequest)) {
			mailString += '\n\n' + bookingInfo.basic.SpecialServiceRequest;
		}
		if(!CommUtils.isBlank(bookingInfo.salesOffice.SalesOfficeName)){
			mailString += '\n' + '取扱個所：';
			mailString += '\n' + bookingInfo.salesOffice.SalesOfficeName + '(' + bookingInfo.salesOffice.SalesOfficeCode + ')';
			if (!CommUtils.isBlank(bookingInfo.salesOffice.SalesOfficePhoneNumber)) mailString += '		TEL' + bookingInfo.salesOffice.SalesOfficePhoneNumber;
		}
//System.debug(LoggingLevel.INFO,'========>\n  '+mailString);
		mLogUtils.write_method_end();  
        return mailString;
    }

    // 支払方法転換
    private static string getLocalPaymentInfo (String mediaType) {
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
        String accountCd = TA_ServiceConfigHelp.getAccountConfig(shopCd).serviceCd;
        if (CommUtils.isBlank(accountCd)) return new AccountMaster__c();
        List<AccountMaster__c> acc = [select Name,Id,TaxRateCal__c,ServiceRate__c  from AccountMaster__c where Field3__c = :accountCd  limit 1];
        if(acc.isEmpty()) return new AccountMaster__c();
        return acc[0];
    }
    
    // 入湯税商品
    private AccountMaster__c getNyuuTouAcc(){
        String accountCd = TA_ServiceConfigHelp.getAccountConfig(shopCd).nyuuTouCd;
        if (CommUtils.isBlank(accountCd)) return new AccountMaster__c();
        List<AccountMaster__c> acc = [select Name,Id,Field5__c,TaxRateCal__c,ServiceRate__c  from AccountMaster__c where Field3__c = :accountCd  limit 1];
        if(acc.isEmpty()) return new AccountMaster__c();
        return acc[0];
    }
    
    private String setUpdateContent(LeadIndex__c leadIndex , BI_TA_SyncInfo bookingInfo){
        List<Attachment> rsAtt = [select Name,Body,ParentId from attachment where parentId = :leadIndex.Id order by CreatedDate desc]; 
        return '';
    }
    
    // 自動割り振りできる部屋リスト情報を取得する
    // 故障部屋は自動割当て機能に追加対応 BEGIN
	 private map<Integer,Room__c> getCanAssignRoom(LeadIndex__c leadIndex, Map<String,Id> roomTypeMap, boolean autoAssingRoomflag, BI_TA_SyncInfo bookingInfo){
	 	mLogUtils.write_method_start('getCanAssignRoom');
//System.debug(loggingLevel.INFO,'-------------::::::::::::::::::::::::getCanAssignRoom----------');            
        map<Id, Id> targetRoomIdTypeMap = new map<Id, Id>();
        map<Id, List<Room__c>> wkCanAssignRoomMap = new map<Id, List<Room__c>>();
        map<Integer,Room__c> resultMap = new map<Integer, Room__c>();
 		List<Id> roomTypeIdLst = roomTypeMap.values();
//System.debug(loggingLevel.INFO,'-------------::::::::::::::::::::::::roomTypeIdLst----------' + roomTypeIdLst);
	 	String sortField = TA_ServiceConfigHelp.getAppConfig(shopCd).roomSortKey;
        String queryHead = 'select id,Name,TypeRoomRef__c from Room__c ';
        String queryWhere = ' where UseOfRoom__c = \'' + String.escapeSingleQuotes(CommConst.ROOM_UseOfType_Guest) + '\'' +
                            ' And TypeRoomRef__c in :roomTypeIdLst ';
        String queryOrder = ' Order By priority__c ' + sortField + ' NULLS LAST ';
        String queryString = queryHead + queryWhere + queryOrder;
//System.debug(loggingLevel.INFO,'-------------::::::::::::::::::::::::queryString----------' + queryString);	 	
	 	for (Room__c room : DataBase.query(queryString)) {
            // 部屋　と　部屋タイプマッピング情報を格納する
            targetRoomIdTypeMap.put(room.Id, room.TypeRoomRef__c);
            // 部屋単位の部屋情報を格納する
            if (!wkCanAssignRoomMap.containsKey(room.TypeRoomRef__c)) {
                wkCanAssignRoomMap.put(room.TypeRoomRef__c, new List<Room__c>());
            }
            wkCanAssignRoomMap.get(room.TypeRoomRef__c).add(room);
        }
    	// 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 BEGIN
    	Date wkBeginDate = leadIndex.EntryDate__c;
    	Date wkEndDate = leadIndex.DepartureDate__c;
    	Integer wkNights = bookingInfo.basic.Nights;
    	if (wkNights > 0) wkEndDate = wkEndDate.addDays(-1);
    	// 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 END
        // 有効な予約データ、一日一部屋で処理するため、重複することは処理対象外
        Set<Id> usedRoomIdSet = new Set<Id>();
        // 既に予約データに入る場合、該当部屋は選択対象外になる
        for (AggregateResult lead :  [
            select Rroom__c roomId from Lead__c
            where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
                // 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 BEGIN
                //And DAY_ONLY(convertTimezone(EntryTime__c)) >= :leadIndex.EntryDate__c
                //And DAY_ONLY(convertTimezone(EntryTime__c)) <= :leadIndex.DepartureDate__c 
                And DAY_ONLY(convertTimezone(EntryTime__c)) >= :wkBeginDate
                And DAY_ONLY(convertTimezone(EntryTime__c)) <= :wkEndDate
                // 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 END
                And Rroom__c in :targetRoomIdTypeMap.keySet()
                And LeadIndexRef__c != :leadIndex.Id
                Group By Rroom__c]) {
            usedRoomIdSet.add((Id)lead.get('roomId'));
//System.debug(loggingLevel.INFO,'-------------::::::::::::::::::::::::usedRoomIdSet----------' + usedRoomIdSet);
        }
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
//System.debug(loggingLevel.INFO,'-------------::::::::::::::::::::::::canAssignRoomMap----------' + canAssignRoomMap);	 	
	 	// アサインできる部屋はない場合、チェック処理中止
        if(canAssignRoomMap.isEmpty()) return resultMap;
	 	Integer nights = bookingInfo.basic.Nights;            // 総宿泊数
        if (nights == 0) nights = 1;
//System.debug(loggingLevel.INFO,'-------------::::::::::::::::::::::::nights----------' + nights);
	 	Integer rooms = bookingInfo.roomAndGuestLst.size();
//System.debug(loggingLevel.INFO,'-------------::::::::::::::::::::::::rooms----------' + rooms);
	 	// 部屋単位に、宿泊期間内の部屋タイプリスト一覧情報を格納する
		//map<Integer, list<string>> tmpRoomTypeListMap = new map<Integer, list<string>>();
		map<Integer, string> tmpRoomTypeMap = new map<Integer, string>();
		// 宿泊期間情報を格納する、1部屋A：1/1,1/2,1/3日は同じ部屋タイプすると、0,1,2は同じリストを格納する<1, <1/1,1/2,1/3>, 2,<1/1,1/2,1/3>>...
		map<Integer, list<date>> roomTypeDateLinkByIdxMap = new map<Integer, list<date>>();
        BI_TA_RoomAndGuestInfo[] roomAndGuest = bookingInfo.roomAndGuestLst;
    	for(Integer j = 0; j < rooms; j ++){
    		BI_TA_RoomAndGuestInfo roomAndGuestInfo = roomAndGuest[j];
    		// 該当部屋に指定の部屋タイプコード[TAの場合、１部屋１部屋タイプコード方式するため]
    		tmpRoomTypeMap.put(j,roomAndGuestInfo.roomI.RoomTypeCode);
    		// 該当部屋に利用年月日情報を格納する
    		roomTypeDateLinkByIdxMap.put(j, new list<date>());
    		// 1部屋N日単位情報
        	for(Integer i = 0; i < nights; i ++){
        		// 情報を取得IDEXを定義する
        		Integer idx = i * rooms + j;
        		// 部屋利用日（到着日)
        		if (roomAndGuestInfo.roomRateLst.size() > i) {
	            	Date stayDate = roomAndGuestInfo.roomRateLst[i].RoomDate;
	            	roomTypeDateLinkByIdxMap.get(j).add(stayDate);
        		}
        		// 2017/02/21 RoomRate部分为空、取込エラー FIX by zh BEGIN
        		else {
        			Date stayDate = bookingInfo.basic.CheckInDate.adddays(i);
        			roomTypeDateLinkByIdxMap.get(j).add(stayDate);
        		}
        		// 2017/02/21 RoomRate部分为空、取込エラー FIX by zh END
        	}
	 	}
	 	// 自動割当可能の部屋IDを格納する
	 	set<id> isAutoAssignRoomtSet = new set<Id>();
    	for (list<Room__c> canAssRooms : canAssignRoomMap.values()) {
    		for (Room__c canAssRoom : canAssRooms) {
    			isAutoAssignRoomtSet.add(canAssRoom.id);
    		}
    	}
system.debug(loggingLevel.INFO,'-------------::::::::::::::::::::::::isAutoAssignRoomtSet----------' + isAutoAssignRoomtSet);	 	
	 	// 部屋状態管理情報を取得する[故障部屋存在すると、割当対象外]
	 	RoomStatusManager roomStatusManger = new RoomStatusManager();
    	// 指定期間ないの故障部屋リストを取得する
    	List<RoomsStatus__c> roomsStatus = roomStatusManger.queryBadRoomList(leadIndex.EntryDate__c,leadIndex.DepartureDate__c ,isAutoAssignRoomtSet);
//system.debug(logginglevel.info,'=========roomsStatus' + roomsStatus);
    	// 指定部屋の故障ありの日付情報を格納する
    	Map<id,List<RoomsStatus__c>> badRoomStatusMap = new Map<id,List<RoomsStatus__c>>();
	 	for(RoomsStatus__c roomStatus : roomsStatus){
    		if(!badRoomStatusMap.containsKey(roomStatus.RoomRef__c)){
    			badRoomStatusMap.put(roomStatus.RoomRef__c,new List<RoomsStatus__c>());
    		}
    		badRoomStatusMap.get(roomStatus.RoomRef__c).add(roomStatus);
    	}
//system.debug(logginglevel.info,'=========badRoomStatusMap' + badRoomStatusMap);	 	
	 	// 部屋単位
		for(Integer j = 0; j < rooms; j ++){
			// 部屋タイプ
			String roomTypeCd = tmpRoomTypeMap.get(j);
    		// 部屋タイプリスト情報を格納する
    		Id roomTypeId = roomTypeMap.get(roomTypeCd);
    		if (roomTypeId == null) continue;
    		// 部屋タイプ関連の部屋リストを取得する
    		List<Room__c> locCanAssingRoomList = canAssignRoomMap.get(roomTypeId);
    		if (locCanAssingRoomList == null || locCanAssingRoomList.isEmpty()) continue;
			// 該当部屋は故障チェックの期間情報を取得する
			list<date> assingRangeDates = roomTypeDateLinkByIdxMap.get(j);
			// 連続期間ない場合、処理対象外
			if (assingRangeDates == null || assingRangeDates.isEmpty()) continue;
    		// 同部屋タイプ連泊の期間日付の開始と終了日付を取得する
			Date startDt = assingRangeDates[0];
			Date endDt = assingRangeDates[assingRangeDates.size()-1];
    		// 該当部屋は指定期間に、故障あり、なしチエックを行う
    		Room__c targetRoom = null;
    		for (Room__c room : locCanAssingRoomList){
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
				resultMap.put(j, targetRoom);
        	}
		}// 各部屋部屋割当
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
    private List<Lead__c> filterTLImportData(List<Lead__c> orgLst , BI_TA_SyncInfo bookingInfo,LeadIndex__c leadIndex, Set<Id> pSubLeadIds){
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
mLogUtils.write_log('dataId=' + dataId);
        // 予約番号情報を登録データが存在する場合
        for(Lead__c lead : orgLst){
            // 予約に予約番号を登録されている　かつ　該当予約番号は予約インデックスと登録の番号が一致（Tl_予約インデックス.ID)
            if(!CommUtils.isBlank(lead.BookingDataID__c) && lead.BookingDataID__c == dataId){
                filterLst.add(lead);
                filterIdSet.add(lead.id);
            }
        }
mLogUtils.write_log('filterIdSet[3]' + filterIdSet);
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
mLogUtils.write_log('filterIdSet[4]' + filterIdSet);
        // 予約情報予約番号登録なし　OR　TL発生源も登録なしの予約情報に対して、
        if(filterLst.isEmpty()){
            for(Lead__c lead : orgLst){
//mLogUtils.write_log('Lead::::' + lead);
                // 予約インデックスSUBのIDをチェックが必要
                if (!pSubLeadIds.contains(lead.LeadIndexSubId__c)) continue;
mLogUtils.write_log('SUBINDEX OK' + lead.LeadIndexSubId__c);
                long leadLong = lead.CreatedDate.getTime();
                if( (leadLong-createTimeLon) <= LEAD_CREATE_TIME_DIFF_INT){
                    filterLst.add(lead);
                    filterIdSet.add(lead.id);
                }
            }
        }
//mLogUtils.write_log('filterIdSet[5]' + filterIdSet);
        if(!filterIdSet.isEmpty()){
            for(Lead__c lead : orgLst){
mLogUtils.write_log('leadID CHECK['+lead.Id+']='+filterIdSet.contains(lead.id));	
                if(!filterIdSet.contains(lead.id)){
                    mLogUtils.write_log('関連更新対象外予約ID='+lead.id);
                }
            }
        }
        mLogUtils.write_method_end();
        return filterLst;
    }

    public class BI_TA_SyncInfo {
    //1-1 在庫からの予約通知連絡  TransactionInformation  
        public BI_TA_DmlAction dmlAction; 
        public String DataID;                           // データID    
        //public String EndFlag;                          //レコード終了フラグ
        public BI_TA_TransactionType transactionType;             //情報区分
        public BI_TA_AccommodationInformation accommodation;   //宿泊施設側情報
        public BI_TA_SalesOfficeInformation salesOffice;     //旅行会社情報
        public BI_TA_BasicInformation basic;           //旅行会社情報
        public BI_TA_BasicRateInformation basicRate;      //基本宿泊情報
        public List<BI_TA_RoomAndGuestInfo> roomAndGuestLst;     //基本情報
        public BI_TA_Member member;                    //予約者・会員情報 
        public BI_TA_SyncInfo(){
            transactionType = new BI_TA_TransactionType();
            accommodation = new BI_TA_AccommodationInformation();
            salesOffice = new BI_TA_SalesOfficeInformation();
            basic = new BI_TA_BasicInformation();
            basicRate = new BI_TA_BasicRateInformation();
            roomAndGuestLst = new List<BI_TA_RoomAndGuestInfo>();
            member = new BI_TA_Member();
        }
    }     
    
    public class BI_TA_TransactionType{
    //2-1 情報区分  TransactionType    
        public String DataFrom;            	//送り元区分                                   
        public String DataClassification;	//データ種別
        //public String DateId;				//予約単位のデータID
        public Date SystemDate;            	//システム日付       
        public Time SystemTime;            	//システム時刻  
    }
    public class BI_TA_AccommodationInformation{
     //2-3-1 宿泊施設側情報  AccommodationInformation   
        public String AccommodationName;         //宿泊施設名         
        public String AccommodationCode;         //宿泊施設コード    
    }
    public class BI_TA_SalesOfficeInformation{
    //2-3-2 旅行会社情報  SalesOfficeInformation
        public String SalesOfficeCompanyCode;             //旅行会社コード
        public String SalesOfficeCompanyName;             //旅行会社名
        public String SalesOfficeName;                    //旅行会社営業所名
        public String SalesOfficeCode;                    //旅行会社営業所コード
        public String SalesOfficePersonInCharge;          //旅行会社営業所担当者名
        public String SalesOfficePhoneNumber;             //旅行会社営業所電話番号
    }
    public class BI_TA_BasicInformation{
    //2-3-3  基本宿泊情報  BasicInformation
        public String TravelAgencyBookingNumber;        //旅行会社予約(管理)番号
        public Date TravelAgencyBookingDate;            //旅行会社予約受付日
        public Time TravelAgencyBookingTime;            //旅行会社受付時間
        public String GuestOrGroupNameSingleByte;       //団体名または代表者氏名(半角)
        public String GuestOrGroupNameDoubleByte;       //団体名または代表者氏名よみがな(全角)
        public String GuestOrGroupNameKanjiName;        //団体名または代表者氏名 漢字
        public Date CheckInDate;                        //チェックイン日
        public Time CheckInTime;                        //チェックイン時間
        public Date CheckOutDate;                       //チェックアウト日
        public Integer Nights;                          //宿泊日数
        public String PackagePlanName;                  //企画(パッケージ)名
        public String PackagePlanCode;                  //企画(パッケージ)コード
        public String SpecialServiceRequest;            //特別リクエスト
        public String OtherServiceInformation;          //一般情報
    }
    public class BI_TA_BasicRateInformation{
    //2-3-4 基本情報 BasicRateInformation
        public String RoomRateOrPersonalRate;       //料金区分
        public String TaxServiceFee;                //税サ区分
        public String Payment;                      //支払い方法
        public Decimal TotalAccommodationCharge;    //合計宿泊料金(総額)
    }   
    public class BI_TA_RoomAndGuestInfo{
    //2-3-5-1  個々の部屋とお客様情報  RoomAndGuestInformation 
        public BI_TA_RoomInformation roomI;                                 //部屋情報(1:1)
        public List<BI_TA_RoomRateInformation> roomRateLst;         //部屋料金情報(0:N)
        public List<BI_TA_GuestInformation> guestInfoLst;               //お客様情報リスト(0:N)      
        public BI_TA_RoomAndGuestInfo(){
            roomI = new BI_TA_RoomInformation();
            roomRateLst = new List<BI_TA_RoomRateInformation>();
            guestInfoLst = new List<BI_TA_GuestInformation>(); 
        }
        
    }
    public class BI_TA_RoomInformation{
    //2-3-5-1-1 部屋情報  RoomInformation
        public String RoomTypeCode;                         //部屋タイプコード  
        public String RoomTypeName;                         //部屋タイプ名    
        public Integer PerRoomPaxCount;                     //利用人数  
        public Integer RoomPaxMaleCount;                    //大人人員(男性)  
        public Integer RoomPaxFemaleCount;                  //大人人員(女性)  
        public Integer RoomChildA70Count;                   //子供A人数 
        public Integer RoomChildB50Count;                   //子供B人数 
        public Integer RoomChildC30Count;                   //子供C人数 
        public Integer RoomChildDNoneCount;                 //子供D人数 
        public Integer RoomChildOtherCount;                 //子供その他人数   
    }
    //2-3-5-1-2 部屋料金情報(0:N)
    public class BI_TA_RoomRateInformation{
        public Date RoomDate;                           //利用年月日 
        public Decimal PerPaxRate;                      //大人一人料金    
        public Decimal PerChildA70Rate;                 //子供A一人料金   
        public Decimal PerChildB50Rate;                 //子供B一人料金   
        public Decimal PerChildC30Rate;                 //子供C一人料金   
        public Decimal PerChildDRate;                   //子供D一人料金   
        public Decimal PerChildOtherRate;               //子供その他一人料金 
        public Decimal TotalPerRoomRate;                //1室あたり宿泊料金合計   

     }
     //2-3-5-1-3-1 お客様情報リスト(0:N)
     public class BI_TA_GuestInformation{
        public String GuestNameSingleByte;              //お客様氏名半角カタカナ英字(姓名)     
        public String GuestSurName;                     //お客様氏名全角ふりがな(姓)        
        public String GuestKanjiName;                   //お客様氏名全角漢字(姓名)     
        public String GuestPhoneNumber;                 //お客様電話番号       
        public String GuestEmergencyPhoneNumber;        //お客様緊急連絡先      
        public String GuestEmail;                       //お客様Email      
        public String GuestStateProvidence;             //お客様住所都道府県     
        public String GuestPostalCode;					//お客様住所郵便番号

     }
     public class BI_TA_Member{
     //2-3-6 予約者・会員情報   Member
        public String UserName;                         //予約者・会員名漢字     
        public String UserKana;                         //予約者・会員名カタカナ       
        public String UserTel;                          //予約者・会員電話番号        
        public String UserMailAddr;                     //予約者・会員Email       
        public String UserZip;                          //予約者・会員郵便番号        
        public String UserAddr;                         //予約者・会員住所      
        public String UserCorp;                         //予約者・会員会社      
        public String UserGivinPoints;                  //付与ポイント        
        public String UserUsePoints;                    //使用ポイント        
        public Integer TotalAccommodationDecleasePoints;    //ポイント割引後の総額        
        public Integer AmountClaimed;                   //宿泊者請求額    
     }

    public class BI_TA_SyncResult {
        // 処理結果
        public BI_TA_Result result;
        public Id sfdcId;
        public String message;
        public Id sfdcJobId;
        public Id sfdcDocumentParentId;
        
    }
    // 戻る結果：処理成功、処理失敗、処理中。
    public enum BI_TA_Result{OK, NG, WAIT}
    // INS:新規 / UPD:更新 / 削除：キャンセル
    public enum BI_TA_DmlAction{INS, UPD, CANCEL, CONFIRM, TEJIMA, ISSUE, OTHER }
    // 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 ZH BEGIN
	public static void convertGuestInfo(BI_TA_SyncInfo bookingInfo) {
        // 宿泊施設側情報
        // 振込銀行情報 BankList
        // 旅行会社情報
        // 基本宿泊情報
        bookingInfo.basic.GuestOrGroupNameKanjiName = CommStringUtils.convertRomanToKana(bookingInfo.basic.GuestOrGroupNameKanjiName, true);
        // オプション情報
        // 基本情報 BasicRateInformation
        // クーポン明細 0:N
        // 個々の部屋とお客様情報<1:N>
        for (BI_TA_RoomAndGuestInfo roomGuestInfo: bookingInfo.roomAndGuestLst) {
            // 部屋情報
            // 1部屋の部屋料金情報(1:N){連泊}
            // 顧客情報
            //BI_TR_GuestInfo guest = roomGuestInfo.guest;
            //if (guest != null) {
                //List<BI_TR_GuestInfo> guestInfoLst = roomGuestInfo.guestInfoLst;
                if (roomGuestInfo != null) {
                    for (BI_TA_GuestInformation guestInfo: roomGuestInfo.guestInfoLst) {
                        guestInfo.guestKanjiName = CommStringUtils.convertRomanToKana(guestInfo.guestKanjiName, true);
                    }
                }
                //guest.GuestKanjiName = CommStringUtils.convertRomanToKana(guest.GuestKanjiName, true);
            //}
        }
        // Member    
        BI_TA_Member member = bookingInfo.member;
        if (member != null) {
            member.UserName = CommStringUtils.convertRomanToKana(member.UserName, true);
        }
	}
	// 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 ZH END
}