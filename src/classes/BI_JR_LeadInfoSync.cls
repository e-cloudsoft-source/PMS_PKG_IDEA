/**
 * バッチ連携：外から連携する顧客情報を反映する
 * JR-らく通機能連携
 * 2015/03/31 Init
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
 * 2016/07/14 予約チャネル名の設定内容変更対応
 * 2016/07/10 予約チャネル名の変換機能追加対応
 * 2016/07/19 店舗別はプラン名で検索できるように改善対応
 * 2016/09/08 プラン明細に非課税明細含め場合、計算結果不正の不具合修正
 * 2016/10/24 予約人数がゼロの不具合改修
 * 2016/10/26 部屋タイプと部屋が1対1の場合は故障部屋を割当される不具合改修
 * 2016/10/21 JR変更機能改善対応、予約変更の場合、予約名を上書きしない、到着日を変更すると、既に割当される部屋をクリア処理追加、項目値自動設定不具合改修
 * 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修
 * 2017/02/21 お子様プランの料金PRICE機能追加 
 * 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応
 * 2017/06/30 XML特殊記号文字UTF-8対応
 * 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応
 * 2017/09/01 最大文字数をこえない問題回避対応
 * 2017/10/09 予約番号重複存在のとき、予約変更できるように改善対応（予約番号から「店舗別、AGTコード、予約番号」別変更対応)
 * 2018/04/10 JR2way機能共通化対応
 * 2018/04/19 氏名変更のみケース対応
 * 2018/08/10 TL->JR変換の紐付ける処理の対応
 * 2018/11/20 小人数取り込み不正の対応
 * 2018/12/30 JR予約変更通知の際に、部屋タイプを自動変更できるように改善対応
 * 2018/12/30 部屋/部屋タイプ不正の場合、部屋と部屋タイプを再設定の改善対応
 * 2019/03/15 (無料)小人0円が小人プランに紐付できるように改善対応
 * 2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する
 * 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応
 * 2019/06/30 予約番号重複存在のとき、間違った予約を更新される不具合対応
 * 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する
 * 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善
 * 2019/11/30 子供料金（RoomDateGuestList)取り込みできるように改善対応
 * 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善
 * 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加
 * 2020/07/30 入湯税の自動入力機能について改善
 * 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善
 **/
global with sharing class BI_JR_LeadInfoSync {
    // 中継アプリの名
    private static final String APPNAME = 'JR';
    // 2016/06/20 EDIT BEGIN
    // 会計商品の商品コード作成する場合、前方数字：例：Pxxxxコードで自動採番を行う
    private static final String PLAN_PRD_PREX_NUM = 'P';
    // 2016/06/20 EDIT END
    // Default チェックアウト時間
    // 2013/02/25 EDIT BEGIN
    //private static final Time defaultCheckinTime = Time.newInstance(15,30,0,0);
    //private static final Time defaultCheckoutTime = Time.newInstance(10,30,0,0);
    // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
    //private static final Time defaultCheckinTime = CommConst.defCheckInTime;
    //private static final Time defaultCheckoutTime = CommConst.defCheckOtTime;
    // 2013/02/25 EDIT END
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
	
    // 2016/06/20 EDIT BEGIN
    // 2015/10/01 店舗コード
    private static String shopCd;
    // 入湯税会計商品情報格納用
    private static AccountMaster__c nyuuTouAcc;
    // サビース料会計商品情報格納用
    private static AccountMaster__c serviceAcc;
    // 調整可能のプラン明細情報の格納
    private static PlanDetailInfo gPlanDetailInf;
    // 予約取込機能改善（変更、キャンセル） BEGIN
    private static Integer LEAD_CREATE_TIME_DIFF_INT = 60000;
    private static String bookingDataId;
    private static String bookingNumber;
    // 予約取込機能改善（変更、キャンセル） END
    // 予約キャンセルの場合、キャンセル内容は本文メールに反映を行う
    private static final Integer commentLength = Lead__c.Comment3__c.getDescribe().getLength();
    private static final Integer emailLength = Lead__c.email__c.getDescribe().getLength();
    // 2016/06/20 EDIT END
    // 2017/09/01 最大文字数をこえない問題回避対応 BEGIN
    private static final Integer indexCommentLength = LeadIndex__c.Comment__c.getDescribe().getLength();
    // 2017/09/01 最大文字数をこえない問題回避対応 END
    // 2017/10/09 予約番号重複存在のとき、予約変更できるように改善対応 BEGIN
    private static Boolean isDupNumberFlg = false;
    // 2017/10/09 予約番号重複存在のとき、予約変更できるように改善対応 END
    // 2018/04/10 JR2way機能共通化対応
    public static CommLogUtils mLogUtils {get;private set;}
    private static Boolean is2way = true;//該当連携対象は2wayがどうか
    // 2018/08/10 TL->JR変換の紐付ける処理の対応
    private static Boolean tl2wayToJr2way = false;
    /*
     * 外部から予約データ連携機能
     */
    webservice static BI_JR_SyncResult upsertLeadInfo(BI_JR_SyncInfo bookingInfo) {
        // 2017/06/30 XML特殊記号文字UTF-8対応 BEGIN
        unescapeXmlProcess(bookingInfo);
        // 2017/06/30 XML特殊記号文字UTF-8対応 END
        // 2016/06/20 EDIT BEGIN
        // 店舗コード
        String accommodationName = bookingInfo.AccommodationName;
        // 2018/04/10 JR2way機能共通化対応 BEGIN
        String pshopCd = BI_JR_ServiceConfigHelp.getCommConfig().shopNameMatchMap.get(accommodationName);
        is2way = false;
        return commUpsertLeadInfo(bookingInfo, pshopCd);
    }
    // JR2Way用 BEGIN
    public static BI_JR_SyncResult commUpsertLeadInfo(BI_JR_SyncInfo bookingInfo, String pShopCd) {
        // JR2Way用 END
        mLogUtils = new CommLogUtils('BI_JR_LeadInfoSync', true);
        mLogUtils.write_method_start('upsertJR2LeadInfo');
        // 2018/12/27 JRログ情報収集機能改善対応 WSQ BEGIN
        if (!is2way) mLogUtils.write_log('インポートXML情報:'+bookingInfo);
        // 2018/12/27 JRログ情報収集機能改善対応 WSQ END
        shopCd = pShopCd;
        // 2018/04/10 JR2way機能共通化対応 END
        mLogUtils.write_log('宿泊施設名：[' + bookingInfo.AccommodationName + ']:店舗コード:[' + shopCd + ']');
        // 変更、キャンセルする場合、予約取込するがどうか判断用フラグ:TRUEの場合、取込みを行う
        Boolean ucIsSyncFlg = BI_JR_ServiceConfigHelp.getAppConfig(shopCd).ucactisSync;
        // 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 ZH BEGIN
        if (BI_JR_ServiceConfigHelp.getAppConfig(shopCd).romanToKanaFlag) convertGuestInfo(bookingInfo);
        // 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 ZH END
        // 2015/12/11 予約取込機能改善（変更、キャンセル） BEGIN
        LEAD_CREATE_TIME_DIFF_INT = BI_JR_ServiceConfigHelp.getCommConfig().mLeadTimeLimit;
        bookingNumber = bookingInfo.TravelAgencyBookingNumber;
        bookingDataId = APPNAME + '_' + bookingNumber;
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
        List < Lead__c > orgLeadLst = new List < Lead__c > ();
        // 2016/06/20 EDIT END
        // 予約情報を更新を行う
        System.debug(logginglevel.INFO, bookingInfo);
        BI_JR_SyncResult rs = new BI_JR_SyncResult();
        //return rs;
        // 2016/06/20 EDIT BEGIN
        Savepoint sp = Database.setSavepoint();
        try {
            // 2017/10/09 「getExistLeadIndexByDataId」２回目呼出問題回避対応 BEGIN
            List < LeadIndex__c > rslst = null;
            // 2017/10/09 「getExistLeadIndexByDataId」２回目呼出問題回避対応 END
            // 2013/06/20 変更ステータス連携対象外
            if (bookingInfo.dmlAction == BI_JR_DmlAction.UPD ||
                bookingInfo.dmlAction == BI_JR_DmlAction.CANCEL) {
                // Data発生源の条件を追加する
                //String dataFrom = bookingInfo.DataFrom;
                // 2016/06/20 EDIT BEGIN
                if (CommUtils.isBlank(bookingNumber)) {
                    rs.result = BI_JR_Result.NG;
                    return rs;
                }
                mLogUtils.write_log('------DataID------' + bookingNumber);
                // 2016/06/20 EDIT END
                // 既存の予約インデックス情報を取得する「予約番号から取得する」
                // 2017/10/09 「getExistLeadIndexByDataId」２回目呼出問題回避対応 BEGIN
                //List<LeadIndex__c> rslst = getExistLeadIndexByDataId(bookingInfo);
                rslst = getExistLeadIndexByDataId(bookingInfo);
                // 2017/10/09 「getExistLeadIndexByDataId」２回目呼出問題回避対応 END
                // 既存の予約情報がない場合
                if (rslst.isEmpty()) {
                    // 変更の場合、新規作成を行う
                    if (bookingInfo.dmlAction == BI_JR_DmlAction.UPD) {
                        // 元の予約インデックスは何も処理を行わない
                        mLogUtils.write_log('DataIDと一致するご予約情報はSalesforceからみつかりません。元のデータが更新対象外になる');
                    }
                    // 次の変更後の新規処理を行う
                    else if (bookingInfo.dmlAction == BI_JR_DmlAction.CANCEL) {
                        mLogUtils.write_log('DataIDと一致するご予約情報はSalesforceからみつかりません。元のデータがキャンセル対象外になる');
                        // 予約インデックスのみ作成して、XMLを格納する
                        // DataIDが非存在する場合、単に該当XMLはSalesforceにアップロードを行う
                        LeadIndex__c dumyIndex = new LeadIndex__c(ID__c = bookingNumber, EventSource__c = bookingInfo.DataFrom, StatusLst__c = CommConst.LEAD_ST_CANCEL, APPNAME__c = APPNAME);
                        insert dumyIndex;
                        mLogUtils.write_log('該当キャンセルXMLファイルは下記予約インデックス[' + dumyIndex.Id + 'にアップロード済');
                        rs.sfdcId = dumyIndex.Id;
                        // キャンセルの場合、新規の予約インデックスデータのみ作成して、XMLを格納する
                        rs.result = BI_JR_Result.OK;
                        return rs;
                    }
                    // 2016/06/20 EDIT END
                } else {
                    // 変更時刻を設定する
                    LeadIndex__c leadIndex = rslst[0];
                    if (bookingInfo.dmlAction == BI_JR_DmlAction.UPD) {
                        leadIndex.TravelAgencyBookingUpdDateTime__c = DateTime.newInstance(bookingInfo.TravelAgencyBookingDate, bookingInfo.TravelAgencyBookingTime != null ? bookingInfo.TravelAgencyBookingTime : Time.newInstance(0, 0, 0, 0));
                    }
                    if (bookingInfo.dmlAction == BI_JR_DmlAction.CANCEL) {
                        leadIndex.TravelAgencyBookingDelDateTime__c = DateTime.newInstance(bookingInfo.TravelAgencyBookingDate, bookingInfo.TravelAgencyBookingTime != null ? bookingInfo.TravelAgencyBookingTime : Time.newInstance(0, 0, 0, 0));
                    }
                    // 予約インデックスのデータ種別に更新を行う
                    leadIndex.DataClassification__c = bookingInfo.dmlAction.name();
                    // 2015/09/10 ADD BEGIN
                    leadIndex.APPNAME__c = APPNAME;
                    // 2015/09/10 ADD END
                    // 変更、キャンセル連動対応の場合、予約インストールのステータスも取消を行う
                    if (ucIsSyncFlg && bookingInfo.dmlAction == BI_JR_DmlAction.CANCEL) {
                        leadIndex.StatusLst__c = CommConst.LEAD_ST_CANCEL;
                    }
                    update leadIndex;
                    // 変更、キャンセル情報を取込ない制御の場合
                    if (!ucIsSyncFlg) {
                        mLogUtils.write_log('変更、キャンセルするため、予約取込処理対象外になる');
                        rs.sfdcId = rslst[0].Id;
                        rs.result = BI_JR_Result.OK;
                        return rs;
                    }
                    // 既存の予約インデックス、予約インデックスSUB,予約情報へ変更、キャンセル処理を行う
                    // 既存の予約インデックスと関連の予約インスタントSUB情報を取得する
                    Set < Id > subLeadIds = new Set < Id > ();
                    for (LeadIndex__c subIndex: [select id from LeadIndex__c where ParentLeadIndxRef__c =: leadIndex.id]) {
                        subLeadIds.add(subIndex.id);
                    }
                    // 予約はキャンセルされる場合
                    if (bookingInfo.dmlAction == BI_JR_DmlAction.CANCEL) {
                        // 同じ予約インデックスを所属する予約情報は全部キャンセルを行う
                        orgLeadLst = [select id, ReservedStatus__c, Comment3__c, RoomGroupNo__c, EntryTime__c, LeadIndexSubId__c, LeadIndexRef__c, email__c, Relcontact__c, Field2__c, EventSource__c, BookingDataID__c, Departure__c, CreatedDate, Nights__c, PlanSycnFlag__c, LeadIndexRef__r.LeadName__c, Name, refTypeOfRooms__c, Rroom__c
                			// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ BEGIN
                			,RoomUpdFlg__c
                			// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ END
                            from Lead__c
                            where(LeadIndexRef__c =: leadIndex.id or LeadIndexSubId__c =: subLeadIds)
                            And CancelBool__c !=: CommConst.LEAD_ST_CANCEL_FLG
                        ];
                        List < Lead__c > emailUpdLeadLst = filterJRImportData(orgLeadLst, bookingInfo, leadIndex, subLeadIds);
                        for (Lead__c orgLead: emailUpdLeadLst) {
                            // キャンセルメール本文を設定する
                            orgLead.email__c = CommLogUtils.removeOverLogString(bookingInfo.specialServiceRequest + '\n\n\n' + CommUtils.nullToBlank(orgLead.email__c), emailLength);
                        }
                    } else if (bookingInfo.dmlAction == BI_JR_DmlAction.UPD) {
                        // 2017/10/09 予約番号重複存在のとき、予約変更できるように改善対応 BEGIN
                        // 複数予約番号が非存在場合
                        if (!isDupNumberFlg) {
                            // 2017/10/09 予約番号重複存在のとき、予約変更できるように改善対応 END
                            // 既存予約変更、キャンセル処理する場合、既存の予約情報を一回キャンセルを更新する
                            orgLeadLst = [select id, ReservedStatus__c, Comment3__c, RoomGroupNo__c, EntryTime__c, LeadIndexSubId__c, LeadIndexRef__c, email__c, Relcontact__c, Field2__c, EventSource__c, BookingDataID__c, Departure__c, CreatedDate, Nights__c, PlanSycnFlag__c, LeadIndexRef__r.LeadName__c, Name, refTypeOfRooms__c, Rroom__c, Field348__c
                                ,Field276__c
                				// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ BEGIN
                				,RoomUpdFlg__c
                				// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ END
                                from Lead__c
                                // 同じ予約インデックスに所属する　OR　
                                where((LeadIndexRef__c =: leadIndex.id or BookingDataID__c =: bookingDataId) OR(LeadIndexSubId__c =: subLeadIds and LeadIndexSubId__c != null))
                                And CancelBool__c !=: CommConst.LEAD_ST_CANCEL_FLG
                                // and LeadIndexSubId__c = :subLeadIds
                                // and LeadIndexSubId__c != null 
                                // 同じ部屋、泊数順番で既存予約情報を取得する
                                order by LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c, EntryTime__c
                            ];
                            // 予約変更の場合、電文から作成の予約情報のみ変更処理を行う、その以外の予約情報は処理対象外になる
                            orgLeadLst = filterJRImportData(orgLeadLst, bookingInfo, leadIndex, subLeadIds);
                            // 2017/10/09 予約番号重複存在のとき、予約変更できるように改善対応 BEGIN
                        } else {
                            // 既存予約変更、キャンセル処理する場合、既存の予約情報を一回キャンセルを更新する
                            orgLeadLst = [select id, ReservedStatus__c, Comment3__c, RoomGroupNo__c, EntryTime__c, LeadIndexSubId__c, LeadIndexRef__c, email__c, Relcontact__c, Field2__c, EventSource__c, BookingDataID__c, Departure__c, CreatedDate, Nights__c, PlanSycnFlag__c, LeadIndexRef__r.LeadName__c, Name, refTypeOfRooms__c, Rroom__c, Field348__c
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
                            orgLeadLst = filterJRImportData(orgLeadLst, bookingInfo, leadIndex, subLeadIds);
                        }
                        // 2017/10/09 予約番号重複存在のとき、予約変更できるように改善対応 END
                    }
                    // アクセス権限制限するため、キャンセル処理する場合、削除から更新に変更する
               		// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ BEGIN
               		boolean chgRoomTypeFlag = BI_JR_ServiceConfigHelp.getAppConfig(shopCd).chgRoomTypeFlag;
               		// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ END
                    for (Lead__c lead: orgLeadLst) {
                        // 2015/10/15 Ver15.71以後、予約変更処理ロジック対応するため、下記設定ロジックを変更する BEGIN
                        String cancelMessage = '<br/>' + System.now().format('yyyy/MM/dd HH:mm:ss:SSS') + ' ';
                        if (bookingInfo.dmlAction == BI_JR_DmlAction.CANCEL) {
                            //キャンセル対応
                            cancelMessage += Label.CONST_038_0002;
                            lead.EventSource__c = bookingDataId + '_' + DateTime.now().getTime();
                            lead.ReservedStatus__c = CommConst.LEAD_ST_CANCEL;
                        } else if (bookingInfo.dmlAction == BI_JR_DmlAction.UPD) {
                            //予約変更対応
                            cancelMessage += Label.CONST_038_0003;
                            // 2018/04/19 氏名変更のみケース対応 BEGIN
					        if (bookingInfo.isUpdForName) {
					            // メール本文に変更内容を設定する
					            lead.email__c = CommLogUtils.removeOverLogString(bookingInfo.specialServiceRequest + '\n\n\n' + CommUtils.nullToBlank(lead.email__c), emailLength);
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
                    if (bookingInfo.dmlAction == BI_JR_DmlAction.CANCEL) {
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
                        mLogUtils.write_log('既存予約情報(' + orgLeadLst.size() + '件)をキャンセル済');
                        // 処理結果を戻る
                        rs.sfdcId = rslst[0].Id;
                        rs.result = BI_JR_Result.OK;
                        return rs;
                    }
                    //update rslst[0];
                    // 2018/04/19 氏名変更のみケース対応 BEGIN
	                else if (bookingInfo.dmlAction == BI_JR_DmlAction.UPD && bookingInfo.isUpdForName) {
	                    CommLogicProcess logic = new CommLogicProcess();
	                    logic.preventShopAuthCheckSetup(orgLeadLst);
	                    if (!orgLeadLst.isEmpty()) update orgLeadLst;
	                    logic.restoreShopAuthCheckSetup(orgLeadLst, true);
	                }
                	// 2018/04/19 氏名変更のみケース対応 END
                }
            }
            // 2016/06/02 新規予約情報を重複取り込み回避対応（同じ予約番号が存在すると、新規取り込みなし、XMLのみコピーする） BEGIN
            else if (bookingInfo.dmlAction == BI_JR_DmlAction.INS) {
                if (CommUtils.isBlank(bookingNumber)) {
                    rs.result = BI_JR_Result.NG;
                    return rs;
                }
                /* JRの中に、同じ予約番号は別々取り込みが存在するため、重複チェックが要らない
            if (!BI_JR_ServiceConfigHelp.getCommConfig().bIsDebug) {
                List<LeadIndex__c> rslst = getExistLeadIndexByDataId(bookingInfo);
                if (!rslst.isEmpty()) {
                    if(bookingInfo.dmlAction == BI_JR_DmlAction.INS){
mLogUtils.write_log('該当データID[' + bookingNumber + ']SalesforceID[' + rslst[0].Id + ']の予約情報は既に取込済ため、重複取込できません。');
                        rs.sfdcId = rslst[0].Id;
                        rs.result = BI_JR_Result.OK;
                        return rs;
                    }
                }
            }*/
            }

            // 2016/06/20 EDIT END  
            //try {
            // 旅行会社情報の新規・更新を行う
            List < Account > traveCompany = upsertTravelInfo(bookingInfo);
            // 団体代表者の情報は顧客へ登録する
            // 2016/06/20 EDIT BEGIN
            //Contact pkuser = upsertContact(bookingInfo);
            Contact pkuser = upsertContact(bookingInfo, orgLeadLst.isEmpty() ? null : orgLeadLst[0]);
            // 2016/06/20 EDIT END
            // 予約インデックスオブジェクト
            // 2017/10/09 「getExistLeadIndexByDataId」２回目呼出問題回避対応 BEGIN
            LeadIndex__c leadIndex = upsertLeadIndex(bookingInfo, pkuser, traveCompany, rslst);
            // 2017/10/09 「getExistLeadIndexByDataId」２回目呼出問題回避対応 END
            // 予約データを作成する　
            // 2016/06/20 EDIT BEGIN
            //upsertLead(bookingInfo, leadIndex, pkuser, traveCompany);
            upsertLead(bookingInfo, leadIndex, pkuser, traveCompany, shopCd, orgLeadLst);
            // 2016/06/20 EDIT BEGIN
            // 処理結果設定を行う
            rs.sfdcId = leadIndex.Id;
            rs.result = BI_JR_Result.OK;
        } catch (CommException ex) {
            DataBase.rollback(sp);
            mLogUtils.write_error(ex.getStackTraceString());
            System.debug(LoggingLevel.ERROR, ex.getStackTraceString());
            System.debug(LoggingLevel.ERROR, ex.getMessage());
            rs.result = BI_JR_Result.NG;
            rs.message = ex.getMessage();
        } catch (Exception e) {
            DataBase.rollback(sp);
            mLogUtils.write_error(e.getStackTraceString());
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());
            System.debug(LoggingLevel.ERROR, e.getMessage());
            rs.result = BI_JR_Result.NG;
            rs.message = e.getMessage();
        }
        mLogUtils.write_method_end();
        // 2018/12/27 JRログ情報収集機能改善対応 WSQ BEGIN
        // JR1wayの場合、ログ出力を行う
        if (!is2way) CommLogUtils.saveLogToDb(mLogUtils.getAllLog(),CommLogUtils.LogType.JR1WAY,1000);
        // 2018/12/27 JRログ情報収集機能改善対応 WSQ END
        return rs;
    }
    // 2016/06/20 EDIT BEGIN
    // 2017/10/09 予約番号重複存在のとき、予約変更できるように改善対応 BEGIN
    @TestVisible private static String testLoadXmlMsg;
    private static string getChildElementByName(Dom.XMLNode parentNode, String elementName) {
        if (parentNode == null) return null;
        Dom.XMLNode childrenNode = parentNode.getChildElement(elementName, null);
        return getChildElementValue(childrenNode);
    }
    private static String getChildElementValue(Dom.XMLNode childNode) {
        if (childNode == null) return null;
        return CommUtils.nullToBlank(childNode.getText());
    }
    // 既存予約INDEX情報を取得する
    private static List < LeadIndex__c > getExistLeadIndexByDataId(BI_JR_SyncInfo bookingInfo) {
        // 2019/06/30 予約番号重複存在のとき、間違った予約を更新される不具合対応 WSQ BEGIN
        String wkSalesOfficeCompanyCode = CommUtils.nullToBlank(bookingInfo.SalesOfficeCompanyCode);
        // 2019/06/30 予約番号重複存在のとき、間違った予約を更新される不具合対応 WSQ END
        //return [select id,EntryDate__c,CreatedDate,TravelAgencyBookingUpdDateTime__c,TravelAgencyBookingDelDateTime__c,LeadName__c from LeadIndex__c
        List < LeadIndex__c > wkleadindexs = [select id, EntryDate__c, CreatedDate, TravelAgencyBookingUpdDateTime__c, TravelAgencyBookingDelDateTime__c, LeadName__c, Channel__c
            // 2019/06/30 予約番号重複存在のとき、間違った予約を更新される不具合対応 WSQ BEGIN
            ,(Select id From LeadIndexRef__r 
                 where (SalesOfficeInfoRef__r.SalesOfficeCompanyCodeJR__c =: wkSalesOfficeCompanyCode OR SalesOfficeInfoRef__r.Parent.SalesOfficeCompanyCodeJR__c =: wkSalesOfficeCompanyCode)
                    And refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c =: shopCd
            )
            // 2019/06/30 予約番号重複存在のとき、間違った予約を更新される不具合対応 WSQ END
            from LeadIndex__c
            where ID__c =: bookingNumber
            And EventSource__c =: bookingInfo.DataFrom
            And APPNAME__c =: APPNAME
            And StatusLst__c !=: CommConst.LEAD_ST_CANCEL
            //order by CreatedDate desc limit 1];
            order by CreatedDate desc
        ];
        // 2019/06/30 予約番号重複存在のとき、間違った予約を更新される不具合対応 WSQ BEGIN

        List < LeadIndex__c >leadindexs = new list<LeadIndex__c>();
       	for (LeadIndex__c ldx : wkleadindexs) {
        	if (!ldx.LeadIndexRef__r.isEmpty()) {
        		leadindexs.add(ldx);
        		break;
        	}
        }
        // 1件のみ、店舗別の場合
        // 1件のみ、同じ店舗場合
        // 2件以上場合
        isDupNumberFlg = wkleadindexs.size() > 1;
        // 予約情報が重複存在する場合、既存関連の予約情報、AGT情報を判断する
        //isDupNumberFlg = false;
        // 2019/06/30 予約番号重複存在のとき、間違った予約を更新される不具合対応 WSQ END
        if (leadindexs.size() > 1) {
            // 予約番号が重複存在することが発生する
            isDupNumberFlg = true;
            // 該当予約に関連ファイルの情報を取得する
            set < id > leadIdxIds = new set < Id > ();
            for (LeadIndex__c leadIdx: leadindexs) leadIdxIds.add(leadIdx.Id);
            // 該当予約インデックスと関連のXMLのマッピング情報格納
            map < id, attachment > relIdxAttMap = new map < id, attachment > ();
            // 予約添付ファイルリスト情報を取得する【作成時間降順】
            list < attachment > attList = [select id, parentId, body from attachment where parentId =: leadIdxIds order by createddate desc];
            for (attachment att: attList) {
                if (!relIdxAttMap.containsKey(att.parentId)) relIdxAttMap.put(att.parentId, att);
            }
            // チェック対象予約インデックス情報を格納用リスト
            List < LeadIndex__c > targetLeadIndex = new List < LeadIndex__c > ();
            // 複数予約インデックスが存在する
            for (LeadIndex__c leadIdx: leadindexs) {
                Id leadIdxId = leadIdx.Id;
                // 該当予約インデックスの添付ファイルを取得する
                // 該当添付ファイルが非存在すると、次の予約インデックスにチェック
                if (!relIdxAttMap.containsKey(leadIdxId)) continue;
                // 該当予約インデックスに含めているXMLファイル
                Attachment attdata = relIdxAttMap.get(leadIdxId);
                // 既存のXML情報を取得する
                String body = attdata.body.tostring();
                Dom.Document doc = new Dom.Document();
                if (Test.isRunningTest()) doc.load(testLoadXmlMsg);
                else doc.load(body);
                // DATA/BOOKINGID 
                Dom.XMLNode allotmentBookingReportNode = doc.getRootElement();
                if (allotmentBookingReportNode != null) {
                    for (Dom.XMLNode childNode: allotmentBookingReportNode.getChildElements()) {
                        // 既存のXMLの「宿泊施設側情報」情報を取得する
                        if (childNode.getName().equalsIgnoreCase('AccommodationInformation')) {
                            // 宿泊施設名コードと宿泊施設名
                            String AccommodationCode = CommUtils.nullToBlank(getChildElementByName(childNode, 'AccommodationCode'));
                            String curAccommodationCode = CommUtils.nullToBlank(bookingInfo.AccommodationCode);
                            if (CommUtils.isBlank(AccommodationCode)) {
                                AccommodationCode = CommUtils.nullToBlank(getChildElementByName(childNode, 'AccommodationName'));
                                curAccommodationCode = CommUtils.nullToBlank(bookingInfo.AccommodationName);
                            }
                            // 旅行会社コード
                            String SalesOfficeCompanyCode = null;
                            Dom.XMLNode travelNode = childNode.getChildElement('SalesOfficeInformation', null);
                            if (travelNode != null) {
                                SalesOfficeCompanyCode = CommUtils.nullToBlank(getChildElementByName(travelNode, 'SalesOfficeCompanyCode'));
                            }
                            // 旅行会計コード&&宿泊施設名コード 上記情報が一致すると、対象データになる
                            if (bookingInfo.SalesOfficeCompanyCode == SalesOfficeCompanyCode && AccommodationCode == curAccommodationCode) {
                                targetLeadIndex.add(leadIdx);
                                break;
                            }
                        }
                    }
                }
                // 予約インデックス比較一致が存在する場合、処理済み、次の処理を行う
                if (!targetLeadIndex.isEmpty()) break;
            }
            // 予約インデックスのXMLにより、チェック結果はない場合、
            // 既存予約の「旅行会計コード」と「店舗コード」と「予約番号」でチェック、情報一致存在するとき、該当予約に所属の予約インデックス情報を更新を行う
            if (targetLeadIndex.isEmpty()) {
                map < id, LeadIndex__c > leadindexIds = new map < id, LeadIndex__c > ();
                for (LeadIndex__c leadIdx: leadindexs) leadindexIds.put(leadIdx.Id, leadIdx);
                String SalesOfficeCompanyCode = CommUtils.nullToBlank(bookingInfo.SalesOfficeCompanyCode);
                List < Lead__c > relLeads = [select id, LeadIndexRef__c from Lead__c
                    where LeadIndexRef__c =: leadindexIds.keyset()
                    // 予約旅行会計コードチェック
                    And(SalesOfficeInfoRef__r.SalesOfficeCompanyCodeJR__c =: salesOfficeCompanyCode OR SalesOfficeInfoRef__r.Parent.SalesOfficeCompanyCodeJR__c =: salesOfficeCompanyCode)
                    And refTypeOfRooms__c in (select id from TypeOfRooms__c where ShopInfoRef__r.ShopCode__c =: shopCd)
                    //And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 
                    limit 1
                ];
                // 関連情報が存在するとき
                if (!relLeads.isEmpty()) {
                    targetLeadIndex.add(leadindexIds.get(relLeads[0].LeadIndexRef__c));
                }
            }
            return targetLeadIndex;
        } else {
        	// 2018/08/10 TL->JR変換の紐付ける処理の対応 BEGIN
			boolean tl2jrFlg = BI_JR_ServiceConfigHelp.getAppConfig(shopCd).tl2jrFlg;
        	if (tl2jrFlg && leadindexs.isEmpty()) {
        		String tlAppName = BI_JR_ServiceConfigHelp.ProcessingType.TL.Name();
        		// TL情報を取得する 
		        leadindexs = [select id, EntryDate__c, CreatedDate, TravelAgencyBookingUpdDateTime__c, TravelAgencyBookingDelDateTime__c, LeadName__c, Channel__c,ID__c
		            from LeadIndex__c
		            where TravelLeadNo__c =: bookingNumber
		            And APPNAME__c =: tlAppName
		            And StatusLst__c !=: CommConst.LEAD_ST_CANCEL
		            order by CreatedDate desc
		        ];
		        if (!leadindexs.isEmpty()) {
		        	tl2wayToJr2way = true;
		        }
mLogUtils.write_log('予約番号：'+ bookingNumber);
mLogUtils.write_log('APPNAME：'+ tlAppName);
mLogUtils.write_log('TL既存データ：'+ leadindexs);
        	}
        	// 2018/08/10 TL->JR変換の紐付ける処理の対応 END
            return leadindexs;
        }
        // 2017/10/09 予約番号重複存在のとき、予約変更できるように改善対応 END
    }
    // 2016/06/20 EDIT END
    /**
     * 予約基本情報
     **/
    private static LeadIndex__c upsertLeadIndex(BI_JR_SyncInfo bookingInfo, Contact pkuser, List < Account > TraveCompany, list < LeadIndex__c > existLeadIndex) {
        mLogUtils.write_method_start('upsertLeadIndex');

        // 2016/06/23 BEGIN
        // 2017/10/09 「getExistLeadIndexByDataId」２回目呼出問題回避対応 BEGIN
        //List<LeadIndex__c> rslst = getExistLeadIndexByDataId(bookingInfo);
        List < LeadIndex__c > rslst = existLeadIndex == null ? new List < LeadIndex__c > () : existLeadIndex;
        // 2017/10/09 「getExistLeadIndexByDataId」２回目呼出問題回避対応 END
        boolean updFlag = bookingInfo.dmlAction == BI_JR_DmlAction.UPD;
        LeadIndex__c leadIndex = new LeadIndex__c(ID__c = bookingNumber);
        if (updFlag && !rslst.isEmpty()) {
            leadIndex = rslst[0];
        }
        // 2016/10/21 TL変更機能改善対応[予約変更の場合、予約名を上書きしない対応] BEGIN
        boolean updFlgIsInsert = updFlag && rslst.isEmpty(); // 更新　かつ　更新元はなかった場合、該当フラグはTRUE
        // 2016/10/21 TL変更機能改善対応[予約変更の場合、予約名を上書きしない対応] END
        System.debug(LoggingLevel.INFO, '-------- leadIndex  ------' + leadIndex);
        // 2016/06/23 END
        if (updFlag || bookingInfo.dmlAction == BI_JR_DmlAction.INS) {
            // 新規データ作成を行う
            DateTime checkInDt = (bookingInfo.CheckInTime == null ? null : DateTime.newInstance(bookingInfo.CheckInDate, bookingInfo.CheckInTime));
            BI_JR_Member member = bookingInfo.member;
            leadIndex.APPNAME__c = APPNAME;
            leadIndex.DataClassification__c = bookingInfo.dmlAction.name();
            leadIndex.EventSource__c = bookingInfo.DataFrom;
            leadIndex.TravelLeadNo__c = bookingNumber; // 2013/12/27 ADD
            leadIndex.EntryDate__c = bookingInfo.CheckInDate;
            leadIndex.EntryTime__c = checkInDt == null ? (bookingInfo.Nights == 0 ? defaultDayUseCheckInTime : defaultCheckInTimeStr) : checkInDt.format('HH:mm');
            leadIndex.DepartureDate__c = bookingInfo.CheckOutDate == null ? leadIndex.EntryDate__c.addDays(bookingInfo.Nights) : bookingInfo.CheckOutDate;
            // 2014/02/25 補足情報を追加する BEGIN
            if (member != null) {
                leadIndex.MemberUserName__c = member.UserName;
                leadIndex.MemberUserKana__c = member.UserKana;
                leadIndex.MemberAddPoint__c = member.UserGivinPoints;
                leadIndex.MemberUsePoint__c = member.UserUsePoints;
                leadIndex.MemberUserTel__c = member.UserTel; // 会員電話番号 
                leadIndex.MemberUserMailAddr__c = member.UserMailAddr; // 会員Email 
                leadIndex.MemberUserZip__c = member.UserZip; // 会員郵便番号 
                leadIndex.MemberUserAddr__c = member.UserAddr; // 会員住所 
                leadIndex.MemberUserCorp__c = member.UserCorp; // 会員会社 
                leadIndex.MemberUserDep__c = member.UserDep; // 会員所属部署 
                leadIndex.MemberUserID__c = member.UserID; // 会員番号 
                //leadIndex.MemberUserType__c = member.UserType;    // 会員種別
                //leadIndex.MemberUserDateOfBirth__c = member.UserDateOfBirth;  // 会員生年月日
                /*leadIndex.MemberUserGendar__c = (member.UserGendar == '0' 
                                                ? '男性' 
                                                : (member.UserGendar == '1' 
                                                    ? '女性' 
                                                    : (member.UserGendar == '2' ? '不明' : '' )));    // 会員性別 
                */
                leadIndex.MemberUserEmergencyPhoneNumber__c = member.UserTel; // 会員緊急連絡先番号(携帯等)
            }
            leadIndex.TotalAccommodationCharge__c = String.valueOf(bookingInfo.TotalAccommodationCharge);
            leadIndex.Payment__c = getLocalPaymentInfo(bookingInfo.Payment);
            // 2014/02/25 補足情報を追加する END
            // チェックアウト時間はDefault値設定を行う
            leadIndex.DepartureTime__c = (bookingInfo.CheckOutTime == null ?
                (bookingInfo.Nights == 0
                    // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
                    //  ? (DateTime.newInstance(Date.today(), CommUtils.stringToTime(leadIndex.EntryTime__c).addHours(CommConst.DEF_DAYUSE_STAY_HOURS))).format('HH:mm') 
                    ?
                    ((bookingInfo.CheckOutTime == null && bookingInfo.CheckInTime == null) ?
                        defaultDayUseCheckOtTime :
                        (DateTime.newInstance(Date.today(), CommUtils.stringToTime(leadIndex.EntryTime__c).addHours(CommConst.DEF_DAYUSE_STAY_HOURS))).format('HH:mm')
                    )
                    // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
                    :
                    defaultCheckoutTimeStr) :
                (DateTime.newInstance(bookingInfo.CheckOutDate, bookingInfo.CheckOutTime)).format('HH:mm')
            );
            leadIndex.Nights__c = bookingInfo.Nights;
            // 2012/12/23 ADD
            // 2016/06/20 EDIT BEGIN
            if (CommUtils.isBlank(leadIndex.contactRef__c)) leadIndex.contactRef__c = pkuser.Id;
            // 2016/06/20 EDIT END
            leadIndex.Rooms__c = (bookingInfo.TotalRoomCount == null || bookingInfo.TotalRoomCount == 0) ?
                bookingInfo.roomAndGuestLst.size() : bookingInfo.TotalRoomCount;
            // ネットからの取込時に予約チャネルに旅行会社名で設定する BEGIN
            // 2016/07/10 予約チャネル名の変換機能追加対応 BEGIN
            //leadIndex.Channel__c = TraveCompany != null ? TraveCompany.Name : null;
            leadIndex.Channel__c = getChanelStr(bookingInfo, TraveCompany);
            // 2016/07/10 予約チャネル名の変換機能追加対応 END
            // 2016/01/28 ネットからの取込時に予約チャネルに旅行会社名で設定する END
            // 2013/08/16 予約名追加
            // 2016/10/21 JR変更機能改善対応[予約変更の場合、予約名を上書きしない対応] BEGIN
            if (updFlgIsInsert || bookingInfo.dmlAction == BI_JR_DmlAction.INS)
                // 2016/10/21 JR変更機能改善対応[予約変更の場合、予約名を上書きしない対応] END
                leadIndex.LeadName__c = CommUtils.isBlank(bookingInfo.GuestOrGroupNameKanjiName) ? bookingInfo.GuestOrGroupNameSingleByte : bookingInfo.GuestOrGroupNameKanjiName;
            // 2013/09/10 特記事項設定追加
            // 2017/09/01 最大文字数をこえない問題回避対応 BEGIN
            //leadIndex.Comment__c = bookingInfo.OtherServiceInformation;
            leadIndex.Comment__c = CommLogUtils.removeOverLogString(bookingInfo.OtherServiceInformation, indexCommentLength);
            // 2017/09/01 最大文字数をこえない問題回避対応 END
            leadIndex.TravelAgencyBookingInsDateTime__c = DateTime.newInstance(bookingInfo.TravelAgencyBookingDate, bookingInfo.TravelAgencyBookingTime != null ? bookingInfo.TravelAgencyBookingTime : Time.newInstance(0, 0, 0, 0));
            // 2018/08/10 TL->JR変換の紐付ける処理の対応 BEGIN
            if (tl2wayToJr2way) leadIndex.ID__c = bookingNumber;
            // 2018/08/10 TL->JR変換の紐付ける処理の対応 END
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
    private static Plan__c upsertPlan(BI_JR_SyncInfo bookingInfo, List < Account > TraveCompany) {
        mLogUtils.write_method_start('upsertPlan');
        Plan__c rsPlan = null;
        // プランのPackageCode/プラン名は両方とも存在する場合、処理対象です
        if (CommUtils.isBlank(bookingInfo.PackagePlanName) &&
            CommUtils.isBlank(bookingInfo.PackagePlanCode)) { return null; }
        // 同じプラン名情報を検索する
        List < Plan__c > existPlanLst = new List < Plan__c > ();
        // プラン名が存在する場合とプランコード
        /* 2014/06/06 プラン検索方式変更
        if (!CommUtils.isBlank(bookingInfo.PackagePlanName)) {
            existPlanLst = [select Id, name from Plan__c Where name = :bookingInfo.PackagePlanName limit 1];
        }*/
        String packageCode = CommUtils.nullToBlank(bookingInfo.PackagePlanCode);
        String packageName = formatPlanName(bookingInfo.PackagePlanName);
        System.debug(LoggingLevel.INFO, 'packageCode:' + packageCode);
        System.debug(LoggingLevel.INFO, 'packageName:' + packageName);
        // 2016/07/01 予約チャネル名の設定内容変更対応
        String agtId = !TraveCompany.isEmpty() ? TraveCompany[0].Id : null;
        boolean chanelFromCompany = BI_JR_ServiceConfigHelp.getAppConfig(shopCd).chanelFromCompany;
        if (!chanelFromCompany && TraveCompany.size() > 1) agtId = TraveCompany[1].Id;
        //String shopCode = bookingInfo.AccommodationCode;
        String shopCode = shopCd;
        System.debug(LoggingLevel.INFO, '----------------shopCode---------------' + shopCode);
        // 2016/06/20 EDIT BEGIN
        // パッケージコードが存在する場合、パッケージからSFのプラン変換ルールをチエックする
        if (!CommUtils.isBlank(packageCode)) {
            String planNo = BI_JR_ServiceConfigHelp.getSfPlanNoByAgtPlanInfo(shopCd, bookingInfo.SalesOfficeCompanyCode, packageCode);
            // 該当パッケージコードからSF側のプランNOが設定されている場合
            if (planNo != null) {
                mLogUtils.write_log('AGTパッケージコード「' + packageCode + '」からPlanNo「' + planNo + '」に変換済');
                // 2020/07/30 入湯税の自動入力機能について改善 ZH BEGIN
                //List < Plan__c > planLst = [select Id, name, PlanNo__c, ShopInfoRef__c, client__c, Price__c, ServiceRate__c, JmstRef__r.TaxRate__c from Plan__c where IsClosed__c != true and PlanNo__c =: planNo limit 1];
                List < Plan__c > planLst = [select Id, name, PlanNo__c, ShopInfoRef__c, client__c, Price__c, ServiceRate__c, JmstRef__r.TaxRate__c,BathTaxAccMstRef__c from Plan__c where IsClosed__c != true and PlanNo__c =: planNo limit 1];
                // 2020/07/30 入湯税の自動入力機能について改善 ZH NED
                if (!planLst.isEmpty()) return planLst[0];
            }
        }
        // 2016/06/20 EDIT END
        // 店舗情報格納する
        Map < String, ShopInformation__c > shopInfoMap = new Map < String, ShopInformation__c > ();
        /* 2014.11.18 プラン検索ロジック変更、店舗検索機能を追加 */
        // 2020/07/30 入湯税の自動入力機能について改善 ZH BEGIN
        String queryHeader = ' select Id, name,PlanNo__c,ServiceRate__c,JmstRef__r.TaxRate__c,Price__c,BathTaxAccMstRef__c from Plan__c ';
        // 2020/07/30 入湯税の自動入力機能について改善 ZH END
        String queryLimit = ' limit 1 ';
        // 2014/07/16 非公開プランは検索対象外に対応
        //String whereStr = ' Where (';
        String whereStr = ' Where IsClosed__c != true And (';
        // 店舗別単位でプラン設定する場合、店舗コードとプランのPackageCodeは合わせる確認が必要です
        if (isPlanOfShopFlg) {
            shopInfoMap = ShopInfoUtil.getShopInfoMap();
            // 2016/07/19 店舗別はプラン名で検索できるように改善対応 BEGIN
            if (!CommUtils.isBlank(packageCode)) {
                whereStr += ' PackageCode__c != null And PackageCode__c = :packageCode And ShopInfoRef__c != null And ShopInfoRef__r.ShopCode__c = :shopCode  ';
            } else if (!CommUtils.isBlank(packageName)) {
                whereStr += ' Name != null And Name = :packageName And ShopInfoRef__c != null And ShopInfoRef__r.ShopCode__c = :shopCode  ';
            }
            // 2016/07/19 プラン検索方式：店舗コード＋プラン名 END
            // 2016/06/20 EDIT BEGIN
            if (!CommUtils.isBlank(shopCode)) whereStr += ' And ShopInfoRef__c != null ';
            // 2016/06/20 EDIT END
        } else {
            if (!CommUtils.isBlank(packageCode)) {
                whereStr += ' PackageCode__c = :packageCode ';
            }
            if (!CommUtils.isBlank(packageName)) {
                if (!CommUtils.isBlank(packageCode)) {
                    whereStr += ' Or ';
                }
                whereStr += ' name = :packageName ';
            }
        }
        whereStr += ')';
        String whereStr2 = '';
        if (!CommUtils.isBlank(agtId)) {
            // AGT情報がXMLに設定されている場合、AGT条件に入れて、検索を行う
            whereStr2 = ' And client__c = :agtId ';
            //System.debug(loggingLevel.info, 'SQL1::' + queryHeader + whereStr + whereStr2 + queryLimit);
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
            rsPlan.name = packageName.length() > 80 ? packageName.subString(0, 80) : packageName;
            rsPlan.PackageCode__c = bookingInfo.PackagePlanCode;
            // 2016/07/01 予約チャネル名の設定内容変更対応
            rsPlan.client__c = agtId;
            // 2020/07/30 入湯税の自動入力機能について改善 ZH BEGIN
            if(!isPlanOfShopFlg && shopInfoMap.isEmpty()) shopInfoMap = ShopInfoUtil.getShopInfoMap();
            // 设定有效的关联入汤税商品ID
            rsPlan.BathTaxAccMstRef__c = CommLogicProcess.getBathTaxAccMstRef(shopInfoMap.get(shopCode), shopCode);
            // 2020/07/30 入湯税の自動入力機能について改善 ZH END
            insert rsPlan;
            // 2016/06/20 EDIT BEGIN
            // 新規作成のプラン情報を再取得する
            // 2020/07/30 入湯税の自動入力機能について改善 ZH BEGIN
            //rsPlan = [select Id, name, PlanNo__c, ServiceRate__c, JmstRef__r.TaxRate__c from Plan__c where id =: rsPlan.id];
            rsPlan = [select Id, name, PlanNo__c, ServiceRate__c, JmstRef__r.TaxRate__c,BathTaxAccMstRef__c from Plan__c where id =: rsPlan.id];
            // 2020/07/30 入湯税の自動入力機能について改善 ZH END
            // 2016/06/20 EDIT END
        } else {
            rsPlan = existPlanLst[0];
        }
        mLogUtils.write_method_end();
        return rsPlan;
    }

    // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
    public static String OPTION_MODE{get{ return CommConst.OPTION_MODE;}}
    public static ProductItemUtils.LeadInfoSync ldInfo;
    // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
    // 2016/06/20 EDIT BEGIN
    /**
     * プランの関連プラン明細情報を自動取得を行う
     **/
    private static void setPlanDetailPlusInfo(Plan__c plan) {
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
        Set < String > queryFieldsSet = new Set < String > ();
        queryFieldsSet.addAll(fixQueryFields.split(','));
        String queryStr = 'select ';
        // Query Field List取得する
        for (string fieldApi: queryFieldsSet) {
            queryStr += fieldApi + ',';
        }
        queryStr = queryStr.removeEnd(',');
        queryStr = queryStr + ' From PlanDetail__c where PlanRef__c = :planId order by name ';
        System.debug(LoggingLevel.INFO, 'プラン明細取得::::::::::::::::' + queryStr);
        // 指定のプラン明細情報を取得する
        List < PlanDetail__c > orgPdList = DataBase.query(queryStr);
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
        // 2019/09/15 軽減税率機能対応 WGCH BEGIN
    	// gPlanDetailInf.init(orgPdList);
    	gPlanDetailInf.init(orgPdList, plan);
    	// 2019/09/15 軽減税率機能対応 WGCH END
        mLogUtils.write_method_end();
    }

    public class PlanDetailInfo {
        public planDetailInfo() {
            orgPlanDetailList = new List < PlanDetail__c > ();
            // 室料商品リスト
            priceRoomPdList = new list < PlanDetail__c > ();
            // 調整不可の明細の合計値を格納する[室料以外の設定されている金額]
            priceNotChangeSumVal = 0;
            // 非課税金額合計値を格納する
            priceNoTaxSumVal = 0;
            // 非課税対象リストを格納する
            noTaxPdList = new List < PlanDetail__c > ();
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
        //, BI_JR_ServiceConfigHelp.BOOKINGCONFIG bookingConfig
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
	public static Decimal setPriceRoomPdSumVal(PlanDetailInfo planDetailInf, map<Id, PlanDetail__c> changePdMap){
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
	public static Decimal setPriceRoomPdSumDiffVal(PlanDetail__c changePd, Decimal priceRoomPdSumVal, Decimal diffSum){
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
    private static map < string, AccountMaster__c > childPlanAccMstMap = new map < string, AccountMaster__c > ();
    // 2017/02/21 お子様プランの料金PRICE機能追加 by zh BEGIN
    private static map < string, AccountMaster__c > childPlanPriceAccMstMap = new map < string, AccountMaster__c > ();
    // 2017/02/21 お子様プランの料金PRICE機能追加 by zh END
    // 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ BEGIN
    private static map<String,String> childPlanNameConvertMap = new map<String,String>();
    // 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ END
    // 商品コードー＞プラン
    private static map < string, Plan__c > childPlanPlanMstMap = new map < string, Plan__c > ();
    // 商品コードー＞プラン明細
    private static map < string, planDetailInfo > childPlanDetailMap = new map < string, planDetailInfo > ();
    // childPlanConfigMap:Rate -> PlanNo
    // 2017/02/21 お子様プランの料金PRICE機能追加 by zh BEGIN
    //private static void setChildPlanInfo(map<string, string> childPlanConfigMap) {
    private static void setChildPlanInfo(map < string, string > childPlanConfigMap, map < string, string > ChildPlanPriceConfigMap) {
        //if (childPlanConfigMap == null || childPlanConfigMap.isEmpty()) return;
        if (childPlanConfigMap.isEmpty() && ChildPlanPriceConfigMap.isEmpty()) return;
        // 2017/02/21 お子様プランの料金PRICE機能追加 by zh END
        System.debug(LoggingLevel.INFO, '-------setChildPlanInfo  BEGIN-----------');
        // プラン関連情報を取得する
        mLogUtils.write_method_start('setChildPlanInfo');
        // 指定の条件で店舗別でプラン定義情報を取得する
        list < string > planNos = childPlanConfigMap.values();
        // 2017/02/21 お子様プランの料金PRICE機能追加 by zh BEGIN
        planNos.addAll(ChildPlanPriceConfigMap.values());
        // 2017/02/21 お子様プランの料金PRICE機能追加 by zh END
        // 2020/07/30 入湯税の自動入力機能について改善 ZH BEGIN
        //String queryHeader = ' select Id, name,PlanNo__c,ServiceRate__c,JmstRef__r.TaxRate__c,Price__c,ShopInfoRef__r.ShopCode__c,(Select Id,Price__c,ServiceRate__c,TaxRate__c,AccountMasterRef__c,AccountMasterRef__r.ActionType__c From PlanRef__r)  from Plan__c ';
        String queryHeader = ' select Id, name,PlanNo__c,ServiceRate__c,JmstRef__r.TaxRate__c,Price__c,ShopInfoRef__r.ShopCode__c,(Select Id,Price__c,ServiceRate__c,TaxRate__c,AccountMasterRef__c,AccountMasterRef__r.ActionType__c From PlanRef__r),BathTaxAccMstRef__c  from Plan__c ';
        // 2020/07/30 入湯税の自動入力機能について改善 ZH END
        // 非公開プランは検索対象外に対応
        String whereStr = ' Where PlanNo__c in :planNos And IsClosed__c != true ';
        List < Plan__c > childrenPlan = DataBase.query(queryHeader + whereStr);
        mLogUtils.write_log('-------childrenPlan-----------' + childrenPlan);
        // PlanNo->会計商品
        map < string, AccountMaster__c > locPlanNoToAccMstMap = new map < string, AccountMaster__c > ();
        // 会計商品コードー＞PlanNo
        map < string, string > locProductCdToPlanNoMap = new map < string, string > ();
        // PlanNo->プラン明細
        map < string, planDetailInfo > locChildPlanDetailMap = new map < string, planDetailInfo > ();
        // 子供料金プラン
        for (Plan__c plan: childrenPlan) {
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
            List < AccountMaster__c > accounts = [select id, Name, jmstRef__r.TaxRate__c, ServiceRate__c, Field3__c from AccountMaster__c where Field3__c =: locProductCdToPlanNoMap.keySet()];
            for (AccountMaster__c acc: accounts) {
                // 商品コード
                String productCd = acc.Field3__c;
                String planNo = locProductCdToPlanNoMap.get(productCd);
                // PlanNOー＞会計商品
                locPlanNoToAccMstMap.put(planNo, acc);
            }
        }
        //
        for (string key: childPlanConfigMap.keySet()) {
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
        for (string key: ChildPlanPriceConfigMap.keySet()) {
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
    private static void matchChildrenPlan(BookingEstimateItem__c item, Decimal perPaxRate) {
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
		String key1 = BI_JR_ServiceConfigHelp.getChildRateMatchKey(strCalRate);
		String key2 = BI_JR_ServiceConfigHelp.getChildPriceMatchKey(strChildPrice);
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
            System.debug(LoggingLevel.INFO, '---------item.ProductName__c-------' + item.ProductName__c);
            // 2017/02/21 お子様プランの料金PRICE機能追加 by zh BEGIN
        } else if (childPlanPriceAccMstMap.containsKey(strChildPrice)) {
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

    // 2016/06/20 EDIT END
    /**
     * 予約情報を登録する
     */
    private static void upsertLead(BI_JR_SyncInfo bookingInfo, LeadIndex__c leadIndex, Contact pkuser, List < Account > TraveCompany, String shopCode, List < Lead__c > oldLeadLst) {
        mLogUtils.write_method_start('upsertJR2Lead');
        /*
        // 予約キャンセル　と　更新場合:　既存予約データを全部キャンセルする
        if (bookingInfo.dmlAction == BI_JR_DmlAction.UPD ||
            bookingInfo.dmlAction == BI_JR_DmlAction.CANCEL) {
            // 既存予約データをキャンセルする
            List<Lead__c> existLeadLst = [select id, ReservedStatus__c, Comment3__c from Lead__c where LeadIndexRef__c = :leadIndex.Id And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG];
            for (Lead__c lead : existLeadLst) {
                lead.ReservedStatus__c = CommConst.LEAD_ST_CANCEL;
                //キャンセル対応(外部インタネットから自動連携)
                lead.Comment3__c = CommUtils.nullToBlank(lead.Comment3__c) + '\n' + System.now().format('yyyy/MM/dd HH:mm:ss:SSS') + ' '+Label.CONST_047_0001;
            }
            update existLeadLst;
        }
        // キャンセル場合、処理中止
        if (bookingInfo.dmlAction == BI_JR_DmlAction.CANCEL) return;
        */
        // 2018/04/19 氏名変更のみケース対応 BEGIN
        if (bookingInfo.dmlAction == BI_JR_DmlAction.UPD && bookingInfo.isUpdForName) {
            mLogUtils.write_log('氏名変更のみため、予約変更詳細処理を行わない、メール本文のみ更新');
            mLogUtils.write_method_end();
            return;
        }
        // 2018/04/19 氏名変更のみケース対応 END
        // 2016/06/20 EDIT BEGIN
        // 部屋自動割り振り機能
        boolean autoAssingRoomflag = BI_JR_ServiceConfigHelp.getAppConfig(shopCd).roomAutoAssignFlag;
        System.debug(LoggingLevel.INFO, '--------autoAssingRoomflag---------' + autoAssingRoomflag);
        // 税区分設定
        // 税区分変換を行う
        Integer taxRateKbn = CommConst.APPOPTION_UTP_DEF_KB;
        // XMLの税区分設定情報を取得,SF側の税区分に変換を行う
        String taxServiceFee = bookingInfo.TaxServiceFee;
        System.debug(LoggingLevel.INFO, '--------税区分------------' + taxServiceFee);
        if (taxServiceFee == 'IncludingServiceWithOutTax') {
            taxRateKbn = CommConst.APPOPTION_UTP_DEF_KB_OP4;
        } else if (taxServiceFee == 'IncludingServiceAndTax') {
            taxRateKbn = CommConst.APPOPTION_UTP_DEF_KB_OP2;
        } else if (taxServiceFee == 'WithoutSerivceAndTax' || taxServiceFee == 'WithoutServiceAndTax') {
            taxRateKbn = CommConst.APPOPTION_UTP_DEF_KB_OP3;
        } else if (taxServiceFee == 'WithoutServiceAndIncludingTax' || taxServiceFee == 'WithoutServiceIncludeingTax') {
            taxRateKbn = CommConst.APPOPTION_UTP_DEF_KB_OP1;
        }

        bookingInfo.TaxServiceFee = String.valueOf(taxRateKbn);
        Integer taxSericeFee = CommUtils.nullToIntZero(bookingInfo.TaxServiceFee);
        // 2019/09/15 軽減税率機能対応 WGCH BEGIN
        taxSericeFeeEnd = taxSericeFee;
        // 2019/09/15 軽減税率機能対応 WGCH END
        // 2016/06/20 EDIT END
        //  プラン情報を取得、作成する
        // プラン情報がNULLの場合、見積明細に直接室料を設定する
        Plan__c curPlan = upsertPlan(bookingInfo, TraveCompany);
        // 2016/06/20 EDIT BEGIN
        // プラン明細情報を取得する
        setPlanDetailPlusInfo(curPlan);
        mLogUtils.write_log('プラン情報::' + curPlan);
        // 2016/06/20 EDIT END
        // 部屋タイプID情報を取得する
        Set < String > roomTypeCdSet = new Set < String > ();
        // 2013/02/26 部屋タイプ名情報を格納する
        Set < String > roomTypeNmSet = new Set < String > ();

        for (BI_JR_RoomAndGuestInfo roomAndGuest: bookingInfo.roomAndGuestLst) {
            if (!CommUtils.isBlank(roomAndGuest.room.RoomTypeCode))
                roomTypeCdSet.add(roomAndGuest.room.RoomTypeCode);
            //roomTypeMap.put(roomAndGuest.room.RoomTypeCode);
            // 2013/02/26 部屋タイプ名：部屋ID情報を格納する
            if (!CommUtils.isBlank(roomAndGuest.room.RoomTypeName)) roomTypeNmSet.add(roomAndGuest.room.RoomTypeName);
        }
        // 部屋タイプMAP情報設定する
        Map < String, Id > roomTypeMap = new Map < String, Id > ();
        // 2013/02/26 部屋タイプ名情報を格納する
        Map < String, Id > roomTypeNmMap = new Map < String, Id > ();
        // 2015/07/22 部屋タイプが存在　かつ　対応部屋タイプに対して、１部屋のみの場合、該当部屋は自動的に予約にアサインする
        Map < Id, id > oneTypeToRoomMap = new Map < Id, Id > ();
        // 2016/06/20 EDIT BEGIN
        for (TypeOfRooms__c roomType: [select id, RoomTypeName__c, RoomTypeCode__c, (Select Id From TypeRoomRef__r limit 2) from TypeOfRooms__c where ShopInfoRef__r.ShopCode__c =: shopCode and(RoomTypeCode__c in: roomTypeCdSet Or RoomTypeName__c in: roomTypeNmSet)]) {
            roomTypeMap.put(roomType.RoomTypeCode__c, roomType.Id);
            // 2013/02/26 部屋タイプ名：部屋ID情報を格納する
            if (!CommUtils.isBlank(roomType.RoomTypeName__c)) roomTypeNmMap.put(roomType.RoomTypeName__c, roomType.Id);
            // 自動割り当てフラグはTRUEのみ、該当関連取得を行う
            if (oneRoomAutoAssingRoomFlg) {
                if (roomType.TypeRoomRef__r != null && roomType.TypeRoomRef__r.size() == 1) {
                    oneTypeToRoomMap.put(roomType.Id, roomType.TypeRoomRef__r[0].Id);
                }
            }
        }
        mLogUtils.write_log('roomTypeMap :: ' + roomTypeMap);
        mLogUtils.write_log('oneTypeToRoomMap :: ' + oneTypeToRoomMap);
        // 2016/06/20 EDIT END
        // 2016/10/26 部屋タイプと部屋が1対1の場合は故障部屋を割当される不具合改修 BEGIN
        map < Integer, Room__c > oneRoomCanAssignRoomMap = new map < Integer, Room__c > ();
        // 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 BEGIN
        /*
        // 部屋タイプが存在する場合
        if (!oneTypeToRoomMap.isEmpty()) {
            // 割当できる部屋情報を取得する　
            oneRoomCanAssignRoomMap = getCanAssignRoom(leadIndex,roomTypeMap,autoAssingRoomFlg,bookingInfo);
        }*/
        // 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 END
        // 2016/10/26 部屋タイプと部屋が1対1の場合は故障部屋を割当される不具合改修 END
        // 2015/07/22  部屋タイプが存在　かつ　対応部屋タイプに対して、１部屋のみの場合、該当部屋は自動的に予約にアサインする END
        // 2016/06/20 EDIT BEGIN
        // 部屋タイプにより、自動割り振りできる部屋情報を戻る
        // 2015/10/30 故障部屋は自動割当て機能に追加対応 BEGIN
        //map<Id, List<Room__c>> canAssignRoomMap = new map<Id, List<Room__c>>();
        map < Integer, Room__c > canAssignRoomMap = new map < Integer, Room__c > ();
        System.debug(LoggingLevel.INFO, '--------autoAssingRoomflag--------' + autoAssingRoomflag);
        if (autoAssingRoomflag) {
            canAssignRoomMap = getCanAssignRoom(leadIndex, roomTypeMap, autoAssingRoomflag, bookingInfo, roomTypeNmMap);
            mLogUtils.write_log('複数部屋自動割り当て対象 :: ' + canAssignRoomMap);
        }
        // 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 BEGIN
        // 部屋タイプが存在する場合
        else if (!oneTypeToRoomMap.isEmpty()) {
            // 割当できる部屋情報を取得する　
            oneRoomCanAssignRoomMap = getCanAssignRoom(leadIndex, roomTypeMap, oneRoomAutoAssingRoomFlg, bookingInfo, roomTypeNmMap);
            mLogUtils.write_log('1VS1部屋自動割り当て対象 :: ' + oneRoomCanAssignRoomMap);
        }
        // 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 END
        // 2015/10/30 故障部屋は自動割当て機能に追加対応 END
        // 2016/06/20 EDIT BEGIN

        // 宿泊レコードタイプ
        String bookingRcTypeId = CommLogicProcess.getLeadBookingRecType();
        // 受付日
        //DateTime reserverDt = DateTime.newInstance(bookingInfo.TravelAgencyBookingDate, bookingInfo.TravelAgencyBookingTime);
        // チェックイン日付・日時[基本宿泊情報から]
        DateTime checkInFirstDayDt = DateTime.newInstance(leadIndex.EntryDate__c,
            bookingInfo.CheckInTime == null ? defaultCheckinTime : bookingInfo.CheckInTime);
        // 最後日のチェックアウト日付・日時[基本宿泊情報から]
        DateTime checkOutLastDayDt = DateTime.newInstance(leadIndex.DepartureDate__c,
            bookingInfo.CheckOutTime == null ? defaultCheckoutTime : bookingInfo.CheckOutTime);
        //newLead.RecordTypeId = s.id;
        //Integer roomNoIdx = 0;
        // メール本文[7XXXXX]
        //BI_TL_RisaplBasic risaplBasic = bookingInfo.risaplsinformation.risaplsCommonInformation.risaplBasic;
        // 2013.05.29 ADD パタン６確認する（連泊、１室、１部屋タイプ）
        // 2013.07.10 ADD 同じ日付のデータ数：部屋数　　部屋利用日の範囲は泊数設定
        // 定義した総泊数からLOOPして、その後、部屋数LOOPする
        Integer nights = bookingInfo.Nights; // 総宿泊数
        if (nights == 0) nights = 1;
        Integer rooms = bookingInfo.TotalRoomCount; // 総部屋数
        // 2013/07/05 予約名自動設定対応、団体名または代表者氏名 漢字ー＞団体名または代表者氏名(半角)
        //String leadName = CommUtils.isBlank(bookingInfo.GuestOrGroupNameKanjiName) ? bookingInfo.GuestOrGroupNameSingleByte : bookingInfo.GuestOrGroupNameKanjiName;
        String leadName = leadIndex.LeadName__c;
        // 複数件予約データを作成する
        List < Lead__c > insLeadLst = new List < Lead__c > ();
        // 2013/07/16 記号機能対応 BEGIN
        // N rooms N nightsのとき、特記事項をその日は、一つにする対応と同様に、親部屋マーク（一文字記号）をカスタム設定のパラメータとして、定義、この定義されたマークを予約名の文字列先頭に付加する、
        // また、人数とプランも一つの予約データのみに取り込み、他の予約データは、人数ゼロ、プランなし、と設定する
        String strRoomDelegatePrefix = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomDelegatePrefix__c);
        // N部屋N泊数標識フラグ
        //Boolean isNroomNnightFlg = (nights > 1 && rooms > 1);
        // 2013/07/16 記号機能対応 End

        // 複数予約日ー＞複数部屋タイプから　１部屋タイプ１日予約データを作成する
        //for (BI_JR_RoomAndGuestInfo roomAndGuest: bookingInfo.roomAndGuestLst) 
        // 2016/06/20 EDIT BEGIN
        Map < String, List < BookingEstimateItem__c >> roomToItemsMap = new Map < String, List < BookingEstimateItem__c >> ();
        Map < String, Integer > roomToItemMap = new Map < String, Integer > ();
        // 見積明細に明細登録用会計商品
        nyuuTouAcc = getNyuuTouAcc(); // [入湯税商品定義情報を取得する]
        serviceAcc = getServiceAcc(); // [サビース料商品定義情報を取得する]
        AccountMaster__c commshitulyouAcc = null; // プラン関連の会計商品情報格納   
        // 消費税情報を取得する   
        JMST__c taxRateMst = CommLogicProcess.getTaxRateInfo();
        // XMLに指定のXMLが存在する場合、プラン関連の会計商品（プラン）情報を取得する
        if (curPlan != null) {
            // 指定のプラン情報により、関連の会計商品を捜す
            String productCd = PLAN_PRD_PREX_NUM + curPlan.PlanNo__c;
            List < AccountMaster__c > accounts = [select id, Name, jmstRef__r.TaxRate__c, ServiceRate__c from AccountMaster__c where Field3__c =: productCd];
            // 関連の会計商品が存在する場合
            if (!accounts.isEmpty()) {
                commshitulyouAcc = accounts[0];
            }
            // 関連の会計商品が非存在する場合、回答プラン関連の会計商品を自動作成を行う
            else {
                commshitulyouAcc = new AccountMaster__c(
                    Name = curPlan.Name,
                    Field3__c = productCd,
                    jmstRef__c = taxRateMst.id,
                    ServiceRate__c = curPlan.ServiceRate__c,
                    ActionType__c = CommConst.PROD_ACTION_TYPE_PL
                );
                if (taxRateMst.Id != null) commshitulyouAcc.jmstRef__r = taxRateMst;
                // 2020/07/30 入湯税の自動入力機能について改善 ZH BEGIN
                // 该Plan存在参照入汤税商品, 该Plan的会计商品设定参照对应的Plan处理
                if(curPlan.BathTaxAccMstRef__c != null) commshitulyouAcc.PlanBathTaxAccMstRef__c = curPlan.Id;
                // 2020/07/30 入湯税の自動入力機能について改善 ZH END
                insert commshitulyouAcc;
            }
            // 2016/06/10 子供料金プラン取り込み機能対応 BGEIN
            // 2017/02/21 お子様プランの料金PRICE機能追加 by zh BEGIN
            //setChildPlanInfo(BI_JR_ServiceConfigHelp.getChildPlanConvertConfig(shopCd));
            setChildPlanInfo(BI_JR_ServiceConfigHelp.getChildPlanConvertConfig(shopCd), BI_JR_ServiceConfigHelp.getChildPlanPriceConvertConfig(shopCd));
            // 2017/02/21 お子様プランの料金PRICE機能追加 by zh END
            // 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ BEGIN
        	// プラン設定情報を取得する
        	childPlanNameConvertMap = BI_JR_ServiceConfigHelp.getChildPlanNameConvertConfig(shopCd);
        	// 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ END
            // 2016/06/10 子供料金プラン取り込み機能対応 END
        }
        // プラン関連の会計商品が非存在する場合、室料商品を取得する
        if (commshitulyouAcc == null) {
            commshitulyouAcc = getShiTuLyouAcc(); // [室料商品定義情報を取得する]
        }
        // 見積明細に登録する会計商品
        mLogUtils.write_log('会計商品：' + commshitulyouAcc);
        // 税区分
        mLogUtils.write_log('税区分：' + bookingInfo.TaxServiceFee);

        Boolean isUpdateFlag = bookingInfo.dmlAction == BI_JR_DmlAction.UPD;
        // 予約情報にプラン存在するがどうかチエックを行う、プランが存在すると、１部屋の総利用金額は該当プランに設定を行う
        // プラン情報はXMLに未定義すると、室料の会計商品で、総金額は室料の金額に設定を行う
        BookingEstimateItem__c cloneItem = null;
        if (commshitulyouAcc.Id != null) {
            cloneItem = new BookingEstimateItem__c(
                refAccountMaster__c = commshitulyouAcc.id,
                refAccountMaster__r = commshitulyouAcc,
                //UnitPriceDefKb__c = bookingInfo.TaxServiceFee,
                TaxRate__c = taxRateMst.TaxRate__c);
            if (curPlan != null) {
                //item.PlanDetailSyncInfo__c = curPlan.id;
                cloneItem.Field3__c = PLAN_PRD_PREX_NUM + curPlan.PlanNo__c;
                // 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応 by zh BEGIN
                boolean plannameToEstflag = BI_JR_ServiceConfigHelp.isSfPlanNmToEstProdNm(shopCd);
                mLogUtils.write_log('見積明細名はプラン目に変更::::' + plannameToEstflag);
                if (plannameToEstflag) {
                    cloneItem.ProductName__c = curPlan.Name;
                } else {
                    cloneItem.ProductName__c = CommUtils.isBlank(bookingInfo.PackagePlanName) ?
                        curPlan.Name :
                        formatPlanName(bookingInfo.PackagePlanName);
                }
                // 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応 by zh END
                cloneItem.ActionType__c = CommConst.PROD_ACTION_TYPE_PL;
            }
        }
        System.debug(LoggingLevel.INFO, '--------見積もり明細取り込完了::roomToItemsMap--------' + roomToItemsMap.keySet());
        if (bookingInfo.TravelAgencyBookingTime == null) bookingInfo.TravelAgencyBookingTime = Time.newInstance(0, 0, 0, 0);
        Map < Integer, List < BookingEstimateItem__c >> roomMaps = new Map < Integer, List < BookingEstimateItem__c >> ();
        Map < String, Object > autoSetupfieldMap = BI_JR_ServiceConfigHelp.getAppConfig(shopCd).fieldMap;
        Map < String, Schema.DescribeFieldResult > finalFieldMap = CommUtils.getFieldMetaData(Lead__c.getSObjectType().getDescribe(), autoSetupfieldMap.keySet());
        boolean isRoomRateFlg = bookingInfo.RoomRateOrPersonalRate == 'PersonalRate' ? false : true;
        mLogUtils.write_log('予約情報新規、変更処理開始');
        //予約　グループのマッピングを作成
        Map < Integer, List < Lead__c >> groupLeadMap = new Map < Integer, List < Lead__c >> ();
        Lead__c beforeLead = null;
        integer roomIndex = 0;
        // 2018/12/30 部屋/部屋タイプ不正の場合、部屋と部屋タイプを再設定の改善対応 WSQ BEGIN
        map<id, id> orgLeadRoomAndTypeMap = new map<id, id>();
        // 2018/12/30 部屋/部屋タイプ不正の場合、部屋と部屋タイプを再設定の改善対応 WSQ END
        // 既存予約情報はグループ化する
        for (Lead__c lead: oldLeadLst) {
            // 別の部屋の予約情報を切り替えする場合
            if (beforeLead != null) {
                if (beforeLead.LeadIndexSubId__c != lead.LeadIndexSubId__c || beforeLead.RoomGroupNo__c != lead.RoomGroupNo__c) {
                    roomIndex++;
                }
            }
            beforeLead = lead;
            if (!groupLeadMap.containsKey(roomIndex)) {
                groupLeadMap.put(roomIndex, new List < Lead__c > ());
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
        Map < String, Id > lastRoomMap = new Map < String, Id > ();
        Set < String > userOrgLeadSet = new Set < String > ();
        Set < Id > updateOrgLeadIdSet = new Set < Id > ();
        // 2016/07/10 予約チャネル名の変換機能追加対応 BEGIN
        String chanelStr = getChanelStr(bookingInfo, TraveCompany);
        // 2016/07/10 予約チャネル名の変換機能追加対応 END
        // 2016/01/07 予約キャンセルの場合、キャンセル内容は本文メールに反映を行う BEGIN
        //integer commentLength = Lead__c.Comment3__c.getDescribe().getLength();
        //integer emailLength = Lead__c.email__c.getDescribe().getLength();
        // 2016/01/07 予約キャンセルの場合、キャンセル内容は本文メールに反映を行う END
        // 2016/06/20 EDIT END
        // N泊間の予約情報
        //boolean dateSameFlag = false;
        map < Integer, Integer > roomNoSameDateMap = new map < Integer, Integer > ();
        System.debug(LoggingLevel.INFO, '-------- bookingInfo.roomAndGuestLst  ------' + bookingInfo.roomAndGuestLst);
        // 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応 by zh BEGIN
        // 支払明細はどの部屋どの泊にリンクすることINDEXを記録する
        Integer payMediaLinkPos = 0;
        if (BI_JR_ServiceConfigHelp.getAppConfig(shopCd).payMeaidToLastDayFlag) payMediaLinkPos = (nights*rooms-rooms);
        // 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応 by zh END
        // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ BEGIN
        // 既存予約の見積明細を上書きするがどう切り替え用フラグ
        Boolean isClearEstItemsFlag = BI_JR_ServiceConfigHelp.getAppConfig(shopCd).modifyEstItemsFlag;
        // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ END
        for (Integer i = 0; i < nights; i++) {
            // 1日間N部屋の予約情報取得する
            for (Integer j = 0; j < rooms; j++) {
                // データ取得INDEX
                if (!roomNoSameDateMap.containsKey(j)) roomNoSameDateMap.put(j, 0);
                Integer notSameIdx = roomNoSameDateMap.get(j);
                // 2016/06/28 begin
                Integer idx = (i - notSameIdx) * rooms + j;
                //i * rooms + j;
                // 2016/06/28 end
                if (idx >= bookingInfo.roomAndGuestLst.size()) continue;
                //　到着日
                BI_JR_RoomAndGuestInfo roomAndGuest = bookingInfo.roomAndGuestLst[idx];
                // 2016/06/27 begin
                if (checkInFirstDayDt.date().addDays(i) != roomAndGuest.roomRate.RoomDate) {
                    notSameIdx++;
                    roomNoSameDateMap.put(j, notSameIdx);
                    continue;
                }
                // 2016/06/27 end
                // 部屋利用日（到着日)
                Date checkInDate = roomAndGuest.roomRate.RoomDate;
                // 新規予約データ作成
                Lead__c newLead = new Lead__c();
                // 2016/10/21 JR変更機能改善対応、項目値自動設定不具合改修 BEGIN
                for (String fieldName: finalFieldMap.keySet()) {
                    Schema.DescribeFieldResult describeField = finalFieldMap.get(fieldName);
                    if (describeField.isCreateable()) {
                        // デイフォル値を自動設定を行う
                        newLead.put(fieldName, CommUtils.ConvByFielType(autoSetupfieldMap.get(fieldName), describeField.getType()));
                        //mLogUtils.write_log('更新内容[' + fieldName + ']:1:' + fieldMap.get(fieldName) );
                        //mLogUtils.write_log('項目値自動設定[' + fieldName + ']:1:' + newLead.get(fieldName) );
                    }
                }
                // 2016/10/21 JR変更機能改善対応、項目値自動設定不具合改修 END
                // 2016/06/20 EDIT BEGIN
                // 変更前の予約泊数
                Integer orgLeadNights = null;
                Lead__c orgLead = null;
                if (isUpdateFlag) {
                    if (groupLeadMap.containsKey(j)) {
                        List < Lead__c > oLeadLst = groupLeadMap.get(j);
                        // 既存の予約の泊数情報を取得する
                        orgLeadNights = oLeadLst.size();
                        integer nightIdx = i - notSameIdx;
                        if (oLeadLst.size() - 1 >= nightIdx) {
                            orgLead = oLeadLst.get(nightIdx).clone(true, true);
                            newLead = oLeadLst.get(nightIdx);
                            userOrgLeadSet.add(j + '_' + nightIdx);
                            updateOrgLeadIdSet.add(orgLead.Id);
                        } else if (oLeadLst.size() > 0) {
                            newLead.LeadIndexSubId__c = oLeadLst[0].LeadIndexSubId__c;
                        }
                    }
                }
                System.debug(LoggingLevel.INFO, '--------既存の予約情報が存在する場合-----------------');
                // 既存の予約情報が存在する場合
                boolean isHadLeadId = (orgLead != null);
                //System.debug(LoggingLevel.INFO,'--------isHadLeadId-----------------' + isHadLeadId);
                // お客様情報
                newLead.Relcontact__c = newLead.Relcontact__c == null ? pkuser.id : newLead.Relcontact__c;
                // 2016/06/20 EDIT END
                // 2013/07/16 記号機能対応 BEGIN
                // 親部屋マーク標識用の文字は予約名の文字列先頭に付加
                // 2016/06/20 EDIT BEGIN
                // プラン情報         
                newLead.Field310__c = curPlan == null ? null : curPlan.Id;
                // 予約名情報を格納する
                if (isHadLeadId) {
                    // 予約名の個別処理
                    String orgLeadName = '';
                    String newLeadName = '';
                    // 既存の予約名はそのまま残り
                    //泊目
                    if (orgLeadNights != null && orgLeadNights > 1) orgLeadName = String.valueOf(orgLeadNights) + '-' + (i + 1) + Label.CONST_038_0007 + ' ' + orgLead.LeadIndexRef__r.LeadName__c;
                    else orgLeadName = orgLead.LeadIndexRef__r.LeadName__c;
                    //泊目
                    if (nights > 1) newLeadName += String.valueOf(nights) + '-' + (i + 1) + Label.CONST_038_0007 + ' ' + leadName; //bookingInfo.GuestOrGroupNameKanjiName;
                    else newLeadName += leadName; //bookingInfo.GuestOrGroupNameKanjiName;
                    // 既存の予約名をReplaceする
                    newLead.name = newLead.name.replace(orgLeadName, newLeadName);
                    if (rooms > 1 && j == 0 &&
                        !CommUtils.isBlank(strRoomDelegatePrefix) &&
                        !newLead.name.startsWith(strRoomDelegatePrefix)) {
                        newLead.name = strRoomDelegatePrefix + newLead.name;
                    }
                } else {
                    newLead.name = (rooms > 1 && j == 0 ? strRoomDelegatePrefix : '');
                    // 予約データ名設定を行う
                    //泊目
                    if (nights > 1) newLead.name += String.valueOf(nights) + '-' + (i + 1) + Label.CONST_047_0002 + ' ' + leadName; //bookingInfo.GuestOrGroupNameKanjiName;
                    else newLead.name += leadName; //bookingInfo.GuestOrGroupNameKanjiName;
                }
                // 2016/06/20 EDIT END
                // レコードタイプ：宿泊タイプ
                newLead.RecordTypeId = bookingRcTypeId;
                // お客様情報
                newLead.Relcontact__c = pkuser.Id;
                // 予約受付日
                // 2013/06/19 予約受付日の受付時間設定ミス、不具合修正、時間項目を設定する
                newLead.ReservedDate__c = DateTime.newInstance(bookingInfo.TravelAgencyBookingDate, bookingInfo.TravelAgencyBookingTime);
                // 支払方法 ----------------BEGIN----------------------
                // 2014/04/25 支払方法設定共通化
                /*
                String mediaType = bookingInfo.Payment;
                String ttendType = null;
                if (mediaType == 'Cach') ttendType = CommConst.MEDIA_TYPE_CD_01;
                else if (mediaType == 'CreditCard') ttendType = CommConst.MEDIA_TYPE_CD_02;
                //else if (mediaType == '売掛') ttendType = CommConst.MEDIA_TYPE_CD_03;
                else if (mediaType == 'Coupon') ttendType = CommConst.MEDIA_TYPE_CD_11;
                // 支払方法設定
                String mediaTypeName = CommConst.getPaymentTypeLabelByKey(ttendType);
                newLead.Field315__c = (mediaTypeName == null ? mediaType : mediaTypeName);*/
                newLead.Field315__c = getLocalPaymentInfo(bookingInfo.Payment);
                // 支払方法 -----------------END-----------------------
                // 予約ステータス[Deafult:確認中]
                //newLead.ReservedStatus__c =
                // First Dayの場合
                if (i == 0) {
                    // チェックイン日
                    newLead.EntryTime__c = checkInFirstDayDt;
                    // チェックイン時間
                    newLead.Field4__c = (bookingInfo.CheckInTime == null
                        // DayUserの場合の時刻情報
                        ?  (bookingInfo.Nights == 0 ? defaultDayUseCheckInTime : defaultCheckInTimeStr)
                        :  (DateTime.newInstance(Date.today(), bookingInfo.CheckInTime)).format('HH:mm') );
                    // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
                    // チェックアウト日
                    if (bookingInfo.Nights == 0) newLead.EntryTime__c = DateTime.newInstance(checkInFirstDayDt.date(), CommUtils.stringToTime(newLead.Field4__c));
                    // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
                } else {
                    // チェックイン日
                    newLead.EntryTime__c = DateTime.newInstance(checkInDate, defaultCheckinTime);
                    // チェックイン時間
                    newLead.Field4__c = defaultCheckInTimeStr;
                }
                // 2016/06/20 EDIT BEGIN
                //2016/03/02 ---------BEGIN----------------
                //予約取込のXMLのタグ：入込方法（Transportaion）存在すると、該当項目内容はご予約の「交通手段」項目へ設定する
                if (CommUtils.isBlank(newLead.Field348__c)) newLead.Field348__c = CommUtils.nullToBlank(bookingInfo.Transportaion);
                //2016/03/02 ----------END-----------------
                // 2016/06/20 EDIT END

                // 最後日の場合
                if (i == nights - 1) {
                    // チェックアウト日
                    newLead.Departure__c = checkOutLastDayDt;
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
                    // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
                    // チェックアウト日
                    if (bookingInfo.Nights == 0) newLead.Departure__c = DateTime.newInstance(checkOutLastDayDt.date(), CommUtils.stringToTime(newLead.Field3__c));
                    // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
                } else {
                    // チェックアウト日
                    newLead.Departure__c = DateTime.newInstance(checkInDate.addDays(1), defaultCheckoutTime);
                    // チェックアウト時間
                    newLead.Field3__c = defaultCheckoutTimeStr;
                }
                // 2016/07/01 BEGIN
                // 部屋タイプID
                newLead.refTypeOfRooms__c = roomTypeMap.get(roomAndGuest.room.RoomTypeCode);
                // 2013/02/26 部屋タイプ名：部屋ID情報を格納する
                if (newLead.refTypeOfRooms__c == null) newLead.refTypeOfRooms__c = roomTypeNmMap.get(roomAndGuest.room.RoomTypeName);
                // 2015/07/22  部屋タイプが存在　かつ　対応部屋タイプに対して、１部屋のみの場合、該当部屋は自動的に予約にアサインする BEGIN
                // 2016/10/26 部屋タイプと部屋が1対1の場合は故障部屋を割当される不具合改修 BEGIN
                /*
                if(newLead.refTypeOfRooms__c != null && oneTypeToRoomMap.containsKey(newLead.refTypeOfRooms__c)){
                    newLead.Rroom__c = oneTypeToRoomMap.get(newLead.refTypeOfRooms__c);
                }*/
                // 2016/10/26 部屋タイプと部屋が1対1の場合は故障部屋を割当される不具合改修 END
                // 2015/07/22  部屋タイプが存在　かつ　対応部屋タイプに対して、１部屋のみの場合、該当部屋は自動的に予約にアサインする END

                // 2016/07/01 END
                // 2013/06/09 宿泊人数は未設定する場合、自動Default値を設定する
                Integer calRoomPaxCount = CommUtils.nullToZero(roomAndGuest.room.RoomPaxMaleCount) +
                    CommUtils.nullToZero(roomAndGuest.room.RoomPaxFemaleCount) +
                    CommUtils.nullToZero(roomAndGuest.room.RoomChildA70Count) +
                    CommUtils.nullToZero(roomAndGuest.room.RoomChildB50Count) +
                    CommUtils.nullToZero(roomAndGuest.room.RoomChildC30Count) +
                    CommUtils.nullToZero(roomAndGuest.room.RoomChildDNoneCount)+
                    // 2018/11/20 小人数取り込み不正の対応 BEGIN
                    CommUtils.nullToZero(roomAndGuest.room.RoomChildOtherCount);
                    // 2018/11/20 小人数取り込み不正の対応 END
                String warningMsg = '';
                if (roomAndGuest.room.PerRoomPaxCount == null || roomAndGuest.room.PerRoomPaxCount == 0) {
                    // XMLの中に、未設定する場合、自動的にSFの初期値で自動設定を行う「非設定する場合、自動設定を行う」
                    if (calRoomPaxCount > 0) {
                        // 1室利用人数
                        newLead.StayPersons__c = calRoomPaxCount;
                    } else {
                        // 該当ケースする場合、注意事項に自動内容追加を行う
                        // サイトコントローラからの予約データのなかに、予約人数がありませんでしたので、デフォルト値(仮の値)を設定させていただきました、つきましては、ご予約者の方へご確認していただきまして、本予約データの予約人数を手動にて変更ください。
                        // 2016/10/26 BEGIN
                        //予約人数がゼロで取り込まれましたので人数を変更してください。
                        warningMsg = '<font color="red">' + Label.CONST_047_0003 + '</font><br/>';
                        newLead.StayPersons__c = 0;
                        // 2016/10/26 END
                    }
                } else {
                    // 1室利用人数
                    newLead.StayPersons__c = roomAndGuest.room.PerRoomPaxCount;
                }
                // 大人人員(男性)
                newLead.Mans__c = CommUtils.nullToZero(roomAndGuest.room.RoomPaxMaleCount);
                // 大人人員(女性)
                newLead.Femails__c = CommUtils.nullToZero(roomAndGuest.room.RoomPaxFemaleCount);
                // 子供A人数
                newLead.ChildFA__c = CommUtils.nullToZero(roomAndGuest.room.RoomChildA70Count);
                // 子供B人数
                newLead.Childs__c = CommUtils.nullToZero(roomAndGuest.room.RoomChildB50Count);
                // 子供C人数
                newLead.ChildC__c = CommUtils.nullToZero(roomAndGuest.room.RoomChildC30Count);
                // 子供D人数
                newLead.ChildD__c = CommUtils.nullToZero(roomAndGuest.room.RoomChildDNoneCount);
                // 2018/11/20 小人数取り込み不正の対応 BEGIN
                newLead.ChildE__c = CommUtils.nullToZero(roomAndGuest.room.RoomChildECount);
				newLead.ChildF__c = CommUtils.nullToZero(roomAndGuest.room.RoomChildFCount);
				newLead.ChildOther__c = CommUtils.nullToZero(roomAndGuest.room.RoomChildOtherCount);
				// 2018/11/20 小人数取り込み不正の対応 END
                //　予約インデックスID
                newLead.LeadIndexRef__c = leadIndex.Id;
                // 2016/06/20 EDIT BEGIN
                // 2015/12/11 予約取込機能改善（変更、キャンセル） BEGIN
                // 予約番号
                newLead.BookingDataID__c = bookingDataId;
                // プラン自動展開対象外フラグ設定
                newLead.PlanSycnFlag__c = newLead.PlanSycnFlag__c == null ? true : !newLead.PlanSycnFlag__c;
                System.debug(LoggingLevel.INFO, '--------newLead.PlanSycnFlag__c-----------------' + newLead.PlanSycnFlag__c);
                // 2015/12/11 予約取込機能改善（変更、キャンセル） END
                // 2016/06/20 EDIT END

                // プラン情報
                newLead.Field310__c = curPlan == null ? null : curPlan.Id;
                // 特記事項設定[一泊で2部屋以上の自動とりこみ予約のときは、特記事項を一つのみとする]
                //if (j == 0) {
                // 2016/06/20 EDIT BEGIN
                //newLead.Comment3__c = warningMsg + bookingInfo.OtherServiceInformation;
                // 料理補足
                //newLead.Field354__c = bookingInfo.MealCondition;
                System.debug(LoggingLevel.INFO, '--------isHadLeadId-----------------' + isHadLeadId);
                if (isHadLeadId) {
                    String commentMessage = newLead.Comment3__c + '<br/>' + warningMsg + bookingInfo.OtherServiceInformation;
                    newLead.Comment3__c = CommLogUtils.removeOverLogString(commentMessage, commentLength);
                    // メール本文
                    newLead.email__c = CommLogUtils.removeOverLogString(bookingInfo.specialServiceRequest + '\n\n\n' + CommUtils.nullToBlank(newLead.email__c), emailLength);
                    // ネットからの取込時に予約チャネルに旅行会社名で設定する
                    // 2016/07/10 予約チャネル名の変換機能追加対応 BEGIN
                    //if(CommUtils.isBlank(newLead.Field2__c)) newLead.Field2__c = TraveCompany != null ? TraveCompany.Name : null;
                    if (CommUtils.isBlank(newLead.Field2__c)) newLead.Field2__c = chanelStr;
                    // 2016/07/10 予約チャネル名の変換機能追加対応 END
                } else {
                    // 2017/09/01 最大文字数をこえない問題回避対応 BEGIN
                    //newLead.Comment3__c = warningMsg + bookingInfo.OtherServiceInformation;
                    newLead.Comment3__c = CommLogUtils.removeOverLogString(warningMsg + bookingInfo.OtherServiceInformation, commentLength);
                    //newLead.email__c = bookingInfo.specialServiceRequest;
                    newLead.email__c = CommLogUtils.removeOverLogString(bookingInfo.specialServiceRequest, emailLength);
                    // 2017/09/01 最大文字数をこえない問題回避対応 END
                    // ネットからの取込時に予約チャネルに旅行会社名で設定する BEGIN
                    // 2016/07/10 予約チャネル名の変換機能追加対応 BEGIN
                    //newLead.Field2__c = TraveCompany != null ? TraveCompany.Name : null;
                    newLead.Field2__c = chanelStr;
                    // 2016/07/10 予約チャネル名の変換機能追加対応 END
                    // 料理補足
                    newLead.Field354__c = bookingInfo.MealCondition;
                }
                // 部屋タイプID
                //newLead.refTypeOfRooms__c = roomTypeMap.get(roomAndGuest.room.RoomTypeCode);
                // 2013/02/26 部屋タイプ名：部屋ID情報を格納する
                //if (newLead.refTypeOfRooms__c == null ) newLead.refTypeOfRooms__c = roomTypeNmMap.get(roomAndGuest.room.RoomTypeName);
                // 2018/12/30 JR予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh BEGIN
                boolean chgRoomTypeFlag = BI_JR_ServiceConfigHelp.getAppConfig(shopCd).chgRoomTypeFlag;
                // 2018/12/30 JR予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh END
                // 部屋タイプを自動されている場合
                if (newLead.refTypeOfRooms__c != null) {
                    if (isHadLeadId) {
                        // 2016/10/18 既存の予約情報の部屋は割当済すると、該当部屋タイプと情報は変更なしで対応する BEGIN
                        /*
                        // 到着日変更　OR　部屋タイプ変更なしの場合、既にアサイン済部屋はそのまま残り
                        if (orgLead.EntryTime__c.date() == newLead.EntryTime__c.date() &&
                            orgLead.refTypeOfRooms__c == newLead.refTypeOfRooms__c) {
                            newLead.Rroom__c = orgLead.Rroom__c;
                        }*/
                        // 2016/10/18 既存の予約情報の部屋は割当済すると、該当部屋タイプと情報は変更なしで対応する END
                        // 2016/10/21 JR変更機能改善対応[到着日を変更すると、既に割当される部屋をクリアする] BEGIN
                        if (orgLead.EntryTime__c.date() != newLead.EntryTime__c.date()) {
                            // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh BEGIN
                            //newLead.Rroom__c = null;
                            boolean chgdtRoomClearFlag = BI_JR_ServiceConfigHelp.getAppConfig(shopCd).chgdtRoomClearFlag;
                            // 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ BEGIN
                            //if (chgdtRoomClearFlag) newLead.Rroom__c = null;
							if(chgdtRoomClearFlag) {
								newLead.Rroom__c = null;
								newLead.Field276__c = false;
							}
                            // 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ END
                            // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh END
                        }
                        // 2016/10/21 JR変更機能改善対応[到着日を変更すると、既に割当される部屋をクリアする] END
                        // 2018/12/30 JR予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh BEGIN
                        if(newLead.Rroom__c != null){
                        	// 部屋タイプを更新可能FLGはTRUE場合 AND 部屋変更不可フラグはFALSEの場合
                            // 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ BEGIN
                            //if(chgRoomTypeFlag && !orgLead.Field276__c){
                            // 部屋タイプ変更可のフラグがTRUEの場合
                        	if(chgRoomTypeFlag){
                        	// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ END
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
                                // 2018/12/30 部屋/部屋タイプ不正の場合、部屋と部屋タイプを再設定の改善対応 WSQ BEGIN
                                // 既存予約の部屋と部屋タイプ定義不一致の場合、ご予約の部屋タイプは部屋により訂正する
                                if (errRoomToTypeIdMap.containsKey(newLead.Rroom__c)) newLead.refTypeOfRooms__c = errRoomToTypeIdMap.get(newLead.Rroom__c);
                                // 2018/12/30 部屋/部屋タイプ不正の場合、部屋と部屋タイプを再設定の改善対応 WSQ END
                            }
                        }
                        // 2018/12/30 JR予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh END
                    }
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
                        else if (oneTypeToRoomMap.containsKey(newLead.refTypeOfRooms__c) && oneRoomCanAssignRoomMap.containsKey(idx)) {
                            newLead.Rroom__c = oneTypeToRoomMap.get(newLead.refTypeOfRooms__c);
                            mLogUtils.write_log('1VS1部屋自動割り当て部屋 :: ' + newLead.Rroom__c);
                        }
                        // 部屋タイプが存在　かつ　対応部屋タイプに対して、１部屋のみの場合、該当部屋は自動的に予約にアサインする END
                    }
                }
                // 2016/10/21 JR変更機能改善対応[到着日を変更すると、既に割当される部屋をクリアする] BEGIN
                else {
                    if (isHadLeadId) {
                        if (orgLead.EntryTime__c.date() != newLead.EntryTime__c.date()) {
                            // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh BEGIN
                            //newLead.Rroom__c = null;
                            boolean chgdtRoomClearFlag = BI_JR_ServiceConfigHelp.getAppConfig(shopCd).chgdtRoomClearFlag;
                            // 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ BEGIN
                            //if (chgdtRoomClearFlag) newLead.Rroom__c = null;
							if(chgdtRoomClearFlag) {
								newLead.Rroom__c = null;
								newLead.Field276__c = false;
							}
                            // 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ END
                            // 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh END
                        }
                    }
                }
                // 2016/10/21 JR変更機能改善対応[到着日を変更すると、既に割当される部屋をクリアする] END
                System.debug(LoggingLevel.INFO, '--------旧予約情報を更新する場合、見積明細は変更対象外-----------------');
                // 旧予約情報を更新する場合、見積明細は変更対象外
                // 新規予約のみ、見積明細を作成する
                if (!isHadLeadId) {
                    //見積もり明細取得
                    roomMaps.put(idx, setEachRoomBookingEstimeteItems(cloneItem, roomAndGuest, taxSericeFee, isRoomRateFlg, curPlan));
                } else {
                	// 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ BEGIN
                	if (isClearEstItemsFlag) roomMaps.put(idx,setEachRoomBookingEstimeteItems(cloneItem,roomAndGuest,taxSericeFee,isRoomRateFlg,curPlan));
                	else
                	// 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ END
                    roomMaps.put(idx, new List < BookingEstimateItem__c > ());
                }
                // 2016/06/20 EDIT END
                //}
                // 2013/07/16 記号機能対応 BEGIN
                // 予約データは親部屋に集めるの場合
                //else 
                if (j > 0 && CommConst.APPOTION_LEADSPLIT_DIV_CODE == CommConst.APPOTION_LEADSPLIT_DIV_CODE_UNION) {
                    // 2016/06/20 EDIT BEGIN
                    //Integer roomIdx = i * rooms;
                    Integer roomIdx = (i - notSameIdx) * rooms;
                    // 2016/10/24 予約人数がゼロの不具合改修 BEGIN
                    //insLeadLst[roomIdx].StayPersons__c += CommUtils.nullToZero(newLead.StayPersons__c);   
                    insLeadLst[roomIdx].StayPersons__c = CommUtils.nullToZero(insLeadLst[roomIdx].StayPersons__c) + CommUtils.nullToZero(newLead.StayPersons__c);
                    // 2016/10/24 予約人数がゼロの不具合改修 END
                    if (roomMaps.containsKey(idx)) {
                        roomMaps.get(roomIdx).addAll(roomMaps.get(idx));
                        roomMaps.remove(idx);
                    }
                    // 2016/06/20 EDIT END
                    // 代表部屋以外のデータ
                    newLead.StayPersons__c = 0;
                    // 大人人員(男性)
                    // 2016/06/20 EDIT BEGIN
                    insLeadLst[roomIdx].Mans__c += CommUtils.nullToZero(newLead.Mans__c);
                    // 2016/06/20 EDIT END
                    newLead.Mans__c = 0;
                    // 大人人員(女性)
                    // 2016/06/20 EDIT BEGIN
                    insLeadLst[roomIdx].Femails__c += CommUtils.nullToZero(newLead.Femails__c);
                    // 2016/06/20 EDIT END
                    newLead.Femails__c = 0;
                    // 子供A人数
                    // 2016/06/20 EDIT BEGIN
                    insLeadLst[roomIdx].ChildFA__c += CommUtils.nullToZero(newLead.ChildFA__c);
                    // 2016/06/20 EDIT END
                    newLead.ChildFA__c = 0;
                    // 子供B人数
                    // 2016/06/20 EDIT BEGIN
                    insLeadLst[roomIdx].Childs__c += CommUtils.nullToZero(newLead.Childs__c);
                    // 2016/06/20 EDIT END
                    newLead.Childs__c = 0;
                    // 子供C人数
                    // 2016/06/20 EDIT BEGIN
                    insLeadLst[roomIdx].ChildC__c += CommUtils.nullToZero(newLead.ChildC__c);
                    // 2016/06/20 EDIT END
                    newLead.ChildC__c = 0;
                    // 2016/06/20 EDIT BEGIN
                    // 子供D人数
                    insLeadLst[roomIdx].ChildD__c += CommUtils.nullToZero(newLead.ChildD__c);
                    newLead.ChildD__c = 0;
                    // 2016/06/20 EDIT END
                    // 2018/11/20 小人数取り込み不正の対応 BEGIN
                    // 子供E人数
                    insLeadLst[roomIdx].ChildE__c += CommUtils.nullToZero(newLead.ChildE__c); 
                    newLead.ChildE__c = 0;
					// 子供F人数
                    insLeadLst[roomIdx].ChildF__c += CommUtils.nullToZero(newLead.ChildF__c); 
                    newLead.ChildF__c = 0;
					// 子供その他人数
                    insLeadLst[roomIdx].ChildOther__c += CommUtils.nullToZero(newLead.ChildOther__c); 
                    newLead.ChildOther__c = 0;
					// 2018/11/20 小人数取り込み不正の対応 END
                    // プラン情報 <- NULL
                    newLead.Field310__c = null;
                    // コメント
                    newLead.Comment3__c = null;

                }
                // 2013/07/16 記号機能対応 END
                // 旅行会社関連参照情報設定
                newLead.SalesOfficeInfoRef__c = TraveCompany.isEmpty() ? null : (TraveCompany.size() > 1 ? TraveCompany[1].Id : TraveCompany[0].Id);
                // メール本文
                //newLead.email__c = bookingInfo.specialServiceRequest;
                // 2012/12/23  Add
                newLead.RoomGroupNo__c = j; //roomNoIdx;
                // 2013/06/25 ADD 旅行会社名から予約チャネルに設定する
                //newLead.Field2__c = TraveCompany.Name;
                // 2016/06/20 EDIT BEGIN
                // 2015/10/30 故障部屋は自動割当て機能に追加対応 BEGIN
                newLead.EventSource__c = bookingDataId + '_' + DateTime.now().getTime();
                // 2015/10/30 故障部屋は自動割当て機能に追加対応 END
                // 単価定義区分の設定する
                newLead.UnitPriceDefKb__c = String.valueOf(CommConst.APPOPTION_UTP_DEF_KB);
                //bookingInfo.TaxServiceFee;
                // 2016/06/20 EDIT END
                insLeadLst.add(newLead);
            }
        }
		// 2018/03/16 2way、ModificationReport→房型和料金都没有值程序报错fix BEGIN
		if(insLeadLst.isEmpty()) return;
		// 2018/03/16 2way、ModificationReport→房型和料金都没有值程序报错fix END
        // 見積り金額設定を行う「一件のみ設定する」
        insLeadLst[0].BridalDantaikei__c = bookingInfo.TotalAccommodationCharge;
        System.debug(LoggingLevel.INFO, '--------TotalAccommodationCharge-----------------' + insLeadLst[0].BridalDantaikei__c);
        List < Lead__c > updLeadLst = new List < Lead__c > ();
        for (integer key: groupLeadMap.keySet()) {
            List < Lead__c > childLst = groupLeadMap.get(key);
            if (childLst != null) {
                for (integer i = 0; i < childLst.size(); i++) {
                    String setKey = key + '_' + i;
                    if (!userOrgLeadSet.contains(setKey)) {
                        // 2016/10/10 在庫キャンセル処理対応(発生源) BEGIN by zh
                        childLst.get(i).EventSource__c = APPNAME + '_' + bookingInfo.DataID + '_' + DateTime.now().getTime();
                        // 2016/10/10 在庫キャンセル処理対応(発生源) END by zh
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
        // 2018/08/10 TL->JR変換の紐付ける処理の対応 BEGIN
        if (tl2wayToJr2way) {
        	DataFixManagerUtils.stopTranTriggger();
	        for (Lead__c lead : updLeadLst) {
	        	lead.EventSource__c = CommConst.BI_PROCESS_TYPE.JR.Name();
	        }
	        if (!updLeadLst.isEmpty()) update updLeadLst;
	        DataFixManagerUtils.begTranTriggger();
        }
        // 2018/08/10 TL->JR変換の紐付ける処理の対応 END
        
        if (!updLeadLst.isEmpty()) update updLeadLst;
        // SUBINDEX自動作成
        // 2017/05/04 店舗ごとの予約・会計権限機能対応 BEGIN
        //CommLogicProcess logic = new CommLogicProcess();
        // 2017/05/04 店舗ごとの予約・会計権限機能対応 END
        logic.autoCreateIndexSub(insLeadLst);

        //insert insLeadLst;
        upsert insLeadLst;
        List < BookingEstimateItem__c > lastInsItems = new List < BookingEstimateItem__c > ();
        List < Id > leadIds = new List < Id > ();
        for (integer i = 0; i < insLeadLst.size(); i++) {
            Lead__c insLead = insLeadLst[i];
            if (roomMaps.containsKey(i)) {
                // X泊Y部屋の見積明細情報の予約IDを自動設定を行う
                List < BookingEstimateItem__c > insLst = roomMaps.get(i);
                for (BookingEstimateItem__c bookingItem: insLst) {
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
        delete[select id, name from BookingEstimateItem__c where refBooking__c =: leadIds and ParentBookingItemRef__c = null];
        delete[select id, name from BookingEstimateItem__c where refBooking__c =: leadIds];
        // 変更の場合、支払情報は更新を行わない
        // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ BEGIN
        //if (updateOrgLeadIdSet.isEmpty()) {
        if (updateOrgLeadIdSet.isEmpty() || isClearEstItemsFlag) {
        // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ END
            //見積もり明細　オプション作成する
            // 2017/08/15 option数据根据单价定义区分计算 fix BEGIN
            //lastInsItems.addAll(upsertBookingEstimeteItemsByEach(bookingInfo,insLeadLst[0]));
            lastInsItems.addAll(upsertBookingEstimeteItemsByEach(bookingInfo, insLeadLst[0], taxSericeFee));
            // 2017/08/15 option数据根据单价定义区分计算 fix END
            //見積もり明細：支払い作成「ポイント・支払い」
            // 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応 by zh BEGIN
	        //lastInsItems.addAll(upsertPaymentBookingExtimeItem(insLeadLst[0], bookingInfo));
	        // 異常ケースを回避対応      
	        if (payMediaLinkPos  >= insLeadLst.size()) payMediaLinkPos = 0;
	        lastInsItems.addAll(upsertPaymentBookingExtimeItem(insLeadLst[payMediaLinkPos],bookingInfo)); 
	        // 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応 by zh END
        }
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
        List < Lead__c > restoreLeads = new List < Lead__c > ();
        restoreLeads.addAll(updLeadLst);
        restoreLeads.addAll(insLeadLst);
        // 2018/08/10 効率改善対応 BEGIN
        DataFixManagerUtils.stopTranTriggger();
        // 2018/08/10 効率改善対応 END
        logic.restoreShopAuthCheckSetup(restoreLeads, true);
        // 2018/08/10 効率改善対応 BEGIN
        DataFixManagerUtils.begTranTriggger();
        // 2018/08/10 効率改善対応 END
        // 2017/05/04 店舗ごとの予約・会計権限機能対応 END
        mLogUtils.write_method_end();
    }
    // 2016/06/20 EDIT BEGIN
    // プラン明細に室料するがどうか判断ロジック
    private static Boolean isRoomRateItem(AccountMaster__c acc) {
        return RackRateUtils.isRoomRateProduct(acc);
    }
    // 2016/07/10 予約チャネル名の変換機能追加対応 BEGIN
    private static string getChanelStr(BI_JR_SyncInfo bookingInfo, list < account > TraveCompany) {
        String agtCode = CommUtils.nullToBlank(bookingInfo.SalesOfficeCompanyCode);
        String chanelStr = BI_JR_ServiceConfigHelp.getMapAgtToChanelConfig(shopCd).get(agtCode);
        if (CommUtils.isBlank(chanelStr)) {
            boolean chanelFromCompany = BI_JR_ServiceConfigHelp.getAppConfig(shopCd).chanelFromCompany;
            if (chanelFromCompany) chanelStr = (!TraveCompany.isEmpty() ? TraveCompany[0].Name : null);
            // 営業所から設定
            else {
                if (TraveCompany.size() > 1) {
                    chanelStr = TraveCompany[1].Name;
                } else if (!TraveCompany.isEmpty()) {
                    chanelStr = TraveCompany[0].Name;
                }
            }
        }
        return chanelStr;
    }
    // 2016/07/10 予約チャネル名の変換機能追加対応 END
    // ポイント、売掛金、カードなど事前支払情報は見積明細に反映を行う
    private static List < BookingEstimateItem__c > upsertPaymentBookingExtimeItem(Lead__c lead, BI_JR_SyncInfo bookingInfo) {
        mLogUtils.write_method_start('upsertPaymentBookingExtimeItem');
        //BI_TL_Risaplsinformation risaplsinformation = bookingInfo.risaplsinformation;
        // 合計宿泊料金(総額)
        Decimal totalPrice = bookingInfo.TotalAccommodationCharge;
        //BI_TL_BasicRate basicRate = risaplsinformation.risaplsCommonInformation.basicRate;
        BI_JR_Member member = bookingInfo.member;
        BillSimpleHelp help = new BillSimpleHelp(shopCd);
        // ポイント合計金額格納
        Decimal pointAmount = 0;
        // 新規追加プランデータ存在する場合
        List < BookingEstimateItem__c > insLst = new List < BookingEstimateItem__c > ();
        // ポイント支払情報格納する
        List < BookingEstimateItem__c > pointLst = new List < BookingEstimateItem__c > ();

        // 2016/06/22  
        // 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う BEGIN
        String settlementDiv = CommUtils.nullToBlank(bookingInfo.Payment);
        String agtCode = CommUtils.nullToBlank(bookingInfo.SalesOfficeCompanyCode);
        list < string > equalKeyLst = getEqualsKeyLst(settlementDiv, agtCode);
        map < string, AccountMaster__c > payProductIdMap = new map < String, AccountMaster__c > ();
        map < String, BI_JR_ServiceConfigHelp.PAYMENT_CONVERT > paymentConfigMap = BI_JR_ServiceConfigHelp.getPaymentConfig(shopCd);
        map < String, BI_JR_ServiceConfigHelp.PAYMENT_CONVERT > pointConfigMap = BI_JR_ServiceConfigHelp.getPointConfig(shopCd);
        list < string > productCdlst = new list < string > ();
        for (BI_JR_ServiceConfigHelp.PAYMENT_CONVERT parserPay: paymentConfigMap.values()) {
            productCdlst.add(parserPay.payProdCode);
        }
        for (BI_JR_ServiceConfigHelp.PAYMENT_CONVERT parserPay: pointConfigMap.values()) {
            productCdlst.add(parserPay.payProdCode);
        }
        if (!productCdlst.isEmpty()) {
            payProductIdMap = BI_JR_ServiceConfigHelp.getPaymentProductId(productCdlst);
        }
        // 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う END  
        // ポイント支払情報が存在する場合
        // basicRateにポイント支払情報が未設定する場合   
        if (member != null && pointLst.isEmpty()) {
            Decimal UserUsePoints = CommUtils.nullToZero(member.UserUsePoints);
            mLogUtils.write_log('MEMBER POINT::' + member.UserUsePoints);
            if (UserUsePoints > 0) {
                System.debug(LoggingLevel.INFO, '使用ポイント:' + UserUsePoints);
                pointLst.add(new BookingEstimateItem__c(
                    refBooking__c = lead.id,
                    UnitPrice__c = UserUsePoints,
                    Amount__c = 1
                ));
                pointAmount += UserUsePoints;
            }
        }
        System.debug(LoggingLevel.INFO, 'pointAmount:' + pointAmount);
        if (pointAmount > 0) {
            AccountMaster__c covertAcc = null;
            for (String key: equalKeyLst) {
                mLogUtils.write_log('割引MATCH:' + KEY + '=' + pointConfigMap.containsKey(key));
                if (pointConfigMap.containsKey(key)) {
                    BI_JR_ServiceConfigHelp.PAYMENT_CONVERT convertInf = pointConfigMap.get(key);
                    covertAcc = payProductIdMap.get(convertInf.payProdCode);
                    break;
                }
            }
            // ポイント支払メデイア情報を取得する
            // 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う BEGIN
            AccountMaster__c pointAcc = covertAcc != null ? covertAcc : help.getMediaLabToAccMstMap().get(help.getPaymentTypeToMediaLabMap().get(CommConst.PROD_PAY_TYPE_DIS_PRICE));
            if (pointAcc != null) {
                for (BookingEstimateItem__c est: pointLst) {
                    est.refAccountMaster__c = pointAcc.Id;
                    est.refAccountMaster__r = pointAcc;
                }
            } else pointLst.clear();
            if (!pointLst.isEmpty()) insLst.addAll(pointLst);
        }
        // 事前決済区分により、支払情報の作成
        if (!CommUtils.isBlank(settlementDiv)) {
            Integer SettlementDivCd = null;
            set < string > cardPaymentConvertSet = BI_JR_ServiceConfigHelp.getCardPaymentConvertConfig(shopCd);
            if (cardPaymentConvertSet != null && cardPaymentConvertSet.contains(settlementDiv)) {
                SettlementDivCd = 2;
            }
            set < string > creditPaymentConvertSet = BI_JR_ServiceConfigHelp.getCreditPaymentConvertConfig(shopCd);
            if (creditPaymentConvertSet != null && creditPaymentConvertSet.contains(settlementDiv)) {
                SettlementDivCd = 4;
            }
            // 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う BEGIN
            AccountMaster__c commAcc = null;
            for (String key: equalKeyLst) {
                mLogUtils.write_log('事前決済MATCH:' + KEY + '=' + paymentConfigMap.containsKey(key));
                if (paymentConfigMap.containsKey(key)) {
                    BI_JR_ServiceConfigHelp.PAYMENT_CONVERT convertInf = paymentConfigMap.get(key);
                    commAcc = payProductIdMap.get(convertInf.payProdCode);
                    break;
                }
            }
            // 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う END
            // TL側の定義参照用:事前決済区分「0」:指定なし、「1」:法人利用、「2」:カード決済ズミ、「3」:現地払い、 「4」:ツアー会社、「5」:一部精算、「6」:エージェント精算
            // 「1」:法人利用 「4」:ツアー会社  →　売掛金
            if (SettlementDivCd == 1 || SettlementDivCd == 4) {
                if (commAcc == null)
                    commAcc = help.getMediaLabToAccMstMap().get(CommConst.MEDIA_TYPE_03);
            }
            // 「2」:カード決済ズミ →カード
            else if (SettlementDivCd == 2) {
                if (commAcc == null)
                    commAcc = help.getMediaLabToAccMstMap().get(help.getPaymentTypeToMediaLabMap().get(CommConst.PROD_PAY_TYPE_CARD));
            }

            mLogUtils.write_log('事前決済区分:[' + SettlementDivCd + ']' + commAcc);
            // 支払情報の作成
            if (commAcc != null) {
                // 割引金額は総金額から外す
                totalPrice -= pointAmount;
                // 支払情報作成する
                insLst.add(new BookingEstimateItem__c(
                    refAccountMaster__c = commAcc.id,
                    refBooking__c = lead.id,
                    Amount__c = 1,
                    UnitPrice__c = totalPrice
                ));
                //System.debug(LoggingLevel.INFO,'----------insLst----------' + insLst);
            }
        }
        // 割引、支払情報を新規作成する
        /*if(!insLst.isEmpty()) {
            Integer rowNo = (pRowNoGroupMap.containsKey(lead.Id) ? pRowNoGroupMap.get(lead.Id) : 0);
            for (BookingEstimateItem__c est : insLst) {
                rowNo++;
                est.RowNo__c = rowNo;
            }
            pRowNoGroupMap.put(lead.Id, rowNo);
            insert insLst;
        }*/
        mLogUtils.write_method_end();
        // 割引、支払情報を新規作成する
        return insLst;
    }
    private static list < String > getEqualsKeyLst(String settlementDiv, String agtCode) {
        List < String > equalKeyLst = new List < String > {
            CommUtils.nullToBlank(settlementDiv) + '_' + CommUtils.nullToBlank(agtCode),
            CommUtils.nullToBlank(settlementDiv) + '_',
            '_' + CommUtils.nullToBlank(agtCode),
            '_'
        };
        list < string > equalKeys = new list < string > ();
        set < string > filterSet = new set < String > ();
        for (Integer i = 0; i < equalKeyLst.size(); i++) {
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
    private static List < BookingEstimateItem__c > setEachRoomBookingEstimeteItems(BookingEstimateItem__c item,
        BI_JR_RoomAndGuestInfo roomAndGuest,
        Integer taxSericeFee,
        Boolean isRoomRateFlg,
        Plan__c pCurPlan) {
        mLogUtils.write_method_start('setEachRoomBookingEstimeteItems');
        mLogUtils.write_log('BookingEstimateItem__c:' + item);
        mLogUtils.write_log('roomAndGuest:' + roomAndGuest);
        mLogUtils.write_log('taxSericeFee:' + taxSericeFee);
        mLogUtils.write_log('isRoomRateFlg:' + isRoomRateFlg);
        mLogUtils.write_log('curPlan:' + pCurPlan);
        //List<BI_JR_RoomRateInfomation> roomRateLst = roomAndGuest.roomRate;
        BI_JR_RoomRateInfomation roomRate = roomAndGuest.roomRate;
        List < BookingEstimateItem__c > detailLst = new List < BookingEstimateItem__c > ();
        if (item == null) return detailLst;
        // 料金設定情報がありません
        //if (roomRateLst.isEmpty()) return detailLst;
        if (roomRate == null) return detailLst;
        // 人員単価金額で総計利用金額を計算を行う
        BI_JR_RoomInformation room = roomAndGuest.room;
        // 宿泊者タイプの総人数
        // 2019/11/08 null object修正 BEGIN by zh
        Integer roomPaxMalCount = CommUtils.nullToZero(room.RoomPaxMaleCount); // 男性人数
        integer roomPaxFemaleCount = CommUtils.nullToZero(room.RoomPaxFemaleCount); // 女性人数
        integer roomChildACount = CommUtils.nullToZero(room.RoomChildA70Count); // 子供A人数
        integer roomChildBCount = CommUtils.nullToZero(room.RoomChildB50Count); // 子供B人数
        integer roomCHildCCount = CommUtils.nullToZero(room.RoomChildC30Count); // 子供C人数
        integer roomChildDCount = CommUtils.nullToZero(room.RoomChildDNoneCount); // 子供D人数
        // 2019/11/08 null object修正 BEGIN by zh
        // 2018/11/20 小人数取り込み不正の対応 BEGIN
        Integer roomChildECount = CommUtils.nullToZero(room.RoomChildECount);
		Integer roomChildFCount = CommUtils.nullToZero(room.RoomChildFCount);
        Integer roomChildOtherCount = CommUtils.nullToZero(room.RoomChildOtherCount);	// 子供その他人数
        // 2018/11/20 小人数取り込み不正の対応 END
        Map < String, BookingEstimateItem__c > itemMap = new Map < String, BookingEstimateItem__c > ();
        // 大人料金
        Decimal perPaxRate = CommUtils.nullToZero(roomRate.PerPaxRate) > 0 ? CommUtils.nullToZero(roomRate.PerPaxRate) : (CommUtils.nullToZero(roomRate.PerPaxMaleRate) > 0 ? CommUtils.nullToZero(roomRate.PerPaxMaleRate) : CommUtils.nullToZero(roomRate.PerPaxFemaleRate));
        if (is2way && isRoomRateFlg) isRoomRateFlg = !(perPaxRate > 0);
        mLogUtils.write_log('料金区分:' + (isRoomRateFlg ? '部屋単価' : '人員単価'));
        mLogUtils.write_log('------------大人料金-----------' + perPaxRate);
        // 室単価の場合、総利用料金はプラン/室料に設定を行う
        if (!isRoomRateFlg || perPaxRate > 0) {
				// 2016/06/10 子供料金プラン取り込み機能対応 END
				//2019/11/30 子供料金（RoomDateGuestList)取り込みできるように改善対応 BEGIN by zh
				Boolean chgGuestRateFlag = BI_JR_ServiceConfigHelp.getAppConfig(shopCd).guestRateFlag;
                //RoomInformation的大人人数
                Integer paxCount = roomPaxMalCount + roomPaxFemaleCount;
                //RoomInformation的小孩人数
                Integer childCount = roomChildACount + roomChildBCount + roomCHildCCount + roomChildDCount + roomChildECount + RoomChildFCount + roomChildOtherCount;
                //RoomDateGuestList的大人人数
                Integer detialPaxCount = 0 ;
                //RoomDateGuestList的小孩人数
                Integer detialChildCount = 0 ;
				//没有大人人数、小孩人数、没有RoomDateGuestList
                if(roomRate.roomDateGuestList == null) roomRate.roomDateGuestList = new List<BI_JR_RoomDateGuest>();
				Decimal dePaxRate = 0;
            	for (BI_JR_RoomDateGuest dinfo: roomRate.roomDateGuestList) {
					//统计RoomDateGuestList的大人人数
					if(dinfo.GuestTypeCode == '大人'){
						detialPaxCount += CommUtils.nullToZero(dinfo.Count);
						dePaxRate = dePaxRate > CommUtils.nullToZero(dinfo.Rate) ? dePaxRate : CommUtils.nullToZero(dinfo.Rate);
					//统计RoomDateGuestList的小孩人数
					}else{
						detialChildCount += CommUtils.nullToZero(dinfo.Count);
					}
				}
				//判断RoomDateGuestList的大人人数==RoomInformation的大人人数
				if(detialPaxCount == paxCount && chgGuestRateFlag){
					for (BI_JR_RoomDateGuest dinfo: roomRate.roomDateGuestList) {
						//生成RoomRateDetailInformation大人的明细
						if(dinfo.GuestTypeCode == '大人'){
		                    BookingEstimateItem__c newItem = item.clone(false, true);
		                    newItem.UnitPrice__c = CommUtils.nullToZero(dinfo.Rate);
		                    String key = 'PaxMalCount_' + newItem.UnitPrice__c;
		                    integer perAddAmount = CommUtils.nullToZero(dinfo.Count);
		                    if (itemMap.containsKey(key))
		                        itemMap.get(key).Amount__c += perAddAmount;
		                    else {
		                        newItem.Amount__c = perAddAmount;
		                        itemMap.put(key, newItem);
		                    }
						}
					}
				}
				else{
				//2019/11/30 子供料金（RoomDateGuestList)取り込みできるように改善対応 END by zh
                if(roomPaxMalCount > 0 && (roomRate.PerPaxRate != null || roomRate.PerPaxMaleRate != null)){
                    integer perAddAmount = 1;
                    BookingEstimateItem__c newItem = item.clone(false,true);
                    // 2016/06/27 BEGIN
                    // 2018/04/11 PerPaxRate不为0时用PerPaxRate的值 BEGIN by zh
                    //newItem.UnitPrice__c = roomRate.PerPaxRate != null? roomRate.PerPaxRate : CommUtils.nullToZero(roomRate.PerPaxMaleRate);
                    newItem.UnitPrice__c = roomRate.PerPaxRate != null && roomRate.PerPaxRate != 0 ? roomRate.PerPaxRate : CommUtils.nullToZero(roomRate.PerPaxMaleRate);
                    // 2018/04/11 PerPaxRate不为0时用PerPaxRate的值 END by zh
                    // 2016/06/27 END
                    String key = 'PaxMalCount_' + newItem.UnitPrice__c;
                    //if(lastRateFlag) perAddAmount = roomPaxMalCount;
                    perAddAmount = roomPaxMalCount;
                    if(itemMap.containsKey(key))
                        itemMap.get(key).Amount__c += perAddAmount;
                    else {
                        newItem.Amount__c = perAddAmount;
                        itemMap.put(key,newItem);
                    }
                    roomPaxMalCount--;
                }
                if(roomPaxFemaleCount > 0 && (roomRate.PerPaxRate != null || roomRate.PerPaxFemaleRate != null)){
                    integer perAddAmount = 1;
                    BookingEstimateItem__c newItem = item.clone(false,true);
                    // 2016/06/27 BEGIN
                    // 2018/04/11 PerPaxRate不为0时用PerPaxRate的值 BEGIN by zh
                    //newItem.UnitPrice__c = roomRate.PerPaxRate != null? roomRate.PerPaxRate : CommUtils.nullToZero(roomRate.PerPaxFemaleRate);
                    newItem.UnitPrice__c = roomRate.PerPaxRate != null && roomRate.PerPaxRate != 0 ? roomRate.PerPaxRate : CommUtils.nullToZero(roomRate.PerPaxFemaleRate);
                    // 2018/04/11 PerPaxRate不为0时用PerPaxRate的值 END by zh
                    // 2016/06/27 END
                    String key = 'PaxFemaleCount_' + newItem.UnitPrice__c;
                    //if(lastRateFlag) perAddAmount = roomPaxFemaleCount;
                    perAddAmount = roomPaxFemaleCount;
                    if(itemMap.containsKey(key))
                        itemMap.get(key).Amount__c += perAddAmount;
                    else {
                        newItem.Amount__c = perAddAmount;
                        itemMap.put(key,newItem);
                    }
                    roomPaxFemaleCount--;
                }
                //2019/11/30 子供料金（RoomDateGuestList)取り込みできるように改善対応 BEGIN by zh
				}
                //判断RoomDateGuestList的小孩人数==RoomInformation的小孩人数
				if(detialChildCount == childCount && chgGuestRateFlag){
					for (BI_JR_RoomDateGuest dinfo: roomRate.roomDateGuestList) {
						//生成RoomRateDetailInformation小孩的明细
						if(dinfo.GuestTypeCode == '子供その他'){
							//integer perAddAmount = 1;
		                    BookingEstimateItem__c newItem = item.clone(false, true);
		                    newItem.UnitPrice__c = CommUtils.nullToZero(dinfo.Rate);
		                    // 2016/06/10 子供料金プラン取り込み機能対応 BEGIN
		                    // 2018/11/20 小人数取り込み不正の対応 BEGIN
		                    //matchChildrenPlan(newItem,perPaxRate);
		                    matchChildrenPlan(newItem,dePaxRate);
		                    // 2018/11/20 小人数取り込み不正の対応 END
		                    // 2016/06/10 子供料金プラン取り込み機能対応 END
		                    String key = 'PaxMalCount_' + newItem.UnitPrice__c;
		                    integer perAddAmount = CommUtils.nullToZero(dinfo.Count);
		                    if (itemMap.containsKey(key))
		                        itemMap.get(key).Amount__c += perAddAmount;
		                    else {
		                        newItem.Amount__c = perAddAmount;
		                        itemMap.put(key, newItem);
		                    }
						}
					}
				}else{
				//2019/11/30 子供料金（RoomDateGuestList)取り込みできるように改善対応 END by zh
                if(roomChildACount > 0 && roomRate.PerChildA70Rate != null){
                    integer perAddAmount = 1;
                    BookingEstimateItem__c newItem = item.clone(false,true);
                    newItem.UnitPrice__c = roomRate.PerChildA70Rate;
                    // 2016/06/10 子供料金プラン取り込み機能対応 BEGIN
                    matchChildrenPlan(newItem,perPaxRate);
                    // 2016/06/10 子供料金プラン取り込み機能対応 END
                    String key = 'ChildACount_' + newItem.UnitPrice__c;
                    //if(lastRateFlag) perAddAmount = roomChildACount;
                    perAddAmount = roomChildACount;
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
System.debug(LoggingLevel.INFO,'key::::::::::::::::::'+ key);
                    //if(lastRateFlag) perAddAmount = roomChildBCount;
                    perAddAmount = roomChildBCount;
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
                    //if(lastRateFlag) perAddAmount = roomCHildCCount;
                    perAddAmount = roomCHildCCount;
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
                    //if(lastRateFlag) perAddAmount = roomChildDCount;
                    perAddAmount = roomChildDCount;
                    if(itemMap.containsKey(key))
                        itemMap.get(key).Amount__c += perAddAmount;
                    else {
                        newItem.Amount__c = perAddAmount;
                        itemMap.put(key,newItem);
                    }
                    roomChildDCount--;
                }
                // 2018/11/20 小人数取り込み不正の対応 BEGIN
                // 子供E
				if(roomChildECount > 0 && roomRate.PerChildERate != null){
                    integer perAddAmount = 1;
                    BookingEstimateItem__c newItem = item.clone(false,true);
                    newItem.UnitPrice__c = roomRate.PerChildERate;
                    // 2016/06/10 子供料金プラン取り込み機能対応 BEGIN
                    matchChildrenPlan(newItem,perPaxRate);
                    // 2016/06/10 子供料金プラン取り込み機能対応 END
                    String key = 'ChildECount_' + newItem.UnitPrice__c;
                    //if(lastRateFlag) perAddAmount = roomChildECount;
                    perAddAmount = roomChildECount;
                    if(itemMap.containsKey(key))
                        itemMap.get(key).Amount__c += perAddAmount;
                    else {
                        newItem.Amount__c = perAddAmount;
                        itemMap.put(key,newItem);
                    }
                    roomChildECount--;
                }
				// 子供F
				if(RoomChildFCount > 0 && roomRate.PerChildFRate != null){
                    integer perAddAmount = 1;
                    BookingEstimateItem__c newItem = item.clone(false,true);
                    newItem.UnitPrice__c = roomRate.PerChildFRate;
                    // 2016/06/10 子供料金プラン取り込み機能対応 BEGIN
                    matchChildrenPlan(newItem,perPaxRate);
                    // 2016/06/10 子供料金プラン取り込み機能対応 END
                    String key = 'ChildFCount_' + newItem.UnitPrice__c;
                    //if(lastRateFlag) perAddAmount = RoomChildFCount;
                    perAddAmount = roomChildFCount;
                    if(itemMap.containsKey(key))
                        itemMap.get(key).Amount__c += perAddAmount;
                    else {
                        newItem.Amount__c = perAddAmount;
                        itemMap.put(key,newItem);
                    }
                    RoomChildFCount--;
                }
				// 子供その他
                if(roomChildOtherCount > 0 && roomRate.PerChildOtherRate != null){
                    integer perAddAmount = 1;
                    BookingEstimateItem__c newItem = item.clone(false,true);
                    newItem.UnitPrice__c = roomRate.PerChildOtherRate;
                    // 2016/06/10 子供料金プラン取り込み機能対応 BEGIN
                    matchChildrenPlan(newItem,perPaxRate);
                    // 2016/06/10 子供料金プラン取り込み機能対応 END
                    String key = 'ChildOtherCount_' + newItem.UnitPrice__c;
                    //if(lastRateFlag) perAddAmount = roomChildOtherCount;
                    perAddAmount = roomChildOtherCount;
                    if(itemMap.containsKey(key))
                        itemMap.get(key).Amount__c += perAddAmount;
                    else {
                        newItem.Amount__c = perAddAmount;
                        itemMap.put(key,newItem);
                    }
                    roomChildOtherCount--;
                }
                // 2018/11/20 小人数取り込み不正の対応 END
                //2019/11/30 子供料金（RoomDateGuestList)取り込みできるように改善対応 BEGIN by zh
            }
            //2019/11/30 子供料金（RoomDateGuestList)取り込みできるように改善対応 END by zh
            //}
            // 利用金額同じする場合、合流判定用マイプ
            Map < Decimal, BookingEstimateItem__c > itemPriceMap = new Map < Decimal, BookingEstimateItem__c > ();
            System.debug(LoggingLevel.INFO, 'itemMap:::' + itemMap);
            for (String key: itemMap.keySet()) {
                BookingEstimateItem__c bookingItem = itemMap.get(key);
                Decimal orgUnitPrice = bookingItem.UnitPrice__c;
                if (!itemPriceMap.containsKey(orgUnitPrice)) {
                    itemPriceMap.put(orgUnitPrice, bookingItem);
                    detailLst.add(bookingItem);
                } else {
                    BookingEstimateItem__c preBookingItem = itemPriceMap.get(orgUnitPrice);
                    preBookingItem.Amount__c += bookingItem.Amount__c;
                }
            }
        }
        // 2015/12/14 RoomRateの場合、プラン室料自動設定機能を追加する BEGIN
        else if (isRoomRateFlg && CommUtils.nullToZero(roomRate.TotalPerRoomRate) > 0) {
            BookingEstimateItem__c newItem = item.clone(false, true);
            newItem.UnitPrice__c = CommUtils.nullToZero(roomRate.TotalPerRoomRate) > 0 ? CommUtils.nullToZero(roomRate.TotalPerRoomRate) : CommUtils.nullToZero(roomRate.PerPaxRate);
            System.debug(LoggingLevel.INFO, 'newItem.UnitPrice__c：::::::::::::::::::' + newItem.UnitPrice__c);
            newItem.Amount__c = 1;
            detailLst.add(newItem);
        }
        // 2015/12/14 RoomRateの場合、プラン室料自動設定機能を追加する END
        System.debug(LoggingLevel.INFO, 'detailLst：' + detailLst);
        // 単価定義区分変換処理を行う
        for (BookingEstimateItem__c bookingItem: detailLst) {

            mLogUtils.write_log('利用金額「変更前」(区分' + taxSericeFee + ')：' + bookingItem.UnitPrice__c);
            // Local変換前の利用金額を格納する
            Decimal orgEstUnitPrice = bookingItem.UnitPrice__c;
            // 2019/09/15 軽減税率機能対応 WGCH BEGIN
            orgEstUnitPriceEnd = orgEstUnitPrice;
            // 2019/09/15 軽減税率機能対応 WGCH END
            // 2016/09/08 プラン明細に非課税明細含め場合、計算結果不正の不具合修正 BEGIN
            // プランとプラン明細の取得場所を移動する
            // 該当対応の会計商品コードを取得する、該当商品コード
            PlanDetailInfo locPlanDetailInf = gPlanDetailInf;
            Plan__c locCurPlan = pCurPlan;
            String locProductCode = bookingItem.Field3__c;
            System.debug(LoggingLevel.INFO, 'locProductCode:::::::::::::::' + locProductCode);
            System.debug(LoggingLevel.INFO, 'childPlanPlanMstMap:::::::::::::::' + childPlanPlanMstMap);
            System.debug(LoggingLevel.INFO, 'childPlanPlanMstMap.containsKey(locProductCode):::::::::::::::' + childPlanPlanMstMap.containsKey(locProductCode));
            if (childPlanPlanMstMap.containsKey(locProductCode)) {
                locCurPlan = childPlanPlanMstMap.get(locProductCode);
                System.debug(LoggingLevel.INFO, 'locCurPlan:::::::::::::::' + locCurPlan);
            }
            if (childPlanDetailMap.containsKey(locProductCode)) {
                locPlanDetailInf = childPlanDetailMap.get(locProductCode);
                System.debug(LoggingLevel.INFO, 'locPlanDetailInf:::::::::::::::' + locPlanDetailInf);
            }
            // 非課税商品が存在すると、該当非課税商品の金額はXMLの単価から減算する
            Decimal noTaxSumValueBaseSf = locPlanDetailInf.isHavePdData ? locPlanDetailInf.priceNoTaxSumVal : 0;
            Decimal noTaxSumValueBaseXml = 0;
            if (noTaxSumValueBaseSf > 0) {
                noTaxSumValueBaseXml = CommUtils.convertPriceByTaxKbn(noTaxSumValueBaseSf,
                    null,
                    item.refAccountMaster__r.ServiceRate__c,
                    CommConst.APPOPTION_UTP_DEF_KB,
                    taxSericeFee);
            }
            // 税区分変更をお行う「XMLに指定の税区分→SF側の税区分に変更」
            //bookingItem.UnitPrice__c = CommUtils.convertPriceByTaxKbn(  orgEstUnitPrice,
            bookingItem.UnitPrice__c = CommUtils.convertPriceByTaxKbn(orgEstUnitPrice - noTaxSumValueBaseXml,
                // 2016/09/08 プラン明細に非課税明細含め場合、計算結果不正の不具合修正 END
                item.refAccountMaster__r.jmstRef__r.TaxRate__c,
                item.refAccountMaster__r.ServiceRate__c,
                taxSericeFee,
                CommConst.APPOPTION_UTP_DEF_KB);
            // 小数桁数の再確認
            bookingItem.UnitPrice__c = checkIfHadScale(bookingItem.UnitPrice__c,
                item.refAccountMaster__r.jmstRef__r.TaxRate__c,
                item.refAccountMaster__r.ServiceRate__c,
                CommConst.APPOPTION_UTP_DEF_KB);
            mLogUtils.write_log('利用金額「変更後」(区分' + CommConst.APPOPTION_UTP_DEF_KB + ')：' + bookingItem.UnitPrice__c);
            // 2019/09/15 軽減税率機能対応 WGCH BEGIN
            Decimal estUnitPriceEnd = bookingItem.UnitPrice__c;
            // 2019/09/15 軽減税率機能対応 WGCH END
            // 2016/09/08 プラン明細に非課税明細含め場合、計算結果不正の不具合修正 BEGIN
            /*
            // 2016/06/10 子供料金プラン取り込み機能対応 BEGIN
            // 該当対応の会計商品コードを取得する、該当商品コード
            PlanDetailInfo locPlanDetailInf = gPlanDetailInf;
            Plan__c locCurPlan = pCurPlan;
            String locProductCode = bookingItem.Field3__c;
            mLogUtils.write_log('locProductCode:::::::::::::::'+locProductCode);
            mLogUtils.write_log('childPlanPlanMstMap:::::::::::::::'+childPlanPlanMstMap);
            mLogUtils.write_log('childPlanPlanMstMap.containsKey(locProductCode):::::::::::::::'+childPlanPlanMstMap.containsKey(locProductCode));
            if (childPlanPlanMstMap.containsKey(locProductCode)) {
                locCurPlan = childPlanPlanMstMap.get(locProductCode);
                mLogUtils.write_log('locCurPlan:::::::::::::::'+locCurPlan);
            }
            if (childPlanDetailMap.containsKey(locProductCode)) {
                locPlanDetailInf = childPlanDetailMap.get(locProductCode);
                mLogUtils.write_log('locPlanDetailInf:::::::::::::::'+locPlanDetailInf);
            }
            // 2016/06/10 子供料金プラン取り込み機能対応 END
            */
            // 2016/09/08 プラン明細に非課税明細含め場合、計算結果不正の不具合修正 END
            // プラン明細の金額自動配分を行う[プランかつプラン明細存在の場合、配分処理を行う]
            // 2016/06/10 子供料金プラン取り込み機能対応 BEGIN
            System.debug(LoggingLevel.INFO, 'locPlanDetailInf.isHavePdData:::::::::::::::' + locPlanDetailInf.isHavePdData);
            if (locPlanDetailInf.isHavePdData) {
                // 利用金額からSF側の単価定義区分と一致の利用金額を変換する
                // 変換後のSF側の利用金額
                Decimal curnPayPrice = bookingItem.UnitPrice__c;
                // SF側のプラン金額（単価）
                Decimal orgPlanPrice = locCurPlan.Price__c;
                // 非課税商品が存在する場合、利用金額は税込み、サビース料金計算後の金額を計算する
                if (locPlanDetailInf.priceNoTaxSumVal > 0) {
                    mLogUtils.write_log('非課税商品あり：金額：' + locPlanDetailInf.priceNoTaxSumVal);
                    // 2016/09/08 プラン明細に非課税明細含め場合、計算結果不正の不具合修正 BEGIN
                    /*
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
                    */
                    // 2016/06/10 子供料金プラン取り込み機能対応 END
                    //orgPlanPrice = orgPlanPrice - planDetailInf.priceNoTaxSumVal;
                    orgPlanPrice = orgPlanPrice - locPlanDetailInf.priceNoTaxSumVal;
                    // 2016/06/10 子供料金プラン取り込み機能対応 END
                    // 2019/09/15 軽減税率機能対応 WGCH BEGIN
                    // プラン元金額から非課税金額を外す
                    if(isReducedTaxFlg){
                    	curnPayPrice = estUnitPriceEnd;//CommUtils.nullToZero(estUnitPriceEnd) - CommUtils.nullToZero(locPlanDetailInf.priceNoTaxSumValEnd);
                    	orgPlanPrice = CommUtils.nullToZero(locPlanDetailInf.curnPayPriceEnd);
                    }
                    // 2019/09/15 軽減税率機能対応 WGCH END
                    mLogUtils.write_log('元のプラン金額は調整後：' + orgPlanPrice);
                    mLogUtils.write_log('元の利用金額は調整後：' + curnPayPrice);
                }
                // 2016/09/08 プラン明細に非課税明細含め場合、計算結果不正の不具合修正 END
                // 2019/09/15 軽減税率機能対応 WGCH BEGIN
                else if(isReducedTaxFlg){
                	curnPayPrice = estUnitPriceEnd;//CommUtils.nullToZero(estUnitPriceEnd) - CommUtils.nullToZero(locPlanDetailInf.priceNoTaxSumValEnd);
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
                if (orgPlanPrice != curnPayPrice) bookingItem.PlanDetailSyncInfo__c = getPlanDetailSyncInfo(orgPlanPrice, curnPayPrice, locPlanDetailInf);
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
        //for(BI_JR_RoomRateInfomation roomRate : roomRateLst){
        // 室料の場合
        //2015/12/14 RoomRateの場合、プラン室料自動設定機能を追加する 場所移動
        /*if(isRoomRateFlg){
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
        if (roomRate.TotalPerlRoomHotSpringTax > 0 && nyuuTouAcc.id != null && roomRate.TotalPerlRoomHotSpringTax != null) {
            Integer roomHotSpringCount = 1;
            Decimal unitPrice = roomRate.TotalPerlRoomHotSpringTax;
            if (nyuuTouAcc.Field5__c != null && nyuuTouAcc.Field5__c != 0) {
                decimal resultCount = roomRate.TotalPerlRoomHotSpringTax / nyuuTouAcc.Field5__c;
                if (resultCount.stripTrailingZeros().scale() == 0) {
                    roomHotSpringCount = integer.valueOf(resultCount);
                    unitPrice = nyuuTouAcc.Field5__c;
                }
            }
            detailLst.add(new BookingEstimateItem__c(
                refAccountMaster__c = nyuuTouAcc.id,
                UnitPrice__c = CommUtils.convertPriceByTaxKbn(unitPrice,
                    nyuuTouAcc.TaxRateCal__c,
                    nyuuTouAcc.ServiceRate__c,
                    taxSericeFee,
                    CommConst.APPOPTION_UTP_DEF_KB),
                refAccountMaster__r = nyuuTouAcc,
                Amount__c = roomHotSpringCount
            ));
        }
        // サビース料金場合
        if (roomRate.TotalPerRoomServiceFee > 0 && serviceAcc.id != null && roomRate.TotalPerRoomServiceFee != null) {
            BookingEstimateItem__c newItem =
                new BookingEstimateItem__c(
                    refAccountMaster__c = serviceAcc.id,
                    refAccountMaster__r = serviceAcc,
                    UnitPrice__c = CommUtils.convertPriceByTaxKbn(roomRate.TotalPerRoomServiceFee,
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
        //}
        mLogUtils.write_method_end();
        return detailLst;

    }

    // プラン関連のプラン明細の単価定義情報の取得する
    // 設定書式：プラン明細ID:単価:会計商品ID:会計商品名;
    private static String getPlanDetailSyncInfo(Decimal orgUnitPrice, Decimal curUnitPrice, PlanDetailInfo planDetailInf) {
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
                mLogUtils.write_log('減算可能金額[' + orgUnitPrice + ']は減算必要な金額[' + curUnitPrice + ']により、すくないので、配分なし');
                return CommConst.CONST_PLANITEM_NOEXPAND;
            } else {
                // プラン調整可能金額を再設定を行う
                orgUnitPrice = canChangePrice;
            }
        }
        // -----------------------
        // 金額調整を行う
        // -----------------------
        List < PlanDetail__c > roomPdList = planDetailInf.getClonePriceRoomPdList();
        //List<PlanDetail__c> otherPdList = planDetailInf.getClonePriceCanChangeOthPdList();
        map < Id, PlanDetail__c > changePdMap = new map < Id, PlanDetail__c > ();
        for (PlanDetail__c pd: roomPdList) {
            changePdMap.put(pd.id, pd);
        }
        //for (PlanDetail__c pd : otherPdList) {
        //changePdMap.put(pd.id, pd);
        //}

        // 調整必要の差分金額
        Decimal diffUnitSum = diffUnit;
        // 室料明細が存在する場合、室料明細に金額調整を行う
        if (!roomPdList.isEmpty()) {
            mLogUtils.write_log('室料明細調整前差分金額：' + diffUnit);
            diffUnitSum = divisionPlanDetailUnitPrice(orgUnitPrice, roomPdList, diffUnit, false);
            mLogUtils.write_log('室料明細調整後差分金額：' + diffUnitSum);
        }
        // 調整不可になる

        if (diffUnitSum != 0) return CommConst.CONST_PLANITEM_NOEXPAND;
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
            for (PlanDetail__c pd: planDetailInf.orgPlanDetailList) {
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
    private static Decimal divisionPlanDetailUnitPrice(Decimal orgUnitPrice, List < PlanDetail__c > pdList, Decimal orgDiffUnit, Boolean autoSplitFlg) {
        mLogUtils.write_method_start('divisionPlanDetailUnitPrice');
        // 小数点区分
        Integer pointLen = CommUtils.getPointLen();
        //PlanDetail__c maxItem = null;
        Decimal diffUnitSum = orgDiffUnit;
        if (autoSplitFlg) {
            orgUnitPrice = 0;
            // 自動配分対象の合計値から比率に配分する
            for (PlanDetail__c pd: pdList) {
                orgUnitPrice += pd.Price__c;
            }
        }
        // 明細に金額を反映を行う
        for (PlanDetail__c pd: pdList) {
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
            if (pointLen > 0) splitUnit = (diffUnitSum < 0 ? -1 : 1) * (1 / 10 * pointLen);
            Integer maxLen = 0; // Dead Loop
            while (diffUnitSum != 0) {
                if (maxLen > 10) break;
                for (PlanDetail__c pd: pdList) {
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
    //private static List<BookingEstimateItem__c> upsertBookingEstimeteItemsByEach(BI_JR_SyncInfo bookingInfo,Lead__c insLead){
    private static List < BookingEstimateItem__c > upsertBookingEstimeteItemsByEach(BI_JR_SyncInfo bookingInfo, Lead__c insLead, Integer taxSericeFee) {
        // 2017/08/15 option数据根据单价定义区分计算 fix END
        // オプション新規作成明細情報を格納する
        List < BookingEstimateItem__c > newOptList = new List < BookingEstimateItem__c > ();

        mLogUtils.write_method_start('upsertBookingEstimeteItemsByEach');
        if (bookingInfo.optionList == null || bookingInfo.optionList.isEmpty()) {
            return newOptList;
        }
        mLogUtils.write_log('option::' + bookingInfo.optionList);

        // オプション商品が存在する場合
        List < BI_JR_OptionInformation > optionLst = bookingInfo.optionList;
        // オプション商品コード　名を格納する
        //set<String> prodCodeSet = new set<String>();
        set < String > prodNameSet = new set < String > ();
        for (BI_JR_OptionInformation option: optionLst) {
            String productNm = option.Name;
            //String productCode = option.OptionCode;
            //if (!CommUtils.isBlank(productCode)) prodCodeSet.add(productCode);
            //if (!CommUtils.isBlank(productNm)) prodNameSet.add(productCode);
            if (!CommUtils.isBlank(productNm)) prodNameSet.add(productNm);
        }
        System.debug(LoggingLevel.INFO, '----------prodNameSet----------' + prodNameSet);
        // コードと名は全部NULLの場合、処理対象外
        //if(prodCodeSet.isEmpty() && prodNameSet.isEmpty()) return newOptList;
        if (prodNameSet.isEmpty()) return newOptList;
        // コード　OR　名前で既存会計商品から情報を取得する
        //List<AccountMaster__c> accs = [select id,name,Field3__c,jmstRef__r.TaxRate__c,ServiceRate__c from AccountMaster__c where Field3__c = :prodCodeSet or Name = :prodNameSet];
        // 2017/08/09 オプション商品検索の場合、非表示商品は対象外になる BEGIN
        //List<AccountMaster__c> accs = [select id,name,Field3__c,jmstRef__r.TaxRate__c,ServiceRate__c from AccountMaster__c where Name = :prodNameSet];
        List < AccountMaster__c > accs = [select id, name, Field3__c, jmstRef__r.TaxRate__c, ServiceRate__c from AccountMaster__c where Name =: prodNameSet And ActionType__c !=: CommConst.PROD_ACTION_TYPE_NO];
        // 2017/08/09 オプション商品検索の場合、非表示商品は対象外になる END
        // 関連会計商品が非存在する場合、処理中止
        if (accs.isEmpty()) return newOptList;
        //　既存会計商品情報を格納する
        map < String, AccountMaster__c > existAccNameMap = new map < String, AccountMaster__c > ();
        map < String, AccountMaster__c > existAccCodeMap = new map < String, AccountMaster__c > ();
        for (AccountMaster__c acc: accs) {
            existAccNameMap.put(acc.Name, acc);
            existAccCodeMap.put(acc.Field3__c, acc);
        }

        // オプション情報は見積明細に反映を行う[１泊目予約に格納]
        for (BI_JR_OptionInformation option: optionLst) {
            String productNm = option.Name;
            //String productCode = option.OptionCode;
            AccountMaster__c existAcc = null;
            // 同じコードの商品が存在する場合　
            /*if (existAccCodeMap.containsKey(productCode)) {
                existAcc = existAccCodeMap.get(productCode);
            } else if (existAccNameMap.containsKey(productNm)) {
                existAcc = existAccNameMap.get(productNm);
            }*/
            /*if (existAcc == null) continue;
            // 数量と利用金額を取得する
            Integer productCount = option.OptionCount;
            Integer unitPriceOptionRate = option.OptionRate;
            // 新規作成対象リスト
            newOptList.add(
                new BookingEstimateItem__c (
                        refAccountMaster__c = existAcc.id,
                        refAccountMaster__r = existAcc,
                        Amount__c = productCount,
                        UnitPrice__c = unitPriceOptionRate,
                        ProductName__c = existAcc.Name,
                        refBooking__c = insLead.id
                ));
        }
        mLogUtils.write_method_end();
        return newOptList;
    }*/
            if (existAccNameMap.containsKey(productNm)) {
                existAcc = existAccNameMap.get(productNm);
            }
            if (existAcc == null) continue;
            // 数量と利用金額を取得する
            // 2017/08/15 没有值报错 fix by zh BEGIN
            //Integer productCount = option.OptionCount;
            //Integer unitPriceOptionRate = option.OptionRate;
            Integer productCount = CommUtils.nullToIntZero(option.OptionCount);
            Integer unitPriceOptionRate = CommUtils.nullToIntZero(option.OptionRate);
            // 2017/08/15 没有值报错 fix by zh END
            // 新規作成対象リスト
            // 2017/08/15 option数据根据单价定义区分计算 fix BEGIN
            //newOptList.add(
            //new BookingEstimateItem__c (
            BookingEstimateItem__c bookingItem = new BookingEstimateItem__c(
                refAccountMaster__c = existAcc.id,
                refAccountMaster__r = existAcc,
                Amount__c = productCount,
                UnitPrice__c = unitPriceOptionRate,
                ProductName__c = existAcc.Name,
                refBooking__c = insLead.id
                //));
            );
            // 税区分変更をお行う「XMLに指定の税区分→SF側の税区分に変更」
            bookingItem.UnitPrice__c = CommUtils.convertPriceByTaxKbn(unitPriceOptionRate,
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
        System.debug(LoggingLevel.INFO, '----------newOptList----------' + newOptList);
        System.debug(LoggingLevel.INFO, '----------upsertBookingEstimeteItemsByEach END-----------');
        return newOptList;
    }
    // 2016/06/20 EDIT END

    /**
     * 代表者として、取引先責任者作成する
     **/
    //private static Contact upsertContact(BI_JR_SyncInfo bookingInfo) {
    private static Contact upsertContact(BI_JR_SyncInfo bookingInfo, Lead__c firstLead) {
        mLogUtils.write_method_start('upsertContact');
        Contact curContact = null;
        // 2016/07/01 EDIT end
        // 予約者情報
        BI_JR_Member member = bookingInfo.member;
        String applicantName = member != null ? member.UserName : null; // 申込者
        String applicantPhone = member != null ? member.UserTel : null; // 申込者電話
        // 団体代表顧客様名
        String primaryUsr = bookingInfo.GuestOrGroupNameKanjiName;
        String primaryUsrKana = bookingInfo.GuestOrGroupNameSingleByte;
        String contactNameKataKana = bookingInfo.GuestOrGroupNameDoubleByte;
        // 漢字名とカナ名
        String[] contactNameArr1 = CommUtils.splitName(CommUtils.nullToBlank(primaryUsr));
        String[] contactNameArr2 = CommUtils.splitName(CommUtils.nullToBlank(primaryUsrKana));
        String fullName1 = (contactNameArr1[0] + ' ' + (contactNameArr1.size() > 1 && !CommUtils.isBlank(contactNameArr1[1]) ? contactNameArr1[1] : '')).trim();
        String fullName2 = (contactNameArr2[0] + ' ' + (contactNameArr2.size() > 1 && !CommUtils.isBlank(contactNameArr2[1]) ? contactNameArr2[1] : '')).trim();
        // 顧客様名と顧客様電話番号で、既存データ存在チェックを行う
        List < Contact > existCList = null;
        //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH BEGIN
        Boolean isChgExistUserFlg = false;
        //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH END
        // 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ BEGIN
        boolean conAlwaysNewFlg = BI_JR_ServiceConfigHelp.getAppConfig(shopCd).contactAlwaysNew;
        // XMLタグがTRUEかつ新規予約の場合、お客様情報は常に新規作成する
        conAlwaysNewFlg = conAlwaysNewFlg && (bookingInfo.dmlAction == BI_JR_DmlAction.INS);
        // 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ END
        // 予約情報が既に存在の場合、該当お客様情報を取得、戻る
        if (bookingInfo.dmlAction == BI_JR_DmlAction.UPD && firstLead != null) {
            String contactId = firstLead.Relcontact__c;
            existCList = [select LastName, FirstName, Name1__c, KanaName1__c, Katakana__c, Phone, Email, MailingPostalCode, MailingStreet,
            	//2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH BEGIN
            	//Phone2__c抽出項目を追加する
                ApplicantName__c, ApplicantPhone__c, Birthdate, MobilePhone, Phone2__c from Contact where id =: contactId
                //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH END
            ];
            // 2018/04/19 氏名変更のみケース対応 BEGIN
            if (bookingInfo.isUpdForName) {
                Contact c = existCList[0];
	            String locPrimaryUsr = CommUtils.isBlank(primaryUsr) ? primaryUsrKana : primaryUsr;
            	String[] contactNameArr = CommUtils.splitName(locPrimaryUsr);
	            c.LastName = contactNameArr[0];
            	c.FirstName = (contactNameArr.size() > 1 ? contactNameArr[1] : '');
	            // 団体名または代表者氏名 漢字
	            c.Name1__c = bookingInfo.GuestOrGroupNameKanjiName;
	            // 団体名または代表者氏名よみがな(半角)
	            c.KanaName1__c = bookingInfo.GuestOrGroupNameSingleByte;
	            // ひらがな ←　団体名または代表者氏名よみがな(全角)
	            c.Katakana__c = bookingInfo.GuestOrGroupNameDoubleByte;
	            existCList[0] = (new CommLogicProcess()).upsertDuplicateErrorProcess(existCList[0]);
	            //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH BEGIN 
	            return existCList[0]; 
	            //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH END
            }
            // 2018/04/19 氏名変更のみケース対応 END
            //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH BEGIN 
            //if (!existCList.isEmpty()) return existCList[0];
            // 該当データは変更通知の既存ユーザーありを識別する
            isChgExistUserFlg = true;
            //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH END
        }

        // 団体名または代表者氏名 漢字
        Map < String, Contact > contactMap = new Map < String, Contact > ();
        // 団体名または代表者氏名(半角)
        Map < String, Contact > kanaNmMap = new Map < String, Contact > ();

        // 個々の部屋とお客様リスト
        for (BI_JR_RoomAndGuestInfo roomAndGuest: bookingInfo.roomAndGuestLst) {

            System.debug(LoggingLevel.INFO, '----------roomAndGuest----------' + roomAndGuest);

            // お客様情報リスト
            BI_JR_GuestInfo guestInformation = roomAndGuest.guest;
            System.debug(LoggingLevel.INFO, '----------guestInformation----------' + guestInformation);
            list < BI_JR_GuestInformationList > guestInformationList = guestInformation != null ? guestInformation.guestInformationList : null;
            if (guestInformationList == null) continue;
            mLogUtils.write_log('----------guestInformationList----------' + guestInformationList);

            for (BI_JR_GuestInformationList guestInfo: guestInformationList) {
                System.debug(LoggingLevel.INFO, 'お客様情報：' + guestInfo);
                // お客様情報リスト
                String contactNm = guestInfo.GuestKanjiName;
                String contactKana = guestInfo.GuestNameSingleByte;
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
                contactItem.Name1__c = guestInfo.GuestKanjiName;
                // カナ
                contactItem.KanaName1__c = guestInfo.GuestNameSingleByte;
                //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH BEGIN 
                // 下記タグは情報設定されないため、設定不要
                // ひらがな
                //contactItem.Katakana__c = guestInfo.GuestSurName;
                //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH END
                // Phone
                String locPhone = CommUtils.convTelphoneNumber(guestInfo.GuestPhoneNumber);
                if (!CommUtils.isBlank(locPhone)) contactItem.Phone = guestInfo.GuestPhoneNumber;
                // 緊急連絡先
                locPhone = CommUtils.convTelphoneNumber(guestInfo.GuestEmergencyPhoneNumber);
                if (!CommUtils.isBlank(locPhone)) contactItem.Phone2__c = guestInfo.GuestEmergencyPhoneNumber;
                // お客様Email
                contactItem.Email = guestInfo.GuestEmail;
                // お客様住所都道府県
                if (!CommUtils.isBlank(guestInfo.GuestStateProvidence)) {
                    List < String > addressLst = CommUtils.parseJapanAddress(guestInfo.GuestStateProvidence);
                    if (addressLst.size() == 3) {
                        contactItem.MailingState = addressLst[0];
                        contactItem.MailingCity = addressLst[1];
                        contactItem.MailingStreet = addressLst[2];
                    } else {
                        contactItem.MailingStreet = addressLst[0];
                    }
                }
                // お客様住所郵便番号
                contactItem.MailingPostalCode = guestInfo.GuestPostalCode;
                // MAPに、顧客上はMAPに格納する
                if (!CommUtils.isBlank(contactNm)) contactMap.put(contactNm, contactItem);
                // MAPに、顧客KANAはMAPに格納する
                if (!CommUtils.isBlank(contactKana)) kanaNmMap.put(contactKana, contactItem);
            }
        }

        //System.debug('contactMap：'+contactMap);
        //System.debug('kanaNmMap：'+kanaNmMap);
        // お客様情報リストから宿泊ユーザー詳細情報をある場合
        if (contactMap.containsKey(primaryUsr) || kanaNmMap.containskey(primaryUsrKana)) {
            // お客様情報リストから設定情報を取得する
            curContact = contactMap.containsKey(primaryUsr) 
                        ? contactMap.get(primaryUsr)
                        : kanaNmMap.get(primaryUsrKana);
        }
        // Member情報
        else if (member != null && (member.UserName == primaryUsr || member.UserKana == primaryUsrKana)) {
            // お客様情報リスト
            String contactNm = member.UserName;
            String contactKana = member.UserKana;

            // 新規存在の顧客情報を設定する
            curContact = new Contact();

            String[] contactNameArr = CommUtils.splitName(CommUtils.isBlank(contactNm) ?
                contactKana : contactNm);
            String lastName = contactNameArr[0];
            String firstName = (contactNameArr.size() > 1 ? contactNameArr[1] : null);
            curContact.LastName = lastName;
            curContact.FirstName = firstName;
            // 漢字
            curContact.Name1__c = contactNm;
            // カナ
            curContact.KanaName1__c = contactKana;
            // Phone:予約者・会員電話番号
            String locPhone = CommUtils.convTelphoneNumber(member.UserTel);
            if (!CommUtils.isBlank(locPhone)) curContact.Phone = member.UserTel;
            // お客様Email:予約者・会員Email
            curContact.Email = member.UserMailAddr;
            // 郵便NO
            curContact.MailingPostalCode = member.UserZip;
            // UserAddr
            // お客様住所都道府県
            if (!CommUtils.isBlank(member.UserAddr)) {
                List < String > addressLst = CommUtils.parseJapanAddress(member.UserAddr);
                if (addressLst.size() == 3) {
                    curContact.MailingState = addressLst[0];
                    curContact.MailingCity = addressLst[1];
                    curContact.MailingStreet = addressLst[2];
                } else {
                    curContact.MailingStreet = addressLst[0];
                }
            }
        }
        System.debug(loggingLevel.INFO, '---------curContact--------' + curContact);
        // お客様情報が存在する場合
        if (curContact != null) {
            if (curContact.firstName == '_' || curContact.firstName == '!') curContact.firstName = '';
            // 申込者
            curContact.ApplicantName__c = applicantName;
            // 申込者電話番号
            curContact.ApplicantPhone__c = applicantPhone;
        } else {
            curContact = new CONTACT();
            // 該当ユーザー情報は代表者に対して、新規ユーザーを作成する
            String locPrimaryUsr = CommUtils.isBlank(primaryUsr) ? primaryUsrKana : primaryUsr;
            String[] contactNameArr = CommUtils.splitName(locPrimaryUsr);
            // 団体名または代表者氏名(半角)
            curContact.LastName = contactNameArr[0];
            curContact.FirstName = (contactNameArr.size() > 1 ? contactNameArr[1] : '');
            // 団体名または代表者氏名 漢字
            curContact.Name1__c = primaryUsr;
            // 団体名または代表者氏名よみがな(全角)
            curContact.KanaName1__c = primaryUsrKana;
            // ひらがな ←　団体名または代表者氏名よみがな(全角)
            curContact.Katakana__c = bookingInfo.GuestOrGroupNameDoubleByte;
        }
        //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH BEGIN 
        // 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ BEGIN
		if (!conAlwaysNewFlg) {
		// 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ END
        // 変更通知以外の場合、関連お客様情報を検索する、変更の場合、再度検索が不要
        if (!isChgExistUserFlg) {
        //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH END 
	        // 2016/05/25 お客様電文番号は[--]の場合、エラー回避
	        String queryPhone = CommUtils.convTelphoneNumber(curContact.Phone);
	        // 2017/12/14 SOSLキーチェック追加対応 BEGIN
	        //if (!CommUtils.isBlank(queryPhone)) {
	        if (CommUtils.isValidateSoslKey(queryPhone)) {
	            // 2017/12/14 SOSLキーチェック追加対応 BEGIN
	            // 既存顧客様情報を探す
	            //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH BEGIN 
	            // SOQL返却項目「Name1__c,Katakana__c,Email,MailingPostalCode,Phone,Phone2__c」を追加
	            String soslQuery = 'FIND :queryPhone IN PHONE FIELDS RETURNING CONTACT (id, name,Name1__c,KanaName1__c,Katakana__c,Email,MailingPostalCode,Phone,Phone2__c where ( Name = :fullName1 or Name  = :fullName2) ';
	            //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH END
	            if (!CommUtils.isBlank(primaryUsrKana)) soslQuery += ' OR KanaName1__c =:primaryUsrKana ';
	            if (!CommUtils.isBlank(primaryUsr)) soslQuery += ' OR Name1__c = :primaryUsr ';
	            if (!CommUtils.isBlank(contactNameKataKana)) soslQuery += ' OR Katakana__c = :contactNameKataKana ';
	            soslQuery += ' limit 1) ';
	            List < List < Sobject >> existRs = search.query(soslQuery);
	            existCList = existRs[0];
	            mLogUtils.write_log('既存お客様:' + existCList);
	            System.debug(loggingLevel.INFO, '---------既存お客様--------' + existCList);
	        }
        //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH BEGIN 
        } //if (!isChgExistUserFlg)
        //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH END  
        if (existCList != null && !existCList.isEmpty()) {
            existCList[0].ApplicantName__c = applicantName;
            existCList[0].ApplicantPhone__c = applicantPhone;
            //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH BEGIN 
		if (CommUtils.isBlank(curContact.Name1__c)) curContact.Name1__c = primaryUsr;
		if (CommUtils.isBlank(curContact.KanaName1__c)) curContact.KanaName1__c = primaryUsrKana;
		if (CommUtils.isBlank(curContact.Katakana__c)) curContact.Katakana__c = contactNameKataKana;
			
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
            existCList[0] = (new CommLogicProcess()).upsertDuplicateErrorProcess(existCList[0]);
            return existCList[0];
        }
    // 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ BEGIN
	}
	// 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ END      
        // 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ BEGIN
		if (!conAlwaysNewFlg) {
		// 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ END
        Contact newContact = (new CommLogicProcess()).upsertDuplicateErrorProcess(curContact);
        // 2016/05/24 お客様重複チェック対応 END
        mLogUtils.write_log('お客様新規作成::' + newContact.id);
        mLogUtils.write_method_end();
        return newContact;
        // 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ BEGIN
		} else {
			(new CommLogicProcess()).forceUpdate(curContact, mLogUtils);
			return curContact;
		}
		// 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ END
        
    }


    /*
     * 旅行会社情報はSFへ登録を行う
     * 会社・営業所が存在する場合、営業所は
     */
    private static List < Account > upsertTravelInfo(BI_JR_SyncInfo bookingInfo) {
        mLogUtils.write_method_start('upsertTravelInfo');
        // 旅行会社のPakcageコードは再設定を行う
        //BI_TL_RisaplBasic risaplBasic = bookingInfo.risaplsinformation.risaplsCommonInformation.risaplBasic;
        //bookingInfo.SalesOfficeCompanyCode = risaplBasic.SalesOfficeCompanyCode;
        // 旅行会社名と同じ取引先が存在するかどうかチェックを行う
        Account travelCompany = null;
        // 旅行会社存在する場合
        if (!CommUtils.isBlank(bookingInfo.SalesOfficeCompanyName) &&
            !CommUtils.isBlank(bookingInfo.SalesOfficeCompanyCode)) {
            List < Account > travelCompanyLst = [select id, name, SalesOfficeCompanyCodeJR__c from Account
                // 2016/06/20 EDIT BEGIN
                //where name = :bookingInfo.SalesOfficeCompanyName 
                //And AccountType__c = :CommConst.ACCOUNT_TYPE_TRAVEL
                //and SalesOfficeCompanyCode__c = :bookingInfo.SalesOfficeCompanyCode limit 1];
				Where ((SalesOfficeCompanyCodeJR__c = :bookingInfo.SalesOfficeCompanyCode)
						OR
						(Name = :bookingInfo.SalesOfficeCompanyName and SalesOfficeCompanyCode__c = :bookingInfo.SalesOfficeCompanyCode )
						)
					And AccountType__c = :CommConst.ACCOUNT_TYPE_TRAVEL limit 1];
            // 2016/06/20 EDIT END
            // 存在なければ、取引先を新規作成する
            if (travelCompanyLst.isEmpty()) {
                travelCompany = new Account();
                travelCompany.Name = bookingInfo.SalesOfficeCompanyName;
                travelCompany.SalesOfficeCompanyCode__c = bookingInfo.SalesOfficeCompanyCode;
                travelCompany.AccountType__c = CommConst.ACCOUNT_TYPE_TRAVEL;
                // 2016/06/20 EDIT BEGIN
                travelCompany.SalesOfficeCompanyCodeJR__c = bookingInfo.SalesOfficeCompanyCode;
                travelCompany.SalesOfficeCompanyCodeJRAPI__c = bookingInfo.SalesOfficeCompanyCode;
                // 2016/06/20 EDIT END
                insert travelCompany;
            } else {
                travelCompany = travelCompanyLst[0];
                if (CommUtils.isBlank(travelCompany.SalesOfficeCompanyCodeJR__c)) {
                    travelCompany.SalesOfficeCompanyCodeJR__c = bookingInfo.SalesOfficeCompanyCode;
                    travelCompany.SalesOfficeCompanyCodeJRAPI__c = bookingInfo.SalesOfficeCompanyCode;
                    update travelCompany;
                }
            }
            mLogUtils.write_log('旅行会社AGT[' + (travelCompanyLst.isEmpty() ? '新規' : '既存') + ']' + travelCompany);
        }

        Account traveOffice = null;
        // 2016/06/20 EDIT BEGIN
        // 2016/02/01 旅行会社（営業所）の取得方式変更（「営業所コード」と「取引先ID」で合わせて取得する）BEGIN
        if (!CommUtils.isBlank(bookingInfo.SalesOfficeCode)) {
            // 取引先IDと営業所コードで存在チェックを行う
            List < Account > traveOfficeLst = [select id, name, ParentId, SalesOfficeCodeJR__c from Account
                where AccountType__c =: CommConst.ACCOUNT_TYPE_TRAVEL
                and ParentId =: travelCompany.Id
				and	(SalesOfficeCodeJR__c = :bookingInfo.SalesOfficeCode
					OR
					 SalesOfficeCode__c = :bookingInfo.SalesOfficeCode)
				limit 1];
            if (!traveOfficeLst.isEmpty()) {
                traveOffice = traveOfficeLst[0];
                // 既存の取引先（営業所）のコードはNULLの場合、自動設定を行う
                if (CommUtils.isBlank(traveOffice.SalesOfficeCodeJR__c)) {
                    traveOffice.SalesOfficeCodeJR__c = bookingInfo.SalesOfficeCode;
                    update traveOffice;
                }
                mLogUtils.write_log('旅行会社-支店既存取得::' + traveOffice.id);
            }
        }
        // 2016/02/01 旅行会社（営業所）の取得方式変更（「営業所コード」と「取引先ID」で合わせて取得する）END
        // 2016/06/20 EDIT END
        // 旅行会社営業所情報が存在する場合
        // 2016/06/20 EDIT BEGIN
        //if (!CommUtils.isBlank(bookingInfo.SalesOfficeCode) &&!CommUtils.isBlank(bookingInfo.SalesOfficeName) ) 
        if (traveOffice == null && !CommUtils.isBlank(bookingInfo.SalesOfficeCode) &&
            !CommUtils.isBlank(bookingInfo.SalesOfficeName)) {

            // 旅行会社営業所情報をチェックを行う
            /*List<Account> traveOfficeLst = [select id , name from Account
                where name = :bookingInfo.SalesOfficeName 
                and AccountType__c = :CommConst.ACCOUNT_TYPE_TRAVEL
                and SalesOfficeCode__c = :bookingInfo.SalesOfficeCode limit 1];*/
            List < Account > traveOfficeLst = [select id, name, ParentId, SalesOfficeCodeJR__c from Account
                where name =: bookingInfo.SalesOfficeName
                and AccountType__c =: CommConst.ACCOUNT_TYPE_TRAVEL
				and SalesOfficeCode__c = :bookingInfo.SalesOfficeCode limit 1];
            // 2016/06/20 EDIT END
            if (traveOfficeLst.isEmpty()) {
                traveOffice = new Account();
                traveOffice.Name = bookingInfo.SalesOfficeName;
                traveOffice.AccountType__c = CommConst.ACCOUNT_TYPE_TRAVEL;
                traveOffice.SalesOfficeCode__c = bookingInfo.SalesOfficeCode;
                // 2016/06/20 EDIT BEGIN
                // 2016/02/01 旅行会社（営業所）の取得方式変更（「営業所コード」と「取引先ID」で合わせて取得する）BEGIN
                traveOffice.SalesOfficeCodeJR__c = bookingInfo.SalesOfficeCode;
                // 2016/02/01 旅行会社（営業所）の取得方式変更（「営業所コード」と「取引先ID」で合わせて取得する）END
                // 2016/06/20 EDIT END
                traveOffice.ParentId = (travelCompany != null ? travelCompany.Id : null);
                traveOffice.Phone = bookingInfo.SalesOfficePhoneNumber;
                insert traveOffice;
                mLogUtils.write_log('旅行会社-支店新規作成::' + traveOffice.id);
            } else {
                traveOffice = traveOfficeLst[0];
                // 2016/06/20 EDIT BEGIN
                if (traveOffice.ParentId != travelCompany.Id || CommUtils.isBlank(traveOffice.SalesOfficeCodeJR__c)) {
                    traveOffice.ParentId = travelCompany.Id;
                    traveOffice.SalesOfficeCodeJR__c = bookingInfo.SalesOfficeCode;
                    update traveOffice;
                }
                mLogUtils.write_log('旅行会社-支店既存取得::' + traveOffice.id);
                // 2016/06/20 EDIT END
            }
        }
        // 担当者->取引先責任者に設定を行う
        // 取引担当者が存在する場合、担当者として、登録する
        if ((travelCompany != null || traveOffice != null) &&
            !CommUtils.isBlank(bookingInfo.SalesOfficePersonInCharge) &&
            !CommUtils.isBlank(bookingInfo.SalesOfficePhoneNumber)) {
            // 同じ氏名と電話の担当者存在チェックを行う
            List < Contact > contactLst = [select id, name from Contact where LastName =: bookingInfo.SalesOfficePersonInCharge and phone =: bookingInfo.SalesOfficePhoneNumber];
            if (contactLst.isEmpty()) {
                Contact newContact = new Contact();
                newContact.LastName = bookingInfo.SalesOfficePersonInCharge;
                newContact.phone = bookingInfo.SalesOfficePhoneNumber;
                newContact.AccountId = (traveOffice == null ? travelCompany.Id : traveOffice.Id);
                insert newContact;
                mLogUtils.write_log('旅行会社関連担当者情報作成::' + newContact.Id);
            }
        }
        // 2016/06/20 EDIT BEGIN
        /*List<Account> rsAccountLst = new List<Account>();
        if (travelCompany != null) rsAccountLst.add(travelCompany);
        if (traveOffice != null) rsAccountLst.add(traveOffice);
        return rsAccountLst;*/
        // 2016/06/20 EDIT END
        // 2016/07/14 予約チャネル名の設定内容変更対応 BEGIN
        //return (traveOffice == null ? travelCompany: traveOffice);
        List < Account > rsAccountLst = new List < Account > ();
        if (travelCompany != null) rsAccountLst.add(travelCompany);
        if (traveOffice != null) rsAccountLst.add(traveOffice);
        mLogUtils.write_method_end();
        return rsAccountLst;
        // 2016/07/14 予約チャネル名の設定内容変更対応 END
    }

    // 支払方法転換
    private static string getLocalPaymentInfo(String mediaType) {
        String ttendType = null;
        if (mediaType == 'Cach' || mediaType == 'Cash') ttendType = CommConst.MEDIA_TYPE_CD_01;
        else if (mediaType == 'CreditCard') ttendType = CommConst.MEDIA_TYPE_CD_02;
        //else if (mediaType == '売掛') ttendType = CommConst.MEDIA_TYPE_CD_03;
        else if (mediaType == 'Coupon') ttendType = CommConst.MEDIA_TYPE_CD_11;
        // 支払方法設定
        String mediaTypeName = CommConst.getPaymentTypeLabelByKey(ttendType);
        return (mediaTypeName == null ? mediaType : mediaTypeName);
    }

    // 2016/06/20 EDIT BEGIN
    private static AccountMaster__c getShiTuLyouAcc() {
        List < AccountMaster__c > shituLyoAccs = ProductItemUtils.getRoomRateProduct(CommConst.APPOPTION_ROOMPRICE_PRODNAME);
        if (shituLyoAccs.isEmpty()) return new AccountMaster__c();
        else return shituLyoAccs[0];
    }
    // サビース料商品
    private static AccountMaster__c getServiceAcc() {
        String accountCd = BI_JR_ServiceConfigHelp.getAccountConfig(shopCd).serviceCd;
        if (CommUtils.isBlank(accountCd)) return new AccountMaster__c();
        List < AccountMaster__c > acc = [select Name, Id, TaxRateCal__c, ServiceRate__c from AccountMaster__c where Field3__c =: accountCd limit 1];
        if (acc.isEmpty()) return new AccountMaster__c();
        return acc[0];
    }
    // 入湯税商品
    private static AccountMaster__c getNyuuTouAcc() {
        String accountCd = BI_JR_ServiceConfigHelp.getAccountConfig(shopCd).nyuuTouCd;
        if (CommUtils.isBlank(accountCd)) return new AccountMaster__c();
        List < AccountMaster__c > acc = [select Name, Id, Field5__c, TaxRateCal__c, ServiceRate__c from AccountMaster__c where Field3__c =: accountCd limit 1];
        if (acc.isEmpty()) return new AccountMaster__c();
        return acc[0];
    }
    private String setUpdateContent(LeadIndex__c leadIndex, BI_JR_SyncInfo bookingInfo) {
        List < Attachment > rsAtt = [select Name, Body, ParentId from attachment where parentId =: leadIndex.Id order by CreatedDate desc];
        //rsAtt[0];
        //bookingInfo.
        //BI_TL_SyncInfo.
        return '';
    }

    // 自動割り振りできる部屋リスト情報を取得する
    // 2015/10/30 故障部屋は自動割当て機能に追加対応 BEGIN
    //private map<Id,List<Room__c>> getCanAssignRoom(LeadIndex__c leadIndex, List<Id> roomTypeIdLst, boolean autoAssingRoomflag, BI_TL_SyncInfo bookingInfo){
    private static map < Integer, Room__c > getCanAssignRoom(LeadIndex__c leadIndex, Map < String, Id > roomTypeMap, boolean autoAssingRoomflag, BI_JR_SyncInfo bookingInfo, Map < String, Id > roomTypeNmMap) {
        // 2015/10/30 故障部屋は自動割当て機能に追加対応 END
        mLogUtils.write_method_start('getCanAssignRoom');
        map < Id, Id > targetRoomIdTypeMap = new map < Id, Id > ();
        map < Id, List < Room__c >> wkCanAssignRoomMap = new map < Id, List < Room__c >> ();
        map < Integer, Room__c > resultMap = new map < Integer, Room__c > ();
        // 自動割り振りの順次でアサイン対象部屋情報を取得する
        // 2015/10/30 故障部屋は自動割当て機能に追加対応 BEGIN
        List < Id > roomTypeIdLst = roomTypeMap.values();
        // 2015/10/30 故障部屋は自動割当て機能に追加対応 END
        // 2017/08/31 部屋タイプ名で部屋自動割り当てできる対応 BEGIN
        if (!roomTypeNmMap.isEmpty()) roomTypeIdLst.addAll(roomTypeNmMap.values());
        // 2017/08/31 部屋タイプ名で部屋自動割り当てできる対応 END
        String sortField = BI_JR_ServiceConfigHelp.getAppConfig(shopCd).roomSortKey;
        String queryHead = 'select id,Name,TypeRoomRef__c from Room__c ';
        String queryWhere = ' where UseOfRoom__c = \'' + String.escapeSingleQuotes(CommConst.ROOM_UseOfType_Guest) + '\'' +
            ' And TypeRoomRef__c in :roomTypeIdLst ';
        String queryOrder = ' Order By priority__c ' + sortField + ' NULLS LAST ';
        String queryString = queryHead + queryWhere + queryOrder;
        // 今回XMLに指定の部屋タイプに関連の部屋定義情報を取得する
        for (Room__c room: DataBase.query(queryString)) {
            // 部屋　と　部屋タイプマッピング情報を格納する
            targetRoomIdTypeMap.put(room.Id, room.TypeRoomRef__c);
            // 部屋単位の部屋情報を格納する
            if (!wkCanAssignRoomMap.containsKey(room.TypeRoomRef__c)) {
                wkCanAssignRoomMap.put(room.TypeRoomRef__c, new List < Room__c > ());
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
        Set < Id > usedRoomIdSet = new Set < Id > ();
        // 既に予約データに入る場合、該当部屋は選択対象外になる
        for (AggregateResult lead: [
                select Rroom__c roomId from Lead__c
                where CancelBool__c !=: CommConst.LEAD_ST_CANCEL_FLG
                // 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 BEGIN
                //And DAY_ONLY(convertTimezone(EntryTime__c)) >= :leadIndex.EntryDate__c
                //And DAY_ONLY(convertTimezone(EntryTime__c)) <= :leadIndex.DepartureDate__c 
                And DAY_ONLY(convertTimezone(EntryTime__c)) >=: wkBeginDate
                And DAY_ONLY(convertTimezone(EntryTime__c)) <=: wkEndDate
                // 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 END
                And Rroom__c in: targetRoomIdTypeMap.keySet()
                And LeadIndexRef__c !=: leadIndex.Id
                    Group By Rroom__c]) {
            usedRoomIdSet.add((Id) lead.get('roomId'));
        }
        // 存在の部屋情報から予約データに利用している部屋は自動アサイン対象外になる
        // map<部屋タイプID,部屋リスト>
        map < Id, List < Room__c >> canAssignRoomMap = new map < Id, List < Room__c >> ();
        for (Id roomTypeId: wkCanAssignRoomMap.keySet()) {
            List < Room__c > targetRoomLst = wkCanAssignRoomMap.get(roomTypeId);
            for (Room__c room: targetRoomLst) {
                // 既に使っている部屋の場合、対象外になる
                if (usedRoomIdSet.contains(room.Id)) continue;
                if (!canAssignRoomMap.containskey(roomTypeId)) canAssignRoomMap.put(roomTypeId, new List < Room__c > ());
                canAssignRoomMap.get(roomTypeId).add(room);
            }
        }
        // アサインできる部屋はない場合、チェック処理中止
        if (canAssignRoomMap.isEmpty()) return resultMap;
        // 2015/10/31 故障部屋チエックロジックを追加対応 BEGIN
        // 同じ部屋、利用日により、同じ部屋は連続の日付はリストに入る
        // 開始日　〜　終了日期間日を取得する
        Integer nights = bookingInfo.Nights; // 総宿泊数
        if (nights == 0) nights = 1;
        Integer rooms = bookingInfo.TotalRoomCount; // 総部屋数
        // 部屋→部屋タイプリスト→map<部屋タイプコード、関連の日付>
        //List<List<map<string,list<Date>>>> roomTypeList = new List<List<map<string,list<Date>>>>(); 
        //map<Integer, list<date>> roomTypeDateLinkMap = new map<Integer, list<date>>();

        // 部屋単位に、宿泊期間内の部屋タイプリスト一覧情報を格納する
        map < Integer, list < string >> tmpRoomTypeListMap = new map < Integer, list < string >> ();
        // 宿泊期間情報を格納する、1部屋A：1/1,1/2,1/3日は同じ部屋タイプすると、0,1,2は同じリストを格納する<1, <1/1,1/2,1/3>, 2,<1/1,1/2,1/3>>...
        map < Integer, list < date >> roomTypeDateLinkByIdxMap = new map < Integer, list < date >> ();
        BI_JR_RoomAndGuestInfo[] roomAndGuest = bookingInfo.roomAndGuestLst;
        // XMLの宿泊部屋単位情報
        for (Integer j = 0; j < rooms; j++) {
            list < string > oneRoomRoomTypes = new list < string > ();
            tmpRoomTypeListMap.put(j, oneRoomRoomTypes);
            // 1部屋N日単位情報
            for (Integer i = 0; i < nights; i++) {
                // 情報を取得IDEXを定義する
                Integer idx = i * rooms + j;
                // 部屋タイプリスト情報を格納する
                String roomTypeCd = roomAndGuest[idx].room.RoomTypeCode;
                // 2017/08/31 部屋タイプ名で部屋自動割り当てできる対応 BEGIN
                if (CommUtils.isBlank(roomTypeCd)) roomTypeCd = roomAndGuest[idx].room.RoomTypeName;
                // 2017/08/31 部屋タイプ名で部屋自動割り当てできる対応 END
                // 部屋利用日（到着日)
                //Date stayDate = roomAndGuest[idx].roomRateLst[0].RoomDate;
                Date stayDate = roomAndGuest[idx].roomRate.RoomDate;
                if (oneRoomRoomTypes.isEmpty()) {
                    oneRoomRoomTypes.add(roomTypeCd);
                    list<date> newitems = new list<date>{stayDate};
                    roomTypeDateLinkByIdxMap.put(idx, newitems);
                } else {
                    // 前回の部屋タイプを取得して、
                    string preRoomTypeCd = oneRoomRoomTypes[oneRoomRoomTypes.size() - 1];
                    // 泊期間に、部屋タイプ変更の場合
                    if (preRoomTypeCd != roomTypeCd) {
                        oneRoomRoomTypes.add(roomTypeCd);
                        list<date> newitems = new list<date>{stayDate};
                        roomTypeDateLinkByIdxMap.put(idx, newitems);
                    } else {
                        // 日付を連続に設定を行う
                        list < date > preitems = roomTypeDateLinkByIdxMap.get((i - 1) * rooms + j);
                        preitems.add(stayDate);
                        roomTypeDateLinkByIdxMap.put(idx, preitems);
                    }
                }
            }
        }
        System.debug(LoggingLevel.INFO, 'tmpRoomTypeListMap::' + tmpRoomTypeListMap);
        System.debug(LoggingLevel.INFO, 'roomTypeDateLinkByIdxMap::' + roomTypeDateLinkByIdxMap);
        // 2015/10/31 故障部屋チエックロジックを追加対応 END
        set < id > isAutoAssignRoomtSet = new set < Id > ();
        for (list < Room__c > canAssRooms: canAssignRoomMap.values()) {
            for (Room__c canAssRoom: canAssRooms) {
                isAutoAssignRoomtSet.add(canAssRoom.id);
            }
        }
        RoomStatusManager roomStatusManger = new RoomStatusManager();
        // 指定期間ないの故障部屋リストを取得する
        List < RoomsStatus__c > roomsStatus = roomStatusManger.queryBadRoomList(leadIndex.EntryDate__c, leadIndex.DepartureDate__c, isAutoAssignRoomtSet);
        system.debug(logginglevel.info, '====roomsStatus=====' + roomsStatus);
        // 指定部屋の故障ありの日付情報を格納する
        Map < id, List < RoomsStatus__c >> badRoomStatusMap = new Map < id, List < RoomsStatus__c >> ();
        //Map<Id, String> roomNameMap = new map<Id, String>();
        for (RoomsStatus__c roomStatus: roomsStatus) {
            //roomNameMap.put(roomStatus.RoomRef__c, roomStatus.RoomRef__r.Name);
            if (!badRoomStatusMap.containsKey(roomStatus.RoomRef__c)) {
                badRoomStatusMap.put(roomStatus.RoomRef__c, new List < RoomsStatus__c > ());
            }
            badRoomStatusMap.get(roomStatus.RoomRef__c).add(roomStatus);
            //Set<Date> curSet = badRoomStatusMap.get(roomStatus.RoomRef__c);
            //integer betweenLength = roomStatus.StatusBeginDate__c.daysBetween(roomStatus.StatusEndDate__c);
            //curSet.addAll(CommUtils.getDaysList(roomStatus.StatusBeginDate__c,betweenLength));
            //if(canAssignRoomMap.containsKey(roomStatus.RoomRef__c))canAssignRoomMap.remove(roomStatus.RoomRef__c);
        }

        // 部屋単位
        for (Integer j = 0; j < rooms; j++) {
            // 日単位情報
            for (Integer i = 0; i < nights; i++) {
                // 情報を取得IDEXを定義する
                Integer idx = i * rooms + j;
                // 部屋タイプリスト情報を格納する
                String roomTypeCd = roomAndGuest[idx].room.RoomTypeCode;
                Id roomTypeId = roomTypeMap.get(roomTypeCd);
                // 2017/08/31 部屋タイプ名で部屋自動割り当てできる対応 BEGIN
                if (CommUtils.isBlank(roomTypeId)) {
                    String roomTypeNm = roomAndGuest[idx].room.RoomTypeName;
                    if (!CommUtils.isBlank(roomTypeNm)) roomTypeId = roomTypeNmMap.get(roomTypeNm);
                }
                // 2017/08/31 部屋タイプ名で部屋自動割り当てできる対応 END
                if (roomTypeId == null) continue;
                // 部屋タイプ関連の部屋リストを取得する
                List < Room__c > locCanAssingRoomList = canAssignRoomMap.get(roomTypeId);
                if (locCanAssingRoomList == null || locCanAssingRoomList.isEmpty()) continue;
                // 該当部屋は故障チェックの期間情報を取得する
                list < date > assingRangeDates = roomTypeDateLinkByIdxMap.get(idx);
                // 連続期間ない場合、処理対象外
                if (assingRangeDates == null || assingRangeDates.isEmpty()) continue;
                // 同部屋タイプ連泊の期間日付の開始と終了日付を取得する
                Date startDt = assingRangeDates[0];
                Date endDt = assingRangeDates[assingRangeDates.size() - 1];
                // 該当部屋は指定期間に、故障あり、なしチエックを行う
                Room__c targetRoom = null;
                for (Room__c room: locCanAssingRoomList) {
                    // 該当部屋は指定期間に、故障がない場合
                    if (!badRoomStatusMap.containsKey(room.Id)) {
                        targetRoom = room;
                        break;
                    } else {
                        // 故障部屋情報リストを取得する
                        List < RoomsStatus__c > badInfoLst = badRoomStatusMap.get(room.Id);
                        Boolean nextRoomFlg = false;
                        // 宿泊期間に故障情報が存在する場合、該当部屋は自動割当て対象外になる
                        for (RoomsStatus__c roomStatus: badInfoLst) {
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
                    if (!badRoomStatusMap.containsKey(targetRoom.Id)) badRoomStatusMap.put(targetRoom.Id, new List < RoomsStatus__c > ());
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

        // 2015/10/30 故障部屋は自動割当て機能に追加対応 BEGIN
        //return canAssignRoomMap;
        mLogUtils.write_method_end();
        return resultMap;
        // 2015/10/30 故障部屋は自動割当て機能に追加対応 END
    }

    // 小数桁数はシステム定義により、長い場合、単数処理後の処理値は検証する
    private static Decimal checkIfHadScale(Decimal orgPrice, Decimal taxRate, Decimal serviceRate, Integer kbn) {
        // システム小数点の長さ
        Integer pointLen = CommUtils.getPointLen();
        // 変換値の小数点桁数
        Integer pricePointLen = orgPrice.stripTrailingZeros().scale();
        // システム予想の小数桁数により、長小数点をもっている場合
        if (pricePointLen > pointLen) {
            // 指定区分でサ込、税込金額を取得する
            CommUtils.ProductInfo pro = new CommUtils.ProductInfo(kbn);
            pro.process(orgPrice, 1, taxRate, serviceRate);
            Decimal orgIncTaxServicePrice = pro.unitPriceTax;

            // 指定小数まで切上げで変換する
            Decimal roundPrice = CommUtils.RoundProcess(orgPrice, pointLen, RoundingMode.CEILING);
            pro.process(roundPrice, 1, taxRate, serviceRate);
            if (pro.unitPriceTax == orgIncTaxServicePrice) return roundPrice;

            // 指定小数まで切り捨てで変換する
            roundPrice = CommUtils.RoundProcess(orgPrice, pointLen, RoundingMode.FLOOR);
            pro.process(roundPrice, 1, taxRate, serviceRate);
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
    private static List < Lead__c > filterJRImportData(List < Lead__c > orgLst, BI_JR_SyncInfo bookingInfo, LeadIndex__c leadIndex, Set < Id > pSubLeadIds) {
        mLogUtils.write_method_start('filterJRImportData');
        // 予約番号比較用: TL_99999999
        //      String dataId = bookingDataId;
        //      System.debug(LoggingLevel.INFO,'-----------dataId----------' + dataId);
        // TL電文経由で作成の予約情報を格納する
        List < Lead__c > filterLst = new List < Lead__c > ();
        // 予約インデックスの作成時間を取得する
        // TODO：予約情報を新規作成後、予約変更電文で泊数変更など、新作成された予約情報も処理対象が必要、該当対応が必要です
        long createTimeLon = leadIndex.CreatedDate.getTime();
        // 2018/08/10 TL->JR変換の紐付ける処理の対応 BEGIN
        String tlAppName = BI_JR_ServiceConfigHelp.ProcessingType.TL.Name(); 
        String tlbookingDataId = tlAppName + '_' + leadIndex.ID__c;
        // 2018/08/10 TL->JR変換の紐付ける処理の対応 END
        //boolean isHadBookingData = false;
        Set < Id > filterIdSet = new Set < Id > ();
        // 予約番号情報を登録データが存在する場合
        for (Lead__c lead: orgLst) {
            // 予約に予約番号を登録されている　かつ　該当予約番号は予約インデックスと登録の番号が一致（Tl_予約インデックス.ID)
	    // 2018/08/10 TL->JR変換の紐付ける処理の対応 BEGIN
            //if (!CommUtils.isBlank(lead.BookingDataID__c) && lead.BookingDataID__c == bookingDataId) {
            if (!CommUtils.isBlank(lead.BookingDataID__c) && 
            	(lead.BookingDataID__c == bookingDataId) || (tl2wayToJr2way && lead.BookingDataID__c == tlbookingDataId) ) {
	    // 2018/08/10 TL->JR変換の紐付ける処理の対応 END
                filterLst.add(lead);
                filterIdSet.add(lead.id);
            }
        }
        // 予約番号を登録されている予約情報がない場合
        if (filterLst.isEmpty()) {
            for (Lead__c lead: orgLst) {
                // 予約インデックスSUBのIDをチェックが必要
                if (!pSubLeadIds.contains(lead.LeadIndexSubId__c)) continue;
                // 予約の発生源情報を登録　かつ　TL経由で作成の予約情報場合
		// 2018/08/10 TL->JR変換の紐付ける処理の対応 BEGIN
                //if (!CommUtils.isBlank(lead.EventSource__c) && lead.EventSource__c.contains(APPNAME)) {
                if (!CommUtils.isBlank(lead.EventSource__c) && 
                	(lead.EventSource__c.contains(APPNAME) || (tl2wayToJr2way && lead.EventSource__c.contains(tlAppName))) ) {
		// 2018/08/10 TL->JR変換の紐付ける処理の対応 END
                    filterLst.add(lead);
                    filterIdSet.add(lead.id);
                }
            }
        }
        // 予約情報予約番号登録なし　OR　TL発生源も登録なしの予約情報に対して、
        if (filterLst.isEmpty()) {
            for (Lead__c lead: orgLst) {
                // 予約インデックスSUBのIDをチェックが必要
                if (!pSubLeadIds.contains(lead.LeadIndexSubId__c)) continue;
                long leadLong = lead.CreatedDate.getTime();
                if ((leadLong - createTimeLon) <= LEAD_CREATE_TIME_DIFF_INT) {
                    filterLst.add(lead);
                    filterIdSet.add(lead.id);
                }
            }
        }
        if (!filterIdSet.isEmpty()) {
            for (Lead__c lead: orgLst) {
                if (!filterIdSet.contains(lead.id)) {
                    mLogUtils.write_log('関連更新対象外予約ID=' + lead.id);
                }
            }
        }
        mLogUtils.write_method_end();
        return filterLst;
    }
    // 2016/06/20 EDIT END
    // 2016/09/30 EDIT BEGIN
    private static String formatPlanName(String planName) {
        planName = CommUtils.nullToBlank(planName);
        return (planName.length() > 80 ? planName.substring(0, 80) : planName);
    }
    // 2016/09/30 EDIT END
    global class BI_JR_SyncInfo {
        // 01 情報区分 TransactionType
        webservice BI_JR_DmlAction dmlAction;
        webservice String DataFrom; //送り元区分     
        webservice String DataClassification; //データ種別       
        webservice String DataID; //データID       
        webservice Date SystemDate; //システム日付        
        webservice Time SystemTime; //システム時刻        


        // 02 宿泊施設側情報 AccommodationInformation
        webservice String AccommodationArea; //宿泊地区名        
        webservice String AccommodationName; //宿泊施設名        
        webservice String AccommodationCode; //宿泊施設コード      
        webservice String ChainName; //チェーンホテル名     
        webservice String AccommodationPersonInCharge; //宿泊施設担当者名       
        webservice String AccommodationEmail; //宿泊施設担当者Email        
        webservice String AccommodationPhoneNumber; //宿泊施設電話番号      
        webservice String AccommodationCPUAddress; //宿泊施設宛先指定       


        // 振込銀行情報 BankList  
        webservice List < BI_JR_BankInformation > bankList;

        // 旅行会社情報 SalesOfficeInformation
        webservice String SalesOfficeCompanyCode; //旅行会社コード     
        webservice String SalesOfficeCompanyName; //旅行会社名       
        webservice String SalesOfficeName; //旅行会社営業所名       
        webservice String SalesOfficeCode; //旅行会社営業所コード     
        webservice String SalesOfficePersonInCharge; //旅行会社営業所担当者名      
        webservice String SalesOfficeEmail; //旅行会社営業所担当者Email       
        webservice String SalesOfficePhoneNumber; //旅行会社営業所電話番号     
        webservice String SalesOfficeFaxNumber; //旅行会社営業所FAX番号      
        webservice String SalesOfficeStateProvidence; //旅行会社営業所住所都道府県       
        webservice String SalesOfficeCityName; //旅行会社営業所住所区市名       
        webservice String SalesOfficeAddressLine; //旅行会社営業所住所町村名        
        webservice String SalesOfficeStreetNumber; //旅行会社営業所住所番地名       
        webservice String SalesOfficePostalCode; //旅行会社営業所住所郵便番号        
        webservice String SalesOfficeRegisteredCategory; //旅行会社登録種別     
        webservice String SalesOfficeLicenseNumber; //旅行会社登録番号      
        webservice String SalesOfficeRegisteredPrefecture; //旅行会社登録行政庁      
        webservice String SalesOfficeCPUAddress; //旅行会社宛先指定     
        webservice String RetailerCompanyName; //販売代理店会社名       
        webservice String RetailerOfficeName; //販売代理店営業所名       
        webservice String RetailerOfficeCode; //販売代理店営業所コード     
        webservice String RetailerPersonInCharge; //販売代理店担当者名       
        webservice String RetailerEmail; //販売代理店担当者Email        
        webservice String RetailerPhoneNumber; //販売代理店電話番号      
        webservice String RetailerStateProvidence; //販売代理店住所都道府県        
        webservice String RetailerCityName; //販売代理店住所区市名        
        webservice String RetailerAddressLine; //販売代理店住所町村名     
        webservice String RetailerStreetNumber; //販売代理店住所番地名        
        webservice String RetailerPostalCode; //販売代理店住所郵便番号     
        webservice String RetailerRegisteredCategory; //販売代理店登録種別       
        webservice String RetailerLicenseNumber; //販売代理店登録番号        
        webservice String RetailerRegisteredPrefecture; //販売代理店登録行政庁        


        // 基本宿泊情報: BasicInformation
        webservice String TravelAgencyBookingNumber; // 旅行会社予約(管理)番号        
        webservice Date TravelAgencyBookingDate; //旅行会社予約受付日        
        webservice Time TravelAgencyBookingTime; //旅行会社受付時間
        webservice String TravelAgencyReportNumber; //通知番号      
        webservice String AccommodationConfirmationNumber; //宿泊個所予約番号       
        webservice String GuestOrGroupNameSingleByte; //団体名または代表者氏名(半角)     
        webservice String GuestOrGroupNameDoubleByte; //団体名または代表者氏名よみがな(全角)     
        webservice String GuestOrGroupNameKanjiName; //団体名または代表者氏名 漢字       
        webservice String GroupNameWelcomeBoard; //団体名(ウェルカムボード用)           
        webservice Date CheckInDate; //チェックイン日  
        webservice Time CheckInTime; //チェックイン時間 
        webservice Date CheckOutDate; //チェックアウト日    
        webservice Time CheckOutTime; //チェックアウト時間   
        webservice Integer Nights; //宿泊日数   
        webservice String Transportaion; //入込方法 
        webservice Integer CoachCount; //入込バス台数 
        webservice Integer CoachCompany; //入込バス会社名  
        webservice Integer TotalRoomCount; //利用客室合計数        
        webservice Integer GrandTotalPaxCount; //お客様総合計人数       
        webservice Integer TotalPaxMaleCount; //大人人員（男性）合計      
        webservice Integer TotalPaxFemaleCount; //大人人員（女性）合計        
        webservice Integer TotalChildA70Count; //子供A人数合計        
        webservice Integer TotalChildB50Count; //子供B人数合計        
        webservice Integer TotalChildC30Count; //子供C人数合計        
        webservice Integer TotalChildDNoneCount; //子供D人数合計      
        webservice Integer TotalChildECount; //子供E人数合計      
        webservice Integer TotalChildFCount; //子供F人数合計      
        webservice Integer TotalChildOtherCount; //子供その他人数合計        
        webservice Integer TotalTourConductorCount; //添乗員人数合計       
        webservice Integer TotalCoachDriverCount; //バスドライバー人数合計     
        webservice Integer TotalGuideCount; //バスガイド人数合計     
        webservice Integer TypeOfGroup; //参加形態      
        webservice String Status; //予約ステータス     
        webservice String PackageType; //企画商品区分     
        webservice String PackagePlanName; //企画(パッケージ)名     
        webservice String PackagePlanCode; //企画(パッケージ)コード       
        webservice String PackagePlanContent; //企画(パッケージ)内容                     
        webservice String MealCondition; //食事条件     
        webservice String SpecificMealCondition; //食事有無情報       
        webservice String MealPlace; //食事個所情報       
        webservice String BanquetRoom; //宴会場利用      
        webservice String ModificationType; //変更点区分     
        webservice String ModificationPoint; //変更ポイント説明 
        webservice String CancellationNumber; //宿泊施設取消番号        
        webservice String PreviousPlace; //前泊地      
        webservice String PreviousAccommodationName; //前泊宿泊施設名      
        webservice String SpecialServiceRequest; //特別リクエスト      
        webservice String OtherServiceInformation; //一般情報       
        webservice String FollowUpInformation; //詳細情報有無     
        webservice String TravelAgencyEmail; //旅行会社作成の予約情報メール       

        //オプション情報
        webservice List < BI_JR_OptionInformation > optionList;

        // 基本情報 BasicRateInformation
        webservice String RoomRateOrPersonalRate; //料金区分           
        webservice String TaxServiceFee; //税サ区分     
        webservice String Payment; //支払い方法      
        webservice Integer BareNetRate; //ネット決済額        
        webservice String CancellationCharge; //前広取消に対する取消料情報       
        webservice String CreditCardAuthority; //クレジットカード会社名        
        webservice String CreditCardNumber; //クレジットカード番号        
        webservice String ExpireDate; //クレジットカード有効期限        
        webservice String CardHolderName; //クレジットカード保有者氏名             
        webservice Integer TotalAccommodationCharge; //合計宿泊料金(総額)       
        webservice Integer TotalAccommodationConsumptionTax; //合計宿泊料金消費税        
        webservice Integer TotalAccommodationHotSpringTax; //合計宿泊料金入湯税      
        webservice Integer TotalAccommodationHotelTax; //合計宿泊料金ホテル税他        
        webservice Integer TotalAccommodationServiceFee; //合計宿泊料金サービス料      
        webservice Integer TotalAccommodationBreakfastFee; //合計朝食料金     
        webservice Integer TotalAccommodationOtherFee; //合計その他料金        
        webservice Decimal CommissionPercentage; //手数料率(%)      
        webservice Integer TotalAccommodationCommissionAmount; //合計手数料総額        
        webservice Integer TotalAccommodationCommissionConsumptionTax; //合計手数料消費税総額     
        webservice Integer TotalAccommodationChargeAfterCheckIn; //宿泊当日変更後の宿泊料金(総額)     
        webservice Integer TotalBalanceAfterCheckIn; //宿泊当日変更後の宿泊料金(差額)     
        webservice Integer TotalAccommodationConsumptionAfterCheckIn; //宿泊当日変更後の手数料消費税      
        webservice Integer CancellationChargeAfterCheckIn; //宿泊当日取消に対する取消料情報        
        webservice String MembershipFee; //定率会費     
        webservice String AdjustmentFee; //精算調整額        

        // クーポン明細 0:N
        webservice List < BI_JR_CouponInformation > couponList;
        // 個々の部屋とお客様情報<1:N>
        webservice List < BI_JR_RoomAndGuestInfo > roomAndGuestLst;
        // 予約者・会員情報
        webservice BI_JR_Member member;
        // 2018/04/19 氏名変更のみケース対応 BEGIN
	    webservice Boolean isUpdForName{get{
	    	return (isUpdForName == null ? false : isUpdForName);
	    } set;}
	    // 2018/04/19 氏名変更のみケース対応 END 
    }

    //振込銀行情報
    global class BI_JR_BankInformation {
        webservice String BankName; //振込銀行名 
        webservice String BankAcountNumber; //口座番号  
        webservice String BankBranchName; //振込銀行支店名 
        webservice String BankAccountClassification; //振込銀行口座種別 
        webservice String BankAccountName; //口座名        
    }

    //オプション情報
    global class BI_JR_OptionInformation {
        webservice Date OptionDate; //オプション利用年月日    
        webservice String Name; //オプション名称   
        webservice String NameRequest; //オプション名備考   
        webservice Integer OptionCount; //オプション個数   
        webservice Integer OptionRate; //オプション料金単価  
    }

    // クーポン明細
    global class BI_JR_CouponInformation {
        webservice String CouponAmount; //クーポン券面額   
        webservice String CouponType; //クーポン種類  
        webservice String CouponTypeRequest; //クーポン備考   
        webservice String CouponNumber; //クーポン番号    
        webservice String CouponIssueDate; //クーポン発行日            
    }

    // １部屋利用情報(1:1) [LEVEL:1-2-3-4]
    global class BI_JR_RoomAndGuestInfo {
        webservice BI_JR_RoomInformation room;
        webservice BI_JR_RoomRateInfomation roomRate;
        webservice BI_JR_GuestInfo guest;
    }

    // 部屋情報[LEVEL:1-2-3-4-5] 
    global class BI_JR_RoomInformation {
        webservice String RoomTypeCode; //部屋タイプコード  
        webservice String RoomTypeName; //部屋タイプ名    
        webservice String RoomCategory; //部屋カテゴリー   
        webservice String ViewType; //部屋眺望  
        webservice String SmokingOrNonSmoking; //喫煙/禁煙  
        webservice Integer PerRoomPaxCount; //1室利用人数    
        webservice Integer RoomPaxMaleCount; //大人人員(男性)         
        webservice Integer RoomPaxFemaleCount; //大人人員(女性)       
        webservice Integer RoomChildA70Count; //子供A人数       
        webservice Integer RoomChildB50Count; //子供B人数       
        webservice Integer RoomChildC30Count; //子供C人数       
        webservice Integer RoomChildDNoneCount; //子供D人数     
        webservice Integer RoomChildECount; //子供E人数     
        webservice Integer RoomChildFCount; //子供F人数     
        webservice Integer RoomChildOtherCount; //子供その他人数       
        webservice String RoomByRoomStatus; //部屋毎予約ステイタス                
        webservice String RoomByRoomConfirmationNumber; //部屋毎予約番号       
        webservice String Facilities; //その他設備       
        webservice String AssignedRoomNumber; //部屋割り後客室名/番号     
        webservice String RoomSpecialRequest; //客室に対する特別リクエスト       
        webservice String RoomTypeAgent; //在庫引落し先旅行会社コード        
    }
    // 1部屋の部屋料金情報[LEVEL:1-2-3-4-5]
    global class BI_JR_RoomRateInfomation {
        webservice List < BI_JR_RoomDateGuest > roomDateGuestList; // 部屋別利用日客種一覧        
        webservice Date RoomDate; //利用年月日       
        webservice Integer PerPaxRate; //大人一人料金     
        webservice Integer PerPaxMaleRate; //大人一人料金(男性)     
        webservice Integer PerPaxFemaleRate; //大人一人料金(女性)       
        webservice Integer PerChildA70Rate; //子供A一人料金       
        webservice Integer PerChildB50Rate; //子供B一人料金               
        webservice Integer PerChildC30Rate; //子供C一人料金       
        webservice Integer PerChildDRate; //子供D一人料金     
        webservice Integer PerChildERate; //子供E一人料金     
        webservice Integer PerChildFRate; //子供F一人料金     
        webservice Integer PerChildOtherRate; //子供その他一人料金       
        webservice Integer TotalPerRoomRate; //1室あたり宿泊料金合計      
        webservice Integer TotalPerRoomConsumptionTax; //1室あたり宿泊料金消費税合計     
        webservice Integer TotalPerlRoomHotSpringTax; //1室あたり宿泊料金入湯税合計      
        webservice Integer TotalPerRoomHotelTax; //1室あたり宿泊料金ホテル税他合計     
        webservice Integer TotalPerRoomServiceFee; //1室あたり宿泊料金サービス料合計       
        webservice Integer TotalPerRoomBreakfastFee; //1室あたり朝食料金合計      
        webservice Integer TotalPerRoomOtherFee; //1室あたりその他料金合計     
        webservice Integer TotalPerRoomCommissionAmount; //1室あたり手数料総額       
        webservice Integer TotalPerRoomCommissionConsumptionTax; //1室あたり手数料消費税額     



    }
    // 部屋別利用日客種一覧[LEVEL:1-2-3-4-5-6]
    global class BI_JR_RoomDateGuest {
        webservice String GuestTypeCode; //客種コード    
        webservice String GuestType; //客種データ    
        webservice Integer Rate; //料金   
        webservice Integer Count; //人数  

    }
    // お客様情報[LEVEL:1-2-3-4-5]
    global class BI_JR_GuestInfo {
        webservice List < BI_JR_GuestInformationList > guestInformationList; // お客様情報リスト   
        // -----  該当Section廃止開始
        webservice String GuestNameSingleByte; //お客様氏名半角カタカナ英字(姓名)      
        webservice String GuestSurName; //お客様氏名全角ふりがな(姓)        
        webservice String GuestGivenName; //お客様氏名全角ふりがな(名)      
        webservice String GuestMiddleName; //お客様氏名半角英字(ミドルネーム)      
        webservice String GuestNamePrefix; //お客様肩書き     
        webservice String GuestKanjiName; //お客様氏名全角漢字(姓名)       
        webservice String GuestGender; //お客様男女区分        
        webservice Integer GuestAge; //お客様年齢        
        webservice Date GuestDateOfBirth; //お客様生年月日     
        webservice String GuestType; //お客様人員区分      
        webservice String GuestShubetsu; //お客様種別        
        webservice String GuestPhoneNumber; //お客様電話番号       
        webservice String GuestEmergencyPhoneNumber; //お客様緊急連絡先     
        webservice String GuestEmail; //お客様Email        
        webservice String GuestCountry; //お客様国籍     
        webservice String GuestStateProvidence; //お客様住所都道府県     
        webservice String GuestCityName; //お客様住所区市名     
        webservice String GuestAddressLine; //お客様住所町村名      
        webservice String GuestStreetNumber; //お客様住所番地名     
        webservice String GuestPostalCode; //お客様住所郵便番号      
        webservice String GuestBuildingName; //お客様住所ビル・部屋名      
        webservice String GuestFFPCarrier; //お客様FFPキャリア     
        webservice String GuestFFPNumber; //お客様FFPNo.       
        webservice String GuestCoachNumber; //お客様バス号車番号     
        webservice String SpecialInformation; //お客様特記情報 
        // -----  該当Section廃止終了
    }
    // お客様情報リスト[LEVEL:1-2-3-4-5-6]
    global class BI_JR_GuestInformationList {
        webservice String GuestNameSingleByte; //お客様氏名半角カタカナ英字(姓名)      
        webservice String GuestSurName; //お客様氏名全角ふりがな(姓)        
        webservice String GuestGivenName; //お客様氏名全角ふりがな(名)      
        webservice String GuestMiddleName; //お客様氏名半角英字(ミドルネーム)      
        webservice String GuestNamePrefix; //お客様肩書き     
        webservice String GuestKanjiName; //お客様氏名全角漢字(姓名)       
        webservice String GuestGender; //お客様男女区分        
        webservice Integer GuestAge; //お客様年齢        
        webservice Date GuestDateOfBirth; //お客様生年月日     
        webservice String GuestType; //お客様人員区分      
        webservice String GuestShubetsu; //お客様種別        
        webservice String GuestPhoneNumber; //お客様電話番号       
        webservice String GuestEmergencyPhoneNumber; //お客様緊急連絡先     
        webservice String GuestEmail; //お客様Email        
        webservice String GuestCountry; //お客様国籍     
        webservice String GuestStateProvidence; //お客様住所都道府県     
        webservice String GuestCityName; //お客様住所区市名     
        webservice String GuestAddressLine; //お客様住所町村名      
        webservice String GuestStreetNumber; //お客様住所番地名     
        webservice String GuestPostalCode; //お客様住所郵便番号      
        webservice String GuestBuildingName; //お客様住所ビル・部屋名      
        webservice String GuestFFPCarrier; //お客様FFPキャリア     
        webservice String GuestFFPNumber; //お客様FFPNo.       
        webservice String GuestCoachNumber; //お客様バス号車番号     
        webservice String SpecialInformation; //お客様特記情報     
    }

    // 予約者・会員情報[LEVEL:1-2-3]
    global class BI_JR_Member {
        webservice String UserName; //予約者・会員名漢字     
        webservice String UserKana; //予約者・会員名カタカナ       
        webservice String UserTel; //予約者・会員電話番号     
        webservice String UserMailAddr; //予約者・会員Email       
        webservice String UserZip; //予約者・会員郵便番号     
        webservice String UserAddr; //予約者・会員住所      
        webservice String UserCorp; //予約者・会員会社      
        webservice String UserDep; //予約者・会員所属部署     
        webservice String UserID; //予約者・会員番号        
        webservice String VIPCode; //VIPコード     
        webservice String PointCompanyName; //充当先       
        webservice String PointName; //ポイント名称       
        webservice String UserGivinPoints; //付与ポイント     
        webservice String UserUsePoints; //使用ポイント       
        webservice Integer TotalAccommodationDecleasePoints; //ポイント割引後の総額       
        webservice Integer TotalAccommodationConsumptaionTax; //ポイント割引後の総額に対する消費税額      
        webservice Integer AmountClaimed; //宿泊者請求額      
        webservice String ChargeEquation; //宿泊料金計算式         
    }

    global class BI_JR_SyncResult {
        // 処理結果
        webservice BI_JR_Result result;
        webservice Id sfdcId;
        webservice String message;
        webservice Id sfdcJobId;
    }
    // 戻る結果：処理成功、処理失敗、処理中。
    global enum BI_JR_Result{OK, NG, WAIT}
    // INS:新規 / UPD:更新 / 削除：キャンセル
    global enum BI_JR_DmlAction{INS, UPD, CANCEL, CONFIRM, TEJIMA, ISSUE, OTHER }
	

    // 2017/06/30 XML特殊記号文字UTF-8対応 BEGIN
    static void unescapeXmlProcess(BI_JR_SyncInfo bookingInfo) {
        // 宿泊施設側情報
        bookingInfo.AccommodationArea = unescapeXml(bookingInfo.AccommodationArea);
        bookingInfo.AccommodationName = unescapeXml(bookingInfo.AccommodationName);
        bookingInfo.AccommodationCode = unescapeXml(bookingInfo.AccommodationCode);
        bookingInfo.ChainName = unescapeXml(bookingInfo.ChainName);
        bookingInfo.AccommodationPersonInCharge = unescapeXml(bookingInfo.AccommodationPersonInCharge);
        bookingInfo.AccommodationEmail = unescapeXml(bookingInfo.AccommodationEmail);
        bookingInfo.AccommodationPhoneNumber = unescapeXml(bookingInfo.AccommodationPhoneNumber);
        bookingInfo.AccommodationCPUAddress = unescapeXml(bookingInfo.AccommodationCPUAddress);
        // 振込銀行情報 BankList
        List < BI_JR_BankInformation > bankLst = bookingInfo.bankList;
        if (bankLst != null) {
            for (BI_JR_BankInformation bank: bankLst) {
                bank.BankName = unescapeXml(bank.BankName);
                bank.BankAcountNumber = unescapeXml(bank.BankAcountNumber);
                bank.BankBranchName = unescapeXml(bank.BankBranchName);
                bank.BankAccountClassification = unescapeXml(bank.BankAccountClassification);
                bank.BankAccountName = unescapeXml(bank.BankAccountName);
            }
        }
        //  旅行会社情報
        bookingInfo.SalesOfficeCompanyCode = unescapeXml(bookingInfo.SalesOfficeCompanyCode);
        bookingInfo.SalesOfficeCompanyName = unescapeXml(bookingInfo.SalesOfficeCompanyName);
        bookingInfo.SalesOfficeName = unescapeXml(bookingInfo.SalesOfficeName);
        bookingInfo.SalesOfficeCode = unescapeXml(bookingInfo.SalesOfficeCode);
        bookingInfo.SalesOfficePersonInCharge = unescapeXml(bookingInfo.SalesOfficePersonInCharge);
        bookingInfo.SalesOfficeEmail = unescapeXml(bookingInfo.SalesOfficeEmail);
        bookingInfo.SalesOfficePhoneNumber = unescapeXml(bookingInfo.SalesOfficePhoneNumber);
        bookingInfo.SalesOfficeFaxNumber = unescapeXml(bookingInfo.SalesOfficeFaxNumber);
        bookingInfo.SalesOfficeStateProvidence = unescapeXml(bookingInfo.SalesOfficeStateProvidence);
        bookingInfo.SalesOfficeCityName = unescapeXml(bookingInfo.SalesOfficeCityName);
        bookingInfo.SalesOfficeAddressLine = unescapeXml(bookingInfo.SalesOfficeAddressLine);
        bookingInfo.SalesOfficeStreetNumber = unescapeXml(bookingInfo.SalesOfficeStreetNumber);
        bookingInfo.SalesOfficePostalCode = unescapeXml(bookingInfo.SalesOfficePostalCode);
        bookingInfo.SalesOfficeRegisteredCategory = unescapeXml(bookingInfo.SalesOfficeRegisteredCategory);
        bookingInfo.SalesOfficeLicenseNumber = unescapeXml(bookingInfo.SalesOfficeLicenseNumber);
        bookingInfo.SalesOfficeRegisteredPrefecture = unescapeXml(bookingInfo.SalesOfficeRegisteredPrefecture);
        bookingInfo.SalesOfficeCPUAddress = unescapeXml(bookingInfo.SalesOfficeCPUAddress);
        bookingInfo.RetailerCompanyName = unescapeXml(bookingInfo.RetailerCompanyName);
        bookingInfo.RetailerOfficeName = unescapeXml(bookingInfo.RetailerOfficeName);
        bookingInfo.RetailerOfficeCode = unescapeXml(bookingInfo.RetailerOfficeCode);
        bookingInfo.RetailerPersonInCharge = unescapeXml(bookingInfo.RetailerPersonInCharge);
        bookingInfo.RetailerEmail = unescapeXml(bookingInfo.RetailerEmail);
        bookingInfo.RetailerPhoneNumber = unescapeXml(bookingInfo.RetailerPhoneNumber);
        bookingInfo.RetailerStateProvidence = unescapeXml(bookingInfo.RetailerStateProvidence);
        bookingInfo.RetailerCityName = unescapeXml(bookingInfo.RetailerCityName);
        bookingInfo.RetailerAddressLine = unescapeXml(bookingInfo.RetailerAddressLine);
        bookingInfo.RetailerStreetNumber = unescapeXml(bookingInfo.RetailerStreetNumber);
        bookingInfo.RetailerPostalCode = unescapeXml(bookingInfo.RetailerPostalCode);
        bookingInfo.RetailerRegisteredCategory = unescapeXml(bookingInfo.RetailerRegisteredCategory);
        bookingInfo.RetailerLicenseNumber = unescapeXml(bookingInfo.RetailerLicenseNumber);
        bookingInfo.RetailerRegisteredPrefecture = unescapeXml(bookingInfo.RetailerRegisteredPrefecture);
        // 基本宿泊情報
        bookingInfo.TravelAgencyBookingNumber = unescapeXml(bookingInfo.TravelAgencyBookingNumber);
        bookingInfo.TravelAgencyReportNumber = unescapeXml(bookingInfo.TravelAgencyReportNumber);
        bookingInfo.AccommodationConfirmationNumber = unescapeXml(bookingInfo.AccommodationConfirmationNumber);
        bookingInfo.GuestOrGroupNameSingleByte = unescapeXml(bookingInfo.GuestOrGroupNameSingleByte);
        bookingInfo.GuestOrGroupNameDoubleByte = unescapeXml(bookingInfo.GuestOrGroupNameDoubleByte);
        bookingInfo.GuestOrGroupNameKanjiName = unescapeXml(bookingInfo.GuestOrGroupNameKanjiName);
        bookingInfo.GroupNameWelcomeBoard = unescapeXml(bookingInfo.GroupNameWelcomeBoard);
        bookingInfo.Transportaion = unescapeXml(bookingInfo.Transportaion);
        bookingInfo.Status = unescapeXml(bookingInfo.Status);
        bookingInfo.PackageType = unescapeXml(bookingInfo.PackageType);
        bookingInfo.PackagePlanName = unescapeXml(bookingInfo.PackagePlanName);
        bookingInfo.PackagePlanCode = unescapeXml(bookingInfo.PackagePlanCode);
        bookingInfo.PackagePlanContent = unescapeXml(bookingInfo.PackagePlanContent);
        bookingInfo.MealCondition = unescapeXml(bookingInfo.MealCondition);
        bookingInfo.SpecificMealCondition = unescapeXml(bookingInfo.SpecificMealCondition);
        bookingInfo.MealPlace = unescapeXml(bookingInfo.MealPlace);
        bookingInfo.BanquetRoom = unescapeXml(bookingInfo.BanquetRoom);
        bookingInfo.ModificationType = unescapeXml(bookingInfo.ModificationType);
        bookingInfo.ModificationPoint = unescapeXml(bookingInfo.ModificationPoint);
        bookingInfo.CancellationNumber = unescapeXml(bookingInfo.CancellationNumber);
        bookingInfo.PreviousPlace = unescapeXml(bookingInfo.PreviousPlace);
        bookingInfo.PreviousAccommodationName = unescapeXml(bookingInfo.PreviousAccommodationName);
        bookingInfo.SpecialServiceRequest = unescapeXml(bookingInfo.SpecialServiceRequest);
        bookingInfo.OtherServiceInformation = unescapeXml(bookingInfo.OtherServiceInformation);
        bookingInfo.FollowUpInformation = unescapeXml(bookingInfo.FollowUpInformation);
        bookingInfo.TravelAgencyEmail = unescapeXml(bookingInfo.TravelAgencyEmail);
        //オプション情報
        List < BI_JR_OptionInformation > optionLst = bookingInfo.optionList;
        if (optionLst != null) {
            for (BI_JR_OptionInformation option: optionLst) {
                option.Name = unescapeXml(option.Name);
                option.NameRequest = unescapeXml(option.NameRequest);
            }
        }
        // 基本情報 BasicRateInformation
        bookingInfo.RoomRateOrPersonalRate = unescapeXml(bookingInfo.RoomRateOrPersonalRate);
        bookingInfo.TaxServiceFee = unescapeXml(bookingInfo.TaxServiceFee);
        bookingInfo.Payment = unescapeXml(bookingInfo.Payment);
        bookingInfo.CancellationCharge = unescapeXml(bookingInfo.CancellationCharge);
        bookingInfo.CreditCardAuthority = unescapeXml(bookingInfo.CreditCardAuthority);
        bookingInfo.CreditCardNumber = unescapeXml(bookingInfo.CreditCardNumber);
        bookingInfo.ExpireDate = unescapeXml(bookingInfo.ExpireDate);
        bookingInfo.CardHolderName = unescapeXml(bookingInfo.CardHolderName);
        bookingInfo.MembershipFee = unescapeXml(bookingInfo.MembershipFee);
        bookingInfo.AdjustmentFee = unescapeXml(bookingInfo.AdjustmentFee);
        // クーポン明細 0:N
        List < BI_JR_CouponInformation > couponLst = bookingInfo.couponList;
        if (couponLst != null) {
            for (BI_JR_CouponInformation coupon: couponLst) {
                coupon.CouponAmount = unescapeXml(coupon.CouponAmount);
                coupon.CouponType = unescapeXml(coupon.CouponType);
                coupon.CouponTypeRequest = unescapeXml(coupon.CouponTypeRequest);
                coupon.CouponNumber = unescapeXml(coupon.CouponNumber);
                coupon.CouponIssueDate = unescapeXml(coupon.CouponIssueDate);
            }
        }
        // 個々の部屋とお客様情報<1:N>
        for (BI_JR_RoomAndGuestInfo roomGuestInfo: bookingInfo.roomAndGuestLst) {
            // 部屋情報
            BI_JR_RoomInformation roomInfo = roomGuestInfo.room;
            if (roomInfo != null) {
                roomInfo.RoomTypeCode = unescapeXml(roomInfo.RoomTypeCode);
                roomInfo.RoomTypeName = unescapeXml(roomInfo.RoomTypeName);
                roomInfo.RoomCategory = unescapeXml(roomInfo.RoomCategory);
                roomInfo.ViewType = unescapeXml(roomInfo.ViewType);
                roomInfo.SmokingOrNonSmoking = unescapeXml(roomInfo.SmokingOrNonSmoking);
                roomInfo.RoomByRoomStatus = unescapeXml(roomInfo.RoomByRoomStatus);
                roomInfo.RoomByRoomConfirmationNumber = unescapeXml(roomInfo.RoomByRoomConfirmationNumber);
                roomInfo.Facilities = unescapeXml(roomInfo.Facilities);
                roomInfo.AssignedRoomNumber = unescapeXml(roomInfo.AssignedRoomNumber);
                roomInfo.RoomSpecialRequest = unescapeXml(roomInfo.RoomSpecialRequest);
                roomInfo.RoomTypeAgent = unescapeXml(roomInfo.RoomTypeAgent);
            }
            // 1部屋の部屋料金情報(1:N){連泊}
            BI_JR_RoomRateInfomation roomRate = roomGuestInfo.roomRate;
            if (roomRate != null) {
                //部屋別利用日客種一覧
                List < BI_JR_RoomDateGuest > roomDateGuestList = roomRate.roomDateGuestList;
                if (roomDateGuestList != null) {
                    for (BI_JR_RoomDateGuest roomDateGuest: roomDateGuestList) {
                        roomDateGuest.GuestTypeCode = unescapeXml(roomDateGuest.GuestTypeCode);
                        roomDateGuest.GuestType = unescapeXml(roomDateGuest.GuestType);
                    }
                }
            }
            // 顧客情報
            BI_JR_GuestInfo guest = roomGuestInfo.guest;
            if (guest != null) {
                List < BI_JR_GuestInformationList > guestInfoLst = guest.guestInformationList;
                if (guestInfoLst != null) {
                    for (BI_JR_GuestInformationList guestInfo: guestInfoLst) {
                        guestInfo.guestNameSingleByte = unescapeXml(guestInfo.guestNameSingleByte);
                        guestInfo.guestSurName = unescapeXml(guestInfo.guestSurName);
                        guestInfo.guestGivenName = unescapeXml(guestInfo.guestGivenName);
                        guestInfo.guestMiddleName = unescapeXml(guestInfo.guestMiddleName);
                        guestInfo.guestNamePrefix = unescapeXml(guestInfo.guestNamePrefix);
                        guestInfo.guestKanjiName = unescapeXml(guestInfo.guestKanjiName);
                        guestInfo.guestGender = unescapeXml(guestInfo.guestGender);
                        guestInfo.guestType = unescapeXml(guestInfo.guestType);
                        guestInfo.guestShubetsu = unescapeXml(guestInfo.guestShubetsu);
                        guestInfo.guestPhoneNumber = unescapeXml(guestInfo.guestPhoneNumber);
                        guestInfo.guestEmergencyPhoneNumber = unescapeXml(guestInfo.guestEmergencyPhoneNumber);
                        guestInfo.guestEmail = unescapeXml(guestInfo.guestEmail);
                        guestInfo.guestCountry = unescapeXml(guestInfo.guestCountry);
                        guestInfo.guestStateProvidence = unescapeXml(guestInfo.guestStateProvidence);
                        guestInfo.guestCityName = unescapeXml(guestInfo.guestCityName);
                        guestInfo.guestAddressLine = unescapeXml(guestInfo.guestAddressLine);
                        guestInfo.guestStreetNumber = unescapeXml(guestInfo.guestStreetNumber);
                        guestInfo.guestPostalCode = unescapeXml(guestInfo.guestPostalCode);
                        guestInfo.guestBuildingName = unescapeXml(guestInfo.guestBuildingName);
                        guestInfo.guestFFPCarrier = unescapeXml(guestInfo.guestFFPCarrier);
                        guestInfo.guestFFPNumber = unescapeXml(guestInfo.guestFFPNumber);
                        guestInfo.guestCoachNumber = unescapeXml(guestInfo.guestCoachNumber);
                        guestInfo.SpecialInformation = unescapeXml(guestInfo.SpecialInformation);
                    }
                }
                guest.GuestNameSingleByte = unescapeXml(guest.GuestNameSingleByte);
                guest.GuestSurName = unescapeXml(guest.GuestSurName);
                guest.GuestGivenName = unescapeXml(guest.GuestGivenName);
                guest.GuestMiddleName = unescapeXml(guest.GuestMiddleName);
                guest.GuestNamePrefix = unescapeXml(guest.GuestNamePrefix);
                guest.GuestKanjiName = unescapeXml(guest.GuestKanjiName);
                guest.GuestGender = unescapeXml(guest.GuestGender);
                guest.GuestType = unescapeXml(guest.GuestType);
                guest.GuestShubetsu = unescapeXml(guest.GuestShubetsu);
                guest.GuestPhoneNumber = unescapeXml(guest.GuestPhoneNumber);
                guest.GuestEmergencyPhoneNumber = unescapeXml(guest.GuestEmergencyPhoneNumber);
                guest.GuestEmail = unescapeXml(guest.GuestEmail);
                guest.GuestCountry = unescapeXml(guest.GuestCountry);
                guest.GuestStateProvidence = unescapeXml(guest.GuestStateProvidence);
                guest.GuestCityName = unescapeXml(guest.GuestCityName);
                guest.GuestAddressLine = unescapeXml(guest.GuestAddressLine);
                guest.GuestStreetNumber = unescapeXml(guest.GuestStreetNumber);
                guest.GuestPostalCode = unescapeXml(guest.GuestPostalCode);
                guest.GuestBuildingName = unescapeXml(guest.GuestBuildingName);
                guest.GuestFFPCarrier = unescapeXml(guest.GuestFFPCarrier);
                guest.GuestFFPNumber = unescapeXml(guest.GuestFFPNumber);
                guest.GuestCoachNumber = unescapeXml(guest.GuestCoachNumber);
                guest.SpecialInformation = unescapeXml(guest.SpecialInformation);
            }
        }
        // Member    
        BI_JR_Member member = bookingInfo.member;
        if (member != null) {
            member.UserName = unescapeXml(member.UserName);
            member.UserKana = unescapeXml(member.UserKana);
            member.UserTel = unescapeXml(member.UserTel);
            member.UserMailAddr = unescapeXml(member.UserMailAddr);
            member.UserZip = unescapeXml(member.UserZip);
            member.UserAddr = unescapeXml(member.UserAddr);
            member.UserCorp = unescapeXml(member.UserCorp);
            member.UserDep = unescapeXml(member.UserDep);
            member.UserID = unescapeXml(member.UserID);
            member.VIPCode = unescapeXml(member.VIPCode);
            member.PointCompanyName = unescapeXml(member.PointCompanyName);
            member.PointName = unescapeXml(member.PointName);
            member.UserGivinPoints = unescapeXml(member.UserGivinPoints);
            member.UserUsePoints = unescapeXml(member.UserUsePoints);
            member.ChargeEquation = unescapeXml(member.ChargeEquation);
        }
    }
    static string unescapeXml(String s) {
        if (CommUtils.isBlank(s)) return s;
        return s.unescapeXml();
    }
    // 2017/06/30 XML特殊記号文字UTF-8対応 END
    // 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 ZH BEGIN
	static void convertGuestInfo(BI_JR_SyncInfo bookingInfo) {
        // 宿泊施設側情報
        // 振込銀行情報 BankList
        // 旅行会社情報
        // 基本宿泊情報
        bookingInfo.GuestOrGroupNameKanjiName = CommStringUtils.convertRomanToKana(bookingInfo.GuestOrGroupNameKanjiName, true);
        // オプション情報
        // 基本情報 BasicRateInformation
        // クーポン明細 0:N
        // 個々の部屋とお客様情報<1:N>
        for (BI_JR_RoomAndGuestInfo roomGuestInfo: bookingInfo.roomAndGuestLst) {
            // 部屋情報
            // 1部屋の部屋料金情報(1:N){連泊}
            // 顧客情報
            BI_JR_GuestInfo guest = roomGuestInfo.guest;
            if (guest != null) {
                List < BI_JR_GuestInformationList > guestInfoLst = guest.guestInformationList;
                if (guestInfoLst != null) {
                    for (BI_JR_GuestInformationList guestInfo: guestInfoLst) {
                        guestInfo.guestKanjiName = CommStringUtils.convertRomanToKana(guestInfo.guestKanjiName, true);
                    }
                }
                guest.GuestKanjiName = CommStringUtils.convertRomanToKana(guest.GuestKanjiName, true);
            }
        }
        // Member    
        BI_JR_Member member = bookingInfo.member;
        if (member != null) {
            member.UserName = CommStringUtils.convertRomanToKana(member.UserName, true);
        }
	}
	// 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 ZH END
}