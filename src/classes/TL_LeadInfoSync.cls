/**
* バッチ連携：外から連携する顧客情報を反映する
* TL-リンカーン機能連携
* 2015/10/08 入湯税、サビース料は見積明細の設定ロジックを変更
* 2015/10/30 故障部屋は自動割当て機能に追加対応
* 2015/12/11 予約取込機能改善（変更、キャンセル）
* 2016/01/07 予約キャンセルの場合、キャンセル内容は本文メールに反映を行う
* 2016/01/18 既存の予約情報の部屋は割当済すると、該当部屋タイプと情報は変更なしで対応する
* 2016/01/28 ネットからの取込時に予約チャネルに旅行会社名で設定する
* 2016/02/01 旅行会社（営業所）の取得方式変更（「営業所コード」と「取引先ID」で合わせて取得する）
* 2016/03/28 じゃらんAGTのポイントとクーポンをそれそのまま取り込み対応
* 2016/03/28 誕生日と携帯電話情報解析と取込
* 2016/05/12 住所分割と事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う
* 2016/06/02 新規予約情報を重複取り込み回避対応（同じ予約番号が存在すると、新規取り込みなし、XMLのみコピーする）
* 2016/06/09 取り込みの見積明細の順番は調整対応（プランは一番上、その後、会計商品コード順昇順)
* 2016/06/10 事前処理区分は０は除外から「現地払い」と認識で対応する
* 2016/06/10 子供料金プラン取り込み機能対応
* 2016/06/22 住所など読み込み拡張機能
* 2016/07/10 予約チャネル名の変換機能追加対応
* 2016/09/17 TL連携在庫調整不具合対応
* 2016/10/21 TL変更機能改善対応、予約変更の場合、予約名を上書きしない、到着日を変更すると、既に割当される部屋をクリア処理追加、項目値自動設定不具合改修
* 2016/10/26 部屋タイプと部屋が1対1の場合は故障部屋を割当される不具合改修
* 2017/01/06 男女区分により、男性、女性自動割り当てる機能対応
* 2017/01/09 メール本文親部屋のみ設定できるように改善対応
* 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修
* 2017/02/21 お子様プランの料金PRICE機能追加 
* 2017/05/09 ネット取り込み、予約変更機能改善
* 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応
* 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応
* 2017/08/15 ネット取込(TL2way)機能、変更通知（２泊→１泊に変更）が来た際に、子部屋２日目の夕食レストランの席がキャンセルできるように改善対応
* 2017/09/01 最大文字数をこえない問題回避対応
* 2017/10/09 ポイント取込はうまくと、見積明細商品名称は会計商品名またはタグ値で切替設定できるよに改善対応
* 2018/04/19 氏名変更のみケース対応
* 2018/05/09 指定AGTにより、男女不明の処理機能対応
* 2018/07/19 TL取り込みの総計人数が不正改善対応
* 2018/10/16 TL2way予約変更通知の際に、部屋タイプを自動変更できるように改善対応
* 2018/12/15 TL2way会計人数制御改善(大人人数のみ予約人数に反映する)
* 2019/03/15 (無料)小人0円が小人プランに紐付できるように改善対応
* 2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する
* 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応
* 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する
* 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善
* 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加
* 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善
* 2020/07/30 入湯税の自動入力機能について改善
* 2020/08/11 予約泊数変更＆到着日変更の場合、在庫変更履歴設定不正の不具合改修
* 2020/09/15 OTAからの予約取り込み時に「楽天ポイント」と「楽天クーポン」が分かれて取り込みできる
* 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善
**/
public with sharing class TL_LeadInfoSync {
    // 中継アプリの名
    private static final String APPNAME = CommConst.BI_PROCESS_TYPE.TL.name(); 
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
    private static Boolean oneRoomAutoAssingRoomFlg { get{ return CommDefine__c.getOrgDefaults().AdvancesReceivedChk__c; }}
    // 2015/10/01 店舗コード
    private String shopCd;
    // ログ出力機能
    public CommLogUtils mLogUtils{get; private set;}
    // 入湯税会計商品情報格納用
    private AccountMaster__c nyuuTouAcc;
    // サビース料会計商品情報格納用
    private AccountMaster__c serviceAcc;
    // 調整可能のプラン明細情報の格納
    private PlanDetailInfo gPlanDetailInf;
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
    // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
    map<id,set<string>> fieldChgHisMap = null;
    // 2017/05/09 ネット取り込み、予約変更機能改善 END
    /**
    * インスタント化
    **/
    public TL_LeadInfoSync() {
        mLogUtils = new CommLogUtils('TL_LeadInfoSync',true);
    }
    /*
    * 外部から予約データ連携機能
    */
    public BI_TL_SyncResult upsertTL2LeadInfo(BI_TL_SyncInfo bookingInfo,String shopCode) {
        mLogUtils.write_method_start('upsertTL2LeadInfo');
        // 店舗コード
        shopCd = shopCode;
        // 変更、キャンセルする場合、予約取込するがどうか判断用フラグ:TRUEの場合、取込みを行う
        Boolean ucIsSyncFlg = TL_ServiceConfigHelp.getAppConfig(shopCd).ucactisSync;
        // 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 ZH BEGIN
        if (TL_ServiceConfigHelp.getAppConfig(shopCd).romanToKanaFlag) convertGuestInfo(bookingInfo);
        // 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 ZH END
        // 2015/12/11 予約取込機能改善（変更、キャンセル） BEGIN
        LEAD_CREATE_TIME_DIFF_INT = TL_ServiceConfigHelp.getCommConfig().mLeadTimeLimit;
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
        BI_TL_SyncResult rs = new BI_TL_SyncResult();
Savepoint sp = Database.setSavepoint();
try {
        // 変更、キャンセル連携処理の場合
        if (bookingInfo.dmlAction == BI_TL_DmlAction.UPD ||
            bookingInfo.dmlAction == BI_TL_DmlAction.CANCEL) {
            // 予約管理ID[新たな予約グループが発生したときに新規発番]
            String DataID = bookingInfo.DataID;
            if(CommUtils.isBlank(DataID)){
                rs.result = BI_TL_Result.NG;
                mLogUtils.write_method_end();
                return rs;
            }
            mLogUtils.write_log('DataID::' + DataID);
            // 既存の予約インデックス情報を取得する
            List<LeadIndex__c> rslst = getExistLeadIndexByDataId(bookingInfo);
            // 既存の予約情報がない場合
            if (rslst.isEmpty()) {
                // 変更の場合、新規作成を行う
                if (bookingInfo.dmlAction == BI_TL_DmlAction.UPD) {
                    // 元の予約インデックスは何も処理を行わない
                    mLogUtils.write_log('DataIDと一致するご予約情報はSalesforceからみつかりません。元のデータが更新対象外になる');
                    
                } 
                // 次の変更後の新規処理を行う
                else if (bookingInfo.dmlAction == BI_TL_DmlAction.CANCEL) {
                    mLogUtils.write_log('DataIDと一致するご予約情報はSalesforceからみつかりません。元のデータがキャンセル対象外になる');
                    // 予約インデックスのみ作成して、XMLを格納する
                    // DataIDが非存在する場合、単に該当XMLはSalesforceにアップロードを行う
                    LeadIndex__c dumyIndex = new LeadIndex__c(ID__c = DataID,EventSource__c = bookingInfo.DataFrom,StatusLst__c = CommConst.LEAD_ST_CANCEL,APPNAME__c = APPNAME);
                    insert dumyIndex;
                    mLogUtils.write_log('該当キャンセルXMLファイルは下記予約インデックス['+dumyIndex.Id+'にアップロード済');
                    rs.sfdcId = dumyIndex.Id;
                    // キャンセルの場合、新規の予約インデックスデータのみ作成して、XMLを格納する
                    rs.result = BI_TL_Result.OK;
                    mLogUtils.write_method_end();
                    return rs;
                }
            } 
            // 既存の予約関連情報が存在する場合
            else {
                // 変更時刻を設定する
                LeadIndex__c leadIndex = rslst[0];
                // 変更時刻情報を設定を行う
                if (bookingInfo.dmlAction == BI_TL_DmlAction.UPD) {
                    leadIndex.TravelAgencyBookingUpdDateTime__c = DateTime.newInstance(bookingInfo.TravelAgencyBookingDate, bookingInfo.TravelAgencyBookingTime !=null?bookingInfo.TravelAgencyBookingTime: Time.newInstance(0,0,0,0) );
                }
                if (bookingInfo.dmlAction == BI_TL_DmlAction.CANCEL) {
                    leadIndex.TravelAgencyBookingDelDateTime__c = DateTime.newInstance(bookingInfo.TravelAgencyBookingDate, bookingInfo.TravelAgencyBookingTime !=null?bookingInfo.TravelAgencyBookingTime: Time.newInstance(0,0,0,0));
                }
                // 予約インデックスのデータ種別に更新を行う
                leadIndex.DataClassification__c = bookingInfo.dmlAction.name();
                // 変更、キャンセル連動対応の場合、予約インストールのステータスも取消を行う
                if (ucIsSyncFlg && bookingInfo.dmlAction == BI_TL_DmlAction.CANCEL) {
                    leadIndex.StatusLst__c = CommConst.LEAD_ST_CANCEL;
                }
                update leadIndex;
                // 変更、キャンセル情報を取込ない制御の場合
                if (!ucIsSyncFlg) {
                    mLogUtils.write_log('変更、キャンセルするため、予約取込処理対象外になる');
                    rs.sfdcId = rslst[0].Id;
                    rs.result = BI_TL_Result.OK;
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
                if (bookingInfo.dmlAction == BI_TL_DmlAction.CANCEL) {
        			// メール本文[7XXXXX]
        			BI_TL_RisaplBasic risaplBasic = bookingInfo.risaplsinformation.risaplsCommonInformation.risaplBasic;
                	// 同じ予約インデックスを所属する予約情報は全部キャンセルを行う
	            	// 2016/09/17 TL連携在庫調整不具合対応 BEGIN
	            	Set<Id> cancelLeadOrgIdSet = new Set<Id>();
	            	// 2016/09/17 TL連携在庫調整不具合対応 END
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
	                
	                List<Lead__c> emailUpdLeadLst = filterTLImportData(orgLeadLst,bookingInfo,leadIndex,subLeadIds);
	                for (Lead__c orgLead : emailUpdLeadLst) {
	                	orgLead.email__c = CommLogUtils.removeOverLogString(risaplBasic.TelegramData + '\n' + CommUtils.nullToBlank(orgLead.email__c),emailLength);
                    	// 2016/09/17 TL連携在庫調整不具合対応 BEGIN
                    	cancelLeadOrgIdSet.add(orgLead.id);
                    	// 2016/09/17 TL連携在庫調整不具合対応 END
	                }
                	// 2016/09/17 TL連携在庫調整不具合対応 BEGIN
                	if (!cancelLeadOrgIdSet.isEmpty() && leadIndex.StockLogicProcessFlg__c) {
				        // キャンセル前にTL経由で在庫変更履歴情報を取得する（予約情報単位）
						Map<Id,StockChangeHisotry__c> historyMap = getPreChangeHistory(cancelLeadOrgIdSet);
	                	checkChgOrgStockRoomByDmlAction(emailUpdLeadLst,new List<Lead__c>(),new BI_TL_RoomAndGuestInfo(),shopCode,bookingInfo.dmlAction,new Map<String,Id>(),historyMap);
                	}
                    // 2016/09/17 TL連携在庫調整不具合対応 END
                } else if (bookingInfo.dmlAction == BI_TL_DmlAction.UPD) {
	                 // 既存予約変更、キャンセル処理する場合、既存の予約情報を一回キャンセルを更新する
	                orgLeadLst = [  select id, ReservedStatus__c,Comment3__c,RoomGroupNo__c,EntryTime__c,LeadIndexSubId__c,LeadIndexRef__c
                							,email__c,Relcontact__c,Field2__c,EventSource__c,BookingDataID__c,Departure__c,CreatedDate 
                							,Nights__c,PlanSycnFlag__c,LeadIndexRef__r.LeadName__c,Name,refTypeOfRooms__c,Rroom__c
                							,Field348__c,SalesOfficeInfoRef__c,refTypeOfRooms__r.RoomTypeCode__c
                							// 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                							,Field4__c,Field3__c,StayPersons__c,Mans__c,Femails__c,ChildFA__c,Childs__c,ChildC__c,ChildD__c
                							// 2017/05/09 ネット取り込み、予約変更機能改善 END
                							,Field276__c
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
				        // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
				        fieldChgHisMap = TL_ServiceConfigHelp.getLeadHisotryInfo(orgLeadLst); 
//mLogUtils.write_log('fieldChgHisMap:::::' + fieldChgHisMap );
// ***************************************** DEBUG ********************//
						for (String key : fieldChgHisMap.keyset()) {
							mLogUtils.write_log('項目変更履歴===========[' + key + ']===========' + key );
							for (String str : fieldChgHisMap.get(key)) {
								mLogUtils.write_log('項目変更時刻[' + str + ']' );
							}
						}
// ***************************************** DEBUG ********************//
				        // 2017/05/09 ネット取り込み、予約変更機能改善 END
				}
                //mLogUtils.write_log('orgLeadLst::' + orgLeadLst.size());
                // 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ BEGIN
                boolean chgRoomTypeFlag = TL_ServiceConfigHelp.getAppConfig(shopCd).chgRoomTypeFlag;
                // 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ END
                // アクセス権限制限するため、キャンセル処理する場合、削除から更新に変更する
                for (Lead__c lead : orgLeadLst) {
                    // 2015/10/15 Ver15.71以後、予約変更処理ロジック対応するため、下記設定ロジックを変更する BEGIN
                    String cancelMessage = '<br/>' + System.now().format('yyyy/MM/dd HH:mm:ss:SSS')+' ';
                    if (bookingInfo.dmlAction == BI_TL_DmlAction.CANCEL) {
                    	//キャンセル対応
                        cancelMessage += Label.CONST_038_0002;
                        lead.EventSource__c = APPNAME + '_' + bookingInfo.DataID + '_' + DateTime.now().getTime();
                        lead.ReservedStatus__c = CommConst.LEAD_ST_CANCEL;
                    } else if (bookingInfo.dmlAction == BI_TL_DmlAction.UPD) {
                    	//予約変更対応
                        cancelMessage += Label.CONST_038_0003;
				        // 2018/04/19 氏名変更のみケース対応 BEGIN
				        if (bookingInfo.isUpdForName) {
				            // メール本文に変更内容を設定する
				            BI_TL_RisaplBasic risaplBasic = bookingInfo.risaplsinformation.risaplsCommonInformation.risaplBasic;
				            lead.email__c = CommLogUtils.removeOverLogString(risaplBasic.TelegramData + '\n\n' + CommUtils.nullToBlank(lead.email__c),emailLength);
				        }
				        // 2018/04/19 氏名変更のみケース対応 END 
                    }
                    // 2015/10/15 Ver15.71以後、予約変更処理ロジック対応するため、下記設定ロジックを変更する END
                    // 2017/09/01 最大文字数をこえない問題回避対応 BEGIN
                    //lead.Comment3__c = CommUtils.nullToBlank(lead.Comment3__c) + cancelMessage;
                    lead.Comment3__c = CommLogUtils.removeOverLogString(CommUtils.nullToBlank(lead.Comment3__c) + cancelMessage, commentLength);
                    // 2017/09/01 最大文字数をこえない問題回避対応 END
                    // 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ BEGIN
                    if (chgRoomTypeFlag) lead.RoomUpdFlg__c = !lead.RoomUpdFlg__c;
                    // 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ END
                }
                // 2015/10/15 Ver15.71以後、予約変更処理ロジック対応するため、キャンセルのみ場合、既存予約情報をキャンセルする
                if (bookingInfo.dmlAction == BI_TL_DmlAction.CANCEL) {
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
                    rs.result = BI_TL_Result.OK;
                    mLogUtils.write_method_end();
                    return rs;
                }
                // 2018/04/19 氏名変更のみケース対応 BEGIN
                else if (bookingInfo.dmlAction == BI_TL_DmlAction.UPD && bookingInfo.isUpdForName) {
                    CommLogicProcess logic = new CommLogicProcess();
                    logic.preventShopAuthCheckSetup(orgLeadLst);
                    if (!orgLeadLst.isEmpty()) update orgLeadLst;
                    logic.restoreShopAuthCheckSetup(orgLeadLst, true);
                }
                // 2018/04/19 氏名変更のみケース対応 END
            }
        }
        // 2016/06/02 新規予約情報を重複取り込み回避対応（同じ予約番号が存在すると、新規取り込みなし、XMLのみコピーする） BEGIN
		else if(bookingInfo.dmlAction == BI_TL_DmlAction.INS ){
            String DataID = bookingInfo.DataID;
            if(CommUtils.isBlank(DataID)){
                rs.result = BI_TL_Result.NG;
                mLogUtils.write_method_end();
                return rs;
            }
if (!TL_ServiceConfigHelp.getCommConfig().bIsDebug) {
			List<LeadIndex__c> rslst = getExistLeadIndexByDataId(bookingInfo);
			if (!rslst.isEmpty()) {
                if(bookingInfo.dmlAction == BI_TL_DmlAction.INS){
                	mLogUtils.write_log('該当データID[' + DataID + ']SalesforceID[' + rslst[0].Id + ']の予約情報は既に取込済ため、重複取込できません。');
                    rs.sfdcId = rslst[0].Id;
                    rs.result = BI_TL_Result.OK;
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
            rs.result = BI_TL_Result.OK;
        } catch (CommException ex) {
        	DataBase.rollback(sp);
            System.debug(ex.getMessage());
            rs.result = BI_TL_Result.NG;
            rs.message = ex.getMessage();
            mLogUtils.write_error(ex.getStackTraceString());
            // 2019/06/15 LogicUtilのINDEX指定不正の不具合改修
            //mLogUtils.write_method_end();
        } catch (Exception e) {
        	DataBase.rollback(sp);
            mLogUtils.write_error(e.getStackTraceString());
            rs.result = BI_TL_Result.NG;
            rs.message = e.getMessage();
            // 2019/06/15 LogicUtilのINDEX指定不正の不具合改修
            //mLogUtils.write_method_end();
        }
        mLogUtils.write_method_end();
        return rs;
    }
    // 既存予約INDEX情報を取得する
    private List<LeadIndex__c> getExistLeadIndexByDataId(BI_TL_SyncInfo bookingInfo) {
        return [select id,EntryDate__c,CreatedDate,StockLogicProcessFlg__c,LeadName__c from LeadIndex__c where ID__c = :bookingInfo.DataID And EventSource__c = :bookingInfo.DataFrom And (APPNAME__c = :APPNAME OR APPNAME__c = null ) and StatusLst__c != :CommConst.LEAD_ST_CANCEL order by CreatedDate desc limit 1];
    }
    /**
    * 予約基本情報
    **/
    private LeadIndex__c upsertLeadIndex(BI_TL_SyncInfo bookingInfo, Contact pkuser, List<Account> TraveCompany) {
        mLogUtils.write_method_start('upsertLeadIndex');
        List<LeadIndex__c> rslst = getExistLeadIndexByDataId(bookingInfo);
        boolean updFlag = bookingInfo.dmlAction == BI_TL_DmlAction.UPD;
        // 初期化処理を行う
        LeadIndex__c leadIndex = new LeadIndex__c();
        if(updFlag && !rslst.isEmpty()){
            leadIndex = rslst[0];
        }
        // 2016/10/21 TL変更機能改善対応[予約変更の場合、予約名を上書きしない対応] BEGIN
        boolean updFlgIsInsert = updFlag && rslst.isEmpty();// 更新　かつ　更新元はなかった場合、該当フラグはTRUE
        // 2016/10/21 TL変更機能改善対応[予約変更の場合、予約名を上書きしない対応] END
        if(updFlag || bookingInfo.dmlAction == BI_TL_DmlAction.INS) {
            // 新規データ作成を行う
            DateTime checkInDt = (bookingInfo.CheckInTime == null ? null : DateTime.newInstance(bookingInfo.CheckInDate, bookingInfo.CheckInTime));
            BI_TL_Member member = bookingInfo.risaplsinformation.risaplsCommonInformation.member;
            // 2015/09/10 ADD BEGIN
            leadIndex.APPNAME__c = APPNAME;
            // 2015/09/10 ADD END
            // 2016/10/06 ADD BEGIN
            if (leadIndex.Id == null) leadIndex.StockLogicProcessFlg__c = TRUE;
            // 2016/10/06 ADD END
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
                // 男性
                                                ? Label.CONST_038_0004 
                                                : (member.UserGendar == '1' 
                //女性
                                                    ? Label.CONST_038_0005 
                //不明
                                                    : (member.UserGendar == '2' ? Label.CONST_038_0006 : '' )));    // 会員性別 
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
            // 2016/07/10 予約チャネル名の変換機能追加対応 BEGIN
            //leadIndex.Channel__c = TraveCompany.size() > 0 ? TraveCompany[0].Name : null;
	    	leadIndex.Channel__c = getChanelStr(bookingInfo,TraveCompany);
	    	// 2016/07/10 予約チャネル名の変換機能追加対応 END
            // 2016/01/28 ネットからの取込時に予約チャネルに旅行会社名で設定する END
            // 2013/08/16 予約名追加
            // 2016/10/21 TL変更機能改善対応[予約変更の場合、予約名を上書きしない対応] BEGIN
            if (updFlgIsInsert || bookingInfo.dmlAction == BI_TL_DmlAction.INS)
            // 2016/10/21 TL変更機能改善対応[予約変更の場合、予約名を上書きしない対応] END
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
    private Plan__c upsertPlan(BI_TL_SyncInfo bookingInfo, List<Account> TraveCompany) {
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
        /* 2014/06/06 プラン検索方式変更
        if (!CommUtils.isBlank(bookingInfo.PackagePlanName)) {
            existPlanLst = [select Id, name from Plan__c Where name = :bookingInfo.PackagePlanName limit 1];
        }*/
        String packageCode = CommUtils.nullToBlank(bookingInfo.PackagePlanCode);
        String packageName = CommUtils.nullToBlank(bookingInfo.PackagePlanName);
        String agtId = TraveCompany[0].Id;
        String shopCode = shopCd;
        // パッケージコードが存在する場合、パッケージからSFのプラン変換ルールをチエックする
        if (!CommUtils.isBlank(packageCode)) {
            String planNo = TL_ServiceConfigHelp.getSfPlanNoByAgtPlanInfo(shopCd,bookingInfo.SalesOfficeCompanyCode,packageCode);
            // 該当パッケージコードからSF側のプランNOが設定されている場合
            if(planNo != null){
                mLogUtils.write_log('AGTパッケージコード「'+packageCode+'」からPlanNo「'+planNo+'」に変換済');
                // 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
                // List<Plan__c> planLst = [select Id, name,PlanNo__c,ShopInfoRef__c,client__c,Price__c,ServiceRate__c,JmstRef__r.TaxRate__c from Plan__c where IsClosed__c != true and PlanNo__c = :planNo limit 1];
                List<Plan__c> planLst = [select Id, name,PlanNo__c,ShopInfoRef__c,client__c,Price__c,ServiceRate__c,JmstRef__r.TaxRate__c,BathTaxAccMstRef__c from Plan__c where IsClosed__c != true and PlanNo__c = :planNo limit 1];
                // 2020/07/30 入湯税の自動入力機能について改善 WGCH NED
                if(!planLst.isEmpty()) return planLst[0];
            }
        }
        
        // 店舗情報格納する
        Map<String, ShopInformation__c> shopInfoMap = new Map<String, ShopInformation__c>(); 
        /* 2014.11.18 プラン検索ロジック変更、店舗検索機能を追加 */
        // 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
        // String queryHeader = ' select Id, name,PlanNo__c,ServiceRate__c,JmstRef__r.TaxRate__c,Price__c  from Plan__c ';
        String queryHeader = ' select Id, name,PlanNo__c,ServiceRate__c,JmstRef__r.TaxRate__c,Price__c,BathTaxAccMstRef__c from Plan__c ';
        // 2020/07/30 入湯税の自動入力機能について改善 WGCH NED
        String queryLimit = ' limit 1 ';
        // 2014/07/16 非公開プランは検索対象外に対応
        //String whereStr = ' Where (';
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
            rsPlan.PackageCode__c = bookingInfo.PackagePlanCode;
            rsPlan.client__c = agtId;
            // 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
            if(!isPlanOfShopFlg && shopInfoMap.isEmpty()) shopInfoMap = ShopInfoUtil.getShopInfoMap();
            // 设定有效的关联入汤税商品ID
            rsPlan.BathTaxAccMstRef__c = CommLogicProcess.getBathTaxAccMstRef(shopInfoMap.get(shopCode), shopCode);
            // 2020/07/30 入湯税の自動入力機能について改善 WGCH END
            insert rsPlan;
            // 新規作成のプラン情報を再取得する
            // 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
            // rsPlan = [select Id, name,PlanNo__c,ServiceRate__c,JmstRef__r.TaxRate__c  from Plan__c where id = :rsPlan.id];
            rsPlan = [select Id, name,PlanNo__c,ServiceRate__c,JmstRef__r.TaxRate__c,BathTaxAccMstRef__c from Plan__c where id = :rsPlan.id];
            // 2020/07/30 入湯税の自動入力機能について改善 WGCH END
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
    	// 2020/05/29 bug fixed 6440 WGCH BEGIN
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
        // 2020/05/29 bug fixed 6440 WGCH END
        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
    	mLogUtils.write_log('プラン明細取得件数:' + orgPdList.size());
    	// 2019/09/15 軽減税率機能対応 WGCH BEGIN
    	// gPlanDetailInf.init(orgPdList);
    	gPlanDetailInf.init(orgPdList, plan);
    	// 2019/09/15 軽減税率機能対応 WGCH END
		
    	mLogUtils.write_method_end();
    }
	
	class PlanDetailInfo {
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
        // 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
        // String queryHeader = ' select Id, name,PlanNo__c,ServiceRate__c,JmstRef__r.TaxRate__c,Price__c,ShopInfoRef__r.ShopCode__c,(Select Id,Price__c,ServiceRate__c,TaxRate__c,AccountMasterRef__c,AccountMasterRef__r.ActionType__c From PlanRef__r)  from Plan__c ';
        String queryHeader = ' select Id, name,PlanNo__c,ServiceRate__c,JmstRef__r.TaxRate__c,Price__c,ShopInfoRef__r.ShopCode__c,(Select Id,Price__c,ServiceRate__c,TaxRate__c,AccountMasterRef__c,AccountMasterRef__r.ActionType__c From PlanRef__r),BathTaxAccMstRef__c from Plan__c ';
        // 2020/07/30 入湯税の自動入力機能について改善 WGCH END
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
		String key1 = TL_ServiceConfigHelp.getChildRateMatchKey(strCalRate);
		String key2 = TL_ServiceConfigHelp.getChildPriceMatchKey(strChildPrice);
		if (childPlanNameConvertMap.containsKey(key1)) {
			item.ProductName__c = childPlanNameConvertMap.get(key1);
			return;
		} else if (childPlanNameConvertMap.containsKey(key2)) {
			item.ProductName__c = childPlanNameConvertMap.get(key2);
			return;
		}
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
    private void upsertTL2Lead(BI_TL_SyncInfo bookingInfo, LeadIndex__c leadIndex, Contact pkuser, List<Account> TraveCompany,String shopCode,List<Lead__c> oldLeadLst) {
        mLogUtils.write_method_start('upsertTL2Lead');

        // 2018/04/19 氏名変更のみケース対応 BEGIN
        if (bookingInfo.dmlAction == BI_TL_DmlAction.UPD && bookingInfo.isUpdForName) {
            mLogUtils.write_log('氏名変更のみため、予約変更詳細処理を行わない、メール本文のみ更新');
            mLogUtils.write_method_end();
            return;
        }
        // 2018/04/19 氏名変更のみケース対応 END
        // 部屋自動割り振り機能
        boolean autoAssingRoomflag = TL_ServiceConfigHelp.getAppConfig(shopCd).roomAutoAssignFlag;
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
        for (BI_TL_RoomAndGuestInfo roomAndGuest: bookingInfo.roomAndGuestLst) {
            roomTypeCdSet.add(roomAndGuest.room.RoomTypeCode);
            //roomTypeMap.put(roomAndGuest.room.RoomTypeCode);
            // 2013/02/26 部屋タイプ名：部屋ID情報を格納する
            if (!CommUtils.isBlank(roomAndGuest.room.RoomTypeName)) roomTypeNmSet.add(roomAndGuest.room.RoomTypeName);
        }
        
        // 部屋タイプMAP情報設定する
        Map<String,Id> roomTypeMap = new Map<String, Id>();
        // 2013/02/26 部屋タイプ名情報を格納する
        Map<String,Id> roomTypeNmMap = new Map<String, Id>();
        // UPDATE 2015/09/15　店舗区分 :新追加 ShopInfoRef__c　
        // 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 BEGIN
        Map<Id, id> oneTypeToRoomMap = new Map<Id, Id>();
        //for (TypeOfRooms__c roomType: [select id, RoomTypeName__c, RoomTypeCode__c from TypeOfRooms__c where ShopInfoRef__r.ShopCode__c = :shopCode and  (RoomTypeCode__c in :roomTypeCdSet Or RoomTypeName__c in :roomTypeNmSet)]) {
        for (TypeOfRooms__c roomType: [select id, RoomTypeName__c, RoomTypeCode__c 
        	,(Select Id From TypeRoomRef__r limit 2)
        	from TypeOfRooms__c where ShopInfoRef__r.ShopCode__c = :shopCode and  (RoomTypeCode__c in :roomTypeCdSet Or RoomTypeName__c in :roomTypeNmSet)]) {
        // 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 END
            roomTypeMap.put(roomType.RoomTypeCode__c, roomType.Id);
            // 2013/02/26 部屋タイプ名：部屋ID情報を格納する
            if (!CommUtils.isBlank(roomType.RoomTypeName__c)) roomTypeNmMap.put(roomType.RoomTypeName__c, roomType.Id);
            // 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 BEGIN
            if (oneRoomAutoAssingRoomFlg) {
            	if (roomType.TypeRoomRef__r != null && roomType.TypeRoomRef__r.size() == 1) {
            		oneTypeToRoomMap.put( roomType.Id, roomType.TypeRoomRef__r[0].Id );
            	}
            }
            // 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 END
        }
        mLogUtils.write_log('roomTypeMap :: ' + roomTypeMap);
        mLogUtils.write_log('oneTypeToRoomMap :: ' + oneTypeToRoomMap);
        // 2015/07/22  部屋タイプが存在　かつ　対応部屋タイプに対して、１部屋のみの場合、該当部屋は自動的に予約にアサインする BEGIN
        // 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 BEGIN
        /*
        Map<Id, id> oneTypeToRoomMap = new Map<Id, Id>();
        // 自動割り当てフラグはTRUEのみ、該当関連取得を行う
        if (oneRoomAutoAssingRoomFlg) {
            for ( TypeOfRooms__c r : [Select id, (Select Id From TypeRoomRef__r limit 2) From TypeOfRooms__c where id in :roomTypeMap.values()] ) {
                if (r.TypeRoomRef__r != null && r.TypeRoomRef__r.size() == 1) {
                    oneTypeToRoomMap.put( r.Id, r.TypeRoomRef__r[0].Id );
                }
            }
        }
        */
        // 2016/10/26 部屋タイプと部屋が1対1の場合は故障部屋を割当される不具合改修 BEGIN
        map<Integer, Room__c> oneRoomCanAssignRoomMap = new map<Integer, Room__c>();
        // 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 BEGIN
        /*
        // 部屋タイプが存在する場合
        if (!oneTypeToRoomMap.isEmpty()) {
        	// 割当できる部屋情報を取得する　
        	oneRoomCanAssignRoomMap = getCanAssignRoom(leadIndex,roomTypeMap,oneRoomAutoAssingRoomFlg,bookingInfo);
        	mLogUtils.write_log('1VS1部屋自動割り当て対象 :: ' + oneRoomCanAssignRoomMap);
        }
        */
        // 2016/10/26 部屋タイプと部屋が1対1の場合は故障部屋を割当される不具合改修 END
        // 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 END
        // 部屋タイプにより、自動割り振りできる部屋情報を戻る
        // 2015/10/30 故障部屋は自動割当て機能に追加対応 BEGIN
        //map<Id, List<Room__c>> canAssignRoomMap = new map<Id, List<Room__c>>();
        map<Integer, Room__c> canAssignRoomMap = new map<Integer, Room__c>();
        if (autoAssingRoomflag) {
            canAssignRoomMap = getCanAssignRoom(leadIndex,roomTypeMap,autoAssingRoomflag,bookingInfo);
            mLogUtils.write_log('複数部屋自動割り当て対象 :: ' + canAssignRoomMap);
        }
        // 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 BEGIN
        // XMLの部屋自動割り当てフラグをONの場合、上記処理に１VS１も含めっているため、下記の処理は個別処理を行わない
        else if (!oneTypeToRoomMap.isEmpty()) {
        	// 割当できる部屋情報を取得する　
        	oneRoomCanAssignRoomMap = getCanAssignRoom(leadIndex,roomTypeMap,oneRoomAutoAssingRoomFlg,bookingInfo);
        	mLogUtils.write_log('1VS1部屋自動割り当て対象 :: ' + oneRoomCanAssignRoomMap);
        }
        // 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 END
        // 2015/10/30 故障部屋は自動割当て機能に追加対応 END
        // 宿泊レコードタイプ
        String bookingRcTypeId = CommLogicProcess.getLeadBookingRecType();
        // チェックイン日付・日時[基本宿泊情報から]
        DateTime checkInFirstDayDt = DateTime.newInstance(leadIndex.EntryDate__c,
            bookingInfo.CheckInTime == null ? defaultCheckinTime : bookingInfo.CheckInTime);
        // 最後日のチェックアウト日付・日時[基本宿泊情報から][出発日設定を行う]
        DateTime checkOutLastDayDt = DateTime.newInstance(leadIndex.DepartureDate__c, 
            bookingInfo.CheckOutTime == null ? defaultCheckoutTime : bookingInfo.CheckOutTime);
        // メール本文[7XXXXX]
        BI_TL_RisaplBasic risaplBasic = bookingInfo.risaplsinformation.risaplsCommonInformation.risaplBasic;
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
                // 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
                // 该Plan存在参照入汤税商品, 该Plan的会计商品设定参照对应的Plan处理
                if(curPlan.BathTaxAccMstRef__c != null) commshitulyouAcc.PlanBathTaxAccMstRef__c = curPlan.Id;
                // 2020/07/30 入湯税の自動入力機能について改善 WGCH END
                insert commshitulyouAcc;
            }
            // 2016/06/10 子供料金プラン取り込み機能対応 BGEIN
	    	// 2017/02/21 お子様プランの料金PRICE機能追加 by zh BEGIN
	    	//setChildPlanInfo(TL_ServiceConfigHelp.getChildPlanConvertConfig(shopCd));
        	setChildPlanInfo(TL_ServiceConfigHelp.getChildPlanConvertConfig(shopCd),TL_ServiceConfigHelp.getChildPlanPriceConvertConfig(shopCd));
        	// 2017/02/21 お子様プランの料金PRICE機能追加 by zh END
        	// 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ BEGIN
        	// プラン設定情報を取得する
        	childPlanNameConvertMap = TL_ServiceConfigHelp.getChildPlanNameConvertConfig(shopCd);
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
        mLogUtils.write_log('税区分：' + bookingInfo.TaxServiceFee);
        
        Boolean isUpdateFlag = bookingInfo.dmlAction == BI_TL_DmlAction.UPD;
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
                boolean plannameToEstflag = TL_ServiceConfigHelp.isSfPlanNmToEstProdNm(shopCd);
mLogUtils.write_log('見積明細名はプラン目に変更::::' + plannameToEstflag);
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
        Map<String,Object> autoSetupfieldMap = TL_ServiceConfigHelp.getAppConfig(shopCd).fieldMap;
        Map<String, Schema.DescribeFieldResult> finalFieldMap = CommUtils.getFieldMetaData(Lead__c.getSObjectType().getDescribe(),autoSetupfieldMap.keySet());
        boolean isRoomRateFlg = bookingInfo.RoomRateOrPersonalRate == 'PersonalRate' ? false : true;
mLogUtils.write_log('予約情報新規、変更処理開始');
        //予約　グループのマッピングを作成
        Map<Integer,List<Lead__c>> groupLeadMap = new Map<Integer,List<Lead__c>>();
        Lead__c beforeLead = null;
        integer roomIndex = 0;
        // 2016/09/17 TL連携在庫調整不具合対応 BEGIN
        Set<Id> orgIdSet = new Set<Id>();
        // 2016/09/17 TL連携在庫調整不具合対応 END
        // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
        Boolean isCanModifyPeoples = true;
        // 2017/05/09 ネット取り込み、予約変更機能改善 END
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
            // 2016/09/17 TL連携在庫調整不具合対応 BEGIN
            orgIdSet.add(lead.id);
            // 2016/09/17 TL連携在庫調整不具合対応 END
            // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
            // 集めるの場合、関連の部屋情報は人數関連項目を変更あり場合、人數自動更新を行わない
            if (CommConst.APPOTION_LEADSPLIT_DIV_CODE == CommConst.APPOTION_LEADSPLIT_DIV_CODE_UNION && isCanModifyPeoples) {
            	set<string> locChgfieldSet = new set<string>();
            	if (fieldChgHisMap != null && fieldChgHisMap.containsKey(lead.Id)) locChgfieldSet = fieldChgHisMap.get(lead.Id);
            	isCanModifyPeoples = (
            	       TL_ServiceConfigHelp.isSetupVal(locChgfieldSet,'StayPersons__c') &&
            	       TL_ServiceConfigHelp.isSetupVal(locChgfieldSet,'Mans__c') &&
            	       TL_ServiceConfigHelp.isSetupVal(locChgfieldSet,'Femails__c') &&
            	       TL_ServiceConfigHelp.isSetupVal(locChgfieldSet,'ChildFA__c') &&
            	       TL_ServiceConfigHelp.isSetupVal(locChgfieldSet,'Childs__c') &&
            	       TL_ServiceConfigHelp.isSetupVal(locChgfieldSet,'ChildC__c') &&
            	       TL_ServiceConfigHelp.isSetupVal(locChgfieldSet,'ChildD__c'));
            }
            // 2017/05/09 ネット取り込み、予約変更機能改善 END
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
        // 2016/09/17 TL連携在庫調整不具合対応 BEGIN
        // 更新前にTL経由で在庫変更履歴情報を取得する（予約情報単位）
		Map<Id,StockChangeHisotry__c> historyMap = getPreChangeHistory(orgIdSet);
		// 2016/09/17 TL連携在庫調整不具合対応 END
        Map<String,Id> lastRoomMap = new Map<String,Id>();
        Set<String> userOrgLeadSet = new Set<String>();
        Set<Id> updateOrgLeadIdSet = new Set<Id>();
		// 2016/07/10 予約チャネル名の変換機能追加対応 BEGIN
        String chanelStr = getChanelStr(bookingInfo,TraveCompany);
        // 2016/07/10 予約チャネル名の変換機能追加対応 END
        // 2016/01/07 予約キャンセルの場合、キャンセル内容は本文メールに反映を行う BEGIN
        //integer commentLength = Lead__c.Comment3__c.getDescribe().getLength();
        //integer emailLength = Lead__c.email__c.getDescribe().getLength();
        // 2016/01/07 予約キャンセルの場合、キャンセル内容は本文メールに反映を行う END
        // 2016/09/17 TL連携在庫調整不具合対応 BEGIN
        List<Lead__c> stockOrgLeadList = new list<lead__c>();
        List<Lead__c> stockNewLeadList = new list<lead__c>();
        List<BI_TL_RoomAndGuestInfo> stockXmlRoomAndGuestList = new list<BI_TL_RoomAndGuestInfo>();
        // 2017/02/07 男女区分取得 by zy BEGIN
        Boolean genderFlag = bookingInfo.risaplsinformation.risaplsCommonInformation.allotment.GenderDiv == 0 ;
        // 2018/05/09 指定AGTにより、男女不明の処理機能対応 BEGIN
        // 男性、女性不明の場合、AGTCODEチェックして、個別処理を行う
        Boolean genderSpecFlg = false;
        if (genderFlag) {
        	// AGTCODE
        	String agtCode = CommUtils.nullToBlank(risaplBasic.SalesOfficeCompanyCode);
        	genderSpecFlg = TL_ServiceConfigHelp.getAppConfig(shopCd).filter.isSpecAgtCode(agtCode);
        }
        // 2018/05/09 指定AGTにより、男女不明の処理機能対応 END
        if (genderFlag) genderFlag = TL_ServiceConfigHelp.getAppConfig(shopCd).filter.getResult( risaplBasic.TelegramData);
        // 2017/02/07 男女区分取得 by zy END
        // 2016/09/17 TL連携在庫調整不具合対応 END
        // 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応 by zh BEGIN
        // 支払明細はどの部屋どの泊にリンクすることINDEXを記録する
        Integer payMediaLinkPos = 0;
        if (TL_ServiceConfigHelp.getAppConfig(shopCd).payMeaidToLastDayFlag) payMediaLinkPos = (nights*rooms-rooms);
        // 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応 by zh END
        // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ BEGIN
        // 既存予約の見積明細を上書きするがどう切り替え用フラグ
        Boolean isClearEstItemsFlag = TL_ServiceConfigHelp.getAppConfig(shopCd).modifyEstItemsFlag;
        // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ END
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
                
                BI_TL_RoomAndGuestInfo roomAndGuest = bookingInfo.roomAndGuestLst[idx];
                // 部屋利用日（到着日)
                Date checkInDate = roomAndGuest.roomRateLst[0].RoomDate;
                
                // 新規予約データ作成
                Lead__c newLead = new Lead__c();
                // 2016/10/21 TL変更機能改善対応、項目値自動設定不具合改修 BEGIN
                for(String fieldName : finalFieldMap.keySet()){
                    Schema.DescribeFieldResult describeField = finalFieldMap.get(fieldName);
                    if(describeField.isCreateable()){
                    	// デイフォル値を自動設定を行う
                        newLead.put(fieldName,CommUtils.ConvByFielType(autoSetupfieldMap.get(fieldName), describeField.getType()));
                    	//mLogUtils.write_log('更新内容[' + fieldName + ']:1:' + fieldMap.get(fieldName) );
                        mLogUtils.write_log('項目値自動設定[' + fieldName + ']:1:' + newLead.get(fieldName) );
                    }
                }
                // 2016/10/21 TL変更機能改善対応、項目値自動設定不具合改修 END
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
                // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                set<string> chgfieldSet = new set<string>();
                if (isHadLeadId) {
                    if (fieldChgHisMap != null && fieldChgHisMap.containsKey(orgLead.Id)) chgfieldSet = fieldChgHisMap.get(orgLead.Id);
                }
                // 2017/05/09 ネット取り込み、予約変更機能改善 END
                // お客様情報
                // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                if (TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'Relcontact__c'))
                // 2017/05/09 ネット取り込み、予約変更機能改善 END
                newLead.Relcontact__c = newLead.Relcontact__c == null ? pkuser.id : newLead.Relcontact__c;
                
                // 2013/07/16 記号機能対応 BEGIN
                // 親部屋マーク標識用の文字は予約名の文字列先頭に付加
            	// プラン情報   
                // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                if (TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'Field310__c'))
                // 2017/05/09 ネット取り込み、予約変更機能改善 END      
            	newLead.Field310__c = curPlan == null ? null : curPlan.Id;
            	// 予約名情報を格納する
                if(isHadLeadId){
                	// 予約名の個別処理
                	String orgLeadName = '';
                	String newLeadName = '';
                	// 既存の予約名はそのまま残り
                	//泊目
                	if (orgLeadNights != null && orgLeadNights > 1) orgLeadName = String.valueOf(orgLeadNights) + '-' + (i+1) + Label.CONST_038_0007 +' ' + orgLead.LeadIndexRef__r.LeadName__c;
                	else orgLeadName = orgLead.LeadIndexRef__r.LeadName__c;
                	//泊目
	                if (nights > 1) newLeadName += String.valueOf(nights) + '-' + (i+1) + Label.CONST_038_0007 +' ' + leadName;  //bookingInfo.GuestOrGroupNameKanjiName;
	                else newLeadName += leadName; //bookingInfo.GuestOrGroupNameKanjiName;
                	// 既存の予約名をReplaceする
                	newLead.name = newLead.name.replace(orgLeadName, newLeadName);
                	if (rooms > 1 && j == 0 
                		&& !CommUtils.isBlank(strRoomDelegatePrefix) 
                		&& !newLead.name.startsWith(strRoomDelegatePrefix)) {
                		newLead.name = strRoomDelegatePrefix + newLead.name;
                	}
                	// 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                	if (CommConst.APPOTION_LEADSPLIT_DIV_CODE != CommConst.APPOTION_LEADSPLIT_DIV_CODE_UNION) {
                        set<string> locChgfieldSet = new set<string>();
                        if (fieldChgHisMap != null && fieldChgHisMap.containsKey(orgLead.Id)) locChgfieldSet = fieldChgHisMap.get(orgLead.Id);
		                isCanModifyPeoples = (
		                       TL_ServiceConfigHelp.isSetupVal(locChgfieldSet,'StayPersons__c') &&
		                       TL_ServiceConfigHelp.isSetupVal(locChgfieldSet,'Mans__c') &&
		                       TL_ServiceConfigHelp.isSetupVal(locChgfieldSet,'Femails__c') &&
		                       TL_ServiceConfigHelp.isSetupVal(locChgfieldSet,'ChildFA__c') &&
		                       TL_ServiceConfigHelp.isSetupVal(locChgfieldSet,'Childs__c') &&
		                       TL_ServiceConfigHelp.isSetupVal(locChgfieldSet,'ChildC__c') &&
		                       TL_ServiceConfigHelp.isSetupVal(locChgfieldSet,'ChildD__c'));
mLogUtils.write_log('StayPersons__c:::' + TL_ServiceConfigHelp.isSetupVal(locChgfieldSet,'StayPersons__c'));
mLogUtils.write_log('Mans__c:::' + TL_ServiceConfigHelp.isSetupVal(locChgfieldSet,'Mans__c'));
mLogUtils.write_log('Femails__c:::' + TL_ServiceConfigHelp.isSetupVal(locChgfieldSet,'Femails__c'));
mLogUtils.write_log('ChildFA__c:::' + TL_ServiceConfigHelp.isSetupVal(locChgfieldSet,'ChildFA__c'));
mLogUtils.write_log('Childs__c:::' + TL_ServiceConfigHelp.isSetupVal(locChgfieldSet,'Childs__c'));
mLogUtils.write_log('ChildC__c:::' + TL_ServiceConfigHelp.isSetupVal(locChgfieldSet,'ChildC__c'));
mLogUtils.write_log('ChildD__c:::' + TL_ServiceConfigHelp.isSetupVal(locChgfieldSet,'ChildD__c'));
                	}
mLogUtils.write_log('orgLead.Id:::' + orgLead.Id);
	                // 2017/05/09 ネット取り込み、予約変更機能改善 END
                } else {
            		newLead.name = (rooms > 1 && j == 0 ? strRoomDelegatePrefix : '');
            		// 2013/07/16 記号機能対応 END
	                // 予約データ名設定を行う
	                //泊目
	                if (nights > 1) newLead.name += String.valueOf(nights) + '-' + (i+1) + Label.CONST_038_0007 +' ' + leadName;  //bookingInfo.GuestOrGroupNameKanjiName;
	                else newLead.name += leadName; //bookingInfo.GuestOrGroupNameKanjiName;
	                // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
	                isCanModifyPeoples = true;
	                // 2017/05/09 ネット取り込み、予約変更機能改善 END
                }
                // レコードタイプ：宿泊タイプ
                newLead.RecordTypeId = bookingRcTypeId;
mLogUtils.write_log('isCanModifyPeoples:::' + isCanModifyPeoples);
                // 予約受付日
                // 2013/06/19 予約受付日の受付時間設定ミス、不具合修正、時間項目を設定する
                newLead.ReservedDate__c = DateTime.newInstance(bookingInfo.TravelAgencyBookingDate, bookingInfo.TravelAgencyBookingTime);
                // 支払方法 ----------------BEGIN----------------------
                // 2014/04/25 支払方法設定共通化
                // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                if (TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'Field315__c'))
                // 2017/05/09 ネット取り込み、予約変更機能改善 END
                newLead.Field315__c = getLocalPaymentInfo(bookingInfo.Payment);
                // 支払方法 -----------------END-----------------------
                // 予約ステータス[Deafult:確認中]
                //newLead.ReservedStatus__c =
                // First Dayの場合
                if (i == 0) {
                	// 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                    // チェックイン日
                    //newLead.EntryTime__c = checkInFirstDayDt;
               	 	if (TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'Field4__c'))
                	// 2017/05/09 ネット取り込み、予約変更機能改善 END
                    // チェックイン時間
                    newLead.Field4__c = (bookingInfo.CheckInTime == null 
                        // DayUserの場合の時刻情報
                        ?  (bookingInfo.Nights == 0 ? defaultDayUseCheckInTime : defaultCheckInTimeStr)
                        :  (DateTime.newInstance(Date.today(), bookingInfo.CheckInTime)).format('HH:mm') );
                    // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                    // チェックイン日
                    newLead.EntryTime__c = DateTime.newInstance(checkInFirstDayDt.date(), CommUtils.stringToTime(newLead.Field4__c));
                    // 2017/05/09 ネット取り込み、予約変更機能改善 END
                } else {
                	// 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                    // チェックイン日
                    //newLead.EntryTime__c = DateTime.newInstance(checkInDate, defaultCheckinTime);
	                // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
	                if (TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'Field4__c'))
	                // 2017/05/09 ネット取り込み、予約変更機能改善 END
                    // チェックイン時間
                    newLead.Field4__c = defaultCheckInTimeStr;
                    // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                    // チェックイン日
                    newLead.EntryTime__c = DateTime.newInstance(checkInDate, CommUtils.stringToTime(newLead.Field4__c));
                    // 2017/05/09 ネット取り込み、予約変更機能改善 END
                }
                //2016/03/02 ---------BEGIN----------------
                //予約取込のXMLのタグ：入込方法（Transportaion）存在すると、該当項目内容はご予約の「交通手段」項目へ設定する
                if(CommUtils.isBlank(newLead.Field348__c)) newLead.Field348__c = CommUtils.nullToBlank(bookingInfo.Transportaion);
                //2016/03/02 ----------END-----------------

                // 最後日の場合
                if (i == nights - 1) {
                    // チェックアウト日
                  //  newLead.Departure__c = checkOutLastDayDt;
	                // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
	                if (TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'Field3__c'))
	                // 2017/05/09 ネット取り込み、予約変更機能改善 END
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
                    // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                    if (TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'Field3__c'))
                    // 2017/05/09 ネット取り込み、予約変更機能改善 END
                    // チェックアウト時間
                    newLead.Field3__c = defaultCheckoutTimeStr;
                }
                // 2017/01/06 男女区分 「0」：男女区分なし、「1」：男女区分あり  BEGIN by zh
				BI_TL_Allotment allotment = bookingInfo.risaplsinformation.risaplsCommonInformation.allotment;    
				// 2017/01/06 男女区分 「0」：男女区分なし、「1」：男女区分あり  END by zh            
mLogUtils.write_log('allotment:::' + allotment);
mLogUtils.write_log('allotment.GenderDiv:::' + allotment.GenderDiv);
                // 2013/06/09 宿泊人数は未設定する場合、自動Default値を設定する
                // 2018/12/15 TL2way会計人数制御改善(大人人数のみ予約人数に反映する) by zh BEGIN
                /*Integer calRoomPaxCount =  CommUtils.nullToZero(roomAndGuest.room.RoomPaxMaleCount) + 
                                           CommUtils.nullToZero(roomAndGuest.room.RoomPaxFemaleCount) + 
                                           CommUtils.nullToZero(roomAndGuest.room.RoomChildA70Count) +
                                           CommUtils.nullToZero(roomAndGuest.room.RoomChildB50Count) +
                                           CommUtils.nullToZero(roomAndGuest.room.RoomChildC30Count) +
                                           CommUtils.nullToZero(roomAndGuest.room.RoomChildDNoneCount);*/
                Set<String> childSet = TL_ServiceConfigHelp.getAppConfig(shopCd).childSet;
	            Integer calRoomPaxCount = 0; 
                //tag存在、有值并且满足条件的情况、总人数计算包含小孩
                if(childSet != null){
                	calRoomPaxCount =  CommUtils.nullToZero(roomAndGuest.room.RoomPaxMaleCount) + 
                                       CommUtils.nullToZero(roomAndGuest.room.RoomPaxFemaleCount); 
	                if (childSet.contains('childfa__c')) calRoomPaxCount += CommUtils.nullToZero(roomAndGuest.room.RoomChildA70Count);
	                if (childSet.contains('childs__c')) calRoomPaxCount += CommUtils.nullToZero(roomAndGuest.room.RoomChildB50Count);
	                if (childSet.contains('childc__c')) calRoomPaxCount += CommUtils.nullToZero(roomAndGuest.room.RoomChildC30Count);
	                if (childSet.contains('childd__c')) calRoomPaxCount += CommUtils.nullToZero(roomAndGuest.room.RoomChildDNoneCount);
                //tag不存在、按原程序计算、总人数一直包含小孩人数
                }else{
                	calRoomPaxCount =  CommUtils.nullToZero(roomAndGuest.room.RoomPaxMaleCount) + 
                                           CommUtils.nullToZero(roomAndGuest.room.RoomPaxFemaleCount) + 
                                           CommUtils.nullToZero(roomAndGuest.room.RoomChildA70Count) +
                                           CommUtils.nullToZero(roomAndGuest.room.RoomChildB50Count) +
                                           CommUtils.nullToZero(roomAndGuest.room.RoomChildC30Count) +
                                           CommUtils.nullToZero(roomAndGuest.room.RoomChildDNoneCount);
                }
                System.debug(loggingLevel.INFO, 'calRoomPaxCount:::' + calRoomPaxCount);
                // 2018/12/15 TL2way会計人数制御改善(大人人数のみ予約人数に反映する) by zh END
                String warningMsg = '';
		// 2017/01/06 男女区分 「0」：男女区分なし、「1」：男女区分あり  BEGIN by zh
                String genderDivMsg = '';
		// 2017/01/06 男女区分 「0」：男女区分なし、「1」：男女区分あり  END by zh
                // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                Boolean stayPerponsChgFlg = (isCanModifyPeoples && TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'StayPersons__c'));
                // 2017/05/09 ネット取り込み、予約変更機能改善 END
                // 2018/07/19 TL取り込みの総計人数が不正改善対応 by zh BEGIN
        		boolean paxCountCalFlag = TL_ServiceConfigHelp.getAppConfig(shopCd).paxCountCalFlag;
        		//if (roomAndGuest.room.PerRoomPaxCount == null || roomAndGuest.room.PerRoomPaxCount == 0) {
                if (roomAndGuest.room.PerRoomPaxCount == null || roomAndGuest.room.PerRoomPaxCount == 0 || paxCountCalFlag) {
                // 2018/07/19 TL取り込みの総計人数が不正改善対応 by zh END
                    // XMLの中に、未設定する場合、自動的にSFの初期値で自動設定を行う「非設定する場合、自動設定を行う」
                    if (calRoomPaxCount > 0) {
                        // 1室利用人数
                        // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                        if (stayPerponsChgFlg)
                        // 2017/05/09 ネット取り込み、予約変更機能改善 END
                        newLead.StayPersons__c = calRoomPaxCount;
                    } else {
                        // 該当ケースする場合、注意事項に自動内容追加を行う
                        //サイトコントローラからの予約データのなかに、予約人数がありませんでしたので、デフォルト値(仮の値)を設定させていただきました、つきましては、ご予約者の方へご確認していただきまして、本予約データの予約人数を手動にて変更ください。
						// 2016/10/26 BEGIN
                        //予約人数がゼロで取り込まれましたので人数を変更してください。
                        warningMsg = '<font color="red">'+ Label.MSG_038_0008 +'</font><br/>';
                        // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                        if (stayPerponsChgFlg)
                        // 2017/05/09 ネット取り込み、予約変更機能改善 END
                        newLead.StayPersons__c = 0;
						// 2016/10/26 END
                    }
                } else {
                    // 1室利用人数
                    // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                    if (stayPerponsChgFlg)
                    // 2017/05/09 ネット取り込み、予約変更機能改善 END
                    newLead.StayPersons__c = roomAndGuest.room.PerRoomPaxCount;
                }
                // 2017/01/06 男女区分 「0」：男女区分なし、「1」：男女区分あり  BEGIN by zh
                // 2017/02/07 男女区分取得 by zy BEGIN
                //if(allotment.GenderDiv == 0){
               // 2018/05/09 指定AGTにより、男女不明の処理機能対応 BEGIN
               // 男性、女性不明の場合、AGTCODEチェックして、個別処理を行う
				if (genderSpecFlg) {
	                // 子供A人数
                    if (isCanModifyPeoples && TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'ChildFA__c'))
	                newLead.ChildFA__c = roomAndGuest.room.RoomChildA70Count;
	                // 子供B人数
                    if (isCanModifyPeoples && TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'Childs__c'))
	                newLead.Childs__c = roomAndGuest.room.RoomChildB50Count;
	                // 子供C人数
                    if (isCanModifyPeoples && TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'ChildC__c'))
	                newLead.ChildC__c = roomAndGuest.room.RoomChildC30Count;
	                // 子供D人数
                    if (isCanModifyPeoples && TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'ChildD__c'))
	                newLead.ChildD__c = roomAndGuest.room.RoomChildDNoneCount;
					// 大人合計値を計算する
					Decimal adultCnt = (roomAndGuest.room.RoomPaxMaleCount + roomAndGuest.room.RoomPaxFemaleCount);
					decimal mans = math.floor(adultCnt / 2);
					decimal femal = adultCnt - mans;
	                // 大人人員(男性)
                    if (isCanModifyPeoples && TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'Mans__c'))
	                newLead.Mans__c = mans;
	                // 大人人員(女性)
                    if (isCanModifyPeoples && TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'Femails__c'))
	                newLead.Femails__c = femal;
	                //男女割は不明
	                genderDivMsg = '<font color="red">'+ Label.MSG_038_0002 +'</font><br/>';
				}
				//if(genderFlag) {
				else if (genderFlag) {
				// 2018/05/09 指定AGTにより、男女不明の処理機能対応 END
               // 2017/02/07 男女区分取得 by zy END
                	// 大人人員(男性)
                    // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                    if (isCanModifyPeoples && TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'Mans__c'))
                    // 2017/05/09 ネット取り込み、予約変更機能改善 END
	                newLead.Mans__c = 0;
	                // 大人人員(女性)
                    // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                    if (isCanModifyPeoples && TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'Femails__c'))
                    // 2017/05/09 ネット取り込み、予約変更機能改善 END
	                newLead.Femails__c = 0;
	                // 子供A人数
                    // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                    if (isCanModifyPeoples && TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'ChildFA__c'))
                    // 2017/05/09 ネット取り込み、予約変更機能改善 END
	                newLead.ChildFA__c = 0;
	                // 子供B人数
                    // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                    if (isCanModifyPeoples && TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'Childs__c'))
                    // 2017/05/09 ネット取り込み、予約変更機能改善 END
	                newLead.Childs__c = 0;
	                // 子供C人数
                    // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                    if (isCanModifyPeoples && TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'ChildC__c'))
                    // 2017/05/09 ネット取り込み、予約変更機能改善 END
	                newLead.ChildC__c = 0;
	                // 子供D人数
                    // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                    if (isCanModifyPeoples && TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'ChildD__c'))
                    // 2017/05/09 ネット取り込み、予約変更機能改善 END
	                newLead.ChildD__c = 0;
	                //男女割は不明
	                genderDivMsg = '<font color="red">'+ Label.MSG_038_0002 +'</font><br/>';
                }else{
            	// 2017/01/06 男女区分 「0」：男女区分なし、「1」：男女区分あり  END by zh
	                // 大人人員(男性)
                    // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                    if (isCanModifyPeoples && TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'Mans__c'))
                    // 2017/05/09 ネット取り込み、予約変更機能改善 END
	                newLead.Mans__c = roomAndGuest.room.RoomPaxMaleCount;
	                // 大人人員(女性)
                    // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                    if (isCanModifyPeoples && TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'Femails__c'))
                    // 2017/05/09 ネット取り込み、予約変更機能改善 END
	                newLead.Femails__c = roomAndGuest.room.RoomPaxFemaleCount;
	                // 子供A人数
                    // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                    if (isCanModifyPeoples && TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'ChildFA__c'))
                    // 2017/05/09 ネット取り込み、予約変更機能改善 END
	                newLead.ChildFA__c = roomAndGuest.room.RoomChildA70Count;
	                // 子供B人数
                    // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                    if (isCanModifyPeoples && TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'Childs__c'))
                    // 2017/05/09 ネット取り込み、予約変更機能改善 END
	                newLead.Childs__c = roomAndGuest.room.RoomChildB50Count;
	                // 子供C人数
                    // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                    if (isCanModifyPeoples && TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'ChildC__c'))
                    // 2017/05/09 ネット取り込み、予約変更機能改善 END
	                newLead.ChildC__c = roomAndGuest.room.RoomChildC30Count;
	                // 子供D人数
                    // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                    if (isCanModifyPeoples && TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'ChildD__c'))
                    // 2017/05/09 ネット取り込み、予約変更機能改善 END
	                newLead.ChildD__c = roomAndGuest.room.RoomChildDNoneCount;
                }
                //　予約インデックスID
                newLead.LeadIndexRef__c = leadIndex.Id;
                //if (newLead.LeadIndexRef__c == null) newLead.LeadIndexRef__c = leadIndex.Id;

                // 2015/12/11 予約取込機能改善（変更、キャンセル） BEGIN
                // 事前決済区分
            	// 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
            	if (TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'SettlementDiv__c'))
            	// 2017/05/09 ネット取り込み、予約変更機能改善 END
                newLead.SettlementDiv__c = CommUtils.nullToBlank(bookingInfo.risaplsinformation.agentNativeInformation.extendmytrip.SettlementDiv);
                // 予約番号
                newLead.BookingDataID__c = bookingDataId;
                // プラン自動展開対象外フラグ設定
                newLead.PlanSycnFlag__c = newLead.PlanSycnFlag__c == null ? true : !newLead.PlanSycnFlag__c;
                // 2015/12/11 予約取込機能改善（変更、キャンセル） END
                // 特記事項設定[一泊で2部屋以上の自動とりこみ予約のときは、特記事項を一つのみとする]
                //if (j == 0) {
                if(isHadLeadId){
                	// 2017/01/06 男女区分 「0」：男女区分なし、「1」：男女区分あり  BEGIN by zh
					//String commentMessage = newLead.Comment3__c + '<br/>' + warningMsg + bookingInfo.OtherServiceInformation;
					String commentMessage = newLead.Comment3__c + '<br/>' + warningMsg + genderDivMsg + bookingInfo.OtherServiceInformation;
					// 2017/01/06 男女区分 「0」：男女区分なし、「1」：男女区分あり  END by zh
					newLead.Comment3__c = CommLogUtils.removeOverLogString(commentMessage,commentLength);
					// メール本文
					newLead.email__c = CommLogUtils.removeOverLogString(risaplBasic.TelegramData + '\n' + CommUtils.nullToBlank(newLead.email__c),emailLength);
					// 2016/10/18 既存の予約情報の部屋は割当済すると、該当部屋タイプと情報は変更なしで対応する BEGIN
					//newLead.Rroom__c = null;
					// 2016/10/18 既存の予約情報の部屋は割当済すると、該当部屋タイプと情報は変更なしで対応する END
					// 2013/06/25 ADD 旅行会社名から予約チャネルに設定する
					// 2016/01/28 ネットからの取込時に予約チャネルに旅行会社名で設定する BEGIN
					//if(CommUtils.isBlank(newLead.Field2__c)) newLead.Field2__c = TraveCompany.size() > 1 ? TraveCompany[1].Name : TraveCompany[0].Name;
					// 2016/07/10 予約チャネル名の変換機能追加対応 BEGIN
					//if(CommUtils.isBlank(newLead.Field2__c)) newLead.Field2__c = TraveCompany.size() > 0 ? TraveCompany[0].Name : null;
                    // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                    if (TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'Field2__c'))
                    // 2017/05/09 ネット取り込み、予約変更機能改善 END
					if(CommUtils.isBlank(newLead.Field2__c)) newLead.Field2__c = chanelStr;
					// 2016/07/10 予約チャネル名の変換機能追加対応 END
					//TraveCompany.size() > 0 ? TraveCompany[0].Name : null;
					// 2016/01/28 ネットからの取込時に予約チャネルに旅行会社名で設定する END
                }else{
                	 // 2017/01/06 男女区分 「0」：男女区分なし、「1」：男女区分あり  BEGIN by zh
                     //newLead.Comment3__c = warningMsg + bookingInfo.OtherServiceInformation;
                     // 2017/09/01 最大文字数をこえない問題回避対応 BEGIN
                     //newLead.Comment3__c = warningMsg + genderDivMsg + bookingInfo.OtherServiceInformation;
                     newLead.Comment3__c = CommLogUtils.removeOverLogString(warningMsg + genderDivMsg + bookingInfo.OtherServiceInformation,commentLength);
                     // 2017/01/06 男女区分 「0」：男女区分なし、「1」：男女区分あり  END by zh
                     //newLead.email__c = risaplBasic.TelegramData;
                     newLead.email__c = CommLogUtils.removeOverLogString(risaplBasic.TelegramData,emailLength);
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
                
				// 部屋タイプID
                newLead.refTypeOfRooms__c = roomTypeMap.get(roomAndGuest.room.RoomTypeCode);
                // 2013/02/26 部屋タイプ名：部屋ID情報を格納する
                if (newLead.refTypeOfRooms__c == null ) newLead.refTypeOfRooms__c = roomTypeNmMap.get(roomAndGuest.room.RoomTypeName);
                // 2018/10/16 TL2way予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh BEGIN
                boolean chgRoomTypeFlag = TL_ServiceConfigHelp.getAppConfig(shopCd).chgRoomTypeFlag;
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
						// 2016/10/21 TL変更機能改善対応[到着日を変更すると、既に割当される部屋をクリアする] BEGIN
						if (orgLead.EntryTime__c.date() != newLead.EntryTime__c.date()) {
							// 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh BEGIN
							//newLead.Rroom__c = null;
							boolean chgdtRoomClearFlag = TL_ServiceConfigHelp.getAppConfig(shopCd).chgdtRoomClearFlag;
							// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ BEGIN
							//if(chgdtRoomClearFlag) newLead.Rroom__c = null;
							if(chgdtRoomClearFlag) {
								newLead.Rroom__c = null;
								newLead.Field276__c = false;
							}
							// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ END
							// 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh END
						}
						// 2016/10/21 TL変更機能改善対応[到着日を変更すると、既に割当される部屋をクリアする] END
						// 2016/09/17 TL連携在庫調整不具合対応 BEGIN
						// 2018/10/16 TL2way予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh BEGIN
						/*if (newLead.Rroom__c != null) {
							newLead.refTypeOfRooms__c = orgLead.refTypeOfRooms__c;
						}*/
						if(newLead.Rroom__c != null){
mLogUtils.write_log('----------------chgRoomTypeFlag=================' + chgRoomTypeFlag);
mLogUtils.write_log('----------------orgLead.Field276__c=================' + orgLead.Field276__c);
                        	// 部屋タイプを更新可能FLGはTRUE場合 AND 部屋変更不可フラグはFALSEの場合
                        	// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ BEGIN
                        	//if(chgRoomTypeFlag && !orgLead.Field276__c){
                        	// 部屋タイプ変更可のフラグがTRUEの場合
                        	if(chgRoomTypeFlag){
                        	// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ END
mLogUtils.write_log('----------------chgRoomTypeFlag1=================' + chgRoomTypeFlag);
mLogUtils.write_log('----------------orgLead.Field276__c1=================' + orgLead.Field276__c);
                            	// XMLの部屋タイプID
                            	Id newRoomTypeId = roomTypeMap.get(roomAndGuest.room.RoomTypeCode);
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
						}// if(newLead.Rroom__c != null){
						// 2018/10/16 TL2way予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh END
						// 2016/09/17 TL連携在庫調整不具合対応 END
						// 2016/10/18 既存の予約情報の部屋は割当済すると、該当部屋タイプと情報は変更なしで対応する END
					} //if(isHadLeadId){
					if (newLead.Rroom__c == null) {
	                    // 部屋自動割り振り機能
	                    if (autoAssingRoomflag) {
							// 2015/10/30 故障部屋は自動割当て機能に追加対応 BEGIN
	                        if (canAssignRoomMap.containsKey(idx)) {
	                        	newLead.Rroom__c = canAssignRoomMap.get(idx).Id;
	                        	mLogUtils.write_log('複数部屋自動割り当て部屋 :: ' + newLead.Rroom__c);
	                        }
							// 2015/10/30 故障部屋は自動割当て機能に追加対応 END
	                    }
	                    // 1部屋自動アサイン機能
	                    // 部屋タイプが存在　かつ　対応部屋タイプに対して、１部屋のみの場合、該当部屋は自動的に予約にアサインする BEGIN
	                    // 2016/10/26 部屋タイプと部屋が1対1の場合は故障部屋を割当される不具合改修 BEGIN

	                    else if (oneTypeToRoomMap.containsKey(newLead.refTypeOfRooms__c) && oneRoomCanAssignRoomMap.containsKey(idx)) {
	                    // 2016/10/26 部屋タイプと部屋が1対1の場合は故障部屋を割当される不具合改修 END
	                        newLead.Rroom__c = oneTypeToRoomMap.get(newLead.refTypeOfRooms__c);
	                        mLogUtils.write_log('1VS1部屋自動割り当て部屋 :: ' + newLead.Rroom__c);
	                    }
	                    // 部屋タイプが存在　かつ　対応部屋タイプに対して、１部屋のみの場合、該当部屋は自動的に予約にアサインする END
                    } // if (newLead.Rroom__c == null) {
                } // if (newLead.refTypeOfRooms__c != null)
                // 2016/10/21 TA変更機能改善対応[到着日を変更すると、既に割当される部屋をクリアする] BEGIN
                // 新規の部屋タイプはSF側に非存在　かつ　到着日へんこうされると、既存の予約の既に割り当てる部屋はクリアを行う
                else {
                    if(isHadLeadId){    
						if (orgLead.EntryTime__c.date() != newLead.EntryTime__c.date()) {
							// 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh BEGIN
							//newLead.Rroom__c = null;
							boolean chgdtRoomClearFlag = TL_ServiceConfigHelp.getAppConfig(shopCd).chgdtRoomClearFlag;
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
                	roomMaps.put(idx,setEachRoomBookingEstimeteItems(cloneItem,roomAndGuest,taxSericeFee,isRoomRateFlg,curPlan));
                } else {
                	// 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ BEGIN
                	if (isClearEstItemsFlag) roomMaps.put(idx,setEachRoomBookingEstimeteItems(cloneItem,roomAndGuest,taxSericeFee,isRoomRateFlg,curPlan));
                	else
                	// 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ END
                	roomMaps.put(idx, new List<BookingEstimateItem__c>());
                }
                //}
                // 2013/07/16 記号機能対応 BEGIN
                // 予約データは親部屋に集めるの場合
                //else 
                // 2017/01/09 親部屋集める:メール本文 fix BEGIN by zh
        		boolean mailDivFlag = TL_ServiceConfigHelp.getAppConfig(shopCd).mailDivFlag;
        		// 2017/01/09 親部屋集める:メール本文 fix END by zh
                if (j > 0 && CommConst.APPOTION_LEADSPLIT_DIV_CODE == CommConst.APPOTION_LEADSPLIT_DIV_CODE_UNION){
                    Integer roomIdx = i * rooms;
                    // 2016/08/31 不具合修正、親部屋の人数は０の場合、人数正常な合計できない不具合修正 BEGIN
					//insLeadLst[roomIdx].StayPersons__c += CommUtils.nullToZero(newLead.StayPersons__c);
                    // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                    if (stayPerponsChgFlg)
                    // 2017/05/09 ネット取り込み、予約変更機能改善 END   
                    insLeadLst[roomIdx].StayPersons__c = CommUtils.nullToZero(insLeadLst[roomIdx].StayPersons__c) + CommUtils.nullToZero(newLead.StayPersons__c);
                    // 新規　かつ　WARNメッセージ存在　かつ　次の部屋の人数が存在する場合 かつ　部屋情報が集める場合
                    if (CommUtils.nullToZero(newLead.StayPersons__c) > 0 
                    	&& bookingInfo.dmlAction == BI_TL_DmlAction.INS 
                    	&& CommUtils.nullToBlank(insLeadLst[roomIdx].comment3__c).contains(Label.MSG_038_0008)) {
                    	insLeadLst[roomIdx].comment3__c = CommUtils.nullToBlank(insLeadLst[roomIdx].comment3__c).replace(Label.MSG_038_0008, '');
                    }
                    // 2016/08/31 不具合修正、親部屋の人数は０の場合、人数正常な合計できない不具合修正 END
                    if (roomMaps.containsKey(idx)) {
                    	roomMaps.get(roomIdx).addAll(roomMaps.get(idx));
                    	roomMaps.remove(idx);
                    }
                    // 代表部屋以外のデータ
                    newLead.StayPersons__c = 0;
                    // 大人人員(男性)
                    // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                    if (isCanModifyPeoples && TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'Mans__c'))
                    // 2017/05/09 ネット取り込み、予約変更機能改善 END
                    insLeadLst[roomIdx].Mans__c += CommUtils.nullToZero(newLead.Mans__c); 
                    newLead.Mans__c = 0;
                    // 大人人員(女性)
                    // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                    if (isCanModifyPeoples && TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'Femails__c'))
                    // 2017/05/09 ネット取り込み、予約変更機能改善 END
                    insLeadLst[roomIdx].Femails__c += CommUtils.nullToZero(newLead.Femails__c); 
                    newLead.Femails__c = 0;
                    // 子供A人数
                    // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                    if (isCanModifyPeoples && TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'ChildFA__c'))
                    // 2017/05/09 ネット取り込み、予約変更機能改善 END
                    insLeadLst[roomIdx].ChildFA__c += CommUtils.nullToZero(newLead.ChildFA__c); 
                    newLead.ChildFA__c = 0;
                    // 子供B人数
                    // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                    if (isCanModifyPeoples && TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'Childs__c'))
                    // 2017/05/09 ネット取り込み、予約変更機能改善 END
                    insLeadLst[roomIdx].Childs__c += CommUtils.nullToZero(newLead.Childs__c); 
                    newLead.Childs__c = 0;
                    // 子供C人数
                    // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                    if (isCanModifyPeoples && TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'ChildC__c'))
                    // 2017/05/09 ネット取り込み、予約変更機能改善 END
                    insLeadLst[roomIdx].ChildC__c += CommUtils.nullToZero(newLead.ChildC__c); 
                    newLead.ChildC__c = 0;
                    // 子供D人数
                    // 2017/05/09 ネット取り込み、予約変更機能改善 BEGIN
                    if (isCanModifyPeoples && TL_ServiceConfigHelp.isSetupVal(chgfieldSet,'ChildD__c'))
                    // 2017/05/09 ネット取り込み、予約変更機能改善 END
                    insLeadLst[roomIdx].ChildD__c += CommUtils.nullToZero(newLead.ChildD__c); 
                    newLead.ChildD__c = 0;
                    // プラン情報 <- NULL
                    newLead.Field310__c = null;
                    // コメント
                    newLead.Comment3__c = null;
                    // 2017/01/09 親部屋集める:メール本文 fix BEGIN by zh
mLogUtils.write_log('mailDivFlag:::' + mailDivFlag);
                    if(mailDivFlag) newLead.email__c = null;
                    // 2017/01/09 親部屋集める:メール本文 fix END by zh
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
                // 2016/10/21 TL変更機能改善対応、項目値自動設定不具合改修 BEGIN
                /*
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
                */
                // 2016/10/21 TL変更機能改善対応、項目値自動設定不具合改修 END
                insLeadLst.add(newLead);
                // 2016/09/17 TL連携在庫調整不具合対応 BEGIN
            	if (orgLead != null) {
            		stockOrgLeadList.add(orgLead);
            		stockNewLeadList.add(newLead);
            		stockXmlRoomAndGuestList.add(roomAndGuest);
            	}
            	// 2016/09/17 TL連携在庫調整不具合対応 END
            }
            // Parent6の場合、外部LOOPを行わない
            //if (isParten6Flg) break;
            //roomNoIdx++;
        }
//System.debug(logginglevel.INFO, 'insLeadLst 3:::' + insLeadLst);
        // 見積り金額設定を行う「一件のみ設定する」
        insLeadLst[0].BridalDantaikei__c = bookingInfo.TotalAccommodationCharge;
        //update モード
        //if(isUpdateFlag) compareXmlDiff(insLeadLst[0],bookingInfo);
        List<Lead__c> updLeadLst = new List<Lead__c>();
//mLogUtils.write_log('userOrgLeadSet:::' + userOrgLeadSet);
        // 2016/09/17 TL連携在庫調整不具合対応 BEGIN
        List<Lead__c> updCancelOrgLeadst = new List<Lead__c>();
        // 2016/09/17 TL連携在庫調整不具合対応 END
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
                        // 2016/09/17 TL連携在庫調整不具合対応 BEGIN
                        updCancelOrgLeadst.add(childLst.get(i));
                        // 2016/09/17 TL連携在庫調整不具合対応 END
                    }
                }
            }
        }
        // 2017/08/15 ネット取込(TL2way)機能、変更通知（２泊→１泊に変更）が来た際に、子部屋２日目の夕食レストランの席がキャンセルできるように改善対応 BEGIN
mLogUtils.write_log('dayUnitChildrenMap:::' + dayUnitChildrenMap);
mLogUtils.write_log('dayUnitOrgLeadMap:::' + dayUnitOrgLeadMap);        
        if (dayUnitChildrenMap != null) {
	        for (Date dt : dayUnitChildrenMap.keySet()) {
	            // 変更前の予約情報を取得する[日付単位]
	            if (dayUnitOrgLeadMap.containsKey(dt)) {
	                List<Lead__c> wkOrgLeads = dayUnitOrgLeadMap.get(dt);
//mLogUtils.write_log('和子数据的予约时间匹配的主数据:::' + wkOrgLeads);
	                // 該当日の予約情報は全部キャンセルされる場合、該当日関連の子部屋データも自動キャンセルする
	                Boolean isAllCancelFlg = true;
	                for (Lead__c lead : wkOrgLeads) {
	                    if (lead.ReservedStatus__c !=  CommConst.LEAD_ST_CANCEL) {
	                        isAllCancelFlg = false;
	                        break;
	                    }
	                }
	                if (isAllCancelFlg) {
	                    List<Lead__c> wkChildLeads = dayUnitChildrenMap.get(dt);
//mLogUtils.write_log('子数据1:::' + wkChildLeads);
	                    for (Lead__c lead : wkChildLeads) {
	                        lead.ReservedStatus__c = CommConst.LEAD_ST_CANCEL;
	                        updLeadLst.add(lead);
//mLogUtils.write_log('updLeadLst1:::' + updLeadLst);
	                    }
	                    continue;
	                }
	                // 該当日の予約情報の到着日全部変更される かつ　変更後の日付は同じ日付の場合、該当日関連の子部屋データの到着日も自動変更を行う
	                Boolean isEntryDtAllChangeFlg = true;
	                set<Date> newDateSet = new Set<Date>();
	                for (Lead__c lead : wkOrgLeads) {
	                    // すでにキャンセルされた予約は対象外になる
	                    if (lead.ReservedStatus__c == CommConst.LEAD_ST_CANCEL) continue;
	                    Date currDt = lead.EntryTime__c.Date();
	                    newDateSet.add(currDt);
	                    if (currDt == dt) {
	                        isEntryDtAllChangeFlg = false;
	                        break;
	                    }
	                }
	                if (isEntryDtAllChangeFlg && newDateSet.size() == 1) {
	                    Date newDt = new List<Date>(newDateSet).get(0);
	                    List<Lead__c> wkChildLeads = dayUnitChildrenMap.get(dt);
//mLogUtils.write_log('子数据2:::' + wkChildLeads);
	                    for (Lead__c lead : wkChildLeads) {
	                        Time orgEntryTime = lead.EntryTime__c.time();
	                        Time orgDeparTime = lead.Departure__c.time();
	                        lead.EntryTime__c = DateTime.newInstance(newDt, orgEntryTime);
	                        lead.Departure__c = DateTime.newInstance(newDt, orgDeparTime);
	                        updLeadLst.add(lead);
//mLogUtils.write_log('updLeadLst2:::' + updLeadLst);
	                    }
	                    continue;
	                }
	            }
	        }
        }
        // 2017/08/15 ネット取込(TL2way)機能、変更通知（２泊→１泊に変更）が来た際に、子部屋２日目の夕食レストランの席がキャンセルできるように改善対応 END
        // 2016/09/17 TL連携在庫調整不具合対応 BEGIN
        if (leadIndex.StockLogicProcessFlg__c) {
	        if (!stockOrgLeadList.isEmpty()) {
	        	// 変更分の関連在庫情報処理
	        	checkChgOrgStockRoomByDmlAction(stockOrgLeadList,stockNewLeadList,stockXmlRoomAndGuestList, shopCode,bookingInfo.dmlAction,roomTypeMap,historyMap);
	        }
	        if (!updCancelOrgLeadst.isEmpty()) {
				// キャンセル前にTL経由で在庫変更履歴情報を取得する（予約情報単位）
				checkChgOrgStockRoomByDmlAction(updCancelOrgLeadst,new List<Lead__c>(),new BI_TL_RoomAndGuestInfo(),shopCode,BI_TL_DmlAction.CANCEL,new Map<String,Id>(),historyMap);
	        }
        }
		// 2017/05/04 店舗ごとの予約・会計権限機能対応 BEGIN
		CommLogicProcess logic = new CommLogicProcess();
		// 自動キャンセルされるデータのフラグはチェック対象外に設定する
		logic.preventShopAuthCheckSetup(updLeadLst);
		// 新規登録・変更対象データはチェック対象外に設定する
		logic.preventShopAuthCheckSetup(insLeadLst);
		// 2017/05/04 店舗ごとの予約・会計権限機能対応 END
        // 2016/09/17 TL連携在庫調整不具合対応 END
        // 電文から作成の予約に対して、変更後の予約情報の泊数対象外の予約はキャンセルに更新を行う
         // 2021/06/31 #JP10242対応 by zy BEGIN 
        filterExitBadRoom(insLeadLst);
        // 2021/06/31 #JP10242対応 by zy END
        update updLeadLst;
        // 2012/12/22 WSQ ADD
        // SUBINDEX自動作成
        // 2017/05/04 店舗ごとの予約・会計権限機能対応 BEGIN
        //CommLogicProcess logic = new CommLogicProcess();
        // 2017/05/04 店舗ごとの予約・会計権限機能対応 END
        logic.autoCreateIndexSub(insLeadLst);
//System.debug(logginglevel.INFO, 'insLeadLst:::' + insLeadLst);
		// 2017/05/23 ご予約項目値自動設定機能改善 BEGIN
		List<Lead__c> wkInsLeadList = new List<lead__c>();
		for (Lead__c lead : insLeadLst) { if (lead.id == null) wkInsLeadList.add(lead); }
		// 2017/05/23 ご予約項目値自動設定機能改善 END
        upsert insLeadLst;
		// 2017/05/23 ご予約項目値自動設定機能改善 BEGIN
		// デフォルト値項目設定あり予約情報を格納する
		map<Id, Lead__c> defaultValForceUpMap = new map<Id, Lead__c>();
		try {
			// 新規作成の予約情報から、自動設定項目が存在する場合、再度自動設定を行う
			if (!wkInsLeadList.isEmpty()) {
				list<TL_ServiceConfigHelp.ConditionInfo> autoSetupfieldList = TL_ServiceConfigHelp.getAppConfig(shopCd).defFieldConLst;
mLogUtils.write_log('autoSetupfieldList :: ' + autoSetupfieldList);
				if (!autoSetupfieldList.isEmpty()) {
					set<String> conDefFieldApiSet = new set<String>();
					for(TL_ServiceConfigHelp.ConditionInfo con : autoSetupfieldList) conDefFieldApiSet.add(con.defFieldApi);
					Map<String, Schema.DescribeFieldResult> conFinalFieldMap = CommUtils.getFieldMetaData(Lead__c.getSObjectType().getDescribe(),conDefFieldApiSet);
					// Id->LoopIndex
					map<id,Lead__c> wkInsLeadConvertMap = new map<Id,Lead__c>();
					for (Lead__c wkLead : wkInsLeadList) {
						wkInsLeadConvertMap.put(wkLead.id, wkLead);
					}
					set<id> wkNewLeadIds = wkInsLeadConvertMap.keySet();
					String wkConQueryHeader = 'select id from Lead__c where id in:wkNewLeadIds ';
					for (TL_ServiceConfigHelp.ConditionInfo con : autoSetupfieldList) {
	                    Schema.DescribeFieldResult describeField = conFinalFieldMap.get(con.defFieldApi);
//mLogUtils.write_log('con :: ' + con);
//mLogUtils.write_log('describeField :: ' + describeField);
                		if(describeField == null || !describeField.isCreateable()) continue;
						String wkConQuery = wkConQueryHeader + ' And ('+ con.condtion +') ';
						List<Lead__c> wkUpdLeads = DataBase.query(wkConQuery);
//mLogUtils.write_log('con.defFieldApi :: ' + wkConQuery);
//mLogUtils.write_log('wkUpdLeads :: ' + wkUpdLeads);
						for (Lead__c lead : wkUpdLeads) {
							Lead__c wkUpdLead = wkInsLeadConvertMap.get(lead.Id);
							wkUpdLead.put(con.defFieldApi,CommUtils.ConvByFielType(con.defFieldVal, describeField.getType()));
							mLogUtils.write_log('[条件あり]項目値自動設定[' + con.defFieldApi + ']::' + wkUpdLead.get(con.defFieldApi) );
							defaultValForceUpMap.put(wkUpdLead.Id, wkUpdLead);
						}
					}
				}
			}
		} catch (Exception e) {
mLogUtils.write_log('Exception :: ' + e.getStackTraceString());	
		}
		// 2017/05/23 ご予約項目値自動設定機能改善 END
//System.debug(logginglevel.INFO, 'roomMaps:::' + roomMaps);
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
        // ご予約のプラン項目から自動作成の見積明細を全部削除する
        delete [select id,name from BookingEstimateItem__c where refBooking__c =:leadIds and ParentBookingItemRef__c = null];
        delete [select id,name from BookingEstimateItem__c where refBooking__c = :leadIds ];
		// 変更の場合、支払情報は更新を行わない
		// 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ BEGIN
        //if (updateOrgLeadIdSet.isEmpty()) {
        if (updateOrgLeadIdSet.isEmpty() || isClearEstItemsFlag) {
        // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ END
			// 2016/06/09 取り込みの見積明細の順番は調整対応 BEGIN
			//見積もり明細　オプション作成する
			// 2017/08/15 option数据根据单价定义区分计算 fix BEGIN
			//lastInsItems.addAll(upsertBookingEstimeteItemsByEach(bookingInfo,insLeadLst[0]));
			lastInsItems.addAll(upsertBookingEstimeteItemsByEach(bookingInfo,insLeadLst[0],taxSericeFee));
			// 2017/08/15 option数据根据单价定义区分计算 fix END
			// 2016/06/09 取り込みの見積明細の順番は調整対応 END
	        //見積もり明細：支払い作成「ポイント・支払い」
	        // 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応 by zh BEGIN
	        //lastInsItems.addAll(upsertPaymentBookingExtimeItem(insLeadLst[0],bookingInfo));
	        // 異常ケースを回避対応      
	        if (payMediaLinkPos  >= insLeadLst.size()) payMediaLinkPos = 0;
	        lastInsItems.addAll(upsertPaymentBookingExtimeItem(insLeadLst[payMediaLinkPos],bookingInfo)); 
	        // 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応 by zh END
			// 2016/06/09 取り込みの見積明細の順番は調整対応 BEGIN
	        //見積もり明細　オプション作成する
	        //upsertBookingEstimeteItemsByEach(bookingInfo,insLeadLst[0]);
			// 2016/06/09 取り込みの見積明細の順番は調整対応 END
		}
		// 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
		List<Lead__c> proLeadLst = new List<Lead__c>();
		proLeadLst.addAll(updLeadLst);
		proLeadLst.addAll(insLeadLst);
		lastInsItems.addAll(CommLogicProcess.getBathTaxBookEstLst(proLeadLst, lastInsItems, oldLeadLst));
        // 2020/07/30 入湯税の自動入力機能について改善 WGCH END
		// 2016/06/09 取り込みの見積明細の順番は調整対応 BEGIN
		(new CommLogicProcess()).sync2wayEstRowNoSetup(insLeadLst, lastInsItems);
		// 2016/06/09 取り込みの見積明細の順番は調整対応 END 
		// 2017/05/04 店舗ごとの予約・会計権限機能対応 BEGIN
		List<Lead__c> restoreLeads = new List<Lead__c>();
		restoreLeads.addAll(updLeadLst);
		restoreLeads.addAll(insLeadLst);
		logic.restoreShopAuthCheckSetup(restoreLeads, true);
		// 2017/05/04 店舗ごとの予約・会計権限機能対応 END
		// 2017/05/23 ご予約項目値自動設定機能改善 BEGIN
		// 自動更新がなかったの場合、個別更新処理を行う
		if (!defaultValForceUpMap.isEmpty() && !CommConst.ShopEditAuthCheckFlg) {
			update defaultValForceUpMap.values();
		}
		// 2017/05/23 ご予約項目値自動設定機能改善 END
        mLogUtils.write_method_end();
    }
    /*
    private void compareXmlDiff(Lead__c firstLead,BI_TL_SyncInfo bookingInfo){
        mLogUtils.write_method_start('compareXmlDiff');
        List<Attachment> rsAtt = [select Name,Body,ParentId from attachment where parentId = :firstLead.LeadIndexRef__c];
        if(!rsAtt.isEmpty()){
            Map<String,String> labelToNameMap = new Map<String,String>();
            labelToNameMap.put('CheckInDate','チェックイン日');
            labelToNameMap.put('Nights','宿泊日数');
            labelToNameMap.put('GrandTotalPaxCount','お客様総合計人数');
            labelToNameMap.put('MealCondition','食事条件');
            labelToNameMap.put('TaxServiceFee','税サ区分');
            labelToNameMap.put('RoomRateOrPersonalRate','料金区分');
            labelToNameMap.put('Payment','支払い方法');
//mLogUtils.write_log('labelToNameMap：' + labelToNameMap);
            TL_ParseXmlToBookingInfoCtrl parseXmlCtrl = new TL_ParseXmlToBookingInfoCtrl(); 
            TL_LeadInfoSync.BI_TL_SyncInfo oldBookingInfo = parseXmlCtrl.parseByNode(rsAtt[0].Body.toString(),'BasicInformation,BasicRateInformation');
            String compareLogStr = '---------------------変更内容---------------------------------------';
            compareLogStr += getChangeMessage(oldBookingInfo,bookingInfo,labelToNameMap);
           	compareLogStr += '-------------------------------------------------------------------';
//mLogUtils.write_log('更新内容::' + compareInfo);  
			firstLead.Comment3__c = CommLogUtils.removeOverLogString(firstLead.Comment3__c + compareLogStr,Lead__c.Comment3__c.getDescribe().getLength());
        }
        mLogUtils.write_method_end();
    }
    */
    /*
    // 金額自動設定モードる
    // estList: 配分金額対象リスト
    // diffUnit:　差分金額
    // isOrderCal: 順番調整
    private Decimal divisionEstUnitPrice(BookingEstimateItem__c orgPlanItem, List<BookingEstimateItem__c> estList, Decimal diffUnit, Boolean isOrderCal) {
        mLogUtils.write_method_start('divisionEstUnitPrice');
        // 小数点区分
        Integer pointLen = CommUtils.getPointLen(); 
        BookingEstimateItem__c maxItem = null;
        Decimal diffUnitSum = 0;
        // 明細に金額を反映を行う
        for (BookingEstimateItem__c est : estList) {
            // 空値存在があります
            if (est == null) continue;
            // 増額処理の場合
            if (diffUnit > 0) {
                // 該当明細は室料の場合、残りの残料金は残部自動設定を行う
                if (isRoomRateItem(est)) {
                    // 差分金額は全部室料に設定する
                    diffUnitSum = diffUnit;
                    est.UnitPrice__c += diffUnit;
                    break;
                }
                // 室料以外の場合、課税明細に比率により、金額自動配分する
                Decimal addUnitPriceRate = CommUtils.RoundProcess(est.UnitPrice__c / orgPlanItem.UnitPrice__c * diffUnit , pointLen);
                //if(diffUnit < addUnitPrice) addUnitPrice = diffUnit;
                est.UnitPrice__c += addUnitPriceRate;
                // 最大値項目を格納する
                if (maxItem == null) maxItem = est;
                else if (maxItem.UnitPrice__c > est.UnitPrice__c) maxItem = est;
                // 既に調整金額を設定する
                diffUnitSum += addUnitPriceRate;
            }
            // 差分額は減額の場合
            else {
                // 順次に減算を行う
                if (isOrderCal) {
                    // ロジック処理注意！！！
                    Decimal calDiff = diffUnit + est.UnitPrice__c;
                    diffUnitSum -= est.UnitPrice__c;
                    if (calDiff < 0) {
                        diffUnit = calDiff;
                        est.UnitPrice__c = 0;
                    } else {
                        // 減算処理完了
                        diffUnit = 0;
                        est.UnitPrice__c = calDiff;
                        return diffUnit;
                    }
                    
                } else {
                    // 該当明細は室料の場合、残りの残料金は残部自動設定を行う
                    if (isRoomRateItem(est)) {
                        // 室料から減額処理
                        // 減額後の金額は０以下の場合、０まで室料に反映を行う
                        est.UnitPrice__c += diffUnit;
                        if (est.UnitPrice__c < 0) {
                            Decimal absPrice = math.abs(est.UnitPrice__c);
                            est.UnitPrice__c = 0;
                            diffUnit += absPrice;   // 室料は０円に設定、減算後の金額は差分金額に反映
                        }
                        continue;
                    }
                    // 室料以外の場合、課税明細に比率により、金額自動配分する
                    Decimal addUnitPriceRate = CommUtils.RoundProcess(est.UnitPrice__c / orgPlanItem.UnitPrice__c * diffUnit , pointLen);
                    //if(diffUnit < addUnitPrice) addUnitPrice = diffUnit;
                    est.UnitPrice__c += addUnitPriceRate;
                    // 最大値項目を格納する
                    if (maxItem == null) maxItem = est;
                    else if (maxItem.UnitPrice__c > est.UnitPrice__c) maxItem = est;
                    // 既に調整金額を設定する
                    diffUnitSum += addUnitPriceRate;
                }
            }
        }
        
        mLogUtils.write_method_end();
        return diffUnitSum - diffUnit;
    }
    
    private Boolean isRoomRateItem(BookingEstimateItem__c est) {
        return RackRateUtils.isRoomRateProduct(new AccountMaster__c(ActionType__c = est.ActionType__c));
    }*/
    // プラン明細に室料するがどうか判断ロジック
    private static Boolean isRoomRateItem(AccountMaster__c acc) {
        return RackRateUtils.isRoomRateProduct(acc);
    }
	// 2016/07/10 予約チャネル名の変換機能追加対応 BEGIN
	private string getChanelStr(BI_TL_SyncInfo bookingInfo, list<account> TraveCompany) {
		BI_TL_RisaplBasic risaplBasic = bookingInfo.risaplsinformation.risaplsCommonInformation.risaplBasic;
        String agtCode = CommUtils.nullToBlank(risaplBasic.SalesOfficeCompanyCode);
        String chanelStr = TL_ServiceConfigHelp.getMapAgtToChanelConfig(shopCd).get(agtCode);
		if (CommUtils.isBlank(chanelStr)) chanelStr = (!TraveCompany.isEmpty() ? TraveCompany[0].Name : null);
		return chanelStr;
	}
    // 2016/07/10 予約チャネル名の変換機能追加対応 END
    // ポイント、売掛金、カードなど事前支払情報は見積明細に反映を行う
    private List<BookingEstimateItem__c> upsertPaymentBookingExtimeItem(Lead__c lead,BI_TL_SyncInfo bookingInfo){
        mLogUtils.write_method_start('upsertPaymentBookingExtimeItem');
        BI_TL_Risaplsinformation risaplsinformation = bookingInfo.risaplsinformation;
        // 合計宿泊料金(総額)
        Decimal totalPrice = bookingInfo.TotalAccommodationCharge;
        BI_TL_BasicRate basicRate = risaplsinformation.risaplsCommonInformation.basicRate;
        BI_TL_Member member = risaplsinformation.risaplsCommonInformation.member;
        BillSimpleHelp help = new BillSimpleHelp(shopCd);
        // ポイント合計金額格納
        Decimal pointAmount = 0;
        // 新規追加プランデータ存在する場合
        List<BookingEstimateItem__c> insLst = new List<BookingEstimateItem__c>();
        // ポイント支払情報格納する
        List<BookingEstimateItem__c> pointLst = new List<BookingEstimateItem__c>();
        if(basicRate != null) {
        	// 2016/03/28 じゃらんAGTのポイントとクーポンをそれそのまま取り込み対応 BEGIN
            set<string> pointNmSet = new set<string>();
            // 2017/09/04 pointsDiscountLst没有值 报错return null object fix BEGIN
            if(basicRate.pointsDiscountLst == null) basicRate.pointsDiscountLst = new List<TL_LeadInfoSync.BI_TL_PointsDiscountInfo>();
            // 2017/09/04 pointsDiscountLst没有值 报错return null object fix END
            for (TL_LeadInfoSync.BI_TL_PointsDiscountInfo pointsInfo : basicRate.pointsDiscountLst) {
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
            // 2017/10/09 ポイント取込はうまくと、見積明細商品名称は会計商品名またはタグ値で切替設定できるよに改善対応 by zh BEGIN
            boolean sfPointNmFlag = TL_ServiceConfigHelp.getAppConfig(shopCd).sfPointNmFlag;
            // 2017/10/09 ポイント取込はうまくと、見積明細商品名称は会計商品名またはタグ値で切替設定できるよに改善対応 by zh END
            for (TL_LeadInfoSync.BI_TL_PointsDiscountInfo pointsInfo : basicRate.pointsDiscountLst) {
                //BI_TL_PointsDiscountInfo pointsInfo = basicRate.pointsDiscountLst.get(i);
                if(pointsInfo.PointsDiscount <= 0) continue;
                mLogUtils.write_log('BASIC POINT::' + pointsInfo);
                // 2016/03/28 じゃらんAGTのポイントとクーポンをそれそのまま取り込み対応 BEGIN
                //pointLst.add(new BookingEstimateItem__c (
                BookingEstimateItem__c est = new BookingEstimateItem__c (
                // 2016/03/28 じゃらんAGTのポイントとクーポンをそれそのまま取り込み対応 END
                  refBooking__c = lead.id,
                  // 2017/10/09 ポイント取込はうまくと、見積明細商品名称は会計商品名またはタグ値で切替設定できるよに改善対応 by zh BEGIN
                  ProductName__c = sfPointNmFlag ? pointsInfo.PointsDiscountName : null,
                  // 2017/10/09 ポイント取込はうまくと、見積明細商品名称は会計商品名またはタグ値で切替設定できるよに改善対応 by zh END
                  UnitPrice__c = pointsInfo.PointsDiscount,
                  // 2020/09/15 OTAからの予約取り込み時に「楽天ポイント」と「楽天クーポン」が分かれて取り込みできる WGCH BEGIN
                  // 初期设定 「暂时寄存值」
                  X1__c = pointsInfo.PointsDiscountName,
                  // 2020/09/15 OTAからの予約取り込み時に「楽天ポイント」と「楽天クーポン」が分かれて取り込みできる WGCH END
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
			// 2016/06/10 事前処理区分は０は除外から「現地払い」と認識で対応する
			//if (intSettlementDiv != null && intSettlementDiv != 0) settlementDiv = Commutils.nullToBlank(intSettlementDiv);
			if (intSettlementDiv != null) settlementDiv = Commutils.nullToBlank(intSettlementDiv);
		}
		String agtCode = CommUtils.nullToBlank(bookingInfo.SalesOfficeCompanyCode);
		list<string> equalKeyLst = getEqualsKeyLst(settlementDiv, agtCode);
 		map<string, AccountMaster__c> payProductIdMap = new map<String, AccountMaster__c>();
 		map<String, TL_ServiceConfigHelp.PAYMENT_CONVERT> paymentConfigMap = TL_ServiceConfigHelp.getPaymentConfig(shopCd);
 		map<String, TL_ServiceConfigHelp.PAYMENT_CONVERT> pointConfigMap = TL_ServiceConfigHelp.getPointConfig(shopCd);
    	list<string> productCdlst = new list<string>();
    	for (TL_ServiceConfigHelp.PAYMENT_CONVERT parserPay : paymentConfigMap.values()) {
    		productCdlst.add(parserPay.payProdCode);
    	}
    	for (TL_ServiceConfigHelp.PAYMENT_CONVERT parserPay : pointConfigMap.values()) {
    		productCdlst.add(parserPay.payProdCode);
    	}
    	if (!productCdlst.isEmpty()) {
    		payProductIdMap = TL_ServiceConfigHelp.getPaymentProductId(productCdlst);
    	}
// 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う END
        // ポイント支払情報が存在する場合
        if (pointAmount>0) {
            // ポイント支払メデイア情報を取得する
            AccountMaster__c pointAcc = help.getMediaLabToAccMstMap().get(help.getPaymentTypeToMediaLabMap().get(CommConst.PROD_PAY_TYPE_DIS_PRICE));
            if (pointAcc != null) {
                for (BookingEstimateItem__c est : pointLst) {
                	// 2016/03/28 じゃらんAGTのポイントとクーポンをそれそのまま取り込み対応 BEGIN
                	// 2020/09/15 OTAからの予約取り込み時に「楽天ポイント」と「楽天クーポン」が分かれて取り込みできる WGCH BEGIN
                	// if (est.refAccountMaster__c != null) continue;
                	AccountMaster__c covertAcc2 = null;
                	// 2020/09/15 OTAからの予約取り込み時に「楽天ポイント」と「楽天クーポン」が分かれて取り込みできる WGCH END
                	// 2016/03/28 じゃらんAGTのポイントとクーポンをそれそのまま取り込み対応 END
// 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う BEGIN
                	AccountMaster__c covertAcc = null;
                	for (String key : equalKeyLst) {
mLogUtils.write_log('割引MATCH:' + KEY + '=' + pointConfigMap.containsKey(key));
                		if (pointConfigMap.containsKey(key)) {
                			TL_ServiceConfigHelp.PAYMENT_CONVERT convertInf = pointConfigMap.get(key);
                			covertAcc = payProductIdMap.get(convertInf.payProdCode);
                			// 2020/09/15 OTAからの予約取り込み時に「楽天ポイント」と「楽天クーポン」が分かれて取り込みできる WGCH BEGIN
                			// pointNameKey合成
                			String key2 = key + '_' + CommUtils.nullToBlank(est.X1__c);
                			// 优先级重置设定
                			if(pointConfigMap.containsKey(key2)){
                				convertInf = pointConfigMap.get(key2);
                				covertAcc2 = payProductIdMap.get(convertInf.payProdCode);
                			}
                			// 2020/09/15 OTAからの予約取り込み時に「楽天ポイント」と「楽天クーポン」が分かれて取り込みできる WGCH END
                			break;
                		}
                	}
                	// 2020/09/15 OTAからの予約取り込み時に「楽天ポイント」と「楽天クーポン」が分かれて取り込みできる WGCH BEGIN
                	// SF环境内存在相同名字的会计商品 && ponitNameAcc不存在
                	if (est.refAccountMaster__c != null && covertAcc2 == null) continue;
                	// 优先级置换会计商品
                	covertAcc = covertAcc2 == null ? covertAcc : covertAcc2;
                	if(covertAcc != null) est.ProductName__c = covertAcc.Name;
                	// 2020/09/15 OTAからの予約取り込み時に「楽天ポイント」と「楽天クーポン」が分かれて取り込みできる WGCH END
                	// 指定の割当
                    est.refAccountMaster__c = covertAcc == null ? pointAcc.Id : covertAcc.Id;
                    est.refAccountMaster__r = covertAcc == null ? pointAcc : covertAcc;
// 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う END
                }
            }
            // 2020/09/15 OTAからの予約取り込み時に「楽天ポイント」と「楽天クーポン」が分かれて取り込みできる WGCH BEGIN
            SYSTEM.DEBUG(LOGGINGLEVEL.INFO, 'pointLst:BEG='+pointLst);
            for(BookingEstimateItem__c est : pointLst){
            	// 重置初期设定「暂时寄存值」
            	est.X1__c = null;
            }
            SYSTEM.DEBUG(LOGGINGLEVEL.INFO, 'pointLst:END='+pointLst);
            // 2020/09/15 OTAからの予約取り込み時に「楽天ポイント」と「楽天クーポン」が分かれて取り込みできる WGCH END
            if (!pointLst.isEmpty()) insLst.addAll(pointLst);
        }
        // 事前決済区分により、支払情報の作成
        if(risaplsinformation.agentNativeInformation != null){
            BI_TL_Extendmytrip trip = risaplsinformation.agentNativeInformation.extendmytrip;
// 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う BEGIN
            AccountMaster__c commAcc = null;
    		for (String key : equalKeyLst) {
mLogUtils.write_log('事前決済MATCH:' + KEY + '=' + paymentConfigMap.containsKey(key));
        		if (paymentConfigMap.containsKey(key)) {
        			TL_ServiceConfigHelp.PAYMENT_CONVERT convertInf = paymentConfigMap.get(key);
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
        mLogUtils.write_method_end();
        // 割引、支払情報を新規作成する
        return insLst;
    }
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
    
    // 指定部屋、指定日の見積明細情報を登録する
    // item:該当日の予約の見積明細作成元
    // 
    // 
    private List<BookingEstimateItem__c> setEachRoomBookingEstimeteItems(   BookingEstimateItem__c item, 
                                                                            BI_TL_RoomAndGuestInfo roomAndGuest,
                                                                            Integer taxSericeFee,
                                                                            Boolean isRoomRateFlg,
                                                                            Plan__c pCurPlan){
        mLogUtils.write_method_start('setEachRoomBookingEstimeteItems');
mLogUtils.write_log('BookingEstimateItem__c:' + item);
mLogUtils.write_log('roomAndGuest:' + roomAndGuest);
mLogUtils.write_log('taxSericeFee:' + taxSericeFee);
mLogUtils.write_log('isRoomRateFlg:' + isRoomRateFlg);
mLogUtils.write_log('curPlan:' + pCurPlan);
        List<BI_TL_RoomRateInfomation> roomRateLst = roomAndGuest.roomRateLst;
        List<BookingEstimateItem__c> detailLst = new List<BookingEstimateItem__c>();
        if (item == null) return detailLst;
        // 料金設定情報がありません
        if (roomRateLst.isEmpty()) return detailLst;
        // 人員単価金額で総計利用金額を計算を行う
        BI_TL_RoomsInfo room = roomAndGuest.room;
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
                BI_TL_RoomRateInfomation roomRate = roomRateLst[i];
                if(i == 0) lastRateFlag = true;
                // 2016/06/10 子供料金プラン取り込み機能対応 BEGIN
    	        // 大人料金
	            Decimal perPaxRate = CommUtils.nullToZero(roomRate.PerPaxRate);
				// 2016/06/10 子供料金プラン取り込み機能対応 END
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
        	for(BI_TL_RoomRateInfomation roomRate : roomRateLst){
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
		    		// 2019/09/15 軽減税率機能対応 WGCH BEGIN
		    		// プラン元金額から非課税金額を外す
		    		if(isReducedTaxFlg){
		    			curnPayPrice = CommUtils.nullToZero(estUnitPriceEnd) - CommUtils.nullToZero(locPlanDetailInf.priceNoTaxSumValEnd);
		    			orgPlanPrice = CommUtils.nullToZero(locPlanDetailInf.curnPayPriceEnd);
		    		}
		    		// 2019/09/15 軽減税率機能対応 WGCH END
                    // 2016/06/10 子供料金プラン取り込み機能対応 END
                    mLogUtils.write_log('元のプラン金額は調整後：' + orgPlanPrice);
                    mLogUtils.write_log('元の利用金額は調整後：' + curnPayPrice);
                }
                // 2019/09/15 軽減税率機能対応 WGCH BEGIN
                else if(isReducedTaxFlg){
                	curnPayPrice = CommUtils.nullToZero(estUnitPriceEnd) - CommUtils.nullToZero(locPlanDetailInf.priceNoTaxSumValEnd);
                	orgPlanPrice = CommUtils.nullToZero(locPlanDetailInf.curnPayPriceEnd);
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
				// 2016/06/10 子供料金プラン取り込み機能対応 BEGIN
               	//if (orgPlanPrice != curnPayPrice) bookingItem.PlanDetailSyncInfo__c = getPlanDetailSyncInfo(orgPlanPrice,curnPayPrice);
				if (orgPlanPrice != curnPayPrice) bookingItem.PlanDetailSyncInfo__c = getPlanDetailSyncInfo(orgPlanPrice,curnPayPrice,locPlanDetailInf);
                // 2016/06/10 子供料金プラン取り込み機能対応 END
		//}
                mLogUtils.write_log('プラン明細個別設定情報 ：' + bookingItem.PlanDetailSyncInfo__c);
            }
        }
        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
        if(ldInfo != null){
        	detailLst = ProductItemUtils.getNwDetailLst(detailLst, ldInfo);
        }
        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
        for(BI_TL_RoomRateInfomation roomRate : roomRateLst){
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
        for(TL_ServiceConfigHelp.Item excludeItem : bookingConfig.excludeLst){
            if(!CommUtils.isBlank(excludeItem.fieldName)){
                for(String value : excludeItem.values){
//mLogUtils.write_log('excludeItem['+value+']：' + getFieldValue(acc,excludeItem.fieldName)); 
                    if(getFieldValue(acc,excludeItem.fieldName) == value) return BI_FILTER_STATUS.EXCLUDE;
                }
            }
        }
        for(TL_ServiceConfigHelp.Item includeItem : bookingConfig.includeLst){
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
    private String getPlanDetailSyncInfo(Decimal orgUnitPrice,Decimal curUnitPrice, PlanDetailInfo planDetailInf){
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
    //private List<BookingEstimateItem__c> upsertBookingEstimeteItemsByEach(BI_TL_SyncInfo bookingInfo,Lead__c insLead){
    private List<BookingEstimateItem__c> upsertBookingEstimeteItemsByEach(BI_TL_SyncInfo bookingInfo,Lead__c insLead, Integer taxSericeFee){
    // 2017/08/15 option数据根据单价定义区分计算 fix END
    	// オプション新規作成明細情報を格納する
        List<BookingEstimateItem__c> newOptList = new List<BookingEstimateItem__c>();
        
        mLogUtils.write_method_start('upsertBookingEstimeteItemsByEach');
        if(bookingInfo.risaplsinformation.risaplsCommonInformation.option == null || bookingInfo.risaplsinformation.risaplsCommonInformation.option.isEmpty()) {
            mLogUtils.write_method_end();
            return newOptList;
        }
        mLogUtils.write_log('option::' + bookingInfo.risaplsinformation.risaplsCommonInformation.option);
        
        // オプション商品が存在する場合
        List<BI_TL_Option> optionLst = bookingInfo.risaplsinformation.risaplsCommonInformation.option;
        // オプション商品コード　名を格納する
        set<String> prodCodeSet = new set<String>();
        set<String> prodNameSet = new set<String>();
        for(BI_TL_Option option : optionLst){
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
        for(BI_TL_Option option : optionLst) {
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
            BookingEstimateItem__c bookingItem = new BookingEstimateItem__c (
                        refAccountMaster__c = existAcc.id,
                        refAccountMaster__r = existAcc,
                        Amount__c = productCount,
                        UnitPrice__c = unitPriceOptionRate,
                        ProductName__c = existAcc.Name,
                        refBooking__c = insLead.id
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
        mLogUtils.write_method_end();
        return newOptList;
    }
    
    /**
    * 代表者として、取引先責任者作成する
    **/
    private Contact upsertContact(BI_TL_SyncInfo bookingInfo ,Lead__c firstLead) {
        mLogUtils.write_method_start('upsertContact');
        // 2013.07.12 ADD 申込者と申込電話は予約に設定する
        // 予約者情報
        BI_TL_Member member = bookingInfo.risaplsinformation.risaplsCommonInformation.member;
        String applicantName = member != null ? member.UserName : null;     // 申込者
        String applicantPhone = member != null ? member.UserTel : null;     // 申込者電話
        // 代表者情報
        BI_TL_RisaplBasic risaplBasic = bookingInfo.risaplsinformation.risaplsCommonInformation.risaplBasic;
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
        
        // 2016/03/28 誕生日と携帯電話情報解析と取込 BEGIN
        Date birthDay = null;
        String moibelPhone = null;   
        List<TL_ServiceConfigHelp.CONTACT_INFO_PARSE> parseDefList = TL_ServiceConfigHelp.getContactConfig(shopCd);   
        // AGTコード
    	string agtCode = bookingInfo.SalesOfficeCompanyCode;
        // 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ BEGIN
        boolean conAlwaysNewFlg = TL_ServiceConfigHelp.getAppConfig(shopCd).contactAlwaysNew;
        // XMLタグがTRUEかつ新規予約の場合、お客様情報は常に新規作成する
        conAlwaysNewFlg = conAlwaysNewFlg && (bookingInfo.dmlAction == BI_TL_DmlAction.INS);
        // 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ END
        for (TL_ServiceConfigHelp.CONTACT_INFO_PARSE parseInf : parseDefList){

        	//String keyword = parseInf.keyWordCd;
			//String format = parseInf.formatCd;
			// メール本文から解析を行う
        	String telegramData = risaplBasic.TelegramData;
        	
        	String[] keyWordLst = parseInf.keyWordCd.split(';');
        	String[] formatLst = parseInf.formatCd.split(';');
        	
        	set<string> agtCodeSet = CommUtils.isBlank(parseInf.agtCodes) ? new set<String>() : new set<String>(parseInf.agtCodes.split(','));
        	set<string> excludeKeySet = CommUtils.isBlank(parseInf.excludeVal) ? new set<String>() : new set<String>(parseInf.excludeVal.split(','));
    		// 該当規則は該当AGTへ適応しない場合、次の規則を実施する
    		if (!agtCodeSet.isEmpty() && !agtCodeSet.contains(agtCode)) continue;
        	for (String keyword : keyWordLst) {
mLogUtils.write_log('keyword：' + keyword);
        		// メール本文に該当KEYWORD情報が存在する場合
        		if (telegramData.contains(keyword)) {
        			String parseTxt = telegramData.substringAfter(keyword);
        			// 2016/06/22 住所など読み込み拡張機能 BEGIN
        			if (!CommUtils.isBlank(parseInf.endKey)) {
        				if (parseInf.endKey == '\\n') parseTxt = parseTxt.substringBefore('\n');
        				else if (parseInf.endKey == '<' || parseInf.endKey == '&lt;') parseTxt = parseTxt.substringBefore('<');
        				else if(parseTxt.indexOf(parseInf.endKey) >= 0){
							integer endIdx = parseTxt.indexOf(parseInf.endKey);
							parseTxt = parseTxt.substring(0,endIdx);
						}
        			}
				// 2016/06/22 住所など読み込み拡張機能 END
        			for (String formatStr : formatLst) {
        				Pattern p=Pattern.compile(formatStr);
        				Matcher m=p.matcher(parseTxt);  
        				if(m.find()){
        				 	// 指定の項目により、変換を行う
        				 	if (parseInf.tofieldCd == 'Contact.Birthday') {
				        	 	String year = m.group(1); 
				        	 	String month = m.group(2); 
				        	 	String day = m.group(3); 
				        	 	Date locBirthDay = Date.newInstance(Integer.valueOf(year), Integer.valueof(month), Integer.valueof(day));
				        	 	Boolean excludeFlg = false;
				        	 	// 指定の個別チェック項目が存在チェック
				        	 	if (!excludeKeySet.isEmpty()) {
				        	 		for (String dtStr : excludeKeySet) {
				        	 			Date excludeDt = CommUtils.stringToDate(dtStr);
				        	 			if (excludeDt != null && excludeDt == locBirthDay) {
				        	 				excludeFlg = true;
mLogUtils.write_log('取込除外:::' + excludeDt);
				        	 				break;
				        	 			}
				        	 		}
				        	 	}
				        	 	// 2016/07/10 予約チャネル名の変換機能追加対応 BEGIN
				        	 	Boolean v = CommUtils.isBirthday(Integer.valueOf(year),Integer.valueof(month), Integer.valueof(day));
				        	 	if (!v) continue;
				        	 	// 2016/07/10 予約チャネル名の変換機能追加対応 END
				        	 	if (!excludeFlg) birthDay = locBirthDay;
        				 	} else if (parseInf.tofieldCd == 'Contact.Phone') {				 		
        				 		String locMoibelPhone = m.group(1); 
        				 		String equMoibelPhone = locMoibelPhone.replaceAll('-', '' ).deleteWhitespace();
mLogUtils.write_log('携帯PARSE：' + locMoibelPhone);
								Boolean excludeFlg = false;
				        	 	// 指定の個別チェック項目が存在チェック
				        	 	if (!excludeKeySet.isEmpty()) {
				        	 		for (String phoneStr : excludeKeySet) {
				        	 			if (phoneStr.replaceAll('-', '' ) == equMoibelPhone) {
				        	 				excludeFlg = true;
mLogUtils.write_log('取込除外:::' + equMoibelPhone);
				        	 				break;
				        	 			} 
				        	 		}
				        	 	}
				        	 	if (!excludeFlg) {
				        	 		if (equMoibelPhone.length() == 11) locMoibelPhone = equMoibelPhone.substring(0,3) + '-' + equMoibelPhone.substring(3,7) + '-' + equMoibelPhone.substring(7,11);
				        	 		moibelPhone = locMoibelPhone;
				        	 	}
        				 	} else if (parseInf.tofieldCd == 'Contact.MailingAddress') {
        				 		Integer size = m.groupCount();	
        				 		if (size == 2) {
        				 			if (CommUtils.isBlank(risaplBasic.PostalCode)) risaplBasic.PostalCode = m.group(1);
        				 			if (CommUtils.isBlank(risaplBasic.Address)) risaplBasic.Address = m.group(2);
        				 		}
        				 	}
        				 	break;
						} // if(m.find()){
        			}
        		}
        	}     
        }
        if (CommUtils.isBlank(phoneNumber) && !CommUtils.isBlank(moibelPhone)) phoneNumber = moibelPhone;
        // 2016/03/28 誕生日と携帯電話情報解析と取込 END

        //usePointFlg;
     	//userUsePoint;
        // 顧客様名と顧客様電話番号で、既存データ存在チェックを行う
        List<Contact> existCList = null;
        if(bookingInfo.dmlAction == BI_TL_DmlAction.UPD && firstLead != null){
        	String contactId = firstLead.Relcontact__c;
        	existCList = [select LastName,FirstName,Name1__c,KanaName1__c,Katakana__c,Phone,Email,MailingPostalCode,MailingStreet,
        							ApplicantName__c,ApplicantPhone__c,Birthdate,MobilePhone from Contact where id = :contactId];
            if(!existCList.isEmpty()) {
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
                // 2018/04/19 氏名変更のみケース対応 BEGIN
                if (bookingInfo.isUpdForName) {
                    Contact c = existCList[0];
		            c.LastName =  lastName;
		            c.FirstName = firstName;
		            // 団体名または代表者氏名 漢字
		            c.Name1__c = bookingInfo.GuestOrGroupNameKanjiName;
		            // 団体名または代表者氏名よみがな(全角)
		            c.KanaName1__c = bookingInfo.GuestOrGroupNameSingleByte;
		            // ひらがな ←　団体名または代表者氏名よみがな(全角)
		            c.Katakana__c = bookingInfo.GuestOrGroupNameDoubleByte;
                    isChange = true;
                }
                // 2018/04/19 氏名変更のみケース対応 END
                //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH BEGIN 
	            // 団体名または代表者氏名 漢字
	            if(CommUtils.isBlank(existCList[0].Name1__c) && !CommUtils.isBlank(contactNameKanji)) {
	            	existCList[0].Name1__c = contactNameKanji;
	            	isChange = true;
	            }
	            // 団体名または代表者氏名よみがな(半角)
	            if(CommUtils.isBlank(existCList[0].KanaName1__c) && !CommUtils.isBlank(contactNameKana)) {
	            	existCList[0].KanaName1__c = contactNameKana;
	            	isChange = true;
	            }
	            // ひらがな ←　団体名または代表者氏名よみか゛な(全角)
	            if(CommUtils.isBlank(existCList[0].Katakana__c) && !CommUtils.isBlank(contactNameKataKana)) {
	            	existCList[0].Katakana__c = contactNameKataKana;
	            	isChange = true;
	            }
				// 電話
				if(CommUtils.isBlank(existCList[0].Phone) && !CommUtils.isBlank(phoneNumber)){
					existCList[0].Phone = CommUtils.isBlank(phoneNumber) ? null : PhoneNumberUtils.splitNumber(phoneNumber,'-');
					isChange = true;
				}
				// メール
				if(CommUtils.isBlank(existCList[0].Email) && !CommUtils.isBlank(risaplBasic.Email)){
					existCList[0].Email = risaplBasic.Email;
					isChange = true;
				}
				// 郵便番号
				if(CommUtils.isBlank(existCList[0].MailingPostalCode) && !CommUtils.isBlank(risaplBasic.PostalCode)){
					existCList[0].MailingPostalCode = risaplBasic.PostalCode;
					isChange = true;
				}
				// 申込者
				if(CommUtils.isBlank(existCList[0].ApplicantName__c) && !CommUtils.isBlank(applicantName)){
					existCList[0].ApplicantName__c = applicantName;
					isChange = true;
				}
				// 申込者電話番号
				if(CommUtils.isBlank(existCList[0].ApplicantPhone__c) && !CommUtils.isBlank(applicantPhone)){
					existCList[0].ApplicantPhone__c = applicantPhone;
					isChange = true;
				}
				//2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH END
				//2016/05/24  お客様重複チェック対応 BEGIN
				//if (isChange) update existCList[0];
				if (isChange) existCList[0] = (new CommLogicProcess()).upsertDuplicateErrorProcess(existCList[0], mLogUtils);
            	//2016/05/24  お客様重複チェック対応 END
            	// 2016/03/28 誕生日と携帯電話情報解析と取込 END
            	mLogUtils.write_method_end();
            	return existCList[0];
            }
        }
        // 2016/05/25 お客様電文番号は[--]の場合、エラー回避
        phoneNumber = CommUtils.convTelphoneNumber(phoneNumber);
// 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ BEGIN
if (!conAlwaysNewFlg) {
// 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ END
        // 2017/12/14 SOSLキーチェック追加対応 BEGIN
        //if (!CommUtils.isBlank(phoneNumber)) {
        if (CommUtils.isValidateSoslKey(phoneNumber)) {
        // 2017/12/14 SOSLキーチェック追加対応 END
            // 既存顧客様情報を探す
            //phoneNumber = CommUtils.convTelphoneNumber(phoneNumber);
            //String exitQueryStr = ' Select id,ApplicantName__c,ApplicantPhone__c From contact where ( KanaName1__c = :contactNameKana OR Name = :fullName ';
            //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH BEGIN    
            // Name1__c,KanaName1__c,Katakana__c,Email,Phone,MailingPostalCode 取得項目を追加する
            String soslQuery = 'FIND :phoneNumber IN PHONE FIELDS RETURNING CONTACT (id, name ,Name1__c,KanaName1__c,Katakana__c,Email,Phone, MailingPostalCode where Name = :fullName ';
            //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH END
            if (!CommUtils.isBlank(contactNameKana)) soslQuery += ' OR KanaName1__c =:contactNameKana ';
            if (!CommUtils.isBlank(contactNameKanji)) soslQuery += ' OR Name1__c = :contactNameKanji ';
            if (!CommUtils.isBlank(contactNameKataKana)) soslQuery += ' OR Katakana__c = :contactNameKataKana ';
            //exitQueryStr += ' ) And Phone = :phoneNumber ';
            //existCList = [select id from contact where (Name = :contactName Or Name1__c = :contactName Or KanaName1__c = :contactName Or Katakana__c = :contactName ) And Phone = :phoneNumber ];
            //existCList = DataBase.query(exitQueryStr);
            soslQuery += ' limit 1) ';
            List<List<Sobject>> existRs = search.query(soslQuery);
            existCList = existRs[0];
            mLogUtils.write_log('既存お客様:' + existCList );
        }
        if (existCList != null && !existCList.isEmpty()) {
        	//2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH BEGIN 
			// 団体名または代表者氏名 漢字
            // 団体名または代表者氏名 漢字
            if(CommUtils.isBlank(existCList[0].Name1__c) && !CommUtils.isBlank(contactNameKanji)) {
            	existCList[0].Name1__c = contactNameKanji;
            }
            // 団体名または代表者氏名よみがな(半角)
            if(CommUtils.isBlank(existCList[0].KanaName1__c) && !CommUtils.isBlank(contactNameKana)) {
            	existCList[0].KanaName1__c = contactNameKana;
            }
            // ひらがな ←　団体名または代表者氏名よみか゛な(全角)
            if(CommUtils.isBlank(existCList[0].Katakana__c) && !CommUtils.isBlank(contactNameKataKana)) {
            	existCList[0].Katakana__c = contactNameKataKana;
            }
			// メール
			if(CommUtils.isBlank(existCList[0].Email) && !CommUtils.isBlank(risaplBasic.Email))
				existCList[0].Email = risaplBasic.Email;
			// 郵便番号
			if(CommUtils.isBlank(existCList[0].MailingPostalCode) && !CommUtils.isBlank(risaplBasic.PostalCode))
				existCList[0].MailingPostalCode = risaplBasic.PostalCode;
			//2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH END 
            existCList[0].ApplicantName__c = applicantName;
            existCList[0].ApplicantPhone__c = applicantPhone;
			// 2016/03/28 誕生日と携帯電話情報解析と取込 BEGIN
            if (birthDay != null) existCList[0].Birthdate = birthDay;
            if (!CommUtils.isBlank(moibelPhone)) existCList[0].MobilePhone = moibelPhone;
            // 2016/03/28 誕生日と携帯電話情報解析と取込 END
            //2016/05/24  お客様重複チェック対応 BEGIN
	    	//update existCList[0];
	    	existCList[0] = (new CommLogicProcess()).upsertDuplicateErrorProcess(existCList[0], mLogUtils);
	    	//2016/05/24  お客様重複チェック対応 END
            mLogUtils.write_method_end();
            return existCList[0];
        }
// 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ BEGIN
}
// 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ END        
        // 非存在する場合（あり得ない）
        //throw new CommException('代表者情報の詳細情報を未設定するため、確認必要があり');
        // 代表者は顧客新規作成を行う
        Contact newContact = new Contact(
            // 2013/07/17 団体名または代表者氏名 漢字優先で設定、空白場合、団体名または代表者氏名(半角)に設定する
            // 団体名または代表者氏名(半角)
            LastName =  lastName,
            FirstName = firstName,
            // 団体名または代表者氏名 漢字
            Name1__c = bookingInfo.GuestOrGroupNameKanjiName,
            // 2013/07/17 団体名または代表者氏名(半角)に設定する
            // 団体名または代表者氏名よみがな(全角)
            //KanaName1__c = bookingInfo.GuestOrGroupNameDoubleByte,
            KanaName1__c = bookingInfo.GuestOrGroupNameSingleByte,
            // ひらがな ←　団体名または代表者氏名よみがな(全角)
            Katakana__c = bookingInfo.GuestOrGroupNameDoubleByte,
            // 電話
            //Phone = risaplBasic.PhoneNumber,
            //2016/08/01 日本電話分割 by zy　BEGIN 
            // 2018/11/12 修正 WGCH BEGIN
            // Phone = CommUtils.isBlank(phoneNumber) ? null : PhoneNumberUtils.splitNumber(risaplBasic.PhoneNumber,'-'),
            Phone = CommUtils.isBlank(phoneNumber) ? null : PhoneNumberUtils.splitNumber(phoneNumber,'-'),
            // 2018/11/12 修正 WGCH END
            //2016/08/01 日本電話分割 by zy　END 
            // メール
            Email = risaplBasic.Email,
            // 郵便番号
            MailingPostalCode = risaplBasic.PostalCode,
            // 住所
            // 2016/05/10 住所分割と電話番号は取込値はそのまま BEGIN
            //MailingStreet = risaplBasic.Address,
            // 2016/05/10 住所分割と電話番号は取込値はそのまま END
            // 申込者
            ApplicantName__c = applicantName,
            // 申込者電話番号
            ApplicantPhone__c = applicantPhone,
            // 2016/03/28 誕生日と携帯電話情報解析と取込 BEGIN
            // 誕生日
            Birthdate = birthDay,
            // 携帯
            MobilePhone = moibelPhone
            // 2016/03/28 誕生日と携帯電話情報解析と取込 END
        );
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
        // 2016/05/10 住所分割と電話番号は取込値はそのまま END
        //2016/05/24  お客様重複チェック対応 BEGIN
        //insert newContact;
        //mLogUtils.write_log('お客様新規作成::' + newContact.id);
// 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ BEGIN
if (!conAlwaysNewFlg) {
// 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ END
        newContact = (new CommLogicProcess()).upsertDuplicateErrorProcess(newContact, mLogUtils);
// 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ BEGIN
} else {
		(new CommLogicProcess()).forceUpdate(newContact, mLogUtils);
}
// 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ END
        // 2016/05/24 お客様重複チェック対応 END
        mLogUtils.write_method_end();
        return newContact;

    }
    

    /*
     * 旅行会社情報はSFへ登録を行う
     * 会社・営業所が存在する場合、営業所も一緒に戻る
     */
    private List<Account> upsertTravelInfo (BI_TL_SyncInfo bookingInfo) {
        mLogUtils.write_method_start('upsertTravelInfo');
        // 旅行会社のPakcageコードは再設定を行う
        BI_TL_RisaplBasic risaplBasic = bookingInfo.risaplsinformation.risaplsCommonInformation.risaplBasic;
        bookingInfo.SalesOfficeCompanyCode = risaplBasic.SalesOfficeCompanyCode;
        // 旅行会社名と同じ取引先が存在するかどうかチェックを行う
        Account travelCompany = null;
        // 旅行会社存在する場合
        if (!CommUtils.isBlank(bookingInfo.SalesOfficeCompanyCode) ) {
            // UPDATE 2015/09/15　支店区分 : SalesOfficeCompanyCode　-- > SalesOfficeCompanyCodeTL__c
            //                             Name = XXXX 条件は外す　
            List<Account> travelCompanyLst = [select id , name from Account
                where AccountType__c = :CommConst.ACCOUNT_TYPE_TRAVEL
                and SalesOfficeCompanyCodeTL__c = :bookingInfo.SalesOfficeCompanyCode 
                // 2016/02/01 旅行会社（営業所）の取得方式変更（「営業所コード」と「取引先ID」で合わせて取得する）BEGIN
                //and SalesOfficeCompanyType__c != null   // 旅行会社分類設定されている    
                // 2016/02/01 旅行会社（営業所）の取得方式変更（「営業所コード」と「取引先ID」で合わせて取得する）END
                limit 1];
            //and SalesOfficeCompanyCode__c = :bookingInfo.SalesOfficeCompanyCode
            // 存在なければ、取引先を新規作成する
            if (travelCompanyLst.isEmpty()) {
                    travelCompany = new Account();
                    travelCompany.Name = bookingInfo.SalesOfficeCompanyName;
                    travelCompany.SalesOfficeCompanyCode__c = bookingInfo.SalesOfficeCompanyCode;
                    travelCompany.AccountType__c = CommConst.ACCOUNT_TYPE_TRAVEL;
                    travelCompany.SalesOfficeCompanyCodeTL__c = bookingInfo.SalesOfficeCompanyCode;
                    travelCompany.SalesOfficeCompanyCodeTLAPI__c = '1'+bookingInfo.SalesOfficeCompanyCode;
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
				and	(SalesOfficeCodeTL__c = :bookingInfo.SalesOfficeCode
					OR
					 SalesOfficeCode__c = :bookingInfo.SalesOfficeCode)
				limit 1];
			if (!traveOfficeLst.isEmpty()) {
				traveOffice = traveOfficeLst[0];
				// 既存の取引先（営業所）のコードはNULLの場合、自動設定を行う
				if (CommUtils.isBlank(traveOffice.SalesOfficeCodeTL__c)) {
					traveOffice.SalesOfficeCodeTL__c = bookingInfo.SalesOfficeCode;
					update traveOffice;
				}
				mLogUtils.write_log('旅行会社-支店既存取得::' + traveOffice.id);
			}
		}
		// 2016/02/01 旅行会社（営業所）の取得方式変更（「営業所コード」と「取引先ID」で合わせて取得する）END
        // 旅行会社営業所情報が存在する場合
        if (traveOffice == null &&
        	!CommUtils.isBlank(bookingInfo.SalesOfficeCode) &&
            !CommUtils.isBlank(bookingInfo.SalesOfficeName) ) {
            // 旅行会社営業所情報をチェックを行う
            List<Account> traveOfficeLst = [select id , name, ParentId, SalesOfficeCodeTL__c from Account
                where name = :bookingInfo.SalesOfficeName 
                and AccountType__c = :CommConst.ACCOUNT_TYPE_TRAVEL
                and SalesOfficeCode__c = :bookingInfo.SalesOfficeCode limit 1];
            if (traveOfficeLst.isEmpty()) {
                traveOffice = new Account();
                traveOffice.Name = bookingInfo.SalesOfficeName;
                traveOffice.AccountType__c = CommConst.ACCOUNT_TYPE_TRAVEL;
                traveOffice.SalesOfficeCode__c = bookingInfo.SalesOfficeCode;
				// 2016/02/01 旅行会社（営業所）の取得方式変更（「営業所コード」と「取引先ID」で合わせて取得する）BEGIN
                traveOffice.SalesOfficeCodeTL__c = bookingInfo.SalesOfficeCode;
				// 2016/02/01 旅行会社（営業所）の取得方式変更（「営業所コード」と「取引先ID」で合わせて取得する）END
                traveOffice.ParentId = (travelCompany != null ? travelCompany.Id : null);
                traveOffice.Phone = bookingInfo.SalesOfficePhoneNumber;
                insert traveOffice;
                mLogUtils.write_log('旅行会社-支店新規作成::' + traveOffice.id);
            } else {
                traveOffice = traveOfficeLst[0];
                if(traveOffice.ParentId != travelCompany.Id || CommUtils.isBlank(traveOffice.SalesOfficeCodeTL__c)) {
                    traveOffice.ParentId = travelCompany.Id;
                    traveOffice.SalesOfficeCodeTL__c = bookingInfo.SalesOfficeCode;
                    update traveOffice;
                }
                mLogUtils.write_log('旅行会社-支店既存取得::' + traveOffice.id);
            }
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
        String accountCd = TL_ServiceConfigHelp.getAccountConfig(shopCd).serviceCd;
        if (CommUtils.isBlank(accountCd)) return new AccountMaster__c();
        List<AccountMaster__c> acc = [select Name,Id,TaxRateCal__c,ServiceRate__c  from AccountMaster__c where Field3__c = :accountCd  limit 1];
        if(acc.isEmpty()) return new AccountMaster__c();
        return acc[0];
    }
    // 入湯税商品
    private AccountMaster__c getNyuuTouAcc(){
        String accountCd = TL_ServiceConfigHelp.getAccountConfig(shopCd).nyuuTouCd;
        if (CommUtils.isBlank(accountCd)) return new AccountMaster__c();
        List<AccountMaster__c> acc = [select Name,Id,Field5__c,TaxRateCal__c,ServiceRate__c  from AccountMaster__c where Field3__c = :accountCd  limit 1];
        if(acc.isEmpty()) return new AccountMaster__c();
        return acc[0];
    }
    private String setUpdateContent(LeadIndex__c leadIndex , BI_TL_SyncInfo bookingInfo){
        List<Attachment> rsAtt = [select Name,Body,ParentId from attachment where parentId = :leadIndex.Id order by CreatedDate desc]; 
        //rsAtt[0];
        //bookingInfo.
        //BI_TL_SyncInfo.
        return '';
    }
    // 自動割り振りできる部屋リスト情報を取得する
    // 2015/10/30 故障部屋は自動割当て機能に追加対応 BEGIN
    //private map<Id,List<Room__c>> getCanAssignRoom(LeadIndex__c leadIndex, List<Id> roomTypeIdLst, boolean autoAssingRoomflag, BI_TL_SyncInfo bookingInfo){
    private map<Integer,Room__c> getCanAssignRoom(LeadIndex__c leadIndex, Map<String,Id> roomTypeMap, boolean autoAssingRoomflag, BI_TL_SyncInfo bookingInfo){
    // 2015/10/30 故障部屋は自動割当て機能に追加対応 END
            mLogUtils.write_method_start('getCanAssignRoom');
            
            map<Id, Id> targetRoomIdTypeMap = new map<Id, Id>();
            map<Id, List<Room__c>> wkCanAssignRoomMap = new map<Id, List<Room__c>>();
            map<Integer,Room__c> resultMap = new map<Integer, Room__c>();
            // 自動割り振りの順次でアサイン対象部屋情報を取得する
            // 2015/10/30 故障部屋は自動割当て機能に追加対応 BEGIN
	    List<Id> roomTypeIdLst = roomTypeMap.values();
	    // 2015/10/30 故障部屋は自動割当て機能に追加対応 END
            String sortField = TL_ServiceConfigHelp.getAppConfig(shopCd).roomSortKey;
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
	    	// 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 BEGIN
	    	Date wkBeginDate = leadIndex.EntryDate__c;
	    	Date wkEndDate = leadIndex.DepartureDate__c;
	    	Integer wkNights = bookingInfo.Nights;
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
            // アサインできる部屋はない場合、チェック処理中止
            if(canAssignRoomMap.isEmpty()) return resultMap;
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
            BI_TL_RoomAndGuestInfo[] roomAndGuest = bookingInfo.roomAndGuestLst;
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
	//system.debug(logginglevel.info,'=========' + roomsStatus);
	    	// 指定部屋の故障ありの日付情報を格納する
	    	Map<id,List<RoomsStatus__c>> badRoomStatusMap = new Map<id,List<RoomsStatus__c>>();
	    	//Map<Id, String> roomNameMap = new map<Id, String>();
	    	for(RoomsStatus__c roomStatus : roomsStatus){
	    		//roomNameMap.put(roomStatus.RoomRef__c, roomStatus.RoomRef__r.Name);
	    		if(!badRoomStatusMap.containsKey(roomStatus.RoomRef__c)){
	    			badRoomStatusMap.put(roomStatus.RoomRef__c,new List<RoomsStatus__c>());
	    		}
	    		badRoomStatusMap.get(roomStatus.RoomRef__c).add(roomStatus);
	    		//Set<Date> curSet = badRoomStatusMap.get(roomStatus.RoomRef__c);
	    		//integer betweenLength = roomStatus.StatusBeginDate__c.daysBetween(roomStatus.StatusEndDate__c);
	    		//curSet.addAll(CommUtils.getDaysList(roomStatus.StatusBeginDate__c,betweenLength));
	    		//if(canAssignRoomMap.containsKey(roomStatus.RoomRef__c))canAssignRoomMap.remove(roomStatus.RoomRef__c);
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
	    // 2015/10/30 故障部屋は自動割当て機能に追加対応 BEGIN
            //return canAssignRoomMap;
            return resultMap;
	    // 2015/10/30 故障部屋は自動割当て機能に追加対応 END
    }
    /*
    private String getChangeMessage(TL_LeadInfoSync.BI_TL_SyncInfo oldBookingInfo,TL_LeadInfoSync.BI_TL_SyncInfo newBookingInfo,Map<String,String> labelToNameMap){
		if(labelToNameMap == null) return null;
		String compareLog = '';
		Map<String,Object> oldfieldsMap = oldBookingInfo.fieldsValueMap();
		Map<String,Object> newfieldsMap = newBookingInfo.fieldsValueMap();
		for(String labelName : labelToNameMap.keySet()){
			Object oldValue = oldfieldsMap.get(labelName);
			Object newValue = newfieldsMap.get(labelName);
			if(oldValue != newValue) compareLog += '<br/>' + labelToNameMap.get(labelName) + ':[' + oldValue + '→' + newValue + ']';
		}
		return compareLog;
	}*/
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
	//private List<Lead__c> otherLeadLst;
	//private LeadIndex__c oldLeadIndex;
	/**
	* 予約処理対象予約情報のリストを取得する
	* 1.同じ予約インデックスに所属する予約情報を取得する
	* 2.取得の予約情報の「予約番号」内容は「予約インデックス」と一致すると、該当予約情報は処理対象予約データ
	* 3.予約番号存在　かつ　該当予約番号は予約インデックスと一致しない場合、処理対象外(予約)
	**/
	private List<Lead__c> filterTLImportData(List<Lead__c> orgLst , BI_TL_SyncInfo bookingInfo,LeadIndex__c leadIndex, Set<Id> pSubLeadIds){
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
		// 2017/08/15 ネット取込(TL2way)機能、変更通知（２泊→１泊に変更）が来た際に、子部屋２日目の夕食レストランの席がキャンセルできるように改善対応 BEGIN
		// 既存にレストラン子部屋情報存在チェックする
		TL_ServiceConfigHelp.SubRuleDefInfo subRuleDefInf = TL_ServiceConfigHelp.getAppConfig(shopCd).subRuleDefInf;
		// レストラン子部屋情報存在チェック条件が存在する場合
		dayUnitChildrenMap = new Map<Date, List<Lead__c>>();
		dayUnitOrgLeadMap = new Map<Date, List<Lead__c>>();
		// 条件により、既に取得した予約情報IDを格納する
		set<Id> existChildIdSet = new Set<Id>();
		// 予約変更の場合　かつ　子部屋条件定義の場合
		if (!subRuleDefInf.subLinkRules.isEmpty() && bookingInfo.dmlAction == BI_TL_DmlAction.UPD) {
		    Set<Id> allLeadIds = new Set<Id>();
//mLogUtils.write_log('orgLst::' + orgLst);
	        for(Lead__c lead : orgLst){
	            allLeadIds.add(lead.Id);
//mLogUtils.write_log('allLeadIds::' + allLeadIds);
//mLogUtils.write_log('filterIdSet::' + filterIdSet);
	            if (filterIdSet.contains(lead.Id)) {
                    Date dt = lead.EntryTime__c.Date();
                    if (!dayUnitOrgLeadMap.containsKey(dt)) dayUnitOrgLeadMap.put(dt, new List<Lead__c>());
                    dayUnitOrgLeadMap.get(dt).add(lead); 
	            }
	        }
            // 子部屋情報チェック条件により、既存データを検索する
	        String subQueryStr = 'select id, ReservedStatus__c,Comment3__c,RoomGroupNo__c,EntryTime__c,LeadIndexSubId__c,LeadIndexRef__c '+
	                               ',email__c,Relcontact__c,Field2__c,EventSource__c,BookingDataID__c,Departure__c,CreatedDate ' +
	                               ',Nights__c,PlanSycnFlag__c,LeadIndexRef__r.LeadName__c,Name,refTypeOfRooms__c,Rroom__c ' +
	                               ',Field348__c,SalesOfficeInfoRef__c,refTypeOfRooms__r.RoomTypeCode__c' +
	                               ',Field4__c,Field3__c,StayPersons__c,Mans__c,Femails__c,ChildFA__c,Childs__c,ChildC__c,ChildD__c' +
                                   ' from Lead__c where id in :allLeadIds ';                                            
//mLogUtils.write_log('subRuleDefInf.subLinkRules::' + subRuleDefInf.subLinkRules);
	        for (String condtion : subRuleDefInf.subLinkRules) {
	            //List<Lead__c> childrends = [select id from Lead__c where  ];
	            String queryStr = subQueryStr + (' And ' + condtion);
//mLogUtils.write_log('queryStr::' + queryStr);
	            List<Lead__c> childrenLeads = DataBase.query(queryStr);
//mLogUtils.write_log('childrenLeads::' + childrenLeads);
	            for (Lead__c children : childrenLeads) {
	                // 該当予約情報は既に存在する場合、再度リストに格納しない対応
	                if (existChildIdSet.contains(children.Id)) continue;
	                existChildIdSet.add(children.Id);
//mLogUtils.write_log('existChildIdSet::' + existChildIdSet);
	                // 到着日単位に予約情報格納する
	                Date dt = children.EntryTime__c.Date();
	                if (!dayUnitChildrenMap.containsKey(dt)) dayUnitChildrenMap.put(dt, new List<Lead__c>());
	                dayUnitChildrenMap.get(dt).add(children);
//mLogUtils.write_log('dayUnitChildrenMap1::' + dayUnitChildrenMap);
	            }
	        }
		}
		// 2017/08/15 ネット取込(TL2way)機能、変更通知（２泊→１泊に変更）が来た際に、子部屋２日目の夕食レストランの席がキャンセルできるように改善対応 END
		mLogUtils.write_method_end();
		return filterLst;
	}
	// 2017/08/15 ネット取込(TL2way)機能、変更通知（２泊→１泊に変更）が来た際に、子部屋２日目の夕食レストランの席がキャンセルできるように改善対応 BEGIN
	private Map<Date, List<Lead__c>> dayUnitChildrenMap;
	private Map<Date, List<Lead__c>> dayUnitOrgLeadMap;
	// 2017/08/15 ネット取込(TL2way)機能、変更通知（２泊→１泊に変更）が来た際に、子部屋２日目の夕食レストランの席がキャンセルできるように改善対応 END
	// 2016/09/17 TL連携在庫調整不具合対応 BEGIN
	private Map<Id,StockChangeHisotry__c> getPreChangeHistory(set<id> orgIdSet) {
		// 該当予約のTL側から変更履歴一覧を取得する
		List<StockChangeHisotry__c> historyLst = [select TypeOfRoomRef__c,TypeOfRoomRef__r.RoomTypeCode__c,LeadRef__c,StockChangeCnt__c,AgtRef__c,StockChangeDate__c,Provisional__c from StockChangeHisotry__c 
													where LeadRef__c = :orgIdSet And CreateSource__c = :APPNAME
													order by Name desc];
		Map<Id,StockChangeHisotry__c> historyMap = new Map<Id,StockChangeHisotry__c>();
		for (StockChangeHisotry__c sc: historyLst) {
			if(!historyMap.containsKey(sc.LeadRef__c)) historyMap.put(sc.LeadRef__c,sc);
		}
		return historyMap;
	}
	private void checkChgOrgStockRoomByDmlAction(List<Lead__c> orgLeads,List<Lead__c> newLeads,BI_TL_RoomAndGuestInfo roomAndGuest,String shopCode,BI_TL_DmlAction action,Map<String,Id> roomTypeMap,Map<Id,StockChangeHisotry__c> historyMap){
		checkChgOrgStockRoomByDmlAction(orgLeads,newLeads,new list<BI_TL_RoomAndGuestInfo>{roomAndGuest},shopCode,action,roomTypeMap,historyMap);
	}
	private void checkChgOrgStockRoomByDmlAction(List<Lead__c> orgLeads,List<Lead__c> newLeads,List<BI_TL_RoomAndGuestInfo> roomAndGuestList,String shopCode,BI_TL_DmlAction action,Map<String,Id> roomTypeMap,Map<Id,StockChangeHisotry__c> historyMap){
		mLogUtils.write_method_start('checkChgOrgStockRoomByDmlAction');
		List<StockChangeHisotry__c> stockLst = new List<StockChangeHisotry__c>();
		//キャンセルの場合
		if(action == BI_TL_DmlAction.CANCEL) {
			// キャンセルされる予約情報をチェックする
			for (Lead__c oldL : orgLeads) {
				StockChangeHisotry__c s = historyMap.get(oldL.id);
				mLogUtils.write_log('s::' + s);
				//起始变换的元房型不同
				if (s != null) {
					// 旧予約の部屋タイプは前回XMLの部屋タイプが一致しない場合
					if (s.TypeOfRoomRef__c != oldL.refTypeOfRooms__c) {
mLogUtils.write_log('CANCEL:::[1-1]::::');
						// TL側から前回のXMLの部屋タイプに対して、在庫-1のリクエストデータ作成する
						// 2020/08/11 予約泊数変更＆到着日変更の場合、在庫変更履歴設定不正の不具合改修 WSQ BEGIN
						// キャンセルされた部屋タイプは前回TLの部屋タイプが不一致場合、キャンセル時点、前回のキャンセル部屋タイプでリセットする
						//stockLst.add(generalStockHisotry(-1,s.AgtRef__c,s.StockChangeDate__c,s.TypeOfRoomRef__c,oldL.id));
						// 部屋タイプはTL側の部屋タイプにリセットする
						oldL.refTypeOfRooms__c = s.TypeOfRoomRef__c;
						oldL.Rroom__c = null;
						// 2020/08/11 予約泊数変更＆到着日変更の場合、在庫変更履歴設定不正の不具合改修 WSQ END
					} else {
mLogUtils.write_log('CANCEL:::[2-1]::::');
						// 旧予約のデータの発生源をチェックする[発生源がTLの場合、処理なし]
						// 発生源がSFDCの場合、旧予約の部屋タイプの在庫数は−１リクエストを発行する
						// 2020/08/11 予約泊数変更＆到着日変更の場合、在庫変更履歴設定不正の不具合改修 WSQ BEGIN
						// TL側キャンセル際に、キャンセル前の部屋タイプと予約部屋タイプが一致場合、個別処理不要
						/*
						if (oldL.EventSource__c == CommConst.BI_PROCESS_TYPE.SFDC.Name()) {
mLogUtils.write_log('CANCEL:::[2-2]::::');
							stockLst.add(generalStockHisotry(-1,s.AgtRef__c,oldL.EntryTime__c.date(),oldL.refTypeOfRooms__c,oldL.id));
						}*/
						// 2020/08/11 予約泊数変更＆到着日変更の場合、在庫変更履歴設定不正の不具合改修 WSQ END
					}
				}
			}
		} else if(action == BI_TL_DmlAction.UPD) {
			// 変更予約リスト
			for (integer i = 0 ; i < orgLeads.size() ; i++ ){
				Lead__c newL = newLeads[i];
				Lead__c oldL = orgLeads[i];
				BI_TL_RoomAndGuestInfo roomAndGuest = roomAndGuestList[i];
				//if (!orgLeads.isEmpty()) {
				//	oldL = orgLeads[i];
				StockChangeHisotry__c s = historyMap.get(oldL.id);
				if (s == null) continue;
				// 到着日変更あり、なし
				boolean sameDate = oldL.EntryTime__c.date() == newL.EntryTime__c.date();
				// 仕様纏める：
				// 今回のXMLの部屋タイプは前回のTLから引き渡しXMLの部屋タイプが一致する場合、個別処理が不要
				Id newXmlRoomTypeId = roomTypeMap.get(roomAndGuest.room.RoomTypeCode);
				Id oldXmlRoomTypeId = s.TypeOfRoomRef__c;
				Id newLeadRoomTypeId = newL.refTypeOfRooms__c;
				Id oldLeadroomTypeId = oldL.refTypeOfRooms__c;
mLogUtils.write_log('newXmlRoomTypeId::' + newXmlRoomTypeId);
mLogUtils.write_log('oldXmlRoomTypeId::' + oldXmlRoomTypeId);
mLogUtils.write_log('newLeadRoomTypeId::' + newLeadRoomTypeId);
mLogUtils.write_log('oldLeadroomTypeId::' + oldLeadroomTypeId);
				Boolean oldLeadSfdcEvent = (oldL.EventSource__c == CommConst.BI_PROCESS_TYPE.SFDC.Name());
				// 今回のXMLの部屋タイプと前回のTLのXML部屋タイプが違う場合、
				if (oldXmlRoomTypeId != newXmlRoomTypeId) {
mLogUtils.write_log(':::[1-1]::::');
					// 変更先の予約の部屋タイプは今回のXMLの部屋タイプが一致する場合
					if (newXmlRoomTypeId == newLeadRoomTypeId) {
mLogUtils.write_log(':::[1-2]::::');
						// 新予約の部屋タイプは旧予約の部屋タイプと一致する場合
						if (newLeadRoomTypeId == oldLeadroomTypeId) {
mLogUtils.write_log(':::[1-3]::::');
							// 到着日変更あり場合、前回のXMLの部屋タイプは旧予約データの到着日の在庫−１
							if (!sameDate) {
mLogUtils.write_log(':::[1-4]::::');
								stockLst.add(generalStockHisotry(-1,s.AgtRef__c,oldL.EntryTime__c.date(),oldXmlRoomTypeId,oldL.id));
							} else {
mLogUtils.write_log(':::[1-5]::::');
								// TL側へ、前回の部屋タイプの在庫-1/今回の部屋タイプの在庫+1
								stockLst.add(generalStockHisotry(-1,s.AgtRef__c,oldL.EntryTime__c.date(),oldXmlRoomTypeId,oldL.id));
								stockLst.add(generalStockHisotry(1,s.AgtRef__c,oldL.EntryTime__c.date(),newXmlRoomTypeId,oldL.id));
							}
						} 
						// 新予約の部屋タイプは旧予約の部屋タイプと一致しない場合
						else {
mLogUtils.write_log(':::[2-1]::::');
							// 旧予約の発生源がSFDCの場合、前回XMLの部屋タイプ、旧予約の到着日の在庫-1
							if (oldLeadSfdcEvent) {
mLogUtils.write_log(':::[2-2]::::');
								stockLst.add(generalStockHisotry(-1,s.AgtRef__c,oldL.EntryTime__c.date(),oldXmlRoomTypeId,oldL.id));
							}
						}
					}
					// 新予約の部屋タイプは今回のXMLの部屋タイプが一致しない場合
					else {
mLogUtils.write_log(':::[3-1]::::');
						// TL側へ、前回の部屋タイプの在庫-1/今回の部屋タイプの在庫+1
						stockLst.add(generalStockHisotry(-1,s.AgtRef__c,oldL.EntryTime__c.date(),oldXmlRoomTypeId,oldL.id));
						stockLst.add(generalStockHisotry(1,s.AgtRef__c,newL.EntryTime__c.date(),newXmlRoomTypeId,newL.id));
					}
				}
				//仮データの作成する「更新範囲の予約のXML部屋タイプ記録」
				stockLst.add(new StockChangeHisotry__c(
					Provisional__c = true,//仮データ[記録専用]
					CreateSource__c = APPNAME,
					TypeOfRoomRef__c = newXmlRoomTypeId,
					AgtRef__c = s.AgtRef__c,
					StockChangeDate__c = newL.EntryTime__c.date(),	// 到着日ー＞調整日付
					LeadRef__c = orgLeads[0].id )
				);
			}
		}	
		if (!stockLst.isEmpty()) insert stockLst;
		mLogUtils.write_method_end();
	}
	private StockChangeHisotry__c generalStockHisotry (Integer stockChgNum, Id agtId, Date stockDate, Id roomTypeId, Id leadId) {
		return new StockChangeHisotry__c(
								StockChangeCnt__c = stockChgNum,
								CreateSource__c = APPNAME,
								BatchRunTarget__c = APPNAME,//連携対象になる
								AgtRef__c = agtId,
								StockChangeDate__c = stockDate,	// 到着日ー＞調整日付
								TypeOfRoomRef__c = roomTypeId,
								LeadRef__c = leadId );
	}
	// 2016/09/17 TL連携在庫調整不具合対応 END
	/**
    * 在庫変更履歴チェック
    */
	public void checkChgOrgStockRoom(List<Lead__c> orgLeads,List<BI_TL_RoomAndGuestInfo> roomAndGuestLst,String shopCode,BI_TL_DmlAction action){
		mLogUtils.write_method_start('checkChgOrgStockRoom');
		Set<Id> leadIdSet = new Set<Id>();
		map<Id,Lead__c> typeMap = new map<Id,Lead__c>();
		//若房间更改了则记录到map中
		for (Lead__c l : orgLeads) {
			leadIdSet.add(l.id);
		}
		Set<String>	roomTypeCdSet = new Set<String>();
		Set<String>	roomTypeNmSet = new Set<String>();
		for (BI_TL_RoomAndGuestInfo roomAndGuest: roomAndGuestLst) {
	        roomTypeCdSet.add(roomAndGuest.room.RoomTypeCode);
	        // 部屋タイプ名：部屋ID情報を格納する
	        if (!CommUtils.isBlank(roomAndGuest.room.RoomTypeName)) roomTypeNmSet.add(roomAndGuest.room.RoomTypeName);
	    }
        // 部屋タイプMAP情報設定する
        Map<String,Id> roomTypeMap = new Map<String, Id>();
         // 店舗区分 :新追加 ShopInfoRef__c　
        for (TypeOfRooms__c roomType: [select id, RoomTypeName__c, RoomTypeCode__c,(Select Id From TypeRoomRef__r limit 2) from TypeOfRooms__c where ShopInfoRef__r.ShopCode__c = :shopCode and  (RoomTypeCode__c in :roomTypeCdSet Or RoomTypeName__c in :roomTypeNmSet)]) {
            roomTypeMap.put(roomType.RoomTypeCode__c, roomType.Id);
        }
		//查询改变房间的lead所关联的在库履历
		List<StockChangeHisotry__c> historyLst = [select TypeOfRoomRef__c,TypeOfRoomRef__r.RoomTypeCode__c,LeadRef__c,StockChangeCnt__c from StockChangeHisotry__c where LeadRef__c = :typeMap.keySet()  and Provisional__c = true order by StockChangeDate__c desc];
		Map<Id,StockChangeHisotry__c> historyMap = new Map<Id,StockChangeHisotry__c>();
		for (StockChangeHisotry__c sc: historyLst) {
			if(!historyMap.containsKey(sc.LeadRef__c)) historyMap.put(sc.LeadRef__c,sc);
		}
		mLogUtils.write_log('orgLeads::' + orgLeads);
		mLogUtils.write_log('roomAndGuestLst::' + roomAndGuestLst);
		List<StockChangeHisotry__c> stockLst = new List<StockChangeHisotry__c>();
		for (integer i = 0 ; i < orgLeads.size() ; i++) {
			Lead__c lead = orgLeads[i];
			StockChangeHisotry__c s = historyMap.get(lead.id);
			//如果调整日期相同说明是上一个调整履历
			//if (lead.EntryTime__c.date() == s.StockChangeDate__c) {
			if (s != null)	{
			//sf未更改房间类型
				if ( action == BI_TL_DmlAction.CANCEL && s.TypeOfRoomRef__r.RoomTypeCode__c == lead.refTypeOfRooms__r.RoomTypeCode__c) continue;
			}	
			//更改的房间和上一次更改的房间不一致
			//if (s == null || roomAndGuestLst[i].room.RoomTypeCode != s.TypeOfRoomRef__r.RoomTypeCode__c ) {
				//这一次更改的数据判断 +1 或者 不变
				//上一次的数据 减去1
			Id minusTypeID = s == null ? lead.refTypeOfRooms__c : s.TypeOfRoomRef__c;
			mLogUtils.write_log('+1::' + minusTypeID);
			stockLst.add(new StockChangeHisotry__c(
							//StatusLst__c = ''
							StockChangeCnt__c = -1,
							CreateSource__c = APPNAME,
							AgtRef__c = lead.SalesOfficeInfoRef__c,
							StockChangeDate__c = lead.EntryTime__c.date(),	// 到着日ー＞調整日付
							TypeOfRoomRef__c = minusTypeID,
							LeadRef__c = lead.id )
						);
			//若是cancel 
			if (action != BI_TL_DmlAction.CANCEL && true){
				mLogUtils.write_log('-1::' + roomTypeMap.get(roomAndGuestLst[i].room.RoomTypeCode));
				//上一次的数据 加算1
				stockLst.add(new StockChangeHisotry__c(
								//StatusLst__c = ''
								StockChangeCnt__c = 1,
								CreateSource__c = APPNAME,
								AgtRef__c = lead.SalesOfficeInfoRef__c,
								StockChangeDate__c = lead.EntryTime__c.date(),	// 到着日ー＞調整日付
								TypeOfRoomRef__c = roomTypeMap.get(roomAndGuestLst[i].room.RoomTypeCode),
								LeadRef__c = lead.id )
							);
				//仮データの作成する
				stockLst.add(new StockChangeHisotry__c(
					Provisional__c = true,
					CreateSource__c = APPNAME,
					AgtRef__c = lead.SalesOfficeInfoRef__c,
					StockChangeDate__c = lead.EntryTime__c.date(),	// 到着日ー＞調整日付
					LeadRef__c = lead.id )
				);
			}
		}
		insert stockLst;
		mLogUtils.write_method_end();
	}
    public class BI_TL_SyncInfo {
        // 情報区分 TransactionType
        public String DataFrom;
        //public String DataClassification;
        public BI_TL_DmlAction dmlAction;
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
        public List<BI_TL_BankInfo> bankLst;    //振込銀行情報
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
        public List<BI_TL_CouponInfo> CouponLst;        //クーポン明細
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
        // 2018/04/19 氏名変更のみケース対応 BEGIN
	    public Boolean isUpdForName{get{
	    	return (isUpdForName == null ? false : isUpdForName);
	    } set;}
        // 2018/04/19 氏名変更のみケース対応 END 
        // 個々の部屋とお客様情報<1:N>
        public List<BI_TL_RoomAndGuestInfo> roomAndGuestLst;
        // 7-1
        public BI_TL_Risaplsinformation risaplsinformation;
        public BI_TL_SyncInfo(){
        	risaplsinformation = new BI_TL_Risaplsinformation();
        }
        public Map<String,Object> fieldsValueMap(){
            Map<String,Object> fieldsValueMap = new Map<String,Object>();
            /*
            fieldsValueMap.put('DataFrom',this.DataFrom);
            fieldsValueMap.put('dmlAction',this.dmlAction);
            fieldsValueMap.put('DataClassification',this.DataClassification);
            fieldsValueMap.put('DataID',this.DataID);
            fieldsValueMap.put('SystemDate',this.SystemDate);
            fieldsValueMap.put('SystimTime',this.SystimTime);
            fieldsValueMap.put('AccommodationName',this.AccommodationName);
            fieldsValueMap.put('AccommodationCode',this.AccommodationCode);
            fieldsValueMap.put('AccommodationArea',this.AccommodationArea);
            fieldsValueMap.put('ChainName',this.ChainName);
            fieldsValueMap.put('AccommodationPersonInCharge',this.AccommodationPersonInCharge);
            fieldsValueMap.put('AccommodationEmail',this.AccommodationEmail);
            fieldsValueMap.put('AccommodationPhoneNumber',this.AccommodationPhoneNumber);
            fieldsValueMap.put('bankLst',this.bankLst);
            fieldsValueMap.put('AccommodationCPUAddress',this.AccommodationCPUAddress);
            fieldsValueMap.put('SalesOfficeCompanyCode',this.SalesOfficeCompanyCode);
            fieldsValueMap.put('SalesOfficeCompanyName',this.SalesOfficeCompanyName);
            fieldsValueMap.put('SalesOfficeName',this.SalesOfficeName);
            fieldsValueMap.put('SalesOfficeCode',this.SalesOfficeCode);
            fieldsValueMap.put('SalesOfficePersonInCharge',this.SalesOfficePersonInCharge);
            fieldsValueMap.put('SalesOfficeEmail',this.SalesOfficeEmail);
            fieldsValueMap.put('SalesOfficePhoneNumber',this.SalesOfficePhoneNumber);
            
            fieldsValueMap.put('SalesOfficeStateProvidence',this.SalesOfficeStateProvidence);
            fieldsValueMap.put('SalesOfficeCityName',this.SalesOfficeCityName);
            fieldsValueMap.put('SalesOfficeAddressLine',this.SalesOfficeAddressLine);
            fieldsValueMap.put('SalesOfficeStreetNumber',this.SalesOfficeStreetNumber);
            fieldsValueMap.put('SalesOfficePostalCode',this.SalesOfficePostalCode);
            
            fieldsValueMap.put('SalesOfficeRegisteredCategory',this.SalesOfficeRegisteredCategory);
            fieldsValueMap.put('SalesOfficeLicenseNumber',this.SalesOfficeLicenseNumber);
            fieldsValueMap.put('SalesOfficeRegisteredPrefecture',this.SalesOfficeRegisteredPrefecture);
            fieldsValueMap.put('SalesOfficeCPUAddress',this.SalesOfficeCPUAddress);
            fieldsValueMap.put('RetailerCompanyName',this.RetailerCompanyName);
            fieldsValueMap.put('RetailerOfficeName',this.RetailerOfficeName);
            fieldsValueMap.put('RetailerOfficeCode',this.RetailerOfficeCode);
            fieldsValueMap.put('RetailerPersonInCharge',this.RetailerPersonInCharge);
            fieldsValueMap.put('RetailerEmail',this.RetailerEmail);
            fieldsValueMap.put('RetailerPhoneNumber',this.RetailerPhoneNumber);
            fieldsValueMap.put('RetailerStateProvidence',this.RetailerStateProvidence);
            fieldsValueMap.put('RetailerCityName',this.RetailerCityName);
            fieldsValueMap.put('RetailerAddressLine',this.RetailerAddressLine);
            fieldsValueMap.put('RetailerStreetNumber',this.RetailerStreetNumber);
            fieldsValueMap.put('RetailerPostalCode',this.RetailerPostalCode);
            fieldsValueMap.put('RetailerRegisteredCategory',this.RetailerRegisteredCategory);
            fieldsValueMap.put('RetailerLicenseNumber',this.RetailerLicenseNumber);
            fieldsValueMap.put('RetailerRegisteredPrefecture',this.RetailerRegisteredPrefecture);
            
            fieldsValueMap.put('TravelAgencyBookingNumber',this.TravelAgencyBookingNumber);
            fieldsValueMap.put('TravelAgencyBookingDate',this.TravelAgencyBookingDate);
            fieldsValueMap.put('TravelAgencyBookingTime',this.TravelAgencyBookingTime);
            fieldsValueMap.put('TravelAgencyReportNumber',this.TravelAgencyReportNumber);
            
            fieldsValueMap.put('GuestOrGroupNameSingleByte',this.GuestOrGroupNameSingleByte);
            fieldsValueMap.put('GuestOrGroupNameDoubleByte',this.GuestOrGroupNameDoubleByte);
            fieldsValueMap.put('GuestOrGroupNameKanjiName',this.GuestOrGroupNameKanjiName);
            fieldsValueMap.put('CheckInDate',this.CheckInDate);
            fieldsValueMap.put('CheckInTime',this.CheckInTime);
            fieldsValueMap.put('CheckOutDate',this.CheckOutDate);
            fieldsValueMap.put('CheckOutTime',this.CheckOutTime);
            */
            fieldsValueMap.put('Nights',this.Nights);
           // fieldsValueMap.put('Transportaion',this.Transportaion);
            fieldsValueMap.put('TotalRoomCount',this.TotalRoomCount);
            fieldsValueMap.put('GrandTotalPaxCount',this.GrandTotalPaxCount);
            fieldsValueMap.put('TotalPaxMaleCount',this.TotalPaxMaleCount);
            fieldsValueMap.put('TotalPaxFemaleCount',this.TotalPaxFemaleCount);
            fieldsValueMap.put('TotalChildA70Count',this.TotalChildA70Count);
            fieldsValueMap.put('TotalChildB50Count',this.TotalChildB50Count);
            fieldsValueMap.put('TotalChildC30Count',this.TotalChildC30Count);
            fieldsValueMap.put('TotalChildDNoneCount',this.TotalChildDNoneCount);
           // fieldsValueMap.put('PackagePlanName',this.PackagePlanName);
            fieldsValueMap.put('PackagePlanCode',this.PackagePlanCode);
            /*
            fieldsValueMap.put('PackagePlanContent',this.PackagePlanContent);
            fieldsValueMap.put('MealCondition',this.MealCondition);
            fieldsValueMap.put('PackagePlanContent',this.PackagePlanContent);
            fieldsValueMap.put('SpecificMealCondition',this.SpecificMealCondition);
            fieldsValueMap.put('MealPlace',this.MealPlace);
            fieldsValueMap.put('SpecialServiceRequest',this.SpecialServiceRequest);
            fieldsValueMap.put('OtherServiceInformation',this.OtherServiceInformation);
            fieldsValueMap.put('FollowUpInformation',this.FollowUpInformation);
            fieldsValueMap.put('AccommodationConfirmationNumber',this.AccommodationConfirmationNumber);
            fieldsValueMap.put('GroupNameWelcomeBoard',this.GroupNameWelcomeBoard);
            fieldsValueMap.put('CoachCount',this.CoachCount);
            fieldsValueMap.put('CoachCompany',this.CoachCompany);
            fieldsValueMap.put('TotalChildOtherCount',this.TotalChildOtherCount);
            fieldsValueMap.put('TotalTourConductorCount',this.TotalTourConductorCount);
            fieldsValueMap.put('TotalCoachDriverCount',this.TotalCoachDriverCount);
            fieldsValueMap.put('TotalGuideCount',this.TotalGuideCount);
            fieldsValueMap.put('TypeOfGroup',this.TypeOfGroup);
            fieldsValueMap.put('Status',this.Status);
            fieldsValueMap.put('PackageType',this.PackageType);
            fieldsValueMap.put('BanquetRoom',this.BanquetRoom);
            fieldsValueMap.put('ModificationType',this.ModificationType);
            fieldsValueMap.put('ModificationPoint',this.ModificationPoint);
            fieldsValueMap.put('CancellationNumber',this.CancellationNumber);
            fieldsValueMap.put('PreviousPlace',this.PreviousPlace);
            fieldsValueMap.put('PreviousAccommodationName',this.PreviousAccommodationName);
            fieldsValueMap.put('RoomRateOrPersonalRate',this.RoomRateOrPersonalRate);
            fieldsValueMap.put('TaxServiceFee',this.TaxServiceFee);
            fieldsValueMap.put('Payment',this.Payment);
            fieldsValueMap.put('BareNetRate',this.BareNetRate);
            fieldsValueMap.put('CreditCardAuthority',this.CreditCardAuthority);
            fieldsValueMap.put('CreditCardNumber',this.CreditCardNumber);
            fieldsValueMap.put('TotalAccommodationCharge',this.TotalAccommodationCharge);
            fieldsValueMap.put('TotalAccommodationHotSpringTax',this.TotalAccommodationHotSpringTax);
            fieldsValueMap.put('TotalAccommodationServiceFee',this.TotalAccommodationServiceFee);
            fieldsValueMap.put('TotalAccommodationOtherFee',this.TotalAccommodationOtherFee);
            fieldsValueMap.put('CommissionPercentage',this.CommissionPercentage);
            
            fieldsValueMap.put('CouponLst',this.CouponLst);
            fieldsValueMap.put('CancellationCharge',this.CancellationCharge);
            fieldsValueMap.put('ExpireDate',this.ExpireDate);
            fieldsValueMap.put('CardHolderName',this.CardHolderName);
            fieldsValueMap.put('TotalAccommodationConsumptionTax',this.TotalAccommodationConsumptionTax);
            fieldsValueMap.put('TotalAccommodationHotelTax',this.TotalAccommodationHotelTax);
            fieldsValueMap.put('TotalAccommodationBreakfastFee',this.TotalAccommodationBreakfastFee);
            fieldsValueMap.put('TotalAccommodationCommissionAmount',this.TotalAccommodationCommissionAmount);
            fieldsValueMap.put('TotalAccommodationCommissionConsumptionTax',this.TotalAccommodationCommissionConsumptionTax);
            fieldsValueMap.put('TotalAccommodationChargeAfterCheckIn',this.TotalAccommodationChargeAfterCheckIn);
            fieldsValueMap.put('TotalBalanceAfterCheckIn',this.TotalBalanceAfterCheckIn);
            fieldsValueMap.put('TotalAccommodationConsumptionAfterCheckIn',this.TotalAccommodationConsumptionAfterCheckIn);
            fieldsValueMap.put('CancellationChargeAfterCheckIn',this.CancellationChargeAfterCheckIn);
            fieldsValueMap.put('MembershipFee',this.MembershipFee);
            fieldsValueMap.put('AdjustmentFee',this.AdjustmentFee);
            */
            return fieldsValueMap;
        }
    }
    // 2015/08/07 TL2WAY対応するため、項目追加 BEGIN
    public class BI_TL_BankInfo {
        public String BankName;         //振込銀行名
        public String BankAccountNumber;            //口座番号
        public String BankBranchName;           //振込銀行支店名
        public String BankAccountClassification;            //振込銀行口座種別
        public String BankAccountName;          //口座名
    }
    public class BI_TL_CouponInfo {
        public Integer CouponAmount;            //クーポン券面額
        public String CouponType;           //クーポン種類
        public String CouponNumber;         //クーポン番号
        public Date CouponIssueDate;            //クーポン発行日
    }
    // 2015/08/07 TL2WAY対応するため、項目追加 END
    
    
    // １部屋利用情報(1:1)
    public class BI_TL_RoomAndGuestInfo {
        public BI_TL_RoomsInfo room;
        //public List<Date> roomDateLst;
        public List<BI_TL_RoomRateInfomation> roomRateLst;
        public List<BI_TL_GuestInfo> guestLst;
    }
    // 1部屋の部屋料金情報(1:N){連泊}
    public class BI_TL_RoomRateInfomation {
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
    public class BI_TL_RoomsInfo{
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
    public class BI_TL_GuestInfo {
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
    public class BI_TL_Risaplsinformation {
        // 07-01
        public BI_TL_RisaplsCommonInformation risaplsCommonInformation;     // リザプリ共通情報
        
        // 2015/08/07 TL2WAY対応するため、項目追加 BEGIN
        public BI_TL_AgentNativeInformation agentNativeInformation;     // リザプリ共通情報
        // 2015/08/07 TL2WAY対応するため、項目追加 END
        public BI_TL_Risaplsinformation(){
        	risaplsCommonInformation = new BI_TL_RisaplsCommonInformation();
        	agentNativeInformation = new BI_TL_AgentNativeInformation();
        }
    }
    // リザプリ共通情報[07-01]
    public class BI_TL_RisaplsCommonInformation {
        public BI_TL_RisaplBasic risaplBasic;                                           // 予約基本情報
        public BI_TL_Member member;     // [07-01-05]
        
        // 2015/08/07 TL2WAY対応するため、項目追加 BEGIN
        public BI_TL_Allotment allotment;       //予約情報      
        public List<BI_TL_Option> option;       //オプション情報
        public List<BI_TL_RoomAndRoomRateInformation> roomAndRoomRateInformationLst;        //個々の部屋と部屋料金情報  
        public List<BI_TL_BlockReport> blockReportLst;      //提供室数、残室   
        public BI_TL_OtherInfo otherInfo;       //その他情報 
        public BI_TL_BasicRate basicRate;       //基本料金情報                
        // 2015/08/07 TL2WAY対応するため、項目追加 END
    }
    // 予約基本情報[07-01-01]
    public class BI_TL_RisaplBasic {
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
    public class BI_TL_Allotment {
        public Integer AssignDiv;            //部屋割区分
        public Integer GenderDiv;            //男女区分
        public Integer HandleDiv;            //取扱区分
        public Integer RsvUserDiv;           //予約者情報区分
        public Integer UseDiv;           //利用区分
    }
    
    public class BI_TL_Option {
        public Date OptionDate;             //オプション利用年月日
        public String Name;             //オプション名称
        public String NameRequest;          //オプション名備考
        public Integer OptionCount;             //オプション個数
        public Integer OptionRate;          //オプション料金単価
        public String OptionCode;           //オプションコード
    }
    
    public class BI_TL_RoomAndRoomRateInformation {
        public BI_TL_RoomsInfo room;
        public List<BI_TL_RoomRateInfomation> roomRateLst;
        public List<BI_TL_GuestInfo> guestLst;
    }   
    
    public class BI_TL_GuestInformation {
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
    
    public class BI_TL_BlockReport {
        public String RoomTypeCode;             //部屋タイプコード
        public String InquiryDate;              //照会日
        public Integer TotalRoomsBlock;             //提供室数
        public Integer TotalRoomsNotYetSold;                //残室数
    }
    
    public class BI_TL_OtherInfo {
        public String Reference;              //通信欄
        public String GuestRequest;           //お客様からの要望
        public String AdditionalInformation;              //予約補足情報
        public List<BI_TL_QuestionAndAnswerInfo> questionAndAnswerLst;            //宿泊者への質問と回答リスト
    }
    
    public class BI_TL_QuestionAndAnswerInfo {
        public String QuestionToGuest;         //宿泊者への質問
        public String AnswerToHotel;           //宿泊者からの回答       
    }
    
    public class BI_TL_BasicRate {
        public Integer TotalAccomodationServiceCharge;               //合計宿泊料金に対するサービス料
        public List<BI_TL_PointsDiscountInfo> pointsDiscountLst;                 //ポイント割引・補助金情報
        public List<BI_TL_DepositInfo> depositLst;               //デポジット情報
    }
    
    public class BI_TL_PointsDiscountInfo {
        public Integer PointsDiv;                //ポイント割引・補助金区分
        public String PointsDiscountName;                //ポイント割引・補助金名称
        public Integer PointsDiscount;               //ポイント割引・補助金額
    }
    
    public class BI_TL_DepositInfo {        
        public Integer DepositAmount;         //デポジット額
    }
    
    public class BI_TL_AgentNativeInformation{
        public BI_TL_Extend extend;         //独自情報1
        public BI_TL_Extendmytrip extendmytrip;         //独自情報2
        public BI_TL_AgentNativeInformation(){
        	extend = new BI_TL_Extend();
        	extendmytrip = new BI_TL_Extendmytrip();
        }
    }
    
    public class BI_TL_Extend{
        public String PointDiv;            //ポイント区分
        public String PointName;               //ポイント名称・補助金名称
        public Integer Points;             //ポイント割引金額・補助金額
        public Integer TotalAccommodationDecleasePoints;               //割引後の総額
        public Integer TotalAccommodationConsumptionTax;               //割引後の総額に対する、消費税額
        public Integer AmountClaimed;              //宿泊者請求額
        public String Pamphlet;            //パンフレット利用フラグ
        public String FromHotelQuestion;               //宿泊施設への質問事項
        public String ToHotelAnswer;               //宿泊施設からの回答
        public String AgentComment;            //じゃらんnetから宿泊施設へのコメント
    }
    
    public class BI_TL_Extendmytrip{
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
    public class BI_TL_Member {
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

    public class BI_TL_SyncResult {
        // 処理結果
        public BI_TL_Result result;
        public Id sfdcId;
        public String message;
        public Id sfdcJobId;
        //public Id sfdcDocumentParentId;
    }
    // 戻る結果：処理成功、処理失敗、処理中。
    public enum BI_TL_Result{OK, NG, WAIT}
    // INS:新規 / UPD:更新 / 削除：キャンセル
    public enum BI_TL_DmlAction{INS, UPD, CANCEL, CONFIRM, TEJIMA, ISSUE, OTHER }
    public enum BI_FILTER_STATUS{EXCLUDE,INCLUDE,OTHER}
    public enum BI_BOOKING_MODE{DEF,STOP}
    // 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 ZH BEGIN
	public static void convertGuestInfo(BI_TL_SyncInfo bookingInfo) {
        // 宿泊施設側情報
        // 振込銀行情報 BankList
        // 旅行会社情報
        // 基本宿泊情報
        bookingInfo.GuestOrGroupNameKanjiName = CommStringUtils.convertRomanToKana(bookingInfo.GuestOrGroupNameKanjiName, true);
        // Member    
        BI_TL_Member member = bookingInfo.risaplsinformation.risaplsCommonInformation.member;
        if (member != null) {
            member.UserName = CommStringUtils.convertRomanToKana(member.UserName, true);
        }
	}
	// 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 ZH END
    // 2021/06/31 #JP10242対応 by zy BEGIN  
    private void filterExitBadRoom(List<Lead__c> leadLst){
        if (!leadLst.isEmpty()) {
            Date leadStartDt = null; // 予約最小到着日 
            Date leadEndDt = null; //　予約最大出発日
            Set<Id> roomSet = new Set<Id>(); // 部屋集合
            for (Lead__c lead : leadLst) {
                // 変更予約チェック
                if (lead.id == null) {
                    continue;
                }
                // 部屋不存在の場合
                if (lead.Rroom__c == null) {
                    continue;
                }
                // キャンセル予約以外の場合
                if (lead.ReservedStatus__c != CommConst.LEAD_ST_CANCEL) {
                    Date entryDt = lead.EntryTime__c.date();
                    Date departDt = lead.Departure__c.date();
                    // 開始日取得
                    if (leadStartDt == null || leadStartDt > entryDt) {
                        leadStartDt = entryDt;
                    }
                    // 終了日取得
                    if (leadEndDt == null || leadEndDt < departDt) {
                        leadEndDt = departDt;
                    }
                    // 部屋を追加する
                    roomSet.add(lead.Rroom__c);
                }
            }
            // データ有効な場合
            if (leadStartDt != null && leadEndDt != null) {
                Map<id,List<RoomsStatus__c>> badRoomStatusMap = new Map<id,List<RoomsStatus__c>>();
                // 指定期間ないの故障部屋リストを取得する
                List<RoomsStatus__c> roomsStatus = (new RoomStatusManager()).queryBadRoomList(leadStartDt,leadEndDt ,roomSet);
                for(RoomsStatus__c roomStatus : roomsStatus){
                    if(!badRoomStatusMap.containsKey(roomStatus.RoomRef__c)){
                        badRoomStatusMap.put(roomStatus.RoomRef__c,new List<RoomsStatus__c>());
                    }
                    badRoomStatusMap.get(roomStatus.RoomRef__c).add(roomStatus);
                }
                for (Lead__c newLead : leadLst) {
                    // 変更予約チェック と　キャンセル予約以外の場合
                    if (newLead.id == null || newLead.ReservedStatus__c == CommConst.LEAD_ST_CANCEL) {
                        continue;
                    }
                    if (badRoomStatusMap.containsKey(newLead.Rroom__c)) {
                        Date startDt = newLead.EntryTime__c.date();
                        Date endDt = newLead.Departure__c.date();
                        for (RoomsStatus__c roomStatus : badRoomStatusMap.get(newLead.Rroom__c)) {
                            // 宿泊期間に故障情報が存在する場合、該当部屋は自動割当て対象外になる
                           // 2021/06/30 #12393 bug fixed by zy BEGIN
                           if ((roomStatus.StatusBeginDate__c <= startDt &&
                                roomStatus.StatusEndDate__c >= startDt) 
                                ) {
                                mLogUtils.write_log('該当日['+startDt.format()+']に故障部屋するため、部屋が未割り当てにする');
                            // 2021/06/30 #12393 bug fixed by zy END
                                newLead.Rroom__c = null;
                                break;
                            }
                        }
                    }
                }
            }
        }
    }
    // 2021/06/31 #JP10242対応 by zy END 
}